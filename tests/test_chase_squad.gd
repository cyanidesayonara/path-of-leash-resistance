extends SceneTree

# A chase squad on foot (systems/chase_squad.gd), run as L'Aeroport's security
# squad (entities/aeroport_threat.gd) down the whole concourse:
# - no officer is ever inside a solid (the walk's bypasser blockers), so none
#   walks the walkway's rails, a desk or a bench
# - the line still gets the length of the hall, held up on the way
# - the catch: an officer's body and reach, the belt between neighbours in
#   formation, and getting behind the whole line; not a gap they left open
# - they kick junk out of their way
# - a continue (the anchor jumping back) puts them back in their places

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		printerr("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _inside(m: Node2D, p: Vector2, slack: float) -> String:
	for bl: Dictionary in m.bypasser_blockers:
		if bl.has("rect"):
			if (bl["rect"] as Rect2).grow(-slack).has_point(p):
				return String(bl["id"])
		elif p.distance_to(bl["center"]) < float(bl["radius"]) - slack:
			return String(bl["id"])
	return ""


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "aeroport"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = true          # no speech during the run

	var Threat: GDScript = load("res://entities/aeroport_threat.gd")
	var A: GDScript = load("res://systems/aeroport.gd")
	var t = Threat.new()
	root.add_child(t)
	t.setup(m, -4600.0, m.walk_cx, m.walk_half, 136.0)
	_check(t.squad.members.size() == 5, "five officers")

	# --- 1. down the whole hall, the pair kept well ahead ---
	var worst := ""
	var on_rail := false
	var min_pace := 1.0
	var steps := 0
	var rails: Array[Rect2] = A.balustrades()
	while t.front_y < 200.0 and steps < 60 * 90:
		t.advance(DT, 300.0, 0.0)
		t.global_position = Vector2(m.walk_cx, t.front_y)
		min_pace = minf(min_pace, t.squad.pace())
		for p: Vector2 in t.squad.points():
			var hit := _inside(m, p, 2.0)
			if hit != "" and worst == "":
				worst = "%s at %s" % [hit, p]
			for r: Rect2 in rails:
				if r.has_point(p):
					on_rail = true
			var e: Vector2 = m.walk_edges(p.y)
			if p.x < e.x - 1.0 or p.x > e.y + 1.0:
				worst = "outside the walk at %s" % p
		steps += 1
	_check(worst == "", "no officer inside a solid all the way down (%s)" % worst)
	_check(not on_rail, "no officer walks the walkway's rails")
	_check(t.front_y >= 200.0, "the line gets the length of the hall (front %.0f after %.0f s)" % [t.front_y, float(steps) * DT])
	_check(min_pace < 0.9, "and is held up on the way (slowest pace %.2f)" % min_pace)

	# --- 2. the catch ---
	t.setup(m, -2400.0, m.walk_cx, m.walk_half, 136.0)
	for k in range(90):
		t.advance(DT, 300.0, 0.0)
	var pts: Array[Vector2] = t.squad.points()
	_check(t.caught(pts[2] + Vector2(0.0, 20.0)), "an officer's body catches")
	_check(t.caught(pts[2] + Vector2(0.0, t.OFFICER_REACH)), "and what they hold out ahead")
	_check(not t.caught(pts[2] + Vector2(0.0, 200.0)), "well ahead of them is clear")
	var gap_i := -1
	for i in range(4):
		if t.squad.belt_held(i):
			gap_i = i
			break
	if gap_i >= 0:
		var mid: Vector2 = (pts[gap_i] + pts[gap_i + 1]) * 0.5 + Vector2(0.0, t.OFFICER_REACH * 0.6)
		_check(t.caught(mid), "the belt between two in formation catches")
	_check(t.caught(Vector2(m.walk_cx, t.squad.rear() - 200.0)), "behind the whole line is caught")
	# split round something, the gap is open: pull two apart by hand
	t.squad.members[1]["pos"] = pts[1] + Vector2(-120.0, 0.0)
	t.squad.members[2]["pos"] = pts[2] + Vector2(120.0, 0.0)
	var split_mid: Vector2 = ((t.squad.members[1]["pos"] as Vector2) + (t.squad.members[2]["pos"] as Vector2)) * 0.5 + Vector2(0.0, t.OFFICER_REACH * 0.6)
	_check(not t.squad.belt_held(1) and not t.caught(split_mid), "a gap they open is open")

	# --- 3. junk is kicked out of the way ---
	var Cone: GDScript = load("res://entities/cone.gd")
	var c: Node2D = Cone.new()
	m.add_child(c)
	c.setup(m, m.dog, m.human, "can")
	t.setup(m, -2400.0, m.walk_cx, m.walk_half, 136.0)
	for k in range(30):
		t.advance(DT, 300.0, 0.0)
	var lead: Dictionary = t.squad.members[2]
	c.global_position = (lead["pos"] as Vector2) + Vector2(0.0, 18.0)
	_check(t.sweep_junk([c]) >= 1 and c.vel.length() > 50.0, "a can in an officer's way is kicked (%.0f px/s)" % c.vel.length())

	# --- 4. a continue puts them back in their places ---
	t.front_y = -3600.0
	t.advance(DT, 300.0, 0.0)
	var far := 0.0
	for i in range(5):
		far = maxf(far, (t.squad.members[i]["pos"] as Vector2).distance_to(t.squad.target(i, Vector2(t.cx + t.sway, t.front_y))))
	_check(far < 140.0, "a jump back puts them in their places (furthest %.0f px off)" % far)

	if failures.is_empty():
		print("test_chase_squad: %d checks, OK" % checks)
	else:
		print("test_chase_squad: %d checks, %d FAILED" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
