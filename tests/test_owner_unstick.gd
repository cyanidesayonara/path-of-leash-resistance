extends SceneTree

# Your human does not get stuck (main.round_pole_dir, human._check_stuck):
#  1. pulled toward a pole the rope is over beside them, the part of the pull
#     aimed into the pole becomes a step round it; a pull away from the pole,
#     or a pole further off, is left alone
#  2. walking into a wide box across the path, they sidestep round it and
#     carry on, instead of pressing against it for ever
#  3. with nothing in the way they never sidestep

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
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame

	# 1) round the pole, not into it
	var hp: Vector2 = m.human.global_position
	m.leash.static_contacts = 1
	m.leash.human_contact_is_pole = true
	m.leash.human_contact_pole = hp + Vector2(24, 0)
	var into: Vector2 = m.round_pole_dir(Vector2(1, 0))
	_check(absf(into.length() - 1.0) < 0.001, "the redirected pull is still a direction")
	_check(into.dot(Vector2(1, 0)) < 0.01, "a pull into the pole becomes a step round it (%s)" % into)
	var away: Vector2 = m.round_pole_dir(Vector2(-1, 0))
	_check(away.is_equal_approx(Vector2(-1, 0)), "a pull away from the pole is left alone")
	var slant := Vector2(1, 1).normalized()
	var slanted: Vector2 = m.round_pole_dir(slant)
	_check(slanted.dot(Vector2(1, 0)) < 0.01 and slanted.y != 0.0, "a slanting pull keeps going round, never into it")
	m.leash.human_contact_pole = hp + Vector2(120, 0)
	_check(m.round_pole_dir(Vector2(1, 0)).is_equal_approx(Vector2(1, 0)), "a pole further off is left alone")
	m.leash.human_contact_is_pole = false
	m.leash.human_contact_pole = hp + Vector2(24, 0)
	_check(m.round_pole_dir(Vector2(1, 0)).is_equal_approx(Vector2(1, 0)), "furniture is not a pole to step round")
	m.leash.static_contacts = 0

	# 3) nothing in the way: no sidestep (sampled first, before the box)
	var side0 := false
	for i in range(120):
		m.dog.global_position = m.human.global_position + Vector2(20, -10)
		m.dog.velocity = Vector2.ZERO
		await physics_frame
		if m.human.sidestep_t > 0.0:
			side0 = true
	_check(not side0, "with nothing in the way they never sidestep")

	# 2) a wide box straight across their path
	var y0: float = m.human.global_position.y
	var box := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(150, 30)
	cs.shape = rs
	box.add_child(cs)
	m.add_child(box)
	box.global_position = Vector2(m.human.global_position.x, y0 - 60.0)
	var sidestepped := false
	for i in range(420):
		m.dog.global_position = m.human.global_position + Vector2(20, -10)
		m.dog.velocity = Vector2.ZERO
		await physics_frame
		if m.human.sidestep_t > 0.0:
			sidestepped = true
	_check(sidestepped, "walking into the box, they sidestep")
	_check(m.human.global_position.y < y0 - 110.0,
		"and get past it (%.0f px on, the box's far side is 75 px on)" % (y0 - m.human.global_position.y))
	box.queue_free()

	m.free()
	print("test_owner_unstick: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
