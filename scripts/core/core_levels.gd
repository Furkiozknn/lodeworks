class_name CoreLevels
extends RefCounted

## The Factory Core's levels: the spine of a shaft's progression.
##
## A level of the Core is not bought with a number. Each one asks the factory
## to have grown in several connected ways at once, and each one opens the
## next era: deeper strata (and the machines and materials found there), a
## higher limit for machine levels (the Vault's among them, which is the
## factory's storage), and new research lines. docs/PROGRESSION.md is the
## design and the reference study behind it.
##
## Every requirement is read from the running factory, never from a checklist
## of its own:
##   CREDITS   paid when the Core grows.
##   STOCK     material in the Core's store, paid when it grows. Only a
##             machine touching the Core hands it anything (Simulation core
##             intake), and the store holds only what the Vault's level
##             allows (MachineDB.stock_cap) -- so a level that asks for more
##             than the store holds asks for a Vault upgrade first.
##   WORKING   machines of a type RUNNING at their working heat (the warning
##             key's own threshold).
##   MACHINE   the level a machine type has been upgraded to; a level is paid
##             in credits and in materials from the store.
##   DEPTH     the deepest stratum of this shaft.
##   RESEARCH  a research line's level (Labs learn from Ingots, Plates and
##             Components). A line opens at a Core level and its levels are
##             capped by the Core (Economy.research_cap).
##   SERVES    what the best support machine of a type stands beside.
##   STABLE    machines running at their working heat while none overheats.
##   OVERDRIVE the Overdrive steps a machine type has been driven (from the
##             Core's level MachineDB.OVERDRIVE_CORE; paid in store
##             materials and research).
##   DOCTRINE  levels bought in the lines of the doctrine this shaft follows
##             (Economy.DOCTRINES, from the Core's level DOCTRINE_CORE) --
##             whichever it is: the row asks for a strategy, not for one.
##   REGIONS   regions of the deep map this shaft has opened (Operations,
##             "regions", from Operations.REGION_CORE) -- whichever they
##             are: the row asks for the world to be explored, not where.
##   REGION_LINES levels bought in the lines the open regions' research
##             opens -- whichever region's: the research path follows the
##             map.
##   ROLES     the crew with at least that many of each kind: Rigs,
##             Breakers and Surveyors.
##   BEACONS   Beacons burning (Operations, "Beacons") -- in whichever
##             regions: the row asks for ground held, not which.
##   TECH      levels bought in the Works' lines (Economy.WORKS) -- the
##             factory's or the crew's, whichever: the row asks for the
##             research the Frames made to have gone somewhere, not where.
##
## The graph has no cycles by construction -- everything level L asks for is
## possible at level L-1 -- and `validate()` checks it, with every
## requirement's reachability, storage and research limit, so a level can
## never ask for the impossible.

enum Req { CREDITS, STOCK, WORKING, MACHINE, DEPTH, RESEARCH, SERVES, STABLE, OVERDRIVE, DOCTRINE,
	OPERATIONS, REGIONS, REGION_LINES, ROLES, BEACONS, TECH }

## A support machine touches four machines at most (Grid.serves).
const MAX_SERVES := 4

## Level 1 is where a shaft starts. Each entry is the level it describes:
## what the factory must show to reach it (from the level before), and what
## it opens. `depth_cap`: the deepest stratum a Core of this level lets the
## shaft go down to. `machine_cap`: the highest level any machine type -- the
## Vault too -- may be upgraded to under it.
const LEVELS := [
	{"level": 1, "era": "Extraction", "depth_cap": 2, "machine_cap": 2, "requires": []},
	{"level": 2, "era": "Processing", "depth_cap": 4, "machine_cap": 3, "requires": [
		[Req.CREDITS, 1000.0],
		[Req.STOCK, MachineDB.Res.INGOT, 40],
		[Req.WORKING, "smelter", 2],
		[Req.MACHINE, "crusher", 2],
		[Req.RESEARCH, "throughput_1", 1],
		[Req.DEPTH, 2],
	]},
	{"level": 3, "era": "Fabrication", "depth_cap": 6, "machine_cap": 4, "requires": [
		[Req.CREDITS, 60000.0],
		[Req.STOCK, MachineDB.Res.PLATE, 250],
		[Req.STOCK, MachineDB.Res.INGOT, 250],
		[Req.WORKING, "press", 2],
		[Req.MACHINE, "smelter", 3],
		[Req.RESEARCH, "yield_1", 2],
		[Req.RESEARCH, "throughput_1", 3],
		[Req.DEPTH, 4],
		# The first gallery, open since Core 2 to the Foreman's Rig: one
		# site cleared (docs/GAME-LOOP.md, section 1).
		[Req.OPERATIONS, 1],
	]},
	{"level": 4, "era": "Assembly", "depth_cap": 9, "machine_cap": 5, "requires": [
		[Req.CREDITS, 1200000.0],
		[Req.STOCK, MachineDB.Res.COMPONENT, 800],
		[Req.STOCK, MachineDB.Res.PLATE, 800],
		[Req.WORKING, "assembler", 3],
		[Req.MACHINE, "press", 4],
		[Req.MACHINE, "drill", 4],
		[Req.SERVES, "amplifier", 3],
		[Req.RESEARCH, "value_1", 2],
		[Req.RESEARCH, "yield_1", 4],
		[Req.DEPTH, 6],
	]},
	# Cores 5 and 6 as Core 7 is (docs/PROGRESSION.md, "Cores 5 and 6"):
	# played, their other rows were met 8 and 16 minutes into the stage and
	# the rest -- 36 minutes and 2 h 42 min -- was saving for 10M and 60M.
	# Their prices are now what the factory earns while it does the rest,
	# and each research row asks for a level the era before could not buy
	# (Tighter Tolerances 6 and 8 had been open since Cores 3 and 4).
	{"level": 5, "era": "Research", "depth_cap": 12, "machine_cap": 6, "requires": [
		[Req.CREDITS, 2000000.0],
		[Req.STOCK, MachineDB.Res.COMPONENT, 2500],
		[Req.STOCK, MachineDB.Res.PLATE, 2500],
		[Req.WORKING, "lab", 4],
		[Req.MACHINE, "assembler", 5],
		[Req.RESEARCH, "research_1", 2],
		[Req.RESEARCH, "value_1", 4],
		[Req.STABLE, 40],
		[Req.DEPTH, 9],
		# The crew Core 4 opens, sent out: sites in the galleries cleared
		# (Operations; docs/GAME-LOOP.md). Three were cleared two minutes
		# into the stage; five take the crew's repairs and a harder site.
		[Req.OPERATIONS, 5],
	]},
	{"level": 6, "era": "Amplification", "depth_cap": 15, "machine_cap": 7, "requires": [
		[Req.CREDITS, 3000000.0],
		[Req.STOCK, MachineDB.Res.COMPONENT, 8000],
		[Req.STOCK, MachineDB.Res.INGOT, 8000],
		[Req.SERVES, "duplicator", 3],
		[Req.SERVES, "condenser", 2],
		[Req.RESEARCH, "research_1", 4],
		[Req.MACHINE, "drill", 6],
		[Req.STABLE, 60],
		[Req.DEPTH, 12],
	]},
	# The Core 6 era's factory, grown in every direction the Core 7 era
	# needs (docs/PROGRESSION.md, "Core 7"): the Component chain at the
	# Core 6 limit and running on hot rock; the cooling the rock of strata
	# 16-19 asks for; a store for what Overdrive is paid in; the
	# Amplification era's research; the whole factory under control. Most
	# of the stage's credits go into the levels it asks for; the Core's own
	# price is what the factory earns in the half hour or so after its other
	# rows are met (measured: docs/PROGRESSION.md, "Core 7") -- never the
	# requirement itself.
	{"level": 7, "era": "Deep works", "depth_cap": 19, "machine_cap": 8, "requires": [
		[Req.CREDITS, 15000000.0],
		[Req.STOCK, MachineDB.Res.COMPONENT, 25000],
		[Req.STOCK, MachineDB.Res.PLATE, 25000],
		[Req.MACHINE, "assembler", 7],
		[Req.MACHINE, "coolant", 7],
		[Req.RESEARCH, "resonance", 2],
		[Req.SERVES, "condenser", 3],
		[Req.STABLE, 80],
		[Req.DEPTH, 15],
	]},
	# The Core 7 era's work, as played (docs/PROGRESSION.md, "After Core
	# 7"): the deep chain into the store -- Alloy, made at white heat from
	# the crystal of strata 16 and down -- with the old chain still feeding
	# it Components; the Smelters that make it driven and levelled; the
	# doctrine the shaft chose; the whole factory under control on the
	# hottest rock yet.
	{"level": 8, "era": "The Abyss", "depth_cap": 24, "machine_cap": 9, "requires": [
		[Req.CREDITS, 40000000.0],
		[Req.STOCK, MachineDB.Res.ALLOY, 25000],
		[Req.STOCK, MachineDB.Res.COMPONENT, 50000],
		[Req.OVERDRIVE, "smelter", 3],
		[Req.DOCTRINE, 4],
		[Req.MACHINE, "smelter", 8],
		[Req.STABLE, 100],
		[Req.DEPTH, 19],
	]},
	# The Core 8 era's work, as played (docs/PROGRESSION.md, "Core 9"): the
	# Frame the Core's level 8 opens becomes the store's row, as a newly
	# opened building does in the reference games; a store past the Vault's
	# limit (a Vault at level 9, paid in Alloy); the Frame Jig's machine
	# driven; the doctrine taken further; the whole factory under control on
	# the hottest rock yet. Its levels -- the Vault's 9 and the Assembler's 8
	# -- are most of the stage's credits, so the Core's own price is what the
	# factory earns in about half an hour. The first design also asked for
	# Drill 9: two levels, as no Core had asked for Drill 8, and with the
	# Core at 160M, 500M of credits in all.
	{"level": 9, "era": "The Forge", "depth_cap": 29, "machine_cap": 10, "requires": [
		[Req.CREDITS, 60000000.0],
		[Req.STOCK, MachineDB.Res.FRAME, 30000],
		[Req.STOCK, MachineDB.Res.ALLOY, 100000],
		[Req.OVERDRIVE, "assembler", 4],
		[Req.DOCTRINE, 8],
		[Req.STABLE, 120],
		[Req.DEPTH, 24],
	]},
	# The Core 9 era's work (docs/PROGRESSION.md, "Core 10"): the Assay
	# Bench Core 9 opens, put to work; the Frame line grown to a store no
	# Vault 9 holds, while the Benches take Frames too -- so the Frames are
	# shared between the Core's store and the research; the Frame Jig's
	# machine driven further; one more doctrine level, of the twelve the
	# shaft may have, so which line is the shaft's choice; the whole factory
	# under control on stratum 27, the insulating one. Strata 26, 28 and 29
	# are conductive -- heat spreads 85% -- and there a levelled White Heat
	# Smelter pushes the Deep Bore, Vault and Assay Bench beside it past
	# their safe range: played to stratum 29, the factory's income fell from
	# 22.5K/s to 11.4K/s as the player tore down what overheated (1,966
	# machines sold in 7 h 46 min, and Core 10 not reached). Going below
	# 27 for richer crystal is the player's choice, at that price. Played on
	# 27 with six Assay Benches and stable 140 asked, the factory held 101 at
	# best and kept three Benches at work in 8 h 46 min, every other row met
	# by 4 h 14 min: the rows ask for four and 130. The
	# formula this level had asked for Crusher 10 and nine Overdrive steps:
	# 521M credits and 1.7M research.
	{"level": 10, "era": "The Frontier", "depth_cap": 34, "machine_cap": 11, "requires": [
		[Req.CREDITS, 50000000.0],
		[Req.STOCK, MachineDB.Res.FRAME, 300000],
		[Req.WORKING, "lab", 4, "assay"],
		[Req.OVERDRIVE, "assembler", 7],
		[Req.DOCTRINE, 9],
		[Req.STABLE, 130],
		[Req.DEPTH, 27],
	]},
	# The Core 10 era is the deep map's (docs/GAME-LOOP.md, section 12):
	# not more of the Core 9 era's rows, each a new kind of work -- the
	# world explored (a region opened by an expedition), the new chain run
	# (Lenses, ground from the Resonite the crew brings home, in the store),
	# the research the region opened (whichever region), a crew of three
	# kinds, and the price. Which region, which research and which crew are
	# the shaft's choice; the row asks that there is one.
	{"level": 11, "era": "The Expedition", "depth_cap": 39, "machine_cap": 12, "requires": [
		[Req.CREDITS, 75000000.0],
		[Req.STOCK, MachineDB.Res.LENS, 4000],
		[Req.REGIONS, 1],
		[Req.REGION_LINES, 2],
		[Req.ROLES, 2],
	]},
	# Core 11 lights Beacons (Operations, "Beacons"); its era's rows hold the
	# ground: one Beacon burning, a second region, its research, a crew of
	# three of each kind, a second Lens Grinder at work, and the price.
	# Measured before it: the formula asked Core 11's rows again, with the
	# Lens row a formality (a new game held 191,000 Lenses at Core 12); the
	# Lenses now go to the Beacons.
	{"level": 12, "era": "The Beacons", "depth_cap": 44, "machine_cap": 13, "requires": [
		[Req.CREDITS, 113000000.0],
		[Req.WORKING, "assembler", 2, "lens"],
		[Req.REGIONS, 2],
		[Req.BEACONS, 1],
		[Req.REGION_LINES, 4],
		[Req.ROLES, 3],
	]},
	# Core 12 opens the Dark Reach to a shaft with two Beacons burning; its
	# era's rows are the Reach's: Prisms cut from its Umbrite and two Lenses
	# each, two Beacons kept lit, a third region, the regions' research the
	# Beacons let go further, a crew of four of each kind.
	{"level": 13, "era": "The Dark Reach", "depth_cap": 49, "machine_cap": 14, "requires": [
		[Req.CREDITS, 170000000.0],
		[Req.STOCK, MachineDB.Res.PRISM, 2000],
		[Req.REGIONS, 3],
		[Req.BEACONS, 2],
		[Req.REGION_LINES, 6],
		[Req.ROLES, 4],
	]},
	# The Core 13 era's rows are the research the Frames make and what it is
	# spent on (docs/GAME-LOOP.md, section 14): six Assay Benches at work,
	# three levels of the Works (the factory's or the crew's, whichever), and
	# the map finished -- all four regions open, the regions' research the
	# Beacons let go further, a third Beacon, the price. Measured before it:
	# the formula asked Core 13's rows again, grown, and the regions' research
	# alone held four of nine stages while the Assay Benches stood idle most
	# of the time.
	{"level": 14, "era": "The Works", "depth_cap": 54, "machine_cap": 15, "requires": [
		[Req.CREDITS, 255000000.0],
		[Req.WORKING, "lab", 6, "assay"],
		[Req.TECH, 3],
		[Req.REGIONS, 4],
		[Req.REGION_LINES, 8],
		[Req.BEACONS, 3],
	]},
	# Core 14's rows grown in each direction at once -- more Benches, more of
	# the Works, every region held -- and the heat of a factory that big under
	# control.
	{"level": 15, "era": "The Deep Works", "depth_cap": 59, "machine_cap": 16, "requires": [
		[Req.CREDITS, 380000000.0],
		[Req.WORKING, "lab", 8, "assay"],
		[Req.TECH, 6],
		[Req.REGION_LINES, 10],
		[Req.BEACONS, 4],
		[Req.STABLE, 150],
	]},
]

## From this level the Core sells what its store has no room for, at
## EXPORT_SHARE of what a Vault pays (Simulation.core_export). Measured
## before it: in the Core 8 and 9 eras the store filled -- Plates,
## Components, Alloy and Frames all at the Vault's limit -- and every machine
## beside the Core that could only hand the store its output stood still;
## income fell from 30.2K/s to 21-23K/s for two hours, and the Core's crowded
## sides had no room for a Vault (docs/PROGRESSION.md, "Core 9"). So the
## tenth level gives the Core itself something new to do, as a Town Hall's
## own weapon does in the reference games: it becomes the factory's
## biggest outlet, at half price, so a Vault still pays best.
const EXPORT_CORE := 10
const EXPORT_SHARE := 0.5

## Past the last level written out, every level asks for more of what the
## last one did, so the Core never stops (a later round writes these out
## with their own identities: docs/PROGRESSION.md, P5): its credits, its
## store, its machines on a job, its Overdrive steps on the same type, its
## doctrine, stability and depth -- each grown by about what an era's income
## grows, and no row that asks a type the stage before never levelled. The
## formula before it asked, from Core 10, a new type each level at the
## Core's limit with every Overdrive step at once: Core 10 was 521M credits
## and 1.7M research, Core 11 1.65B (docs/PROGRESSION.md, "Core 10").
const LATE_DEPTH_STEP := 5
## The deep eras' income grew 1.2 times from the Core 7 era to the Core 8
## era; a machine level from 9 costs 1.5 times the last
## (MachineDB.DEEP_LEVEL_GROWTH).
const LATE_CREDIT_GROWTH := 1.5
const LATE_STOCK_GROWTH := 1.6
const LATE_WORKING_STEP := 2
const LATE_RESEARCH := ["throughput_1", "yield_1", "value_1", "research_1", "resonance"]

## A machine counts as at its working heat at the warning key's threshold.
const WORKING_HEAT := Simulation.THERMAL_WARNING


static func _entry(level: int) -> Dictionary:
	if level <= LEVELS.size():
		return LEVELS[maxi(level, 1) - 1]
	var last: Dictionary = LEVELS[LEVELS.size() - 1]
	var n: int = level - LEVELS.size()
	var reqs: Array = []
	for r: Array in last["requires"]:
		match int(r[0]):
			Req.CREDITS:
				reqs.append([Req.CREDITS, float(r[1]) * pow(LATE_CREDIT_GROWTH, float(n))])
			Req.STOCK:
				# Never more than the store can hold under the level before.
				reqs.append([Req.STOCK, int(r[1]), mini(int(ceil(minf(float(r[2]) * pow(LATE_STOCK_GROWTH,
					float(n)), MachineDB.LEVEL_NUMBER_MAX))), MachineDB.stock_cap(machine_cap(level - 1)))])
			Req.STABLE:
				reqs.append([Req.STABLE, int(r[1]) + 20 * n])
			Req.SERVES:
				reqs.append(r)
			Req.DEPTH:
				reqs.append([Req.DEPTH, depth_cap(level - 1)])
			Req.DOCTRINE:
				reqs.append([Req.DOCTRINE, mini(int(r[1]) + n, doctrine_cap(level - 1))])
			Req.WORKING:
				var w: Array = [Req.WORKING, r[1], int(r[2]) + LATE_WORKING_STEP * n]
				if r.size() > 3:
					w.append(r[3])
				reqs.append(w)
			Req.OVERDRIVE:
				# The same type, one step more a level: a step's research grows
				# 1.47 times the last, about what an era's research does. All
				# three steps a level opens would be 3.2 times a level (1.75M
				# research at Core 11, 57M at Core 14).
				reqs.append([Req.OVERDRIVE, r[1], mini(int(r[2]) + n, overdrive_cap(level - 1))])
			Req.REGIONS:
				# One more region a level, while the map has one.
				reqs.append([Req.REGIONS, mini(int(r[1]) + n, Operations.region_room(level - 1))])
			Req.REGION_LINES:
				reqs.append([Req.REGION_LINES, int(r[1]) + 2 * n])
			Req.ROLES:
				reqs.append([Req.ROLES, mini(int(r[1]) + n, 4)])
			Req.BEACONS:
				# One more Beacon a level, as the map has regions to hold.
				reqs.append([Req.BEACONS, mini(int(r[1]) + n, Operations.region_room(level - 1))])
			Req.TECH:
				reqs.append([Req.TECH, mini(int(r[1]) + 2 * n, tech_cap(level - 1))])
			Req.MACHINE:
				reqs.append([Req.MACHINE, r[1], mini(int(r[2]) + n, machine_cap(level - 1))])
	var line: String = String(LATE_RESEARCH[n % LATE_RESEARCH.size()])
	reqs.append([Req.RESEARCH, line, mini(3 + n / LATE_RESEARCH.size(),
		Economy.research_cap(line, level - 1))])
	return {"level": level, "era": "", "depth_cap": depth_cap(level),
		"machine_cap": machine_cap(level), "requires": reqs}


## The deepest stratum a Core of `level` lets the shaft reach.
static func depth_cap(level: int) -> int:
	if level <= LEVELS.size():
		return int(LEVELS[maxi(level, 1) - 1]["depth_cap"])
	return int(LEVELS[LEVELS.size() - 1]["depth_cap"]) + LATE_DEPTH_STEP * (level - LEVELS.size())


## The highest level a machine type may be upgraded to under a Core of `level`.
static func machine_cap(level: int) -> int:
	if level <= LEVELS.size():
		return int(LEVELS[maxi(level, 1) - 1]["machine_cap"])
	return int(LEVELS[LEVELS.size() - 1]["machine_cap"]) + (level - LEVELS.size())


static func era(level: int) -> String:
	return String(_entry(level)["era"])


## What reaching `level` asks for, as [Req, ...] arrays.
static func requirements(level: int) -> Array:
	return _entry(level)["requires"]


## The lowest level whose depth cap reaches `depth`: a save from before the
## Core had levels keeps every stratum it had reached.
static func level_for_depth(depth: int) -> int:
	var level: int = 1
	while depth_cap(level) < depth:
		level += 1
	return level


## The lowest Vault level whose store holds `amount` of a material.
static func storage_level(amount: int) -> int:
	var v: int = 1
	while MachineDB.stock_cap(v) < amount and v < 1000:
		v += 1
	return v


## The most doctrine levels a shaft may have bought under a Core of `level`:
## the lines of the doctrine with the most, each at the Core's limit.
static func doctrine_cap(level: int) -> int:
	var best: int = 0
	for d: String in Economy.DOCTRINES:
		var n: int = 0
		for id: String in Economy.DOCTRINES[d]["lines"]:
			n += Economy.research_cap(id, level)
		best = maxi(best, n)
	return best if level >= Economy.DOCTRINE_CORE else 0


## The first Core level at which `n` doctrine levels can have been bought.
static func doctrine_at(n: int) -> int:
	var at: int = maxi(Economy.DOCTRINE_CORE, level_for_depth(MachineDB.unlock_depth("lab")))
	var guard: int = 0
	while doctrine_cap(at) < n:
		at += 1
		guard += 1
		if guard > 1000:
			return -1
	return at


## The Overdrive steps a machine type may take under a Core of `level`.
## The most levels of the Works' lines a Core of `level` lets a shaft have
## bought: each line at the Core's research limit.
static func tech_cap(level: int) -> int:
	var n: int = 0
	for id: String in Economy.WORKS:
		n += Economy.research_cap(id, level)
	return n


static func overdrive_cap(level: int) -> int:
	return MachineDB.OVERDRIVE_PER_CORE * maxi(level - MachineDB.OVERDRIVE_CORE + 1, 0)


## The level a machine type must have reached before a Core of `level` lets
## it be driven: the limit the Core before it set.
static func overdrive_from(level: int) -> int:
	return machine_cap(level - 1)


## What reaching `level` opens: the strata below (and the machines and
## materials found there), the machine level limit, the most a Vault may
## then store, the research lines that start there, and the Overdrive steps
## it adds.
static func opens(level: int) -> Dictionary:
	var from: int = depth_cap(level - 1) + 1 if level > 1 else 0
	var to: int = depth_cap(level)
	var machines: Array[String] = []
	for id: String in MachineDB.ORDER:
		var d: int = MachineDB.unlock_depth(id)
		if d >= from and d <= to:
			machines.append(id)
	# A material opens where its first maker can run: a machine found, or a
	# job its rock or the Core's level opens.
	var materials: Array[int] = []
	for res: int in MachineDB.Res.values():
		if material_at(res) == level:
			materials.append(res)
	var jobs: Array = []
	for id: String in MachineDB.ORDER:
		for job: String in (MachineDB.JOBS.get(id, {}) as Dictionary):
			if job_at(id, job) == level:
				jobs.append([id, job])
	var lines: Array[String] = []
	for id: String in Economy.TREE_ORDER:
		if int(Economy.RESEARCH_TREE[id].get("core", 1)) == level:
			lines.append(id)
	return {"strata": [from, to], "machines": machines, "materials": materials, "jobs": jobs,
		"doctrine": level == Economy.DOCTRINE_CORE, "export": level == EXPORT_CORE,
		"regions": level == Operations.REGION_CORE,
		"beacons": level == Operations.CONTROL_CORE,
		"reach": level == Operations.REACH_CORE,
		"works": level == Operations.REGION_CORE,
		"operations": level == MachineDB.RIG_CORE or level == Operations.FIRST_SITE_CORE,
		"machine_cap": machine_cap(level), "research": lines,
		"stock_cap": MachineDB.stock_cap(machine_cap(level)),
		"overdrive": overdrive_cap(level) - overdrive_cap(level - 1)}


## The Core's next level, requirement by requirement, as the running factory
## stands: [{"req", "met", "have", "need"}], and for STOCK the store's
## capacity as "cap". `state` is Sim, or anything with the same fields.
static func status(state: Object) -> Array:
	var level: int = int(state.get("core_level")) + 1
	var out: Array = []
	for r: Array in requirements(level):
		var have: float = 0.0
		var need: float = 0.0
		var row: Dictionary = {}
		match int(r[0]):
			Req.CREDITS:
				have = float(state.get("credits"))
				need = float(r[1])
			Req.STOCK:
				have = float((state.get("stock") as Dictionary).get(int(r[1]), 0))
				need = float(r[2])
				row["cap"] = int(state.call("stock_cap"))
			Req.WORKING:
				have = float(working(state, String(r[1]), row_job(r)))
				need = float(r[2])
			Req.MACHINE:
				have = float(int(state.call("machine_level", String(r[1]))))
				need = float(r[2])
			Req.DEPTH:
				have = float(int(state.get("max_depth")))
				need = float(r[1])
			Req.RESEARCH:
				have = float(int(state.call("upgrade_level", String(r[1]))))
				need = float(r[2])
			Req.SERVES:
				have = float(best_serving(state, String(r[1])))
				need = float(r[2])
			Req.STABLE:
				have = float(stable(state))
				need = float(r[1])
			Req.OVERDRIVE:
				have = float(int(state.call("overdrive_steps", String(r[1]))))
				need = float(r[2])
			Req.DOCTRINE:
				have = float(int(state.call("doctrine_levels")))
				need = float(r[1])
			Req.OPERATIONS:
				have = float(int(state.get("ops_cleared")))
				need = float(r[1])
			Req.REGIONS:
				var ro: Variant = state.get("regions_open")
				have = float((ro as Array).size()) if ro != null else 0.0
				need = float(r[1])
			Req.REGION_LINES:
				have = float(int(state.call("region_lines"))) if state.has_method("region_lines") else 0.0
				need = float(r[1])
			Req.ROLES:
				if state.has_method("crew_roles"):
					var roles: Dictionary = state.call("crew_roles")
					have = float(mini(int(roles["rig"]), mini(int(roles["breaker"]), int(roles["surveyor"]))))
				need = float(r[1])
			Req.BEACONS:
				have = float(int(state.call("lit_beacons"))) if state.has_method("lit_beacons") else 0.0
				need = float(r[1])
			Req.TECH:
				have = float(int(state.call("tech_levels"))) if state.has_method("tech_levels") else 0.0
				need = float(r[1])
		row.merge({"req": r, "met": have >= need, "have": have, "need": need})
		out.append(row)
	return out


static func can_upgrade(state: Object) -> bool:
	for s: Dictionary in status(state):
		if not bool(s["met"]):
			return false
	return true


## Machines of type `id` producing at their working heat right now; with
## `job`, only those set to it.
static func working(state: Object, id: String, job: String = "") -> int:
	var grid: Grid = state.get("grid")
	var sim: Simulation = state.get("sim")
	var n: int = 0
	for cell: int in grid.cells:
		if grid.machine_at(cell) == id and (job == "" or grid.job_at(cell) == job) \
				and sim.status_of(cell) == Simulation.Status.RUNNING \
				and sim.heat_efficiency_at(cell) >= WORKING_HEAT:
			n += 1
	return n


## The job a working row asks its machines to be on (its fourth element), or
## "" for any: [Req.WORKING, "lab", 6, "assay"] is six Assay Benches.
static func row_job(r: Array) -> String:
	return String(r[3]) if int(r[0]) == Req.WORKING and r.size() > 3 else ""


## Why the machine on `cell` is not at its working heat and producing:
## "hot" (overheating, or too hot to count), "cold", "starved", "blocked",
## "idle", or "" when it is.
static func why_not_working(state: Object, cell: int) -> String:
	var grid: Grid = state.get("grid")
	var sim: Simulation = state.get("sim")
	var id: String = grid.machine_at(cell)
	if id == "":
		return "idle"
	var eff: float = sim.heat_efficiency_at(cell)
	if sim.overheated_at(cell):
		return "hot"
	match sim.status_of(cell):
		Simulation.Status.STARVED:
			return "starved"
		Simulation.Status.BLOCKED:
			return "blocked"
		Simulation.Status.RUNNING, Simulation.Status.PASSIVE:
			if eff >= WORKING_HEAT:
				return ""
			var m: Dictionary = sim.machine_of(cell)
			return "cold" if grid.heat_at(cell) < float(m.get("heat_optimum", 0.0)) else "hot"
	return "idle"


## What keeps machines from counting towards a row, worst first: for a
## working row, machines of type `id`; for the stability row (`id` ""),
## every machine that overheats, then every one running off its working
## heat. {"cells": [cell, ...], "why": {reason: count}}.
static func holding_back(state: Object, id: String = "", job: String = "") -> Dictionary:
	var grid: Grid = state.get("grid")
	var order := ["hot", "starved", "blocked", "cold", "idle"]
	var by: Dictionary = {}
	for reason: String in order:
		by[reason] = []
	for cell: int in grid.cells:
		var here: String = grid.machine_at(cell)
		if id != "" and here != id or job != "" and grid.job_at(cell) != job:
			continue
		if id == "" and not MachineDB.has_levels(here):
			continue
		var why: String = why_not_working(state, cell)
		if why == "":
			continue
		# Stability asks about heat: a stalled machine does not break it.
		if id == "" and not (why == "hot" or why == "cold"):
			continue
		(by[why] as Array).append(cell)
	var cells: Array[int] = []
	var counts: Dictionary = {}
	for reason: String in order:
		for c: int in by[reason]:
			cells.append(c)
		if not (by[reason] as Array).is_empty():
			counts[reason] = (by[reason] as Array).size()
	return {"cells": cells, "why": counts}


## The most working machines one support machine of type `id` serves.
static func best_serving(state: Object, id: String) -> int:
	var grid: Grid = state.get("grid")
	var best: int = 0
	for cell: int in grid.cells:
		if grid.machine_at(cell) == id:
			best = maxi(best, grid.serves(cell))
	return best


## Machines running at their working heat, counted only while none is
## overheating (past its tolerance, where it chokes): a factory is stable
## when its heat is under control everywhere. A machine that is merely cold
## is slow, not unstable, and does not stop the count; one that overheats
## does.
static func stable(state: Object) -> int:
	var sim: Simulation = state.get("sim")
	var grid: Grid = state.get("grid")
	var n: int = 0
	for cell: int in grid.cells:
		if sim.overheated_at(cell):
			return 0
		if sim.status_of(cell) == Simulation.Status.RUNNING \
				and sim.heat_efficiency_at(cell) >= WORKING_HEAT:
			n += 1
	return n


## --- the graph, checked -------------------------------------------------------

## The Core level at which a requirement first becomes possible, or -1 when it
## never does. A requirement of level L must be possible at L-1: that is what
## keeps the graph free of cycles and every level reachable.
static func available_at(r: Array) -> int:
	match int(r[0]):
		Req.CREDITS, Req.STABLE:
			return 1
		Req.DEPTH:
			return level_for_depth(int(r[1]))
		Req.STOCK:
			var made: int = material_at(int(r[1]))
			if made < 0:
				return -1
			var store: int = machine_level_at("vault", storage_level(int(r[2])))
			return -1 if store < 0 else maxi(made, store)
		Req.WORKING, Req.SERVES:
			if not MachineDB.exists(String(r[1])):
				return -1
			if int(r[0]) == Req.SERVES and int(r[2]) > MAX_SERVES:
				return -1
			var found: int = level_for_depth(MachineDB.unlock_depth(String(r[1])))
			if row_job(r) != "":
				if MachineDB.job_info(String(r[1]), row_job(r)).is_empty():
					return -1
				return maxi(found, job_at(String(r[1]), row_job(r)))
			return found
		Req.MACHINE:
			return machine_level_at(String(r[1]), int(r[2]))
		Req.RESEARCH:
			return research_at(String(r[1]), int(r[2]))
		Req.OVERDRIVE:
			return overdrive_at(String(r[1]), int(r[2]))
		Req.DOCTRINE:
			return doctrine_at(int(r[1]))
		Req.OPERATIONS:
			# Sites cleared by the crew: the first gallery opens to the
			# Foreman's Rig.
			return Operations.FIRST_SITE_CORE
		Req.REGIONS:
			if int(r[1]) > Operations.REGION_ORDER.size():
				return -1
			# The first three a Core level each; the Dark Reach from its own.
			if int(r[1]) > Operations.REGION_ORDER.size() - 1:
				return maxi(Operations.REACH_CORE, Operations.REGION_CORE + int(r[1]) - 2)
			return Operations.REGION_CORE + int(r[1]) - 1
		Req.REGION_LINES:
			# A line's levels are capped by the Core, RESEARCH_PER_CORE a
			# level, and one region's line is enough.
			return Operations.REGION_CORE + int(ceil(float(r[1]) / float(Economy.RESEARCH_PER_CORE))) - 1
		Req.ROLES:
			return Operations.REGION_CORE
		Req.BEACONS:
			# A Beacon a region: as many regions open first.
			if int(r[1]) > Operations.REGION_ORDER.size():
				return -1
			return maxi(Operations.CONTROL_CORE, available_at([Req.REGIONS, int(r[1])]))
		Req.TECH:
			var at: int = Operations.REGION_CORE
			var guard: int = 0
			while tech_cap(at) < int(r[1]):
				at += 1
				guard += 1
				if guard > 1000:
					return -1
			return at
	return -1


## The first Core level at which machine type `id` can stand at `level`: the
## machine found, the limit high enough, and every level on the way paid for
## in materials some machine by then makes, in a store big enough to hold
## them. -1 when never.
static func machine_level_at(id: String, level: int) -> int:
	if not MachineDB.exists(id) or not MachineDB.has_levels(id):
		return -1 if level > 1 else 1
	var at: int = level_for_depth(MachineDB.unlock_depth(id))
	var guard: int = 0
	while machine_cap(at) < level:
		at += 1
		guard += 1
		if guard > 1000:
			return -1
	for k in range(2, level + 1):
		var cost: Dictionary = MachineDB.level_materials(k, id)
		for res: int in cost:
			var made: int = material_at(res)
			if made < 0:
				return -1
			at = maxi(at, made)
			# The Vault's own levels are paid from the store its level before
			# holds: `validate` checks that it does.
			if id != "vault":
				var v: int = storage_level(int(cost[res]))
				if v > 1:
					var store: int = machine_level_at("vault", v)
					if store < 0:
						return -1
					at = maxi(at, store)
	return at


## The first Core level at which research line `id` can be at `level`: the
## line open, its limit high enough, and a Lab to make research with.
static func research_at(id: String, level: int) -> int:
	var u: Dictionary = Economy.RESEARCH_TREE.get(id, {})
	if u.is_empty() or level > int(u["max"]):
		return -1
	var at: int = maxi(int(u.get("core", 1)), level_for_depth(MachineDB.unlock_depth("lab")))
	var guard: int = 0
	while Economy.research_cap(id, at) < level:
		at += 1
		guard += 1
		if guard > 1000:
			return -1
	return at


## The first Core level at which machine type `id` can have been driven
## `steps` Overdrive steps: Overdrive open that far, the type at the level
## that Core's predecessor allowed, every step's materials in a store its
## Vault can then hold, and a Lab for the research. -1 when never.
static func overdrive_at(id: String, steps: int) -> int:
	if not MachineDB.exists(id) or not MachineDB.can_overdrive(id):
		return -1
	if steps <= 0:
		return 1
	var at: int = MachineDB.OVERDRIVE_CORE
	var guard: int = 0
	while overdrive_cap(at) < steps:
		at += 1
		guard += 1
		if guard > 1000:
			return -1
	var lvl: int = machine_level_at(id, overdrive_from(at))
	if lvl < 0:
		return -1
	at = maxi(at, maxi(lvl, level_for_depth(MachineDB.unlock_depth("lab"))))
	for k in range(1, steps + 1):
		var mats: Dictionary = MachineDB.overdrive_cost(k)["materials"]
		for res: int in mats:
			var made: int = material_at(res)
			if made < 0:
				return -1
			at = maxi(at, made)
			var v: int = storage_level(int(mats[res]))
			if v > 1:
				var store: int = machine_level_at("vault", v)
				if store < 0:
					return -1
				at = maxi(at, store)
	return at


## The machine that makes `res` -- on its own recipe, or on a job -- or "".
static func producer_of(res: int) -> String:
	var makers: Array = MachineDB.makers_of(res)
	return "" if makers.is_empty() else String(makers[0][0])


## The job that machine makes `res` on ("" for its own recipe).
static func job_of(res: int) -> String:
	var makers: Array = MachineDB.makers_of(res)
	return "" if makers.is_empty() else String(makers[0][1])


## The first Core level at which a machine can run job `job` ("" for its
## own recipe): the stratum it needs within the Core's reach, and the
## Core's level the job asks for.
static func job_at(id: String, job: String) -> int:
	return maxi(level_for_depth(MachineDB.job_depth(id, job)),
		int(MachineDB.job_info(id, job).get("core", 1)))


## The first Core level at which `res` can be made, or -1 when never.
static func material_at(res: int) -> int:
	var best: int = -1
	for mk: Array in MachineDB.makers_of(res):
		var at: int = job_at(String(mk[0]), String(mk[1]))
		if best < 0 or at < best:
			best = at
	return best


## Every problem with levels 2..`upto`: [] when the graph is sound.
static func validate(upto: int = 20) -> Array[String]:
	var errors: Array[String] = []
	for level in range(2, upto + 1):
		if depth_cap(level) <= depth_cap(level - 1):
			errors.append("level %d does not go deeper than level %d" % [level, level - 1])
		if machine_cap(level) < machine_cap(level - 1):
			errors.append("level %d lowers the machine limit" % level)
		errors.append_array(problems(level, requirements(level)))
	# Every research line opens at a level the Core reaches, after the Lab.
	for id: String in Economy.TREE_ORDER:
		if research_at(id, 1) < 0:
			errors.append("research %s can never be started" % id)
	# Every Vault level is payable from the store the level before holds, and
	# every machine level from a store at its own level.
	for v in range(2, machine_cap(upto) + 1):
		var vault: Dictionary = MachineDB.level_materials(v, "vault")
		for res: int in vault:
			if int(vault[res]) > MachineDB.stock_cap(v - 1):
				errors.append("the Vault's level %d costs more than its level %d stores" % [v, v - 1])
		var other: Dictionary = MachineDB.level_materials(v)
		for res: int in other:
			if int(other[res]) > MachineDB.stock_cap(v):
				errors.append("a machine's level %d costs more than a level-%d Vault stores" % [v, v])
	# Every Overdrive step a Core level opens is payable from the store a
	# Vault at that level's limit holds.
	for level in range(MachineDB.OVERDRIVE_CORE, upto + 1):
		for k in range(overdrive_cap(level - 1) + 1, overdrive_cap(level) + 1):
			var od: Dictionary = MachineDB.overdrive_cost(k)["materials"]
			for res: int in od:
				if int(od[res]) > MachineDB.stock_cap(machine_cap(level)):
					errors.append("Overdrive step %d, opened by level %d, costs more than its store holds"
						% [k, level])
	return errors


## What is wrong with asking `reqs` for Core `level`: a requirement that can
## never be had (unreachable), one that only becomes possible at `level` or
## later (a cycle: the Core would need itself), a store no Vault then holds,
## research paid in Cores (that would make a collapse a requirement), a
## level that is one number.
static func problems(level: int, reqs: Array) -> Array[String]:
	var errors: Array[String] = []
	if reqs.size() < 3:
		errors.append("level %d asks for %d things; a Core level is never one number"
			% [level, reqs.size()])
	var kinds: Dictionary = {}
	for r: Array in reqs:
		kinds[int(r[0])] = true
		var at: int = available_at(r)
		if at < 0:
			errors.append("level %d asks for %s, which can never be had" % [level, str(r)])
		elif at >= level:
			errors.append("level %d asks for %s, which first becomes possible at level %d"
				% [level, str(r), at])
		if int(r[0]) == Req.DEPTH and int(r[1]) > depth_cap(level - 1):
			errors.append("level %d asks for stratum %d, below its own limit" % [level, int(r[1])])
		if int(r[0]) == Req.RESEARCH:
			var u: Dictionary = Economy.RESEARCH_TREE.get(String(r[1]), {})
			if int(u.get("cost_cores", 0)) > 0:
				errors.append("level %d asks for %s, which is paid in Cores: a collapse would be a requirement"
					% [level, String(r[1])])
	if kinds.size() == 1 and kinds.has(Req.CREDITS):
		errors.append("level %d is only credits" % level)
	return errors
