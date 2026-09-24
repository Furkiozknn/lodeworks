class_name BuildArea
extends RefCounted

## Where on the 44 x 44 board a shaft may build: the Factory Core in the
## middle, and the yard round it.
##
## The Core stands on a 4 x 4 block at the centre of the board (CORE), the
## way a base-building map puts its main building. Nothing is built on it.
## Round it lies the yard: every tile within `radius_at(depth)` tiles of the
## Core. A new shaft opens a one-tile ring -- twenty tiles -- and the ring
## widens as the shaft goes down, so the factory visibly grows outwards from
## its Core until, deep enough, the whole board is open.
## The rest of the board is ground the factory has not reached yet.
##
## It is a rule about where a new machine may go, and only that. A machine
## already standing outside the yard -- from a save made before the yard
## existed -- keeps working, and can be sold or moved inward.

## The Core's block, in board cells.
const CORE := Rect2i(20, 20, 4, 4)
## How far the yard can reach: to the edge of the board.
const MAX_RADIUS := 20


## How many tiles beyond the Core the yard reaches at this stratum. The same
## for every shaft, the first and every one after a collapse.
##
## One ring at the start (20 tiles), two at stratum 1 (48), three at 2
## (84), four at 4 (128), five at 7 (180), then one more every EXTRA_EVERY
## strata from stratum 10. Going down pays in ground as well as machines,
## so the middle of a shaft always has somewhere new to build. The quota
## climbs faster than the room (`Strata.quota_for`), which is what makes a
## deep stratum take longer than a shallow one (docs/AUDIT.md, "Descend:
## the pace").
const RINGS := [1, 2, 3, 3, 4, 4, 4, 5, 5, 5]
const EXTRA_EVERY := 3

static func radius_at(max_depth: int) -> int:
	var d: int = maxi(max_depth, 0)
	if d < RINGS.size():
		return int(RINGS[d])
	return mini(6 + (d - RINGS.size()) / EXTRA_EVERY, MAX_RADIUS)


static func is_core(cell: int) -> bool:
	return CORE.has_point(Grid.xy(cell))


## How many tiles `cell` is from the Core (1 for the ring touching it).
static func reach(cell: int) -> int:
	var p: Vector2i = Grid.xy(cell)
	var dx: int = maxi(maxi(CORE.position.x - p.x, p.x - (CORE.end.x - 1)), 0)
	var dy: int = maxi(maxi(CORE.position.y - p.y, p.y - (CORE.end.y - 1)), 0)
	return maxi(dx, dy)


static func is_open(cell: int, max_depth: int, _collapses: int = 0) -> bool:
	return not is_core(cell) and reach(cell) <= radius_at(max_depth)


## The yard's side, in tiles: the Core and the ring round it.
static func size_at(max_depth: int, _collapses: int = 0) -> Vector2i:
	var r: int = radius_at(max_depth)
	return Vector2i(mini(CORE.size.x + 2 * r, Grid.W), mini(CORE.size.y + 2 * r, Grid.H))


static func is_whole_board(max_depth: int, _collapses: int = 0) -> bool:
	return radius_at(max_depth) >= MAX_RADIUS


## The stratum at which the yard reaches `cell`.
static func opens_at(cell: int) -> int:
	var r: int = reach(cell)
	var d: int = 0
	while radius_at(d) < r and d < 1000:
		d += 1
	return d


## Every cell outside the yard, as a set -- the shape Strata.blocked_cells
## uses, so a measurement tool can treat both alike.
static func closed_cells(max_depth: int, _collapses: int = 0) -> Dictionary:
	var out: Dictionary = {}
	for i in range(Grid.W * Grid.H):
		if not is_open(i, max_depth):
			out[i] = true
	return out


## The yard's square, as its four corners in board edge coordinates: back,
## right, front, left, like Iso.board_corners().
static func corners(max_depth: int, _collapses: int = 0) -> Array[Vector2i]:
	var r: int = radius_at(max_depth)
	var a := Vector2i(maxi(CORE.position.x - r, 0), maxi(CORE.position.y - r, 0))
	var b := Vector2i(mini(CORE.end.x + r, Grid.W), mini(CORE.end.y + r, Grid.H))
	return [a, Vector2i(b.x, a.y), b, Vector2i(a.x, b.y)]


## The yard's cells, nearest the Core first: what the tutorial points at.
static func cells(max_depth: int) -> Array[int]:
	var out: Array[int] = []
	var c: Array[Vector2i] = corners(max_depth)
	for y in range(c[0].y, c[2].y):
		for x in range(c[0].x, c[2].x):
			var i: int = Grid.idx(x, y)
			if is_open(i, max_depth):
				out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool: return reach(a) < reach(b))
	return out
