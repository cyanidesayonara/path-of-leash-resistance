extends SceneTree

# main._apply_leash turns stretch into tug force through the leash's
# tension_force seam: a pull a few pixels past rest length eases in, rather
# than the full LEASH_K * excess the moment the rope goes taut.

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
	var d: CharacterBody2D = m.dog
	var h: CharacterBody2D = m.human
	d.collision_mask = 0
	h.collision_mask = 0
	# far from every pole, so the rope runs straight and unshielded
	var no_poles: Array[Vector2] = []
	d.global_position = Vector2(-20000, 0)
	# the rope ends at the hand, 16px up the screen from the owner
	h.rotation = 0.0
	h.global_position = d.global_position + Vector2(0, 16.0 - m.leash_len * 1.02)
	m.leash.setup(d, h, no_poles, m.leash_len)
	m.leash.resnap()
	d.planted = false
	d.input_active = false
	d.velocity = Vector2.ZERO
	h.velocity = Vector2.ZERO
	var dt := 1.0 / 60.0
	m._apply_leash(dt)
	var excess: float = m.leash.used_length() - m.leash_len
	var ratio: float = m.leash.used_length() / m.leash_len
	_check(ratio > 1.005 and ratio < 1.045,
		"fixture sits inside the onset band (ratio %.4f)" % ratio)
	_check(m.leash.static_contacts == 0, "fixture rope touches nothing")
	var seam: float = m.leash.tension_force(excess, m.LEASH_K)
	var binary: float = m.LEASH_K * excess
	var dv: float = d.velocity.length()
	var want: float = seam / m.DOG_MASS * dt
	print("tension wiring: ratio %.4f excess %.2fpx dog dv %.4f seam %.4f binary %.4f" % [
		ratio, excess, dv, want, binary / m.DOG_MASS * dt])
	_check(absf(dv - want) <= want * 0.02 + 0.0001,
		"the dog is pulled by tension_force (dv %.4f, seam %.4f)" % [dv, want])
	_check(dv < binary / m.DOG_MASS * dt * 0.8,
		"the binary LEASH_K * excess force is gone inside the onset band")
	_check(d.velocity.dot(Vector2.UP) > 0.0, "and towards the human")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_leash_tension_wiring: OK")
		quit(0)
	else:
		quit(1)
