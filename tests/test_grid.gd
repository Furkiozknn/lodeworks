extends RefCounted

## The board's rules. These are cheap tests, but they guard the two things a
## player notices instantly when they break: that rearranging is free, and that
## heat actually comes from neighbours.

var runner: Object


func test_place_and_remove() -> void:
	var g := Grid.new()
	runner.check(g.place(Grid.idx(0, 0), "drill"), "place should succeed on empty cell")
	runner.eq(g.machine_at(Grid.idx(0, 0)), "drill")
	runner.eq(g.count_of("drill"), 1)
	runner.check(not g.place(Grid.idx(0, 0), "vault"), "cell already occupied")
	runner.eq(g.remove(Grid.idx(0, 0)), "drill")
	runner.eq(g.count_of("drill"), 0)


func test_place_rejects_unknown_machine() -> void:
	var g := Grid.new()
	runner.check(not g.place(0, "teleporter"), "unknown machine must be rejected")


func test_move_does_not_change_ownership_counts() -> void:
	# Rearranging a board you already paid for has to be free, or players stop
	# experimenting and the game loses its whole inner loop.
	var g := Grid.new()
	g.place(Grid.idx(1, 1), "crusher")
	var before: float = MachineDB.cost_for("crusher", g.count_of("crusher"))
	runner.check(g.move(Grid.idx(1, 1), Grid.idx(4, 4)), "move to empty cell")
	runner.eq(g.machine_at(Grid.idx(4, 4)), "crusher")
	runner.eq(g.machine_at(Grid.idx(1, 1)), "")
	runner.eq(g.count_of("crusher"), 1)
	runner.near(MachineDB.cost_for("crusher", g.count_of("crusher")), before, 0.001,
		"moving must not change the next purchase price")


func test_move_into_occupied_cell_fails() -> void:
	var g := Grid.new()
	g.place(0, "drill")
	g.place(1, "vault")
	runner.check(not g.move(0, 1), "must not overwrite an occupied cell")
	runner.eq(g.machine_at(0), "drill")
	runner.eq(g.machine_at(1), "vault")


func test_neighbours_are_orthogonal_and_clamped() -> void:
	var g := Grid.new()
	runner.eq(g.neighbours(Grid.idx(0, 0)).size(), 2, "corner has two neighbours")
	runner.eq(g.neighbours(Grid.idx(3, 3)).size(), 4, "interior has four")
	runner.eq(g.neighbours(Grid.idx(Grid.W - 1, Grid.H - 1)).size(), 2, "far corner")


func test_heat_spreads_to_neighbours_at_half() -> void:
	var g := Grid.new()
	var centre: int = Grid.idx(3, 3)
	g.place(centre, "boiler")
	var boiler_heat: float = float(MachineDB.get_machine("boiler")["heat_out"])
	runner.near(g.heat_at(centre), boiler_heat, 0.001, "own cell gets full heat")
	runner.near(g.heat_at(Grid.idx(4, 3)), boiler_heat * MachineDB.HEAT_SPREAD, 0.001,
		"neighbour gets half")
	runner.near(g.heat_at(Grid.idx(5, 3)), 0.0, 0.001, "two cells away gets none")


func test_coolant_cancels_boiler() -> void:
	var g := Grid.new()
	var a: int = Grid.idx(2, 2)
	g.place(a, "boiler")
	g.place(Grid.idx(3, 2), "coolant")
	# Boiler 2.6 in its own cell, minus half of coolant's -2.2 = 1.5
	runner.near(g.heat_at(a), 2.6 - 1.1, 0.001, "coolant bleeds into the boiler cell")


func test_heat_never_reported_negative() -> void:
	var g := Grid.new()
	var c: int = Grid.idx(2, 2)
	g.place(c, "coolant")
	runner.gte(g.heat_at(c), 0.0, "a cell is never colder than zero")
	runner.lt(g.raw_heat_at(c), 0.0, "but the raw field does go negative")


func test_amplify_stacks_additively() -> void:
	var g := Grid.new()
	var c: int = Grid.idx(3, 3)
	g.place(c, "crusher")
	runner.near(g.amplify_at(c), 1.0, 0.001, "no amplifier yet")
	g.place(Grid.idx(2, 3), "amplifier")
	runner.near(g.amplify_at(c), 1.35, 0.001, "one amplifier")
	g.place(Grid.idx(4, 3), "amplifier")
	runner.near(g.amplify_at(c), 1.70, 0.001, "two amplifiers stack")


func test_duplicator_chance_does_not_stack() -> void:
	# Two Duplicators on one machine must be worse than spreading them out,
	# otherwise the optimal board is a single blob and layout stops mattering.
	var g := Grid.new()
	var c: int = Grid.idx(3, 3)
	g.place(c, "drill")
	g.place(Grid.idx(2, 3), "duplicator")
	var one: float = g.duplicate_chance_at(c)
	g.place(Grid.idx(4, 3), "duplicator")
	runner.near(g.duplicate_chance_at(c), one, 0.001, "second duplicator adds nothing")


func test_cost_rises_with_ownership() -> void:
	var first: float = MachineDB.cost_for("drill", 0)
	var tenth: float = MachineDB.cost_for("drill", 9)
	runner.gt(tenth, first * 3.0, "the tenth drill costs meaningfully more than the first")


func test_serialisation_round_trip() -> void:
	var g := Grid.new()
	g.place(Grid.idx(0, 0), "drill")
	g.place(Grid.idx(1, 0), "crusher")
	g.place(Grid.idx(2, 0), "vault")
	var d: Dictionary = g.to_dict()
	var g2 := Grid.new()
	g2.from_dict(d)
	runner.eq(g2.machine_at(Grid.idx(0, 0)), "drill")
	runner.eq(g2.machine_at(Grid.idx(1, 0)), "crusher")
	runner.eq(g2.machine_at(Grid.idx(2, 0)), "vault")
	runner.eq(g2.count_of("drill"), 1, "ownership counts must survive a reload")


func test_load_ignores_garbage() -> void:
	# A corrupted or hand-edited save must not brick the board.
	var g := Grid.new()
	g.from_dict({"cells": {"999999": "drill", "3": "not_a_machine", "-1": "vault"}})
	runner.eq(g.cells.size(), 0, "out-of-range and unknown entries are dropped")
