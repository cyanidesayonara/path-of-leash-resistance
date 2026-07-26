extends SceneTree

# Regression for the teeter/balance moment (teeter.gd):
#  1. do nothing and you fall in
#  2. scramble away and you recover - and it resolves exactly once
#  3. the save window is winnable but not trivial: a HALF-hearted scramble
#     still loses, a committed one wins (this is the fun/fair line)
#  4. a late scramble can still rescue a deep lean (the hero recovery)
#  5. the meter reads 0 upright and rises as you tip

const DT := 1.0 / 60.0
const TeeterScript := preload("res://teeter.gd")


func _run(counter: float, seconds := 3.0) -> Dictionary:
	var tt = TeeterScript.new()
	tt.begin()
	var out := ""
	var steps := 0
	for i in range(int(seconds / DT)):
		var r: String = tt.tick(DT, counter)
		steps += 1
		if r != "":
			out = r
			break
	return {"result": out, "steps": steps, "obj": tt}


func _initialize() -> void:
	var failures := 0

	# 1) stand there and you go in
	var idle: Dictionary = _run(0.0)
	if idle.result != "fell":
		print("FAIL: doing nothing should end in a fall, got '%s'" % idle.result)
		failures += 1

	# 2) commit to the scramble and you are saved, reported once
	var save: Dictionary = _run(1.0)
	if save.result != "saved":
		print("FAIL: a committed scramble should save you, got '%s'" % save.result)
		failures += 1
	var tt = save.obj
	if tt.active:
		print("FAIL: a resolved teeter should not still be active")
		failures += 1
	if tt.tick(DT, 1.0) != "":
		print("FAIL: a resolved teeter must not resolve twice")
		failures += 1

	# 3) the fun/fair line: half-hearted loses, committed wins
	var weak: Dictionary = _run(0.22)
	if weak.result != "fell":
		print("FAIL: a half-hearted scramble should not rescue you")
		failures += 1

	# 4) a LATE scramble can still save a deep lean - the hero recovery
	var late = TeeterScript.new()
	late.begin()
	var res := ""
	for i in range(int(2.5 / DT)):
		# flail for the first third of a second, then commit
		var c := 0.0 if i < int(0.34 / DT) else 1.0
		res = late.tick(DT, c)
		if res != "":
			break
	if res != "saved":
		print("FAIL: a late but committed scramble should still save you, got '%s'" % res)
		failures += 1

	# 5) the meter behaves
	var m = TeeterScript.new()
	m.begin()
	if absf(m.fraction()) > 0.001:
		print("FAIL: the meter should start upright")
		failures += 1
	for i in range(20):
		m.tick(DT, 0.0)
	if m.fraction() <= 0.0 or m.fraction() >= 1.0:
		print("FAIL: the meter should be mid-tip while teetering, got %.2f" % m.fraction())
		failures += 1
	if m.time_left() <= 0.0:
		print("FAIL: time_left should count down, not bottom out immediately")
		failures += 1

	if failures > 0:
		print("test_teeter: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_teeter: OK")
		quit(0)
