extends SceneTree

# Les Obres is its own roadworks (docs/LEVEL_DESIGN.md), not La Rambla with
# cement on it: wet cement poured in rectangular formwork with cones at the
# corners, a freshly painted zebra, a trench across the footway with a plank
# the owner keeps to, a digger, and none of the boulevard's terrace or
# benches.

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
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "site"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.tables.is_empty() and m.chairs.is_empty() and m.benches.is_empty(), "no café terrace, no benches")
	_check(m.vans.size() == 1, "one parked digger")
	# the pours: rectangles of slow wet cement, with a cone off every corner
	for sl: Rect2 in LevelBuild.OBRES_SLABS:
		_check(m.surface_at(sl.get_center()) == m.Surfaces.S.SAND, "the pour at (%.0f, %.0f) is heavy going" % [sl.get_center().x, sl.get_center().y])
		var cornered := 0
		for c: Vector2 in [sl.position, Vector2(sl.end.x, sl.position.y), sl.end, Vector2(sl.position.x, sl.end.y)]:
			for cs: Vector2 in m.cone_spots:
				if cs.distance_to(c) < 30.0:
					cornered += 1
					break
		_check(cornered == 4, "a cone at every corner of the pour (%d)" % cornered)
	# the zebra is wet paint, and a mess to carry rather than a surface
	var zebra := false
	for sz: Dictionary in m.substance_zones:
		zebra = zebra or (sz.has("zebra") and String(sz["kind"]) == "paint")
	_check(zebra, "the fresh zebra is wet paint")
	# the trench: holes either side, the plank dry between them
	var ty: float = LevelBuild.OBRES_TRENCH_Y + LevelBuild.OBRES_TRENCH_H * 0.5
	var te: Vector2 = m.walk_edges(ty)
	var pc: float = (te.x + te.y) * 0.5
	var hole_l := false
	var hole_r := false
	var plank_dry := true
	for c: Rect2 in m.cellars:
		hole_l = hole_l or c.has_point(Vector2(te.x + 30.0, ty))
		hole_r = hole_r or c.has_point(Vector2(te.y - 30.0, ty))
		plank_dry = plank_dry and not c.has_point(Vector2(pc, ty))
	_check(hole_l and hole_r and plank_dry, "the trench is open either side of a dry plank")
	# the owner keeps to the plank while crossing
	var nw: Dictionary = m.narrows[0]
	var human: CharacterBody2D = m.human
	var on_plank := true
	for y in [LevelBuild.OBRES_TRENCH_Y - 20.0, ty, LevelBuild.OBRES_TRENCH_Y + LevelBuild.OBRES_TRENCH_H + 20.0]:
		human.global_position = Vector2(pc, y)
		human.velocity = Vector2.ZERO
		for f in range(900):
			m.elapsed += 1.0 / 30.0
			human._walk(1.0 / 30.0)
			human.global_position.y = y
			on_plank = on_plank and human.global_position.x > float(nw["x0"]) - 10.0 and human.global_position.x < float(nw["x1"]) + 10.0
	_check(on_plank, "the owner's weave keeps to the plank over the trench")
	# walking up to the trench, the owner is lined up before the edge
	# from as far to the side as the footway goes, a full lead away
	human.global_position = Vector2(te.x + 40.0, LevelBuild.OBRES_TRENCH_Y + human.NARROW_LEAD)
	human.velocity = Vector2.ZERO
	for f in range(900):
		m.elapsed += 1.0 / 30.0
		human._walk(1.0 / 30.0)
		if human.global_position.y < LevelBuild.OBRES_TRENCH_Y + LevelBuild.OBRES_TRENCH_H + 4.0:
			break
	_check(human.global_position.x > float(nw["x0"]) - 10.0 and human.global_position.x < float(nw["x1"]) + 10.0,
		"coming up from the side, the owner is on the plank by the trench (x %.0f)" % human.global_position.x)
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_obres: OK")
		quit(0)
	else:
		quit(1)
