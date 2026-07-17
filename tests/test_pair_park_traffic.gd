extends SceneTree

const DT := 1.0 / 60.0
const WALKING := 0
const ARRIVING := 1
const PARKED := 2
const RECALLING := 3
const DEPARTING := 4

var failures := 0
var fixtures: Array[Node] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _make_main() -> Node2D:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	main.visible = false
	root.add_child(main)
	main.set_physics_process(false)
	main.phase = "freedom"
	main.frozen = false
	main.leash.detached = true
	fixtures.append(main)
	return main


func _state(pair: Node2D) -> int:
	return int(pair.get_pair_state())


func _free_pair(pair: Node2D) -> void:
	if not is_instance_valid(pair):
		return
	if pair.get_parent() != null:
		pair.get_parent().remove_child(pair)
	pair.free()


func _pair_children(main: Node2D) -> Array:
	var pairs: Array = []
	for child in main.get_children():
		if child.is_in_group("pairs"):
			pairs.append(child)
	return pairs


func _test_reservations(main: Node2D) -> void:
	var ids := [101, 102, 103, 104]
	var reservations: Array[Dictionary] = []
	for index in range(ids.size()):
		var result: Dictionary = main.reserve_pair_park_spot(ids[index])
		if index < 3:
			_check(bool(result.found), "one of three park slots reserves")
			reservations.append(result)
		else:
			_check(not bool(result.found), "fourth park reservation is rejected")
	_check(reservations.size() == 3, "exactly three park spots are available")
	for index in range(reservations.size()):
		var reservation := reservations[index]
		_check(reservation.has("position"), "reservation exposes position")
		for other_index in range(index + 1, reservations.size()):
			_check(
				int(reservation.slot_id) != int(reservations[other_index].slot_id),
				"reserved slots have unique ownership"
			)
			_check(
				(reservation.position as Vector2).distance_to(
					reservations[other_index].position
				) > 100.0,
				"park spots are separated"
			)
	var repeated: Dictionary = main.reserve_pair_park_spot(ids[1])
	_check(bool(repeated.found), "re-reservation remains successful")
	_check(
		int(repeated.slot_id) == int(reservations[1].slot_id),
		"re-reservation is idempotent"
	)
	_check(main.pair_park_slots.size() == 3, "re-reservation creates no duplicate ownership")

	main.release_pair_park_spot(ids[1])
	var reused: Dictionary = main.reserve_pair_park_spot(ids[3])
	_check(bool(reused.found), "released slot can be reserved")
	_check(
		int(reused.slot_id) == int(reservations[1].slot_id),
		"first-clear policy reuses the exact released slot"
	)
	for pair_id in ids:
		main.release_pair_park_spot(pair_id)


func _test_arrival_qualification(main: Node2D) -> void:
	var upward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y + 20.0),
		Vector2.UP
	)
	var downward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y + 20.0),
		Vector2.DOWN
	)
	_check(upward != null and downward != null, "walking fixtures configure")
	if upward != null and downward != null:
		_check(main._pair_qualifies_for_arrival(upward), "approaching upward walker qualifies")
		_check(not main._pair_qualifies_for_arrival(downward), "downward walker does not qualify")
	_free_pair(upward)
	_free_pair(downward)


func _test_park_pair_builders(main: Node2D) -> void:
	var arrival: Node2D = main._build_park_pair("arrival")
	_check(arrival != null, "freedom policy builds arrival")
	if arrival != null:
		_check(arrival.get_parent() == null, "arrival is configured before tree entry")
		_check(_state(arrival) == ARRIVING, "arrival builder enters ARRIVING")
		_check(arrival.park_area_configured, "arrival has freedom bounds")
		_check(arrival.route != null, "arrival has path route")
		_check(arrival.has_park_slot(), "arrival reserves a park spot")
		_free_pair(arrival)

	var departure: Node2D = main._build_park_pair("departure")
	_check(departure != null, "freedom policy builds departure")
	if departure != null:
		_check(departure.get_parent() == null, "departure is configured before tree entry")
		_check(_state(departure) == PARKED, "departure builder starts PARKED")
		_check(departure.park_area_configured, "departure has freedom bounds")
		_check(departure.route != null, "departure has path route")
		_check(departure.has_park_slot(), "departure reserves a park spot")
		_check(
			main._pair_park_bounds().has_point(departure.npc_dog.position),
			"departure dog starts inside freedom bounds"
		)
		_free_pair(departure)


func _test_failed_spawn_and_cap(main: Node2D) -> void:
	for pair_id in [201, 202, 203]:
		main.reserve_pair_park_spot(pair_id)
	var children_before := main.get_child_count()
	var failed: Node2D = main._spawn_freedom_pair(0, "arrival")
	_check(failed == null, "full reservation capacity rejects a freedom spawn")
	_check(main.get_child_count() == children_before, "failed spawn adds no pair")
	for pair_id in [201, 202, 203]:
		main.release_pair_park_spot(pair_id)

	var capped: Node2D = main._spawn_freedom_pair(3, "arrival")
	_check(capped == null, "active pair cap rejects a fourth pair")
	_check(main.get_child_count() == children_before, "pair cap adds no child")

	for _index in range(3):
		var spawned: Node2D = main._spawn_freedom_pair(_index, "arrival")
		_check(spawned != null, "pair spawns below the active cap")
	var pair_children := 0
	for child in main.get_children():
		if child.is_in_group("pairs"):
			pair_children += 1
	_check(pair_children == 3, "freedom traffic stops at three active pairs")
	for child in main.get_children().duplicate():
		if child.is_in_group("pairs"):
			_free_pair(child)


func _test_configure_failure_falls_back_without_slot_leak() -> void:
	var main := _make_main()
	main.bypasser_blockers.clear()
	main.bypasser_blockers.append({
		"id": "arrival_only_blocker",
		"rect": Rect2(
			main.walk_cx - main.walk_half - 100.0,
			main.GATE_Y + 340.0,
			main.walk_half * 2.0 + 200.0,
			20.0
		),
	})
	var fallback: Node2D = main._spawn_freedom_pair(0, "arrival")
	_check(fallback != null, "failed preferred arrival falls back to departure")
	if fallback != null:
		_check(_state(fallback) == PARKED, "fallback uses the departure lifecycle")
		_check(main.pair_park_slots.size() == 1, "failed route leaves only fallback reservation")
		_check(
			main.pair_park_slots.has(fallback.get_instance_id()),
			"fallback owns the only reservation"
		)
		_free_pair(fallback)
	_check(main.pair_park_slots.is_empty(), "fallback free releases the remaining reservation")


func _test_pairs_orchestrates_arrival_spawn_cap_and_cleanup() -> void:
	var arrival_main := _make_main()
	arrival_main.park_pair_spawn_t = 100.0
	var upward: Node2D = arrival_main._create_configured_pair(
		Vector2(640.0, arrival_main.GATE_Y + 20.0),
		Vector2.UP
	)
	_check(upward != null, "production arrival fixture configures")
	if upward != null:
		arrival_main.add_child(upward)
		upward.set_physics_process(false)
		upward.leash.dynamic_obstacles.append(Vector2(10.0, 20.0))
		upward.update_tangle_state(true, 0.0)
		arrival_main._pairs(0.2)
		_check(_state(upward) == ARRIVING, "_pairs automatically qualifies upward gate traffic")
		_check(upward.has_park_slot(), "_pairs reserves the automatic arrival slot")
		_check(
			upward.leash.dynamic_obstacles.is_empty(),
			"detached _pairs clears NPC rope obstacles"
		)
		_check(
			is_equal_approx(upward.tangle_clear_t, 0.2),
			"detached _pairs advances tangle separation once"
		)
		_free_pair(upward)

	var spawn_main := _make_main()
	for expected_count in range(1, spawn_main.MAX_ACTIVE_PAIRS + 1):
		spawn_main.park_pair_spawn_t = 0.0
		spawn_main._pairs(0.0)
		_check(
			_pair_children(spawn_main).size() == expected_count,
			"freedom timer adds one production pair below cap"
		)
	spawn_main.park_pair_spawn_t = 0.0
	spawn_main._pairs(0.0)
	_check(
		_pair_children(spawn_main).size() == spawn_main.MAX_ACTIVE_PAIRS,
		"live pair group enforces the production cap"
	)
	_check(
		spawn_main.pair_park_slots.size() == spawn_main.MAX_ACTIVE_PAIRS,
		"production cap owns exactly one slot per pair"
	)
	for pair in _pair_children(spawn_main):
		_free_pair(pair)
	_check(spawn_main.pair_park_slots.is_empty(), "production pair cleanup releases all cap slots")


func _test_slot_exhaustion_keeps_gate_traffic_walking() -> void:
	var main := _make_main()
	main.park_pair_spawn_t = 100.0
	var occupied_ids := [301, 302, 303]
	for pair_id in occupied_ids:
		var reservation: Dictionary = main.reserve_pair_park_spot(pair_id)
		_check(bool(reservation.found), "slot exhaustion fixture occupies a park slot")
	_check(main.pair_park_slots.size() == 3, "slot exhaustion fixture fills all three slots")

	var upward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y + 20.0),
		Vector2.UP
	)
	_check(upward != null, "slot exhaustion gate fixture configures")
	if upward == null:
		for pair_id in occupied_ids:
			main.release_pair_park_spot(pair_id)
		return
	main.add_child(upward)
	upward.set_physics_process(false)
	main.cam.position = upward.npc_owner.position
	var start_y: float = upward.npc_owner.position.y
	var remained_walking := true
	for _frame in range(60):
		main.cam.position = upward.npc_owner.position
		main._pairs(DT)
		remained_walking = remained_walking and _state(upward) == WALKING
		upward._physics_process(DT)
		remained_walking = remained_walking and _state(upward) == WALKING

	_check(remained_walking, "full slots leave production gate traffic WALKING")
	_check(not upward.has_park_slot(), "rejected gate traffic owns no park slot")
	_check(
		upward.npc_owner.position.y < start_y,
		"rejected gate traffic continues moving on its route"
	)
	_check(
		upward.npc_owner.position.y < main.GATE_Y,
		"rejected gate traffic crosses the gate instead of stalling"
	)
	_check(main.pair_park_slots.size() == 3, "rejected arrival leaks no reservation")
	_check(
		not main.pair_park_slots.has(upward.get_instance_id()),
		"rejected pair ID is absent from reservations"
	)
	for pair_id in occupied_ids:
		_check(main.pair_park_slots.has(pair_id), "existing reservation remains owned")

	_free_pair(upward)
	for pair_id in occupied_ids:
		main.release_pair_park_spot(pair_id)
	_check(main.pair_park_slots.is_empty(), "slot exhaustion fixture cleans up reservations")


func _test_freedom_transition_clears_obstacles_without_double_advance() -> void:
	var main := _make_main()
	main.phase = "out"
	main.leash.detached = false
	main.leash.dynamic_obstacles.append(Vector2(30.0, 40.0))
	var pair: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y + 20.0),
		Vector2.UP
	)
	_check(pair != null, "freedom transition fixture configures")
	if pair == null:
		return
	main.add_child(pair)
	pair.set_physics_process(false)
	pair.leash.dynamic_obstacles.append(Vector2(50.0, 60.0))
	pair.update_tangle_state(true, 0.0)
	pair.tangle_clear_t = 0.2
	main._enter_freedom()
	_check(main.phase == "freedom", "production transition enters freedom")
	_check(main.leash.detached, "production transition detaches player leash")
	_check(
		main.leash.dynamic_obstacles.is_empty(),
		"freedom transition immediately clears player rope obstacles"
	)
	_check(
		pair.leash.dynamic_obstacles.is_empty(),
		"freedom transition immediately clears NPC rope obstacles"
	)
	_check(
		is_equal_approx(pair.tangle_clear_t, 0.2),
		"freedom transition does not advance tangle separation twice"
	)
	_free_pair(pair)


func _test_home_transition(main: Node2D) -> void:
	var upward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y - 80.0),
		Vector2.UP
	)
	var downward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y + 80.0),
		Vector2.DOWN
	)
	var arriving: Node2D = main._build_park_pair("arrival")
	var parked: Node2D = main._build_park_pair("departure")
	var recalling: Node2D = main._build_park_pair("departure")
	recalling.begin_park_recall()
	var pairs: Array = [upward, downward, arriving, parked, recalling]

	main._prepare_pairs_for_home(pairs)
	_check(_state(upward) == WALKING, "upward walker remains on shared walking route")
	_check(upward.desired_vertical_speed > 0.0, "upward walker reverses downward for home")
	_check(_state(downward) == WALKING, "downward walker continues walking")
	_check(downward.desired_vertical_speed > 0.0, "downward walker keeps its direction")
	_check(_state(arriving) == RECALLING, "home interrupts arrival into recall")
	_check(_state(parked) == RECALLING, "home recalls parked pair")
	_check(_state(recalling) == RECALLING, "home recall is idempotent")
	for pair in pairs:
		_free_pair(pair)

	var departing: Node2D = main._build_park_pair("departure")
	departing.begin_park_recall()
	departing.npc_dog.position = departing.npc_owner.position
	departing._physics_process(0.0)
	main._prepare_pairs_for_home([departing])
	_check(_state(departing) == DEPARTING, "home leaves departure in progress")
	_free_pair(departing)


func _test_enter_home_integration() -> void:
	var main := _make_main()
	main.phase = "freedom"
	main.leash.detached = true
	main.human.park_at(main.gate_bench)
	var upward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y - 80.0),
		Vector2.UP
	)
	var downward: Node2D = main._create_configured_pair(
		Vector2(640.0, main.GATE_Y + 80.0),
		Vector2.DOWN
	)
	var arriving: Node2D = main._build_park_pair("arrival")
	var parked: Node2D = main._build_park_pair("departure")
	var recalling: Node2D = main._build_park_pair("departure")
	_check(
		upward != null
		and downward != null
		and arriving != null
		and parked != null
		and recalling != null,
		"home integration fixtures configure"
	)
	if (
		upward == null
		or downward == null
		or arriving == null
		or parked == null
		or recalling == null
	):
		return
	recalling.begin_park_recall()
	var pairs: Array = [upward, downward, arriving, parked, recalling]
	for pair in pairs:
		main.add_child(pair)
		pair.set_physics_process(false)

	main._enter_home()
	_check(main.phase == "home", "_enter_home switches the production phase")
	_check(not main.leash.detached, "_enter_home reattaches the player leash")
	_check(
		main.leash.pts[0].is_equal_approx(main.dog.global_position)
		and main.leash.pts[main.leash.N - 1].is_equal_approx(main.leash.call("_hand_pos")),
		"_enter_home resnaps both player leash endpoints"
	)
	_check(main.human.homeward and not main.human.parked, "_enter_home unparks the player owner")
	_check(upward.desired_vertical_speed > 0.0, "_enter_home reverses upward walking traffic")
	_check(downward.desired_vertical_speed > 0.0, "_enter_home preserves downward walking traffic")
	_check(_state(arriving) == RECALLING, "_enter_home interrupts arrival")
	_check(_state(parked) == RECALLING, "_enter_home recalls parked traffic")
	_check(_state(recalling) == RECALLING, "_enter_home keeps recall idempotent")
	for pair in pairs:
		_free_pair(pair)


func _test_detached_cleanup_and_free(main: Node2D) -> void:
	var arrival: Node2D = main._build_park_pair("arrival")
	_check(arrival != null, "detached cleanup fixture builds")
	if arrival == null:
		return
	arrival.leash.dynamic_obstacles.append(Vector2(1.0, 2.0))
	arrival.update_tangle_state(true, 0.0)
	main._clear_detached_pair_tangles([arrival], 0.2)
	_check(arrival.leash.dynamic_obstacles.is_empty(), "detached player clears pair rope obstacles")
	_check(
		is_equal_approx(arrival.tangle_clear_t, 0.2),
		"detached cleanup advances tangle separation exactly once"
	)
	_check(not arrival.is_queued_for_deletion(), "detached cleanup does not delete pair")
	var pair_id := arrival.get_instance_id()
	_check(main.pair_park_slots.has(pair_id), "fixture owns its reservation before free")
	_free_pair(arrival)
	_check(not main.pair_park_slots.has(pair_id), "pair free releases its reservation")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _required_main_api(main: Node2D) -> bool:
	var valid := true
	for method in [
		"reserve_pair_park_spot",
		"release_pair_park_spot",
		"_create_configured_pair",
		"_pair_qualifies_for_arrival",
		"_build_park_pair",
		"_spawn_freedom_pair",
		"_prepare_pairs_for_home",
		"_clear_detached_pair_tangles",
	]:
		if not main.has_method(method):
			print("FAIL: main exposes " + method)
			failures += 1
			valid = false
	return valid


func _run_tests() -> void:
	var main := _make_main()
	if _required_main_api(main):
		_test_reservations(main)
		_test_arrival_qualification(main)
		_test_park_pair_builders(main)
		_test_failed_spawn_and_cap(main)
		_test_configure_failure_falls_back_without_slot_leak()
		_test_pairs_orchestrates_arrival_spawn_cap_and_cleanup()
		_test_slot_exhaustion_keeps_gate_traffic_walking()
		_test_freedom_transition_clears_obstacles_without_double_advance()
		_test_home_transition(main)
		_test_enter_home_integration()
		_test_detached_cleanup_and_free(main)
	_cleanup()
	if failures > 0:
		print("test_pair_park_traffic: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_park_traffic: OK")
		quit(0)


func _initialize() -> void:
	seed(1707)
	call_deferred("_run_tests")
