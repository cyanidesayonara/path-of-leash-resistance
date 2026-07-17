extends SceneTree

# Regression for the "bring Tofu home" herding quest (tofu.gd):
#  1. left alone, Tofu holds her hiding spot (no free progress)
#  2. an approaching dog makes her dart to the NEXT spot south
#  3. herding her down the whole chain reports home exactly once, at HOME
# Runs headless by driving _physics_process directly (no rendering).

const DT := 1.0 / 60.0
const TofuScript := preload("res://tofu.gd")


class StubMain extends Node2D:
	var phase := "home"
	var frozen := false
	var home_calls := 0
	var home_pos := Vector2.ZERO
	func on_tofu_home(pos: Vector2) -> void:
		home_calls += 1
		home_pos = pos


func _spots() -> Array[Vector2]:
	# a north -> south chain, home (last) at the bottom
	var s: Array[Vector2] = []
	for i in range(7):
		s.append(Vector2(640.0 + (60.0 if i % 2 == 0 else -60.0), -600.0 + i * 130.0))
	return s


func _initialize() -> void:
	var failures := 0
	var spots := _spots()

	# 1) dog far away -> Tofu stays put on her first spot, never goes home
	var m := StubMain.new()
	var dog := Node2D.new()
	dog.position = Vector2(640.0, 900.0)  # nowhere near
	var tofu = TofuScript.new()
	tofu.setup(m, dog, spots)
	for i in range(180):
		tofu._physics_process(DT)
	if tofu.idx != 0 or tofu.home:
		print("FAIL: unpressed Tofu should hold spot 0 (idx=%d home=%s)" % [tofu.idx, tofu.home])
		failures += 1
	if m.home_calls != 0:
		print("FAIL: Tofu should not go home unattended, got %d calls" % m.home_calls)
		failures += 1

	# 2) dog closes in -> Tofu darts to the next spot (further south)
	var m2 := StubMain.new()
	var dog2 := Node2D.new()
	var tofu2 = TofuScript.new()
	tofu2.setup(m2, dog2, spots)
	var y0: float = tofu2.position.y
	dog2.position = spots[0] + Vector2(10.0, 0.0)  # within FLEE_R
	for i in range(60):
		tofu2._physics_process(DT)
	if tofu2.idx != 1:
		print("FAIL: pressed Tofu should advance to spot 1, idx=%d" % tofu2.idx)
		failures += 1
	if tofu2.position.y <= y0:
		print("FAIL: Tofu should move south when pressed (y %.1f -> %.1f)" % [y0, tofu2.position.y])
		failures += 1

	# 3) relentless chase down the whole chain -> home exactly once, at HOME
	var m3 := StubMain.new()
	var dog3 := Node2D.new()
	var tofu3 = TofuScript.new()
	tofu3.setup(m3, dog3, spots)
	for i in range(1200):
		dog3.position = tofu3.position  # sit right on her every frame
		tofu3._physics_process(DT)
		if tofu3.home:
			break
	if not tofu3.home:
		print("FAIL: relentless herding should bring Tofu home")
		failures += 1
	if m3.home_calls != 1:
		print("FAIL: expected exactly one home call, got %d" % m3.home_calls)
		failures += 1
	if m3.home_pos.distance_to(spots[spots.size() - 1]) > 8.0:
		print("FAIL: Tofu should report home at the last spot, got %s" % m3.home_pos)
		failures += 1

	if failures > 0:
		print("test_tofu_home: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_tofu_home: OK")
		quit(0)
