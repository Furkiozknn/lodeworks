class_name MachineArt
extends RefCounted

## How a machine is drawn, in one place, so that everything that draws one
## draws the same one.
##
## The board, the palette buttons, the app icon, the feature graphic and the
## store screenshots all call this. That is the whole asset pipeline: a new
## machine gets a row in `MachineDB`, a colour and a family in `Palette`, and
## every surface that shows machines picks it up without anyone exporting,
## resizing or re-cutting anything. It is also why the marketing art cannot
## drift away from the game — there is no separate marketing art.
##
## Everything is rectangles. Godot's compatibility renderer batches rect draws
## and treats every circle, arc and thick line as a polygon that breaks the
## batch, and a board of seventy tiles cannot afford seventy broken batches.

## Draw the machine body into `rect`. `scale_ref` is the size the proportions
## are relative to — the cell size on the board, the icon size on the icon.
static func silhouette(ci: CanvasItem, rect: Rect2, scale_ref: float,
		family: int, body: Color, highlight: float = 0.0) -> void:
	var inner: Rect2 = rect.grow(-scale_ref * 0.045)
	var trim: Color = body.lerp(Palette.BG, 0.45)
	match family:
		Palette.Family.RIG:
			# Heavy base, narrow head: it goes down into the rock.
			ci.draw_rect(Rect2(inner.position.x,
				inner.position.y + inner.size.y * 0.30,
				inner.size.x, inner.size.y * 0.70), body, true)
			ci.draw_rect(Rect2(inner.position.x + inner.size.x * 0.26,
				inner.position.y, inner.size.x * 0.48, inner.size.y * 0.34),
				body, true)
		Palette.Family.MILL:
			# Squat body with a lid band across the top.
			ci.draw_rect(inner, body, true)
			ci.draw_rect(Rect2(inner.position.x, inner.position.y,
				inner.size.x, inner.size.y * 0.16), trim, true)
		Palette.Family.FURNACE:
			# Body plus a chimney block offset to one side.
			ci.draw_rect(Rect2(inner.position.x,
				inner.position.y + inner.size.y * 0.18,
				inner.size.x, inner.size.y * 0.82), body, true)
			ci.draw_rect(Rect2(inner.position.x + inner.size.x * 0.58,
				inner.position.y, inner.size.x * 0.28, inner.size.y * 0.26),
				body, true)
		Palette.Family.STORE:
			# Double-walled box: it holds things.
			ci.draw_rect(inner, body, true)
			ci.draw_rect(inner.grow(-scale_ref * 0.09), trim, true)
			ci.draw_rect(inner.grow(-scale_ref * 0.14), body, true)
		Palette.Family.LAB:
			# Narrow tower on a plinth.
			ci.draw_rect(Rect2(inner.position.x + inner.size.x * 0.18,
				inner.position.y, inner.size.x * 0.64, inner.size.y * 0.80),
				body, true)
			ci.draw_rect(Rect2(inner.position.x,
				inner.position.y + inner.size.y * 0.78,
				inner.size.x, inner.size.y * 0.22), trim, true)
		_:
			# FIELD: body with fins on both sides — it reaches outwards.
			ci.draw_rect(Rect2(inner.position.x + inner.size.x * 0.16,
				inner.position.y, inner.size.x * 0.68, inner.size.y), body, true)
			var fin: float = inner.size.y * 0.42
			ci.draw_rect(Rect2(inner.position.x,
				inner.position.y + fin * 0.6,
				inner.size.x * 0.13, fin), trim, true)
			ci.draw_rect(Rect2(inner.position.x + inner.size.x * 0.87,
				inner.position.y + fin * 0.6, inner.size.x * 0.13, fin), trim, true)
	if highlight > 0.01:
		var glow: Color = Color.WHITE
		glow.a = highlight * 0.20
		ci.draw_rect(inner, glow, true)


## The full tile: heat wash, body, glyph and output chip. Used by the icon and
## the feature graphic so promotional art is literally the same drawing code
## as the board.
static func tile(ci: CanvasItem, rect: Rect2, id: String, font: Font,
		heat: float = 0.0) -> void:
	var cs: float = minf(rect.size.x, rect.size.y)
	ci.draw_rect(rect, Palette.CELL.lerp(Palette.heat_color(heat), 0.62), true)
	ci.draw_rect(rect, Palette.LINE, false, maxf(cs * 0.012, 1.0))
	var body: Color = Palette.machine_color(id)
	body.a = 0.96
	silhouette(ci, rect, cs, Palette.family_of(id), body)
	var glyph: String = Palette.machine_glyph(id)
	var gs: int = int(cs * 0.40)
	var ts: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gs)
	ci.draw_string(font, rect.position + Vector2((rect.size.x - ts.x) * 0.5,
		(rect.size.y + ts.y * 0.62) * 0.5), glyph,
		HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Palette.BG)
	var res: int = Palette.output_res(id)
	if res >= 0:
		var chip: float = cs * 0.13
		ci.draw_rect(Rect2(rect.position + Vector2(cs * 0.06, cs * 0.06),
			Vector2(chip, chip)), Palette.res_color(res), true)
