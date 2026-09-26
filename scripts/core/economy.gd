class_name Economy
extends RefCounted

## Currencies, the research tree, and the collapse.
##
## Three currencies, each earned a different way, because a single currency
## collapses every decision into "buy the biggest number".
##
##   Credits   spent on machines. Reset by a collapse. The tactical layer.
##   Research  spent on the tree. Reset by a collapse. Earned only via Labs,
##             so the player must give up selling space to get it.
##   Cores     spent on the tree's permanent tier. SURVIVES a collapse. The
##             only thing that does.
##
## The reason Research resets and Cores do not is the shape of the session: a
## run should end with a real decision ("collapse now and bank Cores, or push
## one more stratum for a better conversion?"), and that decision only exists
## if something is genuinely lost.

const COLLAPSE_MIN_DEPTH := 3

## Permanent upgrades. Flat, cheap to extend, and every one changes the board
## rather than just the number on it.
const RESEARCH_TREE := {
	"throughput_1": {
		"name": "Tighter Tolerances",
		"short": "Every machine works faster.",
		"desc": "All machines run 15% faster.",
		"cost_research": 40.0,
		"cost_cores": 0,
		"max": 8,
		"cost_growth": 2.1,
		"effect": "speed",
		"branch": "production",
		"per_level": 0.15,
		"core": 1,
	},
	"yield_1": {
		"name": "Deeper Bore",
		# Yield multiplies what a Digger or a Maker turns out (Simulation
		# `yield_mult`). A Lab's research and a Vault's sale are not yields.
		"short": "Diggers and Makers turn out more.",
		"desc": "Every Digger and Maker turns out 20% more of what it makes. Labs and Vaults are not changed.",
		"cost_research": 65.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.3,
		"effect": "yield",
		"branch": "production",
		"per_level": 0.20,
		"core": 2,
	},
	"value_1": {
		"name": "Refinery Contracts",
		"short": "Everything sells for more.",
		"desc": "Everything sells for 18% more.",
		"cost_research": 90.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.4,
		"effect": "value",
		"branch": "efficiency",
		"per_level": 0.18,
		"core": 3,
	},
	"research_1": {
		"name": "Field Notes",
		"short": "Labs make more research.",
		"desc": "Labs produce 25% more research.",
		"cost_research": 120.0,
		"cost_cores": 0,
		"max": 5,
		"cost_growth": 2.5,
		"effect": "research",
		"branch": "efficiency",
		"per_level": 0.25,
		"core": 4,
	},
	# The Amplification era's research (the Core's level 6), and the one
	# that keeps the Labs working once the first four lines are complete:
	# every earlier line is at its end by the Core's level 6
	# (docs/PROGRESSION.md, "Core 7"). It changes what a layout is worth,
	# not a flat number: a Booster's neighbours get more of it, and every
	# Booster is warm (MachineDB: an Amplifier gives off 1.0, a Duplicator
	# 1.6), so packing them in is a trade against heat.
	"resonance": {
		"name": "Resonant Frames",
		"short": "Boosters push harder.",
		"desc": "Every Amplifier, Condenser and Duplicator gives its neighbours 15% more of its boost.",
		"cost_research": 60000.0,
		"cost_cores": 0,
		"max": 4,
		"cost_growth": 2.5,
		"effect": "resonance",
		"branch": "production",
		"per_level": 0.15,
		"core": 6,
	},
	"heat_tolerance": {
		"name": "Ceramic Lining",
		"short": "Machines can take more heat.",
		"desc": "Every machine tolerates 0.6 more heat before it chokes.",
		"cost_research": 150.0,
		"cost_cores": 3,
		"max": 5,
		"cost_growth": 2.6,
		"effect": "tolerance",
		"branch": "heat",
		"per_level": 0.6,
		"core": 3,
	},
	"offline_cap": {
		"name": "Night Shift",
		"short": "The shaft works longer while you are away.",
		"desc": "Offline production banks 2 more hours.",
		"cost_research": 200.0,
		"cost_cores": 3,
		"max": 6,
		"cost_growth": 2.2,
		"effect": "offline_hours",
		"branch": "logistics",
		"per_level": 2.0,
		"core": 1,
	},
	"offline_rate": {
		"name": "Standing Orders",
		"short": "The shaft works harder while you are away.",
		"desc": "Offline production runs at 12% more of your live rate.",
		"cost_research": 260.0,
		"cost_cores": 6,
		"max": 4,
		"cost_growth": 2.8,
		"effect": "offline_rate",
		"branch": "logistics",
		"per_level": 0.12,
		"core": 2,
	},
	"core_yield": {
		"name": "Seismic Survey",
		"short": "A collapse gives more Cores.",
		"desc": "A collapse yields 25% more Cores. Compounds with every run.",
		"cost_research": 400.0,
		"cost_cores": 9,
		"max": 5,
		"cost_growth": 3.0,
		"effect": "core_yield",
		"branch": "core",
		"per_level": 0.25,
		"core": 3,
	},
	"blueprint_slots": {
		"name": "Drafting Table",
		"short": "One more saved layout.",
		"desc": "One more blueprint slot for saved layouts.",
		"cost_research": 180.0,
		"cost_cores": 3,
		"max": 3,
		"cost_growth": 2.4,
		"effect": "blueprints",
		"branch": "core",
		"per_level": 1.0,
		"core": 2,
	},
	# The crew's research (Operations): every Rig stronger on a sortie. Its
	# own branch, the first of the robots' tree; opened with the crew, two
	# levels a Core level, so it grows with the sites it is for.
	"rig_plating": {
		"name": "Rig Plating",
		"short": "Every Rig is stronger.",
		"desc": "Every Rig brings 20% more strength to a sortie, for each level.",
		"cost_research": 400.0,
		"cost_cores": 0,
		"max": 12,
		"cost_growth": 2.1,
		"effect": "rig_power",
		"branch": "robotics",
		"per_level": 0.2,
		"core": MachineDB.RIG_CORE,
	},
	# The doctrines' lines (DOCTRINES): research only, opened by the Core's
	# level DOCTRINE_CORE, and bought -- and worth anything -- only in a
	# shaft that follows their doctrine.
	"vein_1": {
		"name": "Crystal Lattice",
		"short": "Deep Bores dig more crystal.",
		"desc": "Every Deep Bore digs 20% more crystal. A Deep Survey line: it works only in a shaft that follows the Deep Survey.",
		"cost_research": 30000.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.0,
		"effect": "vein",
		"branch": "deep",
		"per_level": 0.2,
		"core": 7,
		"doctrine": "deep",
	},
	"survey_1": {
		"name": "Survey Charges",
		"short": "Going down costs less.",
		"desc": "Every stratum's quota is 8% lower. A Deep Survey line: it works only in a shaft that follows the Deep Survey.",
		"cost_research": 30000.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.0,
		"effect": "quota",
		"branch": "deep",
		"per_level": 0.08,
		"core": 7,
		"doctrine": "deep",
	},
	"cryo_1": {
		"name": "Cryo Lines",
		"short": "Coolers cool harder.",
		"desc": "Coolant Cells and Condensers cool 15% harder. A Heat Engineering line: it works only in a shaft that follows Heat Engineering.",
		"cost_research": 30000.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.0,
		"effect": "cooling",
		"branch": "heat",
		"per_level": 0.15,
		"core": 7,
		"doctrine": "thermal",
	},
	"mass_1": {
		"name": "Thermal Mass",
		"short": "Every machine takes more heat.",
		"desc": "Every machine tolerates 0.4 more heat before it chokes. A Heat Engineering line: it works only in a shaft that follows Heat Engineering.",
		"cost_research": 30000.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.0,
		"effect": "tolerance",
		"branch": "heat",
		"per_level": 0.4,
		"core": 7,
		"doctrine": "thermal",
	},
	"jigs_1": {
		"name": "Frame Jigs",
		"short": "Frames and Components sell for more.",
		"desc": "Frames and Components sell for 20% more. A Precision Works line: it works only in a shaft that follows Precision Works.",
		"cost_research": 30000.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.0,
		"effect": "fine_value",
		"branch": "efficiency",
		"per_level": 0.2,
		"core": 7,
		"doctrine": "precision",
	},
	"benches_1": {
		"name": "Lab Benches",
		"short": "Labs learn more from the deep chain.",
		"desc": "Labs learn 25% more from an Alloy or a Frame. A Precision Works line: it works only in a shaft that follows Precision Works.",
		"cost_research": 30000.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.0,
		"effect": "deep_learn",
		"branch": "efficiency",
		"per_level": 0.25,
		"core": 7,
		"doctrine": "precision",
	},
}

const TREE_ORDER := ["throughput_1", "yield_1", "value_1", "research_1", "resonance",
	"heat_tolerance", "offline_cap", "offline_rate", "blueprint_slots",
	"core_yield", "vein_1", "survey_1", "cryo_1", "mass_1", "jigs_1", "benches_1", "rig_plating"]

## What each line of the tree is about: the research grid shows it branch by
## branch, in this order.
const BRANCHES := {
	"production": "Production",
	"efficiency": "Efficiency",
	"heat": "Heat",
	"deep": "Deep mining",
	"logistics": "Logistics",
	"core": "Core",
	"robotics": "Robotics",
}


## --- doctrines ------------------------------------------------------------------
##
## From the Core's level DOCTRINE_CORE a shaft follows one doctrine, chosen
## once and kept until the shaft collapses (Sim.choose_doctrine). Each opens
## two lines of research the others do not (the lines marked "doctrine"),
## and only the chosen doctrine's lines are bought or count -- so the Core 7
## era asks for a strategy, not for everything: the crystal and the descent,
## the heat, or the parts and the Labs. Unlike the rest of the tree, a
## doctrine's research is the shaft's: a collapse clears it with the
## doctrine, so every shaft's Core 7 era has research to spend and a
## choice to make again -- the same one, or another. (Kept, it met the
## doctrine row of every later shaft the moment it was chosen.)
const DOCTRINE_CORE := 7

const DOCTRINES := {
	"deep": {
		"name": "Deep Survey",
		"short": "More crystal, and the way down costs less.",
		"lines": ["vein_1", "survey_1"],
	},
	"thermal": {
		"name": "Heat Engineering",
		"short": "Stronger cooling, and every machine takes more heat.",
		"lines": ["cryo_1", "mass_1"],
	},
	"precision": {
		"name": "Precision Works",
		"short": "Frames and Components pay more, and Labs learn more.",
		"lines": ["jigs_1", "benches_1"],
	},
}

const DOCTRINE_ORDER := ["deep", "thermal", "precision"]

## Base offline behaviour before upgrades. Generous enough that a player who
## opens the game once a day is rewarded, small enough that playing is better
## than not playing.
const OFFLINE_BASE_HOURS := 4.0
const OFFLINE_BASE_RATE := 0.45
const OFFLINE_MAX_HOURS := 24.0


## Core costs rise faster than they used to (1.2 per level rather than 0.6),
## so the last level of an upgrade is the expensive one and the first is still
## reachable after a single early collapse. The whole tree now costs 372 Cores
## against 88 before; a strong run pays around 86, so finishing it is a
## fifteen-or-so-collapse project instead of a formality.
const CORE_COST_GROWTH := 1.2


## Research lines open at a Factory Core level (`core`), and the Core caps how
## far each may go: RESEARCH_PER_CORE levels for every Core level since it
## opened -- the way a central building caps its laboratory. A level already
## bought stays bought (the tree survives a collapse); the cap is on buying.
const RESEARCH_PER_CORE := 2


static func research_cap(id: String, core_level: int) -> int:
	var u: Dictionary = RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return 0
	var open: int = core_level - int(u.get("core", 1)) + 1
	return clampi(open * RESEARCH_PER_CORE, 0, int(u["max"]))


static func upgrade_cost(id: String, level: int) -> Dictionary:
	var u: Dictionary = RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return {"research": INF, "cores": 999999}
	var g: float = pow(float(u["cost_growth"]), float(level))
	return {
		"research": float(u["cost_research"]) * g,
		"cores": int(ceil(float(u["cost_cores"])
			* (1.0 + CORE_COST_GROWTH * float(level)))),
	}


## Cores earned by collapsing right now.
##
## Rewritten after `tools/journey_lab.gd` played the long game and found the
## prestige layer had no floor and no ceiling worth caring about. The old
## curve used `sqrt(lifetime / 2500)` as a MULTIPLIER on depth, and lifetime
## credits are unbounded, so a single seventy-seven minute run to stratum 20
## paid **774 Cores against a permanent tree that cost 88 in total**. The
## tree was finished nearly nine times over by the first collapse, every
## subsequent collapse was a strict loss -- it takes the Research with it --
## and the long game was over before it started. That is the Realm Grinder
## failure exactly: "at each new prestige tier you generally don't have more
## than one new goal to chase".
##
## Two changes. Credits now enter logarithmically rather than as a square
## root, so an hour that earns ten times as much is worth about one and a
## half times as many Cores instead of three; and the depth exponent comes
## down from 1.25 to 1.1. The same stratum-20 run now pays about 86.
##
## What is deliberately kept: depth matters more than money, a collapse below
## stratum 3 pays nothing at all, and half an hour to stratum 3 is still worth
## a Core -- the first prestige has to pay or nobody takes it and the long
## game never starts.
const CREDIT_SCALE := 10000.0
const CREDIT_BASE := 6.0
const DEPTH_EXPONENT := 1.1


static func cores_for_collapse(max_depth: int, lifetime_credits: float,
		core_yield_bonus: float = 0.0) -> int:
	if max_depth < COLLAPSE_MIN_DEPTH:
		return 0
	var depth_part: float = pow(float(max_depth - COLLAPSE_MIN_DEPTH + 1),
		DEPTH_EXPONENT)
	var credit_part: float = log(1.0 + maxf(lifetime_credits, 0.0) / CREDIT_SCALE) \
		/ log(CREDIT_BASE)
	var raw: float = depth_part * (1.0 + credit_part) * (1.0 + core_yield_bonus)
	return int(floor(raw))


static func can_collapse(max_depth: int) -> bool:
	return max_depth >= COLLAPSE_MIN_DEPTH


## The doctrine research line `id` belongs to, or "" for a line every shaft
## has.
static func doctrine_of(id: String) -> String:
	return String((RESEARCH_TREE.get(id, {}) as Dictionary).get("doctrine", ""))


## Applied multipliers for a given set of upgrade levels, in a shaft that
## follows `doctrine` (another doctrine's lines count for nothing).
static func multipliers(levels: Dictionary, doctrine: String = "") -> Dictionary:
	var m: Dictionary = {
		"speed": 1.0,
		"yield": 1.0,
		"value": 1.0,
		"research": 1.0,
		"resonance": 1.0,
		"tolerance": 0.0,
		"offline_hours": OFFLINE_BASE_HOURS,
		"offline_rate": OFFLINE_BASE_RATE,
		"core_yield": 0.0,
		"blueprints": 1.0,
		"vein": 1.0,
		"quota": 1.0,
		"cooling": 1.0,
		"fine_value": 1.0,
		"deep_learn": 1.0,
		"rig_power": 1.0,
	}
	for id: String in RESEARCH_TREE:
		var lvl: int = int(levels.get(id, 0))
		if lvl <= 0:
			continue
		if doctrine_of(id) != "" and doctrine_of(id) != doctrine:
			continue
		var u: Dictionary = RESEARCH_TREE[id]
		var per: float = float(u["per_level"])
		var effect: String = String(u["effect"])
		match effect:
			"speed", "yield", "value", "research", "resonance", "vein", "cooling", "fine_value", "deep_learn", \
					"rig_power":
				m[effect] = float(m[effect]) + per * float(lvl)
			"quota":
				m[effect] = maxf(float(m[effect]) - per * float(lvl), 0.2)
			"tolerance", "core_yield":
				m[effect] = float(m[effect]) + per * float(lvl)
			"offline_hours":
				m[effect] = minf(float(m[effect]) + per * float(lvl), OFFLINE_MAX_HOURS)
			"offline_rate":
				m[effect] = minf(float(m[effect]) + per * float(lvl), 1.0)
			"blueprints":
				m[effect] = float(m[effect]) + per * float(lvl)
	return m


## What the player earned while the app was closed.
##
## Honest by construction: it is the rate their own board was measured at,
## multiplied by capped time and a fraction below 1. No secret nerf, no secret
## boost, and the UI shows the same three numbers this function uses.
static func offline_yield(rate_per_sec: float, seconds_away: float,
		mult: Dictionary, double_it: bool = false) -> Dictionary:
	var cap_seconds: float = float(mult.get("offline_hours", OFFLINE_BASE_HOURS)) * 3600.0
	var counted: float = clampf(seconds_away, 0.0, cap_seconds)
	var eff: float = float(mult.get("offline_rate", OFFLINE_BASE_RATE))
	var amount: float = maxf(rate_per_sec, 0.0) * counted * eff
	if double_it:
		amount *= 2.0
	return {
		"amount": amount,
		"seconds_counted": counted,
		"seconds_away": seconds_away,
		"capped": seconds_away > cap_seconds,
		"rate": eff,
	}


## Compact human formatting. Idle games live or die on whether a big number is
## readable at a glance on a phone.
static func fmt(n: float) -> String:
	var a: float = absf(n)
	if a < 1000.0:
		if a < 10.0 and not is_equal_approx(n, roundf(n)):
			return "%.1f" % n
		return "%d" % int(roundf(n))
	const SUFFIX := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"]
	var tier: int = int(floor(log(a) / log(1000.0)))
	tier = clampi(tier, 0, SUFFIX.size() - 1)
	var scaled: float = n / pow(1000.0, float(tier))
	if absf(scaled) >= 100.0:
		return "%.0f%s" % [scaled, SUFFIX[tier]]
	if absf(scaled) >= 10.0:
		return "%.1f%s" % [scaled, SUFFIX[tier]]
	return "%.2f%s" % [scaled, SUFFIX[tier]]


static func fmt_duration(seconds: float) -> String:
	var s: int = int(maxf(seconds, 0.0))
	if s < 60:
		return Loc.t("%ds") % s
	if s < 3600:
		return Loc.t("%dm %ds") % [s / 60, s % 60]
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	return Loc.t("%dh %dm") % [h, m]
