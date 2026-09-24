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
	return row


static func _icon(name: String, px: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = IsoArt.icon(name)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(px, px)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic
