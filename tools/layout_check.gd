extends Node

## The real main screen, laid out on every screen shape it will meet, and
## checked rather than looked at:
##
##   godot --headless --path . tools/layout_check.tscn
##
## A scene rather than a --script run, because the main screen's scripts
## name the autoloads, and a SceneTree script cannot compile those.
##
## For each canvas (the phones' and tablets' aspect ratios, landscape, plus
## the portrait desktop windows the smoke test uses) it builds the game's
## main screen, lets it lay itself out, and fails if:
##
##   * two parts of the interface overlap
##   * any part leaves the safe area (tested with no inset and with a notch
##     and a gesture bar inset on every side)
##   * a key is smaller than the 48dp touch floor on the reference phone
##   * the Factory Core, framed by the default camera, is off screen or under
##     the interface
##   * Descend is not reachable
##   * on a landscape phone, a tile at the default zoom is under
##     MIN_TILE_DP -- a deep shaft's yard is framed on the Core, and the
##     tiles must stay big enough to aim at
##
## All of that on a shaft with the whole board open. Then again as a new game
## opens -- Core dark, the first yard (BuildArea) -- where it fails if:
##
##   * the yard is not fully on screen, or disappears under the interface
##   * the point on the Core the game asks the player to tap is under a panel
##     or off the screen
##
## It also prints the numbers the audit reports: the cell's size in dp at the
## default and the closest zoom, and how much of the screen the board takes.

## Screen shape, physical pixels, and the density a device of that shape
## typically has -- the dp numbers depend on all three.
const SIZES := [
	["16:9  1920x1080", Vector2i(1920, 1080), 420],
	# The one shape the 48dp floor is reported rather than enforced on: a
	# 720p 16:9 phone at xhdpi, where the canvas grows to 1440x810 and a unit
	# is 0.44 dp. Meeting 48dp there would take keys 108 units tall on every
	# phone; the keys measure 43-44 dp on it, which is Apple's 44pt floor.
	["16:9  1280x720", Vector2i(1280, 720), 320, false],
	["18:9  2160x1080", Vector2i(2160, 1080), 400],
	["19.5:9 2340x1080", Vector2i(2340, 1080), 420],
	["20:9  2400x1080", Vector2i(2400, 1080), 405],
	["21:9  2520x1080", Vector2i(2520, 1080), 420],
	["2:1   1440x720", Vector2i(1440, 720), 280],
	["16:10 2560x1600", Vector2i(2560, 1600), 300],
	["4:3   2048x1536", Vector2i(2048, 1536), 264],
	["port. 720x1440", Vector2i(720, 1440), 0],
	["port. 360x720", Vector2i(360, 720), 0],
]
const INSETS := [Vector4.ZERO, Vector4(96, 0, 48, 0), Vector4(0, 40, 0, 36)]
## The smallest a tile may be, in dp, at a deep shaft's default zoom on a
## landscape phone (IsoView.DEFAULT_ZOOM_MIN keeps it about 20).
const MIN_TILE_DP := 19.0

var _fail: Array[String] = []
var _warned: Dictionary = {}


## The tools read English whatever the machine speaks, unless
## LODEWORKS_LOCALE names a language: this runs before the game's own _ready
## picks the device's language.
func _init() -> void:
	if OS.get_environment("LODEWORKS_LOCALE") == "":
		OS.set_environment("LODEWORKS_LOCALE", "en")


func _ready() -> void:
	var tree: SceneTree = get_tree()
	await tree.process_frame
	var main: Control = get_parent().get_node("Main")
	await tree.process_frame
	main.call("_close_overlay")
	# A deep shaft: stratum 14, a 5-ring yard too big to frame whole.
	_set_state("board", main, 14)
	await tree.process_frame
	await tree.process_frame
	print("a deep shaft: stratum 14, yard %s" % str(BuildArea.size_at(14)))
	print("%-18s %-12s %9s %9s %8s %6s %s" % ["screen", "canvas", "cell dp", "max dp", "yard%",
		"hud%", "notes"])
	print("(cell dp = a cell's height at the default and the closest zoom; 0 = no density, desktop window)")
	for s: Array in SIZES:
		tree.root.size = s[1]
		for inset: Vector4 in INSETS:
			main.call("set_safe_insets", inset)
			for i in range(3):
				await tree.process_frame
			_check(main, String(s[0]), Vector2(s[1]), int(s[2]), inset,
				s.size() < 4 or bool(s[3]))
	print("")
	# A new game, then the first shaft two and four strata down: the yard
	# and the Core it grows beside, at three of the yard's sizes.
	for yd: int in [0, 1, 3]:
		_set_state("yard", main, yd)
		# The old tray's keys are freed at the end of a frame.
		await tree.process_frame
		await tree.process_frame
		print("first shaft, stratum %d: yard %s, Core level %d" % [yd,
			str(BuildArea.size_at(yd, 0)), IsoView.core_level()])
		print("%-18s %-12s %9s %8s %6s %s" % ["screen", "canvas", "cell dp", "yard%", "hud%",
			"notes"])
		for s: Array in SIZES:
			tree.root.size = s[1]
			for inset: Vector4 in INSETS:
				main.call("set_safe_insets", inset)
				for i in range(3):
					await tree.process_frame
				_check_yard(main, String(s[0]), Vector2(s[1]), int(s[2]), inset)
		print("")
	# Settings' "Larger text": the same deep shaft, every word a quarter
	# bigger, on every shape and safe area.
	var had: Variant = Sim.settings.get("large_text", false)
	Sim.settings["large_text"] = true
	main.call("_apply_settings")
	_set_state("board", main, 14)
	await tree.process_frame
	await tree.process_frame
	print("larger text: the deep shaft again")
	for s: Array in SIZES:
		tree.root.size = s[1]
		for inset: Vector4 in INSETS:
			main.call("set_safe_insets", inset)
			for i in range(3):
				await tree.process_frame
			_check(main, "large " + String(s[0]), Vector2(s[1]), int(s[2]), inset,
				s.size() < 4 or bool(s[3]))
	Sim.settings["large_text"] = had
	main.call("_apply_settings")
	print("")
	if _fail.is_empty():
		print("=== layout check passed: %d screens x %d safe areas ===" % [SIZES.size(), INSETS.size()])
		tree.quit(0)
	else:
		for f in _fail:
			print("FAIL  " + f)
		tree.quit(1)


func _check(main: Control, name: String, window: Vector2, dpi: int, inset: Vector4,
		strict: bool) -> void:
	var canvas: Vector2 = main.size
	var tag: String = "%s inset %s" % [name, str(inset)]
	var rects: Dictionary = main.call("hud_rects")
	var safe := Rect2(Vector2(inset.x, inset.y),
		canvas - Vector2(inset.x + inset.z, inset.y + inset.w))
	var keys: Array = rects.keys()
	for i in range(keys.size()):
		var a: Rect2 = rects[keys[i]]
		if not safe.grow(0.5).encloses(a):
			_fail.append("%s: %s %s leaves the safe area %s" % [tag, keys[i], str(a), str(safe)])
		for j in range(i + 1, keys.size()):
			var b: Rect2 = rects[keys[j]]
			if a.intersects(b):
				_fail.append("%s: %s overlaps %s" % [tag, keys[i], keys[j]])
	# Canvas units to dp on this device: its short side in pixels over the
	# canvas's short side in units, over its density.
	var dp_per_unit: float = 0.0
	if dpi > 0:
		dp_per_unit = (minf(window.x, window.y) / minf(canvas.x, canvas.y)) / (float(dpi) / 160.0)
	# Portrait canvases are the desktop smoke windows; the phone is landscape,
	# so the touch floor is checked on landscape canvases only.
	for b: Button in (main.call("hud_buttons") if dpi > 0 else []):
		if b == null or not b.is_visible_in_tree():
			continue
		var short: float = minf(b.size.x, b.size.y) * dp_per_unit
		if short < 47.5:
			var msg: String = "%s: a key is %.0f dp on its short side (%s)" % [tag, short, str(b.size)]
			if strict:
				_fail.append(msg)
			elif inset == Vector4.ZERO and not _warned.has(name):
				_warned[name] = true
				print("WARN  " + msg + " -- reported, not enforced (see SIZES)")
	# The deep shaft's default view: the Core, and as much yard as fits.
	var view: IsoView = main.get("iso_view")
	view.frame_board()
	var free: Rect2 = view.free_rect
	var core: Vector2 = view.cam.world_to_screen(view.core_center())
	if not free.grow(2.0).has_point(core):
		_fail.append("%s: the Core %s is outside the free area %s" % [tag, str(core), str(free)])
	for k: String in rects:
		if (rects[k] as Rect2).has_point(core):
			_fail.append("%s: the %s panel covers the Core" % [tag, k])
	var desc: Rect2 = rects["descend"]
	if desc.size.x < 60.0 or desc.size.y < 60.0:
		_fail.append("%s: Descend is too small to reach" % tag)
	if inset == Vector4.ZERO:
		var scale_px: float = window.y / canvas.y if canvas.x >= canvas.y else window.x / canvas.x
		var cell_dp: float = Iso.TH * view.cam.zoom * dp_per_unit
		var max_dp: float = Iso.TH * view.cam.zoom_max * dp_per_unit
		if canvas.x > canvas.y and dpi > 0 and strict and cell_dp < MIN_TILE_DP:
			_fail.append("%s: a tile is %.1f dp at the default zoom, under %.0f" % [tag,
				cell_dp, MIN_TILE_DP])
		var yard := PackedVector2Array()
		for p in view.yard_corners():
			yard.append(view.cam.world_to_screen(p))
		var shown: float = 0.0
		var screen := PackedVector2Array([Vector2.ZERO, Vector2(canvas.x, 0.0), canvas,
			Vector2(0.0, canvas.y)])
		for part in Geometry2D.intersect_polygons(yard, screen):
			shown += absf(_poly_area(part))
		# No shown text under the interface's floor (main.TEXT_MIN).
		var floor_units: int = int((main.get_script() as GDScript).get("TEXT_MIN"))
		var txt: Dictionary = _smallest_text(main, floor_units)
		for t: String in txt["under"]:
			_fail.append("%s: text under %d units: %s" % [tag, floor_units, t])
		print("%-18s %-12s %9.1f %9.1f %7.1f%% %5.1f%% %s" % [name,
			"%dx%d" % [int(canvas.x), int(canvas.y)], cell_dp, max_dp,
			100.0 * shown / (canvas.x * canvas.y), _hud_share(rects, canvas),
			"zoom %.2f, %.2f px/unit, smallest text %d units = %.1f dp ('%s')" % [view.cam.zoom,
				scale_px, int(txt["units"]), float(txt["units"]) * dp_per_unit, txt["words"]]])


## "board": a deep shaft, the Core long online, research and Cores in hand.
## "yard": a new game or an early stratum.
func _set_state(state: String, main: Control, depth: int = 0) -> void:
	Sim.grid.clear()
	Sim.depth = depth
	Sim.max_depth = depth
	Sim.research = 0.0
	Sim.cores = 0
	Sim.upgrade_levels = {}
	Sim.collapses = 1 if state == "board" else 0
	# Dark only in a new game: by the first descent it has long been online.
	Sim.core_online = state == "board" or depth > 0
	Sim._tutorial_step = Tutorial.count() if state == "board" else 0
	Sim.unlocked.clear()
	Sim._recompute()
	# The interface shows what the state has grown into (main._show_what_matters),
	# and the tray holds what that stratum has unlocked.
	main.call("_rebuild_palette")
	main.call("_refresh")


func _check_yard(main: Control, name: String, window: Vector2, dpi: int,
		inset: Vector4) -> void:
	var canvas: Vector2 = main.size
	var tag: String = "%s inset %s, new game" % [name, str(inset)]
	var rects: Dictionary = main.call("hud_rects")
	var view: IsoView = main.get("iso_view")
	view.frame_board()
	var free: Rect2 = view.free_rect
	var corners := PackedVector2Array()
	for p in view.yard_corners():
		var sp: Vector2 = view.cam.world_to_screen(p)
		corners.append(sp)
		if not free.grow(2.0).has_point(sp):
			_fail.append("%s: yard corner %s is outside the free area %s" % [tag, str(sp), str(free)])
	var cr: Rect2 = view.core_rect()
	var tap: Vector2 = view.cam.world_to_screen(cr.position + cr.size * Vector2(0.5, 0.58))
	var safe := Rect2(Vector2(inset.x, inset.y),
		canvas - Vector2(inset.x + inset.z, inset.y + inset.w))
	if not safe.has_point(tap):
		_fail.append("%s: the Core's tap point %s is off the screen" % [tag, str(tap)])
	for k: String in rects:
		var r: Rect2 = rects[k]
		var box := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		if not Geometry2D.intersect_polygons(corners, box).is_empty():
			_fail.append("%s: the %s panel covers part of the yard" % [tag, k])
		if r.grow(8.0).has_point(tap) and not Sim.core_online:
			_fail.append("%s: the %s panel covers the Core's tap point" % [tag, k])
		if view.board_under_panel():
			_fail.append("%s: a panel covers the yard or the Core" % tag)
			break
	if inset == Vector4.ZERO and OS.get_environment("LODEWORKS_LAYOUT_RECTS") == "1":
		for k: String in rects:
			print("    %-10s %s" % [k, str(rects[k])])
	if inset == Vector4.ZERO:
		var dp_per_unit: float = 0.0
		if dpi > 0:
			dp_per_unit = (minf(window.x, window.y) / minf(canvas.x, canvas.y)) \
				/ (float(dpi) / 160.0)
		print("%-18s %-12s %9.1f %7.1f%% %5.1f%% %s" % [name,
			"%dx%d" % [int(canvas.x), int(canvas.y)], Iso.TH * view.cam.zoom * dp_per_unit,
			100.0 * absf(_poly_area(corners)) / (canvas.x * canvas.y), _hud_share(rects, canvas),
			"zoom %.2f, Core tap at %s, %s" % [view.cam.zoom, str(tap.round()),
				_props_on_screen(view, rects, canvas)]])


## How many of the world's props stand on screen, clear of the panels, and
## how many of those are resource nodes: what a player actually sees round
## the yard, as against what layout.json holds.
## The smallest text on the interface: its size in canvas units, the words,
## and every text under `floor_units`. Labels and keys with words, shown and
## not inside an open panel.
func _smallest_text(main: Control, floor_units: int) -> Dictionary:
	var smallest: int = 999
	var words: String = ""
	var under: Array[String] = []
	for n: Node in main.find_children("*", "", true, false):
		if not (n is Label or n is Button) or not (n as Control).is_visible_in_tree():
			continue
		var text: String = String(n.get("text")).strip_edges()
		if text == "":
			continue
		var fs: int = (n as Control).get_theme_font_size("font_size")
		if fs < floor_units:
			under.append("%s %d" % [text.replace("\n", " ").left(24), fs])
		if fs < smallest:
			smallest = fs
			words = text.replace("\n", " ").left(24)
	return {"units": smallest, "words": words, "under": under}


func _props_on_screen(view: IsoView, rects: Dictionary, canvas: Vector2) -> String:
	var shown: int = 0
	var nodes: int = 0
	for pr: Array in IsoArt.placement().get("props", []):
		if view.call("_prop_cleared", pr):
			continue
		var sp: Vector2 = view.cam.world_to_screen(
			Iso.slab_top(float(pr[0]) + 0.5, float(pr[1]) + 0.5))
		if not Rect2(Vector2.ZERO, canvas).has_point(sp):
			continue
		var under: bool = false
		for k: String in rects:
			if (rects[k] as Rect2).has_point(sp):
				under = true
		if under:
			continue
		shown += 1
		if ResourceNodes.is_node(String(pr[2])):
			nodes += 1
	# And the board's cells whose middle is on screen and clear of the panels:
	# how many are the yard, the Core's foundation, and ground not reached.
	var open: int = 0
	var core: int = 0
	var locked: int = 0
	for cell in range(Grid.W * Grid.H):
		var cp: Vector2 = view.cam.world_to_screen(Iso.cell_center(cell))
		if not Rect2(Vector2.ZERO, canvas).has_point(cp):
			continue
		var hidden: bool = false
		for k: String in rects:
			if (rects[k] as Rect2).has_point(cp):
				hidden = true
		if hidden:
			continue
		if BuildArea.is_core(cell):
			core += 1
		elif Sim.is_open(cell):
			open += 1
		else:
			locked += 1
	return "props on screen %d (nodes %d), cells on screen %d yard / %d core / %d beyond" % [
		shown, nodes, open, core, locked]


## Percent of the screen the interface's panels cover. They never overlap
## (the check above fails if they do), so their areas add up.
func _hud_share(rects: Dictionary, canvas: Vector2) -> float:
	var a: float = 0.0
	var screen := Rect2(Vector2.ZERO, canvas)
	for k: String in rects:
		var r: Rect2 = (rects[k] as Rect2).intersection(screen)
		a += r.size.x * r.size.y
	return 100.0 * a / (canvas.x * canvas.y)


func _poly_area(p: PackedVector2Array) -> float:
	var a: float = 0.0
	for i in range(p.size()):
		var q: Vector2 = p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return a * 0.5
