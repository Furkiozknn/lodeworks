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
var _summary: Label
var _probe: Button
var _on_close: Callable


static func open_over(parent: Node, on_close: Callable = Callable()) -> Control:
	var d: Control = (load("res://scripts/ui/diagnostics.gd") as GDScript).new()
	d.set("_on_close", on_close)
	parent.add_child(d)
	return d


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	run_checks()
	start_sampling()


func _build() -> void:
	# Translucent, so the board keeps rendering underneath and the frame times
	# below are the frame times of the actual game.
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.05, 0.86)
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

	_summary = _head("", 17, Palette.TEXT_FAINT)
	col.add_child(_summary)

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

	var copy := _btn("Copy report")
	copy.pressed.connect(_copy_report)
	row.add_child(copy)

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
