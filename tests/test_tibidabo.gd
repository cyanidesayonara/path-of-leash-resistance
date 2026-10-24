extends SceneTree

# El Tibidabo (systems/tibidabo.gd): The mountain funicular & panoramic overlook.
# Tests campaign registration, corridor bounds, funicular track & viewfinders registered in m.poles,
# panoramic viewfinder observation interaction, Cuca de Llum funicular sighting interaction,
# and LevelCheck.check(m) passing with 0 failures.

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
	_check(String(game.LEVEL_SUBTITLES["tibidabo"]) == "the mountain funicular", "subtitled the mountain funicular")
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
	_check(goal_ids.size() == 12, "exactly 12 goals authored (%d)" % goal_ids.size())
	_check("funicular" in goal_ids, "funicular goal present")
	_check("viewfinder" in goal_ids, "viewfinder goal present")

	# 7. Viewfinder interaction
	_check(not m.tibidabo_viewfinder_gazed, "viewfinder ungazed initially")
	m.dog.global_position = T.VIEWFINDERS[0]
	m.dog.velocity = Vector2.ZERO
	T.update_tibidabo(m, 0.016)
	_check(m.tibidabo_viewfinder_gazed, "stopping at cliffside viewfinder triggers panorama gaze")

	# 8. Funicular sighting interaction
	_check(not m.tibidabo_funicular_seen, "funicular unseen initially")
	var t: float = AnimClock.msec() / 1000.0
	var cycle := fmod(t, 24.0) / 24.0
	var car_y := lerpf(100.0, -4700.0, cycle)
	m.dog.global_position = Vector2(720.0, car_y)
	T.update_tibidabo(m, 0.016)
	_check(m.tibidabo_funicular_seen, "standing near track as funicular passes triggers funicular goal")

	m.queue_free()
	print("test_tibidabo: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
