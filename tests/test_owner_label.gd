extends SceneTree

var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _initialize() -> void:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	if not main.has_method("_owner_label_text"):
		_check(false, "main exposes owner label formatter")
	else:
		_check(main._owner_label_text("him") == "WALKING:  HIM", "formats him")
		_check(main._owner_label_text("her") == "WALKING:  HER", "formats her")
		_check(main._owner_label_text("HeR") == "WALKING:  HER", "normalizes casing")
	main.free()
	if failures > 0:
		print("test_owner_label: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_owner_label: OK")
		quit(0)
