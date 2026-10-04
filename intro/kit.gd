class_name IntroKit
extends RefCounted

# Helpers the intro scenes share: placing a puppet (position, scale, which way
# it faces, squash and stretch), a leash between two points that sags when
# slack and goes straight when taut, speed lines, dust puffs, a "..." bubble.

const INK := Color(0.05, 0.04, 0.06)
const LEASH := Color(0.70, 0.16, 0.20)


# Millie at pos (her feet), facing +1 right or -1 left. Returns where her
# collar ring and her mouth are on screen.
static func millie(c: CanvasItem, pos: Vector2, s: float, face: float, sq: Vector2, pose: Dictionary) -> Dictionary:
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


static func dots(c: CanvasItem, at: Vector2, t: float) -> void:
	# a "..." bubble, the dots arriving one by one
	var r := Rect2(at - Vector2(42, 26), Vector2(84, 46))
	c.draw_rect(r.grow(3.0), INK)
	c.draw_rect(r, Color(0.99, 0.97, 0.92))
	for i in range(3):
		if t > float(i) * 0.25:
			c.draw_circle(r.get_center() + Vector2(-20.0 + float(i) * 20.0, 0), 5.0, INK)


static func fade(c: CanvasItem, a: float, col := Color.BLACK, size := Vector2(1280, 720)) -> void:
	if a > 0.0:
		# far past the frame: scenes move a camera, and a fade covers the screen
		c.draw_rect(Rect2(-3000, -3000, 7280, 6720), Color(col, clampf(a, 0.0, 1.0)))
