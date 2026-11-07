extends SceneTree

# L'Eixample (systems/eixample.gd): one street of the grid, walked to the
# basilica. The street opens into an octagon at every crossing (the cut
# corners), a lamp stands on every chamfer and is a spot to mark, plane trees
# stand down the blocks, the planted islands are solid, Plaça de Gaudí's pond
# is water, and the tour group (systems/eixample_tour.gd) warns before it
# crosses, can be walked into, photographs her on a bark, and counts a near
# miss as a save.

const Eixample := preload("res://systems/eixample.gd")
const EixampleTour := preload("res://systems/eixample_tour.gd")
const Surfaces := preload("res://world/surfaces.gd")

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
	_check(game.LEVELS.has("eixample"), "L'Eixample is a walk")
	var car: Array = game.CAROUSEL
	_check(car.find("eixample") == car.find("llevant") + 1, "it comes after Platja de Llevant, as the planner has it")
	_check(int(game.STAR_GATE.get("eixample", -1)) == 16 and String(game.CHASE_GATE.get("eixample", "")) == "besos",
		"it opens at 16 stars once El Besòs is survived")
	game.level_id = "eixample"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.walk_mod == Eixample, "the walk's module is systems/eixample.gd")

	# the shape: a straight street that opens out at every crossing
	for yi: float in Eixample.XINGS:
		var x: Vector2 = m.walk_edges(yi)
		var blk: Vector2 = m.walk_edges(yi + Eixample.STREET_H + Eixample.RAMP + 120.0)
		_check(absf((x.y - x.x) - Eixample.XHALF * 2.0) < 2.0, "the octagon at %.0f is chamfer to chamfer" % yi)
		_check(absf((blk.y - blk.x) - Eixample.HALF * 2.0) < 2.0, "the block below %.0f is facade to facade" % yi)
		var mid: Vector2 = m.walk_edges(yi + Eixample.STREET_H + Eixample.RAMP * 0.5)
		_check(absf((mid.y - mid.x) * 0.5 - Eixample.half_at(yi + Eixample.STREET_H + Eixample.RAMP * 0.5)) < 2.0,
			"the chamfer at %.0f runs where the module draws it" % yi)
	var g: Vector2 = m.walk_edges(m.GATE_Y + 10.0)
	_check(g.x < m.gate_l and g.y > m.gate_r, "the gate fits the street")

	# the lamps on the corners, and the plane trees down the blocks
	var lamps := 0
	var trees := 0
	for i in range(m.deco_pole_count):
		var p: Vector2 = m.poles[i]
		var e: Vector2 = m.walk_edges(p.y)
		_check(p.x > e.x + 12.0 and p.x < e.y - 12.0, "pole at %s stands in the street" % p)
		if m.is_lamppost(i):
			lamps += 1
		elif m.pole_tree(i) == m.TREE_STREET:
			trees += 1
		for r: Rect2 in Eixample.island_rects():
			_check(not r.grow(18.0).has_point(p), "pole at %s clear of the island %s" % [p, r])
		_check(not Eixample.POND.grow(18.0).has_point(p), "pole at %s clear of the pond" % p)
	_check(lamps == Eixample.XINGS.size() * 4, "a lamp on every chamfer (%d)" % lamps)
	_check(trees >= 28, "plane trees down the blocks (%d)" % trees)
	for t: Vector2 in m.tables + m.chairs:
		var e: Vector2 = m.walk_edges(t.y)
		_check(t.x > e.x + 14.0 and t.x < e.y - 14.0, "terrace furniture at %s stands in the street" % t)

	# the islands are solid, the pond is water, the cross street is paved
	for r: Rect2 in Eixample.island_rects():
		_check(m.solid_rects.has(r), "the island %s is solid" % r)
	_check(m.water.has(Eixample.POND), "the pond is water she can get into")
	_check(m.surface_at(Eixample.POND.get_center()) == Surfaces.S.WATER, "the pond handles as water")
	_check(m.surface_at(Vector2(640.0, -1800.0)) == Surfaces.S.PAVEMENT, "the crossing handles as paving")
	_check(m.lane_ys.size() == Eixample.BIKE_XINGS.size(), "bikes ride the cross streets")

	# the corners goal counts a marked chamfer lamp once
	var spots: Array[Vector2] = Eixample.chamfer_spots(30.0)
	m.marks.clear()
	_check(Eixample.corners_marked(m) == 0, "no corner marked yet")
	m.marks.append(spots[0])
	m.marks.append(spots[0] + Vector2(3.0, 0.0))
	m.marks.append(spots[5])
	_check(Eixample.corners_marked(m) == 2, "two corners marked (%d)" % Eixample.corners_marked(m))
	var ids: Array = m.LEVEL_GOAL_IDS["eixample"]
	_check(ids.size() == 15 and ids.has("corners") and ids.has("tour") and ids.has("pond"), "fifteen goals with its own three")

	# the tour group: nothing until your human comes up the last block, a
	# warning, then the crossing
	var tour: EixampleTour = m.eixample_tour
	_check(tour != null and tour.state == EixampleTour.State.IDLE, "the tour group waits")
	m.phase = "out"
	var human: Node2D = m.human
	var dog: Node2D = m.dog
	human.global_position = Vector2(640.0, EixampleTour.TRIGGER_Y + 200.0)
	dog.global_position = Vector2(640.0, EixampleTour.TRIGGER_Y + 260.0)
	tour.tick(m, 0.1)
	_check(tour.state == EixampleTour.State.IDLE, "not while your human is a block away")
	human.global_position = Vector2(640.0, EixampleTour.TRIGGER_Y - 10.0)
	tour.tick(m, 0.1)
	_check(tour.state == EixampleTour.State.TELEGRAPH, "the guide calls the group first")
	var t := 0.0
	while tour.state == EixampleTour.State.TELEGRAPH and t < 2.0:
		tour.tick(m, 1.0 / 60.0)
		t += 1.0 / 60.0
	_check(absf(t - EixampleTour.WARN) < 0.05, "0.8 s of warning (%.2f)" % t)
	_check(tour.member_pos(0).x < m.walk_edges(EixampleTour.CROSS_Y).x, "the guide steps out from beyond the corner")
	# a bark from across the crossing: every camera comes up, once
	dog.global_position = tour.member_pos(0) + Vector2(60.0, 40.0)
	var b0: int = m.bones
	_check(tour.on_bark(m) and tour.photographed, "a bark gets her photographed")
	_check(not tour.on_bark(m), "and only once")
	_check(m.bones > b0, "and it scores")
	# your human walking into the line costs patience, once
	human.global_position = Vector2(640.0, EixampleTour.CROSS_Y)
	var pat: float = human.patience
	var crossed := 0.0
	while tour.state == EixampleTour.State.CROSSING and crossed < 20.0:
		human.global_position = Vector2(640.0, EixampleTour.CROSS_Y)
		tour.tick(m, 1.0 / 30.0)
		crossed += 1.0 / 30.0
	_check(tour.human_hit, "walking into the group bumps your human")
	_check(human.patience < pat, "and costs patience (%.2f -> %.2f)" % [pat, human.patience])
	_check(human.patience > 0.5, "but not all of it (%.2f)" % human.patience)
	_check(tour.state == EixampleTour.State.GONE, "the group gets across (%.1f s)" % crossed)
	_check(not tour.dodged, "a bump is no save")
	_check(tour.pastry_dropped, "the last tourist dropped a pastry")

	# a near miss is a save: close, then clear, never touched
	var tour2 := EixampleTour.new()
	tour2.state = EixampleTour.State.CROSSING
	tour2.lead_x = 640.0
	var saves: int = m.saves_done
	human.global_position = Vector2(680.0, EixampleTour.CROSS_Y + 40.0)
	tour2.tick(m, 0.0)
	_check(tour2.threatened and not tour2.human_hit, "a close pass is a threat")
	human.global_position = Vector2(700.0, EixampleTour.CROSS_Y + 400.0)
	tour2.tick(m, 0.0)
	_check(tour2.dodged and m.saves_done == saves + 1, "steering clear counts as a save")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_eixample: OK")
		quit(0)
	else:
		quit(1)
