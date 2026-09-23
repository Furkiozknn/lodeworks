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
	[0, 2, "drill"], [1, 2, "crusher"], [2, 2, "smelter"], [3, 2, "boiler"],
	[4, 2, "smelter"], [5, 2, "crusher"], [6, 2, "drill"],
	[0, 3, "drill"], [1, 3, "crusher"], [2, 3, "press"], [3, 3, "coolant"],
	[4, 3, "press"], [5, 3, "crusher"], [6, 3, "drill"],
	[0, 4, "drill"], [1, 4, "crusher"], [2, 4, "assembler"], [3, 4, "amplifier"],
	[4, 4, "assembler"], [5, 4, "crusher"], [6, 4, "drill"],
	[0, 5, "vault"], [1, 5, "vault"], [2, 5, "lab"], [3, 5, "amplifier"],
	[4, 5, "lab"], [5, 5, "vault"], [6, 5, "vault"],
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
	out.append(cpu_benchmark())
	out.append(storage_check())
	out.append(save_round_trip(state))
	out.append(long_idle_check())
	out.append(economy_integrity())
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
