class_name ShapeBatch
extends RefCounted

# Merges a run of filled circles, polygons, rects and wide lines into ONE draw
# call. The Compatibility renderer gives every circle and polygon its own draw
# call, and starts a new one whenever a rect follows a line or the other way
# round, and draw calls are what the web build pays for.
#
# The vertices are the engine's own. draw_circle is a 64-segment fan around
# the centre (RendererCanvasCull::canvas_item_add_ellipse), draw_line with a
# width is a quad offset by half the width along the normal, a filled
# draw_rect is its four corners, and draw_colored_polygon is triangulated by
# Geometry2D.triangulate_polygon. Each is rebuilt here with the same 32-bit
# float operations in the same order (Vector2 methods run the engine's own
# code), and shapes are submitted in the order they were added, so the picture
# is the same pixel for pixel: tests/test_shape_batch.gd renders both ways
# and compares.
#
# Two ways to use it:
# - explicitly: b.circle(), b.rect(), b.line(), b.polygon(), then b.flush()
# - as a stand-in canvas: ShapeBatch.new(self) has draw_circle, draw_rect,
#   draw_line, draw_colored_polygon and draw_set_transform with the
#   CanvasItem signatures, so a drawing function that takes `c` can be handed
#   the batch unchanged. Whatever it cannot reproduce exactly - outlined
#   rects, lines with the default width of -1 (real GL lines, not triangles),
#   antialiasing, textures - flushes what is queued and goes straight to the
#   canvas, so order and pixels are kept either way.
# The batch is drawn where flush() is called, under the draw_set_transform in
# force at that moment; the stand-in's draw_set_transform flushes first.
# Anything else the function draws (text, arcs) must go to the real canvas,
# after a flush().

const SEGMENTS := 64

# One circle as the engine builds it, laid out as a plain triangle list (the
# centre, then two neighbouring rim points, for each of the 64 segments):
# angle = i * (TAU / 64) in 32-bit floats, cos and sin rounded to 32 bits.
# circle() moves it into place with one Transform2D multiply, native code, so
# a batched circle costs a few microseconds of script instead of a loop over
# its 192 vertices.
static var _unit_fan := PackedVector2Array()
static var _half_buf := PackedByteArray([0, 0])

var canvas: CanvasItem
# a triangle list: every three points are a triangle, drawn in order
var _points := PackedVector2Array()
var _colors := PackedColorArray()
var _fill := PackedColorArray()


func _init(ci: CanvasItem = null) -> void:
	canvas = ci


static func _build_unit() -> void:
	var f := PackedFloat32Array([TAU / SEGMENTS, 0.0, 0.0, 0.0])
	var step := f[0]
	var rim := PackedVector2Array()
	for i in range(SEGMENTS + 1):
		f[1] = i * step
		var angle := f[1]
		rim.append(Vector2(cos(angle), sin(angle)))
	for i in range(SEGMENTS):
		_unit_fan.append(Vector2.ZERO)
		_unit_fan.append(rim[i])
		_unit_fan.append(rim[i + 1])


# the renderer stores a line's colour as half floats (a primitive's
# per-point colours), so the same value has to arrive here rounded that way
static func _as_half(c: Color) -> Color:
	var out := c
	for i in range(4):
		_half_buf.encode_half(0, c[i])
		out[i] = _half_buf.decode_half(0)
	return out


func _add_colors(color: Color, n: int) -> void:
	if _fill.size() != n:
		_fill.resize(n)
	_fill.fill(color)
	_colors.append_array(_fill)


# draw_circle(pos, radius, color), filled
func circle(pos: Vector2, radius: float, color: Color) -> void:
	if _unit_fan.is_empty():
		_build_unit()
	# The engine computes cos * radius, then adds the centre, in 32-bit floats.
	# This transform's x row is (radius, 0) and its y row (0, radius), so it
	# does exactly that: radius * cos + 0 * sin, plus the centre.
	_points.append_array(Transform2D(Vector2(radius, 0.0), Vector2(0.0, radius), pos) * _unit_fan)
	_add_colors(color, _unit_fan.size())


# draw_rect(r, color), filled
func rect(r: Rect2, color: Color) -> void:
	_quad(r.position, r.position + Vector2(r.size.x, 0.0), r.position + r.size,
		r.position + Vector2(0.0, r.size.y), color)


# draw_line(from, to, color, width) for width >= 0
func line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	assert(width >= 0.0, "ShapeBatch.line: a width of -1 is a GL line; draw it directly")
	var dir := (from - to).orthogonal().normalized()
	var t := dir * width * 0.5
	_quad(from + t, from - t, to - t, to + t, _as_half(color))


# draw_colored_polygon(points, color)
func polygon(points: PackedVector2Array, color: Color) -> void:
	var tri := Geometry2D.triangulate_polygon(points)
	if tri.is_empty():
		return        # the engine draws nothing for a degenerate polygon either
	for i in tri:
		_points.append(points[i])
	_add_colors(color, tri.size())


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	_points.append(a)
	_points.append(b)
	_points.append(c)
	_points.append(a)
	_points.append(c)
	_points.append(d)
	_add_colors(color, 6)


func flush(ci: CanvasItem = null) -> void:
	if _points.is_empty():
		return
	var target := ci if ci != null else canvas
	RenderingServer.canvas_item_add_triangle_array(target.get_canvas_item(), PackedInt32Array(), _points, _colors)
	_points = PackedVector2Array()
	_colors = PackedColorArray()


# --- the stand-in canvas: CanvasItem's signatures -----------------------------

func draw_circle(pos: Vector2, radius: float, color: Color, filled := true, width := -1.0, antialiased := false) -> void:
	if filled and not antialiased:
		circle(pos, radius, color)
		return
	flush()
	canvas.draw_circle(pos, radius, color, filled, width, antialiased)


func draw_rect(r: Rect2, color: Color, filled := true, width := -1.0, antialiased := false) -> void:
	if filled and not antialiased:
		rect(r, color)
		return
	flush()
	canvas.draw_rect(r, color, filled, width, antialiased)


func draw_line(from: Vector2, to: Vector2, color: Color, width := -1.0, antialiased := false) -> void:
	if width >= 0.0 and not antialiased:
		line(from, to, color, width)
		return
	flush()
	canvas.draw_line(from, to, color, width, antialiased)


func draw_colored_polygon(points: PackedVector2Array, color: Color, uvs := PackedVector2Array(), texture: Texture2D = null) -> void:
	if uvs.is_empty() and texture == null:
		polygon(points, color)
		return
	flush()
	canvas.draw_colored_polygon(points, color, uvs, texture)


func draw_set_transform(pos: Vector2, rotation := 0.0, scale := Vector2.ONE) -> void:
	flush()
	canvas.draw_set_transform(pos, rotation, scale)
