extends SceneTree

## Where, in this economy, would a player genuinely feel value?
##
##   godot --headless --path . --script res://tools/money_lab.gd
##
## The brief for a monetization round is usually "add a shop". That produces a
## shop. The question this file asks instead is the one that decides whether a
## shop is worth building at all: **at which moments does this specific game
## already create a feeling the player would pay to change?**
##
## It answers that by measuring, not by guessing:
##
##   1. Does the player ever WAIT?  A wait is the thing every predatory idle
##      game sells back. If Lodeworks has no wait, it has no timer to sell and
##      must earn money some other way -- which is a finding, not a failure.
##   2. What is an hour offline actually worth against an hour played?  That
##      sets the honest ceiling on what an offline product may offer.
##   3. How many distinct layouts does the strategy space reward?  That says
##      whether blueprint slots are a real constraint or an invented one.
##   4. How long is a run, and what does a collapse hand back?  That says
##      whether there is a "between runs" moment at all.
##
## Every number printed here comes out of the same Simulation the game runs.

const WARM := 25.0
const SAMPLE := 40.0

const STARTER := [[3, 0, "drill"], [3, 1, "vault"]]

const KEY := {
	"d": "drill", "c": "crusher", "s": "smelter", "p": "press",
	"a": "assembler", "v": "vault", "l": "lab", "b": "boiler",
	"o": "coolant", "m": "amplifier", "u": "duplicator", "n": "condenser",
}


func _board(rows: Array, depth: int, upgrades: Dictionary) -> Simulation:
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	var st: Dictionary = Strata.describe(depth)
	var mu: Dictionary = Economy.multipliers(upgrades)
	Strata.apply(s, g, st, mu)
	for y: int in range(rows.size()):
		var row: String = String(rows[y])
		for x: int in range(mini(row.length(), Grid.W)):
			var ch: String = row[x]
			if KEY.has(ch):
				g.place(Grid.idx(x, y), String(KEY[ch]))
	return s


func _pairs(pairs: Array, depth: int, upgrades: Dictionary) -> Simulation:
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	var st: Dictionary = Strata.describe(depth)
	var mu: Dictionary = Economy.multipliers(upgrades)
	Strata.apply(s, g, st, mu)
	for p: Array in pairs:
		g.place(Grid.idx(int(p[0]), int(p[1])), String(p[2]))
	return s


func _rate(s: Simulation) -> Dictionary:
	for i: int in range(int(WARM * Simulation.TICK_HZ)):
		s.tick()
	var c: float = 0.0
	var r: float = 0.0
	var n: int = int(SAMPLE * Simulation.TICK_HZ)
	for i: int in range(n):
		var o: Dictionary = s.tick()
		c += float(o["credits"])
		r += float(o["research"])
	return {"credits": c / SAMPLE, "research": r / SAMPLE}


## --- 1. does the player ever wait? ----------------------------------------
##
## Plays the actual opening: a Drill and a Vault, then buy whatever the board
## can afford next, forever. Records the gap between purchases. A rising gap
## is a wall; a flat or falling gap is a game that never asks you to stop.
func _waiting() -> void:
	print("\n== 1. WAITING: seconds between affordable purchases ==")
	print("   (the opening board, greedily buying the cheapest useful machine)")
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	var st: Dictionary = Strata.describe(0)
	Strata.apply(s, g, st, {})
	for p: Array in STARTER:
		g.place(Grid.idx(int(p[0]), int(p[1])), String(p[2]))

	var credits: float = 0.0
	var spent: float = 0.0
	var placed: int = 2
	var elapsed: float = 0.0
	var last_buy: float = 0.0
	var gaps: Array = []
	# The order a real player extends the opening: alternate a producer and a
	# sink outward from the first pair, which is what the tutorial teaches.
	var plan: Array = []
	for y: int in range(Grid.H):
		for x: int in range(Grid.W):
			if x == 3 and y <= 1:
				continue
			plan.append([x, y, "drill" if (x + y) % 2 == 0 else "vault"])
	var next: int = 0
	while elapsed < 3600.0 and next < plan.size() and placed < 40:
		var o: Dictionary = s.tick()
		credits += float(o["credits"])
		elapsed += Simulation.TICK_DT
		var want: Array = plan[next]
		var price: float = MachineDB.cost_for(String(want[2]), g.count_of(String(want[2])))
		if credits >= price:
			credits -= price
			spent += price
			g.place(Grid.idx(int(want[0]), int(want[1])), String(want[2]))
			placed += 1
			gaps.append(elapsed - last_buy)
			last_buy = elapsed
			next += 1
	var line: String = ""
	for i: int in range(gaps.size()):
		line += "%.0f " % float(gaps[i])
	print("   purchases: %d in %s" % [gaps.size(), Economy.fmt_duration(elapsed)])
	print("   gaps (s): %s" % line)
	if gaps.size() >= 6:
		var early: float = 0.0
		for i: int in range(3):
			early += float(gaps[i])
		var late: float = 0.0
		for i: int in range(gaps.size() - 3, gaps.size()):
			late += float(gaps[i])
		print("   first three avg %.1fs -> last three avg %.1fs" % [early / 3.0, late / 3.0])


## --- 2. what is time away worth? ------------------------------------------
func _offline() -> void:
	print("\n== 2. OFFLINE: what an hour away is worth against an hour played ==")
	var boards := {
		"opening (2 machines)": STARTER,
	}
	for name: String in boards.keys():
		var s: Simulation = _pairs(boards[name], 0, {})
		var r: Dictionary = _rate(s)
		print("   %s live %.2f/s" % [name, float(r["credits"])])
	var mult0: Dictionary = Economy.multipliers({})
	var full: Dictionary = Economy.multipliers({"offline_cap": 6, "offline_rate": 4})
	for label: String in ["no upgrades", "offline tree maxed"]:
		var m: Dictionary = mult0 if label == "no upgrades" else full
		var hours: float = float(m["offline_hours"])
		var rate: float = float(m["offline_rate"])
		print("   %-18s cap %.0fh, banks %.0f%% of live rate" % [label, hours, rate * 100.0])
		print("      %-16s 8h away  = %5.2f h of live play" % ["", minf(8.0, hours) * rate]) 
		print("      %-16s with ad x2         = %5.2f h of live play" % ["", minf(8.0, hours) * rate * 2.0])
		print("      %-16s full cap           = %5.2f h of live play" % ["", hours * rate])
		print("      %-16s full cap with x2   = %5.2f h of live play" % ["", hours * rate * 2.0])


## --- 3. how many layouts does the game actually reward? -------------------
func _layouts() -> void:
	print("\n== 3. LAYOUTS: does one board win everywhere, or does depth change it? ==")
	var arche := {
		"raw": ["ddddddd", "ccccccc", "vvvvvvv", "ddddddd", "ccccccc",
			"vvvvvvv", "ddddddd", "ccccccc", "vvvvvvv", "......."],
		"shallow": ["ddddddd", "ccccccc", "sssssss", "vvvvvvv", "ddddddd",
			"ccccccc", "sssssss", "vvvvvvv", ".......", "......."],
		"deep_columns": ["ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa",
			"vvlvlvv", ".......", ".......", ".......", "......."],
		"lab_heavy": ["ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa",
			"lllllll", "vvvvvvv", ".......", ".......", "......."],
		"cool_deep": ["ddddddd", "cocococ", "sssssss", "popopop", "aaaaaaa",
			"vvlvlvv", ".......", ".......", ".......", "......."],
	}
	var upg := {"throughput_1": 3, "yield_1": 2, "value_1": 2, "research_1": 1,
		"heat_tolerance": 1}
	print("   %-14s %10s %10s %10s" % ["archetype", "d3 cr/s", "d9 cr/s", "d16 cr/s"])
	var winners: Dictionary = {}
	for name: String in arche.keys():
		var line: String = "   %-14s" % name
		for d: int in [3, 9, 16]:
			var s: Simulation = _board(arche[name], d, upg)
			var r: Dictionary = _rate(s)
			var v: float = float(r["credits"])
			line += " %10.1f" % v
			var best: float = float(winners.get(str(d), {}).get("v", -1.0))
			if v > best:
				winners[str(d)] = {"v": v, "n": name}
		print(line)
	var distinct: Dictionary = {}
	for d: String in winners.keys():
		distinct[String(winners[d]["n"])] = true
		print("   depth %-3s best: %s" % [d, winners[d]["n"]])
	print("   distinct winning layouts across depths: %d" % distinct.size())


## --- 4. the run and the collapse ------------------------------------------
func _run_shape() -> void:
	print("\n== 4. RUN SHAPE: what a collapse hands back ==")
	print("   %-8s %-14s %8s %8s" % ["depth", "lifetime cr", "cores", "cores+tree"])
	for d: int in [3, 6, 9, 12, 16]:
		for lc: float in [5000.0, 50000.0, 500000.0]:
			var a: int = Economy.cores_for_collapse(d, lc, 0.0)
			var b: int = Economy.cores_for_collapse(d, lc, 1.25)
			print("   %-8d %-14s %8d %8d" % [d, Economy.fmt(lc), a, b])
	var tree_cost: int = 0
	for id: String in Economy.RESEARCH_TREE:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		for lvl: int in range(int(u["max"])):
			tree_cost += int(Economy.upgrade_cost(id, lvl)["cores"])
	print("   total Cores to finish the permanent tree: %d" % tree_cost)


## --- 5. blueprint pressure -------------------------------------------------
func _blueprints() -> void:
	print("\n== 5. BLUEPRINT SLOTS: is the limit real? ==")
	var m0: Dictionary = Economy.multipliers({})
	var m3: Dictionary = Economy.multipliers({"blueprint_slots": 3})
	print("   base slots            %d" % int(float(m0["blueprints"])))
	print("   with Drafting Table 3 %d" % int(float(m3["blueprints"])))
	print("   licence adds          %d" % int(MonetizationDB.grant_value(
		MonetizationDB.LICENCE, MonetizationDB.GRANT_BLUEPRINT_SLOTS, 0)))
	print("   strategies the board rewards (from section 3 winners) decides")
	print("   whether that ceiling is ever felt.")


## --- 6. does paying break the economy? ------------------------------------
##
## The question the whole design rests on, answered by playing it rather than
## by reasoning about it. Four players, the same board, the same number of
## sessions, over a fortnight:
##
##   free            never watches an ad
##   free + ad       watches the offline double every session
##   licensed        bought the Licence (ads gone, cap doubled)
##   licensed later  bought it on day 7
##
## What matters is not which is biggest -- of course paying is worth
## something, or nobody would pay. What matters is the RATIO, because that is
## the number that decides whether a free player is playing the same game.
func _parity() -> void:
	print("\n== 6. PARITY: free against paying, over a fortnight ==")
	var s: Simulation = _pairs(STARTER, 0, {})
	var warm: Dictionary = _rate(s)
	var live_rate: float = float(warm["credits"])
	print("   reference board live rate: %.2f credits/s" % live_rate)

	const DAYS := 14
	const SESSIONS_PER_DAY := 2
	const SESSION_SECONDS := 900.0        # fifteen minutes, twice a day
	var away: float = (86400.0 / float(SESSIONS_PER_DAY)) - SESSION_SECONDS

	var base: Dictionary = Economy.multipliers({})
	var licence_hours: float = float(MonetizationDB.grant_value(
		MonetizationDB.LICENCE, MonetizationDB.GRANT_OFFLINE_HOURS, 0.0))

	var runs := {
		"free": {"licence_from": 9999, "ad": false},
		"free + ad": {"licence_from": 9999, "ad": true},
		"licensed": {"licence_from": 0, "ad": false},
		# Bought it halfway, having never watched an ad before that.
		"licensed day 7": {"licence_from": 7, "ad": false},
	}
	var totals: Dictionary = {}
	for name: String in runs.keys():
		var cfg: Dictionary = runs[name]
		var total: float = 0.0
		var offline_total: float = 0.0
		for day: int in range(DAYS):
			var licensed: bool = day >= int(cfg["licence_from"])
			var mult: Dictionary = base.duplicate()
			if licensed:
				mult["offline_hours"] = float(base["offline_hours"]) + licence_hours
			for sess: int in range(SESSIONS_PER_DAY):
				# Live play is identical for everyone. This is the assertion
				# the tests make, measured here in credits.
				total += live_rate * SESSION_SECONDS
				# An ad is only offered to someone without the licence, so a
				# licensed player never doubles on top of the bigger cap.
				var doubled: bool = bool(cfg["ad"]) and not licensed
				var off: Dictionary = Economy.offline_yield(live_rate, away,
					mult, doubled)
				total += float(off["amount"])
				offline_total += float(off["amount"])
		totals[name] = total
		print("   %-16s %12s credits   (%s offline, %d%% of it)"
			% [name, Economy.fmt(total), Economy.fmt(offline_total),
				int(round(offline_total / maxf(total, 1.0) * 100.0))])

	var free_total: float = float(totals["free"])
	print("")
	for name: String in runs.keys():
		print("   %-16s %.3fx the free player" % [name,
			float(totals[name]) / maxf(free_total, 1.0)])
	print("   The gap is entirely offline hours. Live play is identical by")
	print("   construction -- tests/test_store.gd asserts byte equality.")
	print("")
	print("   CAVEAT: the board is held fixed for the fortnight, so the share")
	print("   attributed to offline is an upper bound -- a real player spends")
	print("   sessions enlarging the board, which raises the live rate that")
	print("   the offline calculation is then a fraction OF. The ratios above")
	print("   are unaffected: live_rate cancels out of every one of them.")


func _initialize() -> void:
	print("Lodeworks -- where would a player feel value?")
	print("model: %s" % MachineDB.ACTIVE_MODEL)
	_waiting()
	_offline()
	_layouts()
	_run_shape()
	_blueprints()
	_parity()
	print("")
	quit()
