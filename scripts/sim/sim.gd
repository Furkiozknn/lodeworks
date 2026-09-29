extends Node

## The running game. One autoload that owns the state, steps the factory, and
## emits what the UI needs. Everything it depends on (Grid, Simulation, Strata,
## Economy) is a plain RefCounted with no node in it, so the entire game can be
## exercised headless -- which is how the tests work and how the balance was
## checked without ever opening a window.

signal stats_changed()
signal depth_changed(depth: int)
signal machines_unlocked(ids: Array)
signal collapsed(cores_gained: int)
## The Factory Core reached `level` (CoreLevels).
signal core_upgraded(level: int)
## Every machine of type `id` is now at `level`.
signal machine_upgraded(id: String, level: int)
## Contract `index` of the Dispatch board was filled and paid `paid` in
## `pays` ("credits" or "research").
signal contract_filled(index: int, paid: float, pays: String)
signal offline_earnings(report: Dictionary)
## A sortie left (site slot, Rigs), and one came home (Sim._sortie_home).
signal sortie_sent(slot: int, rigs: int)
signal sortie_back(report: Dictionary)
## A region of the deep map opened by an expedition (Operations, "regions").
signal region_opened(region: String)
## A Beacon lit in `region` (Operations, "Beacons"); the Beacons gone dark
## for want of Lenses, or lit again.
signal beacon_lit(region: String)
signal beacons_dimmed(dark: bool)

const AUTOSAVE_SECONDS := 20.0

## The headline rate is a plain average over a fixed window, not an
## exponential smoothing of the per-tick value.
##
## This system is bursty by construction: a Vault sells a whole buffer in one
## tick and nothing on the next, so the instantaneous rate swings by a factor
## of several every tenth of a second. An exponential filter over that still
## wanders — the same board was measured showing 35/s, 81/s and 141/s on three
## consecutive captures — and a headline figure that disagrees with itself is
## the single fastest way to teach a player not to trust any number the game
## prints. Summing three seconds of actual production and dividing is boring,
## honest, and steady.
const RATE_WINDOW := 3.0

var grid: Grid
var sim: Simulation

var credits: float = 0.0
var research: float = 0.0
var cores: int = 0
## What the Rigs hauled out of the galleries' cleared sites and has not been
## spent (Operations.salvage). A collapse keeps it, as it keeps Cores.
var salvage: int = 0
var depth: int = 0
var max_depth: int = 0
var lifetime_credits: float = 0.0
var collapses: int = 0

var upgrade_levels: Dictionary = {}
## The Factory Core's level (CoreLevels): 1 as a shaft opens. It caps how
## deep the shaft may go and how far machines may be upgraded.
var core_level: int = 1
## Machine type -> level (1 when absent). MachineDB.level_speed.
var machine_levels: Dictionary = {}
## Machine type -> Overdrive steps taken (0 when absent), from the Core's
## level MachineDB.OVERDRIVE_CORE (`overdrive_machine`).
var overdrive: Dictionary = {}
## The Core's store: what machines touching the Core have handed it,
## {res: count}, up to what the Vault's level holds (`stock_cap`). Machine
## levels and the Core's own levels are paid from it.
var stock: Dictionary = {}
## The Dispatch board (Dispatch): Dispatch.SLOTS slots, each a contract
## {"res", "n", "pays", "serial"}, or {"rest": units} while a dropped
## contract's slot waits for that many more units in the store, or {}.
var contracts: Array = []
## How many contracts this shaft has been dealt, and has filled; and how
## many every shaft has filled (a collapse keeps it).
var dispatch_serial: int = 0
var contracts_filled: int = 0
var contracts_lifetime: int = 0
## Saved layouts (`save_blueprint`): one per slot, each {"cells": [[cell,
## id, mode, job], ...], "core": the Core's level it was saved at, "depth":
## the stratum}, or {} for an empty slot. A collapse keeps them.
var blueprints: Array = []
## What a blueprint being laid still has to place: [cell, id, mode, job]
## entries, put down as credits, the yard and the machines found allow
## (`fill_pending`).
var blueprint_pending: Array = []
## The doctrine this shaft follows (Economy.DOCTRINES), "" before one is
## chosen. A collapse clears it: the next shaft chooses again.
var doctrine: String = ""
## The highest level any shaft's Core has reached. A new shaft's Core
## starts at its FOUNDATION_SHARE (`foundation`).
var best_core: int = 1
var unlocked: Array[String] = []
var settings: Dictionary = {"sound": true, "haptics": true}

## Live measured rates, used for the header and for offline earnings.
var credits_per_sec: float = 0.0
var research_per_sec: float = 0.0
## The last rates actually measured on this board. The display restarts at
## zero after a Descend (the stratum's rules change the rate), but a save
## made before the new stratum's first measurement banks offline income at
## these, not at nothing. A collapse clears them with the board.
var _measured_rate: float = 0.0
var _measured_research_rate: float = 0.0

var _rate_accum_credits: float = 0.0
var _rate_accum_research: float = 0.0
var _rate_elapsed: float = 0.0
var _board_changed_at: float = 0.0
var _tick_accum: float = 0.0
var _save_accum: float = 0.0
var _stratum: Dictionary = {}
var _mult: Dictionary = {}
var _fill_accum: float = 0.0
var _started: bool = false
var _tutorial_step: int = 0
## Two things the tutorial has to know that the board cannot tell it: whether
## the player has ever moved a machine, and whether they have ever looked at
## the heat overlay. Both are lessons about the interface rather than about
## the factory, so both are counted here rather than inferred.
var tutorial_moves: int = 0
var tutorial_saw_heat: bool = false
## Whether this shaft's Factory Core has been brought online. A new game, and
## every shaft after a collapse, opens with it dark: bringing it online is the
## player's first act, and its reserve buys the first Drill and Vault.
##
## Before this, a new game opened with nothing in the purse and a Drill that
## cost 15 -- no way to place anything, so no way to start -- and every shaft
## after a collapse opened the same way (docs/AUDIT.md, "The first minute").
var core_online: bool = false


func _ready() -> void:
	_ensure()
	process_mode = Node.PROCESS_MODE_ALWAYS


## Builds the model if it does not exist yet.
##
## An autoload's `_ready` does not always run before the first thing that wants
## to use it -- a headless script entry point reaches the singleton first, and
## every accessor then dereferences a null grid. Constructing on demand is one
## line and removes a whole class of ordering bug.
func _ensure() -> void:
	if grid != null:
		return
	grid = Grid.new()
	sim = Simulation.new(grid, 20260923)
	_recompute()


func start() -> void:
	_ensure()
	if _started:
		return
	_started = true
	var report: Dictionary = Save.load_game(self)
	_recompute()
	if not report.is_empty():
		offline_earnings.emit(report)
	Analytics.track("first_launch")
	Analytics.track("session_start", {"depth": depth, "collapses": collapses})


func _process(delta: float) -> void:
	if not _started:
		return
	_tick_accum += delta
	var steps: int = 0
	while _tick_accum >= Simulation.TICK_DT and steps < 6:
		_tick_accum -= Simulation.TICK_DT
		var out: Dictionary = sim.tick()
		after_tick(Simulation.TICK_DT)
		var c: float = float(out["credits"])
		var r: float = float(out["research"])
		credits += c
		research += r
		if c > 0.0 and lifetime_credits <= 0.0:
			# The moment the numbers first move. If this never fires for a
			# player, the tutorial failed, not the balance.
			Analytics.track("first_production")
		lifetime_credits += c
		_rate_accum_credits += c
		_rate_accum_research += r
		_rate_elapsed += Simulation.TICK_DT
		steps += 1
	if _rate_elapsed >= RATE_WINDOW and _started:
		credits_per_sec = _rate_accum_credits / _rate_elapsed
		research_per_sec = _rate_accum_research / _rate_elapsed
		_measured_rate = credits_per_sec
		_measured_research_rate = research_per_sec
		_rate_accum_credits = 0.0
		_rate_accum_research = 0.0
		_rate_elapsed = 0.0
	if steps > 0:
		if not blueprint_pending.is_empty():
			_fill_accum += float(steps) * Simulation.TICK_DT
			if _fill_accum >= 1.0:
				_fill_accum = 0.0
				fill_pending()
		stats_changed.emit()

	_save_accum += delta
	if _save_accum >= AUTOSAVE_SECONDS:
		_save_accum = 0.0
		Save.save_game(self)


## --- board -----------------------------------------------------------------

func cost_of(id: String) -> float:
	return MachineDB.cost_for(id, grid.count_of(id))


func can_afford(id: String) -> bool:
	return credits >= cost_of(id)


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func is_blocked(cell: int) -> bool:
	return Strata.blocked_cells(depth).has(cell)


## Is `cell` inside this shaft's yard (BuildArea)? New machines go only there.
func is_open(cell: int) -> bool:
	return BuildArea.is_open(cell, max_depth, collapses)


func try_place(cell: int, id: String) -> bool:
	if not is_unlocked(id) or is_blocked(cell) or not is_open(cell) \
			or not grid.is_empty(cell):
		return false
	var price: float = cost_of(id)
	if credits < price:
		return false
	if not grid.place(cell, id):
		return false
	credits -= price
	sim.forget([cell])
	_recompute()
	stats_changed.emit()
	return true


## Selling refunds most of the price. A partial refund keeps demolition a real
## decision; a full refund would make the board a scratchpad with no stakes,
## and no refund would punish the experimentation the game is built on.
func sell(cell: int) -> bool:
	if grid.is_empty(cell):
		return false
	var id: String = grid.machine_at(cell)
	var refund: float = MachineDB.cost_for(id, maxi(grid.count_of(id) - 1, 0)) * 0.75
	grid.remove(cell)
	credits += refund
	sim.forget([cell])
	_recompute()
	stats_changed.emit()
	return true


func move_machine(from_cell: int, to_cell: int) -> bool:
	if is_blocked(to_cell) or not is_open(to_cell):
		return false
	if not grid.move(from_cell, to_cell):
		return false
	sim.forget([from_cell, to_cell])
	_recompute()
	stats_changed.emit()
	tutorial_moves += 1
	return true


## --- the Factory Core ------------------------------------------------------

## What the Core holds for a new shaft: exactly a first Drill and a first
## Vault, the two machines the tutorial asks for first. Not a bonus -- the
## fewest credits a shaft can start earning with.
func core_reserve() -> float:
	return MachineDB.cost_for("drill", 0) + MachineDB.cost_for("vault", 0)


## Bring the Core online and draw its reserve. Once a shaft.
func power_core() -> bool:
	if core_online:
		return false
	core_online = true
	credits += core_reserve()
	# The Foreman's Rig: the crew before the Rig Frame job is made
	# (Operations.FIRST_CREW), there as the Core comes online.
	if core_level < MachineDB.RIG_CORE:
		stock[MachineDB.Res.RIG] = Operations.crew_cap(core_level)
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- descent ---------------------------------------------------------------

func quota() -> float:
	return float(_stratum.get("quota", Strata.quota_for(depth))) * float(_mult.get("quota", 1.0))


func can_descend() -> bool:
	return credits >= quota() and depth + 1 <= depth_cap()


## The deepest stratum the Core's level lets this shaft reach.
func depth_cap() -> int:
	return CoreLevels.depth_cap(core_level)


## The quota is met, but the Core has to grow before the shaft goes deeper.
func descent_needs_core() -> bool:
	return credits >= quota() and depth + 1 > depth_cap()


## --- the Factory Core's level ------------------------------------------------

## The Core's next level, requirement by requirement (CoreLevels.status).
func core_status() -> Array:
	return CoreLevels.status(self)


func can_upgrade_core() -> bool:
	return CoreLevels.can_upgrade(self)


## Grow the Core: its credits and its materials are paid.
func upgrade_core() -> bool:
	if not can_upgrade_core():
		return false
	for r: Array in CoreLevels.requirements(core_level + 1):
		match int(r[0]):
			CoreLevels.Req.CREDITS:
				credits -= float(r[1])
			CoreLevels.Req.STOCK:
				if int(r[1]) == MachineDB.Res.LENS:
					_spend_lens(int(r[2]), "core")
				else:
					_take_stock({int(r[1]): int(r[2])})
	core_level += 1
	# The Core's rows count the sites cleared since it last grew.
	ops_cleared = 0
	_sync_core()
	_deal_ops()
	core_upgraded.emit(core_level)
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- the Core's store ------------------------------------------------------------

## How much of each stored material the store holds: the Vault's level.
func stock_cap() -> int:
	return MachineDB.stock_cap(machine_level("vault"))


func stock_of(res: int) -> int:
	return int(stock.get(res, 0))


## Is `cost` ({res: count}) in the store?
func has_stock(cost: Dictionary) -> bool:
	for res: int in cost:
		if stock_of(res) < int(cost[res]):
			return false
	return true


func _take_stock(cost: Dictionary) -> void:
	for res: int in cost:
		var left: int = stock_of(res) - int(cost[res])
		if left > 0:
			stock[res] = left
		else:
			stock.erase(res)
	_sync_core()


## What the machines touching the Core handed it this tick.
func _collect_stock() -> void:
	if sim.core_took.is_empty():
		return
	var cap: int = stock_cap()
	var units: int = 0
	for res: int in sim.core_took:
		# Rigs are the crew, kept up to the crew's limit, not the store's.
		var limit: int = crew_cap() - rigs_out() - rigs_posted() - breakers - breakers_out() \
			- surveyors - surveyors_out() - surveyors_away() if res == MachineDB.Res.RIG else cap
		stock[res] = mini(stock_of(res) + int(sim.core_took[res]), limit)
		units += int(sim.core_took[res])
	sim.core_took.clear()
	_sync_core()
	# A dropped contract's slot comes back after units into the store.
	var dealt: bool = false
	for i in range(contracts.size()):
		var c: Dictionary = contracts[i]
		if c.has("rest"):
			var left: int = int(c["rest"]) - units
			contracts[i] = {} if left <= 0 else {"rest": left}
			dealt = dealt or left <= 0
	if dealt:
		_deal_board()


## Tell the simulation how much room the store has for each material.
func _sync_core() -> void:
	if sim == null:
		return
	var room: Dictionary = {}
	var cap: int = stock_cap()
	for res: int in MachineDB.STOCKED:
		if stock_of(int(res)) < cap:
			room[int(res)] = cap - stock_of(int(res))
	# The crew: Rigs, up to the limit the Core's level sets, less those out.
	var crew: int = crew_cap() - rigs_home() - rigs_out() - rigs_posted() - breakers - breakers_out() \
		- surveyors - surveyors_out() - surveyors_away()
	if crew > 0 and core_level >= MachineDB.RIG_CORE:
		room[MachineDB.Res.RIG] = crew
	sim.core_wants = room
	sim.core_export = CoreLevels.EXPORT_SHARE if core_level >= CoreLevels.EXPORT_CORE else 0.0


## --- machine modes ---------------------------------------------------------------

## Can the machine on `cell` be set to `mode` now? The Core's level
## MachineDB.MODES_CORE opens modes.
func can_set_mode(cell: int, mode: int) -> bool:
	if grid.is_empty(cell) or core_level < MachineDB.MODES_CORE:
		return false
	return MachineDB.modes_for(grid.machine_at(cell)).has(mode)


func set_mode(cell: int, mode: int) -> bool:
	if not can_set_mode(cell, mode) or grid.mode_at(cell) == mode:
		return false
	grid.set_mode(cell, mode)
	sim.forget([cell])
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- machine jobs ----------------------------------------------------------------

## Why the machine on `cell` cannot be set to `job` now, or "" when it can:
## "none" (no such job for it), "depth" (the rock it needs is further
## down), "core" (the Core's level that opens it).
func job_blocker(cell: int, job: String) -> String:
	var id: String = grid.machine_at(cell)
	if id == "" or not MachineDB.jobs_for(id).has(job):
		return "none"
	if max_depth < int(MachineDB.job_info(id, job).get("depth", 0)):
		return "depth"
	if core_level < int(MachineDB.job_info(id, job).get("core", 1)):
		return "core"
	return _job_gate(id, job)


## A job a region opens ("region") or a Beacon keeps ("control"): "region"
## (not open), "control" (no Beacon lit there), or "".
func _job_gate(id: String, job: String) -> String:
	var info: Dictionary = MachineDB.job_info(id, job)
	if info.has("region") and not region_open(String(info["region"])):
		return "region"
	if info.has("control") and not beacons.has(String(info["control"])):
		return "control"
	return ""


func can_set_job(cell: int, job: String) -> bool:
	return job_blocker(cell, job) == ""


## Has this shaft opened job `job` of machine type `id`: its rock reached,
## its Core level grown?
func job_open(id: String, job: String) -> bool:
	return max_depth >= int(MachineDB.job_info(id, job).get("depth", 0)) \
		and core_level >= int(MachineDB.job_info(id, job).get("core", 1)) and _job_gate(id, job) == ""


func set_job(cell: int, job: String) -> bool:
	if not can_set_job(cell, job) or grid.job_at(cell) == job:
		return false
	grid.set_job(cell, job)
	sim.forget([cell])
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	return true


## Can this shaft make `res` now: a machine that makes it found, on a job
## its rock and its Core have opened.
func can_make(res: int) -> bool:
	for mk: Array in MachineDB.makers_of(res):
		var id: String = String(mk[0])
		if is_unlocked(id) and job_open(id, String(mk[1])):
			return true
	return false


## --- the Dispatch board ------------------------------------------------------------

## Deal a contract into every empty slot, once something the store keeps
## can be made. A slot that is resting stays empty.
func _deal_board() -> void:
	while contracts.size() < Dispatch.SLOTS:
		contracts.append({})
	for i in range(contracts.size()):
		if not (contracts[i] as Dictionary).is_empty():
			continue
		var c: Dictionary = Dispatch.deal(core_level, depth + 100 * collapses, dispatch_serial,
			unlocked, stock_cap(), max_depth)
		if c.is_empty():
			return
		contracts[i] = c
		dispatch_serial += 1


func contract(i: int) -> Dictionary:
	return contracts[i] if i >= 0 and i < contracts.size() else {}


## What contract `i` pays now (credit contracts follow the measured income).
func contract_pay(i: int) -> float:
	var c: Dictionary = contract(i)
	return 0.0 if not c.has("res") else Dispatch.payout(c, offline_rate())


func can_fill_contract(i: int) -> bool:
	var c: Dictionary = contract(i)
	return c.has("res") and stock_of(int(c["res"])) >= int(c["n"])


## Fill contract `i` from the store: it pays, and a new one is dealt.
func fill_contract(i: int) -> bool:
	if not can_fill_contract(i):
		return false
	var c: Dictionary = contract(i)
	var paid: float = contract_pay(i)
	_take_stock({int(c["res"]): int(c["n"])})
	if int(c["res"]) == MachineDB.Res.LENS:
		lens_spent["contract"] = int(lens_spent.get("contract", 0)) + int(c["n"])
	if String(c["pays"]) == "research":
		research += paid
	else:
		credits += paid
		lifetime_credits += paid
	contracts_filled += 1
	contracts_lifetime += 1
	contracts[i] = {}
	_deal_board()
	contract_filled.emit(i, paid, String(c["pays"]))
	stats_changed.emit()
	Save.save_game(self)
	return true


## Drop contract `i`: free, and its slot is dealt again after
## Dispatch.REST_UNITS more units go into the store.
func drop_contract(i: int) -> bool:
	if not contract(i).has("res"):
		return false
	contracts[i] = {"rest": Dispatch.REST_UNITS}
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- operations: the crew and the galleries (Operations) ---------------------------

## The sites on the board, Operations.SLOTS of them ({} for a slot not dealt).
var ops_board: Array = []
var ops_serial: int = 0
## Sites the crew has cleared since the Core last grew (its rows count
## them), and in all.
var ops_cleared: int = 0
var ops_lifetime: int = 0
## Sorties out: [{"slot", "n", "left" (seconds to home), "trip", "site" (as
## it was when they left), "out" (Operations.resolve), "wear" (the crew's
## wear when they left)}].
var sorties: Array = []
## How worn the Rigs at home are, 0..Operations.WEAR_MAX.
var rig_wear: float = 0.0


## The crew the Core keeps under its level.
func crew_cap() -> int:
	if core_level < MachineDB.RIG_CORE:
		return Operations.crew_cap(core_level)
	return Operations.crew_cap(core_level) + Operations.earned_rigs(ops_lifetime) + rescued


## Sites still to clear before the crew earns room for another Rig; 0 when
## it has earned all it can.
func sites_to_next_rig() -> int:
	if core_level < MachineDB.RIG_CORE or Operations.earned_rigs(ops_lifetime) >= Operations.SITE_RIGS_MAX:
		return 0
	return Operations.SITES_PER_RIG - ops_lifetime % Operations.SITES_PER_RIG


func rigs_home() -> int:
	return stock_of(MachineDB.Res.RIG)


func rigs_out() -> int:
	var n: int = 0
	for s: Dictionary in sorties:
		n += int(s["n"])
	return n


## Breakers (Operations, "the Breaker"): Rigs refitted, at the Bay, and out.
var breakers: int = 0


func breakers_out() -> int:
	var b: int = 0
	for s: Dictionary in sorties:
		b += int(s.get("b", 0))
	return b


## Surveyors (Operations, "the Surveyor"): Rigs refitted, at the Bay, and out.
var surveyors: int = 0


func surveyors_out() -> int:
	var v: int = 0
	for s: Dictionary in sorties:
		v += int(s.get("v", 0))
	return v


## The crew by kind, at the Bay, out and posted: {"rig", "breaker",
## "surveyor"}.
func crew_roles() -> Dictionary:
	return {"rig": rigs_home() + rigs_out() + rigs_posted(), "breaker": breakers + breakers_out(),
		"surveyor": surveyors + surveyors_out() + surveyors_away()}


## Why a Rig at the Bay cannot be refitted as a `role` ("breaker",
## "surveyor") now, or "": "core" (the Core's level has not reached
## Operations.role_core), "rigs" (none at the Bay), "salvage", "materials".
func refit_blocker(role: String = "breaker") -> String:
	if core_level < Operations.role_core(role):
		return "core"
	if rigs_home() <= 0:
		return "rigs"
	var c: Dictionary = Operations.refit_cost(core_level, role)
	if salvage < int(c["salvage"]):
		return "salvage"
	if stock_of(int(c["res"])) < int(c["n"]):
		return "materials"
	return ""


## Refit a Rig at the Bay as a `role`.
func refit_rig(role: String = "breaker") -> bool:
	if refit_blocker(role) != "":
		return false
	var c: Dictionary = Operations.refit_cost(core_level, role)
	salvage -= int(c["salvage"])
	_take_stock({int(c["res"]): int(c["n"])})
	stock[MachineDB.Res.RIG] = rigs_home() - 1
	if role == "surveyor":
		surveyors += 1
	else:
		breakers += 1
	_sync_core()
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- the deep map: regions (Operations, "regions") --------------------------------

## The regions this shaft has opened, in the order it opened them.
var regions_open: Array = []
## Stranded Rigs brought home in this shaft: room for one more Rig each.
var rescued: int = 0


func region_open(r: String) -> bool:
	return regions_open.has(r)


## Levels bought in the research lines the regions open (Economy, "region").
func region_lines() -> int:
	var n: int = 0
	for id: String in Economy.RESEARCH_TREE:
		if String((Economy.RESEARCH_TREE[id] as Dictionary).get("region", "")) != "":
			n += upgrade_level(id)
	return n


## What an expedition into region `r` has to be strong enough for now.
func survey_site(r: String) -> Dictionary:
	return Operations.survey_site(r, core_level, depth + 100 * collapses)


## Expeditions out now.
func expeditions_out() -> int:
	var n: int = 0
	for s: Dictionary in sorties:
		if String((s["site"] as Dictionary).get("kind", "")) == "survey":
			n += 1
	return n


## Lenses an expedition into another region costs now.
func expedition_lenses() -> int:
	return Operations.EXPEDITION_LENS * regions_open.size()


## Why `n` Rigs, `b` Breakers and `v` Surveyors cannot go on an expedition
## into region `r` now, or "": "core", "open" (it is), "room" (the Core has
## no room for another open region), "busy" (one is out to it), "surveyor"
## (none in the team), "rigs", "lens", "fuel", "weak" (not strong enough
## for its survey).
func expedition_blocker(r: String, n: int, b: int, v: int) -> String:
	if not Operations.REGIONS.has(r) or core_level < Operations.region_core(r):
		return "core"
	if region_open(r):
		return "open"
	if site_busy(Operations.region_slot(r)):
		return "busy"
	if regions_open.size() + expeditions_out() >= Operations.region_slots(core_level):
		return "room"
	# The Dark Reach: only once enough Beacons burn to light the way.
	if r == "reach" and lit_beacons() < Operations.REACH_LIGHT:
		return "beacons"
	if v < 1:
		return "surveyor"
	if n < 0 or b < 0 or n > rigs_home() or b > breakers or v > surveyors:
		return "rigs"
	if stock_of(MachineDB.Res.LENS) < expedition_lenses() + light_lenses(survey_site(r), n, b, v):
		return "lens"
	if stock_of(Operations.fuel_res(core_level)) < expedition_fuel(n, b, v):
		return "fuel"
	var s: Dictionary = survey_site(r)
	if team_strength(s, n, b, v) < float(s["need"]):
		return "weak"
	return ""


func expedition_fuel(n: int, b: int, v: int) -> int:
	return int(ceil(float(Operations.fuel(n, core_level, b, v)) * Operations.EXPEDITION_FUEL))


## Send an expedition into region `r`: when it is home, the region is open.
func send_expedition(r: String, n: int, b: int, v: int) -> bool:
	if expedition_blocker(r, n, b, v) != "":
		return false
	_spend_lens(expedition_lenses(), "expedition")
	var fuel_extra: int = expedition_fuel(n, b, v) - Operations.fuel(n, core_level, b, v)
	_take_stock({Operations.fuel_res(core_level): fuel_extra})
	return _send(Operations.region_slot(r), survey_site(r), n, b, v)


## The fewest that clear an expedition into region `r`, with a Surveyor --
## every Surveyor at home first -- or everyone at home.
func expedition_team(r: String) -> Vector3i:
	var s: Dictionary = survey_site(r)
	for size in range(1, rigs_home() + breakers + surveyors + 1):
		for t: Vector3i in _splits(s, size):
			if t.z >= 1 and team_strength(s, t.x, t.y, t.z) >= float(s["need"]):
				return t
	return Vector3i(rigs_home(), breakers, surveyors)


## Open region `r`: its slot dealt, its advantage on the factory.
func _open_region(r: String) -> void:
	if region_open(r):
		return
	regions_open.append(r)
	_recompute()
	_deal_ops()
	region_opened.emit(r)


## --- Beacons: regions held (Operations, "Beacons") -------------------------------------

## The regions a Beacon burns in, in the order they were lit; a Surveyor
## keeps each, out of the crew.
var beacons: Array = []
## The store could not pay the Beacons' Lenses: every one is dark, and what
## they give stops until it can.
var beacons_dark: bool = false
var _upkeep_due: float = 0.0
## Machines a Surveyor tunes (tune): cell -> true.
var tuners: Dictionary = {}
## Lenses spent, by what for: "core", "expedition", "beacon", "upkeep",
## "light", "factory" (hauled into a machine), "contract" (Dispatch).
var lens_spent: Dictionary = {}


## Does a Beacon burn in region `r` now?
func controlled(r: String) -> bool:
	return beacons.has(r) and not beacons_dark


## Beacons burning now.
func lit_beacons() -> int:
	return 0 if beacons_dark else beacons.size()


## Surveyors out of the crew's reach: keeping Beacons, tuning machines.
func surveyors_away() -> int:
	return beacons.size() + tuners.size()


func beacon_site(r: String) -> Dictionary:
	return Operations.beacon_site(r, core_level, depth + 100 * collapses)


## Lenses the next Beacon costs to light.
func beacon_lenses() -> int:
	return Operations.BEACON_LENS * (beacons.size() + 1)


## Lenses an hour the Beacons burn.
func beacon_upkeep() -> float:
	return Operations.BEACON_UPKEEP * float(beacons.size())


## Lenses a sortie of this team to site `s` burns for light: none but in
## the dark, and none there once a Beacon burns in the Dark Reach.
func light_lenses(s: Dictionary, n: int, b: int, v: int) -> int:
	if not Operations.dark(s) or controlled("reach"):
		return 0
	return Operations.dark_lens(n, b, v)


## Why `n` Rigs, `b` Breakers and `v` Surveyors cannot light a Beacon in
## region `r` now, or "": "core", "closed" (not open), "lit" (one burns),
## "busy" (a team is out there), "surveyor" (none to keep it), "rigs",
## "lens", "fuel", "weak".
func beacon_blocker(r: String, n: int, b: int, v: int) -> String:
	if core_level < Operations.CONTROL_CORE or not Operations.REGIONS.has(r):
		return "core"
	if not region_open(r):
		return "closed"
	if beacons.has(r):
		return "lit"
	if site_busy(Operations.region_slot(r)):
		return "busy"
	if v < 1:
		return "surveyor"
	if n < 0 or b < 0 or n > rigs_home() or b > breakers or v > surveyors:
		return "rigs"
	var s: Dictionary = beacon_site(r)
	if stock_of(MachineDB.Res.LENS) < beacon_lenses() + light_lenses(s, n, b, v):
		return "lens"
	if stock_of(Operations.fuel_res(core_level)) < expedition_fuel(n, b, v):
		return "fuel"
	if team_strength(s, n, b, v) < float(s["need"]):
		return "weak"
	return ""


## Send a team to light a Beacon in region `r`: when it is home, the region
## is held and one Surveyor stays to keep the lamp.
func send_beacon(r: String, n: int, b: int, v: int) -> bool:
	if beacon_blocker(r, n, b, v) != "":
		return false
	_spend_lens(beacon_lenses(), "beacon")
	var fuel_extra: int = expedition_fuel(n, b, v) - Operations.fuel(n, core_level, b, v)
	_take_stock({Operations.fuel_res(core_level): fuel_extra})
	return _send(Operations.region_slot(r), beacon_site(r), n, b, v)


## The fewest that light a Beacon in region `r`, with a Surveyor, or
## everyone at home.
func beacon_team(r: String) -> Vector3i:
	var s: Dictionary = beacon_site(r)
	for size in range(1, rigs_home() + breakers + surveyors + 1):
		for t: Vector3i in _splits(s, size):
			if t.z >= 1 and team_strength(s, t.x, t.y, t.z) >= float(s["need"]):
				return t
	return Vector3i(rigs_home(), breakers, surveyors)


func _light_beacon(r: String) -> void:
	if beacons.has(r) or not region_open(r):
		return
	beacons.append(r)
	# The keeper stays with the lamp.
	surveyors = maxi(surveyors - 1, 0)
	_recompute()
	beacon_lit.emit(r)


## Put out the Beacon in region `r`: its keeper comes home, and what the
## region gave while held stops.
func douse_beacon(r: String) -> bool:
	if not beacons.has(r):
		return false
	beacons.erase(r)
	surveyors += 1
	if beacons.is_empty():
		beacons_dark = false
		_upkeep_due = 0.0
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	return true


## The Beacons' Lenses, as the factory runs: `dt` seconds of them from the
## store; when the store has none, they go dark until it has.
func _upkeep(dt: float) -> void:
	if beacons.is_empty():
		return
	if not beacons_dark:
		_upkeep_due += beacon_upkeep() / 3600.0 * dt
	var owed: int = int(ceil(_upkeep_due)) if beacons_dark else int(_upkeep_due)
	if owed <= 0:
		return
	if stock_of(MachineDB.Res.LENS) >= owed:
		_spend_lens(owed, "upkeep")
		_upkeep_due -= float(owed)
		if beacons_dark:
			beacons_dark = false
			_recompute()
			beacons_dimmed.emit(false)
	elif not beacons_dark:
		beacons_dark = true
		_recompute()
		beacons_dimmed.emit(true)


func _spend_lens(n: int, why: String) -> void:
	_take_stock({MachineDB.Res.LENS: n})
	lens_spent[why] = int(lens_spent.get(why, 0)) + n


## Why a Surveyor at the Bay cannot tune machine `cell` now, or "":
## "machine" (nothing there), "job" (not a job a Surveyor tunes), "tuned"
## (one does), "surveyors" (none at the Bay).
func tune_blocker(cell: int) -> String:
	if grid.is_empty(cell):
		return "machine"
	if not MachineDB.job_info(grid.machine_at(cell), grid.job_at(cell)).has("tuned"):
		return "job"
	if tuners.has(cell):
		return "tuned"
	if surveyors <= 0:
		return "surveyors"
	return ""


## A Surveyor from the Bay tunes machine `cell`: it takes what its job's
## "tuned" recipe says -- half the Resonite a Lens, half the Lenses a Prism
## -- for as long as the Surveyor stays.
func tune(cell: int) -> bool:
	if tune_blocker(cell) != "":
		return false
	surveyors -= 1
	tuners[cell] = true
	_sync_tuners()
	_sync_core()
	stats_changed.emit()
	Save.save_game(self)
	return true


func untune(cell: int) -> bool:
	if not tuners.has(cell):
		return false
	tuners.erase(cell)
	surveyors += 1
	_sync_tuners()
	_sync_core()
	stats_changed.emit()
	return true


## The simulation's view of the Surveyors and the Beacons: each tuned
## machine's recipe, and the jobs no Beacon keeps running. A tuner whose
## machine is gone, or no longer on a job it tunes, comes home.
func _sync_tuners() -> void:
	if sim == null:
		return
	var ins: Dictionary = {}
	for cell: int in tuners.keys():
		var info: Dictionary = {} if grid.is_empty(cell) else MachineDB.job_info(grid.machine_at(cell), grid.job_at(cell))
		if not info.has("tuned"):
			tuners.erase(cell)
			surveyors += 1
			continue
		ins[cell] = info["tuned"]
	var off: Dictionary = {}
	for id: String in MachineDB.JOBS:
		for job: String in (MachineDB.JOBS[id] as Dictionary):
			var c: String = String((MachineDB.JOBS[id][job] as Dictionary).get("control", ""))
			if c != "" and not controlled(c):
				off[job] = true
	if ins != sim.cell_inputs or off != sim.jobs_off:
		sim.cell_inputs = ins
		sim.jobs_off = off
		sim.job_stamp += 1


## --- posts: Rigs at work in the factory (Operations, "Posts") -------------------

## The machines Rigs are posted to: cell -> the part of a unit hauled so far.
var posts: Dictionary = {}
## The Rig Bay's level, and every unit posted Rigs have hauled in all.
var bay_level: int = 1
var hauled: int = 0
## Salvage the galleries have paid in all (the unspent is `salvage`).
var salvage_earned: int = 0


func rigs_posted() -> int:
	return posts.size()


func bay_posts() -> int:
	return Operations.bay_posts(bay_level)


func haul_rate() -> float:
	return Operations.haul_rate(bay_level)


## What machine `cell` would be hauled, from the store: the inputs it takes
## that the store keeps -- for a Lab, which learns from any one of them, the
## one it learns most from that the store holds.
## What a posted Rig leaves of `res` in the store: what the Core's next
## level asks the store for. The crew feeds the machines from what is over
## (measured: two posted Rigs carried every Ingot to the Presses beside the
## Core, and the Core 6 row's 8,000 Ingots stood at 0 for three hours).
##
## A row the store cannot hold yet (the Vault's level comes first) leaves
## the top HAUL_TOP of a full store to the crew: the Core takes nothing more
## until the Vault grows, so the machines beside it may have it (measured:
## with the Frame row at 300,000 and a Vault 9 holding 274,878, no Rig could
## feed an Assay Bench, and the Core 10 row of four Benches stood at one).
func haul_floor(res: int) -> int:
	var keep: int = 0
	for r: Array in CoreLevels.requirements(core_level + 1):
		if int(r[0]) == CoreLevels.Req.STOCK and int(r[1]) == res:
			keep = maxi(keep, int(r[2]))
	if keep > stock_cap():
		keep = int(float(stock_cap()) * (1.0 - HAUL_TOP))
	return keep


const HAUL_TOP := 0.05


## What the crew may haul of `res`: the store's, over its floor.
func haulable(res: int) -> int:
	return maxi(stock_of(res) - haul_floor(res), 0)


func haul_inputs(cell: int) -> Array[int]:
	var out: Array[int] = []
	if grid.is_empty(cell):
		return out
	var m: Dictionary = sim.machine_of(cell)
	var ins: Dictionary = m.get("inputs", {})
	if (m.get("tags", []) as Array).has("research") and ins.size() > 1:
		var best: int = -1
		var learns: Dictionary = m.get("learns", {})
		for res: int in ins:
			if MachineDB.STOCKED.has(res) and haulable(res) > 0 \
					and (best < 0 or float(learns.get(res, 0.0)) > float(learns.get(best, 0.0))):
				best = res
		if best >= 0:
			out.append(best)
		return out
	for res: int in ins:
		if MachineDB.STOCKED.has(res):
			out.append(res)
	return out


## Why a Rig cannot be posted to `cell` now, or "": "machine" (nothing
## there), "side" (it does not touch the Core), "inputs" (it takes nothing
## the store keeps), "posted" (one is already there), "rigs" (none at the
## Bay), "bay" (every dock of the Bay in use).
func post_blocker(cell: int) -> String:
	if grid.is_empty(cell):
		return "machine"
	if not sim.core_touching().has(cell):
		return "side"
	var ins: Dictionary = sim.machine_of(cell).get("inputs", {})
	var takes: bool = false
	for res: int in ins:
		takes = takes or MachineDB.STOCKED.has(res)
	if not takes:
		return "inputs"
	if posts.has(cell):
		return "posted"
	if rigs_home() <= 0:
		return "rigs"
	if posts.size() >= bay_posts():
		return "bay"
	return ""


func can_post(cell: int) -> bool:
	return post_blocker(cell) == ""


## Post a Rig from the Bay to machine `cell`.
func post_rig(cell: int) -> bool:
	if not can_post(cell):
		return false
	stock[MachineDB.Res.RIG] = rigs_home() - 1
	posts[cell] = 0.0
	_sync_core()
	stats_changed.emit()
	Save.save_game(self)
	return true


## Bring the Rig posted to `cell` back to the Bay.
func recall_rig(cell: int) -> bool:
	if not posts.has(cell):
		return false
	posts.erase(cell)
	stock[MachineDB.Res.RIG] = rigs_home() + 1
	_sync_core()
	stats_changed.emit()
	return true


## One tick of the posted Rigs' hauling: each moves up to haul_rate() units
## a second from the store into its machine's input buffer, taking turns
## between what the machine takes. A machine sold, moved or no longer
## beside the Core sends its Rig home.
func _haul(dt: float) -> void:
	if posts.is_empty():
		return
	var limit: int = sim.cap()
	var rate: float = haul_rate()
	var floors: Dictionary = {}
	for res: int in MachineDB.STOCKED:
		floors[int(res)] = haul_floor(int(res))
	for cell: int in posts.keys():
		if grid.is_empty(cell) or not sim.core_touching().has(cell):
			recall_rig(cell)
			continue
		var budget: float = float(posts[cell]) + rate * dt
		var ins: Array[int] = haul_inputs(cell)
		var buf: Dictionary = grid.cells[cell]["buf_in"]
		var moved: bool = true
		while budget >= 1.0 and moved:
			moved = false
			for res: int in ins:
				if budget < 1.0:
					break
				if stock_of(res) <= int(floors.get(res, 0)) or int(buf.get(res, 0)) >= limit:
					continue
				buf[res] = int(buf.get(res, 0)) + 1
				stock[res] = stock_of(res) - 1
				budget -= 1.0
				hauled += 1
				if res == MachineDB.Res.LENS:
					lens_spent["factory"] = int(lens_spent.get("factory", 0)) + 1
				moved = true
		# Nothing to haul now: the Rig waits, and does not bank the time.
		posts[cell] = minf(budget, 1.0)
	_sync_core()


## What `n` Rigs at home bring to a sortie: whole, their Rig Plating, less
## their wear.
func crew_strength(n: int) -> float:
	return float(n) * Operations.RIG_POWER * float(_mult.get("rig_power", 1.0)) * (1.0 - rig_wear)


## What `n` Rigs, `b` Breakers and `v` Surveyors bring to site `s`
## (Operations.team_factor).
func team_strength(s: Dictionary, n: int, b: int, v: int = 0) -> float:
	return crew_strength(1) * Operations.team_factor(s, n, b, v, float(_mult.get("breaker_power", 1.0)))


func site(i: int) -> Dictionary:
	return ops_board[i] if i >= 0 and i < ops_board.size() else {}


## What clearing site `i` pays, at the factory's measured income now.
func site_reward(i: int) -> Dictionary:
	var r: Dictionary = Operations.reward(site(i), offline_rate())
	var reg: String = String(site(i).get("region", ""))
	if reg != "" and controlled(reg):
		for k: String in ["credits", "research"]:
			r[k] = float(r[k]) * Operations.CONTROL_PAY
		r["n"] = int(ceil(float(r["n"]) * Operations.CONTROL_PAY))
	return r


func site_busy(i: int) -> bool:
	for s: Dictionary in sorties:
		if int(s["slot"]) == i:
			return true
	return false


## Why `n` Rigs cannot go to site `i` now, or "" when they can: "core" (no
## gallery is open yet), "site" (nothing dealt there), "busy" (a sortie is
## already out to it), "rigs" (not that many at home), "fuel" (not the
## Ingots).
func sortie_blocker(i: int, n: int, b: int = 0, v: int = 0) -> String:
	if Operations.slots(core_level) == 0:
		return "core"
	if not site(i).has("kind"):
		return "site"
	if site_busy(i):
		return "busy"
	if n < 0 or b < 0 or v < 0 or n + b + v < 1 or n > rigs_home() or b > breakers or v > surveyors:
		return "rigs"
	if stock_of(Operations.fuel_res(core_level)) < Operations.fuel(n, core_level, b, v):
		return "fuel"
	if stock_of(MachineDB.Res.LENS) < light_lenses(site(i), n, b, v):
		return "light"
	return ""


func can_send(i: int, n: int, b: int = 0, v: int = 0) -> bool:
	return sortie_blocker(i, n, b, v) == ""


## The team a sortie to site `i` takes by default, as (Rigs, Breakers,
## Surveyors): the fewest that clear what is left of it -- Breakers first
## on rock, a Breaker leading into danger, Rigs first elsewhere, Surveyors
## last (they are weak and fragile) -- or everyone at home when no team does.
func sortie_team(i: int) -> Vector3i:
	var s: Dictionary = site(i)
	var all := Vector3i(rigs_home(), breakers, surveyors)
	if not s.has("kind"):
		return all
	for size in range(1, all.x + all.y + all.z + 1):
		for t: Vector3i in _splits(s, size):
			if team_strength(s, t.x, t.y, t.z) >= float(s["left"]):
				return t
	return all


## Every team of `size` from the crew at home, the site's preferred first.
func _splits(s: Dictionary, size: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for b in range(mini(size, breakers) + 1):
		for v in range(mini(size - b, surveyors) + 1):
			var n: int = size - b - v
			if n <= rigs_home():
				out.append(Vector3i(n, b, v))
	var rock: bool = Operations.armored(s)
	var wet: bool = Operations.watery(s)
	var danger: bool = Operations.dangerous(s)
	var survey: bool = String(s.get("kind", "")) == "survey"
	var dark: bool = Operations.dark(s)
	var hold: bool = Operations.holding(s)
	var key := func(t: Vector3i) -> float:
		var k: float = 0.0
		if survey:
			k -= 100.0 * float(t.z)
		# In the dark, a Surveyor to guide; on a Beacon's ground, Breakers.
		if dark and t.z >= 1:
			k -= 60.0
		if hold:
			k -= 20.0 * float(t.y)
		if danger and t.y >= 1:
			k -= 50.0
		if rock:
			k -= 10.0 * float(t.y)
		elif wet:
			k += 10.0 * float(t.y)
		# Surveyors last: weak, fragile.
		if not survey:
			k += 5.0 * float(t.z)
		return k
	out.sort_custom(func(a: Vector3i, c: Vector3i) -> bool: return float(key.call(a)) < float(key.call(c)))
	return out


## How many Rigs a sortie to site `i` takes by default: the fewest at home
## that clear what is left of it, or all at home when none do.
func sortie_size(i: int) -> int:
	var s: Dictionary = site(i)
	var home: int = rigs_home()
	if not s.has("kind"):
		return home
	for n in range(1, home + 1):
		if team_strength(s, n, 0) >= float(s["left"]):
			return n
	return home


## Send `n` Rigs to site `i`: they leave the Core with their fuel, and what
## they will do there is decided now (Operations.resolve).
func send_sortie(i: int, n: int, b: int = 0, v: int = 0) -> bool:
	if not can_send(i, n, b, v):
		return false
	return _send(i, site(i), n, b, v)


## A team out to site `s` in board slot `i`: what it will do there decided
## now, from who is in it.
func _send(i: int, s: Dictionary, n: int, b: int, v: int) -> bool:
	var out: Dictionary = Operations.resolve(s, team_strength(s, n, b, v))
	# The Breakers take the brunt; the Surveyors are fragile.
	out["wear"] = float(out["wear"]) * (1.0 - Operations.BREAKER_SHIELD * Operations.breaker_share(s, n, b, v)) \
		* (1.0 + Operations.SURVEYOR_FRAGILE * Operations.surveyor_share(s, n, b, v) * (2.0 if Operations.dangerous(s) else 1.0))
	# Danger: with no Breaker to lead it, the team brings home half.
	out["half"] = Operations.dangerous(s) and b == 0 and String(s.get("kind", "")) != "survey"
	# The Surveyors find more of the Resonite.
	out["find"] = minf(Operations.SURVEYOR_FIND * float(v), Operations.SURVEYOR_FIND_MAX)
	_take_stock({Operations.fuel_res(core_level): Operations.fuel(n, core_level, b, v), MachineDB.Res.RIG: n})
	# Light for the dark.
	var light: int = light_lenses(s, n, b, v)
	if light > 0:
		_spend_lens(light, "light")
	breakers -= b
	surveyors -= v
	var trip: float = Operations.trip(s)
	if n == 0 and b == 0 and v > 0 and String(s.get("kind", "")) != "survey":
		trip *= Operations.SURVEYOR_TRIP
	sorties.append({"slot": i, "n": n, "b": b, "v": v, "left": trip, "trip": trip, "site": s.duplicate(),
		"out": out, "wear": rig_wear})
	# Rigs out still count against the crew.
	_sync_core()
	sortie_sent.emit(i, n)
	stats_changed.emit()
	Save.save_game(self)
	return true


## Sorties come home as the factory runs: `dt` seconds of it.
func advance_ops(dt: float) -> void:
	if sorties.is_empty():
		return
	var back: Array = []
	for s: Dictionary in sorties:
		s["left"] = float(s["left"]) - dt
		if float(s["left"]) <= 0.0:
			back.append(s)
	for s: Dictionary in back:
		sorties.erase(s)
		_sortie_home(s)


## A sortie home: its Rigs back with the site's wear on them, its reward
## paid, and its site cleared and dealt again, or left the weaker.
func _sortie_home(s: Dictionary) -> void:
	var n: int = int(s["n"])
	var b: int = int(s.get("b", 0))
	var v: int = int(s.get("v", 0))
	var out: Dictionary = s["out"]
	var site_was: Dictionary = s["site"]
	var kind: String = String(site_was["kind"])
	var home: int = rigs_home() + breakers + surveyors
	var worn: float = minf(float(s["wear"]) + float(out["wear"]), Operations.WEAR_MAX)
	rig_wear = clampf((rig_wear * float(home) + worn * float(n + b + v)) / float(maxi(home + n + b + v, 1)),
		0.0, Operations.WEAR_MAX)
	stock[MachineDB.Res.RIG] = rigs_home() + n
	breakers += b
	surveyors += v
	var r: Dictionary = Operations.reward(site_was, offline_rate())
	var share: float = float(out["share"])
	# Danger: a team with no Breaker to lead it brought home half.
	var pay: float = share * (0.5 if bool(out.get("half", false)) else 1.0)
	# A held region's sites pay more.
	var reg: String = String(site_was.get("region", ""))
	if reg != "" and controlled(reg) and kind != "beacon":
		pay *= Operations.CONTROL_PAY
	var paid: float = float(r["credits"]) * pay
	credits += paid
	lifetime_credits += paid
	research += float(r["research"]) * pay
	var res: int = int(r["res"])
	var units: float = float(r["n"]) * pay
	if res == MachineDB.Res.RESONITE:
		# More with Surveyors, in the Caverns, and with the Lens research.
		units *= (1.0 + float(out.get("find", 0.0))) * float(_mult.get("resonite", 1.0)) \
			* (Operations.CAVERN_RESONITE if region_open("caverns") else 1.0)
	elif res == MachineDB.Res.UMBRITE:
		units *= (1.0 + float(out.get("find", 0.0))) * float(_mult.get("umbrite", 1.0))
	var got: int = int(floor(units))
	if MachineDB.STOCKED.has(res):
		stock[res] = mini(stock_of(res) + got, stock_cap())
	var slot: int = int(s["slot"])
	var salv: int = int(r["salvage"]) * (Operations.FOUNDRY_CONTROL if controlled("foundry")
		else (Operations.FOUNDRY_SALVAGE if region_open("foundry") else 1))
	if bool(out["cleared"]):
		salvage += salv
		salvage_earned += salv
		ops_cleared += 1
		ops_lifetime += 1
		if kind == "stranded":
			# A rescue: room for one more Rig, and the crew mended.
			rescued = mini(rescued + 1, Operations.RESCUE_MAX)
			rig_wear = 0.0
		if kind == "survey":
			_open_region(String(site_was.get("region", "")))
		elif kind == "beacon":
			_light_beacon(String(site_was.get("region", "")))
		elif slot < ops_board.size():
			ops_board[slot] = {}
		_deal_ops()
	elif kind != "survey" and kind != "beacon" and slot < ops_board.size() \
			and site(slot).get("serial", -1) == site_was.get("serial", -2):
		ops_board[slot]["left"] = float(out["left"])
	_sync_core()
	sortie_back.emit({"kind": kind, "cleared": bool(out["cleared"]),
		"credits": paid, "research": float(r["research"]) * pay, "res": res, "n": got,
		"wear": float(out["wear"]), "rigs": n, "breakers": b, "surveyors": v, "slot": slot,
		"trip": float(s.get("trip", 0.0)),
		"salvage": salv if bool(out["cleared"]) else 0, "region": String(site_was.get("region", ""))})
	stats_changed.emit()


## Plates that repair the Rigs at home.
func repair_cost() -> int:
	return int(ceil(float(Operations.repair_cost(rigs_home() + surveyors, rig_wear, core_level))
		+ float(Operations.repair_cost(breakers, rig_wear, core_level)) * Operations.BREAKER_REPAIR))


func can_repair() -> bool:
	var c: int = repair_cost()
	return c > 0 and stock_of(MachineDB.Res.PLATE) >= c


## Repair the Rigs at home with Plates from the store, at once.
func repair_rigs() -> bool:
	if not can_repair():
		return false
	_take_stock({MachineDB.Res.PLATE: repair_cost()})
	rig_wear = 0.0
	stats_changed.emit()
	Save.save_game(self)
	return true


## Deal a site into every empty slot the Core's level opens.
func _deal_ops() -> void:
	while ops_board.size() < Operations.slots(core_level):
		ops_board.append({})
	# The regions' own slots, after the galleries', once one is open.
	if not regions_open.is_empty():
		while ops_board.size() < Operations.SLOTS + Operations.REGION_ORDER.size():
			ops_board.append({})
	for i in range(ops_board.size()):
		if (ops_board[i] as Dictionary).has("kind"):
			continue
		var r: String = Operations.slot_region(i)
		if r != "" and not region_open(r):
			continue
		ops_board[i] = Operations.deal(core_level, depth + 100 * collapses, ops_serial) if r == "" \
			else Operations.deal_region(r, core_level, depth + 100 * collapses, ops_serial, controlled(r))
		ops_serial += 1


## The galleries' board, the crew's wear and its sorties, as a new shaft
## has them; the lifetime count stays.
func clear_ops() -> void:
	ops_board = []
	ops_serial = 0
	ops_cleared = 0
	sorties = []
	rig_wear = 0.0
	posts = {}
	bay_level = 1
	breakers = 0
	surveyors = 0
	regions_open = []
	rescued = 0
	beacons = []
	beacons_dark = false
	_upkeep_due = 0.0
	tuners = {}


## The Bay's next level: why it cannot be bought now, or "": "max" (the
## last), "core" (the Core's level caps it), "salvage", "credits".
func bay_blocker() -> String:
	if bay_level >= Operations.BAY_MAX:
		return "max"
	if bay_level >= Operations.bay_cap(core_level):
		return "core"
	var c: Dictionary = Operations.bay_cost(bay_level)
	if salvage < int(c["salvage"]):
		return "salvage"
	if credits < float(c["credits"]):
		return "credits"
	return ""


func upgrade_bay() -> bool:
	if bay_blocker() != "":
		return false
	var c: Dictionary = Operations.bay_cost(bay_level)
	credits -= float(c["credits"])
	salvage -= int(c["salvage"])
	bay_level += 1
	stats_changed.emit()
	Save.save_game(self)
	return true


## One tick's work after the factory's: the store takes what the Core was
## handed, and sorties walk on.
func after_tick(dt: float) -> void:
	_collect_stock()
	advance_ops(dt)
	_haul(dt)
	_upkeep(dt)


## --- machine levels ------------------------------------------------------------

func machine_level(id: String) -> int:
	return int(machine_levels.get(id, 1))


## The highest level machines may reach under the Core's level.
func machine_level_cap() -> int:
	return CoreLevels.machine_cap(core_level)


## What machine type `id`'s next level costs: {"credits", "materials"}.
func machine_upgrade_cost(id: String) -> Dictionary:
	var to: int = machine_level(id) + 1
	return {"credits": MachineDB.level_price(id, to), "materials": MachineDB.level_materials(to, id)}


## Why machine type `id` cannot go up a level now, or "" when it can:
## "none" (it has no levels), "locked", "core" (the Core's limit), "storage"
## (the store cannot hold the materials), "stock" (they are not in it),
## "credits".
func machine_upgrade_blocker(id: String) -> String:
	if not MachineDB.has_levels(id):
		return "none"
	if not is_unlocked(id):
		return "locked"
	if machine_level(id) >= machine_level_cap():
		return "core"
	var cost: Dictionary = machine_upgrade_cost(id)
	var mats: Dictionary = cost["materials"]
	for res: int in mats:
		if int(mats[res]) > stock_cap():
			return "storage"
	if not has_stock(mats):
		return "stock"
	if credits < float(cost["credits"]):
		return "credits"
	return ""


func can_upgrade_machine(id: String) -> bool:
	return machine_upgrade_blocker(id) == ""


func upgrade_machine(id: String) -> bool:
	if not can_upgrade_machine(id):
		return false
	var cost: Dictionary = machine_upgrade_cost(id)
	credits -= float(cost["credits"])
	_take_stock(cost["materials"])
	machine_levels[id] = machine_level(id) + 1
	_recompute()
	machine_upgraded.emit(id, machine_level(id))
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- Overdrive ------------------------------------------------------------------

func overdrive_steps(id: String) -> int:
	return int(overdrive.get(id, 0))


## The Overdrive steps a machine type may take under this shaft's Core.
func overdrive_cap() -> int:
	return CoreLevels.overdrive_cap(core_level)


## What machine type `id`'s next Overdrive step costs under this shaft's
## Core: {"materials", "research"}.
func overdrive_cost(id: String) -> Dictionary:
	return MachineDB.overdrive_cost(overdrive_steps(id) + 1, core_level)


## Why machine type `id` cannot take an Overdrive step now, or "" when it
## can: "none" (it cannot be driven), "locked", "core" (the Core's level has
## not opened it, or its steps are at the Core's limit), "level" (it has not
## reached the level the Core before allowed), "storage", "stock",
## "research".
func overdrive_blocker(id: String) -> String:
	if not MachineDB.can_overdrive(id):
		return "none"
	if not is_unlocked(id):
		return "locked"
	if overdrive_steps(id) >= overdrive_cap():
		return "core"
	if machine_level(id) < CoreLevels.overdrive_from(core_level):
		return "level"
	var cost: Dictionary = overdrive_cost(id)
	var mats: Dictionary = cost["materials"]
	for res: int in mats:
		if int(mats[res]) > stock_cap():
			return "storage"
	if not has_stock(mats):
		return "stock"
	if research < float(cost["research"]):
		return "research"
	return ""


func can_overdrive(id: String) -> bool:
	return overdrive_blocker(id) == ""


## Drive machine type `id` one step: its materials and research are paid.
func overdrive_machine(id: String) -> bool:
	if not can_overdrive(id):
		return false
	var cost: Dictionary = overdrive_cost(id)
	research -= float(cost["research"])
	_take_stock(cost["materials"])
	overdrive[id] = overdrive_steps(id) + 1
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	return true


func descend() -> bool:
	if not can_descend():
		return false
	credits -= quota()
	depth += 1
	max_depth = maxi(max_depth, depth)
	var before: Array[String] = unlocked.duplicate()
	_recompute()
	var gained: Array = []
	for id in unlocked:
		if not before.has(id):
			gained.append(id)
	_reset_rate_window(true)
	depth_changed.emit(depth)
	if not gained.is_empty():
		machines_unlocked.emit(gained)
	stats_changed.emit()
	Save.save_game(self)
	Analytics.track("depth_reached", {"depth": depth})
	return true


## --- collapse (prestige) ---------------------------------------------------

func pending_cores() -> int:
	return Economy.cores_for_collapse(max_depth, lifetime_credits,
		float(_mult.get("core_yield", 0.0)))


func can_collapse() -> bool:
	return Economy.can_collapse(max_depth) and pending_cores() > 0


func collapse() -> int:
	if not can_collapse():
		return 0
	var gained: int = pending_cores()
	cores += gained
	collapses += 1
	best_core = maxi(best_core, core_level)
	# What survives: Cores, the permanent tree, blueprints, settings.
	# What does not: the board, credits, research, depth. The loss is the point.
	grid.clear()
	sim.reset_progress()
	credits = 0.0
	research = 0.0
	lifetime_credits = 0.0
	depth = 0
	max_depth = 0
	# A new shaft's Core starts on its foundation -- part of the best level
	# any shaft has reached -- its machines at level 1, its store empty, and
	# it chooses its doctrine again.
	core_level = foundation()
	# A doctrine is the shaft's strategy: its research goes with it, and
	# the next shaft chooses -- and pays -- again.
	doctrine = ""
	for id: String in Economy.RESEARCH_TREE:
		if Economy.doctrine_of(id) != "" \
				or String((Economy.RESEARCH_TREE[id] as Dictionary).get("region", "")) != "":
			upgrade_levels.erase(id)
	blueprint_pending = []
	machine_levels = {}
	overdrive = {}
	stock = {}
	# A new shaft's board is dealt afresh; the lifetime count stays.
	contracts = []
	dispatch_serial = 0
	contracts_filled = 0
	# So is the galleries' board; the crew and its sorties go with the shaft,
	# and Rig Plating, as the whole tree, stays.
	clear_ops()
	# The next shaft's Core starts dark again, and its reserve is what the
	# empty board is rebuilt from.
	core_online = false
	_reset_rate_window(true)
	_measured_rate = 0.0
	_measured_research_rate = 0.0
	_recompute()
	collapsed.emit(gained)
	stats_changed.emit()
	Save.save_game(self)
	Analytics.track("collapse", {"cores": gained, "collapses": collapses})
	return gained


## The Core level a new shaft starts at: FOUNDATION_SHARE of the best any
## shaft has reached, rounded down, and never below 1. What a collapse keeps
## of the Core: a second shaft skips the levels its first one outgrew by
## far, and still has to earn every one it grew in its last stretch.
const FOUNDATION_SHARE := 0.5


func foundation() -> int:
	return maxi(1, int(floor(float(maxi(best_core, core_level)) * FOUNDATION_SHARE)))


## --- doctrines ----------------------------------------------------------------

## Can the shaft choose a doctrine now? Once, from the Core's level
## Economy.DOCTRINE_CORE.
func can_choose_doctrine() -> bool:
	return doctrine == "" and core_level >= Economy.DOCTRINE_CORE


func choose_doctrine(id: String) -> bool:
	if not can_choose_doctrine() or not Economy.DOCTRINES.has(id):
		return false
	doctrine = id
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	return true


## Levels bought in the lines of the doctrine this shaft follows.
func doctrine_levels() -> int:
	if doctrine == "":
		return 0
	var n: int = 0
	for id: String in Economy.DOCTRINES[doctrine]["lines"]:
		n += upgrade_level(id)
	return n


## --- research tree ---------------------------------------------------------

func upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))


func can_buy_upgrade(id: String) -> bool:
	var u: Dictionary = Economy.RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return false
	var lvl: int = upgrade_level(id)
	if lvl >= line_max(id) or lvl >= research_cap(id):
		return false
	# A doctrine's line only in a shaft that follows it.
	if Economy.doctrine_of(id) != "" and Economy.doctrine_of(id) != doctrine:
		return false
	# A region's line only once the region is open.
	var reg: String = String(u.get("region", ""))
	if reg != "" and not region_open(reg):
		return false
	var c: Dictionary = Economy.upgrade_cost(id, lvl)
	return research >= float(c["research"]) and cores >= int(c["cores"]) and salvage >= int(c["salvage"])


## How far research line `id` may go under this shaft's Core.
func research_cap(id: String) -> int:
	return Economy.research_cap(id, core_level, line_max(id) - int(Economy.RESEARCH_TREE.get(id, {}).get("max", 0)))


## The most levels line `id` has in this shaft: a held region's line goes
## Operations.CONTROL_LINE further.
func line_max(id: String) -> int:
	var u: Dictionary = Economy.RESEARCH_TREE.get(id, {})
	var reg: String = String(u.get("region", ""))
	return int(u.get("max", 0)) + (Operations.CONTROL_LINE if reg != "" and controlled(reg) else 0)


func buy_upgrade(id: String) -> bool:
	if not can_buy_upgrade(id):
		return false
	var lvl: int = upgrade_level(id)
	var c: Dictionary = Economy.upgrade_cost(id, lvl)
	research -= float(c["research"])
	cores -= int(c["cores"])
	salvage -= int(c["salvage"])
	upgrade_levels[id] = lvl + 1
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	Analytics.track("first_upgrade")
	return true


## --- derived state ---------------------------------------------------------

## Throw away the part-measured window.
##
## Called whenever the board changes, because the moment it does the number
## being accumulated stops describing anything. Without this the header kept
## averaging the OLD board into the new one for up to three seconds -- most
## visibly right after a collapse, where an empty board was measured showing
## the rate of the factory that had just been given up. A store screenshot of
## the six-machine starter board was captured reading 600 credits a second
## against an actual 2.4, which is how this was found.
func _reset_rate_window(and_display: bool = false) -> void:
	_rate_accum_credits = 0.0
	_rate_accum_research = 0.0
	_rate_elapsed = 0.0
	_board_changed_at = Time.get_ticks_msec() / 1000.0
	if and_display:
		credits_per_sec = 0.0
		research_per_sec = 0.0


func _recompute() -> void:
	if grid == null:
		grid = Grid.new()
		sim = Simulation.new(grid, 20260923)
	_stratum = Strata.describe(depth)
	_mult = Economy.multipliers(upgrade_levels, doctrine)
	# The Sunken Works' brine (Operations, "regions").
	if region_open("sunken"):
		_mult["cooling"] = float(_mult.get("cooling", 1.0)) \
			* (Operations.BRINE_CONTROL if controlled("sunken") else Operations.BRINE_COOLING)
	_sync_tuners()

	# One entry point, so a stratum field can never again be wired in the game
	# and forgotten in the five tools that measure it. `richness` is folded
	# into the yield there: without it, depth only ever made the board hotter
	# and the quota higher, which is the shape of a game nobody finishes.
	Strata.apply(sim, grid, _stratum, _mult)
	var lm: Dictionary = {}
	var hs: Dictionary = {}
	var types: Dictionary = machine_levels.duplicate()
	types.merge(overdrive)
	# A doctrine's Cryo Lines make every cooler cool harder.
	var cooling: float = float(_mult.get("cooling", 1.0))
	if cooling != 1.0:
		types.merge({"coolant": 1, "condenser": 1})
	for id: String in types:
		if MachineDB.level_is_speed(id):
			lm[id] = MachineDB.level_speed(machine_level(id), overdrive_steps(id))
		var f: float = MachineDB.heat_factor(id, machine_level(id), overdrive_steps(id))
		if MachineDB.is_heat_support(id) and (MachineDB.get_machine(id)["tags"] as Array).has("cool"):
			f *= cooling
		if not is_equal_approx(f, 1.0):
			hs[id] = f
	grid.set_heat_scale(hs)
	if lm != sim.level_mult:
		sim.level_mult = lm
		sim.levels_stamp += 1
	_sync_core()

	var newly: Array[String] = MachineDB.unlocked_at(max_depth)
	for id in newly:
		if not unlocked.has(id):
			unlocked.append(id)
	_deal_board()
	_deal_ops()
	_reset_rate_window()


func stratum() -> Dictionary:
	return _stratum


func mult() -> Dictionary:
	return _mult


## How upgraded the factory is, as 0..3 notches.
##
## An upgrade that only moves a number in a menu is an upgrade the player has
## to take on trust. This puts it on every machine on the board, so buying one
## visibly changes the thing it bought.
func upgrade_marks() -> int:
	var total: int = 0
	for id: String in upgrade_levels:
		total += int(upgrade_levels[id])
	if total <= 0:
		return 0
	if total <= 2:
		return 1
	if total <= 6:
		return 2
	return 3


func blueprint_slots() -> int:
	var base: int = int(float(_mult.get("blueprints", 1.0)))
	return base + Store.bonus_blueprint_slots()


## --- blueprints -------------------------------------------------------------------
##
## A blueprint is this board, saved: every machine where it stands, its mode
## and its job. Laid again -- in a later shaft, after a collapse -- it is
## checked against the ground it is laid on (`blueprint_report`: the
## machines not yet found, the tiles outside the yard or under rock, the
## tiles taken, the jobs not open yet, what would overheat or run cold on
## this stratum with all of it standing) and then put down machine by
## machine as credits allow, the rest waiting until the shaft has found,
## reached or earned what it needs (`fill_pending`). So a collapse costs a
## factory's machines, not the thought that went into laying them out.

func blueprint(slot: int) -> Dictionary:
	return blueprints[slot] if slot >= 0 and slot < blueprints.size() else {}


## Save the board into `slot`.
func save_blueprint(slot: int) -> bool:
	if slot < 0 or slot >= blueprint_slots() or grid.cells.is_empty():
		return false
	var cells: Array = []
	for cell: int in grid.cells:
		cells.append([cell, grid.machine_at(cell), grid.mode_at(cell), grid.job_at(cell)])
	cells.sort_custom(func(a: Array, b: Array) -> bool: return _lay_order(a) < _lay_order(b))
	while blueprints.size() <= slot:
		blueprints.append({})
	blueprints[slot] = {"cells": cells, "core": core_level, "depth": depth}
	Save.save_game(self)
	return true


## Saved in the order a line is laid from its end: sellers and Labs first,
## then the makers that hand them something, the diggers, and the supports
## last. `fill_pending` puts a machine down only once it has somewhere to
## hand what it makes (`_lay_ready`), so a blueprint laid on a new shaft
## starts earning with its first two machines -- a Vault, then a Drill
## beside it -- instead of spending the Core's reserve on a line with no
## end (measured: a Drill first, alone, and a shaft that never earned).
const LAY_GROUPS := [MachineDB.Group.SELL, MachineDB.Group.RESEARCH, MachineDB.Group.MAKE,
	MachineDB.Group.DIG, MachineDB.Group.COOL, MachineDB.Group.HEAT, MachineDB.Group.BOOST]


func _lay_order(e: Array) -> int:
	var id: String = String(e[1])
	return LAY_GROUPS.find(MachineDB.group_of(id)) * 10000 + int(e[0])


## Can blueprint entry `e` go down now and be of use: a seller or Lab beside
## something that makes; a maker or digger that has a taker beside it; a
## support beside a maker. (A seller with only a blueprint's maker beside it
## goes down with that maker, as a pair: `_lay_pair`.)
func _lay_ready(e: Array, _pending: Dictionary) -> bool:
	var cell: int = int(e[0])
	var id: String = String(e[1])
	var m: Dictionary = MachineDB.job_machine(id, String(e[3]))
	var tags: Array = m.get("tags", [])
	var outs: Dictionary = m.get("outputs", {})
	if tags.has("sink") or tags.has("research"):
		for n: int in grid.neighbours(cell):
			if not (sim.machine_of(n).get("outputs", {}) as Dictionary).is_empty():
				return true
		return false
	if outs.is_empty():
		for n: int in grid.neighbours(cell):
			if not (sim.machine_of(n).get("outputs", {}) as Dictionary).is_empty():
				return true
		return false
	for n: int in grid.bridged_machines(cell):
		var nm: Dictionary = sim.machine_of(n)
		if (nm.get("tags", []) as Array).has("sink"):
			return true
		for res: int in outs:
			if (nm.get("inputs", {}) as Dictionary).has(res):
				return true
	if sim.core_touching().has(cell):
		for res: int in outs:
			if int(sim.core_wants.get(res, 0)) > 0:
				return true
	return false


## Every machine of blueprint `slot` checked against this shaft as it
## stands: {"cells": [{"cell", "id", "mode", "job", "why"}], "why": {why:
## count}, "cost": credits for what can be placed now}. "why" is "" for a
## machine that can be placed now, else "placed" (it already stands there),
## "taken", "locked" (not found yet), "outside" (the yard), "blocked" (the
## rock), "job" (the job is not open yet), "hot" or "cold" (on this
## stratum, with the whole blueprint standing).
func blueprint_report(slot: int) -> Dictionary:
	return _report(blueprint(slot).get("cells", []))


func _report(entries: Array) -> Dictionary:
	# The board with the blueprint laid over it, on this stratum's rock.
	var g := Grid.new()
	g.from_dict(grid.to_dict())
	g.set_environment(grid.ambient_heat, grid.heat_spread)
	g.set_heat_scale(grid.heat_scale)
	for e: Array in entries:
		var cell: int = int(e[0])
		if g.is_empty(cell):
			g.place(cell, String(e[1]))
			g.set_mode(cell, int(e[2]))
			g.set_job(cell, String(e[3]))
	var out: Array = []
	var counts: Dictionary = {}
	var cost: float = 0.0
	var owned: Dictionary = {}
	for e: Array in entries:
		var cell: int = int(e[0])
		var id: String = String(e[1])
		var job: String = String(e[3])
		var why: String = ""
		if grid.machine_at(cell) == id:
			why = "placed"
		elif not grid.is_empty(cell):
			why = "taken"
		elif not is_unlocked(id):
			why = "locked"
		elif not is_open(cell):
			why = "outside"
		elif is_blocked(cell):
			why = "blocked"
		if why == "" or why == "placed":
			var m: Dictionary = MachineDB.job_machine(id, job)
			var heat: float = g.heat_at(cell)
			var tol: float = float(m["heat_tolerance"]) + sim.tolerance_bonus
			if not MachineDB.is_heat_support(id) and heat > tol:
				why = "hot"
			elif MachineDB.has_levels(id) and not MachineDB.is_heat_support(id) \
					and heat < float(m["heat_optimum"]) \
					and MachineDB.efficiency_of(m, heat, sim.tolerance_bonus) < CoreLevels.WORKING_HEAT:
				why = "cold"
			elif not job_open(id, job):
				why = "job"
		if why in ["", "hot", "cold", "job"] and grid.machine_at(cell) != id:
			cost += MachineDB.cost_for(id, grid.count_of(id) + int(owned.get(id, 0)))
			owned[id] = int(owned.get(id, 0)) + 1
		out.append({"cell": cell, "id": id, "mode": int(e[2]), "job": job, "why": why})
		counts[why] = int(counts.get(why, 0)) + 1
	return {"cells": out, "why": counts, "cost": cost}


## Lay blueprint `slot`: what it still needs placed waits in
## `blueprint_pending` and goes down as it can. The report is `blueprint_report`'s.
func lay_blueprint(slot: int) -> Dictionary:
	var bp: Dictionary = blueprint(slot)
	if bp.is_empty():
		return {}
	var rep: Dictionary = blueprint_report(slot)
	blueprint_pending = []
	for e: Array in bp["cells"]:
		var cell: int = int(e[0])
		if grid.machine_at(cell) == String(e[1]) and grid.mode_at(cell) == int(e[2]) \
				and grid.job_at(cell) == String(e[3]):
			continue
		blueprint_pending.append([cell, String(e[1]), int(e[2]), String(e[3])])
	blueprint_pending.sort_custom(func(a: Array, b: Array) -> bool: return _lay_order(a) < _lay_order(b))
	fill_pending()
	Save.save_game(self)
	return rep


## Put down what a blueprint being laid can have now, in its order: a
## machine where its tile is free, in the yard and found, while credits
## last; then its mode and its job once they are open. A tile another
## machine stands on waits for the player. Returns how many were placed.
func fill_pending() -> int:
	var placed: int = 0
	var changed: bool = false
	var left: Array = []
	var broke: bool = false
	var waiting: Dictionary = {}
	for e: Array in blueprint_pending:
		waiting[int(e[0])] = e
	for e: Array in blueprint_pending:
		var cell: int = int(e[0])
		var id: String = String(e[1])
		if grid.machine_at(cell) != id:
			# A machine laid for a job waits for the job: on its own recipe it
			# would stand where nothing feeds it.
			if broke or not grid.is_empty(cell) or not is_unlocked(id) or not is_open(cell) \
					or is_blocked(cell) or String(e[3]) != "" and not job_open(id, String(e[3])):
				left.append(e)
				continue
			if not _lay_ready(e, waiting):
				# A seller whose maker is still to come: the two go down
				# together, or neither does.
				var partner: Array = _lay_pair(e, waiting)
				if partner.is_empty() or credits < cost_of(id) + cost_of(String(partner[1])):
					left.append(e)
					continue
				if try_place(cell, id):
					placed += 1
					waiting.erase(cell)
					var pc: int = int(partner[0])
					if try_place(pc, String(partner[1])):
						placed += 1
						waiting.erase(pc)
						if String(partner[3]) != "" and can_set_job(pc, String(partner[3])):
							changed = grid.set_job(pc, String(partner[3])) or changed
				else:
					left.append(e)
					continue
			elif credits < cost_of(id):
				# In order: the credits go to this one next.
				broke = true
				left.append(e)
				continue
			elif not try_place(cell, id):
				left.append(e)
				continue
			else:
				placed += 1
				waiting.erase(cell)
		# Its mode and its job, set on the board and worked out once below.
		if int(e[2]) != grid.mode_at(cell) and can_set_mode(cell, int(e[2])):
			changed = grid.set_mode(cell, int(e[2])) or changed
		if String(e[3]) != grid.job_at(cell) and can_set_job(cell, String(e[3])):
			changed = grid.set_job(cell, String(e[3])) or changed
		# Waiting for the Core's level that opens modes, or for its job.
		if grid.mode_at(cell) != int(e[2]) and core_level < MachineDB.MODES_CORE \
				or grid.job_at(cell) != String(e[3]):
			left.append(e)
	blueprint_pending = left
	if changed:
		sim.reset_progress()
		_recompute()
		stats_changed.emit()
	if placed > 0 or changed:
		Save.save_game(self)
	return placed


## For a seller or Lab entry `e` with nothing making beside it yet: a
## waiting blueprint entry beside it that would hand it something, and can go
## down now (found, in the yard, its tile free). [] when none.
func _lay_pair(e: Array, waiting: Dictionary) -> Array:
	var m: Dictionary = MachineDB.job_machine(String(e[1]), String(e[3]))
	if not ((m.get("tags", []) as Array).has("sink") or (m.get("tags", []) as Array).has("research")):
		return []
	var learns: Dictionary = m.get("learns", {})
	var best: Array = []
	for n: int in grid.neighbours(int(e[0])):
		if not waiting.has(n):
			continue
		var pe: Array = waiting[n]
		var pid: String = String(pe[1])
		if not grid.is_empty(n) or not is_unlocked(pid) or not is_open(n) or is_blocked(n):
			continue
		var outs: Dictionary = MachineDB.job_machine(pid, String(pe[3])).get("outputs", {})
		for res: int in outs:
			if ((m.get("tags", []) as Array).has("sink") or learns.has(res)) \
					and (best.is_empty() or cost_of(pid) < cost_of(String(best[1]))):
				best = pe
	return best


func cancel_blueprint() -> void:
	blueprint_pending = []
	Save.save_game(self)


## The credits per second a save banks offline income at: the rate on
## screen, or, in the seconds after a Descend before the new stratum's first
## measurement, the last one measured on this same board.
func offline_rate() -> float:
	return credits_per_sec if credits_per_sec > 0.0 else _measured_rate


func offline_hours() -> float:
	return float(_mult.get("offline_hours", Economy.OFFLINE_BASE_HOURS)) \
		+ Store.bonus_offline_hours()


## How much simulated time the number on the header is currently averaging
## over, and how long ago the board it describes last changed. The device
## self test compares them: the window can never be older than the board.
func rate_window_age() -> float:
	return _rate_elapsed


func seconds_since_board_change() -> float:
	return Time.get_ticks_msec() / 1000.0 - _board_changed_at


## --- undo ------------------------------------------------------------------
##
## A 7x10 grid on a phone puts a 48dp target under a thumb, and the two
## actions that cost something -- placing and selling -- are one tap and one
## hold away from each other. Removing is already behind a confirmation;
## placing cannot be, because placing is the entire game and a dialog every
## time would make it unbearable. So placing is instantly reversible instead,
## at exactly the price that was paid rather than at the 75% resale value.

func undo_place(cell: int, price: float) -> bool:
	if grid.is_empty(cell):
		return false
	grid.remove(cell)
	credits += price
	sim.forget([cell])
	_recompute()
	stats_changed.emit()
	return true


func undo_sell(cell: int, id: String, refunded: float) -> bool:
	if not grid.is_empty(cell) or not is_unlocked(id):
		return false
	if not grid.place(cell, id):
		return false
	credits -= refunded
	sim.forget([cell])
	_recompute()
	stats_changed.emit()
	return true


## --- tutorial --------------------------------------------------------------

func tutorial_step() -> int:
	return _tutorial_step


func advance_tutorial() -> void:
	_tutorial_step += 1
	if tutorial_done():
		Analytics.track("tutorial_complete", {"depth": depth})
	Save.save_game(self)


## The step the player is on, and whether they have already done it. Called
## every time the board changes, so it has to be cheap -- it is, because every
## check is a scan of the placed machines and there are at most seventy.
func tutorial_satisfied() -> bool:
	return Tutorial.satisfied(_tutorial_step, self)


func tutorial_done() -> bool:
	return Tutorial.is_done(_tutorial_step)


## --- persistence -----------------------------------------------------------

func to_dict() -> Dictionary:
	# Serialising before anything has constructed the board is legitimate --
	# the self test does it, and so does a save triggered by an early
	# background notification. Build on demand rather than dereferencing null.
	_ensure()
	return {
		"v": Save.VERSION,
		"credits": credits,
		"research": research,
		"cores": cores,
		"salvage": salvage,
		"depth": depth,
		"max_depth": max_depth,
		"lifetime_credits": lifetime_credits,
		"collapses": collapses,
		"core_level": core_level,
		"machine_levels": machine_levels,
		"overdrive": overdrive,
		"stock": stock,
		"contracts": contracts,
		"dispatch_serial": dispatch_serial,
		"contracts_filled": contracts_filled,
		"contracts_lifetime": contracts_lifetime,
		"ops_board": ops_board,
		"ops_serial": ops_serial,
		"ops_cleared": ops_cleared,
		"ops_lifetime": ops_lifetime,
		"sorties": sorties,
		"rig_wear": rig_wear,
		"breakers": breakers,
		"surveyors": surveyors,
		"regions_open": regions_open,
		"rescued": rescued,
		"beacons": beacons,
		"beacons_dark": beacons_dark,
		"upkeep_due": _upkeep_due,
		"tuners": tuners.keys(),
		"lens_spent": lens_spent,
		"posts": posts.keys(),
		"bay_level": bay_level,
		"hauled": hauled,
		"salvage_earned": salvage_earned,
		"upgrades": upgrade_levels,
		"blueprints": blueprints,
		"blueprint_pending": blueprint_pending,
		"doctrine": doctrine,
		"best_core": best_core,
		"grid": grid.to_dict(),
		"settings": settings,
		"tutorial": _tutorial_step,
		"tutorial_moves": tutorial_moves,
		"tutorial_saw_heat": tutorial_saw_heat,
		"core_online": core_online,
		"rate": offline_rate(),
		"research_rate": research_per_sec if research_per_sec > 0.0 else _measured_research_rate,
		"saved_at": Time.get_unix_time_from_system(),
	}


func from_dict(d: Dictionary) -> void:
	credits = float(d.get("credits", 0.0))
	research = float(d.get("research", 0.0))
	cores = int(d.get("cores", 0))
	salvage = int(d.get("salvage", 0))
	depth = int(d.get("depth", 0))
	max_depth = maxi(int(d.get("max_depth", 0)), depth)
	lifetime_credits = float(d.get("lifetime_credits", 0.0))
	collapses = int(d.get("collapses", 0))
	# A save from before the Core had levels keeps every stratum it reached:
	# its Core starts at the lowest level whose limit covers them.
	core_level = maxi(int(d.get("core_level", CoreLevels.level_for_depth(
		maxi(int(d.get("max_depth", 0)), int(d.get("depth", 0)))))), 1)
	machine_levels = {}
	for id in (d.get("machine_levels", {}) as Dictionary):
		machine_levels[String(id)] = int(d["machine_levels"][id])
	# Overdrive; a save from before it has none.
	overdrive = {}
	for id in (d.get("overdrive", {}) as Dictionary):
		if MachineDB.can_overdrive(String(id)) and int(d["overdrive"][id]) > 0:
			overdrive[String(id)] = int(d["overdrive"][id])
	# The store; a save from the first round of Core levels kept what the
	# Core had taken in towards its next level under "core_intake".
	stock = {}
	var kept: Dictionary = d.get("stock", d.get("core_intake", {}))
	var cap: int = MachineDB.stock_cap(int(machine_levels.get("vault", 1)))
	for res in kept:
		if MachineDB.STOCKED.has(int(res)):
			stock[int(res)] = mini(int(kept[res]), cap)
		elif int(res) == MachineDB.Res.RIG:
			stock[int(res)] = maxi(int(kept[res]), 0)
	# The Dispatch board; JSON brings every number back as a float.
	contracts = []
	for c in (d.get("contracts", []) as Array):
		var e: Dictionary = c
		if e.has("rest"):
			contracts.append({"rest": int(e["rest"])})
		elif e.has("res"):
			contracts.append({"res": int(e["res"]), "n": int(e["n"]), "pays": String(e["pays"]),
				"serial": int(e["serial"])})
		else:
			contracts.append({})
	dispatch_serial = int(d.get("dispatch_serial", 0))
	contracts_filled = int(d.get("contracts_filled", 0))
	contracts_lifetime = int(d.get("contracts_lifetime", 0))
	# The galleries; a save from before them has none. JSON brings every
	# number back as a float.
	ops_board = []
	for e in (d.get("ops_board", []) as Array):
		ops_board.append(_site_from(e))
	ops_serial = int(d.get("ops_serial", 0))
	ops_cleared = int(d.get("ops_cleared", 0))
	ops_lifetime = int(d.get("ops_lifetime", 0))
	rig_wear = clampf(float(d.get("rig_wear", 0.0)), 0.0, Operations.WEAR_MAX)
	breakers = maxi(int(d.get("breakers", 0)), 0)
	surveyors = maxi(int(d.get("surveyors", 0)), 0)
	rescued = clampi(int(d.get("rescued", 0)), 0, Operations.RESCUE_MAX)
	regions_open = []
	for r in (d.get("regions_open", []) as Array):
		if Operations.REGIONS.has(String(r)) and not regions_open.has(String(r)):
			regions_open.append(String(r))
	# Beacons only in open regions; a save from before them has none.
	beacons = []
	for r in (d.get("beacons", []) as Array):
		if regions_open.has(String(r)) and not beacons.has(String(r)):
			beacons.append(String(r))
	beacons_dark = bool(d.get("beacons_dark", false)) and not beacons.is_empty()
	_upkeep_due = maxf(float(d.get("upkeep_due", 0.0)), 0.0)
	tuners = {}
	for c in (d.get("tuners", []) as Array):
		tuners[int(c)] = true
	lens_spent = {}
	var ls: Variant = d.get("lens_spent", {})
	if typeof(ls) == TYPE_DICTIONARY:
		for k in (ls as Dictionary):
			lens_spent[String(k)] = int((ls as Dictionary)[k])
	bay_level = clampi(int(d.get("bay_level", 1)), 1, Operations.BAY_MAX)
	hauled = int(d.get("hauled", 0))
	salvage_earned = int(d.get("salvage_earned", 0))
	posts = {}
	for c in (d.get("posts", []) as Array):
		posts[int(c)] = 0.0
	var away: Array = d.get("sorties", [])
	sorties = []
	upgrade_levels = d.get("upgrades", {})
	# Blueprints; JSON brings every number back as a float.
	blueprints = []
	for b in (d.get("blueprints", []) as Array):
		var bd: Dictionary = b if typeof(b) == TYPE_DICTIONARY else {}
		blueprints.append({} if not bd.has("cells") else {"cells": _entries(bd["cells"]),
			"core": int(bd.get("core", 1)), "depth": int(bd.get("depth", 0))})
	blueprint_pending = _entries(d.get("blueprint_pending", []))
	doctrine = String(d.get("doctrine", ""))
	if not Economy.DOCTRINES.has(doctrine):
		doctrine = ""
	best_core = maxi(int(d.get("best_core", 1)), core_level)
	settings = d.get("settings", {"sound": true, "haptics": true})
	_tutorial_step = int(d.get("tutorial", 0))
	tutorial_moves = int(d.get("tutorial_moves", 0))
	tutorial_saw_heat = bool(d.get("tutorial_saw_heat", false))
	credits_per_sec = float(d.get("rate", 0.0))
	_measured_rate = credits_per_sec
	research_per_sec = float(d.get("research_rate", 0.0))
	_measured_research_rate = research_per_sec
	grid.from_dict(d.get("grid", {}))
	# A save from before the Core had to be brought online: a shaft with
	# anything on its board, or the price of a first Drill in the purse, is
	# running; one with neither is the dead end this replaced, so its Core
	# starts dark and pays out its reserve.
	var stuck: bool = grid.cells.is_empty() and credits < MachineDB.cost_for("drill", 0)
	core_online = bool(d.get("core_online", not stuck))
	sim.reset_progress()
	_recompute()
	# Sorties out when the game was closed came home while it was: each is
	# walked the rest of its way now.
	for e in away:
		var sd: Dictionary = e if typeof(e) == TYPE_DICTIONARY else {}
		if not sd.has("out") or not sd.has("site"):
			continue
		var o: Dictionary = sd["out"]
		_sortie_home({"slot": int(sd.get("slot", 0)), "n": int(sd.get("n", 0)), "b": int(sd.get("b", 0)),
			"v": int(sd.get("v", 0)), "left": 0.0,
			"trip": float(sd.get("trip", 0.0)), "site": _site_from(sd["site"]),
			"out": {"cleared": bool(o.get("cleared", false)), "share": float(o.get("share", 0.0)),
				"wear": float(o.get("wear", 0.0)), "left": float(o.get("left", 0.0)),
				"half": bool(o.get("half", false)), "find": float(o.get("find", 0.0))},
			"wear": float(sd.get("wear", 0.0))})


## A site as saved, its numbers made whole again ({} for none).
func _site_from(raw: Variant) -> Dictionary:
	var e: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	if not Operations.KINDS.has(String(e.get("kind", ""))):
		return {}
	return {"kind": String(e["kind"]), "tier": clampi(int(e.get("tier", 0)), 0, Operations.TIERS.size() - 1),
		"need": float(e.get("need", 1.0)), "left": float(e.get("left", e.get("need", 1.0))),
		"hazard": float(e.get("hazard", 0.1)), "serial": int(e.get("serial", 0)),
		"core": int(e.get("core", core_level)), "depth": int(e.get("depth", 0)),
		"armor": bool(e.get("armor", false)), "region": String(e.get("region", "")),
		"terrain": String(e.get("terrain", ""))}


## Blueprint entries as saved: [[cell, id, mode, job], ...], the numbers
## made whole again and anything not a machine left out.
func _entries(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for e in (raw as Array):
		if typeof(e) != TYPE_ARRAY or (e as Array).size() < 2 or not MachineDB.exists(String(e[1])):
			continue
		var a: Array = e
		out.append([int(a[0]), String(a[1]), int(a[2]) if a.size() > 2 else 0,
			String(a[3]) if a.size() > 3 else ""])
	return out
