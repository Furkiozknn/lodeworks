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
		"short": "Digs ore out of the rock.",
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
		"short": "Crushes ore into gravel.",
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
		"short": "Sells anything it is given.",
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
		"short": "Melts gravel into ingots.",
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
		"short": "Warms the machines around it.",
		"desc": "Produces nothing. Heats everything around it, and lets material pass through. The first machine that is only worth placing because of what it is next to.",
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
		"short": "Cools the machines around it.",
		"desc": "Negative heat, and material still passes through it. Costs you a tile of production but never a connection.",
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
		"short": "Presses ingots into plates.",
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
		"short": "Builds plates into parts.",
		"desc": "The end of the chain, and the hottest thing on the board. A component is worth more than everything that went into it -- if you can keep this cool enough to make one.",
		"cost": 1400.0,
		"cost_growth": 1.20,
		"inputs": {Res.PLATE: 1, Res.GRAVEL: 2},
		"outputs": {Res.COMPONENT: 1},
		"rate": 0.7,
		"heat_out": 0.8,
		"heat_optimum": 1.5,
		"heat_tolerance": 4.0,
		"unlock_depth": 5,
		"tags": [],
	},
	"amplifier": {
		"name": "Amplifier",
		"short": "Speeds up the machines around it.",
		"desc": "Every working neighbour runs 35% faster, and the more of them it touches the harder it pushes. Ore passes straight through it.",
		"cost": 900.0,
		"cost_growth": 1.24,
		"inputs": {},
		"outputs": {},
		"rate": 1.0,
		"heat_out": 1.0,
		"heat_optimum": 0.0,
		"heat_tolerance": 99.0,
		"unlock_depth": 4,
		"tags": ["amplify"],
		"amplify": 0.35,
	},
	"lab": {
		"name": "Lab",
		"short": "Turns materials into research.",
		"desc": "Learns from whatever refined material its neighbours hand it -- a little from an Ingot, more from a Plate, most from a Component -- and turns it into Research instead of credits. What Research buys survives a collapse, so a board with no Lab is a board with no future.",
		"cost": 180.0,
		"cost_growth": 1.22,
		# Any one of these runs a cycle; `learns` is the research it gives.
		"inputs": {Res.INGOT: 1, Res.PLATE: 1, Res.COMPONENT: 1},
		"learns": {Res.INGOT: 0.25, Res.PLATE: 0.5, Res.COMPONENT: 1.0},
		"outputs": {},
		"rate": 0.6,
		"heat_out": 0.3,
		"heat_optimum": 0.0,
		"heat_tolerance": 3.0,
		"unlock_depth": 2,
		"tags": ["research"],
		"research_per_cycle": 1.0,
	},
	"duplicator": {
		"name": "Duplicator",
		"short": "Sometimes doubles what its neighbours make.",
		"desc": "A chance that a neighbour's output comes out twice, larger the more neighbours it serves. Material passes straight through it.",
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
		"short": "Cools the machines around it and speeds them up a little.",
		"desc": "Cools hard and amplifies weakly, and passes material through. The tile you place when you have run out of room to do both separately.",
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


## --- groups ------------------------------------------------------------------
##
## What a machine is for, as the player sorts the board in their head. The
## tray, the Codex and the unlock card all show these, with the same picture.
## A machine's group is read off what it does -- its tags and its recipe --
## so a new machine lands in the right one without anyone filing it.
enum Group { DIG, MAKE, SELL, HEAT, COOL, BOOST, RESEARCH }

const GROUPS := [
	{"id": "dig", "name": "Diggers", "icon": "descend",
		"short": "They dig ore out of the rock."},
	{"id": "make", "name": "Makers", "icon": "settings",
		"short": "They turn one thing into a better thing."},
	{"id": "sell", "name": "Sellers", "icon": "credits",
		"short": "They sell what they are given."},
	{"id": "heat", "name": "Heaters", "icon": "heat",
		"short": "They warm the machines around them."},
	{"id": "cool", "name": "Coolers", "icon": "cold",
		"short": "They cool the machines around them."},
	{"id": "boost", "name": "Boosters", "icon": "energy",
		"short": "They help the machines around them."},
	{"id": "research", "name": "Research", "icon": "research",
		"short": "It turns parts into research."},
]


static func group_of(id: String) -> int:
	var m: Dictionary = get_machine(id)
	var tags: Array = m.get("tags", [])
	if tags.has("source"):
		return Group.DIG
	if tags.has("sink"):
		return Group.SELL
	if tags.has("research"):
		return Group.RESEARCH
	if tags.has("cool"):
		return Group.COOL
	if tags.has("heat"):
		return Group.HEAT
	if tags.has("amplify") or tags.has("duplicate"):
		return Group.BOOST
	return Group.MAKE


## `ids`, grouped: every Digger, then every Maker, and so on, each group in
## the order its machines unlock.
static func by_group(ids: Array) -> Array[String]:
	var out: Array[String] = []
	for g in range(GROUPS.size()):
		for id in ORDER:
			if ids.has(id) and group_of(id) == g:
				out.append(id)
	return out


## Whether a machine wants warmth (1), wants to stay cool (-1), or does not
## much mind (0) -- read off its own heat curve.
static func heat_liking(id: String) -> int:
	var m: Dictionary = get_machine(id)
	if float(m.get("heat_optimum", 0.0)) >= 1.0:
		return 1
	if float(m.get("heat_tolerance", 99.0)) <= 3.0:
		return -1
	return 0


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
		"lab": {"rate": 0.6},
	},

	# Between the two: the deep machines run warm, so a long chain has to be
	# cooled, but not so hot that building one stops being worth it.
	"linear_warm": {
		"values": [1.0, 2.4, 5.4, 11.5, 24.0],
		"smelter": {"inputs": {Res.GRAVEL: 1}, "rate": 0.9},
		"press": {"inputs": {Res.INGOT: 1}, "rate": 0.8, "heat_out": 1.1},
		"assembler": {"inputs": {Res.PLATE: 1}, "rate": 0.7, "heat_out": 1.5},
		"lab": {"rate": 0.6},
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
		"lab": {"rate": 0.6},
	},

	# Ore stays cheap and plentiful — two ore into one gravel is the step that
	# teaches the ratio, and Drills are the one machine there is always room
	# for. Everything above it is one-for-one.
	"hybrid": {
		"values": [1.0, 3.0, 7.0, 15.0, 32.0],
		"press": {"inputs": {Res.INGOT: 1}, "rate": 0.8},
		"assembler": {"inputs": {Res.PLATE: 1, Res.GRAVEL: 1}, "rate": 0.7},
		"lab": {"rate": 0.6},
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
	# Not `_active.get(id, {})`: the default is built on every call, and this
	# is asked for every machine several times a tick.
	var m: Variant = _active.get(id)
	return NONE if m == null else m

## What get_machine answers for an id it does not know. Read-only.
const NONE := {}


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
		return Loc.t("Sells anything a neighbour hands it")
	var ins: Array[String] = []
	for res: int in (m.get("inputs", {}) as Dictionary):
		ins.append("%d %s" % [int(m["inputs"][res]), Loc.t(String(RES_NAME[res]))])
	var outs: Array[String] = []
	for res: int in (m.get("outputs", {}) as Dictionary):
		outs.append("%d %s" % [int(m["outputs"][res]), Loc.t(String(RES_NAME[res]))])
	if tags.has("research"):
		outs.append(Loc.t("Research"))
		return Loc.t("%s or %s") % [", ".join(ins.slice(0, ins.size() - 1)), ins[ins.size() - 1]] \
			+ " → " + " + ".join(outs)
	if ins.is_empty() and outs.is_empty():
		return Loc.t("Changes what its neighbours do")
	if ins.is_empty():
		return "→ " + " + ".join(outs)
	if outs.is_empty():
		return " + ".join(ins) + " → " + Loc.t("nothing")
	return " + ".join(ins) + " → " + " + ".join(outs)


## A machine's name, its one line and its full description, in the player's
## language. The table keeps the English; the English is the key.
static func name_of(id: String) -> String:
	return Loc.t(String(get_machine(id).get("name", id)))


static func short_of(id: String) -> String:
	return Loc.t(String(get_machine(id).get("short", "")))


static func desc_of(id: String) -> String:
	return Loc.t(String(get_machine(id).get("desc", "")))


## The stratum at which machine `id` is first found.
static func unlock_depth(id: String) -> int:
	return int(get_machine(id).get("unlock_depth", 0))


## --- machine levels ---------------------------------------------------------
##
## Every machine type has a level, for all machines of that type at once. A
## maker, digger or Lab runs faster by LEVEL_SPEED a level; the Vault's level
## is the factory's storage instead (`stock_cap`). The Factory Core's level
## caps both (CoreLevels.machine_cap), the way a central building caps what
## can be built under it, so "upgrade the Smelters" and "grow the Core" are
## one connected goal rather than two menus.
##
## A level is paid in credits -- LEVEL_PRICE for level 2, LEVEL_PRICE_GROWTH
## times dearer each level after, the same for every type, so a level is
## priced for the era it opens in -- and in materials from the Core's store
## (`level_materials`): a level 2 in Ingots, a level 3 in Plates and Ingots,
## a level 4 and up in Components and Plates. So upgrading a machine is a
## production problem, not a purchase: the Ingots come from a Smelter
## touching the Core, the store has to be big enough to hold them, and
## every old material keeps a use. The Vault's own levels cost
## VAULT_MATERIAL_SHARE of that, so the store it has always pays for the
## next one.
##
## The numbers were set by tools/core_journey.gd: at 25% a level for a
## sixth of the price, a played factory had every machine at its limit two
## minutes after each Core level and nothing left to do between them
## (docs/PROGRESSION.md, "Balance").
##
## Past level LATE_LEVEL_FROM a level costs LATE_LEVEL_GROWTH times the one
## before, not LEVEL_PRICE_GROWTH. Twelve times a level kept pace with the
## first eras, whose income grew about tenfold each (a new material, a new
## research line); measured, levels 3 to 6 cost 38 s, 47 s, 2 min and 12 min
## of the income of the era that opens them. From the Core's level 5 on,
## income grows about 1.4 times an era, and at twelve times a level 7 cost
## 1.7 hours of the Core 6 factory's income and a level 8 about fifteen:
## the credit wall of docs/PROGRESSION.md, "Core 7". At 3.5 times a level 7
## costs about half an hour of that income.
const LEVEL_SPEED := 0.1
const LEVEL_PRICE := 150.0
const LEVEL_PRICE_GROWTH := 12.0
const LATE_LEVEL_FROM := 6
const LATE_LEVEL_GROWTH := 3.5
const LEVEL_MATERIAL := 10.0
const LEVEL_MATERIAL_GROWTH := 3.0
const VAULT_MATERIAL_SHARE := 0.3
const LEVEL_TIERS := [Res.INGOT, Res.PLATE, Res.COMPONENT]

## What the Core's store keeps, and how much of each a Vault level holds:
## STOCK_BASE at level 1, STOCK_GROWTH times as much each level. It grows
## faster than LEVEL_MATERIAL_GROWTH, so a Vault's next level is always
## payable from the store its level before holds.
const STOCKED := [Res.INGOT, Res.PLATE, Res.COMPONENT]
const STOCK_BASE := 25.0
const STOCK_GROWTH := 3.2


## How much faster machines of a type run at `level`, with `drive`
## Overdrive steps, than at level 1.
static func level_speed(level: int, drive: int = 0) -> float:
	return 1.0 + LEVEL_SPEED * _steps(level, drive)


## A level and its Overdrive steps, as levels above the first.
static func _steps(level: int, drive: int) -> float:
	return float(maxi(level, 1) - 1) + OVERDRIVE_STEP * float(maxi(drive, 0))


## Credits to take machine type `id` from `to_level - 1` to `to_level`.
static func level_price(_id: String, to_level: int) -> float:
	var l: int = maxi(to_level, 2)
	return LEVEL_PRICE * pow(LEVEL_PRICE_GROWTH, float(mini(l, LATE_LEVEL_FROM) - 2)) \
		* pow(LATE_LEVEL_GROWTH, float(maxi(l - LATE_LEVEL_FROM, 0)))


## Materials to take machine type `id` to `to_level`: {res: count}.
static func level_materials(to_level: int, id: String = "") -> Dictionary:
	var step: int = maxi(to_level, 2) - 2
	var raw: float = LEVEL_MATERIAL * pow(LEVEL_MATERIAL_GROWTH, float(step))
	if id == "vault":
		raw *= VAULT_MATERIAL_SHARE
	var n: int = int(ceil(minf(raw, LEVEL_NUMBER_MAX)))
	var t: int = mini(step, LEVEL_TIERS.size() - 1)
	var out: Dictionary = {int(LEVEL_TIERS[t]): n}
	if t > 0:
		out[int(LEVEL_TIERS[t - 1])] = n
	return out


## How much of each stored material the Core's store holds with the Vault
## at `vault_level`. It grows faster than a level's materials, so every
## machine's level L fits a store at level L, and the Vault's own level L
## fits the store at L-1.
static func stock_cap(vault_level: int) -> int:
	return int(round(minf(STOCK_BASE * pow(STOCK_GROWTH, float(maxi(vault_level, 1) - 1)), LEVEL_NUMBER_MAX)))


## Where level numbers stop growing: past it a 64-bit count would wrap
## (found by CoreLevels.validate at the Core's level 36).
const LEVEL_NUMBER_MAX := 1.0e15


## Does machine type `id` have a level at all? A support machine works by
## where it stands, not by how fast it cycles.
static func has_levels(id: String) -> bool:
	var m: Dictionary = get_machine(id)
	if m.is_empty():
		return false
	var tags: Array = m.get("tags", [])
	if is_heat_support(id):
		return true
	return not ((m["inputs"] as Dictionary).is_empty() and (m["outputs"] as Dictionary).is_empty()
		and not tags.has("sink") and not tags.has("research"))


## Does a level make machine type `id` faster? Every levelled machine but the
## Vault, whose level is storage, and the heat supports, whose level is
## strength.
static func level_is_speed(id: String) -> bool:
	return has_levels(id) and not (get_machine(id).get("tags", []) as Array).has("sink") \
		and not is_heat_support(id)


## A machine that makes nothing and heats or cools its neighbours: the
## Boiler, the Coolant Cell, the Condenser.
static func is_heat_support(id: String) -> bool:
	var m: Dictionary = get_machine(id)
	if m.is_empty():
		return false
	var tags: Array = m.get("tags", [])
	return (tags.has("heat") or tags.has("cool")) and (m["inputs"] as Dictionary).is_empty() \
		and (m["outputs"] as Dictionary).is_empty()


## --- heat, by level and by mode -----------------------------------------------------
##
## Heat follows work (docs/PROGRESSION.md, "Heat"). A maker's heat rises
## with its level, HEAT_PER_LEVEL a level, as its speed does: an upgrade
## makes more and runs hotter. A heat support's level is its strength,
## SUPPORT_PER_LEVEL a level: an upgraded Coolant Cell cools more, and the
## Core's machine limit is also the limit on how much cooling a tile can
## give -- the Core that lets the shaft reach hotter rock lets its Coolant
## Cells answer it.
const HEAT_PER_LEVEL := 0.1
const SUPPORT_PER_LEVEL := 0.25


## How much of its table heat a machine of type `id` gives off at `level`,
## with `drive` Overdrive steps.
static func heat_factor(id: String, level: int, drive: int = 0) -> float:
	var step: float = _steps(level, drive)
	if is_heat_support(id):
		return 1.0 + SUPPORT_PER_LEVEL * step
	if level_is_speed(id):
		return 1.0 + HEAT_PER_LEVEL * step
	return 1.0


## --- Overdrive ------------------------------------------------------------------
##
## From the Factory Core's level OVERDRIVE_CORE, a machine type that has
## reached the level the Core before it allowed can be driven past it:
## OVERDRIVE_PER_CORE steps for every Core level from OVERDRIVE_CORE
## (CoreLevels.overdrive_cap). A step counts as OVERDRIVE_STEP of a level,
## for speed and for the heat that follows it -- a heat support's step is
## strength -- and it is paid in the old tiers from the Core's store (Ingots
## and Plates) and in research, never in credits. So the factory the Core 6
## era built keeps growing in the Core 7 era through what it makes rather
## than through what it sells: the store and the Labs have a job again, and
## the machines at the front of the old chain -- the Smelters and Presses
## touching the Core -- are what feeds it (docs/PROGRESSION.md, "Core 7";
## the feature pool's FP-12, from Clash of Clans' Supercharge).
const OVERDRIVE_CORE := 7
const OVERDRIVE_PER_CORE := 3
const OVERDRIVE_STEP := 0.5
const OVERDRIVE_MATERIAL := 4000.0
const OVERDRIVE_RESEARCH := 25000.0
## A Core level's steps cost STOCK_GROWTH times the last level's, as the
## store a Vault at the Core's limit holds grows: every step always fits.
const OVERDRIVE_GROWTH := 1.4736
const OVERDRIVE_TIERS := [Res.INGOT, Res.PLATE]


## Can machine type `id` be driven? Every levelled type but the Vault,
## whose level is storage.
static func can_overdrive(id: String) -> bool:
	return has_levels(id) and not (get_machine(id).get("tags", []) as Array).has("sink")


## What a type's Overdrive step `step` (1 for the first) costs:
## {"materials": {res: count}, "research": amount}.
static func overdrive_cost(step: int) -> Dictionary:
	var g: float = pow(OVERDRIVE_GROWTH, float(maxi(step, 1) - 1))
	var n: int = int(ceil(minf(OVERDRIVE_MATERIAL * g, LEVEL_NUMBER_MAX)))
	var mats: Dictionary = {}
	for res: int in OVERDRIVE_TIERS:
		mats[res] = n
	return {"materials": mats, "research": minf(OVERDRIVE_RESEARCH * g, LEVEL_NUMBER_MAX)}


## Modes: how hard one machine is run. A trade between output and heat the
## player sets per tile, opened by the Core's level MODES_CORE:
##   NORMAL  as built;
##   COOL    three quarters of the speed, half the heat of its own;
##   HOT     a quarter faster, sixty per cent more heat of its own.
## A Boiler can be run LOW (half its heat) -- the answer when the rock has
## grown hot enough that the Boiler a Smelter once needed now pushes its
## other neighbours past their safe range. A Coolant Cell or a Condenser
## has no mode: its level is its lever.
enum Mode { NORMAL, COOL, HOT }
const MODES_CORE := 3
const MODE_SPEED := {Mode.NORMAL: 1.0, Mode.COOL: 0.75, Mode.HOT: 1.25}
const MODE_HEAT := {Mode.NORMAL: 1.0, Mode.COOL: 0.5, Mode.HOT: 1.6}


## The modes machine type `id` can be run in.
static func modes_for(id: String) -> Array[int]:
	var m: Dictionary = get_machine(id)
	if m.is_empty():
		return [Mode.NORMAL]
	var tags: Array = m.get("tags", [])
	if tags.has("heat") and is_heat_support(id):
		return [Mode.NORMAL, Mode.COOL]
	if level_is_speed(id):
		return [Mode.NORMAL, Mode.COOL, Mode.HOT]
	return [Mode.NORMAL]


## The heat range machine type `id` works in at full measure: from the
## warmth it needs (a warm machine below it is slow) to its tolerance (past
## it, it chokes). `bonus` is research's tolerance bonus.
static func safe_range(id: String, bonus: float = 0.0) -> Vector2:
	var m: Dictionary = get_machine(id)
	var optimum: float = float(m.get("heat_optimum", 0.0))
	var low: float = 0.0
	if optimum > 0.0:
		# The cold side runs from COLD_FLOOR at no heat to 1 at the optimum.
		low = optimum * (WORKING_EFFICIENCY - COLD_FLOOR) / (1.0 - COLD_FLOOR)
	return Vector2(low, float(m.get("heat_tolerance", 99.0)) + bonus)


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
##
## The comfortable band -- from the optimum to the tolerance -- fades only to
## WORKING_EFFICIENCY, the warning key's own line, so a machine's safe range
## (`safe_range`) is exactly where it counts as working: one number for the
## player, not two. Until 25 September 2026 the band faded to 80%, so a
## machine that wants no heat stopped counting as working halfway to its
## tolerance, and the rock's heat alone put every Drill past that line from
## stratum 8 while none of them was anywhere near overheating
## (tools/heat_lab.gd; docs/PROGRESSION.md, "Heat").
const WORKING_EFFICIENCY := 0.9
const COLD_FLOOR := 0.55

static func heat_efficiency(cell_heat: float, optimum: float, tolerance: float) -> float:
	var h: float = maxf(cell_heat, 0.0)
	if h <= optimum:
		# Cold side: never worse than COLD_FLOOR, so an unheated board works.
		var t: float = 1.0 if optimum <= 0.0 else h / optimum
		return lerpf(COLD_FLOOR, 1.0, clampf(t, 0.0, 1.0))
	var over: float = h - optimum
	var span: float = maxf(tolerance - optimum, 0.001)
	if over <= span:
		# Comfortable band: full speed fading to the working line at the
		# tolerance edge.
		return lerpf(1.0, WORKING_EFFICIENCY, over / span)
	# Past tolerance the machine chokes. 1/(1+x^2) keeps it continuous and
	# never quite zero, so a player can always see it is still alive.
	var excess: float = (over - span) / span
	return WORKING_EFFICIENCY / (1.0 + excess * excess * 3.0)
