extends SceneTree

# Regression test for Vic (inland market town in fog).
# Verifies campaign placement, walkability, solids-match-drawn, telegraphed
# loose-fuet event, fog find-your-human, farmer dare-giver, cheese-wheel sign,
# and goals.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		printerr("FAIL: ", msg)


func _initialize() -> void:
	call_deferred("_run")


func _load_vic(game: Node) -> Node2D:
	game.weather = "fog"
	game.hour = "day"
	game.level_id = "vic"
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
	var Vic = load("res://systems/vic.gd")
	var LevelBuild = load("res://world/level_build.gd")
	var LevelCheck = load("res://world/level_check.gd")
	var Surfaces = load("res://world/surfaces.gd")
	var WorldSign = load("res://world/world_sign.gd")
	var Challenger = load("res://entities/challenger.gd")
	var Music = load("res://audio/music.gd")
	var Goals = load("res://systems/goals.gd")
	var Outdoors = load("res://systems/outdoors.gd")

	var game := root.get_node("/root/Game")
	var keep_lvl: String = game.level_id
	var keep_w: String = game.weather
	var keep_h: String = game.hour

	# 1. Placement in Game (present, not necessarily last)
	_check(game.LEVELS.has("vic"), "vic present in Game.LEVELS")
	var enc_idx: int = game.CAROUSEL.find("encants")
	var vic_idx: int = game.CAROUSEL.find("vic")
	_check(enc_idx >= 0 and vic_idx > enc_idx and vic_idx - enc_idx <= 2,
		"CAROUSEL places vic just after encants")
	_check(int(game.STAR_GATE.get("vic", -1)) == 50, "STAR_GATE vic == 50")
	_check(String(game.CHASE_GATE.get("vic", "")) == String(game.CHASE_GATE.get("scrap", "")),
		"CHASE_GATE vic matches scrap")
	_check(game.CAMPAIGN_SKY.get("vic", []) == ["fog", "morning"], "CAMPAIGN_SKY vic == [fog, morning]")
	_check(game.WALKS_SINCE_GATES.has("vic"), "WALKS_SINCE_GATES includes vic")
	_check(String(game.LEVEL_NAMES.get("vic", "")) == "Vic", "LEVEL_NAMES vic")
	_check(String(game.LEVEL_SUBTITLES.get("vic", "")) == "Fog, arcades and hanging fuet", "LEVEL_SUBTITLES vic")
	_check(String(game.LEVEL_SUBTITLES_CA.get("vic", "")).length() > 0, "LEVEL_SUBTITLES_CA vic")
	_check(String(game.LEVEL_SUBTITLES_ES.get("vic", "")).length() > 0, "LEVEL_SUBTITLES_ES vic")

	# Dare-giver, music, sign, goals, outdoors
	_check(String(Challenger.WHO.get("vic", "")) == "farmer", "Challenger WHO is farmer")
	_check(Challenger.FOOTPRINT.has("farmer"), "Challenger FOOTPRINT has farmer")
	_check(Challenger.LINES.has("farmer") and Challenger.LINES["farmer"].size() >= 5,
		"Challenger LINES has 5 lines for farmer")
	_check(Challenger.NAMES.has("farmer"), "Challenger NAMES has farmer")
	_check(Music.STYLES.has("vic"), "Music STYLES has vic")
	_check(Music.DARES.has("farmer"), "Music DARES has farmer")
	_check(String(WorldSign.MATERIALS.get("vic", "")) == "cheeses", "WorldSign MATERIALS vic == cheeses")
	_check(WorldSign.FEEL.has("cheeses"), "WorldSign FEEL has cheeses")
	_check(Goals.LEVEL_GOAL_IDS.has("vic"), "Goals has vic")
	_check(Outdoors.shops_open("clear", "day"), "market/shops open by day")
	_check(Outdoors.sunbathers("clear", "day"), "sunbathers out on a clear day")
	# fair() gates on fog_amount; with fog sky strength, sunbathers stay in
	var keep_sky: String = game.sky
	game.sky = "fog"
	_check(not Outdoors.sunbathers("clear", "day"), "sunbathers stay in under fog sky")
	_check(not Outdoors.picnics("clear", "day"), "picnics stay in under fog sky")
	game.sky = keep_sky

	# 2. Load level & check walkability + solids + surfaces
	var m := await _load_vic(game)
	_check(m != null and is_instance_valid(m), "main loaded for vic")
	var issues: Array = LevelCheck.check(m)
	_check(issues.is_empty(), "LevelCheck issues on vic: %s" % [issues])

	# Surfaces: stone street, plaza paving, bridge stone, river water, meadow grass
	_check(Vic.surface(m, Vector2(640.0, 0.0)) == Surfaces.S.PAVEMENT, "old street handles as PAVEMENT")
	_check(Vic.surface(m, Vector2(640.0, -1400.0)) == Surfaces.S.PAVEMENT, "Mercadal handles as PAVEMENT")
	_check(Vic.surface(m, Vector2(640.0, -3700.0)) == Surfaces.S.PAVEMENT, "bridge deck handles as PAVEMENT")
	_check(Vic.surface(m, Vector2(300.0, -3700.0)) == Surfaces.S.WATER, "river beside bridge handles as WATER")
	_check(Vic.surface(m, Vector2(640.0, -4500.0)) == Surfaces.S.GRASS, "meadow approach handles as GRASS")
	_check(Vic.surface(m, Vector2(300.0, float(m.GATE_Y) - 200.0)) == Surfaces.S.GRASS,
		"finish meadow handles as GRASS")
	_check(Vic.surface(m, Vector2(640.0, float(m.GATE_Y) - 160.0)) == Surfaces.S.WATER,
		"meadow river tongue handles as WATER")

	# Poles and lamps
	_check(m.deco_pole_count > 0 and m.deco_pole_count <= m.poles.size(),
		"deco_pole_count set (%d of %d)" % [m.deco_pole_count, m.poles.size()])
	for lp: Vector2 in Vic.STREET_LAMPS:
		_check(Vic.is_lamp(m, lp), "street lamp %s returns is_lamp == true" % [lp])
	_check(not Vic.is_lamp(m, Vic.ARCADE_COLS[0]), "arcade column is not a lamp")
	_check(Vic.tree_kind(m, Vic.PLANE_TREES[0]) == m.TREE_PLANE, "plane tree_kind")

	# After dark every stall keeps its lantern, over the street's own lamps
	var lights: Array[Vector3] = Vic.night_lights(m)
	var street_lights: Array[Vector3] = m.street_night_lights()
	_check(lights.size() == street_lights.size() + Vic.STALLS.size(),
		"night_lights is the street's lamps plus one lantern a stall (%d)" % lights.size())
	for s: Vector2 in Vic.STALLS:
		var lit := false
		for l: Vector3 in lights:
			if Vector2(l.x, l.y).distance_to(s) < 40.0 and l.z < m.NIGHT_LAMP_R:
				lit = true
		_check(lit, "stall %s has its lantern after dark" % [s])

	# A ground band over the market's south end that stops short of its north
	# end still lays every stall in it (the overlap test once ran backwards)
	Vic._recs.clear()
	Vic._recs_key = []
	Vic.draw_cross_section(m, load("res://systems/shape_batch.gd").new(), 0.0, 0.0, 0.0, -1460.0, -900.0)
	for i in range(Vic.STALLS.size()):
		var sy: float = Vic.STALLS[i].y
		if sy > -1460.0 and sy < -900.0:
			_check(Vic._recs.has(["stall", i]), "stall %d at y %d is laid in a band short of the market's north end" % [i, sy])

	# Solids match drawn
	var drawn_solids: Array[Rect2] = Vic.solids(m)
	var built_solids: Array = LevelBuild.level_solid_rects(m)
	var vic_solid_count := 0
	for entry in built_solids:
		if String(entry[0]).begins_with("vic_solid_"):
			vic_solid_count += 1
	_check(vic_solid_count == drawn_solids.size(),
		"level_solid_rects matches Vic.solids size (%d vs %d)" % [vic_solid_count, drawn_solids.size()])
	_check(drawn_solids.size() > 0, "Vic.solids is non-empty")
	_check(LevelBuild.FREEDOM_PROPS.has("vic"), "FREEDOM_PROPS has vic")

	# 3. Loose fuet: telegraphed >= 0.8 s before it drops
	_check(Vic.SAUSAGE_WARN >= 0.8, "SAUSAGE_WARN >= 0.8 s")
	m.phase = "walk"
	m.frozen = false
	m.auto_walk = false
	m.dog.global_position = Vic.STALL_FUET + Vector2(40.0, 80.0)
	m.human.global_position = Vic.STALL_FUET + Vector2(60.0, 100.0)
	m.vic_sausage = {
		"state": "idle", "t": 0.05, "pos": Vic.STALL_FUET, "vel": Vector2.ZERO,
		"swing": 0.0, "carried": false, "eaten": false, "returned": false, "eat_t": 0.0, "said": false,
	}
	m.vic_sausage_returned = 0
	m.vic_sausage_eaten = 0

	Vic.tick(m, 0.08)
	_check(String(m.vic_sausage.get("state", "")) == "swing", "fuet enters swing (telegraph) state")
	_check(float(m.vic_sausage.get("t", 0.0)) >= 0.8, "fuet telegraph gives >= 0.8 s warning")
	_check(bool(m.vic_sausage.get("said", false)), "stallholder has spoken during telegraph")

	# Still swinging halfway; not rolling yet
	Vic.tick(m, 0.4)
	_check(String(m.vic_sausage.get("state", "")) == "swing", "fuet remains swinging during warning")

	# Finish telegraph -> roll
	Vic.tick(m, 0.8)
	_check(String(m.vic_sausage.get("state", "")) == "roll", "fuet drops into roll after telegraph")

	# Carry back: pickup near rolling sausage, then walk to stall
	m.vic_sausage["pos"] = m.dog.global_position
	m.vic_sausage["state"] = "roll"
	m.vic_sausage["t"] = 1.0
	m.vic_sausage["carried"] = false
	m.vic_sausage["eaten"] = false
	m.auto_walk = true
	Vic.tick(m, 0.05)
	_check(String(m.vic_sausage.get("state", "")) == "carry", "auto_walk picks up the fuet")
	m.dog.global_position = Vic.STALL_FUET
	Vic.tick(m, 0.05)
	_check(m.vic_sausage_returned >= 1, "carrying fuet to the stall scores a return")
	_check(bool(m.vic_sausage.get("returned", false)), "fuet marked returned")

	# Eat path: linger without pickup -> bleh penalty
	m.vic_sausage = {
		"state": "ground", "t": 0.0, "pos": m.dog.global_position, "vel": Vector2.ZERO,
		"swing": 0.0, "carried": false, "eaten": false, "returned": false, "eat_t": 0.0, "said": true,
	}
	m.vic_sausage_eaten = 0
	m.auto_walk = false
	var bones_before: int = m.bones
	Vic.tick(m, Vic.SAUSAGE_EAT_HOLD + 0.05)
	_check(m.vic_sausage_eaten >= 1, "lingering on the fuet eats it")
	_check(m.bones <= bones_before, "eating the fuet costs bones")

	# 4. Fog find-your-human
	m.vic_lost = false
	m.vic_found_human = 0
	m.dog.global_position = Vector2(500.0, -1400.0)
	m.human.global_position = Vector2(500.0, -1400.0 - Vic.LOST_R - 20.0)
	# campaign fog is active on this load
	_check(game.fog_amount() >= 0.5, "vic campaign fog is thick (fog_amount >= 0.5)")
	Vic.tick(m, 0.05)
	_check(bool(m.vic_lost), "far dog marks human lost in fog")
	m.human.global_position = m.dog.global_position + Vector2(20.0, 0.0)
	Vic.tick(m, 0.05)
	_check(m.vic_found_human >= 1, "reuniting scores find-your-human")

	m.queue_free()
	await physics_frame

	game.level_id = keep_lvl
	game.weather = keep_w
	game.hour = keep_h

	if failures.is_empty():
		print("test_vic: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_vic: %d FAILURES" % failures.size())
		for f: String in failures:
			printerr("  ", f)
		quit(1)
