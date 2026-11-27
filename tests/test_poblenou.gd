extends SceneTree

# Regression test for Rambla del Poblenou (poblenou).
# Verifies campaign placement, walkability, solids-match-drawn, telegraphed
# horchata tray live event, horchatero dare-giver, farton sign, and goals.

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
	game.weather = "breeze"
	game.hour = "morning"
	game.level_id = "poblenou"
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
	var Poblenou = load("res://systems/poblenou.gd")
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

	_check(game.LEVELS.has("poblenou"), "poblenou present in Game.LEVELS")
	var idx: int = game.CAROUSEL.find("poblenou")
	_check(idx == 14 and game.CAROUSEL[13] == "eixample" and game.CAROUSEL[15] == "tibidabo",
		"CAROUSEL places poblenou at index 14 between eixample and tibidabo (got %d)" % idx)
	_check(int(game.STAR_GATE.get("poblenou", -1)) == 17, "STAR_GATE poblenou == 17")
	_check(String(game.CHASE_GATE.get("poblenou", "")) == "besos", "CHASE_GATE poblenou == besos")
	_check(game.CAMPAIGN_SKY.get("poblenou", []) == ["breeze", "morning"], "CAMPAIGN_SKY poblenou == [breeze, morning]")
	_check(String(Challenger.WHO.get("poblenou", "")) == "horchatero", "Challenger WHO == horchatero")
	_check(Music.STYLES.has("poblenou") and Music.DARES.has("horchatero"), "Music has poblenou & horchatero")
	_check(String(WorldSign.MATERIALS.get("poblenou", "")) == "fartons", "WorldSign MATERIALS == fartons")
	_check(WorldSign.FEEL.has("fartons"), "WorldSign FEEL has fartons")
	var gids: Array = Goals.LEVEL_GOAL_IDS.get("poblenou", [])
	_check(gids.size() == 15 and gids.has("poblenou_kiosks") and gids.has("poblenou_tray"), "15 goals wired")
	_check(TonyHawk.CLOCK_TARGETS.has("poblenou") and TonyHawk.JAMON_POS.has("poblenou"), "TonyHawk wired")

	var m := await _load_walk(game)
	_check(m != null and is_instance_valid(m), "main loaded for poblenou")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on poblenou: %s" % [issues])

	var solids: Array = Poblenou.solids(m)
	var solid_map: Dictionary = {}
	for pair in LevelBuild.level_solid_rects(m):
		solid_map[String(pair[0])] = pair[1]
	for si in range(solids.size()):
		var sk := "poblenou_solid_%d" % si
		_check(solid_map.has(sk) and solid_map[sk] == solids[si], "level_solid_rects matches %s" % sk)

	_check(Poblenou.surface(m, Vector2(640.0, -400.0)) == Surfaces.S.PAVEMENT, "Rambla handles as PAVEMENT")
	_check(Poblenou.surface(m, Vector2(640.0, -3200.0)) == Surfaces.S.PAVEMENT, "Plaça de Prim handles as PAVEMENT")
	_check(Poblenou.surface(m, Vector2(640.0, -5200.0)) == Surfaces.S.PAVEMENT, "Plaça del Poblenou paved freedom")
	_check(Poblenou.tree_kind(m, Poblenou.PLANE_TREES[0]) == m.TREE_PLANE, "plane tree kind")
	_check(Poblenou.tree_kind(m, Poblenou.PALM_TREES[0]) == m.TREE_PALM, "palm tree kind")
	_check(Poblenou.is_lamp(m, Poblenou.STREET_LAMPS[0]), "lamp detected")
	_check(Poblenou.night_lights(m).size() >= Poblenou.STREET_LAMPS.size() + Poblenou.KIOSKS.size(), "night lights")
	_check(not Poblenou.night_fronts(m).is_empty(), "night fronts non-empty")

	# Live event: telegraph >= 0.8s, clean dodge & farton snatch
	m.dog.global_position = Poblenou.WAITER_SPOTS[0] + Vector2(60.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = Poblenou.WAITER_SPOTS[0] + Vector2(90.0, 40.0)
	m.poblenou_tray = {"state": "idle", "idx": 0, "t": 0.02, "waiter": Poblenou.WAITER_SPOTS[0], "target": Vector2.ZERO, "farton": Vector2.ZERO, "farton_active": false, "hit": false, "said": false, "arm_next": 0.0}
	Poblenou.tick(m, 0.05)
	_check(String(m.poblenou_tray.get("state", "")) == "warn", "tray enters warn")
	_check(float(m.poblenou_tray.get("t", 0.0)) >= 0.8, "tray telegraph >= 0.8s")
	_check(Poblenou.idle_status(m).length() > 0, "idle_status active during warn")
	m.dog.global_position = Vector2(640.0, -400.0)
	m.human.global_position = Vector2(640.0, -340.0)
	Poblenou.tick(m, 1.1)
	_check(String(m.poblenou_tray.get("state", "")) == "spill" and m.poblenou_trays_dodged >= 1, "clean tray dodge")
	var pre_bones: int = m.bones
	m.dog.global_position = Vector2(m.poblenou_tray["farton"])
	Poblenou.tick(m, 0.05)
	_check(m.bones == pre_bones + 2 and not bool(m.poblenou_tray.get("farton_active", true)), "farton snatched")

	m.queue_free()
	await physics_frame
	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_poblenou: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_poblenou: %d FAILURES" % failures.size())
		quit(1)
