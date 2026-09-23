extends SceneTree

## Searches for strong board layouts by hill-climbing.
##
##   godot --headless --path . --script res://tools/layout_search.gd
##
## Two uses, and the second is the important one.
##
## The obvious use is finding a good board for the store screenshots and for
## the test suite's reference layout — the previous one was measured to have
## thirteen of its twenty-eight machines permanently stalled.
##
## The real use is as a balance instrument. If this finds one layout that is
## far better than everything else, the game has a solved board and no puzzle.
## If it finds several very different layouts within a few percent of each
## other, the design is doing its job. That is a question a designer cannot
## answer by staring at a spreadsheet, and it takes about a minute here.
##
## Scoring is credits per second plus research valued at the rate the research
## tree actually charges, minus a penalty for every machine that sits below
## five per cent duty cycle. A dead tile cost credits to place and returns
## nothing, and a layout that only looks good because it is enormous is not a
## layout worth showing anyone.

const DEPTH := 9
const UPGRADES := {"throughput_1": 3, "yield_1": 2, "value_1": 2,
	"research_1": 1, "heat_tolerance": 1}

## Short windows during the search, a long one for the final verification.
const SEARCH_WARM := 12.0
const SEARCH_SAMPLE := 12.0
const FINAL_WARM := 25.0
const FINAL_SAMPLE := 40.0

const RESTARTS := 4
const STEPS := 260

## Research is worth something, and without a price on it the search would
## delete every Lab. This is the credits-equivalent the search uses; it is a
## search weight, not a game rule.
const RESEARCH_WEIGHT := 90.0
const DEAD_PENALTY := 12.0

const PALETTE := ["", "drill", "crusher", "smelter", "press", "assembler",
	"vault", "lab", "boiler", "coolant", "amplifier"]

const SYMBOL := {
	"": ".", "drill": "d", "crusher": "c", "smelter": "s", "press": "p",
	"assembler": "a", "vault": "v", "lab": "l", "boiler": "b",
	"coolant": "o", "amplifier": "m", "duplicator": "u", "condenser": "n",
}

var _rng := RandomNumberGenerator.new()
var _stratum: Dictionary = {}
var _mult: Dictionary = {}


func _initialize() -> void:
	_rng.seed = 20260923
	_stratum = Strata.describe(DEPTH)
	_mult = Economy.multipliers(UPGRADES)

	var best: Array = []
	var best_score: float = -1.0
	var results: Array = []

	for r in range(RESTARTS):
		var layout: Array = _seed_layout(r)
		var score: float = _score(layout)["score"]
		for step in range(STEPS):
			var candidate: Array = layout.duplicate()
			_mutate(candidate)
			var s: float = _score(candidate)["score"]
			if s > score:
				layout = candidate
				score = s
		var final: Dictionary = _score(layout, true)
		final["seed"] = r
		final["layout"] = layout
		results.append(final)
		print("restart %d: %.1f credits/s, %.2f research/s, %d machines, %d dead"
			% [r, float(final["credits"]), float(final["research"]),
				int(final["machines"]), int(final["dead"])])
		if float(final["score"]) > best_score:
			best_score = float(final["score"])
			best = layout

	print("")
	print("best board found:")
	for line in _render(best):
		print("  \"%s\"," % line)
	var v: Dictionary = _score(best, true)
	print("")
	print("  %.1f credits/s, %.2f research/s, %d machines, %d dead, %d thermal"
		% [float(v["credits"]), float(v["research"]), int(v["machines"]),
			int(v["dead"]), int(v["thermal"])])

	# The spread between independent restarts is the design signal.
	var lo: float = 1e30
	var hi: float = -1e30
	for r: Dictionary in results:
		lo = minf(lo, float(r["credits"]))
		hi = maxf(hi, float(r["credits"]))
	print("")
	print("spread across %d independent searches: %.1f to %.1f credits/s (%.0f%%)"
		% [RESTARTS, lo, hi, (hi / maxf(lo, 0.001) - 1.0) * 100.0])
	print("A small spread means many different boards are nearly as good, "
		+ "which is what a placement puzzle needs. A large one means there is "
		+ "a single right answer and the puzzle is solved.")
	quit(0)


func _seed_layout(variant: int) -> Array:
	var out: Array = []
	out.resize(Grid.W * Grid.H)
	for i in range(out.size()):
		out[i] = ""
	match variant:
		0:
			pass  # empty: let the climb build it
		1:
			for i in range(out.size()):
				out[i] = "drill" if i % 2 == 0 else "crusher"
		2:
			for y in range(Grid.H):
				for x in range(Grid.W):
					out[Grid.idx(x, y)] = ["drill", "crusher", "smelter",
						"vault"][y % 4]
		_:
			for i in range(out.size()):
				out[i] = PALETTE[_rng.randi_range(0, PALETTE.size() - 1)]
	return out


func _mutate(layout: Array) -> void:
	var n: int = _rng.randi_range(1, 3)
	for _k in range(n):
		var i: int = _rng.randi_range(0, layout.size() - 1)
		if _rng.randf() < 0.25 and layout.size() > 1:
			# Swap two tiles: the game's own free-move action, and the cheapest
			# way to explore adjacency without changing the machine mix.
			var j: int = _rng.randi_range(0, layout.size() - 1)
			var t: Variant = layout[i]
			layout[i] = layout[j]
			layout[j] = t
		else:
			layout[i] = PALETTE[_rng.randi_range(0, PALETTE.size() - 1)]


func _score(layout: Array, final: bool = false) -> Dictionary:
	var g := Grid.new()
	g.set_environment(float(_stratum["ambient_heat"]),
		float(_stratum["heat_spread"]))
	var blocked: Dictionary = Strata.blocked_cells(DEPTH)
	var placed: int = 0
	for i in range(layout.size()):
		var id: String = String(layout[i])
		if id == "" or blocked.has(i):
			continue
		if g.place(i, id):
			placed += 1

	var sim := Simulation.new(g, 4242)
	sim.speed_mult = float(_mult["speed"]) * float(_stratum["process_speed"])
	sim.yield_mult = float(_mult["yield"]) * float(_stratum["source_yield"]) \
		* float(_stratum["richness"])
	sim.value_mult = float(_mult["value"]) * float(_stratum["value"])
	sim.research_mult = float(_mult["research"]) * float(_stratum["research"])
	sim.tolerance_bonus = float(_mult["tolerance"])

	sim.run_ticks(int((FINAL_WARM if final else SEARCH_WARM) * Simulation.TICK_HZ))
	var out: Dictionary = sim.run_ticks(
		int((FINAL_SAMPLE if final else SEARCH_SAMPLE) * Simulation.TICK_HZ))
	var secs: float = maxf(float(out["seconds"]), 0.001)
	var cps: float = float(out["credits"]) / secs
	var rps: float = float(out["research"]) / secs

	var dead: int = 0
	var thermal: int = 0
	for i: int in g.cells:
		if sim.status_of(i) == Simulation.Status.PASSIVE:
			continue
		if sim.uptime_of(i) < 0.05:
			dead += 1
		if sim.heat_efficiency_at(i) < Simulation.THERMAL_WARNING:
			thermal += 1

	return {
		"score": cps + rps * RESEARCH_WEIGHT - float(dead) * DEAD_PENALTY,
		"credits": cps, "research": rps, "machines": placed,
		"dead": dead, "thermal": thermal,
	}


func _render(layout: Array) -> Array:
	var lines: Array = []
	for y in range(Grid.H):
		var row: String = ""
		for x in range(Grid.W):
			row += String(SYMBOL.get(String(layout[Grid.idx(x, y)]), "?"))
		lines.append(row)
	return lines
