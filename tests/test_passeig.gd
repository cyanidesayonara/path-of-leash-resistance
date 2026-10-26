extends SceneTree

# Passeig Marítim's audit fixes (#151): the palms come in runs rather than at
# one spacing; the showers' columns and the volleyball net's posts are solid
# poles the rope can wrap; the chiringuitos' bar huts are solid and clear of
# their terraces; no towel is laid across a landmark; and the sand is the
# ground itself, not a tinted box laid over it that stops at the gate; and the
# dog beach past the gate handles as the sand it is drawn as.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# the dog driven at a spot from a little way off: true if something stops her
func _stops_dog(dog: CharacterBody2D, at: Vector2, from_dir: Vector2, dist := 60.0) -> bool:
	dog.global_position = at + from_dir * dist
	for i in range(40):
		dog.velocity = -from_dir * 500.0
		dog.move_and_slide()
	return dog.global_position.distance_to(at) > 12.0


func _run() -> void:
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "beach"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	# the palms: two ranks, and neither on a ruler
	for rank: Array in [LevelBuild.BEACH_PALMS_SEA, LevelBuild.BEACH_PALMS_LAND]:
		var gaps := {}
		for i in range(1, rank.size()):
			gaps[int(round(absf(float(rank[i]) - float(rank[i - 1])) / 10.0))] = true
		_check(gaps.size() >= 4, "a rank of palms has more than one spacing (%d)" % gaps.size())

	# showers and net posts: poles with bodies, not drawn as palms
	var posts: Array[Vector2] = []
	posts.append_array(LevelBuild.BEACH_SHOWERS)
	posts.append_array(LevelBuild.beach_net_posts())
	for p: Vector2 in posts:
		var idx: int = (m.poles as Array).find(p)
		_check(idx >= m.deco_pole_count and idx < m.body_pole_count,
			"the post at (%.0f, %.0f) is a solid pole, not a palm" % [p.x, p.y])
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	_check(_stops_dog(dog, LevelBuild.BEACH_SHOWERS[0], Vector2(0.0, 1.0)), "a shower's column stops the dog")
	_check(_stops_dog(dog, LevelBuild.beach_net_posts()[1], Vector2(0.0, 1.0)), "a net post stops the dog")

	# the landmarks keep clear of the palms and of each other's furniture
	var marks: Array[Vector2] = posts.duplicate()
	marks.append(LevelBuild.BEACH_TOWER)
	for ps: Vector2 in m.palm_spots:
		for mk: Vector2 in marks:
			_check(ps.distance_to(mk) > 70.0, "palm (%.0f, %.0f) is clear of the landmark at (%.0f, %.0f)" % [ps.x, ps.y, mk.x, mk.y])
		for br: Rect2 in LevelBuild.BEACH_BARS:
			_check(not br.grow(30.0).has_point(ps), "palm (%.0f, %.0f) is clear of a bar hut" % [ps.x, ps.y])

	# the bar huts: solid, and no table or chair inside one
	for br: Rect2 in LevelBuild.BEACH_BARS:
		_check(_stops_dog(dog, br.get_center(), Vector2(-1.0, 0.0), br.size.x * 0.5 + 30.0),
			"the bar hut at y=%.0f stops the dog" % br.position.y)
		for t: Vector2 in m.tables:
			_check(not br.has_point(t), "a table stands outside the bar hut")
		for c: Vector2 in m.chairs:
			_check(not br.has_point(c), "a chair stands outside the bar hut")

	# no towel across the court, under the tower or in a shower's puddle
	for tw: Dictionary in m.towels:
		for keep: Rect2 in LevelBuild.beach_sand_keepouts():
			_check(not (tw.rect as Rect2).intersects(keep), "a towel keeps off the landmarks")

	# the sand is ground, drawn with the cross-section, not a box over it
	var sand_ground := false
	for sz: Dictionary in m.substance_zones:
		if String(sz.kind) == "sand" and not sz.has("patch"):
			sand_ground = bool(sz.get("ground", false))
	_check(sand_ground, "the seafront's sand zone is the ground itself")
	# and the dog beach's shore meets the walk's at the gate
	_check(is_equal_approx(m.beach_shore_x(m.GATE_Y - 30.0), 230.0), "the shorelines meet at the gate")
	# the dog beach handles as sand from the fence to the water, and its sea
	# is still water; the deck below the gate stays firm
	var S: Dictionary = (load("res://world/surfaces.gd") as GDScript).S
	var fr: Rect2 = m._freedom_rect()
	var not_sand := 0
	var y := fr.position.y + 40.0
	while y < fr.end.y - 10.0:
		var x: float = m.beach_shore_x(y) + 20.0
		while x < fr.end.x - 20.0:
			if int(m.surface_at(Vector2(x, y))) != S.SAND:
				not_sand += 1
			x += 60.0
		_check(int(m.surface_at(Vector2(m.beach_shore_x(y) - 80.0, y))) == S.WATER,
			"the dog beach's sea is water at y=%d" % int(y))
		y += 90.0
	_check(not_sand == 0, "the dog beach is sand from the shore to the fence (%d points not)" % not_sand)
	_check(int(m.surface_at(Vector2(700.0, m.GATE_Y + 120.0))) == S.PAVEMENT,
		"the promenade below the gate stays pavement")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_passeig: OK")
		quit(0)
	else:
		quit(1)
