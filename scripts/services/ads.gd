extends Node

## Rewarded video, behind an interface that works with no ad SDK installed.
##
## Two things this file is trying to get right.
##
## **It must run without the plugin.** The AdMob plugin is a native Android/iOS
## addon; it does not exist in the editor, in CI, or in a headless test run. So
## every call goes through here, and here degrades to a no-op that reports "no
## ad available" rather than crashing. That means the game is always playable
## and always testable, and the ad layer can be added or removed without
## touching a single line of game logic.
##
## **There are no interstitials.** Not one. Every ad in this game is rewarded,
## opt-in, and gives something additive: doubling what you already earned,
## rerolling a stratum you already reached. Nothing is taken away to be sold
## back, nothing interrupts play, and the game is complete without watching a
## single one. That is a design decision with a revenue cost and it is made on
## purpose -- an idle game people keep on their phone for months is worth more
## than one they uninstall in week one.

signal reward_granted(placement: String)
signal reward_failed(placement: String, reason: String)
signal availability_changed(available: bool)

## Placements. Each one is additive; none gates content.
const P_DOUBLE_OFFLINE := "double_offline"
const P_REROLL_STRATUM := "reroll_stratum"
const P_EXTRA_BLUEPRINT := "extra_blueprint"

## A cooldown so the game never feels like it is asking. This is a ceiling on
## how often an ad button can even be offered, not a paywall.
const COOLDOWN_SECONDS := 45.0

var _plugin: Object = null
var _available: bool = false
var _last_shown: float = -9999.0
var _pending: String = ""
var _watched_count: int = 0

## Set by the Store when the player owns the unlock. Ads then stop existing.
var ads_removed: bool = false


func _ready() -> void:
	_try_bind_plugin()


func _try_bind_plugin() -> void:
	# The AdMob addon registers a singleton when the native plugin is present.
	# Absent -- editor, CI, desktop build -- we simply never become available.
	if Engine.has_singleton("AdMob"):
		_plugin = Engine.get_singleton("AdMob")
		_connect_plugin()
	else:
		_available = false


func _connect_plugin() -> void:
	if _plugin == null:
		return
	# Signal names differ across plugin majors, so bind defensively rather
	# than assuming a version. A missing signal must not take the game down.
	for sig in ["rewarded_ad_loaded", "on_rewarded_ad_loaded"]:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, _on_loaded):
			_plugin.connect(sig, _on_loaded)
	for sig in ["user_earned_rewarded", "on_user_earned_reward"]:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, _on_earned):
			_plugin.connect(sig, _on_earned)
	for sig in ["rewarded_ad_failed_to_load", "on_rewarded_ad_failed_to_load"]:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, _on_load_failed):
			_plugin.connect(sig, _on_load_failed)
	_load_next()


func _load_next() -> void:
	if _plugin == null or ads_removed:
		return
	if _plugin.has_method("load_rewarded"):
		_plugin.call("load_rewarded")


func _on_loaded(_a = null) -> void:
	_available = true
	availability_changed.emit(true)


func _on_load_failed(_a = null, _b = null) -> void:
	_available = false
	availability_changed.emit(false)


func _on_earned(_a = null, _b = null) -> void:
	var placement: String = _pending
	_pending = ""
	_watched_count += 1
	_last_shown = _now()
	_available = false
	availability_changed.emit(false)
	Analytics.track("rewarded_completed", {"placement": placement,
		"count": _watched_count})
	reward_granted.emit(placement)
	_load_next()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func cooldown_remaining() -> float:
	return maxf(0.0, COOLDOWN_SECONDS - (_now() - _last_shown))


## Whether a rewarded button should even be drawn. A button that is shown and
## then fails is worse than a button that was never shown.
func can_offer(_placement: String) -> bool:
	if ads_removed:
		return false
	if cooldown_remaining() > 0.0:
		return false
	return _available


func is_plugin_present() -> bool:
	return _plugin != null


func watched_count() -> int:
	return _watched_count


## Show a rewarded ad. Returns false immediately if one cannot be shown, and
## in that case nothing is charged and no reward is granted.
func show_rewarded(placement: String) -> bool:
	if not can_offer(placement):
		reward_failed.emit(placement, "unavailable")
		return false
	_pending = placement
	Analytics.track("rewarded_requested", {"placement": placement})
	if _plugin != null and _plugin.has_method("show_rewarded"):
		_plugin.call("show_rewarded")
		return true
	_pending = ""
	reward_failed.emit(placement, "no_plugin")
	return false


## Used by tests and by the editor so the reward paths can be exercised without
## a native plugin. Never called from shipping game code.
func debug_grant(placement: String) -> void:
	if not OS.is_debug_build():
		return
	_pending = placement
	_on_earned()
