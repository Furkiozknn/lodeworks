extends Node

## In-app purchases: exactly one product.
##
## "Foreman's Licence" is a single non-consumable that removes ads and adds
## quality of life. It does not add content, does not add power that cannot be
## earned, and does not gate any stratum, machine or upgrade. Someone who never
## pays can reach the deepest stratum in the game.
##
## One product, bought once, is also the only model a solo developer can
## actually operate: no catalogue to balance, no sale calendar, no currency
## packs, no receipts to reconcile beyond what the platform already does.
##
## Like the ad layer, this runs with no billing plugin present -- the editor,
## CI and desktop builds simply report "not available", and the game is whole
## without it.

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restored()
signal availability_changed(available: bool)

const LICENCE := "foremans_licence"

## What the licence actually gives. Deliberately all convenience: more offline
## banking, more blueprint slots, no ads, and a cosmetic set.
const LICENCE_OFFLINE_HOURS := 4.0
const LICENCE_BLUEPRINT_SLOTS := 2

const OWNED_PATH := "user://entitlements.json"

var _plugin: Object = null
var _available: bool = false
var _owned: Dictionary = {}
var _price_text: String = ""


func _ready() -> void:
	_load_owned()
	_apply()
	_try_bind_plugin()


func _try_bind_plugin() -> void:
	for name in ["GodotGooglePlayBilling", "GooglePlayBilling", "StoreKit"]:
		if Engine.has_singleton(name):
			_plugin = Engine.get_singleton(name)
			break
	if _plugin == null:
		_available = false
		return
	for sig in ["purchases_updated", "on_purchases_updated"]:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, _on_purchases_updated):
			_plugin.connect(sig, _on_purchases_updated)
	for sig in ["purchase_error", "on_purchase_error"]:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, _on_purchase_error):
			_plugin.connect(sig, _on_purchase_error)
	if _plugin.has_method("startConnection"):
		_plugin.call("startConnection")
	_available = true
	availability_changed.emit(true)


## --- entitlement state -----------------------------------------------------
##
## Ownership is cached locally so the game works offline, which for an offline
## game is not optional. The cache is a convenience, not the source of truth:
## `restore()` re-reads the platform, and a wrong local cache can only ever
## grant convenience features, never content or currency. That bounds what a
## tampered file can do to a rounding error on offline banking.

func _load_owned() -> void:
	if not FileAccess.file_exists(OWNED_PATH):
		return
	var f := FileAccess.open(OWNED_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_owned = parsed


func _save_owned() -> void:
	var f := FileAccess.open(OWNED_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_owned))
	f.close()


func _apply() -> void:
	Ads.ads_removed = owns(LICENCE)


func owns(product_id: String) -> bool:
	return bool(_owned.get(product_id, false))


func has_licence() -> bool:
	return owns(LICENCE)


func bonus_offline_hours() -> float:
	return LICENCE_OFFLINE_HOURS if has_licence() else 0.0


func bonus_blueprint_slots() -> int:
	return LICENCE_BLUEPRINT_SLOTS if has_licence() else 0


func is_available() -> bool:
	return _available and _plugin != null


## The platform's localised price string. Never hardcode a price in the UI --
## it is wrong in most of the world and against store guidelines besides.
func price_text() -> String:
	return _price_text if _price_text != "" else ""


## --- purchase flow ---------------------------------------------------------

func purchase(product_id: String = LICENCE) -> bool:
	if owns(product_id):
		return true
	if not is_available():
		purchase_failed.emit(product_id, "unavailable")
		return false
	Analytics.track("iap_started", {"product": product_id})
	if _plugin.has_method("purchase"):
		_plugin.call("purchase", product_id)
		return true
	purchase_failed.emit(product_id, "no_method")
	return false


func restore() -> void:
	if not is_available():
		return
	if _plugin.has_method("queryPurchases"):
		_plugin.call("queryPurchases", "inapp")
	Analytics.track("iap_restore")


func _grant(product_id: String) -> void:
	if owns(product_id):
		return
	_owned[product_id] = true
	_save_owned()
	_apply()
	Analytics.track("iap_purchased", {"product": product_id})
	purchase_completed.emit(product_id)


func _on_purchases_updated(purchases: Variant = null) -> void:
	if typeof(purchases) != TYPE_ARRAY:
		return
	var any: bool = false
	for p: Variant in purchases:
		var id: String = ""
		if typeof(p) == TYPE_DICTIONARY:
			# Plugin majors disagree on the key name; accept both rather than
			# silently failing to grant something someone paid for.
			id = String(p.get("product_id", p.get("sku", "")))
		elif typeof(p) == TYPE_STRING:
			id = String(p)
		if id != "":
			_grant(id)
			any = true
	if any:
		restored.emit()


func _on_purchase_error(code: Variant = null, msg: Variant = null) -> void:
	Analytics.track("iap_failed", {"code": str(code)})
	purchase_failed.emit(LICENCE, str(msg))


## Test/editor hook. Guarded to debug builds so it can never be reached in a
## shipping binary.
func debug_grant(product_id: String = LICENCE) -> void:
	if not OS.is_debug_build():
		return
	_grant(product_id)


func debug_revoke() -> void:
	if not OS.is_debug_build():
		return
	_owned.clear()
	_save_owned()
	_apply()
