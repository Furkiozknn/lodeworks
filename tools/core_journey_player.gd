extends RefCounted

## A competent player chasing the Factory Core, playing the real `Sim`
## (tools/core_journey.gd runs it and prints what it measured).
##
## It is a model, and it says what it does: every beat it grows the Core
## when it can, goes down when it can, buys the research and machine levels
## the Core's next level asks for, works through the Core's open rows --
## a chain into the Core's store for a material, a Vault level for a store
## too small, a Boiler or a Coolant Cell for a machine off its heat, a Lab
## for research -- and spends what is left on "What now?" (Worklist), the
## same list the player sees. It keeps the Core's right and front sides for
## the machines that feed the store. It never uses a number the player
## cannot see.
##
## From the Core's level 7 it follows a doctrine (DOCTRINE, or
## LODEWORKS_CORE_DOCTRINE) and, once the shaft reaches the crystal of
## stratum MachineDB.CRYSTAL_DEPTH, grows the factory with the deep chain:
## Deep Bores feeding White Heat Smelters, each with a Vault, on free ground
## away from the Core (`_build_deep`), and an Alloy line into the store when
## the Core asks for it.

const BEAT := 5.0

## The lines a player lays out for each Core level, feeders first, as a
## player who has read the Core's next level builds them: the machines that
## fill the store touching the Core, their feeders behind them, heat and
## cold beside them, an outlet for when the store is full.
## Level 1, the right side: two Smelters with their Boilers, Crushers and
## Drills, a Vault between them, a Lab behind the upper Boiler.
## Level 2, the front: two Presses fed through Coolant Cells by Smelters
## that share a Boiler, their Crushers and Drills, a Vault between the
## Presses and Coolant on their outer sides.
## Level 3, the left side and the back: three Assemblers, each fed by a
## Press between Coolant Cells, a Smelter with a Boiler, a Crusher and
## Drills; Coolant beside the Assemblers, and a Vault beside each for when
## the store is full.
## Each is started once its Core level is reached and its maker found
## (`from`, a stratum); past these the player works from the Core's rows
## and "What now?" alone.
const PLANS := [
	{"core": 1, "from": 1, "cells": [
		[26, 21, "drill"], [25, 20, "drill"], [25, 21, "crusher"], [24, 21, "smelter"],
		[24, 20, "boiler"], [24, 22, "vault"], [24, 19, "lab"],
		[26, 23, "drill"], [25, 24, "drill"], [25, 23, "crusher"], [24, 23, "smelter"],
		[24, 24, "boiler"],
	]},
	{"core": 2, "from": 3, "cells": [
		[19, 27, "drill"], [21, 27, "drill"], [20, 27, "crusher"], [20, 26, "smelter"],
		[21, 26, "boiler"], [20, 25, "coolant"], [19, 24, "coolant"], [20, 24, "press"],
		[21, 24, "vault"],
		[23, 27, "drill"], [22, 27, "crusher"], [22, 26, "smelter"], [22, 25, "coolant"],
		[23, 24, "coolant"], [22, 24, "press"],
	]},
	{"core": 3, "from": 5, "cells": [
		[16, 19, "drill"], [16, 21, "drill"], [16, 20, "crusher"], [17, 20, "smelter"],
		[17, 21, "boiler"], [18, 19, "coolant"], [18, 21, "coolant"], [18, 20, "press"],
		[19, 21, "coolant"], [19, 20, "assembler"], [19, 19, "vault"],
		[16, 23, "drill"], [16, 22, "crusher"], [17, 22, "smelter"], [18, 23, "coolant"],
		[18, 22, "press"], [19, 22, "assembler"], [19, 23, "vault"],
		[20, 16, "drill"], [22, 16, "drill"], [21, 16, "crusher"], [21, 17, "smelter"],
		[22, 17, "boiler"], [20, 18, "coolant"], [22, 18, "coolant"], [21, 18, "press"],
		[20, 19, "coolant"], [21, 19, "assembler"], [22, 19, "vault"],
	]},
]

var S: Node
var t: float = 0.0
## The doctrine this player follows from the Core's level 7.
var doctrine: String = "deep"
## [seconds, what] for every first: a Core level, a stratum, a machine type
## built, a machine level, a research level.
var events: Array = []
var _seen: Dictionary = {}


func _init(sim: Node) -> void:
	S = sim


## A new game, as a player starts one: an empty save, the Core brought online.
func fresh() -> void:
	Save.wipe()
	S._ensure()
	S.grid.clear()
	S.sim.reset_progress()
	S.credits = 0.0
	S.research = 0.0
	S.cores = 0
	S.depth = 0
	S.max_depth = 0
	S.lifetime_credits = 0.0
	S.collapses = 0
	S.upgrade_levels = {}
	S.core_level = 1
	S.machine_levels = {}
	S.overdrive = {}
	S.stock = {}
	S.core_online = false
	S.unlocked.clear()
	S.best_core = 1
	S.doctrine = ""
	S.blueprints = []
	S.blueprint_pending = []
	S._recompute()
	S.power_core()


## Play `seconds` of real time at the real tick rate.
func advance(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		var out: Dictionary = S.sim.tick()
		S._collect_stock()
		var c: float = float(out["credits"])
		S.credits += c
		S.lifetime_credits += c
		S.research += float(out["research"])
		t += Simulation.TICK_DT


func _event(key: String, what: String) -> void:
	if shaft > 1:
		key = "s%d:%s" % [shaft, key]
		what = "shaft %d: %s" % [shaft, what]
	if _seen.has(key):
		return
	_seen[key] = true
	events.append([t, what])


## The shaft this player is on: 1, then one more after each collapse.
var shaft: int = 1


## A collapse happened (core_journey.gd): the board is gone, so is the
## player's memory of it; the new shaft's Core is brought online.
func new_shaft() -> void:
	shaft += 1
	_dropped.clear()
	_bare.clear()
	_touched.clear()
	_stuck_since.clear()
	_line.clear()
	_history.clear()
	S.power_core()


## One beat of decisions.
func act() -> void:
	var r: float = rate()
	_rate_now = r
	var earned: float = maxf(float(S.lifetime_credits) - _last_life, 0.0)
	_last_life = float(S.lifetime_credits)
	_repair_budget = minf(_repair_budget + earned * REPAIR_SHARE, r * 600.0)
	var c0: float = S.credits
	if S.can_upgrade_core():
		S.upgrade_core()
		_event("core%d" % S.core_level, "Core level %d (earning %s/s)" % [S.core_level, Economy.fmt(r)])
	c0 = _spent("the Core", c0)
	# From Core 7 the rock is hot enough that a stratum down is a layout to
	# rework: the player goes down only while nothing overheats, so the
	# factory settles on each stratum before the next.
	var settled: bool = S.core_level < MachineDB.OVERDRIVE_CORE or CoreLevels.stable(S) > 0
	if S.can_descend() and settled:
		S.descend()
		_event("depth%d" % S.depth, "stratum %d" % S.depth)
	c0 = _spent("strata", c0)
	if S.can_choose_doctrine():
		S.choose_doctrine(doctrine)
		_event("doctrine", "doctrine %s" % doctrine)
	if not S.blueprint_pending.is_empty():
		S.fill_pending()
	c0 = _spent("the blueprint", c0)
	_research()
	_contracts()
	c0 = S.credits
	var reserve: float = _follow_plans()
	c0 = _spent("plans", c0)
	var building: bool = reserve > 0.0
	var open: Array = S.core_status().filter(func(st: Dictionary) -> bool: return not bool(st["met"]))
	# Saving for the Core: when what is left is bought with credits -- its
	# price, its machine levels, a bigger store -- spend nothing else, not
	# even on repairs (a player does not rebuild while saving).
	var buying: Array = [CoreLevels.Req.CREDITS, CoreLevels.Req.STOCK, CoreLevels.Req.MACHINE]
	var saving: bool = not open.is_empty() \
		and open.all(func(st: Dictionary) -> bool: return buying.has(int(st["req"][0])))
	_keep = 0.0
	_keep_levels = 0.0
	if not saving and S.core_level >= KEEP_FROM:
		# A player working towards the Core keeps what its rows are bought
		# with -- the Core's own price, and the machine and Vault levels it
		# asks for -- and grows the factory, or buys a level no row asks
		# for, on what is earned past it.
		for st: Dictionary in open:
			match int(st["req"][0]):
				CoreLevels.Req.CREDITS:
					_keep += float(st["need"])
				CoreLevels.Req.MACHINE:
					_keep_levels += float(S.machine_upgrade_cost(String(st["req"][1]))["credits"])
				CoreLevels.Req.STOCK:
					if int(st["cap"]) < int(st["need"]):
						_keep_levels += float(S.machine_upgrade_cost("vault")["credits"])
		# From Core 7 the Core's price, once saved, is kept: spent on growth
		# it has to be earned again (measured: the credits row met and lost
		# for hours while the player grew the factory on it).
		if S.core_level >= MachineDB.OVERDRIVE_CORE:
			for row: Array in CoreLevels.requirements(S.core_level + 1):
				if int(row[0]) == CoreLevels.Req.CREDITS and S.credits >= float(row[1]):
					_keep += float(row[1])
		_keep += _keep_levels
		reserve += _keep
	if saving:
		for st: Dictionary in open:
			match int(st["req"][0]):
				CoreLevels.Req.CREDITS:
					reserve += float(st["need"])
				CoreLevels.Req.MACHINE:
					reserve += float(S.machine_upgrade_cost(String(st["req"][1]))["credits"])
				CoreLevels.Req.STOCK:
					if int(st["cap"]) < int(st["need"]):
						reserve += float(S.machine_upgrade_cost("vault")["credits"])
	else:
		_repair()
		_tidy()
	c0 = _spent("repairs", c0)
	if not building:
		for st: Dictionary in open:
			_pursue(st)
	c0 = _spent("the Core's rows", c0)
	if not saving:
		_spare_upgrades()
	c0 = _spent("spare levels", c0)
	_spare_overdrive()
	# From the Core's level KEEP_FROM no new line goes down while something
	# overheats and the Core asks for stability: on hot rock a new line is
	# what breaks it. Once nothing overheats, the factory grows again --
	# stability is counted in machines at work.
	var holding: bool = S.core_level >= KEEP_FROM and CoreLevels.stable(S) == 0 \
		and open.any(func(st: Dictionary) -> bool: return int(st["req"][0]) == CoreLevels.Req.STABLE)
	# The deep chain pays for itself in minutes of the Core 7 era's income:
	# a player builds it ahead of the levels the Core asks for -- while a
	# unit costs no more than DEEP_PAYBACK seconds of what the factory
	# earns, a unit a beat -- but not while saving for the Core itself.
	if S.job_open("smelter", "alloy") and _deep_units() < DEEP_UNITS and not saving \
			and S.credits >= _deep_cost() * 1.5 and _deep_cost() <= r * DEEP_PAYBACK:
		_build_deep()
	c0 = _spent("the deep chain", c0)
	if S.credits > reserve and not holding:
		_grow()
	c0 = _spent("growth", c0)
	for id: String in S.machine_levels:
		_event("%s%d" % [id, int(S.machine_levels[id])], "%s level %d" % [id, int(S.machine_levels[id])])
	for id: String in S.upgrade_levels:
		_event("r%s%d" % [id, int(S.upgrade_levels[id])], "research %s %d" % [id, int(S.upgrade_levels[id])])
	for id: String in S.overdrive:
		_event("o%s%d" % [id, int(S.overdrive[id])], "%s Overdrive %d" % [id, int(S.overdrive[id])])
	for cell: int in S.grid.cells:
		var id: String = S.grid.machine_at(cell)
		_event("m" + id, "first " + id)


## What the store keeps for the Core's next level: {res: count}. Its store
## rows; and, from Core 7, what its open Overdrive and machine rows are paid
## in (measured: contracts and spare levels took the Ingots and Plates of
## an Overdrive step the Core asked for, for ten hours).
func _keep_materials() -> Dictionary:
	var keep: Dictionary = {}
	for st: Dictionary in S.core_status():
		var r: Array = st["req"]
		match int(r[0]):
			CoreLevels.Req.STOCK:
				keep[int(r[1])] = int(keep.get(int(r[1]), 0)) + int(st["need"])
			CoreLevels.Req.OVERDRIVE:
				if S.core_level >= MachineDB.OVERDRIVE_CORE and not bool(st["met"]):
					var od: Dictionary = S.overdrive_cost(String(r[1]))["materials"]
					for m: int in od:
						keep[m] = int(keep.get(m, 0)) + int(od[m])
			CoreLevels.Req.MACHINE:
				if S.core_level >= MachineDB.OVERDRIVE_CORE and not bool(st["met"]):
					var lv: Dictionary = S.machine_upgrade_cost(String(r[1]))["materials"]
					for m: int in lv:
						keep[m] = int(keep.get(m, 0)) + int(lv[m])
	return keep


## Fill a contract on the Dispatch board when the store can spare it: what
## the Core's own next level asks for stays in the store.
func _contracts() -> void:
	var keep: Dictionary = _keep_materials()
	for i in range(Dispatch.SLOTS):
		if not S.can_fill_contract(i):
			continue
		var c: Dictionary = S.contract(i)
		var res: int = int(c["res"])
		if S.stock_of(res) - int(c["n"]) >= int(keep.get(res, 0)):
			S.fill_contract(i)
			var n: int = S.contracts_lifetime
			if n == 1 or n % 10 == 0:
				_event("contract%d" % n, "contract %d filled (%s)" % [n, String(c["pays"])])
			return


func _research() -> void:
	var want: Array[String] = []
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.RESEARCH and not bool(st["met"]):
			want.append(String(st["req"][1]))
		if int(st["req"][0]) == CoreLevels.Req.DOCTRINE and not bool(st["met"]) and S.doctrine != "":
			for id: String in Economy.DOCTRINES[S.doctrine]["lines"]:
				want.append(id)
	for id: String in Economy.TREE_ORDER:
		if not want.has(id):
			want.append(id)
	for id: String in want:
		if S.can_buy_upgrade(id):
			S.buy_upgrade(id)
			return


func _pursue(st: Dictionary) -> void:
	var r: Array = st["req"]
	match int(r[0]):
		CoreLevels.Req.STOCK:
			var res: int = int(r[1])
			if int(st["cap"]) < int(st["need"]):
				S.upgrade_machine("vault")
			elif _core_feeders(res) < 2:
				_feed_core(res)
		CoreLevels.Req.WORKING:
			# The ones there are first: warmed, cooled or given an outlet;
			# then more of them.
			var id: String = String(r[1])
			if not _fix_heat_of(id) and not _unblock(id):
				if id == "lab" or S.grid.count_of(id) < int(st["need"]):
					_build_line(id) if id == "lab" else _build_somewhere(id)
		CoreLevels.Req.MACHINE:
			var mid: String = String(r[1])
			var why: String = S.machine_upgrade_blocker(mid)
			if why == "":
				S.upgrade_machine(mid)
			elif why == "storage":
				S.upgrade_machine("vault")
			elif why == "stock":
				for res: int in (S.machine_upgrade_cost(mid)["materials"] as Dictionary):
					if _core_feeders(res) < 1:
						_feed_core(res)
		CoreLevels.Req.RESEARCH:
			if S.grid.count_of("lab") == 0 or _working("lab") == 0:
				_build_lab()
			elif not S.can_buy_upgrade(String(r[1])) and S.upgrade_level(String(r[1])) < S.research_cap(String(r[1])):
				# Short of research, not of the Core: more Labs, fed.
				_more_labs()
		CoreLevels.Req.OVERDRIVE:
			_drive(String(r[1]))
		CoreLevels.Req.DOCTRINE:
			if S.doctrine != "":
				_more_labs()
		CoreLevels.Req.SERVES:
			_place_support(String(r[1]), int(r[2]))
		CoreLevels.Req.STABLE:
			for cell: int in S.grid.cells:
				if S.sim.overheated_at(cell):
					if not _hot_since.has(cell):
						_hot_since[cell] = t
					# From Core 7, one still overheating after HOT_FOR of fixes
					# is beyond them: a player stops fixing and decides.
					var tried: bool = S.core_level >= MachineDB.OVERDRIVE_CORE \
						and t - float(_hot_since[cell]) > HOT_FOR
					# From the Core's level KEEP_FROM a machine being cooled is
					# given the time to show it before it is judged beyond help.
					if not tried and S.core_level >= KEEP_FROM and t - float(_touched.get(cell, -1.0e9)) < SETTLE:
						continue
					if not tried and _fix_heat(cell, false):
						return
					# From Core 7: a Drill the rock overheats bores for crystal
					# instead, which the hot rock suits (MachineDB.JOBS).
					if _to_deep(cell):
						return
					# Nothing can cool it where it stands: a player takes it
					# away, unless a plan needs it there, and leaves the tile.
					# From the Core's level KEEP_FROM a plan's machine goes too
					# (on this stratum): the rock under Core 6 is hotter than
					# anything the plans were laid for.
					if not _reserved(cell) or S.core_level >= KEEP_FROM:
						if _reserved(cell):
							_dropped[cell] = true
						S.sell(cell)
						_bare[cell] = t
						return
			# Nothing overheats: more machines at their working heat.
			var still: Dictionary = {}
			for cell: int in _hot_since:
				if S.sim.overheated_at(cell):
					still[cell] = _hot_since[cell]
			_hot_since = still
			for cell: int in S.sim.problem_cells():
				if S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT and _fix_heat(cell, false):
					return


## An Overdrive step for machine type `id`, or what stands in its way:
## the Vault's level for a store too small, a chain into the store for the
## materials, Labs for the research, the type's own level first.
func _drive(id: String) -> void:
	match S.overdrive_blocker(id):
		"":
			S.overdrive_machine(id)
		"storage":
			S.upgrade_machine("vault")
		"stock":
			for res: int in (S.overdrive_cost(id)["materials"] as Dictionary):
				if S.stock_of(res) < int(S.overdrive_cost(id)["materials"][res]) and _core_feeders(res) < 2:
					_feed_core(res)
					return
		"research":
			_more_labs()
		"level":
			if S.can_upgrade_machine(id):
				S.upgrade_machine(id)


## From the Core's level KEEP_FROM the player keeps, whatever else it does,
## the credits the Core's rows are bought with. Before it the player is
## kept as it was measured.
const KEEP_FROM := 6
var _keep: float = 0.0
## The part of `_keep` that is machine and Vault levels, not the Core's price.
var _keep_levels: float = 0.0


## Labs, up to LABS, where refined material reaches them: research is a
## production decision, and a player short of it builds for it. From the
## Core's level LABS_FROM: the first four lines are cheap enough for the
## Labs the plans already hold, and the player before it is kept as it was
## measured.
const LABS := 12
const LABS_FROM := 6


func _more_labs() -> void:
	# On hot rock, with the deep chain open: a Lab fed Alloy (twice what a
	# Component teaches), cooled.
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.job_open("smelter", "alloy"):
		if _research_units() < LABS and t - _last_lab >= LAB_BEAT:
			_last_lab = t
			_build_research_unit()
		return
	if S.core_level < LABS_FROM or S.grid.count_of("lab") >= LABS or not S.can_afford("lab"):
		return
	# One at a time, given the time to show what it makes.
	if t - _last_lab < SETTLE:
		return
	_last_lab = t
	_build_lab()


## A research unit: a Deep Bore, a White Heat Smelter, a Coolant Cell and a
## Lab in a row. The Cell passes the Alloy on to the Lab and keeps it -- a
## Lab takes 3.0 heat, less than the rock of 17-19 -- cool.
func _build_research_unit() -> bool:
	var cost: float = S.cost_of("drill") + S.cost_of("smelter") + S.cost_of("coolant") + S.cost_of("lab")
	if S.credits < cost * 1.2 or not S.is_unlocked("coolant") or not S.is_unlocked("lab"):
		return false
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	for pass_ in range(2):
		for cell: int in BuildArea.cells(S.max_depth):
			for d: Vector2i in dirs:
				var row: Array[int] = []
				var p: Vector2i = Grid.xy(cell)
				for k in range(4):
					var q: Vector2i = p + d * k
					if not Grid.in_bounds(q.x, q.y):
						break
					row.append(Grid.idx(q.x, q.y))
				if row.size() < 4 or not _deep_ground(row, pass_ == 1):
					continue
				for c: int in row:
					_bare.erase(c)
					if not S.grid.is_empty(c):
						S.sell(c)
				if not S.try_place(row[0], "drill") or not S.try_place(row[1], "smelter") \
						or not S.try_place(row[2], "coolant") or not S.try_place(row[3], "lab"):
					return false
				S.set_job(row[0], "crystal")
				S.set_job(row[1], "alloy")
				for c: int in row:
					_line[c] = true
				return true
	return false


## Labs fed by the deep chain.
func _research_units() -> int:
	var n: int = 0
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == "lab" and S.sim.status_of(cell) != Simulation.Status.STARVED:
			for f: int in S.grid.bridged_machines(cell):
				if S.grid.job_at(f) == "alloy":
					n += 1
					break
	return n


const LAB_BEAT := 60.0


var _last_lab: float = -1.0e9


## Overdrive steps past what the Core asks for, from what the store and the
## research can spare after the Core's own asks: the chain's end first.
func _spare_overdrive() -> void:
	if S.core_level < MachineDB.OVERDRIVE_CORE:
		return
	var keep: Dictionary = _keep_materials()
	for id: String in ["assembler", "press", "smelter", "crusher", "drill", "lab", "coolant", "condenser"]:
		if not S.can_overdrive(id):
			continue
		var cost: Dictionary = S.overdrive_cost(id)
		var ok: bool = true
		for res: int in (cost["materials"] as Dictionary):
			var left: int = S.stock_of(res) - int(cost["materials"][res])
			ok = ok and (left >= int(keep.get(res, 0)) or S.stock_of(res) >= S.stock_cap())
		if ok:
			S.overdrive_machine(id)
			return


## Machine levels past what the Core asks for, from what the store can
## spare after the Core's own materials.
func _spare_upgrades() -> void:
	var keep: Dictionary = _keep_materials()
	# A level is heat as well as speed: in a shaft after a collapse, and on
	# the Core 7 era's rock, a level no row asks for waits while something
	# overheats (measured: cheap levels bought on every type put a second
	# shaft's lines past their tolerance on stratum 12 for twelve hours).
	var hot: bool = (S.collapses > 0 or S.core_level >= MachineDB.OVERDRIVE_CORE) \
		and CoreLevels.stable(S) == 0
	for id: String in ["vault", "smelter", "crusher", "drill", "press", "assembler", "lab"]:
		if not S.can_upgrade_machine(id):
			continue
		if hot and id != "vault":
			continue
		var cost: Dictionary = S.machine_upgrade_cost(id)
		var ok: bool = S.credits - _keep >= float(cost["credits"]) * 1.5
		for res: int in (cost["materials"] as Dictionary):
			# What the Core keeps for itself stays, unless the store is full
			# and refills anyway.
			var left: int = S.stock_of(res) - int(cost["materials"][res])
			ok = ok and left >= 0 and (left >= int(keep.get(res, 0)) or S.stock_of(res) >= S.stock_cap())
		if id == "vault":
			# A full store is a reason on its own.
			ok = ok or (S.stock_of(MachineDB.Res.INGOT) >= S.stock_cap() and S.credits >= float(cost["credits"]))
		if ok:
			S.upgrade_machine(id)
			return


## --- the board ------------------------------------------------------------------

## The next machine of the plans the Core's level has reached: placed when it
## can be, or its price, which the rest of the beat then keeps. 0 when every
## plan so far stands (or waits only for a stratum or a machine not found).
func _follow_plans() -> float:
	if _dropped_depth != S.depth:
		_dropped.clear()
		_dropped_depth = S.depth
	# The plans are the first three Core levels' lines. From the Core's
	# level KEEP_FROM the player works from the Core's rows alone, and does
	# not rebuild a plan's machine the hot rock has cost it.
	if S.core_level >= KEEP_FROM:
		return 0.0
	for plan: Dictionary in PLANS:
		if S.core_level < int(plan["core"]) or S.max_depth < int(plan["from"]):
			break
		for e: Array in plan["cells"]:
			var cell: int = Grid.idx(int(e[0]), int(e[1]))
			var id: String = String(e[2])
			if S.grid.machine_at(cell) == id or _dropped.has(cell):
				continue
			if not S.is_unlocked(id) or not S.is_open(cell) or S.is_blocked(cell):
				continue
			if not S.grid.is_empty(cell):
				# Something built there before the plan started makes way.
				if S.credits < S.cost_of(id):
					return S.cost_of(id)
				S.sell(cell)
			if S.try_place(cell, id):
				return 0.0
			if S.credits < S.cost_of(id):
				return S.cost_of(id)
	return 0.0


var _plan_cells: Dictionary = {}
## Plan tiles the player changed their mind about on this stratum (a
## Coolant Cell that over-cooled here, say): not rebuilt until the next one,
## whose heat is different.
var _dropped: Dictionary = {}
var _dropped_depth: int = -1


## A tile beside `cell` to build on: a free one, or else one standing a
## machine the player built for income alone (not a plan's, not a support
## machine, not one touching the Core), sold to make room. -1 when none.
func _room_near(cell: int) -> int:
	var free: Array[int] = _free_near(cell, false)
	if not free.is_empty():
		return free[0]
	for n: int in S.grid.neighbours(cell):
		if _income_only(n) and not S.sim.core_touching().has(n):
			S.sell(n)
			return n
	return -1


## The tiles of the plans the Core's level has reached: kept for them,
## whatever else the player builds. A later plan's tiles are free until then.
func _reserved(cell: int) -> bool:
	# The plans stop at the Core's level KEEP_FROM; from Overdrive's level
	# on, a player lays the yard again for the hot rock.
	if S.core_level >= MachineDB.OVERDRIVE_CORE:
		return false
	var core: int = int(_plan_cells.get(cell, 999))
	if _plan_cells.is_empty():
		for plan: Dictionary in PLANS:
			for e: Array in plan["cells"]:
				_plan_cells[Grid.idx(int(e[0]), int(e[1]))] = int(plan["core"])
				_plan_from[Grid.idx(int(e[0]), int(e[1]))] = int(plan["from"])
		core = int(_plan_cells.get(cell, 999))
	# A shaft after a collapse starts on the Core's foundation, above plans
	# it has not reached the rock for: their tiles are not kept until it has
	# (measured: a second shaft at Core 4 with every tile of stratum 0 kept
	# for later plans placed nothing, ever).
	if S.collapses > 0 and int(_plan_from.get(cell, 0)) > S.max_depth:
		return false
	return core <= S.core_level


var _plan_from: Dictionary = {}


## Tiles left bare on purpose: something overheated there.
var _bare: Dictionary = {}
## When the player last changed the heat round a tile: a change is given
## SETTLE seconds to show before the same tile is touched again, or a fix
## for one machine and a fix for its neighbour undo each other forever.
var _touched: Dictionary = {}
const SETTLE := 300.0


func _free(cell: int) -> bool:
	if not S.grid.is_empty(cell) or not S.is_open(cell) or S.is_blocked(cell) or _reserved(cell):
		return false
	if S.core_level >= MachineDB.OVERDRIVE_CORE:
		# From Core 7 a tile is left bare, or kept from a machine scrapped
		# on it, for FORGET seconds: lines are laid with their cooling
		# now (`_cool_if_needed`), so the tile can be tried again -- but not
		# at once, or a repair lays again what was just cleared away.
		return t - float(_bare.get(cell, -1.0e9)) > FORGET and t - float(_scrapped.get(cell, -1.0e9)) > FORGET
	return not _bare.has(cell)


## Tiles a machine was scrapped from (`_tidy`), and when.
var _scrapped: Dictionary = {}
const FORGET := 1800.0


func _free_near(cell: int, away_from_core: bool) -> Array[int]:
	var out: Array[int] = []
	for n: int in S.grid.neighbours(cell):
		if _free(n) and not (away_from_core and S.sim.core_touching().has(n)):
			out.append(n)
	return out


func _working(id: String) -> int:
	return CoreLevels.working(S, id)


## Machines making `res` that touch the Core.
func _core_feeders(res: int) -> int:
	var n: int = 0
	for cell: int in S.sim.core_touching():
		if (S.sim.machine_of(cell).get("outputs", {}) as Dictionary).has(res):
			# From Core 7 a feeder that has been starved most of the time is
			# not one: its line behind it has gone.
			if S.core_level >= MachineDB.OVERDRIVE_CORE and S.sim.uptime_of(cell) < 0.2 \
					and S.sim.status_of(cell) == Simulation.Status.STARVED:
				continue
			n += 1
	return n


## The machine type and job this shaft makes `res` with: its own recipe if
## one makes it, else a job the shaft has opened. [] when none.
func _maker(res: int) -> Array:
	var open: Array = []
	for mk: Array in MachineDB.makers_of(res):
		if S.is_unlocked(String(mk[0])) and S.job_open(String(mk[0]), String(mk[1])):
			open.append(mk)
	if open.is_empty():
		return []
	# From Core 7, on the deep rock, a job built for its heat (Alloy Parts
	# rather than Plates into Components) is laid first.
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.max_depth >= MachineDB.CRYSTAL_DEPTH:
		for mk: Array in open:
			if String(mk[1]) != "":
				return mk
	return open[0]


## A chain that ends in a maker of `res` touching the Core.
func _feed_core(res: int) -> bool:
	var mk: Array = _maker(res)
	if mk.is_empty():
		return false
	var maker: String = String(mk[0])
	var best: int = -1
	var room: int = -1
	for cell: int in S.sim.core_touching():
		if not _free(cell):
			continue
		var r: int = _free_near(cell, true).size()
		if _reserved(cell):
			r += 2
		if r > room:
			room = r
			best = cell
	if S.credits < _chain_cost(maker, String(mk[1])):
		return false
	if best < 0 and String(mk[1]) != "" and _retask(mk):
		return true
	if best < 0:
		# Every tile touching the Core is taken: one built for income alone
		# makes way.
		for cell: int in S.sim.core_touching():
			if _income_only(cell):
				S.sell(cell)
				best = cell
				break
	if best < 0 and S.core_level >= MachineDB.OVERDRIVE_CORE:
		# From Core 7: a machine beside the Core making nothing the Core now
		# asks for makes way for one that does (the store's sides are for
		# what the next level needs).
		var wanted: Dictionary = _wanted()
		wanted[res] = true
		for cell: int in S.sim.core_touching():
			var outs: Dictionary = S.sim.machine_of(cell).get("outputs", {})
			if outs.is_empty() or S.grid.machine_at(cell) == "vault":
				continue
			var keep: bool = false
			for o: int in outs:
				keep = keep or wanted.has(o)
			# One starved most of the time is kept for nothing.
			if S.sim.uptime_of(cell) < 0.2 and S.sim.status_of(cell) == Simulation.Status.STARVED:
				keep = false
			if not keep:
				S.sell(cell)
				best = cell
				break
	if best < 0:
		return false
	return _chain(maker, best, 0, String(mk[1]))


## The materials the Core's next level wants in its store: its store rows
## not met, and what its machine and Overdrive rows are paid in.
func _wanted() -> Dictionary:
	var out: Dictionary = {}
	for st: Dictionary in S.core_status():
		if bool(st["met"]):
			continue
		var r: Array = st["req"]
		match int(r[0]):
			CoreLevels.Req.STOCK:
				out[int(r[1])] = true
			CoreLevels.Req.MACHINE:
				for m: int in (S.machine_upgrade_cost(String(r[1]))["materials"] as Dictionary):
					out[m] = true
			CoreLevels.Req.OVERDRIVE:
				for m: int in (S.overdrive_cost(String(r[1]))["materials"] as Dictionary):
					out[m] = true
	return out


## A machine of the type `mk` names, touching the Core and making something
## no open row of the Core asks for, set to `mk`'s job, and a feeder laid
## beside it for what the job takes: what a player does with the sides of
## the Core kept for the store. False when there is no such machine.
func _retask(mk: Array) -> bool:
	var need: Dictionary = {}
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.STOCK and not bool(st["met"]):
			need[int(st["req"][1])] = true
	for cell: int in S.sim.core_touching():
		if S.grid.machine_at(cell) != String(mk[0]) or S.grid.job_at(cell) == String(mk[1]):
			continue
		var wanted: bool = false
		for res: int in (S.sim.machine_of(cell).get("outputs", {}) as Dictionary):
			wanted = wanted or need.has(res)
		# A starved one making the same thing another way is retasked too:
		# the hot rock starved its old line.
		var same: bool = S.sim.machine_of(cell).get("outputs", {}) \
			== MachineDB.job_machine(String(mk[0]), String(mk[1])).get("outputs", {})
		if same and S.sim.uptime_of(cell) < 0.2 and S.sim.status_of(cell) == Simulation.Status.STARVED:
			wanted = false
		if wanted or not S.set_job(cell, String(mk[1])):
			continue
		_line[cell] = true
		for res: int in (MachineDB.job_machine(String(mk[0]), String(mk[1])).get("inputs", {}) as Dictionary):
			var fm: Array = _maker(res)
			if fm.is_empty():
				continue
			var spots: Array[int] = _free_near(cell, true)
			if spots.is_empty():
				# What fed its old job gives way to what feeds the new one.
				for n: int in S.grid.neighbours(cell):
					if S.sim.core_touching().has(n) or S.grid.is_empty(n):
						continue
					var nid: String = S.grid.machine_at(n)
					if nid in ["crusher", "drill", "vault"] and S.grid.job_at(n) == "":
						S.sell(n)
						spots.append(n)
						break
			if not spots.is_empty():
				_chain(String(fm[0]), spots[0], 1, String(fm[1]))
		return true
	return false


## What a maker and the chain behind it cost, roughly: a player looks at the
## prices before starting a line they cannot finish.
func _chain_cost(id: String, job: String = "") -> float:
	var m: Dictionary = MachineDB.job_machine(id, job)
	var total: float = S.cost_of(id)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research"):
		ins = {MachineDB.Res.INGOT: 1}
	for res: int in ins:
		var mk: Array = _maker(res)
		if mk.is_empty():
			return INF
		total += _chain_cost(String(mk[0]), String(mk[1])) * float(clampi(int(ins[res]), 1, 2))
	if MachineDB.heat_liking(id) > 0 and S.is_unlocked("boiler"):
		total += S.cost_of("boiler")
	return total


## A machine starved for an input gets a feeder on a free tile beside it; one
## blocked, with nowhere for its output to go, a Vault.
func _repair() -> void:
	for cell: int in S.grid.cells:
		if S.sim.status_of(cell) == Simulation.Status.BLOCKED:
			if not _worth(S.cost_of("vault")) or S.grid.machine_at(cell) == "drill":
				continue
			var out: int = _room_near(cell)
			if out >= 0 and S.try_place(out, "vault"):
				return
			continue
		if S.sim.status_of(cell) != Simulation.Status.STARVED:
			continue
		if t - float(_touched.get(cell, -1.0e9)) < SETTLE:
			continue
		_touched[cell] = t
		var m: Dictionary = S.sim.machine_of(cell)
		if (m.get("tags", []) as Array).has("sink"):
			continue
		var ins: Dictionary = m.get("inputs", {})
		if (m.get("tags", []) as Array).has("research"):
			ins = {MachineDB.Res.INGOT: 1}
		for res: int in ins:
			var mk: Array = _maker(res)
			if mk.is_empty() or not _worth(_chain_cost(String(mk[0]), String(mk[1]))):
				continue
			var spots: Array[int] = _free_near(cell, true)
			if spots.is_empty():
				# No room: an income-only neighbour makes way for the feeder.
				for n: int in S.grid.neighbours(cell):
					if _income_only(n) and not S.sim.core_touching().has(n):
						S.sell(n)
						spots.append(n)
						break
			if not spots.is_empty():
				_chain(String(mk[0]), spots[0], 1, String(mk[1]))
				return


## Machine `id` on `cell`, on job `job`, and whatever it needs to be fed
## behind it.
func _chain(id: String, cell: int, depth: int, job: String = "") -> bool:
	if depth > 6 or not S.try_place(cell, id):
		return false
	_line[cell] = true
	if job != "":
		S.set_job(cell, job)
	var m: Dictionary = MachineDB.job_machine(id, job)
	_cool_if_needed(cell)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research"):
		ins = {MachineDB.Res.INGOT: 1}
	for res: int in ins:
		var fed: bool = false
		for n: int in S.grid.bridged_machines(cell):
			if (S.sim.machine_of(n).get("outputs", {}) as Dictionary).has(res):
				fed = true
		if fed:
			continue
		var mk: Array = _maker(res)
		if mk.is_empty():
			continue
		var maker: String = String(mk[0])
		# Two feeders for a machine that takes two of a thing at a time.
		for _k in range(clampi(int(ins[res]), 1, 2)):
			var spots: Array[int] = _free_near(cell, true)
			if spots.is_empty():
				for n: int in S.grid.neighbours(cell):
					if _income_only(n) and not S.sim.core_touching().has(n) and S.grid.machine_at(n) != maker:
						S.sell(n)
						spots.append(n)
						break
			if spots.is_empty():
				break
			_chain(maker, spots[0], depth + 1, String(mk[1]))
	# A warmth-loving maker gets a Boiler beside it -- from the Core's level
	# KEEP_FROM only where it is still cold: the rock of strata 13 and deeper
	# is warmer than any maker wants.
	var cold: bool = S.core_level < KEEP_FROM \
		or S.grid.heat_at(cell) < float(m.get("heat_optimum", 0.0))
	if (MachineDB.heat_liking(id) > 0 or float(m.get("heat_optimum", 0.0)) >= 1.0) \
			and S.is_unlocked("boiler") and cold:
		var spots2: Array[int] = _free_near(cell, true)
		if not spots2.is_empty():
			S.try_place(spots2[0], "boiler")
	return true


func _build_somewhere(id: String) -> void:
	var outs: Dictionary = MachineDB.get_machine(id).get("outputs", {})
	if S.credits < _chain_cost(id) * 1.5:
		return
	for res: int in outs:
		if MachineDB.STOCKED.has(res):
			if _feed_core(res):
				return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not S.sim.core_touching().has(cell) and _free_near(cell, true).size() >= 2:
			_chain(id, cell, 0)
			var spots: Array[int] = _free_near(cell, true)
			if not spots.is_empty() and not outs.is_empty():
				S.try_place(spots[0], "vault")
			return
	# The yard is full: a player sells a patch of Drills and Vaults, built
	# only for income, and lays the line there.
	for cell: int in BuildArea.cells(S.max_depth):
		if not _income_only(cell) or S.sim.core_touching().has(cell):
			continue
		var patch: Array[int] = [cell]
		for n: int in S.grid.neighbours(cell):
			if _income_only(n) and not S.sim.core_touching().has(n):
				patch.append(n)
		if patch.size() < 4:
			continue
		for c: int in patch:
			S.sell(c)
		_chain(id, cell, 0)
		var spots2: Array[int] = _free_near(cell, true)
		if not spots2.is_empty() and not outs.is_empty():
			S.try_place(spots2[0], "vault")
		return


## A line of `id` with its feeders and a Vault, on free ground or on a
## patch of income-only machines sold for it -- never on the Core's side.
func _build_line(id: String) -> bool:
	var outs: Dictionary = MachineDB.get_machine(id).get("outputs", {})
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not S.sim.core_touching().has(cell) and _free_near(cell, true).size() >= 3:
			return _lay(id, cell, outs)
	for cell: int in BuildArea.cells(S.max_depth):
		if not _income_only(cell) or S.sim.core_touching().has(cell):
			continue
		var patch: Array[int] = [cell]
		for n: int in S.grid.neighbours(cell):
			if (_income_only(n) or _free(n)) and not S.sim.core_touching().has(n):
				patch.append(n)
		if patch.size() < 5:
			continue
		for c: int in patch:
			if not S.grid.is_empty(c):
				S.sell(c)
		return _lay(id, cell, outs)
	return false


func _lay(id: String, cell: int, outs: Dictionary) -> bool:
	if not _chain(id, cell, 0):
		return false
	var spots: Array[int] = _free_near(cell, true)
	if not spots.is_empty() and not outs.is_empty():
		S.try_place(spots[0], "vault")
	return true


## Machines starved or backed up for SCRAP seconds and not in a plan: a
## player clears them away rather than let them hold the yard.
var _stuck_since: Dictionary = {}
const SCRAP := 600.0


func _tidy() -> void:
	var seen: Dictionary = {}
	# What a blueprint laid is left to the blueprint: it is still being
	# finished (its feeders, its job).
	var laid: Dictionary = {}
	for e: Array in S.blueprint_pending:
		laid[int(e[0])] = true
	for cell: int in S.grid.cells:
		if laid.has(cell):
			continue
		# Barely working: stalled most of the time, whatever it shows now.
		if S.sim.uptime_of(cell) >= 0.2 or S.sim.status_of(cell) == Simulation.Status.PASSIVE:
			continue
		if _reserved(cell) or S.grid.machine_at(cell) == "vault" \
				or S.sim.core_touching().has(cell) or S.grid.job_at(cell) != "":
			continue
		seen[cell] = true
		if not _stuck_since.has(cell):
			_stuck_since[cell] = t
		elif t - float(_stuck_since[cell]) > SCRAP:
			S.sell(cell)
			_stuck_since.erase(cell)
			_scrapped[cell] = t
			return
	for cell: int in _stuck_since.keys():
		if not seen.has(cell):
			_stuck_since.erase(cell)


## A Drill, Vault or Crusher built for income alone: no plan's tile.
func _income_only(cell: int) -> bool:
	if _line.has(cell) and S.grid.machine_at(cell) != "":
		return false
	_line.erase(cell)
	if not S.grid.machine_at(cell) in ["drill", "vault", "crusher"] or _reserved(cell):
		return false
	# From Core 7, when the plans' tiles are no longer kept: a Drill or a
	# Crusher that feeds a maker is part of a line, not built for income.
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.grid.machine_at(cell) != "vault":
		for n: int in S.grid.bridged_machines(cell):
			var nm: Dictionary = S.sim.machine_of(n)
			for res: int in (S.sim.machine_of(cell).get("outputs", {}) as Dictionary):
				if (nm.get("inputs", {}) as Dictionary).has(res) and not (nm.get("tags", []) as Array).has("sink"):
					return false
	return true


## Tiles the player laid as part of a line (`_chain`): not income-only, so
## no other line sells them for room.
var _line: Dictionary = {}


## A Lab where refined material reaches it.
func _build_lab() -> void:
	if not S.is_unlocked("lab") or not S.can_afford("lab"):
		return
	if S.core_level >= KEEP_FROM:
		# On hot rock: where it is fed and would not overheat, beside an
		# Assembler (a Component teaches most) if there is such a tile.
		var tol: float = float(MachineDB.get_machine("lab")["heat_tolerance"]) + S.sim.tolerance_bonus
		var own: float = float(MachineDB.get_machine("lab")["heat_out"]) * float(S.grid.heat_scale.get("lab", 1.0))
		var best: int = -1
		var near_parts: bool = false
		for cell: int in BuildArea.cells(S.max_depth):
			if not _free(cell) or S.sim.core_touching().has(cell):
				continue
			if S.grid.heat_at(cell) + own > tol - 0.2 or not bool(S.sim.links_if_placed(cell, "lab")["fed"]):
				continue
			var parts: bool = false
			for n: int in S.grid.neighbours(cell):
				parts = parts or S.grid.machine_at(n) == "assembler"
			if best < 0 or (parts and not near_parts):
				best = cell
				near_parts = parts
			if near_parts:
				break
		if best >= 0:
			S.try_place(best, "lab")
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not S.sim.core_touching().has(cell) \
				and bool(S.sim.links_if_placed(cell, "lab")["fed"]):
			S.try_place(cell, "lab")
			return
	_build_somewhere("lab")


func _fix_heat_of(id: String) -> bool:
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == id and S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT:
			if _fix_heat(cell):
				return true
	return false


## A machine of type `id` blocked with nowhere for its output: a Vault beside
## it, on a free tile or one an income-only machine gives up.
func _unblock(id: String) -> bool:
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == id and S.sim.status_of(cell) == Simulation.Status.BLOCKED:
			var spot: int = _room_near(cell)
			if spot >= 0 and S.try_place(spot, "vault"):
				return true
	return false


## Warm a machine that is too cold, cool one that is too hot: first by taking
## away a neighbour that pushes it the wrong way (strata change the ambient
## heat, so the same line can be over-cooled one stratum down), then by
## adding a Boiler or a Coolant Cell beside it.
func _fix_heat(cell: int, may_remove: bool = true) -> bool:
	if t - float(_touched.get(cell, -1.0e9)) < SETTLE:
		return false
	_touched[cell] = t
	var m: Dictionary = S.sim.machine_of(cell)
	var warm: bool = S.grid.heat_at(cell) < float(m.get("heat_optimum", 0.0))
	var wrong: String = "coolant" if warm else "boiler"
	var modes: bool = S.core_level >= MachineDB.MODES_CORE
	# Too hot, in the order the heat card offers it: a Boiler beside it run
	# Low; a Boiler the rock has made needless taken away; the machine run
	# Cool; the Coolant Cells a level up; then a new Coolant Cell.
	if not warm:
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "boiler" and modes and S.grid.mode_at(n) == MachineDB.Mode.NORMAL:
				return S.set_mode(n, MachineDB.Mode.COOL)
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "boiler" and (may_remove or S.grid.ambient_heat >= 1.8):
				S.sell(n)
				_dropped[n] = true
				return true
		if modes and S.grid.mode_at(cell) == MachineDB.Mode.NORMAL \
				and MachineDB.modes_for(S.grid.machine_at(cell)).has(MachineDB.Mode.COOL):
			return S.set_mode(cell, MachineDB.Mode.COOL)
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "coolant" and S.can_upgrade_machine("coolant"):
				return S.upgrade_machine("coolant")
	elif S.core_level >= KEEP_FROM and S.grid.mode_at(cell) == MachineDB.Mode.COOL:
		# Too cold and running Cool: Normal again, as the heat card says.
		return S.set_mode(cell, MachineDB.Mode.NORMAL)
	for n: int in S.grid.neighbours(cell):
		if may_remove and S.grid.machine_at(n) == wrong:
			S.sell(n)
			_dropped[n] = true
			return true
	var id: String = "boiler" if warm else "coolant"
	if not S.is_unlocked(id) or not S.can_afford(id):
		return false
	var spot: int = _room_near(cell)
	if spot < 0 and id == "coolant":
		# A Coolant Cell passes material through, so it may take a tile a
		# plan kept empty; the plan leaves it there on this stratum.
		for n: int in S.grid.neighbours(cell):
			if S.grid.is_empty(n) and S.is_open(n) and not S.is_blocked(n):
				spot = n
				_dropped[n] = true
				break
	if spot < 0 and id == "coolant":
		# Boxed in: a Vault beside it gives way to a Coolant Cell, which
		# passes material on to what stands beyond it.
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "vault" and not S.sim.core_touching().has(n):
				S.sell(n)
				spot = n
				_dropped[n] = true
				break
	return spot >= 0 and S.try_place(spot, id)


## A support machine where it serves `need` machines: a free tile, or one
## standing an income-only machine, sold for it.
func _place_support(id: String, need: int) -> void:
	if not S.is_unlocked(id) or not S.can_afford(id):
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and S.grid.serves_if_placed(cell) >= need:
			S.try_place(cell, id)
			return
	for cell: int in BuildArea.cells(S.max_depth):
		var here: String = S.grid.machine_at(cell)
		if here in ["drill", "vault"] and not _reserved(cell) and S.grid.serves(cell) >= need:
			S.sell(cell)
			S.try_place(cell, id)
			return
	# From the Core's level KEEP_FROM: a Condenser in a Coolant Cell's place
	# among the machines it cools (it cools harder, and speeds them).
	if id != "condenser" or S.core_level < KEEP_FROM:
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if S.grid.machine_at(cell) == "coolant" and S.grid.serves(cell) >= need:
			S.sell(cell)
			if S.try_place(cell, id):
				_dropped[cell] = true
			return


## What "What now?" names, off the Core's kept sides.
func _grow() -> void:
	# From Core 7, on the deep rock, the factory grows by the deep chain
	# (`_build_deep`, `_build_research_unit`) and by what the Core's rows
	# ask for: an old line laid for income alone is a line the rock
	# overheats (measured: 120M credits an hour spent on lines that broke
	# the stability row).
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.job_open("smelter", "alloy"):
		return
	# A whole line of the best maker found, fed from its own Drills, with
	# a Vault: what a player who has learnt the chain builds. Single
	# machines where "What now?" points are for the first minutes.
	var top: String = ""
	for id: String in ["assembler", "press", "smelter"]:
		if S.is_unlocked(id):
			top = id
			break
	if top != "" and S.credits - _keep >= _chain_cost(top) * 1.5 + S.cost_of("vault"):
		if _build_line(top):
			return
	if _keep > 0.0 and S.credits <= _keep:
		return
	var best: Dictionary = Worklist.best_placement(S)
	var ext: Dictionary = Worklist.extension(S, best)
	if not ext.is_empty() and _free(int(ext["cell"])) and _free(int(ext["outlet"])):
		if S.try_place(int(ext["cell"]), String(ext["id"])):
			S.try_place(int(ext["outlet"]), "vault")
			return
	if not best.is_empty() and _free(int(best["cell"])):
		S.try_place(int(best["cell"]), String(best["id"]))
		return
	# Nothing works anywhere new: another Drill and Vault on free ground.
	if S.credits < S.cost_of("drill") + S.cost_of("vault"):
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not _reserved(cell):
			var spots: Array[int] = _free_near(cell, false).filter(func(n: int) -> bool: return not _reserved(n))
			if not spots.is_empty():
				S.try_place(cell, "drill")
				S.try_place(spots[0], "vault")
				return


## Can the player pay `cost` for a repair, and is it worth it? From the
## Core's level 7 -- where machines cost what hundreds of them make them
## cost (MachineDB.cost_for) -- a player spends on repairs at most
## REPAIR_SHARE of what the factory earns (`_repair_budget`), and no one
## repair past REPAIR_PAYBACK seconds of its income: measured without it,
## repairs that did not hold took every credit the Core 7 era earned. Before
## Core 7, as measured: whenever it can be paid.
func _worth(cost: float) -> bool:
	if S.credits < cost:
		return false
	if S.core_level < MachineDB.OVERDRIVE_CORE:
		return true
	return cost <= _rate_now * REPAIR_PAYBACK and cost <= _repair_budget


const REPAIR_PAYBACK := 60.0
const REPAIR_SHARE := 0.2
var _rate_now: float = 0.0
var _repair_budget: float = 0.0
var _last_life: float = 0.0


## From the Core's level 7, a machine laid on rock that already has it at
## the edge of its safe range gets a Coolant Cell beside it as it is laid,
## as a player who has read the heat card lays a line on stratum 19: the
## Cell passes material through, so the line is still fed across it.
func _cool_if_needed(cell: int) -> void:
	if S.core_level < MachineDB.OVERDRIVE_CORE or not S.is_unlocked("coolant"):
		return
	var id: String = S.grid.machine_at(cell)
	if MachineDB.is_heat_support(id) or (MachineDB.get_machine(id)["tags"] as Array).has("sink"):
		return
	var m: Dictionary = S.sim.machine_of(cell)
	if m.has("heat_drive"):
		return
	var edge: float = float(m["heat_tolerance"]) + S.sim.tolerance_bonus - COOL_MARGIN
	if S.grid.heat_at(cell) <= edge or not S.can_afford("coolant"):
		return
	var spots: Array[int] = _free_near(cell, true)
	if spots.is_empty():
		# No free tile: an empty one a plan or the rock left, then a Vault
		# beside it gives way -- a Cell passes material on as a Vault did not.
		for n: int in S.grid.neighbours(cell):
			if S.grid.is_empty(n) and S.is_open(n) and not S.is_blocked(n):
				spots.append(n)
				break
	if spots.is_empty():
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "vault" and not S.sim.core_touching().has(n):
				S.sell(n)
				spots.append(n)
				break
	if not spots.is_empty():
		_bare.erase(spots[0])
		S.try_place(spots[0], "coolant")


const COOL_MARGIN := 0.5


## When each machine now overheating was first seen to (`_pursue`,
## stability); cleared once nothing overheats.
var _hot_since: Dictionary = {}
const HOT_FOR := 900.0


## Credits spent this beat by `what`, from `c0` (the credits before it),
## counted in `spend`. Returns the credits now.
func _spent(what: String, c0: float) -> float:
	var d: float = c0 - float(S.credits)
	if d > 0.0:
		spend[what] = float(spend.get(what, 0.0)) + d
		if what == "repairs":
			_repair_budget -= d
	return float(S.credits)


## Credits spent by what, since the last snapshot.
var spend: Dictionary = {}


## --- the deep chain -------------------------------------------------------------------

## A Drill on the old job that overheats, set to bore crystal -- and a
## Smelter beside it making Ingots the store has no room for, set to White
## Heat to take the crystal. True when the Drill was retasked.
func _to_deep(cell: int) -> bool:
	if S.grid.machine_at(cell) != "drill" or S.grid.job_at(cell) != "" or not S.can_set_job(cell, "crystal"):
		return false
	# A Drill feeding a Crusher is the old chain's ore: the Components and
	# Plates the Core still asks for start there. Only a Drill built for
	# income alone is retasked.
	for n: int in S.grid.bridged_machines(cell):
		if S.grid.machine_at(n) == "crusher":
			return false
	S.set_job(cell, "crystal")
	_line[cell] = true
	_event("retask", "first Drill retasked to Deep Bore")
	var ingots_wanted: bool = S.stock_of(MachineDB.Res.INGOT) < S.stock_cap() \
		or S.core_status().any(func(st: Dictionary) -> bool:
			return int(st["req"][0]) == CoreLevels.Req.STOCK and int(st["req"][1]) == MachineDB.Res.INGOT \
				and not bool(st["met"]))
	for n: int in S.grid.neighbours(cell):
		if S.grid.machine_at(n) == "smelter" and S.grid.job_at(n) == "" and not ingots_wanted:
			S.set_job(n, "alloy")
			_line[n] = true
	return true

## Deep units the player builds at most: a Deep Bore, a White Heat Smelter
## and a Vault each.
const DEEP_UNITS := 32
const DEEP_PAYBACK := 120.0


func _deep_units() -> int:
	var n: int = 0
	for cell: int in S.grid.cells:
		if S.grid.job_at(cell) == "alloy":
			n += 1
	return n


func _deep_cost() -> float:
	return S.cost_of("drill") + S.cost_of("smelter") + S.cost_of("vault")


## A Deep Bore, a White Heat Smelter and a Vault in a row on free ground,
## not beside the Core and where none of the three stands beside a maker
## of the old chain that would overheat with it -- or, with no such ground
## left, on a patch of income-only machines sold for it.
func _build_deep() -> bool:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	for pass_ in range(2):
		for cell: int in BuildArea.cells(S.max_depth):
			for d: Vector2i in dirs:
				var row: Array[int] = []
				var p: Vector2i = Grid.xy(cell)
				for k in range(3):
					var q: Vector2i = p + d * k
					if not Grid.in_bounds(q.x, q.y):
						break
					row.append(Grid.idx(q.x, q.y))
				if row.size() < 3 or not _deep_ground(row, pass_ == 1):
					continue
				for c: int in row:
					_bare.erase(c)
					if not S.grid.is_empty(c):
						S.sell(c)
				if not S.try_place(row[0], "drill") or not S.try_place(row[1], "smelter") \
						or not S.try_place(row[2], "vault"):
					return false
				S.set_job(row[0], "crystal")
				S.set_job(row[1], "alloy")
				for c: int in row:
					_line[c] = true
				return true
	return false


## Can a deep unit stand on `row`? Free tiles (or, `sell`, income-only
## ones), off the Core's sides, and nothing but empty ground, Vaults,
## supports or deep machines beside them.
func _deep_ground(row: Array[int], sell: bool) -> bool:
	for c: int in row:
		if S.sim.core_touching().has(c):
			return false
		var bare: bool = _bare.has(c) and S.grid.is_empty(c) and S.is_open(c) and not S.is_blocked(c)
		if not (_free(c) or bare or sell and _income_only(c) and S.grid.job_at(c) == ""):
			return false
	for c: int in row:
		for n: int in S.grid.neighbours(c):
			if row.has(n) or S.grid.is_empty(n):
				continue
			var id: String = S.grid.machine_at(n)
			if id == "vault" or S.grid.job_at(n) != "" or MachineDB.is_heat_support(id):
				continue
			if sell and _income_only(n):
				continue
			return false
	return true


## The player's own memory, to play on from later (core_journey.gd,
## LODEWORKS_CORE_KEEP / _FROM).
func state() -> Dictionary:
	return {"t": t, "events": events, "seen": _seen, "dropped": _dropped,
		"dropped_depth": _dropped_depth, "bare": _bare, "touched": _touched,
		"stuck": _stuck_since, "line": _line, "history": _history, "shaft": shaft,
		"doctrine": doctrine}


func restore(d: Dictionary) -> void:
	t = float(d["t"])
	events = d["events"]
	_seen = d["seen"]
	_dropped = _int_keys(d["dropped"])
	_dropped_depth = int(d["dropped_depth"])
	_bare = _int_keys(d["bare"])
	_touched = _int_keys(d["touched"])
	_stuck_since = _int_keys(d["stuck"])
	_line = _int_keys(d["line"])
	_history = d["history"]
	shaft = int(d.get("shaft", 1))
	doctrine = String(d.get("doctrine", doctrine))


## JSON brings a Dictionary's int keys back as strings.
func _int_keys(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d:
		out[int(k)] = d[k]
	return out


## The driver skipped `dt` seconds of a credit-only wait, `earned` credits
## in it: the player's own clocks move with it, so the skip is not time a
## repair waited for, and the income it measures is unchanged.
func fast_forwarded(dt: float, earned: float) -> void:
	for e: Array in _history:
		e[0] = float(e[0]) + dt
		e[1] = float(e[1]) + earned
	for k: int in _touched:
		_touched[k] = float(_touched[k]) + dt
	for k: int in _stuck_since:
		_stuck_since[k] = float(_stuck_since[k]) + dt


## --- what the player has, as numbers ------------------------------------------------

## Credits a second over the last minute of play.
var _history: Array = []


func rate() -> float:
	_history.append([t, float(S.lifetime_credits)])
	while _history.size() > 1 and t - float(_history[0][0]) > 60.0:
		_history.pop_front()
	var span: float = t - float(_history[0][0])
	return 0.0 if span <= 0.0 else (float(S.lifetime_credits) - float(_history[0][1])) / span


func snapshot() -> Dictionary:
	var open: Array = []
	for st: Dictionary in S.core_status():
		if not bool(st["met"]):
			open.append(_req_text(st))
	var research_left: int = 0
	for id: String in Economy.TREE_ORDER:
		research_left += maxi(S.research_cap(id) - S.upgrade_level(id), 0)
	var upgrades_left: int = 0
	for id: String in MachineDB.ORDER:
		if S.is_unlocked(id) and MachineDB.has_levels(id):
			upgrades_left += maxi(S.machine_level_cap() - S.machine_level(id), 0)
	var locked: int = 0
	for id: String in MachineDB.ORDER:
		if not S.is_unlocked(id):
			locked += 1
	return {"t": t, "core": S.core_level, "rate": rate(), "depth": S.depth, "machines": S.grid.cells.size(),
		"lifetime": S.lifetime_credits, "stock": S.stock.duplicate(), "store": S.stock_cap(),
		"levels": S.machine_levels.duplicate(), "research": S.upgrade_levels.duplicate(),
		"open": open, "research_left": research_left, "upgrades_left": upgrades_left,
		"locked": locked, "strata_left": S.depth_cap() - S.depth,
		"contracts": S.contracts_lifetime, "research_banked": S.research, "working": _working_all(),
		"hot": _hot(), "held": CoreLevels.holding_back(S)["why"], "doctrine": S.doctrine,
		"deep": _deep_units(), "research_per_s": S.sim.last_research, "spend": _take_spend()}


func _take_spend() -> Dictionary:
	var out: Dictionary = spend
	spend = {}
	return out


## The machines past their tolerance, each with what stands beside it:
## what holds the stability row back.
func _hot() -> Array:
	var out: Array = []
	for cell: int in S.grid.cells:
		if S.sim.overheated_at(cell):
			var nb: Array = []
			for n: int in S.grid.neighbours(cell):
				if S.grid.machine_at(n) != "":
					nb.append(S.grid.machine_at(n))
			out.append("%s@%s%s beside %s" % [S.grid.machine_at(cell), str(Grid.xy(cell)),
				" (plan)" if _reserved(cell) else "", ",".join(nb)])
	return out


## Machines of each producing type at their working heat.
func _working_all() -> Dictionary:
	var out: Dictionary = {}
	for id: String in ["drill", "crusher", "smelter", "press", "assembler", "lab"]:
		var n: int = _working(id)
		if n > 0:
			out[id] = n
	# The deep chain's makers among them, by job.
	for job: String in ["crystal", "alloy", "sheet", "parts", "frame"]:
		var k: int = 0
		var placed: int = 0
		for cell: int in S.grid.cells:
			if S.grid.job_at(cell) != job:
				continue
			placed += 1
			if S.sim.status_of(cell) == Simulation.Status.RUNNING \
					and S.sim.heat_efficiency_at(cell) >= CoreLevels.WORKING_HEAT:
				k += 1
		if placed > 0:
			out[job] = "%d/%d" % [k, placed]
	return out


func _req_text(st: Dictionary) -> String:
	var r: Array = st["req"]
	var name: String = ["credits", "stock", "working", "machine", "depth", "research", "serves",
		"stable", "overdrive", "doctrine"][int(r[0])]
	if r.size() > 2:
		var what: String = String(MachineDB.RES_NAME[int(r[1])]) if int(r[0]) == CoreLevels.Req.STOCK else str(r[1])
		name += " " + what
	# What stands in a level's or a step's way: the reason the row waits.
	var why: String = ""
	match int(r[0]):
		CoreLevels.Req.MACHINE:
			why = S.machine_upgrade_blocker(String(r[1]))
		CoreLevels.Req.OVERDRIVE:
			why = S.overdrive_blocker(String(r[1]))
	return "%s %s/%s%s" % [name, Economy.fmt(float(st["have"])), Economy.fmt(float(st["need"])),
		" (%s)" % why if why != "" else ""]
