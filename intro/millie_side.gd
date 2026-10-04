class_name MillieSide
extends RefCounted

# Millie seen from the side, for the intro: a puppet of simple parts (body,
# chest, rump, neck, head, muzzle, ear, four legs, tail, collar) posed by a
# handful of numbers, and drawn in one of two looks:
#   "clay" - soft rounded forms lit from the upper left, a darker rim on the
#            side away from the light, a sheen, no outline (the game's look)
#   "ink"  - one bold outline round the whole silhouette, flat fill, one hard
#            cel shadow and one hard highlight (2D cartoon)
# Units: she stands on y = 0 facing +x, about 130 wide and 95 tall at scale 1.
# Pose keys (all optional, 0 is standing): lean (body tilt, + nose down),
# crouch (0..1, lowers the body), reach (front legs forward), push (back legs
# back), head_up (head tilt, + up), ear (ear swing), tail (tail angle), blink,
# mouth (0..1 open). Purely a drawing: no state, so an animation is a pose
# per frame.

const LIGHT := Vector2(-0.6, -0.8)
const COAT := Color(0.13, 0.13, 0.15)
const COAT_LIT := Color(0.30, 0.30, 0.34)
const COAT_DARK := Color(0.06, 0.06, 0.07)
const GRIZZLE := Color(0.62, 0.62, 0.64)
const PAW := Color(0.78, 0.76, 0.73)
const COLLAR := Color(0.86, 0.20, 0.24)
const INK := Color(0.05, 0.04, 0.06)


static func ellipse(c: Vector2, r: Vector2, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	return pts


# a tapered limb from a to b, wide at a and narrow at b: the convex hull of
# its two end circles, so it is one clean outline at any angle
static func limb(a: Vector2, b: Vector2, wa: float, wb: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(16):
		var ang := TAU * float(i) / 16.0
		pts.append(a + Vector2.from_angle(ang) * wa)
		pts.append(b + Vector2.from_angle(ang) * wb)
	var hull := Geometry2D.convex_hull(pts)
	hull.remove_at(hull.size() - 1)
	return hull


static func _x(p: Vector2, o: Vector2, s: float) -> Vector2:
	return o + p * s


static func _xf(pts: PackedVector2Array, o: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(o + p * s)
	return out


# the shapes of her silhouette, in drawing order, for a pose
static func parts(pose: Dictionary) -> Dictionary:
	var lean: float = pose.get("lean", 0.0)
	var crouch: float = pose.get("crouch", 0.0)
	var reach: float = pose.get("reach", 0.0)
	var push: float = pose.get("push", 0.0)
	var head_up: float = pose.get("head_up", 0.0)
	var ear: float = pose.get("ear", 0.0)
	var tail: float = pose.get("tail", 0.0)
	var drop := 8.0 * crouch
	var body_c := Vector2(0.0, -40.0 + drop)
	var fwd := Vector2.RIGHT.rotated(lean)
	var chest := body_c + fwd * 30.0 + Vector2(0, -2)
	var rump := body_c - fwd * 32.0
	var neck_top := chest + Vector2(14.0, -26.0).rotated(-head_up * 0.6)
	var head := neck_top + Vector2(10.0, -10.0).rotated(-head_up)
	var muzzle := head + Vector2(22.0, 7.0).rotated(-head_up)
	var p := {}
	p["tail"] = limb(rump + Vector2(-14, -8), rump + Vector2(-30, -26).rotated(tail), 4.5, 2.0)
	p["leg_bl"] = limb(rump + Vector2(4, 8), Vector2(-30.0 - push * 16.0, -4.0), 7.0, 4.0)
	p["leg_fl"] = limb(chest + Vector2(-2, 8), Vector2(34.0 + reach * 18.0, -4.0), 6.5, 4.0)
	p["rump"] = ellipse(rump, Vector2(21, 20), lean)
	p["body"] = ellipse(body_c, Vector2(42, 19), lean)
	p["chest"] = ellipse(chest, Vector2(20, 21), lean)
	p["neck"] = limb(chest + Vector2(2, -6), neck_top, 13.0, 10.0)
	p["head"] = ellipse(head, Vector2(23, 20), -head_up * 0.5)
	p["muzzle"] = ellipse(muzzle, Vector2(16, 10.5), -head_up * 0.5 + 0.1)
	p["leg_br"] = limb(rump + Vector2(10, 10), Vector2(-22.0 - push * 10.0, -4.0), 7.0, 4.0)
	p["leg_fr"] = limb(chest + Vector2(4, 10), Vector2(42.0 + reach * 12.0, -4.0), 6.5, 4.0)
	# the ear, a floppy teardrop hanging back from the top of the head
	# hanging from the back of the skull; `ear` swings it back and up, the
	# way an ear streams when she lunges
	var ear_root := head + Vector2(-8, -12).rotated(-head_up * 0.5)
	var ear_tip := ear_root + Vector2(-4, 24).rotated(ear)
	p["ear"] = limb(ear_root, ear_tip, 6.5, 9.0)
	p["_head"] = head
	p["_muzzle"] = muzzle
	p["_neck"] = neck_top
	p["_chest"] = chest
	p["_rump"] = rump
	p["_body"] = body_c
	p["_feet"] = [Vector2(-30.0 - push * 16.0, 0.0), Vector2(34.0 + reach * 18.0, 0.0),
		Vector2(-22.0 - push * 10.0, 0.0), Vector2(42.0 + reach * 12.0, 0.0)]
	return p


const BACK := ["tail", "leg_bl", "leg_fl"]
const MAIN := ["rump", "body", "chest", "neck", "head", "muzzle", "leg_br", "leg_fr"]


# draws her; returns the collar ring's position, where a leash attaches
static func draw(c: CanvasItem, origin: Vector2, s: float, pose: Dictionary, style: String) -> Vector2:
	var p := parts(pose)
	var ring := _x(p["_neck"] + Vector2(-8, 6), origin, s)
	# the ground shadow, squashed, under her feet
	var shadow_c := origin + Vector2(4.0, 2.0) * s
	c.draw_colored_polygon(ellipse(shadow_c, Vector2(62, 7) * s), Color(0.15, 0.12, 0.10, 0.28))
	if style == "ink":
		_draw_ink(c, p, origin, s, pose)
	else:
		if style == "hybrid":
			_draw_outline(c, p, origin, s, 2.0, Color(0.03, 0.03, 0.04))
		_draw_clay(c, p, origin, s, pose)
	_draw_face(c, p, origin, s, pose, style)
	_draw_collar(c, p, origin, s, style)
	return ring


static func _draw_clay(c: CanvasItem, p: Dictionary, o: Vector2, s: float, pose: Dictionary) -> void:
	# the far legs and the tail first, a shade darker: they are in her shadow
	for k in BACK:
		c.draw_colored_polygon(_xf(p[k], o, s), COAT_DARK)
	# the whole form as one: its shaded underside showing below, then the coat
	for k in MAIN:
		c.draw_colored_polygon(_xf(p[k], o + Vector2(1.5, 3.0) * s, s), COAT_DARK)
	for k in MAIN:
		c.draw_colored_polygon(_xf(p[k], o, s), COAT)
	# soft light from the upper left, built up in thin layers so it has no
	# edge: across the back, the top of the head, the top of the muzzle
	var body_c: Vector2 = p["_body"]
	var head: Vector2 = p["_head"]
	for i in range(5):
		var f := 1.0 - float(i) * 0.17
		var a := 0.10
		c.draw_colored_polygon(_xf(ellipse(body_c + Vector2(-6, -9), Vector2(40, 9) * f, 0.0), o, s), Color(COAT_LIT, a))
		c.draw_colored_polygon(_xf(ellipse(head + Vector2(-4, -9), Vector2(15, 7) * f, -0.2), o, s), Color(COAT_LIT, a))
		c.draw_colored_polygon(_xf(ellipse(p["_rump"] + Vector2(-4, -10), Vector2(13, 6) * f, 0.0), o, s), Color(COAT_LIT, a))
		c.draw_colored_polygon(_xf(ellipse(p["_muzzle"] + Vector2(0, -5), Vector2(10, 3) * f, 0.1), o, s), Color(COAT_LIT, a))
	# warm light bouncing up off the ground, along the belly and chest: the
	# thing that makes a dark form look like a lump of clay in the sun
	for i in range(3):
		var f3 := 1.0 - float(i) * 0.25
		c.draw_colored_polygon(_xf(ellipse(body_c + Vector2(4, 13), Vector2(34, 5) * f3, 0.0), o, s), Color(0.55, 0.40, 0.28, 0.10))
		c.draw_colored_polygon(_xf(ellipse(p["_chest"] + Vector2(4, 14), Vector2(12, 5) * f3, 0.0), o, s), Color(0.55, 0.40, 0.28, 0.10))
	c.draw_colored_polygon(_xf(p["ear"], o + Vector2(1.0, 1.5) * s, s), COAT_DARK)
	c.draw_colored_polygon(_xf(p["ear"], o, s), Color(0.16, 0.16, 0.18))
	# white paws
	for f2: Vector2 in p["_feet"]:
		c.draw_colored_polygon(ellipse(_x(f2 + Vector2(0, -3), o, s), Vector2(6.5, 3.6) * s), PAW)


static func _draw_outline(c: CanvasItem, p: Dictionary, o: Vector2, s: float, w: float, col: Color) -> void:
	for k in BACK + MAIN + ["ear"]:
		var pts: PackedVector2Array = p[k]
		var cen := Vector2.ZERO
		for q in pts:
			cen += q
		cen /= float(pts.size())
		var fat := PackedVector2Array()
		for q in pts:
			fat.append(q + (q - cen).normalized() * w)
		c.draw_colored_polygon(_xf(fat, o, s), col)
	for f: Vector2 in p["_feet"]:
		c.draw_colored_polygon(ellipse(_x(f + Vector2(0, -3), o, s), Vector2(6.5 + w, 3.6 + w) * s), col)


static func _draw_ink(c: CanvasItem, p: Dictionary, o: Vector2, s: float, pose: Dictionary) -> void:
	var w := 3.2
	# one silhouette outline: every part drawn fat in ink first
	for k in BACK + MAIN + ["ear"]:
		var pts: PackedVector2Array = p[k]
		var cen := Vector2.ZERO
		for q in pts:
			cen += q
		cen /= float(pts.size())
		var fat := PackedVector2Array()
		for q in pts:
			fat.append(q + (q - cen).normalized() * w)
		c.draw_colored_polygon(_xf(fat, o, s), INK)
	for f: Vector2 in p["_feet"]:
		c.draw_colored_polygon(ellipse(_x(f + Vector2(0, -3), o, s), Vector2(6.5 + w, 3.6 + w) * s), INK)
	var flat := Color(0.17, 0.17, 0.21)
	for k in BACK:
		c.draw_colored_polygon(_xf(p[k], o, s), Color(0.11, 0.11, 0.14))
	for k in MAIN:
		c.draw_colored_polygon(_xf(p[k], o, s), flat)
	# one hard cel shadow along the belly, one hard highlight along the back
	var belly := ellipse(p["_body"] + Vector2(0, 9), Vector2(36, 8), 0.0)
	c.draw_colored_polygon(_xf(belly, o, s), Color(0.10, 0.10, 0.13))
	var back := ellipse(p["_body"] + Vector2(-4, -12), Vector2(28, 4), -0.05)
	c.draw_colored_polygon(_xf(back, o, s), Color(0.36, 0.38, 0.46))
	c.draw_colored_polygon(_xf(ellipse(p["_head"] + Vector2(-5, -11), Vector2(12, 4), -0.2), o, s), Color(0.36, 0.38, 0.46))
	c.draw_colored_polygon(_xf(p["ear"], o, s), Color(0.11, 0.11, 0.14))
	for f: Vector2 in p["_feet"]:
		c.draw_colored_polygon(ellipse(_x(f + Vector2(0, -3), o, s), Vector2(6.5, 3.6) * s), Color(0.93, 0.90, 0.84))


static func _draw_face(c: CanvasItem, p: Dictionary, o: Vector2, s: float, pose: Dictionary, style: String) -> void:
	var head: Vector2 = p["_head"]
	var muz: Vector2 = p["_muzzle"]
	# grizzle on the muzzle: she is not a young dog
	for g: Vector2 in [Vector2(2, -2), Vector2(6, 1), Vector2(-1, 2), Vector2(9, -1), Vector2(4, 3)]:
		c.draw_circle(_x(muz + g, o, s), 1.1 * s, Color(GRIZZLE, 0.7))
	# the nose, with a shine
	var nose := muz + Vector2(15, -3)
	c.draw_circle(_x(nose, o, s), 5.6 * s, INK)
	c.draw_circle(_x(nose + Vector2(-1.2, -1.4), o, s), 1.4 * s, Color(0.6, 0.6, 0.64))
	# the mouth, open when she is hauling
	var mouth: float = pose.get("mouth", 0.0)
	if mouth > 0.05:
		var mp := muz + Vector2(4, 6)
		c.draw_colored_polygon(_xf(ellipse(mp, Vector2(7, 3.5 * mouth)), o, s), Color(0.30, 0.06, 0.08))
		c.draw_colored_polygon(_xf(ellipse(mp + Vector2(1, 1.5 * mouth), Vector2(4, 2 * mouth)), o, s), Color(0.92, 0.45, 0.50))
	else:
		c.draw_line(_x(muz + Vector2(-4, 5), o, s), _x(muz + Vector2(6, 6), o, s), INK, 1.4 * s)
	# the eye: big, with a catchlight; and a brow, which is all the acting
	var eye := head + Vector2(9, -4)
	var blink: float = pose.get("blink", 0.0)
	if blink > 0.5:
		c.draw_line(_x(eye + Vector2(-4, 0), o, s), _x(eye + Vector2(4, 1), o, s), INK, 1.8 * s)
	else:
		c.draw_colored_polygon(ellipse(_x(eye, o, s), Vector2(6.0, 7.0) * s), Color(0.97, 0.95, 0.90))
		c.draw_colored_polygon(ellipse(_x(eye + Vector2(1.8, 0.6), o, s), Vector2(3.8, 4.6) * s), INK)
		c.draw_circle(_x(eye + Vector2(0.6, -1.8), o, s), 1.6 * s, Color.WHITE)
	var brow_lift: float = pose.get("brow", 0.0)
	c.draw_line(_x(eye + Vector2(-6, -11 - brow_lift * 3.0), o, s), _x(eye + Vector2(5, -12 + brow_lift), o, s),
		Color(GRIZZLE, 0.9), 2.0 * s)


static func _draw_collar(c: CanvasItem, p: Dictionary, o: Vector2, s: float, style: String) -> void:
	var nk: Vector2 = p["_neck"]
	var a := nk + Vector2(-11, 2)
	var b := nk + Vector2(5, 9)
	if style == "ink":
		c.draw_line(_x(a, o, s), _x(b, o, s), INK, 9.0 * s)
	c.draw_line(_x(a, o, s), _x(b, o, s), COLLAR, 5.5 * s)
	c.draw_line(_x(a + Vector2(1, -1.5), o, s), _x(b + Vector2(1, -1.5), o, s), COLLAR.lightened(0.35), 1.5 * s)
	c.draw_arc(_x(nk + Vector2(-8, 6), o, s), 3.4 * s, 0, TAU, 14, Color(0.80, 0.74, 0.50), 2.0 * s)
