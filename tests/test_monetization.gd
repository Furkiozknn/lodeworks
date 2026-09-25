extends RefCounted

## Monetization must not be able to touch the game.
##
## The design claim is that ads and the one purchase sit outside the economy:
## a paying player and a free player run the same simulation and get the same
## numbers, and a broken or absent SDK costs nothing but the ad itself. That
## claim is only worth something if it is checked, because it is exactly the
## kind of thing that stops being true quietly, six months later, in a hurry.
##
## So these tests assert three separate things:
##
##   1. No path through `Ads` or `Store` changes credits, research or cores.
##   2. The game remains fully playable when the ad SDK is present and broken,
##      which is the failure nobody writes code for.
##   3. `Analytics` sends only the events that were decided on, and cannot be
##      widened by a caller passing extra properties.

var runner: Object

const BOARD := [
	[3, 4, "drill"], [4, 4, "vault"], [3, 5, "drill"], [2, 4, "crusher"],
	[2, 5, "crusher"], [4, 5, "vault"], [3, 3, "drill"], [2, 3, "crusher"],
	[4, 3, "vault"],
]


func before_each() -> void:
	Store.debug_revoke()
	Ads.debug_set_broken(false)
	Ads.ads_removed = false
	Analytics.debug_reset_milestones()


func _run(ticks: int) -> Dictionary:
	var g := Grid.new()
	for e: Array in BOARD:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var s := Simulation.new(g, 31337)
	return s.run_ticks(ticks)


## --- the economy cannot be touched -----------------------------------------

func test_owning_the_licence_changes_no_economy_number() -> void:
	var free: Dictionary = _run(400)
	Store.debug_grant(Store.LICENCE)
	runner.check(Store.has_licence(), "the test needs the licence granted")
	var paid: Dictionary = _run(400)
	runner.near(float(paid["credits"]), float(free["credits"]), 0.0001,
		"a paying player must earn exactly what a free player earns")
	runner.near(float(paid["research"]), float(free["research"]), 0.0001,
		"and research exactly the same")


func test_removing_ads_changes_no_economy_number() -> void:
	var with_ads: Dictionary = _run(400)
	Ads.ads_removed = true
	var without: Dictionary = _run(400)
	runner.near(float(without["credits"]), float(with_ads["credits"]), 0.0001,
		"whether ads exist must not reach the simulation at all")


func test_the_licence_grants_only_convenience() -> void:
	# Enumerated rather than spot-checked: the licence's entire effect has to
	# be these three things, so that "does it add power" has a short answer.
	runner.near(Store.bonus_offline_hours(), 0.0, 0.001, "nothing before purchase")
	runner.eq(Store.bonus_blueprint_slots(), 0, "no slots before purchase")
	Store.debug_grant(Store.LICENCE)
	runner.near(Store.bonus_offline_hours(),
		float(MonetizationDB.grant_value(Store.LICENCE,
			MonetizationDB.GRANT_OFFLINE_HOURS, 0.0)), 0.001, "offline hours")
	runner.eq(Store.bonus_blueprint_slots(),
		int(MonetizationDB.grant_value(Store.LICENCE,
			MonetizationDB.GRANT_BLUEPRINT_SLOTS, 0)), "slots")
	runner.check(Ads.ads_removed, "and ads stop existing")


func test_a_tampered_entitlement_file_cannot_invent_a_product() -> void:
	# The cache is a convenience for offline play, so it has to be bounded:
	# the worst a hand-edited file can do is grant the one thing that is only
	# convenience anyway.
	var f := FileAccess.open(Store.OWNED_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"foremans_licence": true,
		"infinite_credits": true,
		"all_strata": true,
	}))
	f.close()
	Store.debug_clear_state()
	Store._load_owned()
	# An unsigned legacy file is still read (an install from before the
	# checksum existed is somebody's real purchase), but only for keys this
	# build sells.
	runner.check(Store.owns(Store.LICENCE), "the real product is honoured")
	runner.check(not Store.owns("infinite_credits"),
		"a product this build does not sell cannot be owned")
	runner.check(not Store.owns("all_strata"), "nor can content be unlocked")
	Store.debug_revoke()


## --- a broken SDK must cost nothing ----------------------------------------

func test_a_broken_ad_sdk_still_leaves_the_game_playable() -> void:
	Ads.debug_set_broken(true)
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE),
		"a broken SDK must never offer a button")
	runner.check(not Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE),
		"and must refuse rather than hang or throw")
	# The factory still runs, which is the whole point.
	var out: Dictionary = _run(300)
	runner.gt(float(out["credits"]), 0.0,
		"the game must keep earning with the ad layer dead")


func test_a_failed_ad_costs_the_player_nothing() -> void:
	var failures: Array = []
	var cb := func(p: String, reason: String): failures.append([p, reason])
	Ads.reward_failed.connect(cb)
	Ads.debug_set_broken(true)
	var before_credits: float = Sim.credits
	Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE)
	Ads.reward_failed.disconnect(cb)
	runner.eq(failures.size(), 1, "a refusal must be reported, not swallowed")
	runner.near(Sim.credits, before_credits, 0.0001,
		"and must not have charged or credited anything")


func test_only_the_mvp_placement_is_offerable() -> void:
	# Two placements are written and tested but deliberately not shipped.
	# Shipping three ad surfaces at once means never learning which one
	# players wanted.
	runner.eq(Ads.MVP_PLACEMENTS.size(), 1, "one placement ships")
	runner.check(Ads.MVP_PLACEMENTS.has(Ads.P_DOUBLE_OFFLINE), "and it is the offline double")
	runner.check(not Ads.can_offer(Ads.P_REROLL_STRATUM),
		"a placement outside the MVP set can never be offered")
	runner.check(not Ads.can_offer(Ads.P_EXTRA_BLUEPRINT), "nor this one")


func test_an_ad_cannot_be_requested_while_one_is_pending() -> void:
	Ads._available = true
	Ads._last_shown = -9999.0
	Ads._pending = Ads.P_DOUBLE_OFFLINE
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE),
		"a second request while one is in flight would double-pay the reward")
	Ads._pending = ""
	Ads._available = false


func test_the_watchdog_is_longer_than_a_real_ad() -> void:
	# If this were shorter than a rewarded video, the watchdog would cancel
	# ads that were about to pay out.
	runner.gt(Ads.SHOW_TIMEOUT, 45.0,
		"a rewarded video plus its close button has to fit inside the timeout")
	runner.gt(Ads.COOLDOWN_SECONDS, 20.0, "and the game must not nag")


## --- purchases -------------------------------------------------------------

func test_nothing_is_purchasable_without_a_confirmed_product() -> void:
	for key: String in MonetizationDB.keys():
		runner.check(not Store.can_purchase(key),
			"with no billing plugin there is nothing to buy: " + key)
		runner.check(not Store.product_confirmed(key),
			"and the store has certainly not confirmed " + key)
		runner.check(not Store.purchase(key), "so purchase() must fail cleanly")


func test_no_price_is_ever_composed_locally() -> void:
	for key: String in MonetizationDB.keys():
		runner.eq(Store.price_text(key), "",
			"a price that did not come from the platform must not exist: " + key)


func test_the_purchase_flow_reports_its_own_state_honestly() -> void:
	var st: Dictionary = Store.status()
	runner.check(not bool(st["plugin_present"]), "no plugin in a test build")
	runner.eq((st["catalogue"] as Array).size(), MonetizationDB.ORDER.size(),
		"status names the whole catalogue")
	runner.eq((st["confirmed"] as Array).size(), 0,
		"status must not claim a product the store never confirmed")


## --- analytics -------------------------------------------------------------

func test_an_event_outside_the_vocabulary_is_dropped() -> void:
	var before: int = Analytics.event_count()
	Analytics.track("machine_placed", {"id": "drill"})
	Analytics.track("whatever_someone_adds_later")
	runner.eq(Analytics.event_count(), before,
		"an event not on the list must not be recorded")
	runner.check(Analytics.dropped_events().has("machine_placed"),
		"and the refusal must be visible, not silent")


func test_a_caller_cannot_smuggle_a_property_in() -> void:
	Analytics.track("session_start", {
		"depth": 3,
		"email": "someone@example.com",
		"device_id": "abc123",
	})
	var last: Dictionary = Analytics.recent(1)[0]
	runner.eq(int(last["depth"]), 3, "an allowed property survives")
	runner.check(not last.has("email"), "an unlisted property must be dropped")
	runner.check(not last.has("device_id"), "including anything identifying")


func test_an_event_carries_nothing_that_identifies_a_person() -> void:
	Analytics.track("session_start", {"depth": 0})
	var last: Dictionary = Analytics.recent(1)[0]
	for k: String in last.keys():
		var allowed: bool = ["e", "t", "s", "i", "v"].has(k) \
			or Analytics.ALLOWED_PROPS.has(k)
		runner.check(allowed, "unexpected key in an event payload: " + k)


func test_milestones_fire_exactly_once() -> void:
	var before: int = Analytics.event_count()
	Analytics.track("first_launch")
	Analytics.track("first_launch")
	Analytics.track("first_launch")
	runner.eq(Analytics.event_count(), before + 1,
		"a first launch happens once per install, however often it is called")


func test_the_vocabulary_is_exactly_what_was_decided() -> void:
	# Written out so that widening it is a visible change to this file and not
	# a line slipped into a service.
	var expected: Array[String] = [
		"first_launch", "session_start", "session_end", "tutorial_complete",
		"first_production", "first_upgrade", "depth_reached", "collapse",
		"rewarded_shown", "rewarded_completed",
		"iap_started", "iap_purchased", "iap_failed",
	]
	runner.eq(Analytics.ALLOWED.size(), expected.size(), "no events added quietly")
	for e: String in expected:
		runner.check(Analytics.ALLOWED.has(e), "missing event: " + e)


func test_turning_tracking_off_turns_it_off() -> void:
	Analytics.track("session_start", {"depth": 1})
	runner.gt(float(Analytics.event_count()), 0.0, "there is something to clear")
	Analytics.set_enabled(false)
	runner.eq(Analytics.event_count(), 0, "the buffer is cleared, not just paused")
	Analytics.track("session_start", {"depth": 1})
	runner.eq(Analytics.event_count(), 0, "and nothing new is recorded")
	# And it stays off: the next launch reads it before its first event.
	Analytics.enabled = true
	Analytics._load_consent()
	runner.check(not Analytics.enabled, "off survives a restart")
	Analytics.set_enabled(true)
	Analytics._load_consent()
	runner.check(Analytics.enabled, "and so does on")


## --- the self test itself --------------------------------------------------

func test_the_self_test_runs_and_reports_honestly() -> void:
	var results: Array = SelfTest.run_all(Sim)
	runner.gt(float(results.size()), 8.0, "every check should return a row")
	var ids: Array = []
	for r: Dictionary in results:
		ids.append(String(r["id"]))
		var st: String = String(r["status"])
		runner.check([SelfTest.PASS, SelfTest.FAIL, SelfTest.UNKNOWN,
			SelfTest.INFO].has(st), "unknown status '%s' for %s" % [st, r["id"]])
	for needed: String in ["cpu", "storage", "idle", "economy", "ads", "store",
			"analytics", "screen"]:
		runner.check(ids.has(needed), "missing check: " + needed)


func test_hardware_checks_say_unknown_rather_than_guessing() -> void:
	# The rule the whole project runs on: a number that was never measured is
	# worse than no number, because it stops anyone going and measuring it.
	var screen: Dictionary = SelfTest.screen_check()
	var renderer: Dictionary = SelfTest.renderer_info()
	runner.eq(String(screen["status"]), SelfTest.UNKNOWN,
		"there is no screen in a headless run, so there is no measurement")
	runner.eq(String(renderer["status"]), SelfTest.UNKNOWN,
		"and no rendering device either")


func test_the_self_test_catches_a_real_failure() -> void:
	# Prove the checks can fail, not just pass. A suite of checks that cannot
	# report a problem is decoration.
	Analytics.track("definitely_not_an_event")
	var r: Dictionary = SelfTest.analytics_check()
	runner.eq(String(r["status"]), SelfTest.FAIL,
		"a refused event must show up as a failure on the device report")
	Analytics.debug_reset_milestones()


func test_the_report_is_plain_text_with_no_identifiers() -> void:
	var text: String = SelfTest.as_text(SelfTest.run_all(Sim))
	runner.gt(float(text.length()), 100.0, "there is a report")
	runner.check(not text.contains(Analytics._install_id),
		"the install id must not travel in a report someone pastes publicly")
	runner.check(text.contains("passed"), "and it ends with a summary")
