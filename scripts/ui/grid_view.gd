class_name GridView
extends Control

## The board. Everything here is drawn, and everything here is touched.
##
## Two interactions, both one-thumb:
##
##   tap on empty   place the selected machine
##   tap on filled  select it (shows its readout; tap again to deselect)
##   drag a filled cell to an empty one to move it -- free, always
##   long-press     sell
##
## Dragging rather than "pick up / put down" matters on a phone: the board is a
## layout puzzle and the player will rearrange constantly, so the cost of a
## rearrangement has to be one gesture, not three taps through a menu.

signal cell_tapped(cell: int)
signal cell_long_pressed(cell: int)
signal machine_moved(from_cell: int, to_cell: int)

const LONG_PRESS_SECONDS := 0.45
const DRAG_THRESHOLD := 14.0

var selected_cell: int = -1
## Set by the parent; the machine the palette has armed, or "".
var arm_id: String = ""

var _press_cell: int = -1
var _press_pos: Vector2 = Vector2.ZERO
var _press_time: float = 0.0
var _dragging: bool = false
var _drag_pos: Vector2 = Vector2.ZERO
var _long_fired: bool = false
var _cell_size: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _flash: Dictionary = {}


func _ready() -> void:
	set_process(true)
	Sim.stats_changed.connect(queue_redraw)
	Sim.depth_changed.connect(func(_d): queue_redraw())


func _process(delta: float) -> void:
	if _press_cell >= 0 and not _dragging and not _long_fired:
		_press_time += delta
		if _press_time >= LONG_PRESS_SECONDS:
			_long_fired = true
			cell_long_pressed.emit(_press_cell)
			_buzz()
	# Cycle flashes decay so the board visibly pulses as it works. This is the
	# only animation in the game and it is what makes an idle board feel alive.
	var done: Array = []
	for k: int in _flash:
		_flash[k] = float(_flash[k]) - delta * 2.6
		if float(_flash[k]) <= 0.0:
			done.append(k)
	for k in done:
		_flash.erase(k)
	if not _flash.is_empty():
		queue_redraw()


func pulse(cell: int) -> void:
	_flash[cell] = 1.0


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
				_buzz()
		queue_redraw()
		return
	var cell: int = cell_at(pos)
	if cell >= 0 and cell == from_cell:
		cell_tapped.emit(cell)
	queue_redraw()


func _buzz() -> void:
	if Sim.settings.get("haptics", true):
		Input.vibrate_handheld(18)


## --- drawing ---------------------------------------------------------------

func _draw() -> void:
	_layout()
	var blocked: Dictionary = Strata.blocked_cells(Sim.depth)
	var font: Font = ThemeDB.fallback_font
	var cs: float = _cell_size

	for cell in range(Grid.W * Grid.H):
		var r: Rect2 = cell_rect(cell)
		var is_blocked: bool = blocked.has(cell)
		var heat: float = Sim.grid.heat_at(cell)

		# Base: heat-tinted so the thermal map is always visible. Empty cells
		# get a much weaker tint -- at depth, ambient heat alone would
		# otherwise flood the whole board one colour and the map would stop
		# telling the player anything about their own machines.
		var base: Color
		if is_blocked:
			base = Palette.CELL_BLOCKED
		elif Sim.grid.is_empty(cell):
			base = Palette.CELL.lerp(Palette.heat_color(heat), 0.35)
		else:
			base = Palette.heat_color(heat)
		draw_rect(r, base, true)

		if is_blocked:
			# Hatch a collapsed cell so it reads as rubble, not as a dark tile.
			var step: float = cs * 0.22
			var t: float = 0.0
			while t < r.size.x + r.size.y:
				var a := Vector2(r.position.x + t, r.position.y)
				var b := Vector2(r.position.x, r.position.y + t)
				draw_line(a.clamp(r.position, r.position + r.size),
					b.clamp(r.position, r.position + r.size),
					Palette.LINE, 1.0)
				t += step
			continue

		draw_rect(r, Palette.LINE, false, 1.0)

		var id: String = Sim.grid.machine_at(cell)
		if id == "":
			# An armed palette entry previews where it would land.
			if arm_id != "" and Sim.can_afford(arm_id):
				var ghost: Color = Palette.machine_color(arm_id)
				ghost.a = 0.16
				draw_rect(r.grow(-cs * 0.12), ghost, true)
			continue

		_draw_machine(r, cell, id, font, cs)

	if selected_cell >= 0 and not Sim.grid.is_empty(selected_cell):
		_draw_selection(cell_rect(selected_cell))

	if _dragging and _press_cell >= 0:
		_draw_drag_ghost(font, cs)


func _draw_machine(r: Rect2, cell: int, id: String, font: Font, cs: float) -> void:
	var col: Color = Palette.machine_color(id)
	var flash: float = float(_flash.get(cell, 0.0))
	var body: Color = col.lerp(Color.WHITE, flash * 0.35)
	body.a = 0.92
	draw_rect(r.grow(-cs * 0.06), body, true)

	var glyph: String = Palette.machine_glyph(id)
	var gsize: int = int(cs * 0.42)
	var text_size: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize)
	draw_string(font, r.position + Vector2(
			(r.size.x - text_size.x) * 0.5,
			(r.size.y + text_size.y * 0.62) * 0.5),
		glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize, Palette.BG)

	# Efficiency bar. This is the single most important readout in the game:
	# it is how a player sees that a tile is choking without opening anything.
	var m: Dictionary = MachineDB.get_machine(id)
	var eff: float = MachineDB.heat_efficiency(Sim.grid.heat_at(cell),
		float(m["heat_optimum"]),
		float(m["heat_tolerance"]) + Sim.sim.tolerance_bonus)
	var bar_h: float = maxf(cs * 0.055, 2.0)
	var bar := Rect2(r.position.x + cs * 0.1, r.position.y + r.size.y - bar_h - cs * 0.07,
		(r.size.x - cs * 0.2) * clampf(eff, 0.0, 1.0), bar_h)
	draw_rect(Rect2(r.position.x + cs * 0.1, bar.position.y,
		r.size.x - cs * 0.2, bar_h), Palette.BG.lerp(Palette.LINE, 0.6), true)
	draw_rect(bar, Palette.efficiency_color(eff), true)


func _draw_selection(r: Rect2) -> void:
	draw_rect(r.grow(2.0), Palette.ACCENT, false, 2.5)


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
