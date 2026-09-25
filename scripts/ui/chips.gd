class_name Chips
extends RefCounted

## Pictures that say what the panels used to say in words, so a player who
## reads little -- or no English -- can still follow the factory:
##
##   a material is a coloured gem, in the colour the board's beads carry it
##   a gauge is a bar that fills, with a notch where it wants to be
##   an arrow is an arrow
##
## The words are still there, one tap away, behind a "?" (main._help_button).


## A material: `count` gems of its colour, up to three, then a number.
class Gem extends Control:
	var col := Color.WHITE
	var count: int = 1

	func _init(res: int, n: int, px: float) -> void:
		col = Palette.res_color(res)
		count = n
		var shown: int = clampi(n, 1, 3)
		custom_minimum_size = Vector2(px * (1.0 + 0.6 * float(shown - 1)) + (px * 0.9
			if n > 3 else 0.0), px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var h: float = size.y
		var shown: int = clampi(count, 1, 3)
		for i in range(shown):
			Chips.gem(self, Vector2(h * 0.5 + float(i) * h * 0.6, h * 0.5), h * 0.46, col)
		if count > 3:
			draw_string(ThemeDB.fallback_font, Vector2(h * (0.6 * 3.0 + 0.2), h * 0.72),
				"x%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.55), Palette.TEXT)


## A right-pointing arrow: "becomes".
class Arrow extends Control:
	func _init(px: float) -> void:
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var h: float = size.y
		var c := Vector2(size.x * 0.5, h * 0.5)
		draw_line(c - Vector2(h * 0.32, 0), c + Vector2(h * 0.1, 0), Palette.TEXT_DIM, h * 0.12)
		draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.32, 0),
			c + Vector2(0.0, -h * 0.24), c + Vector2(0.0, h * 0.24)]), Palette.TEXT_DIM)


## A red cross over whatever it is laid on: "this goes".
class Strike extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow(-minf(size.x, size.y) * 0.1)
		var w: float = maxf(minf(size.x, size.y) * 0.1, 3.0)
		var c := Color(Palette.BAD, 0.92)
		draw_line(r.position, r.end, c, w, true)
		draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), c, w, true)


## A fat arrow pointing down at the next thing to tap, bobbing: the first
## minutes' "here". Drawn, so it needs no art and scales to any screen.
class Pointer extends Control:
	var bob: bool = true
	var _t: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(60, 76)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if visible:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var y: float = (0.5 - 0.5 * cos(_t * TAU * 1.2)) * h * 0.16 if bob else h * 0.08
		var pts := PackedVector2Array([
			Vector2(w * 0.32, y), Vector2(w * 0.68, y), Vector2(w * 0.68, y + h * 0.42),
			Vector2(w * 0.96, y + h * 0.42), Vector2(w * 0.5, y + h * 0.84),
			Vector2(w * 0.04, y + h * 0.42), Vector2(w * 0.32, y + h * 0.42)])
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(3, 5))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
		draw_colored_polygon(pts, Palette.CORE)
		var ring := pts.duplicate()
		ring.append(pts[0])
		draw_polyline(ring, Color(0.25, 0.16, 0.05), 3.0, true)
		draw_line(Vector2(w * 0.42, y + h * 0.06), Vector2(w * 0.42, y + h * 0.4),
			Color(1, 1, 1, 0.55), 3.0)


## An on/off switch as a phone draws one: a pill, green with the knob to the
## right when on.
class Switch extends Control:
	var on: bool = false

	func _init(value: bool) -> void:
		on = value
		custom_minimum_size = Vector2(88, 46)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var h: float = size.y
		var w: float = size.x
		var col: Color = Palette.GOOD if on else Color(Palette.BG, 0.9)
		var r: float = h * 0.5
		draw_circle(Vector2(r, r), r, col)
		draw_circle(Vector2(w - r, r), r, col)
		draw_rect(Rect2(r, 0, w - 2.0 * r, h), col, true)
		var knob := Vector2(w - r if on else r, r)
		draw_circle(knob + Vector2(0, 2), r - 5.0, Color(0, 0, 0, 0.3))
		draw_circle(knob, r - 5.0, Palette.TEXT)


## A sign drawn in lines, for the few things the icon sheet has no picture of:
## "speaker", "wave", "screen", "sparkle", "battery", "hand", "vibrate",
## "person", "zoom", "motion", "bin", "undo".
class Glyph extends Control:
	var kind: String = ""
	var col := Palette.TEXT

	func _init(what: String, px: float) -> void:
		kind = what
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _p(x: float, y: float) -> Vector2:
		var s: float = minf(size.x, size.y)
		return (size - Vector2(s, s)) * 0.5 + Vector2(x, y) * s

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		var w: float = maxf(s * 0.07, 2.0)
		var acc := Palette.ACCENT
		match kind:
			"speaker":
				draw_colored_polygon(PackedVector2Array([_p(0.16, 0.38), _p(0.32, 0.38),
					_p(0.52, 0.2), _p(0.52, 0.8), _p(0.32, 0.62), _p(0.16, 0.62)]), col)
				draw_arc(_p(0.52, 0.5), s * 0.16, -0.8, 0.8, 12, acc, w, true)
				draw_arc(_p(0.52, 0.5), s * 0.3, -0.8, 0.8, 16, acc, w, true)
			"wave":
				for k in range(3):
					var pts := PackedVector2Array()
					for i in range(17):
						var x: float = 0.12 + 0.76 * float(i) / 16.0
						pts.append(_p(x, 0.3 + 0.2 * float(k) + 0.06 * sin(x * 14.0 + float(k))))
					draw_polyline(pts, acc if k == 1 else col, w, true)
			"screen":
				draw_rect(Rect2(_p(0.12, 0.2), Vector2(s * 0.76, s * 0.5)), col, false, w)
				draw_rect(Rect2(_p(0.2, 0.28), Vector2(s * 0.6, s * 0.34)), Color(acc, 0.5), true)
				draw_line(_p(0.5, 0.7), _p(0.5, 0.8), col, w)
				draw_line(_p(0.34, 0.82), _p(0.66, 0.82), col, w)
			"sparkle":
				for c: Array in [[0.4, 0.5, 0.3], [0.72, 0.28, 0.16], [0.74, 0.72, 0.12]]:
					var o: Vector2 = _p(float(c[0]), float(c[1]))
					var r: float = s * float(c[2])
					draw_colored_polygon(PackedVector2Array([o + Vector2(0, -r), o + Vector2(r * 0.25, -r * 0.25),
						o + Vector2(r, 0), o + Vector2(r * 0.25, r * 0.25), o + Vector2(0, r),
						o + Vector2(-r * 0.25, r * 0.25), o + Vector2(-r, 0), o + Vector2(-r * 0.25, -r * 0.25)]),
						Palette.CORE)
			"battery":
				draw_rect(Rect2(_p(0.14, 0.3), Vector2(s * 0.64, s * 0.4)), col, false, w)
				draw_rect(Rect2(_p(0.78, 0.42), Vector2(s * 0.08, s * 0.16)), col, true)
				draw_rect(Rect2(_p(0.2, 0.36), Vector2(s * 0.3, s * 0.28)), Palette.GOOD, true)
			"hand":
				draw_circle(_p(0.5, 0.5), s * 0.11, acc)
				draw_arc(_p(0.5, 0.5), s * 0.24, 0.0, TAU, 28, col, w, true)
				draw_arc(_p(0.5, 0.5), s * 0.38, -2.4, -0.7, 16, Color(col, 0.6), w, true)
			"vibrate":
				draw_rect(Rect2(_p(0.36, 0.18), Vector2(s * 0.28, s * 0.64)), col, false, w)
				for side in [-1.0, 1.0]:
					var x0: float = 0.5 + side * 0.24
					var x1: float = 0.5 + side * 0.34
					draw_polyline(PackedVector2Array([_p(x0, 0.3), _p(x1, 0.4), _p(x0, 0.5),
						_p(x1, 0.6), _p(x0, 0.7)]), acc, w, true)
			"person":
				draw_arc(_p(0.5, 0.5), s * 0.42, 0.0, TAU, 32, col, w, true)
				draw_circle(_p(0.5, 0.28), s * 0.07, acc)
				draw_line(_p(0.28, 0.42), _p(0.72, 0.42), acc, w)
				draw_line(_p(0.5, 0.42), _p(0.5, 0.6), acc, w)
				draw_line(_p(0.5, 0.6), _p(0.38, 0.78), acc, w)
				draw_line(_p(0.5, 0.6), _p(0.62, 0.78), acc, w)
			"zoom":
				draw_arc(_p(0.42, 0.42), s * 0.24, 0.0, TAU, 28, col, w, true)
				draw_line(_p(0.6, 0.6), _p(0.84, 0.84), col, w * 1.6)
				draw_line(_p(0.3, 0.42), _p(0.54, 0.42), acc, w)
				draw_line(_p(0.42, 0.3), _p(0.42, 0.54), acc, w)
			"undo":
				# A hooked arrow turning back on itself.
				draw_arc(_p(0.52, 0.56), s * 0.24, -PI * 0.95, PI * 0.55, 24, col, w * 1.4, true)
				var tip: Vector2 = _p(0.52, 0.56) + Vector2(cos(-PI * 0.95), sin(-PI * 0.95)) * s * 0.24
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.13, 0.0),
					tip + Vector2(s * 0.1, -s * 0.14), tip + Vector2(s * 0.1, s * 0.12)]), col)
			"bin":
				var red := Palette.BAD
				draw_line(_p(0.22, 0.26), _p(0.78, 0.26), red, w * 1.3)
				draw_line(_p(0.42, 0.18), _p(0.58, 0.18), red, w * 1.3)
				draw_colored_polygon(PackedVector2Array([_p(0.28, 0.32), _p(0.72, 0.32),
					_p(0.66, 0.84), _p(0.34, 0.84)]), Color(red, 0.25))
				draw_polyline(PackedVector2Array([_p(0.28, 0.32), _p(0.34, 0.84), _p(0.66, 0.84),
					_p(0.72, 0.32)]), red, w, true)
				for x in [0.42, 0.5, 0.58]:
					draw_line(_p(x, 0.42), _p(x, 0.74), red, w * 0.8)
			"text":
				# A big letter and a small one: the size of the words.
				var f: Font = get_theme_default_font()
				draw_string(f, _p(0.1, 0.8), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.66), col)
				draw_string(f, _p(0.58, 0.8), "a", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s * 0.4), acc)
			"up", "down":
				# A stratum's verdict on a machine: a round badge with an
				# arrow, up in green or down in red -- the shape says it too.
				var good: bool = kind == "up"
				var c: Color = Palette.GOOD if good else Palette.BAD
				# A ring as two discs, not an arc: a tray can show eight of these,
				# and plain polygons batch where an antialiased arc does not.
				draw_circle(_p(0.5, 0.5), s * 0.49, c)
				draw_circle(_p(0.5, 0.5), s * 0.49 - w, Color(Palette.BG, 0.95))
				var tri: PackedVector2Array = PackedVector2Array([_p(0.5, 0.2), _p(0.8, 0.64),
					_p(0.2, 0.64)]) if good else PackedVector2Array([_p(0.5, 0.8), _p(0.8, 0.36),
					_p(0.2, 0.36)])
				draw_colored_polygon(tri, c)
			"motion":
				draw_circle(_p(0.66, 0.5), s * 0.16, acc)
				for k in range(3):
					var y: float = 0.36 + 0.14 * float(k)
					draw_line(_p(0.14, y), _p(0.44, y), Color(col, 0.5 + 0.25 * float(k % 2)), w)


## A bar that fills to `value` (0..1), with a notch at `target` when there is
## one -- where a machine's temperature wants to be.
class Gauge extends Control:
	var value: float = 0.0
	var target: float = -1.0
	var fill := Color.WHITE

	func _init(w: float, h: float) -> void:
		custom_minimum_size = Vector2(w, h)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(Palette.BG, 0.85), true)
		var f := Rect2(r.position, Vector2(r.size.x * clampf(value, 0.0, 1.0), r.size.y))
		draw_rect(f, fill, true)
		draw_rect(r, Color(1, 1, 1, 0.18), false, 1.5)
		if target >= 0.0:
			var x: float = r.size.x * clampf(target, 0.0, 1.0)
			draw_line(Vector2(x, -3.0), Vector2(x, r.size.y + 3.0), Palette.TEXT, 3.0)


## A gem shape: a lit diamond on a dark one.
static func gem(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0),
		c + Vector2(0, r), c + Vector2(-r, 0)]), col.darkened(0.45))
	var k: float = r * 0.72
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k, 0),
		c + Vector2(0, k), c + Vector2(-k, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k * 0.5, -k * 0.5),
		c + Vector2(0, 0), c + Vector2(-k * 0.5, -k * 0.5)]), col.lightened(0.35))


## What a machine turns into what, as gems and an arrow: its inputs, an
## arrow, its outputs. A Vault turns anything into credits; a machine with
## no recipe (it works on its neighbours) shows the energy sign.
static func recipe(id: String, px: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m: Dictionary = MachineDB.get_machine(id)
	var ins: Dictionary = m.get("inputs", {})
	var outs: Dictionary = m.get("outputs", {})
	var sink: bool = (m.get("tags", []) as Array).has("sink")
	for res: int in ins:
		row.add_child(Gem.new(res, int(ins[res]), px))
	if sink:
		for res in MachineDB.Res.values():
			row.add_child(Gem.new(int(res), 1, px * 0.62))
	if not ins.is_empty() or sink or not outs.is_empty():
		row.add_child(Arrow.new(px))
	for res: int in outs:
		row.add_child(Gem.new(res, int(outs[res]), px))
	if sink:
		row.add_child(_icon("credits", px * 1.1))
	if ins.is_empty() and outs.is_empty() and not sink:
		row.add_child(_icon("energy", px * 1.1))
	return _centred(row)


## What goes in, the machine, and what comes out, left to right: "gravel
## goes into a Smelter and ingots come out". A machine with no recipe shows
## what it does to its neighbours instead -- heat, cold, speed, a double.
static func flow(id: String, px: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m: Dictionary = MachineDB.get_machine(id)
	var ins: Dictionary = m.get("inputs", {})
	var outs: Dictionary = m.get("outputs", {})
	var tags: Array = m.get("tags", [])
	if tags.has("sink"):
		for res in MachineDB.Res.values():
			row.add_child(Gem.new(int(res), 1, px * 0.42))
		row.add_child(Arrow.new(px * 0.8))
	elif not ins.is_empty():
		for res: int in ins:
			row.add_child(Gem.new(res, int(ins[res]), px))
		row.add_child(Arrow.new(px * 0.8))
	row.add_child(MachineSprite.new(id, px * 1.6))
	row.add_child(Arrow.new(px * 0.8))
	for res: int in outs:
		row.add_child(Gem.new(res, int(outs[res]), px))
	if tags.has("sink"):
		row.add_child(_icon("credits", px * 1.1))
	if tags.has("research"):
		row.add_child(_icon("research", px * 1.1))
	if tags.has("heat"):
		row.add_child(_icon("heat", px * 1.1))
	if tags.has("cool"):
		row.add_child(_icon("cold", px * 1.1))
	if tags.has("amplify"):
		row.add_child(_icon("energy", px * 1.1))
	if tags.has("duplicate"):
		var x2 := Label.new()
		x2.text = "x2"
		x2.add_theme_font_size_override("font_size", int(px * 0.8))
		x2.add_theme_color_override("font_color", Palette.CORE)
		x2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(x2)
	return _centred(row)


## Each picture at its own size, centred on the row: a gem draws to its
## height, so one stretched to a tall neighbour would fill the card.
static func _centred(row: HBoxContainer) -> HBoxContainer:
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for c in row.get_children():
		(c as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return row


static func _icon(name: String, px: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = IsoArt.icon(name)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(px, px)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


## A Control that draws one machine exactly as the board draws it: the same
## sprite from the same sheet, so what you pick is what you get.
class MachineSprite extends Control:
	var id: String = ""
	var bob: bool = false
	var _t: float = 0.0

	func _init(machine_id: String = "", px: float = 64.0, animate: bool = false) -> void:
		id = machine_id
		bob = animate
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _process(delta: float) -> void:
		if bob:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		if id == "" or size.x < 4.0:
			return
		var sheet: Dictionary = IsoArt.sheet(IsoArt.sheet_name(Store.active_theme(),
			Sim.upgrade_marks()))
		var r := Rect2(Vector2.ZERO, size)
		if bob:
			# A pool of its own light behind it, so it arrives lit.
			var g: Color = Palette.machine_light(id)
			g.a = 0.35 + 0.1 * sin(_t * 3.0)
			draw_texture_rect(IsoArt.glow(), r.grow(-size.x * 0.05), false, g)
			r.position.y += sin(_t * 2.0) * size.y * 0.015
		IsoArt.draw_machine_fit(self, r, id, sheet)
