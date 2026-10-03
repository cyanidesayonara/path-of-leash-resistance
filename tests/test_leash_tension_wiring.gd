extends SceneTree

# main._apply_leash eases the whole tug in through the leash's taut amount: a
# pull a few pixels past rest length gets a fraction of the spring force, a
# fraction of the separation damping, and only partly takes the dog's control
# away, rather than all of it the moment the rope goes taut.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# dog and owner far from every pole, the rope 2% past rest length; returns the
# rope's stretch ratio after main has pulled
func _pull(m: Node2D, dog_v: Vector2, human_v: Vector2) -> float:
	var d: CharacterBody2D = m.dog
	var h: CharacterBody2D = m.human
	d.global_position = Vector2(-20000, 0)
	# the rope ends at the hand, 16px up the screen from the owner
	h.rotation = 0.0
	h.global_position = d.global_position + Vector2(0, 16.0 - m.leash_len * 1.02)
	m.leash.rest_len = m.leash_len
	m.leash.resnap()
	d.planted = false
	d.input_active = false
	d.velocity = dog_v
	h.velocity = human_v
	m._apply_leash(1.0 / 60.0)
	return m.leash.used_length() / m.leash_len


# how much speed the dog sheds in one idle frame on a taut leash
func _idle_brake(d: CharacterBody2D, amount: float) -> float:
	d.global_position = Vector2(-20000, 0)
	d.auto = true
	d.auto_move = Vector2.ZERO
	d.planted = false
	d.slick = false
	d.ice = false
	d.mood_accel = 1.0
	d.mood_speed = 1.0
	d.velocity = Vector2(300, 0)
	d.dragged = true
	d.drag_amt = amount
	d.tick(1.0 / 60.0)
	return 300.0 - d.velocity.length()


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
	var dt := 1.0 / 60.0

	# 1) the spring force goes through tension_force
	var ratio := _pull(m, Vector2.ZERO, Vector2.ZERO)
	var excess: float = m.leash.used_length() - m.leash_len
	var amount: float = m.leash.taut_amount(ratio)
	_check(ratio > 1.005 and ratio < 1.045,
		"fixture sits inside the onset band (ratio %.4f)" % ratio)
	_check(m.leash.static_contacts == 0, "fixture rope touches nothing")
	var seam: float = m.leash.tension_force(excess, m.LEASH_K)
	var binary: float = m.LEASH_K * excess
	var dv: float = d.velocity.length()
	var want: float = seam / m.DOG_MASS * dt
	print("tension wiring: ratio %.4f amount %.3f excess %.2fpx dog dv %.4f seam %.4f binary %.4f" % [
		ratio, amount, excess, dv, want, binary / m.DOG_MASS * dt])
	_check(absf(dv - want) <= want * 0.02 + 0.0001,
		"the dog is pulled by tension_force (dv %.4f, seam %.4f)" % [dv, want])
	_check(dv < binary / m.DOG_MASS * dt * 0.8,
		"the binary LEASH_K * excess force is gone inside the onset band")
	_check(d.velocity.dot(Vector2.UP) > 0.0, "and towards the human")

	# 2) the dog is marked dragged, but only as hard as the leash has her
	_check(d.dragged, "a taut leash still marks the dog dragged")
	_check(absf(d.drag_amt - amount) < 0.0001,
		"the dog's drag amount is the leash's taut amount (%.3f vs %.3f)" % [d.drag_amt, amount])
	_check(d.drag_amt < 0.9, "2%% stretch does not take her control away fully (%.3f)" % d.drag_amt)

	# 3) both ends moving apart: separation damping eases in with the force
	ratio = _pull(m, Vector2(0, 100), Vector2(0, -100))
	excess = m.leash.used_length() - m.leash_len
	amount = m.leash.taut_amount(ratio)
	var force: float = m.leash.tension_force(excess, m.LEASH_K)
	var d_dir: Vector2 = m.leash.dog_pull_dir()
	var h_dir: Vector2 = m.leash.human_pull_dir()
	var dog_along: float = Vector2(0, 100).dot(d_dir) + force / m.DOG_MASS * dt
	var dog_want: float = dog_along + maxf(-dog_along, 0.0) * minf(3.0 * dt, 1.0) * amount
	var lunge: float = m.mood.pull_mult() if m.mood != null else 1.0
	var human_along: float = Vector2(0, -100).dot(h_dir) + force * lunge / m.HUMAN_MASS * dt
	var human_want: float = human_along + maxf(-human_along, 0.0) * minf(5.0 * dt, 1.0) * amount
	print("separation: amount %.3f dog %.4f want %.4f human %.4f want %.4f" % [
		amount, d.velocity.dot(d_dir), dog_want, h.velocity.dot(h_dir), human_want])
	_check(absf(d.velocity.dot(d_dir) - dog_want) < 0.01,
		"the dog's separation damping scales with the taut amount (%.4f vs %.4f)" % [
			d.velocity.dot(d_dir), dog_want])
	_check(absf(h.velocity.dot(h_dir) - human_want) < 0.01,
		"the owner's separation damping scales with the taut amount (%.4f vs %.4f)" % [
			h.velocity.dot(h_dir), human_want])

	# 4) dog.tick turns the drag amount into continuous control authority
	var free_brake := _idle_brake(d, 0.0)
	var half_brake := _idle_brake(d, 0.5)
	var full_brake := _idle_brake(d, 1.0)
	print("idle brake per frame: amount 0 %.3f, 0.5 %.3f, 1 %.3f" % [free_brake, half_brake, full_brake])
	_check(free_brake > half_brake and half_brake > full_brake,
		"an idle dog brakes less the harder the leash has her (%.3f, %.3f, %.3f)" % [
			free_brake, half_brake, full_brake])
	_check(full_brake > 0.0, "and still brakes a little when fully dragged")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_leash_tension_wiring: OK")
		quit(0)
	else:
		quit(1)
