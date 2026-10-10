extends SceneTree

# The tutorial's owner holds their ground at a lesson (human.tut_holding,
# main.TUT_BRACE): she can pull ahead as hard as she likes and they stay by
# the lesson, so the pair never overruns the tutorial into the dog park with
# lessons still to do. Once the lesson moves on, they walk on.

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
	game.level_id = "tutorial"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame

	# the swing lesson: a holding one, out by the lamppost
	var vi: int = m.TutorialSteps.index_of("vault")
	m.tut_step = vi
	var hp: Vector2 = m.tut_hold_point(vi)
	m.human.global_position = Vector2(640, hp.y + 5.0)
	m.dog.global_position = Vector2(640, hp.y - 120.0)
	m.leash.resnap()
	await physics_frame
	# she pulls on ahead, flat out, for six seconds
	Input.action_press("move_up")
	Input.action_press("turbo")
	for i in range(360):
		m.dog.energy = 1.0
		await physics_frame
	Input.action_release("move_up")
	Input.action_release("turbo")
	var past: float = hp.y - m.human.global_position.y
	_check(past < m.human.TUT_HOLD_SLACK + 25.0,
		"pulled flat out, your human stays by the lesson (%.0f px past their spot)" % past)
	_check(absf(past) < 60.0, "and is still by their spot (%.0f px off it)" % past)

	# the lesson skipped: they walk on to the next
	m.tut_step = vi + 1
	var y0: float = m.human.global_position.y
	for i in range(240):
		await physics_frame
	_check(m.human.global_position.y < y0 - 60.0, "with the lesson moved on, they walk on")

	m.free()
	print("test_tutorial_brace: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
