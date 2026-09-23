extends Node

## Every piece of store artwork, drawn by the game's own drawing code.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 tools/brand.tscn
##
## Google's specs, from support.google.com/googleplay/android-developer:
##   icon            512x512, 32-bit PNG with alpha, full square
##   feature graphic 1024x500, JPEG or 24-bit PNG with NO alpha
##
## Everything is rendered through a SubViewport rather than the window. The
## project stretches `canvas_items` from a 720x1440 base so the game fits every
## phone, which is right for the game and wrong here — it would scale a 512x512
## icon by whatever factor the window happened to imply. A SubViewport has its
## own size in real pixels and ignores the stretch.

const OUT := "user://brand"

const JOBS := [
	{"name": "icon-512", "w": 512, "h": 512, "kind": "icon", "alpha": false},
	{"name": "icon-192", "w": 192, "h": 192, "kind": "icon", "alpha": false},
	{"name": "icon-foreground-432", "w": 432, "h": 432, "kind": "adaptive",
		"alpha": true},
	{"name": "feature-1024x500", "w": 1024, "h": 500, "kind": "feature",
		"alpha": false},
]

var _vp: SubViewport
var _painter: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_vp = SubViewport.new()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_painter = (load("res://tools/brand_painter.gd") as GDScript).new()
	_painter.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp.add_child(_painter)
	_run()


func _run() -> void:
	for job: Dictionary in JOBS:
		var s := Vector2i(int(job["w"]), int(job["h"]))
		_vp.size = s
		_vp.transparent_bg = bool(job["alpha"])
		# Anchored full-rect inside the SubViewport, so its size follows the
		# viewport's; setting it directly is refused and warns.
		_painter.set("kind", String(job["kind"]))
		_painter.queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = _vp.get_texture().get_image()
		if not bool(job["alpha"]):
			# 24-bit, no alpha channel: what Play asks for, and what keeps the
			# icon from arriving with pre-rounded transparent corners.
			img.convert(Image.FORMAT_RGB8)
		var path: String = "%s/%s.png" % [OUT, String(job["name"])]
		img.save_png(path)
		print("  %s  %dx%d  %s" % [ProjectSettings.globalize_path(path),
			img.get_width(), img.get_height(),
			"rgba" if bool(job["alpha"]) else "rgb"])
	print("brand assets written to %s" % ProjectSettings.globalize_path(OUT))
	get_tree().quit()
