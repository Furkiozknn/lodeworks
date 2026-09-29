extends RefCounted

## A competent player chasing the Factory Core, playing the real `Sim`
## (tools/core_journey.gd runs it and prints what it measured).
##
## It is a model, and it says what it does: every beat it grows the Core
## when it can, goes down when it can, buys the research and machine levels
## the Core's next level asks for, works through the Core's open rows --
## a chain into the Core's store for a material, a Vault level for a store
## too small, a Boiler or a Coolant Cell for a machine off its heat, a Lab
## for research -- and spends what is left on "What now?" (Worklist), the
## same list the player sees. It keeps the Core's right and front sides for
## the machines that feed the store. It never uses a number the player
## cannot see.
##
## From the Core's level 7 it follows a doctrine (DOCTRINE, or
## LODEWORKS_CORE_DOCTRINE) and, once the shaft reaches the crystal of
## stratum MachineDB.CRYSTAL_DEPTH, grows the factory with the deep chain:
## Deep Bores feeding White Heat Smelters, each with a Vault, on free ground
## away from the Core (`_build_deep`), and an Alloy line into the store when
## the Core asks for it.

const BEAT := 5.0

## The lines a player lays out for each Core level, feeders first, as a
## player who has read the Core's next level builds them: the machines that
## fill the store touching the Core, their feeders behind them, heat and
## cold beside them, an outlet for when the store is full.
## Level 1, the right side: two Smelters with their Boilers, Crushers and
## Drills, a Vault between them, a Lab behind the upper Boiler.
## Level 2, the front: two Presses fed through Coolant Cells by Smelters
## that share a Boiler, their Crushers and Drills, a Vault between the
## Presses and Coolant on their outer sides.
## Level 3, the left side and the back: three Assemblers, each fed by a
## Press between Coolant Cells, a Smelter with a Boiler, a Crusher and
## Drills; Coolant beside the Assemblers, and a Vault beside each for when
## the store is full.
## Each is started once its Core level is reached and its maker found
## (`from`, a stratum); past these the player works from the Core's rows
## and "What now?" alone. A fourth element is the machine's job.
const PLANS := [
	{"core": 1, "from": 1, "cells": [
		[26, 21, "drill"], [25, 20, "drill"], [25, 21, "crusher"], [24, 21, "smelter"],
		[24, 20, "boiler"], [24, 22, "vault"], [24, 19, "lab"],
		[26, 23, "drill"], [25, 24, "drill"], [25, 23, "crusher"], [24, 23, "smelter"],
		[24, 24, "boiler"],
	]},
	{"core": 2, "from": 3, "cells": [
		[19, 27, "drill"], [21, 27, "drill"], [20, 27, "crusher"], [20, 26, "smelter"],
		[21, 26, "boiler"], [20, 25, "coolant"], [19, 24, "coolant"], [20, 24, "press"],
		[21, 24, "vault"],
		[23, 27, "drill"], [22, 27, "crusher"], [22, 26, "smelter"], [22, 25, "coolant"],
		[23, 24, "coolant"], [22, 24, "press"],
	]},
	{"core": 3, "from": 5, "cells": [
		[16, 19, "drill"], [16, 21, "drill"], [16, 20, "crusher"], [17, 20, "smelter"],
		[17, 21, "boiler"], [18, 19, "coolant"], [18, 21, "coolant"], [18, 20, "press"],
		[19, 21, "coolant"], [19, 20, "assembler"], [19, 19, "vault"],
		[16, 23, "drill"], [16, 22, "crusher"], [17, 22, "smelter"], [18, 23, "coolant"],
		[18, 22, "press"], [19, 22, "assembler"], [19, 23, "vault"],
		[20, 16, "drill"], [22, 16, "drill"], [21, 16, "crusher"], [21, 17, "smelter"],
		[22, 17, "boiler"], [20, 18, "coolant"], [22, 18, "coolant"], [21, 18, "press"],
		[20, 19, "coolant"], [21, 19, "assembler"], [22, 19, "vault"],
	]},
]

var S: Node
var t: float = 0.0
## The doctrine this player follows from the Core's level 7.
var doctrine: String = "deep"
## What the galleries' salvage goes to (LODEWORKS_CORE_SALVAGE): "gearing",
## Salvaged Gearing whenever it can be bought and Rig Plating when the crew
## needs it; "crew", Rig Plating whenever it can be bought and never
## Gearing; "none", Rig Plating when the crew needs it and never Gearing.
var salvage_mode: String = "gearing"
## [seconds, what] for every first: a Core level, a stratum, a machine type
## built, a machine level, a research level.
var events: Array = []
var _seen: Dictionary = {}


func _init(sim: Node) -> void:
	S = sim


## A new game, as a player starts one: an empty save, the Core brought online.
func fresh() -> void:
	Save.wipe()
	S._ensure()
	S.grid.clear()
	S.sim.reset_progress()
	S.credits = 0.0
	S.research = 0.0
	S.cores = 0
	S.salvage = 0
	S.salvage_earned = 0
	S.hauled = 0
	S.depth = 0
	S.max_depth = 0
	S.lifetime_credits = 0.0
	S.collapses = 0
	S.upgrade_levels = {}
	S.core_level = 1
	S.machine_levels = {}
	S.overdrive = {}
	S.stock = {}
	S.core_online = false
	S.unlocked.clear()
	S.best_core = 1
	S.doctrine = ""
	S.blueprints = []
	S.blueprint_pending = []
	S.clear_ops()
	S._recompute()
	S.power_core()


## Play `seconds` of real time at the real tick rate.
func advance(seconds: float) -> void:
	for _i in range(int(seconds * Simulation.TICK_HZ)):
		var out: Dictionary = S.sim.tick()
		S.after_tick(Simulation.TICK_DT)
		var c: float = float(out["credits"])
		S.credits += c
		S.lifetime_credits += c
		S.research += float(out["research"])
		t += Simulation.TICK_DT


func _event(key: String, what: String) -> void:
	if shaft > 1:
		key = "s%d:%s" % [shaft, key]
		what = "shaft %d: %s" % [shaft, what]
	if _seen.has(key):
		return
	_seen[key] = true
	events.append([t, what])


## The shaft this player is on: 1, then one more after each collapse.
var shaft: int = 1


## A collapse happened (core_journey.gd): the board is gone, so is the
## player's memory of it; the new shaft's Core is brought online.
func new_shaft() -> void:
	shaft += 1
	_dropped.clear()
	_bare.clear()
	_touched.clear()
	_fed_at.clear()
	_stuck_since.clear()
	_line.clear()
	_history.clear()
	S.power_core()


## One beat of decisions.
func act() -> void:
	var r: float = rate()
	_rate_now = r
	var earned: float = maxf(float(S.lifetime_credits) - _last_life, 0.0)
	_last_life = float(S.lifetime_credits)
	_repair_budget = minf(_repair_budget + earned * REPAIR_SHARE, r * 600.0)
	var c0: float = S.credits
	if S.can_upgrade_core():
		S.upgrade_core()
		_event("core%d" % S.core_level, "Core level %d (earning %s/s)" % [S.core_level, Economy.fmt(r)])
	c0 = _spent("the Core", c0)
	# From Core 7 the rock is hot enough that a stratum down is a layout to
	# rework: the player goes down only while nothing overheats, so the
	# factory settles on each stratum before the next.
	var settled: bool = S.core_level < MachineDB.OVERDRIVE_CORE or CoreLevels.stable(S) > 0
	# From Core 9 the strata are read before they are entered: the player
	# goes down while the Core's depth row asks for it -- straight through a
	# stratum where heat spreads far, rather than settling there -- and no
	# further (measured: settling on conductive strata 26 and 28 on the way
	# to 29 overheated 68 machines at once and halved the income).
	if S.core_level >= FORGE_FROM + 1:
		settled = _depth_wanted()
	if S.can_descend() and settled:
		S.descend()
		_event("depth%d" % S.depth, "stratum %d" % S.depth)
	c0 = _spent("strata", c0)
	if S.can_choose_doctrine():
		S.choose_doctrine(doctrine)
		_event("doctrine", "doctrine %s" % doctrine)
	if not S.blueprint_pending.is_empty():
		S.fill_pending()
	c0 = _spent("the blueprint", c0)
	_research()
	_contracts()
	c0 = S.credits
	# A Core row waiting on a posted Rig is served before the galleries take
	# the Rigs at home (measured: in the Sunken Works, whose water wants
	# Rigs, the sorties took every one and the Lens Grinder never had one).
	if _rows_wait_on_posts():
		_posting()
	_operations()
	c0 = _spent("the galleries", c0)
	_posting()
	_tuning()
	_bores()
	c0 = _spent("the Bay", c0)
	var reserve: float = _follow_plans()
	c0 = _spent("plans", c0)
	var building: bool = reserve > 0.0
	var open: Array = S.core_status().filter(func(st: Dictionary) -> bool: return not bool(st["met"]))
	# Saving for the Core: when what is left is bought with credits -- its
	# price, its machine levels, a bigger store -- spend nothing else, not
	# even on repairs (a player does not rebuild while saving).
	var buying: Array = [CoreLevels.Req.CREDITS, CoreLevels.Req.STOCK, CoreLevels.Req.MACHINE]
	var saving: bool = not open.is_empty() \
		and open.all(func(st: Dictionary) -> bool: return buying.has(int(st["req"][0])))
	_keep = 0.0
	_keep_levels = 0.0
	if not saving and S.core_level >= KEEP_FROM:
		# A player working towards the Core keeps what its rows are bought
		# with -- the Core's own price, and the machine and Vault levels it
		# asks for -- and grows the factory, or buys a level no row asks
		# for, on what is earned past it.
		for st: Dictionary in open:
			match int(st["req"][0]):
				CoreLevels.Req.CREDITS:
					_keep += float(st["need"])
				CoreLevels.Req.MACHINE:
					_keep_levels += float(S.machine_upgrade_cost(String(st["req"][1]))["credits"])
				CoreLevels.Req.STOCK:
					if int(st["cap"]) < int(st["need"]):
						_keep_levels += float(S.machine_upgrade_cost("vault")["credits"])
				CoreLevels.Req.OVERDRIVE:
					# From Core 8: the level a type must reach before it is
					# driven is a level the row asks for.
					if S.core_level >= FORGE_FROM and S.overdrive_blocker(String(st["req"][1])) == "level":
						_keep_levels += float(S.machine_upgrade_cost(String(st["req"][1]))["credits"])
		# From Core 7 the Core's price, once saved, is kept: spent on growth
		# it has to be earned again (measured: the credits row met and lost
		# for hours while the player grew the factory on it).
		if S.core_level >= MachineDB.OVERDRIVE_CORE:
			for row: Array in CoreLevels.requirements(S.core_level + 1):
				if int(row[0]) == CoreLevels.Req.CREDITS and S.credits >= float(row[1]):
					_keep += float(row[1])
		_keep += _keep_levels
		reserve += _keep
	if saving:
		for st: Dictionary in open:
			match int(st["req"][0]):
				CoreLevels.Req.CREDITS:
					reserve += float(st["need"])
				CoreLevels.Req.MACHINE:
					reserve += float(S.machine_upgrade_cost(String(st["req"][1]))["credits"])
				CoreLevels.Req.STOCK:
					if int(st["cap"]) < int(st["need"]):
						reserve += float(S.machine_upgrade_cost("vault")["credits"])
	else:
		_repair()
		_tidy()
	c0 = _spent("repairs", c0)
	if not building:
		for st: Dictionary in open:
			_pursue(st)
	c0 = _spent("the Core's rows", c0)
	if not saving:
		_spare_upgrades()
	c0 = _spent("spare levels", c0)
	_spare_overdrive()
	# From the Core's level KEEP_FROM no new line goes down while something
	# overheats and the Core asks for stability: on hot rock a new line is
	# what breaks it. Once nothing overheats, the factory grows again --
	# stability is counted in machines at work.
	var holding: bool = S.core_level >= KEEP_FROM and CoreLevels.stable(S) == 0 \
		and open.any(func(st: Dictionary) -> bool: return int(st["req"][0]) == CoreLevels.Req.STABLE)
	# The deep chain pays for itself in minutes of the Core 7 era's income:
	# a player builds it ahead of the levels the Core asks for -- while a
	# unit costs no more than DEEP_PAYBACK seconds of what the factory
	# earns, a unit a beat -- but not while saving for the Core itself.
	# From Core 8 the unit itself has to pay: a player adds one while what it
	# sells pays it back within DEEP_UNIT_PAYBACK -- each costs more than the
	# last (measured: 74 units at 2-3M each, most of them idle behind a full
	# store, and never the credits for a level the Core asked for).
	var pays: bool = S.core_level < FORGE_FROM \
		or _deep_cost() <= _unit_income() * DEEP_UNIT_PAYBACK and S.credits - _deep_cost() >= _keep
	if S.job_open("smelter", "alloy") and (_deep_units() < DEEP_UNITS or S.core_level >= FORGE_FROM) \
			and not saving and pays \
			and S.credits >= _deep_cost() * 1.5 and _deep_cost() <= r * DEEP_PAYBACK:
		_build_deep()
	c0 = _spent("the deep chain", c0)
	if S.credits > reserve and not holding:
		_grow()
	c0 = _spent("growth", c0)
	for id: String in S.machine_levels:
		_event("%s%d" % [id, int(S.machine_levels[id])], "%s level %d" % [id, int(S.machine_levels[id])])
	for id: String in S.upgrade_levels:
		_event("r%s%d" % [id, int(S.upgrade_levels[id])], "research %s %d" % [id, int(S.upgrade_levels[id])])
	for id: String in S.overdrive:
		_event("o%s%d" % [id, int(S.overdrive[id])], "%s Overdrive %d" % [id, int(S.overdrive[id])])
	for cell: int in S.grid.cells:
		var id: String = S.grid.machine_at(cell)
		_event("m" + id, "first " + id)


## The crew (Operations), from the Core's level 4: a Rig Frame, with the
## lines that feed it, where there is room, while the crew is short (a Rig
## walks to the Core by itself); Rigs repaired once they are a third worn,
## from Plates the Core's rows do not need; and a sortie to every site the
## Rigs at home clear -- or, while the Core asks for sites cleared and none
## can be, the whole crew to the weakest, which leaves it weaker.
func _operations() -> void:
	if S.crew_cap() <= 0 or not operations_on:
		return
	var asked: bool = false
	for st: Dictionary in S.core_status():
		asked = asked or int(st["req"][0]) == CoreLevels.Req.OPERATIONS and not bool(st["met"])
	# A Rig Frame the rock overheats goes, and no other is laid under this
	# Core (measured: with room earned for one more Rig on stratum 15, one
	# was laid, overheated, sold for stability and laid again, and Core 7's
	# stability row stood at 0 for 24 hours).
	for cell: int in S.grid.cells.keys():
		if S.grid.job_at(cell) == "rig" and S.sim.overheated_at(cell):
			# From the deep map the crew is what opens regions: cooled first
			# (measured: at Core 11 every Rig Frame overheated on stratum 27
			# and the crew stood at 12 of 16 for five hours).
			if S.core_level >= Operations.REGION_CORE and _fix_heat(cell):
				continue
			S.sell(cell)
			_rig_hot_core = S.core_level
			_rig_hot_t = t
	# From the deep map, where the crew is what opens a region, another is
	# tried an hour on (measured: a Rig Frame overheated once at Core 11 and
	# the crew stood at 12 of 16 for good).
	var rig_again: bool = _rig_hot_core < S.core_level \
		or S.core_level >= Operations.REGION_CORE and t - _rig_hot_t >= 3600.0
	if S.core_level >= MachineDB.RIG_CORE and _crew_total() < S.crew_cap() \
			and _rig_makers() < 1 and rig_again and t - _last_rig >= LAB_BEAT:
		_last_rig = t
		# Only the first Rig Frame may clear a patch of the yard for itself;
		# later ones go beside a Plate maker or wait (measured: with sites
		# earning the crew room every few minutes, each new Rig Frame sold a
		# patch of four machines, and the Core 5 factory shrank from 149
		# machines to 109 and lost its Duplicators' row for twelve hours).
		if not _place_rig_frame() and S.rigs_home() + S.rigs_out() <= Operations.FIRST_CREW:
			_build_job("assembler", "rig")
	# The crew whole, the Rig Frame goes: it would only stand there, warm,
	# until the Core's next level makes room for another Rig (measured: one
	# laid on stratum 9 overheated the Press beside it on stratum 12, and the
	# Core 5 stage was not over in two hours).
	if _crew_total() >= S.crew_cap():
		for cell: int in S.grid.cells.keys():
			if S.grid.job_at(cell) == "rig":
				S.sell(cell)
				_event("rigframe_sold", "first Rig Frame sold, the crew whole")
	var keep: Dictionary = _keep_materials()
	var plates: int = S.stock_of(MachineDB.Res.PLATE) - int(keep.get(MachineDB.Res.PLATE, 0))
	# Repaired at a third worn, or sooner when wear is all that keeps the
	# crew from every site on the board.
	var stuck: bool = S.rig_wear > 0.0
	for i in range(S.ops_board.size()):
		stuck = stuck and not (S.site(i).has("kind")
			and S.team_strength(S.site(i), S.rigs_home(), S.breakers, S.surveyors) >= float(S.site(i)["left"]))
	# Plates kept for a row the store cannot yet hold (the Vault's level
	# comes first) are not kept from a repair that is a sliver of them
	# (measured: 20 Plates of 8,389 were kept for a row of 25,000, and a worn
	# crew cleared no site for 75 minutes). Plates kept for a row the store
	# can pay are (measured: repairs of 50 Plates a sortie held Smelter 8's
	# 7,290 Plates at 6,900 for hours).
	var cheap: bool = S.repair_cost() * 50 <= S.stock_of(MachineDB.Res.PLATE) \
		and int(keep.get(MachineDB.Res.PLATE, 0)) > S.stock_cap()
	# A crew so worn it clears nothing is repaired from whatever Plates there
	# are (measured: with Plating bought first, a worn crew waited on Plates
	# kept for the Core 7 row and cleared no site from 2 h to 16 h).
	if (S.rig_wear >= 0.3 or stuck) and S.can_repair() and (plates >= S.repair_cost() or cheap or stuck):
		S.repair_rigs()
		_event("repair", "first Rigs repaired")
	# Fuel the Core's rows do not keep, as for repairs, unless the Core asks
	# for sites (measured: from Core 5 the sorties burnt the Ingots the Core 6
	# row asks for as fast as the starved Smelters made them, and the row
	# stood below its 8,000 for four hours).
	var fuel_res: int = Operations.fuel_res(S.core_level)
	var ingots: int = S.stock_of(fuel_res) - int(keep.get(fuel_res, 0))
	var kept_past_store: bool = int(keep.get(fuel_res, 0)) > S.stock_cap()
	# Rock on the board: a Rig refitted as a Breaker, up to a third of the
	# crew (Operations, "the Breaker").
	var rock: bool = false
	for i in range(S.ops_board.size()):
		rock = rock or Operations.armored(S.site(i))
	# A shaft whose first region is water keeps its Rigs: Breakers there
	# only as many as the Core's rows ask for.
	var breakers_wanted: int = (S.crew_cap() + 2) / 3
	if region_first == "sunken" and S.core_level >= Operations.REGION_CORE:
		breakers_wanted = 2
	if rock and S.refit_blocker("breaker") == "" and S.breakers + S.breakers_out() < breakers_wanted:
		S.refit_rig("breaker")
		_event("breaker", "first Rig refitted as a Breaker")
	if _deep_map() or _hold_sorties:
		return
	var weakest: int = -1
	for i in range(S.ops_board.size()):
		if i == _keep_slot:
			continue
		var tm: Vector3i = S.sortie_team(i)
		if tm.x + tm.y + tm.z <= 0 or not S.can_send(i, tm.x, tm.y, tm.z):
			continue
		if not asked and ingots < Operations.fuel(tm.x, S.core_level, tm.y, tm.z) and not kept_past_store:
			continue
		if S.team_strength(S.site(i), tm.x, tm.y, tm.z) >= float(S.site(i)["left"]):
			S.send_sortie(i, tm.x, tm.y, tm.z)
			_event("sortie", "first sortie")
			if tm.y > 0:
				_event("breaker_sortie", "first sortie with Breakers")
			if String(S.site(i).get("region", "")) != "" or Operations.slot_region(i) != "":
				_event("region_sortie", "first sortie into a region of the deep map")
			return
		if weakest < 0 or float(S.site(i)["left"]) < float(S.site(weakest)["left"]):
			weakest = i
	# No site the crew clears: the whole crew to the weakest while it takes
	# a third of it or more -- it earns that share and leaves the site weaker
	# for the next sortie -- or, while the Core asks for sites, whatever it
	# takes (measured: three sites of 114 against a crew of 80 froze the
	# galleries for seven hours; a sortie of 80 takes 70% of one).
	if weakest < 0:
		return
	var all: Vector3i = S.sortie_team(weakest)
	if S.rigs_out() + S.breakers_out() + S.surveyors_out() == 0 and (asked
			or S.team_strength(S.site(weakest), all.x, all.y, all.z) * 3.0 >= float(S.site(weakest)["left"])
			and (ingots >= Operations.fuel(all.x, S.core_level, all.y, all.z) or kept_past_store)):
		S.send_sortie(weakest, all.x, all.y, all.z)


var _last_rig: float = -1.0e9


## The region a player following this plan opens first (the journey's
## LODEWORKS_CORE_REGION); the others after it, in the map's order.
var region_first: String = "caverns"


## The deep map, from the Core's level Operations.REGION_CORE, as a player
## reads it: Surveyors refitted to lead expeditions and to make the crew of
## three kinds the Core's rows ask for, Breakers likewise; an expedition
## into the chosen region when the Core has room for one. True when it
## sent one.
func _deep_map() -> bool:
	# What the crew waits for is worked out again every beat.
	_hold_posts = false
	_hold_sorties = false
	_crew_short = false
	_keep_slot = -1
	if S.core_level < Operations.REGION_CORE:
		return false
	var roles: int = 1
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.ROLES:
			roles = maxi(roles, int(st["need"]))
	var crew: Dictionary = S.crew_roles()
	# Surveyors: the row's number, and one for an expedition while one waits.
	var want_v: int = roles + (1 if S.regions_open.size() < Operations.region_slots(S.core_level) else 0)
	if int(crew["surveyor"]) < want_v and int(crew["rig"]) > roles and S.refit_blocker("surveyor") == "":
		S.refit_rig("surveyor")
		_event("surveyor", "first Rig refitted as a Surveyor")
	elif int(crew["breaker"]) < roles and int(crew["rig"]) > roles and S.refit_blocker("breaker") == "":
		S.refit_rig("breaker")
	if S.regions_open.size() >= Operations.region_slots(S.core_level):
		return _beacon()
	# The chosen region first; after it, the one the whole crew is best
	# matched to (a crew of Breakers is weak in water).
	var rest: Array = []
	for r: String in Operations.REGION_ORDER:
		if r != region_first:
			rest.append(r)
	rest.sort_custom(func(a: String, b: String) -> bool: return _whole_crew(a) > _whole_crew(b))
	var order: Array = [region_first] + rest
	for r: String in order:
		if S.region_open(r) or S.site_busy(Operations.region_slot(r)):
			continue
		var t: Vector3i = S.expedition_team(r)
		var why: String = S.expedition_blocker(r, t.x, t.y, t.z)
		if why == "" and S.send_expedition(r, t.x, t.y, t.z):
			_hold_posts = false
			_hold_sorties = false
			_event("expedition_%s" % r, "expedition into %s" % String(Operations.REGIONS[r]["name"]))
			return true
		# Not this one yet (the Core's level, the Dark Reach's light): the next.
		if why in ["core", "room", "beacons"]:
			continue
		# Too weak with the crew at home: Rigs called home from their posts,
		# one a beat, none posted again and Rig Plating wanted until it has
		# gone; and, strong enough with the whole crew, no sorties either.
		# Too weak even with the whole crew: a Rig at home refitted as a
		# Surveyor, who counts twice on a survey (measured: at Core 11 six
		# Breakers and three Surveyors were 330 of the Sunken Works' 409,
		# and the crew went on sorties for hours).
		var whole: bool = _whole_crew(r) >= 1.0
		if why == "weak" and not whole:
			# Too weak even whole (measured: at Core 11 the second region's
			# survey was 0.73 to 0.86 of the whole crew, and waiting for it
			# held every post for hours): the crew grows -- a tuner home, or a
			# Rig refitted as a Surveyor, who counts twice on a survey -- and
			# meanwhile a Beacon may be lit.
			_crew_short = true
			if not S.tuners.is_empty():
				S.untune(int(S.tuners.keys()[0]))
			elif int(crew["rig"]) > roles and S.refit_blocker("surveyor") == "":
				S.refit_rig("surveyor")
			return _beacon()
		_hold_posts = why == "weak"
		_hold_sorties = _hold_posts
		if _hold_posts and not S.posts.is_empty():
			var rows: Array = _row_machines()
			var cells: Array = S.posts.keys()
			cells.sort_custom(func(a: int, c: int) -> bool: return not _in_rows(a, rows) and _in_rows(c, rows))
			S.recall_rig(int(cells[0]))
		# The first choice waits for its team: the plan is the plan.
		return false
	return _beacon()


## The whole crew -- at the Bay, out and posted -- against region `r`'s
## survey (or `s`): its strength over the need.
func _whole_crew(r: String, s: Dictionary = {}) -> float:
	var c: Dictionary = S.crew_roles()
	if s.is_empty():
		s = S.survey_site(r)
	# Keepers and tuners stay where they are.
	var v: int = int(c["surveyor"]) - S.surveyors_away()
	return S.team_strength(s, int(c["rig"]), int(c["breaker"]), v) / maxf(float(s["need"]), 1.0)


## A Beacon, while the Core's next level asks for one more or the Dark
## Reach waits for its light: in the open region the whole crew is best
## matched to, the crew gathered as for an expedition. True when one went.
func _beacon() -> bool:
	if S.core_level < Operations.CONTROL_CORE:
		return false
	var want: bool = S.core_level >= Operations.REACH_CORE and not S.region_open("reach") \
		and S.lit_beacons() < Operations.REACH_LIGHT
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.BEACONS and not bool(st["met"]):
			want = true
	if not want:
		return false
	for so: Dictionary in S.sorties:
		if String((so["site"] as Dictionary).get("kind", "")) == "beacon":
			return false
	var best: String = ""
	var fit: float = -1.0
	for r: String in S.regions_open:
		if S.beacons.has(r):
			continue
		var f: float = _whole_crew(r, S.beacon_site(r))
		if f > fit:
			fit = f
			best = r
	if best == "":
		return false
	# The region's own sites keep its slot busy: no more sorties there until
	# the Beacon has gone (measured: the Caverns' slot was never free for an
	# hour, and no Beacon was lit).
	if S.site_busy(Operations.region_slot(best)):
		_keep_slot = Operations.region_slot(best)
		return false
	var t: Vector3i = S.beacon_team(best)
	var why: String = S.beacon_blocker(best, t.x, t.y, t.z)
	if why == "" and S.send_beacon(best, t.x, t.y, t.z):
		_hold_posts = false
		_hold_sorties = false
		_event("beacon_%s" % best, "Beacon lit in %s" % String(Operations.REGIONS[best]["name"]))
		return true
	var roles: int = 1
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.ROLES:
			roles = maxi(roles, int(st["need"]))
	var crew: Dictionary = S.crew_roles()
	# Gathered only when the whole crew is enough (measured: posts held for
	# a Beacon no crew could light left the Lens Grinder unfed for hours);
	# short even whole, the crew grows: Rig Plating, a Surveyor refitted.
	_hold_posts = why == "weak" and fit >= 1.0
	_hold_sorties = _hold_posts
	_crew_short = _crew_short or why == "weak" and fit < 1.0
	if _hold_posts and not S.posts.is_empty():
		var rows: Array = _row_machines()
		var cells: Array = S.posts.keys()
		cells.sort_custom(func(a: int, c: int) -> bool: return not _in_rows(a, rows) and _in_rows(c, rows))
		S.recall_rig(int(cells[0]))
	# A keeper wanted: a Surveyor. Short of strength: a Breaker, who holds
	# a Beacon's ground (a Surveyor there is weaker than the Rig it was).
	if why == "surveyor" and int(crew["rig"]) > roles and S.refit_blocker("surveyor") == "":
		S.refit_rig("surveyor")
	elif why == "weak" and fit < 1.0 and int(crew["rig"]) > roles and S.refit_blocker("breaker") == "":
		S.refit_rig("breaker")
	return false


## Surveyors at the Bay past what the deep map waits on tune the Lens
## Grinders and Prism Cutters beside the Core; the Resonant Bore, once the
## Caverns are held, feeds the store from beside it (_bores).
func _tuning() -> void:
	if S.core_level < Operations.REGION_CORE or _crew_short or _hold_posts:
		return
	var reserve: int = 1 if S.regions_open.size() < Operations.region_slots(S.core_level) \
		or S.beacons.size() < S.regions_open.size() else 0
	if S.surveyors <= reserve:
		return
	for cell: int in S.sim.core_touching():
		if S.tune_blocker(cell) == "":
			S.tune(cell)
			_event("tune", "first machine a Surveyor tunes")
			return


func _bores() -> void:
	if not S.controlled("caverns") or t - _last_bore < LAB_BEAT:
		return
	_last_bore = t
	if _count_job("resonite") >= BORES:
		return
	if _build_core_side("drill", "resonite"):
		_event("bore", "first Resonant Bore beside the Core")


## Resonant Bores laid beside the Core once the Caverns are held.
const BORES := 2
var _last_bore: float = -1.0e9


## Posts, and sorties, held while an expedition waits for its team
## (`_deep_map`); a Beacon no whole crew is strong enough for.
var _hold_posts: bool = false
var _hold_sorties: bool = false
var _crew_short: bool = false
## A region's slot kept free for its Beacon (_beacon).
var _keep_slot: int = -1


## The crew a Rig Frame is laid for: the Rigs at the Bay and out, as the
## Core 1-10 journeys were measured with (posted Rigs and Breakers not
## counted: the Rig Frame waits on its own), and the Surveyors, who are
## Rigs refitted -- without them every refit asked for a Rig Frame beside
## the Core, where the Lens Grinder was to go.
func _crew_total() -> int:
	return S.rigs_home() + S.rigs_out() + S.surveyors + S.surveyors_out()


## Rigs posted like a player posts them (Operations, "Posts"): to a machine
## beside the Core that starves for something the store holds, keeping two
## Rigs at the Bay for the galleries unless a Core row is waiting on the
## machine; the Bay a level up when every dock is in use and another is
## wanted. From the Core's level RIG_CORE, when the crew is made.
func _posting() -> void:
	if S.core_level < MachineDB.RIG_CORE or not operations_on or _hold_posts:
		return
	var wanted: Array[int] = _post_candidates()
	if wanted.is_empty():
		return
	# A machine a Core row waits on first (measured: every dock of the Bay
	# fed Presses while four of five Assay Benches beside the Core starved,
	# and the Core 10 row stood at one of four).
	var rows: Array = _row_machines()
	wanted.sort_custom(func(a: int, b: int) -> bool: return _in_rows(a, rows) and not _in_rows(b, rows))
	if S.rigs_posted() >= S.bay_posts():
		if S.bay_blocker() == "":
			S.upgrade_bay()
			_event("bay%d" % S.bay_level, "Rig Bay level %d" % S.bay_level)
			return
		# Every dock in use and the Bay at its height: a Rig posted to a
		# machine no row asks for is called home for one a row does.
		if _in_rows(wanted[0], rows):
			for cell: int in S.posts.keys():
				if not _in_rows(cell, rows):
					S.recall_rig(cell)
					S.post_rig(wanted[0])
					_event("repost", "first Rig called home for a Core row's machine")
					return
		return
	var keep: int = 0 if _rows_wait_on_posts() else 2
	if S.rigs_home() > keep and S.post_rig(wanted[0]):
		_event("post", "first Rig posted")


## A starved machine `id` on `job` away from the Core moved to a tile beside
## it -- a free one, or one standing a machine built for income alone or
## starved most of the time that no row asks for -- while fewer than `need`
## of them stand there.
func _move_beside_core(id: String, job: String, need: int) -> bool:
	var beside: int = 0
	for cell: int in S.sim.core_touching():
		if S.grid.machine_at(cell) == id and S.grid.job_at(cell) == job:
			beside += 1
	if beside >= need:
		return false
	var from: int = -1
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == id and S.grid.job_at(cell) == job \
				and not S.sim.core_touching().has(cell) and S.sim.status_of(cell) == Simulation.Status.STARVED:
			from = cell
			break
	if from < 0:
		return false
	var rows: Array = _row_machines()
	var spot: int = -1
	for cell: int in S.sim.core_touching():
		if _free(cell) and _heat_safe(cell, id):
			spot = cell
			break
	if spot < 0:
		for cell: int in S.sim.core_touching():
			if S.grid.is_empty(cell) or S.posts.has(cell) or _in_rows(cell, rows) \
					or t - float(_fed_at.get(cell, -1.0e9)) < SETTLE:
				continue
			var idle: bool = S.sim.uptime.has(cell) and S.sim.uptime_of(cell) < 0.2 \
				and S.sim.status_of(cell) == Simulation.Status.STARVED
			if _income_only(cell) or idle:
				S.sell(cell)
				spot = cell
				break
	if spot < 0:
		# Every side busy: a machine there making nothing the Core's rows ask
		# for, nor what the row's machine takes, gives its tile up (measured:
		# Assay Benches starved away from the Core for hours while Presses on
		# Alloy Sheet held its sides).
		var wanted: Dictionary = _wanted()
		for res: int in (MachineDB.job_machine(id, job).get("inputs", {}) as Dictionary):
			wanted[res] = true
		for cell: int in S.sim.core_touching():
			if S.grid.is_empty(cell) or _in_rows(cell, rows) \
					or t - float(_fed_at.get(cell, -1.0e9)) < SETTLE:
				continue
			var outs: Dictionary = S.sim.machine_of(cell).get("outputs", {})
			var needed: bool = S.grid.machine_at(cell) == "vault"
			for o: int in outs:
				needed = needed or wanted.has(o)
			if outs.is_empty() or needed:
				continue
			if S.posts.has(cell):
				S.recall_rig(cell)
			S.sell(cell)
			spot = cell
			break
	if spot < 0 or not S.move_machine(from, spot):
		return false
	_fed_at[spot] = t
	_line[spot] = true
	_event("bench_moved", "first %s moved beside the Core" % MachineDB.job_name(id, job))
	return true


## Machines beside the Core, starved, that the store could feed.
func _post_candidates() -> Array[int]:
	var out: Array[int] = []
	for cell: int in S.sim.core_touching():
		if S.grid.is_empty(cell) or S.posts.has(cell):
			continue
		if S.sim.status_of(cell) != Simulation.Status.STARVED:
			continue
		var b: String = S.post_blocker(cell)
		if b != "" and b != "rigs" and b != "bay":
			continue
		for res: int in S.haul_inputs(cell):
			if S.haulable(res) > 0:
				out.append(cell)
				break
	return out


## The machines open rows of the Core ask to be at work: [[id, job], ...].
func _row_machines() -> Array:
	var out: Array = []
	for st: Dictionary in S.core_status():
		var r: Array = st["req"]
		if int(r[0]) == CoreLevels.Req.WORKING and not bool(st["met"]):
			out.append([String(r[1]), CoreLevels.row_job(r)])
		# A store row whose maker only the store can feed (the Lens
		# Grinder): its makers are the row's machines too.
		if int(r[0]) == CoreLevels.Req.STOCK and not bool(st["met"]):
			var mk: Array = _maker(int(r[1]))
			if not mk.is_empty() and _store_only(String(mk[0]), String(mk[1])):
				out.append([String(mk[0]), String(mk[1])])
	return out


## Does machine `id` on `job` take something no machine makes: fed only from
## the store, by a posted Rig?
func _store_only(id: String, job: String) -> bool:
	for res: int in (MachineDB.job_machine(id, job).get("inputs", {}) as Dictionary):
		# A maker only a region or a Beacon allows is no line to build: the
		# Resonant Bore feeds the store beside the Core (_bores), not a chain.
		var lines: bool = false
		for mk: Array in MachineDB.makers_of(res):
			var info: Dictionary = MachineDB.job_info(String(mk[0]), String(mk[1]))
			lines = lines or not (info.has("control") or info.has("region"))
		if not lines:
			return true
	return false


func _in_rows(cell: int, rows: Array) -> bool:
	for r: Array in rows:
		if S.grid.machine_at(cell) == String(r[0]) and S.grid.job_at(cell) == String(r[1]):
			return true
	return false


## Does an open row of the Core ask for machines on a job the store feeds?
func _rows_wait_on_posts() -> bool:
	for m: Array in _row_machines():
		if String(m[1]) != "" and _store_feeds(String(m[0]), String(m[1])):
			return true
	return false


## Can the store feed machine `id` on `job`: does it keep, and hold, every
## input the job takes?
func _store_feeds(id: String, job: String) -> bool:
	var ins: Dictionary = MachineDB.job_machine(id, job).get("inputs", {})
	if ins.is_empty():
		return false
	for res: int in ins:
		if not MachineDB.STOCKED.has(res) or S.haulable(res) < 100:
			return false
	return true


## Machine `id` on `job` on a tile touching the Core -- a free one, or one a
## machine built for income alone gives up -- where a Rig will feed it.
func _build_core_side(id: String, job: String) -> bool:
	if not S.can_afford(id):
		return false
	var spot: int = -1
	for cell: int in S.sim.core_touching():
		if _free(cell) and _heat_safe(cell, id):
			spot = cell
			break
	if spot < 0:
		for cell: int in S.sim.core_touching():
			if _income_only(cell):
				S.sell(cell)
				spot = cell
				break
	# From the deep map: a machine beside the Core that stands starved, with
	# no Rig posted to it and no row asking for it, makes way (measured: the
	# Core 12 row's second Lens Grinder found every side taken, two of them by
	# starved Assay Benches, and was laid away from the Core with no outlet).
	if spot < 0 and S.core_level >= Operations.REGION_CORE:
		var rows: Array = _row_machines()
		for cell: int in S.sim.core_touching():
			if S.grid.is_empty(cell) or S.posts.has(cell) or S.tuners.has(cell) or _in_rows(cell, rows):
				continue
			if S.sim.status_of(cell) == Simulation.Status.STARVED:
				S.sell(cell)
				spot = cell
				break
	if spot < 0 or not S.try_place(spot, id):
		return false
	S.set_job(spot, job)
	_line[spot] = true
	_cool_if_needed(spot)
	return true
## The Core's level under which a Rig Frame last overheated, and when.
var _rig_hot_core: int = 0
var _rig_hot_t: float = -1.0e9
## Off, the player never touches the crew (for measuring what it changes).
var operations_on: bool = true


## A Rig Frame where a player puts one: beside a working Plate maker, which
## then feeds it too, on free ground or in the place of a Drill or a Vault
## built for income alone -- and only where its heat overheats nothing
## beside it. Measured: laid on a fixed tile of the plans, it took a Drill's
## place beside a Press, the Press overheated on stratum 12, and the Core 5
## stage, reached at 46 minutes, was not over in three hours (without it,
## from the same game, Core 6 came at 1 h 18 min).
func _place_rig_frame() -> bool:
	if not S.can_afford("assembler"):
		return false
	for cell: int in BuildArea.cells(S.max_depth):
		var taken: bool = not S.grid.is_empty(cell)
		if taken and not (_income_only(cell) and not S.sim.core_touching().has(cell)) 				or not taken and not _free(cell):
			continue
		var plates: bool = false
		for n: int in S.grid.bridged_machines(cell):
			if S.sim.status_of(n) != Simulation.Status.RUNNING and S.sim.status_of(n) != Simulation.Status.BLOCKED:
				continue
			plates = plates or (S.sim.machine_of(n).get("outputs", {}) as Dictionary).has(MachineDB.Res.PLATE)
		if not plates or not _heat_safe(cell, "assembler"):
			continue
		if taken:
			S.sell(cell)
		if S.try_place(cell, "assembler"):
			S.set_job(cell, "rig")
			_line[cell] = true
			_cool_if_needed(cell)
			return true
	return false


## Rig Frames on the board; one that starves is the repairs' to feed.
func _rig_makers() -> int:
	return _count_job("rig")


## Does the Core's next level ask for a stratum below this one?
func _depth_wanted() -> bool:
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.DEPTH and not bool(st["met"]):
			return true
	return false


## What the store keeps for the Core's next level: {res: count}. Its store
## rows; and, from Core 7, what its open Overdrive and machine rows are paid
## in (measured: contracts and spare levels took the Ingots and Plates of
## an Overdrive step the Core asked for, for ten hours).
func _keep_materials() -> Dictionary:
	var keep: Dictionary = {}
	for st: Dictionary in S.core_status():
		var r: Array = st["req"]
		match int(r[0]):
			CoreLevels.Req.STOCK:
				keep[int(r[1])] = int(keep.get(int(r[1]), 0)) + int(st["need"])
			CoreLevels.Req.OVERDRIVE:
				if S.core_level >= MachineDB.OVERDRIVE_CORE and not bool(st["met"]):
					var od: Dictionary = S.overdrive_cost(String(r[1]))["materials"]
					for m: int in od:
						keep[m] = int(keep.get(m, 0)) + int(od[m])
			CoreLevels.Req.MACHINE:
				if S.core_level >= MachineDB.OVERDRIVE_CORE and not bool(st["met"]):
					var lv: Dictionary = S.machine_upgrade_cost(String(r[1]))["materials"]
					for m: int in lv:
						keep[m] = int(keep.get(m, 0)) + int(lv[m])
	return keep


## Fill a contract on the Dispatch board when the store can spare it: what
## the Core's own next level asks for stays in the store.
func _contracts() -> void:
	var keep: Dictionary = _keep_materials()
	for i in range(Dispatch.SLOTS):
		if not S.can_fill_contract(i):
			continue
		var c: Dictionary = S.contract(i)
		var res: int = int(c["res"])
		if S.stock_of(res) - int(c["n"]) >= int(keep.get(res, 0)):
			S.fill_contract(i)
			var n: int = S.contracts_lifetime
			if n == 1 or n % 10 == 0:
				_event("contract%d" % n, "contract %d filled (%s)" % [n, String(c["pays"])])
			return


func _research() -> void:
	var want: Array[String] = []
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.RESEARCH and not bool(st["met"]):
			want.append(String(st["req"][1]))
		if int(st["req"][0]) == CoreLevels.Req.DOCTRINE and not bool(st["met"]) and S.doctrine != "":
			for id: String in Economy.DOCTRINES[S.doctrine]["lines"]:
				want.append(id)
		if int(st["req"][0]) == CoreLevels.Req.REGION_LINES and not bool(st["met"]):
			for r: String in S.regions_open:
				want.append(String(Operations.REGIONS[r]["research"]))
	for id: String in Economy.TREE_ORDER:
		if not want.has(id):
			want.append(id)
	# Salvage: to Salvaged Gearing whenever it can (its research is small),
	# unless the crew needs Rig Plating first; or, in the mode "crew", to
	# Rig Plating whenever it can (salvage_mode).
	if salvage_mode == "crew" and not _researching() and S.can_buy_upgrade("rig_plating"):
		S.buy_upgrade("rig_plating")
		return
	var bay_first: bool = S.rigs_posted() >= S.bay_posts() and not _post_candidates().is_empty() \
		and S.bay_blocker() != "max" and S.bay_blocker() != "core"
	if salvage_mode == "gearing" and not bay_first and S.can_buy_upgrade("salvage_gearing") and not _plating_wanted():
		S.buy_upgrade("salvage_gearing")
		return
	for id: String in want:
		if id == "salvage_gearing" and salvage_mode != "gearing":
			continue
		# Rig Plating only when the crew needs it: a site the Core asks for
		# that the crew cannot clear (measured: bought whenever it was the
		# cheapest line, it took the Core 4 and 5 eras' research, and Core 6
		# came an hour late).
		if id == "rig_plating" and not _plating_wanted():
			continue
		if S.can_buy_upgrade(id):
			S.buy_upgrade(id)
			return


## Does a research row of the Core's next level still wait?
func _researching() -> bool:
	for st: Dictionary in S.core_status():
		var k: int = int(st["req"][0])
		if (k == CoreLevels.Req.RESEARCH or k == CoreLevels.Req.DOCTRINE or k == CoreLevels.Req.REGION_LINES) \
				and not bool(st["met"]):
			return true
	return false


## Does the crew need to be stronger: no site on the board is one the Rigs
## at home and out, repaired, could clear -- while the Core asks for sites,
## or while no research row waits?
func _plating_wanted() -> bool:
	var asked: bool = false
	for st: Dictionary in S.core_status():
		asked = asked or int(st["req"][0]) == CoreLevels.Req.OPERATIONS and not bool(st["met"])
	# Unasked, only on research no row of the Core is waiting for (measured:
	# bought whenever the crew fell short, it took the Core 4 and 5 eras'
	# research); and not before the Rig Frame makes a crew worth plating.
	# An expedition waiting on a crew too weak for its survey; a Beacon on
	# a crew too weak even whole.
	if _hold_posts or _crew_short:
		return true
	if not asked and (_researching() or S.core_level < MachineDB.RIG_CORE):
		return false
	# The crew as it would be repaired: wear is the Plates' to fix, not
	# research's (measured: bought against worn Rigs, Rig Plating took the
	# Core 4 era's research and Core 6 came late or not at all).
	var crew: float = S.crew_strength(S.rigs_home() + S.rigs_out()) / maxf(1.0 - S.rig_wear, 0.2)
	for i in range(S.ops_board.size()):
		if S.site(i).has("kind") and crew >= float(S.site(i)["left"]):
			return false
	return true


func _pursue(st: Dictionary) -> void:
	var r: Array = st["req"]
	match int(r[0]):
		CoreLevels.Req.STOCK:
			var res: int = int(r[1])
			if int(st["cap"]) < int(st["need"]):
				# The Vault's level first. Vault 9 is paid in Alloy and
				# Components: from Core 8 a store short of them is fed, as for
				# a machine row (measured: a new game's Core 8 factory had 11
				# Components for eight hours; with this, the store was full of
				# them within two).
				if S.core_level >= FORGE_FROM and S.machine_upgrade_blocker("vault") == "stock":
					for m: int in (S.machine_upgrade_cost("vault")["materials"] as Dictionary):
						if _core_feeders(m) < 1:
							_feed_core(m)
				else:
					S.upgrade_machine("vault")
			# The makers beside the Core too, while the Vault grows: at their
			# working heat, and enough of them (measured: with Vault 10 on its
			# way, the Frames stood at 55,899 for two hours, the two Frame
			# Jigs out of their working heat and nothing laid).
			for cell: int in S.sim.core_touching():
				if (S.sim.machine_of(cell).get("outputs", {}) as Dictionary).has(res) \
						and S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT and _fix_heat(cell):
					return
			if _core_feeders(res) < _feeders_wanted(st):
				_feed_core(res)
		CoreLevels.Req.WORKING:
			# The ones there are first: warmed, cooled or given an outlet;
			# then more of them.
			var id: String = String(r[1])
			var job: String = CoreLevels.row_job(r)
			if job != "":
				# The ones on the job first: warmed or cooled to their working
				# heat (measured: six Assay Benches on stratum 27, five of them
				# fed and too hot, never cooled, and the Core 10 row at one of
				# four for four hours).
				for cell: int in S.grid.cells:
					if S.grid.machine_at(cell) == id and S.grid.job_at(cell) == job 							and S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT and _fix_heat(cell):
						return
				# On a job: more of them, one a beat's while -- beside the Core
				# with a Rig to feed them when the store holds what they take
				# (Operations, "Posts"), else with their chain.
				if _count_job(job) < int(st["need"]) + 1 and t - _last_lab >= LAB_BEAT:
					_last_lab = t
					if not (_store_feeds(id, job) and _build_core_side(id, job)) \
							and not (S.core_level >= Operations.REGION_CORE and _store_only(id, job)):
						_build_job(id, job)
				elif _store_feeds(id, job) and t - _last_lab >= LAB_BEAT:
					# Enough of them, starved away from the Core while the store
					# holds what they take: one moved beside it, where a Rig
					# feeds it (measured: eight Assay Benches laid with their
					# chains, seven starved, none beside the Core, and the Core
					# 10 row at one of four for thirteen hours).
					_last_lab = t
					_move_beside_core(id, job, int(st["need"]))
				return
			if not _fix_heat_of(id) and not _unblock(id):
				if id == "lab" or S.grid.count_of(id) < int(st["need"]):
					_build_line(id) if id == "lab" else _build_somewhere(id)
		CoreLevels.Req.MACHINE:
			var mid: String = String(r[1])
			var why: String = S.machine_upgrade_blocker(mid)
			if why == "":
				S.upgrade_machine(mid)
			elif why == "storage":
				S.upgrade_machine("vault")
			elif why == "stock":
				for res: int in (S.machine_upgrade_cost(mid)["materials"] as Dictionary):
					if _core_feeders(res) < 1:
						_feed_core(res)
		CoreLevels.Req.RESEARCH:
			if S.grid.count_of("lab") == 0 or _working("lab") == 0:
				_build_lab()
			elif not S.can_buy_upgrade(String(r[1])) and S.upgrade_level(String(r[1])) < S.research_cap(String(r[1])):
				# Short of research, not of the Core: more Labs, fed.
				_more_labs()
		CoreLevels.Req.OVERDRIVE:
			_drive(String(r[1]))
		CoreLevels.Req.DOCTRINE:
			if S.doctrine != "":
				_more_labs()
		CoreLevels.Req.SERVES:
			_place_support(String(r[1]), int(r[2]))
		CoreLevels.Req.STABLE:
			for cell: int in S.grid.cells:
				if S.sim.overheated_at(cell):
					if not _hot_since.has(cell):
						_hot_since[cell] = t
					# From Core 6, one still overheating after HOT_FOR of fixes
					# is beyond them: a player stops fixing and decides
					# (measured: a Core 6 Crusher and Lab, fixed every five
					# minutes and never cooled, held the Core 7 row's stability
					# at 0 from 1 h 38 min to past 9 h).
					var tried: bool = S.core_level >= KEEP_FROM \
						and t - float(_hot_since[cell]) > HOT_FOR
					# From the Core's level KEEP_FROM a machine being cooled is
					# given the time to show it before it is judged beyond help.
					if not tried and S.core_level >= KEEP_FROM and t - float(_touched.get(cell, -1.0e9)) < SETTLE:
						continue
					if not tried and _fix_heat(cell, false):
						return
					# From Core 7: a Drill the rock overheats bores for crystal
					# instead, which the hot rock suits (MachineDB.JOBS).
					if _to_deep(cell):
						return
					# Nothing can cool it where it stands: a player takes it
					# away, unless a plan needs it there, and leaves the tile.
					# From the Core's level KEEP_FROM a plan's machine goes too
					# (on this stratum): the rock under Core 6 is hotter than
					# anything the plans were laid for.
					# A plan's machine too, once fixes have failed it for HOT_FOR
					# (measured: a plan's Crusher on stratum 12 overheated for
					# hours, and the Core 6 row's stability stood at 0).
					if not _reserved(cell) or S.core_level >= KEEP_FROM \
							or t - float(_hot_since[cell]) > HOT_FOR:
						if _reserved(cell):
							_dropped[cell] = true
						S.sell(cell)
						_bare[cell] = t
						return
			# Nothing overheats: more machines at their working heat.
			var still: Dictionary = {}
			for cell: int in _hot_since:
				if S.sim.overheated_at(cell):
					still[cell] = _hot_since[cell]
			_hot_since = still
			for cell: int in S.sim.problem_cells():
				if S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT and _fix_heat(cell, false):
					return


## An Overdrive step for machine type `id`, or what stands in its way:
## the Vault's level for a store too small, a chain into the store for the
## materials, Labs for the research, the type's own level first.
func _drive(id: String) -> void:
	match S.overdrive_blocker(id):
		"":
			S.overdrive_machine(id)
		"storage":
			S.upgrade_machine("vault")
		"stock":
			for res: int in (S.overdrive_cost(id)["materials"] as Dictionary):
				if S.stock_of(res) < int(S.overdrive_cost(id)["materials"][res]) and _core_feeders(res) < 2:
					_feed_core(res)
					return
		"research":
			_more_labs()
		"level":
			if S.can_upgrade_machine(id):
				S.upgrade_machine(id)


## From the Core's level KEEP_FROM the player keeps, whatever else it does,
## the credits the Core's rows are bought with. Before it the player is
## kept as it was measured.
const KEEP_FROM := 6
var _keep: float = 0.0
## The part of `_keep` that is machine and Vault levels, not the Core's price.
var _keep_levels: float = 0.0


## Labs, up to LABS, where refined material reaches them: research is a
## production decision, and a player short of it builds for it. From the
## Core's level LABS_FROM: the first four lines are cheap enough for the
## Labs the plans already hold, and the player before it is kept as it was
## measured.
const LABS := 12
const LABS_FROM := 6


func _more_labs() -> void:
	# From Core 9: an Assay Bench, fed by a Frame Jig and the chain behind it.
	if S.job_open("lab", "assay"):
		if _count_job("assay") < ASSAYS and t - _last_lab >= LAB_BEAT:
			_last_lab = t
			_build_job("lab", "assay")
		return
	# On hot rock, with the deep chain open: a Lab fed Alloy (twice what a
	# Component teaches), cooled.
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.job_open("smelter", "alloy"):
		if _research_units() < LABS and t - _last_lab >= LAB_BEAT:
			_last_lab = t
			_build_research_unit()
		return
	if S.core_level < LABS_FROM or S.grid.count_of("lab") >= LABS or not S.can_afford("lab"):
		return
	# One at a time, given the time to show what it makes.
	if t - _last_lab < SETTLE:
		return
	_last_lab = t
	_build_lab()


## Assay Benches the player lays at most.
const ASSAYS := 8


func _count_job(job: String) -> int:
	var n: int = 0
	for cell: int in S.grid.cells:
		if S.grid.job_at(cell) == job:
			n += 1
	return n


## A machine `id` on job `job` off the Core's sides, where the most ground is
## free, with the chain that feeds it (an Assay Bench: the Frame Jig and all
## behind it).
func _build_job(id: String, job: String) -> bool:
	# Work a row asks for goes before the levels being saved for.
	if S.credits < _chain_cost(id, job) * 1.2:
		return false
	var best: int = -1
	var room: int = 2
	for cell: int in BuildArea.cells(S.max_depth):
		if not _free(cell) or S.sim.core_touching().has(cell):
			continue
		var r: int = _free_near(cell, true).size()
		if r > room:
			room = r
			best = cell
	if best >= 0:
		return _chain(id, best, 0, job)
	# The yard is full: a patch built for income alone makes way, as for a
	# line (`_build_line`).
	for cell: int in BuildArea.cells(S.max_depth):
		if not _income_only(cell) or S.sim.core_touching().has(cell):
			continue
		var patch: Array[int] = [cell]
		for n: int in S.grid.neighbours(cell):
			if (_income_only(n) or _free(n)) and not S.sim.core_touching().has(n):
				patch.append(n)
		if patch.size() < 4:
			continue
		for c: int in patch:
			if not S.grid.is_empty(c):
				S.sell(c)
		return _chain(id, cell, 0, job)
	return false


## A research unit: a Deep Bore, a White Heat Smelter, a Coolant Cell and a
## Lab in a row. The Cell passes the Alloy on to the Lab and keeps it -- a
## Lab takes 3.0 heat, less than the rock of 17-19 -- cool.
func _build_research_unit() -> bool:
	var cost: float = S.cost_of("drill") + S.cost_of("smelter") + S.cost_of("coolant") + S.cost_of("lab")
	if S.credits < cost * 1.2 or not S.is_unlocked("coolant") or not S.is_unlocked("lab"):
		return false
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	for pass_ in range(2):
		for cell: int in BuildArea.cells(S.max_depth):
			for d: Vector2i in dirs:
				var row: Array[int] = []
				var p: Vector2i = Grid.xy(cell)
				for k in range(4):
					var q: Vector2i = p + d * k
					if not Grid.in_bounds(q.x, q.y):
						break
					row.append(Grid.idx(q.x, q.y))
				if row.size() < 4 or not _deep_ground(row, pass_ == 1):
					continue
				for c: int in row:
					_bare.erase(c)
					if not S.grid.is_empty(c):
						S.sell(c)
				if not S.try_place(row[0], "drill") or not S.try_place(row[1], "smelter") \
						or not S.try_place(row[2], "coolant") or not S.try_place(row[3], "lab"):
					return false
				S.set_job(row[0], "crystal")
				S.set_job(row[1], "alloy")
				for c: int in row:
					_line[c] = true
				return true
	return false


## Labs fed by the deep chain.
func _research_units() -> int:
	var n: int = 0
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == "lab" and S.sim.status_of(cell) != Simulation.Status.STARVED:
			for f: int in S.grid.bridged_machines(cell):
				if S.grid.job_at(f) == "alloy":
					n += 1
					break
	return n


const LAB_BEAT := 60.0


var _last_lab: float = -1.0e9


## Overdrive steps past what the Core asks for, from what the store and the
## research can spare after the Core's own asks: the chain's end first.
func _spare_overdrive() -> void:
	if S.core_level < MachineDB.OVERDRIVE_CORE:
		return
	var keep: Dictionary = _keep_materials()
	var books: float = _keep_research() if S.core_level >= FORGE_FROM else 0.0
	for id: String in ["assembler", "press", "smelter", "crusher", "drill", "lab", "coolant", "condenser"]:
		if not S.can_overdrive(id):
			continue
		var cost: Dictionary = S.overdrive_cost(id)
		var ok: bool = S.research - float(cost["research"]) >= books
		for res: int in (cost["materials"] as Dictionary):
			var left: int = S.stock_of(res) - int(cost["materials"][res])
			ok = ok and (left >= int(keep.get(res, 0)) or S.stock_of(res) >= S.stock_cap())
		if ok:
			S.overdrive_machine(id)
			return


## Research the Core's open research and doctrine rows still need for their
## next level: from Core 8 a spare Overdrive step does not take it
## (measured: five spare steps took 600K of research while the doctrine row,
## the last one open, waited 1 h 44 min for it).
func _keep_research() -> float:
	var out: float = 0.0
	for st: Dictionary in S.core_status():
		if bool(st["met"]):
			continue
		var r: Array = st["req"]
		var lines: Array = []
		match int(r[0]):
			CoreLevels.Req.RESEARCH:
				lines = [String(r[1])]
			CoreLevels.Req.DOCTRINE:
				if S.doctrine != "":
					lines = Economy.DOCTRINES[S.doctrine]["lines"]
		var cheapest: float = INF
		for id: String in lines:
			if S.upgrade_level(id) < S.research_cap(id):
				cheapest = minf(cheapest, float(Economy.upgrade_cost(id, S.upgrade_level(id))["research"]))
		if cheapest < INF:
			out += cheapest
	return out


## Machine levels past what the Core asks for, from what the store can
## spare after the Core's own materials.
func _spare_upgrades() -> void:
	var keep: Dictionary = _keep_materials()
	# A level is heat as well as speed: in a shaft after a collapse, and on
	# the Core 7 era's rock, a level no row asks for waits while something
	# overheats (measured: cheap levels bought on every type put a second
	# shaft's lines past their tolerance on stratum 12 for twelve hours).
	var hot: bool = (S.collapses > 0 or S.core_level >= MachineDB.OVERDRIVE_CORE) \
		and CoreLevels.stable(S) == 0
	for id: String in ["vault", "smelter", "crusher", "drill", "press", "assembler", "lab"]:
		if not S.can_upgrade_machine(id):
			continue
		if hot and id != "vault":
			continue
		var cost: Dictionary = S.machine_upgrade_cost(id)
		var ok: bool = S.credits - _keep >= float(cost["credits"]) * 1.5
		for res: int in (cost["materials"] as Dictionary):
			# What the Core keeps for itself stays, unless the store is full
			# and refills anyway.
			var left: int = S.stock_of(res) - int(cost["materials"][res])
			ok = ok and left >= 0 and (left >= int(keep.get(res, 0)) or S.stock_of(res) >= S.stock_cap())
		if id == "vault":
			# A full store is a reason on its own.
			ok = ok or (S.stock_of(MachineDB.Res.INGOT) >= S.stock_cap() and S.credits >= float(cost["credits"]))
		if ok:
			S.upgrade_machine(id)
			return


## --- the board ------------------------------------------------------------------

## The next machine of the plans the Core's level has reached: placed when it
## can be, or its price, which the rest of the beat then keeps. 0 when every
## plan so far stands (or waits only for a stratum or a machine not found).
func _follow_plans() -> float:
	if _dropped_depth != S.depth:
		_dropped.clear()
		_dropped_depth = S.depth
	# The plans are the first three Core levels' lines. From the Core's
	# level KEEP_FROM the player works from the Core's rows alone, and does
	# not rebuild a plan's machine the hot rock has cost it.
	if S.core_level >= KEEP_FROM:
		return 0.0
	# A later plan's machine for a tile replaces an earlier plan's (the Rig
	# Frame in the Core 3 line's Vault's place): measured, the two plans
	# sold each other's machine on that tile for hours.
	var later: Dictionary = {}
	for plan: Dictionary in PLANS:
		if S.core_level < int(plan["core"]) or S.max_depth < int(plan["from"]):
			break
		for e: Array in plan["cells"]:
			later[Grid.idx(int(e[0]), int(e[1]))] = e
	for plan: Dictionary in PLANS:
		if S.core_level < int(plan["core"]) or S.max_depth < int(plan["from"]):
			break
		for e: Array in plan["cells"]:
			if later.get(Grid.idx(int(e[0]), int(e[1]))) != e:
				continue
			var cell: int = Grid.idx(int(e[0]), int(e[1]))
			var id: String = String(e[2])
			var job: String = String(e[3]) if e.size() > 3 else ""
			if S.grid.machine_at(cell) == id and S.grid.job_at(cell) != job:
				S.set_job(cell, job)
			if S.grid.machine_at(cell) == id or _dropped.has(cell):
				continue
			if not S.is_unlocked(id) or not S.is_open(cell) or S.is_blocked(cell):
				continue
			if not S.grid.is_empty(cell):
				# Something built there before the plan started makes way.
				if S.credits < S.cost_of(id):
					return S.cost_of(id)
				S.sell(cell)
			if S.try_place(cell, id):
				if job != "":
					S.set_job(cell, job)
				return 0.0
			if S.credits < S.cost_of(id):
				return S.cost_of(id)
	return 0.0


var _plan_cells: Dictionary = {}
## Plan tiles the player changed their mind about on this stratum (a
## Coolant Cell that over-cooled here, say): not rebuilt until the next one,
## whose heat is different.
var _dropped: Dictionary = {}
var _dropped_depth: int = -1


## A tile beside `cell` to build on: a free one, or else one standing a
## machine the player built for income alone (not a plan's, not a support
## machine, not one touching the Core), sold to make room. -1 when none.
func _room_near(cell: int, for_id: String = "") -> int:
	var free: Array[int] = _free_near(cell, false)
	if not free.is_empty():
		return free[0]
	for n: int in S.grid.neighbours(cell):
		if S.grid.machine_at(n) == for_id:
			continue
		if _income_only(n) and not S.sim.core_touching().has(n):
			S.sell(n)
			return n
	return -1


## The tiles of the plans the Core's level has reached: kept for them,
## whatever else the player builds. A later plan's tiles are free until then.
func _reserved(cell: int) -> bool:
	# The plans stop at the Core's level KEEP_FROM; from Overdrive's level
	# on, a player lays the yard again for the hot rock.
	if S.core_level >= MachineDB.OVERDRIVE_CORE:
		return false
	var core: int = int(_plan_cells.get(cell, 999))
	if _plan_cells.is_empty():
		for plan: Dictionary in PLANS:
			for e: Array in plan["cells"]:
				_plan_cells[Grid.idx(int(e[0]), int(e[1]))] = int(plan["core"])
				_plan_from[Grid.idx(int(e[0]), int(e[1]))] = int(plan["from"])
		core = int(_plan_cells.get(cell, 999))
	# A shaft after a collapse starts on the Core's foundation, above plans
	# it has not reached the rock for: their tiles are not kept until it has
	# (measured: a second shaft at Core 4 with every tile of stratum 0 kept
	# for later plans placed nothing, ever).
	if S.collapses > 0 and int(_plan_from.get(cell, 0)) > S.max_depth:
		return false
	return core <= S.core_level


var _plan_from: Dictionary = {}


## Tiles left bare on purpose: something overheated there.
var _bare: Dictionary = {}
## When the player last changed the heat round a tile: a change is given
## SETTLE seconds to show before the same tile is touched again, or a fix
## for one machine and a fix for its neighbour undo each other forever.
var _touched: Dictionary = {}
const SETTLE := 300.0


func _free(cell: int) -> bool:
	if not S.grid.is_empty(cell) or not S.is_open(cell) or S.is_blocked(cell) or _reserved(cell):
		return false
	if S.core_level >= MachineDB.OVERDRIVE_CORE:
		# From Core 7 a tile is left bare, or kept from a machine scrapped
		# on it, for FORGET seconds: lines are laid with their cooling
		# now (`_cool_if_needed`), so the tile can be tried again -- but not
		# at once, or a repair lays again what was just cleared away.
		return t - float(_bare.get(cell, -1.0e9)) > FORGET and t - float(_scrapped.get(cell, -1.0e9)) > FORGET
	# Before it, a tile left bare is left for FORGET_EARLY: the rock under
	# the next stratum is another rock (measured: kept bare for good, 67
	# tiles sold for heat in the Core 5 era left no room beside a Duplicator
	# and the row stood at two of three for hours).
	return t - float(_bare.get(cell, -1.0e9)) > FORGET_EARLY


## Tiles a machine was scrapped from (`_tidy`), and when.
var _scrapped: Dictionary = {}
const FORGET := 1800.0
const FORGET_EARLY := 3600.0


func _free_near(cell: int, away_from_core: bool) -> Array[int]:
	var out: Array[int] = []
	for n: int in S.grid.neighbours(cell):
		if _free(n) and not (away_from_core and S.sim.core_touching().has(n)):
			out.append(n)
	return out


func _working(id: String) -> int:
	return CoreLevels.working(S, id)


## Machines making `res` that touch the Core.
func _core_feeders(res: int) -> int:
	var n: int = 0
	for cell: int in S.sim.core_touching():
		if (S.sim.machine_of(cell).get("outputs", {}) as Dictionary).has(res):
			# A feeder that has been starved most of the time is not one: its
			# line behind it has gone (measured: on stratum 12 the Crushers
			# behind the Core 5 factory's Smelters overheated and were sold,
			# and the Smelters beside the Core, starved, still counted).
			if S.sim.uptime_of(cell) < 0.2 and S.sim.status_of(cell) == Simulation.Status.STARVED:
				continue
			n += 1
	return n


## The machine type and job this shaft makes `res` with: its own recipe if
## one makes it, else a job the shaft has opened. [] when none.
func _maker(res: int) -> Array:
	var open: Array = []
	for mk: Array in MachineDB.makers_of(res):
		if S.is_unlocked(String(mk[0])) and S.job_open(String(mk[0]), String(mk[1])):
			open.append(mk)
	if open.is_empty():
		return []
	# From Core 7, on the deep rock, a job built for its heat (Alloy Parts
	# rather than Plates into Components) is laid first.
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.max_depth >= MachineDB.CRYSTAL_DEPTH:
		for mk: Array in open:
			if String(mk[1]) != "":
				return mk
	return open[0]


## Machines beside the Core a store row wants making its material: two, and
## from Core 8 one more for every 60,000 still to come, up to six (the Core
## 8 era's Frame Jigs filled about 85,000 Frames an hour: a row of 300,000
## would be three and a half hours of them).
func _feeders_wanted(st: Dictionary) -> int:
	if S.core_level < FORGE_FROM:
		return 2
	return clampi(ceili((float(st["need"]) - float(st["have"])) / 60000.0), 2, 6)


## A chain that ends in a maker of `res` touching the Core.
func _feed_core(res: int) -> bool:
	var mk: Array = _maker(res)
	if mk.is_empty():
		return false
	var maker: String = String(mk[0])
	# A job only the store can feed (the Lens Grinder, on Resonite the crew
	# brings home): beside the Core, where a Rig feeds it.
	if String(mk[1]) != "" and _store_only(maker, String(mk[1])) and _store_feeds(maker, String(mk[1])):
		if _build_core_side(maker, String(mk[1])):
			_event("store_fed_%s" % String(mk[1]), "first %s beside the Core, fed from the store"
				% MachineDB.job_name(maker, String(mk[1])))
			return true
		return false
	var best: int = -1
	var room: int = -1
	for cell: int in S.sim.core_touching():
		if not _free(cell):
			continue
		var r: int = _free_near(cell, true).size()
		if _reserved(cell):
			r += 2
		if r > room:
			room = r
			best = cell
	if S.credits < _chain_cost(maker, String(mk[1])):
		return false
	if best < 0 and String(mk[1]) != "" and _retask(mk):
		return true
	if best < 0:
		# Every tile touching the Core is taken: one built for income alone
		# makes way.
		for cell: int in S.sim.core_touching():
			if _income_only(cell):
				S.sell(cell)
				best = cell
				break
	if best < 0 and S.core_level >= MachineDB.OVERDRIVE_CORE:
		# From Core 7: a machine beside the Core making nothing the Core now
		# asks for makes way for one that does (the store's sides are for
		# what the next level needs).
		var wanted: Dictionary = _wanted()
		wanted[res] = true
		for cell: int in S.sim.core_touching():
			var outs: Dictionary = S.sim.machine_of(cell).get("outputs", {})
			if outs.is_empty() or S.grid.machine_at(cell) == "vault":
				continue
			# One this laid is given the time to start (measured: an
			# Assembler laid here was read as starved before its first
			# cycle and sold on the next beat, 120 times in five minutes,
			# and the Core 8 stability row stood at 0 for hours).
			if t - float(_fed_at.get(cell, -1.0e9)) < SETTLE:
				continue
			var keep: bool = false
			for o: int in outs:
				keep = keep or wanted.has(o)
			# One starved most of the time is kept for nothing.
			if S.sim.uptime_of(cell) < 0.2 and S.sim.status_of(cell) == Simulation.Status.STARVED:
				keep = false
			if not keep:
				S.sell(cell)
				best = cell
				break
	if best < 0:
		return false
	_fed_at[best] = t
	return _chain(maker, best, 0, String(mk[1]))


## Tiles beside the Core `_feed_core` laid a maker on, and when.
var _fed_at: Dictionary = {}


## The materials the Core's next level wants in its store: its store rows
## not met, and what its machine and Overdrive rows are paid in.
func _wanted() -> Dictionary:
	var out: Dictionary = {}
	for st: Dictionary in S.core_status():
		if bool(st["met"]):
			continue
		var r: Array = st["req"]
		match int(r[0]):
			CoreLevels.Req.STOCK:
				out[int(r[1])] = true
				if int(st["cap"]) < int(st["need"]) and S.core_level >= FORGE_FROM:
					for m: int in (S.machine_upgrade_cost("vault")["materials"] as Dictionary):
						out[m] = true
			CoreLevels.Req.MACHINE:
				for m: int in (S.machine_upgrade_cost(String(r[1]))["materials"] as Dictionary):
					out[m] = true
			CoreLevels.Req.OVERDRIVE:
				for m: int in (S.overdrive_cost(String(r[1]))["materials"] as Dictionary):
					out[m] = true
	return out


## A machine of the type `mk` names, touching the Core and making something
## no open row of the Core asks for, set to `mk`'s job, and a feeder laid
## beside it for what the job takes: what a player does with the sides of
## the Core kept for the store. False when there is no such machine.
func _retask(mk: Array) -> bool:
	var need: Dictionary = {}
	for st: Dictionary in S.core_status():
		if int(st["req"][0]) == CoreLevels.Req.STOCK and not bool(st["met"]):
			need[int(st["req"][1])] = true
	# From Core 8 also what the Core's levels are paid in, and what the jobs
	# making those take: Alloy Parts feeding a Frame Jig are not idle.
	if S.core_level >= FORGE_FROM:
		var w: Dictionary = _wanted()
		for res: int in w.keys():
			var fm: Array = _maker(res)
			if not fm.is_empty():
				for i: int in (MachineDB.job_machine(String(fm[0]), String(fm[1])).get("inputs", {}) as Dictionary):
					w[i] = true
		need.merge(w)
	for cell: int in S.sim.core_touching():
		if S.grid.machine_at(cell) != String(mk[0]) or S.grid.job_at(cell) == String(mk[1]):
			continue
		var wanted: bool = false
		for res: int in (S.sim.machine_of(cell).get("outputs", {}) as Dictionary):
			wanted = wanted or need.has(res)
		# A starved one making the same thing another way is retasked too:
		# the hot rock starved its old line.
		var same: bool = S.sim.machine_of(cell).get("outputs", {}) \
			== MachineDB.job_machine(String(mk[0]), String(mk[1])).get("outputs", {})
		if same and S.sim.uptime_of(cell) < 0.2 and S.sim.status_of(cell) == Simulation.Status.STARVED:
			wanted = false
		if wanted:
			continue
		if S.core_level < FORGE_FROM:
			_retask_at(cell, mk)
			return true
		# From Core 8, only where every input of the new job can be fed: a
		# feeder beside it already, or a tile for one (measured: Frame Jigs
		# retasked between Presses and Smelters, with no tile for the
		# Components they take, starved for hours).
		var ins: Dictionary = MachineDB.job_machine(String(mk[0]), String(mk[1])).get("inputs", {})
		var plan: Dictionary = _feeder_tiles(cell, ins)
		if plan.size() < ins.size() or not S.set_job(cell, String(mk[1])):
			continue
		_line[cell] = true
		for res: int in plan:
			var at: int = int(plan[res])
			if at < 0:
				continue
			if not S.grid.is_empty(at):
				S.sell(at)
			var fm: Array = _maker(res)
			_chain(String(fm[0]), at, 1, String(fm[1]))
		return true
	return false


## The Core 7 era's retask, as measured: the job set, and a feeder laid
## beside it for each input where there is room.
func _retask_at(cell: int, mk: Array) -> void:
	if not S.set_job(cell, String(mk[1])):
		return
	_line[cell] = true
	for res: int in (MachineDB.job_machine(String(mk[0]), String(mk[1])).get("inputs", {}) as Dictionary):
		var fm: Array = _maker(res)
		if fm.is_empty():
			continue
		var spots: Array[int] = _free_near(cell, true)
		if spots.is_empty():
			# What fed its old job gives way to what feeds the new one.
			for n: int in S.grid.neighbours(cell):
				if S.sim.core_touching().has(n) or S.grid.is_empty(n):
					continue
				var nid: String = S.grid.machine_at(n)
				if nid in ["crusher", "drill", "vault"] and S.grid.job_at(n) == "":
					S.sell(n)
					spots.append(n)
					break
		if not spots.is_empty():
			_chain(String(fm[0]), spots[0], 1, String(fm[1]))


## For each of `ins` a machine on `cell` takes: -1 when a machine beside it
## already makes it, else a tile beside it for a feeder -- free ground, or a
## machine off the Core's side that feeds it nothing and is no heat support,
## which gives way. {res: tile}; an input missing has no way to be fed.
func _feeder_tiles(cell: int, ins: Dictionary) -> Dictionary:
	var plan: Dictionary = {}
	var used: Dictionary = {}
	for res: int in ins:
		if _maker(res).is_empty():
			continue
		for n: int in S.grid.bridged_machines(cell):
			if (S.sim.machine_of(n).get("outputs", {}) as Dictionary).has(res):
				plan[res] = -1
		if plan.has(res):
			continue
		for n: int in _free_near(cell, true):
			if not used.has(n):
				plan[res] = n
				break
		if plan.has(res):
			used[plan[res]] = true
			continue
		for n: int in S.grid.neighbours(cell):
			if used.has(n) or S.grid.is_empty(n) or S.sim.core_touching().has(n) or _reserved(n):
				continue
			var nid: String = S.grid.machine_at(n)
			if MachineDB.is_heat_support(nid) or nid == "vault" and not _income_only(n):
				continue
			var feeds: bool = false
			for o: int in (S.sim.machine_of(n).get("outputs", {}) as Dictionary):
				feeds = feeds or ins.has(o)
			if not feeds and S.is_open(n) and not S.is_blocked(n):
				plan[res] = n
				used[n] = true
				break
	return plan


## What a maker and the chain behind it cost, roughly: a player looks at the
## prices before starting a line they cannot finish.
func _chain_cost(id: String, job: String = "") -> float:
	var m: Dictionary = MachineDB.job_machine(id, job)
	var total: float = S.cost_of(id)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research") and ins.size() > 1:
		ins = {MachineDB.Res.INGOT: 1}
	for res: int in ins:
		var mk: Array = _maker(res)
		if mk.is_empty():
			return INF
		total += _chain_cost(String(mk[0]), String(mk[1])) * float(clampi(int(ins[res]), 1, 2))
	if MachineDB.heat_liking(id) > 0 and S.is_unlocked("boiler"):
		total += S.cost_of("boiler")
	return total


## A machine starved for an input gets a feeder on a free tile beside it; one
## blocked, with nowhere for its output to go, a Vault.
func _repair() -> void:
	for cell: int in S.grid.cells:
		# A Rig Frame stands still when the crew is full, and waits on the
		# lines beside it: it is fed and emptied by the crew, not repaired.
		if S.grid.job_at(cell) == "rig":
			continue
		if S.sim.status_of(cell) == Simulation.Status.BLOCKED:
			if not _worth(S.cost_of("vault")) or S.grid.machine_at(cell) == "drill":
				continue
			# Like a starved one: given the time to show what the last
			# answer did (measured: a Vault sold every few seconds for a new
			# one beside the same machine, 55 in five minutes).
			if t - float(_touched.get(cell, -1.0e9)) < SETTLE:
				continue
			_touched[cell] = t
			var out: int = _room_near(cell, "vault")
			if out >= 0 and S.try_place(out, "vault"):
				return
			continue
		if S.sim.status_of(cell) != Simulation.Status.STARVED:
			continue
		if t - float(_touched.get(cell, -1.0e9)) < SETTLE:
			continue
		_touched[cell] = t
		var m: Dictionary = S.sim.machine_of(cell)
		if (m.get("tags", []) as Array).has("sink"):
			continue
		var ins: Dictionary = m.get("inputs", {})
		if (m.get("tags", []) as Array).has("research") and ins.size() > 1:
			ins = {MachineDB.Res.INGOT: 1}
		for res: int in ins:
			var mk: Array = _maker(res)
			if mk.is_empty() or not _worth(_chain_cost(String(mk[0]), String(mk[1]))):
				continue
			if S.core_level >= FORGE_FROM:
				# From Core 8: the input it lacks, not one already fed (measured:
				# a Frame Jig fed Alloy was given more Alloy, never Components),
				# on a tile beside it -- free, or a machine feeding it nothing.
				var plan: Dictionary = _feeder_tiles(cell, {res: 1})
				if not plan.has(res) or int(plan[res]) < 0:
					continue
				var at: int = int(plan[res])
				if not S.grid.is_empty(at):
					S.sell(at)
				_chain(String(mk[0]), at, 1, String(mk[1]))
				return
			var spots: Array[int] = _free_near(cell, true)
			if spots.is_empty():
				# No room: an income-only neighbour makes way for the feeder.
				for n: int in S.grid.neighbours(cell):
					if _income_only(n) and not S.sim.core_touching().has(n):
						S.sell(n)
						spots.append(n)
						break
			if not spots.is_empty():
				_chain(String(mk[0]), spots[0], 1, String(mk[1]))
				return


## Machine `id` on `cell`, on job `job`, and whatever it needs to be fed
## behind it.
func _chain(id: String, cell: int, depth: int, job: String = "") -> bool:
	if depth > 6 or not S.try_place(cell, id):
		return false
	_line[cell] = true
	if job != "":
		S.set_job(cell, job)
	var m: Dictionary = MachineDB.job_machine(id, job)
	_cool_if_needed(cell)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research") and ins.size() > 1:
		ins = {MachineDB.Res.INGOT: 1}
	for res: int in ins:
		var fed: bool = false
		for n: int in S.grid.bridged_machines(cell):
			if (S.sim.machine_of(n).get("outputs", {}) as Dictionary).has(res):
				fed = true
		if fed:
			continue
		var mk: Array = _maker(res)
		if mk.is_empty():
			continue
		var maker: String = String(mk[0])
		# Two feeders for a machine that takes two of a thing at a time.
		for _k in range(clampi(int(ins[res]), 1, 2)):
			var spots: Array[int] = _free_near(cell, true)
			if spots.is_empty():
				for n: int in S.grid.neighbours(cell):
					if _income_only(n) and not S.sim.core_touching().has(n) and S.grid.machine_at(n) != maker:
						S.sell(n)
						spots.append(n)
						break
			if spots.is_empty():
				break
			_chain(maker, spots[0], depth + 1, String(mk[1]))
	# A warmth-loving maker gets a Boiler beside it -- from the Core's level
	# KEEP_FROM only where it is still cold: the rock of strata 13 and deeper
	# is warmer than any maker wants.
	var cold: bool = S.core_level < KEEP_FROM \
		or S.grid.heat_at(cell) < float(m.get("heat_optimum", 0.0))
	if (MachineDB.heat_liking(id) > 0 or float(m.get("heat_optimum", 0.0)) >= 1.0) \
			and S.is_unlocked("boiler") and cold:
		var spots2: Array[int] = _free_near(cell, true)
		if S.core_level >= FORGE_FROM:
			spots2.assign(spots2.filter(func(c: int) -> bool: return _heat_safe(c, "boiler")))
		if not spots2.is_empty():
			S.try_place(spots2[0], "boiler")
	return true


func _build_somewhere(id: String) -> void:
	var outs: Dictionary = MachineDB.get_machine(id).get("outputs", {})
	if S.credits < _chain_cost(id) * 1.5:
		return
	for res: int in outs:
		if MachineDB.STOCKED.has(res):
			if _feed_core(res):
				return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not S.sim.core_touching().has(cell) and _free_near(cell, true).size() >= 2:
			_chain(id, cell, 0)
			var spots: Array[int] = _free_near(cell, true)
			if not spots.is_empty() and not outs.is_empty():
				S.try_place(spots[0], "vault")
			return
	# The yard is full: a player sells a patch of Drills and Vaults, built
	# only for income, and lays the line there.
	for cell: int in BuildArea.cells(S.max_depth):
		if not _income_only(cell) or S.sim.core_touching().has(cell):
			continue
		var patch: Array[int] = [cell]
		for n: int in S.grid.neighbours(cell):
			if _income_only(n) and not S.sim.core_touching().has(n):
				patch.append(n)
		if patch.size() < 4:
			continue
		for c: int in patch:
			S.sell(c)
		_chain(id, cell, 0)
		var spots2: Array[int] = _free_near(cell, true)
		if not spots2.is_empty() and not outs.is_empty():
			S.try_place(spots2[0], "vault")
		return


## A line of `id` with its feeders and a Vault, on free ground or on a
## patch of income-only machines sold for it -- never on the Core's side.
func _build_line(id: String) -> bool:
	var outs: Dictionary = MachineDB.get_machine(id).get("outputs", {})
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not S.sim.core_touching().has(cell) and _free_near(cell, true).size() >= 3:
			return _lay(id, cell, outs)
	for cell: int in BuildArea.cells(S.max_depth):
		if not _income_only(cell) or S.sim.core_touching().has(cell):
			continue
		var patch: Array[int] = [cell]
		for n: int in S.grid.neighbours(cell):
			if (_income_only(n) or _free(n)) and not S.sim.core_touching().has(n):
				patch.append(n)
		if patch.size() < 5:
			continue
		for c: int in patch:
			if not S.grid.is_empty(c):
				S.sell(c)
		return _lay(id, cell, outs)
	return false


func _lay(id: String, cell: int, outs: Dictionary) -> bool:
	if not _chain(id, cell, 0):
		return false
	var spots: Array[int] = _free_near(cell, true)
	if not spots.is_empty() and not outs.is_empty():
		S.try_place(spots[0], "vault")
	return true


## Machines starved or backed up for SCRAP seconds and not in a plan: a
## player clears them away rather than let them hold the yard.
var _stuck_since: Dictionary = {}
const SCRAP := 600.0


func _tidy() -> void:
	var seen: Dictionary = {}
	# What a blueprint laid is left to the blueprint: it is still being
	# finished (its feeders, its job).
	var laid: Dictionary = {}
	for e: Array in S.blueprint_pending:
		laid[int(e[0])] = true
	for cell: int in S.grid.cells:
		if laid.has(cell):
			continue
		# Not yet measured since the board last changed: every placement,
		# sale, move, mode and job clears every machine's status and uptime
		# until the next tick (Simulation.reset_progress), and read then a
		# Duplicator looks idle (measured: a player building every beat
		# scrapped six Duplicators, the Core 6 row's, and forty machines in an
		# hour; the Core 5 stage then lasted twelve).
		if not S.sim.status.has(cell):
			continue
		# Barely working: stalled most of the time, whatever it shows now.
		if S.sim.uptime_of(cell) >= 0.2 or S.sim.status_of(cell) == Simulation.Status.PASSIVE:
			continue
		if _reserved(cell) or S.grid.machine_at(cell) == "vault" \
				or S.sim.core_touching().has(cell) or S.grid.job_at(cell) != "":
			continue
		seen[cell] = true
		if not _stuck_since.has(cell):
			_stuck_since[cell] = t
		elif t - float(_stuck_since[cell]) > SCRAP:
			S.sell(cell)
			_stuck_since.erase(cell)
			_scrapped[cell] = t
			return
	for cell: int in _stuck_since.keys():
		if not seen.has(cell):
			_stuck_since.erase(cell)


## A Drill, Vault or Crusher built for income alone: no plan's tile.
func _income_only(cell: int) -> bool:
	if _line.has(cell) and S.grid.machine_at(cell) != "":
		return false
	_line.erase(cell)
	if not S.grid.machine_at(cell) in ["drill", "vault", "crusher"] or _reserved(cell):
		return false
	# What a Duplicator or an Amplifier serves is what it was placed for
	# (measured: Drills beside the Core 6 row's Duplicators sold one by one
	# for Vaults, until none served three and the row stood for hours).
	if _serves_support(cell):
		return false
	# From Core 7, when the plans' tiles are no longer kept: a Drill or a
	# Crusher that feeds a maker is part of a line, not built for income.
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.grid.machine_at(cell) != "vault":
		for n: int in S.grid.bridged_machines(cell):
			var nm: Dictionary = S.sim.machine_of(n)
			for res: int in (S.sim.machine_of(cell).get("outputs", {}) as Dictionary):
				if (nm.get("inputs", {}) as Dictionary).has(res) and not (nm.get("tags", []) as Array).has("sink"):
					return false
	return true


## Does a support machine that multiplies (a Duplicator, an Amplifier)
## stand beside `cell`?
func _serves_support(cell: int) -> bool:
	for n: int in S.grid.neighbours(cell):
		var m: Dictionary = MachineDB.get_machine(S.grid.machine_at(n))
		if m.has("amplify") or m.has("duplicate_chance"):
			return true
	return false


## Tiles the player laid as part of a line (`_chain`): not income-only, so
## no other line sells them for room.
var _line: Dictionary = {}


## A Lab where refined material reaches it.
func _build_lab() -> void:
	if not S.is_unlocked("lab") or not S.can_afford("lab"):
		return
	if S.core_level >= KEEP_FROM:
		# On hot rock: where it is fed and would not overheat, beside an
		# Assembler (a Component teaches most) if there is such a tile.
		var tol: float = float(MachineDB.get_machine("lab")["heat_tolerance"]) + S.sim.tolerance_bonus
		var own: float = float(MachineDB.get_machine("lab")["heat_out"]) * float(S.grid.heat_scale.get("lab", 1.0))
		var best: int = -1
		var near_parts: bool = false
		for cell: int in BuildArea.cells(S.max_depth):
			if not _free(cell) or S.sim.core_touching().has(cell):
				continue
			if S.grid.heat_at(cell) + own > tol - 0.2 or not bool(S.sim.links_if_placed(cell, "lab")["fed"]):
				continue
			var parts: bool = false
			for n: int in S.grid.neighbours(cell):
				parts = parts or S.grid.machine_at(n) == "assembler"
			if best < 0 or (parts and not near_parts):
				best = cell
				near_parts = parts
			if near_parts:
				break
		if best >= 0:
			S.try_place(best, "lab")
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not S.sim.core_touching().has(cell) \
				and bool(S.sim.links_if_placed(cell, "lab")["fed"]):
			S.try_place(cell, "lab")
			return
	_build_somewhere("lab")


func _fix_heat_of(id: String) -> bool:
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == id and S.sim.heat_efficiency_at(cell) < CoreLevels.WORKING_HEAT:
			if _fix_heat(cell):
				return true
	return false


## A machine of type `id` blocked with nowhere for its output: a Vault beside
## it, on a free tile or one an income-only machine gives up.
func _unblock(id: String) -> bool:
	for cell: int in S.grid.cells:
		if S.grid.machine_at(cell) == id and S.sim.status_of(cell) == Simulation.Status.BLOCKED:
			var spot: int = _room_near(cell, "vault")
			if spot >= 0 and S.try_place(spot, "vault"):
				return true
	return false


## Warm a machine that is too cold, cool one that is too hot: first by taking
## away a neighbour that pushes it the wrong way (strata change the ambient
## heat, so the same line can be over-cooled one stratum down), then by
## adding a Boiler or a Coolant Cell beside it.
func _fix_heat(cell: int, may_remove: bool = true) -> bool:
	if t - float(_touched.get(cell, -1.0e9)) < SETTLE:
		return false
	_touched[cell] = t
	var m: Dictionary = S.sim.machine_of(cell)
	var warm: bool = S.grid.heat_at(cell) < float(m.get("heat_optimum", 0.0))
	var wrong: String = "coolant" if warm else "boiler"
	var modes: bool = S.core_level >= MachineDB.MODES_CORE
	# Too hot, in the order the heat card offers it: a Boiler beside it run
	# Low; a Boiler the rock has made needless taken away; the machine run
	# Cool; the Coolant Cells a level up; then a new Coolant Cell.
	if not warm:
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "boiler" and modes and S.grid.mode_at(n) == MachineDB.Mode.NORMAL:
				return S.set_mode(n, MachineDB.Mode.COOL)
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "boiler" and (may_remove or S.grid.ambient_heat >= 1.8):
				S.sell(n)
				_dropped[n] = true
				return true
		if modes and S.grid.mode_at(cell) == MachineDB.Mode.NORMAL \
				and MachineDB.modes_for(S.grid.machine_at(cell)).has(MachineDB.Mode.COOL):
			return S.set_mode(cell, MachineDB.Mode.COOL)
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "coolant" and S.can_upgrade_machine("coolant"):
				return S.upgrade_machine("coolant")
	elif S.core_level >= KEEP_FROM and S.grid.mode_at(cell) == MachineDB.Mode.COOL:
		# Too cold and running Cool: Normal again, as the heat card says.
		return S.set_mode(cell, MachineDB.Mode.NORMAL)
	for n: int in S.grid.neighbours(cell):
		if may_remove and S.grid.machine_at(n) == wrong:
			S.sell(n)
			_dropped[n] = true
			return true
	var id: String = "boiler" if warm else "coolant"
	if not S.is_unlocked(id) or not S.can_afford(id):
		return false
	if id == "boiler" and S.core_level >= FORGE_FROM:
		# From Core 8: only where no neighbour goes past its safe range.
		for n: int in _free_near(cell, false):
			if _heat_safe(n, "boiler"):
				return S.try_place(n, "boiler")
		return false
	var spot: int = _room_near(cell)
	if spot < 0 and id == "coolant":
		# A Coolant Cell passes material through, so it may take a tile a
		# plan kept empty; the plan leaves it there on this stratum.
		for n: int in S.grid.neighbours(cell):
			if S.grid.is_empty(n) and S.is_open(n) and not S.is_blocked(n):
				spot = n
				_dropped[n] = true
				break
	if spot < 0 and id == "coolant":
		# Boxed in: a Vault beside it gives way to a Coolant Cell, which
		# passes material on to what stands beyond it.
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "vault" and not S.sim.core_touching().has(n):
				S.sell(n)
				spot = n
				_dropped[n] = true
				break
	return spot >= 0 and S.try_place(spot, id)


## A support machine where it serves `need` machines: a free tile, or one
## standing an income-only machine, sold for it.
func _place_support(id: String, need: int) -> void:
	if not S.is_unlocked(id) or not S.can_afford(id):
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and S.grid.serves_if_placed(cell) >= need:
			S.try_place(cell, id)
			return
	for cell: int in BuildArea.cells(S.max_depth):
		var here: String = S.grid.machine_at(cell)
		if here in ["drill", "vault"] and not _reserved(cell) and S.grid.serves(cell) >= need:
			S.sell(cell)
			S.try_place(cell, id)
			return
	# No tile serves enough: the best free one, and Drills laid round it
	# until it would, on tiles where they run cool enough -- what a player
	# does who has read the row.
	if id != "condenser" and _lay_support(id, need):
		return
	# From the Core's level KEEP_FROM: a Condenser in a Coolant Cell's place
	# among the machines it cools (it cools harder, and speeds them).
	if id != "condenser" or S.core_level < KEEP_FROM:
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if S.grid.machine_at(cell) == "coolant" and S.grid.serves(cell) >= need:
			S.sell(cell)
			if S.try_place(cell, id):
				_dropped[cell] = true
			return


## A support machine `id` on the free tile beside the most machines, with
## Drills on its free neighbours until it serves `need`. False when no tile
## has room for that.
func _lay_support(id: String, need: int) -> bool:
	var best: int = -1
	var best_n: int = -1
	for cell: int in BuildArea.cells(S.max_depth):
		if not _free(cell) or S.sim.core_touching().has(cell):
			continue
		var have: int = S.grid.serves_if_placed(cell)
		var room: int = 0
		for n: int in _free_near(cell, true):
			if _heat_safe(n, "drill"):
				room += 1
		if have + room >= need and have > best_n:
			best = cell
			best_n = have
	if best < 0:
		return false
	for n: int in _free_near(best, true):
		if S.grid.serves_if_placed(best) >= need:
			break
		if _heat_safe(n, "drill") and S.can_afford("drill"):
			S.try_place(n, "drill")
	if S.grid.serves_if_placed(best) < need or not S.can_afford(id):
		return false
	return S.try_place(best, id)


## What "What now?" names, off the Core's kept sides.
func _grow() -> void:
	# From Core 7, on the deep rock, the factory grows by the deep chain
	# (`_build_deep`, `_build_research_unit`) and by what the Core's rows
	# ask for: an old line laid for income alone is a line the rock
	# overheats (measured: 120M credits an hour spent on lines that broke
	# the stability row).
	if S.core_level >= MachineDB.OVERDRIVE_CORE and S.job_open("smelter", "alloy"):
		return
	# A whole line of the best maker found, fed from its own Drills, with
	# a Vault: what a player who has learnt the chain builds. Single
	# machines where "What now?" points are for the first minutes.
	var top: String = ""
	for id: String in ["assembler", "press", "smelter"]:
		if S.is_unlocked(id):
			top = id
			break
	if top != "" and S.credits - _keep >= _chain_cost(top) * 1.5 + S.cost_of("vault"):
		if _build_line(top):
			return
	if _keep > 0.0 and S.credits <= _keep:
		return
	var best: Dictionary = Worklist.best_placement(S)
	var ext: Dictionary = Worklist.extension(S, best)
	if not ext.is_empty() and _free(int(ext["cell"])) and _free(int(ext["outlet"])):
		if S.try_place(int(ext["cell"]), String(ext["id"])):
			S.try_place(int(ext["outlet"]), "vault")
			return
	if not best.is_empty() and _free(int(best["cell"])):
		S.try_place(int(best["cell"]), String(best["id"]))
		return
	# Nothing works anywhere new: another Drill and Vault on free ground.
	if S.credits < S.cost_of("drill") + S.cost_of("vault"):
		return
	for cell: int in BuildArea.cells(S.max_depth):
		if _free(cell) and not _reserved(cell):
			var spots: Array[int] = _free_near(cell, false).filter(func(n: int) -> bool: return not _reserved(n))
			if not spots.is_empty():
				S.try_place(cell, "drill")
				S.try_place(spots[0], "vault")
				return


## Can the player pay `cost` for a repair, and is it worth it? From the
## Core's level 7 -- where machines cost what hundreds of them make them
## cost (MachineDB.cost_for) -- a player spends on repairs at most
## REPAIR_SHARE of what the factory earns (`_repair_budget`), and no one
## repair past REPAIR_PAYBACK seconds of its income: measured without it,
## repairs that did not hold took every credit the Core 7 era earned. Before
## Core 7, as measured: whenever it can be paid.
func _worth(cost: float) -> bool:
	if S.credits < cost:
		return false
	if S.core_level < MachineDB.OVERDRIVE_CORE:
		return true
	return cost <= _rate_now * REPAIR_PAYBACK and cost <= _repair_budget


const REPAIR_PAYBACK := 60.0
const REPAIR_SHARE := 0.2
var _rate_now: float = 0.0
var _repair_budget: float = 0.0
var _last_life: float = 0.0


## From the Core's level 7, a machine laid on rock that already has it at
## the edge of its safe range gets a Coolant Cell beside it as it is laid,
## as a player who has read the heat card lays a line on stratum 19: the
## Cell passes material through, so the line is still fed across it.
func _cool_if_needed(cell: int) -> void:
	if S.core_level < MachineDB.OVERDRIVE_CORE or not S.is_unlocked("coolant"):
		return
	var id: String = S.grid.machine_at(cell)
	if MachineDB.is_heat_support(id) or (MachineDB.get_machine(id)["tags"] as Array).has("sink"):
		return
	var m: Dictionary = S.sim.machine_of(cell)
	if m.has("heat_drive"):
		return
	var edge: float = float(m["heat_tolerance"]) + S.sim.tolerance_bonus - COOL_MARGIN
	if S.grid.heat_at(cell) <= edge or not S.can_afford("coolant"):
		return
	var spots: Array[int] = _free_near(cell, true)
	if spots.is_empty():
		# No free tile: an empty one a plan or the rock left, then a Vault
		# beside it gives way -- a Cell passes material on as a Vault did not.
		for n: int in S.grid.neighbours(cell):
			if S.grid.is_empty(n) and S.is_open(n) and not S.is_blocked(n):
				spots.append(n)
				break
	if spots.is_empty():
		for n: int in S.grid.neighbours(cell):
			if S.grid.machine_at(n) == "vault" and not S.sim.core_touching().has(n):
				S.sell(n)
				spots.append(n)
				break
	if not spots.is_empty():
		_bare.erase(spots[0])
		S.try_place(spots[0], "coolant")


const COOL_MARGIN := 0.5


## Would a machine of type `id` on `spot` leave every machine beside it
## within its safe range? What the heat card shows before a Boiler goes
## down; from Core 8 the player looks (measured: Boilers laid to warm White
## Heat Smelters overheated the Vaults and Deep Bores beside them, and the
## stability row stayed at 0 for hours).
func _heat_safe(spot: int, id: String) -> bool:
	var h: float = float(MachineDB.get_machine(id).get("heat_out", 0.0)) \
		* float(S.grid.heat_scale.get(id, 1.0)) * S.grid.heat_spread
	if h <= 0.0:
		return true
	for n: int in S.grid.neighbours(spot):
		var nid: String = S.grid.machine_at(n)
		if nid == "" or MachineDB.is_heat_support(nid):
			continue
		var m: Dictionary = S.sim.machine_of(n)
		if m.has("heat_drive"):
			continue
		if S.grid.heat_at(n) + h > float(m["heat_tolerance"]) + S.sim.tolerance_bonus - COOL_MARGIN:
			return false
	return true


## When each machine now overheating was first seen to (`_pursue`,
## stability); cleared once nothing overheats.
var _hot_since: Dictionary = {}
const HOT_FOR := 900.0


## Credits spent this beat by `what`, from `c0` (the credits before it),
## counted in `spend`. Returns the credits now.
func _spent(what: String, c0: float) -> float:
	var d: float = c0 - float(S.credits)
	if d > 0.0:
		spend[what] = float(spend.get(what, 0.0)) + d
		if what == "repairs":
			_repair_budget -= d
	return float(S.credits)


## Credits spent by what, since the last snapshot.
var spend: Dictionary = {}


## --- the deep chain -------------------------------------------------------------------

## A Drill on the old job that overheats, set to bore crystal -- and a
## Smelter beside it making Ingots the store has no room for, set to White
## Heat to take the crystal. True when the Drill was retasked.
func _to_deep(cell: int) -> bool:
	if S.grid.machine_at(cell) != "drill" or S.grid.job_at(cell) != "" or not S.can_set_job(cell, "crystal"):
		return false
	# A Drill feeding a Crusher is the old chain's ore: the Components and
	# Plates the Core still asks for start there. Only a Drill built for
	# income alone is retasked.
	for n: int in S.grid.bridged_machines(cell):
		if S.grid.machine_at(n) == "crusher":
			return false
	S.set_job(cell, "crystal")
	_line[cell] = true
	_event("retask", "first Drill retasked to Deep Bore")
	var ingots_wanted: bool = S.stock_of(MachineDB.Res.INGOT) < S.stock_cap() \
		or S.core_status().any(func(st: Dictionary) -> bool:
			return int(st["req"][0]) == CoreLevels.Req.STOCK and int(st["req"][1]) == MachineDB.Res.INGOT \
				and not bool(st["met"]))
	for n: int in S.grid.neighbours(cell):
		if S.grid.machine_at(n) == "smelter" and S.grid.job_at(n) == "" and not ingots_wanted:
			S.set_job(n, "alloy")
			_line[n] = true
	return true

## Deep units the player builds at most: a Deep Bore, a White Heat Smelter
## and a Vault each.
const DEEP_UNITS := 32
const DEEP_PAYBACK := 120.0


func _deep_units() -> int:
	var n: int = 0
	for cell: int in S.grid.cells:
		if S.grid.job_at(cell) == "alloy":
			n += 1
	return n


func _deep_cost() -> float:
	return S.cost_of("drill") + S.cost_of("smelter") + S.cost_of("vault")


## From the Core's level FORGE_FROM the player judges a deep unit by what it
## sells, not by the factory's income: at most DEEP_UNIT_PAYBACK seconds.
const FORGE_FROM := 8
const DEEP_UNIT_PAYBACK := 1800.0


## Credits a second a new deep unit's Alloy sells for: the best White Heat
## Smelter at work now, as a Vault sells what it makes.
func _unit_income() -> float:
	var best: float = 0.0
	for cell: int in S.grid.cells:
		if S.grid.job_at(cell) == "alloy" and S.sim.status_of(cell) == Simulation.Status.RUNNING:
			best = maxf(best, S.sim.effective_rate(cell))
	return best * S.sim.yield_mult * MachineDB.value_of(MachineDB.Res.ALLOY) * S.sim.value_mult \
		* float(S.sim.res_value_mult.get(MachineDB.Res.ALLOY, 1.0))


## A Deep Bore, a White Heat Smelter and a Vault in a row on free ground,
## not beside the Core and where none of the three stands beside a maker
## of the old chain that would overheat with it -- or, with no such ground
## left, on a patch of income-only machines sold for it.
func _build_deep() -> bool:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	for pass_ in range(2):
		for cell: int in BuildArea.cells(S.max_depth):
			for d: Vector2i in dirs:
				var row: Array[int] = []
				var p: Vector2i = Grid.xy(cell)
				for k in range(3):
					var q: Vector2i = p + d * k
					if not Grid.in_bounds(q.x, q.y):
						break
					row.append(Grid.idx(q.x, q.y))
				if row.size() < 3 or not _deep_ground(row, pass_ == 1):
					continue
				for c: int in row:
					_bare.erase(c)
					if not S.grid.is_empty(c):
						S.sell(c)
				if not S.try_place(row[0], "drill") or not S.try_place(row[1], "smelter") \
						or not S.try_place(row[2], "vault"):
					return false
				S.set_job(row[0], "crystal")
				S.set_job(row[1], "alloy")
				for c: int in row:
					_line[c] = true
				return true
	return false


## Can a deep unit stand on `row`? Free tiles (or, `sell`, income-only
## ones), off the Core's sides, and nothing but empty ground, Vaults,
## supports or deep machines beside them.
func _deep_ground(row: Array[int], sell: bool) -> bool:
	for c: int in row:
		if S.sim.core_touching().has(c):
			return false
		var bare: bool = _bare.has(c) and S.grid.is_empty(c) and S.is_open(c) and not S.is_blocked(c)
		if not (_free(c) or bare or sell and _income_only(c) and S.grid.job_at(c) == ""):
			return false
	for c: int in row:
		for n: int in S.grid.neighbours(c):
			if row.has(n) or S.grid.is_empty(n):
				continue
			var id: String = S.grid.machine_at(n)
			if id == "vault" or S.grid.job_at(n) != "" or MachineDB.is_heat_support(id):
				continue
			if sell and _income_only(n):
				continue
			return false
	return true


## The player's own memory, to play on from later (core_journey.gd,
## LODEWORKS_CORE_KEEP / _FROM).
func state() -> Dictionary:
	return {"t": t, "events": events, "seen": _seen, "dropped": _dropped,
		"dropped_depth": _dropped_depth, "bare": _bare, "touched": _touched,
		"stuck": _stuck_since, "line": _line, "history": _history, "shaft": shaft,
		"doctrine": doctrine}


func restore(d: Dictionary) -> void:
	t = float(d["t"])
	events = d["events"]
	_seen = d["seen"]
	_dropped = _int_keys(d["dropped"])
	_dropped_depth = int(d["dropped_depth"])
	_bare = _int_keys(d["bare"])
	_touched = _int_keys(d["touched"])
	_stuck_since = _int_keys(d["stuck"])
	_line = _int_keys(d["line"])
	_history = d["history"]
	shaft = int(d.get("shaft", 1))
	doctrine = String(d.get("doctrine", doctrine))


## JSON brings a Dictionary's int keys back as strings.
func _int_keys(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d:
		out[int(k)] = d[k]
	return out


## The driver skipped `dt` seconds of a credit-only wait, `earned` credits
## in it: the player's own clocks move with it, so the skip is not time a
## repair waited for, and the income it measures is unchanged.
func fast_forwarded(dt: float, earned: float) -> void:
	for e: Array in _history:
		e[0] = float(e[0]) + dt
		e[1] = float(e[1]) + earned
	for k: int in _touched:
		_touched[k] = float(_touched[k]) + dt
	for k: int in _stuck_since:
		_stuck_since[k] = float(_stuck_since[k]) + dt


## --- what the player has, as numbers ------------------------------------------------

## Credits a second over the last minute of play.
var _history: Array = []


func rate() -> float:
	_history.append([t, float(S.lifetime_credits)])
	while _history.size() > 1 and t - float(_history[0][0]) > 60.0:
		_history.pop_front()
	var span: float = t - float(_history[0][0])
	return 0.0 if span <= 0.0 else (float(S.lifetime_credits) - float(_history[0][1])) / span


func snapshot() -> Dictionary:
	var open: Array = []
	for st: Dictionary in S.core_status():
		if not bool(st["met"]):
			open.append(_req_text(st))
	var research_left: int = 0
	for id: String in Economy.TREE_ORDER:
		research_left += maxi(S.research_cap(id) - S.upgrade_level(id), 0)
	var upgrades_left: int = 0
	for id: String in MachineDB.ORDER:
		if S.is_unlocked(id) and MachineDB.has_levels(id):
			upgrades_left += maxi(S.machine_level_cap() - S.machine_level(id), 0)
	var locked: int = 0
	for id: String in MachineDB.ORDER:
		if not S.is_unlocked(id):
			locked += 1
	return {"t": t, "core": S.core_level, "rate": rate(), "depth": S.depth, "machines": S.grid.cells.size(),
		"lifetime": S.lifetime_credits, "stock": S.stock.duplicate(), "store": S.stock_cap(),
		"levels": S.machine_levels.duplicate(), "research": S.upgrade_levels.duplicate(),
		"open": open, "research_left": research_left, "upgrades_left": upgrades_left,
		"locked": locked, "strata_left": S.depth_cap() - S.depth,
		"contracts": S.contracts_lifetime, "research_banked": S.research, "working": _working_all(),
		"sites": S.ops_lifetime, "salvage": S.salvage, "crew": S.rigs_home() + S.rigs_out() + S.rigs_posted(),
		"breakers": S.breakers + S.breakers_out(),
		"surveyors": S.surveyors + S.surveyors_out() + S.surveyors_away(), "regions": S.regions_open.duplicate(),
		"rescued": S.rescued, "beacons": S.beacons.duplicate(), "dark": S.beacons_dark, "tuners": S.tuners.size(),
		"lens": S.stock_of(MachineDB.Res.LENS), "lens_spent": S.lens_spent.duplicate(),
		"posted": S.rigs_posted(), "bay": S.bay_level, "hauled": S.hauled, "salvage_earned": S.salvage_earned,
		"hot": _hot(), "held": CoreLevels.holding_back(S)["why"], "doctrine": S.doctrine,
		"deep": _deep_units(), "research_per_s": S.sim.last_research, "spend": _take_spend()}


func _take_spend() -> Dictionary:
	var out: Dictionary = spend
	spend = {}
	return out


## The machines past their tolerance, each with what stands beside it:
## what holds the stability row back.
func _hot() -> Array:
	var out: Array = []
	for cell: int in S.grid.cells:
		if S.sim.overheated_at(cell):
			var nb: Array = []
			for n: int in S.grid.neighbours(cell):
				if S.grid.machine_at(n) != "":
					nb.append(S.grid.machine_at(n))
			out.append("%s@%s%s beside %s" % [S.grid.machine_at(cell), str(Grid.xy(cell)),
				" (plan)" if _reserved(cell) else "", ",".join(nb)])
	return out


## Machines of each producing type at their working heat.
func _working_all() -> Dictionary:
	var out: Dictionary = {}
	for id: String in ["drill", "crusher", "smelter", "press", "assembler", "lab"]:
		var n: int = _working(id)
		if n > 0:
			out[id] = n
	# The deep chain's makers among them, by job.
	for job: String in ["crystal", "alloy", "sheet", "parts", "frame", "assay"]:
		var k: int = 0
		var placed: int = 0
		for cell: int in S.grid.cells:
			if S.grid.job_at(cell) != job:
				continue
			placed += 1
			if S.sim.status_of(cell) == Simulation.Status.RUNNING \
					and S.sim.heat_efficiency_at(cell) >= CoreLevels.WORKING_HEAT:
				k += 1
		if placed > 0:
			out[job] = "%d/%d" % [k, placed]
	return out


func _req_text(st: Dictionary) -> String:
	var r: Array = st["req"]
	var name: String = ["credits", "stock", "working", "machine", "depth", "research", "serves",
		"stable", "overdrive", "doctrine", "operations", "regions", "region lines", "roles", "beacons"][int(r[0])]
	if r.size() > 2:
		var what: String = String(MachineDB.RES_NAME[int(r[1])]) if int(r[0]) == CoreLevels.Req.STOCK else str(r[1])
		name += " " + what
	# What stands in a level's or a step's way: the reason the row waits.
	var why: String = ""
	match int(r[0]):
		CoreLevels.Req.MACHINE:
			why = S.machine_upgrade_blocker(String(r[1]))
		CoreLevels.Req.OVERDRIVE:
			why = S.overdrive_blocker(String(r[1]))
	return "%s %s/%s%s" % [name, Economy.fmt(float(st["have"])), Economy.fmt(float(st["need"])),
		" (%s)" % why if why != "" else ""]
