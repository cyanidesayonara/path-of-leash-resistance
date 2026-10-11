extends SceneTree

# El Mercat is its own market hall (docs/LEVEL_DESIGN.md): in off the street
# under the arch into a hall much wider than the street; stall blocks down
# the middle that are solid, with the owner keeping to one aisle round each;
# an iron column at every block corner to wind the leash on; stalls along
# the walls, the fish counter among them with meltwater and scales in front;
# the arches drawn over everyone; and no van parked indoors. Since #153: the
# wall stalls stand against the walls, the drain is a floor drain and not a
# manhole, crates, trolleys and shoppers along the walls are solid and clear
# of the stalls and the marking spots, and the approach street has its
# delivery van.

var LevelBuild: GDScript

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


# the clear distance between two solids: a Rect2, or a circle as
# Vector3(x, y, radius); negative where they overlap
func _gap(a: Variant, b: Variant) -> float:
	if a is Vector3 and b is Vector3:
		return Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y)) - a.z - b.z
	if a is Vector3:
		return _gap(b, a)
	var ra: Rect2 = a
	if b is Vector3:
		var p := Vector2(b.x, b.y)
		var q := Vector2(clampf(p.x, ra.position.x, ra.end.x), clampf(p.y, ra.position.y, ra.end.y))
		return p.distance_to(q) - b.z
	var rb: Rect2 = b
	var dx := maxf(0.0, maxf(ra.position.x - rb.end.x, rb.position.x - ra.end.x))
	var dy := maxf(0.0, maxf(ra.position.y - rb.end.y, rb.position.y - ra.end.y))
	if dx == 0.0 and dy == 0.0:
		return -1.0
	return Vector2(dx, dy).length()


# something stands against the wall in this band, so it is no probe of the wall
func _crowded(m: Node2D, band: Rect2) -> bool:
	for st: Vector2 in m.stalls:
		if band.intersects(Rect2(st - m.STALL_BODY_SIZE * 0.5, m.STALL_BODY_SIZE).grow(20.0)):
			return true
	for r: Rect2 in m.solid_rects:
		if band.intersects(r.grow(20.0)):
			return true
	var pts: Array = []
	for i in range(m.body_pole_count):
		pts.append(m.poles[i])
	for h: Dictionary in m.hydrants:
		pts.append(h.pos)
	pts.append_array(m.fountains)
	pts.append_array(m.performers)
	for p: Vector2 in pts:
		if band.grow(36.0).has_point(p):
			return true
	return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "market"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var street: Vector2 = m.walk_edges(-200.0)
	var hall: Vector2 = m.walk_edges(-2800.0)
	_check(hall.y - hall.x > (street.y - street.x) + 250.0, "the hall is much wider than the street outside")
	_check(m.islands.size() == LevelBuild.MERCAT_BLOCKS.size(), "the owner keeps to an aisle round every stall block")
	_check(m.deco_pole_count == LevelBuild.MERCAT_BLOCKS.size() * 4, "an iron column at every block corner")
	_check(m.furgoneta.x >= INF, "no van parked inside the hall")
	var kinds := {}
	for k: String in m.stall_kinds:
		kinds[k] = true
	_check(kinds.has("fish") and kinds.has("fruit") and kinds.has("jamon"), "fruit, fish and jamon stalls on the walls")
	var melt := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "puddle" or String(pt["kind"]) == "fish":
			melt += 1
	_check(melt >= 4, "meltwater and scales in front of the fish counters (%d)" % melt)
	var over: Array = m.get_children().filter(func(c: Node) -> bool: return c.get_script() == load("res://world/overheadlayer.gd"))
	_check(over.size() == 1 and (over[0] as Node2D).z_index > m.dog.z_index, "the arches are drawn over everyone")
	# a stall block is solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var blk: Rect2 = LevelBuild.MERCAT_BLOCKS[1]
	dog.global_position = Vector2(blk.get_center().x, blk.end.y + 40.0)
	for i in range(40):
		dog.velocity = Vector2(0, -400)
		dog.move_and_slide()
	_check(not blk.grow(-4.0).has_point(dog.global_position), "a stall block stops the dog")
	_check(m.hydrants.size() >= 4, "enough crate stacks to mark")
	# the wall stalls stand with their backs against the hall's walls
	for i in range(LevelBuild.MERCAT_WALL_STALLS.size()):
		var st: Vector2 = m.stalls[i]
		var we: Vector2 = m.walk_edges(st.y)
		var sr := Rect2(st - m.STALL_BODY_SIZE * 0.5, m.STALL_BODY_SIZE)
		var gap: float = sr.position.x - we.x if bool(LevelBuild.MERCAT_WALL_STALLS[i][1]) else we.y - sr.end.x
		_check(absf(gap) <= 2.0, "wall stall %d stands against the wall (gap %.0f)" % [i, gap])
	# a floor drain, not an open manhole
	_check(m.manholes.is_empty(), "no street manhole in the hall")
	# the side aisles: everything along the walls is solid and in the clear
	var Mercat: GDScript = load("res://world/mercat.gd")
	var dressing: Array = Mercat.solids(m)
	_check(dressing.size() >= 12, "crates, trolleys and shoppers along the walls (%d)" % dressing.size())
	for r: Rect2 in dressing:
		_check(m.solid_rects.has(r), "solid: %s" % r)
		var re: Vector2 = m.walk_edges(r.get_center().y)
		_check(r.position.x >= re.x - 1.0 and r.end.x <= re.y + 1.0, "inside the walls: %s" % r)
		for st: Vector2 in m.stalls:
			_check(not r.grow(8.0).intersects(Rect2(st - m.STALL_BODY_SIZE * 0.5, m.STALL_BODY_SIZE)),
				"%s clear of the stall at %s" % [r, st])
		for h: Dictionary in m.hydrants:
			_check(not r.grow(24.0).has_point(h.pos), "%s clear of the crate stack to mark at %s" % [r, h.pos])
		for p: Vector2 in m.bins + m.fountains + m.cone_spots:
			_check(not r.grow(20.0).has_point(p), "%s clear of %s" % [r, p])
		for bk: Rect2 in LevelBuild.MERCAT_BLOCKS:
			_check(not r.grow(120.0).intersects(bk), "%s leaves the aisle by block %s open" % [r, bk])
	# the delivery van stands on the street outside, not in the hall
	_check(m.vans.size() == 1 and m.vans[0].y > LevelBuild.MERCAT_ARCH_Y, "the delivery van is outside the arch")
	# the stall blocks are in the blockers every walker and rider routes round
	for bi in range(LevelBuild.MERCAT_BLOCKS.size()):
		var found := false
		for bl: Dictionary in m.bypasser_blockers:
			if bl.has("rect") and Rect2(bl["rect"]).encloses(LevelBuild.MERCAT_BLOCKS[bi]):
				found = true
		_check(found, "stall block %d is an NPC blocker" % bi)
	# a passing pair, walking up the hall from either aisle or the middle,
	# steers round every block rather than crossed the food
	for sx: float in [450.0, 640.0, 830.0]:
		for dir: float in [-1.0, 1.0]:
			var route: RefCounted = load("res://systems/bypasser_route.gd").new(sx, m.walk_cx - m.walk_half + 30.0,
				m.walk_cx + m.walk_half - 30.0, 48.0, 90.0, 240.0, 1.35)
			route.configure_blockers(m.bypasser_blockers)
			var rp := Vector2(sx, LevelBuild.MERCAT_ARCH_Y - 60.0 if dir < 0.0 else LevelBuild.MERCAT_DOOR_Y + 60.0)
			var end_y: float = LevelBuild.MERCAT_DOOR_Y + 60.0 if dir < 0.0 else LevelBuild.MERCAT_ARCH_Y - 60.0
			var crossed := ""
			var steps := 0
			while dir * (end_y - rp.y) > 0.0 and steps < 6000:
				steps += 1
				var res: Dictionary = route.step(rp, dir * 110.0, 1.0 / 60.0)
				rp.x = float(res.x)
				if not bool(res.blocked):
					rp.y += dir * 110.0 / 60.0
				for bk: Rect2 in LevelBuild.MERCAT_BLOCKS:
					if crossed == "" and bk.grow(6.0).has_point(rp):
						crossed = str(rp)
			_check(crossed == "", "a pair from x=%.0f going %s keeps off the stall blocks (%s)" % [
				sx, "up" if dir < 0.0 else "down", crossed])
			_check(steps < 6000, "and gets through the hall from x=%.0f" % sx)
	# no pinches in the hall: between any two solids there is either room for
	# your human (a body 30 across, and some) or no gap at all
	var shapes: Array = []
	for bk: Rect2 in LevelBuild.MERCAT_BLOCKS:
		shapes.append(bk)
	for st: Vector2 in m.stalls:
		shapes.append(Rect2(st - m.STALL_BODY_SIZE * 0.5, m.STALL_BODY_SIZE))
	for r: Rect2 in Mercat.solids(m):
		shapes.append(r)
	for i in range(m.body_pole_count):
		shapes.append(Vector3(m.poles[i].x, m.poles[i].y, m.POLE_RADIUS))
	for f: Vector2 in m.fountains:
		shapes.append(Vector3(f.x, f.y, m.FOUNTAIN_RADIUS))
	for pf: Vector2 in m.performers:
		shapes.append(Vector3(pf.x, pf.y, m.PERFORMER_RADIUS))
	for i in range(shapes.size()):
		for j in range(i + 1, shapes.size()):
			var g := _gap(shapes[i], shapes[j])
			_check(g <= 1.0 or g >= 40.0, "no pinch between %s and %s (%.0f px)" % [shapes[i], shapes[j], g])
	# she can walk right up to the drawn walls, in the hall and on the street:
	# nothing invisible stands inside them (#153's straight wall stood 130 px in)
	var probes := 0
	var py := 140.0
	while py > LevelBuild.MERCAT_DOOR_Y + 120.0:
		var pe: Vector2 = m.walk_edges(py)
		for side: float in [-1.0, 1.0]:
			var wall_x: float = pe.x if side < 0.0 else pe.y
			var band := Rect2(minf(wall_x, wall_x - side * 200.0), py - 34.0, 200.0, 68.0)
			if _crowded(m, band):
				continue
			probes += 1
			dog.global_position = Vector2(wall_x - side * 180.0, py)
			for k in range(80):
				dog.velocity = Vector2(side * 400.0, 0.0)
				dog.move_and_slide()
			var gap: float = absf(wall_x - dog.global_position.x)
			_check(gap <= 14.0 + 6.0 + 3.0, "she reaches the %s wall at y=%.0f (stops %.0f px short)" % [
				"west" if side < 0.0 else "east", py, gap])
			_check(side * (dog.global_position.x - wall_x) < 0.0, "and stays inside it at y=%.0f" % py)
		py -= 50.0
	_check(probes >= 30, "enough clear wall to probe (%d)" % probes)
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mercat: OK")
		quit(0)
	else:
		quit(1)
