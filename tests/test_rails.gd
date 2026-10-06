extends SceneTree

# Grinds only on grindables (systems/rails.gd): never on the edge of the path;
# only with the zoomies on, running along the thing; once up, she is held to
# its line whatever the stick does, and landing scores under the grindable's
# own name. The walks with grindables have the ones they should.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(level: String) -> Node2D:
	var game = root.get_node("Game")
	game.level_id = level
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	return m


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var R: GDScript = load("res://systems/rails.gd")

	# El Barri has nothing to grind: the path's edge is not a rail
	var m: Node2D = await _load("barri")
	_check(m.rails.is_empty(), "El Barri has no grindables")
	var e: Vector2 = m.walk_edges(-1500.0)
	m.dog.global_position = Vector2(e.x + 2.0, -1500.0)
	m.dog.velocity = Vector2(0, -420)
	m.dog.turbo_active = true
	m._tick_grind(1.0 / 60.0)
	_check(not m.grind.active, "running along the edge of the path, zoomies and all, is not a grind")
	m.free()
	await physics_frame

	# the tutorial's stone ledge
	m = await _load("tutorial")
	_check(m.rails.size() == 1 and String(m.rails[0]["name"]) == "LEDGE RUN", "the grind lesson has its stone ledge")
	var at: float = load("res://systems/tutorial.gd").at("grind")
	var on := Vector2(R.TUT_LEDGE_X + 6.0, at + 60.0)
	m.dog.global_position = on
	m.dog.velocity = Vector2(0, -420)
	m.dog.turbo_active = false
	m.grind_cd = 0.0
	m._tick_grind(1.0 / 60.0)
	_check(not m.grind.active, "without the zoomies she runs past it")
	m.dog.turbo_active = true
	m.dog.velocity = Vector2(420, 0)
	m._tick_grind(1.0 / 60.0)
	_check(not m.grind.active, "running across it is not riding it")
	m.dog.velocity = Vector2(0, -420)
	m._tick_grind(1.0 / 60.0)
	_check(m.grind.active, "zoomies on, along it: she is up")
	# the stick works the balance and cannot push her off sideways
	m.dog.input_dir = Vector2(1, 0)
	m.dog.velocity = Vector2(300, -420)
	m._tick_grind(1.0 / 60.0)
	_check(is_equal_approx(m.dog.global_position.x, R.TUT_LEDGE_X) and absf(m.dog.velocity.x) < 0.01,
		"held to the ledge's line, only her speed along it her own")
	m.dog.input_dir = Vector2.ZERO
	# run it off the far end: it lands, under the ledge's name
	var c0: int = m.grinds_landed
	for i in range(30):
		m.dog.global_position.y -= 7.0
		m.dog.velocity = Vector2(0, -420)
		m.dog.input_dir = Vector2(-signf(m.grind.lean), 0) if absf(m.grind.lean) > 0.05 else Vector2.ZERO
		m._tick_grind(1.0 / 60.0)
	m.dog.input_dir = Vector2.ZERO
	_check(m.grind.active and m.grind.points() > 0, "a half-second ride is worth something")
	m.dog.global_position = Vector2(R.TUT_LEDGE_X, at - R.TUT_LEDGE_HALF - 30.0)
	m.dog.velocity = Vector2(0, -420)
	m._tick_grind(1.0 / 60.0)
	_check(not m.grind.active, "off the end, it lands")
	_check(m.grinds_landed == c0 + 1, "and counts")
	m.free()
	await physics_frame

	# Montjuic: the terrace walls and the escalators' handrails
	m = await _load("montjuic")
	var names := {}
	for r: Dictionary in m.rails:
		names[String(r["name"])] = int(names.get(String(r["name"]), 0)) + 1
	_check(int(names.get("WALL WALK", 0)) >= 6, "Montjuic's terrace walls are grindable (%d)" % int(names.get("WALL WALK", 0)))
	_check(int(names.get("HANDRAIL", 0)) == 2, "and both escalator handrails")
	m.free()

	print("test_rails: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
