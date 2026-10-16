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
# Everything goes out through one ShapeBatch: the whole figure is one draw call.

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

static var _b: ShapeBatch


static func _limb(a: Vector2, b: Vector2, wa: float, wb: float) -> PackedVector2Array:
	return MillieSide.limb(a, b, wa, wb)


static func _ell(c: Vector2, r: Vector2, rot := 0.0, n := 20) -> PackedVector2Array:
	return MillieSide.ellipse(c, r, rot, n)


# points given in a local frame (origin o, axes ax and ay) into puppet units
static func _tx(pts: Array, o: Vector2, ax: Vector2, ay: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(o + ax * p.x + ay * p.y)
	return out


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


static func _outline(polys: Array, w: float) -> void:
	for p: PackedVector2Array in polys:
		for q: PackedVector2Array in Geometry2D.offset_polygon(p, w, Geometry2D.JOIN_ROUND):
			_b.polygon(q, OUT)


# a small inked shape laid over others (a thumb, an ear)
static func _inked(p: PackedVector2Array, col: Color, w := 1.1) -> void:
	_outline([p], w)
	_b.polygon(p, col)


# a flat fill, its hard shadow on the side away from the light (the shape
# minus itself moved toward the light) and, if hl > 0, a crisp highlight
# sliver inset on the lit side, cut to the circle (hc, hr) when hr > 0
static func _fill(p: PackedVector2Array, col: Color, k := 3.0, hl := 0.0, hc := Vector2.ZERO, hr := 0.0) -> void:
	_b.polygon(p, col)
	if k > 0.0:
		for q: PackedVector2Array in Geometry2D.clip_polygons(p, Transform2D(0.0, LIGHT * k) * p):
			_b.polygon(q, _shade(col))
	if hl > 0.0:
		var inset := Geometry2D.offset_polygon(p, -1.3)
		if inset.is_empty():
			return
		var ip: PackedVector2Array = inset[0]
		for q: PackedVector2Array in Geometry2D.clip_polygons(ip, Transform2D(0.0, -LIGHT * hl) * ip):
			if hr > 0.0:
				for r: PackedVector2Array in Geometry2D.intersect_polygons(q, _ell(hc, Vector2(hr, hr))):
					_b.polygon(r, _hi(col))
			else:
				_b.polygon(q, _hi(col))


# a group of parts [poly, colour, shadow, highlight, highlight centre, radius]:
# their outlines first, then their fills, so only the group's silhouette is
# inked; a later group's outline separates it from this one
static func _group(parts: Array, w: float) -> void:
	var polys := []
	for pr: Array in parts:
		polys.append(pr[0])
	_outline(polys, w)
	for pr: Array in parts:
		_fill(pr[0], pr[1], pr[2], pr[3] if pr.size() > 3 else 0.0, pr[4] if pr.size() > 4 else Vector2.ZERO,
			pr[5] if pr.size() > 5 else 0.0)


# a leg's parts (sneaker, shin, thigh) and what its details need
static func _leg(leg: Array, lift: float, far: bool) -> Array:
	var thigh_d: Vector2 = (leg[1] - leg[0]).normalized()
	var shin_d: Vector2 = (leg[2] - leg[1]).normalized()
	# flat on the floor, or hanging slack off the ankle, toes down and back,
	# when the feet trail behind
	var foot := Vector2.from_angle(lerp_angle(0.0, shin_d.rotated(-1.3).angle(), lift))
	var tr := TROUSERS if not far else _far(TROUSERS)
	var sh := SHOE if not far else _far(SHOE)
	var shoe := [_tx(SNEAKER, leg[2], foot, foot.rotated(PI * 0.5)), sh, 2.0, 0.0 if far else 1.6, leg[2] + foot * 14.0, 6.0]
	var shin := [_limb(leg[1], leg[2] + shin_d * 1.5 * (1.0 - lift), 9.5, 8.0), tr, 2.4]
	var thigh := [_limb(leg[0], leg[1], 13.0, 9.5), tr, 2.6]
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
	_b.polygon(_tx(SNEAKER_SOLE, leg[2], foot, fy), _far(SOLE) if far else SOLE)
	_b.polygon(_tx(SNEAKER_STRIPE, leg[2], foot, fy), _far(STRIPE) if far else STRIPE)
	_b.line(leg[2] + foot * 13.0 + fy * -0.6, leg[2] + foot * 14.4 + fy * 3.4, OUT, 1.1)
	_b.line(leg[2] + foot * -7.6 + fy * 3.4, leg[2] + foot * 20.4 + fy * 3.4, OUT, 1.1)
	# the trouser hem over the shoe, and the crease behind a bent knee
	var across := shin_d.orthogonal()
	var hem: Vector2 = leg[2] - shin_d * 1.5
	_b.line(hem - across * 7.6, hem + across * 7.6, ink, 1.3)
	var into := shin_d - thigh_d
	if into.length() > 0.5:
		into = into.normalized()
		var pit: Vector2 = leg[1] + into * 6.0
		_b.line(pit, pit - thigh_d * 6.0 - into * 1.6, ink, 1.3)
		_b.line(pit, pit + shin_d * 5.0 - into * 1.6, ink, 1.3)


# an arm: bare skin, a T-shirt sleeve over its top with a hem, and a hand
# (grip 1: a fist; 0: a relaxed open hand; -1: a palm, drawn by the caller)
static func _arm(sj: Vector2, elbow: Vector2, hand: Vector2, grip: float, far: bool) -> Array:
	var sk := SKIN if not far else _far(SKIN)
	var st := SHIRT if not far else _far(SHIRT)
	var d := (hand - elbow).normalized()
	var n := d.rotated(PI * 0.5)
	var hem := sj.lerp(elbow, 0.55)
	var hand_shape: PackedVector2Array
	if grip > 0.5:
		hand_shape = _ell(hand + d * 1.5, Vector2(6.4, 5.6), d.angle())
	elif grip < -0.5:
		hand_shape = _ell(hand, Vector2(5.6, 5.0), d.angle())
	else:
		hand_shape = _tx(OPEN_HAND, hand - d * 1.0, d, n)
	var parts := [
		[_limb(sj, elbow, 6.4, 5.6), sk, 1.8],
		[_limb(elbow, hand - d * 2.0, 5.6, 4.6), sk, 1.6],
		[hand_shape, sk, 1.6],
		[_limb(sj, hem, 9.6, 7.6), st, 2.6, 0.0 if far else 2.2, sj + Vector2(-5, -6), 9.0],
	]
	return [parts, hem, (elbow - sj).normalized(), d, n, grip, hand, sk]


static func _arm_detail(info: Array) -> void:
	var hem: Vector2 = info[1]
	var ud: Vector2 = info[2]
	var d: Vector2 = info[3]
	var n: Vector2 = info[4]
	var grip: float = info[5]
	var hand: Vector2 = info[6]
	var sk: Color = info[7]
	var across := ud.orthogonal()
	_b.line(hem - across * 7.6 - ud * 1.0, hem + across * 7.6 - ud * 1.0, _shade(_shade(SHIRT)), 1.6)
	if grip > 0.5:
		# knuckles, and the thumb wrapped over the fingers
		var kc := hand + d * 5.2
		_b.line(kc - n * 3.0, kc + n * 1.5, _shade(_shade(sk)), 1.1)
		_inked(_limb(hand - d * 2.0 - n * 4.6, hand + d * 4.0 - n * 3.6, 2.3, 2.0), sk)
	elif grip > -0.5:
		# the thumb, out ahead of the open hand, and a finger line
		_inked(_limb(hand + d * 1.0 - n * 3.6, hand + d * 5.6 - n * 6.2, 2.3, 1.9), sk)
		_b.line(hand + d * 5.0 + n * 0.6, hand + d * 9.5 + n * 0.4, _shade(_shade(sk)), 1.0)


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
	var mouth: float = pose.get("mouth", 0.0)
	if _b == null:
		_b = ShapeBatch.new()
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
	var torso := _tx(TORSO, hip, fwd, up)
	var jaw := Vector2(-1.5, 5.0) * mouth
	var face_pts := FACE.duplicate()
	for i in range(13, 18):
		face_pts[i] += jaw * (0.6 if i == 17 else 1.0)
	# the open mouth is a notch in the profile, filled by the mouth below
	face_pts[12] = (face_pts[12] as Vector2).lerp(Vector2(14.2, 15.4), mouth)
	var face := _tx(face_pts, head, hx, hy)
	var neck := _limb(shoulder + up * 3.0 + fwd * 2.5, head + hx * 1.0 + hy * 13.0, 8.6, 7.4)
	# the seat of the trousers: low and round on the sofa, tucked in standing
	var rump := _limb(hip + fwd * -3.0 - up * (2.0 + 9.0 * sit), hip + fwd * 6.0 - up * (2.0 + 7.0 * sit),
		lerpf(12.0, 13.0, sit), lerpf(11.0, 12.0, sit))
	_group([near_leg[0], near_leg[1], near_leg[2], [rump, TROUSERS, 2.6], [neck, SKIN, 2.5],
		[torso, SHIRT, 4.0, 3.0, hip + up * 52.0 - fwd * 14.0, 13.0]], OW)
	_leg_detail(legs[0], near_leg)
	# the shirt: its hem over the trousers, a crew collar, folds at the belly
	var sdk := _shade(_shade(SHIRT))
	var tp := func(u: float, v: float) -> Vector2: return hip + fwd * u + up * v
	_b.line(tp.call(-15.0, -6.5), tp.call(16.5, -5.5), sdk, 1.4)
	_b.line(tp.call(-6.5, 69.0), tp.call(1.5, 71.0), sdk, 3.0)
	_b.line(tp.call(1.5, 71.0), tp.call(8.0, 69.0), sdk, 3.0)
	_b.line(tp.call(8.0, 69.0), tp.call(12.0, 64.0), sdk, 3.0)
	_b.line(tp.call(11.0, 22.0), tp.call(17.0, 18.0), _shade(SHIRT), 1.4)
	_b.line(tp.call(9.0, 12.0), tp.call(16.0, 9.5), _shade(SHIRT), 1.4)
	# the leash arm, out ahead, passes in front of the body and behind the
	# head, so a face bowed over it (or yelling) stays in view
	if reach > 0.25:
		_group(arm_free[0], IW)
		_arm_detail(arm_free)
	_group([[face, SKIN, 2.2]], OW)
	# the screen's cold light on the face: a crisp band down the brow, nose
	# and lips, on the side that faces it
	# (gone once they are hauled over and the screen no longer faces them)
	glow *= 1.0 - clampf((lean - 0.5) / 0.4, 0.0, 1.0)
	if glow > 0.0 and phone > 0.3:
		var cool := SKIN.lerp(Color(0.74, 0.88, 1.0), 0.6 * glow)
		for q: PackedVector2Array in Geometry2D.clip_polygons(face, Transform2D(0.0, -hx * 2.4) * face):
			for r: PackedVector2Array in Geometry2D.intersect_polygons(q, _ell(head + hx * 17.0 + hy * 3.0, Vector2(9, 12.5), hr)):
				_b.polygon(r, cool)
	# the ear, the cheek, the nostril
	_inked(_ell(head + hx * -4.5 + hy * 3.0, Vector2(4.4, 6.0), hr), SKIN, 1.2)
	_b.line(head + hx * -3.4 + hy * 0.4, head + hx * -4.6 + hy * 5.4, _shade(SKIN), 1.6)
	_b.polygon(_ell(head + hx * 9.0 + hy * 8.0, Vector2(3.6, 2.4), hr, 12), SKIN.lerp(Color(0.96, 0.52, 0.48), 0.45))
	_b.line(head + hx * 19.2 + hy * 9.0, head + hx * 20.4 + hy * 10.4, _shade(_shade(SKIN)), 1.1)
	# hair over the crown, a crisp shine along its top, the parting
	var hair := _tx(HAIRDO, head, hx, hy)
	_outline([hair], IW)
	_fill(hair, HAIR, 2.2)
	_b.polygon(_tx(HAIR_SHINE, head, hx, hy), _hi(HAIR))
	_b.line(head + hx * 3.0 + hy * -24.0, head + hx * 15.0 + hy * -15.0, _shade(HAIR), 1.2)
	# the eye under a lowered lid, looking down into the screen; wide on the jolt
	var e := func(x: float, y: float) -> Vector2: return head + hx * x + hy * y
	var lid_y := -0.6 - 1.6 * jolt
	if pose.get("blink", 0.0) > 0.5:
		_b.line(e.call(10.0, 0.4), e.call(13.0, 1.2), OUT, 1.6)
		_b.line(e.call(13.0, 1.2), e.call(15.6, 0.6), OUT, 1.6)
	else:
		_b.polygon(PackedVector2Array([e.call(10.2, lid_y + 0.2), e.call(15.4, lid_y), e.call(14.4, 1.5),
			e.call(11.0, 1.3)]), Color(0.98, 0.96, 0.93))
		_b.polygon(_ell(e.call(13.6 - jolt * 0.6, 0.4 - jolt * 0.4), Vector2(1.5, 1.7) * (1.0 + 0.2 * jolt), hr, 10), OUT)
		_b.line(e.call(9.6, lid_y), e.call(12.6, lid_y - 0.5), OUT, 1.8)
		_b.line(e.call(12.6, lid_y - 0.5), e.call(16.2, lid_y + 0.1), OUT, 1.8)
		_b.line(e.call(10.4, lid_y - 2.2), e.call(15.0, lid_y - 2.6), _shade(SKIN), 1.1)
	# the eyebrow, low and level while absorbed, shot up on the jolt
	var by := -6.4 - 2.6 * jolt
	_b.line(e.call(9.6, by + 0.4), e.call(13.2, by - 0.4 - jolt), _shade(HAIR), 2.4)
	_b.line(e.call(13.2, by - 0.4 - jolt), e.call(16.6, by + 0.2), _shade(HAIR), 2.4)
	# the mouth: a small flat line, absorbed, or open
	if mouth > 0.05:
		var m := PackedVector2Array([e.call(19.0, 13.0), e.call(14.0, 15.0), e.call(13.8 + jaw.x * 0.5, 16.0 + jaw.y * 0.7),
			e.call(17.6 + jaw.x, 16.6 + jaw.y)])
		_inked(m, Color(0.30, 0.07, 0.09), 1.0)
		_b.polygon(PackedVector2Array([e.call(14.4 + jaw.x * 0.5, 15.6 + jaw.y * 0.7), e.call(17.2 + jaw.x, 16.2 + jaw.y),
			e.call(15.8 + jaw.x * 0.8, 14.8 + jaw.y * 0.7)]), Color(0.88, 0.42, 0.44))
	else:
		_b.line(e.call(14.4, 14.4), e.call(18.0, 14.6), _shade(_shade(SKIN)), 1.4)

	# ---------------------------------------------------------- the arms in front
	_group(arm_phone[0], IW)
	_arm_detail(arm_phone)
	if phone > 0.3:
		_phone(phone_hand, jolt, pose.get("scroll", 0.0), glow)
	_b.flush(c)
	return arm2[2]


# the phone in the cupped hand, edge on, its screen facing the face; fingers
# round the back edge, the thumb on the screen, scrolling
static func _phone(hand: Vector2, jolt: float, sc: float, glow: float) -> void:
	var ph := hand + Vector2(3, -6)
	var tip := -0.5 + jolt * 0.9
	var px := Vector2.RIGHT.rotated(tip)
	var py := Vector2.DOWN.rotated(tip)
	_inked(_tx([Vector2(-4, -11), Vector2(3.5, -11), Vector2(3.5, 11), Vector2(-4, 11)], ph, px, py), PHONE, 1.4)
	_b.polygon(_tx([Vector2(-4, -10), Vector2(-1.6, -10), Vector2(-1.6, 10), Vector2(-4, 10)], ph, px, py),
		SCREEN.lerp(Color.WHITE, 0.3 * glow))
	_b.line(ph + px * 2.2 + py * -9.0, ph + px * 2.2 + py * -2.0, Color(0.36, 0.36, 0.44), 1.0)
	var f0 := ph + px * 3.6 + py * 1.0
	_inked(_limb(f0, ph + px * 3.6 + py * 8.0, 2.6, 3.0), SKIN)
	_b.line(f0 + px * 0.2 + py * 3.0, f0 + px * 2.4 + py * 3.0, _shade(_shade(SKIN)), 1.0)
	_inked(_limb(hand + px * -2.0 + py * 2.0, ph + px * -3.2 + py * (4.0 - 7.0 * fposmod(sc, 1.0)), 2.6, 2.2), SKIN)
