extends SceneTree

# Regression for the "bring Tofu home" herding quest (tofu.gd):
#  1. cornered on her mat, Tofu settles and reports home exactly once
#  2. an approaching dog makes her skitter AWAY (the herding lever)
#  3. she stays inside the park bounds
# Runs headless by driving _physics_process directly (no rendering).

const DT := 1.0 / 60.0
const TofuScript := preload("res://tofu.gd")


class StubMain extends Node2D:
	var phase := "freedom"
	var frozen := false
	var home_calls := 0
	var home_pos := Vector2.ZERO
	func on_tofu_home(pos: Vector2) -> void:
		home_calls += 1
		home_pos = pos


func _initialize() -> void:
	var failures := 0
	var bounds := Rect2(90.0, -600.0, 1100.0, 570.0)
	var mat := Vector2(700.0, -80.0)

	# 1) on the mat with the dog far away -> settles home once
	var m := StubMain.new()
	var dog := Node2D.new()
	dog.position = Vector2(700.0, -400.0)
	var tofu = TofuScript.new()
	tofu.setup(m, dog, mat, bounds)
	tofu.position = mat
	for i in range(200):
		tofu._physics_process(DT)
	if m.home_calls != 1:
		print("FAIL: expected exactly one home call, got %d" % m.home_calls)
		failures += 1
	if not tofu.home:
		print("FAIL: Tofu should be marked home")
		failures += 1

	# 2) dog approaching from the left -> Tofu flees right (away)
	var m2 := StubMain.new()
	var dog2 := Node2D.new()
	var tofu2 = TofuScript.new()
	tofu2.setup(m2, dog2, mat, bounds)
	tofu2.position = Vector2(600.0, -300.0)
	dog2.position = Vector2(560.0, -300.0)  # just left of Tofu, within FLEE_R
	var x0: float = tofu2.position.x
	for i in range(30):
		tofu2._physics_process(DT)
	if tofu2.position.x <= x0:
		print("FAIL: Tofu should flee away (right) from the dog (x %.1f -> %.1f)" % [x0, tofu2.position.x])
		failures += 1
	if m2.home_calls != 0:
		print("FAIL: Tofu should not go home while being chased away")
		failures += 1

	# 3) relentless chase never pushes her out of bounds
	var m3 := StubMain.new()
	var dog3 := Node2D.new()
	var tofu3 = TofuScript.new()
	tofu3.setup(m3, dog3, mat, bounds)
	tofu3.position = Vector2(150.0, -560.0)
	for i in range(240):
		# shove the dog onto her every frame from the inside
		dog3.position = tofu3.position + Vector2(20.0, 20.0)
		tofu3._physics_process(DT)
		if not bounds.grow(2.0).has_point(tofu3.position):
			print("FAIL: Tofu left the park bounds at %s" % tofu3.position)
			failures += 1
			break

	if failures > 0:
		print("test_tofu_home: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_tofu_home: OK")
		quit(0)
