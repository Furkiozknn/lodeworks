extends Control

## The Codex: optional, short, and mostly not words.
##
## Every page is a title, a **running** two-to-five tile board, one line of
## what to look at, and at most two sentences. The boards are real
## simulations, so a page cannot describe a rule the game does not have.
##
## Pages unlock as the player meets the thing they are about. That is not
## gating for its own sake: the alternative is a list of twenty entries on a
## first launch, which is a wall of text with a scrollbar, and nobody reads it.
##
## Adding a machine adds a page here the same way it adds a row anywhere else
## — `PAGES` is data, and the board on the page is the same `[x, y, id]` list
## the rest of the project uses.

const PAGES := [
	{
		"id": "adjacency",
		"title": "Machines feed what they touch",
		"unlock": 0,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "vault"]],
		"watch": "Watch the ore cross each gap.",
		"body": "There are no belts. A machine hands what it makes to any orthogonal neighbour that wants it, and splits it evenly if several do.",
	},
	{
		"id": "refining",
		"title": "Every step is worth more",
		"unlock": 0,
		"board": [[0, 0, "drill"], [1, 0, "vault"],
			[0, 1, "drill"], [1, 1, "crusher"], [2, 1, "vault"]],
		"watch": "Two identical Drills. The lower line earns more.",
		"body": "Selling raw ore works and is never the best you can do. Each refining step trades throughput for value, and the trade is always worth making if you can keep the machine fed.",
	},
	{
		"id": "status",
		"title": "The lights point at the problem",
		"unlock": 0,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"]],
		"watch": "Amber on the left, red on the right.",
		"body": "Green is working. Amber means its output is backed up — look downstream. Red means it is not being fed — look upstream. The two point in opposite directions, so you can follow the colour to the culprit.",
	},
	{
		"id": "heat_helps",
		"title": "Heat is a tool",
		"unlock": 1,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[2, 1, "boiler"], [3, 0, "vault"]],
		"watch": "The Smelter is hot, and fast.",
		"body": "A Smelter wants to be hot. A Boiler next to it gets it there. Every machine emits heat into its own tile and half of that into each neighbour.",
	},
	{
		"id": "heat_hurts",
		"title": "Heat is also a tax",
		"unlock": 2,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [2, 1, "boiler"], [4, 0, "vault"]],
		"watch": "The Press is choking on the Smelter's heat.",
		"body": "A Press wants to be cold and sits next to things that are not. That is the puzzle: the same Boiler that pays for one tile costs you the next one.",
	},
	{
		"id": "cooling",
		"title": "Cooling costs a tile",
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
		"unlock": 3,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [4, 0, "assembler"], [5, 0, "vault"]],
		"watch": "One of everything, one tile each.",
		"body": "Each step takes one of the thing below it, so one supplier is enough. A full chain earns about what the same tiles of Drills and Crushers would — and it is the only thing that makes Components, which are the only thing a Lab will take.",
	},
	{
		"id": "research",
		"title": "Research survives the collapse",
		"unlock": 4,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
			[3, 0, "press"], [4, 0, "assembler"], [5, 0, "lab"]],
		"watch": "The Lab earns no credits at all.",
		"body": "A Lab turns Components into Research, and Research buys upgrades that outlast the shaft. A board with no Lab is a board with no future, and a board that is only Labs has no present.",
	},
	{
		"id": "amplify",
		"title": "Some machines only matter next to others",
		"unlock": 4,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "amplifier"],
			[3, 0, "crusher"], [4, 0, "vault"], [2, 1, "drill"]],
		"watch": "Both Crushers run faster than they should.",
		"body": "An Amplifier produces nothing and speeds up every producing neighbour. It is the clearest case of the rule the whole board runs on: what a tile is worth depends on what is beside it.",
	},
	{
		"id": "depth",
		"title": "Deeper rock is not just richer",
		"unlock": 5,
		"board": [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "vault"]],
		"ambient": 2.6,
		"watch": "The same three tiles, nine strata down.",
		"body": "Depth multiplies what every machine yields and raises the ambient heat of the whole board. Some strata stop heat spreading, some collapse a third of the grid, some double what Amplifiers do. The board that was right up there is rarely right down here.",
	},
]

var _on_close: Callable
var _list: VBoxContainer


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
	dim.color = Color(0.03, 0.04, 0.05, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var head := HBoxContainer.new()
	var title := _label("Codex", 27, Palette.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.flat = true
	close.custom_minimum_size = Vector2(52, 52)
	close.add_theme_font_size_override("font_size", 22)
	close.pressed.connect(func():
		if _on_close.is_valid():
			_on_close.call()
		queue_free())
	head.add_child(close)
	col.add_child(head)

	col.add_child(_label(
		"Small boards that are actually running. Nothing here is a diagram.",
		15, Palette.TEXT_FAINT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var shown: int = 0
	for page: Dictionary in PAGES:
		if int(page.get("unlock", 0)) > Sim.max_depth:
			continue
		_list.add_child(_page(page))
		shown += 1
	var locked: int = PAGES.size() - shown
	if locked > 0:
		_list.add_child(_label(
			"%d more pages open as you go deeper." % locked, 15,
			Palette.TEXT_FAINT))


func _page(page: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", box)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	col.add_child(_label(String(page["title"]), 21, Palette.TEXT))

	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var mini: Control = (load("res://scripts/ui/mini_board.gd") as GDScript).new()
	scroll.add_child(mini)
	col.add_child(scroll)
	mini.call("setup", page["board"], float(page.get("ambient", 0.0)))
	# Exactly as tall as the board it holds. A fixed height leaves a page
	# that is mostly empty, which reads as something failing to load.
	scroll.custom_minimum_size = Vector2(0, mini.custom_minimum_size.y + 4.0)

	col.add_child(_label(String(page["watch"]), 16, Palette.ACCENT))
	var body := _label(String(page["body"]), 16, Palette.TEXT_DIM)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body)
	return panel


func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	return l
