extends SceneTree

# El Veterinari (systems/vet.gd): The vet clinic escape chase.
# Tests campaign registration, corridor bounds, solids clearing the center walking line,
# IV poles registered in m.poles, pet scale weigh-in interaction, chase threat setup,
# and LevelCheck.check(m) passing with 0 failures.

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


func _fed(m: Node2D, text: String) -> bool:
	for l: Dictionary in m.feed.lines:
		if String(l.get("text", "")) == text:
			return true
	return false


func _count_pops(m: Node2D, text: String) -> int:
	var n := 0
	for p: Dictionary in m.pops.pops:
		if String(p.get("text", "")) == text:
			n += 1
	return n


func _popped(m: Node2D, text: String) -> bool:
	return m.pops != null and _count_pops(m, text) > 0


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "vet"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var V: GDScript = load("res://systems/vet.gd")
	var G: GDScript = load("res://systems/goals.gd")
	var HC: GDScript = load("res://systems/home_chase.gd")

	# 1. Registration in campaign lists
	_check(game.LEVELS.has("vet"), "vet is in LEVELS")
	_check(game.CAROUSEL.has("vet"), "vet is in CAROUSEL")
	_check(int(game.STAR_GATE["vet"]) == 33, "opens at 33 stars")
	_check(String(game.LEVEL_NAMES["vet"]) == "El Veterinari", "named El Veterinari")
	_check(m.gate_text == "CLINICA VETERINARIA", "gate text is CLINICA VETERINARIA")
	_check(m.freedom_kind == "yard", "ends in recovery yard")

	# 2. Structural LevelCheck passes clean
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. Corridor geometry
	var e_start: Vector2 = m.walk_edges(m.START_Y)
	var e_mid: Vector2 = m.walk_edges(-2200.0)
	var e_gate: Vector2 = m.walk_edges(m.GATE_Y)
	_check(e_start.y - e_start.x >= 500.0, "start corridor is wide enough (%.0f)" % (e_start.y - e_start.x))
	_check(e_mid.y - e_mid.x >= 500.0, "clinic corridor is wide enough (%.0f)" % (e_mid.y - e_mid.x))
	_check(e_gate.y - e_gate.x >= 500.0, "gate corridor is wide enough (%.0f)" % (e_gate.y - e_gate.x))

	# 4. Human center path is free of solid obstacles
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

	# 5. IV poles registered in m.poles (rope wrap and slingshot)
	var all_poles_registered := true
	for p: Vector2 in V.IV_POLES:
		if not (p in m.poles):
			all_poles_registered = false
			print("Pole missing from m.poles: %s" % str(p))
	_check(all_poles_registered, "all IV poles registered in m.poles")

	# 6. Sniffable landmarks, snacks, bins
	_check(m.hydrants.size() >= 5, "at least 5 sniffable spots (%d)" % m.hydrants.size())
	_check(m.kebabs.size() >= 4, "at least 4 dropped snacks (%d)" % m.kebabs.size())
	_check(m.bins.size() >= 4, "at least 4 waste bins (%d)" % m.bins.size())
	_check(m.prize_pos.x < INF, "prize placed on reception desk")
	_check(m.prize_text == V.PRIZE_TEXT, "prize text matches")

	# 7. Pet scale weigh-in interaction
	_check(not bool(m.vet_scale_weighed), "scale unweighed initially")
	m.dog.global_position = V.SCALE_POS
	V.tick(m)
	_check(bool(m.vet_scale_weighed), "stepping on scale triggers weigh-in")
	_check(_fed(m, "WEIGH-IN! 14.2 KG"), "the weigh-in is shouted in the feed")
	_check(_popped(m, "beep!"), "the scale beeps")

	# 7b. A bark beside a cat carrier gets a hiss (main.on_bark), one away does not
	var pops_before: int = m.pops.pops.size()
	m.on_bark(V.CAT_CARRIERS[0] + Vector2(30.0, 0.0))
	_check(_popped(m, "hisss!"), "a bark beside the carrier gets a hiss")
	var hisses := _count_pops(m, "hisss!")
	m.on_bark(V.CAT_CARRIERS[0] + Vector2(0.0, 400.0))
	_check(_count_pops(m, "hisss!") == hisses, "a bark across the room gets none")
	_check(m.pops.pops.size() > pops_before, "the hiss is a pop on screen")

	# 8. Chase threat profile integration
	var profile: Dictionary = HC.profile_for("vet")
	_check(not profile.is_empty(), "vet has a valid chase profile")
	_check(String(profile.get("id", "")) == "vet", "chase profile id is vet")
	_check(String(profile.get("script", "")) == "res://entities/vet_threat.gd", "chase uses vet_threat script")
	_check((profile.get("bands", []) as Array).size() >= 2, "chase profile has respites")

	# 9. Goal definitions
	var goal_ids: Array = G.LEVEL_GOAL_IDS["vet"]
	_check(goal_ids.size() == 12, "vet has 12 goals (found %d)" % goal_ids.size())
	_check("scale" in goal_ids, "scale goal in vet")
	_check("cone" in goal_ids, "cone goal in vet")
	_check("snack" in goal_ids, "snack goal in vet")
	_check("prize" in goal_ids, "prize goal in vet")

	# 10. Surface check: clinic corridor is pavement
	var S = load("res://world/surfaces.gd")
	_check(m.surface_at(Vector2(640.0, -2000.0)) == S.S.PAVEMENT, "clinic floor surface is pavement")

	# 11. The chase home actually spawns the clinic assistants and they run.
	# A broken preload once made this script fail to parse, so every vet
	# walk crashed on the way home while every other check stayed green.
	HC.begin(m)
	HC.release(m)
	var threat: Node2D = m.chase_sweeper
	_check(threat != null and threat.get_script() != null
		and (threat.get_script() as Script).resource_path == "res://entities/vet_threat.gd",
		"the chase spawned the vet threat")
	if threat != null and threat.get_script() != null:
		var start_y: float = threat.front_y
		m.chase_phase = "chase"
		for frame in range(30):
			HC.tick(m, 1.0 / 60.0)
			await process_frame
		_check(threat.front_y != start_y, "the assistants advance (%.0f -> %.0f)" % [start_y, threat.front_y])
		_check(threat.has_method("caught") and threat.has_method("gap_to"), "the threat answers the chase interface")

	print("\n--- TEST VET RESULTS ---")
	print("Checks: %d, Failures: %d" % [checks, failures.size()])
	for f: String in failures:
		print("  FAIL: %s" % f)

	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
