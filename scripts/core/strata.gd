class_name Strata
extends RefCounted

## The descent, and where most of the game's content actually comes from.
##
## A stratum is three numbers (richness, ambient heat, quota) plus up to two
## modifiers drawn from a table. Twelve modifiers taken two at a time is 78
## combinations before richness and heat vary at all, and each combination
## genuinely changes which layout is correct -- a board tuned for "Thermal
## Vent + Brittle" is the wrong board for "Coolant Seep + Dense".
##
## That is the whole reason this genre was chosen: one more row in MODIFIERS is
## one more row of work and a much larger multiple of gameplay. Compare that to
## a match-3, where one more level is one more level.
##
## Generation is seeded by depth, so every player descending to stratum 14 sees
## the same stratum 14. That makes the run discussable -- players can compare
## layouts for a named depth -- and it means no server is involved in anything.

const AMBIENT_PER_DEPTH := 0.18
const RICHNESS_PER_DEPTH := 0.22

## Each modifier is a small, legible rule. Nothing here is a flat "+10% to
## everything": every one of them should make you want to move a tile.
const MODIFIERS := {
	"thermal_vent": {
		"name": "Thermal Vent",
		"desc": "Ambient heat +2. Your smelters will love it. Your presses will not.",
		"ambient_heat": 2.0,
	},
	"coolant_seep": {
		"name": "Coolant Seep",
		"desc": "Ambient heat -1.5. Hot machines need their own boilers down here.",
		"ambient_heat": -1.5,
	},
	"brittle": {
		"name": "Brittle Rock",
		"desc": "Drills run 35% faster, but everything downstream runs 15% slower.",
		"source_speed": 1.35,
		"process_speed": 0.85,
	},
	"dense": {
		"name": "Dense Seam",
		"desc": "Everything you sell is worth 45% more. Worth building a bigger line for.",
		"value": 1.45,
	},
	"unstable": {
		"name": "Unstable",
		"desc": "Buffers hold 2 fewer items. Long chains choke; short ones are fine.",
		"buffer_delta": -2,
	},
	"conductive": {
		"name": "Conductive Strata",
		"desc": "Heat spreads further. Every heat decision you make is louder.",
		"heat_spread": 0.85,
	},
	"insulating": {
		"name": "Insulating Clay",
		"desc": "Heat barely spreads. Boilers only help the tile they touch.",
		"heat_spread": 0.2,
	},
	"rich_vein": {
		"name": "Rich Vein",
		"desc": "Drills yield double. The bottleneck moves to whatever you built next.",
		"source_yield": 2.0,
	},
	"academic": {
		"name": "Fossil Record",
		"desc": "Labs produce 80% more research. A depth worth stopping at.",
		"research": 1.8,
	},
	"cramped": {
		"name": "Cramped",
		"desc": "The outer ring of the shaft is collapsed and cannot be built on.",
		"cramped": true,
	},
	"resonant": {
		"name": "Resonant",
		"desc": "Amplifiers are twice as strong. Suddenly they are worth the heat.",
		"amplify": 2.0,
	},
	"barren": {
		"name": "Barren",
		"desc": "Half the ore, but the quota to move on is halved too. A breather.",
		"source_yield": 0.5,
		"quota": 0.5,
	},
}

const MODIFIER_IDS := ["thermal_vent", "coolant_seep", "brittle", "dense",
	"unstable", "conductive", "insulating", "rich_vein", "academic",
	"cramped", "resonant", "barren"]


## The quota curve. Deliberately super-linear but not brutal: the first few
## strata should fall in a single session so the player learns the loop, and by
## depth 20 a descent should be an evening's project rather than a tap.
static func quota_for(depth: int) -> float:
	if depth <= 0:
		return 60.0
	return 60.0 * pow(1.55, float(depth)) + 40.0 * float(depth)


static func modifiers_for(depth: int) -> Array[String]:
	# Depth 0 is always clean. A first-time player meeting "Cramped" before
	# they have placed a drill would learn the wrong lesson about the game.
	if depth <= 0:
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lodeworks-stratum-%d" % depth)
	var count: int = 1 if depth < 4 else (2 if rng.randf() < 0.55 else 1)
	var pool: Array[String] = []
	for id: String in MODIFIER_IDS:
		pool.append(id)
	var out: Array[String] = []
	for _k in range(count):
		if pool.is_empty():
			break
		var pick: int = rng.randi_range(0, pool.size() - 1)
		out.append(pool[pick])
		pool.remove_at(pick)
	return out


static func describe(depth: int) -> Dictionary:
	var mods: Array[String] = modifiers_for(depth)
	var d: Dictionary = {
		"depth": depth,
		"name": "Stratum %d" % depth,
		"quota": quota_for(depth),
		"richness": 1.0 + RICHNESS_PER_DEPTH * float(depth),
		"ambient_heat": AMBIENT_PER_DEPTH * float(depth),
		"modifiers": mods,
		"source_speed": 1.0,
		"process_speed": 1.0,
		"source_yield": 1.0,
		"value": 1.0,
		"research": 1.0,
		"amplify": 1.0,
		"heat_spread": MachineDB.HEAT_SPREAD,
		"buffer_delta": 0,
		"cramped": false,
	}
	for id in mods:
		var m: Dictionary = MODIFIERS[id]
		for k: String in m:
			if k in ["name", "desc"]:
				continue
			if k == "ambient_heat":
				d["ambient_heat"] = float(d["ambient_heat"]) + float(m[k])
			elif k == "buffer_delta":
				d["buffer_delta"] = int(d["buffer_delta"]) + int(m[k])
			elif k == "cramped":
				d["cramped"] = true
			elif k == "heat_spread":
				d["heat_spread"] = float(m[k])
			elif k == "quota":
				d["quota"] = float(d["quota"]) * float(m[k])
			else:
				d[k] = float(d.get(k, 1.0)) * float(m[k])
	d["ambient_heat"] = maxf(float(d["ambient_heat"]), 0.0)
	return d


## Cells that cannot be built on at this depth. Returned as a set so the grid
## and the UI can both ask cheaply.
static func blocked_cells(depth: int) -> Dictionary:
	var out: Dictionary = {}
	if not bool(describe(depth)["cramped"]):
		return out
	for x in range(Grid.W):
		for y in range(Grid.H):
			if x == 0 or y == 0 or x == Grid.W - 1 or y == Grid.H - 1:
				out[Grid.idx(x, y)] = true
	return out


static func modifier_name(id: String) -> String:
	return String(MODIFIERS.get(id, {}).get("name", id))


static func modifier_desc(id: String) -> String:
	return String(MODIFIERS.get(id, {}).get("desc", ""))
