class_name SceneWalkies
extends RefCounted

# Intro 1, "Walkies?": the premise in fourteen seconds and no words.
# Morning in the flat. Your human on the sofa, face lit by the phone. Millie by
# the door, looking from the leash on its hook to them and back. She jumps for
# it, trots over, and drops the loop on their knee. Waits. Nothing. She noses
# the phone; it jolts; "...". She sighs. Their hand closes on the loop without
# them looking up - and she turns, crouches, and YANKS: the leash snaps
# straight, they leave the sofa, and the two of them go out through the door
# into the sun. The title hangs from the leash by a collar round the O.

const LENGTH := 15.0
const S := 1.6                 # character scale
const MS := 1.52               # Millie's scale
const FLOOR := 610.0
const YANK_AT := 9.22          # the bark, and the cut wide for the yank
const MARGIN := Rect2(-800, -1100, 3000, 2900) # (-800, -1100) to (2200, 1800)
const DOOR := Rect2(1060, 250, 150, 360)
const HOOK := Vector2(1010, 320)
const SOFA_X := 380.0
const LEASH_LEN := 300.0
const CARRY_LEN := 120.0     # the leash gathered up in her mouth
const KNEE := Vector2(SOFA_X + 76.0, FLOOR - 104.0)   # where the loop lands
const TITLE_AT := 10.1
const TS := 1.2                # the two of them on the street
# where the phone is in your human's hand on the sofa (for the nudge)
const PHONE := Vector2(466.0, 468.0)


# the camera: [centre, zoom] in scene units. Wide enough at first to see who
# she is looking at; close on her and the hook for the jump; with her across
# the room; a push in on the crouch; a cut wide on the bark for the yank, with
# a short shake; then a cut to the street at the title. The opening creeps in
# toward her so the held shot is never quite still.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return [Vector2(640, 360), 1.0]
	if t >= YANK_AT:
		# the bark shakes the frame for a quarter second, settling to rest
		var d := t - YANK_AT
		var k := 1.0 - Anim.span(t, YANK_AT, YANK_AT + 0.28)
		return [Vector2(800, 420) + Vector2(sin(d * 97.0), sin(d * 71.0)) * 7.0 * k * k, 1.12]
	var cx: float = Anim.k(t, [[0.0, 645.0], [2.2, 668.0, "io"], [2.7, 930.0, "io"], [3.45, 930.0], [4.9, 620.0, "io"],
		[8.55, 620.0], [8.95, 570.0, "io"]])
	var cy: float = Anim.k(t, [[0.0, 425.0], [2.2, 430.0, "io"], [2.7, 445.0, "io"], [4.9, 450.0, "io"], [8.55, 450.0],
		[8.95, 455.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.08], [2.2, 1.14, "io"], [2.7, 1.6, "io"], [3.45, 1.6], [4.9, 1.45, "io"], [8.55, 1.45],
		[8.95, 1.75, "io"]])
	return [Vector2(cx, cy), z]


# ------------------------------------------------------------ the backgrounds
# Every background layer but the door is static, so each is built once into a
# triangle list and submitted in one draw call. The room is seen from eye
# height HORIZON, its floor, ceiling and side walls receding to VP_X: _fp()
# places a point at depth z in front of the back wall, on a level (a height on
# that wall, the floor by default). The sun is a morning one from the upper
# left; shadows are purple-brown (SHADE), never grey. Props get thin warm
# outlines (PROP_INK), the sofa the characters' heavy one (LINE).
const VP_X := 640.0
const HORIZON := 380.0
const PERSP := 1000.0
const WIN := Rect2(150, 130, 210, 230)
const CORNER_L := -340.0
const CORNER_R := 1540.0
const CEIL := 76.0
const RAIL := 100.0
const SKIRT := 584.0
const LINE := Color(0.10, 0.07, 0.08)
const PROP_INK := Color(0.30, 0.17, 0.14)
const SHADE := Color(0.26, 0.11, 0.22)
const SUN := Color(1.0, 0.90, 0.56, 0.42)
const WALL := Color(0.94, 0.83, 0.67)
const TRIM := Color(0.97, 0.94, 0.87)
const TRIM_SH := Color(0.80, 0.71, 0.67)
const BRASS := Color(0.82, 0.62, 0.30)
const WOOD := Color(0.54, 0.34, 0.22)

static var _bg_room: Tris
static var _bg_dressing: Tris
static var _bg_light: Tris
static var _bg_sofa: Tris
static var _bg_sun: Tris
static var _bg_street: Tris


# A triangle list drawn in one call, with a colour per point.
class Tris:
	extends RefCounted
	var pts := PackedVector2Array()
	var cols := PackedColorArray()

	func tri(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
		pts.append(a)
		pts.append(b)
		pts.append(c)
		cols.append(ca)
		cols.append(cb)
		cols.append(cc)

	func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
		tri(a, b, c, col, col, col)
		tri(a, c, d, col, col, col)

	func quad4(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
		tri(a, b, c, ca, cb, cc)
		tri(a, c, d, ca, cc, cd)

	func rect(r: Rect2, col: Color) -> void:
		quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col)

	func vgrad(r: Rect2, top: Color, bot: Color) -> void:
		quad4(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), top, top, bot, bot)

	func hgrad(r: Rect2, left: Color, right: Color) -> void:
		quad4(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), left, right, right, left)

	func line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
		var n := (b - a).orthogonal().normalized() * w * 0.5
		quad(a + n, b + n, b - n, a - n, col)

	func poly(p: PackedVector2Array, col: Color) -> void:
		for i in Geometry2D.triangulate_polygon(p):
			pts.append(p[i])
			cols.append(col)

	func fan(p: PackedVector2Array, col: Color) -> void:
		for i in range(1, p.size() - 1):
			tri(p[0], p[i], p[i + 1], col, col, col)

	func oval(c: Vector2, r: Vector2, col: Color, n := 20) -> void:
		var p := PackedVector2Array()
		for i in range(n):
			var a := TAU * float(i) / float(n)
			p.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		fan(p, col)

	# a shape with an outline w thick round it
	func inked(p: PackedVector2Array, col: Color, w: float, ink: Color) -> void:
		for o in Geometry2D.offset_polygon(p, w, Geometry2D.JOIN_ROUND):
			poly(o, ink)
		poly(p, col)

	# the part of p inside mask: a cel shadow or highlight that keeps to its shape
	func clip(p: PackedVector2Array, mask: PackedVector2Array, col: Color) -> void:
		for o in Geometry2D.intersect_polygons(p, mask):
			poly(o, col)

	var _mesh: ArrayMesh

	# Every layer but the door is built once, so it goes up as a mesh once and
	# each frame only references it: resubmitting a big triangle array copies
	# every vertex, every frame (the street alone doubled the film's CPU cost).
	func draw(ci: CanvasItem) -> void:
		if pts.is_empty():
			return
		if _mesh == null:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = pts
			arrays[Mesh.ARRAY_COLOR] = cols
			_mesh = ArrayMesh.new()
			_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		ci.draw_mesh(_mesh, null)

	# for the one layer rebuilt every frame (the door)
	func draw_once(ci: CanvasItem) -> void:
		if not pts.is_empty():
			RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array(), pts, cols)


static func _fp(x: float, z: float, level := FLOOR) -> Vector2:
	var s := PERSP / (PERSP - z)
	return Vector2(VP_X + (x - VP_X) * s, HORIZON + (level - HORIZON) * s)


# a fixed scatter in [0, 1): the dressing varies, the same way every frame
static func _h(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 78.233) * 43758.5453, 1.0)


static func _rr(r: Rect2, rad: float, n := 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in range(4):
		for i in range(n + 1):
			var a := -PI * 0.5 + float(k) * PI * 0.5 + float(i) / float(n) * PI * 0.5
			pts.append(cs[k] + Vector2.from_angle(a) * rad)
	return pts


static func _pts(arr: Array) -> PackedVector2Array:
	return PackedVector2Array(arr)


static func _shift(p: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in p:
		out.append(q + by)
	return out


static func _dim(col: Color, k: float) -> Color:
	return Color(col.r * k, col.g * k, col.b * k, col.a)


static func _room(c: CanvasItem, _t: float, door_open: float) -> void:
	if _bg_room == null:
		_bg_room = Tris.new()
		_build_room(_bg_room)
	_bg_room.draw(c)
	_door(c, door_open)


static func _build_room(b: Tris) -> void:
	var l := MARGIN.position.x - 300.0
	var span := MARGIN.size.x + 600.0
	var top := MARGIN.position.y - 300.0
	# the ceiling: whitewashed Catalan vaults between dark beams, coming toward you
	b.vgrad(Rect2(l, top, span, CEIL - top), Color(0.66, 0.58, 0.58), Color(0.95, 0.91, 0.84))
	var edges: Array[float] = [CORNER_L]
	var bx := -200.0
	while bx < CORNER_R:
		edges.append(bx)
		var sd := signf(VP_X - bx)
		b.quad(_fp(bx + 13.0 * sd, 0, CEIL - 24), _fp(bx + 13.0 * sd, 0, CEIL), _fp(bx + 13.0 * sd, 900, CEIL),
			_fp(bx + 13.0 * sd, 900, CEIL - 24), Color(0.30, 0.19, 0.15))
		b.quad(_fp(bx - 13, 0, CEIL), _fp(bx + 13, 0, CEIL), _fp(bx + 13, 900, CEIL), _fp(bx - 13, 900, CEIL),
			Color(0.47, 0.31, 0.21))
		bx += 280.0
	edges.append(CORNER_R)
	# the back wall, its top rising in a shallow arch under each vault
	var frieze := Color(0.96, 0.89, 0.76)
	b.rect(Rect2(l, CEIL, span, FLOOR - CEIL), WALL)
	b.rect(Rect2(l, CEIL, span, RAIL - CEIL), frieze)
	for i in range(edges.size() - 1):
		var x0 := edges[i] + (13.0 if i > 0 else 0.0)
		var x1 := edges[i + 1] - (13.0 if i < edges.size() - 2 else 0.0)
		var rise := minf(30.0, (x1 - x0) * 0.13)
		var arch := PackedVector2Array()
		for j in range(13):
			var u := float(j) / 12.0
			arch.append(Vector2(lerpf(x0, x1, u), CEIL - rise * sin(u * PI)))
		b.fan(arch, frieze)
		for j in range(12):
			b.quad(arch[j] - Vector2(0, 8), arch[j + 1] - Vector2(0, 8), arch[j + 1], arch[j], Color(SHADE, 0.16))
	for i in range(1, edges.size() - 1):
		b.rect(Rect2(edges[i] - 13, CEIL - 24, 26, 26), Color(0.36, 0.23, 0.16))
		b.rect(Rect2(edges[i] - 13, CEIL + 2, 26, 6), Color(SHADE, 0.18))
	# the wallpaper: a two-tone stripe with a small diamond between
	var stripe := Color(0.91, 0.79, 0.63)
	var motif := Color(0.85, 0.70, 0.54)
	var sx := -1100.0
	var col_i := 0
	while sx < 2500.0:
		b.rect(Rect2(sx, RAIL, 15, SKIRT - RAIL), stripe)
		var my := RAIL + 26.0 + (22.0 if col_i % 2 == 1 else 0.0)
		while my < SKIRT - 16.0:
			var m := Vector2(sx + 33.0, my)
			b.quad(m + Vector2(0, -5), m + Vector2(3.5, 0), m + Vector2(0, 5), m + Vector2(-3.5, 0), motif)
			my += 44.0
		sx += 52.0
		col_i += 1
	# the picture rail, and the wall darkening up toward it and down to the skirting
	b.vgrad(Rect2(l, RAIL + 7, span, 260), Color(SHADE, 0.16), Color(SHADE, 0.0))
	b.vgrad(Rect2(l, SKIRT - 70, span, 70), Color(SHADE, 0.0), Color(SHADE, 0.12))
	b.rect(Rect2(l, RAIL, span, 3), TRIM)
	b.rect(Rect2(l, RAIL + 3, span, 4), TRIM_SH)
	b.vgrad(Rect2(l, RAIL + 7, span, 5), Color(SHADE, 0.22), Color(SHADE, 0.0))
	_build_wall_sun(b)
	_build_window(b)
	_build_pictures(b)
	# the floorboards, receding: each plank its own tone, a sheen along its far
	# edge and a streak of grain, on a dark seam
	b.rect(Rect2(l, FLOOR, span, MARGIN.end.y + 300.0 - FLOOR), Color(0.30, 0.17, 0.13))
	var pw := 50.0
	var pl := 330.0
	var row := 0
	while _fp(0, float(row) * pw).y < MARGIN.end.y + 100.0:
		var z0 := float(row) * pw
		var z1 := z0 + pw
		var xw := -1400.0 + fposmod(float(row) * 137.0, pl)
		var j := 0
		while xw < 2700.0:
			var col := Color(0.58, 0.38, 0.24).lerp(Color(0.72, 0.50, 0.31), _h(row * 31 + j))
			var g := 1.3
			b.quad(_fp(xw + g, z0 + g), _fp(xw + pl - g, z0 + g), _fp(xw + pl - g, z1 - g), _fp(xw + g, z1 - g), col)
			b.quad(_fp(xw + g, z0 + g), _fp(xw + pl - g, z0 + g), _fp(xw + pl - g, z0 + g + 5), _fp(xw + g, z0 + g + 5),
				col.lightened(0.12))
			var gx := xw + pl * (0.1 + 0.4 * _h(row * 7 + j * 3))
			var gz := z0 + pw * (0.45 + 0.3 * _h(row * 5 + j))
			b.quad(_fp(gx, gz), _fp(gx + pl * 0.4, gz), _fp(gx + pl * 0.4, gz + 1.6), _fp(gx, gz + 1.6), col.darkened(0.09))
			xw += pl
			j += 1
		row += 1
	# the window's reflection in the polish, and the shade where floor meets wall
	for rx: float in [166.0, 268.0]:
		b.quad4(Vector2(rx, FLOOR + 2), Vector2(rx + 86, FLOOR + 2), Vector2(rx + 92, FLOOR + 64), Vector2(rx + 6, FLOOR + 64),
			Color(1.0, 0.95, 0.80, 0.20), Color(1.0, 0.95, 0.80, 0.20), Color(1.0, 0.95, 0.80, 0.0), Color(1.0, 0.95, 0.80, 0.0))
	b.vgrad(Rect2(l, FLOOR, span, 22), Color(SHADE, 0.30), Color(SHADE, 0.0))
	# the skirting board
	b.rect(Rect2(l, SKIRT, span, FLOOR - SKIRT), Color(0.95, 0.91, 0.83))
	b.rect(Rect2(l, SKIRT, span, 4), Color(1.0, 0.98, 0.93))
	b.rect(Rect2(l, SKIRT + 4, span, 2), TRIM_SH)
	b.rect(Rect2(l, FLOOR - 3, span, 3), Color(0.60, 0.48, 0.44))
	b.vgrad(Rect2(l, SKIRT - 6, span, 6), Color(SHADE, 0.0), Color(SHADE, 0.16))
	_side_wall(b, CORNER_L)
	_side_wall(b, CORNER_R)
	_build_door_frame(b)
	_build_hooks(b)


# a side wall from its corner with the back wall out toward you, with the
# picture rail and skirting running along it; the left one has a window (the
# sun on the back wall comes from it), the right one a doorway to the hall
static func _side_wall(b: Tris, cx: float) -> void:
	var far := 860.0
	var left := cx < VP_X
	var col := Color(0.86, 0.73, 0.60) if left else Color(0.89, 0.77, 0.63)
	b.quad(_fp(cx, 0, CEIL - 24), _fp(cx, far, CEIL - 24), _fp(cx, far, FLOOR), _fp(cx, 0, FLOOR), col)
	b.quad(_fp(cx, 0, CEIL - 24), _fp(cx, far, CEIL - 24), _fp(cx, far, RAIL), _fp(cx, 0, RAIL), col.lightened(0.06))
	var z := 0.0
	while z < far - 200.0:
		b.quad(_fp(cx, z, RAIL + 7), _fp(cx, z + 12, RAIL + 7), _fp(cx, z + 12, SKIRT), _fp(cx, z, SKIRT), col.darkened(0.04))
		z += 40.0
	b.quad(_fp(cx, 0, RAIL), _fp(cx, far, RAIL), _fp(cx, far, RAIL + 7), _fp(cx, 0, RAIL + 7), TRIM_SH)
	b.quad(_fp(cx, 0, SKIRT), _fp(cx, far, SKIRT), _fp(cx, far, FLOOR), _fp(cx, 0, FLOOR), Color(0.88, 0.83, 0.76))
	b.quad(_fp(cx, 0, SKIRT), _fp(cx, far, SKIRT), _fp(cx, far, SKIRT + 4), _fp(cx, 0, SKIRT + 4), TRIM)
	if left:
		var w0 := 110.0
		var w1 := 300.0
		b.quad(_fp(cx, w0 - 12, 138), _fp(cx, w1 + 12, 138), _fp(cx, w1 + 12, 446), _fp(cx, w0 - 12, 446), TRIM)
		b.quad4(_fp(cx, w0, 150), _fp(cx, w1, 150), _fp(cx, w1, 432), _fp(cx, w0, 432),
			Color(0.66, 0.84, 0.96), Color(0.66, 0.84, 0.96), Color(0.98, 0.95, 0.86), Color(0.98, 0.95, 0.86))
		var wm := (w0 + w1) * 0.5
		b.quad(_fp(cx, wm - 4, 150), _fp(cx, wm + 4, 150), _fp(cx, wm + 4, 432), _fp(cx, wm - 4, 432), TRIM)
		b.quad(_fp(cx, w0, 240), _fp(cx, w1, 240), _fp(cx, w1, 247), _fp(cx, w0, 247), TRIM)
		b.quad(_fp(cx, w0 - 16, 446), _fp(cx, w1 + 16, 446), _fp(cx, w1 + 16, 456), _fp(cx, w0 - 16, 456), Color(0.92, 0.88, 0.80))
	else:
		b.quad(_fp(cx, 76, 232), _fp(cx, 264, 232), _fp(cx, 264, FLOOR), _fp(cx, 76, FLOOR), TRIM)
		b.quad(_fp(cx, 90, 248), _fp(cx, 250, 248), _fp(cx, 250, FLOOR), _fp(cx, 90, FLOOR), Color(0.50, 0.38, 0.36))
		b.quad(_fp(cx, 90, 248), _fp(cx, 104, 248), _fp(cx, 104, FLOOR), _fp(cx, 90, FLOOR), Color(0.62, 0.50, 0.46))
	b.rect(Rect2(cx - 1.5, CEIL - 24, 3, FLOOR - CEIL + 24), Color(SHADE, 0.22))


# the side window's sun, in four hard-edged panes on the back wall beside the
# window: vertical sides, the top and bottom slanting down away from the sun
static func _build_wall_sun(b: Tris) -> void:
	for pu: Vector2 in [Vector2(0.0, 0.46), Vector2(0.54, 1.0)]:
		for pv: Vector2 in [Vector2(0.0, 0.33), Vector2(0.39, 1.0)]:
			var q := PackedVector2Array()
			for e: Vector2 in [Vector2(pu.x, pv.x), Vector2(pu.y, pv.x), Vector2(pu.y, pv.y), Vector2(pu.x, pv.y)]:
				q.append(Vector2(422.0 + 116.0 * e.x, 150.0 + 236.0 * e.y + 52.0 * e.x))
			b.quad(q[0], q[1], q[2], q[3], Color(SUN, 0.30))


# the window over the sofa: a deep reveal, a white sash with four panes, the
# house across the street in the sun, teal curtains tied back on a brass rod
static func _build_window(b: Tris) -> void:
	var w := WIN
	b.rect(Rect2(w.position + Vector2(9, 9), w.size).grow(13.0), Color(SHADE, 0.14))
	b.rect(w.grow(13.0), TRIM_SH)
	b.rect(Rect2(w.position - Vector2(13, 13), w.size + Vector2(23, 23)), TRIM)
	b.rect(Rect2(w.position - Vector2(13, 13), Vector2(w.size.x + 23, 3)), Color(1.0, 0.98, 0.94))
	b.rect(w, Color(0.78, 0.68, 0.58))
	var g := Rect2(160, 137, 200, 223)
	# the view: sky, an ochre front in the sun with its rose neighbour, green
	# shutters and iron balconies
	b.vgrad(g, Color(0.48, 0.72, 0.93), Color(0.86, 0.92, 0.95))
	var ochre := Color(0.96, 0.80, 0.56)
	var rose := Color(0.93, 0.68, 0.60)
	b.rect(Rect2(160, 194, 112, 166), ochre)
	b.rect(Rect2(160, 188, 112, 8), ochre.darkened(0.14))
	b.rect(Rect2(272, 162, 88, 198), rose)
	b.rect(Rect2(272, 156, 88, 8), rose.darkened(0.14))
	b.rect(Rect2(268, 162, 4, 198), Color(SHADE, 0.25))
	var shut := Color(0.30, 0.54, 0.42)
	for wv: Vector3 in [Vector3(182, 216, 0), Vector3(226, 216, 1), Vector3(182, 306, 1), Vector3(226, 306, 0),
			Vector3(290, 190, 1), Vector3(326, 190, 0), Vector3(290, 282, 0), Vector3(326, 282, 1)]:
		var wr := Rect2(wv.x, wv.y, 24, 50)
		b.rect(Rect2(wr.position - Vector2(3, 6), Vector2(30, 4)), Color(1, 1, 1, 0.35))
		if wv.z > 0.5:
			b.rect(wr, Color(0.24, 0.18, 0.20))
			b.rect(Rect2(wr.position.x - 7, wr.position.y, 7, 50), shut)
			b.rect(Rect2(wr.end.x, wr.position.y, 7, 50), shut.darkened(0.15))
		else:
			b.rect(wr, shut)
			var sy := wr.position.y + 4
			while sy < wr.end.y:
				b.rect(Rect2(wr.position.x, sy, 24, 1.2), shut.darkened(0.25))
				sy += 5.0
			b.rect(Rect2(wr.position.x + 11.5, wr.position.y, 1, 50), shut.darkened(0.35))
		# a balcony: the slab, its hard shadow, the railing
		var by := wr.end.y
		b.quad(Vector2(wr.position.x - 9, by + 3), Vector2(wr.end.x + 9, by + 3), Vector2(wr.end.x + 15, by + 13),
			Vector2(wr.position.x - 3, by + 13), Color(SHADE, 0.28))
		b.rect(Rect2(wr.position.x - 9, by, 42, 4), Color(0.93, 0.90, 0.84))
		b.rect(Rect2(wr.position.x - 8, by - 18, 40, 1.6), Color(0.16, 0.14, 0.16))
		var rx := wr.position.x - 7
		while rx < wr.end.x + 9:
			b.rect(Rect2(rx, by - 18, 1.0, 18), Color(0.16, 0.14, 0.16))
			rx += 4.0
	# geraniums on one balcony
	for f: Vector3 in [Vector3(292, 236, 5), Vector3(300, 233, 4), Vector3(309, 236, 5)]:
		b.oval(Vector2(f.x, f.y), Vector2(f.z, f.z), Color(0.30, 0.52, 0.26), 10)
		b.oval(Vector2(f.x - 1, f.y - 3), Vector2(2.2, 2.2), Color(0.90, 0.24, 0.26), 8)
	b.rect(g, Color(0.80, 0.90, 1.0, 0.16))
	# the sash, its glazing bars, and a glint on each pane
	var fr := Color(0.97, 0.96, 0.92)
	var frs := Color(0.74, 0.70, 0.72)
	for r: Rect2 in [Rect2(160, 137, 200, 8), Rect2(160, 352, 200, 8), Rect2(160, 137, 8, 223), Rect2(352, 137, 8, 223),
			Rect2(255, 137, 10, 223), Rect2(160, 243, 200, 7)]:
		b.rect(r, fr)
	for r: Rect2 in [Rect2(168, 145, 87, 3), Rect2(265, 145, 87, 3), Rect2(168, 250, 87, 3), Rect2(265, 250, 87, 3),
			Rect2(168, 145, 3, 98), Rect2(265, 145, 3, 98), Rect2(168, 250, 3, 102), Rect2(265, 250, 3, 102)]:
		b.rect(r, Color(frs, 0.5))
	for p: Rect2 in [Rect2(168, 145, 87, 98), Rect2(265, 145, 87, 98), Rect2(168, 250, 87, 102), Rect2(265, 250, 87, 102)]:
		var x0 := p.position.x
		var pw := p.size.x
		b.quad(Vector2(x0 + 0.12 * pw, p.end.y), Vector2(x0 + 0.30 * pw, p.end.y), Vector2(x0 + 0.74 * pw, p.position.y),
			Vector2(x0 + 0.56 * pw, p.position.y), Color(1, 1, 1, 0.20))
		b.quad(Vector2(x0 + 0.36 * pw, p.end.y), Vector2(x0 + 0.42 * pw, p.end.y), Vector2(x0 + 0.86 * pw, p.position.y),
			Vector2(x0 + 0.80 * pw, p.position.y), Color(1, 1, 1, 0.14))
	# the marble sill
	b.rect(Rect2(150, 360, 210, 6), Color(0.72, 0.64, 0.58))
	b.rect(Rect2(132, 366, 248, 12), Color(0.96, 0.93, 0.87))
	b.rect(Rect2(132, 366, 248, 3), Color(1.0, 0.99, 0.95))
	b.rect(Rect2(132, 375, 248, 3), Color(0.84, 0.79, 0.76))
	b.quad(Vector2(134, 378), Vector2(380, 378), Vector2(386, 388), Vector2(140, 388), Color(SHADE, 0.20))
	# the rod and the curtains, gathered by tie-backs
	b.line(Vector2(100, 112), Vector2(410, 112), BRASS.darkened(0.2), 5.0)
	b.line(Vector2(100, 111), Vector2(410, 111), BRASS.lightened(0.2), 1.5)
	for fx: float in [98.0, 412.0]:
		b.oval(Vector2(fx, 112), Vector2(6, 6), BRASS, 14)
		b.oval(Vector2(fx - 2, 110), Vector2(2, 2), BRASS.lightened(0.5), 8)
	var cur := Color(0.36, 0.60, 0.58)
	for side: float in [1.0, -1.0]:
		var m := func(p: Vector2) -> Vector2:
			return p if side > 0.0 else Vector2(510.0 - p.x, p.y)
		var shape := PackedVector2Array()
		for p: Vector2 in [Vector2(106, 114), Vector2(176, 114), Vector2(168, 180), Vector2(148, 262), Vector2(140, 300),
				Vector2(150, 346), Vector2(162, 404), Vector2(100, 404), Vector2(108, 350), Vector2(114, 300), Vector2(110, 200)]:
			shape.append(m.call(p))
		b.poly(_shift(shape, Vector2(7, 6)), Color(SHADE, 0.16))
		b.inked(shape, cur, 1.5, PROP_INK)
		# folds: shadows down the inside, a lit edge outside
		for f: Array in [[Vector2(126, 116), Vector2(136, 116), Vector2(130, 300), Vector2(128, 402), Vector2(118, 402), Vector2(122, 300)],
				[Vector2(152, 116), Vector2(166, 116), Vector2(140, 296), Vector2(152, 402), Vector2(142, 402), Vector2(134, 298)]]:
			var fold := PackedVector2Array()
			for p: Vector2 in f:
				fold.append(m.call(p))
			b.clip(fold, shape, cur.darkened(0.25))
		var lit := PackedVector2Array()
		for p: Vector2 in [Vector2(108, 116), Vector2(116, 116), Vector2(118, 200), Vector2(120, 300), Vector2(110, 402), Vector2(103, 402),
				Vector2(111, 300), Vector2(110, 200)]:
			lit.append(m.call(p))
		b.clip(lit, shape, cur.lightened(0.18) if side > 0.0 else cur.lightened(0.06))
		var tie := PackedVector2Array([m.call(Vector2(108, 294)), m.call(Vector2(146, 292)), m.call(Vector2(146, 302)), m.call(Vector2(110, 306))])
		b.inked(tie, Color(0.90, 0.68, 0.30), 1.2, PROP_INK)
		for k in range(5):
			b.oval(m.call(Vector2(110.0 + float(k) * 15.0, 114)), Vector2(3, 3), BRASS.darkened(0.15), 8)


# a portrait of a black dog (who else) in a walnut frame, hung from the
# picture rail, and a small print of the sea beside it
static func _build_pictures(b: Tris) -> void:
	var cord := Color(0.32, 0.22, 0.18)
	b.line(Vector2(620, 103), Vector2(566, 160), cord, 1.4)
	b.line(Vector2(620, 103), Vector2(674, 160), cord, 1.4)
	b.oval(Vector2(620, 103), Vector2(3, 3), BRASS, 8)
	b.rect(Rect2(556, 166, 144, 114), Color(SHADE, 0.18))
	b.rect(Rect2(548, 158, 144, 114), Color(0.32, 0.20, 0.14))
	b.rect(Rect2(548, 158, 144, 4), Color(0.50, 0.33, 0.22))
	b.rect(Rect2(548, 158, 4, 114), Color(0.46, 0.30, 0.20))
	b.rect(Rect2(556, 166, 128, 98), Color(0.84, 0.66, 0.34))
	b.rect(Rect2(559, 169, 122, 92), Color(0.96, 0.92, 0.82))
	var art := Rect2(574, 182, 92, 66)
	b.vgrad(art, Color(0.96, 0.70, 0.40), Color(0.88, 0.52, 0.34))
	b.oval(Vector2(654, 194), Vector2(8, 8), Color(1.0, 0.88, 0.56), 16)
	# her portrait, face on as on the box art: shoulders and a pink collar, a
	# round charcoal head, ears perked up and folding over at the tips, big
	# googly eyes, grey brows and a light grey muzzle with a black nose
	var ink := Color(0.10, 0.08, 0.10)
	var coat := Color(0.22, 0.22, 0.26)
	var ear := Color(0.10, 0.10, 0.12)
	var grey := Color(0.72, 0.70, 0.68)
	b.poly(_pts([Vector2(596, 248), Vector2(600, 236), Vector2(612, 230), Vector2(628, 230), Vector2(640, 236),
		Vector2(644, 248)]), ink)
	b.poly(_pts([Vector2(598.5, 248), Vector2(602, 237), Vector2(613, 232), Vector2(627, 232), Vector2(638, 237),
		Vector2(641.5, 248)]), Color(0.16, 0.16, 0.19))
	b.quad(Vector2(605, 232), Vector2(635, 232), Vector2(637, 237.5), Vector2(603, 237.5), Color(0.94, 0.36, 0.58))
	b.oval(Vector2(631, 236), Vector2(2.6, 2.6), Color(0.90, 0.90, 0.94), 8)
	for sd: float in [-1.0, 1.0]:
		# an ear: up and out from the crown, the tip folded over and down
		var e := _pts([Vector2(620 + sd * 9, 199), Vector2(620 + sd * 17, 189), Vector2(620 + sd * 27, 188),
			Vector2(620 + sd * 31, 196), Vector2(620 + sd * 28, 207), Vector2(620 + sd * 22, 204), Vector2(620 + sd * 16, 205)])
		b.inked(e, ear, 1.4, ink)
		b.poly(_pts([Vector2(620 + sd * 19, 191), Vector2(620 + sd * 25, 190.5), Vector2(620 + sd * 22, 194)]),
			Color(0.30, 0.30, 0.34))
	b.oval(Vector2(620, 213), Vector2(19.5, 17.5), ink, 24)
	b.oval(Vector2(620, 213), Vector2(18, 16), coat, 24)
	b.oval(Vector2(615, 204), Vector2(9, 4), Color(0.32, 0.32, 0.37), 14)
	for sd2: float in [-1.0, 1.0]:
		b.oval(Vector2(620 + sd2 * 9, 203.5), Vector2(3.6, 1.6), grey, 10)
		b.oval(Vector2(620 + sd2 * 7.5, 210), Vector2(5.6, 5.6), ink, 14)
		b.oval(Vector2(620 + sd2 * 7.5, 210), Vector2(4.6, 4.6), Color(0.98, 0.96, 0.90), 14)
		b.oval(Vector2(620 + sd2 * 7.5 + 0.8, 210.6), Vector2(2.4, 2.4), ink, 10)
		b.oval(Vector2(620 + sd2 * 7.5 + 1.4, 209.6), Vector2(0.9, 0.9), Color(1, 1, 1), 6)
	b.oval(Vector2(620, 222), Vector2(10, 7.5), Color(0.52, 0.50, 0.50), 18)
	b.oval(Vector2(620, 222.5), Vector2(9, 6.5), grey, 18)
	b.oval(Vector2(620, 219.5), Vector2(4.2, 3.0), ink, 12)
	b.oval(Vector2(619, 218.6), Vector2(1.4, 0.8), Color(0.62, 0.62, 0.66), 6)
	b.line(Vector2(620, 222), Vector2(620, 225), ink, 1.0)
	b.line(Vector2(615, 225), Vector2(620, 226.4), ink, 1.0)
	b.line(Vector2(620, 226.4), Vector2(625.5, 224.4), ink, 1.0)
	# the sea
	b.line(Vector2(735, 103), Vector2(722, 190), cord, 1.2)
	b.line(Vector2(735, 103), Vector2(748, 190), cord, 1.2)
	b.oval(Vector2(735, 103), Vector2(2.5, 2.5), BRASS, 8)
	b.rect(Rect2(718, 194, 46, 60), Color(SHADE, 0.16))
	b.rect(Rect2(712, 188, 46, 60), Color(0.14, 0.12, 0.14))
	b.rect(Rect2(715, 191, 40, 54), Color(0.97, 0.95, 0.90))
	b.vgrad(Rect2(720, 196, 30, 22), Color(0.62, 0.82, 0.94), Color(0.90, 0.92, 0.88))
	b.oval(Vector2(742, 206), Vector2(4, 4), Color(0.98, 0.76, 0.30), 12)
	b.rect(Rect2(720, 218, 30, 12), Color(0.22, 0.48, 0.70))
	b.rect(Rect2(720, 230, 30, 10), Color(0.94, 0.84, 0.62))


# the front door's casing and the dark of its jamb (the leaf is _door)
static func _build_door_frame(b: Tris) -> void:
	var d := DOOR
	b.rect(Rect2(d.position.x - 10, d.position.y - 22, d.size.x + 36, d.size.y + 22), Color(SHADE, 0.14))
	b.rect(Rect2(d.position.x - 18, d.position.y - 18, d.size.x + 36, d.size.y + 18), TRIM_SH)
	b.rect(Rect2(d.position.x - 18, d.position.y - 18, d.size.x + 33, d.size.y + 18), TRIM)
	b.rect(Rect2(d.position.x - 12, d.position.y - 12, 2, d.size.y + 12), TRIM_SH)
	b.rect(Rect2(d.end.x + 10, d.position.y - 12, 2, d.size.y + 12), TRIM_SH)
	b.rect(Rect2(d.position.x - 12, d.position.y - 12, d.size.x + 24, 2), TRIM_SH)
	# the header, a little cornice over it
	b.quad(Vector2(d.position.x - 26, d.position.y - 18), Vector2(d.end.x + 26, d.position.y - 18),
		Vector2(d.end.x + 32, d.position.y - 36), Vector2(d.position.x - 32, d.position.y - 36), TRIM)
	b.rect(Rect2(d.position.x - 32, d.position.y - 38, d.size.x + 64, 4), Color(1.0, 0.98, 0.94))
	b.rect(Rect2(d.position.x - 26, d.position.y - 18, d.size.x + 52, 3), TRIM_SH)
	# plinth blocks where the casing meets the skirting
	b.rect(Rect2(d.position.x - 20, FLOOR - 34, 24, 34), Color(0.92, 0.88, 0.80))
	b.rect(Rect2(d.end.x - 4, FLOOR - 34, 24, 34), Color(0.88, 0.83, 0.76))
	b.rect(DOOR.grow(6.0), Color(0.40, 0.32, 0.30))


# the hook rail: the leash's hook, and the coat's
static func _build_hooks(b: Tris) -> void:
	b.rect(Rect2(930, 312, 104, 12), Color(SHADE, 0.18))
	b.inked(_rr(Rect2(926, 306, 104, 12), 3.0, 2), WOOD, 1.5, PROP_INK)
	b.rect(Rect2(928, 307, 100, 3), WOOD.lightened(0.2))
	for hx: float in [948.0, HOOK.x]:
		b.line(Vector2(hx, 316), Vector2(hx, 326), BRASS.darkened(0.25), 3.0)
		b.oval(Vector2(hx, 327), Vector2(3.6, 3.6), BRASS, 12)
		b.oval(Vector2(hx - 1.2, 325.8), Vector2(1.2, 1.2), BRASS.lightened(0.5), 6)
	for sx: float in [934.0, 1022.0]:
		b.oval(Vector2(sx, 312), Vector2(1.8, 1.8), BRASS.darkened(0.2), 6)


# the front door on its left hinge, swinging toward us (narrower as it turns,
# its free edge taller as it comes nearer), the street blazing beyond it
static func _door(c: CanvasItem, door_open: float) -> void:
	var b := Tris.new()
	var ang := door_open * 1.9
	if door_open > 0.02:
		_doorway_view(b)
		b.poly(_pts([DOOR.position + Vector2(0, DOOR.size.y), DOOR.end, DOOR.end + Vector2(160, 120),
			DOOR.position + Vector2(-60, DOOR.size.y + 120)]), Color(1.0, 0.95, 0.74, 0.35 * door_open))
	var hinge_x := DOOR.position.x
	var fx := hinge_x + DOOR.size.x * cos(ang)
	var grow := 1.0 + 0.22 * sin(ang)
	var top := DOOR.position.y - DOOR.size.y * (grow - 1.0) * 0.5
	var bot := DOOR.end.y + DOOR.size.y * (grow - 1.0) * 0.5
	var sx := 1.0 if fx >= hinge_x else -1.0
	var panel := _pts([Vector2(hinge_x, DOOR.position.y), Vector2(fx, top), Vector2(fx, bot), Vector2(hinge_x, DOOR.end.y)])
	b.poly(_pts([panel[0] + Vector2(-2, -2), panel[1] + Vector2(2 * sx, -2), panel[2] + Vector2(2 * sx, 2), panel[3] + Vector2(-2, 2)]),
		LINE)
	var shade := 1.0 - 0.35 * sin(ang)
	var green := _dim(Color(0.30, 0.52, 0.41), shade)
	b.poly(panel, green)
	var at := func(u: float, v: float) -> Vector2:
		return Vector2(lerpf(hinge_x, fx, u), lerpf(lerpf(DOOR.position.y, top, u), lerpf(DOOR.end.y, bot, u), v))
	var q := func(u0: float, v0: float, u1: float, v1: float, col: Color) -> void:
		b.quad(at.call(u0, v0), at.call(u1, v0), at.call(u1, v1), at.call(u0, v1), col)
	if absf(fx - hinge_x) > 20.0:
		# the lit edge on the hinge side
		q.call(0.015, 0.005, 0.045, 0.995, green.lightened(0.14))
		# two raised panels: a recess, bevels lit from the upper left, the field
		for pn: Vector2 in [Vector2(0.06, 0.40), Vector2(0.50, 0.92)]:
			var u0 := 0.13
			var u1 := 0.87
			var eu := 0.06
			var ev := 0.022
			q.call(u0, pn.x, u1, pn.y, _dim(green, 0.72))
			b.quad(at.call(u0, pn.x), at.call(u1, pn.x), at.call(u1 - eu, pn.x + ev), at.call(u0 + eu, pn.x + ev), green.lightened(0.16))
			b.quad(at.call(u0, pn.x), at.call(u0 + eu, pn.x + ev), at.call(u0 + eu, pn.y - ev), at.call(u0, pn.y), green.lightened(0.08))
			b.quad(at.call(u1, pn.x), at.call(u1, pn.y), at.call(u1 - eu, pn.y - ev), at.call(u1 - eu, pn.x + ev), _dim(green, 0.62))
			b.quad(at.call(u0, pn.y), at.call(u0 + eu, pn.y - ev), at.call(u1 - eu, pn.y - ev), at.call(u1, pn.y), _dim(green, 0.55))
			q.call(u0 + eu, pn.x + ev, u1 - eu, pn.y - ev, _dim(green, 0.97))
		# the brass: a backplate, the lever, the keyhole, the spyhole
		var brass := _dim(BRASS, shade)
		q.call(0.865, 0.475, 0.915, 0.60, brass.darkened(0.2))
		q.call(0.75, 0.505, 0.905, 0.523, brass)
		q.call(0.75, 0.505, 0.905, 0.510, brass.lightened(0.35))
		q.call(0.882, 0.56, 0.898, 0.578, Color(0.10, 0.08, 0.08))
		var spy: Vector2 = at.call(0.5, 0.25)
		b.oval(spy, Vector2(3.0 * absf(fx - hinge_x) / DOOR.size.x + 0.5, 3.0), brass, 10)
	b.draw_once(c)


# what the open door shows: the street outside, bleached by the sun
static func _doorway_view(b: Tris) -> void:
	var d := DOOR
	b.vgrad(Rect2(d.position, Vector2(d.size.x, 90)), Color(0.88, 0.95, 1.0), Color(1.0, 0.98, 0.90))
	b.rect(Rect2(d.position.x, d.position.y + 56, d.size.x, d.size.y - 56), Color(1.0, 0.90, 0.72))
	b.rect(Rect2(d.position.x, d.position.y + 50, d.size.x, 7), Color(0.96, 0.82, 0.62))
	for wy: float in [d.position.y + 84, d.position.y + 186]:
		for wx: float in [d.position.x + 22, d.position.x + 96]:
			b.rect(Rect2(wx, wy, 32, 62), Color(0.70, 0.86, 0.72))
			b.rect(Rect2(wx - 8, wy + 62, 48, 4), Color(1.0, 0.97, 0.92))
			b.rect(Rect2(wx - 6, wy + 44, 44, 1.5), Color(0.66, 0.60, 0.58))
	b.rect(Rect2(d.position.x + 112, d.position.y + 120, 10, d.size.y - 180), Color(0.86, 0.80, 0.66))
	b.rect(Rect2(d.position.x, d.end.y - 54, d.size.x, 54), Color(1.0, 0.96, 0.86))
	b.rect(Rect2(d.position.x, d.end.y - 56, d.size.x, 3), Color(0.92, 0.86, 0.78))


# the dressing: the rug under the action, a bookshelf, the lamp, a side table
# with the morning's coffee, a plant on the sill, the yellow raincoat on the
# hook beside the leash, her water bowl and her bed by the door (empty: she
# has plans)
static func _dressing(c: CanvasItem) -> void:
	if _bg_dressing == null:
		_bg_dressing = Tris.new()
		_build_dressing(_bg_dressing)
	_bg_dressing.draw(c)


static func _rug_pt(u: float, v: float) -> Vector2:
	return Vector2(lerpf(300.0, 830.0, u), 604.0).lerp(Vector2(lerpf(258.0, 874.0, u), 656.0), v)


static func _rug_quad(b: Tris, u0: float, v0: float, u1: float, v1: float, col: Color) -> void:
	b.quad(_rug_pt(u0, v0), _rug_pt(u1, v0), _rug_pt(u1, v1), _rug_pt(u0, v1), col)


static func _rug_diamond(b: Tris, u: float, v: float, du: float, dv: float, col: Color) -> void:
	b.quad(_rug_pt(u, v - dv), _rug_pt(u + du, v), _rug_pt(u, v + dv), _rug_pt(u - du, v), col)


static func _build_dressing(b: Tris) -> void:
	# the rug: a kilim in indigo, cream and mustard, fringed at the ends
	var cream := Color(0.94, 0.86, 0.69)
	var indigo := Color(0.22, 0.30, 0.50)
	var mustard := Color(0.90, 0.64, 0.26)
	var terra := Color(0.80, 0.38, 0.28)
	for i in range(10):
		var v := 0.05 + float(i) * 0.1
		b.line(_rug_pt(0, v), _rug_pt(0, v) + Vector2(-10, 1), cream.darkened(0.08), 1.6)
		b.line(_rug_pt(1, v), _rug_pt(1, v) + Vector2(10, 1), cream.darkened(0.08), 1.6)
	b.quad(_rug_pt(0, 1), _rug_pt(1, 1), _rug_pt(1, 1) + Vector2(0, 3), _rug_pt(0, 1) + Vector2(0, 3), Color(0.20, 0.12, 0.22))
	_rug_quad(b, 0, 0, 1, 1, cream)
	_rug_quad(b, 0.03, 0.13, 0.97, 0.87, terra)
	_rug_quad(b, 0.04, 0.18, 0.96, 0.82, indigo)
	var u := 0.02
	while u < 0.99:
		_rug_diamond(b, u, 0.065, 0.006, 0.045, terra)
		_rug_diamond(b, u, 0.935, 0.006, 0.045, terra)
		u += 0.024
	for m in range(5):
		var uc := 0.14 + float(m) * 0.18
		_rug_diamond(b, uc, 0.5, 0.065, 0.29, mustard)
		_rug_diamond(b, uc, 0.5, 0.042, 0.18, indigo)
		_rug_diamond(b, uc, 0.5, 0.022, 0.09, terra)
		if m < 4:
			_rug_diamond(b, uc + 0.09, 0.5, 0.012, 0.07, cream)
			_rug_diamond(b, uc + 0.09, 0.28, 0.008, 0.04, mustard)
			_rug_diamond(b, uc + 0.09, 0.72, 0.008, 0.04, mustard)
	_build_bookshelf(b)
	# the floor lamp: walnut tripod, brass stem, a drum shade
	b.oval(Vector2(80, FLOOR + 1), Vector2(40, 4), Color(SHADE, 0.30), 18)
	b.line(Vector2(78, 520), Vector2(84, FLOOR + 1), WOOD.darkened(0.35), 3.0)
	for lx: float in [50.0, 106.0]:
		b.line(Vector2(78, 520), Vector2(lx, FLOOR), PROP_INK, 5.5)
		b.line(Vector2(78, 520), Vector2(lx, FLOOR), WOOD, 3.5)
	b.line(Vector2(78, 524), Vector2(78, 312), PROP_INK, 5.5)
	b.line(Vector2(78, 524), Vector2(78, 312), BRASS, 3.5)
	b.line(Vector2(77, 520), Vector2(77, 316), BRASS.lightened(0.4), 1.0)
	var shade := _pts([Vector2(50, 260), Vector2(106, 260), Vector2(116, 318), Vector2(40, 318)])
	b.poly(_shift(shade, Vector2(8, 7)), Color(SHADE, 0.14))
	b.inked(shade, Color(0.97, 0.90, 0.73), 2.0, PROP_INK)
	b.clip(_pts([Vector2(86, 250), Vector2(130, 250), Vector2(130, 330), Vector2(94, 330)]), shade, Color(0.87, 0.76, 0.62))
	b.clip(_pts([Vector2(52, 250), Vector2(60, 250), Vector2(50, 330), Vector2(42, 330)]), shade, Color(1.0, 0.98, 0.90))
	b.quad(Vector2(41, 313), Vector2(115, 313), Vector2(116, 318), Vector2(40, 318), Color(0.80, 0.64, 0.46))
	# the side table: coffee, two books, magazines underneath
	b.oval(Vector2(210, FLOOR + 1), Vector2(46, 4), Color(SHADE, 0.30), 18)
	for leg: Array in [[Vector2(180, 502), Vector2(175, FLOOR)], [Vector2(240, 502), Vector2(245, FLOOR)]]:
		b.line(leg[0], leg[1], Color(0.16, 0.12, 0.12), 3.0)
	b.line(Vector2(210, 502), Vector2(211, FLOOR - 1), Color(0.26, 0.20, 0.20), 2.5)
	b.inked(_rr(Rect2(178, 564, 64, 5), 2.0, 2), WOOD, 1.2, PROP_INK)
	b.rect(Rect2(184, 556, 48, 8), Color(0.88, 0.40, 0.32))
	b.rect(Rect2(186, 550, 44, 6), Color(0.92, 0.90, 0.82))
	b.inked(_rr(Rect2(166, 492, 88, 11), 4.0, 3), WOOD, 1.5, PROP_INK)
	b.rect(Rect2(170, 492, 80, 3), WOOD.lightened(0.22))
	b.rect(Rect2(170, 500, 80, 3), WOOD.darkened(0.2))
	b.line(Vector2(204, 474), Vector2(211, 476), PROP_INK, 5.0)
	b.line(Vector2(211, 476), Vector2(211, 486), PROP_INK, 5.0)
	b.line(Vector2(211, 486), Vector2(204, 489), PROP_INK, 5.0)
	var mug := _pts([Vector2(184, 468), Vector2(205, 468), Vector2(204, 492), Vector2(185, 492)])
	b.inked(mug, Color(0.98, 0.96, 0.92), 1.5, PROP_INK)
	b.line(Vector2(204, 474), Vector2(211, 476), Color(0.98, 0.96, 0.92), 2.5)
	b.line(Vector2(211, 476), Vector2(211, 486), Color(0.98, 0.96, 0.92), 2.5)
	b.line(Vector2(211, 486), Vector2(204, 489), Color(0.98, 0.96, 0.92), 2.5)
	b.clip(_pts([Vector2(198, 460), Vector2(210, 460), Vector2(210, 500), Vector2(198, 500)]), mug, Color(0.84, 0.80, 0.84))
	b.rect(Rect2(185, 476, 19, 4), Color(0.84, 0.36, 0.28))
	b.inked(_pts([Vector2(216, 483), Vector2(248, 483), Vector2(248, 492), Vector2(216, 492)]), Color(0.26, 0.52, 0.54), 1.2, PROP_INK)
	b.inked(_pts([Vector2(219, 476), Vector2(244, 476), Vector2(244, 483), Vector2(219, 483)]), mustard, 1.2, PROP_INK)
	b.rect(Rect2(219, 479, 25, 1.2), mustard.darkened(0.3))
	# a snake plant on the sill, against the bright window
	var pot := _pts([Vector2(322, 348), Vector2(352, 348), Vector2(348, 374), Vector2(326, 374)])
	for k in range(6):
		var bx := 330.0 + float(k) * 3.4
		var lean := (float(k) - 2.5) * 9.0
		var hgt := 64.0 + 20.0 * _h(k + 40)
		var leaf := _pts([Vector2(bx - 4, 348), Vector2(bx - 6 + lean * 0.4, 348 - hgt * 0.55), Vector2(bx + lean, 348 - hgt),
			Vector2(bx + 6 + lean * 0.4, 348 - hgt * 0.55), Vector2(bx + 4, 348)])
		var lc := Color(0.20, 0.44, 0.28) if k % 2 == 0 else Color(0.26, 0.52, 0.32)
		b.inked(leaf, lc, 1.2, PROP_INK)
		b.clip(_pts([Vector2(bx - 8, 348), Vector2(bx - 8 + lean, 348 - hgt), Vector2(bx + lean, 348 - hgt), Vector2(bx, 348)]), leaf,
			lc.lightened(0.18))
		b.line(Vector2(bx, 346), Vector2(bx + lean * 0.8, 348 - hgt * 0.8), Color(0.78, 0.80, 0.42, 0.8), 1.0)
	b.inked(pot, Color(0.80, 0.44, 0.28), 1.5, PROP_INK)
	b.inked(_pts([Vector2(319, 343), Vector2(355, 343), Vector2(355, 351), Vector2(319, 351)]), Color(0.86, 0.52, 0.34), 1.5, PROP_INK)
	b.clip(_pts([Vector2(340, 340), Vector2(360, 340), Vector2(360, 380), Vector2(340, 380)]), pot, Color(0.64, 0.32, 0.24))
	_build_coat(b)
	# her water bowl, by the door
	b.oval(Vector2(1263, FLOOR + 1), Vector2(26, 3.5), Color(SHADE, 0.32), 16)
	var bowl := _pts([Vector2(1242, 593), Vector2(1284, 593), Vector2(1277, FLOOR), Vector2(1249, FLOOR)])
	b.inked(bowl, Color(0.86, 0.32, 0.30), 1.5, PROP_INK)
	b.clip(_pts([Vector2(1268, 590), Vector2(1290, 590), Vector2(1290, 612), Vector2(1266, 612)]), bowl, Color(0.66, 0.22, 0.26))
	b.rect(Rect2(1243, 593, 40, 3), Color(0.96, 0.56, 0.50))
	b.oval(Vector2(1256, 601), Vector2(3, 2), Color(0.98, 0.92, 0.82), 8)
	b.oval(Vector2(1264, 601), Vector2(3, 2), Color(0.98, 0.92, 0.82), 8)
	b.rect(Rect2(1256, 600, 8, 2), Color(0.98, 0.92, 0.82))
	# her bed: a blue basket with a raised back rim and a cream cushion, and a ball
	b.oval(Vector2(1366, FLOOR + 1), Vector2(74, 5), Color(SHADE, 0.32), 20)
	var bed_blue := Color(0.36, 0.50, 0.70)
	b.inked(_rr(Rect2(1298, 550, 136, 44), 18.0), bed_blue.darkened(0.12), 2.0, PROP_INK)
	b.inked(_rr(Rect2(1312, 566, 108, 22), 10.0), Color(0.93, 0.87, 0.77), 1.5, PROP_INK)
	var front := _rr(Rect2(1300, 580, 132, 30), 13.0)
	b.inked(front, bed_blue, 2.0, PROP_INK)
	b.clip(_pts([Vector2(1290, 598), Vector2(1440, 598), Vector2(1440, 620), Vector2(1290, 620)]), front, bed_blue.darkened(0.22))
	b.rect(Rect2(1312, 583, 108, 3), bed_blue.lightened(0.25))
	b.inked(_rr(Rect2(1280, 597, 13, 13), 6.5, 3), Color(0.80, 0.88, 0.30), 1.2, PROP_INK)
	b.line(Vector2(1282, 601), Vector2(1291, 606), Color(1, 1, 1, 0.9), 1.2)


# her bookshelf, against the wall left of the lamp: books in a row, a few
# leaning, a plant and a photo
static func _build_bookshelf(b: Tris) -> void:
	var r := Rect2(-250, 236, 210, 374)
	b.oval(Vector2(-145, FLOOR + 1), Vector2(120, 5), Color(SHADE, 0.30), 20)
	b.rect(Rect2(r.position + Vector2(10, 8), r.size), Color(SHADE, 0.14))
	b.inked(_pts([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), WOOD, 2.0, PROP_INK)
	b.rect(Rect2(r.position.x + 10, r.position.y + 10, r.size.x - 20, r.size.y - 20), Color(0.30, 0.19, 0.14))
	b.rect(Rect2(r.position.x, r.position.y, 4, r.size.y), WOOD.lightened(0.18))
	var palette := [Color(0.80, 0.34, 0.28), Color(0.26, 0.48, 0.56), Color(0.92, 0.80, 0.56), Color(0.36, 0.44, 0.30),
		Color(0.90, 0.62, 0.26), Color(0.30, 0.30, 0.44), Color(0.94, 0.92, 0.86), Color(0.62, 0.30, 0.40)]
	var shelves := [330.0, 424.0, 518.0, 600.0]
	for s in range(shelves.size()):
		var sy: float = shelves[s]
		var x := r.position.x + 12.0
		var n := 0
		while x < r.end.x - 26.0:
			var hh := 52.0 + 26.0 * _h(s * 50 + n)
			var bw := 9.0 + 9.0 * _h(s * 50 + n + 7)
			var col: Color = palette[(s * 3 + n * 5) % palette.size()]
			if s == 1 and n == 4:
				b.inked(_rr(Rect2(x + 2, sy - 32, 26, 32), 4.0, 2), Color(0.80, 0.44, 0.28), 1.0, PROP_INK)
				b.oval(Vector2(x + 15, sy - 40), Vector2(14, 10), Color(0.30, 0.54, 0.30), 14)
				b.oval(Vector2(x + 10, sy - 44), Vector2(7, 5), Color(0.44, 0.66, 0.38), 10)
				x += 36.0
			elif s == 2 and n == 2:
				b.inked(_pts([Vector2(x + 2, sy - 44), Vector2(x + 34, sy - 44), Vector2(x + 34, sy), Vector2(x + 2, sy)]),
					Color(0.20, 0.16, 0.16), 1.0, PROP_INK)
				b.rect(Rect2(x + 6, sy - 40, 24, 36), Color(0.62, 0.80, 0.90))
				b.oval(Vector2(x + 18, sy - 14), Vector2(7, 6), Color(0.12, 0.11, 0.13), 10)
				x += 40.0
			elif n % 6 == 5:
				# a leaner
				b.inked(_pts([Vector2(x, sy), Vector2(x + bw, sy), Vector2(x + bw + hh * 0.35, sy - hh * 0.92),
					Vector2(x + hh * 0.35, sy - hh * 0.92)]), col, 1.0, PROP_INK)
				x += bw + hh * 0.38
			else:
				b.inked(_pts([Vector2(x, sy - hh), Vector2(x + bw, sy - hh), Vector2(x + bw, sy), Vector2(x, sy)]), col, 1.0, PROP_INK)
				b.rect(Rect2(x, sy - hh * 0.82, bw, 2.0), col.lightened(0.3))
				b.rect(Rect2(x + bw - 2.5, sy - hh, 2.5, hh), col.darkened(0.18))
				x += bw + 1.0
			n += 1
		if s < shelves.size() - 1:
			b.rect(Rect2(r.position.x + 4, sy, r.size.x - 8, 8), WOOD)
			b.rect(Rect2(r.position.x + 4, sy, r.size.x - 8, 2), WOOD.lightened(0.25))
	b.oval(Vector2(-160, 228), Vector2(20, 12), Color(0.30, 0.54, 0.30), 14)
	b.inked(_pts([Vector2(-174, 222), Vector2(-146, 222), Vector2(-150, 236), Vector2(-170, 236)]), Color(0.92, 0.88, 0.80), 1.0, PROP_INK)


# the yellow raincoat on its hook: the hood hanging behind, a sleeve, toggles,
# a pocket flap; lit from the left, its right side in shadow
static func _build_coat(b: Tris) -> void:
	var ch := HOOK + Vector2(-62, 0)
	var coat := Color(0.97, 0.78, 0.24)
	var shape := PackedVector2Array()
	for e: Vector2 in [Vector2(-9, 2), Vector2(9, 2), Vector2(22, 16), Vector2(27, 66), Vector2(32, 140), Vector2(18, 150),
			Vector2(0, 152), Vector2(-18, 150), Vector2(-32, 140), Vector2(-27, 66), Vector2(-22, 16)]:
		shape.append(ch + e)
	b.poly(_shift(shape, Vector2(8, 6)), Color(SHADE, 0.18))
	var hood := PackedVector2Array()
	for e: Vector2 in [Vector2(-14, 4), Vector2(-16, 22), Vector2(-6, 34), Vector2(6, 34), Vector2(16, 22), Vector2(14, 4)]:
		hood.append(ch + e)
	b.inked(hood, coat.darkened(0.3), 1.5, PROP_INK)
	b.inked(shape, coat, 2.0, PROP_INK)
	b.clip(_pts([ch + Vector2(5, -4), ch + Vector2(40, -4), ch + Vector2(40, 160), ch + Vector2(9, 160)]), shape, Color(0.86, 0.58, 0.20))
	b.clip(_pts([ch + Vector2(-20, 22), ch + Vector2(-15, 22), ch + Vector2(-22, 132), ch + Vector2(-27, 132)]), shape, Color(1.0, 0.92, 0.56))
	var sleeve := PackedVector2Array()
	for e: Vector2 in [Vector2(-20, 20), Vector2(-9, 26), Vector2(-12, 114), Vector2(-21, 120), Vector2(-27, 114)]:
		sleeve.append(ch + e)
	b.inked(sleeve, coat.darkened(0.06), 1.2, PROP_INK)
	b.rect(Rect2(ch + Vector2(-24, 108), Vector2(13, 5)), coat.darkened(0.2))
	b.line(ch + Vector2(4, 20), ch + Vector2(4, 150), PROP_INK, 1.5)
	for ty: float in [44.0, 76.0, 108.0]:
		b.rect(Rect2(ch + Vector2(1, ty), Vector2(7, 3)), Color(0.40, 0.26, 0.18))
	b.rect(Rect2(ch + Vector2(9, 98), Vector2(16, 5)), Color(0.80, 0.54, 0.18))
	b.oval(ch + Vector2(0, 3), Vector2(5, 3), coat.darkened(0.25), 10)


# the edges of the room falling into shade: one smooth gradient to each side
static func _light(c: CanvasItem) -> void:
	if _bg_light == null:
		var b := Tris.new()
		var dk := Color(0.16, 0.07, 0.14)
		var clear := Color(dk, 0.0)
		b.hgrad(Rect2(-1200, -1500, 1250, 3600), Color(dk, 0.50), clear)
		b.hgrad(Rect2(1380, -1500, 1220, 3600), clear, Color(dk, 0.50))
		b.vgrad(Rect2(-1200, -1500, 3800, 1640), Color(dk, 0.42), clear)
		b.vgrad(Rect2(-1200, 690, 3800, 340), clear, Color(dk, 0.28))
		b.vgrad(Rect2(-1200, 1030, 3800, 1100), Color(dk, 0.28), Color(dk, 0.5))
		_bg_light = b
	_bg_light.draw(c)


# the sofa, side on, facing right: the back on the left, the arm on the right.
# One heavy outline round the whole silhouette, flat cel shading, lit from
# the upper left
static func _sofa(c: CanvasItem) -> void:
	if _bg_sofa == null:
		_bg_sofa = Tris.new()
		_build_sofa(_bg_sofa)
	_bg_sofa.draw(c)


static func _build_sofa(b: Tris) -> void:
	var body := Color(0.78, 0.36, 0.28)
	var dark := Color(0.60, 0.25, 0.25)
	var lit := Color(0.92, 0.52, 0.40)
	var seam := Color(0.46, 0.17, 0.18)
	var x := SOFA_X
	b.oval(Vector2(x + 44, FLOOR + 2), Vector2(176, 9), Color(SHADE, 0.34), 28)
	for lx: float in [x - 100.0, x + 176.0]:
		b.inked(_pts([Vector2(lx, FLOOR - 30), Vector2(lx + 18, FLOOR - 30), Vector2(lx + 13, FLOOR), Vector2(lx + 5, FLOOR)]),
			Color(0.38, 0.25, 0.17), 2.0, LINE)
	var back := _rr(Rect2(x - 118, FLOOR - 236, 62, 210), 24.0)
	var base := _rr(Rect2(x - 118, FLOOR - 112, 316, 88), 20.0)
	var arm := _rr(Rect2(x + 150, FLOOR - 164, 58, 140), 26.0)
	var seat_l := _rr(Rect2(x - 64, FLOOR - 128, 112, 36), 14.0)
	var seat_r := _rr(Rect2(x + 46, FLOOR - 128, 110, 36), 14.0)
	for p: PackedVector2Array in [back, base, arm, seat_l, seat_r]:
		for o in Geometry2D.offset_polygon(p, 3.0, Geometry2D.JOIN_ROUND):
			b.poly(o, LINE)
	# the frame, then its shadow side and its lit edge
	b.poly(base, body)
	b.clip(base, _pts([Vector2(x - 130, FLOOR - 58), Vector2(x + 220, FLOOR - 64), Vector2(x + 220, FLOOR), Vector2(x - 130, FLOOR)]), dark)
	b.clip(base, _pts([Vector2(x - 130, FLOOR - 120), Vector2(x + 220, FLOOR - 120), Vector2(x + 220, FLOOR - 104), Vector2(x - 130, FLOOR - 100)]), lit)
	b.line(Vector2(x - 100, FLOOR - 60), Vector2(x + 180, FLOOR - 64), seam, 2.0)
	b.poly(back, body)
	b.clip(back, _pts([Vector2(x - 76, FLOOR - 250), Vector2(x - 40, FLOOR - 250), Vector2(x - 40, FLOOR), Vector2(x - 72, FLOOR)]), dark)
	b.clip(back, _pts([Vector2(x - 130, FLOOR - 250), Vector2(x - 66, FLOOR - 250), Vector2(x - 96, FLOOR - 222), Vector2(x - 108, FLOOR - 120),
		Vector2(x - 130, FLOOR - 120)]), lit)
	for ty: float in [FLOOR - 200.0, FLOOR - 158.0]:
		b.oval(Vector2(x - 90, ty), Vector2(2.6, 2.6), seam, 8)
		b.line(Vector2(x - 90, ty), Vector2(x - 98, ty - 9), Color(seam, 0.6), 1.2)
		b.line(Vector2(x - 90, ty), Vector2(x - 98, ty + 9), Color(seam, 0.6), 1.2)
	b.poly(arm, body)
	b.clip(arm, _pts([Vector2(x + 186, FLOOR - 180), Vector2(x + 220, FLOOR - 180), Vector2(x + 220, FLOOR), Vector2(x + 182, FLOOR)]), dark)
	b.clip(arm, _pts([Vector2(x + 140, FLOOR - 180), Vector2(x + 196, FLOOR - 180), Vector2(x + 176, FLOOR - 150), Vector2(x + 160, FLOOR - 146),
		Vector2(x + 140, FLOOR - 120)]), lit)
	# the seat cushions: lit tops, shadowed fronts, a piped seam
	for sc: PackedVector2Array in [seat_l, seat_r]:
		b.poly(sc, body.lightened(0.06))
		b.clip(sc, _pts([Vector2(x - 80, FLOOR - 106), Vector2(x + 170, FLOOR - 106), Vector2(x + 170, FLOOR - 80), Vector2(x - 80, FLOOR - 80)]),
			body.darkened(0.08))
		b.clip(sc, _pts([Vector2(x - 80, FLOOR - 140), Vector2(x + 170, FLOOR - 140), Vector2(x + 170, FLOOR - 122), Vector2(x - 80, FLOOR - 120)]), lit)
	b.line(Vector2(x + 47, FLOOR - 124), Vector2(x + 47, FLOOR - 96), LINE, 2.0)
	# a knitted throw over the arm
	var throw := _pts([Vector2(x + 146, FLOOR - 158), Vector2(x + 168, FLOOR - 170), Vector2(x + 196, FLOOR - 168), Vector2(x + 214, FLOOR - 150),
		Vector2(x + 216, FLOOR - 82), Vector2(x + 208, FLOOR - 76), Vector2(x + 200, FLOOR - 84), Vector2(x + 192, FLOOR - 76),
		Vector2(x + 186, FLOOR - 140), Vector2(x + 160, FLOOR - 150)])
	b.inked(throw, Color(0.30, 0.56, 0.56), 2.0, LINE)
	b.clip(throw, _pts([Vector2(x + 198, FLOOR - 180), Vector2(x + 230, FLOOR - 180), Vector2(x + 230, FLOOR - 60), Vector2(x + 202, FLOOR - 60)]),
		Color(0.20, 0.40, 0.44))
	for ty: float in [FLOOR - 130.0, FLOOR - 112.0, FLOOR - 94.0]:
		b.clip(_pts([Vector2(x + 180, ty), Vector2(x + 222, ty), Vector2(x + 222, ty + 4), Vector2(x + 180, ty + 4)]), throw,
			Color(0.95, 0.90, 0.78))
	# a throw pillow wedged in the corner
	var pillow := _rr(Rect2(x - 70, FLOOR - 204, 54, 74), 16.0)
	b.inked(pillow, Color(0.97, 0.80, 0.36), 2.5, LINE)
	b.clip(pillow, _pts([Vector2(x - 36, FLOOR - 220), Vector2(x - 6, FLOOR - 220), Vector2(x - 6, FLOOR - 120), Vector2(x - 30, FLOOR - 120)]),
		Color(0.86, 0.60, 0.26))
	for k in range(3):
		b.clip(_pts([Vector2(x - 64 + k * 16, FLOOR - 210), Vector2(x - 60 + k * 16, FLOOR - 210), Vector2(x - 60 + k * 16, FLOOR - 124),
			Vector2(x - 64 + k * 16, FLOOR - 124)]), pillow, Color(0.86, 0.46, 0.30))
	b.clip(pillow, _pts([Vector2(x - 74, FLOOR - 210), Vector2(x - 40, FLOOR - 210), Vector2(x - 60, FLOOR - 196), Vector2(x - 74, FLOOR - 170)]),
		Color(1.0, 0.92, 0.62))


# the window's morning sun on the boards and the rug in front of the sofa:
# its four panes, crisp, slanting away from the window (drawn after the sofa,
# under everyone)
static func _window_light(c: CanvasItem) -> void:
	if _bg_sun == null:
		var b := Tris.new()
		for pu: Vector2 in [Vector2(0.0, 0.46), Vector2(0.54, 1.0)]:
			for pv: Vector2 in [Vector2(0.0, 0.47), Vector2(0.53, 1.0)]:
				var q := PackedVector2Array()
				for e: Vector2 in [Vector2(pu.x, pv.x), Vector2(pu.y, pv.x), Vector2(pu.y, pv.y), Vector2(pu.x, pv.y)]:
					q.append(Vector2(392.0 + 196.0 * e.x + 132.0 * (1.0 - e.y), FLOOR + 6.0 + 66.0 * (1.0 - e.y)))
				b.quad(q[0], q[1], q[2], q[3], SUN)
		_bg_sun = b
	_bg_sun.draw(c)


static func draw(c: CanvasItem, t_real: float) -> void:
	var t := t_real
	if t >= TITLE_AT:
		_title(c, t)
		return
	# the door bursts open as she reaches it, overshoots, and swings back a
	# little after your human has gone through
	var door_open: float = Anim.k(t, [[9.42, 0.0], [9.5, 1.08, "snap"], [9.6, 0.94, "io"], [9.67, 1.0, "io"],
		[9.82, 1.0], [9.94, 0.75, "io"]])
	_room(c, t, door_open)
	_dressing(c)

	# ---------------------------------------------------------------- Millie
	# where she stands, and which way she faces
	var mx: float = Anim.k(t, [[0.0, 920.0], [3.45, 920.0], [3.6, 912.0, "out"], [4.95, 625.0, "io"],
		[5.35, 625.0], [5.7, 690.0, "io"], [6.55, 690.0], [6.85, 572.0, "out"], [7.05, 572.0], [7.35, 690.0, "io"],
		[9.25, 690.0], [9.55, 1060.0, "in"], [9.72, 1480.0, "lin"]])
	# turns are quick (two frames) and hidden in a little dip, so she never
	# shows as a sliver
	var face_raw: float = Anim.k(t, [[0.0, 1.0], [3.5, 1.0], [3.58, -1.0, "io"], [8.62, -1.0], [8.7, 1.0, "io"]])
	var face := signf(face_raw) * maxf(absf(face_raw), 0.75) if face_raw != 0.0 else 0.75
	var turn_dip := maxf(maxf(1.0 - absf(face_raw), 0.0), 0.0)
	var trot := Anim.span(t, 3.6, 3.75) * (1.0 - Anim.span(t, 4.8, 4.95)) \
		+ 0.6 * Anim.span(t, 5.4, 5.5) * (1.0 - Anim.span(t, 5.6, 5.7)) \
		+ 0.6 * Anim.span(t, 7.1, 7.2) * (1.0 - Anim.span(t, 7.25, 7.35))
	var sitting := clampf(1.0 - Anim.span(t, 2.55, 2.72) + Anim.span(t, 5.75, 6.0) - Anim.span(t, 6.48, 6.58)
		+ Anim.span(t, 7.4, 7.62) - Anim.span(t, 8.45, 8.58), 0.0, 1.0)
	var windup := Anim.span(t, 2.7, 2.8) * (1.0 - Anim.span(t, 2.9, 2.94))
	var air := Anim.span(t, 2.9, 3.12) * (1.0 - Anim.span(t, 3.12, 3.34))
	var crouch := Anim.span(t, 8.72, 9.1) * (1.0 - Anim.span(t, 9.25, 9.3))
	var dash := Anim.span(t, 9.25, 9.32)
	var paws_up := Anim.span(t, 4.95, 5.12) * (1.0 - Anim.span(t, 5.3, 5.45))
	var nudge := Anim.span(t, 6.75, 6.92) * (1.0 - Anim.span(t, 7.0, 7.15))
	var pose := {
		"sit": sitting,
		"gait": trot, "phase": -mx * TAU / (56.0 * MS),
		"crouch": maxf(maxf(windup, crouch), 0.25 * turn_dip),
		# up and forward at the hook, nose first; tipping down to land
		"lean": 0.25 * crouch + 0.12 * dash - 0.8 * paws_up - 0.75 * nudge
			+ Anim.k(t, [[2.9, 0.0], [3.0, -0.5, "out"], [3.12, -0.45], [3.3, 0.3, "io"], [3.4, 0.0, "io"]]),
		"push": crouch * 0.5 + dash * 0.9 + 0.8 * air,
		"reach": dash + 0.8 * air + 0.3 * paws_up,
		"head_up": Anim.k(t, [[0.0, 0.0], [0.8, 0.8, "io"], [1.45, 0.8], [1.55, 0.5, "io"], [2.35, 0.5], [2.5, 0.75, "io"],
			[3.12, 0.7], [3.5, 0.15, "io"], [4.95, 0.1], [5.15, 0.05, "io"], [5.5, 0.1], [5.9, 0.35, "io"], [6.6, 0.35],
			[6.88, 0.95, "out"], [7.1, 0.3, "io"], [7.6, -0.35, "io"], [8.45, -0.35], [8.65, 0.05, "io"], [9.0, -0.12]]),
		"ear": 0.35 * trot * sin(t * 15.0 + 1.0) + Anim.k(t, [[7.55, 0.0], [7.85, -0.4, "io"], [8.45, -0.4], [8.65, 0.0, "io"],
			[9.0, -0.3, "io"], [9.25, -0.3], [9.33, 0.7, "snap"]]),
		"tail": 0.45 * sin(t * 17.0) * Anim.span(t, 5.95, 6.1) * (1.0 - Anim.span(t, 6.4, 6.5))
			+ 0.38 * sin(t * 14.0) * Anim.span(t, 0.5, 0.8) * (1.0 - Anim.span(t, 2.45, 2.6))
			+ Anim.k(t, [[7.55, 0.0], [7.85, -0.6, "io"], [8.5, -0.6], [8.7, 0.25, "io"]]),
		"mouth": Anim.k(t, [[3.1, 0.0], [3.13, 0.45, "hold"], [5.25, 0.45], [5.28, 0.0, "hold"], [9.25, 0.0], [9.28, 0.9, "hold"]]),
		"brow": Anim.k(t, [[5.75, 0.0], [5.95, 1.0, "io"], [7.4, 1.0], [7.6, -0.6, "io"], [8.7, -0.6], [8.95, -1.0, "io"]]),
		"look_back": Anim.k(t, [[1.5, 0.0], [1.62, 1.0, "out"], [2.3, 1.0], [2.42, 0.0, "io"]]),
		"blink": 1.0 if (t > 1.2 and t < 1.28) or (t > 7.62 and t < 7.95) or (t > 6.3 and t < 6.36) else 0.0,
	}
	var stretch: float = Anim.k(t, [[2.7, 1.0], [2.8, 0.7, "io"], [2.9, 0.7], [2.95, 1.25, "snap"], [3.12, 1.05, "out"],
		[3.3, 1.12, "in"], [3.36, 0.8, "snap"], [3.5, 1.0, "back"],
		[7.6, 1.0], [7.75, 1.07, "out"], [8.0, 0.95, "io"], [8.2, 1.0, "io"],
		[8.72, 1.0], [9.1, 0.68, "io"], [9.25, 0.68]])
	if t < 9.25:
		stretch += 0.022 * sin(t * 5.2) * sitting
	var sq := Anim.squash(stretch)
	if t >= 9.25:
		sq = Vector2(1.38, 0.76)   # stretched along the dash
	# the jump: up until her mouth meets the hook, and down again
	var ground_pos := Vector2(mx, FLOOR)
	var mpos := ground_pos
	if air > 0.0:
		var probe := IntroKit.millie_points(Vector2.ZERO, MS, face, sq, pose)
		var peak: Vector2 = HOOK + Vector2(0, 10) - probe["mouth"]
		var up := Anim.curve("out", Anim.span(t, 2.9, 3.12)) * (1.0 - Anim.curve("in", Anim.span(t, 3.12, 3.34)))
		mpos = ground_pos.lerp(peak, up)
		# an arc, not a lift: a little forward going up, landing forward
		mpos.x += 26.0 * Anim.span(t, 2.9, 3.34)
	if paws_up > 0.0:
		mpos.y -= 14.0 * paws_up
	if nudge > 0.0:
		# up on her hind legs until her nose is on the phone
		var probe2 := IntroKit.millie_points(Vector2.ZERO, MS, face, sq, pose)
		mpos = mpos.lerp(PHONE + Vector2(-6, 22) - probe2["mouth"], Anim.curve("io", nudge))
	var ms := MS
	var mp := IntroKit.millie_points(mpos, ms, face, sq, pose)

	# --------------------------------------------------------------- your human
	# the yank lands: the arm is hauled out straight and the body tips after
	# it (9.27-9.42), then they leave the seat on a rising diagonal
	var tip := Anim.span(t, 9.27, 9.42)
	var off_sofa := Anim.span(t, 9.42, 9.54)
	var fly := Anim.span(t, 9.42, 9.8)
	var hx: float = lerpf(SOFA_X, 1500.0, Anim.curve("in", fly))
	var hy: float = FLOOR - sin(fly * PI) * 70.0 - 40.0 * off_sofa * (1.0 - fly)
	var reach: float = Anim.k(t, [[8.1, 0.0], [8.3, 0.35, "out"], [8.6, 0.8, "io"], [8.95, 0.3, "io"]])
	var hpose := {
		"sit": 1.0 - off_sofa,
		"lean": lerpf(0.15 + 0.5 * tip, 1.3, off_sofa) + Anim.k(t, [[8.1, 0.0], [8.3, 0.25, "out"], [8.55, 0.0, "io"]])
			+ 0.02 * sin(t * 2.4) * (1.0 - off_sofa),
		"scroll": t * 1.3 if t < 6.85 or t > 7.4 else 0.0,
		"blink": 1.0 if fposmod(t, 3.1) < 0.12 and t < 9.2 else 0.0,
		"phone": 1.0,
		"glow": 1.0,
		"reach": maxf(reach, tip) if t < 9.42 else 1.0,
		"reach_down": Anim.k(t, [[8.1, 0.0], [8.3, 0.6, "out"], [8.55, 0.0, "io"]]),
		"lift": off_sofa,
		"stride": t * 26.0,
		"phone_jolt": Anim.k(t, [[6.88, 0.0], [6.93, 1.0, "snap"], [7.02, 1.0], [7.22, 0.0, "back"]]),
		"head": Anim.k(t, [[6.88, 0.0], [6.93, -0.2, "snap"], [7.2, 0.0, "io"], [9.38, 0.0], [9.44, 0.25, "snap"]]),
		"mouth": 1.0 if t > 9.42 else 0.0,
	}
	var hsq := Vector2.ONE if t < 9.42 else Vector2(1.2, 0.86)

	# ------------------------------------------------------------------ draw
	_light(c)
	_sofa(c)
	_window_light(c)
	# out of the door and past its right jamb (_door_front hides them there)
	var m_gone := mx >= 1470.0
	var h_gone := hx >= 1490.0
	var hand := Vector2(hx + 60.0, hy - 150.0)
	if not h_gone:
		hand = IntroKit.human(c, Vector2(hx, hy), S, 1.0, hsq, hpose, 0.0,
			FLOOR if t >= 9.42 else INF)
	# for the first frames off the seat, the sofa's back is in front of the legs
	if t > 9.42 and t < 9.58:
		IntroKit.box(c, Rect2(SOFA_X - 118, FLOOR - 236, 62, 210), 24.0, Color(0.78, 0.36, 0.28))
	# the leash, drawn behind her while she has it, in front of the human:
	# doubled on its hook; clipped to her collar with the loop in her mouth;
	# the loop dropped on their knee; the loop taken by the hand
	var hook_pt := HOOK + Vector2(0, 8)
	# while she carries it the leash is drawn in front of her, so you can see
	# she has it; the rest of the time behind; and not at all once they are out
	var rope_front := t >= 3.3 and t < 5.25
	var draw_rope := func() -> void:
		if t < 3.12:
			IntroKit.rope(c, t, hook_pt, hook_pt + Vector2(5, 0), true, LEASH_LEN, FLOOR - 4.0)
		elif t < 5.25:
			# carried gathered up in her mouth: a short swinging bight under
			# her chin, taken in as she lands
			var gather := Anim.curve("io", Anim.span(t, 3.12, 3.45))
			IntroKit.rope(c, t, mp["ring"], mp["mouth"], true, lerpf(LEASH_LEN, CARRY_LEN, gather), FLOOR - 4.0)
		elif t < 8.3:
			# let go on their knee, it pays back out to its whole length
			var to_knee := Anim.curve("io", Anim.span(t, 5.25, 5.4))
			var out := Anim.curve("io", Anim.span(t, 5.25, 5.9))
			IntroKit.rope(c, t, mp["ring"], mp["mouth"].lerp(KNEE, to_knee), true, lerpf(CARRY_LEN, LEASH_LEN, out), FLOOR - 4.0)
		else:
			var take := Anim.curve("io", Anim.span(t, 8.3, 8.6))
			IntroKit.rope(c, t, mp["ring"], KNEE.lerp(hand, take), true, LEASH_LEN, FLOOR - 4.0)
	if m_gone:
		# she is out: the leash runs from the hand out past the jamb
		mp["ring"] = Vector2(DOOR.end.x + 60.0, FLOOR - 60.0)
	if not rope_front and not h_gone:
		draw_rope.call()
	var m := mp
	if not m_gone:
		m = IntroKit.millie(c, mpos, ms, face, sq, pose, FLOOR)
	if rope_front:
		draw_rope.call()
	# the human's non-reply: a "..." over their head, after the phone jolts
	if t > 7.25 and t < 8.15:
		IntroKit.dots(c, Vector2(SOFA_X + 96, FLOOR - 352), t - 7.25)
	# the sigh: a soft curl of breath, drifting up and away from them
	IntroKit.breath(c, m["mouth"] + Vector2(signf(face) * 14.0, -8.0), Anim.span(t, 7.62, 8.4), face)
	_sunbeam(c, t)
	_woof(c, t)
	# the dash: speed lines behind both, a puff of dust where she left
	if t > 9.27 and not m_gone:
		IntroKit.speed_lines(c, mpos + Vector2(-60, -60), Vector2.RIGHT, 80.0, 3, 0.7)
	if t > 9.27 and t < 10.0:
		for k in range(3):
			IntroKit.puff(c, Vector2(650.0 - float(k) * 28.0, FLOOR - 12.0 - float(k % 2) * 12.0), 13.0 - float(k) * 3.0,
				1.0 - Anim.span(t, 9.3, 10.0))
	if hx > 620.0 and not h_gone:
		IntroKit.speed_lines(c, Vector2(hx, hy) + Vector2(-80, -140), Vector2.RIGHT, 80.0, 3, 0.6)
	# out of the door: whoever runs through the doorway goes behind the wall
	# beside it, as out of any door, instead of being swallowed by its light
	if t > YANK_AT:
		_door_front(c)
	# a quick white flash once they are out, then the street
	var flash: float = Anim.k(t, [[9.84, 0.0], [9.95, 1.0, "out"], [TITLE_AT, 1.0]])
	IntroKit.fade(c, flash, Color(1.0, 0.98, 0.92))
	IntroKit.fade(c, 1.0 - Anim.span(t, 0.0, 0.8))


# The wall, casing and dressing to the right of the doorway's opening, cut out
# of the static layers once and drawn over the characters during the exit, so
# they run out through the doorway and pass behind its right jamb.
static var _bg_front: Tris


static func _door_front(c: CanvasItem) -> void:
	if _bg_front == null:
		_bg_front = Tris.new()
		var r := Rect2(DOOR.end.x, MARGIN.position.y - 400.0, MARGIN.end.x + 400.0 - DOOR.end.x,
			FLOOR + 3.0 - (MARGIN.position.y - 400.0))
		for layer: Tris in [_bg_room, _bg_dressing, _bg_light]:
			if layer != null:
				_clip_into(layer, r, _bg_front)
	_bg_front.draw(c)


# every triangle of src cut to the rect r (Sutherland-Hodgman, colours carried
# along the cut edges), fanned into dst
static func _clip_into(src: Tris, r: Rect2, dst: Tris) -> void:
	for i in range(0, src.pts.size() - 2, 3):
		var poly: Array = [[src.pts[i], src.cols[i]], [src.pts[i + 1], src.cols[i + 1]], [src.pts[i + 2], src.cols[i + 2]]]
		# the four edges of r as (axis, limit, keep greater)
		for edge: Array in [[0, r.position.x, true], [0, r.end.x, false], [1, r.position.y, true], [1, r.end.y, false]]:
			if poly.is_empty():
				break
			var out: Array = []
			for j in range(poly.size()):
				var a: Array = poly[j]
				var b: Array = poly[(j + 1) % poly.size()]
				var av: float = (a[0] as Vector2)[edge[0]]
				var bv: float = (b[0] as Vector2)[edge[0]]
				var a_in: bool = av >= edge[1] if edge[2] else av <= edge[1]
				var b_in: bool = bv >= edge[1] if edge[2] else bv <= edge[1]
				if a_in:
					out.append(a)
				if a_in != b_in:
					var f := (float(edge[1]) - av) / (bv - av)
					out.append([(a[0] as Vector2).lerp(b[0], f), (a[1] as Color).lerp(b[1], f)])
			poly = out
		for k in range(1, poly.size() - 1):
			dst.tri(poly[0][0], poly[k][0], poly[k + 1][0], poly[0][1], poly[k][1], poly[k + 1][1])


# The window's sun as a beam through the room, one hard-edged pale shape from
# the panes to the patch on the floor, with dust drifting slowly down it. One
# batch for the motes; their drift is a pure function of t.
const MOTES := 18
static var _motes: ShapeBatch


static func _sunbeam(c: CanvasItem, t: float) -> void:
	c.draw_colored_polygon(PackedVector2Array([Vector2(150, 130), Vector2(360, 130), Vector2(720, 682), Vector2(524, 682),
		Vector2(392, 616), Vector2(150, 360)]), Color(1.0, 0.93, 0.70, 0.085))
	if _motes == null:
		_motes = ShapeBatch.new()
	for i in range(MOTES):
		var h := fposmod(float(i) * 0.6180339, 1.0)
		var u := fposmod(h * 3.7 + t * (0.025 + 0.02 * h), 1.0)
		var v := clampf(fposmod(h * 7.3, 1.0) + 0.05 * sin(t * 0.8 + float(i)), 0.0, 1.0)
		var top := Vector2(150, 130).lerp(Vector2(360, 130), v)
		var bot := Vector2(524, 682).lerp(Vector2(720, 682), v)
		var p := top.lerp(bot, u) + Vector2(6.0 * sin(t * 0.6 + float(i) * 1.7), 0.0)
		var a := sin(PI * u) * (0.45 + 0.35 * (0.5 + 0.5 * sin(t * 2.3 + float(i) * 2.1)))
		_motes.circle(p, 2.0 + 1.4 * h, Color(1.0, 0.97, 0.86, a))
	_motes.flush(c)


# the bark: a comic burst where her head was, popping in and gone as she bolts
static func _woof(c: CanvasItem, t: float) -> void:
	var pop: float = Anim.k(t, [[YANK_AT, 0.0], [YANK_AT + 0.06, 1.18, "out"], [YANK_AT + 0.13, 1.0, "io"],
		[YANK_AT + 0.22, 1.0], [YANK_AT + 0.29, 0.0, "in"]])
	if pop <= 0.01:
		return
	var at := Vector2(818, 452)
	var rot := -0.12
	var star := PackedVector2Array()
	var ink := PackedVector2Array()
	for i in range(18):
		var a := TAU * float(i) / 18.0 + rot
		var r := (58.0 if i % 2 == 0 else 40.0) * (1.0 + 0.06 * sin(float(i) * 2.7))
		star.append(at + Vector2(cos(a) * r * 1.25, sin(a) * r * 0.85) * pop)
		ink.append(at + Vector2(cos(a) * (r + 5.0) * 1.25, sin(a) * (r + 5.0) * 0.85) * pop)
	c.draw_colored_polygon(ink, LINE)
	c.draw_colored_polygon(star, Color(1.0, 0.97, 0.86))
	var f := IntroTitle._face(30, 0.04)
	var w := IntroTitle._width("WOOF!", 30, 0.04)
	c.draw_set_transform(at, rot, Vector2(pop, pop))
	c.draw_string_outline(f, Vector2(-w * 0.5, 11), "WOOF!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, IntroTitle.LOGO_CREAM)
	c.draw_string(f, Vector2(-w * 0.5, 11), "WOOF!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, IntroTitle.LOGO_RED)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# the street they burst out into, in the Eixample morning: a sky, the Sagrada
# Família's spires in the haze, a row of house fronts with green persianes,
# iron balconies, cornices and shops with awnings at street level, two plane
# trees, a lamppost, a pavement of hexagonal panots, the kerb and the road.
# The fronts are hazed where the title hangs so its cream letters read.
const STREET_BASE := 640.0
const CURB_Z := 207.0


static func _street(c: CanvasItem) -> void:
	if _bg_street == null:
		_bg_street = Tris.new()
		_build_street(_bg_street)
	_bg_street.draw(c)


# a point of the pavement at depth z in front of the house fronts
static func _sp(x: float, z: float) -> Vector2:
	var s := PERSP / (PERSP - z)
	return Vector2(VP_X + (x - VP_X) * s, HORIZON + (STREET_BASE - HORIZON) * s)


static func _build_street(b: Tris) -> void:
	var l := MARGIN.position.x - 300.0
	var span := MARGIN.size.x + 600.0
	var top := MARGIN.position.y - 300.0
	b.vgrad(Rect2(l, top, span, 1200), Color(0.30, 0.54, 0.84), Color(0.50, 0.72, 0.92))
	b.vgrad(Rect2(l, top + 1200, span, 460.0 - top - 1200), Color(0.50, 0.72, 0.92), Color(0.97, 0.92, 0.82))
	for cl: Vector3 in [Vector3(130, 70, 1.0), Vector3(1640, 40, 1.3), Vector3(-460, 10, 1.2), Vector3(520, -300, 1.6),
			Vector3(1300, -620, 2.0), Vector3(-300, -760, 1.8)]:
		_cloud(b, Vector2(cl.x, cl.y), cl.z)
	# the Sagrada Família, far off in the haze over the rooftops
	var far := Color(0.70, 0.76, 0.86)
	for sp: Vector3 in [Vector3(1004, 40, 9), Vector3(1032, 12, 10), Vector3(1062, 18, 10), Vector3(1090, 50, 9)]:
		b.poly(_pts([Vector2(sp.x - sp.z, 240), Vector2(sp.x - sp.z * 0.6, sp.y + 40), Vector2(sp.x, sp.y),
			Vector2(sp.x + sp.z * 0.6, sp.y + 40), Vector2(sp.x + sp.z, 240)]), far)
		b.oval(Vector2(sp.x, sp.y - 3), Vector2(3.5, 3.5), far.lightened(0.1), 10)
		var wy := sp.y + 50.0
		while wy < 200.0:
			b.rect(Rect2(sp.x - 1.5, wy, 3, 6), far.darkened(0.06))
			wy += 14.0
	b.rect(Rect2(990, 150, 112, 90), far)
	# the house fronts
	var x := -120.0
	var k := 0
	var lefts: Array[float] = []
	while x > MARGIN.position.x - 200.0:
		k -= 1
		x -= 240.0 + float(posmod(k * 37, 60))
		lefts.append(x)
	k = -lefts.size()
	for i in range(lefts.size()):
		_house(b, lefts[lefts.size() - 1 - i], k + i)
	x = -120.0
	k = 0
	while x < MARGIN.end.x + 200.0:
		x += _house(b, x, k)
		k += 1
	# a haze over the fronts where the title hangs
	var haze := Color(0.98, 0.95, 0.88)
	b.vgrad(Rect2(l, 120, span, 150), Color(haze, 0.0), Color(haze, 0.55))
	b.rect(Rect2(l, 270, span, 140), Color(haze, 0.55))
	b.vgrad(Rect2(l, 410, span, 150), Color(haze, 0.55), Color(haze, 0.12))
	b.rect(Rect2(l, 560, span, 80), Color(haze, 0.12))
	# the pavement: hexagonal panots in grey, in perspective, out to the kerb
	b.quad(_sp(l, 0), _sp(l + span, 0), _sp(l + span, CURB_Z), _sp(l, CURB_Z), Color(0.56, 0.54, 0.54))
	var hr := 19.0
	var cx := -1300.0
	var ci := 0
	while cx < 2700.0:
		var cz := (hr * 0.866) if ci % 2 == 1 else 0.0
		while cz < CURB_Z + hr:
			var hex := PackedVector2Array()
			var inner := PackedVector2Array()
			for a in range(6):
				var ang := float(a) * PI / 3.0
				var p := Vector2(cx + cos(ang) * (hr - 1.4), clampf(cz + sin(ang) * (hr - 1.4), 0.0, CURB_Z))
				hex.append(_sp(p.x, p.y))
				var p2 := Vector2(cx + cos(ang) * hr * 0.42, clampf(cz + sin(ang) * hr * 0.42, 0.0, CURB_Z))
				inner.append(_sp(p2.x, p2.y))
			var tone := Color(0.80, 0.77, 0.72).lerp(Color(0.86, 0.83, 0.78), _h(ci * 13 + int(cz)))
			b.fan(hex, tone)
			b.fan(inner, tone.darkened(0.07))
			cz += hr * 1.732
		cx += hr * 1.5
		ci += 1
	b.vgrad(Rect2(l, STREET_BASE, span, 14), Color(SHADE, 0.22), Color(SHADE, 0.0))
	# the plane trees and the lamppost
	_plane_tree(b, 20.0)
	_plane_tree(b, 1262.0)
	_lamppost(b, 990.0)
	# the kerb, the gutter and the road
	var kerb := _sp(0, CURB_Z).y
	b.rect(Rect2(l, kerb, span, 6), Color(0.86, 0.84, 0.80))
	b.rect(Rect2(l, kerb + 6, span, 12), Color(0.58, 0.56, 0.56))
	b.rect(Rect2(l, kerb + 18, span, 4), Color(0.26, 0.24, 0.27))
	b.vgrad(Rect2(l, kerb + 22, span, MARGIN.end.y + 300.0 - kerb), Color(0.42, 0.41, 0.44), Color(0.26, 0.25, 0.29))
	var paint := Color(0.92, 0.90, 0.84)
	var dx := -1200.0
	while dx < 2700.0:
		if dx + 124.0 < 640.0 or dx > 1160.0:
			b.quad(Vector2(dx, 862), Vector2(dx + 120, 862), Vector2(dx + 124, 872), Vector2(dx - 4, 872), paint)
		dx += 220.0
	# a zebra crossing, and the kerb and pavement on the near side
	var zx := 700.0
	while zx < 1120.0:
		b.quad(Vector2(zx, kerb + 34), Vector2(zx + 34, kerb + 34), Vector2(VP_X + (zx + 34 - VP_X) * 1.5, 1096),
			Vector2(VP_X + (zx - VP_X) * 1.5, 1096), paint)
		zx += 70.0
	b.rect(Rect2(l, 1108, span, 10), Color(0.20, 0.19, 0.22))
	b.rect(Rect2(l, 1118, span, 22), Color(0.62, 0.60, 0.60))
	b.rect(Rect2(l, 1140, span, 12), Color(0.88, 0.86, 0.82))
	b.rect(Rect2(l, 1152, span, MARGIN.end.y + 300.0 - 1152), Color(0.58, 0.56, 0.56))
	var hx := -1300.0
	var hi := 0
	while hx < 2700.0:
		var hy := 1152.0 + (39.0 if hi % 2 == 1 else 0.0)
		while hy < MARGIN.end.y + 100.0:
			var hex := PackedVector2Array()
			for a in range(6):
				hex.append(Vector2(hx, hy) + Vector2.from_angle(float(a) * PI / 3.0) * Vector2(43, 37))
			b.fan(hex, Color(0.80, 0.77, 0.72).lerp(Color(0.86, 0.83, 0.78), _h(hi * 7 + int(hy))))
			hy += 78.0
		hx += 67.5
		hi += 1
	b.oval(Vector2(520, 800), Vector2(46, 10), Color(0.30, 0.29, 0.32), 20)
	b.oval(Vector2(520, 799), Vector2(40, 8), Color(0.36, 0.35, 0.38), 20)


static func _cloud(b: Tris, at: Vector2, s: float) -> void:
	var white := Color(1.0, 0.99, 0.97)
	var under := Color(0.86, 0.88, 0.96)
	b.rect(Rect2(at + Vector2(-60, 0) * s, Vector2(130, 14) * s), under)
	for bl: Vector3 in [Vector3(-36, -4, 22), Vector3(-6, -18, 30), Vector3(30, -8, 24), Vector3(56, 0, 16)]:
		b.oval(at + Vector2(bl.x, bl.y + 4) * s, Vector2(bl.z, bl.z) * s, under, 18)
	for bl: Vector3 in [Vector3(-36, -4, 22), Vector3(-6, -18, 30), Vector3(30, -8, 24), Vector3(56, 0, 16)]:
		b.oval(at + Vector2(bl.x, bl.y) * s, Vector2(bl.z, bl.z) * s, white, 18)
	b.rect(Rect2(at + Vector2(-60, -6) * s, Vector2(130, 14) * s), white)


# one house front of the Eixample: a stone shop floor with an awning, then
# floors of tall balcony doors with green persianes, a cornice and parapet
static func _house(b: Tris, x: float, k: int) -> float:
	var w := 240.0 + float(posmod(k * 37, 60))
	var top := 110.0 + float(posmod(k * 53, 90))
	var fronts := [Color(0.92, 0.78, 0.56), Color(0.90, 0.66, 0.56), Color(0.93, 0.86, 0.72), Color(0.78, 0.80, 0.66),
		Color(0.88, 0.70, 0.50)]
	var col: Color = fronts[posmod(k, fronts.size())]
	var stone := col.darkened(0.10)
	b.rect(Rect2(x, top, w, STREET_BASE - top), col)
	b.rect(Rect2(x, top, 3, STREET_BASE - top), Color(SHADE, 0.25))
	# the parapet, the cornice and its shadow
	b.rect(Rect2(x + 6, top - 18, w - 12, 18), col.lightened(0.06))
	var bx := x + 14.0
	while bx < x + w - 18.0:
		b.rect(Rect2(bx, top - 14, 5, 12), col.darkened(0.16))
		bx += 12.0
	b.rect(Rect2(x + 2, top - 22, w - 4, 5), col.lightened(0.12))
	b.rect(Rect2(x, top, w, 10), col.darkened(0.14))
	b.rect(Rect2(x, top, w, 2), col.lightened(0.15))
	b.vgrad(Rect2(x, top + 10, w, 10), Color(SHADE, 0.24), Color(SHADE, 0.0))
	# the shop floor: rusticated stone, a shop window and door, an awning
	var shop_top := 528.0
	b.rect(Rect2(x, shop_top, w, STREET_BASE - shop_top), stone)
	var gy := shop_top + 14.0
	while gy < STREET_BASE:
		b.rect(Rect2(x, gy, w, 1.5), stone.darkened(0.14))
		gy += 14.0
	b.rect(Rect2(x, shop_top - 6, w, 6), col.lightened(0.1))
	var sw := Rect2(x + 22, 552, w - 44, STREET_BASE - 552)
	var frame: Color = [Color(0.20, 0.36, 0.30), Color(0.30, 0.20, 0.16), Color(0.18, 0.22, 0.32)][posmod(k, 3)]
	b.rect(sw.grow(4), frame)
	b.vgrad(sw, Color(0.24, 0.28, 0.32), Color(0.14, 0.16, 0.20))
	var door_x := sw.end.x - 34.0
	b.rect(Rect2(door_x, sw.position.y, 4, sw.size.y), frame)
	var ix := sw.position.x + 8.0
	var n := 0
	while ix < door_x - 18.0:
		var ih := 14.0 + 16.0 * _h(k * 17 + n)
		b.rect(Rect2(ix, STREET_BASE - 12 - ih, 12, ih),
			[Color(0.90, 0.62, 0.30), Color(0.86, 0.32, 0.28), Color(0.94, 0.90, 0.80), Color(0.40, 0.62, 0.44)][(n + k) % 4])
		ix += 18.0
		n += 1
	b.rect(Rect2(sw.position.x, STREET_BASE - 12, door_x - sw.position.x, 3), frame.lightened(0.2))
	b.quad(Vector2(sw.position.x + 6, sw.end.y), Vector2(sw.position.x + 22, sw.end.y), Vector2(sw.position.x + 60, sw.position.y),
		Vector2(sw.position.x + 44, sw.position.y), Color(1, 1, 1, 0.10))
	if posmod(k, 2) == 0:
		var stripe: Color = [Color(0.80, 0.28, 0.24), Color(0.22, 0.50, 0.38), Color(0.24, 0.40, 0.62)][posmod(int(floor(float(k) / 2.0)), 3)]
		var ax0 := x + 14.0
		var ax1 := x + w - 14.0
		b.quad(Vector2(ax0 + 4, 548), Vector2(ax1 - 4, 548), Vector2(ax1 + 4, 576), Vector2(ax0 - 4, 576), Color(SHADE, 0.30))
		b.quad(Vector2(ax0, 530), Vector2(ax1, 530), Vector2(ax1 + 6, 562), Vector2(ax0 - 6, 562), Color(0.97, 0.94, 0.88))
		var sx := ax0
		var j := 0
		while sx < ax1:
			var s1 := minf(sx + 14.0, ax1)
			if j % 2 == 0:
				var u0 := (sx - ax0) / (ax1 - ax0)
				var u1 := (s1 - ax0) / (ax1 - ax0)
				b.quad(Vector2(sx, 530), Vector2(s1, 530), Vector2(lerpf(ax0 - 6, ax1 + 6, u1), 562), Vector2(lerpf(ax0 - 6, ax1 + 6, u0), 562), stripe)
			var mid := lerpf(ax0 - 6, ax1 + 6, ((sx + s1) * 0.5 - ax0) / (ax1 - ax0))
			b.oval(Vector2(mid, 562), Vector2(7, 5), stripe if j % 2 == 0 else Color(0.97, 0.94, 0.88), 10)
			sx = s1
			j += 1
	else:
		b.rect(Rect2(x + 30, 532, w - 60, 14), frame)
		b.rect(Rect2(x + 36, 537, w - 72, 4), Color(0.96, 0.90, 0.70))
	if posmod(k, 5) == 1:
		# a pharmacy's green cross
		var pc := Vector2(x + w - 30, 506)
		b.rect(Rect2(pc - Vector2(13, 5), Vector2(26, 10)).grow(2), Color(0.96, 0.98, 0.94))
		b.rect(Rect2(pc - Vector2(5, 13), Vector2(10, 26)).grow(2), Color(0.96, 0.98, 0.94))
		b.rect(Rect2(pc - Vector2(13, 5), Vector2(26, 10)), Color(0.16, 0.66, 0.32))
		b.rect(Rect2(pc - Vector2(5, 13), Vector2(10, 26)), Color(0.16, 0.66, 0.32))
	# the floors above, the first a principal floor with one long balcony
	var nwin := maxi(2, int((w - 40.0) / 66.0))
	var pitch := (w - 40.0) / float(nwin)
	var floor_y := shop_top
	var fi := 0
	while floor_y - 92.0 >= top + 20.0:
		var wb := floor_y - 10.0
		var wt := wb - 64.0
		b.rect(Rect2(x, floor_y - 4, w, 4), col.darkened(0.06))
		if fi == 0:
			_balcony(b, x + 12.0, x + w - 12.0, wb)
		for j in range(nwin):
			var wx := x + 20.0 + pitch * (float(j) + 0.5) - 16.0
			_persiana(b, Rect2(wx, wt, 32, 64), k * 31 + fi * 7 + j, col)
			if fi > 0:
				_balcony(b, wx - 9.0, wx + 41.0, wb)
			if _h(k * 11 + fi * 5 + j * 3) > 0.72:
				b.oval(Vector2(wx + 2, wb - 8), Vector2(7, 6), Color(0.30, 0.52, 0.28), 10)
				b.oval(Vector2(wx + 1, wb - 11), Vector2(2.5, 2.5), Color(0.90, 0.22, 0.26), 8)
				b.oval(Vector2(wx + 5, wb - 9), Vector2(2.2, 2.2), Color(0.94, 0.40, 0.48), 8)
				b.rect(Rect2(wx - 4, wb - 6, 12, 6), Color(0.78, 0.40, 0.26))
		floor_y -= 92.0
		fi += 1
	return w


# a tall balcony door with its persiana: closed, part rolled up, or open with
# its leaves folded back; a moulded lintel over it
static func _persiana(b: Tris, r: Rect2, sd: int, wall: Color) -> void:
	var green := Color(0.28, 0.52, 0.40) if sd % 3 != 0 else Color(0.34, 0.56, 0.42)
	var slat := green.darkened(0.28)
	b.rect(Rect2(r.position.x - 5, r.position.y - 10, r.size.x + 10, 6), wall.lightened(0.10))
	b.rect(Rect2(r.position.x - 3, r.position.y - 4, r.size.x + 6, 4), wall.darkened(0.12))
	b.rect(r.grow(2.0), wall.darkened(0.2))
	b.rect(r, Color(0.20, 0.16, 0.20))
	var state := int(_h(sd) * 3.0)
	if state == 2:
		b.rect(Rect2(r.position.x - 9, r.position.y, 9, r.size.y), green)
		b.rect(Rect2(r.end.x, r.position.y, 9, r.size.y), green.darkened(0.12))
		b.rect(Rect2(r.position.x + 4, r.position.y + 4, 10, r.size.y - 8), Color(0.94, 0.90, 0.84, 0.75))
		return
	var drop := r.size.y if state == 0 else r.size.y * (0.35 + 0.35 * _h(sd + 3))
	b.rect(Rect2(r.position, Vector2(r.size.x, drop)), green)
	var sy := r.position.y + 3.0
	while sy < r.position.y + drop - 1.0:
		b.rect(Rect2(r.position.x, sy, r.size.x, 1.2), slat)
		sy += 4.5
	if state == 0:
		b.rect(Rect2(r.position.x + r.size.x * 0.5 - 0.6, r.position.y, 1.2, r.size.y), slat.darkened(0.2))
	else:
		b.rect(Rect2(r.position.x, r.position.y + drop - 2, r.size.x, 2), slat.darkened(0.2))


# a balcony: the stone slab, its hard shadow down and right on the wall, the
# wrought-iron railing with a band of rings
static func _balcony(b: Tris, x0: float, x1: float, y: float) -> void:
	var iron := Color(0.14, 0.12, 0.15)
	b.quad(Vector2(x0 + 2, y + 5), Vector2(x1 + 2, y + 5), Vector2(x1 + 12, y + 20), Vector2(x0 + 12, y + 20), Color(SHADE, 0.26))
	b.rect(Rect2(x0, y, x1 - x0, 5), Color(0.94, 0.91, 0.84))
	b.rect(Rect2(x0, y + 5, x1 - x0, 2), Color(0.70, 0.64, 0.62))
	b.rect(Rect2(x0 + 1, y - 24, x1 - x0 - 2, 2), iron)
	b.rect(Rect2(x0 + 1, y - 12, x1 - x0 - 2, 1.2), iron)
	var bx := x0 + 2.0
	while bx < x1 - 1.0:
		b.rect(Rect2(bx, y - 24, 1.1, 24), iron)
		bx += 4.0
	var rx := x0 + 6.0
	while rx < x1 - 4.0:
		b.oval(Vector2(rx, y - 18), Vector2(2.6, 2.6), iron, 8)
		b.oval(Vector2(rx, y - 18), Vector2(1.4, 1.4), Color(0.80, 0.78, 0.74), 8)
		rx += 10.0


# a plane tree: a mottled trunk forking into a cel-shaded crown, in a square of iron grating
static func _plane_tree(b: Tris, tx: float) -> void:
	var foot := _sp(tx, 40.0)
	var crown := Vector2(tx, 360)
	b.quad(_sp(tx - 26, 20), _sp(tx + 26, 20), _sp(tx + 26, 62), _sp(tx - 26, 62), Color(0.24, 0.22, 0.24))
	var gx := tx - 22.0
	while gx < tx + 24.0:
		b.quad(_sp(gx, 22), _sp(gx + 2, 22), _sp(gx + 2, 60), _sp(gx, 60), Color(0.38, 0.36, 0.38))
		gx += 7.0
	var bark := Color(0.66, 0.62, 0.50)
	var trunk := _pts([foot + Vector2(-10, 0), foot + Vector2(10, 0), Vector2(tx + 7, 420), Vector2(tx + 34, 370), Vector2(tx + 26, 366),
		Vector2(tx + 2, 404), Vector2(tx - 4, 404), Vector2(tx - 30, 362), Vector2(tx - 37, 368), Vector2(tx - 7, 420)])
	b.inked(trunk, bark, 1.5, PROP_INK)
	for p: Vector3 in [Vector3(-3, 600, 5), Vector3(4, 560, 4), Vector3(-4, 500, 4.5), Vector3(3, 460, 3.5), Vector3(-2, 430, 3)]:
		b.oval(Vector2(tx + p.x, p.y), Vector2(p.z, p.z * 2.2), Color(0.86, 0.84, 0.70), 10)
	for p: Vector3 in [Vector3(4, 620, 4), Vector3(-4, 530, 4), Vector3(4, 486, 3.5), Vector3(-1, 445, 3)]:
		b.oval(Vector2(tx + p.x, p.y), Vector2(p.z, p.z * 2.0), Color(0.50, 0.50, 0.40), 10)
	b.clip(trunk, _pts([Vector2(tx + 3, 300), Vector2(tx + 60, 300), Vector2(tx + 60, 700), Vector2(tx + 4, 700)]), Color(SHADE, 0.22))
	var dark := Color(0.24, 0.42, 0.26)
	var mid := Color(0.36, 0.56, 0.30)
	var hi := Color(0.52, 0.70, 0.36)
	var blobs := [Vector3(-80, 20, 50), Vector3(-30, -30, 64), Vector3(40, -24, 60), Vector3(92, 18, 50), Vector3(-44, 52, 48),
		Vector3(24, 46, 56), Vector3(0, -70, 48)]
	for bl: Vector3 in blobs:
		b.oval(crown + Vector2(bl.x, bl.y), Vector2(bl.z + 2.5, bl.z * 0.84 + 2.5), PROP_INK, 22)
	for bl: Vector3 in blobs:
		b.oval(crown + Vector2(bl.x, bl.y), Vector2(bl.z, bl.z * 0.84), dark, 22)
	for bl: Vector3 in blobs:
		b.oval(crown + Vector2(bl.x - 10, bl.y - 12), Vector2(bl.z * 0.78, bl.z * 0.62), mid, 20)
	for bl: Vector3 in [Vector3(-40, -44, 34), Vector3(28, -40, 30), Vector3(-86, 4, 24), Vector3(-8, -84, 24), Vector3(10, 28, 24)]:
		b.oval(crown + Vector2(bl.x, bl.y), Vector2(bl.z, bl.z * 0.7), hi, 18)
	b.line(Vector2(tx - 30, 362), Vector2(tx - 46, 330), bark.darkened(0.1), 4.0)
	b.line(Vector2(tx + 30, 368), Vector2(tx + 50, 336), bark.darkened(0.2), 4.0)


# an Eixample street lamp: dark green iron, a lantern on a crook
static func _lamppost(b: Tris, lx: float) -> void:
	var iron := Color(0.16, 0.26, 0.22)
	var foot := _sp(lx, 30.0)
	b.oval(foot + Vector2(10, 2), Vector2(18, 3), Color(SHADE, 0.3), 12)
	b.inked(_pts([foot + Vector2(-9, 0), foot + Vector2(9, 0), foot + Vector2(6, -26), foot + Vector2(-6, -26)]), iron, 1.2, PROP_INK)
	b.line(foot + Vector2(0, -24), Vector2(lx, 440), PROP_INK, 7.0)
	b.line(foot + Vector2(0, -24), Vector2(lx, 440), iron, 5.0)
	b.line(foot + Vector2(-1.5, -24), Vector2(lx - 1.5, 440), iron.lightened(0.3), 1.2)
	b.line(Vector2(lx, 442), Vector2(lx + 4, 424), iron, 4.0)
	b.line(Vector2(lx + 4, 424), Vector2(lx + 22, 416), iron, 4.0)
	var lantern := _pts([Vector2(lx + 12, 424), Vector2(lx + 36, 424), Vector2(lx + 32, 448), Vector2(lx + 16, 448)])
	b.inked(lantern, Color(0.98, 0.95, 0.80), 2.5, iron)
	b.poly(_pts([Vector2(lx + 8, 424), Vector2(lx + 40, 424), Vector2(lx + 24, 412)]), iron)
	b.oval(Vector2(lx + 24, 452), Vector2(4, 3), iron, 10)


static func _title(c: CanvasItem, t: float) -> void:
	_street(c)
	IntroTitle.draw(c, t - TITLE_AT, "swing")
	# and there they go along the bottom: Millie trotting ahead, the leash
	# taut, your human towed after her, leaning in, still on the phone
	var x: float = Anim.k(t, [[10.25, -150.0], [14.3, 1720.0, "lin"]])
	if t > 10.25 and t < 14.3:
		# feet matched to the ground: her trot and their stride advance with
		# the distance covered, not the clock
		var mphase := x * TAU / (56.0 * TS)
		var mpose := {"gait": 1.0, "phase": mphase, "lean": 0.35, "crouch": 0.45, "push": 0.7, "head_up": 0.05,
			"tail": sin(mphase) * 0.3, "brow": 0.8, "mouth": 0.6}
		# towed: leaning back against it, short skidding steps, heels kicking dust
		var hp := Vector2(x - 300.0, 676.0)
		var hand := IntroKit.human(c, hp, TS, 1.0, Vector2.ONE,
			{"stride": x * 0.04, "stride_amp": 0.25, "phone": 1.0, "glow": 0.5, "reach": 1.0, "lean": -0.6}, 0.0, 676.0)
		for k in range(2):
			var dp := hp + Vector2(-20.0 - float(k) * 16.0, -6.0 - float(k) * 6.0)
			IntroKit.puff(c, dp, 7.0 - float(k) * 2.0 + sin(x * 0.2 + float(k)) * 1.5, 0.7)
		var mpt := IntroKit.millie_points(Vector2(x, 676.0), TS, 1.0, Vector2.ONE, mpose)
		IntroKit.leash(c, mpt["ring"], hand, 2.0 + 2.0 * sin(mphase * 2.0))
		IntroKit.millie(c, Vector2(x, 676.0), TS, 1.0, Vector2.ONE, mpose, 676.0)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.22), Color(1.0, 0.98, 0.92))
