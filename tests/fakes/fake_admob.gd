extends Object

## Stand-ins for the four JNI singletons the Poing AdMob plugin (5.1.0)
## registers, speaking the protocol its GDScript wrapper uses
## (`addons/admob/gdscript/src/api` and `.../ump/api`). One object plays all
## four parts; the game binds the same object four times, which is harmless
## because every signal name is distinct.

# PoingGodotAdMob
signal on_initialization_complete(status: Dictionary)
# PoingGodotAdMobRewardedAd
signal on_rewarded_ad_loaded(uid: int)
signal on_rewarded_ad_failed_to_load(uid: int, error: Dictionary)
signal on_rewarded_ad_user_earned_reward(uid: int, item: Dictionary)
signal on_rewarded_ad_dismissed_full_screen_content(uid: int)
signal on_rewarded_ad_failed_to_show_full_screen_content(uid: int, error: Dictionary)
signal on_rewarded_ad_showed_full_screen_content(uid: int)
# PoingGodotAdMobConsentInformation
signal on_consent_info_updated_success
signal on_consent_info_updated_failure(error: Dictionary)
# PoingGodotAdMobUserMessagingPlatform
signal on_consent_form_load_success_listener(uid: int)
signal on_consent_form_load_failure_listener(error: Dictionary)
signal on_consent_form_dismissed(uid: int, error: Dictionary)
signal on_privacy_options_form_dismissed_listener(error: Dictionary)

var calls: Array = []
var _next_uid: int = 0
var consent_status: int = 1          # NOT_REQUIRED
var form_available: bool = false


func _log(m: String, args: Array = []) -> void:
	calls.append([m, args])


func count(m: String) -> int:
	var n: int = 0
	for c: Array in calls:
		if c[0] == m:
			n += 1
	return n


func last_args(m: String) -> Array:
	for i in range(calls.size() - 1, -1, -1):
		if calls[i][0] == m:
			return calls[i][1]
	return []


func index_of(m: String) -> int:
	for i in range(calls.size()):
		if calls[i][0] == m:
			return i
	return -1


# --- PoingGodotAdMob ---
func initialize() -> void:
	_log("initialize")


# --- PoingGodotAdMobRewardedAd ---
func create() -> int:
	_next_uid += 1
	_log("create")
	return _next_uid


func load(ad_unit_id: String, ad_request: Dictionary, keywords: PackedStringArray,
		uid: int) -> void:
	_log("load", [ad_unit_id, ad_request, keywords, uid])


func show(uid: int) -> void:
	_log("show", [uid])


func destroy(uid: int) -> void:
	_log("destroy", [uid])


# --- PoingGodotAdMobConsentInformation ---
func update(consent_request: Dictionary) -> void:
	_log("update", [consent_request])


func get_consent_status() -> int:
	return consent_status


func get_is_consent_form_available() -> bool:
	return form_available


# --- PoingGodotAdMobUserMessagingPlatform ---
func load_consent_form() -> void:
	_log("load_consent_form")


func show_privacy_options_form() -> void:
	_log("show_privacy_options_form")
