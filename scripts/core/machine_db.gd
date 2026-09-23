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
		"desc": "Two gravel into one ingot, and it genuinely wants to be hot. Build it a furnace. Then build the furnace a coolant loop.",
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
		"desc": "Two ingots into one plate. Hates heat, and by now your board is full of it.",
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
		"desc": "A plate and two gravel into one component. Wants two different inputs, so it wants to sit at a junction.",
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


static func get_machine(id: String) -> Dictionary:
	return MACHINES.get(id, {})


static func exists(id: String) -> bool:
	return MACHINES.has(id)


static func unlocked_at(depth: int) -> Array[String]:
	var out: Array[String] = []
	for id in ORDER:
		if int(MACHINES[id]["unlock_depth"]) <= depth:
			out.append(id)
	return out


## Cost rises with how many of that machine you already own. Without this the
## optimal board is one machine type repeated, and the grid stops being a
## decision.
static func cost_for(id: String, owned: int) -> float:
	var m: Dictionary = MACHINES.get(id, {})
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
