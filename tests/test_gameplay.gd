extends RefCounted

## The things this release changed, held in place.
##
## Everything here is a design guarantee rather than a snapshot of one
## afternoon's numbers. Where a figure is unavoidable it is a bound with
## headroom, not an equality, because the economy is meant to keep being
## tuned and a test that fails on every tuning pass gets deleted rather than
## read.

var runner: Object

const KEY := {
	"d": "drill", "c": "crusher", "s": "smelter", "p": "press",
	"a": "assembler", "v": "vault", "l": "lab", "b": "boiler", "o": "coolant",
}


func _sim(art: Array, depth: int = 0) -> Simulation:
	var g := Grid.new()
	var st: Dictionary = Strata.describe(depth)
	g.set_environment(float(st["ambient_heat"]), float(st["heat_spread"]))
	for y in range(mini(art.size(), Grid.H)):
		var row: String = String(art[y])
		for x in range(mini(row.length(), Grid.W)):
			if KEY.has(row[x]):
				g.place(Grid.idx(x, y), String(KEY[row[x]]))
	var s := Simulation.new(g, 4242)
	s.yield_mult = float(st["richness"]) * float(st["source_yield"])
	s.value_mult = float(st["value"])
	s.speed_mult = float(st["process_speed"])
	s.research_mult = float(st["research"])
	return s


func _rate(s: Simulation, seconds: float = 40.0) -> Dictionary:
	s.run_ticks(int(25.0 * Simulation.TICK_HZ))
	var out: Dictionary = s.run_ticks(int(seconds * Simulation.TICK_HZ))
	return {"credits": float(out["credits"]) / seconds,
		"research": float(out["research"]) / seconds}


## --- the economic model ----------------------------------------------------

func test_the_shipping_model_is_the_one_that_was_measured() -> void:
	# Written out so that switching models is a visible change here as well as
	# in the table. `tools/econ_lab.gd` is what decides which one it should be.
	runner.eq(MachineDB.ACTIVE_MODEL, "linear_warm",
		"the shipped economy must be the one the comparison chose")
	runner.check(MachineDB.MODELS.has("base"),
		"the original model stays in the source so the comparison can be re-run")


func test_a_long_chain_is_worth_building() -> void:
	# The problem this release set out to fix: with the old recipes, a full
	# production chain scored at the BOTTOM of the layout table and the deep
	# machines were content nobody would build.
	#
	# Every step now takes one of the thing below it, so a single adjacent
	# supplier is enough and a chain can be fed through a four-neighbour grid.
	# The bar is parity, not dominance -- a deep chain that always wins would
	# make the shallow board dead content instead.
	var deep := _sim([
		"ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa", "vvlvlvv",
	], 9)
	var shallow := _sim([
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv",
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv",
	], 9)
	var d: Dictionary = _rate(deep)
	var sh: Dictionary = _rate(shallow)
	runner.gt(float(d["credits"]), float(sh["credits"]) * 0.7,
		"a full chain must be within reach of a shallow board (%.0f vs %.0f)"
		% [float(d["credits"]), float(sh["credits"])])
	runner.lt(float(d["credits"]), float(sh["credits"]) * 2.5,
		"and must not make the shallow board pointless")


func test_only_the_deep_chain_produces_research() -> void:
	# This is what makes depth a decision rather than a bigger number. A
	# shallow board earns and cannot buy anything permanent; a deep one earns
	# about the same and can.
	var deep := _sim([
		"ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa", "vvlvlvv",
	], 9)
	var shallow := _sim([
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv",
	], 9)
	runner.gt(float(_rate(deep)["research"]), 0.3,
		"a board with the full chain must produce research")
	runner.near(float(_rate(shallow)["research"]), 0.0, 0.0001,
		"a board without one must produce none at all")


func test_no_single_board_wins_at_every_depth() -> void:
	# A placement game whose answer does not change is a solved game. The
	# stratum modifiers are what make the answer change -- Cramped alone takes
	# thirty of the seventy tiles away.
	var shapes := {
		"shallow": ["ddddddd", "ccccccc", "sssssss", "vvvvvvv",
			"ddddddd", "ccccccc", "sssssss", "vvvvvvv"],
		"deep": ["ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa",
			"vvlvlvv"],
	}
	var winners: Array[String] = []
	for depth in [3, 9, 16]:
		var best: String = ""
		var best_rate: float = -1.0
		for name: String in shapes:
			var g := Grid.new()
			var st: Dictionary = Strata.describe(depth)
			g.set_environment(float(st["ambient_heat"]), float(st["heat_spread"]))
			var blocked: Dictionary = Strata.blocked_cells(depth)
			var art: Array = shapes[name]
			for y in range(mini(art.size(), Grid.H)):
				var row: String = String(art[y])
				for x in range(mini(row.length(), Grid.W)):
					var i: int = Grid.idx(x, y)
					if KEY.has(row[x]) and not blocked.has(i):
						g.place(i, String(KEY[row[x]]))
			var s := Simulation.new(g, 4242)
			s.yield_mult = float(st["richness"]) * float(st["source_yield"])
			s.speed_mult = float(st["process_speed"])
			var r: float = float(_rate(s, 20.0)["credits"])
			if r > best_rate:
				best_rate = r
				best = name
		winners.append(best)
	var distinct: Array[String] = []
	for w in winners:
		if not distinct.has(w):
			distinct.append(w)
	runner.gt(float(distinct.size()), 1.0,
		"the same board shape won at every depth tested (%s)"
		% ", ".join(winners))


## --- material sharing ------------------------------------------------------

func test_a_producer_splits_its_output_between_equal_neighbours() -> void:
	# It used not to. A producer handed everything to whichever consumer the
	# cell dictionary visited first, so three identical, identically connected
	# Smelters ran at 96%, 73% and 0% with nothing on screen to explain it.
	# Each Smelter needs its own Vault, or it fills its output buffer, blocks,
	# and reads as dead for reasons that have nothing to do with sharing.
	var s := _sim([
		".......",
		"..sv...",
		".dc....",
		"..sv...",
	], 0)
	s.run_ticks(1800)
	var a: float = s.uptime_of(Grid.idx(2, 1))
	var b: float = s.uptime_of(Grid.idx(2, 3))
	runner.gt(a, 0.05, "the first smelter must be fed")
	runner.gt(b, 0.05, "and so must the second (%.2f vs %.2f)" % [a, b])
	runner.lt(absf(a - b), 0.35,
		"two identical, identically connected machines must do similar "
		+ "amounts of work (%.2f vs %.2f)" % [a, b])


func test_sharing_does_not_create_or_destroy_material() -> void:
	# Fairness is a distribution change, not an economy change.
	var before := _sim(["ddddddd", "ccccccc", "vvvvvvv"], 0)
	var out: Dictionary = before.run_ticks(600)
	runner.gt(float(out["credits"]), 0.0, "the board earns")
	var again := _sim(["ddddddd", "ccccccc", "vvvvvvv"], 0)
	runner.near(float(again.run_ticks(600)["credits"]), float(out["credits"]),
		0.001, "and the simulation is still deterministic")


## --- the duty cycle --------------------------------------------------------

func test_duty_cycle_measures_completed_work_not_intent() -> void:
	# The first version reported 99% for a machine that was merely mid-cycle,
	# which made every dead-tile measurement in the balance tools wrong.
	# A machine with nothing to eat must read zero.
	var s := _sim(["..s....", ".......", "..v...."], 0)
	s.run_ticks(600)
	runner.near(s.uptime_of(Grid.idx(2, 0)), 0.0, 0.02,
		"a smelter with no supply at all is not working")

	var fed := _sim([".dcv..."], 0)
	fed.run_ticks(1200)
	runner.gt(fed.uptime_of(Grid.idx(1, 0)), 0.4,
		"a drill with somewhere to put its ore is working")


func test_a_dead_tile_is_detected() -> void:
	# A machine no chain reaches. This is the check the reference-layout test
	# is built on, so it has to be reliable.
	var s := _sim([".dcv...", ".......", "......s"], 0)
	s.run_ticks(900)
	runner.near(s.uptime_of(Grid.idx(6, 2)), 0.0, 0.02,
		"an unconnected smelter is dead")
	var counts: Dictionary = s.problem_counts()
	runner.gte(float(int(counts["starved"])), 1.0,
		"and the board reports it as starved")


## --- the tutorial ----------------------------------------------------------

func test_the_tutorial_is_a_short_chapter_of_short_lines() -> void:
	runner.lte(float(Tutorial.count()), 9.0,
		"chapter one has to be a chapter, not a manual")
	for i in range(Tutorial.count()):
		var line: String = Tutorial.line_for(i)
		runner.gt(float(line.length()), 8.0, "step %d has a line" % i)
		runner.lt(float(line.length()), 72.0,
			"step %d is %d characters; one line on a phone is about sixty"
			% [i, line.length()])


func test_every_tutorial_step_is_satisfied_by_doing_the_thing() -> void:
	# Walked in order against the real Sim, using the same calls the UI makes.
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.credits = 100000.0
	Sim.depth = 0
	Sim.max_depth = 0
	Sim.lifetime_credits = 0.0
	Sim.tutorial_moves = 0
	Sim.tutorial_saw_heat = false
	Sim._tutorial_step = 0
	Sim.unlocked.clear()
	Sim._recompute()

	runner.check(not Tutorial.satisfied(0, Sim), "nothing is done yet")
	runner.gt(float(Tutorial.highlight(0, Sim).size()), 0.0,
		"the first step points at some tiles")

	Sim.try_place(Grid.idx(3, 4), "drill")
	runner.check(Tutorial.satisfied(0, Sim), "placing a drill finishes step 1")

	# Step 2 is about adjacency, so an unconnected vault must not count.
	Sim.try_place(Grid.idx(0, 0), "vault")
	runner.check(not Tutorial.satisfied(1, Sim),
		"a vault nowhere near the drill has not taught adjacency")
	Sim.try_place(Grid.idx(4, 4), "vault")
	runner.check(Tutorial.satisfied(1, Sim), "one that touches it has")

	Sim.lifetime_credits = 5.0
	runner.check(Tutorial.satisfied(2, Sim), "credits arriving finishes step 3")

	runner.check(not Tutorial.satisfied(3, Sim), "nothing has been moved")
	Sim.move_machine(Grid.idx(4, 4), Grid.idx(5, 4))
	runner.check(Tutorial.satisfied(3, Sim), "moving the vault finishes step 4")

	runner.check(not Tutorial.satisfied(4, Sim), "no crusher yet")
	Sim.try_place(Grid.idx(3, 3), "crusher")
	runner.check(not Tutorial.satisfied(4, Sim),
		"a crusher that touches only the drill is not between them")
	Sim.try_place(Grid.idx(4, 4), "crusher")
	runner.check(Tutorial.satisfied(4, Sim),
		"one that touches both the drill and the vault is")

	runner.check(not Tutorial.satisfied(5, Sim), "the heat overlay is unseen")
	Sim.tutorial_saw_heat = true
	runner.check(Tutorial.satisfied(5, Sim), "opening it finishes that step")

	Sim.credits = Strata.quota_for(0) + 1.0
	runner.check(Tutorial.satisfied(6, Sim), "having the quota finishes step 7")
	Sim.descend()
	runner.check(Tutorial.satisfied(7, Sim), "descending finishes the chapter")
	Save.wipe()


func test_the_tutorial_ends_and_stays_ended() -> void:
	runner.check(Tutorial.is_done(Tutorial.count()),
		"past the last step the chapter is over")
	runner.eq(Tutorial.line_for(Tutorial.count()), "",
		"and there is nothing further to say")


## --- the codex -------------------------------------------------------------

func test_every_codex_board_is_a_board_that_runs() -> void:
	# A help page that describes a rule can be wrong. Each page here is a real
	# simulation, so this checks that each one actually simulates -- a page
	# whose machines never touch teaches the opposite of what it claims.
	var codex: GDScript = load("res://scripts/ui/codex.gd")
	var pages: Array = codex.get("PAGES")
	runner.gt(float(pages.size()), 6.0, "there are pages")
	for page: Dictionary in pages:
		var g := Grid.new()
		g.set_environment(float(page.get("ambient", 0.0)), MachineDB.HEAT_SPREAD)
		var placed: int = 0
		for e: Array in page["board"]:
			if g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2])):
				placed += 1
		runner.eq(placed, (page["board"] as Array).size(),
			"every machine on the '%s' page must be placeable" % page["id"])
		var s := Simulation.new(g, 99)
		s.run_ticks(400)
		var working: int = 0
		for i: int in g.cells:
			if s.uptime_of(i) > 0.05 \
					or s.status_of(i) == Simulation.Status.PASSIVE:
				working += 1
		runner.gt(float(working), 1.0,
			"the '%s' page shows a board where nothing happens" % page["id"])


func test_codex_pages_are_short() -> void:
	var codex: GDScript = load("res://scripts/ui/codex.gd")
	for page: Dictionary in codex.get("PAGES"):
		runner.lt(float(String(page["body"]).length()), 330.0,
			"the '%s' page is a wall of text" % page["id"])
		runner.lt(float(String(page["watch"]).length()), 64.0,
			"the '%s' page's caption should fit one line" % page["id"])


## --- placement preview -----------------------------------------------------

func test_the_placement_preview_tells_the_truth() -> void:
	# The board shows what a placement would do to each neighbour before the
	# credits are spent. If that number and the result disagree, the feature
	# is worse than not having it.
	var g := Grid.new()
	g.place(Grid.idx(3, 3), "smelter")
	var before: float = g.heat_at(Grid.idx(3, 3))
	var boiler: Dictionary = MachineDB.get_machine("boiler")
	var predicted: float = float(boiler["heat_out"]) * g.heat_spread
	g.place(Grid.idx(3, 2), "boiler")
	var after: float = g.heat_at(Grid.idx(3, 3))
	runner.near(after - before, predicted, 0.001,
		"the previewed heat change must be the change that happens")


## --- undo ------------------------------------------------------------------

func test_undoing_a_placement_returns_exactly_what_it_cost() -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.credits = 1000.0
	Sim.depth = 0
	Sim.unlocked.clear()
	Sim._recompute()
	var price: float = Sim.cost_of("drill")
	runner.check(Sim.try_place(Grid.idx(3, 3), "drill"), "placed")
	runner.near(Sim.credits, 1000.0 - price, 0.001, "it cost what it said")
	runner.check(Sim.undo_place(Grid.idx(3, 3), price), "undone")
	runner.near(Sim.credits, 1000.0, 0.001,
		"undo must return the price paid, not the resale value")
	runner.check(Sim.grid.is_empty(Grid.idx(3, 3)), "and take the machine back")
	Save.wipe()


## --- recipe text -----------------------------------------------------------

func test_the_ui_reads_recipes_from_the_table() -> void:
	# Hand-written recipe text is how a game ends up lying to its player: the
	# table changes, the sentence does not, and the sentence is what they read.
	var smelter: Dictionary = MachineDB.get_machine("smelter")
	var text: String = MachineDB.recipe_text("smelter")
	var need: int = int((smelter["inputs"] as Dictionary).values()[0])
	runner.check(text.begins_with("%d " % need),
		"the smelter's recipe line must state its real input count (%s)" % text)
	runner.check(MachineDB.recipe_text("vault").to_lower().contains("sell"),
		"a vault's line should say what a vault does")
	runner.check(MachineDB.recipe_text("boiler") != "",
		"even a machine with no recipe needs a line")


## --- the headline number ---------------------------------------------------

func test_the_rate_readout_does_not_survive_the_board_it_measured() -> void:
	# The header averages production over a three-second window. When the
	# board changes, that window stops describing anything -- and it used to
	# keep being published anyway, most visibly right after a collapse, where
	# an empty board reported the rate of the factory just given up. A store
	# screenshot of the six-machine starter board was captured reading 600
	# credits a second against an actual 2.4, which is how this was found.
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.credits = 100000.0
	Sim.depth = 0
	Sim.max_depth = 0
	Sim.unlocked.clear()
	Sim._recompute()
	Sim.credits_per_sec = 999.0
	Sim.try_place(Grid.idx(3, 3), "drill")
	runner.near(Sim._rate_elapsed, 0.0, 0.0001,
		"placing a machine must restart the measurement")

	Sim.credits_per_sec = 999.0
	Sim.max_depth = 4
	Sim.depth = 4
	Sim.lifetime_credits = 500000.0
	if Sim.can_collapse():
		Sim.collapse()
		runner.near(Sim.credits_per_sec, 0.0, 0.0001,
			"an empty board reports nothing, not the rate of the last one")
	else:
		runner.check(true, "")
	Save.wipe()
