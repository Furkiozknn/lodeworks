class_name GridView
extends Control

## The board. Everything here is drawn, and everything here is touched.
##
## Interaction, all one-thumb:
##
##   tap on empty    place the armed machine
##   tap on filled   select it; the detail goes in a sheet at the BOTTOM of the
##                   screen, never in a popover under the finger that is
##                   pointing at the thing being described
##   drag            move a machine — free, always, because the board is a
##                   layout puzzle and rearranging has to cost one gesture
##   long-press      sell
##
## Nothing inside a cell is tappable. At phone width a cell is about 48dp,
## which is exactly Android's minimum touch target, so any sub-element would be
## half the accessible floor and hidden under the fingertip. Every pip, bar and
## chip here is output only.
##
## What the board has to answer, at a glance, without opening anything:
##
##   what is this machine        silhouette family + colour + glyph
##   what does it make           resource chip, top-left
##   is it working               status pip, top-right, four states
##   how hard is it working      duty-cycle bar down the left edge
##   is it mid-cycle             progress bar along the bottom edge
##   where is material going     a mote travelling between the two cells
##   is it the wrong temperature thermal pip state, and the heat overlay
##   what will this placement do the adjacency preview while pressing
##
## Drawing is nearly all `draw_rect`. Godot's compatibility renderer batches
## rects; circles, arcs and thick lines are polygons and each one costs a draw
## call. Seventy cells makes that difference the whole frame budget, so
## silhouettes and pips are built from rectangles and the only polygons on the
## board are the thin cell outlines.

signal cell_tapped(cell: int)
signal cell_long_pressed(cell: int)
signal machine_moved(from_cell: int, to_cell: int)

const LONG_PRESS_SECONDS := 0.45
const DRAG_THRESHOLD := 14.0

## How long a material mote takes to cross between two cells. Short enough to
## keep up with a 10 Hz tick, long enough to be seen.
const MOTE_SECONDS := 0.22
## More motes than this on screen at once stops being information and starts
## being noise.
const MAX_MOTES := 14

enum Overlay { NONE, HEAT }

var selected_cell: int = -1
## Set by the parent; the machine the palette has armed, or "".
var arm_id: String = ""
var overlay: int = Overlay.NONE

var _press_cell: int = -1
var _press_pos: Vector2 = Vector2.ZERO
var _press_time: float = 0.0
var _dragging: bool = false
var _drag_pos: Vector2 = Vector2.ZERO
var _long_fired: bool = false
var _cell_size: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _flash: Dictionary = {}
var _motes: Array = []
var _rock_seed: int = -1
var _rock: PackedFloat32Array = PackedFloat32Array()
var _anim: float = 0.0


func _ready() -> void:
	set_process(true)
	Sim.stats_changed.connect(_on_stats)
	Sim.depth_changed.connect(func(_d): _rock_seed = -1; queue_redraw())


func _on_stats() -> void:
	_collect_motes()
	queue_redraw()


## Material moving between two adjacent machines is the only thing this game
## has in place of belts, so it is the one thing the board must not leave to
## the imagination. Every transfer the simulation actually performed gets a
## mote; the simulation records them, this only animates them.
func _collect_motes() -> void:
	if Sim.sim == null:
		return
	for t: Array in Sim.sim.last_transfers:
		if _motes.size() >= MAX_MOTES:
			return
		_motes.append({"from": int(t[0]), "to": int(t[1]), "res": int(t[2]),
			"t": 0.0})


func _process(delta: float) -> void:
	_anim += delta
	if _press_cell >= 0 and not _dragging and not _long_fired:
		_press_time += delta
		if _press_time >= LONG_PRESS_SECONDS:
			_long_fired = true
			cell_long_pressed.emit(_press_cell)
			Juice.reject()

	var busy: bool = false

	var done: Array = []
	for k: int in _flash:
		_flash[k] = float(_flash[k]) - delta * 2.6
		if float(_flash[k]) <= 0.0:
			done.append(k)
	for k in done:
		_flash.erase(k)
	busy = busy or not _flash.is_empty()

	if not _motes.is_empty():
		var alive: Array = []
		for m: Dictionary in _motes:
			m["t"] = float(m["t"]) + delta / MOTE_SECONDS
			if float(m["t"]) < 1.0:
				alive.append(m)
		_motes = alive
		busy = true

	if busy:
		queue_redraw()


func pulse(cell: int) -> void:
	_flash[cell] = 1.0


func set_overlay(mode: int) -> void:
	overlay = mode
	queue_redraw()


func toggle_heat_overlay() -> bool:
	overlay = Overlay.NONE if overlay == Overlay.HEAT else Overlay.HEAT
	queue_redraw()
	return overlay == Overlay.HEAT


func _layout() -> void:
	var s: Vector2 = size
	# Square cells, centred, with a margin. Fitting to the smaller axis keeps
	# the board square on every aspect ratio from 4:3 tablets to 20:9 phones.
	_cell_size = minf(s.x / float(Grid.W), s.y / float(Grid.H))
	var board := Vector2(_cell_size * Grid.W, _cell_size * Grid.H)
	_origin = (s - board) * 0.5


func cell_at(pos: Vector2) -> int:
	if _cell_size <= 0.0:
		return -1
	var local: Vector2 = pos - _origin
	var x: int = int(floor(local.x / _cell_size))
	var y: int = int(floor(local.y / _cell_size))
	if not Grid.in_bounds(x, y):
		return -1
	return Grid.idx(x, y)


func cell_rect(cell: int) -> Rect2:
	var p: Vector2i = Grid.xy(cell)
	var inset: float = _cell_size * 0.06
	return Rect2(
		_origin + Vector2(float(p.x) * _cell_size + inset, float(p.y) * _cell_size + inset),
		Vector2(_cell_size - inset * 2.0, _cell_size - inset * 2.0))


func cell_center(cell: int) -> Vector2:
	var r: Rect2 = cell_rect(cell)
	return r.position + r.size * 0.5


## --- input -----------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var pos: Vector2 = event.position
		if pressed:
			_press_cell = cell_at(pos)
			_press_pos = pos
			_press_time = 0.0
			_dragging = false
			_long_fired = false
			# Pressing an empty cell with something armed shows what that
			# placement would do to its neighbours, before committing to it.
			# The decision this game is about is made at this moment, so this
			# is where the information belongs.
			queue_redraw()
		else:
			_release(pos)
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _press_cell < 0 or _long_fired:
			return
		var pos: Vector2 = event.position
		if not _dragging and pos.distance_to(_press_pos) > DRAG_THRESHOLD:
			# Only a filled cell can be dragged; dragging an empty cell would
			# have no meaning and would swallow taps.
			if not Sim.grid.is_empty(_press_cell):
				_dragging = true
		if _dragging:
			_drag_pos = pos
			queue_redraw()


func _release(pos: Vector2) -> void:
	var from_cell: int = _press_cell
	_press_cell = -1
	_press_time = 0.0
	if _long_fired:
		_long_fired = false
		_dragging = false
		queue_redraw()
		return
	if _dragging:
		_dragging = false
		var to_cell: int = cell_at(pos)
		if to_cell >= 0 and to_cell != from_cell and Sim.grid.is_empty(to_cell):
			if Sim.move_machine(from_cell, to_cell):
				machine_moved.emit(from_cell, to_cell)
				Juice.place()
		queue_redraw()
		return
	var cell: int = cell_at(pos)
	if cell >= 0 and cell == from_cell:
		cell_tapped.emit(cell)
	queue_redraw()


## --- drawing ---------------------------------------------------------------

func _draw() -> void:
	_layout()
	# The first draw can arrive before the container has given this control a
	# size, and every glyph size and inset below is a fraction of the cell.
	if _cell_size <= 1.0:
		return
	var blocked: Dictionary = Strata.blocked_cells(Sim.depth)
	var font: Font = ThemeDB.fallback_font
	var cs: float = _cell_size
	_ensure_rock()

	for cell in range(Grid.W * Grid.H):
		var r: Rect2 = cell_rect(cell)
		if blocked.has(cell):
			_draw_rubble(r, cs)
			continue
		var id: String = Sim.grid.machine_at(cell)
		if id == "":
			_draw_empty(r, cell, cs, font)
		else:
			_draw_cell_base(r, cell, id, cs)

	# Machines on top of every base, so a neighbour's heat wash never paints
	# over a silhouette.
	for cell in range(Grid.W * Grid.H):
		if blocked.has(cell):
			continue
		var id: String = Sim.grid.machine_at(cell)
		if id != "":
			_draw_machine(cell_rect(cell), cell, id, font, cs)

	_draw_motes(cs)

	if _press_cell >= 0 and not _dragging:
		_draw_placement_preview(font, cs)

	if selected_cell >= 0 and not Sim.grid.is_empty(selected_cell):
		_draw_selection(cell_rect(selected_cell), cs)

	if _dragging and _press_cell >= 0:
		_draw_drag_ghost(font, cs)


## Empty rock. Speckled from a per-stratum seed so depth 9 does not look like
## depth 1 — a player who has descended nine times should be able to see that
## they are somewhere else, and a label is not enough.
func _ensure_rock() -> void:
	if _rock_seed == Sim.depth and not _rock.is_empty():
		return
	_rock_seed = Sim.depth
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lodeworks-rock-%d" % Sim.depth)
	_rock = PackedFloat32Array()
	_rock.resize(Grid.W * Grid.H * 3)
	for i in range(Grid.W * Grid.H):
		_rock[i * 3] = rng.randf()
		_rock[i * 3 + 1] = rng.randf()
		_rock[i * 3 + 2] = rng.randf()


func _draw_empty(r: Rect2, cell: int, cs: float, font: Font) -> void:
	var heat: float = Sim.grid.heat_at(cell)
	# A weak tint on empty rock. At depth, ambient heat alone would otherwise
	# flood the whole board one colour and the map would stop telling the
	# player anything about their own machines.
	# Weak, and weaker than under a machine. Ambient heat at depth applies to
	# every empty tile equally, so painting it at full strength says nothing
	# and costs the board its contrast.
	var base: Color = Palette.CELL.lerp(Palette.heat_color(heat), 0.20)
	draw_rect(r, base, true)

	# Two ore specks, deterministic per cell and per stratum.
	var a: float = _rock[cell * 3]
	var b: float = _rock[cell * 3 + 1]
	var c: float = _rock[cell * 3 + 2]
	var fleck: Color = base.lerp(Palette.TEXT_FAINT, 0.18 + c * 0.22)
	var s1: float = cs * (0.05 + c * 0.05)
	draw_rect(Rect2(r.position + Vector2(r.size.x * a, r.size.y * b),
		Vector2(s1, s1)), fleck, true)
	draw_rect(Rect2(r.position + Vector2(r.size.x * b * 0.8 + cs * 0.1,
		r.size.y * c * 0.8), Vector2(s1 * 0.6, s1 * 0.6)), fleck, true)

	draw_rect(r, Palette.LINE, false, 1.0)

	if overlay == Overlay.HEAT and cs > 34.0:
		# Absolute heat on empty rock, but only where it is not simply the
		# stratum's own ambient level. Printing the same number on forty
		# identical tiles is forty pieces of noise hiding the two that matter.
		if absf(heat - Sim.grid.ambient_heat) > 0.05:
			_num(font, r, "%.1f" % heat, Palette.TEXT_DIM, cs, 0.5)
		return

	# An armed palette entry marks where it could land. A small pip rather
	# than a filled cell: filling every empty tile with the machine's colour
	# washes the whole board and buries the heat field underneath it.
	if arm_id != "" and Sim.can_afford(arm_id) and not Sim.is_blocked(cell):
		var ghost: Color = Palette.machine_color(arm_id)
		ghost.a = 0.34
		var g: float = cs * 0.16
		draw_rect(Rect2(r.position + (r.size - Vector2(g, g)) * 0.5,
			Vector2(g, g)), ghost, true)


func _draw_rubble(r: Rect2, cs: float) -> void:
	draw_rect(r, Palette.CELL_BLOCKED, true)
	# Rubble drawn as blocks rather than hatch lines: a line with width is a
	# polygon and each one would cost a draw call on a board this size.
	var b: float = cs * 0.16
	for k in range(3):
		var f: float = 0.16 + float(k) * 0.28
		draw_rect(Rect2(r.position + Vector2(r.size.x * f, r.size.y * (0.7 - f * 0.6)),
			Vector2(b, b * 0.7)), Palette.LINE, true)


## The cell under the machine: heat, either as the absolute field or as this
## machine's own thermal error.
func _draw_cell_base(r: Rect2, cell: int, id: String, cs: float) -> void:
	var base: Color
	if overlay == Overlay.HEAT:
		var m: Dictionary = MachineDB.get_machine(id)
		base = Palette.divergent_color(Sim.sim.heat_delta_at(cell),
			float(m["heat_tolerance"]) + Sim.sim.tolerance_bonus)
	else:
		# Pulled back towards the board colour. At depth the ambient heat is
		# high everywhere, and a full-strength wash under every machine turns
		# the whole board one shade of brown -- which is exactly the state in
		# which the map stops carrying information.
		base = Palette.CELL.lerp(Palette.heat_color(Sim.grid.heat_at(cell)), 0.62)
	draw_rect(r, base, true)
	draw_rect(r, Palette.LINE, false, 1.0)


func _draw_machine(r: Rect2, cell: int, id: String, font: Font, cs: float) -> void:
	var col: Color = Palette.machine_color(id)
	var flash: float = float(_flash.get(cell, 0.0))
	var st: int = Sim.sim.status_of(cell)
	var eff: float = Sim.sim.heat_efficiency_at(cell)
	var thermal: bool = eff < Simulation.THERMAL_WARNING
	var delta: float = Sim.sim.heat_delta_at(cell)

	var body: Color = col.lerp(Color.WHITE, flash * 0.35)
	# A stalled machine goes dull. Losing its colour is a second, redundant
	# channel for the same fact the status pip carries, which is what makes it
	# readable without colour vision.
	if st == Simulation.Status.STARVED or st == Simulation.Status.BLOCKED:
		body = body.lerp(Palette.CELL, 0.42)
	body.a = 0.94

	MachineArt.silhouette(self, r, cs, Palette.family_of(id), body, flash)

	var glyph: String = Palette.machine_glyph(id)
	var gsize: int = int(cs * 0.40)
	var ts: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize)
	draw_string(font, r.position + Vector2(
			(r.size.x - ts.x) * 0.5,
			(r.size.y + ts.y * 0.62) * 0.5),
		glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize, Palette.BG)

	# What it makes, top-left. "Which building produces which item" is the
	# question players in this genre ask most often and the one a machine
	# glyph cannot answer.
	var out_res: int = Palette.output_res(id)
	if out_res >= 0:
		var chip: float = cs * 0.13
		draw_rect(Rect2(r.position + Vector2(cs * 0.06, cs * 0.06),
			Vector2(chip, chip)), Palette.res_color(out_res), true)

	_draw_status_pip(r, cs, st, thermal, delta)

	# Duty cycle down the left edge: how often this tile is actually working,
	# which is comparable between machine types in a way that items-per-second
	# is not.
	var up: float = Sim.sim.uptime_of(cell)
	var w: float = maxf(cs * 0.045, 2.0)
	var h: float = (r.size.y - cs * 0.12) * up
	draw_rect(Rect2(r.position.x + cs * 0.02,
		r.position.y + r.size.y - cs * 0.06 - h, w, h),
		Palette.efficiency_color(eff), true)

	# Cycle progress along the bottom: the thing that moves. A machine whose
	# bar has stopped sweeping is a machine that has stopped, and that reads
	# faster than any label.
	var prog: float = Sim.sim.progress_of(cell)
	var bh: float = maxf(cs * 0.05, 2.0)
	var bx: float = r.position.x + cs * 0.1
	var bw: float = r.size.x - cs * 0.2
	draw_rect(Rect2(bx, r.position.y + r.size.y - bh - cs * 0.05, bw, bh),
		Palette.BG.lerp(Palette.LINE, 0.6), true)
	draw_rect(Rect2(bx, r.position.y + r.size.y - bh - cs * 0.05, bw * prog, bh),
		Palette.ACCENT if st == Simulation.Status.RUNNING else Palette.ST_IDLE,
		true)

	if overlay == Overlay.HEAT and cs > 34.0:
		# The number, not only the colour. A few tenths of heat decide whether
		# a tile is at 100% or 62%, and a colour ramp cannot express that to
		# someone who is colourblind or to anyone trying to work out how much
		# coolant they actually need.
		# Under the glyph, not over it: the number is the second thing read,
		# after "what is this".
		_num(font, r, "%+.1f" % delta, Palette.TEXT, cs, 0.74)


## Four states, each a different SHAPE as well as a different colour, so the
## board still works for a colourblind player.
##
##   running   a filled square
##   blocked   a wide flat bar   — it is backed up, look downstream
##   starved   a tall thin bar   — it is not being fed, look upstream
##   thermal   a square with a bite out of it
func _draw_status_pip(r: Rect2, cs: float, st: int, thermal: bool,
		delta: float) -> void:
	var col: Color = Palette.status_color(st, thermal, delta)
	var p: float = cs * 0.135
	var x: float = r.position.x + r.size.x - p - cs * 0.04
	var y: float = r.position.y + cs * 0.04
	match st:
		Simulation.Status.BLOCKED:
			draw_rect(Rect2(x - p * 0.35, y + p * 0.32, p * 1.35, p * 0.40), col, true)
		Simulation.Status.STARVED:
			draw_rect(Rect2(x + p * 0.30, y, p * 0.40, p * 1.10), col, true)
		Simulation.Status.IDLE:
			draw_rect(Rect2(x + p * 0.25, y + p * 0.25, p * 0.5, p * 0.5), col, true)
		_:
			if thermal:
				draw_rect(Rect2(x, y, p, p), col, true)
				# Bite out of the corner: hot takes from the top, cold from
				# the bottom, so the pip carries its own direction.
				var bite: float = p * 0.42
				var by: float = y if delta > 0.0 else y + p - bite
				draw_rect(Rect2(x + p - bite, by, bite, bite), Palette.BG, true)
			else:
				draw_rect(Rect2(x, y, p, p), col, true)


## Material in transit. One mote per transfer the simulation actually made,
## travelling from the machine that gave it to the machine that took it.
func _draw_motes(cs: float) -> void:
	if _motes.is_empty():
		return
	var s: float = maxf(cs * 0.13, 3.0)
	for m: Dictionary in _motes:
		var t: float = float(m["t"])
		var a: Vector2 = cell_center(int(m["from"]))
		var b: Vector2 = cell_center(int(m["to"]))
		var p: Vector2 = a.lerp(b, clampf(t, 0.0, 1.0))
		var col: Color = Palette.res_color(int(m["res"]))
		col.a = 1.0 - t * t
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), col, true)


## What this placement would do, shown while the finger is still down.
##
## Both of the game's rules live in the relationship between a cell and its
## four neighbours, so the moment to explain them is the moment the player is
## choosing a cell — not in a tutorial box, and not after the credits have
## already been spent.
func _draw_placement_preview(font: Font, cs: float) -> void:
	var cell: int = _press_cell
	if cell < 0 or Sim.is_blocked(cell):
		return
	var id: String = arm_id if Sim.grid.is_empty(cell) else Sim.grid.machine_at(cell)
	if id == "":
		return
	var m: Dictionary = MachineDB.get_machine(id)
	if m.is_empty():
		return
	var emitted: float = float(m.get("heat_out", 0.0))

	draw_rect(cell_rect(cell).grow(2.0), Palette.ACCENT, false, 2.0)
	for n in Sim.grid.neighbours(cell):
		var nr: Rect2 = cell_rect(n)
		var nid: String = Sim.grid.machine_at(n)
		var bleed: float = emitted * Sim.grid.heat_spread
		if Sim.grid.is_empty(cell) and absf(bleed) < 0.001:
			continue
		var tint: Color = Palette.ST_HOT if bleed > 0.0 else Palette.ST_COLD
		tint.a = 0.20
		draw_rect(nr, tint, true)
		draw_rect(nr.grow(1.0), tint.lightened(0.2), false, 1.5)
		if cs > 30.0:
			var txt: String = "%+.1f" % bleed
			if nid != "":
				# What that bleed does to the machine already standing there
				# is the number that actually decides the placement.
				var nm: Dictionary = MachineDB.get_machine(nid)
				var now: float = Sim.grid.heat_at(n)
				var before: float = MachineDB.heat_efficiency(now,
					float(nm["heat_optimum"]),
					float(nm["heat_tolerance"]) + Sim.sim.tolerance_bonus)
				var after: float = MachineDB.heat_efficiency(now + bleed,
					float(nm["heat_optimum"]),
					float(nm["heat_tolerance"]) + Sim.sim.tolerance_bonus)
				txt = "%+d%%" % int(round((after - before) * 100.0))
			_num(font, nr, txt, Palette.TEXT, cs, 0.5)


func _num(font: Font, r: Rect2, text: String, col: Color, cs: float,
		vfrac: float) -> void:
	var fs: int = maxi(int(cs * 0.24), 9)
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, r.position + Vector2((r.size.x - ts.x) * 0.5,
		r.size.y * vfrac + ts.y * 0.36), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_selection(r: Rect2, cs: float) -> void:
	draw_rect(r.grow(2.0), Palette.ACCENT, false, 2.5)
	# Mark the neighbours it is actually coupled to, so a selection explains
	# the relationship rather than only the tile.
	for n in Sim.grid.neighbours(selected_cell):
		if Sim.grid.is_empty(n):
			continue
		var c: Color = Palette.ACCENT
		c.a = 0.55
		draw_rect(cell_rect(n).grow(1.0), c, false, 1.5)


func _draw_drag_ghost(font: Font, cs: float) -> void:
	var id: String = Sim.grid.machine_at(_press_cell)
	if id == "":
		return
	var target: int = cell_at(_drag_pos)
	if target >= 0 and Sim.grid.is_empty(target) and not Sim.is_blocked(target):
		draw_rect(cell_rect(target).grow(2.0), Palette.GOOD, false, 2.5)
	var ghost := Rect2(_drag_pos - Vector2(cs, cs) * 0.42, Vector2(cs, cs) * 0.84)
	var col: Color = Palette.machine_color(id)
	col.a = 0.75
	draw_rect(ghost, col, true)
	var glyph: String = Palette.machine_glyph(id)
	var gsize: int = int(cs * 0.36)
	var ts: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize)
	draw_string(font, ghost.position + Vector2(
			(ghost.size.x - ts.x) * 0.5, (ghost.size.y + ts.y * 0.62) * 0.5),
		glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize, Palette.BG)
