extends SceneTree

## Compares economic models against board archetypes.
##
##   godot --headless --path . --script res://tools/econ_lab.gd
##
## The question this answers is the one the previous round left open: why does
## the deep end of the production chain lose to a dense shallow board, and
## which rule change actually fixes it rather than papering over it with a
## bigger number.
##
## Every model in `MachineDB.MODELS` is run against every archetype below, at
## three depths, and reported. What is being looked for is NOT the highest
## number. It is:
##
##   1. Does a long chain beat a shallow board at all?      (is depth worth it)
##   2. Is the gap small enough that both stay playable?    (is there a choice)
##   3. Do different archetypes win at different depths?    (is there a puzzle)
##
## A model where one archetype dominates everywhere is a solved game. A model
## where the deep chain never wins is the game as it was.

const DEPTHS := [3, 9, 16]
const UPGRADES := {"throughput_1": 3, "yield_1": 2, "value_1": 2,
	"research_1": 1, "heat_tolerance": 1}
const WARM := 25.0
const SAMPLE := 40.0

const KEY := {
	"d": "drill", "c": "crusher", "s": "smelter", "p": "press",
	"a": "assembler", "v": "vault", "l": "lab", "b": "boiler",
	"o": "coolant", "m": "amplifier", "u": "duplicator", "n": "condenser",
}

## Six ways to fill a board, chosen to be genuinely different strategies
## rather than variations on one. If a model is any good, which of these wins
## should depend on the stratum.
const ARCHETYPES := {
	# Sell the first thing you make. The board a new player builds.
	"raw": [
		"ddddddd", "ccccccc", "vvvvvvv", "ddddddd", "ccccccc",
		"vvvvvvv", "ddddddd", "ccccccc", "vvvvvvv", ".......",
	],
	# One refining step, then sell. The board that wins under the base rules.
	"shallow": [
		"ddddddd", "ccccccc", "sssssss", "vvvvvvv", "ddddddd",
		"ccccccc", "sssssss", "vvvvvvv", ".......", ".......",
	],
	# The reference board: shallow with one component corner.
	"deck": [
		".......", "ddddddd", "ccccccc", "ssapsss", "vvlvvvv",
		".......", ".......", ".......", ".......", ".......",
	],
	# Every step of the chain in columns, each machine directly below its
	# supplier, with the output row taking everything.
	"deep_columns": [
		"ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa",
		"vvlvlvv", ".......", ".......", ".......", ".......",
	],
	# The same chain with a second supply deck under it, so the top of the
	# chain is fed from both directions.
	"deep_double": [
		"ddddddd", "ccccccc", "sssssss", "ppppppp", "aaaaaaa",
		"vvlvlvv", "aaaaaaa", "ppppppp", "sssssss", "ccccccc",
	],
	# Heat used on purpose: boilers between the smelters that want to be hot,
	# coolant under the presses that do not.
	"thermal": [
		"ddddddd", "ccccccc", "sbsbsbs", "popopop", "aaaaaaa",
		"vvlvlvv", ".......", ".......", ".......", ".......",
	],
	# Forty cells instead of seventy: what is left when a stratum collapses
	# its outer ring. Included because a board that cannot be rebuilt smaller
	# is a board that ends the run.
	"cramped": [
		".......", ".ddddd.", ".ccccc.", ".sspss.", ".valv..",
		".ddddd.", ".ccccc.", ".vvvvv.", ".......", ".......",
	],

}


func _initialize() -> void:
	for model_name: String in MachineDB.MODELS.keys():
		MachineDB.use_model(model_name)
		print("")
		print("=== model: %s ===" % model_name)
		print("%-14s %s" % ["archetype",
			" ".join(_headers())])
		var best_by_depth: Dictionary = {}
		for arch: String in ARCHETYPES.keys():
			var cells: Array = []
			for d: int in DEPTHS:
				var r: Dictionary = _run(ARCHETYPES[arch], d)
				cells.append("%9.0f/%5.2f/%2d" % [float(r["credits"]),
					float(r["research"]), int(r["dead"])])
				if float(r["credits"]) > float(best_by_depth.get(d, {}).get("credits", -1.0)):
					best_by_depth[d] = {"credits": float(r["credits"]), "name": arch}
			print("%-14s %s" % [arch, " ".join(cells)])
		var winners: Array[String] = []
		for d: int in DEPTHS:
			winners.append("depth %d: %s" % [d, String(best_by_depth[d]["name"])])
		print("winners       %s" % "  |  ".join(winners))
		print("depth premium %s" % _premium(best_by_depth))
	MachineDB.use_model(MachineDB.ACTIVE_MODEL)
	print("")
	print("Each cell is credits/s / research/s / dead tiles.")
	print("Shipping model: %s" % MachineDB.ACTIVE_MODEL)
	quit(0)


func _headers() -> Array:
	var out: Array = []
	for d: int in DEPTHS:
		out.append("%17s" % ("depth %d" % d))
	return out


## How much better the best deep board is than the best shallow one. This is
## the number the whole exercise is about.
func _premium(_best: Dictionary) -> String:
	var shallow: float = 0.0
	var deep: float = 0.0
	for d: int in DEPTHS:
		shallow = maxf(shallow, float(_run(ARCHETYPES["shallow"], d)["credits"]))
		deep = maxf(deep, float(_run(ARCHETYPES["deep_columns"], d)["credits"]))
	if shallow <= 0.0:
		return "UNKNOWN"
	return "deep_columns is %.2fx the best shallow board" % (deep / shallow)


func _run(art: Array, depth: int) -> Dictionary:
	var g := Grid.new()
	var st: Dictionary = Strata.describe(depth)
	g.set_environment(float(st["ambient_heat"]), float(st["heat_spread"]))
	var blocked: Dictionary = Strata.blocked_cells(depth)
	for y in range(mini(art.size(), Grid.H)):
		var row: String = String(art[y])
		for x in range(mini(row.length(), Grid.W)):
			var ch: String = row[x]
			if not KEY.has(ch):
				continue
			var i: int = Grid.idx(x, y)
			if not blocked.has(i):
				g.place(i, String(KEY[ch]))

	var sim := Simulation.new(g, 4242)
	var mu: Dictionary = Economy.multipliers(UPGRADES)
	Strata.apply(sim, null, st, mu)

	sim.run_ticks(int(WARM * Simulation.TICK_HZ))
	var out: Dictionary = sim.run_ticks(int(SAMPLE * Simulation.TICK_HZ))
	var secs: float = maxf(float(out["seconds"]), 0.001)
	var dead: int = 0
	for i: int in g.cells:
		if sim.status_of(i) != Simulation.Status.PASSIVE \
				and sim.uptime_of(i) < 0.05:
			dead += 1
	return {"credits": float(out["credits"]) / secs,
		"research": float(out["research"]) / secs, "dead": dead}
