class_name IsoCamera
extends RefCounted

## The camera over the world: where it looks, how close, and how it moves.
##
## Pure arithmetic, no nodes, so every promise it makes is a unit test:
##
##   * it never shows anything outside the painting -- no void at any zoom,
##     at any aspect ratio, however hard it is flung
##   * it zooms about the point under the finger or the cursor
##   * a drag moves the world exactly with the finger; only after the finger
##     lifts does anything ease (the fling), so aiming at a tile is exact
##   * wheel steps and "go to that machine" glide rather than snap
##
## Two layers move under it. The board and its island are the near layer and
## follow the camera 1:1; the camera's centre stays inside `near_bounds`, the
## plateau and a margin. The painting behind is far away: it slides at
## `bg_parallax` of the camera's speed and scales by zoom^parallax, and is
## never shown smaller than covers the screen from where it is being looked
## at -- so however big the world is, and wherever the camera goes, there is
## painting behind it and never void.

var viewport := Vector2(1440, 720)
## The painting, in its own pixels, and the world point both layers share
## when the camera is centred on it.
var bg_size := Vector2(3840, 2160)
var anchor := Vector2(1920, 1015)
## How the painting scales with zoom (zoom^parallax) ...
var parallax := 0.82
## ... and how far it slides as the camera moves. Small: the world is far
## bigger than the painting, and the painting is far away.
var bg_parallax := 0.12
## Where the camera's centre may go, in world units. Empty: anywhere.
var near_bounds := Rect2()

var zoom_max := 1.6
## Far enough out to see the whole 44 x 44 board on a phone.
var zoom_floor := 0.22

var center := Vector2(1920, 1015)
var zoom := 1.0

var _target_zoom := 1.0
var _target_center := Vector2(1920, 1015)
var _gliding := false
## Settings' "Reduce motion": a focus cuts to its framing instead of gliding.
var instant := false
var _pivot_screen := Vector2.ZERO
var _pivot_world := Vector2.ZERO
var _pivoting := false
## World units per second, after a fling.
var velocity := Vector2.ZERO

## How quickly a glide closes the gap: a time constant, not a duration, so a
## long move and a short one feel the same.
const GLIDE_RATE := 11.0
const FLING_DECAY := 5.5
const FLING_STOP := 4.0


## The far layer's scale: zoom^parallax, but never smaller than what covers
## the screen from the point of the painting being looked at. The near layer
## can zoom out past that; the painting simply stops shrinking.
func bg_zoom(z: float, c: Vector2 = center) -> float:
	var cb: Vector2 = bg_center(c)
	var need: float = maxf(viewport.x * 0.5 / minf(cb.x, bg_size.x - cb.x),
		viewport.y * 0.5 / minf(cb.y, bg_size.y - cb.y))
	return maxf(maxf(pow(z, parallax), need), cover_zoom())


## The point of the painting the camera looks at: it slides a little with the
## camera, and stops well short of the painting's edges.
func bg_center(c: Vector2) -> Vector2:
	var cb: Vector2 = anchor + (c - anchor) * bg_parallax
	var m: Vector2 = bg_size * 0.3
	return Vector2(clampf(cb.x, m.x, bg_size.x - m.x), clampf(cb.y, m.y, bg_size.y - m.y))


func cover_zoom() -> float:
	return maxf(viewport.x / bg_size.x, viewport.y / bg_size.y)


func min_zoom() -> float:
	return zoom_floor


func clamp_zoom(z: float) -> float:
	return clampf(z, min_zoom(), maxf(zoom_max, min_zoom()))


## The nearest allowed centre: inside the world's bounds. The painting covers
## the screen from anywhere (bg_zoom), so this is only about not losing the
## plateau.
func clamp_center(c: Vector2, _z: float) -> Vector2:
	if near_bounds.size == Vector2.ZERO:
		return c
	return Vector2(clampf(c.x, near_bounds.position.x, near_bounds.end.x),
		clampf(c.y, near_bounds.position.y, near_bounds.end.y))


func world_to_screen(w: Vector2) -> Vector2:
	return viewport * 0.5 + (w - center) * zoom


func screen_to_world(s: Vector2) -> Vector2:
	return center + (s - viewport * 0.5) / zoom


## Where the far layer's pixel `q` lands on screen, and the transform that
## draws the painting.
func bg_transform() -> Transform2D:
	var zb: float = bg_zoom(zoom, center)
	var cb: Vector2 = bg_center(center)
	return Transform2D(0.0, Vector2(zb, zb), 0.0, viewport * 0.5 - cb * zb)


func near_transform() -> Transform2D:
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, viewport * 0.5 - center * zoom)


func set_viewport(size: Vector2) -> void:
	viewport = size
	zoom = clamp_zoom(zoom)
	_target_zoom = clamp_zoom(_target_zoom)
	center = clamp_center(center, zoom)
	_target_center = clamp_center(_target_center, _target_zoom)


## Frame a world rectangle inside a screen rectangle -- the part of the
## screen the interface leaves free -- and snap there. Used once at start;
## everything after that moves.
func fit(world_rect: Rect2, free_rect: Rect2, scale: float = 1.0) -> void:
	var z: float = minf(free_rect.size.x / world_rect.size.x,
		free_rect.size.y / world_rect.size.y) * scale
	zoom = clamp_zoom(z)
	# Centre the rectangle in the free area, not in the screen: the free area
	# is off-centre when the tray takes more room than the top bar.
	var off: Vector2 = free_rect.get_center() - viewport * 0.5
	center = clamp_center(world_rect.get_center() - off / zoom, zoom)
	_target_zoom = zoom
	_target_center = center
	_gliding = false
	_pivoting = false
	velocity = Vector2.ZERO


## A finger or a mouse moved by `delta` screen pixels while holding the world.
func drag(delta: Vector2) -> void:
	_gliding = false
	_pivoting = false
	velocity = Vector2.ZERO
	center = clamp_center(center - delta / zoom, zoom)
	_target_center = center


## The finger lifted while moving at `screen_velocity` px/s.
func release(screen_velocity: Vector2) -> void:
	velocity = -screen_velocity / zoom
	if velocity.length() * zoom < 60.0:
		velocity = Vector2.ZERO


## Pinch: applied immediately, about the midpoint of the two fingers.
func zoom_by(factor: float, screen_pt: Vector2) -> void:
	var w: Vector2 = screen_to_world(screen_pt)
	zoom = clamp_zoom(zoom * factor)
	center = clamp_center(w - (screen_pt - viewport * 0.5) / zoom, zoom)
	_target_zoom = zoom
	_target_center = center
	_gliding = false
	_pivoting = false
	velocity = Vector2.ZERO


## Wheel and buttons: glide to the new zoom, keeping `screen_pt` fixed.
func zoom_toward(factor: float, screen_pt: Vector2) -> void:
	_target_zoom = clamp_zoom(_target_zoom * factor)
	_pivot_screen = screen_pt
	_pivot_world = screen_to_world(screen_pt)
	_pivoting = true
	_gliding = false
	velocity = Vector2.ZERO


## Glide to look at a world point, optionally at a new zoom.
func focus(world_point: Vector2, z: float = -1.0) -> void:
	if z > 0.0:
		_target_zoom = clamp_zoom(z)
	_target_center = clamp_center(world_point, _target_zoom)
	_gliding = not instant
	_pivoting = false
	velocity = Vector2.ZERO
	if instant:
		zoom = _target_zoom
		center = _target_center


func is_moving() -> bool:
	return _gliding or _pivoting or velocity != Vector2.ZERO \
		or absf(zoom - _target_zoom) > 0.0005


func step(dt: float) -> void:
	var k: float = 1.0 - exp(-dt * GLIDE_RATE)
	if _pivoting:
		zoom = lerpf(zoom, _target_zoom, k)
		if absf(zoom - _target_zoom) < 0.0005:
			zoom = _target_zoom
			_pivoting = false
		center = clamp_center(_pivot_world - (_pivot_screen - viewport * 0.5) / zoom, zoom)
		_target_center = center
	elif _gliding:
		zoom = lerpf(zoom, _target_zoom, k)
		center = clamp_center(center.lerp(_target_center, k), zoom)
		if center.distance_to(_target_center) < 0.5 and absf(zoom - _target_zoom) < 0.0005:
			center = _target_center
			zoom = _target_zoom
			_gliding = false
	if velocity != Vector2.ZERO:
		var before: Vector2 = center
		center = clamp_center(center + velocity * dt, zoom)
		# Hitting the edge of the world stops the fling on that axis instead of
		# pressing against it for the rest of the decay.
		var moved: Vector2 = center - before
		for a in range(2):
			if absf(moved[a]) < absf(velocity[a] * dt) * 0.5:
				velocity[a] = 0.0
		velocity *= exp(-dt * FLING_DECAY)
		if velocity.length() * zoom < FLING_STOP:
			velocity = Vector2.ZERO
		_target_center = center


## What part of the world is on screen right now.
func visible_world() -> Rect2:
	return Rect2(screen_to_world(Vector2.ZERO), viewport / zoom)


## What part of the painting is on screen: always inside it.
func visible_bg() -> Rect2:
	var inv: Transform2D = bg_transform().affine_inverse()
	var a: Vector2 = inv * Vector2.ZERO
	var b: Vector2 = inv * viewport
	return Rect2(a, b - a)
