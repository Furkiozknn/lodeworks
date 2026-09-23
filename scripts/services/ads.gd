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
## call to the plugin goes through `_safe_call`, and a show that produces no
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

var _plugin: Object = null
var _available: bool = false
var _last_shown: float = -9999.0
var _pending: String = ""
var _watched_count: int = 0
var _shown_at: float = -1.0
var _load_started_at: float = -1.0
var _consent_obtained: bool = false

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
	# The AdMob addon registers a singleton when the native plugin is present.
	# Absent -- editor, CI, desktop build -- we simply never become available.
	if not Engine.has_singleton("AdMob"):
		_available = false
		last_error = "plugin_absent"
		return
	_plugin = Engine.get_singleton("AdMob")
	if _plugin == null:
		_available = false
		last_error = "singleton_null"
		return
	_connect_plugin()


func _connect_plugin() -> void:
	if _plugin == null:
		return
	# Signal names differ across plugin majors, so bind defensively rather
	# than assuming a version. A missing signal must not take the game down.
	_bind(["rewarded_ad_loaded", "on_rewarded_ad_loaded"], _on_loaded)
	_bind(["user_earned_rewarded", "on_user_earned_reward"], _on_earned)
	_bind(["rewarded_ad_failed_to_load", "on_rewarded_ad_failed_to_load"], _on_load_failed)
	_bind(["rewarded_ad_dismissed", "on_rewarded_ad_dismissed_full_screen_content"],
		_on_dismissed)
	_bind(["rewarded_ad_failed_to_show", "on_rewarded_ad_failed_to_show_full_screen_content"],
		_on_show_failed)
	# UMP consent, where the plugin provides it. Under GDPR the ad SDK must not
	# personalise before consent, and the player must be able to withdraw it
	# later -- `show_privacy_options()` below is that second half, and it is the
	# step most implementations skip.
	_bind(["consent_form_dismissed", "on_consent_form_dismissed"], _on_consent_settled)
	_bind(["consent_info_updated", "on_consent_info_update_success"], _on_consent_settled)
	_safe_call("initialize")
	_request_consent()
	_load_next()


func _bind(names: Array, target: Callable) -> void:
	for sig: String in names:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, target):
			_plugin.connect(sig, target)


## Every call into the native plugin goes through here. A plugin that is
## missing a method it had in the previous major must degrade to "no ad", not
## to a crash on a player's phone.
func _safe_call(method: String, arg: Variant = null) -> bool:
	if _plugin == null or _fake_broken:
		return false
	if not _plugin.has_method(method):
		last_error = "missing_method:" + method
		return false
	if arg == null:
		_plugin.call(method)
	else:
		_plugin.call(method, arg)
	return true


func _request_consent() -> void:
	# Both spellings exist across plugin versions; whichever answers, answers.
	if _safe_call("request_consent_info_update"):
		return
	if _safe_call("load_consent_form"):
		return
	# No consent API exposed: treat consent as unresolved rather than granted,
	# and let the SDK's own defaults apply.
	_consent_obtained = false


func _on_consent_settled(_a = null, _b = null) -> void:
	_consent_obtained = true
	_load_next()


## The GDPR withdrawal path. Wired to a button in the game's own settings, so
## consent can be changed after the first launch without reinstalling.
func show_privacy_options() -> bool:
	if _safe_call("show_privacy_options_form"):
		return true
	return _safe_call("show_consent_form")


func consent_obtained() -> bool:
	return _consent_obtained


func _load_next() -> void:
	if _plugin == null or ads_removed:
		return
	_load_started_at = _now()
	if not _safe_call("load_rewarded"):
		_load_started_at = -1.0
		_set_available(false)


func _on_loaded(_a = null) -> void:
	_load_started_at = -1.0
	last_error = ""
	_set_available(true)


func _on_load_failed(a = null, _b = null) -> void:
	_load_started_at = -1.0
	last_error = "load_failed:" + str(a)
	_set_available(false)


func _on_show_failed(a = null, _b = null) -> void:
	var placement: String = _pending
	_pending = ""
	_shown_at = -1.0
	last_error = "show_failed:" + str(a)
	_set_available(false)
	if placement != "":
		reward_failed.emit(placement, "show_failed")
	_load_next()


## Dismissed without earning: the player closed the ad early. No reward, no
## complaint, no retry prompt.
func _on_dismissed(_a = null) -> void:
	var placement: String = _pending
	_pending = ""
	_shown_at = -1.0
	_set_available(false)
	if placement != "":
		reward_failed.emit(placement, "dismissed")
	_load_next()


func _on_earned(_a = null, _b = null) -> void:
	var placement: String = _pending
	_pending = ""
	_shown_at = -1.0
	_watched_count += 1
	_last_shown = _now()
	_set_available(false)
	Analytics.track("rewarded_completed", {"placement": placement,
		"count": _watched_count})
	reward_granted.emit(placement)
	_load_next()


func _set_available(v: bool) -> void:
	if _available == v:
		return
	_available = v
	availability_changed.emit(v)


## The watchdog. Nothing here talks to the plugin -- it only decides that the
## plugin has stopped talking to us, and hands the UI back to the player.
func _process(_delta: float) -> void:
	if _shown_at > 0.0 and _now() - _shown_at > SHOW_TIMEOUT:
		var placement: String = _pending
		_pending = ""
		_shown_at = -1.0
		last_error = "show_timeout"
		_set_available(false)
		if placement != "":
			reward_failed.emit(placement, "timeout")
		_load_next()
	if _load_started_at > 0.0 and _now() - _load_started_at > LOAD_TIMEOUT:
		_load_started_at = -1.0
		last_error = "load_timeout"
		_set_available(false)


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
	}


## Show a rewarded ad. Returns false immediately if one cannot be shown, and
## in that case nothing is charged and no reward is granted.
func show_rewarded(placement: String) -> bool:
	if not can_offer(placement):
		reward_failed.emit(placement, "unavailable")
		return false
	_pending = placement
	_shown_at = _now()
	Analytics.track("rewarded_shown", {"placement": placement})
	if _safe_call("show_rewarded"):
		return true
	_pending = ""
	_shown_at = -1.0
	last_error = "no_show_method"
	reward_failed.emit(placement, "no_plugin")
	return false


## --- test and editor hooks -------------------------------------------------
##
## Both are guarded to debug builds, so neither exists in a shipping binary.

func debug_grant(placement: String) -> void:
	if not OS.is_debug_build():
		return
	_pending = placement
	_on_earned()


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
