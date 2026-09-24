extends Node

## Boots the real game, opens the diagnostics screen, and captures it.
##
##   xvfb-run -a godot --path . --resolution 1440x720 \
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
	# Every switch in Settings does what it says: flipped, the thing it
	# names changes; flipped back, it is as it was.
	var checks: Array = [
		["graphics", "Machine effects", func() -> bool: return bool(_main.get("iso_view").get("effects"))],
		["graphics", "Battery saver", func() -> bool: return Engine.max_fps == 30],
		["access", "Zoom key", func() -> bool: return bool((_main.get("_btn_zoom") as Control).visible)],
		["access", "Reduce motion", func() -> bool: return bool(_main.get("iso_view").get("calm_motion"))],
		["audio", "Ambience", func() -> bool: return bool(Juice.ambient_enabled)],
		["controls", "Vibration", func() -> bool: return bool(Juice.haptics_enabled)],
	]
	for c: Array in checks:
		_main.set("_settings_tab", String(c[0]))
		_main.call("_fill_settings_page")
		await _settle(0.1)
		var row: Button = null
		for n: Node in _main.find_children("*", "Button", true, false):
			if n.has_meta("setting") and String(n.get_meta("setting")) == String(c[1]) 					and not n.is_queued_for_deletion():
				row = n as Button
		if row == null:
			_failures.append("settings has no '%s' switch" % c[1])
			continue
		var before: bool = (c[2] as Callable).call()
		row.button_pressed = not row.button_pressed
		var after: bool = (c[2] as Callable).call()
		row.button_pressed = not row.button_pressed
		var back: bool = (c[2] as Callable).call()
		if after == before or back != before:
			_failures.append("the '%s' switch does not change what it names" % c[1])
	print("  settings: %d switches checked" % checks.size())
	_main.call("_close_overlay")
	await _settle(0.3)

	# Research: a grid of picture cards, three to a row on a landscape
	# phone, one per line of the tree, each showing the state the Sim says it
	# is in -- a card that looked buyable and was not would be a lie.
	_main.call("_show_research")
	await _settle(0.6)
	await _shot("08_research")
	var grids: Array[Node] = _main.find_children("*", "GridContainer", true, false)
	var cards: GridContainer = null
	for g: Node in grids:
		if g.is_visible_in_tree() and g.get_child_count() > 0 				and (g.get_child(0) as Node).has_meta("research_id"):
			cards = g as GridContainer
	if cards == null:
		_failures.append("the research panel has no card grid")
	else:
		if cards.get_child_count() != Economy.TREE_ORDER.size():
			_failures.append("research shows %d cards for %d lines"
				% [cards.get_child_count(), Economy.TREE_ORDER.size()])
		if _main.size.x >= 1400.0 and cards.columns != 3:
			_failures.append("research is %d columns on a landscape phone, not 3" % cards.columns)
		for card: Node in cards.get_children():
			var id: String = String(card.get_meta("research_id"))
			var st: String = String(card.get_meta("state"))
			var want: String = "max" if Sim.upgrade_level(id) >= int(Economy.RESEARCH_TREE[id]["max"]) 				else ("ready" if Sim.can_buy_upgrade(id) else "")
			if want != "" and st != want:
				_failures.append("research card %s shows %s, the Sim says %s" % [id, st, want])
			if want == "" and st in ["max", "ready"]:
				_failures.append("research card %s shows %s but cannot be bought" % [id, st])
		print("  research: %d cards, %d columns" % [cards.get_child_count(), cards.columns])
	_main.call("_close_overlay")
	await _settle(0.3)

	# Collapse: a card whose state is the Sim's -- locked before the stratum
	# it opens at, and a Collapse key that works only when there is
	# something to collapse for.
	_main.call("_show_collapse")
	await _settle(0.6)
	await _shot("09_collapse")
	var want_c: String = "locked" if not Economy.can_collapse(Sim.max_depth) 		else ("ready" if Sim.can_collapse() else "empty")
	var got_c: String = ""
	for n: Node in _main.find_children("*", "VBoxContainer", true, false):
		if n.has_meta("state") and (n as Control).is_visible_in_tree():
			got_c = String(n.get_meta("state"))
	if got_c != want_c:
		_failures.append("the collapse card shows '%s', the Sim says '%s'" % [got_c, want_c])
	print("  collapse: %s" % got_c)
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
		# A key per group and one for the rules; every machine on its
		# group's page, once; every page the player has reached on the rules.
		var keys: int = 0
		for n: Node in codex.find_children("*", "Button", true, false):
			if n.has_meta("tab"):
				keys += 1
		if keys != MachineDB.GROUPS.size() + 1:
			_failures.append("the codex has %d tab keys for %d groups" % [keys, MachineDB.GROUPS.size()])
		var codex_cards: int = 0
		for g in range(MachineDB.GROUPS.size()):
			codex.call("show_tab", g)
			await _settle(0.1)
			for n: Node in codex.find_children("*", "PanelContainer", true, false):
				if n.has_meta("machine_id") and not n.is_queued_for_deletion():
					codex_cards += 1
					if MachineDB.group_of(String(n.get_meta("machine_id"))) != g:
						_failures.append("%s is on the wrong codex page" % n.get_meta("machine_id"))
		if codex_cards != MachineDB.ORDER.size():
			_failures.append("the codex shows %d machine cards for %d machines" % [codex_cards, MachineDB.ORDER.size()])
		codex.call("show_tab", -1)
		await _settle(0.3)
		await _shot("04_codex_rules")
		var pages: int = 0
		for n: Node in codex.find_children("*", "PanelContainer", true, false):
			if n.has_meta("page_id") and not n.is_queued_for_deletion():
				pages += 1
		var want_pages: int = int((load("res://scripts/ui/codex.gd") as GDScript).call("unlocked_count"))
		if pages != want_pages:
			_failures.append("the codex shows %d rule pages, the player has reached %d" % [pages, want_pages])
		print("  codex: %d keys, %d machine cards, %d rule pages" % [keys, codex_cards, pages])
		codex.queue_free()
	await _settle(0.4)

	# The unlock moment: a machine four times board size, running, with the
	# Foreman cheering. It is the one screen whose whole job is to make
	# somebody want to go and place the thing, so it gets a shot.
	_main.call("_on_unlocked", ["assembler"])
	await _settle(0.9)
	await _shot("07_unlock")
	_main.call("_close_overlay")
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
