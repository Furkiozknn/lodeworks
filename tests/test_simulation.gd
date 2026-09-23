extends RefCounted

## These are the design tests, not the code tests.
##
## Each one encodes a claim the game makes to the player -- "refining pays",
## "heat is worth managing", "a blocked line backs up". If one of these fails,
## the game is still running, it has just stopped being interesting, and that
## is the failure mode nobody notices until reviews arrive.

var runner: Object


func _sim(seed_value: int = 42) -> Simulation:
	return Simulation.new(Grid.new(), seed_value)


func test_a_lone_drill_produces_nothing_spendable() -> void:
	# Ore in a buffer is not money. The player has to connect something.
	var s := _sim()
	s.grid.place(Grid.idx(3, 3), "drill")
	var out: Dictionary = s.run_ticks(100)
	runner.near(float(out["credits"]), 0.0, 0.001, "no vault, no income")
	runner.gt(float(out["cycles"]), 0.0, "but the drill is running")


func test_drill_into_vault_earns() -> void:
	var s := _sim()
	s.grid.place(Grid.idx(3, 3), "drill")
	s.grid.place(Grid.idx(4, 3), "vault")
	var m: Dictionary = s.measure()
	runner.gt(float(m["credits_per_sec"]), 0.0, "adjacency alone should make income")


func test_a_vault_not_touching_anything_earns_nothing() -> void:
	var s := _sim()
	s.grid.place(Grid.idx(0, 0), "drill")
	s.grid.place(Grid.idx(6, 9), "vault")
	var m: Dictionary = s.measure()
	runner.near(float(m["credits_per_sec"]), 0.0, 0.001, "distance matters")


func test_refining_beats_selling_raw() -> void:
	# The central economic claim of the game. Two drills feeding a crusher
	# must out-earn two drills feeding a vault directly, or the entire middle
	# of the tech tree is decoration.
	var raw := _sim()
	raw.grid.place(Grid.idx(2, 2), "drill")
	raw.grid.place(Grid.idx(2, 3), "drill")
	raw.grid.place(Grid.idx(3, 2), "vault")
	raw.grid.place(Grid.idx(3, 3), "vault")
	var raw_rate: float = float(raw.measure()["credits_per_sec"])

	var refined := _sim()
	refined.grid.place(Grid.idx(2, 2), "drill")
	refined.grid.place(Grid.idx(2, 3), "drill")
	refined.grid.place(Grid.idx(3, 2), "crusher")
	refined.grid.place(Grid.idx(3, 3), "crusher")
	refined.grid.place(Grid.idx(4, 2), "vault")
	refined.grid.place(Grid.idx(4, 3), "vault")
	var refined_rate: float = float(refined.measure()["credits_per_sec"])

	runner.gt(refined_rate, raw_rate,
		"refining must pay for the extra tiles it costs")


func test_heat_makes_a_smelter_faster() -> void:
	# The Smelter's optimum is 3.0 and it emits 1.2, so alone it is slow. A
	# Boiler beside it should be a visible, measurable win -- this is the
	# moment the player is supposed to understand the heat system.
	var cold := _sim()
	cold.grid.place(Grid.idx(3, 3), "smelter")
	var cold_rate: float = cold.effective_rate(Grid.idx(3, 3))

	var hot := _sim()
	hot.grid.place(Grid.idx(3, 3), "smelter")
	hot.grid.place(Grid.idx(4, 3), "boiler")
	var hot_rate: float = hot.effective_rate(Grid.idx(3, 3))

	runner.gt(hot_rate, cold_rate * 1.15,
		"a boiler must be worth at least 15% to a smelter")


func test_too_much_heat_hurts() -> void:
	# And the same move, overdone, has to be punished. Without this the answer
	# to every board is "add boilers" and there is no puzzle.
	var one := _sim()
	one.grid.place(Grid.idx(3, 3), "smelter")
	one.grid.place(Grid.idx(4, 3), "boiler")
	var with_one: float = one.effective_rate(Grid.idx(3, 3))

	var four := _sim()
	four.grid.place(Grid.idx(3, 3), "smelter")
	for n in [Vector2i(4, 3), Vector2i(2, 3), Vector2i(3, 4), Vector2i(3, 2)]:
		four.grid.place(Grid.idx(n.x, n.y), "boiler")
	var with_four: float = four.effective_rate(Grid.idx(3, 3))

	runner.lt(with_four, with_one, "four boilers must be worse than one")


func test_coolant_rescues_an_overheated_press() -> void:
	# The Press tolerates almost no heat, so it is the tile that teaches the
	# player to spend a slot on cooling.
	var hot := _sim()
	hot.grid.place(Grid.idx(3, 3), "press")
	hot.grid.place(Grid.idx(4, 3), "boiler")
	hot.grid.place(Grid.idx(2, 3), "boiler")
	var before: float = hot.effective_rate(Grid.idx(3, 3))

	hot.grid.place(Grid.idx(3, 4), "coolant")
	var after: float = hot.effective_rate(Grid.idx(3, 3))

	runner.gt(after, before, "coolant has to actually fix the problem it exists for")


func test_amplifier_raises_throughput() -> void:
	var plain := _sim()
	plain.grid.place(Grid.idx(3, 3), "drill")
	plain.grid.place(Grid.idx(4, 3), "vault")
	var plain_rate: float = float(plain.measure()["credits_per_sec"])

	var amped := _sim()
	amped.grid.place(Grid.idx(3, 3), "drill")
	amped.grid.place(Grid.idx(4, 3), "vault")
	amped.grid.place(Grid.idx(3, 2), "amplifier")
	var amped_rate: float = float(amped.measure()["credits_per_sec"])

	runner.gt(amped_rate, plain_rate * 1.1, "an amplifier must be felt")


func test_backpressure_stalls_an_unsold_line() -> void:
	# A chain with no Vault must fill up and stop, not silently vanish output.
	# This is what makes a stalled board visible instead of merely unprofitable.
	var s := _sim()
	s.grid.place(Grid.idx(3, 3), "drill")
	s.grid.place(Grid.idx(4, 3), "crusher")
	s.run_ticks(400)
	var early: int = s.run_ticks(50)["cycles"]
	s.run_ticks(600)
	var late: int = s.run_ticks(50)["cycles"]
	runner.lt(float(late), float(early) + 1.0,
		"a line with nowhere to sell must wind down, not keep cycling forever")


func test_output_buffer_is_capped() -> void:
	var s := _sim()
	var i: int = Grid.idx(3, 3)
	s.grid.place(i, "drill")
	s.run_ticks(2000)
	var total: int = 0
	for res: int in s.grid.cells[i]["buf_out"]:
		total += int(s.grid.cells[i]["buf_out"][res])
	runner.check(total <= Simulation.BUF_CAP,
		"buffer overflowed: %d > %d" % [total, Simulation.BUF_CAP])


func test_lab_makes_research_not_credits() -> void:
	var s := _sim()
	# Hand the lab its input directly; the point here is the lab's behaviour,
	# not whether a full component chain fits on the board.
	var i: int = Grid.idx(3, 3)
	s.grid.place(i, "lab")
	s.grid.cells[i]["buf_in"][MachineDB.Res.COMPONENT] = 5
	var out: Dictionary = s.run_ticks(60)
	runner.gt(float(out["research"]), 0.0, "lab must produce research")
	runner.near(float(out["credits"]), 0.0, 0.001, "and no credits")


func test_simulation_is_deterministic() -> void:
	# Determinism is what lets the layout comparison readout be trustworthy,
	# and what makes any of these tests meaningful at all.
	var a := _sim(777)
	var b := _sim(777)
	for s in [a, b]:
		s.grid.place(Grid.idx(2, 2), "drill")
		s.grid.place(Grid.idx(3, 2), "duplicator")
		s.grid.place(Grid.idx(2, 3), "vault")
	var ra: Dictionary = a.run_ticks(500)
	var rb: Dictionary = b.run_ticks(500)
	runner.near(float(ra["credits"]), float(rb["credits"]), 0.0001,
		"same seed must give the same result")


func test_different_seeds_diverge_when_chance_is_involved() -> void:
	var a := _sim(1)
	var b := _sim(2)
	for s in [a, b]:
		s.grid.place(Grid.idx(2, 2), "drill")
		s.grid.place(Grid.idx(3, 2), "duplicator")
		s.grid.place(Grid.idx(2, 3), "vault")
	var ra: float = float(a.run_ticks(800)["credits"])
	var rb: float = float(b.run_ticks(800)["credits"])
	runner.check(not is_equal_approx(ra, rb), "duplicator chance should vary by seed")


func test_speed_multiplier_scales_output() -> void:
	var base := _sim()
	base.grid.place(Grid.idx(3, 3), "drill")
	base.grid.place(Grid.idx(4, 3), "vault")
	var base_rate: float = float(base.measure()["credits_per_sec"])

	var fast := _sim()
	fast.grid.place(Grid.idx(3, 3), "drill")
	fast.grid.place(Grid.idx(4, 3), "vault")
	fast.speed_mult = 2.0
	var fast_rate: float = float(fast.measure()["credits_per_sec"])

	runner.gt(fast_rate, base_rate * 1.6, "research speed upgrades must be felt")


func test_empty_board_is_free_and_silent() -> void:
	var s := _sim()
	var out: Dictionary = s.run_ticks(200)
	runner.near(float(out["credits"]), 0.0, 0.001, "")
	runner.eq(int(out["cycles"]), 0, "")
