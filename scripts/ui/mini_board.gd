extends Control

## A two-to-five tile board that is actually running.
##
## Every Codex page shows one of these instead of a paragraph. It is not a
## picture of a factory: it is a `Simulation` with a real `Grid`, ticking, with
## the same machine sprites and the same status colours the real board uses. Put a Boiler next to a Smelter on a Codex page and the
## Smelter's status pip goes green and its progress bar speeds up, because that
## is what happens.
##
## This is the whole point of the Codex design. A help page that describes a
## rule can be wrong. A help page that runs the rule cannot.

const CELL := 64.0
const MARGIN := 6.0

var _grid: Grid
var _sim: Simulation
var _cells: Array = []
var _label_res: bool = true
var _accum: float = 0.0
var _sheet: Dictionary = {}


## `layout` is [[x, y, machine_id], ...] in a small local coordinate space.
func setup(layout: Array, ambient: float = 0.0) -> void:
	_cells = layout
	_grid = Grid.new()
	_grid.set_environment(ambient, MachineDB.HEAT_SPREAD)
	for e: Array in layout:
		_grid.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	_sim = Simulation.new(_grid, 1234)
	_sheet = IsoArt.sheet(IsoArt.sheet_name(Palette.theme(), 0))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Warm it so the page opens on a settled board rather than on a cold one
	# that looks broken for its first second.
	_sim.run_ticks(200)
	custom_minimum_size = _extent()
	queue_redraw()


func _extent() -> Vector2:
	var maxx: int = 1
	var maxy: int = 1
	for e: Array in _cells:
		maxx = maxi(maxx, int(e[0]) + 1)
		maxy = maxi(maxy, int(e[1]) + 1)
	return Vector2(float(maxx) * CELL + MARGIN * 2.0,
		float(maxy) * CELL + MARGIN * 2.0)


func _process(delta: float) -> void:
	if _sim == null:
		return
	_accum += delta
	while _accum >= Simulation.TICK_DT:
		_accum -= Simulation.TICK_DT
		_sim.tick()
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	for e: Array in _cells:
		var x: int = int(e[0])
		var y: int = int(e[1])
		var i: int = Grid.idx(x, y)
		var r := Rect2(MARGIN + float(x) * CELL, MARGIN + float(y) * CELL,
			CELL - 4.0, CELL - 4.0)
		# The floor slab, warmed by the cell's heat, and the machine standing
		# on it -- the same sprite as on the board.
		draw_rect(r, Color("5b4b3f").lerp(Palette.heat_color(_grid.heat_at(i)), 0.25), true)
		draw_rect(r, Color(0, 0, 0, 0.35), false, 1.5)
		var running: bool = _sim.status_of(i) == Simulation.Status.RUNNING
		var mod := Color.WHITE if running else Color(0.7, 0.7, 0.75)
		IsoArt.draw_machine_fit(self, r.grow(-2.0), String(e[2]), _sheet, mod)
		# The same status light as the real board, for the same reason.
		var st: int = _sim.status_of(i)
		var eff: float = _sim.heat_efficiency_at(i)
		var col: Color = Palette.status_color(st,
			eff < Simulation.THERMAL_WARNING, _sim.heat_delta_at(i))
		var p: float = CELL * 0.13
		draw_rect(Rect2(r.position.x + r.size.x - p - 4.0,
			r.position.y + 4.0, p, p), col, true)
		# And the cycle sweep, because a page where nothing moves teaches
		# nothing about a game whose whole subject is throughput.
		var bh: float = 4.0
		draw_rect(Rect2(r.position.x + 6.0, r.position.y + r.size.y - bh - 5.0,
			r.size.x - 12.0, bh), Palette.BG.lerp(Palette.LINE, 0.6), true)
		draw_rect(Rect2(r.position.x + 6.0, r.position.y + r.size.y - bh - 5.0,
			(r.size.x - 12.0) * _sim.progress_of(i), bh),
			Palette.ACCENT if st == Simulation.Status.RUNNING else Palette.ST_IDLE,
			true)

	# What is actually moving between them, drawn as the real board draws it.
	for t: Array in _sim.last_transfers:
		var a: Vector2i = Grid.xy(int(t[0]))
		var b: Vector2i = Grid.xy(int(t[1]))
		var mid := Vector2(
			MARGIN + (float(a.x) + float(b.x)) * 0.5 * CELL + CELL * 0.5 - 4.0,
			MARGIN + (float(a.y) + float(b.y)) * 0.5 * CELL + CELL * 0.5 - 4.0)
		draw_rect(Rect2(mid, Vector2(9, 9)), Palette.res_color(int(t[2])), true)


## What this little board is currently earning, for the page to print.
func rate_text() -> String:
	if _sim == null:
		return ""
	var m: Dictionary = Simulation.new(_grid, 1234).measure(8.0, 12.0)
	var c: float = float(m["credits_per_sec"])
	var r: float = float(m["research_per_sec"])
	if r > 0.0001:
		return "%s credits/s  ·  %.2f research/s" % [Economy.fmt(c), r]
	return "%s credits/s" % Economy.fmt(c)
