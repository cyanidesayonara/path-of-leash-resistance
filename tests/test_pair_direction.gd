extends SceneTree

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _check_distance(main: Node2D, camera_y: float, expected: float, label: String) -> void:
	var distance := float(main.call("_pair_spawn_distance", camera_y))
	_check(is_equal_approx(distance, expected), label)


func _check_route(main: Node2D, walk_phase: String, oncoming: bool, camera_y: float, expected_y: float, expected_direction: Vector2, label: String) -> void:
	var route: Dictionary = main.call("_pair_spawn_route", walk_phase, oncoming, camera_y)
	var route_y := float(route["y"])
	var direction: Vector2 = route["direction"]
	_check(is_equal_approx(route_y, expected_y), label + " spawn position")
	_check(direction.is_equal_approx(expected_direction), label + " direction")
	_check((camera_y - route_y) * direction.y > 0.0, label + " moves toward camera")


func _finish() -> void:
	if failures > 0:
		print("test_pair_direction: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_direction: OK")
		quit(0)


func _initialize() -> void:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	if not main.has_method("_pair_spawn_distance") or not main.has_method("_pair_spawn_route"):
		_check(false, "main exposes pair spawn helpers")
		main.free()
		_finish()
		return

	var camera_y := -1000.0
	_check_distance(main, camera_y, 560.0, "central spawn distance")
	_check_route(main, "out", true, camera_y, -1560.0, Vector2.DOWN, "outbound oncoming")
	_check_route(main, "out", false, camera_y, -440.0, Vector2.UP, "outbound same-direction")
	_check_route(main, "home", true, camera_y, -440.0, Vector2.UP, "home oncoming")
	_check_route(main, "home", false, camera_y, -1560.0, Vector2.DOWN, "home same-direction")

	_check_distance(main, -100.0, 460.0, "upper intermediate spawn distance")
	_check_route(main, "out", true, -100.0, -560.0, Vector2.DOWN, "upper intermediate outbound oncoming")
	_check_route(main, "out", false, -100.0, 360.0, Vector2.UP, "upper intermediate outbound same-direction")

	_check_distance(main, 0.0, 360.0, "upper edge shortens to viewport edge")
	_check_route(main, "out", true, 0.0, -360.0, Vector2.DOWN, "upper edge oncoming")
	_check_route(main, "out", false, 0.0, 360.0, Vector2.UP, "upper edge same-direction")
	_check_distance(main, 1.0, 0.0, "upper margin pauses spawning")

	_check_distance(main, -4480.0, 460.0, "lower intermediate spawn distance")
	_check_route(main, "home", true, -4480.0, -4020.0, Vector2.UP, "lower intermediate home oncoming")
	_check_route(main, "home", false, -4480.0, -4940.0, Vector2.DOWN, "lower intermediate home same-direction")

	_check_distance(main, -4580.0, 360.0, "lower edge shortens to viewport edge")
	_check_route(main, "home", true, -4580.0, -4220.0, Vector2.UP, "lower edge oncoming")
	_check_route(main, "home", false, -4580.0, -4940.0, Vector2.DOWN, "lower edge same-direction")
	_check_distance(main, -4581.0, 0.0, "lower margin pauses spawning")

	main.free()
	_finish()
