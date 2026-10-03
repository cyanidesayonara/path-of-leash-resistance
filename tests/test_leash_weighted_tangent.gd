extends SceneTree

# A single noisy endpoint sample must not decide the whole pull direction.
# The real rope beyond it still points along the stable outgoing span.

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _initialize() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	dog.global_position = Vector2.ZERO
	human.global_position = Vector2(220, 0)
	var no_poles: Array[Vector2] = []
	leash.setup(dog, human, no_poles, 220.0)

	# Point 1 is displaced sharply upward for one frame, while the next
	# interior samples continue along the true rightward rope direction.
	leash.pts[0] = Vector2(0, 0)
	leash.pts[1] = Vector2(0, 80)
	leash.pts[2] = Vector2(40, 0)
	leash.pts[3] = Vector2(80, 0)
	var pull: Vector2 = leash.dog_pull_dir()
	_check(pull.dot(Vector2.RIGHT) > 0.75,
		"weighted dog tangent follows the stable span, not displaced point 1 (got %s)" % pull)

	leash.free()
	dog.free()
	human.free()
	if failures > 0:
		print("test_leash_weighted_tangent: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_weighted_tangent: OK")
		quit(0)
