extends SceneTree

# Every walk with the "bring Tofu home" goal hides her where Millie can reach
# her: each hiding spot on the walkable path at its own y, clear of solid
# rects, water and anything a dog collides with, and each dart between two
# spots clear of the same, so she never vanishes into a verge or a building.
# Then the whole herd is played on El Barri with the real dog and the goal
# must bank.

const DOG_MASK := 1 | 8
const EDGE_MARGIN := 22.0
const BODY_R := 12.0
const DART_STEP := 18.0

var _failures := 0
var _level: Node2D = null


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   %s" % what)
	else:
		print("  FAIL %s" % what)
		_failures += 1


func _free_node(n: Node) -> void:
	if n == null:
		return
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	n.free()


func _load_level(level_id: String) -> Node2D:
	if _level != null:
		_free_node(_level)
		_level = null
	var game = root.get_node("Game")
	game.persist = false
	game.free_play = false
	game.level_id = level_id
	game.weather = "clear"
	game.night = false
	game.menu_step = 2
	game.records = {}
	var sfx = root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.muted = true
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	_level = m
	return m


# why a point is no place for Tofu, or "" when it is fine
func _bad_at(m: Node2D, p: Vector2, margin: float) -> String:
	var e: Vector2 = m.walk_edges(p.y)
	if p.x < e.x + margin or p.x > e.y - margin:
		return "off the path (%.0f..%.0f)" % [e.x, e.y]
	for r: Rect2 in m.solid_rects:
		if r.grow(BODY_R).has_point(p):
			return "in a solid rect %s" % r
	for w: Rect2 in m.water:
		if w.has_point(p):
			return "in water %s" % w
	if m.pond.size.x > 0.0 and m.pond.has_point(p):
		return "in the pond"
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = BODY_R
	q.shape = c
	q.transform = Transform2D(0.0, p)
	q.collision_mask = DOG_MASK
	q.exclude = [m.dog.get_rid(), m.human.get_rid()]
	for hit: Dictionary in m.get_world_2d().direct_space_state.intersect_shape(q, 8):
		if hit.get("collider") is StaticBody2D:
			return "inside a body (%s)" % str(hit.get("collider"))
	return ""


func _tofu(m: Node2D) -> Node2D:
	var all: Array = m.get_tree().get_nodes_in_group("tofu")
	return all[0] if not all.is_empty() else null


func _run() -> void:
	var game = root.get_node("Game")
	var Goals: GDScript = load("res://systems/goals.gd")
	for lv: String in game.LEVELS:
		if not "tofu" in (Goals.LEVEL_GOAL_IDS.get(lv, []) as Array):
			continue
		var m := await _load_level(lv)
		_check(m.tofu_quest_active, "%s: the Tofu goal is live on a fresh save" % lv)
		var t0 := Time.get_ticks_usec()
		load("res://systems/tofu_route.gd").plan(m)
		print("    %s: planned in %.1f ms" % [lv, (Time.get_ticks_usec() - t0) / 1000.0])
		m._enter_home()
		await physics_frame
		var tf := _tofu(m)
		_check(tf != null, "%s: Tofu turns up on the way home" % lv)
		if tf == null:
			continue
		var spots: Array = tf.spots
		_check(spots.size() >= 5, "%s: she has %d hiding spots, 5 or more" % [lv, spots.size()])
		if spots.is_empty():
			continue
		var ok := true
		for i in range(spots.size()):
			var why := _bad_at(m, spots[i], EDGE_MARGIN)
			if why != "":
				print("    %s spot %d at %s: %s" % [lv, i, spots[i], why])
				ok = false
		_check(ok, "%s: all %d hiding spots are reachable ground" % [lv, spots.size()])
		var clear := true
		var routes: Array = tf.routes
		for i in range(spots.size() - 1):
			var run: Array = [spots[i]]
			if i < routes.size():
				run.append_array(routes[i])
			run.append(spots[i + 1])
			for j in range(run.size() - 1):
				var a: Vector2 = run[j]
				var b: Vector2 = run[j + 1]
				var n := maxi(1, int(a.distance_to(b) / DART_STEP))
				for k in range(1, n):
					var p := a.lerp(b, float(k) / float(n))
					var why := _bad_at(m, p, 0.0)
					if why != "":
						print("    %s dart %d->%d at %s: %s" % [lv, i, i + 1, p, why])
						clear = false
						break
		_check(clear, "%s: every dart between spots is clear" % lv)
		# the arrival freezes the walk from its line on, so her last spot must
		# come before it or the goal could never be finished
		var was_auto: bool = m.auto_walk
		m.auto_walk = false
		var arrive_y: float = load("res://systems/arrival.gd").line_y(m)
		m.auto_walk = was_auto
		_check(float(spots[spots.size() - 1].y) < arrive_y,
			"%s: her last spot is before the arrival starts (%.0f, line %.0f)" % [lv, float(spots[spots.size() - 1].y), arrive_y])

	# the whole herd, played: Millie pressed onto each spot in turn banks the goal
	var m := await _load_level("barri")
	# turned for home down from the gate, as a walk comes home: standing at
	# the start they would already be past the arrival line
	m.dog.global_position = Vector2(m.walk_cx, m.GATE_Y + 700.0)
	m.human.global_position = Vector2(m.walk_cx - 40.0, m.GATE_Y + 760.0)
	m.leash.resnap()
	m._enter_home()
	await physics_frame
	var tf := _tofu(m)
	var frames := 0
	while tf != null and not tf.home and frames < 60 * 90:
		var target: Vector2 = tf.global_position
		m.dog.global_position = target + Vector2(0.0, -60.0)
		m.dog.velocity = Vector2.ZERO
		await physics_frame
		frames += 1
	for k in range(30):
		await physics_frame
	_check(tf != null and tf.home, "barri: herded spot by spot, Tofu gets home")
	_check(m.tofu_home, "barri: main knows Tofu is home")
	_check(m.run_goals_hit.has("tofu"), "barri: the Tofu goal banks this walk")
	_check(game.goal_done("barri", "tofu"), "barri: the Tofu goal is on the record")

	_free_node(_level)
	_level = null
	if _failures > 0:
		print("test_tofu_spots: %d FAILURES" % _failures)
		quit(1)
	else:
		print("test_tofu_spots: OK")
		quit(0)
