extends SceneTree

# Regression test for Santa Coloma (santacoloma).
# Verifies campaign placement, walkability, solids-match-drawn, telegraphed
# Capicua domino slam, clock bark, barber dare-giver, dominoes sign, and goals.

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
	game.hour = "day"
	game.level_id = "santacoloma"
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
	var SantaColoma = load("res://systems/santacoloma.gd")
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

	_check(game.LEVELS.has("santacoloma"), "santacoloma present in Game.LEVELS")
	var idx: int = game.CAROUSEL.find("santacoloma")
	_check(idx == 47 and game.CAROUSEL[46] == "ronda" and game.CAROUSEL[48] == "partit",
		"CAROUSEL places santacoloma at index 47 between ronda and partit (got %d)" % idx)
	_check(int(game.STAR_GATE.get("santacoloma", -1)) == 47, "STAR_GATE santacoloma == 47")
	_check(String(game.CHASE_GATE.get("santacoloma", "")) == "atraccions", "CHASE_GATE santacoloma == atraccions")
	_check(game.CAMPAIGN_SKY.get("santacoloma", []) == ["clear", "day"], "CAMPAIGN_SKY == [clear, day]")
	_check(String(Challenger.WHO.get("santacoloma", "")) == "barber", "Challenger WHO == barber")
	_check(Music.STYLES.has("santacoloma") and Music.DARES.has("barber"), "Music has santacoloma & barber")
	_check(String(WorldSign.MATERIALS.get("santacoloma", "")) == "dominoes", "WorldSign MATERIALS == dominoes")
	_check(WorldSign.FEEL.has("dominoes"), "WorldSign FEEL has dominoes")
	var gids: Array = Goals.LEVEL_GOAL_IDS.get("santacoloma", [])
	_check(gids.size() == 15 and gids.has("santacoloma_spices") and gids.has("santacoloma_clock"), "15 goals wired")
	_check(TonyHawk.CLOCK_TARGETS.has("santacoloma") and TonyHawk.JAMON_POS.has("santacoloma"), "TonyHawk wired")

	var m := await _load_walk(game)
	_check(m != null and is_instance_valid(m), "main loaded for santacoloma")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on santacoloma: %s" % [issues])

	var solids: Array = SantaColoma.solids(m)
	var solid_map: Dictionary = {}
	for pair in LevelBuild.level_solid_rects(m):
		solid_map[String(pair[0])] = pair[1]
	for si in range(solids.size()):
		var sk := "santacoloma_solid_%d" % si
		_check(solid_map.has(sk) and solid_map[sk] == solids[si], "level_solid_rects matches %s" % sk)

	_check(SantaColoma.surface(m, Vector2(640.0, -300.0)) == Surfaces.S.PAVEMENT, "hillside PAVEMENT")
	_check(SantaColoma.surface(m, Vector2(640.0, -3300.0)) == Surfaces.S.PAVEMENT, "Plaça del Rellotge PAVEMENT")
	_check(SantaColoma.surface(m, Vector2(640.0, -5200.0)) == -1, "freedom delegates to Mirador GRASS")
	_check(SantaColoma.night_lights(m).size() >= SantaColoma.LAMPS.size() + SantaColoma.SPICE_STALLS.size(), "night lights")

	# Live event + clock bark
	m.dog.global_position = SantaColoma.DOMINO_SPOTS[0] + Vector2(60.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = SantaColoma.DOMINO_SPOTS[0] + Vector2(90.0, 40.0)
	m.santacoloma_domino = {"state": "idle", "idx": 0, "t": 0.02, "spot": SantaColoma.DOMINO_SPOTS[0], "target": Vector2.ZERO, "hit": false}
	SantaColoma.tick(m, 0.05)
	_check(String(m.santacoloma_domino.get("state", "")) == "warn", "domino enters warn")
	_check(float(m.santacoloma_domino.get("t", 0.0)) >= 0.8, "domino telegraph >= 0.8s")
	_check(SantaColoma.idle_status(m).length() > 0, "idle_status active during warn")
	m.dog.global_position = Vector2(640.0, -400.0)
	m.human.global_position = Vector2(640.0, -340.0)
	SantaColoma.tick(m, 1.1)
	_check(String(m.santacoloma_domino.get("state", "")) == "slam" and m.santacoloma_slams_dodged >= 1, "clean domino dodge")
	_check(SantaColoma.on_bark(m, SantaColoma.CLOCK_PLINTH.get_center() + Vector2(45.0, 0.0)) and m.santacoloma_clock_barked, "clock bark")

	m.queue_free()
	await physics_frame
	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_santacoloma: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_santacoloma: %d FAILURES" % failures.size())
		quit(1)
