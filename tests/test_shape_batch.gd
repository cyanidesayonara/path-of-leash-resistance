extends SceneTree

# ShapeBatch (systems/shape_batch.gd) merges runs of shapes into one draw
# call and promises the same picture pixel for pixel. This draws one scene
# both ways - the plain draw_* calls, then ShapeBatch - into offscreen
# viewports and compares the images exactly: circles with odd radii and
# fractional centres, filled rects (negative sizes too), wide lines at every
# angle, concave polygons, all interleaved and overlapping with translucent
# colours, plus a draw_set_transform squash like contact_shadow's. The scene
# is drawn a third time through the stand-in canvas (ShapeBatch.new(ci)),
# with outlined rects and 1px lines that must fall through to the canvas.
# Needs a rendering context, like test_rotate_prompt.gd.

const SIZE := Vector2i(320, 240)

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# the scene as a list of shapes, drawn by both methods in this order
func _shapes() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(240):
		var col := Color(rng.randf(), rng.randf(), rng.randf(), rng.randf_range(0.2, 1.0))
		var at := Vector2(rng.randf_range(10.0, 310.0), rng.randf_range(10.0, 230.0))
		match i % 4:
			0:
				out.append(["circle", at, rng.randf_range(0.6, 38.0), col])
			1:
				var sz := Vector2(rng.randf_range(0.5, 60.0), rng.randf_range(0.5, 40.0))
				if i % 12 == 5:
					sz = -sz
				out.append(["rect", Rect2(at, sz), col])
			2:
				var to := at + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(2.0, 90.0)
				var widths := [0.0, 1.0, 1.5, 2.2, 3.0, 5.0, 7.0]
				out.append(["line", at, to, col, widths[rng.randi() % widths.size()]])
			3:
				var pts := PackedVector2Array()
				var n := 3 + rng.randi() % 6
				for k in range(n):
					# alternate radii, so some polygons are concave
					var rad := rng.randf_range(4.0, 30.0) * (0.5 if k % 2 == 1 else 1.0)
					pts.append(at + Vector2.from_angle(TAU * float(k) / float(n)) * rad)
				out.append(["polygon", pts, col])
	# the cone's own rings, where the case matters most
	for k in [7.0, 9.5, 12.0]:
		var c := Vector2(40.0 + k * 20.0, 200.0)
		for ring in [[0.0, 1.0], [0.05, 0.82], [0.10, 0.60], [0.15, 0.34], [0.18, 0.16]]:
			out.append(["circle", c - Vector2.ONE * k * ring[0], k * ring[1], Color(0.93, 0.52, 0.17, 1.0)])
	return out


# c is a CanvasItem or a stand-in ShapeBatch: the calls are the same
func _draw_scene(c: Object, extras: bool) -> void:
	var n := 0
	for s in _shapes():
		match String(s[0]):
			"circle": c.draw_circle(s[1], s[2], s[3])
			"rect": c.draw_rect(s[1], s[2])
			"line": c.draw_line(s[1], s[2], s[3], s[4])
			"polygon": c.draw_colored_polygon(s[1], s[2])
		n += 1
		# what the stand-in cannot batch, in among what it can
		if extras and n % 25 == 0:
			c.draw_rect(Rect2(s[1] if s[1] is Vector2 else Vector2(40, 40), Vector2(17.5, 11.0)), Color(0.1, 0.1, 0.1, 0.8), false, 2.0)
			c.draw_line(Vector2(5.0, float(n) * 0.9), Vector2(300.0, float(n) * 0.7), Color(1, 1, 1, 0.6))
			# a helper's own batch flushed into c: straight onto a canvas, or
			# into the stand-in's queue
			var inner := ShapeBatch.new()
			inner.circle(Vector2(float(n), 120.0), 9.5, Color(0.9, 0.9, 0.2, 0.5))
			inner.rect(Rect2(float(n) - 4.0, 110.0, 8.0, 20.0), Color(0.2, 0.9, 0.9, 0.5))
			inner.flush(c)
	c.draw_set_transform(Vector2(160.5, 120.25), 0.3, Vector2(1.15, 0.5))
	c.draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	c.draw_rect(Rect2(-8.5, -3.25, 20.0, 9.0), Color(0.9, 0.3, 0.2, 0.7))
	c.draw_line(Vector2(-20, 4), Vector2(25, -6), Color(0.3, 0.9, 0.4, 0.8), 3.0)
	c.draw_circle(Vector2(12.0, -3.0), 11.3, Color(0.2, 0.3, 0.9, 0.6))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_plain(ci: Node2D) -> void:
	_draw_scene(ci, false)


func _draw_plain_extras(ci: Node2D) -> void:
	_draw_scene(ci, true)


func _draw_batched(ci: Node2D) -> void:
	var b := ShapeBatch.new()
	for s in _shapes():
		match String(s[0]):
			"circle": b.circle(s[1], s[2], s[3])
			"rect": b.rect(s[1], s[2])
			"line": b.line(s[1], s[2], s[3], s[4])
			"polygon": b.polygon(s[1], s[2])
	b.flush(ci)
	ci.draw_set_transform(Vector2(160.5, 120.25), 0.3, Vector2(1.15, 0.5))
	b.circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))
	b.rect(Rect2(-8.5, -3.25, 20.0, 9.0), Color(0.9, 0.3, 0.2, 0.7))
	b.line(Vector2(-20, 4), Vector2(25, -6), Color(0.3, 0.9, 0.4, 0.8), 3.0)
	b.circle(Vector2(12.0, -3.0), 11.3, Color(0.2, 0.3, 0.9, 0.6))
	b.flush(ci)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_standin(ci: Node2D) -> void:
	var b := ShapeBatch.new(ci)
	_draw_scene(b, true)
	b.flush()


func _render(drawer: Callable) -> Image:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.5, 0.55, 0.45)
	bg.size = Vector2(SIZE)
	vp.add_child(bg)
	var n := Node2D.new()
	n.draw.connect(drawer.bind(n))
	vp.add_child(n)
	for i in range(4):
		await process_frame
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func _run() -> void:
	var plain: Image = await _render(_draw_plain)
	var batched: Image = await _render(_draw_batched)
	var plain_extras: Image = await _render(_draw_plain_extras)
	var standin: Image = await _render(_draw_standin)
	_check(plain.get_size() == SIZE and batched.get_size() == SIZE, "both viewports rendered")
	var lit := 0
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if not plain.get_pixel(x, y).is_equal_approx(Color(0.5, 0.55, 0.45)):
				lit += 1
	_check(lit > SIZE.x * SIZE.y / 4, "the shapes actually drew (%d px)" % lit)
	var d1 := _differ(plain, batched)
	_check(d1 == 0, "ShapeBatch matches the plain draw calls pixel for pixel (%d px differ)" % d1)
	var d2 := _differ(plain_extras, standin)
	_check(d2 == 0, "the stand-in canvas matches too, fall-throughs included (%d px differ)" % d2)
	_check(_differ(plain, plain_extras) > 0, "the fall-through shapes actually drew")
	_finish()


func _differ(a: Image, b: Image) -> int:
	var n := 0
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				n += 1
	return n


func _finish() -> void:
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_shape_batch: OK")
		quit(0)
	else:
		quit(1)
