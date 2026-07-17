extends SceneTree

var EXPECTED_IDS := PackedStringArray([
	"compact_short_cap",
	"tall_long_glasses",
	"broad_bun_sunglasses",
	"medium_bald_spot_glasses",
	"narrow_short_beanie",
	"rounded_long_cap",
])
var REQUIRED_FIELDS := PackedStringArray([
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
])
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
const EXPECTED_PROFILES := {
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

var failures := 0
var appearance_script: GDScript


class OwnerCanvas:
	extends Node2D

	var appearance_script: GDScript
	var profile: Dictionary
	var origin := Vector2(64.0, 64.0)
	var forward := Vector2.RIGHT
	var gait_phase := 0.4
	var gait_amount := 1.0
	var phone_glow := 1.0
	var phone_state := "held"

	func _draw() -> void:
		appearance_script.call(
			"draw_owner",
			self,
			profile,
			origin,
			forward,
			gait_phase,
			gait_amount,
			phone_glow,
			phone_state
		)


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _contains(messages: PackedStringArray, fragment: String) -> bool:
	for message: String in messages:
		if message.contains(fragment):
			return true
	return false


func _method_info(method_name: String) -> Dictionary:
	for method: Dictionary in appearance_script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return method
	return {}


func _assert_signature(
	method_name: String,
	argument_names: PackedStringArray,
	argument_types: PackedInt32Array,
	return_type: int
) -> void:
	var info := _method_info(method_name)
	_check(not info.is_empty(), "HumanAppearance exposes " + method_name)
	if info.is_empty():
		return
	var args: Array = info.get("args", [])
	_check(args.size() == argument_names.size(), method_name + " argument count is exact")
	for index in range(mini(args.size(), argument_names.size())):
		var argument: Dictionary = args[index]
		_check(
			String(argument.get("name", "")) == argument_names[index],
			method_name + " argument %d name is exact" % index
		)
		_check(
			int(argument.get("type", TYPE_NIL)) == argument_types[index],
			method_name + " argument %d type is exact" % index
		)
	var return_info: Dictionary = info.get("return", {})
	_check(int(return_info.get("type", TYPE_NIL)) == return_type, method_name + " return type is exact")


func _geometry_radius(profile: Dictionary) -> float:
	var body_extent: float = (profile["body_size"] as Vector2).length() + 1.5
	var head_extent: float = (
		float(profile["head_forward_offset"])
		+ float(profile["head_radius"]) * 2.35
		+ 3.0
	)
	var feet_extent := Vector2(
		float(profile["step_distance"]) + float(profile["foot_radius"]),
		float(profile["foot_spread"]) + float(profile["foot_radius"])
	).length()
	var phone_size: Vector2 = profile["phone_size"]
	var phone_extent := (
		Vector2(30.0 + phone_size.y * 0.5, phone_size.x * 0.5).length()
		+ 3.0
	)
	return maxf(body_extent, maxf(head_extent, maxf(feet_extent, phone_extent))) * float(
		profile["size_scale"]
	)


func _render_owner(
	profile: Dictionary,
	forward := Vector2.RIGHT,
	gait_phase := 0.4,
	gait_amount := 1.0,
	phone_glow := 1.0,
	phone_state := "held",
	origin := Vector2(64.0, 64.0)
) -> Image:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	var canvas := OwnerCanvas.new()
	canvas.appearance_script = appearance_script
	canvas.profile = profile
	canvas.origin = origin
	canvas.forward = forward
	canvas.gait_phase = gait_phase
	canvas.gait_amount = gait_amount
	canvas.phone_glow = phone_glow
	canvas.phone_state = phone_state
	viewport.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	viewport.free()
	return image


func _opaque_pixels(image: Image) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.02:
				count += 1
	return count


func _color_near(actual: Color, expected: Color, tolerance := 0.08) -> bool:
	return (
		absf(actual.r - expected.r) <= tolerance
		and absf(actual.g - expected.g) <= tolerance
		and absf(actual.b - expected.b) <= tolerance
		and absf(actual.a - expected.a) <= tolerance
	)


func _phone_region_contains(image: Image, profile: Dictionary, expected: Color) -> bool:
	var scale: float = profile["size_scale"]
	var phone_size: Vector2 = profile["phone_size"] * scale
	var center := Vector2(64.0 + 24.0 * scale, 64.0)
	var left := maxi(0, floori(center.x - phone_size.y * 0.5 - 2.0))
	var right := mini(image.get_width() - 1, ceili(center.x + phone_size.y * 0.5 + 2.0))
	var top := maxi(0, floori(center.y - phone_size.x * 0.5 - 2.0))
	var bottom := mini(image.get_height() - 1, ceili(center.y + phone_size.x * 0.5 + 2.0))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if _color_near(image.get_pixel(x, y), expected):
				return true
	return false


func _test_exact_api() -> bool:
	var constants := appearance_script.get_script_constant_map()
	_check(
		is_equal_approx(float(constants.get("MAX_LOCAL_RADIUS", 0.0)), 48.0),
		"MAX_LOCAL_RADIUS is exactly 48.0"
	)
	_assert_signature("profile_ids", PackedStringArray(), PackedInt32Array(), TYPE_PACKED_STRING_ARRAY)
	_assert_signature(
		"get_profile",
		PackedStringArray(["profile_id"]),
		PackedInt32Array([TYPE_STRING]),
		TYPE_DICTIONARY
	)
	_assert_signature(
		"profile_id_for_key",
		PackedStringArray(["key"]),
		PackedInt32Array([TYPE_INT]),
		TYPE_STRING
	)
	_assert_signature(
		"profile_for_key",
		PackedStringArray(["key"]),
		PackedInt32Array([TYPE_INT]),
		TYPE_DICTIONARY
	)
	_assert_signature(
		"validation_errors",
		PackedStringArray(["profile"]),
		PackedInt32Array([TYPE_DICTIONARY]),
		TYPE_PACKED_STRING_ARRAY
	)
	_assert_signature(
		"draw_owner",
		PackedStringArray([
			"canvas",
			"profile",
			"origin",
			"forward",
			"gait_phase",
			"gait_amount",
			"phone_glow",
			"phone_state",
		]),
		PackedInt32Array([
			TYPE_OBJECT,
			TYPE_DICTIONARY,
			TYPE_VECTOR2,
			TYPE_VECTOR2,
			TYPE_FLOAT,
			TYPE_FLOAT,
			TYPE_FLOAT,
			TYPE_STRING,
		]),
		TYPE_NIL
	)
	var public_methods := PackedStringArray()
	for method: Dictionary in appearance_script.get_script_method_list():
		var method_name := String(method.get("name", ""))
		if not method_name.begins_with("_"):
			public_methods.append(method_name)
	public_methods.sort()
	var expected_public := PackedStringArray([
		"draw_owner",
		"get_profile",
		"profile_for_key",
		"profile_id_for_key",
		"profile_ids",
		"validation_errors",
	])
	_check(public_methods == expected_public, "public method surface is exact")
	return failures == 0


func _test_catalog_selection_and_defensive_data() -> void:
	var ids: PackedStringArray = appearance_script.call("profile_ids")
	_check(ids == EXPECTED_IDS, "profile IDs retain exact stable order")
	var unique := {}
	for profile_id: String in ids:
		unique[profile_id] = true
	_check(unique.size() == EXPECTED_IDS.size(), "profile IDs are unique")
	ids[0] = "mutated"
	_check(appearance_script.call("profile_ids") == EXPECTED_IDS, "profile_ids is defensive")
	var expected_keys := {
		0: "compact_short_cap",
		1: "tall_long_glasses",
		5: "rounded_long_cap",
		6: "compact_short_cap",
		7: "tall_long_glasses",
		-1: "rounded_long_cap",
		-6: "compact_short_cap",
		-7: "rounded_long_cap",
	}
	for key: int in expected_keys:
		_check(
			String(appearance_script.call("profile_id_for_key", key)) == expected_keys[key],
			"key %d selects exact profile" % key
		)
	for key in range(-24, 25):
		_check(
			appearance_script.call("profile_id_for_key", key)
				== appearance_script.call("profile_id_for_key", key + EXPECTED_IDS.size()),
			"selection cycles for key %d" % key
		)
	for profile_id: String in EXPECTED_IDS:
		var profile: Dictionary = appearance_script.call("get_profile", profile_id)
		_check(profile == EXPECTED_PROFILES[profile_id], profile_id + " exact canonical values")
		_check(profile.keys().size() == REQUIRED_FIELDS.size(), profile_id + " exact schema size")
		for field: String in REQUIRED_FIELDS:
			_check(profile.has(field), profile_id + " has " + field)
		_check(String(profile["id"]) == profile_id, profile_id + " ID matches catalog key")
		var second: Dictionary = appearance_script.call("get_profile", profile_id)
		profile["name"] = "mutated"
		profile["body_size"] = Vector2(999.0, 999.0)
		_check(second == EXPECTED_PROFILES[profile_id], profile_id + " lookup is deeply defensive")
		_check(
			appearance_script.call("profile_for_key", EXPECTED_IDS.find(profile_id))
				== EXPECTED_PROFILES[profile_id],
			profile_id + " profile_for_key returns canonical value"
		)
	var unknown: Dictionary = appearance_script.call("get_profile", "unknown")
	_check(unknown == EXPECTED_PROFILES[EXPECTED_IDS[0]], "unknown ID falls back to first profile")
	unknown["name"] = "mutated"
	_check(
		appearance_script.call("get_profile", "unknown") == EXPECTED_PROFILES[EXPECTED_IDS[0]],
		"unknown fallback is defensive"
	)


func _test_validation_and_variety() -> void:
	var hair_styles := {}
	var headwear_styles := {}
	var eyewear_styles := {}
	var phone_treatments := {}
	var shirt_colors := {}
	var skin_colors := {}
	var proportions := {}
	for profile_id: String in EXPECTED_IDS:
		var profile: Dictionary = appearance_script.call("get_profile", profile_id)
		var errors: PackedStringArray = appearance_script.call("validation_errors", profile)
		_check(errors.is_empty(), profile_id + " validates: " + ", ".join(errors))
		_check(_geometry_radius(profile) <= 48.0, profile_id + " fits MAX_LOCAL_RADIUS")
		hair_styles[String(profile["hair_style"])] = true
		headwear_styles[String(profile["headwear_style"])] = true
		eyewear_styles[String(profile["eyewear_style"])] = true
		phone_treatments[String(profile["phone_treatment"])] = true
		shirt_colors[profile["shirt_color"]] = true
		skin_colors[profile["skin_color"]] = true
		var body_size: Vector2 = profile["body_size"]
		proportions["%.2f:%.2f" % [body_size.x, body_size.y]] = true
	_check(hair_styles.keys().size() == 4, "all four hair branches are represented")
	_check(headwear_styles.keys().size() == 3, "all three headwear branches are represented")
	_check(eyewear_styles.keys().size() == 3, "all three eyewear branches are represented")
	_check(phone_treatments.keys().size() == 3, "all three phone branches are represented")
	_check(shirt_colors.size() >= 4, "at least four shirt colors are represented")
	_check(skin_colors.size() >= 4, "at least four skin colors are represented")
	_check(proportions.size() >= 3, "at least three body proportions are represented")

	var missing_errors: PackedStringArray = appearance_script.call("validation_errors", {})
	_check(missing_errors.size() == REQUIRED_FIELDS.size(), "all missing fields are reported")
	var extra: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	extra["unexpected"] = true
	_check(
		_contains(appearance_script.call("validation_errors", extra), "unexpected field"),
		"unknown fields are rejected"
	)
	for field: String in ["id", "name"]:
		var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
		invalid[field] = ""
		_check(
			_contains(appearance_script.call("validation_errors", invalid), field),
			field + " rejects empty strings"
		)
	for field: String in POSITIVE_FLOAT_FIELDS:
		for invalid_value in [0.0, -1.0, INF, NAN, 1]:
			var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
			invalid[field] = invalid_value
			_check(
				not appearance_script.call("validation_errors", invalid).is_empty(),
				field + " rejects invalid scalar"
			)
	for field: String in POSITIVE_VECTOR_FIELDS:
		for invalid_value in [Vector2.ZERO, Vector2(INF, 1.0), Vector2(1.0, NAN), "bad"]:
			var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
			invalid[field] = invalid_value
			_check(
				not appearance_script.call("validation_errors", invalid).is_empty(),
				field + " rejects invalid vector"
			)
	for field: String in COLOR_FIELDS:
		for invalid_value in [Color(-1.0, 0.0, 0.0), Color(0.0, 2.0, 0.0), Color(NAN, 0.0, 0.0), "bad"]:
			var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
			invalid[field] = invalid_value
			_check(
				not appearance_script.call("validation_errors", invalid).is_empty(),
				field + " rejects malformed color"
			)
	for enum_case in [
		["hair_style", "mohawk"],
		["headwear_style", "helmet"],
		["eyewear_style", "monocle"],
		["phone_treatment", "wallet"],
	]:
		var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
		invalid[enum_case[0]] = enum_case[1]
		_check(
			not appearance_script.call("validation_errors", invalid).is_empty(),
			String(enum_case[0]) + " rejects unsupported enum"
		)
	var oversized: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	oversized["phone_size"] = Vector2(100.0, 100.0)
	_check(
		_contains(appearance_script.call("validation_errors", oversized), "MAX_LOCAL_RADIUS"),
		"oversized geometry is rejected"
	)
	var malformed: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	malformed["id"] = ""
	malformed["body_size"] = Vector2(INF, -1.0)
	malformed["arm_width"] = NAN
	malformed["skin_color"] = Color(2.0, -1.0, NAN, 1.0)
	malformed["hair_style"] = "invalid"
	malformed["extra"] = true
	var snapshot := malformed.duplicate(true)
	var malformed_errors: PackedStringArray = appearance_script.call("validation_errors", malformed)
	_check(malformed_errors.size() >= 6, "validation reports multiple safely detectable errors")
	_check(
		var_to_bytes(malformed) == var_to_bytes(snapshot),
		"validation never mutates malformed input"
	)


func _test_rng_isolation() -> void:
	seed(170717)
	var expected_next := randf()
	seed(170717)
	var ids: PackedStringArray = appearance_script.call("profile_ids")
	var selected_id: String = appearance_script.call("profile_id_for_key", -17)
	var selected: Dictionary = appearance_script.call("profile_for_key", 31)
	var looked_up: Dictionary = appearance_script.call("get_profile", selected_id)
	var errors: PackedStringArray = appearance_script.call("validation_errors", looked_up)
	_check(not ids.is_empty() and not selected.is_empty() and errors.is_empty(), "RNG fixture exercises pure API")
	var actual_next := randf()
	_check(is_equal_approx(actual_next, expected_next), "catalog API preserves global RNG")


func _test_renderer() -> void:
	seed(98765)
	var expected_next := randf()
	seed(98765)
	for profile_id: String in EXPECTED_IDS:
		var profile: Dictionary = appearance_script.call("get_profile", profile_id)
		var snapshot := profile.duplicate(true)
		for state in ["held", "raised"]:
			var image: Image = await _render_owner(profile, Vector2.RIGHT, 0.4, 1.0, 1.0, state)
			_check(_opaque_pixels(image) > 0, profile_id + " draws in " + state)
		_check(profile == snapshot, profile_id + " render does not mutate profile")
		var held_image: Image = await _render_owner(profile)
		_check(
			_phone_region_contains(held_image, profile, profile["phone_body_color"]),
			profile_id + " renders a phone body"
		)
		_check(
			_phone_region_contains(held_image, profile, profile["phone_screen_color"]),
			profile_id + " renders a phone screen"
		)
	var actual_next := randf()
	_check(is_equal_approx(actual_next, expected_next), "rendering preserves global RNG")

	var base: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	_check(_opaque_pixels(await _render_owner(base, Vector2.ZERO)) > 0, "zero forward falls back to Vector2.UP")
	_check(_opaque_pixels(await _render_owner(base, Vector2(NAN, INF))) > 0, "non-finite forward falls back to Vector2.UP")
	_check(_opaque_pixels(await _render_owner(base, Vector2.RIGHT, 0.0, 1.0, 1.0, "unknown")) > 0, "unknown phone state renders held")
	var malformed := base.duplicate(true)
	malformed["body_size"] = Vector2(NAN, -1.0)
	var malformed_snapshot := malformed.duplicate(true)
	_check(_opaque_pixels(await _render_owner(malformed)) > 0, "malformed profile draws defensive fallback")
	_check(malformed == malformed_snapshot, "fallback drawing does not mutate malformed profile")
	for invalid_case in [
		[Vector2(NAN, 64.0), 0.0, 1.0, 1.0],
		[Vector2(64.0, 64.0), NAN, 1.0, 1.0],
		[Vector2(64.0, 64.0), 0.0, INF, 1.0],
		[Vector2(64.0, 64.0), 0.0, 1.0, NAN],
	]:
		var image: Image = await _render_owner(
			base,
			Vector2.RIGHT,
			invalid_case[1],
			invalid_case[2],
			invalid_case[3],
			"held",
			invalid_case[0]
		)
		_check(_opaque_pixels(image) == 0, "non-finite draw input emits no geometry")
	var glow_zero: Image = await _render_owner(base, Vector2.RIGHT, 0.0, 0.0, 0.0)
	_check(
		_phone_region_contains(glow_zero, base, base["phone_body_color"]),
		"phone body remains visible at zero glow"
	)


func _finish() -> void:
	if failures > 0:
		print("test_human_appearance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_human_appearance: OK")
		quit(0)


func _run() -> void:
	appearance_script = load("res://human_appearance.gd") as GDScript
	if appearance_script == null:
		_check(false, "human_appearance.gd loads")
		_finish()
		return
	if not _test_exact_api():
		_finish()
		return
	_test_catalog_selection_and_defensive_data()
	_test_validation_and_variety()
	_test_rng_isolation()
	await _test_renderer()
	_finish()


func _initialize() -> void:
	call_deferred("_run")
