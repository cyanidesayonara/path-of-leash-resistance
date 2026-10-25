extends SceneTree

# Plaça Reial (systems/reial.gd): Walk 19 in the Gothic Quarter.
# The corridor builds clean, Antoni Gaudí's 6-armed dragon lampposts (Fanals
# de Gaudí) register in poles with stunt vault radii, the central Font de les
# Tres Gràcies fountain has drinking interaction, dining terraces and busker
# register properly, all 12 goals are well-defined, and LevelCheck.check(m)
# passes with zero errors.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _inside_solid(m: Node2D, p: Vector2, pad: float) -> bool:
	for r: Rect2 in m.solid_rects:
		if r.grow(pad).has_point(p):
			return true
	return false


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "reial"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var R: GDScript = load("res://systems/reial.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration in campaign lists
	_check(game.LEVELS.has("reial"), "reial is in LEVELS")
	_check(game.CAROUSEL.has("reial"), "reial is in CAROUSEL")
	_check(int(game.STAR_GATE["reial"]) == 31, "opens at 31 stars")
	_check(String(game.LEVEL_NAMES["reial"]) == "Plaça Reial", "named Plaça Reial")
	_check(m.gate_text == "PLAÇA REIAL", "gate text is PLAÇA REIAL")
	_check(m.freedom_kind == "placa", "ends in placa")

	# 2. Structural LevelCheck passes clean
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. Plaza corridor geometry
	var e_start: Vector2 = m.walk_edges(m.START_Y)
	var e_mid: Vector2 = m.walk_edges(-2500.0)
	var e_gate: Vector2 = m.walk_edges(m.GATE_Y)
	_check(e_start.y - e_start.x >= 500.0, "start corridor is wide enough (%.0f)" % (e_start.y - e_start.x))
	_check(e_mid.y - e_mid.x >= 500.0, "plaza corridor is wide enough (%.0f)" % (e_mid.y - e_mid.x))
	_check(e_gate.y - e_gate.x >= 500.0, "gate corridor is wide enough (%.0f)" % (e_gate.y - e_gate.x))

	# 4. Central fountain island directs owner around fountain
	_check(not m.islands.is_empty(), "central fountain island is defined")
	_check(m.islands[0].has("rect"), "fountain island has rect")

	# 5. Gaudí lampposts registered as poles (wrap-capable)
	var all_posts_in_poles := true
	for p: Vector2 in R.GAUDI_POSTS:
		if not (p in m.poles):
			all_posts_in_poles = false
			print("Gaudí post missing from m.poles: %s" % str(p))
	_check(all_posts_in_poles, "all Gaudí lampposts are registered in m.poles")

	# 6. Palms registered in poles
	var all_palms_in_poles := true
	for p: Vector2 in R.PALMS:
		if not (p in m.poles):
			all_palms_in_poles = false
			print("Palm missing from m.poles: %s" % str(p))
	_check(all_palms_in_poles, "all royal palm trunks are registered in m.poles")

	# 7. Sniffable spots (hydrants) & snacks
	_check(m.hydrants.size() >= 5, "at least 5 sniffable spots (%d)" % m.hydrants.size())
	_check(m.kebabs.size() >= 4, "at least 4 dropped churros/tapas snacks (%d)" % m.kebabs.size())
	_check(m.bins.size() >= 2, "at least 2 trash bins for bag chore (%d)" % m.bins.size())
	_check(m.prize_pos.x < INF, "prize placed on terrace table")
	_check(m.prize_text == R.PRIZE_TEXT, "prize text matches")
	_check(not _inside_solid(m, m.prize_pos, 2.0), "prize is reachable without being inside solid")

	# 8. Goal definitions
	var goal_ids: Array = G.LEVEL_GOAL_IDS["reial"]
	_check(goal_ids.size() == 12, "reial has 12 goals (found %d)" % goal_ids.size())
	_check("gaudi" in goal_ids, "gaudi goal in reial")
	_check("fountain" in goal_ids, "fountain goal in reial")
	_check("snack" in goal_ids, "snack goal in reial")
	_check("prize" in goal_ids, "prize goal in reial")

	# 9. Surface check: pavement inside gate, freedom verge is not sidewalk
	var Surfaces := load("res://world/surfaces.gd")
	_check(m.surface_at(Vector2(640.0, -2000.0)) == Surfaces.S.PAVEMENT, "plaza surface is pavement")
	var yard := Vector2(m.walk_cx - m.walk_half - 60.0, m.GATE_Y - 300.0)
	_check(m.surface_at(yard) != Surfaces.S.PAVEMENT, "freedom verge is not turned into sidewalk")

	# 10. Mechanics tick: fountain drinking & gaudi wrap & busker duet
	# standing still by the rim without drinking is not a drink, and
	# standing by a lamppost is not a wrap (that check once read a field
	# main does not have, a script error every frame near a post)
	m.dog.global_position = R.FOUNTAIN_POS + Vector2(R.FOUNTAIN_RADIUS + 10.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m.dog.drinking = 0.0
	R.tick(m, 0.1)
	_check(not m.reial_fountain_drank, "standing still by the fountain is not a drink")
	m.dog.global_position = R.GAUDI_POSTS[0] + Vector2(30.0, 0.0)
	R.tick(m, 0.1)
	_check(not m.reial_gaudi_wrapped, "standing by a lamppost is not a wrap")

	m.pee = 0.2
	m.dog.global_position = R.FOUNTAIN_POS + Vector2(R.FOUNTAIN_RADIUS + 10.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m._bodily(0.2)
	_check(m.pee > 0.2, "fountain refills bladder at fountain rim reach (pee=%.2f)" % m.pee)
	_check(m.dog.drinking > 0.0, "drinking animation activates at fountain rim")
	R.tick(m, 0.1)
	_check(bool(m.get("reial_fountain_drank")), "drinking at fountain triggers reial_fountain_drank")

	m.dog.global_position = R.BUSKER_POS + Vector2(20.0, 0.0)
	m.dog.bark_anim = 0.3
	R.tick(m, 0.1)
	_check(bool(m.get("reial_busker_barked")), "barking at busker triggers reial_busker_barked")


	print("\n--- TEST REIAL RESULTS ---")
	print("Checks: %d, Failures: %d" % [checks, failures.size()])
	for f: String in failures:
		print("  FAIL: %s" % f)

	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
