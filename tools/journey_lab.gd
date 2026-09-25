extends SceneTree

## The player's first ten seconds, first ten minutes and first week, measured.
##
##   godot --headless --path . --script res://tools/journey_lab.gd
##
## Everything here plays the actual game: the real `Grid`, the real
## `Simulation`, the real `Strata` and `Economy`, at the real tick rate,
## against wall-clock seconds. No estimates. A "competent player" model buys
## the cheapest useful machine it can afford, descends the moment the quota is
## met, spends research as it arrives, and collapses on a stated rule.
##
## The question it exists to answer is not "is the game balanced". It is
## **"when does this game stop giving the player a new decision?"** -- because
## that moment, not the numbers, is when an idle game gets uninstalled.

const WARM_TICKS := 250
const SAMPLE_TICKS := 400

## What a reasonable player builds, per unlock tier. Not an optimal board --
## an obvious one, which is what a first-time player actually builds.
const PLAN_EARLY := ["drill", "vault", "drill", "crusher", "vault", "drill",
	"crusher", "vault", "drill", "crusher", "vault"]


class Run extends RefCounted:
	var grid: Grid
	var sim: Simulation
	var credits: float = 0.0
	var research: float = 0.0
	var cores: int = 0
	var depth: int = 0
	var max_depth: int = 0
	var lifetime: float = 0.0
	var upgrades: Dictionary = {}
	var elapsed: float = 0.0
	var placed: int = 0
	var collapses: int = 0
	## The machines this run has reached, as Sim.unlocked (Worklist reads it).
	var unlocked: Array = []
	var _blocked: Dictionary = {}
	var _blocked_depth: int = -1

	## `Strata.describe()` re-hashes and re-rolls the modifier table on every
	## call. Asking it ten times a second turned a ten-second measurement into
	## a ten-minute one.
	func blocked() -> Dictionary:
		if _blocked_depth != depth:
			_blocked = Strata.blocked_cells(depth)
			# The yard: a first shaft builds only on the ground it has reached.
			_blocked.merge(BuildArea.closed_cells(max_depth, collapses))
			_blocked_depth = depth
		return _blocked

	func _init() -> void:
		grid = Grid.new()
		sim = Simulation.new(grid, 20260923)
		# LODEWORKS_NO_YARD=1 measures the game as it was before the yard:
		# the whole board open from the first second.
		if OS.get_environment("LODEWORKS_NO_YARD") == "1":
			collapses = 1
		recompute()

	func mult() -> Dictionary:
		return Economy.multipliers(upgrades)

	func recompute() -> void:
		Strata.apply(sim, grid, Strata.describe(depth), mult())
		unlocked = MachineDB.unlocked_at(max_depth)

	## Sim's own questions, so Worklist can read a Run as it reads Sim.
	func can_afford(id: String) -> bool:
		return credits >= cost(id)

	func is_blocked(cell: int) -> bool:
		return blocked().has(cell)

	## Place what "What now?" names, on the first tile where it says it
	## works -- unless a step further along the chain is unlocked and has no
	## such tile, in which case the next step goes where it is fed, with a
	## Vault beside it for what it makes (what the Codex's chains teach).
	## false when there is nothing this run can pay for.
	func try_follow() -> bool:
		var best: Dictionary = Worklist.best_placement(self)
		var at: int = -1 if best.is_empty() else MachineDB.ORDER.find(String(best["id"]))
		if try_extend(at):
			return true
		if best.is_empty():
			return false
		var id: String = String(best["id"])
		var price: float = cost(id)
		if not grid.place(int(best["cell"]), id):
			return false
		credits -= price
		placed += 1
		return true

	## The furthest unlocked step past ORDER[after] that is fed on some empty
	## tile with an empty tile beside it: the step there, a Vault beside it.
	func try_extend(after: int) -> bool:
		var yard: Array[int] = BuildArea.cells(max_depth)
		for k in range(MachineDB.ORDER.size() - 1, after, -1):
			var id: String = String(MachineDB.ORDER[k])
			var m: Dictionary = MachineDB.get_machine(id)
			if not unlocked.has(id) or (m["inputs"] as Dictionary).is_empty() 					or (m["outputs"] as Dictionary).is_empty():
				continue
			if credits < cost(id) + cost("vault"):
				continue
			for cell: int in yard:
				if not grid.is_empty(cell) or is_blocked(cell):
					continue
				if not bool(sim.links_if_placed(cell, id)["fed"]):
					continue
				for u: int in grid.neighbours(cell):
					if yard.has(u) and grid.is_empty(u) and not is_blocked(u):
						var price: float = cost(id) + cost("vault")
						grid.place(cell, id)
						grid.place(u, "vault")
						credits -= price
						placed += 2
						return true
		return false

	var _quota: float = -1.0
	var _quota_depth: int = -1

	func quota() -> float:
		if _quota_depth != depth:
			_quota = float(Strata.describe(depth)["quota"])
			_quota_depth = depth
		return _quota

	func tick() -> void:
		var out: Dictionary = sim.tick()
		var c: float = float(out["credits"])
		credits += c
		lifetime += c
		research += float(out["research"])
		elapsed += Simulation.TICK_DT

	func rate() -> float:
		var c: float = 0.0
		for _i in range(SAMPLE_TICKS):
			var out: Dictionary = sim.tick()
			c += float(out["credits"])
		return c / (float(SAMPLE_TICKS) * Simulation.TICK_DT)

	func cost(id: String) -> float:
		return MachineDB.cost_for(id, grid.count_of(id))

	## Where the row plan wants this machine next.
	##
	## A competent player does not fill the board in reading order -- they
	## build in rows, each row feeding the one below, which is the `shallow`
	## archetype that `tools/money_lab.gd` measured as the best board at most
	## depths. Modelling anything dumber measures the model, not the game.
	func place_row(id: String, rows: Array) -> bool:
		var b: Dictionary = blocked()
		for y in range(Grid.H):
			if String(rows[y % rows.size()]) != id:
				continue
			for x in range(Grid.W):
				var i: int = Grid.idx(x, y)
				if b.has(i) or not grid.is_empty(i):
					continue
				if grid.place(i, id):
					placed += 1
					return true
		return false

	## The obvious extension: put the machine on the frontier, next to
	## something it can talk to, in reading order.
	func place_best(id: String) -> bool:
		var blocked: Dictionary = blocked()
		var best: int = -1
		for i in range(Grid.W * Grid.H):
			if blocked.has(i) or not grid.is_empty(i):
				continue
			if grid.neighbour_machines(i).is_empty() and placed > 0:
				continue
			best = i
			break
		if best < 0:
			for i in range(Grid.W * Grid.H):
				if not blocked.has(i) and grid.is_empty(i):
					best = i
					break
		if best < 0:
			return false
		if not grid.place(best, id):
			return false
		placed += 1
		return true

	func try_buy(plan: Array) -> bool:
		var unlocked: Array[String] = MachineDB.unlocked_at(depth)
		var want: String = String(plan[placed % plan.size()])
		if not unlocked.has(want):
			want = "drill"
		var price: float = cost(want)
		if credits < price:
			return false
		# Paid only for a machine that found a tile. Paying first threw the
		# price away every beat once the yard was full, which read as a wall
		# at stratum 7 that the game does not have: `Sim.try_place` refuses
		# a closed tile without charging.
		if not place_best(want):
			return false
		credits -= price
		return true

	## Build the board the row plan describes, cheapest missing tile first.
	func try_build_rows(rows: Array) -> bool:
		var unlocked: Array[String] = MachineDB.unlocked_at(depth)
		var best: String = ""
		var best_cost: float = INF
		for y in range(Grid.H):
			var id: String = String(rows[y % rows.size()])
			if not unlocked.has(id):
				continue
			var free: bool = false
			var b: Dictionary = blocked()
			for x in range(Grid.W):
				var i: int = Grid.idx(x, y)
				if not b.has(i) and grid.is_empty(i):
					free = true
					break
			if not free:
				continue
			var c: float = cost(id)
			if c < best_cost:
				best_cost = c
				best = id
		if best == "" or credits < best_cost:
			return false
		credits -= best_cost
		return place_row(best, rows)

	func try_upgrade() -> String:
		for id: String in Economy.TREE_ORDER:
			var u: Dictionary = Economy.RESEARCH_TREE[id]
			var lvl: int = int(upgrades.get(id, 0))
			if lvl >= int(u["max"]):
				continue
			var c: Dictionary = Economy.upgrade_cost(id, lvl)
			if research >= float(c["research"]) and cores >= int(c["cores"]):
				research -= float(c["research"])
				cores -= int(c["cores"])
				upgrades[id] = lvl + 1
				recompute()
				return id
		return ""

	func try_descend() -> bool:
		if credits < quota():
			return false
		credits -= quota()
		depth += 1
		max_depth = maxi(max_depth, depth)
		recompute()
		return true

	func pending_cores() -> int:
		return Economy.cores_for_collapse(max_depth, lifetime,
			float(mult().get("core_yield", 0.0)))

	func collapse() -> int:
		var got: int = pending_cores()
		cores += got
		collapses += 1
		_blocked_depth = -1
		grid.clear()
		sim.reset_progress()
		credits = 0.0
		research = 0.0
		lifetime = 0.0
		depth = 0
		max_depth = 0
		placed = 0
		recompute()
		return got


## --- 1. the first ten seconds ---------------------------------------------

func _opening() -> void:
	print("\n== 0-10 SECONDS ==")
	var r := Run.new()
	# The tutorial hands the player a Drill first. Everything before this is
	# one tap on an armed palette button.
	r.grid.place(Grid.idx(3, 0), "drill")
	r.placed = 1
	var first_credit: float = -1.0
	var t: float = 0.0
	while t < 60.0:
		r.tick()
		t += Simulation.TICK_DT
		if r.credits > 0.0 and first_credit < 0.0:
			first_credit = t
			break
	print("   board at t=0: 1 Drill (the tutorial's first instruction)")
	print("   a lone Drill earns: %s" % ("never -- it has nowhere to sell"
		if first_credit < 0.0 else "%.1fs" % first_credit))
	# Which is the point: the second machine is not a suggestion, it is the
	# only way anything happens at all.
	var r2 := Run.new()
	r2.grid.place(Grid.idx(3, 0), "drill")
	r2.grid.place(Grid.idx(3, 1), "vault")
	r2.placed = 2
	var fc: float = -1.0
	t = 0.0
	while t < 60.0:
		r2.tick()
		t += Simulation.TICK_DT
		if r2.credits > 0.0 and fc < 0.0:
			fc = t
			break
	print("   Drill + Vault first credit: %.1fs" % fc)
	print("   cost of machine 3 (a Drill): %.0f credits" % r2.cost("drill"))
	var to_third: float = 0.0
	while r2.credits < r2.cost("drill") and to_third < 300.0:
		r2.tick()
		to_third += Simulation.TICK_DT
	print("   afforded at: %.1fs from the first credit" % to_third)


## --- 2. the first ten minutes ---------------------------------------------

func _first_session() -> void:
	print("\n== 10 SECONDS - 30 MINUTES ==")
	var r := Run.new()
	r.grid.place(Grid.idx(19, 21), "drill")
	r.grid.place(Grid.idx(19, 22), "vault")
	r.placed = 2
	var marks := [10.0, 60.0, 180.0, 600.0, 1800.0]
	# LODEWORKS_JOURNEY_SECONDS runs the same player for longer, to see the
	# pace past the first half hour.
	var horizon: float = maxf(float(OS.get_environment("LODEWORKS_JOURNEY_SECONDS")), 1800.0)
	if horizon > 1800.0:
		marks.append(horizon)
	var mark: int = 0
	var events: Array = []
	var gaps: Array[String] = []
	var last_t: float = 0.0
	var last_depth: int = 0
	var t: float = 0.0
	var beat: int = 0
	while t < horizon:
		r.tick()
		t += Simulation.TICK_DT
		beat += 1
		if r.try_descend():
			var unlocked: Array = []
			for id: String in MachineDB.unlocked_at(r.depth):
				if not MachineDB.unlocked_at(r.depth - 1).has(id):
					unlocked.append(id)
			events.append("%6.0fs  descend to stratum %d  (%d machines)%s" % [t, r.depth,
				r.placed, "" if unlocked.is_empty() else "  UNLOCKS " + ", ".join(unlocked)])
			gaps.append("%d:%.0f" % [r.depth, t - last_t])
			last_t = t
			last_depth = r.depth
		if beat % 5 == 0:
			var up: String = r.try_upgrade()
			if up != "":
				events.append("%6.0fs  research: %s" % [t,
					String(Economy.RESEARCH_TREE[up]["name"])])
			r.try_buy(PLAN_EARLY)
		if mark < marks.size() and t >= float(marks[mark]):
			print("   t=%-6s machines %2d  stratum %d  credits %8s  research %6s"
				% [Economy.fmt_duration(float(marks[mark])), r.placed, r.depth,
					Economy.fmt(r.credits), Economy.fmt(r.research)])
			mark += 1
	print("")
	for e: String in events:
		print("   " + String(e))
	print("")
	print("   seconds per stratum (reached:taken): " + " ".join(gaps))
	print("   after %s: stratum %d, %d machines, collapse %s"
		% [Economy.fmt_duration(horizon), r.depth, r.placed,
			"available (%d Cores)" % r.pending_cores() if Economy.can_collapse(
				r.max_depth) else "not yet"])


## --- 3. the first week ----------------------------------------------------
##
## The number this whole file was written for: how long the permanent
## progression lasts. A permanent tree that finishes is a game that ends.

func _long_game() -> void:
	print("\n== THE LONG GAME: how many runs until the permanent tree is done ==")
	var tree_cost_cores: int = 0
	var tree_cost_research: float = 0.0
	for id: String in Economy.RESEARCH_TREE:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		for lvl: int in range(int(u["max"])):
			var c: Dictionary = Economy.upgrade_cost(id, lvl)
			tree_cost_cores += int(c["cores"])
			tree_cost_research += float(c["research"])
	print("   the whole permanent tree costs %d Cores and %s Research"
		% [tree_cost_cores, Economy.fmt(tree_cost_research)])

	# Drill -> Crusher -> Vault, three rows repeated down the shaft. Chosen
	# because it is buildable at every depth including depth 0, so the model
	# never deadlocks waiting for an unlock. It is the `raw` archetype, which
	# `tools/strategy_lab.gd` scores BELOW every other board -- so the Cores
	# below are a floor, and a better player banks more than this says.
	var rows: Array = ["drill", "crusher", "vault"]
	var r := Run.new()
	r.grid.place(Grid.idx(0, 0), "drill")
	r.grid.place(Grid.idx(0, 1), "crusher")
	r.grid.place(Grid.idx(0, 2), "vault")
	r.placed = 3
	var t: float = 0.0
	var stalled: float = 0.0
	var beat: int = 0
	while t < 5400.0:
		r.tick()
		t += Simulation.TICK_DT
		if r.try_descend():
			stalled = 0.0
		else:
			stalled += Simulation.TICK_DT
		beat += 1
		if beat % int(Simulation.TICK_HZ) == 0:
			r.try_upgrade()
			r.try_build_rows(rows)
		if stalled > 1200.0:
			break
	print("   one run, played out in full: %s to stratum %d, %s lifetime credits"
		% [Economy.fmt_duration(t), r.max_depth, Economy.fmt(r.lifetime)])
	print("   collapsing there pays %d Cores." % r.pending_cores())
	print("")
	# Projected rather than simulated from here: playing forty more runs at
	# tick resolution costs more than the answer is worth, and once the
	# per-run yield is measured the rest is arithmetic.
	var bank: int = 0
	var runs: int = 0
	var spent: Dictionary = {}
	var core_upgrades: int = 0
	for id: String in Economy.RESEARCH_TREE:
		if int(Economy.upgrade_cost(id, 0)["cores"]) > 0:
			core_upgrades += 1
	while runs < 60:
		runs += 1
		bank += Economy.cores_for_collapse(r.max_depth, r.lifetime,
			0.25 * float(spent.get("core_yield", 0)))
		var bought: bool = true
		while bought:
			bought = false
			for id: String in Economy.TREE_ORDER:
				var u: Dictionary = Economy.RESEARCH_TREE[id]
				var lvl: int = int(spent.get(id, 0))
				if lvl >= int(u["max"]):
					continue
				var c: int = int(Economy.upgrade_cost(id, lvl)["cores"])
				if c > 0 and bank >= c:
					bank -= c
					spent[id] = lvl + 1
					bought = true
		var maxed: int = 0
		for id: String in Economy.RESEARCH_TREE:
			if int(Economy.upgrade_cost(id, 0)["cores"]) <= 0:
				continue
			if int(spent.get(id, 0)) >= int(Economy.RESEARCH_TREE[id]["max"]):
				maxed += 1
		if runs <= 6 or maxed == core_upgrades:
			print("   after collapse %2d: %3d Cores banked, %d/%d permanent upgrades maxed"
				% [runs, bank, maxed, core_upgrades])
		if maxed == core_upgrades:
			print("   PERMANENT TREE FINISHED after %d collapses." % runs)
			break
	print("   (projected from the measured yield above at a fixed depth;")
	print("    a player who descends further finishes sooner.)")

## --- 3b. collapse after collapse, played ----------------------------------
##
## The long game above plays one run and projects the rest. This plays them:
## every run from a dark Core and its reserve (the tutorial's Drill and
## Vault), then a player who builds only what the game's own "What now?"
## names, where it says it works (Worklist.best_placement), Research spent as
## it arrives, and the Cores spent the moment they buy a level -- so a run is
## faster than the one before it by exactly what the tree bought. The player
## collapses when the quota has stalled for STALL seconds of play. Lines the
## game does not offer (Worklist.HIDDEN) are neither bought nor counted.
##
##   LODEWORKS_JOURNEY=collapses godot --headless --path . --script res://tools/journey_lab.gd
##   LODEWORKS_COLLAPSES=n (default 8), LODEWORKS_COLLAPSE_STALL=seconds (default 900)

func _collapses() -> void:
	var runs_max: int = maxi(int(OS.get_environment("LODEWORKS_COLLAPSES")), 0)
	if runs_max == 0:
		runs_max = 8
	var stall_limit: float = float(OS.get_environment("LODEWORKS_COLLAPSE_STALL"))
	if stall_limit <= 0.0:
		stall_limit = 900.0
	print("\n== COLLAPSE AFTER COLLAPSE, played (stall %s, up to %d runs) =="
		% [Economy.fmt_duration(stall_limit), runs_max])
	var lines: Array[String] = []
	var tree_cores: int = 0
	for id: String in Economy.TREE_ORDER:
		if Worklist.HIDDEN.has(id):
			continue
		lines.append(id)
		for lvl: int in range(int(Economy.RESEARCH_TREE[id]["max"])):
			tree_cores += int(Economy.upgrade_cost(id, lvl)["cores"])
	print("   the tree the game offers: %d lines, %d Cores in all" % [lines.size(), tree_cores])
	print("   %-4s %-9s %-6s %-9s %-6s %-9s %-7s %s" % ["run", "length", "depth",
		"lifetime", "Cores", "Cores/h", "levels", "played"])
	var r := Run.new()
	var played: float = 0.0
	var spent_cores: int = 0
	for run: int in range(1, runs_max + 1):
		# The Core's reserve buys exactly the tutorial's Drill and Vault, beside
		# the Core; from there the player follows the list.
		r.grid.place(Grid.idx(19, 21), "drill")
		r.grid.place(Grid.idx(19, 22), "vault")
		r.placed = 2
		var t: float = 0.0
		var stalled: float = 0.0
		var beat: int = 0
		while t < 4.0 * 3600.0:
			r.tick()
			t += Simulation.TICK_DT
			if r.try_descend():
				stalled = 0.0
			else:
				stalled += Simulation.TICK_DT
			beat += 1
			# Every two seconds: spend what research buys, then up to three
			# machines the list names.
			if beat % 20 == 0:
				while _buy_offered(r, lines) != "":
					pass
				for _k in range(3):
					if not r.try_follow():
						break
			if stalled >= stall_limit and Economy.can_collapse(r.max_depth):
				break
		var depth: int = r.max_depth
		var lifetime: float = r.lifetime
		var board: Array[String] = []
		for id: String in MachineDB.ORDER:
			if r.grid.count_of(id) > 0:
				board.append("%s %d" % [id, r.grid.count_of(id)])
		var got: int = r.collapse()
		played += t
		var before: int = r.cores
		while _buy_offered(r, lines) != "":
			pass
		spent_cores += before - r.cores
		var levels: int = 0
		var maxed: int = 0
		for id: String in lines:
			levels += int(r.upgrades.get(id, 0))
			if int(r.upgrades.get(id, 0)) >= int(Economy.RESEARCH_TREE[id]["max"]):
				maxed += 1
		print("   %-4d %-9s %-6d %-9s %-6d %-9.1f %-7s %s" % [run, Economy.fmt_duration(t),
			depth, Economy.fmt(lifetime), got, float(got) / (t / 3600.0),
			"%d (%d/%d)" % [levels, maxed, lines.size()], Economy.fmt_duration(played)])
		print("        board: " + ", ".join(board))
		if maxed == lines.size():
			print("   THE TREE IS DONE after %d collapses and %s of play." % [run,
				Economy.fmt_duration(played)])
			return
	print("   after %d collapses: %d of %d Cores of the tree bought, %s of play."
		% [runs_max, spent_cores, tree_cores, Economy.fmt_duration(played)])


## The first line the game offers that the run can pay for, bought; "" if none.
func _buy_offered(r: Run, lines: Array[String]) -> String:
	for id: String in lines:
		var lvl: int = int(r.upgrades.get(id, 0))
		if lvl >= int(Economy.RESEARCH_TREE[id]["max"]):
			continue
		var c: Dictionary = Economy.upgrade_cost(id, lvl)
		if r.research >= float(c["research"]) and r.cores >= int(c["cores"]):
			r.research -= float(c["research"])
			r.cores -= int(c["cores"])
			r.upgrades[id] = lvl + 1
			r.recompute()
			return id
	return ""


## --- 4. what is new at each depth -----------------------------------------

func _novelty() -> void:
	print("\n== WHAT IS ACTUALLY NEW AT EACH DEPTH ==")
	print("   %-6s %-34s %s" % ["depth", "modifiers", "new machine"])
	var last_new: int = 0
	for d: int in range(0, 25):
		var st: Dictionary = Strata.describe(d)
		var names: Array = []
		for m: String in st["modifiers"]:
			names.append(Strata.modifier_name(m))
		var newm: Array = []
		for id: String in MachineDB.unlocked_at(d):
			if d == 0 or not MachineDB.unlocked_at(d - 1).has(id):
				newm.append(id)
		if not newm.is_empty() and d > 0:
			last_new = d
		print("   %-6d %-34s %s" % [d,
			"—" if names.is_empty() else ", ".join(names),
			"—" if newm.is_empty() else ", ".join(newm)])
	print("")
	print("   LAST new machine at depth %d. Past it, a stratum is a quota, a"
		% last_new)
	print("   richness number and a modifier pair -- and modifier pairs repeat.")
	var seen: Dictionary = {}
	var repeats: int = 0
	for d: int in range(1, 60):
		var key: String = ",".join(Strata.modifiers_for(d))
		if seen.has(key):
			repeats += 1
		seen[key] = true
	print("   over 60 strata: %d distinct modifier sets, %d repeats"
		% [seen.size(), repeats])


## --- 5. what the prestige currency is actually for ------------------------

func _prestige_audit() -> void:
	print("\n== THE PRESTIGE LAYER, AUDITED ==")
	var cores_total: int = 0
	var research_total: float = 0.0
	var core_gated: Array[String] = []
	for id: String in Economy.TREE_ORDER:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		var c_sum: int = 0
		var r_sum: float = 0.0
		for lvl: int in range(int(u["max"])):
			var c: Dictionary = Economy.upgrade_cost(id, lvl)
			c_sum += int(c["cores"])
			r_sum += float(c["research"])
		cores_total += c_sum
		research_total += r_sum
		if c_sum > 0:
			core_gated.append(id)
		print("   %-16s %d levels  %8s research  %4d Cores"
			% [id, int(u["max"]), Economy.fmt(r_sum), c_sum])
	print("   TOTAL                     %8s research  %4d Cores"
		% [Economy.fmt(research_total), cores_total])
	print("")
	print("   %d of %d upgrades cost any Cores at all."
		% [core_gated.size(), Economy.RESEARCH_TREE.size()])
	print("   Cores from one collapse at a few depths, with 50K lifetime credits:")
	for d: int in [3, 5, 8, 12, 16, 20]:
		print("      depth %-3d %6d Cores  (the ENTIRE tree costs %d)"
			% [d, Economy.cores_for_collapse(d, 50000.0, 0.0), cores_total])


## --- 6. how long does Research actually take? -----------------------------

func _research_curve() -> void:
	print("\n== RESEARCH: the real gate on the permanent tree ==")
	# A finished board rather than a growing one: the question is what a
	# player who has already built their research line earns per second, not
	# how long the building takes.
	var rows: Array = ["drill", "crusher", "smelter", "press", "assembler",
		"lab", "vault", "drill", "crusher", "vault"]
	var total: float = 0.0
	for id: String in Economy.RESEARCH_TREE:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		for lvl: int in range(int(u["max"])):
			total += float(Economy.upgrade_cost(id, lvl)["research"])
	for d: int in [6, 10, 16]:
		var r := Run.new()
		r.depth = d
		r.max_depth = d
		r.recompute()
		var b: Dictionary = r.blocked()
		# Start the row cycle at the first usable row. A Cramped stratum
		# blocks the outer ring, and a filler that ignores that puts a
		# Crusher on the top row with no Drill above it -- which produces
		# nothing and would have been read as a balance finding rather than
		# as a bug in the measuring tool.
		var first: int = 0
		while first < Grid.H and b.has(Grid.idx(1, first)):
			first += 1
		for y in range(Grid.H):
			for x in range(Grid.W):
				var i: int = Grid.idx(x, y)
				if not b.has(i):
					r.grid.place(i, String(rows[(y - first) % rows.size()]))
		for _w in range(300):
			r.sim.tick()
		var res: float = 0.0
		var cr: float = 0.0
		for _i in range(600):
			var o: Dictionary = r.sim.tick()
			res += float(o["research"])
			cr += float(o["credits"])
		var secs: float = 600.0 * Simulation.TICK_DT
		var rps: float = res / secs
		print("   depth %-3d finished board: %6.2f research/s, %8s credits/s"
			% [d, rps, Economy.fmt(cr / secs)])
		print("            -> %s of unbroken play to finish the tree ONCE"
			% ("never" if rps <= 0.0 else Economy.fmt_duration(total / rps)))
	print("   ...and a collapse takes every point of it back to zero.")


func _initialize() -> void:
	print("Lodeworks -- the player journey, measured")
	print("model: %s" % MachineDB.ACTIVE_MODEL)
	if OS.get_environment("LODEWORKS_JOURNEY") == "collapses":
		_collapses()
		quit()
		return
	_opening()
	_first_session()
	# LODEWORKS_JOURNEY=first: the first half hour and nothing after it.
	if OS.get_environment("LODEWORKS_JOURNEY") == "first":
		quit()
		return
	_novelty()
	_prestige_audit()
	_research_curve()
	_long_game()
	print("")
	quit()
