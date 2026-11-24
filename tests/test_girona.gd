extends SceneTree

# Regression test for Walk 41 (Girona).
# Placement, walkability, solids, all 5 zones + Onyar water, cascade telegraph &
# dry-save/soak paths, Onyar front sniffs, lamps/fronts,
# florist dare-giver, petals gate sign, music, and goals.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		printerr("FAIL: ", msg)


func _initialize() -> void:
	call_deferred("_run")


func _load_walk(game: Node) -> Node2D:
	game.weather = "rain"
	game.hour = "dusk"
	game.level_id = "girona"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for _k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = false
	return m


func _run() -> void:
	var Girona = load("res://systems/girona.gd")
	var LevelBuild = load("res://world/level_build.gd")
	var LevelCheck = load("res://world/level_check.gd")
	var Surfaces = load("res://world/surfaces.gd")
	var WorldSign = load("res://world/world_sign.gd")
	var Challenger = load("res://entities/challenger.gd")
	var Music = load("res://audio/music.gd")
	var Goals = load("res://systems/goals.gd")
	var TonyHawk = load("res://systems/tony_hawk.gd")

	var game := root.get_node("/root/Game")
	var keep_lvl: String = game.level_id
	var keep_w: String = game.weather
	var keep_h: String = game.hour

	# --- registration & campaign placement ---
	_check(game.LEVELS.has("girona"), "girona present in Game.LEVELS")
	var idx: int = game.CAROUSEL.find("girona")
	_check(idx == 41, "CAROUSEL places girona at index 41 (got %d)" % idx)
	_check(game.CAROUSEL[40] == "atraccions" and game.CAROUSEL[42] == "site",
		"CAROUSEL places girona between atraccions and site")
	_check(int(game.STAR_GATE.get("girona", -1)) == 47, "STAR_GATE girona == 47")
	_check(String(game.CHASE_GATE.get("girona", "")) == "molina", "CHASE_GATE girona == molina")
	_check(game.CAMPAIGN_SKY.get("girona", []) == ["rain", "dusk"], "CAMPAIGN_SKY girona == [rain, dusk]")
	_check(game.WALKS_SINCE_GATES.has("girona"), "WALKS_SINCE_GATES includes girona")
	_check(String(game.LEVEL_NAMES.get("girona", "")) == "Girona", "LEVEL_NAMES girona")
	_check(String(game.LEVEL_SUBTITLES.get("girona", "")).length() > 0, "LEVEL_SUBTITLES girona")
	_check(String(game.LEVEL_SUBTITLES_CA.get("girona", "")).length() > 0, "LEVEL_SUBTITLES_CA girona")
	_check(String(game.LEVEL_SUBTITLES_ES.get("girona", "")).length() > 0, "LEVEL_SUBTITLES_ES girona")

	_check(String(Challenger.WHO.get("girona", "")) == "florist", "Challenger WHO girona == florist")
	_check(Challenger.AT.has("girona"), "Challenger AT has girona")
	_check(Challenger.LINES.has("florist"), "Challenger LINES has florist")
	_check(Challenger.FOOTPRINT.has("florist"), "Challenger FOOTPRINT has florist")
	_check(Music.STYLES.has("girona"), "Music STYLES has girona")
	_check(Music.DARES.has("florist"), "Music DARES has florist")
	_check(String(WorldSign.MATERIALS.get("girona", "")) == "petals", "WorldSign MATERIALS girona == petals")
	_check(WorldSign.FEEL.has("petals"), "WorldSign FEEL has petals")
	_check(Goals.LEVEL_GOAL_IDS.has("girona"), "Goals has girona")
	var goal_ids: Array = Goals.LEVEL_GOAL_IDS.get("girona", [])
	_check(goal_ids.size() == 15, "girona has 15 goals (got %d)" % goal_ids.size())
	_check(goal_ids.has("girona_houses") and goal_ids.has("girona_steps") and goal_ids.has("lleona_hide"),
		"girona goal ids include all three signature goals")
	_check(int(TonyHawk.CLOCK_TARGETS.get("girona", 0)) == 195, "TonyHawk CLOCK_TARGETS girona == 195")
	_check(TonyHawk.JAMON_POS.has("girona"), "TonyHawk JAMON_POS has girona")

	var m := await _load_walk(game)
	_check(m != null and is_instance_valid(m), "main loaded for girona")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on girona: %s" % [issues])

	# --- solids & freedom props ---
	_check(LevelBuild.FREEDOM_PROPS.has("girona"), "FREEDOM_PROPS has girona")
	_check(LevelBuild.FREEDOM_PROPS.get("girona", []).size() == 12, "FREEDOM_PROPS girona has 12 props")
	var gsolids: Array = Girona.solids(m)
	_check(gsolids.size() == 13, "Girona.solids returns 13 solids (got %d)" % gsolids.size())
	var solid_map: Dictionary = {}
	for pair in LevelBuild.level_solid_rects(m):
		solid_map[String(pair[0])] = pair[1]
	for si in range(gsolids.size()):
		var sk := "girona_solid_%d" % si
		_check(solid_map.has(sk) and solid_map[sk] == gsolids[si], "level_solid_rects matches %s" % sk)

	# --- surfaces across all 5 zones + Onyar ---
	_check(Girona.surface(m, Vector2(640.0, -300.0)) == Surfaces.S.PAVEMENT, "Rambla pavement")
	_check(Girona.surface(m, Vector2(300.0, -300.0)) == Surfaces.S.WATER, "Rambla west Onyar water")
	_check(Girona.surface(m, Vector2(640.0, -1250.0)) == Surfaces.S.PAVEMENT, "Eiffel bridge deck pavement")
	_check(Girona.surface(m, Vector2(300.0, -1250.0)) == Surfaces.S.WATER, "Onyar west under bridge")
	_check(Girona.surface(m, Vector2(1000.0, -1250.0)) == Surfaces.S.WATER, "Onyar east under bridge")
	_check(Girona.surface(m, Vector2(640.0, -2100.0)) == Surfaces.S.PAVEMENT, "Barri Vell steps idle pavement")
	_check(Girona.surface(m, Vector2(640.0, -3100.0)) == Surfaces.S.PAVEMENT, "Plaça de Sant Feliu pavement")
	_check(Girona.surface(m, Vector2(200.0, -3100.0)) == Surfaces.S.WATER, "Onyar west of Sant Feliu")
	_check(Girona.surface(m, Vector2(640.0, -4400.0)) == Surfaces.S.PAVEMENT, "Muralles pavement")
	_check(Girona.surface(m, Vector2(640.0, -5200.0)) == Surfaces.S.GRASS, "Jardins dels Alemanys freedom grass")

	# --- dusk lights & night fronts ---
	_check(game.lamp_glow() > 0.0, "dusk rain lights lamps (glow > 0)")
	var nlights: Array = Girona.night_lights(m)
	_check(nlights.size() >= Girona.STREET_LAMPS.size() + Girona.HOUSE_SNIFFS.size(),
		"night_lights covers lamps and Onyar sniff windows")
	var nfronts: Array = Girona.night_fronts(m)
	_check(not nfronts.is_empty(), "night_fronts has Rambla and Barri Vell doorways")

	# --- steps cascade live event: telegraph >= 0.8s, wet hit, dry save ---
	m.human_soak = 0.0
	m.dog.global_position = Vector2(640.0, -2100.0)
	m.human.global_position = Vector2(640.0, -2420.0)
	m.dog.velocity = Vector2.ZERO
	m.girona_spout = {"state": "idle", "t": 0.05, "threatened": false, "hit": false, "warned": false, "saved_this": false}
	Girona.tick(m, 0.1)
	_check(String(m.girona_spout.get("state", "")) == "warn", "cascade enters warn state on steps")
	_check(float(m.girona_spout.get("t", 0.0)) >= 0.8, "cascade telegraph >= 0.8s (SPOUT_WARN=1.0)")
	_check(Girona.idle_status(m).length() > 0, "idle_status active during warn")
	Girona.tick(m, 0.4)
	_check(String(m.girona_spout.get("state", "")) == "warn", "still telegraphing at 0.4s")
	_check(is_zero_approx(float(m.human_soak)), "no soak during warn telegraph")

	# Finish warn into rush -> centre of steps turns to water and soaks human inside band
	Girona.tick(m, 0.7)
	_check(String(m.girona_spout.get("state", "")) == "rush", "cascade enters rush after warn")
	_check(Girona.idle_status(m).length() > 0, "idle_status active during rush")
	Girona.tick(m, 0.25)
	_check(Girona.surface(m, Vector2(640.0, -2420.0)) == Surfaces.S.WATER, "active rush wets centre of steps")
	_check(bool(m.girona_spout.get("hit", false)) and float(m.human_soak) > 0.0, "centre hit soaks human")

	# Dry save when tucked under covered side alcove
	m.human.global_position = Vector2(468.0, -2100.0)
	m.dog.global_position = Vector2(460.0, -2100.0)
	m.girona_steps_saved = 0
	m.girona_spout = {"state": "warn", "t": 0.05, "threatened": true, "hit": false, "warned": true, "saved_this": false}
	Girona.tick(m, 0.1)
	_check(String(m.girona_spout.get("state", "")) == "rush", "dry-save test enters rush")
	Girona.tick(m, 2.7)
	_check(m.girona_steps_saved >= 1, "staying dry on side alcove increments girona_steps_saved")

	# --- Onyar house sniffs (La Lleona's fight is tests/test_lleona.gd) ---
	m.girona_houses_sniffed = {}
	m.dog.global_position = Girona.HOUSE_SNIFFS[0]
	m.dog.velocity = Vector2.ZERO
	Girona.tick(m, 0.05)
	_check(m.girona_houses_sniffed.has(0), "sniffing HOUSE_SNIFFS[0] records index 0")

	m.queue_free()
	await physics_frame
	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_girona: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_girona: %d FAILURES" % failures.size())
		quit(1)
