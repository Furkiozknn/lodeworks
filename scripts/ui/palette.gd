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

## Resource colours: the beads on the seams, the gems in the panels and the
## recipe chips all carry a resource in its own colour, because "which
## building makes which item" is the most common readability complaint in the
## genre.
const RES_COLOR := {
	0: Color("8a7f72"),   ## ore     — dull rock
	1: Color("b79b76"),   ## gravel  — warmer, lighter
	2: Color("cfd6df"),   ## ingot   — bright metal
	3: Color("8fb4d6"),   ## plate   — blued steel
	4: Color("d9c56a"),   ## component — finished, valuable
	5: Color("a57be0"),   ## crystal — the violet of the veins in the rock
	6: Color("f08a4b"),   ## alloy — white-hot copper
	7: Color("5fd0c0"),   ## frame — the deep chain's end, cool teal
	8: Color("ffb347"),   ## rig — safety orange, the crew's paint
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
}

const RADIUS := 10.0
const PAD := 12.0


## The warm tint of the lamps, for the interface's lit edges.
const KEY_TINT := Color("ffe9c4")


## --- the shaft, by depth -----------------------------------------------------
##
## Descending has to look like going somewhere, not like the same board with a
## bigger number on it. Four bands, each with its own light (IsoView.band_tint
## tints the world by them) and its own vein colour, for the band's banner and
## the dust in the air:
##
##   0-3   SURFACE   daylight
##   4-9   WORKINGS  lamp light, amber
##   10-16 DEEP      red, embers
##   17+   ABYSSAL   violet, lit from below
const BAND_VEIN := ["4fc3f7", "ffb454", "ff7a3d", "c26bff"]


## Where in the four bands a depth sits: the band index and how far through it.
static func band_at(depth: int) -> Array:
	const EDGES := [0.0, 4.0, 10.0, 17.0, 26.0]
	var d: float = float(maxi(depth, 0))
	for i in range(3):
		if d < EDGES[i + 1]:
			return [i, clampf((d - EDGES[i]) / (EDGES[i + 1] - EDGES[i]), 0.0, 1.0)]
	return [3, clampf((d - EDGES[3]) / (EDGES[4] - EDGES[3]), 0.0, 1.0)]


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
}


static func machine_light(id: String) -> Color:
	if not _light.has(id):
		_light[id] = Color(String(MACHINE_LIGHT.get(id, "ffd479")))
	return _light[id]

## Parsed once: every machine on the board asks for its light every frame.
static var _light: Dictionary = {}


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


## Settings' "Larger text" makes every word the interface writes a quarter
## bigger: the smallest (main.TEXT_MIN) goes from 9.6 to 12 dp on the
## reference phone, Android's body text size. Every panel's labels are
## sized through here.
const LARGE_TEXT := 1.25


static func text_px(size_px: int) -> int:
	if bool(Sim.settings.get("large_text", false)):
		return int(round(float(size_px) * LARGE_TEXT))
	return size_px


static func res_color(res: int) -> Color:
	var arr: Array = Themes.resource_colors(_theme)
	if res >= 0 and res < arr.size():
		return arr[res]
	return RES_COLOR.get(res, Color("8fa5bd"))


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


## Heat error to colour, relative to what this particular machine wants.
## `delta` is signed: negative means colder than ideal, positive hotter.
static func divergent_color(delta: float, tolerance: float) -> Color:
	var span: float = maxf(tolerance, 0.5)
	var t: float = clampf(absf(delta) / span, 0.0, 1.0)
	if delta < 0.0:
		return DIV_OK.lerp(DIV_COLD, t)
	return DIV_OK.lerp(DIV_HOT, t)


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
