extends SceneTree

# El Parc is its own park (docs/LEVEL_DESIGN.md): the path opens out round the
# lake, which stands in the middle as an island with a shore to walk on either
# side; the owner keeps to the east shore; the flowerbed edging is a grind
# rail, and so are the path's own edges where it bends; the bandstand's posts
# are solid; the mammoth can be marked; the sandpit takes prints.

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
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var lake: Rect2 = LevelBuild.PARK_LAKE
	var ly: float = lake.get_center().y
	var e: Vector2 = m.walk_edges(ly)
	var W: int = m.Surfaces.S.WATER
	_check(m.surface_at(lake.get_center()) == W, "the lake is water")
	_check(m.surface_at(Vector2((e.x + lake.position.x) * 0.5, ly)) != W, "there is a west shore to walk")
	_check(m.surface_at(Vector2((e.y + lake.end.x) * 0.5, ly)) != W, "and an east shore")

	# the owner keeps to the east shore past the lake
	var human: CharacterBody2D = m.human
	var east := true
	for y in [lake.end.y + 40.0, ly, lake.position.y - 40.0]:
		human.global_position = Vector2(lake.end.x + 60.0, y)
		human.velocity = Vector2.ZERO
		for f in range(900):
			m.elapsed += 1.0 / 30.0
			human._walk(1.0 / 30.0)
			human.global_position.y = y
			east = east and human.global_position.x > lake.end.x + 10.0
	_check(east, "the owner's weave keeps to the east shore past the lake")
	# approaching from the south, the owner is already over before the water
	human.global_position = Vector2(m.walk_cx, lake.end.y + 420.0)
	human.velocity = Vector2.ZERO
	for f in range(600):
		m.elapsed += 1.0 / 30.0
		human._walk(1.0 / 30.0)
		if human.global_position.y < lake.end.y:
			break
	_check(human.global_position.x > lake.end.x, "walking up to the lake, the owner has crossed to the east shore by the water (x %.0f)" % human.global_position.x)

	# grindables: each flowerbed's clipped hedge edging, both long sides
	_check(m.rails.size() == LevelBuild.PARK_BEDS.size() * 2, "every flowerbed's edging is grindable")
	var hedges := true
	for r: Dictionary in m.rails:
		hedges = hedges and String(r["name"]) == "HEDGE RUN"
	_check(hedges, "and grinding it is a hedge run")

	# the bandstand's posts are solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var bs: Vector2 = LevelBuild.PARK_BANDSTAND
	var post: Vector2 = LevelBuild.bandstand_posts()[0]
	var out_dir: Vector2 = (post - bs).normalized()
	dog.global_position = post + out_dir * 40.0
	for i in range(40):
		dog.velocity = -out_dir * 500.0
		dog.move_and_slide()
	_check(dog.global_position.distance_to(post) > 16.0, "a bandstand post stops the dog")

	# the mammoth is markable, and not counted as off the path
	var mam: Array = m.hydrants.filter(func(h: Dictionary) -> bool: return String(h.get("kind", "")) == "mammoth")
	_check(mam.size() == 1, "the mammoth's foot is a spot to mark")

	# the sandpit takes prints
	var sp: Vector2 = LevelBuild.PARK_PLAYGROUND.get_center() + Vector2(-28.0, 40.0)
	_check(m._takes_prints(sp), "the sandpit takes prints")
	_check(not m._takes_prints(Vector2(m.walk_cx, -1200.0)), "the gravel path does not")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_parc: OK")
		quit(0)
	else:
		quit(1)
