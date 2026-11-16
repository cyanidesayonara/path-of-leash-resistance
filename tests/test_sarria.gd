extends SceneTree

# Tests Sarrià (systems/sarria.gd):
# - registered in LEVELS and CAROUSEL right before El Bosc, with El Bosc's
#   star gate and chase gate, its name, glosses, dawn sky and goals
# - the street's shape is valid and every solid stands on the paving
# - the bells: the clock whirs WARN (0.8 s) before the first strike, never
#   sooner; the strike puts up the plaça's pigeons and makes a dog near the
#   tower BARKY; barking while they ring is the howl; they ring once out and
#   once home, and not for a pair that is already past the plaça
# - her nose at a bakery door counts each bakery once
# - a bark at the balcony gardener is a good morning, once
# - who is out follows the sky (systems/outdoors.gd)

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
	game.level_id = "sarria"
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

	var S: GDScript = load("res://systems/sarria.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var O: GDScript = load("res://systems/outdoors.gd")
	var EP: GDScript = load("res://world/edge_path.gd")
	var Mood: GDScript = load("res://systems/mood.gd")

	# --- 1. registration ---
	_check(game.LEVELS.has("sarria"), "in LEVELS")
	_check(game.LEVELS.find("sarria") + 1 == game.LEVELS.find("trail"), "in LEVELS right before El Bosc")
	_check(game.CAROUSEL.find("sarria") + 1 == game.CAROUSEL.find("trail"), "in CAROUSEL right before El Bosc")
	_check(int(game.STAR_GATE["sarria"]) == int(game.STAR_GATE["trail"]), "El Bosc's star gate")
	_check(String(game.CHASE_GATE["sarria"]) == String(game.CHASE_GATE["trail"]), "El Bosc's chase gate")
	_check(String(game.LEVEL_NAMES["sarria"]) == "Sarrià", "named Sarrià")
	_check(game.LEVEL_SUBTITLES.has("sarria") and game.LEVEL_SUBTITLES_CA.has("sarria") and game.LEVEL_SUBTITLES_ES.has("sarria"), "glossed in English, Catalan and Spanish")
	_check(game.CAMPAIGN_SKY["sarria"] == ["clear", "dawn"], "a clear dawn")
	_check(game.WALKS_SINCE_GATES.has("sarria"), "no save predates its gate")
	var ids: Array = G.LEVEL_GOAL_IDS["sarria"]
	_check(ids.size() == 15 and ids.has("bells") and ids.has("bread") and ids.has("gardener"), "fifteen goals with the bells', the bakeries' and the gardener's")
	_check(m.sarria != null, "the walk has its state")

	# --- 2. the shape ---
	_check(bool(EP.valid(S.NODES).ok), "the street's nodes are a walkable path")
	for r: Rect2 in S.solids(m):
		var e: Vector2 = m.walk_edges(r.get_center().y)
		_check(r.position.x >= e.x - 1.0 and r.end.x <= e.y + 1.0, "solid %s stands on the paving" % str(r))
	_check(S.in_placa(S.FOUNTAIN), "the fountain is on the plaça")

	# --- 3. the bells ---
	var st = m.sarria
	m.phase = "out"
	m.human.global_position = Vector2(640.0, -1800.0)
	m.dog.global_position = Vector2(640.0, -1900.0)
	S.tick(m, DT)
	_check(st.bell == "idle", "quiet below the approach")
	var pig := Node2D.new()
	pig.set_script(load("res://entities/pigeon.gd"))
	pig.position = Vector2(700.0, -2700.0)
	m.add_child(pig)
	pig.setup(m, m.dog, m.human, false)
	pig.wary = 0.0
	m.mood.reset()
	m.dog.global_position = Vector2(560.0, -2250.0)
	var t := 0.0
	var warned_at := -1.0
	var struck_at := -1.0
	while t < 3.0:
		S.tick(m, DT)
		t += DT
		if warned_at < 0.0 and st.bell == "warn":
			warned_at = t
		if struck_at < 0.0 and st.bell == "ring":
			struck_at = t
	_check(warned_at > 0.0, "the clock whirs first")
	_check(struck_at > 0.0 and struck_at - warned_at >= S.WARN - DT * 1.5, "the first strike comes WARN after the whir (%.2f s)" % (struck_at - warned_at))
	_check(bool(pig.flying), "the strike puts the plaça's pigeons up")
	_check(float(m.mood.charge[Mood.M.BARKY]) >= 0.5, "a dog near the tower goes BARKY")
	_check(st.strikes_left < int(S.STRIKES["dawn"]), "it strikes the hour")
	S.on_bark(m, m.dog.global_position)
	_check(st.howled, "barking while it rings is howling along")
	var bells_def: Dictionary = G.defs(m)["bells"]
	_check(int(bells_def.fn.call()) == 1, "and counts for the bells goal")
	while st.bell != "idle" and t < 20.0:
		S.tick(m, DT)
		t += DT
	_check(st.bell == "idle", "the bells stop")
	S.tick(m, DT)
	_check(st.bell == "idle", "and ring only once on the way out")
	m.phase = "home"
	m.dog.global_position = Vector2(640.0, -3300.0)
	S.tick(m, DT)
	_check(st.bell == "warn" and st.strikes_left == S.QUARTER, "the quarter on the way home")
	m.phase = "out"
	# a pair that starts beyond the plaça never hears them
	var st2 = S.State.new()
	st2.shutters.assign([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	st2.rolled.assign([false, false, false, false, false, false])
	m.sarria = st2
	m.dog.global_position = Vector2(640.0, -4300.0)
	S.tick(m, DT)
	_check(st2.bell == "idle", "no bells for a pair already past the plaça")

	# --- 4. the bakeries ---
	var doors: Array = S.bakery_doors()
	m.dog.velocity = Vector2.ZERO
	m.dog.global_position = doors[0]
	for i in range(90):
		S.tick(m, DT)
	_check(S.bread_sniffed(m) == 1, "a still nose at the first bakery door counts")
	for i in range(90):
		S.tick(m, DT)
	_check(S.bread_sniffed(m) == 1, "once")
	m.dog.global_position = doors[1]
	for i in range(90):
		S.tick(m, DT)
	_check(S.bread_sniffed(m) == 2, "and the second bakery too")

	# --- 5. the gardener ---
	S.on_bark(m, S.gardener_pos() + Vector2(60.0, 0.0))
	_check(st2.greeted, "a bark at the balcony is a good morning")
	_check(int((G.defs(m)["gardener"] as Dictionary).fn.call()) == 1, "and counts for the gardener goal")

	# --- 6. who is out ---
	_check(O.bakery_open("rain", "dawn") and not O.bakery_open("clear", "night"), "bakeries open from first light, shut at night")
	_check(O.shops_open("snow", "day") and not O.shops_open("clear", "night"), "shops shut only at night")
	_check(O.street_sweeping("rain", "dawn") and O.street_sweeping("clear", "night") and not O.street_sweeping("clear", "day"), "sweepers on the early and late shifts")
	_check(O.jogging("clear", "dawn") and not O.jogging("rain", "day") and not O.jogging("clear", "night"), "joggers in the dry and the light")
	_check(O.watering_plants("clear", "dawn") and O.watering_plants("wind", "dusk") and not O.watering_plants("clear", "day") and not O.watering_plants("rain", "dawn"), "plants watered morning and evening, never in rain")

	print("test_sarria: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
