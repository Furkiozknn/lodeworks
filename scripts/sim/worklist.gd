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
##   2. the way down is open            (Sim.can_descend)
##   3. research that can be bought     (the Research key's own count)
##   4. a collapse that opens research  (the Collapse card's own rule)
##   5. a machine unlocked but never built, first of the tray's order
##   6. the furthest step of the chain that would work on some empty tile
##      right now (Simulation.links_if_placed), affordable, one line
##   7. otherwise: how much is left to the quota
## At most MAX lines.

const MAX := 5

## Research lines the game does not offer yet (see main.HIDDEN_RESEARCH).
const HIDDEN := ["blueprint_slots"]


## The list for this shaft: [{"kind", ...}], in the order above.
## kind "problems": n; "descend": stratum; "research": n; "collapse": cores,
## lines; "first": id; "place": id, cells; "quota": missing credits.
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
	if bool(state.call("can_descend")):
		out.append({"kind": "descend", "stratum": int(state.get("depth")) + 1})
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
	var best: Dictionary = {}
	var sink: Dictionary = {}
	for id: String in MachineDB.ORDER:
		if not unlocked.has(id) or not bool(state.call("can_afford", id)):
			continue
		var m: Dictionary = MachineDB.get_machine(id)
		var tags: Array = m.get("tags", [])
		if (m["inputs"] as Dictionary).is_empty() and (m["outputs"] as Dictionary).is_empty() \
				and not tags.has("sink") and not tags.has("research"):
			continue
		var n: int = 0
		var first: int = -1
		for cell: int in yard:
			if not grid.is_empty(cell) or bool(state.call("is_blocked", cell)):
				continue
			if grid.neighbour_machines(cell).is_empty():
				continue
			var l: Dictionary = sim.links_if_placed(cell, id)
			if bool(l["fed"]) and bool(l["delivers"]):
				if n == 0:
					first = cell
				n += 1
		if n > 0:
			if tags.has("sink"):
				sink = {"id": id, "cells": n, "cell": first}
			else:
				best = {"id": id, "cells": n, "cell": first}
	return sink if best.is_empty() else best
