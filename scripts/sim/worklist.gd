class_name Worklist
extends RefCounted

## What to do now, in order: the answer to "what next?" one tap away.
##
## The game already shows each of these on its own -- the warning key's
## count, Descend's glow, the Research key's number, the tray's bright and
## dim keys, the green tiles while placing. After the tutorial nothing put
## them in one place, in the order that matters; this does. It only points:
## every line opens something the player could already open, and nothing
## here changes a number of the economy (docs/GAP-AUDIT.md B-1, from the
## ranked suggestion list in docs/research/clash-ux.md 10.2.2).
##
## The order is fixed, so the same board always gives the same list:
##   1. machines in trouble             (the warning key's own count)
##   2. the Core can grow               (Sim.can_upgrade_core)
##   3. the way down is open            (Sim.can_descend)
##   4. what the Core's next level still needs, first of its rows
##   5. a machine level that can be bought, the one the Core asks for first
##   6. research that can be bought     (the Research key's own count)
##   7. a collapse that opens research  (the Collapse card's own rule)
##   8. a machine unlocked but never built, first of the tray's order
##   9. a step further along the chain than any that works now, where it
##      would be fed, with an empty tile beside it for a Vault
##  10. the furthest step of the chain that would work on some empty tile
##      right now (Simulation.links_if_placed), affordable, one line
##  11. otherwise: how much is left to the quota
## So a player coming back finds several things to work on at once -- the
## Core's next condition, a machine level, research, the chain -- the way a
## base-builder keeps its builders and its laboratory busy side by side.
## At most MAX lines.

const MAX := 5

## Research lines the game does not offer yet (see main.HIDDEN_RESEARCH).
const HIDDEN := ["blueprint_slots"]


## The list for this shaft: [{"kind", ...}], in the order above.
## kind "problems": n; "core_grow": level; "descend": stratum; "core_need": st
## (a CoreLevels.status row); "upgrade": id, level; "research": n; "collapse": cores,
## lines; "first": id; "extend": id, feeder, cell, outlet; "place": id,
## cells; "quota": missing credits.
static func of(state: Object) -> Array:
	var out: Array = []
	var sim: Simulation = state.get("sim")
	var grid: Grid = state.get("grid")
	if sim == null or grid == null or not bool(state.get("core_online")):
		return out
	var p: Dictionary = sim.problem_counts()
	var trouble: int = int(p["starved"]) + int(p["blocked"]) + int(p["thermal"])
	if trouble > 0:
		out.append({"kind": "problems", "n": trouble})
	var core: bool = state.has_method("core_status")
	if core and bool(state.call("can_upgrade_core")):
		out.append({"kind": "core_grow", "level": int(state.get("core_level")) + 1})
	if bool(state.call("can_descend")):
		out.append({"kind": "descend", "stratum": int(state.get("depth")) + 1})
	if core:
		var need: Dictionary = core_need(state)
		if not need.is_empty():
			out.append({"kind": "core_need", "st": need})
		var up: String = upgrade_ready(state)
		if up != "":
			out.append({"kind": "upgrade", "id": up,
				"level": int(state.call("machine_level", up)) + 1})
	var ready: int = research_ready(state)
	if ready > 0:
		out.append({"kind": "research", "n": ready})
	if bool(state.call("can_collapse")):
		var opens: Array[String] = cores_open(state, int(state.call("pending_cores")))
		if not opens.is_empty():
			out.append({"kind": "collapse", "cores": int(state.call("pending_cores")),
				"lines": opens})
	var unlocked: Array = state.get("unlocked")
	for id: String in MachineDB.ORDER:
		if out.size() >= MAX:
			break
		if unlocked.has(id) and grid.count_of(id) == 0 and bool(state.call("can_afford", id)):
			out.append({"kind": "first", "id": id})
			break
	var best: Dictionary = best_placement(state)
	var ext: Dictionary = extension(state, best)
	if not ext.is_empty():
		# It names the same machine better than "build your first" would.
		out = out.filter(func(e: Dictionary) -> bool:
			return not (String(e["kind"]) == "first" and String(e["id"]) == String(ext["id"])))
		if out.size() < MAX:
			out.append(ext)
	if not best.is_empty() and out.size() < MAX:
		var dup: bool = false
		for e: Dictionary in out:
			if String(e.get("id", "")) == String(best["id"]):
				dup = true
		if not dup:
			out.append({"kind": "place", "id": best["id"], "cells": best["cells"]})
	if out.is_empty():
		var missing: float = maxf(float(state.call("quota")) - float(state.get("credits")), 0.0)
		out.append({"kind": "quota", "missing": missing})
	return out.slice(0, MAX)


## The first of the Core's next-level rows still open that the player can
## work on now -- its machine found, or the Lab for research -- leaving
## credits to last and the depth to the Descend and quota lines. {} when
## nothing is open yet: early on, the way down is the Core's next step.
static func core_need(state: Object) -> Dictionary:
	if bool(state.call("can_upgrade_core")):
		return {}
	var credits: Dictionary = {}
	var deeper: bool = false
	for st: Dictionary in state.call("core_status"):
		if bool(st["met"]):
			continue
		var r: Array = st["req"]
		match int(r[0]):
			CoreLevels.Req.CREDITS:
				credits = st
			CoreLevels.Req.DEPTH:
				deeper = true
			CoreLevels.Req.STOCK:
				if bool(state.call("is_unlocked", CoreLevels.producer_of(int(r[1])))):
					return st
			CoreLevels.Req.MACHINE:
				var ok: bool = bool(state.call("is_unlocked", String(r[1])))
				for res: int in MachineDB.level_materials(int(state.call("machine_level", String(r[1]))) + 1):
					ok = ok and bool(state.call("is_unlocked", CoreLevels.producer_of(res)))
				if ok:
					return st
			CoreLevels.Req.RESEARCH:
				if bool(state.call("is_unlocked", "lab")):
					return st
			CoreLevels.Req.WORKING, CoreLevels.Req.SERVES:
				if bool(state.call("is_unlocked", String(r[1]))):
					return st
			_:
				return st
	return {} if deeper else credits


## A machine type whose next level can be bought now: one the Core's next
## level asks for first, then the Vault (the store), then the tray's order.
static func upgrade_ready(state: Object) -> String:
	var order: Array[String] = []
	for st: Dictionary in state.call("core_status"):
		if int(st["req"][0]) == CoreLevels.Req.MACHINE and not bool(st["met"]):
			order.append(String(st["req"][1]))
	order.append("vault")
	for id: String in MachineDB.ORDER:
		order.append(id)
	for id: String in order:
		if bool(state.call("can_upgrade_machine", id)):
			return id
	return ""


## Research lines that can be bought now, as the Research key counts them.
static func research_ready(state: Object) -> int:
	var n: int = 0
	for id: String in Economy.TREE_ORDER:
		if not HIDDEN.has(id) and bool(state.call("can_buy_upgrade", id)):
			n += 1
	return n


## Research lines whose next level needs more Cores than the player has, and
## no more than they would have with `gained` more (the Collapse card's row).
static func cores_open(state: Object, gained: int) -> Array[String]:
	var out: Array[String] = []
	var cores: int = int(state.get("cores"))
	for id: String in Economy.TREE_ORDER:
		if HIDDEN.has(id):
			continue
		var lvl: int = int(state.call("upgrade_level", id))
		if lvl >= int(Economy.RESEARCH_TREE[id]["max"]):
			continue
		var need: int = int(Economy.upgrade_cost(id, lvl)["cores"])
		if need > cores and need <= cores + gained:
			out.append(id)
	return out


## A step further along the chain than `best` (best_placement; any step
## when that is empty or only a Vault) that works on no tile now but would
## be fed on one with an empty tile beside it -- the step
## there, a Vault beside it: {"kind": "extend", "id", "feeder", "cell",
## "outlet"}, or {}. Placing only where a machine works right now can build
## Drills and Vaults in a checkerboard, and on that board no tile touches
## both, so a Crusher works nowhere and the list would never name it
## (docs/GAP-AUDIT.md B-1b, found by tools/journey_lab.gd).
static func extension(state: Object, best: Dictionary) -> Dictionary:
	var after: int = -1
	if not best.is_empty() and not (MachineDB.get_machine(String(best["id"]))
			.get("tags", []) as Array).has("sink"):
		after = MachineDB.ORDER.find(String(best["id"]))
	var grid: Grid = state.get("grid")
	var unlocked: Array = state.get("unlocked")
	var depth: int = int(state.get("max_depth"))
	var credits: float = float(state.get("credits"))
	var vault: float = MachineDB.cost_for("vault", grid.count_of("vault"))
	for k in range(MachineDB.ORDER.size() - 1, after, -1):
		var id: String = String(MachineDB.ORDER[k])
		var m: Dictionary = MachineDB.get_machine(id)
		var ins: Dictionary = m["inputs"]
		if not unlocked.has(id) or ins.is_empty() or (m["outputs"] as Dictionary).is_empty():
			continue
		if credits < MachineDB.cost_for(id, grid.count_of(id)) + vault:
			continue
		for cell: int in BuildArea.cells(depth):
			if not grid.is_empty(cell) or bool(state.call("is_blocked", cell)):
				continue
			var feeder: String = ""
			for n: int in grid.bridged_machines(cell):
				var nm: Dictionary = MachineDB.get_machine(grid.machine_at(n))
				for res: int in (nm.get("outputs", {}) as Dictionary):
					if ins.has(res):
						feeder = grid.machine_at(n)
			if feeder == "":
				continue
			for u: int in grid.neighbours(cell):
				if grid.is_empty(u) and BuildArea.is_open(u, depth) \
						and not bool(state.call("is_blocked", u)):
					return {"kind": "extend", "id": id, "feeder": feeder, "cell": cell,
						"outlet": u}
	return {}


## The affordable machine furthest along the chain (the tray's order) that
## would work -- be fed and hand its work on -- on at least one empty tile of
## the yard right now, on how many, and the first of them in reading order:
## {"id", "cells", "cell"}, or {}. Every step pays more than the one before
## it (Codex, "Every step pays more"), so the deeper step is the one worth
## pointing at. A Vault is where the chain ends, not a step along it: it
## "works" beside anything, so ranked by the tray's order it beat the Crusher
## every time; it is named only when nothing else would work. Support
## machines work by standing beside others and are not ranked here. `state`
## is Sim, or anything with the same fields (tools/journey_lab.gd plays a
## player who follows this list).
static func best_placement(state: Object) -> Dictionary:
	var grid: Grid = state.get("grid")
	var sim: Simulation = state.get("sim")
	var unlocked: Array = state.get("unlocked")
	var yard: Array[int] = BuildArea.cells(int(state.get("max_depth")))
	# The empty tiles next to a machine, once: the only ones anything could
	# work on. Then the chain from its far end, stopping at the first step
	# that works -- the answer -- instead of trying every machine on every
	# tile (40 ms on a half-built late yard).
	var open: Array[int] = []
	for cell: int in yard:
		if grid.is_empty(cell) and not bool(state.call("is_blocked", cell)) \
				and not grid.neighbour_machines(cell).is_empty():
			open.append(cell)
	var sink: Dictionary = {}
	for k in range(MachineDB.ORDER.size() - 1, -1, -1):
		var id: String = String(MachineDB.ORDER[k])
		if not unlocked.has(id) or not bool(state.call("can_afford", id)):
			continue
		var m: Dictionary = MachineDB.get_machine(id)
		var tags: Array = m["tags"]
		if (m["inputs"] as Dictionary).is_empty() and (m["outputs"] as Dictionary).is_empty() \
				and not tags.has("sink") and not tags.has("research"):
			continue
		if tags.has("sink") and not sink.is_empty():
			continue
		var n: int = 0
		var first: int = -1
		for cell: int in open:
			var l: Dictionary = sim.links_if_placed(cell, id)
			if bool(l["fed"]) and bool(l["delivers"]):
				if n == 0:
					first = cell
				n += 1
		if n > 0:
			if not tags.has("sink"):
				return {"id": id, "cells": n, "cell": first}
			sink = {"id": id, "cells": n, "cell": first}
	return sink
