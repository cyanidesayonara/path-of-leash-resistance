class_name MillieSide
extends RefCounted

# Millie seen from the side, for the intro: a puppet of simple parts (body,
# chest, rump, neck, head, muzzle, ears, four legs, tail, collar) posed by a
# handful of numbers, drawn as the Store box art's Millie: one bold warm-black
# outline round the silhouette, a soft charcoal coat with one hard cel shadow
# away from the light and one glossy highlight toward it, a light grey muzzle
# with freckles, grey brow spots, big googly eyes, white paws, a pink collar.
# Units: she stands on y = 0 facing +x, about 130 wide and 95 tall at scale 1.
# Pose keys (all optional, 0 is standing): lean (body tilt, + nose down),
# crouch (0..1, lowers the body), reach (front legs forward), push (back legs
# back), head_up (head tilt, + up), ear (ear swing), tail (tail angle), blink,
# mouth (0..1 open), sit, gait, phase, brow, look_back. `_face` (the sign of
# the screen facing, set by IntroKit) keeps the light on the window's side.
# Purely a drawing: no state, so an animation is a pose per frame. Everything
# goes out through one ShapeBatch: one draw call for the whole dog.

const LIGHT := Vector2(-0.6, -0.8)
const LINE := 2.1                              # silhouette outline width
const INK := Color(0.10, 0.07, 0.08)
const COAT := Color(0.21, 0.20, 0.24)
const COAT_SHADE := Color(0.11, 0.09, 0.13)    # cool, a little purple
const COAT_GLOSS := Color(0.40, 0.39, 0.46)
const COAT_FAR := Color(0.14, 0.12, 0.16)      # the far legs, in her shadow
const EAR := Color(0.08, 0.075, 0.09)
const EAR_GLOSS := Color(0.24, 0.23, 0.27)
const MUZZLE := Color(0.71, 0.69, 0.67)
const MUZZLE_SHADE := Color(0.54, 0.51, 0.52)
const MUZZLE_RIM := Color(0.47, 0.45, 0.46)
const FRECKLE := Color(0.33, 0.32, 0.34)
const BROW := Color(0.68, 0.66, 0.64)
const PAW := Color(0.93, 0.90, 0.85)
const PAW_SHADE := Color(0.72, 0.68, 0.70)
const EYE := Color(0.98, 0.96, 0.91)
const EYE_SHADE := Color(0.88, 0.85, 0.80)
const PUPIL := Color(0.05, 0.04, 0.05)
const NOSE_SHINE := Color(0.52, 0.52, 0.56)
const COLLAR := Color(0.93, 0.33, 0.55)
const COLLAR_SHADE := Color(0.72, 0.19, 0.39)
const RING := Color(0.88, 0.88, 0.92)
const MOUTH := Color(0.32, 0.07, 0.10)
const TONGUE := Color(0.94, 0.47, 0.55)
const GROUND_SHADOW := Color(0.15, 0.12, 0.10, 0.28)


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


static func _moved(pts: PackedVector2Array, v: Vector2) -> PackedVector2Array:
	return Transform2D(0.0, v) * pts


static func _area(pts: PackedVector2Array) -> float:
	var a := 0.0
	for i in range(pts.size()):
		var p := pts[i]
		var q := pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return absf(a) * 0.5


# the biggest polygon of a Geometry2D result (drops holes and crumbs)
static func _largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_a := 0.0
	for poly: PackedVector2Array in polys:
		var a := _area(poly)
		if a > best_a:
			best_a = a
			best = poly
	return best


static func _union(list: Array) -> PackedVector2Array:
	var u: PackedVector2Array = list[0]
	for i in range(1, list.size()):
		var nxt: PackedVector2Array = list[i]
		if nxt.size() >= 3:
			u = _largest(Geometry2D.merge_polygons(u, nxt))
	return u


static func _grow(pts: PackedVector2Array, d: float) -> PackedVector2Array:
	return _largest(Geometry2D.offset_polygon(pts, d, Geometry2D.JOIN_ROUND))


# a rounded box (a superellipse): the muzzle's blunt end
static func _blunt(c: Vector2, r: Vector2, rot: float, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var cx := cos(a)
		var sy := sin(a)
		var q := Vector2(signf(cx) * pow(absf(cx), 0.7) * r.x, signf(sy) * pow(absf(sy), 0.8) * r.y)
		pts.append(c + q.rotated(rot))
	return pts


# a curved, tapering strip along the quadratic curve a-k-b, width wa to wb,
# with a round tip: the tail
static func _strip(a: Vector2, k: Vector2, b: Vector2, wa: float, wb: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 9
	var tang := Vector2.RIGHT
	for i in range(n + 1):
		var u := float(i) / float(n)
		var p := a.lerp(k, u).lerp(k.lerp(b, u), u)
		var dv := 2.0 * (1.0 - u) * (k - a) + 2.0 * u * (b - k)
		if dv.length_squared() > 0.0001:
			tang = dv.normalized()
		var w := lerpf(wa, wb, u * u * 0.4 + u * 0.6)
		left.append(p + tang.orthogonal() * w)
		right.append(p - tang.orthogonal() * w)
	var out := left
	for i in range(1, 6):
		out.append(b + tang.orthogonal().rotated(-PI * float(i) / 6.0) * wb)
	right.reverse()
	out.append_array(right)
	return out


# the shapes of her silhouette, in drawing order, for a pose
static func parts(pose: Dictionary) -> Dictionary:
	# `sit` (0..1): rump down on the floor, chest up, front legs straight
	# under it, back paws tucked forward under the haunch
	var sit: float = pose.get("sit", 0.0)
	var lean: float = lerpf(pose.get("lean", 0.0), -0.62, sit)
	var crouch: float = lerpf(pose.get("crouch", 0.0), 0.0, sit)
	var reach: float = lerpf(pose.get("reach", 0.0), -0.45, sit)
	var push: float = lerpf(pose.get("push", 0.0), -1.25, sit)
	var head_up: float = pose.get("head_up", 0.0)
	var ear: float = pose.get("ear", 0.0)
	var tail: float = pose.get("tail", 0.0)
	# `gait` (0..1) and `phase` (radians): a trot, the legs in diagonal pairs
	var g: float = pose.get("gait", 0.0)
	var ph: float = pose.get("phase", 0.0)
	var drop := 8.0 * crouch - absf(cos(ph)) * 2.5 * g
	var body_c := Vector2(0.0, -40.0 + drop)
	var fwd := Vector2.RIGHT.rotated(lean)
	var chest := body_c + fwd * 30.0 + Vector2(0, -2)
	var rump := body_c - fwd * 32.0
	var neck_top := chest + Vector2(14.0, -26.0).rotated(-head_up * 0.6)
	var head := neck_top + Vector2(10.0, -10.0).rotated(-head_up)
	var muzzle := head + Vector2(22.0, 7.0).rotated(-head_up)
	var hrot := -head_up * 0.5
	var p := {}
	# the tail: a curve that tapers to a fine round tip
	var t_base := rump + Vector2(-14, -8)
	var t_tip := rump + Vector2(-32, -27).rotated(tail)
	var t_knee := t_base + Vector2(-15, -3).rotated(tail * 0.6)
	p["tail"] = _strip(t_base, t_knee, t_tip, 5.2, 1.3)
	var swing := 14.0 * g
	var f_fl := Vector2(34.0 + reach * 18.0 + sin(ph + PI) * swing, -4.0 - maxf(0.0, cos(ph + PI)) * 7.0 * g)
	var f_fr := Vector2(42.0 + reach * 12.0 + sin(ph) * swing, -4.0 - maxf(0.0, cos(ph)) * 7.0 * g)
	var f_bl := Vector2(-30.0 - push * 16.0 + sin(ph) * swing, -4.0 - maxf(0.0, cos(ph)) * 7.0 * g)
	var f_br := Vector2(-22.0 - push * 10.0 + sin(ph + PI) * swing, -4.0 - maxf(0.0, cos(ph + PI)) * 7.0 * g)
	# hind legs bend at the hock: up and back from the paw standing, folded
	# flat along the floor sitting
	var hock := Vector2(-5.0, -15.0).lerp(Vector2(-13.0, -4.0), sit)
	p["leg_bl"] = _union([limb(rump + Vector2(4, 8), f_bl + hock, 8.0, 4.4), limb(f_bl + hock, f_bl, 4.4, 3.8)])
	p["leg_fl"] = limb(chest + Vector2(-2, 8), f_fl, 6.5, 3.9)
	p["rump"] = ellipse(rump, Vector2(21, 20), lean)
	# the haunch: the folded back leg showing on her side when she sits
	p["haunch"] = ellipse(rump + Vector2(8, 6), Vector2(17 * sit + 0.01, 14 * sit + 0.01), lean * 0.5)
	# the barrel: deep at the chest, tucked up at the loin
	var barrel := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		var q := Vector2(cos(a) * 42.0, sin(a) * 19.0)
		q.y *= lerpf(0.72, 1.1, (q.x + 42.0) / 84.0) if q.y > 0.0 else 0.96
		barrel.append(body_c + q.rotated(lean))
	p["body"] = barrel
	p["chest"] = ellipse(chest, Vector2(20, 21.5), lean)
	p["neck"] = limb(chest + Vector2(2, -6), neck_top, 13.0, 10.0)
	p["head"] = ellipse(head + Vector2(-0.5, -0.5).rotated(hrot), Vector2(23.5, 20.5), hrot)
	p["muzzle"] = _blunt(muzzle + Vector2(-1, 0.5).rotated(hrot), Vector2(16, 10), hrot + 0.06)
	p["leg_br"] = _union([limb(rump + Vector2(10, 10), f_br + hock, 8.0, 4.4), limb(f_br + hock, f_br, 4.4, 3.8)])
	p["leg_fr"] = limb(chest + Vector2(4, 10), f_fr, 6.5, 3.9)
	# the ears hang from high on the skull; `ear` swings them back and up,
	# the way an ear streams when she lunges
	var sw := clampf(ear, -0.6, 0.7)
	var ear_root := head + Vector2(-9, -14).rotated(hrot)
	var ear_mid := ear_root + Vector2(-5, 9).rotated(sw * 0.6)
	var ear_tip := ear_root + Vector2(-5, 21).rotated(sw)
	var ear_hull := Geometry2D.convex_hull(ellipse(ear_root, Vector2(5, 4), hrot, 10)
		+ ellipse(ear_mid, Vector2(6.5, 6.5), 0.0, 12) + ellipse(ear_tip, Vector2(6, 5.5), sw, 12))
	ear_hull.remove_at(ear_hull.size() - 1)
	p["ear"] = ear_hull
	# the far ear: only its top shows, above the crown
	var fe_root := head + Vector2(3, -16).rotated(hrot)
	p["ear_far"] = limb(fe_root, fe_root + Vector2(-5, 7).rotated(sw * 0.8), 5.5, 6.5)
	p["_head"] = head
	p["_muzzle"] = muzzle
	p["_neck"] = neck_top
	p["_chest"] = chest
	p["_rump"] = rump
	p["_body"] = body_c
	p["_lean"] = lean
	p["_feet"] = [f_bl + Vector2(0, 4), f_fl + Vector2(0, 4), f_br + Vector2(0, 4), f_fr + Vector2(0, 4)]
	return p


const BACK := ["tail", "leg_bl", "leg_fl"]
const MAIN := ["rump", "body", "chest", "neck", "head", "muzzle", "leg_br", "leg_fr", "haunch"]


# draws her; returns the collar ring's position, where a leash attaches.
# `style` is kept for callers: every style draws the one box-art look.
static func draw(c: CanvasItem, origin: Vector2, s: float, pose: Dictionary, _style: String) -> Vector2:
	var p := parts(pose)
	var b := ShapeBatch.new(c)
	# the ground shadow, squashed, under her feet
	if not pose.get("no_shadow", false):
		b.polygon(ellipse(Vector2(4.0, 2.0), Vector2(62, 7)), GROUND_SHADOW)
	var face := signf(float(pose.get("_face", 1.0)))
	var lt := Vector2(LIGHT.x * (face if face != 0.0 else 1.0), LIGHT.y).normalized()
	_draw_dog(b, p, pose, lt)
	if origin != Vector2.ZERO or s != 1.0:
		# built in puppet units: place the queued points before they go out
		b._points = Transform2D(Vector2(s, 0), Vector2(0, s), origin) * b._points
	b.flush()
	return _x(p["_neck"] + Vector2(-8, 6), origin, s)


static func _fill(b: ShapeBatch, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3:
		b.polygon(pts, col)


# one hard cel shadow: the part less itself moved toward the light
static func _shade(b: ShapeBatch, pts: PackedVector2Array, lt: Vector2, d: float, col: Color) -> Array:
	var out := Geometry2D.clip_polygons(pts, _moved(pts, lt * d))
	for poly: PackedVector2Array in out:
		_fill(b, poly, col)
	return out


# one glossy sliver just inside the lit edge, kept to the region `zone`
static func _gloss(b: ShapeBatch, pts: PackedVector2Array, lt: Vector2, d: float, inset: float, zone: PackedVector2Array,
		col: Color) -> void:
	var inner := _grow(pts, -inset)
	if inner.size() < 3:
		return
	for rim: PackedVector2Array in Geometry2D.clip_polygons(inner, _moved(inner, -lt * d)):
		for poly: PackedVector2Array in Geometry2D.intersect_polygons(rim, zone):
			_fill(b, poly, col)


static func _draw_dog(b: ShapeBatch, p: Dictionary, pose: Dictionary, lt: Vector2) -> void:
	var sit: float = pose.get("sit", 0.0)
	var ln: float = p["_lean"]
	var head: Vector2 = p["_head"]
	var hrot: float = -float(pose.get("head_up", 0.0)) * 0.5
	var paws: Array[PackedVector2Array] = []
	for f: Vector2 in p["_feet"]:
		paws.append(ellipse(f + Vector2(1, -3.2), Vector2(7.0, 3.9), 0.0, 16))
	var torso_list := [p["rump"], p["body"], p["chest"], p["neck"]]
	if sit > 0.05:
		torso_list.append(p["haunch"])
	# closed (grown, then shrunk back) so the parts read as one smooth body
	var torso := _grow(_grow(_union(torso_list), 5.0), -5.0)
	var skull := _union([p["head"], p["muzzle"]])
	# the silhouette: every part drawn fat in ink first, so the outline is one
	for k in ["tail", "leg_bl", "leg_fl", "leg_br", "leg_fr", "ear_far"]:
		_fill(b, _grow(p[k], LINE), INK)
	_fill(b, _grow(torso, LINE), INK)
	_fill(b, _grow(skull, LINE), INK)
	for pw in paws:
		_fill(b, _grow(pw, LINE), INK)
	# the far side: tail, far legs and paws, the far ear, a shade down
	_fill(b, p["tail"], COAT)
	_shade(b, p["tail"], lt, 2.5, COAT_SHADE)
	_fill(b, p["leg_bl"], COAT_FAR)
	_fill(b, p["leg_fl"], COAT_FAR)
	_fill(b, paws[0], PAW_SHADE)
	_fill(b, paws[1], PAW_SHADE)
	_fill(b, p["ear_far"], EAR)
	# the body: base, the shadow on the side away from the window, the gloss
	_fill(b, torso, COAT)
	_shade(b, torso, lt, 7.0, COAT_SHADE)
	var body_c: Vector2 = p["_body"]
	_gloss(b, torso, lt, 4.5, 3.0, ellipse(body_c + Vector2(-2, -14).rotated(ln), Vector2(26, 10), ln, 16), COAT_GLOSS)
	if sit > 0.3:
		# the folded thigh's front edge, a thin inner line
		var hc: Vector2 = p["_rump"] + Vector2(8, 6)
		var hr := Vector2(17, 14) * sit
		var prev := Vector2.ZERO
		for i in range(7):
			var a := -1.35 + float(i) * 0.36
			var q := hc + Vector2(cos(a) * hr.x, sin(a) * hr.y).rotated(ln * 0.5)
			if i > 0:
				b.line(prev, q, INK, 1.1)
			prev = q
	# the near legs, each with its own shadow on the back edge
	for k in ["leg_br", "leg_fr"]:
		_fill(b, p[k], COAT)
		_shade(b, p[k], lt, 3.0, COAT_SHADE)
	for i in [2, 3]:
		_fill(b, paws[i], PAW)
		_shade(b, paws[i], lt, 1.8, PAW_SHADE)
	_draw_collar(b, p, torso)
	# the head: coat, its shadow, the grey muzzle (a darker rim where it meets
	# the black) and the muzzle's own shadow, the gloss on the crown
	var muz: Vector2 = p["_muzzle"]
	_fill(b, skull, COAT)
	var hshade := _shade(b, skull, lt, 6.0, COAT_SHADE)
	var grey_shape := _union([_blunt(muz + Vector2(1, 1).rotated(hrot), Vector2(15, 9.5), hrot + 0.06),
		ellipse(muz + Vector2(-11, 3).rotated(hrot), Vector2(8, 7), hrot)])
	var grey := _largest(Geometry2D.intersect_polygons(grey_shape, skull))
	_fill(b, _largest(Geometry2D.intersect_polygons(_grow(grey_shape, 1.5), skull)), MUZZLE_RIM)
	_fill(b, grey, MUZZLE)
	if grey.size() >= 3:
		for sh: PackedVector2Array in hshade:
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(grey, sh):
				_fill(b, poly, MUZZLE_SHADE)
	_gloss(b, skull, lt, 3.0, 2.4, ellipse(head + Vector2(-4, -11).rotated(hrot), Vector2(15, 9), hrot, 14), COAT_GLOSS)
	_draw_face(b, p, pose, hrot)
	# the near ear, in front of the head, outlined again so it reads on it
	var ear_pts: PackedVector2Array = p["ear"]
	_fill(b, _grow(ear_pts, LINE), INK)
	_fill(b, ear_pts, EAR)
	var ec := Vector2.ZERO
	for q in ear_pts:
		ec += q
	ec /= float(ear_pts.size())
	_gloss(b, ear_pts, lt, 2.6, 1.8, ellipse(ec + Vector2(-2, -5), Vector2(7, 8), 0.0, 12), EAR_GLOSS)


static func _draw_face(b: ShapeBatch, p: Dictionary, pose: Dictionary, hrot: float) -> void:
	var head: Vector2 = p["_head"]
	var muz: Vector2 = p["_muzzle"]
	# freckles: a scatter of dark dots on the grey
	for f: Vector2 in [Vector2(-2, 1), Vector2(3, 2.5), Vector2(-6, 4), Vector2(1, 5.5), Vector2(6, 0.5), Vector2(-3, 7)]:
		b.circle(muz + f.rotated(hrot), 0.85, FRECKLE)
	# the mouth: a fond little smile, or open with a tongue when she hauls
	var mouth: float = pose.get("mouth", 0.0)
	if mouth > 0.05:
		var mp := muz + Vector2(3, 7.5).rotated(hrot)
		var jaw := ellipse(mp, Vector2(8.5, 1.5 + 4.0 * mouth), hrot - 0.1, 16)
		_fill(b, _grow(jaw, 1.2), INK)
		_fill(b, jaw, MOUTH)
		_fill(b, ellipse(mp + Vector2(1.5, 1.8 * mouth).rotated(hrot), Vector2(4.8, 2.0 * mouth + 0.3), hrot, 12), TONGUE)
	else:
		var sm := [Vector2(-9, 6.5), Vector2(-4, 8.2), Vector2(1, 8.4), Vector2(6, 7.2)]
		for i in range(sm.size() - 1):
			b.line(muz + (sm[i] as Vector2).rotated(hrot), muz + (sm[i + 1] as Vector2).rotated(hrot), INK, 1.3)
	# the nose: a black bean on the tip, with a grey shine
	var nose := muz + Vector2(14.5, -3.5).rotated(hrot)
	_fill(b, ellipse(nose, Vector2(5.4, 4.4), hrot + 0.15, 16), INK)
	_fill(b, ellipse(nose + Vector2(-1.2, -1.6).rotated(hrot), Vector2(2.2, 1.1), hrot - 0.2, 10), NOSE_SHINE)
	# the eyes: big googly whites with an ink rim, a black pupil and a
	# catchlight; a hint of the far one peeks past the brow
	var eye := head + Vector2(9, -4.5).rotated(hrot)
	var blink: float = pose.get("blink", 0.0)
	var lb: float = pose.get("look_back", 0.0)
	var brow_lift: float = pose.get("brow", 0.0)
	if blink > 0.5:
		b.circle(eye, 8.4, INK)
		b.circle(eye, 7.0, COAT)
		var lid := [Vector2(-5.5, 0.5), Vector2(-2, 2.2), Vector2(2, 2.2), Vector2(5.5, 0.5)]
		for i in range(lid.size() - 1):
			b.line(eye + (lid[i] as Vector2).rotated(hrot), eye + (lid[i + 1] as Vector2).rotated(hrot), INK, 1.5)
	else:
		var far_eye := head + Vector2(17.5, -6.5).rotated(hrot)
		b.circle(far_eye, 4.8, INK)
		b.circle(far_eye, 3.6, EYE)
		b.circle(far_eye + Vector2(1.0 - 2.6 * lb, 0.4).rotated(hrot), 2.3, PUPIL)
		b.circle(eye, 8.4, INK)
		b.circle(eye, 7.0, EYE)
		_fill(b, _largest(Geometry2D.intersect_polygons(ellipse(eye, Vector2(7.0, 7.0), 0.0, 20),
			ellipse(eye + Vector2(0, 6.0), Vector2(8.0, 3.8), 0.0, 16))), EYE_SHADE)
		# `look_back` (0..1) slides the pupil to the back of the eye: a glance
		# over her shoulder without turning her whole body round
		var pp := eye + Vector2(2.0 - 4.4 * lb, -0.4).rotated(hrot)
		b.circle(pp, 4.2, PUPIL)
		b.circle(pp + Vector2(1.3, -1.6).rotated(hrot), 1.45, Color.WHITE)
	# the grey brow spot over the eye: all of her acting
	var bc := eye + Vector2(-1.5, -11.5 - brow_lift * 2.2).rotated(hrot)
	_fill(b, ellipse(bc, Vector2(4.6, 2.1), hrot - 0.18 + brow_lift * 0.22, 12), BROW)


static func _draw_collar(b: ShapeBatch, p: Dictionary, torso: PackedVector2Array) -> void:
	var nk: Vector2 = p["_neck"]
	var a := nk + Vector2(-13, 2)
	var e := nk + Vector2(6, 11)
	var d := (e - a).normalized()
	var n := d.orthogonal()
	# a band curving round the neck, its lower half in shade, the D-ring
	# hanging off it; clipped so it stops just past the neck's outline
	var neck := _grow(torso, 1.0)
	var arc := _strip(a - d * 4.0, (a + e) * 0.5 - n * 2.0, e + d * 4.0, 4.0, 4.0)
	var band := _largest(Geometry2D.intersect_polygons(arc, neck))
	if band.size() < 3:
		return
	var under := _largest(Geometry2D.intersect_polygons(band, _moved(band, -n * 4.4)))
	_fill(b, _grow(band, 1.4), INK)
	_fill(b, band, COLLAR)
	_fill(b, under, COLLAR_SHADE)
	var ring := nk + Vector2(-8, 6)
	b.circle(ring, 4.6, INK)
	b.circle(ring, 3.5, RING)
	b.circle(ring, 1.7, COLLAR_SHADE)
	b.circle(ring + Vector2(-1.4, -1.6), 0.9, Color.WHITE)
