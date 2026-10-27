class_name Obres
extends RefCounted

# Les Obres' dressing (#156): the works compound either side of the footway
# behind a run of Heras panels on their concrete feet, what is stacked in the
# compound (a skip, tarped stacks with their folds, pallets of blocks, rebar,
# spoil heaps), the marks on the dirt of the footway itself, and the two
# pours, each at its own stage. Everything here is drawn, never solid: the
# building line (main.frontage) is the collider the fence stands on.
# Draw-only and hashed from position, so a walk dresses the same every run.
# Also the walk's module (main.WALK_MODULES): the works over the paving,
# the digger, the worker and the conduit bundles are its hooks, below.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08, 0.22)

# the compound ground past the fence, darker and greyer than the footway
const YARD := Color(0.45, 0.41, 0.35)
# one Heras panel, foot to foot along the fence
const PANEL := 104.0
# a panel's shadow lies this far out, the way the light falls
const FENCE_CAST := 24.0
const GALV := Color(0.74, 0.76, 0.76)
const FOOT := Color(0.58, 0.57, 0.54)

const TARP_BLUE := Color(0.20, 0.38, 0.60)
const TARP_GREEN := Color(0.24, 0.42, 0.30)
const SKIP_COLS: Array[Color] = [Color(0.92, 0.66, 0.12), Color(0.86, 0.36, 0.14)]
const EARTH := Color(0.50, 0.40, 0.28)
const RUST := Color(0.46, 0.28, 0.18)

# utility marks sprayed on the footway's dirt ahead of the dig, the way a
# survey crew leaves them: [from, to, colour index]. Fractions across the
# path at their own y (0 = west edge, 1 = east), so they follow the bends.
const SPRAY_COLS: Array[Color] = [Color(0.96, 0.82, 0.16, 0.8), Color(0.22, 0.52, 0.92, 0.8), Color(0.96, 0.30, 0.56, 0.8)]
const SPRAY: Array = [
	[Vector2(0.12, -620.0), Vector2(0.12, -1000.0), 0],
	[Vector2(0.30, -1250.0), Vector2(0.34, -1560.0), 1],
	[Vector2(0.18, -2380.0), Vector2(0.28, -2700.0), 2],
	[Vector2(0.84, -3700.0), Vector2(0.86, -3900.0), 0],
	[Vector2(0.20, -4150.0), Vector2(0.14, -4600.0), 1],
]
# loose stuff lying on the footway, flat enough to walk over:
# [fraction across, y, kind, turn]
const LITTER: Array = [
	[0.10, -820.0, "offcuts", 0.3], [0.90, -1000.0, "bag", -0.4],
	[0.88, -1950.0, "offcuts", 1.2], [0.08, -2150.0, "gravel", 0.0],
	[0.92, -2600.0, "plank", 0.2], [0.10, -3050.0, "bag", 0.9],
	[0.08, -3600.0, "gravel", 0.0], [0.90, -4300.0, "offcuts", -0.6],
	[0.12, -4700.0, "plank", -0.15], [0.86, -4750.0, "gravel", 0.0],
]


static func _h(a: float, b: float) -> float:
	var n := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return n - floorf(n)


static func _quad(c: Vector2, half: Vector2, ang: float) -> PackedVector2Array:
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	return PackedVector2Array([c - ax * half.x - ay * half.y, c + ax * half.x - ay * half.y,
		c + ax * half.x + ay * half.y, c - ax * half.x + ay * half.y])


static func _at(m: Node2D, f: float, y: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2(lerpf(e.x, e.y, f), y)


# whether a road crosses the walk here (the fence and the compound stop for it)
static func _on_road(m: Node2D, y0: float, y1: float) -> bool:
	for ly: float in m.lane_ys:
		if y1 > ly - m.LANE_HALF - 6.0 and y0 < ly + m.LANE_HALF + 6.0:
			return true
	return false


# The Heras fence along both building lines: mesh panels between concrete
# feet, a coupler clamping each joint, the mesh's shadow lying out beside it
# (the only way a mesh panel reads from straight above), and now and then a
# contractor's banner zip-tied to a panel, which throws a solid shadow.
static func draw_fence(m: Node2D, b: Object, vt: float, vb: float) -> void:
	var top: float = float(m.GATE_Y) - 30.0
	var y := maxf(top, floorf((vt - PANEL) / PANEL) * PANEL)
	var off := LIGHT * FENCE_CAST
	while y < vb + PANEL:
		var y1 := y + PANEL
		if y < top or _on_road(m, y, y1):
			y = y1
			continue
		for side: float in [-1.0, 1.0]:
			var fa: Vector2 = m.frontage(y)
			var fb: Vector2 = m.frontage(y1)
			var a := Vector2(fa.x if side < 0.0 else fa.y, y)
			var c := Vector2(fb.x if side < 0.0 else fb.y, y1)
			var n := int(absf(y) / PANEL) + (0 if side < 0.0 else 5)
			var banner := n % 5 == 2
			# the shadow first: solid under a banner, a lattice under bare mesh
			if banner:
				b.polygon(PackedVector2Array([a + Vector2(0, 6), c - Vector2(0, 6), c - Vector2(0, 6) + off,
					a + Vector2(0, 6) + off]), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.2))
			else:
				b.polygon(PackedVector2Array([a, c, c + off, a + off]), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.06))
				var wires := 16
				for w in range(1, wires):
					var p := a.lerp(c, float(w) / float(wires))
					b.line(p, p + off, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.16), 1.0)
				for w in range(1, 5):
					var o := off * float(w) / 5.0
					b.line(a + o, c + o, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.16), 1.0)
				b.line(a + off, c + off, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.24), 2.0)
			# the panel seen from above: its top rail, the mesh a hairline in it
			b.line(a, c, GALV.darkened(0.35), 4.0)
			b.line(a, c, GALV, 2.5)
			if banner:
				var bp := a.lerp(c, 0.12)
				var bq := a.lerp(c, 0.88)
				b.line(bp, bq, Color(0.95, 0.95, 0.92), 5.0)
				b.line(bp, bq, Color(0.94, 0.46, 0.12), 2.0)
			# the foot at this end, across the fence line, with its two post holes
			var foot_c: Color = FOOT.darkened(0.08 * float(n % 3))
			if n % 7 == 3:
				foot_c = Color(0.20, 0.20, 0.21)       # a black rubber foot among the concrete
			var dir := (c - a).normalized()
			var fq := _quad(a, Vector2(8.0, 16.0), dir.angle())
			b.polygon(_quad(a + LIGHT * 3.0, Vector2(8.0, 16.0), dir.angle()), SHADOW)
			b.polygon(fq, foot_c)
			b.line(fq[0], fq[3], foot_c.lightened(0.2), 2.0)
			b.circle(a - dir * 3.0, 2.2, foot_c.darkened(0.45))
			b.circle(a + dir * 3.0, 2.2, foot_c.darkened(0.45))
			# the coupler clamping the two panels together
			b.rect(Rect2(a.x - 3.5, a.y - 2.0, 7.0, 4.0), Color(0.38, 0.40, 0.42))
			# a sandbag slung over the odd foot
			if n % 4 == 1:
				b.polygon(_quad(a + Vector2(side * 9.0, 6.0), Vector2(7.0, 5.0), 0.4), Color(0.70, 0.60, 0.42))
				b.line(a + Vector2(side * 9.0 - 4.0, 4.0), a + Vector2(side * 9.0 + 4.0, 8.0), Color(0.56, 0.48, 0.34), 1.5)
		y = y1


# One stretch of compound behind the fence: one main thing per stretch and
# something small beside it, set back from the fence at their own y so a bend
# in the line never pushes them through it.
static func draw_yard_module(m: Node2D, b: Object, r: Rect2, side: float, k: int) -> void:
	if _on_road(m, r.position.y, r.end.y):
		return
	var y0 := r.position.y
	# grit and ruts on the compound ground
	for g in range(9):
		var gy := y0 + _h(float(k), float(g)) * 220.0
		var fx: float = (m.frontage(gy).x if side < 0.0 else m.frontage(gy).y)
		var gp := Vector2(fx - side * (14.0 + _h(float(g), float(k)) * 240.0), gy)
		b.circle(gp, 1.6 + float(g % 3) * 0.6, YARD.darkened(0.2) if g % 2 == 0 else YARD.lightened(0.12))
	var kinds := ["skip", "tarp", "pallets", "spoil", "tarp", "rebar"]
	var kind: String = kinds[(k * 7 + int(side > 0.0) * 3) % kinds.size()]
	var my := y0 + 110.0
	var fm: float = (m.frontage(my).x if side < 0.0 else m.frontage(my).y)
	# the nearest the fence lets anything stand, over this stretch
	for s in range(5):
		var sf: Vector2 = m.frontage(y0 + float(s) * 55.0)
		fm = minf(fm, sf.x) if side < 0.0 else maxf(fm, sf.y)
	var back := side        # into the compound
	match kind:
		"skip":
			draw_skip(b, Vector2(fm + back * 62.0, my), k)
		"tarp":
			draw_tarp(b, Vector2(fm + back * 70.0, my + 10.0), TARP_BLUE if k % 2 == 0 else TARP_GREEN, k)
		"pallets":
			draw_pallet(b, Vector2(fm + back * 44.0, my - 40.0), 0.05, true)
			draw_pallet(b, Vector2(fm + back * 46.0, my + 26.0), -0.08, k % 3 != 0)
			draw_pallet(b, Vector2(fm + back * 100.0, my - 10.0), 0.12, false)
		"spoil":
			draw_spoil(b, Vector2(fm + back * 80.0, my), 46.0 + float(k % 3) * 8.0, k)
		"rebar":
			draw_rebar(b, Vector2(fm + back * 40.0, my), 1.5708 + 0.06 * float(k % 3 - 1), 150.0)
			draw_pallet(b, Vector2(fm + back * 90.0, my + 60.0), 0.2, true)
	# the small thing alongside: a bundle of rebar, a pallet, or a heap
	var sy := y0 + (24.0 if k % 2 == 0 else 196.0)
	var fs: float = (m.frontage(sy).x if side < 0.0 else m.frontage(sy).y)
	match (k + int(side > 0.0)) % 3:
		0:
			if kind != "rebar":
				draw_rebar(b, Vector2(fs + back * 190.0, sy), 0.25 * float(k % 3 - 1), 90.0)
		1:
			draw_spoil(b, Vector2(fs + back * 200.0, sy), 26.0, k + 3)


# A builder's skip: steel sides, the sloped ends showing lighter, chain lugs,
# and rubble in it - broken slab, bricks, a board.
static func draw_skip(b: Object, c: Vector2, k: int) -> void:
	var col: Color = SKIP_COLS[k % SKIP_COLS.size()]
	var hw := 32.0
	var hh := 58.0
	b.rect(Rect2(c.x - hw + 10.0, c.y - hh + 16.0, hw * 2.0, hh * 2.0), SHADOW)
	b.rect(Rect2(c.x - hw, c.y - hh, hw * 2.0, hh * 2.0), col.darkened(0.25))
	b.rect(Rect2(c.x - hw + 4.0, c.y - hh + 4.0, hw * 2.0 - 8.0, hh * 2.0 - 8.0), col)
	# the sloped ends: wider at the top rim than the floor
	b.polygon(PackedVector2Array([Vector2(c.x - hw + 4.0, c.y - hh + 4.0), Vector2(c.x + hw - 4.0, c.y - hh + 4.0),
		Vector2(c.x + hw - 10.0, c.y - hh + 22.0), Vector2(c.x - hw + 10.0, c.y - hh + 22.0)]), col.lightened(0.18))
	b.polygon(PackedVector2Array([Vector2(c.x - hw + 10.0, c.y + hh - 22.0), Vector2(c.x + hw - 10.0, c.y + hh - 22.0),
		Vector2(c.x + hw - 4.0, c.y + hh - 4.0), Vector2(c.x - hw + 4.0, c.y + hh - 4.0)]), col.darkened(0.12))
	var floor_r := Rect2(c.x - hw + 10.0, c.y - hh + 22.0, hw * 2.0 - 20.0, hh * 2.0 - 44.0)
	b.rect(floor_r, Color(0.30, 0.27, 0.24))
	# the rubble
	for i in range(11):
		var p := floor_r.position + Vector2(_h(float(k), float(i)) * floor_r.size.x, _h(float(i), float(k) + 2.0) * floor_r.size.y)
		var rc := [Color(0.62, 0.60, 0.56), Color(0.62, 0.34, 0.24), Color(0.48, 0.44, 0.40)][i % 3] as Color
		b.polygon(_quad(p, Vector2(5.0 + float(i % 3) * 2.0, 4.0), _h(float(i), 9.0) * 3.0), rc)
	b.line(floor_r.position + Vector2(4, 10), floor_r.position + Vector2(floor_r.size.x - 6.0, 34.0), Color(0.62, 0.48, 0.30), 4.0)
	# chain lugs at the ends
	for e: float in [-1.0, 1.0]:
		b.rect(Rect2(c.x - hw - 3.0, c.y + e * (hh - 14.0) - 3.0, 4.0, 6.0), col.darkened(0.45))
		b.rect(Rect2(c.x + hw - 1.0, c.y + e * (hh - 14.0) - 3.0, 4.0, 6.0), col.darkened(0.45))


# A stack under a tarp: the sheet draped over it with its creases, the ridge
# catching the light, rope over the top, and tyres holding the corners down.
static func draw_tarp(b: Object, c: Vector2, col: Color, k: int) -> void:
	var ang := (float(k % 5) - 2.0) * 0.05
	var half := Vector2(40.0 + float(k % 3) * 6.0, 62.0)
	var q := _quad(c, half, ang)
	b.polygon(_quad(c + LIGHT * 10.0, half, ang), SHADOW)
	b.polygon(q, col)
	# the ridge down the middle of the stack, and the sides falling away
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	var r0 := c - ay * half.y
	var r1 := c + ay * half.y
	b.polygon(PackedVector2Array([q[0], r0, r1, q[3]]), col.lightened(0.10))
	b.polygon(PackedVector2Array([r0, q[1], q[2], r1]), col.darkened(0.14))
	b.line(r0, r1, col.lightened(0.28), 2.0)
	# creases: dark folds fanning from the corners, a lighter edge beside each
	for i in range(4):
		var corner: Vector2 = q[i]
		var to := c + ay * (half.y * (0.4 - 0.27 * float(i))) + ax * (half.x * 0.25 * (1.0 if i % 2 == 0 else -1.0))
		var mid := corner.lerp(to, 0.55)
		b.polygon(PackedVector2Array([corner, mid + ay * 4.0, mid - ay * 4.0]), col.darkened(0.30))
		b.line(corner + ax * 3.0, mid + ax * 3.0, col.lightened(0.22), 1.5)
	# a slack fold where the sheet bunches at the foot
	b.line(q[3].lerp(q[2], 0.2), q[3].lerp(q[2], 0.7) - ay * 6.0, col.darkened(0.35), 2.0)
	# rope across, and the tyres weighing the corners
	b.line(q[0].lerp(q[3], 0.35), q[1].lerp(q[2], 0.35), Color(0.84, 0.78, 0.60), 1.5)
	b.line(q[0].lerp(q[3], 0.7), q[1].lerp(q[2], 0.7), Color(0.84, 0.78, 0.60), 1.5)
	for i in [0, 2]:
		var tp: Vector2 = q[i].lerp(c, 0.12)
		b.circle(tp, 9.0, Color(0.12, 0.12, 0.13))
		b.circle(tp, 4.0, col.darkened(0.2))


# A pallet: five slats with gaps between, and, loaded, concrete blocks on it
# under a sheen of shrink-wrap.
static func draw_pallet(b: Object, c: Vector2, ang: float, loaded: bool) -> void:
	var half := Vector2(24.0, 20.0)
	b.polygon(_quad(c + LIGHT * (8.0 if loaded else 3.0), half, ang), SHADOW)
	b.polygon(_quad(c, half, ang), Color(0.36, 0.28, 0.18))
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	for s in range(5):
		var sc := c + ay * (-16.0 + float(s) * 8.0)
		b.polygon(_quad(sc, Vector2(24.0, 2.8), ang), Color(0.72, 0.60, 0.42))
	if loaded:
		for bx in range(3):
			for by in range(2):
				var bc := c + ax * (-14.0 + float(bx) * 14.0) + ay * (-8.0 + float(by) * 16.0)
				b.polygon(_quad(bc, Vector2(6.5, 7.0), ang), Color(0.64, 0.63, 0.60))
				b.circle(bc, 2.0, Color(0.48, 0.47, 0.45))
		b.line(c - ax * 20.0 - ay * 16.0, c + ax * 20.0 - ay * 4.0, Color(1, 1, 1, 0.22), 3.0)


# A heap of dug earth: layered, lighter where the light hits its top, clods
# rolled off round the foot, and a shovel stuck in it.
static func draw_spoil(b: Object, c: Vector2, rad: float, k: int) -> void:
	b.circle(c + LIGHT * rad * 0.3, rad * 1.02, SHADOW)
	for layer in range(4):
		var f := float(layer) / 3.0
		var pts := PackedVector2Array()
		var lr := rad * (1.0 - f * 0.62)
		var lc := c - LIGHT * rad * 0.18 * f
		for i in range(9):
			var a := TAU * float(i) / 9.0
			var rr := lr * (0.82 + _h(float(k + layer), float(i)) * 0.3)
			pts.append(lc + Vector2(cos(a) * rr, sin(a) * rr * 0.86))
		b.polygon(pts, EARTH.darkened(0.12).lerp(EARTH.lightened(0.16), f))
	for i in range(7):
		var a := TAU * _h(float(k), float(i) + 4.0)
		b.circle(c + Vector2.from_angle(a) * rad * (1.0 + _h(float(i), float(k)) * 0.2), 2.5 + float(i % 3), EARTH.darkened(0.2))
	if k % 2 == 0:
		var sp := c - LIGHT * rad * 0.2
		b.line(sp, sp + Vector2(rad * 0.6, -rad * 0.5), Color(0.52, 0.38, 0.22), 3.0)
		b.rect(Rect2(sp.x - 5.0, sp.y - 3.0, 10.0, 8.0), Color(0.36, 0.38, 0.40))


# A bundle of rebar lying on bearers: ribbed rust-brown bars, tie wire round
# them, and orange safety caps on the ends.
static func draw_rebar(b: Object, c: Vector2, ang: float, length: float) -> void:
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	for e: float in [-0.35, 0.35]:
		b.polygon(_quad(c + ax * length * e, Vector2(4.0, 16.0), ang), Color(0.50, 0.40, 0.28))
	for i in range(7):
		var o := ay * (-9.0 + float(i) * 3.0)
		var lo := c - ax * length * 0.5 + o + ax * float(i % 3) * 3.0
		var hi := c + ax * length * 0.5 + o - ax * float((i + 1) % 3) * 4.0
		b.line(lo + LIGHT * 2.0, hi + LIGHT * 2.0, SHADOW, 2.0)
		b.line(lo, hi, RUST.lightened(0.06 * float(i % 3)), 2.0)
		if i % 2 == 0:
			b.circle(hi, 2.6, Color(0.96, 0.46, 0.10))
	for e: float in [-0.2, 0.2]:
		var tp := c + ax * length * e
		b.line(tp - ay * 11.0, tp + ay * 10.0, Color(0.30, 0.30, 0.32), 1.5)


# The footway's own dirt: the digger's track marks, the survey crew's spray
# lines, gravel, and bits lying about. All flat.
static func draw_footway(m: Node2D, b: Object, vt: float, vb: float) -> void:
	# the digger came in from the side street and backed into its spot:
	# two bands of cleats curving up to where it stands
	var dg: Vector2 = m.vans[0] if not (m.vans as Array).is_empty() else Vector2(900.0, -1400.0)
	if dg.y > vt - 400.0 and dg.y - 300.0 < vb + 200.0:
		for t in range(2):
			var lat := -20.0 + float(t) * 40.0
			var prev := Vector2.INF
			for s in range(15):
				var f := float(s) / 14.0
				var p := dg + Vector2(lat - 120.0 * f * f, 70.0 + f * 260.0)
				if prev.x < INF:
					b.line(prev, p, Color(0.30, 0.24, 0.16, 0.16), 14.0)
					var n := (p - prev).normalized().orthogonal()
					b.line(p - n * 7.0, p + n * 7.0, Color(0.28, 0.22, 0.14, 0.22), 2.0)
				prev = p
	for sp: Array in SPRAY:
		var a := _at(m, (sp[0] as Vector2).x, (sp[0] as Vector2).y)
		var z := _at(m, (sp[1] as Vector2).x, (sp[1] as Vector2).y)
		if maxf(a.y, z.y) < vt - 40.0 or minf(a.y, z.y) > vb + 40.0:
			continue
		var col: Color = SPRAY_COLS[int(sp[2])]
		var n := int(a.distance_to(z) / 26.0)
		for i in range(n):
			b.line(a.lerp(z, float(i) / float(n)), a.lerp(z, (float(i) + 0.6) / float(n)), col, 3.0)
		# an arrow at the far end, the way the run continues
		var d := (z - a).normalized()
		b.line(z, z - d.rotated(0.5) * 12.0, col, 3.0)
		b.line(z, z - d.rotated(-0.5) * 12.0, col, 3.0)
	for it: Array in LITTER:
		var p := _at(m, float(it[0]), float(it[1]))
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		var ang := float(it[3])
		match String(it[2]):
			"offcuts":
				for i in range(3):
					var o := Vector2.from_angle(ang + float(i) * 0.5) * 18.0
					b.line(p - o + LIGHT * 1.5, p + o + LIGHT * 1.5, SHADOW, 2.0)
					b.line(p - o, p + o, RUST, 2.0)
			"bag":
				b.polygon(_quad(p, Vector2(13.0, 8.0), ang), Color(0.84, 0.80, 0.70))
				b.polygon(_quad(p, Vector2(13.0, 3.0), ang), Color(0.70, 0.30, 0.20))
				b.circle(p + Vector2.from_angle(ang) * 16.0, 5.0, Color(0.70, 0.70, 0.68, 0.6))
			"plank":
				b.polygon(_quad(p + LIGHT * 2.0, Vector2(40.0, 5.0), ang), SHADOW)
				b.polygon(_quad(p, Vector2(40.0, 5.0), ang), Color(0.70, 0.56, 0.36))
				b.line(p - Vector2.from_angle(ang) * 30.0, p + Vector2.from_angle(ang) * 26.0, Color(0.56, 0.44, 0.28), 1.0)
			"gravel":
				for i in range(16):
					var gp := p + Vector2(_h(p.y, float(i)) - 0.5, _h(float(i), p.y) - 0.5) * 60.0
					b.circle(gp, 1.6 + float(i % 3) * 0.7, Color(0.62, 0.60, 0.56) if i % 2 == 0 else Color(0.44, 0.42, 0.40))


# The two pours, each at its own stage, so they never read as one slab twice.
# The first is just placed: timber shuttering on stakes, the concrete dark
# and glossy, fanned trowel marks, and the bull float left lying on it. The
# second has been screeded: steel forms pinned down, paler, broomed across,
# starter bars along its edge, the screed bar across one end and the
# barrow it came in by.
static func draw_pour(b: Object, cz: Vector2, size: Vector2, stage: int) -> void:
	var r := Rect2(cz - size * 0.5, size)
	if stage == 0:
		b.rect(r.grow(7.0), Color(0.56, 0.42, 0.26))
		b.rect(r.grow(3.0), Color(0.44, 0.32, 0.20))
		# the stakes holding the boards
		var sx := r.position.x + 10.0
		while sx < r.end.x - 4.0:
			b.rect(Rect2(sx - 3.0, r.position.y - 13.0, 6.0, 6.0), Color(0.36, 0.26, 0.16))
			b.rect(Rect2(sx - 3.0, r.end.y + 7.0, 6.0, 6.0), Color(0.36, 0.26, 0.16))
			sx += 38.0
		b.rect(r, Color(0.50, 0.51, 0.50))
		# wet sheen, then the arcs the trowel left
		b.polygon(PackedVector2Array([r.position + Vector2(12, 8), r.position + Vector2(r.size.x * 0.6, 8),
			r.position + Vector2(r.size.x * 0.3, r.size.y * 0.4), r.position + Vector2(8, r.size.y * 0.3)]), Color(1, 1, 1, 0.07))
		for row in range(4):
			for col in range(3):
				var ctr := r.position + Vector2(r.size.x * (0.2 + 0.3 * float(col)), r.size.y * (0.16 + 0.23 * float(row)))
				var prev := Vector2.INF
				for s in range(7):
					var a := PI * (1.15 + 0.7 * float(s) / 6.0)
					var p := ctr + Vector2.from_angle(a) * 20.0 + Vector2(0, 14)
					if prev.x < INF:
						b.line(prev, p, Color(0.62, 0.63, 0.62, 0.8), 1.5)
					prev = p
		# the bull float, left on the slab, its pole out over the boards
		var fp := r.position + Vector2(r.size.x * 0.55, r.size.y * 0.7)
		b.polygon(_quad(fp + LIGHT * 3.0, Vector2(30.0, 6.0), 0.2), SHADOW)
		b.polygon(_quad(fp, Vector2(30.0, 6.0), 0.2), Color(0.70, 0.72, 0.74))
		b.line(fp, fp + Vector2.from_angle(0.2 - 0.9) * 120.0, Color(0.80, 0.80, 0.78), 3.0)
	else:
		# steel forms with their pins
		b.rect(r.grow(6.0), Color(0.40, 0.42, 0.44))
		b.rect(r.grow(2.0), Color(0.28, 0.30, 0.32))
		var py := r.position.y + 14.0
		while py < r.end.y - 4.0:
			b.circle(Vector2(r.position.x - 10.0, py), 2.5, Color(0.70, 0.40, 0.18))
			b.circle(Vector2(r.end.x + 10.0, py), 2.5, Color(0.70, 0.40, 0.18))
			py += 44.0
		b.rect(r, Color(0.66, 0.65, 0.61))
		# broomed across, fine and close
		var by := r.position.y + 5.0
		var i := 0
		while by < r.end.y - 3.0:
			b.line(Vector2(r.position.x + 3.0, by), Vector2(r.end.x - 3.0, by + 1.5),
				Color(0.56, 0.55, 0.52, 0.55) if i % 2 == 0 else Color(0.74, 0.73, 0.70, 0.5), 1.0)
			by += 5.0
			i += 1
		# a darker band still being worked at the far end, wetter
		b.rect(Rect2(r.position.x, r.position.y, r.size.x, 34.0), Color(0.50, 0.50, 0.48, 0.8))
		# starter bars standing out of the west edge, capped
		var bx := r.position.y + 24.0
		while bx < r.end.y - 10.0:
			b.line(Vector2(r.position.x + 2.0, bx), Vector2(r.position.x + 12.0, bx), RUST, 2.5)
			b.circle(Vector2(r.position.x + 12.0, bx), 2.4, Color(0.96, 0.46, 0.10))
			bx += 32.0
		# the screed bar across the wet end
		b.polygon(_quad(Vector2(r.get_center().x, r.position.y + 30.0) + LIGHT * 2.0, Vector2(r.size.x * 0.5 + 14.0, 3.5), 0.0), SHADOW)
		b.polygon(_quad(Vector2(r.get_center().x, r.position.y + 30.0), Vector2(r.size.x * 0.5 + 14.0, 3.5), 0.0), Color(0.78, 0.80, 0.82))
		# the barrow it came in by, standing off the east side
		draw_barrow(b, Vector2(r.end.x + 46.0, r.end.y - 50.0), -0.4)


static func draw_barrow(b: Object, c: Vector2, ang: float) -> void:
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	b.polygon(_quad(c + LIGHT * 5.0, Vector2(18.0, 13.0), ang), SHADOW)
	# handles back from the pan, the wheel in front
	b.line(c - ax * 10.0 - ay * 8.0, c - ax * 34.0 - ay * 9.0, Color(0.30, 0.30, 0.32), 3.0)
	b.line(c - ax * 10.0 + ay * 8.0, c - ax * 34.0 + ay * 9.0, Color(0.30, 0.30, 0.32), 3.0)
	b.polygon(_quad(c + ax * 22.0, Vector2(5.0, 3.0), ang), Color(0.12, 0.12, 0.13))
	b.polygon(_quad(c, Vector2(18.0, 13.0), ang), Color(0.20, 0.50, 0.36))
	b.polygon(_quad(c, Vector2(13.0, 9.0), ang), Color(0.48, 0.48, 0.46))
	b.circle(c + ax * 3.0, 4.0, Color(0.56, 0.56, 0.54))


# LES OBRES: the pours in their formwork with tape round them, the fresh
# zebra, the trench with its plank and pipe, all drawn over the paving.
static func _draw_works(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# the footway's dirt: track marks, spray lines, bits lying about
	draw_footway(m, b, vt, vb)
	for zi in range(m.cement_zones.size()):
		var cz: Rect2 = m.cement_zones[zi]
		if cz.end.y < vt - 40.0 or cz.position.y > vb + 40.0:
			continue
		# each pour at its own stage (world/obres.gd)
		draw_pour(b, cz.get_center(), cz.size, zi % 2)
		# tape round the cones at the corners, red and white
		var corners: Array[Vector2] = []
		for c: Vector2 in [cz.position, Vector2(cz.end.x, cz.position.y), cz.end, Vector2(cz.position.x, cz.end.y)]:
			corners.append(c + (c - cz.get_center()).normalized() * 16.0)
		for k in range(4):
			var a: Vector2 = corners[k]
			var c2: Vector2 = corners[(k + 1) % 4]
			var n := int(a.distance_to(c2) / 12.0)
			for j in range(n):
				var p0 := a.lerp(c2, float(j) / float(n))
				var p1 := a.lerp(c2, float(j + 1) / float(n))
				b.line(p0, p1, Color(0.90, 0.20, 0.18) if j % 2 == 0 else Color(0.96, 0.96, 0.94), 2.0)
	# the zebra, freshly painted: wet white bars with a sheen
	var zy: float = LevelBuild.OBRES_ZEBRA_Y
	if zy > vt - 80.0 and zy < vb + 80.0:
		var ze: Vector2 = m.walk_edges(zy)
		var zx := ze.x + 36.0
		while zx < ze.y - 36.0:
			b.rect(Rect2(zx, zy + 4.0, 26.0, LevelBuild.OBRES_ZEBRA_H - 8.0), Color(0.96, 0.95, 0.90))
			b.rect(Rect2(zx + 3.0, zy + 6.0, 5.0, LevelBuild.OBRES_ZEBRA_H - 12.0), Color(1, 1, 1, 0.9))
			zx += 46.0
	# the trench: dug earth at the lips, dark inside, utility conduits,
	# timber walers and hydraulic trench shoring struts, red/white safety barrier boards,
	# amber warning beacons, steel approach transition plates, and the heavy timber bridge
	# flanked by galvanized scaffolding pipe handrails (grindable!)
	var ty: float = LevelBuild.OBRES_TRENCH_Y
	var th: float = LevelBuild.OBRES_TRENCH_H
	if ty > vt - 100.0 and ty < vb + 100.0:
		var te: Vector2 = m.walk_edges(ty)
		var pc := (te.x + te.y) * 0.5
		var half_w := LevelBuild.OBRES_PLANK * 0.5

		# 1. Open excavation trenches on either side of the bridge
		for c: Rect2 in m.cellars:
			b.rect(c.grow(7.0), Color(0.48, 0.38, 0.26))
			b.rect(c, Color(0.12, 0.10, 0.09))
			b.rect(Rect2(c.position.x, c.position.y, c.size.x, 6.0), Color(0.50, 0.38, 0.24))
			b.rect(Rect2(c.position.x, c.end.y - 6.0, c.size.x, 6.0), Color(0.38, 0.28, 0.18))
			b.rect(Rect2(c.position.x, c.position.y + th * 0.5 - 6.0, c.size.x, 9.0), Color(0.74, 0.42, 0.18))
			b.rect(Rect2(c.position.x, c.position.y + th * 0.5 - 6.0, c.size.x, 2.5), Color(0.86, 0.56, 0.28))
			b.rect(Rect2(c.position.x, c.position.y + th * 0.5 + 4.0, c.size.x, 5.0), Color(0.20, 0.20, 0.22))
			var strut_x := c.position.x + 35.0
			while strut_x < c.end.x - 20.0:
				b.line(Vector2(strut_x, c.position.y + 2.0), Vector2(strut_x, c.end.y - 2.0), Color(0.88, 0.68, 0.16), 4.5)
				b.rect(Rect2(strut_x - 4.0, c.position.y + th * 0.5 - 3.0, 8.0, 6.0), Color(0.25, 0.25, 0.27))
				b.circle(Vector2(strut_x, c.position.y + 3.0), 3.0, Color(0.35, 0.35, 0.38))
				b.circle(Vector2(strut_x, c.end.y - 3.0), 3.0, Color(0.35, 0.35, 0.38))
				strut_x += 76.0
			for side_edge: float in [c.position.y - 4.0, c.end.y]:
				b.rect(Rect2(c.position.x + 2.0, side_edge, c.size.x - 4.0, 4.0), Color(0.92, 0.92, 0.90))
				var stripe_x := c.position.x + 6.0
				while stripe_x < c.end.x - 8.0:
					b.line(Vector2(stripe_x, side_edge), Vector2(stripe_x + 6.0, side_edge + 4.0), Color(0.86, 0.16, 0.16), 2.5)
					stripe_x += 16.0

		# 2. Heavy timber construction bridge
		var plank := Rect2(pc - half_w - 6.0, ty - 12.0, LevelBuild.OBRES_PLANK + 12.0, th + 24.0)
		b.rect(Rect2(plank.position + LIGHT * 6.0, plank.size), Color(0, 0, 0, 0.24))
		b.rect(plank, Color(0.62, 0.48, 0.28))
		var n_planks := 4
		for k in range(n_planks):
			var x0 := plank.position.x + float(k) * (plank.size.x / float(n_planks))
			var pw := plank.size.x / float(n_planks) - 2.0
			b.rect(Rect2(x0 + 1.0, plank.position.y, pw, plank.size.y), Color(0.66, 0.51, 0.31))
			b.line(Vector2(x0 + pw * 0.5, plank.position.y), Vector2(x0 + pw * 0.5, plank.end.y), Color(0.54, 0.41, 0.24), 1.5)
			b.circle(Vector2(x0 + pw * 0.5, plank.position.y + 4.0), 1.5, Color(0.30, 0.30, 0.32))
			b.circle(Vector2(x0 + pw * 0.5, plank.end.y - 4.0), 1.5, Color(0.30, 0.30, 0.32))

		# checkered steel transition plates at north and south approaches
		for ramp_y: float in [plank.position.y - 3.0, plank.end.y - 3.0]:
			var rr := Rect2(plank.position.x + 2.0, ramp_y, plank.size.x - 4.0, 6.0)
			b.rect(rr, Color(0.70, 0.72, 0.74))
			b.line(Vector2(rr.position.x, rr.position.y), Vector2(rr.end.x, rr.position.y), Color(0.85, 0.86, 0.88), 1.5)
			for bx in range(6):
				b.circle(Vector2(rr.position.x + 8.0 + float(bx) * (rr.size.x - 16.0) / 5.0, rr.position.y + 3.0), 1.2, Color(0.35, 0.35, 0.38))

		# 3. Flashing amber hazard beacon lamps on barricade posts flanking the crossing
		for lx: float in [pc - half_w - 18.0, pc + half_w + 18.0]:
			for ly: float in [ty - 8.0, ty + th + 8.0]:
				b.rect(Rect2(lx - 5.0, ly - 5.0, 10.0, 10.0), Color(0.86, 0.70, 0.14))
				b.circle(Vector2(lx, ly), 16.0, Color(1.0, 0.75, 0.18, 0.10))
				b.circle(Vector2(lx, ly), 5.5, Color(1.0, 0.78, 0.18))
				b.circle(Vector2(lx, ly), 2.5, Color(1.0, 0.96, 0.65))

		# 4. Galvanized scaffolding pipe handrails along both edges (grindable!)
		for side: float in [-1.0, 1.0]:
			var rx: float = pc + side * (half_w + 2.0)
			var y0 := ty - 18.0
			var y1 := ty + th + 18.0
			b.line(Vector2(rx, y0) + LIGHT * 5.0, Vector2(rx, y1) + LIGHT * 5.0, Color(0, 0, 0, 0.22), 4.0)
			for py: float in [y0 + 2.0, (y0 + y1) * 0.5, y1 - 2.0]:
				b.circle(Vector2(rx, py) + LIGHT * 3.0, 4.0, Color(0, 0, 0, 0.20))
				b.circle(Vector2(rx, py), 4.0, Color(0.48, 0.50, 0.52))
				b.circle(Vector2(rx, py), 2.5, Color(0.76, 0.78, 0.80))
			b.line(Vector2(rx, y0), Vector2(rx, y1), Color(0.78, 0.80, 0.82), 3.5)
			b.line(Vector2(rx - side * 0.5, y0), Vector2(rx - side * 0.5, y1), Color(0.92, 0.94, 0.96), 1.5)
			b.circle(Vector2(rx, y0), 2.8, Color(0.96, 0.52, 0.12))
			b.circle(Vector2(rx, y1), 2.8, Color(0.96, 0.52, 0.12))
			var mid_rx: float = rx - side * 3.0
			b.line(Vector2(mid_rx, y0 + 6.0), Vector2(mid_rx, y1 - 6.0), Color(0.66, 0.68, 0.70), 2.0)
	b.flush(m._wc)


# The parked digger, from above: two rubber tracks on their rollers, the
# yellow house on top with its engine deck, exhaust and striped counterweight
# at the back, the cab with its glass roof on the left, and the boom and dipper
# folded forward on their rams, the bucket's teeth resting on a heap of spoil.
# Same footprint as a van; one batch, one draw call.
static func _draw_digger(m: Node2D, v: Vector2) -> void:
	var b := ShapeBatch.new()
	var yel := Color(0.93, 0.70, 0.12)
	var yel_d := Color(0.72, 0.52, 0.08)
	var yel_l := Color(1.0, 0.84, 0.36)
	var steel := Color(0.70, 0.72, 0.74)
	b.polygon(m.round_rect_pts(Rect2(v.x - 36.0 + 10.0, v.y - 50.0 + 14.0, 72.0, 100.0), 10.0),
		Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
	# the tracks: rubber pads over a sprocket and an idler at each end
	for tx: float in [-36.0, 20.0]:
		var tr := Rect2(v.x + tx, v.y - 50.0, 16.0, 100.0)
		b.polygon(m.round_rect_pts(tr, 7.0), Color(0.13, 0.13, 0.14))
		b.polygon(m.round_rect_pts(tr.grow(-3.0), 5.0), Color(0.22, 0.22, 0.24))
		var ty := v.y - 44.0
		while ty < v.y + 44.0:
			b.line(Vector2(tr.position.x + 2.0, ty), Vector2(tr.end.x - 2.0, ty), Color(0.10, 0.10, 0.11), 2.4)
			ty += 7.0
		for ey: float in [-41.0, 41.0]:
			b.circle(Vector2(tr.get_center().x, v.y + ey), 4.0, Color(0.34, 0.34, 0.36))
	# the house: rounded, its shaded rim, the lit upper-left of the deck
	var house := Rect2(v.x - 28.0, v.y - 26.0, 56.0, 64.0)
	b.polygon(m.round_rect_pts(house.grow(1.5), 12.0), yel_d)
	b.polygon(m.round_rect_pts(house, 11.0), yel)
	b.polygon(m.round_rect_pts(Rect2(house.position + Vector2(4, 4), Vector2(30, 22)), 8.0), yel_l)
	# the counterweight at the back, hazard-striped
	var cw := Rect2(v.x - 26.0, v.y + 30.0, 52.0, 12.0)
	b.polygon(m.round_rect_pts(cw, 5.0), Color(0.16, 0.16, 0.17))
	for k in range(6):
		var sx := cw.position.x + 4.0 + float(k) * 8.0
		b.line(Vector2(sx, cw.end.y - 2.0), Vector2(sx + 6.0, cw.position.y + 2.0), yel, 3.0)
	# the engine deck: louvres, and the exhaust stack with soot round it
	for k in range(4):
		var gy := v.y + 12.0 + float(k) * 4.0
		b.line(Vector2(v.x + 4.0, gy), Vector2(v.x + 22.0, gy), yel_d, 1.6)
	b.circle(Vector2(v.x + 18.0, v.y + 4.0), 4.0, Color(0.20, 0.20, 0.20, 0.5))
	b.circle(Vector2(v.x + 18.0, v.y + 4.0), 2.6, Color(0.16, 0.16, 0.17))
	# the cab on the left: a dark frame, a glass roof with the sky in it
	var cab := Rect2(v.x - 26.0, v.y - 22.0, 22.0, 30.0)
	b.polygon(m.round_rect_pts(cab, 4.0), Color(0.18, 0.18, 0.20))
	b.polygon(m.round_rect_pts(cab.grow(-2.5), 3.0), Color(0.36, 0.48, 0.56))
	b.polygon(PackedVector2Array([cab.position + Vector2(4, 4), cab.position + Vector2(14, 4),
		cab.position + Vector2(5, 15)]), Color(0.72, 0.84, 0.90, 0.7))
	b.line(Vector2(cab.position.x + 2.5, cab.get_center().y + 2.0), Vector2(cab.end.x - 2.5, cab.get_center().y + 2.0),
		Color(0.18, 0.18, 0.20), 1.6)
	# the boom from its foot beside the cab, the dipper folded back down
	var foot := v + Vector2(8.0, -22.0)
	var knee := v + Vector2(10.0, -66.0)
	var wrist := v + Vector2(2.0, -80.0)
	b.line(foot + LIGHT * 4.0, knee + LIGHT * 4.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25), 12.0)
	b.polygon(PackedVector2Array([foot + Vector2(-7, 0), foot + Vector2(7, 0), knee + Vector2(4, 0), knee + Vector2(-4, 0)]), yel_d)
	b.polygon(PackedVector2Array([foot + Vector2(-5, 0), foot + Vector2(3, 0), knee + Vector2(1, 0), knee + Vector2(-3, 0)]), yel)
	# the ram along the boom: a steel rod out of its yellow cylinder
	b.line(foot + Vector2(-1, -4), foot.lerp(knee, 0.55) + Vector2(-1, 0), yel_d, 4.0)
	b.line(foot.lerp(knee, 0.55) + Vector2(-1, 0), knee + Vector2(-1, 6), steel, 2.0)
	b.line(knee, wrist, yel_d, 8.0)
	b.line(knee, wrist, yel, 5.0)
	b.circle(knee, 4.0, Color(0.28, 0.28, 0.30))
	b.circle(knee, 1.6, steel)
	# the spoil heap, and the bucket on it, teeth down
	# (heaped on the road side: the kerb side has a hydrant by it)
	b.circle(wrist + Vector2(10, -6), 12.0, Color(0.46, 0.36, 0.25))
	b.circle(wrist + Vector2(0, -10), 9.0, Color(0.52, 0.41, 0.28))
	b.circle(wrist + Vector2(16, -12), 6.0, Color(0.58, 0.47, 0.33))
	var bk := Rect2(wrist.x - 13.0, wrist.y - 13.0, 26.0, 12.0)
	b.polygon(m.round_rect_pts(bk, 3.0), Color(0.26, 0.26, 0.28))
	b.polygon(m.round_rect_pts(Rect2(bk.position + Vector2(2, 2), bk.size - Vector2(4, 6)), 2.0), Color(0.40, 0.40, 0.42))
	for k in range(5):
		var tx2 := bk.position.x + 3.0 + float(k) * 5.0
		b.polygon(PackedVector2Array([Vector2(tx2 - 1.6, bk.position.y), Vector2(tx2 + 1.6, bk.position.y),
			Vector2(tx2, bk.position.y - 4.0)]), steel)
	b.flush(m._wc)


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------
# (a function here named for a hook IS that hook: the footway's dirt is
# draw_footway, not draw_ground, which would replace the ground pass)

# the works over the paving, after the ground and its dressing
static func draw_top(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_works(m, vt, vb)


# the digger, where other walks park a van
static func draw_van(m: Node2D, _wc: Object, v: Vector2) -> void:
	_draw_digger(m, v)


# a worker in hi-vis and a hard hat, leaning on a shovel
static func draw_performer(m: Node2D, wc: Object, pf: Vector2, _idx: int) -> void:
	m.contact_shadow(wc, pf, 12.0, 5.0, 0.2)
	wc.draw_circle(pf, 12.0, Color(0.96, 0.62, 0.12))
	wc.draw_line(pf + Vector2(-10, -2), pf + Vector2(10, -2), Color(0.85, 0.88, 0.80), 3.0)
	wc.draw_circle(pf + Vector2(0, -4), 7.5, Color(0.98, 0.86, 0.20))
	wc.draw_line(pf + Vector2(10, 2), pf + Vector2(22, 20), Color(0.40, 0.30, 0.20), 2.5)
	wc.draw_rect(Rect2(pf.x + 19.0, pf.y + 18.0, 8.0, 8.0), Color(0.45, 0.46, 0.48))


# a strapped bundle of orange utility conduits and timber trench shoring
static func draw_log_prop(_m: Node2D, c: Object, p: Vector2) -> void:
	c.draw_rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 9.0), Color(0.58, 0.44, 0.26))
	c.draw_rect(Rect2(p.x - 30.0, p.y - 1.0, 60.0, 5.0), Color(0.88, 0.42, 0.14))
	c.draw_rect(Rect2(p.x - 30.0, p.y + 4.0, 60.0, 5.0), Color(0.76, 0.34, 0.10))
	for bx: float in [-16.0, 16.0]:
		c.draw_rect(Rect2(p.x + bx - 1.5, p.y - 9.5, 3.0, 19.0), Color(0.22, 0.24, 0.26))
