extends RefCounted

## The billing and ad layers, driven through stand-ins that speak the real
## plugins' protocols.
##
## The rest of the monetization suite proves the decisions -- what is granted,
## when, and what never is. This file proves the WIRING: that the game calls
## the plugin's methods by their real names with their real argument counts,
## binds its real signal names, and reads its real dictionary keys. That is
## the layer that cannot be checked any other way before a phone, and the one
## that fails silently: a signal bound under the wrong name never fires, and a
## JNI call with the wrong number of arguments does nothing.
##
## Protocols: godot-google-play-billing 3.3.0, Poing godot-admob 5.1.0, the
## versions `tools/install-plugins.sh` pins.

const FakeBilling := preload("res://tests/fakes/fake_billing.gd")
const FakeAdMob := preload("res://tests/fakes/fake_admob.gd")

const PURCHASED := 1
const PENDING := 2

var runner: Object


func before_each() -> void:
	Store.debug_clear_state()
	Store.debug_revoke()
	Ads.debug_unbind()
	Ads.ads_removed = false
	MonetizationDB.clear_force()
	MonetizationDB.clear_force_test_ads()


func _billing() -> Object:
	var f: Object = FakeBilling.new()
	for k: String in MonetizationDB.keys():
		f.catalogue[MonetizationDB.store_id(k)] = "$3.99"
	return f


func _done(objs: Array) -> void:
	Store.debug_clear_state()
	Store.debug_revoke()
	Ads.debug_unbind()
	Ads.ads_removed = false
	MonetizationDB.clear_force_test_ads()
	for o: Object in objs:
		o.free()


# --- billing ------------------------------------------------------------------

func test_the_plugin_is_initialised_before_anything_else_is_called() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	runner.check(f.inited, "initPlugin() was called")
	runner.eq(String(f.calls[0][0]), "initPlugin", "and it was the first call")
	runner.check(not f.used_before_init,
		"nothing touched the BillingClient before it existed")
	runner.eq(f.count("startConnection"), 1, "then the connection was started")
	_done([f])


func test_connecting_queries_every_product_by_its_real_signature() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	var args: Array = f.last_args("queryProductDetails")
	runner.eq(args.size(), 2, "queryProductDetails(ids, type)")
	runner.eq(typeof(args[0]), TYPE_PACKED_STRING_ARRAY, "ids as a PackedStringArray")
	runner.eq((args[0] as PackedStringArray).size(), MonetizationDB.keys().size(),
		"every product in one batched query")
	runner.eq(String(args[1]), "inapp", "as one-time products")
	var q: Array = f.last_args("queryPurchases")
	runner.eq(q.size(), 2, "queryPurchases(type, include_suspended)")
	runner.eq(String(q[0]), "inapp", "for one-time products")
	_done([f])


func test_a_price_is_read_from_the_offer_list() -> void:
	var f: Object = _billing()
	f.catalogue[MonetizationDB.store_id(MonetizationDB.LICENCE)] = "₺129,99"
	Store.debug_bind(f)
	runner.eq(Store.price_text(MonetizationDB.LICENCE), "₺129,99",
		"the localised string from one_time_purchase_offer_details_list[0]")
	runner.check(Store.can_purchase(MonetizationDB.LICENCE), "and the product is buyable")
	_done([f])


func test_an_unfetched_product_is_never_buyable() -> void:
	var f: Object = _billing()
	f.catalogue.erase(MonetizationDB.store_id(MonetizationDB.THEMES))
	Store.debug_bind(f)
	runner.check(not Store.can_purchase(MonetizationDB.THEMES),
		"a product the store did not return has no buy button")
	runner.check(Store.can_purchase(MonetizationDB.LICENCE), "the other one still does")
	_done([f])


func test_a_purchase_launches_with_four_arguments() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	runner.check(Store.purchase(MonetizationDB.LICENCE), "the sheet opens")
	var a: Array = f.last_args("purchase")
	runner.eq(a.size(), 4, "purchase(id, option, offer, personalized)")
	runner.eq(String(a[0]), MonetizationDB.store_id(MonetizationDB.LICENCE), "the right id")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted on launch")
	_done([f])


func test_a_completed_purchase_is_granted_once_and_acknowledged() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	var id: String = MonetizationDB.store_id(MonetizationDB.LICENCE)
	Store.purchase(MonetizationDB.LICENCE)
	var rec: Dictionary = FakeBilling.record(id, PURCHASED, "tok1")
	f.deliver([rec])
	runner.check(Store.owns(MonetizationDB.LICENCE), "granted on PURCHASED")
	runner.eq(f.count("acknowledgePurchase"), 1, "acknowledged")
	runner.eq(String(f.last_args("acknowledgePurchase")[0]), "tok1", "with its token")
	runner.eq(Store.debug_ack_queue(), 0, "and the ack succeeded, so nothing is queued")
	var grants: Array = []
	var cb := func(k: String) -> void: grants.append(k)
	Store.purchase_completed.connect(cb)
	f.deliver([rec])
	Store.purchase_completed.disconnect(cb)
	runner.eq(grants.size(), 0, "the same purchase delivered twice grants nothing more")
	_done([f])


func test_a_failed_acknowledgement_is_retried_until_it_lands() -> void:
	var f: Object = _billing()
	f.ack_code = 6
	Store.debug_bind(f)
	f.deliver([FakeBilling.record(MonetizationDB.store_id(MonetizationDB.LICENCE),
		PURCHASED, "tok2")])
	runner.check(Store.owns(MonetizationDB.LICENCE), "the player has what they paid for")
	runner.eq(Store.debug_ack_queue(), 1, "the unacknowledged token is kept")
	f.ack_code = 0
	Store.debug_expire_timers()
	runner.eq(f.count("acknowledgePurchase"), 2, "and retried on the timer")
	runner.eq(Store.debug_ack_queue(), 0, "until Google confirms it")
	_done([f])


func test_a_pending_purchase_waits_and_is_not_acknowledged() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	var id: String = MonetizationDB.store_id(MonetizationDB.LICENCE)
	f.deliver([FakeBilling.record(id, PENDING, "slow")])
	runner.check(Store.is_pending(MonetizationDB.LICENCE), "shown as waiting")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "not granted")
	runner.eq(f.count("acknowledgePurchase"), 0, "and not acknowledged")
	f.deliver([FakeBilling.record(id, PURCHASED, "slow")])
	runner.check(Store.owns(MonetizationDB.LICENCE), "granted when it clears")
	runner.eq(f.count("acknowledgePurchase"), 1, "and only then acknowledged")
	_done([f])


func test_an_abandoned_pending_purchase_stops_being_pending() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	f.deliver([FakeBilling.record(MonetizationDB.store_id(MonetizationDB.LICENCE),
		PENDING, "gone")])
	runner.check(Store.is_pending(MonetizationDB.LICENCE), "pending")
	f.owned = []
	Store.restore()
	runner.check(not Store.is_pending(MonetizationDB.LICENCE),
		"the store no longer lists it, so it is not pending any more")
	_done([f])


func test_a_cancel_arrives_as_a_response_code_and_charges_nothing() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	var reasons: Array = []
	var cb := func(_k: String, r: String) -> void: reasons.append(r)
	Store.purchase_failed.connect(cb)
	Store.purchase(MonetizationDB.LICENCE)
	f.fail(Store.CODE_USER_CANCELED)
	Store.purchase_failed.disconnect(cb)
	runner.eq(reasons, ["cancelled"], "reported as a cancel")
	runner.eq(Store.last_player_message, "", "and nothing is said about it")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted")
	runner.check(Store.can_purchase(MonetizationDB.LICENCE), "and the button comes back")
	_done([f])


func test_item_already_owned_at_launch_restores_instead_of_erroring() -> void:
	var f: Object = _billing()
	var id: String = MonetizationDB.store_id(MonetizationDB.LICENCE)
	f.owned = [FakeBilling.record(id, PURCHASED, "old", true)]
	Store.debug_bind(f)
	Store.debug_revoke()
	f.launch_code = Store.CODE_ITEM_ALREADY_OWNED
	var before: int = f.count("queryPurchases")
	Store.purchase(MonetizationDB.LICENCE)
	runner.eq(f.count("queryPurchases"), before + 1, "the store is asked what is owned")
	runner.check(Store.owns(MonetizationDB.LICENCE), "and the purchase is restored")
	runner.eq(f.count("acknowledgePurchase"), 0,
		"an already acknowledged purchase is not acknowledged again")
	_done([f])


func test_restore_revokes_what_the_store_no_longer_lists() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	Store.debug_grant(MonetizationDB.LICENCE)
	runner.check(Store.owns(MonetizationDB.LICENCE), "owned locally (a refund, or a forged cache)")
	f.owned = []
	Store.restore()
	runner.check(not Store.owns(MonetizationDB.LICENCE),
		"the platform's answer wins: refunded or forged, it is gone")
	runner.check(not Ads.ads_removed, "and ads come back with it")
	f.owned = [FakeBilling.record(MonetizationDB.store_id(MonetizationDB.LICENCE),
		PURCHASED, "real", true)]
	Store.restore()
	runner.check(Store.owns(MonetizationDB.LICENCE), "a real purchase is restored")
	_done([f])


func test_a_failed_purchase_query_changes_nothing() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	Store.debug_grant(MonetizationDB.LICENCE)
	f.query_code = Store.CODE_SERVICE_UNAVAILABLE
	Store.restore()
	runner.check(Store.owns(MonetizationDB.LICENCE),
		"an error is not an answer: nothing is revoked on a failed query")
	_done([f])


func test_a_disconnect_reconnects_with_backoff() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	runner.check(Store.is_available(), "connected")
	f.disconnected.emit()
	runner.check(not Store.is_available(), "a dropped service is not purchasable")
	runner.check(not Store.can_purchase(MonetizationDB.LICENCE), "no buy button meanwhile")
	Store.debug_expire_timers()
	runner.eq(f.count("startConnection"), 2, "and the connection is retried")
	runner.check(Store.is_available(), "and comes back")
	_done([f])


func test_billing_unavailable_on_connect_stops_offering_and_retrying() -> void:
	var f: Object = _billing()
	f.connect_result = Store.CODE_BILLING_UNAVAILABLE
	Store.debug_bind(f)
	runner.check(not Store.is_available(), "not available")
	Store.debug_expire_timers()
	runner.eq(f.count("startConnection"), 1, "and not retried on a terminal error")
	_done([f])


func test_a_network_error_says_nothing_was_charged() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	var q: int = f.count("queryProductDetails")
	Store.purchase(MonetizationDB.LICENCE)
	f.fail(Store.CODE_NETWORK_ERROR)
	runner.check(Store.last_player_message.contains("Nothing was charged"),
		"the player is told plainly")
	runner.eq(f.count("queryProductDetails"), q + 1, "and the products are asked for again")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted")
	_done([f])


func test_an_unknown_product_from_the_store_grants_nothing() -> void:
	var f: Object = _billing()
	Store.debug_bind(f)
	f.deliver([FakeBilling.record("someone_elses_sku", PURCHASED, "x")])
	for k: String in MonetizationDB.keys():
		runner.check(not Store.owns(k), "nothing granted for an id this build does not sell: " + k)
	_done([f])


# --- ads ----------------------------------------------------------------------

func _ads(consent_status: int = 1) -> Array:
	var core: Object = FakeAdMob.new()
	var rew: Object = FakeAdMob.new()
	var con: Object = FakeAdMob.new()
	var ump: Object = FakeAdMob.new()
	con.consent_status = consent_status
	MonetizationDB.force_test_ads(true)
	Ads.debug_bind(core, rew, con, ump)
	return [core, rew, con, ump]


func _ready_ad(f: Array) -> int:
	# consent answered, SDK initialised, an ad loaded
	(f[2] as Object).on_consent_info_updated_success.emit()
	(f[0] as Object).on_initialization_complete.emit({})
	var uid: int = int((f[1] as Object).last_args("load")[3])
	(f[1] as Object).on_rewarded_ad_loaded.emit(uid)
	return uid


func test_consent_is_settled_before_the_sdk_starts() -> void:
	var f: Array = _ads()
	runner.eq((f[2] as Object).count("update"), 1, "consent info is requested first")
	runner.eq((f[0] as Object).count("initialize"), 0, "the SDK waits for it")
	(f[2] as Object).on_consent_info_updated_success.emit()
	runner.eq((f[0] as Object).count("initialize"), 1, "then initialises")
	runner.check(Ads.consent_obtained(), "consent not required counts as settled")
	_done(f)


func test_a_required_consent_form_is_shown_before_any_ad() -> void:
	var f: Array = _ads(2)
	(f[2] as Object).form_available = true
	(f[2] as Object).on_consent_info_updated_success.emit()
	runner.eq((f[3] as Object).count("load_consent_form"), 1, "the form is loaded")
	runner.eq((f[0] as Object).count("initialize"), 0, "no SDK before the form")
	(f[3] as Object).on_consent_form_load_success_listener.emit(7)
	runner.eq(int((f[3] as Object).last_args("show")[0]), 7, "the loaded form is shown")
	(f[2] as Object).consent_status = 3
	(f[3] as Object).on_consent_form_dismissed.emit(7, {})
	runner.eq((f[0] as Object).count("initialize"), 1, "then the SDK starts")
	runner.check(Ads.consent_obtained(), "with consent")
	_done(f)


func test_a_failed_consent_update_still_lets_the_sdk_decide() -> void:
	var f: Array = _ads()
	(f[2] as Object).on_consent_info_updated_failure.emit({"error_code": 1, "message": "x"})
	runner.eq((f[0] as Object).count("initialize"), 1,
		"a failed update is not a refusal; last session's answer applies")
	_done(f)


func test_the_rewarded_load_uses_the_real_signature_and_the_sample_unit() -> void:
	var f: Array = _ads()
	(f[2] as Object).on_consent_info_updated_success.emit()
	(f[0] as Object).on_initialization_complete.emit({})
	var a: Array = (f[1] as Object).last_args("load")
	runner.eq(a.size(), 4, "load(unit, request, keywords, uid)")
	runner.eq(String(a[0]), MonetizationDB.ADMOB_TEST_REWARDED_UNIT,
		"a debug build only ever asks for Google's sample unit")
	runner.eq(typeof(a[1]), TYPE_DICTIONARY, "the request is a dictionary")
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE), "not offerable until loaded")
	(f[1] as Object).on_rewarded_ad_loaded.emit(int(a[3]))
	runner.check(Ads.can_offer(Ads.P_DOUBLE_OFFLINE), "offerable once loaded")
	_done(f)


func test_a_release_build_without_a_live_unit_offers_nothing() -> void:
	var f: Array = _ads()
	MonetizationDB.force_test_ads(false)
	(f[2] as Object).on_consent_info_updated_success.emit()
	(f[0] as Object).on_initialization_complete.emit({})
	runner.eq((f[1] as Object).count("load"), 0, "no load with no unit configured")
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE), "and no button")
	runner.eq(String(Ads.status()["last_error"]), "no_ad_unit", "and the reason is on record")
	_done(f)


func test_a_reward_is_granted_once_and_only_when_earned() -> void:
	var f: Array = _ads()
	var uid: int = _ready_ad(f)
	var granted: Array = []
	var failed: Array = []
	var g := func(p: String) -> void: granted.append(p)
	var b := func(p: String, r: String) -> void: failed.append(r)
	Ads.reward_granted.connect(g)
	Ads.reward_failed.connect(b)
	runner.check(Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE), "shown")
	runner.eq(int((f[1] as Object).last_args("show")[0]), uid, "the loaded ad, by uid")
	runner.eq(granted.size(), 0, "showing is not earning")
	(f[1] as Object).on_rewarded_ad_user_earned_reward.emit(uid, {"amount": 1, "type": "x"})
	(f[1] as Object).on_rewarded_ad_user_earned_reward.emit(uid, {"amount": 1, "type": "x"})
	(f[1] as Object).on_rewarded_ad_dismissed_full_screen_content.emit(uid)
	Ads.reward_granted.disconnect(g)
	Ads.reward_failed.disconnect(b)
	runner.eq(granted.size(), 1, "earned twice, paid once")
	runner.eq(failed.size(), 0, "and a normal close after earning is not a failure")
	runner.eq((f[1] as Object).count("destroy"), 1, "the used ad is destroyed")
	runner.eq((f[1] as Object).count("load"), 2, "and the next one is loaded")
	_done(f)


func test_closing_early_grants_nothing() -> void:
	var f: Array = _ads()
	var uid: int = _ready_ad(f)
	var granted: Array = []
	var failed: Array = []
	var g := func(p: String) -> void: granted.append(p)
	var b := func(p: String, r: String) -> void: failed.append(r)
	Ads.reward_granted.connect(g)
	Ads.reward_failed.connect(b)
	Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE)
	(f[1] as Object).on_rewarded_ad_dismissed_full_screen_content.emit(uid)
	runner.eq(failed.size(), 0, "not settled yet: a late reward may still arrive")
	Ads.debug_expire_timers()
	Ads.reward_granted.disconnect(g)
	Ads.reward_failed.disconnect(b)
	runner.eq(granted.size(), 0, "no reward without the SDK saying it was earned")
	runner.eq(failed, ["dismissed"], "reported as an early close")
	_done(f)


func test_a_reward_that_arrives_after_the_close_still_counts_once() -> void:
	var f: Array = _ads()
	var uid: int = _ready_ad(f)
	var granted: Array = []
	var failed: Array = []
	var g := func(p: String) -> void: granted.append(p)
	var b := func(p: String, r: String) -> void: failed.append(r)
	Ads.reward_granted.connect(g)
	Ads.reward_failed.connect(b)
	Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE)
	(f[1] as Object).on_rewarded_ad_dismissed_full_screen_content.emit(uid)
	(f[1] as Object).on_rewarded_ad_user_earned_reward.emit(uid, {})
	Ads.debug_expire_timers()
	(f[1] as Object).on_rewarded_ad_user_earned_reward.emit(uid, {})
	Ads.reward_granted.disconnect(g)
	Ads.reward_failed.disconnect(b)
	runner.eq(granted.size(), 1, "the player who watched to the end is paid, once")
	runner.eq(failed.size(), 0, "and it is not also reported as a failure")
	_done(f)


func test_a_callback_for_another_ad_is_ignored() -> void:
	var f: Array = _ads()
	var uid: int = _ready_ad(f)
	var granted: Array = []
	var g := func(p: String) -> void: granted.append(p)
	Ads.reward_granted.connect(g)
	Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE)
	(f[1] as Object).on_rewarded_ad_user_earned_reward.emit(uid + 99, {})
	Ads.reward_granted.disconnect(g)
	runner.eq(granted.size(), 0, "a stale uid cannot pay out")
	_done(f)


func test_a_failed_show_grants_nothing_and_loads_again() -> void:
	var f: Array = _ads()
	var uid: int = _ready_ad(f)
	var granted: Array = []
	var failed: Array = []
	var g := func(p: String) -> void: granted.append(p)
	var b := func(p: String, r: String) -> void: failed.append(r)
	Ads.reward_granted.connect(g)
	Ads.reward_failed.connect(b)
	Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE)
	(f[1] as Object).on_rewarded_ad_failed_to_show_full_screen_content.emit(uid,
		{"code": 3, "message": "x"})
	Ads.reward_granted.disconnect(g)
	Ads.reward_failed.disconnect(b)
	runner.eq(granted.size(), 0, "nothing granted")
	runner.eq(failed, ["show_failed"], "reported")
	runner.eq((f[1] as Object).count("load"), 2, "and another ad is requested")
	_done(f)


func test_no_fill_backs_off_and_retries() -> void:
	var f: Array = _ads()
	(f[2] as Object).on_consent_info_updated_success.emit()
	(f[0] as Object).on_initialization_complete.emit({})
	var uid: int = int((f[1] as Object).last_args("load")[3])
	(f[1] as Object).on_rewarded_ad_failed_to_load.emit(uid, {"code": 3, "message": "No fill"})
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE), "no ad, no button")
	runner.eq((f[1] as Object).count("load"), 1, "not hammered immediately")
	Ads.debug_expire_timers()
	runner.eq((f[1] as Object).count("load"), 2, "retried after the backoff")
	_done(f)


func test_owning_the_licence_stops_ads_being_loaded_at_all() -> void:
	Ads.ads_removed = true
	var f: Array = _ads()
	(f[2] as Object).on_consent_info_updated_success.emit()
	(f[0] as Object).on_initialization_complete.emit({})
	runner.eq((f[1] as Object).count("load"), 0, "a paying player never loads an ad")
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE), "or sees one offered")
	_done(f)


func test_the_privacy_options_form_is_reachable() -> void:
	var f: Array = _ads()
	runner.check(Ads.show_privacy_options(), "the withdrawal path exists")
	runner.eq((f[3] as Object).count("show_privacy_options_form"), 1, "and calls the plugin")
	_done(f)
