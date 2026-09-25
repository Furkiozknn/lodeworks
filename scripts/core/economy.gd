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
		"grows": true,
		"cost_growth": 2.1,
		"effect": "speed",
		"per_level": 0.15,
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
		"grows": true,
		"cost_growth": 2.3,
		"effect": "yield",
		"per_level": 0.20,
	},
	"value_1": {
		"name": "Refinery Contracts",
		"short": "Everything sells for more.",
		"desc": "Everything sells for 18% more.",
		"cost_research": 90.0,
		"cost_cores": 0,
		"max": 6,
		"grows": true,
		"cost_growth": 2.4,
		"effect": "value",
		"per_level": 0.18,
	},
	"research_1": {
		"name": "Field Notes",
		"short": "Labs make more research.",
		"desc": "Labs produce 25% more research.",
		"cost_research": 120.0,
		"cost_cores": 0,
		"max": 5,
		"grows": true,
		"cost_growth": 2.5,
		"effect": "research",
		"per_level": 0.25,
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
		"per_level": 0.6,
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
		"per_level": 2.0,
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
		"per_level": 0.12,
	},
	"core_yield": {
		"name": "Seismic Survey",
		"short": "A collapse gives more Cores.",
		"desc": "A collapse yields 25% more Cores. Compounds with every run.",
		"cost_research": 400.0,
		"cost_cores": 9,
		"max": 5,
		"grows": true,
		"cost_growth": 3.0,
		"effect": "core_yield",
		"per_level": 0.25,
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


## Core costs rise faster than they used to (1.2 per level rather than 0.6),
## so the last level of an upgrade is the expensive one and the first is still
## reachable after a single early collapse. The whole tree now costs 372 Cores
## against 88 before; a strong run pays around 86, so finishing it is a
## fifteen-or-so-collapse project instead of a formality.
const CORE_COST_GROWTH := 1.2


## --- research without an end ----------------------------------------------
##
## The tree used to finish: four collapses and about four hours of play
## (docs/AUDIT.md, "Collapse after collapse, played"), after which a
## collapse bought nothing. The owner's decision of 25 September 2026: the
## game is to keep a player growing for as long as they play, the way Clash
## of Clans does, so the tree does not end.
##
## It works the way a Town Hall does (docs/research/clash-ux.md, section 2):
## **every collapse raises the limit of every line marked `grows` by one
## level.** The limit is always there to reach, and the next collapse always
## moves it -- so there is always a next level, and always a reason to
## collapse. The lines that do not grow are the ones whose effect has a
## ceiling of its own (offline hours and rate) or would remove the heat
## puzzle if it kept going (Ceramic Lining).
##
## Past a line's first limit a level is a **deep level**, and three things
## change, each measured by the collapse lab (docs/AUDIT.md, "Research
## without an end"):
##
##   - Its effect multiplies instead of adding: a deep level of Tighter
##     Tolerances makes machines 15% faster than they already are. Added,
##     the twentieth level was worth a twentieth of the first, and the runs
##     stopped at the same stratum however many were bought.
##   - It is priced mainly in Cores: DEEP_CORES, DEEP_CORE_GROWTH dearer
##     each deep level. Cores are what a collapse pays, so the deeper a
##     player goes the more they buy -- priced in Research, Cores piled up
##     unspent from the fourth collapse on while a run's Research bought one
##     deep level or two.
##   - It still costs some Research, so the Labs stay worth their tiles:
##     DEEP_RESEARCH_SHARE of what the line's steep curve would ask at its
##     first limit, LATE_GROWTH dearer each deep level after that. Kept on
##     the steep curve for ever, every level after the tenth would be
##     unreachable: an end by another name.
##
## The limit is the pace: at most one deep level a line a collapse, so the
## growth a run can buy is bounded however rich the player is.
const LATE_GROWTH := 1.2
const DEEP_RESEARCH_SHARE := 0.1
const DEEP_CORES := 20.0
const DEEP_CORE_GROWTH := 1.3


## The highest level line `id` can reach after `collapses` collapses.
static func max_level(id: String, collapses: int) -> int:
	var u: Dictionary = RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return 0
	var base: int = int(u["max"])
	return base + maxi(collapses, 0) if bool(u.get("grows", false)) else base


static func upgrade_cost(id: String, level: int) -> Dictionary:
	var u: Dictionary = RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return {"research": INF, "cores": 999999}
	var base: int = int(u["max"])
	var g: float = pow(float(u["cost_growth"]), float(mini(level, base)))
	var cores: float = float(u["cost_cores"]) * (1.0 + CORE_COST_GROWTH * float(level))
	if level >= base and bool(u.get("grows", false)):
		var deep: int = level - base
		g *= DEEP_RESEARCH_SHARE * pow(LATE_GROWTH, float(deep))
		cores = maxf(cores, DEEP_CORES) * pow(DEEP_CORE_GROWTH, float(deep))
	return {
		"research": float(u["cost_research"]) * g,
		"cores": int(ceil(cores)),
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
		# Deep levels (past the first limit) multiply; see max_level.
		var deep: int = maxi(lvl - int(u["max"]), 0) if bool(u.get("grows", false)) else 0
		var flat: int = lvl - deep
		match effect:
			"speed", "yield", "value", "research":
				m[effect] = (float(m[effect]) + per * float(flat)) * pow(1.0 + per, float(deep))
			"core_yield":
				m[effect] = (1.0 + float(m[effect]) + per * float(flat)) \
					* pow(1.0 + per, float(deep)) - 1.0
			"tolerance":
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
