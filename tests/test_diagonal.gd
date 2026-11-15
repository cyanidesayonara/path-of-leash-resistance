extends SceneTree

# Tests La Diagonal (systems/diagonal.gd) and its turned camera:
# - registered in LEVELS, CAROUSEL (after El Fòrum), STAR_GATE, CHASE_GATE,
#   LEVEL_NAMES and its glosses, CAMPAIGN_SKY, the goals table
# - the camera is turned 45 degrees for this walk, and only this walk
# - the stick means screen directions: screen-up walks her up the avenue's
#   on-screen line, which is up and to the side in the world
# - the culled band grows with a turned camera (main._rot_pad)
# - the tram rings first and reaches her about RING_LEAD later, never before
# - a dog on the rails as it comes is bumped off them, once, and counted
# - off the rails just before it reaches her is a dodge, paid
# - it brakes short of your human on the rails and never hits them

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		printerr("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "diagonal"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = false

	var D: GDScript = load("res://systems/diagonal.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var LB: GDScript = load("res://world/level_build.gd")

	# --- 1. registration ---
	_check(game.LEVELS.has("diagonal"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("diagonal")
	_check(ci == game.CAROUSEL.find("forum") + 1, "in CAROUSEL right after El Fòrum, where the avenue ends")
	_check(game.STAR_GATE.has("diagonal"), "has a star gate")
	_check(String(game.CHASE_GATE.get("diagonal", "")) == "boars", "in Els Senglars' tier, with El Fòrum")
	_check(String(game.LEVEL_NAMES["diagonal"]) == "La Diagonal", "named La Diagonal")
	_check(game.LEVEL_SUBTITLES_CA.has("diagonal") and game.LEVEL_SUBTITLES_ES.has("diagonal"), "glossed in Catalan and Spanish")
	_check(game.CAMPAIGN_SKY["diagonal"] == ["clear", "day"], "a clear day")
	var ids: Array = G.LEVEL_GOAL_IDS["diagonal"]
	_check(ids.size() == 15 and ids.has("tram_dodge") and ids.has("tram_clean") and ids.has("kiosk"), "fifteen goals with the tram's and the kiosk's")

	# --- 2. the turned camera ---
	_check(is_equal_approx(m.cam.rotation, -deg_to_rad(45.0)), "the camera is turned 45 degrees")
	_check(not m.cam.ignore_rotation, "the camera's turn is applied")
	_check(float(LB.CAM_ROT.get("eixample", 0.0)) == 0.0, "L'Eixample's camera is not turned")
	_check(m._rot_pad() > 100.0, "the culled band grows with the turned view")
	# screen-up, turned into the world: up and to the left of north by 45
	var up: Vector2 = Vector2(0.0, -1.0).rotated(m.cam.rotation)
	_check(up.y < -0.6 and up.x < -0.6, "screen-up is up and left in the world (the path climbs to the upper right on screen)")

	# --- 3. the tram ---
	var t = m.diagonal_tram
	_check(t != null, "the walk has its tram")
	m.dog.global_position = Vector2(D.TRACK_X, -1600.0)
	m.human.global_position = Vector2(500.0, -1500.0)
	t.wait = 0.05
	t.rng.seed = 1
	var rang_at := -1.0
	var hit_at := -1.0
	var time := 0.0
	var hits0: int = m.diagonal_tram_hits
	while time < 6.0:
		m.dog.global_position.x = D.TRACK_X
		m.dog.global_position.y = -1600.0
		m.dog.tumble_t = 0.0
		D.tick(m, DT)
		time += DT
		if rang_at < 0.0 and t.rang:
			rang_at = time
		if hit_at < 0.0 and m.diagonal_tram_hits > hits0:
			hit_at = time
			break
	_check(rang_at >= 0.0, "the bell rings")
	_check(hit_at > 0.0, "a dog left on the rails is bumped")
	_check(hit_at - rang_at > D.RING_LEAD * 0.7 and hit_at - rang_at < D.RING_LEAD * 1.4,
		"the bell comes about RING_LEAD before the tram reaches her (%.2f s)" % (hit_at - rang_at))
	# once per run, however long she stays
	var hits1: int = m.diagonal_tram_hits
	for i in range(20):
		m.dog.global_position = Vector2(D.TRACK_X, -1600.0)
		m.dog.tumble_t = 0.0
		D.tick(m, DT)
	_check(m.diagonal_tram_hits == hits1, "bumped once per tram, not every frame")

	# --- 4. a dodge: on the rails, then off just before it comes ---
	_reset_tram(t)
	m.human.global_position = Vector2(500.0, -1500.0)
	var dodges0: int = m.diagonal_tram_dodges
	var hits2: int = m.diagonal_tram_hits
	time = 0.0
	var stepped := false
	while time < 6.0 and not t.passed:
		var to_her: float = (m.dog.global_position.y - t.y) * t.dir if t.running else 1e9
		if not stepped and t.running and to_her < D.TRAM_LEN * 0.5 + 140.0:
			stepped = true
		m.dog.global_position = Vector2(560.0 if stepped else D.TRACK_X, -1600.0)
		m.dog.tumble_t = 0.0
		D.tick(m, DT)
		time += DT
	_check(m.diagonal_tram_hits == hits2, "off the rails in time is no bump")
	_check(m.diagonal_tram_dodges == dodges0 + 1, "off the rails just before it is a dodge")

	# --- 5. it brakes for your human ---
	_reset_tram(t)
	m.dog.global_position = Vector2(500.0, -1600.0)
	m.human.global_position = Vector2(D.TRACK_X, -1600.0)
	var min_gap := 1e9
	time = 0.0
	var braked := false
	while time < 6.0:
		m.human.global_position = Vector2(D.TRACK_X, -1600.0)
		D.tick(m, DT)
		time += DT
		if t.running:
			var front: float = t.y + t.dir * D.TRAM_LEN * 0.5
			min_gap = minf(min_gap, (m.human.global_position.y - front) * t.dir)
			braked = braked or t.braking
	_check(braked, "it brakes for your human on the rails")
	_check(min_gap > 0.0, "and stops short of them (closest %.0f px)" % min_gap)

	print("test_diagonal: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)


func _reset_tram(t) -> void:
	t.running = false
	t.rang = false
	t.passed = false
	t.hit_this_run = false
	t.braking = false
	t.on_track_t = 99.0
	t.wait = 0.05
