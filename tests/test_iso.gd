extends RefCounted

## The landscape world: camera, geometry, pipes, badges, and the art that
## draws them. Everything here is arithmetic or data, so it is tested without
## a window; `tools/layout_check.gd` covers the interface on real canvases.

var runner: Object


## --- the project is a landscape game ----------------------------------------

func test_the_project_is_landscape_at_1440_by_720() -> void:
	runner.eq(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)), 1440,
		"the design canvas is 1440 wide")
	runner.eq(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)), 720,
		"and 720 tall")
	var o: int = int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))
	runner.check(o == 0 or o == 4, "landscape, or sensor landscape (either way up)")
	runner.eq(String(ProjectSettings.get_setting("display/window/stretch/aspect", "")), "expand",
		"expand, so a wider or taller phone gets more world rather than bars")
	# One finger is read through the mouse events Godot emulates from touch.
	# Turning that off would silently make the board untappable on a phone.
	runner.check(bool(ProjectSettings.get_setting(
		"input_devices/pointing/emulate_mouse_from_touch", true)),
		"touch must still emulate the mouse, which is how one finger reaches the board")


## --- geometry -----------------------------------------------------------------

func test_every_cell_round_trips_through_the_projection() -> void:
	for cell in range(Grid.W * Grid.H):
		runner.eq(Iso.cell_at(Iso.cell_center(cell)), cell,
			"cell %d's centre maps back to itself" % cell)
	# And the edges of a cell belong to it, not to its neighbours.
	var c: Vector2 = Iso.cell_center(Grid.idx(3, 4))
	runner.eq(Iso.cell_at(c + Vector2(Iso.TW * 0.45, 0)), Grid.idx(3, 4), "right point")
	runner.eq(Iso.cell_at(c + Vector2(0, -Iso.TH * 0.45)), Grid.idx(3, 4), "top point")
	runner.eq(Iso.cell_at(Iso.anchor() + Vector2(0, -Iso.TH * 60)), -1,
		"off the board is no cell")


func test_the_projection_is_two_to_one() -> void:
	var p: PackedVector2Array = Iso.cell_points(0)
	var w: float = p[1].x - p[3].x
	var h: float = p[2].y - p[0].y
	runner.near(w / h, 2.0, 0.001, "a cell is twice as wide as it is tall")


func test_machines_are_drawn_back_to_front() -> void:
	var order: Array[int] = Iso.depth_order()
	runner.eq(order.size(), Grid.W * Grid.H, "every cell is drawn")
	var seen: Dictionary = {}
	for cell: int in order:
		seen[cell] = true
		var p: Vector2i = Grid.xy(cell)
		# Everything behind this cell -- up and to either side on screen --
		# must already have been drawn, or it would be painted over this one.
		for back: Vector2i in [Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y - 1),
				Vector2i(p.x - 1, p.y - 1)]:
			if Grid.in_bounds(back.x, back.y):
				runner.check(seen.has(Grid.idx(back.x, back.y)),
					"%s is drawn before %s" % [str(back), str(p)])


func test_the_board_sits_on_the_island_with_the_core_in_its_middle() -> void:
	var slab: PackedVector2Array = Iso.slab_corners()
	var slab_poly := PackedVector2Array(slab)
	for p in Iso.board_corners():
		runner.check(Geometry2D.is_point_in_polygon(p, slab_poly)
			or _on_edge(p, slab_poly), "the board corner %s is on the slab" % str(p))
	# The Core is drawn exactly on the block of board cells it takes.
	var cc: Array = IsoArt.placement()["core_cell"]
	var n: int = int(IsoArt.placement()["core_size"])
	var o: Vector2i = Iso.board_offset()
	runner.eq(Vector2i(int(cc[0]), int(cc[1])) - o, BuildArea.CORE.position,
		"the Core's picture stands on its block")
	runner.eq(n, BuildArea.CORE.size.x, "and is as wide")
	runner.eq(BuildArea.CORE.position + BuildArea.CORE.size / 2, Vector2i(Grid.W, Grid.H) / 2,
		"in the middle of the board")
	# However big the world is, the camera can go to every corner of it.
	var c := _cam(Vector2(1440, 720))
	var bounds := Rect2(slab[0], Vector2.ZERO)
	for p in slab:
		bounds = bounds.expand(p)
	c.near_bounds = bounds.grow(Iso.TW)
	for p in Iso.board_corners():
		runner.check(c.clamp_center(p, 1.0).distance_to(p) < 0.5,
			"the camera can look straight at the board corner %s" % str(p))


func _on_edge(p: Vector2, poly: PackedVector2Array) -> bool:
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < 0.01:
			return true
	return false


## --- camera ---------------------------------------------------------------------

func _cam(view: Vector2) -> IsoCamera:
	var c := IsoCamera.new()
	var size_a: Array = IsoArt.layout()["world"]["size"]
	c.bg_size = Vector2(float(size_a[0]), float(size_a[1]))
	c.anchor = Iso.anchor()
	c.center = c.anchor
	c.parallax = float(IsoArt.placement().get("parallax", 0.82))
	c.set_viewport(view)
	return c


func _covers(c: IsoCamera) -> bool:
	var v: Rect2 = c.visible_bg()
	return v.position.x >= -0.5 and v.position.y >= -0.5 \
		and v.end.x <= c.bg_size.x + 0.5 and v.end.y <= c.bg_size.y + 0.5


func test_the_camera_never_shows_the_void() -> void:
	# Every aspect a phone or tablet produces from the 1440x720 base, flung at
	# every edge at every zoom.
	for view: Vector2 in [Vector2(1440, 720), Vector2(1600, 720), Vector2(1440, 810),
			Vector2(1560, 720), Vector2(1440, 1080), Vector2(1440, 900), Vector2(1440, 2560)]:
		var c := _cam(view)
		for z: float in [0.01, c.min_zoom(), 0.6, 1.0, 1.6, 9.0]:
			c.zoom_by(z / c.zoom, view * 0.5)
			for push: Vector2 in [Vector2(9999, 0), Vector2(-9999, 0), Vector2(0, 9999),
					Vector2(0, -9999), Vector2(7000, -7000)]:
				c.drag(push)
				runner.check(_covers(c), "void visible at %s, zoom %.2f, after %s"
					% [str(view), c.zoom, str(push)])
			c.release(Vector2(50000, 30000))
			for i in range(120):
				c.step(1.0 / 60.0)
			runner.check(_covers(c), "void visible after a fling at %s" % str(view))


func test_zoom_is_bounded() -> void:
	var c := _cam(Vector2(1440, 720))
	c.zoom_by(100.0, Vector2(720, 360))
	runner.near(c.zoom, c.zoom_max, 0.0001, "no closer than zoom_max")
	c.zoom_by(0.0001, Vector2(720, 360))
	runner.near(c.zoom, c.min_zoom(), 0.0001, "no further than the floor")
	runner.near(c.min_zoom(), c.zoom_floor, 0.0001, "which is the floor")
	# Zoomed all the way out, the painting still covers the screen.
	runner.check(_covers(c), "the far layer stops shrinking before it would show the void")


func test_zoom_keeps_the_point_under_the_finger() -> void:
	var c := _cam(Vector2(1440, 720))
	c.zoom_by(1.0, Vector2.ZERO)
	var finger := Vector2(900, 400)
	var before: Vector2 = c.screen_to_world(finger)
	c.zoom_by(1.3, finger)
	runner.check(c.screen_to_world(finger).distance_to(before) < 0.5,
		"the world under the finger stays under the finger while zooming")
	# The wheel glides but ends in the same place.
	var c2 := _cam(Vector2(1440, 720))
	var w2: Vector2 = c2.screen_to_world(finger)
	c2.zoom_toward(1.3, finger)
	for i in range(240):
		c2.step(1.0 / 60.0)
	runner.check(c2.screen_to_world(finger).distance_to(w2) < 0.5,
		"a wheel zoom glides about the cursor")


func test_a_drag_moves_the_world_exactly_with_the_finger() -> void:
	var c := _cam(Vector2(1440, 720))
	c.zoom_by(1.2 / c.zoom, Vector2(720, 360))
	var w: Vector2 = c.screen_to_world(Vector2(700, 300))
	c.drag(Vector2(40, -25))
	runner.check(c.world_to_screen(w).distance_to(Vector2(740, 275)) < 0.01,
		"one finger pans 1:1 -- no easing while it is down")
	c.release(Vector2(800, 0))
	var moved_from: Vector2 = c.center
	for i in range(30):
		c.step(1.0 / 60.0)
	runner.check(c.center.distance_to(moved_from) > 1.0, "a fling coasts after release")
	for i in range(600):
		c.step(1.0 / 60.0)
	runner.check(not c.is_moving(), "and stops")


func test_framing_puts_the_first_yard_and_the_core_in_the_free_space() -> void:
	var keep: int = Sim.max_depth
	Sim.max_depth = 0
	var v := IsoView.new()
	v.cam = _cam(Vector2(1440, 720))
	var free := Rect2(Vector2(22, 14), Vector2(1310, 548))
	v.cam.fit(v.frame_rect(), free)
	for p in v.yard_corners():
		runner.check(free.grow(1.0).has_point(v.cam.world_to_screen(p)),
			"yard corner %s is on screen in the free area" % str(p))
	runner.check(free.has_point(v.cam.world_to_screen(v.core_center())),
		"and so is the Core")
	v.free()
	Sim.max_depth = keep


## --- the pipes do not lie ----------------------------------------------------------

func test_a_pipe_is_drawn_exactly_where_the_simulation_can_move_material() -> void:
	var g := Grid.new()
	var s := Simulation.new(g, 7)
	# A chain, a bridge through a support tile, and a machine that takes
	# nothing from its neighbour.
	for e: Array in [[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "amplifier"],
			[3, 0, "smelter"], [1, 1, "vault"], [0, 1, "boiler"], [4, 0, "lab"]]:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var links: Array = Iso.links(g)
	var pairs: Dictionary = {}
	for l: Dictionary in links:
		pairs["%d>%d:%d" % [int(l["from"]), int(l["to"]), int(l["res"])]] = l
	var checked: int = 0
	for cell: int in g.cells:
		var m: Dictionary = MachineDB.get_machine(g.machine_at(cell))
		for res: int in (m.get("outputs", {}) as Dictionary).keys():
			var takers: Array = s.debug_takers(cell, res)
			for n in g.bridged_machines(cell):
				checked += 1
				runner.eq(pairs.has("%d>%d:%d" % [cell, n, res]), takers.has(n),
					"%s -> %s: the pipe and the simulation disagree"
					% [g.machine_at(cell), g.machine_at(n)])
	runner.gt(float(checked), 3.0, "there were pairs to check")
	# The bridge is drawn through the support tile, not across it.
	var bridged: Dictionary = pairs.get("%d>%d:%d" % [Grid.idx(1, 0), Grid.idx(3, 0),
		MachineDB.Res.GRAVEL], {})
	runner.eq((bridged.get("path", []) as Array).size(), 3,
		"a crusher feeds the smelter beyond the amplifier through it")
	# Nothing flows into a Boiler, so no pipe ends at one.
	for l: Dictionary in links:
		runner.check(g.machine_at(int(l["to"])) != "boiler", "no pipe into a boiler")


## --- badges ----------------------------------------------------------------------------

func test_a_badge_waits_for_a_state_to_hold() -> void:
	var b := StatusBadges.new()
	var hot: int = StatusBadges.Show.HOT
	# Flickering on and off every few frames: never shown.
	for i in range(200):
		b.update({5: hot if (i / 5) % 2 == 0 else StatusBadges.Show.NONE}, 1.0 / 60.0)
		if i % 40 == 0:
			runner.eq(b.shown(5), StatusBadges.Show.NONE, "a strobing state never gets a badge")
	# Held for longer than SHOW_AFTER: shown.
	for i in range(int(StatusBadges.SHOW_AFTER * 60.0) + 2):
		b.update({5: hot}, 1.0 / 60.0)
	runner.eq(b.shown(5), hot, "a state that holds for 1.5 s gets its badge")
	# A brief dropout does not take it down.
	for i in range(10):
		b.update({5: StatusBadges.Show.NONE}, 1.0 / 60.0)
	runner.eq(b.shown(5), hot, "a sixth of a second of normal does not clear it")
	for i in range(60):
		b.update({5: StatusBadges.Show.NONE}, 1.0 / 60.0)
	runner.eq(b.shown(5), StatusBadges.Show.NONE, "a second of normal does")


func test_only_the_machine_where_a_jam_starts_is_badged() -> void:
	var B: int = StatusBadges.Show.BLOCKED
	var S: int = StatusBadges.Show.STARVED
	var links := [{"from": 1, "to": 2}, {"from": 2, "to": 3}, {"from": 3, "to": 4},
		{"from": 10, "to": 11}, {"from": 11, "to": 12}]
	var raw := {1: B, 2: B, 3: B, 4: S, 10: StatusBadges.Show.NONE, 11: S, 12: S}
	var out: Dictionary = StatusBadges.root_causes(raw, links)
	runner.eq(out[1], StatusBadges.Show.NONE, "the back of the queue is quiet")
	runner.eq(out[2], StatusBadges.Show.NONE, "so is the middle")
	runner.eq(out[3], B, "the last blocked machine keeps its badge")
	runner.eq(out[4], S, "and the starved one it is waiting on")
	runner.eq(out[11], S, "the first starved machine keeps its badge")
	runner.eq(out[12], StatusBadges.Show.NONE, "the one starving behind it does not")


## --- art ------------------------------------------------------------------------------

func test_layout_json_is_complete_and_every_picture_exists() -> void:
	var L: Dictionary = IsoArt.layout()
	for key: String in ["tile", "machines", "tiles", "island", "world", "foreman",
			"core", "props", "icons", "placement"]:
		runner.check(L.has(key), "layout.json has '%s'" % key)
	var files: Array[String] = []
	for key: String in ["tiles", "island", "world", "foreman", "core", "props", "icons"]:
		files.append(String((L.get(key, {}) as Dictionary).get("file", "")))
	var sheets: Dictionary = L.get("machines", {}).get("sheets", {})
	for theme: String in Themes.ORDER:
		runner.check(sheets.has(theme), "a machine sheet for the %s palette" % theme)
		runner.check(sheets.has(theme + "_up"), "and its top tier")
	for n: String in sheets:
		files.append(String(sheets[n]["file"]))
		var sh: Dictionary = sheets[n]
		var a: Vector2 = IsoArt.anchor(sh)
		var cell: Array = sh["cell"]
		runner.check(a.x > 0.0 and a.y > 0.0 and a.x < float(cell[0]) and a.y < float(cell[1]),
			"%s's anchor is inside its cell" % n)
	for f: String in files:
		runner.check(ResourceLoader.exists(f), "%s exists and is imported" % f)
	var order: Array = L["machines"]["order"]
	runner.eq(order.size(), MachineDB.ORDER.size(), "one sprite per machine")
	for id: String in MachineDB.ORDER:
		runner.check(order.has(id), "%s has a sprite" % id)
	var props: Array = L["props"]["order"]
	for p: Array in L["placement"]["props"]:
		runner.check(props.has(String(p[2])), "placed prop %s exists" % String(p[2]))


func test_a_missing_sheet_falls_back_instead_of_failing() -> void:
	runner.eq(IsoArt.sheet_name("no-such-palette", 0), Themes.DEFAULT,
		"an unknown palette draws the free one")
	runner.eq(IsoArt.sheet_name("no-such-palette", 3), Themes.DEFAULT + "_up",
		"at the top tier, the free palette's top tier")
	runner.eq(IsoArt.sheet_name("brass", 3), "brass_up", "a bought palette keeps its gold tier")
	runner.eq(IsoArt.machine_region({}, "drill"), Rect2(), "no sheet, no region -- not a crash")
	runner.eq(IsoArt.texture("res://assets/art/nothing.webp"), null, "a missing file is null")


func test_every_shipped_picture_has_a_recorded_source() -> void:
	var f := FileAccess.open("res://art_src/sources.json", FileAccess.READ)
	runner.check(f != null, "art_src/sources.json exists")
	if f == null:
		return
	var src: Dictionary = JSON.parse_string(f.get_as_text())
	var used: Dictionary = {}
	for k: String in src:
		var e: Dictionary = src[k]
		for field: String in ["file", "job", "url", "date", "model", "quality", "prompt"]:
			runner.check(String(e.get(field, "")) != "", "%s records its %s" % [k, field])
		for u in e.get("used_for", []):
			used["res://" + String(u)] = true
	var found: Array = []
	_scan("res://assets/art", found)
	runner.gt(float(found.size()), 10.0, "the art is there")
	for p: String in found:
		runner.check(used.has(p), "%s has no entry in art_src/sources.json" % p)


func _scan(dir: String, found: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var p: String = dir + "/" + name
		if d.current_is_dir():
			_scan(p, found)
		elif name.get_extension() in ["png", "jpg", "webp"]:
			found.append(p)
		name = d.get_next()
	d.list_dir_end()


## --- touch -----------------------------------------------------------------------------

func test_a_cell_reaches_48dp_at_the_closest_zoom_on_the_reference_phones() -> void:
	# Canvas units to dp on real screens: a landscape phone's short side is the
	# 720-unit axis. 1080 px at 420 dpi (most 1080p phones), 1440 px at
	# 560 dpi, 720 px at 320 dpi -- all about 0.5-0.57 dp per unit.
	var c := IsoCamera.new()
	for phone: Array in [[1080.0, 420.0], [1440.0, 560.0], [720.0, 320.0]]:
		var dp_per_unit: float = (float(phone[0]) / 720.0) / (float(phone[1]) / 160.0)
		var max_dp: float = Iso.TH * c.zoom_max * dp_per_unit
		runner.gte(max_dp, 48.0,
			"a cell is %.0f dp tall at the closest zoom on %dp@%ddpi" % [max_dp,
				int(phone[0]), int(phone[1])])


## --- a finger means the machine it is on ---------------------------------------------

func _pick_art() -> Array:
	var sheet: Dictionary = IsoArt.sheet(IsoArt.sheet_name(Themes.DEFAULT, 0))
	var img: Image = IsoArt.texture(String(sheet["file"])).get_image()
	return [sheet, img]


## World point of pixel `q` of the picture of the machine on `cell`: the
## placement IsoView._draw_sprite uses.
func _on_picture(cell: int, q: Vector2, sheet: Dictionary) -> Vector2:
	var s: float = Iso.TW * float(IsoArt.placement().get("footprint", 0.8)) \
		/ IsoArt.base_px(sheet)
	return Iso.cell_center(cell) + (q + Vector2(0.5, 0.5) - IsoArt.anchor(sheet)) * s


## Three points of `id`'s picture on `cell`: the opaque pixel nearest its
## middle, one a few pixels under the top of the picture, and a clear corner.
func _picture_points(cell: int, id: String, sheet: Dictionary, img: Image) -> Dictionary:
	var r: Rect2 = IsoArt.machine_region(sheet, id)
	var solid: Array[Vector2] = []
	var top: float = INF
	for y in range(0, int(r.size.y), 2):
		for x in range(0, int(r.size.x), 2):
			if img.get_pixel(int(r.position.x) + x, int(r.position.y) + y).a >= 0.5:
				solid.append(Vector2(x, y))
				top = minf(top, float(y))
	var mean := Vector2.ZERO
	for q in solid:
		mean += q
	mean /= float(solid.size())
	var centre: Vector2 = solid[0]
	var high: Array[Vector2] = []
	for q in solid:
		if q.distance_to(mean) < centre.distance_to(mean):
			centre = q
		if q.y == top + 6.0:
			high.append(q)
	return {"centre": _on_picture(cell, centre, sheet),
		"top": _on_picture(cell, high[high.size() / 2], sheet),
		"clear": _on_picture(cell, Vector2(1, 1), sheet),
		"clear_alpha": img.get_pixel(int(r.position.x) + 1, int(r.position.y) + 1).a}


func test_a_tap_takes_the_machine_the_player_sees() -> void:
	var art: Array = _pick_art()
	var sheet: Dictionary = art[0]
	var img: Image = art[1]
	var g := Grid.new()
	var c: int = Grid.idx(3, 4)
	g.place(c, "smelter")
	var pts: Dictionary = _picture_points(c, "smelter", sheet, img)
	# The middle of the picture.
	runner.eq(IsoArt.pick(pts["centre"], g, sheet, img, false), c, "the middle of the machine")
	# High on the picture -- over the tiles behind it. The tile rule took a
	# tile behind; the machine is what is drawn there.
	runner.check(Iso.cell_at(pts["top"]) != c, "the top of the picture is over another tile")
	runner.eq(IsoArt.pick(pts["top"], g, sheet, img, false), c, "the top of the machine")
	# A clear corner of the picture's rectangle is not the machine.
	runner.lt(float(pts["clear_alpha"]), 0.5, "that corner is transparent")
	runner.check(IsoArt.pick(pts["clear"], g, sheet, img, false) != c,
		"a transparent part of the rectangle is not the machine")
	# An empty tile with nothing drawn over it is that tile.
	var t: int = Grid.idx(0, 0)
	runner.eq(IsoArt.pick(Iso.cell_center(t), g, sheet, img, false), t, "an empty tile")
	# No picture to test (a sheet that failed to read): the old tile rule.
	runner.eq(IsoArt.pick(pts["top"], g, sheet, null, false), Iso.cell_at(pts["top"]),
		"without the atlas image, the tile under the finger")


func test_the_machine_in_front_wins_where_two_pictures_overlap() -> void:
	var art: Array = _pick_art()
	var sheet: Dictionary = art[0]
	var img: Image = art[1]
	var g := Grid.new()
	var back: int = Grid.idx(2, 3)
	var front: int = Grid.idx(3, 4)
	g.place(back, "press")
	g.place(front, "drill")
	var r: Rect2 = IsoArt.machine_region(sheet, "press")
	var both: int = 0
	for y in range(0, int(r.size.y), 3):
		for x in range(0, int(r.size.x), 3):
			if img.get_pixel(int(r.position.x) + x, int(r.position.y) + y).a < 0.5:
				continue
			var w: Vector2 = _on_picture(back, Vector2(x, y), sheet)
			var solo := Grid.new()
			solo.place(front, "drill")
			if IsoArt.machine_at(w, solo, sheet, img) == front:
				both += 1
				runner.eq(IsoArt.pick(w, g, sheet, img, false), front,
					"where both pictures are drawn, the one in front is picked")
	runner.gt(float(both), 20.0, "the two pictures do overlap")
	var pts: Dictionary = _picture_points(back, "press", sheet, img)
	runner.eq(IsoArt.pick(pts["top"], g, sheet, img, false), back,
		"the part of the machine behind that shows is still that machine")


func test_picking_is_the_same_at_every_zoom_and_camera_position() -> void:
	var art: Array = _pick_art()
	var sheet: Dictionary = art[0]
	var img: Image = art[1]
	var g := Grid.new()
	var c: int = Grid.idx(4, 6)
	g.place(c, "assembler")
	var pts: Dictionary = _picture_points(c, "assembler", sheet, img)
	for z: float in [0.42, 0.883, 1.0, 1.6]:
		for pan: Vector2 in [Vector2.ZERO, Vector2(300, -120), Vector2(-420, 200)]:
			var cam := _cam(Vector2(1440, 720))
			cam.zoom_by(z / cam.zoom, Vector2(720, 360))
			cam.drag(pan)
			for k: String in ["centre", "top"]:
				var screen: Vector2 = cam.world_to_screen(pts[k])
				runner.eq(IsoArt.pick(cam.screen_to_world(screen), g, sheet, img, false), c,
					"%s of the machine at zoom %.2f, camera moved %s" % [k, cam.zoom, str(pan)])


func test_placing_still_puts_the_machine_on_the_tile_under_the_finger() -> void:
	var art: Array = _pick_art()
	var sheet: Dictionary = art[0]
	var img: Image = art[1]
	var g := Grid.new()
	for e: Array in [[1, 2, "drill"], [2, 2, "crusher"], [3, 3, "smelter"], [3, 4, "press"],
			[4, 4, "vault"], [2, 6, "assembler"], [5, 7, "lab"]]:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	# Wherever the tile under the finger is empty, an armed machine goes on
	# it, exactly as before -- even where a picture in front overlaps it.
	var r: Rect2 = Iso.board_rect()
	var covered: int = 0
	var checked: int = 0
	for y in range(int(r.position.y), int(r.end.y), 9):
		for x in range(int(r.position.x), int(r.end.x), 9):
			var w := Vector2(x, y)
			var tile: int = Iso.cell_at(w)
			if tile < 0:
				continue
			if g.is_empty(tile):
				checked += 1
				runner.eq(IsoArt.pick(w, g, sheet, img, true), tile,
					"placing on the empty tile under the finger")
				if IsoArt.machine_at(w, g, sheet, img) >= 0:
					covered += 1
			else:
				# A tap on a tile with a machine on it selects, armed or not.
				runner.eq(IsoArt.pick(w, g, sheet, img, true),
					IsoArt.pick(w, g, sheet, img, false), "armed or not, a machine is selected")
	runner.gt(float(checked), 100.0, "empty tiles were tapped")
	runner.gt(float(covered), 0.0, "including where a picture overlaps the tile")


func test_a_tap_on_the_factory_core_reaches_the_core() -> void:
	Sim._ensure()
	var v := IsoView.new()
	v.cam = _cam(Vector2(1440, 720))
	v.call("_refresh_sheet")
	var cr: Rect2 = v.core_rect()
	runner.gt(cr.size.x, 0.0, "the Core has a picture")
	for z: float in [0.6, 1.0, 1.6]:
		v.cam.zoom_by(z / v.cam.zoom, Vector2(720, 360))
		var body: Vector2 = cr.position + cr.size * Vector2(0.5, 0.58)
		runner.eq(v.pick_at_screen(v.cam.world_to_screen(body)), IsoView.CORE,
			"the middle of the Core's body, at zoom %.2f" % v.cam.zoom)
	runner.check(v.pick_at_screen(v.cam.world_to_screen(cr.position + Vector2(2, 2)))
		!= IsoView.CORE, "a clear corner of its rectangle is not the Core")
	v.free()


func test_a_growing_yard_lights_exactly_the_new_ground() -> void:
	Sim._ensure()
	var keep: Array = [Sim.max_depth, Sim.collapses]
	Sim.collapses = 0
	Sim.max_depth = 1
	var v := IsoView.new()
	v.call("_open_wave", BuildArea.size_at(0, 0))
	var opened: Dictionary = v.get("_opened")
	var before: Vector2i = BuildArea.size_at(0, 0)
	var after: Vector2i = BuildArea.size_at(1, 0)
	runner.eq(opened.size(), after.x * after.y - before.x * before.y,
		"every tile the yard gained, and no other (the Core's block is inside both)")
	for cell: int in opened:
		runner.check(not BuildArea.is_open(cell, 0, 0) and BuildArea.is_open(cell, 1, 0),
			"cell %d is new ground" % cell)
	v.free()
	Sim.max_depth = int(keep[0])
	Sim.collapses = int(keep[1])


func test_a_descent_into_a_new_band_takes_longer_than_one_inside_it() -> void:
	# Going down a stratum should feel like going somewhere, and going into a
	# new band like arriving in a new world -- without ever making a player
	# wait on it.
	runner.near(IsoView.dive_seconds(1), 1.43, 0.05, "the first descents are quick")
	for d in [4, 10, 17]:
		runner.near(IsoView.dive_seconds(d), 2.6, 0.001,
			"stratum %d opens a new band and gets the long plunge" % d)
	runner.gt(IsoView.dive_seconds(16), IsoView.dive_seconds(2),
		"a deep descent takes longer than a shallow one")
	for d in range(1, 60):
		runner.lte(IsoView.dive_seconds(d), 2.6, "stratum %d: a plunge, not a wait" % d)


func test_the_problem_alarm_grows_with_the_count_and_never_flashes() -> void:
	# More trouble, a more insistent key -- but a swell, never a strobe.
	runner.eq(StatusBadges.alarm_level(0), 0, "no problems, no alarm")
	runner.near(StatusBadges.alarm_hz(1), 0.0, 0.0001, "one problem: a count, no movement")
	runner.near(StatusBadges.alarm_hz(2), 0.0, 0.0001, "two: still just a count")
	runner.gt(StatusBadges.alarm_hz(3), 0.0, "three start a slow swell")
	var last_hz: float = 0.0
	var last_swell: float = 0.0
	var last_level: int = 0
	for n in range(0, 200):
		var hz: float = StatusBadges.alarm_hz(n)
		var sw: float = StatusBadges.alarm_swell(n)
		var lv: int = StatusBadges.alarm_level(n)
		runner.gte(hz, last_hz, "%d problems swell no slower than %d" % [n, n - 1])
		runner.gte(sw, last_swell, "%d problems swell no smaller" % n)
		runner.gte(float(lv), float(last_level), "%d problems are no calmer" % n)
		runner.lte(hz, 1.25, "%d problems: under the 3-a-second flash limit, with room" % n)
		runner.lte(sw, 0.10, "%d problems: the key grows a tenth at most" % n)
		last_hz = hz
		last_swell = sw
		last_level = lv
	runner.eq(StatusBadges.alarm_level(12), 4, "a dozen is critical")


func _heat_key_on(layout: Array) -> Array:
	var g := Grid.new()
	for e: Array in layout:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var s := Simulation.new(g, 7)
	s.run_ticks(300)
	var b := StatusBadges.new()
	for i in range(int(StatusBadges.SHOW_AFTER * 60.0) + 4):
		var raw: Dictionary = {}
		for c: int in g.cells:
			raw[c] = StatusBadges.classify(s, c)
		b.update(raw, 1.0 / 60.0)
	return b.heat_state(s, g.cells)


func test_the_heat_key_tells_the_boards_heat_before_it_is_opened() -> void:
	# No gauge of its own: the key reads the same badges the board shows.
	var calm: Array = _heat_key_on([[0, 0, "drill"], [1, 0, "vault"]])
	runner.eq(int(calm[0]), 0, "a drill and a vault at the surface: the key is calm")
	# A Press, which wants to stay cool, between two Boilers.
	var hot: Array = _heat_key_on([[0, 1, "drill"], [1, 1, "crusher"], [2, 1, "smelter"],
		[3, 1, "press"], [4, 1, "vault"], [3, 0, "boiler"], [3, 2, "boiler"]])
	runner.gte(float(hot[0]), 2.0, "a machine badged for heat lights the key")
	runner.check(not bool(hot[1]), "and it is heat, so the key shows a flame")
	# A Smelter, which wants three heat, with a Coolant Cell against it.
	var cold: Array = _heat_key_on([[0, 0, "drill"], [1, 0, "crusher"], [2, 0, "smelter"],
		[3, 0, "vault"], [2, 1, "coolant"]])
	runner.gte(float(cold[0]), 2.0, "a Smelter kept cold lights the key")
	runner.check(bool(cold[1]), "and it is cold, so the key shows frost")
