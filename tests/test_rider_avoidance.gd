extends SceneTree

const BIKE_SCRIPT := "res://bike.gd"
const DT := 0.02

var failures := 0
var fixtures: Array[Node] = []


class FakeMain:
	extends Node2D

	var phase := "out"
	var frozen := false
	var cam := Node2D.new()
	var bypasser_blockers: Array[Dictionary] = []

	func _init() -> void:
		add_child(cam)

	func float_text(_position: Vector2, _text: String, _color: Color) -> void:
		pass

	func close_call(_position: Vector2) -> void:
		pass


class FakeDog:
	extends Node2D

	func hit_by_rider(_direction: Vector2) -> void:
		pass


class FakeHuman:
	extends Node2D

	func fall(_reason: String) -> bool:
		return false

	func bumped(_direction: Vector2) -> void:
		pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _circle(id: String, center: Vector2, radius: float, forced_side := "") -> Dictionary:
	var blocker := {"id": id, "center": center, "radius": radius}
	if forced_side != "":
		blocker["forced_side"] = forced_side
	return blocker


func _rect(id: String, rect: Rect2, forced_side := "") -> Dictionary:
	var blocker := {"id": id, "rect": rect}
	if forced_side != "":
		blocker["forced_side"] = forced_side
	return blocker


func _make_world() -> Dictionary:
	var main := FakeMain.new()
	var dog := FakeDog.new()
	var human := FakeHuman.new()
	dog.position = Vector2(5000, 5000)
	human.position = Vector2(5000, 5000)
	root.add_child(main)
	root.add_child(dog)
	root.add_child(human)
	fixtures.append(main)
	fixtures.append(dog)
	fixtures.append(human)
	return {"main": main, "dog": dog, "human": human}


func _make_rider(
	world: Dictionary,
	position: Vector2,
	velocity: Vector2,
	kind := "bike",
	activate := true
) -> Node2D:
	var rider := Node2D.new()
	rider.set_script(load(BIKE_SCRIPT))
	rider.position = position
	rider.visible = false
	rider.set_physics_process(false)
	rider.setup(world.main, world.dog, world.human, velocity, kind)
	if activate:
		root.add_child(rider)
	fixtures.append(rider)
	return rider


func _configure(
	rider: Node2D,
	preferred_x: float,
	min_x: float,
	max_x: float,
	blockers: Array[Dictionary]
) -> bool:
	_check(rider.has_method("configure_route"), "vertical riders expose route configuration")
	if not rider.has_method("configure_route"):
		return false
	return bool(rider.call("configure_route", preferred_x, min_x, max_x, blockers))


func _require_route(
	rider: Node2D,
	preferred_x: float,
	min_x: float,
	max_x: float,
	blockers: Array[Dictionary],
	label: String
) -> bool:
	var configured := _configure(rider, preferred_x, min_x, max_x, blockers)
	_check(configured, label + " route configuration succeeds")
	if not configured and is_instance_valid(rider):
		rider.free()
	return configured


func _inside_expanded(point: Vector2, blocker: Dictionary, clearance: float) -> bool:
	if blocker.has("center"):
		var radius := float(blocker.radius) + clearance
		return point.distance_squared_to(blocker.center) < radius * radius - 0.001
	var expanded: Rect2 = blocker.rect.grow(clearance)
	return (
		point.x > expanded.position.x + 0.001
		and point.x < expanded.end.x - 0.001
		and point.y > expanded.position.y + 0.001
		and point.y < expanded.end.y - 0.001
	)


func _run_past_blocker(
	rider: Node2D,
	blockers: Array[Dictionary],
	direction: int,
	target_y: float,
	label: String,
	expected_side := 0
) -> void:
	var route: Variant = rider.get("route")
	_check(route != null, label + " owns a route planner")
	if route == null:
		return
	var clearance := float(route.get("clearance"))
	var lateral_cap := float(route.get("max_lateral_speed"))
	var reached_target := false
	for _frame in range(240):
		var before := rider.position
		rider._physics_process(DT)
		var after := rider.position
		_check(
			absf(after.x - before.x) <= lateral_cap * DT + 0.001,
			label + " lateral movement stays speed bounded"
		)
		_check(
			rider.vel.is_equal_approx((after - before) / DT),
			label + " velocity represents actual motion"
		)
		if _frame == 0 and expected_side != 0:
			_check(int(route.get("detour_side")) == expected_side, label + " honors forced detour side")
		for blocker in blockers:
			_check(
				not _inside_expanded(after, blocker, clearance),
				label + " never enters expanded blocker " + str(blocker.id)
			)
		if direction < 0 and after.y <= target_y:
			reached_target = true
			break
		if direction > 0 and after.y >= target_y:
			reached_target = true
			break
	_check(reached_target, label + " continues past the blocker")


func _assert_kid_wobble_updates_preference(kid: Node2D, label: String) -> void:
	var route: RefCounted = kid.route
	var before := float(route.get("preferred_x"))
	var now := Time.get_ticks_msec() / 1000.0
	kid.base_x = before
	kid.wob_seed = PI * 0.5 - now * 2.4
	kid.swerve_t = 1.0
	kid._physics_process(DT)
	var after := float(route.get("preferred_x"))
	_check(after > before + 20.0, label + " physics writes wobble into route preferred X")


func _test_fast_bike_avoids_forced_pond_both_directions(world: Dictionary) -> void:
	var pond: Array[Dictionary] = [
		_rect("pond", Rect2(80, -60, 50, 120), "right"),
	]
	for direction in [-1, 1]:
		var start_y := 360.0 if direction < 0 else -360.0
		var target_y := -180.0 if direction < 0 else 180.0
		var bike := _make_rider(world, Vector2(105, start_y), Vector2(0, 460.0 * direction))
		var label := "fast bike direction %d" % direction
		if _require_route(bike, 105.0, 20.0, 220.0, pond, label):
			_run_past_blocker(
				bike,
				pond,
				direction,
				target_y,
				label,
				1
			)


func _test_wobbling_kid_avoids_circle_and_rectangle(world: Dictionary) -> void:
	var cases: Array[Dictionary] = [
		{
			"label": "wobbling kid circle",
			"blockers": [_circle("fountain", Vector2(110, 40), 24.0)],
		},
		{
			"label": "wobbling kid rectangle",
			"blockers": [_rect("stall", Rect2(82, -10, 58, 100))],
		},
	]
	for test_case in cases:
		var blockers: Array[Dictionary] = []
		blockers.assign(test_case.blockers)
		var kid := _make_rider(world, Vector2(110, 320), Vector2(0, -105), "kid")
		var label := str(test_case.label)
		if not _require_route(kid, 110.0, 20.0, 220.0, blockers, label):
			continue
		kid.lane_keep(30.0, 210.0)
		_assert_kid_wobble_updates_preference(kid, label)
		_run_past_blocker(kid, blockers, -1, -160.0, label)


func _test_blocked_corridor_holds_forward_travel(world: Dictionary) -> void:
	var blockers: Array[Dictionary] = [
		_rect("sealed_ahead", Rect2(80, 20, 100, 80), "right"),
	]
	var bike := _make_rider(world, Vector2(100, 240), Vector2(0, -400))
	if not _require_route(bike, 100.0, 20.0, 150.0, blockers, "blocked bike"):
		return
	var before := bike.position
	bike._physics_process(DT)
	_check(is_equal_approx(bike.position.y, before.y), "blocked route holds forward position")
	_check(is_zero_approx(bike.vel.y), "blocked route reports zero actual forward velocity")


func _test_spawn_selection_and_rejection(world: Dictionary) -> void:
	var circle: Array[Dictionary] = [_circle("spawn_circle", Vector2(100, 0), 20.0)]
	var clear_rider := _make_rider(world, Vector2(100, 0), Vector2(0, -100), "bike", false)
	var found_clear_spawn := _require_route(
		clear_rider,
		100.0,
		0.0,
		200.0,
		circle,
		"clear off-screen spawn"
	)
	if found_clear_spawn:
		root.add_child(clear_rider)
		var clear_route: RefCounted = clear_rider.route
		_check(
			not _inside_expanded(clear_rider.position, circle[0], float(clear_route.clearance)),
			"selected spawn clears rider geometry"
		)

	var sealed: Array[Dictionary] = [_rect("sealed_spawn", Rect2(-100, -100, 400, 200))]
	var blocked_rider := _make_rider(world, Vector2(100, 0), Vector2(0, -100), "bike", false)
	var rejected_spawn := not _configure(blocked_rider, 100.0, 0.0, 200.0, sealed)
	_check(
		rejected_spawn,
		"route setup rejects a fully blocked spawn"
	)
	_check(not blocked_rider.is_inside_tree(), "rejected rider remains inactive outside the scene tree")

	var source := FileAccess.get_file_as_string("res://main.gd")
	var vlane_start := source.find("func _vlane")
	var vlane_end := source.find("func _squirrels", vlane_start)
	var vlane_source := source.substr(vlane_start, vlane_end - vlane_start)
	var configure_call := vlane_source.find("configure_route")
	var free_call := vlane_source.find("b.free()", configure_call)
	var return_call := vlane_source.find("return", free_call)
	var add_call := vlane_source.find("add_child(b)")
	_check(
		configure_call >= 0
		and free_call > configure_call
		and return_call > free_call
		and add_call > return_call,
		"main frees and returns after route rejection before rider activation"
	)
	blocked_rider.free()
	_check(not is_instance_valid(blocked_rider), "rejected rider cleanup is safe")


func _test_swept_spawn_and_production_clusters(world: Dictionary) -> void:
	for direction in [-1, 1]:
		var leading: Array[Dictionary] = [
			_circle("leading_arc_%d" % direction, Vector2(100, 30.0 * direction), 10.0),
		]
		var rider := _make_rider(
			world,
			Vector2(100, 0),
			Vector2(0, 460.0 * direction),
			"bike",
			false
		)
		var label := "leading arc rider direction %d" % direction
		if not _require_route(rider, 100.0, 0.0, 220.0, leading, label):
			continue
		root.add_child(rider)
		_check(
			not is_equal_approx(rider.position.x, 100.0),
			label + " relocates before entering the forward circle arc"
		)
		rider._physics_process(DT)
		_check(
			not _inside_expanded(rider.position, leading[0], float(rider.route.clearance)),
			label + " first route frame remains swept-clear"
		)

	var table_chairs: Array[Dictionary] = [
		_circle("table", Vector2(100, 40), 10.0),
		_circle("chair_left", Vector2(77, 58), 7.0),
		_circle("chair_right", Vector2(123, 58), 7.0),
	]
	var fast := _make_rider(world, Vector2(100, 360), Vector2(0, -460))
	if _require_route(fast, 100.0, 0.0, 220.0, table_chairs, "fast table-chair cluster"):
		_run_past_blocker(fast, table_chairs, -1, -160.0, "fast table-chair cluster")

	var tree_slalom: Array[Dictionary] = [
		_circle("tree_0", Vector2(90, 85), 10.0),
		_circle("tree_1", Vector2(112, 55), 10.0),
		_circle("tree_2", Vector2(90, 25), 10.0),
	]
	var kid := _make_rider(world, Vector2(100, 360), Vector2(0, -120), "kid")
	if _require_route(kid, 100.0, 0.0, 220.0, tree_slalom, "kid tree-slalom cluster"):
		kid.lane_keep(20.0, 210.0)
		_run_past_blocker(kid, tree_slalom, -1, -160.0, "kid tree-slalom cluster")


func _test_horizontal_crossing_stays_straight(world: Dictionary) -> void:
	var bike := _make_rider(world, Vector2(100, 100), Vector2(500, 0))
	var before := bike.position
	bike._physics_process(0.1)
	_check(bike.get("route") == null, "horizontal crossing bike has no route planner")
	_check(is_equal_approx(bike.position.x, before.x + 50.0), "horizontal crossing keeps original speed")
	_check(is_equal_approx(bike.position.y, before.y), "horizontal crossing remains straight")
	_check(bike.vel == Vector2(500, 0), "horizontal crossing velocity remains unchanged")


func _test_freedom_cleanup_queues_active_rider(world: Dictionary) -> void:
	var rider := _make_rider(world, Vector2(100, 100), Vector2(0, -100))
	var blockers: Array[Dictionary] = []
	if not _require_route(rider, 100.0, 0.0, 200.0, blockers, "freedom cleanup rider"):
		return
	world.main.phase = "freedom"
	rider._physics_process(0.0)
	_check(rider.is_queued_for_deletion(), "freedom cleanup queues active routed rider")
	world.main.phase = "out"


func _cleanup() -> void:
	for fixture in fixtures:
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_rider_avoidance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_rider_avoidance: OK")
		quit(0)


func _initialize() -> void:
	var world := _make_world()
	_test_fast_bike_avoids_forced_pond_both_directions(world)
	_test_wobbling_kid_avoids_circle_and_rectangle(world)
	_test_blocked_corridor_holds_forward_travel(world)
	_test_spawn_selection_and_rejection(world)
	_test_swept_spawn_and_production_clusters(world)
	_test_horizontal_crossing_stays_straight(world)
	_test_freedom_cleanup_queues_active_rider(world)
	_finish()
