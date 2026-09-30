extends SceneTree

# The owner's retractable reel (entities/human.gd, main._tick_reel_length).
# Like every owner event it is telegraphed: the "click!" comes first and the
# new length REEL_WARN later, never on the same frame. And a reel winds in
# slack only: a click that shortens the leash against a taut rope holds
# rather than dragging the dog, while the owner's deliberate haul (the nag)
# does pull a taut rope in, also after its warning.

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
	var h: CharacterBody2D = m.human
	var dt := 1.0 / 60.0

	# the click is said before it happens
	h.telegraph_t = 0.0
	h.reel_timer = 0.0
	var before: float = m.leash_target
	h._fiddle_with_reel(dt)
	_check(h.bubble.visible and h.bubble.text == "click!", "the reel says click! first")
	_check(is_equal_approx(m.leash_target, before), "and the length does not change on that frame")
	var t := 0.0
	var changed_at := -1.0
	while t < 1.5:
		h._fiddle_with_reel(dt)
		t += dt
		if changed_at < 0.0 and not is_equal_approx(m.leash_target, before):
			changed_at = t
	_check(changed_at >= h.REEL_WARN - dt * 1.5, "the new length lands at least the warning later (%.2f s)" % changed_at)

	# a click that shortens a taut leash holds instead of dragging the dog
	var hp: Vector2 = h.global_position
	m.dog.global_position = hp + Vector2(0, -420.0)
	m.leash_len = 400.0
	m.leash.rest_len = 400.0
	m.leash.resnap()
	var used: float = m.leash.used_length()
	m.set_leash_target(170.0)
	for i in range(60):
		m._tick_reel_length(dt)
	_check(m.leash_len >= minf(400.0, used) - 0.5, "a click never reels in a taut leash (%.0f, rope %.0f)" % [m.leash_len, used])

	# with slack it winds in, down to what is actually out
	m.dog.global_position = hp + Vector2(0, -200.0)
	m.leash.resnap()
	for i in range(120):
		m._tick_reel_length(dt)
	_check(m.leash_len < 390.0, "with slack the reel winds in (%.0f)" % m.leash_len)

	# the nag hauls a taut rope in
	m.dog.global_position = hp + Vector2(0, -420.0)
	m.leash_len = 400.0
	m.leash.rest_len = 400.0
	m.leash.resnap()
	m.set_leash_target(180.0, true)
	for i in range(60):
		m._tick_reel_length(dt)
	_check(m.leash_len < 360.0, "the owner's deliberate haul does pull a taut leash in (%.0f)" % m.leash_len)

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_reel: OK")
		quit(0)
	else:
		quit(1)
