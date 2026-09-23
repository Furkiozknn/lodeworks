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
## CI and desktop builds report "not available", and the game is whole without
## it. Every call into the native plugin goes through `_safe_call`, so a plugin
## that binds and then misbehaves produces a failed purchase, not a crash.
##
## **Nothing here can move a number the economy reads.** The licence grants
## offline hours and blueprint slots and removes ads; it adds no credits, no
## research and no cores, and `tests/test_monetization.gd` asserts that a
## licensed and an unlicensed player produce byte-identical economy state from
## the same inputs.

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restored()
signal availability_changed(available: bool)
signal product_details_changed()

const LICENCE := "foremans_licence"

## What the licence actually gives. Deliberately all convenience: more offline
## banking and more blueprint slots, plus no ads.
const LICENCE_OFFLINE_HOURS := 4.0
const LICENCE_BLUEPRINT_SLOTS := 2

const OWNED_PATH := "user://entitlements.json"

## How long the platform may take to answer a product-details query before the
## UI stops claiming a purchase is possible.
const DETAILS_TIMEOUT := 20.0

var _plugin: Object = null
var _available: bool = false
var _owned: Dictionary = {}
var _price_text: String = ""
## True only once the store has confirmed this product exists and is sellable
## on this device. Until then the buy button is not drawn -- a purchase button
## that fails is worse than no button, and "the code calls purchase()" is not
## the same claim as "the product is purchasable".
var _product_confirmed: bool = false
var _details_requested_at: float = -1.0
var _purchase_in_flight: bool = false

var last_error: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_owned()
	_apply()
	_try_bind_plugin()


func _try_bind_plugin() -> void:
	for n: String in ["GodotGooglePlayBilling", "GooglePlayBilling", "StoreKit"]:
		if Engine.has_singleton(n):
			_plugin = Engine.get_singleton(n)
			break
	if _plugin == null:
		_available = false
		last_error = "plugin_absent"
		return
	_bind(["purchases_updated", "on_purchases_updated"], _on_purchases_updated)
	_bind(["purchase_error", "on_purchase_error"], _on_purchase_error)
	_bind(["connected", "on_connected"], _on_connected)
	_bind(["disconnected", "on_disconnected"], _on_disconnected)
	_bind(["product_details_query_completed", "sku_details_query_completed",
		"on_query_product_details_response"], _on_details)
	_bind(["product_details_query_error", "sku_details_query_error"], _on_details_error)
	if not _safe_call("startConnection"):
		_safe_call("start_connection")
	_available = true
	availability_changed.emit(true)


func _bind(names: Array, target: Callable) -> void:
	for sig: String in names:
		if _plugin.has_signal(sig) and not _plugin.is_connected(sig, target):
			_plugin.connect(sig, target)


func _safe_call(method: String, a: Variant = null, b: Variant = null) -> bool:
	if _plugin == null:
		return false
	if not _plugin.has_method(method):
		return false
	if a == null:
		_plugin.call(method)
	elif b == null:
		_plugin.call(method, a)
	else:
		_plugin.call(method, a, b)
	return true


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _on_connected(_a = null) -> void:
	last_error = ""
	query_product_details()
	restore()


func _on_disconnected(_a = null) -> void:
	_product_confirmed = false
	last_error = "billing_disconnected"
	availability_changed.emit(false)


## Ask the store what this product is called and what it costs here. Until it
## answers, the game does not claim the product can be bought.
func query_product_details() -> void:
	if _plugin == null:
		return
	_details_requested_at = _now()
	if _safe_call("queryProductDetails", [LICENCE], "inapp"):
		return
	if _safe_call("querySkuDetails", [LICENCE], "inapp"):
		return
	if _safe_call("query_product_details", [LICENCE]):
		return
	_details_requested_at = -1.0
	last_error = "no_details_method"


func _on_details(details: Variant = null) -> void:
	_details_requested_at = -1.0
	var found: bool = false
	if typeof(details) == TYPE_ARRAY:
		for d: Variant in details:
			if typeof(d) != TYPE_DICTIONARY:
				continue
			var id: String = String(d.get("product_id", d.get("productId",
				d.get("sku", ""))))
			if id != LICENCE:
				continue
			found = true
			_price_text = _extract_price(d)
	elif typeof(details) == TYPE_DICTIONARY:
		found = true
		_price_text = _extract_price(details)
	_product_confirmed = found
	if not found:
		last_error = "product_not_in_store"
	product_details_changed.emit()


## Prices arrive under different keys depending on the billing library major
## and on whether the product is one-time or subscription-shaped. Whatever the
## platform hands back is what gets shown; nothing is composed locally.
func _extract_price(d: Dictionary) -> String:
	for k: String in ["formatted_price", "formattedPrice", "price",
			"one_time_purchase_offer_formatted_price"]:
		if d.has(k):
			var v: String = String(d[k])
			if v != "":
				return v
	var offer: Variant = d.get("one_time_purchase_offer_details", null)
	if typeof(offer) == TYPE_DICTIONARY:
		return String((offer as Dictionary).get("formatted_price", ""))
	return ""


func _on_details_error(a = null, _b = null) -> void:
	_details_requested_at = -1.0
	_product_confirmed = false
	last_error = "details_error:" + str(a)
	product_details_changed.emit()


func _process(_delta: float) -> void:
	if _details_requested_at > 0.0 and _now() - _details_requested_at > DETAILS_TIMEOUT:
		_details_requested_at = -1.0
		_product_confirmed = false
		last_error = "details_timeout"
		product_details_changed.emit()


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
		# Only keys this build knows about, and only booleans. A hand-edited
		# file cannot introduce a product that does not exist.
		for k: String in [LICENCE]:
			if bool((parsed as Dictionary).get(k, false)):
				_owned[k] = true


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


## Whether a buy button should be drawn at all. Requires the store to have
## confirmed the product, not merely that the code knows its id.
func can_purchase() -> bool:
	return is_available() and _product_confirmed and not has_licence() \
		and not _purchase_in_flight


func product_confirmed() -> bool:
	return _product_confirmed


## The platform's localised price string. Never hardcode a price in the UI --
## it is wrong in most of the world and against store guidelines besides.
func price_text() -> String:
	return _price_text


func status() -> Dictionary:
	return {
		"plugin_present": _plugin != null,
		"available": _available,
		"product_confirmed": _product_confirmed,
		"price": _price_text,
		"owned": has_licence(),
		"in_flight": _purchase_in_flight,
		"last_error": last_error,
		"product_id": LICENCE,
	}


## --- purchase flow ---------------------------------------------------------

func purchase(product_id: String = LICENCE) -> bool:
	if owns(product_id):
		return true
	if not can_purchase():
		last_error = "not_purchasable"
		purchase_failed.emit(product_id, "unavailable")
		return false
	_purchase_in_flight = true
	Analytics.track("iap_started", {"product": product_id})
	if _safe_call("purchase", product_id):
		return true
	_purchase_in_flight = false
	last_error = "no_purchase_method"
	purchase_failed.emit(product_id, "no_method")
	return false


func restore() -> void:
	if not is_available():
		return
	if _safe_call("queryPurchases", "inapp"):
		return
	_safe_call("query_purchases")


func _grant(product_id: String) -> void:
	if product_id != LICENCE:
		# An id this build does not sell is not an entitlement it can grant.
		return
	_purchase_in_flight = false
	if owns(product_id):
		return
	_owned[product_id] = true
	_save_owned()
	_apply()
	Analytics.track("iap_purchased", {"product": product_id})
	purchase_completed.emit(product_id)


func _on_purchases_updated(purchases: Variant = null) -> void:
	_purchase_in_flight = false
	if typeof(purchases) != TYPE_ARRAY:
		return
	var any: bool = false
	for p: Variant in purchases:
		var id: String = ""
		if typeof(p) == TYPE_DICTIONARY:
			# Plugin majors disagree on the key name; accept all rather than
			# silently failing to grant something someone paid for.
			id = String((p as Dictionary).get("product_id",
				(p as Dictionary).get("productId", (p as Dictionary).get("sku", ""))))
			# Acknowledge, where the plugin needs it. Google voids an
			# unacknowledged purchase after three days and refunds the player.
			var token: String = String((p as Dictionary).get("purchase_token",
				(p as Dictionary).get("purchaseToken", "")))
			if token != "" and id == LICENCE:
				if not _safe_call("acknowledgePurchase", token):
					_safe_call("acknowledge_purchase", token)
		elif typeof(p) == TYPE_STRING:
			id = String(p)
		if id != "":
			_grant(id)
			any = true
	if any:
		restored.emit()


func _on_purchase_error(code: Variant = null, msg: Variant = null) -> void:
	_purchase_in_flight = false
	last_error = "purchase_error:" + str(code)
	Analytics.track("iap_failed", {"code": str(code)})
	purchase_failed.emit(LICENCE, str(msg))


## Test/editor hooks. Guarded to debug builds so they cannot be reached in a
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
