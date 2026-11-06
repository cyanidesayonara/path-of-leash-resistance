extends SceneTree

# Tests for the fourth Artsy Detour: "EL DRAC" (Antoni Gaudí modernisme homage) off La Rambla.
# Covers:
# 1. Doorway placement on La Rambla and DetourLayer initialization.
# 2. Chimney-pot sculpture poles: 4 fantastical modernisme chimneys wrapped by the leash.
# 3. Entering the gallery: pair teleport, leash resnap, camera framing, surface shift to TILE.
# 4. El Drac (The Mosaic Dragon / Salamander) greeting interaction and tracking.
# 5. Golden Dragon Bone collection and Tony Hawk goal registration ("drac").
# 6. Exit portal: smooth return to La Rambla sidewalk outside gallery past entrance.
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
	game.level_id = "street"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	m._skip_title()
	await physics_frame
	await physics_frame

	print("--- TEST DETOUR DRAC ---")

	# 1. Setup & Street Doorway
	_check(m.detour_door_pos != Vector2.ZERO, "detour door pos is set on street")
	var e: Vector2 = m.walk_edges(Detour.DRAC_DOOR_Y)
	_check(m.detour_door_pos.y == Detour.DRAC_DOOR_Y, "door is at correct street y (-1850.0)")
	_check(m.detour_door_pos.x <= e.x, "doorway is recessed into the west sidewalk of La Rambla")
	_check(m.detour_layer != null, "detour visual layer is created and registered")
	_check(not m.detour_active, "detour starts inactive on the street")
	_check(not m.drac_bone_taken, "drac bone starts uncollected")
	_check(m.drac_dragon_greeted == 0, "drac dragon greeted starts at 0")

	# 2. Chimney-Pot Sculpture Poles
	_check(m.leash.pole_radii.size() == m.poles.size(),
		"leash radii match the poles (%d radii, %d poles)" % [m.leash.pole_radii.size(), m.poles.size()])
	for sp: Vector2 in Detour.lamp_points(m):
		_check(m.poles.has(sp), "chimney-pot sculpture pole at %s is a rope pole" % sp)

	# 3. Entering the Detour Gallery
	_place(m, m.detour_door_pos)
	await physics_frame
	await physics_frame

	_check(m.detour_active, "dog near doorway enters El Drac gallery")
	_check(m.detour_entered, "detour_entered is marked true")
	_check(m.detour_kind == "drac", "detour_kind is set to drac")
	var expected_entry: Vector2 = Detour.DRAC_ORIGIN + Detour.ROOM_ENTRY
	_check(m.dog.global_position.distance_to(expected_entry) < 10.0, "dog is placed at gallery entrance threshold")
	_check(m.cam_x_now > Detour.DRAC_ORIGIN.x, "camera x shifts to frame the gallery")
	_check(m.surface_at(m.dog.global_position) == Surfaces.S.TILE, "ground underfoot shifts to museum tile")
	_check(m.detour_layer.z_index < m.dog.z_index and m.detour_layer.z_index < m.human.z_index,
		"the gallery is drawn under the pair (layer z %d, dog z %d)" % [m.detour_layer.z_index, m.dog.z_index])

	# 4. El Drac Greeting
	var drac_pos: Vector2 = Detour.DRAC_ORIGIN + Detour.DRAC_SALAMANDER_POS
	_place(m, drac_pos)
	for _i in range(5):
		await physics_frame
	_check(m.drac_dragon_greeted >= 1, "stepping near El Drac greets him (%d greeted)" % m.drac_dragon_greeted)

	# 5. Human browsing inside gallery
	var room: Rect2 = Detour.DRAC_RECT
	m.human.state = m.human.HState.WALK
	m.human.event_timer = 999.0
	m.human.telegraph_t = 0.0
	m.human.bubble.visible = false
	var h_start: Vector2 = m.human.global_position
	for _i in range(300):
		await physics_frame
	_check(m.detour_active, "standing still in El Drac, she is still in the gallery")
	_check(room.has_point(m.human.global_position), "your human stays inside El Drac gallery (%s)" % m.human.global_position.round())

	# 6. Golden Dragon Bone Collection & Goal
	var G: GDScript = load("res://systems/goals.gd")
	var goal_def: Dictionary = G.defs(m)["drac"]
	_check(int(goal_def.fn.call()) == 0, "drac goal initially evaluates to 0")

	var in_play := false
	for q: Dictionary in m.active_quests:
		in_play = in_play or String(q.id) == "drac"
	_check(in_play, "the drac goal is on the walk's list")

	var bones_before: int = m.bones
	var bone_p: Vector2 = Detour.DRAC_ORIGIN + Detour.BONE_POS
	_place(m, bone_p)
	for _i in range(4):
		await physics_frame
	_check(m.run_goals_hit.has("drac"), "the drac goal is credited")
	_check(m.bones >= bones_before + 5, "and pays its bones (%d -> %d)" % [bones_before, m.bones])
	_check(m.drac_bone_taken, "touching pedestal collects the Golden Dragon Bone")
	_check(int(goal_def.fn.call()) == 1, "drac goal evaluates to 1 after collecting the bone")
	_check("drac" in G.LEVEL_GOAL_IDS["street"], "drac goal is part of street goal roster")
	_check(G.LEVEL_GOAL_IDS["street"].size() == 15, "street maintains exact 15-goal roster invariant")

	# 7. Exit Portal & Return to La Rambla
	var exit_p: Vector2 = Detour.DRAC_ORIGIN + Detour.ROOM_EXIT
	_place(m, exit_p)
	await physics_frame
	await physics_frame

	_check(not m.detour_active, "stepping into exit portal deactivates detour")
	_check(m.dog.global_position.distance_to(m.detour_return_pos) < 20.0, "pair returns to street outside gallery past entrance")
	_check(m.cam_x_now == 640.0, "camera x returns to street view (640.0)")

	# 8. Autowalk Bot Safety
	m.free()
	await physics_frame

	game.level_id = "street"
	var m2: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m2)
	m2._skip_title()
	m2.auto_walk = true
	_place(m2, m2.detour_door_pos)
	await physics_frame
	await physics_frame
	_check(not m2.detour_active, "autowalk bot ignores detour door and remains on street")
	m2.free()

	print("test_detour_drac: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
