extends SceneTree

## The deep strata, measured: what the rock of strata 16 and down does to
## the Core 7 era's factory, and what the deep chain (MachineDB.JOBS) makes
## on the same rock.
##
##   godot --headless --path . --script res://tools/deep_lab.gd
##
## It prints, stratum by stratum:
##   * the factory the scripted player had built the moment Core 7's rows
##     were met (tests/fixtures/core7_ready.json), its machine levels and
##     research as they were, moved down unchanged: credits a second, and
##     how many of its makers overheat or work;
##   * per tile, at the Core 7 era's machine level: an Assembler line of the
##     Core's third level with its heat answered (tools/heat_lab.gd), and a
##     block of Deep Bores and White Heat Smelters with Vaults -- the one
##     laid on purpose for heat, the other built to love it.
## The per-tile numbers are what DEEP_VALUES were set from
## (docs/PROGRESSION.md, "After Core 7").

const DEPTHS := [15, 16, 17, 19, 21, 24]
const LEVEL := 7

## The Core's third line (tools/core_journey_player.gd PLANS), one Assembler.
const OLD_LINE := [
	[16, 19, "drill"], [16, 21, "drill"], [16, 20, "crusher"], [17, 20, "smelter"],
	[17, 21, "boiler"], [18, 19, "coolant"], [18, 21, "coolant"], [18, 20, "press"],
	[19, 21, "coolant"], [19, 20, "assembler"], [19, 19, "vault"],
]

## A Deep Bore, a White Heat Smelter and a Vault, twice to a row, three
## rows. A Vault sells what one cycle's buffer holds, so each Smelter has
## its own: two would share one Vault's throughput.
const DEEP_BLOCK := [
	[10, 10, "drill", "crystal"], [11, 10, "smelter", "alloy"], [12, 10, "vault", ""],
	[13, 10, "vault", ""], [14, 10, "smelter", "alloy"], [15, 10, "drill", "crystal"],
	[10, 11, "drill", "crystal"], [11, 11, "smelter", "alloy"], [12, 11, "vault", ""],
	[13, 11, "vault", ""], [14, 11, "smelter", "alloy"], [15, 11, "drill", "crystal"],
	[10, 12, "drill", "crystal"], [11, 12, "smelter", "alloy"], [12, 12, "vault", ""],
	[13, 12, "vault", ""], [14, 12, "smelter", "alloy"], [15, 12, "drill", "crystal"],
]


func _initialize() -> void:
	TranslationServer.set_locale("en")
	print("== THE CORE 7 FACTORY, MOVED DOWN UNCHANGED ==")
	print("  stratum  credits/s  research/s  makers over/working/all")
	var S: Node = root.get_node("Sim")
	S._ensure()
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/core7_ready.json"))
	for d: int in DEPTHS:
		S.from_dict(fx)
		S.core_level = 7
		S.depth = d
		S.max_depth = maxi(int(S.max_depth), d)
		S._recompute()
		S.sim.reset_progress()
		var out: Dictionary = S.sim.measure(20.0, 30.0)
		var c: Dictionary = _count(S.grid, S.sim)
		print("  %7d  %9s  %10s  %d/%d/%d" % [d, Economy.fmt(float(out["credits_per_sec"])),
			Economy.fmt(float(out["research_per_sec"])), int(c["over"]), int(c["working"]), int(c["all"])])
	var mu: Dictionary = Economy.multipliers(fx.get("upgrades", {}))
	print("\n== PER TILE, machines at level %d, the fixture's research ==" % LEVEL)
	print("  stratum  old line /tile (over)   deep block /tile (over)   deep / old   Deep Bore, White Heat cycles/s")
	for d: int in DEPTHS:
		var a: Dictionary = _line(OLD_LINE, d, mu, true)
		var b: Dictionary = _line(DEEP_BLOCK, d, mu, false)
		print("  %7d  %12s (%d)  %16s (%d)  %8.2f   %.2f, %.2f" % [d, Economy.fmt(float(a["per_tile"])), int(a["over"]),
			Economy.fmt(float(b["per_tile"])), int(b["over"]),
			float(b["per_tile"]) / maxf(float(a["per_tile"]), 0.001), float(b["bore"]), float(b["white"])])
	root.get_node("Save").wipe()
	quit(0)


## One layout on stratum `d`'s plain rock, every maker at LEVEL, with the
## research multipliers `mu`: credits a second a tile, and makers overheating.
## `answer`: cool what overheats as a player would (tools/heat_lab.gd).
func _line(line: Array, d: int, mu: Dictionary, answer: bool) -> Dictionary:
	var g := Grid.new()
	var s := Simulation.new(g, 7)
	var st: Dictionary = Strata._describe(d, [] as Array[String])
	Strata.apply(s, g, st, mu)
	for e: Array in line:
		var cell: int = Grid.idx(int(e[0]), int(e[1]))
		g.place(cell, String(e[2]))
		if e.size() > 3:
			g.set_job(cell, String(e[3]))
	var hs: Dictionary = {}
	for id: String in MachineDB.ORDER:
		if MachineDB.has_levels(id) and not (MachineDB.get_machine(id)["tags"] as Array).has("sink"):
			if MachineDB.level_is_speed(id):
				s.level_mult[id] = MachineDB.level_speed(LEVEL)
			hs[id] = MachineDB.heat_factor(id, LEVEL)
	g.set_heat_scale(hs)
	s.levels_stamp += 1
	if answer:
		_answer(g)
	s.reset_progress()
	var out: Dictionary = s.measure(20.0, 60.0)
	var c: Dictionary = _count(g, s)
	# How fast the deep block's machines would cycle, fed: what depth and
	# heat give it, whatever its Vaults can sell.
	var bore: float = 0.0
	var white: float = 0.0
	for cell: int in g.cells:
		if g.job_at(cell) == "crystal" and bore == 0.0:
			bore = s.effective_rate(cell)
		if g.job_at(cell) == "alloy" and white == 0.0:
			white = s.effective_rate(cell)
	return {"per_tile": float(out["credits_per_sec"]) / float(g.cells.size()), "over": int(c["over"]),
		"bore": bore, "white": white}


func _count(g: Grid, s: Simulation) -> Dictionary:
	var over: int = 0
	var working: int = 0
	var all: int = 0
	for c: int in g.cells:
		var id: String = g.machine_at(c)
		if not MachineDB.level_is_speed(id):
			continue
		all += 1
		if s.overheated_at(c):
			over += 1
		if s.status_of(c) == Simulation.Status.RUNNING and s.heat_efficiency_at(c) >= Simulation.THERMAL_WARNING:
			working += 1
	return {"over": over, "working": working, "all": all}


## Coolant Cells beside what overheats, run Cool first, until nothing does.
func _answer(g: Grid) -> void:
	for _round in range(40):
		var hottest: int = -1
		var worst: float = 0.0
		for c: int in g.cells:
			var m: Dictionary = MachineDB.job_machine(g.machine_at(c), g.job_at(c))
			var by: float = g.heat_at(c) - float(m["heat_tolerance"])
			if by > worst:
				worst = by
				hottest = c
		if hottest < 0:
			return
		if g.mode_at(hottest) == MachineDB.Mode.NORMAL \
				and MachineDB.modes_for(g.machine_at(hottest)).has(MachineDB.Mode.COOL):
			g.set_mode(hottest, MachineDB.Mode.COOL)
			continue
		var placed: bool = false
		for n: int in g.neighbours(hottest):
			if g.is_empty(n):
				g.place(n, "coolant")
				placed = true
				break
		if not placed:
			return
