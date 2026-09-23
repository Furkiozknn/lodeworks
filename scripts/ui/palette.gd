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

const BG := Color("0e1116")
const PANEL := Color("161b23")
const PANEL_HI := Color("1d2430")
const LINE := Color("2a3441")
const CELL := Color("141a22")
const CELL_BLOCKED := Color("0b0e12")

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
const HEAT_WARM := Color("6b4a2a")
const HEAT_HOT := Color("a33a1f")

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
}

const RADIUS := 10.0
const PAD := 12.0


static func machine_color(id: String) -> Color:
	return MACHINE_COLOR.get(id, Color("8fa5bd"))


static func machine_glyph(id: String) -> String:
	return String(MACHINE_GLYPH.get(id, "?"))


static func family_of(id: String) -> int:
	return int(MACHINE_FAMILY.get(id, Family.MILL))


static func res_color(res: int) -> Color:
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
	var h: float = maxf(heat, 0.0)
	if h <= 0.05:
		return HEAT_COLD
	if h <= 3.0:
		return HEAT_COLD.lerp(HEAT_WARM, h / 3.0)
	return HEAT_WARM.lerp(HEAT_HOT, clampf((h - 3.0) / 5.0, 0.0, 1.0))


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
