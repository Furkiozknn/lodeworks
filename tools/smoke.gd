extends Node

## Boots the real game, opens the diagnostics screen, and captures it.
##
##   xvfb-run -a godot --path . --resolution 720x1440 \
##       --rendering-driver opengl3 tools/smoke.tscn
##
## The unit tests never build a Control, so a UI that fails to instantiate
## passes all 97 of them. This is the check that the screens actually come up:
## it drives the same buttons a player would, screenshots what it finds, and
## exits non-zero on the first error. It is also the only automated proof that
## the self-test screen -- the thing the whole device-verification plan rests
## on -- can be opened at all.

const OUT_DIR := "user://smoke"

var _main: Control
var _failures: Array[String] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await get_tree().process_frame
	_main = get_parent().get_node_or_null("Main")
	if _main == null:
		print("FAIL: main scene did not load")
		get_tree().quit(1)
		return
	await _run()


func _settle(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "%s/%s.png" % [OUT_DIR, name]
	if img.save_png(path) != OK:
		_failures.append("could not write " + path)
		return
	# A screen that rendered nothing is a black rectangle, and a black
	# rectangle saves perfectly happily. Look at the pixels.
	var lit: int = 0
	for y in range(0, img.get_height(), 17):
		for x in range(0, img.get_width(), 13):
			if img.get_pixel(x, y).get_luminance() > 0.06:
				lit += 1
	if lit < 40:
		_failures.append("%s rendered almost nothing (%d lit samples)" % [name, lit])
	print("  %s  %dx%d  %d lit samples" % [name, img.get_width(), img.get_height(), lit])


func _run() -> void:
	print("smoke test")
	await _settle(1.5)
	await _shot("01_board")

	# The settings panel, which is where the self test lives.
	_main.call("_show_settings")
	await _settle(0.6)
	await _shot("02_settings")
	_main.call("_close_overlay")
	await _settle(0.3)

	# The diagnostics screen itself: instantiated, run, and rendered.
	_main.call("_open_diagnostics")
	await _settle(2.0)
	var diag: Node = null
	for c in _main.get_children():
		if c.has_method("report_text"):
			diag = c
			break
	if diag == null:
		_failures.append("the diagnostics screen did not instantiate")
	else:
		await _shot("03_selftest")
		var report: String = diag.call("report_text")
		if report.length() < 100:
			_failures.append("the diagnostics report came back empty")
		else:
			print("")
			print(report)
		diag.queue_free()
	await _settle(0.4)

	print("")
	if _failures.is_empty():
		print("=== smoke test passed, %s ===" % ProjectSettings.globalize_path(OUT_DIR))
		get_tree().quit(0)
	else:
		for f in _failures:
			print("FAIL  " + f)
		get_tree().quit(1)
