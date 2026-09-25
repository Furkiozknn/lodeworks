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
## The smallest text on the interface, in canvas units: 9.6 dp on the
## reference 18:9 phone, 7.8 before. tools/layout_check.gd fails on any
## shown text under it.
const TEXT_MIN := 16
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
var _research_badge: Label
## The text size the labels on screen were last sized for.
var _large_text_now: bool = false
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
## The Problems key's light, the count it last showed, and where its swell is.
var _problem_glow: TextureRect
## The heat key's picture and light, the state it shows (see
## `StatusBadges.heat_state`) and where its flicker is.
var _descend_seen_closed: bool = false
var _halo_beat: int = 0
var _heat_icon: TextureRect
var _heat_glow: TextureRect
var _heat_state: int = 0
var _heat_beat: int = 0
var _heat_t: float = 0.0
var _problem_n: int = 0
var _alarm_t: float = 0.0
var _btn_heat: Button
var _btn_zoom: Button
## "What now?": the Worklist, one tap away.
var _btn_worklist: Button
## Tiles an "extend" line pointed at, outlined until they are built on.
var _work_hint: Array[int] = []
var _btn_descend: Button
var _lbl_descend_sub: Label
## What the next stratum brings, drawn on the Descend key: the machines it
## unlocks, so "why go down" is answered before it is asked.
var _next_row: HBoxContainer
var _sheet: PanelContainer
var _sheet_body: VBoxContainer
var _sheet_stats: VBoxContainer
var _sheet_title: Label
var _sheet_art: Control
## A band the shaft has just entered, waiting for the view to clear (-1: none).
var _band_news: int = -1
## The open overlay's scroller, so a panel rebuilt in place keeps its place.
var _overlay_scroll: ScrollContainer
var _sheet_status: Control
## The words behind the detail sheet's "?".
var _sheet_help: String = ""
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
var _pointer: Chips.Pointer
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
	# Words are translated where they are written (Loc.t), never by the
	# labels themselves: a word that did not come through Loc stays English,
	# where the pseudo-language check (tools/smoke.gd) can see it.
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_apply_language()
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
			_yard_news = Loc.t("Stratum %d. The yard is bigger: more ground to build on.") % d
			call_deferred("_tell_yard_news")
		elif d > 0:
			_say(_stratum_line(d), Foreman.Pose.JUMP, 3.5)
		# A new band is a new world: its name, big, once the view is clear.
		if d > 0 and int(Palette.band_at(d)[0]) != int(Palette.band_at(d - 1)[0]):
			_band_news = int(Palette.band_at(d)[0])
			call_deferred("_tell_yard_news"))
	Sim.machines_unlocked.connect(_on_unlocked)
	Sim.offline_earnings.connect(_show_offline)
	Sim.collapsed.connect(_on_collapsed)
	Ads.reward_granted.connect(_on_reward)
	Ads.reward_failed.connect(_on_reward_failed)
	Store.purchase_completed.connect(func(k):
		_toast_msg(Loc.t("%s active. Thank you.") % MonetizationDB.title_of(String(k)))
		_refresh())
	Store.purchase_pending.connect(func(_k):
		# A delayed payment instrument. Nothing granted, nothing charged
		# twice, and the player is told rather than left wondering.
		_toast_msg(Loc.t("Waiting on your payment. It unlocks by itself.")))
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
	_apply_settings()


## The language: the one chosen in Settings, else the device's if it is
## translated, else English (Loc.pick). Set before anything is built,
## because every word is written once, when its label is made; the game has
## not loaded yet, so the setting is read from the save directly.
## LODEWORKS_LOCALE overrides it, for the tools that capture and check the
## screens in a given language.
func _apply_language() -> void:
	var forced: String = OS.get_environment("LODEWORKS_LOCALE")
	if forced != "":
		Loc.apply(forced)
		return
	var saved: Dictionary = Sim.settings if bool(Sim.get("_started")) else Save.saved_settings()
	Loc.apply(Loc.pick(String(saved.get("locale", ""))))


## Settings' language: "" follows the device. The interface is made again in
## the new language on the spot; the game itself lives in Sim and is not
## touched.
func _set_language(code: String) -> void:
	Sim.settings["locale"] = code
	Save.save_game(Sim)
	Loc.apply(Loc.pick(code))
	_rebuild_interface()


## Every node of the interface, made again: the words are written when a
## label is made, so a new language is a new interface. The world's camera
## goes back to its default framing.
func _rebuild_interface() -> void:
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_pulsing = null
	_node_card = null
	_node_index = -1
	_next_for = -1
	_armed = ""
	_palette_buttons.clear()
	_palette_costs.clear()
	_problem_level_shown = -1
	_build()
	_rebuild_palette()
	_apply_safe_area()
	_layout_hud()
	_refresh()
	_refresh_hint()
	_apply_settings()


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
		if bool(Sim.settings.get("reduce_motion", false)):
			k = 0.7
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
	_swell_alarm(delta)
	_place_pointer()
	_place_node_card()


## The lit tile the arrow picks while a tutorial step is about the board:
## the one nearest the Core's right-hand corner, clear of the Foreman on the
## left and the toasts along the bottom middle. -1 when nothing is lit.
func pointer_cell() -> int:
	var best: int = -1
	var best_d: float = INF
	var corner: Vector2 = Iso.cell_center(Grid.idx(BuildArea.CORE.end.x, BuildArea.CORE.position.y))
	for c: int in iso_view.highlight_cells:
		var d: float = Iso.cell_center(c).distance_squared_to(corner)
		if d < best_d:
			best_d = d
			best = c
	return best


## Where the arrow points, in the order a new player needs it: the dark Core;
## a key the current step is about (Heat, Descend); or, while the step is
## about the board, a lit tile beside the Core. Nothing once the
## tutorial is done, or while a panel is open.
func _place_pointer() -> void:
	if _pointer == null or iso_view == null:
		return
	var at := Vector2.INF
	var tutoring: bool = not Tutorial.is_done(Sim.tutorial_step())
	if not Sim.core_online:
		var r: Rect2 = iso_view.core_rect()
		at = iso_view.cam.world_to_screen(r.get_center() - Vector2(0, r.size.y * 0.06))
		at = iso_view.get_global_transform() * at
	elif tutoring and _pulsing != null and is_instance_valid(_pulsing) \
			and _pulsing.is_visible_in_tree():
		var gr: Rect2 = _pulsing.get_global_rect()
		at = Vector2(gr.get_center().x, gr.position.y + 4.0)
	elif tutoring and pointer_cell() >= 0:
		at = iso_view.get_global_transform() * iso_view.cam.world_to_screen(
			Iso.cell_center(pointer_cell()) - Vector2(0, Iso.TH * 0.25))
	_pointer.visible = at != Vector2.INF and not _overlay.visible
	if _pointer.visible:
		_pointer.bob = not bool(Sim.settings.get("reduce_motion", false))
		_pointer.global_position = at - Vector2(_pointer.size.x * 0.5, _pointer.size.y)


## The Problems key's swell: its speed and size from the problem count, a
## light behind it from warm to red, and nothing at all for one or two.
func _swell_alarm(delta: float) -> void:
	if _btn_problems == null or _problem_glow == null:
		return
	var n: int = _problem_n
	var level: int = StatusBadges.alarm_level(n)
	var hz: float = StatusBadges.alarm_hz(n)
	if bool(Sim.settings.get("reduce_motion", false)):
		hz = 0.0
	_alarm_t = fposmod(_alarm_t + delta * hz, 1.0)
	var k: float = 0.5 - 0.5 * cos(TAU * _alarm_t) if hz > 0.0 else 0.0
	var grow: float = 1.0 + StatusBadges.alarm_swell(n) * k
	_btn_problems.pivot_offset = _btn_problems.size * 0.5
	_btn_problems.scale = Vector2(grow, grow)
	var glow: Color = Palette.BAD if level >= 4 else Palette.WARN
	var still: float = [0.0, 0.0, 0.22, 0.32, 0.42][level]
	glow.a = still + (0.3 if level >= 2 else 0.0) * k
	_problem_glow.modulate = glow
	_glow_heat(delta)
	# The Descend key's halo: a warm glow round it that swells slowly while
	# the way down is open, drawn as the key's own shadow.
	_halo_beat += 1
	# Fifteen updates a second are enough for a two-second swell, and each
	# update redraws the key.
	if _btn_descend != null and not _btn_descend.disabled and _halo_beat % 4 == 0:
		var k3: float = 0.5 - 0.5 * cos(TAU * fposmod(float(Time.get_ticks_msec()) / 1000.0 * 0.5, 1.0))
		if bool(Sim.settings.get("reduce_motion", false)):
			k3 = 0.5
		for st: String in ["normal", "hover"]:
			var sb := _btn_descend.get_theme_stylebox(st) as StyleBoxFlat
			if sb != null:
				sb.shadow_color = Color(1.0, 0.78, 0.3, 0.35 + 0.4 * k3)
				sb.shadow_size = int(10.0 + 12.0 * k3)
				sb.shadow_offset = Vector2.ZERO


## The heat key: grey when every machine is at its temperature, lit when
## some are not, glowing warm and then red -- or frosty, when it is cold that
## is costing -- with a slow flicker once a machine is badged.
func _glow_heat(delta: float) -> void:
	if _heat_icon == null:
		return
	var st: int = _heat_state
	var hz: float = [0.0, 0.0, 0.6, 1.0][st]
	if bool(Sim.settings.get("reduce_motion", false)):
		hz = 0.0
	_heat_t = fposmod(_heat_t + delta * hz, 1.0)
	var k: float = 0.5 - 0.5 * cos(TAU * _heat_t) if hz > 0.0 else 0.0
	_heat_icon.modulate = Color(0.62, 0.62, 0.68, 0.85) if st == 0 else Color.WHITE
	var frost: bool = _heat_icon.texture == IsoArt.icon("cold")
	var col: Color = Palette.ST_COLD if frost else (Palette.BAD if st >= 3 else Palette.ST_HOT)
	col.a = [0.0, 0.16, 0.30, 0.42][st] + [0.0, 0.0, 0.12, 0.2][st] * k
	_heat_glow.modulate = col


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
		_close_node_card()
		if iso_view.selected_cell >= 0:
			_close_sheet())
	iso_view.core_tapped.connect(_on_core_tapped)
	iso_view.node_tapped.connect(_on_node_tapped)
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
	_undo_btn = _button("", Palette.PANEL_HI)
	_undo_btn.tooltip_text = Loc.t("Undo")
	_undo_btn.visible = false
	_undo_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_undo_btn.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	var undo_mark := Chips.Glyph.new("undo", 60.0)
	undo_mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_undo_btn.add_child(undo_mark)
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

	# The first minutes' "here": an arrow over the next thing to tap.
	_pointer = Chips.Pointer.new()
	_pointer.visible = false
	_hud.add_child(_pointer)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)


func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	# The size it was made at, so Settings' "Larger text" can resize it later.
	l.set_meta("base_fs", size_px)
	l.add_theme_font_size_override("font_size", Palette.text_px(size_px))
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Resize every word already on screen after "Larger text" changes, then
## lay the corners out again round the bigger or smaller panels.
func _apply_text_size() -> void:
	for n: Node in find_children("*", "Label", true, false):
		if n.has_meta("base_fs"):
			(n as Label).add_theme_font_size_override("font_size",
				Palette.text_px(int(n.get_meta("base_fs"))))
			if n.has_meta("fit_w"):
				_fit(n as Label, float(n.get_meta("fit_w")))
	if _stratum_card != null:
		_layout_hud()


## The smallest a word on a key may be made to fit it: well under the
## interface's own floor (TEXT_MIN), and only ever reached by a language
## much longer than English with Larger text on.
const FIT_MIN := 11


## A word on a key whose size is fixed: at its own size if it fits in
## `width`, otherwise a little smaller, until it does. A longer language or
## Larger text must not push a word off its key (tools/loc_check.gd).
func _fit(l: Label, width: float) -> void:
	l.set_meta("fit_w", width)
	var font: Font = l.get_theme_font("font")
	var fs: int = Palette.text_px(int(l.get_meta("base_fs", TEXT_MIN)))
	while fs > FIT_MIN and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
		fs -= 1
	l.add_theme_font_size_override("font_size", fs)


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
	b.add_theme_font_size_override("font_size", Palette.text_px(22))
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
	var l := _label(caption, TEXT_MIN, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fit(l, ACTION_W - 8.0)
	box.add_child(l)
	b.add_child(box)
	return b


## A number in a key's corner: how many things behind the key can be done
## now. Hidden at zero.
func _count_badge(col: Color) -> Label:
	var l := _label("", 17, Palette.TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(15)
	sb.set_border_width_all(2)
	sb.border_color = Palette.BG
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	l.add_theme_stylebox_override("normal", sb)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(30, 30)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.visible = false
	return l


## Research lines the player could buy this moment (Worklist's count).
func _research_ready() -> int:
	return Worklist.research_ready(Sim)


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
	_lbl_depth = _label(Loc.t("Stratum %d") % 0, 20, Palette.TEXT)
	_lbl_depth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_lbl_depth)
	_lbl_band = _label("", TEXT_MIN, Palette.CORE)
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
	# What it costs to go down: a coin and the number, under the bar that
	# fills towards it.
	var qrow := HBoxContainer.new()
	qrow.add_theme_constant_override("separation", 4)
	qrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qrow.add_child(_icon_rect("credits", 18))
	_lbl_quota = _label("", TEXT_MIN, Palette.TEXT_DIM)
	qrow.add_child(_lbl_quota)
	col.add_child(qrow)
	_lbl_mods = _label("", TEXT_MIN, Palette.WARN)
	_lbl_mods.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_mods.custom_minimum_size = Vector2(212, 0)
	col.add_child(_lbl_mods)
	# A tap on the card says what this stratum is and what its rules do.
	p.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and not e.pressed \
				and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
				or (e is InputEventScreenTouch and not e.pressed):
			Juice.tap()
			_show_stratum_info())
	return p


## The stratum card, opened: where the shaft is, what it costs to go on, and
## what this stratum's rules do -- the one place the modifiers are explained.
func _show_stratum_info() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	var where := HBoxContainer.new()
	where.add_theme_constant_override("separation", 14)
	where.add_child(_icon_rect("descend", 64))
	var band: int = int(Palette.band_at(Sim.depth)[0])
	where.add_child(_label(Loc.t(BAND_NAMES[band]), 28, Color(Palette.BAND_VEIN[band]).lightened(0.2)))
	body.add_child(where)
	var cost := HBoxContainer.new()
	cost.add_theme_constant_override("separation", 12)
	cost.add_child(_icon_rect("credits", 52))
	cost.add_child(_label("%s / %s" % [Economy.fmt(Sim.credits), Economy.fmt(Sim.quota())], 26,
		Palette.CORE))
	var bar := Chips.Gauge.new(260, 18)
	bar.value = clampf(Sim.credits / maxf(Sim.quota(), 1.0), 0.0, 1.0)
	bar.fill = Palette.ACCENT
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost.add_child(bar)
	body.add_child(cost)
	_rule_rows(body, Sim.depth, Sim.unlocked)
	_open_overlay(Loc.t("Stratum %d") % Sim.depth, body, [])


## What lies below: the next stratum before going down to it -- how far the
## quota is, its rules with the machines they will move, the machines it
## opens and the ground the yard gains. A tap on Descend before the quota
## shows it, and so does holding Descend at any time. A board that is right
## up here is rarely right down there (Codex, "Deeper is different"); this
## is the chance to see how before paying for it.
func _show_below() -> void:
	var d: int = Sim.depth + 1
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.set_meta("below", d)
	var where := HBoxContainer.new()
	where.add_theme_constant_override("separation", 14)
	where.add_child(_icon_rect("descend", 64))
	var band: int = int(Palette.band_at(d)[0])
	where.add_child(_label(Loc.t(BAND_NAMES[band]), 28, Color(Palette.BAND_VEIN[band]).lightened(0.2)))
	body.add_child(where)
	# How far off it is.
	var cost := HBoxContainer.new()
	cost.add_theme_constant_override("separation", 12)
	cost.add_child(_icon_rect("credits", 52))
	cost.add_child(_label("%s / %s" % [Economy.fmt(Sim.credits), Economy.fmt(Sim.quota())], 26,
		Palette.CORE))
	var bar := Chips.Gauge.new(260, 18)
	bar.value = clampf(Sim.credits / maxf(Sim.quota(), 1.0), 0.0, 1.0)
	bar.fill = Palette.ACCENT
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost.add_child(bar)
	body.add_child(cost)
	# Its rules, on the machines the player will have there.
	var will_have: Array[String] = MachineDB.unlocked_at(maxi(d, Sim.max_depth))
	_rule_rows(body, d, will_have)
	# The machines it opens, and the ground.
	var now: Array[String] = MachineDB.unlocked_at(Sim.depth)
	var opens := HBoxContainer.new()
	opens.add_theme_constant_override("separation", 8)
	for id: String in MachineDB.unlocked_at(d):
		if not now.has(id) and not Sim.unlocked.has(id):
			opens.add_child(Chips.MachineSprite.new(id, 56.0))
	if opens.get_child_count() > 0:
		opens.add_child(_label(Loc.tn("A new machine down there.", "New machines down there.",
			opens.get_child_count()), 20, Palette.TEXT_DIM))
		body.add_child(opens)
	else:
		# Past the last new machine there is none: not kept, or it is a node
		# nothing owns (the smoke test's leak check found one per look below).
		opens.free()
	if d > Sim.max_depth and BuildArea.size_at(d) != BuildArea.size_at(Sim.max_depth):
		var grow := HBoxContainer.new()
		grow.add_theme_constant_override("separation", 12)
		grow.add_child(_core_picture(48.0))
		var s: Vector2i = BuildArea.size_at(d)
		grow.add_child(_label(Loc.t("The yard grows to %d x %d.") % [s.x, s.y], 20, Palette.TEXT_DIM))
		body.add_child(grow)
	var actions: Array = []
	if Sim.can_descend():
		actions.append({"text": Loc.t("Descend"), "color": Palette.WARN, "cb": _on_descend})
	_open_overlay(Loc.t("Below: stratum %d") % d, body, actions)


## A stratum's rules as rows: a star, the rule's name and words, and the
## machines in `machines` it moves, with the arrows their tray keys show.
## Plain rock says so.
func _rule_rows(body: VBoxContainer, depth: int, machines: Array[String]) -> void:
	var mods: Array[String] = Strata.modifiers_for(depth)
	if mods.is_empty():
		var calm := HBoxContainer.new()
		calm.add_theme_constant_override("separation", 12)
		calm.add_child(_icon_rect("ok", 44))
		calm.add_child(_label(Loc.t("Plain rock. No strange rules here."), 20, Palette.TEXT_DIM))
		body.add_child(calm)
	for id in mods:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		# A star: a rule of this stratum, good or bad -- the words say which.
		var ic := _icon_rect("star", 44)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(ic)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_child(_label(Strata.modifier_name(String(id)), 22, Palette.WARN))
		var d := _label(Strata.modifier_desc(String(id)), 18, Palette.TEXT_DIM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(d)
		# The machines this rule moves, with the arrow their tray key shows.
		var moved := HBoxContainer.new()
		moved.add_theme_constant_override("separation", 6)
		for mid: String in MachineDB.by_group(machines):
			for e: Array in Strata.effects_on(mid, depth):
				if String(e[0]) != String(id):
					continue
				var pic := Control.new()
				pic.custom_minimum_size = Vector2(48, 48)
				pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
				pic.add_child(Chips.MachineSprite.new(mid, 48.0))
				var mark := Chips.Glyph.new("up" if int(e[1]) > 0 else "down", 22.0)
				mark.position = Vector2(28, 28)
				mark.size = Vector2(22, 22)
				pic.add_child(mark)
				moved.add_child(pic)
		if moved.get_child_count() > 0:
			words.add_child(moved)
		else:
			moved.free()
		row.add_child(words)
		body.add_child(row)


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
	_lbl_rate = _label(Loc.t("+%s /s") % "0", TEXT_MIN, Palette.TEXT_DIM)
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

	# What to do now, ranked (Worklist): first in the column, because after
	# the tutorial it is the answer to the question the tutorial answered.
	_btn_worklist = _button("", Palette.PANEL_HI)
	_btn_worklist.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	var wl := Chips.Glyph.new("tasks", 60.0)
	wl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_btn_worklist.add_child(wl)
	_btn_worklist.tooltip_text = Loc.t("What now?")
	_btn_worklist.pressed.connect(func():
		Juice.tap()
		_show_worklist())
	col.add_child(_btn_worklist)

	_btn_heat = _button("", Palette.PANEL_HI)
	_btn_heat.toggle_mode = true
	_btn_heat.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	_heat_glow = TextureRect.new()
	_heat_glow.texture = IsoArt.glow()
	_heat_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_heat_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heat_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heat_glow.modulate = Color(Palette.ST_HOT, 0.0)
	_btn_heat.add_child(_heat_glow)
	var hic := _icon_rect("heat", 46)
	hic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heat_icon = hic
	_btn_heat.add_child(hic)
	_btn_heat.tooltip_text = Loc.t("Heat view")
	_btn_heat.toggled.connect(func(on: bool):
		iso_view.set_overlay(IsoView.Overlay.HEAT if on else IsoView.Overlay.NONE)
		if on:
			Sim.tutorial_saw_heat = true
			_maybe_advance_tutorial()
		Juice.tap())
	col.add_child(_btn_heat)

	# One key: in to the middle of the screen, or back out to the whole
	# factory. Off unless Settings turns it on (Accessibility): a phone
	# pinches, and a key that only zooms is a key the screen can do without.
	_btn_zoom = _button("+", Palette.PANEL_HI)
	_btn_zoom.add_theme_font_size_override("font_size", 34)
	_btn_zoom.add_theme_color_override("font_color", Palette.TEXT)
	_btn_zoom.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	_btn_zoom.tooltip_text = Loc.t("Zoom")
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
	# A soft light behind the sign, which the alarm swells.
	_problem_glow = TextureRect.new()
	_problem_glow.texture = IsoArt.glow()
	_problem_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_problem_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_problem_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_problem_glow.modulate = Color(Palette.WARN, 0.0)
	_btn_problems.add_child(_problem_glow)
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
	_btn_problems.tooltip_text = Loc.t("Problems")
	_btn_problems.pressed.connect(_cycle_problem)
	col.add_child(_btn_problems)
	return col


func _build_actions() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_research = _icon_button("research", Loc.t("Research"), Palette.PANEL_HI)
	_btn_research.pressed.connect(_show_research)
	row.add_child(_btn_research)
	# How many research lines can be bought right now, in the key's corner:
	# the one-time nudge says "spend it" once; this says it whenever it is
	# true, and is gone when it is not.
	_research_badge = _count_badge(Palette.RESEARCH)
	_research_badge.position = Vector2(ACTION_W - 26, -8)
	_btn_research.add_child(_research_badge)
	_btn_collapse = _icon_button("cores", Loc.t("Collapse"), Palette.PANEL_HI)
	_btn_collapse.pressed.connect(_show_collapse)
	row.add_child(_btn_collapse)
	# The Codex is one tap from the board because its whole job is to be
	# reachable at the moment a player is confused.
	var codex := _icon_button("codex", Loc.t("Codex"), Palette.PANEL_HI)
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
	# What is left of the key beside its picture: its margins, the picture
	# and the gap.
	var room: float = DESCEND_W - 20.0 - 56.0 - 8.0
	var head := _label(Loc.t("DESCEND"), 22, Palette.BG)
	_fit(head, room)
	col.add_child(head)
	_lbl_descend_sub = _label("", TEXT_MIN, Color(Palette.BG, 0.8))
	_lbl_descend_sub.set_meta("fit_w", room)
	col.add_child(_lbl_descend_sub)
	_next_row = HBoxContainer.new()
	_next_row.add_theme_constant_override("separation", 2)
	_next_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_next_row)
	row.add_child(col)
	_btn_descend.add_child(row)
	# Holding it shows what lies below, at any time.
	_on_hold(_btn_descend, _show_below)
	_btn_descend.pressed.connect(func():
		if not _held_off(_btn_descend):
			_on_descend())
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
	var out: Array[Button] = [_btn_worklist, _btn_heat, _btn_zoom, _btn_problems, _btn_descend]
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
	row.add_theme_constant_override("separation", 14)
	_sheet.add_child(row)

	# The machine itself, big: the picture is what the player recognises.
	_sheet_art = Chips.MachineSprite.new("", 150.0)
	row.add_child(_sheet_art)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_sheet_status = _icon_rect("ok", 44)
	head.add_child(_sheet_status)
	_sheet_title = _label("", 26, Palette.TEXT)
	_sheet_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_sheet_title)
	left.add_child(head)
	# What it makes, as gems: the board carries them in the same colours.
	_sheet_body = VBoxContainer.new()
	left.add_child(_sheet_body)
	# How hot, and how busy: two bars.
	_sheet_stats = VBoxContainer.new()
	_sheet_stats.add_theme_constant_override("separation", 6)
	left.add_child(_sheet_stats)
	row.add_child(left)

	# The words, for whoever wants them.
	row.add_child(_help_button("", func() -> String: return _sheet_help))
	# Remove, in plain sight: select, then act, as every builder game does.
	# The long press still works; this is the key a new player can find.
	var rm := _button("", Palette.PANEL)
	rm.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	rm.size_flags_horizontal = Control.SIZE_SHRINK_END
	rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bin := Chips.Glyph.new("bin", 60.0)
	bin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rm.add_child(bin)
	rm.tooltip_text = Loc.t("Remove")
	rm.pressed.connect(func():
		if iso_view.selected_cell >= 0:
			Juice.tap()
			_on_cell_long_pressed(iso_view.selected_cell))
	row.add_child(rm)

	var close := _button("✕", Palette.PANEL)
	close.add_theme_color_override("font_color", Palette.TEXT)
	close.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(_close_sheet)
	row.add_child(close)


## A "?" key: the words for something a panel now shows in pictures. The
## text is read when it is pressed, so it can describe the moment.
func _help_button(title: String, text: Callable) -> Button:
	var b := _button("?", Palette.PANEL)
	b.add_theme_color_override("font_color", Palette.ACCENT)
	b.add_theme_font_size_override("font_size", 32)
	b.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBox = b.get_theme_stylebox(state)
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).set_corner_radius_all(int(MIN_TOUCH / 2.0))
	b.pressed.connect(func():
		Juice.tap()
		var t: String = String(text.call())
		var head: String = title if title != "" else _sheet_title.text
		_info(head, t))
	return b


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
		_toast_msg(Loc.t("Nothing is stalled or overheating."))
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
	_afford_shown.clear()
	var last: int = -1
	for id in MachineDB.by_group(MachineDB.ORDER.filter(func(k): return Sim.is_unlocked(k))):
		var g: int = MachineDB.group_of(id)
		if last >= 0 and g != last:
			# A seam between groups: the tray reads as Diggers, Makers,
			# Sellers... without a word on it.
			var seam := ColorRect.new()
			seam.custom_minimum_size = Vector2(3, 0)
			seam.size_flags_vertical = Control.SIZE_FILL
			seam.color = Color(Palette.KEY_TINT, 0.22)
			seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_palette_row.add_child(seam)
		last = g
		_palette_row.add_child(_make_palette_button(id))


func _make_palette_button(id: String) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(98, MIN_TOUCH)
	b.toggle_mode = true
	b.tooltip_text = "%s\n%s\n%s" % [MachineDB.name_of(id),
		MachineDB.recipe_text(id), MachineDB.desc_of(id)]
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
	var chip := Chips.MachineSprite.new(id, 66.0)
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(chip)
	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 2)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(_icon_rect("credits", 18))
	var cost_lbl: Label = _label(Economy.fmt(Sim.cost_of(id)), TEXT_MIN, Palette.CORE)
	cost_row.add_child(cost_lbl)
	col.add_child(cost_row)
	b.add_child(col)
	# Its group's sign in the corner: the same picture the Codex files it
	# under.
	var grp := _icon_rect(String(MachineDB.GROUPS[MachineDB.group_of(id)]["icon"]), 26)
	grp.position = Vector2(4, 4)
	grp.size = Vector2(26, 26)
	b.add_child(grp)
	# What this stratum's rock does to it, at the moment of choosing: an
	# arrow up or down, the simulation's own answer (Strata.effect_on). The
	# rule that does it is in the words behind the "?".
	var verdict: int = Strata.effect_on(id, Sim.stratum())
	if verdict != 0:
		var arrow := Chips.Glyph.new("up" if verdict > 0 else "down", 28.0)
		arrow.position = Vector2(98 - 32, 44)
		arrow.size = Vector2(28, 28)
		b.add_child(arrow)
	b.set_meta("verdict", verdict)
	# The name and what it does, behind a "?" in the corner.
	var help: Button = _machine_help(id)
	help.custom_minimum_size = Vector2(40, 40)
	help.size = Vector2(40, 40)
	help.add_theme_font_size_override("font_size", 22)
	help.position = Vector2(98 - 42, 2)
	b.add_child(help)
	# The "?" is small, so holding the whole key opens the same words: a
	# 96-unit target where the "?" is 40.
	_on_hold(b, func(): help.pressed.emit())

	b.pressed.connect(func():
		if _held_off(b):
			# The hold opened the words; the release that ends it arms nothing.
			b.set_pressed_no_signal(_armed == id)
			return
		_arm(id))
	_palette_buttons[id] = b
	_palette_costs[id] = cost_lbl
	return b


## Holding key `b` still for half a second calls `cb`. A press that moves
## is a drag or a scroll, not a hold -- measured on the screen, not on the
## key, because a scrolling tray carries the key along under the finger. The release that ends a hold still
## reaches the key's `pressed`, which asks `_held_off` first.
func _on_hold(b: Button, cb: Callable) -> void:
	var hold := {"down": false, "at": Vector2.ZERO, "n": 0}
	b.set_meta("held", false)
	b.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			hold["down"] = e.pressed
			if e.pressed:
				b.set_meta("held", false)
				hold["at"] = (e as InputEventMouseButton).global_position
				hold["n"] = int(hold["n"]) + 1
				var n: int = int(hold["n"])
				get_tree().create_timer(IsoView.LONG_PRESS_SECONDS).timeout.connect(func():
					if bool(hold["down"]) and int(hold["n"]) == n and is_instance_valid(b):
						hold["down"] = false
						b.set_meta("held", true)
						cb.call())
		elif e is InputEventMouseMotion and bool(hold["down"]) \
				and (e as InputEventMouseMotion).global_position.distance_to(hold["at"]) > IsoView.DRAG_THRESHOLD:
			hold["down"] = false)


## True once, for the release that ended a hold on `b`: not a press.
func _held_off(b: Button) -> bool:
	if bool(b.get_meta("held", false)):
		b.set_meta("held", false)
		return true
	return false


## --- interaction -----------------------------------------------------------

func _arm(id: String) -> void:
	Juice.tap()
	_armed = "" if _armed == id else id
	iso_view.arm_id = _armed
	for k: String in _palette_buttons:
		_palette_buttons[k].button_pressed = (k == _armed)


func _on_cell_tapped(cell: int) -> void:
	_close_node_card()
	if Sim.is_blocked(cell):
		Juice.blocked()
		_toast_msg(Loc.t("This part of the shaft has collapsed."))
		return
	if Sim.grid.is_empty(cell):
		if iso_view.selected_cell >= 0:
			_close_sheet()
		if not Sim.is_open(cell):
			Juice.reject()
			_toast_msg(Loc.t("The yard reaches this ground at stratum %d.")
				% BuildArea.opens_at(cell))
			return
		if _armed == "":
			_toast_msg(Loc.t("Pick a machine below, then tap a tile."))
			return
		if not Sim.can_afford(_armed):
			Juice.reject()
			_toast_msg(Loc.t("Not enough credits for a %s.") % MachineDB.name_of(_armed))
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
	var do_remove := func() -> void:
		Sim.sell(cell)
		_push_undo({"kind": "sell", "cell": cell, "id": id, "refund": refund})
		Juice.sell()
		_close_sheet()
		_shown_credits = Sim.credits
		_refresh()
	# The machine, an arrow, and what comes back for it.
	var what := HBoxContainer.new()
	what.alignment = BoxContainer.ALIGNMENT_CENTER
	what.add_theme_constant_override("separation", 16)
	what.add_child(Chips.MachineSprite.new(id, 150.0))
	what.add_child(Chips.Arrow.new(56.0))
	what.add_child(_icon_rect("credits", 64))
	what.add_child(_label("+%s" % Economy.fmt(refund), 40, Palette.CORE))
	_open_overlay(Loc.t("Remove?"), what, [{"text": Loc.t("Remove"), "color": Palette.BAD,
		"cb": do_remove}])


func _on_descend() -> void:
	if not Sim.can_descend():
		# Not yet: what is down there, and how far off it is.
		Juice.tap()
		_show_below()
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

	# The new machines, big and working, each with what it makes and a "?"
	# for the words. They are waiting in the tray.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id: String in ids:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 6)
		col.add_child(Chips.MachineSprite.new(String(id), 190.0, not Juice.calm))
		# Its name and one line of what it is for: the reward is knowing
		# what the new thing does.
		var un := _label(MachineDB.name_of(String(id)), 28, Palette.TEXT)
		un.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(un)
		var us := _label(MachineDB.short_of(String(id)), 19, Palette.TEXT_DIM)
		us.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(us)
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 8)
		line.add_child(Chips.recipe(String(id), 40.0))
		line.add_child(_machine_help(String(id)))
		col.add_child(line)
		row.add_child(col)
	var badge := Foreman.Badge.new(Foreman.Pose.CHEER, 110.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(badge)
	_open_overlay(Loc.t("NEW!"), row, [])


## A machine's "?": its name, what it makes and what it is for.
func _machine_help(id: String) -> Button:
	var b: Button = _help_button(MachineDB.name_of(id), func() -> String:
		var t: String = MachineDB.recipe_text(id)
		var words: String = (t + "\n\n" if t != "" else "") + MachineDB.desc_of(id)
		# The rules of this stratum that move it: why its key has an arrow.
		for e: Array in Strata.effects_on(id, Sim.depth):
			var why: String = Loc.t("Helped here: %s. %s") if int(e[1]) > 0 \
				else Loc.t("Held back here: %s. %s")
			words += "\n\n" + why % [Strata.modifier_name(String(e[0])),
				Strata.modifier_desc(String(e[0]))]
		return words)
	return b


func _on_collapsed(gained: int) -> void:
	_rebuild_palette()
	_close_sheet()
	_shown_credits = Sim.credits
	Juice.collapse()
	# Framed as what is kept, never as what is lost, and never as a "reset".
	# The genre's most cited progression failure is a prestige that reads as
	# punishment, and the wording is half of that.
	_refresh_hint()
	_info(Loc.t("The shaft collapses"),
		Loc.tn("You brought up %d Core.\n\nCores survive a collapse, and so does every upgrade you have researched. The next shaft goes deeper and faster than this one did.",
			"You brought up %d Cores.\n\nCores survive a collapse, and so does every upgrade you have researched. The next shaft goes deeper and faster than this one did.",
			gained) % gained)


func _on_reward(placement: String) -> void:
	match placement:
		Ads.P_DOUBLE_OFFLINE:
			var extra: float = Save.apply_offline_double(Sim)
			Juice.reward()
			_shown_credits = Sim.credits - extra
			_toast_msg(Loc.t("+%s credits.") % Economy.fmt(extra))
			_refresh()
		_:
			_toast_msg(Loc.t("Reward granted."))


## An ad that does not play is not the player's problem, and it is not worth a
## modal. The base offline payout was already credited before the ad was ever
## offered, so nothing is lost here -- only the doubling.
func _on_reward_failed(_placement: String, reason: String) -> void:
	match reason:
		"dismissed":
			pass  # They closed it deliberately. Saying anything is nagging.
		"timeout", "show_failed":
			_toast_msg(Loc.t("The ad did not play. Nothing was lost."))
		_:
			_toast_msg(Loc.t("No ad available right now."))


## --- refresh ---------------------------------------------------------------

const BAND_NAMES := ["The Surface", "The Workings", "The Deep", "The Abyss"]


## What the tray and the warning key last showed, so a tick that changes
## nothing changes no theme (see _refresh).
var _afford_shown: Dictionary = {}
var _problem_level_shown: int = -1

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
	_lbl_rate.text = Loc.t("+%s /s") % Economy.fmt(Sim.credits_per_sec)
	_lbl_research.text = Economy.fmt(Sim.research)
	_lbl_cores.text = str(Sim.cores)
	var buyable: int = _research_ready()
	_research_badge.text = str(buyable)
	_research_badge.visible = buyable > 0
	_show_what_matters()

	var s: Dictionary = Sim.stratum()
	_lbl_depth.text = Loc.t("Stratum %d") % Sim.depth
	_lbl_band.text = Loc.t(BAND_NAMES[int(Palette.band_at(Sim.depth)[0])])
	var q: float = Sim.quota()
	_quota_bar.value = clampf(Sim.credits / q, 0.0, 1.0) if q > 0.0 else 0.0
	_lbl_quota.text = Economy.fmt(q)
	var mods: Array = s.get("modifiers", [])
	if mods.is_empty():
		_lbl_mods.text = ""
		_lbl_mods.visible = false
	else:
		# Names only: what each one does is a tap on this card away
		# (`_show_stratum_info`), and a paragraph per modifier in the corner
		# of the screen is a wall of text.
		var parts: Array = []
		for id in mods:
			parts.append(Strata.modifier_name(id))
		_lbl_mods.text = " · ".join(parts)
		_lbl_mods.tooltip_text = "\n".join(mods.map(func(id): return "%s: %s" % [
			Strata.modifier_name(id), Strata.modifier_desc(id)]))
		_lbl_mods.visible = true

	_refresh_problems()

	# The moment the quota is met, the key says so: a punch and the credits
	# chime once, and a slow warm swell for as long as it stays open.
	if Sim.can_descend() and _btn_descend.disabled and _descend_seen_closed:
		Juice.punch(_btn_descend, 0.08, 0.35)
		Juice.income()
	_descend_seen_closed = not Sim.can_descend()
	_btn_descend.disabled = not Sim.can_descend()
	var sub: String = Loc.t("to stratum %d") % (Sim.depth + 1) if Sim.can_descend() \
		else Loc.t("%d%% of quota") % int(round(_quota_bar.value * 100.0))
	if _lbl_descend_sub.text != sub:
		_lbl_descend_sub.text = sub
		_fit(_lbl_descend_sub, float(_lbl_descend_sub.get_meta("fit_w")))
	_show_next_unlock()
	for id: String in _palette_buttons:
		var afford: bool = Sim.can_afford(id)
		var cost: Label = _palette_costs.get(id, null)
		if cost != null:
			cost.text = Economy.fmt(Sim.cost_of(id))
		# Only when it changes: a theme override is a relayout of the label,
		# and this runs every tick.
		if _afford_shown.get(id, null) != afford:
			_afford_shown[id] = afford
			if cost != null:
				cost.add_theme_color_override("font_color",
					Palette.CORE if afford else Palette.TEXT_FAINT)
			# The whole card dims when it is out of reach, so "can I afford
			# this" is answered by the brightness of the picture rather than
			# by reading a number and comparing it with another number.
			(_palette_buttons[id] as Button).modulate = Color(1, 1, 1,
				1.0 if afford else 0.45)
	if _stratum_card != null:
		_layout_hud()


## The machines the next stratum unlocks, as small pictures on the Descend
## key, with "+" and the yard's growth when it grows too. Rebuilt only when
## the depth changes.
var _next_for: int = -1

func _show_next_unlock() -> void:
	if _next_for == Sim.depth:
		return
	_next_for = Sim.depth
	for c in _next_row.get_children():
		c.queue_free()
	var now: Array[String] = MachineDB.unlocked_at(Sim.depth)
	var ids: Array[String] = []
	for id: String in MachineDB.unlocked_at(Sim.depth + 1):
		if not now.has(id):
			ids.append(id)
	if ids.is_empty():
		_next_row.visible = false
		return
	_next_row.visible = true
	_next_row.add_child(_label(Loc.t("next:"), TEXT_MIN, Color(Palette.BG, 0.75)))
	for id: String in ids.slice(0, 3):
		var chip := Chips.MachineSprite.new(id, 28.0)
		chip.tooltip_text = MachineDB.name_of(id)
		_next_row.add_child(chip)


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
	# During the first chapter the Foreman says what to do; after it, this.
	_btn_worklist.visible = veteran or Tutorial.is_done(step)
	# Pinch, the wheel and the trackpad zoom; the key is for a player who
	# cannot pinch, and only appears when Settings asks for it.
	_btn_zoom.visible = bool(Sim.settings.get("zoom_key", false))


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
		_toast_msg(Loc.t("That cannot be undone now."))


## The two tutorial steps that complete by waiting rather than by tapping --
## seeing the first credits arrive, and reaching the quota -- are checked here
## rather than polled, because both are things the simulation announces.
func _tutorial_watch() -> void:
	if not Tutorial.is_done(Sim.tutorial_step()) and Sim.tutorial_satisfied():
		_maybe_advance_tutorial()
	if not _research_nudged and Sim.research > 0.0:
		_research_nudged = true
		_say(Loc.t(Tutorial.RESEARCH_NUDGE), Foreman.Pose.POINT, 5.0)


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
	# The alarm grows with the count (`StatusBadges.alarm_*`); a step up into
	# a stronger alarm is heard once.
	var level: int = StatusBadges.alarm_level(n)
	if level >= 3 and level > StatusBadges.alarm_level(_problem_n):
		Juice.alarm()
	_problem_n = n
	# The heat key's picture, from the same badges the board shows. Twice a
	# second is plenty -- a badge takes 1.5 s to appear -- and a full board
	# costs about 0.25 ms to read on the desktop.
	_heat_beat += 1
	if _heat_beat % 5 == 1:
		var hs: Array = iso_view.badges.heat_state(Sim.sim, Sim.grid.cells)
		_heat_state = int(hs[0])
		_heat_icon.texture = IsoArt.icon("cold" if bool(hs[1]) else "heat")
	if level != _problem_level_shown:
		_problem_level_shown = level
		_lbl_problem_count.add_theme_color_override("font_color",
			[Palette.TEXT, Palette.TEXT, Palette.WARN, Palette.WARN, Palette.BAD][level])
	# The Foreman steps in once per stratum, the first time something on the
	# board is actually in trouble -- a machine at critical heat -- and points
	# at the key that finds it. Once, so it is news rather than nagging.
	var calm: bool = Tutorial.is_done(Sim.tutorial_step()) and not _overlay.visible
	if _alerted_depth != Sim.depth and calm:
		for cell: int in Sim.grid.cells:
			if iso_view.badges.shown(cell) == StatusBadges.Show.CRITICAL:
				_alerted_depth = Sim.depth
				_say(Loc.t("Something is overheating. The warning key finds it."),
					Foreman.Pose.ALERT, 5.0)
				break
	var parts: Array[String] = []
	if int(c["starved"]) > 0:
		parts.append(Loc.t("%d starved") % int(c["starved"]))
	if int(c["blocked"]) > 0:
		parts.append(Loc.t("%d backed up") % int(c["blocked"]))
	if int(c["thermal"]) > 0:
		parts.append(Loc.t("%d off temperature") % int(c["thermal"]))
	_btn_problems.tooltip_text = Loc.t("Everything is running.") if parts.is_empty() \
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
		_work_hint.clear()
		_say(Loc.t(Tutorial.CORE_LINE), Foreman.Pose.POINT, 9999.0)
		iso_view.highlight_cells = []
		_pulse_control("")
		return
	var step: int = Sim.tutorial_step()
	if Tutorial.is_done(step):
		var left: Array[int] = []
		for c: int in _work_hint:
			if Sim.grid.is_empty(c):
				left.append(c)
		_work_hint = left
		iso_view.highlight_cells = _work_hint
		_pulse_control("")
		if _foreman_time <= 0.0:
			_foreman.visible = false
		return
	_say(Loc.t(Tutorial.line_for(step)), Foreman.Pose.POINT, 9999.0)
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
	_close_node_card()
	if Sim.power_core():
		iso_view.core_powered()
		Juice.reward()
		_shown_credits = Sim.credits - Sim.core_reserve()
		_toast_msg(Loc.t("The Core is online: %s credits from its reserve.")
			% Economy.fmt(Sim.core_reserve()))
		if Tutorial.is_done(Sim.tutorial_step()):
			_say(Loc.t("Online. Build the shaft back up."), Foreman.Pose.JUMP, 3.0)
		_refresh()
		_refresh_hint()
		return
	_show_core()


## The Factory Core's card: its level, and the factory it runs in pictures
## and a few numbers -- machines, how many work, how many need help, what it
## earns, how much of the yard is built, and what the next stratum brings.
## The words are behind the "?". The numbers are FactoryReport's, which sums
## up any factory it is handed, and "need help" is the warning key's count.
func _show_core() -> void:
	var rep: Dictionary = FactoryReport.of(Sim.grid, Sim.sim, Sim.max_depth,
		Strata.blocked_cells(Sim.depth))
	var lvl: int = IsoView.core_level()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.set_meta("report", rep)

	# The Core, its level as pips, and the words behind a "?".
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 24)
	top.add_child(_core_picture(150.0))
	var lv := VBoxContainer.new()
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	lv.add_theme_constant_override("separation", 8)
	lv.add_child(_label(Loc.t("LEVEL %d") % lvl, 34, Palette.CORE))
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 6)
	for k in range(IsoView.CORE_LEVELS):
		var pip := _pip(k < lvl) as ColorRect
		pip.color = Palette.CORE if k < lvl else Color(Palette.BG, 0.9)
		pips.add_child(pip)
	lv.add_child(pips)
	lv.add_child(_label(Loc.t("Stratum %d") % Sim.depth, 18, Palette.TEXT_DIM))
	top.add_child(lv)
	var next_lvl: String = Loc.t("It is as big as it gets.") if lvl >= IsoView.CORE_LEVELS \
		else Loc.t("It grows with its yard: at stratum %d it reaches level %d.") % [
			IsoView.stratum_for_level(lvl + 1), lvl + 1]
	top.add_child(_help_button(Loc.t("Factory Core"), func() -> String:
		return Loc.t("The heart of this shaft. It gave you the credits for your first Drill and Vault; everything since, the board has earned.\n\n%s Every stratum is richer rock, and new machines open on the way down.") % next_lvl))
	body.add_child(top)

	# The factory in four numbers.
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	var problems: int = int(rep["problems"])
	stats.add_child(_core_stat(Chips.MachineSprite.new("drill", 46.0),
		str(int(rep["machines"])), Loc.t("machines"), Palette.TEXT))
	stats.add_child(_core_stat(_icon_rect("ok", 46), str(int(rep["working"])),
		Loc.t("working"), Palette.GOOD))
	stats.add_child(_core_stat(_icon_rect("warning", 46), str(problems), Loc.t("need help"),
		Palette.WARN if problems > 0 else Palette.TEXT_DIM))
	stats.add_child(_core_stat(_icon_rect("credits", 46),
		Loc.t("+%s /s") % Economy.fmt(Sim.credits_per_sec), Loc.t("earning"), Palette.CORE))
	body.add_child(stats)

	# How much of the yard is built.
	var yard := HBoxContainer.new()
	yard.alignment = BoxContainer.ALIGNMENT_CENTER
	yard.add_theme_constant_override("separation", 14)
	yard.add_child(_label(Loc.t("Yard"), 22, Palette.TEXT))
	var bar := Chips.Gauge.new(300, 18)
	bar.value = clampf(float(rep["machines"]) / float(maxi(int(rep["tiles"]), 1)), 0.0, 1.0)
	bar.fill = Palette.ACCENT
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	yard.add_child(bar)
	yard.add_child(_label(Loc.t("%d / %d tiles") % [int(rep["machines"]), int(rep["tiles"])], 22,
		Palette.TEXT))
	body.add_child(yard)

	# What going down brings next.
	var nxt := HBoxContainer.new()
	nxt.alignment = BoxContainer.ALIGNMENT_CENTER
	nxt.add_theme_constant_override("separation", 12)
	nxt.add_child(_icon_rect("descend", 44))
	var at: int = int(rep["next_stratum"])
	var grow: Vector2i = rep["next_size"]
	var line: String = Loc.t("The yard covers all the ground there is.")
	if at >= 0 and lvl < IsoView.CORE_LEVELS:
		line = Loc.t("Stratum %d: level %d, and the yard grows to %d x %d.") % [at,
			IsoView.level_at(at), grow.x, grow.y]
	elif at >= 0:
		line = Loc.t("Stratum %d: the yard grows to %d x %d.") % [at, grow.x, grow.y]
	nxt.add_child(_label(line, 20, Palette.TEXT_DIM))
	body.add_child(nxt)

	# Something is wrong: one key takes the player to it.
	var actions: Array = []
	if problems > 0:
		actions.append({"text": Loc.t("Show me"), "color": Palette.WARN, "cb": _cycle_problem})
	_open_overlay(Loc.t("Factory Core"), body, actions, 900.0)


## One of the Core card's numbers: a picture, the number, a word under it.
func _core_stat(pic: Control, value: String, word: String, col: Color) -> Control:
	var p := _panel(Palette.PANEL_HI, 0.9)
	p.custom_minimum_size = Vector2(170, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pic)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", -4)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(_label(value, 28, col))
	words.add_child(_label(word, TEXT_MIN, Palette.TEXT_DIM))
	row.add_child(words)
	p.add_child(row)
	return p


## --- what now? --------------------------------------------------------------
##
## The Worklist as a card: one row per thing worth doing, in Worklist's
## fixed order, each with a picture, a few words and the place a tap takes
## the player. Nothing here decides anything; it points at what the rest
## of the interface already offers.

func _show_worklist() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var items: Array = Worklist.of(Sim)
	body.set_meta("worklist", items)
	for e: Dictionary in items:
		body.add_child(_work_row(e))
	_open_overlay(Loc.t("What now?"), body, [], 900.0)


## One Worklist line as a row: its picture, its words, and what a tap does.
func _work_row(e: Dictionary) -> Button:
	var pic: Control
	var title: String = ""
	var sub: String = ""
	var go: Callable = func() -> void: pass
	match String(e["kind"]):
		"problems":
			var n: int = int(e["n"])
			pic = _icon_rect("warning", 52)
			title = Loc.tn("%d machine needs help", "%d machines need help", n) % n
			sub = Loc.t("A tap takes you to the first one.")
			go = _cycle_problem
		"descend":
			pic = _icon_rect("descend", 52)
			title = Loc.t("Go down to stratum %d") % int(e["stratum"])
			sub = Loc.t("The quota is met. See what is down there first.")
			go = _show_below
		"research":
			var n2: int = int(e["n"])
			pic = _icon_rect("research", 52)
			title = Loc.tn("%d research line ready", "%d research lines ready", n2) % n2
			sub = Loc.t("What it buys stays, even after a collapse.")
			go = _show_research
		"collapse":
			var lines: int = (e["lines"] as Array).size()
			pic = _icon_rect("cores", 52)
			title = Loc.t("Collapse for %d Cores") % int(e["cores"])
			sub = Loc.tn("They open %d research line.", "They open %d research lines.", lines) % lines
			go = _show_collapse
		"first":
			var id: String = String(e["id"])
			pic = Chips.MachineSprite.new(id, 52.0)
			title = Loc.t("Build your first %s") % MachineDB.name_of(id)
			sub = MachineDB.short_of(id)
			go = func() -> void: _arm_only(id)
		"extend":
			var id3: String = String(e["id"])
			pic = Chips.MachineSprite.new(id3, 52.0)
			title = Loc.t("Add a %s to the chain") % MachineDB.name_of(id3)
			sub = Loc.t("Beside the %s, with a Vault next to it.") \
				% MachineDB.name_of(String(e["feeder"]))
			go = func() -> void: _show_extension(e)
		"place":
			var id2: String = String(e["id"])
			var cells: int = int(e["cells"])
			pic = Chips.MachineSprite.new(id2, 52.0)
			title = Loc.t("Place a %s") % MachineDB.name_of(id2)
			sub = Loc.tn("It would work on %d tile now: the green one.",
				"It would work on %d tiles now: the green ones.", cells) % cells
			go = func() -> void: _arm_only(id2)
		_:
			pic = _icon_rect("credits", 52)
			title = Loc.t("%s more credits to go down") % Economy.fmt(float(e.get("missing", 0.0)))
			sub = Loc.t("Build more, or make what you have earn more.")
	var b := _setting_row(pic, title, sub)
	b.set_meta("work", String(e["kind"]))
	var arrow := _label("›", 40, Palette.TEXT_DIM)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(b.get_child(0) as HBoxContainer).add_child(arrow)
	b.pressed.connect(func():
		Juice.tap()
		_close_overlay()
		go.call())
	return b


## An "extend" line: the machine armed, the view on its tile, and the tile
## and the Vault's beside it outlined until both are built on.
func _show_extension(e: Dictionary) -> void:
	_work_hint = [int(e["cell"]), int(e["outlet"])]
	_arm_only(String(e["id"]))
	iso_view.focus_cell(int(e["cell"]))
	_refresh_hint()


## Arm a machine for placing, without toggling it off if it already is: the
## green tiles then show where it would work.
func _arm_only(id: String) -> void:
	if _armed != id:
		_arm(id)


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


## What the Foreman says on arriving at stratum `d`: its rules by name, and
## where to see what they do -- the arrows on the tray when a rule moves a
## machine the player has, the stratum's card otherwise.
func _stratum_line(d: int) -> String:
	var mods: Array[String] = Strata.modifiers_for(d)
	if mods.is_empty():
		return Loc.t("Stratum %d. Richer rock, stranger rules.") % d
	var names := PackedStringArray()
	for m: String in mods:
		names.append(Strata.modifier_name(m))
	var st: Dictionary = Strata.describe(d)
	for id: String in Sim.unlocked:
		if Strata.effect_on(id, st) != 0:
			return Loc.t("Stratum %d: %s. The arrows on the tray show what changes.") % [d,
				Loc.t(" and ").join(names)]
	return Loc.t("Stratum %d: %s. The card at the top left says what changes.") % [d,
		Loc.t(" and ").join(names)]


func _tell_yard_news() -> void:
	if _overlay.visible:
		return
	if _band_news >= 0:
		_band_banner(_band_news)
		_band_news = -1
	if _yard_news == "":
		return
	_say(_yard_news, Foreman.Pose.JUMP, 4.0)
	_yard_news = ""


## The name of the band the shaft has just gone down into, across the
## middle of the screen in its own light, while the world changes colour
## behind it. It fades on its own and takes no taps.
func _band_banner(band: int) -> void:
	var l := _label(Loc.upper(Loc.t(BAND_NAMES[band])), 64,
		Color(Palette.BAND_VEIN[band]).lightened(0.25))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.offset_bottom = -size.y * 0.18
	l.modulate.a = 0.0
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


## A centred card over a dimmed world. Sized from the screen, and its body
## scrolls, because a landscape phone is 720 units tall and some of these
## (research, the offline report) are longer than that.
## --- resource nodes --------------------------------------------------------
##
## A tap on a crystal, an ore vein or a heat vent round the yard: a small
## card over it says what it is in a few plain words, whether a machine makes
## its resource, and at which stratum the yard reaches it. Clutter says
## nothing. The words come from `ResourceNodes`; the reach from `BuildArea`.

var _node_card: PanelContainer
var _node_index: int = -1


func _on_node_tapped(index: int) -> void:
	var props: Array = IsoArt.placement().get("props", [])
	if index < 0 or index >= props.size():
		return
	var pr: Array = props[index]
	var info: Dictionary = ResourceNodes.info(String(pr[2]))
	if info.is_empty():
		return
	Juice.tap()
	_close_sheet()
	_close_node_card()
	_node_index = index
	iso_view.selected_node = index

	_node_card = _panel(Palette.PANEL_HI, 0.95)
	_node_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_node_card.add_child(row)
	row.add_child(_prop_picture(String(pr[2]), 72.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_label(Loc.t(String(info["name"])), 21, Palette.CORE))
	col.add_child(_label(Loc.t(String(info["line"])), 16, Palette.TEXT))
	# What uses it: a machine only where one really makes its resource.
	var use := HBoxContainer.new()
	use.add_theme_constant_override("separation", 6)
	use.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if String(info["machine"]) != "":
		use.add_child(Chips.MachineSprite.new(String(info["machine"]), 34.0))
	use.add_child(_label(Loc.t(String(info["use"])), TEXT_MIN, Palette.TEXT_DIM))
	col.add_child(use)
	# When the yard gets there.
	var o: Vector2i = Iso.board_offset()
	var gx: int = int(pr[0]) - o.x
	var gy: int = int(pr[1]) - o.y
	if Grid.in_bounds(gx, gy):
		var when := HBoxContainer.new()
		when.add_theme_constant_override("separation", 6)
		when.mouse_filter = Control.MOUSE_FILTER_IGNORE
		when.add_child(_icon_rect("descend", 26))
		when.add_child(_label(Loc.t("Your yard reaches it at stratum %d.") % BuildArea.opens_at(
			Grid.idx(gx, gy)), TEXT_MIN, Palette.TEXT_DIM))
		col.add_child(when)
	row.add_child(col)
	_hud.add_child(_node_card)
	_place_node_card()


func _close_node_card() -> void:
	if _node_card != null and is_instance_valid(_node_card):
		_node_card.queue_free()
	_node_card = null
	_node_index = -1
	if iso_view != null:
		iso_view.selected_node = -1


## The card stands over its node and follows it as the world moves, kept on
## the screen.
func _place_node_card() -> void:
	if _node_card == null or not is_instance_valid(_node_card) or _node_index < 0:
		return
	if _overlay.visible:
		_close_node_card()
		return
	var pr: Array = IsoArt.placement().get("props", [])[_node_index]
	var r: Rect2 = iso_view.prop_rect(pr)
	var top: Vector2 = iso_view.get_global_transform() * iso_view.cam.world_to_screen(
		r.position + Vector2(r.size.x * 0.5, 0.0))
	var sz: Vector2 = _node_card.get_combined_minimum_size()
	_node_card.size = sz
	var p := Vector2(top.x - sz.x * 0.5, top.y - sz.y - 18.0)
	p.x = clampf(p.x, _safe.x + M, size.x - _safe.z - M - sz.x)
	p.y = clampf(p.y, _safe.y + TOP_H + M, size.y - _safe.w - BOTTOM_H - M - sz.y)
	_node_card.position = p


## A prop's own picture, for the card: the same one the world draws.
func _prop_picture(kind: String, px: float) -> TextureRect:
	var info: Dictionary = IsoArt.layout().get("props", {})
	var a := AtlasTexture.new()
	a.atlas = IsoArt.texture(String(info.get("file", "")))
	a.region = IsoArt.region(info, (info.get("order", []) as Array).find(kind))
	var t := TextureRect.new()
	t.texture = a
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px * 1.2)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _open_overlay(title: String, body: Control, actions: Array,
		max_w: float = 820.0, head_extra: Control = null) -> void:
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
	var w: float = minf(max_w, size.x - 64.0)
	var h: float = minf(size.y - 48.0 - _safe.y - _safe.w, 700.0)
	card.position = Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
	card.size = Vector2(w, h)
	# Shown once it has been fitted to what it holds (`_fit_overlay`).
	card.modulate.a = 0.0
	_overlay.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	# The title, and a close key in the corner where every phone puts one.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var title_lbl := _label(title, 30, Palette.TEXT)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title_lbl)
	if head_extra != null:
		head_extra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(head_extra)
	var close := _button("✕", Palette.PANEL_HI)
	close.add_theme_color_override("font_color", Palette.TEXT)
	close.add_theme_font_size_override("font_size", 30)
	close.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(_close_overlay)
	head.add_child(close)
	col.add_child(head)

	var scroll := ScrollContainer.new()
	_overlay_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	col.add_child(scroll)
	_fit_overlay.call_deferred(card, body, h)

	if actions.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	for a: Dictionary in actions:
		var b := _button(String(a["text"]), a.get("color", Palette.PANEL_HI))
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.custom_minimum_size = Vector2(minf(360.0, w * 0.45), MIN_TOUCH)
		b.add_theme_font_size_override("font_size", Palette.text_px(26))
		if a.has("disabled"):
			b.disabled = bool(a["disabled"])
		var cb: Variant = a.get("cb")
		b.pressed.connect(func():
			_close_overlay()
			if cb is Callable:
				cb.call())
		row.add_child(b)


## A card as tall as what it holds, up to the screen's height: a panel with
## three pictures in it should not be a screen of empty panel. Measured
## after the containers have laid it out, and only then shown.
func _fit_overlay(card: Control, body: Control, max_h: float) -> void:
	for i in range(2):
		await get_tree().process_frame
	if not is_instance_valid(card) or not is_instance_valid(body) \
			or not card.is_inside_tree():
		return
	var scroll: Control = body.get_parent() as Control
	var chrome: float = card.size.y - scroll.size.y
	var want: float = clampf(chrome + body.get_combined_minimum_size().y, 220.0, max_h)
	card.size.y = want
	card.position.y = (size.y - want) * 0.5
	card.create_tween().tween_property(card, "modulate:a", 1.0, 0.12)


func _info(title: String, text: String) -> void:
	var l := _label(text, 20, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_open_overlay(title, l, [])


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
	_sheet_title.text = MachineDB.name_of(id)
	(_sheet_art as Chips.MachineSprite).id = id
	_sheet_art.queue_redraw()

	# The verdict as a picture: all is well, it is too hot or too cold, or
	# something is wrong round it. The words are behind the "?".
	var verdict: String
	var icon: String
	match st:
		Simulation.Status.STARVED:
			verdict = Loc.t("Starved: it is not being fed. Look UPSTREAM.")
			icon = "warning"
		Simulation.Status.BLOCKED:
			verdict = Loc.t("Backed up: nothing takes its output. Look DOWNSTREAM.")
			icon = "warning"
		Simulation.Status.IDLE:
			verdict = Loc.t("Idle. Nothing for it to do.")
			icon = "lock"
		Simulation.Status.PASSIVE:
			verdict = Loc.t("Working by standing there. It has no cycle of its own.")
			icon = "energy"
		_:
			if eff < Simulation.THERMAL_WARNING:
				verdict = (Loc.t("Running, but too hot: giving up %d%% of its output.") if delta > 0.0
					else Loc.t("Running, but too cold: giving up %d%% of its output.")) \
					% int(round((1.0 - eff) * 100.0))
				icon = "heat" if delta > 0.0 else "cold"
			else:
				verdict = Loc.t("Running well.")
				icon = "ok"
	(_sheet_status as TextureRect).texture = IsoArt.icon(icon)
	_sheet_body.add_child(Chips.recipe(id, 42.0))

	# Heat: the bar is the machine's temperature, the notch where it wants to
	# be; red past its tolerance.
	var top: float = float(m["heat_optimum"]) + float(m["heat_tolerance"]) * 1.6 + 1.0
	var hg := Chips.Gauge.new(220, 14)
	hg.value = heat / top
	hg.target = float(m["heat_optimum"]) / top
	hg.fill = Palette.heat_color(heat)
	var heat_row := HBoxContainer.new()
	heat_row.add_theme_constant_override("separation", 8)
	heat_row.add_child(_icon_rect("heat", 30))
	heat_row.add_child(hg)
	_sheet_stats.add_child(heat_row)
	# Busy: how much of the time it is working.
	var wg := Chips.Gauge.new(220, 14)
	wg.value = Sim.sim.uptime_of(cell)
	wg.fill = Palette.GOOD
	var work_row := HBoxContainer.new()
	work_row.add_theme_constant_override("separation", 8)
	work_row.add_child(_icon_rect("upgrade", 30))
	work_row.add_child(wg)
	_sheet_stats.add_child(work_row)

	# Everything the panel used to spell out, for the "?".
	var lines: Array[String] = [verdict]
	var recipe: String = MachineDB.recipe_text(id)
	if recipe != "":
		lines.append(recipe)
	lines.append(MachineDB.desc_of(id))
	lines.append("")
	lines.append(Loc.t("Temperature %.1f (wants %.1f) · thermal output %d%%") % [heat,
		float(m["heat_optimum"]), int(round(eff * 100.0))])
	lines.append(Loc.t("Working %d%% of the time · cycle speed when fed %.2f/s") % [
		int(round(Sim.sim.uptime_of(cell) * 100.0)), Sim.sim.effective_rate(cell)])
	if amp > 1.001:
		lines.append(Loc.t("Neighbour boost +%.0f%%") % ((amp - 1.0) * 100.0))
	_sheet_help = "\n".join(lines)

	_tray.visible = false
	_sheet.visible = true


## What each research line is drawn as: the thing it acts on (a machine, the
## Core, the Foreman who keeps the night shift, or an icon), and the sign of
## what it does to it in the corner.
const RESEARCH_ART := {
	"throughput_1": ["crusher", "energy"],
	"yield_1": ["drill", "upgrade"],
	"value_1": ["vault", "credits"],
	"research_1": ["lab", "research"],
	"heat_tolerance": ["smelter", "heat"],
	"offline_cap": ["@foreman", "star"],
	"offline_rate": ["@foreman", "energy"],
	"core_yield": ["@core", "cores"],
	"blueprint_slots": ["@icon:codex", "upgrade"],
}
## The research grid's columns: three side by side on a landscape phone, two
## where the screen is too narrow for three to keep their pictures big.
const RESEARCH_COLUMNS := 3
const RESEARCH_CARD_MIN_W := 330.0


## Research lines the grid does not offer. Drafting Table sells blueprint
## slots, and no screen saves or loads a blueprint yet: a card that takes
## research and changes nothing the player can see would be a fake. It comes
## back with the blueprint screen; its level, if a save has one, is kept.
const HIDDEN_RESEARCH := Worklist.HIDDEN


func _show_research() -> void:
	# What there is to spend, as the same pictures the prices use, beside the
	# title.
	var wallet := HBoxContainer.new()
	wallet.add_theme_constant_override("separation", 8)
	wallet.add_child(_icon_rect("research", 40))
	wallet.add_child(_label(Economy.fmt(Sim.research), 26, Palette.RESEARCH))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(18, 0)
	wallet.add_child(gap)
	wallet.add_child(_icon_rect("cores", 40))
	wallet.add_child(_label(str(Sim.cores), 26, Palette.CORE))
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(12, 0)
	wallet.add_child(gap2)

	var w: float = minf(1240.0, size.x - 64.0)
	var grid := GridContainer.new()
	grid.columns = RESEARCH_COLUMNS if w >= RESEARCH_CARD_MIN_W * RESEARCH_COLUMNS + 60.0 else 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for id: String in Economy.TREE_ORDER:
		if not HIDDEN_RESEARCH.has(id):
			grid.add_child(_research_card(id))
	_open_overlay(Loc.t("Research"), grid, [], 1240.0, wallet)


## One research line as a card: its picture big, a short name, a line a
## child can read, how far along it is, and its price on the key that buys
## it. A card that can be bought is lit round the edge; a finished one is
## gold; one that needs Cores first is grey with a lock on its picture.
func _research_card(id: String) -> Control:
	var u: Dictionary = Economy.RESEARCH_TREE[id]
	var lvl: int = Sim.upgrade_level(id)
	var top: int = int(u["max"])
	var maxed: bool = lvl >= top
	var c: Dictionary = Economy.upgrade_cost(id, lvl)
	var can: bool = Sim.can_buy_upgrade(id)
	var locked: bool = not maxed and Sim.cores < int(c["cores"])

	var card := _panel(Palette.PANEL_HI, 0.96)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(RESEARCH_CARD_MIN_W, 0)
	var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if maxed:
		sb.border_color = Palette.CORE
		sb.set_border_width_all(3)
	elif can:
		sb.border_color = Palette.RESEARCH
		sb.set_border_width_all(3)
		sb.bg_color = Color(Palette.PANEL_HI.lerp(Palette.RESEARCH, 0.12), 0.96)
	card.set_meta("research_id", id)
	card.set_meta("state", "max" if maxed else ("ready" if can else ("locked" if locked else "short")))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_row.add_child(_research_art(id, 124.0, locked))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 4)
	var name_lbl := _label(Loc.t(String(u["name"])), 21, Palette.TEXT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(name_lbl)
	var short_lbl := _label(Loc.t(String(u.get("short", ""))), 17, Palette.TEXT_DIM)
	short_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(short_lbl)
	# How far along: one pip a level, and the count.
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	for k in range(top):
		pips.add_child(_pip(k < lvl))
	var count := _label("%d/%d" % [lvl, top], 16, Palette.TEXT_FAINT)
	pips.add_child(count)
	words.add_child(pips)
	top_row.add_child(words)
	col.add_child(top_row)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	if maxed:
		var done := HBoxContainer.new()
		done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		done.alignment = BoxContainer.ALIGNMENT_CENTER
		done.custom_minimum_size = Vector2(0, MIN_TOUCH)
		done.add_theme_constant_override("separation", 8)
		done.add_child(_icon_rect("ok", 52))
		done.add_child(_label(Loc.t("MAX"), 26, Palette.CORE))
		bottom.add_child(done)
	else:
		# The price as pictures and numbers on the key that buys it. What is
		# missing is red, so a short card says what to go and get.
		var b := _button("", Palette.RESEARCH)
		b.custom_minimum_size = Vector2(0, MIN_TOUCH)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var price := HBoxContainer.new()
		price.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.add_theme_constant_override("separation", 6)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ok_col: Color = Palette.BG if can else Palette.TEXT
		price.add_child(_icon_rect("research", 42))
		price.add_child(_label(Economy.fmt(float(c["research"])), 24,
			ok_col if Sim.research >= float(c["research"]) else Palette.BAD))
		if int(c["cores"]) > 0:
			price.add_child(_icon_rect("cores", 38))
			price.add_child(_label(str(int(c["cores"])), 24,
				ok_col if Sim.cores >= int(c["cores"]) else Palette.BAD))
		b.add_child(price)
		b.disabled = not can
		b.pressed.connect(func():
			if Sim.buy_upgrade(id):
				Juice.upgrade()
				var keep: int = _overlay_scroll.scroll_vertical if _overlay_scroll != null else 0
				_show_research()
				_refresh()
				await get_tree().process_frame
				if _overlay_scroll != null:
					_overlay_scroll.scroll_vertical = keep)
		bottom.add_child(b)
	var help := _help_button(Loc.t(String(u["name"])), func() -> String:
		var t: String = Loc.t(String(u["desc"]))
		if locked:
			t += "\n\n" + Loc.t("This one also costs Cores. You get Cores when you collapse the shaft.")
		return t)
	help.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	bottom.add_child(help)
	col.add_child(bottom)
	return card


## A research line's picture: what it acts on, big, with the sign of what it
## does in the corner -- or greyed, with a lock, while it needs Cores first.
func _research_art(id: String, px: float, locked: bool) -> Control:
	var art: Array = RESEARCH_ART.get(id, ["@icon:upgrade", "upgrade"])
	var subject: String = String(art[0])
	var box := Control.new()
	box.custom_minimum_size = Vector2(px, px)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic: Control
	if subject == "@foreman":
		pic = Foreman.Badge.new(Foreman.Pose.IDLE, px)
	elif subject == "@core":
		pic = _core_picture(px)
	elif subject.begins_with("@icon:"):
		pic = _icon_rect(subject.substr(6), px * 0.86)
	else:
		pic = Chips.MachineSprite.new(subject, px)
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(pic)
	var sign_name: String = "lock" if locked else String(art[1])
	var k: float = px * (0.56 if locked else 0.46)
	var badge := _icon_rect(sign_name, k)
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.offset_left = -k
	badge.offset_top = -k
	badge.offset_right = 0.0
	badge.offset_bottom = 0.0
	box.add_child(badge)
	if locked:
		pic.modulate = Color(0.5, 0.52, 0.58, 0.8)
	return box


## The Factory Core's picture, for panels that talk about it.
func _core_picture(px: float) -> TextureRect:
	var info: Dictionary = IsoArt.layout().get("core", {})
	var a := AtlasTexture.new()
	a.atlas = IsoArt.texture(String(info.get("file", "")))
	a.region = IsoArt.region(info, 0)
	var t := TextureRect.new()
	t.texture = a
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## One level of a research line: lit if bought.
func _pip(lit: bool) -> Control:
	var d := ColorRect.new()
	d.custom_minimum_size = Vector2(18, 18)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d.color = Palette.RESEARCH if lit else Color(Palette.BG, 0.9)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


## The collapse, as a card: this shaft traded for Cores, big, and what the
## trade takes and leaves as pictures -- crossed out or ticked. Locked, it
## is the Core behind a lock and the strata still to go down.
func _show_collapse() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var need: int = Economy.COLLAPSE_MIN_DEPTH
	if not Economy.can_collapse(Sim.max_depth):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 28)
		row.add_child(_locked_picture(_core_picture(200.0), 200.0))
		# The strata still to go down: one key-sized step each, lit once
		# passed.
		var steps_col := VBoxContainer.new()
		steps_col.alignment = BoxContainer.ALIGNMENT_CENTER
		steps_col.add_theme_constant_override("separation", 10)
		var steps := HBoxContainer.new()
		steps.add_theme_constant_override("separation", 10)
		for d in range(1, need + 1):
			var st := _icon_rect("descend", 84)
			if d > Sim.max_depth:
				st.modulate = Color(0.45, 0.47, 0.52, 0.7)
			steps.add_child(st)
		steps_col.add_child(steps)
		var count := _label("%d / %d" % [mini(Sim.max_depth, need), need], 34, Palette.TEXT)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		steps_col.add_child(count)
		row.add_child(steps_col)
		row.add_child(_help_button(Loc.t("Collapse"), func() -> String:
			return Loc.t("Collapsing the shaft turns everything you have built into Cores, and Cores stay with you into the next shaft.\n\nIt opens at stratum %d. You have reached %d.") % [need, Sim.max_depth]))
		body.add_child(row)
		body.set_meta("state", "locked")
		_open_overlay(Loc.t("Collapse"), body, [], 1000.0)
		return

	var gained: int = Sim.pending_cores()
	# The trade: this shaft, for Cores.
	var trade := HBoxContainer.new()
	trade.alignment = BoxContainer.ALIGNMENT_CENTER
	trade.add_theme_constant_override("separation", 22)
	trade.add_child(_core_picture(190.0))
	trade.add_child(Chips.Arrow.new(80.0))
	trade.add_child(_icon_rect("cores", 140))
	trade.add_child(_label("+%d" % gained, 72, Palette.CORE))
	trade.add_child(_help_button(Loc.t("Collapse the shaft"), func() -> String:
		return Loc.tn("You get %d Core.\n\nGone: the machines, your credits, your research points and your depth.\nKept: your Cores and every upgrade you have researched.\n\nGoing deeper and earning more both raise the Cores. One more stratum is usually worth more than one more hour at this one.",
			"You get %d Cores.\n\nGone: the machines, your credits, your research points and your depth.\nKept: your Cores and every upgrade you have researched.\n\nGoing deeper and earning more both raise the Cores. One more stratum is usually worth more than one more hour at this one.",
			gained) % gained))
	body.add_child(trade)

	# What goes, crossed out; what stays, ticked.
	var fate := HBoxContainer.new()
	fate.alignment = BoxContainer.ALIGNMENT_CENTER
	fate.add_theme_constant_override("separation", 56)
	var gone := HBoxContainer.new()
	gone.add_theme_constant_override("separation", 12)
	for pic: Control in [Chips.MachineSprite.new("drill", 76.0), _icon_rect("credits", 76),
			_icon_rect("research", 76), _icon_rect("descend", 76)]:
		gone.add_child(_fated(pic, 76.0, false))
	fate.add_child(gone)
	var kept := HBoxContainer.new()
	kept.add_theme_constant_override("separation", 12)
	for pic: Control in [_icon_rect("cores", 76), _icon_rect("upgrade", 76)]:
		kept.add_child(_fated(pic, 76.0, true))
	fate.add_child(kept)
	body.add_child(fate)

	# What the Cores are for: the research lines whose Core price the new
	# total reaches and today's does not. They still cost Research, which a
	# collapse takes, so the words say "open", not "buy".
	var opens := HBoxContainer.new()
	opens.alignment = BoxContainer.ALIGNMENT_CENTER
	opens.add_theme_constant_override("separation", 12)
	var opened: Array[String] = _cores_open(gained)
	for id: String in opened:
		opens.add_child(_research_art(id, 64.0, false))
	if not opened.is_empty():
		opens.add_child(_label(Loc.tn("These Cores open this research line.",
			"These Cores open these research lines.", opened.size()), 20, Palette.TEXT_DIM))
		body.add_child(opens)
	body.set_meta("opens", opened)
	body.set_meta("state", "ready" if Sim.can_collapse() else "empty")
	_open_overlay(Loc.t("Collapse"), body,
		[{"text": Loc.t("Collapse"), "color": Palette.CORE, "disabled": not Sim.can_collapse(),
			"cb": func(): Sim.collapse()}], 1000.0)


## The research lines (not yet at their top level) whose next level needs
## more Cores than the player has, and no more than they would have with
## `gained` more.
func _cores_open(gained: int) -> Array[String]:
	return Worklist.cores_open(Sim, gained)


## A picture greyed, with a lock in its corner: not yet.
func _locked_picture(pic: Control, px: float) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(px, px)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic.modulate = Color(0.5, 0.52, 0.58, 0.8)
	box.add_child(pic)
	var k: float = px * 0.48
	var lock := _icon_rect("lock", k)
	lock.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	lock.offset_left = -k
	lock.offset_top = -k
	lock.offset_right = 0.0
	lock.offset_bottom = 0.0
	box.add_child(lock)
	return box


## A picture marked with its fate in a trade: crossed out if it goes, a tick
## in the corner if it stays.
func _fated(pic: Control, px: float, stays: bool) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(px, px)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(pic)
	if stays:
		var k: float = px * 0.46
		var tick := _icon_rect("ok", k)
		tick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		tick.offset_left = -k
		tick.offset_top = -k
		tick.offset_right = 0.0
		tick.offset_bottom = 0.0
		box.add_child(tick)
	else:
		pic.modulate = Color(0.62, 0.62, 0.66, 0.85)
		var x := Chips.Strike.new()
		x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.add_child(x)
	return box


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
	head.add_child(_icon_rect("credits", 72))
	var sum_lbl := _label("+%s" % Economy.fmt(amount), 44, Palette.CORE)
	sum_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sum_lbl)
	var detail: String = Loc.t("The shaft kept running.\n\nAway %s. Counted %s at %d%% of your live rate.") % [away, counted, rate_pct]
	if bool(report.get("capped", false)):
		detail += "\n\n" + Loc.t("Your offline banking is full at %.0f hours. Night Shift in Research raises it.") % Sim.offline_hours()
	head.add_child(_help_button(Loc.t("While you were away"), func() -> String: return detail))
	# The research the Labs banked too: it is added to the purse on return
	# (Save.load_game), so it is shown, beside the credits' own picture.
	var banked_research: float = float(report.get("research", 0.0))
	if banked_research > 0.0:
		var rrow := HBoxContainer.new()
		rrow.add_theme_constant_override("separation", 12)
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(110.0, 0.0)
		rrow.add_child(pad)
		rrow.add_child(_icon_rect("research", 56))
		rrow.add_child(_label("+%s" % Economy.fmt(banked_research), 34, Palette.RESEARCH))
		body.set_meta("research_row", true)
		body.add_child(head)
		body.add_child(rrow)
	else:
		body.add_child(head)

	# And what to do now: the Worklist's first line, as a row to tap.
	var next: Array = Worklist.of(Sim)
	if not next.is_empty() and String(next[0]["kind"]) != "quota":
		body.add_child(_label(Loc.t("Now:"), TEXT_MIN, Palette.TEXT_DIM))
		body.add_child(_work_row(next[0]))
		body.set_meta("next", String(next[0]["kind"]))

	var actions: Array = []
	if Ads.can_offer(Ads.P_DOUBLE_OFFLINE):
		actions.append({
			"text": Loc.t("Ad: x2"),
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
			Loc.t("The Foreman's Licence banks %.0f hours instead of %.0f, permanently, and removes ads.")
			% [Sim.offline_hours() + float(MonetizationDB.grant_value(
				MonetizationDB.LICENCE, MonetizationDB.GRANT_OFFLINE_HOURS, 0.0)),
				Sim.offline_hours()]))
		actions.append({
			"text": Loc.t("Supply Office"),
			"color": Palette.PANEL_HI,
			"cb": func(): _open_shop(),
		})

	_open_overlay(Loc.t("Welcome back"), body, actions)


## Every setting, applied from `Sim.settings` in one place: at start, and
## after any change. Each one does something the player can see or hear;
## there is no switch here for a system the game does not have.
func _apply_settings() -> void:
	var st: Dictionary = Sim.settings
	# An idle game is left running. Uncapped frames on a phone is a warm
	# pocket and a flat battery for a board that changes ten times a second;
	# the battery saver halves it again.
	Engine.max_fps = 30 if bool(st.get("battery_saver", false)) else 60
	Juice.sound_enabled = bool(st.get("sound", true))
	Juice.ambient_enabled = bool(st.get("ambient", true))
	Juice.haptics_enabled = bool(st.get("haptics", true))
	var vol: int = clampi(int(st.get("volume", VOLUME_STEPS)), 0, VOLUME_STEPS)
	AudioServer.set_bus_mute(0, vol == 0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(vol) / float(VOLUME_STEPS), 0.001)))
	if Juice.sound_enabled and Juice.ambient_enabled:
		Juice.start_ambient()
	else:
		Juice.stop_ambient()
	if iso_view != null:
		iso_view.effects = bool(st.get("effects", true))
		iso_view.calm_motion = bool(st.get("reduce_motion", false))
		iso_view.cam.instant = iso_view.calm_motion
	Juice.calm = bool(st.get("reduce_motion", false))
	if _btn_zoom != null:
		_show_what_matters()
	# Only when it changes: a pass over every label is not free.
	var large: bool = bool(st.get("large_text", false))
	if large != _large_text_now:
		_large_text_now = large
		_apply_text_size()


## Settings, in five groups down the left and the switches for the chosen
## one on the right -- the landscape layout every phone game uses. A row is
## one key the size of a thumb: its sign, a few words, and its switch.
const SETTINGS_TABS := [
	{"id": "game", "name": "Game", "icon": "star"},
	{"id": "audio", "name": "Audio", "glyph": "speaker"},
	{"id": "graphics", "name": "Graphics", "glyph": "screen"},
	{"id": "controls", "name": "Controls", "glyph": "hand"},
	{"id": "access", "name": "Accessibility", "glyph": "person"},
]
const VOLUME_STEPS := 5
var _settings_tab: String = "game"
var _settings_page: VBoxContainer
var _settings_keys: Array[Button] = []


func _show_settings() -> void:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.custom_minimum_size = Vector2(0, 530)
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 8)
	rail.custom_minimum_size = Vector2(250, 0)
	_settings_keys.clear()
	for t: Dictionary in SETTINGS_TABS:
		var k := _button("", Palette.PANEL_HI)
		k.toggle_mode = true
		k.custom_minimum_size = Vector2(250, 92)
		k.size_flags_horizontal = Control.SIZE_FILL
		k.set_meta("tab", String(t["id"]))
		var sb: StyleBoxFlat = (k.get_theme_stylebox("pressed") as StyleBoxFlat).duplicate()
		sb.bg_color = Palette.PANEL_HI.lerp(Palette.ACCENT, 0.3)
		sb.border_color = Palette.ACCENT
		sb.set_border_width_all(3)
		k.add_theme_stylebox_override("pressed", sb)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 14
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mark: Control
		if t.has("icon"):
			mark = _icon_rect(String(t["icon"]), 52)
		else:
			mark = Chips.Glyph.new(String(t["glyph"]), 52.0)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(mark)
		var nm := _label(Loc.t(String(t["name"])), 22, Palette.TEXT)
		_fit(nm, 250.0 - 14.0 - 52.0 - 12.0 - 8.0)
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.size_flags_vertical = Control.SIZE_FILL
		row.add_child(nm)
		k.add_child(row)
		var id: String = String(t["id"])
		k.pressed.connect(func():
			Juice.tap()
			_settings_tab = id
			_fill_settings_page())
		_settings_keys.append(k)
		rail.add_child(k)
	var ver := _label("Lodeworks %s" % String(ProjectSettings.get_setting(
		"application/config/version", "")), TEXT_MIN, Palette.TEXT_FAINT)
	ver.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ver.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	rail.add_child(ver)
	body.add_child(rail)

	_settings_page = VBoxContainer.new()
	_settings_page.add_theme_constant_override("separation", 10)
	_settings_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_settings_page)
	_fill_settings_page()
	_open_overlay(Loc.t("Settings"), body, [], 1120.0)


func _fill_settings_page() -> void:
	for k: Button in _settings_keys:
		k.set_pressed_no_signal(String(k.get_meta("tab")) == _settings_tab)
	for c in _settings_page.get_children():
		_settings_page.remove_child(c)
		c.queue_free()
	var page := _settings_page
	match _settings_tab:
		"game":
			# The language first: a player who cannot read the rest finds it
			# by its globe and by its own language's name.
			var chosen: String = String(Sim.settings.get("locale", ""))
			page.add_child(_setting_action(Chips.Glyph.new("globe", 52.0), Loc.t("Language"),
				Loc.name_of(Loc.current()) if chosen != "" \
					else Loc.t("Device language: %s") % Loc.name_of(Loc.current()),
				func(): _show_languages()))
			page.add_child(_setting_action(_icon_rect("codex", 52), Loc.t("Codex"),
				Loc.t("Every machine, and how the factory works"), func():
					_close_overlay()
					_open_codex()))
			var owned: Array[String] = []
			for key: String in MonetizationDB.keys():
				if Store.owns(key):
					owned.append(MonetizationDB.title_of(key))
			# The shop is one row in settings and one offer on the offline
			# panel, and it is reached from nowhere else.
			# `MonetizationDB.PLACEMENTS` is the list and
			# `FORBIDDEN_PLACEMENTS` is what this game refuses to have.
			page.add_child(_setting_action(_icon_rect("shop", 52), Loc.t("Supply Office"),
				Loc.t("Two one-time purchases") if owned.is_empty()
					else Loc.t("Active: %s") % ", ".join(owned),
				func():
					_close_overlay()
					_open_shop()))
			var stats := _setting_switch(_icon_rect("research", 52), Loc.t("Anonymous statistics"),
				Loc.t("No account, no ad ID, nothing personal"), Analytics.enabled, func(on: bool):
					Analytics.set_enabled(on))
			page.add_child(stats)
			# GDPR requires consent to be withdrawable, not just grantable. The
			# ad SDK owns that form; this is the entry point into it.
			if Ads.is_plugin_present():
				page.add_child(_setting_action(_icon_rect("ad", 52), Loc.t("Ad privacy"),
					Loc.t("The ad network's consent form"), func():
						if not Ads.show_privacy_options():
							_toast_msg(Loc.t("The ad SDK did not offer a privacy form."))))
			page.add_child(_setting_action(_icon_rect("ok", 52), Loc.t("Device self test"),
				Loc.t("Frame time, screen, save and plugins"), func():
					_close_overlay()
					_open_diagnostics()))
		"audio":
			page.add_child(_setting_switch(Chips.Glyph.new("speaker", 52.0), Loc.t("Sounds"),
				Loc.t("Taps, machines, descents"), bool(Sim.settings.get("sound", true)),
				func(on: bool): _set_setting("sound", on)))
			page.add_child(_setting_switch(Chips.Glyph.new("wave", 52.0), Loc.t("Ambience"),
				Loc.t("The hum of the shaft"), bool(Sim.settings.get("ambient", true)),
				func(on: bool): _set_setting("ambient", on)))
			page.add_child(_volume_row())
		"graphics":
			page.add_child(_setting_switch(Chips.Glyph.new("sparkle", 52.0), Loc.t("Machine effects"),
				Loc.t("Dust, sparks, steam and coins"), bool(Sim.settings.get("effects", true)),
				func(on: bool): _set_setting("effects", on)))
			page.add_child(_setting_switch(Chips.Glyph.new("battery", 52.0), Loc.t("Battery saver"),
				Loc.t("30 frames a second instead of 60"), bool(Sim.settings.get("battery_saver", false)),
				func(on: bool): _set_setting("battery_saver", on)))
		"controls":
			page.add_child(_setting_switch(Chips.Glyph.new("vibrate", 52.0), Loc.t("Vibration"),
				Loc.t("A small buzz when you build"), bool(Sim.settings.get("haptics", true)),
				func(on: bool): _set_setting("haptics", on)))
		"access":
			page.add_child(_setting_switch(Chips.Glyph.new("zoom", 52.0), Loc.t("Zoom key"),
				Loc.t("A zoom key, for playing without pinching"),
				bool(Sim.settings.get("zoom_key", false)),
				func(on: bool): _set_setting("zoom_key", on)))
			page.add_child(_setting_switch(Chips.Glyph.new("motion", 52.0), Loc.t("Reduce motion"),
				Loc.t("No swelling, flickering or plunging"),
				bool(Sim.settings.get("reduce_motion", false)),
				func(on: bool): _set_setting("reduce_motion", on)))
			page.add_child(_setting_switch(Chips.Glyph.new("text", 52.0), Loc.t("Larger text"),
				Loc.t("Every word a quarter bigger"),
				bool(Sim.settings.get("large_text", false)),
				func(on: bool): _set_setting("large_text", on)))


## The languages, each written in itself, and "the device's" at the top. A
## tap switches at once; the current one is ticked.
func _show_languages() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.set_meta("languages", Loc.ready_codes())
	var chosen: String = String(Sim.settings.get("locale", ""))
	var rows: Array = [["", Loc.t("Device language")]]
	for code: String in Loc.ready_codes():
		rows.append([code, Loc.name_of(code)])
	for r: Array in rows:
		var code: String = String(r[0])
		var b := _setting_row(Chips.Glyph.new("globe", 44.0), String(r[1]), "")
		b.set_meta("locale", code)
		if code == chosen:
			var tick := _icon_rect("ok", 44)
			tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			(b.get_child(0) as HBoxContainer).add_child(tick)
		b.pressed.connect(func():
			Juice.tap()
			_close_overlay()
			_set_language(code)
			_settings_tab = "game"
			_show_settings())
		body.add_child(b)
	_open_overlay(Loc.t("Language"), body, [], 760.0)


func _set_setting(key: String, value: Variant) -> void:
	Sim.settings[key] = value
	_apply_settings()
	Save.save_game(Sim)


## A row that switches something on or off: the whole row is the key.
func _setting_switch(mark: Control, title: String, sub: String, value: bool,
		changed: Callable) -> Button:
	var b := _setting_row(mark, title, sub)
	b.toggle_mode = true
	b.set_pressed_no_signal(value)
	b.set_meta("setting", title)
	var sw := Chips.Switch.new(value)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(b.get_child(0) as HBoxContainer).add_child(sw)
	b.toggled.connect(func(on: bool):
		Juice.tap()
		sw.on = on
		sw.queue_redraw()
		changed.call(on))
	return b


## A row that opens something.
func _setting_action(mark: Control, title: String, sub: String, cb: Callable) -> Button:
	var b := _setting_row(mark, title, sub)
	var go := _label("›", 40, Palette.TEXT_DIM)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(b.get_child(0) as HBoxContainer).add_child(go)
	b.pressed.connect(func():
		Juice.tap()
		cb.call())
	return b


func _setting_row(mark: Control, title: String, sub: String) -> Button:
	var b := _button("", Palette.PANEL_HI)
	b.custom_minimum_size = Vector2(0, MIN_TOUCH)
	# A toggled row looks like any other; the switch shows the state.
	b.add_theme_stylebox_override("pressed", b.get_theme_stylebox("normal"))
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(_label(title, 22, Palette.TEXT))
	if sub != "":
		words.add_child(_label(sub, TEXT_MIN, Palette.TEXT_DIM))
	row.add_child(words)
	b.add_child(row)
	return b


## Volume in five steps, with a key either side: a slider's grabber is too
## small for a thumb.
func _volume_row() -> Control:
	var b := _setting_row(Chips.Glyph.new("speaker", 52.0), Loc.t("Volume"), "")
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = b.get_child(0) as HBoxContainer
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 6)
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var draw_bars := func() -> void:
		var v: int = clampi(int(Sim.settings.get("volume", VOLUME_STEPS)), 0, VOLUME_STEPS)
		for i in range(bars.get_child_count()):
			(bars.get_child(i) as ColorRect).color = Palette.ACCENT if i < v else Color(Palette.BG, 0.9)
	for i in range(VOLUME_STEPS):
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(18, 20 + 6 * i)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bars.add_child(bar)
	draw_bars.call()
	for step: int in [-1, 1]:
		var k := _button("-" if step < 0 else "+", Palette.PANEL)
		k.add_theme_color_override("font_color", Palette.TEXT)
		k.add_theme_font_size_override("font_size", 34)
		k.custom_minimum_size = Vector2(MIN_TOUCH, 80)
		k.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		k.set_meta("volume_step", step)
		k.pressed.connect(func():
			var v: int = clampi(int(Sim.settings.get("volume", VOLUME_STEPS)) + step, 0, VOLUME_STEPS)
			_set_setting("volume", v)
			draw_bars.call()
			Juice.tap())
		if step < 0:
			row.add_child(k)
			row.add_child(bars)
		else:
			row.add_child(k)
	return b


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
