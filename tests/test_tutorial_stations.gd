extends SceneTree

# The First Walk as stations (docs/LEVEL_DESIGN.md): El Barri emptied out,
# one lesson per station, far enough apart that only one is on screen, each
# holding exactly what its lesson needs; the owner waits at a lesson that
# wants them still; and nothing turns up that no lesson asked for.

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
	var TUT: GDScript = load("res://systems/tutorial.gd")
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "tutorial"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.tutorial_mode and m.lvl == "barri", "the tutorial runs on El Barri")
	# stations in order up the walk, a screen apart
	var spaced := true
	for i in range(1, TUT.STEPS.size()):
		var gap := float(TUT.STEPS[i - 1]["at"]) - float(TUT.STEPS[i]["at"])
		spaced = spaced and gap >= 90.0
	_check(spaced, "every station is further up the walk than the last")
	var on_path_gap := true
	for i in range(1, TUT.STEPS.size()):
		if float(TUT.STEPS[i]["at"]) > m.GATE_Y:
			on_path_gap = on_path_gap and (float(TUT.STEPS[i - 1]["at"]) - float(TUT.STEPS[i]["at"])) >= 360.0
	_check(on_path_gap, "stations on the walk are at least a screen apart")
	# each station holds what its lesson needs
	var pee_y: float = TUT.at("pee")
	var sniff_y: float = TUT.at("sniff")
	var near_pee := false
	var near_sniff := false
	for h: Dictionary in m.hydrants:
		near_pee = near_pee or absf((h.pos as Vector2).y - pee_y) < 120.0
		near_sniff = near_sniff or absf((h.pos as Vector2).y - sniff_y) < 120.0
	_check(near_pee and near_sniff and m.hydrants.size() == 2, "one hydrant at the mark station and one at the sniff station")
	var snack_off := false
	for k: Dictionary in m.kebabs:
		var kp: Vector2 = k.pos
		snack_off = kp.x < m.walk_edges(kp.y).x and absf(kp.y - TUT.at("nose")) < 160.0
	_check(m.kebabs.size() == 1 and snack_off, "the nose lesson's snack is out on the grass, off the path")
	_check(m.flock_ys.size() == 1 and absf(float(m.flock_ys[0]) - TUT.at("bark")) < 120.0, "the pigeons wait at the bark station")
	_check(m.deco_pole_count == 2, "the only posts are the vault's and the fling's")
	var fling_pole: Vector2 = m.poles[1]
	var hold_at := float(TUT.at("fling")) + float(m.TUT_HOLD_BACK)
	_check(absf(fling_pole.y - hold_at) < 200.0, "the owner waits close enough to the fling post to be wound round it")
	var pond: Rect2 = LevelBuild.tutorial_pond(m)
	_check(m.water.has(pond), "the brink lesson has its pond")
	_check(absf(m.urge_y - TUT.at("bag")) < 120.0 and m.bins.size() == 1, "the call of nature comes at the business station, a bin beside it")
	_check(m.stalls.is_empty() and m.performers.is_empty() and m.benches.is_empty(), "none of El Barri's furniture")
	# every held lesson's target is inside leash reach from where the owner
	# waits: a full leash, short of the stretch cap, from the worst spot the
	# owner can stand (their own spot if the lesson gives one, otherwise
	# either end of their weave across the path)
	var Surfaces: GDScript = load("res://world/surfaces.gd")
	var reach: float = float(m.LEASH_LENGTH) - 20.0
	var targets := {
		"pee": [(m.hydrants[0].pos as Vector2)],
		"sniff": [(m.hydrants[1].pos as Vector2)],
		"nose": [(m.kebabs[0].pos as Vector2)],
		"vault": [(m.poles[0] as Vector2)],
		"fling": [(m.poles[1] as Vector2)],
	}
	for id: String in targets.keys():
		var i: int = TUT.index_of(id)
		var hp: Vector2 = m.tut_hold_point(i)
		var spots: Array[Vector2] = []
		if hp.x < INF:
			spots.append(hp)
		else:
			var e: Vector2 = m.walk_edges(hp.y)
			var cx := (e.x + e.y) * 0.5
			var sway := minf(110.0, (e.y - e.x) * 0.5 - 60.0)
			spots.append(Vector2(cx - sway, hp.y))
			spots.append(Vector2(cx + sway, hp.y))
		for s: Vector2 in spots:
			var far := 0.0
			for t: Vector2 in targets[id]:
				far = maxf(far, s.distance_to(t))
			_check(far <= reach, "the %s lesson's target is in reach from (%.0f, %.0f): %.0f > %.0f" % [id, s.x, s.y, far, reach] if far > reach else "the %s lesson's target is in reach" % id)
	# the pond's near edge, from the brink lesson's spot
	var tp: Vector2 = m.tut_hold_point(TUT.index_of("teeter"))
	var near_pond := Vector2(clampf(tp.x, pond.position.x, pond.end.x), clampf(tp.y, pond.position.y, pond.end.y))
	_check(tp.x < INF and tp.distance_to(near_pond) <= reach,
		"the brink lesson's owner waits within reach of the pond (%.0f)" % tp.distance_to(near_pond))
	# the snack is on grass, not pavement
	var kp0: Vector2 = m.kebabs[0].pos
	_check(m.surface_at(kp0) == Surfaces.S.GRASS, "the nose lesson's snack lies on grass")

	# the owner waits at a lesson that wants them still
	m.tut_step = TUT.index_of("pull")
	m._tick_tutorial(0.0)
	var human: CharacterBody2D = m.human
	human.global_position = Vector2(m.walk_cx, TUT.at("pull") + 500.0)
	human.velocity = Vector2.ZERO
	for f in range(900):
		m.elapsed += 1.0 / 30.0
		human._walk(1.0 / 30.0)
	var stop_y: float = human.global_position.y
	_check(stop_y > TUT.at("pull") + 60.0 and stop_y < TUT.at("pull") + float(m.TUT_HOLD_BACK) + 40.0,
		"the owner walks up and waits short of the station (y %.0f)" % stop_y)
	# and walks on once the lesson moves on
	m._tut_advance(false)
	m._tick_tutorial(0.0)
	for f in range(300):
		m.elapsed += 1.0 / 30.0
		human._walk(1.0 / 30.0)
	_check(human.global_position.y < stop_y - 200.0, "and walks on when the lesson is done")

	# the nose lesson can be finished, not only skipped: from where the owner
	# waits, the dog walks to the snack and eats it
	m.started = true
	m.frozen = false
	m.tut_step = TUT.index_of("nose")
	m._tick_tutorial(0.0)
	var stand: Vector2 = m.tut_hold_point(m.tut_step)
	human.global_position = stand
	human.velocity = Vector2.ZERO
	m.leash_len = float(m.LEASH_LENGTH)
	m.dog.global_position = stand + Vector2(0.0, -40.0)
	m.dog.velocity = Vector2.ZERO
	m.leash.resnap()
	var snack: Vector2 = m.kebabs[0].pos
	var ate_before: int = m.kebabs_eaten
	m.dog.auto = true
	for f in range(900):
		m.dog.auto_move = (snack - m.dog.global_position).normalized()
		await physics_frame
		if m.kebabs_eaten > ate_before:
			break
	m.dog.auto = false
	m.dog.auto_move = Vector2.ZERO
	_check(m.kebabs_eaten > ate_before,
		"the dog reaches and eats the snack (stopped at %.0f from it)" % m.dog.global_position.distance_to(snack))

	# nothing turns up that no lesson asked for
	for i in range(600):
		await physics_frame
	_check(m.get_tree().get_nodes_in_group("squirrels").is_empty(), "no stray squirrels")
	_check(m.get_tree().get_nodes_in_group("tourists").is_empty() and m.get_tree().get_nodes_in_group("pairs").is_empty(),
		"no crowd and no other dog walkers")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_tutorial_stations: OK")
		quit(0)
	else:
		quit(1)
