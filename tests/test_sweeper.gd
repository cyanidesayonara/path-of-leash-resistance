extends SceneTree

# Regression for the chase-leg devourer (sweeper.gd):
#  1. it advances south at its set speed
#  2. its leading edge is the kill line: bodies north of it are caught,
#     bodies south (ahead) are safe
#  3. a dawdler slower than the sweeper gets caught; a hustler faster than
#     it stays ahead forever (the "keep moving" tension)
# Pure logic, driven by advance()/caught() with no rendering.

const DT := 1.0 / 60.0
const SweeperScript := preload("res://entities/sweeper.gd")


func _initialize() -> void:
	var failures := 0

	# 1) advances south (y increases) at speed
	var s = SweeperScript.new()
	s.setup(null, -1000.0, 640.0, 520.0, 140.0)
	for i in range(60):
		s.advance(DT)
	# ~1 second at 140 u/s -> about +140
	if absf(s.front_y - (-860.0)) > 4.0:
		print("FAIL: after 1s front_y should be ~-860, got %.1f" % s.front_y)
		failures += 1

	# 2) the kill line: north = caught, south = safe
	var s2 = SweeperScript.new()
	s2.setup(null, 0.0, 640.0, 520.0, 140.0)
	if not s2.caught(Vector2(640.0, -5.0)):
		print("FAIL: a body north of the edge should be caught")
		failures += 1
	if s2.caught(Vector2(640.0, 60.0)):
		print("FAIL: a body south (ahead) of the edge should be safe")
		failures += 1
	if s2.gap_to(Vector2(640.0, 60.0)) <= 0.0 or s2.gap_to(Vector2(640.0, -5.0)) >= 0.0:
		print("FAIL: gap_to sign wrong")
		failures += 1

	# 3) a dawdler (92 u/s, like the phone-zombie owner) starting 500 ahead
	#    gets caught; a hustler (220 u/s) never does
	var caught_dawdler := false
	var sd = SweeperScript.new()
	sd.setup(null, -500.0, 640.0, 520.0, 140.0)
	var dawdler_y := 0.0
	for i in range(1200):
		sd.advance(DT)
		dawdler_y += 92.0 * DT
		if sd.caught(Vector2(640.0, dawdler_y)):
			caught_dawdler = true
			break
	if not caught_dawdler:
		print("FAIL: a dawdler slower than the sweeper should be caught")
		failures += 1

	var caught_hustler := false
	var sh = SweeperScript.new()
	sh.setup(null, -500.0, 640.0, 520.0, 140.0)
	var hustler_y := 0.0
	for i in range(1200):
		sh.advance(DT)
		hustler_y += 220.0 * DT
		if sh.caught(Vector2(640.0, hustler_y)):
			caught_hustler = true
			break
	if caught_hustler:
		print("FAIL: a hustler faster than the sweeper should stay ahead")
		failures += 1

	if failures > 0:
		print("test_sweeper: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_sweeper: OK")
		quit(0)
