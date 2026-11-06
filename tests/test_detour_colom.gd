extends SceneTree

# Tests for the third Artsy Detour: "EL COLOM" (Pablo Picasso cubism homage) off Plaça Reial.
# Covers:
# 1. Doorway placement on Plaça Reial and DetourLayer initialization.
# 2. Sculpture poles: 4 faceted analytical cubist sculptures wrapped by the leash.
# 3. Entering the gallery: pair teleport, leash resnap, camera framing, surface shift to TILE.
# 4. Peace Doves ("Els Coloms de la Pau") greeting interaction and tracking.
# 5. Golden Cubist Bone collection and Tony Hawk goal registration ("colom").
# 6. Exit portal: smooth return to Plaça Reial west arcade outside gallery past entrance.
# 7. Autowalk bot safety (leaves detour alone and follows the main walk).
# 8. Your human browses inside, staying in the room and following her.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("  FAIL: %s" % msg)
	else:
		print("  OK: %s" % msg)


func _initialize() -> void:
	call_deferred("_run")


func _place(m: Node2D, p: Vector2) -> void:
	m.dog.global_position = p
	m.dog.velocity = Vector2.ZERO
	m.human.global_position = p + Vector2(0.0, 48.0)
	m.human.velocity = Vector2.ZERO
	if m.leash != null:
		m.leash.resnap()


func _run() -> void:
	var Detour: GDScript = load("res://systems/detour.gd")
	var Surfaces: GDScript = load("res://world/surfaces.gd")

	var game = root.get_node_or_null("Game")
	if game == null:
		failures.append("autoload Game not found")
		quit(1)
		return

	game.persist = false
	if root.has_node("Sfx"):
		root.get_node("Sfx").muted = true
	game.level_id = "reial"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	m._skip_title()
	await physics_frame
	await physics_frame

	print("--- TEST DETOUR COLOM ---")

	# 1. Setup & Street Doorway
	_check(m.detour_door_pos != Vector2.ZERO, "detour door pos is set on reial")
	var e: Vector2 = m.walk_edges(Detour.COLOM_DOOR_Y)
	_check(m.detour_door_pos.y == Detour.COLOM_DOOR_Y, "door is at correct street y (-2050.0)")
	_check(m.detour_door_pos.x <= e.x, "doorway is recessed into the west arcade of Plaça Reial")
	_check(m.detour_layer != null, "detour visual layer is created and registered")
	_check(not m.detour_active, "detour starts inactive on the street")
	_check(not m.colom_bone_taken, "colom bone starts uncollected")
	_check(m.colom_doves_greeted == 0, "colom doves greeted starts at 0")

	# 2. Cubist Sculpture Poles
	_check(m.leash.pole_radii.size() == m.poles.size(),
		"leash radii match the poles (%d radii, %d poles)" % [m.leash.pole_radii.size(), m.poles.size()])
	for sp: Vector2 in Detour.lamp_points(m):
		_check(m.poles.has(sp), "cubist sculpture pole at %s is a rope pole" % sp)

	# 3. Entering the Detour Gallery
	_place(m, m.detour_door_pos)
	await physics_frame
	await physics_frame

	_check(m.detour_active, "dog near doorway enters El Colom gallery")
	_check(m.detour_entered, "detour_entered is marked true")
	_check(m.detour_kind == "colom", "detour_kind is set to colom")
	var expected_entry: Vector2 = Detour.COLOM_ORIGIN + Detour.ROOM_ENTRY
	_check(m.dog.global_position.distance_to(expected_entry) < 10.0, "dog is placed at gallery entrance threshold")
	_check(m.cam_x_now > Detour.COLOM_ORIGIN.x, "camera x shifts to frame the gallery")
	_check(m.surface_at(m.dog.global_position) == Surfaces.S.TILE, "ground underfoot shifts to museum tile")
	_check(m.detour_layer.z_index < m.dog.z_index and m.detour_layer.z_index < m.human.z_index,
		"the gallery is drawn under the pair (layer z %d, dog z %d)" % [m.detour_layer.z_index, m.dog.z_index])

	# 4. Peace Doves Greeting
	var dove_pos: Vector2 = Detour.COLOM_ORIGIN + Detour.COLOM_DOVE_OFFSETS[0]
	_place(m, dove_pos)
	for _i in range(5):
		await physics_frame
	_check(m.colom_doves_greeted >= 1, "stepping near a peace dove greets it (%d greeted)" % m.colom_doves_greeted)

	# 5. Human browsing inside gallery
	var room: Rect2 = Detour.COLOM_RECT
	m.human.state = m.human.HState.WALK
	m.human.event_timer = 999.0
	m.human.telegraph_t = 0.0
	m.human.bubble.visible = false
	var h_start: Vector2 = m.human.global_position
	for _i in range(300):
		await physics_frame
	_check(m.detour_active, "standing still in El Colom, she is still in the gallery")
	_check(room.has_point(m.human.global_position), "your human stays inside El Colom gallery (%s)" % m.human.global_position.round())

	# 6. Golden Cubist Bone Collection & Goal
	var G: GDScript = load("res://systems/goals.gd")
	var goal_def: Dictionary = G.defs(m)["colom"]
	_check(int(goal_def.fn.call()) == 0, "colom goal initially evaluates to 0")

	var in_play := false
	for q: Dictionary in m.active_quests:
		in_play = in_play or String(q.id) == "colom"
	_check(in_play, "the colom goal is on the walk's list")

	var bones_before: int = m.bones
	var bone_p: Vector2 = Detour.COLOM_ORIGIN + Detour.BONE_POS
	_place(m, bone_p)
	for _i in range(4):
		await physics_frame
	_check(m.run_goals_hit.has("colom"), "the colom goal is credited")
	_check(m.bones >= bones_before + 5, "and pays its bones (%d -> %d)" % [bones_before, m.bones])
	_check(m.colom_bone_taken, "touching pedestal collects the Golden Cubist Bone")
	_check(int(goal_def.fn.call()) == 1, "colom goal evaluates to 1 after collecting the bone")
	_check("colom" in G.LEVEL_GOAL_IDS["reial"], "colom goal is part of reial goal roster")
	_check(G.LEVEL_GOAL_IDS["reial"].size() == 15, "reial maintains exact 15-goal roster invariant")

	# 7. Exit Portal & Return to Plaça Reial
	var exit_p: Vector2 = Detour.COLOM_ORIGIN + Detour.ROOM_EXIT
	_place(m, exit_p)
	await physics_frame
	await physics_frame

	_check(not m.detour_active, "stepping into exit portal deactivates detour")
	_check(m.dog.global_position.distance_to(m.detour_return_pos) < 10.0, "pair returns to street outside gallery past entrance")
	_check(m.cam_x_now == 640.0, "camera x returns to street view (640.0)")

	# 8. Autowalk Bot Safety
	m.free()
	await physics_frame

	game.level_id = "reial"
	var m2: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m2)
	m2._skip_title()
	m2.auto_walk = true
	_place(m2, m2.detour_door_pos)
	await physics_frame
	await physics_frame
	_check(not m2.detour_active, "autowalk bot ignores detour door and remains on street")
	m2.free()

	print("test_detour_colom: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
