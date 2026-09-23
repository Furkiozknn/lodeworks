class_name IsoArt
extends RefCounted

## Everything the board draws that is a picture rather than a shape.
##
## The numbers that place those pictures -- where a machine's base plate is in
## its atlas, where the island's flat top is, how big a tile is -- live in
## `assets/art/layout.json`, which `tools/art_build.py` writes from the images
## themselves. Nothing here is typed in by eye, so regenerating a sheet
## re-measures it instead of silently misaligning it.
##
## The palette a player bought and the upgrade tier they have reached choose
## the machine atlas. That is the whole of what a purchase changes on the
## board: a picture. `Themes` explains why it can never be more.

const LAYOUT_PATH := "res://assets/art/layout.json"

## At or above this many upgrade notches the machines are drawn from the
## gilded "top tier" sheet. Below it they wear notches on their plates.
const UP_SHEET_MARKS := 3

static var _layout: Dictionary = {}
static var _tex: Dictionary = {}


static func layout() -> Dictionary:
	if _layout.is_empty():
		var f := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_layout = parsed
	return _layout


static func texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


## The sheet for a palette and an upgrade tier, falling back to the free
## palette and then to the plain tier. A sheet that has not been generated
## yet is a picture that is missing, never a crash.
static func sheet_name(theme_id: String, marks: int) -> String:
	var sheets: Dictionary = layout().get("machines", {}).get("sheets", {})
	var want: Array[String] = []
	if marks >= UP_SHEET_MARKS:
		want.append(theme_id + "_up")
	want.append(theme_id)
	if marks >= UP_SHEET_MARKS:
		want.append(Themes.DEFAULT + "_up")
	want.append(Themes.DEFAULT)
	for n: String in want:
		if sheets.has(n):
			return n
	return ""


static func sheet(name: String) -> Dictionary:
	return layout().get("machines", {}).get("sheets", {}).get(name, {})


## Where machine `id` is in its atlas, and where on that rectangle the centre
## of its base plate falls.
static func machine_region(sheet_info: Dictionary, id: String) -> Rect2:
	var order: Array = layout().get("machines", {}).get("order", [])
	var k: int = order.find(id)
	if k < 0 or sheet_info.is_empty():
		return Rect2()
	return region(sheet_info, k)


## Cell `k` of a sheet laid out `cols` wide.
static func region(sheet_info: Dictionary, k: int) -> Rect2:
	var cell: Array = sheet_info.get("cell", [0, 0])
	var cols: int = int(sheet_info.get("cols", 4))
	return Rect2(float(k % cols) * float(cell[0]), float(k / cols) * float(cell[1]),
		float(cell[0]), float(cell[1]))


static func anchor(sheet_info: Dictionary) -> Vector2:
	var a: Array = sheet_info.get("anchor", [0, 0])
	return Vector2(float(a[0]), float(a[1]))


static func base_px(sheet_info: Dictionary) -> float:
	return float(sheet_info.get("base_px", 224))


## The floor atlas: which of its eight slabs a board cell uses. Mostly plain,
## an inlay now and then, from a hash of the cell and the stratum so the floor
## is the same floor every time you look at it.
static func tile_variant(cell: int, depth: int) -> int:
	var h: int = hash("floor-%d-%d" % [cell, depth]) & 0xffff
	if h % 11 == 0:
		return 4 + (h / 11) % 4
	return h % 4


static func tile_uv(variant: int) -> Rect2:
	var t: Dictionary = layout().get("tiles", {})
	var cols: int = int(t.get("cols", 4))
	var rows: int = int(t.get("rows", 2))
	return Rect2(float(variant % cols) / float(cols),
		float(variant / cols) / float(rows), 1.0 / float(cols),
		1.0 / float(rows))


static func placement() -> Dictionary:
	return layout().get("placement", {})


## A soft round light, made once in code. Glows, pools of light on the
## floor and steam are all this one texture tinted and scaled.
static var _glow: Texture2D = null

static func glow() -> Texture2D:
	if _glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.35))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_glow = t
	return _glow


## One of the sixteen HUD icons, by name (see layout.json "icons").
static var _icons: Dictionary = {}

static func icon(name: String) -> Texture2D:
	if _icons.has(name):
		return _icons[name]
	var info: Dictionary = layout().get("icons", {})
	var tex: Texture2D = texture(String(info.get("file", "")))
	var k: int = (info.get("order", []) as Array).find(name)
	if tex == null or k < 0:
		_icons[name] = null
		return null
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = region(info, k)
	_icons[name] = a
	return a


## A machine drawn to fit a rectangle, plate on the bottom, for the tray,
## the unlock card and the shop -- the same picture the board uses, so what
## the player picks is what appears.
static func draw_machine_fit(ci: CanvasItem, rect: Rect2, id: String,
		sheet_info: Dictionary, mod: Color = Color.WHITE) -> void:
	var tex: Texture2D = texture(String(sheet_info.get("file", "")))
	var r: Rect2 = machine_region(sheet_info, id)
	if tex == null or r.size.x <= 0.0:
		return
	var s: float = minf(rect.size.x / r.size.x, rect.size.y / r.size.y)
	var sz: Vector2 = r.size * s
	ci.draw_texture_rect_region(tex, Rect2(rect.position + (rect.size - sz) * 0.5, sz),
		r, mod)
