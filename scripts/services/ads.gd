extends Node

## Rewarded video, behind an interface that works with no ad SDK installed.
##
## Three things this file is trying to get right.
##
## **It must run without the plugin.** The AdMob plugin is a native Android
## addon; it does not exist in the editor, in CI, or in a headless test run. So
## every call goes through here, and here degrades to a no-op that reports "no
## ad available" rather than crashing. The game is always playable and always
## testable, and the ad layer can be added or removed without touching a line
## of game logic.
##
## **It must run when the plugin is present and broken**, which is the case
## nobody writes code for and everybody eventually ships. A native SDK can bind
## its singleton, accept `load_rewarded()`, and then never call back -- no ad
## fill, no network, a consent form the player dismissed, a mediation adapter
## that threw on a background thread. So every entry point is guarded, every
## call to the plugin goes through `_call`, and a show that produces no
## callback within `SHOW_TIMEOUT` is failed by a watchdog here rather than
## leaving a spinner on screen forever. `last_error` records why, and the
## diagnostics screen prints it.
##
## **There are no interstitials.** Not one. Every ad in this game is rewarded,
## opt-in, and additive: doubling what you already earned, rerolling a stratum
## you already reached. Nothing is taken away to be sold back, nothing
## interrupts play, and the game is complete without watching a single one.
## That is a design decision with a revenue cost, made on purpose -- an idle
## game people keep on their phone for months is worth more than one they
## uninstall in week one.
##
## This service can never move a number the economy reads. It grants rewards by
## emitting a signal; what that signal is worth is decided in game code, and
## `tests/test_monetization.gd` asserts that no path through here changes
## credits, research or cores by itself.

signal reward_granted(placement: String)
signal reward_failed(placement: String, reason: String)
signal availability_changed(available: bool)

## Placements. Each one is additive; none gates content.
## MVP ships only P_DOUBLE_OFFLINE -- see `MVP_PLACEMENTS` below.
const P_DOUBLE_OFFLINE := "double_offline"
const P_REROLL_STRATUM := "reroll_stratum"
const P_EXTRA_BLUEPRINT := "extra_blueprint"

## What the first release actually offers.
##
## Doubling offline earnings is the only placement where the player already
## knows the exact value of the reward before deciding, because the offline
## panel just printed it. That makes it the honest one, and it is also the only
## one whose reward needs no new UI and no new balance argument. The other two
## stay in the code, tested and unreachable, until there is a reason to turn
## them on -- shipping three ad surfaces at once means not knowing which one
## players actually wanted.
const MVP_PLACEMENTS: Array[String] = [P_DOUBLE_OFFLINE]

## A cooldown so the game never feels like it is asking. This is a ceiling on
## how often an ad button can even be offered, not a paywall.
const COOLDOWN_SECONDS := 45.0

## How long a `show_rewarded()` may hang before the watchdog gives up. Real
## rewarded ads run 15-30 seconds, so this has to clear a completed view plus
## the close button; anything past it is a broken SDK, not a slow player.
const SHOW_TIMEOUT := 90.0

## How long a load may hang before availability is written off. The UI simply
## stops offering the button; nothing is shown to the player.
const LOAD_TIMEOUT := 30.0

## The native singletons the Poing AdMob plugin (v5.x) registers. These names
## and the call protocol below are read from the plugin's own GDScript wrapper
## (`addons/admob/gdscript/src`), pinned by `tools/install-plugins.sh`. They are
## bound directly rather than through the wrapper's classes so that this file
## still parses in a build with no addon at all.
const SINGLETON_CORE := "PoingGodotAdMob"
const SINGLETON_REWARDED := "PoingGodotAdMobRewardedAd"
const SINGLETON_CONSENT := "PoingGodotAdMobConsentInformation"
const SINGLETON_UMP := "PoingGodotAdMobUserMessagingPlatform"

## UMP `ConsentInformation.ConsentStatus`.
const CONSENT_UNKNOWN := 0
const CONSENT_NOT_REQUIRED := 1
const CONSENT_REQUIRED := 2
const CONSENT_OBTAINED := 3

## How long to wait for `on_initialization_complete` before loading anyway.
const INIT_GRACE := 10.0
## Backoff after a failed load, so a device with no fill is not hammered.
const LOAD_RETRY_BASE := 20.0
const LOAD_RETRY_MAX := 300.0
## How long after a dismiss a late "earned" callback is still honoured. The
## SDK normally reports the reward first, but the order is not guaranteed, and
## a player who watched to the end must not lose the reward to a race.
const EARN_GRACE := 1.5

var _plugin: Object = null        # PoingGodotAdMob
var _rewarded: Object = null      # PoingGodotAdMobRewardedAd
var _consent: Object = null       # PoingGodotAdMobConsentInformation
var _ump: Object = null           # PoingGodotAdMobUserMessagingPlatform
var _available: bool = false
var _last_shown: float = -9999.0
var _pending: String = ""
var _watched_count: int = 0
var _shown_at: float = -1.0
var _load_started_at: float = -1.0
var _consent_obtained: bool = false
var _consent_status: int = CONSENT_UNKNOWN
var _sdk_started: bool = false
var _sdk_ready: bool = false
var _sdk_started_at: float = -1.0
## uid of the ad being loaded, and of the ad loaded and ready to show.
var _loading_uid: int = -1
var _ad_uid: int = -1
## uid of the ad currently on screen, and whether it has paid out. A reward is
## granted at most once per ad shown, whatever order the callbacks arrive in.
var _showing_uid: int = -1
var _paid_out: bool = false
var _dismissed_at: float = -1.0
var _load_failures: int = 0
var _retry_at: float = -1.0

## The last thing that went wrong, for the on-device diagnostics screen. Empty
## when nothing has.
var last_error: String = ""

## Set by the Store when the player owns the unlock. Ads then stop existing.
var ads_removed: bool = false

## Test hook: pretend a plugin is bound and refuses everything. Used to prove
## the game stays playable when the SDK is present but broken.
var _fake_broken: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_try_bind_plugin()


func _try_bind_plugin() -> void:
	# Absent -- editor, CI, desktop, a build without the addon -- we simply
	# never become available.
	if not Engine.has_singleton(SINGLETON_CORE) \
			or not Engine.has_singleton(SINGLETON_REWARDED):
		_available = false
		last_error = "plugin_absent"
		return
	_bind_plugins(Engine.get_singleton(SINGLETON_CORE),
		Engine.get_singleton(SINGLETON_REWARDED),
		Engine.get_singleton(SINGLETON_CONSENT) if Engine.has_singleton(SINGLETON_CONSENT) else null,
		Engine.get_singleton(SINGLETON_UMP) if Engine.has_singleton(SINGLETON_UMP) else null)


func _bind_plugins(core: Object, rewarded: Object, consent: Object, ump: Object) -> void:
	_plugin = core
	_rewarded = rewarded
	_consent = consent
	_ump = ump
	if _plugin == null or _rewarded == null:
		_available = false
		last_error = "singleton_null"
		return
	_bind(_plugin, "on_initialization_complete", _on_init_complete)
	_bind(_rewarded, "on_rewarded_ad_loaded", _on_loaded)
	_bind(_rewarded, "on_rewarded_ad_failed_to_load", _on_load_failed)
	_bind(_rewarded, "on_rewarded_ad_user_earned_reward", _on_earned)
	_bind(_rewarded, "on_rewarded_ad_dismissed_full_screen_content", _on_dismissed)
	_bind(_rewarded, "on_rewarded_ad_failed_to_show_full_screen_content", _on_show_failed)
	if _consent != null:
		_bind(_consent, "on_consent_info_updated_success", _on_consent_updated)
		_bind(_consent, "on_consent_info_updated_failure", _on_consent_update_failed)
	if _ump != null:
		_bind(_ump, "on_consent_form_load_success_listener", _on_consent_form_loaded)
		_bind(_ump, "on_consent_form_load_failure_listener", _on_consent_form_failed)
		_bind(_ump, "on_consent_form_dismissed", _on_consent_form_dismissed)
		_bind(_ump, "on_privacy_options_form_dismissed_listener", _on_privacy_form_dismissed)
	# UMP first: under GDPR the ad SDK must not request ads before consent is
	# settled, and the player must be able to withdraw it later --
	# `show_privacy_options()` below is that second half.
	_request_consent()


func _bind(obj: Object, sig: String, target: Callable) -> void:
	if obj != null and obj.has_signal(sig) and not obj.is_connected(sig, target):
		obj.connect(sig, target)


## Every call into a native singleton goes through here. A plugin missing a
## method it had in another version must degrade to "no ad", not to a crash on
## a player's phone.
func _call(obj: Object, method: String, args: Array = []) -> Variant:
	if obj == null or _fake_broken:
		return null
	if not obj.has_method(method):
		last_error = "missing_method:" + method
		return null
	return obj.callv(method, args)


func _has(obj: Object, method: String) -> bool:
	return obj != null and not _fake_broken and obj.has_method(method)


## --- consent (UMP) -----------------------------------------------------------

func _request_consent() -> void:
	if not _has(_consent, "update"):
		# No consent API: the SDK's own defaults apply and consent is reported
		# as unresolved, never as granted.
		_consent_obtained = false
		_start_sdk()
		return
	_call(_consent, "update", [{
		"tag_for_under_age_of_consent": false,
		"consent_debug_settings": null,
	}])


func _on_consent_updated() -> void:
	_consent_status = _read_consent_status()
	if _consent_status == CONSENT_REQUIRED and _has(_ump, "load_consent_form") \
			and bool(_call(_consent, "get_is_consent_form_available")):
		_call(_ump, "load_consent_form")
		return
	_consent_settled()


func _on_consent_update_failed(_err: Variant = null) -> void:
	# Google's guidance: a failed update is not a refusal. Whatever consent was
	# stored last session still applies, so carry on and let the SDK decide.
	last_error = "consent_update_failed"
	_consent_settled()


func _on_consent_form_loaded(uid: Variant = null) -> void:
	_call(_ump, "show", [int(uid)])


func _on_consent_form_failed(_err: Variant = null) -> void:
	last_error = "consent_form_failed"
	_consent_settled()


func _on_consent_form_dismissed(_uid: Variant = null, _err: Variant = null) -> void:
	_consent_settled()


func _on_privacy_form_dismissed(_err: Variant = null) -> void:
	_consent_status = _read_consent_status()
	_consent_obtained = _consent_status == CONSENT_OBTAINED \
		or _consent_status == CONSENT_NOT_REQUIRED


func _read_consent_status() -> int:
	var v: Variant = _call(_consent, "get_consent_status")
	return int(v) if v != null else CONSENT_UNKNOWN


func _consent_settled() -> void:
	_consent_status = _read_consent_status()
	_consent_obtained = _consent_status == CONSENT_OBTAINED \
		or _consent_status == CONSENT_NOT_REQUIRED
	_start_sdk()


## The GDPR withdrawal path. Wired to a button in the game's own settings, so
## consent can be changed after the first launch without reinstalling.
func show_privacy_options() -> bool:
	if not _has(_ump, "show_privacy_options_form"):
		return false
	_call(_ump, "show_privacy_options_form")
	return true


func consent_obtained() -> bool:
	return _consent_obtained


## --- SDK start and loading ---------------------------------------------------

func _start_sdk() -> void:
	if _sdk_started:
		_load_next()
		return
	_sdk_started = true
	_sdk_started_at = _now()
	_call(_plugin, "initialize")


func _on_init_complete(_status: Variant = null) -> void:
	_sdk_ready = true
	_sdk_started_at = -1.0
	_load_next()


func _load_next() -> void:
	if _plugin == null or ads_removed or _fake_broken:
		return
	if not _sdk_ready:
		return
	if _ad_uid >= 0 or _loading_uid >= 0:
		return
	var unit: String = MonetizationDB.ad_unit_for(MonetizationDB.AD_DOUBLE_OFFLINE)
	if unit == "":
		# A release build with no live unit configured: offer nothing.
		last_error = "no_ad_unit"
		_set_available(false)
		return
	var uid: Variant = _call(_rewarded, "create")
	if uid == null:
		_set_available(false)
		return
	_loading_uid = int(uid)
	_load_started_at = _now()
	var request: Dictionary = {
		"mediation_extras": {},
		"extras": {},
		"google_request_agent": "Godot-PoingStudios-Lodeworks",
	}
	_call(_rewarded, "load", [unit, request, PackedStringArray(), _loading_uid])


func _on_loaded(uid: Variant = null) -> void:
	if int(uid) != _loading_uid:
		return
	_ad_uid = _loading_uid
	_loading_uid = -1
	_load_started_at = -1.0
	_load_failures = 0
	last_error = ""
	_set_available(true)


func _on_load_failed(uid: Variant = null, err: Variant = null) -> void:
	if int(uid) != _loading_uid:
		return
	_loading_uid = -1
	_load_started_at = -1.0
	last_error = "load_failed:" + _error_text(err)
	_set_available(false)
	_schedule_retry()


func _schedule_retry() -> void:
	_load_failures += 1
	_retry_at = _now() + minf(LOAD_RETRY_BASE * pow(2.0, float(_load_failures - 1)),
		LOAD_RETRY_MAX)


func _error_text(err: Variant) -> String:
	if typeof(err) == TYPE_DICTIONARY:
		var d: Dictionary = err
		return "%s %s" % [str(d.get("code", "")), str(d.get("message", ""))]
	return str(err)


## --- showing -----------------------------------------------------------------

func _finish_show() -> void:
	if _showing_uid >= 0:
		_call(_rewarded, "destroy", [_showing_uid])
	_showing_uid = -1
	_pending = ""
	_shown_at = -1.0
	_dismissed_at = -1.0


func _on_show_failed(uid: Variant = null, err: Variant = null) -> void:
	if int(uid) != _showing_uid:
		return
	var placement: String = _pending
	var paid: bool = _paid_out
	_finish_show()
	last_error = "show_failed:" + _error_text(err)
	_set_available(false)
	if placement != "" and not paid:
		reward_failed.emit(placement, "show_failed")
	_load_next()


## Closed. If the SDK never said the reward was earned, the player closed it
## early: no reward, no complaint, no retry prompt.
func _on_dismissed(uid: Variant = null) -> void:
	if int(uid) != _showing_uid:
		return
	_set_available(false)
	if _paid_out or _pending == "":
		_finish_show()
		_load_next()
		return
	# Not paid yet. Give a late reward callback a moment before calling it an
	# early close; `_process` settles it either way.
	_shown_at = -1.0
	_dismissed_at = _now()


func _settle_dismiss() -> void:
	var placement: String = _pending
	var paid: bool = _paid_out
	_finish_show()
	if placement != "" and not paid:
		reward_failed.emit(placement, "dismissed")
	_load_next()


## The only path that grants. The SDK calls it when the video has played far
## enough to earn the reward -- which can be before or after the dismiss
## callback -- and it pays out once per ad shown, however often it fires.
func _on_earned(uid: Variant = null, _item: Variant = null) -> void:
	if int(uid) != _showing_uid or _paid_out or _pending == "":
		return
	_paid_out = true
	var placement: String = _pending
	_watched_count += 1
	_last_shown = _now()
	Analytics.track("rewarded_completed", {"placement": placement,
		"count": _watched_count})
	reward_granted.emit(placement)
	if _dismissed_at > 0.0:
		# The reward arrived after the close: the show is over.
		_finish_show()
		_load_next()


func _set_available(v: bool) -> void:
	if _available == v:
		return
	_available = v
	availability_changed.emit(v)


## The watchdog. Nothing here talks to the plugin -- it only decides that the
## plugin has stopped talking to us, and hands the UI back to the player.
func _process(_delta: float) -> void:
	var t: float = _now()
	if _shown_at > 0.0 and t - _shown_at > SHOW_TIMEOUT:
		var placement: String = _pending
		var paid: bool = _paid_out
		_finish_show()
		last_error = "show_timeout"
		_set_available(false)
		if placement != "" and not paid:
			reward_failed.emit(placement, "timeout")
		_load_next()
	if _load_started_at > 0.0 and t - _load_started_at > LOAD_TIMEOUT:
		_load_started_at = -1.0
		_loading_uid = -1
		last_error = "load_timeout"
		_set_available(false)
		_schedule_retry()
	if _sdk_started_at > 0.0 and t - _sdk_started_at > INIT_GRACE:
		# The SDK never said it finished initialising. Loading still works on
		# every SDK version this plugin wraps; waiting forever does not.
		_on_init_complete()
	if _retry_at > 0.0 and t >= _retry_at:
		_retry_at = -1.0
		_load_next()
	if _dismissed_at > 0.0 and t - _dismissed_at > EARN_GRACE:
		_settle_dismiss()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func cooldown_remaining() -> float:
	return maxf(0.0, COOLDOWN_SECONDS - (_now() - _last_shown))


## Whether a rewarded button should even be drawn. A button that is shown and
## then fails is worse than a button that was never shown.
func can_offer(placement: String) -> bool:
	if ads_removed:
		return false
	if not MVP_PLACEMENTS.has(placement):
		return false
	if _pending != "":
		return false
	if cooldown_remaining() > 0.0:
		return false
	return _available


func is_plugin_present() -> bool:
	return _plugin != null


func watched_count() -> int:
	return _watched_count


## Everything the on-device diagnostics screen needs to say whether the ad
## layer is actually working, in the one place where that can be checked: a
## real phone with a real network and a real AdMob account.
func status() -> Dictionary:
	return {
		"plugin_present": is_plugin_present(),
		"available": _available,
		"consent": _consent_obtained,
		"ads_removed": ads_removed,
		"watched": _watched_count,
		"pending": _pending,
		"cooldown": cooldown_remaining(),
		"last_error": last_error,
		"placements": MVP_PLACEMENTS,
		"sdk_ready": _sdk_ready,
		"consent_status": _consent_status,
		"ad_loaded": _ad_uid >= 0,
		"unit": MonetizationDB.ad_unit_for(MonetizationDB.AD_DOUBLE_OFFLINE),
	}


## Show a rewarded ad. Returns false immediately if one cannot be shown, and
## in that case nothing is charged and no reward is granted.
func show_rewarded(placement: String) -> bool:
	if not can_offer(placement):
		reward_failed.emit(placement, "unavailable")
		return false
	if not _has(_rewarded, "show") or _ad_uid < 0:
		last_error = "no_show_method"
		reward_failed.emit(placement, "no_plugin")
		return false
	_pending = placement
	_paid_out = false
	_showing_uid = _ad_uid
	_ad_uid = -1
	_shown_at = _now()
	_set_available(false)
	Analytics.track("rewarded_shown", {"placement": placement})
	_call(_rewarded, "show", [_showing_uid])
	return true


## --- test and editor hooks -------------------------------------------------
##
## Both are guarded to debug builds, so neither exists in a shipping binary.

func debug_grant(placement: String) -> void:
	if not OS.is_debug_build():
		return
	_pending = placement
	_showing_uid = 0
	_paid_out = false
	_on_earned(0)
	_finish_show()


## Bind stand-in singletons that speak the plugin's protocol, so the tests
## drive the real binding code rather than a shortcut around it.
func debug_bind(core: Object, rewarded: Object, consent: Object = null,
		ump: Object = null) -> void:
	if not OS.is_debug_build():
		return
	debug_unbind()
	_bind_plugins(core, rewarded, consent, ump)


func debug_unbind() -> void:
	if not OS.is_debug_build():
		return
	for obj: Object in [_plugin, _rewarded, _consent, _ump]:
		if obj == null:
			continue
		for sig: Dictionary in obj.get_signal_list():
			for conn: Dictionary in obj.get_signal_connection_list(String(sig["name"])):
				var cb: Callable = conn["callable"]
				if cb.get_object() == self:
					obj.disconnect(String(sig["name"]), cb)
	_plugin = null
	_rewarded = null
	_consent = null
	_ump = null
	_available = false
	_pending = ""
	_shown_at = -1.0
	_load_started_at = -1.0
	_sdk_started = false
	_sdk_ready = false
	_sdk_started_at = -1.0
	_loading_uid = -1
	_ad_uid = -1
	_showing_uid = -1
	_paid_out = false
	_dismissed_at = -1.0
	_load_failures = 0
	_retry_at = -1.0
	_last_shown = -9999.0
	_consent_obtained = false
	_consent_status = CONSENT_UNKNOWN
	last_error = "plugin_absent"


## Advance the retry and watchdog clocks in a test without waiting for them.
func debug_expire_timers() -> void:
	if not OS.is_debug_build():
		return
	if _retry_at > 0.0:
		_retry_at = _now() - 1.0
	if _sdk_started_at > 0.0:
		_sdk_started_at = _now() - INIT_GRACE - 1.0
	if _dismissed_at > 0.0:
		_dismissed_at = _now() - EARN_GRACE - 1.0
	_last_shown = -9999.0
	_process(0.0)


## Simulate the worst realistic failure: a plugin that binds and then does
## nothing. Used by the test suite to prove the game stays playable.
func debug_set_broken(broken: bool) -> void:
	if not OS.is_debug_build():
		return
	set_broken(broken)


## The same switch, available in a release build, because the diagnostics
## screen on a real phone is the only place the claim "the game is fine when
## the ad SDK dies" can actually be demonstrated. It is reachable only from
## that screen, it never grants anything, and it resets when the screen
## closes -- the worst a player can do with it is turn their own ads off.
func set_broken(broken: bool) -> void:
	_fake_broken = broken
	if broken:
		_set_available(false)
		last_error = "simulated_broken_sdk"
	else:
		last_error = ""
		_load_next()


func debug_set_break_on_device(broken: bool) -> void:
	set_broken(broken)
