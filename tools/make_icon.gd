extends SceneTree

# Generates icon.png - the window, taskbar and itch-app icon.
#
# Run it, do not hand-edit the output:
#   godot --rendering-method gl_compatibility --path . --script res://tools/make_icon.gd
#
# The in-game Millie renderer (dog.gd) is not reusable here: it draws from a
# live CharacterBody2D with a gait, a coat lookup and a leash attached to it.
# An icon wants bolder shapes than a sprite seen at 1:1 anyway, so this
# composes the same silhouette - black dog, pink collar, taut leash - out of
# the game's own palette. Drawn at 4x and downsampled, because Godot's 2D
# polygons are not antialiased and a 256px icon with stair-stepped ears looks
# like a 2010 browser game, which is the exact thing we are climbing out of.

const OUT := "res://icon.png"
const SS := 4          # supersample factor
const SIZE := 256

class IconCanvas:
	extends Node2D

	const GRASS := Color(0.16, 0.28, 0.21)
	const GRASS_LIT := Color(0.22, 0.36, 0.27)
	const FUR := Color(0.13, 0.13, 0.15)
	const FUR_LIT := Color(0.21, 0.21, 0.24)
	const COLLAR := Color(0.93, 0.35, 0.55)
	const LEASH := Color(0.62, 0.26, 0.24)
	const NOSE := Color(0.08, 0.08, 0.09)
	const EAR := Color(0.18, 0.17, 0.19)
	const MUZZLE := Color(0.26, 0.24, 0.25)

	var s := 1.0        # everything is authored against a 256 unit square

	func _ellipse(c: Vector2, r: Vector2, col: Color, rot := 0.0) -> void:
		var pts := PackedVector2Array()
		for i in range(28):
			var a := TAU * float(i) / 28.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
		draw_colored_polygon(pts, col)

	func _draw() -> void:
		var f := func(v: Vector2) -> Vector2: return v * s
		# full bleed; _run() masks the rounded corners back in afterwards, which
		# means the lighting can spill past the edges without leaving square
		# corners behind
		draw_rect(Rect2(Vector2.ZERO, Vector2(256.0, 256.0) * s), GRASS)
		# light from the upper left, the same direction every shadow in the
		# game falls away from
		for i in range(10):
			var k := float(i) / 9.0
			_ellipse(f.call(Vector2(74.0, 58.0)), Vector2(210.0 - k * 150.0, 190.0 - k * 140.0) * s,
				Color(GRASS_LIT.r, GRASS_LIT.g, GRASS_LIT.b, 0.10))

		# --- the leash, from the ring up out of frame ---
		# It is what the game is named after, so it earns the diagonal. Drawn
		# before the head so it tucks behind her cheek.
		var ring := Vector2(176.0, 196.0)
		draw_line(f.call(ring), f.call(Vector2(250.0, 6.0)), LEASH, 9.0 * s)

		# --- Millie, head on. A top-down pose is what the game shows, but at
		# 32px it reads as a dark smudge; a face reads as a dog. ---
		var head := Vector2(122.0, 116.0)
		# ears first, so they sit behind the skull
		for sgn: float in [-1.0, 1.0]:
			var root_p: Vector2 = head + Vector2(58.0 * sgn, -26.0)
			var ear := PackedVector2Array([
				f.call(root_p + Vector2(-16.0 * sgn, 12.0)),
				f.call(root_p + Vector2(12.0 * sgn, -22.0)),
				f.call(root_p + Vector2(30.0 * sgn, 46.0)),
				f.call(root_p + Vector2(8.0 * sgn, 50.0)),
			])
			draw_colored_polygon(ear, EAR)
		# the skull: a wide dome over a slightly narrower jaw
		_ellipse(f.call(head), Vector2(66.0, 58.0) * s, FUR)
		_ellipse(f.call(head + Vector2(0.0, 30.0)), Vector2(54.0, 46.0) * s, FUR)
		# a sheen across the forehead, so black fur has a form
		_ellipse(f.call(head + Vector2(-16.0, -26.0)), Vector2(30.0, 15.0) * s,
			Color(FUR_LIT.r, FUR_LIT.g, FUR_LIT.b, 0.5))
		# muzzle, nose, mouth
		_ellipse(f.call(head + Vector2(0.0, 44.0)), Vector2(33.0, 25.0) * s, MUZZLE)
		_ellipse(f.call(head + Vector2(0.0, 32.0)), Vector2(13.0, 10.0) * s, NOSE)
		draw_line(f.call(head + Vector2(0.0, 42.0)), f.call(head + Vector2(0.0, 52.0)),
			NOSE, 3.0 * s)
		for sgn2: float in [-1.0, 1.0]:
			draw_arc(f.call(head + Vector2(13.0 * sgn2, 52.0)), 13.0 * s,
				PI * (1.15 if sgn2 > 0.0 else 1.55), PI * (1.85 if sgn2 > 0.0 else 2.25),
				10, NOSE, 3.0 * s)
		# eyes: wide-set, with a catchlight. This is the whole trick.
		for sgn3: float in [-1.0, 1.0]:
			var eye: Vector2 = head + Vector2(29.0 * sgn3, -6.0)
			_ellipse(f.call(eye), Vector2(15.0, 16.0) * s, Color(0.97, 0.96, 0.93))
			_ellipse(f.call(eye + Vector2(1.5 * sgn3, 2.0)), Vector2(8.0, 9.0) * s,
				Color(0.09, 0.08, 0.09))
			draw_circle(f.call(eye + Vector2(-3.0, -4.0)), 2.8 * s, Color(1, 1, 1, 0.9))
		# brows: two small light dashes, and she is suddenly A Dog With A Plan
		for sgn4: float in [-1.0, 1.0]:
			draw_line(f.call(head + Vector2(20.0 * sgn4, -28.0)),
				f.call(head + Vector2(38.0 * sgn4, -24.0)),
				Color(MUZZLE.r, MUZZLE.g, MUZZLE.b, 0.75), 4.0 * s)

		# --- the collar, across the chest, with the ring the leash pulls on ---
		var chest := Vector2(122.0, 200.0)
		# shoulders, running off the bottom edge, so she is a dog and not a
		# head balanced on a lump
		_ellipse(f.call(chest + Vector2(0.0, 44.0)), Vector2(86.0, 52.0) * s, FUR)
		draw_line(f.call(chest + Vector2(-58.0, -6.0)), f.call(chest + Vector2(58.0, 2.0)),
			COLLAR, 17.0 * s)
		draw_circle(f.call(ring), 9.0 * s, Color(0.85, 0.85, 0.88))
		draw_circle(f.call(ring), 4.5 * s, GRASS)


func _round_corners(img: Image, r: float) -> void:
	# Done to the pixels rather than by drawing a rounded box, so the canvas
	# above can light the whole square and spill over the edge freely.
	var n := float(SIZE)
	img.convert(Image.FORMAT_RGBA8)
	for y in range(SIZE):
		for x in range(SIZE):
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var cx: float = clampf(px, r, n - r)
			var cy: float = clampf(py, r, n - r)
			var d := Vector2(px - cx, py - cy).length()
			if d <= 0.0:
				continue
			# one pixel of feather, so the curve is not a staircase
			var a: float = clampf(r + 0.5 - d, 0.0, 1.0)
			var col := img.get_pixel(x, y)
			col.a *= a
			img.set_pixel(x, y, col)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE * SS, SIZE * SS)
	vp.transparent_bg = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	var canvas := IconCanvas.new()
	canvas.s = float(SS)
	vp.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	_round_corners(img, 30.0)
	var err := img.save_png(OUT)
	print("icon: %s (%dx%d) err=%d" % [OUT, img.get_width(), img.get_height(), err])
	quit(0 if err == OK else 1)
