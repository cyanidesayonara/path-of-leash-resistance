extends SceneTree

var failures := 0


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := true
	var cam := Camera2D.new()
	var released_pair_ids: Array[int] = []

	func _init() -> void:
		add_child(cam)

	func release_pair_park_spot(pair_instance_id: int) -> void:
		released_pair_ids.append(pair_instance_id)

	func float_text(_position: Vector2, _text: String, _color: Color) -> void:
		pass


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

	var player_dog := Node2D.new()
	player_dog.visible = false
	root.add_child(player_dog)
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.visible = false
	var poles: Array[Vector2] = [Vector2(300.0, 120.0)]
	pair.setup(main, player_dog, poles, Vector2(200.0, 120.0), Vector2.UP)
	var blockers: Array[Dictionary] = []
	_check(
		bool(pair.configure_route(200.0, 20.0, 380.0, blockers)),
		"production pair route configures"
	)
	pair.configure_park_area(0.0, Rect2(0.0, -300.0, 400.0, 260.0))
	root.add_child(pair)
	pair.set_physics_process(false)
	pair._physics_process(0.0)
	_check(not pair.is_queued_for_deletion(), "park-configured dog-walker pair persists in freedom")

	pair.free()
	player_dog.free()
	bike.free()
	main.free()
	if failures > 0:
		print("test_freedom_traffic: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_freedom_traffic: OK")
		quit(0)
