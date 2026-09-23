extends Node

## Can you still tell the machines apart?
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 tools/readability.tscn
##   python3 tools/check-readability.py ~/.local/share/godot/app_userdata/Lodeworks/readability
##
## A visual pass can make a game prettier and less playable at the same time,
## and screenshots do not catch it because the person looking at them already
## knows which machine is which. This renders every machine at the size it is
## actually played at and writes the strip out for `tools/check-readability.py`
## to compare pair by pair -- in colour and again desaturated, because a board
## that only works for people with normal colour vision is a board that does
## not work.
##
## Rendered through a SubViewport with its own pixel size, because the project
## stretches `canvas_items` from a 720x1440 base and would otherwise scale the
## strip by whatever the window happened to imply.

const OUT := "user://readability"
## A 7-wide board on a 360dp phone gives about 44 logical pixels a cell, so
## that is the floor. 96 is a large modern phone. The check that matters is
## the small one.
const SIZES := [44, 64, 96]

var _vp: SubViewport
var _strip: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_vp = SubViewport.new()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_strip = _Strip.new()
	_strip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp.add_child(_strip)
	await _run()


func _run() -> void:
	for px: int in SIZES:
		_vp.size = Vector2i(px * MachineDB.ORDER.size(), px)
		_strip.set("cell", float(px))
		_strip.queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.save_png("%s/strip_%d.png" % [OUT, px])
		print("   %d px strip" % px)
	print("readability strips written to %s"
		% ProjectSettings.globalize_path(OUT))
	get_tree().quit(0)


## Greyscale is done by `tools/check-readability.py` on the written file rather
## than here: desaturating the real frame is exactly what a player with no
## colour discrimination sees, and painting a grey wash over the top is not the
## same thing.
class _Strip extends Control:
	var cell: float = 96.0

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, size), Palette.BG, true)
		for i in range(MachineDB.ORDER.size()):
			var id: String = String(MachineDB.ORDER[i])
			MachineArt.tile(self, Rect2(float(i) * cell, 0.0, cell, cell),
				id, font, 1.2, {"glow": 1.0, "tier": 1})
