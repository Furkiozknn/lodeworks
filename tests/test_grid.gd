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


func test_an_amplifier_is_worth_what_it_serves() -> void:
	# The rule the whole support-machine design rests on: the same Amplifier
	# is weak in a corner and strong in the middle of a chain, so WHERE it
	# goes is the decision. Before this, the effect was flat per neighbour and
	# a support tile could never beat the producer it displaced.
	var g := Grid.new()
	var amp: int = Grid.idx(3, 3)
	g.place(amp, "amplifier")
	runner.eq(g.serves(amp), 0, "an Amplifier alone serves nothing")
	runner.near(g.serve_factor(amp), 0.0, 0.001, "and is worth nothing")

	g.place(Grid.idx(2, 3), "crusher")
	runner.eq(g.serves(amp), 1, "one working neighbour")
	runner.near(g.serve_factor(amp), 1.0, 0.001, "worth its face value")
	runner.near(g.amplify_at(Grid.idx(2, 3)), 1.35, 0.001,
		"and the neighbour gets the base boost")

	g.place(Grid.idx(4, 3), "crusher")
	g.place(Grid.idx(3, 2), "crusher")
	g.place(Grid.idx(3, 4), "crusher")
	runner.eq(g.serves(amp), 4, "four working neighbours")
	runner.near(g.serve_factor(amp), 2.5, 0.001,
		"1 + 0.5 x (n - 1), so four neighbours is two and a half times")
	runner.near(g.amplify_at(Grid.idx(2, 3)), 1.0 + 0.35 * 2.5, 0.001,
		"a well-placed Amplifier is worth seven times a badly-placed one, "
		+ "counting all four neighbours")


func test_a_vault_is_not_something_to_amplify() -> void:
	# A Vault has no rate to raise, so an Amplifier next to one is wasted.
	# If this ever stopped being true the obvious board would be right again.
	var g := Grid.new()
	var amp: int = Grid.idx(3, 3)
	g.place(amp, "amplifier")
	g.place(Grid.idx(2, 3), "vault")
	g.place(Grid.idx(4, 3), "amplifier")
	runner.eq(g.serves(amp), 0,
		"neither a Vault nor another Amplifier counts as something served")


func test_stacked_amplifiers_have_diminishing_returns() -> void:
	# Factorio rebuilt its beacon maths in 2.0 because linear stacking made
	# one layout correct everywhere and building "feel monotonous" (FFF #409).
	# Two Amplifiers on one machine must be worth having and four must be
	# close to pointless, or the board has a single answer.
	var g := Grid.new()
	var c: int = Grid.idx(3, 3)
	g.place(c, "crusher")
	runner.near(g.amplify_at(c), 1.0, 0.001, "no amplifier yet")
	g.place(Grid.idx(2, 3), "amplifier")
	var one: float = g.amplify_at(c) - 1.0
	g.place(Grid.idx(4, 3), "amplifier")
	var two: float = g.amplify_at(c) - 1.0
	g.place(Grid.idx(3, 2), "amplifier")
	var three: float = g.amplify_at(c) - 1.0
	runner.gt(two, one, "a second Amplifier is still worth placing")
	runner.gt(three, two, "and a third")
	runner.lt(three - two, two - one,
		"but each one adds less than the one before it")
	runner.lt(two, one * 2.0, "two are worth less than twice one")


func test_duplicator_chance_is_capped_and_diminishing() -> void:
	# Two Duplicators on one machine must be worse than spreading them out,
	# otherwise the optimal board is a single blob and layout stops mattering.
	var g := Grid.new()
	var c: int = Grid.idx(3, 3)
	g.place(c, "drill")
	g.place(Grid.idx(2, 3), "duplicator")
	var one: float = g.duplicate_chance_at(c)
	g.place(Grid.idx(4, 3), "duplicator")
	var two: float = g.duplicate_chance_at(c)
	runner.gt(two, one, "a second Duplicator is worth something")
	runner.lt(two, one * 2.0, "but less than the first")
	g.place(Grid.idx(3, 2), "duplicator")
	g.place(Grid.idx(3, 4), "duplicator")
	runner.lte(g.duplicate_chance_at(c), 0.9,
		"and a guaranteed double would make the rest of the board irrelevant")


## --- support machines bridge rather than block -----------------------------

func test_a_support_machine_passes_material_through() -> void:
	# The one rule change the audit produced. Without it, a support machine
	# placed inside a chain starves whatever was feeding through it, and one
	# placed outside a chain is next to Vaults and serves nothing -- which
	# made five of the twelve machines impossible to use.
	var g := Grid.new()
	var drill: int = Grid.idx(3, 3)
	var amp: int = Grid.idx(3, 4)
	var crusher: int = Grid.idx(3, 5)
	g.place(drill, "drill")
	g.place(crusher, "crusher")
	runner.check(not g.bridged_machines(drill).has(crusher),
		"two tiles apart with nothing between them is not a connection")
	g.place(amp, "amplifier")
	runner.check(g.bridged_machines(drill).has(crusher),
		"an Amplifier between them bridges the gap")
	runner.check(not g.bridged_machines(drill).has(amp),
		"and is not itself a destination -- material passes through, "
		+ "it does not stop")


func test_a_producer_does_not_bridge() -> void:
	# Only machines that make nothing bridge. A Crusher between a Drill and a
	# Smelter is part of the chain, not a gap in it.
	var g := Grid.new()
	g.place(Grid.idx(3, 3), "drill")
	g.place(Grid.idx(3, 4), "crusher")
	g.place(Grid.idx(3, 5), "smelter")
	runner.check(not g.bridged_machines(Grid.idx(3, 3)).has(Grid.idx(3, 5)),
		"a working machine is a stop, not a bridge")
	runner.check(not g.is_support(Grid.idx(3, 4)), "a Crusher is not support")
	runner.check(g.is_support(Grid.idx(3, 3)) == false, "nor is a Drill")


func test_bridging_is_one_hop_only() -> void:
	# Two hops would turn the board into a graph problem and make "what is
	# this connected to" impossible to see at a glance, which is what the
	# whole visual design exists for.
	var g := Grid.new()
	g.place(Grid.idx(3, 2), "drill")
	g.place(Grid.idx(3, 3), "amplifier")
	g.place(Grid.idx(3, 4), "amplifier")
	g.place(Grid.idx(3, 5), "crusher")
	runner.check(not g.bridged_machines(Grid.idx(3, 2)).has(Grid.idx(3, 5)),
		"a support machine bridges one gap, never a corridor")


func test_a_vault_still_only_takes_from_what_it_touches() -> void:
	var g := Grid.new()
	g.place(Grid.idx(3, 3), "drill")
	g.place(Grid.idx(3, 4), "vault")
	runner.check(g.bridged_machines(Grid.idx(3, 3)).has(Grid.idx(3, 4)),
		"adjacency is unchanged for everything that is not support")


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


func test_the_previewed_service_count_is_the_one_you_get() -> void:
	# The placement preview draws "serves N" under the player's finger before
	# the tile is bought. If that number could disagree with what the machine
	# actually gets, the discovery it is meant to teach would be a lie.
	var g := Grid.new()
	var spot: int = Grid.idx(3, 3)
	g.place(Grid.idx(2, 3), "drill")
	g.place(Grid.idx(4, 3), "crusher")
	g.place(Grid.idx(3, 2), "vault")
	var previewed: int = g.serves_if_placed(spot)
	runner.eq(previewed, 2,
		"two working neighbours; the Vault has no rate to raise")
	g.place(spot, "amplifier")
	runner.eq(g.serves(spot), previewed,
		"what the preview promised is what the machine got")
	runner.near(g.serve_factor(spot), Grid.factor_for(previewed), 0.0001,
		"and the multiplier it promised too")


func test_the_preview_reads_zero_where_a_support_tile_is_wasted() -> void:
	var g := Grid.new()
	g.place(Grid.idx(2, 3), "vault")
	g.place(Grid.idx(4, 3), "amplifier")
	runner.eq(g.serves_if_placed(Grid.idx(3, 3)), 0,
		"next to a Vault and another Amplifier is a wasted tile, and the "
		+ "preview has to say so before the player spends the credits")
	runner.near(Grid.factor_for(0), 0.0, 0.0001, "worth nothing")
