extends SceneTree

# El Bosc is its own wood, not El Parc with a bent path (docs/LEVEL_DESIGN.md):
# no pond, no park benches, a stream crossing the trail under a footbridge
# with water either side and dry boards on it, a drink at the bank, and a
# solid wood line a strip out from the trail that the dog cannot walk into.

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
	game.level_id = "trail"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.pond.size.x == 0.0, "no pond carried over from El Parc")
	_check(m.benches.size() <= 1, "one bench at most, at the viewpoint (%d)" % m.benches.size())
	_check(m.bins.size() <= 2, "a bin at the trailhead and the viewpoint only (%d)" % m.bins.size())
	var sy: float = LevelBuild.TRAIL_STREAM_Y
	var e: Vector2 = m.walk_edges(sy)
	var W: int = m.Surfaces.S.WATER
	_check(m.surface_at(Vector2(e.x - 40.0, sy)) == W and m.surface_at(Vector2(e.y + 40.0, sy)) == W,
		"the stream is water either side of the trail")
	_check(m.surface_at(Vector2((e.x + e.y) * 0.5, sy)) != W, "the footbridge carries the trail over it dry")
	# the drink is at the bank: every refill point is within reach of water
	for f: Vector2 in m.fountains:
		var near := false
		for w: Rect2 in m.water:
			near = near or w.grow(60.0).has_point(f)
		_check(near, "the drink at (%.0f, %.0f) is at the stream" % [f.x, f.y])
	# the wood line: a dog pushed off the trail stops a strip out from it
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var y := -3100.0
	var ey: Vector2 = m.walk_edges(y)
	dog.global_position = Vector2(ey.x - 30.0, y)
	for i in range(60):
		dog.velocity = Vector2(-600.0, 0.0)
		dog.move_and_slide()
	var line: float = ey.x - float(LevelBuild.TRAIL_WOOD_OUT)
	_check(dog.global_position.x > line - 30.0 and dog.global_position.x < ey.x,
		"the dog can nose about the forest floor but stops at the wood line (x %.0f, line %.0f)" % [dog.global_position.x, line])
	# and the pinecone prize off the trail is still inside it
	_check(m.prize_pos.x > m.walk_edges(m.prize_pos.y).x - float(LevelBuild.TRAIL_WOOD_OUT) + 10.0,
		"the pinecone in the brush is on this side of the wood line")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_bosc: OK")
		quit(0)
	else:
		quit(1)
