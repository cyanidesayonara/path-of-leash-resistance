extends SceneTree

# Regression test for Fira de Santa Llúcia (llucia).
# Verifies campaign placement, walkability, solids-match-drawn, telegraphed
# Caga Tió live event, caroler dare-giver, tinsel sign, and goals.

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
	game.hour = "evening"
	game.level_id = "llucia"
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
	var Llucia = load("res://systems/llucia.gd")
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

	_check(game.LEVELS.has("llucia"), "llucia present in Game.LEVELS")
	var idx: int = game.CAROUSEL.find("llucia")
	_check(idx == 36 and game.CAROUSEL[35] == "blai" and game.CAROUSEL[37] == "horta",
		"CAROUSEL places llucia at index 36 between blai and horta (got %d)" % idx)
	_check(int(game.STAR_GATE.get("llucia", -1)) == 42, "STAR_GATE llucia == 42")
	_check(String(game.CHASE_GATE.get("llucia", "")) == "aeroport", "CHASE_GATE llucia == aeroport")
	_check(game.CAMPAIGN_SKY.get("llucia", []) == ["clear", "evening"], "CAMPAIGN_SKY == [clear, evening]")
	_check(String(Challenger.WHO.get("llucia", "")) == "caroler", "Challenger WHO == caroler")
	_check(Music.STYLES.has("llucia") and Music.DARES.has("caroler"), "Music has llucia & caroler")
	_check(String(WorldSign.MATERIALS.get("llucia", "")) == "tinsel", "WorldSign MATERIALS == tinsel")
	_check(WorldSign.FEEL.has("tinsel"), "WorldSign FEEL has tinsel")
	var gids: Array = Goals.LEVEL_GOAL_IDS.get("llucia", [])
	_check(gids.size() == 15 and gids.has("llucia_stalls") and gids.has("llucia_tio"), "15 goals wired")
	_check(TonyHawk.CLOCK_TARGETS.has("llucia") and TonyHawk.JAMON_POS.has("llucia"), "TonyHawk wired")

	var m := await _load_walk(game)
	_check(m != null and is_instance_valid(m), "main loaded for llucia")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on llucia: %s" % [issues])

	var solids: Array = Llucia.solids(m)
	var solid_map: Dictionary = {}
	for pair in LevelBuild.level_solid_rects(m):
		solid_map[String(pair[0])] = pair[1]
	for si in range(solids.size()):
		var sk := "llucia_solid_%d" % si
		_check(solid_map.has(sk) and solid_map[sk] == solids[si], "level_solid_rects matches %s" % sk)

	_check(Llucia.surface(m, Vector2(640.0, -300.0)) == Surfaces.S.PAVEMENT, "approach PAVEMENT")
	_check(Llucia.surface(m, Vector2(640.0, -5200.0)) == Surfaces.S.PAVEMENT, "Plaça de la Catedral paved freedom")
	_check(Llucia.night_lights(m).size() >= Llucia.LAMPS.size() + Llucia.STALLS.size(), "night lights")

	# Live event + torró snatch
	m.dog.global_position = Llucia.TIO_SPOTS[0] + Vector2(60.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = Llucia.TIO_SPOTS[0] + Vector2(90.0, 40.0)
	m.llucia_tio = {"state": "idle", "idx": 0, "t": 0.02, "spot": Llucia.TIO_SPOTS[0], "target": Vector2.ZERO, "torro": Vector2.ZERO, "torro_active": false, "hit": false}
	Llucia.tick(m, 0.05)
	_check(String(m.llucia_tio.get("state", "")) == "warn", "tio enters warn")
	_check(float(m.llucia_tio.get("t", 0.0)) >= 0.8, "tio telegraph >= 0.8s")
	_check(Llucia.idle_status(m).length() > 0, "idle_status active during warn")
	m.dog.global_position = Vector2(640.0, -400.0)
	m.human.global_position = Vector2(640.0, -340.0)
	Llucia.tick(m, 1.2)
	_check(String(m.llucia_tio.get("state", "")) == "drop" and m.llucia_tio_dodged >= 1, "clean tio dodge")
	var pre_bones: int = m.bones
	m.dog.global_position = Vector2(m.llucia_tio["torro"])
	Llucia.tick(m, 0.05)
	_check(m.bones == pre_bones + 2 and not bool(m.llucia_tio.get("torro_active", true)), "torro snatched")

	m.queue_free()
	await physics_frame
	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_llucia: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_llucia: %d FAILURES" % failures.size())
		quit(1)
