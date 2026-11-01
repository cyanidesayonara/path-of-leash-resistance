extends SceneTree

# Circle level of detail (systems/shape_batch.gd, lod): off by default, a
# circle is the engine's 64-segment fan; on, a small circle has fewer sides,
# every rim point on the circle and every edge's midpoint within LOD_SAG of
# it, a large one keeps all 64, and the colour fills every vertex.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var plain := ShapeBatch.new()
	plain.circle(Vector2(10, 10), 3.0, Color.RED)
	_check(plain._points.size() == ShapeBatch.SEGMENTS * 3, "without lod a small circle keeps 64 sides")
	var c := Vector2(40.0, -25.0)
	for r: float in [0.2, 1.5, 3.0, 6.0, 12.0, 30.0, 60.0, 200.0]:
		var b := ShapeBatch.new()
		b.lod = true
		b.circle(c, r, Color(0.2, 0.4, 0.6, 0.5))
		var n := b._points.size() / 3
		_check(n == ShapeBatch.lod_sides(r), "r=%.1f: %d sides as lod_sides says" % [r, n])
		_check(n >= ShapeBatch.LOD_MIN and n <= ShapeBatch.SEGMENTS, "r=%.1f: sides within bounds" % r)
		var worst := 0.0
		var on_rim := true
		for t in range(n):
			var a: Vector2 = b._points[t * 3 + 1]
			var z: Vector2 = b._points[t * 3 + 2]
			on_rim = on_rim and absf(a.distance_to(c) - r) < 0.001 and b._points[t * 3] == c
			worst = maxf(worst, r - ((a + z) * 0.5).distance_to(c))
		_check(on_rim, "r=%.1f: a fan from the centre to points on the circle" % r)
		# at 64 sides it is the engine's own circle, however far a big one sags
		_check(n == ShapeBatch.SEGMENTS or worst <= ShapeBatch.LOD_SAG + 0.001, "r=%.1f: edges within %.2f px of round (%.3f)" % [r, ShapeBatch.LOD_SAG, worst])
		_check(b._colors.size() == b._points.size() and b._colors[b._colors.size() - 1] == Color(0.2, 0.4, 0.6, 0.5), "r=%.1f: every vertex coloured" % r)
	_check(ShapeBatch.lod_sides(200.0) == ShapeBatch.SEGMENTS, "a large circle keeps all 64 sides")
	_check(ShapeBatch.lod_sides(3.0) < 16, "a 3 px dot needs fewer than 16")
	if failures.is_empty():
		print("test_circle_lod: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_circle_lod: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
