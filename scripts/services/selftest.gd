class_name SelfTest
extends RefCounted

## The on-device self test.
##
## Everything the project cannot check from a build server: what the CPU here
## actually does with the simulation, what this screen's shape does to the
## layout, whether the save survives this filesystem, and whether the ad and
## billing plugins bound to anything real. It runs from the game's settings
## screen in one tap and prints a report that can be copied out.
##
## The point of this file is that a real-device claim needs a real device. Run
## headless -- which is how CI runs it -- the checks that need hardware return
## UNKNOWN rather than a plausible number, and the report says so. A number
## that was never measured is worse than no number, because it stops anyone
## going and measuring it.
##
## Each check returns:
##   id      stable key
##   label   what it says on the screen
##   status  "pass" | "fail" | "unknown" | "info"
##   detail  one line of text

const PASS := "pass"
const FAIL := "fail"
const UNKNOWN := "unknown"
const INFO := "info"

## A dense board, used as the CPU benchmark. Same shape as the layout the
## balance tests use, so the number here is comparable to the CI baseline.
const BENCH_BOARD := [
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
]

## Ticks to time. At 10 Hz this is a simulated minute, long enough that the
## measurement is not noise and short enough to sit through on a phone.
const BENCH_TICKS := 600

## The simulation gets one tick per 100 ms. Anything above this per tick and a
## slow phone cannot keep up with its own factory.
const BENCH_BUDGET_MS := 3.0

## Portrait aspect ratios Play devices actually ship. 18:9 through 21:9 is the
## normal band; below 16:9 is a tablet, above 21:9 is a folded foldable.
const ASPECT_MIN := 1.30
const ASPECT_MAX := 2.40


static func run_all(state: Object = null) -> Array:
	var out: Array = []
	out.append(device_info())
	out.append(renderer_info())
	out.append(screen_check())
	out.append(safe_area_check())
	out.append(scaling_check())
	out.append(orientation_check())
	out.append(touch_target_check())
	out.append(draw_budget())
	out.append(shader_stall_check())
	out.append(cpu_benchmark())
	out.append(memory_check())
	out.append(storage_check())
	out.append(save_round_trip(state))
	out.append(save_cost())
	out.append(long_idle_check())
	out.append(persistence_check(state))
	out.append(preview_truth())
	out.append(rate_freshness(state))
	out.append(soak_check())
	out.append(lifecycle_check())
	out.append(economy_integrity())
	out.append(audio_check())
	out.append(ads_check())
	out.append(store_check())
	out.append(purchase_paths_check())
	out.append(analytics_check())
	return out


static func _r(id: String, label: String, status: String, detail: String) -> Dictionary:
	return {"id": id, "label": label, "status": status, "detail": detail}


## Services are reached through the tree rather than by their autoload name.
##
## A `--script` entry point is compiled before the autoloads register their
## global identifiers, so a direct reference to `Ads` here would fail to
## compile and take the command-line runner down with it. Looking them up is
## two lines and makes this file usable from every entry point the project
## has: the game, the test runner, and the CI command line.
static func _svc(n: String) -> Node:
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null(n)
	return null


static func _headless() -> bool:
	return DisplayServer.get_name() == "headless" \
		or DisplayServer.get_name() == "dummy"


## --- hardware --------------------------------------------------------------

static func device_info() -> Dictionary:
	var bits: Array[String] = [
		OS.get_name(),
		OS.get_model_name(),
		"%d cores" % OS.get_processor_count(),
	]
	if OS.has_method("get_version"):
		bits.append("os " + OS.get_version())
	return _r("device", "Device", INFO, " / ".join(bits))


static func renderer_info() -> Dictionary:
	if _headless():
		return _r("renderer", "Renderer", UNKNOWN,
			"headless run -- no rendering device was created")
	var name: String = String(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method", "?"))
	var adapter: String = RenderingServer.get_video_adapter_name()
	var api: String = RenderingServer.get_video_adapter_api_version()
	return _r("renderer", "Renderer", INFO, "%s / %s / %s" % [name, adapter, api])


static func screen_check() -> Dictionary:
	if _headless():
		return _r("screen", "Screen", UNKNOWN,
			"headless run -- there is no screen to measure")
	var size: Vector2i = DisplayServer.window_get_size()
	if size.x <= 0 or size.y <= 0:
		return _r("screen", "Screen", FAIL, "window reports a zero dimension")
	var longest: float = float(maxi(size.x, size.y))
	var shortest: float = float(mini(size.x, size.y))
	var aspect: float = longest / maxf(shortest, 1.0)
	var dpi: int = DisplayServer.screen_get_dpi()
	var detail: String = "%dx%d, %.2f:1, %d dpi" % [size.x, size.y, aspect, dpi]
	if aspect < ASPECT_MIN or aspect > ASPECT_MAX:
		# Not a failure of the device -- a flag that this shape is outside what
		# the layout was designed against and wants looking at by eye.
		return _r("screen", "Screen", FAIL,
			detail + " -- outside the %.2f-%.2f band the layout was built for"
			% [ASPECT_MIN, ASPECT_MAX])
	return _r("screen", "Screen", PASS, detail)


## Cutouts, punch holes and gesture bars. Edge-to-edge is on in the export
## preset, so this is the number that decides whether the top row of the grid
## sits under a camera.
static func safe_area_check() -> Dictionary:
	if _headless():
		return _r("safe_area", "Safe area", UNKNOWN, "headless run")
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return _r("safe_area", "Safe area", UNKNOWN,
			"the platform reported no safe area")
	# The safe area is given in *screen* coordinates, not window ones. On a
	# phone the window is the screen and the difference never shows up; on a
	# desktop it produces nonsense insets, which is how this check found its
	# own bug. Measure against the screen, and say plainly when the run is
	# windowed and the number therefore does not describe a phone.
	var screen: int = DisplayServer.window_get_current_screen()
	var scr: Vector2i = DisplayServer.screen_get_size(screen)
	if scr.x <= 0 or scr.y <= 0:
		return _r("safe_area", "Safe area", UNKNOWN, "the screen reported no size")
	var top: int = safe.position.y
	var left: int = safe.position.x
	var bottom: int = scr.y - (safe.position.y + safe.size.y)
	var right: int = scr.x - (safe.position.x + safe.size.x)
	var detail: String = "insets t%d b%d l%d r%d of a %dx%d screen" % [
		top, bottom, left, right, scr.x, scr.y]
	if top < 0 or bottom < 0 or left < 0 or right < 0:
		return _r("safe_area", "Safe area", FAIL,
			detail + " -- a negative inset means the safe area does not sit "
			+ "inside the screen it was measured against")
	var win: Vector2i = DisplayServer.window_get_size()
	if win != scr:
		return _r("safe_area", "Safe area", UNKNOWN,
			detail + ", but this is a %dx%d window rather than a fullscreen app"
			% [win.x, win.y])
	if top == 0 and bottom == 0 and left == 0 and right == 0:
		return _r("safe_area", "Safe area", PASS,
			"no cutout or gesture inset reported on this display")
	return _r("safe_area", "Safe area", PASS, detail)


## Everything the UI scales by. A phone that reports a content scale the
## layout was not built for is how a board ends up half off the screen.
static func scaling_check() -> Dictionary:
	if _headless():
		return _r("scaling", "UI scaling", UNKNOWN, "headless run")
	var win: Vector2i = DisplayServer.window_get_size()
	var base := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 720)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1440)))
	var loop: MainLoop = Engine.get_main_loop()
	var scale: float = 1.0
	if loop is SceneTree:
		var root: Window = (loop as SceneTree).root
		scale = root.content_scale_factor
		var vp: Vector2i = root.get_visible_rect().size
		var detail: String = "%dx%d window, %dx%d canvas, base %dx%d, scale %.2f" % [
			win.x, win.y, vp.x, vp.y, base.x, base.y, scale]
		# The board is laid out to the shorter axis, so a canvas narrower than
		# the design base is the case that would clip it.
		if vp.x < base.x * 0.8:
			return _r("scaling", "UI scaling", FAIL,
				detail + " -- the canvas is much narrower than the layout was "
				+ "designed against, so the board may be clipped")
		return _r("scaling", "UI scaling", PASS, detail)
	return _r("scaling", "UI scaling", UNKNOWN, "no scene tree")


## What the board actually costs the renderer on this device.
##
## There is no published Godot figure for "how many 2D draw calls an Android
## phone can afford", so this does not pretend there is one. What it checks is
## the property the board was BUILT for: seventy cells drawn as batched
## rectangles must collapse into a small number of batches. If that number
## climbs, something has started drawing polygons -- a circle, an arc, an
## antialiased line -- and each one of those breaks the batch.
static func draw_budget() -> Dictionary:
	if _headless():
		return _r("draw", "Draw batching", UNKNOWN,
			"headless run -- nothing was rendered")
	var loop: MainLoop = Engine.get_main_loop()
	if not (loop is SceneTree):
		return _r("draw", "Draw batching", UNKNOWN, "no scene tree")
	var vp: Viewport = (loop as SceneTree).root
	var calls: int = vp.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS,
		Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var items: int = vp.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS,
		Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
	var detail: String = "%d canvas draw calls, %d canvas items" % [calls, items]
	if calls <= 0:
		return _r("draw", "Draw batching", UNKNOWN,
			"the renderer reported nothing this frame")
	if calls > DRAW_CALL_BUDGET:
		return _r("draw", "Draw batching", FAIL,
			detail + " -- budget is %d" % DRAW_CALL_BUDGET)
	return _r("draw", "Draw batching", PASS, detail)


## Derived from measurement in this project, not from any Godot document.
##
## The full board plus the header, the stratum panel, the machine tray and the
## action row measured **192 canvas draw calls** at 1080x1920 with every tile
## occupied. The budget is set at roughly twice that: enough headroom for a
## panel or two, tight enough that adding a polygon-based primitive to the
## per-cell drawing -- a circle, an arc, an antialiased line -- fails the check
## immediately, because seventy of them arrive at once.
const DRAW_CALL_BUDGET := 400


## Shader compilation after the game has started is a visible stutter.
##
## The compatibility renderer has no ubershaders and no pipeline
## pre-compilation, so every material first drawn at runtime compiles at that
## moment and drops frames. This counter is the only way to see it happening,
## and on a build that ships no custom shaders it should never move.
static func shader_stall_check() -> Dictionary:
	if _headless():
		return _r("shaders", "Shader stalls", UNKNOWN, "headless run")
	var n: float = Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_CANVAS)
	return _r("shaders", "Shader stalls", INFO,
		"%d canvas pipelines compiled so far -- watch this while playing, any "
		% int(n) + "increase is a stutter")


## Memory, and whether it is growing.
static func memory_check() -> Dictionary:
	var bits: Array[String] = []
	var info: Dictionary = OS.get_memory_info()
	var phys: int = int(info.get("physical", -1))
	var avail: int = int(info.get("available", -1))
	if phys > 0:
		bits.append("%d MB physical" % (phys / 1048576))
	if avail > 0:
		bits.append("%d MB available" % (avail / 1048576))
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	bits.append("%d nodes" % nodes)
	var orphans: int = int(Performance.get_monitor(
		Performance.OBJECT_ORPHAN_NODE_COUNT))
	if OS.is_debug_build():
		bits.append("%d orphaned" % orphans)
		bits.append("%.1f MB static" % (Performance.get_monitor(
			Performance.MEMORY_STATIC) / 1048576.0))
	if not _headless():
		bits.append("%.1f MB texture" % (Performance.get_monitor(
			Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0))
	var detail: String = ", ".join(bits)
	if nodes <= 0:
		# A `--script` entry point runs before the scene tree is populated, so
		# every autoload's children are momentarily counted as orphans. That
		# is startup order, not a leak, and calling it one would make the
		# command-line self test fail on a healthy build every time.
		return _r("memory", "Memory", UNKNOWN,
			detail + " -- the scene tree is not up yet, so these are not "
			+ "meaningful")
	if OS.is_debug_build() and orphans > 0:
		return _r("memory", "Memory", FAIL,
			detail + " -- an orphaned node is a leak")
	return _r("memory", "Memory", PASS, detail)


## The board is portrait-locked. A phone that ignores that, or a foldable that
## reports a landscape window anyway, is a layout that has never been seen.
static func orientation_check() -> Dictionary:
	if _headless():
		return _r("orientation", "Orientation", UNKNOWN, "headless run")
	var win: Vector2i = DisplayServer.window_get_size()
	var want_portrait: bool = int(ProjectSettings.get_setting(
		"display/window/handheld/orientation", 1)) == 1
	var is_portrait: bool = win.y >= win.x
	var detail: String = "%dx%d, %s" % [win.x, win.y,
		"portrait" if is_portrait else "landscape"]
	if want_portrait and not is_portrait:
		return _r("orientation", "Orientation", FAIL,
			detail + " -- the project is portrait-locked and this window is not")
	return _r("orientation", "Orientation", PASS, detail)


## The last board cell size, in pixels, as the board actually drew it. Set by
## `GridView` rather than guessed, because the board fits itself to whatever
## space the layout gives it and that depends on the screen.
static var last_cell_px: float = 0.0


## Android's minimum touch target is 48dp. A 7x10 grid on a narrow phone is
## right at that line, which is why nothing inside a cell is tappable -- but
## the cell itself is, and if it falls under the floor the board is not usable
## one-handed.
static func touch_target_check() -> Dictionary:
	if _headless():
		return _r("touch", "Touch targets", UNKNOWN, "headless run")
	if last_cell_px <= 0.0:
		return _r("touch", "Touch targets", UNKNOWN,
			"the board has not drawn yet")
	var dpi: int = DisplayServer.screen_get_dpi()
	if dpi <= 0:
		return _r("touch", "Touch targets", UNKNOWN,
			"this display reports no dpi, so pixels cannot be converted to dp")
	var dp: float = last_cell_px / (float(dpi) / 160.0)
	var detail: String = "%.0f px per cell at %d dpi = %.0f dp" % [
		last_cell_px, dpi, dp]
	if dp < 44.0:
		return _r("touch", "Touch targets", FAIL,
			detail + " -- under Android's 48dp minimum, the board will be "
			+ "hard to use one-handed")
	if dp < 48.0:
		return _r("touch", "Touch targets", INFO,
			detail + " -- just under the 48dp guideline; watch for mis-taps")
	return _r("touch", "Touch targets", PASS, detail)


## --- the game's own cost ---------------------------------------------------
##
## This is the part of performance that is the game's fault rather than the
## renderer's, and the only part that can be measured identically on a build
## server and on a phone. Frame rate is measured live by the diagnostics
## screen, because it needs frames.

static func cpu_benchmark() -> Dictionary:
	var g := Grid.new()
	for e: Array in BENCH_BOARD:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var s := Simulation.new(g, 20260923)
	# Warm the caches so the first tick's allocation is not the measurement.
	s.run_ticks(30)
	var t0: int = Time.get_ticks_usec()
	s.run_ticks(BENCH_TICKS)
	var elapsed_us: int = Time.get_ticks_usec() - t0
	var per_tick: float = float(elapsed_us) / float(BENCH_TICKS) / 1000.0
	var detail: String = "%.3f ms per tick over %d ticks on a full board" % [
		per_tick, BENCH_TICKS]
	if per_tick > BENCH_BUDGET_MS:
		return _r("cpu", "Simulation cost", FAIL,
			detail + " -- budget is %.1f ms" % BENCH_BUDGET_MS)
	return _r("cpu", "Simulation cost", PASS, detail)


## --- storage ---------------------------------------------------------------

static func storage_check() -> Dictionary:
	var probe := "user://.selftest_probe"
	var f := FileAccess.open(probe, FileAccess.WRITE)
	if f == null:
		return _r("storage", "Storage", FAIL,
			"cannot write to user:// -- saving will fail on this device")
	f.store_string("probe")
	f.close()
	var r := FileAccess.open(probe, FileAccess.READ)
	if r == null:
		return _r("storage", "Storage", FAIL, "wrote a file that cannot be read back")
	var got: String = r.get_as_text()
	r.close()
	var d := DirAccess.open("user://")
	if d != null:
		d.remove(probe)
	if got != "probe":
		return _r("storage", "Storage", FAIL, "read back %d bytes, expected 5" % got.length())
	return _r("storage", "Storage", PASS,
		"user:// is writable at " + OS.get_user_data_dir())


## Close the app, reopen it, and find the same factory. This is the check that
## matters most: a lost save is the one bug players do not forgive.
static func save_round_trip(state: Object) -> Dictionary:
	if state == null or not state.has_method("to_dict"):
		return _r("save", "Save round trip", UNKNOWN, "no live game state supplied")
	var save: Node = _svc("Save")
	if save == null:
		return _r("save", "Save round trip", UNKNOWN, "the save service is not loaded")
	var before: Dictionary = state.to_dict()
	var text_before: String = JSON.stringify(before)
	if not save.save_game(state):
		return _r("save", "Save round trip", FAIL, "the write itself failed")
	if not save.has_save():
		return _r("save", "Save round trip", FAIL, "no file exists after a successful write")
	var raw := FileAccess.open(save.PATH, FileAccess.READ)
	if raw == null:
		return _r("save", "Save round trip", FAIL, "the file cannot be reopened")
	var parsed: Variant = JSON.parse_string(raw.get_as_text())
	raw.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return _r("save", "Save round trip", FAIL, "the file on disk is not valid JSON")
	# Compare the fields the player would notice losing.
	var d: Dictionary = parsed
	for k: String in ["credits", "research", "cores", "depth", "max_depth"]:
		if not before.has(k):
			continue
		if not d.has(k):
			return _r("save", "Save round trip", FAIL, "'%s' did not survive the write" % k)
		if absf(float(d[k]) - float(before[k])) > 0.001:
			return _r("save", "Save round trip", FAIL,
				"'%s' changed across the write" % k)
	return _r("save", "Save round trip", PASS,
		"%d bytes, every headline field identical" % text_before.length())


## A phone that has been in a drawer for a week, or one whose clock jumped.
## The cap has to hold in both directions and the arithmetic has to be the
## arithmetic the offline panel prints.
static func long_idle_check() -> Dictionary:
	var mult: Dictionary = Economy.multipliers({})
	var rate := 12.5
	var week: float = 7.0 * 24.0 * 3600.0
	var capped: Dictionary = Economy.offline_yield(rate, week, mult)
	var cap_seconds: float = Economy.OFFLINE_BASE_HOURS * 3600.0
	if float(capped["seconds_counted"]) > cap_seconds + 1.0:
		return _r("idle", "Long idle", FAIL,
			"a week away paid %.0f s, cap is %.0f s"
			% [float(capped["seconds_counted"]), cap_seconds])
	var expected: float = rate * cap_seconds * Economy.OFFLINE_BASE_RATE
	if absf(float(capped["amount"]) - expected) > 1.0:
		return _r("idle", "Long idle", FAIL,
			"paid %.2f, the stated product is %.2f"
			% [float(capped["amount"]), expected])
	# And a backwards clock must pay nothing rather than something negative.
	var backwards: Dictionary = Economy.offline_yield(rate, -3600.0, mult)
	if float(backwards["amount"]) < 0.0:
		return _r("idle", "Long idle", FAIL, "a backwards clock produced a negative payout")
	return _r("idle", "Long idle", PASS,
		"a week away pays the %.0f h cap exactly; a backwards clock pays nothing"
		% Economy.OFFLINE_BASE_HOURS)


## The monetization layer must not be able to move an economy number. This runs
## the same board twice -- once as a free player, once as a licensed player
## with ads removed -- and requires identical output.
static func economy_integrity() -> Dictionary:
	var ads: Node = _svc("Ads")
	var a: Dictionary = _run_board()
	var was_removed: bool = false
	if ads != null:
		was_removed = bool(ads.ads_removed)
		ads.ads_removed = true
	var b: Dictionary = _run_board()
	if ads != null:
		ads.ads_removed = was_removed
	if absf(float(a["credits"]) - float(b["credits"])) > 0.0001:
		return _r("economy", "Economy isolation", FAIL,
			"owning the licence changed earnings: %.4f vs %.4f"
			% [float(a["credits"]), float(b["credits"])])
	if absf(float(a["research"]) - float(b["research"])) > 0.0001:
		return _r("economy", "Economy isolation", FAIL,
			"owning the licence changed research")
	return _r("economy", "Economy isolation", PASS,
		"identical output with and without the licence (%.2f credits)"
		% float(a["credits"]))


static func _run_board() -> Dictionary:
	var g := Grid.new()
	for e: Array in BENCH_BOARD:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var s := Simulation.new(g, 777)
	return s.run_ticks(300)


## Writing the save has to be quick. It happens on every pause, and a pause is
## Android telling the app it is about to be killed -- a slow write there is a
## lost session.
static func save_cost(state: Object = null) -> Dictionary:
	var save: Node = _svc("Save")
	var st: Object = state
	if st == null:
		st = _svc("Sim")
	if save == null or st == null or not st.has_method("to_dict"):
		return _r("save_cost", "Save speed", UNKNOWN, "no live game state")
	var t0: int = Time.get_ticks_usec()
	for _i in range(5):
		save.save_game(st)
	var ms: float = float(Time.get_ticks_usec() - t0) / 5000.0
	var detail: String = "%.2f ms per save" % ms
	if ms > SAVE_BUDGET_MS:
		return _r("save_cost", "Save speed", FAIL,
			detail + " -- budget is %.0f ms" % SAVE_BUDGET_MS)
	return _r("save_cost", "Save speed", PASS, detail)


## Android gives an app a short, unspecified moment after onPause. Twenty
## milliseconds is an arbitrary ceiling, chosen to be far enough under any
## plausible allowance that the question never has to be asked again.
const SAVE_BUDGET_MS := 20.0


## Killed and reopened, not paused and resumed.
##
## Android does not close apps, it kills them, and the path where a process
## dies between two frames is the one autosave does not get to run on. This
## reads the save file back off disk exactly as a cold launch would and
## compares it to what is in memory.
static func persistence_check(state: Object) -> Dictionary:
	var save: Node = _svc("Save")
	if save == null or state == null or not state.has_method("to_dict"):
		return _r("persistence", "Survives a restart", UNKNOWN,
			"no live game state")
	if not save.save_game(state):
		return _r("persistence", "Survives a restart", FAIL, "the write failed")
	var f := FileAccess.open(save.PATH, FileAccess.READ)
	if f == null:
		return _r("persistence", "Survives a restart", FAIL,
			"the file cannot be reopened")
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return _r("persistence", "Survives a restart", FAIL,
			"what is on disk is not valid JSON")
	var live: Dictionary = state.to_dict()
	var disk: Dictionary = parsed
	# Everything a player would notice losing, including the board itself and
	# how far through the tutorial they are.
	var fields: Array[String] = ["credits", "research", "cores", "depth",
		"max_depth", "collapses", "tutorial"]
	var missing: Array[String] = []
	for k: String in fields:
		if not live.has(k):
			continue
		if not disk.has(k):
			missing.append(k)
	if not missing.is_empty():
		return _r("persistence", "Survives a restart", FAIL,
			"not written to disk: " + ", ".join(missing))
	var grid_on_disk: bool = disk.has("grid") \
		and typeof(disk["grid"]) == TYPE_DICTIONARY
	if not grid_on_disk:
		return _r("persistence", "Survives a restart", FAIL,
			"the board itself is not in the save")
	return _r("persistence", "Survives a restart", PASS,
		"%d fields and the board, read back off disk" % fields.size())


## The board promises, before any credits are spent, what a placement will do
## to each neighbour. If that number and the result disagree, the feature is
## worse than not having it.
static func preview_truth() -> Dictionary:
	var g := Grid.new()
	g.place(Grid.idx(3, 3), "smelter")
	var before: float = g.heat_at(Grid.idx(3, 3))
	var boiler: Dictionary = MachineDB.get_machine("boiler")
	var predicted: float = float(boiler["heat_out"]) * g.heat_spread
	g.place(Grid.idx(3, 2), "boiler")
	var actual: float = g.heat_at(Grid.idx(3, 3)) - before
	if absf(actual - predicted) > 0.001:
		return _r("preview", "Placement preview", FAIL,
			"promised %+.2f heat, delivered %+.2f" % [predicted, actual])
	return _r("preview", "Placement preview", PASS,
		"the previewed change is the change that happens (%+.2f)" % actual)


## The headline credits-per-second is an average over a window. It used to
## keep publishing that window after the board had changed, so for three
## seconds after any placement -- and right through a collapse, on an empty
## board -- it reported the rate of a factory that no longer existed.
##
## Checked live rather than synthetically: the measurement window can never be
## older than the last change to the board.
static func rate_freshness(state: Object) -> Dictionary:
	if state == null or not state.has_method("rate_window_age"):
		return _r("rate", "Rate readout", UNKNOWN, "no live game state")
	var window: float = float(state.call("rate_window_age"))
	var since: float = float(state.call("seconds_since_board_change"))
	var detail: String = "measured over %.1fs; board last changed %.1fs ago" % [
		window, since]
	if window > since + 0.35:
		return _r("rate", "Rate readout", FAIL,
			detail + " -- the number on screen includes a board that is gone")
	return _r("rate", "Rate readout", PASS, detail)


## The result of the last soak run, if one has been done. A soak is the only
## way to see thermal throttling and slow memory growth, and it is the one
## check that cannot be hurried.
static var soak_result: Dictionary = {}


static func soak_check() -> Dictionary:
	if soak_result.is_empty():
		return _r("soak", "Long session", UNKNOWN,
			"no soak run yet -- start one from this screen and leave the "
			+ "phone alone")
	var d: Dictionary = soak_result
	var detail: String = ("%.0f min: frame p99 %.1f -> %.1f ms, "
		+ "memory %+.1f MB, %d samples") % [float(d["minutes"]),
		float(d["p99_start"]), float(d["p99_end"]), float(d["mem_delta_mb"]),
		int(d["samples"])]
	# A phone that throttles shows up as frame time climbing while nothing on
	# screen has changed. Half again as slow is well past noticeable.
	if float(d["p99_end"]) > float(d["p99_start"]) * 1.5 + 2.0:
		return _r("soak", "Long session", FAIL,
			detail + " -- frame time degraded, which is what thermal "
			+ "throttling looks like")
	if float(d["mem_delta_mb"]) > 40.0:
		return _r("soak", "Long session", FAIL,
			detail + " -- memory kept growing")
	return _r("soak", "Long session", PASS, detail)


## --- app lifecycle ---------------------------------------------------------
##
## Launch, suspend, resume, relaunch. None of these can be tested from a build
## server; all of them are things a phone does to an app unasked, and the only
## way to know they were handled is to have recorded them when they happened.

const LIFECYCLE_PATH := "user://lifecycle.json"


static func _lifecycle() -> Dictionary:
	if not FileAccess.file_exists(LIFECYCLE_PATH):
		return {}
	var f := FileAccess.open(LIFECYCLE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func _write_lifecycle(d: Dictionary) -> void:
	var f := FileAccess.open(LIFECYCLE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()


static func note_launch() -> void:
	var d: Dictionary = _lifecycle()
	d["launches"] = int(d.get("launches", 0)) + 1
	d["last_launch"] = int(Time.get_unix_time_from_system())
	_write_lifecycle(d)


static func note_pause() -> void:
	var d: Dictionary = _lifecycle()
	d["pauses"] = int(d.get("pauses", 0)) + 1
	d["paused_at"] = int(Time.get_unix_time_from_system())
	_write_lifecycle(d)


static func note_resume() -> void:
	var d: Dictionary = _lifecycle()
	d["resumes"] = int(d.get("resumes", 0)) + 1
	var away: int = int(Time.get_unix_time_from_system()) - int(d.get("paused_at", 0))
	if int(d.get("paused_at", 0)) > 0 and away >= 0:
		d["last_away"] = away
		d["longest_away"] = maxi(int(d.get("longest_away", 0)), away)
	_write_lifecycle(d)


static func lifecycle_check() -> Dictionary:
	var d: Dictionary = _lifecycle()
	if d.is_empty():
		return _r("lifecycle", "App lifecycle", UNKNOWN,
			"nothing recorded yet -- background the app and come back")
	var launches: int = int(d.get("launches", 0))
	var pauses: int = int(d.get("pauses", 0))
	var resumes: int = int(d.get("resumes", 0))
	var detail: String = "%d launches, %d suspends, %d resumes" % [
		launches, pauses, resumes]
	if d.has("longest_away"):
		detail += ", longest gap %s" % Economy.fmt_duration(
			float(d["longest_away"]))
	if pauses > 0 and resumes == 0:
		return _r("lifecycle", "App lifecycle", FAIL,
			detail + " -- the app was suspended but never saw a resume, so "
			+ "anything restored on resume is not running")
	return _r("lifecycle", "App lifecycle", PASS, detail)


## Every sound this build can play. A generator that silently failed leaves a
## game that is simply quiet, which is very hard to notice in testing.
static func audio_check() -> Dictionary:
	var j: Node = _svc("Juice")
	if j == null:
		return _r("audio", "Sound", UNKNOWN, "the audio service is not loaded")
	var names: Array = j.sfx_names()
	if names.size() < EXPECTED_SOUNDS:
		return _r("audio", "Sound", FAIL,
			"%d of %d sounds were generated: %s"
			% [names.size(), EXPECTED_SOUNDS, ", ".join(names)])
	var samples: int = j.total_samples()
	return _r("audio", "Sound", PASS,
		"%d sounds synthesised at startup, %d KB of samples, no audio files"
		% [names.size(), samples * 2 / 1024])


## Every entry in Juice's generator list. Written out so that deleting one is
## a visible change here too.
const EXPECTED_SOUNDS := 14


## --- the native plugins ----------------------------------------------------
##
## These report what is actually bound. "Not installed" is a normal, passing
## result everywhere except a signed build on a phone -- which is exactly the
## situation this screen exists to make visible.

static func ads_check() -> Dictionary:
	var ads: Node = _svc("Ads")
	if ads == null:
		return _r("ads", "Ad plugin", UNKNOWN, "the ad service is not loaded")
	var st: Dictionary = ads.status()
	if not bool(st["plugin_present"]):
		return _r("ads", "Ad plugin", UNKNOWN,
			"not installed in this build -- the game runs, no ad can be shown")
	var bits: Array[String] = [
		"loaded" if bool(st["available"]) else "no ad ready",
		"consent ok" if bool(st["consent"]) else "consent not resolved",
		"%d watched" % int(st["watched"]),
	]
	if String(st["last_error"]) != "":
		bits.append("last error: " + String(st["last_error"]))
	var status: String = PASS if bool(st["available"]) else FAIL
	return _r("ads", "Ad plugin", status, ", ".join(bits))


static func store_check() -> Dictionary:
	var store: Node = _svc("Store")
	if store == null:
		return _r("store", "Billing plugin", UNKNOWN, "the store service is not loaded")
	var st: Dictionary = store.status()
	if not bool(st["plugin_present"]):
		return _r("store", "Billing plugin", UNKNOWN,
			"not installed in this build -- nothing can be purchased")
	var catalogue: Array = st.get("catalogue", [])
	var confirmed: Array = st.get("confirmed", [])
	var owned: Array = st.get("owned", [])
	var pending: Array = st.get("pending", [])
	var sandbox: String = " [SANDBOX IDS]" if bool(st.get("sandbox_ids", false)) else ""
	if not pending.is_empty():
		# Not a failure. A delayed payment instrument is a supported state and
		# the device report should say so rather than calling it broken.
		return _r("store", "Billing plugin", INFO,
			"%d purchase(s) waiting on payment: %s%s"
			% [pending.size(), ", ".join(pending), sandbox])
	if confirmed.size() < catalogue.size():
		var missing: Array = []
		for k: String in catalogue:
			if not confirmed.has(k) and not owned.has(k):
				missing.append(k)
		if not missing.is_empty():
			return _r("store", "Billing plugin", FAIL,
				"the store did not confirm %s -- %s%s"
				% [", ".join(missing), String(st.get("last_error", "")), sandbox])
	var bits: Array[String] = []
	var prices: Dictionary = st.get("prices", {})
	for k: String in catalogue:
		if owned.has(k):
			bits.append("%s owned" % k)
		else:
			bits.append("%s %s" % [k, String(prices.get(k, "no price"))])
	return _r("store", "Billing plugin", PASS,
		"%s%s" % [", ".join(bits), sandbox])


## Runs the purchase state machine on THIS device, in THIS build.
##
## `tests/test_store.gd` proves the same logic in CI, on x86-64, against a
## headless Godot. This proves it in the binary that is actually installed on
## the phone, which is a different compiler target, a different plugin set and
## a different set of autoload timings -- and it is the only part of the
## monetization that can be verified without a store account, so it is worth
## having as a row on the device report rather than as an act of faith.
##
## It never touches the billing plugin and never charges anything: it feeds
## `Store` the same record shapes a plugin delivers and checks what it does
## with them, then puts the entitlement state back exactly as it found it.
static func purchase_paths_check() -> Dictionary:
	var store: Node = _svc("Store")
	if store == null:
		return _r("purchase", "Purchase logic", UNKNOWN,
			"the store service is not loaded")
	if not OS.is_debug_build():
		# The hooks this needs are compiled out of a release build on purpose.
		return _r("purchase", "Purchase logic", UNKNOWN,
			"release build -- the injection hooks are debug-only, so this "
			+ "check only runs on a debug APK")
	var key: String = MonetizationDB.LICENCE
	var id: String = MonetizationDB.store_id(key)
	var before_owned: bool = store.call("owns", key)
	var fails: Array[String] = []

	store.call("debug_clear_state")

	# 1. PENDING grants nothing and is not acknowledged.
	store.call("debug_ingest", {"product_id": id, "purchase_state": 2,
		"purchase_token": "selftest"})
	if store.call("owns", key):
		fails.append("a PENDING purchase granted the entitlement")
	if not store.call("is_pending", key):
		fails.append("a PENDING purchase was not recorded as pending")
	if int(store.call("debug_ack_queue")) != 0:
		fails.append("a PENDING purchase was acknowledged")

	# 2. The transition to PURCHASED grants, once, and acknowledges.
	store.call("debug_ingest", {"product_id": id, "purchase_state": 1,
		"purchase_token": "selftest"})
	if not store.call("owns", key):
		fails.append("a cleared PENDING purchase did not grant")
	if int(store.call("debug_ack_queue")) == 0:
		fails.append("a completed purchase was not queued for acknowledgement")

	# 3. Duplicate delivery is idempotent.
	var again: bool = store.call("debug_ingest", {"product_id": id,
		"purchase_state": 1, "purchase_token": "selftest"})
	if again:
		fails.append("a repeated delivery granted a second time")

	# 4. An id this build does not sell grants nothing.
	if store.call("debug_ingest", {"product_id": "infinite_credits",
		"purchase_state": 1, "purchase_token": "x"}):
		fails.append("an unknown product id was granted")

	# 5. A cancel is silent and grants nothing.
	store.call("debug_purchase_error", 1)
	if String(store.get("last_player_message")) != "":
		fails.append("a cancelled purchase nagged the player")

	# Put it back the way it was.
	store.call("debug_clear_state")
	if before_owned:
		store.call("debug_grant", key)

	if not fails.is_empty():
		return _r("purchase", "Purchase logic", FAIL, "; ".join(fails))
	return _r("purchase", "Purchase logic", PASS,
		"pending grants nothing, clearing grants once, duplicates are "
		+ "idempotent, unknown ids are refused, a cancel is silent")


static func analytics_check() -> Dictionary:
	var an: Node = _svc("Analytics")
	if an == null:
		return _r("analytics", "Event tracking", UNKNOWN,
			"the analytics service is not loaded")
	var dropped: Array = an.dropped_events()
	if not dropped.is_empty():
		return _r("analytics", "Event tracking", FAIL,
			"refused events still being sent: " + ", ".join(dropped))
	return _r("analytics", "Event tracking", PASS,
		"%d events this session, %d in the allowed vocabulary, none refused"
		% [an.event_count(), an.ALLOWED.size()])


## --- reporting -------------------------------------------------------------

## A plain-text report, for copying out of the diagnostics screen and pasting
## somewhere it can be read. No identifiers in it beyond the device model.
static func as_text(results: Array) -> String:
	var lines: Array[String] = [
		"Lodeworks self test",
		"version %s" % ProjectSettings.get_setting("application/config/version", "?"),
		"engine %s" % Engine.get_version_info().get("string", "?"),
		Time.get_datetime_string_from_system(true),
		"",
	]
	for r: Dictionary in results:
		lines.append("[%s] %s: %s" % [String(r["status"]).to_upper(),
			String(r["label"]), String(r["detail"])])
	lines.append("")
	lines.append(summary(results))
	return "\n".join(lines)


## One line per check, in a shape that can be pasted back verbatim. The whole
## point of the device pass is that its result travels, and a screenshot of a
## scrolling list does not.
static func as_checklist(results: Array) -> String:
	var lines: Array[String] = []
	for r: Dictionary in results:
		lines.append("%-12s %-8s %s" % [String(r["id"]),
			String(r["status"]).to_upper(), String(r["detail"])])
	return "\n".join(lines)


static func summary(results: Array) -> String:
	var p: int = 0
	var f: int = 0
	var u: int = 0
	for r: Dictionary in results:
		match String(r["status"]):
			PASS: p += 1
			FAIL: f += 1
			UNKNOWN: u += 1
	return "%d passed, %d failed, %d unknown" % [p, f, u]


static func failed(results: Array) -> Array:
	var out: Array = []
	for r: Dictionary in results:
		if String(r["status"]) == FAIL:
			out.append(r)
	return out
