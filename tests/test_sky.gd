extends SceneTree

# The sky is a pure function of the walk, the weather and the hour. A clear
# day changes nothing, so the shipped grade stays the shipped grade. Night
# and rain stack. A lamp colour is divided back out of the tint, so it still
# reads as light once the world multiplies it.

const SkyLook := preload("res://systems/sky.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var day := SkyLook.tint("barri", "clear", false)
	_check(day.is_equal_approx(Color.WHITE), "a clear day is white (%s)" % day)
	var mod: Dictionary = SkyLook.grade_mod("barri", "clear", false)
	_check(is_equal_approx(float(mod["k_sat"]), 1.0) and is_equal_approx(float(mod["wet"]), 0.0),
		"a clear day leaves the grade alone")
	var happy := {
		"sat": 1.12, "con": 1.05, "vig": 0.26, "tight": 1.6, "exp": 1.00,
		"lift": 0.055, "tint": Vector3.ONE,
		"cool": Vector3(0.90, 0.95, 1.09), "warm": Vector3(1.07, 1.01, 0.93),
	}
	var got: Dictionary = SkyLook.compose(happy, mod)
	_check(is_equal_approx(float(got["sat"]), 1.12) and is_equal_approx(float(got["vig"]), 0.26) \
			and is_equal_approx(float(got["wet"]), 0.0),
		"composing a clear day keeps the mood's grade")

	var night := SkyLook.tint("street", "clear", true)
	_check(night.b > night.r and night.r < 0.6, "night is blue (%s)" % night)
	var lamp := SkyLook.light(Color(1.0, 0.90, 0.62), night)
	_check(lamp.r > 1.0 and lamp.g > 1.0 and lamp.a == 1.0, "a lamp is pushed back above the night tint (%s)" % lamp)
	var brought := Color(lamp.r * night.r, lamp.g * night.g, lamp.b * night.b)
	_check(is_equal_approx(brought.r, 1.0) and is_equal_approx(brought.g, 0.90),
		"the lamp times the tint comes back to the warm colour")

	var rain := SkyLook.grade_mod("barri", "rain", false)
	var both := SkyLook.grade_mod("barri", "rain", true)
	_check(is_equal_approx(float(rain["wet"]), 1.0), "rain wets the grade")
	_check(float(both["k_sat"]) < float(rain["k_sat"]) and is_equal_approx(float(both["wet"]), 1.0),
		"night stacks on rain and the wet stays")
	_check(float(both["add_vig"]) > float(rain["add_vig"]), "night adds vignette on top of the rain")

	var dawn := SkyLook.tint("neteja", "clear", false)
	_check(dawn.r > dawn.b and not dawn.is_equal_approx(Color.WHITE), "La Neteja's day is dawn (%s)" % dawn)
	var dawn_night := SkyLook.tint("neteja", "clear", true)
	_check(dawn_night.b > dawn_night.r, "La Neteja after dark is night, not dawn (%s)" % dawn_night)
	_check(SkyLook.tint("park", "snow", false).b > 1.0, "snow light runs cold")

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_sky: OK")
		quit(0)
	else:
		quit(1)
