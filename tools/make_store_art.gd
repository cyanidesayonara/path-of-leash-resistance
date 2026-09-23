extends SceneTree

# Generates the Microsoft Store listing art from the same drawing as the icon.
#
#   godot --rendering-method gl_compatibility --path . --script res://tools/make_store_art.gd
#
# Writes into build/store-art/ (gitignored):
#   poster-1440x2160.png   9:16 poster art, the main Store logo, with the title
#   boxart-2160.png        1:1 box art, the icon full bleed
#   tile-300.png, tile-150.png, tile-71.png   Store display images
#
# Reuses tools/make_icon.gd's IconCanvas so the Store and the taskbar show one
# dog. Drawn at 2x and downsampled for the same reason the icon is: Godot's 2D
# polygons are not antialiased. Text is ThemeDB.fallback_font, which is what
# every label in the game uses.

const OUT_DIR := "res://build/store-art"
const SS := 2
const IconScript := preload("res://tools/make_icon.gd")

const CREAM := Color(0.96, 0.93, 0.84)


class PosterCanvas:
	extends IconScript.IconCanvas

	var size_px := Vector2(1440.0, 2160.0)
	var icon_px := 1340.0
	var icon_at := Vector2.ZERO

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size_px), GRASS)
		# the dog first, sitting on the bottom edge with her shoulders running
		# off it (the icon's own crop); everything else goes on top, so neither
		# the icon's light nor its square background can cover the title or
		# the leash
		var k := icon_px / 256.0
		draw_set_transform(icon_at)
		s = k
		super._draw()
		draw_set_transform(Vector2.ZERO)
		# the icon's leash leaves its top-right corner; carry it on past the
		# poster's edge along the same line, overlapping the icon's stroke
		var d := Vector2(74.0, -190.0).normalized()
		var a := icon_at + Vector2(250.0, 6.0) * k - d * 20.0 * k
		draw_line(a, a + d * size_px.y, LEASH, 9.0 * k)
		var f := ThemeDB.fallback_font
		var lines := ["PATH OF", "LEASH", "RESISTANCE"]
		var fs := int(size_px.x * 0.125)
		var y := size_px.y * 0.115
		for line in lines:
			var w := f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var p := Vector2((size_px.x - w) * 0.5, y)
			draw_string(f, p + Vector2(0.0, fs * 0.05), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(0, 0, 0, 0.35))
			draw_string(f, p, line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CREAM)
			y += fs * 1.02
		var tag := "you are the dog"
		var ts := int(fs * 0.36)
		var tw := f.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		draw_string(f, Vector2((size_px.x - tw) * 0.5, y + ts * 0.3), tag,
			HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color(CREAM.r, CREAM.g, CREAM.b, 0.8))


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

	var poster := PosterCanvas.new()
	poster.size_px = Vector2(1440.0, 2160.0) * SS
	poster.icon_px = 1340.0 * SS
	poster.icon_at = Vector2((poster.size_px.x - poster.icon_px) * 0.5, poster.size_px.y - poster.icon_px)
	ok = _save(await _render(poster, Vector2i(1440, 2160)), "poster-1440x2160.png") and ok

	var box := IconScript.IconCanvas.new()
	box.s = 2160.0 * SS / 256.0
	var box_img: Image = await _render(box, Vector2i(2160, 2160))
	ok = _save(box_img, "boxart-2160.png") and ok
	for px: int in [300, 150, 71]:
		var t := box_img.duplicate() as Image
		t.resize(px, px, Image.INTERPOLATE_LANCZOS)
		ok = _save(t, "tile-%d.png" % px) and ok

	quit(0 if ok else 1)
