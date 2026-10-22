extends SceneTree

# El Barri (docs/LEVEL_DESIGN.md): the neighbourhood park walk.
# A gravel square under London plane trees, benches, a drinking fountain
# with dog bowl, the petanca pitch with its boules and tape measure,
# concrete ping-pong table with steel net and paddles, and the playground.

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
	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.lvl == "barri", "level is barri")
	_check(not m.tutorial_mode, "standard barri walk is not tutorial mode")

	# Landmarks
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	_check(LevelBuild.BARRI_PETANCA.size.x > 0 and LevelBuild.BARRI_PETANCA.size.y > 0, "petanca pitch is defined")
	_check(LevelBuild.BARRI_PLAYGROUND.size.x > 0 and LevelBuild.BARRI_PLAYGROUND.size.y > 0, "playground is defined")
	_check(LevelBuild.BARRI_PINGPONG != Vector2.ZERO, "ping-pong table is placed")
	_check(LevelBuild.BARRI_FONT != Vector2.ZERO, "barri drinking fountain is placed")
	_check(LevelBuild.BARRI_TREES.size() >= 8, "plane trees line the square")

	# Surfaces
	_check(m.surface_at(Vector2(640.0, -2000.0)) == m.Surfaces.S.PAVEMENT, "park square walkway is pavement surface")
	_check(m.surface_at(Vector2(200.0, -2000.0)) == m.Surfaces.S.GRASS, "outer lawn is grass surface")

	# Methods
	_check(m.has_method("_draw_barri"), "barri landmark drawing function exists")
	_check(m.has_method("_boule"), "boule drawing function exists")
	_check(m.has_method("_draw_barri_font"), "fountain drawing function exists")
	_check(m.has_method("_draw_pingpong"), "ping-pong drawing function exists")
	_check(m.has_method("_playground"), "playground drawing function exists")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_barri: OK")
		quit(0)
	else:
		quit(1)
