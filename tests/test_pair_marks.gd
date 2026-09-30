extends SceneTree

# Other people's dogs sniff and mark like dogs (entities/otherpair.gd): a
# sniff stop goes to a post coming up by the dog's line, the dog stops there
# nose down, often lifts a leg, and leaves a mark your dog can read; never
# more than MARKS_MAX a walk, and a dog towed off its post gives up on it.

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
	m.npc_marks.clear()
	m.hydrants.clear()
	m.trees.clear()
	m.poles.clear()
	m.deco_pole_count = 0
	# one hydrant up ahead, just off the pair's line
	var post := Vector2(700.0, -1110.0)
	m.hydrants.append({"pos": post, "done": false, "progress": 0.0})
	var pair := Node2D.new()
	pair.set_script(load("res://entities/otherpair.gd"))
	pair.set_physics_process(false)
	pair.setup(m, m.dog, m.poles, Vector2(640.0, -1000.0), Vector2(0.0, -1.0))
	root.add_child(pair)
	pair.set_physics_process(false)
	var no_blockers: Array[Dictionary] = []
	pair.configure_route(640.0, 340.0, 940.0, no_blockers)
	pair.marks_left = 2
	pair.sniff_gap = 0.0
	# rig the dice so this sniff gets a reply
	var picked: Vector2 = pair._pick_spot()
	_check(picked.x < INF and picked.distance_to(post) < 20.0, "a sniff stop goes to the post up ahead")
	var dt := 1.0 / 60.0
	var reached := false
	var marked := false
	var max_span := 0.0
	for i in range(420):
		if pair.at_spot and pair.sniff_t > 0.0 and not reached:
			reached = true
			pair.life_rng.seed = 1
		pair._tick_walking(dt, false)
		max_span = maxf(max_span, pair.npc_dog.position.distance_to(pair.npc_owner.position))
		if not m.npc_marks.is_empty():
			marked = true
			break
	_check(reached, "the dog gets to the post and sniffs it")
	_check(max_span <= pair.LEASH_CAP + 0.5, "and never outside its leash")
	if not marked:
		# the dice said no: still a sniff, no mark. Force the reply to check it.
		pair.sniff_spot = picked
		pair.mark_t = 0.01
		pair._tick_walking(dt, false)
		marked = not m.npc_marks.is_empty()
	_check(marked, "a reply at the post leaves a mark")
	if marked:
		var nm: Dictionary = m.npc_marks[0]
		_check(Vector2(nm["pos"]).distance_to(post) < 30.0, "the mark is at the post")
		_check(String(nm["who"]) == pair.dog_name, "the mark says who left it")
	_check(pair._pick_spot().x == INF, "a marked post is not picked again")
	# at most MARKS_MAX a walk
	pair.marks_left = 0
	pair.sniff_spot = picked
	pair.at_spot = true
	pair.sniff_t = 0.01
	var n: int = m.npc_marks.size()
	for i in range(3):
		pair._tick_walking(dt, false)
	_check(m.npc_marks.size() == n and pair.mark_t <= 0.0, "no more marks once it has used its allowance")
	# towed off a post: gives up on it
	pair.sniff_spot = pair.npc_owner.position + Vector2(0.0, 400.0)
	pair.at_spot = true
	pair.sniff_t = 5.0
	pair.npc_dog.position = pair.npc_owner.position + Vector2(0.0, 300.0)
	pair._tick_walking(dt, false)
	_check(pair.sniff_spot.x == INF and pair.sniff_t == 0.0, "towed off its post, the dog gives up on it")
	pair.queue_free()
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_pair_marks: OK")
		quit(0)
	else:
		quit(1)
