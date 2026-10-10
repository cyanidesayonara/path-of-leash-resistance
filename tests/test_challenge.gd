extends SceneTree

# Regression for the combo challenge (challenge.gd, Combo Phase B):
#  1. hitting the target early wins immediately and reports once
#  2. running out of time loses, reporting the partial count
#  3. tricks after it resolves are ignored
#  4. the window fraction drains from 1 to 0
#  5. an offer is read before the clock starts: tricks during it do not
#     count, the clock starts after OFFER_S, and the card stays up END_S
#     after the result
# Pure logic, driven by begin()/add_trick()/tick().

const DT := 1.0 / 60.0
const ChallengeScript := preload("res://systems/challenge.gd")


class StubMain extends Node2D:
	var results: Array = []
	func on_challenge_done(win: bool, target: int, count: int) -> void:
		results.append({"win": win, "target": target, "count": count})


func _tick(c, seconds: float) -> void:
	for i in range(int(round(seconds / DT))):
		c.tick(DT)


func _initialize() -> void:
	var failures := 0

	# 1) reach the target before time runs out -> one win
	var m := StubMain.new()
	var c = ChallengeScript.new()
	c.setup(m)
	c.begin(3, 10.0)
	c.add_trick()
	c.add_trick()
	if c.done:
		print("FAIL: should not be done at 2/3")
		failures += 1
	c.add_trick()
	if not c.done or not c.succeeded:
		print("FAIL: hitting the target should win")
		failures += 1
	if m.results.size() != 1 or not m.results[0].win or m.results[0].count != 3:
		print("FAIL: win should report once with count 3, got %s" % str(m.results))
		failures += 1

	# 2) run out of time short of the target -> lose with the partial count
	var m2 := StubMain.new()
	var c2 = ChallengeScript.new()
	c2.setup(m2)
	c2.begin(5, 8.0)
	c2.add_trick()
	c2.add_trick()
	_tick(c2, 9.0)
	if not c2.done or c2.succeeded:
		print("FAIL: timing out should lose")
		failures += 1
	if m2.results.size() != 1 or m2.results[0].win or m2.results[0].count != 2:
		print("FAIL: loss should report once with count 2, got %s" % str(m2.results))
		failures += 1

	# 3) tricks after resolution are ignored (no second report)
	var m3 := StubMain.new()
	var c3 = ChallengeScript.new()
	c3.setup(m3)
	c3.begin(1, 5.0)
	c3.add_trick()  # instant win
	c3.add_trick()  # should do nothing
	_tick(c3, 6.0)  # should not re-fire on timeout
	if m3.results.size() != 1:
		print("FAIL: a resolved challenge must report exactly once, got %d" % m3.results.size())
		failures += 1

	# 4) the window fraction drains 1 -> 0
	var m4 := StubMain.new()
	var c4 = ChallengeScript.new()
	c4.setup(m4)
	c4.begin(9, 10.0)
	if absf(c4.fraction() - 1.0) > 0.001:
		print("FAIL: fraction should start at 1.0, got %.3f" % c4.fraction())
		failures += 1
	_tick(c4, 5.0)
	if absf(c4.fraction() - 0.5) > 0.02:
		print("FAIL: fraction should be ~0.5 at half time, got %.3f" % c4.fraction())
		failures += 1

	# 5) the offer's telegraph, then the clock, then the result card
	var m5 := StubMain.new()
	var c5 = ChallengeScript.new()
	c5.setup(m5)
	c5.offer(2, 6.0, 35, false)
	c5.add_trick()
	if c5.phase != "offer" or c5.active or c5.count != 0 or not c5.showing():
		print("FAIL: a trick during the offer must not count (phase %s, count %d)" % [c5.phase, c5.count])
		failures += 1
	_tick(c5, c5.OFFER_S * 0.5)
	if c5.phase != "offer" or absf(c5.timer - 6.0) > 0.001:
		print("FAIL: the clock must not run during the offer (timer %.2f)" % c5.timer)
		failures += 1
	_tick(c5, c5.OFFER_S * 0.5 + 0.05)
	if c5.phase != "live" or not c5.active or c5.reward != 35:
		print("FAIL: the clock starts after the offer, keeping its reward (%s, %d)" % [c5.phase, c5.reward])
		failures += 1
	c5.add_trick()
	c5.add_trick()
	if c5.phase != "end" or not c5.succeeded or not c5.showing():
		print("FAIL: a win shows its result card")
		failures += 1
	_tick(c5, c5.END_S + 0.1)
	if c5.showing():
		print("FAIL: the result card goes after END_S")
		failures += 1

	if failures > 0:
		print("test_challenge: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_challenge: OK")
		quit(0)
