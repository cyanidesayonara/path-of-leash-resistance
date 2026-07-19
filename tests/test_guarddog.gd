extends SceneTree

# Regression for the El Desguas guard dog (guarddog.gd):
#  1. a slow creep right past it does NOT wake it (slow is silent)
#  2. a fast mover nearby wakes it, reported exactly once per incident
#  3. noise (bark / phone) within earshot wakes it; out of earshot doesn't
#  4. the alert decays and it goes back to sleep - and can be woken again
# Pure logic, driven by _physics_process with no rendering.

const DT := 1.0 / 60.0
const GuardScript := preload("res://guarddog.gd")


class StubMain extends Node2D:
	var frozen := false
	var wakes := 0
	func on_guard_woken(_pos: Vector2) -> void:
		wakes += 1


class StubDog extends Node2D:
	var velocity := Vector2.ZERO


func _tick(g, seconds: float) -> void:
	for i in range(int(round(seconds / DT))):
		g._physics_process(DT)


func _initialize() -> void:
	var failures := 0

	# 1) creeping past at a walk: close, but slow = silent
	var m := StubMain.new()
	var dog := StubDog.new()
	var g = GuardScript.new()
	g.position = Vector2(400, -1300)
	g.setup(m, dog)
	dog.position = g.position + Vector2(40, 0)  # well inside WAKE_R
	dog.velocity = Vector2(60, 0)               # under FAST
	_tick(g, 2.0)
	if not g.asleep or m.wakes != 0:
		print("FAIL: a slow creep should not wake the guard (wakes=%d)" % m.wakes)
		failures += 1

	# 2) sprinting past wakes it, once
	dog.velocity = Vector2(300, 0)
	_tick(g, 0.5)
	if g.asleep or m.wakes != 1:
		print("FAIL: a fast mover should wake it exactly once (wakes=%d)" % m.wakes)
		failures += 1
	_tick(g, 0.5)  # still fast, still nearby: same incident, no double count
	if m.wakes != 1:
		print("FAIL: one incident must count once (wakes=%d)" % m.wakes)
		failures += 1

	# 3) noise wakes within earshot only
	var m2 := StubMain.new()
	var dog2 := StubDog.new()
	dog2.position = Vector2(0, 900)
	var g2 = GuardScript.new()
	g2.position = Vector2(400, -1300)
	g2.setup(m2, dog2)
	g2.hear_noise(g2.position + Vector2(400, 0), 250.0)  # too far
	if not g2.asleep:
		print("FAIL: noise out of earshot should not wake it")
		failures += 1
	g2.hear_noise(g2.position + Vector2(180, 0), 250.0)  # in earshot
	if g2.asleep or m2.wakes != 1:
		print("FAIL: noise in earshot should wake it (wakes=%d)" % m2.wakes)
		failures += 1

	# 4) it settles back to sleep, and a new incident counts again
	var far := Vector2(0, 900)
	dog2.position = far
	dog2.velocity = Vector2.ZERO
	_tick(g2, 4.0)  # ALERT_T is 3.0
	if not g2.asleep:
		print("FAIL: the guard should settle back to sleep")
		failures += 1
	g2.hear_noise(g2.position + Vector2(100, 0), 250.0)
	if m2.wakes != 2:
		print("FAIL: a fresh incident should count again (wakes=%d)" % m2.wakes)
		failures += 1

	if failures > 0:
		print("test_guarddog: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_guarddog: OK")
		quit(0)
