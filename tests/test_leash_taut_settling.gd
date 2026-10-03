extends SceneTree

# A highly stretched rope may settle from a disturbed shape, but after the
# initial damping window its interior points must not keep visibly buzzing.

const DT := 1.0 / 60.0
const SETTLE_FRAMES := 45
const SAMPLE_FRAMES := 120
const MAX_INTERIOR_STEP := 0.10

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
	dog.global_position = Vector2(-210, 0)
	human.global_position = Vector2(210, 0)
	var no_poles: Array[Vector2] = []
	leash.setup(dog, human, no_poles, 260.0)

	# Disturb every interior point while the endpoints hold the rope at more
	# than 1.6x rest length, then let the real solver damp the disturbance.
	for i in range(1, leash.N - 1):
		leash.pts[i].y += 30.0 if i % 2 == 0 else -30.0
		leash.prev[i] = leash.pts[i]
	for _i in range(SETTLE_FRAMES):
		leash.tick(DT)

	var previous: Array[Vector2] = leash.pts.duplicate()
	var max_step := 0.0
	for _frame in range(SAMPLE_FRAMES):
		leash.tick(DT)
		for i in range(1, leash.N - 1):
			max_step = maxf(max_step, leash.pts[i].distance_to(previous[i]))
		previous = leash.pts.duplicate()
	print("taut settling: max interior step %.6fpx" % max_step)
	_check(max_step <= MAX_INTERIOR_STEP,
		"high-tension interior jitter stays below %.2fpx/frame after settling (got %.3f)" % [
			MAX_INTERIOR_STEP, max_step])

	leash.free()
	dog.free()
	human.free()
	if failures > 0:
		print("test_leash_taut_settling: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_taut_settling: OK")
		quit(0)
