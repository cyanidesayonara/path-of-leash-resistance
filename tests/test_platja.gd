extends SceneTree

# La Platja (docs/LEVEL_DESIGN.md): the Mediterranean beachfront walk along
# Passeig Marítim in Badalona (ending at the Hotel L'Onada plaza with
# the BADALONA sign) and Platja de Llevant (ending at the Platja dels Gossos
# dog beach). Sandy shores, wet sand waterline, wooden boardwalk (passarel·la
# de fusta), palm cutouts, beach showers with rentapeus foot-wash taps,
# Salvament de Platges lifeguard watchtowers with lifebuoys, raked volleyball
# courts, and selective recycling stations.

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
	_check(m.freedom_kind == "placa", "Passeig Marítim off-leash space is Hotel L'Onada plaza")
	_check(m.gate_text == "PLAÇA DE L'HOTEL", "Passeig Marítim gate text is PLAÇA DE L'HOTEL")

	# Beach landmarks
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	_check(LevelBuild.BEACH_SHOWERS.size() == 2, "two beach showers along the front")
	_check(LevelBuild.BEACH_COURT.size.x > 0 and LevelBuild.BEACH_COURT.size.y > 0, "beach volleyball court is defined")
	# where each piece stands: the tower, the court and the showers on the
	# sand, the bars off the promenade on the town side, the showers' columns
	# solid and wrappable like every post
	_check(m.surface_at(LevelBuild.BEACH_TOWER) == m.Surfaces.S.SAND, "the lifeguard tower stands on the sand")
	_check(m.surface_at(LevelBuild.BEACH_COURT.get_center()) == m.Surfaces.S.SAND, "the volleyball court is on the sand")
	for sp: Vector2 in LevelBuild.BEACH_SHOWERS:
		_check(sp.x > m.beach_shore_x(sp.y) and sp.x < m.walk_edges(sp.y).x,
			"the shower at %s stands between the sea and the promenade" % sp)
		_check(sp in m.poles, "the shower at %s is a rope pole" % sp)
	_check(LevelBuild.BEACH_BARS.size() >= 2, "chiringuito beach bars line the front")
	for bar: Rect2 in LevelBuild.BEACH_BARS:
		var be: Vector2 = m.walk_edges(bar.get_center().y)
		_check(bar.position.x >= be.y - 1.0, "the bar at %s stands off the promenade (edge %.0f)" % [bar.position, be.y])

	# Surfaces
	_check(m.surface_at(Vector2(300.0, -1500.0)) == m.Surfaces.S.SAND, "beach sand is sand surface")
	_check(m.surface_at(Vector2(100.0, -1500.0)) == m.Surfaces.S.WATER, "sea is water surface")
	_check(m.surface_at(Vector2(650.0, -1500.0)) == m.Surfaces.S.PAVEMENT, "promenade is pavement surface")

	# Shoreline geometry
	var shore_x: float = m.beach_shore_x(-1500.0)
	_check(shore_x == m.BEACH_GATE_SHORE_X, "shoreline along walk aligns with gate shore x")

	# Selective recycling stations along promenade
	_check(m.bins.size() >= 3, "selective recycling stations placed along front")

	m.queue_free()
	await process_frame

	# Platja de Llevant (Walk 24) carries the dog beach (PLATJA DELS GOSSOS)
	game.level_id = "llevant"
	var ml: Node2D = load("res://main.tscn").instantiate()
	root.add_child(ml)
	if not ml.is_node_ready():
		await ml.ready
	_check(ml.lvl == "llevant", "level is llevant")
	_check(ml.freedom_kind == "beach", "Platja de Llevant off-leash space is dog beach")
	_check(ml.gate_text == "PLATJA DELS GOSSOS", "Platja de Llevant gate text is PLATJA DELS GOSSOS")
	_check(ml.surface_at(Vector2(300.0, -1500.0)) == ml.Surfaces.S.SAND, "llevant sand is sand surface")
	_check(ml.surface_at(Vector2(100.0, -1500.0)) == ml.Surfaces.S.WATER, "llevant sea is water surface")
	_check(ml.surface_at(Vector2(650.0, -1500.0)) == ml.Surfaces.S.PAVEMENT, "llevant promenade is pavement surface")
	var Llevant_script = load("res://systems/llevant.gd")
	for ps: Vector2 in ml.palm_spots:
		_check(not Llevant_script.PERGOLA_RECT.grow(12.0).has_point(ps), "llevant palm is clear of Pergola")
		_check(not Llevant_script.DOG_SHOWER_RECT.grow(12.0).has_point(ps), "llevant palm is clear of Dog Shower")
	_check(ml.tables.is_empty(), "llevant has no stray chiringuito tables inside the solar pergola")
	ml.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_platja: OK")
		quit(0)
	else:
		quit(1)
