extends RefCounted

## Economy, strata and the collapse. These guard the shape of a session: that
## descending stays worth doing, that collapsing is a real decision, and that
## offline earnings are an honest multiplication rather than a number someone
## made up.

var runner: Object


func test_quota_grows_but_the_first_few_are_reachable() -> void:
	# A first session has to include at least a couple of descents or the
	# player never sees the loop the game is built on.
	runner.lt(Strata.quota_for(0), 100.0, "first quota must fall in minutes")
	runner.lt(Strata.quota_for(1), 200.0, "second should too")
	runner.gt(Strata.quota_for(10), Strata.quota_for(5) * 5.0, "but it must climb")


func test_depth_zero_has_no_modifiers() -> void:
	# A new player meeting "Cramped" before placing a drill learns the wrong
	# lesson about what the game is.
	runner.eq(Strata.modifiers_for(0).size(), 0, "the first stratum is clean")


func test_strata_are_deterministic_per_depth() -> void:
	# Same depth, same stratum, for everyone, forever -- no server, and two
	# players can compare layouts for "stratum 14".
	for d in [1, 5, 14, 40]:
		var a: Array[String] = Strata.modifiers_for(d)
		var b: Array[String] = Strata.modifiers_for(d)
		runner.eq(a, b, "depth %d must be stable" % d)


func test_strata_actually_vary() -> void:
	var seen: Dictionary = {}
	for d in range(1, 40):
		seen[",".join(Strata.modifiers_for(d))] = true
	runner.gt(float(seen.size()), 8.0,
		"forty strata should not all look the same")


func test_modifiers_reach_the_description() -> void:
	# Find a depth carrying thermal_vent and check it actually got hotter.
	var found: bool = false
	for d in range(1, 120):
		if Strata.modifiers_for(d).has("thermal_vent"):
			var s: Dictionary = Strata.describe(d)
			var plain: float = Strata.AMBIENT_PER_DEPTH * float(d)
			runner.gt(float(s["ambient_heat"]), plain, "vent must add heat")
			found = true
			break
	runner.check(found, "thermal_vent should appear within 120 strata")


func test_cramped_blocks_the_outer_ring_only() -> void:
	var found: int = -1
	for d in range(1, 200):
		if Strata.modifiers_for(d).has("cramped"):
			found = d
			break
	runner.check(found > 0, "cramped should appear somewhere")
	if found <= 0:
		return
	var blocked: Dictionary = Strata.blocked_cells(found)
	# The outer ring is the yard's: the edge of the ground the factory has.
	var r: int = BuildArea.radius_at(found)
	var c: Rect2i = BuildArea.CORE
	runner.check(blocked.has(Grid.idx(c.position.x - r, c.position.y - r)),
		"the yard's corner is blocked")
	runner.check(not blocked.has(Grid.idx(c.position.x - 1, c.position.y)),
		"the ground by the Core is still usable")
	var open: int = 0
	for i in range(Grid.W * Grid.H):
		if BuildArea.is_open(i, found) and not blocked.has(i):
			open += 1
	runner.gt(float(open), 10.0, "cramped must still leave a playable yard")


func test_no_cores_before_the_minimum_depth() -> void:
	runner.eq(Economy.cores_for_collapse(0, 1e9), 0, "depth 0 yields nothing")
	runner.eq(Economy.cores_for_collapse(2, 1e9), 0, "below the floor yields nothing")
	runner.check(not Economy.can_collapse(2), "and collapse is refused")


func test_cores_reward_both_depth_and_earnings() -> void:
	var shallow: int = Economy.cores_for_collapse(4, 50000.0)
	var deep: int = Economy.cores_for_collapse(10, 50000.0)
	var rich: int = Economy.cores_for_collapse(4, 5000000.0)
	runner.gt(float(deep), float(shallow), "depth must matter")
	runner.gt(float(rich), float(shallow), "earnings must matter")


func test_core_gain_has_diminishing_returns_on_credits() -> void:
	# If it were linear, the correct play would be to never collapse, and the
	# whole prestige layer would be dead content.
	var a: int = Economy.cores_for_collapse(8, 100000.0)
	var b: int = Economy.cores_for_collapse(8, 1000000.0)
	runner.gt(float(b), float(a), "more credits still pays")
	runner.lt(float(b), float(a) * 10.0, "but not ten times for ten times")


func test_core_yield_upgrade_increases_the_payout() -> void:
	var plain: int = Economy.cores_for_collapse(8, 100000.0, 0.0)
	var boosted: int = Economy.cores_for_collapse(8, 100000.0, 0.5)
	runner.gt(float(boosted), float(plain), "the upgrade must be felt")


func test_upgrade_costs_rise_with_level() -> void:
	var l0: Dictionary = Economy.upgrade_cost("throughput_1", 0)
	var l4: Dictionary = Economy.upgrade_cost("throughput_1", 4)
	runner.gt(float(l4["research"]), float(l0["research"]) * 4.0, "")


func test_multipliers_start_neutral() -> void:
	var m: Dictionary = Economy.multipliers({})
	runner.near(float(m["speed"]), 1.0, 0.0001, "")
	runner.near(float(m["value"]), 1.0, 0.0001, "")
	runner.near(float(m["offline_hours"]), Economy.OFFLINE_BASE_HOURS, 0.0001, "")


func test_multipliers_accumulate() -> void:
	var m: Dictionary = Economy.multipliers({"throughput_1": 3})
	runner.near(float(m["speed"]), 1.0 + 0.45, 0.0001, "three levels of 15%")


func test_offline_hours_are_capped() -> void:
	# Without a cap, a player who returns after a holiday gets a number so
	# large that nothing they do afterwards matters.
	var m: Dictionary = Economy.multipliers({"offline_cap": 99})
	runner.check(float(m["offline_hours"]) <= Economy.OFFLINE_MAX_HOURS,
		"offline banking must stay bounded")


func test_offline_rate_never_exceeds_live_play() -> void:
	# Playing has to be better than not playing, or the game is a screensaver.
	var m: Dictionary = Economy.multipliers({"offline_rate": 99})
	runner.check(float(m["offline_rate"]) <= 1.0, "offline cannot beat online")


func test_offline_yield_is_rate_times_time_times_fraction() -> void:
	var m: Dictionary = Economy.multipliers({})
	var out: Dictionary = Economy.offline_yield(10.0, 3600.0, m)
	var expected: float = 10.0 * 3600.0 * Economy.OFFLINE_BASE_RATE
	runner.near(float(out["amount"]), expected, 0.01,
		"the number shown must be exactly this product")
	runner.check(not bool(out["capped"]), "one hour is under the cap")


func test_offline_yield_reports_when_it_capped() -> void:
	var m: Dictionary = Economy.multipliers({})
	var out: Dictionary = Economy.offline_yield(10.0, 3600.0 * 50.0, m)
	runner.check(bool(out["capped"]), "must admit to capping")
	runner.near(float(out["seconds_counted"]),
		Economy.OFFLINE_BASE_HOURS * 3600.0, 0.01, "")


func test_offline_double_is_exactly_double() -> void:
	var m: Dictionary = Economy.multipliers({})
	var plain: float = float(Economy.offline_yield(5.0, 1800.0, m)["amount"])
	var doubled: float = float(Economy.offline_yield(5.0, 1800.0, m, true)["amount"])
	runner.near(doubled, plain * 2.0, 0.001, "the rewarded ad must do what it says")


func test_offline_yield_of_nothing_is_nothing() -> void:
	var m: Dictionary = Economy.multipliers({})
	runner.near(float(Economy.offline_yield(0.0, 99999.0, m)["amount"]), 0.0, 0.0001,
		"an idle board earns nothing while away, same as it does while watched")


func test_number_formatting_is_readable() -> void:
	runner.eq(Economy.fmt(0.0), "0")
	runner.eq(Economy.fmt(42.0), "42")
	runner.eq(Economy.fmt(1500.0), "1.50K")
	runner.eq(Economy.fmt(2_400_000.0), "2.40M")
	runner.eq(Economy.fmt(999_000_000_000.0), "999B")


func test_duration_formatting() -> void:
	runner.eq(Economy.fmt_duration(45.0), "45s")
	runner.eq(Economy.fmt_duration(3600.0 * 5 + 60.0 * 7), "5h 7m")


## --- research without an end (owner's decision, 25 September 2026) ----------

func test_every_collapse_raises_the_growing_lines_and_only_those() -> void:
	var growing: int = 0
	for id: String in Economy.RESEARCH_TREE:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		var base: int = int(u["max"])
		runner.eq(Economy.max_level(id, 0), base, id + ": the first limit is the line's own")
		if bool(u.get("grows", false)):
			growing += 1
			runner.eq(Economy.max_level(id, 7), base + 7, id + ": one level a collapse")
			runner.eq(Economy.max_level(id, 400), base + 400, id + ": and no end to it")
		else:
			runner.eq(Economy.max_level(id, 7), base, id + ": a line with a ceiling keeps it")
	runner.gte(float(growing), 5.0, "speed, yield, value, research and Cores all grow")
	runner.check(not bool(Economy.RESEARCH_TREE["heat_tolerance"].get("grows", false)),
		"heat tolerance stops, or the heat puzzle would end")


func test_past_the_first_limit_a_level_costs_more_but_stays_reachable() -> void:
	for id: String in Economy.RESEARCH_TREE:
		if not bool(Economy.RESEARCH_TREE[id].get("grows", false)):
			continue
		var base: int = int(Economy.RESEARCH_TREE[id]["max"])
		var last: float = 0.0
		for lvl: int in range(base + 12):
			var r: float = float(Economy.upgrade_cost(id, lvl)["research"])
			# The first deep level trades most of its Research price for Cores.
			if lvl != base:
				runner.gt(r, last, "%s level %d costs more than the one before" % [id, lvl])
			last = r
		var a: float = float(Economy.upgrade_cost(id, base + 3)["research"])
		var b: float = float(Economy.upgrade_cost(id, base + 4)["research"])
		runner.near(b / a, Economy.LATE_GROWTH, 0.0001,
			id + ": past the first limit each level is LATE_GROWTH dearer, not the steep curve")


func test_a_deep_level_multiplies_and_costs_cores() -> void:
	# Past the first limit, what a level does compounds: the twentieth level
	# of a line is worth what the first was, not a twentieth of it.
	var base: int = int(Economy.RESEARCH_TREE["throughput_1"]["max"])
	var per: float = float(Economy.RESEARCH_TREE["throughput_1"]["per_level"])
	var at_limit: float = float(Economy.multipliers({"throughput_1": base})["speed"])
	runner.near(at_limit, 1.0 + per * float(base), 0.0001, "the first levels still add")
	var deep3: float = float(Economy.multipliers({"throughput_1": base + 3})["speed"])
	runner.near(deep3, at_limit * pow(1.0 + per, 3.0), 0.0001, "the deep ones multiply")
	var cy: float = float(Economy.multipliers({"core_yield": 7})["core_yield"])
	runner.near(1.0 + cy, (1.0 + 0.25 * 5.0) * 1.25 * 1.25, 0.0001,
		"Seismic Survey's deep levels multiply the Cores a collapse pays")
	for id: String in Economy.RESEARCH_TREE:
		if not bool(Economy.RESEARCH_TREE[id].get("grows", false)):
			continue
		var b: int = int(Economy.RESEARCH_TREE[id]["max"])
		var c0: int = int(Economy.upgrade_cost(id, b)["cores"])
		var c5: int = int(Economy.upgrade_cost(id, b + 5)["cores"])
		runner.gte(float(c0), Economy.DEEP_CORES, id + ": a deep level costs Cores")
		runner.gt(float(c5), float(c0), id + ": and more the deeper it goes")
	runner.eq(int(Economy.upgrade_cost("throughput_1", base - 1)["cores"]), 0,
		"the first levels of a Research line still cost no Cores")
