extends Control

## Draws one piece of store artwork. Driven by tools/brand.gd.
##
## The icon and the feature graphic use `MachineArt`, which is the same code
## that draws the board. That is deliberate and it is the only way a solo
## project keeps its marketing art honest: there is no separate set of
## promotional assets that can drift away from what the game looks like,
## because there is no separate set of promotional assets.

## The machines on the icon. Three tiles of a real chain — a drill feeding a
## crusher feeding a vault — because that is the game's first minute and the
## thing the icon is promising.
const ICON_CHAIN := ["drill", "crusher", "vault"]

var kind: String = "icon"


## A shaft to stand the machines in: cool stone at the top, heat rising from
## below, and a scatter of minerals in the rock.
##
## Built from `Palette.shaft()` -- the same four-band description the board
## uses to decide what stratum nine looks like -- so the store page shows the
## place the game is actually set rather than a gradient chosen to look nice.
func _shaft(s: Vector2, depth: int, heat: float) -> void:
	var sh: Dictionary = Palette.shaft(depth)
	var rock: Color = sh["rock"]
	draw_rect(Rect2(Vector2.ZERO, s), rock.darkened(0.55), true)
	# Vertical light: brighter towards the top where the shaft is open.
	var bands: int = 26
	for i in range(bands):
		var t: float = float(i) / float(bands)
		var c: Color = rock.lerp(Palette.KEY_TINT, 0.10 * (1.0 - t))
		c.a = 0.55 * (1.0 - t)
		draw_rect(Rect2(0.0, s.y * t * 0.75, s.x, s.y / float(bands) + 1.0),
			c, true)
	# Heat banked into the bottom: the game is underground and it is hot.
	# Divided by the band count: these stack, and the first version summed to
	# an opaque orange sheet that buried the rock it was meant to sit in.
	for i in range(bands):
		var t: float = float(i) / float(bands)
		var c: Color = Palette.HEAT_HOT.lerp(Palette.HEAT_WARM, t)
		c.a = heat * (1.0 - t) * 6.0 / float(bands)
		var h: float = s.y * (1.0 - t) * 0.8
		draw_rect(Rect2(0.0, s.y - h, s.x, h), c, true)
	# Minerals, on a fixed seed so the store art is identical every build.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260923
	for i in range(34):
		var p := Vector2(rng.randf() * s.x, rng.randf() * s.y)
		var sz: float = s.y * (0.006 + rng.randf() * 0.012)
		var col: Color = sh["fleck"] if rng.randf() > 0.25 else sh["vein"]
		col.a = 0.25 + rng.randf() * 0.45
		draw_rect(Rect2(p, Vector2(sz, sz)), col, true)
	for i in range(5):
		var p2 := Vector2(rng.randf() * s.x, rng.randf() * s.y)
		Palette.emissive(self, Rect2(p2, Vector2(s.y * 0.016, s.y * 0.014)),
			sh["vein"], 0.5)


func _draw() -> void:
	match kind:
		"icon": _draw_icon(size, true)
		"adaptive": _draw_icon(size, false)
		"feature": _draw_feature(size)


## The icon.
##
## At 48dp in a search grid there is room for one idea, and the one chosen
## here is the game's actual subject: three machines touching, with heat
## between them. No wordmark — text at 48dp is a smear — and no rounded
## corners, because Play masks the icon to a 30% radius and adds its own
## shadow. An icon that rounds itself is double-rounded and reads as inset and
## small, which is exactly where it cannot afford to lose.
func _draw_icon(s: Vector2, opaque: bool) -> void:
	var font: Font = ThemeDB.fallback_font
	if opaque:
		_shaft(s, 14, 0.42)

	# Three tiles and nothing else.
	#
	# The first version of this icon put the chain inside a 3x3 block of rock,
	# which is truer to the board and unreadable at 48dp -- the rock rows went
	# black and the icon became a band. At the size where an icon has to win,
	# there is room for one idea, so the idea is the three machines and the
	# material passing between them.
	var inset: float = 0.08 if opaque else 0.20
	var pad: float = s.x * inset
	var cell: float = (s.x - pad * 2.0) / 3.0
	var y: float = (s.y - cell) * 0.5
	var heats: Array = [0.5, 1.4, 0.7]
	for i in range(3):
		MachineArt.tile(self, Rect2(pad + cell * float(i), y,
			cell * 0.93, cell * 0.93), String(ICON_CHAIN[i]), font,
			float(heats[i]))
	# The handoff, because "they feed each other" is the whole game.
	for i in range(2):
		var m: float = cell * 0.16
		draw_rect(Rect2(pad + cell * (float(i) + 0.88), y + cell * 0.40, m, m),
			Palette.res_color(i), true)


## The feature graphic.
##
## For games this is the primary visual in Play's search results and
## recommendation rows, so it carries the name and the one sentence that says
## what the game is — at a size where a screenshot would be unreadable.
func _draw_feature(s: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, s), Palette.BG, true)

	_shaft(s, 16, 0.30)

	# Words on the left, board on the right, and the two do not touch. The
	# first draft let a five-tile row run under the tagline and neither was
	# readable; at 1024x500 there is room for one column of text and one
	# column of picture.
	var split: float = s.x * 0.55
	var left: float = s.x * 0.045

	var chain: Array = ["drill", "crusher", "smelter", "vault"]
	var heats: Array = [0.4, 1.2, 3.2, 0.8]
	var cell: float = (s.x - split - s.x * 0.03) / float(chain.size())
	var y0: float = (s.y - cell) * 0.5
	for i in range(chain.size()):
		MachineArt.tile(self, Rect2(split + cell * float(i), y0,
			cell * 0.93, cell * 0.93), String(chain[i]), font, float(heats[i]))
	for i in range(chain.size() - 1):
		var m: float = cell * 0.14
		draw_rect(Rect2(split + cell * (float(i) + 0.87), y0 + cell * 0.40,
			m, m), Palette.res_color(i), true)

	var title := "LODEWORKS"
	var ts: int = int(s.y * 0.155)
	var tsz: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts)
	draw_string(font, Vector2(left, s.y * 0.33), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Palette.TEXT)
	# The resource ramp as a rule under the title: five colours, five tiers,
	# and the only place the game's progression appears as a graphic.
	var seg: float = tsz.x / 5.0
	for i in range(5):
		draw_rect(Rect2(left + float(i) * seg, s.y * 0.375, seg - 3.0, 5.0),
			Palette.res_color(i), true)

	var ls: int = int(s.y * 0.058)
	draw_string(font, Vector2(left, s.y * 0.55),
		"Machines feed whatever they touch.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, ls, Palette.ACCENT)
	draw_string(font, Vector2(left, s.y * 0.67),
		"Heat decides whether that helps.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, ls, Palette.WARN)
	draw_string(font, Vector2(left, s.y * 0.87),
		"Idle factory puzzle  ·  plays offline  ·  no interstitials",
		HORIZONTAL_ALIGNMENT_LEFT, -1, int(s.y * 0.045), Palette.TEXT_FAINT)
