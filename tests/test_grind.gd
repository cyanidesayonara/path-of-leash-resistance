extends SceneTree

# Regression for the kerb grind (grind.gd). This pins the FEEL, which is the
# part most likely to drift when someone retunes it later:
#  1. ignore the wobble and you bail
#  2. a competent rider holds it for a good while
#  3. it gets harder the longer you ride (the ramp is real, so a perfect
#     grind cannot be infinite)
#  4. longer rides are worth more per second (the length bonus)
#  5. landing banks the score once; a bail is reported once
#  6. the balance bar reads centred at the start

const DT := 1.0 / 60.0
const GrindScript := preload("res://grind.gd")


# a stand-in for a competent player: nudge against whichever way it is tipping
func _ride(seconds: float, skill: float) -> Dictionary:
	var g = GrindScript.new()
	g.begin()
	var held := 0.0
	var out := ""
	for i in range(int(seconds / DT)):
		# counter is positive to push a positive lean back to centre, so a
		# corrective nudge matches the SIGN of the lean (getting this
		# backwards made the "competent" rider actively throw itself off)
		var counter := signf(g.lean) * skill if absf(g.lean) > 0.001 else 0.0
		var r: String = g.tick(DT, counter)
		held += DT
		if r != "":
			out = r
			break
	return {"result": out, "held": held, "obj": g}


func _initialize() -> void:
	var failures := 0

	# 1) do nothing and the wobble throws you off
	var idle: Dictionary = _ride(8.0, 0.0)
	if idle.result != "bailed":
		print("FAIL: ignoring the wobble should bail, got '%s'" % idle.result)
		failures += 1
	if float(idle.held) > 3.5:
		print("FAIL: an unattended grind should end briskly, lasted %.1fs" % idle.held)
		failures += 1

	# 2) a competent rider holds it for a decent stretch
	var good: Dictionary = _ride(12.0, 1.0)
	if float(good.held) < 2.0:
		print("FAIL: a competent rider should hold it >2s, managed %.1fs" % good.held)
		failures += 1

	# 3) the difficulty ramp is real: even full skill cannot ride forever
	var forever: Dictionary = _ride(60.0, 1.0)
	if forever.result != "bailed":
		print("FAIL: the ramp should eventually end even a perfect grind")
		failures += 1

	# 4) longer rides pay more per second than short ones
	var g2 = GrindScript.new()
	g2.begin()
	for i in range(int(1.0 / DT)):
		g2.tick(DT, signf(g2.lean))
	var early: float = g2.score
	for i in range(int(1.0 / DT)):
		g2.tick(DT, signf(g2.lean))
	var late: float = g2.score - early
	if late <= early:
		print("FAIL: the second second should pay more than the first (%.1f vs %.1f)" % [late, early])
		failures += 1

	# 5) landing banks once, and a landed grind is inert afterwards
	var g3 = GrindScript.new()
	g3.begin()
	for i in range(30):
		g3.tick(DT, signf(g3.lean))
	var banked := g3.land()
	if banked <= 0:
		print("FAIL: landing should bank a positive score, got %d" % banked)
		failures += 1
	if g3.active or g3.land() != 0:
		print("FAIL: a landed grind must not bank twice")
		failures += 1
	if g3.tick(DT, 0.0) != "":
		print("FAIL: a landed grind must not keep ticking")
		failures += 1

	# 6) the bar starts centred
	var g4 = GrindScript.new()
	g4.begin()
	if absf(g4.fraction() - 0.5) > 0.001:
		print("FAIL: the balance bar should start centred, got %.2f" % g4.fraction())
		failures += 1

	if failures > 0:
		print("test_grind: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_grind: OK")
		quit(0)
