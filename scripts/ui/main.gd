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
## The side menu's Core key's picture: the Core's stage now.
var _rail_core_pic: TextureRect
var _rail_core_file: String = ""
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
## The machine sheet's level key (machine levels, capped by the Core).
var _sheet_up: Button
## The key under it that drives the type past its level (Overdrive).
var _sheet_drive: Button
## The machine sheet's mode key (MachineDB.Mode), opened by the Core.
var _sheet_mode: Button
## The machine sheet's job key (MachineDB.JOBS): what this one tile makes.
var _sheet_job: Button
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
	Sim.core_upgraded.connect(func(level: int):
		Juice.upgrade()
		iso_view.pulse_core()
		iso_view.foreman_visit(-1, Foreman.Pose.JUMP, 5.0)
		var words: String = Loc.t("The Core is level %d. The shaft can go down to stratum %d, and machines up to level %d.") \
			% [level, Sim.depth_cap(), Sim.machine_level_cap()]
		if level == Operations.FIRST_SITE_CORE:
			# The first gallery: the Foreman's Rig has somewhere to go.
			words = Loc.t("The first gallery past the yard is open. Send the Core's Rig in: it comes home with what the old workings held.")
		elif level == MachineDB.RIG_CORE:
			# The crew's first contact: what it is, and the one step to it.
			words = Loc.t("The Core can keep a crew now. Set an Assembler to Rig Frame: its Rigs walk to the Core, and from there into the galleries.")
		_show_core_up(level, words))
	Sim.contract_filled.connect(func(_i: int, paid: float, pays: String):
		Juice.income()
		_toast_msg(Loc.t("Contract filled: +%s credits") % Economy.fmt(paid) if pays == "credits"
			else Loc.t("Contract filled: +%s research") % Economy.fmt(paid)))
	Sim.sortie_back.connect(func(rep: Dictionary):
		Juice.income()
		iso_view.deliver(rep)
		var where: String = Loc.t(String(Operations.KINDS[String(rep["kind"])]["name"]))
		if bool(rep["cleared"]):
			_toast_msg(Loc.t("Rigs home from the %s, cleared: +%s credits, +%s research, +%d salvage")
				% [where, Economy.fmt(float(rep["credits"])), Economy.fmt(float(rep["research"])),
				int(rep["salvage"])])
		else:
			_toast_msg(Loc.t("Rigs home from the %s, not cleared: +%s credits, +%s research")
				% [where, Economy.fmt(float(rep["credits"])), Economy.fmt(float(rep["research"]))]))
	Sim.region_opened.connect(_on_region_opened)
	Sim.beacon_lit.connect(_on_beacon_lit)
	Sim.beacons_dimmed.connect(func(dark: bool):
		if dark:
			_say(Loc.t("The Beacons have gone dark: the store has no Lenses for them."), Foreman.Pose.ALERT, 6.0)
		else:
			_say(Loc.t("The Beacons burn again."), Foreman.Pose.POINT, 4.0))
	Sim.machine_upgraded.connect(func(id: String, _level: int):
		# The crew goes out to the machines it levelled (IsoView.service).
		iso_view.service(id))
	Sim.machine_upgraded.connect(func(id: String, level: int):
		Juice.upgrade()
		if iso_view.selected_cell >= 0 and Sim.grid.machine_at(iso_view.selected_cell) == id:
			_show_cell_info(iso_view.selected_cell))
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
	# A gallery mouth: the galleries, where the sites are.
	iso_view.site_tapped.connect(func(i: int):
		# A region's way in: the map while it is sealed, the galleries once
		# it is open.
		var reg: String = Operations.slot_region(i)
		if reg != "" and not Sim.region_open(reg):
			_show_map()
		else:
			_show_galleries())
	iso_view.bay_tapped.connect(func(): _show_bay())
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


## The first stratum of each of the four bands (Palette.band_at).
const BAND_FIRST := [0, 4, 10, 17]


## The shaft's map (the side menu's Map): the four bands top to bottom, each
## its own world -- its picture, its strata, the machines found there --
## with the factory's place marked and how far the Core lets it go. The
## pictures are the bands' own paintings, loaded while the map is open.
func _show_map() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var here: int = int(Palette.band_at(Sim.depth)[0])
	var worlds: Array = IsoArt.layout().get("worlds", [])
	for b in range(4):
		var first: int = int(BAND_FIRST[b])
		var last: int = int(BAND_FIRST[b + 1]) - 1 if b < 3 else -1
		var vein := Color(Palette.BAND_VEIN[b])
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Palette.PANEL_HI, 0.95) if b == here else Color(Palette.PANEL, 0.9)
		sb.set_corner_radius_all(16)
		sb.set_border_width_all(4 if b == here else 0)
		sb.border_color = vein
		sb.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", sb)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var pic := TextureRect.new()
		if b < worlds.size() and ResourceLoader.exists(String(worlds[b])):
			pic.texture = load(String(worlds[b]))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.custom_minimum_size = Vector2(230, 128)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if first > Sim.max_depth:
			pic.modulate = Color(0.45, 0.45, 0.5)
		row.add_child(pic)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 2)
		words.add_child(_label(Loc.t(BAND_NAMES[b]), 26, vein.lightened(0.2)))
		words.add_child(_label(Loc.t("Strata %d-%d") % [first, last] if last >= 0
			else Loc.t("Stratum %d and down") % first, TEXT_MIN, Palette.TEXT_DIM))
		var state: String
		var col: Color = Palette.TEXT
		if b == here:
			state = Loc.t("The factory is here, on stratum %d") % Sim.depth
			col = Palette.CORE
		elif first <= Sim.max_depth:
			state = Loc.t("Reached")
			col = Palette.TEXT_DIM
		elif first <= Sim.depth_cap():
			state = Loc.t("Open to the factory: Descend to reach it")
		else:
			state = Loc.t("The Core's level %d reaches it") % CoreLevels.level_for_depth(first)
			col = Palette.TEXT_DIM
		var st := _label(state, 20, col)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(st)
		# The machines found in the band: shown once found, a lock until then.
		var found := HBoxContainer.new()
		found.add_theme_constant_override("separation", 4)
		for id: String in MachineDB.ORDER:
			var at: int = int(MachineDB.get_machine(id).get("unlock_depth", 0))
			if at < first or (last >= 0 and at > last):
				continue
			if Sim.is_unlocked(id):
				found.add_child(Chips.MachineSprite.new(id, 40.0))
			else:
				found.add_child(_icon_rect("lock", 34))
		if found.get_child_count() > 0:
			words.add_child(found)
		row.add_child(words)
		card.add_child(row)
		body.add_child(card)
	body.add_child(_regions_box())
	# The galleries under the yard: where the crew goes.
	if Operations.slots(Sim.core_level) > 0:
		var sites: int = 0
		for i in range(Sim.ops_board.size()):
			if Sim.site(i).has("kind"):
				sites += 1
		var gal := _label(Loc.t("The galleries: %d sites open, %d cleared in all") % [
			sites, Sim.ops_lifetime], 20, Palette.TEXT_DIM)
		gal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(gal)
	_open_overlay(Loc.t("Map"), body, [], 820.0)


## The picture each region of the deep map is shown with: the band
## painting whose ground it shares.
const REGION_ART := {"sunken": 1, "caverns": 3, "foundry": 2, "reach": 3}


## The deep map on the shaft's map (Operations, "regions"): three regions,
## what each holds and asks of the crew, what it gives the factory for good,
## and for one the Core has room to open, the expedition that opens it.
func _regions_box() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.set_meta("regions", true)
	box.add_child(_label(Loc.t("The deep map"), 26, Palette.CORE))
	if Sim.core_level < Operations.REGION_CORE:
		var later := _label(Loc.t("At the Core's level %d, three regions past the galleries open to expeditions: water, rock and danger, each with its own sites, research and gift to the factory.")
			% Operations.REGION_CORE, TEXT_MIN, Palette.TEXT_DIM)
		later.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(later)
		return box
	var room: int = Operations.region_room(Sim.core_level) - Sim.regions_open.size()
	var lead := _label(Loc.t("Regions open: %d of the %d the Core has room for. Which first is yours to choose.")
		% [Sim.regions_open.size(), Operations.region_room(Sim.core_level)], TEXT_MIN, Palette.TEXT_DIM)
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lead)
	if not Sim.beacons.is_empty():
		var lamps := _label(Loc.t("Beacons dark: the store has no Lenses for them.") if Sim.beacons_dark
			else Loc.t("Beacons: %d burning, %d Lenses an hour from the store") % [Sim.beacons.size(),
				int(Sim.beacon_upkeep())], 20, Palette.WARN if Sim.beacons_dark else Palette.CORE)
		lamps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lamps.set_meta("beacons", Sim.beacons.size())
		box.add_child(lamps)
	var worlds: Array = IsoArt.layout().get("worlds", [])
	for r: String in Operations.REGION_ORDER:
		var reg: Dictionary = Operations.REGIONS[r]
		var open: bool = Sim.region_open(r)
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Palette.PANEL_HI, 0.95) if open else Color(Palette.PANEL, 0.9)
		sb.set_corner_radius_all(16)
		sb.set_border_width_all(4 if open else 0)
		sb.border_color = Palette.CORE
		sb.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", sb)
		card.set_meta("region", r)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var pic := TextureRect.new()
		var k: int = int(REGION_ART[r])
		if k < worlds.size() and ResourceLoader.exists(String(worlds[k])):
			pic.texture = load(String(worlds[k]))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.custom_minimum_size = Vector2(200, 112)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not open:
			pic.modulate = Color(0.55, 0.55, 0.6)
		row.add_child(pic)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 2)
		words.add_child(_label(Loc.t(String(reg["name"])), 24, Palette.TEXT))
		for line: String in [Loc.t(String(reg["short"])), Loc.t("For good: %s") % Loc.t(String(reg["advantage"])),
				Loc.t("Research: %s") % Loc.t(String(Economy.RESEARCH_TREE[String(reg["research"])]["name"]))]:
			var l := _label(line, TEXT_MIN, Palette.TEXT_DIM)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			words.add_child(l)
		row.add_child(words)
		col.add_child(row)
		if open:
			col.add_child(_region_state(r))
		elif Sim.site_busy(Operations.region_slot(r)):
			col.add_child(_label(Loc.t("An expedition is out."), 20, Palette.CORE))
		elif Sim.core_level < Operations.region_core(r):
			var later2 := _label(Loc.t("The Core's level %d opens the way, once %d Beacons burn.")
				% [Operations.region_core(r), Operations.REACH_LIGHT], 20, Palette.TEXT_DIM)
			later2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(later2)
		elif room <= 0:
			col.add_child(_label(Loc.t("The Core's next level has room for it."), 20, Palette.TEXT_DIM))
		elif r == "reach" and Sim.lit_beacons() < Operations.REACH_LIGHT:
			var dark := _label(Loc.t("%d Beacons must burn to light the way; %d do.")
				% [Operations.REACH_LIGHT, Sim.lit_beacons()], 20, Palette.WARN)
			dark.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(dark)
		else:
			col.add_child(_expedition_row(r))
		card.add_child(col)
		box.add_child(card)
	return box


## The expedition that opens region `r`: its survey's strength, the team,
## the cost, and the key that sends it.
func _expedition_row(r: String) -> Control:
	var s: Dictionary = Sim.survey_site(r)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_meta("expedition", r)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cost: String = Loc.t("An expedition: %d s out and back, three times the fuel") % int(Operations.SURVEY_TRIP)
	if Sim.expedition_lenses() > 0:
		cost += Loc.t(", and %d Lenses") % Sim.expedition_lenses()
	var cl := _label(cost, TEXT_MIN, Palette.TEXT_DIM)
	cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(cl)
	var tag: String = _terrain_words(s)
	if tag != "":
		var tl := _label(tag, TEXT_MIN, Palette.WARN)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(tl)
	var need := _label("", TEXT_MIN, Palette.TEXT)
	need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(need)
	row.add_child(words)
	var start: Vector3i = Sim.expedition_team(r)
	if _sortie_pick.has(r):
		start = _sortie_pick[r]
	_ops_reopen = _show_map
	return _team_line(row, _team_picker(s, start, r, need,
			func(n: int, b: int, v: int) -> String: return Sim.expedition_blocker(r, n, b, v),
			func(n: int, b: int, v: int) -> bool: return Sim.send_expedition(r, n, b, v),
			func(n: int, b: int, v: int) -> int: return Sim.expedition_fuel(n, b, v)))


## An open region's state on its card: explored, or held by a Beacon (and
## the key that puts it out), or the Beacon that would hold it.
func _region_state(r: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.add_child(_label(Loc.t("Open: its sites are on the galleries' board."), 20, Palette.CORE))
	if Sim.beacons.has(r):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.set_meta("beacon_lit", r)
		var tech: String = Loc.t(String(Operations.CONTROL_TECH[r]))
		var lit := _label((Loc.t("Its Beacon is dark, with no Lenses in the store: %s") if Sim.beacons_dark
			else Loc.t("A Beacon burns: %s")) % tech, 20, Palette.WARN if Sim.beacons_dark else Palette.CORE)
		lit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lit)
		var out := _button(Loc.t("Put it out"), Palette.PANEL)
		out.custom_minimum_size = Vector2(170, MIN_TOUCH)
		out.set_meta("douse", r)
		out.pressed.connect(func():
			if Sim.douse_beacon(r):
				Juice.tap()
				_show_map())
		row.add_child(out)
		col.add_child(row)
	elif Sim.core_level >= Operations.CONTROL_CORE:
		col.add_child(_beacon_row(r))
	return col


## The Beacon that would hold region `r` (Operations, "Beacons"): its
## ground's strength, the team, the price and the upkeep, what it gives,
## and the key that sends it.
func _beacon_row(r: String) -> Control:
	var s: Dictionary = Sim.beacon_site(r)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_meta("beacon", r)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for line: String in [
			Loc.t("Hold it with a Beacon: %d Lenses, %d an hour to keep it lit, and a Surveyor stays to keep it.")
				% [Sim.beacon_lenses(), int(Operations.BEACON_UPKEEP)],
			Loc.t("While it burns: %s") % Loc.t(String(Operations.CONTROL_TECH[r])),
			Loc.t("Its sites pay half again, from every tier, and its research goes %d levels further.")
				% Operations.CONTROL_LINE]:
		var l := _label(line, TEXT_MIN, Palette.TEXT_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(l)
	var tag: String = _terrain_words(s)
	if tag != "":
		var tg := _label(tag, TEXT_MIN, Palette.WARN)
		tg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(tg)
	var need := _label("", TEXT_MIN, Palette.TEXT)
	need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(need)
	row.add_child(words)
	var pick: String = "beacon:" + r
	var start: Vector3i = Sim.beacon_team(r)
	if _sortie_pick.has(pick):
		start = _sortie_pick[pick]
	_ops_reopen = _show_map
	return _team_line(row, _team_picker(s, start, pick, need,
			func(n: int, b: int, v: int) -> String: return Sim.beacon_blocker(r, n, b, v),
			func(n: int, b: int, v: int) -> bool: return Sim.send_beacon(r, n, b, v),
			func(n: int, b: int, v: int) -> int: return Sim.expedition_fuel(n, b, v)))


## A Beacon lit: its reward card -- what the held region gives, what it
## burns, and, with the second, the way into the Dark Reach.
func _on_beacon_lit(r: String) -> void:
	var reg: Dictionary = Operations.REGIONS[r]
	iso_view.foreman_visit(-1, Foreman.Pose.JUMP, 5.0)
	Juice.upgrade()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.set_meta("beacon_lit", r)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	var pic := TextureRect.new()
	var worlds: Array = IsoArt.layout().get("worlds", [])
	var k: int = int(REGION_ART[r])
	if k < worlds.size() and ResourceLoader.exists(String(worlds[k])):
		pic.texture = load(String(worlds[k]))
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.custom_minimum_size = Vector2(260, 146)
	pic.modulate = Color(1.15, 1.05, 0.85)
	top.add_child(pic)
	var said := VBoxContainer.new()
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	said.add_theme_constant_override("separation", 6)
	said.add_child(_label(Loc.t(String(reg["name"])), 28, Palette.CORE))
	var lines: Array[String] = [Loc.t("While it burns: %s") % Loc.t(String(Operations.CONTROL_TECH[r])),
		Loc.t("Its sites pay half again, from every tier, and its research goes %d levels further.")
			% Operations.CONTROL_LINE,
		Loc.t("A Surveyor keeps it, and it burns %d Lenses an hour from the store; with none, every Beacon goes dark.")
			% int(Operations.BEACON_UPKEEP)]
	if Sim.lit_beacons() >= Operations.REACH_LIGHT and not Sim.region_open("reach"):
		lines.append(Loc.t("%d Beacons burn: the way into the Dark Reach is lit.") % Sim.lit_beacons())
	for line: String in lines:
		var l := _label(line, 20, Palette.TEXT_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.add_child(l)
	top.add_child(said)
	var badge := Foreman.Badge.new(Foreman.Pose.JUMP, 110.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(badge)
	body.add_child(top)
	_open_overlay(Loc.t("A Beacon burns!"), body, [{"text": Loc.t("Onward"), "color": Palette.CORE}], 900.0)


## What a Core level opens on the deep map, in words.
func _deep_opens(o: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if bool(o.get("regions", false)):
		out.append(Loc.t("And the deep map: three regions past the galleries. An expedition led by a Surveyor opens one; which first is the shaft's choice."))
	if bool(o.get("beacons", false)):
		out.append(Loc.t("And Beacons: an open region held by a lamp and a Surveyor pays more, researches further and gives its own work -- while the store has Lenses to burn."))
	if bool(o.get("reach", false)):
		out.append(Loc.t("And the Dark Reach: a fourth region, lit by two Beacons, where only a Surveyor finds the way."))
	return out


## A region opened: the reward, as the Core's levels have theirs -- the
## region, what it gives the factory for good, what it opens, the Foreman.
func _on_region_opened(r: String) -> void:
	var reg: Dictionary = Operations.REGIONS[r]
	iso_view.foreman_visit(-1, Foreman.Pose.JUMP, 5.0)
	Juice.upgrade()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.set_meta("region_opened", r)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	var pic := TextureRect.new()
	var worlds: Array = IsoArt.layout().get("worlds", [])
	var k: int = int(REGION_ART[r])
	if k < worlds.size() and ResourceLoader.exists(String(worlds[k])):
		pic.texture = load(String(worlds[k]))
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.custom_minimum_size = Vector2(260, 146)
	top.add_child(pic)
	var said := VBoxContainer.new()
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	said.add_theme_constant_override("separation", 6)
	said.add_child(_label(Loc.t(String(reg["name"])), 28, Palette.CORE))
	for line: String in [Loc.t("For good: %s") % Loc.t(String(reg["advantage"])),
			Loc.t("Its sites are on the galleries' board, and its research line is open: %s.")
				% Loc.t(String(Economy.RESEARCH_TREE[String(reg["research"])]["name"])),
			Loc.t("The Umbrite the crew brings home becomes Prisms in a Prism Cutter -- an Assembler on its new job, beside the Core, with a Rig posted to feed it two Lenses to each.")
				if r == "reach" else
			Loc.t("The Resonite the crew brings home becomes Lenses in a Lens Grinder -- an Assembler on its new job, beside the Core, with a Rig posted to feed it.")]:
		var l := _label(line, 20, Palette.TEXT_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.add_child(l)
	top.add_child(said)
	var badge := Foreman.Badge.new(Foreman.Pose.JUMP, 110.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(badge)
	body.add_child(top)
	_open_overlay(Loc.t("A region opened!"), body, [{"text": Loc.t("Onward"), "color": Palette.CORE}], 900.0)


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


## The game's menu, down the right-hand side, as the reference games keep
## theirs: a picture and a word a key -- the tasks, the Core, the crew and
## their Bay, the sorties -- then the heat view and the problems. Two keys a
## row: three rows fit the height a landscape phone with a notch and a
## gesture bar leaves between the top panels and the Descend key
## (tools/layout_check.tscn). The shaft's map is with Research, bottom left.
func _build_tools() -> Control:
	var col := GridContainer.new()
	col.columns = 2
	col.add_theme_constant_override("h_separation", 6)
	col.add_theme_constant_override("v_separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# What to do now, ranked (Worklist): first on the menu, because after
	# the tutorial it is the answer to the question the tutorial answered.
	_btn_worklist = _rail_key(Chips.Glyph.new("tasks", 46.0), Loc.t("Tasks"))
	_btn_worklist.tooltip_text = Loc.t("What now?")
	_btn_worklist.pressed.connect(func():
		Juice.tap()
		_show_worklist())
	col.add_child(_btn_worklist)

	# The Core as it stands now: its stage's picture (IsoView.core_info).
	_rail_core_pic = _core_picture(46.0)
	var core_key := _rail_key(_rail_core_pic, Loc.t("Core"))
	core_key.pressed.connect(func():
		Juice.tap()
		_show_core())
	col.add_child(core_key)

	# The crew: the Rig Bay, where Rigs are posted to machines.
	var crew_key := _rail_key(_sheet_picture("crew", "idle", 46.0), Loc.t("Crew"))
	crew_key.pressed.connect(func():
		Juice.tap()
		_show_bay())
	col.add_child(crew_key)

	# The sorties: the galleries and their sites.
	var sortie_key := _rail_key(_sheet_picture("galleries", "open", 46.0), Loc.t("Sorties"))
	sortie_key.pressed.connect(func():
		Juice.tap()
		_show_galleries())
	col.add_child(sortie_key)

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
	var hic := _icon_rect("heat", 42)
	_heat_icon = hic
	_btn_heat.add_child(_rail_face(hic, Loc.t("Heat")))
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
	_btn_problems.add_child(_rail_face(_icon_rect("warning", 40), Loc.t("Problems")))
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


## A key of the side menu: `pic` over `caption`.
func _rail_key(pic: Control, caption: String) -> Button:
	var b := _button("", Palette.PANEL_HI)
	b.custom_minimum_size = Vector2(TOOL_W, MIN_TOUCH)
	b.add_child(_rail_face(pic, caption))
	return b


func _rail_face(pic: Control, caption: String) -> Control:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	var l := _label(caption, TEXT_MIN, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fit(l, TOOL_W - 8.0)
	box.add_child(l)
	return box


## One frame of a sprite sheet in layout.json (the crew, the galleries), as
## a picture `px` square.
func _sheet_picture(key: String, frame: String, px: float) -> TextureRect:
	var info: Dictionary = IsoArt.layout().get(key, {})
	var t := TextureRect.new()
	var k: int = (info.get("order", []) as Array).find(frame)
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	if tex != null and k >= 0:
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = IsoArt.region(info, k)
		t.texture = a
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


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
	# The shaft's map: the four bands, where the factory is, what each holds.
	var map_key := _icon_button("descend", Loc.t("Map"), Palette.PANEL_HI)
	map_key.pressed.connect(func():
		Juice.tap()
		_show_map())
	row.add_child(map_key)
	# The shop, one tap from the board as in the reference games: the two
	# one-time purchases (also in Settings).
	var shop_key := _icon_button("shop", Loc.t("Shop"), Palette.PANEL_HI)
	shop_key.pressed.connect(_open_shop)
	row.add_child(shop_key)
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

	# How hard this one machine is run (MachineDB.Mode), a tap a step.
	_sheet_mode = _button("", Palette.PANEL)
	_sheet_mode.custom_minimum_size = Vector2(140, MIN_TOUCH)
	_sheet_mode.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sheet_mode.pressed.connect(func():
		var cell: int = iso_view.selected_cell
		if cell < 0:
			return
		var modes: Array[int] = MachineDB.modes_for(Sim.grid.machine_at(cell))
		var next: int = modes[(modes.find(Sim.grid.mode_at(cell)) + 1) % modes.size()]
		if Sim.set_mode(cell, next):
			Juice.tap()
			_show_cell_info(cell)
			_refresh())
	# What this one machine makes (MachineDB.JOBS), a tap for the next job
	# the shaft has opened.
	_sheet_job = _button("", Palette.PANEL)
	_sheet_job.custom_minimum_size = Vector2(140, MIN_TOUCH)
	_sheet_job.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sheet_job.pressed.connect(func():
		var cell: int = iso_view.selected_cell
		if cell < 0:
			return
		var next: String = _next_job(cell)
		if next != Sim.grid.job_at(cell) and Sim.set_job(cell, next):
			Juice.tap()
			_show_cell_info(cell)
			_refresh())
	var mode_col := VBoxContainer.new()
	mode_col.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_col.add_theme_constant_override("separation", 6)
	mode_col.add_child(_sheet_mode)
	mode_col.add_child(_sheet_job)
	row.add_child(mode_col)
	# The machine type's level, and the key that raises it; under it, from
	# the Core's level MachineDB.OVERDRIVE_CORE, the key that drives it.
	var keys := VBoxContainer.new()
	keys.alignment = BoxContainer.ALIGNMENT_CENTER
	keys.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	keys.add_theme_constant_override("separation", 6)
	_sheet_up = _button("", Palette.RESEARCH)
	_sheet_up.custom_minimum_size = Vector2(170, MIN_TOUCH)
	_sheet_up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sheet_up.pressed.connect(func():
		var cell: int = iso_view.selected_cell
		if cell >= 0 and Sim.upgrade_machine(Sim.grid.machine_at(cell)):
			_refresh())
	keys.add_child(_sheet_up)
	_sheet_drive = _button("", Palette.CORE)
	_sheet_drive.custom_minimum_size = Vector2(170, MIN_TOUCH)
	_sheet_drive.pressed.connect(func():
		var cell: int = iso_view.selected_cell
		if cell >= 0 and Sim.overdrive_machine(Sim.grid.machine_at(cell)):
			iso_view.service(Sim.grid.machine_at(cell))
			Juice.tap()
			_show_cell_info(cell)
			_refresh())
	keys.add_child(_sheet_drive)
	row.add_child(keys)
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
func _help_button(title: String, text: Callable, actions: Callable = Callable()) -> Button:
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
		_info(head, t, actions.call() if actions.is_valid() else []))
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
			iso_view.foreman_visit(cell, Foreman.Pose.POINT, 2.0)
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
	if Sim.descent_needs_core():
		# The quota is met; the Core's level is what stands in the way.
		Juice.tap()
		_show_core()
		return
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
	iso_view.foreman_visit(-1, Foreman.Pose.CHEER, 4.0)

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


## The Core's new level, as the reward it is: the Core as it stands now
## (a new stage at 4, 7 and 10), the Foreman's word, what the level opened,
## and the first things the next one asks for -- each a tap that goes to do
## it, so the card that celebrates is also the answer to "what now?".
func _show_core_up(level: int, words: String) -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.set_meta("core_up", level)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.add_child(_core_picture(170.0))
	var said := VBoxContainer.new()
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	said.add_theme_constant_override("separation", 6)
	said.alignment = BoxContainer.ALIGNMENT_CENTER
	if CoreLevels.era(level) != "":
		said.add_child(_label(Loc.t(CoreLevels.era(level)), 28, Palette.CORE))
	if level in [4, 7, 10]:
		said.add_child(_label(Loc.t("The Core has grown: see it on the board."), 20, Palette.TEXT))
	var w := _label(words, 20, Palette.TEXT_DIM)
	w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.add_child(w)
	top.add_child(said)
	var badge := Foreman.Badge.new(Foreman.Pose.CHEER, 110.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(badge)
	body.add_child(top)
	# What it opened: the same words the Core card used for it.
	var o: Dictionary = CoreLevels.opens(level)
	var opened := HBoxContainer.new()
	opened.add_theme_constant_override("separation", 10)
	opened.add_child(_icon_rect("descend", 40))
	var ol := _label(Loc.t("It opens strata %d to %d, machine level %d and a store of %d.") % [
		int(o["strata"][0]), int(o["strata"][1]), int(o["machine_cap"]), int(o["stock_cap"])],
		TEXT_MIN, Palette.TEXT_DIM)
	ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opened.add_child(ol)
	for id: String in (o["machines"] as Array).slice(0, 3):
		opened.add_child(Chips.MachineSprite.new(id, 40.0))
	for _id: String in (o["research"] as Array).slice(0, 2):
		opened.add_child(_icon_rect("research", 34))
	body.add_child(opened)
	for deep_words: String in _deep_opens(o):
		var deep := _label(deep_words, 20, Palette.CORE)
		deep.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(deep)
	# The next level: its first rows not met, each a tap.
	var next: Array = []
	for st: Dictionary in Sim.core_status():
		if not bool(st["met"]):
			next.append(st)
	if not next.is_empty():
		body.add_child(_label(Loc.t("Next, for level %d:") % (level + 1), 22, Palette.TEXT))
		for st: Dictionary in next.slice(0, 3):
			body.add_child(_core_req_row(st))
	_open_overlay(Loc.t("Core level %d!") % level, body,
		[{"text": Loc.t("Onward"), "color": Palette.CORE}], 900.0)


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


## The Core level at which the Foreman last said the Core stands in the way.
var _core_gate_said: int = 0

## The machines a Core row's tap is walking through, and where it is.
var _fix_list: Array = []
var _fix_cursor: int = -1

## What the tray and the warning key last showed, so a tick that changes
## nothing changes no theme (see _refresh).
var _afford_shown: Dictionary = {}
var _problem_level_shown: int = -1

func _refresh() -> void:
	# The side menu's Core: the picture of its stage.
	if _rail_core_pic != null and iso_view != null:
		var file: String = String(iso_view.core_info().get("file", ""))
		if file != _rail_core_file:
			_rail_core_file = file
			var pic := _core_picture(46.0)
			_rail_core_pic.texture = pic.texture
			pic.free()
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
	if Sim.descent_needs_core():
		sub = Loc.t("Core level %d first") % (Sim.core_level + 1)
		# Said once a level: the moment the shaft reaches what its Core allows.
		if _core_gate_said != Sim.core_level:
			_core_gate_said = Sim.core_level
			_say(Loc.t("The Core has to grow before the shaft goes deeper. Tap the Core to see what it needs."),
				Foreman.Pose.POINT, 7.0)
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
	lv.add_child(_label(Loc.t("LEVEL %d") % Sim.core_level, 34, Palette.CORE))
	if CoreLevels.era(Sim.core_level) != "":
		lv.add_child(_label(Loc.t(CoreLevels.era(Sim.core_level)), 20, Palette.TEXT))
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 6)
	for k in range(IsoView.CORE_LEVELS):
		var pip := _pip(k < lvl) as ColorRect
		pip.color = Palette.CORE if k < lvl else Color(Palette.BG, 0.9)
		pips.add_child(pip)
	lv.add_child(pips)
	lv.add_child(_label(Loc.t("Down to stratum %d · machines to level %d") % [Sim.depth_cap(),
		Sim.machine_level_cap()], 18, Palette.TEXT_DIM))
	top.add_child(lv)
	top.add_child(_help_button(Loc.t("Factory Core"), func() -> String:
		return Loc.t("The heart of this shaft. Its level decides how deep the shaft may go, how far machines and research may be upgraded, and what the Vault may store.\n\nIt does not grow for credits alone: each level asks the factory to have grown -- materials in its store, handed to it by machines touching it; machines upgraded; a line at its working heat; research; rock reached. Tap a line below to go and do it.")))
	body.add_child(top)
	body.add_child(_core_store())
	_ops_reopen = _show_core
	var galleries: Control = _core_operations()
	if galleries != null:
		body.add_child(galleries)
	var board: Control = _core_contracts()
	if board != null:
		body.add_child(board)
	body.add_child(_core_next())
	body.add_child(_core_blueprints())

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
	if at >= 0:
		line = Loc.t("Stratum %d: the yard grows to %d x %d.") % [at, grow.x, grow.y]
	nxt.add_child(_label(line, 20, Palette.TEXT_DIM))
	body.add_child(nxt)

	# Something is wrong: one key takes the player to it.
	var actions: Array = []
	if problems > 0:
		actions.append({"text": Loc.t("Show me"), "color": Palette.WARN, "cb": _cycle_problem})
	_open_overlay(Loc.t("Factory Core"), body, actions, 900.0)


## The blueprints (Sim.save_blueprint): a row a slot -- what it holds and
## what laying it on this shaft would find -- with a key that saves the board
## into it and one that lays it; while one is being laid, how many machines
## it still has to place, and a key that stops it.
func _core_blueprints() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.set_meta("blueprints", Sim.blueprint_slots())
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(_icon_rect("codex", 36))
	var hl := _label(Loc.t("Blueprints"), 24, Palette.TEXT)
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hl)
	head.add_child(_help_button(Loc.t("Blueprints"), func() -> String:
		return Loc.t("A blueprint is this board saved: every machine where it stands, its mode and its job. A collapse keeps it.\n\nLaid in a new shaft, it is checked against the ground first -- machines not found yet, tiles outside the yard or under rock, tiles taken, jobs not open yet, what would overheat or run cold on this stratum -- and then put down machine by machine as credits allow. What cannot go down yet waits until it can.")))
	box.add_child(head)
	if not Sim.blueprint_pending.is_empty():
		var lay := HBoxContainer.new()
		lay.add_theme_constant_override("separation", 10)
		lay.set_meta("blueprint_pending", Sim.blueprint_pending.size())
		var ll := _label(Loc.tn("Laying a blueprint: %d machine still waiting for credits, ground or its job.",
			"Laying a blueprint: %d machines still waiting for credits, ground or their jobs.", Sim.blueprint_pending.size())
			% Sim.blueprint_pending.size(), 20, Palette.CORE)
		ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lay.add_child(ll)
		var stop := _button(Loc.t("Stop"), Palette.PANEL_HI)
		stop.custom_minimum_size = Vector2(120, MIN_TOUCH)
		stop.pressed.connect(func():
			Sim.cancel_blueprint()
			_show_core())
		lay.add_child(stop)
		box.add_child(lay)
	for slot in range(Sim.blueprint_slots()):
		box.add_child(_blueprint_row(slot))
	return box


func _blueprint_row(slot: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var bp: Dictionary = Sim.blueprint(slot)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var flagged: Array = []
	if bp.is_empty():
		words.add_child(_label(Loc.t("Slot %d: empty") % (slot + 1), 20, Palette.TEXT_DIM))
	else:
		words.add_child(_label(Loc.t("Slot %d: %d machines, saved at Core %d") % [slot + 1,
			(bp["cells"] as Array).size(), int(bp["core"])], 20, Palette.TEXT))
		var rep: Dictionary = Sim.blueprint_report(slot)
		row.set_meta("report", rep["why"])
		var line: String = _blueprint_words(rep)
		var sub := _label(line, TEXT_MIN, Palette.TEXT_DIM)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(sub)
		for e: Dictionary in rep["cells"]:
			if String(e["why"]) in ["taken", "blocked", "outside", "hot", "cold"]:
				flagged.append(int(e["cell"]))
	row.add_child(words)
	if not flagged.is_empty():
		var show_key := _button(Loc.t("Show"), Palette.WARN)
		show_key.custom_minimum_size = Vector2(110, MIN_TOUCH)
		show_key.pressed.connect(func():
			_close_overlay()
			_show_fixes(flagged))
		row.add_child(show_key)
	var save := _button(Loc.t("Save") if bp.is_empty() else Loc.t("Save over"), Palette.PANEL_HI)
	save.custom_minimum_size = Vector2(150, MIN_TOUCH)
	save.disabled = Sim.grid.cells.is_empty()
	save.pressed.connect(func():
		if Sim.save_blueprint(slot):
			Juice.tap()
			_toast_msg(Loc.t("The board is saved in slot %d.") % (slot + 1))
			_show_core())
	row.add_child(save)
	var lay := _button(Loc.t("Lay"), Palette.CORE if not bp.is_empty() else Palette.PANEL)
	lay.custom_minimum_size = Vector2(120, MIN_TOUCH)
	lay.disabled = bp.is_empty()
	lay.set_meta("lay_blueprint", slot)
	lay.pressed.connect(func():
		var before: int = Sim.grid.cells.size()
		Sim.lay_blueprint(slot)
		Juice.reward()
		_toast_msg(Loc.t("Blueprint laid: %d machines down, %d waiting.") % [
			Sim.grid.cells.size() - before, Sim.blueprint_pending.size()])
		_refresh()
		_show_core())
	row.add_child(lay)
	return row


## What a blueprint would find, in a line: "12 ready · 3 not found yet ·
## 2 would overheat · 4.2K credits".
func _blueprint_words(rep: Dictionary) -> String:
	var why: Dictionary = rep["why"]
	var parts: Array[String] = []
	for k: String in ["", "placed", "locked", "outside", "blocked", "taken", "job", "hot", "cold"]:
		if int(why.get(k, 0)) > 0:
			parts.append(Loc.t(String(BLUEPRINT_WORDS[k])) % int(why[k]))
	if float(rep["cost"]) > 0.0:
		parts.append(Loc.t("%s credits") % Economy.fmt(float(rep["cost"])))
	return " · ".join(parts)


## What a blueprint's report says of each kind of machine (Sim._report).
const BLUEPRINT_WORDS := {
	"": "%d ready", "placed": "%d standing", "taken": "%d tiles taken", "locked": "%d not found yet",
	"outside": "%d outside the yard", "blocked": "%d under rock", "job": "%d jobs not open yet",
	"hot": "%d would overheat", "cold": "%d would run cold",
}


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


## --- heat: the safe range, where it comes from, what to do -----------------------

## "2.6 · safe to 3.0", or "2.6 · safe 2.3-6.0" for a machine that wants warmth.
func _heat_words(heat: float, safe: Vector2) -> String:
	if safe.y > 50.0:
		return "%.1f" % heat
	if safe.x > 0.0:
		return Loc.t("%.1f · safe %.1f-%.1f") % [heat, safe.x, safe.y]
	return Loc.t("%.1f · safe to %.1f") % [heat, safe.y]


## The machine sheet's mode key: this machine's mode, a tap for the next --
## or, before the Core's level MODES_CORE, the level that opens it.
func _fill_mode_key(cell: int) -> void:
	for c in _sheet_mode.get_children():
		c.queue_free()
	var id: String = Sim.grid.machine_at(cell)
	var modes: Array[int] = MachineDB.modes_for(id)
	_sheet_mode.visible = modes.size() > 1
	if not _sheet_mode.visible:
		return
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var open: bool = Sim.core_level >= MachineDB.MODES_CORE
	var mode: int = Sim.grid.mode_at(cell)
	var icon := _icon_rect("lock" if not open else ("cold" if mode == MachineDB.Mode.COOL
		else ("heat" if mode == MachineDB.Mode.HOT else "energy")), 30)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)
	var word := _label(_mode_name(id, mode) if open else Loc.t("Core %d") % MachineDB.MODES_CORE,
		TEXT_MIN, Palette.TEXT if open else Palette.TEXT_DIM)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(word)
	_sheet_mode.add_child(col)
	_sheet_mode.disabled = not open
	_sheet_mode.set_meta("mode", mode)
	_sheet_mode.tooltip_text = Loc.t("How hard this one machine runs. Cool: three quarters of the speed, half its own heat. Hot: a quarter faster, 60% more heat. A Boiler run Low gives half its heat.")


## The machine sheet's job key: what this machine makes, a tap for the next
## job the shaft has opened -- or, while none other is open, a lock and what
## opens the first (a stratum or the Core's level).
func _fill_job_key(cell: int) -> void:
	for c in _sheet_job.get_children():
		c.queue_free()
	var id: String = Sim.grid.machine_at(cell)
	var jobs: Array[String] = MachineDB.jobs_for(id)
	_sheet_job.visible = jobs.size() > 1
	if not _sheet_job.visible:
		return
	var job: String = Sim.grid.job_at(cell)
	var next: String = _next_job(cell)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gem: Control
	var outs: Dictionary = MachineDB.job_machine(id, job).get("outputs", {})
	if outs.is_empty():
		gem = _icon_rect("settings", 30)
	else:
		gem = Chips.Gem.new(int(outs.keys()[0]), 1, 30.0)
	gem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(gem)
	var words: String = MachineDB.job_name(id, job)
	var open: bool = next != job
	if not open:
		# Nothing else open yet: say what opens the first other job.
		var other: String = jobs[1] if job == "" else ""
		var why: String = Sim.job_blocker(cell, other)
		if why == "depth":
			words = Loc.t("Stratum %d") % MachineDB.job_depth(id, other)
		elif why == "core":
			words = Loc.t("Core %d") % int(MachineDB.job_info(id, other).get("core", 1))
	var word := _label(words, TEXT_MIN, Palette.TEXT if open else Palette.TEXT_DIM)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(word)
	_sheet_job.add_child(col)
	# The word sits in a child, which does not widen the key: a longer
	# language's word would run past its edges.
	_sheet_job.custom_minimum_size.x = maxf(140.0, word.get_minimum_size().x + 16.0)
	_sheet_job.disabled = not open
	_sheet_job.set_meta("job", job)
	_sheet_job.tooltip_text = Loc.t("What this one machine makes. Deeper rock and the Core's levels open new jobs: crystal from a Drill, alloy from a Smelter at white heat, frames from an Assembler.")


## The next job the shaft has opened for the machine on `cell`, after the
## one it is on; its own job when no other is open.
func _next_job(cell: int) -> String:
	var jobs: Array[String] = MachineDB.jobs_for(Sim.grid.machine_at(cell))
	var at: int = jobs.find(Sim.grid.job_at(cell))
	for k in range(1, jobs.size()):
		var j: String = jobs[(at + k) % jobs.size()]
		if Sim.can_set_job(cell, j):
			return j
	return Sim.grid.job_at(cell)


func _mode_name(id: String, mode: int) -> String:
	match mode:
		MachineDB.Mode.COOL:
			return Loc.t("Low") if MachineDB.is_heat_support(id) else Loc.t("Cool")
		MachineDB.Mode.HOT:
			return Loc.t("Hot")
	return Loc.t("Normal")


## Where the heat at a machine comes from, as the simulation adds it up:
## itself, each neighbour, the rock; its safe range; and what would change
## it -- each line a tap that goes to the machine it names.
func _show_heat(cell: int) -> void:
	var id: String = Sim.grid.machine_at(cell)
	if id == "":
		return
	var heat: float = Sim.grid.heat_at(cell)
	var safe: Vector2 = MachineDB.safe_range(id, Sim.sim.tolerance_bonus, Sim.grid.job_at(cell))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.set_meta("heat_card", cell)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.add_child(Chips.MachineSprite.new(id, 80.0))
	var head := VBoxContainer.new()
	head.add_child(_label(_heat_words(heat, safe), 30,
		Palette.BAD if heat > safe.y else (Palette.COLD if heat < safe.x else Palette.GOOD)))
	var verdict: String = Loc.t("Inside its safe range.")
	if heat > safe.y:
		verdict = Loc.t("%.1f over its safe range: it chokes.") % (heat - safe.y)
	elif heat < safe.x:
		verdict = Loc.t("%.1f too cold: it runs slow.") % (safe.x - heat)
	head.add_child(_label(verdict, 20, Palette.TEXT_DIM))
	head.add_child(_label(Loc.t("Running at %d%% of its speed for its heat") % int(round(
		Sim.sim.heat_efficiency_at(cell) * 100.0)), TEXT_MIN, Palette.TEXT_DIM))
	if Sim.sim.machine_of(cell).has("heat_drive"):
		# White heat: the heat is what it runs on.
		head.add_child(_label(Loc.t("It runs on heat: the hotter, the faster, up to %.1f. Past that it chokes.")
			% safe.y, TEXT_MIN, Palette.CORE))
	top.add_child(head)
	body.add_child(top)
	body.add_child(_label(Loc.t("Where its heat comes from"), 22, Palette.TEXT))
	var sources: Array = Sim.grid.heat_sources(cell)
	sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return absf(float(a["amount"])) > absf(float(b["amount"])))
	for src: Dictionary in sources:
		body.add_child(_heat_source_row(cell, src))
	body.add_child(_label(Loc.t("What changes it"), 22, Palette.TEXT))
	for line: Dictionary in _heat_answers(cell):
		var b := _setting_row(_icon_rect(String(line["icon"]), 36), String(line["words"]), "")
		var go: Callable = line["go"]
		b.pressed.connect(func():
			_close_overlay()
			go.call())
		body.add_child(b)
	_open_overlay(Loc.t("Heat"), body, [], 900.0)


func _heat_source_row(cell: int, src: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var amount: float = float(src["amount"])
	var from: int = int(src["cell"])
	var words: String
	if from < 0:
		row.add_child(_icon_rect("descend", 36))
		words = Loc.t("The rock at stratum %d") % Sim.depth
	elif from == cell:
		row.add_child(Chips.MachineSprite.new(String(src["id"]), 36.0))
		words = Loc.t("Itself") + _mode_note(from)
	else:
		row.add_child(Chips.MachineSprite.new(String(src["id"]), 36.0))
		words = Loc.t("A %s beside it") % MachineDB.name_of(String(src["id"])) + _mode_note(from)
	var l := _label(words, 20, Palette.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_label("%+.1f" % amount, 22, Palette.BAD if amount > 0.0 else Palette.COLD))
	return row


## " (Cool)" after a machine run in a mode.
func _mode_note(cell: int) -> String:
	var mode: int = Sim.grid.mode_at(cell)
	return "" if mode == MachineDB.Mode.NORMAL else " (%s)" % _mode_name(Sim.grid.machine_at(cell), mode)


## What would change the heat at a machine, from what stands round it: the
## Boiler beside it run Low, the machine itself run Cool, a Coolant Cell
## beside it (or a higher level for the ones there), research, or -- too
## cold -- the reverse. Each with the tap that goes and does it.
func _heat_answers(cell: int) -> Array:
	var id: String = Sim.grid.machine_at(cell)
	var heat: float = Sim.grid.heat_at(cell)
	var safe: Vector2 = MachineDB.safe_range(id, Sim.sim.tolerance_bonus, Sim.grid.job_at(cell))
	var out: Array = []
	var modes_open: bool = Sim.core_level >= MachineDB.MODES_CORE
	var spread: float = Sim.grid.heat_spread
	var select := func(c: int) -> Callable:
		return func() -> void:
			iso_view.selected_cell = c
			iso_view.focus_cell(c)
			_show_cell_info(c)
	if heat >= safe.x:
		for n: int in Sim.grid.neighbours(cell):
			if Sim.grid.machine_at(n) == "boiler":
				var less: float = Sim.grid.emitted_at(n) * spread * (1.0 - float(MachineDB.MODE_HEAT[MachineDB.Mode.COOL]))
				out.append({"icon": "heat", "go": select.call(n), "words":
					(Loc.t("Run the Boiler beside it Low: %.1f less") % less) if modes_open and Sim.grid.mode_at(n) == 0
					else Loc.t("Move the Boiler beside it: %.1f less") % (Sim.grid.emitted_at(n) * spread)})
		var own: float = Sim.grid.emitted_at(cell)
		if MachineDB.modes_for(id).has(MachineDB.Mode.COOL) and Sim.grid.mode_at(cell) != MachineDB.Mode.COOL and own > 0.0:
			out.append({"icon": "cold", "go": select.call(cell), "words": (Loc.t("Run it Cool: %.1f less heat, three quarters of the speed")
				% (own * 0.5)) if modes_open else Loc.t("Core level %d opens modes: run it Cool") % MachineDB.MODES_CORE})
		var cool: float = 2.2 * spread * float(Sim.grid.heat_scale.get("coolant", 1.0))
		var has_cool: bool = false
		for n: int in Sim.grid.neighbours(cell):
			has_cool = has_cool or Sim.grid.machine_at(n) == "coolant"
		if Sim.is_unlocked("coolant"):
			var room: bool = false
			var vault: int = -1
			for n: int in Sim.grid.neighbours(cell):
				room = room or (Sim.grid.is_empty(n) and Sim.is_open(n))
				if Sim.grid.machine_at(n) == "vault":
					vault = n
			if room:
				out.append({"icon": "cold", "go": func() -> void: _arm_only("coolant"),
					"words": Loc.t("A Coolant Cell beside it: %.1f less") % cool})
			elif vault >= 0:
				# Boxed in: a Coolant Cell passes material through, so it can
				# stand where the Vault does and hand on what the Vault took.
				out.append({"icon": "cold", "go": select.call(vault),
					"words": Loc.t("No free tile beside it: swap the Vault beside it for a Coolant Cell (%.1f less; material passes through it)") % cool})
			else:
				out.append({"icon": "cold", "go": select.call(cell),
					"words": Loc.t("No free tile beside it: move it, or a neighbour, to make room for a Coolant Cell")})
		# Another job this machine can take that is built for the heat: on
		# deep rock, the answer may be to make something else here.
		for job: String in MachineDB.jobs_for(id):
			if job == Sim.grid.job_at(cell) or not Sim.can_set_job(cell, job):
				continue
			var js: Vector2 = MachineDB.safe_range(id, Sim.sim.tolerance_bonus, job)
			if js.y > safe.y and heat <= js.y:
				out.append({"icon": "settings", "go": select.call(cell), "words":
					Loc.t("Set it to %s: that job takes up to %.1f") % [MachineDB.job_name(id, job), js.y]})
		if has_cool and Sim.machine_upgrade_blocker("coolant") != "none":
			var next: float = 2.2 * spread * MachineDB.heat_factor("coolant", Sim.machine_level("coolant") + 1,
				Sim.overdrive_steps("coolant"))
			out.append({"icon": "upgrade", "go": select.call(_first_of("coolant")), "words":
				Loc.t("Coolant Cells at level %d: %.1f less from each") % [Sim.machine_level("coolant") + 1, next - cool]})
		if MachineDB.level_is_speed(id) and Sim.overdrive_steps(id) > 0:
			out.append({"icon": "heat", "go": select.call(cell), "words":
				Loc.t("Its level %d and %d Overdrive steps give off %d%% more heat than level 1") % [
				Sim.machine_level(id), Sim.overdrive_steps(id), int(round((MachineDB.heat_factor(id,
				Sim.machine_level(id), Sim.overdrive_steps(id)) - 1.0) * 100.0))]})
		elif Sim.machine_levels.has(id) and MachineDB.level_is_speed(id) and int(Sim.machine_levels[id]) > 1:
			out.append({"icon": "heat", "go": select.call(cell), "words":
				Loc.t("Its level %d gives off %d%% more heat than level 1") % [int(Sim.machine_levels[id]),
				int(round((MachineDB.heat_factor(id, int(Sim.machine_levels[id])) - 1.0) * 100.0))]})
	else:
		out.append({"icon": "heat", "go": func() -> void: _arm_only("boiler"),
			"words": Loc.t("A Boiler beside it: %.1f more") % (2.6 * spread)})
		if Sim.grid.mode_at(cell) == MachineDB.Mode.COOL:
			out.append({"icon": "heat", "go": select.call(cell), "words": Loc.t("Run it Normal again")})
	return out


## The first machine of type `id` on the board, or -1.
func _first_of(id: String) -> int:
	for c: int in Sim.grid.cells:
		if Sim.grid.machine_at(c) == id:
			return c
	return -1


## --- the Factory Core's next level ----------------------------------------------
##
## The next level as rows: what it asks for, how far along each one is, and a
## tap that goes to do it -- the machine that makes what the Core takes in,
## armed; a machine to upgrade, selected; the Research grid; the way down.
## Then what the level opens, and the key that grows the Core.

func _core_next() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var next: int = Sim.core_level + 1
	var head := _label(Loc.t("To reach level %d") % next, 24, Palette.TEXT)
	if CoreLevels.era(next) != "":
		head.text += " · " + Loc.t(CoreLevels.era(next))
	box.add_child(head)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.set_meta("core_next", next)
	for st: Dictionary in Sim.core_status():
		rows.add_child(_core_req_row(st))
	box.add_child(rows)
	var o: Dictionary = CoreLevels.opens(next)
	var opens := HBoxContainer.new()
	opens.add_theme_constant_override("separation", 10)
	opens.set_meta("core_opens", o)
	opens.add_child(_icon_rect("descend", 40))
	var line := _label(Loc.t("It opens strata %d to %d, machine level %d and a store of %d.") % [
		int(o["strata"][0]), int(o["strata"][1]), int(o["machine_cap"]), int(o["stock_cap"])],
		TEXT_MIN, Palette.TEXT_DIM)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opens.add_child(line)
	for id: String in (o["machines"] as Array).slice(0, 3):
		opens.add_child(Chips.MachineSprite.new(id, 40.0))
	for _id: String in (o["research"] as Array).slice(0, 2):
		opens.add_child(_icon_rect("research", 34))
	box.add_child(opens)
	if int(o.get("overdrive", 0)) > 0:
		var drive := HBoxContainer.new()
		drive.add_theme_constant_override("separation", 10)
		drive.set_meta("core_opens_overdrive", int(o["overdrive"]))
		drive.add_child(_icon_rect("energy", 36))
		# What a step is paid in under that Core (MachineDB.OVERDRIVE_TIERS).
		var paid: Array = [Loc.t("And Overdrive: %d steps past its level for every machine type the Core before brought to its limit, paid in Ingots, Plates and research."),
			Loc.t("And Overdrive: %d steps past its level for every machine type the Core before brought to its limit, paid in Plates, Components and research."),
			Loc.t("And Overdrive: %d steps past its level for every machine type the Core before brought to its limit, paid in Components, Alloy and research.")]
		var dl := _label(String(paid[clampi(next - MachineDB.OVERDRIVE_CORE, 0, paid.size() - 1)]) % int(o["overdrive"]),
			TEXT_MIN, Palette.TEXT_DIM)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drive.add_child(dl)
		box.add_child(drive)
	for jb: Array in (o.get("jobs", []) as Array):
		var jrow := HBoxContainer.new()
		jrow.add_theme_constant_override("separation", 10)
		jrow.set_meta("core_opens_job", jb)
		jrow.add_child(Chips.MachineSprite.new(String(jb[0]), 36.0))
		var jl := _label(Loc.t("And a new job for the %s: %s -- %s") % [MachineDB.name_of(String(jb[0])),
			MachineDB.job_name(String(jb[0]), String(jb[1])),
			Loc.t(String(MachineDB.job_info(String(jb[0]), String(jb[1]))["short"]))], TEXT_MIN, Palette.TEXT_DIM)
		jl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		jl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		jrow.add_child(jl)
		box.add_child(jrow)
	for deep_words: String in _deep_opens(o):
		var rrow := HBoxContainer.new()
		rrow.add_theme_constant_override("separation", 10)
		rrow.set_meta("core_opens_regions", true)
		rrow.add_child(_icon_rect("descend", 36))
		var rl := _label(deep_words, TEXT_MIN, Palette.TEXT_DIM)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rrow.add_child(rl)
		box.add_child(rrow)
	if bool(o.get("export", false)):
		var erow := HBoxContainer.new()
		erow.add_theme_constant_override("separation", 10)
		erow.set_meta("core_opens_export", true)
		erow.add_child(_icon_rect("credits", 36))
		var el := _label(Loc.t("And the Core sells what its store has no room for, at half what a Vault pays: a full store no longer stops the machines beside it."),
			TEXT_MIN, Palette.TEXT_DIM)
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		erow.add_child(el)
		box.add_child(erow)
	if bool(o.get("doctrine", false)):
		var drow := HBoxContainer.new()
		drow.add_theme_constant_override("separation", 10)
		drow.set_meta("core_opens_doctrine", true)
		drow.add_child(_icon_rect("research", 36))
		var dtl := _label(Loc.t("And a doctrine for the shaft: one of three ways to grow it, each with research of its own. Chosen once, until the shaft collapses."),
			TEXT_MIN, Palette.TEXT_DIM)
		dtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drow.add_child(dtl)
		box.add_child(drow)
	if next == MachineDB.MODES_CORE:
		var modes := HBoxContainer.new()
		modes.add_theme_constant_override("separation", 10)
		modes.add_child(_icon_rect("cold", 36))
		var ml := _label(Loc.t("And machine modes: run a machine Cool for less heat, or Hot for more output."),
			TEXT_MIN, Palette.TEXT_DIM)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		modes.add_child(ml)
		box.add_child(modes)
	var grow := _button("", Palette.CORE if Sim.can_upgrade_core() else Palette.PANEL)
	grow.custom_minimum_size = Vector2(0, MIN_TOUCH)
	grow.disabled = not Sim.can_upgrade_core()
	grow.set_meta("core_grow", true)
	var gl := _label(Loc.t("Grow the Core to level %d") % next, 24,
		Palette.BG if Sim.can_upgrade_core() else Palette.TEXT_DIM)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grow.add_child(gl)
	grow.pressed.connect(func():
		if Sim.upgrade_core():
			_close_overlay()
			_refresh())
	box.add_child(grow)
	return box


## The Core's store: each material a machine this shaft has found makes,
## how much of it is in the store, and what the Vault's level lets it hold.
func _core_store() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.add_child(_label(Loc.t("Store"), 22, Palette.TEXT))
	var cap: int = Sim.stock_cap()
	for res: int in MachineDB.STOCKED:
		if not Sim.can_make(res):
			continue
		row.add_child(Chips.Gem.new(res, 1, 30.0))
		row.add_child(_label("%d/%d" % [Sim.stock_of(res), cap], 22,
			Palette.CORE if Sim.stock_of(res) >= cap else Palette.TEXT))
	var b := _button("", Palette.PANEL)
	b.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	b.add_child(Chips.MachineSprite.new("vault", 44.0))
	b.tooltip_text = Loc.t("The Vault's level is the Core's store.")
	b.pressed.connect(func():
		_close_overlay()
		_select_type("vault"))
	row.add_child(b)
	row.set_meta("store", Sim.stock.duplicate())
	return row


## The Dispatch board (Dispatch): each contract as a row -- the material and
## how many, what it pays, a key that fills it from the store, and a key
## that drops it. A dropped contract's slot says how many more units the
## store has to take before it is dealt again. null before the shaft can
## make anything the store keeps.
func _core_contracts() -> Control:
	var any: bool = false
	for c: Dictionary in Sim.contracts:
		any = any or not c.is_empty()
	if not any:
		return null
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_meta("contracts", Sim.contracts.duplicate(true))
	var head := _label(Loc.t("Contracts"), 24, Palette.TEXT)
	box.add_child(head)
	for i in range(Sim.contracts.size()):
		box.add_child(_contract_row(i))
	return box


func _contract_row(i: int) -> Control:
	var c: Dictionary = Sim.contract(i)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if c.has("rest"):
		var wait := _label(Loc.t("A new contract after %d more units in the store") % int(c["rest"]),
			TEXT_MIN, Palette.TEXT_DIM)
		wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(wait)
		return row
	if not c.has("res"):
		return row
	var res: int = int(c["res"])
	row.add_child(Chips.Gem.new(res, 1, 40.0))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	words.add_child(_label(Loc.t("%d %s") % [int(c["n"]), Loc.t(String(MachineDB.RES_NAME[res]))], 22,
		Palette.TEXT))
	words.add_child(_label("%d / %d  ·  %s" % [mini(Sim.stock_of(res), int(c["n"])), int(c["n"]),
		_contract_pay_words(i)], TEXT_MIN, Palette.TEXT_DIM))
	row.add_child(words)
	var fill := _button(Loc.t("Fill"), Palette.CORE if Sim.can_fill_contract(i) else Palette.PANEL)
	fill.custom_minimum_size = Vector2(120, MIN_TOUCH)
	fill.disabled = not Sim.can_fill_contract(i)
	fill.set_meta("contract", i)
	fill.pressed.connect(func():
		if Sim.fill_contract(i):
			_close_overlay()
			_show_core())
	row.add_child(fill)
	var drop := _button("✕", Palette.PANEL)
	drop.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	drop.tooltip_text = Loc.t("Drop this contract. A new one comes after %d more units in the store.") \
		% Dispatch.REST_UNITS
	drop.pressed.connect(func():
		if Sim.drop_contract(i):
			_close_overlay()
			_show_core())
	row.add_child(drop)
	return row


## What contract `i` pays, in words.
func _contract_pay_words(i: int) -> String:
	var c: Dictionary = Sim.contract(i)
	if String(c.get("pays", "")) == "research":
		return Loc.t("pays %s research") % Economy.fmt(Sim.contract_pay(i))
	return Loc.t("pays %s credits") % Economy.fmt(Sim.contract_pay(i))

## The galleries (Operations): the crew -- Rigs at the Core, out, the limit,
## their wear and a key that repairs them -- and a row for each site on the
## board: what it is, what it needs against the crew, what it pays, and a
## key that sends the Rigs. null before the Core keeps a crew.
func _core_operations(titled: bool = true) -> Control:
	if Operations.slots(Sim.core_level) == 0:
		return null
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_meta("operations", Sim.ops_board.duplicate(true))
	if not titled:
		_ops_rows(box)
		return box
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var title := _label(Loc.t("Galleries"), 24, Palette.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bay_key := _button(Loc.t("Rig Bay"), Palette.PANEL)
	bay_key.custom_minimum_size = Vector2(150, MIN_TOUCH)
	bay_key.set_meta("bay", true)
	bay_key.pressed.connect(func(): _show_bay())
	head.add_child(title)
	head.add_child(bay_key)
	head.add_child(_help_button(Loc.t("Galleries"), func() -> String:
		return Loc.t("Old workings, dead stations and nests of rogue drills lie in the galleries beyond the yard. Rigs -- robots the Core keeps, the first from the start, the rest built by an Assembler on the Rig Frame job -- go out to them and come home with what they held.\n\nEach site says what strength it needs against your crew's, and what it pays. A sortie is decided when it leaves: strong enough, it clears the site; too weak, it earns its share and leaves the site weaker for the next one. The Rigs come home worn, and Plates repair them. Rig Plating makes every Rig stronger.")))
	box.add_child(head)
	_ops_rows(box)
	return box


## The Rig Bay: its level and the key that raises it; the Rigs posted to
## machines beside the Core, each with a key that calls it home; and the
## machines beside the Core a Rig could be posted to, with a key that posts
## one. A posted Rig hauls what its machine takes from the Core's store.
func _show_bay() -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	var info := _label(Loc.t("Level %d · %d of %d docks in use · each posted Rig hauls %s a second from the store")
		% [Sim.bay_level, Sim.rigs_posted(), Sim.bay_posts(), String.num(Sim.haul_rate(), 2)], 22, Palette.TEXT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(info)
	var why: String = Sim.bay_blocker()
	if why != "max":
		var c: Dictionary = Operations.bay_cost(Sim.bay_level)
		var up := _button("", Palette.CORE if why == "" else Palette.PANEL)
		up.custom_minimum_size = Vector2(0, MIN_TOUCH)
		up.disabled = why != ""
		up.set_meta("bay_up", true)
		var price := HBoxContainer.new()
		price.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.add_theme_constant_override("separation", 6)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ink: Color = Palette.BG if why == "" else Palette.TEXT
		price.add_child(_label(Loc.t("Level %d") % (Sim.bay_level + 1), 22, ink))
		if why == "core":
			price.add_child(_label(Loc.t("at the Core's level %d") % (Sim.bay_level + 3), 22, Palette.TEXT_DIM))
		else:
			price.add_child(_icon_rect("settings", 34))
			price.add_child(_label(str(int(c["salvage"])), 22, ink if Sim.salvage >= int(c["salvage"]) else Palette.BAD))
			price.add_child(_icon_rect("credits", 34))
			price.add_child(_label(Economy.fmt(float(c["credits"])), 22,
				ink if Sim.credits >= float(c["credits"]) else Palette.BAD))
		up.add_child(price)
		up.pressed.connect(func():
			if Sim.upgrade_bay():
				Juice.upgrade()
				iso_view.repair_call()
				_show_bay())
		body.add_child(up)
	body.add_child(_refit_row())
	# The machines beside the Core: those with a Rig, then those that could
	# have one -- starved ones first.
	var rows: Array = []
	for cell: int in Sim.sim.core_touching():
		if Sim.grid.is_empty(cell):
			continue
		var b: String = Sim.post_blocker(cell)
		if b == "posted" or b == "" or b == "rigs" or b == "bay":
			var starved: bool = Sim.sim.status_of(cell) == Simulation.Status.STARVED
			rows.append([0 if b == "posted" else (1 if starved else 2), cell, b])
	rows.sort_custom(func(a: Array, b2: Array) -> bool: return int(a[0]) < int(b2[0]))
	if rows.is_empty():
		var none := _label(Loc.t("No machine beside the Core takes anything the store keeps. A Press, an Assembler, a Lab or a Frame Jig touching the Core can have a Rig."),
			TEXT_MIN, Palette.TEXT_DIM)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(none)
	for r: Array in rows.slice(0, 8):
		body.add_child(_post_row(int(r[1]), String(r[2])))
	_open_overlay(Loc.t("Rig Bay"), body, [], 820.0)


## The Bay's refits: a Rig at the Bay made a Breaker (Operations, "the
## Breaker") or a Surveyor ("the Surveyor"), what each is for, and its price.
func _refit_row() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_meta("refit", true)
	for role: String in ["breaker", "surveyor"]:
		box.add_child(_refit_one(role))
	return box


const ROLE_WORDS := {
	"breaker": ["Refit a Rig as a Breaker",
		"At the Core's level %d: refit Rigs as Breakers -- for rock, where a Rig does half.",
		"Breakers: %d at the Bay, %d out. A Breaker does 2.5 Rigs' work on rock, where a Rig does half, and less than one in water; it takes the brunt of a site's wear, leads a team into danger, burns twice the fuel and is never posted."],
	"surveyor": ["Refit a Rig as a Surveyor",
		"At the Core's level %d: refit Rigs as Surveyors -- they lead the expeditions that open the deep map.",
		"Surveyors: %d at the Bay, %d out. An expedition into the deep map goes only with one; each finds a quarter more Resonite, and a team of Surveyors alone is back sooner. On a site a Surveyor does less than a Rig, and it wears twice as fast in danger."],
}


func _refit_one(role: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var words: Array = ROLE_WORDS[role]
	var why: String = Sim.refit_blocker(role)
	if why == "core":
		var later := _label(Loc.t(String(words[1])) % Operations.role_core(role), TEXT_MIN, Palette.TEXT_DIM)
		later.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(later)
		return box
	var have: int = Sim.breakers if role == "breaker" else Sim.surveyors
	var out: int = Sim.breakers_out() if role == "breaker" else Sim.surveyors_out()
	var what := _label(Loc.t(String(words[2])) % [have, out], TEXT_MIN, Palette.TEXT_DIM)
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(what)
	var c: Dictionary = Operations.refit_cost(Sim.core_level, role)
	var key := _button("", Palette.CORE if why == "" else Palette.PANEL)
	key.custom_minimum_size = Vector2(0, MIN_TOUCH)
	key.disabled = why != ""
	key.set_meta("refit", role)
	var price := HBoxContainer.new()
	price.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	price.alignment = BoxContainer.ALIGNMENT_CENTER
	price.add_theme_constant_override("separation", 6)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Dark words on the lit key, light on the dim one.
	var ink: Color = Palette.BG if why == "" else Palette.TEXT
	price.add_child(_label(Loc.t(String(words[0])), 22, ink))
	price.add_child(_icon_rect("settings", 34))
	price.add_child(_label(str(int(c["salvage"])), 22, ink if Sim.salvage >= int(c["salvage"]) else Palette.BAD))
	var gem := Chips.Gem.new(int(c["res"]), 1, 30.0)
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price.add_child(gem)
	price.add_child(_label(str(int(c["n"])), 22, ink if Sim.stock_of(int(c["res"])) >= int(c["n"]) else Palette.BAD))
	key.add_child(price)
	key.pressed.connect(func():
		if Sim.refit_rig(role):
			Juice.upgrade()
			iso_view.repair_call()
			_show_bay())
	box.add_child(key)
	return box


## One machine beside the Core, on the Bay's screen.
func _post_row(cell: int, why: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_meta("post", cell)
	var id: String = Sim.grid.machine_at(cell)
	row.add_child(Chips.MachineSprite.new(id, 52.0))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var job: String = Sim.grid.job_at(cell)
	words.add_child(_label(MachineDB.job_name(id, job) if job != "" else MachineDB.name_of(id), 22, Palette.TEXT))
	var hauls: Array[String] = []
	for res: int in Sim.haul_inputs(cell):
		var word: String = "%s %s" % [Loc.t(String(MachineDB.RES_NAME[res])), Economy.fmt(float(Sim.haulable(res)))]
		if Sim.haul_floor(res) > 0:
			# What the Core's next level asks the store for stays there.
			word += " " + Loc.t("(%s kept for the Core)") % Economy.fmt(float(Sim.haul_floor(res)))
		hauls.append(word)
	var state: String = Loc.t("a Rig hauls it: %s") if why == "posted" else (Loc.t("starved; the store can spare: %s")
		if Sim.sim.status_of(cell) == Simulation.Status.STARVED else Loc.t("the store can spare: %s"))
	var line := _label(state % (", ".join(hauls) if not hauls.is_empty() else "-"), TEXT_MIN, Palette.TEXT_DIM)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(line)
	row.add_child(words)
	# A job a Surveyor tunes (Sim.tune): a key for that too.
	if MachineDB.job_info(id, job).has("tuned"):
		var tuned: bool = Sim.tuners.has(cell)
		var tb: String = Sim.tune_blocker(cell)
		var tl := _label(Loc.t("A Surveyor tunes it: half the Resonite a Lens, half the Lenses a Prism.") if tuned
			else Loc.t("A Surveyor could tune it: half the Resonite a Lens, half the Lenses a Prism."), TEXT_MIN,
			Palette.CORE if tuned else Palette.TEXT_DIM)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(tl)
		var tk := _button(Loc.t("Surveyor home") if tuned else Loc.t("Tune"),
			Palette.PANEL if tuned or tb != "" else Palette.CORE)
		tk.custom_minimum_size = Vector2(150, MIN_TOUCH)
		tk.disabled = not tuned and tb != ""
		tk.set_meta("tune", cell)
		tk.pressed.connect(func():
			var done: bool = Sim.untune(cell) if tuned else Sim.tune(cell)
			if done:
				Juice.tap()
				_show_bay())
		row.add_child(tk)
	var key := _button(Loc.t("Call home") if why == "posted" else Loc.t("Post a Rig"),
		Palette.PANEL if why == "posted" else (Palette.CORE if why == "" else Palette.PANEL))
	key.custom_minimum_size = Vector2(170, MIN_TOUCH)
	key.disabled = why == "rigs" or why == "bay"
	key.pressed.connect(func():
		var ok: bool = Sim.recall_rig(cell) if why == "posted" else Sim.post_rig(cell)
		if ok:
			Juice.tap()
			_show_bay())
	row.add_child(key)
	return row


## The page that opens from the Galleries section and from a gallery mouth
## on the board, if the Core card is not already showing.
var _ops_reopen: Callable = _show_core


## The galleries on their own: what a tap on a gallery mouth opens.
func _show_galleries() -> void:
	if Operations.slots(Sim.core_level) == 0:
		_say(Loc.t("Old galleries, boarded up. At the Core's level %d the first opens, and its Rig can go in.")
			% Operations.FIRST_SITE_CORE, Foreman.Pose.POINT, 6.0)
		return
	_ops_reopen = _show_galleries
	_open_overlay(Loc.t("Galleries"), _core_operations(false), [], 760.0)


## The crew and the sites, into `box`.
func _ops_rows(box: VBoxContainer) -> void:
	# The crew.
	var crew := HBoxContainer.new()
	crew.add_theme_constant_override("separation", 10)
	var gem := Chips.Gem.new(MachineDB.Res.RIG, 1, 40.0)
	# A Gem draws to its height: stretched to the crew's lines, it covered them.
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crew.add_child(gem)
	var cw := VBoxContainer.new()
	cw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cw.add_theme_constant_override("separation", 0)
	cw.add_child(_label(Loc.t("Rigs: %d at the Bay, %d out, %d posted, room for %d") % [Sim.rigs_home(),
		Sim.rigs_out(), Sim.rigs_posted(), Sim.crew_cap()], 22, Palette.TEXT))
	if Sim.breakers + Sim.breakers_out() > 0:
		cw.add_child(_label(Loc.t("Breakers: %d at the Bay, %d out") % [Sim.breakers, Sim.breakers_out()],
			TEXT_MIN, Palette.TEXT))
	if Sim.surveyors + Sim.surveyors_out() + Sim.surveyors_away() > 0:
		cw.add_child(_label(Loc.t("Surveyors: %d at the Bay, %d out") % [Sim.surveyors, Sim.surveyors_out()],
			TEXT_MIN, Palette.TEXT))
	if Sim.surveyors_away() > 0:
		cw.add_child(_label(Loc.t("%d keeping Beacons, %d tuning machines") % [Sim.beacons.size(), Sim.tuners.size()],
			TEXT_MIN, Palette.TEXT_DIM))
	if Sim.sites_to_next_rig() > 0:
		cw.add_child(_label(Loc.t("%d more sites cleared, room for another Rig") % Sim.sites_to_next_rig(),
			TEXT_MIN, Palette.TEXT_DIM))
	var worn: String = Loc.t("%d%% worn") % int(round(Sim.rig_wear * 100.0)) if Sim.rig_wear > 0.0 \
		else Loc.t("whole")
	cw.add_child(_label(Loc.t("strength %d each, %s") % [int(round(Sim.crew_strength(1))), worn], TEXT_MIN,
		Palette.TEXT_DIM))
	var salv := _label(Loc.t("Salvage: %d -- it buys the Rig Bay's levels, and Salvaged Gearing and Rig Plating in Research")
		% Sim.salvage, TEXT_MIN, Palette.TEXT_DIM)
	salv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cw.add_child(salv)
	crew.add_child(cw)
	if Sim.repair_cost() > 0:
		var fix := _button(Loc.t("Repair: %d Plates") % Sim.repair_cost(),
			Palette.CORE if Sim.can_repair() else Palette.PANEL)
		fix.custom_minimum_size = Vector2(170, MIN_TOUCH)
		fix.disabled = not Sim.can_repair()
		fix.set_meta("repair", true)
		fix.pressed.connect(func():
			if Sim.repair_rigs():
				iso_view.repair_call()
				Juice.upgrade()
				_close_overlay()
				_ops_reopen.call())
		crew.add_child(fix)
	box.add_child(crew)
	if Sim.core_level < MachineDB.RIG_CORE:
		var more := _label(Loc.t("At the Core's level %d: more galleries, and Assemblers that build Rigs.")
			% MachineDB.RIG_CORE, TEXT_MIN, Palette.TEXT_DIM)
		more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(more)
	elif Sim.rigs_home() + Sim.rigs_out() == 0:
		var how := _label(Loc.t("No Rigs yet: set an Assembler to the Rig Frame job. Each Rig it makes walks to the Core."),
			TEXT_MIN, Palette.TEXT_DIM)
		how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(how)
	for i in range(Sim.ops_board.size()):
		box.add_child(_site_row(i))


## Site `i` on the board, as a row.
func _site_row(i: int) -> Control:
	var s: Dictionary = Sim.site(i)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_meta("site", i)
	if not s.has("kind"):
		return row
	var kind: Dictionary = Operations.KINDS[String(s["kind"])]
	row.add_child(_icon_rect("warning" if String(s["kind"]) in ["nest", "forge"] else "descend", 40))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var head: String = Loc.t(String(kind["name"]))
	var reg: String = String(s.get("region", ""))
	if reg != "":
		head = Loc.t(String(Operations.REGIONS[reg]["name"])) + " · " + head
	words.add_child(_label(head, 22, Palette.TEXT))
	var tag: String = _terrain_words(s)
	if tag != "":
		var tl := _label(tag, TEXT_MIN, Palette.WARN)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(tl)
	var need := _label("", TEXT_MIN, Palette.TEXT)
	need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(need)
	var r: Dictionary = Sim.site_reward(i)
	var pays := _label(Loc.t("pays %s credits, %s research, %d %s, %d salvage") % [Economy.fmt(float(r["credits"])),
		Economy.fmt(float(r["research"])), int(r["n"]), Loc.t(String(MachineDB.RES_NAME[int(r["res"])])),
		int(r["salvage"])], TEXT_MIN, Palette.TEXT_DIM)
	pays.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(pays)
	if String(s["kind"]) == "stranded":
		words.add_child(_label(Loc.t("Brought home: room for one more Rig, and the crew mended."), TEXT_MIN, Palette.GOOD))
	row.add_child(words)
	if Sim.site_busy(i):
		row.add_child(_label(Loc.t("Rigs out"), TEXT_MIN, Palette.CORE))
		return row
	var start: Vector3i = Sim.sortie_team(i)
	if _sortie_pick.has(i):
		start = _sortie_pick[i]
	return _team_line(row, _team_picker(s, start, i, need,
			func(n: int, b: int, v: int) -> String: return Sim.sortie_blocker(i, n, b, v),
			func(n: int, b: int, v: int) -> bool: return Sim.send_sortie(i, n, b, v),
			func(n: int, b: int, v: int) -> int: return Operations.fuel(n, Sim.core_level, b, v)))


## A target's row and its team's keys: beside it, or -- all three kinds of
## crew being wider than a phone's panel beside the words -- on a line of
## their own under it.
func _team_line(row: HBoxContainer, keys: Array[Control]) -> Control:
	if keys.size() <= 3:
		for c: Control in keys:
			row.add_child(c)
		return row
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for m: StringName in row.get_meta_list():
		box.set_meta(m, row.get_meta(m))
	box.add_child(row)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_END
	line.add_theme_constant_override("separation", 10)
	for c: Control in keys:
		line.add_child(c)
	box.add_child(line)
	return box


## What the ground of site `s` does to a team, in words, or "".
func _terrain_words(s: Dictionary) -> String:
	var out: String = ""
	if Operations.dark(s):
		out = Loc.t("dark: with no Surveyor to guide it a team is lost") if Sim.controlled("reach") \
			else Loc.t("dark: with no Surveyor to guide it a team is lost, and each head burns %d Lenses for light") \
				% Operations.DARK_LENS
		if Operations.dangerous(s):
			out += " · " + Loc.t("danger: with no Breaker to lead, half the pay")
	elif Operations.armored(s):
		out = Loc.t("rock: a Rig does half")
	elif Operations.dangerous(s):
		out = Loc.t("danger: with no Breaker to lead, half the pay")
	elif Operations.watery(s) and Sim.breakers + Sim.breakers_out() > 0:
		out = Loc.t("water: too deep for a Breaker")
	if Operations.holding(s):
		out = (out + " · " if out != "" else "") + Loc.t("a Beacon's ground: Breakers hold it, half again their strength")
	return out


## Lenses the team `n`, `b`, `v` needs for target `s`: an expedition's or a
## Beacon's price, and light in the dark.
func _lens_price(s: Dictionary, n: int, b: int, v: int) -> int:
	var base: int = 0
	match String(s.get("kind", "")):
		"survey":
			base = Sim.expedition_lenses()
		"beacon":
			base = Sim.beacon_lenses()
	return base + Sim.light_lenses(s, n, b, v)


## A team for target `s` (a site, or a region's survey): a - and a + for
## each kind of crew at the Bay, the words under the target's name -- its
## strength, the verdict, the wear it brings home, why it cannot go -- and
## the key that sends it. `blocker`, `send` and `fuel` take the team as
## (Rigs, Breakers, Surveyors). The team picked is kept under `pick` until
## it goes.
func _team_picker(s: Dictionary, start: Vector3i, pick: Variant, need: Label, blocker: Callable,
		send: Callable, fuel: Callable) -> Array[Control]:
	var go := _button("", Palette.CORE)
	go.custom_minimum_size = Vector2(150, MIN_TOUCH)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	go.set_meta("send", pick)
	var most := {"n": Sim.rigs_home(), "b": Sim.breakers, "v": Sim.surveyors}
	# The team in a Dictionary: a lambda keeps its own copy of a plain local.
	var team := {"n": clampi(start.x, 0, int(most["n"])), "b": clampi(start.y, 0, int(most["b"])),
		"v": clampi(start.z, 0, int(most["v"]))}
	# Keys only for the kinds the crew has: the rest never reach the screen.
	var keys: Dictionary = {}
	for k: String in ["n", "b", "v"]:
		if int(most[k]) <= 0:
			continue
		var fewer := _button("-", Palette.PANEL_HI)
		var more := _button("+", Palette.PANEL_HI)
		for key: Button in [fewer, more]:
			key.custom_minimum_size = Vector2(60, MIN_TOUCH)
			key.size_flags_horizontal = Control.SIZE_SHRINK_END
			key.add_theme_font_size_override("font_size", 34)
			key.add_theme_color_override("font_color", Palette.TEXT)
		keys[k] = [fewer, more]
	var survey: bool = String(s.get("kind", "")) == "survey"
	var target: float = float(s["need"]) if survey else float(s["left"])
	var show := func() -> void:
		var n: int = int(team["n"])
		var b: int = int(team["b"])
		var v: int = int(team["v"])
		var strength: float = Sim.team_strength(s, n, b, v)
		var verdict: String = Operations.verdict(s, strength)
		var wear: float = float(Operations.resolve(s, strength)["wear"]) \
			* (1.0 - Operations.BREAKER_SHIELD * Operations.breaker_share(s, n, b, v)) \
			* (1.0 + Operations.SURVEYOR_FRAGILE * Operations.surveyor_share(s, n, b, v)
				* (2.0 if Operations.dangerous(s) else 1.0))
		if Sim.breakers + Sim.surveyors + b + v == 0:
			need.text = Loc.t("needs %d · sending %d: strength %d, %s, wear +%d%%") % [int(ceil(target)), n,
				int(round(strength)), _verdict_words(verdict), int(round(wear * 100.0))]
		else:
			need.text = Loc.t("needs %d · %d Rigs, %d Breakers, %d Surveyors: strength %d, %s, wear +%d%%") % [
				int(ceil(target)), n, b, v, int(round(strength)), _verdict_words(verdict), int(round(wear * 100.0))]
		var col: Color = Palette.GOOD if verdict in ["trivial", "easy", "even"] else \
			(Palette.WARN if verdict == "hard" else Palette.BAD)
		if Operations.dangerous(s) and b == 0 and not survey:
			need.text += "\n" + Loc.t("No Breaker to lead it: half the pay.")
			col = Palette.WARN
		if v > 0 and int(Operations.KINDS[String(s["kind"])]["res"]) == MachineDB.Res.RESONITE:
			need.text += "\n" + Loc.t("Surveyors: %d%% more Resonite.") \
				% int(round(100.0 * minf(Operations.SURVEYOR_FIND * float(v), Operations.SURVEYOR_FIND_MAX)))
		var why: String = String(blocker.call(n, b, v))
		var fr: int = Operations.fuel_res(Sim.core_level)
		match why:
			"fuel":
				need.text += "\n" + Loc.t("Fuel: %d %s, and the store has %d") % [int(fuel.call(n, b, v)),
					Loc.t(String(MachineDB.RES_NAME[fr])), Sim.stock_of(fr)]
				col = Palette.BAD
			"surveyor":
				need.text += "\n" + Loc.t("An expedition goes only with a Surveyor.")
				col = Palette.BAD
			"lens", "light":
				need.text += "\n" + Loc.t("Lenses: %d, and the store has %d") % [_lens_price(s, n, b, v),
					Sim.stock_of(MachineDB.Res.LENS)]
				col = Palette.BAD
			"beacons":
				need.text += "\n" + Loc.t("%d Beacons must burn to light the way; %d do.") % [Operations.REACH_LIGHT,
					Sim.lit_beacons()]
				col = Palette.BAD
			"weak":
				need.text += "\n" + Loc.t("Not strong enough for the survey.")
				col = Palette.BAD
		need.add_theme_color_override("font_color", col)
		go.text = Loc.t("Send %d") % (n + b + v) if n + b + v > 0 else Loc.t("Send")
		go.disabled = why != ""
		go.tooltip_text = Loc.t("Fuel: %d %s") % [int(fuel.call(n, b, v)), Loc.t(String(MachineDB.RES_NAME[fr]))]
		for k: String in keys:
			var total: int = n + b + v
			(keys[k][0] as Button).disabled = int(team[k]) <= 0 or total <= 1
			(keys[k][1] as Button).disabled = int(team[k]) >= int(most[k])
	show.call()
	for k: String in keys:
		var key_name: String = k
		(keys[k][0] as Button).pressed.connect(func():
			team[key_name] = maxi(int(team[key_name]) - 1, 0)
			_sortie_pick[pick] = Vector3i(int(team["n"]), int(team["b"]), int(team["v"]))
			Juice.tap()
			show.call())
		(keys[k][1] as Button).pressed.connect(func():
			team[key_name] = mini(int(team[key_name]) + 1, int(most[key_name]))
			_sortie_pick[pick] = Vector3i(int(team["n"]), int(team["b"]), int(team["v"]))
			Juice.tap()
			show.call())
	go.pressed.connect(func():
		if bool(send.call(int(team["n"]), int(team["b"]), int(team["v"]))):
			_sortie_pick.erase(pick)
			Juice.place()
			_close_overlay()
			_ops_reopen.call())
	var out: Array[Control] = []
	var words := {"n": Loc.t("Rigs"), "b": Loc.t("Breakers"), "v": Loc.t("Surveyors")}
	for k: String in keys:
		out.append(_team_keys(keys[k][0], keys[k][1], String(words[k])))
	out.append(go)
	return out


## A "-" and a "+" for one kind of the team, with the kind's word above.
func _team_keys(fewer: Button, more: Button, word: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_SHRINK_END
	var l := _label(word, TEXT_MIN, Palette.TEXT_DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 4)
	keys.add_child(fewer)
	keys.add_child(more)
	col.add_child(keys)
	return col


## The team the player picked for a site, by the site's place on the board;
## forgotten once it is sent.
var _sortie_pick: Dictionary = {}


## A site's verdict against the crew, in words.
func _verdict_words(v: String) -> String:
	match v:
		"trivial":
			return Loc.t("too easy")
		"easy":
			return Loc.t("easy")
		"even":
			return Loc.t("even")
		"hard":
			return Loc.t("hard: a share of it")
	return Loc.t("out of reach")



## One of the next level's requirements: its picture, its words, how far
## along it is, and what a tap does -- for the Core card and What now?.
func _core_req_info(st: Dictionary) -> Dictionary:
	var r: Array = st["req"]
	var met: bool = bool(st["met"])
	var pic: Control
	var words: String = ""
	var amount: String = "%d / %d" % [int(st["have"]), int(st["need"])]
	var go: Callable = func() -> void: pass
	match int(r[0]):
		CoreLevels.Req.CREDITS:
			pic = _icon_rect("credits", 44)
			words = Loc.t("Credits, paid when the Core grows")
			amount = "%s / %s" % [Economy.fmt(float(st["have"])), Economy.fmt(float(st["need"]))]
		CoreLevels.Req.STOCK:
			var res: int = int(r[1])
			pic = Chips.Gem.new(res, 1, 40.0)
			var mat: String = Loc.t(String(MachineDB.RES_NAME[res]))
			if int(st.get("cap", 0)) < int(st["need"]) and not met:
				# More than the store holds: the Vault's level comes first.
				words = Loc.t("%s in the store -- Vault first") % mat
				go = func() -> void: _select_type("vault")
			else:
				words = Loc.t("%s in the store, from beside the Core") % mat
				var maker: String = CoreLevels.producer_of(res)
				go = func() -> void: _arm_only(maker)
		CoreLevels.Req.WORKING:
			var wid: String = String(r[1])
			var wjob: String = CoreLevels.row_job(r)
			pic = Chips.MachineSprite.new(wid, 44.0)
			words = Loc.t("%s running at working heat") \
				% (MachineDB.job_name(wid, wjob) if wjob != "" else MachineDB.name_of(wid))
			if not met:
				amount = _held_back_words(amount, CoreLevels.holding_back(Sim, wid, wjob))
			go = func() -> void: _show_working(wid, int(st["need"]), wjob)
		CoreLevels.Req.MACHINE:
			var mid: String = String(r[1])
			pic = Chips.MachineSprite.new(mid, 44.0)
			words = Loc.t("%s at level %d") % [MachineDB.name_of(mid), int(st["need"])]
			amount = Loc.t("level %d") % int(st["have"])
			go = func() -> void: _select_type(mid)
		CoreLevels.Req.DEPTH:
			pic = _icon_rect("descend", 44)
			words = Loc.t("Stratum %d reached") % int(st["need"])
			go = _on_descend
		CoreLevels.Req.RESEARCH:
			var rid: String = String(r[1])
			pic = _icon_rect("research", 44)
			words = Loc.t("%s at level %d") % [Loc.t(String(Economy.RESEARCH_TREE[rid]["name"])),
				int(st["need"])]
			amount = Loc.t("level %d") % int(st["have"])
			go = _show_research
		CoreLevels.Req.SERVES:
			var sid: String = String(r[1])
			pic = Chips.MachineSprite.new(sid, 44.0)
			words = Loc.t("A %s serving %d machines") % [MachineDB.name_of(sid), int(st["need"])]
			go = func() -> void: _arm_only(sid)
		CoreLevels.Req.OVERDRIVE:
			var did: String = String(r[1])
			pic = Chips.MachineSprite.new(did, 44.0)
			words = Loc.t("%s driven %d Overdrive steps") % [MachineDB.name_of(did), int(st["need"])]
			amount = "%d / %d" % [int(st["have"]), int(st["need"])]
			go = func() -> void: _select_type(did)
		CoreLevels.Req.DOCTRINE:
			pic = _icon_rect("research", 44)
			if Sim.doctrine == "":
				words = Loc.t("A doctrine chosen, and %d levels of its research") % int(st["need"])
			else:
				words = Loc.t("%d levels of %s research") % [int(st["need"]),
					Loc.t(String(Economy.DOCTRINES[Sim.doctrine]["name"]))]
			go = _show_research
		CoreLevels.Req.OPERATIONS:
			pic = Chips.Gem.new(MachineDB.Res.RIG, 1, 40.0)
			words = Loc.t("%d sites in the galleries cleared since the Core last grew") % int(st["need"])
			go = func() -> void: _show_core()
		CoreLevels.Req.REGIONS:
			pic = _icon_rect("descend", 44)
			words = Loc.t("Regions of the deep map opened: %d, whichever") % int(st["need"])
			go = _show_map
		CoreLevels.Req.REGION_LINES:
			pic = _icon_rect("research", 44)
			words = Loc.t("Levels of the open regions' research: %d, whichever") % int(st["need"])
			go = _show_research
		CoreLevels.Req.ROLES:
			pic = _sheet_picture("crew", "idle", 44.0)
			words = Loc.t("A crew with at least %d Rigs, %d Breakers and %d Surveyors") % [int(st["need"]),
				int(st["need"]), int(st["need"])]
			go = _show_bay
		CoreLevels.Req.BEACONS:
			pic = _icon_rect("descend", 44)
			words = Loc.t("Beacons burning: %d, in whichever regions") % int(st["need"])
			go = _show_map
		CoreLevels.Req.TECH:
			pic = _icon_rect("research", 44)
			words = Loc.t("Levels of the Works' research: %d, the factory's or the crew's") % int(st["need"])
			go = _show_research
		_:
			pic = _icon_rect("heat", 44)
			words = Loc.t("%d machines at working heat, none overheating") % int(st["need"])
			if not met:
				amount = _held_back_words(amount, CoreLevels.holding_back(Sim))
			go = func() -> void: _show_fixes(CoreLevels.holding_back(Sim)["cells"])
	return {"pic": pic, "words": words, "amount": amount, "go": go}


## One of the next level's requirements, as a row to tap.
func _core_req_row(st: Dictionary) -> Button:
	var r: Array = st["req"]
	var met: bool = bool(st["met"])
	var info: Dictionary = _core_req_info(st)
	var go: Callable = info["go"]
	var b := _setting_row(info["pic"], String(info["words"]), String(info["amount"]))
	b.set_meta("core_req", int(r[0]))
	b.set_meta("met", met)
	var mark := _icon_rect("ok" if met else "lock", 34)
	mark.modulate = Color.WHITE if met else Color(1, 1, 1, 0.35)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(b.get_child(0) as HBoxContainer).add_child(mark)
	b.pressed.connect(func():
		Juice.tap()
		_close_overlay()
		go.call())
	return b


## A "working heat" requirement, tapped: too few of them, arm one;
## otherwise go to the ones that do not count, one a tap, worst first --
## overheating, starved, backed up (a full store with no Vault beside it,
## say), too cold -- with the heat view on when heat is the reason.
func _show_working(id: String, need: int, job: String = "") -> void:
	var held: Array = CoreLevels.holding_back(Sim, id, job)["cells"]
	var have: int = Sim.grid.count_of(id)
	if job != "":
		have = 0
		for cell: int in Sim.grid.cells:
			if Sim.grid.machine_at(cell) == id and Sim.grid.job_at(cell) == job:
				have += 1
	if have < need and held.is_empty():
		_arm_only(id)
		return
	_show_fixes(held)


## The machines keeping a Core row from being met, one a tap: the next one
## focused, its sheet open, and the heat view on if its heat is the reason.
## The same list tapped again moves on; a new list starts at its worst.
func _show_fixes(cells: Array) -> void:
	if cells.is_empty():
		_btn_heat.button_pressed = true
		return
	if cells != _fix_list:
		_fix_list = cells.duplicate()
		_fix_cursor = -1
	_fix_cursor = (_fix_cursor + 1) % cells.size()
	var cell: int = int(cells[_fix_cursor])
	var why: String = CoreLevels.why_not_working(Sim, cell)
	if why == "hot" or why == "cold":
		_btn_heat.button_pressed = true
	iso_view.selected_cell = cell
	iso_view.pulse(cell)
	iso_view.focus_cell(cell)
	_show_cell_info(cell)


## "2 / 4", and what holds the rest back: "2 / 4 · 1 starved, 1 too cold".
func _held_back_words(amount: String, held: Dictionary) -> String:
	var parts: Array[String] = []
	var why: Dictionary = held["why"]
	for reason: String in ["hot", "starved", "blocked", "cold", "idle"]:
		if not why.has(reason):
			continue
		var n: int = int(why[reason])
		match reason:
			"hot": parts.append(Loc.t("%d too hot") % n)
			"starved": parts.append(Loc.t("%d starved") % n)
			"blocked": parts.append(Loc.t("%d backed up") % n)
			"cold": parts.append(Loc.t("%d too cold") % n)
			_: parts.append(Loc.t("%d idle") % n)
	return amount if parts.is_empty() else amount + "  ·  " + ", ".join(parts.slice(0, 2))


## Select a machine of type `id` on the board -- its sheet carries the level
## key -- or, with none built, arm one.
func _select_type(id: String) -> void:
	for cell: int in Sim.grid.cells:
		if Sim.grid.machine_at(cell) == id:
			iso_view.focus_cell(cell)
			iso_view.selected_cell = cell
			_show_cell_info(cell)
			return
	_arm_only(id)


## The machine sheet's level key: the type's level, and what the next one
## costs -- or why it cannot be had yet.
func _fill_level_key(id: String) -> void:
	for c in _sheet_up.get_children():
		c.queue_free()
	_sheet_up.visible = MachineDB.has_levels(id)
	if not _sheet_up.visible:
		return
	var lvl: int = Sim.machine_level(id)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var why: String = Sim.machine_upgrade_blocker(id)
	var can: bool = why == ""
	var capped: bool = why == "core"
	var top := _label(Loc.t("Lv.%d") % lvl + ("" if capped else "  ›  %d" % (lvl + 1)), TEXT_MIN,
		Palette.BG if can else Palette.TEXT)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(top)
	if capped or why == "storage":
		var bottom := _label(Loc.t("Core first") if capped else Loc.t("Vault first"), TEXT_MIN, Palette.TEXT_DIM)
		bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(bottom)
	else:
		# The price: credits, and the materials from the Core's store, each
		# red while it is short.
		var cost: Dictionary = Sim.machine_upgrade_cost(id)
		var price := HBoxContainer.new()
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.add_theme_constant_override("separation", 4)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price.add_child(_label(Economy.fmt(float(cost["credits"])), TEXT_MIN,
			Palette.BG if can else (Palette.TEXT_DIM if Sim.credits >= float(cost["credits"]) else Palette.BAD)))
		var mats: Dictionary = cost["materials"]
		for res: int in mats:
			price.add_child(Chips.Gem.new(res, 1, 20.0))
			price.add_child(_label(str(int(mats[res])), TEXT_MIN,
				Palette.BG if can else (Palette.TEXT_DIM if Sim.stock_of(res) >= int(mats[res]) else Palette.BAD)))
		col.add_child(price)
	_sheet_up.add_child(col)
	_sheet_up.disabled = not can
	if id == "vault":
		_sheet_up.tooltip_text = Loc.t("The Vault's level is the Core's store: it holds %d of each material now, %d at the next level.") % [
			Sim.stock_cap(), MachineDB.stock_cap(lvl + 1)]
	elif MachineDB.is_heat_support(id):
		_sheet_up.tooltip_text = Loc.t("Every level, every %s moves %d%% more heat. The Core's level is the limit.") % [
			MachineDB.name_of(id), int(round(MachineDB.SUPPORT_PER_LEVEL * 100.0))]
	else:
		_sheet_up.tooltip_text = Loc.t("Every %s works %d%% faster a level. It is paid in credits and in materials from the Core's store; the Core's level is the limit.") % [
			MachineDB.name_of(id), int(round(MachineDB.LEVEL_SPEED * 100.0))]
	_sheet_up.set_meta("machine_level", lvl)
	_sheet_up.set_meta("blocker", why)


## The sheet's Overdrive key: the step it would take and its price in store
## materials and research, or why it cannot. Shown from the Core's level
## MachineDB.OVERDRIVE_CORE, for a type that can be driven.
func _fill_drive_key(id: String) -> void:
	for c in _sheet_drive.get_children():
		c.queue_free()
	_sheet_drive.visible = MachineDB.can_overdrive(id) and Sim.core_level >= MachineDB.OVERDRIVE_CORE
	if not _sheet_drive.visible:
		return
	var steps: int = Sim.overdrive_steps(id)
	var why: String = Sim.overdrive_blocker(id)
	var can: bool = why == ""
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := _label(Loc.t("Overdrive %d/%d") % [steps, Sim.overdrive_cap()], TEXT_MIN,
		Palette.BG if can else Palette.TEXT)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(top)
	if why == "core" or why == "level" or why == "storage":
		var words: String = Loc.t("Core first")
		if why == "level":
			words = Loc.t("Level %d first") % CoreLevels.overdrive_from(Sim.core_level)
		elif why == "storage":
			words = Loc.t("Vault first")
		var bottom := _label(words, TEXT_MIN, Palette.TEXT_DIM)
		bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(bottom)
	else:
		# The price: store materials and research, each red while short.
		var cost: Dictionary = Sim.overdrive_cost(id)
		var price := HBoxContainer.new()
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.add_theme_constant_override("separation", 4)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mats: Dictionary = cost["materials"]
		for res: int in mats:
			price.add_child(Chips.Gem.new(res, 1, 20.0))
			price.add_child(_label(Economy.fmt(float(mats[res])), TEXT_MIN,
				Palette.BG if can else (Palette.TEXT_DIM if Sim.stock_of(res) >= int(mats[res]) else Palette.BAD)))
		var ic := _icon_rect("research", 20)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		price.add_child(ic)
		price.add_child(_label(Economy.fmt(float(cost["research"])), TEXT_MIN,
			Palette.BG if can else (Palette.TEXT_DIM if Sim.research >= float(cost["research"]) else Palette.BAD)))
		col.add_child(price)
	_sheet_drive.add_child(col)
	_sheet_drive.disabled = not can
	_sheet_drive.tooltip_text = Loc.t("Overdrive: past the level the Core before allowed, every step makes every %s work %d%% harder, with the heat that follows. It is paid from the Core's store, in the two materials the era before made most of (Ingots and Plates under Core 7, Plates and Components under Core 8, Components and Alloy after), and in research, never in credits; each Core level from %d allows %d more steps.") % [
		MachineDB.name_of(id), int(round(MachineDB.LEVEL_SPEED * MachineDB.OVERDRIVE_STEP * 100.0)),
		MachineDB.OVERDRIVE_CORE, MachineDB.OVERDRIVE_PER_CORE]
	_sheet_drive.set_meta("overdrive", steps)
	_sheet_drive.set_meta("blocker", why)


## Why a machine starves, in words: the inputs no machine beside it makes;
## and, beside the Core, that the store is not one of them -- it pays for
## levels and hands nothing out (measured: a Core 8 store held 85,000
## Components and 85,000 Alloy while the Frame Jigs touching it starved).
func _starved_words(cell: int, m: Dictionary) -> String:
	var lack: Array[String] = []
	var stored: bool = false
	for res: int in (m.get("inputs", {}) as Dictionary):
		var fed: bool = false
		for n: int in Sim.grid.bridged_machines(cell):
			fed = fed or (Sim.sim.machine_of(n).get("outputs", {}) as Dictionary).has(res)
		if not fed:
			lack.append(Loc.t(String(MachineDB.RES_NAME[res])))
			stored = stored or Sim.stock_of(res) > 0
	if lack.is_empty():
		return Loc.t("Starved: it is not being fed. Look UPSTREAM.")
	var words: String = Loc.t("Starved: nothing beside it makes %s.") % ", ".join(lack)
	if stored and Sim.sim.core_touching().has(cell):
		words += " " + Loc.t("The Core's store pays for levels; it feeds no machine.")
	return words


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
		"core_grow":
			pic = _core_picture(52.0)
			title = Loc.t("Grow the Core to level %d") % int(e["level"])
			sub = Loc.t("Everything it asked for is ready.")
			go = _show_core
		"core_need":
			var info: Dictionary = _core_req_info(e["st"])
			pic = info["pic"]
			title = String(info["words"])
			sub = Loc.t("For the Core's level %d: %s") % [Sim.core_level + 1, String(info["amount"])]
			go = info["go"]
		"frames":
			pic = Chips.Gem.new(MachineDB.Res.FRAME, 1, 44.0)
			title = Loc.t("The store's Frames run out in %s") % Economy.fmt_duration(float(e["left"]))
			sub = Loc.t("The Benches and the Lens Grinders take more than the Frame Jigs make: more Frame Jigs, or a Rig to feed one beside the Core from the store's Alloy and Components.")
			go = _show_research
		"upgrade":
			var uid: String = String(e["id"])
			pic = Chips.MachineSprite.new(uid, 52.0)
			title = Loc.t("Upgrade the %s to level %d") % [MachineDB.name_of(uid), int(e["level"])]
			sub = Loc.t("Paid in credits and in materials from the Core's store.")
			go = func() -> void: _select_type(uid)
		"overdrive":
			var oid: String = String(e["id"])
			pic = Chips.MachineSprite.new(oid, 52.0)
			title = Loc.t("Overdrive the %s: step %d") % [MachineDB.name_of(oid), int(e["step"])]
			sub = Loc.t("Paid in Ingots, Plates and research, not credits.")
			go = func() -> void: _select_type(oid)
		"post":
			var pc: int = int(e["cell"])
			pic = Chips.MachineSprite.new(Sim.grid.machine_at(pc), 52.0)
			title = Loc.t("Post a Rig to the %s") % MachineDB.name_of(Sim.grid.machine_at(pc))
			sub = Loc.t("It is starved, and the store holds what it takes.")
			go = _show_bay
		"refit":
			pic = _sheet_picture("crew_surveyor" if String(e.get("role", "breaker")) == "surveyor" else "crew_breaker",
				"idle", 52.0)
			if String(e.get("role", "breaker")) == "surveyor":
				title = Loc.t("Refit a Rig as a Surveyor")
				sub = Loc.t("The deep map is open: an expedition into a region goes only with a Surveyor.")
			else:
				title = Loc.t("Refit a Rig as a Breaker")
				sub = Loc.t("Rock in the galleries: a Rig does half there, a Breaker two and a half Rigs' work.")
			go = _show_bay
		"expedition":
			var reg: Dictionary = Operations.REGIONS[String(e["region"])]
			pic = _icon_rect("descend", 52)
			title = Loc.t("Send an expedition into %s") % Loc.t(String(reg["name"]))
			sub = Loc.t("It opens the region: its sites, its research, and for good: %s") % Loc.t(String(reg["advantage"]))
			go = _show_map
		"beacon":
			var reg2: Dictionary = Operations.REGIONS[String(e["region"])]
			pic = _icon_rect("descend", 52)
			title = Loc.t("Light a Beacon in %s") % Loc.t(String(reg2["name"]))
			sub = Loc.t("While it burns: %s") % Loc.t(String(Operations.CONTROL_TECH[String(e["region"])]))
			go = _show_map
		"tune":
			var tc: int = int(e["cell"])
			pic = _sheet_picture("crew_surveyor", "work", 52.0)
			title = Loc.t("A Surveyor to tune the %s") % MachineDB.job_name(Sim.grid.machine_at(tc), Sim.grid.job_at(tc))
			sub = Loc.t("While it stays: half the Resonite a Lens, half the Lenses a Prism.")
			go = _show_bay
		"sortie":
			var si: int = int(e["i"])
			var sk: Dictionary = Operations.KINDS[String(Sim.site(si)["kind"])]
			pic = Chips.Gem.new(MachineDB.Res.RIG, 1, 44.0)
			title = Loc.tn("Send %d Rig to the %s", "Send %d Rigs to the %s", int(e["n"])) % [int(e["n"]),
				Loc.t(String(sk["name"]))]
			if bool(e.get("share", false)):
				sub = Loc.t("Too strong to clear at once: they bring home %d%% of it and leave it weaker.") \
					% int(round(float(e["part"]) * 100.0))
			else:
				sub = Loc.t("They clear it, and come home with what it holds.")
			go = _show_galleries
		"contract":
			var ci: int = int(e["i"])
			var cc: Dictionary = Sim.contract(ci)
			pic = Chips.Gem.new(int(cc["res"]), 1, 44.0)
			title = Loc.t("Fill a contract: %d %s") % [int(cc["n"]),
				Loc.t(String(MachineDB.RES_NAME[int(cc["res"])]))]
			sub = _contract_pay_words(ci)
			go = _show_core
		"research":
			var n2: int = int(e["n"])
			pic = _icon_rect("research", 52)
			title = Loc.tn("%d research line ready", "%d research lines ready", n2) % n2
			sub = Loc.t("What it buys stays, even after a collapse.")
			go = _show_research
		"plan":
			pic = _icon_rect("research", 52)
			title = Loc.t("Plan the research the Frames make")
			sub = Loc.t("The Core asks for research: choose the line the Assay Benches work towards.")
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


func _info(title: String, text: String, actions: Array = []) -> void:
	var l := _label(text, 20, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_open_overlay(title, l, actions)


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
	var job: String = Sim.grid.job_at(cell)
	var m: Dictionary = Sim.sim.machine_of(cell)
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
			verdict = _starved_words(cell, m)
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
	_sheet_body.add_child(Chips.recipe(id, 42.0, job))
	_fill_level_key(id)
	_fill_drive_key(id)
	_fill_mode_key(cell)
	_fill_job_key(cell)

	# Heat: the bar is the machine's temperature, the notch where it wants to
	# be, the red mark the end of its safe range; the numbers beside it; a
	# tap shows where the heat comes from.
	var safe: Vector2 = MachineDB.safe_range(id, Sim.sim.tolerance_bonus, job)
	var top: float = maxf(safe.y * 1.6, heat * 1.1) + 0.5
	var hg := Chips.Gauge.new(130, 14)
	hg.value = heat / top
	hg.target = float(m["heat_optimum"]) / top
	hg.limit = safe.y / top if safe.y < 50.0 else -1.0
	hg.fill = Palette.BAD if Sim.sim.overheated_at(cell) else Palette.heat_color(heat)
	hg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var heat_row := HBoxContainer.new()
	heat_row.add_theme_constant_override("separation", 8)
	heat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heat_row.add_child(_icon_rect("heat", 30))
	heat_row.add_child(hg)
	# Short on the sheet -- the temperature and the end of the safe range
	# (the red mark); the heat card says it in words.
	heat_row.add_child(_label("%.1f / %.1f" % [heat, safe.y] if safe.y < 50.0 else "%.1f" % heat, TEXT_MIN,
		Palette.BAD if heat > safe.y else Palette.TEXT_DIM))
	var heat_key := Button.new()
	heat_key.flat = true
	heat_key.custom_minimum_size = Vector2(0, 40)
	heat_key.tooltip_text = Loc.t("Where its heat comes from")
	heat_key.set_meta("heat_key", cell)
	heat_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heat_key.add_child(heat_row)
	heat_key.pressed.connect(func(): _show_heat(cell))
	_sheet_stats.add_child(heat_key)
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
	var recipe: String = MachineDB.recipe_text(id, job)
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
	"resonance": ["amplifier", "energy"],
	"heat_tolerance": ["smelter", "heat"],
	"offline_cap": ["@foreman", "star"],
	"offline_rate": ["@foreman", "energy"],
	"core_yield": ["@core", "cores"],
	"blueprint_slots": ["@icon:codex", "upgrade"],
	"vein_1": ["drill", "upgrade"],
	"survey_1": ["@icon:descend", "credits"],
	"cryo_1": ["coolant", "cold"],
	"mass_1": ["assembler", "heat"],
	"jigs_1": ["assembler", "credits"],
	"benches_1": ["lab", "research"],
	"assay_racks": ["lab", "research"],
	"jig_lines": ["assembler", "energy"],
	"bench_chutes": ["@core", "research"],
	"haul_harness": ["@crew:crew:carry", "energy"],
	"bay_wing": ["@crew:crew:idle", "upgrade"],
	"survey_kit": ["@crew:crew_surveyor:work", "star"],
}
## The research grid's columns: three side by side on a landscape phone, two
## where the screen is too narrow for three to keep their pictures big.
const RESEARCH_COLUMNS := 3
const RESEARCH_CARD_MIN_W := 330.0


## Research lines the grid does not offer (Worklist.HIDDEN): none since the
## Core card saves and lays blueprints, which Drafting Table's slots are for.
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
	# Salvage, once the galleries have opened: what the Robotics lines cost.
	if Operations.slots(Sim.core_level) > 0 or Sim.salvage > 0:
		var gap3 := Control.new()
		gap3.custom_minimum_size = Vector2(18, 0)
		wallet.add_child(gap3)
		wallet.add_child(_icon_rect("settings", 38))
		wallet.add_child(_label(str(Sim.salvage), 26, Palette.TEXT))
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(12, 0)
	wallet.add_child(gap2)

	var w: float = minf(1240.0, size.x - 64.0)
	var grid := GridContainer.new()
	grid.columns = RESEARCH_COLUMNS if w >= RESEARCH_CARD_MIN_W * RESEARCH_COLUMNS + 60.0 else 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	# Branch by branch (Economy.BRANCHES), each line in the tree's order.
	for branch: String in Economy.BRANCHES:
		for id: String in Economy.TREE_ORDER:
			if not HIDDEN_RESEARCH.has(id) and String(Economy.RESEARCH_TREE[id].get("branch", "")) == branch:
				grid.add_child(_research_card(id))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	if Sim.core_level >= Operations.REGION_CORE:
		body.add_child(_research_budget())
	body.add_child(_doctrine_row())
	body.add_child(grid)
	_open_overlay(Loc.t("Research"), body, [], 1240.0, wallet)


## Where the research comes from and where it is going, above the grid from
## the deep map on: what a Frame is worth sold against taught, the Frames
## made and where they went this last while, the research an hour, and the
## plan with how long until it is in.
func _research_budget() -> Control:
	var p := _panel(Palette.PANEL_HI, 0.96)
	p.set_meta("research_budget", true)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	p.add_child(col)
	var fr: Dictionary = Sim.frame_rates
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(Chips.Gem.new(MachineDB.Res.FRAME, 1, 40.0))
	var worth := _label(Loc.t("A Frame sells for %s credits, or teaches %s research at an Assay Bench.") % [
		Economy.fmt(Sim.frame_sale_value()), Economy.fmt(Sim.frame_research_value())], 18, Palette.TEXT)
	worth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	worth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(worth)
	col.add_child(top)
	var flow := _label(Loc.t("Frames an hour: %s made, %s taught, %s ground into Lenses; %s in the store.") % [
		Economy.fmt(float(fr.get("made", 0.0)) * 3600.0), Economy.fmt(float(fr.get("research", 0.0)) * 3600.0),
		Economy.fmt(float(fr.get("lens", 0.0)) * 3600.0), Economy.fmt(float(Sim.stock_of(MachineDB.Res.FRAME)))],
		16, Palette.TEXT_DIM)
	flow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(flow)
	# The store running dry, while there is time to lay a Frame Jig.
	var left: float = Sim.frames_left()
	if left >= 0.0 and left < Worklist.FRAMES_WARN:
		var dry := _label(Loc.t("At this rate the store's Frames run out in %s: the Benches and the Lens Grinders take more than the Frame Jigs make.")
			% Economy.fmt_duration(left), 16, Palette.WARN)
		dry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dry.set_meta("frames_dry", true)
		col.add_child(dry)
	var rate: float = Sim.research_per_sec * 3600.0
	var plan_words: String = Loc.t("No plan: open a line's ? and plan it -- its next level is bought the moment it is paid for.")
	if Sim.research_plan != "":
		var plan_name: String = Loc.t(String(Economy.RESEARCH_TREE[Sim.research_plan]["name"]))
		var eta: float = Sim.plan_eta()
		var b: String = Sim.research_blocker(Sim.research_plan)
		if b == "needs":
			plan_words = Loc.t("Plan: %s -- it opens behind what it needs.") % plan_name
		elif b == "core":
			plan_words = Loc.t("Plan: %s -- the Core's level holds it.") % plan_name
		elif b == "frames":
			plan_words = Loc.t("Plan: %s -- the store is short of Frames.") % plan_name
		elif eta < 0.0:
			plan_words = Loc.t("Plan: %s -- no research is being made.") % plan_name
		else:
			plan_words = Loc.t("Plan: %s -- in %s.") % [plan_name, Economy.fmt_duration(eta)]
	var plan := _label(Loc.t("Research %s an hour.") % Economy.fmt(rate) + " " + plan_words, 16, Palette.RESEARCH)
	plan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(plan)
	return p


## What research line `id` still opens behind, in words.
func _need_words(need: Array) -> String:
	match String(need[0]):
		"line":
			return Loc.t("%s at level %d") % [Loc.t(String(Economy.RESEARCH_TREE[String(need[1])]["name"])), int(need[2])]
		"beacons":
			return Loc.t("%d Beacons burning") % int(need[1])
		"working":
			return Loc.t("%d %s at work") % [int(need[2]), MachineDB.job_name(String(need[1]),
				String(need[3]) if need.size() > 3 else "")]
		"region":
			return Loc.t("%s open") % Loc.t(String(Operations.REGIONS[String(need[1])]["name"]))
	return ""


## The shaft's doctrine (Economy.DOCTRINES), above the research grid: the
## Core's level that opens it; the three to choose from; or the one chosen.
func _doctrine_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.set_meta("doctrine", Sim.doctrine)
	if Sim.doctrine != "":
		var d: Dictionary = Economy.DOCTRINES[Sim.doctrine]
		row.add_child(_icon_rect("ok", 40))
		var l := _label(Loc.t("Doctrine: %s. %s") % [Loc.t(String(d["name"])), Loc.t(String(d["short"]))],
			20, Palette.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		return row
	if not Sim.can_choose_doctrine():
		row.add_child(_icon_rect("lock", 40))
		var l2 := _label(Loc.t("Core level %d opens doctrines: one of three ways to grow the shaft, with research of its own.")
			% Economy.DOCTRINE_CORE, 20, Palette.TEXT_DIM)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l2)
		return row
	for id: String in Economy.DOCTRINE_ORDER:
		var d2: Dictionary = Economy.DOCTRINES[id]
		var b := _button("", Palette.RESEARCH)
		b.custom_minimum_size = Vector2(0, MIN_TOUCH + 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("choose_doctrine", id)
		var col := VBoxContainer.new()
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var n := _label(Loc.t(String(d2["name"])), 22, Palette.BG)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		var sh := _label(Loc.t(String(d2["short"])), 15, Palette.BG)
		sh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(sh)
		b.add_child(col)
		b.pressed.connect(func(): _confirm_doctrine(id))
		row.add_child(b)
	return row


## Choosing a doctrine is for the whole shaft: said before it is done.
func _confirm_doctrine(id: String) -> void:
	var d: Dictionary = Economy.DOCTRINES[id]
	var text: String = Loc.t("Follow %s in this shaft? %s\n\nIts two lines of research open, and the other doctrines' close until the shaft collapses. What you buy in them is this shaft's: a collapse clears it, and the next shaft chooses again.") % [
		Loc.t(String(d["name"])), Loc.t(String(d["short"]))]
	var l := _label(text, 20, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_open_overlay(Loc.t(String(d["name"])), l, [{"text": Loc.t("Follow it"), "color": Palette.RESEARCH,
		"cb": func():
			if Sim.choose_doctrine(id):
				Juice.upgrade()
				_show_research()
				_refresh()}])


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
	# A doctrine's line, in a shaft that does not follow it.
	var doctrine: String = Economy.doctrine_of(id)
	var other: bool = doctrine != "" and doctrine != Sim.doctrine
	# A region's line, before the region is open.
	var region: String = String(u.get("region", ""))
	var sealed: bool = region != "" and not Sim.region_open(region)
	# What it opens behind (Economy "requires").
	var needs: Array = Sim.research_needs(id)
	var planned: bool = Sim.research_plan == id
	# The Core's level is this line's limit: the level that lets it go on.
	var core_needed: int = 0
	if not maxed and lvl >= Sim.research_cap(id):
		core_needed = Sim.core_level + 1
		while Economy.research_cap(id, core_needed) <= lvl and core_needed < Sim.core_level + 100:
			core_needed += 1

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
	elif planned:
		sb.border_color = Palette.CORE
		sb.set_border_width_all(3)
		sb.bg_color = Color(Palette.PANEL_HI.lerp(Palette.CORE, 0.10), 0.96)
	elif can:
		sb.border_color = Palette.RESEARCH
		sb.set_border_width_all(3)
		sb.bg_color = Color(Palette.PANEL_HI.lerp(Palette.RESEARCH, 0.12), 0.96)
	card.set_meta("research_id", id)
	card.set_meta("state", "max" if maxed else ("ready" if can else ("doctrine" if other
		else ("core" if core_needed > 0 else ("needs" if not needs.is_empty() and not sealed
		else ("locked" if locked else "short"))))))
	card.set_meta("planned", planned)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_row.add_child(_research_art(id, 124.0, locked))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 4)
	# Its branch, and a doctrine's name on a doctrine's line.
	var tag: String = Loc.t(String(Economy.BRANCHES.get(String(u.get("branch", "")), ""))).to_upper()
	if doctrine != "":
		tag += " · " + Loc.t(String(Economy.DOCTRINES[doctrine]["name"]))
	if planned:
		tag += " · " + Loc.t("Planned").to_upper()
	# Wrapped, so a long language's branch and doctrine never widen the card.
	var tag_lbl := _label(tag, 14, Palette.RESEARCH if doctrine == "" else Palette.CORE)
	tag_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(tag_lbl)
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
	elif sealed:
		var only := HBoxContainer.new()
		only.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		only.alignment = BoxContainer.ALIGNMENT_CENTER
		only.custom_minimum_size = Vector2(0, MIN_TOUCH)
		only.add_theme_constant_override("separation", 8)
		only.add_child(_icon_rect("lock", 40))
		var only_lbl := _label(Loc.t("Opens with %s") % Loc.t(String(Operations.REGIONS[region]["name"])), 20,
			Palette.TEXT_DIM)
		only_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		only_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		only.add_child(only_lbl)
		bottom.add_child(only)
	elif other:
		var only := HBoxContainer.new()
		only.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		only.alignment = BoxContainer.ALIGNMENT_CENTER
		only.custom_minimum_size = Vector2(0, MIN_TOUCH)
		only.add_theme_constant_override("separation", 8)
		only.add_child(_icon_rect("lock", 40))
		var only_lbl := _label(Loc.t("%s only") % Loc.t(String(Economy.DOCTRINES[doctrine]["name"])), 20,
			Palette.TEXT_DIM)
		only_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		only_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		only.add_child(only_lbl)
		bottom.add_child(only)
	elif core_needed > 0:
		var wait := HBoxContainer.new()
		wait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wait.alignment = BoxContainer.ALIGNMENT_CENTER
		wait.custom_minimum_size = Vector2(0, MIN_TOUCH)
		wait.add_theme_constant_override("separation", 8)
		wait.add_child(_icon_rect("lock", 40))
		wait.add_child(_label(Loc.t("Core level %d") % core_needed, 22, Palette.TEXT_DIM))
		bottom.add_child(wait)
	elif not needs.is_empty():
		var wait2 := HBoxContainer.new()
		wait2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wait2.alignment = BoxContainer.ALIGNMENT_CENTER
		wait2.custom_minimum_size = Vector2(0, MIN_TOUCH)
		wait2.add_theme_constant_override("separation", 8)
		wait2.add_child(_icon_rect("lock", 40))
		var parts: Array[String] = []
		for need: Array in needs:
			parts.append(_need_words(need))
		var need_lbl := _label(Loc.t("Needs %s") % ", ".join(parts), 18, Palette.TEXT_DIM)
		need_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		need_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wait2.add_child(need_lbl)
		bottom.add_child(wait2)
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
		if int(c["salvage"]) > 0:
			price.add_child(_icon_rect("settings", 36))
			price.add_child(_label(str(int(c["salvage"])), 24,
				ok_col if Sim.salvage >= int(c["salvage"]) else Palette.BAD))
		if int(c["frames"]) > 0:
			price.add_child(Chips.Gem.new(MachineDB.Res.FRAME, 1, 34.0))
			price.add_child(_label(Economy.fmt(float(c["frames"])), 24,
				ok_col if Sim.stock_of(MachineDB.Res.FRAME) >= int(c["frames"]) else Palette.BAD))
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
	# The plan: this line's next level bought the moment it is paid for.
	# The "?" sheet also plans the line (Sim.research_plan): its next level
	# bought the moment it is paid for. On the sheet, not on the card, so the
	# card keeps its width in any language.
	var plannable: bool = not maxed and not other and not sealed and core_needed == 0
	var help := _help_button(Loc.t(String(u["name"])), func() -> String:
		var t: String = Loc.t(String(u["desc"]))
		if locked:
			t += "\n\n" + Loc.t("This one also costs Cores. You get Cores when you collapse the shaft.")
		if core_needed > 0:
			t += "\n\n" + Loc.t("The Factory Core's level is this line's limit. At level %d it goes further.") % core_needed
		return t, func() -> Array:
			if not plannable:
				return []
			var now: bool = Sim.research_plan == id
			return [{"text": Loc.t("Stop planning it") if now else Loc.t("Plan it"), "color": Palette.CORE,
				"cb": func():
					Sim.plan_research("" if now else id)
					_show_research()}])
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
	elif subject.begins_with("@crew:"):
		pic = _sheet_picture(subject.get_slice(":", 1), subject.get_slice(":", 2), px)
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
	var info: Dictionary = iso_view.core_info() if iso_view != null else IsoArt.layout().get("core", {})
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
			gained) % gained + "\n\n" + Loc.t("Also kept: your blueprints, and half of the Core's best level -- the next shaft's Core starts at level %d. Its doctrine, and the doctrine's research, start again.") % Sim.foundation()))
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
	for pic: Control in [_icon_rect("cores", 76), _icon_rect("upgrade", 76), _icon_rect("codex", 76)]:
		kept.add_child(_fated(pic, 76.0, true))
	fate.add_child(kept)
	body.add_child(fate)
	# The Core's foundation: where the next shaft starts.
	var found := _label(Loc.t("The next shaft's Core starts at level %d.") % Sim.foundation(), 22, Palette.CORE)
	found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	found.set_meta("foundation", Sim.foundation())
	body.add_child(found)

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
	else:
		opens.free()
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
