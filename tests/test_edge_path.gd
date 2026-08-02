extends SceneTree

# The corridor shape (edge_path.gd).
#
# The point of this file is that a path can now BEND, and the renderer, the
# surface under her paws and the prop fitting all have to agree about where it
# went. They agree by all calling the same function, so this is where that
# function gets held to its word.
#
# The most important test here is the boring one: with no control nodes the
# answer must be EXACTLY the old straight corridor, to the float. That is what
# made it safe to land the machinery before any level used it.
#
#   godot --headless --path . --script res://tests/test_edge_path.gd

const EdgePath := preload("res://edge_path.gd")

var failures: Array[String] = []
var checks := 0


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("  FAIL  %s" % msg)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_straight_is_unchanged()
	_test_bend()
	_test_smoothness()
	_test_validation()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("EDGE PATH OK")
		quit(0)
	else:
		print("EDGE PATH FAIL")
		quit(1)


func _test_straight_is_unchanged() -> void:
	print("\n--- no nodes means exactly the old straight corridor ---")
	# every level is this case today, so any drift here is a regression in a
	# level nobody touched
	for half: float in [225.0, 270.0, 340.0, 390.0]:
		for y: float in [260.0, -1000.0, -2500.0, -4999.0]:
			var e := EdgePath.edges([], y, 640.0, half)
			_check(is_equal_approx(e.x, 640.0 - half) and is_equal_approx(e.y, 640.0 + half),
				"half=%.0f at y=%.0f is %.1f..%.1f" % [half, y, e.x, e.y])
	# and it must not depend on y at all
	var a := EdgePath.edges([], 0.0, 640.0, 340.0)
	var b := EdgePath.edges([], -4000.0, 640.0, 340.0)
	_check(a.is_equal_approx(b), "a straight corridor is the same all the way down")


func _test_bend() -> void:
	print("\n--- a path that bends ---")
	var nodes := [
		{"y": -1000.0, "cx": 640.0, "half": 300.0},
		{"y": -2000.0, "cx": 480.0, "half": 220.0},
		{"y": -3000.0, "cx": 760.0, "half": 300.0},
	]
	# on a node, you get that node
	var mid := EdgePath.sample(nodes, -2000.0, 640.0, 340.0)
	_check(is_equal_approx(mid.x, 480.0) and is_equal_approx(mid.y, 220.0),
		"lands exactly on an authored node (%.1f, %.1f)" % [mid.x, mid.y])
	# between two nodes, somewhere between them
	var between := EdgePath.sample(nodes, -1500.0, 640.0, 340.0)
	_check(between.x < 640.0 and between.x > 480.0, "eases between nodes (cx %.1f)" % between.x)
	_check(between.y < 300.0 and between.y > 220.0, "...width too (half %.1f)" % between.y)
	# the pinch really pinches
	_check(EdgePath.sample(nodes, -2000.0, 640.0, 340.0).y
		< EdgePath.sample(nodes, -1000.0, 640.0, 340.0).y, "the narrow point is narrower")
	# Past the ends it HOLDS rather than extrapolating off into the buildings.
	# Nodes are in walk order, so the FIRST is the southernmost (y=-1000) and
	# the LAST is the far north end (y=-3000).
	var far_n := EdgePath.sample(nodes, -9000.0, 640.0, 340.0)
	var far_s := EdgePath.sample(nodes, 5000.0, 640.0, 340.0)
	_check(is_equal_approx(far_n.x, 760.0), "holds the last (northmost) node beyond it")
	_check(is_equal_approx(far_s.x, 640.0), "holds the first (southmost) node behind it")
	# edges() and sample() must never disagree
	var s := EdgePath.sample(nodes, -1700.0, 640.0, 340.0)
	var e := EdgePath.edges(nodes, -1700.0, 640.0, 340.0)
	_check(is_equal_approx(e.x, s.x - s.y) and is_equal_approx(e.y, s.x + s.y),
		"edges() is sample() spread either side of the centre")


func _test_smoothness() -> void:
	print("\n--- it eases, it does not turn corners ---")
	var nodes := [
		{"y": -1000.0, "cx": 640.0, "half": 300.0},
		{"y": -2000.0, "cx": 400.0, "half": 300.0},
	]
	# walk it and check the sideways step never jumps: a corner in the path is
	# a wall the player runs into without seeing it coming
	var prev := EdgePath.sample(nodes, -900.0, 640.0, 340.0).x
	var biggest := 0.0
	var y := -900.0
	while y <= -2100.0 + 0.5:
		var cur := EdgePath.sample(nodes, y, 640.0, 340.0).x
		biggest = maxf(biggest, absf(cur - prev))
		prev = cur
		y -= 10.0
	# 240px of drift over 1000px, eased: no single 10px step may be a lurch
	_check(biggest < 5.0, "no sudden sideways lurch (worst 10px step moved %.2f)" % biggest)
	# smoothstep means it leaves and arrives gently, so the ends move less
	# than the middle
	var at_start := absf(EdgePath.sample(nodes, -1010.0, 640.0, 340.0).x
		- EdgePath.sample(nodes, -1000.0, 640.0, 340.0).x)
	var at_mid := absf(EdgePath.sample(nodes, -1510.0, 640.0, 340.0).x
		- EdgePath.sample(nodes, -1500.0, 640.0, 340.0).x)
	_check(at_mid > at_start * 2.0,
		"eases in rather than starting at full tilt (%.3f vs %.3f)" % [at_start, at_mid])
	_check(EdgePath.max_slope(nodes) > 0.0, "max_slope notices a bend at all")
	_check(EdgePath.max_slope([]) == 0.0, "...and reports nothing for a straight path")


func _test_validation() -> void:
	print("\n--- the authoring guard ---")
	_check(bool(EdgePath.valid([])["ok"]), "no nodes is a valid (straight) path")
	_check(bool(EdgePath.valid([
		{"y": -1000.0, "cx": 640.0, "half": 300.0},
		{"y": -2000.0, "cx": 500.0, "half": 260.0},
	])["ok"]), "a sane bend passes")
	# y must advance, or the path doubles back on itself and sample() would
	# pick whichever node it met first
	_check(not bool(EdgePath.valid([
		{"y": -1000.0, "cx": 640.0, "half": 300.0},
		{"y": -1000.0, "cx": 500.0, "half": 300.0},
	])["ok"]), "two nodes at the same y are rejected")
	_check(not bool(EdgePath.valid([
		{"y": -2000.0, "cx": 640.0, "half": 300.0},
		{"y": -1000.0, "cx": 500.0, "half": 300.0},
	])["ok"]), "nodes that go backwards are rejected")
	# and a path that pinches shut is not a path
	_check(not bool(EdgePath.valid([
		{"y": -1000.0, "cx": 640.0, "half": 300.0},
		{"y": -2000.0, "cx": 640.0, "half": 20.0},
	], 120.0)["ok"]), "a corridor that pinches to nothing is rejected")
	# a missing field is an authoring slip, not a crash
	_check(not bool(EdgePath.valid([{"y": -1000.0, "cx": 640.0}])["ok"]),
		"a node missing its width is rejected")
	# the reason is reported, because a bare false helps nobody
	var why: String = String(EdgePath.valid([
		{"y": -1000.0, "cx": 640.0, "half": 10.0}], 120.0)["why"])
	_check(why != "", "rejections say why: %s" % why)
