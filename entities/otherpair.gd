extends Node2D

# Another dog-walker: an NPC owner and dog joined by their own leash
# (a real leash.gd rope). They amble along the path. When their leash
# crosses yours, the two ropes drape over each other and TANGLE - the
# flagship dog-park mayhem, emergent from the shared rope physics.

const BypasserRouteScript := preload("res://systems/bypasser_route.gd")
const Clay := preload("res://entities/clay.gd")
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
# A dog that has dropped behind its place (a sniff stop left it there) trots
# to catch up, faster than any owner walks; DOG_TROT is also the fastest the
# dog ever goes on the walk.
const DOG_TROT := 150.0
const DOG_TROT_GAP := 30.0
# the owner ambles at this share of their pace while the dog sniffs or marks
const SNIFF_PACE := 0.75
# The walk: the dog goes a little ahead of its owner and to one side of the
# line, DOG_LEAD along the way they are walking and DOG_SIDE across, and the
# wander roll moves it about that spot (WANDER_ACROSS and WANDER_ALONG of it).
const DOG_LEAD := 70.0
const DOG_SIDE := 16.0
const WANDER_ACROSS := 0.6
const WANDER_ALONG := 0.45
# The leash: LEASH_LEN of strap from the fist to the collar. The owner takes
# in what the dog is not using, down to LEASH_MIN, keeping LEASH_SLACK of it
# as a gentle droop, at LEASH_REEL_SPEED; so slack never trails behind the
# pair. The dog can go LEASH_TAUT past the full length, which is the strap
# drawn taut, and never further than LEASH_CAP from its owner.
const LEASH_LEN := 92.0
const LEASH_MIN := 28.0
const LEASH_SLACK := 1.1
const LEASH_REEL_SPEED := 180.0
const LEASH_TAUT := 1.04
const LEASH_CAP := 118.0
# the fist holding the strap: beside the phone, on the dog's side
const HAND_FORWARD := 16.0
const HAND_SIDE := 7.0
const DOG_DETOUR_OFFSET := 12.0
# share of DOG_LEAD the dog keeps ahead while the pair detours round something
const DETOUR_LEAD := 0.7
# how far to the side of a held-up owner the dog waits
const DOG_WAIT_SIDE := 24.0
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
const SPOT_REACH := 80.0
const SPOT_AHEAD := 150.0
const MARK_P := 0.6
const MARK_T := 1.1
const MARKS_MAX := 2
# meeting your dog nose to nose: the other dog stops and sniffs back, and
# its owner waits that long; GRUMPY_P of dogs would rather not
const GREET_HOLD := 1.4
const GRUMPY_P := 0.2
# Meeting your dog on the way past. A friendly dog spots her from MEET_R and
# pulls over to say hello, its owner slowing to let it; a grumpy one goes
# stiff and stares for MEET_WARN (the telegraph every hazard gets), then
# lunges to the end of its leash barking every BARK_GAP while its owner stops
# and reels it in short. It is over once she is MEET_END away, once a walk.
const MEET_R := 150.0
const MEET_END := 230.0
const MEET_WARN := 0.8
const BARK_GAP := 0.55
const HELLO_PACE := 0.3
# how short a grumpy dog's owner holds it while it lunges
const LUNGE_LEASH := 0.7
# nearer than this to a lunging dog, she gets a fright
const LUNGE_SCARE_R := 46.0
# What the owner's hands are busy with (HumanAppearance.HABITS), by share of
# owners: most are on their phone, some on a call, some just walking the dog,
# some carrying a coffee.
const HABIT_SHARES := {"held": 0.45, "call": 0.15, "free": 0.25, "cup": 0.15}
# a phone owner stops dead now and then to type something
const TYPE_GAP_MIN := 9.0
const TYPE_GAP_MAX := 18.0
const TYPE_T := 1.4
# an owner without a phone in their face looks at your dog this near
const LOOK_R := 220.0
const LOOK_EASE := 6.0
# someone on a call says one line of it as they pass this near
const CALL_SAY_R := 240.0
# the longest a hello or a lunge goes on: then the owner walks on regardless
const HELLO_MAX := 4.0
# a friendly dog coming over stops this close, nose to nose
const NOSE_R := 24.0
const LUNGE_MAX := 4.5
const NAMES := ["a terrier", "a beagle", "a whippet", "a poodle", "a wiener dog", "a labrador",
	"a pit bull", "a pug", "a greyhound", "a collie", "a spaniel", "a chihuahua"]
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
# the strap had to haul the dog this frame: no bench may then hold it back
var towed_now := false
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
# meeting your dog: "" not yet, "hello", "warn", "lunge", then "done"
var meet := ""
var meet_t := 0.0
var bark_t := 0.0
# a bark just went off: the burst at its mouth, for the drawing
var bark_flash := 0.0
var _scared := false
var habit := "held"
var type_t := 0.0
var type_gap := 0.0
# where the owner's head points, on the canvas
var look_dir := Vector2.DOWN
var _said := false
var _habit_rng := RandomNumberGenerator.new()
# your dog has sniffed noses with this one: a hello is over when that sniff is
var _greeted := false
# which side of the line this dog walks on: +1 right, -1 left (in x)
var dog_side := 1.0
# how far ahead of the dog's center its collar is drawn
var collar_reach := 0.0
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
	# from the seed already rolled, so the shared dice are not moved
	dog_side = 1.0 if int(seed_o * 1000.0) % 2 == 0 else -1.0
	sniff_gap = life_rng.randf_range(1.0, SNIFF_GAP_MAX)
	dog_name = NAMES[life_rng.randi() % NAMES.size()]
	grumpy = life_rng.randf() < GRUMPY_P
	# its own dice, so the dog's sniffing keeps the rolls it had
	_habit_rng.seed = int(seed_o * 100000.0) + 31
	habit = _roll_habit(_habit_rng.randf())
	type_gap = _habit_rng.randf_range(TYPE_GAP_MIN * 0.4, TYPE_GAP_MAX)
	owner_face = direction.normalized() if direction.length() > 0.1 else Vector2.DOWN
	dog_face = owner_face
	var owner_appearance_key := randi()
	owner_appearance_profile = HumanAppearanceScript.profile_for_key(owner_appearance_key)
	owner_col = owner_appearance_profile["shirt_color"]
	var dog_appearance_key := randi()
	appearance_profile = DogAppearanceScript.profile_for_key(dog_appearance_key)
	dog_col = appearance_profile["base_color"]
	collar_reach = DogAppearanceScript.collar_reach(appearance_profile)
	npc_owner = Node2D.new()
	npc_owner.position = start
	add_child(npc_owner)
	npc_dog = Node2D.new()
	npc_dog.position = start + _lead_offset(owner_face)
	add_child(npc_dog)
	leash = Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	leash.z_index = 6
	add_child(leash)
	leash.setup(npc_dog, npc_owner, poles, LEASH_LEN)
	_place_hand()
	leash.rest_len = _leash_want()


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
	var formation_offsets: Array[Vector2] = [Vector2.ZERO, npc_dog.position - npc_owner.position]
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


# how far past the view a pair still redraws: past the box around owner and
# dog, the owner's body and phone, both shadows, the rope's sag and a step
const VIEW_MARGIN := 100.0


func _physics_process(delta: float) -> void:
	if main.phase == "freedom" and not park_area_configured:
		queue_free()
		return
	if main.frozen:
		return
	var owner_was: Vector2 = npc_owner.position
	var dog_was: Vector2 = npc_dog.position
	var seen := Clay.in_view(self, main,
		Rect2(npc_owner.global_position, Vector2.ZERO).expand(npc_dog.global_position), VIEW_MARGIN)
	leash.out_of_view = not seen
	towed_now = false
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
	if pair_state == PairState.WALKING and not towed_now and _in_solid(npc_dog.position) and not _in_solid(dog_was):
		# its wander and its detour lead ignore benches: it stops short instead,
		# but a towed dog follows the strap, or it would leap the bench once freed
		npc_dog.position = dog_was
	_update_pose(owner_was, dog_was, delta)
	# owner/dog move via transform every frame; redraw the pose at ~30fps
	if Engine.get_physics_frames() % 2 == 0 and seen:
		Redraw.later(self)


func _in_solid(p: Vector2) -> bool:
	return route != null and bool(route.call("in_body", p))


# your dog has come up nose to nose: stop, sniff back, the owner waits
func greet() -> void:
	greet_t = GREET_HOLD
	_greeted = true
	sniff_t = maxf(sniff_t, GREET_HOLD)
	sniff_spot = Vector2(INF, INF)
	at_spot = false
	mark_t = 0.0


func _tick_walking(delta: float, _allow_arrival: bool) -> void:
	greet_t = maxf(0.0, greet_t - delta)
	_tick_meet(delta)
	_tick_habit(delta)
	var route_was_clear := (
		route != null
		and int(route.get("detour_side")) == 0
		and not bool(route.get("blocked"))
	)
	if route_was_clear:
		wander_t -= delta
		if wander_t <= 0.0:
			# its own dice: how often this rolls depends on the route, and must
			# not move the shared seed the rest of the walk depends on
			wander_t = life_rng.randf_range(0.6, 1.6)
			wander = Vector2(life_rng.randf_range(-1, 1), life_rng.randf_range(-1, 1)) * 40.0
	var clear_dog_offset := _clear_dog_offset()
	# round an obstacle the dog still goes a little ahead, on the detour's side
	var detour_lead := _lead_offset(Vector2(0.0, desired_vertical_speed)).y * DETOUR_LEAD
	# the owner ambles in their lane; a tangle roots them in place
	if tangled_t <= 0.0 and greet_t <= 0.0 and route != null:
		var before: Vector2 = npc_owner.position
		var formation_offsets: Array[Vector2] = [
			Vector2.ZERO,
			npc_dog.position - before,
		]
		var left_offsets: Array[Vector2] = [
			Vector2.ZERO,
			Vector2(-DOG_DETOUR_OFFSET, detour_lead),
		]
		var right_offsets: Array[Vector2] = [
			Vector2.ZERO,
			Vector2(DOG_DETOUR_OFFSET, detour_lead),
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
				else before.y + desired_vertical_speed * delta * _owner_pace()
		)
	var detour_side := int(route.get("detour_side")) if route != null else 0
	var route_blocked := bool(route.get("blocked")) if route != null else false
	if detour_side != 0:
		var detour_target := Vector2(
			float(route.get("detour_target_x")) + detour_side * DOG_DETOUR_OFFSET,
			npc_owner.position.y + detour_lead
		)
		npc_dog.position = _move_dog_lateral_first(
			npc_dog.position,
			detour_target,
			DOG_SPEED * delta
		)
	elif route_blocked:
		# the way ahead is shut: it waits at its owner's side, not on their feet
		npc_dog.position = _move_dog_lateral_first(
			npc_dog.position,
			npc_owner.position + Vector2(dog_side * DOG_WAIT_SIDE, 0.0),
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
		if meet == "hello" and (greet_t > 0.0 or npc_dog.position.distance_to(my_dog.global_position - global_position) < NOSE_R):
			# nose to nose: it stays put for the sniff
			dog_speed_now = 0.0
		elif meet == "hello" or meet == "lunge":
			# straight for your dog, as far as the leash lets it
			var to: Vector2 = my_dog.global_position - global_position
			dog_speed_now = move_toward(dog_speed_now, DOG_TROT * (1.25 if meet == "lunge" else 1.0), DOG_ACCEL * 2.0 * delta)
			npc_dog.position = npc_dog.position.move_toward(to, dog_speed_now * delta)
		elif meet == "warn":
			dog_speed_now = 0.0
		elif mark_t > 0.0:
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
			var pace := DOG_TROT if npc_dog.position.distance_to(target) > DOG_TROT_GAP else DOG_SPEED
			dog_speed_now = move_toward(dog_speed_now, pace, DOG_ACCEL * delta)
			npc_dog.position = npc_dog.position.move_toward(target, dog_speed_now * delta)
	# keep the dog within their (short) leash; towed off a post, it gives up
	# on it, mark or no mark, and towed off any sniff it comes along
	if _cap_dog_to_owner() and (sniff_spot.x < INF or (sniff_t > 0.0 and greet_t <= 0.0)):
		sniff_spot = Vector2(INF, INF)
		at_spot = false
		sniff_t = 0.0
		mark_t = 0.0
	_tick_leash(delta)
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
	var target := npc_owner.position + _lead_offset(park_spot - npc_owner.position) * 0.55
	npc_dog.position = npc_dog.position.move_toward(target, DOG_SPEED * delta)
	_cap_dog_to_owner()
	_tick_leash(delta)
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
		_place_hand()
		leash.rest_len = _leash_want()
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
	var target := npc_owner.position + _lead_offset(gate_exit - npc_owner.position)
	npc_dog.position = npc_dog.position.move_toward(target, DOG_SPEED * delta)
	_cap_dog_to_owner()
	_tick_leash(delta)
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


# Holds the dog to the strap: no further than the taut leash from the fist,
# and never past LEASH_CAP from the owner. True when it had to tow.
func _cap_dog_to_owner() -> bool:
	var towed := false
	var hand := _hand_local()
	var reach := LEASH_LEN * LEASH_TAUT
	var from_hand := npc_dog.position - hand
	if from_hand.length() > reach:
		npc_dog.position = hand + from_hand.normalized() * reach
		towed = true
	var span := npc_dog.position - npc_owner.position
	if span.length() > LEASH_CAP:
		npc_dog.position = npc_owner.position + span.normalized() * LEASH_CAP
		towed = true
	towed_now = towed_now or towed
	return towed


# A dog with its nose down slows its owner; they do not stop for it. A dog
# saying hello slows them more; a grumpy one barking at yours stops them.
func _owner_pace() -> float:
	if meet == "warn" or meet == "lunge":
		return 0.0
	if meet == "hello":
		return HELLO_PACE
	if type_t > 0.0:
		return 0.0
	return SNIFF_PACE if (sniff_t > 0.0 or mark_t > 0.0) and greet_t <= 0.0 else 1.0


static func _roll_habit(r: float) -> String:
	for h: String in HABIT_SHARES:
		r -= float(HABIT_SHARES[h])
		if r < 0.0:
			return h
	return "held"


# The owner as a person: a phone owner stops to type now and then; anyone
# whose eyes are free looks at your dog going by; everyone looks down at
# their own when it stops, says hello or kicks off; someone on a call says a
# line of it as they pass.
func _tick_habit(delta: float) -> void:
	type_t = maxf(0.0, type_t - delta)
	var calm := (meet == "" or meet == "done") and tangled_t <= 0.0
	if habit == "held" and calm:
		type_gap -= delta
		if type_gap <= 0.0:
			type_t = TYPE_T
			type_gap = _habit_rng.randf_range(TYPE_GAP_MIN, TYPE_GAP_MAX)
	elif not calm:
		type_t = 0.0
	var want := owner_face
	var to_mine: Vector2 = npc_dog.position - npc_owner.position
	var to_yours: Vector2 = (my_dog.global_position - global_position - npc_owner.position) if my_dog != null else Vector2.ZERO
	if meet == "lunge" or meet == "warn":
		want = to_mine
	elif habit != "held" and meet == "hello":
		want = to_yours if int(AnimClock.msec() / 900.0) % 2 == 0 else to_mine
	elif habit != "held" and (sniff_t > 0.0 or mark_t > 0.0):
		want = to_mine
	elif habit != "held" and my_dog != null and to_yours.length() < LOOK_R:
		want = to_yours
	if want.length() > 0.01:
		look_dir = look_dir.lerp(want.normalized(), 1.0 - exp(-LOOK_EASE * delta)).normalized()
	if habit == "call" and not _said and my_dog != null and to_yours.length() < CALL_SAY_R:
		_said = true
		if main != null and main.has_method("on_pair_call"):
			main.on_pair_call(self)


# Meeting your dog: starts when she comes within MEET_R of this dog, walking
# and untangled; ends when she is MEET_END away. Once a walk.
func _tick_meet(delta: float) -> void:
	bark_flash = maxf(0.0, bark_flash - delta)
	if my_dog == null or main == null:
		return
	var d: float = my_dog.global_position.distance_to(global_position + npc_dog.position)
	if meet == "":
		if d < MEET_R and tangled_t <= 0.0 and not tangle_active:
			meet = "warn" if grumpy else "hello"
			meet_t = MEET_WARN if grumpy else HELLO_MAX
			sniff_spot = Vector2(INF, INF)
			at_spot = false
			sniff_t = 0.0
			mark_t = 0.0
			if main.has_method("on_pair_meet"):
				main.on_pair_meet(self, meet)
		return
	if meet == "done":
		return
	if d > MEET_END or tangled_t > 0.0:
		meet = "done"
		return
	if meet == "hello":
		meet_t -= delta
		if meet_t <= 0.0 or (_greeted and greet_t <= 0.0):
			meet = "done"
	elif meet == "warn":
		meet_t -= delta
		if meet_t <= 0.0:
			meet = "lunge"
			meet_t = LUNGE_MAX
			bark_t = 0.0
			if main.has_method("on_pair_meet"):
				main.on_pair_meet(self, "lunge")
	elif meet == "lunge":
		meet_t -= delta
		if meet_t <= 0.0:
			# the owner hauls it off and walks on
			meet = "done"
			return
		bark_t -= delta
		if bark_t <= 0.0:
			bark_t = BARK_GAP
			bark_flash = 0.22
			if main.has_method("on_pair_bark"):
				main.on_pair_bark(self)
		if not _scared and d < LUNGE_SCARE_R and main.has_method("on_pair_scare"):
			_scared = true
			main.on_pair_scare(self)


# the dog's place on the walk for a pair heading `way`: DOG_LEAD ahead, on its
# own side of the line
func _lead_offset(way: Vector2) -> Vector2:
	var along := signf(way.y) if absf(way.y) > 0.01 else signf(owner_face.y)
	if along == 0.0:
		along = 1.0
	return Vector2(dog_side * DOG_SIDE, along * DOG_LEAD)


func _hand_local() -> Vector2:
	return npc_owner.position + leash.hand_offset


# the strap's fist follows the way the owner faces, on the dog's side, and
# the other end is clipped to the collar, wherever the dog faces
func _place_hand() -> void:
	leash.hand_offset = owner_face * HAND_FORWARD + Vector2(dog_side * HAND_SIDE, 0.0)
	leash.dog_offset = dog_face * collar_reach


# the strap the owner lets out for where the dog is now
func _leash_want() -> float:
	var collar: Vector2 = npc_dog.position + leash.dog_offset
	var most := LEASH_LEN * (LUNGE_LEASH if meet == "lunge" else 1.0)
	return clampf(_hand_local().distance_to(collar) * LEASH_SLACK, LEASH_MIN, most)


# The owner takes in or lets out strap toward _leash_want(), then the rope
# solves. A leash caught on anything (a pole, furniture, your leash) is never
# taken in: the wrap or the tangle keeps the rope it is using.
func _tick_leash(delta: float) -> void:
	_place_hand()
	var want := _leash_want()
	if want < leash.rest_len and (
		leash.contacts > 0 or tangle_active or tangled_t > 0.0 or not leash.dynamic_obstacles.is_empty()
	):
		want = leash.rest_len
	leash.rest_len = move_toward(leash.rest_len, want, LEASH_REEL_SPEED * delta)
	leash.tick(delta)


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
	var lead := _lead_offset(Vector2(0.0, desired_vertical_speed))
	return lead + Vector2(wander.x * WANDER_ACROSS, signf(lead.y) * wander.y * WANDER_ALONG) + curious


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
				main.float_text(npc_owner.position, "Excuse me, go ahead.", Color(1, 0.92, 0.78), main.POP_SAY)
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
				main.float_text(npc_owner.position, "Excuse me, go ahead.", Color(1, 0.92, 0.78), main.POP_SAY)
			return false
		if tangle_active:
			return false
		tangle_active = true
		main.float_text(npc_owner.position, "Oh, sorry!", Color(1, 0.9, 0.8), main.POP_SAY)
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
	var env: Array = HumanAppearanceScript.env(self)
	HumanAppearanceScript.draw_owner(
		_b,
		owner_appearance_profile,
		npc_owner.position,
		owner_forward,
		owner_stride * 0.075 + seed_o,
		owner_gait_amount,
		owner_phone_glow,
		"raised" if type_t > 0.0 else habit,
		String(env[0]),
		String(env[1]),
		bool(env[2]),
		int(seed_o * 1000.0),
		look_dir,
		leash.hand_offset
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
	# a grumpy dog meeting yours holds its tail still; a friendly one coming
	# over can't keep it still
	if grumpy and (greet_t > 0.0 or meet == "warn" or meet == "lunge"):
		wag_rate = 0.0
	elif meet == "hello":
		wag_rate = 22.0
	var wag := t * wag_rate + seed_o
	DogAppearanceScript.draw_dog(
		_b,
		appearance_profile,
		dp,
		facing,
		bob,
		wag
	)
	# a bark: three short strokes thrown out ahead of its muzzle
	if bark_flash > 0.0:
		var mouth := dp + facing * 15.0
		var side := facing.orthogonal()
		var k := bark_flash / 0.22
		for s: float in [-1.0, 0.0, 1.0]:
			var dir := (facing + side * s * 0.55).normalized()
			_b.draw_line(mouth + dir * (5.0 + 4.0 * (1.0 - k)), mouth + dir * (11.0 + 4.0 * (1.0 - k)), Color(1.0, 0.96, 0.86, 0.9 * k), 2.0)
