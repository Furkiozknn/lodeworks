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
## The machines are the board's sprites, drawn from the same sheets and at
## the sizes a cell actually reaches on a phone: 44 px is a 720p phone at the
## furthest zoom, 110 px a 1080p phone at the default one. Two sheets are
## checked: the free palette, and Slate -- the grey plant, which is the one
## most likely to turn two machines into the same picture.
##
## Rendered through a SubViewport with its own pixel size, because the project
## stretches `canvas_items` from a 1440x720 base and would otherwise scale the
## strip by whatever the window happened to imply.

const OUT := "user://readability"
const SIZES := [44, 72, 110]
const SHEETS := ["shaft", "slate"]

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
	for sheet: String in SHEETS:
		for px: int in SIZES:
			_vp.size = Vector2i(px * MachineDB.ORDER.size(), px)
			_strip.set("cell", float(px))
			_strip.set("sheet", sheet)
			_strip.queue_redraw()
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img: Image = _vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			img.save_png("%s/strip_%s_%d.png" % [OUT, sheet, px])
			print("   %s %d px strip" % [sheet, px])
	print("readability strips written to %s"
		% ProjectSettings.globalize_path(OUT))
	get_tree().quit(0)


## Greyscale is done by `tools/check-readability.py` on the written file rather
## than here: desaturating the real frame is exactly what a player with no
## colour discrimination sees, and painting a grey wash over the top is not the
## same thing.
class _Strip extends Control:
	var cell: float = 96.0
	var sheet: String = "shaft"

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _draw() -> void:
		# The floor colour the machines stand on, not the UI background.
		draw_rect(Rect2(Vector2.ZERO, size), Color("7a6656"), true)
		var info: Dictionary = IsoArt.sheet(sheet)
		for i in range(MachineDB.ORDER.size()):
			var id: String = String(MachineDB.ORDER[i])
			IsoArt.draw_machine_fit(self, Rect2(float(i) * cell, 0.0, cell, cell), id, info)
