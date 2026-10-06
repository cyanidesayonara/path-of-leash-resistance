extends SceneTree

# Regression for the combo/multiplier meter (combo.gd), tricks-only:
#  1. business alone (sniffs, marks) never starts a chain
#  2. a lone trick never banks (no multiplier)
#  3. two tricks in the window bank once, score = points x links
#  4. business inside a live chain adds its points and keeps it alive, but
#     never raises the multiplier
#  5. a bail drops the chain with nothing banked
#  6. the bones bonus scales with the multiplier and caps
#  7. the main game hears every score, and can change a trick's points
#     (golden zoomies double them)
# Pure logic, driven by add()/tick() with no rendering.

const DT := 1.0 / 60.0
const ComboScript := preload("res://systems/combo.gd")


class StubMain extends Node2D:
	var banks: Array = []
	var heard: Array = []
	var double := false
	func on_combo_banked(score: int, mult: int, bonus: int) -> void:
		banks.append({"score": score, "mult": mult, "bonus": bonus})
	func on_scored(label: String, pts: int, trick: bool) -> int:
		heard.append([label, trick])
		return pts * 2 if double and trick else pts


var failures := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)


func _tick(c, seconds: float) -> void:
	for i in range(int(round(seconds / DT))):
		c.tick(DT)


func _fresh() -> Array:
	var m := StubMain.new()
	var c = ComboScript.new()
	c.setup(m)
	return [m, c]


func _initialize() -> void:
	# 1) business alone never starts a chain
	var p1 := _fresh()
	p1[1].add("SNIFF", 2)
	p1[1].add("MARK", 3)
	_check(not p1[1].active() and p1[1].mult() == 0, "sniffing and marking is not a combo")
	_tick(p1[1], 5.0)
	_check(p1[0].banks.is_empty(), "and banks nothing")

	# 2) a lone trick never banks
	var p2 := _fresh()
	p2[1].add("FLING", 30)
	_check(p2[1].active() and p2[1].mult() == 1, "a trick starts a chain")
	_tick(p2[1], 5.0)
	_check(p2[0].banks.is_empty(), "a lone trick does not bank")

	# 3) two tricks bank once: (30 + 20) x 2
	var p3 := _fresh()
	p3[1].add("FLING", 30)
	_tick(p3[1], 1.0)
	p3[1].add("POLE SWING", 20)
	_check(p3[1].mult() == 2, "two tricks make x2")
	_tick(p3[1], 5.0)
	_check(p3[0].banks.size() == 1 and p3[0].banks[0].score == 100 and p3[0].banks[0].mult == 2,
		"they bank once, points x links (got %s)" % [p3[0].banks])
	_check(p3[1].best_mult == 2 and p3[1].run_style == 100, "run totals kept")

	# 4) business keeps a live chain going and adds points, never links
	var p4 := _fresh()
	p4[1].add("HEDGE RUN", 40)
	_tick(p4[1], 3.5)
	p4[1].add("SNIFF", 2)        # refreshes the window, no new link
	_check(p4[1].mult() == 1, "business never raises the multiplier")
	_tick(p4[1], 3.5)
	_check(p4[1].active(), "but it keeps the chain alive")
	p4[1].add("BALANCE", 4)
	_tick(p4[1], 5.0)
	_check(p4[0].banks.size() == 1 and p4[0].banks[0].mult == 2 and p4[0].banks[0].score == 92,
		"banked x2 on 40 + 2 + 4 (got %s)" % [p4[0].banks])

	# 5) a bail drops the chain
	var p5 := _fresh()
	p5[1].add("FLING", 30)
	p5[1].add("WALL WALK", 20)
	p5[1].bail()
	_check(not p5[1].active() and p5[1].mult() == 0, "a bail clears the chain")
	_tick(p5[1], 5.0)
	_check(p5[0].banks.is_empty(), "and it never banks")

	# 6) the bonus curve
	_check(ComboScript.bonus_for(1) == 0, "x1 pays no bonus")
	_check(ComboScript.bonus_for(2) == 2 and ComboScript.bonus_for(3) == 6 and ComboScript.bonus_for(5) == 20,
		"the bonus scales with the multiplier")
	_check(ComboScript.bonus_for(9) == 40, "and caps at 40")

	# 7) the main game hears everything and can double a trick
	var p7 := _fresh()
	p7[0].double = true
	p7[1].add("SNIFF", 2)
	p7[1].add("FLING", 30)
	p7[1].add("SNIFF", 2)
	_check(p7[0].heard.size() == 3 and p7[0].heard[0][1] == false and p7[0].heard[1][1] == true,
		"every score is heard, tricks told apart from business")
	_check(p7[1].points == 62, "a doubled trick counts double, business does not (got %d)" % p7[1].points)
	for t: String in ["LEDGE RUN", "HEDGE RUN", "BENCH GRIND", "WALL WALK", "HANDRAIL"]:
		_check(ComboScript.is_trick(t), "%s is a trick" % t)
	for b: String in ["SNIFF", "MARK", "HELLO", "SNACK", "DIG"]:
		_check(not ComboScript.is_trick(b), "%s is business" % b)

	if failures > 0:
		print("test_combo: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_combo: OK")
		quit(0)
