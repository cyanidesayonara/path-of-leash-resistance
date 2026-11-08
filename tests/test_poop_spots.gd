extends SceneTree

# Nature calls at a point down the walk that snacks and zoomies bring sooner,
# and a dog has standards: soft ground or a tree's pit is a good spot and pays
# more than the pavement, which costs your human a little patience. A walk
# with no good spot anywhere (all paving) keeps the old rule: any spot, the
# old price, no complaint.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(level: String) -> Node2D:
	root.get_node("Game").level_id = level
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	return m


func _free(m: Node2D) -> void:
	m.queue_free()
	await process_frame


# the first point of `kind` ground across the walk, searching from y down
func _find(m: Node2D, good: bool, y0: float) -> Vector2:
	var y := y0
	while y > float(m.GATE_Y) + 200.0:
		var e: Vector2 = m.walk_edges(y)
		var x := e.x + 12.0
		while x < e.y - 12.0:
			var p := Vector2(x, y)
			if bool(m.poop_spot_good(p)) == good:
				return p
			x += 20.0
		y -= 60.0
	return Vector2(INF, INF)


func _business_at(m: Node2D, p: Vector2) -> Dictionary:
	m.dog.global_position = p
	m.poop_state = 1
	m.bones = 0
	var patience: float = m.human.patience
	m._finish_business(true)
	return {"bones": int(m.bones), "patience_lost": patience - float(m.human.patience)}


func _run() -> void:
	# El Parc: lawns and trees, so it has good spots, and its gravel path is not one
	var m: Node2D = await _load("park")
	_check(m.walk_has_good_spots(), "El Parc has good spots")
	var good := _find(m, true, -1200.0)
	var poor := _find(m, false, -1200.0)
	_check(good.x < INF and poor.x < INF, "El Parc has both good and poor spots in reach")
	var g: Dictionary = _business_at(m, good)
	_check(g.bones == m.POOP_GOOD_BONES and g.patience_lost <= 0.0001,
		"a good spot pays %d and costs no patience (got %d, %.3f)" % [m.POOP_GOOD_BONES, g.bones, g.patience_lost])
	var b: Dictionary = _business_at(m, poor)
	_check(b.bones == m.POOP_PAVE_BONES and absf(b.patience_lost - m.POOP_PAVE_PATIENCE) < 0.001,
		"the pavement pays %d and costs %.2f patience (got %d, %.3f)" % [m.POOP_PAVE_BONES, m.POOP_PAVE_PATIENCE, b.bones, b.patience_lost])
	# a tree's pit is a good spot even on paving: La Rambla's plane trees
	await _free(m)
	m = await _load("street")
	var tree := Vector2(INF, INF)
	for i in range(m.deco_pole_count):
		if m.pole_tree(i) != m.TREE_NONE:
			tree = m.poles[i]
			break
	_check(tree.x < INF, "La Rambla has a tree")
	_check(m.poop_spot_good(tree + Vector2(m.POOP_TREE_R - 8.0, 0.0)), "beside a tree's trunk is a good spot")
	# snacks and zoomies bring the call sooner, never to the start line
	m.poop_state = 0
	var before: float = m.urge_y
	m.poop_sooner(m.POOP_SNACK_PULL)
	_check(m.urge_y > before, "a snack brings the call sooner")
	for i in range(100):
		m.poop_sooner(m.POOP_SNACK_PULL)
	_check(m.urge_y <= float(m.START_Y) - m.POOP_URGE_MIN_GAP + 0.01, "never as soon as the start line")
	m.poop_state = 1
	var held: float = m.urge_y
	m.poop_sooner(m.POOP_SNACK_PULL)
	_check(is_equal_approx(m.urge_y, held), "once it has come, snacks change nothing")
	await _free(m)
	# L'Estació: all paving, no trees, so any spot is the spot at the old price
	m = await _load("station")
	_check(not m.walk_has_good_spots(), "L'Estació has no good spot")
	var s: Dictionary = _business_at(m, Vector2(640.0, -1500.0))
	_check(s.bones == m.POOP_ANY_BONES and s.patience_lost <= 0.0001,
		"on a walk with no good spot, any spot pays %d with no complaint (got %d)" % [m.POOP_ANY_BONES, s.bones])
	await _free(m)
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_poop_spots: OK")
		quit(0)
	else:
		quit(1)
