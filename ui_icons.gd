extends RefCounted

# The game's UI iconography, drawn as vectors.
#
# Everything on the HUD used to be ASCII - [x], [ ], #----- - and not by
# choice: the web export ships no font fallbacks, so a tick or a filled square
# arrived in the browser as a tofu box. Drawing the shapes sidesteps the font
# entirely, which means the browser and the desktop build finally agree, and
# it costs a handful of polygons per row.
#
# Static, and every function takes the CanvasItem to draw onto, so the goal
# card, the results card and anything later can share one set of shapes.

enum Check { OPEN, PARTIAL, DONE_NOW, DONE_BEFORE }

const GOLD := Color(0.94, 0.79, 0.35)
const GREEN := Color(0.56, 0.89, 0.60)
const GREEN_OLD := Color(0.44, 0.55, 0.46)
const FAINT := Color(1, 1, 1, 0.22)
const BONE := Color(0.93, 0.90, 0.83)


static func draw_check(c: CanvasItem, at: Vector2, s: float, state: int) -> void:
	# a rounded box, and what is in it says how the goal stands: open, part
	# done, done just now, or done on some previous walk
	var r := Rect2(at.x, at.y, s, s)
	var col: Color = GOLD
	match state:
		Check.DONE_NOW:
			col = GREEN
		Check.DONE_BEFORE:
			col = GREEN_OLD
		Check.PARTIAL:
			col = GOLD
	if state == Check.DONE_NOW or state == Check.DONE_BEFORE:
		c.draw_rect(r, Color(col.r, col.g, col.b, 0.20))
	c.draw_rect(r, Color(col.r, col.g, col.b, 0.85), false, 1.6)
	match state:
		Check.PARTIAL:
			c.draw_circle(r.get_center(), s * 0.18, col)
		Check.DONE_NOW, Check.DONE_BEFORE:
			# the tick, in two strokes
			var a := at + Vector2(s * 0.22, s * 0.52)
			var b := at + Vector2(s * 0.42, s * 0.74)
			var d := at + Vector2(s * 0.80, s * 0.24)
			c.draw_line(a, b, col, 2.2)
			c.draw_line(b, d, col, 2.2)


static func draw_meter(c: CanvasItem, at: Vector2, w: float, h: float, f: float,
		col := GOLD) -> void:
	# progress on a multi-step goal. A bar reads as momentum in a way "2/5"
	# alone does not, which is the whole reason the ASCII one existed.
	var r := Rect2(at.x, at.y, w, h)
	c.draw_rect(r, Color(1, 1, 1, 0.10))
	var fw: float = w * clampf(f, 0.0, 1.0)
	if fw > 1.0:
		c.draw_rect(Rect2(at.x, at.y, fw, h), col)
	c.draw_rect(r, Color(1, 1, 1, 0.16), false, 1.0)


static func draw_bone(c: CanvasItem, at: Vector2, s: float, col := BONE) -> void:
	# the currency
	c.draw_line(at + Vector2(-s * 0.55, 0), at + Vector2(s * 0.55, 0), col, s * 0.34)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			c.draw_circle(at + Vector2(s * 0.6 * sx, s * 0.26 * sy), s * 0.25, col)


static func draw_star(c: CanvasItem, at: Vector2, s: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var a := -PI * 0.5 + TAU * float(i) / 10.0
		var rr: float = s if i % 2 == 0 else s * 0.45
		pts.append(at + Vector2(cos(a), sin(a)) * rr)
	if filled:
		c.draw_colored_polygon(pts, GOLD)
	else:
		pts.append(pts[0])
		c.draw_polyline(pts, Color(0.6, 0.58, 0.52, 0.7), 1.4)


static func draw_phone_pip(c: CanvasItem, at: Vector2, s: float, on: bool) -> void:
	# one of the phone's three lives
	var r := Rect2(at.x, at.y, s * 0.62, s)
	c.draw_rect(r, Color(0.16, 0.18, 0.22))
	c.draw_rect(r.grow(-1.5), Color(0.70, 0.85, 1.0, 0.92) if on else Color(0.32, 0.34, 0.38))


static func draw_paw(c: CanvasItem, at: Vector2, s: float, col: Color) -> void:
	# the pad and four toes: used as a bullet where a tick would be wrong
	c.draw_circle(at + Vector2(0, s * 0.22), s * 0.42, col)
	for i in range(4):
		var a := -PI * 0.86 + float(i) * (PI * 0.24)
		c.draw_circle(at + Vector2(cos(a), sin(a)) * s * 0.62, s * 0.19, col)
