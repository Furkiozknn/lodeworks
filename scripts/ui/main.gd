extends Control

## The whole interface, built in code.
##
## No .tscn beyond an empty root. That is not dogma — it is because a UI
## assembled in one readable file can be reviewed, diffed and regenerated,
## while a scene file of a hundred nodes can only be edited by hand in an
## editor. For a project whose production model is "one person plus a lot of
## generated code", the code-built tree is the maintainable one.
##
## The screen is landscape and the world is the hero. `IsoView` fills it --
## the canyon, the island, the factory -- and the interface sits in the
## corners and along the edges, never over the middle:
##
##   top left      where you are: the stratum, its quota, what it does to you
##   top right     what you have: credits (and their rate), research, cores,
##                 and the settings button
##   right edge    heat view, zoom, and the problems button
##   bottom left   the three big actions: research, collapse, codex
##   bottom middle the machine tray -- or, while a machine is selected, the
##                 panel describing it, in the same place
##   bottom right  DESCEND
##   left edge     the Foreman, only when there is something to say
##
## `hud_rects()` reports where each of those landed, which is what the layout
## tests read: nothing overlaps, everything is inside the safe area, and the
## board is visible in the space that is left.

const PANEL_FADE := 0.14
## The interface's own margin inside the safe area.
const M := 14.0
const TOP_H := 66.0
## The bottom bar: a 96-unit key and the tray's margin round it.
const BOTTOM_H := 110.0
const ACTION_W := 96.0
const TOOL_W := 96.0
const DESCEND_W := 204.0
## Android's 48dp touch floor, in canvas units, on the phone where a canvas
## unit is smallest: a 16:9 1080p phone at 420 dpi, whose canvas grows to
## 1440x810, so one unit is 1080/810 px = 0.51 dp and 48 dp is 95 units.
## tools/layout_check.tscn measures every key against it.
const MIN_TOUCH := 96.0

var iso_view: IsoView
var _hud: Control
var _stratum_card: Control
## Parts of the interface a new player has no use for yet. They appear when
## they first mean something (_refresh): the world first, the interface as
## the game grows into it.
var _pill_research: Control
var _pill_cores: Control
var _btn_research: Button
var _btn_collapse: Button
var _resources: Control
var _tools: Control
var _actions: Control
var _tray: Control
var _palette_row: HBoxContainer
var _descend_box: Control
var _foreman: Control
var _foreman_label: Label
var _foreman_pose: int = Foreman.Pose.IDLE
var _foreman_time: float = 0.0
var _overlay: Control
var _toast: Label

var _lbl_credits: Label
var _lbl_rate: Label
var _lbl_research: Label
var _lbl_cores: Label
var _lbl_depth: Label
var _lbl_band: Label
var _lbl_quota: Label
var _quota_bar: ProgressBar
var _lbl_mods: Label
var _btn_problems: Button
var _lbl_problem_count: Label
var _btn_heat: Button
var _btn_zoom: Button
var _btn_descend: Button
var _lbl_descend_sub: Label
var _sheet: PanelContainer
var _sheet_body: VBoxContainer
var _sheet_stats: VBoxContainer
var _sheet_title: Label
var _sheet_art: Control
var _palette_buttons: Dictionary = {}
var _palette_costs: Dictionary = {}

var _armed: String = ""
var _toast_time: float = 0.0
var _shown_credits: float = 0.0
var _problem_cursor: int = 0
var _undo: Array = []
var _undo_btn: Button
var _undo_time: float = 0.0
var _pulsing: Control = null
var _pulse_t: float = 0.0
var _research_nudged: bool = false
var _last_thermal: int = 0
var _alerted_depth: int = -1
## The yard grew and the player has not been told yet (see _tell_yard_news).
var _yard_news: String = ""
## Safe-area insets in canvas units: left, top, right, bottom. Measured from
## the display on a device; settable by the layout tests.
var _safe := Vector4.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Sim.stats_changed.connect(_refresh)
	Sim.stats_changed.connect(_tutorial_watch)
	Sim.depth_changed.connect(func(d: int):
		_rebuild_palette()
		_refresh()
		if d > 0 and BuildArea.size_at(Sim.max_depth - 1, Sim.collapses) \
				!= BuildArea.size_at(Sim.max_depth, Sim.collapses):
			# Said once the world is in view again: a descent usually opens a
			# "new machine" card first.
			_yard_news = "Stratum %d. The yard is bigger: more ground to build on." % d
			call_deferred("_tell_yard_news")
		elif d > 0:
			_say("Stratum %d. Richer rock, stranger rules." % d, Foreman.Pose.JUMP, 3.5))
	Sim.machines_unlocked.connect(_on_unlocked)
	Sim.offline_earnings.connect(_show_offline)
	Sim.collapsed.connect(_on_collapsed)
	Ads.reward_granted.connect(_on_reward)
	Ads.reward_failed.connect(_on_reward_failed)
	Store.purchase_completed.connect(func(k):
		_toast_msg("%s active. Thank you." % MonetizationDB.title_of(String(k)))
		_refresh())
	Store.purchase_pending.connect(func(_k):
		# A delayed payment instrument. Nothing granted, nothing charged
		# twice, and the player is told rather than left wondering.
		_toast_msg("Waiting on your payment. It unlocks by itself."))
	Store.theme_changed.connect(func(_id):
		if iso_view != null:
			iso_view.palette_changed()
		_rebuild_palette()
		_refresh())
	resized.connect(_layout_hud)
	SelfTest.note_launch()
	Sim.start()
	_rebuild_palette()
	_shown_credits = Sim.credits
	_apply_safe_area()
	_layout_hud()
	_refresh()
	_refresh_hint()
	get_tree().auto_accept_quit = false

	# An idle game is left running. Uncapped frames on a phone is a warm
	# pocket and a flat battery for a board that changes ten times a second,
	# so the cap is set here rather than left to whatever the device does.
	Engine.max_fps = 60
	Juice.sound_enabled = bool(Sim.settings.get("sound", true))
	Juice.haptics_enabled = bool(Sim.settings.get("haptics", true))
	Juice.start_ambient()


func _notification(what: int) -> void:
	# Mobile apps are killed, not closed. Saving on every pause is the only
	# reliable moment; waiting for a quit notification loses the session.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Save.save_game(Sim)
		SelfTest.note_pause()
		# Nothing of this game should keep making noise in a pocket.
		Juice.stop_ambient()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		SelfTest.note_resume()
		Juice.start_ambient()
		# A pending purchase can clear, or a purchase can be made on another
		# device, while this app is in the background. Play's guidance is to
		# query purchases on resume, and this is the only place that happens.
		Store.on_resume()
		_apply_safe_area()
		_layout_hud()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.save_game(Sim)
		Analytics.end_session(Sim.depth)
		get_tree().quit()


func _process(delta: float) -> void:
	if _undo_time > 0.0:
		_undo_time -= delta
		if _undo_time <= 0.0:
			_undo_btn.visible = false
			_undo.clear()
	if _pulsing != null and is_instance_valid(_pulsing):
		_pulse_t += delta
		var k: float = 0.5 + 0.5 * sin(_pulse_t * 4.0)
		_pulsing.modulate = Color.WHITE.lerp(Palette.ACCENT, k * 0.85)
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.visible = _toast_time > 0.0
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
	# The Foreman steps in for a few seconds and steps out again; during the
	# tutorial he stays, because the tutorial is him talking.
	if _foreman_time > 0.0 and Tutorial.is_done(Sim.tutorial_step()):
		_foreman_time -= delta
		if _foreman_time <= 0.0:
			_foreman.visible = false
	if _btn_zoom != null:
		_btn_zoom.text = "−" if iso_view.cam.zoom > iso_view.default_zoom() * 1.15 else "+"


## --- construction ----------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	iso_view = IsoView.new()
	iso_view.cell_tapped.connect(_on_cell_tapped)
	iso_view.cell_long_pressed.connect(_on_cell_long_pressed)
	iso_view.ground_tapped.connect(func():
		if iso_view.selected_cell >= 0:
			_close_sheet())
	iso_view.core_tapped.connect(_on_core_tapped)
	iso_view.machine_moved.connect(func(from_cell: int, to_cell: int):
		_push_undo({"kind": "move", "cell": to_cell, "from": from_cell})
		_maybe_advance_tutorial()
		_show_cell_info(to_cell)
		_refresh())
	add_child(iso_view)

	# Everything else sits in one full-screen layer that ignores the mouse, so
	# only the panels and buttons themselves take input and every other touch
	# falls through to the world.
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)

	_stratum_card = _build_stratum_card()
	_hud.add_child(_stratum_card)
	_resources = _build_resources()
	_hud.add_child(_resources)
	_tools = _build_tools()
	_hud.add_child(_tools)
	_actions = _build_actions()
	_hud.add_child(_actions)
	_tray = _build_tray()
	_hud.add_child(_tray)
	_build_sheet()
	_hud.add_child(_sheet)
	_descend_box = _build_descend()
	_hud.add_child(_descend_box)
	_foreman = _build_foreman()
	_hud.add_child(_foreman)

	# The standard mobile pattern: the thing that just happened, and one tap to
	# take it back, for a few seconds. Cheaper than a confirmation on every
	# placement and far cheaper than a mis-tap the player cannot reverse.
	_undo_btn = _button("Undo", Palette.PANEL_HI)
	_undo_btn.add_theme_color_override("font_color", Palette.TEXT)
	_undo_btn.visible = false
	_undo_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_undo_btn.custom_minimum_size = Vector2(140, MIN_TOUCH)
	_undo_btn.pressed.connect(_do_undo)
	_hud.add_child(_undo_btn)

	_toast = _label("", 21, Palette.TEXT)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(Palette.PANEL, 0.92)
	tsb.set_corner_radius_all(18)
	tsb.content_margin_left = 18
	tsb.content_margin_right = 18
	tsb.content_margin_top = 8
	tsb.content_margin_bottom = 8
	_toast.add_theme_stylebox_override("normal", tsb)
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_toast)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)


func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Panels are dark glass: the world shows through them a little, so the
## interface reads as laid over the world rather than cut out of it.
func _panel(col: Color = Palette.PANEL, alpha: float = 0.86) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col, alpha)
	sb.set_corner_radius_all(int(Palette.RADIUS) + 4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_width_top = 2
	sb.border_width_bottom = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_color = Color(Palette.ACCENT, 0.30)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


func _button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(0, 64)   # a comfortable thumb target
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		if state == "disabled":
			sb.bg_color = col.lerp(Palette.PANEL, 0.62)
		elif state == "pressed":
			sb.bg_color = col.darkened(0.18)
		elif state == "hover":
			sb.bg_color = col.lightened(0.08)
		sb.set_corner_radius_all(int(Palette.RADIUS) + 2)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		# A lit top edge and a shadow beneath: the cheapest way to make a flat
		# rectangle read as a physical key under the same light as the board.
		sb.border_width_top = 2
		sb.border_color = sb.bg_color.lerp(Color.WHITE, 0.30)
		if state != "pressed":
			sb.shadow_color = Color(0, 0, 0, 0.38)
			sb.shadow_size = 5
			sb.shadow_offset = Vector2(0, 3)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Palette.BG)
	b.add_theme_color_override("font_disabled_color", Palette.TEXT_FAINT)
	return b


## A square key with a picture on it and a word under the picture.
func _icon_button(icon_name: String, caption: String, col: Color) -> Button:
	var b := _button("", col)
	b.custom_minimum_size = Vector2(ACTION_W, MIN_TOUCH)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var ic := TextureRect.new()
	ic.texture = IsoArt.icon(icon_name)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(0, 46)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(ic)
	var l := _label(caption, 13, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	b.add_child(box)
	return b


func _icon_rect(icon_name: String, px: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = IsoArt.icon(icon_name)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(px, px)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


func _build_stratum_card() -> Control:
	var p := _panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	row.add_child(_icon_rect("descend", 44))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.custom_minimum_size = Vector2(212, 0)
	row.add_child(col)
	var top := HBoxContainer.new()
	_lbl_depth = _label("Stratum 0", 20, Palette.TEXT)
	_lbl_depth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_lbl_depth)
	_lbl_band = _label("", 14, Palette.CORE)
	top.add_child(_lbl_band)
	col.add_child(top)
	_quota_bar = ProgressBar.new()
	_quota_bar.show_percentage = false
	_quota_bar.custom_minimum_size = Vector2(0, 8)
	_quota_bar.min_value = 0.0
	_quota_bar.max_value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.ACCENT
	fill.set_corner_radius_all(5)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(Palette.BG, 0.8)
	back.set_corner_radius_all(5)
	_quota_bar.add_theme_stylebox_override("fill", fill)
	_quota_bar.add_theme_stylebox_override("background", back)
	_quota_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_quota_bar)
	_lbl_quota = _label("", 13, Palette.TEXT_DIM)
	col.add_child(_lbl_quota)
	_lbl_mods = _label("", 13, Palette.WARN)
	_lbl_mods.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_mods.custom_minimum_size = Vector2(212, 0)
	col.add_child(_lbl_mods)
	return p


func _pill(icon_name: String, value: Label, sub: Label = null) -> Control:
	var p := _panel(Palette.PANEL, 0.82)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	p.add_child(row)
	row.add_child(_icon_rect(icon_name, 34))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(value)
	if sub != null:
		col.add_child(sub)
	row.add_child(col)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _build_resources() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_credits = _label("0", 24, Palette.CORE)
	_lbl_rate = _label("0 /s", 13, Palette.TEXT_DIM)
	var money := _pill("credits", _lbl_credits, _lbl_rate)
	money.custom_minimum_size = Vector2(146, 0)
	row.add_child(money)
	_lbl_research = _label("0", 20, Palette.RESEARCH)
	_pill_research = _pill("research", _lbl_research)
	row.add_child(_pill_research)
	_lbl_cores = _label("0", 20, Palette.CORE)
	_pill_cores = _pill("cores", _lbl_cores)
	row.add_child(_pill_cores)
	var menu := _button("", Palette.PANEL_HI)
	menu.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_END
	var ic := _icon_rect("settings", 42)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(ic)
	menu.pressed.connect(_show_settings)
	row.add_child(menu)
	return row


func _build_tools() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_btn_heat = _button("", Palette.PANEL_HI)
	_btn_heat.toggle_mode = true
	_btn_heat.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	var hic := _icon_rect("heat", 46)
	hic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_btn_heat.add_child(hic)
	_btn_heat.tooltip_text = "Heat view"
	_btn_heat.toggled.connect(func(on: bool):
		iso_view.set_overlay(IsoView.Overlay.HEAT if on else IsoView.Overlay.NONE)
		if on:
			Sim.tutorial_saw_heat = true
			_maybe_advance_tutorial()
		Juice.tap())
	col.add_child(_btn_heat)

	# One key: in to the middle of the screen, or back out to the whole
	# factory. The pinch and the wheel do everything in between.
	_btn_zoom = _button("+", Palette.PANEL_HI)
	_btn_zoom.add_theme_font_size_override("font_size", 34)
	_btn_zoom.add_theme_color_override("font_color", Palette.TEXT)
	_btn_zoom.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	_btn_zoom.tooltip_text = "Zoom"
	_btn_zoom.pressed.connect(func():
		Juice.tap()
		if iso_view.cam.zoom > iso_view.default_zoom() * 1.15:
			iso_view.cam.focus(iso_view.frame_rect().get_center()
				- (iso_view.free_rect.get_center() - iso_view.size * 0.5)
				/ iso_view.default_zoom(), iso_view.default_zoom())
		else:
			iso_view.cam.zoom_toward(1.6, iso_view.free_rect.get_center()))
	col.add_child(_btn_zoom)

	# Every stalled or overheating machine, worst first, one tap each; the
	# camera glides to it. The count is on the key.
	_btn_problems = _button("", Palette.PANEL_HI)
	_btn_problems.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	var wic := _icon_rect("warning", 42)
	wic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_btn_problems.add_child(wic)
	_lbl_problem_count = _label("", 16, Palette.TEXT)
	_lbl_problem_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_problem_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_lbl_problem_count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lbl_problem_count.offset_right = -6
	_lbl_problem_count.offset_bottom = -2
	_lbl_problem_count.add_theme_constant_override("outline_size", 6)
	_lbl_problem_count.add_theme_color_override("font_outline_color", Palette.BG)
	_btn_problems.add_child(_lbl_problem_count)
	_btn_problems.tooltip_text = "Problems"
	_btn_problems.pressed.connect(_cycle_problem)
	col.add_child(_btn_problems)
	return col


func _build_actions() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_research = _icon_button("research", "Research", Palette.PANEL_HI)
	_btn_research.pressed.connect(_show_research)
	row.add_child(_btn_research)
	_btn_collapse = _icon_button("cores", "Collapse", Palette.PANEL_HI)
	_btn_collapse.pressed.connect(_show_collapse)
	row.add_child(_btn_collapse)
	# The Codex is one tap from the board because its whole job is to be
	# reachable at the moment a player is confused.
	var codex := _icon_button("codex", "Codex", Palette.PANEL_HI)
	codex.pressed.connect(_open_codex)
	row.add_child(codex)
	return row


func _build_tray() -> Control:
	var p := _panel(Palette.PANEL, 0.80)
	var scroll := ScrollContainer.new()
	# Drag to scroll a long tray; no bar, which would make the tray taller.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(scroll)
	_palette_row = HBoxContainer.new()
	_palette_row.add_theme_constant_override("separation", 6)
	scroll.add_child(_palette_row)
	return p


func _build_descend() -> Control:
	_btn_descend = _button("", Palette.WARN)
	_btn_descend.custom_minimum_size = Vector2(DESCEND_W, BOTTOM_H)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon_rect("descend", 56))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", -2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_label("DESCEND", 22, Palette.BG))
	_lbl_descend_sub = _label("", 14, Color(Palette.BG, 0.8))
	col.add_child(_lbl_descend_sub)
	row.add_child(col)
	_btn_descend.add_child(row)
	_btn_descend.pressed.connect(_on_descend)
	return _btn_descend


func _build_foreman() -> Control:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_theme_constant_override("separation", 4)
	var badge := Foreman.Badge.new(Foreman.Pose.IDLE, 150.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_END
	box.add_child(badge)
	var bubble := _panel(Palette.PANEL_HI, 0.94)
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_foreman_label = _label("", 17, Palette.TEXT)
	_foreman_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_foreman_label.custom_minimum_size = Vector2(230, 0)
	bubble.add_child(_foreman_label)
	box.add_child(bubble)
	box.visible = false
	# Tapping him sends him away. He is never in the way for longer than the
	# player wants him there.
	box.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_foreman_time = 0.0
			box.visible = false)
	return box


## The Foreman says one short thing, with a pose, for a few seconds.
func _say(text: String, pose: int = Foreman.Pose.POINT, seconds: float = 4.0) -> void:
	_foreman_label.text = text
	var badge: Foreman.Badge = _foreman.get_child(0)
	badge.pose = pose
	_foreman_pose = pose
	_foreman.visible = true
	_foreman_time = seconds
	_layout_hud()


## Where the safe area is, from the display: the notch, the rounded corners
## and the gesture bar, in canvas units.
func _apply_safe_area() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var win: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	if win.x <= 0.0 or safe.size.x <= 0.0:
		return
	var k: Vector2 = size / win
	var pos: Vector2 = Vector2(DisplayServer.window_get_position())
	var l: float = maxf(safe.position.x - pos.x, 0.0) * k.x
	var t: float = maxf(safe.position.y - pos.y, 0.0) * k.y
	var r: float = maxf(pos.x + win.x - safe.end.x, 0.0) * k.x
	var b: float = maxf(pos.y + win.y - safe.end.y, 0.0) * k.y
	set_safe_insets(Vector4(l, t, r, b))


func set_safe_insets(insets: Vector4) -> void:
	_safe = insets
	_layout_hud()


## Every piece of the interface placed by hand from the canvas size. Anchored
## containers would do most of this, but the tests need the rectangles to be
## the ones on screen, and the camera needs the free space between them.
func _layout_hud() -> void:
	if _hud == null:
		return
	var S: Vector2 = size
	if S.x < 8.0:
		return
	var l: float = _safe.x + M
	var t: float = _safe.y + M
	var r: float = S.x - _safe.z - M
	var b: float = S.y - _safe.w - M

	_place(_stratum_card, Vector2(l, t))
	var rs: Vector2 = _resources.get_combined_minimum_size()
	_place(_resources, Vector2(r - rs.x, t))
	var ts: Vector2 = _tools.get_combined_minimum_size()
	_place(_tools, Vector2(r - ts.x, maxf(t + TOP_H + 12.0, (S.y - ts.y) * 0.5 - 30.0)))
	var as_: Vector2 = _actions.get_combined_minimum_size()
	_place(_actions, Vector2(l, b - as_.y))
	_place(_descend_box, Vector2(r - DESCEND_W, b - BOTTOM_H))
	var tray_l: float = l + as_.x + 12.0
	var tray_r: float = r - DESCEND_W - 12.0
	# As wide as the machines in it, not the whole bar: three machines are a
	# short tray, and the world shows either side of it.
	var tray_w: float = _palette_row.get_combined_minimum_size().x + 26.0
	_tray.position = Vector2(tray_l, b - BOTTOM_H)
	_tray.size = Vector2(clampf(tray_w, 120.0, maxf(tray_r - tray_l, 120.0)), BOTTOM_H)
	var sheet_h: float = BOTTOM_H + 70.0
	_sheet.position = Vector2(tray_l, b - sheet_h)
	_sheet.size = Vector2(maxf(tray_r - tray_l, 120.0), sheet_h)
	_undo_btn.size = _undo_btn.get_combined_minimum_size()
	_undo_btn.position = Vector2(tray_r - _undo_btn.size.x, b - sheet_h - _undo_btn.size.y - 8.0)
	var fs: Vector2 = _foreman.get_combined_minimum_size()
	_place(_foreman, Vector2(l, b - as_.y - 12.0 - fs.y))
	_toast.size = _toast.get_combined_minimum_size()
	_toast.position = Vector2((S.x - _toast.size.x) * 0.5, b - sheet_h - _toast.size.y - 12.0)

	# What is left for the world: between the top corners' panels and the
	# bottom bar, clear of the right-hand tools.
	var free := Rect2(Vector2(l + 8.0, t), Vector2(r - ts.x - 12.0 - (l + 8.0),
		b - BOTTOM_H - 10.0 - t))
	var had: Rect2 = iso_view.free_rect
	iso_view.free_rect = free
	var avoid: Array[Rect2] = []
	var hr: Dictionary = hud_rects()
	for k: String in hr:
		avoid.append(hr[k])
	iso_view.avoid_rects = avoid
	if had.size == Vector2.ZERO or not had.is_equal_approx(free):
		iso_view.frame_board()


func _place(c: Control, at: Vector2) -> void:
	c.size = c.get_combined_minimum_size()
	c.position = at


## Where each part of the interface is on screen, for the layout tests.
func hud_rects() -> Dictionary:
	var out: Dictionary = {
		"stratum": _stratum_card.get_rect(),
		"resources": _resources.get_rect(),
		"tools": _tools.get_rect(),
		"actions": _actions.get_rect(),
		"tray": _tray.get_rect(),
		"descend": _descend_box.get_rect(),
	}
	return out


## The keys a finger has to hit, for the touch-target test.
func hud_buttons() -> Array[Button]:
	var out: Array[Button] = [_btn_heat, _btn_zoom, _btn_problems, _btn_descend]
	for c in _actions.get_children():
		out.append(c as Button)
	for k: String in _palette_buttons:
		out.append(_palette_buttons[k] as Button)
	return out


## The detail panel takes the tray's place while a machine is selected: the
## information about a machine appears where the machines came from, below
## the board, never over it and never under the finger pointing at it.
func _build_sheet() -> void:
	_sheet = _panel(Palette.PANEL_HI, 0.94)
	_sheet.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_sheet.add_child(row)

	_sheet_art = MachineSprite.new("", 130.0)
	row.add_child(_sheet_art)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	var head := HBoxContainer.new()
	_sheet_title = _label("", 22, Palette.TEXT)
	_sheet_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_sheet_title)
	left.add_child(head)
	_sheet_body = VBoxContainer.new()
	_sheet_body.add_theme_constant_override("separation", 2)
	left.add_child(_sheet_body)
	row.add_child(left)

	_sheet_stats = VBoxContainer.new()
	_sheet_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_stats.add_theme_constant_override("separation", 1)
	row.add_child(_sheet_stats)

	var close := _button("✕", Palette.PANEL)
	close.add_theme_color_override("font_color", Palette.TEXT)
	close.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(_close_sheet)
	row.add_child(close)


func _close_sheet() -> void:
	_sheet.visible = false
	_tray.visible = true
	iso_view.selected_cell = -1


## Step through whatever is wrong, worst first. One button, one tap per
## problem, the camera glides to it -- which is as close as a board this size
## needs to get to a diagnostics tool.
func _cycle_problem() -> void:
	var cells: Array[int] = Sim.sim.problem_cells()
	if cells.is_empty():
		_toast_msg("Nothing is stalled or overheating.")
		return
	_problem_cursor = (_problem_cursor + 1) % cells.size()
	var cell: int = cells[_problem_cursor]
	iso_view.selected_cell = cell
	iso_view.pulse(cell)
	iso_view.focus_cell(cell)
	_show_cell_info(cell)
	Juice.tap()


func _rebuild_palette() -> void:
	for c in _palette_row.get_children():
		c.queue_free()
	_palette_buttons.clear()
	_palette_costs.clear()
	for id in MachineDB.ORDER:
		if not Sim.is_unlocked(id):
			continue
		_palette_row.add_child(_make_palette_button(id))


## A Control that draws one machine exactly as the board draws it: the same
## sprite from the same sheet, so what you pick is what you get.
class MachineSprite extends Control:
	var id: String = ""
	var bob: bool = false
	var _t: float = 0.0

	func _init(machine_id: String = "", px: float = 64.0, animate: bool = false) -> void:
		id = machine_id
		bob = animate
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _process(delta: float) -> void:
		if bob:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		if id == "" or size.x < 4.0:
			return
		var sheet: Dictionary = IsoArt.sheet(IsoArt.sheet_name(Store.active_theme(),
			Sim.upgrade_marks()))
		var r := Rect2(Vector2.ZERO, size)
		if bob:
			# A pool of its own light behind it, so it arrives lit.
			var g: Color = Palette.machine_light(id)
			g.a = 0.35 + 0.1 * sin(_t * 3.0)
			draw_texture_rect(IsoArt.glow(), r.grow(-size.x * 0.05), false, g)
			r.position.y += sin(_t * 2.0) * size.y * 0.015
		IsoArt.draw_machine_fit(self, r, id, sheet)


func _make_palette_button(id: String) -> Control:
	var m: Dictionary = MachineDB.get_machine(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(98, MIN_TOUCH)
	b.toggle_mode = true
	b.tooltip_text = "%s\n%s\n%s" % [m["name"],
		MachineDB.recipe_text(id), m["desc"]]
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Palette.PANEL_HI, 0.9) if state != "pressed" else \
			Palette.machine_color(id).lerp(Palette.PANEL_HI, 0.55)
		if state == "disabled":
			sb.bg_color = Palette.PANEL
		sb.set_corner_radius_all(int(Palette.RADIUS))
		sb.content_margin_left = 2
		sb.content_margin_right = 2
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2 if state == "pressed" else 0
		sb.border_color = Palette.machine_light(id) if state == "pressed" \
			else sb.bg_color.lerp(Palette.KEY_TINT, 0.16)
		b.add_theme_stylebox_override(state, sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var chip := MachineSprite.new(id, 58.0)
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(chip)
	var name_lbl: Label = _label(String(m["name"]), 13, Palette.TEXT)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	col.add_child(name_lbl)
	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 2)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(_icon_rect("credits", 18))
	var cost_lbl: Label = _label(Economy.fmt(Sim.cost_of(id)), 14, Palette.CORE)
	cost_row.add_child(cost_lbl)
	col.add_child(cost_row)
	b.add_child(col)

	b.pressed.connect(func(): _arm(id))
	_palette_buttons[id] = b
	_palette_costs[id] = cost_lbl
	return b


## --- interaction -----------------------------------------------------------

func _arm(id: String) -> void:
	Juice.tap()
	_armed = "" if _armed == id else id
	iso_view.arm_id = _armed
	for k: String in _palette_buttons:
		_palette_buttons[k].button_pressed = (k == _armed)


func _on_cell_tapped(cell: int) -> void:
	if Sim.is_blocked(cell):
		Juice.blocked()
		_toast_msg("This part of the shaft has collapsed.")
		return
	if Sim.grid.is_empty(cell):
		if iso_view.selected_cell >= 0:
			_close_sheet()
		if not Sim.is_open(cell):
			Juice.reject()
			_toast_msg("The yard reaches this ground at stratum %d."
				% BuildArea.opens_at(cell))
			return
		if _armed == "":
			_toast_msg("Pick a machine below, then tap a tile.")
			return
		if not Sim.can_afford(_armed):
			Juice.reject()
			_toast_msg("Not enough credits for a %s." % MachineDB.get_machine(_armed)["name"])
			return
		var price: float = Sim.cost_of(_armed)
		if Sim.try_place(cell, _armed):
			Juice.place()
			iso_view.pulse(cell)
			_push_undo({"kind": "place", "cell": cell, "id": _armed,
				"price": price})
			_shown_credits = Sim.credits
			_refresh()
			_maybe_advance_tutorial()
		return
	iso_view.selected_cell = -1 if iso_view.selected_cell == cell else cell
	if iso_view.selected_cell >= 0:
		Juice.tap()
		_show_cell_info(cell)
	else:
		_close_sheet()


func _on_cell_long_pressed(cell: int) -> void:
	if Sim.grid.is_empty(cell):
		return
	var id: String = Sim.grid.machine_at(cell)
	var refund: float = MachineDB.cost_for(id, maxi(Sim.grid.count_of(id) - 1, 0)) * 0.75
	_confirm("Remove %s?" % MachineDB.get_machine(id)["name"],
		"You get %s credits back." % Economy.fmt(refund),
		"Remove", func():
			Sim.sell(cell)
			_push_undo({"kind": "sell", "cell": cell, "id": id,
				"refund": refund})
			Juice.sell()
			_close_sheet()
			_shown_credits = Sim.credits
			_refresh())


func _on_descend() -> void:
	if not Sim.can_descend():
		Juice.reject()
		_toast_msg("Reach %s credits to descend." % Economy.fmt(Sim.quota()))
		return
	if Sim.descend():
		_undo.clear()
		_maybe_advance_tutorial()
		Juice.descend()
		Juice.punch(_stratum_card, 0.06, 0.30)
		_close_sheet()
		_shown_credits = Sim.credits
		_refresh_hint()


func _on_unlocked(ids: Array) -> void:
	if ids.is_empty():
		return
	_rebuild_palette()
	Juice.unlock()

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id: String in ids:
		row.add_child(MachineSprite.new(String(id), 170.0, true))
	body.add_child(row)
	for id2: String in ids:
		var m: Dictionary = MachineDB.get_machine(id2)
		body.add_child(_label(String(m["name"]), 24,
			Palette.machine_light(String(id2))))
		body.add_child(_wrap_label(MachineDB.recipe_text(String(id2))))
		body.add_child(_wrap_label(String(m["desc"])))
	body.add_child(HSeparator.new())
	var hint := HBoxContainer.new()
	hint.add_theme_constant_override("separation", 12)
	var badge := Foreman.Badge.new(Foreman.Pose.CHEER, 96.0)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hint.add_child(badge)
	var hint_lbl: Label = _wrap_label(
		"It is in the tray at the bottom. What it is next to matters more "
		+ "than how many you own.")
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.add_child(hint_lbl)
	body.add_child(hint)
	_open_overlay("New machine unlocked", body, [])


func _on_collapsed(gained: int) -> void:
	_rebuild_palette()
	_close_sheet()
	_shown_credits = Sim.credits
	Juice.collapse()
	# Framed as what is kept, never as what is lost, and never as a "reset".
	# The genre's most cited progression failure is a prestige that reads as
	# punishment, and the wording is half of that.
	_refresh_hint()
	_info("The shaft collapses",
		"You brought up %d Cores.\n\nCores are the only thing that survives a collapse — and everything you spend them on survives with them. The next shaft goes deeper and faster than this one did." % gained)


func _on_reward(placement: String) -> void:
	match placement:
		Ads.P_DOUBLE_OFFLINE:
			var extra: float = Save.apply_offline_double(Sim)
			Juice.reward()
			_shown_credits = Sim.credits - extra
			_toast_msg("+%s credits." % Economy.fmt(extra))
			_refresh()
		_:
			_toast_msg("Reward granted.")


## An ad that does not play is not the player's problem, and it is not worth a
## modal. The base offline payout was already credited before the ad was ever
## offered, so nothing is lost here -- only the doubling.
func _on_reward_failed(_placement: String, reason: String) -> void:
	match reason:
		"dismissed":
			pass  # They closed it deliberately. Saying anything is nagging.
		"timeout", "show_failed":
			_toast_msg("The ad did not play. Nothing was lost.")
		_:
			_toast_msg("No ad available right now.")


## --- refresh ---------------------------------------------------------------

const BAND_NAMES := ["The Surface", "The Workings", "The Deep", "The Abyss"]


func _refresh() -> void:
	# The headline figure counts up rather than snapping. In a game whose
	# whole feedback loop is a number going up, a number that jumps reads as
	# a variable being assigned and a number that rolls reads as income.
	if absf(Sim.credits - _shown_credits) > 0.5:
		Juice.roll(_lbl_credits, _shown_credits, Sim.credits,
			func(v: float) -> String: return Economy.fmt(v))
		_shown_credits = Sim.credits
	elif _lbl_credits.text == "":
		_lbl_credits.text = Economy.fmt(Sim.credits)
	_lbl_rate.text = "+%s /s" % Economy.fmt(Sim.credits_per_sec)
	_lbl_research.text = Economy.fmt(Sim.research)
	_lbl_cores.text = str(Sim.cores)
	_show_what_matters()

	var s: Dictionary = Sim.stratum()
	_lbl_depth.text = "Stratum %d" % Sim.depth
	_lbl_band.text = BAND_NAMES[int(Palette.band_at(Sim.depth)[0])]
	var q: float = Sim.quota()
	_quota_bar.value = clampf(Sim.credits / q, 0.0, 1.0) if q > 0.0 else 0.0
	_lbl_quota.text = "descend at %s" % Economy.fmt(q)
	var mods: Array = s.get("modifiers", [])
	if mods.is_empty():
		_lbl_mods.text = ""
		_lbl_mods.visible = false
	else:
		# Names only: what each one does is a tap away in the Codex, and a
		# paragraph per modifier in the corner of the screen is a wall of text.
		var parts: Array = []
		for id in mods:
			parts.append(Strata.modifier_name(id))
		_lbl_mods.text = " · ".join(parts)
		_lbl_mods.tooltip_text = "\n".join(mods.map(func(id): return "%s — %s" % [
			Strata.modifier_name(id), Strata.modifier_desc(id)]))
		_lbl_mods.visible = true

	_refresh_problems()

	_btn_descend.disabled = not Sim.can_descend()
	_lbl_descend_sub.text = "to stratum %d" % (Sim.depth + 1) if Sim.can_descend() \
		else "%d%% of quota" % int(round(_quota_bar.value * 100.0))
	for id: String in _palette_buttons:
		var afford: bool = Sim.can_afford(id)
		var cost: Label = _palette_costs.get(id, null)
		if cost != null:
			cost.text = Economy.fmt(Sim.cost_of(id))
			cost.add_theme_color_override("font_color",
				Palette.CORE if afford else Palette.TEXT_FAINT)
		# The whole card dims when it is out of reach, so "can I afford this"
		# is answered by the brightness of the picture rather than by reading
		# a number and comparing it with another number.
		(_palette_buttons[id] as Button).modulate = Color(1, 1, 1,
			1.0 if afford else 0.45)
	if _stratum_card != null:
		_layout_hud()


## The interface a player has grown into. A new game shows the Stratum,
## credits, the settings key, the zoom key, the Codex, the tray and Descend;
## research, Cores, the collapse, the heat view and the problem list appear
## the first time they mean something, and stay.
func _show_what_matters() -> void:
	var veteran: bool = Sim.collapses > 0
	var research: bool = veteran or Sim.research > 0.0 or Sim.is_unlocked("lab") \
		or not Sim.upgrade_levels.is_empty()
	var cores: bool = veteran or Sim.cores > 0 or Economy.can_collapse(Sim.max_depth)
	var step: int = Sim.tutorial_step()
	var heat: bool = veteran or Tutorial.is_done(step) or step >= Tutorial.index_of("see_heat") \
		or Sim.tutorial_saw_heat
	_pill_research.visible = research
	_btn_research.visible = research
	_pill_cores.visible = cores
	_btn_collapse.visible = cores
	_btn_heat.visible = heat
	_btn_problems.visible = veteran or not Sim.grid.cells.is_empty()


## --- undo ------------------------------------------------------------------

## How long the offer stands. Long enough to notice a mistake, short enough
## that the button is not part of the furniture.
const UNDO_SECONDS := 6.0


func _push_undo(entry: Dictionary) -> void:
	_undo = [entry]
	_undo_btn.visible = true
	_undo_time = UNDO_SECONDS


func _do_undo() -> void:
	if _undo.is_empty():
		return
	var e: Dictionary = _undo.pop_back()
	_undo_btn.visible = false
	_undo_time = 0.0
	var ok: bool = false
	match String(e["kind"]):
		"place":
			ok = Sim.undo_place(int(e["cell"]), float(e["price"]))
		"sell":
			ok = Sim.undo_sell(int(e["cell"]), String(e["id"]), float(e["refund"]))
		"move":
			ok = Sim.move_machine(int(e["cell"]), int(e["from"]))
	if ok:
		Juice.lift()
		_close_sheet()
		_shown_credits = Sim.credits
		_refresh()
	else:
		Juice.reject()
		_toast_msg("That cannot be undone now.")


## The two tutorial steps that complete by waiting rather than by tapping --
## seeing the first credits arrive, and reaching the quota -- are checked here
## rather than polled, because both are things the simulation announces.
func _tutorial_watch() -> void:
	if not Tutorial.is_done(Sim.tutorial_step()) and Sim.tutorial_satisfied():
		_maybe_advance_tutorial()
	if not _research_nudged and Sim.research > 0.0:
		_research_nudged = true
		_say(Tutorial.RESEARCH_NUDGE, Foreman.Pose.POINT, 5.0)


## The count on the Problems key, and the heat warning sound on the moment a
## machine starts overheating. Starvation first, because it stops production
## dead; then backpressure; then heat, which only costs a percentage.
func _refresh_problems() -> void:
	var c: Dictionary = Sim.sim.problem_counts()
	# Heard once when it starts, not every frame it continues. Juice throttles
	# the sound itself; this only fires on the transition.
	if int(c["thermal"]) > _last_thermal and int(c["thermal"]) > 0:
		Juice.heat_warning()
	_last_thermal = int(c["thermal"])
	var n: int = int(c["starved"]) + int(c["blocked"]) + int(c["thermal"])
	_lbl_problem_count.text = str(n) if n > 0 else ""
	# The Foreman steps in once per stratum, the first time something on the
	# board is actually in trouble -- a machine at critical heat -- and points
	# at the key that finds it. Once, so it is news rather than nagging.
	var calm: bool = Tutorial.is_done(Sim.tutorial_step()) and not _overlay.visible
	if _alerted_depth != Sim.depth and calm:
		for cell: int in Sim.grid.cells:
			if iso_view.badges.shown(cell) == StatusBadges.Show.CRITICAL:
				_alerted_depth = Sim.depth
				_say("Something is overheating. The warning key finds it.",
					Foreman.Pose.ALERT, 5.0)
				break
	var parts: Array[String] = []
	if int(c["starved"]) > 0:
		parts.append("%d starved" % int(c["starved"]))
	if int(c["blocked"]) > 0:
		parts.append("%d backed up" % int(c["blocked"]))
	if int(c["thermal"]) > 0:
		parts.append("%d off temperature" % int(c["thermal"]))
	_btn_problems.tooltip_text = "Everything is running." if parts.is_empty() \
		else "  ·  ".join(parts)
	_btn_problems.modulate = Color.WHITE if n > 0 else Color(1, 1, 1, 0.55)


## --- onboarding ------------------------------------------------------------
##
## One line at a time, from the Foreman, a pulsing outline where the answer
## is, and nothing that has to be dismissed. The steps live in `Tutorial` as
## data; this only draws them and asks, after every change to the board,
## whether the player has done the thing yet. After the last step he goes
## quiet.

func _refresh_hint() -> void:
	# A dark Core comes before everything, the chapter included: nothing can
	# be bought until it is online.
	iso_view.highlight_core = not Sim.core_online
	if not Sim.core_online:
		_say(Tutorial.CORE_LINE, Foreman.Pose.POINT, 9999.0)
		iso_view.highlight_cells = []
		_pulse_control("")
		return
	var step: int = Sim.tutorial_step()
	if Tutorial.is_done(step):
		iso_view.highlight_cells = []
		_pulse_control("")
		if _foreman_time <= 0.0:
			_foreman.visible = false
		return
	_say(Tutorial.line_for(step), Foreman.Pose.POINT, 9999.0)
	iso_view.highlight_cells = Tutorial.highlight(step, Sim)
	_pulse_control(Tutorial.highlight_control(step))
	# Arming the suggested machine for them removes a tap and a guess. They
	# can still pick anything else; nothing here is modal.
	var arm: String = Tutorial.arm_for(step)
	if arm != "" and _armed != arm and Sim.is_unlocked(arm):
		_armed = arm
		iso_view.arm_id = arm
		for k: String in _palette_buttons:
			_palette_buttons[k].button_pressed = (k == arm)


## The Factory Core. Dark, a tap brings it online and draws its reserve --
## the first thing a new game, and every shaft after a collapse, asks for.
## Online, a tap says what it is.
func _on_core_tapped() -> void:
	if Sim.power_core():
		iso_view.core_powered()
		Juice.reward()
		_shown_credits = Sim.credits - Sim.core_reserve()
		_toast_msg("The Core is online: %s credits from its reserve."
			% Economy.fmt(Sim.core_reserve()))
		if Tutorial.is_done(Sim.tutorial_step()):
			_say("Online. Build the shaft back up.", Foreman.Pose.JUMP, 3.0)
		_refresh()
		_refresh_hint()
		return
	var lvl: int = IsoView.core_level()
	var next: String = "It is as big as it gets." if lvl >= IsoView.CORE_LEVELS \
		else "Descend to take it deeper: at stratum %d it grows to level %d." % [lvl, lvl + 1]
	_info("Factory Core, level %d" % lvl, ("The heart of this shaft. It gave you the "
		+ "credits for your first Drill and Vault; everything since, the board has "
		+ "earned.\n\nStratum %d. %s Every stratum is richer rock, and new machines "
		+ "open on the way down.") % [Sim.depth, next])


## Some steps have their answer on a button rather than on the board.
func _pulse_control(which: String) -> void:
	var target: Control = null
	match which:
		"heat_button": target = _btn_heat
		"descend_button": target = _btn_descend
	for c: Control in [_btn_heat, _btn_descend]:
		if c == null:
			continue
		c.modulate = Color.WHITE
	_pulsing = target


## Called after anything that could have completed the current step.
func _maybe_advance_tutorial() -> void:
	var guard: int = 0
	while not Tutorial.is_done(Sim.tutorial_step()) \
			and Sim.tutorial_satisfied() and guard < Tutorial.count():
		guard += 1
		Sim.advance_tutorial()
		# A step completing is a small win and should feel like one.
		Juice.tap()
	_refresh_hint()


## --- overlays --------------------------------------------------------------

func _close_overlay() -> void:
	for c in _overlay.get_children():
		c.queue_free()
	_overlay.visible = false
	if iso_view != null:
		iso_view.hold_effects = false
	_tell_yard_news()


func _tell_yard_news() -> void:
	if _yard_news == "" or _overlay.visible:
		return
	_say(_yard_news, Foreman.Pose.JUMP, 4.0)
	_yard_news = ""


## A centred card over a dimmed world. Sized from the screen, and its body
## scrolls, because a landscape phone is 720 units tall and some of these
## (research, the offline report) are longer than that.
func _open_overlay(title: String, body: Control, actions: Array) -> void:
	_close_overlay()
	_overlay.visible = true
	iso_view.hold_effects = true

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
			_close_overlay())
	_overlay.add_child(dim)

	var card := _panel(Palette.PANEL, 0.97)
	var w: float = minf(820.0, size.x - 80.0)
	var h: float = minf(size.y - 48.0 - _safe.y - _safe.w, 700.0)
	card.position = Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
	card.size = Vector2(w, h)
	_overlay.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	col.add_child(_label(title, 28, Palette.TEXT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	col.add_child(scroll)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for a: Dictionary in actions:
		var b := _button(String(a["text"]), a.get("color", Palette.PANEL_HI))
		if a.has("disabled"):
			b.disabled = bool(a["disabled"])
		var cb: Variant = a.get("cb")
		b.pressed.connect(func():
			_close_overlay()
			if cb is Callable:
				cb.call())
		row.add_child(b)
	var close := _button("Close", Palette.PANEL_HI)
	close.add_theme_color_override("font_color", Palette.TEXT)
	close.pressed.connect(_close_overlay)
	row.add_child(close)
	col.add_child(row)


func _info(title: String, text: String) -> void:
	var l := _label(text, 20, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_open_overlay(title, l, [])


func _confirm(title: String, text: String, ok: String, cb: Callable) -> void:
	var l := _label(text, 20, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_open_overlay(title, l, [{"text": ok, "color": Palette.BAD, "cb": cb}])


func _toast_msg(text: String) -> void:
	_toast.text = text
	_toast_time = 2.2
	_toast.visible = true
	_toast.modulate.a = 1.0
	_layout_hud()


func _show_cell_info(cell: int) -> void:
	var id: String = Sim.grid.machine_at(cell)
	if id == "":
		_close_sheet()
		return
	var m: Dictionary = MachineDB.get_machine(id)
	var heat: float = Sim.grid.heat_at(cell)
	var eff: float = Sim.sim.heat_efficiency_at(cell)
	var delta: float = Sim.sim.heat_delta_at(cell)
	var amp: float = Sim.grid.amplify_at(cell)
	var st: int = Sim.sim.status_of(cell)

	for c in _sheet_body.get_children():
		c.queue_free()
	for c in _sheet_stats.get_children():
		c.queue_free()
	_sheet_title.text = String(m["name"])
	(_sheet_art as MachineSprite).id = id
	_sheet_art.queue_redraw()

	# The verdict first, in words, in the direction the player has to look.
	# A colour on a tile says something is wrong; this says what to do.
	var verdict: String
	var verdict_col: Color
	match st:
		Simulation.Status.STARVED:
			verdict = "Starved — it is not being fed. Look UPSTREAM."
			verdict_col = Palette.BAD
		Simulation.Status.BLOCKED:
			verdict = "Backed up — nothing takes its output. Look DOWNSTREAM."
			verdict_col = Palette.WARN
		Simulation.Status.IDLE:
			verdict = "Idle. Nothing for it to do."
			verdict_col = Palette.TEXT_FAINT
		Simulation.Status.PASSIVE:
			verdict = "Working by standing there. It has no cycle of its own."
			verdict_col = Palette.GOOD
		_:
			if eff < Simulation.THERMAL_WARNING:
				verdict = "Running, but %s: giving up %d%% of its output." % [
					"too hot" if delta > 0.0 else "too cold",
					int(round((1.0 - eff) * 100.0))]
				verdict_col = Palette.ST_HOT if delta > 0.0 else Palette.ST_COLD
			else:
				verdict = "Running well."
				verdict_col = Palette.GOOD
	var v := _label(verdict, 17, verdict_col)
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet_body.add_child(v)
	# The recipe, rendered from the table rather than written down, so the
	# panel cannot describe a machine the simulation does not have.
	var recipe: String = MachineDB.recipe_text(id)
	if recipe != "":
		var rl := _label(recipe, 15, Palette.TEXT_DIM)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_sheet_body.add_child(rl)
	var d := _label(String(m["desc"]), 14, Palette.TEXT_FAINT)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet_body.add_child(d)

	_sheet_stats.add_child(_stat_row("Temperature",
		"%.1f  (wants %.1f)" % [heat, float(m["heat_optimum"])]))
	_sheet_stats.add_child(_stat_row("Thermal output",
		"%d%%" % int(round(eff * 100.0))))
	# Duty cycle, not items per second. It is comparable between machine
	# types, it needs no unit, and it answers what the player is asking:
	# is this tile earning its square.
	_sheet_stats.add_child(_stat_row("Working",
		"%d%% of the time" % int(round(Sim.sim.uptime_of(cell) * 100.0))))
	if amp > 1.001:
		_sheet_stats.add_child(_stat_row("Neighbour boost",
			"+%.0f%%" % ((amp - 1.0) * 100.0)))
	# Labelled as a capability, not as output. A machine that is backed up can
	# be quick and still be doing nothing.
	_sheet_stats.add_child(_stat_row("Cycle speed when fed",
		"%.2f /s" % Sim.sim.effective_rate(cell)))

	_tray.visible = false
	_sheet.visible = true


func _stat_row(name: String, value: String) -> Control:
	var row := HBoxContainer.new()
	var a := _label(name, 15, Palette.TEXT_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	row.add_child(_label(value, 15, Palette.TEXT))
	return row


func _show_research() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	for id in Economy.TREE_ORDER:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		var lvl: int = Sim.upgrade_level(id)
		var maxed: bool = lvl >= int(u["max"])
		var c: Dictionary = Economy.upgrade_cost(id, lvl)

		var row := _panel(Palette.PANEL_HI)
		var rc := HBoxContainer.new()
		rc.add_theme_constant_override("separation", 12)
		row.add_child(rc)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(_label("%s   %d/%d" % [u["name"], lvl, int(u["max"])], 20, Palette.TEXT))
		var dl := _label(String(u["desc"]), 16, Palette.TEXT_DIM)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(dl)
		rc.add_child(text)

		if maxed:
			rc.add_child(_label("Fully researched", 17, Palette.GOOD))
		else:
			var cost_text: String = "%s research" % Economy.fmt(float(c["research"]))
			if int(c["cores"]) > 0:
				cost_text += "  +  %d cores" % int(c["cores"])
			var b := _button(cost_text, Palette.RESEARCH)
			b.size_flags_horizontal = Control.SIZE_SHRINK_END
			b.custom_minimum_size = Vector2(250, 60)
			b.add_theme_font_size_override("font_size", 18)
			b.disabled = not Sim.can_buy_upgrade(id)
			b.pressed.connect(func():
				if Sim.buy_upgrade(id):
					Juice.upgrade()
					_close_overlay()
					_show_research()
					_refresh())
			rc.add_child(b)
		col.add_child(row)

	_open_overlay("Research", col, [])


func _show_collapse() -> void:
	var gained: int = Sim.pending_cores()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	if not Economy.can_collapse(Sim.max_depth):
		body.add_child(_wrap_label(
			"Collapsing the shaft converts everything you have built into Cores, which survive into the next run.\n\nYou need to reach stratum %d first. You are at %d."
			% [Economy.COLLAPSE_MIN_DEPTH, Sim.max_depth]))
		_open_overlay("Collapse", body, [])
		return
	body.add_child(_wrap_label(
		"You recover %d Cores.\n\nGone: the board, your credits, your research, your depth.\nKept: Cores, everything you have researched permanently, and your blueprints.\n\nDeeper runs and larger lifetime earnings both raise the payout, with diminishing returns on earnings — so pushing one more stratum is usually worth more than grinding one more hour."
		% gained))
	_open_overlay("Collapse the shaft", body,
		[{"text": "Collapse for %d" % gained, "color": Palette.CORE,
			"cb": func(): Sim.collapse()}])


func _wrap_label(text: String) -> Label:
	var l := _label(text, 19, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _show_offline(report: Dictionary) -> void:
	var amount: float = float(report.get("amount", 0.0))
	if amount <= 0.0:
		return
	var away: String = Economy.fmt_duration(float(report.get("seconds_away", 0.0)))
	var counted: String = Economy.fmt_duration(float(report.get("seconds_counted", 0.0)))
	var rate_pct: int = int(round(float(report.get("rate", 0.45)) * 100.0))

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var off_badge := Foreman.Badge.new(Foreman.Pose.CHEER, 110.0)
	off_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(off_badge)
	var sum_col := VBoxContainer.new()
	sum_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sum_col.add_child(_label("+%s credits" % Economy.fmt(amount), 34,
		Palette.CORE))
	sum_col.add_child(_label("The shaft kept running.", 16, Palette.TEXT_DIM))
	head.add_child(sum_col)
	body.add_child(head)
	var detail: String = "Away %s. Counted %s at %d%% of your live rate." % [away, counted, rate_pct]
	if bool(report.get("capped", false)):
		detail += "\n\nYour offline banking is full at %.0f hours. Night Shift in Research raises it." % Sim.offline_hours()
	body.add_child(_wrap_label(detail))

	var actions: Array = []
	if Ads.can_offer(Ads.P_DOUBLE_OFFLINE):
		actions.append({
			"text": "Watch an ad to double it",
			"color": Palette.GOOD,
			"cb": func(): Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE),
		})

	# The one offer that belongs here, and the reason it does: this panel has
	# just printed the exact credits banked, the hours counted and the cap
	# that limited them. The player is looking at the number before anything
	# is offered, which is the only condition under which offering is honest.
	# It is a line of text and a secondary button below the claim -- never a
	# gate, never a modal of its own, and the panel closes without it.
	if MonetizationDB.allowed_at(MonetizationDB.LICENCE, "offline_panel") \
			and not Store.owns(MonetizationDB.LICENCE) \
			and not Store.is_pending(MonetizationDB.LICENCE) \
			and Store.can_purchase(MonetizationDB.LICENCE) \
			and bool(report.get("capped", false)):
		# Only when the cap actually bit. Offering more offline hours to
		# somebody whose hours were not capped is selling them nothing.
		body.add_child(HSeparator.new())
		body.add_child(_wrap_label(
			"The Foreman's Licence banks %.0f hours instead of %.0f, permanently, and removes ads."
			% [Sim.offline_hours() + float(MonetizationDB.grant_value(
				MonetizationDB.LICENCE, MonetizationDB.GRANT_OFFLINE_HOURS, 0.0)),
				Sim.offline_hours()]))
		actions.append({
			"text": "Supply Office",
			"color": Palette.PANEL_HI,
			"cb": func(): _open_shop(),
		})

	_open_overlay("While you were away", body, actions)


func _show_settings() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	# The shop is one line in settings and one offer on the offline panel, and
	# it is reached from nowhere else. `MonetizationDB.PLACEMENTS` is the list
	# and `FORBIDDEN_PLACEMENTS` is what this game refuses to have.
	var owned: Array[String] = []
	for k: String in MonetizationDB.keys():
		if Store.owns(k):
			owned.append(MonetizationDB.title_of(k))
	var shop := _button("Supply Office", Palette.PANEL_HI)
	shop.add_theme_color_override("font_color", Palette.TEXT)
	shop.pressed.connect(func():
		_close_overlay()
		_open_shop())
	col.add_child(shop)
	if owned.is_empty():
		col.add_child(_label(
			"Two one-time purchases. Neither unlocks a machine, a stratum or an upgrade.",
			15, Palette.TEXT_FAINT))
	else:
		col.add_child(_label("Active: %s. Thank you." % ", ".join(owned), 15,
			Palette.GOOD))

	col.add_child(HSeparator.new())

	var snd := CheckBox.new()
	snd.text = "Sound"
	snd.button_pressed = bool(Sim.settings.get("sound", true))
	snd.add_theme_font_size_override("font_size", 20)
	snd.toggled.connect(func(on):
		Sim.settings["sound"] = on
		Juice.set_sound(on)
		Save.save_game(Sim))
	col.add_child(snd)

	var haptics := CheckBox.new()
	haptics.text = "Haptics"
	haptics.button_pressed = bool(Sim.settings.get("haptics", true))
	haptics.add_theme_font_size_override("font_size", 20)
	haptics.toggled.connect(func(on):
		Sim.settings["haptics"] = on
		Juice.haptics_enabled = on
		Save.save_game(Sim))
	col.add_child(haptics)

	var anon := CheckBox.new()
	anon.text = "Anonymous gameplay statistics"
	anon.button_pressed = Analytics.enabled
	anon.add_theme_font_size_override("font_size", 20)
	anon.toggled.connect(func(on): Analytics.set_enabled(on))
	col.add_child(anon)
	var an := _label(
		"No account, no advertising ID, no personal data. %d event types only: sessions, depth reached, tutorial and first-production milestones, ads watched and purchases."
		% Analytics.ALLOWED.size(),
		15, Palette.TEXT_FAINT)
	an.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(an)

	# GDPR requires consent to be withdrawable, not just grantable. The ad
	# SDK owns that form; this is the entry point into it, and it is the step
	# most implementations leave out.
	if Ads.is_plugin_present():
		var privacy := _button("Ad privacy options", Palette.PANEL_HI)
		privacy.add_theme_color_override("font_color", Palette.TEXT)
		privacy.pressed.connect(func():
			if not Ads.show_privacy_options():
				_toast_msg("The ad SDK did not offer a privacy form."))
		col.add_child(privacy)

	col.add_child(HSeparator.new())

	var codex_btn := _button("Codex", Palette.PANEL_HI)
	codex_btn.add_theme_color_override("font_color", Palette.TEXT)
	codex_btn.pressed.connect(func():
		_close_overlay()
		_open_codex())
	col.add_child(codex_btn)
	col.add_child(_label(
		"Short pages with small boards that are actually running.",
		15, Palette.TEXT_FAINT))

	col.add_child(HSeparator.new())

	var diag := _button("Run device self test", Palette.PANEL_HI)
	diag.add_theme_color_override("font_color", Palette.TEXT)
	diag.pressed.connect(func():
		_close_overlay()
		_open_diagnostics())
	col.add_child(diag)
	col.add_child(_label(
		"Frame time, screen shape, save integrity and plugin status, measured on this device.",
		15, Palette.TEXT_FAINT))

	_open_overlay("Lodeworks", col, [])


func _open_shop() -> void:
	Juice.tap()
	var sh: Control = (load("res://scripts/ui/shop.gd") as GDScript).new()
	add_child(sh)


func _open_codex() -> void:
	Juice.tap()
	var c: Control = (load("res://scripts/ui/codex.gd") as GDScript).new()
	add_child(c)


func _open_diagnostics() -> void:
	var d: Control = (load("res://scripts/ui/diagnostics.gd") as GDScript).new()
	add_child(d)
