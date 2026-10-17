class_name HumanSide
extends RefCounted

# Your human seen from the side, for the intro, in the intro's cartoon look:
# one bold warm-black outline round the silhouette, flat fills, one hard cel
# shadow on the side away from the light (upper left) and one crisp highlight.
# Facing +x, feet on y = 0, about 200 tall at scale 1. Draw it under a
# transform for position, flip and squash (c.draw_set_transform), at the origin.
# Pose keys (all optional): sit (0..1), lean (torso tilt, + forward), stride
# (walk phase, radians), stride_amp (0..1), phone (0..1, phone up at the face),
# reach (0..1, the other arm out forward holding the leash), reach_down (0..1,
# that arm down to the knee), lift (0..1, feet off the ground and trailing, for
# being yanked), head (head tilt), mouth (0..1, open), glow (0..1, the phone
# lighting the face), phone_jolt (0..1), scroll (thumb phase), blink.
#
# The whole figure is one triangle list and one draw call. It is drawn every
# frame, on the web too, so the per-frame work is kept to native transforms:
# - limbs are capsules (two circles and a quad) and hands are ellipses, all
#   from one unit circle fan; an outline is the same shape grown, and the cel
#   shadow is the shape in shadow with the lit shape, shrunk and moved toward
#   the light, laid over it;
# - the drawn outlines (torso, face, hair, sneaker, open hand) are triangulated
#   once, with their outlines, shadows and highlights, in their own frame, per
#   one of 64 light directions, and cached.

const OUT := Color(0.10, 0.07, 0.08)
const SKIN := Color(0.95, 0.77, 0.62)
const HAIR := Color(0.42, 0.25, 0.15)
const SHIRT := Color(0.24, 0.45, 0.78)
const TROUSERS := Color(0.25, 0.27, 0.36)
const SHOE := Color(0.95, 0.93, 0.88)
const SOLE := Color(0.80, 0.70, 0.60)
const STRIPE := Color(0.84, 0.24, 0.24)
const PHONE := Color(0.16, 0.16, 0.20)
const SCREEN := Color(0.80, 0.93, 1.0)
const LIGHT := Vector2(-0.6, -0.8)
const OW := 2.0      # silhouette outline, in puppet units (about 3 px in the film)
const IW := 1.6      # the outline of parts laid over the body (arms, hair)
const SEGMENTS := 18 # of the unit circle every round part is made from
const LIGHT_STEPS := 64

# the shirt's body in its own frame: u forward, v up from the hip; a slumped back
const TORSO := [Vector2(-15, -9), Vector2(-19, 4), Vector2(-21, 20), Vector2(-21, 36), Vector2(-19, 50),
	Vector2(-14.5, 63), Vector2(-7, 70.5), Vector2(1.5, 72.5), Vector2(9, 70), Vector2(14, 63), Vector2(16.5, 52),
	Vector2(17.5, 40), Vector2(17, 28), Vector2(18, 14), Vector2(19, 2), Vector2(16, -8), Vector2(4, -11.5),
	Vector2(-8, -11.5)]
# the head in profile, x forward, y down, about the head centre; the jaw points
# (13..17) drop when the mouth opens
const FACE := [Vector2(-2, -21), Vector2(7, -19.5), Vector2(13, -14.5), Vector2(16, -7.5), Vector2(16.6, -3.5),
	Vector2(15.6, -0.5), Vector2(17.2, 3), Vector2(20.6, 6.4), Vector2(22.4, 8.6), Vector2(21.2, 10.6),
	Vector2(18.6, 11.2), Vector2(18.8, 13.2), Vector2(17.6, 14.6), Vector2(18.2, 16.2), Vector2(16.2, 18.2),
	Vector2(16.8, 20.6), Vector2(14.2, 23), Vector2(8, 23.6), Vector2(1, 20.5), Vector2(-5, 14), Vector2(-12, 10),
	Vector2(-17, 2), Vector2(-18, -7), Vector2(-14, -15), Vector2(-8, -19.5)]
# a swept quiff with the fringe over the brow, a sideburn, and a short nape
const HAIRDO := [Vector2(19.5, -12.5), Vector2(16, -10.8), Vector2(11, -10.6), Vector2(6, -11.6), Vector2(2, -9.5),
	Vector2(0.4, -5.5), Vector2(1.6, -0.5), Vector2(-0.6, 1.2), Vector2(-3, -3), Vector2(-7, -3.8), Vector2(-9.5, 2),
	Vector2(-10.5, 9), Vector2(-13.5, 11), Vector2(-17.5, 6), Vector2(-20.5, -4), Vector2(-19.5, -13.5),
	Vector2(-14.5, -21.5), Vector2(-5, -26), Vector2(5, -25.5), Vector2(13, -21.5), Vector2(18.5, -17.5),
	Vector2(21, -14.5)]
const HAIR_SHINE := [Vector2(-15, -17.5), Vector2(-6, -22.6), Vector2(4, -22.6), Vector2(11, -19.6),
	Vector2(3, -20.4), Vector2(-6, -20.2)]
# a sneaker about the ankle: x along the foot, y down to the sole
const SNEAKER := [Vector2(-6, -5), Vector2(-1, -6.5), Vector2(4, -5), Vector2(9, -2.5), Vector2(15, -0.6),
	Vector2(19, 1.4), Vector2(20.6, 3.6), Vector2(19.6, 6), Vector2(-6.4, 6), Vector2(-8, 3), Vector2(-7.6, -1)]
const SNEAKER_SOLE := [Vector2(-7.9, 3.4), Vector2(20.4, 3.4), Vector2(20.5, 4), Vector2(19.6, 6), Vector2(-6.4, 6),
	Vector2(-8, 3.4)]
const SNEAKER_STRIPE := [Vector2(0.5, -3.8), Vector2(3.5, -4.2), Vector2(10, 2.6), Vector2(6.6, 2.8)]
const OPEN_HAND := [Vector2(-2, -4.5), Vector2(4, -4.6), Vector2(9, -3.4), Vector2(11.5, -1), Vector2(11, 2),
	Vector2(7, 3.8), Vector2(1, 4.2), Vector2(-2.5, 3)]
const PHONE_BODY := [Vector2(-4, -11), Vector2(3.5, -11), Vector2(3.5, 11), Vector2(-4, 11)]

# cache keys: shape * 100000 + variant * 100 + light step
enum { K_TORSO = 1, K_FACE, K_HAIR, K_SNEAKER, K_HAND, K_MOUTH, K_GLOW, K_STATIC }

static var _v := PackedVector2Array()    # the frame's triangle list
static var _col := PackedColorArray()
static var _circle := PackedVector2Array()
static var _cache := {}


# ------------------------------------------------------------------ geometry

static func _shade(c: Color) -> Color:
	# shadows go cool and a little purple, never grey
	return Color(c.r * 0.72, c.g * 0.64, c.b * 0.80, c.a)


static func _hi(c: Color) -> Color:
	return c.lerp(Color(1.0, 0.97, 0.88), 0.4)


static func _far(c: Color) -> Color:
	return c.lerp(_shade(c), 0.55)


# a two-bone limb from root, bending at the middle by `bend` (+ is forward)
static func _two(root: Vector2, dir: Vector2, l1: float, l2: float, bend: float) -> Array:
	var mid := root + dir * l1
	var end := mid + dir.rotated(bend) * l2
	return [root, mid, end]


static func _push(tris: PackedVector2Array, col: Color) -> void:
	var n := tris.size()
	if n == 0:
		return
	_v.append_array(tris)
	var cs := PackedColorArray()
	cs.resize(n)
	cs.fill(col)
	_col.append_array(cs)


static func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	_push(PackedVector2Array([a, b, c, a, c, d]), col)


static func _line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var n := (b - a).normalized().orthogonal() * (w * 0.5)
	_quad(a + n, b + n, b - n, a - n, col)


static func _ellipse(c: Vector2, r: Vector2, rot: float, col: Color) -> void:
	_push(Transform2D(rot, r, 0.0, c) * _circle, col)


# the hull of two circles: both circles and the quad between their tangents
static func _capsule(a: Vector2, b: Vector2, ra: float, rb: float, col: Color) -> void:
	_push(Transform2D(0.0, Vector2(ra, ra), 0.0, a) * _circle, col)
	_push(Transform2D(0.0, Vector2(rb, rb), 0.0, b) * _circle, col)
	var l := a.distance_to(b)
	if l <= absf(ra - rb) + 0.001:
		return
	var d := (b - a) / l
	var s := (ra - rb) / l
	var co := sqrt(1.0 - s * s)
	var n := d.orthogonal()
	var u1 := n * co + d * s
	var u2 := -n * co + d * s
	_quad(a + u1 * ra, b + u1 * rb, b + u2 * rb, a + u2 * ra, col)


# a triangle list for a simple polygon (only when building the cache)
static func _tris(p: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in Geometry2D.triangulate_polygon(p):
		out.append(p[i])
	return out


static func _tris_all(polys: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: PackedVector2Array in polys:
		out.append_array(_tris(p))
	return out


static func _ell_pts(c: Vector2, r: Vector2, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


# a drawn shape in its own frame, for the light falling along `light` in that
# frame: its fill, cel shadow (the shape minus itself moved toward the light),
# highlight (an inset sliver on the lit side, cut to the circle hc, hr) and its
# outlines, all as triangle lists. Built once per light step and kept.
static func _shape(kind: int, variant: int, pts: PackedVector2Array, light: Vector2, k: float, hl := 0.0,
		hc := Vector2.ZERO, hr := 0.0) -> Dictionary:
	var step := posmod(roundi(light.angle() / TAU * LIGHT_STEPS), LIGHT_STEPS)
	var key := kind * 100000 + variant * 100 + step
	if _cache.has(key):
		return _cache[key]
	var lt := Vector2.from_angle(float(step) * TAU / LIGHT_STEPS)
	var e := {"fill": _tris(pts), "shadow": PackedVector2Array(), "hl": PackedVector2Array()}
	if k > 0.0:
		e["shadow"] = _tris_all(Geometry2D.clip_polygons(pts, Transform2D(0.0, lt * k) * pts))
	if hl > 0.0:
		var inset := Geometry2D.offset_polygon(pts, -1.3)
		if not inset.is_empty():
			var ip: PackedVector2Array = inset[0]
			var sl := PackedVector2Array()
			for q: PackedVector2Array in Geometry2D.clip_polygons(ip, Transform2D(0.0, -lt * hl) * ip):
				if hr > 0.0:
					sl.append_array(_tris_all(Geometry2D.intersect_polygons(q, _ell_pts(hc, Vector2(hr, hr)))))
				else:
					sl.append_array(_tris(q))
			e["hl"] = sl
	for w: float in [OW, IW, 1.4, 1.0]:
		e[w] = _tris_all(Geometry2D.offset_polygon(pts, w, Geometry2D.JOIN_ROUND))
	_cache[key] = e
	return e


# the light's direction in a frame with axes ax, ay
static func _light_in(ax: Vector2, ay: Vector2) -> Vector2:
	return Vector2(LIGHT.dot(ax), LIGHT.dot(ay))


# a part: ["c", a, b, ra, rb, colour, shadow, shine] a capsule;
# ["e", centre, radii, rotation, colour, shadow] an ellipse;
# ["p", cached shape, frame, colour, shine] a drawn shape.
# A group inks all its outlines first, then fills, so only its silhouette is
# outlined; a later group's outline separates it from this one.
static func _group(parts: Array, w: float) -> void:
	for pr: Array in parts:
		match pr[0]:
			"c":
				_capsule(pr[1], pr[2], pr[3] + w, pr[4] + w, OUT)
			"e":
				_ellipse(pr[1], pr[2] + Vector2(w, w), pr[3], OUT)
			"p":
				_push((pr[2] as Transform2D) * (pr[1][w] as PackedVector2Array), OUT)
	for pr: Array in parts:
		match pr[0]:
			"c":
				var k: float = pr[6]
				var s := LIGHT * (k * 0.5)
				_capsule(pr[1], pr[2], pr[3], pr[4], _shade(pr[5]))
				_capsule(pr[1] + s, pr[2] + s, pr[3] - k * 0.5, pr[4] - k * 0.5, pr[5])
				if pr[7] > 0.0:
					_cap_shine(pr[1], pr[2], pr[3] - 1.3, pr[7], _hi(pr[5]))
			"e":
				var k: float = pr[5]
				_ellipse(pr[1], pr[2], pr[3], _shade(pr[4]))
				_ellipse(pr[1] + LIGHT * (k * 0.5), pr[2] - Vector2(k, k) * 0.5, pr[3], pr[4])
			"p":
				var xf: Transform2D = pr[2]
				_push(xf * (pr[1]["fill"] as PackedVector2Array), pr[3])
				_push(xf * (pr[1]["shadow"] as PackedVector2Array), _shade(pr[3]))
				if pr[4]:
					_push(xf * (pr[1]["hl"] as PackedVector2Array), _hi(pr[3]))


# the highlight on a capsule's rounded end at a: a crescent along the lit
# side of its cap, thinning to nothing where the cap meets the straight side
static func _cap_shine(a: Vector2, b: Vector2, r: float, hl: float, col: Color) -> void:
	var axis := (b - a).normalized()
	var lit := LIGHT.angle()
	var prev_o := Vector2.ZERO
	var prev_i := Vector2.ZERO
	var have := false
	for i in range(9):
		var ph := deg_to_rad(-68.0 + 17.0 * float(i))
		var u := Vector2.from_angle(lit + ph)
		if u.dot(axis) > 0.0:
			have = false
			continue
		var o := a + u * r
		var inn := a + u * (r - hl * cos(ph))
		if have:
			_quad(prev_o, o, inn, prev_i, col)
		prev_o = o
		prev_i = inn
		have = true


static func _frame(o: Vector2, ax: Vector2, ay: Vector2) -> Transform2D:
	return Transform2D(ax, ay, o)


static func _static(kind: int, pts: Array) -> PackedVector2Array:
	var key := K_STATIC * 100000 + kind
	if not _cache.has(key):
		_cache[key] = _tris(PackedVector2Array(pts))
	return _cache[key]


# ------------------------------------------------------------------ the parts

# a leg's parts (sneaker, shin, thigh) and what its details need
static func _leg(leg: Array, lift: float, far: bool) -> Array:
	var thigh_d: Vector2 = (leg[1] - leg[0]).normalized()
	var shin_d: Vector2 = (leg[2] - leg[1]).normalized()
	# flat on the floor, or hanging slack off the ankle, toes down and back,
	# when the feet trail behind
	var foot := Vector2.from_angle(lerp_angle(0.0, shin_d.rotated(-1.3).angle(), lift))
	var fy := foot.rotated(PI * 0.5)
	var tr := TROUSERS if not far else _far(TROUSERS)
	var sh := SHOE if not far else _far(SHOE)
	var shoe_e := _shape(K_SNEAKER, 0, PackedVector2Array(SNEAKER), _light_in(foot, fy), 2.0, 1.6, Vector2(14, 0), 6.0)
	var shoe := ["p", shoe_e, _frame(leg[2], foot, fy), sh, not far]
	var shin := ["c", leg[1], leg[2] + shin_d * 1.5 * (1.0 - lift), 9.5, 8.0, tr, 2.4, 0.0]
	var thigh := ["c", leg[0], leg[1], 13.0, 9.5, tr, 2.6, 0.0]
	# the hem covers the shoe's collar on the floor; a trailing shoe is laid
	# over the hem so it is not lost inside the trouser leg
	if lift > 0.5:
		return [thigh, shin, shoe, thigh_d, shin_d, foot, far]
	return [shoe, shin, thigh, thigh_d, shin_d, foot, far]


static func _leg_detail(leg: Array, info: Array) -> void:
	var thigh_d: Vector2 = info[3]
	var shin_d: Vector2 = info[4]
	var foot: Vector2 = info[5]
	var far: bool = info[6]
	var tr := TROUSERS if not far else _far(TROUSERS)
	var ink := _shade(_shade(tr))
	var fy := foot.rotated(PI * 0.5)
	var xf := _frame(leg[2], foot, fy)
	_push(xf * _static(1, SNEAKER_SOLE), _far(SOLE) if far else SOLE)
	_push(xf * _static(2, SNEAKER_STRIPE), _far(STRIPE) if far else STRIPE)
	_line(leg[2] + foot * 13.0 + fy * -0.6, leg[2] + foot * 14.4 + fy * 3.4, OUT, 1.1)
	_line(leg[2] + foot * -7.6 + fy * 3.4, leg[2] + foot * 20.4 + fy * 3.4, OUT, 1.1)
	# the trouser hem over the shoe, and the crease behind a bent knee
	var across := shin_d.orthogonal()
	var hem: Vector2 = leg[2] - shin_d * 1.5
	_line(hem - across * 7.6, hem + across * 7.6, ink, 1.3)
	var into := shin_d - thigh_d
	if into.length() > 0.5:
		into = into.normalized()
		var pit: Vector2 = leg[1] + into * 6.0
		_line(pit, pit - thigh_d * 6.0 - into * 1.6, ink, 1.3)
		_line(pit, pit + shin_d * 5.0 - into * 1.6, ink, 1.3)


# an arm: bare skin, a T-shirt sleeve over its top with a hem, and a hand
# (grip 1: a fist; 0: a relaxed open hand; -1: a palm cupping the phone)
static func _arm(sj: Vector2, elbow: Vector2, hand: Vector2, grip: float, far: bool) -> Array:
	var sk := SKIN if not far else _far(SKIN)
	var st := SHIRT if not far else _far(SHIRT)
	var d := (hand - elbow).normalized()
	var n := d.rotated(PI * 0.5)
	var hem := sj.lerp(elbow, 0.55)
	var hand_part: Array
	if grip > 0.5:
		hand_part = ["e", hand + d * 1.5, Vector2(6.4, 5.6), d.angle(), sk, 1.6]
	elif grip < -0.5:
		hand_part = ["e", hand, Vector2(5.6, 5.0), d.angle(), sk, 1.6]
	else:
		hand_part = ["p", _shape(K_HAND, 0, PackedVector2Array(OPEN_HAND), _light_in(d, n), 1.6),
			_frame(hand - d * 1.0, d, n), sk, false]
	var parts := [
		["c", sj, elbow, 6.4, 5.6, sk, 1.8, 0.0],
		["c", elbow, hand - d * 2.0, 5.6, 4.6, sk, 1.6, 0.0],
		hand_part,
		["c", sj, hem, 9.6, 7.6, st, 2.6, 0.0 if far else 2.2],
	]
	return [parts, hem, (elbow - sj).normalized(), d, n, grip, hand, sk]


# a small inked capsule laid over others (a thumb, a finger)
static func _inked_cap(a: Vector2, b: Vector2, ra: float, rb: float, col: Color) -> void:
	_capsule(a, b, ra + 1.1, rb + 1.1, OUT)
	_capsule(a, b, ra, rb, col)


static func _arm_detail(info: Array) -> void:
	var hem: Vector2 = info[1]
	var ud: Vector2 = info[2]
	var d: Vector2 = info[3]
	var n: Vector2 = info[4]
	var grip: float = info[5]
	var hand: Vector2 = info[6]
	var sk: Color = info[7]
	var across := ud.orthogonal()
	_line(hem - across * 7.6 - ud * 1.0, hem + across * 7.6 - ud * 1.0, _shade(_shade(SHIRT)), 1.6)
	if grip > 0.5:
		# knuckles, and the thumb wrapped over the fingers
		var kc := hand + d * 5.2
		_line(kc - n * 3.0, kc + n * 1.5, _shade(_shade(sk)), 1.1)
		_inked_cap(hand - d * 2.0 - n * 4.6, hand + d * 4.0 - n * 3.6, 2.3, 2.0, sk)
	elif grip > -0.5:
		# the thumb, out ahead of the open hand, and a finger line
		_inked_cap(hand + d * 1.0 - n * 3.6, hand + d * 5.6 - n * 6.2, 2.3, 1.9, sk)
		_line(hand + d * 5.0 + n * 0.6, hand + d * 9.5 + n * 0.4, _shade(_shade(sk)), 1.0)


# returns the hand that holds the leash (in the puppet's own units)
static func draw(c: CanvasItem, pose: Dictionary) -> Vector2:
	var sit: float = pose.get("sit", 0.0)
	var lean: float = pose.get("lean", 0.0)
	var phase: float = pose.get("stride", 0.0)
	var amp: float = pose.get("stride_amp", 0.0)
	var phone: float = pose.get("phone", 1.0)
	var reach: float = pose.get("reach", 0.0)
	var reach_down: float = pose.get("reach_down", 0.0)
	var lift: float = pose.get("lift", 0.0)
	var head_t: float = pose.get("head", 0.0)
	var glow: float = pose.get("glow", 0.0)
	var jolt: float = pose.get("phone_jolt", 0.0)
	# the jaw opens in eighths, so each opening is one cached face
	var mouth_q := clampi(roundi(float(pose.get("mouth", 0.0)) * 8.0), 0, 8)
	var mouth := float(mouth_q) / 8.0
	if _circle.is_empty():
		for i in range(SEGMENTS):
			_circle.append(Vector2.ZERO)
			_circle.append(Vector2.from_angle(TAU * float(i) / SEGMENTS))
			_circle.append(Vector2.from_angle(TAU * float(i + 1) / SEGMENTS))
	_v.clear()
	_col.clear()
	# leaning back against a pull, standing, the feet go out ahead of the hips
	# and dig in; the hips drop to keep the soles on the floor
	var brace := maxf(0.0, -lean) * 0.4 * (1.0 - sit) * (1.0 - lift)
	var hip := Vector2(0.0, lerpf(-100.0, -58.0, sit) + 98.0 * (1.0 - cos(brace)))
	var up := Vector2.UP.rotated(lean)
	var fwd := up.rotated(PI * 0.5)
	var shoulder := hip + up * 62.0
	# the neck juts forward and the head tips down into the phone: the stoop
	# of someone who has not looked up in an hour
	head_t += 0.75 * phone
	var neck_top := shoulder + up.rotated(0.35 * phone) * 14.0
	var head := neck_top + up.rotated(head_t * 0.6) * 18.0 + Vector2(5, 0)
	var hr := head_t * 0.6
	var hx := Vector2.RIGHT.rotated(hr)
	var hy := Vector2.DOWN.rotated(hr)
	var hxf := _frame(head, hx, hy)
	var legs := []
	for side in range(2):
		var ph := phase + PI * float(side)
		var swing := sin(ph) * 0.55 * amp
		var thigh_dir := Vector2.DOWN.rotated(-swing - brace).lerp(Vector2.RIGHT, sit).normalized()
		var bend := maxf(0.0, -cos(ph)) * 0.9 * amp + sit * 1.45
		if lift > 0.0:
			# trailing out behind, the far leg further, whipping as they go
			thigh_dir = thigh_dir.lerp(Vector2(-0.85, 0.5).normalized(), lift).normalized()
			bend = lerpf(bend, 0.35 + 0.35 * float(side) + sin(phase * 2.0) * 0.25, lift)
		legs.append(_two(hip + Vector2(4.0 * float(side) - 2.0, 0), thigh_dir, 48.0, 50.0, bend))
	# the phone held up near the chin, elbow down, the screen tipped to the face
	var phone_at := (Vector2(40, 30) * phone + Vector2(14, 58) * (1.0 - phone)) + Vector2(14, -12) * jolt
	var phone_hand := shoulder + phone_at.rotated(lean)
	var elbow := shoulder + Vector2(10, 30).rotated(lean)
	# the free arm: hanging, out ahead on the leash, or down to the floor
	var free_dir := Vector2.DOWN.rotated(-0.2).lerp(Vector2.RIGHT.rotated(0.12), reach).normalized()
	free_dir = free_dir.lerp(Vector2(0.55, 0.85).normalized(), reach_down).normalized()
	var arm2 := _two(shoulder + Vector2(-2, 4), free_dir, 34.0, 32.0, -0.3 * (1.0 - reach) * (1.0 - reach_down))
	# both arms hang from one shoulder joint, just under the top of the shirt
	var sj := hip + up * 57.0 - fwd * 1.0
	var grip := 1.0 if reach >= 0.45 or (reach > 0.2 and reach_down < 0.3) else 0.0
	var arm_free := _arm(sj, arm2[1], arm2[2], grip, reach <= 0.25)
	var arm_phone := _arm(sj, elbow, phone_hand, -1.0 if phone > 0.3 else 0.0, false)

	# ---------------------------------------------------------- far side
	var far_leg := _leg(legs[1], lift, true)
	var back := [far_leg[0], far_leg[1], far_leg[2]]
	if reach <= 0.25:
		back.append_array(arm_free[0])
	_group(back, OW)
	_leg_detail(legs[1], far_leg)
	if reach <= 0.25:
		_arm_detail(arm_free)

	# ---------------------------------------------------------- the body
	var near_leg := _leg(legs[0], lift, false)
	var torso := _shape(K_TORSO, 0, PackedVector2Array(TORSO), _light_in(fwd, up), 4.0, 3.0, Vector2(-14, 52), 13.0)
	var jaw := Vector2(-1.5, 5.0) * mouth
	# the seat of the trousers: low and round on the sofa, tucked in standing
	var rump := ["c", hip + fwd * -3.0 - up * (2.0 + 9.0 * sit), hip + fwd * 6.0 - up * (2.0 + 7.0 * sit),
		lerpf(12.0, 13.0, sit), lerpf(11.0, 12.0, sit), TROUSERS, 2.6, 0.0]
	var neck := ["c", shoulder + up * 3.0 + fwd * 2.5, head + hx * 1.0 + hy * 13.0, 8.6, 7.4, SKIN, 2.5, 0.0]
	_group([near_leg[0], near_leg[1], near_leg[2], rump, neck, ["p", torso, _frame(hip, fwd, up), SHIRT, true]], OW)
	_leg_detail(legs[0], near_leg)
	# the shirt: its hem over the trousers, a crew collar, folds at the belly
	var sdk := _shade(_shade(SHIRT))
	var txf := _frame(hip, fwd, up)
	_line(txf * Vector2(-15.0, -6.5), txf * Vector2(16.5, -5.5), sdk, 1.4)
	_line(txf * Vector2(-6.5, 69.0), txf * Vector2(1.5, 71.0), sdk, 3.0)
	_line(txf * Vector2(1.5, 71.0), txf * Vector2(8.0, 69.0), sdk, 3.0)
	_line(txf * Vector2(8.0, 69.0), txf * Vector2(12.0, 64.0), sdk, 3.0)
	_line(txf * Vector2(11.0, 22.0), txf * Vector2(17.0, 18.0), _shade(SHIRT), 1.4)
	_line(txf * Vector2(9.0, 12.0), txf * Vector2(16.0, 9.5), _shade(SHIRT), 1.4)
	# the leash arm, out ahead, passes in front of the body and behind the
	# head, so a face bowed over it (or yelling) stays in view
	if reach > 0.25:
		_group(arm_free[0], IW)
		_arm_detail(arm_free)
	var face_pts := PackedVector2Array(FACE)
	for i in range(13, 18):
		face_pts[i] += jaw * (0.6 if i == 17 else 1.0)
	# the open mouth is a notch in the profile, filled by the mouth below
	face_pts[12] = face_pts[12].lerp(Vector2(14.2, 15.4), mouth)
	var face := _shape(K_FACE, mouth_q, face_pts, _light_in(hx, hy), 2.2)
	_group([["p", face, hxf, SKIN, false]], OW)
	# the screen's cold light on the face: a crisp band down the brow, nose
	# and lips, on the side that faces it
	# (gone once they are hauled over and the screen no longer faces them)
	glow *= 1.0 - clampf((lean - 0.5) / 0.4, 0.0, 1.0)
	if glow > 0.0 and phone > 0.3:
		var gk := K_GLOW * 100000 + mouth_q
		if not _cache.has(gk):
			var band := PackedVector2Array()
			for q: PackedVector2Array in Geometry2D.clip_polygons(face_pts, Transform2D(0.0, Vector2(-2.4, 0)) * face_pts):
				band.append_array(_tris_all(Geometry2D.intersect_polygons(q, _ell_pts(Vector2(17, 3), Vector2(9, 12.5)))))
			_cache[gk] = band
		_push(hxf * (_cache[gk] as PackedVector2Array), SKIN.lerp(Color(0.74, 0.88, 1.0), 0.6 * glow))
	# the ear, the cheek, the nostril
	_ellipse(head + hx * -4.5 + hy * 3.0, Vector2(5.6, 7.2), hr, OUT)
	_ellipse(head + hx * -4.5 + hy * 3.0, Vector2(4.4, 6.0), hr, SKIN)
	_line(head + hx * -3.4 + hy * 0.4, head + hx * -4.6 + hy * 5.4, _shade(SKIN), 1.6)
	_ellipse(head + hx * 9.0 + hy * 8.0, Vector2(3.6, 2.4), hr, SKIN.lerp(Color(0.96, 0.52, 0.48), 0.45))
	_line(head + hx * 19.2 + hy * 9.0, head + hx * 20.4 + hy * 10.4, _shade(_shade(SKIN)), 1.1)
	# hair over the crown, a crisp shine along its top, the parting
	var hair := _shape(K_HAIR, 0, PackedVector2Array(HAIRDO), _light_in(hx, hy), 2.2)
	_group([["p", hair, hxf, HAIR, false]], IW)
	_push(hxf * _static(3, HAIR_SHINE), _hi(HAIR))
	_line(head + hx * 3.0 + hy * -24.0, head + hx * 15.0 + hy * -15.0, _shade(HAIR), 1.2)
	# the eye under a lowered lid, looking down into the screen; wide on the jolt
	var lid_y := -0.6 - 1.6 * jolt
	if pose.get("blink", 0.0) > 0.5:
		_line(hxf * Vector2(10.0, 0.4), hxf * Vector2(13.0, 1.2), OUT, 1.6)
		_line(hxf * Vector2(13.0, 1.2), hxf * Vector2(15.6, 0.6), OUT, 1.6)
	else:
		_quad(hxf * Vector2(10.2, lid_y + 0.2), hxf * Vector2(15.4, lid_y), hxf * Vector2(14.4, 1.5),
			hxf * Vector2(11.0, 1.3), Color(0.98, 0.96, 0.93))
		_ellipse(hxf * Vector2(13.6 - jolt * 0.6, 0.4 - jolt * 0.4), Vector2(1.5, 1.7) * (1.0 + 0.2 * jolt), hr, OUT)
		_line(hxf * Vector2(9.6, lid_y), hxf * Vector2(12.6, lid_y - 0.5), OUT, 1.8)
		_line(hxf * Vector2(12.6, lid_y - 0.5), hxf * Vector2(16.2, lid_y + 0.1), OUT, 1.8)
		_line(hxf * Vector2(10.4, lid_y - 2.2), hxf * Vector2(15.0, lid_y - 2.6), _shade(SKIN), 1.1)
	# the eyebrow, low and level while absorbed, shot up on the jolt
	var by := -6.4 - 2.6 * jolt
	_line(hxf * Vector2(9.6, by + 0.4), hxf * Vector2(13.2, by - 0.4 - jolt), _shade(HAIR), 2.4)
	_line(hxf * Vector2(13.2, by - 0.4 - jolt), hxf * Vector2(16.6, by + 0.2), _shade(HAIR), 2.4)
	# the mouth: a small flat line, absorbed, or open
	if mouth > 0.05:
		var m := _shape(K_MOUTH, mouth_q, PackedVector2Array([Vector2(19.0, 13.0), Vector2(14.0, 15.0),
			Vector2(13.8 + jaw.x * 0.5, 16.0 + jaw.y * 0.7), Vector2(17.6 + jaw.x, 16.6 + jaw.y)]), Vector2.RIGHT, 0.0)
		_push(hxf * (m[1.0] as PackedVector2Array), OUT)
		_push(hxf * (m["fill"] as PackedVector2Array), Color(0.30, 0.07, 0.09))
		_push(PackedVector2Array([hxf * Vector2(14.4 + jaw.x * 0.5, 15.6 + jaw.y * 0.7),
			hxf * Vector2(17.2 + jaw.x, 16.2 + jaw.y), hxf * Vector2(15.8 + jaw.x * 0.8, 14.8 + jaw.y * 0.7)]),
			Color(0.88, 0.42, 0.44))
	else:
		_line(hxf * Vector2(14.4, 14.4), hxf * Vector2(18.0, 14.6), _shade(_shade(SKIN)), 1.4)

	# ---------------------------------------------------------- the arms in front
	_group(arm_phone[0], IW)
	_arm_detail(arm_phone)
	if phone > 0.3:
		_phone(phone_hand, jolt, pose.get("scroll", 0.0), glow)
	RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(), PackedInt32Array(), _v, _col)
	return arm2[2]


# the phone in the cupped hand, edge on, its screen facing the face; fingers
# round the back edge, the thumb on the screen, scrolling
static func _phone(hand: Vector2, jolt: float, sc: float, glow: float) -> void:
	var ph := hand + Vector2(3, -6)
	var tip := -0.5 + jolt * 0.9
	var px := Vector2.RIGHT.rotated(tip)
	var py := Vector2.DOWN.rotated(tip)
	var xf := _frame(ph, px, py)
	var body := _shape(K_STATIC, 4, PackedVector2Array(PHONE_BODY), Vector2.RIGHT, 0.0)
	_push(xf * (body[1.4] as PackedVector2Array), OUT)
	_push(xf * (body["fill"] as PackedVector2Array), PHONE)
	_quad(xf * Vector2(-4, -10), xf * Vector2(-1.6, -10), xf * Vector2(-1.6, 10), xf * Vector2(-4, 10),
		SCREEN.lerp(Color.WHITE, 0.3 * glow))
	_line(ph + px * 2.2 + py * -9.0, ph + px * 2.2 + py * -2.0, Color(0.36, 0.36, 0.44), 1.0)
	var f0 := ph + px * 3.6 + py * 1.0
	_inked_cap(f0, ph + px * 3.6 + py * 8.0, 2.6, 3.0, SKIN)
	_line(f0 + px * 0.2 + py * 3.0, f0 + px * 2.4 + py * 3.0, _shade(_shade(SKIN)), 1.0)
	_inked_cap(hand + px * -2.0 + py * 2.0, ph + px * -3.2 + py * (4.0 - 7.0 * fposmod(sc, 1.0)), 2.6, 2.2, SKIN)
