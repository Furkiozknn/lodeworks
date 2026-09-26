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
## Credits it costs to leave a stratum. It grows 1.8x a stratum; it was
## 1.55x until 24 September 2026. The journey lab's player measured the old
## curve getting faster, not slower, past the first strata: 17 to 47 seconds
## each for strata 8 to 12. At 1.8x the first strata take two to three
## minutes, the middle three to four, and from stratum 9 five minutes and
## more (docs/AUDIT.md, "Descend: the pace").
##
## From DEEP_QUOTA_FROM it grows DEEP_QUOTA_GROWTH a stratum. Past stratum
## 20 the Core's level caps the descent, five strata an era, and income
## grows about 1.2-1.5 times an era, not 1.8 times a stratum: measured, the
## way from stratum 24 to 29 that Core 10 asks for cost 1.8B credits at 1.8
## times, eighteen hours of the Core 9 factory's income (docs/PROGRESSION.md,
## "Core 10"). At 1.1 times it is 68M, about forty minutes of it.
const DEEP_QUOTA_FROM := 20
const DEEP_QUOTA_GROWTH := 1.1


static func quota_for(depth: int) -> float:
	if depth <= 0:
		return 60.0
	if depth > DEEP_QUOTA_FROM:
		return quota_for(DEEP_QUOTA_FROM) * pow(DEEP_QUOTA_GROWTH, float(depth - DEEP_QUOTA_FROM))
	return 60.0 * pow(1.8, float(depth)) + 40.0 * float(depth)


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


## How much crystal the rock holds for a Deep Bore (MachineDB.JOBS): none
## above MachineDB.CRYSTAL_DEPTH, then more with every stratum -- so the deep
## chain pays more the deeper the shaft goes, as the old one pays less.
static func vein(depth: int) -> float:
	if depth < MachineDB.CRYSTAL_DEPTH:
		return 0.0
	return 1.0 + MachineDB.VEIN_GROWTH * float(depth - MachineDB.CRYSTAL_DEPTH)


static func describe(depth: int) -> Dictionary:
	return _describe(depth, modifiers_for(depth))


## A stratum at `depth` with the modifiers `mods`: describe(), and the same
## rock with only some of its rules for effects_on().
static func _describe(depth: int, mods: Array[String]) -> Dictionary:
	var d: Dictionary = {
		"depth": depth,
		"name": "Stratum %d" % depth,
		"quota": quota_for(depth),
		"richness": 1.0 + RICHNESS_PER_DEPTH * float(depth),
		"vein": vein(depth),
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


static var _blocked_cache: Dictionary = {}


## Cells that cannot be built on at this depth. Returned as a set so the grid
## and the UI can both ask cheaply.
static func blocked_cells(depth: int) -> Dictionary:
	if _blocked_cache.has(depth):
		return _blocked_cache[depth]
	var out: Dictionary = {}
	if bool(describe(depth)["cramped"]):
		# Cramped: the outermost ring of the yard caves in -- the edge of the
		# ground the factory has, wherever that edge is by now (BuildArea).
		var r: int = BuildArea.radius_at(depth)
		for i in range(Grid.W * Grid.H):
			if not BuildArea.is_core(i) and BuildArea.reach(i) == r:
				out[i] = true
	# Asked for every tile, many times a frame; the answer only depends on
	# the depth.
	_blocked_cache[depth] = out
	return out


## Point a Simulation at a stratum. The ONLY place a stratum is applied.
##
## This exists because of a bug it would have prevented. Nine files -- the
## game, five measurement tools and three test files -- each built a
## Simulation from a stratum by hand, copying six assignments. Two of the
## stratum's fields were therefore never assigned anywhere except in the
## dictionary that produced them:
##
##   * `source_speed`, which Brittle Rock sets to 1.35, was read by nobody, so
##     "Drills run 35% faster, but everything downstream runs 15% slower" was
##     a pure 15% penalty. Measured: Brittle scored below a clean stratum in
##     all 32 board-by-condition cells of `tools/strategy_lab.gd`.
##   * `amplify`, which Resonant Strata sets to 2.0, was read by nobody, so
##     "Amplifiers are twice as strong" changed nothing. Measured: identical
##     to the last credit against a clean stratum, on every board including
##     one built entirely around Amplifiers.
##
## Both were copy-paste omissions rather than mistakes in reasoning, which is
## exactly the failure a single entry point removes. A new stratum field is
## now wired in one place or in none.
## The one way a simulation is set up for a stratum, from the stratum and
## the research multipliers.
static func apply(sim: Simulation, grid: Grid, st: Dictionary,
		mu: Dictionary) -> void:
	if grid != null:
		grid.set_environment(float(st["ambient_heat"]), float(st["heat_spread"]))
	sim.speed_mult = float(mu.get("speed", 1.0)) * float(st["process_speed"])
	sim.source_speed_mult = float(st["source_speed"])
	# Resonant Frames scales every Booster's boost, the stratum's own
	# modifier with it.
	sim.amplify_mult = float(st["amplify"]) * float(mu.get("resonance", 1.0))
	sim.duplicate_mult = float(mu.get("resonance", 1.0))
	sim.yield_mult = float(mu.get("yield", 1.0)) * float(st["source_yield"]) \
		* float(st["richness"])
	sim.value_mult = float(mu.get("value", 1.0)) * float(st["value"])
	sim.research_mult = float(mu.get("research", 1.0)) * float(st["research"])
	sim.tolerance_bonus = float(mu.get("tolerance", 0.0))
	sim.vein_mult = float(st.get("vein", 0.0)) * float(mu.get("vein", 1.0))
	# A doctrine's research on single materials (Economy.DOCTRINES).
	var fine: float = float(mu.get("fine_value", 1.0))
	sim.res_value_mult = {} if fine == 1.0 else {MachineDB.Res.FRAME: fine, MachineDB.Res.COMPONENT: fine}
	var learn: float = float(mu.get("deep_learn", 1.0))
	sim.res_learn_mult = {} if learn == 1.0 else {MachineDB.Res.ALLOY: learn, MachineDB.Res.FRAME: learn}
	sim.buffer_cap = maxi(Simulation.BUF_CAP + int(st["buffer_delta"]), 1)


## How this stratum's rock treats machine `id` standing on it: 1 when it
## works faster, yields more or earns more here than on plain rock at the
## same depth (by NOTICEABLE or more), -1 when less, 0 otherwise. The tray shows
## it as an arrow on the machine's key. Only what the machine does itself
## counts; a rule that changes the whole board (Unstable, Cramped, how far
## heat spreads) gives no machine an arrow.
static func effect_on(id: String, st: Dictionary) -> int:
	var f: float = _factor(id, st)
	if f >= 1.0 + NOTICEABLE:
		return 1
	if f <= 1.0 - NOTICEABLE:
		return -1
	return 0


## Less than this, and a rule is not worth an arrow: a 2% change on a key
## would be noise the player learns to ignore.
const NOTICEABLE := 0.05


## The rules of stratum `depth` that move machine `id`, each with its sign:
## [[modifier id, 1 or -1], ...]. The words on a tray key's "?".
static func effects_on(id: String, depth: int) -> Array:
	var out: Array = []
	for mod: String in modifiers_for(depth):
		var only: Array[String] = [mod]
		var e: int = effect_on(id, _describe(depth, only))
		if e != 0:
			out.append([mod, e])
	return out


## What `apply` does to one machine alone on this rock, as a single factor
## against plain rock at the same depth: its speed, its yield, what it
## sells or researches, and the heat of its own tile (the rock's, plus its
## own, as Grid adds them).
static func _factor(id: String, st: Dictionary) -> float:
	var m: Dictionary = MachineDB.get_machine(id)
	if m.is_empty():
		return 1.0
	var tags: Array = m.get("tags", [])
	var passive: bool = (m["inputs"] as Dictionary).is_empty() \
		and (m["outputs"] as Dictionary).is_empty() \
		and not tags.has("sink") and not tags.has("research")
	if passive:
		# A tile that works by existing: only a stronger push changes it.
		return float(st["amplify"]) if tags.has("amplify") else 1.0
	var f: float = float(st["process_speed"])
	if tags.has("source"):
		f *= float(st["source_speed"]) * float(st["source_yield"])
	if tags.has("sink"):
		f *= float(st["value"])
	if tags.has("research"):
		f *= float(st["research"])
	var own: float = float(m.get("heat_out", 0.0))
	var opt: float = float(m["heat_optimum"])
	var tol: float = float(m["heat_tolerance"])
	var plain: float = MachineDB.heat_efficiency(
		maxf(AMBIENT_PER_DEPTH * float(st["depth"]) + own, 0.0), opt, tol)
	if plain > 0.0:
		f *= MachineDB.heat_efficiency(maxf(float(st["ambient_heat"]) + own, 0.0), opt, tol) / plain
	return f


## A rule's name and words, in the player's language.
static func modifier_name(id: String) -> String:
	return Loc.t(String(MODIFIERS.get(id, {}).get("name", id)))


static func modifier_desc(id: String) -> String:
	return Loc.t(String(MODIFIERS.get(id, {}).get("desc", "")))
