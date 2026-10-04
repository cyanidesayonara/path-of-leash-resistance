extends SceneTree

# A style test for the intro: Millie mid-yank, side on, in the two looks the
# intro could take ("clay" and "ink"), side by side, with their backgrounds.
# Rendered at 2x and scaled down so polygon edges are smooth.
#   godot --rendering-method gl_compatibility --path . --script res://tools/intro_style.gd -- out.png

const SS := 2
const W := 1920
const H := 720


class StylePanel:
	extends Node2D
	var style := "clay"
	var rect := Rect2()

	func _draw() -> void:
		var r := rect
		var cx := r.position.x + r.size.x * 0.5
		var ground := r.position.y + r.size.y * 0.72
		if style != "ink":
			# warm soft sky, a hill with a lit crest, a soft sun
			for i in range(12):
				var f := float(i) / 11.0
				draw_rect(Rect2(r.position.x, r.position.y + r.size.y * f, r.size.x, r.size.y / 11.0 + 1.0),
					Color(0.98, 0.90, 0.74).lerp(Color(0.86, 0.92, 0.94), 1.0 - f))
			draw_circle(Vector2(r.position.x + r.size.x * 0.8, r.position.y + r.size.y * 0.2), 70.0 * SS, Color(1.0, 0.95, 0.80, 0.5))
			var hill := MillieSide.ellipse(Vector2(cx, ground + 260.0 * SS), Vector2(r.size.x * 0.9, 300.0 * SS))
			draw_colored_polygon(hill, Color(0.42, 0.58, 0.34))
			draw_colored_polygon(MillieSide.ellipse(Vector2(cx - 60.0 * SS, ground + 250.0 * SS), Vector2(r.size.x * 0.75, 270.0 * SS)), Color(0.50, 0.66, 0.40))
		else:
			# flat colour fields and a bold horizon line
			draw_rect(r, Color(0.99, 0.84, 0.46))
			draw_circle(Vector2(r.position.x + r.size.x * 0.8, r.position.y + r.size.y * 0.2), 64.0 * SS, Color(1.0, 0.97, 0.80))
			draw_rect(Rect2(r.position.x, ground - 6.0 * SS, r.size.x, r.end.y - ground + 6.0 * SS), Color(0.40, 0.70, 0.36))
			draw_line(Vector2(r.position.x, ground - 6.0 * SS), Vector2(r.end.x, ground - 6.0 * SS), MillieSide.INK, 5.0 * SS)
		var pose := {"lean": 0.16, "crouch": 0.5, "reach": 0.7, "push": 0.6, "head_up": -0.08,
			"ear": 0.7, "tail": 0.35, "mouth": 0.8, "brow": 1.0}
		var o := Vector2(cx + 30.0 * SS, ground)
		var s := 1.9 * SS
		# the leash first, back to someone off to the left and up, taut
		var ring: Vector2 = MillieSide.parts(pose)["_neck"] + Vector2(-8, 6)
		var rp := o + ring * s
		var far := Vector2(r.position.x - 20.0, r.position.y + r.size.y * 0.18)
		if style == "ink":
			draw_line(rp, far, MillieSide.INK, 10.0 * SS)
		draw_line(rp, far, Color(0.62, 0.18, 0.20), 5.0 * SS)
		# the twang: lines either side of the taut leash
		var d := (far - rp).normalized()
		var n := d.orthogonal()
		for k in range(3):
			var mid := rp.lerp(far, 0.35 + float(k) * 0.12)
			var off := (8.0 + float(k) * 4.0) * SS
			var lc := MillieSide.INK if style == "ink" else Color(1, 1, 1, 0.7)
			draw_line(mid + n * off - d * 10.0 * SS, mid + n * off + d * 10.0 * SS, lc, 2.0 * SS)
			draw_line(mid - n * off - d * 10.0 * SS, mid - n * off + d * 10.0 * SS, lc, 2.0 * SS)
		MillieSide.draw(self, o, s, pose, style)
		# dust kicked up behind her back feet
		for k in range(4):
			var dp := o + Vector2(-90.0 - float(k) * 20.0, -8.0 - float(k % 2) * 10.0) * s / 2.2
			var dc := Color(0.96, 0.92, 0.82) if style == "ink" else Color(0.80, 0.72, 0.58, 0.6)
			if style == "ink":
				draw_circle(dp, (11.0 - float(k) * 2.0) * SS + 3.0 * SS, MillieSide.INK)
			draw_circle(dp, (11.0 - float(k) * 2.0) * SS, dc)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(r.position.x + 24.0 * SS, r.end.y - 24.0 * SS), {"clay": "1  clay lighting", "hybrid": "2  clay with a soft outline", "ink": "3  ink and flat colour"}[style],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22 * SS, Color(0.15, 0.12, 0.10))


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# one viewport per panel, so nothing drawn for one look spills into the next
	var out_img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var pw := W / 3
	var styles := ["clay", "hybrid", "ink"]
	for i in range(3):
		var vp := SubViewport.new()
		vp.size = Vector2i(pw * SS, H * SS)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vp)
		var p := StylePanel.new()
		p.style = styles[i]
		p.rect = Rect2(0.0, 0.0, float(pw * SS), float(H * SS))
		vp.add_child(p)
		for k in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(pw, H, Image.INTERPOLATE_LANCZOS)
		out_img.blit_rect(img, Rect2i(0, 0, pw, H), Vector2i(i * pw, 0))
		vp.queue_free()
	var args := OS.get_cmdline_user_args()
	var out := "user://intro_style.png" if args.is_empty() else args[0]
	out_img.save_png(out)
	print("intro_style: " + out)
	quit(0)
