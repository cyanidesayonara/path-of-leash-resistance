extends SceneTree

# La Carretera de les Aigües (systems/aigues.gd): the hillside track.
# Registration, the level check, the bends inside their envelope, the culvert
# pinch and its parapet rails, the margin pines as forest trees, the fence
# posts on the drop side, the riders down the middle of the track, the bells,
# and the view goal, each with the case that must not count.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "aigues"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var A: GDScript = load("res://systems/aigues.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration
	_check(game.LEVELS.has("aigues") and game.CAROUSEL.has("aigues"), "in LEVELS and CAROUSEL")
	_check(int(game.STAR_GATE["aigues"]) == 37, "opens at 37 stars")
	_check(String(game.LEVEL_NAMES["aigues"]) == "La Carretera de les Aigües", "named La Carretera de les Aigües")
	_check(String(game.LEVEL_SUBTITLES["aigues"]) == "The hillside hike", "subtitled the hillside hike")
	_check(m.gate_text == "FONT DE LA BUDELLERA", "gate text is FONT DE LA BUDELLERA")
	_check(m.freedom_kind == "clearing", "ends in the clearing")
	_check(String(load("res://systems/arrival.gd").place_for("aigues")) == "trailhead", "starts at a trailhead")

	# 2. Structural level check
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. The bends stay inside the envelope, so the side walls never cut in;
	# the culvert pinches and the mirador bulges
	var y: float = m.START_Y
	var inside := true
	while y > m.GATE_Y:
		var e: Vector2 = m.walk_edges(y)
		if e.x < m.sw_l - 0.5 or e.y > m.sw_r + 0.5:
			inside = false
			print("edge outside the envelope at y %.0f: %s" % [y, e])
		y -= 25.0
	_check(inside, "every bend is inside sw_l..sw_r")
	var ec: Vector2 = m.walk_edges(A.CULVERT_Y)
	var em: Vector2 = m.walk_edges(A.MIRADOR_Y)
	var e0: Vector2 = m.walk_edges(-1700.0)
	_check(ec.y - ec.x < e0.y - e0.x - 100.0, "the culvert pinches the track (%.0f against %.0f)" % [ec.y - ec.x, e0.y - e0.x])
	_check(em.x < e0.x - 30.0, "the mirador bulges toward the drop")
	_check(A.MIRADOR_SPOT.x > em.x and A.MIRADOR_SPOT.x < em.y, "the mirador spot is on the track")
	_check(m.surface_at(Vector2((e0.x + e0.y) * 0.5, -1700.0)) == m.Surfaces.S.PAVEMENT, "the track is firm underfoot")

	# 4. Rope geometry: the margin pines are deco poles drawn as forest trees,
	# the fence posts are poles on the drop side, never on the culvert
	_check(m.deco_pole_count == A.pines(m).size(), "every deco pole is a pine (%d)" % m.deco_pole_count)
	for i in range(m.deco_pole_count):
		_check(m.pole_tree(i) == m.TREE_FOREST and not m.is_lamppost(i), "pole %d is a forest tree, not a lamp" % i)
	var posts: Array[Vector2] = A.fence_posts(m)
	_check(posts.size() >= 25, "a fence's worth of posts (%d)" % posts.size())
	for fp: Vector2 in posts:
		if not (fp in m.poles) or A.on_culvert(fp.y) or fp.x > m.walk_edges(fp.y).x + 20.0:
			_check(false, "fence post at %s is a pole on the drop side, off the culvert" % fp)
			break

	# 5. The signature line's grind: the culvert's two parapets
	var parapets := 0
	for r: Dictionary in m.rails:
		if String(r["name"]) == "PARAPET RUN":
			parapets += 1
	_check(parapets == 2, "both parapets are grindable (%d)" % parapets)

	# 6. Contents
	_check(m.hydrants.size() >= 5, "at least 5 marking spots (%d)" % m.hydrants.size())
	_check(m.kebabs.size() >= 3, "at least 3 dropped snacks (%d)" % m.kebabs.size())
	_check(m.benches.size() == 2, "two mirador benches")
	_check(m.fountains.size() == 1, "one font to drink at")
	var muds := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "mud":
			muds += 1
	_check(muds >= 3, "mud in the low spots (%d)" % muds)
	_check(m.prize_pos == A.PRIZE and m.prize_text == A.PRIZE_TEXT, "the banana is the prize")
	var goal_ids: Array = G.LEVEL_GOAL_IDS["aigues"]
	_check("bikes" in goal_ids and "view" in goal_ids and "drink" in goal_ids, "bikes, view and drink goals")

	# 7. Riders keep to the middle of the track, where every bend overlaps
	for k in range(40):
		var rl: Dictionary = A.rider_lane(m, k % 2 == 0)
		if float(rl.x) < A.RIDE_LO or float(rl.x) > A.RIDE_HI:
			_check(false, "a rider starts inside the lane (%.0f)" % float(rl.x))
			break
	y = m.START_Y
	var lane_on_track := true
	while y > m.GATE_Y:
		var e2: Vector2 = m.walk_edges(y)
		if A.RIDE_LO < e2.x + 20.0 or A.RIDE_HI > e2.y - 20.0:
			lane_on_track = false
		y -= 25.0
	_check(lane_on_track, "the riders' lane is on the track the whole way")

	# 8. A rider coming at your human rings, once; one riding away does not
	var hp: Vector2 = m.human.global_position
	var bk := Node2D.new()
	bk.set_script(load("res://entities/bike.gd"))
	bk.set_physics_process(false)
	bk.set_process(false)
	m.add_child(bk)
	bk.setup(m, m.dog, m.human, Vector2(0.0, 300.0), "bike")
	bk.set_physics_process(false)
	bk.global_position = hp + Vector2(0.0, -200.0)
	bk.vel = Vector2(0.0, -300.0)
	A.tick(m, 0.016)
	_check(not bk.has_meta("rang"), "a rider going away does not ring")
	bk.vel = Vector2(0.0, 300.0)
	A.tick(m, 0.016)
	_check(bk.has_meta("rang"), "a rider coming at your human rings")
	bk.queue_free()

	# 9. The view: trotting through the mirador is not it, nor standing there
	# alone; keeping still there with your human close is
	_check(not A.view_taken(m), "the view not yet taken")
	m.dog.global_position = A.MIRADOR_SPOT
	m.dog.velocity = Vector2(140.0, 0.0)
	m.human.global_position = A.MIRADOR_SPOT + Vector2(80.0, 40.0)
	for k in range(90):
		A.tick(m, 0.016)
	_check(not A.view_taken(m), "trotting through the mirador is not the view")
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = A.MIRADOR_SPOT + Vector2(150.0, 600.0)
	for k in range(90):
		A.tick(m, 0.016)
	_check(not A.view_taken(m), "keeping still there without your human is not the view")
	m.human.global_position = A.MIRADOR_SPOT + Vector2(80.0, 40.0)
	for k in range(40):
		A.tick(m, 0.016)
	_check(not A.view_taken(m), "not after a moment")
	for k in range(40):
		A.tick(m, 0.016)
	_check(A.view_taken(m), "still at the mirador with your human close, for a second, is")

	m.queue_free()
	print("test_aigues: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
