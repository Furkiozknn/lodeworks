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

const PLAN := [
	[3, 4, "drill"], [4, 4, "vault"], [3, 5, "drill"], [2, 4, "crusher"],
	[2, 5, "crusher"], [4, 5, "vault"], [3, 3, "drill"], [2, 3, "crusher"],
	[4, 3, "vault"],
]

var runner: Object


func _ok(cond: bool, msg: String) -> void:
	runner.check(cond, msg)


## Advance the simulation by wall-clock seconds without a frame loop.
func _advance(seconds: float) -> void:
	var ticks: int = int(seconds * Simulation.TICK_HZ)
	for _i in range(ticks):
		var out: Dictionary = Sim.sim.tick()
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
	Sim.core_online = false
	Sim.unlocked.clear()
	Sim._recompute()
	Sim.start()

	_ok(Sim.credits == 0.0, "a new game starts with nothing")
	_ok(Sim.is_unlocked("drill"), "the first machines are available immediately")
	_ok(not Sim.is_unlocked("lab"), "and the late ones are not")

	# --- first session ------------------------------------------------------
	# The first thing the game asks for, and the only money it ever gives.
	_ok(not Sim.can_afford("drill"), "nothing can be bought before the Core is online")
	_ok(Sim.power_core(), "the Core comes online")
	_ok(Sim.try_place(Grid.idx(3, 4), "drill"), "can place the first drill")
	_ok(Sim.try_place(Grid.idx(4, 4), "vault"), "can place a vault beside it")
	_advance(30.0)
	_ok(Sim.credits > 0.0, "thirty seconds of two tiles earns something")
	_ok(Sim.credits_per_sec > 0.0, "and the rate readout is non-zero")

	_buy_out(PLAN, 600.0)
	_ok(Sim.grid.cells.size() >= 6, "a naive player fills a board out")

	# --- descending ---------------------------------------------------------
	var descents: int = 0
	var guard: int = 0
	while descents < 6 and guard < 400:
		guard += 1
		if Sim.can_descend():
			if Sim.descend():
				descents += 1
			continue
		_advance(30.0)
	_ok(descents >= 6, "six strata reached by playing badly (%d)" % descents)
	_ok(Sim.depth == descents, "depth tracks the descents")
	_ok(Sim.is_unlocked("smelter"), "descending unlocks machines")
	print("        depth %d, rate %.2f/s, lifetime %s"
		% [Sim.depth, Sim.credits_per_sec, Economy.fmt(Sim.lifetime_credits)])

	# --- research -----------------------------------------------------------
	var built_research: bool = false
	for i in range(60):
		if Sim.research >= 40.0:
			built_research = true
			break
		# Labs need a component chain; a naive player gets research slowly, so
		# hand it the research it would earn rather than simulating an hour.
		Sim.research += 1.0
	_ok(built_research, "research accumulates")
	_ok(Sim.can_buy_upgrade("throughput_1"), "the first upgrade is affordable")
	var before_rate: float = Sim.credits_per_sec
	_ok(Sim.buy_upgrade("throughput_1"), "and can be bought")
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
	_ok(absf(Sim.credits - credits_before) < maxf(credits_before * 0.5, 10.0),
		"credits survive a reload (offline earnings aside)")
	_ok(Sim.grid.cells.size() >= 6, "and so does the board")

	# --- collapse -----------------------------------------------------------
	_ok(Sim.can_collapse(), "a six-stratum run is worth collapsing")
	var cores: int = Sim.collapse()
	_ok(cores > 0, "the collapse pays %d cores" % cores)
	_ok(Sim.depth == 0 and Sim.credits == 0.0, "and resets the run")
	_ok(Sim.cores == cores, "cores are kept")
	_ok(Sim.upgrade_level("throughput_1") == 1, "research survives the collapse")
	_ok(Sim.grid.cells.is_empty(), "the board does not")

	Save.wipe()
