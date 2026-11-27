extends SceneTree

# Regression test for Les Tres Xemeneies (xemeneies).
# Verifies campaign placement, walkability, solids-match-drawn, telegraphed
# spray-can event, chimney bark echo, muralist dare-giver, caps sign, and goals.

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
	game.level_id = "xemeneies"
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
	var Xemeneies = load("res://systems/xemeneies.gd")
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

	_check(game.LEVELS.has("xemeneies"), "xemeneies present in Game.LEVELS")
	var idx: int = game.CAROUSEL.find("xemeneies")
	_check(idx == 25 and game.CAROUSEL[24] == "metro" and game.CAROUSEL[26] == "carmel",
		"CAROUSEL places xemeneies at index 25 between metro and carmel (got %d)" % idx)
	_check(int(game.STAR_GATE.get("xemeneies", -1)) == 31, "STAR_GATE xemeneies == 31")
	_check(String(game.CHASE_GATE.get("xemeneies", "")) == "boars", "CHASE_GATE xemeneies == boars")
	_check(game.CAMPAIGN_SKY.get("xemeneies", []) == ["clear", "dusk"], "CAMPAIGN_SKY == [clear, dusk]")
	_check(String(Challenger.WHO.get("xemeneies", "")) == "muralist", "Challenger WHO == muralist")
	_check(Music.STYLES.has("xemeneies") and Music.DARES.has("muralist"), "Music has xemeneies & muralist")
	_check(String(WorldSign.MATERIALS.get("xemeneies", "")) == "caps", "WorldSign MATERIALS == caps")
	_check(WorldSign.FEEL.has("caps"), "WorldSign FEEL has caps")
	var gids: Array = Goals.LEVEL_GOAL_IDS.get("xemeneies", [])
	_check(gids.size() == 15 and gids.has("xemeneies_murals") and gids.has("xemeneies_echo"), "15 goals wired")
	_check(TonyHawk.CLOCK_TARGETS.has("xemeneies") and TonyHawk.JAMON_POS.has("xemeneies"), "TonyHawk wired")

	var m := await _load_walk(game)
	_check(m != null and is_instance_valid(m), "main loaded for xemeneies")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on xemeneies: %s" % [issues])

	var solids: Array = Xemeneies.solids(m)
	var solid_map: Dictionary = {}
	for pair in LevelBuild.level_solid_rects(m):
		solid_map[String(pair[0])] = pair[1]
	for si in range(solids.size()):
		var sk := "xemeneies_solid_%d" % si
		_check(solid_map.has(sk) and solid_map[sk] == solids[si], "level_solid_rects matches %s" % sk)

	_check(m.rails.size() == Xemeneies.SKATE_LEDGES.size(), "grindable skate rails built")
	_check(Xemeneies.surface(m, Vector2(640.0, -300.0)) == Surfaces.S.PAVEMENT, "approach PAVEMENT")
	_check(Xemeneies.surface(m, Vector2(640.0, -3300.0)) == Surfaces.S.PAVEMENT, "chimneys plaza PAVEMENT")
	_check(Xemeneies.surface(m, Vector2(640.0, -5200.0)) == -1, "freedom delegates to yard GRASS")
	_check(Xemeneies.night_lights(m).size() >= Xemeneies.LAMPS.size() + Xemeneies.CHIMNEY_RECTS.size(), "night lights")

	# Live event + bark echo
	m.dog.global_position = Xemeneies.ARTIST_SPOTS[0] + Vector2(60.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = Xemeneies.ARTIST_SPOTS[0] + Vector2(100.0, 40.0)
	m.xemeneies_spray = {"state": "idle", "idx": 0, "t": 0.02, "artist": Xemeneies.ARTIST_SPOTS[0], "target": Vector2.ZERO, "hit": false}
	Xemeneies.tick(m, 0.05)
	_check(String(m.xemeneies_spray.get("state", "")) == "warn", "spray enters warn")
	_check(float(m.xemeneies_spray.get("t", 0.0)) >= 0.8, "spray telegraph >= 0.8s")
	_check(Xemeneies.idle_status(m).length() > 0, "idle_status active during warn")
	m.dog.global_position = Vector2(640.0, -400.0)
	m.human.global_position = Vector2(640.0, -340.0)
	Xemeneies.tick(m, 1.1)
	_check(String(m.xemeneies_spray.get("state", "")) == "spray" and m.xemeneies_sprays_dodged >= 1, "clean spray dodge")
	_check(Xemeneies.on_bark(m, Xemeneies.CHIMNEY_RECTS[0].get_center() + Vector2(40.0, 0.0)) and m.xemeneies_echo_barked, "chimney echo bark")

	m.queue_free()
	await physics_frame
	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_xemeneies: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_xemeneies: %d FAILURES" % failures.size())
		quit(1)
