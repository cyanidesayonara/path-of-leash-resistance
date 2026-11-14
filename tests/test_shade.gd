extends SceneTree

# The one light (systems/shade.gd): by day shadows fall exactly as the old
# constant did; after dark they keep the same lean but only a short pool.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	Shade.set_night(false)
	_check(Shade.light == Vector2(0.5, 0.866), "by day the light is the old sun constant exactly")
	_check(Shade.throw == 1.0, "by day shadows are thrown full length")
	Shade.set_night(true)
	_check(Shade.light.length() < 0.3, "at night shadows are short pools")
	_check(Shade.light.length() > 0.1, "at night objects still keep a contact shadow")
	_check(absf(Shade.light.angle() - Shade.SUN.angle()) < 0.001, "at night the pool leans the same way, so nothing jumps")
	_check(Shade.throw < 0.3, "scripts with their own sun shorten by the same throw")
	Shade.set_night(false)
	_check(Shade.light == Shade.SUN, "day restores the full sun")
	print("%d checks, %d failures" % [checks, failures.size()])
	print("test_shade: " + ("OK" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
