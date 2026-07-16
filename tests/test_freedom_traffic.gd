extends SceneTree

var failures := 0


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := true


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _make_traffic(script_path: String, main: Node2D) -> Node2D:
	var traffic := Node2D.new()
	traffic.set_script(load(script_path))
	traffic.visible = false
	traffic.set_physics_process(false)
	traffic.main = main
	root.add_child(traffic)
	return traffic


func _initialize() -> void:
	var main := FakeMain.new()
	root.add_child(main)

	var bike := _make_traffic("res://bike.gd", main)
	bike._physics_process(0.0)
	_check(bike.is_queued_for_deletion(), "active rider removes itself in freedom")

	var pair := _make_traffic("res://otherpair.gd", main)
	pair.configure_park_area(0.0, Rect2(0.0, -300.0, 400.0, 260.0))
	pair._physics_process(0.0)
	_check(not pair.is_queued_for_deletion(), "park-configured dog-walker pair persists in freedom")

	if failures > 0:
		print("test_freedom_traffic: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_freedom_traffic: OK")
		quit(0)
