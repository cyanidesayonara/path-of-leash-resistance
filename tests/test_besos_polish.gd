extends SceneTree

# El Besos visual polish:
# 1. West flood wall embankment (_draw_besos_wall_module) has upper promenade,
#    concrete coping, expansion joints, and emergency evacuation stairs; east
#    river side has no city building roofs or awnings under the water.
# 2. _draw_besos renders the riverside cycle lane, shingle cobbles, quarry-stone
#    riprap embankment (escullera), riverside reed beds (canyissars), detailed
#    maintenance apron (BESOS_APRON), graduated hydrological gauges + SAHBE
#    beacons, ribbed inflatable rubber weir (-3112) with overflow foam, bridge
#    shadows, and SAHBE electronic entrance sign (open and flood-alert states).
# 3. _draw_besos_post renders Parc Fluvial waymarker totems instead of red
#    cast-iron street fire hydrants.


class SpyCanvas:
	var rects: Array[Dictionary] = []
	var circles: Array[Dictionary] = []
	var lines: Array[Dictionary] = []
	var arcs: Array[Dictionary] = []

	func draw_rect(r: Rect2, col: Color, filled := true, _w := -1.0) -> void:
		rects.append({"rect": r, "col": col, "filled": filled})

	func draw_circle(p: Vector2, r: float, col: Color) -> void:
		circles.append({"pos": p, "r": r, "col": col})

	func draw_line(a: Vector2, b: Vector2, col: Color, w := -1.0) -> void:
		lines.append({"a": a, "b": b, "col": col, "w": w})

	func draw_arc(p: Vector2, r: float, a0: float, a1: float, _pts: int, col: Color, w := 1.0) -> void:
		arcs.append({"pos": p, "r": r, "a0": a0, "a1": a1, "col": col, "w": w})

	func draw_colored_polygon(_pts: PackedVector2Array, _col: Color) -> void:
		pass

	func draw_set_transform(_p: Vector2, _r := 0.0, _s := Vector2.ONE) -> void:
		pass


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
	game.level_id = "besos"
	game.weather = "clear"
	game.night = false
	seed(1)
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	await process_frame

	# 1. Edge layer: west flood wall embankment, no east-side city blocks under the river
	var edge_spy := SpyCanvas.new()
	m._draw_edges(edge_spy, -1200.0, -400.0)
	var east_roofs := 0
	var west_wall_rects := 0
	for rc: Dictionary in edge_spy.rects:
		var r: Rect2 = rc["rect"]
		if r.size.x > 0.0 and r.position.x >= 700.0:
			east_roofs += 1
		if r.size.x > 0.0 and r.end.x <= m.sw_l + 40.0:
			west_wall_rects += 1
	_check(east_roofs == 0, "besos edge layer draws no city building blocks under the east river (got %d)" % east_roofs)
	_check(west_wall_rects >= 20, "besos edge layer draws west flood wall embankment and emergency stair bays (got %d rects)" % west_wall_rects)
	_check(edge_spy.lines.size() >= 12, "besos flood wall modules draw upper cycle track dashes, railings, and expansion joints (got %d lines)" % edge_spy.lines.size())

	# 2. _draw_besos across full river span (entrance, gauge, apron, weir, reedy stretch, bridge)
	m._wc = ShapeBatch.new()
	m.chase_phase = ""
	m._draw_besos(-5020.0, 120.0)
	var batch_pts: int = m._wc._points.size()
	_check(batch_pts > 8000, "besos ShapeBatch contains rich riprap boulders, reeds, apron, weir, and gauge geometry (got %d vertices)" % batch_pts)

	# 3. SAHBE electronic entrance board & beacons react to flood warning state
	m._wc = ShapeBatch.new()
	m.chase_phase = ""
	m._draw_besos(-40.0, 120.0)
	var calm_pts: int = m._wc._points.size()

	m._wc = ShapeBatch.new()
	m.chase_phase = "warning"
	m._draw_besos(-40.0, 120.0)
	var alert_pts: int = m._wc._points.size()
	_check(alert_pts > calm_pts, "flood warning state adds pulsing amber beacon halos on SAHBE entrance board (%d vs %d vertices)" % [alert_pts, calm_pts])
	m.chase_phase = ""

	# 4. Markable park posts (_draw_besos_post)
	var post_spy := SpyCanvas.new()
	m._draw_besos_post(post_spy, {"pos": Vector2(280.0, -1000.0), "done": false, "progress": 0.4})
	_check(post_spy.rects.size() >= 5, "besos markable post draws timber/green totem and SAHBE hydrological badge (got %d rects)" % post_spy.rects.size())
	_check(post_spy.circles.size() >= 2, "besos markable post draws concrete collar footing (got %d circles)" % post_spy.circles.size())
	_check(post_spy.arcs.size() == 1, "besos markable post draws progress arc when being marked")

	print("test_besos_polish: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
