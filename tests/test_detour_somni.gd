extends SceneTree

# Tests for the first Artsy Detour: "EL SOMNI" (Dalí homage) off Carrer del Gòtic.
# Covers:
# 1. Doorway placement on Carrer del Gòtic and DetourLayer initialization.
# 2. Entering the gallery: pair teleport, leash resnap, camera framing, surface shift.
# 3. Melting lampposts droop response.
# 4. Golden Dream Bone collection and goal registration.
# 5. Exit portal: smooth return to street outside gallery past entrance.
# 6. Autowalk bot safety (leaves detour alone and follows the main walk).
# 7. Your human browses inside, staying in the room and following her.

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
	game.level_id = "oldtown"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	m._skip_title()
	await physics_frame
	await physics_frame

	print("--- TEST DETOUR SOMNI ---")

	# 1. Setup & Street Doorway
	_check(m.detour_door_pos != Vector2.ZERO, "detour door pos is set on oldtown")
	var e: Vector2 = m.walk_edges(Detour.STREET_DOOR_Y)
	_check(m.detour_door_pos.y == Detour.STREET_DOOR_Y, "door is at correct street y (-2150.0)")
	_check(m.detour_door_pos.x <= e.x, "doorway is recessed into the west wall of El Gòtic")
	_check(m.detour_layer != null, "detour visual layer is created and registered")
	_check(not m.detour_active, "detour starts inactive on the street")
	_check(not m.somni_bone_taken, "somni bone starts uncollected")

	# the lampposts are ordinary rope poles, registered with the level's
	# round posts. Added after the build, they once refilled every radius on
	# El Gotic, flattening the furniture outlines to the post size.
	_check(m.leash.pole_radii.size() == m.poles.size(),
		"leash radii match the poles (%d radii, %d poles)" % [m.leash.pole_radii.size(), m.poles.size()])
	var LB: GDScript = load("res://world/level_build.gd")
	var samples := 0
	var kept := 0
	for rr: Rect2 in m.rope_rects:
		for smp: Vector3 in LB.rect_rope_samples(rr):
			samples += 1
			var i: int = m.poles.find(Vector2(smp.x, smp.y))
			if i >= 0 and is_equal_approx(m.leash.pole_radii[i], smp.z):
				kept += 1
	_check(samples > 0 and kept == samples,
		"furniture outlines keep their own rope radii (%d of %d)" % [kept, samples])
	for lp: Vector2 in Detour.lamp_points():
		_check(m.poles.has(lp), "lamppost at %s is a rope pole" % lp)

	# 2. Entering the Detour Gallery
	_place(m, m.detour_door_pos)
	await physics_frame
	await physics_frame

	_check(m.detour_active, "dog near doorway enters the detour gallery")
	_check(m.detour_entered, "detour_entered is marked true")
	var expected_entry: Vector2 = Detour.DETOUR_ORIGIN + Detour.ROOM_ENTRY
	_check(m.dog.global_position.distance_to(expected_entry) < 10.0, "dog is placed at gallery entrance threshold")
	_check(m.cam_x_now > Detour.DETOUR_ORIGIN.x, "camera x shifts to frame the gallery")
	_check(m.surface_at(m.dog.global_position) == Surfaces.S.SAND, "ground underfoot shifts to desert sand")
	# the gallery floor was drawn over the pair (z 11 over their 10), hiding both
	_check(m.detour_layer.z_index < m.dog.z_index and m.detour_layer.z_index < m.human.z_index,
		"the gallery is drawn under the pair (layer z %d, dog z %d)" % [m.detour_layer.z_index, m.dog.z_index])
	# El Gotic's washing hangs between walk_edges, which the gallery overrides
	_check(m.overhead_pieces().is_empty(), "no street washing strung across the gallery")

	# 3. Melting Lampposts Droop Physics
	var post_pos: Vector2 = Detour.DETOUR_ORIGIN + Detour.LAMP_OFFSETS[0]
	_place(m, post_pos + Vector2(10.0, 10.0))
	for _i in range(15):
		await physics_frame
	_check(Detour.droop_t[0] > 0.3, "melting lamppost bends and droops when pair is adjacent (droop=%.2f)" % Detour.droop_t[0])

	# Moving away allows post to relax
	_place(m, expected_entry)
	for _i in range(30):
		await physics_frame
	_check(Detour.droop_t[0] < 0.2, "melting lamppost relaxes when released (droop=%.2f)" % Detour.droop_t[0])

	# 3b. In the gallery your human browses. The street's route used to march
	# them north out through the SORTIDA gap into the void, dragging her out
	# of the gallery within ten seconds of standing still.
	var room: Rect2 = Detour.ROOM_RECT
	var h_start: Vector2 = m.human.global_position
	for _i in range(600):
		await physics_frame
	_check(m.detour_active, "standing still for 10 s, she is still in the gallery")
	_check(room.has_point(m.human.global_position), "your human stays inside the gallery (%s)" % m.human.global_position.round())
	_check(m.human.global_position.distance_to(h_start) < 40.0,
		"your human browses where they are while she stands (moved %.0f px)" % m.human.global_position.distance_to(h_start))
	_check(m.human.state != m.human.HState.DRIFT or m.human.state_t > 0.0, "a typing drift ends in the gallery")
	# a phone event (a call holds them up to 21 s) would stand them still
	m.human.state = m.human.HState.WALK
	m.human.event_timer = 999.0
	m.human.telegraph_t = 0.0
	m.human.bubble.visible = false
	Input.action_press("move_left")
	for _i in range(150):
		await physics_frame
	Input.action_release("move_left")
	for _i in range(240):
		await physics_frame
	var gap: float = m.human.global_position.distance_to(m.dog.global_position)
	_check(m.human.global_position.x < h_start.x - 60.0, "your human follows her across the gallery (x %.0f -> %.0f)" % [h_start.x, m.human.global_position.x])
	_check(gap < 200.0, "and ambles up close to her (%.0f px)" % gap)
	_check(room.has_point(m.human.global_position) and m.detour_active, "still inside, still in the gallery")

	# 4. Golden Dream Bone Collection & Goal
	var G: GDScript = load("res://systems/goals.gd")
	var goal_def: Dictionary = G.defs(m)["somni"]
	_check(int(goal_def.fn.call()) == 0, "somni goal initially evaluates to 0")

	var in_play := false
	for q: Dictionary in m.active_quests:
		in_play = in_play or String(q.id) == "somni"
	_check(in_play, "the somni goal is on the walk's list")
	var bones_before: int = m.bones
	var bone_p: Vector2 = Detour.DETOUR_ORIGIN + Detour.BONE_POS
	_place(m, bone_p)
	for _i in range(4):
		await physics_frame
	# credited through the goal system like every other goal: the toast,
	# the bones and the saved star, not a bare flag
	_check(m.run_goals_hit.has("somni"), "the somni goal is credited")
	_check(m.bones >= bones_before + 5, "and pays its bones (%d -> %d)" % [bones_before, m.bones])

	_check(m.somni_bone_taken, "touching plinth collects the Golden Dream Bone")
	_check(int(goal_def.fn.call()) == 1, "somni goal evaluates to 1 after collecting the bone")
	_check("somni" in G.LEVEL_GOAL_IDS["oldtown"], "somni goal is part of oldtown goal roster")

	# 5. Exit Portal & Return to Carrer del Gòtic
	var exit_p: Vector2 = Detour.DETOUR_ORIGIN + Detour.ROOM_EXIT
	_place(m, exit_p)
	await physics_frame
	await physics_frame

	_check(not m.detour_active, "stepping into exit portal deactivates detour")
	_check(m.dog.global_position.distance_to(m.detour_return_pos) < 10.0, "pair returns to street outside gallery past entrance")
	_check(m.cam_x_now == 640.0, "camera x returns to street view (640.0)")

	# 6. Autowalk Bot Safety
	m.free()
	await physics_frame

	game.level_id = "oldtown"
	var m2: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m2)
	m2._skip_title()
	m2.auto_walk = true
	_place(m2, m2.detour_door_pos)
	await physics_frame
	await physics_frame
	_check(not m2.detour_active, "autowalk bot ignores detour door and remains on street")
	m2.free()

	print("test_detour_somni: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
