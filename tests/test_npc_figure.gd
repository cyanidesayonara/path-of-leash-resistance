extends SceneTree

# A passer-by drawn by NpcFigure (entities/npc_figure.gd): every pose draws
# into the caller's batch without a call of its own, the same person looks
# the same every time, different people differ, a walking person's feet
# move with the stride, and the figure faces where it is told.

var failures := 0
var checks := 0


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + msg)


func _draw(key: int, facing: Vector2, stride: float, o := {}) -> ShapeBatch:
	var b := ShapeBatch.new(null)   # recording: a live call would land in _ops
	var F: GDScript = load("res://entities/npc_figure.gd")
	F.person(b, Vector2(100, 100), facing, key, stride, o)
	return b


func _initialize() -> void:
	var F: GDScript = load("res://entities/npc_figure.gd")
	for arms: int in [F.Arms.SIDE, F.Arms.BEHIND, F.Arms.READY, F.Arms.UP, F.Arms.THROW]:
		for hw: String in ["none", "cap", "beanie"]:
			var b := _draw(5, Vector2.UP, 1.0, {"arms": arms, "headwear": hw})
			_check(b._ops.is_empty(), "pose %d with %s draws in the batch, no call of its own" % [arms, hw])
			_check(b._points.size() > 60, "and draws a whole person (%d points)" % b._points.size())
	_check(_draw(9, Vector2.UP, -1.0)._colors == _draw(9, Vector2.UP, -1.0)._colors, "the same person looks the same")
	_check(_draw(9, Vector2.UP, -1.0)._colors != _draw(10, Vector2.UP, -1.0)._colors, "two people differ")
	_check(_draw(9, Vector2.UP, 0.0)._points != _draw(9, Vector2.UP, PI * 0.5)._points, "a walker's feet move with the stride")
	_check(_draw(9, Vector2.UP, -1.0)._points != _draw(9, Vector2.DOWN, -1.0)._points, "the figure turns to face its way")
	_check(F.skin_for(3) == F.skin_for(3) and F.hair_for(3) == F.hair_for(3), "skin and hair are the person's own")
	print("test_npc_figure: %d checks, %s" % [checks, "OK" if failures == 0 else "%d FAILED" % failures])
	quit(1 if failures > 0 else 0)
