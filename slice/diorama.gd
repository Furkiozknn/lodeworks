extends Node3D

## The visual vertical slice: Lodeworks as a diorama.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 720x1440 \
##       --fixed-fps 30 slice/diorama.tscn -- --capture=/tmp/slice
##
## A small factory on a block of rock, cut out of the Workings (stratum 7) and
## lit from above. The board, the machines, the heat, the transfers and the
## sales are driven by the REAL `Grid` and `Simulation` -- not a mock-up -- so
## a machine that looks stuck is stuck and an ingot crossing a seam is a
## transfer the simulation made. None of the game's own code is changed.
##
## Rendered with the Compatibility renderer, the one the game ships on.

const DEPTH := 7
const TICK := 0.1

## A mid-game board at this depth, two chains and a row of ore sellers:
##
##   row 4   Drill > Crusher > Smelter > Press > Vault, a Boiler behind the
##           Smelter keeping it at temperature
##   row 7   the same chain again, its Boiler in front this time
##   row 1   Drills selling raw ore straight into Vaults
##
## At this depth a Drill out-produces a Crusher several times over and a
## Smelter out-produces a Press, so each chain has extra Vaults selling the
## surplus. The layout was chosen by running the real simulation until
## exactly one machine on the board is stalled by the game's own rule: the
## Drill at the front with nowhere to put its ore. The ghost Vault beside it
## is the placement that fixes it. Both Presses run hot -- that is the heat
## problem this stratum is about.
const LAYOUT := [
	[1, 4, "drill"], [2, 4, "crusher"], [3, 4, "smelter"], [4, 4, "press"],
	[5, 4, "vault"], [3, 3, "boiler"], [3, 5, "vault"], [1, 3, "vault"],
	[0, 7, "drill"], [1, 7, "crusher"], [2, 7, "smelter"], [3, 7, "press"],
	[4, 7, "vault"], [2, 8, "boiler"], [2, 6, "vault"], [0, 6, "vault"],
	[1, 1, "drill"], [2, 1, "vault"], [3, 1, "drill"], [5, 1, "drill"],
	[5, 2, "vault"],
	[5, 8, "drill"],
]
const GHOST := [4, 8, "vault"]
const HOT_BADGE := 0.8

var grid: Grid
var sim: Simulation
var _machines: Dictionary = {}     # cell -> SliceMachine
var _tiles: MultiMeshInstance3D
var _acc: float = 0.0
var _items: Array = []             # {res, from, to, t}
var _item_mm: Dictionary = {}      # res -> MultiMesh
var _coins: Array = []
var _coin_mm: MultiMesh
var _pops: Array = []              # floating "+12" over the Vault
var _pop_pool: Array = []
var _credits: float = 0.0
var _rate: float = 0.0
var _sold_accum: float = 0.0
var _pop_wait: float = 0.0
var _lbl_credits: Label
var _lbl_rate: Label
var _capture_dir: String = ""
var _still_only: bool = false
var _frame: int = 0
var _last_progress: Dictionary = {}  # cell -> progress at the last tick
var _moving: Dictionary = {}       # cell -> seconds left of "it moved"
var _ek := SliceKit.new()          # static scenery, baked
var _el := SliceKit.new()          # static scenery lamps, baked


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			_capture_dir = a.substr("--capture=".length())
		if a == "--still-only":
			_still_only = true
	# 2x MSAA on the 3D pass: thin girders and chamfers alias badly without it,
	# and on the tiled GPUs phones use, MSAA resolves on-chip.
	get_viewport().msaa_3d = Viewport.MSAA_2X
	_build_sim()
	_build_world()
	_build_board()
	_build_machines()
	_build_links()
	_build_ghost()
	_build_floor_fx()
	_build_items()
	_commit_scenery()
	_build_hud()
	_build_tray()
	# Settle the factory before anyone looks at it: buffers full, statuses
	# real, the stuck Drill actually stuck.
	for _i in range(240):
		sim.tick()
	_refresh_tiles()


# --- simulation -----------------------------------------------------------------

func _build_sim() -> void:
	grid = Grid.new()
	sim = Simulation.new(grid, 20260923)
	Strata.apply(sim, grid, Strata.describe(DEPTH),
		Economy.multipliers({"throughput_1": 2, "yield_1": 1, "value_1": 1}))
	for e: Array in LAYOUT:
		grid.place(Grid.idx(int(e[0]), int(e[1])), String(e[2]))


static func cell_pos(x: int, y: int) -> Vector3:
	return Vector3(float(x) - 3.0, 0.0, float(y) - 4.5)


# --- baked scenery helpers ----------------------------------------------------------

func _sbox(size: Vector3, pos: Vector3, paint: String, rot := Vector3.ZERO,
		bevel: float = 0.05) -> void:
	var p: Array = SliceMachine.P[paint] if SliceMachine.P.has(paint) else SCENE[paint]
	_ek.add(SliceGeo.bevel_box(size, bevel), SliceKit.xf(pos, rot),
		Color(String(p[0])), float(p[1]), float(p[2]))


func _smesh(mesh: Mesh, pos: Vector3, paint: String, rot := Vector3.ZERO,
		scl := Vector3.ONE) -> void:
	var p: Array = SliceMachine.P[paint] if SliceMachine.P.has(paint) else SCENE[paint]
	_ek.add(mesh, SliceKit.xf(pos, rot, scl), Color(String(p[0])), float(p[1]), float(p[2]))


func _sglow(mesh: Mesh, pos: Vector3, col: String, energy: float,
		rot := Vector3.ZERO, scl := Vector3.ONE) -> void:
	_el.add(mesh, SliceKit.xf(pos, rot, scl), Color(col), energy, 0.0)


const SCENE := {
	"wood": ["7a4f31", 0.0, 0.85],
	"wood2": ["5a3923", 0.0, 0.9],
	"slab": ["3d3438", 0.2, 0.8],
	"lip": ["565e6e", 0.7, 0.35],
	"s1": ["a0703f", 0.0, 0.92],
	"s2": ["71472e", 0.0, 0.94],
	"s3": ["b98f5e", 0.0, 0.9],
	"s4": ["573a2c", 0.0, 0.95],
	"s5": ["8a5f45", 0.0, 0.92],
	"hole": ["120b08", 0.0, 1.0],
	"rail": ["8a909c", 0.8, 0.3],
}


func _commit_scenery() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _ek.commit()
	mi.material_override = SliceMats.body()
	add_child(mi)
	var ml := MeshInstance3D.new()
	ml.mesh = _el.commit()
	ml.material_override = SliceMats.lamp()
	ml.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ml)


# --- the chamber ----------------------------------------------------------------------

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("0e0a12")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("6f73a0")
	e.ambient_light_energy = 0.62
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.0
	e.tonemap_white = 6.0
	e.glow_enabled = true
	e.glow_intensity = 0.85
	e.glow_strength = 1.0
	e.glow_bloom = 0.03
	e.glow_hdr_threshold = 1.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.fog_enabled = true
	e.fog_light_color = Color("2a1a2c")
	e.fog_light_energy = 1.0
	e.fog_density = 0.02
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.15
	e.adjustment_contrast = 1.08
	env.environment = e
	add_child(env)

	# The key: warm light down the shaft, from above and to the left.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -55, 0)
	sun.light_color = Color("ffd9a8")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 1.0
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.8
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 24.0
	add_child(sun)
	# A cool rim from behind: every machine gets a blue edge on its dark side.
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-22, 150, 0)
	rim.light_color = Color("86a8ff")
	rim.light_energy = 0.6
	add_child(rim)

	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 31.0
	var target := Vector3(0, -0.6, 0.9)
	var dist: float = 17.0
	var elev: float = deg_to_rad(52.0)
	cam.position = target + Vector3(0, sin(elev) * dist, cos(elev) * dist)
	add_child(cam)
	cam.look_at(target)

	_build_column()
	_build_walls()
	_build_crystals()
	_build_gallery()
	_build_pipes()
	_build_dust()


## The block of rock the factory stands on, cut away at the front so its
## strata show: the one image in the game that says DEPTH without a number.
func _build_column() -> void:
	var y: float = -0.55
	var bands := [[0.5, "s1"], [0.3, "s4"], [0.75, "s3"], [0.28, "s2"], [0.65, "s5"],
		[0.36, "s4"], [0.85, "s1"], [0.55, "s2"], [0.8, "s5"]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var faces: Array = []   # [y top, y bottom, front z]
	for i in range(bands.size()):
		var h: float = float(bands[i][0])
		var w: float = 8.0 + float(i) * 0.1 + rng.randf_range(-0.12, 0.12)
		var d: float = 11.0 + float(i) * 0.08 + rng.randf_range(-0.1, 0.1)
		var off := Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.05, 0.05))
		_sbox(Vector3(w, h, d), Vector3(0, y - h * 0.5, 0) + off, String(bands[i][1]),
			Vector3(0, rng.randf_range(-0.6, 0.6), 0), 0.1)
		faces.append([y, y - h, d * 0.5 + off.z, w * 0.5])
		y -= h
	# Seams of ore in the cut face: gold mostly, now and then a cold blue.
	for k in range(26):
		var f: Array = faces[rng.randi_range(1, faces.size() - 1)]
		var fy: float = rng.randf_range(float(f[1]) + 0.08, float(f[0]) - 0.08)
		var fx: float = rng.randf_range(-float(f[3]) + 0.3, float(f[3]) - 0.3)
		var s: float = rng.randf_range(0.1, 0.22)
		_sglow(SliceGeo.crystal(1.0, 0.14), Vector3(fx, fy, float(f[2]) - 0.02),
			"ffc34a" if k % 5 != 0 else "4fd8ff", 1.6,
			Vector3(rng.randf_range(70, 110), rng.randf() * 360.0, 0), Vector3(s, s, s))
	for k in range(18):
		var f: Array = faces[rng.randi_range(0, faces.size() - 1)]
		var s: float = rng.randf_range(0.16, 0.36)
		_smesh(SliceGeo.rock(600 + k, 1.0, 0.7), Vector3(rng.randf_range(-3.8, 3.8),
			float(f[1]) + 0.05, float(f[2]) - 0.05), "s3" if k % 2 == 0 else "s5",
			Vector3(0, rng.randf() * 360.0, 0), Vector3(s, s * 0.7, s))


## Rocks, as four shared meshes in four MultiMeshes: a whole chamber wall for a
## handful of draw calls.
func _scatter(points: Array, tint: String, seed_base: int, shadow: bool = true) -> void:
	var variants: int = 4
	var groups: Array = []
	for _v in range(variants):
		groups.append([])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_base
	for p: Array in points:
		groups[rng.randi() % variants].append([p, rng.randf() * TAU])
	for v in range(variants):
		if (groups[v] as Array).is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = SliceGeo.rock(seed_base + v * 7, 1.0, 0.8)
		mm.instance_count = (groups[v] as Array).size()
		for i in range((groups[v] as Array).size()):
			var entry: Array = groups[v][i]
			var p: Array = entry[0]
			var s: Vector3 = p[1]
			var b := Basis(Vector3.UP, float(entry[1])).scaled(s)
			mm.set_instance_transform(i, Transform3D(b, p[0]))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = SliceMats.rock(tint)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


func _build_walls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var back: Array = []
	for tier in range(4):
		for i in range(10):
			var x: float = -9.5 + float(i) * 2.1 + rng.randf_range(-0.5, 0.5)
			var z: float = -7.4 - float(tier) * 1.5 + rng.randf_range(-0.4, 0.4)
			var y: float = -1.8 + float(tier) * 2.0 + rng.randf_range(-0.3, 0.3)
			var s: float = rng.randf_range(1.5, 2.3) + float(tier) * 0.35
			back.append([Vector3(x, y, z), Vector3(s, s * rng.randf_range(0.9, 1.3), s)])
	_scatter(back, "cave_back", 101)
	# The chasm walls, far off to either side and falling away below.
	var sides: Array = []
	for i in range(9):
		for sx in [-1.0, 1.0]:
			var z: float = -6.0 + float(i) * 1.8 + rng.randf_range(-0.4, 0.4)
			var x: float = sx * rng.randf_range(6.6, 7.6)
			var s: float = rng.randf_range(1.2, 2.0)
			sides.append([Vector3(x, rng.randf_range(-2.8, -0.4), z),
				Vector3(s, s * rng.randf_range(1.0, 1.8), s)])
	_scatter(sides, "cave_dark", 211)
	# Rubble along the top of the column, where the board meets the rock.
	var rubble: Array = []
	for i in range(24):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var s: float = rng.randf_range(0.2, 0.45)
		rubble.append([Vector3(side * rng.randf_range(4.05, 4.35), -0.45,
			rng.randf_range(-5.2, 5.2)), Vector3(s, s * 0.8, s)])
	_scatter(rubble, "ochre", 307)


func _build_crystals() -> void:
	# Gold in the Workings, with a little cold blue for contrast.
	var clusters := [
		[Vector3(-4.8, -0.6, -6.4), "gold", 1.3],
		[Vector3(-2.8, 1.4, -8.2), "gold", 1.6],
		[Vector3(3.9, 0.4, -7.0), "cyan", 1.3],
		[Vector3(2.0, 3.2, -9.6), "gold", 1.9],
		[Vector3(-6.6, 2.4, -8.6), "cyan", 1.6],
		[Vector3(6.2, 2.8, -8.8), "gold", 1.5],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var by_colour := {"gold": [], "cyan": []}
	for c: Array in clusters:
		for k in range(5):
			var off := Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.3, 0.3))
			var tilt := Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU,
				rng.randf_range(-0.5, 0.5))
			var s: float = float(c[2]) * rng.randf_range(0.45, 1.0)
			(by_colour[String(c[1])] as Array).append(
				Transform3D(Basis.from_euler(tilt).scaled(Vector3(s, s, s)), c[0] + off))
	for col: String in by_colour:
		var list: Array = by_colour[col]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = SliceGeo.crystal(1.0, 0.16)
		mm.instance_count = list.size()
		for i in range(list.size()):
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = SliceMats.crystal(col)
		add_child(mmi)


## A mine gallery across the back of the board: pit props, a cap beam,
## lanterns, and a tunnel mouth with light coming out of it.
func _build_gallery() -> void:
	var z: float = -5.75
	for x in [-4.1, -1.35, 1.35, 4.1]:
		_sbox(Vector3(0.28, 3.3, 0.28), Vector3(x, 1.0, z), "wood", Vector3.ZERO, 0.04)
		_sbox(Vector3(0.36, 0.14, 0.36), Vector3(x, -0.6, z), "wood2", Vector3.ZERO, 0.03)
	_sbox(Vector3(8.8, 0.3, 0.34), Vector3(0, 2.65, z), "wood", Vector3.ZERO, 0.05)
	for x in [-4.1, 4.1]:
		_sbox(Vector3(0.14, 1.1, 0.14), Vector3(x + (0.45 if x < 0 else -0.45), 2.2, z),
			"wood2", Vector3(0, 0, 40 if x < 0 else -40), 0.02)
	for x in [-2.75, 0.0, 2.75]:
		_sbox(Vector3(0.025, 0.4, 0.025), Vector3(x, 2.3, z + 0.1), "steel", Vector3.ZERO, 0.008)
		_sbox(Vector3(0.24, 0.05, 0.24), Vector3(x, 2.08, z + 0.1), "gun", Vector3.ZERO, 0.015)
		_sbox(Vector3(0.24, 0.05, 0.24), Vector3(x, 1.76, z + 0.1), "gun", Vector3.ZERO, 0.015)
		_sglow(SliceGeo.bevel_box(Vector3(0.17, 0.26, 0.17), 0.03), Vector3(x, 1.92, z + 0.1),
			"ffd48a", 3.0)
	# Tunnel mouth in the back wall, warm light spilling out.
	_sbox(Vector3(2.2, 0.3, 0.4), Vector3(0, 1.3, -6.9), "wood", Vector3.ZERO, 0.05)
	for x in [-0.95, 0.95]:
		_sbox(Vector3(0.3, 1.9, 0.4), Vector3(x, 0.3, -6.9), "wood", Vector3.ZERO, 0.05)
	_sbox(Vector3(1.6, 1.7, 0.1), Vector3(0, 0.3, -7.05), "hole", Vector3.ZERO, 0.02)
	_sglow(SliceGeo.bevel_box(Vector3(0.14, 0.2, 0.14), 0.03), Vector3(0.45, 0.7, -6.95), "ffd48a", 3.0)
	# A mine-cart track out of it along the back ledge.
	for s in [-1.0, 1.0]:
		_sbox(Vector3(8.2, 0.05, 0.06), Vector3(0, -0.08, -5.2 + s * 0.22), "rail", Vector3.ZERO, 0.01)
	for i in range(18):
		_sbox(Vector3(0.14, 0.05, 0.64), Vector3(-3.9 + float(i) * 0.46, -0.12, -5.2), "wood2",
			Vector3.ZERO, 0.01)
	var cart := Vector3(-2.6, 0.12, -5.2)
	_sbox(Vector3(0.9, 0.42, 0.62), cart + Vector3(0, 0.12, 0), "rust", Vector3.ZERO, 0.05)
	_sbox(Vector3(0.94, 0.05, 0.66), cart + Vector3(0, 0.33, 0), "gun", Vector3.ZERO, 0.015)
	for sx in [-0.28, 0.28]:
		for sz in [-0.3, 0.3]:
			_smesh(SliceGeo.cylinder(0.1, 0.1, 0.05, 10), cart + Vector3(sx, -0.1, sz), "gun",
				Vector3(90, 0, 0))
	for k in range(6):
		_sglow(SliceGeo.crystal(1.0, 0.14), cart + Vector3(-0.3 + float(k) * 0.12, 0.36,
			-0.1 + float(k % 2) * 0.18), "ffc34a", 2.2, Vector3(20, float(k) * 50.0, 0),
			Vector3(0.18, 0.18, 0.18))
	var l := OmniLight3D.new()
	l.position = Vector3(0, 1.7, -5.2)
	l.light_color = Color("ffc47a")
	l.light_energy = 2.4
	l.omni_range = 6.0
	add_child(l)


func _build_pipes() -> void:
	# A service main down the left of the column with energy running in it.
	var x: float = -4.45
	_smesh(SliceGeo.cylinder(0.17, 0.17, 11.2, 12), Vector3(x, -0.3, 0.0), "gun", Vector3(90, 0, 0))
	_sglow(SliceGeo.cylinder(0.06, 0.06, 11.2, 6), Vector3(x + 0.13, -0.22, 0.0), "4fd8ff", 2.6,
		Vector3(90, 0, 0))
	for i in range(8):
		_smesh(SliceGeo.cylinder(0.23, 0.23, 0.1, 12), Vector3(x, -0.3, -5.0 + float(i) * 1.45),
			"gold", Vector3(90, 0, 0))
		_sbox(Vector3(0.4, 0.08, 0.14), Vector3(x + 0.2, -0.5, -5.0 + float(i) * 1.45), "steel",
			Vector3.ZERO, 0.02)
	_smesh(SliceGeo.cylinder(0.15, 0.15, 4.2, 12), Vector3(x, 1.8, -5.5), "gun")


func _build_water() -> void:
	# A fall out of the back-right wall, dropping past the column into the dark.
	var fall := MeshInstance3D.new()
	var fm := QuadMesh.new()
	fm.size = Vector2(1.0, 9.0)
	fall.mesh = fm
	fall.material_override = SliceMats.water(true)
	fall.position = Vector3(5.4, -1.2, -5.2)
	fall.rotation_degrees = Vector3(0, -24, 0)
	add_child(fall)
	var mist := CPUParticles3D.new()
	mist.amount = 14
	mist.lifetime = 1.6
	mist.position = Vector3(5.4, 2.6, -5.1)
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(0.4, 3.0, 0.1)
	mist.direction = Vector3(0, 1, 0.4)
	mist.spread = 40.0
	mist.initial_velocity_min = 0.1
	mist.initial_velocity_max = 0.3
	mist.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	q.material = SliceMats.puff(Color(0.75, 0.9, 1.0, 0.18))
	mist.mesh = q
	add_child(mist)


func _build_dust() -> void:
	var p := CPUParticles3D.new()
	p.amount = 36
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(4.5, 1.5, 6.0)
	p.position = Vector3(0, 1.4, 0)
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.15
	p.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	q.material = SliceMats.glow("lamp", 3.0).duplicate()
	(q.material as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p.mesh = q
	add_child(p)


# --- the board ----------------------------------------------------------------------

func _build_board() -> void:
	# The deck the grid is laid on: a dark slab with a steel lip, standing on
	# the rock, bolted at the corners with amber marker lamps.
	_sbox(Vector3(7.7, 0.4, 10.7), Vector3(0, -0.35, 0), "slab", Vector3.ZERO, 0.08)
	for spec in [[Vector3(7.84, 0.12, 0.16), Vector3(0, -0.2, 5.37)],
			[Vector3(7.84, 0.12, 0.16), Vector3(0, -0.2, -5.37)],
			[Vector3(0.16, 0.12, 10.8), Vector3(3.87, -0.2, 0)],
			[Vector3(0.16, 0.12, 10.8), Vector3(-3.87, -0.2, 0)]]:
		_sbox(spec[0], spec[1], "lip", Vector3.ZERO, 0.03)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_sbox(Vector3(0.34, 0.7, 0.34), Vector3(sx * 3.93, -0.3, sz * 5.43), "gun",
				Vector3.ZERO, 0.05)
			_sbox(Vector3(0.38, 0.05, 0.38), Vector3(sx * 3.93, 0.04, sz * 5.43), "gold",
				Vector3.ZERO, 0.015)
			_sglow(SliceGeo.bevel_box(Vector3(0.2, 0.1, 0.2), 0.03),
				Vector3(sx * 3.93, 0.11, sz * 5.43), "ffb21f", 2.6)
	for i in range(8):
		_sbox(Vector3(0.1, 0.08, 0.04), Vector3(-3.5 + float(i), -0.2, 5.46),
			"yellow" if i % 2 == 0 else "dark", Vector3(0, 0, 30), 0.01)

	# Seventy tiles, one draw call: a MultiMesh of chamfered sandstone blocks
	# with heat, variation and highlight passed per instance.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = SliceGeo.bevel_box(Vector3(0.94, 0.3, 0.94), 0.07)
	mm.instance_count = Grid.W * Grid.H
	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	for y in range(Grid.H):
		for x in range(Grid.W):
			var i: int = Grid.idx(x, y)
			var h: float = rng.randf_range(-0.015, 0.015)
			mm.set_instance_transform(i, Transform3D(Basis(),
				cell_pos(x, y) + Vector3(0, -0.15 + h, 0)))
			mm.set_instance_custom_data(i, Color(0, rng.randf(), 0, 0))
	_tiles = MultiMeshInstance3D.new()
	_tiles.multimesh = mm
	_tiles.material_override = SliceMats.tiles()
	add_child(_tiles)


## Heat into the stone, every tick.
func _refresh_tiles() -> void:
	var mm: MultiMesh = _tiles.multimesh
	var amb: float = grid.ambient_heat
	for y in range(Grid.H):
		for x in range(Grid.W):
			var i: int = Grid.idx(x, y)
			var c: Color = mm.get_instance_custom_data(i)
			c.r = clampf((grid.heat_at(i) - amb) / 2.6, -1.0, 1.0)
			c.b = 1.0 if (x == int(GHOST[0]) and y == int(GHOST[1])) else 0.0
			mm.set_instance_custom_data(i, c)


func _build_machines() -> void:
	for e: Array in LAYOUT:
		var m := SliceMachine.new(String(e[2]))
		m.position = cell_pos(int(e[0]), int(e[1]))
		add_child(m)
		_machines[Grid.idx(int(e[0]), int(e[1]))] = m


## The game has no belts: a machine hands its output straight to the one
## beside it. So every seam where the simulation says that really happens gets
## a short steel chute bridging it, with a lit strip in its floor -- the
## adjacency rule, as hardware. The Boiler feeds nothing; what it gives its
## neighbour is heat, so it gets a lagged heat pipe instead.
func _build_links() -> void:
	for cell: int in grid.cells:
		var res: int = Palette.output_res(grid.machine_at(cell))
		if res < 0:
			continue
		for n: int in sim.debug_takers(cell, res):
			_chute(cell, n, false)
	for cell: int in grid.cells:
		if grid.machine_at(cell) != "boiler":
			continue
		for n: int in grid.neighbour_machines(cell):
			_heat_pipe(cell, n)


func _chute(from: int, to: int, ghost: bool) -> void:
	var a: Vector2i = Grid.xy(from)
	var b: Vector2i = Grid.xy(to)
	var pa: Vector3 = cell_pos(a.x, a.y)
	var pb: Vector3 = cell_pos(b.x, b.y)
	var mid: Vector3 = (pa + pb) * 0.5
	var along: float = 0.0 if a.y == b.y else 90.0
	var kit: SliceKit = _ek
	if ghost:
		kit = SliceKit.new()
	var y: float = 0.3
	var p: Array = SliceMachine.P["steel"]
	var g: Array = SliceMachine.P["gold"]
	kit.add(SliceGeo.bevel_box(Vector3(0.36, 0.05, 0.26), 0.015),
		SliceKit.xf(mid + Vector3(0, y, 0), Vector3(0, along, 0)), Color(String(p[0])), 0.8, 0.3)
	for s in [-1.0, 1.0]:
		var off := Vector3(0, 0, s * 0.13) if along == 0.0 else Vector3(s * 0.13, 0, 0)
		kit.add(SliceGeo.bevel_box(Vector3(0.38, 0.08, 0.035), 0.01),
			SliceKit.xf(mid + off + Vector3(0, y + 0.05, 0), Vector3(0, along, 0)),
			Color(String(g[0])), 0.9, 0.26)
	if ghost:
		var mi := MeshInstance3D.new()
		mi.mesh = kit.commit()
		mi.material_override = SliceMats.ghost()
		add_child(mi)
	else:
		_el.add(SliceGeo.bevel_box(Vector3(0.3, 0.012, 0.08), 0.004),
			SliceKit.xf(mid + Vector3(0, y + 0.03, 0), Vector3(0, along, 0)),
			Color("ffb21f"), 1.8, 0.0)


func _heat_pipe(from: int, to: int) -> void:
	var a: Vector2i = Grid.xy(from)
	var b: Vector2i = Grid.xy(to)
	var pa: Vector3 = cell_pos(a.x, a.y) + Vector3(0, 0.5, 0)
	var pb: Vector3 = cell_pos(b.x, b.y) + Vector3(0, 0.5, 0)
	var d: Vector3 = (pb - pa).normalized()
	var s0: Vector3 = pa + d * 0.3
	var s1: Vector3 = pb - d * 0.34
	var c: Array = SliceMachine.P["brass"]
	_ek.add(SliceGeo.cylinder(0.075, 0.075, s0.distance_to(s1), 12), SliceKit.beam_xf(s0, s1),
		Color(String(c[0])), 0.85, 0.3)
	for t in [0.15, 0.85]:
		_ek.add(SliceGeo.cylinder(0.105, 0.105, 0.05, 12), SliceKit.beam_xf(
			s0.lerp(s1, t) - d * 0.025, s0.lerp(s1, t) + d * 0.025), Color("f4ab35"), 0.9, 0.26)
	for t in [0.38, 0.5, 0.62]:
		_el.add(SliceGeo.cylinder(0.082, 0.082, 0.035, 12), SliceKit.beam_xf(
			s0.lerp(s1, t) - d * 0.018, s0.lerp(s1, t) + d * 0.018), Color("ff6a1f"), 2.6, 0.0)


## The placement preview: a ghost Vault on the tile that would unblock the
## stuck Drill, the chute it would bring into being, and a lit frame.
func _build_ghost() -> void:
	var g := SliceMachine.new(String(GHOST[2]))
	g.position = cell_pos(int(GHOST[0]), int(GHOST[1]))
	add_child(g)
	g.set_ghost()
	_machines[-1] = g
	_chute(Grid.idx(5, 8), Grid.idx(int(GHOST[0]), int(GHOST[1])), true)
	var p: Vector3 = cell_pos(int(GHOST[0]), int(GHOST[1]))
	for spec in [[Vector3(1.0, 0.04, 0.06), Vector3(0, 0.02, 0.5)],
			[Vector3(1.0, 0.04, 0.06), Vector3(0, 0.02, -0.5)],
			[Vector3(0.06, 0.04, 1.0), Vector3(0.5, 0.02, 0)],
			[Vector3(0.06, 0.04, 1.0), Vector3(-0.5, 0.02, 0)]]:
		_el.add(SliceGeo.bevel_box(spec[0], 0.01), SliceKit.xf(p + spec[1]),
			Color("4dff9a"), 2.4, 0.0)


## Soft contact shadow under every machine, and a pool of each machine's own
## light on the stone in front of it. Two MultiMeshes, two draw calls.
func _build_floor_fx() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var blobs := MultiMesh.new()
	blobs.transform_format = MultiMesh.TRANSFORM_3D
	blobs.mesh = quad
	blobs.instance_count = LAYOUT.size()
	for i in range(LAYOUT.size()):
		var e: Array = LAYOUT[i]
		blobs.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1.3, 1, 1.3)),
			cell_pos(int(e[0]), int(e[1])) + Vector3(0.06, 0.012, 0.06)))
	var bi := MultiMeshInstance3D.new()
	bi.multimesh = blobs
	bi.material_override = SliceMats.blob()
	bi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bi)

	# Where each machine's own light falls: in front of its mouth or firebox,
	# or straight down its bore.
	const POOL := {
		"smelter": [0.75, 1.5, Color(1.0, 0.42, 0.12)],
		"boiler": [0.62, 1.2, Color(1.0, 0.3, 0.08)],
		"press": [0.6, 0.9, Color(1.0, 0.45, 0.15)],
		"vault": [0.62, 1.0, Color(0.25, 1.0, 0.55)],
		"drill": [0.0, 0.8, Color(1.0, 0.6, 0.15)],
		"crusher": [0.6, 0.8, Color(1.0, 0.62, 0.15)],
	}
	var pools: Array = []
	for e: Array in LAYOUT:
		var spec: Array = POOL[String(e[2])]
		pools.append([Vector2i(int(e[0]), int(e[1])), Vector3(0, 0, float(spec[0])),
			float(spec[1]), spec[2]])
	pools.append([Vector2i(int(GHOST[0]), int(GHOST[1])), Vector3.ZERO, 1.2,
		Color(0.25, 1.0, 0.6)])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = pools.size()
	for i in range(pools.size()):
		var sp: Array = pools[i]
		var c: Vector2i = sp[0]
		var s: float = float(sp[2])
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, 1, s)),
			cell_pos(c.x, c.y) + sp[1] + Vector3(0, 0.02, 0)))
		var col: Color = sp[3]
		col.a = float(i) * 0.13
		mm.set_instance_custom_data(i, Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, col.a))
	var pi := MultiMeshInstance3D.new()
	pi.multimesh = mm
	pi.material_override = SliceMats.pool()
	pi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pi)


# --- things in motion ------------------------------------------------------------------

const ITEM_CAP := 24

func _item_mesh(res: int) -> ArrayMesh:
	var k := SliceKit.new()
	match res:
		0:
			k.add(SliceGeo.rock(501, 0.1), Transform3D(), Color("8a6446"), 0.0, 0.9)
			k.add(SliceGeo.crystal(1.0, 0.14), SliceKit.xf(Vector3(0.02, 0.02, 0),
				Vector3(20, 0, 10), Vector3(0.12, 0.12, 0.12)), Color("f4ab35"), 0.9, 0.2)
		1:
			for j in range(3):
				k.add(SliceGeo.rock(510 + j, 0.05, 0.6), SliceKit.xf(
					Vector3(-0.05 + float(j) * 0.05, 0, float(j % 2) * 0.04)), Color("b77a4a"), 0.0, 0.9)
		2:
			k.add(SliceGeo.bevel_box(Vector3(0.22, 0.07, 0.1), 0.02), Transform3D(),
				Color("ff8a2a"), 2.2, 0.0)
		3:
			k.add(SliceGeo.bevel_box(Vector3(0.22, 0.03, 0.22), 0.01), Transform3D(),
				Color("8fb6e8"), 0.9, 0.2)
		_:
			k.add(SliceGeo.bevel_box(Vector3(0.14, 0.14, 0.14), 0.03), Transform3D(),
				Color("f4ab35"), 0.9, 0.26)
	return k.commit()


func _build_items() -> void:
	for res in range(5):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _item_mesh(res)
		mm.instance_count = ITEM_CAP
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		# Ingots leave the Smelter hot: they are the one item that glows.
		mmi.material_override = SliceMats.lamp() if res == 2 else SliceMats.body()
		add_child(mmi)
		_item_mm[res] = mm
	var ck := SliceKit.new()
	ck.add(SliceGeo.cylinder(0.075, 0.075, 0.02, 12), SliceKit.xf(Vector3.ZERO, Vector3(90, 0, 0)),
		Color("ffcf4a"), 2.2, 0.0)
	_coin_mm = MultiMesh.new()
	_coin_mm.transform_format = MultiMesh.TRANSFORM_3D
	_coin_mm.mesh = ck.commit()
	_coin_mm.instance_count = 16
	_coin_mm.visible_instance_count = 0
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = _coin_mm
	cmi.material_override = SliceMats.lamp()
	cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cmi)
	for _i in range(4):
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 72
		l.outline_size = 18
		l.pixel_size = 0.0042
		l.modulate = Color("ffd23f")
		l.outline_modulate = Color(0.16, 0.07, 0.02, 1)
		l.visible = false
		l.render_priority = 20
		l.outline_render_priority = 19
		add_child(l)
		_pop_pool.append(l)


# --- the HUD ----------------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.86)
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(2)
	sb.border_color = Color(1.0, 0.72, 0.3, 0.55)
	sb.content_margin_left = 16
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(688, 0)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var coin := Panel.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color("f6b32e")
	cs.set_corner_radius_all(22)
	cs.set_border_width_all(4)
	cs.border_color = Color("ffe08a")
	coin.add_theme_stylebox_override("panel", cs)
	coin.custom_minimum_size = Vector2(44, 44)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	var money := VBoxContainer.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.add_theme_constant_override("separation", -4)
	_lbl_credits = Label.new()
	_lbl_credits.add_theme_font_size_override("font_size", 36)
	_lbl_credits.add_theme_color_override("font_color", Color("ffd66b"))
	_lbl_credits.add_theme_color_override("font_outline_color", Color(0.2, 0.08, 0.0))
	_lbl_credits.add_theme_constant_override("outline_size", 6)
	money.add_child(_lbl_credits)
	_lbl_rate = Label.new()
	_lbl_rate.add_theme_font_size_override("font_size", 18)
	_lbl_rate.add_theme_color_override("font_color", Color("8fe3a8"))
	money.add_child(_lbl_rate)
	row.add_child(money)
	var depth := VBoxContainer.new()
	depth.add_theme_constant_override("separation", -2)
	var d1 := Label.new()
	d1.text = "STRATUM %d" % DEPTH
	d1.add_theme_font_size_override("font_size", 15)
	d1.add_theme_color_override("font_color", Color("f4ab35"))
	d1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	depth.add_child(d1)
	var d2 := Label.new()
	d2.text = "The Workings"
	d2.add_theme_font_size_override("font_size", 24)
	d2.add_theme_color_override("font_color", Color("f2ece2"))
	depth.add_child(d2)
	row.add_child(depth)


## The build tray, so the placement preview has its context: six cards, each
## with a thumbnail rendered ONCE from the same 3D model that stands on the
## board -- icons and world from one source, no separate icon art to drift.
func _build_tray() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.9)
	sb.set_corner_radius_all(22)
	sb.set_border_width_all(2)
	sb.border_color = Color(1.0, 0.72, 0.3, 0.5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(16, 1440 - 16 - 200)
	panel.custom_minimum_size = Vector2(688, 200)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	for id: String in ["drill", "crusher", "smelter", "boiler", "press", "vault"]:
		var selected: bool = id == String(GHOST[2])
		var card := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color("1a2340") if not selected else Color("123a2e")
		cs.set_corner_radius_all(16)
		cs.set_border_width_all(2 if not selected else 4)
		cs.border_color = Color(1, 1, 1, 0.12) if not selected else Color("4dff9a")
		cs.content_margin_top = 4
		cs.content_margin_bottom = 6
		if selected:
			cs.shadow_color = Color(0.3, 1.0, 0.6, 0.45)
			cs.shadow_size = 10
		card.add_theme_stylebox_override("panel", cs)
		card.custom_minimum_size = Vector2(105, 0)
		row.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		card.add_child(col)
		var tex := TextureRect.new()
		tex.texture = _thumbnail(id)
		tex.custom_minimum_size = Vector2(100, 112)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(tex)
		var name_l := Label.new()
		name_l.text = String(MachineDB.get_machine(id)["name"])
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_size_override("font_size", 16)
		name_l.add_theme_color_override("font_color", Color("f2ece2"))
		col.add_child(name_l)
		var cost_l := Label.new()
		cost_l.text = Economy.fmt(MachineDB.cost_for(id, grid.count_of(id)))
		cost_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_l.add_theme_font_size_override("font_size", 16)
		cost_l.add_theme_color_override("font_color", Color("ffd66b"))
		col.add_child(cost_l)


func _thumbnail(id: String) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(200, 224)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("7a7fb0")
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 6.0
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_color = Color("ffe0b8")
	key.light_energy = 1.5
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_color = Color("86a8ff")
	rim.light_energy = 0.8
	vp.add_child(rim)
	var m := SliceMachine.new(id)
	vp.add_child(m)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var h: float = float(SliceMachine.TOP[id])
	var target := Vector3(0, h * 0.4, 0)
	cam.position = target + Vector3(1.55, 1.25, 2.3) * (0.95 + h * 0.28)
	vp.add_child(cam)
	cam.look_at(target)
	return vp.get_texture()


# --- the running factory -----------------------------------------------------------------

func _process(delta: float) -> void:
	_acc += delta
	while _acc >= TICK:
		_acc -= TICK
		var out: Dictionary = sim.tick()
		var c: float = float(out["credits"])
		_credits += c
		_rate = lerpf(_rate, c / TICK, 0.08)
		var sold_at: int = -1
		for t: Array in sim.last_transfers:
			if grid.machine_at(int(t[1])) == "vault":
				sold_at = int(t[1])
		if c > 0.0:
			_sale(c, sold_at)
		for cell: int in grid.cells:
			var pr: float = sim.progress_of(cell)
			if not is_equal_approx(pr, float(_last_progress.get(cell, -1.0))):
				_moving[cell] = 0.3
			_last_progress[cell] = pr
		for t: Array in sim.last_transfers:
			if _items.size() < ITEM_CAP * 3:
				_items.append({"res": int(t[2]), "from": int(t[0]), "to": int(t[1]), "t": 0.0})
		_refresh_tiles()
	_lbl_credits.text = Economy.fmt(_credits + 18420.0)
	_lbl_rate.text = "+%s / s" % Economy.fmt(_rate)

	for cell: int in _machines:
		var m: SliceMachine = _machines[cell]
		if cell < 0:
			m.drive(delta, false, 0, false, 0.0, false)
			continue
		var st: int = sim.status_of(cell)
		var stall: int = 0
		if st == Simulation.Status.BLOCKED:
			stall = 1
		elif st == Simulation.Status.STARVED:
			stall = 2
		# The game's own rule for "look here": stalled AND barely working.
		var stopped: bool = stall != 0 and sim.uptime_of(cell) < Simulation.SEVERE_UPTIME
		# Moves exactly when the simulation says it is making progress, so a
		# throttled machine works in bursts and a stuck one stands still.
		_moving[cell] = maxf(float(_moving.get(cell, 0.0)) - delta, 0.0)
		var working: bool = st == Simulation.Status.PASSIVE \
			or float(_moving[cell]) > 0.0
		# At this depth the ambient heat alone puts most machines just under the
		# game's 0.9 warning line. The floating badge is kept for the one that
		# is really losing output (more than a fifth); the rest show their
		# heat in the stone under them.
		var hot: bool = sim.heat_efficiency_at(cell) < HOT_BADGE \
			and sim.heat_delta_at(cell) > 0.0
		m.drive(delta, working, stall, stopped, sim.progress_of(cell), hot)
	_move_items(delta)
	_move_coins(delta)
	_move_pops(delta)

	if _capture_dir != "":
		_capture()


func _move_items(delta: float) -> void:
	var keep: Array = []
	var counts: Dictionary = {}
	for it: Dictionary in _items:
		it["t"] = float(it["t"]) + delta / 0.6
		var t: float = float(it["t"])
		if t >= 1.0:
			continue
		var res: int = clampi(int(it["res"]), 0, 4)
		var n: int = int(counts.get(res, 0))
		if n >= ITEM_CAP:
			continue
		counts[res] = n + 1
		var a: Vector2i = Grid.xy(int(it["from"]))
		var b: Vector2i = Grid.xy(int(it["to"]))
		var pa: Vector3 = cell_pos(a.x, a.y)
		var pb: Vector3 = cell_pos(b.x, b.y)
		# Out of the machine's side, across the chute, into the next one.
		var u: float = lerpf(0.22, 0.78, t)
		var pos: Vector3 = pa.lerp(pb, u) + Vector3(0, 0.4 + sin(t * PI) * 0.1, 0)
		(_item_mm[res] as MultiMesh).set_instance_transform(n,
			Transform3D(Basis(Vector3.UP, t * 1.5).scaled(Vector3.ONE * 1.5), pos))
		keep.append(it)
	for res in range(5):
		(_item_mm[res] as MultiMesh).visible_instance_count = int(counts.get(res, 0))
	_items = keep


# A sale: coins jump out of the Vault's slot and the amount floats up.
func _sale(amount: float, at: int) -> void:
	if at < 0:
		at = Grid.idx(5, 4)
	var xy: Vector2i = Grid.xy(at)
	var v: Vector3 = cell_pos(xy.x, xy.y) + Vector3(0, 0.86, 0)
	for _k in range(2):
		if _coins.size() >= 16:
			break
		var vel := Vector3(randf_range(-0.5, 0.5), randf_range(1.6, 2.2), randf_range(-0.2, 0.5))
		_coins.append({"pos": v, "vel": vel, "t": 0.0, "spin": randf() * TAU})
	_sold_accum += amount
	if _pop_pool.is_empty() or _pop_wait > 0.0:
		return
	_pop_wait = 1.0
	var l: Label3D = _pop_pool.pop_back()
	l.text = "+%s" % Economy.fmt(_sold_accum)
	_sold_accum = 0.0
	l.position = v + Vector3(randf_range(-0.15, 0.15), 0.45, 0)
	l.visible = true
	_pops.append({"node": l, "t": 0.0})


func _move_coins(delta: float) -> void:
	var keep: Array = []
	for c: Dictionary in _coins:
		c["t"] = float(c["t"]) + delta
		if float(c["t"]) > 0.9:
			continue
		var vel: Vector3 = c["vel"]
		vel.y -= 5.0 * delta
		c["vel"] = vel
		c["pos"] = (c["pos"] as Vector3) + vel * delta
		c["spin"] = float(c["spin"]) + delta * 9.0
		keep.append(c)
	_coins = keep
	for i in range(_coins.size()):
		var c: Dictionary = _coins[i]
		var s: float = maxf(1.0 - maxf(float(c["t"]) - 0.6, 0.0) / 0.3, 0.01)
		_coin_mm.set_instance_transform(i, Transform3D(
			Basis(Vector3.UP, float(c["spin"])).scaled(Vector3.ONE * s), c["pos"]))
	_coin_mm.visible_instance_count = _coins.size()


func _move_pops(delta: float) -> void:
	_pop_wait = maxf(_pop_wait - delta, 0.0)
	var keep: Array = []
	for p: Dictionary in _pops:
		p["t"] = float(p["t"]) + delta
		var l: Label3D = p["node"]
		var t: float = float(p["t"])
		if t > 0.95:
			l.visible = false
			_pop_pool.append(l)
			continue
		l.position.y += delta * 0.7
		var a: float = clampf(1.0 - maxf(t - 0.6, 0.0) / 0.35, 0.0, 1.0)
		l.modulate.a = a
		l.outline_modulate.a = a
		var pop: float = 1.0 + 0.35 * maxf(0.0, 1.0 - t * 6.0)
		l.scale = Vector3.ONE * pop
		keep.append(p)
	_pops = keep


# --- capture ---------------------------------------------------------------------------------

func _capture() -> void:
	_frame += 1
	if _frame == 60:
		DirAccess.make_dir_recursive_absolute(_capture_dir)
		_save("%s/still.png" % _capture_dir)
		var vp := get_viewport()
		var info := {
			"draw_calls": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,
				Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			"primitives": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,
				Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
			"objects": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,
				Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
			"shadow_draw_calls": vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,
				Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			"shadow_primitives": vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,
				Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
			"texture_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
			"buffer_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
			"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		}
		var f := FileAccess.open("%s/render_info.json" % _capture_dir, FileAccess.WRITE)
		f.store_string(JSON.stringify(info, "  "))
		f.close()
		print("render: ", JSON.stringify(info))
		for cell: int in grid.cells:
			print("  %-8s %s status=%d up=%.2f heat=%.2f eff=%.2f" % [grid.machine_at(cell),
				str(Grid.xy(cell)), sim.status_of(cell), sim.uptime_of(cell),
				grid.heat_at(cell), sim.heat_efficiency_at(cell)])
	if _still_only and _frame >= 60:
		get_tree().quit()
		return
	if _frame > 60 and _frame <= 150:
		_save("%s/f_%03d.png" % [_capture_dir, _frame - 60])
	if _frame > 150:
		get_tree().quit()


func _save(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
