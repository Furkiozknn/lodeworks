class_name BuildArea
extends RefCounted

## How much of the board a shaft may build on: the yard.
##
## A new shaft does not hand the player all seventy tiles. It opens a small
## yard beside the Factory Core and widens it as the shaft goes deeper, so the
## first screen says "start here" rather than "here is everything", and every
## stratum visibly gives the factory more room. The yard grows from the
## board's left corner, where the Core stands.
##
## After the first collapse the whole board is open from the start: a player
## who has been deep once does not need walking through the first strata
## again, and the prestige loop keeps the pace it was balanced at.
##
## It is a rule about where a new machine may go, and only that. A machine
## already standing outside the yard -- from a save made before the yard
## existed -- keeps working, and can be sold or moved inward.

## The yard at each stratum, as [columns, rows], counted from the Core's
## corner of the board: columns from x = 0, rows up from the bottom row.
##
## Sized so that it never holds a player back, only shows them where to
## build: each step is at least as many tiles as the journey lab's competent
## player has built by the time they descend from that stratum (14, 31, 42,
## 53 and 64 machines -- tools/journey_lab.gd with LODEWORKS_NO_YARD=1).
const STEPS := [[4, 4], [5, 7], [6, 8], [7, 8], [7, 10]]


static func size_at(max_depth: int, collapses: int) -> Vector2i:
	if collapses > 0:
		return Vector2i(Grid.W, Grid.H)
	var s: Array = STEPS[clampi(max_depth, 0, STEPS.size() - 1)]
	return Vector2i(int(s[0]), int(s[1]))


static func is_open(cell: int, max_depth: int, collapses: int) -> bool:
	var size: Vector2i = size_at(max_depth, collapses)
	var p: Vector2i = Grid.xy(cell)
	return p.x < size.x and p.y >= Grid.H - size.y


static func is_whole_board(max_depth: int, collapses: int) -> bool:
	return size_at(max_depth, collapses) == Vector2i(Grid.W, Grid.H)


## The stratum a first shaft opens `cell` at.
static func opens_at(cell: int) -> int:
	for d in range(STEPS.size()):
		if is_open(cell, d, 0):
			return d
	return STEPS.size() - 1


## Every cell outside the yard, as a set -- the shape Strata.blocked_cells
## uses, so a measurement tool can treat both alike.
static func closed_cells(max_depth: int, collapses: int) -> Dictionary:
	var out: Dictionary = {}
	for i in range(Grid.W * Grid.H):
		if not is_open(i, max_depth, collapses):
			out[i] = true
	return out


## The yard's four corners on the slab, in board cells: back, right, front,
## left, like Iso.board_corners().
static func corners(max_depth: int, collapses: int) -> Array[Vector2i]:
	var size: Vector2i = size_at(max_depth, collapses)
	var y0: int = Grid.H - size.y
	return [Vector2i(0, y0), Vector2i(size.x, y0), Vector2i(size.x, Grid.H),
		Vector2i(0, Grid.H)]
