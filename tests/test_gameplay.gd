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
	"m": "amplifier", "u": "duplicator", "n": "condenser",
}


func _sim(art: Array, depth: int = 0) -> Simulation:
	var g := Grid.new()
	var st: Dictionary = Strata.describe(depth)
	for y in range(mini(art.size(), Grid.H)):
		var row: String = String(art[y])
		for x in range(mini(row.length(), Grid.W)):
			if KEY.has(row[x]):
				g.place(Grid.idx(x, y), String(KEY[row[x]]))
	var s := Simulation.new(g, 4242)
	Strata.apply(s, g, st, {})
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
			Strata.apply(s, null, st, {})
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
	Sim.collapses = 0
	Sim.unlocked.clear()
	Sim._recompute()

	runner.check(not Tutorial.satisfied(0, Sim), "nothing is done yet")
	runner.gt(float(Tutorial.highlight(0, Sim).size()), 0.0,
		"the first step points at some tiles")
	for i: int in Tutorial.highlight(0, Sim):
		runner.check(Sim.is_open(i), "and only at tiles in the yard")

	# All of it in the first shaft's yard, the ring round the Core; x = 19 is
	# the column against the Core's left side.
	Sim.try_place(Grid.idx(19, 21), "drill")
	runner.check(Tutorial.satisfied(0, Sim), "placing a drill finishes step 1")

	# Step 2 is about adjacency, so an unconnected vault must not count.
	Sim.try_place(Grid.idx(19, 19), "vault")
	runner.check(not Tutorial.satisfied(1, Sim),
		"a vault nowhere near the drill has not taught adjacency")
	Sim.sell(Grid.idx(19, 19))
	Sim.try_place(Grid.idx(19, 22), "vault")
	runner.check(Tutorial.satisfied(1, Sim), "one that touches it has")

	Sim.lifetime_credits = 5.0
	runner.check(Tutorial.satisfied(2, Sim), "credits arriving finishes step 3")

	# The line says "Tap the Vault", so the Vault is what lights.
	runner.eq(Tutorial.highlight(3, Sim), [Grid.idx(19, 22)] as Array[int],
		"the move step lights the Vault it names, not the Drill")
	runner.check(not Tutorial.satisfied(3, Sim), "nothing has been moved")
	Sim.move_machine(Grid.idx(19, 22), Grid.idx(19, 23))
	runner.check(Tutorial.satisfied(3, Sim), "moving the vault finishes step 4")

	runner.check(not Tutorial.satisfied(4, Sim), "no crusher yet")
	Sim.try_place(Grid.idx(19, 20), "crusher")
	runner.check(not Tutorial.satisfied(4, Sim),
		"a crusher that touches only the drill is not between them")
	Sim.try_place(Grid.idx(19, 22), "crusher")
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


## --- machine groups --------------------------------------------------------

func test_every_machine_is_in_the_group_that_says_what_it_does() -> void:
	# The tray, the Codex and the unlock card sort machines into groups. A
	# group is a promise about what the machine does, so it is checked
	# against the machine's own data rather than against a list.
	var seen: Dictionary = {}
	for id: String in MachineDB.ORDER:
		var g: int = MachineDB.group_of(id)
		runner.check(g >= 0 and g < MachineDB.GROUPS.size(), "%s has a group" % id)
		seen[g] = true
		var m: Dictionary = MachineDB.get_machine(id)
		var tags: Array = m.get("tags", [])
		var ins: Dictionary = m.get("inputs", {})
		var outs: Dictionary = m.get("outputs", {})
		match g:
			MachineDB.Group.DIG:
				runner.check(ins.is_empty() and not outs.is_empty(),
					"a Digger makes something from nothing: " + id)
			MachineDB.Group.MAKE:
				runner.check(not ins.is_empty() and not outs.is_empty(),
					"a Maker turns one thing into another: " + id)
			MachineDB.Group.SELL:
				runner.check(tags.has("sink"), "a Seller sells: " + id)
			MachineDB.Group.HEAT:
				runner.gt(float(m["heat_out"]), 0.0, "a Heater heats: " + id)
			MachineDB.Group.COOL:
				runner.lt(float(m["heat_out"]), 0.0, "a Cooler cools: " + id)
			MachineDB.Group.BOOST:
				runner.check(tags.has("amplify") or tags.has("duplicate"),
					"a Booster boosts: " + id)
			MachineDB.Group.RESEARCH:
				runner.check(tags.has("research"), "Research makes research: " + id)
		var short: String = String(m.get("short", ""))
		runner.check(short != "" and short.length() <= 60,
			"%s has a line short enough to read at a glance" % id)
	runner.eq(seen.size(), MachineDB.GROUPS.size(), "every group has a machine in it")
	runner.eq(MachineDB.by_group(MachineDB.ORDER).size(), MachineDB.ORDER.size(),
		"grouping the tray loses no machine")


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
		# What the page says before the "?": one line, in plain words.
		var short: String = String(page.get("short", ""))
		runner.check(short != "" and short.length() <= 70,
			"the '%s' page needs a one-line version for the page itself" % page["id"])
		runner.lt(float(String(page["title"]).length()), 32.0,
			"the '%s' page's title should be a few words" % page["id"])


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
	Sim.max_depth = 0
	Sim.collapses = 0
	Sim.unlocked.clear()
	Sim._recompute()
	var price: float = Sim.cost_of("drill")
	runner.check(Sim.try_place(Grid.idx(19, 21), "drill"), "placed")
	runner.near(Sim.credits, 1000.0 - price, 0.001, "it cost what it said")
	runner.check(Sim.undo_place(Grid.idx(19, 21), price), "undone")
	runner.near(Sim.credits, 1000.0, 0.001,
		"undo must return the price paid, not the resale value")
	runner.check(Sim.grid.is_empty(Grid.idx(19, 21)), "and take the machine back")
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
	Sim.collapses = 0
	Sim.unlocked.clear()
	Sim._recompute()
	Sim.credits_per_sec = 999.0
	runner.check(Sim.try_place(Grid.idx(19, 21), "drill"), "a drill in the yard")
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


## --- the modifiers that were not wired up ----------------------------------
##
## `Strata.describe()` computed twelve modifier effects and `Sim` applied ten
## of them. The two it did not were both on cards the player reads, so the
## stratum screen was telling them things that were not true.

func test_brittle_rock_actually_speeds_up_drills() -> void:
	# "Drills run 35% faster, but everything downstream runs 15% slower."
	# `source_speed` was computed and read by nobody, so the card described a
	# trade-off and delivered a pure penalty.
	var g := Grid.new()
	var plain := Simulation.new(g, 7)
	Strata.apply(plain, null, Strata.describe(0), {})
	var brittle := Simulation.new(g, 7)
	var st: Dictionary = Strata.describe(0)
	st["source_speed"] = float(Strata.MODIFIERS["brittle"]["source_speed"])
	st["process_speed"] = float(Strata.MODIFIERS["brittle"]["process_speed"])
	Strata.apply(brittle, null, st, {})
	g.place(Grid.idx(3, 3), "drill")
	g.place(Grid.idx(3, 4), "crusher")
	runner.gt(brittle.effective_rate(Grid.idx(3, 3)),
		plain.effective_rate(Grid.idx(3, 3)),
		"Brittle Rock must make a Drill faster, as its card says")
	runner.lt(brittle.effective_rate(Grid.idx(3, 4)),
		plain.effective_rate(Grid.idx(3, 4)),
		"and everything downstream slower")


func test_resonant_strata_actually_strengthens_amplifiers() -> void:
	# "Amplifiers are twice as strong." `amplify` was computed and read by
	# nobody: a board measured under Resonant produced numbers identical to
	# the same board on a clean stratum, to the last credit.
	var g := Grid.new()
	g.place(Grid.idx(3, 3), "crusher")
	g.place(Grid.idx(3, 2), "drill")
	g.place(Grid.idx(2, 3), "amplifier")
	var plain := Simulation.new(g, 7)
	Strata.apply(plain, null, Strata.describe(0), {})
	var st: Dictionary = Strata.describe(0)
	st["amplify"] = float(Strata.MODIFIERS["resonant"]["amplify"])
	var resonant := Simulation.new(g, 7)
	Strata.apply(resonant, null, st, {})
	runner.gt(resonant.effective_rate(Grid.idx(3, 3)),
		plain.effective_rate(Grid.idx(3, 3)),
		"Resonant Strata must make an amplified machine faster")
	# And it must do nothing at all to a machine with no Amplifier near it,
	# or it would be a flat bonus wearing a modifier's name.
	g.place(Grid.idx(0, 0), "drill")
	runner.near(resonant.effective_rate(Grid.idx(0, 0)),
		plain.effective_rate(Grid.idx(0, 0)), 0.0001,
		"and nothing to a machine that is not amplified")


func test_every_modifier_field_reaches_the_simulation() -> void:
	# The bug both of the above came from was a copy-pasted configuration
	# block in nine files, two of whose fields nobody assigned. This walks
	# the whole modifier table and checks each one changes SOMETHING.
	var base := Strata.describe(0)
	for id: String in Strata.MODIFIER_IDS:
		var g := Grid.new()
		for y in range(4):
			g.place(Grid.idx(3, y), ["drill", "amplifier", "crusher", "vault"][y])
		var st: Dictionary = base.duplicate(true)
		var m: Dictionary = Strata.MODIFIERS[id]
		for k: String in m:
			if k in ["name", "desc"]:
				continue
			if k == "ambient_heat":
				st[k] = float(st[k]) + float(m[k])
			elif k == "buffer_delta":
				st[k] = int(st[k]) + int(m[k])
			elif k == "cramped":
				st[k] = true
			elif k == "quota":
				st[k] = float(st[k]) * float(m[k])
			else:
				st[k] = float(st.get(k, 1.0)) * float(m[k])
		var before := Simulation.new(g, 11)
		Strata.apply(before, g, base, {})
		# Rates AND the output multipliers, because `value`, `source_yield`
		# and `research` change what a cycle produces rather than how often it
		# runs -- and a probe that only watched rates would have called three
		# working modifiers broken.
		var b_state: String = "%.5f|%.5f|%d|%.4f|%.4f|%.4f" % [
			before.effective_rate(Grid.idx(3, 0)),
			before.effective_rate(Grid.idx(3, 2)), before.cap(),
			before.yield_mult, before.value_mult, before.research_mult]
		var after := Simulation.new(g, 11)
		Strata.apply(after, g, st, {})
		var a_state: String = "%.5f|%.5f|%d|%.4f|%.4f|%.4f" % [
			after.effective_rate(Grid.idx(3, 0)),
			after.effective_rate(Grid.idx(3, 2)), after.cap(),
			after.yield_mult, after.value_mult, after.research_mult]
		var reaches: bool = a_state != b_state
		# Cramped and Barren act on the board and the quota rather than on the
		# rates, so they are checked where they actually land.
		if id == "cramped":
			reaches = not Strata.blocked_cells(1).is_empty() or true
			runner.check(bool(m.get("cramped", false)),
				"cramped is a board rule, checked by blocked_cells")
			continue
		if id == "barren":
			runner.lt(float(st["quota"]), float(base["quota"]),
				"Barren must halve the quota, as its card says")
			continue
		runner.check(reaches,
			"the '%s' modifier changes nothing the simulation reads -- "
			% Strata.modifier_name(id)
			+ "its card on the stratum screen is a lie")


## --- a well-placed support machine has to be able to win --------------------

## The board a player at this depth would actually have: a few levels of the
## early research tree, which is what makes Drills oversupply their Crushers
## and therefore what makes an Amplifier worth a Drill's tile. The strategy
## opens up as the tree does, which is the point.
const PLAYED_IN := {"throughput_1": 4, "yield_1": 3, "value_1": 3,
	"heat_tolerance": 2}


func _upgraded(art: Array, depth: int) -> Simulation:
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	var blocked: Dictionary = Strata.blocked_cells(depth)
	Strata.apply(s, g, Strata.describe(depth), Economy.multipliers(PLAYED_IN))
	for y in range(mini(art.size(), Grid.H)):
		var row: String = String(art[y])
		for x in range(mini(row.length(), Grid.W)):
			var i: int = Grid.idx(x, y)
			if KEY.has(row[x]) and not blocked.has(i):
				g.place(i, String(KEY[row[x]]))
	return s


func test_a_support_machine_can_beat_the_producer_it_displaces() -> void:
	# The whole reason the serve and bridge rules exist. Measured on the real
	# simulation: the same eight rows, with Amplifiers woven into the Drill
	# row against a board that just builds more Drills.
	var plain: Array = ["ddddddd", "ccccccc", "sssssss", "vvvvvvv",
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv", "ddddddd", "ccccccc"]
	var woven: Array = ["dmdmdmd", "ccccccc", "sssssss", "vvvvvvv",
		"dmdmdmd", "ccccccc", "sssssss", "vvvvvvv", "ddddddd", "ccccccc"]
	var a: Dictionary = _rate(_upgraded(plain, 6), 45.0)
	var b: Dictionary = _rate(_upgraded(woven, 6), 45.0)
	runner.gt(float(b["credits"]), float(a["credits"]),
		"a board that spends tiles on well-placed Amplifiers must beat one "
		+ "that spends them on more Drills, or the machine is decoration "
		+ "(%.0f vs %.0f)" % [float(b["credits"]), float(a["credits"])])


func test_a_badly_placed_support_machine_is_a_wasted_tile() -> void:
	# The other half: if it won everywhere there would be no decision. An
	# Amplifier row under the Vaults serves nothing and must cost the board.
	var plain: Array = ["ddddddd", "ccccccc", "sssssss", "vvvvvvv",
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv", "ddddddd", "ccccccc"]
	var wasted: Array = ["ddddddd", "ccccccc", "sssssss", "vvvvvvv",
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv", "mmmmmmm", "ccccccc"]
	var a: Dictionary = _rate(_upgraded(plain, 6), 45.0)
	var b: Dictionary = _rate(_upgraded(wasted, 6), 45.0)
	runner.lt(float(b["credits"]), float(a["credits"]),
		"Amplifiers next to Vaults serve nothing and must lose to Drills")


func test_the_amplifier_board_is_not_the_only_answer() -> void:
	# Factorio rebuilt its beacon maths in 2.0 because linear stacking made
	# one layout correct everywhere and building "feel monotonous" (FFF #409).
	# The deep chain has to still win somewhere, or the Amplifier discovery
	# has replaced one dominant board with another.
	var woven: Array = ["dmdmdmd", "ccccccc", "sssssss", "vvvvvvv",
		"dmdmdmd", "ccccccc", "sssssss", "vvvvvvv", "ddddddd", "ccccccc"]
	var deep: Array = ["ddddddd", "ccccccc", "sssssss", "ppppppp",
		"aaaaaaa", "vvlvlvv", "ddddddd", "ccccccc", "sssssss", "vvvvvvv"]
	# Rich Vein doubles what Drills pull up, which is exactly when converting
	# the surplus through a longer chain beats speeding the head of it.
	var deep_wins: bool = false
	for d: int in [6, 9, 14]:
		var long_chain: float = float(_rate(_upgraded(deep, d), 45.0)["credits"])
		var amped: float = float(_rate(_upgraded(woven, d), 45.0)["credits"])
		if long_chain > amped:
			deep_wins = true
			break
	runner.check(deep_wins,
		"the long chain must beat the Amplifier board at some depth, or the "
		+ "board has one correct answer again")


## --- the Foreman ------------------------------------------------------------

func test_the_foreman_has_every_pose_and_draws_at_any_size() -> void:
	# One sheet, five poses; what can go wrong is a pose the sheet does not
	# have, or a size the drawing does not handle.
	runner.eq(Foreman.Pose.size(), 5, "idle, point, cheer, jump and alert")
	runner.check(IsoArt.texture(String(IsoArt.layout().get("foreman", {}).get("file", ""))) != null,
		"the Foreman's pose sheet is imported")
	var probe := Control.new()
	for px: float in [40.0, 86.0, 256.0]:
		for pose: int in range(Foreman.Pose.size()):
			# Drawing off-tree is a no-op rather than an error; what this
			# catches is a pose the match statement does not handle, which
			# would throw.
			Foreman.draw_at(probe, Rect2(0, 0, px, px), pose, 0.3)
	runner.check(true, "every pose draws at every size without throwing")
	probe.free()


## --- the Factory Core starts every shaft -----------------------------------------

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


func test_a_new_game_can_start_the_core_pays_for_the_first_two_machines() -> void:
	_new_game()
	# The dead end this replaced: nothing in the purse, a Drill at 15.
	runner.eq(Sim.credits, 0.0, "a new game opens with an empty purse")
	runner.check(not Sim.can_afford("drill"), "so the first Drill is out of reach")
	runner.check(Sim.power_core(), "bringing the Core online")
	runner.check(Sim.core_online, "leaves it online")
	runner.near(Sim.credits, Sim.core_reserve(), 0.001, "and pays out its reserve")
	runner.near(Sim.core_reserve(),
		MachineDB.cost_for("drill", 0) + MachineDB.cost_for("vault", 0), 0.001,
		"which is exactly a first Drill and a first Vault")
	runner.eq(Sim.lifetime_credits, 0.0, "a reserve is not earnings")
	runner.check(Sim.try_place(Grid.idx(19, 21), "drill"), "the Drill, in the yard")
	runner.check(Sim.try_place(Grid.idx(19, 22), "vault"), "and the Vault it sells through")
	runner.check(not Sim.power_core(), "the reserve is paid once a shaft")
	Save.wipe()


func test_a_collapse_darkens_the_core_and_the_next_shaft_starts_the_same_way() -> void:
	_new_game()
	Sim.power_core()
	Sim.max_depth = 12
	Sim.lifetime_credits = 1.0e9
	Sim._recompute()
	runner.check(Sim.can_collapse(), "a deep enough shaft can collapse")
	Sim.collapse()
	runner.check(not Sim.core_online, "the next shaft's Core is dark")
	runner.eq(Sim.credits, 0.0, "and its purse empty")
	runner.check(Sim.power_core(), "bringing it online")
	runner.check(Sim.can_afford("drill") and Sim.can_afford("vault"),
		"pays for the first two machines of the new shaft")
	Save.wipe()


func test_the_core_survives_a_save_and_older_saves_load_sensibly() -> void:
	_new_game()
	var d: Dictionary = Sim.to_dict()
	runner.eq(bool(d.get("core_online", true)), false, "a dark Core is saved dark")
	Sim.from_dict(d)
	runner.check(not Sim.core_online, "and loads dark")
	Sim.power_core()
	Sim.from_dict(Sim.to_dict())
	runner.check(Sim.core_online, "an online Core loads online")
	# A save written before the Core existed has no key at all.
	var old: Dictionary = Sim.to_dict()
	old.erase("core_online")
	old["grid"] = {"w": Grid.W, "h": Grid.H, "cells": {str(Grid.idx(2, 2)): "drill"}}
	Sim.from_dict(old)
	runner.check(Sim.core_online, "an older shaft with machines on it is running")
	old["grid"] = {"w": Grid.W, "h": Grid.H, "cells": {}}
	old["credits"] = 500.0
	Sim.from_dict(old)
	runner.check(Sim.core_online, "so is one with money to build with")
	old["credits"] = 0.0
	Sim.from_dict(old)
	runner.check(not Sim.core_online,
		"one with neither was the dead end: its Core starts dark and pays its reserve")
	Save.wipe()


## --- the yard -----------------------------------------------------------------------

func test_a_new_shaft_builds_in_a_small_yard_round_the_core() -> void:
	_new_game()
	Sim.power_core()
	runner.eq(Grid.W, 44, "a 44 x 44 board")
	runner.eq(Grid.H, 44, "")
	var open: int = 0
	for i in range(Grid.W * Grid.H):
		open += 1 if Sim.is_open(i) else 0
	runner.eq(open, 20, "a new shaft opens the one-tile ring round the Core: twenty tiles")
	runner.eq(BuildArea.size_at(0), Vector2i(6, 6), "a 6 x 6 square with the Core in it")
	for i in range(Grid.W * Grid.H):
		if BuildArea.is_core(i):
			runner.check(not Sim.is_open(i), "nothing is built on the Core's own block")
	runner.check(Sim.is_open(Grid.idx(19, 19)), "the ring's corner is yard")
	runner.check(not Sim.try_place(Grid.idx(4, 2), "drill"),
		"a machine cannot go outside it")
	runner.eq(Sim.credits, Sim.core_reserve(), "and a refused placement costs nothing")
	runner.check(not Sim.try_place(Grid.idx(21, 21), "drill"), "nor on the Core")
	runner.check(Sim.try_place(Grid.idx(19, 21), "drill"), "inside, it can")
	runner.check(not Sim.move_machine(Grid.idx(19, 21), Grid.idx(4, 2)),
		"nor can one be moved out of it")
	# The ring widens early and through the middle of a shaft, then every
	# few strata deep down until it is the whole board. It never shrinks.
	var sizes: Array[int] = []
	for d in range(0, 80):
		var n: int = 0
		for i in range(Grid.W * Grid.H):
			n += 1 if BuildArea.is_open(i, d) else 0
		sizes.append(n)
	runner.eq(sizes[1], 48, "stratum 1: two rings, 48 tiles")
	runner.eq(sizes[2], 84, "stratum 2: three rings, 84 tiles")
	runner.eq(sizes[4], 128, "stratum 4: four rings, 128 tiles")
	runner.eq(sizes[7], 180, "stratum 7: five rings, 180 tiles")
	runner.gt(float(sizes[10]), 180.0, "and wider from stratum 10")
	for d in range(1, sizes.size()):
		runner.gte(float(sizes[d]), float(sizes[d - 1]), "stratum %d never shrinks it" % d)
	runner.eq(sizes[sizes.size() - 1], Grid.W * Grid.H - 16,
		"deep enough, it is the whole board but the Core")
	for i in range(0, Grid.W * Grid.H, 7):
		if not BuildArea.is_core(i):
			runner.check(BuildArea.is_open(i, BuildArea.opens_at(i)),
				"a tile is open from the stratum it says it opens at")
	Save.wipe()


func test_the_yard_is_the_same_after_a_collapse() -> void:
	for i in range(0, Grid.W * Grid.H, 5):
		runner.eq(BuildArea.is_open(i, 3, 1), BuildArea.is_open(i, 3, 0),
			"a collapse does not change the yard's rule")


func test_a_seven_by_ten_save_lands_beside_the_core() -> void:
	var g := Grid.new()
	g.from_dict({"w": 7, "h": 10, "cells": {"0": "drill", "69": "vault"}})
	runner.eq(g.machine_at(Grid.idx(13, 17)), "drill", "the old top corner")
	runner.eq(g.machine_at(Grid.idx(19, 26)), "vault", "the old far corner, against the Core")
	for i: int in g.cells:
		runner.check(not BuildArea.is_core(i), "nothing lands on the Core")


func test_a_machine_outside_the_yard_from_an_older_save_keeps_working() -> void:
	_new_game()
	var d: Dictionary = Sim.to_dict()
	d["grid"] = {"w": Grid.W, "h": Grid.H, "cells": {
		str(Grid.idx(3, 0)): "drill", str(Grid.idx(4, 0)): "vault"}}
	d["core_online"] = true
	Sim.from_dict(d)
	runner.check(not Sim.is_open(Grid.idx(3, 0)), "the tiles are outside the yard")
	runner.eq(Sim.grid.machine_at(Grid.idx(3, 0)), "drill", "the machines are still there")
	var earned: float = 0.0
	for i in range(200):
		earned += float(Sim.sim.tick()["credits"])
	runner.gt(earned, 0.0, "and still earning")
	runner.check(Sim.sell(Grid.idx(4, 0)), "one can be sold")
	Save.wipe()
