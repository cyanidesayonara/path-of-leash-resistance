class_name Eixample
extends RefCounted

# WALK: L'EIXAMPLE, the grid of cut corners round the unfinished basilica.
#
# One street of Cerdà's grid, walked block by block towards the basilica: the
# street is one of the new green axes, paved wall to wall, with panot flower
# tiles along the facades, a granite middle where the road was, plane trees
# down both sides and planted islands with benches. Every block ends in a
# crossing where all four corners are cut off at forty-five degrees (the
# chamfers, els xamfrans), so the street opens into an octagon at each
# cross street: that is the walk's shape, a straight street that breathes out
# four times. The cross streets carry their bikes, the chamfers their lamps,
# a café terrace and the recycling containers. The last block runs past
# Plaça de Gaudí's pond on the left and the basilica on the right, towers,
# cranes and all; the gate opens onto the garden inside the next block.
#
# Signature line: wrap the chamfer lamps as the street opens, thread the
# planted islands, cut across the octagons on the diagonal.
# Live event: the tour group following its guide's umbrella across the last
# cross street (systems/eixample_tour.gd).

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EixampleTour := preload("res://systems/eixample_tour.gd")
const NightFronts := preload("res://world/night_fronts.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)

# --- the street's shape --------------------------------------------------------
const CX := 640.0
const HALF := 250.0                 # facade to facade along a block
const XHALF := 420.0                # across the octagon, chamfer to chamfer
const STREET_H := 90.0              # half the cross street's width
const RAMP := 210.0                 # the chamfer's run along the walk
const XINGS: Array[float] = [-560.0, -1800.0, -3040.0, -4280.0]
# the cross streets the bikes ride (main.lane_ys); the last is the tour's
const BIKE_XINGS: Array[float] = [-1800.0, -3040.0]
const SIDEWALK := 104.0             # panot from the facade to the tree line

# --- the things on it ------------------------------------------------------------
const POND := Rect2(418.0, -4930.0, 124.0, 250.0)
const PRIZE := Vector2(892.0, -1962.0)
const PRIZE_TEXT := "snatch the croissant off the terrace table"
# planted islands down the middle, as (centre y, length)
const ISLANDS: Array[Vector2] = [
	Vector2(-1050.0, 230.0), Vector2(-1420.0, 180.0),
	Vector2(-2290.0, 200.0), Vector2(-2660.0, 200.0),
	Vector2(-3500.0, 180.0), Vector2(-3840.0, 200.0),
]
const ISLAND_W := 74.0
# a corner counts as marked when its lamp is (marks keep the pole's position)
const CORNER_R := 40.0

# --- colours -----------------------------------------------------------------------
const PANOT := Color(0.71, 0.68, 0.63)
const PANOT_JOINT := Color(0.60, 0.57, 0.52)
const PANOT_FLOWER := Color(0.64, 0.61, 0.56)
const GRANITE := Color(0.66, 0.65, 0.62)
const GRANITE_LIT := Color(0.71, 0.70, 0.67)
const GRANITE_JOINT := Color(0.56, 0.55, 0.52)
const RIGOLA := Color(0.50, 0.49, 0.47)
const ASPHALT := Color(0.27, 0.27, 0.29)
const ASPHALT_LIT := Color(0.31, 0.31, 0.33)
const KERB := Color(0.58, 0.57, 0.54)
const ZEBRA := Color(0.90, 0.89, 0.84, 0.92)
const SAULO := Color(0.78, 0.70, 0.55)
const HEDGE := Color(0.24, 0.40, 0.24)
const HEDGE_LIT := Color(0.32, 0.50, 0.30)
const BENCH_WOOD := Color(0.58, 0.42, 0.26)
const IRON := Color(0.16, 0.17, 0.18)

const ROOF_TONES: Array[Color] = [
	Color(0.72, 0.52, 0.40), Color(0.80, 0.66, 0.50), Color(0.66, 0.46, 0.38),
	Color(0.76, 0.60, 0.48), Color(0.70, 0.58, 0.50), Color(0.82, 0.70, 0.56),
]
const TERRAT := Color(0.74, 0.44, 0.32)            # a roof terrace's red tiles
const PARAPET := Color(0.88, 0.84, 0.76)
const CORNICE_SHADE := Color(0.10, 0.08, 0.07, 0.30)
const COURTYARD := Color(0.36, 0.48, 0.32)
const STAIR_HOUSE := Color(0.84, 0.80, 0.72)
const TANK := Color(0.82, 0.82, 0.80)
const BALCONY := Color(0.20, 0.19, 0.18)
const TURRET := Color(0.46, 0.56, 0.60)
const TURRET_LIT := Color(0.58, 0.68, 0.70)
const TRENCADIS: Array[Color] = [
	Color(0.20, 0.52, 0.66), Color(0.92, 0.76, 0.24), Color(0.84, 0.32, 0.26),
	Color(0.36, 0.64, 0.40), Color(0.94, 0.92, 0.86),
]
const CONTAINERS: Array[Color] = [
	Color(0.20, 0.42, 0.24), Color(0.92, 0.78, 0.18), Color(0.20, 0.36, 0.66),
	Color(0.48, 0.32, 0.22), Color(0.40, 0.42, 0.44),
]
const STONE := Color(0.80, 0.74, 0.62)
const STONE_DARK := Color(0.62, 0.56, 0.46)
const STONE_LIT := Color(0.88, 0.83, 0.72)
const CRANE := Color(0.92, 0.70, 0.16)
const WATER := Color(0.26, 0.46, 0.52)
const WATER_LIT := Color(0.40, 0.60, 0.64)
const LAMP_IRON := Color(0.14, 0.18, 0.16)


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


# --- shape -------------------------------------------------------------------------

static func edge_nodes(m: Node2D) -> Array:
	var nodes: Array = [{"y": m.START_Y, "cx": CX, "half": HALF}]
	for yi: float in XINGS:
		nodes.append({"y": yi + STREET_H + RAMP, "cx": CX, "half": HALF})
		nodes.append({"y": yi + STREET_H, "cx": CX, "half": XHALF})
		nodes.append({"y": yi - STREET_H, "cx": CX, "half": XHALF})
		nodes.append({"y": yi - STREET_H - RAMP, "cx": CX, "half": HALF})
	nodes.append({"y": m.GATE_Y, "cx": CX, "half": HALF})
	return nodes


# the street's half width at y, from the nodes above (no main needed)
static func half_at(y: float) -> float:
	for yi: float in XINGS:
		var d := absf(y - yi)
		if d <= STREET_H:
			return XHALF
		if d < STREET_H + RAMP:
			return lerpf(XHALF, HALF, (d - STREET_H) / RAMP)
	return HALF


# the middle of each chamfer, a little inside the street: where its lamp is
static func chamfer_spots(inset: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var ny := RAMP / Vector2(XHALF - HALF, RAMP).length()
	var nx := (XHALF - HALF) / Vector2(XHALF - HALF, RAMP).length()
	for yi: float in XINGS:
		for sy: float in [-1.0, 1.0]:
			var y := yi + sy * (STREET_H + RAMP * 0.5)
			var hx := (XHALF + HALF) * 0.5
			for sx: float in [-1.0, 1.0]:
				# step in along the chamfer's inward normal
				out.append(Vector2(CX + sx * (hx - inset * ny), y - sy * inset * nx))
	return out


static func in_cross_street(y: float) -> bool:
	for yi: float in XINGS:
		if absf(y - yi) < STREET_H:
			return true
	return false


# each octagon's sides as wall segments, 6 px out like main's building line:
# the chamfers and, across the side streets' mouths, where the containers
# stand. Main leaves a gap in its building line where bikes cross (it is how
# other walks' side streets lead somewhere), which here opened a way out of
# the street down a side street; the bikes are not bodies and ride through.
static func octagon_walls() -> Array:
	var out: Array = []
	for yi: float in XINGS:
		for side: float in [-1.0, 1.0]:
			var lo := Vector2(CX + side * (HALF + 6.0), yi + STREET_H + RAMP)
			var a := Vector2(CX + side * (XHALF + 6.0), yi + STREET_H)
			var b := Vector2(CX + side * (XHALF + 6.0), yi - STREET_H)
			var hi := Vector2(CX + side * (HALF + 6.0), yi - STREET_H - RAMP)
			out.append([lo, a])
			out.append([a, b])
			out.append([b, hi])
	return out


static func island_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for isl: Vector2 in ISLANDS:
		out.append(Rect2(CX - ISLAND_W * 0.5, isl.x - isl.y * 0.5, ISLAND_W, isl.y))
	return out


# --- build -----------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "INTERIOR D'ILLA"
	m.gate_l = CX - 200.0
	m.gate_r = CX + 200.0
	m.eixample_tour = EixampleTour.new()
	m.eixample_pond_paddled = false
	m.lane_ys = Array(BIKE_XINGS.duplicate(), TYPE_FLOAT, &"", null)

	# the plane trees, in grates along the line between the panot and the
	# granite, down every block (not on the chamfers or the cross streets)
	var tree_x: Array[float] = [CX - HALF + SIDEWALK + 8.0, CX + HALF - SIDEWALK - 8.0]
	var y := 120.0
	var k := 0
	while y > m.GATE_Y + 80.0:
		if half_at(y - 24.0) <= HALF + 0.5 and half_at(y + 24.0) <= HALF + 0.5:
			for tx: float in tree_x:
				if not (tx < CX and y < POND.end.y + 60.0 and y > POND.position.y - 60.0):
					m.poles.append(Vector2(tx, y + (8.0 if k % 2 == 0 else -8.0)))
		y -= 168.0
		k += 1
	# a lamp on every chamfer
	for p: Vector2 in chamfer_spots(30.0):
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	# the café terrace on the far right chamfer of the second crossing
	m.tables = Array([Vector2(900.0, -1940.0), Vector2(846.0, -1990.0), Vector2(880.0, -2048.0)], TYPE_VECTOR2, &"", null)
	m.chairs = Array([
		Vector2(930.0, -1918.0), Vector2(872.0, -1928.0), Vector2(820.0, -1966.0),
		Vector2(818.0, -2016.0), Vector2(846.0, -2076.0), Vector2(902.0, -2034.0),
	], TYPE_VECTOR2, &"", null)
	m.parasols = Array([Vector2(872.0, -1990.0)], TYPE_VECTOR2, &"", null)
	# a delivery van in the loading bay on a chamfer, as every morning
	m.vans = Array([Vector2(422.0, -3440.0)], TYPE_VECTOR2, &"", null)
	# the benches face out of the planted islands
	var benches: Array[Vector2] = []
	for r: Rect2 in island_rects():
		benches.append(Vector2(r.position.x - 16.0, r.get_center().y))
	m.benches = Array(benches, TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(CX - HALF + 22.0, -330.0), Vector2(CX + HALF - 22.0, -1240.0),
		Vector2(CX - HALF + 22.0, -2480.0), Vector2(CX + HALF - 22.0, -3660.0),
	], TYPE_VECTOR2, &"", null)
	if "fountains" in m:
		m.fountains = Array([Vector2(CX + HALF - 24.0, -2840.0), Vector2(CX - HALF + 24.0, -4060.0)], TYPE_VECTOR2, &"", null)

	var hyd_list: Array[Vector2] = [
		Vector2(CX - HALF + 18.0, -120.0), Vector2(CX + HALF - 18.0, -1500.0),
		Vector2(CX - HALF + 18.0, -2780.0), Vector2(CX + HALF - 18.0, -3980.0),
		Vector2(CX + HALF - 18.0, -4720.0),
	]
	var keb_list: Array[Vector2] = [
		Vector2(560.0, -800.0), Vector2(720.0, -2150.0), Vector2(580.0, -3300.0), Vector2(700.0, -4560.0),
	]
	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	return island_rects()


static func tree_kind(m: Node2D, p: Vector2) -> int:
	return m.TREE_NONE if is_lamp(m, p) else m.TREE_STREET


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return half_at(p.y) > HALF + 1.0


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		var r: Rect2 = m._freedom_rect()
		var lawn := r.grow(-70.0)
		if lawn.has_point(p) and absf(p.x - CX) > 56.0:
			return Surfaces.S.GRASS
		return Surfaces.S.PAVEMENT
	if POND.has_point(p):
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


# chamfered corners she has marked: each chamfer counts once
static func corners_marked(m: Node2D) -> int:
	var spots := chamfer_spots(30.0)
	var n := 0
	for s: Vector2 in spots:
		for mk: Vector2 in m.marks:
			if mk.distance_to(s) < CORNER_R:
				n += 1
				break
	return n


# --- per frame -----------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if not m.eixample_pond_paddled and POND.grow(-6.0).has_point(m.dog.global_position):
		m.eixample_pond_paddled = true
		m.award_points(2, "paddle! +2")
	if m.eixample_tour != null:
		m.eixample_tour.tick(m, delta)


static func on_bark(m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	return m.eixample_tour != null and m.eixample_tour.on_bark(m)


# --- ground: the street itself (static, recorded once per stretch) ------------------

static func _corridor_poly(lo: float, hi: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var ys: Array[float] = [hi]
	for yi: float in XINGS:
		for yy: float in [yi + STREET_H + RAMP, yi + STREET_H, yi - STREET_H, yi - STREET_H - RAMP]:
			if yy < hi and yy > lo:
				ys.append(yy)
	ys.append(lo)
	ys.sort()
	ys.reverse()
	for yy: float in ys:
		var h := half_at(yy)
		left.append(Vector2(CX - h, yy))
		right.append(Vector2(CX + h, yy))
	var pts := PackedVector2Array()
	pts.append_array(left)
	right.reverse()
	pts.append_array(right)
	return pts


static func draw_cross_section(m: Node2D, wc: ShapeBatch, top: float, bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	_draw_cross_section(m, wc, top, bottom, ctop, vt, vb)
	wc.lod = keep_lod


static func _draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 30.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	wc.polygon(_corridor_poly(lo, hi), PANOT)
	# the granite middle where the road was, with its slab joints
	var gl := CX - HALF + SIDEWALK + 22.0
	var gr := CX + HALF - SIDEWALK - 22.0
	wc.rect(Rect2(gl, lo, gr - gl, hi - lo), GRANITE)
	var row := int(floorf(lo / 60.0))
	var sy := float(row) * 60.0
	while sy < hi:
		wc.line(Vector2(gl, sy), Vector2(gr, sy), GRANITE_JOINT, 1.4)
		var off := 0.0 if row % 2 == 0 else 45.0
		var sx := gl + off
		while sx < gr:
			wc.line(Vector2(sx, sy), Vector2(sx, sy + 60.0), GRANITE_JOINT, 1.2)
			if _h(row * 31 + int(sx)) > 0.72:
				wc.rect(Rect2(sx + 2.0, sy + 2.0, 86.0, 56.0).intersection(Rect2(gl, sy, gr - gl, 60.0)), GRANITE_LIT)
			sx += 90.0
		row += 1
		sy += 60.0
	# the channels either side of it, where the kerbs used to be
	wc.rect(Rect2(gl - 8.0, lo, 8.0, hi - lo), RIGOLA)
	wc.rect(Rect2(gr, lo, 8.0, hi - lo), RIGOLA)
	# panot: the four-petal flower tile, a joint grid and one flower per tile
	_panot(wc, lo, hi)
	# the cross streets: asphalt across the octagon, a kerb each side, the
	# zebra where the walk crosses and a green bike lane down the middle
	for yi: float in XINGS:
		if yi + STREET_H + RAMP < lo or yi - STREET_H - RAMP > hi:
			continue
		var r := Rect2(CX - XHALF, yi - STREET_H, XHALF * 2.0, STREET_H * 2.0)
		wc.rect(r, ASPHALT)
		for i in range(10):
			var px := CX - XHALF + 30.0 + _h(int(yi) + i) * (XHALF * 2.0 - 60.0)
			var py := yi - STREET_H + 14.0 + _h(int(yi) + i * 7) * (STREET_H * 2.0 - 28.0)
			wc.circle(Vector2(px, py), 10.0 + _h(i) * 8.0, ASPHALT_LIT)
		wc.rect(Rect2(r.position.x, r.position.y - 4.0, r.size.x, 6.0), KERB)
		wc.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 6.0), KERB)
		# the zebra: stripes along the traffic, stacked up the crossing. A
		# crossing the bikes ride is main's bike lane instead (main.lane_ys),
		# drawn over this with its warning light.
		if not BIKE_XINGS.has(yi):
			var zy := yi - STREET_H + 10.0
			while zy < yi + STREET_H - 18.0:
				wc.rect(Rect2(CX - 150.0, zy, 300.0, 14.0), ZEBRA)
				zy += 26.0
	# Plaça de Gaudí's pond, with the basilica's towers upside down in it
	if POND.end.y + 30.0 > lo and POND.position.y - 30.0 < hi:
		_pond(wc)
	# the planted islands' beds and hedges
	for r: Rect2 in island_rects():
		if r.end.y + 20.0 > lo and r.position.y - 20.0 < hi:
			wc.rect(r.grow(5.0), KERB)
			wc.rect(r, SAULO)
	_islands(wc, lo, hi)
	# where the facades meet the paving: a dark line of shade all the way up
	var poly := _corridor_poly(lo, hi)
	var n := poly.size() / 2
	for i in range(n - 1):
		wc.line(poly[i], poly[i + 1], CORNICE_SHADE, 6.0)
		wc.line(poly[poly.size() - 1 - i], poly[poly.size() - 2 - i], CORNICE_SHADE, 6.0)


static func _islands(wc: ShapeBatch, lo: float, hi: float) -> void:
	# the planted islands' hedges, with lavender at the ends
	for r: Rect2 in island_rects():
		if r.end.y + 30.0 < lo or r.position.y - 30.0 > hi:
			continue
		wc.rect(Rect2(r.position + LIGHT * 8.0, r.size), SHADOW)
		var hy := r.position.y + 14.0
		while hy < r.end.y - 10.0:
			wc.circle(Vector2(r.get_center().x - 14.0, hy), 15.0, HEDGE)
			wc.circle(Vector2(r.get_center().x + 14.0, hy + 9.0), 15.0, HEDGE)
			wc.circle(Vector2(r.get_center().x - 18.0, hy - 4.0), 9.0, HEDGE_LIT)
			wc.circle(Vector2(r.get_center().x + 10.0, hy + 5.0), 9.0, HEDGE_LIT)
			hy += 26.0
		# lavender at the ends
		for e: float in [r.position.y + 8.0, r.end.y - 8.0]:
			for i in range(3):
				wc.circle(Vector2(r.position.x + 16.0 + float(i) * 20.0, e), 5.0, Color(0.56, 0.46, 0.70))


static func _panot(wc: ShapeBatch, lo: float, hi: float) -> void:
	# the four-petal flower tile: one diamond per tile and the joints between
	# them. Joints run the whole length of a straight stretch as one line;
	# only the chamfers, whose width changes, are jointed row by row.
	const T := 40.0
	var gl := CX - HALF + SIDEWALK + 14.0
	var gr := CX + HALF - SIDEWALK - 14.0
	var yy := floorf(lo / T) * T
	var run_top := yy
	var run_on := false
	while yy < hi:
		var mid := yy + T * 0.5
		var hh := half_at(mid)
		var straight := hh <= HALF + 0.5
		var crossing := in_cross_street(mid)
		# close a straight run: its vertical joints, one line each
		if run_on and not straight:
			_panot_columns(wc, run_top, yy, CX - HALF, gl, gr, CX + HALF)
			run_on = false
		if straight and not run_on:
			run_top = yy
			run_on = true
		if not crossing:
			var spans: Array[Vector2] = [Vector2(CX - hh, gl), Vector2(gr, CX + hh)]
			if not straight:
				spans = [Vector2(CX - hh, CX + hh)]
			for sp: Vector2 in spans:
				wc.line(Vector2(sp.x, yy), Vector2(sp.y, yy), PANOT_JOINT, 1.2)
				var xx := CX - floorf((CX - sp.x) / T) * T
				while xx < sp.y:
					if not straight and xx > sp.x:
						wc.line(Vector2(xx, yy), Vector2(xx, yy + T), PANOT_JOINT, 1.2)
					var c := Vector2(xx + T * 0.5, mid)
					if c.x > sp.x + 10.0 and c.x < sp.y - 10.0:
						wc.quad(c + Vector2(0, -12), c + Vector2(12, 0), c + Vector2(0, 12), c + Vector2(-12, 0), PANOT_FLOWER)
					xx += T
		yy += T
	if run_on:
		_panot_columns(wc, run_top, yy, CX - HALF, gl, gr, CX + HALF)


static func _panot_columns(wc: ShapeBatch, top: float, bot: float, x0: float, gl: float, gr: float, x1: float) -> void:
	const T := 40.0
	for sp: Vector2 in [Vector2(x0, gl), Vector2(gr, x1)]:
		var xx := CX - floorf((CX - sp.x) / T) * T
		while xx < sp.y:
			if xx > sp.x:
				wc.line(Vector2(xx, top), Vector2(xx, bot), PANOT_JOINT, 1.2)
			xx += T


static func _pond(wc: ShapeBatch) -> void:
	var r := POND
	wc.rect(r.grow(10.0), STONE_DARK)
	wc.rect(r.grow(6.0), STONE)
	wc.rect(r, WATER)
	# the towers' reflection: dark spires pointing down the water
	for i in range(4):
		var bx := r.position.x + 22.0 + float(i) * 26.0
		var top := r.position.y + 30.0 + (10.0 if i == 1 or i == 2 else 34.0)
		wc.quad(Vector2(bx - 8.0, r.position.y + 6.0), Vector2(bx + 8.0, r.position.y + 6.0),
			Vector2(bx + 2.0, top + 70.0), Vector2(bx - 2.0, top + 70.0), Color(0.18, 0.30, 0.34, 0.6))
	for i in range(5):
		var ly := r.position.y + 40.0 + float(i) * 44.0
		wc.line(Vector2(r.position.x + 16.0, ly), Vector2(r.end.x - 20.0, ly + 4.0), WATER_LIT, 2.0)
	# reeds and a willow's edge at the far corner
	for i in range(6):
		var p := Vector2(r.position.x + 6.0 + float(i) * 6.0, r.end.y - 8.0 - _h(i) * 10.0)
		wc.line(p, p + Vector2(2.0, -14.0), HEDGE_LIT, 2.0)


# --- the blocks either side (edge layer, culled to the view) --------------------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# circles at the sides their size needs, not the full 64 (shape_batch.gd)
	var keep_lod := b.lod
	b.lod = true
	_draw_edge_layer(m, b, vt, vb)
	b.lod = keep_lod


static func _draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var gate_y := float(m.GATE_Y)
	var lo := maxf(vt - 300.0, gate_y - 40.0)
	var hi := minf(vb + 300.0, float(m.START_Y) + 600.0)
	if hi <= lo:
		return
	b.rect(Rect2(-440.0, lo, 2160.0, hi - lo), ASPHALT)
	# the blocks between the cross streets, each a run of buildings with the
	# cut corner at either end
	var bounds: Array[float] = [float(m.START_Y) + 600.0]
	for yi: float in XINGS:
		bounds.append(yi + STREET_H)
		bounds.append(yi - STREET_H)
	bounds.append(gate_y - 40.0)
	var bi := 0
	while bi + 1 < bounds.size():
		var bot := bounds[bi]
		var top := bounds[bi + 1]
		bi += 2
		if top > hi or bot < lo:
			continue
		var last := top <= gate_y
		for side: float in [-1.0, 1.0]:
			if last and side > 0.0:
				_basilica(b, top, bot)
			else:
				_block(b, top, bot, side, bi)
	# the cross streets outside the walk: parked cars and the containers on
	# the corner, a zebra over each side street
	for yi: float in XINGS:
		if yi + STREET_H < lo or yi - STREET_H > hi:
			continue
		_side_street(b, yi)


# the building line at y on one side: the walk's edge, chamfers included
static func _front_x(y: float, side: float) -> float:
	return CX + side * half_at(y)


static func _block(b: ShapeBatch, top: float, bot: float, side: float, salt: int) -> void:
	var far := -440.0 if side < 0.0 else 1720.0
	# the whole block: courtyard green in the middle, the buildings round it
	var poly := PackedVector2Array()
	var steps: Array[float] = [bot]
	for yy: float in [bot - RAMP, top + RAMP]:
		if yy < bot and yy > top:
			steps.append(yy)
	steps.append(top)
	for yy: float in steps:
		poly.append(Vector2(_front_x(yy, side), yy))
	poly.append(Vector2(far, top))
	poly.append(Vector2(far, bot))
	b.polygon(poly, ROOF_TONES[salt % ROOF_TONES.size()].darkened(0.12))
	# the courtyard: buildings 150 deep, the green inside them
	var depth := 150.0
	var cin := CX + side * (HALF + depth)
	var c_top := top + depth
	var c_bot := bot - depth
	if c_bot - c_top > 60.0:
		var cr := Rect2(minf(cin, far), c_top, absf(far - cin), c_bot - c_top)
		b.rect(cr, COURTYARD)
		for i in range(5):
			var tp := Vector2(cin + side * (40.0 + 60.0 * float(i)), c_top + 40.0 + _h(salt * 5 + i) * maxf(1.0, c_bot - c_top - 80.0))
			b.circle(tp + Vector2(5.0, 7.0), 22.0, SHADOW)
			b.circle(tp, 22.0, HEDGE)
			b.circle(tp - Vector2(5.0, 6.0), 14.0, HEDGE_LIT)
	# plots along the street front, each its own roof
	var y := bot
	var k := 0
	while y > top:
		var pw := 150.0 + _h(salt * 17 + k) * 70.0
		# the corner house takes the whole chamfer
		if half_at(y - 1.0) > HALF + 1.0:
			pw = RAMP + 2.0
		var py0 := maxf(top, y - pw)
		# a plot never straddles the turn from the street front to a chamfer
		for s_y: float in steps:
			if s_y < y - 1.0 and s_y > py0:
				py0 = s_y
		var tone: Color = ROOF_TONES[(salt * 3 + k) % ROOF_TONES.size()]
		var chamfer := half_at((py0 + y) * 0.5) > HALF + 1.0
		var x_front0 := _front_x(y, side)
		var x_front1 := _front_x(py0, side)
		var x_back := CX + side * (HALF + depth)
		if chamfer:
			x_back = CX + side * (XHALF + 70.0)
		var pts := PackedVector2Array([
			Vector2(x_front0, y), Vector2(x_front1, py0),
			Vector2(x_back, py0), Vector2(x_back, y),
		])
		b.polygon(pts, tone)
		_roof_detail(b, pts, side, salt * 13 + k, chamfer)
		y = py0
		k += 1
	# the cornice and the balconies along the whole front
	for i in range(steps.size() - 1):
		var a := Vector2(_front_x(steps[i], side), steps[i])
		var c := Vector2(_front_x(steps[i + 1], side), steps[i + 1])
		b.line(a, c, PARAPET, 5.0)
		var dirv := (c - a).normalized()
		var outv := Vector2(-dirv.y, dirv.x) * (1.0 if side > 0.0 else -1.0)
		var seg_len := a.distance_to(c)
		var t := 18.0
		while t < seg_len - 18.0:
			var p := a + dirv * t + outv * 5.0
			b.line(p, p + dirv * 22.0, BALCONY, 3.0)
			t += 40.0


static func _roof_detail(b: ShapeBatch, pts: PackedVector2Array, side: float, salt: int, chamfer: bool) -> void:
	var c := (pts[0] + pts[1] + pts[2] + pts[3]) * 0.25
	if chamfer:
		# the corner house: a round tribune turret on the cut corner with a
		# trencadís cap, as the modernista corners have
		var corner := (pts[0] + pts[1]) * 0.5 + Vector2(side * 30.0, 0.0)
		b.circle(corner + LIGHT * 10.0, 26.0, SHADOW)
		b.circle(corner, 26.0, TURRET)
		b.circle(corner - LIGHT * 4.0, 19.0, TURRET_LIT)
		for i in range(10):
			var a := TAU * float(i) / 10.0
			b.circle(corner + Vector2.from_angle(a) * 12.0, 3.4, TRENCADIS[(salt + i) % TRENCADIS.size()])
		b.circle(corner, 5.0, TRENCADIS[salt % TRENCADIS.size()])
		# and its roof terrace behind the turret
		var back := (pts[2] + pts[3]) * 0.5
		var mid := corner.lerp(back, 0.62)
		b.rect(Rect2(mid - Vector2(34.0, 30.0), Vector2(68.0, 60.0)), PARAPET)
		b.rect(Rect2(mid - Vector2(30.0, 26.0), Vector2(60.0, 52.0)), TERRAT)
		b.rect(Rect2(mid + Vector2(-12.0, -22.0) + LIGHT * 5.0, Vector2(26.0, 20.0)), SHADOW)
		b.rect(Rect2(mid + Vector2(-12.0, -22.0), Vector2(26.0, 20.0)), STAIR_HOUSE)
		return
	# a roof terrace: red tiles inside a white parapet, the stair house, a
	# water tank, and a line of washing
	var inner := PackedVector2Array()
	for p: Vector2 in pts:
		inner.append(p + (c - p) * 0.14)
	b.polygon(inner, TERRAT)
	var sh := c + Vector2(side * 20.0, -10.0 + _h(salt) * 20.0)
	b.rect(Rect2(sh + LIGHT * 6.0 - Vector2(16.0, 12.0), Vector2(32.0, 24.0)), SHADOW)
	b.rect(Rect2(sh - Vector2(16.0, 12.0), Vector2(32.0, 24.0)), STAIR_HOUSE)
	b.rect(Rect2(sh - Vector2(16.0, 12.0), Vector2(32.0, 5.0)), STAIR_HOUSE.darkened(0.12))
	if _h(salt * 3) > 0.4:
		var tk := c + Vector2(-side * 26.0, 18.0)
		b.circle(tk + LIGHT * 5.0, 9.0, SHADOW)
		b.circle(tk, 9.0, TANK)
		b.circle(tk - LIGHT * 2.0, 5.0, TANK.lightened(0.1))
	if _h(salt * 7) > 0.5:
		var w0 := c + Vector2(-side * 34.0, -26.0)
		var w1 := w0 + Vector2(side * 56.0, 0.0)
		b.line(w0, w1, Color(0.3, 0.3, 0.3, 0.6), 1.0)
		for i in range(4):
			var wp := w0.lerp(w1, (float(i) + 0.5) / 4.0)
			b.rect(Rect2(wp - Vector2(4.0, 0.0), Vector2(8.0, 9.0)), TRENCADIS[(salt + i * 2) % TRENCADIS.size()].lightened(0.3))


static func _side_street(b: ShapeBatch, yi: float) -> void:
	for side: float in [-1.0, 1.0]:
		var x0 := CX + side * XHALF
		var x1 := 1720.0 if side > 0.0 else -440.0
		# lane lines and parked cars along the far kerb
		var lx := minf(x0, x1)
		var lw := absf(x1 - x0)
		b.rect(Rect2(lx, yi - STREET_H, lw, 6.0), KERB)
		b.rect(Rect2(lx, yi + STREET_H - 6.0, lw, 6.0), KERB)
		var dx := x0 + side * 30.0
		while (dx - x1) * side < 0.0:
			b.rect(Rect2(dx, yi - 2.0, side * 26.0, 3.0).abs(), Color(0.9, 0.9, 0.86, 0.6))
			dx += side * 60.0
		# the zebra across the side street, set back from the corner
		var zx := x0 + side * 70.0
		for i in range(6):
			b.rect(Rect2(zx + side * float(i) * 20.0, yi - STREET_H + 8.0, side * 12.0, STREET_H * 2.0 - 16.0).abs(), ZEBRA)
		var cx := x0 + side * 220.0
		for i in range(3):
			var car := Vector2(cx + side * float(i) * 120.0, yi + STREET_H - 26.0)
			var col: Color = [Color(0.72, 0.18, 0.16), Color(0.86, 0.86, 0.84), Color(0.18, 0.24, 0.36)][(int(absf(yi) / 10.0) + i) % 3]
			b.rect(Rect2(car - Vector2(46.0, 14.0) + LIGHT * 5.0, Vector2(92.0, 32.0)), SHADOW)
			b.rect(Rect2(car - Vector2(46.0, 16.0), Vector2(92.0, 32.0)), col)
			b.rect(Rect2(car - Vector2(20.0, 12.0), Vector2(40.0, 24.0)), Color(0.24, 0.30, 0.36))
			b.rect(Rect2(car - Vector2(16.0, 10.0), Vector2(32.0, 20.0)), col.lightened(0.1))
	# the recycling containers in a row on the corner's road edge, one per
	# colour, the way every Eixample chamfer has them, along the mouth of
	# the side street where the walk's wall closes it
	for side: float in [-1.0, 1.0]:
		# with the gap in the middle the people cross by
		var x := CX + side * (XHALF + 12.0)
		var offs: Array[float] = [-78.0, -52.0, 32.0, 58.0, 84.0]
		for i in range(5):
			var r := Rect2(x - 12.0, yi + offs[i] - 12.0, 24.0, 24.0)
			b.rect(Rect2(r.position + LIGHT * 4.0, r.size), SHADOW)
			b.rect(r, CONTAINERS[i])
			b.rect(Rect2(r.position.x + 3.0, r.position.y + 3.0, r.size.x - 6.0, 6.0), CONTAINERS[i].lightened(0.18))


static func _basilica(b: ShapeBatch, top: float, bot: float) -> void:
	# the precinct: stone paving behind a railing, the facade's portal
	# porches and four bell towers at the street, the nave roof and the
	# central towers going back, and the crane over it all
	var front := CX + HALF
	b.rect(Rect2(front, top, 1720.0 - front, bot - top), STONE_DARK)
	b.rect(Rect2(front, top, 70.0, bot - top), STONE)
	var rail_x := front + 2.0
	b.line(Vector2(rail_x, top), Vector2(rail_x, bot), IRON, 3.0)
	var y := bot - 10.0
	while y > top:
		b.circle(Vector2(rail_x, y), 2.4, IRON)
		y -= 14.0
	# the transept facade: three porches and the towers behind them
	var fx := front + 110.0
	var fy0 := maxf(top, -4980.0)
	var fy1 := minf(bot, -4560.0)
	b.rect(Rect2(fx, fy0, 480.0, fy1 - fy0), STONE)
	for i in range(3):
		var py := lerpf(fy0, fy1, (float(i) + 0.5) / 3.0)
		b.circle(Vector2(fx + 20.0, py) + LIGHT * 8.0, 46.0, SHADOW)
		b.circle(Vector2(fx + 20.0, py), 46.0, STONE_LIT)
		b.circle(Vector2(fx + 20.0, py), 30.0, Color(0.70, 0.74, 0.54))
		b.circle(Vector2(fx + 20.0, py), 16.0, Color(0.52, 0.62, 0.42))
	# four bell towers in a row: long shadows, the stone shaft, the
	# trencadís pinnacle with its cross of four balls
	for i in range(4):
		var ty := lerpf(fy0 + 40.0, fy1 - 40.0, float(i) / 3.0)
		var tp := Vector2(fx + 150.0, ty)
		b.capsule(tp, tp + LIGHT * 150.0, 26.0, SHADOW)
		b.circle(tp, 30.0, STONE_DARK)
		b.circle(tp - LIGHT * 3.0, 25.0, STONE)
		b.circle(tp - LIGHT * 6.0, 17.0, STONE_LIT)
		for j in range(8):
			var a := TAU * float(j) / 8.0
			b.circle(tp - LIGHT * 6.0 + Vector2.from_angle(a) * 11.0, 3.0, TRENCADIS[(i + j) % TRENCADIS.size()])
		b.circle(tp - LIGHT * 8.0, 6.0, Color(0.94, 0.86, 0.50))
		for j in range(4):
			b.circle(tp - LIGHT * 8.0 + Vector2.from_angle(TAU * float(j) / 4.0) * 7.0, 2.4, Color(0.96, 0.96, 0.92))
	# the nave's long roof and the great central tower behind it
	b.rect(Rect2(fx + 230.0, fy0 + 60.0, 400.0, fy1 - fy0 - 120.0), Color(0.62, 0.58, 0.50))
	var ct := Vector2(fx + 420.0, (fy0 + fy1) * 0.5)
	b.capsule(ct, ct + LIGHT * 260.0, 44.0, SHADOW)
	b.circle(ct, 50.0, STONE_DARK)
	b.circle(ct - LIGHT * 6.0, 40.0, STONE_LIT)
	b.circle(ct - LIGHT * 10.0, 16.0, Color(0.96, 0.96, 0.92))
	# a tower crane, its mast in the works and its jib swung over the nave
	var mast := Vector2(fx + 320.0, fy0 + 30.0)
	b.rect(Rect2(mast - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), CRANE.darkened(0.2))
	var jib_end := mast + Vector2(-40.0, 340.0)
	b.line(mast + LIGHT * 40.0, jib_end + LIGHT * 40.0, SHADOW, 8.0)
	b.line(mast, jib_end, CRANE, 6.0)
	b.line(mast, mast + Vector2(16.0, -110.0), CRANE, 6.0)
	b.rect(Rect2(mast + Vector2(6.0, -128.0), Vector2(26.0, 22.0)), Color(0.48, 0.50, 0.52))
	var t := 0.0
	while t < 1.0:
		b.line(mast.lerp(jib_end, t), mast.lerp(jib_end, t + 0.05) + Vector2(6.0, 0.0), CRANE.darkened(0.25), 1.4)
		t += 0.08


# --- standing things, drawn every frame --------------------------------------------------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# circles at the sides their size needs, not the full 64 (shape_batch.gd)
	var keep_lod := b.lod
	b.lod = true
	_draw_live(m, b, vt, vb)
	b.lod = keep_lod


static func _draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# the croissant on its saucer, at the edge of a terrace table
	var taken: bool = bool(m.prize_taken)
	if not taken and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		b.glow(PRIZE, 22.0, Color(1.0, 0.88, 0.50, 0.26))
		b.circle(PRIZE + Vector2(1.5, 2.0), 7.5, SHADOW)
		b.circle(PRIZE, 7.5, Color(0.94, 0.94, 0.92))
		var cr := Color(0.86, 0.60, 0.28)
		b.capsule(PRIZE + Vector2(-5.0, 1.0), PRIZE + Vector2(5.0, 1.0), 3.4, cr)
		b.circle(PRIZE + Vector2(-5.0, 2.5), 2.4, cr.darkened(0.12))
		b.circle(PRIZE + Vector2(5.0, 2.5), 2.4, cr.darkened(0.12))
		b.line(PRIZE + Vector2(-2.0, -1.0), PRIZE + Vector2(-1.0, 3.0), cr.darkened(0.25), 1.0)
		b.line(PRIZE + Vector2(1.5, -1.0), PRIZE + Vector2(2.5, 3.0), cr.darkened(0.25), 1.0)
	if m.eixample_tour != null:
		m.eixample_tour.draw(b, vt, vb, m.dog.global_position)


# --- the off-leash space: the garden inside the next block ---------------------------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	var gate_y := float(m.GATE_Y)
	# the block's back: everyone's rear galleries and washing, all round
	b.rect(Rect2(-440.0, gate_y - 2400.0, 2160.0, 2400.0), ROOF_TONES[1].darkened(0.1))
	var k := 0
	var x := -400.0
	while x < 1700.0:
		var w := 120.0 + _h(k) * 80.0
		var tone: Color = ROOF_TONES[k % ROOF_TONES.size()]
		b.rect(Rect2(x, r.position.y - 200.0, w - 4.0, 170.0), tone)
		b.rect(Rect2(x + 10.0, r.position.y - 60.0, w - 24.0, 26.0), Color(0.86, 0.84, 0.78))
		for i in range(int(w / 26.0)):
			b.rect(Rect2(x + 12.0 + float(i) * 26.0, r.position.y - 56.0, 14.0, 10.0), TRENCADIS[(k + i) % TRENCADIS.size()].lightened(0.3))
		x += w
		k += 1
	for side: float in [-1.0, 1.0]:
		var sx := r.position.x - 200.0 if side < 0.0 else r.end.x + 30.0
		var yy := r.position.y - 30.0
		while yy < r.end.y + 40.0:
			b.rect(Rect2(sx, yy, 170.0, 116.0), ROOF_TONES[(k + int(yy)) % ROOF_TONES.size()])
			b.rect(Rect2(sx + (140.0 if side < 0.0 else 4.0), yy + 8.0, 26.0, 100.0), Color(0.86, 0.84, 0.78))
			yy += 120.0
			k += 1
	# the garden: lawns either side of a sauló path, a play corner, and the
	# old water tower in the middle of the far end
	b.rect(r, SAULO)
	var lawn := r.grow(-70.0)
	b.rect(Rect2(lawn.position.x, lawn.position.y, CX - 56.0 - lawn.position.x, lawn.size.y), Color(0.38, 0.54, 0.30))
	b.rect(Rect2(CX + 56.0, lawn.position.y, lawn.end.x - CX - 56.0, lawn.size.y), Color(0.38, 0.54, 0.30))
	for i in range(24):
		var tp := Vector2(lawn.position.x + 20.0 + _h(i * 3) * (lawn.size.x - 40.0), lawn.position.y + 20.0 + _h(i * 5 + 1) * (lawn.size.y - 40.0))
		if absf(tp.x - CX) > 70.0:
			b.circle(tp, 5.0, Color(0.32, 0.48, 0.26))
	var tower := Vector2(r.position.x + 150.0, r.position.y - 70.0)
	b.capsule(tower, tower + LIGHT * 120.0, 40.0, SHADOW)
	b.circle(tower, 46.0, Color(0.56, 0.30, 0.22))
	b.circle(tower - LIGHT * 4.0, 38.0, Color(0.68, 0.38, 0.28))
	b.circle(tower - LIGHT * 8.0, 24.0, Color(0.30, 0.42, 0.48))
	b.circle(tower - LIGHT * 10.0, 8.0, Color(0.20, 0.20, 0.22))
	b.rect(Rect2(r.position.x - 20.0, r.position.y - 20.0, r.size.x + 40.0, 20.0), Color(0.86, 0.84, 0.78))
	b.rect(Rect2(r.position.x - 20.0, r.position.y, 20.0, r.size.y), Color(0.86, 0.84, 0.78))
	b.rect(Rect2(r.end.x, r.position.y, 20.0, r.size.y), Color(0.86, 0.84, 0.78))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, BENCH_WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, "The garden inside the block, off leash")


# The street after dark (world/night_fronts.gd): this walk draws its own
# edges, so it lists its illuminated shopfronts, bars and doorways.
static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var y := maxf(float(m.GATE_Y) + 40.0, -4800.0)
	var i := 0
	while y < minf(float(m.START_Y) + 60.0, 200.0):
		var in_xway := false
		for xi: float in XINGS:
			if absf(y - xi) < STREET_H + 24.0:
				in_xway = true
				break
		if not in_xway:
			for side: float in [-1.0, 1.0]:
				var k := i * 2 + (0 if side < 0.0 else 1) + 707
				var kind := NightFronts.kind_of(k)
				if kind != "":
					var fx := _front_x(y, side)
					out.append(NightFronts.front(Vector2(fx, y), -side, kind, k))
		y += 180.0
		i += 1
	return out

