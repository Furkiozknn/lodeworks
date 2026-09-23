extends RefCounted

## Every state a purchase can be in, driven through the real code.
##
## These do not mock the Store. They feed `Store` the same records a billing
## plugin feeds it -- dictionaries with `product_id`, `purchase_state`,
## `purchase_token`, `is_acknowledged` -- through `debug_ingest`, and the same
## response codes through `debug_purchase_error`. So what passes here is the
## path the shipped build takes, not a parallel one written to be testable.
##
## The enumerated cases, each with its own test below:
##
##   product found · product not found · purchase success · purchase cancelled
##   · purchase pending · pending that clears · pending that is abandoned ·
##   restore · duplicate delivery · entitlement persistence across a restart ·
##   entitlement survives save/load · entitlement survives a collapse ·
##   offline earnings with and without it · rewarded x2 · ad failure ·
##   billing unavailable · SDK absent · no network · tampered entitlement data
##
## **None of this is a claim about a real store.** Nothing here has been near
## Google Play. What these prove is that the client handles each state the
## documented way; whether the product is actually purchasable in a real store
## account is UNKNOWN until somebody buys one.

var runner: Object

const BOARD := [
	[3, 4, "drill"], [4, 4, "vault"], [3, 5, "drill"], [2, 4, "crusher"],
	[2, 5, "crusher"], [4, 5, "vault"], [3, 3, "drill"], [2, 3, "crusher"],
	[4, 3, "vault"],
]

## Google Play's Purchase.PurchaseState values.
const STATE_UNSPECIFIED := 0
const STATE_PURCHASED := 1
const STATE_PENDING := 2


func before_each() -> void:
	Store.debug_clear_state()
	MonetizationDB.clear_force()
	Ads.debug_set_broken(false)
	Ads.ads_removed = false


func after_each() -> void:
	MonetizationDB.clear_force()


func _record(key: String, state: int, token: String = "tok",
		acked: bool = false) -> Dictionary:
	return {
		"product_id": MonetizationDB.store_id(key),
		"purchase_state": state,
		"purchase_token": token,
		"is_acknowledged": acked,
	}


func _run(ticks: int) -> Dictionary:
	var g := Grid.new()
	for e: Array in BOARD:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var s := Simulation.new(g, 31337)
	return s.run_ticks(ticks)


## --- the catalogue itself ---------------------------------------------------

func test_the_catalogue_sells_nothing_that_touches_the_economy() -> void:
	# The single most important assertion in the project. If this ever fails,
	# the game has become pay-to-win and it says so here rather than in a
	# review.
	runner.eq(MonetizationDB.ECONOMY_GRANTS.size(), 0,
		"no product may grant anything the simulation reads")
	for key: String in MonetizationDB.keys():
		var grants: Dictionary = MonetizationDB.grants_of(key)
		runner.gt(float(grants.size()), 0.0, "a product must grant something: " + key)
		for g: String in grants:
			runner.check(MonetizationDB.ALLOWED_GRANTS.has(g),
				"%s grants '%s', which is not on the allowed list" % [key, g])
			runner.check(not MonetizationDB.ECONOMY_GRANTS.has(g),
				"%s grants an economy effect: %s" % [key, g])


func test_every_product_has_ids_copy_and_a_place_to_appear() -> void:
	for key: String in MonetizationDB.keys():
		var p: Dictionary = MonetizationDB.product(key)
		runner.check(String(p.get("store_id", "")) != "", "no store id: " + key)
		runner.eq(String(p.get("type", "")), "inapp",
			"%s must be one-time, never a subscription" % key)
		runner.check(not bool(p.get("consumable", false)),
			"%s must be non-consumable -- nothing here is spent" % key)
		runner.check(MonetizationDB.title_of(key) != "", "no title: " + key)
		runner.check(MonetizationDB.headline_of(key) != "", "no headline: " + key)
		runner.gt(float(MonetizationDB.bullets_of(key).size()), 0.0,
			"no bullets: " + key)
		for b: String in MonetizationDB.bullets_of(key):
			runner.check(b.length() <= 46,
				"a bullet has to fit one line on a narrow phone: '%s'" % b)
		runner.gt(float((p.get("placements", []) as Array).size()), 0.0,
			"a product nobody can reach: " + key)
		for pl: String in (p.get("placements", []) as Array):
			runner.check(MonetizationDB.PLACEMENTS.has(pl),
				"%s appears at an undeclared placement: %s" % [key, pl])
			runner.check(not MonetizationDB.FORBIDDEN_PLACEMENTS.has(pl),
				"%s appears at a forbidden placement: %s" % [key, pl])


func test_no_placement_interrupts_play() -> void:
	# The whole shape of the monetization: every offer is somewhere the player
	# chose to go. Nothing arrives.
	for pl: String in MonetizationDB.PLACEMENTS:
		runner.check(not bool((MonetizationDB.PLACEMENTS[pl] as Dictionary)
			.get("interrupts_play", true)),
			"placement '%s' interrupts play" % pl)


func test_product_ids_are_valid_play_identifiers() -> void:
	# Play product ids: lowercase letters, digits, underscore and period, must
	# start with a letter or digit. A malformed one fails at upload, which is
	# a slow way to find out.
	var re := RegEx.new()
	re.compile("^[a-z0-9][a-z0-9_.]*$")
	for key: String in MonetizationDB.keys():
		var p: Dictionary = MonetizationDB.product(key)
		for field: String in ["store_id", "sandbox_id"]:
			var id: String = String(p.get(field, ""))
			if id == "":
				continue
			runner.check(re.search(id) != null,
				"%s.%s is not a valid Play product id: %s" % [key, field, id])


func test_store_ids_are_unique_across_the_catalogue() -> void:
	var seen: Dictionary = {}
	for key: String in MonetizationDB.keys():
		var p: Dictionary = MonetizationDB.product(key)
		for field: String in ["store_id", "sandbox_id"]:
			var id: String = String(p.get(field, ""))
			if id == "":
				continue
			runner.check(not seen.has(id), "duplicate product id: " + id)
			seen[id] = true


func test_test_and_production_ids_are_separate_and_both_resolve() -> void:
	MonetizationDB.force_sandbox(false)
	var live: Array = MonetizationDB.all_store_ids()
	MonetizationDB.force_sandbox(true)
	var sandbox: Array = MonetizationDB.all_store_ids()
	MonetizationDB.clear_force()
	runner.eq(live.size(), MonetizationDB.ORDER.size(), "every product has a live id")
	runner.eq(sandbox.size(), MonetizationDB.ORDER.size(), "and a sandbox id")
	for id: String in live:
		runner.check(not sandbox.has(id),
			"a sandbox build must not be able to touch the live SKU: " + id)
	# Both directions map home, so a purchase made by either build is still
	# the player's purchase on the other.
	for id: String in live + sandbox:
		runner.check(MonetizationDB.key_for_store_id(id) != "",
			"an id the game issued does not map back: " + id)


## --- product details --------------------------------------------------------

func test_product_found_makes_it_purchasable() -> void:
	Store.debug_set_available(true)
	Store.debug_set_confirmed(MonetizationDB.LICENCE, true)
	runner.check(Store.product_confirmed(MonetizationDB.LICENCE),
		"a product the store returned is confirmed")
	runner.check(Store.can_purchase(MonetizationDB.LICENCE),
		"and a confirmed product on an available store is purchasable")


func test_product_not_found_is_never_purchasable() -> void:
	# The case that produces a buy button that fails: the code knows the id,
	# the store has never heard of it.
	Store.debug_set_available(true)
	Store.debug_set_confirmed(MonetizationDB.LICENCE, false)
	runner.check(not Store.product_confirmed(MonetizationDB.LICENCE),
		"an unconfirmed product stays unconfirmed")
	runner.check(not Store.can_purchase(MonetizationDB.LICENCE),
		"and must never be offered")
	runner.check(not Store.purchase(MonetizationDB.LICENCE),
		"and purchasing it must fail cleanly rather than throw")


func test_an_unknown_id_from_the_store_grants_nothing() -> void:
	var granted: bool = Store.debug_ingest({
		"product_id": "infinite_credits",
		"purchase_state": STATE_PURCHASED,
		"purchase_token": "t",
	})
	runner.check(not granted, "an id this build does not sell is not an entitlement")
	runner.check(not Store.owns("infinite_credits"), "and cannot be owned")


## --- the purchase itself ----------------------------------------------------

func test_purchase_success_grants_exactly_once() -> void:
	var completed: Array = []
	var cb := func(k: String): completed.append(k)
	Store.purchase_completed.connect(cb)
	var changed: bool = Store.debug_ingest(_record(MonetizationDB.LICENCE,
		STATE_PURCHASED))
	Store.purchase_completed.disconnect(cb)
	runner.check(changed, "a purchased record grants")
	runner.check(Store.owns(MonetizationDB.LICENCE), "the product is owned")
	runner.eq(Store.state_of(MonetizationDB.LICENCE), Store.State.OWNED, "state")
	runner.eq(completed.size(), 1, "and the signal fires exactly once")


func test_purchase_cancelled_says_nothing_and_charges_nothing() -> void:
	# A player who backs out of the Play sheet has not failed at anything.
	# Nagging them about it is how a shop earns a one-star review.
	var failures: Array = []
	var cb := func(_k: String, reason: String): failures.append(reason)
	Store.purchase_failed.connect(cb)
	Store.debug_purchase_error(Store.CODE_USER_CANCELED)
	Store.purchase_failed.disconnect(cb)
	runner.eq(failures.size(), 1, "the flow ends")
	runner.eq(String(failures[0]), "cancelled", "and is recorded as a cancel")
	runner.eq(Store.last_player_message, "",
		"a cancel must produce no message at the player at all")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing is granted")


func test_a_pending_purchase_grants_nothing_and_is_not_acknowledged() -> void:
	# Google Play: do not grant entitlement for PENDING, and do not
	# acknowledge it either -- the three-day acknowledgement clock only starts
	# when it becomes PURCHASED. An integration that grants here hands out the
	# product for a payment that may never land.
	var pending: Array = []
	var cb := func(k: String): pending.append(k)
	Store.purchase_pending.connect(cb)
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PENDING, "slowcard"))
	Store.purchase_pending.disconnect(cb)
	runner.eq(pending.size(), 1, "the pending state is reported")
	runner.check(Store.is_pending(MonetizationDB.LICENCE), "and recorded")
	runner.check(not Store.owns(MonetizationDB.LICENCE),
		"a pending purchase must NOT grant the entitlement")
	runner.eq(Store.debug_ack_queue(), 0,
		"and must NOT be acknowledged while pending")
	runner.near(Store.bonus_offline_hours(), 0.0, 0.001,
		"nor grant any part of what it would grant")


func test_a_pending_purchase_that_clears_grants_once() -> void:
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PENDING, "slowcard"))
	runner.check(Store.is_pending(MonetizationDB.LICENCE), "pending first")
	var changed: bool = Store.debug_ingest(_record(MonetizationDB.LICENCE,
		STATE_PURCHASED, "slowcard"))
	runner.check(changed, "the transition grants")
	runner.check(Store.owns(MonetizationDB.LICENCE), "and the product is owned")
	runner.check(not Store.is_pending(MonetizationDB.LICENCE), "no longer pending")
	runner.gt(float(Store.debug_ack_queue()), 0.0,
		"and NOW it must be acknowledged, or Google refunds it in three days")


func test_a_pending_purchase_that_is_abandoned_grants_nothing() -> void:
	# The slow test card that declines. The record comes back in an
	# unspecified state and the pending mark has to come off.
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PENDING, "slowcard"))
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_UNSPECIFIED, "slowcard"))
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted")
	runner.check(not Store.is_pending(MonetizationDB.LICENCE),
		"and the game stops telling the player to wait for it")


func test_buying_something_already_pending_is_refused_politely() -> void:
	Store.debug_set_available(true)
	Store.debug_set_confirmed(MonetizationDB.LICENCE, true)
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PENDING, "slowcard"))
	runner.check(not Store.can_purchase(MonetizationDB.LICENCE),
		"a pending product is not offered a second time")
	runner.check(not Store.purchase(MonetizationDB.LICENCE),
		"and a second attempt is refused rather than double-charging")
	runner.check(Store.last_player_message.contains("waiting")
		or Store.last_player_message.contains("Waiting"),
		"and the player is told why, in words: " + Store.last_player_message)


func test_duplicate_delivery_of_the_same_purchase_grants_once() -> void:
	# queryPurchases returns the same record on every connect, forever. A
	# grant that is not idempotent fires a "thank you" toast on every launch.
	var completed: Array = []
	var cb := func(k: String): completed.append(k)
	Store.purchase_completed.connect(cb)
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED, "tok"))
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED, "tok"))
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED, "tok"))
	Store.purchase_completed.disconnect(cb)
	runner.eq(completed.size(), 1, "three deliveries, one grant")
	runner.check(Store.owns(MonetizationDB.LICENCE), "and it is owned")


func test_buying_something_already_owned_succeeds_without_charging() -> void:
	Store.debug_grant(MonetizationDB.LICENCE)
	var completed: Array = []
	var cb := func(k: String): completed.append(k)
	Store.purchase_completed.connect(cb)
	var ok: bool = Store.purchase(MonetizationDB.LICENCE)
	Store.purchase_completed.disconnect(cb)
	runner.check(ok, "buying what you own is a no-op success, not an error")
	runner.eq(completed.size(), 1, "the UI is told so it can redraw as owned")


func test_item_already_owned_triggers_a_restore_not_an_error() -> void:
	# Almost always a previous purchase that never reached this install.
	# Showing an error at somebody who has already paid is the worst possible
	# response.
	var failures: Array = []
	var cb := func(_k: String, reason: String): failures.append(reason)
	Store.purchase_failed.connect(cb)
	Store.debug_purchase_error(Store.CODE_ITEM_ALREADY_OWNED)
	Store.purchase_failed.disconnect(cb)
	runner.eq(String(failures[0]), "already_owned", "classified correctly")
	runner.check(Store.last_player_message.to_lower().contains("already own"),
		"and the player is told it is being restored, not that it failed")


## --- restore ----------------------------------------------------------------

func test_restore_grants_a_purchase_made_on_another_device() -> void:
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing to start")
	# What queryPurchases hands back on a fresh install of a paying player.
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED, "old", true))
	runner.check(Store.owns(MonetizationDB.LICENCE), "restored")
	runner.eq(Store.debug_ack_queue(), 0,
		"an already-acknowledged purchase must not be acknowledged again")


func test_restore_without_a_store_does_nothing_and_does_not_throw() -> void:
	Store.debug_set_available(false)
	Store.restore()
	runner.check(not Store.owns(MonetizationDB.LICENCE),
		"restore with no store grants nothing")


func test_a_purchase_record_with_no_state_field_is_honoured() -> void:
	# Older plugin majors return only completed purchases from queryPurchases
	# and carry no state field. Refusing to grant would lose somebody their
	# purchase; refusing to grant a record that DOES say pending would not.
	var changed: bool = Store.debug_ingest({
		"product_id": MonetizationDB.store_id(MonetizationDB.LICENCE),
		"purchase_token": "legacy",
	})
	runner.check(changed, "a stateless record from an old plugin still grants")
	runner.check(Store.owns(MonetizationDB.LICENCE), "owned")


func test_purchase_state_is_read_as_a_string_too() -> void:
	Store.debug_ingest({
		"product_id": MonetizationDB.store_id(MonetizationDB.LICENCE),
		"purchase_state": "PENDING",
		"purchase_token": "s",
	})
	runner.check(Store.is_pending(MonetizationDB.LICENCE),
		"a plugin that reports state as a string must not be read as purchased")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted")


## --- entitlement persistence ------------------------------------------------

func test_an_entitlement_survives_a_restart() -> void:
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED))
	Store.debug_ingest(_record(MonetizationDB.THEMES, STATE_PURCHASED, "t2"))
	# Exactly what a relaunch does: forget everything in memory, read the file.
	Store.debug_clear_state()
	Store._load_owned()
	runner.check(Store.owns(MonetizationDB.LICENCE), "the licence came back")
	runner.check(Store.owns(MonetizationDB.THEMES), "and so did the palettes")


func test_a_pending_purchase_is_never_persisted() -> void:
	# Pending is the platform's fact, not ours. Writing it down would mean a
	# relaunch showing "waiting on your payment" for a payment that was
	# abandoned weeks ago.
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PENDING, "slow"))
	Store.debug_clear_state()
	Store._load_owned()
	runner.check(not Store.is_pending(MonetizationDB.LICENCE),
		"a pending state must not come back from disk")
	runner.check(not Store.owns(MonetizationDB.LICENCE), "and certainly not as owned")


func test_a_tampered_entitlement_file_is_discarded_whole() -> void:
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED))
	var f := FileAccess.open(Store.OWNED_PATH, FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	runner.check(parsed.has("_c"), "a written file carries its checksum")
	# Add a product the player never bought, leaving the checksum stale.
	parsed[MonetizationDB.THEMES] = true
	f = FileAccess.open(Store.OWNED_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(parsed))
	f.close()
	Store.debug_clear_state()
	Store._load_owned()
	runner.check(not Store.owns(MonetizationDB.THEMES),
		"a forged entitlement is not honoured")
	runner.check(not Store.owns(MonetizationDB.LICENCE),
		"and the rest of the file goes with it -- restore() is the recovery")
	runner.eq(Store.last_error, "entitlements_tampered", "and it is recorded")


func test_a_corrupt_entitlement_file_does_not_take_the_game_down() -> void:
	var f := FileAccess.open(Store.OWNED_PATH, FileAccess.WRITE)
	f.store_string("{this is not json at all")
	f.close()
	Store.debug_clear_state()
	Store._load_owned()
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted")
	var out: Dictionary = _run(200)
	runner.gt(float(out["credits"]), 0.0, "and the factory still runs")


func test_an_entitlement_survives_a_collapse() -> void:
	# A collapse resets credits, research, the board and the depth. It must
	# not reset something somebody paid for.
	Store.debug_ingest(_record(MonetizationDB.LICENCE, STATE_PURCHASED))
	var before: float = Store.bonus_offline_hours()
	Sim._ensure()
	var depth_before: int = Sim.max_depth
	Sim.max_depth = maxi(Sim.max_depth, Economy.COLLAPSE_MIN_DEPTH)
	Sim.lifetime_credits = 10000.0
	Sim.collapse()
	Sim.max_depth = depth_before
	runner.check(Store.owns(MonetizationDB.LICENCE), "still owned after a collapse")
	runner.near(Store.bonus_offline_hours(), before, 0.001, "and still granting")


## --- what the entitlement actually does -------------------------------------

func test_offline_earnings_differ_only_by_the_cap() -> void:
	# The licence's whole economic footprint, measured: the same live rate and
	# the same offline fraction, over more hours. Nothing is multiplied.
	var mult_free: Dictionary = Economy.multipliers({})
	var free: Dictionary = Economy.offline_yield(10.0, 86400.0, mult_free)
	Store.debug_grant(MonetizationDB.LICENCE)
	var mult_paid: Dictionary = mult_free.duplicate()
	mult_paid["offline_hours"] = float(mult_free["offline_hours"]) \
		+ Store.bonus_offline_hours()
	var paid: Dictionary = Economy.offline_yield(10.0, 86400.0, mult_paid)
	runner.near(float(free["rate"]), float(paid["rate"]), 0.0001,
		"the offline fraction is identical -- no secret multiplier")
	runner.gt(float(paid["seconds_counted"]), float(free["seconds_counted"]),
		"only the number of hours counted changes")
	var ratio: float = float(paid["amount"]) / maxf(float(free["amount"]), 0.001)
	runner.near(ratio, 2.0, 0.01,
		"at base multipliers the licence is exactly the rewarded ad, permanently")


func test_the_rewarded_double_is_exactly_double() -> void:
	var mult: Dictionary = Economy.multipliers({})
	var plain: Dictionary = Economy.offline_yield(12.0, 7200.0, mult, false)
	var doubled: Dictionary = Economy.offline_yield(12.0, 7200.0, mult, true)
	runner.near(float(doubled["amount"]), float(plain["amount"]) * 2.0, 0.0001,
		"the ad doubles what the panel already showed, and nothing else")
	runner.near(float(doubled["seconds_counted"]), float(plain["seconds_counted"]),
		0.0001, "it does not quietly extend the window as well")


func test_the_ad_is_never_offered_to_someone_who_paid() -> void:
	# Asking a paying player to watch an ad is how a purchase stops feeling
	# like one.
	Store.debug_grant(MonetizationDB.LICENCE)
	runner.check(Ads.ads_removed, "buying the licence removes ads")
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE),
		"and the offer disappears entirely")
	runner.eq(String(MonetizationDB.AD_PLACEMENTS[MonetizationDB.AD_DOUBLE_OFFLINE]
		.get("suppressed_by", "")), MonetizationDB.LICENCE,
		"and the catalogue says so, so the rule is data rather than a habit")


func test_a_failed_ad_grants_nothing_and_leaves_the_game_playable() -> void:
	Ads.debug_set_broken(true)
	var before: float = Sim.credits
	var ok: bool = Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE)
	runner.check(not ok, "a broken SDK refuses rather than hanging")
	runner.near(Sim.credits, before, 0.0001, "and nothing is credited")
	var out: Dictionary = _run(200)
	runner.gt(float(out["credits"]), 0.0, "and the factory keeps running")


func test_blueprint_slots_come_from_the_catalogue_not_from_a_constant() -> void:
	var base: int = Sim.blueprint_slots()
	Store.debug_grant(MonetizationDB.LICENCE)
	var paid: int = Sim.blueprint_slots()
	runner.eq(paid - base, int(MonetizationDB.grant_value(MonetizationDB.LICENCE,
		MonetizationDB.GRANT_BLUEPRINT_SLOTS, 0)),
		"the game reads the same table the shop describes")


## --- store failure modes ----------------------------------------------------

func test_billing_unavailable_stops_offering_everything() -> void:
	Store.debug_set_available(true)
	for k: String in MonetizationDB.keys():
		Store.debug_set_confirmed(k, true)
	Store.debug_purchase_error(Store.CODE_BILLING_UNAVAILABLE)
	for k: String in MonetizationDB.keys():
		runner.check(not Store.can_purchase(k),
			"billing unavailable means nothing is offered: " + k)
	runner.check(Store.last_player_message.to_lower().contains("billing"),
		"and the player is told it is the device, not the game")


func test_a_network_failure_says_nothing_was_charged() -> void:
	# The single most important sentence a failed purchase can contain.
	Store.debug_purchase_error(Store.CODE_NETWORK_ERROR)
	runner.check(Store.last_player_message.to_lower().contains("nothing was charged"),
		"a network failure must say so plainly: " + Store.last_player_message)
	runner.check(not Store.owns(MonetizationDB.LICENCE), "and grant nothing")


func test_an_unrecognised_error_code_still_fails_safely() -> void:
	Store.debug_purchase_error(9999)
	runner.check(not Store.owns(MonetizationDB.LICENCE), "nothing granted")
	runner.check(Store.last_player_message != "",
		"and the player is not left with a silent dead button")


func test_error_codes_arrive_as_strings_too() -> void:
	Store.debug_purchase_error("USER_CANCELED")
	runner.eq(Store.last_player_message, "",
		"a string cancel is still a cancel, not a scary error")


func test_no_sdk_at_all_is_a_complete_playable_game() -> void:
	# The path CI, the editor and every desktop build take.
	runner.check(not Store.is_available(), "no billing plugin in a test build")
	runner.check(not bool(Ads.status().get("plugin_present", false)),
		"and no ad plugin either")
	for k: String in MonetizationDB.keys():
		runner.check(not Store.can_purchase(k), "nothing is offered: " + k)
	var out: Dictionary = _run(400)
	runner.gt(float(out["credits"]), 0.0, "and the game earns exactly as it should")
	runner.gt(float(Sim.offline_hours()), 0.0, "with offline banking intact")


func test_the_status_report_never_claims_more_than_it_knows() -> void:
	var st: Dictionary = Store.status()
	runner.check(not bool(st["plugin_present"]), "no plugin")
	runner.eq((st["owned"] as Array).size(), 0, "nothing owned")
	runner.eq((st["pending"] as Array).size(), 0, "nothing pending")
	runner.eq((st["confirmed"] as Array).size(), 0, "nothing confirmed")
	runner.eq(String(st["theme"]), Themes.DEFAULT, "and the free palette is active")


## --- themes: the cosmetic product ------------------------------------------

func test_a_theme_cannot_change_a_single_economy_number() -> void:
	# The claim the whole cosmetic product rests on, checked the only way that
	# settles it: run the same board under every palette and compare.
	var base: Dictionary = _run(400)
	for id: String in Themes.ORDER:
		Palette.set_theme(id)
		var out: Dictionary = _run(400)
		runner.near(float(out["credits"]), float(base["credits"]), 0.0001,
			"palette '%s' changed what the board earns" % id)
		runner.near(float(out["research"]), float(base["research"]), 0.0001,
			"palette '%s' changed research" % id)
	Palette.set_theme(Themes.DEFAULT)


func test_a_locked_theme_cannot_be_selected() -> void:
	runner.check(not Store.owns(MonetizationDB.THEMES), "unpaid to start")
	for id: String in Themes.ORDER:
		if Themes.is_free(id):
			continue
		runner.check(not Store.select_theme(id),
			"a locked palette must be refused, not silently ignored: " + id)
		runner.eq(Store.active_theme(), Themes.DEFAULT, "and the board stays put")


func test_buying_the_palettes_unlocks_every_one() -> void:
	Store.debug_grant(MonetizationDB.THEMES)
	for id: String in Themes.ORDER:
		runner.check(Store.theme_unlocked(id), "unlocked: " + id)
		runner.check(Store.select_theme(id), "and selectable: " + id)
		runner.eq(Palette.theme(), id, "and the board is actually drawing it")
	Store.select_theme(Themes.DEFAULT)


func test_a_selected_theme_falls_back_if_the_entitlement_goes_away() -> void:
	# A refund, a revoked purchase, a restore on an account that does not own
	# it. The board must not keep drawing something that is no longer paid for,
	# and must not break either.
	Store.debug_grant(MonetizationDB.THEMES)
	Store.select_theme("ember")
	Store.debug_revoke()
	runner.eq(Store.active_theme(), Themes.DEFAULT,
		"the palette reverts when the entitlement does")


func test_every_theme_is_complete_and_keeps_the_status_language() -> void:
	runner.eq(Themes.count(), 6, "the copy says six palettes")
	runner.eq(Themes.paid_count(), Themes.count() - 1, "one of them is free")
	for id: String in Themes.ORDER:
		var t: Dictionary = Themes.get_theme(id)
		runner.check(String(t.get("name", "")) != "", "unnamed theme: " + id)
		var machines: Dictionary = Themes.machine_colors(id)
		for m: String in Themes.REQUIRED_MACHINES:
			runner.check(machines.has(m),
				"theme '%s' has no colour for %s" % [id, m])
		runner.eq(Themes.resource_colors(id).size(), 5,
			"theme '%s' must colour all five resources" % id)
		runner.eq(Themes.heat_ramp(id).size(), 3,
			"theme '%s' needs a three-stop heat ramp" % id)
	# The status lights are NOT themeable. Amber means look downstream and red
	# means look upstream; a palette that repainted them would be selling
	# somebody a board that is harder to read.
	runner.check(Palette.ST_RUNNING != Palette.ST_BLOCKED, "")
	runner.check(Palette.ST_BLOCKED != Palette.ST_STARVED,
		"the three directional status colours stay distinct in every theme")


func test_a_theme_choice_survives_a_restart() -> void:
	Store.debug_grant(MonetizationDB.THEMES)
	Store.select_theme("frost")
	Store.debug_clear_state()
	Store._load_owned()
	Store._apply()
	runner.check(Store.owns(MonetizationDB.THEMES), "still owned")
	runner.eq(Store.active_theme(), "frost", "and still wearing the same palette")
	runner.eq(Palette.theme(), "frost", "and the board agrees")


func test_theme_colours_are_all_parseable() -> void:
	# A malformed hex string draws as black and is very hard to spot in a
	# screenshot of a dark game.
	for id: String in Themes.ORDER:
		for c: Color in Themes.machine_colors(id).values():
			runner.check(c.a > 0.0, "transparent machine colour in " + id)
			runner.gt(c.r + c.g + c.b, 0.05,
				"a machine in '%s' is drawn black" % id)


## --- store listing copy -----------------------------------------------------

func test_the_console_checklist_is_complete() -> void:
	# What somebody has to type into the Play Console, generated from the same
	# table the game reads rather than written down twice.
	var rows: Array = MonetizationDB.console_checklist()
	runner.eq(rows.size(), MonetizationDB.ORDER.size(), "one row per product")
	for r: Dictionary in rows:
		runner.check(String(r["product_id"]) != "", "no id")
		runner.check(String(r["title"]).length() <= 55,
			"Play caps an in-app product title at 55 characters: " + String(r["title"]))
		# Play: "The description must be 200 single byte characters or less."
		runner.check(String(r["description"]).length() <= 200,
			"Play caps an in-app product description at 200 characters (%d): %s"
			% [String(r["description"]).length(), String(r["product_id"])])
		runner.gt(float(r["suggested_tier_usd"]), 0.0, "a price tier to type in")
		runner.lte(float(r["suggested_tier_usd"]), 4.99,
			"sourced review-mining puts well-received one-time purchases at or "
			+ "below $4.99; above that the complaints start")


## --- the economic bound -----------------------------------------------------
##
## `tools/money_lab.gd` plays a fortnight of a twice-a-day player four ways and
## reports the ratio between them. These lock the finding in place so that a
## future change to a grant, a cap or an offline rule cannot quietly turn a
## convenience purchase into a power purchase without a test going red.

const FORTNIGHT_DAYS := 14
const SESSIONS_PER_DAY := 2
const SESSION_SECONDS := 900.0


func _fortnight(licensed_from: int, watches_ads: bool) -> float:
	var live: float = 10.0
	var away: float = (86400.0 / float(SESSIONS_PER_DAY)) - SESSION_SECONDS
	var base: Dictionary = Economy.multipliers({})
	var bonus: float = float(MonetizationDB.grant_value(MonetizationDB.LICENCE,
		MonetizationDB.GRANT_OFFLINE_HOURS, 0.0))
	var total: float = 0.0
	for day: int in range(FORTNIGHT_DAYS):
		var licensed: bool = day >= licensed_from
		var mult: Dictionary = base.duplicate()
		if licensed:
			mult["offline_hours"] = float(base["offline_hours"]) + bonus
		for _s: int in range(SESSIONS_PER_DAY):
			total += live * SESSION_SECONDS
			total += float(Economy.offline_yield(live, away, mult,
				watches_ads and not licensed)["amount"])
	return total


func test_paying_is_worth_convenience_not_power() -> void:
	var free: float = _fortnight(9999, false)
	var paid: float = _fortnight(0, false)
	var ratio: float = paid / free
	runner.gt(ratio, 1.05,
		"a purchase has to be worth something or nobody would make it")
	runner.lte(ratio, 2.0,
		"a fortnight of paying must stay inside 2x a free player -- past that "
		+ "it stops being convenience (measured %.3fx)" % ratio)


func test_paying_buys_exactly_what_watching_ads_buys() -> void:
	# The cleanest possible statement of what the money is for: the Licence
	# is not an advantage over a free player, it is the same advantage without
	# the thirty seconds. Measured over a fortnight rather than argued.
	var ad_watcher: float = _fortnight(9999, true)
	var licensed: float = _fortnight(0, false)
	runner.near(licensed, ad_watcher, ad_watcher * 0.001,
		"a free player who watches the ad must end the fortnight level with "
		+ "somebody who paid")


func test_a_free_player_reaches_everything() -> void:
	# Nothing in the catalogue gates content, so this is a statement about the
	# catalogue rather than about the progression: no grant can unlock a
	# machine, a stratum or an upgrade, because no such grant exists.
	for key: String in MonetizationDB.keys():
		for g: String in MonetizationDB.grants_of(key):
			runner.check(not ["machines", "strata", "upgrades", "credits",
				"research", "cores", "speed", "yield", "value"].has(g),
				"%s grants '%s', which would gate or accelerate content" % [key, g])
	# And the research tree -- the only permanent progression there is -- costs
	# nothing but Research and Cores, both of which are earned by playing.
	for id: String in Economy.RESEARCH_TREE:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		runner.check(u.has("cost_research") and u.has("cost_cores"),
			"an upgrade priced in something other than earned currency: " + id)
