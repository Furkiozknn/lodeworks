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
signal offline_earnings(report: Dictionary)

const AUTOSAVE_SECONDS := 20.0
## Measured throughput is smoothed so the header number does not jitter with
## every cycle. Idle players stare at this number; it has to feel steady.
const RATE_SMOOTHING := 0.12

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
var blueprints: Array = []
var unlocked: Array[String] = []
var settings: Dictionary = {"sound": true, "haptics": true}

## Live measured rates, used for the header and for offline earnings.
var credits_per_sec: float = 0.0
var research_per_sec: float = 0.0

var _tick_accum: float = 0.0
var _save_accum: float = 0.0
var _stratum: Dictionary = {}
var _mult: Dictionary = {}
var _started: bool = false
var _tutorial_step: int = 0


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
	Analytics.track("session_start", {"depth": depth, "collapses": collapses})


func _process(delta: float) -> void:
	if not _started:
		return
	_tick_accum += delta
	var steps: int = 0
	while _tick_accum >= Simulation.TICK_DT and steps < 6:
		_tick_accum -= Simulation.TICK_DT
		var out: Dictionary = sim.tick()
		var c: float = float(out["credits"])
		var r: float = float(out["research"])
		credits += c
		research += r
		lifetime_credits += c
		# Instantaneous rate, exponentially smoothed.
		var inst_c: float = c / Simulation.TICK_DT
		var inst_r: float = r / Simulation.TICK_DT
		credits_per_sec = lerpf(credits_per_sec, inst_c, RATE_SMOOTHING)
		research_per_sec = lerpf(research_per_sec, inst_r, RATE_SMOOTHING)
		steps += 1
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


func try_place(cell: int, id: String) -> bool:
	if not is_unlocked(id) or is_blocked(cell) or not grid.is_empty(cell):
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
	Analytics.track("machine_placed", {"id": id, "depth": depth})
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
	if is_blocked(to_cell):
		return false
	if not grid.move(from_cell, to_cell):
		return false
	sim.reset_progress()
	_recompute()
	stats_changed.emit()
	return true


## --- descent ---------------------------------------------------------------

func quota() -> float:
	return float(_stratum.get("quota", Strata.quota_for(depth)))


func can_descend() -> bool:
	return credits >= quota()


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
	depth_changed.emit(depth)
	if not gained.is_empty():
		machines_unlocked.emit(gained)
	stats_changed.emit()
	Save.save_game(self)
	Analytics.track("descend", {"depth": depth, "unlocked": gained.size()})
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
	credits_per_sec = 0.0
	research_per_sec = 0.0
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
	if lvl >= int(u["max"]):
		return false
	var c: Dictionary = Economy.upgrade_cost(id, lvl)
	return research >= float(c["research"]) and cores >= int(c["cores"])


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
	Analytics.track("upgrade", {"id": id, "level": lvl + 1})
	return true


## --- derived state ---------------------------------------------------------

func _recompute() -> void:
	if grid == null:
		grid = Grid.new()
		sim = Simulation.new(grid, 20260923)
	_stratum = Strata.describe(depth)
	_mult = Economy.multipliers(upgrade_levels)

	sim.speed_mult = float(_mult["speed"]) * float(_stratum["process_speed"])
	# `richness` is the base reward for descending; without it, depth only ever
	# made the board hotter and the quota higher, which is the shape of a game
	# nobody finishes.
	sim.yield_mult = float(_mult["yield"]) * float(_stratum["source_yield"]) \
		* float(_stratum["richness"])
	sim.value_mult = float(_mult["value"]) * float(_stratum["value"])
	sim.research_mult = float(_mult["research"]) * float(_stratum["research"])
	sim.tolerance_bonus = float(_mult["tolerance"])
	sim.buffer_cap = Simulation.BUF_CAP + int(_stratum["buffer_delta"])
	grid.set_environment(float(_stratum["ambient_heat"]),
		float(_stratum["heat_spread"]))

	var newly: Array[String] = MachineDB.unlocked_at(max_depth)
	for id in newly:
		if not unlocked.has(id):
			unlocked.append(id)


func stratum() -> Dictionary:
	return _stratum


func mult() -> Dictionary:
	return _mult


func blueprint_slots() -> int:
	var base: int = int(float(_mult.get("blueprints", 1.0)))
	return base + Store.bonus_blueprint_slots()


func offline_hours() -> float:
	return float(_mult.get("offline_hours", Economy.OFFLINE_BASE_HOURS)) \
		+ Store.bonus_offline_hours()


## --- tutorial --------------------------------------------------------------

func tutorial_step() -> int:
	return _tutorial_step


func advance_tutorial() -> void:
	_tutorial_step += 1
	Analytics.track("tutorial_step", {"step": _tutorial_step})
	Save.save_game(self)


func tutorial_done() -> bool:
	return _tutorial_step >= 5


## --- persistence -----------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"v": 1,
		"credits": credits,
		"research": research,
		"cores": cores,
		"depth": depth,
		"max_depth": max_depth,
		"lifetime_credits": lifetime_credits,
		"collapses": collapses,
		"upgrades": upgrade_levels,
		"blueprints": blueprints,
		"grid": grid.to_dict(),
		"settings": settings,
		"tutorial": _tutorial_step,
		"rate": credits_per_sec,
		"research_rate": research_per_sec,
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
	upgrade_levels = d.get("upgrades", {})
	blueprints = d.get("blueprints", [])
	settings = d.get("settings", {"sound": true, "haptics": true})
	_tutorial_step = int(d.get("tutorial", 0))
	credits_per_sec = float(d.get("rate", 0.0))
	research_per_sec = float(d.get("research_rate", 0.0))
	grid.from_dict(d.get("grid", {}))
	sim.reset_progress()
	_recompute()
