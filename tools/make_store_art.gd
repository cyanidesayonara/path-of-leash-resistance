extends SceneTree

# Generates the Microsoft Store listing art from the same drawing as the icon.
#
#   godot --rendering-method gl_compatibility --path . --script res://tools/make_store_art.gd
# Options after a "--": --eyes=dog|googly, as for tools/make_icon.gd.
#
# Writes into build/store-art/ (gitignored):
#   poster-1440x2160.png   9:16 poster art, the main Store logo, with the title
#   boxart-2160.png        1:1 box art, the icon full bleed
#   tile-300.png, tile-150.png, tile-71.png   Store display images
#
# Reuses tools/make_icon.gd's IconCanvas so the Store and the taskbar show one
# dog. Drawn at 2x and downsampled for the same reason the icon is: Godot's 2D
# polygons are not antialiased.
#
# The title is the game's own heavy face (hud/ui_kit.gd's display(): the
# built-in font, emboldened), set harder here because it is a logo: stacked,
# each line fitted to one measure, LEASH the biggest word and in the leash's
# colour, and tilted up toward the pull like everything else in the picture.

const OUT_DIR := "res://build/store-art"
const SS := 2
const IconScript := preload("res://tools/make_icon.gd")

const CREAM := Color(1.0, 0.97, 0.88)
const INK := Color(0.27, 0.15, 0.09)
const SHADOW := Color(0.45, 0.25, 0.14)


class PosterCanvas:
	extends IconScript.IconCanvas

	var size_px := Vector2(1440.0, 2160.0)
	var icon_px := 1340.0
	var icon_at := Vector2.ZERO

	# the display face at a weight and a letter spacing, both in proportion to
	# the size it is set at
	func _face(px: int, track: float) -> FontVariation:
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 1.1
		f.set_spacing(TextServer.SPACING_GLYPH, int(round(px * track)))
		return f

	# the font size at which a line spans exactly `measure` pixels
	func _fit(text: String, measure: float, track: float) -> int:
		var probe := 200
		var w := _face(probe, track).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, probe).x
		# glyph spacing also follows the last letter; take it back off
		w -= probe * track
		return int(floor(probe * measure / w))

	func _line(text: String, centre_x: float, baseline: float, px: int, track: float,
			fill: Color) -> void:
		var f := _face(px, track)
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x - px * track
		var p := Vector2(centre_x - w * 0.5, baseline)
		# a hard drop shadow, then a fat cream keyline, then the letters: a
		# sticker, so it reads on the sky at any size the Store shows it
		var sh := Vector2(0.0, px * 0.07)
		draw_string_outline(f, p + sh, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			int(px * 0.22), SHADOW)
		draw_string(f, p + sh, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, SHADOW)
		draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, int(px * 0.20), CREAM)
		draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, fill)

	func _draw() -> void:
		paint_sky_glow(Rect2(Vector2.ZERO, size_px), Vector2(size_px.x * 0.27, size_px.y * 0.36),
			Vector2(size_px.x * 0.9, size_px.y * 0.6))
		# the dog first, on the bottom edge with her shoulders running off it
		# (the icon's own crop); the title goes over everything, the leash
		# included, which runs up behind it and out of the top
		var k := icon_px / 256.0
		draw_set_transform(icon_at)
		s = k
		paint_sky = false
		leash_reach = size_px.y / k
		super._draw()

		# the title alone: no subtitle, no tagline
		var measure := size_px.x * 0.80
		var cx := size_px.x * 0.5
		var top := size_px.y * 0.075
		draw_set_transform(Vector2(cx, top + measure * 0.35), -0.05)
		var small_track := 0.30
		var big_track := 0.04
		var fs_path := int(_fit("PATH OF", measure * 0.62, small_track))
		var fs_leash := mini(_fit("LEASH", measure, big_track), int(measure * 0.30))
		var fs_res := _fit("RESISTANCE", measure, big_track)
		var y := -measure * 0.35 + fs_path * 0.9
		_line("PATH OF", 0.0, y, fs_path, small_track, INK)
		y += fs_leash * 0.98
		_line("LEASH", 0.0, y, fs_leash, big_track, LEASH)
		y += fs_res * 1.12
		_line("RESISTANCE", 0.0, y, fs_res, big_track, INK)
		draw_set_transform(Vector2.ZERO)


func _initialize() -> void:
	call_deferred("_run")


func _render(canvas: Node2D, px: Vector2i) -> Image:
	var vp := SubViewport.new()
	vp.size = px * SS
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	vp.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	img.resize(px.x, px.y, Image.INTERPOLATE_LANCZOS)
	vp.queue_free()
	return img


func _save(img: Image, name: String) -> bool:
	var path := OUT_DIR.path_join(name)
	var err := img.save_png(path)
	print("store art: %s (%dx%d) err=%d" % [path, img.get_width(), img.get_height(), err])
	return err == OK


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# keep the editor from importing the output as game resources
	FileAccess.open(OUT_DIR.path_join(".gdignore"), FileAccess.WRITE).close()
	var ok := true
	var eyes := IconScript.eye_style_arg()

	var poster := PosterCanvas.new()
	poster.eye_style = eyes
	poster.size_px = Vector2(1440.0, 2160.0) * SS
	# wider than the poster, so her shoulders and the hill bleed off both sides
	poster.icon_px = 1560.0 * SS
	poster.icon_at = Vector2((poster.size_px.x - poster.icon_px) * 0.5,
		poster.size_px.y - poster.icon_px * 0.98)
	ok = _save(await _render(poster, Vector2i(1440, 2160)), "poster-1440x2160.png") and ok

	var box := IconScript.IconCanvas.new()
	box.eye_style = eyes
	box.s = 2160.0 * SS / 256.0
	var box_img: Image = await _render(box, Vector2i(2160, 2160))
	ok = _save(box_img, "boxart-2160.png") and ok
	for px: int in [300, 150, 71]:
		var t := box_img.duplicate() as Image
		t.resize(px, px, Image.INTERPOLATE_LANCZOS)
		ok = _save(t, "tile-%d.png" % px) and ok

	quit(0 if ok else 1)
