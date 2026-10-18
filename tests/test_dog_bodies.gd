extends SceneTree

# The dog's body against the world and against your human (entities/dog.gd,
# main._part_bodies):
#  1. pressed against the underside of a block, a sideways hold slides her
#     along it at a run. Grounded motion took that face for a ceiling and
#     kept her sideways speed at zero, so she crept at 5 px/s (El Mercat's
#     stall blocks, the 1.60 playtest's DOG STUCK)
#  2. the same along the top of a block, and round a column standing out of
#     a block's corner: she slides round it instead of sticking
#  3. a near head-on press into a pole, from below or above, slides her round
#     it, slowly
#  4. walked dead on into a pole with your human coming up behind, she is
#     pushed aside and does not end up inside them, and they step round her;
#     apart, nothing moves them

var checks := 0
var failures: Array[String] = []
var m: Node2D
var solids: Array[Node] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _box(center: Vector2, size: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	cs.shape = rs
	sb.add_child(cs)
	m.add_child(sb)
	sb.global_position = center
	solids.append(sb)


func _post(center: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = m.POLE_RADIUS
	cs.shape = sh
	sb.add_child(cs)
	m.add_child(sb)
	sb.global_position = center
	solids.append(sb)


func _clear() -> void:
	for s in solids:
		s.free()
	solids.clear()


# She steers by `dir` for `frames` with your human kept 70 px off, so the
# leash stays slack and only her own motion counts. Returns how far she got.
func _drive(start: Vector2, dir: Vector2, frames: int, human_off := Vector2(0, 70)) -> float:
	m.dog.global_position = start
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = start + human_off
	m.leash.resnap()
	await physics_frame
	for i in range(frames):
		m.dog.auto_move = dir
		m.dog.energy = 0.0
		m.human.event_timer = 999.0
		m.human.patience = 1.0
		m.human.global_position = m.dog.global_position + human_off
		await physics_frame
	return m.dog.global_position.distance_to(start)


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "barri"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.human.event_timer = 999.0
	await physics_frame
	m.dog.auto = true
	# well off the walk to one side, clear of everything the level built
	var o := Vector2(-6000.0, m.dog.global_position.y)

	# 1) along the underside of a block: its south face at o.y - 14
	_box(o + Vector2(0, -44), Vector2(600, 60))
	var along: float = await _drive(o, Vector2(1, 0), 60)
	_check(along > 150.0, "under a block, holding right slides her along its face (%.0f px in 1 s)" % along)
	along = await _drive(o, Vector2(-1, -0.3).normalized(), 60)
	_check(along > 150.0, "and a hold slanting into it too (%.0f px in 1 s)" % along)
	_clear()

	# 2) along the top of a block, and round a column out of its corner
	_box(o + Vector2(0, 44), Vector2(600, 60))
	along = await _drive(o, Vector2(1, 0), 60, Vector2(0, -70))
	_check(along > 150.0, "on top of a block, holding right slides her along it (%.0f px in 1 s)" % along)
	_clear()
	# El Mercat's corner: block above, its column 6 px out of the corner
	var corner := o + Vector2(60, -14)
	_box(corner + Vector2(-300, -30), Vector2(600, 60))
	_post(corner + Vector2(6, 6))
	var before: Vector2 = o + Vector2(60 - 6 - 24.0, 0)
	await _drive(before, Vector2(1, 0), 60)
	_check(m.dog.global_position.x > corner.x + 30.0,
		"against the block, holding right takes her round its corner column (x %.0f, column at %.0f)" % [
			m.dog.global_position.x, corner.x + 6.0])
	_clear()

	# 3) a near head-on press into a pole: 8 degrees off dead on
	_post(o + Vector2(0, -24))
	var slid: float = await _drive(o + Vector2(0, 0), Vector2(0, -1).rotated(deg_to_rad(8.0)), 90)
	_check(m.dog.global_position.y < o.y - 30.0,
		"pressing nearly dead on into a pole, she slides round it (%.0f px, now at y %+.0f)" % [
			slid, m.dog.global_position.y - o.y])
	_clear()
	# and from above, pressing down onto one
	_post(o + Vector2(0, 24))
	slid = await _drive(o, Vector2(0, 1).rotated(deg_to_rad(8.0)), 90, Vector2(0, -70))
	_check(m.dog.global_position.y > o.y + 30.0,
		"pressing nearly dead on down onto a pole, she slides round it (%.0f px, now at y %+.0f)" % [
			slid, m.dog.global_position.y - o.y])
	_clear()

	# 4) she stops against a pole, your human walks up into her from behind
	var pole := o + Vector2(0, -24)
	_post(pole)
	m.dog.global_position = o
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = o + Vector2(0, 80)
	m.leash.resnap()
	await physics_frame
	var closest := INF
	for i in range(120):
		m.dog.auto_move = Vector2(0, -1)
		m.dog.energy = 0.0
		m.human.event_timer = 999.0
		m.human.patience = 1.0
		# them walking straight at her, at their own pace, every frame
		m.human.global_position += (m.dog.global_position - m.human.global_position).normalized() * 1.5
		await physics_frame
		closest = minf(closest, m.dog.global_position.distance_to(m.human.global_position))
	_check(closest > 20.0, "your human walking into her, she is never inside them (closest %.1f px)" % closest)
	_check(m.dog.global_position.distance_to(pole) > 23.0, "and she is not pushed into the pole")
	_check(absf(m.human.global_position.x - o.x) > 8.0,
		"with her against the pole, they step aside round her (%.0f px off her line)" % absf(m.human.global_position.x - o.x))
	_clear()

	# apart, nothing moves either of them
	m.dog.global_position = o
	m.human.global_position = o + Vector2(40, 0)
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	m._part_bodies()
	_check(m.dog.global_position == dp and m.human.global_position == hp,
		"40 px apart, neither is pushed")
	# overlapping, both move, she the further
	m.human.global_position = o + Vector2(10, 0)
	hp = m.human.global_position
	m._part_bodies()
	var dog_moved: float = m.dog.global_position.distance_to(dp)
	var human_moved: float = m.human.global_position.distance_to(hp)
	_check(dog_moved > human_moved and human_moved > 0.0,
		"10 px apart, both give way and she gives the more (%.1f, %.1f)" % [dog_moved, human_moved])
	_check(m.dog.global_position.x < dp.x, "she is pushed away from them, not through them")

	# she is against a wall they are walking her into: they sidestep round her
	_box(o + Vector2(0, -44), Vector2(300, 60))
	# the new box is in the physics space from the next step
	await physics_frame
	m.dog.global_position = o
	m.human.global_position = o + Vector2(0, 12)
	m.human.sidestep_t = 0.0
	m.human.walk_intent = Vector2(0, -90)
	m._part_bodies()
	_check(m.human.sidestep_t > 0.0, "walked into her where a wall holds her, they start a sidestep")
	_clear()

	m.free()
	print("test_dog_bodies: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
