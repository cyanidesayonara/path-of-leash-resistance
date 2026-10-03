extends SceneTree

# Natural ground is open ground, and it shows what it is
# (docs/superpowers/specs/2026-10-03-menu-terrain-design.md, pass 2):
# - on the walks with lawns, sand and water, no grass, sand, mud or water
#   sample away from the outer level edge sits inside a wall (a long strip of
#   static collision; compact props on the grass are solid on purpose)
#   (tools/terrain_audit.gd prints the full report for every walk);
# - her paws mark it: grass is flattened, mud splatters at a run, a step into
#   water rings out, never more than MARKS_MAX at once, and they expire.

const Surfaces := preload("res://world/surfaces.gd")
const OPEN_WALKS := ["barri", "park", "trail", "beach", "tutorial"]
const EDGE := 100.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _natural(k: int) -> bool:
	return k == Surfaces.S.GRASS or k == Surfaces.S.SAND or k == Surfaces.S.MUD or k == Surfaces.S.WATER


func _load(lvl: String) -> Node2D:
	root.get_node("Game").level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	for k in range(3):
		await physics_frame
	return m


func _run() -> void:
	for lvl: String in OPEN_WALKS:
		var m: Node2D = await _load(lvl)
		var space: PhysicsDirectSpaceState2D = m.get_world_2d().direct_space_state
		var q := PhysicsPointQueryParameters2D.new()
		q.collision_mask = 1
		var natural := 0
		var blocked: Array[Vector2] = []
		var y: float = m.START_Y - 20.0
		while y > m.GATE_Y + 20.0:
			var x := EDGE
			while x < 1280.0 - EDGE:
				var p := Vector2(x, y)
				if _natural(m.surface_at(p)):
					natural += 1
					q.position = p
					for r: Dictionary in space.intersect_point(q, 4):
						var c: Object = r["collider"]
						if c is CharacterBody2D:
							continue
						# what this guards against is an invisible WALL across
						# natural ground: a long strip of collision. Anything
						# compact standing on the grass (a bandstand, a beach
						# hut, a bench) is solid on purpose.
						var body := c as CollisionObject2D
						var sh: Shape2D = body.shape_owner_get_shape(body.shape_find_owner(int(r["shape"])), 0)
						if sh is RectangleShape2D and maxf((sh as RectangleShape2D).size.x, (sh as RectangleShape2D).size.y) > 600.0:
							blocked.append(p)
				x += 24.0
			y -= 48.0
		_check(natural > 100, "%s: has natural ground to sample (%d)" % [lvl, natural])
		_check(blocked.is_empty(), "%s: no natural ground inside collision: %s" % [lvl, blocked.slice(0, 6)])
		m.queue_free()
		await process_frame
	# the marks
	var m2: Node2D = await _load("park")
	var dog: CharacterBody2D = m2.dog
	m2.ground_marks.clear()
	dog.velocity = Vector2(200.0, 0.0)
	dog.surface = Surfaces.S.GRASS
	m2.mark_surface = Surfaces.S.GRASS
	for i in range(60):
		dog.global_position = Vector2(200.0 + float(i) * 30.0, -1500.0)
		m2._ground_marks()
	_check(m2.ground_marks.size() == m2.MARKS_MAX, "marks are capped (%d)" % m2.ground_marks.size())
	_check(String(m2.ground_marks[0]["kind"]) == "flat", "grass is flattened")
	m2.ground_marks.clear()
	dog.surface = Surfaces.S.MUD
	m2.mark_surface = Surfaces.S.MUD
	m2.mark_last = Vector2(INF, INF)
	m2._ground_marks()
	_check(not m2.ground_marks.is_empty() and String(m2.ground_marks[0]["kind"]) == "splat", "mud splatters at a run")
	m2.ground_marks.clear()
	dog.velocity = Vector2.ZERO
	m2.mark_surface = Surfaces.S.GRASS
	dog.surface = Surfaces.S.WATER
	m2._ground_marks()
	_check(not m2.ground_marks.is_empty() and String(m2.ground_marks[0]["kind"]) == "ring", "a step into water rings out, at any speed")
	m2.elapsed += 5.0
	m2._draw_ground_marks(-1e9, 1e9)
	_check(m2.ground_marks.is_empty(), "and the marks expire")
	m2.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_terrain: OK")
		quit(0)
	else:
		quit(1)
