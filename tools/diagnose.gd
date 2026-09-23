extends SceneTree

## Balance diagnostics. Prints what each cell of a board is actually doing, so
## a stalled chain can be found by reading rather than guessing.
##
##   godot --headless --path . --script res://tools/diagnose.gd

func _board(pairs: Array, depth: int, upgrades: Dictionary = {}) -> Simulation:
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	var st: Dictionary = Strata.describe(depth)
	var mu: Dictionary = Economy.multipliers(upgrades)
	Strata.apply(s, g, st, mu)
	for p: Array in pairs:
		g.place(Grid.idx(int(p[0]), int(p[1])), String(p[2]))
	return s


func _dump(label: String, s: Simulation, depth: int) -> void:
	var st: Dictionary = Strata.describe(depth)
	print("\n=== %s  (depth %d, ambient %.2f, mods %s) ===" %
		[label, depth, float(st["ambient_heat"]), str(st["modifiers"])])
	s.run_ticks(300)
	var m: Dictionary = s.measure(10.0, 10.0)
	print("  credits/s %.3f   research/s %.3f   cycles/s %.2f" %
		[m["credits_per_sec"], m["research_per_sec"], m["cycles_per_sec"]])
	for i: int in s.grid.cells:
		var cell: Dictionary = s.grid.cells[i]
		var id: String = String(cell["id"])
		var md: Dictionary = MachineDB.get_machine(id)
		var p: Vector2i = Grid.xy(i)
		var eff: float = MachineDB.heat_efficiency(s.grid.heat_at(i),
			float(md["heat_optimum"]), float(md["heat_tolerance"]) + s.tolerance_bonus)
		print("   (%d,%d) %-10s heat %5.2f  eff %3d%%  rate %.2f  in %s out %s" %
			[p.x, p.y, id, s.grid.heat_at(i), int(eff * 100.0),
			s.effective_rate(i), str(cell["buf_in"]), str(cell["buf_out"])])


func _initialize() -> void:
	_dump("starter d0", _board([
		[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
		[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
	], 0), 0)

	_dump("starter d10", _board([
		[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
		[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
	], 10), 10)

	_dump("late chain d8", _board([
		[0, 2, "drill"], [1, 2, "crusher"], [2, 2, "smelter"], [3, 2, "boiler"],
		[4, 2, "smelter"], [5, 2, "crusher"], [6, 2, "drill"],
		[0, 3, "drill"], [1, 3, "crusher"], [2, 3, "press"], [3, 3, "coolant"],
		[4, 3, "press"], [5, 3, "crusher"], [6, 3, "drill"],
		[0, 4, "drill"], [1, 4, "crusher"], [2, 4, "assembler"], [3, 4, "vault"],
		[4, 4, "assembler"], [5, 4, "crusher"], [6, 4, "drill"],
		[2, 5, "lab"], [3, 5, "vault"], [4, 5, "lab"],
	], 8), 8)

	_dump("heat plain d3", _board([
		[2, 3, "drill"], [3, 3, "crusher"], [4, 3, "smelter"], [5, 3, "vault"],
		[2, 4, "drill"], [3, 4, "crusher"],
	], 3), 3)
	_dump("heat managed d3", _board([
		[2, 3, "drill"], [3, 3, "crusher"], [4, 3, "smelter"], [5, 3, "vault"],
		[2, 4, "drill"], [3, 4, "crusher"], [4, 2, "boiler"], [5, 2, "coolant"],
	], 3), 3)
	quit()
