extends SceneTree

# Tests L'Aeroport and the Security Cart Buggy (systems/aeroport.gd,
# entities/aeroport_threat.gd, intro/film_aeroport.gd):
# - registered in LEVELS, CAROUSEL, STAR_GATE, CHASE_GATE, LEVEL_NAMES, CAMPAIGN_SKY
# - the goals table has its goals
# - its chase profile has its script and its story film
# - the moving walkway (conveyor_zone) carries forward
# - the security cart rolls, steers toward the pair, and drops rolling suitcases
# - dodging clear of a tumbling suitcase awards a dodge; inside the radius hits
# - a continue restores the suitcase dodge and hit counts
# - the Gate Rush triggers on the way out, warns, crosses, and awards a dodge
# - barking at the carousel sets aeroport_carousel_barked

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
	game.level_id = "aeroport"
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
	m.auto_walk = false

	# --- 1. Level registration ---
	var A: GDScript = load("res://systems/aeroport.gd")
	var Threat: GDScript = load("res://entities/aeroport_threat.gd")
	var Film: GDScript = load("res://intro/film_aeroport.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")
	var CC: GDScript = load("res://systems/chase_checkpoint.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var Rails: GDScript = load("res://systems/rails.gd")

	_check(A != null, "systems/aeroport.gd loads")
	_check(Threat != null, "entities/aeroport_threat.gd loads")
	_check(Film != null, "intro/film_aeroport.gd loads")

	_check(game.LEVELS.has("aeroport"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("aeroport")
	_check(ci > 0 and ci < game.CAROUSEL.find("raval"), "in CAROUSEL before raval")
	_check(int(game.STAR_GATE["aeroport"]) == 51, "opens at 51 stars")
	_check(String(game.CHASE_GATE.get("aeroport", "")) == "cremada", "after La Cremada")
	_check(String(game.LEVEL_NAMES["aeroport"]) == "L'Aeroport", "named L'Aeroport")
	_check(game.CAMPAIGN_SKY["aeroport"] == ["clear", "day"], "a clear day inside terminal")

	# --- 2. Goals table ---
	_check(G.LEVEL_GOAL_IDS.has("aeroport"), "has goal list")
	var goals: Array = G.LEVEL_GOAL_IDS["aeroport"]
	_check(goals.has("walkway"), "moving walkway goal")
	_check(goals.has("gate_rush"), "gate rush goal")
	_check(goals.has("luggage_dodge"), "luggage dodge goal")
	_check(goals.has("security_clean"), "security clean run goal")
	_check(goals.has("carousel_bark"), "carousel bark goal")

	# --- 3. Chase profile and film ---
	var prof: Dictionary = HC.profile_for("aeroport")
	_check(not prof.is_empty(), "has a chase profile")
	_check(String(prof.get("kind", "")) == "buggy", "threat kind is buggy")
	_check(String(prof.get("script", "")) == "res://entities/aeroport_threat.gd", "threat script")
	_check(String(prof.get("film", "")) == "res://intro/film_aeroport.gd", "its film")
	_check(prof.get("bands", []).size() == 2, "two respites")

	# --- 4. Concourse layout and conveyor ---
	_check(m.conveyor_zone.size.y > 2000.0, "conveyor_zone spans terminal concourse")
	_check(m.conveyor_dir.y < 0.0, "conveyor carries northward")
	Rails.build(m)
	_check(m.rails.size() >= 2, "handrails registered as grindables")

	# --- 5. Threat setup, movement, and tumbling suitcases ---
	var threat = Threat.new()
	threat.setup(m, -4000.0, 640.0, 260.0, 136.0)
	root.add_child(threat)

	var y0: float = threat.front_y
	threat.advance(0.1, 300.0, 0.0)
	_check(threat.front_y > y0, "security cart advances")
	_check(not threat.jammed(), "not jammed in open concourse")

	# Advance until a suitcase is dropped
	threat.suitcase_t = 0.01
	threat.advance(0.02, 300.0, 0.0)
	_check(threat.suitcases.size() == 1, "cart drops a tumbling suitcase")

	# Suitcase landing and dodge detection
	var s: Dictionary = threat.suitcases[0]
	var target_at: Vector2 = s["at"]
	# Position dog safely nearby for a dodge
	m.dog.global_position = target_at + Vector2(threat.SUITCASE_DODGE_R - 10.0, 0.0)
	m.human.global_position = target_at + Vector2(250.0, 0.0)
	var dodges0: int = m.aeroport_luggage_dodges
	threat._land_suitcase(target_at)
	_check(m.aeroport_luggage_dodges == dodges0 + 1, "dog within dodge radius counts a luggage dodge")

	# Position dog right on the landing spot for a hit
	m.dog.global_position = target_at
	var hits0: int = m.aeroport_cart_hits
	threat._land_suitcase(target_at)
	_check(m.aeroport_cart_hits == hits0 + 1, "dog directly on landing spot takes a hit")

	# --- 6. Checkpoint persistence ---
	_check(CC.MAIN_FIELDS.has("aeroport_luggage_dodges") and CC.MAIN_FIELDS.has("aeroport_cart_hits"),
		"checkpoint snapshots aeroport luggage dodges and hits")

	# --- 7. Gate Rush Live Event ---
	m.phase = "out"
	m.aeroport_rush = {"state": "waiting", "t": 0.0}
	m.aeroport_rush_dodged = false
	m.human.global_position = Vector2(640.0, A.RUSH_TRIGGER_Y + 100.0)  # short of trigger
	A.tick(m, 0.1)
	_check(String(m.aeroport_rush.get("state", "")) == "waiting", "gate rush waiting before trigger")

	m.human.global_position = Vector2(640.0, A.RUSH_TRIGGER_Y - 50.0)  # crosses trigger
	A.tick(m, 0.1)
	_check(String(m.aeroport_rush.get("state", "")) == "warn", "gate rush enters warning state on trigger")

	# Advance through warn into running
	A.tick(m, A.RUSH_WARN_SECS + 0.1)
	_check(String(m.aeroport_rush.get("state", "")) == "running", "gate rush enters running state")

	# Place pair clear of the crossing and complete
	m.human.global_position = Vector2(640.0, A.GATE_RUSH_Y - 120.0)
	m.dog.global_position = Vector2(640.0, A.GATE_RUSH_Y - 140.0)
	A.tick(m, A.RUSH_CROSS_SECS + 0.5)
	_check(m.aeroport_rush_dodged, "staying clear of the gate rush awards the dodge")

	# --- 8. Baggage Carousel Bark ---
	m.aeroport_carousel_barked = false
	m.dog.global_position = Vector2(200.0, -1000.0)  # far away
	A.on_bark(m, m.dog.global_position)
	_check(not m.aeroport_carousel_barked, "barking far away does not count")

	m.dog.global_position = A.CAROUSEL_RECT.get_center()
	A.on_bark(m, m.dog.global_position)
	_check(m.aeroport_carousel_barked, "barking near baggage carousel sets aeroport_carousel_barked")

	if failures.is_empty():
		print("test_aeroport: %d checks, OK" % checks)
	else:
		print("test_aeroport: %d checks, %d FAILED" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
