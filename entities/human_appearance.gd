class_name HumanAppearance
extends RefCounted

const MAX_LOCAL_RADIUS := 48.0
const MAX_SWAY := 1.5
const PHONE_HELD_FORWARD := 24.0
const PHONE_RAISED_FORWARD := 30.0
const DRAW_MARGIN := 3.0
const PROFILE_IDS := [
	"compact_short_cap",
	"tall_long_glasses",
	"broad_bun_sunglasses",
	"medium_bald_spot_glasses",
	"narrow_short_beanie",
	"rounded_long_cap",
]
const REQUIRED_FIELDS := [
	"id",
	"name",
	"size_scale",
	"body_size",
	"head_radius",
	"head_forward_offset",
	"foot_radius",
	"foot_spread",
	"step_distance",
	"arm_width",
	"skin_color",
	"shirt_color",
	"pants_color",
	"hair_color",
	"hair_style",
	"headwear_style",
	"headwear_color",
	"eyewear_style",
	"eyewear_color",
	"phone_size",
	"phone_body_color",
	"phone_screen_color",
	"phone_accent_color",
	"phone_treatment",
]
const POSITIVE_FLOAT_FIELDS := [
	"size_scale",
	"head_radius",
	"head_forward_offset",
	"foot_radius",
	"foot_spread",
	"step_distance",
	"arm_width",
]
const POSITIVE_VECTOR_FIELDS := ["body_size", "phone_size"]
const COLOR_FIELDS := [
	"skin_color",
	"shirt_color",
	"pants_color",
	"hair_color",
	"headwear_color",
	"eyewear_color",
	"phone_body_color",
	"phone_screen_color",
	"phone_accent_color",
]
const HAIR_STYLES := ["short", "long", "bun", "bald_spot"]
const HEADWEAR_STYLES := ["none", "cap", "beanie"]
const EYEWEAR_STYLES := ["none", "glasses", "sunglasses"]
const PHONE_TREATMENTS := ["plain", "bumper", "sticker"]

const PROFILES := {
	"compact_short_cap": {
		"id": "compact_short_cap",
		"name": "Compact Short-Hair Cap",
		"size_scale": 0.94,
		"body_size": Vector2(13.0, 14.0),
		"head_radius": 8.5,
		"head_forward_offset": 5.0,
		"foot_radius": 4.5,
		"foot_spread": 6.5,
		"step_distance": 5.5,
		"arm_width": 4.5,
		"skin_color": Color(0.78, 0.59, 0.45),
		"shirt_color": Color(0.38, 0.49, 0.66),
		"pants_color": Color(0.22, 0.25, 0.31),
		"hair_color": Color(0.25, 0.18, 0.12),
		"hair_style": "short",
		"headwear_style": "cap",
		"headwear_color": Color(0.72, 0.30, 0.25),
		"eyewear_style": "none",
		"eyewear_color": Color(0.10, 0.10, 0.12),
		"phone_size": Vector2(12.0, 18.0),
		"phone_body_color": Color(0.08, 0.09, 0.12),
		"phone_screen_color": Color(0.63, 0.82, 1.0),
		"phone_accent_color": Color(0.72, 0.30, 0.25),
		"phone_treatment": "plain",
	},
	"tall_long_glasses": {
		"id": "tall_long_glasses",
		"name": "Tall Long-Hair Glasses",
		"size_scale": 1.05,
		"body_size": Vector2(15.0, 13.0),
		"head_radius": 8.0,
		"head_forward_offset": 5.5,
		"foot_radius": 4.2,
		"foot_spread": 7.0,
		"step_distance": 6.0,
		"arm_width": 4.0,
		"skin_color": Color(0.52, 0.34, 0.25),
		"shirt_color": Color(0.24, 0.56, 0.55),
		"pants_color": Color(0.20, 0.24, 0.29),
		"hair_color": Color(0.12, 0.09, 0.08),
		"hair_style": "long",
		"headwear_style": "none",
		"headwear_color": Color(0.24, 0.56, 0.55),
		"eyewear_style": "glasses",
		"eyewear_color": Color(0.12, 0.12, 0.14),
		"phone_size": Vector2(11.0, 18.0),
		"phone_body_color": Color(0.12, 0.13, 0.16),
		"phone_screen_color": Color(0.72, 0.88, 0.96),
		"phone_accent_color": Color(0.90, 0.70, 0.26),
		"phone_treatment": "bumper",
	},
	"broad_bun_sunglasses": {
		"id": "broad_bun_sunglasses",
		"name": "Broad Bun Sunglasses",
		"size_scale": 1.08,
		"body_size": Vector2(13.5, 17.0),
		"head_radius": 9.2,
		"head_forward_offset": 4.8,
		"foot_radius": 4.8,
		"foot_spread": 7.5,
		"step_distance": 5.2,
		"arm_width": 5.0,
		"skin_color": Color(0.88, 0.72, 0.58),
		"shirt_color": Color(0.64, 0.38, 0.55),
		"pants_color": Color(0.29, 0.25, 0.34),
		"hair_color": Color(0.40, 0.25, 0.15),
		"hair_style": "bun",
		"headwear_style": "none",
		"headwear_color": Color(0.64, 0.38, 0.55),
		"eyewear_style": "sunglasses",
		"eyewear_color": Color(0.06, 0.07, 0.09),
		"phone_size": Vector2(13.0, 18.0),
		"phone_body_color": Color(0.15, 0.10, 0.16),
		"phone_screen_color": Color(0.76, 0.82, 1.0),
		"phone_accent_color": Color(0.96, 0.76, 0.30),
		"phone_treatment": "sticker",
	},
	"medium_bald_spot_glasses": {
		"id": "medium_bald_spot_glasses",
		"name": "Medium Bald-Spot Glasses",
		"size_scale": 1.0,
		"body_size": Vector2(14.5, 15.0),
		"head_radius": 9.4,
		"head_forward_offset": 4.5,
		"foot_radius": 4.6,
		"foot_spread": 7.0,
		"step_distance": 5.0,
		"arm_width": 4.8,
		"skin_color": Color(0.68, 0.47, 0.34),
		"shirt_color": Color(0.48, 0.55, 0.34),
		"pants_color": Color(0.28, 0.29, 0.25),
		"hair_color": Color(0.20, 0.15, 0.11),
		"hair_style": "bald_spot",
		"headwear_style": "none",
		"headwear_color": Color(0.48, 0.55, 0.34),
		"eyewear_style": "glasses",
		"eyewear_color": Color(0.18, 0.14, 0.12),
		"phone_size": Vector2(12.0, 17.0),
		"phone_body_color": Color(0.09, 0.11, 0.10),
		"phone_screen_color": Color(0.66, 0.86, 0.78),
		"phone_accent_color": Color(0.48, 0.55, 0.34),
		"phone_treatment": "plain",
	},
	"narrow_short_beanie": {
		"id": "narrow_short_beanie",
		"name": "Narrow Short-Hair Beanie",
		"size_scale": 0.98,
		"body_size": Vector2(15.5, 12.0),
		"head_radius": 8.3,
		"head_forward_offset": 5.5,
		"foot_radius": 4.2,
		"foot_spread": 6.2,
		"step_distance": 6.0,
		"arm_width": 4.0,
		"skin_color": Color(0.39, 0.27, 0.21),
		"shirt_color": Color(0.72, 0.48, 0.24),
		"pants_color": Color(0.18, 0.22, 0.28),
		"hair_color": Color(0.08, 0.07, 0.07),
		"hair_style": "short",
		"headwear_style": "beanie",
		"headwear_color": Color(0.26, 0.38, 0.58),
		"eyewear_style": "sunglasses",
		"eyewear_color": Color(0.05, 0.06, 0.08),
		"phone_size": Vector2(11.0, 18.0),
		"phone_body_color": Color(0.08, 0.09, 0.13),
		"phone_screen_color": Color(0.70, 0.84, 1.0),
		"phone_accent_color": Color(0.26, 0.38, 0.58),
		"phone_treatment": "bumper",
	},
	"rounded_long_cap": {
		"id": "rounded_long_cap",
		"name": "Rounded Long-Hair Cap",
		"size_scale": 1.03,
		"body_size": Vector2(13.0, 16.0),
		"head_radius": 8.8,
		"head_forward_offset": 5.0,
		"foot_radius": 4.7,
		"foot_spread": 7.2,
		"step_distance": 5.4,
		"arm_width": 4.6,
		"skin_color": Color(0.93, 0.79, 0.66),
		"shirt_color": Color(0.38, 0.43, 0.62),
		"pants_color": Color(0.25, 0.23, 0.31),
		"hair_color": Color(0.58, 0.39, 0.20),
		"hair_style": "long",
		"headwear_style": "cap",
		"headwear_color": Color(0.34, 0.62, 0.48),
		"eyewear_style": "none",
		"eyewear_color": Color(0.12, 0.12, 0.14),
		"phone_size": Vector2(12.0, 18.0),
		"phone_body_color": Color(0.13, 0.12, 0.16),
		"phone_screen_color": Color(0.78, 0.88, 1.0),
		"phone_accent_color": Color(0.34, 0.62, 0.48),
		"phone_treatment": "sticker",
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
	var body_size: Vector2 = profile["body_size"]
	var phone_size: Vector2 = profile["phone_size"]
	var body_extent := body_size.length() + MAX_SWAY
	var head_extent := (
		float(profile["head_forward_offset"])
		+ float(profile["head_radius"]) * 2.35
		+ DRAW_MARGIN
	)
	var feet_extent := Vector2(
		float(profile["step_distance"]) + float(profile["foot_radius"]),
		float(profile["foot_spread"]) + float(profile["foot_radius"])
	).length()
	var phone_extent := (
		Vector2(
			PHONE_RAISED_FORWARD + phone_size.y * 0.5,
			phone_size.x * 0.5
		).length()
		+ DRAW_MARGIN
	)
	return maxf(body_extent, maxf(head_extent, maxf(feet_extent, phone_extent))) * float(
		profile["size_scale"]
	)


static func validation_errors(profile: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var has_missing_field := false
	for field: String in REQUIRED_FIELDS:
		if not profile.has(field):
			errors.append("missing field: " + field)
			has_missing_field = true
	for field: Variant in profile.keys():
		if typeof(field) != TYPE_STRING or not REQUIRED_FIELDS.has(String(field)):
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
	for field: String in POSITIVE_VECTOR_FIELDS:
		var value: Variant = profile[field]
		if (
			typeof(value) != TYPE_VECTOR2
			or not _is_finite_vector(value)
			or (value as Vector2).x <= 0.0
			or (value as Vector2).y <= 0.0
		):
			errors.append(field + " must have finite positive components")
	for field: String in COLOR_FIELDS:
		if not _is_valid_color(profile[field]):
			errors.append(field + " must be a finite Color in [0.0, 1.0]")
	if typeof(profile["hair_style"]) != TYPE_STRING or not HAIR_STYLES.has(profile["hair_style"]):
		errors.append("hair_style must be one of: short, long, bun, bald_spot")
	if (
		typeof(profile["headwear_style"]) != TYPE_STRING
		or not HEADWEAR_STYLES.has(profile["headwear_style"])
	):
		errors.append("headwear_style must be one of: none, cap, beanie")
	if (
		typeof(profile["eyewear_style"]) != TYPE_STRING
		or not EYEWEAR_STYLES.has(profile["eyewear_style"])
	):
		errors.append("eyewear_style must be one of: none, glasses, sunglasses")
	if (
		typeof(profile["phone_treatment"]) != TYPE_STRING
		or not PHONE_TREATMENTS.has(profile["phone_treatment"])
	):
		errors.append("phone_treatment must be one of: plain, bumper, sticker")
	if errors.is_empty():
		var radius := _geometry_radius(profile)
		if not is_finite(radius):
			errors.append("generated geometry must be finite")
		elif radius > MAX_LOCAL_RADIUS:
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
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(
			_to_canvas(
				center + Vector2(cos(angle) * half_extents.x, sin(angle) * half_extents.y),
				origin,
				forward,
				side
			)
		)
	return points


static func _rect_points(
	center: Vector2,
	half_extents: Vector2,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> PackedVector2Array:
	return PackedVector2Array([
		_to_canvas(center + Vector2(-half_extents.x, -half_extents.y), origin, forward, side),
		_to_canvas(center + Vector2(half_extents.x, -half_extents.y), origin, forward, side),
		_to_canvas(center + Vector2(half_extents.x, half_extents.y), origin, forward, side),
		_to_canvas(center + Vector2(-half_extents.x, half_extents.y), origin, forward, side),
	])


static func _arc_points(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	point_count: int,
	origin: Vector2,
	forward: Vector2,
	side: Vector2
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var weight := float(index) / float(point_count - 1)
		var angle := lerpf(start_angle, end_angle, weight)
		points.append(
			_to_canvas(
				center + Vector2(cos(angle), sin(angle)) * radius,
				origin,
				forward,
				side
			)
		)
	return points


static func draw_owner(
	canvas: CanvasItem,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	gait_phase: float,
	gait_amount: float,
	phone_glow: float,
	phone_state: String
) -> void:
	if (
		not _is_finite_vector(origin)
		or not is_finite(gait_phase)
		or not is_finite(gait_amount)
		or not is_finite(phone_glow)
	):
		return
	var active_profile := profile
	if not validation_errors(active_profile).is_empty():
		active_profile = get_profile(String(PROFILE_IDS[0]))
	var facing := forward
	if not _is_finite_vector(facing) or facing.is_zero_approx():
		facing = Vector2.UP
	else:
		facing = facing.normalized()
	var side := facing.orthogonal()
	var scale: float = active_profile["size_scale"]
	var amount := clampf(gait_amount, 0.0, 1.0)
	var glow := clampf(phone_glow, 0.0, 1.0)
	var body_size: Vector2 = active_profile["body_size"] * scale
	var head_radius: float = active_profile["head_radius"] * scale
	var head_center := Vector2(float(active_profile["head_forward_offset"]) * scale, 0.0)
	var foot_radius: float = active_profile["foot_radius"] * scale
	var foot_spread: float = active_profile["foot_spread"] * scale
	var step_distance: float = active_profile["step_distance"] * scale
	var arm_width: float = active_profile["arm_width"] * scale
	var skin_color: Color = active_profile["skin_color"]
	var shirt_color: Color = active_profile["shirt_color"]
	var pants_color: Color = active_profile["pants_color"]
	var hair_color: Color = active_profile["hair_color"]
	var headwear_color: Color = active_profile["headwear_color"]
	var eyewear_color: Color = active_profile["eyewear_color"]
	var phone_size: Vector2 = active_profile["phone_size"] * scale
	var phone_body_color: Color = active_profile["phone_body_color"]
	var phone_screen_base: Color = active_profile["phone_screen_color"]
	var phone_screen_color := Color(
		phone_screen_base.r,
		phone_screen_base.g,
		phone_screen_base.b,
		phone_screen_base.a * glow
	)
	var phone_accent_color: Color = active_profile["phone_accent_color"]
	var step := sin(gait_phase) * step_distance * amount
	var sway := sin(gait_phase * 0.5) * MAX_SWAY * amount * scale
	var body_center := Vector2(0.0, sway)
	var left_foot := Vector2(step, -foot_spread)
	var right_foot := Vector2(-step, foot_spread)
	var resolved_phone_state := phone_state if phone_state in ["held", "raised"] else "held"
	var phone_forward := (
		PHONE_RAISED_FORWARD if resolved_phone_state == "raised" else PHONE_HELD_FORWARD
	)
	var phone_center := Vector2(phone_forward * scale, 0.0)

	canvas.draw_circle(_to_canvas(left_foot, origin, facing, side), foot_radius, pants_color)
	canvas.draw_circle(_to_canvas(right_foot, origin, facing, side), foot_radius, pants_color)

	match String(active_profile["hair_style"]):
		"long":
			canvas.draw_colored_polygon(
				_ellipse_points(
					head_center - Vector2(head_radius * 0.35, 0.0),
					Vector2(head_radius * 1.15, head_radius * 1.35),
					origin,
					facing,
					side
				),
				hair_color
			)
		"bun":
			canvas.draw_circle(
				_to_canvas(
					head_center - Vector2(head_radius * 1.15, 0.0),
					origin,
					facing,
					side
				),
				head_radius * 0.55,
				hair_color
			)

	canvas.draw_colored_polygon(
		_ellipse_points(body_center, body_size, origin, facing, side),
		shirt_color
	)
	canvas.draw_circle(_to_canvas(head_center, origin, facing, side), head_radius, skin_color)

	match String(active_profile["hair_style"]):
		"short":
			canvas.draw_polyline(
				_arc_points(
					head_center,
					head_radius * 0.95,
					PI * 0.55,
					PI * 1.45,
					10,
					origin,
					facing,
					side
				),
				hair_color,
				maxf(1.0, head_radius * 0.38),
				true
			)
		"long":
			canvas.draw_polyline(
				_arc_points(
					head_center,
					head_radius * 0.92,
					PI * 0.58,
					PI * 1.42,
					10,
					origin,
					facing,
					side
				),
				hair_color,
				maxf(1.0, head_radius * 0.28),
				true
			)
		"bun":
			canvas.draw_polyline(
				_arc_points(
					head_center,
					head_radius * 0.95,
					PI * 0.58,
					PI * 1.42,
					10,
					origin,
					facing,
					side
				),
				hair_color,
				maxf(1.0, head_radius * 0.32),
				true
			)
		"bald_spot":
			canvas.draw_polyline(
				_arc_points(
					head_center,
					head_radius * 0.96,
					PI * 0.45,
					PI * 1.55,
					12,
					origin,
					facing,
					side
				),
				hair_color,
				maxf(1.0, head_radius * 0.42),
				true
			)
			canvas.draw_circle(
				_to_canvas(
					head_center - Vector2(head_radius * 0.72, 0.0),
					origin,
					facing,
					side
				),
				head_radius * 0.25,
				skin_color
			)

	match String(active_profile["headwear_style"]):
		"cap":
			canvas.draw_polyline(
				_arc_points(
					head_center,
					head_radius * 1.08,
					PI * 0.62,
					PI * 1.38,
					10,
					origin,
					facing,
					side
				),
				headwear_color,
				maxf(1.0, head_radius * 0.42),
				true
			)
			canvas.draw_line(
				_to_canvas(
					head_center + Vector2(head_radius * 0.65, -head_radius * 0.45),
					origin,
					facing,
					side
				),
				_to_canvas(
					head_center + Vector2(head_radius * 1.35, -head_radius * 0.12),
					origin,
					facing,
					side
				),
				headwear_color,
				maxf(1.0, 2.2 * scale),
				true
			)
		"beanie":
			canvas.draw_colored_polygon(
				_ellipse_points(
					head_center - Vector2(head_radius * 0.28, 0.0),
					Vector2(head_radius * 0.78, head_radius * 1.04),
					origin,
					facing,
					side
				),
				headwear_color
			)
			canvas.draw_line(
				_to_canvas(
					head_center + Vector2(-head_radius * 0.15, -head_radius),
					origin,
					facing,
					side
				),
				_to_canvas(
					head_center + Vector2(-head_radius * 0.15, head_radius),
					origin,
					facing,
					side
				),
				hair_color,
				maxf(1.0, 2.0 * scale),
				true
			)

	match String(active_profile["eyewear_style"]):
		"glasses":
			for eye_side in [-1.0, 1.0]:
				canvas.draw_arc(
					_to_canvas(
						head_center + Vector2(head_radius * 0.38, head_radius * 0.38 * eye_side),
						origin,
						facing,
						side
					),
					head_radius * 0.25,
					0.0,
					TAU,
					10,
					eyewear_color,
					maxf(1.0, scale),
					true
				)
			canvas.draw_line(
				_to_canvas(head_center + Vector2(head_radius * 0.38, -head_radius * 0.13), origin, facing, side),
				_to_canvas(head_center + Vector2(head_radius * 0.38, head_radius * 0.13), origin, facing, side),
				eyewear_color,
				maxf(1.0, scale),
				true
			)
		"sunglasses":
			for eye_side in [-1.0, 1.0]:
				canvas.draw_circle(
					_to_canvas(
						head_center + Vector2(head_radius * 0.38, head_radius * 0.38 * eye_side),
						origin,
						facing,
						side
					),
					head_radius * 0.25,
					eyewear_color
				)
			canvas.draw_line(
				_to_canvas(head_center + Vector2(head_radius * 0.38, -head_radius * 0.13), origin, facing, side),
				_to_canvas(head_center + Vector2(head_radius * 0.38, head_radius * 0.13), origin, facing, side),
				eyewear_color,
				maxf(1.0, scale),
				true
			)

	for arm_side in [-1.0, 1.0]:
		var arm_start := body_center + Vector2(body_size.x * 0.45, body_size.y * 0.72 * arm_side)
		var arm_end := phone_center + Vector2(-phone_size.y * 0.45, phone_size.x * 0.36 * arm_side)
		canvas.draw_line(
			_to_canvas(arm_start, origin, facing, side),
			_to_canvas(arm_end, origin, facing, side),
			skin_color,
			arm_width,
			true
		)

	var phone_half := Vector2(phone_size.y * 0.5, phone_size.x * 0.5)
	if String(active_profile["phone_treatment"]) == "bumper":
		canvas.draw_colored_polygon(
			_rect_points(
				phone_center,
				phone_half + Vector2(1.5, 1.5) * scale,
				origin,
				facing,
				side
			),
			phone_accent_color
		)
	canvas.draw_colored_polygon(
		_rect_points(phone_center, phone_half, origin, facing, side),
		phone_body_color
	)
	var screen_center := phone_center + Vector2(phone_size.y * 0.08, 0.0)
	var screen_half := Vector2(phone_size.y * 0.27, phone_size.x * 0.32)
	canvas.draw_colored_polygon(
		_rect_points(screen_center, screen_half, origin, facing, side),
		phone_screen_color
	)
	if String(active_profile["phone_treatment"]) == "sticker":
		canvas.draw_circle(
			_to_canvas(
				phone_center - Vector2(phone_size.y * 0.32, 0.0),
				origin,
				facing,
				side
			),
			maxf(1.0, phone_size.x * 0.12),
			phone_accent_color
		)
