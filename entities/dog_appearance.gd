class_name DogAppearance
extends RefCounted

const MAX_LOCAL_RADIUS := 40.0
const MAX_BOB := 1.5
const PROFILE_IDS := [
	"compact_point_ear",
	"long_low_drop_ear",
	"tall_narrow_rose_ear",
	"stocky_fold_ear",
	"fluffy_curl_tail",
	"shaggy_drop_ear",
]
const REQUIRED_FIELDS := [
	"id",
	"name",
	"size_scale",
	"body_size",
	"head_radius",
	"muzzle_size",
	"ear_style",
	"ear_size",
	"ear_offset",
	"tail_style",
	"tail_length",
	"tail_thickness",
	"tail_carriage",
	"base_color",
	"secondary_color",
	"marking_color",
	"marking_style",
	"marking_offset",
	"marking_scale",
]
const POSITIVE_FLOAT_FIELDS := [
	"size_scale",
	"head_radius",
	"tail_length",
	"tail_thickness",
]
const POSITIVE_VECTOR_FIELDS := [
	"body_size",
	"muzzle_size",
	"ear_size",
	"marking_scale",
]
const PLACEMENT_VECTOR_FIELDS := [
	"ear_offset",
	"marking_offset",
]
const COLOR_FIELDS := [
	"base_color",
	"secondary_color",
	"marking_color",
]
const EAR_STYLES := ["point", "drop", "rose", "fold"]
const TAIL_STYLES := ["straight", "whip", "curl", "plume"]
const MARKING_STYLES := ["solid", "patch", "blaze_points", "brindle"]

const PROFILES := {
	"compact_point_ear": {
		"id": "compact_point_ear",
		"name": "Compact Point-Ear",
		"size_scale": 0.92,
		"body_size": Vector2(8.5, 6.5),
		"head_radius": 5.4,
		"muzzle_size": Vector2(3.8, 1.8),
		"ear_style": "point",
		"ear_size": Vector2(3.0, 5.0),
		"ear_offset": Vector2(-1.0, 3.6),
		"tail_style": "straight",
		"tail_length": 9.0,
		"tail_thickness": 2.2,
		"tail_carriage": 0.35,
		"base_color": Color(0.63, 0.43, 0.25),
		"secondary_color": Color(0.78, 0.62, 0.40),
		"marking_color": Color(0.94, 0.86, 0.68),
		"marking_style": "solid",
		"marking_offset": Vector2(-1.0, 0.0),
		"marking_scale": Vector2(2.0, 1.5),
	},
	"long_low_drop_ear": {
		"id": "long_low_drop_ear",
		"name": "Long Low Drop-Ear",
		"size_scale": 0.88,
		"body_size": Vector2(14.0, 5.0),
		"head_radius": 5.0,
		"muzzle_size": Vector2(5.0, 2.0),
		"ear_style": "drop",
		"ear_size": Vector2(3.0, 6.0),
		"ear_offset": Vector2(-2.0, 3.8),
		"tail_style": "whip",
		"tail_length": 12.0,
		"tail_thickness": 1.4,
		"tail_carriage": -0.15,
		"base_color": Color(0.74, 0.57, 0.34),
		"secondary_color": Color(0.52, 0.35, 0.20),
		"marking_color": Color(0.91, 0.80, 0.60),
		"marking_style": "patch",
		"marking_offset": Vector2(-2.5, 1.0),
		"marking_scale": Vector2(5.0, 2.8),
	},
	"tall_narrow_rose_ear": {
		"id": "tall_narrow_rose_ear",
		"name": "Tall Narrow Rose-Ear",
		"size_scale": 1.08,
		"body_size": Vector2(9.0, 4.2),
		"head_radius": 4.6,
		"muzzle_size": Vector2(4.2, 1.6),
		"ear_style": "rose",
		"ear_size": Vector2(3.5, 3.0),
		"ear_offset": Vector2(-1.2, 3.0),
		"tail_style": "straight",
		"tail_length": 12.5,
		"tail_thickness": 1.2,
		"tail_carriage": 0.05,
		"base_color": Color(0.42, 0.43, 0.46),
		"secondary_color": Color(0.61, 0.61, 0.63),
		"marking_color": Color(0.92, 0.91, 0.86),
		"marking_style": "blaze_points",
		"marking_offset": Vector2(1.5, 0.0),
		"marking_scale": Vector2(4.2, 1.1),
	},
	"stocky_fold_ear": {
		"id": "stocky_fold_ear",
		"name": "Stocky Fold-Ear",
		"size_scale": 1.12,
		"body_size": Vector2(10.0, 7.2),
		"head_radius": 6.2,
		"muzzle_size": Vector2(3.8, 2.6),
		"ear_style": "fold",
		"ear_size": Vector2(4.2, 4.0),
		"ear_offset": Vector2(-1.8, 4.0),
		"tail_style": "whip",
		"tail_length": 8.0,
		"tail_thickness": 2.0,
		"tail_carriage": 0.55,
		"base_color": Color(0.24, 0.22, 0.21),
		"secondary_color": Color(0.39, 0.32, 0.27),
		"marking_color": Color(0.62, 0.48, 0.34),
		"marking_style": "brindle",
		"marking_offset": Vector2(-1.0, 0.0),
		"marking_scale": Vector2(6.0, 5.0),
	},
	"fluffy_curl_tail": {
		"id": "fluffy_curl_tail",
		"name": "Fluffy Curl-Tail",
		"size_scale": 1.02,
		"body_size": Vector2(11.0, 7.6),
		"head_radius": 6.0,
		"muzzle_size": Vector2(4.0, 2.3),
		"ear_style": "point",
		"ear_size": Vector2(4.0, 5.5),
		"ear_offset": Vector2(-1.5, 4.2),
		"tail_style": "curl",
		"tail_length": 10.0,
		"tail_thickness": 3.0,
		"tail_carriage": 0.9,
		"base_color": Color(0.87, 0.78, 0.58),
		"secondary_color": Color(0.96, 0.90, 0.73),
		"marking_color": Color(0.58, 0.43, 0.27),
		"marking_style": "patch",
		"marking_offset": Vector2(0.5, -2.0),
		"marking_scale": Vector2(4.0, 2.8),
	},
	"shaggy_drop_ear": {
		"id": "shaggy_drop_ear",
		"name": "Shaggy Drop-Ear",
		"size_scale": 0.98,
		"body_size": Vector2(12.0, 6.2),
		"head_radius": 5.8,
		"muzzle_size": Vector2(5.2, 2.4),
		"ear_style": "drop",
		"ear_size": Vector2(3.8, 6.2),
		"ear_offset": Vector2(-1.8, 4.0),
		"tail_style": "plume",
		"tail_length": 13.0,
		"tail_thickness": 2.8,
		"tail_carriage": 0.45,
		"base_color": Color(0.36, 0.30, 0.24),
		"secondary_color": Color(0.60, 0.53, 0.42),
		"marking_color": Color(0.78, 0.72, 0.62),
		"marking_style": "brindle",
		"marking_offset": Vector2(-1.0, 0.0),
		"marking_scale": Vector2(7.0, 4.5),
	},
}


static func profile_ids() -> PackedStringArray:
	return PackedStringArray(PROFILE_IDS)


static func get_profile(profile_id: String) -> Dictionary:
	var resolved_id := profile_id if PROFILES.has(profile_id) else String(PROFILE_IDS[0])
	var canonical: Dictionary = PROFILES[resolved_id]
	return canonical.duplicate(true)


static func profile_id_for_key(key: int) -> String:
	var count := PROFILE_IDS.size()
	var index := ((key % count) + count) % count
	return String(PROFILE_IDS[index])


static func profile_for_key(key: int) -> Dictionary:
	return get_profile(profile_id_for_key(key))


static func _is_finite_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)


static func _is_valid_color(value: Variant) -> bool:
	if typeof(value) != TYPE_COLOR:
		return false
	var color: Color = value
	return (
		is_finite(color.r)
		and is_finite(color.g)
		and is_finite(color.b)
		and is_finite(color.a)
		and color.r >= 0.0
		and color.r <= 1.0
		and color.g >= 0.0
		and color.g <= 1.0
		and color.b >= 0.0
		and color.b <= 1.0
		and color.a >= 0.0
		and color.a <= 1.0
	)


static func _geometry_radius(profile: Dictionary) -> float:
	var scale: float = profile["size_scale"]
	var body_size: Vector2 = profile["body_size"]
	var head_radius: float = profile["head_radius"]
	var muzzle_size: Vector2 = profile["muzzle_size"]
	var ear_size: Vector2 = profile["ear_size"]
	var ear_offset: Vector2 = profile["ear_offset"]
	var tail_length: float = profile["tail_length"]
	var tail_thickness: float = profile["tail_thickness"]
	var marking_offset: Vector2 = profile["marking_offset"]
	var marking_scale: Vector2 = profile["marking_scale"]
	var head_center_x := body_size.x * 0.65 + head_radius * 0.35
	var body_radius := body_size.length()
	var head_extent := head_center_x + head_radius
	var muzzle_extent := head_center_x + head_radius + muzzle_size.x + muzzle_size.y
	var ear_extent := head_center_x + ear_offset.length() + ear_size.length()
	var tail_extent := body_size.x * 0.8 + tail_length * 1.25 + tail_thickness * 1.65
	var marking_extent := head_center_x + marking_offset.length() + marking_scale.length()
	return (
		maxf(
			body_radius,
			maxf(
				head_extent,
				maxf(muzzle_extent, maxf(ear_extent, maxf(tail_extent, marking_extent)))
			)
		) * scale
		+ MAX_BOB
	)


static func validation_errors(profile: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var has_missing_field := false
	for field: String in REQUIRED_FIELDS:
		if not profile.has(field):
			errors.append("missing field: " + field)
			has_missing_field = true
	for field: Variant in profile.keys():
		if not REQUIRED_FIELDS.has(String(field)):
			errors.append("unexpected field: " + String(field))
	if has_missing_field:
		return errors

	for field: String in ["id", "name"]:
		var value: Variant = profile[field]
		if typeof(value) != TYPE_STRING or String(value).strip_edges().is_empty():
			errors.append(field + " must be a non-empty String")

	for field: String in POSITIVE_FLOAT_FIELDS:
		var value: Variant = profile[field]
		if typeof(value) != TYPE_FLOAT or not is_finite(float(value)) or float(value) <= 0.0:
			errors.append(field + " must be a finite float greater than zero")

	var carriage: Variant = profile["tail_carriage"]
	if typeof(carriage) != TYPE_FLOAT or not is_finite(float(carriage)):
		errors.append("tail_carriage must be a finite float")

	for field: String in POSITIVE_VECTOR_FIELDS:
		var value: Variant = profile[field]
		if (
			typeof(value) != TYPE_VECTOR2
			or not _is_finite_vector(value)
			or (value as Vector2).x <= 0.0
			or (value as Vector2).y <= 0.0
		):
			errors.append(field + " must have finite positive components")

	for field: String in PLACEMENT_VECTOR_FIELDS:
		var value: Variant = profile[field]
		if typeof(value) != TYPE_VECTOR2 or not _is_finite_vector(value):
			errors.append(field + " must be a finite Vector2")

	for field: String in COLOR_FIELDS:
		if not _is_valid_color(profile[field]):
			errors.append(field + " must be a finite Color in [0.0, 1.0]")

	if typeof(profile["ear_style"]) != TYPE_STRING or not EAR_STYLES.has(profile["ear_style"]):
		errors.append("ear_style must be one of: point, drop, rose, fold")
	if typeof(profile["tail_style"]) != TYPE_STRING or not TAIL_STYLES.has(profile["tail_style"]):
		errors.append("tail_style must be one of: straight, whip, curl, plume")
	if (
		typeof(profile["marking_style"]) != TYPE_STRING
		or not MARKING_STYLES.has(profile["marking_style"])
	):
		errors.append("marking_style must be one of: solid, patch, blaze_points, brindle")

	if errors.is_empty() and _geometry_radius(profile) > MAX_LOCAL_RADIUS:
		errors.append("generated geometry exceeds MAX_LOCAL_RADIUS")
	return errors


static func _to_canvas(
	local_point: Vector2,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> Vector2:
	return origin + forward * local_point.x + side * local_point.y


static func _ellipse_points(
	center: Vector2,
	half_extents: Vector2,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var local_point := center + Vector2(cos(angle) * half_extents.x, sin(angle) * half_extents.y)
		points.append(_to_canvas(local_point, origin, forward, side))
	return points


static func _polygon_points(
	local_points: PackedVector2Array,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for local_point: Vector2 in local_points:
		points.append(_to_canvas(local_point, origin, forward, side))
	return points


static func draw_dog(
	canvas: CanvasItem,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	bob: float,
	wag_phase: float
) -> void:
	if (
		not _is_finite_vector(origin)
		or not is_finite(bob)
		or not is_finite(wag_phase)
	):
		return
	var active_profile := profile
	if not validation_errors(active_profile).is_empty():
		active_profile = get_profile(String(PROFILE_IDS[0]))

	var facing := forward
	if not _is_finite_vector(facing) or facing.is_zero_approx():
		facing = Vector2.RIGHT
	else:
		facing = facing.normalized()
	var side := facing.orthogonal()
	var draw_origin := origin + Vector2(0.0, clampf(bob, -MAX_BOB, MAX_BOB))
	var scale: float = active_profile["size_scale"]
	var body_size: Vector2 = active_profile["body_size"] * scale
	var head_radius: float = active_profile["head_radius"] * scale
	var muzzle_size: Vector2 = active_profile["muzzle_size"] * scale
	var ear_size: Vector2 = active_profile["ear_size"] * scale
	var ear_offset: Vector2 = active_profile["ear_offset"] * scale
	var tail_length: float = active_profile["tail_length"] * scale
	var tail_thickness: float = active_profile["tail_thickness"] * scale
	var tail_carriage: float = active_profile["tail_carriage"]
	var marking_offset: Vector2 = active_profile["marking_offset"] * scale
	var marking_scale: Vector2 = active_profile["marking_scale"] * scale
	var base_color: Color = active_profile["base_color"]
	var secondary_color: Color = active_profile["secondary_color"]
	var marking_color: Color = active_profile["marking_color"]
	var head_center := Vector2(body_size.x * 0.65 + head_radius * 0.35, 0.0)
	var tail_base := Vector2(-body_size.x * 0.8, 0.0)
	var wag := sin(wag_phase) * 0.35
	var tail_angle := tail_carriage + wag
	var tail_direction := Vector2(-cos(tail_angle), sin(tail_angle))

	match String(active_profile["tail_style"]):
		"straight":
			canvas.draw_line(
				_to_canvas(tail_base, draw_origin, facing, side),
				_to_canvas(tail_base + tail_direction * tail_length, draw_origin, facing, side),
				secondary_color,
				tail_thickness,
				true
			)
		"whip":
			var whip := PackedVector2Array([
				_to_canvas(tail_base, draw_origin, facing, side),
				_to_canvas(
					tail_base + tail_direction * tail_length * 0.55 + Vector2(0.0, wag * 3.0),
					draw_origin,
					facing,
					side
				),
				_to_canvas(
					tail_base + tail_direction * tail_length + Vector2(0.0, wag * 5.0),
					draw_origin,
					facing,
					side
				),
			])
			canvas.draw_polyline(whip, secondary_color, tail_thickness, true)
		"curl":
			var curl_radius := tail_length * 0.42
			var curl_center_local := (
				tail_base
				+ tail_direction * (tail_length - curl_radius)
				+ Vector2(0.0, wag * 2.0)
			)
			var curl_center := _to_canvas(curl_center_local, draw_origin, facing, side)
			var curl_start := facing.angle() + tail_angle + PI * 0.25
			canvas.draw_arc(
				curl_center,
				curl_radius,
				curl_start,
				curl_start + PI * 1.65,
				14,
				secondary_color,
				tail_thickness,
				true
			)
		"plume":
			var plume := PackedVector2Array([
				_to_canvas(tail_base, draw_origin, facing, side),
				_to_canvas(
					tail_base + tail_direction * tail_length * 0.5 + Vector2(0.0, -tail_length * 0.2),
					draw_origin,
					facing,
					side
				),
				_to_canvas(
					tail_base + tail_direction * tail_length + Vector2(0.0, wag * 4.0),
					draw_origin,
					facing,
					side
				),
			])
			canvas.draw_polyline(plume, secondary_color, tail_thickness * 1.65, true)
			canvas.draw_polyline(plume, base_color, tail_thickness * 0.7, true)

	canvas.draw_colored_polygon(
		_ellipse_points(Vector2.ZERO, body_size, draw_origin, facing, side),
		base_color
	)

	match String(active_profile["marking_style"]):
		"solid":
			pass
		"patch":
			canvas.draw_colored_polygon(
				_ellipse_points(marking_offset, marking_scale, draw_origin, facing, side),
				marking_color
			)
		"blaze_points":
			var blaze_center := head_center + marking_offset
			canvas.draw_line(
				_to_canvas(
					blaze_center - Vector2(marking_scale.x * 0.5, 0.0),
					draw_origin,
					facing,
					side
				),
				_to_canvas(
					blaze_center + Vector2(marking_scale.x * 0.5, 0.0),
					draw_origin,
					facing,
					side
				),
				marking_color,
				maxf(1.0, marking_scale.y),
				true
			)
			canvas.draw_circle(
				_to_canvas(
					head_center + Vector2(0.0, head_radius * 0.55),
					draw_origin,
					facing,
					side
				),
				maxf(0.8, marking_scale.y * 0.65),
				marking_color
			)
			canvas.draw_circle(
				_to_canvas(
					head_center + Vector2(0.0, -head_radius * 0.55),
					draw_origin,
					facing,
					side
				),
				maxf(0.8, marking_scale.y * 0.65),
				marking_color
			)
		"brindle":
			for stripe_index in range(-2, 3):
				var stripe_x := marking_offset.x + float(stripe_index) * marking_scale.x * 0.22
				var stripe_half_y := marking_scale.y * (0.45 + 0.08 * absf(float(stripe_index)))
				canvas.draw_line(
					_to_canvas(
						Vector2(stripe_x - marking_scale.x * 0.08, marking_offset.y - stripe_half_y),
						draw_origin,
						facing,
						side
					),
					_to_canvas(
						Vector2(stripe_x + marking_scale.x * 0.08, marking_offset.y + stripe_half_y),
						draw_origin,
						facing,
						side
					),
					marking_color,
					maxf(0.8, scale),
					true
				)

	canvas.draw_colored_polygon(
		_ellipse_points(head_center, Vector2(head_radius, head_radius), draw_origin, facing, side),
		base_color
	)

	for ear_side in [-1.0, 1.0]:
		var ear_base := head_center + Vector2(ear_offset.x, ear_offset.y * ear_side)
		match String(active_profile["ear_style"]):
			"point":
				var point_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.45, -ear_size.x * 0.45 * ear_side),
					ear_base + Vector2(-ear_size.y, 0.0),
					ear_base + Vector2(ear_size.x * 0.45, ear_size.x * 0.45 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(point_ear, draw_origin, facing, side),
					secondary_color
				)
			"drop":
				var drop_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.35, -ear_size.x * 0.45 * ear_side),
					ear_base + Vector2(-ear_size.x * 0.3, ear_size.y * ear_side),
					ear_base + Vector2(-ear_size.x, ear_size.y * 0.65 * ear_side),
					ear_base + Vector2(-ear_size.x * 0.4, ear_size.x * 0.45 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(drop_ear, draw_origin, facing, side),
					secondary_color
				)
			"rose":
				var rose_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.45, -ear_size.y * 0.5 * ear_side),
					ear_base + Vector2(-ear_size.x, 0.0),
					ear_base + Vector2(ear_size.x * 0.25, ear_size.y * 0.5 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(rose_ear, draw_origin, facing, side),
					secondary_color
				)
			"fold":
				var fold_ear := PackedVector2Array([
					ear_base + Vector2(ear_size.x * 0.5, -ear_size.y * 0.4 * ear_side),
					ear_base + Vector2(-ear_size.x, -ear_size.y * 0.2 * ear_side),
					ear_base + Vector2(-ear_size.x * 0.2, ear_size.y * ear_side),
					ear_base + Vector2(ear_size.x * 0.45, ear_size.y * 0.35 * ear_side),
				])
				canvas.draw_colored_polygon(
					_polygon_points(fold_ear, draw_origin, facing, side),
					secondary_color
				)
				canvas.draw_line(
					_to_canvas(ear_base, draw_origin, facing, side),
					_to_canvas(
						ear_base + Vector2(-ear_size.x * 0.35, ear_size.y * 0.35 * ear_side),
						draw_origin,
						facing,
						side
					),
					base_color,
					maxf(0.8, scale),
					true
				)

	var muzzle_center := head_center + Vector2(head_radius + muzzle_size.x * 0.45, 0.0)
	canvas.draw_colored_polygon(
		_ellipse_points(
			muzzle_center,
			Vector2(muzzle_size.x * 0.55, muzzle_size.y),
			draw_origin,
			facing,
			side
		),
		secondary_color
	)
	for eye_side in [-1.0, 1.0]:
		canvas.draw_circle(
			_to_canvas(
				head_center + Vector2(head_radius * 0.3, head_radius * 0.42 * eye_side),
				draw_origin,
				facing,
				side
			),
			maxf(0.7, scale),
			Color(0.08, 0.07, 0.06)
		)
	canvas.draw_circle(
		_to_canvas(
			muzzle_center + Vector2(muzzle_size.x * 0.52, 0.0),
			draw_origin,
			facing,
			side
		),
		maxf(1.0, muzzle_size.y * 0.45),
		Color(0.08, 0.07, 0.06)
	)
