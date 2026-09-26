class_name Operations
extends RefCounted

## Operations: the Rigs a Factory Core keeps as its crew, and the sites in
## the galleries beyond the yard the Core sends them to (docs/GAME-LOOP.md,
## "The first slice").
##
## The loop the reference games hang everything on -- the base makes an
## army, the army goes out, what it brings back makes the base stronger --
## in Lodeworks' own terms: an Assembler on the Rig Frame job makes a Rig
## from two Plates; the Core keeps Rigs as its crew, up to a
## limit its level sets; a sortie takes some of them, and Ingots for fuel,
## to one of SLOTS sites dealt on the board; they walk out, work, and walk
## home with the site's printed reward, worn by its hazard; worn Rigs are
## weaker until Plates repair them; Rig Plating (research) makes every Rig
## stronger; a cleared site is dealt again, harder as the Core grows.
##
## Everything here is decided, never drawn (D5): a site is dealt from the
## Core's level, the stratum and a running count, like a Dispatch contract,
## and a sortie's outcome is worked out the moment it leaves -- a sortie
## too weak for what is left of a site takes its share of the reward and
## leaves the site that much weaker for the next one (a failure that eases
## the next try, not a loss). No Rig is ever destroyed (FP-09).

## The Core's level that opens the Rig Frame job, a crew of several and the
## whole board.
const RIG_CORE := MachineDB.RIG_CORE
## Before it, the crew is FIRST_CREW Rig the Core keeps from the moment it
## comes online -- the Foreman's, which walks to the machines every level
## bought -- and from FIRST_SITE_CORE one gallery is open to it: a site of
## EARLY_NEED strength, which a whole Rig clears, paying EARLY_PAY of what a
## site of its strength pays once the crew is made. The owner's brief asked
## for the robots and the operations in the first minutes, not after half
## an hour (docs/GAME-LOOP.md, section 1).
const FIRST_CREW := 1
const FIRST_SITE_CORE := 2
const EARLY_NEED := 8.0
const EARLY_PAY := 0.25
## The crew the Core keeps: CREW_BASE Rigs at RIG_CORE, CREW_PER_CORE more
## for every level after.
const CREW_BASE := 3
const CREW_PER_CORE := 1
## What sorties bring home besides their pay: every SITES_PER_RIG sites
## cleared, in any shaft, the Core finds room for one more Rig, up to
## SITE_RIGS_MAX more -- the crew grows by what it has done, as a
## reference game's army grows with its camps (docs/GAME-LOOP.md). The
## count is the lifetime one, so a collapse keeps it.
const SITES_PER_RIG := 10
const SITE_RIGS_MAX := 6


## The Rigs the crew has earned room for by `sites` cleared in all.
static func earned_rigs(sites: int) -> int:
	return mini(maxi(sites, 0) / SITES_PER_RIG, SITE_RIGS_MAX)


## What one Rig brings to a sortie, whole and with no Rig Plating.
const RIG_POWER := 10.0
## Sites on the board at a time.
const SLOTS := 3

## The kinds of site in the galleries below the shaft. `hazard` is the wear
## a sortie that only just clears it leaves on every Rig it sent; `res` the
## material it pays besides credits and research.
const KINDS := {
	"flooded": {
		"name": "Flooded Gallery",
		"line": "Old workings under water. There is pipe and plate worth hauling out.",
		"hazard": 0.08,
		"res": MachineDB.Res.PLATE,
	},
	"drift": {
		"name": "Collapsed Drift",
		"line": "A caved-in drift with its seam still showing.",
		"hazard": 0.12,
		"res": MachineDB.Res.INGOT,
	},
	"pumphouse": {
		"name": "Old Pump House",
		"line": "A dead pumping station, full of parts.",
		"hazard": 0.10,
		"res": MachineDB.Res.COMPONENT,
	},
	"nest": {
		"name": "Rogue Drill Nest",
		"line": "Old drills gone feral down here. They fight back.",
		"hazard": 0.25,
		"res": MachineDB.Res.COMPONENT,
	},
}
const KIND_ORDER := ["flooded", "drift", "pumphouse", "nest"]

## A site's strength: NEED_BASE at RIG_CORE, NEED_GROWTH times as much for
## every Core level after, times its tier. A Core 4 crew of three whole Rigs
## clears a tier-1 site and needs two sorties, or Rig Plating, for the
## others. At 20 the crew cleared the three sites Core 5 then asked for in
## two minutes.
const NEED_BASE := 25.0
const NEED_GROWTH := 1.35
const TIERS := [1.0, 1.6, 2.5]
const TIER_WEIGHTS := [0.5, 0.35, 0.15]
## What a cleared site pays, for each unit of its strength, at RIG_CORE
## (growing with the Core as its strength does): credits, research and
## units of its material. And never less, in credits, than REWARD_SECONDS
## of the factory's measured income a unit of tier. A sortie is a minute
## or so; at 45 seconds a site, a Core 4 crew cleared nine in fourteen
## minutes and added two thirds to the factory's income, and the galleries
## became the factory. At 10 they add about a fifth: worth the crew, not
## worth more than the lines that make it.
const CREDITS_PER_NEED := 900.0
const RESEARCH_PER_NEED := 3.0
const UNITS_PER_NEED := 0.8
const REWARD_SECONDS := 10.0
## Ingots a Rig burns on a sortie, growing with the Core.
const FUEL_PER_RIG := 4.0
## Plates that repair one Rig from fully worn, growing with the Core.
const REPAIR_PER_RIG := 6.0
## No Rig wears past this: a worn crew is weaker, never gone.
const WEAR_MAX := 0.8
## A sortie's walk out and back, in seconds: TRIP_BASE, and TRIP_PER_TIER
## more for each tier past the first -- the harder sites lie further out.
const TRIP_BASE := 40.0
const TRIP_PER_TIER := 20.0


## The crew the Core keeps under a Core of `level`.
static func crew_cap(level: int) -> int:
	if level < RIG_CORE:
		return FIRST_CREW
	return CREW_BASE + CREW_PER_CORE * (level - RIG_CORE)


## Sites on the board under a Core of `level`: none before FIRST_SITE_CORE,
## one before RIG_CORE.
static func slots(level: int) -> int:
	if level < FIRST_SITE_CORE:
		return 0
	return 1 if level < RIG_CORE else SLOTS


## How much the Core's level has grown the galleries' numbers.
static func growth(level: int) -> float:
	return pow(NEED_GROWTH, float(maxi(level - RIG_CORE, 0)))


## Site number `serial` of this shaft: {"kind", "tier", "need", "left",
## "hazard", "serial", "core", "depth"}. `left` is what is still to clear.
static func deal(core_level: int, depth: int, serial: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lodeworks-site-%d-%d-%d" % [core_level, depth, serial])
	# The nest -- the one that fights back -- once the crew has had a level
	# to learn on.
	var kinds: Array = KIND_ORDER.duplicate()
	if core_level <= RIG_CORE:
		kinds.erase("nest")
	# Before the crew is made, only what a first factory has: Plates and
	# Ingots, at one Rig's strength.
	var early: bool = core_level < RIG_CORE
	if early:
		kinds = ["flooded", "drift"]
	var kind: String = String(kinds[rng.randi_range(0, kinds.size() - 1)])
	var pick: float = rng.randf()
	var tier: int = 0
	for k in range(TIERS.size()):
		pick -= float(TIER_WEIGHTS[k])
		if pick <= 0.0:
			tier = k
			break
	if early:
		tier = 0
	var need: float = EARLY_NEED if early else snappedf(NEED_BASE * growth(core_level) * float(TIERS[tier]), 1.0)
	# Deeper galleries are rougher on a Rig.
	var hazard: float = minf(float(KINDS[kind]["hazard"]) * (1.0 + 0.02 * float(depth)), 0.6)
	return {"kind": kind, "tier": tier, "need": need, "left": need, "hazard": hazard,
		"serial": serial, "core": core_level, "depth": depth}


## What clearing site `s` pays, given the factory's measured credits a
## second: {"credits", "research", "res", "n"}.
static func reward(s: Dictionary, credits_per_sec: float) -> Dictionary:
	if s.is_empty():
		return {}
	var need: float = float(s["need"])
	var tier: float = float(TIERS[int(s["tier"])])
	var pay: float = EARLY_PAY if int(s.get("core", RIG_CORE)) < RIG_CORE else 1.0
	return {
		"credits": maxf(need * CREDITS_PER_NEED * pay, credits_per_sec * REWARD_SECONDS * tier),
		"research": need * RESEARCH_PER_NEED * pay,
		"res": int(KINDS[String(s["kind"])]["res"]),
		"n": int(ceil(need * UNITS_PER_NEED)),
	}


## Ingots a sortie of `n` Rigs burns under a Core of `level`.
static func fuel(n: int, level: int) -> int:
	return int(ceil(float(n) * FUEL_PER_RIG * growth(level)))


## Seconds a sortie to site `s` takes, out and back.
static func trip(s: Dictionary) -> float:
	return TRIP_BASE + TRIP_PER_TIER * float(s.get("tier", 0))


## What a sortie of `strength` does to site `s`: {"cleared", "share" (of
## the site's reward it earns), "wear" (added to every Rig sent), "left"
## (what the site has left after it)}.
static func resolve(s: Dictionary, strength: float) -> Dictionary:
	var left: float = float(s["left"])
	var need: float = maxf(float(s["need"]), 1.0)
	if strength <= 0.0:
		return {"cleared": false, "share": 0.0, "wear": 0.0, "left": left}
	var done: float = minf(strength, left)
	# The more to spare, the less wear: a crew twice the site's strength
	# comes home half as worn.
	var wear: float = float(s["hazard"]) * clampf(left / strength, 0.25, 1.0)
	return {"cleared": strength >= left, "share": done / need, "wear": wear, "left": left - done}


## How a crew of `strength` compares with what is left of site `s`, worst
## first: "reach" (under a third), "hard" (under the whole), "even", "easy"
## (half again or more), "trivial" (twice or more).
static func verdict(s: Dictionary, strength: float) -> String:
	var left: float = maxf(float(s.get("left", 1.0)), 1.0)
	var r: float = strength / left
	if r >= 2.0:
		return "trivial"
	if r >= 1.5:
		return "easy"
	if r >= 1.0:
		return "even"
	if r >= 0.34:
		return "hard"
	return "reach"


## Plates that repair a crew of `rigs` Rigs from wear `wear` under a Core
## of `level`.
static func repair_cost(rigs: int, wear: float, level: int) -> int:
	if rigs <= 0 or wear <= 0.0:
		return 0
	return int(ceil(float(rigs) * wear * REPAIR_PER_RIG * growth(level)))
