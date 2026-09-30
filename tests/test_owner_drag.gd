extends SceneTree

# An owner hauled along by the leash is drawn being dragged (entities/human.gd
# _track_drag): braced, leaning back, reaching along the leash. It must come
# on only when the leash is taut AND they are moving somewhere other than
# where they are walking, and go again once they are walking on their own.

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
	var h: CharacterBody2D = m.human
	var dt := 1.0 / 60.0
	# walking where they mean to, leash slack: not dragged
	for i in range(60):
		h.walk_intent = Vector2(0, -90)
		h.velocity = Vector2(0, -90)
		h.strain = false
		h._track_drag(dt)
	_check(h.drag_amt < 0.01, "walking on their own is not being dragged")
	# walking one way, hauled another on a taut leash: dragged
	for i in range(60):
		h.walk_intent = Vector2(0, -90)
		h.velocity = Vector2(120, 20)
		h.strain = true
		h._track_drag(dt)
	_check(h.drag_amt > 0.99, "hauled sideways on a taut leash is being dragged (%.2f)" % h.drag_amt)
	_check(h.drag_dir.dot(Vector2(1, 0.9).normalized()) > 0.8, "and they face the pull")
	# a taut leash that happens to go where they are walking is not a drag
	for i in range(60):
		h.walk_intent = Vector2(0, -90)
		h.velocity = Vector2(0, -100)
		h.strain = true
		h._track_drag(dt)
	_check(h.drag_amt < 0.01, "a taut leash going their way is not a drag")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_owner_drag: OK")
		quit(0)
	else:
		quit(1)
