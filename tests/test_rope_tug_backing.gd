extends SceneTree

# In the rope tug (systems/freedom_games.gd) Millie faces the other dog along
# the rope the whole time, so pushing the stick away from it backs her up,
# rump first, her stride running in reverse; she does not turn round and run.
# When the tug ends the stick turns her again.

const WARMUP := 6
const FRAMES := 40
# facing within about 18 degrees of the toy
const FACE_DOT := 0.95

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
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 300.0)
	m.human.global_position = Vector2(640.0, m.GATE_Y - 60.0)
	m.leash.resnap()
	m._enter_freedom()
	await physics_frame
	var fd: Node2D = m.tug_dog
	_check(fd != null and fd.rope, "one free dog has the rope")
	if fd == null:
		_finish(m)
		return
	# the other dog to her left with the rope, Millie at its free end.
	# the park around them is still live: a trunk lands somewhere new each
	# run, and a ball brought back clears her mouth
	_isolate_tug(m, fd)
	fd.global_position = Vector2(560.0, m.GATE_Y - 250.0)
	fd.face = Vector2.RIGHT
	m.dog.facing = Vector2.LEFT
	m.dog.global_position = fd.rope_end() - m.dog.facing * 22.0
	m.freedom_games_tick(1.0 / 60.0)
	_check(m.tug != null, "taking the rope's end starts a tug")
	# pull: push away from the other dog (to the right)
	Input.action_press("move_right")
	var faced := 0
	var backed := 0
	var counted := 0
	var gait_was: float = m.dog.gait
	for i in range(WARMUP + FRAMES):
		await physics_frame
		if m.tug == null:
			break
		if i < WARMUP:
			gait_was = m.dog.gait
			continue
		counted += 1
		var to_toy: Vector2 = (fd.global_position - m.dog.global_position).normalized()
		if m.dog.facing.dot(to_toy) > FACE_DOT:
			faced += 1
		var v: Vector2 = m.dog.velocity
		if v.length() > 10.0 and v.normalized().dot(to_toy) < -0.5:
			backed += 1
	_check(counted > 0, "the tug lasts long enough to watch")
	_check(faced == counted, "pulling, she faces the toy every frame (%d/%d)" % [faced, counted])
	_check(backed == counted, "pulling, she moves away from it every frame (%d/%d)" % [backed, counted])
	_check(m.dog.gait < gait_was, "backing up, her stride runs in reverse")
	_check(m.dog.brace > 0.5, "she braces against the pull")
	Input.action_release("move_right")
	# end it: the stick turns her again
	if m.tug != null:
		load("res://systems/freedom_games.gd")._end_tug(m, "draw")
	_check(m.dog.face_lock == Vector2.ZERO, "the tug over, nothing holds her facing")
	# well clear of the rope, so she does not take it up again at once
	m.dog.global_position = fd.global_position + Vector2(200.0, 0.0)
	Input.action_press("move_down")
	for i in range(4):
		await physics_frame
	Input.action_release("move_down")
	_check(m.dog.facing.dot(Vector2.DOWN) > 0.9, "after the tug the stick turns her again")
	_finish(m)


# The grove, the logs and the balls are part of the live park, and none of
# them is the tug. Trunks are placed with the unseeded roll, so a run that
# clips one stops her for a few frames; a ball returned to its thrower clears
# dog_carrying. Park that scenery out of the tug.
func _isolate_tug(m: Node2D, fd: Node2D) -> void:
	m.tug = null
	m.dog_carrying = false
	m.dog.face_lock = Vector2.ZERO
	m.rope_carry_t = 0.0
	_park_toy(m.ball)
	_park_toy(m.npc_ball)
	if is_instance_valid(m.frisbee):
		m.frisbee.queue_free()
		m.frisbee = null
	var spot := Vector2(90.0, m.freedom_lo + 24.0)
	for other in m.get_tree().get_nodes_in_group("freedogs"):
		if other == fd:
			continue
		var od := other as Node2D
		od.global_position = spot
		od.set_physics_process(false)
		spot.x += 36.0
	if is_instance_valid(m.rival):
		m.rival.set_physics_process(false)
		m.rival.global_position = Vector2(90.0, m.GATE_Y - 36.0)
	var box := Rect2(Vector2(120.0, m.GATE_Y - 520.0), Vector2(1080.0, 460.0)).grow(40.0)
	for child in m.get_children():
		if child is StaticBody2D and box.has_point((child as Node2D).global_position):
			(child as Node2D).global_position = Vector2(-400.0, m.GATE_Y)


func _park_toy(toy: Node) -> void:
	if not is_instance_valid(toy):
		return
	var body := toy as Node2D
	body.set_physics_process(false)
	if body.get("state") != null:
		body.state = body.State.RESTING
	body.global_position = Vector2(-400.0, 0.0)


func _finish(m: Node2D) -> void:
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_rope_tug_backing: OK")
		quit(0)
	else:
		quit(1)
