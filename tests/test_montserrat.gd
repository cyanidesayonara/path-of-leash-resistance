extends SceneTree

# Tests Montserrat and the Wild Goat Herd chase (systems/montserrat.gd,
# entities/goat_threat.gd, intro/film_montserrat.gd):
# - registration in LEVELS, CAROUSEL, STAR_GATE, CHASE_GATE, CAMPAIGN_SKY, LEVEL_NAMES
# - goals registered in LEVEL_GOAL_IDS (15 goals)
# - chase profile in HomeChase with respites and story film
# - rolling boulder dodge mechanics award montserrat_boulder_dodges
# - direct boulder hit causes knockback and records montserrat_goat_hits
# - chase checkpoint snapshots montserrat counters
# - Sant Joan funicular crossing state transitions and dodge award
# - barking near the mel i mató stall sets montserrat_mato_barked

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
	game.level_id = "montserrat"

	var main_scene = load("res://main.tscn")
	var m: Node2D = main_scene.instantiate()
	root.add_child(m)

	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame

	m._skip_title()
	await physics_frame

	m.set_physics_process(false)
	m.set_process(false)

	var M: GDScript = load("res://systems/montserrat.gd")
	var Threat: GDScript = load("res://entities/goat_threat.gd")
	var Film: GDScript = load("res://intro/film_montserrat.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")
	var CC: GDScript = load("res://systems/chase_checkpoint.gd")

	# 1. Core registrations
	_check(M != null, "systems/montserrat.gd loads")
	_check(Threat != null, "entities/goat_threat.gd loads")
	_check(Film != null, "intro/film_montserrat.gd loads")

	_check(game.LEVELS.has("montserrat"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("montserrat")
	_check(ci != -1 and ci > game.CAROUSEL.find("aeroport"), "in CAROUSEL after aeroport")
	_check(int(game.STAR_GATE["montserrat"]) == 52, "opens at 52 stars")
	_check(String(game.CHASE_GATE.get("montserrat", "")) == "aeroport", "after L'Aeroport")
	_check(String(game.LEVEL_NAMES["montserrat"]) == "Montserrat", "named Montserrat")
	_check(game.CAMPAIGN_SKY["montserrat"] == ["clear", "day"], "a clear day in the mountains")

	# 2. Goals
	_check(G.LEVEL_GOAL_IDS.has("montserrat"), "has goal list")
	var goals: Array = G.LEVEL_GOAL_IDS["montserrat"]
	_check(goals.size() == 15, "has exactly 15 goals (has %d)" % goals.size())
	_check(goals.has("funicular_dodge"), "has funicular_dodge goal")
	_check(goals.has("boulder_dodge"), "has boulder_dodge goal")
	_check(goals.has("goat_clean"), "has goat_clean goal")
	_check(goals.has("mato_bark"), "has mato_bark goal")
	_check(goals.has("jamon"), "has jamon goal")
	_check(goals.has("clock"), "has clock goal")

	# 3. Chase Profile
	var prof: Dictionary = HC.profile_for("montserrat")
	_check(not prof.is_empty(), "has chase profile")
	_check(String(prof.get("kind", "")) == "goat", "goat kind")
	_check(String(prof.get("script", "")) == "res://entities/goat_threat.gd", "threat script")
	_check(String(prof.get("film", "")) == "res://intro/film_montserrat.gd", "its film")
	var bands: Array = prof.get("bands", [])
	_check(bands.size() == 2, "2 respite bands (has %d)" % bands.size())
	_check(bool(bands[1].get("checkpoint", false)), "midpoint is a checkpoint")

	# 4. Goat Threat & Boulder Dodge Mechanics
	var threat_inst = Threat.new()
	m.add_child(threat_inst)
	threat_inst.setup(m, -400.0, 640.0, 260.0, 138.0)
	_check(threat_inst.front_y == -400.0, "threat starts at given front_y")

	# Simulate boulder dodge
	m.dog.global_position = Vector2(640.0, -480.0)
	var dodges0: int = m.montserrat_boulder_dodges
	threat_inst._resolve_boulder_impact({"target": Vector2(640.0, -550.0)}) # 70 px away: inside dodge radius
	_check(m.montserrat_boulder_dodges == dodges0 + 1, "dog within dodge radius counts a boulder dodge")

	# Simulate boulder direct hit
	var hits0: int = m.montserrat_goat_hits
	threat_inst._resolve_boulder_impact({"target": Vector2(640.0, -480.0)}) # directly on dog
	_check(m.montserrat_goat_hits == hits0 + 1, "dog directly on landing spot takes a hit")

	# Checkpoint schema includes montserrat fields
	_check(CC.MAIN_FIELDS.has("montserrat_boulder_dodges") and CC.MAIN_FIELDS.has("montserrat_goat_hits"),
		"checkpoint snapshots montserrat boulder dodges and hits")

	# 5. Funicular Crossing (walk clock; the carriage pauses off the path)
	var run: float = (M.FUNICULAR_TO - M.FUNICULAR_FROM) / M.FUNICULAR_SPEED
	var leg: float = run + M.FUNICULAR_PAUSE
	var off_t := 0.0
	var on_t := -1.0
	var t := 0.0
	while t < leg * 2.0:
		if not M.funicular_near_crossing(t) and off_t == 0.0 and t > run:
			off_t = t
		t += 0.05
	_check(off_t > 0.0, "the carriage leaves the path for a while each cycle")
	t = 0.0
	while t < leg * 2.0 and on_t < 0.0:
		if M.funicular_on_path(t):
			on_t = t
		t += 0.01
	_check(on_t >= 0.0, "and crosses it")
	_check(on_t <= 0.0 or M.funicular_near_crossing(on_t - M.FUNICULAR_WARN + 0.02), "the bell rings before it reaches the path")

	# a pass that comes by the pair and hits nobody pays once
	m.montserrat_funicular = {"state": "waiting", "t": 0.0}
	m.montserrat_funicular_dodged = false
	m.human.global_position = Vector2(640.0, M.CROSSING_Y + 120.0)
	m.dog.global_position = Vector2(640.0, M.CROSSING_Y + 100.0)
	var bones0: int = m.bones
	t = 0.0
	while t < leg:
		m.elapsed = t
		M.tick(m, 0.05)
		t += 0.05
	_check(m.montserrat_funicular_dodged, "waiting out a pass awards funicular_dodge")
	_check(m.bones == bones0 + 3, "and pays 3 (got %d)" % (m.bones - bones0))

	# standing on the line: hit once a pass, however long they stay there
	m.montserrat_funicular = {"state": "waiting", "t": 0.0}
	m.montserrat_funicular_dodged = false
	var pat0: float = m.human.patience
	t = leg * 2.0
	while t < leg * 3.0:
		m.elapsed = t
		var cx: float = M.funicular_car_x(t)
		m.human.global_position = Vector2(clampf(cx, M.PATH_L + 10.0, M.PATH_R - 10.0), M.CROSSING_Y)
		m.dog.global_position = Vector2(640.0, M.CROSSING_Y + 200.0)
		M.tick(m, 0.05)
		t += 0.05
	_check(is_equal_approx(m.human.patience, maxf(0.0, pat0 - m.LIVE_EVENT_BUMP_PATIENCE)), "one bump for the pass (patience %.2f)" % m.human.patience)
	_check(not m.montserrat_funicular_dodged, "a pass that hit your human pays nothing")

	# 6. Mel i mató Cheese Stall
	m.montserrat_mato_barked = false
	m.dog.global_position = Vector2(100.0, -100.0)
	M.on_bark(m, m.dog.global_position)
	_check(not m.montserrat_mato_barked, "barking far away does not count")

	m.dog.global_position = M.CHEESE_STALL_POS + Vector2(20.0, 20.0)
	M.on_bark(m, m.dog.global_position)
	_check(m.montserrat_mato_barked, "barking near cheese stall sets montserrat_mato_barked")

	if failures.is_empty():
		print("test_montserrat: %d checks, OK" % checks)
	else:
		print("test_montserrat: %d checks, %d FAILED" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
