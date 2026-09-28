extends RefCounted

## The deep map (Operations, "regions"; docs/GAME-LOOP.md, section 12): the
## Surveyor, expeditions that open a region, each region's sites, terrain and
## gift to the factory, Resonite into the store and the Lens Grinder, the
## regions' research lines, and Core 11's rows -- saved, loaded and migrated.

var runner: Object

const RIG := MachineDB.Res.RIG
const PLATE := MachineDB.Res.PLATE
const FRAME := MachineDB.Res.FRAME
const RESONITE := MachineDB.Res.RESONITE
const LENS := MachineDB.Res.LENS


## A Core 10 shaft with a crew of `rigs` Rigs at the Bay, fuel, Frames,
## Components and salvage to refit with, and a board dealt.
func _frontier(rigs: int = 8) -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.collapses = 0
	# A Core 10 crew is plated (Rig Plating 12: 3.4 times a bare Rig).
	Sim.upgrade_levels = {"rig_plating": 12}
	Sim.core_level = Operations.REGION_CORE
	Sim.depth = 27
	Sim.max_depth = 27
	# A Core 10 store: a Vault at 10.
	Sim.machine_levels = {"vault": 10}
	Sim.overdrive = {}
	Sim.doctrine = ""
	Sim.clear_ops()
	Sim.ops_lifetime = 0
	Sim.salvage = 100
	Sim.lifetime_credits = 0.0
	Sim.best_core = 1
	Sim.unlocked.clear()
	for id: String in MachineDB.ORDER:
		Sim.unlocked.append(id)
	Sim.stock = {RIG: rigs, MachineDB.Res.ALLOY: 5000, FRAME: 5000, MachineDB.Res.COMPONENT: 5000, PLATE: 5000}
	Sim._recompute()
	Sim._deal_ops()


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
	Sim.lifetime_credits = 0.0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.core_level = 1
	Sim.machine_levels = {}
	Sim.overdrive = {}
	Sim.stock = {}
	Sim.contracts = []
	Sim.dispatch_serial = 0
	Sim.core_online = true
	Sim.unlocked.clear()
	Sim.credits_per_sec = 0.0
	Sim.best_core = 1
	Sim.doctrine = ""
	Sim.blueprints = []
	Sim.blueprint_pending = []
	Sim.clear_ops()
	Sim.ops_lifetime = 0
	Sim._recompute()
	Save.wipe()


func _run(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		Sim.sim.tick()
		Sim.after_tick(Simulation.TICK_DT)


## --- the Surveyor -----------------------------------------------------------------------

func test_a_surveyor_is_a_rig_refitted_from_core_10_and_is_nothing_like_a_breaker() -> void:
	_frontier()
	Sim.core_level = Operations.REGION_CORE - 1
	Sim._recompute()
	runner.eq(Sim.refit_blocker("surveyor"), "core", "no Surveyor before the Core's level 10")
	Sim.core_level = Operations.REGION_CORE
	Sim._recompute()
	var c: Dictionary = Operations.refit_cost(Sim.core_level, "surveyor")
	runner.eq(int(c["res"]), FRAME, "paid in Frames")
	runner.check(Sim.refit_rig("surveyor"), "")
	runner.eq(Sim.surveyors, 1, "")
	runner.eq(Sim.rigs_home(), 7, "a Rig fewer")
	runner.eq(Sim.stock_of(FRAME), 5000 - int(c["n"]), "")
	runner.eq(int(Sim.crew_roles()["surveyor"]), 1, "")
	# Against the same hall: a Surveyor is the weakest; on rock weaker still.
	var hall := {"kind": "pumphouse"}
	var rock := {"kind": "vein", "armor": true}
	runner.lt(Operations.team_factor(hall, 0, 0, 1), Operations.team_factor(hall, 1, 0, 0), "weaker than a Rig on a site")
	runner.lt(Operations.team_factor(rock, 0, 0, 1), Operations.team_factor(hall, 0, 0, 1), "and on rock")
	runner.gt(Operations.team_factor(Operations.survey_site("sunken", 10, 27), 0, 0, 1),
		Operations.team_factor(Operations.survey_site("sunken", 10, 27), 1, 0, 0), "but on a survey worth two Rigs")
	# A region's way in is its own: it does not grow with the Core.
	runner.eq(float(Operations.survey_site("foundry", 12, 30)["need"]),
		float(Operations.survey_site("foundry", 10, 27)["need"]), "the survey the same at Core 12")
	runner.gt(float(Operations.survey_site("foundry", 10, 27)["need"]),
		float(Operations.survey_site("sunken", 10, 27)["need"]), "danger's way in the hardest")
	_done()


## --- expeditions ------------------------------------------------------------------------

func test_an_expedition_with_a_surveyor_opens_the_chosen_region() -> void:
	_frontier(12)
	runner.eq(Operations.region_slots(9), 0, "")
	runner.eq(Operations.region_slots(10), 1, "one region open at Core 10")
	runner.eq(Operations.region_slots(11), 2, "")
	var t: Vector3i = Sim.expedition_team("sunken")
	runner.eq(t.z, 0, "no Surveyor yet")
	runner.eq(Sim.expedition_blocker("sunken", t.x, t.y, t.z), "surveyor", "an expedition goes only with a Surveyor")
	for _k in range(3):
		Sim.refit_rig("surveyor")
	t = Sim.expedition_team("sunken")
	runner.gte(float(t.z), 1.0, "the default team is led by a Surveyor")
	runner.eq(Sim.expedition_blocker("sunken", t.x, t.y, t.z), "", "")
	runner.check(Sim.send_expedition("sunken", t.x, t.y, t.z), "an expedition into the Sunken Works")
	runner.eq(Sim.expedition_blocker("caverns", 1, 0, 1), "room", "the Core has room for one region")
	runner.check(Sim.site_busy(Operations.region_slot("sunken")), "")
	_run(Operations.SURVEY_TRIP + 2.0)
	runner.check(Sim.region_open("sunken"), "home: the region is open")
	var s: Dictionary = Sim.site(Operations.region_slot("sunken"))
	runner.check(String(s.get("kind", "")) in ["cistern", "stranded"], "its own sites, in its own slot")
	runner.check(Operations.watery(s), "on its terrain: water")
	runner.eq(Sim.expedition_lenses(), Operations.EXPEDITION_LENS, "the next region costs Lenses")
	Sim.core_level = 11
	Sim._recompute()
	var t2: Vector3i = Sim.expedition_team("caverns")
	runner.eq(Sim.expedition_blocker("caverns", t2.x, t2.y, t2.z), "lens", "")
	_done()


## --- each region, on its own ground ----------------------------------------------------

func test_the_regions_ask_for_different_crews_and_give_different_factories() -> void:
	_frontier()
	# Rock: the Caverns' vein wants Breakers; danger: the Foundry's forge a
	# Breaker to lead; water: the Sunken Works' cistern no Breaker at all.
	var vein: Dictionary = Operations.deal_region("caverns", 10, 27, 1)
	var forge: Dictionary = Operations.deal_region("foundry", 10, 27, 2)
	var cistern := Operations.deal_region("sunken", 10, 27, 3)
	cistern["kind"] = "cistern"
	runner.check(Operations.armored(vein), "a vein is rock")
	runner.check(Operations.dangerous(forge), "a forge is danger")
	runner.check(Operations.watery(cistern), "a cistern is water")
	runner.gt(Operations.team_factor(vein, 0, 1, 0), Operations.team_factor(vein, 2, 0, 0) * 2.0, "")
	runner.lt(Operations.team_factor(cistern, 0, 1, 0), Operations.team_factor(cistern, 2, 0, 0), "")
	# Danger: with no Breaker, half the pay; Surveyors wear double.
	Sim.refit_rig("breaker")
	Sim.refit_rig("surveyor")
	Sim.ops_board = [forge.duplicate(), forge.duplicate()]
	(Sim.ops_board[0] as Dictionary)["serial"] = 50
	(Sim.ops_board[1] as Dictionary)["serial"] = 51
	runner.check(Sim.send_sortie(0, 6, 0, 0), "Rigs alone into the forge")
	runner.check(bool(Sim.sorties[0]["out"]["half"]), "bring home half")
	runner.check(Sim.send_sortie(1, 0, 1, 0), "a Breaker leading")
	runner.check(not bool(Sim.sorties[1]["out"]["half"]), "brings home the whole")
	_done()


func test_resonite_comes_home_more_with_surveyors_and_in_the_caverns() -> void:
	_frontier()
	for _k in range(4):
		Sim.refit_rig("surveyor")
	Sim.refit_rig("breaker")
	var base := func(v: int, caverns: bool) -> int:
		Sim.clear_ops()
		Sim.stock = {RIG: 3, MachineDB.Res.ALLOY: 5000, FRAME: 5000, PLATE: 5000}
		Sim.surveyors = 4
		Sim.breakers = 2
		if caverns:
			Sim.regions_open = ["caverns"]
		Sim._recompute()
		var s: Dictionary = Operations.deal_region("caverns", 10, 27, 7)
		s["need"] = 100.0
		s["left"] = 100.0
		Sim.ops_board = [s]
		Sim.send_sortie(0, 0, 2, v)
		_run(200.0)
		return Sim.stock_of(RESONITE)
	var none: int = int(base.call(0, false))
	var two: int = int(base.call(2, false))
	var here: int = int(base.call(0, true))
	runner.gt(float(none), 0.0, "a vein pays Resonite, into the store")
	runner.near(float(two), float(none) * 1.5, 1.01, "two Surveyors find half again")
	runner.near(float(here), float(none) * Operations.CAVERN_RESONITE, 1.01, "and the Caverns half again")
	_done()


func test_a_rescue_is_room_for_a_rig_and_the_crew_mended() -> void:
	_frontier()
	Sim.regions_open = ["sunken"]
	Sim._recompute()
	var cap: int = Sim.crew_cap()
	var s: Dictionary = Operations.deal_region("sunken", 10, 27, 9)
	s["kind"] = "stranded"
	s["need"] = 10.0
	s["left"] = 10.0
	Sim.ops_board = [s]
	Sim.rig_wear = 0.4
	runner.check(Sim.send_sortie(0, 4, 0, 0), "")
	_run(Operations.trip(s) + 2.0)
	runner.eq(Sim.rescued, 1, "a crew brought home")
	runner.eq(Sim.crew_cap(), cap + 1, "is room for one more Rig")
	runner.eq(Sim.rig_wear, 0.0, "and the crew mended")
	_done()


func test_the_sunken_works_brine_cools_and_the_foundry_doubles_salvage() -> void:
	_frontier()
	var c0: float = float(Sim.mult().get("cooling", 1.0))
	Sim.regions_open = ["sunken"]
	Sim._recompute()
	runner.near(float(Sim.mult().get("cooling", 1.0)), c0 * Operations.BRINE_COOLING, 0.001, "brine cools harder")
	Sim.regions_open = ["foundry"]
	Sim._recompute()
	var s: Dictionary = Operations.deal(10, 27, 11)
	s["need"] = 10.0
	s["left"] = 10.0
	Sim.ops_board = [s]
	var before: int = Sim.salvage
	Sim.send_sortie(0, 4, 0, 0)
	_run(Operations.trip(s) + 2.0)
	runner.eq(Sim.salvage - before, Operations.salvage(s) * Operations.FOUNDRY_SALVAGE, "the Foundry pays twice the salvage")
	_done()


## --- the chain, the research, the rows ------------------------------------------------

func test_resonite_becomes_lenses_only_through_the_store_and_a_posted_rig() -> void:
	runner.check(MachineDB.makers_of(RESONITE).is_empty(), "no machine makes Resonite")
	runner.check(MachineDB.STOCKED.has(RESONITE) and MachineDB.STOCKED.has(LENS), "both kept in the store")
	var lens: Dictionary = MachineDB.job_machine("assembler", "lens")
	runner.eq(int((lens["outputs"] as Dictionary).get(LENS, 0)), 1, "")
	runner.check((lens["inputs"] as Dictionary).has(RESONITE) and (lens["inputs"] as Dictionary).has(FRAME), "")
	runner.eq(CoreLevels.material_at(LENS), Operations.REGION_CORE, "Core 10 opens the Lens Grinder")
	_frontier()
	var cell: int = Grid.idx(19, 22)
	Sim.grid.place(cell, "assembler")
	runner.check(Sim.set_job(cell, "lens"), "")
	Sim.stock[RESONITE] = 400
	Sim._recompute()
	runner.check(Sim.post_rig(cell), "a Rig posted to the Grinder")
	_run(60.0)
	runner.gt(float(Sim.stock_of(LENS)), 0.0, "Lenses in the store")
	runner.lt(float(Sim.stock_of(RESONITE)), 400.0, "from the store's Resonite")
	_done()


func test_a_regions_research_opens_with_it_and_goes_at_a_collapse() -> void:
	_frontier()
	Sim.research = 1.0e9
	runner.check(not Sim.can_buy_upgrade("lens_1"), "the Caverns' line, shut")
	Sim.regions_open = ["caverns"]
	runner.check(Sim.can_buy_upgrade("lens_1"), "open with the Caverns")
	runner.check(not Sim.can_buy_upgrade("brine_1"), "the others' lines still shut: the path follows the map")
	Sim.buy_upgrade("lens_1")
	runner.eq(Sim.region_lines(), 1, "")
	Sim.max_depth = 27
	Sim.lifetime_credits = 1.0e12
	if Sim.can_collapse():
		Sim.collapse()
		runner.eq(Sim.upgrade_level("lens_1"), 0, "a region's line goes with the shaft")
		runner.check(Sim.regions_open.is_empty(), "and so do its regions")
	_done()


func test_core_11_asks_for_five_kinds_of_new_work() -> void:
	var reqs: Array = CoreLevels.requirements(11)
	var kinds: Dictionary = {}
	for r: Array in reqs:
		kinds[int(r[0])] = r
	runner.eq(kinds.size(), reqs.size(), "no kind asked twice")
	runner.gte(float(kinds.size()), 5.0, "five kinds")
	for k: int in [CoreLevels.Req.CREDITS, CoreLevels.Req.STOCK, CoreLevels.Req.REGIONS,
			CoreLevels.Req.REGION_LINES, CoreLevels.Req.ROLES]:
		runner.check(kinds.has(k), "Core 11 asks for %s" % CoreLevels.Req.keys()[k])
	runner.eq(int(kinds[CoreLevels.Req.STOCK][1]), LENS, "the store row is the new chain's")
	var p10: float = 0.0
	for r: Array in CoreLevels.requirements(10):
		if int(r[0]) == CoreLevels.Req.CREDITS:
			p10 = float(r[1])
	runner.lte(float(kinds[CoreLevels.Req.CREDITS][1]), p10 * 1.5 + 1.0, "not a price wall")
	runner.eq(CoreLevels.validate(16), [] as Array[String], "the graph holds to Core 16")
	runner.check(bool(CoreLevels.opens(Operations.REGION_CORE)["regions"]), "Core 10 opens the deep map")
	# Past the table: more of the deep map, not the old rows.
	var r12: Array = CoreLevels.requirements(12)
	var regions12: int = 0
	for r: Array in r12:
		if int(r[0]) == CoreLevels.Req.REGIONS:
			regions12 = int(r[1])
	runner.eq(regions12, 2, "Core 12 asks for a second region")


func test_the_rows_read_the_running_shaft() -> void:
	_frontier()
	Sim.core_level = 10
	Sim._recompute()
	var have := func(kind: int) -> float:
		for st: Dictionary in Sim.core_status():
			if int(st["req"][0]) == kind:
				return float(st["have"])
		return -1.0
	runner.eq(float(have.call(CoreLevels.Req.REGIONS)), 0.0, "")
	runner.eq(float(have.call(CoreLevels.Req.ROLES)), 0.0, "no Breaker, no Surveyor")
	Sim.refit_rig("breaker")
	Sim.refit_rig("breaker")
	Sim.refit_rig("surveyor")
	Sim.refit_rig("surveyor")
	Sim.regions_open = ["foundry"]
	Sim.research = 1.0e9
	Sim.buy_upgrade("forge_1")
	runner.eq(float(have.call(CoreLevels.Req.ROLES)), 2.0, "two of each kind")
	runner.eq(float(have.call(CoreLevels.Req.REGIONS)), 1.0, "")
	runner.eq(float(have.call(CoreLevels.Req.REGION_LINES)), 1.0, "")
	_done()


## --- saved, loaded, migrated ------------------------------------------------------------

func test_a_save_keeps_the_deep_map_and_an_expedition_out_comes_home() -> void:
	_frontier(10)
	for _k in range(2):
		Sim.refit_rig("surveyor")
	Sim.refit_rig("breaker")
	Sim.rescued = 2
	Sim.stock[RESONITE] = 77
	Sim.stock[LENS] = 5
	var t: Vector3i = Sim.expedition_team("sunken")
	runner.check(Sim.send_expedition("sunken", t.x, t.y, t.z), "")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.from_dict(d)
	runner.check(Sim.region_open("sunken"), "the expedition out comes home on load, and opens its region")
	runner.eq(Sim.surveyors, 2, "its Surveyors home")
	runner.eq(Sim.breakers, 1, "")
	runner.eq(Sim.rescued, 2, "")
	runner.gt(float(Sim.stock_of(RESONITE)), 77.0, "Resonite kept, and the survey's find added")
	runner.eq(Sim.stock_of(LENS), 5, "Lenses kept")
	var again: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.from_dict(again)
	runner.eq(Sim.regions_open, ["sunken"], "")
	runner.check(String(Sim.site(Operations.region_slot("sunken")).get("region", "")) == "sunken",
		"its site keeps its region")
	_done()


func test_a_save_from_before_the_deep_map_loads() -> void:
	_frontier()
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	for k: String in ["surveyors", "regions_open", "rescued"]:
		d.erase(k)
	Sim.from_dict(d)
	runner.eq(Sim.surveyors, 0, "")
	runner.check(Sim.regions_open.is_empty(), "")
	runner.eq(Sim.rescued, 0, "")
	runner.eq(Sim.ops_board.size(), Operations.SLOTS, "the galleries' board as it was")
	_done()


func test_what_now_points_at_the_deep_map() -> void:
	_frontier()
	var kinds := func() -> Array:
		return Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]) + ":" + String(e.get("role", e.get("region", ""))))
	runner.check((kinds.call() as Array).has("refit:surveyor"), "no Surveyor: refit one")
	for _k in range(3):
		Sim.refit_rig("surveyor")
	var k2: Array = kinds.call()
	var any: bool = false
	for e: String in k2:
		any = any or e.begins_with("expedition:")
	runner.check(any, "a Surveyor: send an expedition")
	_done()
