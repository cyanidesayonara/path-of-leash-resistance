extends SceneTree

# El Mosaic's life (docs/LEVEL_DESIGN.md): the queue at the gate, standing up
# the west side of the forecourt clear of the owner's line; tourists posing
# round the salamander on the side away from the owner's way round, out only
# as it comes into view, who coo once at a dog who comes to drink; the
# pickpockets starting at the gate and stepping out of the queue; and the
# parakeets going up over the terrace wall.

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


func _tourists(m: Node2D, mode: String) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for tw: Node2D in m.get_tree().get_nodes_in_group("tourists"):
		if tw.mode == mode and not tw.is_queued_for_deletion():
			out.append(tw)
	return out


func _run() -> void:
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "guell"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.crowded(), "El Mosaic has a crowd")
	m.cam.position.y = m.START_Y - 60.0
	m.pp_spawn_t = 99.0
	m._tick_crowd(0.016)
	var queue := _tourists(m, "queue")
	_check(queue.size() == m.MOSAIC_QUEUE, "the gate queue is out (%d)" % queue.size())
	var clear := true
	for tw in queue:
		var e: Vector2 = m.walk_edges(tw.global_position.y)
		clear = clear and tw.global_position.x > e.x and tw.global_position.x < m.walk_cx - 150.0
	_check(clear, "the queue stands up the west side, clear of the owner's line")
	_check(_tourists(m, "amble").size() <= m.MOSAIC_CROWD, "only a few tourists walking")
	_check(_tourists(m, "pose").is_empty(), "nobody at the salamander before it is in view")
	# the first pickpocket works the queue
	m.cam.position.y = 0.0
	m.pp_spawn_t = 0.0
	m._tick_crowd(0.016)
	var pps: Array = m.get_tree().get_nodes_in_group("pickpockets")
	_check(pps.size() == 1, "a pickpocket at the gate")
	if pps.size() == 1:
		var near := INF
		for tw in queue:
			near = minf(near, tw.global_position.distance_to(pps[0].global_position))
		_check(near < 40.0, "he steps out of the queue (%.0f)" % near)
	# the salamander's posers, on its west and south, clear of the owner's way
	var sm: Vector2 = LevelBuild.MOSAIC_SALAMANDER
	m.dog.global_position = sm + Vector2(300.0, 600.0)
	m.cam.position.y = sm.y + 700.0
	m._tick_crowd(0.016)
	var posers := _tourists(m, "pose")
	_check(posers.size() == m.MOSAIC_POSERS.size(), "tourists posing at the salamander (%d)" % posers.size())
	var west := true
	for tw in posers:
		west = west and tw.global_position.x < sm.x - 80.0
	_check(west, "the posers keep off the owner's way round the east side")
	_check(not m.mosaic_aww, "no coo before the dog comes")
	m.dog.global_position = sm + Vector2(0.0, 100.0)
	m._tick_crowd(0.016)
	_check(m.mosaic_aww, "a dog at the salamander is the photo everyone wanted")
	# parakeets go up over the wall they were feeding under
	var pk := Node2D.new()
	pk.set_script(load("res://entities/pigeon.gd"))
	m.add_child(pk)
	pk.global_position = Vector2(m.walk_edges(-2000.0).y - 30.0, -2000.0)
	pk.setup(m, m.dog, m.human, false)
	pk.make_parakeet(1.0)
	m.dog.global_position = pk.global_position + Vector2(40.0, 0.0)
	pk.scare()
	_check(pk.flying and pk.fly_dir.x > 0.0 and pk.fly_dir.y < 0.0, "a parakeet flies up over its own wall, even with the dog on that side")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mosaic_life: OK")
		quit(0)
	else:
		quit(1)
