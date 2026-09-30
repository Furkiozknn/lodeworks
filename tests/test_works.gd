extends RefCounted

## The Works (Economy, "The Works"; docs/GAME-LOOP.md, section 14): a Frame
## taken to an Assay Bench becomes research; research and Frames buy the
## Works' lines, each behind what it needs; each does what it says; the
## plan buys its line the moment it is paid for; the Frames' ledger and
## rates; Cores 14 and 15 -- and a tree or a Core row that could never be
## had is caught. Saved, loaded and migrated.

var runner: Object

const RIG := MachineDB.Res.RIG
const FRAME := MachineDB.Res.FRAME
const LENS := MachineDB.Res.LENS


## A Core `level` shaft on stratum 27 with every machine found, a crew of
## `rigs` Rigs at the Bay, Frames and Lenses in the store, and no research.
func _shaft(level: int = 12, rigs: int = 10) -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 1.0e9
	Sim.research = 0.0
	Sim.cores = 0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.research_plan = ""
	Sim.frame_spent = {}
	Sim.core_level = level
	Sim.depth = 27
	Sim.max_depth = 27
	Sim.machine_levels = {"vault": 11}
	Sim.overdrive = {}
	Sim.doctrine = ""
	Sim.clear_ops()
	Sim.salvage = 200
	Sim.unlocked.clear()
	for id: String in MachineDB.ORDER:
		Sim.unlocked.append(id)
	Sim.stock = {RIG: rigs, FRAME: 200000, LENS: 40000, MachineDB.Res.ALLOY: 50000,
		MachineDB.Res.COMPONENT: 50000, MachineDB.Res.PLATE: 50000}
	Sim.regions_open = ["caverns"]
	Sim.bay_level = 4
	Sim._recompute()


func _done() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.salvage = 0
	Sim.depth = 0
	Sim.max_depth = 0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.research_plan = ""
	Sim.frame_spent = {}
	Sim.core_level = 1
	Sim.machine_levels = {}
	Sim.overdrive = {}
	Sim.stock = {}
	Sim.bay_level = 1
	Sim.core_online = true
	Sim.unlocked.clear()
	Sim.doctrine = ""
	Sim.clear_ops()
	Sim.lens_spent = {}
	Sim._recompute()
	Save.wipe()


## Play `seconds`, research counted as the running game counts it.
func _run(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		var out: Dictionary = Sim.sim.tick()
		Sim.after_tick(Simulation.TICK_DT)
		Sim.research += float(out["research"])


## An Assay Bench on a free tile beside the Core; its cell, or -1.
func _bench() -> int:
	for cell: int in Sim.sim.core_touching():
		if Sim.grid.is_empty(cell) and not Sim.is_blocked(cell):
			Sim.grid.place(cell, "lab")
			if Sim.set_job(cell, "assay"):
				return cell
			Sim.grid.remove(cell)
	return -1


## Every level of the Works' lines below `id` its "requires" asks for.
func _open_needs(id: String) -> void:
	for need: Array in (Economy.RESEARCH_TREE[id].get("requires", []) as Array):
		if String(need[0]) == "line":
			Sim.upgrade_levels[String(need[1])] = maxi(Sim.upgrade_level(String(need[1])), int(need[2]))
	Sim._recompute()


## --- the chain: a Frame, a Bench, research ------------------------------------------------

func test_a_frame_hauled_to_an_assay_bench_becomes_research() -> void:
	_shaft(12)
	var cell: int = _bench()
	runner.check(cell >= 0, "an Assay Bench beside the Core")
	runner.check(Sim.post_rig(cell), "a Rig posted to it")
	var frames0: int = Sim.stock_of(FRAME)
	_run(40.0)
	runner.lt(float(Sim.stock_of(FRAME)), float(frames0), "Frames left the store")
	runner.gt(float(Sim.frame_spent.get("research", 0)), 0.0, "on the ledger, as research")
	runner.gt(float(Sim.sim.learned.get(FRAME, 0)), 0.0, "the Bench learned from them")
	runner.gt(Sim.research, 0.0, "research made")
	# What a Frame is worth each way, as the research screen says it.
	runner.near(Sim.frame_research_value(), MachineDB.ASSAY_LEARNS * Sim.sim.research_mult, 0.001, "")
	runner.gt(Sim.frame_sale_value(), 0.0, "")
	_done()


func test_the_frames_an_hour_are_measured() -> void:
	_shaft(12)
	Sim._measure_frames(0.0)
	Sim.sim.made[FRAME] = int(Sim.sim.made.get(FRAME, 0)) + 600
	Sim.sim.learned[FRAME] = int(Sim.sim.learned.get(FRAME, 0)) + 300
	Sim.frame_spent["lens"] = int(Sim.frame_spent.get("lens", 0)) + 60
	Sim._measure_frames(60.0)
	runner.near(float(Sim.frame_rates["made"]), 10.0, 0.001, "")
	runner.near(float(Sim.frame_rates["research"]), 5.0, 0.001, "")
	runner.near(float(Sim.frame_rates["lens"]), 1.0, 0.001, "")
	_done()


func test_the_store_s_frames_left_are_read_from_their_trend() -> void:
	_shaft(12)
	Sim.frame_rates = {}
	Sim._frame_marks = []
	Sim.stock[FRAME] = 10000
	Sim._measure_frames(3.0)
	runner.check(not Sim.frame_rates.has("store"), "no trend before a window is marked")
	Sim.stock[FRAME] = 9700
	Sim._measure_frames(3.0)
	runner.near(float(Sim.frame_rates["store"]), -100.0, 0.001, "the first window sets the trend")
	runner.near(Sim.frames_left(), 97.0, 0.001, "97 seconds of Frames at 100 a second")
	# A still window eases the trend; it does not wipe it.
	Sim._measure_frames(3.0)
	runner.lt(float(Sim.frame_rates["store"]), 0.0, "")
	runner.gt(float(Sim.frame_rates["store"]), -100.0, "")
	for _i in range(200):
		Sim.stock[FRAME] = Sim.stock_of(FRAME) + 300
		Sim._measure_frames(3.0)
	runner.gt(float(Sim.frame_rates["store"]), 0.0, "rising again")
	runner.near(Sim.frames_left(), -1.0, 0.001, "not falling: no time to run out")
	Sim.frame_rates = {}
	Sim._frame_marks = []
	_done()


func test_the_benches_leave_the_beacons_their_frames() -> void:
	_shaft(12)
	var cell: int = _bench()
	runner.check(Sim.post_rig(cell), "a Rig posted to the Bench")
	var floor0: int = Sim.haul_floor(FRAME)
	runner.eq(Sim.research_floor(), floor0, "no Beacon: the Benches take what a Rig may haul")
	Sim.beacons = ["caverns"]
	Sim.stock[LENS] = 0
	var hour: int = int(Sim.beacon_upkeep())
	runner.eq(Sim.research_floor(), floor0 + hour, "the Frames of the Beacons' next hour stay")
	Sim.stock[FRAME] = floor0 + hour + 20
	_run(30.0)
	runner.eq(Sim.stock_of(FRAME), floor0 + hour, "the Bench took only what was over")
	Sim.stock[LENS] = hour
	runner.eq(Sim.research_floor(), floor0 + hour, "Lenses in the store or not: the Grinders' hour stays")
	Sim.beacons = []
	_done()


## --- the tree: what each line opens behind -------------------------------------------------

func test_the_works_open_behind_what_they_need() -> void:
	_shaft(12)
	runner.eq(Sim.research_blocker("assay_racks"), "research", "open, and short of research")
	runner.eq(Sim.research_blocker("jig_lines"), "needs", "behind Assay Racks")
	runner.eq(Sim.research_needs("jig_lines"), [["line", "assay_racks", 1]], "")
	runner.eq(Sim.research_blocker("survey_kit"), "needs", "behind a Beacon")
	runner.eq(Sim.research_needs("survey_kit"), [["beacons", 1]], "")
	# Store Chutes: Assay Racks 2 and two Benches at work.
	Sim.upgrade_levels["assay_racks"] = 2
	Sim._recompute()
	runner.eq(Sim.research_needs("bench_chutes"), [["working", "lab", 2, "assay"]], "the Benches still")
	runner.eq(Sim.research_blocker("jig_lines"), "research", "Jig Lines open")
	# Under Core 10 the Works are shut.
	_shaft(9)
	runner.eq(Sim.research_blocker("assay_racks"), "core", "")
	runner.eq(Sim.research_blocker("haul_harness"), "core", "")
	_done()


func test_a_works_level_costs_research_and_frames() -> void:
	_shaft(12)
	var c: Dictionary = Economy.upgrade_cost("assay_racks", 0)
	runner.gt(float(c["frames"]), 0.0, "a Works level costs Frames")
	Sim.research = float(c["research"])
	Sim.stock[FRAME] = int(c["frames"]) - 1
	runner.eq(Sim.research_blocker("assay_racks"), "frames", "one Frame short")
	runner.check(not Sim.buy_upgrade("assay_racks"), "")
	Sim.stock[FRAME] = int(c["frames"]) + 500
	runner.check(Sim.buy_upgrade("assay_racks"), "")
	runner.eq(Sim.stock_of(FRAME), 500, "the Frames paid from the store")
	runner.eq(int(Sim.frame_spent.get("tech", 0)), int(c["frames"]), "on the ledger")
	runner.near(Sim.research, 0.0, 0.001, "the research paid")
	runner.eq(Sim.tech_levels(), 1, "")
	_done()


func test_each_works_line_does_what_it_says() -> void:
	_shaft(12)
	# Assay Racks: a Frame teaches more.
	var taught: float = Sim.frame_research_value()
	Sim.upgrade_levels["assay_racks"] = 1
	Sim._recompute()
	runner.near(Sim.frame_research_value(), taught * 1.25, 0.001, "Assay Racks")
	# Jig Lines: a Frame Jig works faster.
	var jig: int = -1
	for cell: int in Sim.sim.core_touching():
		if Sim.grid.is_empty(cell) and not Sim.is_blocked(cell):
			Sim.grid.place(cell, "assembler")
			Sim.set_job(cell, "frame")
			jig = cell
			break
	var r0: float = Sim.sim.effective_rate(jig)
	runner.gt(r0, 0.0, "the Jig runs on this rock")
	Sim.upgrade_levels["jig_lines"] = 2
	Sim._recompute()
	runner.near(Sim.sim.effective_rate(jig), r0 * 1.5, 0.001, "Jig Lines")
	# Hauling Harness and Bay Wing: the posted Rigs carry more, and more dock.
	var haul: float = Sim.haul_rate()
	var docks: int = Sim.bay_posts()
	Sim.upgrade_levels["haul_harness"] = 1
	Sim.upgrade_levels["bay_wing"] = 1
	Sim._recompute()
	runner.near(Sim.haul_rate(), haul * 1.5, 0.001, "Hauling Harness")
	runner.eq(Sim.bay_posts(), docks + 2, "Bay Wing")
	# Survey Instruments: a Surveyor is stronger.
	var s: Dictionary = {"kind": "cistern", "need": 100.0, "left": 100.0, "terrain": "water"}
	var v0: float = Sim.team_strength(s, 0, 0, 2)
	Sim.upgrade_levels["survey_kit"] = 2
	Sim._recompute()
	runner.near(Sim.team_strength(s, 0, 0, 2), v0 * 1.5, 0.001, "Survey Instruments")
	_done()


func test_store_chutes_feed_a_bench_with_no_rig() -> void:
	_shaft(12)
	var cell: int = _bench()
	_run(10.0)
	runner.eq(int(Sim.frame_spent.get("research", 0)), 0, "no Rig, no chutes: nothing moves")
	Sim.upgrade_levels["bench_chutes"] = 1
	Sim._recompute()
	var frames0: int = Sim.stock_of(FRAME)
	_run(20.0)
	runner.gt(float(Sim.frame_spent.get("research", 0)), 10.0, "the chutes fed it")
	runner.lt(float(Sim.stock_of(FRAME)), float(frames0), "from the store")
	runner.gt(float(Sim.sim.learned.get(FRAME, 0)), 0.0, "and it learned")
	# The chutes leave what a posted Rig would: the Core's next row's Frames.
	Sim.stock[FRAME] = Sim.haul_floor(FRAME)
	var spent: int = int(Sim.frame_spent.get("research", 0))
	_run(5.0)
	runner.eq(int(Sim.frame_spent.get("research", 0)), spent, "nothing under the floor")
	runner.check(cell >= 0, "")
	_done()


## --- the plan ----------------------------------------------------------------------------

func test_the_plan_buys_the_moment_it_is_paid_for_and_is_done() -> void:
	_shaft(12)
	runner.check(Sim.plan_research("assay_racks"), "")
	runner.eq(Sim.research_plan, "assay_racks", "")
	_run(1.0)
	runner.eq(Sim.upgrade_level("assay_racks"), 0, "not paid for yet")
	runner.eq(Sim.research_plan, "assay_racks", "the plan waits")
	Sim.research = float(Economy.upgrade_cost("assay_racks", 0)["research"])
	_run(0.2)
	runner.eq(Sim.upgrade_level("assay_racks"), 1, "bought on the next tick")
	runner.eq(Sim.research_plan, "", "and the plan is done")
	# A line with no such name, or at its end, cannot be planned.
	runner.check(not Sim.plan_research("nowhere"), "")
	Sim.upgrade_levels["bay_wing"] = int(Economy.RESEARCH_TREE["bay_wing"]["max"])
	runner.check(not Sim.plan_research("bay_wing"), "at its end")
	runner.check(Sim.plan_research(""), "cleared")
	_done()


func test_the_plan_waits_while_frames_are_short() -> void:
	_shaft(12)
	var c: Dictionary = Economy.upgrade_cost("haul_harness", 0)
	Sim.research = float(c["research"]) * 3.0
	Sim.stock[FRAME] = 10
	Sim.plan_research("haul_harness")
	_run(1.0)
	runner.eq(Sim.upgrade_level("haul_harness"), 0, "Frames short: no level")
	runner.eq(Sim.research_blocker("haul_harness"), "frames", "")
	runner.eq(Sim.research_plan, "haul_harness", "")
	Sim.stock[FRAME] = int(c["frames"]) * 2
	_run(0.2)
	runner.eq(Sim.upgrade_level("haul_harness"), 1, "the Frames in: bought")
	_done()


func test_what_now_asks_for_a_plan_when_the_core_asks_for_research() -> void:
	_shaft(13)
	var kinds: Array = []
	for e: Dictionary in Worklist.of(Sim):
		kinds.append(String(e["kind"]))
	runner.check(kinds.has("plan"), "the Core 14 row asks for the Works, and nothing is planned")
	Sim.plan_research("assay_racks")
	kinds.clear()
	for e: Dictionary in Worklist.of(Sim):
		kinds.append(String(e["kind"]))
	runner.check(not kinds.has("plan"), "planned")
	_done()


func test_what_now_warns_while_the_store_s_frames_run_out() -> void:
	_shaft(12)
	Sim.stock[FRAME] = 3000
	Sim.frame_rates = {"store": -1.0}
	var hit: Dictionary = {}
	for e: Dictionary in Worklist.of(Sim):
		if String(e["kind"]) == "frames":
			hit = e
	runner.check(not hit.is_empty(), "out within two hours: a line of its own")
	runner.near(float(hit.get("left", 0.0)), 3000.0, 0.001, "")
	Sim.frame_rates = {"store": 1.0}
	var kinds: Array = []
	for e: Dictionary in Worklist.of(Sim):
		kinds.append(String(e["kind"]))
	runner.check(not kinds.has("frames"), "rising: no line")
	Sim.frame_rates = {}
	_done()


## --- the Core's rows -------------------------------------------------------------------

func test_cores_14_and_15_ask_for_the_works_and_more() -> void:
	for level in [14, 15]:
		var kinds: Dictionary = {}
		for r: Array in CoreLevels.requirements(level):
			kinds[int(r[0])] = true
		runner.check(kinds.has(CoreLevels.Req.TECH), "Core %d asks for the Works" % level)
		runner.check(kinds.has(CoreLevels.Req.WORKING), "and Assay Benches at work")
		runner.gte(float(kinds.size()), 6.0, "Core %d asks for six kinds of work or more" % level)
	runner.eq(CoreLevels.validate(20), [], "every level reachable, none circular")
	runner.eq(Economy.tree_problems(), [], "the tree sound")
	# The formula past 15 grows the Works' row.
	var tech16: int = 0
	for r: Array in CoreLevels.requirements(16):
		if int(r[0]) == CoreLevels.Req.TECH:
			tech16 = int(r[1])
	runner.gt(float(tech16), 6.0, "")
	# The row reads the running shaft.
	_shaft(13)
	Sim.upgrade_levels["assay_racks"] = 2
	Sim.upgrade_levels["haul_harness"] = 1
	for st: Dictionary in Sim.core_status():
		if int(st["req"][0]) == CoreLevels.Req.TECH:
			runner.eq(int(st["have"]), 3, "whichever line")
			runner.check(bool(st["met"]), "")
	_done()


func test_a_research_row_that_could_never_be_had_is_caught() -> void:
	var errors: Array[String] = CoreLevels.problems(14, [[CoreLevels.Req.CREDITS, 1.0],
		[CoreLevels.Req.TECH, 999], [CoreLevels.Req.STABLE, 1]])
	runner.check(errors.any(func(e: String) -> bool: return e.contains("can never be had")), str(errors))
	# More of the Works than the Core before could have let the shaft buy.
	var early: Array[String] = CoreLevels.problems(11, [[CoreLevels.Req.CREDITS, 1.0],
		[CoreLevels.Req.TECH, 10], [CoreLevels.Req.STABLE, 1]])
	runner.check(early.any(func(e: String) -> bool: return e.contains("first becomes possible")), str(early))


func test_a_broken_tree_is_caught() -> void:
	var tree: Dictionary = {
		"a": {"max": 2, "core": 10, "requires": [["line", "b", 1]]},
		"b": {"max": 2, "core": 10, "requires": [["line", "a", 1]]},
		"c": {"max": 2, "core": 10, "requires": [["line", "nowhere", 1]]},
		"d": {"max": 2, "core": 10, "requires": [["line", "a", 5]]},
		"e": {"max": 2, "core": 10, "requires": [["line", "f", 1]]},
		"f": {"max": 2, "core": 12, "requires": []},
		"g": {"max": 2, "core": 10, "requires": [["weather", 1]]},
	}
	var errors: Array[String] = Economy.tree_problems(tree, ["a", "b", "c", "d", "e", "f", "g", "h"])
	var said: String = "\n".join(errors)
	runner.check(said.contains("a needs itself") and said.contains("b needs itself"), said)
	runner.check(said.contains("c needs nowhere, which is not a line"), said)
	runner.check(said.contains("d needs a 5, a level it does not have"), said)
	runner.check(said.contains("e needs f, which opens later"), said)
	runner.check(said.contains("a kind of need there is not"), said)
	runner.check(said.contains("h is in the tree's order but not in the tree"), said)


## --- saved, loaded, migrated -------------------------------------------------------------

func test_a_save_keeps_the_plan_and_the_frames_ledger() -> void:
	_shaft(12)
	Sim.plan_research("haul_harness")
	Sim.frame_spent = {"tech": 1500, "research": 300}
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.research_plan = ""
	Sim.frame_spent = {}
	Sim.from_dict(d)
	runner.eq(Sim.research_plan, "haul_harness", "")
	runner.eq(Sim.frame_spent, {"tech": 1500, "research": 300}, "")
	_done()


func test_a_save_from_before_the_works_loads() -> void:
	_shaft(12)
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	d.erase("research_plan")
	d.erase("frame_spent")
	Sim.from_dict(d)
	runner.eq(Sim.research_plan, "", "no plan")
	runner.eq(Sim.frame_spent, {}, "")
	runner.eq(Sim.tech_levels(), 0, "")
	# A plan for a line the tree no longer has is dropped.
	d["research_plan"] = "gone_line"
	Sim.from_dict(d)
	runner.eq(Sim.research_plan, "", "")
	_done()
