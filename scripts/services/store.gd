extends Node

## In-app purchases, driven entirely by `MonetizationDB`.
##
## There is not one product id, price or piece of store copy in this file. It
## asks the catalogue what this build sells, asks the platform what those cost
## here, and holds entitlements by internal key so that changing a store-side
## id never orphans something a player paid for.
##
## ---------------------------------------------------------------------------
## THE PART THAT IS ACTUALLY HARD
## ---------------------------------------------------------------------------
##
## The happy path is twenty lines. Everything below it exists because Google
## Play's purchase lifecycle has states that a naive integration silently gets
## wrong, and each one of those is somebody's money:
##
##   **PENDING.** A purchase made with a delayed instrument -- a convenience
##   store voucher, a bank transfer, a slow test card -- arrives with
##   `purchaseState == PENDING`. Play's documentation is explicit: do not grant
##   entitlement, and do not acknowledge it either, because the three-day
##   acknowledgement clock starts when it becomes PURCHASED. An integration
##   that grants on arrival hands out the product for a payment that may never
##   land. This one is tracked, shown to the player as waiting, and granted
##   only on the transition.
##
##   **Acknowledgement.** An unacknowledged purchase is refunded automatically
##   after three days and the entitlement revoked. Acknowledging once and
##   hoping is not enough: the call can fail on a dropped connection. Failures
##   go into `_ack_queue` and are retried on every reconnect and on resume.
##
##   **ITEM_ALREADY_OWNED.** Almost always means a previous purchase completed
##   but was never acknowledged or never reached this install. The correct
##   response is to query purchases, not to show an error at somebody who has
##   already paid.
##
##   **Purchases that happen while the app is not running** -- a promo
##   redemption, a second device, a PENDING that cleared overnight. The only
##   way to see those is to query on connect and again on resume.
##
##   **Disconnection.** The billing service drops. Reconnect with backoff, with
##   a ceiling, and stop claiming the product is purchasable in the meantime.
##
## ---------------------------------------------------------------------------
## WHAT IT CANNOT DO
## ---------------------------------------------------------------------------
##
## Nothing here can move a number the economy reads. `MonetizationDB` declares
## `ECONOMY_GRANTS` empty and `tests/test_store.gd` asserts both that the list
## is empty and that a fully entitled player and an unentitled one produce
## byte-identical economy state from the same inputs. The grants are: no ads,
## more offline hours, more blueprint slots, and a choice of palette.
##
## And it runs with no plugin at all. The editor, CI and every headless test
## take that path: `is_available()` is false, no buy button is drawn, and the
## game is whole.

signal purchase_completed(key: String)
signal purchase_failed(key: String, reason: String)
signal purchase_pending(key: String)
signal restored()
signal availability_changed(available: bool)
signal product_details_changed()
signal theme_changed(id: String)

## Kept as an alias so older call sites and saves keep working. The catalogue
## owns the value.
const LICENCE := MonetizationDB.LICENCE
const THEMES_PRODUCT := MonetizationDB.THEMES

const OWNED_PATH := "user://entitlements.json"

## How long the platform may take to answer a details query before the UI
## stops claiming a purchase is possible.
const DETAILS_TIMEOUT := 20.0

## How long a launched purchase flow may hang before it is written off. A real
## Play purchase sheet can sit open while somebody finds their card, so this
## is generous; past it, something is wrong with the SDK, not the player.
const PURCHASE_TIMEOUT := 180.0

## Reconnect policy after a billing service disconnect.
const RECONNECT_BASE := 2.0
const RECONNECT_MAX := 30.0
const RECONNECT_TRIES := 5

## Acknowledgement retry policy. Google voids an unacknowledged purchase after
## three days, so this retries for as long as the app is open and again on
## every connect.
const ACK_RETRY_SECONDS := 20.0

## Entitlement states.
enum State { NONE, PENDING, OWNED }

## Billing response codes, classified by what this app should do about them.
## Values match `BillingClient.BillingResponseCode`; they arrive as ints from
## the plugin and as strings from some plugin majors, so both are accepted.
const CODE_OK := 0
const CODE_USER_CANCELED := 1
const CODE_SERVICE_UNAVAILABLE := 2
const CODE_BILLING_UNAVAILABLE := 3
const CODE_ITEM_UNAVAILABLE := 4
const CODE_DEVELOPER_ERROR := 5
const CODE_ERROR := 6
const CODE_ITEM_ALREADY_OWNED := 7
const CODE_ITEM_NOT_OWNED := 8
const CODE_NETWORK_ERROR := 12

## Transient: worth retrying, and worth telling the player to try again.
const RETRYABLE: Array[int] = [CODE_SERVICE_UNAVAILABLE, CODE_ERROR,
	CODE_NETWORK_ERROR]
## Terminal for this device or build: stop offering the product.
const TERMINAL: Array[int] = [CODE_BILLING_UNAVAILABLE, CODE_ITEM_UNAVAILABLE,
	CODE_DEVELOPER_ERROR]

var _plugin: Object = null
var _available: bool = false
## key -> State
var _state: Dictionary = {}
## key -> localised price string, exactly as the platform gave it
var _price: Dictionary = {}
## key -> true once the store has confirmed this product exists and is sellable
## here. Until then no buy button is drawn: a purchase button that fails is
## worse than no button, and "the code knows the id" is not the same claim as
## "the product is purchasable".
var _confirmed: Dictionary = {}
var _details_requested_at: float = -1.0
var _purchase_in_flight: String = ""
var _purchase_started_at: float = -1.0
## purchase_token -> key, for acknowledgements that have not succeeded yet.
var _ack_queue: Dictionary = {}
var _ack_next_try: float = 0.0
var _reconnect_at: float = -1.0
var _reconnect_tries: int = 0
var _selected_theme: String = Themes.DEFAULT

var last_error: String = ""
## Set when the store told us something the player should be told, in words
## they can act on. Empty when there is nothing to say.
var last_player_message: String = ""

## Debug only. Lets the tests drive the "store is connected" branches without
## a native plugin, so the purchasable/not-purchasable logic is exercised
## rather than short-circuited by the absence of Google Play.
var _debug_force_available: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_owned()
	_apply()
	_try_bind_plugin()


## --- plugin binding ---------------------------------------------------------
##
## Bound to the `GodotGooglePlayBilling` singleton of
## `godot-sdk-integrations/godot-google-play-billing` 3.x (Billing Library 9),
## version pinned in `tools/install-plugins.sh`. The method names, argument
## counts, signal names and dictionary keys below are the plugin's own
## (`GodotGooglePlayBilling.kt`, `Utils.kt`), not guesses: a JNI call with the
## wrong number of arguments fails, and a signal bound under the wrong name
## simply never fires, so there is no such thing as a tolerant binding here.

const SINGLETON := "GodotGooglePlayBilling"


func _try_bind_plugin() -> void:
	if not Engine.has_singleton(SINGLETON):
		_available = false
		last_error = "plugin_absent"
		return
	_bind_plugin(Engine.get_singleton(SINGLETON))


func _bind_plugin(plugin: Object) -> void:
	_plugin = plugin
	if _plugin == null:
		_available = false
		last_error = "singleton_null"
		return
	# The Kotlin side builds its BillingClient in initPlugin(). Every other
	# call dereferences it, so calling startConnection() first is an
	# uninitialised-property crash on the phone, not an error code.
	if not _plugin.has_method("initPlugin"):
		last_error = "no_init_method"
		_plugin = null
		_available = false
		return
	_call("initPlugin")
	_bind("connected", _on_connected)
	_bind("disconnected", _on_disconnected)
	_bind("connect_error", _on_connect_error)
	_bind("query_product_details_response", _on_details_response)
	_bind("query_purchases_response", _on_query_purchases_response)
	_bind("on_purchase_updated", _on_purchase_updated)
	_bind("acknowledge_purchase_response", _on_ack_response)
	_connect_billing()


func _connect_billing() -> void:
	_call("startConnection")


func _bind(sig: String, target: Callable) -> void:
	if _plugin.has_signal(sig) and not _plugin.is_connected(sig, target):
		_plugin.connect(sig, target)


## Every call into the singleton goes through here. Returns the call's result,
## or null when there is no plugin or no such method -- callers that need to
## tell those apart check `has_method` themselves.
func _call(method: String, args: Array = []) -> Variant:
	if _plugin == null or not _plugin.has_method(method):
		return null
	return _plugin.callv(method, args)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## --- connection lifecycle ---------------------------------------------------

func _on_connected(_a = null) -> void:
	last_error = ""
	_reconnect_tries = 0
	_reconnect_at = -1.0
	_available = true
	availability_changed.emit(true)
	query_product_details()
	# Every connect: catch purchases made on another device, redeemed from a
	# promo code, or transitioned out of PENDING while the app was closed.
	restore()
	_flush_acks(true)


func _on_disconnected(_a = null) -> void:
	_available = false
	_confirmed.clear()
	last_error = "billing_disconnected"
	_schedule_reconnect()
	availability_changed.emit(false)


func _on_connect_error(code: Variant = null, _msg: Variant = null) -> void:
	var c: int = _code(code)
	_available = false
	_confirmed.clear()
	last_error = "connect_error:%d" % c
	if TERMINAL.has(c):
		# Billing genuinely unavailable on this device (an emulator without
		# Play services, a region where it is not offered, a sideload). Stop
		# retrying and stop offering anything.
		_reconnect_tries = RECONNECT_TRIES
		last_player_message = Loc.t("Google Play billing isn't available on this device.")
	else:
		_schedule_reconnect()
	availability_changed.emit(false)


func _schedule_reconnect() -> void:
	if _reconnect_tries >= RECONNECT_TRIES:
		return
	var delay: float = minf(RECONNECT_BASE * pow(2.0, float(_reconnect_tries)),
		RECONNECT_MAX)
	_reconnect_tries += 1
	_reconnect_at = _now() + delay


## --- product details --------------------------------------------------------

func query_product_details() -> void:
	if _plugin == null:
		return
	var ids: Array = MonetizationDB.all_store_ids()
	if ids.is_empty():
		return
	if not _plugin.has_method("queryProductDetails"):
		last_error = "no_details_method"
		return
	_details_requested_at = _now()
	_call("queryProductDetails", [PackedStringArray(ids), "inapp"])


## `query_product_details_response`: {response_code, debug_message,
## product_details: [...], unfetched_products: [...]}.
func _on_details_response(response: Variant = null) -> void:
	var d: Dictionary = response if typeof(response) == TYPE_DICTIONARY else {}
	var c: int = _code(d.get("response_code", null))
	if c != CODE_OK:
		_on_details_error(c, d.get("debug_message", ""))
		return
	var rows: Variant = d.get("product_details", [])
	_on_details(rows if typeof(rows) == TYPE_ARRAY else [])


func _on_details(details: Variant = null) -> void:
	_details_requested_at = -1.0
	var seen: Dictionary = {}
	var rows: Array = []
	if typeof(details) == TYPE_ARRAY:
		rows = details
	elif typeof(details) == TYPE_DICTIONARY:
		rows = [details]
	for d: Variant in rows:
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var dd: Dictionary = d
		var id: String = String(dd.get("product_id",
			dd.get("productId", dd.get("sku", ""))))
		var key: String = MonetizationDB.key_for_store_id(id)
		if key == "":
			continue
		seen[key] = true
		_confirmed[key] = true
		_price[key] = _extract_price(dd)
	# A product this build sells that the store did not return is not
	# purchasable here, whatever the code believes.
	for k: String in MonetizationDB.keys():
		if not seen.has(k):
			_confirmed[k] = false
	if seen.is_empty():
		last_error = "no_products_in_store"
	product_details_changed.emit()


## Prices arrive under different keys depending on the billing library major
## and on whether the product is one-time or subscription-shaped. Whatever the
## platform hands back is what gets shown; nothing is composed locally, because
## a locally composed price is wrong in most of the world.
func _extract_price(d: Dictionary) -> String:
	for k: String in ["formatted_price", "formattedPrice", "price",
			"one_time_purchase_offer_formatted_price"]:
		if d.has(k):
			var v: String = String(d[k])
			if v != "":
				return v
	# Billing Library 8+: one-time products carry a LIST of offers. The first
	# is the base purchase option, which is what `purchase()` buys when no
	# purchase option id is given.
	var offers: Variant = d.get("one_time_purchase_offer_details_list", null)
	if typeof(offers) == TYPE_ARRAY and not (offers as Array).is_empty():
		var first: Variant = (offers as Array)[0]
		if typeof(first) == TYPE_DICTIONARY:
			return String((first as Dictionary).get("formatted_price", ""))
	var offer: Variant = d.get("one_time_purchase_offer_details", null)
	if typeof(offer) == TYPE_DICTIONARY:
		return String((offer as Dictionary).get("formatted_price", ""))
	return ""


func _on_details_error(a = null, _b = null) -> void:
	_details_requested_at = -1.0
	_confirmed.clear()
	last_error = "details_error:" + str(a)
	product_details_changed.emit()


## --- the pump ---------------------------------------------------------------

func _process(_delta: float) -> void:
	var t: float = _now()
	if _details_requested_at > 0.0 and t - _details_requested_at > DETAILS_TIMEOUT:
		_details_requested_at = -1.0
		_confirmed.clear()
		last_error = "details_timeout"
		product_details_changed.emit()
	if _purchase_started_at > 0.0 and t - _purchase_started_at > PURCHASE_TIMEOUT:
		var k: String = _purchase_in_flight
		_purchase_in_flight = ""
		_purchase_started_at = -1.0
		last_error = "purchase_timeout"
		last_player_message = Loc.t("That took too long. Nothing was charged.")
		purchase_failed.emit(k, "timeout")
	if _reconnect_at > 0.0 and t >= _reconnect_at:
		_reconnect_at = -1.0
		_connect_billing()
	if not _ack_queue.is_empty() and t >= _ack_next_try:
		_flush_acks(false)


## Re-check on resume: a PENDING purchase can clear, or a purchase can be made
## on another device, while this app is in the background.
func on_resume() -> void:
	if is_available():
		restore()
		_flush_acks(true)


## --- entitlement storage ----------------------------------------------------
##
## Ownership is cached locally so the game works offline, which for an offline
## game is not optional. The cache is a convenience, never the source of truth:
## `restore()` re-reads the platform on every connect and on every resume.
##
## A tampered file is bounded by what the grants can do -- some offline hours,
## some blueprint slots, a palette -- so this checks for tampering to keep the
## file honest rather than to defend a revenue stream that is not there. On a
## checksum mismatch the whole file is discarded and the platform re-queried,
## so a real purchase is restored within a second of being online and a forged
## one lasts exactly that long.

const _CHECKSUM_KEY := "_c"


func _checksum(d: Dictionary) -> String:
	var parts: Array[String] = []
	for k: String in MonetizationDB.keys():
		parts.append("%s=%s" % [k, str(d.get(k, false))])
	parts.append(String(d.get("theme", Themes.DEFAULT)))
	# Not a security boundary and not presented as one. It makes accidental
	# corruption and casual edits visible; a determined edit is expected to
	# succeed and to be undone by the next restore().
	return String(("lodeworks|" + "|".join(parts)).sha256_text()).substr(0, 16)


func _load_owned() -> void:
	if not FileAccess.file_exists(OWNED_PATH):
		return
	var f := FileAccess.open(OWNED_PATH, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "entitlements_unreadable"
		return
	var d: Dictionary = parsed
	var stored: String = String(d.get(_CHECKSUM_KEY, ""))
	if stored != "" and stored != _checksum(d):
		# Discard everything rather than trusting part of it.
		last_error = "entitlements_tampered"
		_state.clear()
		_selected_theme = Themes.DEFAULT
		return
	# Only keys this build sells, and only booleans. A hand-edited file cannot
	# introduce a product that does not exist, and cannot set a state other
	# than owned -- PENDING is never persisted, because a pending purchase is
	# the platform's fact and not ours.
	for k: String in MonetizationDB.keys():
		if bool(d.get(k, false)):
			_state[k] = State.OWNED
	var th: String = String(d.get("theme", Themes.DEFAULT))
	_selected_theme = th if Themes.exists(th) else Themes.DEFAULT


func _save_owned() -> void:
	var d: Dictionary = {}
	for k: String in MonetizationDB.keys():
		if owns(k):
			d[k] = true
	d["theme"] = _selected_theme
	d[_CHECKSUM_KEY] = _checksum(d)
	var f := FileAccess.open(OWNED_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()


func _apply() -> void:
	# Read across the whole catalogue rather than off one product, so a future
	# product that also removes ads works without editing this line.
	var no_ads: bool = false
	for k: String in MonetizationDB.keys():
		if owns(k) and bool(MonetizationDB.grant_value(k,
				MonetizationDB.GRANT_NO_ADS, false)):
			no_ads = true
	Ads.ads_removed = no_ads
	Palette.set_theme(active_theme())


## --- entitlement queries ----------------------------------------------------

func owns(key: String) -> bool:
	return int(_state.get(key, State.NONE)) == State.OWNED


func is_pending(key: String) -> bool:
	return int(_state.get(key, State.NONE)) == State.PENDING


func state_of(key: String) -> int:
	return int(_state.get(key, State.NONE))


func has_licence() -> bool:
	return owns(LICENCE)


## Sum of a numeric grant across everything owned. Additive by construction, so
## a future product granting the same thing composes instead of overwriting.
func _granted_total(grant: String) -> float:
	var total: float = 0.0
	for k: String in MonetizationDB.keys():
		if not owns(k):
			continue
		var v: Variant = MonetizationDB.grant_value(k, grant, null)
		if v != null and (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT):
			total += float(v)
	return total


func bonus_offline_hours() -> float:
	return _granted_total(MonetizationDB.GRANT_OFFLINE_HOURS)


func bonus_blueprint_slots() -> int:
	return int(_granted_total(MonetizationDB.GRANT_BLUEPRINT_SLOTS))


func has_themes() -> bool:
	return owns(THEMES_PRODUCT)


func theme_unlocked(id: String) -> bool:
	return Themes.is_free(id) or has_themes()


func active_theme() -> String:
	if theme_unlocked(_selected_theme):
		return _selected_theme
	return Themes.DEFAULT


## Choosing a theme is a local preference, not a purchase. Selecting a locked
## one is refused rather than silently ignored, so the UI cannot show a
## selection the board is not drawing.
func select_theme(id: String) -> bool:
	if not Themes.exists(id) or not theme_unlocked(id):
		return false
	_selected_theme = id
	Palette.set_theme(id)
	_save_owned()
	theme_changed.emit(id)
	return true


func is_available() -> bool:
	if _debug_force_available:
		return true
	return _available and _plugin != null


## Whether a buy button should be drawn for this product at all.
func can_purchase(key: String) -> bool:
	if not MonetizationDB.has(key):
		return false
	return is_available() and bool(_confirmed.get(key, false)) \
		and state_of(key) == State.NONE and _purchase_in_flight == ""


func product_confirmed(key: String) -> bool:
	return bool(_confirmed.get(key, false))


## The platform's localised price string. Empty until the store has answered,
## and the UI draws nothing rather than guessing.
func price_text(key: String) -> String:
	return String(_price.get(key, ""))


func status() -> Dictionary:
	var owned: Array[String] = []
	var pending: Array[String] = []
	var confirmed: Array[String] = []
	for k: String in MonetizationDB.keys():
		if owns(k):
			owned.append(k)
		if is_pending(k):
			pending.append(k)
		if product_confirmed(k):
			confirmed.append(k)
	return {
		"plugin_present": _plugin != null,
		"available": _available,
		"catalogue": MonetizationDB.keys(),
		"sandbox_ids": MonetizationDB.use_sandbox(),
		"confirmed": confirmed,
		"owned": owned,
		"pending": pending,
		"prices": _price.duplicate(),
		"in_flight": _purchase_in_flight,
		"ack_queue": _ack_queue.size(),
		"reconnect_tries": _reconnect_tries,
		"theme": active_theme(),
		"last_error": last_error,
	}


## --- purchase ---------------------------------------------------------------

func purchase(key: String) -> bool:
	last_player_message = ""
	if not MonetizationDB.has(key):
		purchase_failed.emit(key, "unknown_product")
		return false
	if owns(key):
		# Idempotent: already paid for, nothing to charge, nothing to fail.
		purchase_completed.emit(key)
		return true
	if is_pending(key):
		last_player_message = Loc.t("That purchase is still waiting on your payment.")
		purchase_failed.emit(key, "already_pending")
		return false
	if not can_purchase(key):
		last_error = "not_purchasable"
		last_player_message = _unavailable_reason()
		purchase_failed.emit(key, "unavailable")
		return false
	_purchase_in_flight = key
	_purchase_started_at = _now()
	Analytics.track("iap_started", {"product": key})
	var id: String = MonetizationDB.store_id(key)
	if _plugin == null or not _plugin.has_method("purchase"):
		_purchase_in_flight = ""
		_purchase_started_at = -1.0
		last_error = "no_purchase_method"
		purchase_failed.emit(key, "no_method")
		return false
	# purchase(product_id, purchase_option_id, offer_id, is_offer_personalized)
	# returns the launchBillingFlow result synchronously. OK means the sheet
	# is up and the outcome will arrive on `on_purchase_updated`; anything
	# else means the sheet never opened.
	var r: Variant = _call("purchase", [id, "", "", false])
	var d: Dictionary = r if typeof(r) == TYPE_DICTIONARY else {}
	var c: int = _code(d.get("response_code", CODE_OK)) if not d.is_empty() else CODE_OK
	if c != CODE_OK:
		_on_purchase_error(c, d.get("debug_message", ""))
		return false
	return true


func _unavailable_reason() -> String:
	if _plugin == null:
		return Loc.t("Purchases aren't available in this build.")
	if not _available:
		return Loc.t("Can't reach Google Play right now. Try again in a moment.")
	return Loc.t("That isn't available on this device.")


func restore() -> void:
	if not is_available():
		return
	_call("queryPurchases", ["inapp", false])


## `query_purchases_response`: {response_code, debug_message, purchases}. The
## platform's complete answer for this account, so it is also the moment a
## refunded or revoked product -- or a forged line in the local cache --
## stops being owned, and a PENDING that was abandoned stops being pending.
func _on_query_purchases_response(response: Variant = null) -> void:
	var d: Dictionary = response if typeof(response) == TYPE_DICTIONARY else {}
	var c: int = _code(d.get("response_code", null))
	if c != CODE_OK:
		last_error = "query_purchases_error:%d" % c
		return
	var list: Variant = d.get("purchases", [])
	var rows: Array = list if typeof(list) == TYPE_ARRAY else []
	var present: Dictionary = {}
	var touched: bool = false
	for p: Variant in rows:
		var k: String = _key_of(p)
		if k != "":
			present[k] = true
		if _ingest(p):
			touched = true
	for k: String in MonetizationDB.keys():
		if present.has(k) or state_of(k) == State.NONE:
			continue
		_state.erase(k)
		touched = true
		if k == THEMES_PRODUCT and not Themes.is_free(_selected_theme):
			_selected_theme = Themes.DEFAULT
	if touched:
		_save_owned()
		_apply()
		restored.emit()


## `on_purchase_updated`: the outcome of a purchase flow, or a purchase that
## arrived by itself (a PENDING that cleared, a promo code). Errors -- a
## cancel, ITEM_ALREADY_OWNED, a network drop -- come through here too, as a
## response code with no purchases.
func _on_purchase_updated(response: Variant = null) -> void:
	var d: Dictionary = response if typeof(response) == TYPE_DICTIONARY else {}
	var c: int = _code(d.get("response_code", null))
	if c != CODE_OK:
		_on_purchase_error(c, d.get("debug_message", ""))
		return
	var list: Variant = d.get("purchases", [])
	_on_purchases_updated(list if typeof(list) == TYPE_ARRAY else [])


func _key_of(p: Variant) -> String:
	if typeof(p) != TYPE_DICTIONARY:
		return MonetizationDB.key_for_store_id(String(p)) if typeof(p) == TYPE_STRING else ""
	var d: Dictionary = p
	var id: String = String(d.get("product_id", d.get("productId", "")))
	if id == "":
		var ids: Variant = d.get("product_ids", d.get("products", null))
		if (typeof(ids) == TYPE_ARRAY or typeof(ids) == TYPE_PACKED_STRING_ARRAY) \
				and ids.size() > 0:
			id = String(ids[0])
	return MonetizationDB.key_for_store_id(id)


## --- incoming purchases -----------------------------------------------------

func _on_purchases_updated(purchases: Variant = null) -> void:
	_purchase_in_flight = ""
	_purchase_started_at = -1.0
	if typeof(purchases) != TYPE_ARRAY:
		return
	var touched: bool = false
	for p: Variant in purchases:
		if _ingest(p):
			touched = true
	if touched:
		restored.emit()


## One purchase record from the platform, in whatever shape the plugin major
## hands it over.
##
## Returns true if it changed anything. This is the only path by which an
## entitlement is ever granted, and it is deliberately the only place that
## reads `purchase_state`.
func _ingest(p: Variant) -> bool:
	var id: String = ""
	var state_raw: Variant = null
	var token: String = ""
	var acked: bool = false
	if typeof(p) == TYPE_DICTIONARY:
		var d: Dictionary = p
		id = String(d.get("product_id", d.get("productId", d.get("sku", ""))))
		# Some plugin majors hand back a list of ids per purchase.
		if id == "":
			var ids: Variant = d.get("product_ids", d.get("products", null))
			if (typeof(ids) == TYPE_ARRAY or typeof(ids) == TYPE_PACKED_STRING_ARRAY) \
					and ids.size() > 0:
				id = String(ids[0])
		state_raw = d.get("purchase_state", d.get("purchaseState", null))
		token = String(d.get("purchase_token", d.get("purchaseToken", "")))
		acked = bool(d.get("is_acknowledged", d.get("isAcknowledged", false)))
	elif typeof(p) == TYPE_STRING:
		id = String(p)
	var key: String = MonetizationDB.key_for_store_id(id)
	if key == "":
		# An id this build does not sell is not an entitlement it can grant.
		return false

	if _is_pending(state_raw):
		# Google Play: do not grant, and do not acknowledge -- the three-day
		# acknowledgement window only opens once it becomes PURCHASED.
		if state_of(key) != State.PENDING:
			_state[key] = State.PENDING
			Analytics.track("iap_failed", {"code": "pending"})
			last_player_message = Loc.t("Waiting on your payment. The %s unlocks as soon as it clears.") \
				% MonetizationDB.title_of(key)
			purchase_pending.emit(key)
			return true
		return false

	if not _is_purchased(state_raw):
		# Unspecified, cancelled, or a state this build does not understand.
		# Nothing is granted and nothing is acknowledged.
		if state_of(key) == State.PENDING:
			_state.erase(key)
			return true
		return false

	if token != "" and not acked:
		_ack_queue[token] = key
		_flush_acks(true)
	return _grant(key)


## Purchase state arrives as an int on some plugins and a string on others.
func _is_pending(raw: Variant) -> bool:
	if raw == null:
		return false
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return int(raw) == 2          # Purchase.PurchaseState.PENDING
	return String(raw).to_lower() == "pending"


## A record with no state field at all is treated as purchased: older plugin
## majors only ever returned completed purchases from queryPurchases, and
## refusing to grant would lose somebody their purchase. A record that DOES
## carry a state must say PURCHASED.
func _is_purchased(raw: Variant) -> bool:
	if raw == null:
		return true
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return int(raw) == 1          # Purchase.PurchaseState.PURCHASED
	var s: String = String(raw).to_lower()
	return s == "purchased" or s == "1"


func _grant(key: String) -> bool:
	if owns(key):
		# Duplicate delivery of a purchase already held. Idempotent by design:
		# queryPurchases returns the same record on every connect.
		return false
	_state[key] = State.OWNED
	_save_owned()
	_apply()
	Analytics.track("iap_purchased", {"product": key})
	last_player_message = ""
	purchase_completed.emit(key)
	return true


## --- acknowledgement --------------------------------------------------------

func _flush_acks(force: bool) -> void:
	if _ack_queue.is_empty() or _plugin == null:
		return
	if not force and _now() < _ack_next_try:
		return
	_ack_next_try = _now() + ACK_RETRY_SECONDS
	for token: String in _ack_queue.keys():
		_call("acknowledgePurchase", [token])


## `acknowledge_purchase_response`: {response_code, debug_message, token}.
func _on_ack_response(response: Variant = null) -> void:
	var d: Dictionary = response if typeof(response) == TYPE_DICTIONARY else {}
	var c: int = _code(d.get("response_code", null))
	if c == CODE_OK:
		_on_ack_ok(d.get("token", ""))
	else:
		_on_ack_failed(c, d.get("debug_message", ""))


func _on_ack_ok(token: Variant = null, _b = null) -> void:
	var t: String = String(token)
	if t != "" and _ack_queue.has(t):
		_ack_queue.erase(t)
	elif _ack_queue.size() == 1:
		# Some plugin majors report success without echoing the token.
		_ack_queue.clear()


func _on_ack_failed(code: Variant = null, _msg: Variant = null) -> void:
	# Left in the queue deliberately. Retried on the timer and on every
	# reconnect, because the alternative is Google refunding in three days.
	last_error = "ack_failed:%d" % _code(code)


## --- errors -----------------------------------------------------------------

func _code(raw: Variant) -> int:
	if raw == null:
		return CODE_ERROR
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return int(raw)
	var s: String = String(raw).strip_edges()
	if s.is_valid_int():
		return int(s)
	match s.to_upper():
		"USER_CANCELED", "USER_CANCELLED": return CODE_USER_CANCELED
		"SERVICE_UNAVAILABLE": return CODE_SERVICE_UNAVAILABLE
		"BILLING_UNAVAILABLE": return CODE_BILLING_UNAVAILABLE
		"ITEM_UNAVAILABLE": return CODE_ITEM_UNAVAILABLE
		"DEVELOPER_ERROR": return CODE_DEVELOPER_ERROR
		"ITEM_ALREADY_OWNED": return CODE_ITEM_ALREADY_OWNED
		"ITEM_NOT_OWNED": return CODE_ITEM_NOT_OWNED
		"NETWORK_ERROR": return CODE_NETWORK_ERROR
	return CODE_ERROR


func _on_purchase_error(code: Variant = null, msg: Variant = null) -> void:
	var key: String = _purchase_in_flight
	_purchase_in_flight = ""
	_purchase_started_at = -1.0
	var c: int = _code(code)
	last_error = "purchase_error:%d" % c

	match c:
		CODE_USER_CANCELED:
			# Not an error. The player changed their mind, which is allowed,
			# and saying anything about it would be nagging.
			last_player_message = ""
			purchase_failed.emit(key, "cancelled")
			return
		CODE_ITEM_ALREADY_OWNED:
			# Almost always a previous purchase that never reached this
			# install. Asking the store beats showing an error at somebody who
			# has already paid.
			last_player_message = Loc.t("You already own that: restoring it now.")
			restore()
			purchase_failed.emit(key, "already_owned")
			return
		CODE_BILLING_UNAVAILABLE:
			_confirmed.clear()
			last_player_message = Loc.t("Google Play billing isn't available on this device.")
		CODE_ITEM_UNAVAILABLE:
			if key != "":
				_confirmed[key] = false
			last_player_message = Loc.t("That isn't available on this device.")
		CODE_NETWORK_ERROR, CODE_SERVICE_UNAVAILABLE:
			last_player_message = Loc.t("No connection to Google Play. Nothing was charged.")
		CODE_DEVELOPER_ERROR:
			last_player_message = Loc.t("Purchases are misconfigured in this build.")
		_:
			last_player_message = Loc.t("That didn't go through. Nothing was charged.")

	if RETRYABLE.has(c):
		# Transient. Ask the store again so the button comes back by itself
		# rather than staying dead until the next launch.
		query_product_details()
	Analytics.track("iap_failed", {"code": str(c)})
	purchase_failed.emit(key, str(msg))


## --- test and editor hooks --------------------------------------------------
##
## Guarded to debug builds so they cannot be reached in a shipping binary.
## `tests/test_store.gd` drives the real code paths through these rather than
## through a mock, so what the tests prove is what the game runs.

func debug_grant(key: String = LICENCE) -> void:
	if not OS.is_debug_build():
		return
	_grant(key)


func debug_revoke() -> void:
	if not OS.is_debug_build():
		return
	_state.clear()
	_selected_theme = Themes.DEFAULT
	_save_owned()
	_apply()


## Feed a purchase record in exactly as the platform would. This is how the
## PENDING, duplicate and malformed-record paths are tested without a store.
func debug_ingest(record: Variant) -> bool:
	if not OS.is_debug_build():
		return false
	return _ingest(record)


func debug_purchase_error(code: Variant) -> void:
	if not OS.is_debug_build():
		return
	_on_purchase_error(code, "test")


func debug_set_confirmed(key: String, on: bool) -> void:
	if not OS.is_debug_build():
		return
	_confirmed[key] = on


func debug_set_available(on: bool) -> void:
	if not OS.is_debug_build():
		return
	_available = on
	_debug_force_available = on


func debug_ack_queue() -> int:
	return _ack_queue.size()


## Bind a stand-in singleton that speaks the plugin's protocol, so the tests
## drive the real binding rather than a shortcut around it.
func debug_bind(plugin: Object) -> void:
	if not OS.is_debug_build():
		return
	debug_unbind()
	_bind_plugin(plugin)


func debug_unbind() -> void:
	if not OS.is_debug_build():
		return
	if _plugin != null:
		for sig: Dictionary in _plugin.get_signal_list():
			for conn: Dictionary in _plugin.get_signal_connection_list(String(sig["name"])):
				var cb: Callable = conn["callable"]
				if cb.get_object() == self:
					_plugin.disconnect(String(sig["name"]), cb)
	_plugin = null
	_available = false
	_reconnect_at = -1.0
	_reconnect_tries = 0
	_details_requested_at = -1.0
	_purchase_in_flight = ""
	_purchase_started_at = -1.0


## Run the reconnect and acknowledgement timers now.
func debug_expire_timers() -> void:
	if not OS.is_debug_build():
		return
	if _reconnect_at > 0.0:
		_reconnect_at = _now() - 1.0
	_ack_next_try = 0.0
	_process(0.0)


func debug_clear_state() -> void:
	if not OS.is_debug_build():
		return
	debug_unbind()
	_debug_force_available = false
	_available = false
	_state.clear()
	_confirmed.clear()
	_price.clear()
	_ack_queue.clear()
	_purchase_in_flight = ""
	_selected_theme = Themes.DEFAULT
	last_error = ""
	last_player_message = ""
	_apply()
