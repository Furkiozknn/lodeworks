class_name Iso
extends RefCounted

## The board's geometry in the world, and nothing else.
##
## A 2:1 isometric projection: the grid is turned 45 degrees and squashed to
## half height, so a cell is a diamond twice as wide as it is tall. Board x
## runs down-right on screen, board y runs down-left, and "further back" is
## simply a smaller x + y. The simulation's grid is untouched -- this only
## decides where on the screen a cell is drawn and which cell a finger is on.
##
## The board sits on a square slab of `slab_cells` cells, offset by
## `board_offset`. What is left of the slab around the 7 x 10 board is
## ground the factory does not own yet: drawn, locked, and deliberately not
## part of any rule.

const TW := 128.0
const TH := 64.0


static func _placement() -> Dictionary:
	return IsoArt.placement()


static func slab_cells() -> int:
	return int(_placement().get("slab_cells", 12))


static func board_offset() -> Vector2i:
	var o: Array = _placement().get("board_offset", [1, 1])
	return Vector2i(int(o[0]), int(o[1]))


## The world point the slab is centred on: the empty middle of the painting.
static func anchor() -> Vector2:
	var a: Array = IsoArt.layout().get("world", {}).get("anchor", [1920, 1015])
	return Vector2(float(a[0]), float(a[1]))


## Top corner of slab cell (0, 0).
static func origin() -> Vector2:
	return anchor() - Vector2(0.0, float(slab_cells()) * TH * 0.5)


static func slab_top(sx: float, sy: float) -> Vector2:
	return origin() + Vector2((sx - sy) * TW * 0.5, (sx + sy) * TH * 0.5)


static func cell_top(cell: int) -> Vector2:
	var p: Vector2i = Grid.xy(cell)
	var o: Vector2i = board_offset()
	return slab_top(float(p.x + o.x), float(p.y + o.y))


static func cell_center(cell: int) -> Vector2:
	return cell_top(cell) + Vector2(0.0, TH * 0.5)


## The four corners of a cell, clockwise from the top.
static func cell_points(cell: int) -> PackedVector2Array:
	var t: Vector2 = cell_top(cell)
	return PackedVector2Array([t, t + Vector2(TW * 0.5, TH * 0.5),
		t + Vector2(0.0, TH), t + Vector2(-TW * 0.5, TH * 0.5)])


## The board cell under a world point, or -1.
static func cell_at(world: Vector2) -> int:
	var local: Vector2 = world - origin()
	var u: float = local.x / (TW * 0.5)
	var v: float = local.y / (TH * 0.5)
	var o: Vector2i = board_offset()
	var x: int = int(floor((u + v) * 0.5)) - o.x
	var y: int = int(floor((v - u) * 0.5)) - o.y
	if not Grid.in_bounds(x, y):
		return -1
	return Grid.idx(x, y)


## The board's diamond, as its four corners: back, right, front, left.
static func board_corners() -> PackedVector2Array:
	var o: Vector2i = board_offset()
	return PackedVector2Array([
		slab_top(o.x, o.y), slab_top(o.x + Grid.W, o.y),
		slab_top(o.x + Grid.W, o.y + Grid.H), slab_top(o.x, o.y + Grid.H)])


static func board_rect() -> Rect2:
	var c: PackedVector2Array = board_corners()
	var r := Rect2(c[0], Vector2.ZERO)
	for p in c:
		r = r.expand(p)
	return r


static func slab_corners() -> PackedVector2Array:
	var n: float = float(slab_cells())
	return PackedVector2Array([slab_top(0, 0), slab_top(n, 0), slab_top(n, n),
		slab_top(0, n)])


## Back to front. A cell is drawn after every cell that is further back, so a
## machine in front covers the one behind it and never the other way round.
static func depth_order() -> Array[int]:
	var cells: Array[int] = []
	for i in range(Grid.W * Grid.H):
		cells.append(i)
	cells.sort_custom(func(a: int, b: int) -> bool:
		var pa: Vector2i = Grid.xy(a)
		var pb: Vector2i = Grid.xy(b)
		if pa.x + pa.y != pb.x + pb.y:
			return pa.x + pa.y < pb.x + pb.y
		return pa.x < pb.x)
	return cells


static func depth_key(cell: int) -> int:
	var p: Vector2i = Grid.xy(cell)
	return (p.x + p.y) * Grid.W + p.x


## --- pipes -------------------------------------------------------------------
##
## A pipe is drawn where, and only where, the simulation can move material:
## from a machine that makes something to a neighbour -- or the machine on the
## far side of a support tile -- that takes it. The rule is the one
## `Simulation._takers` applies, minus the momentary "is its buffer full",
## because a pipe is the connection and not the traffic on it.
## `test_a_pipe_is_drawn_exactly_where_the_simulation_can_move_material` holds the two to
## each other.

static func accepts(g: Grid, cell: int, res: int) -> bool:
	var m: Dictionary = MachineDB.get_machine(g.machine_at(cell))
	if m.is_empty():
		return false
	if (m.get("tags", []) as Array).has("sink"):
		return true
	return (m.get("inputs", {}) as Dictionary).has(res)


## [{from, to, res, path}] where path is the cells material passes through,
## source first -- two cells for neighbours, three through a support tile.
static func links(g: Grid) -> Array:
	var out: Array = []
	for cell: int in g.cells:
		var m: Dictionary = MachineDB.get_machine(g.machine_at(cell))
		if m.is_empty():
			continue
		for res: int in (m.get("outputs", {}) as Dictionary).keys():
			for n: int in g.bridged_machines(cell):
				if not accepts(g, n, res):
					continue
				var path: Array[int] = [cell]
				if not g.neighbours(cell).has(n):
					for s: int in g.neighbours(cell):
						if g.is_support(s) and g.neighbours(s).has(n):
							path.append(s)
							break
				path.append(n)
				out.append({"from": cell, "to": n, "res": res, "path": path})
	return out


## Every seam a pipe crosses, once, keyed "a-b" with a < b.
static func segments(link_list: Array) -> Dictionary:
	var seg: Dictionary = {}
	for l: Dictionary in link_list:
		var path: Array = l["path"]
		for i in range(path.size() - 1):
			var a: int = int(path[i])
			var b: int = int(path[i + 1])
			var key: String = "%d-%d" % [mini(a, b), maxi(a, b)]
			if not seg.has(key):
				seg[key] = {"a": mini(a, b), "b": maxi(a, b), "res": int(l["res"])}
	return seg
