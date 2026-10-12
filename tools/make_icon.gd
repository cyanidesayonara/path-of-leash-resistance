extends SceneTree

# Generates icon.png - the window, taskbar and itch-app icon.
#
# Run it, do not hand-edit the output:
#   godot --rendering-method gl_compatibility --path . --script res://tools/make_icon.gd
# Options after a "--": --eyes=dog|googly overrides EYE_STYLE, --out=PATH
# writes somewhere other than icon.png (for comparing the two).
#
# The in-game Millie renderer (dog.gd) is not reusable here: it draws from a
# live CharacterBody2D with a gait, a coat lookup and a leash attached to it.
# An icon wants bolder shapes than a sprite seen at 1:1 anyway, so this
# composes the same dog - black with salt and pepper, pink collar, taut
# leash - out of the game's own palette. Drawn at 4x and downsampled, because
# Godot's 2D polygons are not antialiased.
#
# What has to survive at 32px and 16px: a dark head shape with two ears on
# top, a light grey muzzle with a black nose in it, two catchlights, the pink
# collar and the leash's diagonal. Everything else is for 256px and up.

const OUT := "res://icon.png"
const SS := 4          # supersample factor
const SIZE := 256
# "dog": dark brown irises filling the eye, a catchlight, a sliver of white
# as she side-eyes the leash. "googly": the old cartoon whites, refined.
const EYE_STYLE := "dog"


# --eyes=dog|googly after a "--" on the command line, else EYE_STYLE
static func eye_style_arg() -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--eyes="):
			return a.trim_prefix("--eyes=")
	return EYE_STYLE


class IconCanvas:
	extends Node2D

	# a warm, light sky and a green hill: a dark dog reads on it at 16px
	const SKY := Color(0.98, 0.86, 0.58)
	const SKY_LIT := Color(1.0, 0.96, 0.82)
	const HILL := Color(0.45, 0.65, 0.34)
	const HILL_LIT := Color(0.58, 0.76, 0.42)
	const HILL_DARK := Color(0.36, 0.54, 0.28)
	const YANK := Color(0.40, 0.24, 0.16)
	# the coat in three values, so head, ears and body separate: the ears are
	# the darkest thing on her, the head a step lighter, the shoulders between
	const FUR := Color(0.21, 0.20, 0.22)
	const FUR_LIT := Color(0.40, 0.39, 0.42)
	const BODY := Color(0.15, 0.14, 0.16)
	const EAR := Color(0.07, 0.07, 0.08)
	const EAR_LIT := Color(0.30, 0.29, 0.32)
	# salt and pepper: the grizzle on her muzzle, brows, chin and chest
	const GRIZZLE := Color(0.70, 0.68, 0.66)
	const GRIZZLE_DARK := Color(0.50, 0.48, 0.47)
	const PEPPER := Color(0.20, 0.19, 0.20)
	const RIM := Color(1.0, 0.88, 0.62)
	const NOSE := Color(0.06, 0.06, 0.07)
	const COLLAR := Color(0.94, 0.33, 0.55)
	const COLLAR_DARK := Color(0.74, 0.20, 0.40)
	const LEASH := Color(0.74, 0.28, 0.20)
	const LEASH_DARK := Color(0.52, 0.17, 0.13)
	const RING := Color(0.88, 0.88, 0.90)
	const IRIS := Color(0.36, 0.20, 0.09)
	const IRIS_LIT := Color(0.58, 0.36, 0.16)
	const PUPIL := Color(0.04, 0.03, 0.03)
	const LEASH_TOP := Vector2(252.0, -4.0)
	const WHITE := Color(0.98, 0.96, 0.92)
	const LID := Color(0.03, 0.03, 0.04)

	var s := 1.0        # everything is authored against a 256 unit square
	var eye_style := EYE_STYLE
	# the head leans away from the pull: the leash goes up to the right
	var head := Vector2(120.0, 112.0)
	var tilt := -0.09
	# the poster paints its own, taller sky and turns this off
	var paint_sky := true
	# how far past the icon's top edge the leash carries on (the poster's is
	# taller than the icon)
	var leash_reach := 0.0

	# a point in head space, tilted, in pixels
	func _h(v: Vector2) -> Vector2:
		return (head + v.rotated(tilt)) * s

	func _ellipse_pts(c: Vector2, r: Vector2, rot := 0.0) -> PackedVector2Array:
		# enough sides that the poster, at eight times the icon, has no facets
		var n := clampi(int(maxf(r.x, r.y) * 0.7), 24, 200)
		var pts := PackedVector2Array()
		for i in range(n):
			var a := TAU * float(i) / float(n)
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
		return pts

	func _ellipse(c: Vector2, r: Vector2, col: Color, rot := 0.0) -> void:
		draw_colored_polygon(_ellipse_pts(c, r, rot), col)

	# an ellipse in head space (centre and radii in 256 units)
	func _hell(c: Vector2, r: Vector2, col: Color, rot := 0.0) -> void:
		_ellipse(_h(c), r * s, col, rot + tilt)

	# Chaikin corner cutting: a rough closed outline becomes a soft shape
	func _smooth(pts: PackedVector2Array, rounds := 4) -> PackedVector2Array:
		var p := pts
		for _r in range(rounds):
			var q := PackedVector2Array()
			for i in range(p.size()):
				var a := p[i]
				var b := p[(i + 1) % p.size()]
				q.append(a.lerp(b, 0.25))
				q.append(a.lerp(b, 0.75))
			p = q
		return p

	# a soft closed shape from head-space control points
	func _hshape(ctrl: Array, col: Color) -> void:
		var p := PackedVector2Array()
		for v: Vector2 in ctrl:
			p.append(_h(v))
		draw_colored_polygon(_smooth(p), col)

	func _draw() -> void:
		_draw_ground()
		_draw_body()
		# over the collar, under the head: the ear may hang across it
		_draw_leash()
		_draw_ring()
		_draw_head()

	func _draw_ground() -> void:
		# full bleed; _run() masks the rounded corners back in afterwards, so
		# the light can spill past the edges without leaving square corners
		if paint_sky:
			paint_sky_glow(Rect2(Vector2.ZERO, Vector2(256.0, 256.0) * s),
				Vector2(70.0, 50.0) * s, Vector2(210.0, 190.0) * s)
		# the hill she is being hauled up, and the pale path over it
		_ellipse(Vector2(120.0, 330.0) * s, Vector2(260.0, 150.0) * s, HILL)
		_ellipse(Vector2(200.0, 330.0) * s, Vector2(150.0, 128.0) * s, Color(HILL_DARK, 0.5))
		_ellipse(Vector2(60.0, 192.0) * s, Vector2(100.0, 16.0) * s, Color(HILL_LIT, 0.7), -0.10)

	# light from the upper left, the same direction every shadow in the game
	# falls away from
	func paint_sky_glow(r: Rect2, at: Vector2, reach: Vector2) -> void:
		draw_rect(r, SKY)
		for i in range(10):
			var k := float(i) / 9.0
			_ellipse(at, reach * (1.0 - k * 0.72), Color(SKY_LIT, 0.14))

	func _draw_leash() -> void:
		# It is what the game is named after, so it earns the diagonal, and it
		# runs out of frame: the human on the other end is not the point
		var ring := ring_at()
		var top := LEASH_TOP
		var d := (top - ring).normalized()
		top += d * leash_reach
		var side := Vector2(-d.y, d.x)
		draw_line(ring * s, top * s, LEASH_DARK, 12.0 * s)
		draw_line((ring - side * 1.5) * s, (top - side * 1.5) * s, LEASH, 8.0 * s)
		draw_line((ring - side * 3.0 + d * 10.0) * s, (top - side * 3.0) * s,
			Color(1.0, 0.7, 0.6, 0.35), 2.0 * s)
		# mid-yank: speed lines beside the ring, along the pull
		for k2 in range(3):
			var o: Vector2 = ring + side * (16.0 + float(k2) * 9.0) + d * (14.0 - float(k2) * 7.0)
			draw_line(o * s, (o + d * (24.0 - float(k2) * 6.0)) * s, YANK, 4.0 * s)

	func ring_at() -> Vector2:
		var n := neck_at()
		var a := PI * 0.2
		return n + Vector2(cos(a) * 51.0, sin(a) * 22.0 + 2.0)

	func _draw_body() -> void:
		# shoulders running off the bottom edge, so she is a dog and not a head
		# balanced on a lump; lit from the upper left like the head
		var chest := Vector2(120.0, 262.0)
		_ellipse((chest + Vector2(-3.0, -3.0)) * s, Vector2(98.0, 76.0) * s, FUR_LIT)
		_ellipse(chest * s, Vector2(98.0, 74.0) * s, BODY)
		var neck := neck_at()
		_ellipse(neck * s, Vector2(45.0, 30.0) * s, BODY)
		# the collar wraps the front of the neck, its ends turning away round
		# the sides, with the ring the leash pulls on at the front right
		var band := PackedVector2Array()
		for i in range(25):
			var a := lerpf(PI * 0.96, PI * 0.06, float(i) / 24.0)
			band.append((neck + Vector2(cos(a) * 51.0, sin(a) * 22.0 + 2.0)) * s)
		draw_polyline(band, COLLAR_DARK, 19.0 * s)
		var top_band := PackedVector2Array()
		for p in band:
			top_band.append(p + Vector2(0.0, -2.5) * s)
		draw_polyline(top_band, COLLAR, 14.0 * s)

	func _draw_ring() -> void:
		# the ring, pulled into an oval along the leash
		var ring := ring_at()
		var d := (LEASH_TOP - ring).normalized()
		_ellipse(ring * s, Vector2(10.0, 8.0) * s, LID, d.angle())
		_ellipse(ring * s, Vector2(8.5, 6.5) * s, RING, d.angle())
		_ellipse(ring * s, Vector2(4.5, 3.0) * s, COLLAR_DARK, d.angle())

	func neck_at() -> Vector2:
		return Vector2(122.0, 170.0)

	func _draw_head() -> void:
		# --- the skull: a dome over cheeks, with a lit crescent on the upper
		# left (the key light) so the dark coat has a form, and a warm rim on
		# the right where the sky wraps round her ---
		_hell(Vector2(-3.0, -3.0), Vector2(63.0, 55.0), FUR_LIT)
		_hell(Vector2(-3.0, 27.0), Vector2(53.0, 43.0), FUR_LIT)
		_hell(Vector2(1.8, 0.8), Vector2(61.0, 53.5), Color(RIM, 0.7))
		_hell(Vector2(1.8, 29.0), Vector2(51.0, 41.0), Color(RIM, 0.7))
		_hell(Vector2(0.0, 0.0), Vector2(61.0, 53.0), FUR)
		_hell(Vector2(0.0, 30.0), Vector2(51.0, 41.0), FUR)
		_hell(Vector2(-14.0, -30.0), Vector2(28.0, 12.0), Color(FUR_LIT, 0.35), -0.15)

		_draw_ears()

		# --- the grizzled muzzle: the lightest thing on her, so her face reads
		# as a face at 16px; a grey blaze runs up the bridge between the eyes ---
		_hshape([Vector2(-6, -4), Vector2(6, -4), Vector2(10, 12), Vector2(34, 22),
			Vector2(38, 46), Vector2(20, 60), Vector2(-20, 60), Vector2(-38, 46),
			Vector2(-34, 22), Vector2(-10, 12)], GRIZZLE_DARK)
		_hshape([Vector2(-4, 2), Vector2(4, 2), Vector2(8, 16), Vector2(30, 24),
			Vector2(34, 44), Vector2(18, 56), Vector2(-18, 56), Vector2(-34, 44),
			Vector2(-30, 24), Vector2(-8, 16)], GRIZZLE)
		# the pepper in the salt: whisker pits and flecks
		for sx: float in [-1.0, 1.0]:
			for f: Vector2 in [Vector2(14, 36), Vector2(21, 33), Vector2(18, 42), Vector2(26, 40),
					Vector2(11, 44), Vector2(28, 30)]:
				draw_circle(_h(Vector2(f.x * sx, f.y)), 1.5 * s, Color(PEPPER, 0.75))
		# the chin beard, under the mouth
		_hshape([Vector2(-14, 58), Vector2(14, 58), Vector2(10, 70), Vector2(-10, 70)], GRIZZLE)

		# --- nose and mouth: a dry little smirk on the side the leash is on ---
		_hshape([Vector2(-16, 22), Vector2(16, 22), Vector2(12, 34), Vector2(0, 38),
			Vector2(-12, 34)], NOSE)
		_hell(Vector2(-5.0, 25.0), Vector2(5.0, 2.5), Color(1, 1, 1, 0.45), -0.2)
		var w := 3.2 * s
		draw_line(_h(Vector2(0, 36)), _h(Vector2(0, 45)), NOSE, w)
		var mouth := PackedVector2Array()
		for i in range(13):
			var t := float(i) / 12.0
			# left cheek droops, right one hooks up
			var x := lerpf(-18.0, 20.0, t)
			var y := 46.0 + sin(t * PI) * 4.0 - (t * t) * 10.0 + 2.0
			mouth.append(_h(Vector2(x, y)))
		draw_polyline(mouth, NOSE, w)

		_draw_eyes()

	func _draw_ears() -> void:
		# Floppy, and set high: the root sits on top of the skull and the flap
		# folds over the crown and hangs down beside the face. Drawn over the
		# skull so the fold reads as a fold, in the coat's darkest value with a
		# lit crest so it separates from the head behind it.
		for sx: float in [-1.0, 1.0]:
			# the flap swings out a little further on the leash side, where she
			# is being pulled from
			var swing := 1.0 if sx < 0.0 else 1.08
			var ctrl := [Vector2(-14, -50), Vector2(-28, -64), Vector2(-56, -64),
				Vector2(-74 * swing, -44), Vector2(-82 * swing, -12), Vector2(-76 * swing, 6),
				Vector2(-62, 4), Vector2(-56, -18), Vector2(-40, -38)]
			var crest := [Vector2(-14, -50), Vector2(-28, -66), Vector2(-56, -67),
				Vector2(-76 * swing, -46), Vector2(-86 * swing, -12), Vector2(-79 * swing, 8),
				Vector2(-64, 2), Vector2(-58, -20), Vector2(-40, -40)]
			var mirror := func(arr: Array) -> Array:
				var out := []
				for v: Vector2 in arr:
					out.append(Vector2(v.x * sx * -1.0, v.y))
				return out
			_hshape(mirror.call(crest), EAR_LIT)
			_hshape(mirror.call(ctrl), EAR)
			# the inside of the fold, a sliver of lighter coat at the root
			_hshape(mirror.call([Vector2(-20, -52), Vector2(-34, -60), Vector2(-50, -58),
				Vector2(-36, -50)]), Color(EAR_LIT, 0.7))

	func _draw_eyes() -> void:
		for sx: float in [-1.0, 1.0]:
			var eye := Vector2(27.0 * sx, -6.0)
			if eye_style == "googly":
				_googly(eye, sx)
			else:
				_dog_eye(eye, sx)
		_draw_brows()

	func _dog_eye(eye: Vector2, sx: float) -> void:
		# a dark lid round the whole eye, an iris that fills nearly all of it,
		# and a crescent of white low on the far side as she looks up at the
		# leash: the side-eye is the joke, the rest is a dog
		_hell(eye, Vector2(14.0, 12.5), LID)
		_hell(eye, Vector2(11.5, 10.5), WHITE)
		var look := Vector2(1.6, -1.2)
		_hell(eye + look, Vector2(11.0, 10.5), IRIS)
		_hell(eye + look + Vector2(1.0, 3.5), Vector2(7.0, 4.5), Color(IRIS_LIT, 0.7))
		_hell(eye + look * 1.4, Vector2(6.5, 6.5), PUPIL)
		# the upper lid comes down a touch: unimpressed, not alarmed
		_hshape([eye + Vector2(-13, -11), eye + Vector2(0, -14), eye + Vector2(13, -11),
			eye + Vector2(13, -5), eye + Vector2(0, -8), eye + Vector2(-13, -5)], LID)
		_hell(eye + Vector2(-2.5, -3.5), Vector2(3.6, 3.2), Color(1, 1, 1, 0.95))
		_hell(eye + Vector2(5.5, 4.5), Vector2(1.6, 1.6), Color(1, 1, 1, 0.6))

	func _googly(eye: Vector2, sx: float) -> void:
		# the old cartoon eyes, tidied: a dark outline so the whites do not
		# melt into the grey brows, both pupils rolled toward the leash, and
		# the far eye a touch bigger, which is funnier than symmetry
		var r := 16.0 if sx < 0.0 else 17.5
		_hell(eye, Vector2(r + 2.5, r + 3.0), LID)
		_hell(eye, Vector2(r, r + 0.5), WHITE)
		_hell(eye + Vector2(0.0, r * 0.35), Vector2(r * 0.9, r * 0.5), Color(0.82, 0.78, 0.72, 0.5))
		var look := Vector2(4.0, -3.5)
		_hell(eye + look, Vector2(8.5, 9.0), PUPIL)
		_hell(eye + look + Vector2(-2.5, -3.0), Vector2(2.8, 2.8), Color(1, 1, 1, 0.95))

	func _draw_brows() -> void:
		# grizzled brow tufts, the dog's whole vocabulary: the near one level,
		# the one by the leash cocked up. Dry, not cross.
		var lift := 0.0 if eye_style == "dog" else -4.0
		_hshape([Vector2(-38, -24 + lift), Vector2(-26, -30 + lift), Vector2(-14, -27 + lift),
			Vector2(-18, -22 + lift), Vector2(-34, -20 + lift)], GRIZZLE)
		_hshape([Vector2(14, -30 + lift), Vector2(26, -38 + lift), Vector2(40, -34 + lift),
			Vector2(36, -29 + lift), Vector2(18, -26 + lift)], GRIZZLE)


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
	var out := OUT
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE * SS, SIZE * SS)
	vp.transparent_bg = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	var canvas := IconCanvas.new()
	canvas.s = float(SS)
	canvas.eye_style = eye_style_arg()
	vp.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	_round_corners(img, 30.0)
	var err := img.save_png(out)
	print("icon: %s (%dx%d, %s eyes) err=%d" % [out, img.get_width(), img.get_height(),
		canvas.eye_style, err])
	quit(0 if err == OK else 1)
