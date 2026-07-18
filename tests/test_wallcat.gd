extends SceneTree

# Regression for the El Gotic wall cat (wallcat.gd):
#  1. a bark scares it exactly once (no double-scoring)
#  2. it arches as the dog closes in, relaxes as the dog leaves
# Pure logic, driven by scare()/_physics_process with no rendering.

const DT := 1.0 / 60.0
const WallcatScript := preload("res://wallcat.gd")


class StubMain extends Node2D:
	var frozen := false
	var spooks := 0
	func on_wallcat_spooked(_pos: Vector2) -> void:
		spooks += 1


func _initialize() -> void:
	var failures := 0

	# 1) scaring twice only scores once
	var m := StubMain.new()
	var dog := Node2D.new()
	dog.position = Vector2(500, 500)
	var wc = WallcatScript.new()
	wc.position = Vector2(360, -900)
	wc.setup(m, dog, -1.0)
	wc.scare()
	wc.scare()
	if not wc.spooked:
		print("FAIL: cat should be spooked after a scare")
		failures += 1
	if m.spooks != 1:
		print("FAIL: a wall cat must score exactly once, got %d" % m.spooks)
		failures += 1

	# 2) arches toward 1 with the dog near, relaxes toward 0 when far
	var m2 := StubMain.new()
	var dog2 := Node2D.new()
	var wc2 = WallcatScript.new()
	wc2.position = Vector2(920, -1450)
	wc2.setup(m2, dog2, 1.0)
	dog2.position = wc2.position + Vector2(20, 0)  # within NOTICE_R
	for i in range(60):
		wc2._physics_process(DT)
	if wc2.arch < 0.7:
		print("FAIL: cat should arch up near the dog, arch=%.2f" % wc2.arch)
		failures += 1
	dog2.position = wc2.position + Vector2(600, 0)  # far away
	for i in range(60):
		wc2._physics_process(DT)
	if wc2.arch > 0.3:
		print("FAIL: cat should relax when the dog leaves, arch=%.2f" % wc2.arch)
		failures += 1

	if failures > 0:
		print("test_wallcat: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_wallcat: OK")
		quit(0)
