class_name Themes
extends RefCounted

## Palettes for the factory. Colour tables and nothing else.
##
## A theme may change what the machines, the ore and the rock look like. It
## may not change anything else, and the structure of this file is what
## enforces that rather than a convention someone has to remember:
##
##   * A theme is a Dictionary of colours. There is nowhere in one to put a
##     number, a rate, a cost or a rule, so a theme cannot reach the
##     simulation even by accident. `Simulation` and `Grid` are node-free
##     RefCounted that never import `Palette`, so the drawing layer is not on
##     the path between a board and its credits at all.
##   * **Status colours are not themeable.** Green working, amber blocked
##     (look downstream), red starved (look upstream), blue/orange thermal --
##     those carry direction, not decoration, and a palette that recoloured
##     them would be selling the player a worse game. They live in `Palette`
##     as constants and stay there.
##   * Neither is the interface chrome. Panels, text and the accent stay put,
##     so contrast ratios hold in every theme and a purchase can never make
##     the game harder to read.
##
## What is left is genuinely worth looking at for hours, which is the only
## honest reason to sell it.

const DEFAULT := "shaft"

## Colours every theme must define. A theme missing one of these is a bug the
## catalogue test catches rather than a tile that silently draws magenta.
const REQUIRED_MACHINES: Array[String] = ["drill", "crusher", "vault", "smelter",
	"boiler", "coolant", "press", "assembler", "amplifier", "lab",
	"duplicator", "condenser"]

const THEMES := {
	# The board as designed: cold rock, blue-grey machinery, heat as the only
	# warm thing on screen. Free, and always the fallback.
	"shaft": {
		"name": "Shaft",
		"blurb": "Cold rock, and heat the only warm thing in it.",
		"free": true,
		"machines": {
			"drill": "6e8ba8", "crusher": "7f96ad", "vault": "5ddba0",
			"smelter": "d98a4a", "boiler": "e2703a", "coolant": "4fc3f7",
			"press": "8fa5bd", "assembler": "9fb4c9", "amplifier": "ffd479",
			"lab": "a780ff", "duplicator": "ff8fd0", "condenser": "6fd6e8",
		},
		"resources": ["8a7f72", "b79b76", "cfd6df", "8fb4d6", "d9c56a"],
		"rock_deep": "2a1c26",
		"heat": ["1a2430", "7a4a24", "c2401c"],
	},
	# Everything machined from brass and copper, the rock gone ochre. Warmer
	# overall, so the thermal blues read harder against it.
	"brass": {
		"name": "Brass Works",
		"blurb": "Copper, lacquer and a shaft that never cooled.",
		"free": false,
		"machines": {
			"drill": "b08d57", "crusher": "9c7c4a", "vault": "7ec49a",
			"smelter": "e09a3e", "boiler": "d4622a", "coolant": "6fc2d6",
			"press": "c9a166", "assembler": "d8b779", "amplifier": "ffd98a",
			"lab": "b894e0", "duplicator": "e59ac0", "condenser": "8fd4de",
		},
		"resources": ["8f7c5e", "c4a173", "e4dcc8", "a8b89a", "e8cf7a"],
		"rock_deep": "2b2018",
		"heat": ["221c16", "7a5430", "b04a22"],
	},
	# An arctic station: white plant, blue ice, almost no warm hue except the
	# heat ramp itself.
	"frost": {
		"name": "Deep Frost",
		"blurb": "A plant built into ice that refuses to melt.",
		"free": false,
		"machines": {
			"drill": "8fa8c4", "crusher": "a3b8cf", "vault": "6fd9b8",
			"smelter": "e6a15c", "boiler": "eb8354", "coolant": "7fd8f5",
			"press": "c3d3e2", "assembler": "d6e2ee", "amplifier": "ffe6a8",
			"lab": "bba6f0", "duplicator": "f0aad8", "condenser": "9ae8f2",
		},
		"resources": ["9aa7b3", "c2cbd4", "eef3f8", "a9c9e8", "e8dc9a"],
		"rock_deep": "16222e",
		"heat": ["16222e", "5d5a52", "9c5340"],
	},
	# Something grew down here. Green plant, mineral ore, warm rot in the rock.
	"verdant": {
		"name": "Verdant Seam",
		"blurb": "Something grew down here before you did.",
		"free": false,
		"machines": {
			"drill": "6f9a72", "crusher": "84a97f", "vault": "6fe0a4",
			"smelter": "d09040", "boiler": "cf6f3a", "coolant": "5ec9c4",
			"press": "9ab594", "assembler": "aec7a5", "amplifier": "e8d477",
			"lab": "9fd06a", "duplicator": "e2a0c8", "condenser": "7ad6c0",
		},
		"resources": ["7d8471", "a3a878", "d7dcc4", "93b8a0", "cfd06a"],
		"rock_deep": "1d2a1e",
		"heat": ["16241c", "5f6030", "9a5028"],
	},
	# Close enough to the magma to be a bad idea. Reds, and a rock that glows
	# on its own.
	"ember": {
		"name": "Ember Cut",
		"blurb": "Close enough to the magma to be a bad idea.",
		"free": false,
		"machines": {
			"drill": "a8706e", "crusher": "b58280", "vault": "6fd99a",
			"smelter": "f0954a", "boiler": "ff7a44", "coolant": "5fc9ef",
			"press": "c99a96", "assembler": "d9ada8", "amplifier": "ffd06a",
			"lab": "c48af0", "duplicator": "ff9ac2", "condenser": "7fd2e6",
		},
		"resources": ["8f6f68", "bf8d78", "e6d8d0", "b0a0c8", "f0c860",
		],
		"rock_deep": "2e1616",
		"heat": ["281a1a", "8a4426", "c73c1c"],
	},
	# Greyscale but for the glyph chips. Also the palette to reach for if
	# colour is not carrying its weight for you -- every machine still differs
	# by silhouette family and glyph, and the status lights are untouched.
	"slate": {
		"name": "Slate",
		"blurb": "Grey plant, coloured cargo. Shape does the work.",
		"free": false,
		"machines": {
			"drill": "8a939c", "crusher": "9aa3ac", "vault": "b6c0c8",
			"smelter": "a8a29c", "boiler": "b0a49c", "coolant": "9caab4",
			"press": "aab3bc", "assembler": "b8c1c9", "amplifier": "c6ccd2",
			"lab": "9fa6b4", "duplicator": "c0bcc6", "condenser": "a6b4bc",
		},
		# The cargo stays in colour on purpose: in a greyscale plant the chip
		# is the only thing saying what a machine hands over.
		"resources": ["8a7f72", "c49a5e", "e8eef4", "6fa8e0", "e8c840"],
		"rock_deep": "1e2126",
		"heat": ["191d22", "5a5a5a", "8f8f8f"],
	},
}

## Draw order in the picker. Free one first.
const ORDER: Array[String] = ["shaft", "brass", "frost", "verdant", "ember", "slate"]


static func count() -> int:
	return ORDER.size()


static func paid_count() -> int:
	var n: int = 0
	for k: String in ORDER:
		if not bool((THEMES[k] as Dictionary).get("free", false)):
			n += 1
	return n


static func exists(id: String) -> bool:
	return THEMES.has(id)


static func is_free(id: String) -> bool:
	return bool((THEMES.get(id, {}) as Dictionary).get("free", false))


static func name_of(id: String) -> String:
	return Loc.t(String((THEMES.get(id, {}) as Dictionary).get("name", id)))


static func blurb_of(id: String) -> String:
	var b: String = String((THEMES.get(id, {}) as Dictionary).get("blurb", ""))
	return Loc.t(b) if b != "" else ""


static func get_theme(id: String) -> Dictionary:
	return THEMES.get(id, THEMES[DEFAULT])


## Machine colours for a theme, as Colors. Built on demand and cached, because
## this is read once per machine per frame.
static var _cache: Dictionary = {}


static func machine_colors(id: String) -> Dictionary:
	var key: String = id + ":m"
	if _cache.has(key):
		return _cache[key]
	var src: Dictionary = (get_theme(id).get("machines", {}) as Dictionary)
	var out: Dictionary = {}
	for m: String in src:
		out[m] = Color(String(src[m]))
	_cache[key] = out
	return out


static func resource_colors(id: String) -> Array:
	var key: String = id + ":r"
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	for hex: String in (get_theme(id).get("resources", []) as Array):
		out.append(Color(hex))
	_cache[key] = out
	return out


static func rock_deep(id: String) -> Color:
	return Color(String(get_theme(id).get("rock_deep", "241a1c")))


static func heat_ramp(id: String) -> Array:
	var key: String = id + ":h"
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	for hex: String in (get_theme(id).get("heat", []) as Array):
		out.append(Color(hex))
	_cache[key] = out
	return out
