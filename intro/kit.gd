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


# your human at pos (their feet). Returns the leash hand on screen.
static func human(c: CanvasItem, pos: Vector2, s: float, face: float, sq: Vector2, pose: Dictionary, rot := 0.0) -> Vector2:
	var xs := Vector2(face * s * sq.x, s * sq.y)
	c.draw_set_transform(pos, rot, xs)
	var hand_l: Vector2 = HumanSide.draw(c, pose)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return pos + (hand_l * xs).rotated(rot)


# THE LEASH AS ROPE: a little verlet rope, so it swings, drags and drapes
# instead of hanging rigid. End a is always held; end b is held or free
# (then it falls and lies on the floor). The state carries over between
# frames and starts again whenever time goes backwards, so a scene stays a
# function of time for anything that plays it from the start.
const ROPE_N := 26
static var rope_p := PackedVector2Array()
static var rope_q := PackedVector2Array()
static var rope_t := -1.0
static var rope_phase := -1


# `phase` names what is holding it; when it changes the rope is laid afresh as
# a loop hanging between its ends (carrying the old shape across would fling it)
static func rope(c: CanvasItem, t: float, a: Vector2, b: Vector2, b_held: bool, length: float, floor_y: float,
		phase := 0, w := 4.0) -> void:
	if rope_t < 0.0 or t < rope_t or rope_p.size() != ROPE_N or (phase != rope_phase and b_held):
		rope_p.resize(ROPE_N)
		rope_q.resize(ROPE_N)
		var sag := maxf(0.0, (length - a.distance_to(b)) * 0.5)
		for i in range(ROPE_N):
			var f := float(i) / float(ROPE_N - 1)
			var p := a.lerp(b, f) + Vector2(0, sin(f * PI) * sag)
			p.y = minf(p.y, floor_y)
			rope_p[i] = p
			rope_q[i] = p
		rope_t = t
	rope_phase = phase
	var steps := clampi(int(ceil((t - rope_t) * 240.0)), 0, 480)
	var dt := 1.0 / 240.0
	var seg := length / float(ROPE_N - 1)
	for _s in range(steps):
		for i in range(ROPE_N):
			var cur := rope_p[i]
			var vel := (cur - rope_q[i]) * 0.955
			rope_q[i] = cur
			rope_p[i] = cur + vel + Vector2(0, 1400.0) * dt * dt
		for _it in range(14):
			rope_p[0] = a
			if b_held:
				rope_p[ROPE_N - 1] = b
			for i in range(ROPE_N - 1):
				var d := rope_p[i + 1] - rope_p[i]
				var l := d.length()
				if l < 0.0001:
					continue
				var corr := d * (1.0 - seg / l) * 0.5
				if i == 0:
					rope_p[i + 1] -= corr * 2.0
				elif i + 1 == ROPE_N - 1 and b_held:
					rope_p[i] += corr * 2.0
				else:
					rope_p[i] += corr
					rope_p[i + 1] -= corr
			for i in range(ROPE_N):
				if rope_p[i].y > floor_y:
					# lying on the floor: it stops there and drags rather than slides
					rope_p[i].y = floor_y
					rope_q[i].x = lerpf(rope_q[i].x, rope_p[i].x, 0.3)
		rope_p[0] = a
		if b_held:
			rope_p[ROPE_N - 1] = b
	rope_t = t
	c.draw_polyline(rope_p, INK, w + 3.0)
	c.draw_polyline(rope_p, LEASH, w)
	# the loop at the free or held end
	c.draw_arc(rope_p[ROPE_N - 1], 7.0, 0, TAU, 12, INK, 5.0)
	c.draw_arc(rope_p[ROPE_N - 1], 7.0, 0, TAU, 12, LEASH, 2.5)


# a leash from a to b: `slack` is how far it sags in the middle (0 is taut)
static func leash(c: CanvasItem, a: Vector2, b: Vector2, slack: float, w := 4.0) -> void:
	var pts := PackedVector2Array()
	for i in range(17):
		var f := float(i) / 16.0
		pts.append(a.lerp(b, f) + Vector2(0, sin(f * PI) * slack))
	c.draw_polyline(pts, INK, w + 3.0)
	c.draw_polyline(pts, LEASH, w)


# streaks behind something moving fast in direction dir
static func speed_lines(c: CanvasItem, at: Vector2, dir: Vector2, length: float, n := 4, a := 0.8) -> void:
	var nrm := dir.orthogonal()
	for i in range(n):
		var off := nrm * (float(i) - float(n - 1) * 0.5) * 22.0
		var back := -dir * (40.0 + float(i % 2) * 30.0)
		c.draw_line(at + off + back, at + off + back - dir * length, Color(INK, a), 4.0)


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
