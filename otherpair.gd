extends Node2D

# Another dog-walker: an NPC owner and dog joined by their own leash
# (a real leash.gd rope). They amble along the path. When their leash
# crosses yours, the two ropes drape over each other and TANGLE - the
# flagship dog-park mayhem, emergent from the shared rope physics.

const BypasserRouteScript := preload("res://bypasser_route.gd")
const TANGLE_REARM_S := 0.5
const PAIR_CLEARANCE := 48.0
const PAIR_MAX_LATERAL_SPEED := 90.0
const PAIR_MINIMUM_LOOKAHEAD := 240.0
const PAIR_LOOKAHEAD_TIME := 1.35
const DOG_SPEED := 90.0
const LEASH_CAP := 150.0
const INITIAL_DOG_OFFSET := Vector2(40, 30)
const DOG_DETOUR_OFFSET := 12.0

var main: Node2D
var my_dog: Node2D
var npc_owner: Node2D
var npc_dog: Node2D
var leash: Node2D
var vel := Vector2.ZERO
var owner_col := Color(0.5, 0.45, 0.55)
var dog_col := Color(0.6, 0.5, 0.4)
var wander_t := 0.0
var wander := Vector2.ZERO
var seed_o := 0.0
var tangled_t := 0.0
var tangle_active := false
var tangle_clear_t := 0.0
var sampled: Array[Vector2] = []
var route: RefCounted
var desired_vertical_speed := 0.0


func setup(m: Node2D, mine: Node2D, poles: Array[Vector2], start: Vector2, direction: Vector2) -> void:
	add_to_group("pairs")
	main = m
	my_dog = mine
	vel = direction * randf_range(58.0, 82.0)
	seed_o = randf() * 10.0
	owner_col = [Color(0.5, 0.45, 0.55), Color(0.45, 0.5, 0.42), Color(0.55, 0.48, 0.4)][randi() % 3]
	dog_col = [Color(0.6, 0.5, 0.4), Color(0.75, 0.72, 0.68), Color(0.35, 0.3, 0.28)][randi() % 3]
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


func _physics_process(delta: float) -> void:
	if main.phase == "freedom":
		queue_free()
		return
	if main.frozen:
		return
	tangled_t = maxf(0.0, tangled_t - delta)
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
	# sample our rope thinly for the other leash to collide against
	sampled.clear()
	for i in range(0, leash.N, 2):
		sampled.append(leash.pts[i])
	# despawn once well off camera
	if absf(npc_owner.position.y - float(main.cam.position.y)) > 1200.0:
		queue_free()
	queue_redraw()


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
	# NPC owner (no glowing phone - they are present, unlike yours)
	var op: Vector2 = npc_owner.position
	draw_circle(op + Vector2(0, 14), 5.0, Color(0.25, 0.25, 0.3))
	draw_circle(op, 13.0, owner_col)
	draw_circle(op + Vector2(0, -12), 7.0, Color(0.85, 0.72, 0.58))
	draw_arc(op + Vector2(0, -12), 7.0, PI, TAU, 10, Color(0.3, 0.24, 0.16), 4.0)
	# NPC dog
	var dp: Vector2 = npc_dog.position
	var t := Time.get_ticks_msec() / 1000.0
	draw_line(dp, dp + Vector2(-9, -3).rotated(sin(t * 8.0 + seed_o) * 0.4), dog_col.darkened(0.2), 3.0)
	draw_circle(dp, 7.0, dog_col)
	var face := (my_dog.global_position - dp).normalized()
	draw_circle(dp + face * 6.0, 4.5, dog_col)
	draw_circle(dp + face * 8.0, 1.4, Color(0.1, 0.09, 0.08))
