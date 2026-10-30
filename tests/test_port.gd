extends SceneTree

# El Port (systems/port.gd): Port Vell and Barceloneta fishing docks.
# The corridor builds clean, cast-iron mooring bollards and palms register
# in poles so the leash wraps around them, the human center corridor remains
# open, solids clear the walking path, all 12 goals are well-defined and
# satisfyable, and LevelCheck.check(m) passes with zero errors.

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
	game.level_id = "port"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var P: GDScript = load("res://systems/port.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration in campaign lists
	_check(game.LEVELS.has("port"), "port is in LEVELS")
	_check(game.CAROUSEL.has("port"), "port is in CAROUSEL")
	_check(int(game.STAR_GATE["port"]) == 29, "opens at 29 stars")
	_check(String(game.LEVEL_NAMES["port"]) == "El Port", "named El Port")
	_check(m.gate_text == "MOLL DE LA FUSTA", "gate text is MOLL DE LA FUSTA")
	_check(m.freedom_kind == "placa", "ends in quayside placa")

	# 2. Structural LevelCheck passes clean
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. Wharf corridor geometry
	var e_start: Vector2 = m.walk_edges(m.START_Y)
	var e_mid: Vector2 = m.walk_edges(-2200.0)
	var e_gate: Vector2 = m.walk_edges(m.GATE_Y)
	_check(e_start.y - e_start.x >= 500.0, "start corridor is wide enough (%.0f)" % (e_start.y - e_start.x))
	_check(e_mid.y - e_mid.x >= 500.0, "wharf corridor is wide enough (%.0f)" % (e_mid.y - e_mid.x))
	_check(e_gate.y - e_gate.x >= 500.0, "gate corridor is wide enough (%.0f)" % (e_gate.y - e_gate.x))

	# 4. Human center path is completely clear of solids
	var y: float = m.START_Y
	var human_clear := true
	while y >= m.GATE_Y:
		var hp := Vector2(640.0, y)
		if _inside_solid(m, hp, 18.0):
			human_clear = false
			print("Human blocked at y=%.0f" % y)
			break
		y -= 100.0
	_check(human_clear, "human walking line (x=640) is free of solid obstacles")

	# 5. Mooring bollards registered as poles (wrap-capable)
	var all_bollards_in_poles := true
	for b: Vector2 in P.BOLLARDS:
		if not (b in m.poles):
			all_bollards_in_poles = false
			print("Bollard missing from m.poles: %s" % str(b))
	_check(all_bollards_in_poles, "all mooring bollards are registered in m.poles")

	# 6. Sniffable spots (hydrants) & snacks
	_check(m.hydrants.size() >= 5, "at least 5 sniffable spots (%d)" % m.hydrants.size())
	_check(m.kebabs.size() >= 4, "at least 4 dropped fish snacks (%d)" % m.kebabs.size())
	_check(m.bins.size() >= 3, "port has bins for the bag chore (%d)" % m.bins.size())
	_check(m.prize_pos.x < INF, "prize catch placed on auction scale")
	_check(m.prize_text == P.PRIZE_TEXT, "prize text matches")

	# 7. Goal definitions
	var goal_ids: Array = G.LEVEL_GOAL_IDS["port"]
	_check(goal_ids.size() == 15, "port has 15 goals (found %d)" % goal_ids.size())
	_check("gulls" in goal_ids, "gulls goal in port")
	_check("bollard" in goal_ids, "bollard goal in port")
	_check("snack" in goal_ids, "snack goal in port")
	_check("prize" in goal_ids, "prize goal in port")

	# 8. Surface checks: pier vs harbor basin
	var p_pier := Vector2(640.0, -2000.0)
	var p_water := Vector2(P.WHARF_EDGE_X + 50.0, -2000.0)
	var S = load("res://world/surfaces.gd")
	_check(m.surface_at(p_pier) == S.S.PAVEMENT, "pier surface is pavement")
	_check(m.surface_at(p_water) == S.S.WATER, "basin surface is water")

	# 9. Simulation step sanity
	for frame in range(15):
		m._physics_process(1.0 / 60.0)
	# (ran 15 physics frames cleanly without error: a draw error fails the run as a SCRIPT ERROR)

	# 10. The gulls perched along the pier take off like the live flocks and
	# count for the gulls goal. They were painted on and never moved, beside
	# a goal asking her to startle gulls.
	var perched := true
	for k in range(P.GULL_SPOTS.size()):
		perched = perched and P.gull_took_off[k] < 0.0
	_check(perched, "every pier gull starts perched")
	var g1: Vector2 = P.GULL_SPOTS[1]
	var before: int = m.port_gulls_startled
	m.dog.global_position = g1 + Vector2(30.0, 0.0)
	m.human.global_position = g1 + Vector2(30.0, 220.0)
	m.leash.resnap()
	for frame in range(3):
		m._physics_process(1.0 / 60.0)
	_check(P.gull_took_off[1] >= 0.0, "walking up to a pier gull sends it up")
	_check(m.port_gulls_startled == before + 1, "and counts for the goal once (%d -> %d)" % [before, m.port_gulls_startled])
	for frame in range(30):
		m._physics_process(1.0 / 60.0)
	_check(m.port_gulls_startled == before + 1, "a gull in the air is not counted again")
	_check(P.gull_took_off[0] < 0.0 and P.gull_took_off[2] < 0.0, "the others stay perched")
	var g2: Vector2 = P.GULL_SPOTS[2]
	m.dog.global_position = g2 + Vector2(-150.0, 0.0)
	m.human.global_position = g2 + Vector2(-150.0, 200.0)
	m.leash.resnap()
	m.on_bark(m.dog.global_position)
	_check(P.gull_took_off[2] >= 0.0, "a bark in earshot sends a pier gull up")
	_check(m.port_gulls_startled == before + 2, "and counts too")
	# drawn in flight (a draw error fails the run as a SCRIPT ERROR)
	m.cam.position = g2
	for frame in range(4):
		await process_frame

	print("\n--- TEST PORT RESULTS ---")
	print("Checks: %d, Failures: %d" % [checks, failures.size()])
	for f: String in failures:
		print("  FAIL: %s" % f)

	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
