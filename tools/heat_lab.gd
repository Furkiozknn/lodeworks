extends SceneTree

## Heat, measured across the depths: does the same factory still work when
## the rock gets hotter, and what does it take to keep it working?
##
##   godot --headless --path . --script res://tools/heat_lab.gd
##
## Plain rock (no stratum modifiers, spread 0.5, ambient heat
## Strata.AMBIENT_PER_DEPTH a stratum), the real Grid and Simulation. It
## prints:
##   * the stratum at which each machine overheats standing alone;
##   * for each reference line -- the lines the scripted player builds for
##     the Core's first levels, and a dense Drill field -- at each depth:
##     machines overheating, machines at their working heat, output, and
##     what heats the hottest machine most;
##   * the same lines with every maker at the level the Core allows at that
##     depth -- more output, more heat;
##   * and then answered the way a player can: a Boiler set Low beside a
##     machine it overheats, the machine run Cool, the Coolant Cells raised
##     to the level the Core allows, a Coolant Cell on a free tile beside
##     it -- tried in that order on the hottest machine until nothing
##     overheats or nothing more can be done (docs/PROGRESSION.md, "Heat").

const DEPTHS := [0, 2, 4, 6, 8, 10, 12, 15, 18, 21, 24]

## The Core's first three lines (tools/core_journey_player.gd PLANS), each
## with its own Drills, and a dense Drill field sold into Vaults.
const LINES := {
	"smelter line (Core 1)": [
		[26, 21, "drill"], [25, 20, "drill"], [25, 21, "crusher"], [24, 21, "smelter"],
		[24, 20, "boiler"], [24, 22, "vault"], [24, 19, "lab"],
		[26, 23, "drill"], [25, 24, "drill"], [25, 23, "crusher"], [24, 23, "smelter"],
		[24, 24, "boiler"],
	],
	"press line (Core 2)": [
		[19, 27, "drill"], [21, 27, "drill"], [20, 27, "crusher"], [20, 26, "smelter"],
		[21, 26, "boiler"], [20, 25, "coolant"], [19, 24, "coolant"], [20, 24, "press"],
		[21, 24, "vault"],
		[23, 27, "drill"], [22, 27, "crusher"], [22, 26, "smelter"], [22, 25, "coolant"],
		[23, 24, "coolant"], [22, 24, "press"],
	],
	"assembler line (Core 3)": [
		[16, 19, "drill"], [16, 21, "drill"], [16, 20, "crusher"], [17, 20, "smelter"],
		[17, 21, "boiler"], [18, 19, "coolant"], [18, 21, "coolant"], [18, 20, "press"],
		[19, 21, "coolant"], [19, 20, "assembler"], [19, 19, "vault"],
	],
	"drill field": [
		[10, 10, "drill"], [11, 10, "vault"], [12, 10, "drill"], [13, 10, "vault"],
		[10, 11, "vault"], [11, 11, "drill"], [12, 11, "vault"], [13, 11, "drill"],
		[10, 12, "drill"], [11, 12, "vault"], [12, 12, "drill"], [13, 12, "vault"],
		[10, 13, "vault"], [11, 13, "drill"], [12, 13, "vault"], [13, 13, "drill"],
	],
}


func _initialize() -> void:
	TranslationServer.set_locale("en")
	print("== ALONE: the stratum at which a machine overheats with nothing beside it ==")
	for id: String in MachineDB.ORDER:
		var m: Dictionary = MachineDB.get_machine(id)
		if float(m["heat_tolerance"]) > 50.0:
			continue
		var at: float = (float(m["heat_tolerance"]) - float(m["heat_out"])) / Strata.AMBIENT_PER_DEPTH
		print("  %-10s heat %.1f, safe to %.1f: from stratum %d" % [id, float(m["heat_out"]),
			float(m["heat_tolerance"]), int(floor(at)) + 1])
	for name: String in LINES:
		print("\n== %s ==" % name)
		print("  stratum  over  working/levelled  credits/s  hottest, and what heats it most")
		for d: int in DEPTHS:
			_row(LINES[name], d, {})
		print("  -- every maker at the Core's limit for that depth:")
		for d: int in DEPTHS:
			_row(LINES[name], d, {"levels": true})
		print("  -- and answered (the actions taken are listed):")
		for d: int in DEPTHS:
			_row(LINES[name], d, {"levels": true, "answer": true})
	print("\n(%s)" % Time.get_datetime_string_from_system())
	quit(0)


## One line at one depth: build it on plain rock, run it, and report.
## `options` lets a caller ask for machine levels ("levels": {id: n}).
func _row(line: Array, depth: int, options: Dictionary) -> Dictionary:
	var g := Grid.new()
	var s := Simulation.new(g, 7)
	g.set_environment(Strata.AMBIENT_PER_DEPTH * float(depth), MachineDB.HEAT_SPREAD)
	for e: Array in line:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var cap: int = CoreLevels.machine_cap(CoreLevels.level_for_depth(depth))
	var levels: Dictionary = {}
	if bool(options.get("levels", false)):
		var hs: Dictionary = {}
		for id: String in MachineDB.ORDER:
			if MachineDB.level_is_speed(id):
				levels[id] = cap
				s.level_mult[id] = MachineDB.level_speed(cap)
				hs[id] = MachineDB.heat_factor(id, cap)
		g.set_heat_scale(hs)
		s.levels_stamp += 1
	var actions: Array[String] = []
	if bool(options.get("answer", false)):
		actions = _answer(g, s, cap)
	var out: Dictionary = s.measure(20.0, 30.0)
	var over: int = 0
	var working: int = 0
	var levelled: int = 0
	var hottest: int = -1
	var hot_by: float = -INF
	for c: int in g.cells:
		var id: String = g.machine_at(c)
		if not MachineDB.has_levels(id) or (MachineDB.get_machine(id)["tags"] as Array).has("sink"):
			continue
		levelled += 1
		if s.overheated_at(c):
			over += 1
		if s.status_of(c) == Simulation.Status.RUNNING and s.heat_efficiency_at(c) >= Simulation.THERMAL_WARNING:
			working += 1
		var m: Dictionary = MachineDB.get_machine(id)
		var by: float = g.heat_at(c) - float(m["heat_tolerance"])
		if by > hot_by:
			hot_by = by
			hottest = c
	var note: String = "-"
	if hottest >= 0 and hot_by > 0.0:
		note = "%s %.1f over; most from %s" % [g.machine_at(hottest), hot_by, _top_source(g, hottest)]
	if not actions.is_empty():
		note += "  [" + ", ".join(actions) + "]"
	print("  %7d  %4d  %7d/%-8d  %9.1f  %s" % [depth, over, working, levelled,
		float(out["credits_per_sec"]), note])
	return {"over": over, "working": working, "levelled": levelled, "rate": float(out["credits_per_sec"])}


## A player's answers, hottest machine first, until nothing overheats or
## nothing more can be done: a Boiler beside it set Low; the machine itself
## run Cool; the Coolant Cells raised to `cap`; a Coolant Cell on a free
## tile beside it. What was done, counted.
func _answer(g: Grid, s: Simulation, cap: int) -> Array[String]:
	var done: Dictionary = {}
	for _round in range(60):
		var hottest: int = -1
		var worst: float = 0.0
		for c: int in g.cells:
			var id: String = g.machine_at(c)
			var by: float = g.heat_at(c) - float(MachineDB.get_machine(id)["heat_tolerance"])
			if by > worst:
				worst = by
				hottest = c
		if hottest < 0:
			break
		var acted: bool = false
		for n: int in g.neighbours(hottest):
			if g.machine_at(n) == "boiler" and g.mode_at(n) == MachineDB.Mode.NORMAL:
				g.set_mode(n, MachineDB.Mode.COOL)
				done["Boiler low"] = int(done.get("Boiler low", 0)) + 1
				acted = true
				break
		if not acted and g.mode_at(hottest) == MachineDB.Mode.NORMAL \
				and MachineDB.modes_for(g.machine_at(hottest)).has(MachineDB.Mode.COOL):
			g.set_mode(hottest, MachineDB.Mode.COOL)
			done["run Cool"] = int(done.get("run Cool", 0)) + 1
			acted = true
		if not acted and float(g.heat_scale.get("coolant", 1.0)) < MachineDB.heat_factor("coolant", cap) - 0.001:
			var hs: Dictionary = g.heat_scale.duplicate()
			hs["coolant"] = MachineDB.heat_factor("coolant", cap)
			g.set_heat_scale(hs)
			done["Coolant level %d" % cap] = 1
			acted = true
		if not acted:
			for n: int in g.neighbours(hottest):
				if g.is_empty(n):
					g.place(n, "coolant")
					done["+Coolant"] = int(done.get("+Coolant", 0)) + 1
					acted = true
					break
		if not acted:
			done["stuck"] = 1
			break
	s.reset_progress()
	var out: Array[String] = []
	for k: String in done:
		out.append("%s x%d" % [k, int(done[k])] if int(done[k]) > 1 else k)
	return out


## What adds most heat to cell `i`: itself, a neighbour, or the rock.
func _top_source(g: Grid, i: int) -> String:
	var best: String = "the rock (%.1f)" % g.ambient_heat
	var amount: float = g.ambient_heat
	var own: float = g.emitted_at(i)
	if own > amount:
		amount = own
		best = "itself (%.1f)" % own
	for n: int in g.neighbours(i):
		var h: float = g.emitted_at(n) * g.heat_spread
		if h > amount:
			amount = h
			best = "a %s beside it (%.1f)" % [g.machine_at(n), h]
	return best
