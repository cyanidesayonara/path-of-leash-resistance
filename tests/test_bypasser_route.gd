extends SceneTree

const SCRIPT_PATH := "res://bypasser_route.gd"
const DT := 0.1

var failures := 0


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


func _planner(
	preferred_x := 100.0,
	min_x := 0.0,
	max_x := 200.0,
	clearance := 10.0,
	lateral_speed := 100.0
) -> RefCounted:
	var planner_script: Script = load(SCRIPT_PATH)
	return planner_script.new(
		preferred_x,
		min_x,
		max_x,
		clearance,
		lateral_speed,
		60.0,
		1.0
	)


func _configure_planner(
	planner: RefCounted,
	blockers: Array[Dictionary],
	label: String
) -> bool:
	if not planner.has_method("configure_blockers"):
		_check(false, label + " planner exposes configured blocker cache")
		return false
	planner.call("configure_blockers", blockers)
	return true


func _configured_step(
	planner: RefCounted,
	position: Vector2,
	vertical_speed: float,
	delta: float,
	member_offsets: Array[Vector2] = []
) -> Dictionary:
	return planner.call("step", position, vertical_speed, delta, member_offsets)


func _transition_step(
	planner: RefCounted,
	position: Vector2,
	vertical_speed: float,
	delta: float,
	current_offsets: Array[Vector2],
	left_offsets: Array[Vector2],
	right_offsets: Array[Vector2],
	clear_offsets: Array[Vector2] = []
) -> Dictionary:
	for method in planner.get_method_list():
		if method.name == "step" and method.args.size() >= 7:
			return planner.call(
				"step",
				position,
				vertical_speed,
				delta,
				current_offsets,
				left_offsets,
				right_offsets,
				clear_offsets
			)
	_check(false, "runtime step accepts explicit side-specific formation transitions")
	return {
		"x": position.x,
		"target_x": position.x,
		"blocked": true,
		"side": 0,
		"blocker_id": null,
	}


func _configured_spawn(
	planner: RefCounted,
	y: float,
	vertical_speed: float,
	member_offsets: Array[Vector2] = []
) -> Dictionary:
	return planner.call("find_clear_spawn_x", y, vertical_speed, member_offsets)


func _step(
	planner: RefCounted,
	position: Vector2,
	vertical_speed: float,
	blockers: Array[Dictionary],
	delta := DT
) -> Dictionary:
	if int(planner.get("normalization_passes")) == 0 or (
		int(planner.get("configured_blocker_count")) == 0 and not blockers.is_empty()
	):
		planner.call("configure_blockers", blockers)
	return planner.call("step", position, vertical_speed, delta)


func _spawn(
	planner: RefCounted,
	y: float,
	blockers: Array[Dictionary],
	member_offsets: Array[Vector2] = []
) -> Variant:
	planner.call("configure_blockers", blockers)
	return planner.call("find_clear_spawn_x", y, 0.0, member_offsets)


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


func _test_clear_travel_and_return() -> void:
	var planner := _planner()
	var clear_result := _step(planner, Vector2(100, 100), -40.0, [])
	_check(is_equal_approx(float(clear_result.x), 100.0), "clear travel stays in the preferred lane")
	_check(not bool(clear_result.blocked), "clear travel is not blocked")

	var blockers: Array[Dictionary] = [_circle("tree", Vector2(100, 40), 15.0)]
	var position := Vector2(100, 100)
	for _frame in range(30):
		var result := _step(planner, position, -40.0, blockers)
		position = Vector2(float(result.x), position.y - 4.0)
	_check(is_equal_approx(position.x, 100.0), "planner returns smoothly to the preferred lane after clearing")


func _test_out_of_bounds_recovery_is_speed_bounded() -> void:
	var planner := _planner(100.0, 0.0, 200.0, 10.0, 60.0)
	var position := Vector2(235.0, 100.0)
	for _frame in range(8):
		var result := _step(planner, position, -40.0, [], 0.1)
		var displacement := absf(float(result.x) - position.x)
		_check(displacement <= 6.0001, "out-of-bounds recovery respects the per-frame lateral cap")
		_check(float(result.x) <= position.x, "out-of-bounds recovery moves toward the allowed route")
		position.x = float(result.x)
	_check(position.x < 200.0, "bounded recovery eventually re-enters route bounds")


func _test_circle_detours() -> void:
	var blocker: Array[Dictionary] = [_circle("circle", Vector2(100, 40), 15.0)]
	var left_result := _step(_planner(), Vector2(100, 100), -40.0, blocker)
	_check(int(left_result.side) == -1, "equidistant circle detour deterministically chooses left")
	_check(float(left_result.x) < 100.0, "left circle detour moves laterally without snapping")
	_check(float(left_result.x) > float(left_result.target_x), "left circle detour is speed bounded")

	var right_result := _step(_planner(25.0, 20.0, 200.0), Vector2(25, 100), -40.0, [
		_circle("circle", Vector2(25, 40), 15.0),
	])
	_check(int(right_result.side) == 1, "circle detour chooses right when left is outside route bounds")
	_check(float(right_result.x) > 25.0, "right circle detour moves right")


func _test_rectangles_in_both_directions() -> void:
	var outbound := _step(_planner(), Vector2(100, 100), -40.0, [
		_rect("outbound_rect", Rect2(85, 35, 30, 30)),
	])
	_check(int(outbound.side) == -1, "outbound rectangle chooses deterministic left detour")

	var homebound := _step(_planner(), Vector2(100, 0), 40.0, [
		_rect("homebound_rect", Rect2(85, 50, 30, 30), "right"),
	])
	_check(int(homebound.side) == 1, "homebound rectangle detours in the travel direction")
	_check(float(homebound.x) > 100.0, "homebound rectangle moves toward its right detour")


func _test_forced_right_and_hysteresis() -> void:
	var pond: Array[Dictionary] = [
		_rect("pond", Rect2(85, 35, 30, 30), "right"),
	]
	var planner := _planner()
	var first := _step(planner, Vector2(100, 100), -40.0, pond)
	_check(int(first.side) == 1, "forced-right blocker chooses the right side")
	var second := _step(planner, Vector2(float(first.x), 96), -40.0, pond)
	_check(int(second.side) == 1, "detour side remains stable across consecutive frames")
	_check(str(second.blocker_id) == "pond", "active blocker remains stable across consecutive frames")
	var at_trailing_edge := _step(planner, Vector2(float(second.x), 25), -40.0, pond)
	_check(int(at_trailing_edge.side) == 1, "hysteresis holds through the full expanded blocker")
	_check(str(at_trailing_edge.blocker_id) == "pond", "active blocker remains latched at its trailing edge")
	var released := _step(planner, Vector2(float(at_trailing_edge.x), 24), -40.0, pond)
	_check(int(released.side) == 0, "hysteresis releases only after the blocker is fully behind")
	_check(released.blocker_id == null, "released blocker clears active state")
	_check(float(released.x) < float(at_trailing_edge.x), "release begins bounded return toward the preferred lane")


func _test_connected_forced_side_and_hysteresis() -> void:
	var cluster: Array[Dictionary] = [
		_circle("forced_member", Vector2(95, 40), 15.0, "right"),
		_circle("overlap_member", Vector2(120, 40), 12.0),
	]
	var planner := _planner(100.0, 0.0, 240.0)
	var first := _step(planner, Vector2(100, 110), -40.0, cluster)
	_check(int(first.side) == 1, "connected cluster inherits its forced-right member")
	_check(
		str(first.blocker_id).contains("forced_member")
			and str(first.blocker_id).contains("overlap_member"),
		"connected forced cluster exposes both stable member IDs"
	)
	var edge := _step(planner, Vector2(float(first.x), 15.0), -40.0, cluster)
	_check(int(edge.side) == 1, "connected forced cluster stays latched at its expanded edge")
	var released := _step(planner, Vector2(float(edge.x), 14.9), -40.0, cluster)
	_check(int(released.side) == 0, "connected forced cluster releases immediately after its expanded edge")


func _test_formation_release_has_no_second_clearance() -> void:
	var blocker: Array[Dictionary] = [_circle("single", Vector2(100, 40), 10.0)]
	var planner := _planner(100.0, 0.0, 220.0, 48.0, 90.0)
	if not _configure_planner(planner, blocker, "formation release"):
		return
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(40, 30)]
	var first := _configured_step(planner, Vector2(100, 180), -70.0, 0.1, offsets)
	_check(int(first.side) != 0, "formation release fixture activates a detour")
	var expanded_top := 40.0 - 10.0 - 48.0
	var owner_y := expanded_top - 30.1
	var released := _configured_step(
		planner,
		Vector2(float(first.x), owner_y),
		-70.0,
		0.1,
		offsets
	)
	_check(
		released.blocker_id == null,
		"formation releases once every current member clears expanded geometry"
	)


func _test_candidate_rejection() -> void:
	var left_occupied: Array[Dictionary] = [
		_circle("primary", Vector2(100, 40), 15.0),
		_circle("left_guard", Vector2(72, 40), 8.0),
	]
	var side_result := _step(_planner(), Vector2(100, 100), -40.0, left_occupied)
	_check(int(side_result.side) == 1, "nearby blocker rejects an occupied detour side")

	var both_occupied: Array[Dictionary] = []
	both_occupied.assign(left_occupied)
	both_occupied.append(_circle("right_guard", Vector2(128, 40), 8.0))
	var blocked_result := _step(_planner(), Vector2(100, 100), -40.0, both_occupied)
	_check(not bool(blocked_result.blocked), "connected blocker cluster finds a clear outer edge")
	_check(int(blocked_result.side) == -1, "connected cluster uses deterministic outer-side tie breaking")
	_check(float(blocked_result.target_x) <= 54.001, "connected cluster targets its outer expanded boundary")

	var boxed_result := _step(_planner(), Vector2(100, 100), -40.0, [
		_rect("boxed", Rect2(-10, 20, 220, 80)),
	])
	_check(bool(boxed_result.blocked), "genuinely boxed route reports blocked")
	_check(is_equal_approx(float(boxed_result.x), 100.0), "boxed route does not teleport")


func _run_configured_cluster(
	blockers: Array[Dictionary],
	label: String,
	member_offsets: Array[Vector2] = []
) -> void:
	var planner := _planner(100.0, 0.0, 250.0, 10.0, 100.0)
	if not _configure_planner(planner, blockers, label):
		return
	var position := Vector2(100, 180)
	var saw_detour := false
	var checked_offsets: Array[Vector2] = []
	checked_offsets.assign(member_offsets)
	if checked_offsets.is_empty():
		checked_offsets.append(Vector2.ZERO)
	for _frame in range(70):
		var result := _configured_step(planner, position, -40.0, 0.1, member_offsets)
		position = Vector2(float(result.x), position.y if bool(result.blocked) else position.y - 4.0)
		saw_detour = saw_detour or int(result.side) != 0
		for offset in checked_offsets:
			for blocker in blockers:
				_check(
					not _inside_expanded(position + offset, blocker, 10.0),
					label + " formation stays outside " + str(blocker.id)
				)
	_check(saw_detour, label + " activates a cluster detour")
	_check(position.y < -80.0, label + " passes the complete cluster")


func _test_production_like_clusters() -> void:
	var table_chairs: Array[Dictionary] = [
		_circle("table", Vector2(100, 30), 10.0),
		_circle("chair_left", Vector2(78, 48), 8.0),
		_circle("chair_right", Vector2(122, 48), 8.0),
		_circle("chair_front", Vector2(100, 67), 8.0),
	]
	_run_configured_cluster(table_chairs, "table and chair cluster")


func _move_member_lateral_first(from: Vector2, target: Vector2, distance: float) -> Vector2:
	var lateral_target := Vector2(target.x, from.y)
	var moved := from.move_toward(lateral_target, distance)
	return moved.move_toward(target, maxf(0.0, distance - moved.distance_to(from)))


func _test_exact_production_park_slalom() -> void:
	var centers: Array[Vector2] = [
		Vector2(570, -1150),
		Vector2(690, -1280),
		Vector2(570, -1410),
		Vector2(690, -1540),
	]
	var blockers: Array[Dictionary] = []
	for i in centers.size():
		blockers.append(_circle("park_slalom_%d" % i, centers[i], 10.0))
	var left_offsets: Array[Vector2] = [Vector2.ZERO, Vector2(-12, 0)]
	var right_offsets: Array[Vector2] = [Vector2.ZERO, Vector2(12, 0)]
	var clear_offsets: Array[Vector2] = [Vector2.ZERO, Vector2(30, 24)]
	for direction in [-1, 1]:
		var planner := _planner(640.0, 330.0, 950.0, 48.0, 90.0)
		if not _configure_planner(planner, blockers, "exact production slalom"):
			return
		var owner := Vector2(640, -900.0 if direction < 0 else -1790.0)
		var dog := owner + Vector2(40, 30)
		var target_y := -1790.0 if direction < 0 else -900.0
		var saw_ids := {}
		var saw_navigation_extension := false
		var side_changes := 0
		var previous_side := 0
		var reached := false
		for _frame in range(1100):
			var owner_before := owner
			var dog_before := dog
			var current_offsets: Array[Vector2] = [Vector2.ZERO, dog - owner]
			var result := _transition_step(
				planner,
				owner,
				70.0 * direction,
				1.0 / 60.0,
				current_offsets,
				left_offsets,
				right_offsets,
				clear_offsets
			)
			owner = Vector2(
				float(result.x),
				owner.y
					if bool(result.blocked) or bool(result.formation_transitioning)
					else owner.y + 70.0 * direction / 60.0
			)
			var side := int(result.side)
			if side != 0 and previous_side != 0 and side != previous_side:
				side_changes += 1
			if side != 0:
				previous_side = side
			var dog_target := (
				Vector2(float(result.target_x) + side * 12.0, owner.y)
				if side != 0
				else owner + Vector2(30, 24)
			)
			dog = _move_member_lateral_first(dog, dog_target, 90.0 / 60.0)
			var active_id := str(result.blocker_id)
			if not active_id.is_empty() and active_id != "<null>":
				saw_ids[active_id] = true
				for first_index in range(centers.size() - 1):
					saw_navigation_extension = saw_navigation_extension or (
						active_id.contains("park_slalom_%d" % first_index)
						and active_id.contains("park_slalom_%d" % (first_index + 1))
					)
			for blocker in blockers:
				_check(
					not _inside_expanded(owner, blocker, 48.0),
					"exact park slalom owner stays clear direction %d" % direction
				)
				_check(
					not _inside_expanded(dog, blocker, 48.0),
					"exact park slalom commanded dog path stays clear direction %d" % direction
				)
				var expanded_radius := float(blocker.radius) + 48.0
				var both_past := (
					owner_before.y < float(blocker.center.y) - expanded_radius
						and dog_before.y < float(blocker.center.y) - expanded_radius
					if direction < 0
					else owner_before.y > float(blocker.center.y) + expanded_radius
						and dog_before.y > float(blocker.center.y) + expanded_radius
				)
				if both_past:
					_check(
						active_id != str(blocker.id)
							or bool(result.formation_transitioning)
							or bool(result.return_transition_guarded),
						"cleared tree route is not stale direction %d: %s"
							% [direction, str(blocker.id)]
					)
			if (
				(direction < 0 and owner.y <= target_y)
				or (direction > 0 and owner.y >= target_y)
			):
				reached = true
				break
		_check(reached, "exact production slalom passes direction %d" % direction)
		_check(not planner.blocked, "exact production slalom remains traversable direction %d" % direction)
		_check(
			saw_navigation_extension or saw_ids.size() >= 2,
			"non-touching production trees extend or replan direction %d" % direction
		)
		_check(saw_ids.size() >= 2, "production slalom replans beyond the first tree direction %d" % direction)
		_check(
			side_changes <= centers.size(),
			"production slalom side replans stay bounded direction %d" % direction
		)


func _test_commanded_formation_path_and_bounds() -> void:
	var current: Array[Vector2] = [Vector2.ZERO, Vector2(40, 30)]
	var left: Array[Vector2] = [Vector2.ZERO, Vector2(-12, 0)]
	var right: Array[Vector2] = [Vector2.ZERO, Vector2(12, 0)]
	var clear: Array[Vector2] = [Vector2.ZERO, Vector2(30, 24)]
	var planner := _planner(100.0, -100.0, 300.0, 10.0, 90.0)
	var blockers: Array[Dictionary] = [
		_circle("primary", Vector2(100, 40), 10.0),
		_circle("left_transition_guard", Vector2(68, 5), 7.0, "right"),
	]
	if _configure_planner(planner, blockers, "commanded transition"):
		var result := _transition_step(
			planner,
			Vector2(100, 150),
			-70.0,
			0.1,
			current,
			left,
			right,
			clear
		)
		_check(int(result.side) == 1, "opposite-side blocker rejects the commanded dog transition")

	var bounded := _planner(30.0, 0.0, 200.0, 10.0, 90.0)
	var bounded_blockers: Array[Dictionary] = [
		_circle("edge_primary", Vector2(20, 40), 10.0),
	]
	if _configure_planner(bounded, bounded_blockers, "commanded bounds"):
		var bounded_result := _transition_step(
			bounded,
			Vector2(60, 150),
			-70.0,
			0.1,
			current,
			left,
			right,
			clear
		)
		_check(
			int(bounded_result.side) == 1,
			"route bounds reject a side whose commanded dog target leaves bounds"
		)


func _test_clear_return_checks_all_clusters_and_bounds() -> void:
	var left: Array[Vector2] = [Vector2.ZERO, Vector2(-12, 0)]
	var right: Array[Vector2] = [Vector2.ZERO, Vector2(12, 0)]
	var clear: Array[Vector2] = [Vector2.ZERO, Vector2(30, 0)]
	for direction in [-1, 1]:
		var release_y := -30.0 if direction < 0 else 110.0
		var safe_y := -60.0 if direction < 0 else 140.0
		var blockers: Array[Dictionary] = [
			_circle("active_%d" % direction, Vector2(100, 40), 10.0),
			_circle("return_guard_%d" % direction, Vector2(130, release_y), 5.0),
		]
		var planner := _planner(100.0, 0.0, 220.0, 10.0, 100.0)
		if not _configure_planner(planner, blockers, "all-cluster clear return"):
			continue
		var start_y := 150.0 if direction < 0 else -70.0
		var first := _transition_step(
			planner,
			Vector2(100, start_y),
			40.0 * direction,
			0.1,
			[Vector2.ZERO, Vector2(40, 30)],
			left,
			right,
			clear
		)
		var side := int(first.side)
		var current: Array[Vector2] = [
			Vector2.ZERO,
			Vector2(side * 12.0, 0.0),
		]
		var guarded := _transition_step(
			planner,
			Vector2(float(first.target_x), release_y),
			40.0 * direction,
			0.1,
			current,
			left,
			right,
			clear
		)
		_check(
			bool(guarded.return_transition_guarded),
			"clear return checks a separate configured cluster direction %d" % direction
		)
		_check(
			str(guarded.blocker_id).contains("active_%d" % direction),
			"separate clear blocker retains the active route direction %d" % direction
		)
		var released := _transition_step(
			planner,
			Vector2(float(guarded.target_x), safe_y),
			40.0 * direction,
			0.1,
			current,
			left,
			right,
			clear
		)
		_check(
			not bool(released.return_transition_guarded)
				and released.blocker_id == null,
			"clear return eventually releases safely direction %d" % direction
		)
		var return_x := float(released.x)
		for _frame in range(20):
			var returning := _transition_step(
				planner,
				Vector2(return_x, safe_y + direction * 4.0),
				40.0 * direction,
				0.1,
				current,
				left,
				right,
				clear
			)
			return_x = float(returning.x)
		_check(
			is_equal_approx(return_x, 100.0),
			"clear return reaches the preferred lane direction %d" % direction
		)

	for direction in [-1, 1]:
		var beach := _planner(890.0, 575.0, 950.0, 10.0, 100.0)
		var blockers: Array[Dictionary] = [
			_circle("beach_active_%d" % direction, Vector2(890, 40), 10.0),
		]
		if not _configure_planner(beach, blockers, "beach clear bounds"):
			continue
		var start_y := 150.0 if direction < 0 else -70.0
		var first := _transition_step(
			beach,
			Vector2(890, start_y),
			40.0 * direction,
			0.1,
			[Vector2.ZERO, Vector2(40, 30)],
			left,
			right,
			[Vector2.ZERO, Vector2(104, 0)]
		)
		var side := int(first.side)
		var current: Array[Vector2] = [
			Vector2.ZERO,
			Vector2(side * 12.0, 0.0),
		]
		var release_y := -80.0 if direction < 0 else 160.0
		var out_of_bounds := _transition_step(
			beach,
			Vector2(float(first.target_x), release_y),
			40.0 * direction,
			0.1,
			current,
			left,
			right,
			[Vector2.ZERO, Vector2(104, 0)]
		)
		_check(
			bool(out_of_bounds.return_transition_guarded),
			"beach maximum clear offset remains guarded inside route bounds direction %d"
				% direction
		)
		var bounded := _transition_step(
			beach,
			Vector2(float(out_of_bounds.target_x), release_y),
			40.0 * direction,
			0.1,
			current,
			left,
			right,
			[Vector2.ZERO, Vector2(60, 0)]
		)
		_check(
			not bool(bounded.return_transition_guarded)
				and bounded.blocker_id == null,
			"beach bounded clear offset releases without permanent guard direction %d"
				% direction
		)


func _test_configured_cache_and_filtering() -> void:
	var planner := _planner()
	var descriptors: Array[Dictionary] = [
		_circle("valid", Vector2(100, 40), 10.0),
		{"id": "", "center": Vector2(100, 20), "radius": 10.0},
		{"id": "bad", "center": Vector2(NAN, 20), "radius": 10.0},
	]
	if not _configure_planner(planner, descriptors, "cache"):
		return
	_check(int(planner.get("configured_blocker_count")) == 1, "configuration filters malformed blockers once")
	var passes_before := int(planner.get("normalization_passes"))
	for i in range(12):
		_configured_step(planner, Vector2(100, 150 - i * 2), -40.0, 0.05)
	_check(int(planner.get("normalization_passes")) == passes_before, "normal steps reuse normalized blocker state")
	descriptors[0].center = Vector2(1000, 1000)
	var cached := _configured_step(planner, Vector2(100, 100), -40.0, 0.1)
	_check(cached.blocker_id != null, "configured geometry is immutable from source descriptor mutation")


func _test_forward_sweep_spawn() -> void:
	for direction in [-1, 1]:
		var planner := _planner()
		var blockers: Array[Dictionary] = [
			_circle("leading_arc", Vector2(100, 30.0 * direction), 10.0),
		]
		if not _configure_planner(planner, blockers, "leading arc spawn"):
			return
		var result := _configured_spawn(planner, 0.0, 40.0 * direction)
		_check(bool(result.found), "leading arc spawn finds a swept-clear origin direction %d" % direction)
		_check(
			not is_equal_approx(float(result.x), 100.0),
			"point-clear but forward-unsafe preferred spawn relocates direction %d" % direction
		)

	var sealed_planner := _planner()
	var sealed: Array[Dictionary] = [_rect("sweep_sealed", Rect2(-20, -100, 240, 200))]
	if _configure_planner(sealed_planner, sealed, "sealed sweep spawn"):
		var rejected := _configured_spawn(sealed_planner, 0.0, -40.0)
		_check(not bool(rejected.found), "fully sweep-blocked spawn reports no solution")


func _test_swept_candidate_rejection() -> void:
	var steering_blocked := _step(_planner(), Vector2(100, 100), -40.0, [
		_circle("primary", Vector2(100, 40), 15.0),
		_circle("steering_guard", Vector2(87, 100), 2.0),
	])
	_check(
		not bool(steering_blocked.blocked)
			and str(steering_blocked.blocker_id).contains("steering_guard"),
		"blocker on the lateral steering sweep extends the navigation route"
	)

	var staggered_blocked := _step(_planner(), Vector2(100, 100), -40.0, [
		_circle("primary", Vector2(100, 40), 15.0),
		_circle("staggered_guard", Vector2(75, -10), 8.0),
	])
	_check(int(staggered_blocked.side) == 1, "staggered blocker on the forward detour corridor rejects that side")

	var diagonal_sweep_blocked := _step(_planner(), Vector2(100, 100), -40.0, [
		_circle("primary", Vector2(100, 40), 15.0),
		_circle("diagonal_guard", Vector2(87, 75), 2.0),
	])
	_check(
		not bool(diagonal_sweep_blocked.blocked)
			and str(diagonal_sweep_blocked.blocker_id).contains("diagonal_guard"),
		"blocker inside the steering corridor extends the navigation route"
	)


func _test_circle_corner_precision() -> void:
	var result := _step(_planner(), Vector2(100, 100), -40.0, [
		_circle("primary", Vector2(100, 40), 15.0),
		_circle("aabb_corner_only", Vector2(55.1, -4.0), 10.0),
	])
	_check(int(result.side) == -1, "circle AABB corner without swept-circle contact remains passable")


func _test_nearest_circle_uses_actual_corridor_contact() -> void:
	var result := _step(_planner(), Vector2(100, 100), -40.0, [
		_circle("offset_farther", Vector2(76, 40), 15.0, "right"),
		_circle("on_axis_nearer", Vector2(100, 66), 0.1, "left"),
	])
	_check(str(result.blocker_id) == "on_axis_nearer", "nearest circle ranks actual corridor contact, not AABB edge")


func _test_route_bounds_and_spawn() -> void:
	var bounded := _step(_planner(25.0, 20.0, 200.0), Vector2(25, 100), -40.0, [
		_circle("edge", Vector2(25, 40), 15.0),
	])
	_check(int(bounded.side) == 1, "route bounds reject the outside candidate")
	_check(float(bounded.target_x) >= 20.0, "chosen target remains within route bounds")

	var planner := _planner()
	var spawn_blockers: Array[Dictionary] = [_circle("spawn", Vector2(100, 0), 15.0)]
	var spawn_result: Variant = _spawn(planner, 0.0, spawn_blockers)
	_check(spawn_result is Dictionary, "spawn helper returns an explicit result dictionary")
	if not spawn_result is Dictionary:
		return
	_check(bool(spawn_result.found), "spawn helper reports a clear solution")
	var spawn_x := float(spawn_result.x)
	_check(not is_equal_approx(spawn_x, 100.0), "spawn helper moves an obstructed off-screen spawn")
	_check(spawn_x >= 0.0 and spawn_x <= 200.0, "spawn helper keeps initial X within route bounds")
	_check(absf(spawn_x - 100.0) >= 25.0 - 0.001, "spawn result clears circle radius plus entity clearance")
	var clear_spawn: Variant = _spawn(planner, 200.0, spawn_blockers)
	_check(bool(clear_spawn.found), "clear preferred spawn reports success")
	_check(is_equal_approx(float(clear_spawn.x), 100.0), "spawn helper preserves a clear preferred lane")

	var no_solution: Variant = _spawn(planner, 0.0, [
		_rect("sealed_route", Rect2(-50, -50, 300, 100)),
	])
	_check(not bool(no_solution.found), "fully blocked route bounds report explicit spawn failure")
	_check(no_solution.x == null, "failed spawn result carries no obstructed coordinate")


func _test_formation_spawn() -> void:
	var planner := _planner()
	var members: Array[Vector2] = [Vector2.ZERO, Vector2(40, 30)]
	var dog_only_blocker := _circle("dog_only", Vector2(150, 30), 10.0)
	var blockers: Array[Dictionary] = [dog_only_blocker]
	var owner_only: Dictionary = _spawn(planner, 0.0, blockers)
	_check(bool(owner_only.found), "owner-only compatibility spawn remains available")
	_check(
		is_equal_approx(float(owner_only.x), 100.0),
		"owner-only compatibility call preserves its preferred origin"
	)

	var formation: Dictionary = _spawn(planner, 0.0, blockers, members)
	_check(bool(formation.found), "formation spawn finds a shared clear origin")
	if bool(formation.found):
		var origin_x := float(formation.x)
		for offset in members:
			_check(
				not _inside_expanded(Vector2(origin_x, 0.0) + offset, dog_only_blocker, 10.0),
				"every formation member clears the expanded blocker"
			)
		_check(
			not is_equal_approx(origin_x, float(owner_only.x)),
			"formation spawn relocates when only the offset dog is blocked"
		)

	var formation_sealed: Array[Dictionary] = [
		_circle("cover_left", Vector2(42, 30), 1.0),
		_circle("cover_middle", Vector2(139, 30), 1.0),
		_circle("cover_right", Vector2(236, 30), 1.0),
		_circle("cover_edge", Vector2(284, 30), 1.0),
	]
	var bounded_planner := _planner(100.0, 0.0, 250.0, 48.0)
	var bounded_owner_only: Dictionary = _spawn(bounded_planner, 0.0, formation_sealed)
	_check(
		bool(bounded_owner_only.found) and is_equal_approx(float(bounded_owner_only.x), 100.0),
		"owner alone fits the preferred spawn in the formation-sealed case"
	)
	var rejected: Dictionary = _spawn(bounded_planner, 0.0, formation_sealed, members)
	_check(not bool(rejected.found), "fully blocked formation reports explicit spawn failure")
	_check(rejected.x == null, "failed formation spawn carries no origin coordinate")


func _test_invalid_blockers_are_ignored() -> void:
	var invalid: Array[Dictionary] = [
		{},
		{"id": "missing_radius", "center": Vector2(100, 40)},
		_circle("zero_circle", Vector2(100, 40), 0.0),
		_circle("negative_circle", Vector2(100, 40), -5.0),
		_rect("zero_rect", Rect2(85, 35, 0, 30)),
		_rect("negative_rect", Rect2(85, 35, 30, -2)),
		{"id": "bad_center", "center": "nope", "radius": 12.0},
		{"id": "bad_rect", "rect": Vector2.ZERO},
		{"id": "", "center": Vector2(100, 40), "radius": 12.0},
		{"id": 123, "center": Vector2(100, 40), "radius": 12.0},
		{"id": "nan_center", "center": Vector2(NAN, 40), "radius": 12.0},
		{"id": "inf_radius", "center": Vector2(100, 40), "radius": INF},
		{"id": "inf_rect", "rect": Rect2(85, 35, INF, 20)},
	]
	var result := _step(_planner(), Vector2(100, 100), -40.0, invalid)
	_check(is_equal_approx(float(result.x), 100.0), "malformed and non-positive blockers are ignored")
	_check(not bool(result.blocked), "invalid blocker set does not report blocked")


func _test_main_blocker_catalog() -> void:
	var main := Node2D.new()
	main.set_script(load("res://main.gd"))
	var pole_fixture: Array[Vector2] = [Vector2(10, 10), Vector2(20, 20), Vector2(30, 30)]
	var point_fixture: Array[Vector2] = [Vector2(40, 40)]
	var rect_fixture: Array[Rect2] = [Rect2(50, 50, 20, 30)]
	main.poles = pole_fixture
	main.body_pole_count = 2
	main.hydrants = [{"pos": Vector2(60, 60), "done": false, "progress": 0.0}]
	main.fountains = point_fixture
	main.performers = point_fixture
	main.benches = point_fixture
	main.vans = point_fixture
	main.stalls = point_fixture
	main.manholes = point_fixture
	main.cellars = rect_fixture
	main.pond = Rect2(70, 70, 40, 50)
	main.call("_build_bypasser_blockers")

	var catalog: Array[Dictionary] = main.bypasser_blockers
	_check(catalog.size() == 11, "catalog includes every required fixture category exactly once")
	var ids := {}
	for blocker in catalog:
		var id := str(blocker.id)
		_check(not ids.has(id), "catalog IDs are unique: " + id)
		ids[id] = true
	for expected_id in [
		"pole_0", "pole_1", "hydrant_0", "fountain_0", "performer_0",
		"bench_0", "van_0", "stall_0", "manhole_0", "cellar_0", "pond_0",
	]:
		_check(ids.has(expected_id), "catalog contains " + expected_id)
	_check(not ids.has("pole_2"), "catalog excludes rope-only poles after body_pole_count")
	var pond_descriptor: Dictionary = catalog[catalog.size() - 1]
	_check(pond_descriptor.id == "pond_0", "pond catalog ID is stable")
	_check(pond_descriptor.forced_side == "right", "pond catalog forces right-side routing")
	_check(pond_descriptor.rect == main.pond, "pond catalog preserves positive rectangle geometry")

	var source := FileAccess.get_file_as_string("res://main.gd")
	var ready_start := source.find("func _ready()")
	var autowalk_seed_constant := source.find("const AUTOWALK_SEED")
	var autowalk_finish_constant := source.find("const AUTOWALK_MIN_FINISH_TIME")
	var autowalk_request := source.find("autowalk_requested", ready_start)
	var autowalk_seed_call := source.find("seed(AUTOWALK_SEED)", ready_start)
	var level_data_call := source.find("\t_build_level_data()", ready_start)
	var catalog_call := source.find("\t_build_bypasser_blockers()", ready_start)
	var walls_call := source.find("\t_build_walls()", ready_start)
	_check(
		ready_start >= 0
		and level_data_call < catalog_call
		and catalog_call < walls_call,
		"catalog builds after level data and before world/entity construction"
	)
	_check(
		autowalk_seed_constant >= 0
		and ready_start < autowalk_request
		and autowalk_request < autowalk_seed_call
		and autowalk_seed_call < level_data_call,
		"non-daily autowalk selects its named seed before level construction"
	)
	var progress_start := source.find("func _progress(")
	var finish_gate := source.find(
		"elapsed >= AUTOWALK_MIN_FINISH_TIME",
		progress_start
	)
	_check(
		autowalk_finish_constant >= 0
		and progress_start >= 0
		and finish_gate > progress_start,
		"autowalk completion uses a deterministic fixed-fps finish gate"
	)
	main.free()


func _finish() -> void:
	if failures > 0:
		print("test_bypasser_route: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_bypasser_route: OK")
		quit(0)


func _initialize() -> void:
	if not ResourceLoader.exists(SCRIPT_PATH):
		_check(false, "shared bypasser planner script exists")
		_finish()
		return
	_test_clear_travel_and_return()
	_test_out_of_bounds_recovery_is_speed_bounded()
	_test_circle_detours()
	_test_rectangles_in_both_directions()
	_test_forced_right_and_hysteresis()
	_test_connected_forced_side_and_hysteresis()
	_test_formation_release_has_no_second_clearance()
	_test_candidate_rejection()
	_test_production_like_clusters()
	_test_exact_production_park_slalom()
	_test_commanded_formation_path_and_bounds()
	_test_clear_return_checks_all_clusters_and_bounds()
	_test_configured_cache_and_filtering()
	_test_swept_candidate_rejection()
	_test_circle_corner_precision()
	_test_nearest_circle_uses_actual_corridor_contact()
	_test_route_bounds_and_spawn()
	_test_formation_spawn()
	_test_forward_sweep_spawn()
	_test_invalid_blockers_are_ignored()
	_test_main_blocker_catalog()
	_finish()
