extends Object

## A stand-in for the `GodotGooglePlayBilling` JNI singleton.
##
## Same signal names, same method names, same argument counts and the same
## dictionary keys as `GodotGooglePlayBilling.kt` / `Utils.kt` in
## godot-sdk-integrations/godot-google-play-billing 3.3.0. What it adds is a
## call log and a handful of knobs, so a test can say "the store answers
## this" and then check what the game did about it.

signal connected
signal disconnected
signal connect_error(response_code: int, debug_message: String)
signal query_product_details_response(response: Dictionary)
signal query_purchases_response(response: Dictionary)
signal on_purchase_updated(response: Dictionary)
signal consume_purchase_response(response: Dictionary)
signal acknowledge_purchase_response(response: Dictionary)

const OK := 0

## Every call, in order: [method, args].
var calls: Array = []
var inited: bool = false
## Set if anything but initPlugin() is called first -- on a phone that is a
## lateinit crash inside the plugin.
var used_before_init: bool = false

## "ok" emits connected, an int emits connect_error with that code, "none"
## emits nothing (a service that never answers).
var connect_result: Variant = "ok"
## product id -> formatted price. Ids not in here come back as unfetched.
var catalogue: Dictionary = {}
## What queryPurchases answers with.
var owned: Array = []
var query_code: int = OK
## What launchBillingFlow returns synchronously.
var launch_code: int = OK
## What acknowledgePurchase answers with.
var ack_code: int = OK


func _log(m: String, args: Array = []) -> void:
	calls.append([m, args])
	if m != "initPlugin" and not inited:
		used_before_init = true


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


func initPlugin() -> void:
	inited = true
	_log("initPlugin")


func startConnection() -> void:
	_log("startConnection")
	if typeof(connect_result) == TYPE_STRING and connect_result == "ok":
		connected.emit()
	elif typeof(connect_result) == TYPE_INT:
		connect_error.emit(int(connect_result), "fake")


func endConnection() -> void:
	_log("endConnection")


func isReady() -> bool:
	return inited


func queryProductDetails(product_ids: PackedStringArray, product_type: String) -> void:
	_log("queryProductDetails", [product_ids, product_type])
	var details: Array = []
	var unfetched: Array = []
	for id: String in product_ids:
		if catalogue.has(id):
			details.append({
				"product_id": id,
				"title": id,
				"name": id,
				"description": "",
				"product_type": product_type,
				"one_time_purchase_offer_details_list": [{
					"price_amount_micros": 3990000,
					"price_currency_code": "USD",
					"formatted_price": String(catalogue[id]),
					"purchase_option_id": "base",
					"offer_id": null,
					"offer_token": "tok-" + id,
				}],
				"subscription_offer_details": null,
			})
		else:
			unfetched.append({"product_id": id, "product_type": product_type,
				"status_code": 3})
	query_product_details_response.emit({
		"response_code": OK, "debug_message": "",
		"product_details": details, "unfetched_products": unfetched,
	})


func queryPurchases(product_type: String, include_suspended_subs: bool) -> void:
	_log("queryPurchases", [product_type, include_suspended_subs])
	if query_code != OK:
		query_purchases_response.emit({"response_code": query_code, "debug_message": "fake"})
		return
	query_purchases_response.emit({"response_code": OK, "debug_message": "",
		"purchases": owned.duplicate(true)})


func purchase(product_id: String, purchase_option_id: String, offer_id: String,
		is_offer_personalized: bool) -> Dictionary:
	_log("purchase", [product_id, purchase_option_id, offer_id, is_offer_personalized])
	return {"response_code": launch_code, "debug_message": ""}


func acknowledgePurchase(purchase_token: String) -> void:
	_log("acknowledgePurchase", [purchase_token])
	acknowledge_purchase_response.emit({"response_code": ack_code, "debug_message": "",
		"token": purchase_token})


func consumePurchase(purchase_token: String) -> void:
	_log("consumePurchase", [purchase_token])


## --- what the store "does" after a purchase sheet --------------------------

static func record(product_id: String, state: int, token: String,
		acked: bool = false) -> Dictionary:
	return {
		"order_id": "GPA.fake-" + token,
		"purchase_token": token,
		"package_name": "com.lodeworks.game",
		"purchase_state": state,     # 0 unspecified, 1 purchased, 2 pending
		"purchase_time": 0,
		"original_json": "{}",
		"is_acknowledged": acked,
		"is_auto_renewing": false,
		"is_suspended": false,
		"quantity": 1,
		"signature": "",
		"product_ids": PackedStringArray([product_id]),
	}


func deliver(purchases: Array) -> void:
	on_purchase_updated.emit({"response_code": OK, "debug_message": "",
		"purchases": purchases})


func fail(code: int) -> void:
	on_purchase_updated.emit({"response_code": code, "debug_message": "fake"})
