extends SceneTree

# Regression test for Walk 43 (Camí de Ronda).
# Verifies campaign placement, walkability, solids-match-drawn, cliff edge
# collision for both walkers and the leash rope, telegraphed tramuntana gust,
# planted-dog shielding, snorkeler dare-giver, fishing-float sign, and goals.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		printerr("FAIL: ", msg)


func _initialize() -> void:
	call_deferred("_run")


func _load_ronda(game: Node) -> Node2D:
	game.weather = "wind"
	game.hour = "day"
	game.level_id = "ronda"
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
	var Ronda = load("res://systems/ronda.gd")
	var LevelBuild = load("res://world/level_build.gd")
	var LevelCheck = load("res://world/level_check.gd")
	var EdgePath = load("res://world/edge_path.gd")
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
	_check(game.LEVELS.has("ronda"), "ronda present in Game.LEVELS")
	var site_idx: int = game.CAROUSEL.find("site")
	_check(site_idx >= 0 and site_idx + 1 < game.CAROUSEL.size() and game.CAROUSEL[site_idx + 1] == "ronda",
		"CAROUSEL places ronda right after site")
	_check(int(game.STAR_GATE.get("ronda", -1)) == 47, "STAR_GATE ronda == 47")
	_check(String(game.CHASE_GATE.get("ronda", "")) == String(game.CHASE_GATE.get("site", "")),
		"CHASE_GATE ronda matches site")
	_check(game.CAMPAIGN_SKY.get("ronda", []) == ["wind", "day"], "CAMPAIGN_SKY ronda == [wind, day]")
	_check(game.WALKS_SINCE_GATES.has("ronda"), "WALKS_SINCE_GATES includes ronda")
	_check(String(game.LEVEL_NAMES.get("ronda", "")) == "Camí de Ronda", "LEVEL_NAMES ronda")
	_check(String(game.LEVEL_SUBTITLES.get("ronda", "")) == "The cliff path above the coves", "LEVEL_SUBTITLES ronda")
	_check(String(game.LEVEL_SUBTITLES_CA.get("ronda", "")).length() > 0, "LEVEL_SUBTITLES_CA ronda")
	_check(String(game.LEVEL_SUBTITLES_ES.get("ronda", "")).length() > 0, "LEVEL_SUBTITLES_ES ronda")

	# Dare-giver, music, sign, goals
	_check(String(Challenger.WHO.get("ronda", "")) == "snorkeler", "Challenger WHO is snorkeler")
	_check(Challenger.FOOTPRINT.has("snorkeler"), "Challenger FOOTPRINT has snorkeler")
	_check(Challenger.LINES.has("snorkeler") and Challenger.LINES["snorkeler"].size() >= 5,
		"Challenger LINES has 5 lines for snorkeler")
	_check(Challenger.NAMES.has("snorkeler"), "Challenger NAMES has snorkeler")
	_check(Music.STYLES.has("ronda"), "Music STYLES has ronda")
	_check(Music.DARES.has("snorkeler"), "Music DARES has snorkeler")
	_check(String(WorldSign.MATERIALS.get("ronda", "")) == "floats", "WorldSign MATERIALS ronda == floats")
	_check(Goals.LEVEL_GOAL_IDS.has("ronda"), "Goals has ronda")

	# 2. Load level & check walkability + solids + surfaces
	var m := await _load_ronda(game)
	_check(m != null and is_instance_valid(m), "main loaded for ronda")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on ronda: %s" % [issues])

	# Surfaces
	_check(Ronda.surface(m, Vector2(560.0, 0.0)) == Surfaces.S.PAVEMENT, "village cobbles handle as PAVEMENT")
	_check(Ronda.surface(m, Vector2(685.0, -1450.0)) == Surfaces.S.PAVEMENT, "headland stone steps handle as PAVEMENT")
	_check(Ronda.surface(m, Vector2(640.0, -1250.0)) == Surfaces.S.SAND, "cliff dirt path handles as SAND")
	_check(Ronda.surface(m, Vector2(640.0, -1250.0)) != Surfaces.S.WATER, "cliff path not WATER")
	_check(Ronda.surface(m, Vector2(575.0, -4000.0)) == Surfaces.S.SAND, "pine trail center handles as SAND")
	_check(Ronda.surface(m, Vector2(400.0, -4000.0)) == Surfaces.S.GRASS, "pine needle flank handles as GRASS")
	_check(Ronda.surface(m, Vector2(1050.0, -350.0)) == Surfaces.S.WATER, "east cove sea handles as WATER")
	_check(Ronda.surface(m, Vector2(640.0, float(m.GATE_Y) - 300.0)) == Surfaces.S.SAND, "finish cove shingle handles as SAND")
	_check(Ronda.surface(m, Vector2(1150.0, float(m.GATE_Y) - 300.0)) == Surfaces.S.WATER, "finish cove east sea handles as WATER")

	# Poles and lamps
	var expected_deco: int = Ronda._pine_poles().size() + Ronda.VILLAGE_LAMPS.size() + Ronda._rail_posts().size() + Ronda._boulder_poles().size()
	_check(m.deco_pole_count == expected_deco and m.deco_pole_count <= m.poles.size(),
		"deco_pole_count matches corridor poles (%d, expected %d, total %d)" % [m.deco_pole_count, expected_deco, m.poles.size()])
	for lp: Vector2 in Ronda.VILLAGE_LAMPS:
		_check(Ronda.is_lamp(m, lp), "village lamp %s returns is_lamp == true" % [lp])
	_check(not Ronda.is_lamp(m, Vector2(500.0, -1450.0)), "non-lamp pole returns is_lamp == false")

	# Solids match drawn
	var drawn_solids: Array[Rect2] = Ronda.solids(m)
	var built_solids: Array = LevelBuild.level_solid_rects(m)
	var ronda_solid_count := 0
	for entry in built_solids:
		if String(entry[0]).begins_with("ronda_solid_"):
			ronda_solid_count += 1
	_check(ronda_solid_count == drawn_solids.size(),
		"level_solid_rects matches Ronda.solids size (%d vs %d)" % [ronda_solid_count, drawn_solids.size()])
	_check(drawn_solids.size() > 0, "Ronda.solids is non-empty")

	# 3. Cliff edge holds both walkers AND the leash rope
	var edge_1450: Vector2 = EdgePath.edges(Ronda.edge_nodes(m), -1450.0, Ronda.CX, Ronda.HALF)
	var space := m.get_world_2d().direct_space_state
	var rq := PhysicsRayQueryParameters2D.create(
		Vector2(edge_1450.y - 20.0, -1450.0),
		Vector2(edge_1450.y + 40.0, -1450.0)
	)
	rq.collide_with_bodies = true
	rq.collide_with_areas = false
	var cliff_hit := space.intersect_ray(rq)
	_check(not cliff_hit.is_empty(), "cliff east wall has solid physics barrier at east edge y=-1450")

	var rope_wall_hits := 0
	for rr: Rect2 in m.leash.rope_rects:
		if rr.has_point(Vector2(edge_1450.y + 40.0, -1450.0)):
			rope_wall_hits += 1
	_check(rope_wall_hits > 0, "leash rope_rects blocks east cliff edge")

	# Leash rope solver must expel a point pushed past the cliff edge
	m.human.global_position = Vector2(edge_1450.y - 40.0, -1440.0)
	m.dog.global_position = Vector2(edge_1450.y - 40.0, -1460.0)
	var test_mid: int = m.leash.pts.size() / 2
	m.leash.pts[test_mid] = Vector2(edge_1450.y + 80.0, -1450.0)
	m.leash.prev[test_mid] = m.leash.pts[test_mid]
	m.leash.tick(0.016)
	_check(m.leash.pts[test_mid].x <= edge_1450.y + 12.0,
		"rope solver expels seaward point back behind cliff edge (x=%.1f vs edge=%.1f)" % [m.leash.pts[test_mid].x, edge_1450.y])

	# 4. Tramuntana gust: telegraphed >= 1.0 s before pushing, then planted landward dog shields human
	_check(Ronda.GUST_WARN >= 1.0, "GUST_WARN >= 1.0 s")
	m.phase = "walk"
	m.frozen = false
	m.auto_walk = false
	m.human.global_position = Vector2(620.0, -1500.0)
	m.dog.global_position = Vector2(560.0, -1500.0)
	m.ronda_gust = {"state": "idle", "t": 0.05, "saved": false, "hit": false, "bow": 0.0}
	m.ronda_gust_held = 0

	# Step across idle -> telegraph
	Ronda.tick(m, 0.08)
	_check(String(m.ronda_gust.get("state", "")) == "telegraph", "gust enters telegraph state")
	_check(float(m.ronda_gust.get("t", 0.0)) >= 1.0, "gust telegraph gives >= 1.0 s warning")

	# Halfway through telegraph: still telegraphing (not blowing yet), human not shoved
	var vel_before: Vector2 = m.human.velocity
	Ronda.tick(m, 0.5)
	_check(String(m.ronda_gust.get("state", "")) == "telegraph", "gust remains in telegraph during warning")
	_check(float(m.ronda_gust.get("bow", 0.0)) > 0.0, "pines bow during telegraph")
	_check(m.human.velocity.x <= vel_before.x + 1.0, "human not shoved during telegraph")

	# Now plant dog on landward side (dog.x < human.x) and finish telegraph -> blowing
	m.dog.planted = true
	m.dog.global_position = Vector2(540.0, -1500.0)
	m.human.global_position = Vector2(620.0, -1500.0)
	m.human.velocity = Vector2.ZERO
	Ronda.tick(m, 0.85)  # triggers transition into blowing
	Ronda.tick(m, 0.35)  # active gust while dog is planted landward
	_check(String(m.ronda_gust.get("state", "")) == "blowing", "gust transitions to blowing after telegraph")
	_check(m.ronda_gust_held >= 1, "planted landward dog held the gust and scored save")
	_check(m.human.velocity.x <= 25.0, "human seaward velocity anchored by planted landward dog")

	# Verify unplanted dog fails to anchor and gust shoves human seaward
	m.ronda_gust = {"state": "blowing", "t": Ronda.GUST_BLOW * 0.5, "saved": false, "hit": false, "bow": 1.0}
	m.dog.planted = false
	m.human.velocity = Vector2.ZERO
	Ronda.tick(m, 0.1)
	_check(m.human.velocity.x > 10.0, "unshielded gust shoves human seaward")

	m.queue_free()
	await physics_frame

	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_ronda: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_ronda: %d FAILURES" % failures.size())
		quit(1)
