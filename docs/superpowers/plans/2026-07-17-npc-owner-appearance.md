# Reusable NPC Owner Appearance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add six reusable, neutral procedural appearance profiles for generic NPC pair owners while preserving exact pair RNG cadence, profile and node identity, phones, dog rendering, and every gameplay contract.

**Architecture:** Introduce `human_appearance.gd` as a stateless `RefCounted` catalog, validator, signed-key selector, and procedural `CanvasItem` renderer. `otherpair.gd` consumes the existing raw third setup draw as the owner profile key, retains one defensive profile dictionary for the pair lifetime, derives compatibility `owner_col`, and delegates owner drawing from the existing pair parent; `human.gd` and the real `npc_owner` node remain untouched. A module-level real-renderer regression goes RED before the module exists, and a separate real-pair regression goes RED before pair integration.

**Tech Stack:** Godot 4.7, GDScript, GL Compatibility renderer, procedural `CanvasItem` primitives, `SubViewport` pixel assertions, headless `SceneTree` tests, PowerShell, Git, GitHub Actions.

## Global Constraints

- The approved design at `docs/superpowers/specs/2026-07-17-npc-owner-appearance-design.md` is the source of truth. Stop and reconcile any implementation idea that conflicts with it.
- Isolated implementation is exactly four files: create `human_appearance.gd`, modify `otherpair.gd`, create `tests/test_human_appearance.gd`, and create `tests/test_pair_owner_appearance.gd`.
- The user’s abbreviated boundary omitted `tests/test_human_appearance.gd`; the approved spec explicitly requires that file and strict module-level RED is impossible without it. The four-file approved spec boundary governs execution.
- Until both review stages pass, do not modify `.github/workflows/ci.yml`, `CHANGELOG.md`, `HANDOVER.md`, `PROJECT.md`, `AGENTS.md`, any specification or plan, any existing test, or any other production file.
- The current `tests/test_pair_dog_appearance.gd:13-17,121,137` still asserts the obsolete three-color owner palette. That assertion cannot coexist with both exact canonical shirt colors and `owner_col == owner_appearance_profile["shirt_color"]`. Preserve the test unchanged through the two-stage isolated review, require reviewers to acknowledge this source conflict, then remove only that obsolete owner assertion in the separate integration task. Keep its raw third-draw consumption and every dog/RNG/lifecycle assertion.
- Preserve unrelated work. Never stage, revert, overwrite, or format a file outside the active task’s file list.
- Use Godot 4.7 GDScript only. Keep GL Compatibility and web-export compatibility. Add no assets, scenes, resources, textures, SVGs, fonts, plugins, dependencies, or production-art replacements.
- `HumanAppearance` creates no nodes, stores no mutable runtime state, calls no RNG API, creates no `RandomNumberGenerator`, reads no clock, and knows nothing about main, player-owner code, pair states, movement, routing, leashes, tangles, groups, spawning, or cleanup.
- `HumanAppearance` public API is exactly `MAX_LOCAL_RADIUS` plus `profile_ids`, `get_profile`, `profile_id_for_key`, `profile_for_key`, `validation_errors`, and `draw_owner` with the approved types and argument order. All helpers are private.
- Stable profile IDs and order are exactly `compact_short_cap`, `tall_long_glasses`, `broad_bun_sunglasses`, `medium_bald_spot_glasses`, `narrow_short_beanie`, `rounded_long_cap`.
- Canonical dictionaries contain exactly the approved 24 fields, types, and values. Existing IDs must never be renamed, reordered, or repurposed.
- Selection uses `((key % profile_count) + profile_count) % profile_count`; lookups and selections return deep defensive copies and consume no randomness.
- Validation is non-mutating, reports every safely detectable error, rejects missing/extra fields, wrong types, empty identity strings, non-finite or non-positive geometry, invalid colors/enums, unsafe primitives, and geometry above `MAX_LOCAL_RADIUS == 48.0`.
- Rendering validates profiles, falls back to a fresh `compact_short_cap`, never mutates caller data, normalizes finite non-zero facing, uses `Vector2.UP` for zero/non-finite facing, and emits no draw calls for non-finite origin or animation scalars.
- Every canonical owner visibly holds a phone. `held` uses 24 local forward pixels; `raised` uses 30. Unknown phone state renders as `held`. Phone glow is clamped to `[0.0, 1.0]`; the case remains visible at zero glow.
- Every visual schema field except `id` and `name` affects a supported renderer branch. Exercise every hair, headwear, eyewear, and phone-treatment branch.
- Keep `otherpair.gd::setup(m: Node2D, mine: Node2D, poles: Array[Vector2], start: Vector2, direction: Vector2) -> void` unchanged.
- Pair setup consumes exactly four initial global draws in this order: velocity `randf_range(58.0, 82.0)`, `seed_o` `randf()`, raw owner `randi()`, raw dog `randi()`. No draw is inserted, removed, moved, repeated, or hidden.
- The raw third draw selects `owner_appearance_profile`; `owner_col` remains and equals its `shirt_color`. The raw fourth draw and existing `DogAppearance` integration remain unchanged.
- `owner_appearance_profile` and existing dog `appearance_profile` are distinct fields. The same owner dictionary object and ID persist through `WALKING`, `ARRIVING`, `PARKED`, `RECALLING`, `DEPARTING`, resumed `WALKING`, `initialize_parked_departure`, and home interruption.
- The pair, `npc_owner`, `npc_dog`, and `leash` node identities, parenting, groups, collision, leash endpoint roles, and positions remain gameplay-owned by `otherpair.gd`.
- Both owner and dog render on the pair parent. `npc_owner` remains the real owner/leash endpoint. Keep the dog-facing, bob, wag, and `DogAppearanceScript.draw_dog(...)` flow unchanged except mechanically moving the existing `t` local.
- Do not modify `human.gd`, the player owner, `dog_appearance.gd`, `main.gd`, `leash.gd`, behavior, movement, stats, collisions, difficulty, scoring, creator UI, save data, migrations, persistence, unlocks, or progression.
- Use no named real people, gender labels, demographic claims, or emoji.
- Do not commit the isolated implementation until stage-one spec review and stage-two quality review both pass and explicit implementation-checkpoint authorization is received.
- CI, changelog, and handover integration is a separate task after the authorized implementation checkpoint.

## Exact File Map

- Create `human_appearance.gd`: exact six-profile catalog, defensive API, positive-modulo selection, comprehensive validation, finite radius calculation, coordinate helpers, and complete owner/phone renderer.
- Modify `otherpair.gd:8-10,40-45,63-83,464-484`: preload `HumanAppearance`, store one owner profile, reuse the third draw, derive `owner_col`, and delegate parent-Canvas owner drawing.
- Create `tests/test_human_appearance.gd`: module API/schema/value/selection/validation/RNG/render/pixel regression using the real script and offscreen renderer.
- Create `tests/test_pair_owner_appearance.gd`: real `otherpair.gd`, `human_appearance.gd`, `dog_appearance.gd`, and `leash.gd` regression for exact RNG, compatibility colors, lifecycle dictionary identity, node/endpoints, phones, zero velocity, parent rendering, and RNG isolation.
- Modify `tests/test_pair_dog_appearance.gd:13-17,121,137` only after both reviews and the implementation checkpoint: remove its obsolete owner-palette constant/assertion while retaining the consumed raw third draw and all dog-focused contracts.
- Modify `.github/workflows/ci.yml:65-68` only after both reviews and the implementation checkpoint: add the two new focused tests before level smokes.
- Modify `CHANGELOG.md:5` only during integration: add the append-only owner appearance entry.
- Modify `HANDOVER.md:52-82,87-124,125-230` only during integration: record architecture, branch/commit/PR state, exact evidence, outstanding manual visual acceptance, residual risks, and next priorities without stale claims.

---

### Task 1: Establish Module-Level RED

**Files:**
- Create: `tests/test_human_appearance.gd`
- Inspect only: `docs/superpowers/specs/2026-07-17-npc-owner-appearance-design.md`

**Interfaces:**
- Consumes: the approved `HumanAppearance` signatures, schema, values, renderer inputs, and radius formula.
- Produces: a real-script `SceneTree` regression that exits `1` with `FAIL:` lines and exits `0` only after `test_human_appearance: OK`.
- Produces: offscreen real-renderer assertions; it does not duplicate a fake renderer or selection implementation.

- [ ] **Step 1: Create an isolated feature branch and confirm baseline ownership**

Run:

```powershell
git status --short
git log -3 --oneline --decorate
git switch -c npc-owner-appearances
git diff -- otherpair.gd
```

Expected: the starting tree is clean, `HEAD` is the approved design/plan baseline, the new branch is `npc-owner-appearances`, and `otherpair.gd` has no diff. If the tree is not clean or the caller changed, preserve the work and stop for coordination.

- [ ] **Step 2: Write the complete failing module test**

Create `tests/test_human_appearance.gd` with exactly:

```gdscript
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
	_check(malformed == snapshot, "validation never mutates malformed input")


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
```

- [ ] **Step 3: Run the test and verify strict RED before the module exists**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_human_appearance.gd
```

Expected: exit code `1`, a missing-resource diagnostic for `res://human_appearance.gd`, and:

```text
FAIL: human_appearance.gd loads
test_human_appearance: 1 FAILURES
```

The test file itself must parse. Do not create a stub module before recording this RED result.

- [ ] **Step 4: Confirm the isolated diff**

Run:

```powershell
git status --short
git diff --check -- tests/test_human_appearance.gd
```

Expected: only `?? tests/test_human_appearance.gd`; the check exits `0`. Do not stage or commit.

---

### Task 2: Implement the Complete Stateless Appearance Module

**Files:**
- Create: `human_appearance.gd`
- Test: `tests/test_human_appearance.gd`

**Interfaces:**
- Consumes: the Task 1 exact API, canonical values, validation contract, radius formula, and real-renderer assertions.
- Produces: `class_name HumanAppearance extends RefCounted`, `MAX_LOCAL_RADIUS == 48.0`, all six exact static methods, and no other public methods.
- Produces: only private pure geometry helpers; all CanvasItem calls occur inside `draw_owner`.

- [ ] **Step 1: Create the complete module**

Create `human_appearance.gd` with exactly:

```gdscript
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
```

- [ ] **Step 2: Run the module test to GREEN**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_human_appearance.gd
```

Expected: exit code `0` and:

```text
test_human_appearance: OK
```

No parse warning, invalid draw diagnostic, profile validation error, phone pixel failure, mutation failure, or RNG mismatch is acceptable.

- [ ] **Step 3: Verify module isolation and renderer surface**

Run:

```powershell
$forbidden = rg -n "seed|randf|randi|randomize|RandomNumberGenerator|Time\.|main|human\.gd|PairState|leash|tangle|group|spawn|cleanup" human_appearance.gd
if ($LASTEXITCODE -eq 0) { $forbidden; throw "forbidden module dependency found" }
if ($LASTEXITCODE -gt 1) { throw "rg failed" }
rg -n "^static func (profile_ids|get_profile|profile_id_for_key|profile_for_key|validation_errors|draw_owner)" human_appearance.gd
rg -n "canvas\.draw_" human_appearance.gd
git diff --check -- human_appearance.gd tests/test_human_appearance.gd
```

Expected: no forbidden match; exactly six public static signatures; every `canvas.draw_` match is lexically inside `draw_owner`; diff check exits `0`.

---

### Task 3: Establish Real-Pair Integration RED

**Files:**
- Create: `tests/test_pair_owner_appearance.gd`
- Test: `tests/test_human_appearance.gd`
- Inspect only: `otherpair.gd`, `tests/test_pair_dog_appearance.gd`, `leash.gd`

**Interfaces:**
- Consumes: complete `HumanAppearance` API, real `DogAppearance`, real pair lifecycle, and real leash endpoint fields `dog` and `human`.
- Produces: a separate `SceneTree` regression with success marker `test_pair_owner_appearance: OK`.
- Specifies: `owner_appearance_profile: Dictionary`, exact third/fourth raw draw use, compatibility colors, dictionary identity, node/endpoints, all-profile parent drawing, phones, and zero velocity.

- [ ] **Step 1: Create the complete pair regression**

Create `tests/test_pair_owner_appearance.gd`:

```gdscript
extends SceneTree

const HumanAppearanceScript := preload("res://human_appearance.gd")
const DogAppearanceScript := preload("res://dog_appearance.gd")
const PairScript := preload("res://otherpair.gd")
const PARK_BOUNDS := Rect2(20.0, -260.0, 360.0, 230.0)
const PARK_SPOT := Vector2(300.0, -90.0)
const WALKING := 0
const ARRIVING := 1
const PARKED := 2
const RECALLING := 3
const DEPARTING := 4

var failures := 0
var fixtures: Array[Node] = []


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := false
	var cam := Camera2D.new()
	var released_pair_ids: Array[int] = []

	func _init() -> void:
		add_child(cam)

	func release_pair_park_spot(pair_instance_id: int) -> void:
		released_pair_ids.append(pair_instance_id)

	func float_text(_position: Vector2, _text: String, _color: Color) -> void:
		pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _has_property(object: Object, property_name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _make_main() -> FakeMain:
	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	return main


func _make_player() -> Node2D:
	var player := Node2D.new()
	player.visible = false
	player.position = Vector2(1000.0, 1000.0)
	root.add_child(player)
	fixtures.append(player)
	return player


func _make_pair(
	main: FakeMain,
	player: Node2D,
	seed_value: int,
	start := Vector2(200.0, 120.0),
	direction := Vector2.UP
) -> Node2D:
	seed(seed_value)
	var pair := Node2D.new()
	pair.set_script(PairScript)
	var poles: Array[Vector2] = []
	pair.setup(main, player, poles, start, direction)
	var blockers: Array[Dictionary] = []
	_check(bool(pair.configure_route(start.x, 20.0, 380.0, blockers)), "real pair route configures")
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)
	main.cam.position = pair.npc_owner.position
	return pair


func _state(pair: Node2D) -> int:
	return int(pair.get_pair_state())


func _check_owner_identity(
	pair: Node2D,
	profile: Dictionary,
	profile_id: String,
	label: String
) -> void:
	_check(
		is_same(pair.owner_appearance_profile, profile),
		label + " keeps the same owner profile dictionary"
	)
	_check(
		String(pair.owner_appearance_profile.get("id", "")) == profile_id,
		label + " keeps the same owner profile ID"
	)


func _check_nodes_and_endpoints(
	pair: Node2D,
	pair_id: int,
	owner_id: int,
	dog_id: int,
	leash_id: int,
	label: String
) -> void:
	_check(pair.get_instance_id() == pair_id, label + " keeps pair identity")
	_check(pair.npc_owner.get_instance_id() == owner_id, label + " keeps owner identity")
	_check(pair.npc_dog.get_instance_id() == dog_id, label + " keeps dog identity")
	_check(pair.leash.get_instance_id() == leash_id, label + " keeps leash identity")
	_check(pair.leash.human == pair.npc_owner, label + " keeps owner leash endpoint")
	_check(pair.leash.dog == pair.npc_dog, label + " keeps dog leash endpoint")


func _test_exact_setup_rng(main: FakeMain, player: Node2D) -> void:
	const RNG_SEED := 424242
	var direction := Vector2.UP
	seed(RNG_SEED)
	var expected_speed := randf_range(58.0, 82.0)
	var expected_seed_o := randf() * 10.0
	var raw_owner_key := randi()
	var raw_dog_key := randi()
	var expected_next := randf()
	seed(RNG_SEED)
	var pair := Node2D.new()
	pair.set_script(PairScript)
	var poles: Array[Vector2] = []
	pair.setup(main, player, poles, Vector2(200.0, 120.0), direction)
	var actual_next := randf()
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)

	var expected_owner: Dictionary = HumanAppearanceScript.profile_for_key(raw_owner_key)
	var expected_dog: Dictionary = DogAppearanceScript.profile_for_key(raw_dog_key)
	_check(pair.vel.is_equal_approx(direction * expected_speed), "first draw sets velocity")
	_check(is_equal_approx(pair.seed_o, expected_seed_o), "second draw sets seed_o")
	_check(pair.owner_appearance_profile == expected_owner, "raw third draw selects owner profile")
	_check(pair.owner_col == expected_owner["shirt_color"], "owner_col derives from shirt_color")
	_check(pair.appearance_profile == expected_dog, "raw fourth draw still selects dog profile")
	_check(pair.dog_col == expected_dog["base_color"], "dog_col still derives from dog profile")
	_check(is_equal_approx(actual_next, expected_next), "setup preserves following global RNG value")

	var repeated := _make_pair(main, player, RNG_SEED)
	_check(
		repeated.owner_appearance_profile == pair.owner_appearance_profile,
		"equal seeds select equal owner profiles"
	)
	_check(repeated.appearance_profile == pair.appearance_profile, "equal seeds select equal dog profiles")
	_check(is_equal_approx(repeated.seed_o, pair.seed_o), "equal seeds select equal animation phases")
	var selected_owner_ids := {}
	for seed_value in [11, 29, 47, 83, 131, 197, 251, 307]:
		var candidate := _make_pair(main, player, seed_value)
		selected_owner_ids[String(candidate.owner_appearance_profile["id"])] = true
	_check(selected_owner_ids.size() > 1, "representative seeds select multiple owner profiles")


func _test_lifecycle_identity(main: FakeMain, player: Node2D) -> Node2D:
	var pair := _make_pair(main, player, 1707)
	pair.configure_park_area(0.0, PARK_BOUNDS)
	var owner_profile: Dictionary = pair.owner_appearance_profile
	var owner_profile_id := String(owner_profile["id"])
	var dog_profile: Dictionary = pair.appearance_profile
	var pair_id := pair.get_instance_id()
	var owner_id: int = pair.npc_owner.get_instance_id()
	var dog_id: int = pair.npc_dog.get_instance_id()
	var leash_id: int = pair.leash.get_instance_id()

	_check(_state(pair) == WALKING, "pair starts WALKING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "WALKING")
	_check_nodes_and_endpoints(pair, pair_id, owner_id, dog_id, leash_id, "WALKING")
	_check(bool(pair.begin_park_arrival(7, PARK_SPOT)), "pair begins arrival")
	_check(_state(pair) == ARRIVING, "pair enters ARRIVING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "ARRIVING")
	pair._enter_parked(100.0)
	_check(_state(pair) == PARKED, "pair enters PARKED")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "PARKED")
	pair.begin_park_recall()
	_check(_state(pair) == RECALLING, "pair enters RECALLING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "RECALLING")
	pair.npc_dog.position = pair.park_spot
	pair._physics_process(0.0)
	_check(_state(pair) == DEPARTING, "close recall enters DEPARTING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "DEPARTING")
	pair.npc_owner.position = Vector2(pair.walking_lane_x, 80.0)
	pair._physics_process(0.0)
	_check(_state(pair) == WALKING, "gate clearance resumes WALKING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "resumed WALKING")
	_check(is_same(pair.appearance_profile, dog_profile), "dog profile dictionary also remains identical")
	_check_nodes_and_endpoints(pair, pair_id, owner_id, dog_id, leash_id, "resumed WALKING")
	return pair


func _test_initialization_and_interrupt(main: FakeMain, player: Node2D) -> void:
	var departure := _make_pair(main, player, 2718)
	departure.configure_park_area(0.0, PARK_BOUNDS)
	var departure_profile: Dictionary = departure.owner_appearance_profile
	var departure_id := String(departure_profile["id"])
	_check(
		bool(departure.initialize_parked_departure(
			9,
			PARK_SPOT,
			Vector2(80.0, -220.0),
			100.0
		)),
		"parked departure initializes"
	)
	_check_owner_identity(departure, departure_profile, departure_id, "initialized PARKED")

	var interrupted := _make_pair(main, player, 3141)
	interrupted.configure_park_area(0.0, PARK_BOUNDS)
	var interrupted_profile: Dictionary = interrupted.owner_appearance_profile
	var interrupted_id := String(interrupted_profile["id"])
	_check(bool(interrupted.begin_park_arrival(10, PARK_SPOT)), "interrupt fixture enters ARRIVING")
	main.phase = "home"
	interrupted._physics_process(0.0)
	_check(_state(interrupted) == RECALLING, "home interrupts arrival into RECALLING")
	_check_owner_identity(
		interrupted,
		interrupted_profile,
		interrupted_id,
		"home-interrupted RECALLING"
	)
	main.phase = "freedom"


func _region_has_rgb(image: Image, center: Vector2, expected: Color) -> bool:
	var left := maxi(0, floori(center.x - 52.0))
	var right := mini(image.get_width() - 1, ceili(center.x + 52.0))
	var top := maxi(0, floori(center.y - 52.0))
	var bottom := mini(image.get_height() - 1, ceili(center.y + 52.0))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var actual := image.get_pixel(x, y)
			if (
				actual.a > 0.2
				and absf(actual.r - expected.r) <= 0.08
				and absf(actual.g - expected.g) <= 0.08
				and absf(actual.b - expected.b) <= 0.08
			):
				return true
	return false


func _region_has_screen_mix(
	image: Image,
	center: Vector2,
	body_color: Color,
	screen_color: Color
) -> bool:
	var left := maxi(0, floori(center.x - 52.0))
	var right := mini(image.get_width() - 1, ceili(center.x + 52.0))
	var top := maxi(0, floori(center.y - 52.0))
	var bottom := mini(image.get_height() - 1, ceili(center.y + 52.0))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var actual := image.get_pixel(x, y)
			for weight in [0.35, 0.45, 0.55, 0.65, 0.75]:
				var expected := body_color.lerp(screen_color, weight)
				if (
					actual.a > 0.9
					and absf(actual.r - expected.r) <= 0.08
					and absf(actual.g - expected.g) <= 0.08
					and absf(actual.b - expected.b) <= 0.08
				):
					return true
	return false


func _test_parent_rendering(pair: Node2D, player: Node2D) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	fixtures.append(viewport)
	pair.reparent(viewport)
	pair.position = Vector2.ZERO
	pair.npc_owner.position = Vector2(96.0, 96.0)
	pair.npc_dog.position = Vector2(170.0, 150.0)
	player.position = pair.npc_dog.global_position
	pair.vel = Vector2.ZERO
	seed(98765)
	var expected_next := randf()
	seed(98765)
	for state in [WALKING, ARRIVING, PARKED, RECALLING, DEPARTING]:
		pair.pair_state = state
		for profile_id: String in HumanAppearanceScript.profile_ids():
			pair.owner_appearance_profile = HumanAppearanceScript.get_profile(profile_id)
			pair.owner_col = pair.owner_appearance_profile["shirt_color"]
			pair.queue_redraw()
			await process_frame
			await process_frame
			var image := viewport.get_texture().get_image()
			_check(
				_region_has_rgb(
					image,
					pair.npc_owner.position,
					pair.owner_appearance_profile["phone_body_color"]
				),
				"%s state %d renders a phone body on the pair parent" % [profile_id, state]
			)
			_check(
				_region_has_screen_mix(
					image,
					pair.npc_owner.position,
					pair.owner_appearance_profile["phone_body_color"],
					pair.owner_appearance_profile["phone_screen_color"]
				),
				"%s state %d renders a phone screen on the pair parent" % [profile_id, state]
			)
	var actual_next := randf()
	_check(is_equal_approx(actual_next, expected_next), "pair drawing preserves global RNG")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_pair_owner_appearance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_owner_appearance: OK")
		quit(0)


func _run() -> void:
	var probe := Node2D.new()
	probe.set_script(PairScript)
	var has_owner_profile := _has_property(probe, "owner_appearance_profile")
	_check(has_owner_profile, "otherpair stores owner_appearance_profile")
	probe.free()
	if not has_owner_profile:
		_finish()
		return
	var main := _make_main()
	var player := _make_player()
	_test_exact_setup_rng(main, player)
	var lifecycle_pair := _test_lifecycle_identity(main, player)
	_test_initialization_and_interrupt(main, player)
	await _test_parent_rendering(lifecycle_pair, player)
	_finish()


func _initialize() -> void:
	call_deferred("_run")
```

- [ ] **Step 2: Run the pair test and verify strict RED before pair integration**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_owner_appearance.gd
```

Expected: exit code `1` and:

```text
FAIL: otherpair stores owner_appearance_profile
test_pair_owner_appearance: 1 FAILURES
```

There must be no parse error and no fake pair implementation.

- [ ] **Step 3: Re-run the module test**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_human_appearance.gd
```

Expected: `test_human_appearance: OK`. The pair RED must not weaken the module boundary.

---

### Task 4: Integrate Owner Profiles Into Real NPC Pairs

**Files:**
- Modify: `otherpair.gd:8-10,40-45,63-83,464-484`
- Test: `tests/test_pair_owner_appearance.gd`
- Regression: `tests/test_pair_dog_appearance.gd`

**Interfaces:**
- Consumes: `HumanAppearanceScript.profile_for_key(key: int) -> Dictionary` and approved eight-argument `draw_owner`.
- Produces: `var owner_appearance_profile: Dictionary = {}` distinct from dog `appearance_profile`.
- Preserves: exact pair setup signature, exact four initial draws, existing dog profile API/field/call, and all pair gameplay methods.

- [ ] **Step 1: Preload the module and add persistent owner profile state**

Change the preload block to:

```gdscript
const BypasserRouteScript := preload("res://bypasser_route.gd")
const DogAppearanceScript := preload("res://dog_appearance.gd")
const HumanAppearanceScript := preload("res://human_appearance.gd")
```

Change the visual fields to:

```gdscript
var owner_col := Color(0.5, 0.45, 0.55)
var dog_col := Color(0.6, 0.5, 0.4)
var owner_appearance_profile: Dictionary = {}
var appearance_profile: Dictionary = {}
var wander_t := 0.0
```

- [ ] **Step 2: Replace only the owner palette draw while preserving exact RNG order**

In `setup`, replace lines 67-72 with exactly:

```gdscript
	vel = direction * randf_range(58.0, 82.0)
	seed_o = randf() * 10.0
	var owner_appearance_key := randi()
	owner_appearance_profile = HumanAppearanceScript.profile_for_key(owner_appearance_key)
	owner_col = owner_appearance_profile["shirt_color"]
	var dog_appearance_key := randi()
	appearance_profile = DogAppearanceScript.profile_for_key(dog_appearance_key)
	dog_col = appearance_profile["base_color"]
```

The raw third value is not reduced by `% 3`. Do not insert any appearance RNG call before, inside, or after either module call.

- [ ] **Step 3: Replace only legacy owner drawing and keep dog rendering**

Replace `_draw()` with exactly:

```gdscript
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
```

Do not alter any state transition, movement, route, leash, tangle, greeting, group, slot, cleanup, collision, or endpoint code.

- [ ] **Step 4: Run both new focused tests to GREEN**

Run:

```powershell
foreach ($test in @("test_human_appearance.gd", "test_pair_owner_appearance.gd")) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
```

Expected:

```text
test_human_appearance: OK
test_pair_owner_appearance: OK
```

- [ ] **Step 5: Record the exact stale dog-test conflict without changing it**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_dog_appearance.gd
```

Expected: exit code `1` with only:

```text
FAIL: owner color uses the third randi
test_pair_dog_appearance: 1 FAILURES
```

The test’s dog profile, `dog_col`, RNG-stream, lifecycle, identity, and draw assertions must still pass. This known RED is caused by the current test asserting the removed palette and is intentionally repaired only after the two-stage isolated review and authorized implementation checkpoint. Any additional failure blocks review.

- [ ] **Step 6: Inspect exact RNG and draw call sites**

Run:

```powershell
rg -n "randf_range\(58\.0, 82\.0\)|seed_o = randf\(\) \* 10\.0|owner_appearance_key := randi\(\)|dog_appearance_key := randi\(\)" otherpair.gd
rg -n "HumanAppearanceScript\.(profile_for_key|draw_owner)|DogAppearanceScript\.(profile_for_key|draw_dog)" otherpair.gd
git diff --check -- human_appearance.gd otherpair.gd tests/test_human_appearance.gd tests/test_pair_owner_appearance.gd
```

Expected: the four RNG lines appear once and in order; each selector/renderer appears once; diff check exits `0`.

---

### Task 5: Verify and Two-Stage Review the Isolated Boundary

**Files:**
- Review: `human_appearance.gd`
- Review: `otherpair.gd`
- Review: `tests/test_human_appearance.gd`
- Review: `tests/test_pair_owner_appearance.gd`
- Do not modify any other file.

**Interfaces:**
- Consumes: complete four-file isolated implementation.
- Produces: full automated evidence and two independent review gates before implementation commit or integration edits.

- [ ] **Step 1: Run the complete current focused regression suite**

Run:

```powershell
$tests = @(
  "test_wrap.gd",
  "test_critter_chase.gd",
  "test_tangle_latch.gd",
  "test_freedom_traffic.gd",
  "test_pair_direction.gd",
  "test_bandana_preview.gd",
  "test_owner_label.gd",
  "test_bypasser_route.gd",
  "test_rider_avoidance.gd",
  "test_pair_pond_avoidance.gd",
  "test_pair_park_lifecycle.gd",
  "test_pair_park_slots.gd",
  "test_pair_park_traffic.gd",
  "test_free_dog_variety.gd",
  "test_pair_dog_appearance.gd",
  "test_human_appearance.gd",
  "test_pair_owner_appearance.gd"
)
foreach ($test in $tests) {
  $output = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test" 2>&1
  $exitCode = $LASTEXITCODE
  $output
  if ($test -eq "test_pair_dog_appearance.gd") {
    if ($exitCode -ne 1) { throw "$test did not produce the expected stale-contract RED" }
    $failLines = @($output | Where-Object { "$_" -match "FAIL:" })
    if ($failLines.Count -ne 1 -or "$($failLines[0])" -notmatch "FAIL: owner color uses the third randi") {
      throw "$test produced an unexpected failure"
    }
  } elseif ($exitCode -ne 0) {
    throw "$test failed"
  }
}
```

Expected during the isolated four-file review: 16 tests exit `0` and print their own `: OK` markers; `test_pair_dog_appearance.gd` exits `1` with only the documented obsolete owner-palette failure. `test_wrap.gd` may additionally print rope metrics. Any other failure blocks review. The final integration rerun in Task 7 must restore all 17 tests to green.

- [ ] **Step 2: Run all four level smokes**

Run:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
foreach ($level in @("street", "park", "beach", "market")) {
  $output = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- "--level=$level" 2>&1
  $exitCode = $LASTEXITCODE
  $output | Set-Content "build\owner-smoke-$level.log"
  if ($exitCode -ne 0) { throw "$level smoke failed" }
  if ($output -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "$level smoke logged a script failure"
  }
}
```

Expected: all four commands exit `0`; no log includes script/load errors. `build/` remains ignored.

- [ ] **Step 3: Run deterministic street and park autowalks**

Run:

```powershell
foreach ($level in @("street", "park")) {
  $output = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- "--level=$level" --autowalk 2>&1
  $exitCode = $LASTEXITCODE
  $output | Set-Content "build\owner-autowalk-$level.log"
  if ($exitCode -ne 0) { throw "$level autowalk failed" }
  if ($output -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "$level autowalk logged a script failure"
  }
  if ($output -notmatch "AUTOWALK FINISHED") {
    throw "$level autowalk did not finish"
  }
}
```

Expected: both exit `0`, have no script/load failures, and include `AUTOWALK FINISHED`.

- [ ] **Step 4: Run API, RNG, forbidden-call, and scope checks**

Run:

```powershell
$moduleForbidden = rg -n "seed|randf|randi|randomize|RandomNumberGenerator|Time\.|PairState|main|leash|tangle|spawn|cleanup" human_appearance.gd
if ($LASTEXITCODE -eq 0) { $moduleForbidden; throw "forbidden HumanAppearance dependency" }
if ($LASTEXITCODE -gt 1) { throw "rg failed" }
$scopeForbidden = rg -n "creator|save|migration|unlock|progression|gameplay.stat|difficulty|score" human_appearance.gd otherpair.gd
if ($LASTEXITCODE -eq 0) { $scopeForbidden; throw "excluded scope found" }
if ($LASTEXITCODE -gt 1) { throw "rg failed" }
rg -n "^static func (profile_ids|get_profile|profile_id_for_key|profile_for_key|validation_errors|draw_owner)" human_appearance.gd
rg -n "func setup\(m: Node2D, mine: Node2D, poles: Array\[Vector2\], start: Vector2, direction: Vector2\) -> void" otherpair.gd
rg -n "owner_appearance_key := randi\(\)|dog_appearance_key := randi\(\)" otherpair.gd
git diff --name-only
```

Expected: both forbidden searches have no matches; six exact module methods; unchanged setup signature; one owner and one dog key draw in order; changed names are exactly the isolated four files.

- [ ] **Step 5: Inspect the isolated diff and object contracts**

Run:

```powershell
git diff --check
git diff -- human_appearance.gd otherpair.gd tests/test_human_appearance.gd tests/test_pair_owner_appearance.gd
git status --short
```

Expected status:

```text
 M otherpair.gd
?? human_appearance.gd
?? tests/test_human_appearance.gd
?? tests/test_pair_owner_appearance.gd
```

There must be no edit to `human.gd`, `dog_appearance.gd`, `main.gd`, `leash.gd`, any existing test, CI, changelog, handover, project docs, specs, or plans.

- [ ] **Step 6: Run stage-one spec-compliance review**

Give the reviewer the approved spec and exactly this review brief:

```text
Review only human_appearance.gd, otherpair.gd, tests/test_human_appearance.gd,
and tests/test_pair_owner_appearance.gd against
docs/superpowers/specs/2026-07-17-npc-owner-appearance-design.md.
Check every exact API signature, MAX_LOCAL_RADIUS, profile ID/order/schema/value,
defensive-copy and positive-modulo rule, validation requirement, finite/radius
safety, renderer coordinate/input/draw-order contract, every hair/headwear/
eyewear/phone branch, every phone and glow/state rule, zero/non-finite behavior,
all-field renderer use, no mutation/RNG, exact pair four-draw cadence with raw
third/fourth keys, owner_col compatibility, owner/dog dictionary identity,
all lifecycle and initialization paths, pair/owner/dog/leash identity and
endpoints, parent-Canvas rendering, unchanged DogAppearance and human.gd, and
all scope exclusions. Confirm that the sole existing test failure is the
impossible obsolete owner-palette assertion in test_pair_dog_appearance.gd and
approve its narrowly specified post-checkpoint removal. CI/docs and that
existing-test correction remain outside this isolated review.
```

Expected: every approved requirement maps to code and a real-script assertion. Fix every finding only inside the four-file boundary, rerun Steps 1-5, and repeat stage one until it passes.

- [ ] **Step 7: Run stage-two code-quality review**

Give a second reviewer:

```text
Review the stage-one-approved four-file implementation for concrete GDScript
correctness and maintainability risks: parse/type/signature consistency,
malformed dictionary safety, finite derived geometry, conservative radius,
primitive point/dimension safety, CanvasItem draw legality in headless mode,
phone pixel-test reliability, hidden RNG/clock/state coupling, profile aliasing
or lifecycle replacement, renderer branch completeness, accidental behavior
changes, and brittle test fixtures. Treat the approved spec as fixed scope.
```

Expected: no unresolved correctness or maintainability finding. Fix findings inside the four-file boundary, rerun Steps 1-6, and repeat both review stages. Do not commit, push, or edit integration files until both pass.

---

### Task 6: Create the Authorized Implementation Checkpoint

**Files:**
- Stage only: `human_appearance.gd`
- Stage only: `otherpair.gd`
- Stage only: `tests/test_human_appearance.gd`
- Stage only: `tests/test_pair_owner_appearance.gd`

**Interfaces:**
- Consumes: passing focused evidence, the one precisely documented stale test assertion, and both approved reviews from Task 5.
- Produces: one reviewable isolated implementation commit.
- Does not modify CI/docs and does not push.

- [ ] **Step 1: Obtain explicit checkpoint authorization**

Authorization must explicitly allow committing the reviewed four-file implementation and proceeding to integration. Passing tests alone is not authorization.

- [ ] **Step 2: Re-run both focused tests immediately before staging**

Run:

```powershell
foreach ($test in @("test_human_appearance.gd", "test_pair_owner_appearance.gd")) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
```

Expected: both print `: OK`. Re-run `test_pair_dog_appearance.gd` separately and require its only failure to remain the exact obsolete owner-palette assertion documented in Task 4 Step 5.

- [ ] **Step 3: Stage only the reviewed boundary**

Run:

```powershell
git add -- human_appearance.gd otherpair.gd tests/test_human_appearance.gd tests/test_pair_owner_appearance.gd
git diff --cached --check
git diff --cached --name-only
```

Expected names exactly:

```text
human_appearance.gd
otherpair.gd
tests/test_human_appearance.gd
tests/test_pair_owner_appearance.gd
```

- [ ] **Step 4: Commit the authorized implementation**

Run:

```powershell
git commit -m "Add reusable NPC owner appearances"
```

Expected: one commit with exactly the four reviewed files. Record its hash with `git rev-parse HEAD`. Do not push yet.

---

### Task 7: Integrate CI, Changelog, and Comprehensive Handover

**Files:**
- Modify: `tests/test_pair_dog_appearance.gd`
- Modify: `.github/workflows/ci.yml`
- Modify: `CHANGELOG.md`
- Modify: `HANDOVER.md`

**Interfaces:**
- Consumes: authorized implementation checkpoint and complete Task 5 evidence.
- Produces: removal of one impossible obsolete owner-palette assertion while preserving every dog-focused contract, Linux CI coverage for both new tests, append-only release history, and a context-complete model-neutral handover.
- Produces: a separately reviewable integration commit.

- [ ] **Step 1: Remove only the obsolete owner-palette assertion**

Delete this constant from `tests/test_pair_dog_appearance.gd`:

```gdscript
const OWNER_COLORS := [
	Color(0.5, 0.45, 0.55),
	Color(0.45, 0.5, 0.42),
	Color(0.55, 0.48, 0.4),
]
```

Change:

```gdscript
	var owner_key := randi()
```

to:

```gdscript
	var _owner_key := randi()
```

Delete only:

```gdscript
	_check(pair.owner_col == OWNER_COLORS[owner_key % OWNER_COLORS.size()], "owner color uses the third randi")
```

The raw third draw remains in the expected sequence, so the fourth dog key and following RNG value remain exact. Do not alter any dog profile, lifecycle, identity, or renderer assertion; the new owner-focused test now owns the replacement `owner_col` contract.

- [ ] **Step 2: Run the existing dog test back to GREEN**

Run:

```powershell
.\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_pair_dog_appearance.gd
```

Expected: `test_pair_dog_appearance: OK`.

- [ ] **Step 3: Add both focused tests to CI**

Immediately after the existing NPC pair dog appearance step and before level smokes, add:

```yaml
      - name: Human appearance regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_human_appearance.gd

      - name: NPC pair owner appearance regression test
        run: ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_pair_owner_appearance.gd

```

- [ ] **Step 4: Add the append-only changelog entry**

Insert after the preamble and before the current newest entry:

```markdown
## 2026-07-17 — reusable NPC owner appearances

- Added six neutral procedural NPC owner profiles with distinct proportions,
  hair, headwear, eyewear, palettes, and phone treatments behind a reusable
  stateless appearance boundary.
- NPC pairs reuse their existing owner-color random draw as the raw profile key,
  preserving exact setup RNG cadence, downstream randomness, and the existing
  dog appearance selection.
- The same defensive owner profile now persists through walking, arrival,
  parking, recall, re-leashing, departure, and resumed walking while the real
  owner, dog, and leash nodes remain unchanged.
- Added real-script catalog, validation, renderer, phone-pixel, RNG, lifecycle,
  node-identity, and parent-Canvas regressions.

```

- [ ] **Step 5: Capture actual repository state for the handover**

Run:

```powershell
$branch = git branch --show-current
$implementationCommit = git rev-parse HEAD
$implementationSubject = git log -1 --format=%s
$upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
if ($LASTEXITCODE -ne 0) { $upstream = "none" }
$pr = gh pr view --json number,url,state,headRefName,baseRefName 2>$null
if ($LASTEXITCODE -ne 0) { $pr = '{"state":"not created"}' }
@(
  "branch=$branch",
  "implementation_commit=$implementationCommit",
  "implementation_subject=$implementationSubject",
  "upstream=$upstream",
  "pr=$pr"
) | Set-Content build\owner-handover-state.txt
Get-Content build\owner-handover-state.txt
```

Expected: concrete values, not template markers. The implementation subject is `Add reusable NPC owner appearances`. Do not claim a push or PR that has not happened.

- [ ] **Step 6: Rewrite the relevant HANDOVER sections comprehensively**

Update `HANDOVER.md` so it includes all of this exact substantive content, using the concrete state values captured in Step 3:

```markdown
### Reusable NPC owner appearance architecture

`human_appearance.gd` is the stateless reusable boundary for generic NPC owner
presentation. It exposes six persistence-facing IDs in stable order, defensive
profile lookup and signed-key selection, comprehensive validation, and one
procedural renderer. It creates no nodes, owns no runtime state, consumes no
randomness, and has no dependency on pair behavior, lifecycle, leashes, player
owner code, creator UI, or save data.

`otherpair.gd` owns one `owner_appearance_profile` dictionary for the complete
pair lifetime. Setup still consumes exactly velocity `randf_range`, animation
phase `randf`, raw owner `randi`, and raw dog `randi` in that order.
`owner_col` derives from the selected owner profile's `shirt_color`; the
existing dog profile and `dog_col` flow is unchanged. Both procedural
renderers draw on the pair parent while `npc_owner`, `npc_dog`, and `leash`
remain the real persistent gameplay nodes and endpoints.

The stable owner IDs are `compact_short_cap`, `tall_long_glasses`,
`broad_bun_sunglasses`, `medium_bald_spot_glasses`,
`narrow_short_beanie`, and `rounded_long_cap`. Their order, exact schema, and
meaning are persistence-facing API for possible later creator reuse. No
creator, selector, save, migration, unlock, progression, stat, or behavior
feature is part of this implementation.

### NPC owner appearance repository state

Record the actual current feature branch, the full implementation checkpoint
hash and subject, its upstream state, and the actual PR state from
`build/owner-handover-state.txt`. State explicitly that the later CI/docs
integration commit will sit above that implementation checkpoint. Do not write
`latest`, `current`, an abbreviated guess, a template token, or a PR URL/state
that was not observed.

### NPC owner appearance automated evidence

- `test_human_appearance.gd` loads the real module and covers the exact public
  API, stable ID order, canonical values/schema/types, defensive copies,
  positive and negative key cycling, non-mutating malformed-data validation,
  finite/color/enum/primitive/radius safety, every visual trait branch, RNG
  isolation, zero/non-finite facing fallback, non-finite early return,
  malformed-profile fallback, headless drawing in both phone states, and
  rendered body/screen pixels for every canonical phone.
- `test_pair_owner_appearance.gd` loads the real pair, owner appearance, dog
  appearance, and leash scripts and covers the exact four setup draws, raw
  third/fourth profile keys, following RNG value, compatibility colors, equal
  seeds, owner profile variety, dictionary identity through every lifecycle
  state and initialization/interruption path, pair/owner/dog/leash identity,
  leash endpoint references, zero-velocity north fallback, parent-Canvas
  owner-and-dog drawing, held phones, and draw-time RNG isolation.
- `test_pair_dog_appearance.gd` remains green and dog-focused; its obsolete
  three-color owner-palette assertion was removed after isolated review because
  the approved owner contract derives `owner_col` from canonical shirt color.
- List every focused regression run and its observed `: OK` result; list all
  four level smokes and both fixed-60-FPS street/park autowalks, including the
  observed `AUTOWALK FINISHED` markers. Include execution date and platform.
  Do not summarize a test as passing unless its command was actually run after
  the final code change.

### NPC owner appearance manual acceptance

Manual visual acceptance remains outstanding unless a human actually launched
the game and inspected all six profiles through walking, arrival, parking,
recall, re-leashing, departure, and resumed walking. Headless draw and pixel
tests do not establish silhouette readability, phone legibility, accessory
layering, color contrast, local-scale quality, gait feel, or lifecycle visual
continuity. Record the exact manual observations if performed; otherwise keep
this outstanding statement.

### Recommended next priorities

1. Perform and record manual NPC owner and existing NPC lifecycle visual
   acceptance before tuning presentation or movement.
2. Fix only observed profile/renderer defects inside the appearance boundary;
   do not alter pair behavior to tune art.
3. Keep future creator work separate. It may consume stable IDs, defensive
   profiles, validation, and rendering, but requires its own approved design
   for player-owner integration, UI, and persistence.
4. Continue the existing roadmap priorities only after appearance and
   lifecycle acceptance evidence is recorded.
```

Also update the CI source-of-truth list to include `test_human_appearance.gd` and `test_pair_owner_appearance.gd`. Remove or rewrite stale statements that reusable owner appearances are merely future work. Preserve unrelated historical context.

- [ ] **Step 7: Run the complete suite, smokes, and autowalks again**

Run:

```powershell
$tests = @(
  "test_wrap.gd",
  "test_critter_chase.gd",
  "test_tangle_latch.gd",
  "test_freedom_traffic.gd",
  "test_pair_direction.gd",
  "test_bandana_preview.gd",
  "test_owner_label.gd",
  "test_bypasser_route.gd",
  "test_rider_avoidance.gd",
  "test_pair_pond_avoidance.gd",
  "test_pair_park_lifecycle.gd",
  "test_pair_park_slots.gd",
  "test_pair_park_traffic.gd",
  "test_free_dog_variety.gd",
  "test_pair_dog_appearance.gd",
  "test_human_appearance.gd",
  "test_pair_owner_appearance.gd"
)
foreach ($test in $tests) {
  .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
foreach ($level in @("street", "park", "beach", "market")) {
  $output = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 1800 -- "--level=$level" 2>&1
  $exitCode = $LASTEXITCODE
  $output | Set-Content "build\owner-final-smoke-$level.log"
  if ($exitCode -ne 0) { throw "$level smoke failed" }
  if ($output -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "$level smoke logged a script failure"
  }
}
foreach ($level in @("street", "park")) {
  $output = & .\godot\Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . --quit-after 12000 -- "--level=$level" --autowalk 2>&1
  $exitCode = $LASTEXITCODE
  $output | Set-Content "build\owner-final-autowalk-$level.log"
  if ($exitCode -ne 0) { throw "$level autowalk failed" }
  if ($output -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    throw "$level autowalk logged a script failure"
  }
  if ($output -notmatch "AUTOWALK FINISHED") {
    throw "$level autowalk did not finish"
  }
}
```

Expected: all 17 focused tests pass; all four level smokes are clean; street and park autowalk both include `AUTOWALK FINISHED`.

- [ ] **Step 8: Inspect and commit only integration files**

Run:

```powershell
git diff --check
git diff -- tests/test_pair_dog_appearance.gd .github/workflows/ci.yml CHANGELOG.md HANDOVER.md
git status --short
git add -- tests/test_pair_dog_appearance.gd .github/workflows/ci.yml CHANGELOG.md HANDOVER.md
git diff --cached --check
git diff --cached --name-only
git commit -m "Integrate NPC owner appearance regressions"
```

Expected staged names exactly:

```text
.github/workflows/ci.yml
CHANGELOG.md
HANDOVER.md
tests/test_pair_dog_appearance.gd
```

Expected: a second commit above the isolated implementation checkpoint.

---

### Task 8: Final Whole-Branch Review and Push/PR Decision

**Files:**
- Review: whole branch against its merge base.
- Modify only `HANDOVER.md` if actual final repository/PR state must be synchronized.

**Interfaces:**
- Consumes: implementation and integration commits plus all evidence.
- Produces: final branch-level review, accurate handover, feature-branch push, and an explicit PR decision.

- [ ] **Step 1: Review the whole branch against main**

Run:

```powershell
git fetch origin
git diff --check origin/main...HEAD
git diff --stat origin/main...HEAD
git diff --name-status origin/main...HEAD
git log --oneline --decorate origin/main..HEAD
```

Expected branch file set exactly:

```text
M	.github/workflows/ci.yml
M	CHANGELOG.md
M	HANDOVER.md
A	human_appearance.gd
M	otherpair.gd
A	tests/test_human_appearance.gd
M	tests/test_pair_dog_appearance.gd
A	tests/test_pair_owner_appearance.gd
```

Expected two commits: `Add reusable NPC owner appearances` and `Integrate NPC owner appearance regressions`.

- [ ] **Step 2: Run final whole-branch spec and quality review**

Review `origin/main...HEAD` for:

```text
Exact approved API/schema/profile IDs/order/values and renderer signatures;
all phone and trait contracts; validation, finite and radius safety; zero and
non-finite input behavior; no profile mutation or RNG; exact pair third/fourth
raw draws and downstream stream; owner_col and dog compatibility; owner
dictionary identity in every state/path; pair/owner/dog/leash identity and
endpoints; parent-Canvas rendering; unchanged human.gd and DogAppearance;
absence of creator/save/stats/behavior/assets/dependencies; CI completeness;
append-only changelog; comprehensive non-stale model-neutral handover; and no
unrelated branch change.
```

Expected: no unresolved finding. Any code/test finding returns to the two-stage isolated review and reruns all evidence; any integration finding is fixed in the integration files and reviewed again.

- [ ] **Step 3: Push the feature branch**

Run only after final review approval and push authorization:

```powershell
git push -u origin npc-owner-appearances
```

Expected: remote branch `origin/npc-owner-appearances` is created/updated and local upstream is set. Do not push implementation commits directly to `main`.

- [ ] **Step 4: Make and record the PR decision**

If authorized to open a PR, run:

```powershell
gh pr create --base main --head npc-owner-appearances --title "Add reusable NPC owner appearances" --body "Implements the approved reusable NPC owner appearance spec with exact RNG preservation, real-script renderer and lifecycle coverage, complete regression/smoke/autowalk evidence, and manual visual acceptance explicitly left outstanding."
gh pr view --json number,url,state,headRefName,baseRefName
```

Expected: an open PR from `npc-owner-appearances` to `main` and concrete number/URL output.

If PR creation is not authorized, do not run `gh pr create`; record the explicit decision as “feature branch pushed; PR not created pending user decision.” This is a required decision, not an implicit omission.

- [ ] **Step 5: Synchronize handover only when final state changed**

If the push or PR state makes `HANDOVER.md` stale, update only its repository-state subsection with the observed branch/upstream/PR values, preserve all evidence and manual-acceptance wording, then run:

```powershell
git add -- HANDOVER.md
git diff --cached --check
git commit -m "Finalize NPC owner appearance handover"
git push
```

Expected: a third documentation-only commit when and only when needed. Because a commit cannot contain its own hash, identify this final handover commit by its exact subject and record the full hashes of the implementation and integration commits beneath it. Never invent a self-referential HEAD hash.

- [ ] **Step 6: Report final status**

Run:

```powershell
git status --short --branch
git log -3 --oneline --decorate
git rev-parse HEAD
git rev-parse '@{u}'
gh pr view --json number,url,state,headRefName,baseRefName 2>$null
```

Expected: clean feature branch, local and upstream hashes equal, accurate commit stack, and observed PR state matching `HANDOVER.md`. Report all automated evidence and state that manual visual acceptance remains outstanding unless actually completed.

---

## Plan Self-Review Result

- Spec coverage: every approved architecture, API, schema, profile, renderer, validation, RNG, lifecycle, identity, phone, review, integration, evidence, handover, and exclusion requirement maps to a task and to the requirement trace below.
- No incomplete instructions: the plan contains no deferred implementation markers, vague error-handling directions, omitted code steps, or references that substitute for required command/code content.
- Type and signature consistency: all six public method names, argument names/order/types, return types, `MAX_LOCAL_RADIUS`, profile fields, pair field names, and renderer call sites match from tests through implementation and integration.
- RNG cadence: both tests and integration use exactly `randf_range`, `randf`, raw owner `randi`, raw dog `randi`, then compare the following value. Neither appearance module nor draw path consumes randomness.
- Profile and renderer completeness: all exact canonical values are asserted; all visual fields except identity metadata feed rendering; all hair, headwear, eyewear, and phone treatments are represented; held/raised/unknown phone states, every phone’s rendered body/screen, zero/non-finite facing, malformed fallback, non-finite early return, and radius safety are covered.
- Future creator boundary: only stable IDs, defensive profile data, validation, and rendering are reusable. No player-owner integration, UI, save, migration, progression, stats, or behavior enters this task.
- Scope exclusions: production edits remain limited to `human_appearance.gd` and `otherpair.gd`; `human.gd`, `dog_appearance.gd`, gameplay, assets, dependencies, and existing behavior stay unchanged.
- Current-source conflict found and resolved: `tests/test_pair_dog_appearance.gd` currently asserts the obsolete three-color owner palette, which is mathematically incompatible with the approved exact shirt colors and compatibility rule. The plan preserves that test through both isolated reviews, records its sole expected RED, then removes only that obsolete assertion in the post-checkpoint integration task while retaining its raw third draw and every dog/RNG/lifecycle contract.
- Handover accuracy: runtime commands capture concrete branch, commit, upstream, and PR state; the handover records only observed evidence, keeps manual visual acceptance outstanding unless performed, and names no assumed capabilities of a later model.

---

## Requirement-to-Task Trace

- Required sub-skill header, goal, architecture, tech stack, constraints, file map, interfaces, checkboxes, exact commands/output: document header and every task.
- Strict module RED before implementation: Task 1.
- Exact API, six IDs/order/schema/values, positive modulo, defensive copies, future creator boundary: Tasks 1-2.
- Complete validation, malformed/finite/color/enum/primitive/radius safety and non-mutation: Tasks 1-2.
- Every hair/headwear/eyewear/phone branch, every visual field, all phones, held/raised/unknown states, glow, draw order, geometry bound: Tasks 1-2.
- Zero/non-finite forward, non-finite origin/scalars, malformed fallback, headless real-script draw, phone pixels: Tasks 1-2.
- No module RNG/clock/lifecycle dependency: Tasks 1-2 and Task 5 checks.
- Strict pair RED before integration: Task 3.
- Exact pair four-draw count/order, raw third/fourth keys, downstream stream, owner_col/dog_col compatibility: Tasks 3-5.
- Owner dictionary identity through all states, parked initialization, home interruption, node/leash/dog identity and endpoints: Tasks 3-5.
- Parent-Canvas owner and dog rendering, all profiles, all states, phones, zero velocity: Tasks 3-5.
- No `human.gd`, player owner, behavior, stats, creator UI, save, migration, progression, asset, or dependency changes: Global Constraints and Task 5.
- Four-file isolated boundary and no CI/docs before review: Global Constraints and Tasks 1-5.
- Stage-one spec review and stage-two quality review: Task 5.
- Authorized implementation checkpoint: Task 6.
- Separate CI/CHANGELOG/HANDOVER integration: Task 7.
- Full existing regressions including dog appearance and both new owner tests, with the impossible obsolete owner-palette assertion corrected only after isolated review: Tasks 5 and 7.
- Four level smokes and deterministic street/park autowalks through `AUTOWALK FINISHED`: Tasks 5 and 7.
- API, forbidden-call, RNG, diff, scope, and whole-branch checks: Tasks 2, 4, 5, and 8.
- Comprehensive handover for context switching, actual branch/commit/PR state, complete evidence, manual visual acceptance, priorities, and no implementation-capability assumptions: Tasks 7-8.
- Final feature-branch push and explicit PR decision: Task 8.
