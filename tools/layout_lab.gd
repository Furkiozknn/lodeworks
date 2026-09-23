extends SceneTree

## Scores candidate board layouts.
##
##   godot --headless --path . --script res://tools/layout_lab.gd
##
## This exists because the board the project used as its showcase layout was
## measured, after the per-tile status readout was added, to have thirteen of
## its twenty-eight machines permanently output-blocked and contributing
## nothing. It passed every test, because the tests asked whether the board
## produced credits and research -- which it did, on half of itself.
##
## So the question a layout has to answer is not only "how much does it earn"
## but "how much of it is doing anything". A board where half the tiles are
## dead is a board that teaches the player the wrong lesson about the game.
##
## Reported per candidate:
##   credits/s, research/s   measured over a settled window
##   working                 share of machines above 50% duty cycle
##   dead                    machines under 5% duty cycle
##   thermal                 machines losing throughput to heat

const DEPTH := 9
const UPGRADES := {"throughput_1": 3, "yield_1": 2, "value_1": 2,
	"research_1": 1, "heat_tolerance": 1}

## d drill   c crusher   s smelter   p press   a assembler
## v vault   l lab       b boiler    o coolant  m amplifier
## u duplicator  n condenser  .  empty
const KEY := {
	"d": "drill", "c": "crusher", "s": "smelter", "p": "press",
	"a": "assembler", "v": "vault", "l": "lab", "b": "boiler",
	"o": "coolant", "m": "amplifier", "u": "duplicator", "n": "condenser",
}

const CANDIDATES := {
	# The layout the project has been showing off and testing against.
	"baseline": [
		".......",
		".......",
		"dcsbscd",
		"dcpopcd",
		"dcamacd",
		"vvlmlvv",
		".......",
		".......",
		".......",
		".......",
	],
	# The same chain, but the components have somewhere to go besides a lab.
	# A component is worth 95 credits; a lab that can only take 0.6 of them a
	# second is a bottleneck with a price tag.
	"sell_surplus": [
		".......",
		".......",
		"dcsbscd",
		"dcpopcd",
		"dcamacd",
		"vvlmlvv",
		"..vvv..",
		".......",
		".......",
		".......",
	],
	# Two drills per crusher, which is the ratio the recipe actually asks for.
	"fed_crushers": [
		".......",
		"ddddddd",
		"cdcdcdc",
		"scspscs",
		"vamamav",
		"vvlblvv",
		".......",
		".......",
		".......",
		".......",
	],
	# A wide shallow board: sell early, refine only where it pays.
	"wide_shallow": [
		".......",
		"ddddddd",
		"cccbccc",
		"ssspsss",
		"vvvavvv",
		"..vlv..",
		".......",
		".......",
		".......",
		".......",
	],
	# Full depth with vaults threaded through every stage, so nothing ever
	# backs up and every tile keeps moving.
	"threaded": [
		".......",
		"ddddddd",
		"cccbccc",
		"vsspssv",
		"camamac",
		"vvlvlvv",
		"..ddd..",
		"..ccc..",
		".......",
		".......",
	],
	# A crusher wants two ore a second and a drill makes one, so every crusher
	# here has a drill above it and drills on both sides. The ratio the recipe
	# asks for, expressed as a shape.
	"fed_ladder": [
		".d.d.d.",
		"dcdcdcd",
		".s.s.s.",
		".pbp.p.",
		"vamamav",
		"vvlvlvv",
		".d.d.d.",
		"dcdcdcd",
		".v.v.v.",
		".......",
	],
	# The same fed-crusher shape, but everything is sold as gravel. Gravel is
	# worth three and needs no further machines, so this is the board a player
	# builds before they understand the game.
	"gravel_only": [
		".d.d.d.",
		"dcdcdcd",
		".v.v.v.",
		".d.d.d.",
		"dcdcdcd",
		".v.v.v.",
		".d.d.d.",
		"dcdcdcd",
		".v.v.v.",
		".......",
	],
	# One properly fed component chain, with a vault beside each assembler so
	# surplus components are sold rather than backing the whole board up.
	"component_farm": [
		".d.d.d.",
		"dcdcdcd",
		".s.s.s.",
		"dcpbpcd",
		".savas.",
		"dcamlcd",
		".v.v.v.",
		".d.d.d.",
		"dcdcdcd",
		".v.v.v.",
	],
	# Amplifiers earn their heat at this depth (the stratum 9 modifier doubles
	# them), so this one builds around two amplifier cores.
	"amplified": [
		".d.d.d.",
		"dcdcdcd",
		".s.s.s.",
		"dcmbmcd",
		".papap.",
		"vamamav",
		"vvlvlvv",
		".d.d.d.",
		"dcdcdcd",
		".v.v.v.",
	],
	# Variants on wide_shallow, which was the strongest hand-built board in
	# the first round but produced no research at all -- its single assembler
	# had no gravel neighbour, so the component chain never started.
	"deck_a": [
		".......",
		"ddddddd",
		"ccccccc",
		"ssapsss",
		"vvlvvvv",
		".......",
		".......",
		".......",
		".......",
		".......",
	],
	"deck_b": [
		"ddddddd",
		"ccccccc",
		"sssbsss",
		"vpvavpv",
		"vvlvlvv",
		".......",
		".......",
		".......",
		".......",
		".......",
	],
	"deck_c": [
		"ddddddd",
		"cccbccc",
		"ssspsss",
		"vvcacvv",
		"vvvlvvv",
		".......",
		".......",
		".......",
		".......",
		".......",
	],
	# Three shallow decks stacked, using the whole board.
	"three_decks": [
		"ddddddd",
		"ccccccc",
		"sssbsss",
		"vvvvvvv",
		"ddddddd",
		"ccccccc",
		"sssbsss",
		"vvavvvv",
		"ddddddd",
		"cclvccc",
	],
	# Two shallow decks and one component corner with its own supply.
	"two_decks_plus": [
		"ddddddd",
		"cccbccc",
		"sssssss",
		"vvvvvvv",
		"ddddddd",
		"cccbccc",
		"ssspsss",
		"vvcacvv",
		"ddvlvdd",
		"ccccccc",
	],
	# The full chain as a showcase, now that one input per step makes it
	# feedable. Each stage sits directly under its supplier.
	"deep_showcase": [
		".......",
		"ddddddd",
		"ccccccc",
		"sssssss",
		"ppppppp",
		"aaaaaaa",
		"vvlvlvv",
		".......",
		".......",
		".......",
	],
	"deep_amped": [
		".......",
		"ddddddd",
		"ccccccc",
		"sssssss",
		"pmpmpmp",
		"aaaaaaa",
		"vvlvlvv",
		".......",
		".......",
		".......",
	],
	"deep_cooled": [
		".......",
		"ddddddd",
		"ccccccc",
		"sbsbsbs",
		"sssssss",
		"popopop",
		"aaaaaaa",
		"vvlvlvv",
		".......",
		".......",
	],
	# The full chain, tapered: each stage narrower than the one feeding it,
	# with vaults on the shoulders so nothing at the edge has to back up.
	"deep_taper": [
		".......",
		"ddddddd",
		"ccccccc",
		"vsssssv",
		"vpppppv",
		"vvaaavv",
		".vvlvv.",
		".......",
		".......",
		".......",
	],
	"deep_taper2": [
		"ddddddd",
		"ccccccc",
		"vsssssv",
		"vpppppv",
		"vvaaavv",
		".vvlvv.",
		"ddddddd",
		"ccccccc",
		"vvvvvvv",
		".......",
	],
	# Heat used on purpose: a boiler core with the smelters around it and
	# coolant protecting the presses.
	"hot_core": [
		".......",
		"ddddddd",
		"ccccccc",
		"sssbsss",
		"popopop",
		"vamamav",
		"vvlvlvv",
		".......",
		".......",
		".......",
	],
}


func _initialize() -> void:
	var rows: Array = []
	for name: String in CANDIDATES.keys():
		rows.append(_score(name, CANDIDATES[name]))
	rows.sort_custom(func(a, b): return float(a["credits"]) > float(b["credits"]))
	print("")
	print("%-14s %10s %10s %8s %6s %8s %8s" % ["layout", "credits/s",
		"research/s", "machines", "dead", "working", "thermal"])
	for r: Dictionary in rows:
		print("%-14s %10.1f %10.2f %8d %6d %7d%% %8d" % [
			r["name"], float(r["credits"]), float(r["research"]),
			int(r["machines"]), int(r["dead"]),
			int(r["working_pct"]), int(r["thermal"])])
	print("")
	print("dead = under 5%% duty cycle. A dead tile cost credits to place and "
		+ "returns nothing.")
	quit(0)


func _score(name: String, art: Array) -> Dictionary:
	var g := Grid.new()
	var st: Dictionary = Strata.describe(DEPTH)
	g.set_environment(float(st["ambient_heat"]), float(st["heat_spread"]))
	var blocked: Dictionary = Strata.blocked_cells(DEPTH)
	var placed: int = 0
	for y in range(mini(art.size(), Grid.H)):
		var row: String = String(art[y])
		for x in range(mini(row.length(), Grid.W)):
			var ch: String = row[x]
			if not KEY.has(ch):
				continue
			var i: int = Grid.idx(x, y)
			if blocked.has(i):
				continue
			if g.place(i, String(KEY[ch])):
				placed += 1

	var sim := Simulation.new(g, 4242)
	var mu: Dictionary = Economy.multipliers(UPGRADES)
	sim.speed_mult = float(mu["speed"]) * float(st["process_speed"])
	sim.yield_mult = float(mu["yield"]) * float(st["source_yield"]) * float(st["richness"])
	sim.value_mult = float(mu["value"]) * float(st["value"])
	sim.research_mult = float(mu["research"]) * float(st["research"])
	sim.tolerance_bonus = float(mu["tolerance"])
	sim.buffer_cap = int(st["buffer_cap"]) if st.has("buffer_cap") else Simulation.BUF_CAP

	sim.run_ticks(int(25.0 * Simulation.TICK_HZ))
	var out: Dictionary = sim.run_ticks(int(40.0 * Simulation.TICK_HZ))
	var secs: float = float(out["seconds"])

	var dead: int = 0
	var working: int = 0
	var thermal: int = 0
	for i: int in g.cells:
		var u: float = sim.uptime_of(i)
		if sim.status_of(i) == Simulation.Status.PASSIVE:
			working += 1
			continue
		if u < 0.05:
			dead += 1
		if u > 0.5:
			working += 1
		if sim.heat_efficiency_at(i) < Simulation.THERMAL_WARNING:
			thermal += 1
	return {
		"name": name,
		"credits": float(out["credits"]) / secs,
		"research": float(out["research"]) / secs,
		"machines": placed,
		"dead": dead,
		"working_pct": int(round(float(working) / maxf(float(placed), 1.0) * 100.0)),
		"thermal": thermal,
	}
