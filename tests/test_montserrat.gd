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

	# 5. Funicular Crossing
	m.montserrat_funicular = {"state": "waiting", "t": 0.0}
	m.montserrat_funicular_dodged = false
	m.elapsed = 0.0
	_check(String(m.montserrat_funicular.get("state", "")) == "waiting", "funicular waiting initially")

	# Advance elapsed to trigger near crossing
	m.elapsed = 4.0 # funicular near crossing
	M.tick(m, 0.1)
	_check(String(m.montserrat_funicular.get("state", "")) == "crossing", "funicular enters crossing state")

	# Position dog past crossing and clear
	m.dog.global_position = Vector2(640.0, -2750.0)
	m.elapsed = 8.0 # carriage moved past
	M.tick(m, 0.1)
	_check(m.montserrat_funicular_dodged, "crossing safely awards funicular_dodge")

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
