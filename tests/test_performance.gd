extends RefCounted

## Performance budgets that can be checked without a phone.
##
## The numbers a mobile game is judged on — frame time, battery, thermal
## behaviour — cannot be measured on a build server, and this file does not
## pretend otherwise; the device self test measures those on hardware and
## reports UNKNOWN everywhere else.
##
## What CAN be checked here is everything that is a property of the project
## rather than of the device: how long a tick takes, how long a save takes,
## how much the game allocates while it runs, and — the structural ones that
## matter most for this project — that it still ships no bitmaps, no audio
## files, and no board layout with half its tiles dead.
##
## A budget with no test behind it is a sentence in a document. These are the
## ones that will actually stop a regression.

var runner: Object

## One tick per 100 ms of game time. Three milliseconds is a generous share of
## that for a mid-range phone, and the container measures roughly a sixth of
## it, so the headroom is real rather than aspirational.
const TICK_BUDGET_MS := 3.0
## Android gives an app a short and unspecified moment after onPause to write
## anything it wants to keep. Twenty milliseconds is far under any plausible
## allowance.
const SAVE_BUDGET_MS := 20.0
## Synthesised audio is held in memory as raw 16-bit samples. Two megabytes is
## a whole soundscape at 22 kHz and still less than a single compressed music
## track would cost.
const AUDIO_BUDGET_KB := 2048

const BENCH := [
	[0, 0, "drill"], [1, 0, "drill"], [2, 0, "drill"], [3, 0, "drill"],
	[4, 0, "drill"], [5, 0, "drill"], [6, 0, "drill"],
	[0, 1, "crusher"], [1, 1, "crusher"], [2, 1, "crusher"], [3, 1, "crusher"],
	[4, 1, "crusher"], [5, 1, "crusher"], [6, 1, "crusher"],
	[0, 2, "vault"], [1, 2, "smelter"], [2, 2, "smelter"], [3, 2, "smelter"],
	[4, 2, "smelter"], [5, 2, "smelter"], [6, 2, "vault"],
	[0, 3, "vault"], [1, 3, "press"], [2, 3, "press"], [3, 3, "press"],
	[4, 3, "press"], [5, 3, "press"], [6, 3, "vault"],
	[0, 4, "vault"], [1, 4, "vault"], [2, 4, "assembler"], [3, 4, "assembler"],
	[4, 4, "assembler"], [5, 4, "vault"], [6, 4, "vault"],
	[1, 5, "vault"], [2, 5, "vault"], [3, 5, "lab"], [4, 5, "vault"],
	[5, 5, "vault"],
	[0, 6, "drill"], [1, 6, "drill"], [2, 6, "drill"], [3, 6, "drill"],
	[4, 6, "drill"], [5, 6, "drill"], [6, 6, "drill"],
	[0, 7, "crusher"], [1, 7, "crusher"], [2, 7, "crusher"], [3, 7, "crusher"],
	[4, 7, "crusher"], [5, 7, "crusher"], [6, 7, "crusher"],
	[0, 8, "vault"], [1, 8, "vault"], [2, 8, "vault"], [3, 8, "vault"],
	[4, 8, "vault"], [5, 8, "vault"], [6, 8, "vault"],
]


func _full_board() -> Simulation:
	var g := Grid.new()
	for e: Array in BENCH:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	return Simulation.new(g, 20260923)


## --- the cost of running the game ------------------------------------------

func test_a_tick_fits_its_budget() -> void:
	var s: Simulation = _full_board()
	s.run_ticks(40)
	var t0: int = Time.get_ticks_usec()
	s.run_ticks(600)
	var ms: float = float(Time.get_ticks_usec() - t0) / 600000.0
	runner.lt(ms, TICK_BUDGET_MS,
		"a tick on a full board must fit inside its share of a frame")


## Status tracking was added for the board to draw. It is per-tile work on
## every tick, so it has to be nearly free or it is not worth having.
func test_status_tracking_is_cheap() -> void:
	var s: Simulation = _full_board()
	s.run_ticks(600)
	var counted: int = 0
	var t0: int = Time.get_ticks_usec()
	for _i in range(200):
		var c: Dictionary = s.problem_counts()
		counted += int(c["starved"]) + int(c["blocked"])
	var us: float = float(Time.get_ticks_usec() - t0) / 200.0
	runner.lt(us, 400.0,
		"reading the board's problem counts must stay well under a millisecond")
	runner.gte(float(counted), 0.0, "")


func test_running_the_game_does_not_grow_the_object_count() -> void:
	# A steady leak in the tick is the one performance bug an idle game cannot
	# survive: the app is left running for hours.
	var s: Simulation = _full_board()
	s.run_ticks(300)
	var before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	s.run_ticks(3000)
	var after: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	runner.lt(float(after - before), 200.0,
		"three thousand ticks must not leave objects behind")


func test_a_save_is_quick_enough_for_a_pause() -> void:
	Save.wipe()
	Sim._ensure()
	var t0: int = Time.get_ticks_usec()
	for _i in range(10):
		Save.save_game(Sim)
	var ms: float = float(Time.get_ticks_usec() - t0) / 10000.0
	runner.lt(ms, SAVE_BUDGET_MS,
		"the save happens when Android says the app is about to be killed")


## --- what the build actually contains --------------------------------------

func _scan(dir: String, exts: Array, found: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var path: String = dir.path_join(name)
		if d.current_is_dir():
			if not name.begins_with("."):
				_scan(path, exts, found)
		else:
			for e: String in exts:
				if name.to_lower().ends_with(e):
					found.append(path)
		name = d.get_next()
	d.list_dir_end()


## The claim in every design note in this project is that it ships no art and
## no audio. That claim is load-bearing — it is why the build is small, why
## there is no licence to check, and why a new machine costs a table row. So
## it is a test, not a sentence.
## The one file on the allowed list is Godot's own project icon, which the
## editor requires and which never reaches a phone screen.
## The art budget. Measured by tools/asset_budget.py too; this is the gate.
const ART_BUDGET_MB := 40.0

## Pictures ship only from assets/art (built by tools/art_build.py, each with
## a recorded source) plus the one SVG icon. Sound is still synthesised: no
## audio file ships at all.
func test_media_ships_only_from_the_art_folder_and_within_budget() -> void:
	var found: Array = []
	for folder: String in ["res://scripts", "res://scenes", "res://assets"]:
		_scan(folder, [".png", ".jpg", ".jpeg", ".webp", ".svg", ".ogg",
			".wav", ".mp3", ".ttf", ".otf"], found)
	var unexpected: Array = []
	var bytes: int = 0
	for f: String in found:
		if f.get_extension() in ["ogg", "wav", "mp3"]:
			unexpected.append(f)
		elif not (f.begins_with("res://assets/art/") or f == "res://assets/icons/icon.svg"):
			unexpected.append(f)
		if f.begins_with("res://assets/art/"):
			var fa := FileAccess.open(f, FileAccess.READ)
			if fa != null:
				bytes += fa.get_length()
	runner.eq(unexpected.size(), 0,
		"unexpected media in the shipped tree: " + ", ".join(unexpected))
	runner.lt(float(bytes) / 1048576.0, ART_BUDGET_MB,
		"assets/art is %.1f MB against a %.0f MB budget" % [float(bytes) / 1048576.0,
			ART_BUDGET_MB])


## The launcher icons are generated by tools/brand.gd into store/brand/, and
## the Android presets take them from there.
func test_the_launcher_icons_exist_and_are_generated() -> void:
	var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	for p: String in ["res://store/brand/icon-512.png", "res://store/brand/icon-192.png",
			"res://store/brand/icon-foreground-432.png"]:
		runner.check(FileAccess.file_exists(p), "missing launcher icon " + p)
	for p: String in ["res://store/brand/icon-192.png", "res://store/brand/icon-foreground-432.png"]:
		runner.check(presets.contains('"%s"' % p), "the Android presets do not use " + p)


func test_every_sound_was_generated_and_fits_its_budget() -> void:
	var names: Array = Juice.sfx_names()
	runner.gte(float(names.size()), 14.0,
		"a sound that failed to generate leaves a game that is simply quiet")
	var kb: int = Juice.total_samples() * 2 / 1024
	runner.lt(float(kb), float(AUDIO_BUDGET_KB),
		"synthesised audio must stay small enough to be worth not shipping files")


## --- the board the game shows off ------------------------------------------

func test_the_reference_layout_is_not_half_dead() -> void:
	# This test exists because the previous reference layout was not.
	#
	# It passed every functional test — it produced credits and it produced
	# research — while thirteen of its twenty-eight machines sat permanently
	# output-blocked at zero per cent duty cycle. Nothing was watching the
	# question "is this board any good", so nothing noticed. Now something is.
	var s: Simulation = _full_board()
	var st: Dictionary = Strata.describe(9)
	s.grid.set_environment(float(st["ambient_heat"]), float(st["heat_spread"]))
	s.run_ticks(600)
	var dead: int = 0
	var total: int = 0
	for i: int in s.grid.cells:
		if s.status_of(i) == Simulation.Status.PASSIVE:
			continue
		total += 1
		if s.uptime_of(i) < 0.05:
			dead += 1
	runner.gt(float(total), 10.0, "the reference board has machines on it")
	runner.lt(float(dead) / float(total), 0.34,
		"at most a third of the reference board may be doing nothing "
		+ "(%d of %d are)" % [dead, total])
