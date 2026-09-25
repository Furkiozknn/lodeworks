class_name FactoryReport
extends RefCounted

## One factory, summed up: what the Factory Core's card shows.
##
## It reads a board, its simulation and how deep its shaft has been, never
## the game's singletons, so it sums up whichever factory it is handed --
## this shaft today, a second factory or another player's later -- the same
## way.
##
## "Need help" is the warning key's own count (`Simulation.problem_counts`),
## so the card and the key never disagree; every other machine is working.


static func of(grid: Grid, sim: Simulation, max_depth: int,
		blocked: Dictionary = {}) -> Dictionary:
	var p: Dictionary = sim.problem_counts()
	var problems: int = int(p["starved"]) + int(p["blocked"]) + int(p["thermal"])
	var machines: int = grid.cells.size()
	# The yard's tiles a machine can stand on: open, and not this stratum's
	# rubble.
	var tiles: int = 0
	for cell: int in BuildArea.cells(max_depth):
		if not blocked.has(cell):
			tiles += 1
	# The next stratum at which the yard widens, or -1 once it is the board.
	var next: int = -1
	if not BuildArea.is_whole_board(max_depth):
		next = max_depth + 1
		while BuildArea.radius_at(next) <= BuildArea.radius_at(max_depth):
			next += 1
	return {
		"machines": machines,
		"working": maxi(machines - problems, 0),
		"problems": problems,
		"tiles": tiles,
		"next_stratum": next,
		"next_size": BuildArea.size_at(next) if next >= 0 else BuildArea.size_at(max_depth),
	}
