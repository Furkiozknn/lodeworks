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
var blueprints: Array = []
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
		_collect_stock()
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
	sim.reset_progress()
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
	sim.reset_progress()
	_recompute()
	stats_changed.emit()
	return true


func move_machine(from_cell: int, to_cell: int) -> bool:
	if is_blocked(to_cell) or not is_open(to_cell):
		return false
	if not grid.move(from_cell, to_cell):
		return false
	sim.reset_progress()
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
	stats_changed.emit()
	Save.save_game(self)
	return true


## --- descent ---------------------------------------------------------------

func quota() -> float:
	return float(_stratum.get("quota", Strata.quota_for(depth)))


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
				_take_stock({int(r[1]): int(r[2])})
	core_level += 1
	_sync_core()
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
		stock[res] = mini(stock_of(res) + int(sim.core_took[res]), cap)
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
	sim.core_wants = room


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
	sim.reset_progress()
	_recompute()
	stats_changed.emit()
	Save.save_game(self)
	return true


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
			unlocked, stock_cap())
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


## What machine type `id`'s next Overdrive step costs: {"materials", "research"}.
func overdrive_cost(id: String) -> Dictionary:
	return MachineDB.overdrive_cost(overdrive_steps(id) + 1)


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
	# What survives: Cores, the permanent tree, blueprints, settings.
	# What does not: the board, credits, research, depth. The loss is the point.
	grid.clear()
	sim.reset_progress()
	credits = 0.0
	research = 0.0
	lifetime_credits = 0.0
	depth = 0
	max_depth = 0
	# A new shaft's Core starts at level 1, its machines at level 1, its
	# store empty.
	core_level = 1
	machine_levels = {}
	overdrive = {}
	stock = {}
	# A new shaft's board is dealt afresh; the lifetime count stays.
	contracts = []
	dispatch_serial = 0
	contracts_filled = 0
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


## --- research tree ---------------------------------------------------------

func upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))


func can_buy_upgrade(id: String) -> bool:
	var u: Dictionary = Economy.RESEARCH_TREE.get(id, {})
	if u.is_empty():
		return false
	var lvl: int = upgrade_level(id)
	if lvl >= int(u["max"]) or lvl >= research_cap(id):
		return false
	var c: Dictionary = Economy.upgrade_cost(id, lvl)
	return research >= float(c["research"]) and cores >= int(c["cores"])


## How far research line `id` may go under this shaft's Core.
func research_cap(id: String) -> int:
	return Economy.research_cap(id, core_level)


func buy_upgrade(id: String) -> bool:
	if not can_buy_upgrade(id):
		return false
	var lvl: int = upgrade_level(id)
	var c: Dictionary = Economy.upgrade_cost(id, lvl)
	research -= float(c["research"])
	cores -= int(c["cores"])
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
	_mult = Economy.multipliers(upgrade_levels)

	# One entry point, so a stratum field can never again be wired in the game
	# and forgotten in the five tools that measure it. `richness` is folded
	# into the yield there: without it, depth only ever made the board hotter
	# and the quota higher, which is the shape of a game nobody finishes.
	Strata.apply(sim, grid, _stratum, _mult)
	var lm: Dictionary = {}
	var hs: Dictionary = {}
	var types: Dictionary = machine_levels.duplicate()
	types.merge(overdrive)
	for id: String in types:
		if MachineDB.level_is_speed(id):
			lm[id] = MachineDB.level_speed(machine_level(id), overdrive_steps(id))
		var f: float = MachineDB.heat_factor(id, machine_level(id), overdrive_steps(id))
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
	sim.reset_progress()
	_recompute()
	stats_changed.emit()
	return true


func undo_sell(cell: int, id: String, refunded: float) -> bool:
	if not grid.is_empty(cell) or not is_unlocked(id):
		return false
	if not grid.place(cell, id):
		return false
	credits -= refunded
	sim.reset_progress()
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
		"upgrades": upgrade_levels,
		"blueprints": blueprints,
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
	upgrade_levels = d.get("upgrades", {})
	blueprints = d.get("blueprints", [])
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
