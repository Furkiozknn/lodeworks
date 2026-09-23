extends Node

## Drives the game and writes every store asset from it.
##
##   xvfb-run -a godot --path . --resolution 1080x1920 \
##       --rendering-driver opengl3 tools/shots.tscn
##
## Every image in the listing is produced by this, from the running game, at
## the resolution Google asks for. No mock-ups and no composited marketing art:
## if a screenshot shows a board, that board was simulated, and the boards used
## here are the ones the test suite verifies. A store listing that shows
## something the app does not do is both a rejection risk under Play's
## deceptive-behaviour rules and the setup for the one-star review that
## follows.
##
## It also captures a frame sequence for the preview video, because Play wants
## core gameplay inside the first ten seconds and the honest way to get that is
## to record the game playing rather than to edit something that looks better
## than it is.

const OUT_DIR := "user://shots"
const REEL_DIR := "user://reel"

## Landscape phone screenshots have to be at least 1920x1080 to count towards
## the three Play wants before a game is eligible for its recommendation
## surfaces, and must be 24-bit with no alpha channel.
const SHOTS := [
	{"name": "01_line", "build": "full", "wait": 2.5,
		"alt": "A full production line on the seven by ten grid, machines feeding their neighbours."},
	{"name": "02_heat", "build": "heat", "wait": 2.0, "overlay": true,
		"alt": "The heat overlay, showing how far each machine is from the temperature it wants."},
	{"name": "03_bottleneck", "build": "broken", "wait": 3.0,
		"alt": "Two machines flagged as starved and backed up, with a count above the board."},
	{"name": "04_place", "build": "heat", "wait": 1.5, "press": [4, 4], "arm": "boiler",
		"alt": "Placing a boiler, previewing the heat it will add to each neighbour."},
	{"name": "05_detail", "build": "full", "wait": 2.0, "select": [2, 2],
		"alt": "The detail sheet for a smelter, naming what is wrong and which way to look."},
	{"name": "06_research", "build": "full", "wait": 1.0, "panel": "research",
		"alt": "The permanent research tree, bought with Cores."},
	{"name": "07_offline", "build": "full", "wait": 1.0, "panel": "offline",
		"alt": "The welcome back panel, showing the three numbers the offline payout was made from."},
	{"name": "08_first_line", "build": "starter", "wait": 2.0,
		"alt": "The first three machines, with the tutorial line above the board."},
]

## The preview video. Each beat runs for its seconds while frames are captured.
## Core gameplay has to be on screen inside the first ten seconds, so the reel
## opens on a working board rather than on a title.
const REEL_FPS := 20
const REEL := [
	{"build": "full", "seconds": 3.0},
	{"build": "full", "seconds": 2.0, "overlay": true},
	{"build": "heat", "seconds": 3.0, "grow": true},
	{"build": "broken", "seconds": 2.5},
	{"build": "full", "seconds": 2.5, "select": [2, 4]},
]

var _main: Control
var _reel_frame: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(REEL_DIR)
	await get_tree().process_frame
	_main = get_parent().get_node_or_null("Main")
	if _main == null:
		push_error("Main scene not found -- run with the game's main scene loaded")
		get_tree().quit(1)
		return
	# A silent capture. The reel gets its audio, if it ever gets any, from
	# something that is not a headless render.
	Juice.set_sound(false)
	_run()


func _run() -> void:
	if OS.get_environment("LODEWORKS_CAPTURE") == "audit":
		await _run_audit()
		get_tree().quit()
		return
	for s: Dictionary in SHOTS:
		_apply_build(String(s["build"]))
		_set_overlay(bool(s.get("overlay", false)))
		await _settle(float(s["wait"]))
		if s.has("select"):
			var sc: Array = s["select"]
			_select(Grid.idx(int(sc[0]), int(sc[1])))
			await _settle(0.5)
		if s.has("press"):
			var pc: Array = s["press"]
			_press(Grid.idx(int(pc[0]), int(pc[1])), String(s.get("arm", "")))
			await _settle(0.4)
		if s.has("panel"):
			_open_panel(String(s["panel"]))
			await _settle(0.6)
		await _capture(String(s["name"]))
		_clear_transient()
		await _settle(0.2)

	# The tablet pass reuses this scene at a different resolution and does not
	# need a second copy of the video.
	if OS.get_environment("LODEWORKS_SHOTS_ONLY") == "":
		await _record_reel()
	_write_alt_text()
	print("wrote %d screenshots and %d reel frames"
		% [SHOTS.size(), _reel_frame])
	get_tree().quit()


func _settle(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


func _clear_transient() -> void:
	if _main.has_method("_close_overlay"):
		_main.call("_close_overlay")
	if _main.has_method("_close_sheet"):
		_main.call("_close_sheet")
	var gv: IsoView = _main.get("iso_view")
	if gv != null:
		gv.arm_id = ""
		gv.selected_cell = -1
		gv.set("_press_cell", -1)
		gv.set("_pressed", false)
		gv.set_overlay(IsoView.Overlay.NONE)


func _set_overlay(on: bool) -> void:
	var gv: IsoView = _main.get("iso_view")
	if gv != null:
		gv.set_overlay(IsoView.Overlay.HEAT if on else IsoView.Overlay.NONE)


func _select(cell: int) -> void:
	var gv: IsoView = _main.get("iso_view")
	if gv == null:
		return
	gv.selected_cell = cell
	if _main.has_method("_show_cell_info"):
		_main.call("_show_cell_info", cell)


## Freeze the board in the middle of a placement, which is where the game
## explains both of its rules at once.
func _press(cell: int, arm: String) -> void:
	var gv: IsoView = _main.get("iso_view")
	if gv == null:
		return
	gv.arm_id = arm
	gv.set("_press_cell", cell)
	gv.set("_pressed", true)


## Boards used for the shots. Hand-built, because a screenshot should show a
## board a competent player would actually have rather than a random one.
func _apply_build(kind: String) -> void:
	Sim.grid.clear()
	Sim.sim.reset_progress()
	# Every field reset, every time.
	#
	# The shots run in one process, and leaving research, Cores and upgrade
	# levels behind from the previous build produced a "first three machines"
	# screenshot showing 823 Research, 14 Cores and 527 credits a second. That
	# is a store listing claiming something the app does not do at that point,
	# which is both a Play policy problem and a lie to whoever installs it.
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.lifetime_credits = 0.0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.tutorial_moves = 0
	Sim.tutorial_saw_heat = false
	match kind:
		"starter":
			Sim.depth = 0
			Sim.max_depth = 0
			Sim.credits = 240.0
			_place([
				[2, 4, "drill"], [3, 4, "crusher"], [4, 4, "vault"],
				[2, 5, "drill"], [3, 5, "crusher"], [4, 5, "vault"],
			])
		"heat":
			Sim.depth = 3
			Sim.max_depth = 3
			Sim.credits = 4200.0
			_place([
				[1, 3, "drill"], [2, 3, "crusher"], [3, 3, "smelter"],
				[3, 2, "boiler"], [4, 3, "press"], [4, 2, "coolant"],
				[5, 3, "vault"], [1, 4, "drill"], [2, 4, "crusher"],
			])
		"broken":
			# Deliberately wrong, because "the board tells you which machine is
			# the problem" is the thing worth showing and it cannot be shown on
			# a board where nothing is wrong. The assembler has no plate
			# supply, so it starves; the line behind it backs up.
			Sim.depth = 5
			Sim.max_depth = 5
			Sim.credits = 26000.0
			_place([
				[1, 3, "drill"], [2, 3, "crusher"], [3, 3, "smelter"],
				[4, 3, "press"], [5, 3, "assembler"],
				[1, 4, "drill"], [2, 4, "crusher"], [3, 4, "smelter"],
				[5, 4, "lab"],
			])
		"hero":
			# The board the audit screenshots show, chosen by measurement
			# (a scratch run compared four candidate boards at depths 5-8):
			# a mid-game factory at the Workings, 397.9 credits a second at
			# stratum 7, the Dense Seam. Every chain is complete, so the one
			# jammed drill and the press row running hot are the only badges
			# on screen -- the heat language, without noise.
			Sim.depth = 7
			Sim.max_depth = 7
			Sim.cores = 6
			Sim.research = 340.0
			Sim.credits = 41000.0
			Sim.upgrade_levels = {"throughput_1": 1, "yield_1": 1}
			_place([
				[1, 0, "drill"], [2, 0, "drill"], [3, 0, "drill"], [4, 0, "drill"], [5, 0, "drill"],
				[1, 1, "crusher"], [2, 1, "crusher"], [3, 1, "amplifier"], [4, 1, "crusher"],
				[5, 1, "crusher"],
				[0, 2, "vault"], [1, 2, "smelter"], [2, 2, "smelter"], [3, 2, "vault"],
				[4, 2, "smelter"], [5, 2, "smelter"], [6, 2, "vault"],
				[0, 3, "vault"], [1, 3, "press"], [2, 3, "press"], [3, 3, "coolant"],
				[4, 3, "press"], [5, 3, "press"], [6, 3, "vault"],
				[1, 4, "vault"], [2, 4, "assembler"], [3, 4, "assembler"], [4, 4, "assembler"],
				[5, 4, "vault"],
				[2, 5, "vault"], [3, 5, "lab"], [4, 5, "vault"],
				[1, 7, "drill"], [2, 7, "crusher"], [3, 7, "smelter"], [4, 7, "vault"],
			])
		"full":
			Sim.depth = 9
			Sim.max_depth = 9
			Sim.cores = 14
			Sim.research = 820.0
			Sim.credits = 186000.0
			Sim.upgrade_levels = {"throughput_1": 3, "yield_1": 2, "value_1": 2,
				"research_1": 1, "heat_tolerance": 1}
			# Exactly the layout tests/test_progression.gd verifies end to end,
			# so the screenshot cannot show a board that does not work.
			_place([
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
			])
	Sim.unlocked.clear()
	# The tutorial banner belongs on a first-run board, not on a deep one.
	Sim._tutorial_step = 0 if kind == "starter" else 9
	Sim._recompute()
	# Warm the board properly so the header shows the rate a player would see
	# and every status pip reflects a settled board, not a cold-start artefact.
	var m: Dictionary = Sim.sim.measure(15.0, 20.0)
	Sim.credits_per_sec = float(m["credits_per_sec"])
	Sim.research_per_sec = float(m["research_per_sec"])
	Sim.stats_changed.emit()
	if _main.has_method("_rebuild_palette"):
		_main.call("_rebuild_palette")
	_main.call("_refresh")
	if _main.has_method("_refresh_hint"):
		_main.call("_refresh_hint")


func _place(list: Array) -> void:
	for e: Array in list:
		Sim.grid.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))


func _open_panel(which: String) -> void:
	match which:
		"research":
			_main.call("_show_research")
		"offline":
			_main.call("_show_offline", {
				"amount": Sim.credits_per_sec * 3600.0 * 4.0 * 0.45,
				"seconds_away": 3600.0 * 7.5,
				"seconds_counted": 3600.0 * 4.0,
				"rate": 0.45,
				"capped": true,
			})


## --- the preview video -----------------------------------------------------

func _record_reel() -> void:
	for beat: Dictionary in REEL:
		_apply_build(String(beat["build"]))
		_set_overlay(bool(beat.get("overlay", false)))
		if beat.has("select"):
			var sc: Array = beat["select"]
			_select(Grid.idx(int(sc[0]), int(sc[1])))
		var frames: int = int(float(beat["seconds"]) * REEL_FPS)
		var grow: bool = bool(beat.get("grow", false))
		var queue: Array = [
			[5, 2, "boiler"], [6, 3, "vault"], [2, 2, "crusher"],
			[0, 3, "drill"], [4, 4, "press"], [5, 4, "vault"],
		]
		for f in range(frames):
			# Placing machines on camera: the one thing a still cannot show is
			# that the numbers move when the board changes.
			if grow and f % 10 == 0 and not queue.is_empty():
				var e: Array = queue.pop_front()
				Sim.grid.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
				Sim._recompute()
			await _reel_capture()
		_clear_transient()


func _reel_capture() -> void:
	# One simulated tick per captured frame keeps the recording moving at a
	# believable rate rather than at whatever the render loop manages.
	Sim.sim.tick()
	Sim.stats_changed.emit()
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/f%04d.png" % [REEL_DIR, _reel_frame])
	_reel_frame += 1


## --- capture ---------------------------------------------------------------

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	# Play requires 24-bit PNG with no alpha channel for screenshots and the
	# feature graphic. Godot's viewport image is RGBA8; saving it as-is
	# produces a 32-bit file that does not meet the spec.
	img.convert(Image.FORMAT_RGB8)
	var path: String = "%s/%s.png" % [OUT_DIR, name]
	var err: int = img.save_png(path)
	if err != OK:
		push_error("could not write %s (%d)" % [path, err])
	else:
		print("  %s  %dx%d" % [ProjectSettings.globalize_path(path),
			img.get_width(), img.get_height()])


## Alt text, up to 140 characters each, written next to the images so whoever
## uploads them does not have to invent it at the console.
func _write_alt_text() -> void:
	var lines: Array[String] = []
	for s: Dictionary in SHOTS:
		var alt: String = String(s.get("alt", ""))
		if alt.length() > 140:
			alt = alt.substr(0, 137) + "..."
		lines.append("%s.png\t%s" % [String(s["name"]), alt])
	var f := FileAccess.open(OUT_DIR + "/alt-text.tsv", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()


## --- the visual audit ------------------------------------------------------

const AUDIT_DIR := "user://audit"


func _run_audit() -> void:
	DirAccess.make_dir_recursive_absolute(AUDIT_DIR)
	var gv: IsoView = _main.get("iso_view")
	_apply_build("hero")
	# A save from an earlier run brings up the offline panel; the audit is
	# about the board, so it is closed rather than photographed.
	_main.call("_close_overlay")
	gv.frame_board()
	# Long enough for the badges' 1.5 s hysteresis and a settled heat field.
	await _settle(3.2)
	await _audit_shot("01_main_landscape")

	var c: Vector2 = Iso.board_rect().get_center()
	gv.cam.focus(c, 1.3)
	await _settle(1.6)
	await _audit_shot("02_zoomed")

	gv.cam.focus(gv.cam.anchor, 0.0001)
	await _settle(1.6)
	await _audit_shot("03_full_world")

	var target: int = Grid.idx(2, 3)
	gv.selected_cell = target
	_main.call("_show_cell_info", target)
	gv.cam.focus(Iso.cell_center(target) - Vector2(0, 40), gv.cam.zoom_max)
	await _settle(1.8)
	await _audit_shot("04_machine_closeup")
	print("wrote the audit screens to %s" % ProjectSettings.globalize_path(AUDIT_DIR))


func _audit_shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/%s.png" % [AUDIT_DIR, name])
	print("  %s  %dx%d" % [name, img.get_width(), img.get_height()])
