class_name Palette
extends RefCounted

## Colour, shape and layout, in one place.
##
## The whole game is drawn with `_draw()` — rectangles, thin lines and text.
## There is not one bitmap in the project. That is a deliberate production
## decision, not a placeholder: no art pipeline, no atlas, no import settings,
## no texture memory, perfect crispness at every phone density, a build
## measured in single-digit megabytes, and — the part that matters most for a
## game whose content strategy is "add a row to a table" — a new machine gets
## its look from data instead of from an artist.
##
## Almost everything here is expressed as rectangles on purpose. Godot's
## compatibility renderer batches rect draws while polygons (circles, arcs,
## thick or antialiased lines) each break the batch and cost a draw call, and
## this board has seventy cells. Silhouettes are therefore built from two or
## three rects rather than from a polygon outline.
##
## The palette is dark because the game is played in long sessions, often in
## the evening, and because heat reads as colour against a dark board.

const BG := Color("0d1219")
const PANEL := Color("161d29")
const PANEL_HI := Color("222c3b")
const LINE := Color("33415a")
const CELL := Color("1a2331")
const CELL_BLOCKED := Color("0b0e12")
## The colour the empty rock tends towards at the bottom of the shaft. Warmer
## and redder, so depth is visible in the ground rather than only in a label.
const ROCK_DEEP := Color("2a1c26")

const TEXT := Color("e6edf5")
const TEXT_DIM := Color("8b9bb0")
const TEXT_FAINT := Color("55647a")

const ACCENT := Color("4fc3f7")        ## credits / primary action
const RESEARCH := Color("a780ff")      ## research
const CORE := Color("ffd479")          ## cores, the permanent currency
const GOOD := Color("5ddba0")
const WARN := Color("ffb454")
const BAD := Color("ff6b6b")
const COLD := Color("5aa9e6")

## Absolute heat ramp, used for the rock and for the "how hot is this part of
## the board" reading. Cold is the board colour; hot is a strong orange-red.
const HEAT_COLD := Color("1a2430")
const HEAT_WARM := Color("7a4a24")
const HEAT_HOT := Color("c2401c")

## Status colours. Four, and no more.
##
## The semantics are borrowed from the Factorio "Bottleneck" mods, which do
## nothing except put a coloured light on every machine and have been
## downloaded hundreds of thousands of times — players install a third-party
## mod to get exactly this. What makes three colours enough to find a problem
## on a large board without any graph analysis is that two of them point in
## OPPOSITE directions along the chain:
##
##   green   working
##   amber   output backed up  -> the problem is DOWNSTREAM of this tile
##   red     missing an input  -> the problem is UPSTREAM of this tile
##
## The fourth is this game's own: the tile is fed and draining fine, but it is
## at the wrong temperature and is quietly giving up throughput. Blue for too
## cold, orange for too hot, so it also carries its direction.
const ST_RUNNING := Color("5ddba0")
const ST_BLOCKED := Color("ffb454")
const ST_STARVED := Color("ff6b6b")
const ST_HOT := Color("ff8a3d")
const ST_COLD := Color("5aa9e6")
const ST_IDLE := Color("46566b")

## Diverging ramp for the heat overlay, centred on each machine's OWN ideal
## temperature rather than on an absolute value. Every machine in this game
## wants a different temperature, so an absolute map answers the wrong
## question: what a player needs to see is "how wrong is each tile", and the
## sign of the error tells them whether to add a Boiler or a Coolant Cell.
const DIV_COLD := Color("2e6ea8")
const DIV_OK := Color("2f7a5a")
const DIV_HOT := Color("b0432a")

## Resource colours and marks. Every machine carries a small chip showing what
## it OUTPUTS, because "which building makes which item" is the most common
## readability complaint in the genre and the board cannot answer it from the
## machine glyph alone.
const RES_COLOR := {
	0: Color("8a7f72"),   ## ore     — dull rock
	1: Color("b79b76"),   ## gravel  — warmer, lighter
	2: Color("cfd6df"),   ## ingot   — bright metal
	3: Color("8fb4d6"),   ## plate   — blued steel
	4: Color("d9c56a"),   ## component — finished, valuable
}

const RES_MARK := {
	0: "·",
	1: "∷",
	2: "▬",
	3: "▤",
	4: "✦",
}

## Machine colours. Grouped by role so the board is legible at a glance:
## blue-grey = moves material, orange = makes heat, cyan = removes it,
## violet = science, green = sells, gold = boosts.
const MACHINE_COLOR := {
	"drill": Color("6e8ba8"),
	"crusher": Color("7f96ad"),
	"vault": Color("5ddba0"),
	"smelter": Color("d98a4a"),
	"boiler": Color("e2703a"),
	"coolant": Color("4fc3f7"),
	"press": Color("8fa5bd"),
	"assembler": Color("9fb4c9"),
	"amplifier": Color("ffd479"),
	"lab": Color("a780ff"),
	"duplicator": Color("ff8fd0"),
	"condenser": Color("6fd6e8"),
	"heat_pipe": Color("c27a52"),
}

## A one-or-two glyph mark per machine, drawn as text. Cheaper than icons,
## instantly recognisable once learned, and it localises for free.
const MACHINE_GLYPH := {
	"drill": "▼",       # down triangle - it digs
	"crusher": "▦",     # hatched square - it breaks things up
	"vault": "◎",       # ringed circle - a safe
	"smelter": "▲",     # up triangle - a furnace flame
	"boiler": "≈",      # waves - heat
	"coolant": "❄",     # snowflake
	"press": "▬",       # heavy bar - it flattens
	"assembler": "◈",   # diamond in diamond - composition
	"amplifier": "▶",   # play - it pushes
	"lab": "○",         # flask bulb
	"duplicator": "⧉",  # two squares - a copy
	"condenser": "❅",   # flowered snowflake
	"heat_pipe": "⇌",   # two-way arrows - heat carried across
}

## Silhouette families. Two machines of the same colour must still be
## distinguishable in greyscale and at a glance, so the body outline differs
## by what the machine DOES. Each family is drawn from rectangles, so the
## whole board still batches.
##
##   RIG     a source — heavy base, tapered head, it goes into the rock
##   MILL    a converter — squat body with a lid band
##   FURNACE a heat machine — body with a chimney block
##   STORE   a sink — double-walled box
##   LAB     science — narrow tower
##   FIELD   a passive booster — body with side fins
enum Family { RIG, MILL, FURNACE, STORE, LAB, FIELD }

const MACHINE_FAMILY := {
	"drill": Family.RIG,
	"crusher": Family.MILL,
	"vault": Family.STORE,
	"smelter": Family.FURNACE,
	"boiler": Family.FURNACE,
	"coolant": Family.FURNACE,
	"press": Family.MILL,
	"assembler": Family.MILL,
	"amplifier": Family.FIELD,
	"lab": Family.LAB,
	"duplicator": Family.FIELD,
	"condenser": Family.FURNACE,
	"heat_pipe": Family.FURNACE,
}

const RADIUS := 10.0
const PAD := 12.0


## --- the material and lighting system ---------------------------------------
##
## Everything in this game is still drawn with `draw_rect`. What changed is
## that a rectangle is no longer a flat colour: it is one face of a solid,
## lit by one key light, and the game builds machines out of faces.
##
## Three tones make a block read as three-dimensional on a flat board:
##
##   TOP    the face pointing at the light. Lightest, slightly desaturated
##          towards white, because a highlight is light, not more paint.
##   FRONT  the face pointing at the camera. The machine's actual colour.
##   SIDE   the face turned away. Darkest, and pushed towards the ambient
##          blue of the shaft rather than towards black, because nothing in a
##          lit room is ever truly black.
##
## Plus two thin extras that do most of the work for almost no cost:
##
##   RIM    a one-pixel line along the top-left edge where the key light
##          catches the corner. This is the single cheapest thing that makes
##          a flat shape look machined.
##   CONTACT a dark pad under the body. A block with no shadow floats; a
##          block with a shadow sits on the tile.
##
## The light is fixed: one warm key from the upper left, a cool ambient fill
## from the shaft itself. It never moves, so every machine on the board agrees
## about where the light is, which is what makes seventy separate drawings
## look like one scene.

## Where the key light comes from, in tile fractions. Up and to the left.
const LIGHT_DIR := Vector2(-0.38, -0.55)
## How far a top face is offset from its body. The whole 3D read is this
## number; larger looks like a tower, smaller looks like a sticker.
const FACE_LIFT := 0.17
## The warm tint of the key light and the cool tint of the ambient fill.
const KEY_TINT := Color("ffe9c4")
const FILL_TINT := Color("2b3a52")


## The five tones a solid is drawn with.
static func faces(base: Color) -> Dictionary:
	return {
		"top": base.lerp(KEY_TINT, 0.52),
		"front": base,
		"side": base.lerp(FILL_TINT, 0.46).darkened(0.12),
		"rim": base.lerp(KEY_TINT, 0.78),
		"contact": base.lerp(BG, 0.72).darkened(0.25),
	}


## Draw one solid block: side faces, front face, lifted top face, rim light
## and contact shadow. `lift` is the top-face offset as a fraction of the
## block height; 0 draws a flat plate.
##
## Six rectangles, all of which batch. A machine is three or four of these
## stacked, which is why the board can afford to look built.
static func block(ci: CanvasItem, r: Rect2, base: Color, lift: float = FACE_LIFT,
		rim: bool = true, contact: bool = true) -> void:
	var f: Dictionary = faces(base)
	var dy: float = r.size.y * lift
	if contact and dy > 0.5:
		var pad: Color = f["contact"]
		pad.a = 0.55
		ci.draw_rect(Rect2(r.position.x + r.size.x * 0.06,
			r.position.y + r.size.y - dy * 0.35,
			r.size.x * 0.94, dy * 0.75), pad, true)
	# Side: the whole footprint, darkest, showing beneath the front face.
	ci.draw_rect(r, f["side"], true)
	# Front: inset from the right and bottom so the side face shows there.
	ci.draw_rect(Rect2(r.position.x, r.position.y,
		r.size.x - maxf(dy * 0.55, 0.0), r.size.y - maxf(dy * 0.5, 0.0)),
		f["front"], true)
	# Top: lifted and inset, the face the light lands on.
	if dy > 0.5:
		ci.draw_rect(Rect2(r.position.x + dy * 0.22, r.position.y,
			r.size.x - dy * 1.0, dy), f["top"], true)
	if rim:
		var w: float = maxf(r.size.y * 0.035, 1.0)
		ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x - dy * 0.55, w),
			f["rim"], true)
		ci.draw_rect(Rect2(r.position.x, r.position.y, w, r.size.y - dy * 0.5),
			f["rim"], true)


## A glowing element: a bright core with a soft halo around it, drawn as three
## nested rectangles of falling alpha. Cheaper than a shader and it reads at
## any size, which a blur texture does not.
static func emissive(ci: CanvasItem, r: Rect2, col: Color,
		strength: float = 1.0) -> void:
	if strength <= 0.01:
		return
	var k: float = clampf(strength, 0.0, 2.0)
	# Four steps rather than two, sized off the SHORT edge so a wide element
	# does not throw a halo twice its own height. The first version grew the
	# halo by the element's height and produced a hard orange rectangle round
	# every Smelter instead of a glow.
	var unit: float = minf(r.size.x, r.size.y)
	var halo: Color = col
	const STEPS := [0.85, 0.52, 0.28, 0.12]
	const ALPHA := [0.05, 0.09, 0.15, 0.26]
	for i in range(STEPS.size()):
		halo.a = ALPHA[i] * k
		ci.draw_rect(r.grow(unit * STEPS[i] * minf(k, 1.25)), halo, true)
	# The core itself: white-hot in the middle, its own colour at the edge.
	var core: Color = col.lerp(Color.WHITE, clampf(0.22 * k, 0.0, 0.6))
	ci.draw_rect(r, core, true)
	var hot: Color = Color.WHITE
	hot.a = clampf(0.30 * k, 0.0, 0.7)
	ci.draw_rect(r.grow(-unit * 0.22), hot, true)


## --- the shaft, by depth -----------------------------------------------------
##
## Descending has to look like going somewhere, not like the same board with a
## bigger number on it. Four bands, each with its own rock, its own mineral and
## its own light, blended continuously so a descent is a slide rather than a
## cut:
##
##   0-3   SURFACE   cool blue-grey stone, pale quartz, daylight leaking in
##   4-9   WORKINGS  warmer worked rock, copper flecks, lamp light
##   10-16 DEEP      dark iron-red, violet crystal, heat in the cracks
##   17+   ABYSSAL   near-black basalt, bright veins, everything lit from below
##
## The theme's own `rock_deep` is the destination the ramp walks towards, so a
## purchased palette still changes the shaft rather than being overruled by it.
const BAND_ROCK := ["1e2a3a", "2a2a33", "33222a", "2a1820"]
const BAND_FLECK := ["9fb6cc", "c9a173", "c08a9a", "e0b0ff"]
const BAND_VEIN := ["4fc3f7", "ffb454", "ff7a3d", "c26bff"]


## Where in the four bands a depth sits: the band index and how far through it.
static func band_at(depth: int) -> Array:
	const EDGES := [0.0, 4.0, 10.0, 17.0, 26.0]
	var d: float = float(maxi(depth, 0))
	for i in range(3):
		if d < EDGES[i + 1]:
			return [i, clampf((d - EDGES[i]) / (EDGES[i + 1] - EDGES[i]), 0.0, 1.0)]
	return [3, clampf((d - EDGES[3]) / (EDGES[4] - EDGES[3]), 0.0, 1.0)]


## The rock, the mineral in it and the light coming out of it, at this depth.
static func shaft(depth: int) -> Dictionary:
	var b: Array = band_at(depth)
	var i: int = int(b[0])
	var t: float = float(b[1])
	var j: int = mini(i + 1, 3)
	var rock: Color = Color(BAND_ROCK[i]).lerp(Color(BAND_ROCK[j]), t)
	# The theme still gets the last word on how deep rock reads, so a bought
	# palette changes the shaft instead of being painted over by it.
	rock = rock.lerp(rock_deep(), 0.35 * clampf(float(depth) / 20.0, 0.0, 1.0))
	return {
		"rock": rock,
		"fleck": Color(BAND_FLECK[i]).lerp(Color(BAND_FLECK[j]), t),
		"vein": Color(BAND_VEIN[i]).lerp(Color(BAND_VEIN[j]), t),
		# How much the rock itself glows. Nothing at the surface; by the
		# abyssal band the ground is a light source.
		"ember": clampf((float(depth) - 8.0) / 16.0, 0.0, 1.0),
	}


## The colour a machine glows. Its light signature -- the thing that tells you
## what a tile is from across the board when the glyph is too small to read.
##
## Twelve hues, spread far enough apart that no two of them can be confused at
## a glance. `test_machine_light_colours_are_distinct` enforces the spacing,
## and it found three yellows sitting on top of each other the first time it
## ran: a Drill, a Press and an Amplifier all glowed the same amber. The Press
## is now cold steel, which is also truer -- it is the one machine in the
## chain that wants to stay cool.
const MACHINE_LIGHT := {
	"drill": "ffc46b",       # warm work lamp
	"crusher": "ff8c3a",     # friction heat
	"vault": "5df0a0",       # money green
	"smelter": "ff5a1f",     # molten orange
	"boiler": "ff2e12",      # furnace red
	"coolant": "5ecbff",     # ice blue
	"press": "dfe8f5",       # cold hydraulic steel
	"assembler": "2f9dff",   # assembly blue
	"amplifier": "fff03a",   # power yellow
	"lab": "b06bff",         # research violet
	"duplicator": "ff6bc4",  # duplication pink
	"condenser": "4ff0cf",   # condensation teal
	"heat_pipe": "ffa8a0",   # glowing copper
}


static func machine_light(id: String) -> Color:
	return Color(String(MACHINE_LIGHT.get(id, "ffd479")))


## --- the active palette -----------------------------------------------------
##
## A theme may change three things: what the machines are painted, what the
## cargo chips are painted, and what the rock and its heat ramp look like. It
## may change nothing else, and this is the whole surface through which it can
## try.
##
## The constants above stay exactly where they are and keep their meanings.
## Status colours in particular are NOT themeable -- amber means "look
## downstream" and red means "look upstream", and a palette that repainted
## them would be selling somebody a board that is harder to read. Panels, text
## and the accent are not themeable either, so contrast holds whatever is
## selected.
##
## Nothing in the simulation can see any of this: `Grid` and `Simulation` are
## node-free RefCounted that never import this file, so the theme is not on the
## path between a board and its credits. `tests/test_store.gd` asserts that by
## running the same board under every theme and comparing the output.

static var _theme: String = Themes.DEFAULT


static func set_theme(id: String) -> void:
	_theme = id if Themes.exists(id) else Themes.DEFAULT


static func theme() -> String:
	return _theme


static func machine_color(id: String) -> Color:
	var c: Variant = Themes.machine_colors(_theme).get(id, null)
	if c != null:
		return c
	return MACHINE_COLOR.get(id, Color("8fa5bd"))


static func machine_glyph(id: String) -> String:
	return String(MACHINE_GLYPH.get(id, "?"))


static func family_of(id: String) -> int:
	return int(MACHINE_FAMILY.get(id, Family.MILL))


static func res_color(res: int) -> Color:
	var arr: Array = Themes.resource_colors(_theme)
	if res >= 0 and res < arr.size():
		return arr[res]
	return RES_COLOR.get(res, Color("8fa5bd"))


static func res_mark(res: int) -> String:
	return String(RES_MARK.get(res, "·"))


## The resource a machine hands to its neighbours, or -1 for the ones that
## hand over nothing (a Vault consumes, a Boiler only radiates).
static func output_res(id: String) -> int:
	var m: Dictionary = MachineDB.get_machine(id)
	if m.is_empty():
		return -1
	var outs: Dictionary = m.get("outputs", {})
	for k: int in outs.keys():
		return k
	return -1


## Heat to colour, absolute. The knee at 3.0 is where most machines start to
## be unhappy, so it is also where the colour starts to shout.
static func heat_color(heat: float) -> Color:
	var ramp: Array = Themes.heat_ramp(_theme)
	var cold: Color = ramp[0] if ramp.size() > 0 else HEAT_COLD
	var warm: Color = ramp[1] if ramp.size() > 1 else HEAT_WARM
	var hot: Color = ramp[2] if ramp.size() > 2 else HEAT_HOT
	var h: float = maxf(heat, 0.0)
	if h <= 0.05:
		return cold
	if h <= 3.0:
		return cold.lerp(warm, h / 3.0)
	return warm.lerp(hot, clampf((h - 3.0) / 5.0, 0.0, 1.0))


## The colour the empty rock tends towards at the bottom of the shaft, for the
## selected theme.
static func rock_deep() -> Color:
	return Themes.rock_deep(_theme)


## Heat error to colour, relative to what this particular machine wants.
## `delta` is signed: negative means colder than ideal, positive hotter.
static func divergent_color(delta: float, tolerance: float) -> Color:
	var span: float = maxf(tolerance, 0.5)
	var t: float = clampf(absf(delta) / span, 0.0, 1.0)
	if delta < 0.0:
		return DIV_OK.lerp(DIV_COLD, t)
	return DIV_OK.lerp(DIV_HOT, t)


## Efficiency to colour, used for the bar under each machine.
static func efficiency_color(eff: float) -> Color:
	if eff >= 0.95:
		return GOOD
	if eff >= 0.7:
		return WARN
	return BAD


## Status to colour. `heat_delta` decides which way the thermal warning goes.
static func status_color(status: int, thermal: bool, heat_delta: float) -> Color:
	match status:
		Simulation.Status.STARVED:
			return ST_STARVED
		Simulation.Status.BLOCKED:
			return ST_BLOCKED
		Simulation.Status.IDLE:
			return ST_IDLE
	if thermal:
		return ST_HOT if heat_delta > 0.0 else ST_COLD
	return ST_RUNNING
