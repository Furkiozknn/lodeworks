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

	var newly: Array[String] = MachineDB.unlocked_at(max_depth)
	for id in newly:
		if not unlocked.has(id):
			unlocked.append(id)
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
