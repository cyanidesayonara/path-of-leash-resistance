extends SceneTree

# Rope obstacles live at the strap's waist-high plane. Wide things follow
# their visible/body outline; low clutter stays below it.

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
	_test_rect_samples()
	await _test_live_partit()
	await _test_low_clutter_and_benches()
	await _test_scooters_topple()
	print("test_leash_height_geometry: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _test_rect_samples() -> void:
	var lb: Script = load("res://world/level_build.gd")
	if not lb.has_method("rect_rope_samples"):
		_check(false, "level geometry exposes rect_rope_samples")
		return
	var r := Rect2(100.0, 200.0, 52.0, 108.0)
	var samples: Array = lb.call("rect_rope_samples", r)
	_check(samples.size() >= 16, "a parked car has an outline, not four corner ghosts (%d)" % samples.size())
	var worst_out := 0.0
	var covered := true
	for sample in samples:
		var p := Vector2(sample.x, sample.y)
		var rad := float(sample.z)
		var inside := minf(minf(p.x - r.position.x, r.end.x - p.x),
			minf(p.y - r.position.y, r.end.y - p.y))
		worst_out = maxf(worst_out, rad - inside)
	for side in range(4):
		var length := r.size.x if side < 2 else r.size.y
		for n in range(int(length / 4.0) + 1):
			var q: Vector2
			var along := minf(float(n) * 4.0, length)
			match side:
				0: q = Vector2(r.position.x + along, r.position.y)
				1: q = Vector2(r.position.x + along, r.end.y)
				2: q = Vector2(r.position.x, r.position.y + along)
				_: q = Vector2(r.end.x, r.position.y + along)
			var hit := false
			for sample in samples:
				if q.distance_to(Vector2(sample.x, sample.y)) <= float(sample.z):
					hit = true
					break
			covered = covered and hit
	_check(worst_out <= 4.1, "the strap clears a car by at most 4px (%.1f)" % worst_out)
	_check(covered, "the car outline has no gaps for a segment to cross")
	_test_segment_meets_rect(samples, r)


func _test_segment_meets_rect(samples: Array, r: Rect2) -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	dog.global_position = Vector2(r.position.x - 30.0, r.get_center().y + 2.0)
	human.global_position = Vector2(r.end.x + 30.0, r.get_center().y + 2.0)
	var poles: Array[Vector2] = []
	var radii := PackedFloat32Array()
	for sample: Vector3 in samples:
		poles.append(Vector2(sample.x, sample.y))
		radii.append(sample.z)
	leash.setup(dog, human, poles, 150.0)
	leash.pole_radii = radii
	leash.furniture_poles = poles
	for i in range(90):
		leash.tick(1.0 / 60.0)
	_check(leash.contacts > 0, "a strap laid through the car meets its outline")
	leash.free()
	dog.free()
	human.free()


func _make_level(id: String) -> Node2D:
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = id
	root.get_node("Sfx").muted = true
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	return m


func _near_sample(m: Node2D, at: Vector2, within: float) -> bool:
	var got = m.leash.get("pole_radii")
	if not got is PackedFloat32Array:
		return false
	var radii: PackedFloat32Array = got
	if radii.size() != m.poles.size():
		return false
	for i in range(m.poles.size()):
		if m.poles[i].distance_to(at) <= within:
			return true
	return false


func _test_live_partit() -> void:
	var m := await _make_level("partit")
	var radii = m.leash.get("pole_radii")
	_check(radii is PackedFloat32Array, "the solver stores one radius per static obstacle")
	if radii is PackedFloat32Array:
		_check(radii.size() == m.poles.size(), "radii stay parallel to positions")
	var car := Rect2(752.0, -300.0, 52.0, 108.0)
	var edge := Vector2(car.position.x, car.get_center().y)
	_check(_near_sample(m, edge, 13.0), "the parked car's door edge catches the leash")
	_check(_near_sample(m, car.get_center(), 8.0), "the solid car interior cannot strand the leash")
	m.free()


func _test_scooters_topple() -> void:
	var m := await _make_level("oldtown")
	var scooters := m.get_tree().get_nodes_in_group("parked_scooters")
	_check(scooters.size() == m.scooters.size(), "every parked scooter is a toppleable object")
	_check(not _near_sample(m, m.scooters[0], 4.0), "a parked scooter is not a permanent rope anchor")
	if not scooters.is_empty():
		var scooter: Node2D = scooters[0]
		m.leash.taut = true
		for i in range(m.leash.pts.size()):
			m.leash.pts[i] = scooter.global_position
		scooter._physics_process(1.0 / 60.0)
		_check(bool(scooter.get("fallen")), "a taut strap tips the scooter over")
	m.free()


func _test_low_clutter_and_benches() -> void:
	var m := await _make_level("street")
	_check(not m.hydrants.is_empty(), "fixture has hydrants")
	_check(not m.astands.is_empty(), "fixture has A-stands")
	_check(not m.benches.is_empty(), "fixture has benches")
	_check(not _near_sample(m, m.hydrants[0].pos, 4.0), "hydrants stay below the leash plane")
	_check(not _near_sample(m, m.astands[0], 4.0), "A-stands topple instead of snagging")
	_check(_near_sample(m, m.benches[0], 30.0), "a bench back catches the leash")
	var manhole: Vector2 = m.manholes[0] if not m.manholes.is_empty() else Vector2(INF, INF)
	if manhole.x < INF:
		_check(not _near_sample(m, manhole, 4.0), "manholes stay below the leash plane")
	var challengers := m.get_tree().get_nodes_in_group("challengers")
	_check(challengers.size() == 1, "fixture has the dare bench")
	if challengers.size() == 1:
		_check(_near_sample(m, challengers[0].global_position, 36.0), "the dare bench catches, not the kid")
	m.free()
