extends SceneTree

## How often a tap reaches the machine the player aimed at: the tile rule the
## board used to pick by, against IsoArt.pick. No window, no device:
##
##   godot --headless --path . --script res://tools/pick_rate.gd
##
## On the audit's hero board (tools/screenshot.gd, "hero"), it prints
##   * the share of every machine's visible picture that reaches that machine
##   * taps aimed at the middle of each machine's visible picture, scattered
##     like a finger: a normal spread of sigma mm on each axis, at the default
##     zoom of an 18:9 phone (2160x1080 at 400 dpi, zoom 0.883 -- the
##     layout check's numbers). The sigmas are assumptions, not measurements
##     of a finger; the comparison between the two rules is the point
##   * how much of the empty tiles' floor a picture now covers (an unarmed tap
##     there selects that machine instead of the tile)
##   * what the change costs: the atlas image it holds, and one pick

const HERO := [
	[1, 0, "drill"], [2, 0, "drill"], [3, 0, "drill"], [4, 0, "drill"], [5, 0, "drill"],
	[1, 1, "crusher"], [2, 1, "crusher"], [3, 1, "amplifier"], [4, 1, "crusher"],
	[5, 1, "crusher"],
	[0, 2, "vault"], [1, 2, "smelter"], [2, 2, "smelter"], [3, 2, "vault"],
	[4, 2, "smelter"], [5, 2, "smelter"], [6, 2, "vault"],
	[0, 3, "vault"], [1, 3, "press"], [2, 3, "press"], [3, 3, "coolant"],
	[4, 3, "press"], [5, 3, "press"], [6, 3, "vault"],
	[1, 4, "vault"], [2, 4, "assembler"], [3, 4, "assembler"], [4, 4, "assembler"],
	[5, 4, "vault"],
	[2, 5, "vault"], [3, 5, "lab"], [4, 5, "vault"],
	[1, 7, "drill"], [2, 7, "crusher"], [3, 7, "smelter"], [4, 7, "vault"],
]
const SIGMA_MM := [1.0, 1.5, 2.0]
const TAPS := 200
## World units per mm on the reference phone: 400/25.4 px per mm, 1.5 px per
## canvas unit, zoom 0.883.
const UNITS_PER_MM := (400.0 / 25.4) / 1.5 / 0.883


func _init() -> void:
	var sheet: Dictionary = IsoArt.sheet(IsoArt.sheet_name(Themes.DEFAULT, 0))
	var tex: Texture2D = IsoArt.texture(String(sheet["file"]))
	var img: Image = tex.get_image()
	img.clear_mipmaps()

	var g := Grid.new()
	for e: Array in HERO:
		g.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))
	var s: float = Iso.TW * float(IsoArt.placement().get("footprint", 0.8)) / IsoArt.base_px(sheet)
	var a: Vector2 = IsoArt.anchor(sheet)

	# Every machine's visible picture: its opaque pixels no nearer picture covers.
	var visible: Dictionary = {}
	var px_all: int = 0
	var px_tile: int = 0
	for cell: int in g.cells:
		var r: Rect2 = IsoArt.machine_region(sheet, g.machine_at(cell))
		var pts: Array[Vector2] = []
		for y in range(0, int(r.size.y), 4):
			for x in range(0, int(r.size.x), 4):
				if img.get_pixel(int(r.position.x) + x, int(r.position.y) + y).a < 0.5:
					continue
				var w: Vector2 = Iso.cell_center(cell) + (Vector2(x, y) + Vector2(0.5, 0.5) - a) * s
				if IsoArt.machine_at(w, g, sheet, img) == cell:
					pts.append(w)
					px_all += 1
					px_tile += 1 if Iso.cell_at(w) == cell else 0
		visible[cell] = pts
	print("visible picture pixels that reach their own machine:")
	print("  tile rule %.1f%%   picture rule 100%% (by definition), %d samples" % [
		100.0 * px_tile / px_all, px_all])

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	print("taps aimed at the middle of each machine's visible picture (%d per machine):" % TAPS)
	for sigma_mm: float in SIGMA_MM:
		var sd: float = sigma_mm * UNITS_PER_MM
		var hit_tile: int = 0
		var hit_pick: int = 0
		var n: int = 0
		for cell: int in visible:
			var pts: Array[Vector2] = visible[cell]
			var mean := Vector2.ZERO
			for p in pts:
				mean += p
			mean /= float(pts.size())
			var aim: Vector2 = pts[0]
			for p in pts:
				if p.distance_to(mean) < aim.distance_to(mean):
					aim = p
			for i in range(TAPS):
				var t: Vector2 = aim + Vector2(rng.randfn(0.0, sd), rng.randfn(0.0, sd))
				hit_tile += 1 if Iso.cell_at(t) == cell else 0
				hit_pick += 1 if IsoArt.pick(t, g, sheet, img, false) == cell else 0
				n += 1
		print("  sigma %.1f mm: tile rule %.1f%%, picture rule %.1f%%" % [sigma_mm,
			100.0 * hit_tile / n, 100.0 * hit_pick / n])

	var floor_all: int = 0
	var floor_covered: int = 0
	var br: Rect2 = Iso.board_rect()
	for y in range(int(br.position.y), int(br.end.y), 6):
		for x in range(int(br.position.x), int(br.end.x), 6):
			var tile: int = Iso.cell_at(Vector2(x, y))
			if tile >= 0 and g.is_empty(tile):
				floor_all += 1
				floor_covered += 1 if IsoArt.machine_at(Vector2(x, y), g, sheet, img) >= 0 else 0
	print("empty tiles' floor under a picture: %.1f%%" % (100.0 * floor_covered / floor_all))

	var t0: int = Time.get_ticks_usec()
	var k: int = 0
	for y in range(int(br.position.y), int(br.end.y), 11):
		for x in range(int(br.position.x), int(br.end.x), 11):
			IsoArt.pick(Vector2(x, y), g, sheet, img, false)
			k += 1
	# The atlas read itself is not timed here: without a GPU, get_image()
	# hands back a copy the importer kept, not a read from video memory.
	print("cost: the atlas image held after the first tap %.1f MB; one pick %.1f us (average of %d)"
		% [img.get_data_size() / 1048576.0, float(Time.get_ticks_usec() - t0) / k, k])
	quit()
