extends RefCounted

## After Core 7 (docs/PROGRESSION.md, "After Core 7"): the deep chain made on
## jobs (MachineDB.JOBS) -- Crystal from deep rock, Alloy at white heat,
## Frames -- and what it connects to; the doctrines (Economy.DOCTRINES); the
## Core's foundation a collapse keeps; blueprints saved, checked and laid.

var runner: Object


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
	Sim.overdrive = {}
	Sim.stock = {}
	Sim.core_online = true
	Sim.unlocked.clear()
	Sim.best_core = 1
	Sim.doctrine = ""
	Sim.blueprints = []
	Sim.blueprint_pending = []
	Sim._recompute()


func _done() -> void:
	_fresh()
	Save.wipe()


## A shaft at Core `core`, on stratum `depth`, with every machine found.
func _shaft(core: int, depth: int) -> void:
	_fresh()
	Sim.core_level = core
	Sim.depth = depth
	Sim.max_depth = depth
	for id: String in MachineDB.ORDER:
		Sim.unlocked.append(id)
	Sim._recompute()


## One machine on plain rock at stratum `depth`, at level 1, run for
## `seconds`: {"sim", "grid", "cell"}.
func _alone(id: String, job: String, depth: int, neighbours: Array = []) -> Dictionary:
	var g := Grid.new()
	var s := Simulation.new(g, 3)
	Strata.apply(s, g, Strata._describe(depth, [] as Array[String]), {})
	var cell: int = Grid.idx(20, 20)
	g.place(cell, id)
	g.set_job(cell, job)
	for n: Array in neighbours:
		var c: int = Grid.idx(20 + int(n[0]), 20 + int(n[1]))
		g.place(c, String(n[2]))
		if n.size() > 3:
			g.set_job(c, String(n[3]))
	return {"sim": s, "grid": g, "cell": cell}


## --- jobs --------------------------------------------------------------------------

func test_a_job_is_kept_with_its_tile_through_a_move_and_a_save() -> void:
	var g := Grid.new()
	var a: int = Grid.idx(10, 10)
	g.place(a, "smelter")
	runner.eq(g.job_at(a), "", "a machine starts on its own recipe")
	runner.check(not g.set_job(a, "crystal"), "a job another machine has is refused")
	runner.check(g.set_job(a, "alloy"), "its own job is taken")
	var b: int = Grid.idx(11, 10)
	runner.check(g.move(a, b), "")
	runner.eq(g.job_at(b), "alloy", "a move takes the job along")
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var g2 := Grid.new()
	g2.from_dict(d)
	runner.eq(g2.job_at(b), "alloy", "and a save keeps it")
	# A save from before jobs.
	d.erase("jobs")
	g2.from_dict(d)
	runner.eq(g2.job_at(b), "", "a save without jobs loads every machine on its own recipe")
	runner.check(g2.set_job(b, ""), "and a job goes back to the machine's own")


func test_a_job_changes_what_a_machine_takes_makes_and_how_hot_it_wants_to_be() -> void:
	var m: Dictionary = MachineDB.job_machine("smelter", "alloy")
	runner.eq(m["inputs"], {MachineDB.Res.CRYSTAL: 1}, "White Heat takes Crystal")
	runner.eq(m["outputs"], {MachineDB.Res.ALLOY: 1}, "and makes Alloy")
	runner.gt(float(m["heat_optimum"]), float(MachineDB.get_machine("smelter")["heat_optimum"]), "hotter than an Ingot wants")
	runner.eq(float(m["heat_out"]), float(MachineDB.get_machine("smelter")["heat_out"]), "but gives off the machine's own heat")
	runner.eq(MachineDB.job_machine("smelter", ""), MachineDB.get_machine("smelter"), "no job is the machine")
	runner.eq(MachineDB.makers_of(MachineDB.Res.ALLOY), [["smelter", "alloy"]], "")
	runner.eq(MachineDB.makers_of(MachineDB.Res.INGOT), [["smelter", ""]], "")
	runner.eq(CoreLevels.producer_of(MachineDB.Res.FRAME), "assembler", "")
	# Components two ways: Plates on the old chain, or Alloy at depth.
	runner.eq(MachineDB.makers_of(MachineDB.Res.COMPONENT), [["assembler", ""], ["assembler", "parts"]], "")
	runner.eq(CoreLevels.material_at(MachineDB.Res.COMPONENT), 3, "the old way still opens first")
	var parts: Dictionary = _alone("assembler", "parts", 19)
	var plain: Dictionary = _alone("assembler", "", 19)
	runner.check((plain["sim"] as Simulation).overheated_at(int(plain["cell"])), "on stratum 19 an Assembler on Plates chokes")
	runner.check(not (parts["sim"] as Simulation).overheated_at(int(parts["cell"])), "on Alloy Parts it does not")
	# Plates the same two ways, and a Plate is worth less than its Alloy:
	# rolling one is for the levels, not for income.
	runner.eq(MachineDB.makers_of(MachineDB.Res.PLATE), [["press", ""], ["press", "sheet"]], "")
	var sheet: Dictionary = _alone("press", "sheet", 19)
	var press: Dictionary = _alone("press", "", 19)
	runner.check((press["sim"] as Simulation).overheated_at(int(press["cell"])), "a Press on Ingots chokes on stratum 19")
	runner.check(not (sheet["sim"] as Simulation).overheated_at(int(sheet["cell"])), "on Alloy Sheet it does not")
	runner.lt(MachineDB.value_of(MachineDB.Res.PLATE), MachineDB.value_of(MachineDB.Res.ALLOY), "")
	runner.eq(CoreLevels.job_of(MachineDB.Res.CRYSTAL), "crystal", "")
	runner.check(MachineDB.recipe_text("smelter", "alloy").contains("Crystal"), "its recipe says so")


func test_the_shaft_opens_a_job_where_its_rock_and_its_core_say() -> void:
	_shaft(7, 15)
	var cell: int = Grid.idx(30, 22)
	Sim.grid.place(cell, "drill")
	runner.eq(Sim.job_blocker(cell, "crystal"), "depth", "no crystal above stratum 16")
	Sim.max_depth = 16
	runner.check(Sim.set_job(cell, "crystal"), "at 16 a Drill bores for it")
	var asm: int = Grid.idx(30, 24)
	Sim.grid.place(asm, "assembler")
	runner.eq(Sim.job_blocker(asm, "frame"), "core", "Frames wait for the Core's level 8")
	Sim.core_level = 8
	runner.check(Sim.can_set_job(asm, "frame"), "")
	runner.eq(Sim.job_blocker(asm, "alloy"), "none", "an Assembler has no White Heat")
	runner.check(Sim.can_make(MachineDB.Res.ALLOY), "the shaft can make Alloy")
	_done()


## --- the deep chain on the rock -----------------------------------------------------------

func test_a_deep_bore_digs_nothing_above_the_crystal_and_more_the_deeper() -> void:
	runner.eq(Strata.vein(15), 0.0, "no vein above stratum 16")
	runner.near(Strata.vein(16), 1.0, 0.0001, "")
	runner.gt(Strata.vein(24), Strata.vein(19), "more crystal the deeper")
	var shallow: Dictionary = _alone("drill", "crystal", 15)
	runner.eq((shallow["sim"] as Simulation).effective_rate(int(shallow["cell"])), 0.0, "a Deep Bore at 15 is idle")
	var sold: Dictionary = _alone("drill", "crystal", 16, [[1, 0, "vault"]])
	runner.gt(float((sold["sim"] as Simulation).measure(5.0, 30.0)["credits_per_sec"]), 0.0,
		"at 16 a Vault beside it sells crystal")
	# How fast it digs, the rock's heat included.
	var r: Array = []
	for d in [16, 19, 24]:
		var a: Dictionary = _alone("drill", "crystal", d)
		r.append((a["sim"] as Simulation).effective_rate(int(a["cell"])))
	runner.gt(float(r[1]), float(r[0]), "it digs faster at 19")
	runner.gt(float(r[2]), float(r[1]), "and faster at 24")
	# It is built for hot rock: a plain Drill overheats where it does not.
	var drill: Dictionary = _alone("drill", "", 19)
	var bore: Dictionary = _alone("drill", "crystal", 19)
	runner.check((drill["sim"] as Simulation).overheated_at(int(drill["cell"])), "a plain Drill chokes on stratum 19")
	runner.check(not (bore["sim"] as Simulation).overheated_at(int(bore["cell"])), "a Deep Bore does not")


func test_white_heat_runs_faster_the_hotter_it_is_until_it_chokes() -> void:
	var o: float = 5.0
	var t: float = 9.0
	runner.near(MachineDB.drive_efficiency(o, o, t), 1.0, 0.0001, "at its optimum, full speed")
	runner.gt(MachineDB.drive_efficiency(7.0, o, t), MachineDB.drive_efficiency(6.0, o, t), "hotter is faster")
	runner.gt(MachineDB.drive_efficiency(t, o, t), 1.7, "up to its tolerance")
	runner.lt(MachineDB.drive_efficiency(t + 1.5, o, t), MachineDB.drive_efficiency(t, o, t) * 0.5,
		"and past it, it chokes hard")
	runner.near(MachineDB.drive_efficiency(0.0, o, t), MachineDB.COLD_FLOOR, 0.0001, "cold, it crawls")
	# On the board: the same Smelter, with and without a Boiler beside it.
	var plain: Dictionary = _alone("smelter", "alloy", 16)
	var fired: Dictionary = _alone("smelter", "alloy", 16, [[1, 0, "boiler"]])
	var e0: float = (plain["sim"] as Simulation).heat_efficiency_at(int(plain["cell"]))
	var e1: float = (fired["sim"] as Simulation).heat_efficiency_at(int(fired["cell"]))
	runner.gt(e1, e0, "a Boiler beside it makes it faster (%.2f -> %.2f)" % [e0, e1])
	var safe: Vector2 = MachineDB.safe_range("smelter", 0.0, "alloy")
	runner.near(safe.x, o * MachineDB.WORKING_EFFICIENCY, 0.0001, "its safe range starts where it counts as working")


func test_crystal_to_alloy_to_the_store_and_the_labs() -> void:
	# Deep Bore -> White Heat Smelter -> Vault, on stratum 19.
	var a: Dictionary = _alone("smelter", "alloy", 19, [[-1, 0, "drill", "crystal"], [1, 0, "vault"]])
	var s: Simulation = a["sim"]
	s.run_ticks(600)
	runner.gt(float(s.measure(0.0, 30.0)["credits_per_sec"]), 0.0, "the chain sells Alloy")
	var learns: Dictionary = MachineDB.get_machine("lab")["learns"]
	runner.gt(float(learns[MachineDB.Res.ALLOY]), float(learns[MachineDB.Res.COMPONENT]), "a Lab learns more from Alloy")
	runner.gt(float(learns[MachineDB.Res.FRAME]), float(learns[MachineDB.Res.ALLOY]), "and most from a Frame")
	runner.check(MachineDB.STOCKED.has(MachineDB.Res.ALLOY) and MachineDB.STOCKED.has(MachineDB.Res.FRAME),
		"the Core's store keeps both")
	runner.check(not MachineDB.STOCKED.has(MachineDB.Res.CRYSTAL), "not the raw crystal")
	# A machine level from 9 is paid in Alloy.
	runner.check((MachineDB.level_materials(MachineDB.DEEP_LEVEL_FROM) as Dictionary).has(MachineDB.Res.ALLOY),
		"level %d is paid in Alloy" % MachineDB.DEEP_LEVEL_FROM)
	runner.check(not (MachineDB.level_materials(MachineDB.DEEP_LEVEL_FROM - 1) as Dictionary).has(MachineDB.Res.ALLOY),
		"the level before is not")
	# Every new material ties into two existing systems or more.
	var c: int = MachineDB.Res.CRYSTAL
	runner.check(Strata.vein(19) > 0.0 and (MachineDB.job_machine("smelter", "alloy")["inputs"] as Dictionary).has(c),
		"Crystal: found by the strata, taken by a Smelter")
	var al: int = MachineDB.Res.ALLOY
	runner.check((MachineDB.job_machine("assembler", "frame")["inputs"] as Dictionary).has(al)
		and MachineDB.STOCKED.has(al) and learns.has(al), "Alloy: Frames, the store, the Labs, machine levels")
	var fr: int = MachineDB.Res.FRAME
	runner.check(MachineDB.STOCKED.has(fr) and learns.has(fr)
		and not CoreLevels.requirements(9).filter(func(r: Array) -> bool:
			return int(r[0]) == CoreLevels.Req.STOCK and int(r[1]) == fr).is_empty(),
		"Frames: the store, the Labs, the Core's level 9")


func test_the_store_the_contracts_and_what_the_core_opens_know_the_deep_chain() -> void:
	runner.eq(CoreLevels.material_at(MachineDB.Res.CRYSTAL), 7, "Crystal with Core 7's strata")
	runner.eq(CoreLevels.material_at(MachineDB.Res.ALLOY), 7, "Alloy too")
	runner.eq(CoreLevels.material_at(MachineDB.Res.FRAME), MachineDB.FRAME_CORE, "Frames with Core 8")
	runner.eq(CoreLevels.material_at(MachineDB.Res.COMPONENT), 3, "an old material as it was")
	var o7: Dictionary = CoreLevels.opens(7)
	runner.check((o7["materials"] as Array).has(MachineDB.Res.ALLOY), "Core 7 opens Alloy")
	runner.check((o7["jobs"] as Array).has(["smelter", "alloy"]), "and White Heat")
	runner.check(bool(o7["doctrine"]), "and the doctrines")
	runner.check((CoreLevels.opens(8)["jobs"] as Array).has(["assembler", "frame"]), "Core 8 opens the Frame Jig")
	var all: Array = MachineDB.unlocked_at(30)
	runner.check(not Dispatch.reachable(all, 15, 7).has(MachineDB.Res.ALLOY), "no Alloy contract above the crystal")
	runner.check(Dispatch.reachable(all, 16, 7).has(MachineDB.Res.ALLOY), "one below it")
	runner.check(not Dispatch.reachable(all, 20, 7).has(MachineDB.Res.FRAME), "no Frame contract before Core 8")
	runner.check(Dispatch.reachable(all, 20, 8).has(MachineDB.Res.FRAME), "")
	runner.eq(CoreLevels.validate(40), [], "forty Core levels, the deep chain's rows among them, are sound")


## --- doctrines -------------------------------------------------------------------------

func test_a_doctrine_is_chosen_once_from_core_7_and_only_its_lines_count() -> void:
	_shaft(6, 12)
	runner.check(not Sim.choose_doctrine("deep"), "not before Core 7")
	Sim.core_level = 7
	Sim._recompute()
	runner.check(Sim.choose_doctrine("thermal"), "at Core 7")
	runner.check(not Sim.choose_doctrine("deep"), "once a shaft")
	Sim.research = 1.0e9
	runner.check(not Sim.can_buy_upgrade("vein_1"), "another doctrine's line is not for sale")
	runner.check(Sim.buy_upgrade("mass_1"), "its own is")
	runner.near(Sim.sim.tolerance_bonus, 0.4, 0.0001, "and counts")
	runner.eq(Sim.doctrine_levels(), 1, "")
	# The same levels in a shaft that follows another doctrine count for nothing.
	var mu: Dictionary = Economy.multipliers({"mass_1": 3, "vein_1": 2}, "deep")
	runner.near(float(mu["tolerance"]), 0.0, 0.0001, "Thermal Mass is nothing to the Deep Survey")
	runner.near(float(mu["vein"]), 1.4, 0.0001, "Crystal Lattice counts")
	# Cryo Lines make every cooler cool harder.
	Sim.upgrade_levels["cryo_1"] = 2
	Sim._recompute()
	runner.near(float(Sim.grid.heat_scale.get("coolant", 1.0)), 1.3, 0.0001, "Cryo Lines 2: 30% more cold")
	# A collapse keeps the levels and clears the choice.
	Sim.max_depth = 19
	Sim.lifetime_credits = 1.0e9
	runner.check(Sim.collapse() > 0, "a collapse")
	runner.eq(Sim.doctrine, "", "the next shaft chooses again")
	runner.eq(Sim.upgrade_level("mass_1"), 0, "and pays for its doctrine again: the research was the shaft's")
	runner.eq(Sim.upgrade_level("cryo_1"), 0, "")
	runner.near(Sim.sim.tolerance_bonus, 0.0, 0.0001, "")
	_done()


func test_the_doctrine_row_asks_for_a_strategy_not_for_one_line() -> void:
	_shaft(7, 19)
	var row: Dictionary = {}
	for st: Dictionary in Sim.core_status():
		if int(st["req"][0]) == CoreLevels.Req.DOCTRINE:
			row = st
	runner.check(not row.is_empty(), "Core 8 asks for a doctrine")
	runner.eq(float(row["have"]), 0.0, "none chosen, none met")
	for d: String in Economy.DOCTRINE_ORDER:
		_shaft(7, 19)
		Sim.choose_doctrine(d)
		for id: String in Economy.DOCTRINES[d]["lines"]:
			Sim.upgrade_levels[id] = 2
		for st: Dictionary in Sim.core_status():
			if int(st["req"][0]) == CoreLevels.Req.DOCTRINE:
				runner.check(bool(st["met"]), "any doctrine meets it: %s" % d)
	runner.eq(CoreLevels.doctrine_cap(6), 0, "no doctrine before Core 7")
	runner.eq(CoreLevels.doctrine_cap(7), 4, "two lines, two levels each, at Core 7")
	runner.eq(CoreLevels.doctrine_at(5), 8, "five levels wait for Core 8")
	_done()


func test_survey_charges_make_the_way_down_cheaper() -> void:
	_shaft(7, 17)
	var q: float = Sim.quota()
	Sim.choose_doctrine("deep")
	Sim.upgrade_levels["survey_1"] = 2
	Sim._recompute()
	runner.near(Sim.quota(), q * (1.0 - 2.0 * 0.08), 0.01, "two levels: 16% off")
	_done()


## --- the Core's foundation ---------------------------------------------------------------

func test_a_collapse_keeps_half_the_best_core_and_saves_carry_it() -> void:
	_shaft(8, 20)
	Sim.lifetime_credits = 1.0e9
	runner.eq(Sim.foundation(), 4, "a Core at 8 founds the next at 4")
	runner.check(Sim.collapse() > 0, "")
	runner.eq(Sim.core_level, 4, "the new shaft's Core is at 4")
	runner.eq(Sim.best_core, 8, "the best is remembered")
	runner.eq(Sim.depth_cap(), CoreLevels.depth_cap(4), "and so is its reach")
	runner.eq(Sim.machine_levels, {}, "its machines start at level 1")
	runner.eq(Sim.stock, {}, "and its store empty")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.best_core = 1
	Sim.from_dict(d)
	runner.eq(Sim.best_core, 8, "a save keeps it")
	# A collapse from a lower Core does not lower the foundation.
	Sim.max_depth = 9
	Sim.lifetime_credits = 1.0e9
	Sim.collapse()
	runner.eq(Sim.core_level, 4, "a weaker shaft does not take it back")
	# A save from before the foundation: the best is the Core it has.
	d.erase("best_core")
	d["core_level"] = 6
	Sim.from_dict(d)
	runner.eq(Sim.best_core, 6, "an old save's best is its own Core")
	runner.eq(Sim.doctrine, "", "and it follows no doctrine")
	_done()


## --- blueprints ------------------------------------------------------------------------

func test_a_blueprint_is_saved_checked_and_laid_as_credits_allow() -> void:
	_shaft(7, 17)
	Sim.credits = 1.0e9
	var line: Array = [[16, 19, "drill", ""], [17, 19, "crusher", ""], [18, 19, "vault", ""],
		[16, 21, "drill", "crystal"], [17, 21, "smelter", "alloy"], [18, 21, "vault", ""]]
	for e: Array in line:
		var c: int = Grid.idx(int(e[0]), int(e[1]))
		runner.check(Sim.try_place(c, String(e[2])), "placed %s" % str(e))
		if String(e[3]) != "":
			Sim.set_job(c, String(e[3]))
	Sim.set_mode(Grid.idx(17, 19), MachineDB.Mode.HOT)
	runner.eq(Sim.blueprint_slots(), 1 + Store.bonus_blueprint_slots(), "one slot to start with")
	runner.check(Sim.save_blueprint(0), "the board is saved")
	runner.check(not Sim.save_blueprint(Sim.blueprint_slots()), "not into a slot it does not have")
	var bp: Dictionary = Sim.blueprint(0)
	runner.eq((bp["cells"] as Array).size(), line.size(), "every machine")
	runner.eq(int(bp["core"]), 7, "and the Core it was saved at")
	# Laid on itself it all stands -- and the plain Drill, which stratum
	# 17's rock overheats, is flagged as it stands.
	var own: Dictionary = Sim.blueprint_report(0)["why"]
	runner.eq(int(own.get("placed", 0)) + int(own.get("hot", 0)) + int(own.get("cold", 0)), line.size(),
		"laid on itself, all of it stands: %s" % str(own))
	runner.gte(float(own.get("hot", 0)), 1.0, "and what the rock overheats is flagged")
	# A collapse keeps it; the new shaft's ground is small and new.
	Sim.max_depth = 19
	Sim.lifetime_credits = 1.0e9
	Sim.collapse()
	runner.eq((Sim.blueprint(0)["cells"] as Array).size(), line.size(), "a collapse keeps the blueprint")
	Sim.power_core()
	var rep: Dictionary = Sim.blueprint_report(0)
	var why: Dictionary = rep["why"]
	runner.gt(float(why.get("locked", 0)) + float(why.get("outside", 0)), 0.0,
		"on a new shaft it finds machines not found and ground not reached: %s" % str(why))
	# Every machine found, the yard grown, a little money: laid in order.
	for id: String in MachineDB.ORDER:
		if not Sim.unlocked.has(id):
			Sim.unlocked.append(id)
	Sim.max_depth = 17
	Sim.depth = 17
	Sim._recompute()
	# Credits for a Vault and a Smelter: a line is laid from its end, a
	# seller with the maker that feeds it, so what goes down first earns.
	Sim.credits = MachineDB.cost_for("vault", 0) + MachineDB.cost_for("crusher", 0)
	var laid: Dictionary = Sim.lay_blueprint(0)
	runner.check(not laid.is_empty(), "")
	runner.eq(Sim.grid.cells.size(), 2, "it puts down what the credits buy: a seller and what feeds it")
	runner.eq(Sim.grid.machine_at(Grid.idx(18, 19)), "vault", "the line's end first")
	runner.eq(Sim.grid.machine_at(Grid.idx(17, 19)), "crusher", "and the maker beside it")
	runner.eq(Sim.blueprint_pending.size(), line.size() - 2, "the rest waits")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.blueprint_pending = []
	Sim.from_dict(d)
	runner.eq(Sim.blueprint_pending.size(), line.size() - 2, "a save keeps what is waiting")
	Sim.credits = 1.0e9
	Sim.fill_pending()
	runner.eq(Sim.grid.cells.size(), line.size(), "credits in hand, the rest goes down")
	runner.eq(Sim.grid.job_at(Grid.idx(17, 21)), "alloy", "on its job")
	runner.eq(Sim.grid.mode_at(Grid.idx(17, 19)), MachineDB.Mode.HOT, "in its mode")
	runner.check(Sim.blueprint_pending.is_empty(), "and nothing waits")
	_done()


func test_a_blueprint_flags_what_would_overheat_or_is_in_the_way() -> void:
	_shaft(7, 19)
	Sim.credits = 1.0e9
	# A Press between two Boilers overheats on any rock; saved, it says so.
	var p: int = Grid.idx(17, 20)
	runner.check(Sim.try_place(p, "press"), "")
	runner.check(Sim.try_place(Grid.idx(16, 20), "boiler"), "")
	runner.check(Sim.try_place(Grid.idx(18, 20), "boiler"), "")
	Sim.save_blueprint(0)
	var rep: Dictionary = Sim.blueprint_report(0)
	var hot: Array = (rep["cells"] as Array).filter(func(e: Dictionary) -> bool: return String(e["why"]) == "hot")
	runner.eq(hot.size(), 1, "the Press would overheat")
	runner.eq(int(hot[0]["cell"]), p, "and it is the Press")
	# Something else standing on a blueprint's tile: taken, and left alone.
	Sim.grid.clear()
	Sim._recompute()
	Sim.try_place(p, "vault")
	rep = Sim.blueprint_report(0)
	runner.eq(int(rep["why"].get("taken", 0)), 1, "a tile another machine holds is taken")
	Sim.lay_blueprint(0)
	runner.eq(Sim.grid.machine_at(p), "vault", "and the Vault on it stays")
	runner.eq(Sim.blueprint_pending.size(), 3, "the Press waits for the tile, the Boilers for a maker to warm")
	runner.check(Sim.grid.machine_at(Grid.idx(16, 20)) == "", "a Boiler with nothing to warm is not laid")
	Sim.cancel_blueprint()
	runner.check(Sim.blueprint_pending.is_empty(), "until the player stops it")
	_done()
