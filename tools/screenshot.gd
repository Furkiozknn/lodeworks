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
		"alt": "A factory wrapped round its Core on the 44 x 44 board, machines feeding their neighbours."},
	{"name": "02_heat", "build": "heat", "wait": 2.0, "overlay": true,
		"alt": "The heat overlay, showing how far each machine is from the temperature it wants."},
	{"name": "03_bottleneck", "build": "broken", "wait": 3.0,
		"alt": "Two machines flagged as starved and backed up, with a count above the board."},
	{"name": "04_place", "build": "heat", "wait": 1.5, "press": [23, 18], "arm": "boiler",
		"alt": "Placing a boiler, previewing the heat it will add to each neighbour."},
	{"name": "05_detail", "build": "full", "wait": 2.0, "select": [21, 19],
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
	{"build": "full", "seconds": 2.5, "select": [21, 19]},
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
	if OS.get_environment("LODEWORKS_CAPTURE") == "first":
		await _run_first()
		get_tree().quit()
		return
	if OS.get_environment("LODEWORKS_CAPTURE") == "ui":
		await _run_ui()
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
		"new":
			# A fresh install: nothing on the board and nothing in the purse.
			Sim.depth = 0
			Sim.max_depth = 0
		"starter":
			Sim.depth = 0
			Sim.max_depth = 0
			Sim.credits = 240.0
			# Two short lines along the ring behind the Core.
			var y: int = BuildArea.CORE.position.y - 1
			var x0: int = BuildArea.CORE.position.x - 1
			_place([
				[x0, y, "drill"], [x0 + 1, y, "crusher"], [x0 + 2, y, "vault"],
				[x0 + 3, y, "drill"], [x0 + 4, y, "crusher"], [x0 + 5, y, "vault"],
			])
		"heat":
			Sim.depth = 3
			Sim.max_depth = 3
			Sim.credits = 4200.0
			_place_shifted([
				[1, 3, "drill"], [2, 3, "crusher"], [3, 3, "smelter"],
				[3, 2, "boiler"], [4, 3, "press"], [4, 2, "coolant"],
				[5, 3, "vault"], [1, 4, "drill"], [2, 4, "crusher"],
			], 2)
		"broken":
			# Deliberately wrong, because "the board tells you which machine is
			# the problem" is the thing worth showing and it cannot be shown on
			# a board where nothing is wrong. The assembler has no plate
			# supply, so it starves; the line behind it backs up.
			Sim.depth = 5
			Sim.max_depth = 5
			Sim.credits = 26000.0
			_place_shifted([
				[1, 3, "drill"], [2, 3, "crusher"], [3, 3, "smelter"],
				[4, 3, "press"], [5, 3, "assembler"],
				[1, 4, "drill"], [2, 4, "crusher"], [3, 4, "smelter"],
				[5, 4, "lab"],
			], 3)
		"hero":
			# The board the audit screenshots and the performance probe show: a
			# mid-game factory at the Workings wrapped round the front of its
			# Core -- spokes of Drill, Crusher and Vault, every third one a
			# Smelter selling through the Vaults beside it -- at stratum 7,
			# the Dense Seam.
			Sim.depth = 7
			Sim.max_depth = 7
			Sim.cores = 6
			Sim.research = 340.0
			Sim.credits = 41000.0
			Sim.upgrade_levels = {"throughput_1": 1, "yield_1": 1}
			_ring(["front", "right"])
		"full":
			# Every tile of the stratum-9 yard: the whole ring round the Core.
			Sim.depth = 9
			Sim.max_depth = 9
			Sim.cores = 14
			Sim.research = 820.0
			Sim.credits = 186000.0
			Sim.upgrade_levels = {"throughput_1": 3, "yield_1": 2, "value_1": 2,
				"research_1": 1, "heat_tolerance": 1}
			_ring(["back", "front", "left", "right"])
	Sim.unlocked.clear()
	# A new game's Core is still dark; every other board has long been running.
	Sim.set("core_online", kind != "new")
	# The tutorial banner belongs on a first-run board, not on a deep one.
	Sim._tutorial_step = 0 if kind == "starter" or kind == "new" else Tutorial.count()
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


## A layout from the 7 x 10 board, moved into the three rows of yard behind
## the Core (row `top` of the old layout lands on the ring's outer row).
func _place_shifted(list: Array, top: int) -> void:
	var c: Rect2i = BuildArea.CORE
	var shift := Vector2i(c.position.x - 3 - 0, c.position.y - 3 - top)
	for e: Array in list:
		Sim.grid.place(Grid.idx(int(e[0]) + shift.x, int(e[1]) + shift.y), String(e[2]))


## A factory in the three-tile ring round the Core, on the given sides. Rows
## run along the ring, outer to inner, so no machine waits and none is
## stuck: a Crusher under every other outer Drill, fed by it and by the
## Drills beside it in the middle row; Vaults over those middle Drills and
## all along the inner row -- every fourth place a Smelter instead, selling
## ingots through the Vaults either side of it.
func _ring(sides: Array) -> void:
	var c: Rect2i = BuildArea.CORE
	for side: String in sides:
		var along: int = 10 if side == "back" or side == "front" else 4
		for i in range(along):
			var kinds: Array = ["vault", "drill", "vault"]
			if i % 2 == 0:
				kinds = ["drill", "crusher", "smelter" if i % 4 == 0 else "vault"]
			for k in range(3):
				var p: Vector2i
				match side:
					"back":
						p = Vector2i(c.position.x - 3 + i, c.position.y - 3 + k)
					"front":
						p = Vector2i(c.position.x - 3 + i, c.end.y + 2 - k)
					"left":
						p = Vector2i(c.position.x - 3 + k, c.position.y + i)
					"right":
						p = Vector2i(c.end.x + 2 - k, c.position.y + i)
				Sim.grid.place(Grid.idx(p.x, p.y), String(kinds[k]))


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
		# The heat build's neighbours in the ring behind the Core.
		var queue: Array = [
			[22, 17, "boiler"], [23, 18, "vault"], [19, 17, "crusher"],
			[17, 18, "drill"], [22, 19, "press"], [23, 19, "vault"],
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

	# A Smelter in the ring in front of the Core.
	var target: int = Grid.idx(BuildArea.CORE.position.x + 1, BuildArea.CORE.end.y)
	gv.selected_cell = target
	_main.call("_show_cell_info", target)
	gv.cam.focus(Iso.cell_center(target) - Vector2(0, 40), gv.cam.zoom_max)
	await _settle(1.8)
	await _audit_shot("04_machine_closeup")
	print("wrote the audit screens to %s" % ProjectSettings.globalize_path(AUDIT_DIR))


## The first minute of a new game, as a fresh install opens it, into the same
## folder as the audit screens:
##   first_01_open   the shaft as it opens
##   first_02_core   after the first thing the game asks for
##   first_03_income a Drill and a Vault bought where the tutorial points,
##                   with whatever the game has given the player, ten
##                   seconds on -- an empty board here means a new player
##                   cannot start
##   first_04/05     the first descent: the yard growing, and after
func _run_first() -> void:
	DirAccess.make_dir_recursive_absolute(AUDIT_DIR)
	var gv: IsoView = _main.get("iso_view")
	_apply_build("new")
	_main.call("_close_overlay")
	_main.call("_refresh_hint")
	gv.frame_board()
	await _settle(2.5)
	await _audit_shot("first_01_open")
	if _main.has_method("_on_core_tapped"):
		_main.call("_on_core_tapped")
	await _settle(1.5)
	await _audit_shot("first_02_core")
	# Where the tutorial's arrow points, as a new player would follow it.
	var spots: Array[int] = [int(_main.call("pointer_cell"))]
	if spots[0] >= 0 and Sim.try_place(spots[0], "drill"):
		for n: int in Sim.grid.neighbours(spots[0]):
			if Sim.grid.is_empty(n) and not Sim.is_blocked(n) and Sim.try_place(n, "vault"):
				break
	_main.call("_refresh")
	_main.call("_maybe_advance_tutorial")
	_main.call("_refresh_hint")
	await _settle(10.0)
	await _audit_shot("first_03_income")
	print("credits %.0f, machines %d" % [Sim.credits, Sim.grid.cells.size()])
	# The first descent, straight away: the yard grows and the view follows.
	Sim.credits = maxf(Sim.credits, Sim.quota())
	_main.call("_on_descend")
	await _settle(1.0)
	# The descent's "new machine" card, read and closed; then the ground grows.
	_main.call("_close_overlay")
	await _settle(0.5)
	await _audit_shot("first_04_yard_grows")
	await _settle(2.5)
	await _audit_shot("first_05_bigger_yard")


## The panels, one shot each, into the audit folder. Each is opened on a
## board whose numbers put every state of the panel on screen at once.
##   ui_research  a line finished, lines to buy, lines short of research and
##                lines that need Cores first
##   ui_collapse, ui_collapse_locked  the trade, and the locked card
##   ui_codex_makers, ui_codex_boosters, ui_codex_rules  the Codex
##   ui_settings_*   Settings, one shot per group
##   ui_band_banner  a new band's name as a descent reaches it
func _run_ui() -> void:
	DirAccess.make_dir_recursive_absolute(AUDIT_DIR)
	_apply_build("hero")
	_main.call("_close_overlay")
	Sim.upgrade_levels = {"throughput_1": 8, "yield_1": 3, "value_1": 1}
	Sim.research = 400.0
	Sim.cores = 2
	await _settle(1.0)
	_main.call("_show_research")
	await _settle(0.8)
	await _audit_shot("ui_research")
	_main.call("_close_overlay")
	# Collapse, open (the hero board is at stratum 7) and still locked.
	_main.call("_show_collapse")
	await _settle(0.6)
	await _audit_shot("ui_collapse")
	_main.call("_close_overlay")
	var keep_depth: int = Sim.max_depth
	Sim.max_depth = 1
	_main.call("_show_collapse")
	await _settle(0.6)
	await _audit_shot("ui_collapse_locked")
	_main.call("_close_overlay")
	Sim.max_depth = keep_depth
	# The Codex: the Makers, the Boosters (one open, one still locked at
	# stratum 7), and the rules.
	_main.call("_open_codex")
	await _settle(0.8)
	var cx: Node = null
	for c in _main.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("codex.gd"):
			cx = c
	if cx != null:
		for t: Array in [[MachineDB.Group.MAKE, "ui_codex_makers"],
				[MachineDB.Group.BOOST, "ui_codex_boosters"], [-1, "ui_codex_rules"]]:
			cx.call("show_tab", int(t[0]))
			await _settle(0.8)
			await _audit_shot(String(t[1]))
		cx.queue_free()
		await _settle(0.2)
	# Settings, one shot per group.
	_main.call("_show_settings")
	await _settle(0.6)
	for tab: String in ["game", "audio", "graphics", "controls", "access"]:
		_main.set("_settings_tab", tab)
		_main.call("_fill_settings_page")
		await _settle(0.3)
		await _audit_shot("ui_settings_" + tab)
	_main.call("_close_overlay")
	await _settle(0.2)
	# A new band's name across the world, as a descent into the Workings
	# shows it.
	_main.call("_band_banner", 1)
	await _settle(0.9)
	await _audit_shot("ui_band_banner")
	await _settle(2.4)
	print("wrote the panel screens to %s" % ProjectSettings.globalize_path(AUDIT_DIR))


func _audit_shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/%s.png" % [AUDIT_DIR, name])
	print("  %s  %dx%d" % [name, img.get_width(), img.get_height()])
