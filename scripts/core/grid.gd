class_name Grid
extends RefCounted

## The board, and the heat field over it.
##
## Deliberately dumb: it stores what is where and answers questions about
## neighbours and heat. It does not tick, does not move resources and does not
## know about money. The simulation does that, which is what makes both of them
## testable without a running game.

const W := 7
const H := 10

## cell index -> {id: String, buf_in: Dictionary, buf_out: Dictionary}
var cells: Dictionary = {}

## Cached heat per cell. Rebuilt on any placement change rather than per tick,
## because placement is rare and ticking is not.
var _heat: PackedFloat32Array = PackedFloat32Array()
var _heat_dirty: bool = true

## How many of each machine id are on the board -- drives the cost curve.
var owned: Dictionary = {}

## Set by the stratum. Ambient heat is added to every cell; spread controls how
## far a machine's own heat reaches. Both are what make the same layout behave
## differently at different depths, which is the whole point of descending.
var ambient_heat: float = 0.0
var heat_spread: float = MachineDB.HEAT_SPREAD


func _init() -> void:
	_heat.resize(W * H)


static func idx(x: int, y: int) -> int:
	return y * W + x


static func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < W and y >= 0 and y < H


static func xy(i: int) -> Vector2i:
	return Vector2i(i % W, i / W)


func is_empty(i: int) -> bool:
	return not cells.has(i)


func machine_at(i: int) -> String:
	var c: Variant = cells.get(i)
	return "" if c == null else String(c["id"])


func count_of(id: String) -> int:
	return int(owned.get(id, 0))


func place(i: int, id: String) -> bool:
	if i < 0 or i >= W * H:
		return false
	if not is_empty(i):
		return false
	if not MachineDB.exists(id):
		return false
	cells[i] = {"id": id, "buf_in": {}, "buf_out": {}}
	owned[id] = count_of(id) + 1
	_heat_dirty = true
	return true


func remove(i: int) -> String:
	if is_empty(i):
		return ""
	var id: String = machine_at(i)
	cells.erase(i)
	owned[id] = maxi(count_of(id) - 1, 0)
	_heat_dirty = true
	return id


## Moving is its own operation rather than remove+place because a move must not
## touch the cost curve -- rearranging a board you already paid for should be
## free, otherwise players stop experimenting and the game dies.
func move(from_i: int, to_i: int) -> bool:
	if is_empty(from_i) or not is_empty(to_i):
		return false
	if to_i < 0 or to_i >= W * H:
		return false
	cells[to_i] = cells[from_i]
	cells.erase(from_i)
	_heat_dirty = true
	return true


func neighbours(i: int) -> Array[int]:
	var p: Vector2i = xy(i)
	var out: Array[int] = []
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = p + d
		if in_bounds(n.x, n.y):
			out.append(idx(n.x, n.y))
	return out


## Occupied neighbours only -- the common case, and it keeps the sim loops tight.
func neighbour_machines(i: int) -> Array[int]:
	var out: Array[int] = []
	for n in neighbours(i):
		if not is_empty(n):
			out.append(n)
	return out


func _rebuild_heat() -> void:
	for k in range(_heat.size()):
		_heat[k] = 0.0
	for i: int in cells:
		var m: Dictionary = MachineDB.get_machine(machine_at(i))
		var h: float = float(m.get("heat_out", 0.0))
		if is_zero_approx(h):
			continue
		_heat[i] += h
		for n in neighbours(i):
			_heat[n] += h * heat_spread
	_relay_heat()
	for k in range(_heat.size()):
		_heat[k] += ambient_heat
	_heat_dirty = false


## Heat Pipes. Each pipe hands every neighbour the heat its OTHER neighbours
## spread into the pipe's tile, times the pipe's heat_relay. Leaving out the
## receiving neighbour's own contribution is what stops a Smelter heating
## itself through the pipe, and reading only the first-pass spread (never
## another pipe's relay) keeps it one hop, the same rule as material bridging:
## a player can see what a pipe connects without tracing a network.
##
## Ambient heat is added after this on purpose. The stratum warms every tile
## once; a pipe must not double it.
func _relay_heat() -> void:
	var extra: Dictionary = {}
	for p: int in cells:
		var pm: Dictionary = MachineDB.get_machine(machine_at(p))
		var relay: float = float(pm.get("heat_relay", 0.0))
		if relay <= 0.0:
			continue
		var into: Dictionary = {}
		for n in neighbours(p):
			if is_empty(n):
				continue
			var nm: Dictionary = MachineDB.get_machine(machine_at(n))
			into[n] = float(nm.get("heat_out", 0.0)) * heat_spread
		for n in neighbours(p):
			var carried: float = 0.0
			for src: int in into:
				if src != n:
					carried += float(into[src])
			if not is_zero_approx(carried):
				extra[n] = float(extra.get(n, 0.0)) + carried * relay
	for n: int in extra:
		_heat[n] += float(extra[n])


## What one machine does to the heat of every OTHER tile, as cell -> signed
## change. For an empty cell it is the machine id would be if placed there;
## for an occupied one, the machine already standing on it.
##
## Computed by rebuilding the field with and without it rather than by a
## formula, so the placement preview and the board run one rule and cannot
## disagree. That matters since the Heat Pipe: a pipe emits nothing, yet
## placing one changes its neighbours' heat, and an emitter placed beside a
## pipe warms tiles two steps away. Ownership counts and buffers are untouched.
func heat_contribution(cell: int, id: String = "") -> Dictionary:
	if cell < 0 or cell >= W * H:
		return {}
	if _heat_dirty:
		_rebuild_heat()
	var with_it: PackedFloat32Array
	var without: PackedFloat32Array
	if is_empty(cell):
		if not MachineDB.exists(id):
			return {}
		without = _heat.duplicate()
		cells[cell] = {"id": id, "buf_in": {}, "buf_out": {}}
		_rebuild_heat()
		with_it = _heat.duplicate()
		cells.erase(cell)
	else:
		with_it = _heat.duplicate()
		var saved: Dictionary = cells[cell]
		cells.erase(cell)
		_rebuild_heat()
		without = _heat.duplicate()
		cells[cell] = saved
	_heat_dirty = true
	var out: Dictionary = {}
	for k in range(with_it.size()):
		if k == cell:
			continue
		var change: float = with_it[k] - without[k]
		if absf(change) > 0.001:
			out[k] = change
	return out


## Heat in a cell, floored at zero. Negative heat from coolant cancels positive
## heat but never makes a cell "cold enough to be bad" -- there is no benefit to
## modelling cryogenics here and it would only add a second way to lose.
func heat_at(i: int) -> float:
	if _heat_dirty:
		_rebuild_heat()
	return maxf(_heat[i], 0.0)


func raw_heat_at(i: int) -> float:
	if _heat_dirty:
		_rebuild_heat()
	return _heat[i]


## --- support machines --------------------------------------------------------
##
## A support machine -- Amplifier, Duplicator, Condenser -- makes nothing. It
## spends a tile so that its neighbours do better. On a seventy-tile board
## that is a straight trade: it has to be worth more than the producer that
## would otherwise stand there.
##
## It measurably was not. `tools/strategy_lab.gd` scores the same eight-row
## chain with its fourteen spare tiles spent seven different ways, and with a
## flat per-neighbour effect the Boiler, Coolant Cell, Duplicator and Condenser
## rows all landed within 1% of leaving the tiles EMPTY, while simply building
## more chain won 24 of 32 conditions. Four of the twelve machines were
## decoration.
##
## The fix is one rule, and it is the rule the machines already implied:
##
##     **A support machine works harder the more machines it serves.**
##     Its effect is multiplied by 1 + 0.5 x (n - 1), where n is how many
##     working neighbours it has, up to four.
##
## So the same Amplifier is worth 0.35 producers in a corner and 3.5 in the
## middle of a chain, and *where you put it* becomes the decision instead of
## *whether you can afford it*. Nothing is hidden: the number is on the
## placement preview before the tile is bought and the Codex has a page that
## is a running board showing it.
##
## The receiving side deliberately does NOT scale the same way. Factorio spent
## 2.0 rebuilding its beacon maths because linear stacking made one layout
## correct everywhere and, in their words, made building "feel monotonous"
## (FFF #409). So stacked supports pay 1, 0.6, 0.36, 0.22 of their value --
## a second Amplifier on the same tile is worth having and a fourth is nearly
## not. The board stays a question.
const SERVE_BONUS := 0.5
const STACK_FALLOFF := 0.6


## Is this a support machine -- a tile that makes nothing and exists only for
## what it does to its neighbours?
func is_support(i: int) -> bool:
	var m: Dictionary = MachineDB.get_machine(machine_at(i))
	if m.is_empty():
		return false
	var tags: Array = m.get("tags", [])
	if tags.has("sink") or tags.has("research"):
		return false
	return (m.get("inputs", {}) as Dictionary).is_empty() \
		and (m.get("outputs", {}) as Dictionary).is_empty()


## Neighbours, plus whatever lies one tile beyond a support machine.
##
## **A support machine bridges a line rather than blocking it.** It still makes
## nothing and still holds nothing -- material does not stop in it, it passes
## straight through to the real consumer on the far side.
##
## This is the one rule change the audit produced, and it exists because the
## geometry made five of the twelve machines impossible to use. On a
## four-neighbour grid with no belts, every tile of a chain is the sole outlet
## of the tile upstream of it. So a Boiler, Coolant Cell, Amplifier,
## Duplicator or Condenser placed *inside* a chain starves whatever was
## feeding through it, and one placed *outside* a chain is next to Vaults and
## serves nothing. The two requirements were mutually exclusive, and the
## numbers said so plainly: in `tools/strategy_lab.gd` the Boiler, Coolant,
## Duplicator and Condenser rows all scored within 1% of leaving those tiles
## EMPTY, and an Amplifier row woven into a Crusher row scored 473 against 652
## for not building it, because it starved three Drills at the head of the
## chain and amplifying a starved machine returns nothing.
##
## Bridging makes the trade the one it was always described as: a support tile
## costs you a tile of *production*, not a tile of *connection*. "The first
## machine that is only worth placing because of what it is next to" becomes
## true instead of aspirational.
##
## Deliberately one hop. Two would turn the board into a graph problem and
## make "what is this machine connected to" impossible to see at a glance,
## which is the thing the whole visual design is for.
func bridged_machines(i: int) -> Array[int]:
	var out: Array[int] = []
	var seen: Dictionary = {i: true}
	for n in neighbour_machines(i):
		if seen.has(n):
			continue
		seen[n] = true
		if is_support(n):
			# Look through it, do not stop in it.
			for far in neighbour_machines(n):
				if not seen.has(far) and not is_support(far):
					seen[far] = true
					out.append(far)
			continue
		out.append(n)
	out.sort()
	return out


## How many working machines this support tile serves. Empty tiles, Vaults and
## other support machines do not count: an Amplifier boosting an Amplifier is
## not serving anything, and a Vault has no rate to raise.
func serves(i: int) -> int:
	var n: int = 0
	for j in neighbour_machines(i):
		var m: Dictionary = MachineDB.get_machine(machine_at(j))
		if m.is_empty():
			continue
		var tags: Array = m.get("tags", [])
		if tags.has("sink"):
			continue
		if m.has("amplify") or m.has("duplicate_chance"):
			continue
		if (m.get("outputs", {}) as Dictionary).is_empty() \
				and not tags.has("research"):
			continue
		n += 1
	return n


## What a support machine WOULD serve if one were placed on this tile.
##
## Same rule as `serves`, asked hypothetically, so the number the placement
## preview draws under the player's finger and the number the machine gets
## when they lift it are produced by one function and cannot disagree.
func serves_if_placed(i: int) -> int:
	if not is_empty(i):
		return serves(i)
	var n: int = 0
	for j in neighbour_machines(i):
		var m: Dictionary = MachineDB.get_machine(machine_at(j))
		if m.is_empty():
			continue
		var tags: Array = m.get("tags", [])
		if tags.has("sink") or m.has("amplify") or m.has("duplicate_chance"):
			continue
		if (m.get("outputs", {}) as Dictionary).is_empty() \
				and not tags.has("research"):
			continue
		n += 1
	return n


## The multiplier a support tile gets for serving `n` machines, as a pure
## function so the preview can ask about a tile that does not exist yet.
static func factor_for(n: int) -> float:
	if n <= 0:
		return 0.0
	return 1.0 + SERVE_BONUS * float(n - 1)


func serve_factor(i: int) -> float:
	return factor_for(serves(i))





## Stacked contributions with diminishing returns: sorted high to low, each
## one worth `STACK_FALLOFF` of the last.
func _stacked(values: Array) -> float:
	if values.is_empty():
		return 0.0
	values.sort()
	values.reverse()
	var total: float = 0.0
	var weight: float = 1.0
	for v: float in values:
		total += v * weight
		weight *= STACK_FALLOFF
	return total


## Amplify from neighbours that carry the tag, as a multiplier.
func amplify_at(i: int) -> float:
	var parts: Array = []
	for n in neighbour_machines(i):
		var m: Dictionary = MachineDB.get_machine(machine_at(n))
		if m.has("amplify"):
			var f: float = serve_factor(n)
			if f > 0.0:
				parts.append(float(m["amplify"]) * f)
	return 1.0 + _stacked(parts)


func duplicate_chance_at(i: int) -> float:
	var parts: Array = []
	for n in neighbour_machines(i):
		var m: Dictionary = MachineDB.get_machine(machine_at(n))
		if m.has("duplicate_chance"):
			var f: float = serve_factor(n)
			if f > 0.0:
				parts.append(float(m["duplicate_chance"]) * f)
	# Capped below 1.0: a guaranteed double would make the rest of the board
	# irrelevant, and an idle game with one correct tile is not a game.
	return minf(_stacked(parts), 0.9)


## Changing a stratum parameter invalidates the cached field.
func set_environment(ambient: float, spread: float) -> void:
	if is_equal_approx(ambient, ambient_heat) and is_equal_approx(spread, heat_spread):
		return
	ambient_heat = ambient
	heat_spread = spread
	_heat_dirty = true


func clear() -> void:
	cells.clear()
	owned.clear()
	_heat_dirty = true


func to_dict() -> Dictionary:
	var packed: Dictionary = {}
	for i: int in cells:
		packed[str(i)] = cells[i]["id"]
	return {"w": W, "h": H, "cells": packed}


func from_dict(d: Dictionary) -> void:
	clear()
	var packed: Dictionary = d.get("cells", {})
	for k: String in packed:
		var i: int = int(k)
		var id: String = String(packed[k])
		if i >= 0 and i < W * H and MachineDB.exists(id):
			place(i, id)
