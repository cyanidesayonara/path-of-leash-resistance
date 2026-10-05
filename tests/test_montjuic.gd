extends SceneTree

# Montjuic (systems/montjuic.gd): the climb slows your human going up and
# speeds them coming down, and nowhere else; every gust is telegraphed before
# it shoves; and the escalators up the last straight sit on the path and carry
# whoever stands on them up the hill.

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
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "montjuic"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var M: GDScript = load("res://systems/montjuic.gd")

	# the slope
	_check(M.slope_mult(m, -2000.0, -1.0) < 1.0, "uphill is slower")
	_check(M.slope_mult(m, -2000.0, 1.0) > 1.0, "downhill is quicker")
	_check(M.slope_mult(m, 400.0, -1.0) == 1.0, "off the hill, no slope")

	# the escalators: on the path, carrying up
	var z: Rect2 = m.conveyor_zone
	var e: Vector2 = m.walk_edges(z.get_center().y)
	_check(z.size.y > 200.0 and z.position.x > e.x and z.end.x < e.y, "the escalators run up the path itself")
	_check(z.end.y < M.terrace_ys(m)[M.terrace_ys(m).size() - 1] - M.STEP_H, "clear of the last terrace's steps")
	_check(m.conveyor_dir.y < 0.0, "and they go up")
	# a still dog on them rises; the same dog beside them does not
	m.dog.global_position = Vector2(z.get_center().x, z.end.y - 20.0)
	m.human.global_position = m.dog.global_position + Vector2(0, 40)
	m.leash.resnap()
	var y0: float = m.dog.global_position.y
	for i in range(40):
		await physics_frame
	_check(m.dog.global_position.y < y0 - 20.0, "standing on them carries her up (%.0f)" % (y0 - m.dog.global_position.y))
	m.dog.global_position = Vector2(e.x + 20.0, z.end.y - 20.0)
	m.human.global_position = m.dog.global_position + Vector2(0, 40)
	m.leash.resnap()
	y0 = m.dog.global_position.y
	for i in range(40):
		await physics_frame
	_check(absf(m.dog.global_position.y - y0) < 20.0, "on the stairs beside, she stays put")

	# the wind: a warning before every gust
	m.dog.global_position = Vector2(640, -4200)
	m.human.global_position = Vector2(640, -4160)
	m.leash.resnap()
	m.wind_next = 0.01
	var warned := false
	var gusted_unwarned := false
	for i in range(240):
		await physics_frame
		if m.wind_warn > 0.0:
			warned = true
		if m.wind_gust > 0.0 and not warned:
			gusted_unwarned = true
	_check(warned and not gusted_unwarned, "every gust is telegraphed first")

	m.free()
	print("test_montjuic: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
