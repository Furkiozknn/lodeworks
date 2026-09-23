class_name SliceGeo
extends RefCounted

## Procedural low-poly geometry for the 3D vertical slice.
##
## No Blender in the toolchain and no way to bring generated meshes into the
## build environment, so every solid is made here from vertices. That is also
## the right answer on its own terms: flat-shaded chamfered solids are exactly
## the toy-industrial look of the reference, every one of them is a handful of
## triangles, and they share materials so the whole board batches.

static var _cache: Dictionary = {}


## Emit one flat-shaded polygon (convex, points in any consistent order) with
## the given outward normal. Winding is fixed up here so callers never have to
## think about it: Godot treats clockwise triangles as front-facing.
static func _poly(st: SurfaceTool, pts: Array, n: Vector3) -> void:
	for i in range(1, pts.size() - 1):
		var a: Vector3 = pts[0]
		var b: Vector3 = pts[i]
		var c: Vector3 = pts[i + 1]
		if (b - a).cross(c - a).dot(n) > 0.0:
			var t: Vector3 = b
			b = c
			c = t
		st.set_normal(n)
		st.add_vertex(a)
		st.set_normal(n)
		st.add_vertex(b)
		st.set_normal(n)
		st.add_vertex(c)


## A box with every edge chamfered. Six inset faces, twelve edge bevels and
## eight corner triangles -- the chamfers catch the key light as separate
## facets, which is most of what makes a block read as a machined, toy-like
## object instead of a cube.
static func bevel_box(size: Vector3, bevel: float = 0.06) -> ArrayMesh:
	var key: String = "bb:%s:%.3f" % [str(size), bevel]
	if _cache.has(key):
		return _cache[key]
	var h: Vector3 = size * 0.5
	var b: float = minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.95)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ix: float = h.x - b
	var iy: float = h.y - b
	var iz: float = h.z - b
	# Faces.
	for s in [-1.0, 1.0]:
		_poly(st, [Vector3(s * h.x, -iy, -iz), Vector3(s * h.x, iy, -iz),
			Vector3(s * h.x, iy, iz), Vector3(s * h.x, -iy, iz)], Vector3(s, 0, 0))
		_poly(st, [Vector3(-ix, s * h.y, -iz), Vector3(ix, s * h.y, -iz),
			Vector3(ix, s * h.y, iz), Vector3(-ix, s * h.y, iz)], Vector3(0, s, 0))
		_poly(st, [Vector3(-ix, -iy, s * h.z), Vector3(ix, -iy, s * h.z),
			Vector3(ix, iy, s * h.z), Vector3(-ix, iy, s * h.z)], Vector3(0, 0, s))
	# Edge chamfers.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_poly(st, [Vector3(sx * h.x, sy * iy, -iz), Vector3(sx * ix, sy * h.y, -iz),
				Vector3(sx * ix, sy * h.y, iz), Vector3(sx * h.x, sy * iy, iz)],
				Vector3(sx, sy, 0).normalized())
		for sz in [-1.0, 1.0]:
			_poly(st, [Vector3(sx * h.x, -iy, sz * iz), Vector3(sx * ix, -iy, sz * h.z),
				Vector3(sx * ix, iy, sz * h.z), Vector3(sx * h.x, iy, sz * iz)],
				Vector3(sx, 0, sz).normalized())
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_poly(st, [Vector3(-ix, sy * h.y, sz * iz), Vector3(-ix, sy * iy, sz * h.z),
				Vector3(ix, sy * iy, sz * h.z), Vector3(ix, sy * h.y, sz * iz)],
				Vector3(0, sy, sz).normalized())
	# Corners.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_poly(st, [Vector3(sx * h.x, sy * iy, sz * iz),
					Vector3(sx * ix, sy * h.y, sz * iz),
					Vector3(sx * ix, sy * iy, sz * h.z)],
					Vector3(sx, sy, sz).normalized())
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


## A low-poly rock: a subdivided octahedron pushed about by a seeded noise,
## flat shaded so every facet catches the light differently.
static func rock(seed_value: int, radius: float = 0.5, squash: float = 0.75) -> ArrayMesh:
	var key: String = "rock:%d:%.2f:%.2f" % [seed_value, radius, squash]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var verts: Array = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0),
		Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var faces: Array = [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0],
		[4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
	# One subdivision: twenty-four... thirty-two facets, enough to read as stone.
	var mid_cache: Dictionary = {}
	var mid := func(a: int, bb: int) -> int:
		var k: String = "%d_%d" % [mini(a, bb), maxi(a, bb)]
		if mid_cache.has(k):
			return mid_cache[k]
		verts.append(((verts[a] + verts[bb]) * 0.5).normalized())
		mid_cache[k] = verts.size() - 1
		return verts.size() - 1
	var nf: Array = []
	for f: Array in faces:
		var ab: int = mid.call(f[0], f[1])
		var bc: int = mid.call(f[1], f[2])
		var ca: int = mid.call(f[2], f[0])
		nf.append([f[0], ab, ca])
		nf.append([f[1], bc, ab])
		nf.append([f[2], ca, bc])
		nf.append([ab, bc, ca])
	var pts: Array = []
	for v: Vector3 in verts:
		var s: float = radius * (0.78 + rng.randf() * 0.36)
		pts.append(Vector3(v.x * s, v.y * s * squash, v.z * s))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f: Array in nf:
		var a: Vector3 = pts[f[0]]
		var bb: Vector3 = pts[f[1]]
		var c: Vector3 = pts[f[2]]
		var n: Vector3 = (bb - a).cross(c - a).normalized()
		var centre: Vector3 = (a + bb + c) / 3.0
		if n.dot(centre) < 0.0:
			n = -n
		_poly(st, [a, bb, c], n)
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


## A crystal: a hexagonal prism with a pointed cap, flat shaded.
static func crystal(height: float = 1.0, radius: float = 0.14) -> ArrayMesh:
	var key: String = "cr:%.2f:%.2f" % [height, radius]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 6
	var body: float = height * 0.72
	var ring_lo: Array = []
	var ring_hi: Array = []
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		ring_lo.append(Vector3(cos(a) * radius, 0.0, sin(a) * radius))
		ring_hi.append(Vector3(cos(a) * radius * 0.92, body, sin(a) * radius * 0.92))
	var tip := Vector3(0, height, 0)
	for i in range(n):
		var j: int = (i + 1) % n
		var mid: float = TAU * (float(i) + 0.5) / float(n)
		var out := Vector3(cos(mid), 0, sin(mid))
		_poly(st, [ring_lo[i], ring_lo[j], ring_hi[j], ring_hi[i]], out)
		var cap_n: Vector3 = (out + Vector3(0, 0.7, 0)).normalized()
		_poly(st, [ring_hi[i], ring_hi[j], tip], cap_n)
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


## A toothed gear/roller: a cylinder with box teeth around it, as one mesh.
static func gear(radius: float, width: float, teeth: int = 10) -> ArrayMesh:
	var key: String = "gear:%.2f:%.2f:%d" % [radius, width, teeth]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = teeth * 2
	var hw: float = width * 0.5
	var r_in: float = radius * 0.80
	for i in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		var r: float = radius if i % 2 == 0 else r_in
		var p0 := Vector3(cos(a0) * r, sin(a0) * r, 0)
		var p1 := Vector3(cos(a1) * r, sin(a1) * r, 0)
		var out := Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0)
		_poly(st, [p0 + Vector3(0, 0, -hw), p1 + Vector3(0, 0, -hw),
			p1 + Vector3(0, 0, hw), p0 + Vector3(0, 0, hw)], out)
		# Tooth flanks.
		var nxt_r: float = r_in if i % 2 == 0 else radius
		var q := Vector3(cos(a1) * nxt_r, sin(a1) * nxt_r, 0)
		var flank_n := Vector3(-sin(a1), cos(a1), 0) * (1.0 if i % 2 == 0 else -1.0)
		_poly(st, [p1 + Vector3(0, 0, -hw), q + Vector3(0, 0, -hw),
			q + Vector3(0, 0, hw), p1 + Vector3(0, 0, hw)], flank_n)
		# Caps.
		for s in [-1.0, 1.0]:
			_poly(st, [Vector3(0, 0, s * hw), p0 + Vector3(0, 0, s * hw),
				p1 + Vector3(0, 0, s * hw)], Vector3(0, 0, s))
	var m: ArrayMesh = st.commit()
	_cache[key] = m
	return m


static func cylinder(r_top: float, r_bottom: float, height: float,
		sides: int = 12) -> CylinderMesh:
	var key: String = "cyl:%.3f:%.3f:%.3f:%d" % [r_top, r_bottom, height, sides]
	if _cache.has(key):
		return _cache[key]
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = height
	c.radial_segments = sides
	c.rings = 1
	_cache[key] = c
	return c


static func sphere(r: float, segs: int = 10) -> SphereMesh:
	var key: String = "sph:%.3f:%d" % [r, segs]
	if _cache.has(key):
		return _cache[key]
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(segs / 2, 4)
	_cache[key] = s
	return s


static func torus(inner: float, outer: float, sides: int = 14) -> TorusMesh:
	var key: String = "tor:%.3f:%.3f:%d" % [inner, outer, sides]
	if _cache.has(key):
		return _cache[key]
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = sides
	t.ring_segments = 6
	_cache[key] = t
	return t
