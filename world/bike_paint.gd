class_name BikePaint
extends RefCounted

# What is painted on a Barcelona bike lane, seen from above: the bicycle
# glyph with an arrow ahead of it for each way the lane runs, white edge
# lines, a dashed centre line on a two-way lane, and where a bike lane
# crosses a road or a pavement, the rows of white squares Spanish road
# marking uses for a cyclists' crossing. Drawn into the caller's batch:
# no draw call of its own.

const GLYPH_LEN := 26.0


# The bicycle glyph centred at `c`, its length along `dir` (the way the
# lane runs there), with the arrow ahead of it. `bg` is the lane under it,
# for the hollow of the wheels.
static func glyph(b: ShapeBatch, c: Vector2, dir: Vector2, col: Color, bg: Color) -> void:
	var u := dir.normalized()
	var v := u.orthogonal()
	var rear := c - u * 7.0
	var front := c + u * 7.0
	for w: Vector2 in [rear, front]:
		b.circle(w, 4.6, col)
		b.circle(w, 3.0, bg)
	# frame, seat and bars
	b.line(rear, c + u * 1.0 - v * 4.0, col, 1.4)
	b.line(c + u * 1.0 - v * 4.0, front, col, 1.4)
	b.line(rear, c - u * 1.5 + v * 0.5, col, 1.4)
	b.line(c - u * 1.5 + v * 0.5, c + u * 1.0 - v * 4.0, col, 1.4)
	b.line(c - u * 3.0 - v * 5.0, c - u * 0.2 - v * 5.0, col, 1.6)
	b.line(front - v * 3.6, front - v * 6.0 + u * 1.6, col, 1.4)
	# the arrow ahead
	var tail := c + u * 15.0
	var tip := c + u * 26.0
	b.line(tail, tip - u * 4.0, col, 2.0)
	b.polygon(PackedVector2Array([tip, tip - u * 6.0 + v * 4.0, tip - u * 6.0 - v * 4.0]), col)


# A row of white squares from `a` to `b2`: the edge of a cyclists' crossing.
static func squares(b: ShapeBatch, a: Vector2, b2: Vector2, size: float, col: Color) -> void:
	var len := a.distance_to(b2)
	if len < size:
		return
	var u := (b2 - a) / len
	var v := u.orthogonal()
	var n := int(floorf(len / (size * 2.0)))
	var start := a + u * (len - float(n) * size * 2.0 + size) * 0.5
	for i in range(n):
		var p := start + u * (float(i) * size * 2.0)
		b.quad(p - v * size * 0.5, p + u * size - v * size * 0.5, p + u * size + v * size * 0.5,
			p + v * size * 0.5, col)
