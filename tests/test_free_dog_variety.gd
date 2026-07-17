extends SceneTree

var EXPECTED_IDS := PackedStringArray([
	"compact_point_ear",
	"long_low_drop_ear",
	"tall_narrow_rose_ear",
	"stocky_fold_ear",
	"fluffy_curl_tail",
	"shaggy_drop_ear",
])
var REQUIRED_FIELDS := PackedStringArray([
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
])
const REPRESENTATIVE_POSITIONS := [
	Vector2(200.0, -160.0),
	Vector2(640.0, -220.0),
	Vector2(1080.0, -80.0),
]
const Y_LO := -300.0
const Y_HI := -30.0

var failures := 0
var fixtures: Array[Node] = []
var appearance_script: GDScript
var free_dog_script: GDScript


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _script_has_method(script: GDScript, method_name: String) -> bool:
	for method: Dictionary in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false


func _has_property(object: Object, property_name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _contains_fragment(messages: PackedStringArray, fragment: String) -> bool:
	for message: String in messages:
		if message.contains(fragment):
			return true
	return false


func _make_free_dog(
	main: FakeMain,
	player_dog: Node2D,
	spawn_position: Vector2,
	run_setup := true
) -> Node2D:
	var free_dog := Node2D.new()
	free_dog.set_script(free_dog_script)
	free_dog.position = spawn_position
	root.add_child(free_dog)
	free_dog.set_physics_process(false)
	fixtures.append(free_dog)
	if run_setup:
		free_dog.setup(main, player_dog, Y_LO, Y_HI)
	return free_dog


func _test_public_api_and_selection() -> bool:
	var required_methods := [
		"profile_ids",
		"get_profile",
		"profile_id_for_key",
		"profile_for_key",
		"validation_errors",
	]
	var complete := true
	for method_name: String in required_methods:
		var present := _script_has_method(appearance_script, method_name)
		_check(present, "DogAppearance exposes " + method_name)
		complete = complete and present
	if not complete:
		return false
	var constants := appearance_script.get_script_constant_map()
	_check(
		is_equal_approx(float(constants.get("MAX_LOCAL_RADIUS", 0.0)), 40.0),
		"DogAppearance exposes MAX_LOCAL_RADIUS = 40.0"
	)

	var ids: PackedStringArray = appearance_script.call("profile_ids")
	_check(ids == EXPECTED_IDS, "profile IDs retain the exact stable order")
	var unique := {}
	for profile_id: String in ids:
		unique[profile_id] = true
	_check(ids.size() >= 6, "profile list contains at least six IDs")
	_check(unique.size() == ids.size(), "profile IDs are unique")

	var mutated_ids := ids
	mutated_ids[0] = "mutated"
	_check(
		appearance_script.call("profile_ids") == EXPECTED_IDS,
		"profile ID lookup returns an independent array"
	)

	var expected_by_key := {
		0: EXPECTED_IDS[0],
		1: EXPECTED_IDS[1],
		5: EXPECTED_IDS[5],
		6: EXPECTED_IDS[0],
		7: EXPECTED_IDS[1],
		-1: EXPECTED_IDS[5],
		-6: EXPECTED_IDS[0],
		-7: EXPECTED_IDS[5],
	}
	for key: int in expected_by_key:
		var first: String = appearance_script.call("profile_id_for_key", key)
		var second: String = appearance_script.call("profile_id_for_key", key)
		_check(first == String(expected_by_key[key]), "key %d selects the expected ID" % key)
		_check(second == first, "key %d selection is repeatable" % key)

	var count := EXPECTED_IDS.size()
	for key in range(-18, 19):
		_check(
			appearance_script.call("profile_id_for_key", key)
				== appearance_script.call("profile_id_for_key", key + count),
			"selection cycles by profile count for key %d" % key
		)
	return true


func _test_profiles_validation_and_variety() -> void:
	var ear_styles := {}
	var tail_styles := {}
	var marking_styles := {}
	var coat_colors := {}
	var silhouettes := {}
	for profile_id: String in EXPECTED_IDS:
		var profile: Dictionary = appearance_script.call("get_profile", profile_id)
		_check(profile.keys().size() == REQUIRED_FIELDS.size(), profile_id + " uses only the exact schema")
		for field: String in REQUIRED_FIELDS:
			_check(profile.has(field), profile_id + " has field " + field)
		_check(String(profile.get("id", "")) == profile_id, profile_id + " matches its catalog key")
		var errors: PackedStringArray = appearance_script.call("validation_errors", profile)
		_check(errors.is_empty(), profile_id + " validates: " + ", ".join(errors))
		ear_styles[String(profile.get("ear_style", ""))] = true
		tail_styles[String(profile.get("tail_style", ""))] = true
		marking_styles[String(profile.get("marking_style", ""))] = true
		coat_colors[profile.get("base_color")] = true
		var body_size: Vector2 = profile.get("body_size", Vector2.ZERO)
		var size_scale: float = profile.get("size_scale", 0.0)
		silhouettes["%.2f:%.2f:%.2f" % [body_size.x, body_size.y, size_scale]] = true

		var first: Dictionary = appearance_script.call("get_profile", profile_id)
		var second: Dictionary = appearance_script.call("get_profile", profile_id)
		_check(first == second, profile_id + " repeated lookups are value-equal")
		first["name"] = "mutated"
		first["body_size"] = Vector2(999.0, 999.0)
		_check(first != second, profile_id + " lookups are independently mutable")
		_check(
			appearance_script.call("get_profile", profile_id) == second,
			profile_id + " canonical data is protected from caller mutation"
		)

	_check(ear_styles.size() >= 3, "profiles exercise at least three ear styles")
	_check(tail_styles.size() >= 3, "profiles exercise at least three tail styles")
	_check(marking_styles.size() >= 4, "profiles exercise all four marking styles")
	_check(coat_colors.size() >= 4, "profiles use at least four base-coat colors")
	_check(silhouettes.size() >= 3, "profiles use at least three silhouettes")
	_check(ear_styles.has("point"), "point ears are represented")
	_check(ear_styles.has("drop"), "drop ears are represented")
	_check(ear_styles.has("rose"), "rose ears are represented")
	_check(ear_styles.has("fold"), "fold ears are represented")
	_check(tail_styles.has("straight"), "straight tails are represented")
	_check(tail_styles.has("whip"), "whip tails are represented")
	_check(tail_styles.has("curl"), "curl tails are represented")
	_check(tail_styles.has("plume"), "plume tails are represented")
	_check(marking_styles.has("solid"), "solid coats are represented")
	_check(marking_styles.has("patch"), "patched coats are represented")
	_check(marking_styles.has("blaze_points"), "blazed/pointed coats are represented")
	_check(marking_styles.has("brindle"), "brindled coats are represented")

	var fallback: Dictionary = appearance_script.call("get_profile", "not_a_profile")
	_check(fallback["id"] == EXPECTED_IDS[0], "unknown IDs fall back to the first profile")
	var fallback_again: Dictionary = appearance_script.call("get_profile", "not_a_profile")
	fallback["name"] = "mutated"
	_check(fallback_again["name"] != "mutated", "fallback profiles are defensive copies")

	var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	invalid["id"] = ""
	invalid["size_scale"] = 0.0
	invalid["body_size"] = Vector2(INF, -1.0)
	invalid["ear_style"] = "bat"
	invalid["tail_style"] = "stub"
	invalid["marking_style"] = "spots"
	invalid["base_color"] = Color(2.0, -1.0, NAN, 1.0)
	invalid["unexpected"] = true
	var invalid_snapshot := invalid.duplicate(true)
	var invalid_errors: PackedStringArray = appearance_script.call("validation_errors", invalid)
	_check(invalid_errors.size() >= 8, "malformed profiles return multiple validation errors")
	_check(invalid == invalid_snapshot, "validation does not mutate malformed input")

	var missing_errors: PackedStringArray = appearance_script.call("validation_errors", {})
	_check(missing_errors.size() == REQUIRED_FIELDS.size(), "missing schema fields are all reported")

	var oversized: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	oversized["body_size"] = Vector2(100.0, 100.0)
	var oversized_errors: PackedStringArray = appearance_script.call("validation_errors", oversized)
	_check(
		_contains_fragment(oversized_errors, "MAX_LOCAL_RADIUS"),
		"validation rejects geometry outside MAX_LOCAL_RADIUS"
	)


func _test_appearance_rng_isolation() -> void:
	seed(170717)
	var expected_next := randf()
	seed(170717)
	var ids: PackedStringArray = appearance_script.call("profile_ids")
	var selected_id: String = appearance_script.call("profile_id_for_key", -17)
	var selected: Dictionary = appearance_script.call("profile_for_key", 31)
	var looked_up: Dictionary = appearance_script.call("get_profile", selected_id)
	var errors: PackedStringArray = appearance_script.call("validation_errors", looked_up)
	var actual_next := randf()
	_check(not ids.is_empty() and not selected.is_empty(), "RNG fixture exercises selection and lookup")
	_check(errors.is_empty(), "RNG fixture exercises validation")
	_check(
		is_equal_approx(actual_next, expected_next),
		"selection, lookup, and validation preserve global RNG state"
	)


func _test_free_dog_setup_and_lifecycle(main: FakeMain, player_dog: Node2D) -> bool:
	var probe := _make_free_dog(main, player_dog, REPRESENTATIVE_POSITIONS[0], false)
	var has_profile := _has_property(probe, "appearance_profile")
	_check(has_profile, "freedog stores appearance_profile")
	if not has_profile:
		return false

	seed(271828)
	var expected_next := randf()
	seed(271828)
	probe.setup(main, player_dog, Y_LO, Y_HI)
	var actual_next := randf()
	_check(
		is_equal_approx(actual_next, expected_next),
		"freedog setup preserves global RNG state"
	)
	_check(probe.is_in_group("freedogs"), "setup joins freedogs")
	_check(probe.main == main, "setup retains the main reference")
	_check(probe.my_dog == player_dog, "setup retains the player-dog reference")
	_check(is_equal_approx(probe.lo, Y_LO), "setup retains the lower bound")
	_check(is_equal_approx(probe.hi, Y_HI), "setup retains the upper bound")

	var duplicate := _make_free_dog(main, player_dog, REPRESENTATIVE_POSITIONS[0])
	_check(
		probe.appearance_profile == duplicate.appearance_profile,
		"identical setup inputs produce equal profiles"
	)
	_check(
		is_equal_approx(probe.seed_o, duplicate.seed_o),
		"identical setup inputs produce equal animation offsets"
	)

	var selected_ids := {}
	for spawn_position: Vector2 in REPRESENTATIVE_POSITIONS:
		var first := _make_free_dog(main, player_dog, spawn_position)
		var second := _make_free_dog(main, player_dog, spawn_position)
		_check(
			first.appearance_profile == second.appearance_profile,
			"position %s produces a repeatable profile" % spawn_position
		)
		_check(
			is_equal_approx(first.seed_o, second.seed_o),
			"position %s produces a repeatable animation offset" % spawn_position
		)
		selected_ids[String(first.appearance_profile.get("id", ""))] = true
	_check(selected_ids.size() > 1, "representative spawn inputs select more than one profile")

	probe.position = Vector2(500.0, -100.0)
	probe.vel = Vector2(120.0, 0.0)
	probe.wander_t = 1.0
	main.frozen = true
	var before := probe.position
	probe._physics_process(0.1)
	_check(probe.position.is_equal_approx(before), "frozen free dogs remain stationary")

	main.frozen = false
	main.phase = "home"
	probe._physics_process(0.1)
	_check(probe.position.is_equal_approx(before), "free dogs remain stationary outside freedom")

	main.phase = "freedom"
	probe._physics_process(0.1)
	_check(
		probe.position.is_equal_approx(before + Vector2(12.0, 0.0)),
		"active free dogs retain fixed-velocity movement"
	)

	probe.position = Vector2(1188.0, 99.0)
	probe.vel = Vector2(100.0, 100.0)
	probe.wander_t = 1.0
	probe._physics_process(0.1)
	_check(is_equal_approx(probe.position.x, 1190.0), "active movement keeps the x clamp")
	_check(is_equal_approx(probe.position.y, Y_HI), "active movement keeps the y clamp")
	return true


func _test_render_smoke(main: FakeMain, player_dog: Node2D) -> void:
	var free_dog := _make_free_dog(main, player_dog, Vector2(400.0, -120.0))
	player_dog.position = free_dog.position
	for profile_id: String in EXPECTED_IDS:
		free_dog.appearance_profile = appearance_script.call("get_profile", profile_id)
		free_dog.queue_redraw()
		await process_frame
	var invalid: Dictionary = appearance_script.call("get_profile", EXPECTED_IDS[0])
	invalid["tail_style"] = "invalid"
	free_dog.appearance_profile = invalid
	free_dog.queue_redraw()
	await process_frame
	_check(true, "all profiles draw with coincident player position")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_free_dog_variety: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_free_dog_variety: OK")
		quit(0)


func _run() -> void:
	appearance_script = load("res://dog_appearance.gd") as GDScript
	if appearance_script == null:
		_check(false, "dog_appearance.gd loads")
		_finish()
		return
	free_dog_script = load("res://freedog.gd") as GDScript
	if free_dog_script == null:
		_check(false, "freedog.gd loads")
		_finish()
		return
	if not _test_public_api_and_selection():
		_finish()
		return

	_test_profiles_validation_and_variety()
	_test_appearance_rng_isolation()
	var has_renderer := _script_has_method(appearance_script, "draw_dog")
	_check(has_renderer, "DogAppearance exposes draw_dog")
	if not has_renderer:
		_finish()
		return

	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	var player_dog := Node2D.new()
	player_dog.visible = false
	root.add_child(player_dog)
	fixtures.append(player_dog)
	if _test_free_dog_setup_and_lifecycle(main, player_dog):
		await _test_render_smoke(main, player_dog)
	_finish()


func _initialize() -> void:
	call_deferred("_run")
