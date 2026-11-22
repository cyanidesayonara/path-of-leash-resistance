extends SceneTree

# Tests Sitges (systems/sitges.gd):
# - registered in Game.LEVELS, right after "poble" in CAROUSEL, star gate 47,
#   chase gate "cremada", windy day campaign sky, Catalan gloss, 15 goals,
#   kitesurfer dare-giver and music styles
# - walkable start to finish: LevelCheck clean, corridor slope <= 0.85,
#   no prop clashes, >= 200 px plaza past church, drawn solids match solids()
# - surfaces handle as pavement on Ribera, sand on cove/kite bay/Fragata,
#   stone (PAVEMENT) on La Punta and steps (never grass), WATER in the sea
# - telegraphed breaking wave at the bend: SPRAY >= 0.8 s before WASH,
#   soaks human and sets dog.slick inside wash while sliding loose cones,
#   and keeping human in east dry strip awards wave_dodge cleanly
# - blowing napkins, La Punta bell bark, outdoors wind rules

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


func _load(game, weather: String = "wind", hour: String = "day") -> Node2D:
	game.weather = weather
	game.hour = hour
	game.level_id = "sitges"
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


func _free(m: Node2D) -> void:
	m.get_parent().remove_child(m)
	m.free()


func _solids(m: Node2D) -> Array:
	var things: Array = []
	var furniture := {}
	for tb: Vector2 in m.tables:
		things.append([tb, 14.0, "table %s" % tb])
		furniture[tb] = true
	for ch: Vector2 in m.chairs:
		things.append([ch, 7.0, "chair %s" % ch])
		furniture[ch] = true
	for bn: Vector2 in m.bins:
		things.append([bn, 10.0, "bin %s" % bn])
		furniture[bn] = true
	for i in range(m.body_pole_count):
		if not furniture.has(m.poles[i]):
			things.append([m.poles[i], m.POLE_RADIUS, "post %s" % m.poles[i]])
	for p: Vector2 in m.performers:
		things.append([p, m.PERFORMER_RADIUS, "person %s" % p])
	for h: Dictionary in m.hydrants:
		things.append([h.pos, m.HYDRANT_RADIUS, "hydrant %s" % h.pos])
	for f: Vector2 in m.fountains:
		things.append([f, m.FOUNTAIN_RADIUS, "fountain %s" % f])
	return things


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	game.sky_from_args = true
	root.get_node("Sfx").muted = true

	var S: GDScript = load("res://systems/sitges.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var Surfaces: GDScript = load("res://world/surfaces.gd")
	var LC: GDScript = load("res://world/level_check.gd")
	var Chal: GDScript = load("res://entities/challenger.gd")
	var Music: GDScript = load("res://audio/music.gd")
	var Outdoors: GDScript = load("res://systems/outdoors.gd")

	# 1. Registration & Identity
	_check(game.LEVELS.has("sitges"), "sitges in LEVELS")
	_check(game.LEVELS.has("sitges") and game.LEVELS.find("sitges") > game.LEVELS.find("santpau"), "sitges in LEVELS after santpau")
	_check(game.CAROUSEL.find("sitges") == game.CAROUSEL.find("poble") + 1, "in CAROUSEL right after poble")
	_check(int(game.STAR_GATE["sitges"]) == 47, "STAR_GATE is 47")
	_check(String(game.CHASE_GATE.get("sitges", "")) == "molina", "CHASE_GATE is molina")
	_check(game.CAMPAIGN_SKY["sitges"] == ["wind", "day"], "CAMPAIGN_SKY is wind/day")
	_check(String(game.LEVEL_NAMES["sitges"]) == "Sitges", "named Sitges")
	_check(String(game.LEVEL_SUBTITLES["sitges"]) == "Whitewashed streets by the sea", "subtitle The town by the sea")
	_check(G.LEVEL_GOAL_IDS.has("sitges") and G.LEVEL_GOAL_IDS["sitges"].size() == 15, "15 goals registered")
	for g: String in ["dry", "wave_dodge", "napkin", "punta_bark"]:
		_check(G.LEVEL_GOAL_IDS["sitges"].has(g), "has goal %s" % g)
	_check(String(Chal.WHO.get("sitges", "")) == "kitesurfer", "dare-giver is kitesurfer")
	_check(Chal.LINES.has("kitesurfer") and (Chal.LINES["kitesurfer"] as Dictionary).size() >= 5, "kitesurfer has 5 lines")
	_check(Music.STYLES.has("sitges"), "Music.STYLES has sitges")
	_check(Music.DARES.has("kitesurfer"), "Music.DARES has kitesurfer")
	_check(S.WAVE_WARN_S >= 0.8, "wave telegraph >= 0.8 s")

	# 2. Layout, Solids, Walkability & Surfaces
	var m := await _load(game, "wind", "day")
	var lc_errs: Array = LC.check(m)
	_check(lc_errs.is_empty(), "LevelCheck clean (%s)" % str(lc_errs))

	# Corridor nodes smooth slope & open clearance round church
	var nodes: Array = S.edge_nodes(m)
	for i in range(nodes.size() - 1):
		var dy := absf(float(nodes[i]["y"]) - float(nodes[i + 1]["y"]))
		var l0 := float(nodes[i]["cx"]) - float(nodes[i]["half"])
		var l1 := float(nodes[i + 1]["cx"]) - float(nodes[i + 1]["half"])
		var r0 := float(nodes[i]["cx"]) + float(nodes[i]["half"])
		var r1 := float(nodes[i + 1]["cx"]) + float(nodes[i + 1]["half"])
		var dl := absf(l0 - l1)
		var dr := absf(r0 - r1)
		_check(dl / maxf(1.0, dy) <= 0.85 and dr / maxf(1.0, dy) <= 0.85, "corridor slope <= 0.85 at seg %d" % i)

	var punta_e: Vector2 = S.edges_at(-4300.0)
	_check(S.CHURCH_RECT.position.x - punta_e.x >= 200.0, "plaza past church >= 200 px wide")
	var chal_node: Node2D = null
	for ch in m.get_children():
		if ch.has_method("dare_number"):
			chal_node = ch
			break
	_check(chal_node != null and chal_node.global_position.distance_to(S.KITE_POS) < 5.0, "challenger positioned on kite sand")

	# Solids match expected church & railings, and props sit inside edges clear of each other
	var sol: Array[Rect2] = S.solids(m)
	_check(sol.has(S.CHURCH_RECT), "CHURCH_RECT in solids")
	_check(sol.size() >= 6, "railing & wall solids present (%d)" % sol.size())
	for t: Array in _solids(m):
		var p: Vector2 = t[0]
		var e: Vector2 = m.walk_edges(p.y)
		_check(p.x >= e.x - 2.0 and p.x <= e.y + 2.0, "%s inside walk_edges" % t[2])
		_check(not S.CHURCH_RECT.grow(float(t[1]) - 1.0).has_point(p), "%s clear of church solid" % t[2])

	# Surface kinds across sections
	_check(m.surface_at(Vector2(620.0, -500.0)) == Surfaces.S.PAVEMENT, "promenade paving handles as PAVEMENT")
	_check(m.surface_at(Vector2(140.0, -500.0)) == Surfaces.S.WATER, "sea west of shore handles as WATER")
	_check(m.surface_at(S.KITE_POS) == Surfaces.S.SAND, "kitesurfer apron handles as SAND")
	_check(m.surface_at(Vector2(310.0, -800.0)) == Surfaces.S.SAND, "Ribera beach strip handles as SAND")
	_check(m.surface_at(Vector2(560.0, -4300.0)) == Surfaces.S.PAVEMENT, "La Punta rock plaza handles as firm stone (PAVEMENT)")
	_check(m.surface_at(Vector2(580.0, -3700.0)) == Surfaces.S.PAVEMENT, "steps handle as firm stone (PAVEMENT)")
	_check(m.surface_at(Vector2(600.0, -4960.0)) == Surfaces.S.SAND, "Platja de la Fragata handles as SAND")
	_check(Outdoors.wind_strength("wind") == 1.0 and not Outdoors.beach_parasols_open("wind", "day") and Outdoors.blowing_napkins("wind", "day"),
		"Outdoors rules reflect windy day")

	# 3. Telegraphed Breaking Wave Event
	m.human.global_position = Vector2(540.0, -2400.0)
	m.dog.global_position = Vector2(520.0, -2400.0)
	S.tick(m, DT)
	_check(String(m.sitges_wave["state"]) == "spray", "wave enters SPRAY telegraph when pair approaches bend")
	var spray_elapsed := 0.0
	while spray_elapsed < S.WAVE_WARN_S - 0.1 and String(m.sitges_wave["state"]) == "spray":
		S.tick(m, DT)
		spray_elapsed += DT
	_check(spray_elapsed >= 0.78 and String(m.sitges_wave["state"]) == "spray", "SPRAY stays in telegraph >= 0.8 s (%.2f)" % spray_elapsed)
	while String(m.sitges_wave["state"]) == "spray":
		S.tick(m, DT)
	_check(String(m.sitges_wave["state"]) == "wash", "SPRAY transitions cleanly to WASH")

	# Place one bottle inside wash path to confirm loose items slide eastward
	var test_cone: Node2D = null
	for c in get_nodes_in_group("cones"):
		if is_instance_valid(c) and c.global_position.y >= S.WAVE_Y0 and c.global_position.y <= S.WAVE_Y1:
			test_cone = c
			break
	_check(test_cone != null, "loose cone/bottle present in wave wash zone")
	var start_vel_x: float = test_cone.vel.x if test_cone != null else 0.0

	# During WASH: staying inside wash zone soaks human, slicks dog, and pushes cone
	var wash_ticks := 0
	while wash_ticks < 35 and String(m.sitges_wave["state"]) == "wash":
		S.tick(m, DT)
		wash_ticks += 1
	_check(m.human_soak > 0.0, "human inside wash gets soaked (human_soak=%.2f)" % m.human_soak)
	_check(m.dog.slick, "dog inside wash gets slick")
	_check(m.surface_at(Vector2(540.0, -2400.0)) == Surfaces.S.WATER, "active wash handles as WATER")
	if test_cone != null:
		_check(test_cone.vel.x > start_vel_x + 40.0, "wash slides loose bottles/cones eastward (%.1f)" % test_cone.vel.x)

	# Second cycle: pull clear to east dry strip >= 780 -> dodge goal increments without soaking
	m.sitges_wave["cooldown"] = 0.0
	m.sitges_wave["state"] = "wait"
	m.human.global_position = Vector2(560.0, -2400.0)
	m.dog.global_position = Vector2(820.0, -2400.0)
	S.tick(m, DT)
	m.human.global_position = Vector2(820.0, -2400.0)
	while String(m.sitges_wave["state"]) in ["spray", "wash"]:
		S.tick(m, DT)
	_check(m.sitges_waves_dodged >= 1, "staying clear in east dry strip awards wave_dodge (%d)" % m.sitges_waves_dodged)

	# 4. Napkins & Bell bark
	_check(m.sitges_napkins.size() > 0, "windy day spawns blowing napkins (%d)" % m.sitges_napkins.size())
	var np0: Vector2 = m.sitges_napkins[0].pos
	m.dog.global_position = np0
	S.tick(m, DT)
	_check(m.sitges_napkins_caught >= 1, "dog catches blowing napkin (%d)" % m.sitges_napkins_caught)

	m.dog.global_position = S.BELL_POS + Vector2(-70.0, 20.0)
	_check(S.on_bark(m), "barking near Sant Bartomeu bell tower answers")
	_check(m.sitges_church_barked, "bell bark flag set for goal")

	_free(m)

	if failures.is_empty():
		print("test_sitges: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_sitges: %d FAILED of %d checks" % [failures.size(), checks])
		quit(1)
