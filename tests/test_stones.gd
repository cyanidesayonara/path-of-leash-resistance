extends SceneTree

# world/stones.gd: a stone is a stamped outline, one triangle fan of
# Stones.SIDES triangles, inside about its radius, the same for the same hash,
# and a lit stone is three of them (shadow, body, lit facet).

const Stones := preload("res://world/stones.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	var at := Vector2(100.0, -200.0)
	var b := ShapeBatch.new()
	Stones.stone(b, at, 10.0, Color.GRAY, 0.3)
	_check(b._points.size() == Stones.SIDES * 3, "a stone is one fan of %d triangles (%d points)" % [Stones.SIDES, b._points.size()])
	var inside := true
	for p: Vector2 in b._points:
		inside = inside and p.distance_to(at) <= 10.0 * 1.2
	_check(inside, "a stone lies within about its radius")
	var again := ShapeBatch.new()
	Stones.stone(again, at, 10.0, Color.GRAY, 0.3)
	_check(again._points == b._points, "the same hash draws the same stone")
	var other := ShapeBatch.new()
	Stones.stone(other, at, 10.0, Color.GRAY, 0.8)
	_check(other._points != b._points, "another hash draws another stone")
	var lit := ShapeBatch.new()
	Stones.lit_stone(lit, at, 10.0, Color.GRAY, Color(0, 0, 0, 0.5), 0.3)
	_check(lit._points.size() == Stones.SIDES * 9, "a lit stone is shadow, body and facet")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_stones: OK")
		quit(0)
	else:
		quit(1)
