extends SceneTree

# Passeig Marítim's audit fixes (#151) and Badalona seafront rework: the palms
# come in runs rather than at one spacing; the showers' columns and the
# volleyball net's posts are solid poles the rope can wrap; the chiringuitos'
# bar huts are solid and clear of their terraces; no towel is laid across a
# landmark; the sand is the ground itself; Badalona's landmarks sit in their
# real south-to-north order from Estació de Badalona and the bus stop up to
# Pont del Petroli and the Hotel Marina Badalona plaza with the BADALONA sign;
# rollerbladers skate the bike lane; and Platja de Llevant owns the dog beach
# (PLATJA DELS GOSSOS) past the gate.

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
	var Passeig: GDScript = load("res://systems/passeig.gd")
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
		_check(not Passeig.SURF_CLUB_RECT.grow(12.0).has_point(ps), "palm (%.0f, %.0f) is clear of Surf Club" % [ps.x, ps.y])
		_check(not Passeig.GYM_RECT.grow(12.0).has_point(ps), "palm (%.0f, %.0f) is clear of Gym" % [ps.x, ps.y])

	# solid landmarks: bar huts, surf club, gym, hotel and tourist letters sign
	for br: Rect2 in LevelBuild.BEACH_BARS:
		_check(_stops_dog(dog, br.get_center(), Vector2(-1.0, 0.0), br.size.x * 0.5 + 30.0),
			"the bar hut at y=%.0f stops the dog" % br.position.y)
		for t: Vector2 in m.tables:
			_check(not br.has_point(t), "a table stands outside the bar hut")
		for c: Vector2 in m.chairs:
			_check(not br.has_point(c), "a chair stands outside the bar hut")
	_check(_stops_dog(dog, Passeig.HOTEL_RECT.get_center(), Vector2(0.0, 1.0), Passeig.HOTEL_RECT.size.y * 0.5 + 30.0),
		"Hotel Marina Badalona stops the dog")
	_check(_stops_dog(dog, Passeig.HOTEL_SIGN_RECT.get_center(), Vector2(0.0, 1.0), Passeig.HOTEL_SIGN_RECT.size.y * 0.5 + 20.0),
		"the BADALONA letters sign stops the dog")
	for t: Vector2 in m.trees:
		_check(not Passeig.HOTEL_RECT.grow(20.0).has_point(t), "plaza tree at (%.0f, %.0f) is clear of Hotel Marina" % [t.x, t.y])
		_check(not Passeig.HOTEL_SIGN_RECT.grow(20.0).has_point(t), "plaza tree at (%.0f, %.0f) is clear of BADALONA sign" % [t.x, t.y])

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
	# and the plaza's western shore meets the walk's at the gate
	_check(is_equal_approx(m.beach_shore_x(m.GATE_Y - 30.0), 230.0), "the shorelines meet at the gate")

	# Badalona landmark order (south to north): station/bus stop -> chiringuitos/surf club ->
	# restaurant -> gym/calisthenics -> Pont del Petroli & Anís del Mono works -> Hotel Marina Badalona plaza
	_check(Passeig.BUS_STOP_RECT.position.y > Passeig.SURF_CLUB_RECT.position.y, "bus stop is south of surf club")
	_check(Passeig.SURF_CLUB_RECT.position.y > Passeig.RESTAURANT_RECT.position.y, "surf club is south of restaurant")
	_check(Passeig.RESTAURANT_RECT.position.y > Passeig.GYM_RECT.position.y, "restaurant is south of gym")
	_check(Passeig.GYM_RECT.position.y > LevelBuild.BEACH_PIER_Y, "gym is south of Pont del Petroli")
	_check(absf(Passeig.WORKS_Y - LevelBuild.BEACH_PIER_Y) < 420.0, "Anís del Mono works sit opposite Pont del Petroli")
	_check(Passeig.HOTEL_SIGN_RECT.position.y < float(m.GATE_Y), "BADALONA sign stands in the hotel plaza past the gate")
	_check(Passeig.HOTEL_RECT.position.y < Passeig.HOTEL_SIGN_RECT.position.y, "Hotel Marina Badalona stands north of the BADALONA sign")

	# Rollerbladers (kind == "roller") spawn on the seafront bike lane
	m.cam.position.y = -2000.0
	var rollers := 0
	for _i in range(30):
		m.vspawn_t = 0.0
		m._vlane(1.0)
		for n in m.get_tree().get_nodes_in_group("bikes"):
			if n.get("kind") == "roller":
				rollers += 1
			n.remove_from_group("bikes")
	_check(rollers >= 1, "rollerbladers skate along Passeig Marítim (%d spawned)" % rollers)

	# Hotel Marina Badalona plaza past the gate handles as pavement east of x=452, sea west of shore
	var S: Dictionary = (load("res://world/surfaces.gd") as GDScript).S
	var fr: Rect2 = m._freedom_rect()
	var not_pave := 0
	var y := fr.position.y + 40.0
	while y < fr.end.y - 10.0:
		var x := 460.0
		while x < fr.end.x - 20.0:
			if int(m.surface_at(Vector2(x, y))) != S.PAVEMENT:
				not_pave += 1
			x += 60.0
		_check(int(m.surface_at(Vector2(m.beach_shore_x(y) - 80.0, y))) == S.WATER,
			"the plaza's sea is water at y=%d" % int(y))
		y += 90.0
	_check(not_pave == 0, "the Hotel Marina Badalona plaza is pavement from x=452 to the east wall (%d points not)" % not_pave)
	_check(int(m.surface_at(Vector2(700.0, m.GATE_Y + 120.0))) == S.PAVEMENT,
		"the promenade below the gate stays pavement")

	m.queue_free()
	await process_frame

	# Platja de Llevant (llevant) now owns the dog beach past the gate:
	# handles as sand from the fence to the water, and its sea is water
	game.level_id = "llevant"
	var ml: Node2D = load("res://main.tscn").instantiate()
	root.add_child(ml)
	if not ml.is_node_ready():
		await ml.ready
	var fr_l: Rect2 = ml._freedom_rect()
	var not_sand := 0
	var yl := fr_l.position.y + 40.0
	while yl < fr_l.end.y - 10.0:
		var xl: float = ml.beach_shore_x(yl) + 20.0
		while xl < fr_l.end.x - 20.0:
			if int(ml.surface_at(Vector2(xl, yl))) != S.SAND:
				not_sand += 1
			xl += 60.0
		_check(int(ml.surface_at(Vector2(ml.beach_shore_x(yl) - 80.0, yl))) == S.WATER,
			"the dog beach's sea is water at y=%d" % int(yl))
		yl += 90.0
	_check(not_sand == 0, "Platja de Llevant's dog beach is sand from the shore to the fence (%d points not)" % not_sand)
	ml.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_passeig: OK")
		quit(0)
	else:
		quit(1)
