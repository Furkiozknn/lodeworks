class_name Tutorial
extends RefCounted

## The first chapter, as data.
##
## The old tutorial was five sentences that appeared above the board and
## advanced when the player happened to do the thing they described. This one
## is built on a different rule: **the player should be doing something before
## they are told anything, and what they are told should be one line.**
##
## So every step here is a goal the player reaches by touching the board, the
## game highlights where, and the line is at most a dozen words. There is no
## modal, no "tap here" hand, no wall of text and no page the player has to
## dismiss. The board itself is the teacher: the status lights, the material
## moving between tiles, the heat overlay and the placement preview all say
## more than a paragraph could, and they keep saying it after the tutorial is
## over.
##
## After this chapter the game stops instructing entirely. Everything later is
## either discovered on the board or looked up in the Codex, which the player
## opens only if they want it.
##
## One beat is deliberately missing. The brief asked for the first research
## upgrade to be part of chapter one, and it cannot be: Research comes from a
## Lab, a Lab eats Components, and a Component needs a five-machine chain that
## costs more than a first session earns. Forcing it would mean handing out
## free Research, which would make the first number the game shows a lie.
## Instead the research nudge fires once, later, the first time a player
## actually has some -- see `RESEARCH_NUDGE`.

## Order matters, and one ordering is impossible.
##
## The first draft asked for a Crusher "between" the Drill and the Vault
## immediately after they had been placed touching each other -- and two
## orthogonally adjacent tiles on a grid share no common neighbour, so there
## was nowhere to put it. Moving therefore comes first, which is better
## teaching anyway: the player learns that rearranging is free at the moment
## they need to rearrange something.
##
## Each step: what the player has to do, the one line they are told, which
## palette entry to pulse, and how to work out which tiles to highlight.
const STEPS := [
	{
		"id": "place_drill",
		"line": "Tap DRILL below, then tap any tile.",
		"arm": "drill",
		"highlight": "open_middle",
	},
	{
		"id": "place_vault",
		"line": "Now a VAULT touching it. Machines only reach what they touch.",
		"arm": "vault",
		"highlight": "next_to_drill",
	},
	{
		"id": "see_income",
		"line": "That is ore being sold. Watch the number.",
		"arm": "",
		"highlight": "none",
	},
	{
		"id": "move_one",
		"line": "Tap the Vault, then drag it one tile away. Moving is free.",
		"arm": "",
		"highlight": "owned",
	},
	{
		"id": "place_crusher",
		"line": "Put a CRUSHER in the gap. Gravel sells for more than ore.",
		"arm": "crusher",
		"highlight": "between_drill_and_vault",
	},
	{
		"id": "see_heat",
		"line": "Tap HEAT. Every machine has a temperature it wants.",
		"arm": "",
		"highlight": "heat_button",
	},
	{
		"id": "reach_quota",
		"line": "Fill the board and reach the quota at the top right.",
		"arm": "",
		"highlight": "none",
	},
	{
		"id": "descend",
		"line": "DESCEND. Deeper rock is richer, hotter and stranger.",
		"arm": "",
		"highlight": "descend_button",
	},
]

## Fires once, the first time the player has Research to spend. Not part of
## the chapter, and not repeated.
const RESEARCH_NUDGE := "You have Research. Spend it — it is the only thing a collapse does not take."


static func count() -> int:
	return STEPS.size()


static func step(index: int) -> Dictionary:
	if index < 0 or index >= STEPS.size():
		return {}
	return STEPS[index]


static func line_for(index: int) -> String:
	var s: Dictionary = step(index)
	return String(s.get("line", ""))


static func arm_for(index: int) -> String:
	var s: Dictionary = step(index)
	return String(s.get("arm", ""))


static func is_done(index: int) -> bool:
	return index >= STEPS.size()


## Has the player done the thing this step asks for?
##
## Every check reads the live board rather than counting taps, so a player who
## works it out before being told is never asked to do it again — which is the
## whole point of teaching with a board instead of with a script.
static func satisfied(index: int, state: Node) -> bool:
	var s: Dictionary = step(index)
	if s.is_empty() or state == null:
		return false
	var grid: Grid = state.get("grid")
	if grid == null:
		return false
	match String(s["id"]):
		"place_drill":
			return grid.count_of("drill") > 0
		"place_vault":
			# Not merely owning a Vault: owning one that is actually connected.
			# The lesson is adjacency, so the check has to be adjacency.
			return _touching(grid, "vault", "drill")
		"see_income":
			return float(state.get("lifetime_credits")) > 0.0
		"place_crusher":
			return _touching(grid, "crusher", "drill") \
				and _touching(grid, "crusher", "vault")
		"move_one":
			return int(state.get("tutorial_moves")) > 0
		"see_heat":
			return bool(state.get("tutorial_saw_heat"))
		"reach_quota":
			return state.call("can_descend")
		"descend":
			return int(state.get("max_depth")) > 0
	return false


## Which tiles to pulse. Highlighting where to put the thing is worth more
## than a sentence explaining where, and it costs the player no reading.
static func highlight(index: int, state: Node) -> Array[int]:
	var out: Array[int] = []
	var s: Dictionary = step(index)
	if s.is_empty() or state == null:
		return out
	var grid: Grid = state.get("grid")
	if grid == null:
		return out
	match String(s.get("highlight", "none")):
		"open_middle":
			# A small block in the middle of the board, so the first machine
			# lands somewhere there is room to build around it.
			for y in range(3, 6):
				for x in range(2, 5):
					var i: int = Grid.idx(x, y)
					if grid.is_empty(i) and not state.call("is_blocked", i):
						out.append(i)
		"next_to_drill":
			for i: int in grid.cells:
				if grid.machine_at(i) != "drill":
					continue
				for n in grid.neighbours(i):
					if grid.is_empty(n) and not out.has(n) \
							and not state.call("is_blocked", n):
						out.append(n)
		"between_drill_and_vault":
			# Empty tiles that touch both, which is exactly the shape the
			# lesson is about.
			for i in range(Grid.W * Grid.H):
				if not grid.is_empty(i) or state.call("is_blocked", i):
					continue
				var near_drill: bool = false
				var near_vault: bool = false
				for n in grid.neighbours(i):
					var id: String = grid.machine_at(n)
					if id == "drill":
						near_drill = true
					elif id == "vault":
						near_vault = true
				if near_drill and near_vault:
					out.append(i)
		"owned":
			for i: int in grid.cells:
				out.append(i)
	return out


## Which control to pulse, for the steps whose answer is not on the board.
static func highlight_control(index: int) -> String:
	var s: Dictionary = step(index)
	return String(s.get("highlight", "none"))


static func _touching(grid: Grid, a: String, b: String) -> bool:
	for i: int in grid.cells:
		if grid.machine_at(i) != a:
			continue
		for n in grid.neighbours(i):
			if grid.machine_at(n) == b:
				return true
	return false
