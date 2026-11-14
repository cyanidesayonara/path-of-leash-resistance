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

	# 9. The cheer counts only while the anxaneta crowns (walk clock, CastellCycle)
	var near_bark := stage_c + Vector2(0.0, 60.0)
	m.elapsed = 16.0 + 1.0    # climbing
	Gracia.on_bark(m, near_bark)
	_check(not m.gracia_aleta_cheered, "bark while the anxaneta climbs does not cheer")
	m.elapsed = 16.0 + 7.5    # descending
	Gracia.on_bark(m, near_bark)
	_check(not m.gracia_aleta_cheered, "bark on the way down does not cheer")
	var bones_before: int = m.bones
	m.elapsed = 16.0 + 5.0    # l'aleta
	Gracia.on_bark(m, near_bark)
	_check(m.gracia_aleta_cheered, "bark during l'aleta cheers")
	_check(m.bones == bones_before + 2, "aleta cheer awards 2 bones")
	Gracia.on_bark(m, near_bark)
	_check(m.bones == bones_before + 2, "aleta cheer does not pay twice")

	# 11. Scenery draw execution without errors
	var vt := stage.position.y - 100.0
	var vb := stage.end.y + 100.0
	Gracia.draw_scenery(m, m._wc, vt, vb)
	_check(true, "draw_scenery runs cleanly with dynamic castellers")

	m.queue_free()
	print("test_gracia_castellers: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
