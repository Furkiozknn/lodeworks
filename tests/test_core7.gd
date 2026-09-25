extends RefCounted

## The Factory Core's level 7 (docs/PROGRESSION.md, "Core 7"): a level the
## Core 6 era's factory reaches by growing -- its Component chain, its
## cooling, its store, its research, its stability -- not by saving for a
## price; what it opens (Overdrive); and what the level after it asks for.
##
## The Core 6 -> 7 tests play from tests/fixtures/core7_ready.json: the
## factory the scripted player (tools/core_journey_player.gd) had built the
## moment every row of level 7 was met, written by
##   LODEWORKS_CORE_SKIP=1 LODEWORKS_CORE_TARGET=7 \
##   LODEWORKS_CORE_DUMP=7:<file> godot --headless --path . \
##     --script res://tools/core_journey.gd
## A change to the economy that moves when those rows are met means writing
## it again from a new run.

const FIXTURE := "res://tests/fixtures/core7_ready.json"

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
	Sim._recompute()


func _done() -> void:
	_fresh()
	Save.wipe()


func _tick(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		var out: Dictionary = Sim.sim.tick()
		Sim._collect_stock()
		Sim.credits += float(out["credits"])
		Sim.research += float(out["research"])


## The played factory, ready for Core 7, running again. A save keeps no
## machine's part-done cycle, so the chains fill up again first; the
## stability row was met at its edge when the Core grew (80 of 80), and it
## is met again within minutes of the factory running.
func _ready_for_seven() -> Dictionary:
	_fresh()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	Sim.from_dict(d)
	Sim.sim.rng.seed = 7
	for _k in range(60):
		_tick(10.0)
		# The purse as it was at the moment; ticking only adds.
		Sim.credits = maxf(Sim.credits, float(d["credits"]))
		if Sim.can_upgrade_core():
			break
	return d


func _row(level: int, kind: int) -> Array:
	for r: Array in CoreLevels.requirements(level):
		if int(r[0]) == kind:
			return r
	return []


func _status(kind: int, id: Variant = null) -> Dictionary:
	for st: Dictionary in Sim.core_status():
		var r: Array = st["req"]
		if int(r[0]) == kind and (id == null or r[1] == id):
			return st
	return {}


## Does `r`, asked by Core `level`, ask for work the era before it (under
## Core `level` - 1) has to do? A store, a machine level, a research level,
## a stratum or an Overdrive step past what the Core two levels down already
## allowed; or a count of machines working, serving or stable past anything
## an earlier level asked. A row the factory already had is not a row.
func _new_work(level: int, r: Array) -> bool:
	var before: int = level - 2
	match int(r[0]):
		CoreLevels.Req.CREDITS:
			return true
		CoreLevels.Req.STOCK:
			return int(r[2]) > MachineDB.stock_cap(CoreLevels.machine_cap(before))
		CoreLevels.Req.MACHINE:
			return int(r[2]) > CoreLevels.machine_cap(before)
		CoreLevels.Req.RESEARCH:
			return int(r[2]) > Economy.research_cap(String(r[1]), before)
		CoreLevels.Req.DEPTH:
			return int(r[1]) > CoreLevels.depth_cap(before)
		CoreLevels.Req.OVERDRIVE:
			return int(r[2]) > CoreLevels.overdrive_cap(before)
	var most: int = -1
	for l in range(2, level):
		for e: Array in CoreLevels.requirements(l):
			if int(e[0]) != int(r[0]):
				continue
			if int(r[0]) == CoreLevels.Req.STABLE:
				most = maxi(most, int(e[1]))
			elif String(e[1]) == String(r[1]):
				most = maxi(most, int(e[2]))
	var need: int = int(r[1]) if int(r[0]) == CoreLevels.Req.STABLE else int(r[2])
	return need > most


## --- the graph ------------------------------------------------------------------

func test_every_row_of_core_7_is_work_the_core_6_era_does() -> void:
	var kinds: Dictionary = {}
	for r: Array in CoreLevels.requirements(7):
		kinds[int(r[0])] = true
		runner.check(_new_work(7, r), "Core 7's row %s asks for something the Core 6 era must build" % str(r))
	# Credits, the store, machine levels, research, a support machine,
	# stability and depth: seven systems, not a price with a list.
	runner.gte(float(kinds.size()), 7.0, "Core 7 asks seven kinds of thing")
	# What the old table asked was not: Deeper Bore 6 had been allowed since
	# Core 4, and was met five seconds into the stage it was meant to gate.
	runner.check(not _new_work(7, [CoreLevels.Req.RESEARCH, "yield_1", 6]),
		"a research level the Core 5 era already allowed is not a Core 7 row")
	for r: Array in CoreLevels.requirements(8):
		runner.check(_new_work(8, r), "Core 8's row %s is work for the Core 7 era" % str(r))


func test_the_checker_catches_broken_overdrive_and_resonance_rows() -> void:
	var c: int = CoreLevels.Req.CREDITS
	var d: int = CoreLevels.Req.DEPTH
	var od: int = CoreLevels.Req.OVERDRIVE
	var has := func(errors: Array[String], what: String) -> bool:
		return errors.any(func(e: String) -> bool: return e.contains(what))
	# A cycle: Overdrive is opened by Core 7, so Core 7 cannot ask for it.
	runner.check(has.call(CoreLevels.problems(7, [[c, 1.0], [od, "assembler", 1], [d, 15]]),
		"first becomes possible at level 7"), "Core 7 asking for Overdrive would need itself")
	runner.check(has.call(CoreLevels.problems(8, [[c, 1.0], [od, "assembler", 4], [d, 19]]),
		"first becomes possible at level 8"), "and Core 8 asking for Core 8's own steps")
	# Never: the Vault's level is storage, an Amplifier has no level, a
	# machine that does not exist.
	var never: Array[String] = CoreLevels.problems(8, [[c, 1.0], [od, "vault", 1],
		[od, "amplifier", 1], [od, "nothing", 1], [d, 19]])
	runner.eq(never.filter(func(e: String) -> bool: return e.contains("never")).size(), 3,
		"what cannot be driven can never be asked for")
	# Resonant Frames opens at Core 6 and goes two levels a Core level.
	runner.check(has.call(CoreLevels.problems(6, [[c, 1.0], [CoreLevels.Req.RESEARCH, "resonance", 1], [d, 12]]),
		"first becomes possible at level 6"), "Core 6 cannot ask for the line it opens")
	runner.check(has.call(CoreLevels.problems(7, [[c, 1.0], [CoreLevels.Req.RESEARCH, "resonance", 3], [d, 15]]),
		"first becomes possible at level 7"), "nor Core 7 for a level only Core 7 allows")
	runner.eq(CoreLevels.problems(7, CoreLevels.requirements(7)), [], "Core 7 as written is sound")
	runner.eq(CoreLevels.problems(8, CoreLevels.requirements(8)), [], "and so is Core 8")


func test_no_level_is_unreachable_and_every_overdrive_step_fits_its_store() -> void:
	runner.eq(CoreLevels.validate(40), [], "forty levels, Overdrive's steps included")
	for level in range(MachineDB.OVERDRIVE_CORE, 41):
		var last: int = CoreLevels.overdrive_cap(level)
		var cost: Dictionary = MachineDB.overdrive_cost(last)
		for res: int in (cost["materials"] as Dictionary):
			runner.lte(float(cost["materials"][res]), float(MachineDB.stock_cap(CoreLevels.machine_cap(level))),
				"Core %d's last Overdrive step fits a store at its Vault limit" % level)
		for r: Array in CoreLevels.requirements(level):
			var at: int = CoreLevels.available_at(r)
			runner.check(at >= 1 and at < level, "Core %d's %s is possible by Core %d" % [level, str(r), at])
	runner.eq(CoreLevels.overdrive_cap(6), 0, "no Overdrive before Core 7")
	runner.eq(CoreLevels.overdrive_cap(7), MachineDB.OVERDRIVE_PER_CORE, "")


## --- what Core 7 opens, and what comes after it ----------------------------------------

func test_core_7_opens_overdrive_and_the_rock_below() -> void:
	var o: Dictionary = CoreLevels.opens(7)
	runner.eq(o["strata"], [16, 19], "strata 16 to 19")
	runner.eq(int(o["machine_cap"]), 8, "machine level 8")
	runner.eq(int(o["overdrive"]), MachineDB.OVERDRIVE_PER_CORE, "and Overdrive, three steps")
	runner.eq(int(CoreLevels.opens(6)["overdrive"]), 0, "Core 6 opens none")
	runner.eq(CoreLevels.opens(6)["research"], ["resonance"], "Core 6 opens Resonant Frames")
	runner.eq(Economy.research_cap("resonance", 7), 4, "Core 7 lets it go to its end")


func test_the_level_after_core_7_asks_for_what_core_7_opened() -> void:
	var od: Array = _row(8, CoreLevels.Req.OVERDRIVE)
	runner.check(not od.is_empty(), "Core 8 asks for Overdrive steps")
	runner.eq(CoreLevels.available_at(od), 7, "which Core 7 first makes possible")
	var res: Array = []
	for r: Array in CoreLevels.requirements(8):
		if int(r[0]) == CoreLevels.Req.RESEARCH:
			res = r
	runner.eq(res, [CoreLevels.Req.RESEARCH, "resonance", 4], "and Resonant Frames' last levels")
	var o: Dictionary = CoreLevels.opens(8)
	runner.eq(int(o["overdrive"]), MachineDB.OVERDRIVE_PER_CORE, "Core 8 opens three more steps")
	runner.eq(CoreLevels.overdrive_from(8), CoreLevels.machine_cap(7), "for types at Core 7's limit")
	# Every level past the table keeps asking for a step of Overdrive.
	for level in range(9, 14):
		runner.check(not _row(level, CoreLevels.Req.OVERDRIVE).is_empty(), "Core %d asks for Overdrive" % level)


## --- machine levels past 6, Overdrive and Resonant Frames in play ----------------------

func test_machine_levels_past_six_grow_at_the_late_rate() -> void:
	var p6: float = MachineDB.level_price("smelter", 6)
	runner.near(p6, MachineDB.LEVEL_PRICE * pow(MachineDB.LEVEL_PRICE_GROWTH, 4.0), 0.5,
		"levels up to 6 are priced as they were")
	runner.near(MachineDB.level_price("smelter", 7), p6 * MachineDB.LATE_LEVEL_GROWTH, 0.5, "")
	runner.near(MachineDB.level_price("smelter", 8), p6 * pow(MachineDB.LATE_LEVEL_GROWTH, 2.0), 0.5, "")


func test_overdrive_is_paid_in_store_and_research_and_drives_speed_and_heat() -> void:
	_fresh()
	Sim.core_level = 6
	Sim.depth = 15
	Sim.max_depth = 15
	Sim.machine_levels = {"assembler": 7, "vault": 7, "smelter": 6}
	Sim._recompute()
	runner.eq(Sim.overdrive_blocker("assembler"), "core", "a Core 6 shaft cannot drive")
	Sim.core_level = 7
	Sim._recompute()
	runner.eq(Sim.overdrive_blocker("vault"), "none", "the Vault's level is storage")
	runner.eq(Sim.overdrive_blocker("amplifier"), "none", "an Amplifier has no level")
	runner.eq(Sim.overdrive_blocker("smelter"), "level", "a type short of Core 6's limit comes first")
	runner.eq(Sim.overdrive_blocker("assembler"), "stock", "the store is empty")
	var cost: Dictionary = Sim.overdrive_cost("assembler")
	Sim.stock = (cost["materials"] as Dictionary).duplicate()
	runner.eq(Sim.overdrive_blocker("assembler"), "research", "and so are the Labs' books")
	Sim.research = float(cost["research"]) + 5.0
	Sim.credits = 0.0
	var speed: float = float(Sim.sim.level_mult["assembler"])
	var heat: float = float(Sim.grid.heat_scale["assembler"])
	runner.check(Sim.overdrive_machine("assembler"), "it drives with no credits at all")
	runner.eq(Sim.overdrive_steps("assembler"), 1, "")
	runner.near(Sim.research, 5.0, 0.001, "its research is paid")
	runner.eq(Sim.stock_of(MachineDB.Res.INGOT), 0, "and its Ingots and Plates")
	runner.near(float(Sim.sim.level_mult["assembler"]) - speed,
		MachineDB.LEVEL_SPEED * MachineDB.OVERDRIVE_STEP, 0.0001, "half a level faster")
	runner.near(float(Sim.grid.heat_scale["assembler"]) - heat,
		MachineDB.HEAT_PER_LEVEL * MachineDB.OVERDRIVE_STEP, 0.0001, "and half a level's heat hotter")
	Sim.overdrive = {"assembler": CoreLevels.overdrive_cap(7)}
	runner.eq(Sim.overdrive_blocker("assembler"), "core", "three steps is Core 7's limit")
	_done()


func test_a_coolant_cells_overdrive_is_strength() -> void:
	runner.near(MachineDB.heat_factor("coolant", 7, 2) - MachineDB.heat_factor("coolant", 7),
		MachineDB.SUPPORT_PER_LEVEL * MachineDB.OVERDRIVE_STEP * 2.0, 0.0001,
		"two steps on a Coolant Cell move a level's worth more heat")


func test_resonant_frames_strengthen_every_booster() -> void:
	# A Crusher with an Amplifier beside it, with and without the research.
	var run := func(level: int) -> Array:
		var g := Grid.new()
		var s := Simulation.new(g, 5)
		Strata.apply(s, g, Strata.describe(0), Economy.multipliers({"resonance": level}))
		g.place(Grid.idx(10, 10), "crusher")
		g.place(Grid.idx(11, 10), "amplifier")
		return [s.effective_rate(Grid.idx(10, 10)), g.amplify_at(Grid.idx(10, 10)) - 1.0, s.duplicate_mult]
	var plain: Array = run.call(0)
	var two: Array = run.call(2)
	var b: float = float(plain[1])
	runner.gt(b, 0.0, "the Amplifier boosts the Crusher")
	runner.near(float(two[0]) / float(plain[0]), (1.0 + 1.3 * b) / (1.0 + b), 0.0001,
		"Resonant Frames 2: 30% more of that boost")
	runner.near(float(two[2]), 1.3, 0.0001, "and of a Duplicator's chance")


## --- saves --------------------------------------------------------------------------

func test_overdrive_and_resonance_survive_a_save_and_a_collapse_keeps_only_the_tree() -> void:
	_fresh()
	Sim.core_level = 7
	Sim.machine_levels = {"assembler": 7, "coolant": 7}
	Sim.overdrive = {"assembler": 2, "coolant": 1}
	Sim.upgrade_levels = {"resonance": 2}
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.overdrive = {}
	Sim.upgrade_levels = {}
	Sim.from_dict(d)
	runner.eq(Sim.overdrive, {"assembler": 2, "coolant": 1}, "Overdrive comes back, keyed by type")
	runner.eq(Sim.upgrade_level("resonance"), 2, "and Resonant Frames")
	runner.near(float(Sim.sim.level_mult["assembler"]), MachineDB.level_speed(7, 2), 0.0001,
		"a loaded shaft runs its driven machines as driven")
	Sim.max_depth = 16
	Sim.lifetime_credits = 1.0e9
	runner.check(Sim.collapse() > 0, "a collapse")
	runner.eq(Sim.overdrive, {}, "a new shaft's machines are not driven")
	runner.eq(Sim.upgrade_level("resonance"), 2, "the research tree is kept, as every line is")
	_done()


func test_saves_from_before_core_7_changed_load_under_the_new_table() -> void:
	_fresh()
	# A shaft at Core 7 under the old table: machines to level 8, Deeper
	# Bore 6, no Overdrive, no Resonant Frames.
	var d: Dictionary = Sim.to_dict()
	d["core_level"] = 7
	d["depth"] = 17
	d["max_depth"] = 17
	d["machine_levels"] = {"assembler": 8, "smelter": 7, "vault": 7}
	d["upgrades"] = {"yield_1": 6, "throughput_1": 8}
	d.erase("overdrive")
	Sim.from_dict(JSON.parse_string(JSON.stringify(d)))
	runner.eq(Sim.core_level, 7, "its Core stays at 7")
	runner.eq(Sim.machine_level("assembler"), 8, "its levels stay")
	runner.eq(Sim.overdrive, {}, "it has no Overdrive yet")
	var od: Dictionary = _status(CoreLevels.Req.OVERDRIVE, "assembler")
	runner.check(not od.is_empty() and not bool(od["met"]), "and Core 8 now asks for it")
	runner.eq(Sim.overdrive_blocker("assembler"), "stock", "which it can start on at once: level 8 >= 7")
	# A Core 6 shaft meets the new Core 7 rows.
	d["core_level"] = 6
	d["depth"] = 13
	d["max_depth"] = 13
	Sim.from_dict(JSON.parse_string(JSON.stringify(d)))
	runner.check(not _status(CoreLevels.Req.RESEARCH, "resonance").is_empty(), "a Core 6 shaft is asked for Resonant Frames")
	runner.check(_status(CoreLevels.Req.RESEARCH, "yield_1").is_empty(), "not Deeper Bore 6")
	runner.near(float(_status(CoreLevels.Req.CREDITS)["need"]), 15.0e6, 1.0, "and 15M credits of its own, not 1B")
	# A save naming Overdrive on something that cannot be driven drops it.
	d["overdrive"] = {"vault": 2, "amplifier": 1, "press": 0, "smelter": 1}
	Sim.from_dict(JSON.parse_string(JSON.stringify(d)))
	runner.eq(Sim.overdrive, {"smelter": 1}, "only what can be driven is kept")
	_done()


## --- the Core 6 -> 7 journey, from the played factory ----------------------------------

func test_the_played_factory_meets_every_row_of_core_7() -> void:
	var d: Dictionary = _ready_for_seven()
	runner.eq(Sim.core_level, 6, "the fixture is a Core 6 shaft")
	for st: Dictionary in Sim.core_status():
		runner.check(bool(st["met"]), "met: %s (%.0f / %.0f)" % [str(st["req"]), float(st["have"]), float(st["need"])])
	runner.check(Sim.can_upgrade_core(), "so the Core can grow")
	runner.gt(float(d["journey_rate"]), 0.0, "the fixture carries its measured income")
	_done()


func test_each_row_of_core_7_blocks_it_on_its_own() -> void:
	var breaks: Array = [
		[CoreLevels.Req.CREDITS, func() -> void: Sim.credits = _price(7) - 1.0],
		[CoreLevels.Req.STOCK, func() -> void:
			Sim.stock[MachineDB.Res.COMPONENT] = 24999
			Sim._sync_core()],
		[CoreLevels.Req.MACHINE, func() -> void:
			Sim.machine_levels["assembler"] = 6
			Sim._recompute()],
		[CoreLevels.Req.RESEARCH, func() -> void: Sim.upgrade_levels["resonance"] = 1],
		[CoreLevels.Req.DEPTH, func() -> void: Sim.max_depth = 14],
		[CoreLevels.Req.SERVES, func() -> void:
			for cell: int in Sim.grid.cells.keys():
				if Sim.grid.machine_at(cell) == "condenser":
					Sim.grid.remove(cell)
			Sim._recompute()],
	]
	for b: Array in breaks:
		_ready_for_seven()
		(b[1] as Callable).call()
		var open: Array = Sim.core_status().filter(func(st: Dictionary) -> bool:
			return not bool(st["met"]) and int(st["req"][0]) == int(b[0]))
		runner.gte(float(open.size()), 1.0, "breaking %s leaves its row open" % str(b[0]))
		runner.check(not Sim.can_upgrade_core(), "and the Core does not grow")
	# Stability: one machine made to overheat.
	_ready_for_seven()
	var press: int = -1
	for cell: int in Sim.grid.cells:
		if Sim.grid.machine_at(cell) == "press":
			press = cell
			break
	for n: int in Sim.grid.neighbours(press):
		Sim.grid.remove(n)
		Sim.grid.place(n, "boiler")
	Sim._recompute()
	_tick(10.0)
	runner.eq(CoreLevels.stable(Sim), 0, "a Press between Boilers breaks stability")
	runner.check(not Sim.can_upgrade_core(), "so the Core does not grow")
	_done()


func test_growing_to_core_7_opens_overdrive_on_the_played_factory() -> void:
	_ready_for_seven()
	var credits: float = Sim.credits
	runner.check(Sim.upgrade_core(), "the Core grows")
	runner.eq(Sim.core_level, 7, "")
	runner.near(Sim.credits, credits - _price(7), 1.0, "its credits are paid")
	runner.eq(Sim.depth_cap(), 19, "the shaft may go to 19")
	runner.eq(Sim.overdrive_cap(), 3, "and Overdrive is open")
	# The Assemblers the Core asked for are at level 7: the first to drive.
	runner.check(Sim.overdrive_blocker("assembler") in ["", "stock", "research"],
		"the Assemblers can be driven as soon as the store and the Labs pay")
	var next: Array = Sim.core_status()
	runner.check(next.any(func(st: Dictionary) -> bool: return int(st["req"][0]) == CoreLevels.Req.OVERDRIVE),
		"the next level asks for Overdrive")
	var items: Array = Worklist.of(Sim)
	runner.check(items.any(func(e: Dictionary) -> bool:
		return String(e["kind"]) == "overdrive" or String(e["kind"]) == "core_need" or String(e["kind"]) == "upgrade"),
		"and What now? has a Core 7 line to offer")
	_done()


func test_core_7_is_hours_of_the_played_income_not_days() -> void:
	var d: Dictionary = _ready_for_seven()
	var rate: float = float(d["journey_rate"])
	runner.gt(rate, 0.0, "")
	# The Core's own price, and the machine levels it asks for, in hours of
	# the income the played Core 6 factory earned.
	var levels: float = 0.0
	for r: Array in CoreLevels.requirements(7):
		if int(r[0]) == CoreLevels.Req.MACHINE:
			levels += MachineDB.level_price(String(r[1]), int(r[2]))
	levels += MachineDB.level_price("vault", CoreLevels.storage_level(25000))
	var hours: float = (_price(7) + levels) / rate / 3600.0
	runner.lt(hours, 8.0, "Core 7's credits and the levels it asks are %.1f h of the played income" % hours)
	runner.gt(hours, 1.0, "and still a long goal, not a formality")
	_done()


func _price(level: int) -> float:
	for r: Array in CoreLevels.requirements(level):
		if int(r[0]) == CoreLevels.Req.CREDITS:
			return float(r[1])
	return 0.0


## --- a fresh game, played -----------------------------------------------------------

func test_a_fresh_game_played_reaches_core_3_in_twenty_minutes() -> void:
	var P: RefCounted = load("res://tools/core_journey_player.gd").new(Sim)
	P.fresh()
	while P.t < 1200.0:
		P.advance(P.BEAT)
		P.act()
	runner.gte(float(Sim.core_level), 3.0, "the scripted player reaches Core 3 by 20 minutes (Core %d)" % Sim.core_level)
	runner.gte(float(Sim.max_depth), 4.0, "and the strata it opens")
	_done()
