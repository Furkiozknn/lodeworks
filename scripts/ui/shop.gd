extends Control

## The shop. Two products, shown the way the rest of the game shows anything.
##
## The rule this screen is built to obey: **the value is on screen before the
## price is.** Not a bullet list of adjectives with a button underneath -- a
## picture of the thing, drawn with the same code that draws the board.
##
##   * The Licence draws two bars, the hours you bank now against the hours you
##     would bank, filled to scale from `Sim.offline_hours()` -- which is this
##     player's real number, not a marketing one. Underneath, in plain credits,
##     what that difference is worth at this player's own measured rate.
##   * The palettes draw themselves: a strip of real machine tiles, through
##     `MachineArt.tile()`, in each theme's actual colours. Tapping one shows
##     it on the board behind. What you see is exactly the file you get.
##
## And the rules it is built to refuse. There is no countdown, no "was/now",
## no badge, no bundle that punishes buying in the wrong order, no currency,
## no confirm-dialog dark pattern, and no second ask after a decline. The
## screen is reached from a button in the header and from the settings sheet
## and from nowhere else -- `MonetizationDB.PLACEMENTS` lists where an offer
## may appear and `FORBIDDEN_PLACEMENTS` names the ones this game will not
## have, and `tests/test_store.gd` reads both.
##
## Every state the store can be in has a visible form here: unavailable,
## unconfirmed, pending payment, owned, and failed-with-a-reason. A shop that
## only draws the happy path is how a player who has already paid ends up
## looking at a buy button.

const PAD := 16


## A bar chart of offline hours: what this player banks now, and what they
## would bank. Drawn rather than described, because "+4 hours" means nothing
## until it is next to the four you already have.
class OfflineBars extends Control:
	var now_hours: float = 4.0
	var then_hours: float = 8.0
	var rate: float = 0.45
	var credits_per_sec: float = 0.0
	## Somebody who already owns it is looking at what they have, not at an
	## offer, so the rows are labelled the other way round.
	var owned: bool = false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 118)

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		if size.x <= 1.0:
			return
		var span: float = maxf(then_hours, 1.0)
		var rows := [
			{"label": "Without it" if owned else "Now", "h": now_hours,
				"col": Palette.TEXT_DIM, "fill": Palette.PANEL_HI},
			{"label": "You bank" if owned else "With the Licence",
				"h": then_hours, "col": Palette.CORE, "fill": Palette.CORE},
		]
		var bar_h: float = 26.0
		var y: float = 8.0
		for r: Dictionary in rows:
			var w: float = (size.x - 24.0) * (float(r["h"]) / span)
			draw_rect(Rect2(12.0, y, size.x - 24.0, bar_h),
				Palette.BG.lerp(Palette.LINE, 0.5), true)
			draw_rect(Rect2(12.0, y, maxf(w, 3.0), bar_h), r["fill"], true)
			var txt: String = "%s  %.0f h" % [String(r["label"]), float(r["h"])]
			draw_string(font, Vector2(20.0, y + bar_h - 8.0), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Palette.BG if float(r["h"]) / span > 0.45 else Palette.TEXT)
			y += bar_h + 10.0
		# The honest translation: hours banked are not hours played.
		var gained: float = maxf(then_hours - now_hours, 0.0) * 3600.0 * rate
		var line: String = "%.1f more hours of production, every time you come back" \
			% (maxf(then_hours - now_hours, 0.0) * rate)
		if owned:
			line = "%.1f hours of production more than the free cap, every time" \
				% (maxf(then_hours - now_hours, 0.0) * rate)
		if credits_per_sec > 0.0:
			line += "  (+%s credits at your rate)" % Economy.fmt(gained * credits_per_sec)
		draw_string(font, Vector2(12.0, y + 14.0), line,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 14, Palette.TEXT_FAINT)


## A strip of real machine tiles in one theme's colours. This is the product.
class ThemeStrip extends Control:
	const TILE := 46.0
	const SHOWN: Array[String] = ["drill", "smelter", "boiler", "vault", "lab"]

	var theme_id: String = Themes.DEFAULT
	var selected: bool = false
	var locked: bool = false
	var tapped: Callable

	func _init() -> void:
		custom_minimum_size = Vector2(0, TILE + 34.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed:
			if tapped.is_valid():
				tapped.call(theme_id)
		elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			if tapped.is_valid():
				tapped.call(theme_id)

	func _draw() -> void:
		if size.x <= 1.0:
			return
		var font: Font = ThemeDB.fallback_font
		# Selection is a frame and a filled dot, never colour alone.
		var frame: Color = Palette.ACCENT if selected else Palette.LINE
		draw_rect(Rect2(0, 0, size.x, size.y), Palette.BG.lerp(
			Themes.rock_deep(theme_id), 0.85), true)
		draw_rect(Rect2(0, 0, size.x, size.y), frame, false, 2.0 if selected else 1.0)

		# Drawn through the theme by swapping the active palette for the
		# duration of the strip and putting it straight back -- the tiles are
		# the game's own, so a swatch cannot flatter a theme the board will
		# not deliver.
		var prev: String = Palette.theme()
		Palette.set_theme(theme_id)
		var x: float = 8.0
		for id: String in SHOWN:
			MachineArt.tile(self, Rect2(x, 6.0, TILE, TILE), id, font, 0.0)
			x += TILE + 5.0
		Palette.set_theme(prev)
		if locked:
			# Dimmed as well as labelled. A single faint word is not enough to
			# carry "you do not have this" on a phone in daylight.
			draw_rect(Rect2(6.0, 4.0, x - 8.0, TILE + 4.0),
				Color(0.03, 0.04, 0.05, 0.55), true)

		var label: String = Themes.name_of(theme_id)
		if locked:
			label += "   locked"
		draw_string(font, Vector2(10.0, size.y - 10.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 15,
			Palette.TEXT if not locked else Palette.TEXT_FAINT)
		if selected:
			draw_rect(Rect2(size.x - 20.0, 12.0, 10.0, 10.0), Palette.ACCENT, true)


var _list: VBoxContainer
var _on_close: Callable


func _ready() -> void:
	# Anchors AND offsets, plus an explicit size: a Control added to an
	# already-laid-out Control parent never gets a resize notification, and
	# anchors alone leave it zero by zero -- present, functional, invisible.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if get_parent() is Control:
		size = (get_parent() as Control).size
	process_mode = Node.PROCESS_MODE_ALWAYS
	Store.purchase_completed.connect(_rebuild_deferred)
	Store.purchase_failed.connect(func(_k, _r): _rebuild_deferred())
	Store.purchase_pending.connect(_rebuild_deferred)
	Store.product_details_changed.connect(_rebuild_deferred)
	Store.availability_changed.connect(func(_a): _rebuild_deferred())
	_build()


func _rebuild_deferred(_a = null) -> void:
	call_deferred("_build")


func _build() -> void:
	for c: Node in get_children():
		c.queue_free()

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.05, 0.985)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, PAD)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var head := HBoxContainer.new()
	var title := _label("Supply Office", 27, Palette.TEXT)
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
		"Two things, bought once. Neither unlocks a machine, a stratum or an upgrade.",
		15, Palette.TEXT_FAINT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	for key: String in MonetizationDB.products_at("shop"):
		_list.add_child(_card(key))

	if Store.has_themes():
		_list.add_child(_theme_picker())

	var restore := Button.new()
	restore.text = "Restore purchases"
	restore.custom_minimum_size = Vector2(0, 46)
	restore.add_theme_font_size_override("font_size", 17)
	restore.add_theme_color_override("font_color", Palette.TEXT_DIM)
	restore.flat = true
	restore.pressed.connect(func():
		Juice.tap()
		Store.restore())
	_list.add_child(restore)
	_list.add_child(_label(
		"Already bought something? Restore brings it back on any device signed in to the same account.",
		14, Palette.TEXT_FAINT))


## One product. Picture, then facts, then price, then the button -- and the
## button is drawn in whatever state the store is actually in.
func _card(key: String) -> Control:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.set_corner_radius_all(int(Palette.RADIUS))
	box.set_content_margin_all(14)
	box.border_color = Palette.LINE
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	v.add_child(_label(MonetizationDB.title_of(key), 22, Palette.TEXT))
	v.add_child(_wrap(MonetizationDB.headline_of(key), 17, Palette.TEXT_DIM))

	# The picture. Specific to the product, and made of the game's own parts.
	var art: Control = _art_for(key)
	if art != null:
		v.add_child(art)

	for b: String in MonetizationDB.bullets_of(key):
		v.add_child(_wrap("•  " + b, 16, Palette.TEXT))

	var foot: String = MonetizationDB.footnote_of(key)
	if foot != "":
		v.add_child(_wrap(foot, 14, Palette.TEXT_FAINT))

	v.add_child(_state_row(key))
	return panel


func _art_for(key: String) -> Control:
	match key:
		MonetizationDB.LICENCE:
			var bars := OfflineBars.new()
			bars.now_hours = Sim.offline_hours()
			var add: Variant = MonetizationDB.grant_value(key,
				MonetizationDB.GRANT_OFFLINE_HOURS, 0.0)
			bars.then_hours = bars.now_hours + float(add)
			if Store.owns(key):
				# Already applied, so "now" already includes it. Show the
				# honest pair rather than pretending it is still to come --
				# and relabel, so it never reads as an offer to somebody who
				# has already taken it.
				bars.owned = true
				bars.then_hours = bars.now_hours
				bars.now_hours = maxf(bars.now_hours - float(add), 0.0)
			bars.rate = Economy.multipliers(Sim.upgrade_levels).get("offline_rate",
				Economy.OFFLINE_BASE_RATE)
			bars.credits_per_sec = Sim.credits_per_sec
			return bars
		MonetizationDB.THEMES:
			var strip := VBoxContainer.new()
			strip.add_theme_constant_override("separation", 6)
			for id: String in Themes.ORDER:
				var s := ThemeStrip.new()
				s.theme_id = id
				s.locked = not Store.theme_unlocked(id)
				s.selected = id == Store.active_theme()
				s.tapped = _pick_theme
				strip.add_child(s)
			return strip
	return null


## The one row that has to be right: what the store is doing, said plainly.
func _state_row(key: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)

	if Store.owns(key):
		v.add_child(_label("Owned. Thank you.", 18, Palette.GOOD))
		return v

	if Store.is_pending(key):
		# Play's delayed instruments -- a voucher, a bank transfer -- land
		# here. Nothing is granted and nothing is charged twice.
		v.add_child(_label("Waiting on your payment", 18, Palette.WARN))
		v.add_child(_wrap(
			"Google Play is still processing it. This unlocks by itself the moment it clears — there is nothing to do and nothing to pay again.",
			14, Palette.TEXT_FAINT))
		return v

	var price: String = Store.price_text(key)
	var buy := Button.new()
	buy.text = "Buy" if price == "" else price
	buy.custom_minimum_size = Vector2(0, 52)
	buy.add_theme_font_size_override("font_size", 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.CORE
	style.set_corner_radius_all(int(Palette.RADIUS))
	buy.add_theme_stylebox_override("normal", style)
	buy.add_theme_stylebox_override("hover", style)
	buy.add_theme_stylebox_override("pressed", style)
	buy.add_theme_color_override("font_color", Palette.BG)
	# A disabled button has to still look like a button, or it reads as loose
	# text and the player never learns there was something to press.
	var off := StyleBoxFlat.new()
	off.bg_color = Palette.PANEL_HI
	off.set_corner_radius_all(int(Palette.RADIUS))
	off.border_color = Palette.LINE
	off.set_border_width_all(1)
	buy.add_theme_stylebox_override("disabled", off)
	buy.add_theme_color_override("font_disabled_color", Palette.TEXT_FAINT)
	buy.disabled = not Store.can_purchase(key)
	buy.pressed.connect(func():
		Juice.tap()
		Store.purchase(key))
	v.add_child(buy)

	if not Store.can_purchase(key):
		v.add_child(_wrap(_reason(key), 14, Palette.TEXT_FAINT))
	elif price == "":
		v.add_child(_label("Checking the price with Google Play…", 14,
			Palette.TEXT_FAINT))

	if Store.last_player_message != "":
		v.add_child(_wrap(Store.last_player_message, 15, Palette.WARN))
	return v


## Why there is no working buy button. Said in words the player can act on --
## "unavailable" with no reason is how a store outage gets mistaken for a bug
## in the game, and how somebody who has already paid concludes they were
## robbed.
func _reason(key: String) -> String:
	if not Store.is_available():
		if OS.has_feature("editor") or not OS.has_feature("android"):
			return "Purchases only work in the Play Store build."
		return "Can't reach Google Play right now. The game works exactly the same without it."
	if not Store.product_confirmed(key):
		return "Google Play hasn't confirmed this product yet. Nothing is wrong with your game."
	return "Not available on this device."


func _pick_theme(id: String) -> void:
	if not Store.theme_unlocked(id):
		Juice.reject()
		return
	Juice.tap()
	Store.select_theme(id)
	call_deferred("_build")


func _theme_picker() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(_label("Tap a palette to wear it. The board changes underneath.",
		14, Palette.TEXT_FAINT))
	return v


func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	return l


func _wrap(text: String, size_px: int, col: Color) -> Label:
	var l := _label(text, size_px, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
