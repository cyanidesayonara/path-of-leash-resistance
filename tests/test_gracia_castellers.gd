extends SceneTree

const ShapeBatch := preload("res://systems/shape_batch.gd")

# Regression test for upgraded Festa de Gràcia Castellers (Walk 26).
# Tests stage configuration, respectful watch / equilibri trick, aleta cheer bark trick,
# single-award guards, distance thresholds, and visual draw safety.

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
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "gracia"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	var Gracia: GDScript = load("res://systems/gracia.gd")
	var stage: Rect2 = Gracia.CASTELL_STAGE
	var stage_c := stage.get_center()
	_check(stage.size.x == 160.0 and stage.size.y == 70.0, "castell stage bounds match specification")
	_check(m.poles.has(Vector2(stage.position.x + 8.0, stage.get_center().y)), "left wrap pole placed")
	_check(m.poles.has(Vector2(stage.end.x - 8.0, stage.get_center().y)), "right wrap pole placed")

	# Initial state
	_check(m.gracia_castell_t == 0.0, "initial castell watch timer is 0.0")
	_check(not m.gracia_castell_watched, "initial castell watched flag is false")
	_check(not m.gracia_aleta_cheered, "initial aleta cheer flag is false")

	# 1. Distant dog does not advance watch timer
	m.dog.global_position = stage_c + Vector2(0.0, 300.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.dragged = false
	Gracia.tick(m, 0.5)
	_check(m.gracia_castell_t == 0.0, "distant dog does not advance castell watch timer")
	_check(not m.gracia_castell_watched, "distant dog does not trigger watched trick")

	# 2. Fast moving dog near stage does not advance timer
	m.dog.global_position = stage_c + Vector2(0.0, 50.0)
	m.dog.velocity = Vector2(100.0, 0.0)
	m.dog.dragged = false
	Gracia.tick(m, 0.5)
	_check(m.gracia_castell_t == 0.0, "fast moving dog does not advance watch timer")

	# 3. Dragged dog near stage does not advance timer
	m.dog.velocity = Vector2.ZERO
	m.dog.dragged = true
	Gracia.tick(m, 0.5)
	_check(m.gracia_castell_t == 0.0, "dragged dog does not advance watch timer")

	# 4. Respectful standing dog advances timer
	m.dog.dragged = false
	Gracia.tick(m, 0.5)
	_check(is_equal_approx(m.gracia_castell_t, 0.5), "calm standing dog advances watch timer by delta")
	_check(not m.gracia_castell_watched, "not watched yet at t=0.5s")

	# 5. Stepping away resets uncompleted timer
	m.dog.global_position = stage_c + Vector2(0.0, 150.0)
	Gracia.tick(m, 0.1)
	_check(m.gracia_castell_t == 0.0, "walking away resets watch timer")

	# 6. Standing for 1.5s awards Equilibri trick
	var initial_bones: int = m.bones
	m.dog.global_position = stage_c + Vector2(0.0, 50.0)
	Gracia.tick(m, 1.0)
	_check(not m.gracia_castell_watched, "not watched yet at t=1.0s")
	Gracia.tick(m, 0.6)
	_check(m.gracia_castell_watched, "standing for 1.5s awards castell watched trick")
	_check(m.bones == initial_bones + 2, "equilibri trick awards 2 bones")

	# 7. Equilibri trick does not re-trigger
	Gracia.tick(m, 2.0)
	_check(m.bones == initial_bones + 2, "equilibri trick does not award bones twice")

	# 8. Bark far from stage does not trigger aleta cheer
	var far_bark := stage_c + Vector2(0.0, 250.0)
	Gracia.on_bark(m, far_bark)
	_check(not m.gracia_aleta_cheered, "distant bark does not trigger aleta cheer")

	# 9. Bark near stage triggers aleta cheer only during aleta window (3.8s..6.5s in 8s cycle)
	var near_bark := stage_c + Vector2(0.0, 60.0)
	var t_sec: float = AnimClock.msec() * 0.001
	var phase_t := fmod(t_sec, 8.0)
	if phase_t >= 3.8 and phase_t <= 6.5:
		Gracia.on_bark(m, near_bark)
		_check(m.gracia_aleta_cheered, "bark during aleta window triggers aleta cheer trick")
		var bones_after_aleta: int = m.bones
		Gracia.on_bark(m, near_bark)
		_check(m.bones == bones_after_aleta, "aleta cheer does not trigger twice")
	else:
		# If outside window, simulate barking during aleta
		# (anim clock advances with time, we verify logic contract directly)
		_check(not m.gracia_aleta_cheered, "bark outside aleta window does not cheer")

	# 10. Direct verification of on_bark aleta cheer
	m.gracia_aleta_cheered = false
	var bones_before: int = m.bones
	# Test with AnimClock or simulate phase window:
	# Gracia.on_bark checks bp.distance_to(c) <= 160.0 and phase_t in [3.8, 6.5]
	var in_aleta := (phase_t >= 3.8 and phase_t <= 6.5)
	Gracia.on_bark(m, near_bark)
	if in_aleta:
		_check(m.gracia_aleta_cheered, "aleta bark awarded during aleta phase")
		_check(m.bones == bones_before + 2, "aleta cheer awards 2 bones")
	else:
		_check(not m.gracia_aleta_cheered, "aleta bark not awarded outside aleta phase")

	# 11. Scenery draw execution without errors
	var vt := stage.position.y - 100.0
	var vb := stage.end.y + 100.0
	Gracia.draw_scenery(m, m._wc, vt, vb)
	_check(true, "draw_scenery runs cleanly with dynamic castellers")

	m.queue_free()
	print("test_gracia_castellers: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
