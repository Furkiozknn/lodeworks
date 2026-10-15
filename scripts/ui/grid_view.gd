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
## Tiles the tutorial is pointing at. Pulsing an outline where the answer is
## replaces a sentence explaining where, and costs the player no reading.
var highlight_cells: Array[int] = []
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
## The rock, mineral and vein colours for the stratum being drawn. Resolved
## once per frame rather than once per tile.
var _shaft: Dictionary = {}
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
	if not highlight_cells.is_empty():
		queue_redraw()
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
	# Published rather than guessed: the device self test converts this to dp
	# and compares it with Android's 48dp minimum touch target, and only the
	# board knows how much room the layout gave it.
	SelfTest.last_cell_px = _cell_size


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
	_shaft = Palette.shaft(Sim.depth)

	# ---------------------------------------------------------------------
	# Drawn in passes, and the reason is draw calls rather than tidiness.
	#
	# Godot's compatibility renderer batches consecutive rectangles and breaks
	# the batch for every texture switch. A glyph is a texture. Drawing each
	# machine as body-then-glyph-then-body-then-glyph therefore cost seventy
	# batch breaks; drawing every body, then every glyph, costs one. That is
	# what pays for machines built out of fifteen lit faces instead of three
	# flat ones.
	# ---------------------------------------------------------------------

	# Pass 1: the ground. Rock, platforms, heat.
	for cell in range(Grid.W * Grid.H):
		var r: Rect2 = cell_rect(cell)
		if blocked.has(cell):
			_draw_rubble(r, cs)
			continue
		if Sim.grid.machine_at(cell) == "":
			_draw_empty(r, cell, cs)
		else:
			_draw_cell_base(r, cell, Sim.grid.machine_at(cell), cs)

	# Pass 1b: the light each machine throws onto the floor around it. Drawn
	# under everything else so a working factory lights its own ground, which
	# is most of what "the place is alive" is made of.
	for cell in range(Grid.W * Grid.H):
		if blocked.has(cell) or Sim.grid.machine_at(cell) == "":
			continue
		_draw_light_pool(cell, cs)

	# Pass 1c: the conduits. A short run of pipe across every seam where one
	# machine can actually hand something to the one beside it.
	_draw_conduits(cs, blocked)

	# Pass 2: the machines themselves, on top of every base, so a neighbour's
	# heat wash never paints over a silhouette.
	for cell in range(Grid.W * Grid.H):
		if blocked.has(cell):
			continue
		var id: String = Sim.grid.machine_at(cell)
		if id != "":
			_draw_machine(cell_rect(cell), cell, id, cs)

	# Pass 3: the readouts. Duty, progress, status, upgrade notches, output.
	for cell in range(Grid.W * Grid.H):
		if blocked.has(cell) or Sim.grid.machine_at(cell) == "":
			continue
		_draw_readouts(cell_rect(cell), cell, cs)

	# Pass 4: everything made of text, in one batch.
	if cs > 24.0:
		for cell in range(Grid.W * Grid.H):
			if blocked.has(cell):
				continue
			var id2: String = Sim.grid.machine_at(cell)
			if id2 != "":
				MachineArt.glyph(self, cell_rect(cell), id2, font, cs)
	if overlay == Overlay.HEAT and cs > 34.0:
		_draw_heat_numbers(font, cs, blocked)

	_draw_dust(cs)
	_draw_motes(cs)
	_draw_vignette(cs)

	if not highlight_cells.is_empty():
		_draw_highlights(cs)

	if _press_cell >= 0 and not _dragging:
		_draw_placement_preview(font, cs)

	if selected_cell >= 0 and not Sim.grid.is_empty(selected_cell):
		_draw_selection(cell_rect(selected_cell), cs)

	if _dragging and _press_cell >= 0:
		_draw_drag_ghost(font, cs)


## Heat as a number as well as a colour, for every tile that has something to
## say. A few tenths decide whether a tile runs at 100% or 62%, and a colour
## ramp cannot express that to someone who is colourblind or to anyone working
## out how much coolant they actually need.
func _draw_heat_numbers(font: Font, cs: float, blocked: Dictionary) -> void:
	for cell in range(Grid.W * Grid.H):
		if blocked.has(cell):
			continue
		var r: Rect2 = cell_rect(cell)
		if Sim.grid.machine_at(cell) == "":
			var h: float = Sim.grid.heat_at(cell)
			# Only where it is not simply the stratum's own ambient level.
			# Printing the same number on forty identical tiles is forty
			# pieces of noise hiding the two that matter.
			if absf(h - Sim.grid.ambient_heat) > 0.05:
				_num(font, r, "%.1f" % h, Palette.TEXT_DIM, cs, 0.5, true)
		else:
			_num(font, r, "%+.1f" % Sim.sim.heat_delta_at(cell), Palette.TEXT,
				cs, 0.44, true)


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


func _draw_empty(r: Rect2, cell: int, cs: float) -> void:
	var heat: float = Sim.grid.heat_at(cell)
	# Rock colour shifts with depth as well as with heat, so a player who has
	# descended nine times can see that they are somewhere else. A label
	# saying "Stratum 9" is not the same as the ground looking different.
	#
	# The heat tint is weak, and weaker than under a machine. Ambient heat at
	# depth applies to every empty tile equally, so painting it at full
	# strength says nothing and costs the board its contrast.
	var sh: Dictionary = _shaft
	# A light heat tint, and lighter than it used to be. Ambient heat at depth
	# applies to every empty tile equally, so a strong wash turns the whole
	# board one shade of brown -- which is exactly the state in which the map
	# stops carrying information and starts looking like mud.
	var base: Color = (sh["rock"] as Color).lerp(Palette.heat_color(heat), 0.12)
	# Per-tile tonal variation, from the same per-stratum seed as the flecks.
	# Seventy identical squares read as a spreadsheet; seventy slightly
	# different ones read as ground.
	base = base.lerp(base.lightened(0.12), _rock[cell * 3 + 2])

	# An empty tile is a shallow pit rather than a square of colour: a dark
	# seam, a floor, and a lit lip along the top edge where the key light
	# reaches in. Three rectangles, and the grid stops looking like a table.
	var seam: float = maxf(cs * 0.035, 1.0)
	draw_rect(r, base.darkened(0.42), true)
	draw_rect(Rect2(r.position.x + seam, r.position.y + seam,
		r.size.x - seam * 2.0, r.size.y - seam * 2.0), base, true)
	var lip: Color = base.lerp(Palette.KEY_TINT, 0.16)
	lip.a = 0.42
	draw_rect(Rect2(r.position.x + seam, r.position.y + seam,
		r.size.x - seam * 2.0, seam), lip, true)

	# Ore specks, deterministic per cell and per stratum. Warmer and brighter
	# with depth: the rock is richer down there and it should look it.
	var a: float = _rock[cell * 3]
	var b: float = _rock[cell * 3 + 1]
	var c: float = _rock[cell * 3 + 2]
	var fleck: Color = base.lerp(sh["fleck"], 0.22 + c * 0.34)
	var s1: float = cs * (0.05 + c * 0.05)
	draw_rect(Rect2(r.position + Vector2(r.size.x * a, r.size.y * b),
		Vector2(s1, s1)), fleck, true)
	draw_rect(Rect2(r.position + Vector2(r.size.x * b * 0.8 + cs * 0.1,
		r.size.y * c * 0.8), Vector2(s1 * 0.6, s1 * 0.6)), fleck, true)
	# A vein of something in the rock, on about one tile in ten, and brighter
	# the deeper the shaft goes. By the abyssal band the ground itself is a
	# light source, which is most of what makes depth feel like somewhere.
	var ember: float = float(sh["ember"])
	if c > 0.90:
		Palette.emissive(self, Rect2(r.position
			+ Vector2(r.size.x * 0.42, r.size.y * 0.40),
			Vector2(cs * 0.11, cs * 0.09)), sh["vein"], 0.30 + ember * 0.75)
	elif ember > 0.35 and b > 0.86:
		# A hairline crack, lit from underneath.
		var crack: Color = (sh["vein"] as Color)
		crack.a = 0.16 + ember * 0.30
		draw_rect(Rect2(r.position.x + r.size.x * a * 0.5 + cs * 0.12,
			r.position.y + r.size.y * 0.66, cs * (0.18 + b * 0.30),
			maxf(cs * 0.022, 1.0)), crack, true)

	if overlay == Overlay.HEAT:
		return

	# An armed palette entry marks where it could land -- but only on tiles
	# where landing there would connect to something.
	#
	# Marking every empty tile put sixty pips on the board and taught nothing;
	# marking the frontier answers the question the player is actually asking,
	# which is "where would this reach". On an empty board every tile is the
	# frontier, so the first placement is unconstrained.
	if arm_id != "" and Sim.can_afford(arm_id) and not Sim.is_blocked(cell) \
			and (Sim.grid.cells.is_empty() or _touches_machine(cell)):
		# A small hollow marker, not a lit block. The first version used the
		# machine's own emissive colour and put twenty glowing orange squares
		# on the board, which read as twenty machines rather than as twenty
		# places a machine could go.
		var ghost: Color = Palette.machine_light(arm_id)
		ghost.a = 0.42
		var g: float = cs * 0.15
		var gr := Rect2(r.position + (r.size - Vector2(g, g)) * 0.5,
			Vector2(g, g))
		var t: float = maxf(cs * 0.018, 1.0)
		draw_rect(Rect2(gr.position.x, gr.position.y, g, t), ghost, true)
		draw_rect(Rect2(gr.position.x, gr.position.y + g - t, g, t), ghost, true)
		draw_rect(Rect2(gr.position.x, gr.position.y, t, g), ghost, true)
		draw_rect(Rect2(gr.position.x + g - t, gr.position.y, t, g), ghost, true)


func _touches_machine(cell: int) -> bool:
	for n in Sim.grid.neighbours(cell):
		if not Sim.grid.is_empty(n):
			return true
	return false


func _draw_rubble(r: Rect2, cs: float) -> void:
	draw_rect(r, Palette.CELL_BLOCKED, true)
	# Rubble drawn as blocks rather than hatch lines: a line with width is a
	# polygon and each one would cost a draw call on a board this size.
	var b: float = cs * 0.16
	for k in range(3):
		var f: float = 0.16 + float(k) * 0.28
		draw_rect(Rect2(r.position + Vector2(r.size.x * f, r.size.y * (0.7 - f * 0.6)),
			Vector2(b, b * 0.7)), Palette.LINE, true)


## The platform a machine stands on: heat, either as the absolute field or as
## this machine's own thermal error, bevelled so the tile reads as ground.
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
		base = Palette.CELL.lerp(Palette.heat_color(Sim.grid.heat_at(cell)), 0.55)
	MachineArt.platform(self, r, cs, base)


## The machine: a lit solid standing on its platform, built by `MachineArt`
## from the live state of the tile.
##
## Everything that changes here changes because the simulation changed, and
## each channel is redundant with a second one, so nothing depends on colour
## vision alone:
##
##   working    the moving part moves, the core is bright, the bar sweeps
##   starved    the body goes dull AND the pip becomes a tall thin bar
##   blocked    the body goes dull AND the pip becomes a wide flat bar
##   too hot    the core burns harder AND the pip loses its top corner
##   too cold   the core turns blue AND the pip loses its bottom corner
##   upgraded   the machine has visibly more parts on it
func _draw_machine(r: Rect2, cell: int, id: String, cs: float) -> void:
	var flash: float = float(_flash.get(cell, 0.0))
	var st: int = Sim.sim.status_of(cell)
	var eff: float = Sim.sim.heat_efficiency_at(cell)
	var thermal: bool = eff < Simulation.THERMAL_WARNING
	var delta: float = Sim.sim.heat_delta_at(cell)
	var running: bool = st == Simulation.Status.RUNNING
	var stalled: bool = st == Simulation.Status.STARVED \
		or st == Simulation.Status.BLOCKED

	# How hard the core is lit. A working machine glows; a stalled one is
	# nearly dark; an overheating one burns. This is the thing that is legible
	# from the far side of the board when the glyph is four pixels tall.
	var glow: float = 1.0
	if stalled:
		glow = 0.22
	elif st == Simulation.Status.IDLE or st == Simulation.Status.EMPTY:
		glow = 0.45
	elif thermal:
		glow = 1.45 if delta > 0.0 else 0.85
	glow += flash * 0.8

	var inset: float = cs * (1.0 - MachineArt.FOOT) * 0.5
	MachineArt.build(self, r.grow(-inset), cs, id, {
		"tier": Sim.upgrade_marks(),
		"phase": Sim.sim.progress_of(cell),
		"running": running,
		"glow": glow,
		"cold": thermal and delta < 0.0,
	})

	# An overheating machine vents. Two pale blocks rising off the top edge,
	# so "this one is cooking" is visible without reading a number or knowing
	# which colour means what.
	if thermal and delta > 0.0 and cs > 30.0:
		var t: float = fposmod(_anim * 0.8 + float(cell) * 0.17, 1.0)
		var puff: Color = Palette.ST_HOT.lerp(Color.WHITE, 0.45)
		puff.a = (1.0 - t) * 0.45
		var w: float = cs * (0.12 + t * 0.14)
		draw_rect(Rect2(r.position.x + r.size.x * 0.58,
			r.position.y + cs * 0.06 - t * cs * 0.22, w, w * 0.7), puff, true)


## The readouts, drawn after every machine so they land in one batch and never
## disappear under a neighbour's glow.
func _draw_readouts(r: Rect2, cell: int, cs: float) -> void:
	var id: String = Sim.grid.machine_at(cell)
	var st: int = Sim.sim.status_of(cell)
	var eff: float = Sim.sim.heat_efficiency_at(cell)
	var thermal: bool = eff < Simulation.THERMAL_WARNING
	var delta: float = Sim.sim.heat_delta_at(cell)

	# What it makes, top-left. "Which building produces which item" is the
	# question players in this genre ask most often and the one a machine
	# glyph cannot answer.
	var out_res: int = Palette.output_res(id)
	if out_res >= 0:
		var chip: float = cs * 0.13
		var cr := Rect2(r.position + Vector2(cs * 0.055, cs * 0.055),
			Vector2(chip, chip))
		draw_rect(cr.grow(maxf(cs * 0.016, 1.0)), Palette.BG, true)
		draw_rect(cr, Palette.res_color(out_res), true)

	_draw_status_pip(r, cs, st, thermal, delta)

	# Research, on the machines it bought. Three notches at most: the point is
	# "this factory is better than it was", not a readout.
	var marks: int = Sim.upgrade_marks()
	if marks > 0 and cs > 26.0:
		var mw: float = cs * 0.075
		for k in range(marks):
			draw_rect(Rect2(r.position.x + cs * 0.06 + float(k) * (mw + cs * 0.03),
				r.position.y + r.size.y - cs * 0.16, mw, cs * 0.045),
				Palette.CORE, true)

	# Duty cycle down the left edge: how often this tile is actually working,
	# which is comparable between machine types in a way that items-per-second
	# is not.
	var up: float = Sim.sim.uptime_of(cell)
	var w: float = maxf(cs * 0.045, 2.0)
	var h: float = (r.size.y - cs * 0.12) * up
	draw_rect(Rect2(r.position.x + cs * 0.025,
		r.position.y + r.size.y - cs * 0.06 - h, w, h),
		Palette.efficiency_color(eff), true)

	# Cycle progress along the bottom: the thing that moves. A machine whose
	# bar has stopped sweeping is a machine that has stopped, and that reads
	# faster than any label.
	var prog: float = Sim.sim.progress_of(cell)
	var bh: float = maxf(cs * 0.05, 2.0)
	var bx: float = r.position.x + cs * 0.1
	var bw: float = r.size.x - cs * 0.2
	var by: float = r.position.y + r.size.y - bh - cs * 0.045
	draw_rect(Rect2(bx, by, bw, bh), Palette.BG.lerp(Palette.LINE, 0.6), true)
	if prog > 0.001:
		var fill: Color = Palette.machine_light(id) \
			if st == Simulation.Status.RUNNING else Palette.ST_IDLE
		draw_rect(Rect2(bx, by, bw * prog, bh), fill, true)


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
## The light a machine throws on the floor.
##
## A lit object with an unlit floor under it looks like a sticker. This paints
## a soft warm pool on the machine's own tile and a weaker one on each
## neighbour, in the machine's own light colour and scaled by how hard it is
## currently glowing -- so a running factory lights its own ground, a stalled
## one goes dark, and the brightness of the FLOOR is a second, peripheral
## channel for the same fact the status pip carries.
func _draw_light_pool(cell: int, cs: float) -> void:
	var st: int = Sim.sim.status_of(cell)
	if st == Simulation.Status.STARVED or st == Simulation.Status.BLOCKED:
		return
	var k: float = 1.0 if st == Simulation.Status.RUNNING else 0.45
	k += float(_flash.get(cell, 0.0)) * 0.9
	var col: Color = Palette.machine_light(Sim.grid.machine_at(cell))
	var r: Rect2 = cell_rect(cell)
	# A falloff rather than a slab. The first version painted two big squares
	# of flat alpha and produced coloured rectangles bleeding across the
	# board, which read as tinted tiles instead of as light -- prettier and
	# less legible, which is the failure this whole pass is guarded against.
	const FALL := [0.30, 0.18, 0.08, 0.0]
	const A := [0.020, 0.035, 0.055, 0.075]
	for i in range(FALL.size()):
		col.a = A[i] * k
		draw_rect(r.grow(cs * FALL[i]), col, true)


## Conduits: the game's central rule, made visible when nothing is moving.
##
## Lodeworks has no belts on purpose -- a machine hands what it makes to any
## orthogonal neighbour that wants it. That rule is legible the moment a mote
## crosses a seam and completely invisible the rest of the time, which is
## exactly when a player is standing still trying to work out why a tile is
## starved.
##
## So every seam where one machine CAN feed the one beside it gets a short run
## of pipe, coloured by the resource that would cross it. Dim when nothing is
## flowing, lit when something is. It is the same information the motes carry,
## available at rest, and it is also the thing that makes a dense board look
## like plumbing rather than like a spreadsheet of tiles.
func _draw_conduits(cs: float, blocked: Dictionary) -> void:
	if cs < 30.0:
		return
	var w: float = maxf(cs * 0.055, 2.0)
	var reach: float = cs * 0.22
	for cell: int in Sim.grid.cells:
		if blocked.has(cell):
			continue
		var res: int = Palette.output_res(Sim.grid.machine_at(cell))
		if res < 0:
			continue
		var a: Vector2 = cell_center(cell)
		for n in Sim.grid.bridged_machines(cell):
			# Only downstream, and only once per pair: the pipe runs from the
			# maker to the taker.
			if not _accepts(n, res):
				continue
			var b: Vector2 = cell_center(n)
			var mid: Vector2 = (a + b) * 0.5
			var live: bool = Sim.sim.status_of(cell) == Simulation.Status.RUNNING
			var col: Color = Palette.res_color(res)
			# At rest the pipe is barely there: it is answering "could this
			# feed that" for somebody who is looking for it, not competing
			# with the machines for attention.
			var body: Color = col.lerp(Palette.BG, 0.35 if live else 0.80)
			var horizontal: bool = absf(b.x - a.x) > absf(b.y - a.y)
			var seg: Rect2
			if horizontal:
				seg = Rect2(mid.x - reach, mid.y - w * 0.5, reach * 2.0, w)
			else:
				seg = Rect2(mid.x - w * 0.5, mid.y - reach, w, reach * 2.0)
			# A dark casing with a lit core, so the pipe reads as a pipe and
			# not as a coloured line.
			draw_rect(seg.grow(maxf(cs * 0.012, 1.0)), Palette.BG, true)
			draw_rect(seg, body, true)
			if live:
				draw_rect(seg.grow(-w * 0.30), col.lerp(Color.WHITE, 0.30), true)


## Can the machine on this tile take that resource? Vaults take anything.
func _accepts(cell: int, res: int) -> bool:
	var m: Dictionary = MachineDB.get_machine(Sim.grid.machine_at(cell))
	if m.is_empty():
		return false
	if (m.get("tags", []) as Array).has("sink"):
		return true
	return (m.get("inputs", {}) as Dictionary).has(res)


## Ambient particles: dust at the surface, embers in the deep.
##
## Sixteen of them, drifting on a fixed loop, seeded per stratum so the same
## depth always looks the same. This is the cheapest thing on the board and it
## is the difference between air and vacuum.
func _draw_dust(cs: float) -> void:
	if _rock.is_empty() or _shaft.is_empty():
		return
	var ember: float = float(_shaft["ember"])
	var col: Color = (_shaft["fleck"] as Color).lerp(_shaft["vein"], ember)
	var board := Rect2(Vector2.ZERO, size)
	for i in range(16):
		var seed_a: float = _rock[(i * 7) % _rock.size()]
		var seed_b: float = _rock[(i * 13 + 3) % _rock.size()]
		# Rising, slowly, at a speed of its own.
		var t: float = fposmod(_anim * (0.06 + seed_a * 0.09) + seed_b, 1.0)
		var p := Vector2(
			board.size.x * seed_a + sin(_anim * 0.4 + float(i)) * cs * 0.18,
			board.size.y * (1.0 - t))
		var s: float = cs * (0.025 + seed_b * 0.035)
		var c: Color = col
		c.a = (0.12 + ember * 0.28) * sin(t * PI)
		draw_rect(Rect2(p, Vector2(s, s)), c, true)


## A dark frame around the shaft.
##
## The board used to run edge to edge inside its panel, which read as a table
## with tiles on it. Four gradient bands push the corners back and leave the
## middle lit, so the factory sits in a hole in the ground rather than on a
## sheet of paper.
func _draw_vignette(cs: float) -> void:
	var steps: int = 6
	var depth_px: float = cs * 0.55
	for i in range(steps):
		var t: float = float(i) / float(steps)
		var c := Color(0.02, 0.03, 0.05)
		c.a = 0.16 * (1.0 - t)
		var band: float = depth_px * (1.0 - t) / float(steps) + 1.0
		var off: float = depth_px * t
		draw_rect(Rect2(0.0, off, size.x, band), c, true)
		draw_rect(Rect2(0.0, size.y - off - band, size.x, band), c, true)
		draw_rect(Rect2(off, 0.0, band, size.y), c, true)
		draw_rect(Rect2(size.x - off - band, 0.0, band, size.y), c, true)


func _draw_motes(cs: float) -> void:
	if _motes.is_empty():
		return
	# Material in transit, drawn as a lit packet rather than a flat square.
	# This is the single clearest signal that the factory is working: on a
	# busy board dozens of these are crossing gaps every second, and the eye
	# reads "flow" long before it reads a credits-per-second number.
	var s: float = maxf(cs * 0.15, 3.0)
	for m: Dictionary in _motes:
		var t: float = clampf(float(m["t"]), 0.0, 1.0)
		var a: Vector2 = cell_center(int(m["from"]))
		var b: Vector2 = cell_center(int(m["to"]))
		# Eased so it leaves quickly and arrives softly, which reads as a
		# thing being handed over rather than a dot sliding on a rail.
		var p: Vector2 = a.lerp(b, t * t * (3.0 - 2.0 * t))
		var col: Color = Palette.res_color(int(m["res"]))
		var fade: float = 1.0 - t * t
		Palette.emissive(self, Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)),
			col, fade * 0.85)


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
	# Every tile whose heat this machine changes, from the same rebuild the
	# board uses: neighbours for an emitter, and with a Heat Pipe in play also
	# tiles two steps away.
	var change: Dictionary = Sim.grid.heat_contribution(cell, id)

	draw_rect(cell_rect(cell).grow(2.0), Palette.ACCENT, false, 2.0)

	# A support machine's whole value is how many working neighbours it ends
	# up with, and that is invisible until it is placed. So it is drawn on the
	# tile before the tile is bought: how many it will serve, and what that
	# makes it worth. This is the difference between a rule the game has and a
	# rule a player can find.
	if m.has("amplify") or m.has("duplicate_chance"):
		_draw_service_preview(font, cs, cell, m)

	for n: int in change:
		var nr: Rect2 = cell_rect(n)
		var nid: String = Sim.grid.machine_at(n)
		var bleed: float = float(change[n])
		# Pressing an existing tile shows what it is doing to the tiles now;
		# their heat already includes it, so "before" is without it.
		var now_offset: float = 0.0 if Sim.grid.is_empty(cell) else -bleed
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
				var now: float = maxf(Sim.grid.raw_heat_at(n) + now_offset, 0.0)
				var before: float = MachineDB.heat_efficiency(now,
					float(nm["heat_optimum"]),
					float(nm["heat_tolerance"]) + Sim.sim.tolerance_bonus)
				var after: float = MachineDB.heat_efficiency(now + bleed,
					float(nm["heat_optimum"]),
					float(nm["heat_tolerance"]) + Sim.sim.tolerance_bonus)
				txt = "%+d%%" % int(round((after - before) * 100.0))
			_num(font, nr, txt, Palette.TEXT, cs, 0.5)


## What a support tile would be worth here, drawn before it is bought.
##
## Counts what it would serve from where the finger is, including the machines
## it would newly connect by bridging, and prints both the count and the
## multiplier the rule gives it. A player who moves their finger one tile and
## watches "serves 1 (x1.0)" become "serves 4 (x2.5)" has been told the rule
## without being told the rule.
func _draw_service_preview(font: Font, cs: float, cell: int,
		_m: Dictionary) -> void:
	var n: int = Sim.grid.serves_if_placed(cell)
	var factor: float = Grid.factor_for(n)
	var r: Rect2 = cell_rect(cell)
	var col: Color = Palette.GOOD if n >= 3 else (
		Palette.WARN if n >= 1 else Palette.BAD)
	if cs > 30.0:
		_num(font, r, "serves %d" % n, col, cs, 0.26)
		_num(font, r, "x%.1f" % factor, col, cs, 0.52)


func _num(font: Font, r: Rect2, text: String, col: Color, cs: float,
		vfrac: float, backing: bool = false) -> void:
	var fs: int = maxi(int(cs * 0.24), 9)
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var p: Vector2 = r.position + Vector2((r.size.x - ts.x) * 0.5,
		r.size.y * vfrac + ts.y * 0.36)
	if backing:
		# A number printed straight onto a lit machine body is unreadable, and
		# the heat overlay exists precisely so somebody can read numbers.
		var pad: Color = Palette.BG
		pad.a = 0.78
		draw_rect(Rect2(p.x - cs * 0.05, p.y - ts.y * 0.82,
			ts.x + cs * 0.10, ts.y * 1.02), pad, true)
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## A slow breathing outline. Fast enough to catch the eye, slow enough not to
## be the most urgent thing on a screen that also has a factory on it.
func _draw_highlights(cs: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(_anim * 3.4)
	var col: Color = Palette.ACCENT
	col.a = 0.35 + 0.45 * pulse
	var w: float = 2.0 + 1.6 * pulse
	for cell in highlight_cells:
		if cell < 0 or cell >= Grid.W * Grid.H:
			continue
		draw_rect(cell_rect(cell).grow(1.0 + pulse * 2.0), col, false, w)


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
