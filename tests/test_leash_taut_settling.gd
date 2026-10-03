extends SceneTree

# A taut rope may settle from a disturbed shape, but its interior points must
# not keep reversing direction frame to frame after the initial damping pass.

const DT := 1.0 / 60.0
const REST_LEN := 260.0
const ENDPOINT_SPAN := REST_LEN * 1.15
const SETTLE_FRAMES := 10
const SAMPLE_FRAMES := 120
# 0.04px is below a visible sub-pixel buzz while retaining a 15% margin from
# the 0.0468px baseline failure, far larger than platform float variation.
const MAX_REVERSAL_STEP := 0.04
const MIN_EXCITATION_STEP := 10.0

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
	dog.global_position = Vector2(-ENDPOINT_SPAN * 0.5, 0)
	human.global_position = Vector2(ENDPOINT_SPAN * 0.5, 0)
	var no_poles: Array[Vector2] = []
	leash.setup(dog, human, no_poles, REST_LEN)

	# Disturb every interior point while the endpoints hold at the gameplay
	# geometry cap, then let the real solver damp the disturbance.
	for i in range(1, leash.N - 1):
		leash.pts[i].y += 18.0 if i % 2 == 0 else -18.0
		leash.prev[i] = leash.pts[i]
	var previous: Array[Vector2] = leash.pts.duplicate()
	var excitation_step := 0.0
	for _i in range(SETTLE_FRAMES):
		leash.tick(DT)
		var current: Array[Vector2] = leash.pts.duplicate()
		for i in range(1, leash.N - 1):
			excitation_step = maxf(excitation_step, current[i].distance_to(previous[i]))
		previous = current

	var previous_steps: Array[Vector2] = []
	previous_steps.resize(leash.N)
	var max_reversal_step := 0.0
	var reversals := 0
	for _frame in range(SAMPLE_FRAMES):
		leash.tick(DT)
		var current: Array[Vector2] = leash.pts.duplicate()
		for i in range(1, leash.N - 1):
			var step: Vector2 = current[i] - previous[i]
			if step.dot(previous_steps[i]) < 0.0:
				reversals += 1
				max_reversal_step = maxf(
					max_reversal_step, minf(step.length(), previous_steps[i].length()))
			previous_steps[i] = step
		previous = current
	var span_ratio: float = dog.global_position.distance_to(human.global_position) / REST_LEN
	print("taut settling: ratio %.3f excitation %.3fpx reversals %d max %.6fpx" % [
		span_ratio, excitation_step, reversals, max_reversal_step])
	_check(span_ratio <= leash.STRETCH_CAP + 0.0001,
		"settling fixture stays within the %.2fx gameplay cap (got %.3f)" % [
			leash.STRETCH_CAP, span_ratio])
	_check(excitation_step >= MIN_EXCITATION_STEP,
		"disturbed rope genuinely moves before jitter sampling (max %.3fpx)" % excitation_step)
	_check(max_reversal_step <= MAX_REVERSAL_STEP,
		"oscillatory interior jitter stays below %.2fpx/frame (got %.6f)" % [
			MAX_REVERSAL_STEP, max_reversal_step])

	leash.free()
	dog.free()
	human.free()
	if failures > 0:
		print("test_leash_taut_settling: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_taut_settling: OK")
		quit(0)
