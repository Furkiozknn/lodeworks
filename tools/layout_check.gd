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
##   * the board, framed by the default camera, is not fully on screen, or
##     disappears under the interface
##   * Descend is not reachable
##   * on a landscape screen, the board takes less than MIN_BOARD_SHARE of it
##     at the default zoom, with no inset
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
## Percent of a landscape screen the board's diamond must take at the default
## zoom. It was 10-14% before the default view was tightened and is 18.5-25%
## now (docs/AUDIT.md, "The default view"); this keeps it from sliding back.
const MIN_BOARD_SHARE := 18.0

var _fail: Array[String] = []
var _warned: Dictionary = {}


func _ready() -> void:
	var tree: SceneTree = get_tree()
	await tree.process_frame
	var main: Control = get_parent().get_node("Main")
	await tree.process_frame
	main.call("_close_overlay")
	print("%-18s %-12s %9s %9s %8s %s" % ["screen", "canvas", "cell dp", "max dp", "board%", "notes"])
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
	# The board, as the default camera frames it.
	var view: IsoView = main.get("iso_view")
	view.frame_board()
	var free: Rect2 = view.free_rect
	var corners: PackedVector2Array = PackedVector2Array()
	for p in Iso.board_corners():
		var sp: Vector2 = view.cam.world_to_screen(p)
		corners.append(sp)
		if not free.grow(2.0).has_point(sp):
			_fail.append("%s: board corner %s is outside the free area %s" % [tag, str(sp), str(free)])
	for k: String in rects:
		var r: Rect2 = rects[k]
		var box := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		if not Geometry2D.intersect_polygons(corners, box).is_empty():
			_fail.append("%s: the %s panel covers part of the board" % [tag, k])
	var desc: Rect2 = rects["descend"]
	if desc.size.x < 60.0 or desc.size.y < 60.0:
		_fail.append("%s: Descend is too small to reach" % tag)
	if inset == Vector4.ZERO:
		var area: float = absf(_poly_area(corners))
		var scale_px: float = window.y / canvas.y if canvas.x >= canvas.y else window.x / canvas.x
		var cell_dp: float = Iso.TH * view.cam.zoom * dp_per_unit
		var max_dp: float = Iso.TH * view.cam.zoom_max * dp_per_unit
		var share: float = 100.0 * area / (canvas.x * canvas.y)
		if canvas.x > canvas.y and share < MIN_BOARD_SHARE:
			_fail.append("%s: the board is %.1f%% of the screen, under %.0f%%" % [tag, share,
				MIN_BOARD_SHARE])
		print("%-18s %-12s %9.1f %9.1f %7.1f%% %s" % [name, "%dx%d" % [int(canvas.x), int(canvas.y)],
			cell_dp, max_dp, share,
			"zoom %.2f, %.2f px/unit" % [view.cam.zoom, scale_px]])


func _poly_area(p: PackedVector2Array) -> float:
	var a: float = 0.0
	for i in range(p.size()):
		var q: Vector2 = p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return a * 0.5
