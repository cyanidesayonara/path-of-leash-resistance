extends Node2D

# Another dog-walker: an NPC owner and dog joined by their own leash
# (a real leash.gd rope). They amble along the path. When their leash
# crosses yours, the two ropes drape over each other and TANGLE - the
# flagship dog-park mayhem, emergent from the shared rope physics.

const BypasserRouteScript := preload("res://bypasser_route.gd")
const DogAppearanceScript := preload("res://dog_appearance.gd")
const HumanAppearanceScript := preload("res://human_appearance.gd")
const TANGLE_REARM_S := 0.5
const PAIR_CLEARANCE := 48.0
const PAIR_MAX_LATERAL_SPEED := 90.0
const PAIR_MINIMUM_LOOKAHEAD := 240.0
const PAIR_LOOKAHEAD_TIME := 1.35
const DOG_SPEED := 90.0
const LEASH_CAP := 150.0
const INITIAL_DOG_OFFSET := Vector2(40, 30)
const DOG_DETOUR_OFFSET := 12.0
const PARK_OWNER_SPEED := 82.0
const PARK_DOG_SPEED := 110.0
const PARK_RECALL_SPEED := 150.0
const PARK_STAY_MIN := 7.0
const PARK_STAY_MAX := 15.0
const RELEASH_DISTANCE := 18.0

enum PairState {
	WALKING,
	ARRIVING,
	PARKED,
	RECALLING,
	DEPARTING,
}

var main: Node2D
var my_dog: Node2D
var npc_owner: Node2D
var npc_dog: Node2D
var leash: Node2D
var vel := Vector2.ZERO
var owner_col := Color(0.5, 0.45, 0.55)
var dog_col := Color(0.6, 0.5, 0.4)
var owner_appearance_profile: Dictionary = {}
var appearance_profile: Dictionary = {}
var wander_t := 0.0
var wander := Vector2.ZERO
var seed_o := 0.0
var tangled_t := 0.0
var tangle_active := false
var tangle_clear_t := 0.0
var sampled: Array[Vector2] = []
var route: RefCounted
var desired_vertical_speed := 0.0
var pair_state := PairState.WALKING
var park_gate_y := -INF
var park_bounds := Rect2()
var park_spot := Vector2.ZERO
var park_stay_t := 0.0
var park_dog_vel := Vector2.ZERO
var park_slot_id := -1
var park_area_configured := false
var walking_lane_x := 0.0


func setup(m: Node2D, mine: Node2D, poles: Array[Vector2], start: Vector2, direction: Vector2) -> void:
	add_to_group("pairs")
	main = m
	my_dog = mine
	vel = direction * randf_range(58.0, 82.0)
	seed_o = randf() * 10.0
	var owner_appearance_key := randi()
	owner_appearance_profile = HumanAppearanceScript.profile_for_key(owner_appearance_key)
	owner_col = owner_appearance_profile["shirt_color"]
	var dog_appearance_key := randi()
	appearance_profile = DogAppearanceScript.profile_for_key(dog_appearance_key)
	dog_col = appearance_profile["base_color"]
	npc_owner = Node2D.new()
	npc_owner.position = start
	add_child(npc_owner)
	npc_dog = Node2D.new()
	npc_dog.position = start + INITIAL_DOG_OFFSET
	add_child(npc_dog)
	leash = Node2D.new()
	leash.set_script(load("res://leash.gd"))
	leash.z_index = 6
	add_child(leash)
	leash.setup(npc_dog, npc_owner, poles, 150.0)


func configure_route(
	preferred_x: float,
	min_x: float,
	max_x: float,
	blockers: Array[Dictionary]
) -> bool:
	route = BypasserRouteScript.new(
		preferred_x,
		min_x,
		max_x,
		PAIR_CLEARANCE,
		PAIR_MAX_LATERAL_SPEED,
		PAIR_MINIMUM_LOOKAHEAD,
		PAIR_LOOKAHEAD_TIME
	)
	route.call("configure_blockers", blockers)
	desired_vertical_speed = vel.y
	walking_lane_x = preferred_x
	var formation_offsets: Array[Vector2] = [Vector2.ZERO, INITIAL_DOG_OFFSET]
	var spawn: Dictionary = route.call(
		"find_clear_spawn_x",
		npc_owner.global_position.y,
		desired_vertical_speed,
		formation_offsets
	)
	if not bool(spawn.found):
		route = null
		return false
	var shift_x := float(spawn.x) - npc_owner.global_position.x
	if not is_zero_approx(shift_x):
		npc_owner.position.x += shift_x
		npc_dog.position.x += shift_x
		leash.resnap()
	return true


func configure_park_area(gate_y: float, bounds: Rect2) -> void:
	park_gate_y = gate_y
	park_bounds = bounds
	park_area_configured = bounds.size.x > 0.0 and bounds.size.y > 0.0


func begin_park_arrival(slot_id: int, spot: Vector2) -> bool:
	if not park_area_configured or pair_state != PairState.WALKING or slot_id < 0:
		return false
	park_slot_id = slot_id
	park_spot = spot
	pair_state = PairState.ARRIVING
	return true


func initialize_parked_departure(
	slot_id: int,
	spot: Vector2,
	dog_position: Vector2,
	stay_time: float
) -> bool:
	if not park_area_configured or pair_state != PairState.WALKING or slot_id < 0:
		return false
	park_slot_id = slot_id
	park_spot = spot
	npc_owner.position = spot
	npc_dog.position = Vector2(
		clampf(dog_position.x, park_bounds.position.x, park_bounds.end.x),
		clampf(dog_position.y, park_bounds.position.y, park_bounds.end.y)
	)
	_enter_parked(stay_time)
	return true


func begin_park_recall() -> void:
	if pair_state == PairState.PARKED or pair_state == PairState.ARRIVING:
		if pair_state == PairState.ARRIVING:
			park_spot = npc_owner.position
		pair_state = PairState.RECALLING
		park_stay_t = 0.0
		park_dog_vel = Vector2.ZERO
	if pair_state == PairState.RECALLING:
		_suspend_leash()


func begin_departure() -> void:
	begin_home_departure()


func begin_home_departure() -> void:
	if pair_state == PairState.WALKING:
		if desired_vertical_speed < 0.0:
			desired_vertical_speed = absf(desired_vertical_speed)
			vel = Vector2(0.0, desired_vertical_speed)
		return
	begin_park_recall()


func get_pair_state() -> PairState:
	return pair_state


func is_park_lifecycle_active() -> bool:
	return pair_state != PairState.WALKING


func has_park_slot() -> bool:
	return park_slot_id >= 0


func is_parked() -> bool:
	return pair_state == PairState.PARKED


func _physics_process(delta: float) -> void:
	if main.phase == "freedom" and not park_area_configured:
		queue_free()
		return
	if main.frozen:
		return
	tangled_t = maxf(0.0, tangled_t - delta)
	if main.phase == "home" and (
		pair_state == PairState.PARKED or pair_state == PairState.ARRIVING
	):
		begin_park_recall()
	match pair_state:
		PairState.ARRIVING:
			_tick_arriving(delta)
		PairState.PARKED:
			_tick_parked(delta)
		PairState.RECALLING:
			_tick_recalling(delta)
		PairState.DEPARTING:
			_tick_departing(delta)
		_:
			_tick_walking(delta, true)
	if pair_state == PairState.WALKING:
		if absf(npc_owner.position.y - float(main.cam.position.y)) > 1200.0:
			queue_free()
	# owner/dog move via transform every frame; redraw the pose at ~30fps
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func _tick_walking(delta: float, _allow_arrival: bool) -> void:
	var route_was_clear := (
		route != null
		and int(route.get("detour_side")) == 0
		and not bool(route.get("blocked"))
	)
	if route_was_clear:
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(0.6, 1.6)
			wander = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 40.0
	var clear_dog_offset := _clear_dog_offset()
	# the owner ambles in their lane; a tangle roots them in place
	if tangled_t <= 0.0 and route != null:
		var before: Vector2 = npc_owner.position
		var formation_offsets: Array[Vector2] = [
			Vector2.ZERO,
			npc_dog.position - before,
		]
		var left_offsets: Array[Vector2] = [
			Vector2.ZERO,
			Vector2(-DOG_DETOUR_OFFSET, 0.0),
		]
		var right_offsets: Array[Vector2] = [
			Vector2.ZERO,
			Vector2(DOG_DETOUR_OFFSET, 0.0),
		]
		var clear_offsets: Array[Vector2] = [
			Vector2.ZERO,
			clear_dog_offset,
		]
		var result: Dictionary = route.call(
			"step",
			before,
			desired_vertical_speed,
			delta,
			formation_offsets,
			left_offsets,
			right_offsets,
			clear_offsets
		)
		npc_owner.position = Vector2(
			float(result.x),
			before.y
				if bool(result.blocked) or bool(result.formation_transitioning)
				else before.y + desired_vertical_speed * delta
		)
	var detour_side := int(route.get("detour_side")) if route != null else 0
	var route_blocked := bool(route.get("blocked")) if route != null else false
	if detour_side != 0:
		var detour_target := Vector2(
			float(route.get("detour_target_x")) + detour_side * DOG_DETOUR_OFFSET,
			npc_owner.position.y
		)
		npc_dog.position = _move_dog_lateral_first(
			npc_dog.position,
			detour_target,
			DOG_SPEED * delta
		)
	elif route_blocked:
		npc_dog.position = _move_dog_lateral_first(
			npc_dog.position,
			npc_owner.position,
			DOG_SPEED * delta
		)
	else:
		# Outside a detour the pair retains its original wandering behavior.
		var target := npc_owner.position + clear_dog_offset
		if route != null:
			target.x = clampf(
				target.x,
				float(route.get("min_x")),
				float(route.get("max_x"))
			)
		npc_dog.position = npc_dog.position.move_toward(target, DOG_SPEED * delta)
	# keep the dog within their (short) leash
	var span := npc_dog.position - npc_owner.position
	if span.length() > LEASH_CAP:
		npc_dog.position = npc_owner.position + span.normalized() * LEASH_CAP
	leash.tick(delta)
	_sample_rope()


func _tick_arriving(delta: float) -> void:
	var before := npc_owner.position
	npc_owner.position = npc_owner.position.move_toward(park_spot, PARK_OWNER_SPEED * delta)
	vel = (npc_owner.position - before) / delta if delta > 0.0 else Vector2.ZERO
	var target := npc_owner.position + INITIAL_DOG_OFFSET * 0.55
	npc_dog.position = npc_dog.position.move_toward(target, DOG_SPEED * delta)
	_cap_dog_to_owner()
	leash.tick(delta)
	_sample_rope()
	if npc_owner.position.is_equal_approx(park_spot):
		_enter_parked(randf_range(PARK_STAY_MIN, PARK_STAY_MAX))


func _enter_parked(stay_time: float) -> void:
	pair_state = PairState.PARKED
	park_stay_t = maxf(stay_time, 0.0)
	park_dog_vel = Vector2.ZERO
	_suspend_leash()
	tangled_t = 0.0
	tangle_active = false
	tangle_clear_t = 0.0


func _tick_parked(delta: float) -> void:
	npc_owner.position = park_spot
	sampled.clear()
	leash.dynamic_obstacles.clear()
	if main.phase == "freedom":
		park_stay_t = maxf(0.0, park_stay_t - delta)
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(0.5, 1.5)
			if randf() < 0.4 and my_dog.global_position.distance_to(npc_dog.global_position) < 300.0:
				park_dog_vel = (my_dog.global_position - npc_dog.global_position).normalized() * 150.0
			else:
				park_dog_vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * PARK_DOG_SPEED
		npc_dog.position += park_dog_vel * delta
		park_dog_vel = park_dog_vel.move_toward(Vector2.ZERO, 120.0 * delta)
		npc_dog.position.x = clampf(npc_dog.position.x, park_bounds.position.x, park_bounds.end.x)
		npc_dog.position.y = clampf(npc_dog.position.y, park_bounds.position.y, park_bounds.end.y)
	if park_stay_t <= 0.0 and main.phase == "freedom":
		pair_state = PairState.RECALLING


func _tick_recalling(delta: float) -> void:
	npc_owner.position = park_spot
	_suspend_leash()
	park_dog_vel = Vector2.ZERO
	npc_dog.position = npc_dog.position.move_toward(npc_owner.position, PARK_RECALL_SPEED * delta)
	if npc_dog.position.distance_to(npc_owner.position) <= RELEASH_DISTANCE:
		leash.detached = false
		leash.dynamic_obstacles.clear()
		leash.resnap()
		leash.visible = true
		pair_state = PairState.DEPARTING
		desired_vertical_speed = absf(desired_vertical_speed)
		vel = Vector2(0.0, desired_vertical_speed)
		if route != null:
			route.set("preferred_x", walking_lane_x)


func _suspend_leash() -> void:
	leash.detached = true
	leash.visible = false
	leash.dynamic_obstacles.clear()
	sampled.clear()


func _tick_departing(delta: float) -> void:
	var gate_exit := Vector2(walking_lane_x, park_gate_y + 80.0)
	var before := npc_owner.position
	npc_owner.position = npc_owner.position.move_toward(gate_exit, PARK_OWNER_SPEED * delta)
	vel = (npc_owner.position - before) / delta if delta > 0.0 else Vector2.ZERO
	var target := npc_owner.position + INITIAL_DOG_OFFSET
	npc_dog.position = npc_dog.position.move_toward(target, DOG_SPEED * delta)
	_cap_dog_to_owner()
	leash.tick(delta)
	_sample_rope()
	if npc_owner.position.is_equal_approx(gate_exit):
		pair_state = PairState.WALKING
		desired_vertical_speed = absf(desired_vertical_speed)
		vel = Vector2(0.0, desired_vertical_speed)
		_release_park_spot()


func _release_park_spot() -> void:
	if park_slot_id < 0:
		return
	park_slot_id = -1
	if is_instance_valid(main) and main.has_method("release_pair_park_spot"):
		main.call("release_pair_park_spot", get_instance_id())


func _sample_rope() -> void:
	sampled.clear()
	for i in range(0, leash.N, 2):
		sampled.append(leash.pts[i])


func _cap_dog_to_owner() -> void:
	var span := npc_dog.position - npc_owner.position
	if span.length() > LEASH_CAP:
		npc_dog.position = npc_owner.position + span.normalized() * LEASH_CAP


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_UNPARENTED
		or what == NOTIFICATION_EXIT_TREE
		or what == NOTIFICATION_PREDELETE
	):
		_release_park_spot()


func _move_dog_lateral_first(from: Vector2, target: Vector2, distance: float) -> Vector2:
	var available := maxf(distance, 0.0)
	var lateral_target := Vector2(target.x, from.y)
	var moved := from.move_toward(lateral_target, available)
	available -= moved.distance_to(from)
	return moved.move_toward(target, available)


func _clear_dog_offset() -> Vector2:
	var offset := _raw_clear_dog_offset()
	if route == null:
		return offset
	var route_preferred_x := float(route.get("preferred_x"))
	offset.x = (
		clampf(
			route_preferred_x + offset.x,
			float(route.get("min_x")),
			float(route.get("max_x"))
		)
		- route_preferred_x
	)
	return offset


func _raw_clear_dog_offset() -> Vector2:
	var to_mine := my_dog.global_position - npc_dog.global_position
	var curious := to_mine.normalized() * 34.0 if to_mine.length() < 160.0 else Vector2.ZERO
	return Vector2(30, 24) + wander + curious


func update_tangle_state(crossing: bool, delta: float) -> bool:
	if crossing:
		tangled_t = 0.4
		tangle_clear_t = 0.0
		if tangle_active:
			return false
		tangle_active = true
		main.float_text(npc_owner.position, "oh - sorry!", Color(1, 0.9, 0.8))
		return true
	if tangle_active:
		tangle_clear_t += delta
		if tangle_clear_t >= TANGLE_REARM_S:
			tangle_active = false
			tangle_clear_t = 0.0
	return false


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var owner_forward := vel
	var owner_gait_amount := (
		0.0
		if pair_state == PairState.PARKED or pair_state == PairState.RECALLING
		else clampf(vel.length() / 82.0, 0.0, 1.0)
	)
	var owner_phone_glow := 0.55 + 0.2 * sin(t * 7.3 + seed_o)
	HumanAppearanceScript.draw_owner(
		self,
		owner_appearance_profile,
		npc_owner.position,
		owner_forward,
		t * 6.0 + seed_o,
		owner_gait_amount,
		owner_phone_glow,
		"held"
	)
	# NPC dog remains drawn by the pair parent; npc_dog stays the real endpoint.
	var dp: Vector2 = npc_dog.position
	var facing := (my_dog.global_position - dp).normalized()
	var bob := sin(t * 6.0 + seed_o) * 1.5
	var wag := t * 8.0 + seed_o
	DogAppearanceScript.draw_dog(
		self,
		appearance_profile,
		dp,
		facing,
		bob,
		wag
	)
