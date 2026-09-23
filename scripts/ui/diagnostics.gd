extends Control

## The diagnostics screen. One tap, from the settings panel, on a real phone.
##
## This exists because a build server cannot answer the questions that decide
## whether this game is shippable: what frame time this SoC produces with the
## real board on screen, what this panel's aspect ratio and cutout do to the
## layout, how long this device takes to get a touch onto a frame, and whether
## the ad and billing plugins bound to anything. Every one of those is a
## property of the hardware, and the honest way to get them is to run the game
## on the hardware and read them off.
##
## The live measurements here are taken **through the real game**: the panel is
## translucent and does not pause anything, so the frame times are the frame
## times of the board underneath, not of a benchmark scene that renders
## something else. The static checks come from `SelfTest`, which also runs in
## CI so that a regression in the checks themselves gets caught.
##
## Anything that cannot be measured says so. There is no fallback estimate.

const SAMPLE_SECONDS := 5.0
const SAMPLE_CAP := 900

var _results: Array = []
var _frames: PackedFloat32Array = PackedFloat32Array()
var _sampling: bool = false
var _sample_left: float = 0.0
var _input_at_usec: int = -1
var _input_to_frame_ms: float = -1.0

var _list: VBoxContainer
var _perf: Label
var _counters: Label
var _summary: Label
var _probe: Button
var _log: Label
var _on_close: Callable
var _pipelines_at_open: int = 0
var _soak_left: float = -1.0
var _soak_frames: PackedFloat32Array = PackedFloat32Array()
var _soak_first: PackedFloat32Array = PackedFloat32Array()
var _soak_mem_start: float = 0.0
var _soak_btn: Button = null


static func open_over(parent: Node, on_close: Callable = Callable()) -> Control:
	var d: Control = (load("res://scripts/ui/diagnostics.gd") as GDScript).new()
	d.set("_on_close", on_close)
	parent.add_child(d)
	return d


func _ready() -> void:
	# Anchors AND offsets, plus an explicit size.
	#
	# A Control added to a plain Control parent after that parent has already
	# been laid out never gets a resize notification, so anchors alone leave
	# it at zero by zero -- it exists, its methods work, and it draws nothing.
	# That is exactly how this screen passed a smoke test for two releases
	# while rendering as an invisible rectangle over the board.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if get_parent() is Control:
		size = (get_parent() as Control).size
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pipelines_at_open = int(Performance.get_monitor(
		Performance.PIPELINE_COMPILATIONS_CANVAS))
	_build()
	run_checks()
	start_sampling()


func _exit_tree() -> void:
	Ads.debug_set_break_on_device(false)


func _build() -> void:
	# Translucent, so the board keeps rendering underneath and the frame times
	# below are the frame times of the actual game.
	var dim := ColorRect.new()
	# Nearly opaque. The first version let the board show through at 0.86 and
	# the header and action row behind it read as part of this screen, which
	# on a report that is meant to be pasted into a bug is worse than useless.
	dim.color = Color(0.03, 0.04, 0.05, 0.985)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	col.add_child(_head("Device self test", 26, Palette.TEXT))

	_perf = _head("measuring frame time...", 19, Palette.TEXT_DIM)
	col.add_child(_perf)

	_counters = _head("", 15, Palette.TEXT_FAINT)
	col.add_child(_counters)

	_summary = _head("", 17, Palette.TEXT_FAINT)
	col.add_child(_summary)

	# The live checks that need a real device and a real account: an ad that
	# actually plays, a product the store actually sells, a purchase that
	# actually restores. None of these can be answered anywhere but here.
	var live := HBoxContainer.new()
	live.add_theme_constant_override("separation", 6)
	live.add_child(_action("Play an ad", _try_ad))
	live.add_child(_action("Check the store", _try_store))
	live.add_child(_action("Restore", _try_restore))
	live.add_child(_action("Break the SDK", _try_break))
	col.add_child(live)

	var live2 := HBoxContainer.new()
	live2.add_theme_constant_override("separation", 6)
	live2.add_child(_action("Sound + buzz", _try_audio))
	live2.add_child(_action("Soak %d min" % SOAK_MINUTES, _toggle_soak))
	live2.add_child(_action("Copy report", _copy_report))
	col.add_child(live2)

	_log = _head("", 15, Palette.TEXT_DIM)
	col.add_child(_log)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	_probe = _btn("Tap to time input")
	_probe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Timed on the press itself, not on the release, so the number is the path
	# from the touch reaching the app to the next frame reaching the panel.
	_probe.button_down.connect(_on_probe_down)
	row.add_child(_probe)

	var again := _btn("Re-run")
	again.pressed.connect(func():
		run_checks()
		start_sampling())
	row.add_child(again)

	var close := _btn("Close")
	close.pressed.connect(func():
		if _on_close.is_valid():
			_on_close.call()
		queue_free())
	row.add_child(close)

	col.add_child(row)


func _head(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _action(text: String, cb: Callable) -> Button:
	var b := _btn(text)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b


func _say(text: String) -> void:
	_log.text = text


## The real rewarded flow, on demand rather than by waiting for an offline
## return. Reports what happened either way, because "nothing visible
## happened" is the most common outcome of a misconfigured ad unit and the
## hardest to diagnose from the game itself.
func _try_ad() -> void:
	var st: Dictionary = Ads.status()
	if not bool(st["plugin_present"]):
		_say("No ad plugin in this build. Install it and rebuild.")
		return
	if not bool(st["available"]):
		_say("Plugin bound but no ad is loaded. Last error: %s"
			% (String(st["last_error"]) if String(st["last_error"]) != "" else "none"))
		return
	_say("Requesting a rewarded ad...")
	var placement: String = Ads.P_DOUBLE_OFFLINE
	if not Ads.can_offer(placement):
		_say("Refused: cooldown %.0fs, removed=%s"
			% [Ads.cooldown_remaining(), str(Ads.ads_removed)])
		return
	if not Ads.show_rewarded(placement):
		_say("show_rewarded refused. Last error: " + Ads.last_error)


func _try_store() -> void:
	var st: Dictionary = Store.status()
	if not bool(st["plugin_present"]):
		_say("No billing plugin in this build.")
		return
	Store.query_product_details()
	_say("Asked the store about %s. Re-run the checks in a moment; the "
		% ", ".join(MonetizationDB.all_store_ids())
		+ "Billing row will say whether they came back.")


func _try_restore() -> void:
	if not Store.is_available():
		_say("No billing service to restore from.")
		return
	Store.restore()
	_say("Restore requested. Anything this account owns will appear on the "
		+ "Billing row within a second or two.")


## Prove the game survives the SDK failing, on the device, rather than only in
## the test suite. Flips the ad layer into its broken state and leaves it
## there until the screen is closed.
## Every sound in the game, in order, with a buzz on each.
##
## A phone can be silent for reasons that have nothing to do with the game --
## a mute switch, a routed output, a broken speaker, a sound that failed to
## synthesise. This is the only way to find out which, and it takes eight
## seconds.
func _try_audio() -> void:
	var names: Array = Juice.sfx_names()
	_say("Playing %d sounds. You should hear each one and feel a buzz."
		% names.size())
	var i: int = 0
	for n: String in names:
		if String(n) == "ambient":
			continue
		var delay: float = float(i) * 0.55
		get_tree().create_timer(delay).timeout.connect(func():
			Juice.play(String(n))
			Input.vibrate_handheld(14, 0.5))
		i += 1


## How long a soak runs. Long enough for a phone to get warm and start
## throttling, short enough that somebody will actually sit through it.
const SOAK_MINUTES := 3
## The first and last thirty seconds are compared; everything between is what
## heats the device up.
const SOAK_EDGE_SECONDS := 30.0


func _toggle_soak() -> void:
	if _soak_left > 0.0:
		_soak_left = -1.0
		_say("Soak cancelled.")
		return
	_soak_left = float(SOAK_MINUTES) * 60.0
	_soak_frames = PackedFloat32Array()
	_soak_first = PackedFloat32Array()
	_soak_mem_start = _memory_mb()
	_say("Soaking for %d minutes. Leave the game on this screen and put the "
		% SOAK_MINUTES + "phone down. Frame time and memory are being "
		+ "sampled; thermal throttling shows up as the first number rising.")


func _memory_mb() -> float:
	var info: Dictionary = OS.get_memory_info()
	var phys: int = int(info.get("available", -1))
	if phys > 0:
		# Available memory falls as the app grows, so the delta is negated to
		# read as "the app grew by".
		return -float(phys) / 1048576.0
	if OS.is_debug_build():
		return Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	return 0.0


func _soak_step(delta: float) -> void:
	var ms: float = delta * 1000.0
	if _soak_left > float(SOAK_MINUTES) * 60.0 - SOAK_EDGE_SECONDS:
		_soak_first.append(ms)
	_soak_frames.append(ms)
	_soak_left -= delta
	var left: int = int(ceil(_soak_left))
	if left % 10 == 0:
		_say("Soaking... %d:%02d left, %d samples"
			% [left / 60, left % 60, _soak_frames.size()])
	if _soak_left > 0.0:
		return
	_soak_left = -1.0
	# The last thirty seconds against the first thirty.
	var tail := PackedFloat32Array()
	var window: int = mini(_soak_first.size(), _soak_frames.size())
	for i in range(maxi(_soak_frames.size() - window, 0), _soak_frames.size()):
		tail.append(_soak_frames[i])
	SelfTest.soak_result = {
		"minutes": float(SOAK_MINUTES),
		"p99_start": _p99(_soak_first),
		"p99_end": _p99(tail),
		"mem_delta_mb": _memory_mb() - _soak_mem_start,
		"samples": _soak_frames.size(),
	}
	run_checks()
	_say("Soak finished. The Long session row above has the result.")


func _p99(a: PackedFloat32Array) -> float:
	if a.is_empty():
		return 0.0
	var sorted: Array = Array(a)
	sorted.sort()
	return float(sorted[mini(sorted.size() - 1,
		int(float(sorted.size()) * 0.99))])


func _try_break() -> void:
	Ads.debug_set_break_on_device(true)
	run_checks()
	_say("Ad layer forced into failure. The game should be completely "
		+ "unaffected. Close and reopen this screen to restore it.")


func _btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size = Vector2(0, 52)
	return b


## --- static checks ---------------------------------------------------------

func run_checks() -> void:
	_results = SelfTest.run_all(Sim)
	for c in _list.get_children():
		c.queue_free()
	for r: Dictionary in _results:
		_list.add_child(_row(r))
	_summary.text = SelfTest.summary(_results)


func _row(r: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	var status: String = String(r["status"])
	var col: Color = Palette.TEXT_DIM
	match status:
		SelfTest.PASS: col = Palette.GOOD
		SelfTest.FAIL: col = Palette.BAD
		SelfTest.UNKNOWN: col = Palette.CORE
	box.add_child(_head("%s  —  %s" % [status.to_upper(), String(r["label"])], 18, col))
	box.add_child(_head(String(r["detail"]), 15, Palette.TEXT_FAINT))
	return box


## --- live frame timing -----------------------------------------------------

func start_sampling() -> void:
	_frames = PackedFloat32Array()
	_sample_left = SAMPLE_SECONDS
	_sampling = true


func _process(delta: float) -> void:
	if _soak_left > 0.0:
		_soak_step(delta)
	if _input_at_usec > 0:
		_input_to_frame_ms = float(Time.get_ticks_usec() - _input_at_usec) / 1000.0
		_input_at_usec = -1
		_probe.text = "input to frame: %.1f ms" % _input_to_frame_ms

	if not _sampling:
		return
	if _frames.size() < SAMPLE_CAP:
		_frames.append(delta * 1000.0)
	_sample_left -= delta
	if _sample_left <= 0.0:
		_sampling = false
	_perf.text = _perf_text()
	_counters.text = _counter_text()


## The renderer's own numbers, live. Draw calls are the one that matters on a
## board of seventy tiles: they should stay flat while the board animates, and
## a jump of seventy means something started drawing polygons.
func _counter_text() -> String:
	var vp: Viewport = get_viewport()
	var calls: int = vp.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS,
		Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var items: int = vp.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS,
		Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
	var pipe: int = int(Performance.get_monitor(
		Performance.PIPELINE_COMPILATIONS_CANVAS)) - _pipelines_at_open
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var tex: float = Performance.get_monitor(
		Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	var bits: Array[String] = [
		"%d draw calls" % calls,
		"%d items" % items,
		"%d nodes" % nodes,
		"%.1f MB textures" % tex,
	]
	if pipe > 0:
		bits.append("%d shader compiles since opening — each one is a stutter" % pipe)
	var info: Dictionary = OS.get_memory_info()
	if int(info.get("available", -1)) > 0:
		bits.append("%d MB free" % (int(info["available"]) / 1048576))
	return "  ·  ".join(bits)


func _on_probe_down() -> void:
	_input_at_usec = Time.get_ticks_usec()


## Average frame time is the number people quote and the least useful one. An
## idle game is judged on whether it stutters, so the worst frames get equal
## billing here.
func _perf_text() -> String:
	if _frames.size() < 5:
		return "measuring frame time..."
	var sorted: Array = Array(_frames)
	sorted.sort()
	var n: int = sorted.size()
	var total: float = 0.0
	for v: float in sorted:
		total += v
	var avg: float = total / float(n)
	var p50: float = float(sorted[n / 2])
	var p99: float = float(sorted[mini(n - 1, int(float(n) * 0.99))])
	var worst: float = float(sorted[n - 1])
	var line: String = "%.1f fps  ·  frame %.1f ms median, %.1f ms avg, %.1f ms p99, %.1f ms worst  (%d frames)" % [
		1000.0 / maxf(p50, 0.001), p50, avg, p99, worst, n]
	if _sampling:
		line += "  · sampling"
	return line


## --- report ----------------------------------------------------------------

func report_text() -> String:
	var body: String = SelfTest.as_text(_results)
	var live: String = "\nlive frame timing: " + _perf_text()
	live += "\nrenderer: " + _counter_text()
	# The pasteable part. A scrolling list of rows does not travel; one block
	# of "id STATUS detail" does.
	live += "\n\n--- checklist ---\n" + SelfTest.as_checklist(_results)
	if _input_to_frame_ms >= 0.0:
		live += "\ninput to frame: %.1f ms" % _input_to_frame_ms
	else:
		live += "\ninput to frame: not measured -- the probe was not tapped"
	return body + live


func _copy_report() -> void:
	var text: String = report_text()
	DisplayServer.clipboard_set(text)
	# A file too, because a clipboard does not survive the app being killed and
	# this is exactly the report someone wants to attach to a bug.
	var f := FileAccess.open("user://selftest.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	_summary.text = SelfTest.summary(_results) + "  ·  copied, and written to selftest.txt"
