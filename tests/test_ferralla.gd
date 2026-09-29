extends SceneTree

# La Ferralla is its own scrapyard (docs/LEVEL_DESIGN.md): a lane that shifts
# between stacks of wrecks (solid), oil pooled beside them, lasers that span
# the lane where it actually is, the bone prize beside a sleeping guard, and
# none of the boulevard's terrace, benches, crossings or drains.

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
	var game: Node = root.get_node("Game")
	game.level_id = "scrap"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.tables.is_empty() and m.benches.is_empty() and m.lane_ys.is_empty() and m.manholes.is_empty(),
		"no terrace, no benches, no crossings, no drains")
	var cxs := {}
	for y in [-1400.0, -2300.0, -3200.0]:
		var e: Vector2 = m.walk_edges(y)
		cxs[int((e.x + e.y) * 0.5)] = true
	_check(cxs.size() == 2, "the lane shifts from side to side and back")
	_check(m.vans.size() >= 8, "wreck stacks line the lane")
	# a wreck stack is solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var wv: Vector2 = m.vans[2]
	var side := 1.0 if wv.x < m.walk_edges(wv.y).x + 100.0 else -1.0
	dog.global_position = wv + Vector2(side * 70.0, 0.0)
	for i in range(40):
		dog.velocity = Vector2(-side * 500.0, 0.0)
		dog.move_and_slide()
	_check(absf(dog.global_position.x - wv.x) > 30.0, "a wreck stack stops the dog")
	# the oil is beside the stacks
	var oil := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "oil":
			oil += 1
	_check(oil >= 4, "oil pooled beside the stacks (%d)" % oil)
	# lasers span the lane where it is
	var spans := true
	for lz: Dictionary in m.lasers:
		var e2: Vector2 = m.walk_edges((float(lz.y_lo) + float(lz.y_hi)) * 0.5)
		spans = spans and absf(float(lz.x0) - e2.x) < 30.0 and absf(float(lz.x1) - e2.y) < 30.0
	_check(spans, "the lasers run across the lane where it is")
	_check(m.prize_pos.distance_to(m.guard_posts[1]) < 60.0, "the bone is right by a sleeping guard")
	_check(m.hydrants.size() >= 4, "enough tyre stacks to sniff")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_ferralla: OK")
		quit(0)
	else:
		quit(1)
