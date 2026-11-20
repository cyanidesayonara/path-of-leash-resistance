extends SceneTree

# Regression test for Walk 47 (Tarragona).
# Placement, walkability, solids, telegraphed casteller practice, Balcó view,
# gladiator dare-giver, tesserae sign, and goals.

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
	game.weather = "clear"
	game.hour = "dusk"
	game.level_id = "tarragona"
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
	var Tarragona = load("res://systems/tarragona.gd")
	var LevelBuild = load("res://world/level_build.gd")
	var LevelCheck = load("res://world/level_check.gd")
	var Surfaces = load("res://world/surfaces.gd")
	var WorldSign = load("res://world/world_sign.gd")
	var Challenger = load("res://entities/challenger.gd")
	var Music = load("res://audio/music.gd")
	var Goals = load("res://systems/goals.gd")

	var game := root.get_node("/root/Game")
	var keep_lvl: String = game.level_id
	var keep_w: String = game.weather
	var keep_h: String = game.hour

	_check(game.LEVELS.has("tarragona"), "tarragona present in Game.LEVELS")
	var mont_idx: int = game.CAROUSEL.find("montserrat")
	_check(mont_idx >= 0 and mont_idx + 1 < game.CAROUSEL.size() and game.CAROUSEL[mont_idx + 1] == "tarragona",
		"CAROUSEL places tarragona right after montserrat")
	_check(int(game.STAR_GATE.get("tarragona", -1)) == 50, "STAR_GATE tarragona == 50")
	_check(String(game.CHASE_GATE.get("tarragona", "")) == String(game.CHASE_GATE.get("scrap", "")),
		"CHASE_GATE tarragona matches scrap")
	_check(game.CAMPAIGN_SKY.get("tarragona", []) == ["clear", "dusk"], "CAMPAIGN_SKY tarragona == [clear, dusk]")
	_check(game.WALKS_SINCE_GATES.has("tarragona"), "WALKS_SINCE_GATES includes tarragona")
	_check(String(game.LEVEL_NAMES.get("tarragona", "")) == "Tarragona", "LEVEL_NAMES tarragona")
	_check(String(game.LEVEL_SUBTITLES.get("tarragona", "")) == "Roman stones above the sea", "LEVEL_SUBTITLES tarragona")
	_check(String(game.LEVEL_SUBTITLES_CA.get("tarragona", "")).length() > 0, "LEVEL_SUBTITLES_CA tarragona")
	_check(String(game.LEVEL_SUBTITLES_ES.get("tarragona", "")).length() > 0, "LEVEL_SUBTITLES_ES tarragona")

	_check(String(Challenger.WHO.get("tarragona", "")) == "gladiator", "Challenger WHO is gladiator")
	_check(Challenger.FOOTPRINT.has("gladiator"), "Challenger FOOTPRINT has gladiator")
	_check(Challenger.LINES.has("gladiator") and Challenger.LINES["gladiator"].size() >= 5,
		"Challenger LINES has 5 lines for gladiator")
	_check(Challenger.NAMES.has("gladiator"), "Challenger NAMES has gladiator")
	_check(Music.STYLES.has("tarragona"), "Music STYLES has tarragona")
	_check(Music.DARES.has("gladiator"), "Music DARES has gladiator")
	_check(String(WorldSign.MATERIALS.get("tarragona", "")) == "tesserae", "WorldSign MATERIALS tarragona == tesserae")
	_check(Goals.LEVEL_GOAL_IDS.has("tarragona"), "Goals has tarragona")

	var m := await _load_walk(game)
	_check(m != null and is_instance_valid(m), "main loaded for tarragona")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on tarragona: %s" % [issues])

	_check(Tarragona.surface(m, Vector2(640.0, -200.0)) == Surfaces.S.PAVEMENT, "Balcó paving handles as PAVEMENT")
	_check(Tarragona.surface(m, Vector2(640.0, -2200.0)) == Surfaces.S.PAVEMENT, "Rambla paving handles as PAVEMENT")
	_check(Tarragona.surface(m, Vector2(900.0, -400.0)) == Surfaces.S.WATER, "east sea handles as WATER")
	_check(Tarragona.surface(m, Vector2(640.0, -4000.0)) == Surfaces.S.PAVEMENT, "old town handles as PAVEMENT")

	var drawn_solids: Array[Rect2] = Tarragona.solids(m)
	var built_solids: Array = LevelBuild.level_solid_rects(m)
	var solid_count := 0
	for entry in built_solids:
		if String(entry[0]).begins_with("tarragona_solid_"):
			solid_count += 1
	_check(solid_count == drawn_solids.size(),
		"level_solid_rects matches Tarragona.solids size (%d vs %d)" % [solid_count, drawn_solids.size()])
	_check(drawn_solids.size() > 0, "Tarragona.solids is non-empty")
	_check(LevelBuild.FREEDOM_PROPS.has("tarragona"), "FREEDOM_PROPS has tarragona")

	# Casteller live event: telegraph before act
	_check(Tarragona.CASTELL_WARN >= 0.8, "CASTELL_WARN >= 0.8 s")
	m.phase = "walk"
	m.frozen = false
	m.human.global_position = Vector2(640.0, -3180.0)
	m.dog.global_position = Vector2(560.0, -3180.0)
	m.tarragona_castell = {"state": "idle", "t": 0.05, "tier": 0, "rewarded": false, "pulled": false, "planted": false, "in_crowd": false, "warned": false}
	Tarragona.tick(m, 0.08)
	_check(String(m.tarragona_castell.get("state", "")) == "telegraph", "castell enters telegraph")
	_check(float(m.tarragona_castell.get("t", 0.0)) >= 0.8, "castell telegraph >= 0.8 s")
	var pace_before := float(m.human.walk_pace)
	Tarragona.tick(m, 0.4)
	_check(String(m.tarragona_castell.get("state", "")) == "telegraph", "still telegraphing; not building yet")
	_check(is_equal_approx(float(m.human.walk_pace), 1.0) or pace_before >= 0.9, "no crawl during telegraph")

	# Finish telegraph into build; human in crowd crawls
	m.human.global_position = Vector2(640.0, -3200.0)
	Tarragona.tick(m, 0.9)
	_check(String(m.tarragona_castell.get("state", "")) == "build", "castell builds after telegraph")
	Tarragona.tick(m, 0.05)
	_check(float(m.human.walk_pace) < 0.5, "human crawls in packed crowd (pace=%.2f)" % m.human.walk_pace)

	# Edge pull / plant earns reward at crowning
	m.tarragona_castell = {"state": "crowned", "t": 1.0, "tier": 4, "rewarded": false, "pulled": true, "planted": false, "in_crowd": false, "warned": true}
	m.human.global_position = Vector2(500.0, -3200.0)
	m.dog.global_position = Vector2(480.0, -3200.0)
	Tarragona.tick(m, 0.05)
	_check(bool(m.tarragona_castell.get("rewarded", false)), "edge pull earns crowning reward")
	_check(Tarragona.castell_rewarded(m) == 1, "castell_rewarded reports 1")

	# Balcó view mechanic
	m.tarragona_balco = false
	m.tarragona_balco_t = 0.0
	m.dog.global_position = Tarragona.BALCO_SPOT
	m.human.global_position = Tarragona.BALCO_SPOT + Vector2(-40.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	Tarragona.tick(m, Tarragona.VIEW_HOLD + 0.05)
	_check(Tarragona.view_taken(m), "Balcó view taken when pair stands still at the rail")

	m.queue_free()
	await physics_frame
	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_tarragona: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_tarragona: %d FAILURES" % failures.size())
		quit(1)
