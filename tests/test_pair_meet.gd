extends SceneTree

# Another walker's dog meeting yours (entities/otherpair.gd, meet): a friendly
# one comes over to her and stops nose to nose while its owner slows, and it
# is over once they have sniffed; a grumpy one first goes stiff for MEET_WARN
# (the telegraph), then lunges toward her barking every BARK_GAP, its owner
# stopped and reeling it in short, she is spooked if she is too near, and
# after LUNGE_MAX its owner walks on; once a walk each.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(60.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _pair(m: Node2D, grumpy: bool) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://entities/otherpair.gd"))
	pair.setup(m, m.dog, m.poles, Vector2(640.0, -1000.0), Vector2(0.0, -1.0))
	root.add_child(pair)
	pair.set_physics_process(false)
	pair.grumpy = grumpy
	var no_blockers: Array[Dictionary] = []
	pair.configure_route(640.0, 340.0, 940.0, no_blockers)
	for i in range(30):
		pair._tick_walking(1.0 / 60.0, false)
	return pair


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	for p in m.get_tree().get_nodes_in_group("pairs"):
		p.queue_free()
	await process_frame
	var dt := 1.0 / 60.0

	# a friendly dog
	var f := _pair(m, false)
	m.dog.global_position = f.npc_dog.position + Vector2(-110.0, 0.0)
	var gap0: float = m.dog.global_position.distance_to(f.npc_dog.position)
	var owner0: Vector2 = f.npc_owner.position
	for i in range(20):
		f._tick_walking(dt, false)
	_check(f.meet == "hello", "a friendly dog spots yours and comes over")
	_check(m.dog.global_position.distance_to(f.npc_dog.position) < gap0 - 10.0, "it closes the gap")
	var crawl: float = f.npc_owner.position.distance_to(owner0)
	_check(crawl < 20.0 * 70.0 / 60.0 * 0.5, "its owner slows to let it (%.1f px)" % crawl)
	for i in range(90):
		f._tick_walking(dt, false)
	_check(m.dog.global_position.distance_to(f.npc_dog.position) >= f.NOSE_R - 2.0, "it stops nose to nose, not on top of her")
	# she goes the rest of the way: it can only come as far as its leash
	m.dog.global_position = f.npc_dog.position + Vector2(-22.0, 0.0)
	m._greetings()
	for i in range(int(f.GREET_HOLD * 60.0) + 5):
		f._tick_walking(dt, false)
	_check(f.meet == "done", "the hello is over once they have sniffed")
	var at: Vector2 = f.npc_owner.position
	for i in range(60):
		f._tick_walking(dt, false)
	_check(f.npc_owner.position.distance_to(at) > 20.0, "and they walk on")
	f.queue_free()

	# a grumpy dog
	# she is well away while it settles into its walk
	m.dog.global_position = Vector2(640.0, 400.0)
	var g := _pair(m, true)
	m.dog.global_position = g.npc_dog.position + Vector2(-130.0, 0.0)
	var dog0: Vector2 = g.npc_dog.position
	var gowner0: Vector2 = g.npc_owner.position
	g._tick_walking(dt, false)
	_check(g.meet == "warn", "a grumpy dog goes stiff first")
	for i in range(int(g.MEET_WARN * 60.0) - 4):
		g._tick_walking(dt, false)
	_check(g.meet == "warn" and g.npc_dog.position.distance_to(dog0) < 2.0, "it holds still for the whole telegraph")
	for i in range(8):
		g._tick_walking(dt, false)
	_check(g.meet == "lunge", "then it lunges")
	var barks := 0
	var was := 0.0
	var reeled := false
	for i in range(int(2.0 * 60.0)):
		g._tick_walking(dt, false)
		if g.bark_flash > was:
			barks += 1
		was = g.bark_flash
		reeled = reeled or g.leash.rest_len <= g.LEASH_LEN * g.LUNGE_LEASH + 0.5
	_check(barks >= 3, "barking all the while (%d barks in 2 s)" % barks)
	_check(g.npc_owner.position.distance_to(gowner0) < 2.0, "its owner stops")
	_check(g.npc_dog.position.distance_to(m.dog.global_position) < 130.0 - 20.0, "it strains toward her")
	_check(reeled, "its owner reels it in short")
	m.dog.global_position = g.npc_dog.position + Vector2(-20.0, 0.0)
	g._tick_walking(dt, false)
	_check(g._scared, "too near a lunging dog, she gets a fright")
	for i in range(int(g.LUNGE_MAX * 60.0)):
		g._tick_walking(dt, false)
	_check(g.meet == "done", "after a while its owner hauls it off")
	var gat: Vector2 = g.npc_owner.position
	for i in range(60):
		g._tick_walking(dt, false)
	_check(g.npc_owner.position.distance_to(gat) > 20.0, "and walks on")
	m.dog.global_position = g.npc_dog.position + Vector2(-60.0, 0.0)
	g._tick_walking(dt, false)
	_check(g.meet == "done", "once a walk: it does not start again")

	if failures.is_empty():
		print("test_pair_meet: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_pair_meet: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
