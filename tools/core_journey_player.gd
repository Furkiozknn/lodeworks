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
	S.stock = {}
	S.core_online = false
	S.unlocked.clear()
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
	if _seen.has(key):
		return
	_seen[key] = true
	events.append([t, what])


## One beat of decisions.
func act() -> void:
	var r: float = rate()
	if S.can_upgrade_core():
		S.upgrade_core()
		_event("core%d" % S.core_level, "Core level %d (earning %s/s)" % [S.core_level, Economy.fmt(r)])
	if S.can_descend():
		S.descend()
		_event("depth%d" % S.depth, "stratum %d" % S.depth)
	_research()
	var reserve: float = _follow_plans()
	_repair()
	var open: Array = S.core_status().filter(func(st: Dictionary) -> bool: return not bool(st["met"]))
	if reserve <= 0.0:
		for st: Dictionary in open:
			_pursue(st)
	# Saving for the Core: when what is left is bought with credits -- its
	# price, its machine levels, a bigger store -- spend nothing else.
	var buying: Array = [CoreLevels.Req.CREDITS, CoreLevels.Req.STOCK, CoreLevels.Req.MACHINE]
	if not open.is_empty() and open.all(func(st: Dictionary) -> bool: return buying.has(int(st["req"][0]))):
		for st: Dictionary in open:
			match int(st["req"][0]):
				CoreLevels.Req.CREDITS:
					reserve += float(st["need"])
				CoreLevels.Req.MACHINE:
					reserve += float(S.machine_upgrade_cost(String(st["req"][1]))["credits"])
				CoreLevels.Req.STOCK:
					if int(st["cap"]) < int(st["need"]):
						reserve += float(S.machine_upgrade_cost("vault")["credits"])
	_spare_upgrades()
	if S.credits > reserve:
		_grow()
	for id: String in S.machine_levels:
		_event("%s%d" % [id, int(S.machine_levels[id])], "%s level %d" % [id, int(S.machine_levels[id])])
	for id: String in S.upgrade_levels:
		_event("r%s%d" % [id, int(S.upgrade_levels[id])], "research %s %d" % [id, int(S.upgrade_levels[id])])
	for cell: int in S.grid.cells:
		var id: String = S.grid.machine_at(cell)
		_event("m" + id, "first " + id)


func _research() -> void:
	var want: Array[String] = []
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.RESEARCH and not bool(st["met"]):
			want.append(String(st["req"][1]))
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
			if not _fix_heat_of(id) and not _unblock(id) and S.grid.count_of(id) < int(st["need"]):
				_build_somewhere(id)
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
		CoreLevels.Req.SERVES:
			_place_support(String(r[1]), int(r[2]))
		CoreLevels.Req.STABLE:
			for cell: int in S.grid.cells:
				if S.sim.overheated_at(cell):
					if _fix_heat(cell, false):
						return
					# Nothing can cool it where it stands: a player takes it
					# away, unless a plan needs it there, and leaves the tile.
					if not _reserved(cell):
						S.sell(cell)
						_bare[cell] = true
						return
			# Nothing overheats: more machines at their working heat.
			for cell: int in S.sim.problem_cells():
				if S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT and _fix_heat(cell, false):
					return


## Machine levels past what the Core asks for, from what the store can
## spare after the Core's own materials.
func _spare_upgrades() -> void:
	var keep: Dictionary = {}
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.STOCK:
			keep[int(st["req"][1])] = int(st["need"])
	for id: String in ["vault", "smelter", "crusher", "drill", "press", "assembler", "lab"]:
		if not S.can_upgrade_machine(id):
			continue
		var cost: Dictionary = S.machine_upgrade_cost(id)
		var ok: bool = S.credits >= float(cost["credits"]) * 1.5
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
		var id: String = S.grid.machine_at(n)
		if id in ["drill", "vault", "crusher"] and not _reserved(n) \
				and not S.sim.core_touching().has(n):
			S.sell(n)
			return n
	return -1


## The tiles of the plans the Core's level has reached: kept for them,
## whatever else the player builds. A later plan's tiles are free until then.
func _reserved(cell: int) -> bool:
	var core: int = int(_plan_cells.get(cell, 999))
	if _plan_cells.is_empty():
		for plan: Dictionary in PLANS:
			for e: Array in plan["cells"]:
				_plan_cells[Grid.idx(int(e[0]), int(e[1]))] = int(plan["core"])
		core = int(_plan_cells.get(cell, 999))
	return core <= S.core_level


## Tiles left bare on purpose: something overheated there.
var _bare: Dictionary = {}
## When the player last changed the heat round a tile: a change is given
## SETTLE seconds to show before the same tile is touched again, or a fix
## for one machine and a fix for its neighbour undo each other forever.
var _touched: Dictionary = {}
const SETTLE := 300.0


func _free(cell: int) -> bool:
	return S.grid.is_empty(cell) and S.is_open(cell) and not S.is_blocked(cell) \
		and not _reserved(cell) and not _bare.has(cell)


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
		var id: String = S.grid.machine_at(cell)
		if id != "" and (MachineDB.get_machine(id).get("outputs", {}) as Dictionary).has(res):
			n += 1
	return n


## A chain that ends in a maker of `res` touching the Core.
func _feed_core(res: int) -> bool:
	var maker: String = CoreLevels.producer_of(res)
	if maker == "" or not S.is_unlocked(maker):
		return false
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
	if S.credits < _chain_cost(maker):
		return false
	if best < 0:
		# Every tile touching the Core is taken: one built for income alone
		# makes way.
		for cell: int in S.sim.core_touching():
			if _income_only(cell):
				S.sell(cell)
				best = cell
				break
	if best < 0:
		return false
	return _chain(maker, best, 0)


## What a maker and the chain behind it cost, roughly: a player looks at the
## prices before starting a line they cannot finish.
func _chain_cost(id: String) -> float:
	var m: Dictionary = MachineDB.get_machine(id)
	var total: float = S.cost_of(id)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research"):
		ins = {MachineDB.Res.INGOT: 1}
	for res: int in ins:
		total += _chain_cost(CoreLevels.producer_of(res)) * float(clampi(int(ins[res]), 1, 2))
	if MachineDB.heat_liking(id) > 0 and S.is_unlocked("boiler"):
		total += S.cost_of("boiler")
	return total


## A machine starved for an input gets a feeder on a free tile beside it; one
## blocked, with nowhere for its output to go, a Vault.
func _repair() -> void:
	for cell: int in S.grid.cells:
		if S.sim.status_of(cell) == Simulation.Status.BLOCKED:
			if S.credits < S.cost_of("vault") or S.grid.machine_at(cell) == "drill":
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
		var id: String = S.grid.machine_at(cell)
		var m: Dictionary = MachineDB.get_machine(id)
		if (m.get("tags", []) as Array).has("sink"):
			continue
		var ins: Dictionary = m.get("inputs", {})
		if (m.get("tags", []) as Array).has("research"):
			ins = {MachineDB.Res.INGOT: 1}
		for res: int in ins:
			var maker: String = CoreLevels.producer_of(res)
			if S.credits < _chain_cost(maker):
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
				_chain(maker, spots[0], 1)
				return


## Machine `id` on `cell`, and whatever it needs to be fed behind it.
func _chain(id: String, cell: int, depth: int) -> bool:
	if depth > 6 or not S.try_place(cell, id):
		return false
	var m: Dictionary = MachineDB.get_machine(id)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research"):
		ins = {MachineDB.Res.INGOT: 1}
	for res: int in ins:
		var fed: bool = false
		for n: int in S.grid.bridged_machines(cell):
			if (MachineDB.get_machine(S.grid.machine_at(n)).get("outputs", {}) as Dictionary).has(res):
				fed = true
		if fed:
			continue
		var maker: String = CoreLevels.producer_of(res)
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
			_chain(maker, spots[0], depth + 1)
	# A warmth-loving maker gets a Boiler beside it.
	if MachineDB.heat_liking(id) > 0 and S.is_unlocked("boiler"):
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


## A Drill, Vault or Crusher built for income alone: no plan's tile.
func _income_only(cell: int) -> bool:
	return S.grid.machine_at(cell) in ["drill", "vault", "crusher"] and not _reserved(cell)


## A Lab where refined material reaches it.
func _build_lab() -> void:
	if not S.is_unlocked("lab") or not S.can_afford("lab"):
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
	var m: Dictionary = MachineDB.get_machine(S.grid.machine_at(cell))
	var warm: bool = S.grid.heat_at(cell) < float(m.get("heat_optimum", 0.0))
	var wrong: String = "coolant" if warm else "boiler"
	for n: int in S.grid.neighbours(cell):
		if may_remove and S.grid.machine_at(n) == wrong:
			S.sell(n)
			_dropped[n] = true
			return true
	var id: String = "boiler" if warm else "coolant"
	if not S.is_unlocked(id) or not S.can_afford(id):
		return false
	var spot: int = _room_near(cell)
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


## What "What now?" names, off the Core's kept sides.
func _grow() -> void:
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
		"locked": locked, "strata_left": S.depth_cap() - S.depth}


func _req_text(st: Dictionary) -> String:
	var r: Array = st["req"]
	var name: String = ["credits", "stock", "working", "machine", "depth", "research", "serves",
		"stable"][int(r[0])]
	if r.size() > 2:
		var what: String = String(MachineDB.RES_NAME[int(r[1])]) if int(r[0]) == CoreLevels.Req.STOCK else str(r[1])
		name += " " + what
	return "%s %s/%s" % [name, Economy.fmt(float(st["have"])), Economy.fmt(float(st["need"]))]
