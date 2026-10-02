extends Node2D

# Another dog-walker: an NPC owner and dog joined by their own leash
# (a real leash.gd rope). They amble along the path. When their leash
# crosses yours, the two ropes drape over each other and TANGLE - the
# flagship dog-park mayhem, emergent from the shared rope physics.

const BypasserRouteScript := preload("res://systems/bypasser_route.gd")
const DogAppearanceScript := preload("res://entities/dog_appearance.gd")
const HumanAppearanceScript := preload("res://entities/human_appearance.gd")
const TANGLE_REARM_S := 0.5
# Owner roots briefly on contact; bound so a stuck geometry contact cannot
# freeze the lane forever. 90 frames at 60 Hz = ordinary recovery target.
const TANGLE_ROOT_S := 0.4
const TANGLE_PAUSE_MAX_S := 1.5
# Mercy ramp begins at the taut-escape budget (180 frames); hard release at
# 300 frames so every supported single-pair encounter frees in time.
const TANGLE_MERCY_RAMP_S := 3.0
const TANGLE_MERCY_S := 5.0
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
# How the pair LOOKS alive (presentation, plus the dog's sniff stops): the
# owner walks only when actually moving and faces where they go; the dog
# eases up to speed instead of gliding, stops now and then to sniff (the
# leash then tows it on), looks at your dog only when it is close, and wags
# harder when it does.
const DOG_ACCEL := 320.0
const SNIFF_MIN := 0.8
const SNIFF_MAX := 1.9
const SNIFF_GAP_MIN := 3.0
const SNIFF_GAP_MAX := 7.5
const CURIOUS_R := 160.0
# a sniff stop goes to a post if there is one coming up by the dog's line: a
# hydrant, a lamppost, a tree, up to SPOT_REACH across and SPOT_AHEAD along
# the way they are walking. A good sniff there gets a reply MARK_P of the
# time, at most MARKS_MAX a walk, and leaves a mark your dog can read.
const SPOT_REACH := 120.0
const SPOT_AHEAD := 150.0
const MARK_P := 0.6
const MARK_T := 1.1
const MARKS_MAX := 2
# meeting your dog nose to nose: the other dog stops and sniffs back, and
# its owner waits that long; GRUMPY_P of dogs would rather not
const GREET_HOLD := 1.4
const GRUMPY_P := 0.2
const NAMES := ["a terrier", "a beagle", "a whippet", "a poodle", "a sausage dog", "a labrador",
	"a staffie", "a pug", "a greyhound", "a collie", "a spaniel", "a chihuahua"]
const POSE_EASE := 0.25

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
var tangle_touching := false
var tangle_root_acc := 0.0
var tangle_hold_t := 0.0
var mercy_shown := false
# After a hard mercy release, stay disengaged until geometry separates so the
# rising-edge reward cannot re-fire every TANGLE_MERCY_S on the same snag.
var mercy_hold := false
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
# the pose: velocities measured from where the owner and dog actually went,
# where each faces, and how far each has walked (the gait follows distance,
# so a rooted owner stands still instead of walking on the spot)
var owner_pose_vel := Vector2.ZERO
var dog_pose_vel := Vector2.ZERO
var owner_face := Vector2.DOWN
var dog_face := Vector2.DOWN
var owner_stride := 0.0
var dog_stride := 0.0
var dog_speed_now := 0.0
var sniff_t := 0.0
var sniff_gap := 0.0
var sniff_spot := Vector2(INF, INF)   # the post it is going to, or sniffing
var at_spot := false
var mark_t := 0.0
var marks_left := MARKS_MAX
var dog_name := "a dog"
var greet_t := 0.0
var grumpy := false
# its own dice, so a sniff stop never moves the shared seed the rest of the
# walk (and the autowalk) depends on
var life_rng := RandomNumberGenerator.new()


func setup(m: Node2D, mine: Node2D, poles: Array[Vector2], start: Vector2, direction: Vector2) -> void:
	add_to_group("pairs")
	main = m
	my_dog = mine
	vel = direction * randf_range(58.0, 82.0)
	seed_o = randf() * 10.0
	life_rng.seed = int(seed_o * 100000.0) + 7
	sniff_gap = life_rng.randf_range(1.0, SNIFF_GAP_MAX)
	dog_name = NAMES[life_rng.randi() % NAMES.size()]
	grumpy = life_rng.randf() < GRUMPY_P
	owner_face = direction.normalized() if direction.length() > 0.1 else Vector2.DOWN
	dog_face = owner_face
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
	leash.set_script(load("res://entities/leash.gd"))
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
	# Same cancellation rules on every recall entry, including no-op calls
	# from WALKING tests/paths that only need the tangle cleared.
	_cancel_tangle()
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
	var owner_was: Vector2 = npc_owner.position
	var dog_was: Vector2 = npc_dog.position
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
	_update_pose(owner_was, dog_was, delta)
	# owner/dog move via transform every frame; redraw the pose at ~30fps
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


# your dog has come up nose to nose: stop, sniff back, the owner waits
func greet() -> void:
	greet_t = GREET_HOLD
	sniff_t = maxf(sniff_t, GREET_HOLD)
	sniff_spot = Vector2(INF, INF)
	at_spot = false
	mark_t = 0.0


func _tick_walking(delta: float, _allow_arrival: bool) -> void:
	greet_t = maxf(0.0, greet_t - delta)
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
	if tangled_t <= 0.0 and greet_t <= 0.0 and route != null:
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
		# Outside a detour the dog wanders about its owner, and now and then
		# stops dead with its nose down; the leash tows it on if that goes on
		# too long, which is exactly what a dog on a sniff does.
		var target := npc_owner.position + clear_dog_offset
		if route != null:
			target.x = clampf(
				target.x,
				float(route.get("min_x")),
				float(route.get("max_x"))
			)
		if mark_t > 0.0:
			mark_t -= delta
			dog_speed_now = 0.0
			if mark_t <= 0.0:
				main.on_npc_mark(sniff_spot + Vector2(0.0, 8.0), dog_col, dog_name)
				marks_left -= 1
				sniff_spot = Vector2(INF, INF)
		elif sniff_t > 0.0:
			sniff_t -= delta
			dog_speed_now = 0.0
			if sniff_t <= 0.0 and at_spot:
				# a good sniff at a post usually deserves a reply
				if marks_left > 0 and life_rng.randf() < MARK_P:
					mark_t = MARK_T
				else:
					sniff_spot = Vector2(INF, INF)
				at_spot = false
		elif sniff_spot.x < INF:
			# off to the post, nose first
			dog_speed_now = move_toward(dog_speed_now, DOG_SPEED, DOG_ACCEL * delta)
			npc_dog.position = npc_dog.position.move_toward(sniff_spot, dog_speed_now * delta)
			if npc_dog.position.distance_to(sniff_spot) < 16.0:
				at_spot = true
				sniff_t = life_rng.randf_range(SNIFF_MIN, SNIFF_MAX)
		else:
			sniff_gap -= delta
			if sniff_gap <= 0.0 and route_was_clear:
				sniff_gap = life_rng.randf_range(SNIFF_GAP_MIN, SNIFF_GAP_MAX)
				sniff_spot = _pick_spot()
				if sniff_spot.x == INF:
					sniff_t = life_rng.randf_range(SNIFF_MIN, SNIFF_MAX)
			dog_speed_now = move_toward(dog_speed_now, DOG_SPEED, DOG_ACCEL * delta)
			npc_dog.position = npc_dog.position.move_toward(target, dog_speed_now * delta)
	# keep the dog within their (short) leash; towed off a post, it gives up
	# on it, mark or no mark
	var span := npc_dog.position - npc_owner.position
	if span.length() > LEASH_CAP:
		npc_dog.position = npc_owner.position + span.normalized() * LEASH_CAP
		if sniff_spot.x < INF:
			sniff_spot = Vector2(INF, INF)
			at_spot = false
			sniff_t = 0.0
			mark_t = 0.0
	leash.tick(delta)
	_sync_leash_taut()
	_sample_rope()


# a post coming up by the dog's line that no dog has marked yet, or none
func _pick_spot() -> Vector2:
	var fwd := signf(desired_vertical_speed)
	# (a stand-in main, as in the tests, has no posts)
	if fwd == 0.0 or main == null or not ("hydrants" in main):
		return Vector2(INF, INF)
	var spots: Array[Vector2] = []
	for h: Dictionary in main.hydrants:
		spots.append(h["pos"])
	for tr: Vector2 in main.trees:
		spots.append(tr)
	for i in range(mini(int(main.deco_pole_count), main.poles.size())):
		spots.append(main.poles[i])
	var best := Vector2(INF, INF)
	var best_d := INF
	var from: Vector2 = npc_owner.position
	for sp: Vector2 in spots:
		var ahead := (sp.y - from.y) * fwd
		if ahead < 20.0 or ahead > SPOT_AHEAD or absf(sp.x - npc_dog.position.x) > SPOT_REACH:
			continue
		if not main._npc_mark_at(sp + Vector2(0.0, 8.0)).is_empty():
			continue
		var d := npc_dog.position.distance_to(sp)
		if d < best_d:
			best_d = d
			best = sp
	# the dog noses up to the post's foot on its own side, not into it
	if best.x < INF:
		best += Vector2(signf(npc_dog.position.x - best.x) * 14.0, 0.0)
	return best


func _update_pose(owner_was: Vector2, dog_was: Vector2, delta: float) -> void:
	if delta <= 0.0:
		return
	var ov: Vector2 = (npc_owner.position - owner_was) / delta
	var dv: Vector2 = (npc_dog.position - dog_was) / delta
	# a re-leash or a respawn is a jump, not a walk
	if ov.length() > 400.0:
		ov = Vector2.ZERO
	if dv.length() > 600.0:
		dv = Vector2.ZERO
	owner_pose_vel = owner_pose_vel.lerp(ov, POSE_EASE)
	dog_pose_vel = dog_pose_vel.lerp(dv, POSE_EASE)
	owner_stride += owner_pose_vel.length() * delta
	dog_stride += dog_pose_vel.length() * delta
	if owner_pose_vel.length() > 8.0:
		owner_face = owner_face.lerp(owner_pose_vel.normalized(), 0.2).normalized()
	var want := dog_face
	var near := my_dog != null and my_dog.global_position.distance_to(npc_dog.global_position) < CURIOUS_R
	if greet_t > 0.0 and my_dog != null:
		want = (my_dog.global_position - npc_dog.global_position).normalized()
	elif mark_t > 0.0 and sniff_spot.x < INF:
		# side on to the post, leg up
		var to_post := Vector2(signf(sniff_spot.x - npc_dog.position.x - 0.01) * -14.0, 0.0)
		want = to_post.normalized().orthogonal()
	elif sniff_t > 0.0 and sniff_spot.x < INF:
		want = (sniff_spot - npc_dog.position + Vector2(0.0, -1.0)).normalized()
	elif sniff_t > 0.0:
		want = dog_face
	elif near:
		want = (my_dog.global_position - npc_dog.global_position).normalized()
	elif dog_pose_vel.length() > 12.0:
		want = dog_pose_vel.normalized()
	if want.length() > 0.5:
		dog_face = dog_face.lerp(want, 0.18).normalized()


func _tick_arriving(delta: float) -> void:
	var before := npc_owner.position
	npc_owner.position = npc_owner.position.move_toward(park_spot, PARK_OWNER_SPEED * delta)
	vel = (npc_owner.position - before) / delta if delta > 0.0 else Vector2.ZERO
	var target := npc_owner.position + INITIAL_DOG_OFFSET * 0.55
	npc_dog.position = npc_dog.position.move_toward(target, DOG_SPEED * delta)
	_cap_dog_to_owner()
	leash.tick(delta)
	_sync_leash_taut()
	_sample_rope()
	if npc_owner.position.is_equal_approx(park_spot):
		_enter_parked(randf_range(PARK_STAY_MIN, PARK_STAY_MAX))


func _enter_parked(stay_time: float) -> void:
	pair_state = PairState.PARKED
	park_stay_t = maxf(stay_time, 0.0)
	park_dog_vel = Vector2.ZERO
	_suspend_leash()


func _tick_parked(delta: float) -> void:
	npc_owner.position = park_spot
	_cancel_tangle()
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
	_cancel_tangle()
	_suspend_leash()
	park_dog_vel = Vector2.ZERO
	npc_dog.position = npc_dog.position.move_toward(npc_owner.position, PARK_RECALL_SPEED * delta)
	if npc_dog.position.distance_to(npc_owner.position) <= RELEASH_DISTANCE:
		leash.detached = false
		_cancel_tangle()
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
	_cancel_tangle()
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
	_sync_leash_taut()
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


func _sync_leash_taut() -> void:
	# NPC leashes share the player's taut presentation rule: stretch vs reel.
	leash.taut = leash.used_length() > leash.rest_len


func _cap_dog_to_owner() -> void:
	var span := npc_dog.position - npc_owner.position
	if span.length() > LEASH_CAP:
		npc_dog.position = npc_owner.position + span.normalized() * LEASH_CAP


func _cancel_tangle() -> void:
	tangled_t = 0.0
	tangle_active = false
	tangle_clear_t = 0.0
	tangle_touching = false
	tangle_root_acc = 0.0
	tangle_hold_t = 0.0
	mercy_shown = false
	mercy_hold = false
	if leash != null:
		leash.dynamic_obstacles.clear()


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_UNPARENTED
		or what == NOTIFICATION_EXIT_TREE
		or what == NOTIFICATION_PREDELETE
	):
		_cancel_tangle()
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
	# A tangle is already chaotic; do not also steer the NPC dog into the
	# player while the ropes are snagged.
	var curious := Vector2.ZERO
	if tangled_t <= 0.0 and not tangle_active and not mercy_hold and to_mine.length() < 160.0:
		curious = to_mine.normalized() * 34.0
	return Vector2(30, 24) + wander + curious


func update_tangle_state(crossing: bool, delta: float) -> bool:
	tangle_touching = crossing
	if mercy_hold:
		if crossing:
			tangled_t = 0.0
			if leash != null:
				leash.dynamic_obstacles.clear()
				leash.free_slip_t = maxf(leash.free_slip_t, 1.0)
			return false
		mercy_hold = false
	if crossing:
		tangle_hold_t += delta
		if tangle_root_acc < TANGLE_PAUSE_MAX_S:
			tangled_t = TANGLE_ROOT_S
			tangle_root_acc = minf(TANGLE_PAUSE_MAX_S, tangle_root_acc + delta)
		else:
			# Pause budget spent: owner unroots even if geometry still touches.
			tangled_t = 0.0
			tangle_root_acc = TANGLE_PAUSE_MAX_S
		tangle_clear_t = 0.0
		# Visible mercy ramp: free-slip the NPC rope so the snag cannot lock.
		if tangle_hold_t >= TANGLE_MERCY_RAMP_S and leash != null:
			var ramp_t := tangle_hold_t - TANGLE_MERCY_RAMP_S
			leash.free_slip_t = maxf(leash.free_slip_t, 0.35 + ramp_t * 0.4)
			if not mercy_shown and is_instance_valid(main):
				mercy_shown = true
				main.float_text(npc_owner.position, "excuse me - go on", Color(1, 0.92, 0.78), main.POP_SAY)
		if tangle_hold_t >= TANGLE_MERCY_S:
			var need_line := not mercy_shown
			tangled_t = 0.0
			tangle_active = false
			tangle_clear_t = 0.0
			tangle_root_acc = 0.0
			tangle_hold_t = 0.0
			mercy_shown = false
			mercy_hold = true
			if leash != null:
				leash.dynamic_obstacles.clear()
				leash.free_slip_t = maxf(leash.free_slip_t, 1.0)
			if need_line and is_instance_valid(main):
				main.float_text(npc_owner.position, "excuse me - go on", Color(1, 0.92, 0.78), main.POP_SAY)
			return false
		if tangle_active:
			return false
		tangle_active = true
		main.float_text(npc_owner.position, "oh - sorry!", Color(1, 0.9, 0.8), main.POP_SAY)
		return true
	tangle_root_acc = maxf(0.0, tangle_root_acc - delta * 2.0)
	tangle_hold_t = maxf(0.0, tangle_hold_t - delta)
	if tangle_active:
		tangle_clear_t += delta
		if tangle_clear_t >= TANGLE_REARM_S:
			tangle_active = false
			tangle_clear_t = 0.0
			tangle_hold_t = 0.0
			mercy_shown = false
	return false


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_draw_shapes()
	_b.flush()


func _draw_shapes() -> void:
	var t := AnimClock.msec() / 1000.0
	# contact shadows under both ends of the pair, light up-and-left
	for sh in [[npc_owner.position, 15.0], [npc_dog.position, 10.5]]:
		_b.draw_set_transform((sh[0] as Vector2) + Vector2(5.0, 8.0), 0.0, Vector2(1.2, 0.5))
		_b.draw_circle(Vector2.ZERO, sh[1], Color(0.06, 0.05, 0.08, 0.24))
	_b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# drawn from where they actually went, not the lane speed they were given
	var owner_forward := owner_face
	var owner_gait_amount := (
		0.0
		if pair_state == PairState.PARKED or pair_state == PairState.RECALLING
		else clampf(owner_pose_vel.length() / 82.0, 0.0, 1.0)
	)
	var owner_phone_glow := 0.55 + 0.2 * sin(t * 7.3 + seed_o)
	HumanAppearanceScript.draw_owner(
		_b,
		owner_appearance_profile,
		npc_owner.position,
		owner_forward,
		owner_stride * 0.075 + seed_o,
		owner_gait_amount,
		owner_phone_glow,
		"held",
		Game.weather,
		Game.level_id,
		Game.night,
		int(seed_o * 1000.0)
	)
	# NPC dog remains drawn by the pair parent; npc_dog stays the real endpoint.
	var dp: Vector2 = npc_dog.position
	var facing := dog_face
	var dspeed := clampf(dog_pose_vel.length() / 70.0, 0.0, 1.0)
	var bob := sin(dog_stride * 0.09 + seed_o) * 1.5 * dspeed
	# a slow wag while sniffing, an ordinary one walking, a blur when your
	# dog is right there
	var near := my_dog.global_position.distance_to(npc_dog.global_position) < CURIOUS_R
	var wag_rate := 16.0 if near else (4.0 if sniff_t > 0.0 else 8.0)
	# a grumpy dog meeting yours holds its tail still
	if grumpy and greet_t > 0.0:
		wag_rate = 0.0
	var wag := t * wag_rate + seed_o
	DogAppearanceScript.draw_dog(
		_b,
		appearance_profile,
		dp,
		facing,
		bob,
		wag
	)
