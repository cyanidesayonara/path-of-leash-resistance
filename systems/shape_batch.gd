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
# With `lod` on, a circle gets only as many sides as keep its rim within this
# many pixels of the true circle: 8 for a 2 px dot, 19 at 10 px, all 64 from
# about 110 px. A sign or a lawn of small discs is most of a million vertices
# a redraw at 64 sides each, for detail no screen can show.
const LOD_SAG := 0.15
const LOD_MIN := 8
# a distance crowd mark: 8 sides, not the engine's circle. circle() stays the
# 64-segment fan that matches draw_circle; this one is for hundreds of dots
const COARSE := 8

# One circle as the engine builds it, laid out as a plain triangle list (the
# centre, then two neighbouring rim points, for each of the 64 segments):
# angle = i * (TAU / 64) in 32-bit floats, cos and sin rounded to 32 bits.
# circle() moves it into place with one Transform2D multiply, native code, so
# a batched circle costs a few microseconds of script instead of a loop over
# its 192 vertices.
static var _unit_fan := PackedVector2Array()
static var _coarse_fan := PackedVector2Array()
static var _half_buf := PackedByteArray([0, 0])

var canvas: CanvasItem
# fewer sides for small circles (LOD_SAG). Off by default: circle() then
# matches draw_circle pixel for pixel, which tests/test_shape_batch.gd checks
var lod := false
# unit fans by side count, built as needed
static var _lod_fans := {}
# a triangle list: every three points are a triangle, drawn in order
var _points := PackedVector2Array()
var _colors := PackedColorArray()
var _fill := PackedColorArray()
var _fan_fill := PackedColorArray()
var _quad_fill := PackedColorArray()
var _coarse_fill := PackedColorArray()

# a rect as two triangles, (0,0) (1,0) (1,1) and (0,0) (1,1) (0,1); read only
static var UNIT_QUAD := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)])


func _init(ci: CanvasItem = null) -> void:
	canvas = ci
	_fan_fill.resize(SEGMENTS * 3)
	_quad_fill.resize(6)
	_coarse_fill.resize(COARSE * 3)


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
	if lod:
		var n := lod_sides(radius)
		if n < SEGMENTS:
			var fan: PackedVector2Array = _lod_fans.get(n, PackedVector2Array())
			if fan.is_empty():
				fan = _build_fan(n)
				_lod_fans[n] = fan
			_points.append_array(Transform2D(Vector2(radius, 0.0), Vector2(0.0, radius), pos) * fan)
			_add_colors(color, n * 3)
			return
	if _unit_fan.is_empty():
		_build_unit()
	# The engine computes cos * radius, then adds the centre, in 32-bit floats.
	# This transform's x row is (radius, 0) and its y row (0, radius), so it
	# does exactly that: radius * cos + 0 * sin, plus the centre.
	_points.append_array(Transform2D(Vector2(radius, 0.0), Vector2(0.0, radius), pos) * _unit_fan)
	_fan_fill.fill(color)
	_colors.append_array(_fan_fill)


# Same placement as circle(), eight sides instead of 64. A crowd of these stays
# one draw call and does not spend the frame building full circles.
func coarse(pos: Vector2, radius: float, color: Color) -> void:
	if _coarse_fan.is_empty():
		_build_coarse()
	_points.append_array(Transform2D(Vector2(radius, 0.0), Vector2(0.0, radius), pos) * _coarse_fan)
	_coarse_fill.fill(color)
	_colors.append_array(_coarse_fill)


# how many sides keep a circle of this radius within LOD_SAG of round
static func lod_sides(radius: float) -> int:
	if radius <= LOD_SAG * 2.0:
		return LOD_MIN
	return clampi(ceili(PI / acos(1.0 - LOD_SAG / radius)), LOD_MIN, SEGMENTS)


static func _build_fan(n: int) -> PackedVector2Array:
	var step := TAU / float(n)
	var fan := PackedVector2Array()
	for i in range(n):
		fan.append(Vector2.ZERO)
		fan.append(Vector2(cos(float(i) * step), sin(float(i) * step)))
		fan.append(Vector2(cos(float(i + 1) * step), sin(float(i + 1) * step)))
	return fan


static func _build_coarse() -> void:
	var step := TAU / float(COARSE)
	var rim := PackedVector2Array()
	for i in range(COARSE + 1):
		var angle := float(i) * step
		rim.append(Vector2(cos(angle), sin(angle)))
	for i in range(COARSE):
		_coarse_fan.append(Vector2.ZERO)
		_coarse_fan.append(rim[i])
		_coarse_fan.append(rim[i + 1])


# draw_rect(r, color), filled. The engine's corners are position,
# position + (w, 0), position + size and position + (0, h); the unit square
# scaled by (w, h) and moved to position gives the same sums in 32 bits
# (w * 1 + 0 * h + x), in one native multiply.
func rect(r: Rect2, color: Color) -> void:
	_points.append_array(Transform2D(Vector2(r.size.x, 0.0), Vector2(0.0, r.size.y), r.position) * UNIT_QUAD)
	_quad_fill.fill(color)
	_colors.append_array(_quad_fill)


# draw_line(from, to, color, width) for width >= 0
func line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	assert(width >= 0.0, "ShapeBatch.line: a width of -1 is a GL line; draw it directly")
	var dir := (from - to).orthogonal().normalized()
	var t := dir * width * 0.5
	var a := from + t
	var c := to - t
	_points.append(a)
	_points.append(from - t)
	_points.append(c)
	_points.append(a)
	_points.append(c)
	_points.append(to + t)
	_quad_fill.fill(_as_half(color))
	_colors.append_array(_quad_fill)


# draw_colored_polygon(points, color)
func polygon(points: PackedVector2Array, color: Color) -> void:
	var tri := Geometry2D.triangulate_polygon(points)
	if tri.is_empty():
		return        # the engine draws nothing for a degenerate polygon either
	for i in tri:
		_points.append(points[i])
	_add_colors(color, tri.size())


# A soft band across a strip: rows of points (left to right, the same count in
# each row) with a colour per row, blended between rows by the GPU. Rows
# fading to an alpha of zero at the strip's edges give a light or a sheen with
# no hard edge and no steps. `row_alpha` scales each row's colour; each row is
# `pts[r * n .. r * n + n)`. A column's alpha may also fade: `col_alpha`
# multiplies each column (empty means all ones).
func band(pts: PackedVector2Array, n: int, color: Color, row_alpha: PackedFloat32Array, col_alpha := PackedFloat32Array()) -> void:
	var rows := pts.size() / n
	for r in range(rows - 1):
		for i in range(n - 1):
			var a := r * n + i
			var q := [a, a + 1, a + n + 1, a, a + n + 1, a + n]
			for v: int in q:
				_points.append(pts[v])
				var ca := 1.0 if col_alpha.is_empty() else col_alpha[v % n]
				_colors.append(Color(color.r, color.g, color.b, color.a * row_alpha[v / n] * ca))


# A soft round light: `color` at the centre fading smoothly to nothing at
# `radius`. Stacked flat discs show their edges as rings; this is a few ring
# strips whose vertex colours the GPU blends, so the falloff has no steps, and
# it joins the batch's one draw call like any other shape. The falloff is
# 1 - smoothstep: flat at the centre, easing out to nothing at the rim. `core`
# (0..1) holds full strength out to that fraction of the radius first.
# Two meshes: a pool of light wants its full circle, a lamp's small halo
# a few pixels across does not, and a dozen of them are drawn every frame.
const GLOW_SMALL_R := 48.0
const GLOW_MESHES := [[32, 6], [16, 4]]   # [segments, rings]
# each mesh's unit glow as a triangle list (a centre fan, then a quad strip
# per ring), and the ring each vertex lies on, built once
static var _glow_unit: Array[PackedVector2Array] = []
static var _glow_ring: Array[PackedInt32Array] = []
# the vertex colours of a glow, by mesh, colour and core: lamps share one,
# and a pulsing glow comes back to the same few
static var _glow_cols := {}
const GLOW_CACHE := 96


static func _build_glow() -> void:
	for mesh: Array in GLOW_MESHES:
		var segs: int = mesh[0]
		var rings: int = mesh[1]
		var unit := PackedVector2Array()
		var ring := PackedInt32Array()
		var rim := PackedVector2Array()
		for i in range(segs + 1):
			rim.append(Vector2.from_angle(TAU * float(i) / float(segs)))
		for k in range(1, rings + 1):
			var r0 := float(k - 1) / float(rings)
			var r1 := float(k) / float(rings)
			for i in range(segs):
				if k == 1:
					unit.append_array([Vector2.ZERO, rim[i] * r1, rim[i + 1] * r1])
					ring.append_array([0, 1, 1])
				else:
					unit.append_array([rim[i] * r0, rim[i] * r1, rim[i + 1] * r1,
						rim[i] * r0, rim[i + 1] * r1, rim[i + 1] * r0])
					ring.append_array([k - 1, k, k, k - 1, k, k - 1])
		_glow_unit.append(unit)
		_glow_ring.append(ring)


func glow(pos: Vector2, radius: float, color: Color, core := 0.0) -> void:
	if _glow_unit.is_empty():
		_build_glow()
	var mi := 1 if radius < GLOW_SMALL_R else 0
	var rings: int = GLOW_MESHES[mi][1]
	# alpha to 1/256: what 8-bit output shows, and it keeps the cache small
	var c := Color(color.r, color.g, color.b, roundf(color.a * 256.0) / 256.0)
	var cr := snappedf(core, 0.05)
	var key := [mi, c, cr]
	var cols: PackedColorArray = _glow_cols.get(key, PackedColorArray())
	if cols.is_empty():
		var ring_col: Array[Color] = []
		for k in range(rings + 1):
			var t := float(k) / float(rings)
			var u := clampf((t - cr) / maxf(0.001, 1.0 - cr), 0.0, 1.0)
			ring_col.append(Color(c.r, c.g, c.b, 0.0 if k == rings else c.a * (1.0 - smoothstep(0.0, 1.0, u))))
		var ring: PackedInt32Array = _glow_ring[mi]
		cols.resize(ring.size())
		for i in range(ring.size()):
			cols[i] = ring_col[ring[i]]
		if _glow_cols.size() >= GLOW_CACHE:
			_glow_cols.clear()
		_glow_cols[key] = cols
	_points.append_array(Transform2D(Vector2(radius, 0.0), Vector2(0.0, radius), pos) * _glow_unit[mi])
	_colors.append_array(cols)


# Draws what is queued onto ci (the batch's own canvas by default). ci may be
# another ShapeBatch standing in for a canvas: the shapes then join its queue,
# still in order, and go out in its draw call.
func flush(ci: Object = null) -> void:
	if _points.is_empty():
		return
	var target: Object = ci if ci != null else canvas
	if target is ShapeBatch:
		var outer: ShapeBatch = target
		outer._points.append_array(_points)
		outer._colors.append_array(_colors)
	else:
		var item: CanvasItem = target
		RenderingServer.canvas_item_add_triangle_array(item.get_canvas_item(), PackedInt32Array(), _points, _colors)
	_points = PackedVector2Array()
	_colors = PackedColorArray()


# Append retained geometry without consuming it. Static, expensive shape runs
# can be built once and still join the caller's single draw call each frame.
func append_to(target: ShapeBatch) -> void:
	target._points.append_array(_points)
	target._colors.append_array(_colors)


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


# Everything else a stand-in's caller may draw: queued shapes go first, so the
# order on the canvas is the order of the calls.
func draw_arc(...args: Array) -> void:
	flush()
	canvas.callv("draw_arc", args)


func draw_polyline(...args: Array) -> void:
	flush()
	canvas.callv("draw_polyline", args)


func draw_string(...args: Array) -> void:
	flush()
	canvas.callv("draw_string", args)


func draw_string_outline(...args: Array) -> void:
	flush()
	canvas.callv("draw_string_outline", args)


func draw_multiline_string(...args: Array) -> void:
	flush()
	canvas.callv("draw_multiline_string", args)


func draw_char(...args: Array) -> void:
	flush()
	canvas.callv("draw_char", args)


func draw_style_box(...args: Array) -> void:
	flush()
	canvas.callv("draw_style_box", args)
