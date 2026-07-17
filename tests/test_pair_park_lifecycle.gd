extends SceneTree

const DT := 1.0 / 60.0
const GATE_Y := 0.0
const GATE_EXIT_Y := 80.0
const PARK_BOUNDS := Rect2(20.0, -260.0, 360.0, 230.0)
const PARK_SPOT := Vector2(300.0, -90.0)
const WALKING := 0
const ARRIVING := 1
const PARKED := 2
const RECALLING := 3
const DEPARTING := 4

var failures := 0
var fixtures: Array[Node] = []
var created_pairs := 0


class FakeMain:
	extends Node2D

	var phase := "out"
	var frozen := false
	var cam := Node2D.new()
	var released_pair_ids: Array[int] = []
	var apologies := 0

	func _init() -> void:
		add_child(cam)

	func release_pair_park_spot(pair_instance_id: int) -> void:
		released_pair_ids.append(pair_instance_id)

	func float_text(_position: Vector2, text: String, _color: Color) -> void:
		if text == "oh - sorry!":
			apologies += 1


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _required_api(pair: Node2D) -> bool:
	var valid := true
	for method in [
		"configure_park_area",
		"begin_park_arrival",
		"initialize_parked_departure",
		"begin_park_recall",
		"get_pair_state",
		"is_park_lifecycle_active",
		"has_park_slot",
	]:
		var present := pair.has_method(method)
		_check(present, "pair exposes " + method)
		valid = valid and present
	return valid


func _make_main(phase := "out") -> FakeMain:
	var main := FakeMain.new()
	main.phase = phase
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	return main


func _make_pair(
	main: FakeMain,
	start := Vector2(200.0, 120.0),
	direction := Vector2.UP
) -> Node2D:
	var player_dog := Node2D.new()
	player_dog.visible = false
	player_dog.position = Vector2(1000.0, 1000.0)
	root.add_child(player_dog)
	fixtures.append(player_dog)

	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.visible = false
	var poles: Array[Vector2] = []
	pair.setup(main, player_dog, poles, start, direction)
	var blockers: Array[Dictionary] = []
	var configured := bool(pair.configure_route(start.x, 20.0, 380.0, blockers))
	_check(configured, "pair route configures")
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)
	created_pairs += 1
	main.cam.position = pair.npc_owner.position
	return pair


func _state(pair: Node2D) -> int:
	return int(pair.get_pair_state()) if pair.has_method("get_pair_state") else -1


func _tick(pair: Node2D, delta := DT, follow_camera := true) -> void:
	if follow_camera:
		pair.main.cam.position = pair.npc_owner.position
	pair._physics_process(delta)


func _tick_until_state(pair: Node2D, expected: int, frames := 1200) -> bool:
	for _frame in range(frames):
		_tick(pair)
		if _state(pair) == expected:
			return true
	return false


func _inside_inclusive(bounds: Rect2, point: Vector2) -> bool:
	return (
		point.x >= bounds.position.x
		and point.x <= bounds.end.x
		and point.y >= bounds.position.y
		and point.y <= bounds.end.y
	)


func _rope_points_equal(first: Array[Vector2], second: Array[Vector2]) -> bool:
	if first.size() != second.size():
		return false
	for index in range(first.size()):
		if not first[index].is_equal_approx(second[index]):
			return false
	return true


func _test_interface_and_explicit_arrival() -> void:
	var main := _make_main("freedom")
	var pair := _make_pair(main, Vector2(200.0, 30.0), Vector2.UP)
	if not _required_api(pair):
		return
	var state_constants: Dictionary = pair.get_script().get_script_constant_map().get("PairState", {})
	_check(
		state_constants == {
			"WALKING": WALKING,
			"ARRIVING": ARRIVING,
			"PARKED": PARKED,
			"RECALLING": RECALLING,
			"DEPARTING": DEPARTING,
		},
		"PairState exposes the required ordered lifecycle"
	)
	pair.configure_park_area(GATE_Y, PARK_BOUNDS)
	for _frame in range(90):
		_tick(pair)
	_check(_state(pair) == WALKING, "configured upward traffic does not auto-reserve")
	_check(not pair.is_queued_for_deletion(), "configured pair persists through freedom")
	_check(not bool(pair.has_park_slot()), "walking pair owns no park slot")
	_check(pair.update_tangle_state(true, DT), "pre-arrival crossing starts one tangle event")
	_check(main.apologies == 1, "pre-arrival crossing rewards once")
	_check(
		not pair.update_tangle_state(false, 0.2),
		"partial pre-arrival separation emits no event"
	)
	var clear_before_arrival: float = pair.tangle_clear_t
	_check(bool(pair.begin_park_arrival(3, PARK_SPOT)), "latched pair starts arrival")
	_check(pair.tangle_active, "arrival preserves the active tangle latch")
	_check(
		is_equal_approx(pair.tangle_clear_t, clear_before_arrival),
		"arrival preserves accumulated tangle separation"
	)
	_check(
		not pair.update_tangle_state(true, DT),
		"arrival crossing does not duplicate the latched tangle event"
	)
	_check(main.apologies == 1, "arrival crossing does not duplicate the reward")
	_check(
		not pair.update_tangle_state(false, pair.TANGLE_REARM_S - 0.01),
		"short arrival separation keeps the event latched"
	)
	_check(pair.tangle_active, "arrival latch waits for the full separation dwell")
	_check(
		not pair.update_tangle_state(false, 0.01),
		"full arrival separation only rearms the event"
	)
	_check(not pair.tangle_active, "arrival latch rearms after normal separation dwell")
	_check(pair.update_tangle_state(true, DT), "later arrival crossing is a new event")
	_check(main.apologies == 2, "later arrival crossing rewards exactly once")

	var unconfigured_main := _make_main("freedom")
	var unconfigured := _make_pair(unconfigured_main)
	_tick(unconfigured, 0.0)
	_check(
		unconfigured.is_queued_for_deletion(),
		"ordinary unconfigured freedom cleanup remains intact"
	)


func _test_arrival_reaches_persistent_parked_pair() -> void:
	var main := _make_main("freedom")
	var pair := _make_pair(main)
	if not _required_api(pair):
		return
	pair.configure_park_area(GATE_Y, PARK_BOUNDS)
	var owner_id: int = pair.npc_owner.get_instance_id()
	var dog_id: int = pair.npc_dog.get_instance_id()
	var leash_id: int = pair.leash.get_instance_id()
	var owner_color: Color = pair.owner_col
	var dog_color: Color = pair.dog_col
	var pair_id := pair.get_instance_id()
	var started := bool(pair.begin_park_arrival(7, PARK_SPOT))
	_check(started, "reserved arrival starts")
	_check(_state(pair) == ARRIVING, "arrival enters ARRIVING")
	_check(bool(pair.is_park_lifecycle_active()), "arrival reports active lifecycle")
	_check(bool(pair.has_park_slot()), "arrival holds the supplied slot")

	var owner_before: Vector2 = pair.npc_owner.position
	_tick(pair)
	_check(
		pair.npc_owner.position.distance_to(owner_before) <= pair.PARK_OWNER_SPEED * DT + 0.001,
		"arrival owner movement is bounded"
	)
	_check(pair.leash.visible, "arrival keeps leash visible")
	_check(not bool(pair.leash.detached), "arrival keeps leash attached")
	_check(not pair.sampled.is_empty(), "arrival continues sampling the real rope")
	pair.main.cam.position = Vector2(10000.0, 10000.0)
	_tick(pair, DT, false)
	_check(not pair.is_queued_for_deletion(), "arrival is immune to path despawn")
	pair.main.cam.position = pair.npc_owner.position
	pair.leash.dynamic_obstacles.append(Vector2(123.0, 456.0))
	var arrival_motion_bounded := true
	var reached_parked := false
	for _frame in range(1200):
		var arrival_owner_before: Vector2 = pair.npc_owner.position
		_tick(pair)
		arrival_motion_bounded = arrival_motion_bounded and (
			pair.npc_owner.position.distance_to(arrival_owner_before)
				<= pair.PARK_OWNER_SPEED * DT + 0.001
		)
		if _state(pair) == PARKED:
			reached_parked = true
			break
	_check(reached_parked, "arrival reaches PARKED")
	_check(arrival_motion_bounded, "arrival completion never snaps beyond its movement cap")

	_check(pair.npc_owner.position.is_equal_approx(PARK_SPOT), "owner reaches assigned spot")
	_check(not pair.leash.visible, "parked leash is hidden")
	_check(bool(pair.leash.detached), "parked leash is detached")
	_check(pair.sampled.is_empty(), "parked rope samples are empty")
	_check(pair.leash.dynamic_obstacles.is_empty(), "parking clears dynamic rope obstacles")
	_check(pair.npc_owner.get_instance_id() == owner_id, "owner identity persists")
	_check(pair.npc_dog.get_instance_id() == dog_id, "dog identity persists")
	_check(pair.leash.get_instance_id() == leash_id, "leash identity persists")
	_check(pair.get_instance_id() == pair_id, "pair instance identity persists")
	_check(pair.owner_col == owner_color, "owner color persists")
	_check(pair.dog_col == dog_color, "dog color persists")

	var parked_owner: Vector2 = pair.npc_owner.position
	var parked_rope_points: Array[Vector2] = pair.leash.pts.duplicate()
	pair.park_stay_t = 100.0
	pair.wander_t = 0.0
	for _frame in range(240):
		_tick(pair)
		_check(
			_inside_inclusive(PARK_BOUNDS, pair.npc_dog.position),
			"parked dog stays inside configured bounds"
		)
	_check(pair.npc_owner.position.is_equal_approx(parked_owner), "parked owner remains fixed")
	_check(pair.sampled.is_empty(), "parked movement never samples the rope")
	_check(
		_rope_points_equal(parked_rope_points, pair.leash.pts),
		"parked movement leaves suspended rope points unchanged"
	)
	pair.leash.dynamic_obstacles.append(Vector2(123.0, 456.0))
	_tick(pair)
	_check(pair.leash.dynamic_obstacles.is_empty(), "parked tick rejects stale rope obstacles")
	pair.main.cam.position = Vector2(10000.0, 10000.0)
	_tick(pair, DT, false)
	_check(not pair.is_queued_for_deletion(), "parked pair is immune to path despawn")


func _make_parked_fixture(
	main: FakeMain,
	slot_id: int,
	dog_position: Vector2,
	stay_time: float
) -> Node2D:
	var pair := _make_pair(main)
	if not _required_api(pair):
		return pair
	pair.configure_park_area(GATE_Y, PARK_BOUNDS)
	var initialized := bool(
		pair.initialize_parked_departure(slot_id, PARK_SPOT, dog_position, stay_time)
	)
	_check(initialized, "already-parked departure fixture initializes")
	_check(_state(pair) == PARKED, "fixture initializes in PARKED")
	return pair


func _test_timer_home_and_idempotent_recall() -> void:
	var timer_main := _make_main("freedom")
	var timer_pair := _make_parked_fixture(
		timer_main,
		11,
		Vector2(60.0, -220.0),
		0.0
	)
	if not timer_pair.has_method("get_pair_state"):
		return
	_tick(timer_pair)
	_check(_state(timer_pair) == RECALLING, "park timer expiry starts recall")

	var home_main := _make_main("freedom")
	var home_pair := _make_parked_fixture(
		home_main,
		12,
		Vector2(340.0, -220.0),
		100.0
	)
	if not home_pair.has_method("get_pair_state"):
		return
	home_main.phase = "home"
	_tick(home_pair)
	_check(_state(home_pair) == RECALLING, "home phase starts recall")
	var held_owner: Vector2 = home_pair.npc_owner.position
	home_pair.begin_park_recall()
	home_pair.begin_park_recall()
	_check(_state(home_pair) == RECALLING, "begin recall is idempotent")
	_check(home_pair.npc_owner.position.is_equal_approx(held_owner), "recall keeps owner fixed")
	home_pair.main.cam.position = Vector2(10000.0, 10000.0)
	_tick(home_pair, DT, false)
	_check(not home_pair.is_queued_for_deletion(), "recall is immune to path despawn")

	var arrival_main := _make_main("freedom")
	var arrival_pair := _make_pair(arrival_main)
	arrival_pair.configure_park_area(GATE_Y, PARK_BOUNDS)
	_check(
		bool(arrival_pair.begin_park_arrival(13, PARK_SPOT)),
		"home-during-arrival fixture starts arrival"
	)
	for _frame in range(10):
		_tick(arrival_pair)
	var interrupted_owner: Vector2 = arrival_pair.npc_owner.position
	arrival_pair.npc_dog.position = interrupted_owner + Vector2(100.0, 0.0)
	arrival_pair.leash.dynamic_obstacles.append(Vector2(222.0, 333.0))
	var interrupted_rope_points: Array[Vector2] = arrival_pair.leash.pts.duplicate()
	arrival_main.phase = "home"
	_tick(arrival_pair, 0.0)
	_check(_state(arrival_pair) == RECALLING, "home phase interrupts an active arrival")
	_check(
		arrival_pair.npc_owner.position.is_equal_approx(interrupted_owner),
		"arrival interruption fixes owner at the recall point"
	)
	_check(not arrival_pair.leash.visible, "arrival interruption hides the leash immediately")
	_check(bool(arrival_pair.leash.detached), "arrival interruption detaches the leash immediately")
	_check(arrival_pair.sampled.is_empty(), "arrival interruption clears rope samples immediately")
	_check(
		arrival_pair.leash.dynamic_obstacles.is_empty(),
		"arrival interruption clears dynamic rope obstacles immediately"
	)
	for _frame in range(5):
		_tick(arrival_pair)
	_check(not arrival_pair.leash.visible, "interrupted recall keeps the leash hidden")
	_check(bool(arrival_pair.leash.detached), "interrupted recall keeps the leash detached")
	_check(arrival_pair.sampled.is_empty(), "interrupted recall keeps rope samples empty")
	_check(
		_rope_points_equal(interrupted_rope_points, arrival_pair.leash.pts),
		"interrupted recall leaves suspended rope points unchanged"
	)


func _test_recall_attach_gate_release_and_route_resume() -> void:
	var main := _make_main("out")
	var pair := _make_pair(main)
	var stale_blockers: Array[Dictionary] = [
		{"id": "stale_arrival_detour", "center": Vector2(200.0, 0.0), "radius": 20.0},
	]
	pair.route.call("configure_blockers", stale_blockers)
	_tick(pair)
	_check(int(pair.route.detour_side) != 0, "fixture activates a real pre-arrival detour")
	var stale_detour_side := int(pair.route.detour_side)
	pair.configure_park_area(GATE_Y, PARK_BOUNDS)
	_check(
		bool(
			pair.initialize_parked_departure(
				21,
				PARK_SPOT,
				Vector2(40.0, -230.0),
				100.0
			)
		),
		"stale-detour parked fixture initializes"
	)
	main.phase = "freedom"
	if not pair.has_method("get_pair_state"):
		return
	var pair_id := pair.get_instance_id()
	var owner_id: int = pair.npc_owner.get_instance_id()
	var dog_id: int = pair.npc_dog.get_instance_id()
	pair.begin_park_recall()
	_check(_state(pair) == RECALLING, "explicit recall enters RECALLING")
	var recall_rope_points: Array[Vector2] = pair.leash.pts.duplicate()
	_tick(pair)
	_check(not pair.leash.visible, "leash remains hidden while dog is outside attach distance")
	_check(bool(pair.leash.detached), "leash remains detached during physical recall")
	_check(
		_rope_points_equal(recall_rope_points, pair.leash.pts),
		"recall leaves suspended rope points unchanged before attach"
	)
	_check(main.released_pair_ids.is_empty(), "recall beside the spot does not release slot")
	pair.leash.dynamic_obstacles.append(Vector2(99.0, 99.0))

	_check(_tick_until_state(pair, DEPARTING), "dog reaches owner and attaches")
	_check(pair.leash.visible, "attach makes leash visible")
	_check(not bool(pair.leash.detached), "attach reconnects leash")
	_check(pair.leash.dynamic_obstacles.is_empty(), "attach clears stale rope obstacles")
	_check(
		pair.leash.pts[0].is_equal_approx(pair.npc_dog.global_position),
		"attach resnaps dog end"
	)
	_check(
		pair.leash.pts[pair.leash.N - 1].is_equal_approx(pair.leash.call("_hand_pos")),
		"attach resnaps owner end"
	)
	_check(main.released_pair_ids.is_empty(), "attach keeps slot until gate is clear")
	_check(bool(pair.has_park_slot()), "departing pair still owns its slot at attach")

	var saw_gate_approach := false
	var gate_exit := Vector2(pair.walking_lane_x, GATE_EXIT_Y)
	for _frame in range(1200):
		var owner_before: Vector2 = pair.npc_owner.position
		_tick(pair)
		if _state(pair) == DEPARTING:
			saw_gate_approach = saw_gate_approach or pair.npc_owner.position.y > owner_before.y
			_check(
				pair.npc_owner.position.distance_to(owner_before)
					<= pair.PARK_OWNER_SPEED * DT + 0.001,
				"departure owner movement toward the gate is bounded"
			)
			_check(
				pair.npc_owner.position.distance_to(gate_exit)
					< owner_before.distance_to(gate_exit),
				"departure moves toward the gate-exit waypoint"
			)
			_check(main.released_pair_ids.is_empty(), "slot stays held before gate clearance")
		if _state(pair) == WALKING:
			break
	_check(saw_gate_approach, "departure moves through a gate-exit waypoint")
	_check(_state(pair) == WALKING, "gate clearance returns pair to WALKING")
	_check(pair.npc_owner.position.is_equal_approx(gate_exit), "owner reaches the gate-exit waypoint")
	_check(main.released_pair_ids == [pair_id], "gate clearance releases exact pair ID once")
	_check(not bool(pair.has_park_slot()), "cleared pair no longer owns a slot")
	_check(pair.desired_vertical_speed > 0.0, "departure restores downward direction")
	var route_resume_y: float = pair.npc_owner.position.y
	_tick(pair)
	_check(pair.npc_owner.position.y > route_resume_y, "shared route resumes downward")
	_check(stale_detour_side != 0, "departure fixture began with a stale detour")
	_check(int(pair.route.detour_side) == 0, "downward route clears the stale detour")
	_check(pair.route.active_blocker_id == null, "downward route releases the stale blocker")
	_check(not bool(pair.route.blocked), "downward route is not blocked by arrival state")
	_check(pair.npc_owner.get_instance_id() == owner_id, "departing owner identity persists")
	_check(pair.npc_dog.get_instance_id() == dog_id, "departing dog identity persists")
	root.remove_child(pair)
	_check(main.released_pair_ids == [pair_id], "later exit does not double-release slot")
	fixtures.erase(pair)
	pair.free()


func _test_exit_tree_releases_held_slot_once() -> void:
	var main := _make_main("freedom")
	var pair := _make_pair(main)
	if not _required_api(pair):
		return
	pair.configure_park_area(GATE_Y, PARK_BOUNDS)
	var pair_id := pair.get_instance_id()
	_check(bool(pair.begin_park_arrival(31, PARK_SPOT)), "cleanup fixture begins arrival")
	_check(bool(pair.has_park_slot()), "cleanup fixture holds slot")
	root.remove_child(pair)
	fixtures.erase(pair)
	pair.free()
	_check(main.released_pair_ids == [pair_id], "exit tree releases exact pair ID once")
	_check(main.released_pair_ids == [pair_id], "free after exit does not double-release")


func _test_walking_route_and_tangle_regression() -> void:
	var main := _make_main("out")
	var pair := _make_pair(main, Vector2(200.0, 300.0), Vector2.UP)
	var owner_before: Vector2 = pair.npc_owner.position
	_tick(pair)
	_check(pair.npc_owner.position.y < owner_before.y, "WALKING keeps existing route movement")
	var rooted_position: Vector2 = pair.npc_owner.position
	pair.tangled_t = 0.4
	_tick(pair, 0.1)
	_check(pair.npc_owner.position.is_equal_approx(rooted_position), "tangle still roots WALKING owner")
	_check(pair.tangled_t > 0.0, "tangle latch timer remains active")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	_check(
		get_nodes_in_group("pairs").is_empty(),
		"all %d pair fixtures are cleaned up" % created_pairs
	)
	if failures > 0:
		print("test_pair_park_lifecycle: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_park_lifecycle: OK")
		quit(0)


func _initialize() -> void:
	seed(1607)
	_test_interface_and_explicit_arrival()
	_test_arrival_reaches_persistent_parked_pair()
	_test_timer_home_and_idempotent_recall()
	_test_recall_attach_gate_release_and_route_resume()
	_test_exit_tree_releases_held_slot_once()
	_test_walking_route_and_tangle_regression()
	_finish()
