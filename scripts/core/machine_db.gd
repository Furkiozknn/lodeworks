class_name MachineDB
extends RefCounted

## Every machine in the game, as data.
##
## The whole content strategy of this project rests on one property: a new
## machine does not add one new thing to do, it multiplies what every existing
## machine can be placed next to. Twelve machines on a grid with heat coupling
## is a far larger design space than twelve hand-built levels, and it costs one
## dictionary entry to extend.
##
## So machines live here as pure data with no scene, no texture and no node
## attached. The simulation reads this table, the tests read this table, and
## the UI reads this table. Adding content means adding rows.

## Resources flow strictly up this chain. Keeping it linear is deliberate:
## the interesting decisions should come from SPACE and HEAT, not from
## memorising a recipe graph.
enum Res { ORE, GRAVEL, INGOT, PLATE, COMPONENT }

const RES_NAME := {
	Res.ORE: "Ore",
	Res.GRAVEL: "Gravel",
	Res.INGOT: "Ingot",
	Res.PLATE: "Plate",
	Res.COMPONENT: "Component",
}

## What a unit of each resource is worth when a Vault sells it. The curve is
## steeper than the conversion ratio, so refining is always worth the space --
## otherwise the optimal board would be all Drills and Vaults and the game
## would have no middle.
const RES_VALUE := {
	Res.ORE: 1.0,
	Res.GRAVEL: 3.0,
	Res.INGOT: 9.0,
	Res.PLATE: 28.0,
	Res.COMPONENT: 95.0,
}

## Heat is the spatial constraint that makes placement a puzzle rather than a
## packing exercise. A machine emits heat into its own cell; half of it bleeds
## into each orthogonal neighbour. Machines then run fast or slow depending on
## how hot the cell they sit in actually is.
const HEAT_SPREAD := 0.5

## Machines that want to be cold sit at optimum 0. Machines that want to be hot
## sit higher, which forces you to build heat on purpose and then contain it.
const MACHINES := {
	"drill": {
		"name": "Drill",
		"desc": "Pulls raw ore out of the stratum. Needs no input, so it is the only thing that works alone -- and the only thing that is boring alone.",
		"cost": 15.0,
		"cost_growth": 1.16,
		"inputs": {},
		"outputs": {Res.ORE: 1},
		"rate": 1.0,
		"heat_out": 0.4,
		"heat_optimum": 0.0,
		"heat_tolerance": 3.0,
		"unlock_depth": 0,
		"tags": ["source"],
	},
	"crusher": {
		"name": "Crusher",
		"desc": "Two ore into one gravel. Runs a little better warm, which is the first hint that heat is a tool and not only a tax.",
		"cost": 40.0,
		"cost_growth": 1.17,
		"inputs": {Res.ORE: 2},
		"outputs": {Res.GRAVEL: 1},
		"rate": 1.0,
		"heat_out": 0.6,
		"heat_optimum": 1.0,
		"heat_tolerance": 4.0,
		"unlock_depth": 0,
		"tags": [],
	},
	"vault": {
		"name": "Vault",
		"desc": "Sells whatever its neighbours hand it. Deeper resources are worth disproportionately more, so a Vault fed raw ore is a Vault wasted.",
		"cost": 25.0,
		"cost_growth": 1.14,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": 0.0,
		"heat_optimum": 0.0,
		"heat_tolerance": 6.0,
		"unlock_depth": 0,
		"tags": ["sink"],
	},
	"smelter": {
		"name": "Smelter",
		"desc": "Wants to be hot, and says so. Build it a furnace. Then build the furnace a coolant loop.",
		"cost": 120.0,
		"cost_growth": 1.18,
		"inputs": {Res.GRAVEL: 2},
		"outputs": {Res.INGOT: 1},
		"rate": 0.9,
		"heat_out": 1.2,
		"heat_optimum": 3.0,
		"heat_tolerance": 6.0,
		"unlock_depth": 1,
		"tags": [],
	},
	"boiler": {
		"name": "Boiler",
		"desc": "Produces nothing. Heats everything around it. The first machine that is only worth placing because of what it is next to.",
		"cost": 90.0,
		"cost_growth": 1.20,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": 2.6,
		"heat_optimum": 0.0,
		"heat_tolerance": 99.0,
		"unlock_depth": 1,
		"tags": ["heat"],
	},
	"coolant": {
		"name": "Coolant Cell",
		"desc": "Negative heat. Costs you a tile you would rather have filled, which is exactly the trade the game is about.",
		"cost": 110.0,
		"cost_growth": 1.20,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": -2.2,
		"heat_optimum": 0.0,
		"heat_tolerance": 99.0,
		"unlock_depth": 2,
		"tags": ["cool"],
	},
	"press": {
		"name": "Press",
		"desc": "Squeezes ingots flat. Runs hot doing it and cannot take much in return, which is the whole problem with building deep.",
		"cost": 420.0,
		"cost_growth": 1.19,
		"inputs": {Res.INGOT: 2},
		"outputs": {Res.PLATE: 1},
		"rate": 0.8,
		"heat_out": 0.5,
		"heat_optimum": 0.0,
		"heat_tolerance": 2.5,
		"unlock_depth": 3,
		"tags": [],
	},
	"assembler": {
		"name": "Assembler",
		"desc": "The end of the chain, and the hottest thing on the board. A component is worth more than everything that went into it -- if you can keep this cool enough to make one.",
		"cost": 1400.0,
		"cost_growth": 1.20,
		"inputs": {Res.PLATE: 1, Res.GRAVEL: 2},
		"outputs": {Res.COMPONENT: 1},
		"rate": 0.7,
		"heat_out": 0.8,
		"heat_optimum": 1.5,
		"heat_tolerance": 4.0,
		"unlock_depth": 4,
		"tags": [],
	},
	"amplifier": {
		"name": "Amplifier",
		"desc": "Every producing neighbour runs 35% faster. Stacks with other Amplifiers, which is how the board stops being flat.",
		"cost": 900.0,
		"cost_growth": 1.24,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": 1.0,
		"heat_optimum": 0.0,
		"heat_tolerance": 99.0,
		"unlock_depth": 5,
		"tags": ["amplify"],
		"amplify": 0.35,
	},
	"lab": {
		"name": "Lab",
		"desc": "Turns components into Research instead of credits. Research is the only thing that survives a collapse, so a board with no Lab is a board with no future.",
		"cost": 2600.0,
		"cost_growth": 1.22,
		"inputs": {Res.COMPONENT: 1},
		"outputs": {},
		"rate": 0.6,
		"heat_out": 0.3,
		"heat_optimum": 0.0,
		"heat_tolerance": 3.0,
		"unlock_depth": 6,
		"tags": ["research"],
		"research_per_cycle": 1.0,
	},
	"duplicator": {
		"name": "Duplicator",
		"desc": "A flat chance that anything passing through an adjacent machine comes out twice. Cheap to describe, very hard to place well.",
		"cost": 5200.0,
		"cost_growth": 1.26,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": 1.6,
		"heat_optimum": 0.0,
		"heat_tolerance": 99.0,
		"unlock_depth": 8,
		"tags": ["duplicate"],
		"duplicate_chance": 0.18,
	},
	"condenser": {
		"name": "Condenser",
		"desc": "Cools hard and amplifies weakly. The tile you place when you have run out of room to do both separately.",
		"cost": 9000.0,
		"cost_growth": 1.25,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": -3.4,
		"heat_optimum": 0.0,
		"heat_tolerance": 99.0,
		"unlock_depth": 10,
		"tags": ["cool", "amplify"],
		"amplify": 0.12,
	},
}

const ORDER := ["drill", "crusher", "vault", "smelter", "boiler", "coolant",
	"press", "assembler", "amplifier", "lab", "duplicator", "condenser"]


## --- economic models -------------------------------------------------------
##
## `MACHINES` above is the base recipe table. A model is a set of overrides on
## top of it, applied at load and then frozen.
##
## This exists because of a measurement, not a preference. With the base
## recipes, hand-built long production chains scored at the BOTTOM of the
## layout table while dense shallow boards won by up to nine times — which
## made the Press, Assembler, Lab and Condenser content that an optimising
## player would never build, and made "descend for a deeper chain" a promise
## the arithmetic did not keep.
##
## The cause is structural rather than numeric. A machine is fed only by the
## four cells it touches, and one of those is usually its own output, leaving
## three. When every refining step consumes TWO of the thing below it, the
## supply tree branches by two at every level while the space to attach it
## branches by three — so a chain deeper than about three steps cannot be fed
## at all, no matter how valuable its product is.
##
## So the models here are rule changes, not buffs, and which one ships was
## decided by running all of them through `tools/econ_lab.gd` against the same
## set of board archetypes. Keeping them all in the source means the next
## person to argue about the economy can re-run the comparison instead of
## arguing.

const MODELS := {
	# The original. Kept so the comparison can always be re-run.
	"base": {},

	# One input per cycle from the Smelter upwards, so a single adjacent
	# supplier is enough, and the value ladder flattened to match — with 1:1
	# conversions the old ladder would have made a five-tile chain worth
	# ninety-five times a drill.
	"linear": {
		"values": [1.0, 2.4, 5.4, 11.5, 24.0],
		"smelter": {"inputs": {Res.GRAVEL: 1}, "rate": 0.9},
		"press": {"inputs": {Res.INGOT: 1}, "rate": 0.8},
		"assembler": {"inputs": {Res.PLATE: 1}, "rate": 0.7},
		"lab": {"inputs": {Res.COMPONENT: 1}, "rate": 0.6},
	},

	# Between the two: the deep machines run warm, so a long chain has to be
	# cooled, but not so hot that building one stops being worth it.
	"linear_warm": {
		"values": [1.0, 2.4, 5.4, 11.5, 24.0],
		"smelter": {"inputs": {Res.GRAVEL: 1}, "rate": 0.9},
		"press": {"inputs": {Res.INGOT: 1}, "rate": 0.8, "heat_out": 1.1},
		"assembler": {"inputs": {Res.PLATE: 1}, "rate": 0.7, "heat_out": 1.5},
		"lab": {"inputs": {Res.COMPONENT: 1}, "rate": 0.6},
	},

	# The same again, but the deep machines run hot AND cannot take much heat.
	# Measured to over-correct: it put the long chain back below a shallow
	# board, which is the problem this whole exercise started from. Kept so
	# the comparison can be re-run.
	"linear_hot": {
		"values": [1.0, 2.4, 5.6, 12.5, 28.0],
		"smelter": {"inputs": {Res.GRAVEL: 1}, "rate": 0.9},
		"press": {"inputs": {Res.INGOT: 1}, "rate": 0.8,
			"heat_out": 1.6, "heat_tolerance": 2.0},
		"assembler": {"inputs": {Res.PLATE: 1}, "rate": 0.7,
			"heat_out": 2.2, "heat_optimum": 1.5, "heat_tolerance": 3.2},
		"lab": {"inputs": {Res.COMPONENT: 1}, "rate": 0.6},
	},

	# Ore stays cheap and plentiful — two ore into one gravel is the step that
	# teaches the ratio, and Drills are the one machine there is always room
	# for. Everything above it is one-for-one.
	"hybrid": {
		"values": [1.0, 3.0, 7.0, 15.0, 32.0],
		"press": {"inputs": {Res.INGOT: 1}, "rate": 0.8},
		"assembler": {"inputs": {Res.PLATE: 1, Res.GRAVEL: 1}, "rate": 0.7},
		"lab": {"inputs": {Res.COMPONENT: 1}, "rate": 0.6},
	},
}

## The model this build ships. Changed only with a measurement behind it.
const ACTIVE_MODEL := "linear_warm"

static var _active: Dictionary = {}
static var _active_values: Dictionary = {}
static var _active_name: String = ""


static func _build(model_name: String) -> void:
	var model: Dictionary = MODELS.get(model_name, {})
	var out: Dictionary = {}
	for id: String in MACHINES:
		var base: Dictionary = (MACHINES[id] as Dictionary).duplicate(true)
		var over: Variant = model.get(id, null)
		if typeof(over) == TYPE_DICTIONARY:
			for k: String in (over as Dictionary):
				base[k] = (over as Dictionary)[k]
		out[id] = base
	_active = out
	_active_values = RES_VALUE.duplicate()
	var vals: Variant = model.get("values", null)
	if typeof(vals) == TYPE_ARRAY:
		for i in range((vals as Array).size()):
			_active_values[i] = float((vals as Array)[i])
	_active_name = model_name


## Switch models. Used by `tools/econ_lab.gd` to compare them and by the tests
## that assert the shipped one is the shipped one. Anything holding a
## Dictionary returned by `get_machine` before the switch keeps the old one,
## which is why this rebuilds rather than mutating in place.
static func use_model(model_name: String) -> void:
	if not MODELS.has(model_name):
		push_error("unknown economic model: " + model_name)
		return
	_build(model_name)


static func model_name() -> String:
	if _active_name == "":
		_build(ACTIVE_MODEL)
	return _active_name


static func get_machine(id: String) -> Dictionary:
	if _active.is_empty():
		_build(ACTIVE_MODEL)
	return _active.get(id, {})


## What a unit of each resource sells for under the active model.
static func value_of(res: int) -> float:
	if _active_values.is_empty():
		_build(ACTIVE_MODEL)
	return float(_active_values.get(res, 0.0))


static func exists(id: String) -> bool:
	return MACHINES.has(id)


## "2 Ore -> 1 Gravel", built from the active model rather than written down.
##
## Hand-written recipe text is how a game ends up lying to its player: the
## table changes, the sentence does not, and the sentence is what they read.
## The flavour line in each machine's `desc` is allowed to be prose; this is
## the part that has to be true.
static func recipe_text(id: String) -> String:
	var m: Dictionary = get_machine(id)
	if m.is_empty():
		return ""
	var tags: Array = m.get("tags", [])
	if tags.has("sink"):
		return "Sells anything a neighbour hands it"
	var ins: Array[String] = []
	for res: int in (m.get("inputs", {}) as Dictionary):
		ins.append("%d %s" % [int(m["inputs"][res]), String(RES_NAME[res])])
	var outs: Array[String] = []
	for res: int in (m.get("outputs", {}) as Dictionary):
		outs.append("%d %s" % [int(m["outputs"][res]), String(RES_NAME[res])])
	if tags.has("research"):
		outs.append("Research")
	if ins.is_empty() and outs.is_empty():
		return "Changes what its neighbours do"
	if ins.is_empty():
		return "→ " + " + ".join(outs)
	if outs.is_empty():
		return " + ".join(ins) + " → nothing"
	return " + ".join(ins) + " → " + " + ".join(outs)


static func unlocked_at(depth: int) -> Array[String]:
	var out: Array[String] = []
	for id in ORDER:
		if int(get_machine(id)["unlock_depth"]) <= depth:
			out.append(id)
	return out


## Cost rises with how many of that machine you already own. Without this the
## optimal board is one machine type repeated, and the grid stops being a
## decision.
static func cost_for(id: String, owned: int) -> float:
	var m: Dictionary = get_machine(id)
	if m.is_empty():
		return INF
	return float(m["cost"]) * pow(float(m["cost_growth"]), float(owned))


## How fast a machine runs in a cell at a given heat.
##
## Deliberately a smooth curve rather than a threshold: a threshold makes the
## right answer discoverable by one experiment, a curve makes it worth tuning.
## Below optimum the machine is sluggish but functional; above tolerance it
## falls off hard, so overheating is a real failure and not a rounding error.
static func heat_efficiency(cell_heat: float, optimum: float, tolerance: float) -> float:
	var h: float = maxf(cell_heat, 0.0)
	if h <= optimum:
		# Cold side: never worse than 55%, so an unheated board still works.
		var t: float = 1.0 if optimum <= 0.0 else h / optimum
		return lerpf(0.55, 1.0, clampf(t, 0.0, 1.0))
	var over: float = h - optimum
	var span: float = maxf(tolerance - optimum, 0.001)
	if over <= span:
		# Comfortable band: full speed fading to 80% at the tolerance edge.
		return lerpf(1.0, 0.8, over / span)
	# Past tolerance the machine chokes. 1/(1+x^2) keeps it continuous and
	# never quite zero, so a player can always see it is still alive.
	var excess: float = (over - span) / span
	return 0.8 / (1.0 + excess * excess * 3.0)
