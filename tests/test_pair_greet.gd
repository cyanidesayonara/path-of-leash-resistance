extends SceneTree

# Your dog meeting another walker's dog nose to nose (main._greet_pair,
# otherpair.greet): the other dog stops and turns to sniff back, its owner
# waits for it and says something, then they walk on. A grumpy dog holds
# its tail still and its owner apologises.

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
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	for p in m.get_tree().get_nodes_in_group("pairs"):
		p.queue_free()
	await process_frame
	var pair := Node2D.new()
	pair.set_script(load("res://entities/otherpair.gd"))
	pair.set_physics_process(false)
	pair.setup(m, m.dog, m.poles, Vector2(640.0, -1000.0), Vector2(0.0, -1.0))
	root.add_child(pair)
	pair.set_physics_process(false)
	var no_blockers: Array[Dictionary] = []
	pair.configure_route(640.0, 340.0, 940.0, no_blockers)
	var dt := 1.0 / 60.0
	for i in range(30):
		pair._tick_walking(dt, false)
	# your dog comes up beside it
	m.dog.global_position = pair.npc_dog.position + Vector2(-20.0, 0.0)
	m._greetings()
	_check(pair.greet_t > 0.0, "meeting your dog stops the other dog to sniff back")
	var owner_at: Vector2 = pair.npc_owner.position
	var face_ok := false
	for i in range(int(pair.GREET_HOLD * 60.0) - 6):
		var was_d: Vector2 = pair.npc_dog.position
		var was_o: Vector2 = pair.npc_owner.position
		pair._tick_walking(dt, false)
		pair._update_pose(was_o, was_d, dt)
	face_ok = pair.dog_face.dot((m.dog.global_position - pair.npc_dog.position).normalized()) > 0.8
	_check(pair.npc_owner.position.distance_to(owner_at) < 1.0, "its owner waits while they sniff")
	_check(face_ok, "the other dog turns to your dog")
	for i in range(60):
		pair._tick_walking(dt, false)
	_check(pair.npc_owner.position.distance_to(owner_at) > 20.0, "then they walk on")
	m._greetings()
	_check(int(m.dogs_greeted) == 1, "one hello per dog")
	_check(pair.GRUMPY_P > 0.0 and pair.GRUMPY_P < 0.5, "some dogs, not most, are grumpy")
	pair.queue_free()
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_pair_greet: OK")
		quit(0)
	else:
		quit(1)
