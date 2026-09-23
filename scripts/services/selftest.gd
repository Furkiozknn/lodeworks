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
	[0, 1, "drill"], [1, 1, "drill"], [2, 1, "drill"], [3, 1, "drill"],
	[4, 1, "drill"], [5, 1, "drill"], [6, 1, "drill"],
	[0, 2, "crusher"], [1, 2, "crusher"], [2, 2, "crusher"], [3, 2, "crusher"],
	[4, 2, "crusher"], [5, 2, "crusher"], [6, 2, "crusher"],
	[0, 3, "smelter"], [1, 3, "smelter"], [2, 3, "assembler"], [3, 3, "press"],
	[4, 3, "smelter"], [5, 3, "smelter"], [6, 3, "smelter"],
	[0, 4, "vault"], [1, 4, "vault"], [2, 4, "lab"], [3, 4, "vault"],
	[4, 4, "vault"], [5, 4, "vault"], [6, 4, "vault"],
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
	out.append(draw_budget())
	out.append(shader_stall_check())
	out.append(cpu_benchmark())
	out.append(memory_check())
	out.append(storage_check())
	out.append(save_round_trip(state))
	out.append(save_cost())
	out.append(long_idle_check())
	out.append(lifecycle_check())
	out.append(economy_integrity())
	out.append(audio_check())
	out.append(ads_check())
	out.append(store_check())
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
const EXPECTED_SOUNDS := 12


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
	if bool(st["owned"]):
		return _r("store", "Billing plugin", PASS, "licence owned on this account")
	if not bool(st["product_confirmed"]):
		return _r("store", "Billing plugin", FAIL,
			"'%s' was not confirmed by the store -- %s"
			% [String(st["product_id"]), String(st["last_error"])])
	var price: String = String(st["price"])
	return _r("store", "Billing plugin", PASS,
		"'%s' is sellable here at %s" % [String(st["product_id"]),
			price if price != "" else "a price the store did not name"])


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
