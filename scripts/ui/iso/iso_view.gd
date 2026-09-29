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
## A tap on the Factory Core.
signal core_tapped()
## A resource node on the ground round the yard (an index into the layout's
## props), tapped.
signal node_tapped(index: int)
## A gallery mouth past the yard's edge (Operations).
signal site_tapped(index: int)
signal bay_tapped()

## What pick_at_screen returns for the Factory Core, which is on no cell.
const CORE := -2
## The closest the default view comes: phones sit under it, a tablet stops
## here.
const YARD_ZOOM_MAX := 1.15
## The farthest the default view goes: a tile is still about 20 dp on a
## phone. A bigger yard is framed on the Core and panned for the rest.
const DEFAULT_ZOOM_MIN := 0.6

enum Overlay { NONE, HEAT }

const LONG_PRESS_SECONDS := 0.45
const DRAG_THRESHOLD := 14.0

var selected_cell: int = -1
## The resource node whose card is open (an index into placement.props), or -1.
var selected_node: int = -1
var _press_node: int = -1
var _props_mask: BitMap
## Each prop's fixed facts (_props_now), and the yard they were worked out for.
var _prop_facts: Array = []
var _prop_facts_depth: int = -1
## Yard cells the Core's tower hides from the camera, for the Core's current
## level (cells_behind_core), and how opaque the Core is drawn: it thins
## while the player is placing or dragging into one of them.
var _hidden: Array[int] = []
var _hidden_level: int = -1
var _core_alpha: float = 1.0
## Where the armed machine would be connected both ways (_linked_cells), and
## the machine and board it was worked out for.
var _linked: Dictionary = {}
var _linked_sig: Array = []
var highlight_cells: Array[int] = []
var arm_id: String = ""
## Pulse a ring round the Core's base: it is the thing to tap.
var highlight_core: bool = false
var overlay: int = Overlay.NONE

var cam := IsoCamera.new()
var badges := StatusBadges.new()
## The part of the screen the interface leaves clear. Set by the HUD; the
## camera frames the board inside it.
var free_rect := Rect2()
## The interface's panels, in screen space. The default view is stepped back
## until no corner of the board sits under one of them -- the free rectangle
## alone cannot know that the top corners of the screen are taken while the
## top middle is not.
var avoid_rects: Array[Rect2] = []

var _ground: Node2D
var _ground_sig: Array = []
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
## Seams whose material runs from the higher cell index to the lower.
var _flow_from_b: Dictionary = {}
var _links: Array = []
## The board version `_links` was worked out for, the links' paths by
## from * PAIR + to, and the badges' raw states as of the last tick.
var _links_version: int = -1
var _links_grid: Grid = null
var _paths: Dictionary = {}
var _raw: Dictionary = {}
const PAIR := 4096
## Each pipe's fixed shape, worked out with the links: [key, a, b, p0, p1,
## normal, colour]. The casing, its shadow and the brass collars are drawn
## with the ground, which redraws only when the board changes; the floor
## draws only the part that lights up.
var _pipe_geo: Array = []
var _side_down: Dictionary = {}
var _side_up: Dictionary = {}
## Iso.chain for the selected machine, worked out again only when the
## selection or the board changes.
var _chain: Array = []
var _chain_sig: Array = []
var _segments: Dictionary = {}
var _sheet_name: String = ""
var _sheet: Dictionary = {}
var _atlas: Texture2D
var _pick_img: Image
var _pick_sheet: String = ""
var _core_mask: BitMap
var _core_mask_file: String = ""
## The yard the view was last framed for.
var _yard := Vector2i.ZERO
## Ground the yard has just reached, lighting up in a wave: cell -> seconds
## until its light arrives (negative once it has).
var _opened: Dictionary = {}
var _glide_pending: bool = false
## Set while a card covers the world: the yard's wave and the glide wait
## for it, so the player sees the ground grow instead of it happening behind
## the "new machine" card a descent usually brings.
var hold_effects: bool = false
## Settings: the dust, sparks, steam and coins round working machines.
var effects: bool = true
## Settings: "Reduce motion" -- no plunge on descending (the colour still
## changes), no bobbing marks, and the camera cuts instead of gliding.
var calm_motion: bool = false
## 1 the moment the Core comes online, falling to 0.
var _core_flash: float = 0.0
var _tiles: Texture2D
var _world_tex: Texture2D
## Each band of the shaft has its own painting (layout.json "worlds"): the
## Surface, the Workings, the Deep, the Abyss. Only the band's own is held,
## and, while a dive crosses into a new band, the one it left, fading out.
var _world_band: int = -1
## The ground beyond the yard, the band's own (layout.json "terrain_bands"):
## one seamless picture laid across every cell the yard has not reached,
## TERRAIN_CELLS cells to a repeat, so it reads as land, not as slabs.
var _terrain: Texture2D
const TERRAIN_CELLS := 7.0
var _world_prev: Texture2D
var _world_fade: float = 0.0
var _island_tex: Texture2D
var _band_tint := Color.WHITE
var _band_target := Color.WHITE
var _framed: bool = false
## 1 -> 0 over a descent: the canyon drops away and the light changes.
var _dive: float = 0.0
var _dive_seconds: float = 1.4


func _ready() -> void:
	# With offsets: a bare set_anchors_preset keeps the current (empty) rect.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ground = _layer(false)
	# The land beyond the yard is one picture repeated (_draw_terrain).
	_ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	_floor = _layer(false)
	_floor_glow = _layer(true)
	_things = _layer(false)
	_glow = _layer(true)
	_over = _layer(false)
	# The world's own grade: the painting and the ground under the factory,
	# not the machines, the lights or the interface.
	material = _grade(GRADE_FAR)
	_ground.material = _grade(GRADE_GROUND)
	_floor.material = _grade(GRADE_GROUND)
	_ground.draw.connect(_draw_ground)
	_floor.draw.connect(_draw_floor)
	_floor_glow.draw.connect(_draw_floor_glow)
	_things.draw.connect(_draw_things)
	_glow.draw.connect(_draw_glow)
	_over.draw.connect(_draw_over)

	var L: Dictionary = IsoArt.layout()
	var w: Dictionary = L.get("world", {})
	_island_tex = IsoArt.texture(String(L.get("island", {}).get("file", "")))
	# The band's own painting and floor; the Workings' only if a band has
	# none. Held here, not in IsoArt's cache, so a band left behind is freed
	# rather than kept beside the new one.
	_set_world_band(int(Palette.band_at(Sim.depth)[0]), false)
	if _world_tex == null:
		_world_tex = IsoArt.texture(String(w.get("file", "")))
	if _tiles == null:
		_tiles = IsoArt.texture(String(L.get("tiles", {}).get("file", "")))
	var size_a: Array = w.get("size", [3840, 2160])
	cam.bg_size = Vector2(float(size_a[0]), float(size_a[1]))
	cam.anchor = Iso.anchor()
	cam.center = cam.anchor
	cam.parallax = float(IsoArt.placement().get("parallax", 0.82))
	cam.bg_parallax = float(IsoArt.placement().get("bg_parallax", 0.12))
	var slab := Rect2(Iso.slab_corners()[0], Vector2.ZERO)
	for p in Iso.slab_corners():
		slab = slab.expand(p)
	cam.near_bounds = slab.grow(Iso.TW)
	_band_tint = band_tint(Sim.depth)
	_band_target = _band_tint
	_refresh_sheet()

	Sim.stats_changed.connect(_on_stats)
	Sim.depth_changed.connect(func(d: int):
		_band_target = band_tint(d)
		_set_world_band(int(Palette.band_at(d)[0]), d > 0 and not calm_motion)
		if d > 0 and not calm_motion:
			_dive = 1.0
			_dive_seconds = dive_seconds(d)
		# A bigger yard: the new ground lights up, and the view glides out to
		# take it in.
		var grown: Vector2i = BuildArea.size_at(Sim.max_depth, Sim.collapses)
		if _yard != Vector2i.ZERO and grown != _yard:
			_open_wave(_yard)
			_yard = grown
			_glide_pending = true
		elif grown != _yard:
			frame_board())
	resized.connect(_on_resized)
	_on_stats()


## The colour of the world, measured against the reference concept with
## tools/visual_compare.py: its panels sit at saturation 0.55-0.58 and warmth
## 0.12-0.16, and the game's screens were at 0.39-0.46 and 0.04-0.07 -- a cool
## haze over everything (docs/AUDIT.md, "The world's colour"). A grade on
## the two layers that are world, in the shader they are drawn with anyway:
## no extra pass, no extra draw call.
##
## [saturation, warm tint]
const GRADE_FAR := [1.28, Color(1.07, 1.0, 0.90)]
const GRADE_GROUND := [1.30, Color(1.07, 1.01, 0.92)]
const GRADE_SHADER := """
shader_type canvas_item;
uniform float saturation = 1.0;
uniform vec3 warm = vec3(1.0);
void fragment() {
	// COLOR arrives already multiplied by the texture.
	vec4 c = COLOR;
	float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
	c.rgb = max(mix(vec3(l), c.rgb, saturation), vec3(0.0)) * warm;
	COLOR = c;
}
"""
static var _grade_shader: Shader


static func _grade(g: Array) -> ShaderMaterial:
	if _grade_shader == null:
		_grade_shader = Shader.new()
		_grade_shader.code = GRADE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _grade_shader
	m.set_shader_parameter("saturation", float(g[0]))
	var t: Color = g[1]
	m.set_shader_parameter("warm", Vector3(t.r, t.g, t.b))
	return m


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
	_yard = BuildArea.size_at(Sim.max_depth, Sim.collapses)
	var fr: Rect2 = free_rect if free_rect.size.x > 8.0 else Rect2(Vector2.ZERO, size)
	var scale: float = 1.0
	cam.fit(frame_rect(), fr, scale)
	# A first yard is small; fitted to a tablet it would fill the screen and
	# hide the world it stands in.
	if cam.zoom > YARD_ZOOM_MAX:
		scale = YARD_ZOOM_MAX / cam.zoom
		cam.fit(frame_rect(), fr, scale)
	if cam.zoom < DEFAULT_ZOOM_MIN:
		# A yard too big to see whole at a readable size: the Core and as much
		# of the yard round it as fits. The rest is a pan away.
		cam.fit(frame_rect(), fr, DEFAULT_ZOOM_MIN / cam.zoom)
		_framed = true
		return
	while scale > 0.6 and board_under_panel():
		scale *= 0.97
		cam.fit(frame_rect(), fr, scale)
	_framed = true


## Does any panel cover part of the yard -- the board, once the yard is the
## whole board -- as the camera frames it now? While the Core is dark its
## picture must be clear of panels too: it is the one thing to tap.
##
## Once it is online it is left out on purpose. Keeping it clear of the
## stratum card as well stepped the view back until the board was 14% of a
## 2:1 screen instead of 21.5%, and a four-strata yard came out at 27 dp
## tiles instead of 35 (docs/AUDIT.md, "The first minute").
func board_under_panel() -> bool:
	var polys: Array[PackedVector2Array] = []
	var corners := PackedVector2Array()
	for p in yard_corners():
		corners.append(cam.world_to_screen(p))
	polys.append(corners)
	if not Sim.core_online:
		var cr: Rect2 = core_rect()
		# The picture, less the clear margin its rectangle carries.
		cr = cr.grow_individual(-cr.size.x * 0.2, -cr.size.y * 0.02, -cr.size.x * 0.2, 0.0)
		var core := PackedVector2Array()
		for p in [cr.position, Vector2(cr.end.x, cr.position.y), cr.end,
				Vector2(cr.position.x, cr.end.y)]:
			core.append(cam.world_to_screen(p))
		polys.append(core)
	for r: Rect2 in avoid_rects:
		var box := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		for poly in polys:
			if not Geometry2D.intersect_polygons(poly, box).is_empty():
				return true
	return false


## What the first look has to contain: the Core and the yard -- the whole
## board once the yard is the whole board. While the yard is smaller the view
## closes in on the Core and the ground the player can build on, with a strip
## of the ground still to come on either side (BuildArea).
func frame_rect() -> Rect2:
	var y: PackedVector2Array = yard_corners()
	var r := Rect2(y[0], Vector2.ZERO)
	for p in y:
		r = r.expand(p)
	# A machine an older save left outside the yard is still the player's.
	for cell: int in Sim.grid.cells:
		if not Sim.is_open(cell):
			r = r.expand(Iso.cell_center(cell))
	r = r.grow_individual(Iso.TW * 0.6, machine_rise() + 6.0, Iso.TW * 0.6, 24.0)
	return r.merge(core_rect().grow(8.0))


## The yard's diamond, as world points: back, right, front, left.
func yard_corners() -> PackedVector2Array:
	var o: Vector2i = Iso.board_offset()
	var out := PackedVector2Array()
	for c: Vector2i in BuildArea.corners(Sim.max_depth, Sim.collapses):
		out.append(Iso.slab_top(c.x + o.x, c.y + o.y))
	return out


## The world rectangle the default view has to show: the board, plus exactly
## as much above its back corner as the tallest machine rises (measured from
## the sprite sheet, 58 units today) and the slab's front face below.
##
## It used to carry two cell-heights of margin above and the whole Factory
## Core standing behind the board, and the board came out at 12% of a 2:1
## screen with 25 dp cells. Framed tightly, with the Core moved beside the
## board's left corner so it no longer sets the height, the board is 22% of
## the screen and a cell is 34 dp (docs/AUDIT.md, "The default view").
static func board_frame_rect() -> Rect2:
	var r: Rect2 = Iso.board_rect()
	return r.grow_individual(Iso.TW * 0.2, machine_rise() + 6.0, Iso.TW * 0.2, 24.0)


## How far the tallest machine picture rises above its tile's top corner.
static func machine_rise() -> float:
	var sheet: Dictionary = IsoArt.sheet(Themes.DEFAULT)
	var s: float = Iso.TW * float(IsoArt.placement().get("footprint", 0.8)) \
		/ IsoArt.base_px(sheet)
	return maxf(IsoArt.anchor(sheet).y * s - Iso.TH * 0.5, 0.0)


## The zoom the default view settles on, for the touch-target report.
func default_zoom() -> float:
	var fr: Rect2 = free_rect if free_rect.size.x > 8.0 else Rect2(Vector2.ZERO, size)
	var r: Rect2 = frame_rect()
	return clampf(cam.clamp_zoom(minf(fr.size.x / r.size.x, fr.size.y / r.size.y)),
		DEFAULT_ZOOM_MIN, YARD_ZOOM_MAX)


## How long the plunge into stratum `depth` takes: 1.4 s near the surface,
## a little longer the deeper it goes, and 2.6 s into a new band -- the
## Workings, the Deep, the Abyss -- where the whole world changes colour.
## Never long enough to wait on: the board keeps running and takes taps.
static func dive_seconds(depth: int) -> float:
	if depth > 0 and int(Palette.band_at(depth)[0]) != int(Palette.band_at(depth - 1)[0]):
		return 2.6
	return lerpf(1.4, 2.0, clampf(float(depth) / 20.0, 0.0, 1.0))


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
	_sprite_geo = {}


## Called when a palette is chosen. Swapping the atlas is the whole cost.
func palette_changed() -> void:
	_refresh_sheet()


func _on_stats() -> void:
	if Sim.grid == null:
		return
	# The links only change with the board. Worked out on every tick, and
	# matched against every transfer by a scan of all of them, they cost a
	# 300-machine board 11 ms a tick (docs/AUDIT.md, "A late board").
	if Sim.grid.version != _links_version or Sim.grid != _links_grid:
		_links_version = Sim.grid.version
		_links_grid = Sim.grid
		_links = Iso.links(Sim.grid)
		_segments = Iso.segments(_links)
		_paths = {}
		for l: Dictionary in _links:
			(_paths.get_or_add(int(l["from"]) * PAIR + int(l["to"]), []) as Array).append(l["path"])
		_pipe_geo = []
		for key: String in _segments:
			_pipe_geo.append(_pipe_shape(key))
		_link_sides()
		# The ground draws the casings: draw it again with the new ones.
		_ground_sig = []
	_refresh_sheet()
	# Material the simulation actually moved this tick lights its pipes.
	if Sim.sim != null:
		for t: Array in Sim.sim.last_transfers:
			# A Rig made: it drives out of the machine that made it to the Bay.
			if int(t[1]) == Simulation.CORE_TAKER and int(t[2]) == MachineDB.Res.RIG and not calm_motion:
				_newborn.append({"cell": int(t[0]), "t0": _anim})
			for path: Array in _paths.get(int(t[0]) * PAIR + int(t[1]), []):
				for i in range(path.size() - 1):
					var a: int = int(path[i])
					var b: int = int(path[i + 1])
					var key: String = "%d-%d" % [mini(a, b), maxi(a, b)]
					_flow[key] = 0.6
					# Which way it went, so the bead rides the right way.
					if a > b:
						_flow_from_b[key] = true
					else:
						_flow_from_b.erase(key)
	# The badges' raw states change only when the simulation does: once a
	# tick here, not once a frame.
	_raw = _raw_states()
	badges.update(_raw, 0.0)


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


## The tile under screen point `p`: where a dragged machine is dropped.
func cell_at_screen(p: Vector2) -> int:
	return Iso.cell_at(cam.screen_to_world(p))


## What a finger on screen point `p` means: the machine drawn there, or the
## tile when none is, and the empty tile while a machine is armed
## (IsoArt.pick) -- or CORE, where the Factory Core is what is drawn.
func pick_at_screen(p: Vector2) -> int:
	var w: Vector2 = cam.screen_to_world(p)
	var placing: bool = arm_id != ""
	var cell: int = IsoArt.pick(w, Sim.grid, _sheet, _pick_image(), placing)
	if not _on_core(w):
		# The Core's own sixteen cells are its foundation, not ground: a tap
		# on one is a tap on the Core.
		if cell >= 0 and BuildArea.is_core(cell):
			return CORE
		return cell
	if cell < 0:
		return CORE
	if Sim.grid.is_empty(cell):
		return cell if placing else CORE
	# A machine and the Core both drawn here: the nearer one, in the order
	# _draw_things sorts them.
	var drawn: bool = IsoArt.machine_at(w, Sim.grid, _sheet, _pick_image()) == cell
	var p2: Vector2i = Grid.xy(cell)
	var o: Vector2i = Iso.board_offset()
	if drawn and float(p2.x + o.x + p2.y + o.y) > _core_depth():
		return cell
	# Behind the tower, but drawn through it (_draw_things): the machine the
	# player can see is the one they get.
	if drawn and cells_behind_core().has(cell):
		return cell
	return CORE


## The yard cells the Core's tower hides from the camera: at least half of
## a cell's diamond under the Core's opaque picture. They are ordinary yard
## cells -- open, buildable, the same rules as any other -- and the view
## makes them usable: while a machine is armed their outlines are drawn over
## the Core, the Core thins while a finger places or drags into one, and a
## machine standing in one is drawn through the Core and tapped through it.
## Cached per Core level, the only thing that changes the Core's size.
func cells_behind_core() -> Array[int]:
	var lvl: int = core_level()
	if lvl == _hidden_level:
		return _hidden
	_hidden_level = lvl
	_hidden = []
	var r: Rect2 = core_rect()
	if r.size.x <= 0.0:
		return _hidden
	for cell in range(Grid.W * Grid.H):
		if BuildArea.is_core(cell):
			continue
		var c: Vector2 = Iso.cell_center(cell)
		if not r.grow(Iso.TW).has_point(c):
			continue
		var n: int = 0
		var hit: int = 0
		for i in range(-4, 5):
			for j in range(-4, 5):
				if absi(i) + absi(j) > 4:
					continue
				n += 1
				if _on_core(c + Vector2(float(i) * Iso.TW * 0.11, float(j) * Iso.TH * 0.11)):
					hit += 1
		if hit * 2 >= n:
			_hidden.append(cell)
	return _hidden


## Whether the Core should be drawn thin: something the player is working
## on is behind it.
func _see_through_core() -> bool:
	if _dragging:
		return true
	if _pressed and arm_id != "" and _press_cell >= 0 and cells_behind_core().has(_press_cell):
		return true
	return selected_cell >= 0 and not Sim.grid.is_empty(selected_cell) \
		and cells_behind_core().has(selected_cell)


## Is the Core's picture opaque at world point `w`?
func _on_core(w: Vector2) -> bool:
	var r: Rect2 = core_rect()
	if not r.has_point(w):
		return false
	var info: Dictionary = core_info()
	if _core_mask == null or _core_mask_file != String(info.get("file", "")):
		_core_mask_file = String(info.get("file", ""))
		_core_mask = _alpha_mask(_core_mask_file)
		if _core_mask == null:
			return false
	var region: Rect2 = IsoArt.region(info, 0)
	var q: Vector2 = region.position + (w - r.position) / r.size * region.size
	return _core_mask.get_bitv(Vector2i(q))


## A sheet's opaque pixels, one bit each: all a tap test needs, at a
## thirty-second of the decompressed picture's memory.
static func _alpha_mask(file: String) -> BitMap:
	var tex: Texture2D = IsoArt.texture(file)
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	var m := BitMap.new()
	m.create_from_image_alpha(img, 0.5)
	return m


## The Core's place in the drawing order (see _draw_things).
func _core_depth() -> float:
	var cc: Array = IsoArt.placement().get("core_cell", [])
	if cc.size() != 2:
		return -INF
	var n: int = int(IsoArt.placement().get("core_size", 3))
	return float(int(cc[0]) + int(cc[1]) + n) - 0.75


## The moment the Core comes online: it flares.
func core_powered() -> void:
	_core_flash = 1.0


## The yard has grown past `was`: light the new ground, nearest the old yard
## first, so the growth reads as the factory's ground spreading outwards.
func _open_wave(was: Vector2i) -> void:
	_opened.clear()
	# The yard was `was` tiles square round the Core: its reach was half of
	# what the Core does not take up.
	var old_r: int = (was.x - BuildArea.CORE.size.x) / 2
	for i: int in BuildArea.cells(Sim.max_depth):
		var r: int = BuildArea.reach(i)
		if r > old_r:
			_opened[i] = -0.18 * float(r - old_r - 1)


## Glide, rather than cut, to the default view for the current yard.
func _glide_to_frame() -> void:
	var z0: float = cam.zoom
	var c0: Vector2 = cam.center
	frame_board()
	var z1: float = cam.zoom
	var c1: Vector2 = cam.center
	cam.zoom = z0
	cam.center = c0
	cam.focus(c1, z1)


## The machine atlas as an image, for testing a tap against what is drawn.
## Read once per sheet, and only when a finger first needs it.
func _pick_image() -> Image:
	if _atlas == null:
		return null
	if _pick_sheet != _sheet_name:
		_pick_sheet = _sheet_name
		_pick_img = _atlas.get_image()
		if _pick_img != null and _pick_img.is_compressed():
			_pick_img.decompress()
		if _pick_img != null:
			_pick_img.clear_mipmaps()
	return _pick_img


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
	for n: Node2D in [_ground, _floor, _floor_glow, _things, _glow]:
		n.transform = t
	_band_tint = _band_tint.lerp(_band_target, 1.0 - exp(-delta * 2.5))
	if _world_prev != null:
		_world_fade = maxf(_world_fade - delta / maxf(_dive_seconds, 0.5), 0.0)
		if _world_fade <= 0.0:
			_world_prev = null
	# Held while a card covers the world, like the yard's wave: the plunge
	# is for seeing.
	if not hold_effects:
		_dive = maxf(_dive - delta / _dive_seconds, 0.0)
	_core_flash = maxf(_core_flash - delta / 1.6, 0.0)
	if not hold_effects:
		_fm_step(delta)
	_core_alpha = move_toward(_core_alpha, 0.4 if _see_through_core() else 1.0, delta * 4.0)

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
	if not hold_effects:
		for k: int in _opened.keys():
			_opened[k] = float(_opened[k]) + delta
			if float(_opened[k]) > 1.6:
				_opened.erase(k)
		if _glide_pending:
			_glide_pending = false
			_glide_to_frame()
	for k: String in _flow.keys():
		_flow[k] = float(_flow[k]) - delta
		if float(_flow[k]) <= 0.0:
			_flow.erase(k)

	if Sim.grid != null and Sim.sim != null:
		badges.update(_raw, delta)

	# Published for the device self test: a cell's short axis on the physical
	# screen, now and at the closest zoom, so it can be turned into dp.
	var px_scale: float = get_tree().root.get_final_transform().get_scale().y
	SelfTest.last_cell_px = Iso.TH * cam.zoom * px_scale
	SelfTest.max_cell_px = Iso.TH * cam.zoom_max * px_scale

	queue_redraw()
	for n: Node2D in [_floor, _floor_glow, _things, _glow, _over]:
		n.queue_redraw()
	# The ground -- 1,936 tiles, the island, the rim -- is only redrawn when
	# something it shows has changed. Its layer moves with the camera like the
	# others, so panning and zooming never touch it.
	var sig: Array = [Sim.depth, Sim.max_depth, overlay, Sim.grid.version,
		_band_tint.to_html(false)]
	if sig != _ground_sig:
		_ground_sig = sig
		_ground.queue_redraw()


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
	_press_cell = -1 if pan_only else pick_at_screen(pos)
	# A node is for looking at, not building on: only when nothing is armed.
	_press_node = node_at_screen(pos) if not pan_only and arm_id == "" else -1


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
	var cell: int = pick_at_screen(pos)
	# A gallery mouth, past the yard's edge.
	var tap_w: Vector2 = cam.screen_to_world(pos)
	# The Rig Bay, past the yard's edge: its screen.
	if (cell < 0 or Sim.grid.is_empty(cell)) and cell != CORE \
			and (bay_pos() - Vector2(0, Iso.TH * 0.5)).distance_to(tap_w) < Iso.TW * 0.8:
		bay_tapped.emit()
		return
	var mouth: int = site_at(tap_w)
	if mouth >= 0 and (cell < 0 or Sim.grid.is_empty(cell)) and cell != CORE:
		site_tapped.emit(mouth)
		return
	# A resource node, unless a machine or the Core is what is drawn there.
	var machine_here: bool = cell >= 0 and not Sim.grid.is_empty(cell)
	if _press_node >= 0 and not machine_here and cell != CORE \
			and node_at_screen(pos) == _press_node:
		node_tapped.emit(_press_node)
		return
	if cell >= 0 and cell == from_cell:
		cell_tapped.emit(cell)
	elif cell == CORE and from_cell == CORE:
		core_tapped.emit()
	elif cell == -1:
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

## The painting of band `band`; with `fade`, the one before fades out over
## the dive into it.
func _set_world_band(band: int, fade: bool) -> void:
	if band == _world_band:
		return
	var files: Array = IsoArt.layout().get("worlds", [])
	if band < 0 or band >= files.size() or not ResourceLoader.exists(String(files[band])):
		return
	_world_prev = _world_tex if fade and _world_band >= 0 else null
	_world_fade = 1.0 if _world_prev != null else 0.0
	_world_band = band
	_world_tex = load(String(files[band]))
	# And its floor: grass and earth at the Surface, flagstone in the
	# Workings, basalt in the Deep, violet stone in the Abyss.
	var lands: Array = IsoArt.layout().get("terrain_bands", [])
	if band < lands.size() and ResourceLoader.exists(String(lands[band])):
		_terrain = load(String(lands[band]))
	var floors: Array = IsoArt.layout().get("tiles_bands", [])
	if band < floors.size() and ResourceLoader.exists(String(floors[band])):
		_tiles = load(String(floors[band]))
		_ground_sig = []


func _draw() -> void:
	if _world_tex == null:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.BG, true)
		return
	# Descending: the far wall rushes up past the island and the light dips,
	# for as long as the new stratum's colour takes to arrive. The painting is
	# scaled up a little while it moves so no edge of it is ever on screen.
	var d: float = sin(_dive * PI)
	var bt: Transform2D = cam.bg_transform()
	if d > 0.001:
		var k: float = 1.0 + 0.10 * d
		bt = Transform2D(0.0, bt.get_scale() * k, 0.0,
			(bt.origin - size * 0.5) * k + size * 0.5 + Vector2(0, -size.y * 0.04 * d))
	draw_set_transform_matrix(bt)
	# Each band's painting carries its own light: the band's tint only
	# settles it with the board.
	var world_tint: Color = Color.WHITE.lerp(_band_tint, 0.3)
	draw_texture(_world_tex, Vector2.ZERO, world_tint)
	if _world_prev != null and _world_fade > 0.0:
		draw_texture(_world_prev, Vector2.ZERO, Color(world_tint, _world_fade))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# A little haze over the far world so the island reads as nearer.
	var haze: Color = Color(0.10, 0.12, 0.20, 0.18 + 0.35 * d)
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


## The ground: the island, the slab's faces, every tile, the rim, rubble.
## Redrawn only when it changes (see _process).
func _draw_ground() -> void:
	var ci: CanvasItem = _ground
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
	var tris := Tris.new()
	_draw_rim(ci, bc, tris)
	for cell: int in Strata.blocked_cells(Sim.depth):
		_rubble(tris, cell)
	tris.flush(ci)

	# Contact shadows: a machine that casts nothing floats. With the ground,
	# because they move only when the machines do.
	var g: Texture2D = IsoArt.glow()
	for cell: int in Sim.grid.cells:
		var c: Vector2 = Iso.cell_center(cell) + Vector2(4.0, 6.0)
		ci.draw_texture_rect(g, Rect2(c - Vector2(Iso.TW * 0.46, Iso.TH * 0.46),
			Vector2(Iso.TW * 0.92, Iso.TH * 0.92)), false, Color(0, 0, 0, 0.55))
	# The pipes' casings, shadows and brass collars.
	var casings := Tris.new()
	for geo: Array in _pipe_geo:
		_pipe_casing(casings, geo)
	casings.flush(ci)


func _draw_floor() -> void:
	var ci: CanvasItem = _floor
	_draw_yard_edge(ci)
	_draw_core_footprint(ci)
	_draw_floor_marks(ci)

	# The pipes lie on the floor, in the seams between plates, all in one
	# batch. Drawn under every machine rather than interleaved with them: a
	# pipe between two machines is behind the nearer one either way, and
	# keeping them out of the machine pass lets all the machines -- one atlas
	# -- draw as one batch instead of breaking at every pipe. Only the body,
	# which lights up with what moves, is drawn here; the rest is the ground's.
	var pipes := Tris.new()
	for geo: Array in _pipe_geo:
		_pipe_body(pipes, geo)
	pipes.flush(ci)


## Untextured triangles collected and drawn in one call. Lines, circles and
## polygons are each a draw call in the compatibility renderer; seventy
## rivets and forty pipes were a third of the frame's draw calls.
class Tris:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()

	# Appended one value at a time: an array literal per call is an
	# allocation per quad, and a late board draws thousands a frame.
	func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
		var i: int = pts.size()
		pts.push_back(a)
		pts.push_back(b)
		pts.push_back(c)
		pts.push_back(d)
		for _k in range(4):
			cols.push_back(col)
		idx.push_back(i)
		idx.push_back(i + 1)
		idx.push_back(i + 2)
		idx.push_back(i)
		idx.push_back(i + 2)
		idx.push_back(i + 3)

	## A straight band `w` wide from p0 to p1.
	func band(p0: Vector2, p1: Vector2, w: float, col: Color) -> void:
		var d: Vector2 = (p1 - p0).normalized()
		var n := Vector2(-d.y, d.x) * (w * 0.5)
		quad(p0 + n, p1 + n, p1 - n, p0 - n, col)

	func dot(c: Vector2, r: float, col: Color) -> void:
		quad(c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0), col)

	func tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		var i: int = pts.size()
		pts.push_back(a)
		pts.push_back(b)
		pts.push_back(c)
		cols.push_back(col)
		cols.push_back(col)
		cols.push_back(col)
		idx.push_back(i)
		idx.push_back(i + 1)
		idx.push_back(i + 2)

	## The unit circle in n steps, worked out once per n: a badge is three
	## circles, and a late board has a hundred badges.
	static var _units: Dictionary = {}

	static func _unit(n: int) -> PackedVector2Array:
		var u: Variant = _units.get(n)
		if u == null:
			var a := PackedVector2Array()
			for k in range(n + 1):
				a.append(Vector2.from_angle(TAU * float(k) / float(n)))
			_units[n] = a
			u = a
		return u

	func circle(c: Vector2, r: float, col: Color, n: int = 16) -> void:
		var i: int = pts.size()
		var u: PackedVector2Array = _unit(n)
		pts.append(c)
		cols.append(col)
		for k in range(n):
			pts.append(c + u[k] * r)
			cols.append(col)
		for k in range(n):
			idx.push_back(i)
			idx.push_back(i + 1 + k)
			idx.push_back(i + 1 + (k + 1) % n)

	func ring(c: Vector2, r: float, w: float, col: Color, n: int = 18) -> void:
		var u: PackedVector2Array = _unit(n)
		for k in range(n):
			quad(c + u[k] * (r - w * 0.5), c + u[k + 1] * (r - w * 0.5), c + u[k + 1] * (r + w * 0.5),
				c + u[k] * (r + w * 0.5), col)

	func flush(ci: CanvasItem) -> void:
		if idx.is_empty():
			return
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, cols)


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
	# The plot's outline, dashed: ground that is marked out and not yet built.
	var c := PackedVector2Array([Iso.slab_top(int(a[0]), int(a[1])),
		Iso.slab_top(int(b[0]) + 1, int(a[1])), Iso.slab_top(int(b[0]) + 1, int(b[1]) + 1),
		Iso.slab_top(int(a[0]), int(b[1]) + 1)])
	ci.draw_colored_polygon(c, dim)
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
	var paved: Dictionary = _paved()
	_draw_terrain(ci, blocked, paved)
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
		if BuildArea.is_core(cell):
			# The Core's own foundation: steel under its plate, never ground
			# the yard has yet to reach.
			c = Color(0.52, 0.53, 0.60) * (0.92 + 0.08 * k)
			c.a = 1.0
		elif _terrain != null and not blocked.has(cell) and not paved.has(cell):
			# Land: the yard's own that nothing stands on yet, and the land
			# it has not reached -- drawn below, as land.
			continue
		elif not Sim.is_open(cell):
			# Ground the yard has not reached yet: marked out, not laid. The
			# slabs are drawn faint and grey over the island's own rock, so
			# the future ground reads as ground rather than as a dark hole.
			var l: float = (c.r + c.g + c.b) / 3.0 * 0.70
			c = Color(l, l, l * 1.06, 0.45)
		var shade: float = 1.0 - 0.05 * float(pxy.x + pxy.y) / float(Grid.W + Grid.H)
		c = Color(c.r * shade, c.g * shade, c.b * shade, c.a)
		var i0: int = pts.size()
		for j in range(4):
			pts.append(p[(j + 3) % 4])
			uvs.append(tuv[j])
			cols.append(c)
		idx.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts,
		cols, uvs, PackedInt32Array(), PackedFloat32Array(), _tiles.get_rid())


## The yard's paved ground: the Core's foundation and every tile a
## machine stands on, with an apron of one tile round them. The rest of the
## yard stays land until something is built on it, as a base in the
## reference games is grass until a building goes down -- except under the
## heat overlay, which paints every tile the yard owns.
func _paved() -> Dictionary:
	var out: Dictionary = {}
	for cell in range(Grid.W * Grid.H):
		if not Sim.is_open(cell) or overlay == Overlay.HEAT:
			if Sim.is_open(cell):
				out[cell] = true
			continue
		if not (BuildArea.is_core(cell) or Sim.grid.cells.has(cell)):
			continue
		var xy: Vector2i = Grid.xy(cell)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var q := Vector2i(xy.x + dx, xy.y + dy)
				if q.x < 0 or q.y < 0 or q.x >= Grid.W or q.y >= Grid.H:
					continue
				var n: int = Grid.idx(q.x, q.y)
				if Sim.is_open(n):
					out[n] = true
	return out


## The land: every cell neither paved nor the Core's, one seamless picture
## across them all (the texture repeats, so its UVs run past 1), darker
## towards the board's far corner and beyond the yard. The yard's own land
## is marked out by a faint line along each tile's back edges, so where a
## machine can go still reads at a glance.
func _draw_terrain(ci: CanvasItem, blocked: Dictionary, paved: Dictionary) -> void:
	if _terrain == null:
		return
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var marks := Tris.new()
	var mark := Color(1.0, 1.0, 1.0, 0.09)
	var base: Color = Color.WHITE.lerp(_band_tint, 0.3)
	for cell in range(Grid.W * Grid.H):
		if paved.has(cell) or BuildArea.is_core(cell) or blocked.has(cell):
			continue
		var xy: Vector2i = Grid.xy(cell)
		var p: PackedVector2Array = Iso.cell_points(cell)
		var u0 := Vector2(float(xy.x), float(xy.y)) / TERRAIN_CELLS
		var u1 := Vector2(float(xy.x + 1), float(xy.y + 1)) / TERRAIN_CELLS
		var tuv := PackedVector2Array([Vector2(u0.x, u0.y), Vector2(u1.x, u0.y),
			Vector2(u1.x, u1.y), Vector2(u0.x, u1.y)])
		var shade: float = 1.0 - 0.08 * float(xy.x + xy.y) / float(Grid.W + Grid.H)
		var open: bool = Sim.is_open(cell)
		if not open:
			shade *= 0.86
		var c := Color(base.r * shade, base.g * shade, base.b * shade, 1.0)
		var i0: int = pts.size()
		for j in range(4):
			pts.append(p[(j + 3) % 4])
			uvs.append(tuv[j])
			cols.append(c)
		idx.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3])
		if open:
			marks.band(p[0], p[1], 1.4, mark)
			marks.band(p[3], p[0], 1.4, mark)
	if pts.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts,
		cols, uvs, PackedInt32Array(), PackedFloat32Array(), _terrain.get_rid())
	marks.flush(ci)


## The iron frame around the board: the edge of what the factory owns.
func _draw_rim(ci: CanvasItem, bc: PackedVector2Array, tris: Tris) -> void:
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
			tris.dot(a.lerp(b, float(i) / float(cells)), 3.0, brass)


## The yard's edge, where it stops short of the rim: a lit line, so the
## ground the player can build on reads at a glance. Nothing to draw once the
## yard is the whole board -- the rim is its edge then.
func _draw_yard_edge(ci: CanvasItem) -> void:
	if BuildArea.is_whole_board(Sim.max_depth, Sim.collapses):
		return
	var y: PackedVector2Array = yard_corners()
	# The two inner edges: back-right (back to right corner) and right-front.
	var inner := PackedVector2Array([y[0], y[1], y[2]])
	ci.draw_polyline(inner, Color(0.05, 0.06, 0.09, 0.8), 8.0, true)
	var lit: Color = Palette.ACCENT
	lit.a = 0.75 + 0.15 * sin(_anim * 2.0)
	ci.draw_polyline(inner, lit, 3.5, true)


## The Core's footprint: a brass edge round its sixteen cells, so what the
## Core occupies reads apart from the yard round it.
func _draw_core_footprint(ci: CanvasItem) -> void:
	var c: Rect2i = BuildArea.CORE
	var o: Vector2i = Iso.board_offset()
	var pts := PackedVector2Array([
		Iso.slab_top(c.position.x + o.x, c.position.y + o.y),
		Iso.slab_top(c.end.x + o.x, c.position.y + o.y),
		Iso.slab_top(c.end.x + o.x, c.end.y + o.y),
		Iso.slab_top(c.position.x + o.x, c.end.y + o.y),
		Iso.slab_top(c.position.x + o.x, c.position.y + o.y)])
	ci.draw_polyline(pts, Color(0.05, 0.05, 0.08, 0.7), 7.0, true)
	ci.draw_polyline(pts, Color(0.86, 0.66, 0.30, 0.9), 3.0, true)


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
		# Where it would be fed and could hand its work on, the tile is
		# filled green: put it here and it works.
		var linked: Dictionary = _linked_cells()
		var good: Color = Palette.GOOD
		good.a = 0.20 + 0.16 * pulse
		for cell: int in BuildArea.cells(Sim.max_depth):
			if not Sim.grid.is_empty(cell) or Sim.is_blocked(cell):
				continue
			if not (Sim.grid.cells.is_empty() or _touches_machine(cell)):
				continue
			if linked.has(cell):
				ci.draw_colored_polygon(_diamond(cell, 0.62).slice(0, 4), good)
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
		if target >= 0 and Sim.grid.is_empty(target) and not Sim.is_blocked(target) \
				and Sim.is_open(target):
			ci.draw_colored_polygon(_diamond(target, 0.94).slice(0, 4),
				Color(Palette.GOOD, 0.35))
	if _pressed and not _panning and not _dragging and _press_cell >= 0:
		ci.draw_polyline(_diamond(_press_cell, 1.0), Palette.ACCENT, 2.5, true)


## The yard's empty tiles where the armed machine would be fed and could
## hand what it makes on (Simulation.links_if_placed), as a set. Worked out
## again only when the machine, the board or the yard changes. A support
## machine has its own mark ("serves N", the placement preview).
func _linked_cells() -> Dictionary:
	var sig: Array = [arm_id, Sim.grid.version, Sim.max_depth]
	if sig == _linked_sig:
		return _linked
	_linked_sig = sig
	_linked = {}
	var m: Dictionary = MachineDB.get_machine(arm_id)
	if m.is_empty():
		return _linked
	var tags: Array = m.get("tags", [])
	if (m["inputs"] as Dictionary).is_empty() and (m["outputs"] as Dictionary).is_empty() \
			and not tags.has("sink") and not tags.has("research"):
		return _linked
	for cell: int in BuildArea.cells(Sim.max_depth):
		if not Sim.grid.is_empty(cell) or Sim.is_blocked(cell) or not _touches_machine(cell):
			continue
		var l: Dictionary = Sim.sim.links_if_placed(cell, arm_id)
		if bool(l["fed"]) and bool(l["delivers"]):
			_linked[cell] = true
	return _linked


func _touches_machine(cell: int) -> bool:
	for n in Sim.grid.neighbours(cell):
		if not Sim.grid.is_empty(n):
			return true
	return false


## --- light on the floor ------------------------------------------------------

func _draw_floor_glow() -> void:
	var ci: CanvasItem = _floor_glow
	var g: Texture2D = IsoArt.glow()
	# Newly opened ground: each tile flares as the wave reaches it and fades.
	for cell: int in _opened:
		var t: float = float(_opened[cell])
		if t < 0.0:
			continue
		var col: Color = Palette.ACCENT
		col.a = 0.55 * (1.0 - t / 1.6)
		ci.draw_colored_polygon(_diamond(cell, 0.92).slice(0, 4), col)
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
			k *= 1.3 + (0.0 if calm_motion else 0.3 * sin(_anim * 5.0))
		col.a = 0.20 * k
		var c: Vector2 = Iso.cell_center(cell)
		ci.draw_texture_rect(g, Rect2(c - Vector2(Iso.TW, Iso.TH) * 0.95,
			Vector2(Iso.TW, Iso.TH) * 1.9), false, col)
	_draw_core_conduits(ci)
	# The ring round a dark Core's base: the one thing to tap.
	if highlight_core:
		var n: float = float(IsoArt.placement().get("core_size", 3))
		var beat: float = 0.5 + 0.5 * sin(_anim * 4.0)
		ci.draw_set_transform(core_center(), 0.0, Vector2(1.0, 0.5))
		ci.draw_arc(Vector2.ZERO, n * Iso.TW * 0.40 + 10.0 * beat, 0.0, TAU, 56,
			Color(0.45, 0.9, 1.0, 0.45 + 0.35 * beat), 7.0)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
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
	if _fp < 0.0:
		_fp = float(IsoArt.placement().get("footprint", 0.80))
	return _fp

var _fp: float = -1.0


func _draw_things() -> void:
	var ci: CanvasItem = _things
	# Everything that stands on the slab -- machines, the Core, props --
	# drawn by slab depth, so a lamp on the front rim covers the machine
	# behind it and the Core's tower is covered by the machines in front of
	# it. The machines' order changes only with the board and the props'
	# only with the depth, so both are sorted then, and each frame merges
	# them: sorting all of it every frame was a third of this pass on a
	# 300-machine board (docs/AUDIT.md, "A late board").
	_sort_things()
	var props: Array = _props_by_depth
	var core_key: float = _core_key
	var core_done: bool = core_key == INF
	var j: int = 0
	# Only the props on screen: each one out of sight would still be drawn,
	# and would split the machines' batch where it sorts between them.
	var seen: Rect2 = cam.visible_world().grow(Iso.TW)
	for i in range(_order.size() + 1):
		var key: float = _order_keys[i] if i < _order.size() else INF
		while j < props.size() and float(props[j][3]) - 0.25 < key:
			var f: Array = props[j]
			j += 1
			if not core_done and core_key <= float(f[3]) - 0.25:
				core_done = true
				_draw_core(ci)
			if not f[2] and seen.intersects(f[1]):
				_draw_prop(ci, f)
		if not core_done and core_key <= key:
			core_done = true
			_draw_core(ci)
		if i < _order.size():
			var cell: int = _order[i]
			var id: String = Sim.grid.machine_at(cell)
			if id != "" and not (_dragging and cell == selected_cell):
				_draw_machine(ci, cell, id)
	# Machines the Core's tower hides, drawn again faintly over it: what
	# stands behind the Core can be seen, and tapped (pick_at_screen).
	for cell: int in cells_behind_core():
		var hid: String = Sim.grid.machine_at(cell)
		if hid != "" and not (_dragging and cell == selected_cell):
			# A cool, see-through tint: it reads as "behind", not as a
			# smudge on the Core.
			_draw_sprite(ci, hid, Iso.cell_center(cell), Color(0.6, 0.88, 1.0, 0.5), 1.0)
	_draw_galleries(ci)
	if _dragging and selected_cell >= 0 and not Sim.grid.is_empty(selected_cell):
		var w: Vector2 = cam.screen_to_world(_drag_pos)
		_draw_sprite(ci, Sim.grid.machine_at(selected_cell), w + Vector2(0, Iso.TH * 0.2),
			Color(1, 1, 1, 0.8), 1.0)


## The machines in drawing order (slab depth), with their keys; the props
## in the same order; the Core's key (INF when there is none). The first
## two follow the board and the depth.
var _order: Array[int] = []
var _order_keys: PackedFloat32Array = PackedFloat32Array()
var _order_sig: Array = []
var _props_by_depth: Array = []
var _core_key: float = INF
var _sprite_geo: Dictionary = {}

func _sort_things() -> void:
	var sig: Array = [Sim.grid, Sim.grid.version, Sim.max_depth]
	if sig == _order_sig:
		return
	_order_sig = sig
	var o: Vector2i = Iso.board_offset()
	var keyed: Array = []
	for cell: int in Sim.grid.cells:
		var p: Vector2i = Grid.xy(cell)
		keyed.append(Vector2(float(p.x + o.x + p.y + o.y), float(cell)))
	keyed.sort()
	_order = []
	_order_keys = PackedFloat32Array()
	for k: Vector2 in keyed:
		_order.append(int(k.y))
		_order_keys.append(k.x)
	_props_by_depth = _props_now().duplicate()
	_props_by_depth.sort_custom(func(x: Array, y: Array) -> bool: return float(x[3]) < float(y[3]))
	_core_key = INF
	var cc: Array = IsoArt.placement().get("core_cell", [])
	if cc.size() == 2:
		var n: int = int(IsoArt.placement().get("core_size", 3))
		_core_key = float(int(cc[0]) + int(cc[1]) + n) - 0.75


## The Factory Core: three cells of the slab, behind the board, never on it.
## It is the landmark the eye finds first and it takes no tile from play.
func core_center() -> Vector2:
	var cc: Array = IsoArt.placement().get("core_cell", [1, 1])
	var n: float = float(IsoArt.placement().get("core_size", 3))
	return Iso.slab_top(float(cc[0]) + n * 0.5, float(cc[1]) + n * 0.5)


## The Core grows with its shaft: one level for each ring of yard round it,
## 1 as a shaft opens and 8 at stratum 16. The level is only what the Core
## looks like -- its size up to level 5, then its light: a column of light
## from its crystal from 6, growing each level, a second orbit from 7, a
## crystal that never goes dark at 8 -- and it reads the depth the shaft has
## already reached, so it asks nothing new of the player.
const CORE_LEVELS := 8
## The level at which the Core reaches its full size; above it, it grows in
## light and energy rather than in size, so it never covers its ring.
const CORE_FULL_SIZE_LEVEL := 5


## The Core's picture follows the level the player has grown it to
## (CoreLevels, docs/PROGRESSION.md), up to its last stage.
static func core_level() -> int:
	return clampi(int(Sim.core_level), 1, CORE_LEVELS)


## The Core's picture for its level: four stages -- a young furnace-drum
## (Cores 1-3), the tower (4-6), the tower with rings and pylons (7-9), the
## citadel (10 and up) -- so a player sees from across the board how far the
## factory has come. Within a stage it still grows a little a level.
const CORE_STAGES := ["core_t1", "core", "core_t3", "core_t4"]


func core_info() -> Dictionary:
	var lvl: int = core_level()
	var stage: int = 0 if lvl <= 3 else (1 if lvl <= 6 else (2 if lvl <= 9 else 3))
	var info: Dictionary = IsoArt.layout().get(CORE_STAGES[stage], {})
	return info if not info.is_empty() else IsoArt.layout().get("core", {})


func core_rect() -> Rect2:
	var info: Dictionary = core_info()
	if info.is_empty():
		return Rect2(core_center(), Vector2.ZERO)
	var n: float = float(IsoArt.placement().get("core_size", 3))
	# A level-1 Core is 84% of the full one; each level adds 4%, up to full.
	var grow: float = 0.84 + 0.04 * float(mini(core_level(), CORE_FULL_SIZE_LEVEL) - 1)
	var s: float = n * Iso.TW * 0.86 / IsoArt.base_px(info) * grow
	var cell: Array = info["cell"]
	var a: Vector2 = IsoArt.anchor(info)
	return Rect2(core_center() - a * s, Vector2(float(cell[0]), float(cell[1])) * s)


func _draw_core(ci: CanvasItem) -> void:
	var info: Dictionary = core_info()
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
	if not Sim.core_online:
		# Dark and cold: built, not yet running.
		mod = Color(0.42, 0.45, 0.55)
	mod = mod.lerp(Color(1.5, 1.5, 1.5), _core_flash * 0.6)
	mod.a = _core_alpha
	ci.draw_texture_rect_region(tex, r, IsoArt.region(info, 0), mod)


## Is prop `pr` standing on ground the yard has reached? The yard clears it.
func _prop_cleared(pr: Array) -> bool:
	var o: Vector2i = Iso.board_offset()
	var x: int = int(pr[0]) - o.x
	var y: int = int(pr[1]) - o.y
	return Grid.in_bounds(x, y) and Sim.is_open(Grid.idx(x, y))


## `f` is one of _props_now()'s entries.
func _draw_prop(ci: CanvasItem, f: Array) -> void:
	var tex: Texture2D = IsoArt.texture(String(IsoArt.layout().get("props", {}).get("file", "")))
	if tex == null or f[4] == Rect2():
		return
	ci.draw_texture_rect_region(tex, f[1], f[4], Color.WHITE.lerp(_band_tint, 0.3))


## Each prop's fixed facts, worked out once: [the layout's entry, where it
## is drawn, whether the yard has cleared it, its depth in the drawing
## order, its picture on the sheet, the point it stands on]. The props never move while the game
## runs, and only a growing yard clears one, so this is redone only then.
## Worked out afresh every frame, a hundred props cost a millisecond.
func _props_now() -> Array:
	if _prop_facts_depth == Sim.max_depth and not _prop_facts.is_empty():
		return _prop_facts
	_prop_facts_depth = Sim.max_depth
	_prop_facts = []
	var info: Dictionary = IsoArt.layout().get("props", {})
	var order: Array = info.get("order", [])
	for pr: Array in IsoArt.placement().get("props", []):
		var k: int = order.find(String(pr[2]))
		_prop_facts.append([pr, prop_rect(pr), _prop_cleared(pr),
			float(int(pr[0]) + int(pr[1])), IsoArt.region(info, k) if k >= 0 else Rect2(),
			Iso.slab_top(float(pr[0]) + 0.5, float(pr[1]) + 0.5)])
	return _prop_facts


## A prop's size: the layout's fourth number, or 1. Resource fields far out
## are drawn a little larger than the starters by the yard.
static func prop_scale(pr: Array) -> float:
	return clampf(float(pr[3]), 0.5, 1.5) if pr.size() > 3 else 1.0


## Where a prop's picture is drawn, in world units: standing on its cell.
func prop_rect(pr: Array) -> Rect2:
	var info: Dictionary = IsoArt.layout().get("props", {})
	var at: Vector2 = Iso.slab_top(float(pr[0]) + 0.5, float(pr[1]) + 0.5)
	var s: float = Iso.TW * 0.78 / IsoArt.base_px(info) * prop_scale(pr)
	var cell: Array = info.get("cell", [1, 1])
	return Rect2(at - IsoArt.anchor(info) * s, Vector2(float(cell[0]), float(cell[1])) * s)


## The resource node drawn at world point `w`, nearest the camera first, or
## -1. Clutter (rubble, crates, lamps) is never a node, and a node the yard
## has cleared is gone.
func node_at(w: Vector2) -> int:
	var props: Array = IsoArt.placement().get("props", [])
	var info: Dictionary = IsoArt.layout().get("props", {})
	var order: Array = (info.get("order", []) as Array)
	var best: int = -1
	var best_depth: float = -INF
	for i in range(props.size()):
		var pr: Array = props[i]
		if not ResourceNodes.is_node(String(pr[2])) or _prop_cleared(pr):
			continue
		var r: Rect2 = prop_rect(pr)
		if not r.has_point(w):
			continue
		var depth: float = float(int(pr[0]) + int(pr[1]))
		if depth <= best_depth:
			continue
		if _props_mask == null:
			_props_mask = _alpha_mask(String(info.get("file", "")))
		if _props_mask != null:
			var region: Rect2 = IsoArt.region(info, order.find(String(pr[2])))
			var q: Vector2 = region.position + (w - r.position) / r.size * region.size
			if not _props_mask.get_bitv(Vector2i(q)):
				continue
		best = i
		best_depth = depth
	return best


func node_at_screen(p: Vector2) -> int:
	return node_at(cam.screen_to_world(p))



func _rubble(tris: Tris, cell: int) -> void:
	var c: Vector2 = Iso.cell_center(cell)
	for k in range(3):
		var o := Vector2(-18.0 + 18.0 * k, -2.0 + 5.0 * (k % 2))
		tris.dot(c + o, 10.0 - k, Color(0.24, 0.22, 0.25))
		tris.dot(c + o - Vector2(2, 3), 6.0 - k, Color(0.40, 0.37, 0.40))


func _draw_sprite(ci: CanvasItem, id: String, at: Vector2, mod: Color, squash: float) -> void:
	if _atlas == null:
		ci.draw_circle(at, Iso.TH * 0.35, Palette.machine_color(id))
		return
	# Where the machine is on the sheet and how it scales: read from the
	# sheet's dictionaries once per sheet, not for every machine every frame.
	var geo: Variant = _sprite_geo.get(id)
	if geo == null:
		geo = [IsoArt.machine_region(_sheet, id), Iso.TW * _footprint() / IsoArt.base_px(_sheet),
			IsoArt.anchor(_sheet)]
		_sprite_geo[id] = geo
	var region: Rect2 = geo[0]
	var s: float = geo[1]
	var a: Vector2 = geo[2]
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
		var m: Dictionary = Sim.sim.machine_of(cell)
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
	var jolt := Vector2.ZERO
	if running:
		squash = 1.0 + 0.012 * sin(Sim.sim.progress_of(cell) * TAU)
		match id:
			"drill":
				# The bit is biting: a fine, fast shudder.
				jolt = Vector2(sin(_anim * 41.0 + float(cell)),
					cos(_anim * 37.0 + float(cell) * 2.0)) * 0.9
			"crusher", "press":
				# The stamp at the end of every cycle, in time with production.
				squash *= 1.0 - 0.035 * sin(_stamp(cell) * PI)
	_draw_sprite(ci, id, Iso.cell_center(cell) + jolt, mod, squash)



## A pipe's fixed shape: plate edge to plate edge, and a little under each
## plate, so the ends are tucked in rather than floating; raised a little off
## the floor so it reads as a pipe lying across the seam.
func _pipe_shape(key: String) -> Array:
	var s: Dictionary = _segments[key]
	var a: Vector2 = Iso.cell_center(int(s["a"]))
	var b: Vector2 = Iso.cell_center(int(s["b"]))
	var dir: Vector2 = (b - a).normalized()
	var reach: float = a.distance_to(b) * (0.5 - _footprint() * 0.5) + 16.0
	var mid: Vector2 = (a + b) * 0.5 - Vector2(0, 9.0)
	return [key, int(s["a"]), int(s["b"]), mid - dir * reach, mid + dir * reach,
		Vector2(-dir.y, dir.x), Palette.res_color(int(s["res"]))]


func _pipe_casing(t: Tris, geo: Array) -> void:
	var p0: Vector2 = geo[3]
	var p1: Vector2 = geo[4]
	var n: Vector2 = geo[5]
	t.band(p0 + Vector2(0, 5), p1 + Vector2(0, 5), 14.0, Color(0, 0, 0, 0.35))
	t.band(p0, p1, 14.0, Color(0.16, 0.15, 0.18))
	var brass := Color(0.80, 0.62, 0.30)
	t.band(p0 - n * 8.5, p0 + n * 8.5, 4.5, brass)
	t.band(p1 - n * 8.5, p1 + n * 8.5, 4.5, brass)


## The body: bright while material moves along it, and pulsing amber or red
## while a machine at either end is badged backed up or starved.
func _pipe_body(t: Tris, geo: Array) -> void:
	var p0: Vector2 = geo[3]
	var p1: Vector2 = geo[4]
	var live: bool = _flow.has(String(geo[0]))
	var warn: Color = Color(0, 0, 0, 0)
	for cell: int in [int(geo[1]), int(geo[2])]:
		var sh: int = badges.shown(cell)
		if sh == StatusBadges.Show.BLOCKED:
			warn = Palette.ST_BLOCKED
		elif sh == StatusBadges.Show.STARVED and warn.a == 0.0:
			warn = Palette.ST_STARVED
	var body: Color = (geo[6] as Color).lerp(Color(0.25, 0.25, 0.3), 0.15 if live else 0.55)
	if warn.a > 0.0:
		body = body.lerp(warn, 0.35 + 0.25 * sin(_anim * 5.0))
	t.band(p0, p1, 9.5, body)
	t.band(p0 - Vector2(0, 2.5), p1 - Vector2(0, 2.5), 2.5, body.lightened(0.5))


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
	var seams := Tris.new()
	for key: String in _flow:
		if not _segments.has(key):
			continue
		var s: Dictionary = _segments[key]
		var a: Vector2 = Iso.cell_center(int(s["a"]))
		var b: Vector2 = Iso.cell_center(int(s["b"]))
		var t: float = fposmod(_anim * 1.6 + float(int(s["a"]) % 7) * 0.13, 1.0)
		# Which way it went, as the tick recorded it (segments run low cell to
		# high). Looked up rather than found by scanning every link, which on a
		# 300-machine board was most of this layer's frame.
		var from_a: bool = not _flow_from_b.has(key)
		var p: Vector2 = (a.lerp(b, t) if from_a else b.lerp(a, t)) - Vector2(0, 12)
		var live: float = clampf(float(_flow[key]) * 2.0, 0.0, 1.0)
		var col2: Color = Palette.res_color(int(s["res"])).lerp(Color.WHITE, 0.55)
		# The seam itself lights up while material crosses it. Light, not
		# pipe: it passes over the nearer machine's foot as a glow would, so a
		# connection that is working can be read at a glance even where the
		# pipe underneath is hidden by the machine in front of it.
		var dir: Vector2 = (b - a).normalized()
		var reach: float = a.distance_to(b) * (0.5 - _footprint() * 0.5) + 14.0
		var mid: Vector2 = (a + b) * 0.5 - Vector2(0, 12)
		var seam: Color = col2
		seam.a = 0.45 * live
		seams.band(mid - dir * reach, mid + dir * reach, 6.0, seam)
		col2.a = live
		ci.draw_texture_rect(g, Rect2(p - Vector2(20, 20), Vector2(40, 40)), false, col2)
	_draw_life(ci, g)
	seams.flush(ci)


## Each running machine doing its own job where it can be seen doing it:
## dust off a drill's bit, chips from a stamp, sparks out of a melt, cold mist
## off coolant, coins while a vault has something to sell, a welding flicker,
## a lab's pulse. Light only, so it all goes in this additive layer and
## batches with the rest of it; timed from the machine's own cycle, so what
## moves is what is producing; and only close enough to be seen -- zoomed
## out, a factory is its glow.
const WORK_LOD := 0.55
## At most this many machines show their work at once. Past it, a fixed
## share of them does -- the same ones every frame, so nothing flickers --
## which on a 300-machine board halves the pass, and on a board that size
## the eye reads the glow, not each drill's dust.
const WORK_BUDGET := 150

func _draw_work(ci: CanvasItem, g: Texture2D) -> void:
	if cam.zoom < WORK_LOD:
		return
	var stride: int = maxi(ceili(float(Sim.grid.cells.size()) / float(WORK_BUDGET)), 1)
	for cell: int in Sim.grid.cells:
		if stride > 1 and (cell * 7 + cell / Grid.W) % stride != 0:
			continue
		if Sim.sim.status_of(cell) != Simulation.Status.RUNNING:
			continue
		var id: String = Sim.grid.machine_at(cell)
		var c: Vector2 = Iso.cell_center(cell)
		var off: float = float(cell) * 0.731
		match id:
			"drill":
				for k in range(3):
					var t: float = fposmod(_anim * 1.1 + float(k) / 3.0 + off, 1.0)
					var p: Vector2 = c + Vector2((float(k) - 1.0) * 14.0
						+ sin(t * 6.0 + off) * 5.0, 8.0 - t * 22.0)
					_mote(ci, g, p, 5.0 + t * 7.0, Color(0.95, 0.80, 0.60, 0.24 * sin(t * PI)))
			"crusher", "press":
				var hit: float = _stamp(cell)
				if hit > 0.0:
					for k in range(5):
						var a: float = TAU * float(k) / 5.0 + off
						var p: Vector2 = c - Vector2(0, 6) \
							+ Vector2(cos(a) * 30.0, sin(a) * 13.0) * hit
						_mote(ci, g, p, 4.5, Color(1.0, 0.70, 0.35, 0.55 * (1.0 - hit)))
			"smelter":
				for k in range(3):
					var t: float = fposmod(_anim * 0.9 + float(k) / 3.0 + off, 1.0)
					var p: Vector2 = c - Vector2(0, 38) + Vector2(sin(t * 9.0 + float(k) * 2.0)
						* 10.0, -t * 46.0)
					_mote(ci, g, p, 3.5, Color(1.0, 0.60, 0.20, 0.85 * (1.0 - t)))
			"coolant":
				for k in range(3):
					var t: float = fposmod(_anim * 0.45 + float(k) / 3.0 + off, 1.0)
					var p: Vector2 = c + Vector2((float(k) - 1.0) * 20.0 + t * 8.0, -16.0 + t * 20.0)
					_mote(ci, g, p, 9.0 + t * 8.0, Color(0.55, 0.85, 1.0, 0.22 * sin(t * PI)))
			"vault":
				if not _receiving(cell):
					continue
				for k in range(2):
					var t: float = fposmod(_anim * 0.8 + float(k) * 0.5 + off, 1.0)
					var p: Vector2 = c - Vector2(0, 50) + Vector2((float(k) - 0.5) * 16.0,
						-t * 30.0)
					_mote(ci, g, p, 5.0, Color(1.0, 0.85, 0.30, 0.9 * sin(t * PI)))
			"assembler":
				var f: float = maxf(sin(_anim * 23.0 + off) * sin(_anim * 7.0 + off), 0.0)
				_mote(ci, g, c - Vector2(6, 54), 10.0 + 8.0 * f,
					Color(0.70, 0.95, 1.0, 0.45 * f))
			"lab", "amplifier", "duplicator", "condenser":
				var pl: float = 0.5 + 0.5 * sin(_anim * 3.0 + off)
				var col: Color = Palette.machine_light(id)
				col.a = 0.18 + 0.20 * pl
				_mote(ci, g, c - Vector2(0, 56), 16.0 + 8.0 * pl, col)


## What a Core's level looks like beyond its size: from level 2 a halo at
## its base, from level 3 motes of energy circling it, one more per level,
## and at level 5 a slow flare from its crystal. All light, all in this
## layer.
func _draw_core_level(ci: CanvasItem, g: Texture2D, cr: Rect2) -> void:
	var lvl: int = core_level()
	var base: Vector2 = core_center()
	if lvl >= 2:
		var halo := Color(0.45, 0.85, 1.0, 0.10 + 0.04 * float(lvl))
		ci.draw_texture_rect(g, Rect2(base - Vector2(170, 90), Vector2(340, 180)), false, halo)
	if lvl >= 3:
		var mid: Vector2 = cr.position + cr.size * Vector2(0.5, 0.45)
		for k in range(lvl - 1):
			var a: float = _anim * 0.9 + TAU * float(k) / float(lvl - 1)
			var p: Vector2 = mid + Vector2(cos(a) * cr.size.x * 0.42, sin(a) * cr.size.x * 0.16)
			_mote(ci, g, p, 9.0, Color(0.55, 0.9, 1.0, 0.55))
	if lvl >= 5:
		var tip := Vector2(cr.get_center().x, cr.position.y + cr.size.y * 0.12)
		var f: float = maxf(sin(_anim * 0.8), 0.0)
		# From level 8 the crystal never goes dark between flares.
		var floor_a: float = 0.12 if lvl >= 8 else 0.0
		_mote(ci, g, tip, 60.0 + 50.0 * f, Color(0.6, 0.9, 1.0, floor_a + 0.25 * f))
	if lvl >= 6:
		# A column of light rising from the crystal, taller and brighter at
		# each level: it stands above everything on the board, so it reads
		# from any zoom, where a ring on the ground would be under the
		# machines round the Core.
		var top := Vector2(cr.get_center().x, cr.position.y + cr.size.y * 0.12)
		var steps: int = 3 + 2 * (lvl - 6)
		var pulse2: float = 0.8 + 0.2 * sin(_anim * 1.4)
		for i in range(steps):
			var up: float = float(i) / float(steps)
			var p3: Vector2 = top - Vector2(0, cr.size.y * 0.16 * float(i))
			var r3: float = cr.size.x * (0.2 - 0.1 * up)
			_mote(ci, g, p3, r3, Color(0.5, 0.9, 1.0, (0.5 - 0.35 * up) * pulse2))
	if lvl >= 7:
		# A second, higher orbit.
		var hi: Vector2 = cr.position + cr.size * Vector2(0.5, 0.25)
		for k in range(3):
			var a3: float = -_anim * 1.3 + TAU * float(k) / 3.0
			_mote(ci, g, hi + Vector2(cos(a3) * cr.size.x * 0.3, sin(a3) * cr.size.x * 0.1), 18.0,
				Color(0.7, 0.95, 1.0, 0.75))


## The Core's conduits into the yard, from level 2: lit lines on the floor
## from its base to the tiles beside it, with light running along them -- the
## Core powering the ground the factory stands on.
func _draw_core_conduits(ci: CanvasItem) -> void:
	if not Sim.core_online:
		return
	var n: int = mini(core_level() - 1, 4)
	var base: Vector2 = core_center()
	var c: Rect2i = BuildArea.CORE
	# Out of the middle of each of the Core's sides into the ring round it.
	var sides: Array[Vector2i] = [Vector2i(c.position.x - 1, c.position.y + 1),
		Vector2i(c.end.x, c.position.y + 2), Vector2i(c.position.x + 2, c.position.y - 1),
		Vector2i(c.position.x + 1, c.end.y)]
	var tris := Tris.new()
	for k in range(n):
		var to: Vector2 = Iso.cell_center(Grid.idx(sides[k].x, sides[k].y))
		var lit: Color = Palette.ACCENT
		lit.a = 0.35
		tris.band(base, to, 5.0, lit)
		var t: float = fposmod(_anim * 0.7 + float(k) * 0.33, 1.0)
		var bead: Color = Palette.ACCENT.lerp(Color.WHITE, 0.4)
		bead.a = 0.9 * sin(t * PI)
		tris.dot(base.lerp(to, t), 5.0, bead)
	tris.flush(ci)


## A soft round of light at `p`.
func _mote(ci: CanvasItem, g: Texture2D, p: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(g, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


## 0..1 through the last seventh of a stamping machine's cycle, 0 otherwise.
func _stamp(cell: int) -> float:
	return clampf((Sim.sim.progress_of(cell) - 0.86) / 0.14, 0.0, 1.0)


## Is material crossing into `cell` right now?
func _receiving(cell: int) -> bool:
	for n in Sim.grid.neighbours(cell):
		if _flow.has("%d-%d" % [mini(cell, n), maxi(cell, n)]):
			return true
	return false


## The things that make the place feel lived in, all light and all cheap:
## steam off the machines that run hot by nature, embers off the ones that
## are overheating, the crystals and lamps breathing, the Core's crystal, and
## a little dust drifting through the lamp light. Every one of them reads the
## simulation or the layout; none of them is a rule.
const STEAMERS := ["smelter", "boiler", "press", "condenser"]

func _draw_life(ci: CanvasItem, g: Texture2D) -> void:
	# Settings' "Machine effects" is the machines' own: their work and their
	# steam. The crystals, the lamps and the Core stay lit either way.
	if effects:
		_draw_work(ci, g)
	for cell: int in (Sim.grid.cells if effects else {}):
		var id: String = Sim.grid.machine_at(cell)
		var st: int = Sim.sim.status_of(cell)
		var shown: int = badges.shown(cell)
		var hot: bool = shown == StatusBadges.Show.HOT or shown == StatusBadges.Show.CRITICAL
		if not (hot or (st == Simulation.Status.RUNNING and STEAMERS.has(id))):
			continue
		var top: Vector2 = Iso.cell_center(cell) - Vector2(0, Iso.TH * 1.55)
		for k in range(2):
			var t: float = fposmod(_anim * 0.55 + float(k) * 0.5 + float(cell) * 0.137, 1.0)
			var drift := Vector2(sin(t * 5.0 + float(cell)) * 6.0, -t * 46.0)
			var col: Color = Color(1.0, 0.55, 0.25) if hot else Color(0.85, 0.88, 0.95)
			col.a = (0.30 if hot else 0.16) * sin(t * PI)
			var r: float = (7.0 if hot else 11.0) + t * 16.0
			ci.draw_texture_rect(g, Rect2(top + drift - Vector2(r, r), Vector2(r, r) * 2.0),
				false, col)
	# Crystals and lamps on the slab, the ones on screen.
	var seen: Rect2 = cam.visible_world().grow(Iso.TW)
	for f: Array in _props_now():
		if f[2] or not seen.intersects(f[1]):
			continue
		var pr: Array = f[0]
		var kind: String = String(pr[2])
		var col2: Color
		match kind:
			"crystal_purple": col2 = Color(0.75, 0.35, 1.0)
			"crystal_cyan": col2 = Color(0.35, 0.85, 1.0)
			"ore_vein": col2 = Color(1.0, 0.55, 0.2)
			"lamp": col2 = Color(1.0, 0.75, 0.4)
			_: continue
		var ks: float = prop_scale(pr)
		var at: Vector2 = f[5] - Vector2(0, 30 * ks)
		var breathe: float = 0.5 + 0.5 * sin(_anim * 1.7 + float(int(pr[0]) * 3 + int(pr[1])))
		col2.a = 0.17 + 0.14 * breathe
		ci.draw_texture_rect(g, Rect2(at - Vector2(46, 40) * ks, Vector2(92, 80) * ks), false, col2)
	# The Core's crystal, brighter the more of the board is running.
	var cr: Rect2 = core_rect()
	if cr.size.x > 0.0 and Sim.core_online:
		var running: int = 0
		for cell: int in Sim.grid.cells:
			if Sim.sim.status_of(cell) == Simulation.Status.RUNNING:
				running += 1
		var k2: float = clampf(float(running) / 12.0, 0.2, 1.0) + _core_flash * 2.0
		var tip := Vector2(cr.get_center().x, cr.position.y + cr.size.y * 0.16)
		var col3 := Color(0.45, 0.85, 1.0, (0.35 + 0.15 * sin(_anim * 2.2)) * k2)
		ci.draw_texture_rect(g, Rect2(tip - Vector2(70, 70), Vector2(140, 140)), false, col3)
		_draw_core_level(ci, g, cr)
	# Dust in the lamp light: a fixed set of motes on slow loops over the slab.
	# The band sets its colour and how thick it hangs -- lamp dust at the
	# Surface, amber in the Workings, embers in the Deep, violet in the Abyss
	# -- until each band has its own art (docs/AUDIT.md, "Planned: a
	# different look per depth"). Reduce motion leaves the air still.
	if calm_motion:
		return
	var band: int = int(Palette.band_at(Sim.depth)[0])
	var mote := Color(1.0, 0.9, 0.7)
	if band > 0:
		mote = Color(Palette.BAND_VEIN[band]).lerp(mote, 0.35)
	var slab: PackedVector2Array = Iso.slab_corners()
	var left: float = slab[3].x
	var width: float = slab[1].x - slab[3].x
	for i in range([22, 28, 36, 44][band]):
		var sx: float = fposmod(float(i) * 0.6180339, 1.0)
		var t2: float = fposmod(_anim * (0.03 + 0.02 * fposmod(float(i) * 0.37, 1.0)) + sx, 1.0)
		var p2 := Vector2(left + width * sx + sin(_anim * 0.5 + float(i)) * 20.0,
			slab[2].y - t2 * (slab[2].y - slab[0].y + 260.0))
		var col4 := Color(mote, (0.20 if band == 0 else 0.26) * sin(t2 * PI))
		ci.draw_texture_rect(g, Rect2(p2 - Vector2(3, 3), Vector2(6, 6)), false, col4)


## --- the crew and the galleries (Operations) --------------------------------------
##
## The Rigs are on the board: the ones at home park at the Rig Bay past the
## yard's upper-left edge; a sortie drives out to its site's mouth beyond
## the yard's edge, works there, and drives home carrying what it found;
## a service call drives to the machines levelled. The sites are gallery
## mouths past three of the yard's edges. All of it is drawn
## on the things layer, after the machines: the Rigs, the mouths and the
## Rig Bay as pictures from two sheets (`crew/rig.webp`,
## `world/galleries.webp`), and the rest as one list of triangles -- no node,
## so the crew costs a few draw calls whatever its size.

## The Rigs drawn parked at the Bay, at most.
const RIGS_SHOWN := 12
## A service call: Rigs from the Core walk to the machines of a type that
## was just levelled or driven, work on them, and walk back -- the
## upgrade, done by the crew, on the board. Only for the eye: the level is
## the player's the moment it is bought.
const SERVICE_SECONDS := 5.0
const SERVICE_RIGS := 3
var _service: Array = []


## Send up to SERVICE_RIGS Rigs at home to the machines of type `id`
## nearest the Core.
func service(id: String) -> void:
	if Sim.rigs_home() <= 0 or calm_motion:
		return
	var cells: Array = []
	for cell: int in Sim.grid.cells:
		if Sim.grid.machine_at(cell) == id:
			cells.append(cell)
	var c0: Vector2 = core_center()
	cells.sort_custom(func(a: int, b: int) -> bool:
		return Iso.cell_center(a).distance_squared_to(c0) < Iso.cell_center(b).distance_squared_to(c0))
	for k in range(mini(mini(SERVICE_RIGS, Sim.rigs_home()), cells.size())):
		_service.append({"cell": int(cells[k]), "t0": _anim + float(k) * 0.35})
## A Rig just made drives from its Rig Frame to the Bay (NEWBORN_SECONDS);
## a repair sets the crew at the Bay to work, sparks and all
## (REPAIR_SECONDS). Only for the eye: the Rig is the crew's, and the wear
## gone, the moment the simulation says so.
const NEWBORN_SECONDS := 3.0
const REPAIR_SECONDS := 3.0
var _newborn: Array = []
var _repair_until: float = -1.0


func repair_call() -> void:
	if not calm_motion:
		_repair_until = _anim + REPAIR_SECONDS


## A sortie home: what it brought flies from the crew's row into the Core
## for DELIVERY_SECONDS -- a gem of the site's material, and a grey one when
## it paid salvage.
const DELIVERY_SECONDS := 1.2
var _deliveries: Array = []


func deliver(report: Dictionary) -> void:
	if calm_motion:
		return
	var res: int = int(Operations.KINDS[String(report.get("kind", "flooded"))]["res"])
	_deliveries.append({"t0": _anim, "res": res, "salvage": int(report.get("salvage", 0)) > 0})


func _draw_deliveries() -> void:
	_deliveries = _deliveries.filter(func(d: Dictionary) -> bool: return _anim - float(d["t0"]) < DELIVERY_SECONDS)
	var to: Vector2 = core_center()
	for d: Dictionary in _deliveries:
		var p: float = (_anim - float(d["t0"])) / DELIVERY_SECONDS
		var cols: Array = [Palette.res_color(int(d["res"]))]
		if bool(d["salvage"]):
			cols.append(Color(0.72, 0.74, 0.78))
		for k in range(cols.size() * 3):
			var q: float = clampf(p - 0.08 * float(k), 0.0, 1.0)
			if q <= 0.0 or q >= 1.0:
				continue
			var from: Vector2 = rig_home(k % 3, 3)
			var at: Vector2 = from.lerp(to, q) - Vector2(0, sin(q * PI) * Iso.TH * 0.9)
			var r: float = Iso.TW * 0.035
			var col: Color = cols[k % cols.size()]
			_quad(at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), col)


## The share of a sortie's trip spent walking out; as long walking home, and
## the rest at work in the site's mouth.
const WALK_SHARE := 0.42


## Where site slot `i`'s gallery mouth opens: past the middle of one of
## the yard's edges -- the upper left, the upper right, the lower right, the
## three a phone's panels leave in view -- most of a cell out.
func site_pos(i: int) -> Vector2:
	var reg: String = Operations.slot_region(i)
	if reg != "":
		return region_pos(reg)
	var yc: PackedVector2Array = yard_corners()
	if yc.size() < 4:
		return core_center()
	var mid: Vector2 = (yc[0] + yc[1] + yc[2] + yc[3]) * 0.25
	var edges: Array = [[3, 0], [0, 1], [1, 2]]
	var e: Array = edges[i % edges.size()]
	var edge: Vector2 = (yc[int(e[0])] + yc[int(e[1])]) * 0.5
	return edge + (edge - mid).normalized() * Iso.TW * 0.9


## Where region `r`'s way in stands: past the yard's corners, further out
## than the galleries -- the top corner, the right, and the bottom-left
## edge -- the deep map around the factory.
func region_pos(r: String) -> Vector2:
	var yc: PackedVector2Array = yard_corners()
	if yc.size() < 4:
		return core_center()
	var mid: Vector2 = (yc[0] + yc[1] + yc[2] + yc[3]) * 0.25
	var at: Vector2
	match Operations.REGION_ORDER.find(r):
		0:
			at = yc[0]
		1:
			at = yc[1]
		2:
			at = yc[2].lerp(yc[3], 0.5)
		_:
			# The Dark Reach: past the far corner, the deepest way out.
			at = yc[2]
	return at + (at - mid).normalized() * Iso.TW * 1.5


## How each region's way in is drawn: the galleries' picture, tinted for its
## ground.
const REGION_LOOK := {"sunken": ["open", Color(0.62, 0.82, 1.0)], "caverns": ["open", Color(0.86, 0.66, 1.0)],
	"foundry": ["nest", Color(1.0, 0.62, 0.45)], "reach": ["open", Color(0.45, 0.42, 0.72)]}


## A Beacon over a held region's way in: a lamp over the picture's middle,
## warm while it burns, a cold ember while the store has no Lenses for it.
func _draw_beacon(ci: CanvasItem, info: Dictionary, at: Vector2, k_scale: float, r: String) -> void:
	var cell: Array = info.get("cell", [256, 256])
	var anchor: Array = info.get("anchor", [128, 256])
	var box := Rect2(at - Vector2(float(anchor[0]), float(anchor[1])) * k_scale,
		Vector2(float(cell[0]), float(cell[1])) * k_scale)
	var top: Vector2 = Vector2(box.get_center().x, box.position.y + box.size.y * 0.18)
	var pulse: float = 0.5 + 0.5 * sin(_anim * 2.4 + float(Operations.REGION_ORDER.find(r)))
	var lamp: Color = Color(0.45, 0.55, 0.8, 0.30) if Sim.beacons_dark \
		else Color(1.0, 0.82, 0.42, 0.40 + 0.2 * pulse)
	var g: Texture2D = IsoArt.glow()
	ci.draw_texture_rect(g, Rect2(top - Vector2(120, 100), Vector2(240, 200)), false, lamp)
	var flame: Color = Color(1.0, 0.95, 0.8, 0.9) if not Sim.beacons_dark else Color(0.6, 0.7, 0.95, 0.5)
	ci.draw_texture_rect(g, Rect2(top - Vector2(26, 26), Vector2(52, 52)), false, flame)


## The Rig Bay, the crew's garage and charging pad: past the yard's upper
## left edge, a quarter of the way from its left corner, where the crew
## parks between jobs -- off the machines, and in view with the mouths.
func bay_pos() -> Vector2:
	var yc: PackedVector2Array = yard_corners()
	if yc.size() < 4:
		return core_center()
	var mid: Vector2 = (yc[0] + yc[1] + yc[2] + yc[3]) * 0.25
	var edge: Vector2 = yc[3].lerp(yc[0], 0.28)
	return edge + (edge - mid).normalized() * Iso.TW * 1.25


## Where Rig `k` of `n` at home stands: parked in rows of five along the
## Bay's front edge, the side its door opens on.
func rig_home(k: int, _n: int) -> Vector2:
	var along := Vector2(Iso.TW * 0.32, -Iso.TH * 0.16)
	var out := Vector2(Iso.TW * 0.24, Iso.TH * 0.3)
	return bay_pos() + Vector2(Iso.TW * 0.3, Iso.TH * 0.12) + along * float(k % 5) + out * float(k / 5)


## A site's mouth under world point `w`, or -1. The boarded-up mouths
## answer too.
func site_at(w: Vector2) -> int:
	for i in range(Operations.SLOTS):
		if i < Operations.slots(Sim.core_level) and not Sim.site(i).has("kind"):
			continue
		if site_pos(i).distance_to(w) < Iso.TW * 0.45:
			return i
	# The deep map's ways in, from the Core that opens it.
	if Sim.core_level >= Operations.REGION_CORE:
		for r: String in Operations.REGION_ORDER:
			if region_pos(r).distance_to(w) < Iso.TW * 0.5:
				return Operations.region_slot(r)
	return -1


func _draw_galleries(ci: CanvasItem) -> void:
	# The mouths the Core's level has not opened are there from the first
	# minute, boarded up -- the world past the yard, and a promise.
	var gal: Dictionary = IsoArt.layout().get("galleries", {})
	var tint: Color = Color.WHITE.lerp(_band_tint, 0.3)
	for i in range(Operations.SLOTS):
		var art: String = "boarded"
		if i < Operations.slots(Sim.core_level):
			var s: Dictionary = Sim.site(i)
			if not s.has("kind"):
				continue
			art = "nest" if String(s["kind"]) == "nest" else "open"
		# The upper-right mouth faces the yard, down and to the left.
		_sprite(ci, gal, art, site_pos(i) + Vector2(0, Iso.TH * 0.3), MOUTH_SCALE, i == 1, tint)
	# The deep map's ways in: sealed until an expedition opens them.
	if Sim.core_level >= Operations.REGION_CORE:
		for r: String in Operations.REGION_ORDER:
			var look: Array = REGION_LOOK[r]
			var open: bool = Sim.region_open(r)
			var rt: Color = (look[1] as Color) * (Color.WHITE if open else Color(0.55, 0.55, 0.6))
			_sprite(ci, gal, String(look[0]) if open else "boarded", region_pos(r) + Vector2(0, Iso.TH * 0.3),
				MOUTH_SCALE * 1.15, false, Color(rt.r, rt.g, rt.b, 1.0))
			if Sim.beacons.has(r):
				_draw_beacon(ci, gal, region_pos(r) + Vector2(0, Iso.TH * 0.3), MOUTH_SCALE * 1.15, r)
	_sprite(ci, gal, "bay", bay_pos(), MOUTH_SCALE, false, tint)
	# What is left of each open site, as a bar under its mouth.
	for i in range(Sim.ops_board.size()):
		var s2: Dictionary = Sim.site(i)
		if not s2.has("kind"):
			continue
		var rim: Color = Color(0.9, 0.3, 0.2) if String(s2["kind"]) == "nest" else Color(1.0, 0.72, 0.35)
		var left: float = clampf(float(s2["left"]) / maxf(float(s2["need"]), 1.0), 0.0, 1.0)
		var bar := Rect2(site_pos(i) + Vector2(-Iso.TW * 0.25, Iso.TH * 0.55), Vector2(Iso.TW * 0.5, 7.0))
		_rect(bar, Color(0, 0, 0, 0.6))
		_rect(Rect2(bar.position, Vector2(bar.size.x * left, bar.size.y)), Color(rim, 0.95))
	# Posted Rigs: from the Core's side to their machine with a load from
	# the store, and back for the next.
	for pc: int in Sim.posts:
		var mach: Vector2 = Iso.cell_center(pc) + Vector2(Iso.TW * 0.2, Iso.TH * 0.15)
		var dock: Vector2 = mach.lerp(core_center(), 0.35)
		var ph: float = fposmod(_anim * 0.45 + float(pc) * 0.137, 1.0)
		if ph < 0.5:
			_draw_rig(dock.lerp(mach, ph * 2.0), _anim * 9.0, false, 0.0, true, mach - dock)
		else:
			_draw_rig(mach.lerp(dock, (ph - 0.5) * 2.0), _anim * 9.0, false, 0.0, false, dock - mach)
	# Rigs just made, on their way from the Rig Frame to the Bay.
	_newborn = _newborn.filter(func(nb: Dictionary) -> bool: return _anim - float(nb["t0"]) < NEWBORN_SECONDS)
	for m: int in range(_newborn.size()):
		var nb: Dictionary = _newborn[m]
		var from0: Vector2 = Iso.cell_center(int(nb["cell"]))
		var to0: Vector2 = rig_home(0, 1)
		var p0: float = (_anim - float(nb["t0"])) / NEWBORN_SECONDS
		_draw_rig(from0.lerp(to0, p0), _anim * 9.0 + float(m), false, 0.0, false, to0 - from0)
	# The crew at home; the ones out on a service call are drawn there, and
	# the ones still driving in from the Rig Frame are not yet here.
	var home: int = mini(maxi(Sim.rigs_home() - _newborn.size(), 0), RIGS_SHOWN)
	var mending: bool = _anim < _repair_until
	var calls: Array = _service.filter(func(c: Dictionary) -> bool: return _anim - float(c["t0"]) < SERVICE_SECONDS)
	_service = calls
	var busy: int = mini(calls.size(), home)
	for k in range(home - busy):
		var spot: Vector2 = rig_home(k, home)
		# Being repaired: every other Rig at work on its neighbour.
		var at_work: bool = mending and k % 2 == 0
		_draw_rig(spot, float(k) * 1.3, at_work, 0.0 if mending else Sim.rig_wear)
		if at_work and fposmod(_anim * 3.0 + float(k) * 0.41, 1.0) < 0.35:
			for sp in range(3):
				var d := Vector2(cos(float(sp) * 2.3 + _anim * 8.0), -absf(sin(float(sp) * 1.9 + _anim * 6.0)))
				_seg(spot + Vector2(-8, -14), spot + Vector2(-8, -14) + d * 12.0, 2.0, Color(0.6, 0.95, 1.0, 0.9))
	# The Breakers at home, parked past the Rigs: bigger, in rust-red plate.
	for kb in range(mini(Sim.breakers, RIGS_SHOWN)):
		_draw_rig(rig_home(home - busy + kb, home), float(kb) * 1.7, false, 0.0 if mending else Sim.rig_wear,
			false, Vector2.ZERO, true)
	# The Surveyors past them: lighter, smaller, in sea-glass paint.
	for kv in range(mini(Sim.surveyors, RIGS_SHOWN)):
		_draw_rig(rig_home(home - busy + mini(Sim.breakers, RIGS_SHOWN) + kv, home), float(kv) * 2.1, false,
			0.0 if mending else Sim.rig_wear, false, Vector2.ZERO, false, true)
	for j in range(busy):
		var call: Dictionary = calls[j]
		var k2: int = home - busy + j
		var from: Vector2 = rig_home(k2, home)
		var to: Vector2 = Iso.cell_center(int(call["cell"])) + Vector2(Iso.TW * 0.22, Iso.TH * 0.1)
		var p: float = (_anim - float(call["t0"])) / SERVICE_SECONDS
		var at: Vector2
		var working: bool = false
		var heading: Vector2 = Vector2.ZERO
		if p < 0.3:
			at = from.lerp(to, p / 0.3)
			heading = to - from
		elif p < 0.7:
			working = true
			at = to
		else:
			at = to.lerp(from, (p - 0.7) / 0.3)
			heading = from - to
		_draw_rig(at, _anim * 9.0 + float(j), working, Sim.rig_wear, false, heading)
		if working and not calm_motion and fposmod(_anim * 3.0 + float(j) * 0.41, 1.0) < 0.3:
			for sp in range(3):
				var d := Vector2(cos(float(sp) * 2.3 + _anim * 8.0), -absf(sin(float(sp) * 1.9 + _anim * 6.0)))
				_seg(at + Vector2(0, -12), at + Vector2(0, -12) + d * 12.0, 2.0, Color(0.6, 0.95, 1.0, 0.9))
	# Sorties out: walking out, at work in the mouth, walking home.
	for so: Dictionary in Sim.sorties:
		var trip: float = maxf(float(so["trip"]), 1.0)
		var p: float = clampf(1.0 - float(so["left"]) / trip, 0.0, 1.0)
		var n: int = mini(int(so["n"]), RIGS_SHOWN)
		var nb: int = mini(int(so.get("b", 0)), RIGS_SHOWN)
		var nv: int = mini(int(so.get("v", 0)), RIGS_SHOWN)
		var target: Vector2 = site_pos(int(so["slot"]))
		for k in range(n + nb + nv):
			var start: Vector2 = rig_home(k, n)
			var q: float = clampf(p - 0.015 * float(k), 0.0, 1.0)
			var at: Vector2
			var working: bool = false
			var heading: Vector2 = Vector2.ZERO
			if q < WALK_SHARE:
				at = start.lerp(target, q / WALK_SHARE)
				heading = target - start
			elif q < 1.0 - WALK_SHARE:
				working = true
				at = target + Vector2(sin(_anim * 3.0 + float(k)) * Iso.TW * 0.12,
					Iso.TH * 0.25 + Iso.TH * 0.1 * float(k % 2))
			else:
				at = target.lerp(start, (q - (1.0 - WALK_SHARE)) / WALK_SHARE)
				heading = start - target
			_draw_rig(at, _anim * 9.0 + float(k), working, float(so["wear"]), q >= 1.0 - WALK_SHARE, heading,
				k >= n and k < n + nb, k >= n + nb)
			if working and not calm_motion and fposmod(_anim * 2.0 + float(k) * 0.37, 1.0) < 0.25:
				# Sparks: the work.
				for sp in range(3):
					var d := Vector2(cos(float(sp) * 2.1 + _anim * 7.0), -absf(sin(float(sp) * 1.7 + _anim * 5.0)))
					_seg(at + Vector2(0, -10), at + Vector2(0, -10) + d * 12.0, 2.0, Color(1.0, 0.85, 0.4, 0.9))
	_draw_deliveries()
	_flush_tris(ci)
	var crew: Dictionary = IsoArt.layout().get("crew", {})
	# The Breaker's and the Surveyor's own sheets; without them, the Rig's,
	# scaled and painted.
	var heavy: Dictionary = IsoArt.layout().get("crew_breaker", {})
	var light: Dictionary = IsoArt.layout().get("crew_surveyor", {})
	_rigs_to_draw.sort_custom(func(a: Array, b: Array) -> bool: return (a[1] as Vector2).y < (b[1] as Vector2).y)
	for r: Array in _rigs_to_draw:
		var own: Dictionary = heavy if bool(r[3]) else (light if bool(r[4]) else crew)
		if own.is_empty():
			var scale: float = BREAKER_SCALE if bool(r[3]) else (SURVEYOR_SCALE if bool(r[4]) else 1.0)
			_sprite(ci, crew, String(r[0]), r[1], RIG_SCALE * scale, bool(r[2]),
				BREAKER_TINT if bool(r[3]) else (SURVEYOR_TINT if bool(r[4]) else Color.WHITE))
		else:
			_sprite(ci, own, String(r[0]), r[1], RIG_SCALE, bool(r[2]))
	_rigs_to_draw.clear()
	_draw_walker(ci)


## --- the Foreman on the board -----------------------------------------------
##
## The Foreman walks the yard: to the Core when it grows, to a machine the
## moment it is laid, to the Core again when a machine is found; now and
## then to a working machine, to look it over. He stands where he was sent
## in the pose of what he came for, then goes back to his place at the
## front of the Core's plate. The HUD's Foreman is his voice; this is him.

var _fm_at := Vector2.INF
var _fm_to := Vector2.ZERO
var _fm_pose: int = Foreman.Pose.IDLE
var _fm_hold: float = 0.0
var _fm_idle: float = 0.0
var _fm_walking: bool = false
## How fast he walks, in tiles a second; how long he stays idle before he
## goes to look a machine over; his size against the sheet.
const FM_SPEED := 1.4
const FM_WANDER := 16.0
const FM_SCALE := 0.15


## Send the Foreman to `cell` (-1: the Core) to stand there in `pose` for
## `hold` seconds.
func foreman_visit(cell: int, pose: int, hold: float = 3.0) -> void:
	_fm_to = _fm_home() if cell < 0 else Iso.cell_center(cell) + Vector2(0.0, Iso.TH * 0.32)
	_fm_pose = pose
	_fm_hold = hold
	_fm_idle = 0.0


## His place: on the Core's plate, at its front corner, a step in. The
## Core does not move: found once.
var _fm_home_at := Vector2.INF


func _fm_home() -> Vector2:
	if _fm_home_at == Vector2.INF:
		_fm_home_at = _fm_find_home()
	return _fm_home_at


func _fm_find_home() -> Vector2:
	var front: int = -1
	for cell in range(Grid.W * Grid.H):
		if BuildArea.is_core(cell):
			var xy: Vector2i = Grid.xy(cell)
			if front < 0 or xy.x + xy.y > Grid.xy(front).x + Grid.xy(front).y:
				front = cell
	if front < 0:
		return Iso.board_rect().get_center()
	return Iso.cell_center(front) + Vector2(-Iso.TW * 0.18, Iso.TH * 0.22)


func _fm_step(delta: float) -> void:
	var home: Vector2 = _fm_home()
	if _fm_at == Vector2.INF:
		_fm_at = home
		_fm_to = home
	var d: Vector2 = _fm_to - _fm_at
	var step: float = FM_SPEED * Iso.TW * delta
	if d.length() > step:
		_fm_at += d.normalized() * step
		_fm_walking = true
		return
	_fm_at = _fm_to
	_fm_walking = false
	if _fm_hold > 0.0:
		_fm_hold -= delta
		if _fm_hold <= 0.0 and not _fm_to.is_equal_approx(home):
			_fm_to = home
			_fm_pose = Foreman.Pose.IDLE
		return
	_fm_idle += delta
	if _fm_idle > FM_WANDER and not Sim.grid.cells.is_empty():
		# A working machine, looked over.
		var cells: Array = Sim.grid.cells.keys()
		var cell: int = int(cells[int(_anim * 7919.0) % cells.size()])
		if Sim.sim.status_of(cell) == Simulation.Status.RUNNING:
			foreman_visit(cell, Foreman.Pose.POINT, 2.5)
		else:
			_fm_idle = FM_WANDER * 0.5


func _draw_walker(ci: CanvasItem) -> void:
	if _fm_at == Vector2.INF:
		return
	var sz := Vector2(252.0, 420.0) * FM_SCALE
	var pose: int = Foreman.Pose.IDLE if _fm_walking else _fm_pose
	# A walk is a bob; standing, the sheet's own slow breathing.
	var bob: float = 0.0 if calm_motion or not _fm_walking else -absf(sin(_anim * 9.0)) * 3.0
	Foreman.draw_at(ci, Rect2(_fm_at - Vector2(sz.x * 0.5, sz.y - bob), sz), pose, _anim * 0.45)


## One Rig on `at`: the pose for what it is doing -- standing, driving,
## at work, carrying home, or worn -- facing the way it goes (the sheet
## faces down and to the left; `heading` right of it is the mirror).
func _draw_rig(at: Vector2, phase: float, working: bool, wear: float, cargo: bool = false,
		heading: Vector2 = Vector2.ZERO, heavy: bool = false, light: bool = false) -> void:
	var pose: String = "idle"
	if working:
		pose = "work"
	elif cargo:
		pose = "carry"
	elif heading != Vector2.ZERO:
		pose = "drive"
	elif wear >= 0.4:
		pose = "worn"
	var bob: float = 0.0
	if not calm_motion and pose == "drive":
		bob = sin(phase) * 1.5
	_rigs_to_draw.append([pose, at + Vector2(0, bob), heading.x > 0.0, heavy, light])


## The Rigs of this frame, drawn after the triangles: [pose, at, mirrored,
## a Breaker].
var _rigs_to_draw: Array = []
const RIG_SCALE := 0.34
const BREAKER_SCALE := 1.3
const BREAKER_TINT := Color(1.0, 0.62, 0.48)
const SURVEYOR_SCALE := 0.85
const SURVEYOR_TINT := Color(0.62, 1.0, 0.92)
const MOUTH_SCALE := 0.62


## Picture `pic` of sheet `info`, standing on `at`, `k_scale` of its size.
func _sprite(ci: CanvasItem, info: Dictionary, pic: String, at: Vector2, k_scale: float, mirror: bool,
		tint: Color = Color.WHITE) -> void:
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	var k: int = (info.get("order", []) as Array).find(pic)
	if tex == null or k < 0:
		return
	var cell: Array = info["cell"]
	var anchor: Array = info["anchor"]
	var src := Rect2(float(k) * float(cell[0]), 0.0, float(cell[0]), float(cell[1]))
	var sz := Vector2(float(cell[0]), float(cell[1])) * k_scale
	var pos: Vector2 = at - Vector2(float(anchor[0]), float(anchor[1])) * k_scale
	if mirror:
		# A negative width draws the picture mirrored.
		ci.draw_texture_rect_region(tex, Rect2(pos.x + sz.x, pos.y, -sz.x, sz.y), src, tint)
	else:
		ci.draw_texture_rect_region(tex, Rect2(pos, sz), src, tint)


## What is drawn as shapes -- the sites' bars, sparks, what flies home --
## goes to the renderer as one list of triangles a frame, not a draw command
## a shape (measured: drawn shape by shape, five Rigs and two sorties took
## the idle board from 191 draw calls to 295).
var _tri_pts := PackedVector2Array()
var _tri_cols := PackedColorArray()
var _tri_idx := PackedInt32Array()


func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	_tri_pts.append(a)
	_tri_pts.append(b)
	_tri_pts.append(c)
	_tri_cols.append(col)
	_tri_cols.append(col)
	_tri_cols.append(col)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	_tri(a, b, c, col)
	_tri(a, c, d, col)


func _rect(r: Rect2, col: Color) -> void:
	_quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col)


## A line `w` wide from `a` to `b`.
func _seg(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var n: Vector2 = (b - a).orthogonal().normalized() * w * 0.5
	_quad(a + n, b + n, b - n, a - n, col)


func _flush_tris(ci: CanvasItem) -> void:
	var n: int = _tri_pts.size()
	if n == 0:
		return
	while _tri_idx.size() < n:
		_tri_idx.append(_tri_idx.size())
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(),
		_tri_idx if _tri_idx.size() == n else _tri_idx.slice(0, n), _tri_pts, _tri_cols)
	_tri_pts = PackedVector2Array()
	_tri_cols = PackedColorArray()


## --- screen-space overlay ------------------------------------------------------

func _badge_side(cell: int, downstream: bool) -> Vector2:
	return (_side_down if downstream else _side_up).get(cell, Vector2(0.55, -0.4))


## Per machine, the way its links leave (downstream) and arrive (upstream),
## for the side a badge sits on. Worked out with the links, not per badge
## per frame by a scan of every link.
func _link_sides() -> void:
	_side_down = {}
	_side_up = {}
	for l: Dictionary in _links:
		var a: int = int(l["from"])
		var b: int = int(l["to"])
		var d: Vector2 = Iso.cell_center(b) - Iso.cell_center(a)
		_side_down[a] = Vector2(_side_down.get(a, Vector2.ZERO)) + d
		_side_up[b] = Vector2(_side_up.get(b, Vector2.ZERO)) - d
	for side: Dictionary in [_side_down, _side_up]:
		for k: int in side.keys():
			var v: Vector2 = side[k]
			if v == Vector2.ZERO:
				side.erase(k)
			else:
				side[k] = v.normalized()


func _draw_over() -> void:
	var ci: CanvasItem = _over
	var font: Font = ThemeDB.fallback_font
	var z: float = cam.zoom
	var r: float = clampf(12.0 * z, 9.0, 16.0)
	# Every shape in this layer goes into one batch; text follows it.
	var ov := Tris.new()
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
		_badge(ov, p, r, shown)

	# While a machine is armed or being moved, the yard cells behind the
	# Core are outlined over it: they are there, and they take machines.
	if (arm_id != "" or _dragging) and overlay != Overlay.HEAT:
		var edge: Color = Palette.ACCENT
		edge.a = 0.6 + 0.25 * sin(_anim * 3.4)
		for hc: int in cells_behind_core():
			if not Sim.is_open(hc) or not Sim.grid.is_empty(hc) or Sim.is_blocked(hc):
				continue
			var d: PackedVector2Array = _diamond(hc, 0.9)
			for e in range(4):
				ov.band(cam.world_to_screen(d[e]), cam.world_to_screen(d[e + 1]), 2.5, edge)

	# The resource node the player tapped: its ground ringed, a marker over it.
	if selected_node >= 0:
		var props: Array = IsoArt.placement().get("props", [])
		if selected_node < props.size() and not _prop_cleared(props[selected_node]):
			var pr: Array = props[selected_node]
			var base: Vector2 = Iso.slab_top(float(pr[0]) + 0.5, float(pr[1]) + 0.5)
			var ring: Color = Palette.CORE
			ring.a = 0.7 + 0.25 * sin(_anim * 4.0)
			var hw: float = Iso.TW * 0.46
			var hh: float = Iso.TH * 0.46
			var dm := PackedVector2Array([base + Vector2(0, -hh), base + Vector2(hw, 0),
				base + Vector2(0, hh), base + Vector2(-hw, 0), base + Vector2(0, -hh)])
			for e in range(4):
				ov.band(cam.world_to_screen(dm[e]), cam.world_to_screen(dm[e + 1]), 3.0, ring)
			var tip: Vector2 = cam.world_to_screen(prop_rect(pr).position
				+ Vector2(prop_rect(pr).size.x * 0.5, 0.0)) + Vector2(0, sin(_anim * 4.0) * 4.0 - 4.0)
			var mw: float = clampf(11.0 * z, 8.0, 15.0)
			ov.tri(tip + Vector2(-mw, -mw * 1.4), tip + Vector2(mw, -mw * 1.4),
				tip + Vector2(0, -mw * 0.15), Palette.CORE)

	# A dark Core is the one thing to tap: a target pulsing on its body, in
	# screen space so it is the same size at any zoom.
	if highlight_core:
		var cr: Rect2 = core_rect()
		var at: Vector2 = cam.world_to_screen(cr.position + cr.size * Vector2(0.5, 0.58))
		var beat: float = 0.5 + 0.5 * sin(_anim * 4.0)
		ov.ring(at, 30.0 + 10.0 * beat, 7.0, Color(0.05, 0.05, 0.08, 0.55), 28)
		var ring: Color = Palette.ACCENT
		ring.a = 0.55 + 0.4 * beat
		ov.ring(at, 30.0 + 10.0 * beat, 4.0, ring, 28)
		ov.circle(at, 7.0, Color(0.05, 0.05, 0.08, 0.7))
		ov.circle(at, 5.0, Palette.ACCENT)

	# Material in transit: one small bead per seam the simulation actually
	# moved something across in the last moment, riding from the machine that
	# gave it to the one that took it. Screen-sized, so it stays readable when
	# zoomed out, and outlined, so it reads over any machine.
	var bead_r: float = clampf(5.0 * z, 3.5, 7.0)
	for key: String in _flow:
		if not _segments.has(key):
			continue
		var s: Dictionary = _segments[key]
		var a: Vector2 = Iso.cell_center(int(s["a"]))
		var b: Vector2 = Iso.cell_center(int(s["b"]))
		if _flow_from_b.has(key):
			var tmp: Vector2 = a
			a = b
			b = tmp
		var t: float = fposmod(_anim * 1.4 + float(key.hash() % 97) * 0.01, 1.0)
		var d: Vector2 = (b - a)
		var p: Vector2 = cam.world_to_screen(a + d * (0.3 + 0.4 * t) - Vector2(0, 14))
		var live: float = clampf(float(_flow[key]) * 2.0, 0.0, 1.0)
		var col: Color = Palette.res_color(int(s["res"])).lerp(Color.WHITE, 0.35)
		col.a = live
		ov.dot(p, bead_r + 1.5, Color(0.05, 0.05, 0.08, 0.85 * live))
		ov.dot(p, bead_r, col)

	if selected_cell >= 0 and not Sim.grid.is_empty(selected_cell) and not _dragging:
		_selected_links(ov)
		var top: Vector2 = cam.world_to_screen(Iso.cell_center(selected_cell)
			- Vector2(0, Iso.TH * 1.55))
		var bob: float = 0.0 if calm_motion else sin(_anim * 4.0) * 4.0
		var t := top + Vector2(0, bob)
		var w: float = clampf(11.0 * z, 8.0, 15.0)
		ov.tri(t + Vector2(-w, -w * 1.2), t + Vector2(w, -w * 1.2), t, Color(0, 0, 0, 0.4))
		ov.tri(t + Vector2(-w, -w * 1.4), t + Vector2(w, -w * 1.4), t + Vector2(0, -w * 0.15),
			Palette.ACCENT)
	# Research, on every machine it bought: notches on the plate's front
	# corner until the whole set turns gold.
	var marks: int = Sim.upgrade_marks()
	if marks > 0 and marks < IsoArt.UP_SHEET_MARKS and z > 0.55:
		for cell: int in Sim.grid.cells:
			var f: Vector2 = cam.world_to_screen(Iso.cell_center(cell)
				+ Vector2(0, Iso.TH * 0.5 * _footprint()))
			for k in range(marks):
				ov.dot(f + Vector2((-5.0 + 10.0 * k) * z, -3.0 * z), 3.2 * z, Palette.CORE)
	ov.flush(ci)
	if overlay == Overlay.HEAT and z > 0.55:
		_draw_heat_numbers(ci, font)
	if _pressed and not _panning and not _dragging and _press_cell >= 0:
		_draw_placement_preview(ci, font)


## "Where is this machine fed from, and where does its output go": the chain
## it is part of (Iso.chain) -- what feeds it and what feeds those, what it
## feeds and onward -- drawn over everything as lit lines with chevrons
## running the way material runs, the links touching it brightest and the
## rest fading with distance. It is the one moment the pipes are allowed on
## top of the machines, because it is the moment the player asked.
func _selected_links(ov: Tris) -> void:
	var lift := Vector2(0, -Iso.TH * 0.45)
	var sig: Array = [selected_cell, Sim.grid.version]
	if sig != _chain_sig:
		_chain_sig = sig
		_chain = Iso.chain(_links, selected_cell)
	for e: Array in _chain:
		var l: Dictionary = e[0]
		var hops: int = int(e[1])
		var path: Array = l["path"]
		var col: Color = Palette.res_color(int(l["res"])).lightened(0.25)
		col.a = 1.0 if hops == 0 else maxf(0.85 - 0.15 * float(hops), 0.35)
		var wide: float = 1.0 if hops == 0 else 0.7
		var pts := PackedVector2Array()
		for c in path:
			pts.append(cam.world_to_screen(Iso.cell_center(int(c)) + lift))
		for i in range(pts.size() - 1):
			ov.band(pts[i], pts[i + 1], 7.0 * wide, Color(0, 0, 0, 0.55 * col.a))
			ov.band(pts[i], pts[i + 1], 3.5 * wide, col)
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var d: Vector2 = (b - a).normalized()
			var n := Vector2(-d.y, d.x)
			for k in range(2 if hops == 0 else 1):
				var t: float = fposmod(_anim * 0.9 + 0.5 * float(k), 1.0)
				var p: Vector2 = a.lerp(b, 0.2 + 0.6 * t)
				ov.tri(p + d * 7.0, p - d * 5.0 + n * 6.0, p - d * 5.0 - n * 6.0, col)


func _badge(ov: Tris, p: Vector2, r: float, kind: int) -> void:
	if not calm_motion:
		p.y += sin(_anim * 3.0) * 1.5
	ov.circle(p + Vector2(0, 2), r + 1.5, Color(0, 0, 0, 0.45))
	var col: Color
	match kind:
		StatusBadges.Show.BLOCKED: col = Palette.ST_BLOCKED
		StatusBadges.Show.STARVED: col = Palette.ST_STARVED
		StatusBadges.Show.HOT: col = Palette.ST_HOT
		StatusBadges.Show.COLD: col = Palette.ST_COLD
		_: col = Palette.BAD
	if kind == StatusBadges.Show.CRITICAL:
		var k: float = 0.5 + 0.5 * sin(_anim * 7.0)
		ov.circle(p, r * (1.35 + 0.25 * k), Color(col, 0.25 * (1.0 - k)))
	ov.circle(p, r + 1.5, Color(0.08, 0.09, 0.12))
	ov.circle(p, r, col)
	var w := Color(1, 1, 1, 0.95)
	var u: float = r * 0.5
	var lw: float = maxf(r * 0.16, 2.0)
	# A different glyph for every state, not only a different colour.
	match kind:
		StatusBadges.Show.BLOCKED:
			ov.quad(p + Vector2(-u * 0.75, -u * 0.8), p + Vector2(-u * 0.25, -u * 0.8),
				p + Vector2(-u * 0.25, u * 0.8), p + Vector2(-u * 0.75, u * 0.8), w)
			ov.quad(p + Vector2(u * 0.25, -u * 0.8), p + Vector2(u * 0.75, -u * 0.8),
				p + Vector2(u * 0.75, u * 0.8), p + Vector2(u * 0.25, u * 0.8), w)
		StatusBadges.Show.STARVED:
			ov.ring(p, u * 0.95, lw, w)
			ov.band(p + Vector2(-u, u), p + Vector2(u, -u), lw, w)
		StatusBadges.Show.HOT:
			ov.quad(p + Vector2(0, -u * 1.2), p + Vector2(u * 0.8, u * 0.4), p + Vector2(0, u),
				p + Vector2(-u * 0.8, u * 0.4), w)
		StatusBadges.Show.COLD:
			for a in range(3):
				var d := Vector2.from_angle(float(a) * PI / 3.0) * u * 1.05
				ov.band(p - d, p + d, maxf(r * 0.14, 1.5), w)
		_:
			ov.quad(p + Vector2(-u * 0.18, -u), p + Vector2(u * 0.18, -u),
				p + Vector2(u * 0.18, u * 0.2), p + Vector2(-u * 0.18, u * 0.2), w)
			ov.circle(p + Vector2(0, u * 0.62), u * 0.2, w, 8)


func _num(ci: CanvasItem, font: Font, at: Vector2, text: String, col: Color, fs: int,
		backing: bool = true) -> void:
	fs = Palette.text_px(fs)
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
		_num(ci, font, at, Loc.t("serves %d  x%.1f") % [n, Grid.factor_for(n)], col, 16)
	for nb in Sim.grid.neighbours(cell):
		var bleed: float = emitted * Sim.grid.heat_spread
		if Sim.grid.is_empty(cell) and absf(bleed) < 0.001:
			continue
		var txt: String = "%+.1f" % bleed
		var nid: String = Sim.grid.machine_at(nb)
		if nid != "":
			var nm: Dictionary = Sim.sim.machine_of(nb)
			var now: float = Sim.grid.heat_at(nb)
			var before: float = MachineDB.efficiency_of(nm, now, Sim.sim.tolerance_bonus)
			var after: float = MachineDB.efficiency_of(nm, now + bleed, Sim.sim.tolerance_bonus)
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
