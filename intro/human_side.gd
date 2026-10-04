class_name HumanSide
extends RefCounted

# Your human seen from the side, for the intro, in the intro's look (soft clay
# forms with a thin dark outline, lit from the upper left). Facing +x, feet on
# y = 0, about 200 tall at scale 1. Draw it under a transform for position,
# flip and squash (c.draw_set_transform), at the origin.
# Pose keys (all optional): sit (0..1), lean (torso tilt, + forward), stride
# (walk phase, radians), stride_amp (0..1), phone (0..1, phone up at the face),
# reach (0..1, the other arm out forward holding the leash), lift (0..1, feet
# off the ground and trailing, for being yanked), head (head tilt), mouth
# (0..1, an "o"), glow (0..1, the phone lighting the face).

const OUT := Color(0.04, 0.04, 0.05)
const SKIN := Color(0.94, 0.78, 0.64)
const HAIR := Color(0.36, 0.24, 0.16)
const SHIRT := Color(0.26, 0.44, 0.74)
const TROUSERS := Color(0.24, 0.26, 0.32)
const SHOE := Color(0.14, 0.11, 0.10)
const LIGHT := Vector2(-0.6, -0.8)


static func _limb(a: Vector2, b: Vector2, wa: float, wb: float) -> PackedVector2Array:
	return MillieSide.limb(a, b, wa, wb)


static func _ell(c: Vector2, r: Vector2, rot := 0.0) -> PackedVector2Array:
	return MillieSide.ellipse(c, r, rot)


static func _fat(pts: PackedVector2Array, w: float) -> PackedVector2Array:
	var cen := Vector2.ZERO
	for q in pts:
		cen += q
	cen /= float(pts.size())
	var out := PackedVector2Array()
	for q in pts:
		out.append(q + (q - cen).normalized() * w)
	return out


# a two-bone limb from root, bending at the middle by `bend` (+ is forward)
static func _two(root: Vector2, dir: Vector2, l1: float, l2: float, bend: float) -> Array:
	var mid := root + dir * l1
	var end := mid + dir.rotated(bend) * l2
	return [root, mid, end]


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
	var hip := Vector2(0.0, lerpf(-100.0, -58.0, sit))
	var up := Vector2.UP.rotated(lean)
	var shoulder := hip + up * 62.0
	# the neck juts forward and the head tips down into the phone: the stoop
	# of someone who has not looked up in an hour
	head_t += 0.75 * phone
	var neck_top := shoulder + up.rotated(0.35 * phone) * 14.0
	var head := neck_top + up.rotated(head_t * 0.6) * 18.0 + Vector2(5, 0)
	var legs := []
	for side in range(2):
		var ph := phase + PI * float(side)
		var swing := sin(ph) * 0.55 * amp
		var thigh_dir := Vector2.DOWN.rotated(-swing).lerp(Vector2.RIGHT, sit).normalized()
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
	var arm1 := [shoulder + Vector2(4, 4), elbow, phone_hand]
	# the free arm: hanging, out ahead on the leash, or down to the floor
	var free_dir := Vector2.DOWN.rotated(-0.2).lerp(Vector2.RIGHT.rotated(0.12), reach).normalized()
	free_dir = free_dir.lerp(Vector2(0.55, 0.85).normalized(), reach_down).normalized()
	var arm2 := _two(shoulder + Vector2(-2, 4), free_dir, 34.0, 32.0, -0.3 * (1.0 - reach) * (1.0 - reach_down))
	var far_leg: Array = legs[1]
	var near_leg: Array = legs[0]
	var arm2_parts := [
		[_limb(arm2[0], arm2[1], 7.5, 6.5), SHIRT if reach > 0.25 else SHIRT.darkened(0.25)],
		[_limb(arm2[1], arm2[2], 6.5, 5.5), SKIN if reach > 0.25 else SKIN.darkened(0.15)],
	]
	var parts_back := [
		[_limb(far_leg[0], far_leg[1], 11.0, 9.0), TROUSERS.darkened(0.25)],
		[_limb(far_leg[1], far_leg[2], 9.0, 7.5), TROUSERS.darkened(0.25)],
		[_ell(far_leg[2] + Vector2(7, 0), Vector2(13, 6)), SHOE],
	]
	# when the hand is out holding something it is the arm we see in front
	if reach <= 0.25:
		parts_back.append_array(arm2_parts)
	var torso := _limb(hip + Vector2(0, -6), shoulder + up * 2.0, 21.0, 22.0)
	var parts_front := [
		[torso, SHIRT],
		[_limb(near_leg[0], near_leg[1], 12.0, 9.5), TROUSERS],
		[_limb(near_leg[1], near_leg[2], 9.5, 7.5), TROUSERS],
		[_ell(near_leg[2] + Vector2(8, 0), Vector2(14, 6.5)), SHOE],
		[_limb(shoulder + up * 2.0, neck_top, 7.5, 6.5), SKIN.darkened(0.06)],
		[_ell(head, Vector2(18, 20), head_t * 0.3), SKIN],
		[_ell(head + Vector2(16, 5).rotated(head_t * 0.6), Vector2(5, 5)), SKIN],
		[_limb(arm1[0], arm1[1], 7.5, 6.5), SHIRT],
		[_limb(arm1[1], arm1[2], 6.5, 5.5), SKIN],
	]
	if reach > 0.25:
		parts_front.append_array(arm2_parts)
	for pr: Array in parts_back + parts_front:
		c.draw_colored_polygon(_fat(pr[0], 2.0), OUT)
	for pr: Array in parts_back:
		c.draw_colored_polygon(pr[0], pr[1])
	for pr: Array in parts_front:
		c.draw_colored_polygon(pr[0], pr[1])
	# soft light down the back of the shirt
	for i in range(4):
		var f := 1.0 - float(i) * 0.2
		c.draw_colored_polygon(_ell((hip + shoulder) * 0.5 + Vector2(-8, -6), Vector2(9, 26) * f, lean), Color(1, 1, 1, 0.05))
	# hair: a cap over the back and crown, well back off the eye, and a fringe
	var hr := head_t * 0.6
	var cap := head + Vector2(-9, -9).rotated(hr)
	c.draw_colored_polygon(_fat(_ell(cap, Vector2(16, 14), -0.3 + hr), 2.0), OUT)
	c.draw_colored_polygon(_ell(cap, Vector2(16, 14), -0.3 + hr), HAIR)
	c.draw_colored_polygon(_ell(head + Vector2(4, -17).rotated(hr), Vector2(9, 5), 0.2 + hr), HAIR)
	c.draw_colored_polygon(_ell(cap + Vector2(-2, -8).rotated(hr), Vector2(7, 3.5), -0.4 + hr), HAIR.lightened(0.18))
	# the ear, below the hairline and behind the cheek
	c.draw_colored_polygon(_ell(head + Vector2(-5, 3).rotated(hr), Vector2(4.5, 6), hr), SKIN.darkened(0.12))
	# the eye, looking down at the screen, its lid half lowered
	var eye := head + Vector2(9, -1).rotated(hr)
	c.draw_colored_polygon(_ell(eye, Vector2(3.0, 3.4), hr), Color(0.97, 0.95, 0.92))
	c.draw_colored_polygon(_ell(eye + Vector2(1.2, 1.4).rotated(hr), Vector2(1.9, 2.2), hr), OUT)
	c.draw_line(eye + Vector2(-3.5, -1.2).rotated(hr), eye + Vector2(3.5, -0.4).rotated(hr), SKIN.darkened(0.25), 2.2)
	c.draw_line(eye + Vector2(-4, -6).rotated(hr), eye + Vector2(3, -6.5).rotated(hr), HAIR.darkened(0.3), 2.0)
	if pose.get("blink", 0.0) > 0.5:
		c.draw_colored_polygon(_ell(eye, Vector2(3.4, 3.8), hr), SKIN)
		c.draw_line(eye + Vector2(-3.5, 0.5).rotated(hr), eye + Vector2(3.5, 1.2).rotated(hr), OUT, 1.6)
	var mouth: float = pose.get("mouth", 0.0)
	var mp := head + Vector2(12, 11).rotated(hr)
	if mouth > 0.05:
		c.draw_colored_polygon(_ell(mp, Vector2(3.0, 4.5 * mouth)), Color(0.35, 0.08, 0.08))
	else:
		# a small flat mouth, absorbed
		c.draw_line(mp + Vector2(-4, -0.5).rotated(hr), mp + Vector2(3, 0.5).rotated(hr), Color(0.32, 0.14, 0.12), 2.0)
	# the phone, tipped up to the face, and its cold light on it
	if phone > 0.3:
		var ph := phone_hand + Vector2(3, -6)
		var tip := -0.5 + jolt * 0.9
		var pr := PackedVector2Array([ph + Vector2(-5, -11).rotated(tip), ph + Vector2(5, -11).rotated(tip),
			ph + Vector2(5, 11).rotated(tip), ph + Vector2(-5, 11).rotated(tip)])
		c.draw_colored_polygon(_fat(pr, 1.6), OUT)
		c.draw_colored_polygon(pr, Color(0.14, 0.15, 0.18))
		c.draw_line(ph + Vector2(-3, -9).rotated(tip), ph + Vector2(-3, 9).rotated(tip), Color(0.86, 0.94, 1.0), 2.0)
		# the thumb, scrolling
		var sc: float = pose.get("scroll", 0.0)
		c.draw_circle(ph + Vector2(1, 4 - 7.0 * fposmod(sc, 1.0)).rotated(tip), 2.6, SKIN.darkened(0.1))
		if glow > 0.0:
			# the screen's light on the face: a cool rim down the front of it
			for i in range(4):
				c.draw_colored_polygon(_ell(head + Vector2(12, 8).rotated(hr), Vector2(9, 14) * (1.0 - float(i) * 0.2), hr),
					Color(0.88, 0.95, 1.0, 0.10 * glow))
	return arm2[2]
