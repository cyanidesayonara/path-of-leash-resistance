extends SceneTree

# main.freedom_side_lamps, the shared lamps a walk's night_lights hook hangs
# down both sides of its off-leash area: a pair at each fraction asked for,
# inset from the area's edges, each a wall lamp to the light layer.

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
	root.get_node("Sfx").muted = true
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var r: Rect2 = m._freedom_rect()
	var fracs: Array[float] = [0.25, 0.6]
	var lamps: Array[Vector3] = m.freedom_side_lamps(fracs, 30.0, 140.0)
	_check(lamps.size() == 4, "a pair for each fraction (%d)" % lamps.size())
	_check(lamps[0] == Vector3(r.position.x + 30.0, r.position.y + r.size.y * 0.25, 140.0), "the first is on the west side, a quarter down")
	_check(lamps[1] == Vector3(r.end.x - 30.0, r.position.y + r.size.y * 0.25, 140.0), "its pair is on the east side")
	_check(lamps[3].y == r.position.y + r.size.y * 0.6, "the second pair is at its own fraction")
	var wall := true
	for l: Vector3 in lamps:
		wall = wall and l.z < m.NIGHT_LAMP_R and r.has_point(Vector2(l.x, l.y))
	_check(wall, "each is a wall lamp inside the off-leash area")
	_check(m.freedom_side_lamps([] as Array[float], 0.0, 100.0).is_empty(), "no fractions, no lamps")
	m.queue_free()
	await process_frame
	print("%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_freedom_lamps: OK")
		quit(0)
	else:
		quit(1)
