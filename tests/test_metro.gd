extends SceneTree

# Tests El Metro (systems/metro.gd):
# - registered in LEVELS, CAROUSEL (right after La Superilla), STAR_GATE (as
#   L'Estació), CHASE_GATE (as La Superilla), LEVEL_NAMES and its glosses,
#   CAMPAIGN_SKY (rain by day), the goals table
# - the ground: pavement on the street, tile in the hall and the passage
# - the light: the street's sky up top, the station's own lamps below, and
#   no rain on screen underground
# - the turnstile: your human says so FUMBLE_WARN before they stop to find
#   their card; a dog over the line meanwhile slipped under the bar
# - the car's doors: the chime CHIME_T before they move, a leash across a
#   door is caught (counted) and the doors reopen; a clear door rides, and
#   the train opens at the other end
# - the surge: announced, then the chime, and the crowd steps off only
#   SURGE_OPEN_T later; a dog planted in it holds and is paid
# - the busker goes home after dark (systems/outdoors.gd)

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
	game.level_id = "metro"
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

	var M: GDScript = load("res://systems/metro.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var O: GDScript = load("res://systems/outdoors.gd")
	var S: GDScript = load("res://world/surfaces.gd")

	# --- 1. registration ---
	_check(game.LEVELS.has("metro"), "in LEVELS")
	_check(game.LEVELS.find("metro") == game.LEVELS.find("superilla") + 1, "in LEVELS right after La Superilla")
	_check(game.CAROUSEL.find("metro") == game.CAROUSEL.find("superilla") + 1, "in CAROUSEL right after La Superilla")
	_check(int(game.STAR_GATE.get("metro", -1)) == int(game.STAR_GATE["station"]), "opens at L'Estació's star gate")
	_check(String(game.CHASE_GATE.get("metro", "")) == String(game.CHASE_GATE["superilla"]), "in La Superilla's chase tier")
	_check(String(game.LEVEL_NAMES["metro"]) == "El Metro", "named El Metro")
	_check(game.LEVEL_SUBTITLES.has("metro") and game.LEVEL_SUBTITLES_CA.has("metro") and game.LEVEL_SUBTITLES_ES.has("metro"),
		"glossed in English, Catalan and Spanish")
	_check(game.CAMPAIGN_SKY["metro"] == ["rain", "day"], "a rainy day")
	var ids: Array = G.LEVEL_GOAL_IDS["metro"]
	_check(ids.size() == 15 and ids.has("turnstile") and ids.has("surge") and ids.has("doors_clean"),
		"fifteen goals with the turnstile's, the surge's and the doors'")
	_check(m.metro != null, "the walk has its state")

	# --- 2. the ground ---
	_check(M.surface(m, Vector2(640.0, 0.0)) == S.S.PAVEMENT, "the street is pavement")
	_check(M.surface(m, Vector2(640.0, -1000.0)) == S.S.TILE, "the ticket hall is tile")
	_check(M.surface(m, Vector2(640.0, -2300.0)) == S.S.TILE, "the passage is tile")
	_check(M.surface(m, Vector2(640.0, -2900.0)) == S.S.TILE, "the platform is tile")

	# --- 3. the light ---
	_check(M.under_at(200.0) == 0.0 and M.under_at(-2000.0) == 1.0 and M.under_at(-4980.0) == 0.0,
		"the street at both ends, underground between")
	m.dog.global_position = Vector2(640.0, -2000.0)
	m.human.global_position = Vector2(640.0, -1950.0)
	M.tick(m, DT)
	_check((m.night_cm.color as Color).is_equal_approx(M.UNDER_TINT), "underground the station's own light, not the sky's")
	_check(m.weather_fx == null or not m.weather_fx.visible, "no rain on screen underground")
	m.dog.global_position = Vector2(640.0, 150.0)
	m.human.global_position = Vector2(640.0, 200.0)
	M.tick(m, DT)
	_check(m.weather_fx == null or m.weather_fx.visible, "the rain is back up on the street")

	# --- 4. the turnstile ---
	var st = m.metro
	var g = st.gate
	var gx: float = M.GATE_XS[M.HUMAN_GATE]
	m.human.homeward = false
	m.human.global_position = Vector2(gx, M.TURN_Y + 60.0)
	m.dog.global_position = Vector2(gx - 84.0, M.TURN_Y + 40.0)
	m.human.halt_t = 0.0
	M.tick(m, DT)
	_check(g.stage == 1, "short of the line, your human says so first")
	var warned := 0.0
	while g.stage == 1 and warned < 2.0:
		m.human.halt_t = 0.0
		M.tick(m, DT)
		warned += DT
	_check(absf(warned - M.FUMBLE_WARN) < 0.05, "the card hunt starts FUMBLE_WARN after the bubble (%.2f s)" % warned)
	M.tick(m, DT)
	_check(m.human.halt_t > 0.0, "and they stop to look")
	m.dog.global_position = Vector2(gx - 84.0, M.TURN_Y - 40.0)
	M.tick(m, DT)
	_check(m.metro_turnstile_slipped, "over the line meanwhile: under the bar")
	var fumble := 0.0
	while g.stage == 2 and fumble < 4.0:
		M.tick(m, DT)
		fumble += DT
	_check(g.stage == 3, "the card is found")
	m.human.global_position = Vector2(gx, M.TURN_Y - 80.0)
	M.tick(m, DT)
	_check(g.done_out, "through the gate, the fumble is over for the way out")

	# --- 5. the car's doors: a leash across the open door is caught ---
	var tr = st.train
	_check(tr.open_end == 1 and tr.gap_s >= 0.99 and tr.gap_n <= 0.01, "docked at Paraigües, the south door open")
	m.human.global_position = Vector2(640.0, M.CAR_S - 160.0)
	m.dog.global_position = Vector2(640.0, M.CAR_S + 60.0)
	_rope(m)
	M.tick(m, DT)
	_check(tr.state == tr.St.CHIME, "aboard: the chime")
	var chimed := 0.0
	while tr.state == tr.St.CHIME and chimed < 2.0:
		_check_gap_open(tr)
		M.tick(m, DT)
		chimed += DT
	_check(absf(chimed - M.CHIME_T) < 0.05, "the doors move CHIME_T after the chime (%.2f s)" % chimed)
	var catches0: int = m.metro_door_catches
	var closing := 0.0
	while tr.state == tr.St.CLOSING and closing < 2.0:
		_rope(m)
		M.tick(m, DT)
		closing += DT
	_check(tr.state == tr.St.CAUGHT, "a leash across the door is caught")
	_check(m.metro_door_catches == catches0 + 1, "and counted")
	var t := 0.0
	while tr.state != tr.St.DOCKED and t < 4.0:
		_rope(m)
		M.tick(m, DT)
		t += DT
	_check(tr.state == tr.St.DOCKED and tr.gap_s >= 0.99, "the doors open again")

	# --- 6. both aboard: the ride, and out at Sant Gos ---
	m.dog.global_position = Vector2(600.0, M.CAR_S - 200.0)
	_rope(m)
	t = 0.0
	var rode := false
	while t < 20.0:
		m.human.global_position = Vector2(640.0, M.CAR_S - 160.0)
		m.dog.global_position = Vector2(600.0, M.CAR_S - 200.0)
		_rope(m)
		M.tick(m, DT)
		t += DT
		rode = rode or tr.state == tr.St.RIDE
		if tr.rides > 0 and tr.state == tr.St.DOCKED:
			break
	_check(rode, "a clear door closes and the train rides")
	_check(m.metro_door_catches == catches0 + 1, "a clear door catches nothing")
	_check(tr.rides == 1 and tr.open_end == -1, "one stop: the north door opens at Sant Gos")
	_check(tr.gap_n >= 0.99 and tr.gap_s <= 0.01, "and the south door stays shut")

	# --- 7. the surge ---
	var s = st.surge
	s.state = s.St.IDLE
	s.done_out = false
	m.human.global_position = Vector2(560.0, -2900.0)
	m.dog.global_position = Vector2(560.0, -2860.0)
	m.dog.planted = false
	M.tick(m, DT)
	_check(s.state == s.St.ARRIVE, "on the platform, a train in on the other track")
	var opened_at := -1.0
	var first_off := -1.0
	t = 0.0
	while t < 8.0 and first_off < 0.0:
		M.tick(m, DT)
		t += DT
		if opened_at < 0.0 and s.state == s.St.OPEN:
			opened_at = t
		if s.spawned > 0:
			first_off = t
	_check(opened_at > 0.0 and first_off > 0.0, "the chime, then the crowd")
	_check(first_off - opened_at >= M.SURGE_OPEN_T - 0.02, "the crowd steps off SURGE_OPEN_T after the chime (%.2f s)" % (first_off - opened_at))
	# planted in the crowd's way until it holds
	m.dog.planted = true
	t = 0.0
	while t < 8.0 and not m.metro_surge_held:
		for p: Dictionary in st.people:
			if String(p.mode) == "flow":
				m.dog.global_position = (p.p as Vector2) + Vector2(0.0, 20.0)
				break
		M.tick(m, DT)
		t += DT
	_check(m.metro_surge_held, "dug in against the crowd: rock solid")
	m.dog.planted = false

	# --- 8. who is out ---
	_check(O.underground_busker("rain", "day") and not O.underground_busker("clear", "night"), "the busker plays in the rain, not after dark")
	_check(O.underground_crowd(26, "rain", "day") == 26, "rain does not thin the underground crowd")
	_check(O.umbrella_shakers("rain", "day") and not O.umbrella_shakers("clear", "day"), "umbrellas shaken out only when it rains")

	print("test_metro: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)


# the rope, straight from the dog to your human
func _rope(m: Node2D) -> void:
	var a: Vector2 = m.dog.global_position
	var b: Vector2 = m.human.global_position
	var n: int = m.leash.pts.size()
	for i in range(n):
		m.leash.pts[i] = a.lerp(b, float(i) / float(maxi(1, n - 1)))


func _check_gap_open(tr) -> void:
	if tr.gap_s < 0.99:
		_check(false, "the doors stay open through the chime")
