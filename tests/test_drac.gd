extends SceneTree

const DT := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []

func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)

func _initialize() -> void:
	call_deferred("_run")

func _ticks(m: Node2D, secs: float) -> void:
	var n := int(secs / DT)
	for i in range(n):
		m.elapsed += DT
		m.drac.tick_state(DT)

func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "guell"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	var BD: GDScript = load("res://systems/boss_drac.gd")
	var G: GDScript = load("res://systems/goals.gd")
	_check(m.drac != null, "El Drac is built")
	_check(m.drac.state == BD.State.IDLE, "asleep on the fountain")
	_check(m.drac.leg_indices.size() == 4, "four legs on the rope")
	var ids: Array = G.LEVEL_GOAL_IDS["guell"]
	_check(ids.size() == 15, "15 goals: %d" % ids.size())
	_check(ids.has("drac_dodge") and ids.has("drac_column") and ids.has("drac_trip"), "boss goals listed")
	_check(not ids.has("drink") and not ids.has("hi") and not ids.has("tofu"), "drink/hi/tofu removed")
	var defs: Dictionary = G.defs(m)
	for id: String in ids:
		_check(defs.has(id), "goal %s is defined" % id)
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	var dr = m.drac
	m.human.global_position = Vector2(640.0, BD.HOLD_Y - 400.0)
	m.dog.global_position = Vector2(640.0, BD.HOLD_Y - 500.0)
	_ticks(m, 0.5)
	_check(dr.state == BD.State.IDLE, "still asleep with the pair past him")

	m.human.global_position = Vector2(640.0, BD.HOLD_Y + 120.0)
	m.dog.global_position = Vector2(640.0, BD.WAKE_Y - 30.0)
	_ticks(m, 0.1)
	_check(dr.state == BD.State.AWAKEN, "wakes as she passes")
	_check(m.human.tut_hold_y == BD.HOLD_Y, "your human is held short of him")
	_check(dr.awake_for_draw(), "boss owns the salamander draw")
	_ticks(m, BD.AWAKEN_TIME + 0.1)
	_check(dr.state == BD.State.PROWL, "down off the fountain and prowling")

	print("test_drac: %d checks, %d failures" % [checks, failures.size()])
	for f in failures:
		print("  " + f)
	quit(1 if failures.size() > 0 else 0)
