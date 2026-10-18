extends SceneTree

# La Neteja is its own back street at dawn (docs/LEVEL_DESIGN.md): dumpsters
# out at the kerbs (solid) that still leave the street runnable for the
# sweeper chase, scooters parked up, crates by the dumpsters, puddles from
# the water truck, washing overhead, and a dawn light over it all.

var LevelBuild: GDScript
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
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "neteja"
	game.night = false
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var dumps: Array = LevelBuild.neteja_dumpsters(m)
	_check(dumps.size() >= 4, "dumpsters out at the kerbs")
	# still runnable: a clear gap past every dumpster, wider than the pair
	var runnable := true
	for d: Vector2 in dumps:
		var e: Vector2 = m.walk_edges(d.y)
		var gap: float = (e.y - e.x) - LevelBuild.NETEJA_DUMPSTER.x - 12.0
		runnable = runnable and gap >= 250.0
	_check(runnable, "a runnable gap past every dumpster")
	_check(m.scooters.size() >= 3, "scooters parked up")
	var puddles := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "puddle":
			puddles += 1
	_check(puddles >= 4, "puddles from the water truck (%d)" % puddles)
	_check(m.laundry_lines.size() >= 4, "washing overhead")
	var tint: Color = m._weather_tint()
	_check(tint.r > tint.b + 0.1, "a warm dawn light")
	# the market skeleton used to leave an open manhole, and four warning
	# cones round it, in the middle of the chase
	_check(m.manholes.is_empty(), "no open manhole in the lane")
	var road_cones := 0
	var crates := 0
	for c: Node2D in m.get_tree().get_nodes_in_group("cones"):
		if String(c.kind) == "cone":
			road_cones += 1
		elif String(c.kind) == "crate":
			crates += 1
	_check(road_cones == 0, "no warning cones in the street (%d)" % road_cones)
	_check(crates >= dumps.size() * 2, "delivery crates stacked by the dumpsters (%d)" % crates)
	var lamps := true
	for i in range(m.deco_pole_count):
		lamps = lamps and m.pole_tree(i) == m.TREE_NONE
	_check(lamps and m.deco_pole_count >= 4, "the slalom posts are lampposts, not trees")
	var hydrant_clear := true
	for hyd: Dictionary in m.hydrants:
		var hp: Vector2 = hyd.pos
		for d: Vector2 in dumps:
			var body := Rect2(d - LevelBuild.NETEJA_DUMPSTER * 0.5, LevelBuild.NETEJA_DUMPSTER)
			if body.grow(6.0).has_point(hp):
				hydrant_clear = false
	_check(hydrant_clear, "no hydrant parked inside a dumpster")
	# a dumpster is solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var d0: Vector2 = dumps[0]
	var into := 1.0 if d0.x < m.walk_cx else -1.0
	dog.global_position = d0 + Vector2(into * 70.0, 0.0)
	for i in range(40):
		dog.velocity = Vector2(-into * 400.0, 0.0)
		dog.move_and_slide()
	_check(absf(dog.global_position.x - d0.x) > LevelBuild.NETEJA_DUMPSTER.x * 0.5 - 2.0, "a dumpster stops the dog")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_neteja: OK")
		quit(0)
	else:
		quit(1)
