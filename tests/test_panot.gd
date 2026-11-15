extends SceneTree

# Barcelona's pavement tiles (world/panot.gd):
# - flower tiles stay inside the rect they are given, and a strip too narrow
#   for a flower gets nothing
# - a row of flower tiles stays between its two edges
# - Gaudi's hexagons are laid only where they fit whole inside the span, and
#   not at all where the span is empty (a cross street)
# - every hexagon touches one of each figure: its own top corner and the top
#   corners of the two tiles below it always differ
# - all of it is triangles in the caller's batch: nothing only a canvas can
#   draw, so no draw call of its own

const Panot := preload("res://world/panot.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _bounds(b: ShapeBatch) -> Rect2:
	var pts: PackedVector2Array = b._points
	var r := Rect2(pts[0], Vector2.ZERO)
	for p: Vector2 in pts:
		r = r.expand(p)
	return r


func _initialize() -> void:
	var b := ShapeBatch.new()
	Panot.flor(b, 100.0, 300.0, -400.0, -280.0)
	_check(b._points.size() > 0 and b._points.size() % 3 == 0, "flower tiles are whole triangles")
	_check(Rect2(99.0, -401.0, 202.0, 122.0).encloses(_bounds(b)), "flower tiles stay inside their rect: %s" % _bounds(b))
	_check(b._ops.is_empty(), "flower tiles are all in the one batch")

	var narrow := ShapeBatch.new()
	Panot.flor(narrow, 100.0, 120.0, -400.0, -280.0)
	Panot.flor_row(narrow, 100.0, 120.0, -400.0, 100.0)
	_check(narrow._points.is_empty(), "a strip too narrow for a flower gets no tiles")

	var row := ShapeBatch.new()
	Panot.flor_row(row, 113.0, 271.0, -400.0, 100.0, Panot.INK, Panot.SHINE, 32.0)
	_check(Rect2(112.0, -401.0, 160.0, 34.0).encloses(_bounds(row)), "a row of tiles stays between its edges: %s" % _bounds(row))

	# a strip that slants, with a cross street cut out of it
	var span := func(y: float) -> Vector2:
		if y > -700.0 and y < -500.0:
			return Vector2(INF, -INF)
		return Vector2(200.0 + y * 0.1, 420.0 + y * 0.1)
	var hexes := ShapeBatch.new()
	Panot.gaudi(hexes, span, -1000.0, -200.0)
	_check(hexes._points.size() > 0 and hexes._ops.is_empty(), "hexagons are all in the one batch")
	var out := 0
	var crossed := 0
	for p: Vector2 in hexes._points:
		if p.y > -700.0 + Panot.HEX and p.y < -500.0 - Panot.HEX:
			crossed += 1
		elif p.y <= -700.0 or p.y >= -500.0:
			var e: Vector2 = span.call(p.y)
			if p.x < e.x - 0.5 or p.x > e.y + 0.5:
				out += 1
	_check(out == 0, "no hexagon pokes past the pavement's edge (%d points did)" % out)
	_check(crossed == 0, "no hexagon is laid across the cross street (%d points were)" % crossed)

	var same := 0
	for r in range(-9, 10):
		for c in range(-9, 10):
			var odd := posmod(r, 2)
			var a := Panot.figure_at(c, r)
			var bl := Panot.figure_at(c - 1 + odd, r + 1)
			var br := Panot.figure_at(c + odd, r + 1)
			if a == bl or a == br or bl == br:
				same += 1
	_check(same == 0, "every hexagon touches one of each figure (%d did not)" % same)

	print("test_panot: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
