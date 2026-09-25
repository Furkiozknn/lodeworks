extends RefCounted

## The Factory Core's levels (CoreLevels): the prerequisite graph is sound,
## every requirement is read from the running factory, each one really
## blocks the Core on its own, and the Core, the machines' levels and the
## Core's store survive a save and reset with a collapse.

var runner: Object

## The first Core level, played: two Smelters touching the Core's right
## side, each with a Boiler for its working heat and fed by a Crusher that
## two Drills feed; a shared Vault; a Lab behind the upper Boiler, which
## hands it Ingots straight through.
const LINE := [
	[26, 21, "drill"], [25, 20, "drill"], [25, 21, "crusher"],
	[26, 23, "drill"], [25, 24, "drill"], [25, 23, "crusher"],
	[24, 22, "vault"], [24, 21, "smelter"], [24, 23, "smelter"],
	[24, 20, "boiler"], [24, 24, "boiler"], [24, 19, "lab"],
]


func _fresh() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.depth = 0
	Sim.max_depth = 0
	Sim.lifetime_credits = 0.0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.core_level = 1
	Sim.machine_levels = {}
	Sim.stock = {}
	Sim.core_online = true
	Sim.unlocked.clear()
	Sim._recompute()


func _done() -> void:
	_fresh()
	Save.wipe()


func _tick(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		Sim.sim.tick()
		Sim._collect_stock()


func _build(line: Array) -> void:
	for e: Array in line:
		Sim.grid.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	Sim.sim.reset_progress()
	Sim._recompute()


## What the Core's `level` costs in credits.
func _price(level: int) -> float:
	for r: Array in CoreLevels.requirements(level):
		if int(r[0]) == CoreLevels.Req.CREDITS:
			return float(r[1])
	return 0.0


func _unmet() -> Array:
	return Sim.core_status().filter(func(st: Dictionary) -> bool: return not bool(st["met"]))


## A factory that meets every condition of the Core's second level, played
## rather than written: the line runs at stratum 2 until its Smelters are at
## their working heat; the store, research and the Crusher's level are set.
func _ready_for_two() -> void:
	_fresh()
	Sim.depth = 2
	Sim.max_depth = 2
	Sim.machine_levels = {"crusher": 2, "vault": 2}
	Sim.upgrade_levels = {"throughput_1": 1}
	Sim._recompute()
	_build(LINE)
	_tick(120.0)
	Sim.stock = {MachineDB.Res.INGOT: 40}
	Sim.credits = _price(2)
	Sim._sync_core()


## --- the graph ------------------------------------------------------------------

func test_the_graph_has_no_cycle_and_nothing_unreachable_for_forty_levels() -> void:
	var errors: Array[String] = CoreLevels.validate(40)
	runner.eq(errors, [], "the Core's prerequisite graph is sound")


func test_the_checker_finds_every_kind_of_broken_requirement() -> void:
	var c: int = CoreLevels.Req.CREDITS
	var has := func(errors: Array[String], what: String) -> bool:
		return errors.any(func(e: String) -> bool: return e.contains(what))
	# A cycle: Presses are found at stratum 3, which a level-1 Core cannot
	# reach -- level 2 asking for them would need itself to grow.
	var cyc: Array[String] = CoreLevels.problems(2, [[c, 10.0],
		[CoreLevels.Req.WORKING, "press", 1], [CoreLevels.Req.DEPTH, 2]])
	runner.check(has.call(cyc, "first becomes possible"), "a requirement only possible at its own level is a cycle")
	var never: Array[String] = CoreLevels.problems(3, [[c, 10.0],
		[CoreLevels.Req.RESEARCH, "throughput_1", 99], [CoreLevels.Req.MACHINE, "nothing", 2],
		[CoreLevels.Req.SERVES, "amplifier", 5]])
	runner.eq(never.filter(func(e: String) -> bool: return e.contains("never")).size(), 3,
		"past a line's end, a machine that does not exist, a support machine serving five")
	runner.check(has.call(CoreLevels.problems(2, [[c, 10.0]]), "only credits"), "credits alone are never a Core level")
	runner.check(has.call(CoreLevels.problems(2, [[c, 10.0], [CoreLevels.Req.STOCK, MachineDB.Res.INGOT, 5],
		[CoreLevels.Req.DEPTH, 9]]), "below its own limit"), "a stratum the Core's own limit keeps out of reach")
	# Storage: a level-1 Core lets the Vault reach level 2, which holds 80.
	var store: Array[String] = CoreLevels.problems(2, [[c, 10.0],
		[CoreLevels.Req.STOCK, MachineDB.Res.INGOT, 500], [CoreLevels.Req.DEPTH, 2]])
	runner.check(has.call(store, "first becomes possible"), "a store no Vault can yet hold is out of reach")
	# Research the Core has not opened, or has not let go far enough.
	var early: Array[String] = CoreLevels.problems(2, [[c, 10.0],
		[CoreLevels.Req.RESEARCH, "yield_1", 1], [CoreLevels.Req.DEPTH, 2]])
	runner.check(has.call(early, "first becomes possible"), "a research line that opens at level 2 cannot gate level 2")
	var far: Array[String] = CoreLevels.problems(2, [[c, 10.0],
		[CoreLevels.Req.RESEARCH, "throughput_1", 3], [CoreLevels.Req.DEPTH, 2]])
	runner.check(has.call(far, "first becomes possible"), "nor a research level past the Core's limit")
	var cores: Array[String] = CoreLevels.problems(4, [[c, 10.0],
		[CoreLevels.Req.RESEARCH, "heat_tolerance", 1], [CoreLevels.Req.DEPTH, 4]])
	runner.check(has.call(cores, "paid in Cores"), "research paid in Cores would make a collapse a requirement")


func test_every_level_opens_something_new_and_asks_for_several_systems() -> void:
	var last_cap: int = CoreLevels.depth_cap(1)
	for level in range(2, 25):
		runner.gt(float(CoreLevels.depth_cap(level)), float(last_cap), "level %d goes deeper" % level)
		last_cap = CoreLevels.depth_cap(level)
		var kinds: Dictionary = {}
		for r: Array in CoreLevels.requirements(level):
			kinds[int(r[0])] = true
		runner.gte(float(kinds.size()), 4.0, "level %d asks for four kinds of thing or more" % level)
		runner.gt(float(CoreLevels.machine_cap(level)), float(CoreLevels.machine_cap(level - 1)),
			"level %d raises the machine limit" % level)
		runner.gt(float(CoreLevels.opens(level)["stock_cap"]), float(CoreLevels.opens(level - 1)["stock_cap"]),
			"and what a Vault may hold")
	# The first five levels each open a production layer or a new tool.
	for level in range(2, 6):
		var o: Dictionary = CoreLevels.opens(level)
		runner.check(not (o["machines"] as Array).is_empty() or not (o["research"] as Array).is_empty(),
			"level %d opens a machine or a research line: %s %s" % [level, str(o["machines"]), str(o["research"])])
	runner.eq(CoreLevels.opens(2)["machines"], ["press", "amplifier"], "level 2 opens Plates and the Amplifier")
	runner.eq(CoreLevels.opens(3)["materials"], [MachineDB.Res.COMPONENT], "level 3 opens Components")
	runner.eq(CoreLevels.level_for_depth(0), 1, "")
	runner.eq(CoreLevels.level_for_depth(CoreLevels.depth_cap(3)), 3, "")
	runner.eq(CoreLevels.level_for_depth(CoreLevels.depth_cap(3) + 1), 4, "")


func test_every_machine_and_research_line_is_reached_by_some_core_level() -> void:
	for id: String in MachineDB.ORDER:
		runner.lte(float(CoreLevels.level_for_depth(MachineDB.unlock_depth(id))), 8.0,
			"%s is found under a Core the table writes out" % id)
	for id: String in Economy.TREE_ORDER:
		var at: int = CoreLevels.research_at(id, 1)
		runner.check(at >= 1 and at <= 4, "research %s opens at Core level %d" % [id, at])
		runner.eq(Economy.research_cap(id, at - 1), 0, "and not before")


## --- the store ---------------------------------------------------------------------------

func test_only_a_machine_touching_the_core_fills_its_store_and_only_while_it_has_room() -> void:
	var g := Grid.new()
	var s := Simulation.new(g, 3)
	Strata.apply(s, g, Strata.describe(1), Economy.multipliers({}))
	# A Crusher touching the Core's left side, fed by two Drills; another
	# Crusher out in the yard beside a Vault.
	g.place(Grid.idx(19, 21), "crusher")
	g.place(Grid.idx(18, 21), "drill")
	g.place(Grid.idx(19, 20), "drill")
	g.place(Grid.idx(12, 12), "crusher")
	g.place(Grid.idx(11, 12), "drill")
	g.place(Grid.idx(13, 12), "vault")
	runner.check(s.core_touching().has(Grid.idx(19, 21)), "(19, 21) touches the Core")
	runner.check(not s.core_touching().has(Grid.idx(19, 19)), "a corner does not")
	s.core_wants = {MachineDB.Res.GRAVEL: 5}
	for _i in range(900):
		s.tick()
	runner.eq(int(s.core_took.get(MachineDB.Res.GRAVEL, 0)), 5, "the Core takes what it has room for, no more")
	runner.eq(int(s.core_wants.get(MachineDB.Res.GRAVEL, 0)), 0, "and has no more room")
	runner.check(not s.core_took.has(MachineDB.Res.ORE), "and nothing it has no room for")
	var l: Dictionary = s.links_if_placed(Grid.idx(19, 22), "crusher")
	runner.check(not bool(l["delivers"]), "with no room, the Core is no outlet")
	s.core_wants = {MachineDB.Res.GRAVEL: 1}
	l = s.links_if_placed(Grid.idx(19, 22), "crusher")
	runner.check(bool(l["delivers"]), "with room, a tile touching the Core is an outlet")


func test_the_store_holds_what_the_vault_level_allows() -> void:
	_fresh()
	Sim.depth = 2
	Sim.max_depth = 2
	Sim._recompute()
	runner.eq(Sim.stock_cap(), MachineDB.stock_cap(1), "a level-1 Vault's store")
	runner.eq(int(Sim.sim.core_wants.get(MachineDB.Res.INGOT, 0)), Sim.stock_cap(), "the Core has room for all of it")
	runner.check(not Sim.sim.core_wants.has(MachineDB.Res.GRAVEL), "and keeps no Gravel: it is not stored")
	_build(LINE)
	_tick(300.0)
	runner.eq(Sim.stock_of(MachineDB.Res.INGOT), MachineDB.stock_cap(1), "a running line fills the store to its limit")
	runner.eq(int(Sim.sim.core_wants.get(MachineDB.Res.INGOT, 0)), 0, "and no further")
	var two: Array = Sim.core_status().filter(func(st: Dictionary) -> bool:
		return int(st["req"][0]) == CoreLevels.Req.STOCK)
	runner.check(not bool(two[0]["met"]) and int(two[0]["cap"]) < int(two[0]["need"]),
		"level 2 asks for more Ingots than a level-1 Vault holds: insufficient storage")
	Sim.credits = 1.0e6
	runner.eq(Sim.machine_upgrade_blocker("vault"), "", "the Vault's next level is payable from its own store")
	runner.check(Sim.upgrade_machine("vault"), "the Vault goes to level 2")
	runner.eq(Sim.stock_cap(), MachineDB.stock_cap(2), "and the store holds more")
	_tick(120.0)
	runner.gt(float(Sim.stock_of(MachineDB.Res.INGOT)), float(MachineDB.stock_cap(1)), "and fills past the old limit")
	_done()


## --- every condition of the second level blocks it on its own ---------------------------

func test_the_second_level_is_met_by_a_real_factory() -> void:
	_ready_for_two()
	for st: Dictionary in Sim.core_status():
		runner.check(bool(st["met"]), "met: %s (%.0f / %.0f)" % [str(st["req"]), float(st["have"]), float(st["need"])])
	runner.check(Sim.can_upgrade_core(), "so the Core can grow")
	_done()


func test_credits_alone_do_not_grow_the_core() -> void:
	_fresh()
	Sim.credits = 1.0e9
	runner.check(not Sim.can_upgrade_core(), "a fortune in credits is not enough")
	runner.gte(float(_unmet().size()), 4.0, "four conditions or more are still open")
	_done()


func test_missing_material_blocks_the_core() -> void:
	_ready_for_two()
	Sim.stock = {MachineDB.Res.INGOT: 39}
	runner.eq(_unmet().size(), 1, "one Ingot short")
	runner.eq(int(_unmet()[0]["req"][0]), CoreLevels.Req.STOCK, "and it is the store")
	runner.check(not Sim.upgrade_core(), "the Core does not grow")
	_done()


func test_a_missing_machine_level_blocks_the_core() -> void:
	_ready_for_two()
	Sim.machine_levels.erase("crusher")
	Sim._recompute()
	runner.eq(int(_unmet()[0]["req"][0]), CoreLevels.Req.MACHINE, "the Crushers are still at level 1")
	runner.check(not Sim.upgrade_core(), "the Core does not grow")
	_done()


func test_missing_research_blocks_the_core() -> void:
	_ready_for_two()
	Sim.upgrade_levels = {}
	Sim._recompute()
	runner.eq(_unmet().size(), 1, "")
	runner.eq(int(_unmet()[0]["req"][0]), CoreLevels.Req.RESEARCH, "no research done")
	runner.check(not Sim.upgrade_core(), "the Core does not grow")
	_done()


func test_heat_blocks_the_core() -> void:
	_ready_for_two()
	# Take the Boilers away: the Smelters still run, but cold.
	Sim.grid.remove(Grid.idx(24, 20))
	Sim.grid.remove(Grid.idx(24, 24))
	Sim._recompute()
	_tick(30.0)
	Sim.stock = {MachineDB.Res.INGOT: 40}
	Sim.credits = _price(2)
	var w: Array = _unmet().filter(func(st: Dictionary) -> bool: return int(st["req"][0]) == CoreLevels.Req.WORKING)
	runner.eq(w.size(), 1, "cold Smelters are not at their working heat")
	runner.check(not Sim.upgrade_core(), "so the Core does not grow")
	# And the row says why, and where: both Smelters, too cold.
	var held: Dictionary = CoreLevels.holding_back(Sim, "smelter")
	runner.eq(held["why"], {"cold": 2}, "both Smelters are held back by the cold")
	runner.eq((held["cells"] as Array).size(), 2, "and a tap walks to each")
	runner.eq(CoreLevels.why_not_working(Sim, Grid.idx(24, 21)), "cold", "")
	_done()


func test_what_holds_a_row_back_is_named_worst_first() -> void:
	_ready_for_two()
	runner.eq(CoreLevels.holding_back(Sim, "smelter")["cells"], [], "working Smelters hold nothing back")
	# A Press between two Boilers overheats; stability names it first.
	Sim.depth = 3
	Sim.max_depth = 3
	Sim._recompute()
	for e: Array in [[15, 30, "boiler"], [16, 30, "press"], [17, 30, "boiler"], [16, 31, "boiler"]]:
		Sim.grid.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	Sim._recompute()
	_tick(10.0)
	var hot: int = Grid.idx(16, 30)
	runner.check(Sim.sim.overheated_at(hot), "the Press is past its tolerance")
	runner.eq(CoreLevels.stable(Sim), 0, "so nothing counts as stable")
	var held: Dictionary = CoreLevels.holding_back(Sim)
	runner.eq(int((held["cells"] as Array)[0]), hot, "and it is the first machine the row points at")
	runner.eq(CoreLevels.why_not_working(Sim, hot), "hot", "")
	runner.check(not held["cells"].has(Grid.idx(15, 30)), "a Boiler is never what holds stability back")
	_done()


func test_depth_and_credits_each_block_the_core() -> void:
	_ready_for_two()
	Sim.credits = _price(2) - 1.0
	runner.eq(int(_unmet()[0]["req"][0]), CoreLevels.Req.CREDITS, "one credit short")
	Sim.credits = _price(2)
	Sim.max_depth = 1
	runner.eq(int(_unmet()[0]["req"][0]), CoreLevels.Req.DEPTH, "a stratum short")
	runner.check(not Sim.upgrade_core(), "")
	_done()


func test_growing_spends_its_credits_and_its_materials() -> void:
	_ready_for_two()
	Sim.credits = _price(2) + 50.0
	Sim.stock = {MachineDB.Res.INGOT: 55}
	runner.check(Sim.upgrade_core(), "the Core grows")
	runner.eq(Sim.core_level, 2, "")
	runner.near(Sim.credits, 50.0, 0.001, "its credits are paid")
	runner.eq(Sim.stock_of(MachineDB.Res.INGOT), 15, "and its Ingots")
	runner.eq(Sim.depth_cap(), CoreLevels.depth_cap(2), "the shaft may go deeper")
	runner.eq(Sim.machine_level_cap(), CoreLevels.machine_cap(2), "machines higher")
	runner.eq(Sim.research_cap("yield_1"), Economy.RESEARCH_PER_CORE, "and a new research line opens")
	var next: Array = Sim.core_status()
	runner.check(next.any(func(st: Dictionary) -> bool:
		return int(st["req"][0]) == CoreLevels.Req.STOCK and int(st["req"][1]) == MachineDB.Res.PLATE),
		"the next level asks for the new material")
	_done()


## --- what now? --------------------------------------------------------------------------------

func test_what_now_names_the_core_its_next_condition_and_a_machine_level() -> void:
	_ready_for_two()
	var kinds: Array = Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]))
	runner.check(kinds.has("core_grow"), "a Core that can grow is on the list: %s" % str(kinds))
	Sim.stock = {MachineDB.Res.INGOT: 20}
	Sim.machine_levels.erase("crusher")
	Sim._recompute()
	Sim.credits = 1.0e6
	var items: Array = Worklist.of(Sim)
	var need: Array = items.filter(func(e: Dictionary) -> bool: return String(e["kind"]) == "core_need")
	runner.eq(need.size(), 1, "the Core's next condition is a line")
	runner.eq(int(need[0]["st"]["req"][0]), CoreLevels.Req.STOCK, "the store, first of its open rows")
	var up: Array = items.filter(func(e: Dictionary) -> bool: return String(e["kind"]) == "upgrade")
	runner.eq(up.size(), 1, "a machine level that can be bought is a line")
	runner.eq(String(up[0]["id"]), "crusher", "the one the Core asks for")
	_done()


## --- machine levels ------------------------------------------------------------------------

func test_a_machine_level_is_paid_in_credits_and_materials() -> void:
	_fresh()
	Sim.credits = 1.0e9
	runner.eq(Sim.machine_upgrade_blocker("crusher"), "stock", "a Crusher's level 2 needs Ingots in the store")
	runner.check(not Sim.upgrade_machine("crusher"), "money does not buy it")
	var need: int = int(MachineDB.level_materials(2)[MachineDB.Res.INGOT])
	Sim.stock = {MachineDB.Res.INGOT: need + 3}
	var price: float = float(Sim.machine_upgrade_cost("crusher")["credits"])
	runner.check(Sim.upgrade_machine("crusher"), "with the Ingots it goes to level 2")
	runner.eq(Sim.stock_of(MachineDB.Res.INGOT), 3, "the Ingots are spent")
	runner.near(Sim.credits, 1.0e9 - price, 0.01, "and the credits")
	runner.eq(Sim.machine_upgrade_blocker("crusher"), "core", "a level-1 Core stops it at level 2")
	Sim.core_level = 2
	Sim._recompute()
	runner.eq(Sim.machine_upgrade_blocker("crusher"), "storage", "level 3's materials do not fit a level-1 Vault")
	Sim.machine_levels["vault"] = 2
	Sim._recompute()
	runner.eq(Sim.machine_upgrade_blocker("crusher"), "stock", "a level-2 Vault holds them, but there are no Plates")
	runner.eq(MachineDB.level_materials(3).keys().size(), 2, "level 3 costs Plates and Ingots: old materials keep a use")
	runner.eq(Sim.machine_upgrade_blocker("amplifier"), "none", "a support machine that is not heat has no level")
	runner.eq(Sim.machine_upgrade_blocker("boiler"), "locked", "a Boiler has one, once it is found")
	runner.eq(Sim.machine_upgrade_blocker("assembler"), "locked", "nor a machine not yet found")
	_done()


func test_a_machine_level_makes_that_machine_faster_and_only_that_one() -> void:
	_fresh()
	Sim.grid.place(Grid.idx(19, 21), "crusher")
	Sim.grid.place(Grid.idx(19, 22), "drill")
	var crusher: int = Grid.idx(19, 21)
	var drill: int = Grid.idx(19, 22)
	var heat1: float = Sim.grid.emitted_at(crusher)
	Sim.credits = 1.0e6
	Sim.stock = {MachineDB.Res.INGOT: 20}
	runner.check(Sim.upgrade_machine("crusher"), "")
	runner.near(float(Sim.sim.level_mult["crusher"]), MachineDB.level_speed(2), 0.0001,
		"level 2 runs LEVEL_SPEED faster")
	runner.check(not Sim.sim.level_mult.has("drill"), "the Drills are not made faster")
	runner.near(Sim.grid.emitted_at(crusher), heat1 * MachineDB.heat_factor("crusher", 2), 0.0001,
		"and it runs HEAT_PER_LEVEL hotter: an upgrade makes more and gives off more heat")
	runner.near(Sim.grid.emitted_at(drill), 0.4, 0.0001, "the Drill's own heat is its own")
	runner.check(Sim.upgrade_machine("vault"), "a Vault's level")
	runner.check(not Sim.sim.level_mult.has("vault"), "is storage, not speed")
	_done()


## --- research ----------------------------------------------------------------------------------

func test_a_lab_learns_from_any_refined_material_and_most_from_the_best() -> void:
	var lab: Dictionary = MachineDB.get_machine("lab")
	var learns: Dictionary = lab["learns"]
	runner.gt(float(learns[MachineDB.Res.COMPONENT]), float(learns[MachineDB.Res.PLATE]), "")
	runner.gt(float(learns[MachineDB.Res.PLATE]), float(learns[MachineDB.Res.INGOT]), "")
	runner.lte(float(MachineDB.unlock_depth("lab")), float(CoreLevels.depth_cap(1)),
		"a level-1 Core reaches the Lab: the first research comes before the second level")
	var g := Grid.new()
	var s := Simulation.new(g, 5)
	Strata.apply(s, g, Strata.describe(2), Economy.multipliers({}))
	var at: int = Grid.idx(5, 5)
	g.place(at, "lab")
	var buf: Dictionary = g.cells[at]["buf_in"]
	buf[MachineDB.Res.INGOT] = 1
	buf[MachineDB.Res.COMPONENT] = 1
	var got: float = 0.0
	for _i in range(40):
		got += float(s.tick()["research"])
		if got > 0.0:
			break
	runner.near(got, float(learns[MachineDB.Res.COMPONENT]), 0.0001, "handed both, it learns from the Component first")
	runner.eq(int(buf.get(MachineDB.Res.INGOT, 0)), 1, "and keeps the Ingot for the next cycle")


func test_the_core_caps_research_and_opens_new_lines() -> void:
	_fresh()
	Sim.research = 1.0e9
	runner.check(Sim.can_buy_upgrade("throughput_1"), "a level-1 Core opens Tighter Tolerances")
	runner.check(not Sim.can_buy_upgrade("yield_1"), "but not Deeper Bore")
	for _i in range(Economy.RESEARCH_PER_CORE):
		runner.check(Sim.buy_upgrade("throughput_1"), "")
	runner.check(not Sim.can_buy_upgrade("throughput_1"), "and only %d levels of it" % Economy.RESEARCH_PER_CORE)
	Sim.core_level = 2
	runner.check(Sim.can_buy_upgrade("throughput_1") and Sim.can_buy_upgrade("yield_1"),
		"a level-2 Core lets it go further, and opens Deeper Bore")
	_done()


## --- the Core's limits -----------------------------------------------------------------------

func test_the_core_caps_the_depth() -> void:
	_fresh()
	Sim.depth = CoreLevels.depth_cap(1)
	Sim.max_depth = Sim.depth
	Sim._recompute()
	Sim.credits = Sim.quota() * 10.0
	runner.check(not Sim.can_descend(), "a level-1 Core stops at stratum %d" % Sim.depth)
	runner.check(Sim.descent_needs_core(), "and says it is the Core")
	Sim.core_level = 2
	Sim._recompute()
	runner.check(Sim.can_descend(), "a level-2 Core goes on")
	_done()


## --- persistence -------------------------------------------------------------------------

func test_the_core_machine_levels_and_store_survive_a_save_and_reset_with_a_collapse() -> void:
	_fresh()
	Sim.core_level = 3
	Sim.machine_levels = {"smelter": 3, "crusher": 2, "vault": 2}
	Sim.stock = {MachineDB.Res.PLATE: 12, MachineDB.Res.INGOT: 70}
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.core_level = 1
	Sim.machine_levels = {}
	Sim.stock = {}
	Sim.from_dict(d)
	runner.eq(Sim.core_level, 3, "the Core's level")
	runner.eq(Sim.machine_levels, {"smelter": 3, "crusher": 2, "vault": 2}, "the machines' levels")
	runner.eq(Sim.stock, {MachineDB.Res.PLATE: 12, MachineDB.Res.INGOT: 70}, "the store, keyed by material")
	Sim.max_depth = 6
	Sim.lifetime_credits = 1.0e6
	runner.check(Sim.collapse() > 0, "a collapse")
	runner.eq(Sim.core_level, 1, "a new shaft's Core is at level 1")
	runner.eq(Sim.machine_levels, {}, "its machines at level 1")
	runner.eq(Sim.stock, {}, "and its store is empty")
	_done()


func test_an_old_save_keeps_every_stratum_and_what_the_core_took_in() -> void:
	_fresh()
	var d: Dictionary = Sim.to_dict()
	d.erase("core_level")
	d.erase("machine_levels")
	d.erase("stock")
	d["depth"] = 9
	d["max_depth"] = 9
	Sim.from_dict(d)
	runner.eq(Sim.core_level, CoreLevels.level_for_depth(9), "the Core starts where the depth needs it")
	runner.gte(float(Sim.depth_cap()), 9.0, "so stratum 9 is still within its limit")
	runner.eq(Sim.machine_levels, {}, "and machines start at level 1")
	# The first round of Core levels saved what the Core had taken in.
	d = Sim.to_dict()
	d.erase("stock")
	d["core_intake"] = {"2": 12, "1": 5, "3": 999}
	Sim.from_dict(d)
	runner.eq(Sim.stock_of(MachineDB.Res.INGOT), 12, "Ingots the Core had taken in are in its store")
	runner.check(not Sim.stock.has(MachineDB.Res.GRAVEL), "Gravel is not stored")
	runner.eq(Sim.stock_of(MachineDB.Res.PLATE), Sim.stock_cap(), "and nothing past what the Vault holds")
	_done()


func test_a_new_game_starts_at_the_first_level() -> void:
	_fresh()
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.from_dict(d)
	runner.eq(Sim.core_level, 1, "a new shaft's Core is at level 1")
	runner.eq(Sim.stock, {}, "its store is empty")
	runner.eq(Sim.depth_cap(), CoreLevels.depth_cap(1), "")
	runner.check(not Sim.can_upgrade_core(), "and it cannot grow on nothing")
	_done()
