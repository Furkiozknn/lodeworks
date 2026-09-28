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
## limit its level sets; a sortie takes some of them, and fuel (fuel_res),
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


## What a cleared site holds that the factory cannot make: salvage -- old
## gearing and parts, hauled out -- which pays for the research lines marked
## "cost_salvage" (Salvaged Gearing, Rig Plating) and the Rig Bay's levels.
## One from a cleared site, SALVAGE_NEST more from the nest; a site not
## cleared pays none. The reference games' loot that only a battle brings
## (docs/GAME-LOOP.md, section 4). Scarce on purpose: at one to three a site
## and a tier, every way of spending it ended the Core 8 era with more than
## a thousand unspent, and it chose nothing (section 9).
const SALVAGE_NEST := 1


static func salvage(s: Dictionary) -> int:
	if s.is_empty():
		return 0
	return 1 + (SALVAGE_NEST if String(s["kind"]) in ["nest", "forge"] else 0)


## Posts: a Rig at the Bay can be posted to a machine touching the Core,
## and hauls into it, from the Core's store, what that machine takes -- the
## store, which only ever took, feeds the machines beside it through the
## crew (docs/GAME-LOOP.md, section 11). The Rig Bay's level sets how many
## Rigs may be posted at once and how fast each hauls; a Rig posted is a
## Rig not in the galleries. Measured: a Core 9 factory held 67,000 Frames
## in its store while all eight of its Assay Benches starved.
const HAUL_BASE := 1.0
const HAUL_PER_BAY := 0.35
const BAY_MAX := 8
## What a level of the Bay costs, from level L to L + 1: credits
## BAY_CREDITS x BAY_CREDIT_GROWTH^(L-1), salvage BAY_SALVAGE x
## BAY_SALVAGE_GROWTH^(L-1). Salvage is the galleries' own pay: the Bay
## grows on what the crew brings home.
const BAY_CREDITS := 20000.0
const BAY_CREDIT_GROWTH := 4.0
const BAY_SALVAGE := 6.0
const BAY_SALVAGE_GROWTH := 1.8


## Rigs the Bay at `level` may have posted at once.
static func bay_posts(level: int) -> int:
	return clampi(level, 1, BAY_MAX)


## The Bay's highest level under a Core of `core_level`.
static func bay_cap(core_level: int) -> int:
	return clampi(core_level - 2, 1, BAY_MAX)


## Units a second one posted Rig hauls, with the Bay at `level`.
static func haul_rate(level: int) -> float:
	return HAUL_BASE * (1.0 + HAUL_PER_BAY * float(maxi(level, 1) - 1))


## What the Bay's next level costs, from `level`: {"credits", "salvage"}.
static func bay_cost(level: int) -> Dictionary:
	var k: float = float(maxi(level, 1) - 1)
	return {"credits": BAY_CREDITS * pow(BAY_CREDIT_GROWTH, k),
		"salvage": int(ceil(BAY_SALVAGE * pow(BAY_SALVAGE_GROWTH, k)))}


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
	# The deep map's (REGIONS): dealt only in the region that holds them.
	"cistern": {
		"name": "Flooded Cistern",
		"line": "Resonite settled in black water, and pumps that still turn.",
		"hazard": 0.10,
		"res": MachineDB.Res.RESONITE,
	},
	"stranded": {
		"name": "Stranded Rigs",
		"line": "A crew lost down here long ago. Bring them home.",
		"hazard": 0.08,
		"res": MachineDB.Res.PLATE,
	},
	"vein": {
		"name": "Resonite Vein",
		"line": "A seam of Resonite in hard rock. It will not come out for Rigs.",
		"hazard": 0.14,
		"res": MachineDB.Res.RESONITE,
	},
	"forge": {
		"name": "Rogue Forge",
		"line": "An old forge that runs itself, and does not want visitors.",
		"hazard": 0.30,
		"res": MachineDB.Res.RESONITE,
	},
	# An expedition's target: a region, sealed until surveyed.
	"survey": {
		"name": "Survey",
		"line": "The way into a region of the deep map.",
		"hazard": 0.12,
		"res": MachineDB.Res.RESONITE,
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
## Fuel a Rig burns on a sortie (fuel_res), growing with the Core.
const FUEL_PER_RIG := 4.0
## Plates that repair one Rig from fully worn, growing with the Core.
const REPAIR_PER_RIG := 6.0
## No Rig wears past this: a worn crew is weaker, never gone.
const WEAR_MAX := 0.8
## A sortie's walk out and back, in seconds: TRIP_BASE, and TRIP_PER_TIER
## more for each tier past the first -- the harder sites lie further out.
const TRIP_BASE := 40.0
const TRIP_PER_TIER := 20.0


## --- the Breaker: the crew's second kind ---------------------------------------
##
## From BREAKER_CORE a Rig at the Bay can be refitted as a Breaker: heavy
## plate and a rock hammer, paid in Components and salvage (refit_cost). It
## answers a property of a site, not only its strength:
##
##   * rock -- an armoured site (`armor`: a drift's cave-in, a nest's shell,
##     dealt from BREAKER_CORE) -- takes a Rig at ARMOR_RIG of its strength
##     and a Breaker at BREAKER_POWER Rigs;
##   * water -- a flooded gallery -- takes a Breaker at FLOOD_BREAKER of
##     that: it is too heavy for it;
##   * a Breaker takes the brunt of a site: the wear a sortie brings home
##     falls by BREAKER_SHIELD of the share of its strength the Breakers
##     brought;
##   * it burns BREAKER_FUEL a Rig's fuel, costs BREAKER_REPAIR a Rig's
##     Plates to repair, and is never posted: too heavy to haul.
##
## A Breaker is a Rig refitted, so the crew's room is the same: a team is a
## choice of Rigs and Breakers against the site, and a crew is a choice of
## how many Rigs to refit (docs/GAME-LOOP.md, section 11).
const BREAKER_CORE := 6
const BREAKER_POWER := 2.5
const ARMOR_RIG := 0.5
const FLOOD_BREAKER := 0.4
const BREAKER_SHIELD := 0.5
const BREAKER_FUEL := 2.0
const BREAKER_REPAIR := 2.0
const ARMORED := ["drift", "nest"]
## A refit: REFIT_COMPONENTS Components, growing with the Core as a site's
## strength does, and REFIT_SALVAGE salvage.
const REFIT_COMPONENTS := 30.0
const REFIT_SALVAGE := 4


## Is site `s` armoured: rock a Rig does half its strength against?
static func armored(s: Dictionary) -> bool:
	return bool(s.get("armor", false))


## Is site `s` under water: too deep for a Breaker?
static func watery(s: Dictionary) -> bool:
	return String(s.get("kind", "")) in WATER or String(s.get("terrain", "")) == "water"


## Is site `s` dangerous: a team with no Breaker to lead it brings home half?
static func dangerous(s: Dictionary) -> bool:
	return String(s.get("kind", "")) == "forge" or String(s.get("terrain", "")) == "danger"


const WATER := ["flooded", "cistern", "stranded"]


## --- the Surveyor: the crew's third kind (Core 10) --------------------------------
##
## From REGION_CORE a Rig at the Bay can be refitted as a Surveyor, paid in
## Frames and salvage (refit_cost): a light frame, lamps and sounding gear.
## It is the Breaker's opposite:
##
##   * an expedition into a region of the deep map (REGIONS) goes only with
##     a Surveyor, and there each counts SURVEY_POWER Rigs;
##   * on a site it does SURVEYOR_POWER of a Rig's work -- half that on rock;
##   * each Surveyor on a sortie finds SURVEYOR_FIND more of the Resonite a
##     site holds, up to SURVEYOR_FIND_MAX more;
##   * a team of Surveyors alone is back in SURVEYOR_TRIP of the time;
##   * it is fragile: the wear a sortie brings home grows by SURVEYOR_FRAGILE
##     of the share of the team's strength the Surveyors brought;
##   * it is never posted.
const SURVEYOR_POWER := 0.8
const SURVEY_POWER := 2.0
const SURVEYOR_FIND := 0.25
const SURVEYOR_FIND_MAX := 1.0
const SURVEYOR_TRIP := 0.6
const SURVEYOR_FRAGILE := 1.0
const REFIT_FRAMES := 60.0
const SURVEYOR_SALVAGE := 6


## What `n` Rigs, `b` Breakers and `v` Surveyors bring to site `s`, in whole
## Rigs. `bpow` is the Breakers' research (Economy, "breaker_power").
static func team_factor(s: Dictionary, n: int, b: int, v: int = 0, bpow: float = 1.0) -> float:
	var rock: bool = armored(s)
	var rig: float = ARMOR_RIG if rock else 1.0
	var breaker: float = BREAKER_POWER * bpow * (FLOOD_BREAKER if watery(s) else 1.0)
	var surveyor: float = SURVEY_POWER if String(s.get("kind", "")) == "survey" \
		else SURVEYOR_POWER * (ARMOR_RIG if rock else 1.0)
	return float(maxi(n, 0)) * rig + float(maxi(b, 0)) * breaker + float(maxi(v, 0)) * surveyor


## The share of a team's strength its Breakers bring.
static func breaker_share(s: Dictionary, n: int, b: int, v: int = 0) -> float:
	var all: float = team_factor(s, n, b, v)
	return 0.0 if all <= 0.0 else team_factor(s, 0, b, 0) / all


## The share of a team's strength its Surveyors bring.
static func surveyor_share(s: Dictionary, n: int, b: int, v: int) -> float:
	var all: float = team_factor(s, n, b, v)
	return 0.0 if all <= 0.0 else team_factor(s, 0, 0, v) / all


## What a refit costs under a Core of `level`: {"res", "n", "salvage"} --
## a Breaker in Components, a Surveyor in Frames.
static func refit_cost(level: int, role: String = "breaker") -> Dictionary:
	if role == "surveyor":
		return {"res": MachineDB.Res.FRAME, "n": int(ceil(REFIT_FRAMES * growth(level))),
			"salvage": SURVEYOR_SALVAGE}
	return {"res": MachineDB.Res.COMPONENT, "n": int(ceil(REFIT_COMPONENTS * growth(level))),
		"salvage": REFIT_SALVAGE}


## The Core's level that refits each kind of crew.
static func role_core(role: String) -> int:
	return REGION_CORE if role == "surveyor" else BREAKER_CORE


## --- the deep map: regions (Core 10) ------------------------------------------------
##
## Past the galleries lie three regions, sealed. From REGION_CORE the Core
## has room for one open region, and one more at every level after. A
## region is opened by an expedition -- a team with a Surveyor in it, strong
## enough for the region's survey, SURVEY_TRIP seconds out and back -- and,
## after the first, EXPEDITION_LENS Lenses for each region already open. An
## open region deals its own sites into a slot of its own (SLOTS + its
## place in REGION_ORDER), each of its own kinds, and gives the factory its
## advantage for good; its research line opens (Economy, "region").
##
## Which region first is the choice: each asks for a different crew and
## gives a different factory.
##
##   the Sunken Works    water: Breakers are no use there. Cisterns of
##                       Resonite, and Stranded Rigs -- a rescue: every one
##                       brought home is room for one more Rig (up to
##                       RESCUE_MAX), and the crew mended. Its brine makes
##                       every Coolant Cell and Condenser cool BRINE_COOLING
##                       harder.
##   the Resonite Caverns rock: Rigs do half. Veins rich in Resonite; the
##                       crew brings home CAVERN_RESONITE times the Resonite
##                       from every site.
##   the Rogue Foundry   danger: a team with no Breaker brings home half,
##                       and a Surveyor there wears double. Forges pay more
##                       salvage; every cleared site pays FOUNDRY_SALVAGE
##                       times its salvage.
const REGION_CORE := 10
const REGION_ORDER := ["sunken", "caverns", "foundry"]
const REGIONS := {
	"sunken": {"name": "The Sunken Works", "short": "Water. Resonite cisterns, and Rigs to rescue.",
		"terrain": "water", "kinds": ["cistern", "cistern", "stranded"], "survey": 1.0, "research": "brine_1",
		"advantage": "Every Coolant Cell and Condenser cools a quarter harder."},
	"caverns": {"name": "The Resonite Caverns", "short": "Rock. The richest Resonite, for Breakers.",
		"terrain": "rock", "kinds": ["vein"], "survey": 1.3, "research": "lens_1",
		"advantage": "Every site pays half again its Resonite."},
	"foundry": {"name": "The Rogue Foundry", "short": "Danger. Forges that fight back, and salvage.",
		"terrain": "danger", "kinds": ["forge"], "survey": 1.6, "research": "forge_1",
		"advantage": "Every cleared site pays twice its salvage."},
}
const SURVEY_NEED := 2.0
const SURVEY_TRIP := 150.0
const EXPEDITION_FUEL := 3.0
const EXPEDITION_LENS := 200
const RESCUE_MAX := 3
const BRINE_COOLING := 1.25
const CAVERN_RESONITE := 1.5
const FOUNDRY_SALVAGE := 2
## Resonite a cleared site holds, a unit of its strength (UNITS_PER_NEED
## for the other materials): rarer than what the factory makes. At 0.4 a
## Core 10 crew in the Caverns brought home 28,000 in 35 minutes and the
## Core 11 row's Lenses were a formality.
const RESONITE_PER_NEED := 0.15


## Regions a Core of `level` has room to have open.
static func region_slots(level: int) -> int:
	return clampi(level - REGION_CORE + 1, 0, REGION_ORDER.size())


## The board slot of region `r`'s sites.
static func region_slot(r: String) -> int:
	return SLOTS + REGION_ORDER.find(r)


## The region a board slot belongs to, or "" for the galleries' own.
static func slot_region(slot: int) -> String:
	var k: int = slot - SLOTS
	return String(REGION_ORDER[k]) if k >= 0 and k < REGION_ORDER.size() else ""


## Region `r`'s survey under a Core of `level`: the site an expedition goes to.
## Its strength is the region's own, as at REGION_CORE: the way in does not
## grow with the Core; what grows is its price in Lenses (measured: grown
## with the Core, the Sunken Works' survey was 409 at Core 11 against a
## whole crew of 330 in water, and Core 12 was never reached).
static func survey_site(r: String, level: int, depth: int) -> Dictionary:
	var reg: Dictionary = REGIONS[r]
	var need: float = snappedf(NEED_BASE * growth(REGION_CORE) * SURVEY_NEED * float(reg["survey"]), 1.0)
	var terrain: String = String(reg["terrain"])
	return {"kind": "survey", "region": r, "tier": 0, "need": need, "left": need,
		"hazard": minf(float(KINDS["survey"]["hazard"]) * (1.0 + 0.02 * float(depth)), 0.6),
		"serial": -1, "core": level, "depth": depth, "armor": terrain == "rock", "terrain": terrain}


## Site number `serial` of region `r`: one of its own kinds, dealt as the
## galleries' sites are (deal), on the region's terrain.
static func deal_region(r: String, core_level: int, depth: int, serial: int) -> Dictionary:
	var reg: Dictionary = REGIONS[r]
	var s: Dictionary = deal(core_level, depth, serial)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lodeworks-region-%s-%d-%d" % [r, core_level, serial])
	var kinds: Array = reg["kinds"]
	var kind: String = String(kinds[rng.randi_range(0, kinds.size() - 1)])
	s["kind"] = kind
	s["region"] = r
	# A region's sites are its bread and butter, not its walls: the first
	# two tiers only (measured: tier-3 cisterns of 378 against a Core 10
	# crew in water of about 300 were never cleared).
	if int(s["tier"]) > 1:
		s["tier"] = 1
		s["need"] = snappedf(NEED_BASE * growth(core_level) * float(TIERS[1]), 1.0)
		s["left"] = s["need"]
	s["terrain"] = String(reg["terrain"])
	s["armor"] = String(reg["terrain"]) == "rock"
	s["hazard"] = minf(float(KINDS[kind]["hazard"]) * (1.0 + 0.02 * float(depth)), 0.6)
	return s


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
	# Rock, from the Core's level that makes Breakers: what they are for.
	var armor: bool = core_level >= BREAKER_CORE and ARMORED.has(kind)
	return {"kind": kind, "tier": tier, "need": need, "left": need, "hazard": hazard,
		"serial": serial, "core": core_level, "depth": depth, "armor": armor}


## What clearing site `s` pays, given the factory's measured credits a
## second: {"credits", "research", "res", "n", "salvage"}.
static func reward(s: Dictionary, credits_per_sec: float) -> Dictionary:
	if s.is_empty():
		return {}
	var need: float = float(s["need"])
	var tier: float = float(TIERS[int(s["tier"])])
	var pay: float = EARLY_PAY if int(s.get("core", RIG_CORE)) < RIG_CORE else 1.0
	var res: int = int(KINDS[String(s["kind"])]["res"])
	return {
		"credits": maxf(need * CREDITS_PER_NEED * pay, credits_per_sec * REWARD_SECONDS * tier),
		"research": need * RESEARCH_PER_NEED * pay,
		"res": res,
		"n": int(ceil(need * (RESONITE_PER_NEED if res == MachineDB.Res.RESONITE else UNITS_PER_NEED))),
		"salvage": salvage(s),
	}


## What a sortie burns under a Core of `level`, following what the era's
## store holds: Ingots; from PLATE_FUEL_CORE Plates -- the Core 6 and 7
## eras turn their Ingots into Plates and no row keeps Ingots (measured: a
## Core 6 store held no Ingot and 8,389 Plates, and the crew stood at the
## Bay for five hours); from the Core 8 era Alloy, whose factory runs on
## crystal and makes few of either (measured: a Core 8 factory held 38
## Ingots, its crew of thirteen needed 173 for a sortie, and sat at the
## Core for four hours).
const PLATE_FUEL_CORE := 6


static func fuel_res(level: int) -> int:
	if level >= MachineDB.FRAME_CORE:
		return MachineDB.Res.ALLOY
	return MachineDB.Res.PLATE if level >= PLATE_FUEL_CORE else MachineDB.Res.INGOT


## What a sortie of `n` Rigs burns under a Core of `level`, in fuel_res.
static func fuel(n: int, level: int, b: int = 0, v: int = 0) -> int:
	return int(ceil((float(n) + float(v) + float(b) * BREAKER_FUEL) * FUEL_PER_RIG * growth(level)))


## Seconds a sortie to site `s` takes, out and back.
static func trip(s: Dictionary) -> float:
	if String(s.get("kind", "")) == "survey":
		return SURVEY_TRIP
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
