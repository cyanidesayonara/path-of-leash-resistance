extends SceneTree

# El Laberint d'Horta (systems/horta.gd): the cypress maze. Registration, the
# level check, the maze straight between its walls, the hedge blocks as solid
# islands on alternating sides with the leash going round them, Eros as a fat
# real pole on a solid plinth, the balustrade rail, the contents, and the
# Eros lap goal, each with the case that must not count.

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
	game.level_id = "horta"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var H: GDScript = load("res://systems/horta.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration
	_check(game.LEVELS.has("horta") and game.CAROUSEL.has("horta"), "in LEVELS and CAROUSEL")
	_check(int(game.STAR_GATE["horta"]) == 39, "opens at 39 stars")
	_check(String(game.LEVEL_NAMES["horta"]) == "El Laberint d'Horta", "named El Laberint d'Horta")
	_check(String(game.LEVEL_SUBTITLES["horta"]) == "The cypress maze", "subtitled the cypress maze")
	_check(game.LEVEL_SUBTITLES_CA.has("horta") and game.LEVEL_SUBTITLES_ES.has("horta"), "glossed in Catalan and Spanish")
	_check(m.gate_text == "COLLSEROLA", "gate text is COLLSEROLA")
	_check(m.freedom_kind == "clearing", "ends in the clearing")
	_check(String(load("res://systems/arrival.gd").place_for("horta")) == "metro", "arrives by metro")

	# 2. Structural level check
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. The maze runs straight between its walls
	var y: float = H.MAZE_BOT - 10.0
	var straight := true
	while y > H.MAZE_TOP + 10.0:
		var e: Vector2 = m.walk_edges(y)
		if absf(e.x - H.MAZE_X0) > 0.5 or absf(e.y - H.MAZE_X1) > 0.5:
			straight = false
			print("maze edge off its walls at y %.0f: %s" % [y, e])
		y -= 25.0
	_check(straight, "the path is the maze, wall to wall")

	# 4. The hedge blocks: inside the maze, solid, each an island on its side,
	# the sides alternating with Eros in the sequence; the leash goes round them
	var seq: Array[float] = []
	var ordered: Array = []
	for i in range(H.BLOCKS.size()):
		ordered.append([H.BLOCKS[i].get_center().y, H.BLOCK_SIDES[i]])
	ordered.append([H.EROS.y, H.EROS_SIDE])
	ordered.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	for o: Array in ordered:
		seq.append(float(o[1]))
	var alternate := true
	for i in range(1, seq.size()):
		alternate = alternate and seq[i] != seq[i - 1]
	_check(alternate, "the way through goes one side then the other (%s)" % str(seq))
	for r: Rect2 in H.BLOCKS:
		_check(H.in_maze(r.position.y) and H.in_maze(r.end.y), "block %s is in the maze" % r)
		_check(r in m.solid_rects, "block %s is solid" % r)
		_check(r in m.rope_rects, "the leash goes round block %s" % r)
		var e2: Vector2 = m.walk_edges(r.get_center().y)
		_check(r.position.x - e2.x >= 180.0 and e2.y - r.end.x >= 180.0, "both aisles round %s are wide enough" % r)
	_check(m.islands.size() == H.BLOCKS.size() + 1, "every block and Eros is an island (%d)" % m.islands.size())

	# 5. Eros: a real pole with his plinth's girth; nothing else in the maze
	var ei: int = m.poles.find(H.EROS)
	_check(ei >= m.deco_pole_count and ei < m.body_pole_count, "Eros is a body pole")
	_check(m.rope_radii[ei] >= H.EROS_R, "the leash goes round his plinth, not through it")
	_check(m.leash.is_real_pole(H.EROS), "he can be tetherballed round")
	_check(m.pole_tree(ei) == m.TREE_NONE, "he is not drawn as a tree")
	for i in range(m.deco_pole_count):
		_check(not H.in_maze(m.poles[i].y), "tree %d is not inside the maze" % i)

	# 6. The balustrade rail, and the contents
	var rails := 0
	for r: Dictionary in m.rails:
		if String(r["name"]) == "BALUSTRADE RUN":
			rails += 1
	_check(rails == 1, "the terrace balustrade is grindable")
	_check(m.hydrants.size() >= 5, "at least 5 marking spots (%d)" % m.hydrants.size())
	_check(m.kebabs.size() >= 3, "at least 3 dropped snacks (%d)" % m.kebabs.size())
	_check(m.fountains.size() == 1, "one font to drink at")
	_check(H.CANAL in m.water, "the canal is water she can get into")
	for hd in m.hydrants:
		for r: Rect2 in m.solid_rects:
			if r.grow(12.0).has_point(hd.pos):
				_check(false, "marking spot %s is clear of the hedges" % hd.pos)
	_check(m.prize_pos == H.PRIZE and m.prize_text == H.PRIZE_TEXT, "the bocadillo is the prize")
	var goal_ids: Array = G.LEVEL_GOAL_IDS["horta"]
	_check("eros" in goal_ids and "fling" in goal_ids and "drink" in goal_ids, "eros, fling and drink goals")

	# 7. Round Eros: passing him is not a lap, nor a lap without your human
	# near; a whole lap with your human close is
	_check(not H.eros_lapped(m), "Eros not yet lapped")
	m.human.global_position = H.EROS + Vector2(0.0, 260.0)
	for k in range(20):
		var a := -PI * 0.5 + PI * float(k) / 19.0
		m.dog.global_position = H.EROS + Vector2.from_angle(a) * 120.0
		H.tick(m, 0.016)
	_check(not H.eros_lapped(m), "half way round is not a lap")
	m.human.global_position = H.EROS + Vector2(0.0, 900.0)
	for k in range(40):
		m.dog.global_position = H.EROS + Vector2.from_angle(TAU * float(k) / 36.0) * 120.0
		H.tick(m, 0.016)
	_check(not H.eros_lapped(m), "a lap without your human near is not it")
	m.human.global_position = H.EROS + Vector2(0.0, 260.0)
	for k in range(30):
		m.dog.global_position = H.EROS + Vector2.from_angle(-TAU * float(k) / 36.0) * 120.0
		H.tick(m, 0.016)
	_check(not H.eros_lapped(m), "not before the lap is whole")
	for k in range(30, 40):
		m.dog.global_position = H.EROS + Vector2.from_angle(-TAU * float(k) / 36.0) * 120.0
		H.tick(m, 0.016)
	_check(H.eros_lapped(m), "a whole lap the other way with your human close is")

	m.queue_free()
	print("test_horta: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
