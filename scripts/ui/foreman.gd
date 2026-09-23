class_name Foreman
extends RefCounted

## The Foreman: a young miner in a hard hat, the one person in the shaft.
##
## He is never on the board. He stands at the edge of the screen, in the
## world's margin rather than over the factory, and he only appears when the
## game has something to say -- the first chapter of the tutorial, a machine
## unlocked, a new stratum, a problem worth walking over to, coming back from
## being away. Otherwise the factory is left to speak for itself.
##
## Five poses from one generated sheet (`assets/art/foreman/poses.webp`, see
## art_src/SOURCES.md), so the Foreman in the tutorial, the shop and the
## Codex is always the same character:
##
##   IDLE    standing with his clipboard. The default.
##   POINT   one arm out. "Look at this."
##   CHEER   thumbs up. A reward.
##   JUMP    both fists up. A new stratum, a big unlock.
##   ALERT   leaning back, hands up. Something is wrong.

enum Pose { IDLE, POINT, CHEER, JUMP, ALERT }


static func _sheet() -> Dictionary:
	return IsoArt.layout().get("foreman", {})


## Draw the Foreman inside `rect`, feet on its bottom edge, centred.
## `phase` drives a slow idle bob; the same phase always draws the same
## picture. Off-tree, or with the sheet missing, it draws nothing rather than
## failing.
static func draw_at(ci: CanvasItem, rect: Rect2, pose: int = Pose.IDLE,
		phase: float = 0.0) -> void:
	var info: Dictionary = _sheet()
	var tex: Texture2D = IsoArt.texture(String(info.get("file", "")))
	if tex == null or rect.size.y < 8.0:
		return
	var cell: Array = info.get("cell", [252, 420])
	var cw: float = float(cell[0])
	var ch: float = float(cell[1])
	var k: int = clampi(pose, 0, Pose.size() - 1)
	var s: float = minf(rect.size.x / cw, rect.size.y / ch)
	var bob: float = sin(phase * TAU) * rect.size.y * 0.012
	var size := Vector2(cw, ch) * s
	var pos := Vector2(rect.position.x + (rect.size.x - size.x) * 0.5,
		rect.position.y + rect.size.y - size.y + bob)
	ci.draw_texture_rect_region(tex, Rect2(pos, size),
		Rect2(float(k) * cw, 0.0, cw, ch))


## A Control that draws the Foreman and animates him, for dropping into a
## panel. Ignores the mouse, so he can never eat a tap meant for a button.
class Badge extends Control:
	var pose: int = Foreman.Pose.IDLE
	var _t: float = 0.0

	func _init(p: int = Foreman.Pose.IDLE, px: float = 96.0) -> void:
		pose = p
		custom_minimum_size = Vector2(px * 0.62, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _process(delta: float) -> void:
		_t += delta * 0.45
		queue_redraw()

	func _draw() -> void:
		Foreman.draw_at(self, Rect2(Vector2.ZERO, size), pose, _t)
