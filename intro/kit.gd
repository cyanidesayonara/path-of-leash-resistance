class_name IntroKit
extends RefCounted

# Helpers the intro scenes share: placing a puppet (position, scale, which way
# it faces, squash and stretch), a leash between two points that sags when
# slack and goes straight when taut, speed lines, dust puffs, a "..." bubble.

const INK := Color(0.05, 0.04, 0.06)
const LEASH := Color(0.70, 0.16, 0.20)


# Millie at pos (her feet), facing +1 right or -1 left. Returns where her
# collar ring and her mouth are on screen. `ground` is the floor's y: her
# shadow stays on it when she jumps, smaller and fainter the higher she is.
static func millie(c: CanvasItem, pos: Vector2, s: float, face: float, sq: Vector2, pose: Dictionary, ground := INF) -> Dictionary:
	var gy := pos.y if ground == INF else ground
	var lift := maxf(0.0, gy - pos.y)
	var k := clampf(1.0 - lift / 160.0, 0.35, 1.0)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(pos.x + 4.0 * s, gy + 2.0 * s), Vector2(62, 7) * s * Vector2(k, 1.0)),
		Color(0.15, 0.12, 0.10, 0.28 * k))
	pose = pose.duplicate()
	pose["no_shadow"] = true
	var xs := Vector2(face * s * sq.x, s * sq.y)
	c.draw_set_transform(pos, 0.0, xs)
	var ring_l: Vector2 = MillieSide.draw(c, Vector2.ZERO, 1.0, pose, "hybrid")
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var p := MillieSide.parts(pose)
	var mouth_l: Vector2 = p["_muzzle"] + Vector2(6, 6)
	return {"ring": pos + ring_l * xs, "mouth": pos + mouth_l * xs}


# where Millie's collar ring and mouth will be for this pose, without drawing
# her (so the leash can be drawn behind her)
static func millie_points(pos: Vector2, s: float, face: float, sq: Vector2, pose: Dictionary) -> Dictionary:
	var xs := Vector2(face * s * sq.x, s * sq.y)
	var p := MillieSide.parts(pose)
	var ring_l: Vector2 = p["_neck"] + Vector2(-8, 6)
	var mouth_l: Vector2 = p["_muzzle"] + Vector2(6, 6)
	return {"ring": pos + ring_l * xs, "mouth": pos + mouth_l * xs}


# your human at pos (their feet). Returns the leash hand on screen. `ground`
# puts their shadow on the floor (none if not given).
static func human(c: CanvasItem, pos: Vector2, s: float, face: float, sq: Vector2, pose: Dictionary, rot := 0.0,
		ground := INF) -> Vector2:
	if ground != INF:
		var lift := maxf(0.0, ground - pos.y)
		var k := clampf(1.0 - lift / 220.0, 0.3, 1.0)
		var w := 46.0 if pose.get("sit", 0.0) < 0.5 else 30.0
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(pos.x + 6.0 * s, ground + 2.0 * s), Vector2(w, 7) * s * Vector2(k, 1.0)),
			Color(0.15, 0.12, 0.10, 0.26 * k))
	var xs := Vector2(face * s * sq.x, s * sq.y)
	c.draw_set_transform(pos, rot, xs)
	var hand_l: Vector2 = HumanSide.draw(c, pose)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return pos + (hand_l * xs).rotated(rot)


# THE LEASH AS ROPE: a little verlet rope, so it swings, drags and drapes
# instead of hanging rigid. End a is always held; end b is held or free (then
# it falls and lies on the floor). It is laid once, when the scene starts (or
# time goes backwards), and settled before the first frame so it begins at
# rest; after that its ends simply move, so it never jumps. Well damped, with
# a bending stiffness (every other point kept apart) so it does not wobble or
# fold into zigzags.
const ROPE_N := 24
const ROPE_DAMP := 0.93
const ROPE_ITER := 24
static var rope_p := PackedVector2Array()
static var rope_q := PackedVector2Array()
static var rope_t := -1.0


static func _rope_step(a: Vector2, b: Vector2, b_held: bool, seg: float, floor_y: float, dt: float) -> void:
	for i in range(ROPE_N):
		var cur := rope_p[i]
		var vel := (cur - rope_q[i]) * ROPE_DAMP
		rope_q[i] = cur
		rope_p[i] = cur + vel + Vector2(0, 1500.0) * dt * dt
	for _it in range(ROPE_ITER):
		for i in range(ROPE_N - 1):
			var d := rope_p[i + 1] - rope_p[i]
			var l := d.length()
			if l < 0.0001:
				continue
			var corr := d * (1.0 - seg / l) * 0.5
			rope_p[i] += corr
			rope_p[i + 1] -= corr
		# bending: two links apart stay at least 1.25 links apart, enough to
		# stop it folding into zigzags but slack enough to drape and lie down
		for i in range(ROPE_N - 2):
			var d2 := rope_p[i + 2] - rope_p[i]
			var l2 := d2.length()
			if l2 < seg * 1.25 and l2 > 0.0001:
				var corr2 := d2 * (1.0 - seg * 1.25 / l2) * 0.2
				rope_p[i] += corr2
				rope_p[i + 2] -= corr2
		for i in range(ROPE_N):
			if rope_p[i].y > floor_y:
				rope_p[i].y = floor_y
				rope_q[i].x = lerpf(rope_q[i].x, rope_p[i].x, 0.5)
		rope_p[0] = a
		if b_held:
			rope_p[ROPE_N - 1] = b


static func rope(c: CanvasItem, t: float, a: Vector2, b: Vector2, b_held: bool, length: float, floor_y: float, w := 4.0) -> void:
	var seg := length / float(ROPE_N - 1)
	var dt := 1.0 / 240.0
	if rope_t < 0.0 or t < rope_t or rope_p.size() != ROPE_N:
		rope_p.resize(ROPE_N)
		rope_q.resize(ROPE_N)
		var sag := maxf(0.0, (length - a.distance_to(b)) * 0.5)
		for i in range(ROPE_N):
			var f := float(i) / float(ROPE_N - 1)
			var p := a.lerp(b, f) + Vector2(0, sin(f * PI) * sag)
			p.y = minf(p.y, floor_y)
			rope_p[i] = p
			rope_q[i] = p
		# settle it: two seconds of simulation before anyone sees it
		for _s in range(480):
			_rope_step(a, b, b_held, seg, floor_y, dt)
		for i in range(ROPE_N):
			rope_q[i] = rope_p[i]
		rope_t = t
	var steps := clampi(int(ceil((t - rope_t) / dt)), 0, 480)
	for _s in range(steps):
		_rope_step(a, b, b_held, seg, floor_y, dt)
	rope_t = t
	# drawn through a Catmull-Rom curve, four points to a link, so it is a
	# smooth line and not a chain of straight segments
	var sm := PackedVector2Array()
	for i in range(ROPE_N - 1):
		var p0 := rope_p[maxi(i - 1, 0)]
		var p1 := rope_p[i]
		var p2 := rope_p[i + 1]
		var p3 := rope_p[mini(i + 2, ROPE_N - 1)]
		for k in range(4):
			var u := float(k) / 4.0
			var u2 := u * u
			var u3 := u2 * u
			sm.append(0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3))
	sm.append(rope_p[ROPE_N - 1])
	c.draw_polyline(sm, INK, w + 3.0)
	c.draw_polyline(sm, LEASH, w)
	# the handle loop at the end
	c.draw_arc(rope_p[ROPE_N - 1] + Vector2(0, 6), 9.0, 0, TAU, 28, INK, 5.5)
	c.draw_arc(rope_p[ROPE_N - 1] + Vector2(0, 6), 9.0, 0, TAU, 28, LEASH, 3.0)


# a soft curl of breath (the sigh): no outline, rising and fading
static func breath(c: CanvasItem, at: Vector2, f: float) -> void:
	if f <= 0.0 or f >= 1.0:
		return
	var a := 0.55 * (1.0 - f)
	for k in range(3):
		var p := at + Vector2(14.0 * f + float(k) * 7.0, -26.0 * f - float(k) * 5.0 + sin(f * 6.0 + float(k)) * 3.0)
		c.draw_circle(p, (5.0 + float(k) * 2.0) * (0.6 + f * 0.6), Color(1, 1, 1, a))


# a leash from a to b: `slack` is how far it sags in the middle (0 is taut)
static func leash(c: CanvasItem, a: Vector2, b: Vector2, slack: float, w := 4.0) -> void:
	var pts := PackedVector2Array()
	for i in range(17):
		var f := float(i) / 16.0
		pts.append(a.lerp(b, f) + Vector2(0, sin(f * PI) * slack))
	c.draw_polyline(pts, INK, w + 3.0)
	c.draw_polyline(pts, LEASH, w)


# streaks behind something moving fast in direction dir: thin, tapering off
static func speed_lines(c: CanvasItem, at: Vector2, dir: Vector2, length: float, n := 4, a := 0.8) -> void:
	var nrm := dir.orthogonal()
	for i in range(n):
		var off := nrm * (float(i) - float(n - 1) * 0.5) * 18.0
		var back := -dir * (30.0 + float(i % 2) * 22.0)
		var p0 := at + off + back
		for k in range(4):
			var f0 := float(k) / 4.0
			var f1 := float(k + 1) / 4.0
			c.draw_line(p0 - dir * length * f0, p0 - dir * length * f1, Color(INK, a * (1.0 - f0)), 2.5 - f0 * 1.5)


static func puff(c: CanvasItem, at: Vector2, r: float, a := 1.0) -> void:
	if a <= 0.0:
		return
	c.draw_circle(at, r + 3.0, Color(INK, a))
	c.draw_circle(at, r, Color(0.97, 0.94, 0.86, a))


# a rounded rectangle as a polygon
static func rrect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in range(4):
		for i in range(7):
			var a := -PI * 0.5 + float(k) * PI * 0.5 + float(i) / 6.0 * PI * 0.5
			pts.append(cs[k] + Vector2.from_angle(a) * rad)
	return pts


# a filled shape with the intro's outline round it
static func box(c: CanvasItem, r: Rect2, rad: float, col: Color, w := 3.0) -> void:
	c.draw_colored_polygon(rrect(r.grow(w), rad + w), INK)
	c.draw_colored_polygon(rrect(r, rad), col)


static func dots(c: CanvasItem, at: Vector2, t: float) -> void:
	# a "..." speech bubble with its tail, the dots arriving one by one
	var r := Rect2(at - Vector2(46, 28), Vector2(92, 52))
	var tail := PackedVector2Array([r.position + Vector2(18, 48), r.position + Vector2(40, 48), r.position + Vector2(10, 74)])
	c.draw_colored_polygon(rrect(r.grow(3.0), 23.0), INK)
	c.draw_line(tail[0], tail[2], INK, 7.0)
	c.draw_line(tail[1], tail[2], INK, 7.0)
	c.draw_colored_polygon(tail, Color(0.99, 0.97, 0.92))
	c.draw_colored_polygon(rrect(r, 20.0), Color(0.99, 0.97, 0.92))
	for i in range(3):
		if t > float(i) * 0.25:
			c.draw_circle(r.get_center() + Vector2(-20.0 + float(i) * 20.0, 0), 5.0, INK)


static func fade(c: CanvasItem, a: float, col := Color.BLACK, size := Vector2(1280, 720)) -> void:
	if a > 0.0:
		# far past the frame: scenes move a camera, and a fade covers the screen
		c.draw_rect(Rect2(-3000, -3000, 7280, 6720), Color(col, clampf(a, 0.0, 1.0)))
