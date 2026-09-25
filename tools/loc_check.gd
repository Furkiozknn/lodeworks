extends Node

## Opens every screen of the game in one language and checks its words.
##
##   LODEWORKS_LOCALE=tr     godot --path . --resolution 1440x720 tools/loc_check.tscn
##   LODEWORKS_LOCALE=pseudo godot --path . --resolution 1440x720 tools/loc_check.tscn
##
## For every screen -- the board, each Settings tab, the language list,
## Research, Collapse (locked and ready), the Factory Core, what lies below,
## the stratum, the Codex's every tab, the shop, a resource node, a new
## machine, removing one, the machine sheet and its words, the welcome back
## panel, a toast and the Foreman -- it looks at every word on screen:
##   * pseudo: a word without the pseudo-language's bracket did not come
##     through Loc: it is written into the code, and no translation reaches it;
##   * tr: a word that is still the English of a message Turkish translates
##     was not translated where it is shown;
##   * both: a word wider than the key it sits on, or off the screen.
## It writes a picture of each screen to user://loc/<language>/ and exits
## non-zero on the first run with a failure.

const OUT := "user://loc"

var _main: Control
var _lang: String = ""
var _fails: Array[String] = []
var _english: Dictionary = {}
var _checked: int = 0


func _ready() -> void:
	_lang = OS.get_environment("LODEWORKS_LOCALE")
	if _lang == "":
		_lang = "tr"
	DirAccess.make_dir_recursive_absolute("%s/%s" % [OUT, _lang])
	await get_tree().process_frame
	_main = get_parent().get_node_or_null("Main")
	if _main == null:
		print("FAIL: main scene did not load")
		get_tree().quit(1)
		return
	# The English of every message this language translates differently.
	if _lang != Loc.PSEUDO:
		for e: Dictionary in (load("res://tools/loc_catalog.gd") as GDScript).call("collect"):
			var id: String = String(e["id"])
			if Loc.t(id) != id:
				_english[id] = true
	await _run()


func _settle(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


func _run() -> void:
	# LODEWORKS_LARGE=1: the same screens with Settings' "Larger text" on.
	var large: bool = OS.get_environment("LODEWORKS_LARGE") == "1"
	Sim.settings["large_text"] = large
	_main.call("_apply_settings")
	print("loc check: %s%s" % [_lang, ", larger text" if large else ""])
	# A new game: the Foreman's first line, the tray, Descend.
	await _settle(1.2)
	await _screen("01_board")
	Sim.power_core()
	_main.call("_refresh")
	_main.call("_refresh_hint")
	await _settle(0.4)
	await _screen("02_board_online")
	_main.call("_toast_msg", Loc.t("Pick a machine below, then tap a tile."))
	await _settle(0.2)
	await _screen("03_toast")

	for tab: String in ["game", "audio", "graphics", "controls", "access"]:
		_main.set("_settings_tab", tab)
		_main.call("_show_settings")
		await _settle(0.4)
		await _screen("10_settings_" + tab)
	_main.call("_show_languages")
	await _settle(0.4)
	await _screen("11_languages")
	_main.call("_close_overlay")

	_main.call("_show_research")
	await _settle(0.5)
	await _screen("20_research")
	_main.call("_show_collapse")
	await _settle(0.4)
	await _screen("21_collapse_locked")
	var keep: Array = [Sim.max_depth, Sim.lifetime_credits]
	Sim.max_depth = Economy.COLLAPSE_MIN_DEPTH
	Sim.lifetime_credits = 5.0e6
	_main.call("_show_collapse")
	await _settle(0.4)
	await _screen("22_collapse_ready")
	Sim.max_depth = int(keep[0])
	Sim.lifetime_credits = float(keep[1])
	_main.call("_show_core")
	await _settle(0.4)
	await _screen("23_core")
	_main.call("_show_below")
	await _settle(0.4)
	await _screen("24_below")
	_main.call("_show_stratum_info")
	await _settle(0.4)
	await _screen("25_stratum")
	_main.call("_on_unlocked", ["smelter", "boiler"])
	await _settle(0.5)
	await _screen("26_new_machines")
	_main.call("_show_offline", {"amount": 1234.0, "research": 56.0, "seconds_away": 7300.0,
		"seconds_counted": 7300.0, "rate": 0.45, "capped": true})
	await _settle(0.4)
	await _screen("27_welcome_back")
	_main.call("_close_overlay")

	# A machine on the board: its sheet, its words, and removing it.
	var cell: int = -1
	for c: int in BuildArea.cells(Sim.max_depth):
		if Sim.grid.is_empty(c) and not Sim.is_blocked(c):
			cell = c
			break
	Sim.credits = maxf(Sim.credits, 1000.0)
	if cell >= 0 and Sim.try_place(cell, "drill"):
		_main.call("_refresh")
		_main.call("_show_cell_info", cell)
		await _settle(0.4)
		await _screen("30_machine_sheet")
		_main.call("_info", Loc.t("Drill"), String(_main.get("_sheet_help")))
		await _settle(0.4)
		await _screen("31_machine_words")
		# Where its heat comes from, and what would change it.
		_main.call("_close_overlay")
		_main.call("_show_heat", cell)
		await _settle(0.4)
		await _screen("33_heat")
		_main.call("_on_cell_long_pressed", cell)
		await _settle(0.4)
		await _screen("32_remove")
		_main.call("_close_overlay")
		_main.call("_close_sheet")

	# The Core's level 7: Overdrive on a machine's sheet, the Core card that
	# asks for it at level 8, and the one at level 6 that asks for level 7.
	var kept: Array = [Sim.core_level, Sim.machine_levels.duplicate(), Sim.max_depth, Sim.credits]
	Sim.core_level = MachineDB.OVERDRIVE_CORE
	Sim.machine_levels["assembler"] = CoreLevels.overdrive_from(MachineDB.OVERDRIVE_CORE)
	Sim.max_depth = maxi(Sim.max_depth, MachineDB.unlock_depth("assembler"))
	Sim.credits = maxf(Sim.credits, 1.0e6)
	Sim._recompute()
	var at: int = -1
	for c: int in BuildArea.cells(Sim.max_depth):
		if Sim.grid.is_empty(c) and not Sim.is_blocked(c):
			at = c
			break
	if at >= 0 and Sim.try_place(at, "assembler"):
		_main.call("_refresh")
		_main.call("_show_cell_info", at)
		await _settle(0.4)
		await _screen("35_overdrive")
		_main.call("_close_sheet")
		Sim.sell(at)
	_main.call("_show_core")
	await _settle(0.4)
	await _screen("36_core_7")
	_main.call("_close_overlay")
	Sim.core_level = MachineDB.OVERDRIVE_CORE - 1
	Sim._recompute()
	_main.call("_show_core")
	await _settle(0.4)
	await _screen("37_core_6")
	_main.call("_close_overlay")
	Sim.core_level = int(kept[0])
	Sim.machine_levels = kept[1]
	Sim.max_depth = int(kept[2])
	Sim.credits = float(kept[3])
	Sim._recompute()

	# What now?: as many kinds of line as one board gives.
	var was: Array = [Sim.research, Sim.max_depth, Sim.lifetime_credits]
	Sim.research = 1.0e6
	Sim.max_depth = Economy.COLLAPSE_MIN_DEPTH
	Sim.lifetime_credits = 5.0e6
	_main.call("_show_worklist")
	await _settle(0.4)
	await _screen("34_what_now")
	_main.call("_close_overlay")
	Sim.research = float(was[0])
	Sim.max_depth = int(was[1])
	Sim.lifetime_credits = float(was[2])

	# A resource node round the yard.
	var props: Array = IsoArt.placement().get("props", [])
	var view: Control = _main.get("iso_view")
	for i in range(props.size()):
		if ResourceNodes.is_node(String(props[i][2])) and not view.call("_prop_cleared", props[i]):
			_main.call("_on_node_tapped", i)
			await _settle(0.4)
			await _screen("33_resource_node")
			_main.call("_close_node_card")
			break

	# The Codex, every tab.
	_main.call("_open_codex")
	await _settle(1.2)
	var codex: Node = null
	for c in _main.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("codex.gd"):
			codex = c
	if codex != null:
		for tab in range(MachineDB.GROUPS.size()):
			codex.call("show_tab", tab)
			await _settle(0.5)
			await _screen("40_codex_%d" % tab)
		codex.call("show_tab", -1)
		await _settle(0.8)
		await _screen("41_codex_rules")
		codex.queue_free()
		await _settle(0.2)

	# The shop.
	_main.call("_open_shop")
	await _settle(0.6)
	await _screen("50_shop")
	for c in _main.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("shop.gd"):
			c.queue_free()
	await _settle(0.2)

	print("  %d words checked on screen" % _checked)
	if _fails.is_empty():
		print("=== loc check passed: %s ===" % _lang)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL  " + f)
		print("=== loc check FAILED: %s, %d problems ===" % [_lang, _fails.size()])
		get_tree().quit(1)


## Every word on screen now, checked, and a picture of it.
func _screen(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("%s/%s/%s.png" % [OUT, _lang, name])
	var screen := Rect2(Vector2.ZERO, _main.size)
	for n: Node in _main.find_children("*", "", true, false):
		if not (n is Label or n is Button) or not (n as Control).is_visible_in_tree():
			continue
		var c := n as Control
		var text: String = String(c.get("text")).strip_edges()
		if text == "" or not RegEx.create_from_string("[A-Za-zÀ-ÿĞğİıŞşÇçÖöÜü]{2,}").search(text):
			continue
		_checked += 1
		var at: String = "%s: '%s'" % [name, text.replace("\n", " ").left(48)]
		if _lang == Loc.PSEUDO and not text.contains("[") and not _allowed(text):
			_fails.append(at + " did not come through Loc")
		if _english.has(text):
			_fails.append(at + " is still English")
		var r: Rect2 = c.get_global_rect()
		# In a scrolling panel a word may be below the fold; it must still
		# fit across the screen.
		var fits: bool = screen.grow(2.0).encloses(r) if not _scrolls(c) \
			else (r.position.x >= -2.0 and r.end.x <= screen.end.x + 2.0)
		if c is Label and not fits:
			_fails.append("%s runs off the screen (%s)" % [at, str(r)])
		# A word on a key must fit the key.
		var key: Control = _key_of(c)
		if key != null and c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
			var need: float = (c as Label).get_minimum_size().x
			if need > key.size.x + 2.0:
				_fails.append("%s is %.0f wide on a %.0f key" % [at, need, key.size.x])


## The key a word is written on, if it is on one.
func _key_of(c: Control) -> Control:
	var p: Node = c.get_parent()
	while p != null and p != _main:
		if p is Button:
			return p as Control
		p = p.get_parent()
	return null


func _scrolls(c: Control) -> bool:
	var p: Node = c.get_parent()
	while p != null and p != _main:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


## Words that are not translated on purpose: the game's name and version.
## And each language's own name, which is written in that language.
func _allowed(text: String) -> bool:
	if text.begins_with("Lodeworks "):
		return true
	for l: Dictionary in Loc.LANGUAGES:
		if String(l["name"]) == text:
			return true
	return false
