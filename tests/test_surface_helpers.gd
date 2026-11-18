extends SceneTree

# The shared ground-past-the-gate helpers in world/surfaces.gd, which a walk's
# surface hook returns as they stand: -1 short of the gate's line, then a
# paved area's pavement with soft earth round its trees and planted props, or
# a lawn wall to wall.

const Surfaces := preload("res://world/surfaces.gd")

var checks := 0
var failures: Array[String] = []


class FakeWalk extends Node2D:
	var GATE_Y := -5000.0
	var park_props: Array = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	var m := FakeWalk.new()
	m.park_props = [
		{"kind": "planter", "pos": Vector2(300.0, -5400.0)},
		{"kind": "bench", "pos": Vector2(500.0, -5400.0)},
		{"kind": "dig", "pos": Vector2(700.0, -5400.0)},
	]
	var trees: Array = [Vector2(900.0, -5600.0)]
	var S := Surfaces.S

	# short of the line 40 past the gate, main decides
	_check(Surfaces.paved_past_gate(m, Vector2(640.0, -4970.0), trees) == -1, "paved: short of the gate answers -1")
	_check(Surfaces.paved_past_gate(m, Vector2(640.0, -5040.0), trees) == -1, "paved: on the line answers -1")
	_check(Surfaces.lawn_past_gate(m, Vector2(640.0, -4970.0)) == -1, "lawn: short of the gate answers -1")
	_check(Surfaces.lawn_past_gate(m, Vector2(640.0, -5040.0)) == -1, "lawn: on the line answers -1")

	# past it, a paved area is pavement bar the soft ground
	_check(Surfaces.paved_past_gate(m, Vector2(640.0, -5300.0), trees) == S.PAVEMENT, "paved: open paving is pavement")
	_check(Surfaces.paved_past_gate(m, Vector2(310.0, -5400.0), trees) == S.GRASS, "paved: a planter's earth is soft")
	_check(Surfaces.paved_past_gate(m, Vector2(705.0, -5400.0), trees) == S.GRASS, "paved: a dig spot is soft")
	_check(Surfaces.paved_past_gate(m, Vector2(500.0, -5400.0), trees) == S.PAVEMENT, "paved: a bench stands on paving")
	_check(Surfaces.paved_past_gate(m, Vector2(910.0, -5600.0), trees) == S.GRASS, "paved: a tree pit is soft")
	_check(Surfaces.paved_past_gate(m, Vector2(900.0, -5626.0), trees) == S.GRASS, "paved: inside the default radius")
	_check(Surfaces.paved_past_gate(m, Vector2(900.0, -5626.0), trees, 24.0) == S.PAVEMENT, "paved: a smaller radius is honoured")
	_check(Surfaces.paved_past_gate(m, Vector2(900.0, -5600.0), []) == S.PAVEMENT, "paved: only the trees it is given")

	# a lawn is grass all the way across
	_check(Surfaces.lawn_past_gate(m, Vector2(100.0, -5300.0)) == S.GRASS, "lawn: grass past the gate")
	_check(Surfaces.lawn_past_gate(m, Vector2(310.0, -5400.0)) == S.GRASS, "lawn: grass by a planter too")
	m.free()

	if failures.is_empty():
		print("%d checks, 0 failures" % checks)
		print("test_surface_helpers: OK")
		quit(0)
	else:
		print("%d checks, %d FAILURES:" % [checks, failures.size()])
		for f in failures:
			print("  - " + f)
		quit(1)
