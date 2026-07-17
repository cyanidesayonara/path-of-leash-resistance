extends SceneTree

# Regression for the passive combo/multiplier meter (combo.gd):
#  1. a lone trick never banks (no multiplier)
#  2. two+ tricks in the window bank once, score = points x links
#  3. a new trick refreshes the window (the chain survives)
#  4. a bail drops the chain with nothing banked
#  5. the bones bonus scales with the multiplier and caps
# Pure logic, driven by add()/tick() with no rendering.

const DT := 1.0 / 60.0
const ComboScript := preload("res://combo.gd")


class StubMain extends Node2D:
	var banks: Array = []
	func on_combo_banked(score: int, mult: int, bonus: int) -> void:
		banks.append({"score": score, "mult": mult, "bonus": bonus})


func _tick(c, seconds: float) -> void:
	var n := int(round(seconds / DT))
	for i in range(n):
		c.tick(DT)


func _initialize() -> void:
	var failures := 0

	# 1) a single trick, then let the window lapse -> no bank
	var m := StubMain.new()
	var c = ComboScript.new()
	c.setup(m)
	c.add("SNIFF", 2)
	_tick(c, 4.0)
	if m.banks.size() != 0:
		print("FAIL: a lone trick should not bank, got %d" % m.banks.size())
		failures += 1
	if c.active():
		print("FAIL: chain should be dead after the window")
		failures += 1

	# 2) two tricks inside the window -> one bank, score = (2+3)*2 = 10
	var m2 := StubMain.new()
	var c2 = ComboScript.new()
	c2.setup(m2)
	c2.add("SNIFF", 2)
	_tick(c2, 1.0)
	c2.add("MARK", 3)
	if c2.mult() != 2:
		print("FAIL: multiplier should be 2, got %d" % c2.mult())
		failures += 1
	_tick(c2, 4.0)
	if m2.banks.size() != 1:
		print("FAIL: expected exactly one bank, got %d" % m2.banks.size())
		failures += 1
	elif m2.banks[0].score != 10 or m2.banks[0].mult != 2:
		print("FAIL: bank should be score 10 x2, got %s" % m2.banks[0])
		failures += 1
	if c2.best_mult != 2 or c2.run_style != 10:
		print("FAIL: run totals wrong (best=%d style=%d)" % [c2.best_mult, c2.run_style])
		failures += 1

	# 3) a trick just before the window closes refreshes it -> chain lives
	var m3 := StubMain.new()
	var c3 = ComboScript.new()
	c3.setup(m3)
	c3.add("SNIFF", 2)
	_tick(c3, 3.0)  # under WINDOW (3.2)
	if not c3.active():
		print("FAIL: chain should still be alive just under the window")
		failures += 1
	c3.add("MARK", 3)  # refresh
	_tick(c3, 3.0)
	c3.add("FLING", 8)
	if c3.mult() != 3:
		print("FAIL: refreshed chain should reach x3, got %d" % c3.mult())
		failures += 1
	_tick(c3, 4.0)
	if m3.banks.size() != 1 or m3.banks[0].mult != 3 or m3.banks[0].score != 39:
		print("FAIL: refreshed chain should bank x3 score 39, got %s" % m3.banks)
		failures += 1

	# 4) a bail drops the chain, nothing banked
	var m4 := StubMain.new()
	var c4 = ComboScript.new()
	c4.setup(m4)
	c4.add("SNIFF", 2)
	c4.add("MARK", 3)
	c4.bail()
	if c4.active() or c4.mult() != 0:
		print("FAIL: bail should clear the chain")
		failures += 1
	_tick(c4, 4.0)
	if m4.banks.size() != 0:
		print("FAIL: a bailed chain must never bank, got %d" % m4.banks.size())
		failures += 1

	# 5) the bonus curve: scales with the multiplier, capped at 40
	if ComboScript.bonus_for(1) != 0:
		print("FAIL: x1 should pay no bonus")
		failures += 1
	if ComboScript.bonus_for(2) != 2 or ComboScript.bonus_for(3) != 6 or ComboScript.bonus_for(5) != 20:
		print("FAIL: bonus curve wrong (x2=%d x3=%d x5=%d)" % [ComboScript.bonus_for(2), ComboScript.bonus_for(3), ComboScript.bonus_for(5)])
		failures += 1
	if ComboScript.bonus_for(9) != 40:
		print("FAIL: bonus should cap at 40, got %d" % ComboScript.bonus_for(9))
		failures += 1

	if failures > 0:
		print("test_combo: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_combo: OK")
		quit(0)
