extends RefCounted

## An automated playthrough against the real game state.
##
## Runs as part of the normal suite, because it is the only check that the
## pieces work *together*.
##
## This is the end-to-end check that the *game*, not the simulation, works: it
## starts from an empty save, places machines through the same `Sim.try_place`
## the UI calls, waits for credits at the real tick rate, descends when it can
## afford to, buys upgrades, and collapses. If any of that has come apart, this
## exits non-zero.
##
## It plays badly on purpose -- a fixed, obvious strategy with no optimisation.
## If a naive player cannot get anywhere, the game is wrong.

## In the first shaft's yard, the ring round the Core: down its left side
## (x = 19) and along the front (y = 24).
const PLAN := [
	[19, 21, "drill"], [19, 22, "vault"], [19, 20, "drill"], [19, 19, "crusher"],
	[20, 19, "vault"], [19, 23, "crusher"], [19, 24, "drill"], [20, 24, "crusher"],
	[21, 24, "vault"],
]

## The Core's second level, played for (CoreLevels): two Smelters touching the
## Core on its right side, filling its store, each with a Boiler for its
## working heat and a shared Vault for what the store has no room for, each
## fed by a Crusher that two Drills feed; a Lab behind the upper Boiler,
## which hands it Ingots straight through, for the first research.
const CORE_LINE := [
	[26, 21, "drill"], [25, 20, "drill"], [25, 21, "crusher"],
	[26, 23, "drill"], [25, 24, "drill"], [25, 23, "crusher"],
	[24, 22, "vault"], [24, 21, "smelter"], [24, 23, "smelter"],
	[24, 20, "boiler"], [24, 24, "boiler"], [24, 19, "lab"],
]

var runner: Object


func _ok(cond: bool, msg: String) -> void:
	runner.check(cond, msg)


## Advance the simulation by wall-clock seconds without a frame loop.
func _advance(seconds: float) -> void:
	var ticks: int = int(seconds * Simulation.TICK_HZ)
	for _i in range(ticks):
		var out: Dictionary = Sim.sim.tick()
		Sim._collect_stock()
		var c: float = float(out["credits"])
		Sim.credits += c
		Sim.lifetime_credits += c
		Sim.research += float(out["research"])
	var m: Dictionary = Sim.sim.measure(5.0, 10.0)
	Sim.credits_per_sec = float(m["credits_per_sec"])
	Sim.research_per_sec = float(m["research_per_sec"])


func _buy_out(plan: Array, budget_seconds: float) -> void:
	for step: Array in plan:
		var cell: int = Grid.idx(int(step[0]), int(step[1]))
		var id: String = String(step[2])
		if not Sim.is_unlocked(id):
			continue
		var waited: float = 0.0
		while not Sim.can_afford(id) and waited < budget_seconds:
			_advance(10.0)
			waited += 10.0
		if Sim.can_afford(id):
			Sim.try_place(cell, id)


func test_a_naive_player_can_actually_progress() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.depth = 0
	Sim.max_depth = 0
	Sim.lifetime_credits = 0.0
	Sim.upgrade_levels = {}
	Sim.collapses = 0
	Sim.core_online = false
	Sim.unlocked.clear()
	Sim.best_core = 1
	Sim.doctrine = ""
	Sim.blueprints = []
	Sim.blueprint_pending = []
	Sim.clear_ops()
	Sim._recompute()
	Sim.start()

	_ok(Sim.credits == 0.0, "a new game starts with nothing")
	_ok(Sim.is_unlocked("drill"), "the first machines are available immediately")
	_ok(not Sim.is_unlocked("lab"), "and the late ones are not")

	# --- first session ------------------------------------------------------
	# The first thing the game asks for, and the only money it ever gives.
	_ok(not Sim.can_afford("drill"), "nothing can be bought before the Core is online")
	_ok(Sim.power_core(), "the Core comes online")
	_ok(Sim.try_place(Grid.idx(19, 21), "drill"), "can place the first drill")
	_ok(Sim.try_place(Grid.idx(19, 22), "vault"), "can place a vault beside it")
	_advance(30.0)
	_ok(Sim.credits > 0.0, "thirty seconds of two tiles earns something")
	_ok(Sim.credits_per_sec > 0.0, "and the rate readout is non-zero")

	_buy_out(PLAN, 600.0)
	_ok(Sim.grid.cells.size() >= 6, "a naive player fills a board out")

	# --- descending, as far as a level-1 Core allows ------------------------
	var descents: int = _descend_to(CoreLevels.depth_cap(1))
	_ok(descents == CoreLevels.depth_cap(1), "a level-1 Core lets the shaft reach stratum %d (%d)"
		% [CoreLevels.depth_cap(1), descents])
	_ok(Sim.is_unlocked("smelter"), "descending unlocks machines")
	var waited: float = 0.0
	while not Sim.descent_needs_core() and waited < 1800.0:
		_advance(30.0)
		waited += 30.0
	_ok(Sim.descent_needs_core() and not Sim.can_descend(),
		"with the quota met, the Core has to grow before the shaft goes deeper")
	_ok(not Sim.can_upgrade_core(), "and credits alone do not grow it")

	# --- the Core's second level: a real line, a real upgrade ----------------
	_buy_out(CORE_LINE, 900.0)
	for step: Array in CORE_LINE:
		_ok(Sim.grid.machine_at(Grid.idx(int(step[0]), int(step[1]))) == String(step[2]),
			"%s at (%d, %d)" % [step[2], step[0], step[1]])
	# Everything the second level asks for comes out of this one line: the
	# Ingots in the store pay for the Vault's level 2 (a bigger store) and
	# the Crushers' level 2, the Lab's research buys the first line of the
	# tree, and the store then fills for the Core itself.
	waited = _wait_for(func() -> bool: return Sim.can_upgrade_machine("vault"), 1800.0)
	_ok(Sim.upgrade_machine("vault"), "the Vault goes to level 2: a bigger store (%.0f s)" % waited)
	waited = _wait_for(func() -> bool: return Sim.can_upgrade_machine("crusher"), 1800.0)
	_ok(Sim.upgrade_machine("crusher"), "the Crushers go to level 2, paid in Ingots (%.0f s)" % waited)
	waited = _wait_for(func() -> bool: return Sim.can_buy_upgrade("throughput_1"), 1800.0)
	_ok(Sim.buy_upgrade("throughput_1"), "the Lab's first research is bought (%.0f s)" % waited)
	waited = _wait_for(func() -> bool: return Sim.can_upgrade_core(), 3600.0)
	for st: Dictionary in Sim.core_status():
		_ok(bool(st["met"]), "Core level 2 asks for %s: %.0f / %.0f"
			% [str(st["req"]), float(st["have"]), float(st["need"])])
	print("        Core level 2 ready after %.0f s of play for it" % waited)
	_ok(Sim.upgrade_core(), "the Core grows to level 2")
	_ok(Sim.core_level == 2, "")
	_ok(Sim.research_cap("yield_1") > 0, "and a new research line opens")
	descents += _descend_to(CoreLevels.depth_cap(2))
	_ok(descents >= 4, "four strata reached by playing badly (%d)" % descents)
	_ok(Sim.depth == descents, "depth tracks the descents")
	_ok(Sim.is_unlocked("press") and Sim.is_unlocked("amplifier"),
		"the Core's level opened the strata below, and their machines")
	print("        depth %d, rate %.2f/s, lifetime %s"
		% [Sim.depth, Sim.credits_per_sec, Economy.fmt(Sim.lifetime_credits)])

	# --- research -----------------------------------------------------------
	waited = _wait_for(func() -> bool: return Sim.can_buy_upgrade("throughput_1"), 3600.0)
	_ok(Sim.can_buy_upgrade("throughput_1"), "the Lab earns the next level (%.0f s)" % waited)
	var before_rate: float = Sim.credits_per_sec
	_ok(Sim.buy_upgrade("throughput_1"), "and it can be bought")
	_advance(30.0)
	_ok(Sim.credits_per_sec > before_rate * 1.02,
		"buying it visibly raises the rate (%.2f -> %.2f)"
		% [before_rate, Sim.credits_per_sec])
	print("        after upgrade: %.2f/s" % Sim.credits_per_sec)

	# --- save round trip ----------------------------------------------------
	var depth_before: int = Sim.depth
	var credits_before: float = Sim.credits
	_ok(Save.save_game(Sim), "the game saves")
	Sim.grid.clear()
	Sim.credits = 0.0
	Sim.depth = 0
	Save.load_game(Sim)
	_ok(Sim.depth == depth_before, "depth survives a reload")
	_ok(Sim.core_level == 2 and Sim.machine_level("crusher") == 2,
		"so do the Core's level and the machines' levels")
	_ok(absf(Sim.credits - credits_before) < maxf(credits_before * 0.5, 10.0),
		"credits survive a reload (offline earnings aside)")
	_ok(Sim.grid.cells.size() >= 6, "and so does the board")

	# --- collapse -----------------------------------------------------------
	_ok(Sim.can_collapse(), "a four-stratum run is worth collapsing")
	var cores: int = Sim.collapse()
	_ok(cores > 0, "the collapse pays %d cores" % cores)
	_ok(Sim.depth == 0 and Sim.credits == 0.0, "and resets the run")
	_ok(Sim.cores == cores, "cores are kept")
	_ok(Sim.upgrade_level("throughput_1") == 2, "research survives the collapse")
	_ok(Sim.grid.cells.is_empty(), "the board does not")
	_ok(Sim.core_level == 1 and Sim.machine_level("crusher") == 1,
		"a new shaft's Core and machines start at level 1")

	Save.wipe()



## Descend whenever the quota allows, up to stratum `to`; how many descents.
func _descend_to(to: int) -> int:
	var n: int = 0
	var guard: int = 0
	while Sim.depth < to and guard < 400:
		guard += 1
		if Sim.can_descend():
			if Sim.descend():
				n += 1
			continue
		_advance(30.0)
	return n


## Play until `done` is true or `limit` seconds have gone; the seconds played.
func _wait_for(done: Callable, limit: float) -> float:
	var waited: float = 0.0
	while not bool(done.call()) and waited < limit:
		_advance(15.0)
		waited += 15.0
	return waited
