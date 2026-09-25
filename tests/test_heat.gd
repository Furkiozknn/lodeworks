extends RefCounted

## Heat as a factory decision (docs/PROGRESSION.md, "Heat"): a machine's
## safe range is where it counts as working; the heat at a machine is the
## sum of its sources, and the game can say which; heat follows work (levels
## and modes); the rock's heat rises with depth; and the answers -- a Boiler
## run Low, a machine run Cool, Coolant Cells and their levels, a better
## layout -- keep a factory working and pay for themselves.

var runner: Object


## A board on plain rock at `depth`: no stratum modifiers.
func _board(cells: Array, depth: int, levels: Dictionary = {}) -> Array:
	var g := Grid.new()
	var s := Simulation.new(g, 11)
	g.set_environment(Strata.AMBIENT_PER_DEPTH * float(depth), MachineDB.HEAT_SPREAD)
	for e: Array in cells:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
		if e.size() > 3:
			g.set_mode(Grid.idx(int(e[0]), int(e[1])), int(e[3]))
	var hs: Dictionary = {}
	for id: String in levels:
		hs[id] = MachineDB.heat_factor(id, int(levels[id]))
		if MachineDB.level_is_speed(id):
			s.level_mult[id] = MachineDB.level_speed(int(levels[id]))
	g.set_heat_scale(hs)
	s.levels_stamp += 1
	return [g, s]


func _over(b: Array, x: int, y: int) -> bool:
	return (b[1] as Simulation).overheated_at(Grid.idx(x, y))


func test_the_safe_range_is_where_a_machine_counts_as_working() -> void:
	for id: String in MachineDB.ORDER:
		var m: Dictionary = MachineDB.get_machine(id)
		if float(m["heat_tolerance"]) > 50.0:
			continue
		var safe: Vector2 = MachineDB.safe_range(id)
		var opt: float = float(m["heat_optimum"])
		var tol: float = float(m["heat_tolerance"])
		runner.near(MachineDB.heat_efficiency(safe.y, opt, tol), Simulation.THERMAL_WARNING, 0.0001,
			"%s at the top of its safe range is at the working line" % id)
		runner.lt(MachineDB.heat_efficiency(safe.y + 0.05, opt, tol), Simulation.THERMAL_WARNING,
			"and just past it, below")
		runner.near(MachineDB.heat_efficiency(safe.x, opt, tol), Simulation.THERMAL_WARNING if opt > 0.0 else 1.0,
			0.0001, "%s at the bottom of its safe range" % id)
	# A Drill with no heat of its own nearby works to its tolerance: the
	# rock's heat alone no longer takes it off the working line at stratum 8.
	var b: Array = _board([[5, 5, "drill"]], 8)
	runner.gte((b[1] as Simulation).heat_efficiency_at(Grid.idx(5, 5)), Simulation.THERMAL_WARNING,
		"a lone Drill at stratum 8 is at its working heat")


func test_the_heat_at_a_machine_is_the_sum_of_its_sources() -> void:
	var b: Array = _board([[5, 5, "press"], [4, 5, "boiler"], [6, 5, "coolant"], [5, 4, "smelter"]], 10)
	var g: Grid = b[0]
	var i: int = Grid.idx(5, 5)
	var sum: float = 0.0
	var kinds: Dictionary = {}
	for src: Dictionary in g.heat_sources(i):
		sum += float(src["amount"])
		kinds[String(src["id"])] = float(src["amount"])
	runner.near(sum, g.raw_heat_at(i), 0.0001, "itself, its neighbours and the rock add up to its heat")
	runner.near(float(kinds["press"]), 1.1, 0.0001, "its own heat")
	runner.near(float(kinds["boiler"]), 1.3, 0.0001, "half a Boiler's beside it")
	runner.near(float(kinds["coolant"]), -1.1, 0.0001, "half a Coolant Cell's, taken away")
	runner.near(float(kinds[""]), Strata.AMBIENT_PER_DEPTH * 10.0, 0.0001, "and the rock's")


func test_early_strata_ask_little_of_heat() -> void:
	# The Core's first line, Smelters with their Boilers, and the first
	# Presses beside their Smelters: nothing overheats on the first strata.
	var line := [[26, 21, "drill"], [25, 20, "drill"], [25, 21, "crusher"], [24, 21, "smelter"],
		[24, 20, "boiler"], [24, 22, "vault"], [24, 19, "lab"], [23, 21, "press"]]
	for d in range(0, 5):
		var b: Array = _board(line, d)
		var over: int = 0
		for c: int in (b[0] as Grid).cells:
			if (b[1] as Simulation).overheated_at(c):
				over += 1
		runner.eq(over, 0, "stratum %d: nothing overheats" % d)


func test_the_first_hot_strata_overheat_a_press_and_a_coolant_answers() -> void:
	runner.check(not _over(_board([[5, 5, "press"]], 7), 5, 5), "a lone Press is safe at stratum 7")
	runner.check(_over(_board([[5, 5, "press"]], 8), 5, 5), "and overheats at stratum 8")
	runner.check(not _over(_board([[5, 5, "press"], [6, 5, "coolant"]], 8), 5, 5), "a Coolant Cell beside it answers")


func test_a_boiler_that_warmed_a_smelter_overheats_its_other_neighbour_deeper() -> void:
	var cells := [[5, 5, "smelter"], [5, 4, "boiler"], [5, 3, "drill"]]
	runner.check(not _over(_board(cells, 2), 5, 3), "at stratum 2 the Drill beside the Boiler is safe")
	runner.check(_over(_board(cells, 12), 5, 3), "at stratum 12 the Boiler pushes it past its range")
	var b: Array = _board(cells, 12)
	var top: Dictionary = {}
	for src: Dictionary in (b[0] as Grid).heat_sources(Grid.idx(5, 3)):
		if String(src["id"]) == "boiler":
			top = src
	runner.near(float(top["amount"]), 1.3, 0.0001, "and the heat card names it")
	var low := [[5, 5, "smelter"], [5, 4, "boiler", MachineDB.Mode.COOL], [5, 3, "drill"]]
	runner.check(_over(_board(cells, 9), 5, 3), "at stratum 9 it already does")
	runner.check(not _over(_board(low, 9), 5, 3), "and run Low it stops")
	runner.check(_over(_board(low, 12), 5, 3), "at 12, Low is not enough")
	# By then the rock alone keeps the Smelter warm: the Boiler has done
	# its job and can go.
	var gone: Array = _board([[5, 5, "smelter"], [5, 3, "drill"]], 12)
	runner.check(not _over(gone, 5, 3), "without the Boiler the Drill is safe")
	runner.gte((gone[1] as Simulation).heat_efficiency_at(Grid.idx(5, 5)), Simulation.THERMAL_WARNING,
		"and the Smelter, on hot rock, is warm enough without it")


func test_a_dense_drill_field_needs_a_new_layout_as_the_rock_heats() -> void:
	var field := [[5, 5, "drill"], [6, 5, "vault"], [7, 5, "drill"], [5, 6, "vault"], [6, 6, "drill"],
		[7, 6, "vault"]]
	runner.check(not _over(_board(field, 12), 5, 5), "at stratum 12 the field is safe")
	runner.check(_over(_board(field, 15), 5, 5), "at 15 every Drill overheats from the rock alone")
	var cool := []
	for e: Array in field:
		cool.append(e + [MachineDB.Mode.COOL] if String(e[2]) == "drill" else e)
	runner.check(not _over(_board(cool, 15), 5, 5), "run Cool, the Drills get through stratum 15")
	runner.check(_over(_board(cool, 18), 5, 5), "but not 18: there the field needs Coolant Cells")
	var cooled := [[5, 5, "drill", MachineDB.Mode.COOL], [6, 5, "coolant"], [7, 5, "vault"],
		[5, 6, "coolant"], [5, 4, "vault"]]
	runner.check(not _over(_board(cooled, 18, {"coolant": 3}), 5, 5),
		"with Coolant Cells between Drills and Vaults (material passes through them)")


func test_levels_raise_output_and_heat_together() -> void:
	var b1: Array = _board([[5, 5, "press"]], 4)
	var b5: Array = _board([[5, 5, "press"]], 4, {"press": 5})
	runner.near((b5[0] as Grid).emitted_at(Grid.idx(5, 5)), 1.1 * MachineDB.heat_factor("press", 5), 0.0001,
		"a level-5 Press gives off more heat")
	runner.gt(MachineDB.heat_factor("press", 5), 1.0, "")
	runner.check(not _over(b1, 5, 5), "a level-1 Press is safe at stratum 4")
	runner.check(not _over(_board([[5, 5, "press"]], 5, {"press": 5}), 5, 5), "")
	runner.check(_over(_board([[5, 5, "press"]], 7, {"press": 5}), 5, 5),
		"a level-5 Press overheats a stratum sooner than a level-1 one")
	runner.gt(float((b5[1] as Simulation).level_mult["press"]), 1.0, "and it runs faster")


func test_coolant_levels_are_the_cooling_that_grows_with_the_core() -> void:
	var b: Array = _board([[5, 5, "press"], [6, 5, "coolant"]], 21, {"coolant": 1})
	runner.check(_over(b, 5, 5), "at stratum 21 one level-1 Coolant Cell is not enough")
	var b9: Array = _board([[5, 5, "press"], [6, 5, "coolant"], [4, 5, "coolant"]], 21, {"coolant": 5})
	runner.check(not _over(b9, 5, 5), "two at level 5 are")
	runner.near((b9[0] as Grid).emitted_at(Grid.idx(6, 5)), -2.2 * MachineDB.heat_factor("coolant", 5), 0.0001,
		"each moves SUPPORT_PER_LEVEL more heat a level")
	# The Core that reaches a stratum lets the Coolant Cells answer it.
	for level in range(4, 9):
		var d: int = CoreLevels.depth_cap(level)
		var cap: int = CoreLevels.machine_cap(level)
		var ring := [[5, 5, "press"], [6, 5, "coolant"], [4, 5, "coolant"], [5, 6, "coolant"]]
		runner.check(not _over(_board(ring, d, {"coolant": cap, "press": cap}), 5, 5),
			"Core %d: a Press at its limit, three Coolant Cells at theirs, safe at stratum %d" % [level, d])


func test_minimum_and_maximum_cooling() -> void:
	var one := [[5, 5, "assembler"], [6, 5, "coolant"]]
	var four := [[5, 5, "assembler"], [6, 5, "coolant"], [4, 5, "coolant"], [5, 6, "coolant"], [5, 4, "coolant"]]
	runner.check(_over(_board(one, 21), 5, 5), "one Coolant Cell at stratum 21 is too little")
	var b: Array = _board(four, 21)
	runner.check(not _over(b, 5, 5), "four are enough")
	runner.lt((b[1] as Simulation).heat_efficiency_at(Grid.idx(5, 5)), Simulation.THERMAL_WARNING,
		"but an Assembler wants some warmth: four is too cold -- cooling is a choice, not a pile")


func test_a_good_layout_beats_a_bad_one_at_depth() -> void:
	var bad := [[3, 5, "drill"], [4, 5, "crusher"], [5, 5, "smelter"], [6, 5, "press"], [7, 5, "vault"],
		[6, 4, "boiler"], [3, 4, "drill"]]
	var good := [[3, 5, "drill"], [4, 5, "crusher"], [5, 5, "smelter"], [6, 5, "press"], [7, 5, "vault"],
		[6, 4, "coolant"], [3, 4, "drill"]]
	var b: Array = _board(bad, 10)
	var g: Array = _board(good, 10)
	runner.check(_over(b, 6, 5), "a Press beside a Boiler overheats at stratum 10")
	runner.check(not _over(g, 6, 5), "beside a Coolant Cell it does not")
	var rb: float = float((b[1] as Simulation).measure(20.0, 30.0)["credits_per_sec"])
	var rg: float = float((g[1] as Simulation).measure(20.0, 30.0)["credits_per_sec"])
	runner.gt(rg, rb * 1.1, "and the good layout earns more (%.1f against %.1f)" % [rg, rb])


func test_modes_trade_output_for_heat() -> void:
	runner.eq(MachineDB.modes_for("smelter"), [MachineDB.Mode.NORMAL, MachineDB.Mode.COOL, MachineDB.Mode.HOT], "")
	runner.eq(MachineDB.modes_for("boiler"), [MachineDB.Mode.NORMAL, MachineDB.Mode.COOL], "a Boiler: Normal or Low")
	runner.eq(MachineDB.modes_for("coolant"), [MachineDB.Mode.NORMAL], "a Coolant Cell's lever is its level")
	runner.eq(MachineDB.modes_for("vault"), [MachineDB.Mode.NORMAL], "")
	var n: Array = _board([[5, 5, "press"]], 3)
	var c: Array = _board([[5, 5, "press", MachineDB.Mode.COOL]], 3)
	var h: Array = _board([[5, 5, "press", MachineDB.Mode.HOT]], 3)
	var i: int = Grid.idx(5, 5)
	runner.near((c[0] as Grid).emitted_at(i), 0.55, 0.0001, "Cool: half its heat")
	runner.near((h[0] as Grid).emitted_at(i), 1.76, 0.0001, "Hot: 60% more")
	runner.near((c[1] as Simulation).effective_rate(i) / (n[1] as Simulation).effective_rate(i),
		0.75 * (c[1] as Simulation).heat_efficiency_at(i) / (n[1] as Simulation).heat_efficiency_at(i), 0.0001,
		"and three quarters of the speed")
	runner.check(not _over(h, 5, 5), "run Hot at stratum 3 a Press is safe")
	runner.check(_over(_board([[5, 5, "press", MachineDB.Mode.HOT]], 5), 5, 5), "at stratum 5, Hot costs it")


func test_modes_open_with_the_core_and_are_saved() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.core_level = 1
	Sim.max_depth = 3
	Sim.depth = 3
	Sim._recompute()
	var cell: int = Grid.idx(19, 21)
	Sim.grid.place(cell, "press")
	runner.check(not Sim.set_mode(cell, MachineDB.Mode.COOL), "no modes under a level-1 Core")
	Sim.core_level = MachineDB.MODES_CORE
	runner.check(Sim.set_mode(cell, MachineDB.Mode.COOL), "the Core's level %d opens them" % MachineDB.MODES_CORE)
	runner.check(not Sim.set_mode(cell, 7), "no mode a machine does not have")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.grid.clear()
	Sim.from_dict(d)
	runner.eq(Sim.grid.mode_at(cell), MachineDB.Mode.COOL, "a mode survives a save")
	Sim.move_machine(cell, Grid.idx(19, 22))
	runner.eq(Sim.grid.mode_at(Grid.idx(19, 22)), MachineDB.Mode.COOL, "and a move: it belongs to the machine")
	Sim.grid.clear()
	Sim.core_level = 1
	Sim.depth = 0
	Sim.max_depth = 0
	Sim._recompute()
	Save.wipe()


func test_the_same_board_meets_hotter_rock_after_a_descend() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.core_level = 5
	Sim.depth = 4
	Sim.max_depth = 4
	Sim._recompute()
	var press: int = Grid.idx(19, 21)
	Sim.grid.place(press, "press")
	Sim._recompute()
	runner.check(not Sim.sim.overheated_at(press), "a lone Press at stratum 4 is safe")
	Sim.depth = 12
	Sim.max_depth = 12
	Sim._recompute()
	runner.check(Sim.sim.overheated_at(press), "the same Press at stratum 12 overheats")
	var why: Dictionary = CoreLevels.holding_back(Sim)
	runner.eq(int((why["cells"] as Array)[0]), press, "and stability points at it")
	Sim.grid.clear()
	Sim.core_level = 1
	Sim.depth = 0
	Sim.max_depth = 0
	Sim._recompute()
	Save.wipe()


## A player's answers, hottest machine first, until nothing overheats: a
## Boiler beside it run Low, the machine run Cool, the Coolant Cells raised
## to `cap`, a Coolant Cell on a free tile beside it (tools/heat_lab.gd does
## the same and prints the result for every line and depth).
func _answer(g: Grid, cap: int) -> bool:
	for _round in range(60):
		var hottest: int = -1
		var worst: float = 0.0
		for c: int in g.cells:
			var by: float = g.heat_at(c) - float(MachineDB.get_machine(g.machine_at(c))["heat_tolerance"])
			if by > worst:
				worst = by
				hottest = c
		if hottest < 0:
			return true
		var acted: bool = false
		for n: int in g.neighbours(hottest):
			if g.machine_at(n) == "boiler" and g.mode_at(n) == MachineDB.Mode.NORMAL:
				acted = g.set_mode(n, MachineDB.Mode.COOL)
				break
		if not acted and g.mode_at(hottest) == MachineDB.Mode.NORMAL:
			acted = g.set_mode(hottest, MachineDB.Mode.COOL)
		if not acted and float(g.heat_scale.get("coolant", 1.0)) < MachineDB.heat_factor("coolant", cap) - 0.001:
			var hs: Dictionary = g.heat_scale.duplicate()
			hs["coolant"] = MachineDB.heat_factor("coolant", cap)
			g.set_heat_scale(hs)
			acted = true
		if not acted:
			for n: int in g.neighbours(hottest):
				if g.is_empty(n):
					acted = g.place(n, "coolant")
					break
		if not acted:
			return false
	return false


func test_managing_heat_pays() -> void:
	# The Core's Press line on stratum 15, every maker at the level the Core
	# that reaches it allows, as built and as a player answers it.
	var line := [[19, 27, "drill"], [21, 27, "drill"], [20, 27, "crusher"], [20, 26, "smelter"],
		[21, 26, "boiler"], [20, 25, "coolant"], [19, 24, "coolant"], [20, 24, "press"], [21, 24, "vault"],
		[23, 27, "drill"], [22, 27, "crusher"], [22, 26, "smelter"], [22, 25, "coolant"],
		[23, 24, "coolant"], [22, 24, "press"]]
	var cap: int = CoreLevels.machine_cap(CoreLevels.level_for_depth(15))
	var levels := {"drill": cap, "crusher": cap, "smelter": cap, "press": cap}
	var as_built: Array = _board(line, 15, levels)
	var answered: Array = _board(line, 15, levels)
	runner.check(_answer(answered[0] as Grid, cap), "a player's answers leave nothing overheating")
	(answered[1] as Simulation).reset_progress()
	var over_a: int = 0
	var over_b: int = 0
	for c: int in (as_built[0] as Grid).cells:
		if (as_built[1] as Simulation).overheated_at(c):
			over_a += 1
		if (answered[1] as Simulation).overheated_at(c):
			over_b += 1
	runner.gt(float(over_a), 0.0, "as built, something overheats at stratum 15 (%d)" % over_a)
	runner.eq(over_b, 0, "answered, nothing does")
	var ra: float = float((as_built[1] as Simulation).measure(20.0, 30.0)["credits_per_sec"])
	var rb: float = float((answered[1] as Simulation).measure(20.0, 30.0)["credits_per_sec"])
	runner.gt(rb, ra, "and it earns more (%.1f against %.1f): cooling is not only a cost" % [rb, ra])
