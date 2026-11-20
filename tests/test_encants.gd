extends SceneTree

# Regression test for Els Encants (Mercat dels Encants at Glòries).
# Verifies campaign placement, walkability, solids-match-drawn, dry canopy /
# wet street surfaces, telegraphed stall spill, planted-dog hold, haggler
# dare-giver, button sign, and goals.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		printerr("FAIL: ", msg)


func _initialize() -> void:
	call_deferred("_run")


func _load_encants(game: Node) -> Node2D:
	game.weather = "rain"
	game.hour = "day"
	game.level_id = "encants"
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
	var Encants = load("res://systems/encants.gd")
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

	# 1. Placement in Game
	_check(game.LEVELS.has("encants"), "encants present in Game.LEVELS")
	var mont_idx: int = game.CAROUSEL.find("montserrat")
	_check(mont_idx >= 0 and mont_idx + 1 < game.CAROUSEL.size() and game.CAROUSEL[mont_idx + 1] == "encants",
		"CAROUSEL places encants right after montserrat")
	_check(int(game.STAR_GATE.get("encants", -1)) == 50, "STAR_GATE encants == 50")
	_check(String(game.CHASE_GATE.get("encants", "")) == String(game.CHASE_GATE.get("scrap", "")),
		"CHASE_GATE encants matches scrap")
	_check(game.CAMPAIGN_SKY.get("encants", []) == ["rain", "day"], "CAMPAIGN_SKY encants == [rain, day]")
	_check(game.WALKS_SINCE_GATES.has("encants"), "WALKS_SINCE_GATES includes encants")
	_check(String(game.LEVEL_NAMES.get("encants", "")) == "Els Encants", "LEVEL_NAMES encants")
	_check(String(game.LEVEL_SUBTITLES.get("encants", "")).length() > 0, "LEVEL_SUBTITLES encants")
	_check(String(game.LEVEL_SUBTITLES_CA.get("encants", "")).length() > 0, "LEVEL_SUBTITLES_CA encants")
	_check(String(game.LEVEL_SUBTITLES_ES.get("encants", "")).length() > 0, "LEVEL_SUBTITLES_ES encants")

	# Dare-giver, music, sign, goals
	_check(String(Challenger.WHO.get("encants", "")) == "haggler", "Challenger WHO is haggler")
	_check(Challenger.FOOTPRINT.has("haggler"), "Challenger FOOTPRINT has haggler")
	_check(Challenger.LINES.has("haggler") and Challenger.LINES["haggler"].size() >= 5,
		"Challenger LINES has 5 lines for haggler")
	_check(Challenger.NAMES.has("haggler"), "Challenger NAMES has haggler")
	_check(Music.STYLES.has("encants"), "Music STYLES has encants")
	_check(Music.DARES.has("haggler"), "Music DARES has haggler")
	_check(String(WorldSign.MATERIALS.get("encants", "")) == "buttons", "WorldSign MATERIALS encants == buttons")
	_check(Goals.LEVEL_GOAL_IDS.has("encants"), "Goals has encants")
	_check(Goals.LEVEL_GOAL_IDS["encants"].has("carry"), "Goals encants includes carry")
	_check(Goals.LEVEL_GOAL_IDS["encants"].has("encants_spill"), "Goals encants includes encants_spill")

	# 2. Load level & check walkability + solids + surfaces
	var m := await _load_encants(game)
	_check(m != null and is_instance_valid(m), "main loaded for encants")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on encants: %s" % [issues])

	# Surfaces: pavement throughout the corridor (dry look under canopy, wet outside)
	_check(Encants.surface(m, Vector2(640.0, -200.0)) == Surfaces.S.PAVEMENT, "street start handles as PAVEMENT")
	_check(Encants.surface(m, Vector2(640.0, -2000.0)) == Surfaces.S.PAVEMENT, "canopy lane handles as PAVEMENT")
	_check(Encants.surface(m, Vector2(640.0, -2000.0)) != Surfaces.S.WATER, "canopy lane not WATER")
	_check(Encants._under_canopy(-2000.0), "y=-2000 is under the canopy")
	_check(not Encants._under_canopy(-200.0), "y=-200 is outside the canopy")
	_check(Encants.surface(m, Vector2(640.0, float(m.GATE_Y) - 200.0)) == Surfaces.S.PAVEMENT,
		"finish square handles as PAVEMENT")

	# Poles: stilts + street lamps
	var expected_deco: int = Encants.STILTS.size() + Encants.STREET_LAMPS.size()
	_check(m.deco_pole_count == expected_deco and m.deco_pole_count <= m.poles.size(),
		"deco_pole_count matches stilts+lamps (%d, expected %d, total %d)" % [m.deco_pole_count, expected_deco, m.poles.size()])
	for lp: Vector2 in Encants.STREET_LAMPS:
		_check(Encants.is_lamp(m, lp), "street lamp %s returns is_lamp == true" % [lp])
	_check(not Encants.is_lamp(m, Encants.STILTS[0]), "stilt returns is_lamp == false")

	# Solids match drawn
	var drawn_solids: Array[Rect2] = Encants.solids(m)
	var built_solids: Array = LevelBuild.level_solid_rects(m)
	var encants_solid_count := 0
	for entry in built_solids:
		if String(entry[0]).begins_with("encants_solid_"):
			encants_solid_count += 1
	_check(encants_solid_count == drawn_solids.size(),
		"level_solid_rects matches Encants.solids size (%d vs %d)" % [encants_solid_count, drawn_solids.size()])
	_check(drawn_solids.size() > 0, "Encants.solids is non-empty")

	# Carry sock wired
	_check(m.carry_item == "the sock", "carry item is the sock")
	_check(m.carry_pickup.distance_to(Encants.SOCK_PICKUP) < 1.0, "carry pickup at sock stall")

	# FREEDOM_PROPS authored
	_check(LevelBuild.FREEDOM_PROPS.has("encants"), "FREEDOM_PROPS has encants")

	# 3. Stall spill: telegraphed >= 1.0 s before sliding, then planted dog holds
	_check(Encants.SPILL_WARN >= 1.0, "SPILL_WARN >= 1.0 s")
	m.phase = "walk"
	m.frozen = false
	m.auto_walk = false
	m.human.global_position = Vector2(640.0, -2000.0)
	m.dog.global_position = Vector2(600.0, -2000.0)
	m.encants_spill = {"state": "idle", "t": 0.05, "saved": false, "hit": false, "wobble": 0.0, "slide": 0.0}
	m.encants_spill_held = 0

	Encants.tick(m, 0.08)
	_check(String(m.encants_spill.get("state", "")) == "telegraph", "spill enters telegraph state")
	_check(float(m.encants_spill.get("t", 0.0)) >= 1.0, "spill telegraph gives >= 1.0 s warning")

	var vel_before: Vector2 = m.human.velocity
	Encants.tick(m, 0.5)
	_check(String(m.encants_spill.get("state", "")) == "telegraph", "spill remains in telegraph during warning")
	_check(float(m.encants_spill.get("wobble", 0.0)) > 0.0, "stack wobbles during telegraph")
	_check(m.human.velocity.length() <= vel_before.length() + 1.0, "human not hit during telegraph")

	# Plant dog near spill and finish telegraph -> spilling
	m.dog.planted = true
	m.dog.global_position = Encants.SPILL_RECT.get_center() + Vector2(-20.0, 0.0)
	m.human.global_position = Vector2(620.0, -2080.0)
	m.human.velocity = Vector2.ZERO
	Encants.tick(m, 0.7)
	Encants.tick(m, 0.4)
	_check(String(m.encants_spill.get("state", "")) == "spilling", "spill transitions to spilling after telegraph")
	_check(m.encants_spill_held >= 1, "planted dog held the spill and scored save")

	# Unplanted dog: human walks into spill and takes the phone hit
	m.encants_spill = {"state": "spilling", "t": Encants.SPILL_SLIDE * 0.5, "saved": false, "hit": false, "wobble": 1.0, "slide": 0.5}
	m.dog.planted = false
	m.human.global_position = Encants.SPILL_RECT.get_center()
	m.human.velocity = Vector2.ZERO
	var pat_before: float = m.human.patience
	Encants.tick(m, 0.1)
	_check(bool(m.encants_spill.get("hit", false)), "unshielded human walks into the spill")
	_check(m.human.patience < pat_before, "spill hit costs patience")

	m.queue_free()
	await physics_frame

	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_encants: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_encants: %d FAILURES" % failures.size())
		quit(1)
