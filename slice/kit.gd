class_name SliceKit
extends RefCounted

## Bakes many small solids into ONE mesh.
##
## Every part is appended with its colour, metalness and roughness written
## into the vertices (colour in COLOR, metal/rough in UV2), so a whole machine
## body -- plinth, frame, panels, bolts, pipes -- is a single mesh drawn with a
## single shared material. That is the mobile technique the brief names
## (shared materials, few draw calls) without giving up per-part materials:
## the steel still looks like steel and the brass like brass, because the
## shader reads them per vertex.
##
## Lamps use the same trick with UV2.x as emission energy.

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _uv2 := PackedVector2Array()
var _i := PackedInt32Array()


func is_empty() -> bool:
	return _v.is_empty()


func add(mesh: Mesh, xf: Transform3D, col: Color, a: float = 0.3,
		b: float = 0.5) -> void:
	var nb: Basis = xf.basis.inverse().transposed()
	for s in range(mesh.get_surface_count()):
		var arr: Array = mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var base: int = _v.size()
		for k in range(verts.size()):
			_v.append(xf * verts[k])
			_n.append((nb * norms[k]).normalized())
			_c.append(col)
			_uv2.append(Vector2(a, b))
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		if idx == null or (idx as PackedInt32Array).is_empty():
			for k in range(verts.size()):
				_i.append(base + k)
		else:
			for k: int in (idx as PackedInt32Array):
				_i.append(base + k)


func commit() -> ArrayMesh:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _v
	arr[Mesh.ARRAY_NORMAL] = _n
	arr[Mesh.ARRAY_COLOR] = _c
	arr[Mesh.ARRAY_TEX_UV2] = _uv2
	arr[Mesh.ARRAY_INDEX] = _i
	var m := ArrayMesh.new()
	if not _v.is_empty():
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


static func xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> Transform3D:
	var bas := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x),
		deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z))).scaled(scl)
	return Transform3D(bas, pos)


## A box stretched between two points -- legs, braces, girders.
static func beam_xf(a: Vector3, b: Vector3) -> Transform3D:
	var d: Vector3 = b - a
	var y: Vector3 = d.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), (a + b) * 0.5)
