class_name MachineArt
extends RefCounted

## How a machine is drawn, in one place, so that everything that draws one
## draws the same one.
##
## The board, the palette buttons, the Codex, the shop swatches, the app icon,
## the feature graphic and the store screenshots all call this. That is the
## whole asset pipeline: a new machine gets a row in `MachineDB`, a colour, a
## light and a build here, and every surface that shows machines picks it up
## without anyone exporting, resizing or re-cutting anything. It is also why
## the marketing art cannot drift away from the game -- there is no separate
## marketing art.
##
## ---------------------------------------------------------------------------
## WHY THIS IS STILL RECTANGLES
## ---------------------------------------------------------------------------
##
## Every machine below is built from `Palette.block()`, which is six
## `draw_rect` calls arranged as the side, front and top faces of a solid plus
## a rim light and a contact shadow. Stacked three or four deep with an
## emissive core on top, that reads as a lit three-dimensional object -- and it
## batches, scales to any screen density, weighs nothing, and cannot drift out
## of sync with the twelve rows in `MachineDB` the way a folder of exported
## sprites can.
##
## The alternative was a sprite sheet: twelve machines times four heat states
## times four upgrade tiers is a hundred and ninety-two images that have to
## agree with each other about where the light is. They never do.
##
## ---------------------------------------------------------------------------
## THE LANGUAGE
## ---------------------------------------------------------------------------
##
## Each machine is built from the same four parts, so that twelve machines
## look like one factory rather than twelve art styles:
##
##   PLINTH   a dark foot. Everything sits on the tile rather than floating.
##   MASS     one or two body blocks in the machine's own metal colour.
##   MARK     the part that says what the machine DOES -- a bit, a ram, a
##            chimney, a fin, a tube. This is the silhouette, and it is what
##            has to be distinguishable in greyscale at forty pixels.
##   LIGHT    an emissive core in the machine's light colour. From across the
##            board this is the only thing you can see, so it is also an
##            identifier: molten orange is a Smelter, ice blue is a Coolant
##            Cell, violet is a Lab.
##
## Upgrades add MASS and MARK, never just brightness, so a levelled machine is
## visibly a bigger machine. Heat changes LIGHT, never the body colour, so a
## hot Smelter still looks like a Smelter.

## How much of the tile a machine occupies. The remainder is the platform it
## stands on, which is what gives the board its grid.
const FOOT := 0.80


## One sub-block, positioned in fractions of the machine's own rect. Keeping
## the compositions in normalised coordinates is what lets the same build
## describe a forty-pixel tile and a five-hundred-pixel feature graphic.
static func _b(ci: CanvasItem, r: Rect2, x: float, y: float, w: float,
		h: float, col: Color, lift: float = 0.14, rim: bool = true,
		contact: bool = false) -> void:
	var rr := Rect2(r.position.x + r.size.x * x, r.position.y + r.size.y * y,
		maxf(r.size.x * w, 1.0), maxf(r.size.y * h, 1.0))
	Palette.block(ci, rr, col, lift, rim, contact)


## One emissive element, in the same normalised coordinates.
static func _e(ci: CanvasItem, r: Rect2, x: float, y: float, w: float,
		h: float, col: Color, strength: float) -> void:
	var rr := Rect2(r.position.x + r.size.x * x, r.position.y + r.size.y * y,
		maxf(r.size.x * w, 1.0), maxf(r.size.y * h, 1.0))
	Palette.emissive(ci, rr, col, strength)


## Draw the machine body. `scale_ref` is the size the proportions are relative
## to. `opts` carries the live state the board knows and a still image does
## not: `tier` 0-3 upgrade notches, `phase` 0-1 animation, `running`,
## `glow` 0-2 how hard the core is lit, `cold` for thermal-blue tinting.
static func build(ci: CanvasItem, rect: Rect2, scale_ref: float, id: String,
		opts: Dictionary = {}) -> void:
	var body: Color = Palette.machine_color(id)
	var light: Color = Palette.machine_light(id)
	var tier: int = int(opts.get("tier", 0))
	var phase: float = float(opts.get("phase", 0.0))
	var running: bool = bool(opts.get("running", false))
	var glow: float = float(opts.get("glow", 1.0))
	var cold: bool = bool(opts.get("cold", false))
	if cold:
		light = light.lerp(Palette.ST_COLD, 0.6)
	var r: Rect2 = rect
	var dark: Color = body.lerp(Palette.BG, 0.42)
	var trim: Color = body.lerp(Palette.CORE, 0.30)
	# A running machine breathes; an idle one is still. The amplitude is tiny
	# on purpose -- seventy tiles bouncing is a screensaver, not a factory.
	var beat: float = (sin(phase * TAU) * 0.5 + 0.5) if running else 0.0

	match id:
		"drill":
			# A rig: wide foot, mast, and a bit that goes DOWN into the rock.
			_b(ci, r, 0.10, 0.62, 0.80, 0.30, dark, 0.10, true, true)
			_b(ci, r, 0.30, 0.16, 0.40, 0.52, body)
			if tier >= 1:
				_b(ci, r, 0.06, 0.34, 0.16, 0.30, dark, 0.10)   # side motor
			if tier >= 2:
				_b(ci, r, 0.78, 0.34, 0.16, 0.30, dark, 0.10)
			# The bit, which strokes downward as it works.
			var bit: float = 0.66 + beat * 0.10
			_b(ci, r, 0.42, bit, 0.16, 0.26, trim, 0.06)
			_e(ci, r, 0.38, 0.24, 0.24, 0.10, light, glow)
			if tier >= 3:
				_e(ci, r, 0.38, 0.40, 0.24, 0.06, light, glow * 0.8)
		"crusher":
			# A mill: a drum with toothed rollers biting across the top.
			_b(ci, r, 0.08, 0.30, 0.84, 0.62, body, 0.16, true, true)
			_b(ci, r, 0.14, 0.14, 0.72, 0.22, dark, 0.12)
			var teeth: int = 3 + tier
			for i in range(teeth):
				var tx: float = 0.18 + float(i) * (0.64 / float(maxi(teeth, 1)))
				var bob: float = 0.14 + (beat * 0.03 if i % 2 == 0 else -beat * 0.03)
				_b(ci, r, tx, bob, 0.08, 0.14, trim, 0.05, false)
			_e(ci, r, 0.20, 0.52, 0.60, 0.12, light, glow)
		"vault":
			# A sink: an armoured strongbox. Double wall, slot, lock.
			_b(ci, r, 0.08, 0.16, 0.84, 0.76, body, 0.15, true, true)
			_b(ci, r, 0.18, 0.26, 0.64, 0.56, dark, 0.08)
			_e(ci, r, 0.30, 0.36, 0.40, 0.09, light, glow)
			_b(ci, r, 0.42, 0.56, 0.16, 0.16, trim, 0.06, false)
			if tier >= 2:
				_b(ci, r, 0.08, 0.08, 0.84, 0.08, trim, 0.05, false)
		"smelter":
			# A furnace: wide arched mouth full of molten metal, stack aside.
			_b(ci, r, 0.08, 0.30, 0.84, 0.62, body, 0.16, true, true)
			_b(ci, r, 0.62, 0.04, 0.24, 0.30, dark, 0.10)      # chimney
			if tier >= 2:
				_b(ci, r, 0.14, 0.08, 0.18, 0.26, dark, 0.08)
			_e(ci, r, 0.18, 0.46, 0.44, 0.26, light, glow * (0.75 + beat * 0.45))
			_b(ci, r, 0.14, 0.74, 0.56, 0.08, trim, 0.05, false)
		"boiler":
			# Pure heat: a banded pressure tank, a tall stack, a valve.
			_b(ci, r, 0.06, 0.34, 0.88, 0.56, body, 0.18, true, true)
			for i in range(2 + tier):
				_b(ci, r, 0.16 + float(i) * 0.22, 0.34, 0.05, 0.56, dark, 0.0, false)
			_b(ci, r, 0.56, 0.02, 0.26, 0.34, dark, 0.12)
			_e(ci, r, 0.12, 0.58, 0.34, 0.16, light, glow * (0.7 + beat * 0.5))
			_e(ci, r, 0.60, 0.02, 0.18, 0.06, light, glow * 0.5 * (0.4 + beat))
		"coolant":
			# The opposite: a finned column with a frost cap.
			_b(ci, r, 0.22, 0.22, 0.56, 0.70, body, 0.16, true, true)
			for i in range(3 + tier):
				var fy: float = 0.30 + float(i) * (0.52 / float(3 + tier))
				_b(ci, r, 0.06, fy, 0.88, 0.05, dark, 0.0, false)
			_b(ci, r, 0.28, 0.08, 0.44, 0.16, trim, 0.10)
			_e(ci, r, 0.34, 0.40, 0.32, 0.30, light, glow * 1.1)
		"press":
			# A frame with a ram that visibly comes down.
			_b(ci, r, 0.08, 0.72, 0.84, 0.20, dark, 0.10, true, true)   # anvil
			_b(ci, r, 0.08, 0.08, 0.14, 0.66, body, 0.10)               # uprights
			_b(ci, r, 0.78, 0.08, 0.14, 0.66, body, 0.10)
			_b(ci, r, 0.08, 0.04, 0.84, 0.14, body, 0.12)               # crown
			var ram: float = 0.26 + beat * 0.26
			_b(ci, r, 0.24, ram, 0.52, 0.22, trim, 0.10)
			_e(ci, r, 0.24, 0.66, 0.52, 0.07, light, glow * (0.4 + beat * 0.8))
			if tier >= 2:
				_b(ci, r, 0.30, 0.04, 0.40, 0.06, trim, 0.04, false)
		"assembler":
			# Stepped tiers with a component window and a small arm.
			_b(ci, r, 0.08, 0.54, 0.84, 0.38, body, 0.16, true, true)
			_b(ci, r, 0.16, 0.30, 0.68, 0.26, body, 0.12)
			_b(ci, r, 0.26, 0.12, 0.48, 0.20, dark, 0.10)
			var arm: float = 0.30 + beat * 0.16
			_b(ci, r, arm, 0.06, 0.12, 0.10, trim, 0.05, false)
			_e(ci, r, 0.24, 0.62, 0.52, 0.16, light, glow)
			if tier >= 1:
				_e(ci, r, 0.34, 0.36, 0.32, 0.08, light, glow * 0.7)
			if tier >= 3:
				_b(ci, r, 0.08, 0.46, 0.84, 0.06, trim, 0.04, false)
		"amplifier":
			# A pylon between two dishes. It reaches outwards, so it is wide.
			_b(ci, r, 0.36, 0.18, 0.28, 0.74, body, 0.16, true, true)
			var reach: float = 0.06 - beat * 0.02
			_b(ci, r, reach, 0.34, 0.24, 0.34, dark, 0.12)
			_b(ci, r, 0.94 - 0.24 - reach, 0.34, 0.24, 0.34, dark, 0.12)
			_e(ci, r, 0.38, 0.30, 0.24, 0.24, light, glow * (0.8 + beat * 0.6))
			_e(ci, r, reach + 0.05, 0.44, 0.14, 0.12, light, glow * 0.55)
			_e(ci, r, 0.95 - 0.19 - reach, 0.44, 0.14, 0.12, light, glow * 0.55)
			if tier >= 2:
				_b(ci, r, 0.30, 0.06, 0.40, 0.12, trim, 0.08)
		"lab":
			# A narrow tower with a glass section and a crystal inside it.
			_b(ci, r, 0.10, 0.76, 0.80, 0.16, dark, 0.08, true, true)
			_b(ci, r, 0.26, 0.10, 0.48, 0.68, body, 0.14)
			_e(ci, r, 0.34, 0.26, 0.32, 0.34, light, glow * (0.7 + beat * 0.5))
			_b(ci, r, 0.30, 0.04, 0.40, 0.10, trim, 0.08)
			if tier >= 1:
				_b(ci, r, 0.10, 0.34, 0.14, 0.34, dark, 0.08)
			if tier >= 3:
				_b(ci, r, 0.76, 0.34, 0.14, 0.34, dark, 0.08)
		"duplicator":
			# Two mirrored halves with the copy happening between them.
			var split: float = 0.03 + beat * 0.025
			_b(ci, r, 0.06, 0.24, 0.36, 0.66, body, 0.15, true, true)
			_b(ci, r, 0.58, 0.24, 0.36, 0.66, body, 0.15, true, true)
			_e(ci, r, 0.46 - split, 0.34, 0.08 + split * 2.0, 0.46, light,
				glow * (0.8 + beat * 0.7))
			_b(ci, r, 0.06, 0.16, 0.88, 0.08, dark, 0.06, false)
			if tier >= 2:
				_e(ci, r, 0.14, 0.44, 0.18, 0.10, light, glow * 0.5)
				_e(ci, r, 0.68, 0.44, 0.18, 0.10, light, glow * 0.5)
		"condenser":
			# A wide drum under a dome, radiating heat away through fins.
			_b(ci, r, 0.06, 0.40, 0.88, 0.52, body, 0.18, true, true)
			_b(ci, r, 0.24, 0.12, 0.52, 0.30, trim, 0.14)
			for i in range(3 + tier):
				var cx: float = 0.12 + float(i) * (0.76 / float(3 + tier))
				_b(ci, r, cx, 0.46, 0.06, 0.40, dark, 0.0, false)
			_e(ci, r, 0.30, 0.20, 0.40, 0.18, light, glow * 1.1)
			_e(ci, r, 0.14, 0.62, 0.20, 0.08, light, glow * 0.45)
		"heat_pipe":
			# A cross of lagged pipe on a low plinth: it reaches every side,
			# because it hands heat to every side. The glow travels along it.
			_b(ci, r, 0.10, 0.72, 0.80, 0.18, dark, 0.08, true, true)    # plinth
			_b(ci, r, 0.04, 0.38, 0.92, 0.22, body, 0.14, true, true)    # run
			_b(ci, r, 0.39, 0.06, 0.22, 0.70, body, 0.14)                # riser
			for i in range(2 + tier):
				var fx: float = 0.10 + float(i) * (0.74 / float(2 + tier))
				_b(ci, r, fx, 0.34, 0.05, 0.30, trim, 0.0, false)        # flanges
			var flow: float = 0.08 + beat * 0.60
			_e(ci, r, flow, 0.44, 0.22, 0.10, light, glow * 0.9)
			_e(ci, r, 0.42, 0.40, 0.16, 0.18, light, glow * 0.6)
		_:
			_b(ci, r, 0.12, 0.18, 0.76, 0.74, body, 0.16, true, true)
			_e(ci, r, 0.30, 0.36, 0.40, 0.20, light, glow)


## Kept for anything that wants the plain shape: the palette buttons, the
## drag ghost, the app icon mark.
static func silhouette(ci: CanvasItem, rect: Rect2, scale_ref: float,
		_family: int, body: Color, highlight: float = 0.0) -> void:
	Palette.block(ci, rect.grow(-scale_ref * 0.06), body, 0.16, true, true)
	if highlight > 0.01:
		var glow: Color = Color.WHITE
		glow.a = highlight * 0.20
		ci.draw_rect(rect.grow(-scale_ref * 0.06), glow, true)


## The full tile: platform, machine, glyph and output chip. Used by the Codex
## boards, the shop swatches, the icon and the feature graphic, so promotional
## art is literally the same drawing code as the board.
static func tile(ci: CanvasItem, rect: Rect2, id: String, font: Font,
		heat: float = 0.0, opts: Dictionary = {}) -> void:
	var cs: float = minf(rect.size.x, rect.size.y)
	platform(ci, rect, cs, Palette.CELL.lerp(Palette.heat_color(heat), 0.55))
	var inset: float = cs * (1.0 - FOOT) * 0.5
	build(ci, rect.grow(-inset), cs, id, opts)
	glyph(ci, rect, id, font, cs)
	var res: int = Palette.output_res(id)
	if res >= 0:
		var chip: float = cs * 0.14
		var cr := Rect2(rect.position + Vector2(cs * 0.05, cs * 0.05),
			Vector2(chip, chip))
		ci.draw_rect(cr.grow(maxf(cs * 0.014, 1.0)), Palette.BG, true)
		ci.draw_rect(cr, Palette.res_color(res), true)


## The tile the machine stands on: a bevelled platform with a lit top edge and
## a dark seam, so the grid reads as built ground rather than as a table.
static func platform(ci: CanvasItem, r: Rect2, cs: float, base: Color) -> void:
	var seam: float = maxf(cs * 0.035, 1.0)
	ci.draw_rect(r, base.darkened(0.45), true)
	ci.draw_rect(Rect2(r.position.x + seam, r.position.y + seam,
		r.size.x - seam * 2.0, r.size.y - seam * 2.0), base, true)
	var lip: Color = base.lerp(Palette.KEY_TINT, 0.22)
	lip.a = 0.55
	ci.draw_rect(Rect2(r.position.x + seam, r.position.y + seam,
		r.size.x - seam * 2.0, seam), lip, true)


## The mark. Drawn last and separately from the bodies so that every glyph on
## the board lands in one batch instead of seventy.
static func glyph(ci: CanvasItem, rect: Rect2, id: String, font: Font,
		cs: float) -> void:
	var g: String = Palette.machine_glyph(id)
	var gs: int = int(cs * 0.26)
	if gs < 7:
		return
	# Bottom-right, small, in the machine's own light colour. It used to be
	# stamped across the middle at 40% of the tile, which on a lit body reads
	# as a hole punched through the machine. The silhouette and the core
	# colour are now doing the identifying; this is the third channel, for a
	# player who has not learned them yet.
	var ts: Vector2 = font.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, gs)
	var p: Vector2 = rect.position + Vector2(
		rect.size.x - ts.x - cs * 0.06, rect.size.y - cs * 0.10)
	var shade: Color = Palette.BG
	shade.a = 0.85
	ci.draw_string(font, p + Vector2(0, maxf(cs * 0.016, 1.0)), g,
		HORIZONTAL_ALIGNMENT_LEFT, -1, gs, shade)
	ci.draw_string(font, p, g, HORIZONTAL_ALIGNMENT_LEFT, -1, gs,
		Palette.machine_light(id).lerp(Color.WHITE, 0.45))
