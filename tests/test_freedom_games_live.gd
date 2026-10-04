extends SceneTree

# The off-leash games in a real level: the course is laid with nothing
# standing on its lane, a run through it scores and sets the best time, the
# rope dog's end starts a tug that moves both dogs, the frisbee comes out once
# fetch is done (after the ball is back) and pays more for an air catch, and
# everything is cleared when the walk turns for home. Nothing is saved.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _open(lvl: String) -> Node2D:
	var game = root.get_node("Game")
	game.persist = false
	game.agility_best = 0.0
	game.level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 300.0)
	m.human.global_position = Vector2(640.0, m.GATE_Y - 60.0)
	m.leash.resnap()
	m._enter_freedom()
	await physics_frame
	return m


func _close(m: Node2D) -> void:
	m.queue_free()
	await process_frame


func _run() -> void:
	var game = root.get_node("Game")
	for lvl: String in ["park", "beach", "guell", "site", "market"]:
		var m: Node2D = await _open(lvl)
		var lane: Rect2 = m.agility.lane_rect()
		var blocked := 0
		for pp in m.park_props:
			if lane.has_point(pp.pos):
				blocked += 1
		for tr: Vector2 in m.trees:
			if lane.grow(-8.0).has_point(tr):
				blocked += 1
		_check(blocked == 0, "%s: nothing stands on the agility lane (%d)" % [lvl, blocked])
		_check(m.games_ground != null and m.games_ground.visible, "%s: the course is drawn" % lvl)
		await _close(m)

	var m: Node2D = await _open("park")
	# --- a run along the lane, the dog steered by hand
	var ag: AgilityCourse = m.agility
	var bones0: int = m.bones
	m.dog.global_position = Vector2(ag.x0 - 40.0, ag.ly)
	m.agility_prev = m.dog.global_position
	var x := ag.x0 - 40.0
	var weave_k := 0
	while x < ag.x1 + 30.0:
		x += 5.0
		var y := ag.ly
		for p: Dictionary in ag.parts:
			if int(p["kind"]) == AgilityCourse.E.WEAVE and absf(x - float(p["x"])) < 14.0:
				y = ag.ly + float(p["side"]) * 16.0
		m.dog.global_position = Vector2(x, y)
		m.freedom_games_tick(1.0 / 60.0)
		if m.dog.hop > 0.0:
			weave_k += 1
	_check(m.agility_runs == 1, "a run along the course finishes it")
	_check(game.agility_best > 0.0, "the run sets the best time")
	_check(m.bones > bones0, "the run scores")
	_check(weave_k > 0, "she hops over the jumps")

	# --- the rope: grab the free end, and both dogs move with the tug
	var fd: Node2D = m.tug_dog
	_check(fd != null and fd.rope, "one free dog has the rope")
	if fd != null:
		fd.global_position = Vector2(640.0, m.GATE_Y - 250.0)
		fd.face = Vector2.RIGHT
		m.dog.facing = Vector2.LEFT
		m.dog.global_position = fd.rope_end() - m.dog.facing * 22.0
		m.dog_carrying = false
		m.freedom_games_tick(1.0 / 60.0)
		_check(m.tug != null, "taking the rope's end starts a tug")
		var fd0: Vector2 = fd.global_position
		for i in range(30):
			m.freedom_games_tick(1.0 / 60.0)
		_check(fd.global_position.distance_to(fd0) > 2.0, "the other dog hauls during the tug")
		_check(m.dog_carrying, "her mouth is full while she tugs")
		for i in range(60 * 15):
			if m.tug == null:
				break
			m.freedom_games_tick(1.0 / 60.0)
		_check(m.tug == null, "a tug always ends")

	# --- the frisbee after fetch, not while the ball is in her mouth
	m.rope_carry_t = 0.0
	m.dog_carrying = false
	m.romp_done = true
	m.ball.state = m.ball.State.CARRIED
	m.freedom_games_tick(1.0 / 60.0)
	_check(not is_instance_valid(m.frisbee), "no frisbee while the ball is in her mouth")
	m.ball.state = m.ball.State.RESTING
	m.freedom_games_tick(1.0 / 60.0)
	_check(is_instance_valid(m.frisbee) and not is_instance_valid(m.ball), "the frisbee replaces the ball after fetch")
	var b1: int = m.bones
	m.on_frisbee_caught(true)
	var air: int = m.bones - b1
	b1 = m.bones
	m.on_frisbee_caught(false)
	_check(air > m.bones - b1, "an air catch pays more than one off the ground")

	# --- home clears it all
	m.dog.global_position = Vector2(640.0, m.GATE_Y + 60.0)
	m._enter_home()
	await process_frame
	_check(m.tug == null and not is_instance_valid(m.frisbee) and not m.games_ground.visible,
		"the games are cleared for the walk home")
	await _close(m)

	# --- the autowalk never gets the rope or the frisbee
	var m2: Node2D = await _open("park")
	m2.auto_walk = true
	m2._enter_freedom()
	m2.romp_done = true
	if is_instance_valid(m2.ball):
		m2.ball.queue_free()
	m2.freedom_games_tick(1.0 / 60.0)
	_check(m2.tug_dog == null and not is_instance_valid(m2.frisbee), "the autowalk gets no rope and no frisbee")
	await _close(m2)

	print("test_freedom_games_live: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
