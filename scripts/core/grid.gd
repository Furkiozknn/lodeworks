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
	for k in range(_heat.size()):
		_heat[k] += ambient_heat
	_heat_dirty = false


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


## Sum of amplify from neighbours that carry the tag. Returned as a multiplier
## so the sim can apply it without knowing the rule.
func amplify_at(i: int) -> float:
	var total: float = 0.0
	for n in neighbour_machines(i):
		var m: Dictionary = MachineDB.get_machine(machine_at(n))
		if m.has("amplify"):
			total += float(m["amplify"])
	return 1.0 + total


func duplicate_chance_at(i: int) -> float:
	var best: float = 0.0
	for n in neighbour_machines(i):
		var m: Dictionary = MachineDB.get_machine(machine_at(n))
		if m.has("duplicate_chance"):
			# Chances do not stack additively: two Duplicators next to one
			# machine should be worse than spreading them out, so that the
			# board stays a layout problem.
			best = maxf(best, float(m["duplicate_chance"]))
	return best


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
