class_name IsoView
extends Control

## The world, and the factory standing in it.
##
## A painted canyon far below, a rock island floating in it, a stone floor on
## the island, and on the floor the 7 x 10 board the simulation plays on --
## seen from a three-quarter isometric camera the player can drag, pinch and
## wheel. Everything drawn here READS the simulation; nothing here writes to
## it except the three things a finger does: place, move, sell.
##
## Interaction:
##
##   tap on an empty tile      place the armed machine
##   tap on a machine          select it (the detail panel opens)
##   drag a SELECTED machine   move it -- free, always
##   drag anywhere else        pan the camera; it coasts when released
##   long-press a machine      sell
##   pinch / wheel             zoom about the fingers or the cursor
##
## "Drag a selected machine" is the one rule that changed with the camera:
## once dragging the world pans it, dragging a machine by accident would move
## it, so a machine is picked up only once it has been picked out.
##
## Draw order, back to front, each a child layer so the two light passes can
## be additive without a shader:
##
##   this Control   the painting, behind everything, with parallax
##   _floor         island, slab edge, floor tiles, rim, floor marks, shadows
##   _floor_glow    light the machines throw on the floor           (additive)
##   _things        pipes and machines, strictly back to front
##   _glow          machine cores, lamps, flow along live pipes     (additive)
##   _over          badges, numbers, previews -- screen space, fixed size

signal cell_tapped(cell: int)
signal cell_long_pressed(cell: int)
signal machine_moved(from_cell: int, to_cell: int)
## A tap that landed on no board cell: the world, the island, the sky.
signal ground_tapped()

enum Overlay { NONE, HEAT }

const LONG_PRESS_SECONDS := 0.45
const DRAG_THRESHOLD := 14.0

var selected_cell: int = -1
var highlight_cells: Array[int] = []
var arm_id: String = ""
var overlay: int = Overlay.NONE

var cam := IsoCamera.new()
var badges := StatusBadges.new()
## The part of the screen the interface leaves clear. Set by the HUD; the
## camera frames the board inside it.
var free_rect := Rect2()

var _floor: Node2D
var _floor_glow: Node2D
var _things: Node2D
var _glow: Node2D
var _over: Node2D

# Pointer state. One finger is handled through the mouse events Godot
# emulates from touch (the default), which is also exactly what a desktop
# mouse sends; a second finger is tracked separately for the pinch.
var _press_cell: int = -1
var _press_pos := Vector2.ZERO
var _press_time: float = 0.0
var _pressed: bool = false
var _panning: bool = false
var _dragging: bool = false
var _drag_pos := Vector2.ZERO
var _long_fired: bool = false
var _samples: Array = []
var _touches: Dictionary = {}
var _pinching: bool = false
var _pinch_dist: float = 0.0
var _pinch_mid := Vector2.ZERO

var _anim: float = 0.0
var _flash: Dictionary = {}
## "a-b" -> seconds of glow left; a pipe glows for a moment after the
## simulation actually moved something along it.
var _flow: Dictionary = {}
var _links: Array = []
var _segments: Dictionary = {}
var _sheet_name: String = ""
var _sheet: Dictionary = {}
var _atlas: Texture2D
var _tiles: Texture2D
var _world_tex: Texture2D
var _island_tex: Texture2D
var _band_tint := Color.WHITE
var _band_target := Color.WHITE
var _framed: bool = false


func _ready() -> void:
	# With offsets: a bare set_anchors_preset keeps the current (empty) rect.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_floor = _layer(false)
	_floor_glow = _layer(true)
	_things = _layer(false)
	_glow = _layer(true)
	_over = _layer(false)
	_floor.draw.connect(_draw_floor)
	_floor_glow.draw.connect(_draw_floor_glow)
	_things.draw.connect(_draw_things)
	_glow.draw.connect(_draw_glow)
	_over.draw.connect(_draw_over)

	var L: Dictionary = IsoArt.layout()
	var w: Dictionary = L.get("world", {})
	_world_tex = IsoArt.texture(String(w.get("file", "")))
	_island_tex = IsoArt.texture(String(L.get("island", {}).get("file", "")))
	_tiles = IsoArt.texture(String(L.get("tiles", {}).get("file", "")))
	var size_a: Array = w.get("size", [3840, 2160])
	cam.bg_size = Vector2(float(size_a[0]), float(size_a[1]))
	cam.anchor = Iso.anchor()
	cam.center = cam.anchor
	cam.parallax = float(IsoArt.placement().get("parallax", 0.82))
	_band_tint = band_tint(Sim.depth)
	_band_target = _band_tint
	_refresh_sheet()

	Sim.stats_changed.connect(_on_stats)
	Sim.depth_changed.connect(func(d: int): _band_target = band_tint(d))
	resized.connect(_on_resized)
	_on_stats()


func _layer(additive: bool) -> Node2D:
	var n := Node2D.new()
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		n.material = m
	add_child(n)
	return n


func _on_resized() -> void:
	cam.set_viewport(size)
	if not _framed or free_rect.size == Vector2.ZERO:
		frame_board()


## Frame the whole board in the free part of the screen: the default view.
func frame_board() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	cam.set_viewport(size)
	var fr: Rect2 = free_rect if free_rect.size.x > 8.0 else Rect2(Vector2.ZERO, size)
	cam.fit(frame_rect(), fr)
	_framed = true


## The board and the Core together: what the first look has to contain.
func frame_rect() -> Rect2:
	return board_frame_rect().merge(core_rect().grow(8.0))


## The world rectangle the default view has to show: the board, plus the
## height of the tallest machine above its back corner.
static func board_frame_rect() -> Rect2:
	var r: Rect2 = Iso.board_rect()
	return r.grow_individual(Iso.TW * 0.35, Iso.TH * 2.2, Iso.TW * 0.35, Iso.TH * 0.6)


## The zoom the default view settles on, for the touch-target report.
func default_zoom() -> float:
	var fr: Rect2 = free_rect if free_rect.size.x > 8.0 else Rect2(Vector2.ZERO, size)
	var r: Rect2 = frame_rect()
	return cam.clamp_zoom(minf(fr.size.x / r.size.x, fr.size.y / r.size.y))


## Descending has to look like going somewhere. One painting, tinted per band:
## daylight at the surface, lamp light in the Workings, red in the Deep, violet
## in the Abyss. A tint rather than four paintings until the bands earn their
## own art.
static func band_tint(depth: int) -> Color:
	const TINTS := [Color(1.06, 1.06, 1.10), Color(1.0, 0.97, 0.94),
		Color(0.80, 0.62, 0.66), Color(0.50, 0.42, 0.70), Color(0.36, 0.30, 0.58)]
	var b: Array = Palette.band_at(depth)
	var i: int = int(b[0])
	return (TINTS[i] as Color).lerp(TINTS[i + 1], float(b[1]) * 0.6)


func _refresh_sheet() -> void:
	var n: String = IsoArt.sheet_name(Store.active_theme(), Sim.upgrade_marks())
	if n == _sheet_name and _atlas != null:
		return
	_sheet_name = n
	_sheet = IsoArt.sheet(n)
	_atlas = IsoArt.texture(String(_sheet.get("file", "")))


## Called when a palette is chosen. Swapping the atlas is the whole cost.
func palette_changed() -> void:
	_refresh_sheet()


func _on_stats() -> void:
	if Sim.grid == null:
		return
	_links = Iso.links(Sim.grid)
	_segments = Iso.segments(_links)
	_refresh_sheet()
	# Material the simulation actually moved this tick lights its pipes.
	if Sim.sim != null:
		for t: Array in Sim.sim.last_transfers:
			for l: Dictionary in _links:
				if int(l["from"]) == int(t[0]) and int(l["to"]) == int(t[1]):
					var path: Array = l["path"]
					for i in range(path.size() - 1):
						var a: int = int(path[i])
						var b: int = int(path[i + 1])
						_flow["%d-%d" % [mini(a, b), maxi(a, b)]] = 0.6
	badges.update(_raw_states(), 0.0)


func _raw_states() -> Dictionary:
	var raw: Dictionary = {}
	for cell: int in Sim.grid.cells:
		raw[cell] = StatusBadges.classify(Sim.sim, cell)
	return StatusBadges.root_causes(raw, _links)


func pulse(cell: int) -> void:
	_flash[cell] = 1.0


func set_overlay(mode: int) -> void:
	overlay = mode


func toggle_heat_overlay() -> bool:
	overlay = Overlay.NONE if overlay == Overlay.HEAT else Overlay.HEAT
	return overlay == Overlay.HEAT


## Glide to a cell and close in on it -- the Problems button uses this.
func focus_cell(cell: int) -> void:
	cam.focus(Iso.cell_center(cell) - Vector2(0, Iso.TH * 0.4),
		maxf(cam.zoom, 1.15))


func cell_at_screen(p: Vector2) -> int:
	return Iso.cell_at(cam.screen_to_world(p))


func screen_of_cell(cell: int) -> Vector2:
	return cam.world_to_screen(Iso.cell_center(cell))


## --- frame -------------------------------------------------------------------

func _process(delta: float) -> void:
	_anim += delta
	if not _framed and size.x > 8.0:
		frame_board()
	cam.set_viewport(size)
	cam.step(delta)
	var t: Transform2D = cam.near_transform()
	for n: Node2D in [_floor, _floor_glow, _things, _glow]:
		n.transform = t
	_band_tint = _band_tint.lerp(_band_target, 1.0 - exp(-delta * 2.5))

	if _pressed and not _panning and not _dragging and not _long_fired \
			and _press_cell >= 0 and not Sim.grid.is_empty(_press_cell):
		_press_time += delta
		if _press_time >= LONG_PRESS_SECONDS:
			_long_fired = true
			cell_long_pressed.emit(_press_cell)
			Juice.reject()

	for k: int in _flash.keys():
		_flash[k] = float(_flash[k]) - delta * 2.4
		if float(_flash[k]) <= 0.0:
			_flash.erase(k)
	for k: String in _flow.keys():
		_flow[k] = float(_flow[k]) - delta
		if float(_flow[k]) <= 0.0:
			_flow.erase(k)

	if Sim.grid != null and Sim.sim != null:
		badges.update(_raw_states(), delta)

	# Published for the device self test: a cell's short axis on the physical
	# screen, now and at the closest zoom, so it can be turned into dp.
	var px_scale: float = get_tree().root.get_final_transform().get_scale().y
	SelfTest.last_cell_px = Iso.TH * cam.zoom * px_scale
	SelfTest.max_cell_px = Iso.TH * cam.zoom_max * px_scale

	queue_redraw()
	for n: Node2D in [_floor, _floor_glow, _things, _glow, _over]:
		n.queue_redraw()


## --- input -------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	# The pinch. Fingers are tracked here because a second finger may land on
	# a part of the screen some other control owns; the gesture belongs to
	# the world if the first finger does.
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		if _touches.size() >= 2 and (_pressed or _pinching):
			_start_pinch()
		elif _touches.size() < 2 and _pinching:
			_pinching = false
			_pressed = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_touches[sd.index] = sd.position
		if _pinching and _touches.size() >= 2:
			var pts: Array = _touches.values()
			var a: Vector2 = pts[0]
			var b: Vector2 = pts[1]
			var d: float = maxf(a.distance_to(b), 1.0)
			var mid: Vector2 = (a + b) * 0.5
			cam.zoom_by(d / _pinch_dist, mid)
			cam.drag(mid - _pinch_mid)
			_pinch_dist = d
			_pinch_mid = mid
			get_viewport().set_input_as_handled()


func _start_pinch() -> void:
	var pts: Array = _touches.values()
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	_pinching = true
	_pinch_dist = maxf(a.distance_to(b), 1.0)
	_pinch_mid = (a + b) * 0.5
	# Whatever the first finger was doing, it is now half of a pinch.
	_press_cell = -1
	_panning = false
	_dragging = false
	_long_fired = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					cam.zoom_toward(1.12, mb.position)
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					cam.zoom_toward(1.0 / 1.12, mb.position)
				accept_event()
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				if mb.pressed:
					_press(mb.position, mb.button_index != MOUSE_BUTTON_LEFT)
				else:
					_release(mb.position)
				accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _pressed and not _pinching:
			_move(mm.position, mm.relative)
			accept_event()
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		cam.zoom_by(mg.factor, mg.position)
		accept_event()
	elif event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		cam.drag(-pg.delta * 12.0)
		accept_event()


func _press(pos: Vector2, pan_only: bool) -> void:
	if _pinching:
		return
	_pressed = true
	_press_pos = pos
	_press_time = 0.0
	_panning = pan_only
	_dragging = false
	_long_fired = false
	_samples.clear()
	_samples.append([Time.get_ticks_msec(), pos])
	_press_cell = -1 if pan_only else cell_at_screen(pos)


func _move(pos: Vector2, rel: Vector2) -> void:
	if _long_fired:
		return
	if not _panning and not _dragging and pos.distance_to(_press_pos) > DRAG_THRESHOLD:
		if _press_cell >= 0 and _press_cell == selected_cell \
				and not Sim.grid.is_empty(_press_cell):
			_dragging = true
		else:
			_panning = true
			# The threshold is dead zone, not lost motion: catch up to the
			# finger so the world is still exactly under it.
			rel = pos - _press_pos
	if _dragging:
		_drag_pos = pos
	elif _panning:
		cam.drag(rel)
		_samples.append([Time.get_ticks_msec(), pos])
		if _samples.size() > 6:
			_samples.pop_front()


func _release(pos: Vector2) -> void:
	if not _pressed:
		return
	_pressed = false
	var from_cell: int = _press_cell
	_press_cell = -1
	if _pinching:
		return
	if _long_fired:
		_long_fired = false
		return
	if _dragging:
		_dragging = false
		var to_cell: int = cell_at_screen(pos)
		if to_cell >= 0 and to_cell != from_cell and Sim.grid.is_empty(to_cell) \
				and not Sim.is_blocked(to_cell):
			if Sim.move_machine(from_cell, to_cell):
				selected_cell = to_cell
				machine_moved.emit(from_cell, to_cell)
				Juice.place()
		return
	if _panning:
		_panning = false
		cam.release(_fling_velocity())
		return
	var cell: int = cell_at_screen(pos)
	if cell >= 0 and cell == from_cell:
		cell_tapped.emit(cell)
	elif cell < 0:
		ground_tapped.emit()


func _fling_velocity() -> Vector2:
	if _samples.size() < 2:
		return Vector2.ZERO
	var now: int = Time.get_ticks_msec()
	var first: Array = _samples[0]
	for s: Array in _samples:
		if now - int(s[0]) <= 90:
			first = s
			break
	var last: Array = _samples[_samples.size() - 1]
	var dt: float = float(int(last[0]) - int(first[0])) / 1000.0
	if dt <= 0.0 or now - int(last[0]) > 80:
		return Vector2.ZERO
	return ((last[1] as Vector2) - (first[1] as Vector2)) / dt


## --- the painting --------------------------------------------------------------

func _draw() -> void:
	if _world_tex == null:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.BG, true)
		return
	draw_set_transform_matrix(cam.bg_transform())
	draw_texture(_world_tex, Vector2.ZERO, _band_tint)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# A little haze over the far world so the island reads as nearer.
	var haze: Color = Color(0.10, 0.12, 0.20, 0.18)
	draw_rect(Rect2(Vector2.ZERO, size), haze, true)


## --- the floor ---------------------------------------------------------------

func _island_transform() -> Transform2D:
	var isl: Dictionary = IsoArt.layout().get("island", {})
	var tc: Array = isl.get("top_center", [1024, 378])
	var half_w: float = float(isl.get("top_half_w", 1024))
	var half_h: float = float(isl.get("top_half_h", 372))
	var n: float = float(Iso.slab_cells())
	var sx: float = n * Iso.TW * 0.5 / half_w
	# The painted top is flatter than 2:1; it is stretched to the board's own
	# projection so the stone around the board lies in the same plane.
	var sy: float = n * Iso.TH * 0.5 / half_h
	var lift: float = float(IsoArt.placement().get("board_lift", 10))
	var top: Vector2 = Iso.anchor() + Vector2(0.0, lift)
	return Transform2D(0.0, Vector2(sx, sy), 0.0,
		top - Vector2(float(tc[0]) * sx, float(tc[1]) * sy))


func _draw_floor() -> void:
	var ci: CanvasItem = _floor
	var lift: float = float(IsoArt.placement().get("board_lift", 10))
	if _island_tex != null:
		ci.draw_set_transform_matrix(_island_transform())
		ci.draw_texture(_island_tex, Vector2.ZERO,
			Color.WHITE.lerp(_band_tint, 0.55))
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)

	_draw_expansion(ci)

	var bc: PackedVector2Array = Iso.board_corners()
	# The board is a raised slab: its two front faces are drawn once, along the
	# front edges, instead of a lip on every tile -- which is what used to turn
	# the seams into a grid of thick lines.
	var down := Vector2(0.0, lift)
	var lit := Color(0.52, 0.44, 0.38).lerp(_band_tint, 0.2)
	var shade := Color(0.30, 0.25, 0.23).lerp(_band_tint, 0.2)
	ci.draw_colored_polygon(PackedVector2Array([bc[3], bc[2], bc[2] + down,
		bc[3] + down]), lit)
	ci.draw_colored_polygon(PackedVector2Array([bc[2], bc[1], bc[1] + down,
		bc[2] + down]), shade)

	_draw_tiles(ci)
	_draw_rim(ci, bc)
	_draw_floor_marks(ci)

	# Contact shadows: a machine that casts nothing floats.
	var g: Texture2D = IsoArt.glow()
	for cell: int in Sim.grid.cells:
		var c: Vector2 = Iso.cell_center(cell) + Vector2(4.0, 6.0)
		ci.draw_texture_rect(g, Rect2(c - Vector2(Iso.TW * 0.46, Iso.TH * 0.46),
			Vector2(Iso.TW * 0.92, Iso.TH * 0.92)), false, Color(0, 0, 0, 0.55))


## The ground the factory does not own yet: the rest of the slab. Locked
## plots are dimmed and fenced so they read as "not yet" rather than as
## decoration, and nothing on them is part of any rule.
func _draw_expansion(ci: CanvasItem) -> void:
	var ex: Array = IsoArt.placement().get("expansion", [])
	if ex.size() < 2:
		return
	var a: Array = ex[0]
	var b: Array = ex[1]
	var dim := Color(0.05, 0.06, 0.10, 0.30)
	var edge := Color(1.0, 0.85, 0.55, 0.16)
	for sy in range(int(a[1]), int(b[1]) + 1):
		for sx in range(int(a[0]), int(b[0]) + 1):
			var t: Vector2 = Iso.slab_top(sx, sy)
			var pts := PackedVector2Array([t, t + Vector2(Iso.TW * 0.5, Iso.TH * 0.5),
				t + Vector2(0, Iso.TH), t + Vector2(-Iso.TW * 0.5, Iso.TH * 0.5)])
			ci.draw_colored_polygon(pts, dim)
	# The plot's outline, dashed: ground that is marked out and not yet built.
	var c := PackedVector2Array([Iso.slab_top(int(a[0]), int(a[1])),
		Iso.slab_top(int(b[0]) + 1, int(a[1])), Iso.slab_top(int(b[0]) + 1, int(b[1]) + 1),
		Iso.slab_top(int(a[0]), int(b[1]) + 1)])
	for e in range(4):
		ci.draw_dashed_line(c[e], c[(e + 1) % 4], edge, 3.0, 12.0)


func _draw_tiles(ci: CanvasItem) -> void:
	if _tiles == null:
		for cell in range(Grid.W * Grid.H):
			ci.draw_colored_polygon(Iso.cell_points(cell), Palette.CELL)
		return
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var blocked: Dictionary = Strata.blocked_cells(Sim.depth)
	var base: Color = Color.WHITE.lerp(_band_tint, 0.35)
	for cell in range(Grid.W * Grid.H):
		var p: PackedVector2Array = Iso.cell_points(cell)
		var uv: Rect2 = IsoArt.tile_uv(IsoArt.tile_variant(cell, Sim.depth))
		# The square slab texture turned 45 degrees: its top-left corner goes to
		# the diamond's left point, so the painted light falls from the left.
		var u0: Vector2 = uv.position
		var u1: Vector2 = uv.position + uv.size
		var tuv := PackedVector2Array([Vector2(u0.x, u0.y), Vector2(u1.x, u0.y),
			Vector2(u1.x, u1.y), Vector2(u0.x, u1.y)])
		var c: Color = base
		# A little light falling off towards the front, and variation per
		# slab, so seventy squares read as a floor rather than a table.
		var pxy: Vector2i = Grid.xy(cell)
		var k: float = float((hash(cell * 7 + Sim.depth) & 0xff)) / 255.0
		c = c * (0.90 + 0.10 * k)
		c.a = 1.0
		if blocked.has(cell):
			c = Color(0.35, 0.33, 0.36)
		elif overlay == Overlay.HEAT:
			c = c.lerp(Palette.heat_color(Sim.grid.heat_at(cell)), 0.55)
		var shade: float = 1.0 - 0.05 * float(pxy.x + pxy.y) / float(Grid.W + Grid.H)
		c = Color(c.r * shade, c.g * shade, c.b * shade, 1.0)
		var i0: int = pts.size()
		for j in range(4):
			pts.append(p[(j + 3) % 4])
			uvs.append(tuv[j])
			cols.append(c)
		idx.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts,
		cols, uvs, PackedInt32Array(), PackedFloat32Array(), _tiles.get_rid())


## The iron frame around the board: the edge of what the factory owns.
func _draw_rim(ci: CanvasItem, bc: PackedVector2Array) -> void:
	var w: float = 7.0
	var dark := Color(0.13, 0.13, 0.17)
	var top := Color(0.36, 0.33, 0.33)
	var brass := Color(0.86, 0.66, 0.30)
	var closed := PackedVector2Array([bc[0], bc[1], bc[2], bc[3], bc[0]])
	ci.draw_polyline(closed, dark, w + 3.0, true)
	ci.draw_polyline(closed, top, w * 0.45, true)
	# Rivets along the edges, one per cell, brass on iron.
	for e in range(4):
		var a: Vector2 = bc[e]
		var b: Vector2 = bc[(e + 1) % 4]
		var cells: int = Grid.W if e % 2 == 0 else Grid.H
		for i in range(cells + 1):
			var p: Vector2 = a.lerp(b, float(i) / float(cells))
			ci.draw_circle(p, 2.6, brass)


func _diamond(cell: int, grow: float) -> PackedVector2Array:
	var c: Vector2 = Iso.cell_center(cell)
	var hw: float = Iso.TW * 0.5 * grow
	var hh: float = Iso.TH * 0.5 * grow
	return PackedVector2Array([c + Vector2(0, -hh), c + Vector2(hw, 0),
		c + Vector2(0, hh), c + Vector2(-hw, 0), c + Vector2(0, -hh)])


## Marks that belong on the ground: where a finger could place, what is
## selected, what the tutorial is pointing at, where a dragged machine lands.
func _draw_floor_marks(ci: CanvasItem) -> void:
	var pulse: float = 0.5 + 0.5 * sin(_anim * 3.4)
	if arm_id != "" and overlay != Overlay.HEAT and Sim.can_afford(arm_id):
		var ghost: Color = Palette.machine_light(arm_id)
		ghost.a = 0.22 + 0.10 * pulse
		for cell in range(Grid.W * Grid.H):
			if not Sim.grid.is_empty(cell) or Sim.is_blocked(cell):
				continue
			if not (Sim.grid.cells.is_empty() or _touches_machine(cell)):
				continue
			ci.draw_polyline(_diamond(cell, 0.62), ghost, 2.0, true)
	for cell in highlight_cells:
		if cell < 0 or cell >= Grid.W * Grid.H:
			continue
		var col: Color = Palette.ACCENT
		col.a = 0.35 + 0.5 * pulse
		ci.draw_polyline(_diamond(cell, 0.96 + 0.04 * pulse), col, 3.0 + 1.5 * pulse, true)
	if selected_cell >= 0 and not Sim.grid.is_empty(selected_cell):
		var sel: Color = Palette.ACCENT
		sel.a = 0.75
		ci.draw_polyline(_diamond(selected_cell, 1.0), sel, 3.0, true)
		for nb in Sim.grid.neighbours(selected_cell):
			if Sim.grid.is_empty(nb):
				continue
			var c2: Color = Palette.ACCENT
			c2.a = 0.30
			ci.draw_polyline(_diamond(nb, 0.9), c2, 2.0, true)
	if _dragging and selected_cell >= 0:
		var target: int = cell_at_screen(_drag_pos)
		if target >= 0 and Sim.grid.is_empty(target) and not Sim.is_blocked(target):
			ci.draw_colored_polygon(_diamond(target, 0.94).slice(0, 4),
				Color(Palette.GOOD, 0.35))
	if _pressed and not _panning and not _dragging and _press_cell >= 0:
		ci.draw_polyline(_diamond(_press_cell, 1.0), Palette.ACCENT, 2.5, true)


func _touches_machine(cell: int) -> bool:
	for n in Sim.grid.neighbours(cell):
		if not Sim.grid.is_empty(n):
			return true
	return false


## --- light on the floor ------------------------------------------------------

func _draw_floor_glow() -> void:
	var ci: CanvasItem = _floor_glow
	var g: Texture2D = IsoArt.glow()
	for cell: int in Sim.grid.cells:
		var st: int = Sim.sim.status_of(cell)
		if st == Simulation.Status.STARVED or st == Simulation.Status.BLOCKED:
			continue
		var k: float = 1.0 if st == Simulation.Status.RUNNING else 0.45
		k += float(_flash.get(cell, 0.0)) * 0.9
		var col: Color = Palette.machine_light(Sim.grid.machine_at(cell))
		var shown: int = badges.shown(cell)
		if shown == StatusBadges.Show.HOT or shown == StatusBadges.Show.CRITICAL:
			col = Palette.ST_HOT
			k *= 1.3 + 0.3 * sin(_anim * 5.0)
		col.a = 0.20 * k
		var c: Vector2 = Iso.cell_center(cell)
		ci.draw_texture_rect(g, Rect2(c - Vector2(Iso.TW, Iso.TH) * 0.95,
			Vector2(Iso.TW, Iso.TH) * 1.9), false, col)
	# The rim's four corner lamps.
	var bc: PackedVector2Array = Iso.board_corners()
	for p in bc:
		var lamp := Color(1.0, 0.72, 0.36, 0.55 + 0.05 * sin(_anim * 2.0))
		ci.draw_texture_rect(g, Rect2(p - Vector2(34, 22), Vector2(68, 44)), false, lamp)


## --- pipes and machines, back to front ---------------------------------------

## How much of a cell a machine's plate covers. Less than all of it, so there
## is floor between neighbours for a pipe to cross -- the reason pipes
## vanished when machines grew.
func _footprint() -> float:
	return float(IsoArt.placement().get("footprint", 0.80))


func _draw_things() -> void:
	var ci: CanvasItem = _things
	var o: Vector2i = Iso.board_offset()
	# Everything that stands on the slab -- machines, pipes, the Core, props --
	# in one list sorted by slab depth, so a lamp on the front rim covers the
	# machine behind it and the Core's tower is covered by the machines in
	# front of it.
	var items: Array = []
	var blocked: Dictionary = Strata.blocked_cells(Sim.depth)
	for cell in range(Grid.W * Grid.H):
		var p: Vector2i = Grid.xy(cell)
		items.append([float(p.x + o.x + p.y + o.y), 0, cell])
	for key: String in _segments:
		var sg: Dictionary = _segments[key]
		var pa: Vector2i = Grid.xy(int(sg["a"]))
		var pb: Vector2i = Grid.xy(int(sg["b"]))
		var back: float = float(mini(pa.x + pa.y, pb.x + pb.y) + o.x + o.y)
		# After the machine it leaves, before the one it reaches.
		items.append([back + 0.5, 1, key])
	var props: Array = IsoArt.placement().get("props", [])
	for pr: Array in props:
		items.append([float(int(pr[0]) + int(pr[1])) - 0.25, 2, pr])
	var cc: Array = IsoArt.placement().get("core_cell", [])
	if cc.size() == 2:
		var n: int = int(IsoArt.placement().get("core_size", 3))
		items.append([float(int(cc[0]) + int(cc[1]) + n) - 0.75, 3, null])
	items.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for it: Array in items:
		match int(it[1]):
			0:
				var cell: int = int(it[2])
				if blocked.has(cell):
					_draw_rubble(ci, cell)
				var id: String = Sim.grid.machine_at(cell)
				if id != "" and not (_dragging and cell == selected_cell):
					_draw_machine(ci, cell, id)
			1:
				_draw_pipe(ci, String(it[2]))
			2:
				_draw_prop(ci, it[2])
			3:
				_draw_core(ci)
	if _dragging and selected_cell >= 0 and not Sim.grid.is_empty(selected_cell):
		var w: Vector2 = cam.screen_to_world(_drag_pos)
		_draw_sprite(ci, Sim.grid.machine_at(selected_cell), w + Vector2(0, Iso.TH * 0.2),
			Color(1, 1, 1, 0.8), 1.0)


## The Factory Core: three cells of the slab, behind the board, never on it.
## It is the landmark the eye finds first and it takes no tile from play.
func core_center() -> Vector2:
	var cc: Array = IsoArt.placement().get("core_cell", [1, 1])
	var n: float = float(IsoArt.placement().get("core_size", 3))
	return Iso.slab_top(float(cc[0]) + n * 0.5, float(cc[1]) + n * 0.5)


func core_rect() -> Rect2:
	var info: Dictionary = IsoArt.layout().get("core", {})
	if info.is_empty():
		return Rect2(core_center(), Vector2.ZERO)
	var n: float = float(IsoArt.placement().get("core_size", 3))
	var s: float = n * Iso.TW * 0.86 / IsoArt.base_px(info)
	var cell: Array = info["cell"]
	var a: Vector2 = IsoArt.anchor(info)
	return Rect2(core_center() - a * s, Vector2(float(cell[0]), float(cell[1])) * s)


func _draw_core(ci: CanvasItem) -> void:
	var info: Dictionary = IsoArt.layout().get("core", {})
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	if tex == null:
		return
	var r: Rect2 = core_rect()
	# It breathes with the factory: brighter the more of the board is running.
	var running: int = 0
	for cell: int in Sim.grid.cells:
		if Sim.sim.status_of(cell) == Simulation.Status.RUNNING:
			running += 1
	var k: float = clampf(float(running) / 12.0, 0.0, 1.0)
	var mod := Color(0.9, 0.9, 0.95).lerp(Color(1.08, 1.06, 1.02), k)
	ci.draw_texture_rect_region(tex, r, IsoArt.region(info, 0), mod)


func _draw_prop(ci: CanvasItem, pr: Array) -> void:
	var info: Dictionary = IsoArt.layout().get("props", {})
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	if tex == null:
		return
	var k: int = (info.get("order", []) as Array).find(String(pr[2]))
	if k < 0:
		return
	var at: Vector2 = Iso.slab_top(float(pr[0]) + 0.5, float(pr[1]) + 0.5)
	var s: float = Iso.TW * 0.78 / IsoArt.base_px(info)
	var a: Vector2 = IsoArt.anchor(info)
	var region: Rect2 = IsoArt.region(info, k)
	ci.draw_texture_rect_region(tex, Rect2(at - a * s, region.size * s), region,
		Color.WHITE.lerp(_band_tint, 0.3))


func _draw_rubble(ci: CanvasItem, cell: int) -> void:
	var c: Vector2 = Iso.cell_center(cell)
	for k in range(3):
		var o := Vector2(-18.0 + 18.0 * k, -2.0 + 5.0 * (k % 2))
		ci.draw_circle(c + o, 9.0 - k, Color(0.24, 0.22, 0.25))
		ci.draw_circle(c + o - Vector2(2, 3), 5.0 - k, Color(0.40, 0.37, 0.40))


func _draw_sprite(ci: CanvasItem, id: String, at: Vector2, mod: Color, squash: float) -> void:
	if _atlas == null:
		ci.draw_circle(at, Iso.TH * 0.35, Palette.machine_color(id))
		return
	var region: Rect2 = IsoArt.machine_region(_sheet, id)
	var s: float = Iso.TW * _footprint() / IsoArt.base_px(_sheet)
	var a: Vector2 = IsoArt.anchor(_sheet)
	var size_w := Vector2(region.size.x * s, region.size.y * s * squash)
	var pos := Vector2(at.x - a.x * s, at.y - a.y * s * squash)
	ci.draw_texture_rect_region(_atlas, Rect2(pos, size_w), region, mod)


## Everything about a machine's state that its body can say without a word:
## a working machine breathes, a stalled one goes dark, an overheating one
## flushes, and research shows as notches on its plate until the whole set
## turns gold.
func _draw_machine(ci: CanvasItem, cell: int, id: String) -> void:
	var st: int = Sim.sim.status_of(cell)
	var shown: int = badges.shown(cell)
	var running: bool = st == Simulation.Status.RUNNING
	var stalled: bool = st == Simulation.Status.STARVED or st == Simulation.Status.BLOCKED
	var mod := Color.WHITE
	if stalled:
		mod = Color(0.62, 0.62, 0.68)
	elif st == Simulation.Status.IDLE:
		mod = Color(0.82, 0.82, 0.86)
	match shown:
		StatusBadges.Show.MILD:
			var hot: bool = Sim.sim.heat_delta_at(cell) > 0.0
			mod = mod * (Color(1.06, 0.96, 0.90) if hot else Color(0.92, 0.98, 1.08))
		StatusBadges.Show.HOT:
			mod = mod * Color(1.12, 0.92, 0.82)
		StatusBadges.Show.COLD:
			mod = mod * Color(0.86, 0.96, 1.14)
		StatusBadges.Show.CRITICAL:
			var k: float = 0.5 + 0.5 * sin(_anim * 6.0)
			mod = mod * Color(1.0 + 0.2 * k, 0.85 - 0.1 * k, 0.8 - 0.1 * k)
	if overlay == Overlay.HEAT:
		var m: Dictionary = MachineDB.get_machine(id)
		var dv: Color = Palette.divergent_color(Sim.sim.heat_delta_at(cell),
			float(m["heat_tolerance"]) + Sim.sim.tolerance_bonus)
		mod = mod * Color.WHITE.lerp(dv.lightened(0.35), 0.45)
	if cell == selected_cell:
		mod = mod * Color(1.12, 1.12, 1.12)
	var flash: float = float(_flash.get(cell, 0.0))
	if flash > 0.0:
		mod = mod.lerp(Color(1.4, 1.4, 1.4), flash * 0.4)
	mod.a = 1.0
	# The breath: a percent of height on the cycle, and only while working.
	var squash: float = 1.0
	if running:
		squash = 1.0 + 0.012 * sin(Sim.sim.progress_of(cell) * TAU)
	_draw_sprite(ci, id, Iso.cell_center(cell), mod, squash)

	var marks: int = Sim.upgrade_marks()
	if marks > 0 and marks < IsoArt.UP_SHEET_MARKS:
		var f: Vector2 = Iso.cell_center(cell) + Vector2(0, Iso.TH * 0.5 * _footprint() + 2.0)
		for k in range(marks):
			ci.draw_circle(f + Vector2(-6.0 + 12.0 * k, -2.0), 3.0, Palette.CORE)


func _draw_pipe(ci: CanvasItem, key: String) -> void:
	var s: Dictionary = _segments[key]
	var a: Vector2 = Iso.cell_center(int(s["a"]))
	var b: Vector2 = Iso.cell_center(int(s["b"]))
	var dir: Vector2 = (b - a).normalized()
	# From the edge of one plate to the edge of the next, raised a little off
	# the floor so it reads as a pipe lying across the seam.
	# Plate edge to plate edge, and a little under each plate, so the ends are
	# tucked in rather than floating.
	var reach: float = a.distance_to(b) * (0.5 - _footprint() * 0.5) + 16.0
	var mid: Vector2 = (a + b) * 0.5 - Vector2(0, 9.0)
	var p0: Vector2 = mid - dir * reach
	var p1: Vector2 = mid + dir * reach
	var res: int = int(s["res"])
	var col: Color = Palette.res_color(res)
	var live: bool = _flow.has(key)
	var warn: Color = Color(0, 0, 0, 0)
	for cell: int in [int(s["a"]), int(s["b"])]:
		var sh: int = badges.shown(cell)
		if sh == StatusBadges.Show.BLOCKED:
			warn = Palette.ST_BLOCKED
		elif sh == StatusBadges.Show.STARVED and warn.a == 0.0:
			warn = Palette.ST_STARVED
	ci.draw_line(p0 + Vector2(0, 5), p1 + Vector2(0, 5), Color(0, 0, 0, 0.35), 14.0, true)
	ci.draw_line(p0, p1, Color(0.16, 0.15, 0.18), 14.0, true)
	var body: Color = col.lerp(Color(0.25, 0.25, 0.3), 0.15 if live else 0.55)
	if warn.a > 0.0:
		body = body.lerp(warn, 0.35 + 0.25 * sin(_anim * 5.0))
	ci.draw_line(p0, p1, body, 9.5, true)
	ci.draw_line(p0 - Vector2(0, 2.5), p1 - Vector2(0, 2.5), body.lightened(0.5), 2.5, true)
	var brass := Color(0.80, 0.62, 0.30)
	var n := Vector2(-dir.y, dir.x)
	for p in [p0, p1]:
		ci.draw_line(p - n * 8.5, p + n * 8.5, brass, 4.5, true)


## --- light on top ------------------------------------------------------------

func _draw_glow() -> void:
	var ci: CanvasItem = _glow
	var g: Texture2D = IsoArt.glow()
	for cell: int in Sim.grid.cells:
		var st: int = Sim.sim.status_of(cell)
		var k: float = 0.0
		match st:
			Simulation.Status.RUNNING:
				k = 0.55 + 0.25 * sin(Sim.sim.progress_of(cell) * TAU)
			Simulation.Status.PASSIVE:
				k = 0.45
			Simulation.Status.IDLE:
				k = 0.2
			_:
				k = 0.05
		k += float(_flash.get(cell, 0.0))
		var id: String = Sim.grid.machine_at(cell)
		var col: Color = Palette.machine_light(id)
		col.a = 0.32 * k
		var c: Vector2 = Iso.cell_center(cell) - Vector2(0, Iso.TH * 0.75)
		ci.draw_texture_rect(g, Rect2(c - Vector2(34, 34), Vector2(68, 68)), false, col)
	# Material moving: a bright bead travelling along each live pipe.
	for key: String in _flow:
		if not _segments.has(key):
			continue
		var s: Dictionary = _segments[key]
		var a: Vector2 = Iso.cell_center(int(s["a"]))
		var b: Vector2 = Iso.cell_center(int(s["b"]))
		var t: float = fposmod(_anim * 1.6 + float(int(s["a"]) % 7) * 0.13, 1.0)
		var from_a: bool = true
		for l: Dictionary in _links:
			if (l["path"] as Array).has(int(s["a"])) and (l["path"] as Array).has(int(s["b"])):
				var path: Array = l["path"]
				from_a = path.find(int(s["a"])) < path.find(int(s["b"]))
				break
		var p: Vector2 = (a.lerp(b, t) if from_a else b.lerp(a, t)) - Vector2(0, 12)
		var col2: Color = Palette.res_color(int(s["res"])).lightened(0.35)
		col2.a = 0.95 * clampf(float(_flow[key]) * 2.0, 0.0, 1.0)
		ci.draw_texture_rect(g, Rect2(p - Vector2(17, 17), Vector2(34, 34)), false, col2)


## --- screen-space overlay ------------------------------------------------------

func _badge_side(cell: int, downstream: bool) -> Vector2:
	var c: Vector2 = Iso.cell_center(cell)
	var acc := Vector2.ZERO
	for l: Dictionary in _links:
		if downstream and int(l["from"]) == cell:
			acc += Iso.cell_center(int(l["to"])) - c
		elif not downstream and int(l["to"]) == cell:
			acc += Iso.cell_center(int(l["from"])) - c
	if acc == Vector2.ZERO:
		return Vector2(0.55, -0.4)
	return acc.normalized()


func _draw_over() -> void:
	var ci: CanvasItem = _over
	var font: Font = ThemeDB.fallback_font
	var z: float = cam.zoom
	var r: float = clampf(12.0 * z, 9.0, 16.0)
	for cell: int in Sim.grid.cells:
		var shown: int = badges.shown(cell)
		if shown == StatusBadges.Show.NONE or shown == StatusBadges.Show.MILD:
			continue
		var top: Vector2 = cam.world_to_screen(Iso.cell_center(cell)
			- Vector2(0, Iso.TH * 1.25))
		var p: Vector2 = top
		match shown:
			StatusBadges.Show.BLOCKED:
				p = cam.world_to_screen(Iso.cell_center(cell)
					+ _badge_side(cell, true) * Iso.TW * 0.32 - Vector2(0, Iso.TH * 0.55))
			StatusBadges.Show.STARVED:
				p = cam.world_to_screen(Iso.cell_center(cell)
					+ _badge_side(cell, false) * Iso.TW * 0.32 - Vector2(0, Iso.TH * 0.55))
		_draw_badge(ci, p, r, shown)

	if selected_cell >= 0 and not Sim.grid.is_empty(selected_cell) and not _dragging:
		_draw_selected_links(ci)
		var top: Vector2 = cam.world_to_screen(Iso.cell_center(selected_cell)
			- Vector2(0, Iso.TH * 1.55))
		var bob: float = sin(_anim * 4.0) * 4.0
		var t := top + Vector2(0, bob)
		var w: float = clampf(11.0 * z, 8.0, 15.0)
		ci.draw_colored_polygon(PackedVector2Array([t + Vector2(-w, -w * 1.2),
			t + Vector2(w, -w * 1.2), t]), Color(0, 0, 0, 0.4))
		ci.draw_colored_polygon(PackedVector2Array([t + Vector2(-w, -w * 1.4),
			t + Vector2(w, -w * 1.4), t + Vector2(0, -w * 0.15)]), Palette.ACCENT)
	if overlay == Overlay.HEAT and z > 0.55:
		_draw_heat_numbers(ci, font)
	if _pressed and not _panning and not _dragging and _press_cell >= 0:
		_draw_placement_preview(ci, font)


## "Where is this machine fed from, and where does its output go": every link
## in and out of the selected machine, drawn over everything as a lit line
## with chevrons running the way material runs. It is the one moment the
## pipes are allowed on top of the machines, because it is the moment the
## player asked.
func _draw_selected_links(ci: CanvasItem) -> void:
	var lift := Vector2(0, -Iso.TH * 0.45)
	for l: Dictionary in _links:
		var path: Array = l["path"]
		if int(l["from"]) != selected_cell and int(l["to"]) != selected_cell:
			continue
		var col: Color = Palette.res_color(int(l["res"])).lightened(0.25)
		var pts := PackedVector2Array()
		for c in path:
			pts.append(cam.world_to_screen(Iso.cell_center(int(c)) + lift))
		ci.draw_polyline(pts, Color(0, 0, 0, 0.55), 7.0, true)
		ci.draw_polyline(pts, col, 3.5, true)
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var d: Vector2 = (b - a).normalized()
			var n := Vector2(-d.y, d.x)
			for k in range(2):
				var t: float = fposmod(_anim * 0.9 + 0.5 * float(k), 1.0)
				var p: Vector2 = a.lerp(b, 0.2 + 0.6 * t)
				ci.draw_colored_polygon(PackedVector2Array([p + d * 7.0,
					p - d * 5.0 + n * 6.0, p - d * 5.0 - n * 6.0]), col)


func _draw_badge(ci: CanvasItem, p: Vector2, r: float, kind: int) -> void:
	var bob: float = sin(_anim * 3.0) * 1.5
	p.y += bob
	ci.draw_circle(p + Vector2(0, 2), r + 1.5, Color(0, 0, 0, 0.45))
	var col: Color
	match kind:
		StatusBadges.Show.BLOCKED: col = Palette.ST_BLOCKED
		StatusBadges.Show.STARVED: col = Palette.ST_STARVED
		StatusBadges.Show.HOT: col = Palette.ST_HOT
		StatusBadges.Show.COLD: col = Palette.ST_COLD
		_: col = Palette.BAD
	if kind == StatusBadges.Show.CRITICAL:
		var k: float = 0.5 + 0.5 * sin(_anim * 7.0)
		ci.draw_circle(p, r * (1.35 + 0.25 * k), Color(col, 0.25 * (1.0 - k)))
	ci.draw_circle(p, r + 1.5, Color(0.08, 0.09, 0.12))
	ci.draw_circle(p, r, col)
	var w := Color(1, 1, 1, 0.95)
	var u: float = r * 0.5
	# A different glyph for every state, not only a different colour.
	match kind:
		StatusBadges.Show.BLOCKED:
			ci.draw_rect(Rect2(p + Vector2(-u * 0.75, -u * 0.8), Vector2(u * 0.5, u * 1.6)), w)
			ci.draw_rect(Rect2(p + Vector2(u * 0.25, -u * 0.8), Vector2(u * 0.5, u * 1.6)), w)
		StatusBadges.Show.STARVED:
			ci.draw_arc(p, u * 0.95, 0.0, TAU, 20, w, maxf(r * 0.16, 2.0), true)
			ci.draw_line(p + Vector2(-u, u), p + Vector2(u, -u), w, maxf(r * 0.16, 2.0), true)
		StatusBadges.Show.HOT:
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -u * 1.2),
				p + Vector2(u * 0.8, u * 0.4), p + Vector2(0, u), p + Vector2(-u * 0.8, u * 0.4)]), w)
		StatusBadges.Show.COLD:
			for a in range(3):
				var d := Vector2.from_angle(float(a) * PI / 3.0) * u * 1.05
				ci.draw_line(p - d, p + d, w, maxf(r * 0.14, 1.5), true)
		_:
			ci.draw_rect(Rect2(p + Vector2(-u * 0.18, -u * 1.0), Vector2(u * 0.36, u * 1.2)), w)
			ci.draw_circle(p + Vector2(0, u * 0.62), u * 0.2, w)


func _num(ci: CanvasItem, font: Font, at: Vector2, text: String, col: Color, fs: int,
		backing: bool = true) -> void:
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var p: Vector2 = at + Vector2(-ts.x * 0.5, ts.y * 0.3)
	if backing:
		ci.draw_rect(Rect2(p + Vector2(-5, -ts.y * 0.85), Vector2(ts.x + 10, ts.y * 1.1)),
			Color(Palette.BG, 0.78), true)
	ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_heat_numbers(ci: CanvasItem, font: Font) -> void:
	var blocked: Dictionary = Strata.blocked_cells(Sim.depth)
	for cell in range(Grid.W * Grid.H):
		if blocked.has(cell):
			continue
		var at: Vector2 = cam.world_to_screen(Iso.cell_center(cell))
		if Sim.grid.machine_at(cell) == "":
			var h: float = Sim.grid.heat_at(cell)
			if absf(h - Sim.grid.ambient_heat) > 0.05:
				_num(ci, font, at, "%.1f" % h, Palette.TEXT_DIM, 14)
		else:
			_num(ci, font, at - Vector2(0, Iso.TH * 0.5 * cam.zoom),
				"%+.1f" % Sim.sim.heat_delta_at(cell), Palette.TEXT, 15)


## What this placement would do, shown while the finger is still down: the
## heat it would push into each neighbour, and for a support machine how many
## it would serve. Same functions as the simulation, so the preview cannot
## promise what the placement will not deliver.
func _draw_placement_preview(ci: CanvasItem, font: Font) -> void:
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
	if m.has("amplify") or m.has("duplicate_chance"):
		var n: int = Sim.grid.serves_if_placed(cell)
		var col: Color = Palette.GOOD if n >= 3 else (Palette.WARN if n >= 1 else Palette.BAD)
		var at: Vector2 = cam.world_to_screen(Iso.cell_center(cell) - Vector2(0, Iso.TH * 1.6))
		_num(ci, font, at, "serves %d  x%.1f" % [n, Grid.factor_for(n)], col, 16)
	for nb in Sim.grid.neighbours(cell):
		var bleed: float = emitted * Sim.grid.heat_spread
		if Sim.grid.is_empty(cell) and absf(bleed) < 0.001:
			continue
		var txt: String = "%+.1f" % bleed
		var nid: String = Sim.grid.machine_at(nb)
		if nid != "":
			var nm: Dictionary = MachineDB.get_machine(nid)
			var now: float = Sim.grid.heat_at(nb)
			var before: float = MachineDB.heat_efficiency(now, float(nm["heat_optimum"]),
				float(nm["heat_tolerance"]) + Sim.sim.tolerance_bonus)
			var after: float = MachineDB.heat_efficiency(now + bleed, float(nm["heat_optimum"]),
				float(nm["heat_tolerance"]) + Sim.sim.tolerance_bonus)
			txt = "%+d%%" % int(round((after - before) * 100.0))
		var tint: Color = Palette.ST_HOT if bleed > 0.0 else Palette.ST_COLD
		_num(ci, font, cam.world_to_screen(Iso.cell_center(nb)), txt, tint.lightened(0.3), 15)
	if Sim.grid.is_empty(cell) and _atlas != null:
		# The machine itself, as a ghost on the tile it would stand on.
		var s: float = cam.zoom
		var region: Rect2 = IsoArt.machine_region(_sheet, id)
		var k: float = Iso.TW * _footprint() / IsoArt.base_px(_sheet) * s
		var a: Vector2 = IsoArt.anchor(_sheet)
		var at2: Vector2 = cam.world_to_screen(Iso.cell_center(cell))
		ci.draw_texture_rect_region(_atlas, Rect2(at2 - a * k, region.size * k), region,
			Color(1, 1, 1, 0.55))
