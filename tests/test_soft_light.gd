extends SceneTree

# Soft light (systems/shape_batch.gd glow and band): a glow is full strength
# at its centre, nothing at its rim, and never brighter further out, with no
# jump between rings large enough to read as a band; a small glow takes the
# coarse mesh; a pulsing glow reuses its colours; a band is clear at its
# feathered edges. Headless: this reads the batch's queued triangles.

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
	var col := Color(1.0, 0.84, 0.56, 0.36)
	for spec: Array in [[190.0, 0.0], [190.0, 0.3], [20.0, 0.0]]:
		var r: float = spec[0]
		var core: float = spec[1]
		var b := ShapeBatch.new()
		b.glow(Vector2(100, 50), r, col, core)
		var pts: PackedVector2Array = b._points
		var cols: PackedColorArray = b._colors
		var what := "glow r=%d core=%.1f" % [int(r), core]
		_check(pts.size() == cols.size() and pts.size() % 3 == 0, what + " is a whole triangle list")
		var mi := 1 if r < ShapeBatch.GLOW_SMALL_R else 0
		var mesh: Array = ShapeBatch.GLOW_MESHES[mi]
		var segs: int = mesh[0]
		var rings: int = mesh[1]
		_check(pts.size() == segs * 3 + (rings - 1) * segs * 6, what + " uses the %s mesh" % ["fine", "coarse"][mi])
		# alpha against distance from the centre
		var by_d := {}
		for i in range(pts.size()):
			var d := snappedf(pts[i].distance_to(Vector2(100, 50)) / r, 0.001)
			by_d[d] = cols[i].a
			_check(cols[i].r == col.r and cols[i].g == col.g and cols[i].b == col.b, what + " keeps its colour")
		var ds: Array = by_d.keys()
		ds.sort()
		# alpha is kept to 1/256, what 8-bit output can show
		_check(absf(float(by_d[ds[0]]) - col.a) <= 1.0 / 256.0, what + " is full strength at the centre")
		_check(float(by_d[ds[-1]]) == 0.0 and is_equal_approx(float(ds[-1]), 1.0), what + " is clear at its rim")
		var worst := 0.0
		for k in range(1, ds.size()):
			_check(float(by_d[ds[k]]) <= float(by_d[ds[k - 1]]) + 0.0001, what + " never brightens outward")
			worst = maxf(worst, float(by_d[ds[k - 1]]) - float(by_d[ds[k]]))
		_check(worst <= col.a * 0.45, what + " has no step that reads as a band (%.3f)" % worst)
	# a pulsing glow comes back to the same colours
	var b1 := ShapeBatch.new()
	b1.glow(Vector2.ZERO, 104.0, Color(0.66, 0.8, 1.0, 0.2))
	var n := ShapeBatch._glow_cols.size()
	b1.glow(Vector2(5, 5), 80.0, Color(0.66, 0.8, 1.0, 0.2))
	_check(ShapeBatch._glow_cols.size() == n, "the same glow colour is built once")
	# a band: clear at its feathered columns, full in the middle
	var bb := ShapeBatch.new()
	bb.band(PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(20, 0), Vector2(0, 20), Vector2(10, 20), Vector2(20, 20)]),
		3, Color(0.2, 0.2, 0.2, 0.5), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
	var mid_full := false
	var edges_clear := true
	for i in range(bb._points.size()):
		var x := bb._points[i].x
		if x == 10.0:
			mid_full = mid_full or is_equal_approx(bb._colors[i].a, 0.5)
		else:
			edges_clear = edges_clear and bb._colors[i].a == 0.0
	_check(bb._points.size() == 2 * 2 * 3, "a band of two rows and three columns is four triangles")
	_check(mid_full and edges_clear, "a band is full along its middle and clear at its edges")
	if failures.is_empty():
		print("test_soft_light: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_soft_light: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
