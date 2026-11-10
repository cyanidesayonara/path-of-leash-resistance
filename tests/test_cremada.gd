extends SceneTree

# Tests La Cremada and the Dimoni float (systems/cremada.gd,
# entities/dimoni_threat.gd, systems/home_chase.gd's "dimoni" kind):
# - Registration: LEVELS, CAROUSEL (the chase slot after Plaça Reial), the
#   gates, the night sky, names, goals, the chase profile, its film and bands
# - The rockets: none before ROCKET_FIRST; a ring is aimed ahead of the float
#   at her, then your human, in turn; one landing on her knocks her, on your
#   human bumps them; one she is clear of but near is a dodge with a bone;
#   the autowalk bot is never hit; at most MAX_ROCKETS in the air
# - The float: it rolls, wedges at its jams and comes free; its catch line
# - The rocket banner while a ring fills near either of them
# - The traca: lit as your human comes up to it, telegraphed, a startle if
#   they are under it as it pops, a dodge and the goal if they are not

const DT := 1.0 / 60.0

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
	game.level_id = "cremada"
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
	var C: GDScript = load("res://systems/cremada.gd")
	var D: GDScript = load("res://entities/dimoni_threat.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration
	_check(game.LEVELS.has("cremada"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("cremada")
	_check(ci == 25, "the chase at campaign walk 25: %d" % ci)
	_check(game.CAROUSEL[ci - 1] == "reial", "after Plaça Reial")
	_check(int(game.STAR_GATE["cremada"]) == 36, "opens at 36 stars")
	_check(String(game.CHASE_GATE.get("cremada", "")) == "boars", "after Els Senglars")
	_check(String(game.LEVEL_NAMES["cremada"]) == "La Cremada", "named La Cremada")
	_check(game.CAMPAIGN_SKY["cremada"] == ["clear", "night"], "a clear night")
	_check(G.LEVEL_GOAL_IDS["cremada"].has("dimoni_dodge"), "the dodge goal")
	_check(G.LEVEL_GOAL_IDS["cremada"].has("traca"), "the traca goal")
	var prof: Dictionary = HC.profile_for("cremada")
	_check(String(prof.get("kind", "")) == "dimoni", "the Dimoni's chase")
	_check(String(prof.get("script", "")) == "res://entities/dimoni_threat.gd", "his float")
	_check(String(prof.get("film", "")) == "res://intro/film_cremada.gd", "his film")
	_check(load(String(prof.film)) != null, "the film loads")
	var bands: Array = prof.bands
	_check(bands.size() == 2 and float(bands[0].jam_y) == C.UNDERPASS_JAM_Y and float(bands[1].jam_y) == C.ARCH_JAM_Y,
		"the bands are the underpass and the arch")
	_check(m.chase_jams.size() == 2, "two jams built")
	_check(HC.kind_behavior("correfoc").get("warning") != prof.get("warning"), "not Gràcia's correfoc")

	# 2. The float and its rockets, driven by hand
	var f: Node2D = Node2D.new()
	f.set_script(D)
	m.add_child(f)
	f.setup(m, -3000.0, 640.0, C.HALF, 118.0)
	m.dog.global_position = Vector2(600.0, -2400.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.tumble_t = 0.0
	m.human.global_position = Vector2(700.0, -2300.0)
	m.human.velocity = Vector2.ZERO
	f.advance(D.ROCKET_FIRST * 0.5, 600.0, 0.0)
	_check(f.rockets.is_empty(), "nothing fired before ROCKET_FIRST")
	f.advance(D.ROCKET_FIRST * 0.5 + 0.02, 600.0, 0.0)
	_check(f.rockets.size() == 1, "the first rocket goes up")
	var r0: Dictionary = f.rockets[0]
	_check(Vector2(r0.at).distance_to(m.dog.global_position) < 5.0, "the first is aimed at her")
	_check(float(Vector2(r0.at).y) > f.front_y + D.ROCKET_MIN_AHEAD - 1.0, "it lands ahead of the float")
	f.fire_t = 0.0
	f.advance(DT, 600.0, 0.0)
	_check(f.rockets.size() == 2, "a second")
	_check(Vector2(f.rockets[1].at).distance_to(m.human.global_position) < 5.0, "the second at your human")
	f.fire_t = 0.0
	f.advance(DT, 600.0, 0.0)
	f.fire_t = 0.0
	f.advance(DT, 600.0, 0.0)
	_check(f.rockets.size() <= D.MAX_ROCKETS, "never more than MAX_ROCKETS in the air")
	_check(f.rocket_warning(), "a ring by them: the rocket banner")

	# the landings, one at a time
	f.rockets.clear()
	var hits0: int = m.dog_hits
	m.dog.tumble_t = 0.0
	f.land(m.dog.global_position + Vector2(10.0, 0.0))
	_check(m.dog_hits == hits0 + 1 and m.dog.tumble_t > 0.0, "a rocket on her knocks her")
	_check(m.cremada_hits == 1, "and counts a hit")
	m.dog.tumble_t = 0.0
	var bones0: int = m.bones
	var dodges0: int = m.cremada_dodges
	f.land(m.dog.global_position + Vector2(D.ROCKET_R + 30.0, 0.0))
	_check(m.cremada_dodges == dodges0 + 1, "clear of the ring but near: a dodge")
	_check(m.bones == bones0 + D.DODGE_BONES, "worth a bone")
	_check(m.dog.tumble_t <= 0.0, "and no knock")
	var far_dodges: int = m.cremada_dodges
	f.land(m.dog.global_position + Vector2(0.0, 600.0))
	_check(m.cremada_dodges == far_dodges, "nowhere near either: nothing")
	m.auto_walk = true
	var auto_hits: int = m.dog_hits
	m.dog.tumble_t = 0.0
	f.land(m.dog.global_position)
	_check(m.dog_hits == auto_hits, "the autowalk bot is never hit")
	m.auto_walk = false

	# a rocket counts down and lands by itself
	f.rockets.clear()
	f.rockets.append({"from": f.launcher(), "at": m.dog.global_position + Vector2(0.0, 900.0), "t": 0.0})
	f.fire_t = 99.0
	for i in range(int(D.ROCKET_WARN / DT) + 2):
		f.advance(DT, 600.0, 0.0)
	_check(f.rockets.is_empty(), "the ring fills, the rocket lands")

	# the roll, the jams
	var y0: float = f.front_y
	f.advance(0.5, 300.0, 0.0)
	_check(f.front_y > y0, "the float rolls on toward home")
	f.jams.clear()
	f.jams.append(Vector2(640.0, f.front_y + 1.0))
	f.advance(0.1, 300.0, 0.0)
	_check(f.jammed_now and f.jammed(), "it wedges at a jam")
	var yj: float = f.front_y
	f.advance(1.0, 300.0, 0.0)
	_check(is_equal_approx(f.front_y, yj), "and stays put while wedged")
	for i in range(int(D.JAM_SECS / 0.1) + 2):
		f.advance(0.1, 300.0, 0.0)
	_check(not f.jammed(), "then comes free")
	_check(f.caught(Vector2(640.0, f.front_y - 20.0)), "under its front: caught")
	_check(not f.caught(Vector2(640.0, f.front_y + 40.0)), "ahead of it: not caught")
	_check(f.gap_to(Vector2(640.0, f.front_y + 100.0)) > 99.0, "the gap is down the street")
	f.queue_free()

	# 3. The traca
	m.phase = "out"
	m.cremada_traca = {"state": "hung", "t": 0.0}
	m.cremada_traca_dodged = false
	m.human.global_position = Vector2(640.0, C.TRACA_Y + C.TRACA_NOTICE + 50.0)
	C.tick(m, DT)
	_check(String(m.cremada_traca.state) == "hung", "not lit while your human is short of it")
	m.human.global_position = Vector2(640.0, C.TRACA_Y + C.TRACA_NOTICE - 20.0)
	C.tick(m, DT)
	_check(String(m.cremada_traca.state) == "fuse", "lit as your human comes up to it")
	for i in range(int(C.TRACA_WARN / DT) + 1):
		C.tick(m, DT)
	_check(String(m.cremada_traca.state) == "pop", "the fuse burns TRACA_WARN, then it pops")
	for i in range(int(C.TRACA_POP / DT) + 2):
		C.tick(m, DT)
	_check(String(m.cremada_traca.state) == "spent" and m.cremada_traca_dodged, "held short of it: a dodge")
	m.cremada_traca = {"state": "hung", "t": 0.0}
	m.cremada_traca_dodged = false
	m.human.global_position = Vector2(640.0, C.TRACA_Y + C.TRACA_NOTICE - 20.0)
	C.tick(m, DT)
	m.human.global_position = Vector2(640.0, C.TRACA_Y + 10.0)
	for i in range(int((C.TRACA_WARN + C.TRACA_POP) / DT) + 4):
		C.tick(m, DT)
	_check(bool(m.cremada_traca.get("hit", false)) and not m.cremada_traca_dodged, "under it as it pops: startled, no dodge")
	m.phase = "home"
	m.cremada_traca = {"state": "hung", "t": 0.0}
	m.human.global_position = Vector2(640.0, C.TRACA_Y + 100.0)
	C.tick(m, DT)
	_check(String(m.cremada_traca.state) == "hung", "never lit on the way home")

	# 4. The parked figure is a solid, not a pole
	var solids: Array = C.solids(m)
	_check(solids.has(C.parked_rect()), "the parked float is solid")
	_check(C.parked_rect().position.y > float(m.freedom_lo), "and inside the beach")

	if failures.is_empty():
		print("test_cremada: %d checks, OK" % checks)
	else:
		print("test_cremada: %d checks, %d FAILED" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
