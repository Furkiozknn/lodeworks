extends SceneTree

## The Factory Core's progression, played for hours and measured.
##
##   godot --headless --path . --script res://tools/core_journey.gd
##   LODEWORKS_CORE_HOURS=6 ... plays six hours instead of four.
##
## A competent player (tools/core_journey_player.gd) plays a new game on the
## real Sim at the real tick rate, and this prints:
##   * when each first happened: a Core level, a stratum, a machine type, a
##     machine level, a research level;
##   * the factory at 10 and 30 minutes and every hour: its Core, depth,
##     store, what the Core's next level still asks for, and how much there
##     is left to do (research levels, machine levels, machines not found,
##     strata left under the Core);
##   * the longest stretch with nothing new, the "dead zone" a player would
##     feel.
## Active play only: a player who is away earns offline at their measured
## rate (Economy.offline_yield), which this does not model.

const MARKS := [600.0, 1800.0, 3600.0, 7200.0, 10800.0, 14400.0, 18000.0, 21600.0]


func _initialize() -> void:
	TranslationServer.set_locale("en")
	var hours: float = maxf(float(OS.get_environment("LODEWORKS_CORE_HOURS")), 0.0)
	var horizon: float = (hours if hours > 0.0 else 4.0) * 3600.0
	var P: RefCounted = load("res://tools/core_journey_player.gd").new(root.get_node("Sim"))
	P.fresh()
	var marks: Array = MARKS.filter(func(m: float) -> bool: return m <= horizon)
	var mark: int = 0
	var started: int = Time.get_ticks_msec()
	print("== THE FACTORY CORE, PLAYED (%.1f h of active play) ==" % (horizon / 3600.0))
	while P.t < horizon:
		P.advance(P.BEAT)
		# The factory as it runs, before this beat's decisions change it.
		if mark < marks.size() and P.t >= float(marks[mark]):
			_snapshot(P.snapshot())
			mark += 1
		P.act()
	print("\n== FIRSTS ==")
	var last: float = 0.0
	var gap: float = 0.0
	var gap_at: float = 0.0
	for e: Array in P.events:
		print("  %7s  %s" % [_clock(float(e[0])), String(e[1])])
		if float(e[0]) - last > gap:
			gap = float(e[0]) - last
			gap_at = last
		last = float(e[0])
	if horizon - last > gap:
		gap = horizon - last
		gap_at = last
	print("\n== THE LONGEST STRETCH WITH NOTHING NEW ==")
	print("  %s from %s" % [_clock(gap), _clock(gap_at)])
	print("\n(%.0f s of wall clock)" % ((Time.get_ticks_msec() - started) / 1000.0))
	root.get_node("Save").wipe()
	quit(0)


func _snapshot(s: Dictionary) -> void:
	print("\n-- at %s --" % _clock(float(s["t"])))
	print("  Core level %d, stratum %d, %d machines, earning %s/s, lifetime %s credits" % [int(s["core"]),
		int(s["depth"]), int(s["machines"]), Economy.fmt(float(s["rate"])), Economy.fmt(float(s["lifetime"]))])
	var stock: Array[String] = []
	for res: int in (s["stock"] as Dictionary):
		stock.append("%s %d" % [String(MachineDB.RES_NAME[res]), int(s["stock"][res])])
	print("  store (holds %d each): %s" % [int(s["store"]), ", ".join(stock) if not stock.is_empty() else "empty"])
	print("  machine levels: %s" % str(s["levels"]))
	print("  research: %s" % str(s["research"]))
	print("  the Core's next level still asks for: %s" % (", ".join(s["open"]) if not (s["open"] as Array).is_empty() else "nothing -- it can grow"))
	print("  left to do: %d research levels open, %d machine levels open, %d machines not found, %d strata under the Core"
		% [int(s["research_left"]), int(s["upgrades_left"]), int(s["locked"]), int(s["strata_left"])])


func _clock(s: float) -> String:
	var m: int = int(s) / 60
	return "%d:%02d:%02d" % [m / 60, m % 60, int(s) % 60]
