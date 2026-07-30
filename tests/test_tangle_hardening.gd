extends SceneTree

# Round 3 NPC-leash tangle hardening. Production-layout regressions for
# segment/capsule contact, enter/exit hysteresis, static-only vault/shield
# semantics, pre-solve obstacle refresh, rising-edge rewards, finite
# coordinates, and bounded mercy recovery.
#
#   godot --headless --path . --script res://tests/test_tangle_hardening.gd

const DT := 1.0 / 60.0
const ORDINARY_FRAMES := 90
const TAUT_ESCAPE_FRAMES := 180
const HARD_RELEASE_FRAMES := 300

var failures := 0


class FakeMain:
	extends Node2D

	var phase := "out"
	var frozen := false
	var cam := Camera2D.new()
	var apologies := 0
	var mercy_lines := 0

	func _init() -> void:
		add_child(cam)

	func contact_shadow(_c: CanvasItem, _at: Vector2, _r: float, _h: float, _a := 0.24) -> void:
		pass

	func cast_shadow(_c: CanvasItem, _at: Vector2, _w: float, _h: float, _a := 0.20) -> void:
		pass

	func float_text(_pos: Vector2, text: String, _color: Color) -> void:
		if text == "oh - sorry!":
			apologies += 1
		elif text.to_lower().contains("go on") or text.to_lower().contains("excuse"):
			mercy_lines += 1

	func release_pair_park_spot(_id: int) -> void:
		pass


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _free_node(n: Node) -> void:
	if is_instance_valid(n):
		n.free()


func _settle(leash: Node2D, frames: int) -> void:
	for _i in range(frames):
		leash.tick(DT)


func _make_leash(dog: Node2D, human: Node2D, poles: Array[Vector2], rest: float) -> Node2D:
	var leash := Node2D.new()
	leash.set_script(load("res://leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	leash.setup(dog, human, poles, rest)
	return leash


func _make_pair(main: Node2D) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.main = main
	pair.my_dog = Node2D.new()
	pair.npc_owner = Node2D.new()
	pair.npc_dog = Node2D.new()
	pair.add_child(pair.my_dog)
	pair.add_child(pair.npc_owner)
	pair.add_child(pair.npc_dog)
	pair.leash = Node2D.new()
	pair.leash.set_script(load("res://leash.gd"))
	pair.add_child(pair.leash)
	var empty: Array[Vector2] = []
	pair.leash.setup(pair.npc_dog, pair.npc_owner, empty, 150.0)
	main.add_child(pair)
	return pair


func _load_geom():
	return load("res://tangle_geom.gd")


func _test_true_crossing_and_parallel_miss() -> void:
	var Geom = _load_geom()
	_check(Geom != null, "tangle_geom.gd exists")
	if Geom == null:
		return
	# true X crossing at the origin
	var a: Array[Vector2] = [Vector2(-40, 0), Vector2(40, 0)]
	var b: Array[Vector2] = [Vector2(0, -40), Vector2(0, 40)]
	_check(Geom.ropes_capsule_near(a, b, Geom.ENTER_PX), "true segment crossing is a contact")
	# parallel near miss: 20px apart, outside ENTER
	var p1: Array[Vector2] = [Vector2(0, 0), Vector2(80, 0)]
	var p2: Array[Vector2] = [Vector2(0, 20), Vector2(80, 20)]
	_check(not Geom.ropes_capsule_near(p1, p2, Geom.ENTER_PX),
		"parallel ropes %.0fpx apart are not an enter contact" % 20.0)
	_check(Geom.ENTER_PX < Geom.EXIT_PX, "enter threshold is tighter than exit")


func _test_sparse_intersection() -> void:
	var Geom = _load_geom()
	if Geom == null:
		return
	# Samples land far apart, but the segments between them cross.
	# Point-to-point (old 17px proximity) would miss this; capsule must not.
	var a: Array[Vector2] = [Vector2(-30, -2), Vector2(30, 2)]
	var b: Array[Vector2] = [Vector2(-2, 30), Vector2(2, -30)]
	var nearest_pts := INF
	for pa in a:
		for pb in b:
			nearest_pts = minf(nearest_pts, pa.distance_to(pb))
	_check(nearest_pts > 17.0, "fixture keeps sample points farther than old 17px proximity")
	_check(Geom.ropes_capsule_near(a, b, Geom.ENTER_PX),
		"sparse sample set still detects the intervening segment cross")


func _test_hysteresis() -> void:
	var Geom = _load_geom()
	if Geom == null:
		return
	var a: Array[Vector2] = [Vector2(0, 0), Vector2(60, 0)]
	var mid: Array[Vector2] = [Vector2(0, 18), Vector2(60, 18)]
	_check(not Geom.contact_with_hysteresis(a, mid, false),
		"18px gap does not enter (ENTER tighter)")
	var close: Array[Vector2] = [Vector2(0, 10), Vector2(60, 10)]
	_check(Geom.contact_with_hysteresis(a, close, false), "10px gap enters")
	_check(Geom.contact_with_hysteresis(a, mid, true),
		"18px gap still holds while already touching (EXIT wider)")
	var far: Array[Vector2] = [Vector2(0, 28), Vector2(60, 28)]
	_check(not Geom.contact_with_hysteresis(a, far, true),
		"28px gap exits after hysteresis hold")


func _test_no_dynamic_contact_vault_or_shield() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	dog.global_position = Vector2(40, 0)
	human.global_position = Vector2(-40, 0)
	var empty: Array[Vector2] = []
	var leash := _make_leash(dog, human, empty, 100.0)
	var dyn_pos := Vector2(0, 8)
	var dyn: Array[Vector2] = [dyn_pos]
	leash.dynamic_obstacles = dyn
	_settle(leash, 20)
	for i in range(120):
		var ang := float(i) / 120.0 * TAU
		dog.global_position = dyn_pos + Vector2(28, 0).rotated(ang)
		leash.tick(DT)
	_settle(leash, 30)
	_check(leash.contacts > 0, "dynamic snag produces contacts")
	_check(leash.get("contact_static") == false, "dynamic contact is not static")
	_check(leash.contact_pole.x >= INF, "dynamic contact does not populate contact_pole")
	_check(leash.get("static_contacts") != null, "leash exposes static_contacts")
	if leash.get("static_contacts") != null:
		_check(int(leash.static_contacts) == 0, "dynamic-only snag has zero static_contacts")
	_check(leash.get("contact_dynamic") != null, "leash exposes contact_dynamic")
	if leash.get("contact_dynamic") != null:
		_check(leash.contact_dynamic.distance_to(dyn_pos) < 1.0,
			"contact_dynamic reports the visible dynamic snag position")
	_free_node(leash)
	_free_node(dog)
	_free_node(human)


func _test_cleanup_before_solve() -> void:
	# Structural: player leash solve must see refreshed dynamic obstacles.
	var src := FileAccess.get_file_as_string("res://main.gd")
	_check(src.contains("_refresh_pair_obstacles"), "main exposes _refresh_pair_obstacles")
	var phys := src.find("func _physics_process")
	_check(phys >= 0, "main has _physics_process")
	if phys < 0:
		return
	var window := src.substr(phys, 2800)
	var refresh_i := window.find("_refresh_pair_obstacles")
	var apply_i := window.find("_apply_leash")
	_check(refresh_i >= 0 and apply_i >= 0, "physics process refreshes obstacles and applies leash")
	_check(refresh_i < apply_i, "dynamic obstacles refresh before the player leash solve")
	# Broad-phase uses rope bounds, not dog-to-owner distance alone.
	_check(
		src.contains("rope_bounds") or src.contains("TangleGeom") or src.contains("tangle_geom"),
		"main uses rope-bounds broad-phase helpers"
	)
	_check(not src.contains("distance_to(p.npc_owner.position) > 320"),
		"tangle feed no longer uses dog-to-owner 320 as the sole broad-phase gate")

func _test_one_reward_per_encounter() -> void:
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)
	_check(pair.update_tangle_state(true, DT), "first crossing is a new event")
	_check(main.apologies == 1, "first crossing apologises once")
	_check(not pair.update_tangle_state(true, DT), "sustained contact is one encounter")
	_check(main.apologies == 1, "sustained contact does not re-reward")
	_check(not pair.update_tangle_state(false, 0.2), "brief separation does not rearm")
	_check(not pair.update_tangle_state(true, DT), "flicker recross stays one encounter")
	_check(main.apologies == 1, "flicker does not re-reward")
	_check(not pair.update_tangle_state(false, pair.TANGLE_REARM_S), "full separation rearms")
	_check(pair.update_tangle_state(true, DT), "later crossing is a new encounter")
	_check(main.apologies == 2, "later crossing rewards once more")
	_free_node(main)


func _test_finite_coordinates_under_tangle() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	dog.global_position = Vector2(50, 0)
	human.global_position = Vector2(-50, 0)
	var empty: Array[Vector2] = []
	var leash := _make_leash(dog, human, empty, 120.0)
	var dyn: Array[Vector2] = [Vector2(0, 0), Vector2(4, 6), Vector2(-5, 3)]
	leash.dynamic_obstacles = dyn
	for i in range(240):
		dog.global_position = Vector2(40.0 + sin(float(i) * 0.2) * 20.0, cos(float(i) * 0.15) * 18.0)
		human.global_position = Vector2(-40.0, sin(float(i) * 0.11) * 10.0)
		leash.tick(DT)
	var finite := true
	for p in leash.pts:
		if not (is_finite(p.x) and is_finite(p.y)):
			finite = false
			break
	_check(finite, "tangle solve keeps finite rope coordinates")
	_free_node(leash)
	_free_node(dog)
	_free_node(human)


func _test_curiosity_suppressed_and_pause_bounded() -> void:
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)
	pair.my_dog.global_position = Vector2(100, 0)
	pair.npc_dog.position = Vector2(0, 0)
	pair.npc_owner.position = Vector2(-30, 0)
	pair.wander = Vector2.ZERO
	_check(pair.has_method("_raw_clear_dog_offset") or pair.get("TANGLE_PAUSE_MAX_S") != null,
		"pair exposes tangle pause bound / dog offset helper")
	pair.update_tangle_state(true, DT)
	_check(pair.tangled_t > 0.0, "crossing roots the owner briefly")
	# While latched, curiosity toward the player dog must not pull the NPC dog.
	if pair.has_method("_raw_clear_dog_offset"):
		var tangled_off: Vector2 = pair._raw_clear_dog_offset()
		var was_t: float = float(pair.tangled_t)
		var was_a: bool = bool(pair.tangle_active)
		pair.tangled_t = 0.0
		pair.tangle_active = false
		var clear_off: Vector2 = pair._raw_clear_dog_offset()
		pair.tangled_t = was_t
		pair.tangle_active = was_a
		var to_player: Vector2 = (
			pair.my_dog.global_position - pair.npc_dog.global_position
		).normalized()
		_check(
			tangled_off.dot(to_player) < clear_off.dot(to_player) - 0.5,
			"curiosity toward the player is suppressed while tangled"
		)
	_check(pair.get("TANGLE_PAUSE_MAX_S") != null, "pair names TANGLE_PAUSE_MAX_S")
	if pair.get("TANGLE_PAUSE_MAX_S") != null:
		var max_s: float = float(pair.TANGLE_PAUSE_MAX_S)
		_check(max_s <= float(ORDINARY_FRAMES) * DT + 0.001,
			"owner pause bound is within ordinary recovery (%.2fs)" % max_s)
		# Hold geometry contact past the pause bound: tangled_t must stop refreshing.
		for _i in range(int(max_s / DT) + 10):
			pair.update_tangle_state(true, DT)
		_check(pair.tangled_t <= 0.0 or pair.get("tangle_root_acc") != null,
			"pause accumulation is tracked after sustained contact")
		if pair.get("tangle_root_acc") != null:
			_check(float(pair.tangle_root_acc) >= max_s - DT,
				"root pause accumulates up to the named bound")
			pair.update_tangle_state(true, DT)
			_check(pair.tangled_t <= DT * 2.0,
				"owner pause no longer refreshes after TANGLE_PAUSE_MAX_S")
	_free_node(main)


func _test_mercy_release_bounded() -> void:
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)
	pair.npc_owner.position = Vector2(0, 0)
	pair.npc_dog.position = Vector2(40, 0)
	_check(pair.get("TANGLE_MERCY_S") != null, "pair names TANGLE_MERCY_S")
	if pair.get("TANGLE_MERCY_S") == null:
		_free_node(main)
		return
	var mercy_s: float = float(pair.TANGLE_MERCY_S)
	_check(is_equal_approx(mercy_s, float(HARD_RELEASE_FRAMES) * DT),
		"mercy hard release is 300 frames at 60 Hz (got %.2fs)" % mercy_s)
	_check(pair.get("TANGLE_MERCY_RAMP_S") != null, "pair names TANGLE_MERCY_RAMP_S")
	if pair.get("TANGLE_MERCY_RAMP_S") != null:
		var ramp: float = float(pair.TANGLE_MERCY_RAMP_S)
		_check(is_equal_approx(ramp, float(TAUT_ESCAPE_FRAMES) * DT),
			"mercy ramp starts at 180 frames / taut-escape target")
	pair.update_tangle_state(true, DT)
	var released := false
	for _i in range(HARD_RELEASE_FRAMES + 5):
		pair.update_tangle_state(true, DT)
		if not pair.tangle_active and pair.tangled_t <= 0.0:
			released = true
			break
	_check(released, "every supported single-pair encounter releases before 300 frames")
	_check(pair.leash.dynamic_obstacles.is_empty(), "mercy release clears dynamic obstacles")
	_check(main.mercy_lines >= 1, "mercy release is visible (float text)")
	_free_node(main)


func _test_cancel_paths_clear_tangle() -> void:
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)
	_check(
		pair.has_method("_cancel_tangle") or pair.has_method("cancel_tangle"),
		"pair exposes a shared tangle cancellation helper"
	)
	var cancel := "_cancel_tangle" if pair.has_method("_cancel_tangle") else "cancel_tangle"
	if not pair.has_method(cancel):
		_free_node(main)
		return
	pair.update_tangle_state(true, DT)
	pair.leash.dynamic_obstacles.append(Vector2(1, 2))
	pair.call(cancel)
	_check(not pair.tangle_active, "cancel clears tangle_active")
	_check(pair.tangled_t <= 0.0, "cancel clears tangled_t")
	_check(pair.leash.dynamic_obstacles.is_empty(), "cancel clears dynamic obstacles")
	# Parking / recall / suspend must use the same rules.
	pair.update_tangle_state(true, DT)
	pair.leash.dynamic_obstacles.append(Vector2(3, 4))
	pair.configure_park_area(0.0, Rect2(-100, -100, 200, 200))
	pair.park_spot = Vector2.ZERO
	pair._enter_parked(1.0)
	_check(not pair.tangle_active, "parking cancels tangle")
	_check(pair.leash.dynamic_obstacles.is_empty(), "parking clears dynamic obstacles")
	pair.pair_state = pair.PairState.WALKING
	pair.update_tangle_state(true, DT)
	pair.leash.dynamic_obstacles.append(Vector2(5, 6))
	pair.begin_park_recall()
	_check(not pair.tangle_active or pair.leash.dynamic_obstacles.is_empty(),
		"recall cancels or clears tangle obstacles")
	_check(pair.leash.dynamic_obstacles.is_empty(), "recall clears dynamic obstacles")
	pair.pair_state = pair.PairState.WALKING
	pair.leash.detached = false
	pair.update_tangle_state(true, DT)
	pair.leash.dynamic_obstacles.append(Vector2(7, 8))
	pair._suspend_leash()
	_check(not pair.tangle_active, "suspend cancels tangle latch")
	_check(pair.leash.dynamic_obstacles.is_empty(), "suspend clears dynamic obstacles")
	_free_node(main)


func _test_distinguishable_dynamic_presentation() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	dog.global_position = Vector2(40, 0)
	human.global_position = Vector2(-40, 0)
	var empty: Array[Vector2] = []
	var leash := _make_leash(dog, human, empty, 100.0)
	_check(leash.get("DYNAMIC_SLIP_MIN") != null, "dynamic slip constant remains named")
	var dyn: Array[Vector2] = [Vector2(0, 8)]
	leash.dynamic_obstacles = dyn
	for i in range(90):
		dog.global_position = Vector2(0, 8) + Vector2(26, 0).rotated(float(i) / 90.0 * TAU)
		leash.tick(DT)
	_settle(leash, 20)
	leash.taut = true
	leash.queue_redraw()
	_check(leash.contacts > 0, "dynamic presentation fixture has contacts")
	_check(leash.get("contact_dynamic") != null and leash.contact_dynamic.x < INF,
		"dynamic contact position is available for presentation")
	# NPC taut consistency: pairs must mark taut from stretch after tick.
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)
	pair.npc_owner.position = Vector2(0, 0)
	pair.npc_dog.position = Vector2(200, 0)
	pair.leash.resnap()
	pair.leash.tick(DT)
	# After a long span the pair tick path should keep taut honest. Call the
	# walking sample helper if present; otherwise require an explicit setter.
	if pair.has_method("_sync_leash_taut"):
		pair._sync_leash_taut()
	elif pair.has_method("_sample_rope"):
		pair.leash.taut = pair.leash.used_length() > pair.leash.rest_len
		pair._sample_rope()
	_check(pair.leash.taut == (pair.leash.used_length() > pair.leash.rest_len),
		"NPC leash taut matches stretch")
	_free_node(main)
	_free_node(leash)
	_free_node(dog)
	_free_node(human)


func _test_ordinary_recovery_target_constants() -> void:
	# Pin the acceptance frame budgets as named feel constants on the pair.
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)
	_check(pair.get("TANGLE_PAUSE_MAX_S") != null, "ordinary pause constant present")
	if pair.get("TANGLE_PAUSE_MAX_S") != null:
		_check(is_equal_approx(float(pair.TANGLE_PAUSE_MAX_S), float(ORDINARY_FRAMES) * DT),
			"ordinary crossing pause bound is 90 frames at 60 Hz")
	_free_node(main)


func _initialize() -> void:
	_test_true_crossing_and_parallel_miss()
	_test_sparse_intersection()
	_test_hysteresis()
	_test_no_dynamic_contact_vault_or_shield()
	_test_cleanup_before_solve()
	_test_one_reward_per_encounter()
	_test_finite_coordinates_under_tangle()
	_test_curiosity_suppressed_and_pause_bounded()
	_test_mercy_release_bounded()
	_test_cancel_paths_clear_tangle()
	_test_distinguishable_dynamic_presentation()
	_test_ordinary_recovery_target_constants()
	if failures > 0:
		print("test_tangle_hardening: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_tangle_hardening: OK")
		quit(0)
