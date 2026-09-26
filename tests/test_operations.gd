extends RefCounted

## The crew and the galleries (Operations; docs/GAME-LOOP.md): Rigs made on
## the Rig Frame job and kept at the Core up to the crew's limit; sites
## dealt deterministically; a sortie decided when it leaves, walking home
## with its reward and its wear; a sortie too weak leaving its site weaker;
## repairs in Plates; Rig Plating; a save; a collapse; the Core 5 row.

var runner: Object

const RIG := MachineDB.Res.RIG
const INGOT := MachineDB.Res.INGOT
const PLATE := MachineDB.Res.PLATE


func _fresh(core: int = MachineDB.RIG_CORE, depth: int = 6) -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.salvage = 0
	Sim.depth = depth
	Sim.max_depth = depth
	Sim.lifetime_credits = 0.0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.core_level = core
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


func _done() -> void:
	_fresh(1, 0)
	Save.wipe()


## --- the crew -----------------------------------------------------------------------

func test_the_crew_opens_at_core_4_with_the_rig_frame_job() -> void:
	runner.eq(Operations.crew_cap(MachineDB.RIG_CORE - 1), Operations.FIRST_CREW,
		"before Core 4, one Rig: the Foreman's")
	runner.eq(Operations.crew_cap(MachineDB.RIG_CORE), Operations.CREW_BASE, "three Rigs at Core 4")
	runner.eq(Operations.crew_cap(MachineDB.RIG_CORE + 2), Operations.CREW_BASE + 2, "one more a level")
	var m: Dictionary = MachineDB.job_machine("assembler", "rig")
	runner.eq(m["inputs"], {PLATE: 2}, "a Rig is two Plates")
	runner.eq(m["outputs"], {RIG: 1}, "")
	runner.lt(float(m["rate"]), float(MachineDB.get_machine("assembler")["rate"]) / 5.0,
		"and a machine's minutes of work, not a part's seconds")
	runner.eq(CoreLevels.job_at("assembler", "rig"), MachineDB.RIG_CORE, "the Core's level 4 opens it")
	var o: Dictionary = CoreLevels.opens(MachineDB.RIG_CORE)
	runner.check(bool(o["operations"]) and (o["jobs"] as Array).has(["assembler", "rig"]),
		"and says so: the job and the galleries")
	# Core 5 asks for sites cleared.
	var ops: Array = []
	for r: Array in CoreLevels.requirements(5):
		if int(r[0]) == CoreLevels.Req.OPERATIONS:
			ops = r
	runner.check(not ops.is_empty(), "Core 5 asks for sites cleared")
	runner.eq(CoreLevels.available_at(ops), Operations.FIRST_SITE_CORE, "which the first gallery makes possible")
	runner.check(not MachineDB.STOCKED.has(RIG), "a Rig is crew, not stock: no store row, contract or export")
	runner.eq(Operations.fuel_res(MachineDB.FRAME_CORE - 1), INGOT, "sorties burn Ingots until the Core 8 era")
	runner.eq(Operations.fuel_res(MachineDB.FRAME_CORE), MachineDB.Res.ALLOY, "and Alloy in it")
	# Sites cleared earn the crew room: one Rig every ten, up to six.
	runner.eq(Operations.earned_rigs(9), 0, "")
	runner.eq(Operations.earned_rigs(10), 1, "ten sites cleared, room for one more Rig")
	runner.eq(Operations.earned_rigs(1000), Operations.SITE_RIGS_MAX, "never more than six")
	_fresh()
	Sim.ops_lifetime = 23
	runner.eq(Sim.crew_cap(), Operations.CREW_BASE + 2, "a Core 4 crew after 23 sites in all")
	runner.eq(Sim.sites_to_next_rig(), 7, "and seven more for the next")
	_fresh(3, 6)
	Sim.ops_lifetime = 50
	runner.eq(Sim.crew_cap(), Operations.FIRST_CREW, "one Rig before Core 4, whatever it has done")
	runner.eq(Sim.sites_to_next_rig(), 0, "and no room to earn before the Rig Frame")
	_done()


func test_rigs_come_from_beside_the_core_up_to_the_crew_limit() -> void:
	_fresh()
	runner.eq(int(Sim.sim.core_wants.get(RIG, 0)), Sim.crew_cap(), "the Core has room for its whole crew")
	Sim.sim.core_took = {RIG: 10}
	Sim._collect_stock()
	runner.eq(Sim.rigs_home(), Sim.crew_cap(), "no more than the limit is kept")
	runner.eq(int(Sim.sim.core_wants.get(RIG, 0)), 0, "and the Core takes no more")
	_fresh(3, 6)
	runner.eq(int(Sim.sim.core_wants.get(RIG, 0)), 0, "a Core 3 takes in no Rigs: nothing makes them yet")
	runner.eq(Sim.ops_board.size(), 1, "and has one gallery open")
	_done()


## --- before the crew: the Foreman's Rig and the first gallery ----------------------

func test_the_foremans_rig_and_the_first_gallery() -> void:
	_fresh(1, 0)
	Sim.core_online = false
	Sim.stock = {}
	runner.check(Sim.power_core(), "")
	runner.eq(Sim.rigs_home(), Operations.FIRST_CREW, "the Core comes online with the Foreman's Rig")
	runner.check(Sim.ops_board.is_empty(), "no gallery open at level 1")
	runner.eq(Sim.sortie_blocker(0, 1), "core", "")
	_fresh(2, 3)
	Sim.stock = {RIG: 1, INGOT: 50}
	Sim._sync_core()
	runner.eq(Sim.ops_board.size(), 1, "Core 2 opens one gallery")
	var s: Dictionary = Sim.site(0).duplicate()
	runner.check(["flooded", "drift"].has(String(s["kind"])), "of what a first factory knows")
	runner.near(float(s["need"]), Operations.EARLY_NEED, 0.0001, "")
	runner.check(Sim.crew_strength(1) >= float(s["left"]), "which one whole Rig clears")
	var r: Dictionary = Operations.reward(s, 0.0)
	runner.near(float(r["credits"]), Operations.EARLY_NEED * Operations.CREDITS_PER_NEED * Operations.EARLY_PAY,
		0.01, "for a quarter of a later site's pay")
	var kinds: Array = Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]))
	runner.check(kinds.has("sortie"), "What now? points at it")
	runner.check(Sim.send_sortie(0, 1), "the Rig goes in")
	kinds = Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]))
	runner.check(not kinds.has("sortie"), "and not while it is out")
	Sim.advance_ops(Operations.trip(s) + 1.0)
	runner.eq(Sim.ops_cleared, 1, "and clears it")
	runner.eq(Sim.rigs_home(), 1, "home again")
	runner.eq(Sim.ops_board.size(), 1, "and another is dealt")
	var ops: Array = []
	for row: Array in CoreLevels.requirements(3):
		if int(row[0]) == CoreLevels.Req.OPERATIONS:
			ops = row
	runner.eq(ops, [CoreLevels.Req.OPERATIONS, 1], "Core 3 asks for that one site")
	# What the first sorties bring makes the factory faster from Core 2: four
	# early sites' salvage and a little research buy Salvaged Gearing.
	runner.eq(int(Sim.site_reward(0)["salvage"]), 1, "an early site pays one salvage")
	Sim.salvage = 4
	Sim.research = 100.0
	runner.check(Sim.can_buy_upgrade("salvage_gearing"), "four of them buy Salvaged Gearing at Core 2")
	_done()


## --- the board ----------------------------------------------------------------------

func test_a_site_is_dealt_the_same_way_every_time_and_grows_with_the_core() -> void:
	runner.eq(Operations.deal(4, 6, 3), Operations.deal(4, 6, 3), "the same board on every device")
	var nests: int = 0
	for serial in range(40):
		var s: Dictionary = Operations.deal(4, 6, serial)
		nests += 1 if String(s["kind"]) == "nest" else 0
		runner.near(float(s["need"]), Operations.NEED_BASE * float(Operations.TIERS[int(s["tier"])]), 0.5,
			"a Core 4 site's strength is its tier's")
	runner.eq(nests, 0, "the nest, which fights back, waits for Core 5")
	var later: int = 0
	for serial in range(40):
		later += 1 if String(Operations.deal(6, 6, serial)["kind"]) == "nest" else 0
	runner.gt(float(later), 0.0, "and then comes")
	var s6: Dictionary = Operations.deal(6, 6, 0)
	runner.near(float(s6["need"]), Operations.NEED_BASE * pow(Operations.NEED_GROWTH, 2.0)
		* float(Operations.TIERS[int(s6["tier"])]), 0.5, "two Core levels on, 1.35 times twice")
	runner.gt(float(Operations.deal(4, 30, 0)["hazard"]), float(Operations.deal(4, 0, 0)["hazard"]),
		"deeper galleries are rougher")


func test_a_sortie_is_decided_the_moment_it_leaves() -> void:
	var s: Dictionary = {"kind": "drift", "tier": 0, "need": 20.0, "left": 20.0, "hazard": 0.2}
	var even: Dictionary = Operations.resolve(s, 20.0)
	runner.check(bool(even["cleared"]), "strength enough clears it")
	runner.near(float(even["share"]), 1.0, 0.0001, "for the whole reward")
	runner.near(float(even["wear"]), 0.2, 0.0001, "and the site's full wear")
	var twice: Dictionary = Operations.resolve(s, 40.0)
	runner.near(float(twice["wear"]), 0.1, 0.0001, "twice the strength, half the wear")
	var short: Dictionary = Operations.resolve(s, 5.0)
	runner.check(not bool(short["cleared"]), "a quarter of it does not")
	runner.near(float(short["share"]), 0.25, 0.0001, "but earns a quarter of the reward")
	runner.near(float(short["left"]), 15.0, 0.0001, "and leaves the site weaker")
	runner.eq(Operations.verdict(s, 45.0), "trivial", "")
	runner.eq(Operations.verdict(s, 31.0), "easy", "")
	runner.eq(Operations.verdict(s, 20.0), "even", "")
	runner.eq(Operations.verdict(s, 10.0), "hard", "")
	runner.eq(Operations.verdict(s, 5.0), "reach", "")


## --- sorties -------------------------------------------------------------------------

func test_a_sortie_walks_out_and_home_with_its_reward_and_its_wear() -> void:
	_fresh()
	runner.eq(Sim.ops_board.size(), Operations.SLOTS, "a Core 4 deals the whole board")
	Sim.stock = {RIG: 3, INGOT: 100}
	Sim._sync_core()
	var i: int = 0
	var s: Dictionary = Sim.site(i).duplicate()
	var fuel: int = Operations.fuel(3, Sim.core_level)
	var strength: float = Sim.crew_strength(3)
	var out: Dictionary = Operations.resolve(s, strength)
	var reward: Dictionary = Sim.site_reward(i)
	runner.check(Sim.send_sortie(i, 3), "three Rigs go")
	runner.eq(Sim.rigs_home(), 0, "none left at the Core")
	runner.eq(Sim.rigs_out(), 3, "")
	runner.eq(Sim.stock_of(INGOT), 100 - fuel, "and their fuel is burnt")
	runner.check(Sim.site_busy(i) and Sim.sortie_blocker(i, 1) == "busy", "one sortie to a site at a time")
	runner.eq(int(Sim.sim.core_wants.get(RIG, 0)), 0, "Rigs out still count against the crew")
	Sim.advance_ops(Operations.trip(s) - 1.0)
	runner.eq(Sim.rigs_out(), 3, "a second short of home they are still out")
	Sim.advance_ops(2.0)
	runner.eq(Sim.rigs_out(), 0, "then home")
	runner.eq(Sim.rigs_home(), 3, "all of them: a Rig is never lost")
	runner.near(Sim.credits, float(reward["credits"]) * float(out["share"]), 0.01, "with the reward")
	runner.near(Sim.research, float(reward["research"]) * float(out["share"]), 0.01, "")
	runner.near(Sim.rig_wear, float(out["wear"]), 0.0001, "worn by the site")
	if bool(out["cleared"]):
		runner.eq(Sim.ops_cleared, 1, "a site cleared counts")
		runner.gt(float(Sim.ops_serial), float(Operations.SLOTS), "and its slot is dealt again")
	_done()


func test_a_sortie_too_weak_takes_its_share_and_leaves_the_site_weaker() -> void:
	_fresh()
	Sim.ops_board[1] = {"kind": "pumphouse", "tier": 2, "need": 100.0, "left": 100.0, "hazard": 0.1,
		"serial": 99, "core": Sim.core_level, "depth": Sim.depth}
	Sim.stock = {RIG: 1, INGOT: 100}
	var strength: float = Sim.crew_strength(1)
	runner.eq(Operations.verdict(Sim.site(1), strength), "reach", "one Rig against a site of 100")
	runner.check(Sim.send_sortie(1, 1), "sent anyway")
	Sim.advance_ops(600.0)
	runner.eq(Sim.ops_cleared, 0, "not cleared")
	runner.near(float(Sim.site(1)["left"]), 100.0 - strength, 0.001, "but what it did stays done")
	runner.gt(Sim.credits, 0.0, "and it earned its share")
	_done()


func test_blockers_repairs_and_rig_plating() -> void:
	_fresh(1, 0)
	runner.eq(Sim.sortie_blocker(0, 1), "core", "no gallery open at Core 1")
	_fresh()
	runner.eq(Sim.sortie_blocker(0, 1), "rigs", "no Rigs at home")
	Sim.stock = {RIG: 2}
	runner.eq(Sim.sortie_blocker(0, 2), "fuel", "no Ingots for their fuel")
	runner.eq(Sim.sortie_blocker(0, 3), "rigs", "not three at home")
	# Wear, and its repair in Plates.
	Sim.rig_wear = 0.5
	var whole: float = Sim.crew_strength(2) / 0.5
	var cost: int = Sim.repair_cost()
	runner.eq(cost, Operations.repair_cost(2, 0.5, Sim.core_level), "")
	runner.gt(float(cost), 0.0, "worn Rigs cost Plates to repair")
	runner.check(not Sim.repair_rigs(), "not without them")
	Sim.stock[PLATE] = cost
	runner.check(Sim.repair_rigs(), "with them, at once")
	runner.eq(Sim.stock_of(PLATE), 0, "")
	runner.near(Sim.crew_strength(2), whole, 0.001, "and they are whole again")
	# Rig Plating: every Rig stronger.
	Sim.upgrade_levels["rig_plating"] = 2
	Sim._recompute()
	runner.near(Sim.crew_strength(2), whole * 1.4, 0.001, "two levels of Rig Plating: 40% stronger")
	runner.eq(Economy.research_cap("rig_plating", MachineDB.RIG_CORE), Economy.RESEARCH_PER_CORE,
		"opened with the crew")
	_done()


## --- a save and a collapse ------------------------------------------------------------

func test_a_sortie_out_when_the_game_closes_comes_home_on_loading() -> void:
	_fresh()
	Sim.stock = {RIG: 3, INGOT: 100}
	var cleared: bool = bool(Operations.resolve(Sim.site(2), Sim.crew_strength(3))["cleared"])
	runner.check(Sim.send_sortie(2, 3), "")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.clear_ops()
	Sim.stock = {}
	Sim.credits = 0.0
	Sim.from_dict(d)
	runner.eq(Sim.rigs_out(), 0, "the sortie is home")
	runner.eq(Sim.rigs_home(), 3, "with every Rig")
	runner.gt(Sim.credits, 0.0, "and its reward")
	runner.eq(Sim.ops_cleared, 1 if cleared else 0, "")
	runner.eq(Sim.ops_board.size(), Operations.SLOTS, "the board is back")
	# A save from before the galleries loads with none.
	d.erase("ops_board")
	d.erase("sorties")
	d.erase("rig_wear")
	Sim.from_dict(d)
	runner.eq(Sim.rigs_out(), 0, "")
	runner.near(Sim.rig_wear, 0.0, 0.0001, "")
	_done()


func test_a_collapse_takes_the_crew_and_the_board_and_keeps_rig_plating() -> void:
	_fresh(6, 12)
	Sim.cores = 0
	Sim.salvage = 0
	Sim.lifetime_credits = 1.0e9
	Sim.stock = {RIG: 3, INGOT: 100}
	Sim.upgrade_levels["rig_plating"] = 1
	Sim.ops_cleared = 4
	Sim.ops_lifetime = 4
	Sim.salvage = 7
	Sim.send_sortie(0, 1)
	Sim.depth = 12
	if Sim.can_collapse():
		Sim.collapse()
		runner.eq(Sim.rigs_home() + Sim.rigs_out(), 0, "the crew goes with the shaft")
		runner.eq(Sim.ops_cleared, 0, "and the count of its sites")
		runner.eq(Sim.ops_lifetime, 4, "not the lifetime count")
		runner.eq(Sim.upgrade_level("rig_plating"), 1, "Rig Plating stays, as the tree does")
		runner.eq(Sim.salvage, 7, "and so does salvage, as Cores do")
	else:
		runner.check(false, "a Core 6 shaft on stratum 12 can collapse")
	_done()


## --- salvage: what only the galleries pay ---------------------------------------------

func test_a_cleared_site_pays_salvage_which_buys_what_research_alone_cannot() -> void:
	_fresh()
	Sim.stock = {RIG: 3, INGOT: 100}
	Sim._sync_core()
	Sim.ops_board[0]["left"] = 1.0
	var s: Dictionary = Sim.site(0).duplicate()
	var due: int = 1 + int(s["tier"]) + (Operations.SALVAGE_NEST if String(s["kind"]) == "nest" else 0)
	runner.eq(int(Sim.site_reward(0)["salvage"]), due, "a site prints its salvage with its pay")
	runner.check(Sim.send_sortie(0, 1), "")
	Sim.advance_ops(Operations.trip(s) + 1.0)
	runner.eq(Sim.salvage, due, "and pays it, cleared")
	# Only salvage buys Salvaged Gearing, however much research there is.
	Sim.research = 1.0e6
	Sim.salvage = 3
	runner.check(not Sim.can_buy_upgrade("salvage_gearing"), "four salvage for the first level: three is short")
	Sim.salvage = 10
	runner.check(Sim.buy_upgrade("salvage_gearing"), "ten is enough")
	runner.eq(Sim.salvage, 6, "and four are spent")
	runner.near(float(Economy.multipliers({"salvage_gearing": 1})["speed"]), 1.05, 0.0001,
		"every machine works 5% faster")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.salvage = 0
	Sim.from_dict(d)
	runner.eq(Sim.salvage, 6, "a save keeps it")
	_done()


func test_a_save_keeps_the_crew_its_wear_the_board_and_the_counts() -> void:
	_fresh()
	Sim.stock = {RIG: 3, INGOT: 100}
	Sim.rig_wear = 0.3
	Sim.ops_cleared = 2
	Sim.ops_lifetime = 17
	Sim.salvage = 9
	Sim._sync_core()
	var board: Array = Sim.ops_board.duplicate(true)
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	_fresh()
	Sim.from_dict(d)
	runner.eq(Sim.rigs_home(), 3, "the Rigs at the Core")
	runner.near(Sim.rig_wear, 0.3, 0.0001, "their wear")
	runner.eq(Sim.ops_cleared, 2, "the sites cleared since the Core last grew")
	runner.eq(Sim.ops_lifetime, 17, "and in all, which sets the crew's room")
	runner.eq(Sim.crew_cap(), Operations.CREW_BASE + 1, "")
	runner.eq(Sim.salvage, 9, "the salvage")
	runner.eq(Sim.ops_board.size(), board.size(), "and the board, site by site")
	for i in range(board.size()):
		runner.eq(String(Sim.site(i).get("kind", "")), String((board[i] as Dictionary).get("kind", "")), "")
		runner.near(float(Sim.site(i).get("left", 0.0)), float((board[i] as Dictionary).get("left", 0.0)), 0.01, "")
	_done()


func test_what_now_points_at_a_site_the_crew_can_take_a_share_of() -> void:
	_fresh()
	Sim.stock = {RIG: 3, INGOT: 100}
	Sim._sync_core()
	for i in range(Sim.ops_board.size()):
		Sim.ops_board[i]["left"] = 1000.0
	Sim.ops_board[1]["left"] = 60.0
	var lines: Array = Worklist.of(Sim).filter(func(e: Dictionary) -> bool: return String(e["kind"]) == "sortie")
	runner.eq(lines.size(), 1, "no site is cleared at once, and What now? still points at one")
	runner.eq(int(lines[0]["i"]), 1, "the one the crew takes the most of")
	runner.check(bool(lines[0]["share"]), "for a share")
	runner.near(float(lines[0]["part"]), 0.5, 0.001, "half of it")
	Sim.ops_board[1]["left"] = 1000.0
	lines = Worklist.of(Sim).filter(func(e: Dictionary) -> bool: return String(e["kind"]) == "sortie")
	runner.eq(lines.size(), 0, "nothing it takes a third of: no line")
	_done()
