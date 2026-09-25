extends Control

## The Codex: pictures first, then one short line, and the words behind a
## "?".
##
## A row of keys along the top, one per machine group (`MachineDB.GROUPS`,
## the same pictures the tray uses) and one for how the factory works:
##
##   a group       its machines, big and running, each with what goes in and
##                 what comes out and whether it likes heat or cold. One the
##                 player has not reached is a dark shape with a lock and the
##                 stratum it opens at, so the Codex also shows what is coming.
##   How it works  one rule per page, each on a small board that is really
##                 running: a `Simulation` with a real `Grid`, so a page
##                 cannot describe a rule the game does not have.
##
## Rule pages unlock as the player meets what they are about, so a first
## launch is not a manual. Adding a machine adds its card here by itself:
## its group is read off what it does.

const PAGES := [
	{
		"id": "adjacency",
		"title": "Side by side",
		"short": "Machines hand things to the machines they touch.",
		"unlock": 0,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "vault"]],
		"watch": "Watch the ore cross each gap.",
		"body": "There are no belts. A machine hands what it makes to any orthogonal neighbour that wants it, and splits it evenly if several do. While you place one, the green tiles are where it would be fed and could hand its work on.",
	},
	{
		"id": "refining",
		"title": "Every step pays more",
		"short": "Crushed ore sells for more than raw ore.",
		"unlock": 0,
		"board": [[0, 0, "drill"], [1, 0, "vault"],
			[0, 1, "drill"], [1, 1, "crusher"], [2, 1, "vault"]],
		"watch": "Two identical Drills. The lower line earns more.",
		"body": "Selling raw ore works and is never the best you can do. Each refining step trades throughput for value, and the trade is always worth making if you can keep the machine fed.",
	},
	{
		"id": "support",
		"title": "Helpers let things through",
		"short": "Heaters, Coolers and Boosters let things pass through them.",
		"unlock": 1,
		"board": [[0, 0, "drill"], [1, 0, "amplifier"], [2, 0, "drill"],
			[0, 1, "crusher"], [1, 1, "crusher"], [2, 1, "crusher"],
			[0, 2, "vault"], [1, 2, "vault"], [2, 2, "vault"]],
		"watch": "Ore crosses the Amplifier as if it were not there.",
		"body": "A Boiler, Coolant Cell, Amplifier, Duplicator or Condenser makes nothing — but material passes straight through it, so it costs you a tile of production and never a connection. Put one inside a working line, not beside it.",
	},
	{
		"id": "serving",
		"title": "Helpers boost what they touch",
		"short": "The more machines a Booster touches, the more it helps.",
		"unlock": 2,
		"board": [[1, 0, "drill"],
			[0, 1, "drill"], [1, 1, "amplifier"], [2, 1, "drill"],
			[1, 2, "crusher"], [1, 3, "vault"]],
		"watch": "One Amplifier, four neighbours, all of them faster.",
		"body": "The boost grows with how many working machines a support tile touches: one neighbour is face value, four is two and a half times that. Vaults do not count — there is no rate to raise. Move it one tile and the number on the preview changes before you buy.",
	},
	{
		"id": "status",
		"title": "The lights show the problem",
		"short": "Green: working. Amber: nowhere to send it. Red: nothing coming in.",
		"unlock": 0,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"]],
		"watch": "Amber on the left, red on the right.",
		"body": "Green is working. Amber means its output is backed up — look downstream. Red means it is not being fed — look upstream. The two point in opposite directions, so you can follow the colour to the culprit.",
	},
	{
		"id": "heat_helps",
		"title": "Heat can help",
		"short": "A Smelter likes heat. Put a Boiler next to it.",
		"unlock": 1,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[2, 1, "boiler"], [3, 0, "vault"]],
		"watch": "The Smelter is hot, and fast.",
		"body": "A Smelter wants to be hot. A Boiler next to it gets it there. Every machine emits heat into its own tile and half of that into each neighbour.",
	},
	{
		"id": "heat_hurts",
		"title": "Heat can hurt",
		"short": "Too much heat slows a Press down.",
		"unlock": 2,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [2, 1, "boiler"], [4, 0, "vault"]],
		"watch": "The Press is choking on the Smelter's heat.",
		"body": "A Press wants to be cold and sits next to things that are not. That is the puzzle: the same Boiler that pays for one tile costs you the next one.",
	},
	{
		"id": "cooling",
		"title": "Cooling",
		"short": "A Coolant Cell cools the machines around it.",
		"unlock": 2,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [2, 1, "boiler"], [3, 1, "coolant"],
			[4, 0, "vault"]],
		"watch": "Same board, one Coolant Cell. The Press recovers.",
		"body": "A Coolant Cell produces nothing. It buys back the throughput the heat was taking, and it costs you a tile you would rather have filled. That trade is most of the late game.",
	},
	{
		"id": "chain",
		"title": "The long chain",
		"short": "Ore, gravel, ingot, plate, part: one step at a time.",
		"unlock": 3,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [4, 0, "assembler"], [5, 0, "vault"]],
		"watch": "One of everything, one tile each.",
		"body": "Each step takes one of the thing below it, so one supplier is enough. A full chain earns about what the same tiles of Drills and Crushers would — and it is the only thing that makes Components, which teach a Lab the most.",
	},
	{
		"id": "research",
		"title": "Research buys what lasts",
		"short": "Labs turn materials into research. What it buys outlasts a collapse.",
		"unlock": 4,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [4, 0, "assembler"], [5, 0, "lab"]],
		"watch": "The Lab earns no credits at all.",
		"body": "A Lab turns Ingots, Plates or Components into Research -- most from a Component -- and Research buys upgrades that outlast the shaft. A board with no Lab is a board with no future, and a board that is only Labs has no present.",
	},
	{
		"id": "amplify",
		"title": "Faster together",
		"short": "An Amplifier makes the machines it touches faster.",
		"unlock": 4,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "amplifier"],
			[3, 0, "crusher"], [4, 0, "vault"], [2, 1, "drill"]],
		"watch": "Both Crushers run faster than they should.",
		"body": "An Amplifier produces nothing and speeds up every producing neighbour. It is the clearest case of the rule the whole board runs on: what a tile is worth depends on what is beside it.",
	},
	{
		"id": "depth",
		"title": "Deeper is different",
		"short": "Deeper rock pays more and runs hotter.",
		"unlock": 5,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "vault"]],
		"ambient": 2.6,
		"watch": "The same three tiles, nine strata down.",
		"body": "Depth multiplies what every machine yields and raises the ambient heat of the whole board. Some strata stop heat spreading, some collapse a third of the grid, some double what Amplifiers do. The board that was right up there is rarely right down here. Hold Descend to see the next one first; arrows on the tray show what it does.",
	},
]


## The tab that shows how the factory works rather than a group of machines.
const RULES_TAB := -1

var _on_close: Callable
var _tab: int = 0
var _tabs: Array[Button] = []
var _scroll: ScrollContainer
var _content: VBoxContainer
var _popup: Control


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
	_build()


## How many pages this player has reached. Kept deliberately generous: the
## unlock is there to stop a first launch being a manual, not to hide things.
static func unlocked_count() -> int:
	var n: int = 0
	for p: Dictionary in PAGES:
		if int(p.get("unlock", 0)) <= Sim.max_depth:
			n += 1
	return n


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.05, 0.95)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	# One row: the title, a key per group and one for the rules, and close.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var title := _label(Loc.t("Codex"), 30, Palette.TEXT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var tab_scroll := ScrollContainer.new()
	tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_scroll.add_child(tab_row)
	for g in range(MachineDB.GROUPS.size()):
		var info: Dictionary = MachineDB.GROUPS[g]
		tab_row.add_child(_tab_key(String(info["icon"]), Loc.t(String(info["name"])), g))
	tab_row.add_child(_tab_key("codex", Loc.t("How it works"), RULES_TAB))
	head.add_child(tab_scroll)
	var close := _key("✕", Palette.PANEL_HI)
	close.custom_minimum_size = Vector2(96, 96)
	close.pressed.connect(func():
		if _on_close.is_valid():
			_on_close.call()
		queue_free())
	head.add_child(close)
	col.add_child(head)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	show_tab(0)


## A key along the top: the group's picture, and its name small beneath.
func _tab_key(icon: String, caption: String, tab: int) -> Button:
	var b := _key("", Palette.PANEL)
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(122, 96)
	b.set_meta("tab", tab)
	var sb: StyleBoxFlat = (b.get_theme_stylebox("pressed") as StyleBoxFlat).duplicate()
	sb.bg_color = Palette.PANEL_HI.lerp(Palette.ACCENT, 0.25)
	sb.border_color = Palette.ACCENT
	sb.set_border_width_all(3)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("hover_pressed", sb)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := _icon(icon, 50)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ic)
	var l := _label(caption, 16, Palette.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The name fits its key in any language and at any text size: a little
	# smaller when it would not (main._fit, the same rule).
	var fs: int = Palette.text_px(16)
	var font: Font = l.get_theme_font("font")
	while fs > 11 and font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 114.0:
		fs -= 1
	l.add_theme_font_size_override("font_size", fs)
	box.add_child(l)
	b.add_child(box)
	b.pressed.connect(func():
		Juice.tap()
		show_tab(tab))
	_tabs.append(b)
	return b


func show_tab(tab: int) -> void:
	_tab = tab
	for b: Button in _tabs:
		b.set_pressed_no_signal(int(b.get_meta("tab")) == tab)
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	if tab == RULES_TAB:
		_rules()
	else:
		_group(tab)
	_scroll.scroll_vertical = 0


## --- a group: its machines, big and working --------------------------------

func _group(g: int) -> void:
	var info: Dictionary = MachineDB.GROUPS[g]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.add_child(_icon(String(info["icon"]), 60))
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(_label(Loc.t(String(info["name"])), 28, Palette.TEXT))
	words.add_child(_label(Loc.t(String(info["short"])), 19, Palette.TEXT_DIM))
	head.add_child(words)
	_content.add_child(head)

	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 14)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	for id: String in MachineDB.by_group(MachineDB.ORDER):
		if MachineDB.group_of(id) == g:
			row.add_child(_machine_card(id))
	_content.add_child(row)


## One machine: the machine itself, big and running; its name and one line;
## what goes in and what comes out; whether it likes heat or cold; and the
## words behind a "?". One the player has not reached is a dark shape with
## the stratum it opens at, so the Codex also says what is coming.
func _machine_card(id: String) -> Control:
	var m: Dictionary = MachineDB.get_machine(id)
	var opens: int = int(m["unlock_depth"])
	var open: bool = opens <= Sim.max_depth

	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL_HI if open else Palette.PANEL
	box.set_corner_radius_all(int(Palette.RADIUS) + 4)
	box.border_color = Color(Palette.machine_light(id), 0.55) if open else Palette.LINE
	box.border_width_top = 3
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(330, 0)
	card.set_meta("machine_id", id)
	card.set_meta("open", open)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)

	var pic_box := Control.new()
	pic_box.custom_minimum_size = Vector2(302, 200)
	var pic := Chips.MachineSprite.new(id, 200.0, open)
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic_box.add_child(pic)
	if not open:
		pic.modulate = Color(0.12, 0.13, 0.17, 0.95)
		var lock := _icon("lock", 84)
		lock.set_anchors_preset(Control.PRESET_CENTER)
		lock.offset_left = -42
		lock.offset_top = -42
		lock.offset_right = 42
		lock.offset_bottom = 42
		pic_box.add_child(lock)
		# Where it opens: the Descend sign and the stratum.
		var when := HBoxContainer.new()
		when.add_theme_constant_override("separation", 4)
		when.position = Vector2(4, 4)
		when.add_child(_icon("descend", 44))
		when.add_child(_label(str(opens), 30, Palette.TEXT))
		pic_box.add_child(when)
	col.add_child(pic_box)
	# The words, in the picture's corner: the picture is the card.
	var help := _help(MachineDB.name_of(id), func() -> String:
		var t: String = MachineDB.recipe_text(id)
		var lines: Array[String] = []
		if t != "":
			lines.append(t)
		lines.append(MachineDB.desc_of(id))
		match MachineDB.heat_liking(id):
			1:
				lines.append(Loc.t("It runs best warm: around %.1f heat.") % float(m["heat_optimum"]))
			-1:
				lines.append(Loc.t("It runs best cool, and slows down past %.1f heat.") % float(m["heat_tolerance"]))
		if not open:
			lines.append(Loc.t("It opens at stratum %d.") % opens)
		return "\n\n".join(lines))
	help.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help.offset_left = -96
	help.offset_right = 0
	help.offset_top = 0
	help.offset_bottom = 96
	pic_box.add_child(help)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var name_lbl := _label(MachineDB.name_of(id), 26, Palette.TEXT if open else Palette.TEXT_DIM)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)
	var liking: int = MachineDB.heat_liking(id)
	if liking != 0:
		name_row.add_child(_icon("heat" if liking > 0 else "cold", 38))
	col.add_child(name_row)
	var short := _label(MachineDB.short_of(id), 19, Palette.TEXT_DIM)
	short.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	short.custom_minimum_size = Vector2(302, 0)
	col.add_child(short)

	# What goes in, the machine, and what comes out.
	var flow: Control = Chips.flow(id, 42.0)
	flow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(flow)
	return card


## --- the rules, each on a small board that is really running ---------------

func _rules() -> void:
	for page: Dictionary in PAGES:
		if int(page.get("unlock", 0)) > Sim.max_depth:
			continue
		_content.add_child(_page(page))
	var locked: int = PAGES.size() - unlocked_count()
	if locked > 0:
		# The pages still to come, as a lock and a count.
		var more := HBoxContainer.new()
		more.alignment = BoxContainer.ALIGNMENT_CENTER
		more.add_theme_constant_override("separation", 10)
		more.add_child(_icon("lock", 48))
		more.add_child(_label("+%d" % locked, 28, Palette.TEXT_DIM))
		more.add_child(_icon("descend", 48))
		_content.add_child(more)


func _page(page: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.set_corner_radius_all(int(Palette.RADIUS) + 4)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("page_id", String(page["id"]))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)

	# The board first and big: it is the page.
	var mini: Control = (load("res://scripts/ui/mini_board.gd") as GDScript).new()
	mini.call("setup", page["board"], float(page.get("ambient", 0.0)), 96.0)
	var board_scroll := ScrollContainer.new()
	board_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	board_scroll.add_child(mini)
	board_scroll.custom_minimum_size = Vector2(minf(mini.custom_minimum_size.x, 600.0),
		mini.custom_minimum_size.y + 4.0)
	row.add_child(board_scroll)

	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 8)
	words.add_child(_label(Loc.t(String(page["title"])), 26, Palette.TEXT))
	var short := _label(Loc.t(String(page.get("short", ""))), 20, Palette.TEXT)
	short.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(short)
	var watch := _label(Loc.t(String(page["watch"])), 17, Palette.ACCENT)
	watch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(watch)
	row.add_child(words)
	var body: String = Loc.t(String(page["body"]))
	var help := _help(Loc.t(String(page["title"])), func() -> String: return body)
	help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(help)
	return panel


## --- the words, one tap away --------------------------------------------------

func _help(title: String, text: Callable) -> Button:
	var b := _key("?", Palette.LINE)
	b.add_theme_color_override("font_color", Palette.ACCENT)
	b.add_theme_font_size_override("font_size", 32)
	b.custom_minimum_size = Vector2(96, 96)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBox = b.get_theme_stylebox(state)
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).set_corner_radius_all(48)
	b.pressed.connect(func():
		Juice.tap()
		_say(title, String(text.call())))
	return b


func _say(title: String, text: String) -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = Control.new()
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.size = size
	add_child(_popup)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
			_popup.queue_free())
	_popup.add_child(dim)
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL_HI
	box.set_corner_radius_all(int(Palette.RADIUS) + 4)
	for side: String in ["left", "right", "top", "bottom"]:
		box.set("content_margin_" + side, 18)
	card.add_theme_stylebox_override("panel", box)
	var w: float = minf(760.0, size.x - 64.0)
	card.custom_minimum_size = Vector2(w, 0)
	card.position = Vector2((size.x - w) * 0.5, size.y * 0.18)
	_popup.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	var head := HBoxContainer.new()
	var t := _label(title, 28, Palette.TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := _key("✕", Palette.PANEL)
	close.custom_minimum_size = Vector2(96, 96)
	close.pressed.connect(func(): _popup.queue_free())
	head.add_child(close)
	col.add_child(head)
	var l := _label(text, 20, Palette.TEXT_DIM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(l)


## --- building blocks -----------------------------------------------------------

func _key(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Palette.TEXT)
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if state != "pressed" else col.darkened(0.18)
		if state == "hover":
			sb.bg_color = col.lightened(0.08)
		sb.set_corner_radius_all(int(Palette.RADIUS) + 2)
		sb.border_width_top = 2
		sb.border_color = sb.bg_color.lerp(Color.WHITE, 0.25)
		b.add_theme_stylebox_override(state, sb)
	return b


func _icon(name: String, px: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = IsoArt.icon(name)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(px, px)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", Palette.text_px(size_px))
	l.add_theme_color_override("font_color", col)
	return l
