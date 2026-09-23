class_name Foreman
extends RefCounted

## The Foreman: a small robot, drawn out of the same blocks as the machines.
##
## The brief asked for a mascot and the previous art direction argued against
## one on the grounds that "the factory is the character". Both are right, and
## this is the resolution: the mascot IS a machine. It is built from
## `Palette.block()` and lit by the same key light as everything on the board,
## so it belongs to the factory rather than visiting it, and it costs nothing
## -- no texture, no import, no atlas, no drift between the version in the
## tutorial and the version in the shop.
##
## It is deliberately not on the gameplay screen. A mascot standing next to a
## board the player is trying to read is a mascot in the way. It appears at
## the four moments where the game is talking rather than being played: coming
## back from being away, unlocking something, the Codex, and the shop.
##
## Three poses, because a mascot with one pose is a sticker:
##
##   IDLE   arms down, visor level. The default.
##   POINT  one arm out, leaning. For "look at this".
##   CHEER  both arms up. For a reward.

enum Pose { IDLE, POINT, CHEER }

## Body colours. Steel plate and brass trim, the same family the machines use,
## with the visor in the game's own accent so the Foreman reads as "the thing
## that talks to you" rather than as a thirteenth machine.


static func _plate() -> Color:
	return Color("7d94ad")


static func _trim() -> Color:
	return Color("ffc663")


static func _visor() -> Color:
	return Palette.ACCENT


## Draw the Foreman inside `rect`, facing right. `phase` drives a slow idle
## bob and the antenna blink; nothing here is frame-dependent, so the same
## phase always draws the same picture.
static func draw_at(ci: CanvasItem, rect: Rect2, pose: int = Pose.IDLE,
		phase: float = 0.0) -> void:
	var u: float = minf(rect.size.x, rect.size.y)
	if u < 12.0:
		return
	var plate: Color = _plate()
	var trim: Color = _trim()
	var dark: Color = plate.lerp(Palette.BG, 0.40)
	var bob: float = sin(phase * TAU) * u * 0.012
	var o := Vector2(rect.position.x, rect.position.y + bob)

	# Everything below is in fractions of the shorter side, so the Foreman is
	# the same Foreman at forty pixels and at four hundred.
	var b := func(x: float, y: float, w: float, h: float, c: Color,
			lift: float = 0.14, rim: bool = true, contact: bool = false):
		Palette.block(ci, Rect2(o.x + u * x, o.y + u * y,
			maxf(u * w, 1.0), maxf(u * h, 1.0)), c, lift, rim, contact)

	# Feet and legs, planted wide.
	b.call(0.22, 0.82, 0.20, 0.15, dark, 0.10, true, true)
	b.call(0.58, 0.82, 0.20, 0.15, dark, 0.10, true, true)
	b.call(0.29, 0.64, 0.13, 0.20, plate, 0.08)
	b.call(0.58, 0.64, 0.13, 0.20, plate, 0.08)

	# Torso: broad shoulders under a chest plate with a lit core, because
	# everything in this world that works has a light in it.
	b.call(0.20, 0.36, 0.60, 0.30, plate, 0.16, true, true)
	b.call(0.20, 0.36, 0.60, 0.06, trim, 0.05, false)
	Palette.emissive(ci, Rect2(o.x + u * 0.41, o.y + u * 0.46,
		u * 0.18, u * 0.11), Palette.CORE, 0.9)

	# Arms, by pose.
	match pose:
		Pose.POINT:
			b.call(0.13, 0.40, 0.12, 0.22, plate, 0.08)
			b.call(0.76, 0.32, 0.20, 0.11, plate, 0.08)
			b.call(0.92, 0.30, 0.10, 0.10, trim, 0.06)
		Pose.CHEER:
			b.call(0.09, 0.22, 0.11, 0.22, plate, 0.08)
			b.call(0.80, 0.22, 0.11, 0.22, plate, 0.08)
			b.call(0.06, 0.13, 0.12, 0.11, trim, 0.06)
			b.call(0.82, 0.13, 0.12, 0.11, trim, 0.06)
		_:
			b.call(0.13, 0.40, 0.11, 0.25, plate, 0.08)
			b.call(0.76, 0.40, 0.11, 0.25, plate, 0.08)

	# Head: a helmet brim over a wide visor. The brim is the silhouette -- a
	# hard hat is the one shape that says "this one is in charge of a mine"
	# without a single word.
	b.call(0.31, 0.14, 0.38, 0.22, plate, 0.13, true, true)
	# The dome, then the brim over it. A hard hat is the one shape that says
	# "this one is in charge of a mine" without a single word.
	b.call(0.36, 0.07, 0.28, 0.07, trim, 0.06)
	b.call(0.24, 0.12, 0.52, 0.06, trim, 0.05)
	Palette.emissive(ci, Rect2(o.x + u * 0.35, o.y + u * 0.21,
		u * 0.30, u * 0.09), _visor(), 1.0)

	# Antenna, with a light that blinks on its own clock.
	b.call(0.485, 0.00, 0.035, 0.08, dark, 0.0, false)
	var blink: float = 0.35 + 0.65 * maxf(sin(phase * TAU * 2.0), 0.0)
	Palette.emissive(ci, Rect2(o.x + u * 0.46, o.y - u * 0.03,
		u * 0.08, u * 0.045), Palette.GOOD, blink)


## A Control that draws the Foreman and animates him, for dropping into a
## panel. Ignores the mouse, so he can never eat a tap meant for a button.
class Badge extends Control:
	var pose: int = Foreman.Pose.IDLE
	var _t: float = 0.0

	func _init(p: int = Foreman.Pose.IDLE, px: float = 96.0) -> void:
		pose = p
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta * 0.45
		queue_redraw()

	func _draw() -> void:
		var u: float = minf(size.x, size.y)
		Foreman.draw_at(self, Rect2((size - Vector2(u, u)) * 0.5,
			Vector2(u, u)), pose, _t)
