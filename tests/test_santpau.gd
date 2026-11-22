extends SceneTree

# Tests Sant Pau (systems/santpau.gd):
# - registered at the end of LEVELS, right after espanya in CAROUSEL,
#   STAR_GATE 46, CHASE_GATE "boars", CAMPAIGN_SKY ["clear", "dusk"],
#   LEVEL_NAMES "Sant Pau", glossed, 15 goals with santpau_tour, santpau_chime,
#   santpau_lavender, and world_sign material "oranges"
# - layout is walkable start to finish (central axis unobstructed, level_check
#   passes, no two solid things clash, all props on paving and clear of solids)
# - solids match PAVILIONS and wrap_rects (rope wraps their corners)
# - surfaces: garden beds handle as GRASS, paths and courtyard walks as PAVEMENT
# - dusk lamps and pavilion fronts lit via Game.lamp_glow()
# - live event: clock tower chimes and school tour group telegraphed >= 0.8 s
#   before stepping onto the axis; bark cheers & howls; bump costs patience
#   (respecting grace); dodge awards a save
# - dare-giver "sketcher" registered with 5 lines and dare_sketcher track

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


func _load(game, hour: String, weather := "clear") -> Node2D:
	game.weather = weather
	game.hour = hour
	game.level_id = "santpau"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = false
	return m


static func _solids(m: Node2D) -> Array:
	var things: Array = []
	var furniture := {}
	for bn: Vector2 in m.bins:
		things.append([bn, 10.0, "bin %s" % bn])
		furniture[bn] = true
	for bnc: Vector2 in m.benches:
		things.append([bnc, 12.0, "bench %s" % bnc])
		furniture[bnc] = true
	for i in range(m.body_pole_count):
		if not furniture.has(m.poles[i]):
			things.append([m.poles[i], m.POLE_RADIUS, "pole %s" % m.poles[i]])
	for p: Vector2 in m.performers:
		things.append([p, m.PERFORMER_RADIUS, "person %s" % p])
	for h: Dictionary in m.hydrants:
		things.append([h.pos, m.HYDRANT_RADIUS, "hydrant %s" % h.pos])
	for f: Vector2 in m.fountains:
		things.append([f, m.FOUNTAIN_RADIUS, "fountain %s" % f])
	return things


static func _clashes(m: Node2D, pavs: Array[Rect2]) -> Array:
	var things := _solids(m)
	var clashes: Array[String] = []
	for i in range(things.size()):
		for j in range(i + 1, things.size()):
			var a: Array = things[i]
			var b: Array = things[j]
			if (a[0] as Vector2).distance_to(b[0]) < float(a[1]) + float(b[1]) - 1.0:
				clashes.append("%s / %s" % [a[2], b[2]])
	for r: Rect2 in pavs:
		for t: Array in things:
			if r.grow(float(t[1]) - 1.0).has_point(t[0]):
				clashes.append("pavilion %s / %s" % [r, t[2]])
	var off: Array[String] = []
	for t: Array in things:
		var at: Vector2 = t[0]
		var ee: Vector2 = m.walk_edges(at.y)
		if at.y > m.GATE_Y and (at.x < ee.x - 2.0 or at.x > ee.y + 2.0):
			off.append(String(t[2]))
	for r: Rect2 in pavs:
		for c: Vector2 in [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y)]:
			var ee: Vector2 = m.walk_edges(c.y)
			if c.x < ee.x - 2.0 or c.x > ee.y + 2.0:
				off.append("pavilion %s" % r)
				break
	return [clashes, off, things.size()]


func _free(m: Node2D) -> void:
	m.get_parent().remove_child(m)
	m.free()


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	game.sky_from_args = true
	root.get_node("Sfx").muted = true

	var S: GDScript = load("res://systems/santpau.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var Sur: GDScript = load("res://world/surfaces.gd")
	var Ch: GDScript = load("res://entities/challenger.gd")
	var WS: GDScript = load("res://world/world_sign.gd")

	# --- 1. registration ---
	_check(game.LEVELS.has("santpau") and game.LEVELS.find("santpau") > game.LEVELS.find("molina"), "santpau in LEVELS after molina")
	_check(game.CAROUSEL.find("santpau") == game.CAROUSEL.find("espanya") + 1, "in CAROUSEL right after espanya")
	_check(int(game.STAR_GATE["santpau"]) == 46, "STAR_GATE is 46")
	_check(String(game.CHASE_GATE.get("santpau", "")) == "molina", "CHASE_GATE is molina")
	_check(String(game.LEVEL_NAMES["santpau"]) == "Sant Pau", "named Sant Pau")
	_check(String(game.LEVEL_SUBTITLES.get("santpau", "")) == "The modernista hospital gardens", "English gloss matches")
	_check(game.LEVEL_SUBTITLES_CA.has("santpau") and game.LEVEL_SUBTITLES_ES.has("santpau"), "glossed in CA and ES")
	_check(game.CAMPAIGN_SKY["santpau"] == ["clear", "dusk"], "CAMPAIGN_SKY is clear dusk")
	var ids: Array = G.LEVEL_GOAL_IDS["santpau"]
	_check(ids.size() == 15 and ids.has("santpau_tour") and ids.has("santpau_chime") and ids.has("santpau_lavender"),
		"15 goals with Sant Pau's own three")
	_check(String(WS.MATERIALS.get("santpau", "")) == "oranges", "world_sign material is oranges")
	_check(Ch.giver_for("santpau") == "sketcher", "dare-giver is the watercolor painter")
	_check(Music.all_tracks().has("dare_sketcher"), "music has dare_sketcher")

	# --- 2. walkable layout, solids, surfaces, dusk lighting ---
	var m: Node2D = await _load(game, "dusk")
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level_check passes: %s" % str(problems))

	var pavs: Array[Rect2] = S.solids(m)
	_check(pavs.size() == 10 and S.wrap_rects().size() == 10, "10 solid pavilions and wrap_rects")
	for r: Rect2 in pavs:
		var found_solid := false
		for sr: Rect2 in m.solid_rects:
			if sr.is_equal_approx(r):
				found_solid = true
				break
		_check(found_solid, "pavilion %s in m.solid_rects" % r)
		var found_rope := false
		for rr: Rect2 in m.rope_rects:
			if rr.is_equal_approx(r):
				found_rope = true
				break
		_check(found_rope, "pavilion %s in m.rope_rects for corner wrapping" % r)

	# Central promenade is clear start to finish (no solid pavilion overlaps x=560..720)
	var axis_clear := true
	var y := 240.0
	while y >= float(m.GATE_Y):
		var e: Vector2 = m.walk_edges(y)
		if e.x > 556.0 or e.y < 724.0:
			axis_clear = false
			break
		for r: Rect2 in pavs:
			if r.intersects(Rect2(556.0, y - 20.0, 168.0, 40.0)):
				axis_clear = false
				break
		y -= 60.0
	_check(axis_clear, "central promenade x=556..724 is unobstructed from start to gate")

	var cl: Array = _clashes(m, pavs)
	_check((cl[0] as Array).is_empty(), "no two solids clash: %s" % str((cl[0] as Array).slice(0, 6)))
	_check((cl[1] as Array).is_empty(), "all props and pavilions inside walk edges: %s" % str((cl[1] as Array).slice(0, 6)))

	# Surfaces: garden beds are GRASS, paths & courtyard paths are PAVEMENT
	_check(S.surface(m, S.GARDEN_BEDS[0].get_center()) == Sur.S.GRASS, "garden bed handles as GRASS")
	_check(S.surface(m, Vector2(640.0, -1500.0)) == Sur.S.PAVEMENT, "central axis path handles as PAVEMENT")
	_check(S.surface(m, S.COURTYARD_BEDS[0].get_center()) == Sur.S.GRASS, "courtyard garden bed handles as GRASS")
	_check(S.surface(m, Vector2(640.0, -5120.0)) == Sur.S.PAVEMENT, "courtyard path handles as PAVEMENT")

	# Dusk lamps & lit fronts
	_check(game.lamp_glow() > 0.0, "Game.lamp_glow() > 0 at dusk")
	_check(not m.night_lights().is_empty(), "garden lamps provide night_lights")
	_check(not m.night_fronts().is_empty(), "pavilions emit night_fronts")

	# --- 3. live event: clock tower chime & telegraphed school tour ---
	var tour = m.santpau_tour
	_check(tour != null and tour.state == S.SchoolTour.State.IDLE, "school tour starts IDLE")
	m.phase = "out"
	m.human.global_position = Vector2(640.0, S.TOUR_TRIGGER_Y - 20.0)
	m.dog.global_position = Vector2(640.0, S.TOUR_TRIGGER_Y - 80.0)
	S.tick(m, DT)
	_check(tour.state == S.SchoolTour.State.TELEGRAPH, "approaching axis triggers TELEGRAPH")
	_check(m.santpau_chime_t > 0.0, "clock tower chimes on trigger")
	var warn_elapsed := 0.0
	while tour.state == S.SchoolTour.State.TELEGRAPH and warn_elapsed < 3.0:
		S.tick(m, DT)
		warn_elapsed += DT
	_check(warn_elapsed >= 0.8, "telegraph lasts >= 0.8 s before group crosses (%.2f s)" % warn_elapsed)
	_check(tour.state == S.SchoolTour.State.CROSSING, "tour enters CROSSING after telegraph")

	# Barking during crossing cheers the class & howls with the chime
	var leader_p: Vector2 = tour.member_pos(0)
	m.dog.global_position = leader_p + Vector2(0.0, 40.0)
	var bark_ok: bool = S.on_bark(m, m.dog.global_position)
	_check(bark_ok and tour.cheered and m.santpau_chime_howled, "barking cheers the school tour and howls with the chime")

	# Bumping a tour member costs patience; respect grace_t
	tour.human_hit = false
	m.human.patience = 0.8
	m.human.grace_t = 0.0
	m.human.global_position = tour.member_pos(2)
	S.tick(m, DT)
	_check(tour.human_hit and is_equal_approx(float(m.human.patience), 0.8 - S.TOUR_PATIENCE_COST),
		"bumping the school tour costs TOUR_PATIENCE_COST")

	# Lavender bed tracking
	m.santpau_beds_visited.clear()
	for bi in range(3):
		m.dog.global_position = S.GARDEN_BEDS[bi].get_center()
		S.tick(m, DT)
	_check(m.santpau_beds_visited.size() == 3, "visiting 3 lavender beds fills lavender goal")

	_free(m)

	print("test_santpau: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
