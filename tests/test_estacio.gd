extends SceneTree

# L'Estacio is its own station (docs/LEVEL_DESIGN.md): the moving walkway
# counts a ride only end to end; the ticket barriers are solid except at their
# gaps, and the owner goes through the middle one; the train stands between
# two platforms, solid, with the owner keeping to the east one. No terrace,
# no crossings, no drains.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _push(body: CharacterBody2D, from: Vector2, v: Vector2, frames: int) -> Vector2:
	body.global_position = from
	for i in range(frames):
		body.velocity = v
		body.move_and_slide()
	return body.global_position


func _run() -> void:
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "station"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	_check(m.tables.is_empty() and m.lane_ys.is_empty() and m.manholes.is_empty(), "no terrace, no crossings, no drains indoors")
	var ids: Array = []
	for q: Dictionary in m.active_quests:
		ids.append(q.id)
	_check("walkway" in ids, "L'Estacio has its walkway goal")
	# the barriers: solid between the gaps, open at a gap
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var by: float = LevelBuild.ESTACIO_BARRIER_Y
	var between: float = (float(LevelBuild.ESTACIO_GAPS[0]) + float(LevelBuild.ESTACIO_GAPS[1])) * 0.5
	var stopped := _push(dog, Vector2(between, by + 60.0), Vector2(0, -400), 40)
	_check(stopped.y > by, "the barrier line stops the dog between the gaps")
	var through := _push(dog, Vector2(float(LevelBuild.ESTACIO_GAPS[0]), by + 60.0), Vector2(0, -400), 40)
	_check(through.y < by - 20.0, "and lets her through a gap")
	# the train is solid
	var tr: Rect2 = LevelBuild.ESTACIO_TRAIN
	var off := _push(dog, Vector2(tr.position.x - 60.0, tr.get_center().y), Vector2(400, 0), 40)
	_check(off.x < tr.position.x, "the train is solid")
	# the owner: through the middle gate, then down the east platform
	var human: CharacterBody2D = m.human
	var nw: Dictionary = m.narrows[0]
	human.global_position = Vector2(m.walk_edges(by).x + 60.0, by + human.NARROW_LEAD)
	human.velocity = Vector2.ZERO
	for f in range(900):
		m.elapsed += 1.0 / 30.0
		human._walk(1.0 / 30.0)
		if human.global_position.y < by + 14.0:
			break
	_check(human.global_position.x > float(nw["x0"]) - 12.0 and human.global_position.x < float(nw["x1"]) + 12.0,
		"the owner lines up for the middle gate (x %.0f)" % human.global_position.x)
	# straight on from the gate, the owner is round the train's end, not into it
	human.global_position = Vector2(float(LevelBuild.ESTACIO_GAPS[1]), by - 20.0)
	human.velocity = Vector2.ZERO
	var clear := true
	for f in range(900):
		m.elapsed += 1.0 / 30.0
		human._walk(1.0 / 30.0)
		clear = clear and not tr.grow(6.0).has_point(human.global_position)
		if human.global_position.y < tr.end.y - 60.0:
			break
	_check(clear and human.global_position.x > tr.end.x, "from the gate the owner walks round the train onto the east platform (x %.0f)" % human.global_position.x)
	var east := true
	for y in [tr.end.y - 40.0, tr.get_center().y, tr.position.y + 40.0]:
		human.global_position = Vector2(tr.end.x + 80.0, y)
		human.velocity = Vector2.ZERO
		for f in range(600):
			m.elapsed += 1.0 / 30.0
			human._walk(1.0 / 30.0)
			human.global_position.y = y
			east = east and human.global_position.x > tr.end.x
	_check(east, "the owner keeps to the east platform beside the train")
	# the walkway: a ride counts end to end, not a hop on halfway
	var wz: Rect2 = m.conveyor_zone
	m.walkway_rides = 0
	m.walkway_from = INF
	m.frozen = false
	var r0: int = m.walkway_rides
	# a hop on halfway and off at the top does not count
	dog.global_position = wz.get_center()
	m._physics_process(1.0 / 60.0)
	dog.global_position = Vector2(wz.get_center().x, wz.position.y + 20.0)
	m._physics_process(1.0 / 60.0)
	_check(m.walkway_rides == r0, "hopping on halfway does not count")
	# off, then on at the bottom and all the way up
	dog.global_position = Vector2(wz.end.x + 80.0, wz.end.y + 60.0)
	m._physics_process(1.0 / 60.0)
	dog.global_position = Vector2(wz.get_center().x, wz.end.y - 30.0)
	m._physics_process(1.0 / 60.0)
	dog.global_position = Vector2(wz.get_center().x, wz.get_center().y)
	m._physics_process(1.0 / 60.0)
	dog.global_position = Vector2(wz.get_center().x, wz.position.y + 20.0)
	m._physics_process(1.0 / 60.0)
	_check(m.walkway_rides == r0 + 1, "riding it from the bottom to the top counts")
	# a still dog on it rises; the same dog beside it does not
	dog.global_position = Vector2(wz.get_center().x, wz.end.y - 20.0)
	human.global_position = dog.global_position + Vector2(0, 40)
	m.leash.resnap()
	var y0: float = dog.global_position.y
	for i in range(40):
		await physics_frame
	_check(dog.global_position.y < y0 - 20.0, "standing on the walkway carries her up (%.0f)" % (y0 - dog.global_position.y))
	dog.global_position = Vector2(wz.end.x + 80.0, wz.end.y - 20.0)
	human.global_position = dog.global_position + Vector2(0, 40)
	m.leash.resnap()
	y0 = dog.global_position.y
	for i in range(40):
		await physics_frame
	_check(absf(dog.global_position.y - y0) < 20.0, "beside the walkway, she stays put")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_estacio: OK")
		quit(0)
	else:
		quit(1)
