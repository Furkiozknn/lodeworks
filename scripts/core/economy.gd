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
		"desc": "All machines run 15% faster.",
		"cost_research": 40.0,
		"cost_cores": 0,
		"max": 8,
		"cost_growth": 2.1,
		"effect": "speed",
		"per_level": 0.15,
	},
	"yield_1": {
		"name": "Deeper Bore",
		"desc": "Machines that produce from nothing yield 20% more.",
		"cost_research": 65.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.3,
		"effect": "yield",
		"per_level": 0.20,
	},
	"value_1": {
		"name": "Refinery Contracts",
		"desc": "Everything sells for 18% more.",
		"cost_research": 90.0,
		"cost_cores": 0,
		"max": 6,
		"cost_growth": 2.4,
		"effect": "value",
		"per_level": 0.18,
	},
	"research_1": {
		"name": "Field Notes",
		"desc": "Labs produce 25% more research.",
		"cost_research": 120.0,
		"cost_cores": 0,
		"max": 5,
		"cost_growth": 2.5,
		"effect": "research",
		"per_level": 0.25,
	},
	"heat_tolerance": {
		"name": "Ceramic Lining",
		"desc": "Every machine tolerates 0.6 more heat before it chokes.",
		"cost_research": 150.0,
		"cost_cores": 1,
		"max": 5,
		"cost_growth": 2.6,
		"effect": "tolerance",
		"per_level": 0.6,
	},
	"offline_cap": {
		"name": "Night Shift",
		"desc": "Offline production banks 2 more hours.",
		"cost_research": 200.0,
		"cost_cores": 1,
		"max": 6,
		"cost_growth": 2.2,
		"effect": "offline_hours",
		"per_level": 2.0,
	},
	"offline_rate": {
		"name": "Standing Orders",
		"desc": "Offline production runs at 12% more of your live rate.",
		"cost_research": 260.0,
		"cost_cores": 2,
		"max": 4,
		"cost_growth": 2.8,
		"effect": "offline_rate",
		"per_level": 0.12,
	},
	"core_yield": {
		"name": "Seismic Survey",
		"desc": "A collapse yields 25% more Cores. Compounds with every run.",
		"cost_research": 400.0,
		"cost_cores": 3,
		"max": 5,
		"cost_growth": 3.0,
		"effect": "core_yield",
		"per_level": 0.25,
	},
	"blueprint_slots": {
		"name": "Drafting Table",
		"desc": "One more blueprint slot for saved layouts.",
		"cost_research": 180.0,
		"cost_cores": 1,
		"max": 3,
		"cost_growth": 2.4,
		"effect": "blueprints",
		"per_level": 1.0,
	},
}

const TREE_ORDER := ["throughput_1", "yield_1", "value_1", "research_1",
	"heat_tolerance", "offline_cap", "offline_rate", "blueprint_slots",
	"core_yield"]

## Base offline behaviour before upgrades. Generous enough that a player who
## opens the game once a day is rewarded, small enough that playing is better
## than not playing.
const OFFLINE_BASE_HOURS := 4.0
const OFFLINE_BASE_RATE := 0.45
const OFFLINE_MAX_HOURS := 24.0


static func upgrade_cost(id: String, level: int) -> Dictionary:
	var u: Dictionary = RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return {"research": INF, "cores": 999999}
	var g: float = pow(float(u["cost_growth"]), float(level))
	return {
		"research": float(u["cost_research"]) * g,
		"cores": int(ceil(float(u["cost_cores"]) * (1.0 + 0.6 * float(level)))),
	}


## Cores earned by collapsing right now.
##
## Square-rooted on credits so the first collapse of a long run is worth doing
## and the tenth hour is not worth ten times the first -- that is what stops
## the optimal strategy being "never collapse".
static func cores_for_collapse(max_depth: int, lifetime_credits: float,
		core_yield_bonus: float = 0.0) -> int:
	if max_depth < COLLAPSE_MIN_DEPTH:
		return 0
	var depth_part: float = pow(float(max_depth - COLLAPSE_MIN_DEPTH + 1), 1.25)
	var credit_part: float = sqrt(maxf(lifetime_credits, 0.0) / 2500.0)
	var raw: float = depth_part * (1.0 + credit_part) * (1.0 + core_yield_bonus)
	return int(floor(raw))


static func can_collapse(max_depth: int) -> bool:
	return max_depth >= COLLAPSE_MIN_DEPTH


## Applied multipliers for a given set of upgrade levels.
static func multipliers(levels: Dictionary) -> Dictionary:
	var m: Dictionary = {
		"speed": 1.0,
		"yield": 1.0,
		"value": 1.0,
		"research": 1.0,
		"tolerance": 0.0,
		"offline_hours": OFFLINE_BASE_HOURS,
		"offline_rate": OFFLINE_BASE_RATE,
		"core_yield": 0.0,
		"blueprints": 1.0,
	}
	for id: String in RESEARCH_TREE:
		var lvl: int = int(levels.get(id, 0))
		if lvl <= 0:
			continue
		var u: Dictionary = RESEARCH_TREE[id]
		var per: float = float(u["per_level"])
		var effect: String = String(u["effect"])
		match effect:
			"speed", "yield", "value", "research":
				m[effect] = float(m[effect]) + per * float(lvl)
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
		return "%ds" % s
	if s < 3600:
		return "%dm %ds" % [s / 60, s % 60]
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	return "%dh %dm" % [h, m]
