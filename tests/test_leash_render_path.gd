extends SceneTree

# Rendering may smooth a free span, but it must preserve solver geometry at a
# static contact. Otherwise the visible leash can cut through the pole that
# the physical leash is wrapped around.

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _contains_point(path: Array, target: Vector2) -> bool:
	for p: Vector2 in path:
		if p.distance_to(target) < 0.01:
			return true
	return false


func _initialize() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	dog.global_position = Vector2(-180, 0)
	human.global_position = Vector2(180, 0)
	var pole := Vector2.ZERO
	var poles: Array[Vector2] = [pole]
	leash.setup(dog, human, poles, 360.0)
	leash._touch.resize(leash.N)

	_check(leash.has_method("render_points"),
		"leash exposes render_points() for the smoothed visible path")
	if leash.has_method("render_points"):
		# First prove the helper actually smooths a free, visibly bent span.
		for i in range(leash.N):
			var x := -180.0 + 360.0 * float(i) / float(leash.N - 1)
			leash.pts[i] = Vector2(x, 24.0 * sin(float(i) * 0.7))
			leash._touch[i] = -1
		var open_path: Array = Array(leash.render_points())
		_check(open_path.size() > leash.pts.size(),
			"an open span receives intermediate render samples")

		# Put the middle controls on a valid 14px arc around the 13px pole.
		# The contact and both adjacent controls are hard pins for smoothing.
		var mid: int = leash.N / 2
		leash._obs_pos = PackedVector2Array([pole])
		leash._obs_kind = PackedInt32Array([leash.K_POLE])
		for i in range(leash.N):
			leash._touch[i] = -1
		for offset in range(-2, 3):
			var angle := -PI / 2.0 + float(offset) * PI / 6.0
			leash.pts[mid + offset] = pole + Vector2.from_angle(angle) * 14.0
		leash._touch[mid] = 0
		var wrapped_path: Array = Array(leash.render_points())
		for index in [mid - 1, mid, mid + 1]:
			_check(_contains_point(wrapped_path, leash.pts[index]),
				"render path pins control %d beside the static contact" % index)
		for p: Vector2 in wrapped_path:
			_check(p.distance_to(pole) + 0.01 >= leash.POLE_PAD,
				"smoothed render path clears POLE_PAD (point %s)" % p)

	leash.free()
	dog.free()
	human.free()
	if failures > 0:
		print("test_leash_render_path: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_render_path: OK")
		quit(0)
