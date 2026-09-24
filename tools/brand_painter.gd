extends Control

## Draws one piece of store artwork. Driven by tools/brand.gd.
##
## Everything here is drawn from the game's own pictures: the world painting,
## the Factory Core and the machine sheet the board uses. There is no separate
## set of promotional art that could drift away from what the game looks like.
## (Until 25 September 2026 the icon was drawn with `MachineArt`, the
## rectangle machines the board had before its art; the game stopped using
## them and the icon kept showing them.)

var kind: String = "icon"


func _draw() -> void:
	match kind:
		"icon": _draw_icon(size, true)
		"adaptive": _draw_icon(size, false)
		"feature": _draw_feature(size)


## The world painting, cropped to cover `s` around its canyon, darkened a
## little so what stands on it reads.
func _world(s: Vector2, dark: float) -> void:
	var info: Dictionary = IsoArt.layout().get("world", {})
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	if tex == null:
		draw_rect(Rect2(Vector2.ZERO, s), Palette.BG, true)
		return
	var full: Vector2 = tex.get_size()
	var a: Array = info.get("anchor", [full.x * 0.5, full.y * 0.5])
	# The widest crop of the painting with the target's shape, around its
	# anchor, at 60% of the painting's height so the canyon fills it.
	var h: float = full.y * 0.6
	var w: float = h * s.x / s.y
	if w > full.x:
		w = full.x
		h = w * s.y / s.x
	var src := Rect2(clampf(float(a[0]) - w * 0.5, 0.0, full.x - w),
		clampf(float(a[1]) - h * 0.55, 0.0, full.y - h), w, h)
	draw_texture_rect_region(tex, Rect2(Vector2.ZERO, s), src,
		Color(1.0 - dark, 1.0 - dark * 1.05, 1.0 - dark * 1.1))


## The Factory Core, standing with its base centre at `foot`, `h` tall.
func _core(foot: Vector2, h: float) -> void:
	var info: Dictionary = IsoArt.layout().get("core", {})
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	if tex == null:
		return
	var region: Rect2 = IsoArt.region(info, 0)
	var k: float = h / region.size.y
	var anchor: Vector2 = IsoArt.anchor(info)
	var at: Vector2 = foot - anchor * k
	draw_texture_rect_region(tex, Rect2(at, region.size * k), region)


## A soft pool of light: the glow texture the board's lamps use.
func _glow(c: Vector2, r: float, col: Color) -> void:
	draw_texture_rect(IsoArt.glow(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


## A machine standing on the ground at `foot`, `w` wide.
func _machine(id: String, foot: Vector2, w: float) -> void:
	var sheet: Dictionary = IsoArt.sheet(IsoArt.sheet_name(Palette.theme(), 0))
	IsoArt.draw_machine_fit(self, Rect2(foot - Vector2(w * 0.5, w * 1.05), Vector2(w, w * 1.1)),
		id, sheet)


## The icon.
##
## At 48dp in a search grid there is room for one idea: the Factory Core,
## lit, with its first two machines at its feet -- the game's first minute.
## No wordmark, since text at 48dp is a smear, and no rounded corners,
## because Play masks the icon itself and one that rounds itself is
## double-rounded.
func _draw_icon(s: Vector2, opaque: bool) -> void:
	if opaque:
		_world(s, 0.45)
		# A dark rim so the icon holds its edge on a light home screen.
		for i in range(10):
			var t: float = float(i) / 10.0
			draw_rect(Rect2(Vector2.ONE * s.x * 0.03 * t, s - Vector2.ONE * s.x * 0.06 * t),
				Color(0, 0, 0, 0.05), false, s.x * 0.03)
	# The adaptive foreground keeps to the middle 60%, which every launcher
	# mask leaves visible.
	var k: float = 1.0 if opaque else 0.66
	var c := Vector2(s.x * 0.5, s.y * 0.5)
	_glow(c + Vector2(0, -s.y * 0.04 * k), s.x * 0.5 * k, Color(0.35, 0.8, 1.0, 0.55))
	_core(c + Vector2(0, s.y * 0.25 * k), s.y * 0.76 * k)
	_machine("drill", c + Vector2(-s.x * 0.32 * k, s.y * 0.40 * k), s.x * 0.29 * k)
	_machine("vault", c + Vector2(s.x * 0.32 * k, s.y * 0.40 * k), s.x * 0.29 * k)


## The feature graphic.
##
## For games this is the primary visual in Play's search results and
## recommendation rows, so it carries the name and one plain sentence of
## what the game is, at a size where a screenshot would be unreadable: words
## on the left, the Core and its first machines on the right.
func _draw_feature(s: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font
	_world(s, 0.15)
	# Darker behind the words.
	for i in range(24):
		var t: float = float(i) / 24.0
		draw_rect(Rect2(0.0, 0.0, s.x * (0.62 - 0.62 * t), s.y), Color(0.03, 0.03, 0.06, 0.045), true)

	# The Core, lit, with a line of machines at its feet.
	var core_foot := Vector2(s.x * 0.78, s.y * 0.76)
	_glow(core_foot + Vector2(0, -s.y * 0.34), s.y * 0.48, Color(0.35, 0.8, 1.0, 0.5))
	_core(core_foot, s.y * 0.74)
	var line: Array = [["drill", -0.165, 0.9], ["crusher", -0.09, 1.0], ["smelter", 0.09, 1.0],
		["vault", 0.165, 0.9]]
	for m: Array in line:
		_machine(String(m[0]), core_foot + Vector2(s.x * float(m[1]), s.y * 0.15 * float(m[2])),
			s.y * 0.22)

	var left: float = s.x * 0.05
	var title := "LODEWORKS"
	var ts: int = int(s.y * 0.15)
	var tsz: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts)
	draw_string_outline(font, Vector2(left, s.y * 0.33), title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts,
		int(s.y * 0.02), Color(0.05, 0.03, 0.02))
	draw_string(font, Vector2(left, s.y * 0.33), title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Palette.CORE)
	# The resource ramp as a rule under the title: five colours, five tiers.
	var seg: float = tsz.x / 5.0
	for i in range(5):
		draw_rect(Rect2(left + float(i) * seg, s.y * 0.375, seg - 3.0, 6.0),
			Palette.res_color(i), true)
	var ls: int = int(s.y * 0.062)
	for l: Array in [["Build a factory deep underground.", 0.54, Palette.TEXT],
			["Machines feed whatever they touch.", 0.66, Palette.ACCENT]]:
		draw_string_outline(font, Vector2(left, s.y * float(l[1])), String(l[0]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, ls, 6, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(left, s.y * float(l[1])), String(l[0]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, ls, l[2])
	draw_string_outline(font, Vector2(left, s.y * 0.88),
		"Idle factory puzzle  ·  plays offline  ·  no interstitials",
		HORIZONTAL_ALIGNMENT_LEFT, -1, int(s.y * 0.042), 5, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2(left, s.y * 0.88),
		"Idle factory puzzle  ·  plays offline  ·  no interstitials",
		HORIZONTAL_ALIGNMENT_LEFT, -1, int(s.y * 0.042), Palette.TEXT_DIM)
