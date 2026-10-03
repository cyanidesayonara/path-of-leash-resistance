extends SceneTree

const Leash = preload("res://entities/leash.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	var leash := Leash.new()
	var dog := Node2D.new()
	var human := Node2D.new()
	root.add_child(leash)
	root.add_child(dog)
	root.add_child(human)

	dog.global_position = Vector2(20, 40)
	human.global_position = Vector2(260, -80)
	leash.setup(dog, human, [], 260.0)

	dog.global_position = Vector2(-75, 125)
	human.global_position = Vector2(405, -115)
	leash.setup(dog, human, [], 320.0)

	_check(leash.pts.size() == Leash.N,
			"repeated setup keeps %d current points (got %d)" % [Leash.N, leash.pts.size()])
	_check(leash.prev.size() == Leash.N,
			"repeated setup keeps %d previous points (got %d)" % [Leash.N, leash.prev.size()])

	var laid_between_current_endpoints := true
	for i in range(Leash.N):
		var expected := dog.global_position.lerp(
				human.global_position, float(i) / (Leash.N - 1))
		var current: Vector2 = leash.pts[i]
		var previous: Vector2 = leash.prev[i]
		laid_between_current_endpoints = laid_between_current_endpoints \
				and current.is_finite() and previous.is_finite() \
				and current.is_equal_approx(expected) \
				and previous.is_equal_approx(expected)
	_check(laid_between_current_endpoints,
			"repeated setup exactly interpolates finite current and previous points")

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_leash_setup: OK")
		quit(0)
	else:
		quit(1)
