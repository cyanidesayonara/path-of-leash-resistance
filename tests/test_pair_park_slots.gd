extends SceneTree

var failures := 0


class ArrivalStub:
	extends Node2D

	var desired_vertical_speed := -70.0
	var npc_owner := Node2D.new()
	var started := false
	var assigned_slot := -1
	var assigned_spot := Vector2.ZERO

	func _init() -> void:
		add_child(npc_owner)

	func is_park_lifecycle_active() -> bool:
		return started

	func begin_park_arrival(slot_id: int, spot: Vector2) -> bool:
		started = true
		assigned_slot = slot_id
		assigned_spot = spot
		return true


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _initialize() -> void:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	var pairs: Array[Node] = []
	var spots: Array[Vector2] = []
	for i in range(5):
		var pair := Node.new()
		pairs.append(pair)
		var result: Dictionary = main.reserve_pair_park_spot(pair)
		if i < 4:
			_check(bool(result.found), "slot %d reserves" % i)
			spots.append(result.spot)
		else:
			_check(not bool(result.found), "fifth pair is rejected")
	_check(spots.size() == 4, "four park spots are available")
	for i in range(spots.size()):
		for j in range(i + 1, spots.size()):
			_check(not spots[i].is_equal_approx(spots[j]), "park spots are distinct")
		_check(main._pair_park_bounds().has_point(spots[i]), "park spot is inside freedom bounds")
		_check(spots[i].distance_to(main.gate_bench) > 100.0, "park spot avoids player bench")

	main.release_pair_park_spot(pairs[1].get_instance_id())
	var retry: Dictionary = main.reserve_pair_park_spot(pairs[4])
	_check(bool(retry.found), "released slot can be reused")
	_check((retry.spot as Vector2).is_equal_approx(spots[1]), "released spot is reused")
	for pair in pairs:
		main.release_pair_park_spot(pair.get_instance_id())

	var arrival := ArrivalStub.new()
	arrival.npc_owner.position = Vector2(640.0, -5000.0)
	main._start_pair_arrivals([arrival])
	_check(arrival.started, "gate-window walker starts explicit arrival")
	_check(arrival.assigned_slot >= 0, "arrival receives a reserved slot")
	_check(
		(arrival.assigned_spot as Vector2).is_equal_approx(spots[arrival.assigned_slot]),
		"arrival receives its slot's waiting spot"
	)
	main.release_pair_park_spot(arrival.get_instance_id())
	arrival.free()

	for pair in pairs:
		pair.free()
	main.free()
	if failures > 0:
		print("test_pair_park_slots: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_park_slots: OK")
		quit(0)
