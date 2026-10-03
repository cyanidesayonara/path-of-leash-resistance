extends SceneTree

# Your human answers the leash (human.gd, the leash conversation): a steady
# pull leads them across the path and speeds or slows them along it; a hard
# one wears their patience down until a telegraphed "HEY!" and a correction (a
# step back and a shorter leash), which a dug-in dog turns into his stumble;
# a slack leash builds patience back; and they wait while she does her
# business.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _intent_after(h: CharacterBody2D, pull: Vector2, frames := 90) -> Vector2:
	var dt := 1.0 / 60.0
	h.felt_pull = Vector2.ZERO
	for i in range(frames):
		h._pull_now = pull
		h.felt_pull = h.felt_pull.lerp(pull, minf(h.PULL_EASE * dt, 1.0))
		h.velocity = Vector2.ZERO
		h.global_position = Vector2(640.0, -1500.0)
		h._walk(dt)
	return h.walk_intent


func _run() -> void:
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	var h: CharacterBody2D = m.human
	h.collision_mask = 0
	m.dog.collision_mask = 0
	h.state = h.HState.WALK
	h.wobble_seed = 0.0
	m.elapsed = 0.0
	# led: a steady pull to the right draws them right, up the path faster,
	# back down it slower
	var plain := _intent_after(h, Vector2.ZERO)
	var right := _intent_after(h, Vector2(h.GIVE_FULL, 0.0))
	_check(right.x > plain.x + 20.0, "a steady pull leads them across the path (%.0f vs %.0f)" % [right.x, plain.x])
	var ahead := _intent_after(h, Vector2(0.0, -h.GIVE_FULL))
	var back := _intent_after(h, Vector2(0.0, h.GIVE_FULL))
	_check(ahead.length() > plain.length() * 1.2, "pulled the way they are going, they walk quicker")
	_check(back.length() < plain.length() * 0.6, "pulled back, they slow and wait")
	# patience: hard hauling wears it down, slack builds it back
	h.patience = 1.0
	h.grace_t = 0.0
	h.correct_t = 0.0
	var dt := 1.0 / 60.0
	for i in range(60):
		h._pull_now = Vector2(0.0, 1.0) * (h.PATIENCE_HARD * 1.6)
		h.felt_pull = h._pull_now
		h.strain = true
		h._converse(dt)
	_check(h.patience < 0.9, "a hard pull wears their patience down (%.2f)" % h.patience)
	var low: float = h.patience
	for i in range(120):
		h.strain = false
		h._converse(dt)
	_check(h.patience > low, "a slack leash builds it back")
	# run it out: the "HEY!" is telegraphed first, then the correction
	h.patience = 0.01
	h.felt_pull = Vector2(0.0, 1.0) * (h.PATIENCE_HARD * 1.6)
	h._pull_now = h.felt_pull
	h.strain = true
	h._converse(dt)
	h._pull_now = h.felt_pull
	h._converse(dt)
	_check(h.is_correcting() and h.bubble.text == "HEY!", "out of patience: a telegraphed HEY! first")
	m.leash_len = 400.0
	m.leash_target = 400.0
	m.dog.planted = false
	m.dog.global_position = h.global_position + Vector2(0.0, -200.0)
	for i in range(int(h.CORRECT_WARN * 60.0) + 2):
		h._converse(dt)
	_check(not h.is_correcting(), "then the correction lands")
	_check(float(m.leash_target) < 300.0, "and the leash goes short (%.0f)" % float(m.leash_target))
	_check(h.patience >= h.CORRECT_REST - 0.01 and h.grace_t > 0.0, "patience resets, with a grace before it drains again")
	# dug in when it lands: his stumble, and a reward
	h.state = h.HState.WALK
	h.patience = 0.0
	h.grace_t = 0.0
	h.correct_t = 0.0
	var bones_before: int = m.bones
	h.felt_pull = Vector2(0.0, 1.0) * (h.PATIENCE_HARD * 1.6)
	h._pull_now = h.felt_pull
	h.strain = true
	h._converse(dt)
	m.dog.planted = true
	for i in range(int(h.CORRECT_WARN * 60.0) + 2):
		h._converse(dt)
	_check(h.state == h.HState.STUMBLE, "dug in when it lands: it is him that lurches")
	_check(int(m.bones) > bones_before, "and holding firm pays")
	# they wait while she does her business
	h.state = h.HState.WALK
	m.dog.planted = false
	m.dog.squat_t = 2.0
	h.waited = 0.0
	h.velocity = Vector2(0.0, -90.0)
	for i in range(30):
		h._walk(dt)
	_check(h.velocity.length() < 20.0, "they wait while she does her business")
	m.dog.squat_t = 0.0
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_leash_conversation: OK")
		quit(0)
	else:
		quit(1)
