extends SceneTree

# El Barri is the first walk (docs/LEVEL_DESIGN.md): open from the start and
# first in the list after the tutorial, with La Rambla now
# behind a couple of stars. It is the everyday park at the end of the
# street: no traffic, no riders, no crowd, no pickpockets, nothing that says where.

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
	_check(game.LEVELS[0] == "barri", "El Barri is the first walk")
	_check(int(game.STAR_GATE["barri"]) == 0, "and open from the start")
	_check(int(game.STAR_GATE["street"]) > 0, "La Rambla now needs stars")
	var c: Array = game.CAROUSEL
	_check(c.find("barri") == c.find("tutorial") + 1, "first in the list after the tutorial")
	_check(not "daily" in c, "the walk select has no Daily Walk")
	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(not m.rambla(), "it is not La Rambla")
	_check(m.lane_ys.is_empty(), "no traffic to cross")
	_check(m.blankets.is_empty() and m.statues.is_empty(), "none of La Rambla's clutter")
	_check(m.stall_kinds.size() == 1 and m.stall_kinds[0] == "pingpong", "the one table is the ping-pong table")
	_check(m.freedom_kind == "yard", "the off-leash area is the fenced dog park")
	# the audit fixes (#160): every piece where it belongs, in level space
	var LB: GDScript = load("res://world/level_build.gd")
	var pitch: Rect2 = LB.BARRI_PETANCA
	var pe: Vector2 = m.walk_edges(pitch.get_center().y)
	_check(pitch.position.x >= pe.x and pitch.end.x <= pe.y, "the petanca pitch lies on the gravel")
	var on_pitch: bool = m.performers.size() == 3
	for pf: Vector2 in m.performers:
		on_pitch = on_pitch and pitch.has_point(pf)
	_check(on_pitch, "the three petanca players stand on their pitch")
	var pg: Rect2 = LB.BARRI_PLAYGROUND
	_check(pg.grow(10.0).position.x > m.walk_edges(pg.get_center().y).y, "the playground is on the lawn, off the path")
	_check(m.fountains.size() == 1 and m.fountains[0] == LB.BARRI_FONT, "the drinking fountain is there")
	var left_ys: Array[float] = []
	var right_ys: Array[float] = []
	for i in range(m.deco_pole_count):
		var tp: Vector2 = m.poles[i]
		var te: Vector2 = m.walk_edges(tp.y)
		_check(tp.x - 13.0 > te.x and tp.x + 60.0 < te.y, "plane tree at %s stands with its shadow on the gravel" % tp)
		if tp.x < m.walk_cx:
			left_ys.append(tp.y)
		else:
			right_ys.append(tp.y)
	var mirrored := 0
	for ly: float in left_ys:
		for ry: float in right_ys:
			if absf(ly - ry) < 60.0:
				mirrored += 1
	_check(mirrored == 0, "the two rows of plane trees do not mirror each other (%d pairs)" % mirrored)
	_check(m.surface_at(Vector2(640.0, -2000.0)) == m.Surfaces.S.PAVEMENT, "the square's walkway is pavement")
	_check(m.surface_at(Vector2(270.0, -2000.0)) == m.Surfaces.S.GRASS, "the outer lawn is grass")
	_check(m.surface_at(Vector2(200.0, -2000.0)) == m.Surfaces.S.PAVEMENT, "past the railing is the street's pavement")
	for i in range(240):
		await physics_frame
	_check(m.get_tree().get_nodes_in_group("tourists").is_empty() and m.get_tree().get_nodes_in_group("pickpockets").is_empty(),
		"no crowd and no pickpockets")
	# no rider lane, so no riders: once a stray rider stood at x=0 off screen
	m._skip_title()
	m.auto_walk = true
	var riders := 0
	for i in range(900):
		await physics_frame
		riders = maxi(riders, m.get_tree().get_nodes_in_group("bikes").size())
	_check(riders == 0, "no riders on a walk without a rider lane (saw %d)" % riders)
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_barri: OK")
		quit(0)
	else:
		quit(1)
