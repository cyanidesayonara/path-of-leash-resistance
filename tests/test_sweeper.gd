extends SceneTree

# Regression for the chase-leg devourer (sweeper.gd):
#  1. it lurches, but on average advances south at its set speed
#  2. it only goes faster than its lurch for being FAR behind: up close it
#     is never quicker than base speed plus the lurch
#  3. its leading edge is the kill line: bodies north of it are caught,
#     bodies south (ahead) are safe
#  4. a dawdler slower than the sweeper gets caught; a hustler faster than
#     it stays ahead forever (the "keep moving" tension), catch-up and all
#  5. a jam stalls it for JAM_SECS, once, and says so for one tick each end
#  6. junk on the kill line is flung down the street the first time and
#     swallowed the next
#  7. the brooms swing in round something parked at the kerb, but not
#     round a dumpster still waiting to jam one
#  8. the body swerves, but never out of the street
# Pure logic, driven by advance()/caught() with no rendering.

const DT := 1.0 / 60.0
const SweeperScript := preload("res://entities/sweeper.gd")
const ConeScript := preload("res://entities/cone.gd")

var failures := 0


func _fail(msg: String) -> void:
	print("FAIL: " + msg)
	failures += 1


func _initialize() -> void:
	# 1) on average, south at speed: a minute of lurching lands within 3%
	var s = SweeperScript.new()
	s.setup(null, 0.0, 640.0, 185.0, 140.0)
	var lo := INF
	var hi := 0.0
	for i in range(3600):
		s.advance(DT)
		lo = minf(lo, s.cur_speed)
		hi = maxf(hi, s.cur_speed)
	if absf(s.front_y - 140.0 * 60.0) > 140.0 * 60.0 * 0.03:
		_fail("a minute at 140 should cover ~8400, got %.0f" % s.front_y)
	if hi - lo < 140.0 * SweeperScript.SURGE:
		_fail("it should lurch, not cruise (%.0f..%.0f)" % [lo, hi])

	# 2) catch-up only when far behind
	var near_max := 0.0
	var sn = SweeperScript.new()
	sn.setup(null, 0.0, 640.0, 185.0, 140.0)
	for i in range(600):
		sn.advance(DT, 150.0)
		near_max = maxf(near_max, sn.cur_speed)
	if near_max > 140.0 * (1.0 + SweeperScript.SURGE) + 0.5:
		_fail("up close it must never beat its lurch (%.0f)" % near_max)
	var sf = SweeperScript.new()
	sf.setup(null, 0.0, 640.0, 185.0, 140.0)
	var far_min := INF
	for i in range(600):
		sf.advance(DT, 1200.0)
		far_min = minf(far_min, sf.cur_speed)
	if far_min < 140.0 * 1.4:
		_fail("far behind it should gun it (slowest %.0f)" % far_min)

	# 3) the kill line: north = caught, south = safe
	var s2 = SweeperScript.new()
	s2.setup(null, 0.0, 640.0, 520.0, 140.0)
	if not s2.caught(Vector2(640.0, -5.0)):
		_fail("a body north of the edge should be caught")
	if s2.caught(Vector2(640.0, 60.0)):
		_fail("a body south (ahead) of the edge should be safe")
	if s2.gap_to(Vector2(640.0, 60.0)) <= 0.0 or s2.gap_to(Vector2(640.0, -5.0)) >= 0.0:
		_fail("gap_to sign wrong")

	# 4) a dawdler (92 u/s, like the phone-zombie owner) starting 500 ahead
	#    gets caught; a hustler (220 u/s) never does
	if not _runs_down(92.0):
		_fail("a dawdler slower than the sweeper should be caught")
	if _runs_down(220.0):
		_fail("a hustler faster than the sweeper should stay ahead")

	# 5) a jam: stalls JAM_SECS, once
	var sj = SweeperScript.new()
	sj.setup(null, -300.0, 640.0, 185.0, 140.0)
	sj.jams = [Vector2(800.0, -100.0)] as Array[Vector2]
	var started_jam := 0
	var freed := 0
	var stalled := 0.0
	for i in range(900):
		sj.advance(DT)
		started_jam += int(sj.jammed_now)
		freed += int(sj.freed_now)
		if sj.jammed():
			stalled += DT
	if started_jam != 1 or freed != 1:
		_fail("a jam should start once and end once (%d, %d)" % [started_jam, freed])
	if absf(stalled - SweeperScript.JAM_SECS) > 0.05:
		_fail("a jam should hold it for %.1fs (held %.2f)" % [SweeperScript.JAM_SECS, stalled])
	if sj.jam_side != 1.0:
		_fail("the jam should be on the east broom (%.0f)" % sj.jam_side)
	if not sj.jams.is_empty():
		_fail("a jam fires only once")

	# 6) junk: flung south the first time, swallowed the next
	var sk = SweeperScript.new()
	sk.setup(null, 0.0, 640.0, 185.0, 140.0)
	var crate = ConeScript.new()
	crate.kind = "crate"
	crate.position = Vector2(560.0, -20.0)
	var far_junk = ConeScript.new()
	far_junk.position = Vector2(640.0, 300.0)
	if sk.sweep_junk([crate, far_junk]) != 1:
		_fail("only the junk on the kill line is flung")
	if crate.vel.y <= 0.0 or crate.swept != 1 or crate.flung_t <= 0.0:
		_fail("flung junk goes south, marked as swept (vel %s)" % crate.vel)
	var drag: float = float(ConeScript.KINDS["crate"].drag)
	var reach: float = crate.vel.length_squared() / (2.0 * drag)
	if reach < SweeperScript.FLING_MIN - 1.0 or reach > SweeperScript.FLING_MAX + 1.0:
		_fail("it should fly %.0f-%.0f, not %.0f" % [SweeperScript.FLING_MIN, SweeperScript.FLING_MAX, reach])
	if crate.vel.x <= 0.0:
		_fail("junk west of the machine is swept inward, east")
	if far_junk.vel != Vector2.ZERO:
		_fail("junk well ahead is left alone")
	sk.sweep_junk([crate])
	if not crate.is_queued_for_deletion():
		_fail("junk the brooms reach again is swallowed")
	far_junk.free()

	# 7) the brooms swing in round a parked dumpster, not one waiting to jam
	var sb = SweeperScript.new()
	sb.setup(null, 0.0, 640.0, 185.0, 140.0)
	var open_x: float = sb._broom_x(1.0)
	var dump := Rect2(Vector2(640.0 + 185.0 - 52.0, -60.0), Vector2(46.0, 90.0))
	sb.kerb_blocks = [dump] as Array[Rect2]
	var blocked_x: float = sb._broom_x(1.0)
	if blocked_x > dump.position.x - SweeperScript.BROOM_R - 640.0 + 0.5:
		_fail("the east broom should swing in clear of the dumpster (%.0f)" % blocked_x)
	if not is_equal_approx(sb._broom_x(-1.0), -open_x):
		_fail("the west broom is not bothered by an east dumpster")
	sb.jams = [Vector2(dump.get_center().x, dump.position.y - 4.0)] as Array[Vector2]
	if not is_equal_approx(sb._broom_x(1.0), open_x):
		_fail("a dumpster still to jam the broom must not be swung round")

	# 8) careening stays inside the street
	var sw = SweeperScript.new()
	sw.setup(null, 0.0, 640.0, 185.0, 140.0)
	var widest := 0.0
	for i in range(3600):
		sw.advance(DT, 300.0, 400.0 * sin(float(i) * 0.05))
		widest = maxf(widest, absf(sw.sway))
	if widest < 20.0:
		_fail("the body should swerve about (%.0f)" % widest)
	if widest > 185.0 - SweeperScript.BODY_HALF:
		_fail("the body swerved out of the street (%.0f)" % widest)

	for o in [s, sn, sf, s2, sj, sk, sb, sw]:
		o.free()
	if failures > 0:
		print("test_sweeper: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_sweeper: OK")
		quit(0)


func _runs_down(pace: float) -> bool:
	var sd = SweeperScript.new()
	sd.setup(null, -500.0, 640.0, 185.0, 140.0)
	var y := 0.0
	var caught := false
	for i in range(3600):
		sd.advance(DT, sd.gap_to(Vector2(640.0, y)))
		y += pace * DT
		if sd.caught(Vector2(640.0, y)):
			caught = true
			break
	sd.free()
	return caught
