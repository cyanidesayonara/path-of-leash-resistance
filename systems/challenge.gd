extends Node

# Combo Phase B: a self-contained, optional combo CHALLENGE handed out by
# a character on the walk. It is a bounded window with a target number of
# tricks - land them in time and it pays out. The walk itself stays
# time-free; only the challenge has a clock, and failing costs nothing.

var main: Node2D
var active := false
var done := false
var succeeded := false
var target := 0
var count := 0
var timer := 0.0
var duration := 0.0


func setup(m: Node2D) -> void:
	main = m


func begin(trick_target: int, seconds: float) -> void:
	active = true
	done = false
	succeeded = false
	target = maxi(1, trick_target)
	count = 0
	duration = maxf(0.1, seconds)
	timer = duration


func add_trick() -> void:
	if not active:
		return
	count += 1
	if count >= target:
		_finish(true)


func tick(delta: float) -> void:
	if not active:
		return
	timer -= delta
	if timer <= 0.0:
		timer = 0.0
		_finish(false)


func fraction() -> float:
	return clampf(timer / duration, 0.0, 1.0) if duration > 0.0 else 0.0


func _finish(win: bool) -> void:
	active = false
	done = true
	succeeded = win
	if main != null:
		main.on_challenge_done(win, target, count)
