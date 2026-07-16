extends SceneTree

const CONTACT_POS := Vector2(20, 0)

var failures := 0


class FakeMain:
	extends Node2D

	var frozen := false
	var riders_cache: Array = []
	var cam := Node2D.new()
	var chase_count := 0
	var last_kind := ""

	func _init() -> void:
		add_child(cam)

	func on_critter_chase(_pos: Vector2, kind: String) -> void:
		chase_count += 1
		last_kind = kind

	func nearest_cover(_from: Vector2, _threat: Vector2) -> Vector2:
		return Vector2(140, 80)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _make_critter(main: Node2D, dog: Node2D, kind: String) -> Node2D:
	var critter := Node2D.new()
	critter.set_script(load("res://squirrel.gd"))
	root.add_child(critter)
	critter.setup(main, dog, kind)
	return critter


func _initialize() -> void:
	var main := FakeMain.new()
	var dog := Node2D.new()
	root.add_child(main)
	root.add_child(dog)
	dog.global_position = Vector2.ZERO

	var squirrel := _make_critter(main, dog, "squirrel")
	squirrel.global_position = CONTACT_POS
	squirrel.state = 2
	squirrel._physics_process(0.0)
	_check(main.chase_count == 1, "a fleeing squirrel scores on contact")
	_check(main.last_kind == "squirrel", "squirrel contact reports its kind")

	squirrel._physics_process(0.0)
	_check(main.chase_count == 1, "the same squirrel cannot score twice")

	var tofu := _make_critter(main, dog, "cat")
	tofu.global_position = CONTACT_POS
	tofu.state = 1
	tofu._physics_process(0.0)
	_check(main.chase_count == 2, "Tofu scores one boop on contact")
	_check(tofu.hide_target == Vector2(140, 80), "Tofu keeps relocating after the boop")

	var rat := _make_critter(main, dog, "rat")
	rat.global_position = Vector2(100, 0)
	rat.scare()
	rat._physics_process(0.0)
	_check(main.chase_count == 2, "a scare outside contact range does not score")

	if failures > 0:
		print("test_critter_chase: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_critter_chase: OK")
		quit(0)
