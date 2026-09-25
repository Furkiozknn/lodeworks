extends Node

## What the main screen costs, measured on whatever machine runs this.
##
##   godot --path . --resolution 1440x720 tools/perf_probe.tscn
##   LODEWORKS_SOAK=600 godot ...      (soak seconds; default 180)
##
## It prints a markdown table and writes it to user://perf/perf.md. Every
## number is from this run on this machine. On a desktop GPU they say how the
## scene behaves, not how a phone will: the phone column stays UNKNOWN until
## the same probe (or the device self test) runs on one.
##
## Measured:
##   boot            engine start to the first rendered frame of the game
##   scene load      instantiating the main scene a second time, warm
##   art load        loading every picture the world draws, cold cache
##   sim tick        one Simulation.tick() on the reference board
##   frames          frame time p50/p95/p99 while idle, panning and zooming
##   draw calls      per frame, from the renderer's own counter
##   texture memory  from the renderer's own counter
##   palette switch  time until the first frame drawn with the new sheet
##   depth switch    descending, until the first frame after it
##   soak            static memory at the start and end of N seconds idle

const OUT := "user://perf"

var _main: Control
var _rows: Array = []
var _frames: PackedFloat32Array = PackedFloat32Array()
var _last_us: int = 0


## The tools read English whatever the machine speaks, unless
## LODEWORKS_LOCALE names a language: this runs before the game's own _ready
## picks the device's language.
func _init() -> void:
	if OS.get_environment("LODEWORKS_LOCALE") == "":
		OS.set_environment("LODEWORKS_LOCALE", "en")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_row("boot (engine start to first frame)", "%d ms" % Time.get_ticks_msec())
	_main = get_parent().get_node_or_null("Main")
	if _main == null:
		print("FAIL: no main scene")
		get_tree().quit(1)
		return
	# Measured uncapped, so frame times are the work and not the vsync wait.
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_main.call("_close_overlay")
	await _run()


func _row(what: String, value: String) -> void:
	_rows.append([what, value])
	print("  %-44s %s" % [what, value])


func _settle(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


## Frame-to-frame wall time for `seconds`, while `each` is called per frame.
func _sample(seconds: float, each: Callable = Callable()) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var t0: int = Time.get_ticks_usec()
	var prev: int = t0
	var dc_max: int = 0
	var dc_sum: int = 0
	var n: int = 0
	while float(Time.get_ticks_usec() - t0) < seconds * 1000000.0:
		if each.is_valid():
			each.call(float(Time.get_ticks_usec() - t0) / 1000000.0)
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		out.append(float(now - prev) / 1000.0)
		prev = now
		var dc: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		dc_max = maxi(dc_max, dc)
		dc_sum += dc
		n += 1
	_frames = out
	_last_draw = [dc_sum / maxi(n, 1), dc_max]
	return out


var _last_draw: Array = [0, 0]


func _pct(a: PackedFloat32Array, p: float) -> float:
	var s: Array = Array(a)
	s.sort()
	if s.is_empty():
		return 0.0
	return float(s[clampi(int(ceil(p * float(s.size()))) - 1, 0, s.size() - 1)])


func _frame_row(label: String, a: PackedFloat32Array) -> void:
	_row(label, "p50 %.2f ms, p95 %.2f ms, p99 %.2f ms (%d frames, %.0f fps median); draw calls avg %d, max %d"
		% [_pct(a, 0.5), _pct(a, 0.95), _pct(a, 0.99), a.size(), 1000.0 / maxf(_pct(a, 0.5), 0.001),
			int(_last_draw[0]), int(_last_draw[1])])


func _run() -> void:
	print("perf probe -- %s, %s, %dx%d" % [RenderingServer.get_video_adapter_name(),
		RenderingServer.get_current_rendering_method(), get_viewport().get_visible_rect().size.x,
		get_viewport().get_visible_rect().size.y])
	_rows.append(["machine", "%s / %s / %s" % [OS.get_name(), RenderingServer.get_video_adapter_name(),
		RenderingServer.get_current_rendering_method()]])

	# The reference board: the audit's hero board.
	var shots: Node = load("res://tools/screenshot.gd").new()
	shots.set("_main", _main)
	shots.call("_apply_build", "hero")
	shots.free()
	_main.call("_close_overlay")
	var view: Control = _main.get("iso_view")
	if view != null:
		view.call("frame_board")
	await _settle(2.0)

	# Scene load, warm: a second main scene, built and freed.
	var t: int = Time.get_ticks_usec()
	var packed: PackedScene = load("res://scenes/main.tscn")
	var second: Node = packed.instantiate()
	var inst_ms: float = float(Time.get_ticks_usec() - t) / 1000.0
	second.free()
	_row("scene load (instantiate main, warm)", "%.1f ms" % inst_ms)

	# Art load, cold: every picture, with Godot's cache emptied first.
	var files: Array[String] = []
	var L: Dictionary = IsoArt.layout()
	for k: String in ["world", "island", "tiles", "core", "props", "icons", "foreman"]:
		files.append(String(L[k]["file"]))
	var sheets: Dictionary = L["machines"]["sheets"]
	files.append(String(sheets["shaft"]["file"]))
	t = Time.get_ticks_usec()
	for f: String in files:
		ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_IGNORE)
	_row("art load (world + one machine sheet, uncached)", "%.1f ms for %d files" % [
		float(Time.get_ticks_usec() - t) / 1000.0, files.size()])

	# One simulation tick on the reference board.
	t = Time.get_ticks_usec()
	for i in range(500):
		Sim.sim.tick()
	_row("sim tick (reference board, %d machines)" % Sim.grid.cells.size(),
		"%.3f ms average over 500" % (float(Time.get_ticks_usec() - t) / 1000.0 / 500.0))

	await _settle(1.0)
	_frame_row("frames, idle (default view)", await _sample(5.0))
	_row("texture memory (renderer counter)", "%.1f MB" % (
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0))
	_row("video memory (renderer counter)", "%.1f MB" % (
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0))

	if view != null:
		var cam: IsoCamera = view.get("cam")
		var c0: Vector2 = cam.center
		_frame_row("frames, panning", await _sample(4.0, func(s: float):
			cam.drag(Vector2(sin(s * 2.0) * 14.0, cos(s * 1.3) * 9.0))))
		_frame_row("frames, zooming in and out", await _sample(4.0, func(s: float):
			cam.zoom_by(1.0 + 0.03 * sin(s * 3.0), cam.viewport * 0.5)))
		cam.focus(c0, view.call("default_zoom"))
		await _settle(1.0)

		# Palette switch: the first frame with a sheet not loaded before.
		var store: Node = get_tree().root.get_node("Store")
		store.call("debug_grant", MonetizationDB.THEMES)
		t = Time.get_ticks_usec()
		store.call("select_theme", "ember")
		await RenderingServer.frame_post_draw
		_row("palette switch (to an unloaded sheet, to drawn)", "%.1f ms" % (
			float(Time.get_ticks_usec() - t) / 1000.0))
		store.call("select_theme", Themes.DEFAULT)
		store.call("debug_revoke")
		await _settle(0.5)

	# Depth switch: descend, to the first frame after it.
	Sim.credits = maxf(Sim.credits, Sim.quota() + 1.0)
	t = Time.get_ticks_usec()
	Sim.descend()
	await RenderingServer.frame_post_draw
	_row("depth switch (descend, to drawn)", "%.1f ms" % (float(Time.get_ticks_usec() - t) / 1000.0))
	# Descending unlocks a machine, and the unlock card is an overlay; the
	# soak is of the board, so it is closed once it has come up.
	await _settle(1.0)
	_main.call("_close_overlay")
	await _settle(1.0)

	var soak: float = float(OS.get_environment("LODEWORKS_SOAK")) if OS.get_environment("LODEWORKS_SOAK") != "" else 180.0
	var m0: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var n0: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var soak_frames := await _sample(soak)
	var m1: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var n1: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_frame_row("frames, %.0f s soak" % soak, soak_frames)
	_row("memory over the soak (static)", "%.1f MB -> %.1f MB (%+.1f MB), nodes %d -> %d" % [
		m0, m1, m1 - m0, n0, n1])

	var md: Array[String] = ["| measure | value |", "|---|---|"]
	for r: Array in _rows:
		md.append("| %s | %s |" % [r[0], r[1]])
	var f := FileAccess.open(OUT + "/perf.md", FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	f.close()
	print("wrote %s" % ProjectSettings.globalize_path(OUT + "/perf.md"))
	get_tree().quit(0)
