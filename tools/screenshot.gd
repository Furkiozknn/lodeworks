extends Node

## Drives the game and writes real screenshots.
##
##   xvfb-run -a godot --path . --resolution 720x1440 \
##       --script-args ... res://tools/screenshot.gd
##
## Every image in the store listing is produced by this, from the running game,
## at the real device resolution. No mock-ups, no composited marketing art: if
## a screenshot shows a board, that board was simulated. Store listings that
## show something the app does not do get rejected, and more importantly they
## set up the one-star review that follows.

const OUT_DIR := "user://shots"
const SHOTS := [
	{"name": "01_first_line", "build": "starter", "wait": 2.0},
	{"name": "02_heat", "build": "heat", "wait": 2.5},
	{"name": "03_full_board", "build": "full", "wait": 3.0},
	{"name": "04_research", "build": "full", "wait": 1.0, "panel": "research"},
	{"name": "05_offline", "build": "full", "wait": 1.0, "panel": "offline"},
]

var _main: Control
var _shot: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await get_tree().process_frame
	_main = get_parent().get_node_or_null("Main")
	if _main == null:
		push_error("Main scene not found -- run with the game's main scene loaded")
		get_tree().quit(1)
		return
	_run()


func _run() -> void:
	for s: Dictionary in SHOTS:
		_apply_build(String(s["build"]))
		await _settle(float(s["wait"]))
		if s.has("panel"):
			_open_panel(String(s["panel"]))
			await _settle(0.6)
		await _capture(String(s["name"]))
		if s.has("panel"):
			_main.call("_close_overlay")
			await _settle(0.3)
	print("wrote %d screenshots to %s" % [SHOTS.size(), ProjectSettings.globalize_path(OUT_DIR)])
	get_tree().quit()


func _settle(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


## Boards used for the shots. These are hand-built because a screenshot should
## show a board a competent player would actually have, not a random one.
func _apply_build(kind: String) -> void:
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 0.0
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
				[0, 2, "drill"], [1, 2, "crusher"], [2, 2, "smelter"], [3, 2, "boiler"],
				[4, 2, "smelter"], [5, 2, "crusher"], [6, 2, "drill"],
				[0, 3, "drill"], [1, 3, "crusher"], [2, 3, "press"], [3, 3, "coolant"],
				[4, 3, "press"], [5, 3, "crusher"], [6, 3, "drill"],
				[0, 4, "drill"], [1, 4, "crusher"], [2, 4, "assembler"],
				[3, 4, "amplifier"], [4, 4, "assembler"], [5, 4, "crusher"],
				[6, 4, "drill"],
				[0, 5, "vault"], [1, 5, "vault"], [2, 5, "lab"], [3, 5, "amplifier"],
				[4, 5, "lab"], [5, 5, "vault"], [6, 5, "vault"],
			])
	Sim.unlocked.clear()
	# The tutorial banner belongs on a first-run board, not on a deep one.
	Sim._tutorial_step = 0 if kind == "starter" else 9
	Sim._recompute()
	# Warm the board properly so the header shows the rate a player would see,
	# not a cold-start artefact.
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


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "%s/%s.png" % [OUT_DIR, name]
	var err: int = img.save_png(path)
	if err != OK:
		push_error("could not write %s (%d)" % [path, err])
	else:
		print("  ", ProjectSettings.globalize_path(path))
