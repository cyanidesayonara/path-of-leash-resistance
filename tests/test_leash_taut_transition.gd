extends SceneTree

# The first few pixels beyond rest length need a continuous onset for both
# visible cinching and force. A bool threshold cannot represent that ramp.

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _check_ramp(leash: Node2D, method: String, label: String) -> void:
	_check(leash.has_method(method), "leash exposes %s(stretch_ratio)" % method)
	if not leash.has_method(method):
		return
	var slack: float = float(leash.call(method, 1.0))
	var middle: float = float(leash.call(method, 1.025))
	var taut: float = float(leash.call(method, 1.05))
	_check(slack <= 0.001, "%s is zero at rest (got %.3f)" % [label, slack])
	_check(middle > 0.05 and middle < 0.95,
		"%s exposes an intermediate onset value (got %.3f)" % [label, middle])
	_check(taut >= 0.99, "%s reaches full value after the onset band (got %.3f)" % [label, taut])


func _initialize() -> void:
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(leash)
	_check_ramp(leash, "taut_visual_amount", "taut presentation")
	_check_ramp(leash, "tension_onset_amount", "tension onset")
	leash.free()

	if failures > 0:
		print("test_leash_taut_transition: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_taut_transition: OK")
		quit(0)
