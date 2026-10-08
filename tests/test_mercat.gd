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
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mercat: OK")
		quit(0)
	else:
		quit(1)
