class_name SliceMats
extends RefCounted

## Every material in the slice, created once and shared.
##
## Sharing is what keeps the draw-call count sane: the renderer batches by
## material, so seventy tiles on one material cost one draw call per pass and
## seventy tiles on seventy materials cost seventy.
##
## The palette is the reference's, split by what a thing is MADE of rather
## than by what it is -- the brief's point that metal, rock, glass, energy,
## crystal, pipe and heat have to look physically different from each other.
## Painted machine metal is saturated and a little glossy; bare steel is dark
## and metallic; brass is warm and bright; stone is rough and matte; anything
## that makes its own light is emissive and blooms.

static var _m: Dictionary = {}


static func _std(key: String, albedo: Color, metallic: float = 0.0,
		roughness: float = 0.7) -> StandardMaterial3D:
	if _m.has(key):
		return _m[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	m.metallic_specular = 0.55
	_m[key] = m
	return m


static func _glow(key: String, col: Color, energy: float) -> StandardMaterial3D:
	if _m.has(key):
		return _m[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.roughness = 0.4
	_m[key] = m
	return m


# --- metals and paint --------------------------------------------------------

static func paint(name: String) -> StandardMaterial3D:
	const P := {
		"yellow": "f2b134",   # mining equipment
		"red": "d2412c",      # pressure vessel
		"teal": "2f9a7c",     # the vault
		"blue": "5d86b8",     # cold steel machinery
		"slate": "6d7f97",    # the crusher
		"brick": "8a4632",    # furnace brick
		"rust": "c9692f",     # hoppers and chutes
		"cream": "e8dcc4",    # enamel panels
	}
	return _std("paint:" + name, Color(String(P.get(name, "999999"))), 0.25, 0.42)


static func steel() -> StandardMaterial3D:
	return _std("steel", Color("3a4150"), 0.75, 0.38)


static func chrome() -> StandardMaterial3D:
	return _std("chrome", Color("c9d2de"), 0.95, 0.18)


static func brass() -> StandardMaterial3D:
	return _std("brass", Color("e0a84a"), 0.9, 0.28)


static func rubber() -> StandardMaterial3D:
	return _std("rubber", Color("1e2026"), 0.0, 0.8)


static func wood() -> StandardMaterial3D:
	return _std("wood", Color("7a5234"), 0.0, 0.85)


# --- stone -------------------------------------------------------------------

static func rock(tint: String = "rock") -> StandardMaterial3D:
	const R := {
		"rock": "5b5363",      # the chamber walls, violet-grey
		"dark": "2e2a36",      # deep rock and the cave floor
		"slab": "4a4652",      # the platform the board stands on
		"warm": "7a6558",      # sunlit rock
		"moss": "4f8a3c",      # the only green underground
		"cave": "6e4b37",      # the Workings: warm, iron-stained rock
		"cave_back": "4e3a44", # the far wall, cooler, so the lit board stands off it
		"cave_dark": "3b2920",
		"ochre": "8c6440",
	}
	return _std("rock:" + tint, Color(String(R.get(tint, "5b5363"))), 0.0, 0.95)


# --- light -------------------------------------------------------------------

static func glow(name: String, energy: float = 3.0) -> StandardMaterial3D:
	const G := {
		"molten": "ff6a1f",
		"fire": "ff3b12",
		"ember": "ff9a3a",
		"lamp": "ffd48a",
		"cold": "cfe6ff",
		"cyan": "4fd8ff",
		"green": "4dff9a",
		"violet": "b86bff",
		"gold": "ffcf4a",
		"amber": "ffb21f",
		"alarm": "ff3030",
		"water": "3fb8ff",
	}
	return _glow("glow:%s:%.1f" % [name, energy],
		Color(String(G.get(name, "ffffff"))), energy)


## The same light switched off: what an emissive part looks like on a stalled
## machine. Dark, but still the colour of the thing, so it reads as "off"
## rather than "missing".
static func dim(name: String) -> StandardMaterial3D:
	return glow(name, 0.25)


static func crystal(name: String) -> StandardMaterial3D:
	var key: String = "crystal:" + name
	if _m.has(key):
		return _m[key]
	var m: StandardMaterial3D = glow(name, 0.9).duplicate()
	m.albedo_color = m.albedo_color.darkened(0.25)
	m.metallic = 0.3
	m.roughness = 0.18
	m.rim_enabled = true
	m.rim = 0.6
	_m[key] = m
	return m


## Translucent, unlit, for the placement preview. The only transparent
## material on the board, on purpose: transparency is overdraw on a phone.
static func ghost() -> StandardMaterial3D:
	if _m.has("ghost"):
		return _m["ghost"]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.45, 1.0, 0.8, 0.32)
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_m["ghost"] = m
	return m


static func puff(col: Color) -> StandardMaterial3D:
	var key: String = "puff:" + col.to_html()
	if _m.has(key):
		return _m[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_color = col
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_m[key] = m
	return m


# --- shaders -----------------------------------------------------------------

## The board tiles. Heat is drawn INTO the stone: a tile under a Boiler glows
## from the top face like a hotplate, a cold tile frosts over. Per-tile data
## arrives through the MultiMesh's custom channel, so seventy tiles with
## seventy different heats are still one draw call.
static func tiles() -> ShaderMaterial:
	if _m.has("tiles"):
		return _m["tiles"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 top_color : source_color = vec3(0.54, 0.41, 0.30);
uniform vec3 top_color2 : source_color = vec3(0.44, 0.32, 0.23);
uniform vec3 side_color : source_color = vec3(0.27, 0.17, 0.12);
uniform vec3 hot_color : source_color = vec3(1.0, 0.36, 0.08);
uniform vec3 cold_color : source_color = vec3(0.4, 0.75, 1.0);
uniform vec3 hi_color : source_color = vec3(0.35, 1.0, 0.72);
varying float v_heat;
varying float v_var;
varying float v_hi;
varying float v_top;
varying vec3 v_w;
varying vec3 v_l;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	v_heat = INSTANCE_CUSTOM.r;
	v_var = INSTANCE_CUSTOM.g;
	v_hi = INSTANCE_CUSTOM.b;
	v_top = smoothstep(0.55, 0.9, NORMAL.y);
	v_w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_l = VERTEX;
}
void fragment() {
	// Sandstone: two octaves of mottling, a darker rim toward each block's
	// edge, and a per-block tint so the floor never reads as one sheet.
	float n = vnoise(v_w.xz * 3.1) * 0.6 + vnoise(v_w.xz * 9.0 + 7.0) * 0.4;
	vec3 top = mix(top_color2, top_color, clamp(n * 1.2 - 0.1 + (v_var - 0.5) * 0.5, 0.0, 1.0));
	float edge = smoothstep(0.3, 0.42, max(abs(v_l.x), abs(v_l.z)));
	top *= 1.0 - edge * 0.18;
	vec3 base = mix(side_color, top, v_top);
	float h = clamp(v_heat, -1.0, 1.0);
	float hot = max(h, 0.0);
	// Hot stone darkens and reddens before it glows, the way a hotplate does.
	base = mix(base, base * vec3(1.0, 0.7, 0.58), hot * v_top);
	ALBEDO = base;
	ROUGHNESS = 0.86;
	float cracks = smoothstep(0.46, 0.5, vnoise(v_w.xz * 5.0 + 3.0)) * smoothstep(0.54, 0.5, vnoise(v_w.xz * 5.0 + 3.0));
	vec3 em = hot_color * hot * hot * (1.6 + cracks * 3.0) * v_top;
	em += cold_color * max(-h, 0.0) * 0.5 * v_top;
	em += hi_color * v_hi * (0.9 + 0.5 * sin(TIME * 5.0)) * v_top;
	EMISSION = em;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_m["tiles"] = m
	return m


## Conveyor belts: dark rubber with bright cleats scrolling in the direction of
## flow. The one piece of the board whose whole job is to say "this is
## moving", so it moves even between the moments a crate is on it.
static func belt(live: bool) -> ShaderMaterial:
	var key: String = "belt:%s" % str(live)
	if _m.has(key):
		return _m[key]
	var sh: Shader
	if _m.has("belt_shader"):
		sh = _m["belt_shader"]
	else:
		sh = Shader.new()
		sh.code = """
shader_type spatial;
uniform float speed = 1.6;
uniform float live = 1.0;
uniform vec3 cleat : source_color = vec3(1.0, 0.72, 0.25);
void fragment() {
	float s = step(0.62, fract(UV.x * 5.0 - TIME * speed * live));
	vec3 rubber = vec3(0.07, 0.075, 0.09);
	ALBEDO = mix(rubber, vec3(0.32, 0.30, 0.28), s);
	EMISSION = cleat * s * 0.9 * live;
	ROUGHNESS = 0.7;
}
"""
		_m["belt_shader"] = sh
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("live", 1.0 if live else 0.0)
	_m[key] = m
	return m


## Running water, for the channel along the side of the chamber and the fall
## that feeds it. Cold blue against a warm factory is the colour contrast the
## reference gets from its waterfalls.
static func water(vertical: bool) -> ShaderMaterial:
	var key: String = "water:%s" % str(vertical)
	if _m.has(key):
		return _m[key]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform float vertical = 0.0;
void fragment() {
	float flow = mix(UV.x, UV.y, vertical);
	float across = mix(UV.y, UV.x, vertical);
	float band = sin((flow * 9.0 - TIME * (2.0 + vertical * 3.0)) + sin(across * 13.0) * 0.8);
	float foam = smoothstep(0.75, 1.0, band);
	vec3 deep = vec3(0.05, 0.28, 0.55);
	vec3 lit = vec3(0.35, 0.8, 1.0);
	ALBEDO = mix(deep, lit, 0.35 + 0.35 * band) + foam * 0.45;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("vertical", 1.0 if vertical else 0.0)
	_m[key] = m
	return m


# --- baked parts (see SliceKit) --------------------------------------------------

## Vertex colours reach the shader already linear (measured: a raw COLOR
## renders identically to a StandardMaterial3D of the same albedo), so the
## shaders use them as they are.

## Everything solid on a machine: colour, metal and roughness per vertex.
## Near the floor the albedo darkens -- a baked contact occlusion that grounds
## every machine on its tile for free.
static func body() -> ShaderMaterial:
	if _m.has("body"):
		return _m["body"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float rim_amount = 0.35;
varying float v_wy;

void vertex() {
	v_wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
void fragment() {
	vec3 c = COLOR.rgb;
	float ao = mix(0.42, 1.0, smoothstep(0.0, 0.32, v_wy));
	ALBEDO = c * ao;
	METALLIC = UV2.x;
	ROUGHNESS = UV2.y;
	RIM = rim_amount;
	RIM_TINT = 0.4;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_m["body"] = m
	return m


## Everything on a machine that makes its own light. One material per
## machine (so a stalled machine can turn its lamps down) but still one draw
## call per machine for all of them.
static func lamp_shader() -> Shader:
	if _m.has("lamp_shader"):
		return _m["lamp_shader"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform float power = 1.0;
uniform float flicker = 0.0;
uniform vec3 pip_color : source_color = vec3(0.3, 1.0, 0.6);
uniform float pip_energy = 2.5;

void fragment() {
	vec3 c = COLOR.rgb;
	float f = 1.0 - flicker * (0.5 + 0.5 * sin(TIME * 23.0 + VERTEX.x * 3.0) * sin(TIME * 9.0));
	vec3 lit = c * max(UV2.x * power * f, 0.12);
	ALBEDO = mix(lit, pip_color * pip_energy, step(0.5, UV2.y));
}
"""
	_m["lamp_shader"] = sh
	return sh


static func lamp() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = lamp_shader()
	return m


## Soft contact shadows and pools of machine light on the floor, both as
## flat quads in one MultiMesh each. A real omni light per machine would cost
## a pass per object it touches; a pool costs one quad.
static func blob() -> ShaderMaterial:
	if _m.has("blob"):
		return _m["blob"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = max(abs(p.x), abs(p.y));
	float r = length(p) * 0.6 + d * 0.4;
	float s = smoothstep(1.0, 0.35, r);
	ALBEDO = vec3(0.06, 0.035, 0.03);
	ALPHA = s * 0.5;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_m["blob"] = m
	return m


static func pool() -> ShaderMaterial:
	if _m.has("pool"):
		return _m["pool"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
varying vec4 v_col;
void vertex() {
	v_col = INSTANCE_CUSTOM;
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float s = pow(clamp(1.0 - r, 0.0, 1.0), 1.8);
	float pulse = 0.85 + 0.15 * sin(TIME * 3.0 + v_col.a * 20.0);
	ALBEDO = v_col.rgb * s * pulse;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_m["pool"] = m
	return m


## Status badges that float over a machine: a round plate with an icon drawn
## as a distance field, so no font or texture is needed and it is sharp at
## any size. 0 = alert (!), 1 = too hot (thermometer), 2 = place here (+).
static func badge(icon: int, col: Color) -> ShaderMaterial:
	var key: String = "badge:%d:%s" % [icon, col.to_html()]
	if _m.has(key):
		return _m[key]
	if not _m.has("badge_shader"):
		var sh := Shader.new()
		sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;
uniform vec3 plate : source_color = vec3(1.0, 0.2, 0.2);
uniform int icon = 0;
float box(vec2 p, vec2 b) { vec2 d = abs(p) - b; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float r = length(p);
	if (r > 1.0) discard;
	float ring = smoothstep(0.80, 0.84, r);
	float g = 1e3;
	if (icon == 0) {
		g = min(box(p - vec2(0.0, 0.16), vec2(0.1, 0.36)), length(p - vec2(0.0, -0.44)) - 0.12);
	} else if (icon == 1) {
		g = min(box(p - vec2(0.0, 0.16), vec2(0.1, 0.38)), length(p - vec2(0.0, -0.36)) - 0.22);
	} else {
		g = min(box(p, vec2(0.12, 0.48)), box(p, vec2(0.48, 0.12)));
	}
	float glyph = 1.0 - smoothstep(0.0, 0.03, g);
	vec3 c = mix(plate, vec3(1.0), glyph);
	c = mix(c, vec3(1.0, 0.97, 0.9), ring);
	ALBEDO = c * 1.25;
}
"""
		_m["badge_shader"] = sh
	var m := ShaderMaterial.new()
	m.shader = _m["badge_shader"]
	m.set_shader_parameter("plate", col)
	m.set_shader_parameter("icon", icon)
	m.render_priority = 10
	_m[key] = m
	return m


## Smoke, steam, dust and heat haze: camera-facing quads with a soft round
## falloff, coloured per particle by the emitter's ramp.
static func soft_puff() -> ShaderMaterial:
	if _m.has("soft_puff"):
		return _m["soft_puff"]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
varying vec4 v_col;
void vertex() {
	float sc = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc, INV_VIEW_MATRIX[1] * sc,
		INV_VIEW_MATRIX[2] * sc, MODEL_MATRIX[3]);
	v_col = COLOR;
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float a = smoothstep(1.0, 0.1, length(p));
	ALBEDO = v_col.rgb;
	ALPHA = v_col.a * a;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	_m["soft_puff"] = m
	return m
