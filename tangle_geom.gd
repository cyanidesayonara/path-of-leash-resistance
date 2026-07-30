extends RefCounted

# Pure rope-vs-rope contact geometry for NPC leash tangles. Isolated so a
# bare --script regression can pin enter/exit hysteresis without booting the
# full walk scene. main.gd owns the call sites; thresholds live here as the
# named feel constants tests pin.

const ENTER_PX := 14.0
const EXIT_PX := 22.0
const BROADPHASE_PAD := 48.0


static func segment_distance(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2) -> float:
	# Closest distance between two finite segments (capsule spine).
	var ua := a1 - a0
	var ub := b1 - b0
	var r := a0 - b0
	var ua_len2 := ua.length_squared()
	var ub_len2 := ub.length_squared()
	var rua := r.dot(ua)
	var rub := r.dot(ub)
	var uaub := ua.dot(ub)
	var s := 0.0
	var t := 0.0
	if ua_len2 < 0.0001 and ub_len2 < 0.0001:
		return a0.distance_to(b0)
	if ua_len2 < 0.0001:
		t = clampf(rub / ub_len2, 0.0, 1.0)
		return a0.distance_to(b0 + ub * t)
	if ub_len2 < 0.0001:
		s = clampf(-rua / ua_len2, 0.0, 1.0)
		return (a0 + ua * s).distance_to(b0)
	var denom := ua_len2 * ub_len2 - uaub * uaub
	if absf(denom) > 0.0001:
		s = clampf((uaub * rub - ub_len2 * rua) / denom, 0.0, 1.0)
	t = (uaub * s + rub) / ub_len2
	if t < 0.0:
		t = 0.0
		s = clampf(-rua / ua_len2, 0.0, 1.0)
	elif t > 1.0:
		t = 1.0
		s = clampf((uaub - rua) / ua_len2, 0.0, 1.0)
	return (a0 + ua * s).distance_to(b0 + ub * t)


static func ropes_capsule_near(a: Array[Vector2], b: Array[Vector2], radius: float) -> bool:
	if a.size() < 2 or b.size() < 2:
		return false
	var r2 := radius * radius
	for i in range(a.size() - 1):
		for j in range(b.size() - 1):
			var d := segment_distance(a[i], a[i + 1], b[j], b[j + 1])
			if d * d <= r2:
				return true
	return false


static func rope_bounds(pts: Array[Vector2], pad: float) -> Rect2:
	if pts.is_empty():
		return Rect2()
	var rl := pts[0].x
	var rr := pts[0].x
	var rt := pts[0].y
	var rb := pts[0].y
	for p in pts:
		rl = minf(rl, p.x)
		rr = maxf(rr, p.x)
		rt = minf(rt, p.y)
		rb = maxf(rb, p.y)
	return Rect2(rl - pad, rt - pad, (rr - rl) + pad * 2.0, (rb - rt) + pad * 2.0)


static func bounds_overlap(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)


static func contact_with_hysteresis(
	a: Array[Vector2],
	b: Array[Vector2],
	was_touching: bool
) -> bool:
	var radius := EXIT_PX if was_touching else ENTER_PX
	return ropes_capsule_near(a, b, radius)
