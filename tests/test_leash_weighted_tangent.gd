extends SceneTree

# A single noisy endpoint sample must not decide the whole pull direction.
# The real rope beyond it still points along the stable outgoing span.

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


# A real ticked rope: the dog circles three quarters round a pole close by, so
# the solver records a contact within the first few points from her end. Past
# a contact the rope runs the other way round the pole, so the pull keeps the
# rope's own first segment, exactly as before the weighted tangent existed.
func _check_contact_in_run() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	var poles: Array[Vector2] = [Vector2.ZERO]
	var radius := 26.0
	dog.global_position = Vector2(0, radius)
	human.global_position = Vector2(0, 230)
	leash.setup(dog, human, poles, 270.0)
	var frames := 90
	for f in range(frames):
		var a: float = PI * 0.5 - TAU * 0.75 * float(f + 1) / frames
		dog.global_position = Vector2.from_angle(a) * radius
		leash.tick(1.0 / 60.0)
	for _f in range(10):
		leash.tick(1.0 / 60.0)
	var first := -1
	for i in range(1, 4):
		if leash._touch[i] >= 0:
			first = i
			break
	_check(first >= 1, "fixture: the ticked rope touches the pole within three segments of the dog")
	var single: Vector2 = (leash.pts[1] - leash.pts[0]).normalized()
	var pull: Vector2 = leash.dog_pull_dir()
	var off := absf(single.angle_to(pull))
	print("contact in run: first contact %d, pull off first segment by %.6f rad" % [first, off])
	_check(off < 0.0001,
		"a contact within the run keeps the single first-segment pull (off by %.6f rad)" % off)
	leash.free()
	dog.free()
	human.free()


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
	_check_contact_in_run()
	if failures > 0:
		print("test_leash_weighted_tangent: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_weighted_tangent: OK")
		quit(0)
