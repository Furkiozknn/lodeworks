class_name Palette
extends RefCounted

## Colour and layout, in one place.
##
## The whole game is drawn with `_draw()` — rounded rectangles, lines and text.
## There is not one bitmap in the project. That is a deliberate production
## decision, not a placeholder: it means no art pipeline, no atlas, no import
## settings, no texture memory, perfect crispness at every phone density, and a
## build measured in single-digit megabytes. A solo developer's scarcest
## resource is art, so the design removes the need for it.
##
## The palette is dark because the game is played in long sessions and often in
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

## Heat ramp. Cold is the board colour; hot is a strong orange-red. A player
## should be able to read the thermal state of a board without reading a number.
const HEAT_COLD := Color("1a2430")
const HEAT_WARM := Color("6b4a2a")
const HEAT_HOT := Color("a33a1f")

## Machine colours. Grouped by role so the board is legible at a glance:
## blue-ish = moves material, orange = heat, cyan = cooling, violet = science,
## green = sells.
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

const RADIUS := 10.0
const PAD := 12.0


static func machine_color(id: String) -> Color:
	return MACHINE_COLOR.get(id, Color("8fa5bd"))


static func machine_glyph(id: String) -> String:
	return String(MACHINE_GLYPH.get(id, "?"))


## Heat to colour. The knee at 3.0 is where most machines start to be unhappy,
## so it is also where the colour starts to shout.
static func heat_color(heat: float) -> Color:
	var h: float = maxf(heat, 0.0)
	if h <= 0.05:
		return HEAT_COLD
	if h <= 3.0:
		return HEAT_COLD.lerp(HEAT_WARM, h / 3.0)
	return HEAT_WARM.lerp(HEAT_HOT, clampf((h - 3.0) / 5.0, 0.0, 1.0))


## Efficiency to colour, used for the little bar under each machine.
static func efficiency_color(eff: float) -> Color:
	if eff >= 0.95:
		return GOOD
	if eff >= 0.7:
		return WARN
	return BAD
