extends RefCounted

## Can a player actually get anywhere?
##
## Unit tests prove the parts work. These prove the *game* works: that a
## reasonable board earns at a reasonable speed, that the early quotas fall in
## a session rather than a week, and that the curve does not flatten into the
## wall where idle games die.
##
## Everything here plays the game headlessly with no UI, at real tick rate, and
## asserts against wall-clock seconds. If the balance is ever changed, these are
## the tests that say whether it is still playable.

var runner: Object

## A complete ore-to-component-to-research chain that fits on the 7x10 board.
## Every multi-input machine here has all of its inputs orthogonally adjacent,
## which on a four-neighbour grid is the actual puzzle the late game sets.
const FULL_CHAIN := [
	[0, 0, "drill"], [1, 0, "drill"], [2, 0, "drill"], [3, 0, "drill"],
	[4, 0, "drill"], [5, 0, "drill"], [6, 0, "drill"],
	[0, 1, "crusher"], [1, 1, "crusher"], [2, 1, "crusher"], [3, 1, "crusher"],
	[4, 1, "crusher"], [5, 1, "crusher"], [6, 1, "crusher"],
	[0, 2, "vault"], [1, 2, "smelter"], [2, 2, "smelter"], [3, 2, "smelter"],
	[4, 2, "smelter"], [5, 2, "smelter"], [6, 2, "vault"],
	[0, 3, "vault"], [1, 3, "press"], [2, 3, "press"], [3, 3, "press"],
	[4, 3, "press"], [5, 3, "press"], [6, 3, "vault"],
	[0, 4, "vault"], [1, 4, "vault"], [2, 4, "assembler"], [3, 4, "assembler"],
	[4, 4, "assembler"], [5, 4, "vault"], [6, 4, "vault"],
	[1, 5, "vault"], [2, 5, "vault"], [3, 5, "lab"], [4, 5, "vault"],
	[5, 5, "vault"],
	[0, 6, "drill"], [1, 6, "drill"], [2, 6, "drill"], [3, 6, "drill"],
	[4, 6, "drill"], [5, 6, "drill"], [6, 6, "drill"],
	[0, 7, "crusher"], [1, 7, "crusher"], [2, 7, "crusher"], [3, 7, "crusher"],
	[4, 7, "crusher"], [5, 7, "crusher"], [6, 7, "crusher"],
	[0, 8, "vault"], [1, 8, "vault"], [2, 8, "vault"], [3, 8, "vault"],
	[4, 8, "vault"], [5, 8, "vault"], [6, 8, "vault"],
]


func _board(pairs: Array, depth: int = 0, upgrades: Dictionary = {}) -> Simulation:
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	var st: Dictionary = Strata.describe(depth)
	var mu: Dictionary = Economy.multipliers(upgrades)
	Strata.apply(s, g, st, mu)
	for p: Array in pairs:
		g.place(Grid.idx(int(p[0]), int(p[1])), String(p[2]))
	return s


## The board the tutorial walks a new player into, on the first stratum.
func _starter(depth: int = 0) -> Simulation:
	return _board([
		[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
		[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
	], depth)


func test_the_first_minute_earns_something_visible() -> void:
	# A player who places a drill and a vault must see the number move within
	# seconds. This is the whole first impression.
	var s := _board([[3, 4, "drill"], [4, 4, "vault"]])
	var out: Dictionary = s.run_ticks(int(10.0 * Simulation.TICK_HZ))
	runner.gt(float(out["credits"]), 3.0,
		"ten seconds of a drill and a vault should be visibly productive")


func test_first_quota_is_reachable_in_a_first_session() -> void:
	# Stratum 0's quota has to fall inside a few minutes of the tutorial board,
	# or the player never sees the descent and never learns what the game is.
	var s := _starter(0)
	var per_sec: float = float(s.measure()["credits_per_sec"])
	runner.gt(per_sec, 0.0, "the starter board must earn")
	var seconds_needed: float = Strata.quota_for(0) / per_sec
	runner.lt(seconds_needed, 300.0,
		"first descent took %.0fs of pure idling; that is too long for a first session"
		% seconds_needed)


func test_second_and_third_quotas_stay_within_a_session() -> void:
	# Allowing for the player expanding the board a little as they go.
	for d in [1, 2]:
		var s := _board([
			[2, 3, "drill"], [3, 3, "crusher"], [4, 3, "vault"],
			[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
			[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
		], d)
		var per_sec: float = float(s.measure()["credits_per_sec"])
		runner.gt(per_sec, 0.0, "depth %d must earn" % d)
		var seconds: float = Strata.quota_for(d) / per_sec
		runner.lt(seconds, 900.0,
			"depth %d would take %.0fs on a nine-tile board" % [d, seconds])


func test_a_better_layout_beats_a_bigger_one() -> void:
	# The core promise of the genre: thinking is worth more than owning. Eight
	# machines arranged well must beat ten arranged badly.
	var sloppy := _board([
		[0, 0, "drill"], [6, 0, "drill"], [0, 9, "drill"], [6, 9, "drill"],
		[3, 0, "vault"], [3, 9, "vault"], [0, 5, "crusher"], [6, 5, "crusher"],
		[2, 0, "crusher"], [4, 9, "crusher"],
	], 2)
	var tidy := _board([
		[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
		[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
		[2, 6, "drill"], [3, 6, "crusher"],
	], 2)
	var sloppy_rate: float = float(sloppy.measure()["credits_per_sec"])
	var tidy_rate: float = float(tidy.measure()["credits_per_sec"])
	runner.gt(tidy_rate, sloppy_rate,
		"a connected eight-tile board must beat a scattered ten-tile one")


func test_heat_only_helps_the_actual_bottleneck() -> void:
	# Heat is not a free multiplier, and this is the lesson the game is built
	# to teach: making a machine faster does nothing when the thing limiting
	# it is what arrives, not what it can process.
	#
	# Three Smelters share one Crusher fed by one Drill, so every Smelter is
	# badly under-supplied. A Boiler on one of them raises what that Smelter
	# COULD do and cannot raise what it is given.
	#
	# Asserted as a relative change and as a duty cycle rather than against a
	# fixed credits figure, so that re-balancing the economy cannot silently
	# turn this from a design guarantee into a snapshot of one afternoon.
	var starved := [
		[2, 3, "drill"], [3, 3, "crusher"],
		[3, 2, "smelter"], [4, 2, "vault"],
		[4, 3, "smelter"], [5, 3, "vault"],
		[3, 4, "smelter"], [4, 4, "vault"],
	]
	# On the first stratum, where the rock is poor and one Drill really is one
	# Drill. Deeper strata multiply every stage at once, which hides the
	# shortage this test is about.
	var cold := _board(starved, 0)
	var hot := _board(starved + [[3, 1, "boiler"]], 0)
	var a: float = float(cold.measure()["credits_per_sec"])
	var b: float = float(hot.measure()["credits_per_sec"])

	# The Smelter really is starved in both boards, which is what makes the
	# rest of the assertion mean anything.
	cold.run_ticks(600)
	hot.run_ticks(600)
	var cell: int = Grid.idx(3, 2)
	# (0.5 and 0.6 until the comfortable heat band stopped at 90% rather
	# than 80% on 25 September 2026: the Crusher upstream runs a little
	# faster in it, and the Smelter waits a little less.)
	runner.lt(cold.uptime_of(cell), 0.7,
		"the fixture only tests what it claims if the smelter is under-supplied")
	runner.lt(hot.uptime_of(cell), 0.75,
		"and heating it must not have solved the supply problem")
	runner.gt(a, 0.0, "the board earns something")
	runner.lt(absf(b - a) / a, 0.12,
		"a boiler on a starved machine must not move the board's output "
		+ "(%.2f vs %.2f)" % [b, a])


func test_heat_management_is_worth_real_money_when_it_is_the_bottleneck() -> void:
	# Three crushers into one smelter: now the smelter IS the constraint, and
	# a boiler has to pay for the tile it occupies.
	var saturated := [
		[2, 2, "drill"], [3, 2, "crusher"],
		[2, 3, "drill"], [3, 3, "crusher"], [4, 3, "smelter"], [5, 3, "vault"],
		[2, 4, "drill"], [3, 4, "crusher"],
	]
	var plain := _board(saturated, 3)
	var managed := _board(saturated + [[4, 2, "boiler"]], 3)
	var a: float = float(plain.measure()["credits_per_sec"])
	var b: float = float(managed.measure()["credits_per_sec"])
	runner.gt(b, a * 1.03,
		"a boiler on a saturated smelter must pay for itself (%.2f vs %.2f)" % [b, a])


func test_a_deep_board_earns_far_more_than_a_shallow_one() -> void:
	# The reason to descend. Same shape of board, much better rate.
	var shallow: float = float(_starter(0).measure()["credits_per_sec"])
	var deep: float = float(_starter(10).measure()["credits_per_sec"])
	runner.gt(deep, shallow * 1.8, "depth 10 must feel like progress")


func test_the_research_tree_meaningfully_multiplies_output() -> void:
	var bare: float = float(_starter(4).measure()["credits_per_sec"])
	var teched: float = float(_board([
		[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
		[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
	], 4, {"throughput_1": 4, "yield_1": 3, "value_1": 3}).measure()["credits_per_sec"])
	runner.gt(teched, bare * 2.0, "a mid-game tree must at least double output")


func test_a_full_late_board_produces_research() -> void:
	# Labs have to be reachable in practice, not only in theory: a complete
	# component chain has to fit on a 7x10 board and actually run.
	var s := _board(FULL_CHAIN, 8)
	var m: Dictionary = s.measure(20.0, 20.0)
	runner.gt(float(m["research_per_sec"]), 0.0,
		"a full chain into labs must actually produce research")
	runner.gt(float(m["credits_per_sec"]), 0.0, "and still earn")


func test_collapsing_at_the_earliest_point_is_worth_doing() -> void:
	# The first prestige has to pay, or nobody ever takes it and the long game
	# never starts.
	var s := _starter(3)
	var per_sec: float = float(s.measure()["credits_per_sec"])
	var lifetime: float = per_sec * 1800.0    # half an hour of play
	var cores: int = Economy.cores_for_collapse(3, lifetime)
	runner.gte(float(cores), 1.0,
		"half an hour to stratum 3 must be worth at least one Core")


func test_the_curve_does_not_wall_out_by_depth_twenty() -> void:
	# The classic idle failure: quotas outrun any board you can build and the
	# game silently ends. Check that a strong board at depth 20, with a
	# plausible tree, still clears its quota inside a long session.
	var s := _board(FULL_CHAIN, 20,
		{"throughput_1": 8, "yield_1": 6, "value_1": 6, "heat_tolerance": 5})
	var per_sec: float = float(s.measure(20.0, 20.0)["credits_per_sec"])
	runner.gt(per_sec, 0.0, "a full late board must earn at depth 20")
	var hours: float = Strata.quota_for(20) / per_sec / 3600.0
	runner.lt(hours, 12.0,
		"depth 20 would need %.1f hours of idling; the curve has walled out" % hours)


func test_offline_is_worth_opening_the_game_for_but_not_instead_of_it() -> void:
	var s := _starter(5)
	var rate: float = float(s.measure()["credits_per_sec"])
	var mu: Dictionary = Economy.multipliers({})
	var eight_hours: float = float(Economy.offline_yield(rate, 8.0 * 3600.0, mu)["amount"])
	var one_hour_live: float = rate * 3600.0
	runner.gt(eight_hours, one_hour_live * 0.5,
		"a night away should be worth coming back for")
	runner.lt(eight_hours, one_hour_live * 8.0,
		"but never more than actually playing for the same time")
