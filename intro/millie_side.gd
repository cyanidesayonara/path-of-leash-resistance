class_name MillieSide
extends RefCounted

# Millie seen from the side, for the intro: a puppet of simple parts (body,
# chest, rump, neck, head, muzzle, ears, four legs, tail, collar) posed by a
# handful of numbers, drawn as the Store box art's Millie: one bold warm-black
# outline round the silhouette, a soft charcoal coat with one hard cel shadow
# away from the light and one glossy highlight toward it, a light grey muzzle
# and grey round the eyes and brows (a young dog with an old face), big
# googly eyes, tall pointed ears tipped forward, a lean, deep-chested,
# long-legged body with a white chest flash, white toes, a long low tail
# and a pink collar.
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
const EAR_FLAP := Color(0.22, 0.21, 0.25)      # the folded flap, its outer side to the light
const MUZZLE := Color(0.67, 0.63, 0.59)
const MUZZLE_SHADE := Color(0.51, 0.47, 0.45)
const MUZZLE_RIM := Color(0.42, 0.39, 0.38)
const GRIZZLE := Color(0.40, 0.39, 0.43)
const FRECKLE := Color(0.33, 0.32, 0.34)
const BROW := Color(0.76, 0.73, 0.70)
const PAW := Color(0.93, 0.90, 0.85)
const PAW_SHADE := Color(0.72, 0.68, 0.70)
const EYE := Color(0.98, 0.96, 0.91)
const EYE_SHADE := Color(0.88, 0.85, 0.80)
const PUPIL := Color(0.05, 0.04, 0.05)
const NOSE_SHINE := Color(0.52, 0.52, 0.56)
const COLLAR := Color(0.85, 0.15, 0.19)
const COLLAR_SHADE := Color(0.62, 0.64, 0.68)     # its grey reflective lining
const TAG := Color(0.98, 0.82, 0.18)
const RING := Color(0.88, 0.88, 0.92)
const MOUTH := Color(0.32, 0.07, 0.10)
const TONGUE := Color(0.94, 0.47, 0.55)
const GROUND_SHADOW := Color(0.15, 0.12, 0.10, 0.28)


static func breed_id_of(breed: Variant) -> int:
	if breed is int:
		return clampi(breed, 0, 4)
	var s := str(breed)
	match s:
		"pipa": return 1
		"mochi": return 2
		"tito": return 3
		"bruna": return 4
	return 0


static func breed_scale(bid: int) -> float:
	match bid:
		1: return 1.06
		2: return 0.88
		3: return 0.68
		4: return 1.02
	return 1.0


static func breed_palette(bid: int) -> Dictionary:
	match bid:
		1: # Pipa (Galgo - sleek fawn brindle)
			var fur := Color(0.76, 0.62, 0.44)
			var dark := Color(0.54, 0.42, 0.28)
			return {
				"fur": fur, "dark": dark, "gloss": fur.lightened(0.28),
				"far": dark.darkened(0.25), "muz": Color(0.85, 0.74, 0.58),
				"muz_sh": Color(0.66, 0.55, 0.40), "collar": Color(0.15, 0.60, 0.58),
				"collar_sh": Color(0.10, 0.42, 0.40), "ear": dark.darkened(0.15),
				"ear_gloss": fur.lightened(0.15), "ear_flap": dark
			}
		2: # Mochi (French Bulldog - chocolate fawn)
			var fur := Color(0.36, 0.24, 0.17)
			var dark := Color(0.22, 0.14, 0.09)
			return {
				"fur": fur, "dark": dark, "gloss": fur.lightened(0.30),
				"far": dark.darkened(0.25), "muz": Color(0.18, 0.14, 0.12),
				"muz_sh": Color(0.12, 0.09, 0.08), "collar": Color(0.20, 0.40, 0.70),
				"collar_sh": Color(0.12, 0.25, 0.48), "ear": dark.darkened(0.20),
				"ear_gloss": fur.lightened(0.10), "ear_flap": dark
			}
		3: # Tito (Chihuahua - golden cream)
			var fur := Color(0.88, 0.76, 0.52)
			var dark := Color(0.68, 0.56, 0.36)
			return {
				"fur": fur, "dark": dark, "gloss": fur.lightened(0.25),
				"far": dark.darkened(0.25), "muz": Color(0.92, 0.84, 0.66),
				"muz_sh": Color(0.74, 0.64, 0.46), "collar": Color(0.55, 0.30, 0.72),
				"collar_sh": Color(0.36, 0.18, 0.48), "ear": dark.darkened(0.10),
				"ear_gloss": fur.lightened(0.15), "ear_flap": dark
			}
		4: # Bruna (Gos d'Atura - shaggy blue merle)
			var fur := Color(0.42, 0.44, 0.48)
			var dark := Color(0.26, 0.28, 0.32)
			return {
				"fur": fur, "dark": dark, "gloss": fur.lightened(0.32),
				"far": dark.darkened(0.25), "muz": Color(0.68, 0.70, 0.74),
				"muz_sh": Color(0.48, 0.50, 0.54), "collar": Color(0.85, 0.15, 0.19),
				"collar_sh": Color(0.55, 0.10, 0.12), "ear": dark.darkened(0.15),
				"ear_gloss": fur.lightened(0.20), "ear_flap": dark
			}
	return {
		"fur": COAT, "dark": COAT_SHADE, "gloss": COAT_GLOSS,
		"far": COAT_FAR, "muz": MUZZLE, "muz_sh": MUZZLE_SHADE,
		"collar": COLLAR, "collar_sh": COLLAR_SHADE, "ear": EAR,
		"ear_gloss": EAR_GLOSS, "ear_flap": EAR_FLAP
	}


static var _units := {}


static func _unit_circle(n: int) -> PackedVector2Array:
	if not _units.has(n):
		var pts := PackedVector2Array()
		for i in range(n):
			var a := TAU * float(i) / float(n)
			pts.append(Vector2(cos(a), sin(a)))
		_units[n] = pts
	return _units[n]


static func ellipse(c: Vector2, r: Vector2, rot := 0.0, n := 28) -> PackedVector2Array:
	return Transform2D(rot, r, 0.0, c) * _unit_circle(n)


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


# the same hull built straight from its two tangent arcs: no hull search, so
# cheap enough for the legs every frame
static func _limb(a: Vector2, b: Vector2, wa: float, wb: float) -> PackedVector2Array:
	var dv := b - a
	var l := dv.length()
	if l <= absf(wa - wb) + 0.001:
		return ellipse(a if wa >= wb else b, Vector2.ONE * maxf(wa, wb), 0.0, 16)
	var ang := dv.angle()
	var phi := acos((wa - wb) / l)
	var pts := PackedVector2Array()
	pts.resize(18)
	for i in range(9):
		pts[i] = b + Vector2.from_angle(ang - phi + 2.0 * phi * float(i) / 8.0) * wb
		pts[9 + i] = a + Vector2.from_angle(ang + phi + (TAU - 2.0 * phi) * float(i) / 8.0) * wa
	return pts


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


# outward round joins on an already smooth, dense outline only add points:
# `smooth` mitres them instead, the same curve to a fiftieth of a unit
static func _grow(pts: PackedVector2Array, d: float, smooth := false) -> PackedVector2Array:
	var join := Geometry2D.JOIN_MITER if smooth else Geometry2D.JOIN_ROUND
	return _largest(Geometry2D.offset_polygon(pts, d, join))


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


# where her joints are for a pose: everything parts() hangs its shapes on,
# and all a leash or a placement needs. The last few poses are remembered:
# a frame asks for the same pose more than once.
static var _memo_keys: Array[int] = []
static var _memo_vals: Array[Dictionary] = []


static func anchors(pose: Dictionary) -> Dictionary:
	var key := pose.hash()
	var at := _memo_keys.find(key)
	if at >= 0:
		return _memo_vals[at]
	var a := _anchors(pose)
	_memo_keys.push_front(key)
	_memo_vals.push_front(a)
	if _memo_keys.size() > 6:
		_memo_keys.pop_back()
		_memo_vals.pop_back()
	return a


static func _anchors(pose: Dictionary) -> Dictionary:
	var bid := breed_id_of(pose.get("breed", ""))
	var sit: float = pose.get("sit", 0.0)
	var lean: float = pose["_lean_eff"] if pose.has("_lean_eff") else lerpf(pose.get("lean", 0.0), -0.62, sit)
	var crouch: float = lerpf(pose.get("crouch", 0.0), 0.0, sit)
	var reach: float = lerpf(pose.get("reach", 0.0), -0.45, sit)
	var push: float = lerpf(pose.get("push", 0.0), -1.25, sit)
	var head_up: float = pose.get("head_up", 0.0)
	var g: float = pose.get("gait", 0.0)
	var ph: float = pose.get("phase", 0.0)
	var drop := 8.0 * crouch - absf(cos(ph)) * 2.5 * g
	var body_c := Vector2(0.0, -51.0 + drop)
	var fwd := Vector2.RIGHT.rotated(lean)
	var chest := body_c + fwd * (34.0 if bid == 1 else (26.0 if bid == 2 or bid == 3 else 30.0)) + Vector2(0, -3.0 if bid == 1 else -2.0)
	var rump := body_c - fwd * (28.0 if bid == 3 else (30.0 if bid == 2 else 32.0))
	var neck_top: Vector2
	if bid == 1:
		neck_top = chest + Vector2(17.0, -32.0).rotated(-head_up * 0.6)
	elif bid == 2:
		neck_top = chest + Vector2(10.0, -20.0).rotated(-head_up * 0.6)
	elif bid == 3:
		neck_top = chest + Vector2(11.0, -22.0).rotated(-head_up * 0.6)
	else:
		neck_top = chest + Vector2(14.0, -26.0).rotated(-head_up * 0.6)
	var head := neck_top + Vector2(10.0, -10.0).rotated(-head_up)
	var swing := 14.0 * g
	var f_fl := Vector2(34.0 + reach * 18.0 + sin(ph + PI) * swing, -4.0 - maxf(0.0, cos(ph + PI)) * 7.0 * g)
	var f_fr := Vector2(42.0 + reach * 12.0 + sin(ph) * swing, -4.0 - maxf(0.0, cos(ph)) * 7.0 * g)
	var f_bl := Vector2(-30.0 - push * 16.0 + sin(ph) * swing, -4.0 - maxf(0.0, cos(ph)) * 7.0 * g)
	var f_br := Vector2(-22.0 - push * 10.0 + sin(ph + PI) * swing, -4.0 - maxf(0.0, cos(ph + PI)) * 7.0 * g)
	var muz_off := Vector2(28.0, 6.0) if bid == 1 else (Vector2(18.0, 9.0) if bid == 2 else (Vector2(17.0, 7.0) if bid == 3 else Vector2(24.0, 7.0)))
	return {
		"_head": head, "_muzzle": head + muz_off.rotated(-head_up), "_neck": neck_top,
		"_chest": chest, "_rump": rump, "_body": body_c, "_lean": lean,
		"_feet": [f_bl + Vector2(0, 4), f_fl + Vector2(0, 4), f_br + Vector2(0, 4), f_fr + Vector2(0, 4)],
		"_hock": Vector2(-5.0, -18.0).lerp(Vector2(-13.0, -4.0), sit),
		"_sit": sit, "_head_up": head_up, "_hrot": -head_up * 0.5,
		"_ear": clampf(pose.get("ear", 0.0), -0.6, 0.7), "_tail": float(pose.get("tail", 0.0)),
		"_bid": bid,
	}


# the leg shapes, hip or shoulder to paw: [far back, far front, near back,
# near front]; a hind leg is two pieces, thigh and shin
static func _legs(a: Dictionary, grow := 0.0) -> Array:
	var feet: Array = a["_feet"]
	var hock: Vector2 = a["_hock"]
	var rump: Vector2 = a["_rump"]
	var chest: Vector2 = a["_chest"]
	var out := []
	for i in range(4):
		var f: Vector2 = feet[i] - Vector2(0, 4)
		if i % 2 == 0:
			var hip := rump + (Vector2(4, 8) if i == 0 else Vector2(10, 10))
			out.append([_limb(hip, f + hock, 8.6 + grow, 4.6 + grow), _limb(f + hock, f, 4.6 + grow, 4.0 + grow)])
		else:
			out.append([_limb(chest + (Vector2(-2, 8) if i == 1 else Vector2(4, 10)), f, 6.9 + grow, 4.1 + grow)])
	return out


# the shapes of her silhouette for a pose, with the anchors
static func parts(pose: Dictionary) -> Dictionary:
	return _parts(pose, true)


# `legs` false skips the leg shapes, which the baked pieces never use
static func _parts(pose: Dictionary, legs: bool) -> Dictionary:
	var a := anchors(pose)
	var p := a.duplicate()
	var sit: float = a["_sit"]
	var lean: float = a["_lean"]
	var hrot: float = a["_hrot"]
	var head: Vector2 = a["_head"]
	var rump: Vector2 = a["_rump"]
	var chest: Vector2 = a["_chest"]
	var body_c: Vector2 = a["_body"]
	var bid: int = a["_bid"]
	var tail: float = a["_tail"]
	var t_base := rump + Vector2(-15, -7)
	if bid == 2:
		p["tail"] = _strip(t_base, t_base + Vector2(-5, -2), t_base + Vector2(-11, -3), 4.8, 2.8)
	elif bid == 3:
		var t_mid := t_base + Vector2(-10, -20).rotated(tail * 0.4)
		var t_tip := t_base + Vector2(-2, -32).rotated(tail * 0.7)
		p["tail"] = _strip(t_base, t_mid, t_tip, 3.4, 1.2)
	elif bid == 1:
		var t_mid := t_base + Vector2(-28, 16).rotated(tail * 0.5)
		var t_tip := t_base + Vector2(-58, 4).rotated(tail * 0.8)
		p["tail"] = _strip(t_base, t_mid, t_tip, 4.2, 1.4)
	elif bid == 4:
		var t_knee := t_base + Vector2(-24, 12).rotated(tail * 0.6)
		var t_tip := rump + Vector2(-49, -15).rotated(tail)
		p["tail"] = _strip(t_base, t_knee, t_tip, 8.2, 3.2)
	else:
		var t_knee := t_base + Vector2(-22, 10).rotated(tail * 0.6)
		var t_tip := rump + Vector2(-47, -17).rotated(tail)
		p["tail"] = _strip(t_base, t_knee, t_tip, 5.8, 1.6)
	if legs:
		var lg := _legs(a)
		p["leg_bl"] = _union(lg[0])
		p["leg_fl"] = lg[1][0]
		p["leg_br"] = _union(lg[2])
		p["leg_fr"] = lg[3][0]
	if bid == 1:
		p["rump"] = ellipse(rump, Vector2(17, 16), lean)
		p["haunch"] = ellipse(rump + Vector2(8, 6), Vector2(14 * sit + 0.01, 12 * sit + 0.01), lean * 0.5)
		var barrel := PackedVector2Array()
		for i in range(32):
			var an := TAU * float(i) / 32.0
			var q := Vector2(cos(an) * 45.0, sin(an) * 17.5)
			q.y *= lerpf(0.35, 1.35, (q.x + 45.0) / 90.0) if q.y > 0.0 else 0.85
			barrel.append(body_c + q.rotated(lean))
		p["body"] = barrel
		p["chest"] = ellipse(chest, Vector2(23.0, 25.5), lean)
		p["neck"] = limb(chest + Vector2(3, -7), a["_neck"], 12.0, 9.0)
		p["head"] = ellipse(head + Vector2(-1.0, 0.0).rotated(hrot), Vector2(21.0, 15.0), hrot - 0.05)
		p["muzzle"] = _blunt(a["_muzzle"] + Vector2(3.0, 0.5).rotated(hrot), Vector2(24.0, 7.8), hrot + 0.04)
		p["beard"] = PackedVector2Array()
	elif bid == 2:
		p["rump"] = ellipse(rump, Vector2(21, 20), lean)
		p["haunch"] = ellipse(rump + Vector2(8, 6), Vector2(17 * sit + 0.01, 14 * sit + 0.01), lean * 0.5)
		var barrel := PackedVector2Array()
		for i in range(32):
			var an := TAU * float(i) / 32.0
			var q := Vector2(cos(an) * 36.0, sin(an) * 22.0)
			q.y *= lerpf(0.72, 1.15, (q.x + 36.0) / 72.0) if q.y > 0.0 else 1.05
			barrel.append(body_c + q.rotated(lean))
		p["body"] = barrel
		p["chest"] = ellipse(chest, Vector2(24.0, 23.0), lean)
		p["neck"] = limb(chest + Vector2(1, -4), a["_neck"], 16.0, 12.5)
		p["head"] = ellipse(head + Vector2(-1.5, 1.0).rotated(hrot), Vector2(23.5, 20.0), hrot)
		p["muzzle"] = _blunt(a["_muzzle"] + Vector2(1.0, 3.0).rotated(hrot), Vector2(13.5, 12.0), hrot)
		p["beard"] = PackedVector2Array()
	elif bid == 3:
		p["rump"] = ellipse(rump, Vector2(17, 16), lean)
		p["haunch"] = ellipse(rump + Vector2(8, 6), Vector2(13 * sit + 0.01, 11 * sit + 0.01), lean * 0.5)
		var barrel := PackedVector2Array()
		for i in range(32):
			var an := TAU * float(i) / 32.0
			var q := Vector2(cos(an) * 34.0, sin(an) * 16.0)
			q.y *= lerpf(0.52, 1.12, (q.x + 34.0) / 68.0) if q.y > 0.0 else 0.90
			barrel.append(body_c + q.rotated(lean))
		p["body"] = barrel
		p["chest"] = ellipse(chest, Vector2(18.0, 19.0), lean)
		p["neck"] = limb(chest + Vector2(2, -5), a["_neck"], 11.5, 8.5)
		p["head"] = ellipse(head + Vector2(-1.0, -1.5).rotated(hrot), Vector2(22.0, 19.0), hrot)
		p["muzzle"] = _blunt(a["_muzzle"] + Vector2(1.0, 1.0).rotated(hrot), Vector2(12.5, 7.0), hrot)
		p["beard"] = PackedVector2Array()
	elif bid == 4:
		p["rump"] = ellipse(rump, Vector2(22, 21), lean)
		p["haunch"] = ellipse(rump + Vector2(8, 6), Vector2(18 * sit + 0.01, 15 * sit + 0.01), lean * 0.5)
		var barrel := PackedVector2Array()
		for i in range(32):
			var an := TAU * float(i) / 32.0
			var q := Vector2(cos(an) * 42.0, sin(an) * 21.5)
			q.y *= lerpf(0.62, 1.18, (q.x + 42.0) / 84.0) if q.y > 0.0 else 1.0
			barrel.append(body_c + q.rotated(lean))
		p["body"] = barrel
		p["chest"] = ellipse(chest, Vector2(22.0, 23.5), lean)
		p["neck"] = limb(chest + Vector2(2, -6), a["_neck"], 14.5, 11.5)
		p["head"] = ellipse(head + Vector2(-1.5, 0.5).rotated(hrot), Vector2(23.0, 18.5), hrot - 0.06)
		p["muzzle"] = _blunt(a["_muzzle"] + Vector2(1.5, 0.5).rotated(hrot), Vector2(20.5, 10.5), hrot + 0.05)
		var mz: Vector2 = a["_muzzle"]
		var beard := PackedVector2Array()
		for q: Vector2 in [Vector2(-3, 5), Vector2(18, 5), Vector2(18, 12), Vector2(14, 15), Vector2(7, 17),
				Vector2(0, 16), Vector2(-4, 12)]:
			beard.append(mz + q.rotated(hrot))
		p["beard"] = beard
	else:
		p["rump"] = ellipse(rump, Vector2(21, 20), lean)
		p["haunch"] = ellipse(rump + Vector2(8, 6), Vector2(17 * sit + 0.01, 14 * sit + 0.01), lean * 0.5)
		var barrel := PackedVector2Array()
		for i in range(32):
			var an := TAU * float(i) / 32.0
			var q := Vector2(cos(an) * 42.0, sin(an) * 19.5)
			q.y *= lerpf(0.58, 1.16, (q.x + 42.0) / 84.0) if q.y > 0.0 else 0.94
			barrel.append(body_c + q.rotated(lean))
		p["body"] = barrel
		p["chest"] = ellipse(chest, Vector2(20.5, 22.5), lean)
		p["neck"] = limb(chest + Vector2(2, -6), a["_neck"], 13.5, 10.5)
		p["head"] = ellipse(head + Vector2(-1.5, 0.5).rotated(hrot), Vector2(21.5, 17.5), hrot - 0.08)
		p["muzzle"] = _blunt(a["_muzzle"] + Vector2(1.5, 0.5).rotated(hrot), Vector2(19.5, 9.5), hrot + 0.06)
		var mz: Vector2 = a["_muzzle"]
		var beard := PackedVector2Array()
		for q: Vector2 in [Vector2(-2, 6), Vector2(17, 5), Vector2(16.5, 8.5), Vector2(13, 10.5), Vector2(8, 12.5),
				Vector2(3, 11.5), Vector2(-2.5, 9)]:
			beard.append(mz + q.rotated(hrot))
		p["beard"] = beard
	var sw: float = a["_ear"]
	var near_root := head + Vector2(-10, -11).rotated(hrot)
	if bid == 2:
		var e := _bat_ear(near_root, hrot, sw, 1.0)
		p["_ear_rise"] = e[0]
		p["_ear_flap"] = ellipse(e[1], Vector2(4.8, 4.8))
		p["ear"] = _union([p["_ear_rise"], p["_ear_flap"]])
		var ef := _bat_ear(head + Vector2(-3, -15).rotated(hrot), hrot, sw, 0.85)
		p["ear_far"] = _union([ef[0], ellipse(ef[1], Vector2(4.0, 4.0))])
	elif bid == 3:
		var e := _chihuahua_ear(near_root, hrot, sw, 1.0)
		p["_ear_rise"] = e[0]
		p["_ear_flap"] = ellipse(e[1], Vector2(2.4, 2.4))
		p["ear"] = _union([p["_ear_rise"], p["_ear_flap"]])
		var ef := _chihuahua_ear(head + Vector2(-3, -15).rotated(hrot), hrot, sw, 0.85)
		p["ear_far"] = _union([ef[0], ellipse(ef[1], Vector2(2.0, 2.0))])
	elif bid == 1:
		var e := _rose_ear(near_root, hrot, sw, 1.0)
		p["_ear_rise"] = e[0]
		p["_ear_flap"] = e[1]
		p["ear"] = _union([p["_ear_rise"], p["_ear_flap"]])
		var ef := _rose_ear(head + Vector2(-3, -15).rotated(hrot), hrot, sw, 0.85)
		p["ear_far"] = _union([ef[0], ef[1]])
	elif bid == 4:
		var e := _droop_ear(near_root, hrot, sw, 1.0)
		p["_ear_rise"] = e[0]
		p["_ear_flap"] = e[1]
		p["ear"] = _union([p["_ear_rise"], p["_ear_flap"]])
		var ef := _droop_ear(head + Vector2(-3, -15).rotated(hrot), hrot, sw, 0.85)
		p["ear_far"] = _union([ef[0], ef[1]])
	else:
		var e := _ear_crease(near_root, hrot, sw, 1.0)
		p["_ear_rise"] = _limb(near_root, e[0], 6.0, 5.2)
		p["_ear_flap"] = _limb(e[0], e[1], 5.4, 1.2)
		p["ear"] = _union([p["_ear_rise"], p["_ear_flap"]])
		p["ear_far"] = _button_ear(head + Vector2(-3, -15).rotated(hrot), hrot, sw, 0.8)
	return p


static func _bat_ear(root: Vector2, hrot: float, sw: float, k: float) -> Array:
	var pos := clampf(sw, 0.0, 0.7) / 0.7
	var neg := clampf(-sw, 0.0, 0.6) / 0.4
	var angle := -1.35 + 0.3 * pos - 0.4 * neg
	var tip := root + Vector2.from_angle(hrot + angle) * (24.0 * k)
	var rise := _limb(root, tip, 7.4 * k, 5.0 * k)
	return [rise, tip]


static func _chihuahua_ear(root: Vector2, hrot: float, sw: float, k: float) -> Array:
	var pos := clampf(sw, 0.0, 0.7) / 0.7
	var neg := clampf(-sw, 0.0, 0.6) / 0.4
	var angle := -1.95 + 0.35 * pos - 0.45 * neg
	var tip := root + Vector2.from_angle(hrot + angle) * (26.0 * k)
	var rise := _limb(root, tip, 6.8 * k, 2.0 * k)
	return [rise, tip]


static func _rose_ear(root: Vector2, hrot: float, sw: float, k: float) -> Array:
	var pos := clampf(sw, 0.0, 0.7) / 0.7
	var neg := clampf(-sw, 0.0, 0.6) / 0.4
	var crease := root + Vector2(-9.0, -3.0).rotated(hrot) * k
	var tip := crease + Vector2(-12.0, 2.5).rotated(hrot + 0.3 * pos - 0.4 * neg) * k
	return [_limb(root, crease, 5.2 * k, 4.0 * k), _limb(crease, tip, 4.0 * k, 1.4 * k)]


static func _droop_ear(root: Vector2, hrot: float, sw: float, k: float) -> Array:
	var pos := clampf(sw, 0.0, 0.7) / 0.7
	var neg := clampf(-sw, 0.0, 0.6) / 0.4
	var crease := root + Vector2(2.0, -4.0).rotated(hrot) * k
	var tip := crease + Vector2(3.0, 18.0).rotated(hrot + 0.25 * pos - 0.2 * neg) * k
	return [_limb(root, crease, 6.5 * k, 5.8 * k), _limb(crease, tip, 5.8 * k, 3.2 * k)]


# one ear from its root on the skull: a triangle rising to a crease, then
# the narrow tip tipped forward; `k` scales it
static func _button_ear(root: Vector2, hrot: float, sw: float, k: float) -> PackedVector2Array:
	var e := _ear_crease(root, hrot, sw, k)
	return _union([_limb(root, e[0], 6.0 * k, 5.2 * k), _limb(e[0], e[1], 5.4 * k, 1.2 * k)])


# [the crease, the folded tip] of a button ear
static func _ear_crease(root: Vector2, hrot: float, sw: float, k: float) -> Array:
	var pos := clampf(sw, 0.0, 0.7) / 0.7
	var neg := clampf(-sw, 0.0, 0.6) / 0.4
	# lifted a little off the skull, then the flap tips forward and down; a
	# lunge swings the flap back, a sulk lays the whole ear back
	var crease := root + Vector2(-1.5, -10.0).rotated(hrot - 0.5 * pos - 1.2 * neg) * k
	var fold := deg_to_rad(52.0 - 210.0 * pos + 85.0 * neg)
	return [crease, crease + Vector2.from_angle(fold + hrot) * (15.0 - 2.0 * pos) * k]


const BACK := ["tail", "leg_bl", "leg_fl"]
const MAIN := ["rump", "body", "chest", "neck", "head", "muzzle", "leg_br", "leg_fr", "haunch"]

# Baked pieces: the rigid parts (body with collar, head, ears, tail, paws)
# are drawn once per quantized pose into triangle meshes, then moved into
# place with one native transform per frame. The transform turns the
# quantized angle's remainder back in, so motion stays smooth. Only the legs
# and the eyes, mouth and brow are built live.
const Q_LEAN := 0.04
const Q_SIT := 0.1
const Q_HEAD := 0.06
const Q_EAR := 0.05
const Q_TAIL := 0.03
const CACHE_MAX := 3000
static var _torso_cache := {}
static var _head_cache := {}
static var _ear_cache := {}
static var _tail_cache := {}
static var _paw_cache := {}
static var _eye_shade := []


# a mesh: what a scratch batch collected, moved so `anchor` is the origin
static func _mesh(sb: ShapeBatch, anchor: Vector2) -> Array:
	var m := [Transform2D(0.0, -anchor) * sb._points, sb._colors]
	sb._points = PackedVector2Array()
	sb._colors = PackedColorArray()
	return m


static func _put(b: ShapeBatch, m: Array, xf: Transform2D) -> void:
	b._points.append_array(xf * (m[0] as PackedVector2Array))
	b._colors.append_array(m[1])


static func _cached(cache: Dictionary, key: Vector4i) -> Array:
	if cache.size() > CACHE_MAX:
		cache.clear()
	return cache.get(key, [])


static func _q(v: float, step: float) -> int:
	return roundi(v / step)


static func _torso_mesh(a: Dictionary, fi: int, lt: Vector2, bid: int = 0) -> Array:
	var key := Vector4i(_q(a["_lean"], Q_LEAN), _q(a["_sit"], Q_SIT), _q(a["_head_up"], Q_HEAD), fi * 10 + bid)
	var m := _cached(_torso_cache, key)
	if not m.is_empty():
		return m
	var pal := breed_palette(bid)
	var ql := float(key.x) * Q_LEAN
	var qs := float(key.y) * Q_SIT
	var p := _parts({"_lean_eff": ql, "sit": qs, "head_up": float(key.z) * Q_HEAD, "breed": bid}, false)
	var torso_list := [p["rump"], p["body"], p["chest"], p["neck"]]
	if qs > 0.05:
		torso_list.append(p["haunch"])
	# closed (grown, then shrunk back) so the parts read as one smooth body
	var torso := _grow(_grow(_union(torso_list), 5.0, true), -5.0)
	var sb := ShapeBatch.new()
	var body_c: Vector2 = p["_body"]
	_fill(sb, _grow(torso, LINE, true), INK)
	var ink := _mesh(sb, body_c)
	# base, the shadow on the side away from the window, the gloss
	_fill(sb, torso, pal.fur)
	var tshade := _shade(sb, torso, lt, 7.0, pal.dark)
	# the white flash on her chest, shaded where the body is
	var flash := _largest(Geometry2D.intersect_polygons(
		ellipse(p["_chest"] + Vector2(11, 7).rotated(ql), Vector2(7, 12), ql - 0.35, 20), torso))
	_fill(sb, flash, PAW)
	for sh: PackedVector2Array in tshade:
		for poly: PackedVector2Array in Geometry2D.intersect_polygons(flash, sh):
			_fill(sb, poly, PAW_SHADE)
	_gloss(sb, torso, lt, 4.5, 3.0, ellipse(body_c + Vector2(-2, -14).rotated(ql), Vector2(26, 10), ql, 16), pal.gloss)
	if qs > 0.3:
		# the folded thigh's front edge, a thin inner line
		var hc: Vector2 = p["_rump"] + Vector2(8, 6)
		var hr := Vector2(17, 14) * qs
		var prev := Vector2.ZERO
		for i in range(7):
			var an := -1.35 + float(i) * 0.36
			var q := hc + Vector2(cos(an) * hr.x, sin(an) * hr.y).rotated(ql * 0.5)
			if i > 0:
				sb.line(prev, q, INK, 1.1)
			prev = q
	_draw_collar(sb, p, torso, pal.collar, pal.collar_sh)
	m = [ql, ink, _mesh(sb, body_c)]
	_torso_cache[key] = m
	return m


static func _head_mesh(a: Dictionary, fi: int, lt: Vector2, bid: int = 0) -> Array:
	var key := Vector4i(_q(a["_head_up"], Q_HEAD), 0, bid, fi)
	var m := _cached(_head_cache, key)
	if not m.is_empty():
		return m
	var pal := breed_palette(bid)
	var qh := float(key.x) * Q_HEAD
	var p := _parts({"head_up": qh, "breed": bid}, false)
	var hrot: float = p["_hrot"]
	var head: Vector2 = p["_head"]
	var muz: Vector2 = p["_muzzle"]
	var skull := _union([p["head"], p["muzzle"], p["beard"]])
	var sb := ShapeBatch.new()
	_fill(sb, _grow(skull, LINE, true), INK)
	var ink := _mesh(sb, head)
	# coat, its shadow, the grey muzzle (a darker rim where it meets the
	# black) and the muzzle's own shadow, the gloss on the crown
	_fill(sb, skull, pal.fur)
	var hshade := _shade(sb, skull, lt, 6.0, pal.dark)
	# the grey face: muzzle, cheek, and a soft ring round the eye and brow
	var grey_shape := _union([_blunt(muz + Vector2(3, 1).rotated(hrot), Vector2(18, 8), hrot + 0.06), _grow(p["beard"], 0.5),
		ellipse(muz + Vector2(-11, 3).rotated(hrot), Vector2(8, 7), hrot),
		ellipse(head + Vector2(9, -4.5).rotated(hrot), Vector2(10, 9.6), hrot)])
	var grey := _largest(Geometry2D.intersect_polygons(grey_shape, skull))
	_fill(sb, _largest(Geometry2D.intersect_polygons(_grow(grey_shape, 1.5), skull)), MUZZLE_RIM)
	_fill(sb, grey, pal.muz)
	if grey.size() >= 3:
		for sh: PackedVector2Array in hshade:
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(grey, sh):
				_fill(sb, poly, pal.muz_sh)
	_gloss(sb, skull, lt, 3.0, 2.4, ellipse(head + Vector2(-4, -11).rotated(hrot), Vector2(15, 9), hrot, 14), pal.gloss)
	# a few grizzle dots on the grey, and silver grizzle through the black
	# of her crown and cheek: the salt and pepper of a wiry coat
	for f: Vector2 in [Vector2(0, 1), Vector2(5, 2.5), Vector2(-4, 3.5), Vector2(3, 5), Vector2(9, 1)]:
		sb.circle(muz + f.rotated(hrot), 0.85, FRECKLE)
	for g: Array in [[Vector2(-6, -12), Vector2(-2.5, -13)], [Vector2(0, -13.5), Vector2(3.5, -13.5)],
			[Vector2(-15, 2), Vector2(-12.5, 0)], [Vector2(-9, 8), Vector2(-6, 6.5)]]:
		sb.line(head + (g[0] as Vector2).rotated(hrot), head + (g[1] as Vector2).rotated(hrot), GRIZZLE, 1.1)
	# the nose: a black bean on the tip, with a grey shine
	var nose := muz + Vector2(18.5, -2.5).rotated(hrot)
	_fill(sb, ellipse(nose, Vector2(5.4, 4.4), hrot + 0.15, 16), INK)
	_fill(sb, ellipse(nose + Vector2(-1.2, -1.6).rotated(hrot), Vector2(2.2, 1.1), hrot - 0.2, 10), NOSE_SHINE)
	m = [qh, ink, _mesh(sb, head)]
	_head_cache[key] = m
	return m


static func _ear_mesh(a: Dictionary, fi: int, lt: Vector2, bid: int = 0) -> Array:
	var key := Vector4i(_q(a["_ear"], Q_EAR), _q(a["_head_up"], Q_HEAD), bid, fi)
	var m := _cached(_ear_cache, key)
	if not m.is_empty():
		return m
	var pal := breed_palette(bid)
	var qh := float(key.y) * Q_HEAD
	var p := _parts({"head_up": qh, "ear": float(key.x) * Q_EAR}, false)
	var head: Vector2 = p["_head"]
	var sb := ShapeBatch.new()
	_fill(sb, _grow(p["ear_far"], LINE), INK)
	var far_ink := _mesh(sb, head)
	_fill(sb, p["ear_far"], pal.ear)
	var far_paint := _mesh(sb, head)
	# the near ear, in front of the head, outlined again so it reads on it;
	# the folded tip is its own outlined flap lying over the rise
	var ear_pts: PackedVector2Array = p["ear"]
	_fill(sb, _grow(ear_pts, LINE, true), INK)
	_fill(sb, p["_ear_rise"], pal.ear)
	_gloss(sb, p["_ear_rise"], lt, 2.6, 1.6, ellipse(p["_ear_rise"][0], Vector2(12, 12), 0.0, 12), pal.ear_gloss)
	var flap: PackedVector2Array = p["_ear_flap"]
	_fill(sb, _grow(flap, LINE * 0.8), INK)
	_fill(sb, flap, pal.ear_flap)
	_gloss(sb, flap, lt, 2.0, 1.4, ellipse(flap[0], Vector2(14, 14), 0.0, 12), pal.ear_gloss)
	m = [qh, far_ink, far_paint, _mesh(sb, head)]
	_ear_cache[key] = m
	return m


static func _tail_mesh(a: Dictionary, fi: int, lt: Vector2, bid: int = 0) -> Array:
	var key := Vector4i(_q(a["_tail"], Q_TAIL), 0, bid, fi)
	var m := _cached(_tail_cache, key)
	if not m.is_empty():
		return m
	var pal := breed_palette(bid)
	var p := _parts({"tail": float(key.x) * Q_TAIL}, false)
	var rump: Vector2 = p["_rump"]
	var sb := ShapeBatch.new()
	_fill(sb, _grow(p["tail"], LINE), INK)
	var ink := _mesh(sb, rump)
	_fill(sb, p["tail"], pal.fur)
	_shade(sb, p["tail"], lt, 2.5, pal.dark)
	m = [0.0, ink, _mesh(sb, rump)]
	_tail_cache[key] = m
	return m


# a paw, white-ish, its centre at the origin: ink, near paint, far paint
static func _paw_mesh(fi: int, lt: Vector2, bid: int = 0) -> Array:
	var key_paw := fi * 10 + bid
	var m: Array = _paw_cache.get(key_paw, [])
	if not m.is_empty():
		return m
	var pal := breed_palette(bid)
	# a dark foot with white toe tips at its front
	var pw := ellipse(Vector2.ZERO, Vector2(7.2, 4.0), 0.0, 16)
	var toes := _largest(Geometry2D.intersect_polygons(pw, ellipse(Vector2(6.5, 0.8), Vector2(6.0, 4.6), 0.0, 14)))
	var sb := ShapeBatch.new()
	_fill(sb, _grow(pw, LINE), INK)
	var ink := _mesh(sb, Vector2.ZERO)
	_fill(sb, pw, pal.fur)
	_fill(sb, toes, PAW)
	_shade(sb, toes, lt, 1.4, PAW_SHADE)
	for tx: float in [3.2, 6.0]:
		sb.line(Vector2(tx, -1.5), Vector2(tx + 0.6, 2.8), PAW_SHADE, 0.8)
	var near := _mesh(sb, Vector2.ZERO)
	_fill(sb, pw, pal.far)
	_fill(sb, toes, PAW_SHADE)
	m = [ink, near, _mesh(sb, Vector2.ZERO)]
	_paw_cache[key_paw] = m
	return m


# draws her; returns the collar ring's position, where a leash attaches.
# `style` is kept for callers: every style draws the one box-art look.
static func draw(c: CanvasItem, origin: Vector2, s: float, pose: Dictionary, _style: String) -> Vector2:
	var a := anchors(pose)
	var b := ShapeBatch.new(c)
	# the ground shadow, squashed, under her feet
	if not pose.get("no_shadow", false):
		b.polygon(ellipse(Vector2(4.0, 2.0), Vector2(62, 7)), GROUND_SHADOW)
	var fi := -1 if float(pose.get("_face", 1.0)) < 0.0 else 1
	var lt := Vector2(LIGHT.x * float(fi), LIGHT.y).normalized()
	_draw_dog(b, a, pose, fi, lt)
	if origin != Vector2.ZERO or s != 1.0:
		# built in puppet units: place the queued points before they go out
		b._points = Transform2D(Vector2(s, 0), Vector2(0, s), origin) * b._points
	b.flush()
	return _x(a["_neck"] + Vector2(-8, 6), origin, s)


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


static func _draw_dog(b: ShapeBatch, a: Dictionary, pose: Dictionary, fi: int, lt: Vector2) -> void:
	var bid := int(a.get("_bid", 0))
	var pal := breed_palette(bid)
	var head: Vector2 = a["_head"]
	var head_up: float = a["_head_up"]
	var tor := _torso_mesh(a, fi, lt, bid)
	var hd := _head_mesh(a, fi, lt, bid)
	var er := _ear_mesh(a, fi, lt, bid)
	var tl := _tail_mesh(a, fi, lt, bid)
	var pw := _paw_mesh(fi, lt, bid)
	var x_torso := Transform2D(float(a["_lean"]) - float(tor[0]), a["_body"])
	var x_head := Transform2D(-(head_up - float(hd[0])) * 0.75, head)
	var x_ear := Transform2D(-(head_up - float(er[0])) * 0.5, head)
	var x_tail := Transform2D(0.0, a["_rump"])
	var x_paw: Array[Transform2D] = []
	for f: Vector2 in a["_feet"]:
		x_paw.append(Transform2D(0.0, f + Vector2(1, -3.2)))
	var legs := _legs(a)
	# the silhouette: every part drawn fat in ink first, so the outline is one
	_put(b, tl[1], x_tail)
	for leg: Array in _legs(a, LINE):
		for piece: PackedVector2Array in leg:
			_fill(b, piece, INK)
	_put(b, er[1], x_ear)
	_put(b, tor[1], x_torso)
	_put(b, hd[1], x_head)
	for xp in x_paw:
		_put(b, pw[0], xp)
	# the far side: tail, far legs and paws, the far ear, a shade down
	_put(b, tl[2], x_tail)
	for i in [0, 1]:
		for piece: PackedVector2Array in legs[i]:
			_fill(b, piece, pal.far)
	_put(b, pw[2], x_paw[0])
	_put(b, pw[2], x_paw[1])
	_put(b, er[2], x_ear)
	# the body, with its collar
	_put(b, tor[2], x_torso)
	_draw_ring(b, a["_neck"], pal.collar)
	# the near legs, each with its own shadow on the back edge
	for i in [2, 3]:
		var leg: PackedVector2Array = legs[i][0] if legs[i].size() == 1 else _union(legs[i])
		_fill(b, leg, pal.fur)
		_shade(b, leg, lt, 3.0, pal.dark)
	_put(b, pw[1], x_paw[2])
	_put(b, pw[1], x_paw[3])
	_put(b, hd[2], x_head)
	_draw_face(b, a, pose)
	_put(b, er[3], x_ear)


static func _draw_face(b: ShapeBatch, a: Dictionary, pose: Dictionary) -> void:
	var head: Vector2 = a["_head"]
	var muz: Vector2 = a["_muzzle"]
	var hrot: float = a["_hrot"]
	# the mouth: a fond little smile, or open with a tongue when she hauls
	var mouth: float = pose.get("mouth", 0.0)
	if mouth > 0.05:
		var mp := muz + Vector2(3, 7.5).rotated(hrot)
		var jr := Vector2(8.5, 1.5 + 4.0 * mouth)
		_fill(b, ellipse(mp, jr + Vector2(1.2, 1.2), hrot - 0.1, 16), INK)
		_fill(b, ellipse(mp, jr, hrot - 0.1, 16), MOUTH)
		_fill(b, ellipse(mp + Vector2(1.5, 1.8 * mouth).rotated(hrot), Vector2(4.8, 2.0 * mouth + 0.3), hrot, 12), TONGUE)
	else:
		var sm := [Vector2(-9, 6.5), Vector2(-3, 8.0), Vector2(3, 8.0), Vector2(9, 6.6)]
		for i in range(sm.size() - 1):
			b.line(muz + (sm[i] as Vector2).rotated(hrot), muz + (sm[i + 1] as Vector2).rotated(hrot), INK, 1.3)
	# the eyes: big googly whites with an ink rim, a black pupil and a
	# catchlight; a hint of the far one peeks past the brow
	var eye := head + Vector2(9, -4.5).rotated(hrot)
	var blink: float = pose.get("blink", 0.0)
	var lb: float = pose.get("look_back", 0.0)
	var brow_lift: float = pose.get("brow", 0.0)
	if blink > 0.5:
		b.circle(eye, 8.4, INK)
		b.circle(eye, 7.0, MUZZLE)
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
		if _eye_shade.is_empty():
			var sb := ShapeBatch.new()
			_fill(sb, _largest(Geometry2D.intersect_polygons(ellipse(Vector2.ZERO, Vector2(7.0, 7.0), 0.0, 20),
				ellipse(Vector2(0, 6.0), Vector2(8.0, 3.8), 0.0, 16))), EYE_SHADE)
			_eye_shade = _mesh(sb, Vector2.ZERO)
		_put(b, _eye_shade, Transform2D(0.0, eye))
		# `look_back` (0..1) slides the pupil to the back of the eye: a glance
		# over her shoulder without turning her whole body round
		var pp := eye + Vector2(2.0 - 4.4 * lb, -0.4).rotated(hrot)
		b.circle(pp, 4.2, PUPIL)
		b.circle(pp + Vector2(1.3, -1.6).rotated(hrot), 1.45, Color.WHITE)
	# the grey brow spot over the eye: all of her acting
	# a wiry tuft of three strokes, sweeping up and forward
	var bc := eye + Vector2(-2.0, -9.5 - brow_lift * 2.0).rotated(hrot)
	var br := hrot - 0.18 + brow_lift * 0.22
	for k in range(3):
		var s0 := bc + Vector2(-4.0 + float(k) * 3.0, 1.0).rotated(br)
		b.line(s0, s0 + Vector2(2.8, -2.0 - float(k) * 0.5).rotated(br), BROW, 1.8)


static func _draw_collar(b: ShapeBatch, p: Dictionary, torso: PackedVector2Array, col_c: Color = COLLAR, col_sh: Color = COLLAR_SHADE) -> void:
	var nk: Vector2 = p["_neck"]
	var a := nk + Vector2(-13, 2)
	var e := nk + Vector2(6, 11)
	var d := (e - a).normalized()
	var n := d.orthogonal()
	# a band curving round the neck, its lower half in shade, the D-ring
	# hanging off it; clipped so it stops just past the neck's outline
	var neck := _grow(torso, 1.0, true)
	var arc := _strip(a - d * 4.0, (a + e) * 0.5 - n * 2.0, e + d * 4.0, 4.0, 4.0)
	var band := _largest(Geometry2D.intersect_polygons(arc, neck))
	if band.size() < 3:
		return
	var under := _largest(Geometry2D.intersect_polygons(band, _moved(band, -n * 4.4)))
	_fill(b, _grow(band, 1.4), INK)
	_fill(b, band, col_c)
	_fill(b, under, col_sh)


# the D-ring, drawn live so it sits exactly where the leash clips on
static func _draw_ring(b: ShapeBatch, nk: Vector2, col_c: Color = COLLAR) -> void:
	var ring := nk + Vector2(-8, 6)
	b.circle(ring, 4.6, INK)
	b.circle(ring, 3.5, RING)
	b.circle(ring, 1.7, col_c)
	b.circle(ring + Vector2(-1.4, -1.6), 0.9, Color.WHITE)
	# her yellow tag, hanging from the ring
	b.circle(ring + Vector2(0.5, 6.0), 3.6, INK)
	b.circle(ring + Vector2(0.5, 6.0), 2.7, TAG)
