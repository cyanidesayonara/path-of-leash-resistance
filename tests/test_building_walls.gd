extends SceneTree

# On a walk whose street bends or opens out (edge_nodes), the wall is the
# building line, and nothing else stands in the street. The straight wall at
# sw_l/sw_r once ran the whole walk and stood across the path itself where it
# bent past them (80 px of El Gòtic's alley, L'Eixample's crossings) and
# across every front yard the stepped building line drew (#474). Pushed at
# each side, down each walk, she reaches the building line and goes no
# further.

var LevelBuild: GDScript
const WALKS: Array[String] = ["oldtown", "station", "site", "spook", "scrap", "guell", "market"]

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


# something solid stands in this band, so it is no probe of the wall
func _crowded(m: Node2D, band: Rect2) -> bool:
	for r: Rect2 in m.solid_rects:
		if band.intersects(r.grow(24.0)):
			return true
	var pts: Array = []
	for i in range(m.body_pole_count):
		pts.append(m.poles[i])
	for h: Dictionary in m.hydrants:
		pts.append(h.pos)
	pts.append_array(m.fountains)
	pts.append_array(m.bins)
	pts.append_array(m.benches)
	pts.append_array(m.tables)
	pts.append_array(m.chairs)
	pts.append_array(m.parasols)
	pts.append_array(m.vans)
	pts.append_array(m.stalls)
	pts.append_array(m.performers)
	for p: Vector2 in pts:
		if band.grow(40.0).has_point(p):
			return true
	# anything else with a body: cones, junk, the entities placed in the street
	for c: Node in m.get_children():
		if c is Node2D and not (c is StaticBody2D):
			for k: Node in c.get_children():
				if k is StaticBody2D and band.grow(40.0).has_point((c as Node2D).global_position):
					return true
	# where the building line steps, a wall crosses the yard 10 px either side
	# of the module boundary: a probe along it is a probe of that wall
	var my: float = band.get_center().y
	if m._stepped_line() and absf(my - roundf(my / m.EDGE_MOD) * m.EDGE_MOD) < 40.0:
		return true
	for ly: float in m.lane_ys:
		if absf(band.get_center().y - ly) < float(m.LANE_HALF) + 80.0:
			return true
	return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	for lv: String in WALKS:
		game.level_id = lv
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		_check(not m.edge_nodes.is_empty() and bool(m.built), "%s bends and is built" % lv)
		var dog: CharacterBody2D = m.dog
		dog.collision_mask = 1
		var probes := 0
		var y: float = m.START_Y - 300.0
		var top: float = m.GATE_Y + 260.0
		if lv == "market":
			top = LevelBuild.MERCAT_DOOR_Y - 200.0
		while y > top:
			var bl: Vector2 = m.building_line(y)
			var e: Vector2 = m.walk_edges(y)
			for side: float in [-1.0, 1.0]:
				var wall_x: float = bl.x if side < 0.0 else bl.y
				var from_x: float = (e.x + e.y) * 0.5
				var band := Rect2(minf(wall_x, from_x), y - 30.0, absf(from_x - wall_x), 60.0)
				if _crowded(m, band):
					continue
				probes += 1
				await physics_frame
				dog.global_position = Vector2(from_x, y)
				for i in range(90):
					dog.velocity = Vector2(side * 600.0, 0.0)
					dog.move_and_slide()
				var end_bl: Vector2 = m.building_line(dog.global_position.y)
				var end_x: float = end_bl.x if side < 0.0 else end_bl.y
				var gap: float = side * (end_x - dog.global_position.x)
				_check(gap >= 0.0, "%s: she stays inside the %s building line at y=%.0f (x %.0f, line %.0f)" % [
					lv, "west" if side < 0.0 else "east", y, dog.global_position.x, end_x])
				_check(gap <= 26.0, "%s: she reaches the %s building line at y=%.0f (stops %.0f px short)" % [
					lv, "west" if side < 0.0 else "east", y, gap])
			y -= 130.0
		_check(probes >= 12, "%s: enough clear wall to probe (%d)" % [lv, probes])
		m.queue_free()
		await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_building_walls: OK")
		quit(0)
	else:
		quit(1)
