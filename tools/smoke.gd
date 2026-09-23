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
var _board_lit: int = 0


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
	# A full-screen panel that renders as an invisible rectangle produces a
	# capture identical to the board behind it, and a check that only counts
	# lit pixels passes it happily. The diagnostics screen did exactly that
	# for two releases. So every screen after the first has to look different
	# from the board.
	if name == "01_board":
		_board_lit = lit
	elif _board_lit > 0 and lit == _board_lit:
		_failures.append(("%s is pixel-for-pixel as lit as the bare board, "
			+ "so it is almost certainly not being drawn") % name)
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

	# The Codex. Every page on it runs a real simulation, so a page that
	# fails to build is a page that renders as an empty box -- which is
	# exactly what the lit-sample check below catches.
	_main.call("_open_codex")
	await _settle(1.6)
	var codex: Node = null
	for c in _main.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("codex.gd"):
			codex = c
			break
	if codex == null:
		_failures.append("the codex did not instantiate")
	else:
		await _shot("04_codex")
		codex.queue_free()
	await _settle(0.4)

	# The placement preview for a support machine is verified by
	# `tests/test_grid.gd` rather than by a screenshot: it only exists while a
	# finger is down, and a shot of transient input state is a flaky test
	# rather than a useful one. What matters is that the number drawn under
	# the finger is the number the machine gets, and one function produces
	# both.

	# The shop. Every card draws a real illustration -- the offline bars and
	# a strip of machine tiles per palette -- so a card that fails to build
	# renders as an empty box, which the lit-sample check below catches. This
	# screen is also the one place a bug is somebody's money, so it gets
	# opened twice: once unowned, once owned, because "already bought" is a
	# completely different set of branches.
	var store0: Node = get_tree().root.get_node_or_null("Store")
	if store0 != null:
		# A previous run's entitlement file would otherwise make the "unowned"
		# pass draw the owned screen, which is how a broken buy button hides.
		store0.call("debug_revoke")
	for owned: bool in [false, true]:
		var store: Node = get_tree().root.get_node_or_null("Store")
		if owned and store != null:
			store.call("debug_grant", MonetizationDB.LICENCE)
			store.call("debug_grant", MonetizationDB.THEMES)
			store.call("select_theme", "ember")
		_main.call("_open_shop")
		await _settle(1.2)
		var shop: Node = null
		for c in _main.get_children():
			if c.get_script() != null and String(c.get_script().resource_path).ends_with("shop.gd"):
				shop = c
				break
		if shop == null:
			_failures.append("the shop did not instantiate (owned=%s)" % str(owned))
		else:
			await _shot("05_shop_owned" if owned else "05_shop")
			shop.queue_free()
		await _settle(0.4)
	var store_after: Node = get_tree().root.get_node_or_null("Store")
	if store_after != null:
		store_after.call("debug_revoke")
	await _settle(0.4)

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
