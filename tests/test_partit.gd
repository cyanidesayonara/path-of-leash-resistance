extends SceneTree

# Dia de Partit (systems/partit.gd), the corridor and its set dressing: the
# walk builds clean, every solid stall, car and barrier lane stands on the
# pavement with a body and leaves your human's line clear, the barriers are
# grindable, the sidewalk trees are trees and the median's poles lamps, and
# nothing to mark, eat or win sits inside something solid.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _inside_solid(m: Node2D, p: Vector2, pad: float) -> bool:
	for r: Rect2 in m.solid_rects:
		if r.grow(pad).has_point(p):
			return true
	return false


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "partit"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var P: GDScript = load("res://systems/partit.gd")

	# the walk in the game's lists, after Montjuic
	_check(game.LEVELS.has("partit") and game.LEVELS.find("partit") > game.LEVELS.find("montjuic"), "after Montjuïc in LEVELS")
	_check(int(game.STAR_GATE["partit"]) == 27, "opens at 27 stars")
	_check(String(game.LEVEL_NAMES["partit"]) == "Dia de Partit", "named Dia de Partit")
	_check(m.gate_text == "PLAÇA DEL GOL", "the gate is PLAÇA DEL GOL")
	_check(m.freedom_kind == "placa", "it ends in a square")

	# the level check passes
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check: %s" % str(problems))

	# the shape: a narrow side street, the wide avenue, the approach bending west
	var side: Vector2 = m.walk_edges(-300.0)
	var ave: Vector2 = m.walk_edges(-2000.0)
	var app: Vector2 = m.walk_edges(-4100.0)
	_check(side.y - side.x < 500.0, "the side street is narrow (%.0f)" % (side.y - side.x))
	_check(ave.y - ave.x > 760.0, "the avenue is wide (%.0f)" % (ave.y - ave.x))
	_check((app.x + app.y) * 0.5 < 600.0, "the approach leaves the stadium the east of the view")

	# every solid: on the pavement, with a body, off your human's line
	var solids: Array = P.solids(m)
	for r: Rect2 in solids:
		var e0: Vector2 = m.walk_edges(r.position.y)
		var e1: Vector2 = m.walk_edges(r.end.y)
		_check(r.position.x >= minf(e0.x, e1.x) - 2.0 and r.end.x <= maxf(e0.y, e1.y) + 2.0,
			"solid %s stands on the pavement" % str(r))
		_check(m.solid_rects.has(r), "solid %s has a body" % str(r))
		var cy: float = r.get_center().y
		var ce: Vector2 = m.walk_edges(cy)
		var mid: float = (ce.x + ce.y) * 0.5
		_check(r.position.x > mid + 100.0 or r.end.x < mid - 100.0, "solid %s keeps clear of the middle" % str(r))
		_check(m.owner_keepouts.has(r), "your human steps round %s" % str(r))
	for i in range(solids.size()):
		for j in range(i + 1, solids.size()):
			_check(not (solids[i] as Rect2).intersects(solids[j]), "solids %d and %d do not overlap" % [i, j])

	# the barriers are rails, on the road side of the kerbs
	var runs := 0
	for rl: Dictionary in m.rails:
		if String(rl["name"]) == "BARRIER RUN":
			runs += 1
	_check(runs == P.BARRIERS.size(), "every barrier run is grindable (%d)" % runs)
	for run: Array in P.BARRIERS:
		var ey: float = (float(run[1]) + float(run[2])) * 0.5
		var be: Vector2 = m.walk_edges(ey)
		_check(float(run[0]) > be.x and float(run[0]) < be.y, "barrier at x %.0f is on the street" % float(run[0]))
		for r2: Rect2 in solids:
			_check(not Rect2(float(run[0]) - 12.0, float(run[2]), 24.0, float(run[1]) - float(run[2])).intersects(r2),
				"barrier at %.0f, %.0f is clear of %s" % [float(run[0]), float(run[1]), str(r2)])

	# trees and lamps
	for i in range(m.deco_pole_count):
		var p: Vector2 = m.poles[i]
		if P.is_street_tree(p):
			_check(m.pole_tree(i) == m.TREE_STREET, "sidewalk pole %s is a plane tree" % str(p))
		else:
			_check(m.is_lamppost(i), "pole %s is a lamppost" % str(p))
	for y: float in P.MEDIAN_YS:
		_check(P.is_street_tree(Vector2(640.0, y)) == false, "the median's poles are lamps")

	# nothing to mark, eat or win inside anything solid
	for h: Dictionary in m.hydrants:
		_check(not _inside_solid(m, h.pos, 10.0), "bollard %s is clear of solids" % str(h.pos))
	for kb: Dictionary in m.kebabs:
		_check(not _inside_solid(m, kb.pos, 6.0), "snack %s is clear of solids" % str(kb.pos))
	_check(not _inside_solid(m, m.prize_pos, 4.0), "the prize can be reached")
	var pe: Vector2 = m.walk_edges(m.prize_pos.y)
	_check(m.prize_pos.x > pe.x and m.prize_pos.x < pe.y, "the prize is on the pavement")

	# the sidewalks: as wide as the street allows, and gone past the road's end
	_check(is_equal_approx(P.sidewalk(-300.0), P.SIDE_SW), "the side street's sidewalks")
	_check(is_equal_approx(P.sidewalk(-2000.0), P.AVE_SW), "the avenue's sidewalks")
	_check(P.sidewalk(-4000.0) == 0.0, "the stadium's paving has no kerb")

	await _march(m, P)

	# the walk's name is written in sunflower seed shells
	var WS: GDScript = load("res://world/world_sign.gd")
	_check(WS.material_for("partit", "clear") == "pipes", "the name is laid in seed shells")

	print("test_partit: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _march(m: Node2D, _p) -> void:
	var day = load("res://systems/march.gd").new()
	var pair := Vector2(800.0, -2800.0)
	day.arm(pair)
	var n := 0
	while not day.warned and n < 200:
		day.advance(0.05, pair)
		n += 1
	var gap: float = pair.y - float(day.foot.end.y)
	_check(day.warned, "the siren starts")
	_check(gap / 55.0 >= 3.9, "the column is still %.2f s out when the siren starts" % (gap / 55.0))
	_check(day.holds_bot(pair), "the bot waits on the column's side")
	_check(not day.holds_bot(Vector2(500.0, pair.y)), "west of the column the bot keeps walking")
	m.march.on = true
	m.march.warned = true
	m.march.passed = false
	m.march.foot = day.foot
	m.march.horses = day.horses
	m.human.global_position = day.foot.get_center()
	m.dog.global_position = Vector2(560.0, day.foot.get_center().y)
	var y0: float = m.human.global_position.y
	var hp: int = m.phone_hp
	for _i in 25:
		await physics_frame
	_check(m.human.global_position.y > y0 + 8.0, "a human inside the column is carried south")
	_check(m.phone_hp == hp, "the column does not crack the phone")
	var lx: float = m.match_crowd._lane_x(day.foot.get_center().y, 7, 0, m.walk_edges)
	_check(lx < m.march.foot.position.x, "the river keeps west of the column")
	m.human.state = 0
	m.human.iframes = 0.0
	m.human.global_position = m.march.horses[0]
	var hp2: int = m.phone_hp
	await physics_frame
	_check(m.phone_hp == hp2 - 1, "a horse's shoulder is one crack")
	await physics_frame
	_check(m.phone_hp == hp2 - 1, "the same horse does not crack the phone twice")
	m.march._drop_in = 0.0
	m.march._drop(m, 0.0)
	var stinky := false
	for sz: Dictionary in m.substance_zones:
		if String(sz.kind) != "stinky":
			continue
		stinky = true
		var drawn: Color = (m.SUBSTANCES[String(sz.kind)] as Dictionary).col
		_check(drawn.a > 0.0, "a dropping has a colour the world can draw")
	_check(stinky and m.march.droppings.size() == 1, "a horse leaves a dropping the world knows")
