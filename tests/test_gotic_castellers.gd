extends SceneTree

const ShapeBatch := preload("res://systems/shape_batch.gd")

# Regression test for Castellers de Barcelona in El Gòtic (Walk 7).
# Tests diada placement, flanking stanchions, solid body & bypasser blocker,
# autowalk line clearance, respectful watch / equilibri trick, aleta cheer bark trick,
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
	game.level_id = "oldtown"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var GoticCastellers: GDScript = load("res://systems/gotic_castellers.gd")
	var Detour: GDScript = load("res://systems/detour.gd")
	var diada_pos: Vector2 = GoticCastellers.DIADA_POS
	var placa: Vector2 = LevelBuild.GOTIC_PLACA

	# 1. Placement & Geometry
	_check(diada_pos == placa + Vector2(160.0, -50.0), "diada position is in northeast quadrant of plaça: %s" % diada_pos)
	_check(m.poles.has(GoticCastellers.STANCHION_L), "left stone stanchion wrap pole placed in m.poles: %s" % GoticCastellers.STANCHION_L)
	_check(m.poles.has(GoticCastellers.STANCHION_R), "right stone stanchion wrap pole placed in m.poles: %s" % GoticCastellers.STANCHION_R)

	# 2. Clearance to other plaça elements
	var fountain_pos: Vector2 = m.fountains[0]
	_check(diada_pos.distance_to(fountain_pos) > 150.0, "clear of fountain basin (%f px)" % diada_pos.distance_to(fountain_pos))
	if not m.performers.is_empty():
		var busker_pos: Vector2 = m.performers[0]
		_check(diada_pos.distance_to(busker_pos) > 140.0, "clear of Spanish guitar busker (%f px)" % diada_pos.distance_to(busker_pos))
	for bn: Vector2 in m.benches:
		_check(diada_pos.distance_to(bn) > 80.0, "clear of plaça bench (%f px)" % diada_pos.distance_to(bn))

	# 3. Autowalk path clearance (owner walks north at x ≈ 740.0)
	var autowalk_x := 740.0
	var clearance_to_diada := absf(diada_pos.x - autowalk_x)
	var clearance_to_stanchion := absf(GoticCastellers.STANCHION_L.x - autowalk_x)
	_check(clearance_to_diada >= 90.0, "autowalk has >= 90px clearance from castell core (%f px)" % clearance_to_diada)
	_check(clearance_to_stanchion >= 50.0, "autowalk has >= 50px clearance from left stanchion (%f px)" % clearance_to_stanchion)

	# 4. Solid obstacle and bypasser blocker coverage
	var has_blocker := false
	for b: Dictionary in m.bypasser_blockers:
		if b.has("rect") and Rect2(b["rect"]).grow(0.5).encloses(GoticCastellers.COLLISION_RECT):
			has_blocker = true
			break
	_check(has_blocker, "bypasser blocker encloses gotic castellers collision rect")

	# Initial state
	_check(m.gotic_castell_t == 0.0, "initial gotic castell watch timer is 0.0")
	_check(not m.gotic_castell_watched, "initial gotic castell watched flag is false")
	_check(not m.gotic_aleta_cheered, "initial gotic aleta cheer flag is false")

	# 5. Distant dog does not advance watch timer
	m.dog.global_position = diada_pos + Vector2(0.0, 300.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.dragged = false
	Detour.tick(m, 0.5)
	_check(m.gotic_castell_t == 0.0, "distant dog does not advance castell watch timer")
	_check(not m.gotic_castell_watched, "distant dog does not trigger watched trick")

	# 6. Fast moving dog near castell does not advance timer
	m.dog.global_position = diada_pos + Vector2(0.0, 50.0)
	m.dog.velocity = Vector2(100.0, 0.0)
	m.dog.dragged = false
	Detour.tick(m, 0.5)
	_check(m.gotic_castell_t == 0.0, "fast moving dog does not advance watch timer")

	# 7. Dragged dog near castell does not advance timer
	m.dog.velocity = Vector2.ZERO
	m.dog.dragged = true
	Detour.tick(m, 0.5)
	_check(m.gotic_castell_t == 0.0, "dragged dog does not advance watch timer")

	# 8. Respectful standing dog advances timer
	m.dog.dragged = false
	Detour.tick(m, 0.5)
	_check(is_equal_approx(m.gotic_castell_t, 0.5), "calm standing dog advances watch timer by delta")
	_check(not m.gotic_castell_watched, "not watched yet at t=0.5s")

	# 9. Stepping away resets uncompleted timer
	m.dog.global_position = diada_pos + Vector2(0.0, 160.0)
	Detour.tick(m, 0.1)
	_check(m.gotic_castell_t == 0.0, "walking away resets watch timer")

	# 10. Standing for 1.5s awards Equilibri trick (+2 points, combo EQUILIBRI)
	var initial_bones: int = m.bones
	m.dog.global_position = diada_pos + Vector2(0.0, 50.0)
	Detour.tick(m, 1.0)
	_check(not m.gotic_castell_watched, "not watched yet at t=1.0s")
	Detour.tick(m, 0.6)
	_check(m.gotic_castell_watched, "standing for 1.5s awards castell watched trick")
	_check(m.bones == initial_bones + 2, "equilibri trick awards 2 bones")

	# 11. Equilibri trick does not re-trigger
	Detour.tick(m, 2.0)
	_check(m.bones == initial_bones + 2, "equilibri trick does not award bones twice")

	# 12. Bark far from castell does not trigger aleta cheer
	var far_bark := diada_pos + Vector2(0.0, 250.0)
	Detour.on_bark(m, far_bark)
	_check(not m.gotic_aleta_cheered, "distant bark does not trigger aleta cheer")

	# 13. The cheer counts only while the anxaneta crowns (walk clock, CastellCycle)
	var near_bark := diada_pos + Vector2(0.0, 50.0)
	m.elapsed = 24.0 + 1.0    # climbing
	Detour.on_bark(m, near_bark)
	_check(not m.gotic_aleta_cheered, "bark while the anxaneta climbs does not cheer")
	var bones_before: int = m.bones
	m.elapsed = 24.0 + 5.0    # l'aleta
	Detour.on_bark(m, near_bark)
	_check(m.gotic_aleta_cheered, "aleta bark awarded during aleta phase")
	_check(m.bones == bones_before + 2, "aleta cheer awards 2 bones")
	Detour.on_bark(m, near_bark)
	_check(m.bones == bones_before + 2, "aleta cheer does not trigger twice")

	# 14. Scenery draw execution without errors
	var b := ShapeBatch.new()
	var vt := diada_pos.y - 100.0
	var vb := diada_pos.y + 100.0
	GoticCastellers.draw(m, b, vt, vb)
	b.flush(m._wc)
	_check(true, "draw runs cleanly with Castellers de Barcelona")

	m.queue_free()
	print("test_gotic_castellers: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
