extends SceneTree

const PAIR_SCRIPT := "res://otherpair.gd"
const DT := 1.0 / 60.0
const PREFERRED_X := 100.0
const MIN_X := 0.0
const MAX_X := 250.0
const PASS_FRAMES := 900

var failures := 0
var fixtures: Array[Node] = []


class FakeMain:
	extends Node2D

	var phase := "out"
	var frozen := false
	var cam := Node2D.new()
	var bypasser_blockers: Array[Dictionary] = []
	var apologies := 0

	func _init() -> void:
		add_child(cam)

	func float_text(_position: Vector2, text: String, _color: Color) -> void:
		if text == "oh - sorry!":
			apologies += 1


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


func _make_world() -> Dictionary:
	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	var player_dog := Node2D.new()
	player_dog.visible = false
	player_dog.position = Vector2(-10000, -10000)
	root.add_child(player_dog)
	fixtures.append(player_dog)
	return {"main": main, "dog": player_dog}


func _make_pair(
	world: Dictionary,
	start: Vector2,
	direction: Vector2,
	poles: Array[Vector2] = [],
	activate := true
) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load(PAIR_SCRIPT))
	pair.visible = false
	pair.set_physics_process(false)
	pair.setup(world.main, world.dog, poles, start, direction)
	if activate:
		root.add_child(pair)
		pair.set_physics_process(false)
	fixtures.append(pair)
	return pair


func _configure(
	pair: Node2D,
	preferred_x: float,
	min_x: float,
	max_x: float,
	blockers: Array[Dictionary]
) -> bool:
	_check(pair.has_method("configure_route"), "pairs expose route configuration")
	if not pair.has_method("configure_route"):
		return false
	return bool(pair.call("configure_route", preferred_x, min_x, max_x, blockers))


func _require_route(
	pair: Node2D,
	preferred_x: float,
	min_x: float,
	max_x: float,
	blockers: Array[Dictionary],
	label: String
) -> bool:
	var configured := _configure(pair, preferred_x, min_x, max_x, blockers)
	_check(configured, label + " route configuration succeeds")
	if not configured and is_instance_valid(pair):
		fixtures.erase(pair)
		pair.free()
	return configured


func _run_coordinated_pass(
	world: Dictionary,
	blocker_or_cluster: Variant,
	direction: int,
	label: String,
	expected_side := 0,
	rope_poles: Array[Vector2] = []
) -> void:
	var start_y := 340.0 if direction < 0 else -340.0
	var target_y := -260.0 if direction < 0 else 260.0
	var blockers: Array[Dictionary] = []
	if blocker_or_cluster is Dictionary:
		blockers.append(blocker_or_cluster)
	else:
		blockers.assign(blocker_or_cluster)
	var cluster_left := INF
	var cluster_right := -INF
	for blocker in blockers:
		if blocker.has("center"):
			cluster_left = minf(cluster_left, float(blocker.center.x) - float(blocker.radius))
			cluster_right = maxf(cluster_right, float(blocker.center.x) + float(blocker.radius))
		else:
			cluster_left = minf(cluster_left, float(blocker.rect.position.x))
			cluster_right = maxf(cluster_right, float(blocker.rect.end.x))
	var cluster_center_x := (cluster_left + cluster_right) * 0.5
	world.main.bypasser_blockers = blockers
	var pair := _make_pair(
		world,
		Vector2(PREFERRED_X, start_y),
		Vector2(0, direction),
		rope_poles,
		false
	)
	if not _require_route(pair, PREFERRED_X, MIN_X, MAX_X, blockers, label):
		return
	root.add_child(pair)
	pair.set_physics_process(false)
	pair.wander_t = 1000.0
	pair.wander = Vector2(-40.0, 40.0)
	var route: RefCounted = pair.route
	var clearance := float(route.clearance)
	var lateral_cap := float(route.max_lateral_speed)
	var reached_target := false
	var saw_detour := false
	var saw_same_side := false
	var saw_blocked := false
	var contact_frames := 0
	for _frame in PASS_FRAMES:
		world.main.cam.position = pair.npc_owner.position
		var owner_before: Vector2 = pair.npc_owner.position
		var dog_before: Vector2 = pair.npc_dog.position
		pair._physics_process(DT)
		var owner_after: Vector2 = pair.npc_owner.position
		var dog_after: Vector2 = pair.npc_dog.position
		_check(
			absf(owner_after.x - owner_before.x) <= lateral_cap * DT + 0.001,
			label + " owner lateral movement stays bounded"
		)
		_check(
			dog_after.distance_to(dog_before) <= 90.0 * DT + 0.001,
			label + " dog movement keeps the existing speed cap"
		)
		for blocker in blockers:
			_check(
				not _inside_expanded(owner_after, blocker, clearance),
				label + " owner stays outside expanded blocker " + str(blocker.id)
			)
			_check(
				not _inside_expanded(dog_after, blocker, clearance),
				label + " dog stays outside expanded blocker " + str(blocker.id)
			)
		if bool(route.blocked):
			saw_blocked = true
			_check(
				is_equal_approx(owner_after.y, owner_before.y),
				label + " blocked route holds forward owner movement"
			)
		var side := int(route.detour_side)
		if side != 0:
			saw_detour = true
			if expected_side != 0:
				_check(side == expected_side, label + " honors the required detour side")
			var expanded_band := false
			for blocker in blockers:
				if blocker.has("center"):
					expanded_band = expanded_band or (
						absf(owner_after.y - float(blocker.center.y))
							<= float(blocker.radius) + clearance
					)
				else:
					expanded_band = expanded_band or (
						owner_after.y >= float(blocker.rect.position.y) - clearance
						and owner_after.y <= float(blocker.rect.end.y) + clearance
					)
			if expanded_band:
				var owner_side := signi(int(round(owner_after.x - cluster_center_x)))
				var dog_side := signi(int(round(dog_after.x - cluster_center_x)))
				if owner_side == side and dog_side == side:
					saw_same_side = true
		if pair.leash.contacts > 0:
			contact_frames += 1
		if direction < 0 and owner_after.y <= target_y:
			reached_target = true
			break
		if direction > 0 and owner_after.y >= target_y:
			reached_target = true
			break
	_check(reached_target, label + " continues past the blocker")
	_check(saw_detour, label + " activates one shared detour")
	_check(saw_same_side, label + " owner and dog commit to the same side")
	_check(not saw_blocked, label + " has a viable coordinated route")
	_check(
		absf(pair.npc_owner.position.x - PREFERRED_X) <= 0.01,
		label + " owner returns to the preferred lane"
	)
	_check(pair.leash.contacts == 0, label + " finishes without leash contact")
	_check(contact_frames <= 2, label + " avoids meaningful accumulated leash contact")
	_check(absf(pair.leash.winding()) < 0.75, label + " finishes without meaningful leash winding")


func _test_real_pair_avoids_supported_geometry(world: Dictionary) -> void:
	for direction in [-1, 1]:
		_run_coordinated_pass(
			world,
			_rect("pond_%d" % direction, Rect2(75, -55, 65, 110), "right"),
			direction,
			"forced-right pond direction %d" % direction,
			1
		)
		_run_coordinated_pass(
			world,
			_circle("tree_%d" % direction, Vector2(100, 0), 22.0),
			direction,
			"circular tree direction %d" % direction,
			-1,
			[Vector2(100, 0)]
		)
		_run_coordinated_pass(
			world,
			_rect("bench_%d" % direction, Rect2(78, -48, 44, 96)),
			direction,
			"rectangular furniture direction %d" % direction,
			-1
		)
		var table_chairs: Array[Dictionary] = [
			_circle("table_%d" % direction, Vector2(80, 20), 10.0),
			_circle("chair_l_%d" % direction, Vector2(60, 45), 7.0),
			_circle("chair_r_%d" % direction, Vector2(100, 45), 7.0),
		]
		_run_coordinated_pass(
			world,
			table_chairs,
			direction,
			"table-chair cluster direction %d" % direction,
			1
		)
		var tree_slalom: Array[Dictionary] = [
			_circle("slalom_0_%d" % direction, Vector2(110, 75), 10.0),
			_circle("slalom_1_%d" % direction, Vector2(130, 40), 10.0),
			_circle("slalom_2_%d" % direction, Vector2(110, 5), 10.0),
		]
		_run_coordinated_pass(
			world,
			tree_slalom,
			direction,
			"opposite-side tree cluster direction %d" % direction,
			-1,
			[Vector2(110, 75), Vector2(130, 40), Vector2(110, 5)]
		)


func _test_exact_production_park_slalom(world: Dictionary) -> void:
	var centers: Array[Vector2] = [
		Vector2(570, -1150),
		Vector2(690, -1280),
		Vector2(570, -1410),
		Vector2(690, -1540),
	]
	var blockers: Array[Dictionary] = []
	for i in centers.size():
		blockers.append(_circle("production_slalom_%d" % i, centers[i], 10.0))
	for direction in [-1, 1]:
		var start_y := -900.0 if direction < 0 else -1790.0
		var target_y := -1790.0 if direction < 0 else -900.0
		var label := "exact production park slalom direction %d" % direction
		var pair := _make_pair(
			world,
			Vector2(640, start_y),
			Vector2(0, direction),
			centers,
			false
		)
		if not _require_route(pair, 640.0, 330.0, 950.0, blockers, label):
			continue
		root.add_child(pair)
		pair.set_physics_process(false)
		pair.wander_t = 1000.0
		pair.wander = Vector2.ZERO
		var route: RefCounted = pair.route
		var reached := false
		var saw_extended_navigation := false
		var saw_replan := false
		var previous_id := ""
		for _frame in range(1200):
			world.main.cam.position = pair.npc_owner.position
			var owner_before: Vector2 = pair.npc_owner.position
			var dog_before: Vector2 = pair.npc_dog.position
			pair._physics_process(DT)
			var owner_after: Vector2 = pair.npc_owner.position
			var dog_after: Vector2 = pair.npc_dog.position
			_check(
				absf(owner_after.x - owner_before.x)
					<= float(route.max_lateral_speed) * DT + 0.001,
				label + " owner movement stays bounded"
			)
			_check(
				dog_after.distance_to(dog_before) <= 90.0 * DT + 0.001,
				label + " commanded dog transition stays bounded"
			)
			for blocker in blockers:
				_check(
					not _inside_expanded(owner_after, blocker, 48.0),
					label + " owner clears " + str(blocker.id)
				)
				_check(
					not _inside_expanded(dog_after, blocker, 48.0),
					label + " actual dog path clears " + str(blocker.id)
				)
			var active_id := str(route.active_blocker_id)
			for blocker in blockers:
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
							or bool(route.formation_transitioning)
							or bool(route.return_transition_guarded),
						label + " does not retain a cleared tree as its sole route"
					)
			if active_id != previous_id and not previous_id.is_empty() and active_id != "<null>":
				saw_replan = true
			previous_id = active_id
			saw_extended_navigation = saw_extended_navigation or (
				active_id.contains("production_slalom_0")
				and active_id.contains("production_slalom_1")
			)
			if (
				(direction < 0 and owner_after.y <= target_y)
				or (direction > 0 and owner_after.y >= target_y)
			):
				reached = true
				break
		_check(reached, label + " reaches the far side")
		_check(not bool(route.blocked), label + " does not falsely report boxed")
		_check(saw_replan, label + " advances beyond the first non-touching tree")
		_check(
			saw_extended_navigation or saw_replan,
			label + " extends or replans across upcoming non-touching trees"
		)
		_check(pair.leash.contacts == 0, label + " finishes without leash contacts")
		_check(absf(pair.leash.winding()) < 0.75, label + " finishes without leash winding")


func _test_beach_clear_offset_is_route_bounded(world: Dictionary) -> void:
	var pair := _make_pair(world, Vector2(890, 200), Vector2.UP, [], false)
	if not _require_route(pair, 890.0, 575.0, 950.0, [], "beach clear offset"):
		return
	root.add_child(pair)
	pair.set_physics_process(false)
	pair.wander = Vector2(40, 0)
	world.dog.position = pair.npc_dog.global_position + Vector2(100, 0)
	_check(
		pair.has_method("_raw_clear_dog_offset"),
		"pair exposes raw clear offset before route-bound targeting"
	)
	if not pair.has_method("_raw_clear_dog_offset"):
		return
	var raw_offset: Vector2 = pair.call("_raw_clear_dog_offset")
	var bounded_offset: Vector2 = pair.call("_clear_dog_offset")
	_check(
		is_equal_approx(raw_offset.x, 104.0),
		"beach clear offset includes maximum wander and curiosity"
	)
	_check(
		is_equal_approx(bounded_offset.x, 60.0),
		"beach clear dog target stays inside the route maximum"
	)
	_check(
		is_equal_approx(float(pair.route.preferred_x) + bounded_offset.x, 950.0),
		"bounded beach clear target reaches the route edge exactly"
	)


func _test_spawn_selection_and_rejection(world: Dictionary) -> void:
	var circle: Array[Dictionary] = [_circle("spawn_tree", Vector2(100, 0), 20.0)]
	var relocated := _make_pair(world, Vector2(100, 0), Vector2.UP, [], false)
	var owner_before: Vector2 = relocated.npc_owner.position
	var dog_before: Vector2 = relocated.npc_dog.position
	if _require_route(relocated, 100.0, 0.0, 250.0, circle, "relocated pair spawn"):
		_check(
			not is_equal_approx(relocated.npc_owner.position.x, owner_before.x),
			"blocked preferred spawn relocates the owner"
		)
		var shift: Vector2 = relocated.npc_owner.position - owner_before
		_check(
			relocated.npc_dog.position.is_equal_approx(dog_before + shift),
			"spawn relocation shifts owner and dog together"
		)
		var clearance := float(relocated.route.clearance)
		for blocker in circle:
			_check(
				not _inside_expanded(relocated.npc_owner.position, blocker, clearance),
				"relocated owner clears every expanded spawn blocker"
			)
			_check(
				not _inside_expanded(relocated.npc_dog.position, blocker, clearance),
				"relocated dog clears every expanded spawn blocker"
			)
		_check(
			relocated.leash.pts[0].is_equal_approx(relocated.npc_dog.global_position),
			"spawn relocation resnaps the dog end of the leash"
		)
		_check(
			relocated.leash.pts[relocated.leash.N - 1].is_equal_approx(
				relocated.leash.call("_hand_pos")
			),
			"spawn relocation resnaps the owner end of the leash"
		)

	var formation_sealed: Array[Dictionary] = [
		_circle("cover_left", Vector2(42, 30), 1.0),
		_circle("cover_middle", Vector2(139, 30), 1.0),
		_circle("cover_right", Vector2(236, 30), 1.0),
		_circle("cover_edge", Vector2(284, 30), 1.0),
	]
	var formation_rejected := _make_pair(world, Vector2(100, 0), Vector2.UP, [], false)
	for blocker in formation_sealed:
		_check(
			not _inside_expanded(
				formation_rejected.npc_owner.position,
				blocker,
				float(formation_rejected.PAIR_CLEARANCE)
			),
			"owner alone fits the formation-sealed spawn"
		)
	_check(
		not _configure(formation_rejected, 100.0, 0.0, 250.0, formation_sealed),
		"pair spawn rejects a corridor blocked for the dog formation"
	)
	_check(
		formation_rejected.route == null,
		"formation-rejected pair clears its route"
	)

	var sealed: Array[Dictionary] = [
		_rect("sealed_spawn", Rect2(-100, -100, 500, 200)),
	]
	var rejected := _make_pair(world, Vector2(100, 0), Vector2.UP, [], false)
	_check(
		not _configure(rejected, 100.0, 0.0, 250.0, sealed),
		"fully blocked pair spawn is explicitly rejected"
	)
	if rejected.has_method("configure_route"):
		_check(rejected.route == null, "rejected pair clears its route")
	_check(not rejected.is_inside_tree(), "rejected pair remains inactive off-tree")

	for direction in [-1, 1]:
		var leading: Array[Dictionary] = [
			_circle("leading_arc_%d" % direction, Vector2(60, 55.0 * direction), 1.0),
		]
		var swept_pair := _make_pair(
			world,
			Vector2(100, 0),
			Vector2(0, direction),
			[],
			false
		)
		var label := "pair leading arc direction %d" % direction
		if _require_route(swept_pair, 100.0, 0.0, 250.0, leading, label):
			_check(
				not is_equal_approx(swept_pair.npc_owner.position.x, 100.0),
				label + " relocates the point-clear formation before its initial sweep"
			)

	var source := FileAccess.get_file_as_string("res://main.gd")
	var pairs_start := source.find("func _make_pair")
	var pairs_end := source.find("func _pairs", pairs_start)
	var pairs_source := source.substr(pairs_start, pairs_end - pairs_start)
	var setup_call := pairs_source.find("pair.setup")
	var configure_call := pairs_source.find("pair.configure_route", setup_call)
	var free_call := pairs_source.find("pair.free()", configure_call)
	var add_call := pairs_source.find("add_child(pair)", configure_call)
	_check(
		setup_call >= 0
		and configure_call > setup_call
		and free_call > configure_call
		and add_call > free_call,
		"main configures and rejects pair spawns before activation"
	)
	_check(
		pairs_source.find("walk_cx - walk_half + 30.0") >= 0
		and pairs_source.find("walk_cx + walk_half - 30.0") >= 0,
		"main supplies the full inset pair corridor"
	)
	_check(
		pairs_source.find("bypasser_blockers") >= 0,
		"main supplies the shared blocker catalog"
	)


func _test_normal_target_semantics(world: Dictionary) -> void:
	var pair := _make_pair(world, Vector2(100, 300), Vector2.UP)
	var blockers: Array[Dictionary] = []
	if not _require_route(pair, 100.0, 0.0, 250.0, blockers, "clear pair"):
		return
	pair.wander_t = 1000.0
	pair.wander = Vector2(17.0, -11.0)
	world.dog.position = pair.npc_dog.global_position + Vector2(100, 0)
	var owner_expected: Vector2 = pair.npc_owner.position + Vector2(0, pair.vel.y * DT)
	var curious := Vector2(34.0, 0.0)
	var target: Vector2 = owner_expected + Vector2(30, 24) + pair.wander + curious
	var dog_expected: Vector2 = pair.npc_dog.position.move_toward(target, 90.0 * DT)
	pair._physics_process(DT)
	_check(
		pair.npc_owner.position.is_equal_approx(owner_expected),
		"clear route preserves owner vertical movement"
	)
	_check(
		pair.npc_dog.position.is_equal_approx(dog_expected),
		"outside a detour the exact wander and curiosity target is preserved"
	)


func _test_blocked_hold_and_tangle_rooting(world: Dictionary) -> void:
	var blocked_geometry: Array[Dictionary] = [
		_rect("sealed_ahead", Rect2(70, 20, 160, 100), "right"),
	]
	var blocked_pair := _make_pair(world, Vector2(100, 260), Vector2.UP)
	if _require_route(
		blocked_pair,
		100.0,
		0.0,
		180.0,
		[],
		"runtime-blocked pair"
	):
		blocked_pair.route.call("configure_blockers", blocked_geometry)
		var owner_before: Vector2 = blocked_pair.npc_owner.position
		var dog_before: Vector2 = blocked_pair.npc_dog.position
		blocked_pair._physics_process(DT)
		_check(bool(blocked_pair.route.blocked), "sealed forward route reports blocked")
		_check(
			is_equal_approx(blocked_pair.npc_owner.position.y, owner_before.y),
			"blocked pair holds forward owner movement"
		)
		_check(
			absf(blocked_pair.npc_owner.position.x - owner_before.x)
				<= float(blocked_pair.route.max_lateral_speed) * DT + 0.001,
			"blocked owner lateral movement remains bounded"
		)
		_check(
			blocked_pair.npc_dog.position.distance_to(dog_before) <= 90.0 * DT + 0.001,
			"blocked dog catch-up remains bounded"
		)

	var route_geometry: Array[Dictionary] = [
		_circle("rooted_tree", Vector2(100, 0), 20.0),
	]
	var rooted := _make_pair(world, Vector2(100, 250), Vector2.UP)
	if not _require_route(rooted, 100.0, 0.0, 250.0, route_geometry, "rooted pair"):
		return
	rooted._physics_process(DT)
	var active_id: Variant = rooted.route.active_blocker_id
	var rooted_position: Vector2 = rooted.npc_owner.position
	rooted.tangled_t = 0.4
	rooted._physics_process(0.1)
	_check(
		rooted.npc_owner.position.is_equal_approx(rooted_position),
		"positive tangle timer roots the routed owner"
	)
	_check(rooted.tangled_t > 0.0, "physics does not silently clear the tangle timer")
	_check(
		rooted.route.active_blocker_id == active_id,
		"tangle rooting preserves active route state"
	)


func _test_freedom_cleanup(world: Dictionary) -> void:
	var pair := _make_pair(world, Vector2(100, 300), Vector2.UP)
	var blockers: Array[Dictionary] = []
	if not _require_route(pair, 100.0, 0.0, 250.0, blockers, "freedom pair"):
		return
	world.main.phase = "freedom"
	pair._physics_process(0.0)
	_check(pair.is_queued_for_deletion(), "freedom cleanup still queues an active routed pair")
	world.main.phase = "out"


func _cleanup() -> void:
	for fixture in fixtures:
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_pair_pond_avoidance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_pond_avoidance: OK")
		quit(0)


func _initialize() -> void:
	seed(3003)
	var world := _make_world()
	_test_real_pair_avoids_supported_geometry(world)
	_test_exact_production_park_slalom(world)
	_test_beach_clear_offset_is_route_bounded(world)
	_test_spawn_selection_and_rejection(world)
	_test_normal_target_semantics(world)
	_test_blocked_hold_and_tangle_rooting(world)
	_test_freedom_cleanup(world)
	_finish()
