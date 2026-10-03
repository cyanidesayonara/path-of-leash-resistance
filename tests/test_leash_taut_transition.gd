extends SceneTree

# The first few pixels beyond rest length need one continuous amount that
# presentation and force can consume. Integration is pinned once those callers
# exist; this RED test defines only the narrow public value contract.

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _initialize() -> void:
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(leash)
	_check(leash.has_method("taut_amount"),
		"leash exposes one taut_amount(stretch_ratio) transition value")
	if leash.has_method("taut_amount"):
		var samples: Array[float] = []
		for i in range(11):
			var ratio := 1.0 + float(i) * 0.005
			samples.append(float(leash.taut_amount(ratio)))
		_check(samples[0] <= 0.001, "taut amount is zero at rest (got %.3f)" % samples[0])
		_check(samples[-1] >= 0.99,
			"taut amount reaches full value after the onset band (got %.3f)" % samples[-1])
		var strict_steps := 0
		for i in range(1, samples.size()):
			_check(samples[i] + 0.0001 >= samples[i - 1],
				"taut amount is monotonic at sample %d (%.3f after %.3f)" % [
					i, samples[i], samples[i - 1]])
			if samples[i] > samples[i - 1] + 0.01:
				strict_steps += 1
			_check(samples[i] >= -0.001 and samples[i] <= 1.001,
				"taut amount remains normalized at sample %d (got %.3f)" % [i, samples[i]])
		_check(strict_steps >= 3,
			"taut onset progresses across several samples, not one binary step (%s)" % samples)
		_check(samples[5] > 0.05 and samples[5] < 0.95,
			"taut onset exposes an intermediate midpoint (got %.3f)" % samples[5])
	leash.free()

	if failures > 0:
		print("test_leash_taut_transition: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_taut_transition: OK")
		quit(0)
