extends SceneTree

# El Tibidabo (systems/tibidabo.gd): the mountain funicular and the overlook.
# Registration, the level check, the corridor, the road surface, the track and
# pines off the road, the carriage moving on the walk clock and drawn every
# frame, and the viewfinder and funicular goals, each with the case that must
# not count.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "tibidabo"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var T: GDScript = load("res://systems/tibidabo.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration in campaign lists
	_check(game.LEVELS.has("tibidabo"), "tibidabo is in LEVELS")
	_check(game.CAROUSEL.has("tibidabo"), "tibidabo is in CAROUSEL")
	_check(int(game.STAR_GATE["tibidabo"]) == 35, "opens at 35 stars")
	_check(String(game.LEVEL_NAMES["tibidabo"]) == "El Tibidabo", "named El Tibidabo")
	_check(String(game.LEVEL_SUBTITLES["tibidabo"]) == "The city's highest hill and its old fairground", "subtitled the highest hill")
	_check(m.gate_text == "MIRADOR DEL TIBIDABO", "gate text is MIRADOR DEL TIBIDABO")
	_check(m.freedom_kind == "placa", "ends in fairground plaza")

	# 2. Structural LevelCheck passes clean
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. Corridor geometry
	var e_start: Vector2 = m.walk_edges(m.START_Y)
	var e_mid: Vector2 = m.walk_edges(-2400.0)
	var e_gate: Vector2 = m.walk_edges(m.GATE_Y)
	_check(e_start.y - e_start.x >= 480.0, "start corridor is wide enough (%.0f)" % (e_start.y - e_start.x))
	_check(e_mid.y - e_mid.x >= 480.0, "crossing corridor is wide enough (%.0f)" % (e_mid.y - e_mid.x))
	_check(e_gate.y - e_gate.x >= 500.0, "summit corridor is wide enough (%.0f)" % (e_gate.y - e_gate.x))

	# 4. Viewfinders registered in m.poles (rope wrap)
	var all_viewfinders_registered := true
	for vf: Vector2 in T.VIEWFINDERS:
		if not (vf in m.poles):
			all_viewfinders_registered = false
			print("Viewfinder missing from m.poles: %s" % str(vf))
	_check(all_viewfinders_registered, "all viewfinders registered in m.poles")

	# 5. Sniffable landmarks, snacks, bins, prize
	_check(m.hydrants.size() >= 5, "at least 5 sniffable spots (%d)" % m.hydrants.size())
	_check(m.kebabs.size() >= 4, "at least 4 dropped snacks (%d)" % m.kebabs.size())
	_check(m.bins.size() >= 4, "at least 4 waste bins (%d)" % m.bins.size())
	_check(m.fountains.size() >= 2, "at least 2 drinking fountains (%d)" % m.fountains.size())
	_check(m.prize_pos.x < INF, "prize placed on candy cart")
	_check(m.prize_text == T.PRIZE_TEXT, "prize text matches")

	# 6. Goals list well formed
	var goal_ids: Array = G.LEVEL_GOAL_IDS["tibidabo"]
	_check(goal_ids.size() == 15, "exactly 15 goals authored (%d)" % goal_ids.size())
	_check("funicular" in goal_ids, "funicular goal present")
	_check("viewfinder" in goal_ids, "viewfinder goal present")

	# 7. The road is a road, and everything off it stays off it
	_check(m.surface_at(Vector2(m.walk_edges(-2400.0).x + 60.0, -2400.0)) == m.Surfaces.S.PAVEMENT,
		"the road is pavement underfoot")
	var widest: float = -INF
	var y: float = m.START_Y
	while y > m.GATE_Y:
		widest = maxf(widest, m.walk_edges(y).y)
		y -= 50.0
	_check(T.TRACK_X - T.TRACK_W * 0.5 > widest, "the track is off the road (track %.0f, road edge %.0f)" % [T.TRACK_X - T.TRACK_W * 0.5, widest])
	for pp: Vector2 in T.PINES:
		_check(pp in m.poles and pp.x - T.PINE_R > T.TRACK_X + T.TRACK_W * 0.5,
			"pine at %s is a rope pole beyond the track" % pp)
	var se: Vector2 = m.walk_edges(T.SIGNAL_POS.y)
	_check(T.SIGNAL_POS.x > se.x and T.SIGNAL_POS.x < se.y, "the trackside signal is on the road, where she can mark it")

	# 8. The carriage moves on the walk clock, up and back, within the track
	var ys: Array[float] = []
	for k in range(9):
		ys.append(T.carriage_y(float(k) * T.CAR_PERIOD / 8.0))
	_check(absf(ys[0] - T.CAR_BOTTOM_Y) < 1.0 and absf(ys[4] - T.CAR_TOP_Y) < 1.0 and absf(ys[8] - T.CAR_BOTTOM_Y) < 1.0,
		"bottom, top, bottom over one period (%s)" % str(ys))
	_check(ys[1] < ys[0] and ys[2] < ys[1] and ys[5] > ys[4], "it climbs, then comes back down")
	# drawn every frame by its own layer, not the cached edge layer
	var layer: Node2D = null
	for c in m.get_children():
		if c.get_script() != null and (c.get_script() as Script).resource_path == "res://world/funicular_layer.gd":
			layer = c
	_check(layer != null, "the funicular layer is in the scene")
	if layer != null:
		var redraws := [0]
		layer.draw.connect(func() -> void: redraws[0] += 1)
		for k in range(4):
			await process_frame
		_check(redraws[0] >= 3, "the funicular layer redraws every frame (%d in 4)" % redraws[0])

	# 9. Viewfinder: walking past does not count, standing still at one does
	_check(not m.tibidabo_viewfinder_gazed, "viewfinder ungazed initially")
	m.dog.global_position = T.VIEWFINDERS[0]
	m.dog.velocity = Vector2(120.0, 0.0)
	T.tick(m, 0.016)
	_check(not m.tibidabo_viewfinder_gazed, "trotting past a viewfinder is not a look")
	m.dog.velocity = Vector2.ZERO
	T.tick(m, 0.016)
	_check(m.tibidabo_viewfinder_gazed, "standing still at a viewfinder is")

	# 10. Funicular: at the road's east side, only with the carriage level
	_check(not m.tibidabo_funicular_seen, "funicular unseen initially")
	m.elapsed = T.CAR_PERIOD * 0.25
	var car_y: float = T.carriage_y(m.elapsed)
	m.dog.global_position = Vector2(820.0, car_y + 900.0)
	T.tick(m, 0.016)
	_check(not m.tibidabo_funicular_seen, "the carriage far up the track is not a sighting")
	m.dog.global_position = Vector2(820.0, car_y)
	T.tick(m, 0.016)
	_check(m.tibidabo_funicular_seen, "the carriage level with her at the east side is")
	# parked at the bottom station by the start line, it is not a sighting
	m.tibidabo_funicular_seen = false
	m.elapsed = 0.0
	m.dog.global_position = Vector2(820.0, T.carriage_y(0.0))
	T.tick(m, 0.016)
	_check(not m.tibidabo_funicular_seen, "the carriage parked at the bottom station is not a sighting")

	# 11. The walk ends at the funicular's bottom station: the door on the
	# road's east side, and the carriage docked there once they are in
	var A: GDScript = load("res://systems/arrival.gd")
	var door: Vector2 = A.fit(m)
	_check(door.x > m.walk_cx + 80.0, "the door is on the road's east side, by the track (x %.0f)" % door.x)
	_check(A.rect_clear(m, Rect2(door - Vector2(A.MOUTH_W, A.MOUTH_H) * 0.5, Vector2(A.MOUTH_W, A.MOUTH_H))), "and clear to walk into")
	_check(absf(T.CAR_BOTTOM_Y - door.y) < T.CAR_L, "the bottom station is level with the door")
	m.elapsed = T.CAR_PERIOD * 0.5
	m.finished = true
	_check(is_equal_approx(T.shown_carriage_y(m), T.CAR_BOTTOM_Y), "the carriage is docked when the walk is done")
	m.finished = false

	m.queue_free()
	print("test_tibidabo: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
