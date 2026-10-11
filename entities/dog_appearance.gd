class_name DogAppearance
extends RefCounted

const Clay := preload("res://entities/clay.gd")

const MAX_LOCAL_RADIUS := 40.0
const MAX_BOB := 1.5
# the walkers' and the park's dogs, one breed each, so a park full of them
# reads as a park full of different dogs
const PROFILE_IDS := [
	"compact_point_ear",
	"long_low_drop_ear",
	"tall_narrow_rose_ear",
	"stocky_fold_ear",
	"fluffy_curl_tail",
	"shaggy_drop_ear",
	"sturdy_otter_tail",
	"spotted_drop_ear",
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

# body_size is the body's half length and half width; muzzle_size is its
# length and half width. "brutus" (the park thief) and "guard" (the
# scrapyard's chained dog) are not in PROFILE_IDS: nobody else gets their look.
const PROFILES := {
	"compact_point_ear": {
		"id": "compact_point_ear",
		"name": "Terrier",
		"size_scale": 1.0,
		"body_size": Vector2(9.0, 5.6),
		"head_radius": 5.0,
		"muzzle_size": Vector2(3.4, 2.0),
		"ear_style": "point",
		"ear_size": Vector2(2.6, 3.8),
		"ear_offset": Vector2(-1.4, 3.2),
		"tail_style": "straight",
		"tail_length": 5.5,
		"tail_thickness": 2.4,
		"tail_carriage": 0.0,
		"base_color": Color(0.95, 0.93, 0.87),
		"secondary_color": Color(0.74, 0.50, 0.27),
		"marking_color": Color(0.70, 0.46, 0.24),
		"marking_style": "patch",
		"marking_offset": Vector2(-3.5, 1.2),
		"marking_scale": Vector2(3.8, 3.4),
	},
	"long_low_drop_ear": {
		"id": "long_low_drop_ear",
		"name": "Dachshund",
		"size_scale": 1.0,
		"body_size": Vector2(15.0, 4.4),
		"head_radius": 4.6,
		"muzzle_size": Vector2(5.6, 1.9),
		"ear_style": "drop",
		"ear_size": Vector2(2.8, 5.6),
		"ear_offset": Vector2(-1.6, 3.4),
		"tail_style": "whip",
		"tail_length": 10.0,
		"tail_thickness": 1.8,
		"tail_carriage": -0.1,
		"base_color": Color(0.64, 0.32, 0.15),
		"secondary_color": Color(0.44, 0.21, 0.10),
		"marking_color": Color(0.80, 0.52, 0.30),
		"marking_style": "solid",
		"marking_offset": Vector2(0.0, 0.0),
		"marking_scale": Vector2(1.0, 1.0),
	},
	"tall_narrow_rose_ear": {
		"id": "tall_narrow_rose_ear",
		"name": "Greyhound",
		"size_scale": 1.22,
		"body_size": Vector2(11.0, 3.7),
		"head_radius": 3.8,
		"muzzle_size": Vector2(6.0, 1.5),
		"ear_style": "rose",
		"ear_size": Vector2(3.0, 2.6),
		"ear_offset": Vector2(-2.2, 2.4),
		"tail_style": "whip",
		"tail_length": 14.0,
		"tail_thickness": 1.1,
		"tail_carriage": -0.35,
		"base_color": Color(0.72, 0.58, 0.42),
		"secondary_color": Color(0.56, 0.43, 0.30),
		"marking_color": Color(0.33, 0.24, 0.17),
		"marking_style": "brindle",
		"marking_offset": Vector2(-0.5, 0.0),
		"marking_scale": Vector2(17.0, 3.4),
	},
	"stocky_fold_ear": {
		"id": "stocky_fold_ear",
		"name": "Pug",
		"size_scale": 1.0,
		"body_size": Vector2(8.0, 6.8),
		"head_radius": 6.2,
		"muzzle_size": Vector2(1.6, 3.0),
		"ear_style": "fold",
		"ear_size": Vector2(3.0, 3.2),
		"ear_offset": Vector2(-1.0, 4.4),
		"tail_style": "curl",
		"tail_length": 7.0,
		"tail_thickness": 2.6,
		"tail_carriage": 0.0,
		"base_color": Color(0.88, 0.75, 0.55),
		"secondary_color": Color(0.17, 0.14, 0.13),
		"marking_color": Color(0.17, 0.14, 0.13),
		"marking_style": "solid",
		"marking_offset": Vector2(0.0, 0.0),
		"marking_scale": Vector2(1.0, 1.0),
	},
	"fluffy_curl_tail": {
		"id": "fluffy_curl_tail",
		"name": "Husky",
		"size_scale": 1.16,
		"body_size": Vector2(11.0, 6.4),
		"head_radius": 5.6,
		"muzzle_size": Vector2(4.0, 2.4),
		"ear_style": "point",
		"ear_size": Vector2(3.4, 4.6),
		"ear_offset": Vector2(-1.2, 3.4),
		"tail_style": "curl",
		"tail_length": 10.0,
		"tail_thickness": 3.6,
		"tail_carriage": 0.0,
		"base_color": Color(0.43, 0.45, 0.51),
		"secondary_color": Color(0.30, 0.31, 0.36),
		"marking_color": Color(0.95, 0.95, 0.93),
		"marking_style": "blaze_points",
		"marking_offset": Vector2(1.6, 0.0),
		"marking_scale": Vector2(4.0, 4.4),
	},
	"shaggy_drop_ear": {
		"id": "shaggy_drop_ear",
		"name": "Poodle",
		"size_scale": 1.1,
		"body_size": Vector2(10.0, 5.6),
		"head_radius": 5.0,
		"muzzle_size": Vector2(4.6, 1.8),
		"ear_style": "drop",
		"ear_size": Vector2(3.4, 5.4),
		"ear_offset": Vector2(-1.6, 3.8),
		"tail_style": "plume",
		"tail_length": 8.0,
		"tail_thickness": 1.6,
		"tail_carriage": 0.2,
		"base_color": Color(0.88, 0.66, 0.46),
		"secondary_color": Color(0.80, 0.56, 0.37),
		"marking_color": Color(0.94, 0.78, 0.60),
		"marking_style": "solid",
		"marking_offset": Vector2(0.0, 0.0),
		"marking_scale": Vector2(1.0, 1.0),
	},
	"sturdy_otter_tail": {
		"id": "sturdy_otter_tail",
		"name": "Labrador",
		"size_scale": 1.24,
		"body_size": Vector2(12.0, 6.4),
		"head_radius": 6.0,
		"muzzle_size": Vector2(4.6, 2.8),
		"ear_style": "drop",
		"ear_size": Vector2(3.2, 4.6),
		"ear_offset": Vector2(-1.8, 4.2),
		"tail_style": "straight",
		"tail_length": 11.0,
		"tail_thickness": 3.4,
		"tail_carriage": 0.1,
		"base_color": Color(0.19, 0.18, 0.18),
		"secondary_color": Color(0.14, 0.13, 0.13),
		"marking_color": Color(0.30, 0.28, 0.27),
		"marking_style": "solid",
		"marking_offset": Vector2(0.0, 0.0),
		"marking_scale": Vector2(1.0, 1.0),
	},
	"spotted_drop_ear": {
		"id": "spotted_drop_ear",
		"name": "Dalmatian",
		"size_scale": 1.18,
		"body_size": Vector2(12.0, 5.4),
		"head_radius": 5.2,
		"muzzle_size": Vector2(4.8, 2.2),
		"ear_style": "drop",
		"ear_size": Vector2(3.0, 4.4),
		"ear_offset": Vector2(-1.6, 3.8),
		"tail_style": "whip",
		"tail_length": 13.0,
		"tail_thickness": 1.8,
		"tail_carriage": 0.15,
		"base_color": Color(0.96, 0.95, 0.92),
		"secondary_color": Color(0.13, 0.13, 0.14),
		"marking_color": Color(0.13, 0.13, 0.14),
		"marking_style": "solid",
		"marking_offset": Vector2(0.0, 0.0),
		"marking_scale": Vector2(1.0, 1.0),
	},
	"brutus": {
		"id": "brutus",
		"name": "Brutus",
		"size_scale": 1.28,
		"body_size": Vector2(10.5, 7.0),
		"head_radius": 6.6,
		"muzzle_size": Vector2(3.4, 3.4),
		"ear_style": "rose",
		"ear_size": Vector2(3.2, 2.8),
		"ear_offset": Vector2(-2.0, 4.6),
		"tail_style": "whip",
		"tail_length": 8.0,
		"tail_thickness": 2.6,
		"tail_carriage": 0.2,
		"base_color": Color(0.40, 0.29, 0.20),
		"secondary_color": Color(0.27, 0.19, 0.13),
		"marking_color": Color(0.20, 0.14, 0.10),
		"marking_style": "brindle",
		"marking_offset": Vector2(-0.5, 0.0),
		"marking_scale": Vector2(16.0, 6.4),
	},
	"guard": {
		"id": "guard",
		"name": "Guard dog",
		"size_scale": 1.3,
		"body_size": Vector2(11.0, 7.0),
		"head_radius": 6.4,
		"muzzle_size": Vector2(3.8, 3.2),
		"ear_style": "fold",
		"ear_size": Vector2(3.2, 3.4),
		"ear_offset": Vector2(-1.2, 4.6),
		"tail_style": "straight",
		"tail_length": 3.5,
		"tail_thickness": 3.0,
		"tail_carriage": 0.0,
		"base_color": Color(0.15, 0.13, 0.13),
		"secondary_color": Color(0.11, 0.10, 0.10),
		"marking_color": Color(0.72, 0.46, 0.22),
		"marking_style": "blaze_points",
		"marking_offset": Vector2(1.0, 0.0),
		"marking_scale": Vector2(3.0, 3.0),
	},
}

# What a profile's numbers cannot say: the face, the coat's texture, the leg
# length, the collar. Drawing only, keyed by profile id; a profile without an
# entry draws plainly.
#   legs: paw spread and reach (short dachshund 0.55, long greyhound 1.5)
#   coat: "smooth" | "fluffy" | "curly" | "wire"
#   head, muzzle, tail: colours that differ from the body
#   face: "white" a husky's white face and dark cap, "brows" tan points
#   mask: a band across the eyes; spots: dalmatian spots; studs: collar studs
#   eyes: iris colour where it shows; wrinkles: a pug's forehead
const LOOKS := {
	"compact_point_ear": {"legs": 0.9, "coat": "wire", "head": Color(0.74, 0.50, 0.27),
		"muzzle": Color(0.95, 0.93, 0.87), "collar": Color(0.82, 0.20, 0.18)},
	"long_low_drop_ear": {"legs": 0.55, "muzzle": Color(0.55, 0.27, 0.12),
		"collar": Color(0.26, 0.60, 0.40)},
	"tall_narrow_rose_ear": {"legs": 1.5, "muzzle": Color(0.62, 0.48, 0.34),
		"collar": Color(0.28, 0.44, 0.78), "collar_w": 2.2},
	"stocky_fold_ear": {"legs": 0.7, "tail": Color(0.86, 0.72, 0.52),
		"muzzle": Color(0.17, 0.14, 0.13), "wrinkles": true, "collar": Color(0.20, 0.66, 0.66)},
	"fluffy_curl_tail": {"legs": 1.0, "coat": "fluffy", "face": "white",
		"muzzle": Color(0.95, 0.95, 0.93), "eyes": Color(0.45, 0.72, 0.98),
		"collar": Color(0.86, 0.24, 0.20)},
	"shaggy_drop_ear": {"legs": 1.2, "coat": "curly", "muzzle": Color(0.93, 0.76, 0.58),
		"collar": Color(0.56, 0.34, 0.72)},
	"sturdy_otter_tail": {"legs": 1.1, "collar": Color(0.95, 0.56, 0.14)},
	"spotted_drop_ear": {"legs": 1.25, "spots": true, "tail": Color(0.96, 0.95, 0.92),
		"collar": Color(0.84, 0.22, 0.24)},
	"brutus": {"legs": 1.0, "mask": Color(0.09, 0.07, 0.07), "studs": true,
		"collar": Color(0.10, 0.09, 0.09), "collar_w": 2.6, "muzzle": Color(0.30, 0.22, 0.16)},
	"guard": {"legs": 1.0, "face": "brows", "muzzle": Color(0.72, 0.46, 0.22),
		"collar": Color(0.62, 0.62, 0.66), "collar_w": 2.4, "studs": true},
}
# where a dalmatian's spots sit, in body half-extents (x along, y across)
const SPOTS := [
	Vector2(0.55, -0.35), Vector2(0.20, 0.45), Vector2(-0.15, -0.55), Vector2(-0.45, 0.10),
	Vector2(-0.70, -0.30), Vector2(0.35, 0.05), Vector2(-0.30, 0.60), Vector2(0.75, 0.40),
	Vector2(-0.05, -0.10),
]


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


# A dog seen from straight above, in soft plasticine: paws poking out under
# the body, the body, the head, the face. Only filled circles, polygons and
# wide lines, so a ShapeBatch standing in for `canvas` draws the whole dog in
# one call. `bob` is the stride's sine (scaled to MAX_BOB), which also swings
# the paws; `mouth` (0..1) opens the jaw for a bark.
# how far ahead of the dog's center draw_dog puts the collar, for a leash
# clipped to it
static func collar_reach(profile: Dictionary) -> float:
	var p := profile
	if not validation_errors(p).is_empty():
		p = get_profile(String(PROFILE_IDS[0]))
	var s: float = p["size_scale"]
	var bs: Vector2 = p["body_size"] * s
	var hr: float = p["head_radius"] * s
	return bs.x * 0.80 + hr * 0.45 - hr * 0.80


static func draw_dog(
	canvas: Object,
	profile: Dictionary,
	origin: Vector2,
	forward: Vector2,
	bob: float,
	wag_phase: float,
	mouth := 0.0
) -> void:
	if (
		not _is_finite_vector(origin)
		or not is_finite(bob)
		or not is_finite(wag_phase)
	):
		return
	var p := profile
	if not validation_errors(p).is_empty():
		p = get_profile(String(PROFILE_IDS[0]))
	var look: Dictionary = LOOKS.get(String(p["id"]), {})

	var fwd := forward
	if not _is_finite_vector(fwd) or fwd.is_zero_approx():
		fwd = Vector2.RIGHT
	else:
		fwd = fwd.normalized()
	var side := fwd.orthogonal()
	var bob_c := clampf(bob, -MAX_BOB, MAX_BOB)
	var o := origin + Vector2(0.0, bob_c)
	var s: float = p["size_scale"]
	var bs: Vector2 = p["body_size"] * s
	var hr: float = p["head_radius"] * s
	var mz: Vector2 = p["muzzle_size"] * s
	var ear: Vector2 = p["ear_size"] * s
	var ear_off: Vector2 = p["ear_offset"] * s
	var tl: float = p["tail_length"] * s
	var tw: float = p["tail_thickness"] * s
	var base: Color = p["base_color"]
	var sec: Color = p["secondary_color"]
	var mark: Color = p["marking_color"]
	var head_col: Color = look.get("head", base)
	var muzzle_col: Color = look.get("muzzle", base.darkened(0.06))
	var tail_col: Color = look.get("tail", sec)
	var legs: float = look.get("legs", 1.0)
	var coat: String = look.get("coat", "smooth")
	var dark := Color(0.08, 0.07, 0.06)
	# the stride: diagonal pairs swing together
	var ph := bob_c / MAX_BOB
	var head_c := Vector2(bs.x * 0.80 + hr * 0.45, 0.0)

	# paws, under everything
	var pr := clampf(bs.y * 0.30, 1.4, 2.8)
	var paw_col: Color = look.get("paw", base.darkened(0.14))
	var reach := bs.x * 0.58 + pr * maxf(0.0, legs - 1.0) * 1.6
	var spread := bs.y * 0.70 + pr * 0.55 * legs
	var swing := ph * bs.x * 0.16 * legs
	for k in range(4):
		var front := k < 2
		var sd := 1.0 if k % 2 == 0 else -1.0
		var sw := swing * sd * (1.0 if front else -1.0)
		var lp := Vector2((reach if front else -reach) + sw, spread * sd)
		canvas.draw_circle(_pt(o, fwd, side, lp), pr, paw_col)

	# the tail, which lies on the ground behind (a curl sits on the back)
	var style: String = p["tail_style"]
	var tail_base := Vector2(-bs.x * 0.90, 0.0)
	var a: float = float(p["tail_carriage"]) + sin(wag_phase) * 0.35
	var tdir := Vector2(-cos(a), sin(a))
	var tperp := Vector2(-tdir.y, tdir.x)
	match style:
		"straight":
			var tip := tail_base + tdir * tl
			var pts := PackedVector2Array([_pt(o, fwd, side, tail_base), _pt(o, fwd, side, tail_base.lerp(tip, 0.55)), _pt(o, fwd, side, tip)])
			Clay.stroke(canvas, pts, tw * 1.25, tw * 0.70, Clay.rim_of(tail_col))
			Clay.stroke(canvas, pts, tw * 0.85, tw * 0.40, tail_col)
			canvas.draw_circle(pts[2], tw * 0.35, Clay.rim_of(tail_col))
		"whip":
			var pts := PackedVector2Array()
			for i in range(5):
				var f := float(i) / 4.0
				var bend := sin(wag_phase - f * 2.4) * f * tl * 0.22
				pts.append(_pt(o, fwd, side, tail_base + tdir * (tl * f) + tperp * bend))
			Clay.stroke(canvas, pts, tw * 1.3, tw * 0.6, Clay.rim_of(tail_col))
			Clay.stroke(canvas, pts, tw * 0.9, tw * 0.3, tail_col)
		"plume":
			# a poodle's pompom on a slim stalk
			var tip := tail_base + tdir * tl
			var pts := PackedVector2Array([_pt(o, fwd, side, tail_base), _pt(o, fwd, side, tip)])
			Clay.stroke(canvas, pts, tw, tw * 0.8, tail_col.darkened(0.1))
			_curly_ball(canvas, _pt(o, fwd, side, tip), tw * 2.3, base)

	# the body, and the coat's texture around it
	var body_at := _pt(o, fwd, side, Vector2.ZERO)
	if coat == "fluffy" or coat == "wire":
		var n := 12 if coat == "fluffy" else 8
		var fr := bs.y * (0.34 if coat == "fluffy" else 0.24)
		for i in range(n):
			var ang := TAU * (float(i) + 0.5) / float(n)
			var lp := Vector2(cos(ang) * bs.x * 0.92, sin(ang) * bs.y * 0.92)
			var wp := _pt(o, fwd, side, lp)
			var lit := (wp - body_at).normalized().dot(Clay.LIGHT)
			canvas.draw_circle(wp, fr, Clay.rim_of(base) if lit > -0.2 else base)
	Clay.blob(canvas, body_at, bs, fwd, base)
	if coat == "curly":
		for cp: Vector2 in [Vector2(0.5, -0.4), Vector2(0.5, 0.4), Vector2(0.0, 0.0), Vector2(-0.5, -0.4), Vector2(-0.5, 0.4)]:
			_curly_ball(canvas, _pt(o, fwd, side, Vector2(cp.x * bs.x, cp.y * bs.y)), bs.y * 0.52, base)

	# markings on the coat
	match String(p["marking_style"]):
		"patch":
			var mo: Vector2 = p["marking_offset"] * s
			var ms: Vector2 = p["marking_scale"] * s
			Clay.patch(canvas, _pt(o, fwd, side, mo), ms, fwd, mark)
			Clay.patch(canvas, _pt(o, fwd, side, mo) - Clay.LIGHT * ms.y * 0.3, ms * 0.5, fwd, Clay.lit_of(mark))
		"brindle":
			var stripe := Color(mark, 0.70)
			for i in range(7):
				var f := -0.78 + float(i) * 0.26
				var hy := bs.y * 0.82 * sqrt(maxf(0.0, 1.0 - f * f))
				var a0 := _pt(o, fwd, side, Vector2(bs.x * f - 0.8 * s, -hy))
				var a1 := _pt(o, fwd, side, Vector2(bs.x * f + 0.8 * s, hy))
				canvas.draw_line(a0, a1, stripe, maxf(1.0, 1.1 * s))
	if look.get("spots", false):
		for i in range(SPOTS.size()):
			var sp: Vector2 = SPOTS[i]
			canvas.draw_circle(_pt(o, fwd, side, Vector2(sp.x * bs.x, sp.y * bs.y)),
				(0.9 + 0.35 * float(i % 3)) * s, sec)

	# a curled tail rides on the rump
	if style == "curl":
		var cr := tl * 0.36
		var cc := _pt(o, fwd, side, Vector2(-bs.x * 0.62, sin(wag_phase) * bs.y * 0.18))
		if coat == "fluffy":
			# a fluffy curl: a lighter underside showing through the swirl
			Clay.ball(canvas, cc, cr * 1.1, tail_col)
			canvas.draw_circle(cc + Clay.LIGHT * cr * 0.25, cr * 0.45, tail_col.lerp(mark, 0.45))
			canvas.draw_circle(cc + Clay.LIGHT * cr * 0.05, cr * 0.25, tail_col)
		else:
			Clay.ball(canvas, cc, cr, tail_col)
			canvas.draw_circle(cc + Clay.LIGHT * cr * 0.1, cr * 0.38, Clay.rim_of(tail_col))

	# the collar, where the neck meets the head
	var collar_col: Color = look.get("collar", Color(0.80, 0.25, 0.22))
	var cx := head_c.x - hr * 0.80
	var cw := minf(bs.y, hr) * 0.92
	var c0 := _pt(o, fwd, side, Vector2(cx, -cw))
	var c1 := _pt(o, fwd, side, Vector2(cx, cw))
	canvas.draw_line(c0, c1, collar_col, float(look.get("collar_w", 1.7)) * s)
	if look.get("studs", false):
		for f: float in [-0.6, 0.0, 0.6]:
			canvas.draw_circle(c0.lerp(c1, 0.5 + f * 0.5), 0.7 * s, Color(0.85, 0.85, 0.88))

	# the head
	var hc := _pt(o, fwd, side, head_c)
	Clay.ball(canvas, hc, hr, head_col)
	var face: String = look.get("face", "")
	if face == "white":
		# a husky's white face, with the dark cap running down between the eyes
		Clay.patch(canvas, _pt(o, fwd, side, head_c + Vector2(hr * 0.30, 0.0)), Vector2(hr * 0.68, hr * 0.80), fwd, mark)
		canvas.draw_colored_polygon(PackedVector2Array([
			_pt(o, fwd, side, head_c + Vector2(-hr * 0.7, -hr * 0.45)),
			_pt(o, fwd, side, head_c + Vector2(hr * 0.45, 0.0)),
			_pt(o, fwd, side, head_c + Vector2(-hr * 0.7, hr * 0.45)),
		]), head_col)
	elif face == "brows":
		for sd: float in [-1.0, 1.0]:
			canvas.draw_circle(_pt(o, fwd, side, head_c + Vector2(hr * 0.12, hr * 0.42 * sd)), maxf(0.9, hr * 0.17), mark)
	if look.get("wrinkles", false):
		for k in range(2):
			var wx := head_c.x + hr * (0.05 + 0.22 * float(k))
			canvas.draw_line(_pt(o, fwd, side, Vector2(wx, -hr * 0.30)), _pt(o, fwd, side, Vector2(wx + hr * 0.08, hr * 0.30)),
				Clay.rim_of(head_col), maxf(0.8, 0.6 * s))
	if coat == "curly":
		# the topknot
		_curly_ball(canvas, _pt(o, fwd, side, head_c - Vector2(hr * 0.25, 0.0)), hr * 0.62, base)

	# ears
	var es: String = p["ear_style"]
	for sd: float in [-1.0, 1.0]:
		var eb := head_c + Vector2(ear_off.x, ear_off.y * sd)
		match es:
			"point":
				var tri := PackedVector2Array([
					_pt(o, fwd, side, eb + Vector2(ear.x * 0.65, -ear.x * 0.15 * sd)),
					_pt(o, fwd, side, eb + Vector2(-ear.x * 0.65, -ear.x * 0.25 * sd)),
					_pt(o, fwd, side, eb + Vector2(-ear.y * 0.30, ear.y * 0.80 * sd)),
				])
				canvas.draw_colored_polygon(tri, sec)
				var inner := PackedVector2Array([
					tri[0].lerp(tri[2], 0.18).lerp(tri[1], 0.25),
					tri[1].lerp(tri[2], 0.18).lerp(tri[0], 0.25),
					tri[2].lerp(tri[0], 0.30).lerp(tri[1], 0.30),
				])
				canvas.draw_colored_polygon(inner, Color(0.86, 0.62, 0.58))
			"drop":
				var flap := eb + Vector2(-ear.x * 0.25, ear.y * 0.30 * sd + ph * 0.5 * sd)
				Clay.blob(canvas, _pt(o, fwd, side, flap), Vector2(ear.x * 0.62, ear.y * 0.48), fwd, sec)
			"rose":
				var fl := eb + Vector2(-ear.x * 0.55, ear.y * 0.22 * sd)
				var rdir := (fwd.rotated(0.5 * sd)).normalized()
				canvas.draw_colored_polygon(Clay.ellipse_pts(_pt(o, fwd, side, fl), Vector2(ear.x * 0.62, ear.y * 0.38), rdir, 12), Clay.rim_of(sec))
				canvas.draw_colored_polygon(Clay.ellipse_pts(_pt(o, fwd, side, fl) - Clay.LIGHT * 0.4, Vector2(ear.x * 0.45, ear.y * 0.25), rdir, 10), sec)
			"fold":
				var tri := PackedVector2Array([
					_pt(o, fwd, side, eb + Vector2(-ear.x * 0.65, -ear.y * 0.10 * sd)),
					_pt(o, fwd, side, eb + Vector2(ear.x * 0.55, -ear.y * 0.10 * sd)),
					_pt(o, fwd, side, eb + Vector2(ear.x * 0.35, ear.y * 0.80 * sd)),
				])
				canvas.draw_colored_polygon(tri, sec)
				canvas.draw_line(tri[0], tri[1], Clay.lit_of(sec), maxf(0.8, 0.5 * s))

	# the face: muzzle, mask, eyes, nose
	var mc := head_c + Vector2(hr * 0.82 + mz.x * 0.40, 0.0)
	var jaw := clampf(mouth, 0.0, 1.0)
	if jaw > 0.0:
		var open_at := _pt(o, fwd, side, mc + Vector2(mz.x * 0.45, 0.0))
		canvas.draw_colored_polygon(Clay.ellipse_pts(open_at, Vector2(mz.x * 0.35 + jaw * 2.2 * s, mz.y * 0.85), fwd, 12), Color(0.42, 0.10, 0.10))
		canvas.draw_circle(open_at + fwd * jaw * 1.2 * s, mz.y * 0.45, Color(0.92, 0.48, 0.52))
	Clay.blob(canvas, _pt(o, fwd, side, mc), Vector2(mz.x * 0.60, mz.y), fwd, muzzle_col)
	var eye_r := maxf(0.75, 0.85 * s)
	var mask_col: Variant = look.get("mask", null)
	if mask_col != null:
		canvas.draw_line(_pt(o, fwd, side, head_c + Vector2(hr * 0.32, -hr * 0.95)),
			_pt(o, fwd, side, head_c + Vector2(hr * 0.32, hr * 0.95)), mask_col, hr * 0.55)
	for sd: float in [-1.0, 1.0]:
		var ep := _pt(o, fwd, side, head_c + Vector2(hr * 0.34, hr * 0.44 * sd))
		if mask_col != null:
			canvas.draw_circle(ep, eye_r * 1.25, Color(0.96, 0.94, 0.88))
			canvas.draw_circle(ep + fwd * eye_r * 0.35, eye_r * 0.7, dark)
		elif look.has("eyes"):
			canvas.draw_circle(ep, eye_r * 1.1, look["eyes"])
			canvas.draw_circle(ep + fwd * eye_r * 0.2, eye_r * 0.55, dark)
		else:
			canvas.draw_circle(ep, eye_r, dark)
	var nose := _pt(o, fwd, side, mc + Vector2(mz.x * 0.55, 0.0))
	canvas.draw_circle(nose, maxf(1.0, minf(mz.y * 0.5, 1.6 * s)), dark)
	canvas.draw_circle(nose - Clay.LIGHT * 0.5, maxf(0.4, 0.4 * s), Color(0.45, 0.42, 0.40))


static func _pt(o: Vector2, fwd: Vector2, side: Vector2, lp: Vector2) -> Vector2:
	return o + fwd * lp.x + side * lp.y


# a tight curly tuft: a lump with a few lighter curls on it
static func _curly_ball(canvas: Object, at: Vector2, r: float, col: Color) -> void:
	Clay.ball(canvas, at, r, col)
	var lit := Clay.lit_of(col)
	for k in range(3):
		var ang := -2.2 + float(k) * 1.1
		canvas.draw_circle(at + Vector2.from_angle(ang) * r * 0.45, r * 0.26, lit)
