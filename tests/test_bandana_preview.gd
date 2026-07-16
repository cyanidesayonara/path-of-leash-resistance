extends SceneTree

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _finish() -> void:
	if failures > 0:
		print("test_bandana_preview: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_bandana_preview: OK")
		quit(0)


func _initialize() -> void:
	var dog := CharacterBody2D.new()
	dog.set_script(load("res://dog.gd"))
	var required := [
		"set_cosmetic_preview",
		"_cosmetic_collar_key",
		"_cosmetic_bandana_key",
		"_bandana_points",
	]
	for method: String in required:
		if not dog.has_method(method):
			_check(false, "dog exposes " + method)
	if failures > 0:
		dog.free()
		_finish()
		return

	dog.preview_mode = true
	dog.set_cosmetic_preview("blue", "navy")
	seed(424242)
	var expected_next_random := randf()
	seed(424242)
	root.add_child(dog)
	var actual_next_random := randf()
	_check(dog.get_child_count() == 0, "preview mode creates no collision child")
	_check(is_equal_approx(actual_next_random, expected_next_random), "preview creation preserves global RNG")
	_check(dog._cosmetic_collar_key() == "blue", "preview collar override resolves")
	_check(dog._cosmetic_bandana_key() == "navy", "preview bandana override resolves")

	dog.set_cosmetic_preview("red", "none")
	_check(dog._cosmetic_bandana_key() == "none", "none clears preview bandana")

	var forward := Vector2.UP
	var points: PackedVector2Array = dog._bandana_points(Vector2.ZERO, forward)
	_check(points.size() == 3, "bandana is a triangle")
	if points.size() == 3:
		var base_mid := (points[0] + points[1]) * 0.5
		var base_width := points[0].distance_to(points[1])
		var twice_area := absf((points[1] - points[0]).cross(points[2] - points[0]))
		_check(base_width >= 14.0, "bandana has a broad neck base")
		_check(twice_area > 1.0, "bandana triangle has area")
		_check((points[2] - base_mid).dot(forward) < 0.0, "bandana point trails behind")

	dog.free()
	_finish()
