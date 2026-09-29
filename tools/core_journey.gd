extends SceneTree

## The Factory Core's progression, played for hours and measured.
##
##   godot --headless --path . --script res://tools/core_journey.gd
##   LODEWORKS_CORE_HOURS=6 ... plays six hours instead of four.
##   LODEWORKS_CORE_TARGET=7 ... stops once the Core reaches level 7.
##   LODEWORKS_CORE_SKIP=1 ... fast-forwards a stretch where the only row
##     left is credits and the factory has stopped changing (see `_skip`).
##   LODEWORKS_CORE_DUMP=7:<file> ... writes the save of the factory the
##     moment every row of the Core's level 7 is met, before it grows: the
##     fixture tests/test_core7.gd plays from.
##   LODEWORKS_CORE_CARRY=<file> ... a new game that starts with what a
##     collapse keeps: {"upgrades": {line: level}, "cores": n} -- the second
##     shaft, measured against the first.
##   LODEWORKS_CORE_SALVAGE=gearing|crew|none ... what the scripted player
##     spends the galleries' salvage on (its salvage_mode).
##   LODEWORKS_CORE_REGION=sunken|caverns|foundry ... the region of the deep
##     map the player opens first (from Core 10; the caverns when not given).
##   LODEWORKS_CORE_DOCTRINE=deep|thermal|precision ... the doctrine the
##     player follows from the Core's level 7 (Economy.DOCTRINES); deep when
##     not given.
##   LODEWORKS_CORE_COLLAPSE=8 ... once the Core reaches level 8, the player
##     saves the board as a blueprint, collapses, lays the blueprint in the
##     new shaft and plays on: the second shaft, as the game plays it.
##   LODEWORKS_CORE_KEEP=6:<file> ... writes the game and the player the
##     moment the Core reaches level 6; LODEWORKS_CORE_FROM=<file> plays on
##     from there. For trying a later level's rules without replaying the
##     early ones: the machines' part-done cycles are not kept, so a run
##     from it is close to, not the same as, the run it was written in.
##
## A competent player (tools/core_journey_player.gd) plays a new game on the
## real Sim at the real tick rate, and this prints:
##   * when each first happened: a Core level, a stratum, a machine type, a
##     machine level, a research level;
##   * the factory at 10 and 30 minutes and every hour: its Core, depth,
##     store, what the Core's next level still asks for, and how much there
##     is left to do (research levels, machine levels, machines not found,
##     strata left under the Core);
##   * each Core level as a stage: what it opened, what the next one asked
##     for and when each row was met, how long only credits were left (the
##     wait), how many decisions the player made and in how many minutes,
##     and where the credits went;
##   * the longest stretch with nothing new, the "dead zone" a player would
##     feel.
## Active play only: a player who is away earns offline at their measured
## rate (Economy.offline_yield), which this does not model.

const EARLY_MARKS := [600.0, 1800.0]

## A credit-only stretch is skipped only after the factory has sat in it,
## unchanged, for this long: the rate it is skipped at is the one measured
## over that time.
const SKIP_AFTER := 1200.0
const SKIP_CHUNK := 3600.0

var P: RefCounted
var stages: Array = []
var stage: Dictionary = {}
var _board: Dictionary = {}
var _levels: Dictionary = {}
var _research: Dictionary = {}
var _overdrive: Dictionary = {}
var _contracts: int = 0
var _depth: int = 0
## [t, lifetime credits, research] while only credits are left.
var _wait_log: Array = []
var skipped: float = 0.0
## The crew as last seen, and sorties sent since (Sim.sortie_sent).
var _sorties_sent: int = 0
var _posted: int = 0
var _bay: int = 1
var _wear: float = 0.0


func _initialize() -> void:
	TranslationServer.set_locale("en")
	var hours: float = maxf(float(OS.get_environment("LODEWORKS_CORE_HOURS")), 0.0)
	var horizon: float = (hours if hours > 0.0 else 4.0) * 3600.0
	var target: int = int(OS.get_environment("LODEWORKS_CORE_TARGET"))
	var skip: bool = OS.get_environment("LODEWORKS_CORE_SKIP") == "1"
	var dump: String = OS.get_environment("LODEWORKS_CORE_DUMP")
	var dump_level: int = int(dump.get_slice(":", 0)) if dump != "" else 0
	P = load("res://tools/core_journey_player.gd").new(root.get_node("Sim"))
	P.fresh()
	P.S.sortie_sent.connect(func(_i: int, _n: int) -> void: _sorties_sent += 1)
	P.S.sortie_back.connect(_tally)
	if OS.get_environment("LODEWORKS_CORE_DOCTRINE") != "":
		P.doctrine = OS.get_environment("LODEWORKS_CORE_DOCTRINE")
	if OS.get_environment("LODEWORKS_CORE_SALVAGE") != "":
		P.salvage_mode = OS.get_environment("LODEWORKS_CORE_SALVAGE")
		print("  (salvage goes to: %s)" % P.salvage_mode)
	if Operations.REGIONS.has(OS.get_environment("LODEWORKS_CORE_REGION")):
		P.region_first = OS.get_environment("LODEWORKS_CORE_REGION")
		print("  (the first region of the deep map: %s)" % P.region_first)
	var collapse_at: int = int(OS.get_environment("LODEWORKS_CORE_COLLAPSE"))
	var carry: String = OS.get_environment("LODEWORKS_CORE_CARRY")
	if carry != "":
		var kept: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(carry))
		for id: String in (kept.get("upgrades", {}) as Dictionary):
			P.S.upgrade_levels[id] = int(kept["upgrades"][id])
		P.S.cores = int(kept.get("cores", 0))
		P.S.collapses = 1
		P.S._recompute()
		print("  (a second shaft: the tree %s and %d Cores kept)" % [str(P.S.upgrade_levels), P.S.cores])
	var keep: String = OS.get_environment("LODEWORKS_CORE_KEEP")
	var keep_level: int = int(keep.get_slice(":", 0)) if keep != "" else 0
	var from: String = OS.get_environment("LODEWORKS_CORE_FROM")
	if from != "":
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(from))
		P.S.from_dict(saved["sim"])
		P.restore(saved["player"])
		print("  (playing on from %s, Core %d at %s)" % [from.get_file(), int(P.S.core_level), _clock(P.t)])
		# Another doctrine than the kept game's: the choice is undone, and
		# the research its lines took is given back, so each doctrine
		# starts the era from the same factory.
		var want: String = OS.get_environment("LODEWORKS_CORE_DOCTRINE")
		if want != "" and String(P.S.doctrine) != want:
			for id: String in Economy.RESEARCH_TREE:
				if Economy.doctrine_of(id) == "":
					continue
				for k in range(int(P.S.upgrade_level(id))):
					P.S.research += float(Economy.upgrade_cost(id, k)["research"])
				P.S.upgrade_levels.erase(id)
			P.S.doctrine = ""
			P.doctrine = want
			P.S._recompute()
			print("  (the doctrine undone for %s)" % want)
	var marks: Array = EARLY_MARKS.duplicate()
	var h: float = 3600.0
	while h <= horizon:
		marks.append(h)
		h += 3600.0
	var mark: int = 0
	while mark < marks.size() and float(marks[mark]) < P.t:
		mark += 1
	var started: int = Time.get_ticks_msec()
	print("== THE FACTORY CORE, PLAYED (%.1f h of active play%s) ==" % [horizon / 3600.0,
		", credit-only waits fast-forwarded" if skip else ""])
	_remember()
	_open_stage()
	while P.t < horizon:
		P.advance(P.BEAT)
		# The factory as it runs, before this beat's decisions change it.
		while mark < marks.size() and P.t >= float(marks[mark]):
			_snapshot(P.snapshot())
			mark += 1
		var level: int = int(P.S.core_level)
		if dump_level > 0 and level == dump_level - 1 and P.S.can_upgrade_core():
			var f := FileAccess.open(dump.substr(dump.find(":") + 1), FileAccess.WRITE)
			var save: Dictionary = P.S.to_dict()
			# What the scripted player measured: its income over the last
			# minute, and when.
			save["journey_rate"] = P.rate()
			save["journey_t"] = P.t
			f.store_string(JSON.stringify(save, "\t"))
			f.close()
			print("  (the factory ready for Core %d written at %s)" % [dump_level, _clock(P.t)])
			dump_level = 0
		P.act()
		_record(level)
		if keep_level > 0 and int(P.S.core_level) == keep_level:
			var kf := FileAccess.open(keep.substr(keep.find(":") + 1), FileAccess.WRITE)
			kf.store_string(JSON.stringify({"sim": P.S.to_dict(), "player": P.state()}))
			kf.close()
			print("  (the game at Core %d kept at %s)" % [keep_level, _clock(P.t)])
			keep_level = 0
		if collapse_at > 0 and int(P.S.core_level) >= collapse_at:
			_collapse()
			collapse_at = 0
		if target > 0 and int(P.S.core_level) >= target and collapse_at == 0:
			break
		if skip:
			_skip(horizon)
	_close_stage(false)
	_print_crew()
	print("\n== FIRSTS ==")
	var last: float = 0.0
	var gap: float = 0.0
	var gap_at: float = 0.0
	for e: Array in P.events:
		print("  %9s  %s" % [_clock(float(e[0])), String(e[1])])
		if float(e[0]) - last > gap:
			gap = float(e[0]) - last
			gap_at = last
		last = float(e[0])
	if P.t - last > gap:
		gap = P.t - last
		gap_at = last
	print("\n== THE LONGEST STRETCH WITH NOTHING NEW ==")
	print("  %s from %s" % [_clock(gap), _clock(gap_at)])
	_print_stages()
	if skipped > 0.0:
		print("\n(%s of credit-only waiting fast-forwarded at the measured rate)" % _clock(skipped))
	print("\n(%.0f s of wall clock)" % ((Time.get_ticks_msec() - started) / 1000.0))
	root.get_node("Save").wipe()
	quit(0)


## The first shaft ends: the board saved as a blueprint, the shaft
## collapsed, the blueprint laid in the next one -- what is kept and what
## the blueprint finds, printed.
func _collapse() -> void:
	var S: Node = P.S
	_close_stage(false)
	stage["collapsed"] = true
	S.save_blueprint(0)
	var level: int = int(S.core_level)
	var gained: int = S.collapse()
	P.new_shaft()
	var rep: Dictionary = S.lay_blueprint(0)
	print("\n-- at %s: collapsed at Core %d for %d Cores; the new shaft's Core starts at %d --" % [
		_clock(P.t), level, gained, int(S.core_level)])
	print("  kept: the tree %s, %d Cores, the blueprint (%d machines)" % [str(S.upgrade_levels), int(S.cores),
		(S.blueprint(0).get("cells", []) as Array).size()])
	print("  the blueprint, laid on the new shaft's ground: %s; %s credits for what can go down now" % [
		str(rep.get("why", {})), Economy.fmt(float(rep.get("cost", 0.0)))])
	_board = _board_now()
	_remember()
	_open_stage()


## --- stages: one per Core level ------------------------------------------------------

## The deep map's sorties, from Core 10: {purpose: {"R/B/V": count}} --
## purpose the region's ground and kind of work -- and {region: [sorties,
## seconds out, units home]}.
var _teams: Dictionary = {}
var _regions_time: Dictionary = {}


func _tally(e: Dictionary) -> void:
	if int(P.S.core_level) < Operations.REGION_CORE:
		return
	var kind: String = String(e["kind"])
	var reg: String = String(e.get("region", ""))
	var purpose: String = kind if kind in ["survey", "beacon"] else ("region " + kind if reg != "" else "galleries")
	var combo: String = "%d/%d/%d" % [int(e["rigs"]), int(e["breakers"]), int(e["surveyors"])]
	var byp: Dictionary = _teams.get(purpose, {})
	byp[combo] = int(byp.get(combo, 0)) + 1
	_teams[purpose] = byp
	var key: String = reg if reg != "" else "galleries"
	var row: Array = _regions_time.get(key, [0, 0.0, 0])
	row[0] = int(row[0]) + 1
	row[1] = float(row[1]) + float(e.get("trip", 0.0))
	row[2] = int(row[2]) + int(e.get("n", 0))
	_regions_time[key] = row


func _print_crew() -> void:
	if _teams.is_empty():
		return
	print("\n== THE CREW ON THE DEEP MAP, FROM CORE 10 ==")
	print("  teams (Rigs/Breakers/Surveyors) by what they went for, most used first:")
	for purpose: String in _teams:
		var byp: Dictionary = _teams[purpose]
		var keys: Array = byp.keys()
		keys.sort_custom(func(a: String, b: String) -> bool: return int(byp[a]) > int(byp[b]))
		var parts: Array[String] = []
		var total: int = 0
		for k: String in keys:
			total += int(byp[k])
		for k: String in keys.slice(0, 4):
			parts.append("%s x%d" % [k, int(byp[k])])
		print("    %-22s %4d sorties: %s" % [purpose, total, ", ".join(parts)])
	print("  where the crew spent its time out (sorties, minutes out, units home):")
	for key: String in _regions_time:
		var row: Array = _regions_time[key]
		print("    %-12s %4d  %6.0f min  %d" % [key, int(row[0]), float(row[1]) / 60.0, int(row[2])])


func _open_stage() -> void:
	var S: Node = P.S
	var level: int = int(S.core_level)
	var rows: Array = CoreLevels.requirements(level + 1)
	var upgrades: int = 0
	for id: String in MachineDB.ORDER:
		if S.is_unlocked(id) and MachineDB.has_levels(id):
			upgrades += maxi(S.machine_level_cap() - S.machine_level(id), 0)
	var research_open: int = 0
	for id: String in Economy.TREE_ORDER:
		if int(Economy.RESEARCH_TREE[id]["cost_cores"]) == 0:
			research_open += maxi(S.research_cap(id) - S.upgrade_level(id), 0)
	var makers: Array[String] = []
	for id: String in MachineDB.ORDER:
		if S.is_unlocked(id) and not (MachineDB.get_machine(id)["outputs"] as Dictionary).is_empty():
			makers.append(id)
	var first: Array = []
	for _r in rows:
		first.append(-1.0)
	stage = {"level": level, "shaft": int(S.collapses) + 1, "t0": P.t, "rows": rows, "first": first, "wait": 0.0,
		"decisions": {}, "minutes": {}, "rate0": P.rate(), "levels_spent": 0.0,
		"upgrades_open": upgrades, "research_open": research_open,
		"makers": makers, "opens": CoreLevels.opens(level + 1), "skipped": 0.0,
		"research_bought": 0, "life0": float(S.lifetime_credits), "credits0": float(S.credits),
		"research_spent": 0.0, "research0": float(S.research), "overdrive": 0,
		# The crew over the stage: sites, salvage, hauling, and where the
		# Rigs were, beat by beat; and how much of the store stood full.
		"lens_spent0": S.lens_spent.duplicate(), "lens0": S.stock_of(MachineDB.Res.LENS),
		"sites0": int(S.ops_lifetime), "salvage_earned0": int(S.salvage_earned),
		"salvage0": int(S.salvage), "hauled0": int(S.hauled), "beats": 0,
		"rigs_out": 0, "rigs_posted": 0, "rigs_home": 0, "full": 0, "kept": 0,
		"collapse": Economy.cores_for_collapse(int(S.max_depth), float(S.lifetime_credits),
			float(S.mult().get("core_yield", 0.0)))}
	_wait_log.clear()


func _close_stage(reached: bool) -> void:
	stage["t1"] = P.t
	stage["life1"] = float(P.S.lifetime_credits)
	stage["research1"] = float(P.S.research)
	# The Core's price was paid on the beat it grew; credits now are after it.
	stage["credits1"] = float(P.S.credits)
	stage["core_paid"] = 0.0
	if reached:
		for r: Array in CoreLevels.requirements(int(stage["level"]) + 1):
			if int(r[0]) == CoreLevels.Req.CREDITS:
				stage["core_paid"] = float(r[1])
	if reached:
		# Rows first met on the beat the Core grew.
		for i in range((stage["first"] as Array).size()):
			if float(stage["first"][i]) < 0.0:
				stage["first"][i] = P.t - float(stage["t0"])
	stage["reached"] = reached
	stage["rate1"] = P.rate()
	stage["sites1"] = int(P.S.ops_lifetime)
	stage["salvage_earned1"] = int(P.S.salvage_earned)
	stage["salvage1"] = int(P.S.salvage)
	stage["hauled1"] = int(P.S.hauled)
	stage["lens_spent1"] = P.S.lens_spent.duplicate()
	stage["lens1"] = P.S.stock_of(MachineDB.Res.LENS)
	stages.append(stage)


## What changed this beat, counted as the player's decisions, and which of
## the Core's rows are met.
func _record(level_before: int) -> void:
	var S: Node = P.S
	stage["beats"] = int(stage["beats"]) + 1
	stage["rigs_out"] = int(stage["rigs_out"]) + S.rigs_out() + S.breakers_out() + S.surveyors_out()
	stage["rigs_posted"] = int(stage["rigs_posted"]) + S.rigs_posted()
	stage["rigs_home"] = int(stage["rigs_home"]) + S.rigs_home() + S.breakers + S.surveyors
	stage["breakers"] = maxi(int(stage.get("breakers", 0)), S.breakers + S.breakers_out())
	for res: int in MachineDB.STOCKED:
		if S.stock_of(int(res)) > 0:
			stage["kept"] = int(stage["kept"]) + 1
			if S.stock_of(int(res)) >= S.stock_cap():
				stage["full"] = int(stage["full"]) + 1
	var d: Dictionary = stage["decisions"]
	var n: int = 0
	var now: Dictionary = _board_now()
	for cell: int in now:
		if not _board.has(cell) or String(_board[cell]).get_slice("|", 0) != String(now[cell]).get_slice("|", 0):
			d["placed"] = int(d.get("placed", 0)) + 1
			n += 1
		elif _board[cell] != now[cell]:
			d["modes"] = int(d.get("modes", 0)) + 1
			n += 1
	for cell: int in _board:
		if not now.has(cell) or String(_board[cell]).get_slice("|", 0) != String(now[cell]).get_slice("|", 0):
			d["sold"] = int(d.get("sold", 0)) + 1
			n += 1
	for id: String in S.machine_levels:
		var was: int = int(_levels.get(id, 1))
		for k in range(was + 1, int(S.machine_levels[id]) + 1):
			d["machine levels"] = int(d.get("machine levels", 0)) + 1
			stage["levels_spent"] = float(stage["levels_spent"]) + MachineDB.level_price(id, k)
			n += 1
	for id: String in S.upgrade_levels:
		var was_r: int = int(_research.get(id, 0))
		var up: int = int(S.upgrade_levels[id]) - was_r
		if up > 0:
			d["research"] = int(d.get("research", 0)) + up
			stage["research_bought"] = int(stage["research_bought"]) + up
			for k in range(was_r, int(S.upgrade_levels[id])):
				stage["research_spent"] = float(stage["research_spent"]) \
					+ float(Economy.upgrade_cost(id, k)["research"])
				if Economy.doctrine_of(id) != "":
					stage["research_doctrine"] = float(stage.get("research_doctrine", 0.0)) \
						+ float(Economy.upgrade_cost(id, k)["research"])
			n += up
	for id: String in S.overdrive:
		var steps: int = int(S.overdrive[id]) - int(_overdrive.get(id, 0))
		if steps > 0:
			d["overdrive"] = int(d.get("overdrive", 0)) + steps
			stage["overdrive"] = int(stage["overdrive"]) + steps
			for k in range(int(_overdrive.get(id, 0)) + 1, int(S.overdrive[id]) + 1):
				stage["research_spent"] = float(stage["research_spent"]) \
					+ float(MachineDB.overdrive_cost(k)["research"])
				stage["research_od"] = float(stage.get("research_od", 0.0)) \
					+ float(MachineDB.overdrive_cost(k)["research"])
			n += steps
	if int(S.contracts_lifetime) > _contracts:
		d["contracts"] = int(d.get("contracts", 0)) + int(S.contracts_lifetime) - _contracts
		n += int(S.contracts_lifetime) - _contracts
	if int(S.depth) != _depth:
		d["strata"] = int(d.get("strata", 0)) + absi(int(S.depth) - _depth)
		n += 1
	# The crew's decisions: a sortie sent, a Rig posted or called home, the
	# Bay raised, the crew repaired.
	if _sorties_sent > 0:
		d["sorties"] = int(d.get("sorties", 0)) + _sorties_sent
		n += _sorties_sent
		_sorties_sent = 0
	if S.rigs_posted() != _posted:
		d["posts"] = int(d.get("posts", 0)) + absi(S.rigs_posted() - _posted)
		n += 1
	if int(S.bay_level) != _bay:
		d["the Bay"] = int(d.get("the Bay", 0)) + 1
		n += 1
	if float(S.rig_wear) < _wear - 0.001 and float(S.rig_wear) <= 0.0:
		d["repairs"] = int(d.get("repairs", 0)) + 1
		n += 1
	_posted = S.rigs_posted()
	_bay = int(S.bay_level)
	_wear = float(S.rig_wear)
	_board = now
	_remember()
	if n > 0:
		(stage["minutes"] as Dictionary)[int(P.t / 60.0)] = true
	if int(S.core_level) != level_before:
		_close_stage(true)
		_open_stage()
		return
	# Which rows are met, and whether only credits are left.
	var status: Array = S.core_status()
	var only_credits: bool = true
	for i in range(status.size()):
		var met: bool = bool(status[i]["met"])
		if met and float(stage["first"][i]) < 0.0:
			stage["first"][i] = P.t - float(stage["t0"])
		if not met and int(status[i]["req"][0]) != CoreLevels.Req.CREDITS:
			only_credits = false
	var credits_open: bool = status.any(func(s: Dictionary) -> bool:
		return int(s["req"][0]) == CoreLevels.Req.CREDITS and not bool(s["met"]))
	if _saving(status):
		stage["saving"] = float(stage.get("saving", 0.0)) + P.BEAT
	if only_credits and credits_open:
		stage["wait"] = float(stage["wait"]) + P.BEAT
		_wait_log.append([P.t, float(S.lifetime_credits), float(S.research)])
	else:
		_wait_log.clear()


## Every row still open can be had for credits alone: the Core's price, or
## a machine or Vault level short of nothing but credits.
func _saving(status: Array) -> bool:
	var S: Node = P.S
	var any: bool = false
	for st: Dictionary in status:
		if bool(st["met"]):
			continue
		any = true
		var r: Array = st["req"]
		match int(r[0]):
			CoreLevels.Req.CREDITS:
				pass
			CoreLevels.Req.MACHINE:
				if S.machine_upgrade_blocker(String(r[1])) != "credits":
					return false
			CoreLevels.Req.STOCK:
				if int(st["cap"]) >= int(st["need"]) or S.machine_upgrade_blocker("vault") != "credits":
					return false
			_:
				return false
	return any


func _board_now() -> Dictionary:
	var out: Dictionary = {}
	var g: Grid = P.S.grid
	for cell: int in g.cells:
		out[cell] = "%s|%d|%s" % [g.machine_at(cell), g.mode_at(cell), g.job_at(cell)]
	return out


func _remember() -> void:
	var S: Node = P.S
	_levels = S.machine_levels.duplicate()
	_research = S.upgrade_levels.duplicate()
	_overdrive = S.overdrive.duplicate()
	_contracts = int(S.contracts_lifetime)
	_depth = int(S.depth)


## Fast-forward a credit-only wait: once only credits have been left for
## SKIP_AFTER seconds, the factory is left as it is and earns at the rate
## it earned over that time (contracts filled in it included), up to an
## hour at a time and never past the credits the Core asks for.
func _skip(horizon: float) -> void:
	if _wait_log.size() < 2 or P.t - float(_wait_log[0][0]) < SKIP_AFTER:
		return
	var a: Array = _wait_log[0]
	var span: float = P.t - float(a[0])
	var rate: float = (float(P.S.lifetime_credits) - float(a[1])) / span
	var r_rate: float = maxf((float(P.S.research) - float(a[2])) / span, 0.0)
	if rate <= 0.0:
		return
	var need: float = 0.0
	for s: Dictionary in P.S.core_status():
		if int(s["req"][0]) == CoreLevels.Req.CREDITS:
			need = float(s["need"]) - float(P.S.credits)
	var dt: float = minf(minf(need / rate - 60.0, SKIP_CHUNK), horizon - P.t)
	if dt < 600.0:
		return
	P.S.credits += rate * dt
	P.S.lifetime_credits += rate * dt
	P.S.research += r_rate * dt
	P.t += dt
	P.fast_forwarded(dt, rate * dt)
	skipped += dt
	stage["wait"] = float(stage["wait"]) + dt
	stage["skipped"] = float(stage["skipped"]) + dt
	_wait_log.clear()


func _print_stages() -> void:
	print("\n== EACH CORE LEVEL AS A STAGE ==")
	for s: Dictionary in stages:
		var level: int = int(s["level"])
		var dur: float = float(s["t1"]) - float(s["t0"])
		if dur <= 0.0:
			continue
		print("\n%sCore %d -> %d: %s -> %s (%s%s)" % ["" if int(s["shaft"]) == 1 else "Shaft %d, " % int(s["shaft"]),
			level, level + 1, _clock(float(s["t0"])), _clock(float(s["t1"])), _clock(dur),
			"" if bool(s["reached"]) else (", collapsed" if bool(s.get("collapsed", false)) else ", not reached")])
		var o: Dictionary = s["opens"]
		print("  Core %d would open: strata %d-%d, machine levels to %d, research %s, machines %s" % [
			level + 1, int(o["strata"][0]), int(o["strata"][1]), int(o["machine_cap"]),
			str(o["research"]), str(o["machines"])])
		print("  at the start: %d machine levels and %d research levels open under the Core; makers: %s" % [
			int(s["upgrades_open"]), int(s["research_open"]), ", ".join(s["makers"])])
		print("  rows, first met after:")
		var last_other: float = 0.0
		for i in range((s["rows"] as Array).size()):
			var r: Array = s["rows"][i]
			var f: float = float(s["first"][i])
			print("    %-34s %s" % [_row_text(r), _clock(f) if f >= 0.0 else "not met"])
			if int(r[0]) != CoreLevels.Req.CREDITS:
				last_other = maxf(last_other, f if f >= 0.0 else dur)
		var wait: float = float(s["wait"])
		print("  every other row met after %s; only credits left for %s (%d%% of the stage)%s" % [
			_clock(last_other), _clock(wait), int(round(100.0 * wait / dur)),
			" -- %s of it fast-forwarded" % _clock(float(s["skipped"])) if float(s["skipped"]) > 0.0 else ""])
		var saving: float = float(s.get("saving", 0.0)) + float(s["skipped"])
		print("  saving -- only rows credits alone buy (the Core, a level) left: %s (%d%% of the stage)" % [
			_clock(saving), int(round(100.0 * saving / dur))])
		var parts: Array[String] = []
		var total: int = 0
		for k: String in s["decisions"]:
			parts.append("%s %d" % [k, int(s["decisions"][k])])
			total += int(s["decisions"][k])
		var minutes: int = (s["minutes"] as Dictionary).size()
		var span: int = int(float(s["t1"]) / 60.0) - int(float(s["t0"]) / 60.0) + 1
		print("  decisions: %d in %d of %d minutes (%s)" % [total, minutes, span,
			", ".join(parts)])
		var earned: float = float(s["life1"]) - float(s["life0"])
		var spent: float = earned - (float(s["credits1"]) - float(s["credits0"]))
		var machines: float = spent - float(s["levels_spent"]) - float(s["core_paid"])
		print("  income %s/s -> %s/s (%s/s over the stage); earned %s: machine levels %s, the Core %s, machines %s" % [
			Economy.fmt(float(s["rate0"])), Economy.fmt(float(s["rate1"])), Economy.fmt(earned / dur),
			Economy.fmt(earned), Economy.fmt(float(s["levels_spent"])), Economy.fmt(float(s["core_paid"])),
			Economy.fmt(machines)])
		print("  research: %s made, %s spent on %d levels; Overdrive steps %d; a collapse at the start would have paid %d Cores" % [
			Economy.fmt(float(s.get("research1", 0.0)) - float(s["research0"]) + float(s["research_spent"])),
			Economy.fmt(float(s["research_spent"])), int(s["research_bought"]), int(s["overdrive"]),
			int(s["collapse"])])
		var beats: float = maxf(float(s["beats"]), 1.0)
		var rigs: float = maxf(float(int(s["rigs_out"]) + int(s["rigs_posted"]) + int(s["rigs_home"])), 1.0)
		var sites: int = int(s["sites1"]) - int(s["sites0"])
		var earned_s: int = int(s["salvage_earned1"]) - int(s["salvage_earned0"])
		print("  the crew: %.1f Rigs on average -- %d%% out on sorties, %d%% posted, %d%% at the Bay; %d sites cleared (%.1f an hour); salvage %d earned, %d spent; %d units hauled from the store" % [
			rigs / beats, int(round(100.0 * float(s["rigs_out"]) / rigs)), int(round(100.0 * float(s["rigs_posted"]) / rigs)),
			int(round(100.0 * float(s["rigs_home"]) / rigs)), sites, float(sites) / (dur / 3600.0),
			earned_s, earned_s - (int(s["salvage1"]) - int(s["salvage0"])), int(s["hauled1"]) - int(s["hauled0"])])
		if int(s.get("breakers", 0)) > 0:
			print("  Breakers in the crew: up to %d" % int(s["breakers"]))
		# The Lenses over the stage: what was ground, and where it went.
		var ls0: Dictionary = s.get("lens_spent0", {})
		var ls1: Dictionary = s.get("lens_spent1", {})
		var went: Array[String] = []
		var lens_out: int = 0
		for why: String in ["core", "expedition", "beacon", "upkeep", "light", "factory", "contract"]:
			var d: int = int(ls1.get(why, 0)) - int(ls0.get(why, 0))
			lens_out += d
			if d > 0:
				went.append("%s %s" % [why, Economy.fmt(float(d))])
		var made: int = lens_out + int(s.get("lens1", 0)) - int(s.get("lens0", 0))
		if made > 0 or lens_out > 0:
			print("  Lenses: %s ground; spent %s (%s); %s in the store at the end" % [Economy.fmt(float(made)),
				Economy.fmt(float(lens_out)), ", ".join(went) if not went.is_empty() else "none",
				Economy.fmt(float(int(s.get("lens1", 0))))])
		print("  the store: %d%% of the time a material it keeps stood at the Vault's limit" % [
			int(round(100.0 * float(s["full"]) / maxf(float(s["kept"]), 1.0)))])
		if float(s.get("research_od", 0.0)) + float(s.get("research_doctrine", 0.0)) > 0.0:
			print("    of it: Overdrive %s, doctrine lines %s, the rest of the tree %s" % [
				Economy.fmt(float(s.get("research_od", 0.0))), Economy.fmt(float(s.get("research_doctrine", 0.0))),
				Economy.fmt(float(s["research_spent"]) - float(s.get("research_od", 0.0))
					- float(s.get("research_doctrine", 0.0)))])


func _row_text(r: Array) -> String:
	var name: String = ["credits", "stock", "working", "machine", "depth", "research", "serves",
		"stable", "overdrive", "doctrine", "operations", "regions", "region lines", "roles", "beacons"][int(r[0])]
	match int(r[0]):
		CoreLevels.Req.CREDITS:
			return "credits %s" % Economy.fmt(float(r[1]))
		CoreLevels.Req.STOCK:
			return "stock %s %d" % [String(MachineDB.RES_NAME[int(r[1])]), int(r[2])]
		CoreLevels.Req.DEPTH, CoreLevels.Req.STABLE, CoreLevels.Req.DOCTRINE, CoreLevels.Req.OPERATIONS, 				CoreLevels.Req.REGIONS, CoreLevels.Req.REGION_LINES, CoreLevels.Req.ROLES, CoreLevels.Req.BEACONS:
			return "%s %d" % [name, int(r[1])]
	var job: String = " (%s)" % CoreLevels.row_job(r) if CoreLevels.row_job(r) != "" else ""
	return "%s %s %d%s" % [name, str(r[1]), int(r[2]), job]


func _snapshot(s: Dictionary) -> void:
	print("\n-- at %s --" % _clock(float(s["t"])))
	print("  Core level %d, stratum %d, %d machines, earning %s/s, lifetime %s credits" % [int(s["core"]),
		int(s["depth"]), int(s["machines"]), Economy.fmt(float(s["rate"])), Economy.fmt(float(s["lifetime"]))])
	var stock: Array[String] = []
	for res: int in (s["stock"] as Dictionary):
		stock.append("%s %d" % [String(MachineDB.RES_NAME[res]), int(s["stock"][res])])
	print("  store (holds %d each): %s" % [int(s["store"]), ", ".join(stock) if not stock.is_empty() else "empty"])
	print("  machine levels: %s" % str(s["levels"]))
	print("  research: %s; %s research banked" % [str(s["research"]), Economy.fmt(float(s["research_banked"]))])
	print("  the Core's next level still asks for: %s" % (", ".join(s["open"]) if not (s["open"] as Array).is_empty() else "nothing -- it can grow"))
	print("  left to do: %d research levels open, %d machine levels open, %d machines not found, %d strata under the Core"
		% [int(s["research_left"]), int(s["upgrades_left"]), int(s["locked"]), int(s["strata_left"])])
	print("  at working heat: %s" % str(s["working"]))
	if not (s["held"] as Dictionary).is_empty():
		print("  off the working line: %s" % str(s["held"]))
	if not (s["hot"] as Array).is_empty():
		print("  overheating: %s" % "; ".join(s["hot"]))
	print("  contracts filled: %d" % int(s["contracts"]))
	print("  the galleries: %d Rigs (%d posted, Bay %d), %d Breakers and %d Surveyors, %d sites cleared in all, salvage %d earned / %d unspent, %d units hauled"
		% [int(s.get("crew", 0)), int(s.get("posted", 0)), int(s.get("bay", 1)), int(s.get("breakers", 0)),
		int(s.get("surveyors", 0)), int(s.get("sites", 0)), int(s.get("salvage_earned", 0)), int(s.get("salvage", 0)),
		int(s.get("hauled", 0))])
	if not (s.get("regions", []) as Array).is_empty():
		print("  the deep map: %s open; Beacons: %s%s; %d Surveyors tuning; %d rescued" % [", ".join(s["regions"]),
			", ".join(s.get("beacons", [])) if not (s.get("beacons", []) as Array).is_empty() else "none",
			" (dark)" if bool(s.get("dark", false)) else "", int(s.get("tuners", 0)), int(s.get("rescued", 0))])
		print("  Lenses: %s in the store; spent in all: %s" % [Economy.fmt(float(int(s.get("lens", 0)))),
			str(s.get("lens_spent", {}))])
	var sp: Array[String] = []
	for k: String in (s.get("spend", {}) as Dictionary):
		sp.append("%s %s" % [k, Economy.fmt(float(s["spend"][k]))])
	if not sp.is_empty():
		print("  credits spent since the last mark: %s" % ", ".join(sp))
	if String(s.get("doctrine", "")) != "" or int(s.get("deep", 0)) > 0:
		print("  doctrine: %s; deep units (Deep Bore, White Heat Smelter): %d" % [String(s["doctrine"]), int(s["deep"])])


func _clock(s: float) -> String:
	var m: int = int(s) / 60
	return "%d:%02d:%02d" % [m / 60, m % 60, int(s) % 60]
