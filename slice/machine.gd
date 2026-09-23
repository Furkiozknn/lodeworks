class_name SliceMachine
extends Node3D

## One machine, as a physical object standing on its tile.
##
## Every machine shares one construction DNA, taken from the reference sheet:
## a dark steel PLINTH with a gold trim band and four bolts, a gunmetal or
## painted BODY framed at the corners, a MECHANISM whose shape says what the
## machine does, and a LIGHT that is on when it works. They are told apart by
## silhouette first and colour second:
##
##   Drill     a tapered yellow derrick over a bore hole; the motor rides up
##             and down it and the auger spins down INTO the ground
##   Crusher   a framed block with a hopper; two toothed rollers turn in it
##   Smelter   a brick furnace with a molten mouth, a crucible, a stack
##   Boiler    a banded red pressure tank on a firebox, venting steam
##   Press     two blue pillars and a crown; a heavy ram comes down on a
##             glowing ingot and throws sparks
##   Vault     a teal-and-gold strongbox with a round door and a lit slot
##
## Static parts are baked (SliceKit) into one mesh per machine and one lamp
## mesh per machine; only the parts that actually move are separate nodes.
## Everything that moves is driven by state the simulation already has.

signal cycled()

## Colour, metalness, roughness. Paint is glossy, steel is dark and metallic,
## gold is warm and bright, brick and rubber are matte.
const P := {
	"gun": ["343b4a", 0.5, 0.42],
	"gun2": ["495469", 0.5, 0.4],
	"dark": ["1b1e25", 0.2, 0.75],
	"steel": ["707a8e", 0.8, 0.3],
	"chrome": ["d8dfea", 0.95, 0.12],
	"gold": ["f4ab35", 0.9, 0.26],
	"brass": ["c78d3d", 0.85, 0.3],
	"yellow": ["f7b829", 0.25, 0.4],
	"orange": ["ee7824", 0.25, 0.4],
	"red": ["c93a27", 0.3, 0.36],
	"brick": ["8f412b", 0.0, 0.85],
	"brick2": ["692d1f", 0.0, 0.9],
	"blue": ["3b74c6", 0.3, 0.38],
	"teal": ["18a086", 0.3, 0.38],
	"slate": ["5d7394", 0.3, 0.42],
	"cream": ["ebe0c8", 0.2, 0.42],
	"rust": ["bd5a28", 0.3, 0.5],
	"rubber": ["15171c", 0.0, 0.85],
	"ore": ["80593f", 0.0, 0.9],
}
## Light colours, sRGB. Energy is per part.
const G := {
	"molten": "ff6a1f", "fire": "ff4a14", "ember": "ff9a3a", "amber": "ffb21f",
	"lamp": "ffd48a", "cold": "c4e6ff", "green": "4dff9a", "gold": "ffcf4a",
	"cyan": "4fd8ff", "alarm": "ff3030",
}
## Where the status badge floats, per machine.
const TOP := {"drill": 1.95, "crusher": 1.35, "smelter": 1.75, "boiler": 1.8,
	"press": 1.95, "vault": 1.3}

var kind: String = ""
var _root: Node3D           # everything that thumps on a completed cycle
var _stack: Array = []      # [node, body kit, lamp kit] being built
var _lamp_mat: ShaderMaterial
var _spin: Array = []       # [node, axis, speed] turning while running
var _bob: Node3D
var _ram: Node3D
var _badge: MeshInstance3D
var _pile: Node3D
var _light: OmniLight3D
var _light_energy: float = 0.0
var _smoke: CPUParticles3D
var _dust: CPUParticles3D
var _sparks: CPUParticles3D
var _haze: CPUParticles3D
var _last_phase: float = 0.0
var _pulse: float = 0.0
var _t: float = 0.0
var _ghost: bool = false


func _init(machine_kind: String) -> void:
	kind = machine_kind
	_lamp_mat = SliceMats.lamp()
	_root = Node3D.new()
	add_child(_root)
	_open(_root)
	# The status pip on the plinth's front corner is part of the lamp mesh;
	# its colour comes from the lamp material, so it costs no draw call.
	(_stack.back()[2] as SliceKit).add(SliceGeo.sphere(0.045, 8),
		SliceKit.xf(Vector3(-0.39, 0.16, 0.39)), Color.WHITE, 1.0, 1.0)
	match kind:
		"drill": _build_drill()
		"crusher": _build_crusher()
		"smelter": _build_smelter()
		"boiler": _build_boiler()
		"press": _build_press()
		"vault": _build_vault()
	_close()
	_build_status()


# --- baking -------------------------------------------------------------------

func _open(node: Node3D) -> void:
	_stack.append([node, SliceKit.new(), SliceKit.new()])


func _close() -> void:
	var top: Array = _stack.pop_back()
	var node: Node3D = top[0]
	var k: SliceKit = top[1]
	var kl: SliceKit = top[2]
	if not k.is_empty():
		var mi := MeshInstance3D.new()
		mi.mesh = k.commit()
		mi.material_override = SliceMats.body()
		node.add_child(mi)
	if not kl.is_empty():
		var ml := MeshInstance3D.new()
		ml.mesh = kl.commit()
		ml.material_override = _lamp_mat
		ml.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(ml)


func _part(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _add(mesh: Mesh, pos: Vector3, paint: String, rot := Vector3.ZERO,
		scl := Vector3.ONE) -> void:
	var p: Array = P[paint]
	(_stack.back()[1] as SliceKit).add(mesh, SliceKit.xf(pos, rot, scl),
		Color(String(p[0])), float(p[1]), float(p[2]))


func _box(size: Vector3, pos: Vector3, paint: String, rot := Vector3.ZERO,
		bevel: float = 0.03) -> void:
	_add(SliceGeo.bevel_box(size, bevel), pos, paint, rot)


func _cyl(r_top: float, r_bot: float, h: float, pos: Vector3, paint: String,
		rot := Vector3.ZERO, sides: int = 12) -> void:
	_add(SliceGeo.cylinder(r_top, r_bot, h, sides), pos, paint, rot)


func _beam(a: Vector3, b: Vector3, w: float, paint: String) -> void:
	var p: Array = P[paint]
	(_stack.back()[1] as SliceKit).add(
		SliceGeo.bevel_box(Vector3(w, a.distance_to(b), w), minf(w * 0.25, 0.02)),
		SliceKit.beam_xf(a, b), Color(String(p[0])), float(p[1]), float(p[2]))


func _glow(mesh: Mesh, pos: Vector3, light: String, energy: float,
		rot := Vector3.ZERO, scl := Vector3.ONE) -> void:
	(_stack.back()[2] as SliceKit).add(mesh, SliceKit.xf(pos, rot, scl),
		Color(String(G[light])), energy, 0.0)


func _glow_box(size: Vector3, pos: Vector3, light: String, energy: float,
		rot := Vector3.ZERO) -> void:
	_glow(SliceGeo.bevel_box(size, minf(0.015, size[size.min_axis_index()] * 0.3)),
		pos, light, energy, rot)


# --- the shared DNA --------------------------------------------------------------

## Dark steel slab, gold trim band round the top edge, four chrome bolts.
func _plinth(h: float = 0.1, hole: bool = false) -> void:
	if hole:
		for s in [-1.0, 1.0]:
			_box(Vector3(0.92, h, 0.26), Vector3(0, h * 0.5, s * 0.33), "gun2")
			_box(Vector3(0.26, h, 0.4), Vector3(s * 0.33, h * 0.5, 0), "gun2")
	else:
		_box(Vector3(0.92, h, 0.92), Vector3(0, h * 0.5, 0), "gun2")
	for s in [-1.0, 1.0]:
		_box(Vector3(0.94, 0.035, 0.045), Vector3(0, h, s * 0.448), "gold", Vector3.ZERO, 0.01)
		_box(Vector3(0.045, 0.035, 0.94), Vector3(s * 0.448, h, 0), "gold", Vector3.ZERO, 0.01)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(0.035, 0.04, 0.035, Vector3(sx * 0.39, h + 0.02, sz * 0.39), "chrome",
				Vector3.ZERO, 8)


func _corners(half: float, y0: float, y1: float, paint: String = "gold",
		w: float = 0.08) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(Vector3(w, y1 - y0, w), Vector3(sx * half, (y0 + y1) * 0.5, sz * half),
				paint, Vector3.ZERO, 0.02)


func _light_at(col: Color, energy: float, range_m: float, pos: Vector3) -> void:
	_light = OmniLight3D.new()
	_light.light_color = col
	_light.light_energy = energy
	_light_energy = energy
	_light.omni_range = range_m
	_light.omni_attenuation = 1.6
	_light.position = pos
	add_child(_light)


func _particles(amount: int, lifetime: float, col: Color, size_m: float,
		pos: Vector3, vel: float, spread: float = 18.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.position = pos
	p.direction = Vector3.UP
	p.spread = spread
	p.gravity = Vector3(0, 0.15, 0)
	p.initial_velocity_min = vel * 0.7
	p.initial_velocity_max = vel
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.set_color(0, Color(col.r, col.g, col.b, 0.0))
	ramp.add_point(0.15, Color(col.r, col.g, col.b, col.a))
	ramp.set_color(ramp.get_point_count() - 1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = ramp
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0, 0.4))
	scale_curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = scale_curve
	var q := QuadMesh.new()
	q.size = Vector2(size_m, size_m)
	q.material = SliceMats.soft_puff()
	p.mesh = q
	add_child(p)
	return p


# --- the six machines ---------------------------------------------------------

func _build_drill() -> void:
	_plinth(0.1, true)
	# The bore: a dark hole with a faint glow of ore at the bottom.
	_cyl(0.2, 0.2, 0.012, Vector3(0, 0.006, 0), "rubber", Vector3.ZERO, 14)
	_glow(SliceGeo.torus(0.1, 0.17, 14), Vector3(0, 0.008, 0), "amber", 0.9,
		Vector3.ZERO, Vector3(1, 0.1, 1))
	# The derrick: four yellow girders leaning in to a crown.
	var lo: float = 0.37
	var hi: float = 0.12
	var top: float = 1.42
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_beam(Vector3(sx * lo, 0.1, sz * lo), Vector3(sx * hi, top, sz * hi), 0.085, "yellow")
	# Ring braces and cross bracing, in dark steel so the yellow reads as frame.
	var at := func(y: float) -> float: return lerpf(lo, hi, (y - 0.1) / (top - 0.1))
	for y: float in [0.46, 0.98]:
		var w: float = at.call(y)
		for s in [-1.0, 1.0]:
			_beam(Vector3(-w, y, s * w), Vector3(w, y, s * w), 0.05, "gun")
			_beam(Vector3(s * w, y, -w), Vector3(s * w, y, w), 0.05, "gun")
	for s in [-1.0, 1.0]:
		var w0: float = at.call(0.46)
		var w1: float = at.call(0.98)
		_beam(Vector3(s * w0, 0.46, -w0), Vector3(s * w1, 0.98, w1), 0.03, "gun")
		_beam(Vector3(-w0, 0.46, s * w0), Vector3(w1, 0.98, s * w1), 0.03, "gun")
	# The crown and the sheave the cable runs over.
	_box(Vector3(0.4, 0.12, 0.4), Vector3(0, top + 0.04, 0), "yellow")
	_box(Vector3(0.44, 0.04, 0.44), Vector3(0, top - 0.03, 0), "gold", Vector3.ZERO, 0.01)
	_glow_box(Vector3(0.18, 0.05, 0.03), Vector3(0, top + 0.04, 0.205), "lamp", 2.2)
	_box(Vector3(0.03, 0.5, 0.03), Vector3(0, top - 0.3, 0), "dark", Vector3.ZERO, 0.008)
	var sheave := _part(_root, Vector3(0, top + 0.2, 0))
	_open(sheave)
	_add(SliceGeo.torus(0.07, 0.12, 12), Vector3.ZERO, "steel", Vector3(0, 0, 90))
	_cyl(0.035, 0.035, 0.1, Vector3.ZERO, "gold", Vector3(0, 0, 90), 8)
	_close()
	_spin.append([sheave, Vector3.RIGHT, 5.0])
	for s in [-1.0, 1.0]:
		_box(Vector3(0.04, 0.16, 0.14), Vector3(s * 0.08, top + 0.16, 0), "gun")

	# The motor rides the mast; the auger turns under it and goes into the hole.
	_bob = _part(_root, Vector3.ZERO)
	_open(_bob)
	_box(Vector3(0.36, 0.3, 0.36), Vector3(0, 0.8, 0), "orange", Vector3.ZERO, 0.05)
	_box(Vector3(0.4, 0.06, 0.4), Vector3(0, 0.97, 0), "gun")
	_box(Vector3(0.4, 0.05, 0.4), Vector3(0, 0.64, 0), "gun")
	for s in [-1.0, 1.0]:
		_box(Vector3(0.02, 0.2, 0.2), Vector3(s * 0.185, 0.8, 0), "gun", Vector3.ZERO, 0.008)
	_glow_box(Vector3(0.2, 0.09, 0.03), Vector3(0, 0.82, 0.185), "amber", 2.4)
	var auger := _part(_bob, Vector3.ZERO)
	_open(auger)
	_cyl(0.045, 0.045, 0.78, Vector3(0, 0.23, 0), "chrome", Vector3.ZERO, 8)
	for i in range(8):
		var a: float = float(i) * 50.0
		var yy: float = -0.1 + float(i) * 0.075
		var d := Vector3(cos(deg_to_rad(a)), 0, -sin(deg_to_rad(a)))
		_box(Vector3(0.22, 0.028, 0.07), Vector3(0, yy, 0) + d * 0.06, "steel",
			Vector3(0, a, 14), 0.01)
	_cyl(0.02, 0.07, 0.1, Vector3(0, -0.16, 0), "chrome", Vector3(180, 0, 0), 8)
	_close()
	_close()
	_spin.append([auger, Vector3.UP, 9.0])
	_dust = _particles(10, 0.9, Color(0.66, 0.52, 0.4, 0.55), 0.16,
		Vector3(0, 0.06, 0), 0.5, 55.0)
	# What a blocked Drill looks like: its ore piles up on the deck.
	_pile = _part(_root, Vector3.ZERO)
	_open(_pile)
	for i in range(6):
		_add(SliceGeo.rock(70 + i, 0.075), Vector3(-0.26 + float(i % 3) * 0.13,
			0.16 + float(i / 3) * 0.06, 0.3 - float(i / 3) * 0.06), "ore")
	_close()
	_pile.visible = false


func _build_crusher() -> void:
	_plinth()
	_box(Vector3(0.8, 0.48, 0.8), Vector3(0, 0.34, 0), "gun", Vector3.ZERO, 0.05)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.56, 0.3, 0.02), Vector3(0, 0.34, s * 0.405), "slate", Vector3.ZERO, 0.008)
		_box(Vector3(0.02, 0.3, 0.56), Vector3(s * 0.405, 0.34, 0), "slate", Vector3.ZERO, 0.008)
	_corners(0.39, 0.1, 0.6, "gold", 0.075)
	_box(Vector3(0.84, 0.05, 0.84), Vector3(0, 0.6, 0), "gold", Vector3.ZERO, 0.012)
	# Hopper: a square funnel, open, dark inside.
	_cyl(0.52, 0.32, 0.34, Vector3(0, 0.79, 0), "rust", Vector3(0, 45, 0), 4)
	_box(Vector3(0.52, 0.02, 0.52), Vector3(0, 0.9, 0), "dark", Vector3.ZERO, 0.005)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.76, 0.04, 0.04), Vector3(0, 0.97, s * 0.36), "gold", Vector3.ZERO, 0.01)
		_box(Vector3(0.04, 0.04, 0.76), Vector3(s * 0.36, 0.97, 0), "gold", Vector3.ZERO, 0.01)
	for s in [-1.0, 1.0]:
		var roller := _part(_root, Vector3(0, 0.93, s * 0.095))
		_open(roller)
		_add(SliceGeo.gear(0.1, 0.5, 9), Vector3.ZERO, "steel", Vector3(0, 90, 0))
		_close()
		_spin.append([roller, Vector3.RIGHT, 6.0 * s])
	# Output: a chute out of the front and a lit slot above it.
	_box(Vector3(0.32, 0.05, 0.2), Vector3(0, 0.2, 0.47), "rust", Vector3(28, 0, 0))
	_glow_box(Vector3(0.36, 0.07, 0.03), Vector3(0, 0.45, 0.415), "amber", 2.2)
	for x in [-0.12, 0.0, 0.12]:
		_box(Vector3(0.025, 0.1, 0.02), Vector3(x, 0.45, 0.425), "dark", Vector3.ZERO, 0.005)
	_dust = _particles(8, 0.8, Color(0.78, 0.62, 0.45, 0.5), 0.14,
		Vector3(0, 1.0, 0), 0.4, 40.0)


func _build_smelter() -> void:
	_plinth()
	_box(Vector3(0.84, 0.62, 0.78), Vector3(0, 0.41, 0), "brick", Vector3.ZERO, 0.05)
	for y in [0.28, 0.42, 0.56]:
		_box(Vector3(0.85, 0.015, 0.79), Vector3(0, y, 0), "brick2", Vector3.ZERO, 0.004)
	for y in [0.16, 0.68]:
		_box(Vector3(0.88, 0.06, 0.82), Vector3(0, y, 0), "steel", Vector3.ZERO, 0.015)
	_corners(0.41, 0.1, 0.72, "gun", 0.07)
	# The mouth: a steel frame, grate bars, molten metal behind.
	_box(Vector3(0.54, 0.4, 0.05), Vector3(0, 0.4, 0.39), "gun", Vector3.ZERO, 0.02)
	_glow_box(Vector3(0.42, 0.28, 0.05), Vector3(0, 0.39, 0.405), "molten", 3.0)
	for x in [-0.12, 0.0, 0.12]:
		_box(Vector3(0.03, 0.3, 0.03), Vector3(x, 0.39, 0.435), "dark", Vector3.ZERO, 0.006)
	_box(Vector3(0.5, 0.05, 0.14), Vector3(0, 0.2, 0.45), "gold", Vector3.ZERO, 0.012)
	# The crucible on top, brim-full.
	_cyl(0.22, 0.17, 0.2, Vector3(-0.1, 0.82, 0.05), "steel", Vector3.ZERO, 12)
	_add(SliceGeo.torus(0.2, 0.235, 12), Vector3(-0.1, 0.92, 0.05), "gold")
	_glow(SliceGeo.cylinder(0.19, 0.19, 0.02, 12), Vector3(-0.1, 0.915, 0.05), "molten", 3.2)
	# The stack, glowing at the lip.
	_cyl(0.1, 0.13, 0.7, Vector3(0.24, 1.07, -0.22), "brick", Vector3.ZERO, 10)
	_cyl(0.13, 0.13, 0.06, Vector3(0.24, 0.86, -0.22), "steel", Vector3.ZERO, 10)
	_cyl(0.125, 0.11, 0.06, Vector3(0.24, 1.4, -0.22), "steel", Vector3.ZERO, 10)
	_glow(SliceGeo.torus(0.07, 0.1, 10), Vector3(0.24, 1.44, -0.22), "ember", 2.6)
	_light_at(Color("ff7a2f"), 2.4, 2.1, Vector3(0, 0.45, 0.75))
	_smoke = _particles(14, 2.2, Color(0.33, 0.3, 0.32, 0.55), 0.32,
		Vector3(0.24, 1.48, -0.22), 0.45, 12.0)


func _build_boiler() -> void:
	_box(Vector3(0.74, 0.26, 0.74), Vector3(0, 0.13, 0), "gun", Vector3.ZERO, 0.04)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.76, 0.03, 0.04), Vector3(0, 0.26, s * 0.36), "gold", Vector3.ZERO, 0.01)
		_box(Vector3(0.04, 0.03, 0.76), Vector3(s * 0.36, 0.26, 0), "gold", Vector3.ZERO, 0.01)
	_glow_box(Vector3(0.5, 0.1, 0.03), Vector3(0, 0.13, 0.375), "fire", 3.0)
	for x in [-0.15, -0.05, 0.05, 0.15]:
		_box(Vector3(0.025, 0.12, 0.02), Vector3(x, 0.13, 0.39), "dark", Vector3.ZERO, 0.005)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.12, 0.24, 0.62), Vector3(s * 0.26, 0.38, 0), "steel", Vector3.ZERO, 0.025)
	_cyl(0.3, 0.3, 0.8, Vector3(0, 0.66, 0), "red", Vector3(0, 0, 90), 18)
	for s in [-1.0, 1.0]:
		_add(SliceGeo.sphere(0.3, 14), Vector3(s * 0.4, 0.66, 0), "gold", Vector3.ZERO,
			Vector3(0.3, 1, 1))
	for x in [-0.22, 0.0, 0.22]:
		_add(SliceGeo.torus(0.295, 0.325, 18), Vector3(x, 0.66, 0), "brass", Vector3(0, 0, 90))
	# Stack, safety valve, gauge.
	_cyl(0.075, 0.09, 0.62, Vector3(-0.2, 1.22, -0.06), "steel", Vector3.ZERO, 10)
	_cyl(0.12, 0.08, 0.09, Vector3(-0.2, 1.56, -0.06), "gold", Vector3.ZERO, 10)
	_cyl(0.04, 0.05, 0.14, Vector3(0.14, 1.0, -0.02), "gold", Vector3.ZERO, 8)
	_cyl(0.11, 0.11, 0.05, Vector3(0.16, 0.7, 0.3), "gold", Vector3(90, 0, 0), 14)
	_glow(SliceGeo.cylinder(0.082, 0.082, 0.02, 14), Vector3(0.16, 0.7, 0.33), "cold", 1.6,
		Vector3(90, 0, 0))
	_beam(Vector3(-0.28, 0.5, 0.2), Vector3(-0.28, 0.27, 0.3), 0.05, "brass")
	var wheel := _part(_root, Vector3(0.14, 1.08, -0.02))
	_open(wheel)
	_add(SliceGeo.torus(0.05, 0.08, 10), Vector3.ZERO, "red")
	_box(Vector3(0.15, 0.02, 0.02), Vector3.ZERO, "red", Vector3.ZERO, 0.005)
	_box(Vector3(0.02, 0.02, 0.15), Vector3.ZERO, "red", Vector3.ZERO, 0.005)
	_close()
	_spin.append([wheel, Vector3.UP, 1.4])
	_light_at(Color("ff5a2a"), 2.0, 1.8, Vector3(0, 0.2, 0.7))
	_smoke = _particles(18, 2.4, Color(0.94, 0.95, 1.0, 0.5), 0.34,
		Vector3(-0.2, 1.62, -0.06), 0.6, 10.0)


func _build_press() -> void:
	_box(Vector3(0.9, 0.22, 0.9), Vector3(0, 0.11, 0), "gun", Vector3.ZERO, 0.04)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.92, 0.035, 0.045), Vector3(0, 0.22, s * 0.44), "gold", Vector3.ZERO, 0.01)
	for i in range(7):
		_box(Vector3(0.1, 0.08, 0.02), Vector3(-0.36 + float(i) * 0.12, 0.11, 0.455),
			"yellow" if i % 2 == 0 else "dark", Vector3(0, 0, 30), 0.005)
	_box(Vector3(0.54, 0.08, 0.54), Vector3(0, 0.26, 0), "chrome", Vector3.ZERO, 0.02)
	_glow_box(Vector3(0.28, 0.06, 0.16), Vector3(0, 0.33, 0), "molten", 2.8)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.16, 1.1, 0.24), Vector3(s * 0.36, 0.77, 0), "blue", Vector3.ZERO, 0.035)
		for y in [0.36, 1.18]:
			_cyl(0.035, 0.035, 0.03, Vector3(s * 0.36, y, 0.125), "chrome", Vector3(90, 0, 0), 8)
	_box(Vector3(0.94, 0.26, 0.48), Vector3(0, 1.38, 0), "blue", Vector3.ZERO, 0.06)
	_box(Vector3(0.96, 0.04, 0.5), Vector3(0, 1.24, 0), "gold", Vector3.ZERO, 0.012)
	_glow_box(Vector3(0.5, 0.045, 0.03), Vector3(0, 1.38, 0.245), "cold", 2.2)
	_cyl(0.13, 0.13, 0.22, Vector3(0, 1.62, 0), "steel", Vector3.ZERO, 14)
	_cyl(0.15, 0.15, 0.04, Vector3(0, 1.74, 0), "gold", Vector3.ZERO, 14)
	_ram = _part(_root, Vector3(0, 0.95, 0))
	_open(_ram)
	_box(Vector3(0.54, 0.22, 0.44), Vector3.ZERO, "steel", Vector3.ZERO, 0.04)
	_box(Vector3(0.56, 0.04, 0.46), Vector3(0, 0.06, 0), "gold", Vector3.ZERO, 0.01)
	_box(Vector3(0.46, 0.05, 0.38), Vector3(0, -0.13, 0), "chrome", Vector3.ZERO, 0.012)
	_cyl(0.05, 0.05, 0.5, Vector3(0, 0.36, 0), "chrome", Vector3.ZERO, 10)
	_close()
	_sparks = _particles(16, 0.4, Color(1.0, 0.75, 0.3, 1.0), 0.05,
		Vector3(0, 0.34, 0.12), 1.8, 80.0)
	_sparks.gravity = Vector3(0, -6, 0)
	_sparks.one_shot = true
	_sparks.emitting = false
	_sparks.explosiveness = 1.0
	(_sparks.mesh as QuadMesh).material = SliceMats.glow("ember", 8.0)
	(_sparks.mesh.material as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED


func _build_vault() -> void:
	_plinth()
	_box(Vector3(0.8, 0.66, 0.8), Vector3(0, 0.43, 0), "teal", Vector3.ZERO, 0.06)
	_corners(0.385, 0.1, 0.78, "gold", 0.11)
	_box(Vector3(0.86, 0.05, 0.86), Vector3(0, 0.78, 0), "gold", Vector3.ZERO, 0.015)
	_box(Vector3(0.72, 0.04, 0.72), Vector3(0, 0.82, 0), "teal", Vector3.ZERO, 0.012)
	_cyl(0.27, 0.27, 0.06, Vector3(0, 0.44, 0.41), "steel", Vector3(90, 0, 0), 18)
	_glow(SliceGeo.torus(0.27, 0.3, 18), Vector3(0, 0.44, 0.425), "green", 2.2, Vector3(90, 0, 0))
	for y in [0.3, 0.58]:
		_box(Vector3(0.08, 0.06, 0.05), Vector3(-0.3, y, 0.42), "gold", Vector3.ZERO, 0.01)
	_glow_box(Vector3(0.34, 0.03, 0.08), Vector3(0, 0.845, 0), "gold", 2.4)
	for i in range(3):
		_cyl(0.07, 0.07, 0.022, Vector3(0.24, 0.85 + float(i) * 0.024, 0.22), "gold",
			Vector3.ZERO, 12)
	var wheel := _part(_root, Vector3(0, 0.44, 0.46))
	wheel.rotation_degrees = Vector3(90, 0, 0)
	_open(wheel)
	_add(SliceGeo.torus(0.08, 0.11, 12), Vector3.ZERO, "gold")
	for i in range(3):
		_box(Vector3(0.22, 0.02, 0.025), Vector3.ZERO, "gold", Vector3(0, float(i) * 60.0, 0), 0.005)
	_close()
	_spin.append([wheel, Vector3.UP, 2.0])


## A status pip on the front corner of the plinth, and a floating badge that
## only appears when something needs the player: a red "!" for a machine that
## has stopped, an orange thermometer for one losing output to heat.
func _build_status() -> void:
	_badge = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.46, 0.46)
	_badge.mesh = q
	_badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_badge.position = Vector3(0, float(TOP[kind]), 0)
	_badge.visible = false
	add_child(_badge)


# --- behaviour ---------------------------------------------------------------

## Make this a placement preview: every surface ghosted, nothing lit, nothing
## moving, a green "+" over it.
func set_ghost() -> void:
	_ghost = true
	for c in find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_override = SliceMats.ghost()
		(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in find_children("*", "CPUParticles3D", true, false):
		(c as CPUParticles3D).emitting = false
	if _light != null:
		_light.visible = false
	_badge.material_override = SliceMats.badge(2, Color("22c77a"))
	_badge.visible = true


## Drive the machine from the simulation's view of its tile.
##   working  it is doing its job (running, or stalled only momentarily)
##   stall    0 fine, 1 backed up, 2 starved
##   stopped  stalled AND barely working -- the player should look here
func drive(delta: float, working: bool, stall: int, stopped: bool, phase: float,
		hot: bool) -> void:
	_t += delta
	if _ghost:
		_root.position.y = 0.05 + sin(_t * 3.0) * 0.03
		_badge.position.y = float(TOP[kind]) + sin(_t * 3.0) * 0.05
		return

	if working and phase < _last_phase - 0.3:
		_pulse = 1.0
		cycled.emit()
		if _sparks != null:
			_sparks.restart()
			_sparks.emitting = true
	_last_phase = phase
	_pulse = maxf(_pulse - delta * 5.0, 0.0)
	var squash: float = 1.0 + 0.06 * sin(_pulse * PI)
	_root.scale = Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash))

	if working:
		for s: Array in _spin:
			(s[0] as Node3D).rotate(s[1], float(s[2]) * delta)
	if _bob != null:
		_bob.position.y = -0.16 * sin(phase * PI) if working else 0.0
	if _ram != null:
		var fall: float = 0.0
		if working:
			fall = clampf((phase - 0.8) / 0.12, 0.0, 1.0)
			fall = fall * fall
			if phase < 0.25:
				fall = 1.0 - clampf(phase / 0.25, 0.0, 1.0)
		_ram.position.y = 0.95 - fall * 0.47

	if hot and not stopped:
		_root.position = Vector3(sin(_t * 61.0) * 0.012, 0, cos(_t * 53.0) * 0.012)
	else:
		_root.position = Vector3.ZERO

	_lamp_mat.set_shader_parameter("power", 1.0 if not stopped else 0.18)
	_lamp_mat.set_shader_parameter("flicker", 0.35 if hot else 0.0)
	if _light != null:
		var flicker: float = 0.85 + 0.15 * sin(_t * 17.0) * sin(_t * 7.3)
		_light.light_energy = _light_energy * (flicker if not stopped else 0.12)
	for p in [_smoke, _dust]:
		if p != null:
			(p as CPUParticles3D).emitting = working
	if hot and _haze == null:
		_haze = _particles(8, 1.4, Color(1.0, 0.55, 0.25, 0.3), 0.34,
			Vector3(0, float(TOP[kind]) - 0.6, 0), 0.5, 25.0)
	if _haze != null:
		_haze.emitting = hot
	if _pile != null:
		_pile.visible = stall == 1 and stopped

	var blink: bool = fposmod(_t, 0.8) < 0.45
	var pip := Color("4dff9a")
	var pip_e: float = 2.5
	if stopped:
		pip = Color("ff3030") if stall == 2 else Color("ffb21f")
		pip_e = 3.0 if blink else 0.2
	elif hot:
		pip = Color("ff7a2a")
	_lamp_mat.set_shader_parameter("pip_color", pip)
	_lamp_mat.set_shader_parameter("pip_energy", pip_e)
	_badge.visible = stopped or hot
	if stopped:
		_badge.material_override = SliceMats.badge(0, Color("e8392f") if stall == 2
			else Color("f08a1c"))
	elif hot:
		_badge.material_override = SliceMats.badge(1, Color("f25a1c"))
	_badge.position.y = float(TOP[kind]) + absf(sin(_t * 4.0)) * 0.08
