extends SceneTree

# The off-leash games' rules (systems/agility.gd, systems/rope_tug.gd), run
# without a level: a clean agility run, faults for a missed pole and a skipped
# tunnel, an abandoned run; tug-of-war won by pulling away, lost by standing
# about, held longer dug in; and every space's lane clear of its fixed things.
#   godot --headless --path . --script res://tests/test_freedom_games.gd

var failures := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


# run a dog along waypoints at `speed`, feeding the course each 1/60 s
func _run(ag: AgilityCourse, pts: Array, speed := 300.0) -> Array:
	var ev: Array = []
	var pos: Vector2 = pts[0]
	for i in range(1, pts.size()):
		var to: Vector2 = pts[i]
		while pos.distance_to(to) > 0.5:
			var nxt := pos.move_toward(to, speed / 60.0)
			ev.append_array(ag.step(pos, nxt, 1.0 / 60.0))
			pos = nxt
	return ev


func _weave_path(ag: AgilityCourse, wrong_at := -1) -> Array:
	var pts: Array = [Vector2(ag.x0 - 60.0, ag.ly)]
	var k := 0
	for p: Dictionary in ag.parts:
		var px: float = p["x"]
		if int(p["kind"]) == AgilityCourse.E.WEAVE:
			var side: float = p["side"]
			if k == wrong_at:
				side = -side
			pts.append(Vector2(px - 12.0, ag.ly + side * 18.0))
			pts.append(Vector2(px + 12.0, ag.ly + side * 18.0))
			k += 1
		else:
			pts.append(Vector2(px - 10.0, ag.ly))
			pts.append(Vector2(px + 10.0 + (AgilityCourse.TUNNEL_LEN if int(p["kind"]) == AgilityCourse.E.TUNNEL else 0.0), ag.ly))
	pts.append(Vector2(ag.x1 + 40.0, ag.ly))
	return pts


func _finish(ev: Array) -> Array:
	for e: Array in ev:
		if String(e[0]) == "finish":
			return e
	return []


func _initialize() -> void:
	# a clean run
	var ag := AgilityCourse.new(-500.0, 260.0, 960.0)
	var ev := _run(ag, _weave_path(ag))
	var fin := _finish(ev)
	_check(not fin.is_empty(), "a clean run finishes")
	if not fin.is_empty():
		_check(int(fin[2]) == 0, "a clean run has no faults (%d)" % int(fin[2]))
		_check(float(fin[1]) > 1.5 and float(fin[1]) < 6.0, "a clean run's time is plausible (%.2f)" % float(fin[1]))
	var jumps := 0
	for e: Array in ev:
		if String(e[0]) == "jump":
			jumps += 1
	_check(jumps == 2, "both jumps are cleared (%d)" % jumps)
	_check(not ag.running, "the run is over at the finish")
	# one pole on the wrong side: one fault, two seconds
	var ag2 := AgilityCourse.new(-500.0, 260.0, 960.0)
	var fin2 := _finish(_run(ag2, _weave_path(ag2, 2)))
	_check(not fin2.is_empty() and int(fin2[2]) == 1, "a pole on the wrong side is one fault")
	# round the tunnel instead of through it: a fault
	var ag3 := AgilityCourse.new(-500.0, 260.0, 960.0)
	var pts3 := _weave_path(ag3)
	var tun: Dictionary = ag3.parts[6]
	var path3: Array = []
	for p: Vector2 in pts3:
		if p.x > float(tun["x"]) - 20.0 and p.x < float(tun["x_end"]) + 20.0:
			continue
		path3.append(p)
	var i3 := 0
	while i3 < path3.size() and (path3[i3] as Vector2).x < float(tun["x"]):
		i3 += 1
	path3.insert(i3, Vector2(float(tun["x"]) - 30.0, ag3.ly + 60.0))
	path3.insert(i3 + 1, Vector2(float(tun["x_end"]) + 30.0, ag3.ly + 60.0))
	var fin3 := _finish(_run(ag3, path3))
	_check(not fin3.is_empty() and int(fin3[2]) >= 1, "going round the tunnel is a fault")
	# wandering off abandons the run
	var ag4 := AgilityCourse.new(-500.0, 260.0, 960.0)
	var ev4 := _run(ag4, [Vector2(200, -500), Vector2(330, -500), Vector2(330, -260)])
	var quit := false
	for e: Array in ev4:
		quit = quit or String(e[0]) == "quit"
	_check(quit and not ag4.running, "wandering off the lane abandons the run")
	# no start from outside the lane
	var ag5 := AgilityCourse.new(-500.0, 260.0, 960.0)
	_run(ag5, [Vector2(200, -400), Vector2(400, -400)])
	_check(not ag5.running, "crossing the start line off the lane does not start a run")

	# tug-of-war: pulling away wins, standing loses, digging in holds longer
	_check(_tug("away") == "won", "pulling away wins the tug")
	_check(_tug("stand") == "lost", "standing about loses the tug")
	var t_stand := _tug_time("stand")
	var t_plant := _tug_time("plant")
	_check(t_plant > t_stand * 2.0, "digging in holds much longer (%.1f vs %.1f s)" % [t_plant, t_stand])
	var t_away := _tug_time("away")
	_check(t_away > 2.5 and t_away < 12.0, "a pulled-away win takes a few seconds (%.1f)" % t_away)

	# every space's lane: inside the space, and props pushed out of it
	for kind: String in ["yard", "lot", "clearing", "placa", "beach"]:
		var c := AgilityCourse.for_space(kind, -5000.0)
		var r := c.lane_rect()
		_check(r.position.x >= 70.0 and r.end.x <= 1180.0, "%s lane inside the space" % kind)
		_check(r.position.y >= -5620.0 and r.end.y <= -5030.0, "%s lane inside the space vertically" % kind)
		var pushed := c.push_out(Vector2((c.x0 + c.x1) * 0.5, c.ly + 5.0), 20.0)
		_check(not c.lane_rect(20.0).has_point(pushed), "%s pushes a prop off the lane" % kind)
	print("test_freedom_games: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)


func _tug_sim(style: String) -> Array:
	var me := Vector2(0, 0)
	var them := Vector2(-46, 0)
	var tug := RopeTug.new(me, them)
	var t := 0.0
	while t < 30.0:
		var pull := Vector2.ZERO
		var planted := style == "plant"
		if style == "away":
			pull = Vector2.RIGHT
			me += pull * 330.0 * RopeTug.MY_SPEED / 60.0
		var out := tug.step(me, them, pull, planted, false, 1.0 / 60.0)
		me = out[0]
		them = out[1]
		t += 1.0 / 60.0
		if String(out[2]) != "":
			return [String(out[2]), t]
	return ["", t]


func _tug(style: String) -> String:
	return _tug_sim(style)[0]


func _tug_time(style: String) -> float:
	return _tug_sim(style)[1]
