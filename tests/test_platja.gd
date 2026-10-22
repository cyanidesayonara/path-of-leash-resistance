extends SceneTree

# La Platja (docs/LEVEL_DESIGN.md): the Mediterranean beachfront walk along
# Passeig Maritim and Bogatell. Sandy shores, wet sand waterline, wooden
# boardwalk (passarel·la de fusta), palm cutouts, beach showers with rentapeus
# foot-wash taps, Salvament de Platges lifeguard watchtowers with lifebuoys,
# raked volleyball courts, and selective recycling stations.

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
	game.level_id = "beach"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.lvl == "beach", "level is beach")
	_check(m.freedom_kind == "beach", "off-leash space is dog beach")

	# Beach landmarks
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	_check(LevelBuild.BEACH_SHOWERS.size() == 2, "two beach showers along the front")
	_check(LevelBuild.BEACH_COURT.size.x > 0 and LevelBuild.BEACH_COURT.size.y > 0, "beach volleyball court is defined")
	_check(LevelBuild.BEACH_TOWER != Vector2.ZERO, "lifeguard tower is placed")
	_check(LevelBuild.BEACH_BARS.size() >= 2, "chiringuito beach bars line the front")

	# Surfaces
	_check(m.surface_at(Vector2(300.0, -1500.0)) == m.Surfaces.S.SAND, "beach sand is sand surface")
	_check(m.surface_at(Vector2(100.0, -1500.0)) == m.Surfaces.S.WATER, "sea is water surface")
	_check(m.surface_at(Vector2(650.0, -1500.0)) == m.Surfaces.S.PAVEMENT, "promenade is pavement surface")

	# Shoreline geometry
	var shore_x: float = m.beach_shore_x(-1500.0)
	_check(shore_x == m.BEACH_GATE_SHORE_X, "shoreline along walk aligns with gate shore x")

	# Selective recycling stations along promenade
	_check(m.bins.size() >= 3, "selective recycling stations placed along front")

	# Method checks
	_check(m.has_method("_draw_beach_shower"), "beach shower drawing function exists")
	_check(m.has_method("_draw_lifeguard_tower"), "lifeguard tower drawing function exists")
	_check(m.has_method("_draw_beach_recycling_station"), "beach recycling station drawing function exists")
	_check(m.has_method("_draw_beach_access_ramp"), "beach access ramp drawing function exists")
	_check(m.has_method("_draw_volley_court"), "volleyball court drawing function exists")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_platja: OK")
		quit(0)
	else:
		quit(1)
