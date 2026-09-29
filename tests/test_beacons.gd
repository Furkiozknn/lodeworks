extends RefCounted

## Beacons and the Dark Reach (Operations, "Beacons" and "the Dark Reach";
## docs/GAME-LOOP.md, section 13): a region held by a lamp and a Surveyor,
## what it gives and what it burns; the fourth region, dark, with its own
## crew and its Umbrite; the Prism Cutter; a Surveyor tuning a machine; the
## Lenses' ledger; Cores 12 and 13 -- saved, loaded and migrated.

var runner: Object

const RIG := MachineDB.Res.RIG
const PLATE := MachineDB.Res.PLATE
const FRAME := MachineDB.Res.FRAME
const RESONITE := MachineDB.Res.RESONITE
const LENS := MachineDB.Res.LENS
const UMBRITE := MachineDB.Res.UMBRITE
const PRISM := MachineDB.Res.PRISM


## A Core `level` shaft with regions `open` explored, a plated crew of
## `rigs` Rigs -- three of them refitted as Surveyors and four as Breakers --
## at the Bay, fuel, Frames and Lenses.
func _held(level: int = 11, open: Array = ["caverns"], rigs: int = 20) -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 1.0e9
	Sim.research = 0.0
	Sim.cores = 0
	Sim.collapses = 0
	Sim.upgrade_levels = {"rig_plating": 12}
	Sim.core_level = level
	Sim.depth = 27
	Sim.max_depth = 27
	Sim.machine_levels = {"vault": 11}
	Sim.overdrive = {}
	Sim.doctrine = ""
	Sim.clear_ops()
	Sim.ops_lifetime = 0
	Sim.salvage = 200
	Sim.lifetime_credits = 0.0
	Sim.best_core = 1
	Sim.unlocked.clear()
	for id: String in MachineDB.ORDER:
		Sim.unlocked.append(id)
	Sim.stock = {RIG: rigs, MachineDB.Res.ALLOY: 50000, FRAME: 50000, MachineDB.Res.COMPONENT: 50000,
		PLATE: 50000, LENS: 40000}
	Sim.regions_open = open.duplicate()
	Sim._recompute()
	for _k in range(3):
		Sim.refit_rig("surveyor")
	for _k in range(4):
		Sim.refit_rig("breaker")
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
	Sim.lens_spent = {}
	Sim._recompute()
	Save.wipe()


func _run(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		Sim.sim.tick()
		Sim.after_tick(Simulation.TICK_DT)


## Light a Beacon in `r` with the default team and bring it home.
func _light(r: String) -> bool:
	var t: Vector3i = Sim.beacon_team(r)
	if not Sim.send_beacon(r, t.x, t.y, t.z):
		return false
	_run(Operations.SURVEY_TRIP + 2.0)
	return Sim.beacons.has(r)


## --- a Beacon ---------------------------------------------------------------------------

func test_a_beacon_holds_an_open_region_and_a_surveyor_stays_to_keep_it() -> void:
	_held(10)
	var t: Vector3i = Sim.beacon_team("caverns")
	runner.eq(Sim.beacon_blocker("caverns", t.x, t.y, t.z), "core", "Core 11 lights Beacons")
	Sim.core_level = Operations.CONTROL_CORE
	Sim._recompute()
	t = Sim.beacon_team("caverns")
	runner.eq(Sim.beacon_blocker("sunken", t.x, t.y, t.z), "closed", "only in an open region")
	runner.eq(Sim.beacon_blocker("caverns", t.x, t.y, 0), "surveyor", "a Surveyor to keep it")
	runner.eq(Sim.beacon_blocker("caverns", 1, 0, 1), "weak", "the high ground is held by a team strong enough")
	Sim.stock[LENS] = 10
	runner.eq(Sim.beacon_blocker("caverns", t.x, t.y, t.z), "lens", "")
	Sim.stock[LENS] = 40000
	runner.eq(Sim.beacon_blocker("caverns", t.x, t.y, t.z), "", "")
	var lit: Array = []
	Sim.beacon_lit.connect(func(r: String) -> void: lit.append(r))
	var v0: int = Sim.surveyors
	var roles0: int = int(Sim.crew_roles()["surveyor"])
	runner.check(Sim.send_beacon("caverns", t.x, t.y, t.z), "")
	runner.eq(Sim.stock_of(LENS), 40000 - Operations.BEACON_LENS, "the first Beacon's Lenses")
	runner.eq(int(Sim.lens_spent.get("beacon", 0)), Operations.BEACON_LENS, "on the ledger")
	_run(Operations.SURVEY_TRIP + 2.0)
	runner.eq(Sim.beacons, ["caverns"], "home: the Caverns are held")
	runner.eq(lit, ["caverns"], "and the card is told")
	runner.eq(Sim.surveyors, v0 - 1, "one Surveyor stayed with the lamp")
	runner.eq(int(Sim.crew_roles()["surveyor"]), roles0, "still the crew's")
	runner.eq(Sim.beacon_lenses(), Operations.BEACON_LENS * 2, "the next Beacon costs more")
	runner.check(Sim.douse_beacon("caverns"), "put out")
	runner.eq(Sim.surveyors, v0, "its keeper home")
	runner.check(not Sim.controlled("caverns"), "")
	_done()


func test_breakers_hold_a_beacons_ground_even_in_water() -> void:
	_held(11, ["sunken", "caverns"])
	var survey: Dictionary = Operations.survey_site("sunken", 11, 27)
	var ground: Dictionary = Operations.beacon_site("sunken", 11, 27)
	runner.eq(float(ground["need"]), float(survey["need"]) * Operations.BEACON_NEED, "the survey's own ground")
	runner.check(Operations.holding(ground) and Operations.watery(ground), "")
	var held: float = Operations.team_factor(ground, 0, 1, 0)
	var wet: float = Operations.team_factor(Operations.deal_region("sunken", 11, 27, 1), 0, 1, 0)
	runner.eq(held, wet * Operations.CONTROL_HOLD, "a Breaker holds half again")
	runner.gt(held, Operations.team_factor(ground, 1, 0, 0), "and there does more than a Rig")
	var rock: Dictionary = Operations.beacon_site("caverns", 11, 27)
	runner.gt(Operations.team_factor(rock, 0, 1, 0), 3.0 * Operations.team_factor(rock, 1, 0, 0),
		"on rock, far more")
	_done()


func test_a_beacon_burns_lenses_and_goes_dark_without_them() -> void:
	_held(11)
	runner.check(_light("caverns"), "")
	runner.check(Sim.controlled("caverns"), "")
	var dims: Array = []
	Sim.beacons_dimmed.connect(func(dark: bool) -> void: dims.append(dark))
	var before: int = Sim.stock_of(LENS)
	_run(36.0)
	var burnt: int = before - Sim.stock_of(LENS)
	runner.gte(float(burnt), Operations.BEACON_UPKEEP / 100.0 - 2.0, "about a hundredth of an hour's upkeep")
	runner.lte(float(burnt), Operations.BEACON_UPKEEP / 100.0 + 2.0, "")
	runner.gte(float(Sim.lens_spent.get("upkeep", 0)), float(burnt), "on the ledger")
	Sim.stock[LENS] = 0
	_run(3.0)
	runner.check(Sim.beacons_dark, "no Lenses: dark")
	runner.eq(Sim.lit_beacons(), 0, "")
	runner.check(not Sim.controlled("caverns"), "what it gives stops")
	runner.check(Sim.sim.jobs_off.has("resonite"), "the Resonant Bore with it")
	runner.eq(dims, [true], "")
	Sim.stock[LENS] = 100
	_run(1.0)
	runner.check(not Sim.beacons_dark, "Lenses again: lit again")
	runner.eq(dims, [true, false], "")
	_done()


## --- what a held region gives -------------------------------------------------------------

func test_a_held_region_pays_more_deals_every_tier_and_researches_further() -> void:
	_held(12, ["caverns", "foundry"])
	var slot: int = Operations.region_slot("caverns")
	var pay0: Dictionary = Sim.site_reward(slot)
	runner.eq(Sim.line_max("lens_1"), 4, "")
	runner.check(_light("caverns"), "")
	var pay1: Dictionary = Operations.reward(Sim.site(slot), Sim.offline_rate())
	var shown: Dictionary = Sim.site_reward(slot)
	runner.eq(float(shown["research"]), float(pay1["research"]) * Operations.CONTROL_PAY, "half again")
	runner.eq(Sim.line_max("lens_1"), 4 + Operations.CONTROL_LINE, "its research goes further")
	runner.eq(Sim.research_cap("lens_1"), 6, "as far as the Core lets it")
	runner.eq(Sim.line_max("forge_1"), 4, "the Foundry's does not")
	var tiers: Dictionary = {}
	for serial in range(60):
		tiers[int(Operations.deal_region("caverns", 12, 27, serial, true)["tier"])] = true
		runner.lte(float(Operations.deal_region("caverns", 12, 27, serial)["tier"]), 1.0, "an unheld region, two tiers")
	runner.check(tiers.has(2), "a held one, every tier")
	runner.check(pay0.has("credits"), "")
	_done()


func test_each_region_held_gives_its_own_work() -> void:
	_held(12, ["sunken", "caverns", "foundry"], 24)
	var cooling0: float = float(Sim._mult["cooling"])
	runner.check(_light("sunken"), "")
	runner.eq(float(Sim._mult["cooling"]), cooling0 / Operations.BRINE_COOLING * Operations.BRINE_CONTROL,
		"the Sunken Works' brine mains")
	# The Caverns: the Resonant Bore, only while its Beacon burns.
	var cell: int = Grid.idx(19, 22)
	Sim.grid.place(cell, "drill")
	runner.eq(Sim.job_blocker(cell, "resonite"), "control", "no Bore before the Caverns are held")
	Sim.research = 0.0
	Sim.stock[LENS] = 40000
	runner.check(_light("caverns"), "")
	runner.check(Sim.set_job(cell, "resonite"), "a Resonant Bore")
	runner.check(Sim.can_make(RESONITE), "Resonite made on the board")
	var r0: int = Sim.stock_of(RESONITE)
	_run(30.0)
	runner.gt(float(Sim.stock_of(RESONITE)), float(r0), "into the store, beside the Core")
	# The Foundry: three times a site's salvage.
	Sim.stock[LENS] = 100000
	runner.check(_light("foundry"), "")
	var slot: int = Operations.region_slot("foundry")
	var s: Dictionary = Sim.site(slot)
	s["left"] = 1.0
	var salv0: int = Sim.salvage
	runner.check(Sim.send_sortie(slot, 1, 1, 0), "")
	_run(Operations.trip(s) + 2.0)
	runner.eq(Sim.salvage - salv0, Operations.salvage(s) * Operations.FOUNDRY_CONTROL, "three times the salvage")
	_done()


## --- the Dark Reach ------------------------------------------------------------------------

func test_the_dark_reach_opens_to_two_beacons_and_needs_a_guide() -> void:
	_held(11, ["sunken", "caverns"], 24)
	var t: Vector3i = Sim.expedition_team("reach")
	runner.eq(Sim.expedition_blocker("reach", t.x, t.y, t.z), "core", "Core 12 opens the way")
	Sim.core_level = Operations.REACH_CORE
	Sim._recompute()
	t = Sim.expedition_team("reach")
	runner.eq(Sim.expedition_blocker("reach", t.x, t.y, t.z), "beacons", "and two Beacons light it")
	runner.check(_light("sunken"), "")
	runner.check(_light("caverns"), "")
	runner.check(Sim.refit_rig("surveyor"), "")
	t = Sim.expedition_team("reach")
	runner.gte(float(t.z), 1.0, "led by a Surveyor")
	runner.eq(Sim.expedition_blocker("reach", t.x, t.y, t.z), "", "")
	var lens0: int = Sim.stock_of(LENS)
	var price: int = Sim.expedition_lenses()
	runner.check(Sim.send_expedition("reach", t.x, t.y, t.z), "")
	runner.eq(lens0 - Sim.stock_of(LENS), price + Operations.dark_lens(t.x, t.y, t.z),
		"the expedition's Lenses, and light for the dark")
	runner.gt(float(Sim.lens_spent.get("light", 0)), 0.0, "on the ledger")
	_run(Operations.SURVEY_TRIP + 2.0)
	runner.check(Sim.region_open("reach"), "the Dark Reach is open")
	var s: Dictionary = Sim.site(Operations.region_slot("reach"))
	runner.check(Operations.dark(s), "its ground is dark")
	runner.check(String(s.get("kind", "")) in ["hollow", "shade"], "its own sites")
	# The dark: lost without a guide, a Surveyor's lamps worth more.
	runner.eq(Operations.team_factor(s, 4, 0, 0), 4.0 * Operations.DARK_LOST, "lost without a Surveyor")
	runner.eq(Operations.team_factor(s, 4, 0, 1), 4.0 + Operations.DARK_SURVEYOR, "")
	runner.eq(Operations.team_factor(s, 0, 1, 1), Operations.DARK_BREAKER + Operations.DARK_SURVEYOR,
		"a Breaker is only a Rig in the dark")
	runner.eq(Sim.light_lenses(s, 2, 1, 1), 4 * Operations.DARK_LENS, "Lenses a head for light")
	Sim.stock[LENS] = 0
	runner.eq(Sim.sortie_blocker(Operations.region_slot("reach"), 2, 1, 1), "light", "no Lenses, no light")
	_done()


func test_umbrite_comes_home_and_becomes_prisms() -> void:
	_held(12, ["caverns"])
	var hollow: Dictionary = Operations.deal_region("reach", 12, 27, 3)
	hollow["kind"] = "hollow"
	var pay: Dictionary = Operations.reward(hollow, 0.0)
	runner.eq(int(pay["res"]), UMBRITE, "a hollow holds Umbrite")
	runner.eq(int(pay["n"]), int(ceil(float(hollow["need"]) * Operations.UMBRITE_PER_NEED)), "")
	runner.check(MachineDB.makers_of(UMBRITE).is_empty(), "no machine makes Umbrite")
	runner.eq(CoreLevels.material_at(PRISM), Operations.REACH_CORE, "Core 12 opens the Prism Cutter")
	var cell: int = Grid.idx(19, 22)
	Sim.grid.place(cell, "assembler")
	runner.eq(Sim.job_blocker(cell, "prism"), "region", "not before the Dark Reach is open")
	Sim.regions_open.append("reach")
	Sim._recompute()
	runner.check(Sim.set_job(cell, "prism"), "a Prism Cutter")
	Sim.stock[UMBRITE] = 200
	runner.check(Sim.post_rig(cell), "fed from the store")
	var l0: int = Sim.stock_of(LENS)
	_run(60.0)
	runner.gt(float(Sim.stock_of(PRISM)), 0.0, "Prisms in the store")
	runner.lt(float(Sim.stock_of(LENS)), float(l0), "from the store's Lenses")
	runner.gt(float(Sim.lens_spent.get("factory", 0)), 0.0, "on the ledger, as the factory's")
	_done()


## --- a Surveyor tuning ----------------------------------------------------------------------

func test_a_surveyor_tunes_a_grinder_to_half_the_resonite() -> void:
	_held(11)
	var cell: int = Grid.idx(19, 22)
	Sim.grid.place(cell, "assembler")
	runner.eq(Sim.tune_blocker(cell), "job", "an Assembler on its own recipe is not tuned")
	runner.check(Sim.set_job(cell, "lens"), "")
	runner.eq(Sim.tune_blocker(cell), "", "")
	var v0: int = Sim.surveyors
	runner.check(Sim.tune(cell), "")
	runner.eq(Sim.surveyors, v0 - 1, "a Surveyor from the Bay")
	runner.eq(Sim.surveyors_away(), 1, "")
	runner.eq(Sim.sim.cell_inputs.get(cell, {}), {FRAME: 1, RESONITE: 1}, "half the Resonite a Lens")
	Sim.stock[RESONITE] = 300
	runner.check(Sim.post_rig(cell), "")
	_run(60.0)
	var tuned_lens: int = Sim.stock_of(LENS) - 40000
	var tuned_res: int = 300 - Sim.stock_of(RESONITE)
	runner.gt(float(tuned_lens), 0.0, "")
	runner.check(Sim.untune(cell), "")
	runner.eq(Sim.surveyors, v0, "home")
	runner.check(Sim.sim.cell_inputs.is_empty(), "the recipe as it was")
	Sim.tune(cell)
	Sim.sell(cell)
	runner.eq(Sim.surveyors, v0, "a machine sold sends its Surveyor home")
	runner.check(Sim.tuners.is_empty(), "")
	runner.gt(float(tuned_res), 0.0, "")
	_done()


## --- Cores 12 and 13 --------------------------------------------------------------------------

func test_cores_12_and_13_each_ask_five_kinds_of_new_work() -> void:
	for level: int in [12, 13]:
		var kinds: Dictionary = {}
		for r: Array in CoreLevels.requirements(level):
			kinds[int(r[0])] = r
		runner.gte(float(kinds.size()), 5.0, "Core %d: five kinds or more" % level)
		runner.check(kinds.has(CoreLevels.Req.BEACONS), "Core %d asks for Beacons" % level)
		runner.check(kinds.has(CoreLevels.Req.CREDITS) and kinds.has(CoreLevels.Req.REGIONS)
			and kinds.has(CoreLevels.Req.REGION_LINES) and kinds.has(CoreLevels.Req.ROLES), "")
	var r13: Dictionary = {}
	for r: Array in CoreLevels.requirements(13):
		r13[int(r[0])] = r
	runner.eq(int(r13[CoreLevels.Req.STOCK][1]), PRISM, "Core 13's store row is the Dark Reach's")
	runner.eq(int(r13[CoreLevels.Req.BEACONS][1]), 2, "")
	var r12: Dictionary = {}
	for r: Array in CoreLevels.requirements(12):
		r12[int(r[0])] = r
	runner.eq(String(r12[CoreLevels.Req.WORKING][3]), "lens", "Core 12: a second Lens Grinder")
	runner.check(bool(CoreLevels.opens(Operations.CONTROL_CORE)["beacons"]), "Core 11 opens Beacons")
	runner.check(bool(CoreLevels.opens(Operations.REACH_CORE)["reach"]), "Core 12 the Dark Reach")
	runner.eq(CoreLevels.validate(18), [] as Array[String], "the graph holds to Core 18")
	var r14: Dictionary = {}
	for r: Array in CoreLevels.requirements(14):
		r14[int(r[0])] = r
	runner.eq(int(r14[CoreLevels.Req.REGIONS][1]), 4, "Core 14: the whole map")
	runner.eq(int(r14[CoreLevels.Req.BEACONS][1]), 3, "and a third Beacon")
	_done()


func test_the_beacons_row_reads_the_running_shaft() -> void:
	_held(11, ["caverns"])
	var have := func() -> float:
		for st: Dictionary in Sim.core_status():
			if int(st["req"][0]) == CoreLevels.Req.BEACONS:
				return float(st["have"])
		return -1.0
	runner.eq(float(have.call()), 0.0, "")
	runner.check(_light("caverns"), "")
	runner.eq(float(have.call()), 1.0, "")
	Sim.stock[LENS] = 0
	_run(3.0)
	runner.eq(float(have.call()), 0.0, "a dark Beacon holds nothing")
	_done()


## --- saved, loaded, migrated -----------------------------------------------------------------

func test_a_save_keeps_beacons_tuners_and_the_ledger() -> void:
	_held(11, ["caverns"])
	runner.check(_light("caverns"), "")
	var cell: int = Grid.idx(19, 22)
	Sim.grid.place(cell, "assembler")
	Sim.set_job(cell, "lens")
	Sim.tune(cell)
	var v: int = Sim.surveyors
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.from_dict(d)
	runner.eq(Sim.beacons, ["caverns"], "")
	runner.check(Sim.tuners.has(cell), "")
	runner.eq(Sim.surveyors, v, "")
	runner.eq(Sim.sim.cell_inputs.get(cell, {}), {FRAME: 1, RESONITE: 1}, "the tuned recipe back")
	runner.eq(int(Sim.lens_spent.get("beacon", 0)), Operations.BEACON_LENS, "")
	# A Beacon out, lighting, comes home on load.
	Sim.douse_beacon("caverns")
	var t: Vector3i = Sim.beacon_team("caverns")
	Sim.send_beacon("caverns", t.x, t.y, t.z)
	var d2: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.from_dict(d2)
	runner.eq(Sim.beacons, ["caverns"], "lit on load")
	_done()


func test_a_save_from_before_beacons_loads() -> void:
	_held(11, ["caverns"])
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	for k: String in ["beacons", "beacons_dark", "upkeep_due", "tuners", "lens_spent"]:
		d.erase(k)
	Sim.from_dict(d)
	runner.check(Sim.beacons.is_empty() and Sim.tuners.is_empty(), "")
	runner.check(not Sim.beacons_dark, "")
	runner.eq(Sim.lens_spent, {}, "")
	runner.eq(Sim.regions_open, ["caverns"], "the deep map as it was")
	# Beacons only in open regions.
	d["beacons"] = ["caverns", "foundry", "nowhere"]
	Sim.from_dict(d)
	runner.eq(Sim.beacons, ["caverns"], "")
	_done()


func test_what_now_points_at_a_beacon_and_a_tune() -> void:
	_held(11, ["caverns"])
	var kinds := func() -> Array:
		return Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]))
	runner.check((kinds.call() as Array).has("beacon"), "Core 12 asks for a Beacon: light one")
	var cell: int = Grid.idx(19, 22)
	Sim.grid.place(cell, "assembler")
	Sim.set_job(cell, "lens")
	runner.check((kinds.call() as Array).has("tune"), "a Surveyor at the Bay and a Grinder to tune")
	_done()
