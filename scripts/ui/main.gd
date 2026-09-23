extends Control

## The whole interface, built in code.
##
## No .tscn beyond an empty root. That is not dogma — it is because a UI
## assembled in one readable file can be reviewed, diffed and regenerated,
## while a scene file of a hundred nodes can only be edited by hand in an
## editor. For a project whose production model is "one person plus a lot of
## generated code", the code-built tree is the maintainable one.
##
## Layout is a single vertical stack sized for a phone in portrait:
##
##   header    what you have, and what it is growing at
##   stratum   where you are and what this depth does to you
##   board     the game
##   palette   what you can place, and what it costs
##   actions   descend / research / collapse

const PANEL_FADE := 0.14

var grid_view: GridView
var _header: Control
var _stratum_bar: Control
var _palette_row: HBoxContainer
var _actions: HBoxContainer
var _hint: Label
var _overlay: Control
var _toast: Label

var _lbl_credits: Label
var _lbl_rate: Label
var _lbl_research: Label
var _lbl_cores: Label
var _lbl_depth: Label
var _lbl_quota: Label
var _lbl_mods: Label
var _lbl_problems: Button
var _btn_heat: Button
var _btn_descend: Button
var _sheet: PanelContainer
var _sheet_body: VBoxContainer
var _sheet_title: Label
var _palette_buttons: Dictionary = {}

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


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Sim.stats_changed.connect(_refresh)
	Sim.stats_changed.connect(_tutorial_watch)
	Sim.depth_changed.connect(func(_d): _rebuild_palette(); _refresh())
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
		if grid_view != null:
			grid_view.queue_redraw()
		_refresh())
	SelfTest.note_launch()
	Sim.start()
	_rebuild_palette()
	_shown_credits = Sim.credits
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


## --- construction ----------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.offset_left = Palette.PAD
	root.offset_right = -Palette.PAD
	root.offset_top = Palette.PAD
	root.offset_bottom = -Palette.PAD
	add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_stratum_bar())

	_hint = _label("", 20, Palette.ACCENT)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	grid_view = GridView.new()
	grid_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_view.cell_tapped.connect(_on_cell_tapped)
	grid_view.cell_long_pressed.connect(_on_cell_long_pressed)
	grid_view.machine_moved.connect(func(from_cell: int, to_cell: int):
		_push_undo({"kind": "move", "cell": to_cell, "from": from_cell})
		_maybe_advance_tutorial()
		_refresh())
	root.add_child(grid_view)

	root.add_child(_build_palette())
	root.add_child(_build_actions())

	_build_sheet()

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	# The standard mobile pattern: the thing that just happened, and one tap to
	# take it back, for a few seconds. Cheaper than a confirmation on every
	# placement and far cheaper than a mis-tap the player cannot reverse.
	_undo_btn = Button.new()
	_undo_btn.text = "Undo"
	_undo_btn.visible = false
	_undo_btn.custom_minimum_size = Vector2(120, 52)
	_undo_btn.add_theme_font_size_override("font_size", 19)
	_undo_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_undo_btn.offset_left = -60
	_undo_btn.offset_right = 60
	_undo_btn.offset_top = -132
	_undo_btn.offset_bottom = -80
	_undo_btn.pressed.connect(_do_undo)
	add_child(_undo_btn)

	_toast = _label("", 22, Palette.TEXT)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.offset_top = -220
	_toast.offset_bottom = -170
	_toast.visible = false
	add_child(_toast)


func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	return l


func _panel(col: Color = Palette.PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = int(Palette.RADIUS)
	sb.corner_radius_top_right = int(Palette.RADIUS)
	sb.corner_radius_bottom_left = int(Palette.RADIUS)
	sb.corner_radius_bottom_right = int(Palette.RADIUS)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	return p


func _button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(0, 64)   # a comfortable thumb target
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if state != "disabled" else col.darkened(0.55)
		if state == "pressed":
			sb.bg_color = col.darkened(0.2)
		sb.corner_radius_top_left = int(Palette.RADIUS)
		sb.corner_radius_top_right = int(Palette.RADIUS)
		sb.corner_radius_bottom_left = int(Palette.RADIUS)
		sb.corner_radius_bottom_right = int(Palette.RADIUS)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Palette.BG)
	b.add_theme_color_override("font_disabled_color", Palette.TEXT_FAINT)
	return b


func _build_header() -> Control:
	var p := _panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	p.add_child(row)

	var money := VBoxContainer.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_credits = _label("0", 34, Palette.ACCENT)
	_lbl_rate = _label("0 /s", 17, Palette.TEXT_DIM)
	money.add_child(_lbl_credits)
	money.add_child(_lbl_rate)
	row.add_child(money)

	var sci := VBoxContainer.new()
	_lbl_research = _label("0", 24, Palette.RESEARCH)
	sci.add_child(_label("RESEARCH", 13, Palette.TEXT_FAINT))
	sci.add_child(_lbl_research)
	row.add_child(sci)

	var core := VBoxContainer.new()
	_lbl_cores = _label("0", 24, Palette.CORE)
	core.add_child(_label("CORES", 13, Palette.TEXT_FAINT))
	core.add_child(_lbl_cores)
	row.add_child(core)

	var menu := Button.new()
	menu.text = "☰"
	menu.add_theme_font_size_override("font_size", 26)
	menu.flat = true
	menu.custom_minimum_size = Vector2(56, 56)
	menu.add_theme_color_override("font_color", Palette.TEXT_DIM)
	menu.pressed.connect(_show_settings)

	# The Codex sits in the header rather than behind the menu because its
	# whole job is to be reachable at the moment a player is confused, and a
	# player who is confused does not go looking through settings.
	var codex := _button("?", Palette.PANEL_HI)
	codex.add_theme_color_override("font_color", Palette.TEXT_DIM)
	codex.custom_minimum_size = Vector2(56, 56)
	codex.pressed.connect(_open_codex)
	row.add_child(codex)
	row.add_child(menu)

	_header = p
	return p


func _build_stratum_bar() -> Control:
	var p := _panel(Palette.PANEL_HI)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	p.add_child(col)

	var top := HBoxContainer.new()
	_lbl_depth = _label("Stratum 0", 22, Palette.TEXT)
	_lbl_depth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_quota = _label("", 18, Palette.TEXT_DIM)
	top.add_child(_lbl_depth)
	top.add_child(_lbl_quota)
	col.add_child(top)

	_lbl_mods = _label("", 16, Palette.WARN)
	_lbl_mods.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lbl_mods)

	# The one line that says what is wrong with the board, and the one button
	# that explains why. Between them these answer the question every factory
	# game struggles with -- "which machine is the problem" -- without the
	# player having to inspect tiles one at a time.
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)

	_lbl_problems = Button.new()
	_lbl_problems.flat = true
	_lbl_problems.text = ""
	_lbl_problems.add_theme_font_size_override("font_size", 16)
	_lbl_problems.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_problems.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_lbl_problems.custom_minimum_size = Vector2(0, 40)
	_lbl_problems.pressed.connect(_cycle_problem)
	tools.add_child(_lbl_problems)

	_btn_heat = Button.new()
	_btn_heat.text = "Heat"
	_btn_heat.toggle_mode = true
	_btn_heat.add_theme_font_size_override("font_size", 16)
	_btn_heat.custom_minimum_size = Vector2(88, 40)
	_btn_heat.toggled.connect(func(on: bool):
		grid_view.set_overlay(GridView.Overlay.HEAT if on else GridView.Overlay.NONE)
		if on:
			Sim.tutorial_saw_heat = true
			_maybe_advance_tutorial()
		Juice.tap())
	tools.add_child(_btn_heat)

	col.add_child(tools)

	_stratum_bar = p
	return p


## The detail sheet lives at the BOTTOM of the screen and is not modal.
##
## A popover next to the tapped tile would sit under the thumb that is
## pointing at it, which is the most common complaint about inspecting things
## in mobile builds of this genre. Anchoring it to the bottom edge keeps the
## board visible and leaves the player free to tap another tile and watch the
## sheet follow -- comparing two machines is the thing they are actually doing.
func _build_sheet() -> void:
	_sheet = _panel(Palette.PANEL_HI)
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.offset_left = Palette.PAD
	_sheet.offset_right = -Palette.PAD
	_sheet.offset_top = -280
	_sheet.offset_bottom = -Palette.PAD
	_sheet.visible = false
	add_child(_sheet)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_sheet.add_child(col)

	var head := HBoxContainer.new()
	_sheet_title = _label("", 22, Palette.TEXT)
	_sheet_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_sheet_title)
	var close := Button.new()
	close.text = "✕"
	close.flat = true
	close.custom_minimum_size = Vector2(48, 48)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(_close_sheet)
	head.add_child(close)
	col.add_child(head)

	_sheet_body = VBoxContainer.new()
	_sheet_body.add_theme_constant_override("separation", 3)
	col.add_child(_sheet_body)


func _close_sheet() -> void:
	_sheet.visible = false
	grid_view.selected_cell = -1
	grid_view.queue_redraw()


## Step through whatever is wrong, worst first. One button, one tap per
## problem, selection lands on the tile -- which is as close as a board this
## size needs to get to a diagnostics tool.
func _cycle_problem() -> void:
	var cells: Array[int] = Sim.sim.problem_cells()
	if cells.is_empty():
		_toast_msg("Nothing is stalled or overheating.")
		return
	_problem_cursor = (_problem_cursor + 1) % cells.size()
	var cell: int = cells[_problem_cursor]
	grid_view.selected_cell = cell
	grid_view.pulse(cell)
	grid_view.queue_redraw()
	_show_cell_info(cell)
	Juice.tap()


func _build_palette() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 108)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_palette_row = HBoxContainer.new()
	_palette_row.add_theme_constant_override("separation", 8)
	scroll.add_child(_palette_row)
	return scroll


func _build_actions() -> Control:
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)

	_btn_descend = _button("Descend", Palette.ACCENT)
	_btn_descend.pressed.connect(_on_descend)
	_actions.add_child(_btn_descend)

	var research_btn := _button("Research", Palette.RESEARCH)
	research_btn.pressed.connect(_show_research)
	_actions.add_child(research_btn)

	var collapse_btn := _button("Collapse", Palette.CORE)
	collapse_btn.pressed.connect(_show_collapse)
	_actions.add_child(collapse_btn)

	return _actions


func _rebuild_palette() -> void:
	for c in _palette_row.get_children():
		c.queue_free()
	_palette_buttons.clear()
	for id in MachineDB.ORDER:
		if not Sim.is_unlocked(id):
			continue
		_palette_row.add_child(_make_palette_button(id))


func _make_palette_button(id: String) -> Control:
	var m: Dictionary = MachineDB.get_machine(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(104, 96)
	b.toggle_mode = true
	b.tooltip_text = "%s\n%s\n%s" % [m["name"],
		MachineDB.recipe_text(id), m["desc"]]
	b.add_theme_font_size_override("font_size", 15)
	b.text = "%s\n%s\n%s" % [Palette.machine_glyph(id), m["name"],
		Economy.fmt(Sim.cost_of(id))]
	b.add_theme_color_override("font_color", Palette.TEXT)
	b.pressed.connect(func(): _arm(id))
	_palette_buttons[id] = b
	return b


## --- interaction -----------------------------------------------------------

func _arm(id: String) -> void:
	Juice.tap()
	_armed = "" if _armed == id else id
	grid_view.arm_id = _armed
	for k: String in _palette_buttons:
		_palette_buttons[k].button_pressed = (k == _armed)
	grid_view.queue_redraw()


func _on_cell_tapped(cell: int) -> void:
	if Sim.is_blocked(cell):
		Juice.blocked()
		_toast_msg("This part of the shaft has collapsed.")
		return
	if Sim.grid.is_empty(cell):
		_close_sheet()
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
			grid_view.pulse(cell)
			_push_undo({"kind": "place", "cell": cell, "id": _armed,
				"price": price})
			_shown_credits = Sim.credits
			_refresh()
			_maybe_advance_tutorial()
		return
	grid_view.selected_cell = -1 if grid_view.selected_cell == cell else cell
	if grid_view.selected_cell >= 0:
		Juice.tap()
		_show_cell_info(cell)
	else:
		_close_sheet()
	grid_view.queue_redraw()


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
		Juice.punch(_stratum_bar, 0.06, 0.30)
		_close_sheet()
		_shown_credits = Sim.credits
		_toast_msg("Stratum %d." % Sim.depth)
		_refresh_hint()


func _on_unlocked(ids: Array) -> void:
	if ids.is_empty():
		return
	var names: Array = []
	for id in ids:
		names.append(String(MachineDB.get_machine(id)["name"]))
	_rebuild_palette()
	Juice.unlock()
	_info("New machine unlocked", "\n".join(names) +
		"\n\nIt is in the tray at the bottom. What it is next to matters more than how many you own.")


func _on_collapsed(gained: int) -> void:
	_rebuild_palette()
	_close_sheet()
	_shown_credits = Sim.credits
	Juice.collapse()
	# Framed as what is kept, never as what is lost, and never as a "reset".
	# The genre's most cited progression failure is a prestige that reads as
	# punishment, and the wording is half of that.
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
	_lbl_rate.text = "%s /s" % Economy.fmt(Sim.credits_per_sec)
	_lbl_research.text = Economy.fmt(Sim.research)
	_lbl_cores.text = str(Sim.cores)

	var s: Dictionary = Sim.stratum()
	_lbl_depth.text = "Stratum %d" % Sim.depth
	_lbl_quota.text = "descend at %s" % Economy.fmt(Sim.quota())
	var mods: Array = s.get("modifiers", [])
	if mods.is_empty():
		_lbl_mods.text = "Nothing unusual down here."
		_lbl_mods.add_theme_color_override("font_color", Palette.TEXT_FAINT)
	else:
		var parts: Array = []
		for id in mods:
			parts.append("%s — %s" % [Strata.modifier_name(id), Strata.modifier_desc(id)])
		_lbl_mods.text = "\n".join(parts)
		_lbl_mods.add_theme_color_override("font_color", Palette.WARN)

	_refresh_problems()

	_btn_descend.disabled = not Sim.can_descend()
	for id: String in _palette_buttons:
		var b: Button = _palette_buttons[id]
		var m: Dictionary = MachineDB.get_machine(id)
		b.text = "%s\n%s\n%s" % [Palette.machine_glyph(id), m["name"],
			Economy.fmt(Sim.cost_of(id))]
		b.add_theme_color_override("font_color",
			Palette.TEXT if Sim.can_afford(id) else Palette.TEXT_FAINT)


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
		_toast_msg(Tutorial.RESEARCH_NUDGE)


## One line, counts only, in the order a player should deal with them:
## starvation first because it stops production dead, then backpressure, then
## heat, which only costs a percentage.
func _refresh_problems() -> void:
	var c: Dictionary = Sim.sim.problem_counts()
	# Heard once when it starts, not every frame it continues. Juice throttles
	# the sound itself; this only fires on the transition.
	if int(c["thermal"]) > _last_thermal and int(c["thermal"]) > 0:
		Juice.heat_warning()
	_last_thermal = int(c["thermal"])
	var parts: Array[String] = []
	if int(c["starved"]) > 0:
		parts.append("%d starved" % int(c["starved"]))
	if int(c["blocked"]) > 0:
		parts.append("%d backed up" % int(c["blocked"]))
	if int(c["thermal"]) > 0:
		parts.append("%d off temperature" % int(c["thermal"]))
	if parts.is_empty():
		_lbl_problems.text = "  Everything is running."
		_lbl_problems.add_theme_color_override("font_color", Palette.TEXT_FAINT)
	else:
		_lbl_problems.text = "  " + "  ·  ".join(parts) + "   ›"
		_lbl_problems.add_theme_color_override("font_color", Palette.WARN)


## --- onboarding ------------------------------------------------------------
##
## One line at a time, a pulsing outline where the answer is, and nothing that
## has to be dismissed. The steps live in `Tutorial` as data; this only draws
## them and asks, after every change to the board, whether the player has done
## the thing yet.

func _refresh_hint() -> void:
	var step: int = Sim.tutorial_step()
	if Tutorial.is_done(step):
		_hint.visible = false
		grid_view.highlight_cells = []
		_pulse_control("")
		grid_view.queue_redraw()
		return
	_hint.visible = true
	_hint.text = Tutorial.line_for(step)
	grid_view.highlight_cells = Tutorial.highlight(step, Sim)
	_pulse_control(Tutorial.highlight_control(step))
	# Arming the suggested machine for them removes a tap and a guess. They
	# can still pick anything else; nothing here is modal.
	var arm: String = Tutorial.arm_for(step)
	if arm != "" and _armed != arm and Sim.is_unlocked(arm):
		_armed = arm
		grid_view.arm_id = arm
		for k: String in _palette_buttons:
			_palette_buttons[k].button_pressed = (k == arm)
	grid_view.queue_redraw()


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


func _open_overlay(title: String, body: Control, actions: Array) -> void:
	_close_overlay()
	_overlay.visible = true

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventScreenTouch and e.pressed:
			_close_overlay())
	_overlay.add_child(dim)

	var card := _panel(Palette.PANEL)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -330
	card.offset_right = 330
	card.offset_top = -420
	card.offset_bottom = 420
	_overlay.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	col.add_child(_label(title, 28, Palette.TEXT))

	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

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
	_sheet_title.text = String(m["name"])

	# The verdict first, in words, in the direction the player has to look.
	# A colour on a tile says something is wrong; this says what to do.
	var verdict: String
	var verdict_col: Color
	match st:
		Simulation.Status.STARVED:
			verdict = "Starved — it is not being fed. Look at what is UPSTREAM of it."
			verdict_col = Palette.BAD
		Simulation.Status.BLOCKED:
			verdict = "Backed up — nothing is taking its output. Look DOWNSTREAM."
			verdict_col = Palette.WARN
		Simulation.Status.IDLE:
			verdict = "Idle. Nothing for it to do."
			verdict_col = Palette.TEXT_FAINT
		Simulation.Status.PASSIVE:
			verdict = "Working by standing there. It has no cycle of its own."
			verdict_col = Palette.GOOD
		_:
			if eff < Simulation.THERMAL_WARNING:
				verdict = "Running, but %s. It is giving up %d%% of its output." % [
					"too hot" if delta > 0.0 else "too cold",
					int(round((1.0 - eff) * 100.0))]
				verdict_col = Palette.ST_HOT if delta > 0.0 else Palette.ST_COLD
			else:
				verdict = "Running well."
				verdict_col = Palette.GOOD
	var v := _label(verdict, 18, verdict_col)
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet_body.add_child(v)

	_sheet_body.add_child(_stat_row("Temperature",
		"%.1f  (wants %.1f, %+.1f off)" % [heat, float(m["heat_optimum"]), delta]))
	_sheet_body.add_child(_stat_row("Thermal output",
		"%d%% of full speed" % int(round(eff * 100.0))))
	# Duty cycle, not items per second. It is comparable between machine
	# types, it needs no unit, and it answers what the player is asking:
	# is this tile earning its square.
	_sheet_body.add_child(_stat_row("Working",
		"%d%% of the time" % int(round(Sim.sim.uptime_of(cell) * 100.0))))
	if amp > 1.001:
		_sheet_body.add_child(_stat_row("Neighbour boost",
			"+%.0f%%" % ((amp - 1.0) * 100.0)))
	# Labelled as a capability, not as output. A machine that is backed up can
	# be quick and still be doing nothing, and printing one number next to the
	# other without saying which is which is how a readout becomes a riddle.
	_sheet_body.add_child(_stat_row("Cycle speed when fed",
		"%.2f per second" % Sim.sim.effective_rate(cell)))

	# The recipe, rendered from the table rather than written down, so the
	# sheet cannot describe a machine the simulation does not have.
	var recipe: String = MachineDB.recipe_text(id)
	if recipe != "":
		_sheet_body.add_child(_stat_row("Recipe", recipe))

	var d := _label(String(m["desc"]), 16, Palette.TEXT_FAINT)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet_body.add_child(d)

	_sheet.visible = true


func _stat_row(name: String, value: String) -> Control:
	var row := HBoxContainer.new()
	var a := _label(name, 17, Palette.TEXT_DIM)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	row.add_child(_label(value, 17, Palette.TEXT))
	return row


func _show_research() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 560)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	for id in Economy.TREE_ORDER:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		var lvl: int = Sim.upgrade_level(id)
		var maxed: bool = lvl >= int(u["max"])
		var c: Dictionary = Economy.upgrade_cost(id, lvl)

		var row := _panel(Palette.PANEL_HI)
		var rc := VBoxContainer.new()
		row.add_child(rc)
		rc.add_child(_label("%s   %d/%d" % [u["name"], lvl, int(u["max"])], 21, Palette.TEXT))
		rc.add_child(_label(String(u["desc"]), 17, Palette.TEXT_DIM))

		if maxed:
			rc.add_child(_label("Fully researched", 17, Palette.GOOD))
		else:
			var cost_text: String = "%s research" % Economy.fmt(float(c["research"]))
			if int(c["cores"]) > 0:
				cost_text += "  +  %d cores" % int(c["cores"])
			var b := _button(cost_text, Palette.RESEARCH)
			b.disabled = not Sim.can_buy_upgrade(id)
			b.pressed.connect(func():
				if Sim.buy_upgrade(id):
					Juice.upgrade()
					_close_overlay()
					_show_research()
					_refresh())
			rc.add_child(b)
		col.add_child(row)

	_open_overlay("Research", scroll, [])


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
	body.add_child(_label("+%s credits" % Economy.fmt(amount), 34, Palette.ACCENT))
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
	col.add_child(_label(
		"No account, no advertising ID, no personal data. %d event types only: sessions, depth reached, tutorial and first-production milestones, ads watched and purchases."
		% Analytics.ALLOWED.size(),
		15, Palette.TEXT_FAINT))

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
