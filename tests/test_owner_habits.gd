extends SceneTree

# Other walkers as people (entities/otherpair.gd, habit): the habits come in
# their shares and leave the dog's own dice alone; a phone owner stops dead to
# type and walks on; an owner with free eyes watches your dog go by while a
# phone owner does not; someone on a call says one line of it, once.

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


func _pair(m: Node2D, habit: String) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://entities/otherpair.gd"))
	pair.setup(m, m.dog, m.poles, Vector2(640.0, -1000.0), Vector2(0.0, -1.0))
	root.add_child(pair)
	pair.set_physics_process(false)
	pair.habit = habit
	pair.meet = "done"
	var no_blockers: Array[Dictionary] = []
	pair.configure_route(640.0, 340.0, 940.0, no_blockers)
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
	var script: GDScript = load("res://entities/otherpair.gd")

	var counts := {}
	for i in range(1000):
		var h: String = script._roll_habit((float(i) + 0.5) / 1000.0)
		counts[h] = int(counts.get(h, 0)) + 1
	for h: String in script.HABIT_SHARES:
		var share := float(counts.get(h, 0)) / 1000.0
		_check(absf(share - float(script.HABIT_SHARES[h])) < 0.01, "%s comes up its share (%.2f)" % [h, share])
		_check(h in HumanAppearance.HABITS, "%s is a habit the owner can be drawn with" % h)

	# the habit roll does not move the dog's own dice
	var a := _pair(m, "held")
	var replay := RandomNumberGenerator.new()
	replay.seed = int(a.seed_o * 100000.0) + 7
	_check(is_equal_approx(a.sniff_gap, replay.randf_range(1.0, a.SNIFF_GAP_MAX)), "the dog's first sniff is the roll it always was")
	_check(a.dog_name == a.NAMES[replay.randi() % a.NAMES.size()], "and so is its name")

	# a phone owner stops to type, then walks on
	m.dog.global_position = Vector2(2000.0, 2000.0)
	var p := _pair(m, "held")
	p.type_gap = 0.01
	p._tick_walking(dt, false)
	_check(p.type_t > 0.0, "a phone owner stops to type")
	_check(p._owner_pace() == 0.0, "and stands still while typing")
	var at: Vector2 = p.npc_owner.position
	for i in range(int(p.TYPE_T * 60.0) + 2):
		p._tick_walking(dt, false)
	_check(p.type_t <= 0.0 and p.type_gap >= p.TYPE_GAP_MIN, "typing ends and the next pause is a while off")
	for i in range(60):
		p._tick_walking(dt, false)
	_check(p.npc_owner.position.distance_to(at) > 20.0, "and they walk on")

	# free eyes watch your dog; a phone owner's do not
	var f := _pair(m, "free")
	var ph := _pair(m, "held")
	ph.type_gap = 999.0
	for pr: Node2D in [f, ph]:
		pr.sniff_t = 0.0
		pr.mark_t = 0.0
	m.dog.global_position = f.global_position + f.npc_owner.position + Vector2(150.0, 0.0)
	for i in range(60):
		f.sniff_t = 0.0
		f._tick_walking(dt, false)
	var to_dog: Vector2 = (m.dog.global_position - f.global_position - f.npc_owner.position).normalized()
	_check(f.look_dir.dot(to_dog) > 0.9, "an owner with free eyes looks at your dog")
	m.dog.global_position = ph.global_position + ph.npc_owner.position + Vector2(150.0, 0.0)
	for i in range(60):
		ph.sniff_t = 0.0
		ph._tick_walking(dt, false)
	_check(ph.look_dir.dot(ph.owner_face) > 0.9, "a phone owner keeps their eyes on the phone")

	# someone on a call says one line, once
	var c := _pair(m, "call")
	m.dog.global_position = c.global_position + c.npc_owner.position + Vector2(100.0, 0.0)
	c._tick_walking(dt, false)
	_check(c._said, "someone on a call says a line as you pass")
	var once: bool = c._said
	c._tick_walking(dt, false)
	_check(once and c._said, "and only the one")

	m.queue_free()
	if failures.is_empty():
		print("test_owner_habits: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_owner_habits: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
