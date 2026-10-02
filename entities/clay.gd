extends RefCounted

# Plasticine shading for the animals, shared so they all sit under the same
# light: a darker rim on the lower right, a lighter dab on the upper left.
# Every helper draws only filled circles and polygons, so a ShapeBatch
# standing in for the canvas keeps a whole animal in one draw call.
# Drawing only: nothing here reads or changes game state, and nothing here
# touches the global RNG.

# the direction shadows fall; mirrors main.gd's LIGHT
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08)
const ELLIPSE_STEPS := 18
# beyond this from the camera an animal skips its own drawing; it redraws
# every frame or two anyway, so it is back before it can be seen
const DRAW_RANGE := 1400.0


# true when the node is too far from main's camera to be seen
static func offscreen(node: Node2D, main: Object) -> bool:
	if main == null:
		return false
	var cam: Variant = main.get("cam")
	if cam == null or not (cam is Node2D):
		return false
	return node.global_position.distance_squared_to((cam as Node2D).global_position) > DRAW_RANGE * DRAW_RANGE


# an ellipse with half extents `half`, its x axis along `fwd`
static func ellipse_pts(center: Vector2, half: Vector2, fwd: Vector2, steps := ELLIPSE_STEPS) -> PackedVector2Array:
	var side := fwd.orthogonal()
	var pts := PackedVector2Array()
	pts.resize(steps)
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		pts[i] = center + fwd * (cos(a) * half.x) + side * (sin(a) * half.y)
	return pts


# a soft shadow on the ground, like main.contact_shadow but with no
# transform, so it stays inside the batch
static func ground_shadow(c: Object, at: Vector2, rx: float, ry: float, lift: float, a := 0.22) -> void:
	c.draw_colored_polygon(ellipse_pts(at + LIGHT * lift, Vector2(rx, ry), Vector2.RIGHT),
		Color(SHADOW.r, SHADOW.g, SHADOW.b, a))


static func rim_of(col: Color) -> Color:
	return Color(col.darkened(0.30), col.a)


static func lit_of(col: Color, amount := 0.16) -> Color:
	return Color(col.lightened(amount), col.a)


# a round lump: rim, body, highlight; the silhouette stays radius r
static func ball(c: Object, at: Vector2, r: float, col: Color) -> void:
	c.draw_circle(at, r, rim_of(col))
	c.draw_circle(at - LIGHT * (r * 0.10), r * 0.86, col)
	c.draw_circle(at - LIGHT * (r * 0.36), r * 0.40, lit_of(col))


# an oval lump along fwd: rim, body, highlight
static func blob(c: Object, at: Vector2, half: Vector2, fwd: Vector2, col: Color) -> void:
	var m := minf(half.x, half.y)
	c.draw_colored_polygon(ellipse_pts(at, half, fwd), rim_of(col))
	c.draw_colored_polygon(ellipse_pts(at - LIGHT * (m * 0.12), half - Vector2(m, m) * 0.14, fwd), col)
	c.draw_colored_polygon(ellipse_pts(at - LIGHT * (m * 0.48), half * 0.40, fwd, 12), lit_of(col, 0.13))


# a flat patch on a surface (a marking, a wing): no highlight of its own
static func patch(c: Object, at: Vector2, half: Vector2, fwd: Vector2, col: Color) -> void:
	c.draw_colored_polygon(ellipse_pts(at, half, fwd, 14), col)


# a tapering stroke through pts, as a run of quads: one batch, no GL lines
static func stroke(c: Object, pts: PackedVector2Array, w0: float, w1: float, col: Color) -> void:
	var n := pts.size()
	for i in range(n - 1):
		var f := float(i) / float(maxi(1, n - 2))
		var w := lerpf(w0, w1, f)
		c.draw_line(pts[i], pts[i + 1], col, w)
		if i > 0:
			c.draw_circle(pts[i], w * 0.5, col)
