class_name BypasserRoute
extends RefCounted

# Configure immutable blocker geometry once with configure_blockers().
# Runtime consumers call:
# - step(position, signed_vertical_speed, delta, current_member_offsets = [],
#       left_member_offsets = [], right_member_offsets = [],
#       clear_member_offsets = [])
# - find_clear_spawn_x(y, signed_vertical_speed, member_offsets = [])
# step returns x, target_x, blocked, side (-1/0/1), and blocker_id.
# Side-specific target offsets describe commanded formation transitions.
# Spawn returns {"found": true, "x": float} or {"found": false, "x": null}.

var preferred_x: float
var min_x: float
var max_x: float
var clearance: float
var max_lateral_speed: float
var minimum_lookahead: float
var lookahead_time: float

var active_blocker_id: Variant = null
var detour_side := 0
var detour_target_x: float
var blocked := false
var formation_transitioning := false
var return_transition_guarded := false
var configured_blocker_count := 0
var configured_cluster_count := 0
var normalization_passes := 0

var _travel_direction := 0
var _blockers: Array[Dictionary] = []
var _clusters: Array[Dictionary] = []
var _active_navigation: Dictionary = {}


func _init(
	p_preferred_x: float,
	p_min_x: float,
	p_max_x: float,
	p_clearance: float,
	p_max_lateral_speed: float,
	p_minimum_lookahead: float,
	p_lookahead_time: float
) -> void:
	min_x = minf(p_min_x, p_max_x)
	max_x = maxf(p_min_x, p_max_x)
	preferred_x = clampf(p_preferred_x, min_x, max_x)
	clearance = maxf(p_clearance, 0.0)
	max_lateral_speed = maxf(p_max_lateral_speed, 0.0)
	minimum_lookahead = maxf(p_minimum_lookahead, 0.0)
	lookahead_time = maxf(p_lookahead_time, 0.0)
	detour_target_x = preferred_x


func configure_blockers(descriptors: Array[Dictionary]) -> int:
	normalization_passes += 1
	_blockers.clear()
	for descriptor in descriptors:
		var normalized := _normalize_blocker(descriptor)
		if not normalized.is_empty():
			_blockers.append(normalized)
	configured_blocker_count = _blockers.size()
	_build_clusters()
	_clear_detour()
	return configured_blocker_count


func step(
	position: Vector2,
	vertical_speed: float,
	delta: float,
	current_member_offsets: Array[Vector2] = [],
	left_member_offsets: Array[Vector2] = [],
	right_member_offsets: Array[Vector2] = [],
	clear_member_offsets: Array[Vector2] = []
) -> Dictionary:
	return_transition_guarded = false
	var direction := _travel_direction
	if not is_zero_approx(vertical_speed):
		direction = 1 if vertical_speed > 0.0 else -1
		if _travel_direction != 0 and direction != _travel_direction:
			_clear_detour()
		_travel_direction = direction

	var active := {}
	if active_blocker_id != null:
		active = _active_navigation
		var fully_behind := (
			not active.is_empty()
			and direction != 0
			and _cluster_fully_behind(
				active,
				position.y,
				direction,
				current_member_offsets
			)
		)
		return_transition_guarded = (
			fully_behind
			and not _clear_transition_is_safe(
				position,
				current_member_offsets,
				clear_member_offsets
			)
		)
		var can_release := (
			fully_behind
			and not return_transition_guarded
		)
		if active.is_empty() or direction == 0 or can_release:
			_clear_detour()
			active = {}

	var lookahead := minimum_lookahead + absf(vertical_speed) * lookahead_time
	if active.is_empty() and direction != 0:
		active = _nearest_forward_cluster(
			position,
			direction,
			lookahead,
			current_member_offsets
		)
		if not active.is_empty():
			active_blocker_id = active.id
			_active_navigation = active

	if not active.is_empty():
		_choose_detour(
			active,
			position,
			direction,
			lookahead,
			current_member_offsets,
			left_member_offsets,
			right_member_offsets
		)
	else:
		blocked = false
		detour_side = 0
		detour_target_x = preferred_x
		formation_transitioning = false

	var next_x := position.x
	if not blocked:
		next_x = move_toward(
			position.x,
			detour_target_x,
			max_lateral_speed * maxf(delta, 0.0)
		)
	return {
		"x": next_x,
		"target_x": detour_target_x,
		"blocked": blocked,
		"side": detour_side,
		"blocker_id": active_blocker_id,
		"formation_transitioning": formation_transitioning,
		"return_transition_guarded": return_transition_guarded,
	}


func find_clear_spawn_x(
	y: float,
	vertical_speed: float,
	member_offsets: Array[Vector2] = []
) -> Dictionary:
	var offsets := _valid_member_offsets(member_offsets)
	var candidates: Array[float] = [preferred_x, min_x, max_x]
	var min_offset_x := _minimum_offset_x(offsets)
	var max_offset_x := _maximum_offset_x(offsets)
	for cluster in _clusters:
		candidates.append(float(cluster.left) - max_offset_x)
		candidates.append(float(cluster.right) - min_offset_x)

	var best := preferred_x
	var best_deviation := INF
	var found := false
	for candidate in candidates:
		if candidate < min_x or candidate > max_x:
			continue
		if _spawn_sweep_blocked(candidate, y, vertical_speed, offsets):
			continue
		var deviation := absf(candidate - preferred_x)
		if not found or deviation < best_deviation or (
			is_equal_approx(deviation, best_deviation) and candidate < best
		):
			found = true
			best = candidate
			best_deviation = deviation
	if found:
		return {"found": true, "x": best}
	return {"found": false, "x": null}


func _valid_member_offsets(member_offsets: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for offset in member_offsets:
		if _finite_vector(offset):
			result.append(offset)
	if result.is_empty():
		result.append(Vector2.ZERO)
	return result


func _minimum_offset_x(offsets: Array) -> float:
	if offsets.is_empty():
		return 0.0
	var result := INF
	for value in offsets:
		var offset: Vector2 = value
		result = minf(result, offset.x)
	return result


func _maximum_offset_x(offsets: Array) -> float:
	if offsets.is_empty():
		return 0.0
	var result := -INF
	for value in offsets:
		var offset: Vector2 = value
		result = maxf(result, offset.x)
	return result


func _minimum_offset_y(offsets: Array) -> float:
	if offsets.is_empty():
		return 0.0
	var result := INF
	for value in offsets:
		var offset: Vector2 = value
		result = minf(result, offset.y)
	return result


func _maximum_offset_y(offsets: Array) -> float:
	if offsets.is_empty():
		return 0.0
	var result := -INF
	for value in offsets:
		var offset: Vector2 = value
		result = maxf(result, offset.y)
	return result


func _clear_detour() -> void:
	active_blocker_id = null
	_active_navigation = {}
	detour_side = 0
	detour_target_x = preferred_x
	blocked = false
	formation_transitioning = false
	return_transition_guarded = false


func _normalize_blocker(descriptor: Dictionary) -> Dictionary:
	if not descriptor.has("id") or not descriptor.id is String or str(descriptor.id).is_empty():
		return {}
	var forced_side := _forced_side(descriptor.get("forced_side", ""))
	if descriptor.has("center") and descriptor.has("radius"):
		if not descriptor.center is Vector2 or not _is_number(descriptor.radius):
			return {}
		var center: Vector2 = descriptor.center
		var radius := float(descriptor.radius)
		if radius <= 0.0 or not _finite_vector(center) or not is_finite(radius):
			return {}
		var expanded := radius + clearance
		return {
			"id": str(descriptor.id),
			"kind": "circle",
			"center": center,
			"radius": expanded,
			"left": center.x - expanded,
			"right": center.x + expanded,
			"top": center.y - expanded,
			"bottom": center.y + expanded,
			"forced_side": forced_side,
		}
	if descriptor.has("rect"):
		if not descriptor.rect is Rect2:
			return {}
		var rect: Rect2 = descriptor.rect
		if (
			rect.size.x <= 0.0
			or rect.size.y <= 0.0
			or not _finite_vector(rect.position)
			or not _finite_vector(rect.size)
		):
			return {}
		var expanded_rect := rect.grow(clearance)
		return {
			"id": str(descriptor.id),
			"kind": "rect",
			"rect": expanded_rect,
			"left": expanded_rect.position.x,
			"right": expanded_rect.end.x,
			"top": expanded_rect.position.y,
			"bottom": expanded_rect.end.y,
			"forced_side": forced_side,
		}
	return {}


func _build_clusters() -> void:
	_clusters.clear()
	var assigned: Array[bool] = []
	assigned.resize(_blockers.size())
	assigned.fill(false)
	for start in range(_blockers.size()):
		if assigned[start]:
			continue
		var member_indices: Array[int] = [start]
		assigned[start] = true
		var cursor := 0
		while cursor < member_indices.size():
			var current := member_indices[cursor]
			cursor += 1
			for candidate in range(_blockers.size()):
				if assigned[candidate]:
					continue
				if _blockers_touch(_blockers[current], _blockers[candidate]):
					assigned[candidate] = true
					member_indices.append(candidate)
		var members: Array[Dictionary] = []
		for index in member_indices:
			members.append(_blockers[index])
		_clusters.append(_make_cluster(members))
	configured_cluster_count = _clusters.size()


func _make_cluster(members: Array[Dictionary]) -> Dictionary:
	var left := INF
	var right := -INF
	var top := INF
	var bottom := -INF
	var forced_side := 0
	var ids: Array[String] = []
	for member in members:
		left = minf(left, float(member.left))
		right = maxf(right, float(member.right))
		top = minf(top, float(member.top))
		bottom = maxf(bottom, float(member.bottom))
		ids.append(str(member.id))
		var member_forced := int(member.forced_side)
		if forced_side == 0 and member_forced != 0:
			forced_side = member_forced
	ids.sort()
	var cluster_id := ids[0] if ids.size() == 1 else "cluster:" + "|".join(ids)
	return {
		"id": cluster_id,
		"cluster_ids": [cluster_id],
		"members": members,
		"left": left,
		"right": right,
		"top": top,
		"bottom": bottom,
		"forced_side": forced_side,
	}


func _blockers_touch(first: Dictionary, second: Dictionary) -> bool:
	if first.kind == "circle" and second.kind == "circle":
		var combined := float(first.radius) + float(second.radius)
		return first.center.distance_squared_to(second.center) <= combined * combined
	if first.kind == "circle":
		return _circle_intersects_rect(first.center, float(first.radius), second)
	if second.kind == "circle":
		return _circle_intersects_rect(second.center, float(second.radius), first)
	return (
		float(first.right) >= float(second.left)
		and float(first.left) <= float(second.right)
		and float(first.bottom) >= float(second.top)
		and float(first.top) <= float(second.bottom)
	)


func _circle_intersects_rect(center: Vector2, radius: float, rect_blocker: Dictionary) -> bool:
	var closest := Vector2(
		clampf(center.x, float(rect_blocker.left), float(rect_blocker.right)),
		clampf(center.y, float(rect_blocker.top), float(rect_blocker.bottom))
	)
	return center.distance_squared_to(closest) <= radius * radius


func _forced_side(value: Variant) -> int:
	if value is String:
		if value == "left":
			return -1
		if value == "right":
			return 1
	if _is_number(value):
		return signi(int(value))
	return 0


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _finite_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)


func _find_cluster(id: Variant) -> Dictionary:
	for cluster in _clusters:
		if cluster.id == id:
			return cluster
	return {}


func _nearest_forward_cluster(
	position: Vector2,
	direction: int,
	lookahead: float,
	offsets: Array
) -> Dictionary:
	var corridor_left := minf(position.x, preferred_x) + _minimum_offset_x(offsets)
	var corridor_right := maxf(position.x, preferred_x) + _maximum_offset_x(offsets)
	var forward_y := position.y + direction * lookahead
	var corridor_top := minf(position.y, forward_y) + _minimum_offset_y(offsets)
	var corridor_bottom := maxf(position.y, forward_y) + _maximum_offset_y(offsets)
	var nearest := {}
	var nearest_distance := INF
	for cluster in _clusters:
		if not _cluster_intersects_rect(
			cluster,
			corridor_left,
			corridor_right,
			corridor_top,
			corridor_bottom
		):
			continue
		var distance := _cluster_forward_distance(
			cluster,
			position.y,
			direction,
			corridor_left,
			corridor_right
		)
		if distance > lookahead:
			continue
		if distance < nearest_distance or (
			is_equal_approx(distance, nearest_distance)
			and str(cluster.id) < str(nearest.get("id", ""))
		):
			nearest = cluster
			nearest_distance = distance
	return nearest


func _cluster_forward_distance(
	cluster: Dictionary,
	origin_y: float,
	direction: int,
	corridor_left: float,
	corridor_right: float
) -> float:
	var nearest := INF
	var members: Array[Dictionary] = cluster.members
	for member in members:
		var center_y := (float(member.top) + float(member.bottom)) * 0.5
		var extent := (float(member.bottom) - float(member.top)) * 0.5
		if member.kind == "circle":
			var center_x := float(member.center.x)
			var x_distance := 0.0
			if center_x < corridor_left:
				x_distance = corridor_left - center_x
			elif center_x > corridor_right:
				x_distance = center_x - corridor_right
			var radius := float(member.radius)
			if x_distance > radius:
				continue
			extent = sqrt(maxf(radius * radius - x_distance * x_distance, 0.0))
		var near_distance := direction * (center_y - origin_y) - extent
		var far_distance := direction * (center_y - origin_y) + extent
		if far_distance >= 0.0:
			nearest = minf(nearest, maxf(near_distance, 0.0))
	return nearest


func _cluster_fully_behind(
	cluster: Dictionary,
	origin_y: float,
	direction: int,
	offsets: Array
) -> bool:
	if offsets.is_empty():
		return (
			origin_y > float(cluster.bottom)
			if direction > 0
			else origin_y < float(cluster.top)
		)
	for value in offsets:
		var offset: Vector2 = value
		var member_y := origin_y + offset.y
		if direction > 0 and member_y <= float(cluster.bottom):
			return false
		if direction < 0 and member_y >= float(cluster.top):
			return false
	return true


func _clear_transition_is_safe(
	position: Vector2,
	current_offsets: Array,
	target_offsets: Array
) -> bool:
	if target_offsets.is_empty():
		return true
	if not _formation_target_within_bounds(preferred_x, target_offsets):
		return false
	var member_count := maxi(maxi(current_offsets.size(), target_offsets.size()), 1)
	for cluster in _clusters:
		for index in range(member_count):
			var current_offset := _member_offset(current_offsets, index)
			var target_offset := _member_offset(target_offsets, index, current_offset)
			var start := position + current_offset
			var finish := Vector2(preferred_x, position.y) + target_offset
			if _cluster_intersects_rect(
				cluster,
				minf(start.x, finish.x),
				maxf(start.x, finish.x),
				minf(start.y, finish.y),
				maxf(start.y, finish.y)
			):
				return false
	return true


func _choose_detour(
	active: Dictionary,
	position: Vector2,
	direction: int,
	lookahead: float,
	current_offsets: Array,
	left_offsets: Array,
	right_offsets: Array
) -> void:
	var forced := int(active.forced_side)
	var sides: Array[int] = []
	if forced != 0:
		sides.append(forced)
	elif detour_side != 0:
		sides.append(detour_side)
		sides.append(-detour_side)
	else:
		sides.assign([-1, 1])
	var found := false
	var best_side := 0
	var best_target := preferred_x
	var best_navigation := {}
	var best_target_offsets: Array = []
	var best_deviation := INF
	for side in sides:
		var target_offsets: Array = (
			left_offsets
			if side < 0 and not left_offsets.is_empty()
			else right_offsets
			if side > 0 and not right_offsets.is_empty()
			else current_offsets
		)
		var option := _extended_navigation_option(
			active,
			side,
			position,
			direction,
			lookahead,
			current_offsets,
			target_offsets
		)
		if not bool(option.found):
			continue
		var candidate := float(option.target_x)
		var deviation := absf(candidate - preferred_x)
		if not found or deviation < best_deviation:
			found = true
			best_side = side
			best_target = candidate
			best_deviation = deviation
			best_navigation = option.navigation
			best_target_offsets = target_offsets
		if detour_side != 0 and side == detour_side:
			break
	blocked = not found
	if found:
		detour_side = best_side
		detour_target_x = best_target
		_active_navigation = best_navigation
		active_blocker_id = best_navigation.id
		formation_transitioning = _formation_needs_transition(
			position.x,
			best_target,
			current_offsets,
			best_target_offsets
		)
	else:
		detour_side = 0
		formation_transitioning = false


func _formation_needs_transition(
	current_x: float,
	target_x: float,
	current_offsets: Array,
	target_offsets: Array
) -> bool:
	if absf(current_x - target_x) > 0.001:
		return true
	var member_count := maxi(current_offsets.size(), target_offsets.size())
	for index in range(member_count):
		if not _member_offset(current_offsets, index).is_equal_approx(
			_member_offset(target_offsets, index)
		):
			return true
	return false


func _extended_navigation_option(
	initial_navigation: Dictionary,
	side: int,
	position: Vector2,
	direction: int,
	lookahead: float,
	current_offsets: Array,
	target_offsets: Array
) -> Dictionary:
	var navigation: Dictionary = initial_navigation
	for _iteration in range(_clusters.size() + 1):
		if int(navigation.forced_side) != 0 and int(navigation.forced_side) != side:
			return {"found": false}
		var candidate := _navigation_candidate_x(navigation, side, target_offsets)
		if not _formation_target_within_bounds(candidate, target_offsets):
			return {"found": false}
		var conflict := _first_navigation_conflict(
			navigation,
			candidate,
			position,
			direction,
			lookahead,
			current_offsets,
			target_offsets
		)
		if conflict.is_empty():
			return {
				"found": true,
				"target_x": candidate,
				"navigation": navigation,
			}
		if int(conflict.forced_side) != 0 and int(conflict.forced_side) != side:
			return {"found": false}
		navigation = _merge_navigation(navigation, conflict)
	return {"found": false}


func _navigation_candidate_x(
	navigation: Dictionary,
	side: int,
	target_offsets: Array
) -> float:
	return (
		float(navigation.left) - _maximum_offset_x(target_offsets)
		if side < 0
		else float(navigation.right) - _minimum_offset_x(target_offsets)
	)


func _formation_target_within_bounds(candidate_x: float, target_offsets: Array) -> bool:
	if target_offsets.is_empty():
		return candidate_x >= min_x and candidate_x <= max_x
	for value in target_offsets:
		var offset: Vector2 = value
		var member_x := candidate_x + offset.x
		if member_x < min_x or member_x > max_x:
			return false
	return true


func _first_navigation_conflict(
	navigation: Dictionary,
	candidate_x: float,
	position: Vector2,
	direction: int,
	lookahead: float,
	current_offsets: Array,
	target_offsets: Array
) -> Dictionary:
	var navigation_exit_y := (
		float(navigation.bottom)
		if direction > 0
		else float(navigation.top)
	)
	var forward_y := position.y + direction * lookahead
	forward_y = (
		maxf(forward_y, navigation_exit_y)
		if direction > 0
		else minf(forward_y, navigation_exit_y)
	)
	var best := {}
	var best_distance := INF
	for cluster in _clusters:
		if _navigation_contains_cluster(navigation, str(cluster.id)):
			continue
		if not _cluster_intersects_formation_sweep(
			cluster,
			candidate_x,
			position,
			forward_y,
			current_offsets,
			target_offsets
		):
			continue
		var distance := maxf(
			direction * (
				(float(cluster.top) + float(cluster.bottom)) * 0.5 - position.y
			),
			0.0
		)
		if distance < best_distance or (
			is_equal_approx(distance, best_distance)
			and str(cluster.id) < str(best.get("id", ""))
		):
			best = cluster
			best_distance = distance
	return best


func _cluster_intersects_formation_sweep(
	cluster: Dictionary,
	candidate_x: float,
	position: Vector2,
	forward_y: float,
	current_offsets: Array,
	target_offsets: Array
) -> bool:
	var member_count := maxi(maxi(current_offsets.size(), target_offsets.size()), 1)
	for index in range(member_count):
		var current_offset := _member_offset(current_offsets, index)
		var target_offset := _member_offset(target_offsets, index, current_offset)
		var start := position + current_offset
		var finish := Vector2(candidate_x, forward_y) + target_offset
		if _cluster_touches_rect(
			cluster,
			minf(start.x, finish.x),
			maxf(start.x, finish.x),
			minf(start.y, finish.y),
			maxf(start.y, finish.y)
		):
			return true
	return false


func _cluster_touches_rect(
	cluster: Dictionary,
	left: float,
	right: float,
	top: float,
	bottom: float
) -> bool:
	var members: Array[Dictionary] = cluster.members
	for member in members:
		if member.kind == "circle":
			var center: Vector2 = member.center
			var closest := Vector2(
				clampf(center.x, left, right),
				clampf(center.y, top, bottom)
			)
			if (
				center.distance_squared_to(closest)
					<= float(member.radius) * float(member.radius)
			):
				return true
		elif (
			float(member.right) >= left
			and float(member.left) <= right
			and float(member.bottom) >= top
			and float(member.top) <= bottom
		):
			return true
	return false


func _member_offset(offsets: Array, index: int, fallback := Vector2.ZERO) -> Vector2:
	if index >= offsets.size():
		return fallback
	var value: Variant = offsets[index]
	return value if value is Vector2 else fallback


func _navigation_contains_cluster(navigation: Dictionary, cluster_id: String) -> bool:
	var cluster_ids: Array = navigation.cluster_ids
	return cluster_id in cluster_ids


func _merge_navigation(first: Dictionary, second: Dictionary) -> Dictionary:
	var members: Array[Dictionary] = []
	var seen := {}
	var first_members: Array[Dictionary] = first.members
	var second_members: Array[Dictionary] = second.members
	for member in first_members + second_members:
		var member_id := str(member.id)
		if seen.has(member_id):
			continue
		seen[member_id] = true
		members.append(member)
	var merged := _make_cluster(members)
	var cluster_ids: Array[String] = []
	for value in first.cluster_ids:
		cluster_ids.append(str(value))
	for value in second.cluster_ids:
		var cluster_id := str(value)
		if cluster_id not in cluster_ids:
			cluster_ids.append(cluster_id)
	cluster_ids.sort()
	merged.cluster_ids = cluster_ids
	return merged


func _spawn_sweep_blocked(
	origin_x: float,
	origin_y: float,
	vertical_speed: float,
	offsets: Array[Vector2]
) -> bool:
	var lookahead := minimum_lookahead + absf(vertical_speed) * lookahead_time
	var direction := 0
	if not is_zero_approx(vertical_speed):
		direction = 1 if vertical_speed > 0.0 else -1
	for offset in offsets:
		var start := Vector2(origin_x, origin_y) + offset
		var finish := start + Vector2(0.0, direction * lookahead)
		for cluster in _clusters:
			if _cluster_intersects_rect(
				cluster,
				start.x,
				finish.x,
				minf(start.y, finish.y),
				maxf(start.y, finish.y)
			):
				return true
	return false


func _cluster_intersects_rect(
	cluster: Dictionary,
	left: float,
	right: float,
	top: float,
	bottom: float
) -> bool:
	var members: Array[Dictionary] = cluster.members
	for member in members:
		if _blocker_intersects_rect(member, left, right, top, bottom):
			return true
	return false


func _blocker_intersects_rect(
	blocker: Dictionary,
	left: float,
	right: float,
	top: float,
	bottom: float
) -> bool:
	if blocker.kind == "circle":
		var center: Vector2 = blocker.center
		var closest := Vector2(
			clampf(center.x, left, right),
			clampf(center.y, top, bottom)
		)
		return center.distance_squared_to(closest) < float(blocker.radius) * float(blocker.radius)
	return (
		float(blocker.right) > left
		and float(blocker.left) < right
		and float(blocker.bottom) > top
		and float(blocker.top) < bottom
	)
