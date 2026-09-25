extends RefCounted

## "What now?": the Worklist's order is fixed, each line is the game's own
## answer to its question, and it never runs longer than MAX.

var runner: Object


func _new_game() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.depth = 0
	Sim.max_depth = 0
	Sim.lifetime_credits = 0.0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.core_online = false
	Sim.unlocked.clear()
	Sim._recompute()


func _kinds(items: Array) -> Array:
	return items.map(func(e): return String(e["kind"]))


func test_nothing_to_list_while_the_core_is_dark() -> void:
	_new_game()
	runner.eq(Worklist.of(Sim), [], "the Foreman's first line is the only thing to do")
	Save.wipe()


func test_the_order_is_trouble_the_way_down_research_then_building() -> void:
	_new_game()
	Sim.power_core()
	# A Drill with nothing to sell to: it backs up.
	runner.check(Sim.try_place(Grid.idx(19, 21), "drill"), "a lone Drill")
	Sim.sim.run_ticks(900)
	Sim.credits = Sim.quota() + 500.0
	Sim.research = 1.0e6
	Sim.cores = 1000
	var items: Array = Worklist.of(Sim)
	var kinds: Array = _kinds(items)
	runner.eq(kinds[0], "problems", "a machine in trouble comes first")
	runner.eq(int(items[0]["n"]), int(Sim.sim.problem_counts()["blocked"])
		+ int(Sim.sim.problem_counts()["starved"]) + int(Sim.sim.problem_counts()["thermal"]),
		"with the warning key's own count")
	runner.eq(kinds[1], "descend", "then the way down")
	runner.eq(int(items[1]["stratum"]), 1, "to the next stratum")
	runner.eq(kinds[2], "research", "then research")
	runner.eq(int(items[2]["n"]), Worklist.research_ready(Sim), "with the Research key's count")
	runner.check(kinds.has("first") or kinds.has("extend"),
		"and a machine unlocked but never built")
	runner.lte(float(items.size()), float(Worklist.MAX), "never longer than MAX")
	Save.wipe()


func test_a_first_machine_is_the_earliest_unbuilt_one_that_can_be_paid_for() -> void:
	_new_game()
	Sim.power_core()
	Sim.try_place(Grid.idx(19, 21), "drill")
	Sim.try_place(Grid.idx(19, 22), "vault")
	# Enough for a Crusher, not for a Crusher and its Vault (see below).
	Sim.credits = MachineDB.cost_for("crusher", 0) + 5.0
	var firsts: Array = Worklist.of(Sim).filter(func(e): return e["kind"] == "first")
	runner.eq(firsts.size(), 1, "one line")
	runner.eq(String(firsts[0]["id"]), "crusher", "the Crusher: the Drill and the Vault are built")
	Save.wipe()


func test_the_placement_line_is_a_machine_that_really_works_where_it_says() -> void:
	_new_game()
	Sim.power_core()
	# A Drill and a Vault a tile apart: the gap takes a Crusher that is fed
	# by the Drill and sells through the Vault.
	Sim.try_place(Grid.idx(19, 21), "drill")
	Sim.try_place(Grid.idx(19, 23), "vault")
	Sim.try_place(Grid.idx(18, 18), "crusher")
	Sim.credits = 1000.0
	var best: Dictionary = Worklist.best_placement(Sim)
	runner.check(not best.is_empty(), "something would work")
	var id: String = String(best["id"])
	var n: int = 0
	for cell: int in BuildArea.cells(Sim.max_depth):
		if Sim.grid.is_empty(cell) and not Sim.is_blocked(cell) \
				and not Sim.grid.neighbour_machines(cell).is_empty():
			var l: Dictionary = Sim.sim.links_if_placed(cell, id)
			if bool(l["fed"]) and bool(l["delivers"]):
				n += 1
	runner.eq(int(best["cells"]), n, "on exactly the tiles it counts")
	runner.gt(float(n), 0.0, "")
	# Nothing further along the chain works anywhere, or it would be named.
	var later: bool = false
	for other: String in MachineDB.ORDER.slice(MachineDB.ORDER.find(id) + 1):
		if Sim.unlocked.has(other) and Sim.can_afford(other):
			later = later or not Worklist.best_placement(Sim).is_empty() and String(Worklist.best_placement(Sim)["id"]) != id
	runner.check(not later, "it is the furthest step that would work")
	Save.wipe()


func test_with_nothing_else_to_do_it_says_how_far_the_quota_is() -> void:
	_new_game()
	Sim.power_core()
	Sim.try_place(Grid.idx(19, 21), "drill")
	Sim.try_place(Grid.idx(19, 22), "vault")
	Sim.try_place(Grid.idx(18, 21), "crusher")
	Sim.credits = 0.0
	var items: Array = Worklist.of(Sim)
	runner.eq(_kinds(items), ["quota"], "only the quota")
	runner.near(float(items[0]["missing"]), Sim.quota(), 0.001, "and how much is left")
	Save.wipe()


func test_a_collapse_line_appears_only_when_its_cores_open_something() -> void:
	_new_game()
	Sim.power_core()
	Sim.max_depth = Economy.COLLAPSE_MIN_DEPTH
	Sim.lifetime_credits = 1.0e7
	var gained: int = Sim.pending_cores()
	runner.gt(float(gained), 0.0, "a collapse would pay")
	var items: Array = Worklist.of(Sim).filter(func(e): return e["kind"] == "collapse")
	runner.eq(items.size(), 1 if not Worklist.cores_open(Sim, gained).is_empty() else 0,
		"a collapse line exactly when its Cores open a research line")
	Sim.cores = 100000
	runner.eq(Worklist.of(Sim).filter(func(e): return e["kind"] == "collapse").size(), 0,
		"and none when the Cores already there open everything they could")
	Save.wipe()


func test_a_step_that_works_nowhere_is_named_with_room_for_its_vault() -> void:
	# A Drill above a Vault: no empty tile touches both, so a Crusher works
	# nowhere, and a list that only named machines that work would never
	# name it (GAP-AUDIT B-1b).
	_new_game()
	Sim.power_core()
	Sim.try_place(Grid.idx(19, 21), "drill")
	Sim.try_place(Grid.idx(19, 22), "vault")
	Sim.credits = 1000.0
	var items: Array = Worklist.of(Sim)
	var ext: Array = items.filter(func(e): return e["kind"] == "extend")
	runner.eq(ext.size(), 1, "one extend line")
	var e: Dictionary = ext[0]
	runner.eq(String(e["id"]), "crusher", "for the Crusher")
	runner.eq(String(e["feeder"]), "drill", "beside the Drill that feeds it")
	var cell: int = int(e["cell"])
	var outlet: int = int(e["outlet"])
	var l: Dictionary = Sim.sim.links_if_placed(cell, "crusher")
	runner.check(bool(l["fed"]) and not bool(l["delivers"]), "fed there, with nothing yet to take gravel")
	runner.check(Sim.grid.neighbours(cell).has(outlet) and Sim.grid.is_empty(outlet)
		and Sim.is_open(outlet), "and an open tile beside it for the Vault")
	runner.check(items.filter(func(x): return x["kind"] == "first").is_empty(),
		"it takes the place of 'build your first Crusher'")
	# Built as it says, the chain runs.
	runner.check(Sim.try_place(cell, "crusher") and Sim.try_place(outlet, "vault"), "both placed")
	Sim.sim.run_ticks(300)
	# One Drill feeds a Crusher that takes two ore a cycle, so between
	# cycles it waits: it works when it is busy a good part of the time,
	# whatever its status says on the last tick.
	runner.gt(Sim.sim.uptime_of(cell), 0.1, "and the Crusher works")
	Save.wipe()
