class_name Partit
extends RefCounted

# DIA DE PARTIT, match day in Les Corts (docs/superpowers/specs/
# 2026-10-17-dia-de-partit-design.md). This file is the first piece, the
# corridor and its set dressing: a calm side street, the corner where the
# police have closed the avenue, the avenue itself with its vendors, the bar
# terrace and the steel barriers along the kerbs, the stadium approach with
# its ticket windows, drummers and gates, and the square beside the stadium
# where she comes off the leash. The crowd, the kick-off clock and the set
# pieces come in later pieces.
#
# Branding (the spec's rules): no club, crest, sponsor, player or stadium
# name anywhere. Home colours are blue and claret, in halves; flags carry a
# plain white star; the stadium is "L'ESTADI" and nothing else.
#
# Layout is in level space (the corridor fit leaves this walk alone). The
# path IS the street: sidewalks are drawn inside walk_edges, so every stall
# and table stands on the pavement the level check measures. The ground,
# the stalls and the blocks are static, so they live on the cached edge layer
# (draw_edge_layer); the world pass only draws what moves (draw_live).
# Static functions over main's state, like the other systems.

const Letters := preload("res://world/sign_letters.gd")
const HumanLook := preload("res://entities/human_appearance.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08, 0.20)

# --- colours ---------------------------------------------------------------
const ASPHALT := Color(0.31, 0.31, 0.33)
const PAVING := Color(0.68, 0.66, 0.62)        # the sidewalks' hydraulic tiles
const PAVING_JOINT := Color(0.58, 0.56, 0.52)
const KERB := Color(0.78, 0.76, 0.71)
const CONCOURSE := Color(0.74, 0.72, 0.67)
const LINE_WHITE := Color(0.90, 0.89, 0.84)
const BLUE_ZONE := Color(0.26, 0.46, 0.80)
const HOME_BLUE := Color(0.16, 0.30, 0.62)
const HOME_CLARET := Color(0.56, 0.12, 0.24)
const AWAY_ORANGE := Color(0.92, 0.50, 0.16)
const AWAY_SLATE := Color(0.36, 0.40, 0.46)
const STAR_WHITE := Color(0.97, 0.96, 0.92)
const STEEL := Color(0.72, 0.74, 0.76)
const POLICE_NAVY := Color(0.12, 0.16, 0.28)
const ROOF_COLS: Array[Color] = [Color(0.72, 0.52, 0.42), Color(0.62, 0.60, 0.57), Color(0.78, 0.66, 0.52),
	Color(0.66, 0.46, 0.38), Color(0.56, 0.55, 0.53)]
const SKINS: Array[Color] = [Color(0.92, 0.76, 0.62), Color(0.62, 0.44, 0.32), Color(0.82, 0.64, 0.50), Color(0.45, 0.30, 0.22)]
const HAIRS: Array[Color] = [Color(0.16, 0.12, 0.10), Color(0.42, 0.28, 0.16), Color(0.80, 0.66, 0.40), Color(0.62, 0.60, 0.58)]

# --- the corridor ------------------------------------------------------------
const STREET_Y1 := -600.0      # the side street ends...
const AVENUE_Y0 := -1000.0     # ...and opens onto the avenue
const AVENUE_Y1 := -3250.0     # the avenue bends toward the stadium
const ROAD_END_Y := -3420.0    # where the road stops and the stadium's paving begins
const PORTES_Y0 := -3650.0     # the stadium approach, the stadium along the east
const PORTES_Y1 := -4650.0
const STADIUM_Y0 := -3420.0    # the stadium's wall starts here on the east side
const SIDE_SW := 64.0          # sidewalk width in the side street
const AVE_SW := 84.0           # ...and on the avenue
const ZEBRA_Y := -1090.0

# --- the furniture -----------------------------------------------------------
# lampposts down the avenue's painted median (x 640): the rope winds on them
const MEDIAN_YS: Array[float] = [-1250.0, -1600.0, -1950.0, -2300.0, -2650.0, -3000.0]
# plane trees in grates on the sidewalks
const TREES: Array[Vector2] = [
	Vector2(442.0, -130.0), Vector2(838.0, -40.0), Vector2(442.0, -520.0),
	Vector2(282.0, -1420.0), Vector2(282.0, -2320.0), Vector2(282.0, -2560.0), Vector2(282.0, -2990.0),
	Vector2(998.0, -1140.0), Vector2(998.0, -1580.0), Vector2(998.0, -1860.0), Vector2(998.0, -2140.0),
	Vector2(998.0, -2620.0), Vector2(998.0, -2920.0), Vector2(998.0, -3200.0),
]
# floodlight standards on the stadium's paving
const FLOODS: Array[Vector2] = [Vector2(470.0, -3820.0), Vector2(700.0, -4180.0), Vector2(450.0, -4500.0)]
# steel crowd barriers along the kerbs, [x, south y, north y]: grindable
# (systems/rails.gd, BARRIER RUN), with gaps where the stalls and the
# terrace are
const BARRIERS: Array = [
	[330.0, -1300.0, -1580.0], [330.0, -2200.0, -2700.0], [330.0, -2850.0, -3200.0],
	[950.0, -1100.0, -1240.0], [950.0, -1450.0, -2130.0], [950.0, -2450.0, -3200.0],
]
const SECTION := 46.0          # one barrier section

const SCARF_STALL := Rect2(966.0, -1400.0, 70.0, 140.0)
const CART := Rect2(250.0, -1700.0, 58.0, 88.0)
const SAUSAGE := Rect2(964.0, -2360.0, 72.0, 120.0)
const BAR_Y0 := -2100.0        # BAR LA PENYA's frontage, west side
const BAR_Y1 := -1800.0
const DECK := Rect2(328.0, -2090.0, 66.0, 270.0)   # the terrace's deck in the parking lane
const POLICE_VAN := Vector2(296.0, -1200.0)
const OFFICERS := Rect2(338.0, -1176.0, 30.0, 44.0)
const CARS: Array[Rect2] = [Rect2(752.0, -300.0, 52.0, 108.0), Rect2(752.0, -476.0, 52.0, 104.0)]
const CAR_COLS: Array[Color] = [Color(0.78, 0.20, 0.18), Color(0.86, 0.86, 0.84), Color(0.22, 0.30, 0.44)]
const GRANDAD := Rect2(808.0, -612.0, 26.0, 30.0)
const REGULARS := Rect2(246.0, -1846.0, 28.0, 60.0)   # two at the bar door
const CART_SELLER := Rect2(312.0, -1646.0, 26.0, 28.0)
# the corner's barrier stubs, with CARRER TALLAT on the west one
const STUBS: Array[Rect2] = [Rect2(248.0, -1014.0, 112.0, 10.0), Rect2(920.0, -1014.0, 112.0, 10.0)]
const TAQUILLES := Rect2(232.0, -3960.0, 66.0, 220.0)
const DRUM_STAND := Rect2(240.0, -4380.0, 84.0, 120.0)
# the stadium's gates on the east wall, and the barrier lanes into each
const GATE_YS: Array[float] = [-3800.0, -4100.0, -4400.0]
const GATE_NUMS: Array[String] = ["9", "10", "11"]
const LANE := Vector2(70.0, 10.0)

# the walk's hazardous prize (for now: PR 5 moves it under the police horses)
const PRIZE := Vector2(950.0, -2300.0)
const PRIZE_TEXT := "grab the sausage that fell off the grill"


static func is_on(m: Node2D) -> bool:
	return m.lvl == "partit"


# --- the build -----------------------------------------------------------------

# A calm side street, opening at the corner onto the wide avenue; the avenue
# bends west at its north end so the stadium can fill the east side of the
# view; a pinch through the esplanade to the square's gate.
static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 230.0},
		{"y": STREET_Y1, "cx": 640.0, "half": 230.0},
		{"y": AVENUE_Y0, "cx": 640.0, "half": 400.0},
		{"y": AVENUE_Y1, "cx": 640.0, "half": 400.0},
		{"y": PORTES_Y0, "cx": 560.0, "half": 330.0},
		{"y": PORTES_Y1, "cx": 560.0, "half": 330.0},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": 300.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 300.0},
	]


# [marking spots, snacks]
static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DEL GOL"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	for y: float in MEDIAN_YS:
		m.poles.append(Vector2(640.0, y))
	for t: Vector2 in TREES:
		m.poles.append(t)
	for f: Vector2 in FLOODS:
		m.poles.append(f)
	m.deco_pole_count = m.poles.size()
	m.vans = Array([POLICE_VAN], TYPE_VECTOR2, &"", null)
	# BAR LA PENYA's terrace: tables on the sidewalk and on the deck
	m.tables = Array([Vector2(286.0, -1880.0), Vector2(286.0, -2030.0), Vector2(362.0, -1850.0),
		Vector2(362.0, -1960.0), Vector2(362.0, -2060.0)], TYPE_VECTOR2, &"", null)
	m.chairs = Array([Vector2(286.0, -1846.0), Vector2(286.0, -1914.0), Vector2(286.0, -1996.0),
		Vector2(286.0, -2064.0), Vector2(362.0, -1904.0), Vector2(362.0, -2010.0)], TYPE_VECTOR2, &"", null)
	# the terrace's parasol, and the drinks cart's umbrella
	m.parasols = Array([Vector2(330.0, -1955.0), CART.get_center() + Vector2(0.0, 6.0)], TYPE_VECTOR2, &"", null)
	m.bins = Array([Vector2(448.0, -40.0), Vector2(300.0, -2760.0), Vector2(986.0, -1720.0), Vector2(860.0, -3560.0)],
		TYPE_VECTOR2, &"", null)
	m.benches = Array([Vector2(846.0, -560.0)], TYPE_VECTOR2, &"", null)
	# a drinking fountain in the side street, as every street here has
	m.fountains = Array([Vector2(444.0, -360.0)], TYPE_VECTOR2, &"", null)
	# cones where the police closed the avenue
	m.cone_spots = Array([Vector2(372.0, -1050.0), Vector2(906.0, -1050.0)], TYPE_VECTOR2, &"", null)
	m.performers = Array([], TYPE_VECTOR2, &"", null)
	m.owner_keepouts.clear()
	for r: Rect2 in solids(m):
		m.owner_keepouts.append(r)
	# the city's cast-iron bollards, where a street has hydrants: at the
	# corner, the crossing and the road's end
	var marks: Array[Vector2] = [Vector2(402.0, -730.0), Vector2(878.0, -730.0), Vector2(338.0, -1110.0),
		Vector2(942.0, -1080.0), Vector2(338.0, -2780.0), Vector2(320.0, -3440.0), Vector2(880.0, -3400.0)]
	var snacks: Array[Vector2] = [Vector2(560.0, -880.0), Vector2(720.0, -2480.0), Vector2(480.0, -3960.0)]
	return [marks, snacks]


# What the dog, your human and the passers-by have to go round, beyond main's
# own furniture: the stalls, the parked cars, the barrier stubs, the officers,
# the ticket office, the drummers' stand and the gates' barrier lanes.
static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = [SCARF_STALL, CART, SAUSAGE, OFFICERS, GRANDAD, REGULARS, CART_SELLER, TAQUILLES, DRUM_STAND]
	for c: Rect2 in CARS:
		out.append(c)
	for s: Rect2 in STUBS:
		out.append(s)
	for gy: float in GATE_YS:
		out.append(lane_rect(gy, -1.0))
		out.append(lane_rect(gy, 1.0))
	return out


# one of the two barrier rails into a gate, against the stadium's wall
static func lane_rect(gy: float, side: float) -> Rect2:
	return Rect2(890.0 - LANE.x, gy + side * 36.0 - LANE.y * 0.5, LANE.x, LANE.y)


# The corners the rope catches on (the bodies are the rects above).
static func wrap_points(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for r: Rect2 in [SCARF_STALL, CART, SAUSAGE, TAQUILLES, DRUM_STAND, CARS[0], CARS[1]]:
		var g := r.grow(4.0)
		for c: Vector2 in [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)]:
			# only the corners out on the pavement: a corner inside the
			# building line is one the rope can never reach
			var e: Vector2 = m.walk_edges(c.y)
			if c.x > e.x + 2.0 and c.x < e.y - 2.0:
				out.append(c)
	for s: Rect2 in STUBS:
		out.append(Vector2(s.end.x + 3.0, s.get_center().y) if s.position.x < 640.0 else Vector2(s.position.x - 3.0, s.get_center().y))
	return out


# the sidewalk trees are trees; the median's and the stadium's poles are lamps
static func is_street_tree(p: Vector2) -> bool:
	for t: Vector2 in TREES:
		if t.distance_squared_to(p) < 1.0:
			return true
	return false


# how wide the sidewalk is at this point down the walk (0 past the road's end)
static func sidewalk(y: float) -> float:
	if y < ROAD_END_Y:
		return 0.0
	if y > STREET_Y1:
		return SIDE_SW
	if y < AVENUE_Y0:
		return AVE_SW
	return lerpf(SIDE_SW, AVE_SW, smoothstep(STREET_Y1, AVENUE_Y0, y))


# --- drawing: the cached edge layer ------------------------------------------

# Everything static under the actors: the street, the stalls and the blocks
# either side, and the stadium. `c` is the edge layer's ShapeBatch.
static func draw_edge_layer(m: Node2D, c: ShapeBatch, vt: float, vb: float) -> void:
	var top := maxf(vt - 300.0, m.GATE_Y - 40.0)
	var bot := minf(vb + 300.0, m.START_Y + 600.0)
	if bot <= top:
		return
	_draw_blocks(m, c, top, bot)
	_draw_ground(m, c, top, bot)
	_draw_markings(m, c, top, bot)
	_draw_barriers(c, top, bot)
	_draw_furniture(m, c, top, bot)


static func _edges_strip(m: Node2D, top: float, bot: float, step: float) -> Array:
	var ys: Array[float] = []
	var y := floorf(top / step) * step
	while y < bot + step:
		ys.append(minf(y, bot))
		if y >= bot:
			break
		y += step
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for yy: float in ys:
		var e: Vector2 = m.walk_edges(yy)
		left.append(Vector2(e.x, yy))
		right.append(Vector2(e.y, yy))
	return [left, right]


static func _ribbon(left: PackedVector2Array, right: PackedVector2Array) -> PackedVector2Array:
	var poly := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	return poly


static func _draw_ground(m: Node2D, c: ShapeBatch, top: float, bot: float) -> void:
	var lr: Array = _edges_strip(m, top, bot, 40.0)
	var left: PackedVector2Array = lr[0]
	var right: PackedVector2Array = lr[1]
	# the whole path in sidewalk paving, then the road laid over the middle
	c.polygon(_ribbon(left, right), PAVING)
	var rt := maxf(top, ROAD_END_Y)
	if bot > rt:
		var rl := PackedVector2Array()
		var rr := PackedVector2Array()
		var y := rt
		while true:
			var yy := minf(y, bot)
			var e: Vector2 = m.walk_edges(yy)
			var sw := sidewalk(yy)
			rl.append(Vector2(e.x + sw, yy))
			rr.append(Vector2(e.y - sw, yy))
			if yy >= bot:
				break
			y += 40.0
		c.polygon(_ribbon(rl, rr), ASPHALT)
		# the kerbs: a pale granite edge, and its shadow on the road
		for pts: PackedVector2Array in [rl, rr]:
			for i in range(pts.size() - 1):
				c.line(pts[i], pts[i + 1], KERB, 5.0)
		for i in range(rl.size() - 1):
			c.line(rl[i] + Vector2(3.5, 0), rl[i + 1] + Vector2(3.5, 0), Color(0, 0, 0, 0.18), 2.0)
		# the road's end: a kerb straight across, ramped down in the middle
		if ROAD_END_Y > top and ROAD_END_Y < bot:
			var ee: Vector2 = m.walk_edges(ROAD_END_Y)
			var sw2 := sidewalk(ROAD_END_Y + 1.0)
			c.line(Vector2(ee.x + sw2, ROAD_END_Y), Vector2(ee.y - sw2, ROAD_END_Y), KERB, 5.0)
			c.rect(Rect2(560.0, ROAD_END_Y - 2.0, 120.0, 10.0), PAVING_JOINT)
		# sidewalk tiles: the joints across, and one down the middle of each
		var jy := floorf(rt / 26.0) * 26.0
		while jy < bot:
			if jy >= rt:
				var e2: Vector2 = m.walk_edges(jy)
				var sw3 := sidewalk(jy)
				c.line(Vector2(e2.x, jy), Vector2(e2.x + sw3 - 3.0, jy), PAVING_JOINT, 1.2)
				c.line(Vector2(e2.y - sw3 + 3.0, jy), Vector2(e2.y, jy), PAVING_JOINT, 1.2)
				# the panot's flower: a small diamond pressed into each tile
				if int(absf(jy) / 26.0) % 2 == 0:
					for x0: float in [e2.x + sw3 * 0.3, e2.x + sw3 * 0.72, e2.y - sw3 * 0.3, e2.y - sw3 * 0.72]:
						var q := Vector2(x0, jy + 13.0)
						c.polygon(PackedVector2Array([q + Vector2(0, -3.5), q + Vector2(3.5, 0), q + Vector2(0, 3.5),
							q + Vector2(-3.5, 0)]), PAVING_JOINT.lightened(0.05))
			jy += 26.0
	# the stadium's paving: big granite slabs with a darker band every few
	var ct := top
	var cb := minf(bot, ROAD_END_Y)
	if cb > ct:
		var cl: Array = _edges_strip(m, ct, cb, 40.0)
		c.polygon(_ribbon(cl[0], cl[1]), CONCOURSE)
		var sy := floorf(ct / 60.0) * 60.0
		while sy < cb:
			if sy >= ct:
				var e3: Vector2 = m.walk_edges(sy)
				var band := int(absf(sy) / 60.0) % 5 == 0
				c.line(Vector2(e3.x, sy), Vector2(e3.y, sy), PAVING_JOINT if not band else Color(0.54, 0.52, 0.50), 1.5 if not band else 6.0)
			sy += 60.0
		var sx := 120.0
		while sx < 1160.0:
			var pts := PackedVector2Array()
			var yy := ct
			while yy <= cb:
				var e4: Vector2 = m.walk_edges(yy)
				if sx > e4.x and sx < e4.y:
					pts.append(Vector2(sx, yy))
				elif pts.size() > 1:
					break
				yy += 60.0
			for i in range(pts.size() - 1):
				c.line(pts[i], pts[i + 1], PAVING_JOINT, 1.5)
			sx += 60.0


static func _draw_markings(m: Node2D, c: ShapeBatch, top: float, bot: float) -> void:
	# the zebra at the corner: bars across the whole road
	if ZEBRA_Y > top - 40.0 and ZEBRA_Y < bot + 40.0:
		var e: Vector2 = m.walk_edges(ZEBRA_Y)
		var sw := sidewalk(ZEBRA_Y)
		var x := e.x + sw + 12.0
		while x < e.y - sw - 20.0:
			c.rect(Rect2(x, ZEBRA_Y - 28.0, 16.0, 56.0), LINE_WHITE)
			x += 32.0
	# the avenue: lane dashes, the painted median between the lamp islands, the
	# blue-zone parking bays along both kerbs, and a drain every so often
	var a0 := maxf(top, AVENUE_Y1)
	var a1 := minf(bot, AVENUE_Y0 - 140.0)
	if a1 > a0:
		var dy := floorf(a0 / 80.0) * 80.0
		while dy < a1:
			for lx: float in [484.0, 796.0]:
				c.rect(Rect2(lx - 2.0, dy, 4.0, 34.0), Color(LINE_WHITE.r, LINE_WHITE.g, LINE_WHITE.b, 0.8))
			dy += 80.0
		# the median: two solid lines and hatching between them
		c.rect(Rect2(624.0, a0, 3.0, a1 - a0), LINE_WHITE)
		c.rect(Rect2(653.0, a0, 3.0, a1 - a0), LINE_WHITE)
		var hy := floorf(a0 / 22.0) * 22.0
		while hy < a1:
			c.line(Vector2(627.0, hy + 16.0), Vector2(653.0, hy), Color(LINE_WHITE.r, LINE_WHITE.g, LINE_WHITE.b, 0.55), 2.5)
			hy += 22.0
		for my: float in MEDIAN_YS:
			if my < a0 - 50.0 or my > a1 + 50.0:
				continue
			# a raised island round each lamp, kerbed
			var isl := Rect2(624.0, my - 40.0, 32.0, 80.0)
			c.polygon(_rr(isl.grow(2.0), 10.0), KERB.darkened(0.15))
			c.polygon(_rr(isl, 9.0), PAVING)
		# blue-zone bays
		for bx: float in [376.0, 904.0]:
			var by := floorf(a0 / 24.0) * 24.0
			while by < a1:
				c.rect(Rect2(bx - 1.5, by, 3.0, 12.0), BLUE_ZONE)
				by += 24.0
			var sy := floorf(a0 / 110.0) * 110.0
			while sy < a1:
				var kx := 330.0 if bx < 640.0 else 950.0
				c.line(Vector2(minf(kx, bx), sy), Vector2(maxf(kx, bx), sy), BLUE_ZONE, 2.0)
				sy += 110.0
		var gy := floorf(a0 / 420.0) * 420.0 + 130.0
		while gy < a1:
			for gx: float in [334.0, 940.0]:
				c.rect(Rect2(gx, gy, 12.0, 30.0), Color(0.18, 0.18, 0.19))
				for k in range(4):
					c.line(Vector2(gx + 1.0, gy + 5.0 + float(k) * 6.0), Vector2(gx + 11.0, gy + 5.0 + float(k) * 6.0),
						Color(0.40, 0.40, 0.42), 1.5)
			gy += 420.0
	# the side street: one lane, a dashed edge line, the parking lane east
	var s0 := maxf(top, STREET_Y1)
	var s1 := minf(bot, m.START_Y + 600.0)
	if s1 > s0:
		var ly := floorf(s0 / 60.0) * 60.0
		while ly < s1:
			c.rect(Rect2(742.0, ly, 3.0, 26.0), Color(LINE_WHITE.r, LINE_WHITE.g, LINE_WHITE.b, 0.7))
			ly += 60.0
	# cast-iron manhole covers in the road, and litter: seed shells round the
	# cart, a squashed cup or two
	for mh: Vector2 in [Vector2(560.0, -560.0), Vector2(720.0, -1780.0), Vector2(540.0, -2900.0)]:
		if mh.y < top - 30.0 or mh.y > bot + 30.0:
			continue
		c.circle(mh, 15.0, Color(0.20, 0.20, 0.21))
		c.circle(mh, 12.5, Color(0.28, 0.28, 0.29))
		for k in range(4):
			c.line(mh + Vector2(-10.0, -6.0 + float(k) * 4.0), mh + Vector2(10.0, -6.0 + float(k) * 4.0), Color(0.22, 0.22, 0.23), 1.2)
	if CART.position.y < bot + 60.0 and CART.end.y > top - 60.0:
		for i in range(26):
			var sp := CART.get_center() + Vector2(fmod(float(i) * 37.0, 120.0) - 20.0, fmod(float(i) * 53.0, 150.0) - 75.0)
			c.circle(sp, 1.6, Color(0.14, 0.13, 0.12, 0.8))


# the steel crowd barriers: a top rail, the joints between sections, a foot
# either side of each joint; a supporters' flag zip-tied on here and there
static func _draw_barriers(c: ShapeBatch, top: float, bot: float) -> void:
	for run: Array in BARRIERS:
		var x := float(run[0])
		var ys := float(run[2])
		var ye := float(run[1])
		if ye < top - 20.0 or ys > bot + 20.0:
			continue
		c.rect(Rect2(x - 1.0, ys + 6.0, 9.0, ye - ys), Color(0, 0, 0, 0.22))
		var k := 0
		var y := ys
		while y < ye:
			var y2 := minf(y + SECTION, ye)
			# the frame from above: two galvanised rails with the uprights
			# between them, and the flat feet where two sections meet
			for rx: float in [x - 3.5, x + 3.5]:
				c.line(Vector2(rx, y + 2.0), Vector2(rx, y2 - 2.0), STEEL.darkened(0.25), 3.0)
				c.line(Vector2(rx - 0.6, y + 2.0), Vector2(rx - 0.6, y2 - 2.0), STEEL.lightened(0.3), 1.2)
			var by := y + 6.0
			while by < y2 - 4.0:
				c.line(Vector2(x - 3.5, by), Vector2(x + 3.5, by), STEEL.darkened(0.15), 1.2)
				by += 5.0
			c.line(Vector2(x - 12.0, y), Vector2(x + 12.0, y), Color(0.28, 0.30, 0.32), 4.0)
			if k % 5 == 2:
				_flag(c, Vector2(x + (8.0 if x < 640.0 else -8.0), y + SECTION * 0.5), 9.0, x < 640.0)
			y = y2
			k += 1
		c.line(Vector2(x - 11.0, ye), Vector2(x + 11.0, ye), Color(0.30, 0.32, 0.34), 4.0)


# a home flag, blue and claret halves with a plain white star, lying out from
# whatever it is tied to (`east` = it hangs out to the east)
static func _flag(c: ShapeBatch, at: Vector2, h: float, east: bool) -> void:
	var w := h * 1.5
	var x0 := at.x if east else at.x - w
	c.rect(Rect2(x0 + 2.0, at.y - h * 0.5 + 2.0, w, h), Color(0, 0, 0, 0.16))
	c.rect(Rect2(x0, at.y - h * 0.5, w * 0.5, h), HOME_BLUE)
	c.rect(Rect2(x0 + w * 0.5, at.y - h * 0.5, w * 0.5, h), HOME_CLARET)
	_star(c, Vector2(x0 + w * 0.5, at.y), h * 0.32, STAR_WHITE)


static func _star(c: ShapeBatch, at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in range(10):
		var a := -PI * 0.5 + PI * float(k) / 5.0
		pts.append(at + Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.45))
	c.polygon(pts, col)


static func _rr(r: Rect2, rad: float) -> PackedVector2Array:
	var k := minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var cs := [Vector2(r.end.x - k, r.position.y + k), Vector2(r.end.x - k, r.end.y - k),
		Vector2(r.position.x + k, r.end.y - k), Vector2(r.position.x + k, r.position.y + k)]
	var pts := PackedVector2Array()
	for ci in range(4):
		for s in range(4):
			pts.append(cs[ci] + Vector2.from_angle(-PI * 0.5 + float(ci) * PI * 0.5 + float(s) * PI / 6.0) * k)
	return pts


static func _box_shadow(c: ShapeBatch, r: Rect2, h: float) -> void:
	c.polygon(_rr(Rect2(r.position + LIGHT * h, r.size).grow(2.0), 6.0), Color(0.05, 0.05, 0.08, 0.10))
	c.polygon(_rr(Rect2(r.position + LIGHT * (h * 0.7), r.size), 5.0), SHADOW)


# Painted words, as the stroke letters the walk's names are made of: batched
# with everything else rather than a draw call each.
static func letters(c: ShapeBatch, txt: String, at: Vector2, h: float, col: Color, w: float, max_w := INF) -> void:
	var lay: Array = Letters.layout(txt, at, h, max_w)
	for pl: PackedVector2Array in lay[0]:
		for i in range(pl.size()):
			c.circle(pl[i], w * 0.5, col)
			if i > 0:
				c.line(pl[i - 1], pl[i], col, w)


# One person from above, standing: a home shirt in halves when `kit`.
static func person(c: ShapeBatch, p: Vector2, face: Vector2, k: int, shirt: Color, kit := false,
		headwear := "none", hcol := Color.BLACK, scarf := Color(0, 0, 0, 0)) -> void:
	c.circle(p + Vector2(3, 4), 10.0, Color(0, 0, 0, 0.16))
	var half := Vector2(8.0, 10.5)
	HumanLook.draw_torso(c, p, face, half, HOME_CLARET if kit else shirt, false, scarf)
	if kit:
		var side := face.orthogonal()
		var pts := PackedVector2Array()
		for i in range(9):
			var t := PI + PI * float(i) / 8.0
			pts.append(p + face * cos(t) * half.x + side * sin(t) * half.y)
		c.polygon(pts, HOME_BLUE)
	HumanLook.draw_head(c, p + face * 3.0, face, 6.0, SKINS[k % SKINS.size()], HAIRS[(k / 2) % HAIRS.size()],
		["short", "bun", "curly", "long", "bald_spot"][k % 5], headwear, hcol)


static func _draw_furniture(m: Node2D, c: ShapeBatch, top: float, bot: float) -> void:
	var vis := func(r: Rect2) -> bool: return r.end.y > top - 80.0 and r.position.y < bot + 80.0
	# the corner: the barrier stubs and CARRER TALLAT
	for i in range(STUBS.size()):
		var s: Rect2 = STUBS[i]
		if not vis.call(s):
			continue
		c.rect(Rect2(s.position + Vector2(3, 4), s.size), Color(0, 0, 0, 0.18))
		c.rect(s, STEEL.darkened(0.15))
		c.rect(Rect2(s.position, Vector2(s.size.x, 2.5)), STEEL.lightened(0.2))
		var fx := s.position.x
		while fx <= s.end.x:
			c.line(Vector2(fx, s.position.y - 7.0), Vector2(fx, s.end.y + 7.0), Color(0.40, 0.42, 0.44), 3.0)
			fx += SECTION
		if i == 0:
			var plate := Rect2(s.get_center().x - 40.0, s.position.y - 30.0, 80.0, 24.0)
			c.rect(Rect2(plate.position + Vector2(2, 3), plate.size), Color(0, 0, 0, 0.2))
			c.rect(plate, Color(0.80, 0.14, 0.14))
			c.rect(plate.grow(-3.0), Color(0.97, 0.96, 0.93))
			letters(c, "CARRER TALLAT", plate.get_center() + Vector2(0, 4.0), 8.0, Color(0.12, 0.12, 0.14), 1.6, 70.0)
	# the officers by their van, chatting
	if vis.call(OFFICERS):
		person(c, OFFICERS.position + Vector2(15, 10), Vector2(0.3, 1).normalized(), 2, POLICE_NAVY, false, "cap", POLICE_NAVY)
		person(c, OFFICERS.position + Vector2(15, 34), Vector2(-0.2, -1).normalized(), 5, POLICE_NAVY, false, "cap", POLICE_NAVY)
	# the parked cars in the side street
	for i in range(CARS.size()):
		if vis.call(CARS[i]):
			_car(c, CARS[i], CAR_COLS[i % CAR_COLS.size()])
	# the grandad in his scarf, out early, by the bench
	if vis.call(GRANDAD):
		person(c, GRANDAD.get_center(), Vector2(-1, 0.2).normalized(), 4, Color(0.42, 0.38, 0.34), false, "beanie",
			HOME_CLARET, HOME_BLUE)
		c.line(GRANDAD.get_center() + Vector2(-12, 4), GRANDAD.get_center() + Vector2(-16, 14), Color(0.30, 0.22, 0.14), 2.0)
	if vis.call(SCARF_STALL):
		_scarf_stall(c, SCARF_STALL)
	if vis.call(CART):
		_cart(c, CART)
	if vis.call(SAUSAGE):
		_sausage_stand(c, SAUSAGE)
	if vis.call(DECK):
		_deck(c, DECK)
		# two regulars at the bar door, glasses of soda in hand
		person(c, REGULARS.position + Vector2(12.0, 16.0), Vector2(1, 0.3).normalized(), 7, Color(0.30, 0.34, 0.30), true)
		person(c, REGULARS.position + Vector2(16.0, 44.0), Vector2(1, -0.4).normalized(), 3, Color(0.70, 0.66, 0.58), false, "none",
			Color.BLACK, HOME_CLARET)
	if vis.call(TAQUILLES):
		_taquilles(c, TAQUILLES)
	if vis.call(DRUM_STAND):
		_drum_stand(c, DRUM_STAND)
	for gy: float in GATE_YS:
		for side: float in [-1.0, 1.0]:
			var r := lane_rect(gy, side)
			if not vis.call(r):
				continue
			c.rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.18))
			c.rect(r, STEEL.darkened(0.15))
			c.rect(Rect2(r.position, Vector2(r.size.x, 2.0)), STEEL.lightened(0.2))
			c.line(Vector2(r.position.x, r.position.y - 6.0), Vector2(r.position.x, r.end.y + 6.0), Color(0.40, 0.42, 0.44), 3.0)


static func _car(c: ShapeBatch, r: Rect2, col: Color) -> void:
	_box_shadow(c, r, 14.0)
	for w: Vector2 in [Vector2(-3, 16), Vector2(r.size.x - 3, 16), Vector2(-3, r.size.y - 30), Vector2(r.size.x - 3, r.size.y - 30)]:
		c.polygon(_rr(Rect2(r.position + w, Vector2(6, 15)), 2.5), Color(0.10, 0.10, 0.12))
	c.polygon(_rr(r, 12.0), col.darkened(0.3))
	c.polygon(_rr(Rect2(r.position, r.size - Vector2(2.5, 2.5)), 12.0), col)
	# windscreen to the north, rear window to the south, the roof between
	c.polygon(PackedVector2Array([r.position + Vector2(6, 22), r.position + Vector2(r.size.x - 6, 22),
		r.position + Vector2(r.size.x - 9, 38), r.position + Vector2(9, 38)]), Color(0.24, 0.30, 0.38))
	c.polygon(PackedVector2Array([r.position + Vector2(9, r.size.y - 30), r.position + Vector2(r.size.x - 9, r.size.y - 30),
		r.position + Vector2(r.size.x - 7, r.size.y - 18), r.position + Vector2(7, r.size.y - 18)]), Color(0.24, 0.30, 0.38))
	c.polygon(_rr(Rect2(r.position + Vector2(8, 40), Vector2(r.size.x - 16, r.size.y - 72)), 6.0), col.lightened(0.08))
	c.line(r.position + Vector2(10, 24), r.position + Vector2(18, 24), Color(1, 1, 1, 0.5), 2.0)


static func _scarf_stall(c: ShapeBatch, r: Rect2) -> void:
	_box_shadow(c, r, 12.0)
	# the trestle table along the front, folded scarves in rows on it
	var table := Rect2(r.position.x, r.position.y + 6.0, 30.0, r.size.y - 12.0)
	c.polygon(_rr(table, 3.0), Color(0.42, 0.32, 0.22))
	c.polygon(_rr(table.grow(-2.0), 2.0), Color(0.86, 0.84, 0.78))
	var y := table.position.y + 6.0
	var k := 0
	while y < table.end.y - 10.0:
		for j in range(2):
			var sr := Rect2(table.position.x + 4.0 + float(j) * 12.0, y, 10.0, 12.0)
			var a := HOME_BLUE if (k + j) % 2 == 0 else HOME_CLARET
			c.rect(sr, a)
			c.rect(Rect2(sr.position.x, sr.position.y + 4.0, sr.size.x, 2.0), STAR_WHITE)
			c.rect(Rect2(sr.position.x, sr.position.y + 8.0, sr.size.x, 2.0), HOME_CLARET if a == HOME_BLUE else HOME_BLUE)
		y += 15.0
		k += 1
	# the rack against the wall, scarves hanging off it in bars
	var rack_x := r.end.x - 10.0
	c.line(Vector2(rack_x, r.position.y + 4.0), Vector2(rack_x, r.end.y - 4.0), Color(0.30, 0.30, 0.32), 3.0)
	var hy := r.position.y + 8.0
	k = 0
	while hy < r.end.y - 10.0:
		c.rect(Rect2(rack_x - 14.0, hy, 14.0, 6.0), HOME_BLUE if k % 2 == 0 else HOME_CLARET)
		c.rect(Rect2(rack_x - 14.0, hy + 2.0, 14.0, 1.5), STAR_WHITE)
		hy += 9.0
		k += 1
	# flags on poles at the front corners
	for fy: float in [r.position.y + 4.0, r.end.y - 4.0]:
		c.circle(Vector2(r.position.x + 2.0, fy), 2.5, Color(0.30, 0.30, 0.32))
		_flag(c, Vector2(r.position.x + 3.0, fy), 10.0, true)
	# the seller, between the table and the rack
	person(c, Vector2(r.position.x + 44.0, r.get_center().y + 10.0), Vector2(-1, 0), 1, Color(0.30, 0.30, 0.34), false,
		"cap", HOME_BLUE, HOME_CLARET)


static func _cart(c: ShapeBatch, r: Rect2) -> void:
	_box_shadow(c, r, 10.0)
	# two wheels, the steel frame, a cool box and the sacks of seeds on top
	for wy: float in [r.position.y + 14.0, r.end.y - 22.0]:
		c.polygon(_rr(Rect2(r.end.x - 4.0, wy, 7.0, 16.0), 2.5), Color(0.10, 0.10, 0.12))
	c.polygon(_rr(r, 4.0), Color(0.52, 0.54, 0.56))
	c.polygon(_rr(r.grow(-3.0), 3.0), Color(0.66, 0.68, 0.70))
	var box := Rect2(r.position.x + 6.0, r.position.y + 8.0, r.size.x - 12.0, 36.0)
	c.polygon(_rr(box, 3.0), Color(0.24, 0.42, 0.74))
	c.polygon(_rr(Rect2(box.position.x + 2.0, box.position.y + 2.0, box.size.x - 4.0, 10.0), 2.0), Color(0.92, 0.92, 0.90))
	for i in range(6):
		var bp := Vector2(r.position.x + 12.0 + float(i % 3) * 13.0, r.end.y - 34.0 + float(i / 3) * 14.0)
		c.polygon(_rr(Rect2(bp, Vector2(11.0, 12.0)), 2.0), Color(0.94, 0.78, 0.22) if i % 2 == 0 else Color(0.90, 0.36, 0.20))
	# its seller, on the road side
	person(c, CART_SELLER.get_center(), Vector2(-1, -0.3).normalized(), 6, Color(0.84, 0.80, 0.70))


static func _sausage_stand(c: ShapeBatch, r: Rect2) -> void:
	_box_shadow(c, r, 18.0)
	# a little trailer kiosk: the roof, its vent, the serving hatch west with
	# its counter and the grill, sausages on it
	c.polygon(_rr(r, 6.0), Color(0.80, 0.78, 0.72))
	c.polygon(_rr(Rect2(r.position + Vector2(18.0, 0.0), r.size - Vector2(18.0, 2.5)), 6.0), Color(0.92, 0.90, 0.84))
	for ry in range(4):
		c.line(Vector2(r.position.x + 22.0, r.position.y + 24.0 + float(ry) * 22.0), Vector2(r.end.x - 4.0, r.position.y + 24.0 + float(ry) * 22.0),
			Color(0.78, 0.76, 0.70), 2.0)
	c.polygon(_rr(Rect2(r.end.x - 30.0, r.position.y + 40.0, 18.0, 18.0), 3.0), Color(0.56, 0.56, 0.58))
	var counter := Rect2(r.position.x, r.position.y + 14.0, 18.0, r.size.y - 28.0)
	c.rect(counter, Color(0.52, 0.30, 0.20))
	var grill := Rect2(counter.position.x + 3.0, counter.position.y + 10.0, 12.0, counter.size.y - 20.0)
	c.rect(grill, Color(0.12, 0.12, 0.13))
	var sy := grill.position.y + 4.0
	while sy < grill.end.y - 4.0:
		c.line(Vector2(grill.position.x + 2.0, sy), Vector2(grill.end.x - 2.0, sy), Color(0.58, 0.26, 0.16), 3.5)
		sy += 7.0
	# the stripe along the side, home colours
	c.rect(Rect2(r.end.x - 6.0, r.position.y + 4.0, 4.0, r.size.y - 8.0), HOME_CLARET)
	c.rect(Rect2(r.end.x - 10.0, r.position.y + 4.0, 4.0, r.size.y - 8.0), HOME_BLUE)


static func _deck(c: ShapeBatch, r: Rect2) -> void:
	# the terrace's timber deck out in the parking lane, planters at its ends
	c.rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.14))
	c.rect(r, Color(0.56, 0.40, 0.26))
	var y := r.position.y + 8.0
	while y < r.end.y:
		c.line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(0.46, 0.32, 0.20), 1.5)
		y += 10.0
	c.line(Vector2(r.end.x - 1.0, r.position.y), Vector2(r.end.x - 1.0, r.end.y), Color(0.24, 0.24, 0.26), 2.5)
	for py: float in [r.position.y, r.end.y - 22.0]:
		c.rect(Rect2(r.position.x + 4.0, py, r.size.x - 8.0, 22.0), Color(0.44, 0.40, 0.36))
		for k in range(4):
			c.circle(Vector2(r.position.x + 12.0 + float(k) * 14.0, py + 11.0), 7.0, Color(0.30, 0.48, 0.26).lightened(float(k % 2) * 0.08))


static func _taquilles(c: ShapeBatch, r: Rect2) -> void:
	_box_shadow(c, r, 24.0)
	# a low concrete block, flat roofed; its windows face the paving, a clerk
	# at each, and the queue's belt barriers in front
	c.rect(r, Color(0.60, 0.58, 0.56))
	c.rect(Rect2(r.position + Vector2(4, 4), r.size - Vector2(10, 8)), Color(0.70, 0.68, 0.65))
	for k in range(4):
		var wy := r.position.y + 26.0 + float(k) * 50.0
		c.rect(Rect2(r.end.x - 6.0, wy, 6.0, 26.0), Color(0.22, 0.30, 0.38))
		c.circle(Vector2(r.end.x - 12.0, wy + 13.0), 5.0, SKINS[k % SKINS.size()])
		var px := r.end.x + 26.0
		c.circle(Vector2(px, wy - 4.0), 3.0, Color(0.20, 0.20, 0.22))
		c.circle(Vector2(px, wy + 34.0), 3.0, Color(0.20, 0.20, 0.22))
		c.line(Vector2(px, wy - 4.0), Vector2(px, wy + 34.0), HOME_CLARET, 2.0)
	c.rect(Rect2(r.position.x, r.position.y, r.size.x, 4.0), Color(0.80, 0.78, 0.74))


static func _drum_stand(c: ShapeBatch, r: Rect2) -> void:
	_box_shadow(c, r, 8.0)
	c.rect(r, Color(0.36, 0.28, 0.20))
	c.rect(r.grow(-3.0), Color(0.50, 0.38, 0.26))
	var y := r.position.y + 10.0
	while y < r.end.y:
		c.line(Vector2(r.position.x + 3.0, y), Vector2(r.end.x - 3.0, y), Color(0.42, 0.32, 0.22), 1.5)
		y += 14.0
	# four drummers in kit and their drums (the sticks are draw_live's)
	for i in range(4):
		var p := drummer(i)
		person(c, p, Vector2(1, 0), i + 2, HOME_CLARET, true)
		var dp := p + Vector2(25.0, 0.0)
		c.circle(dp + LIGHT * 3.0, 11.0, SHADOW)
		c.circle(dp, 11.0, Color(0.70, 0.18, 0.22) if i != 1 else Color(0.20, 0.24, 0.48))
		c.circle(dp, 8.5, Color(0.78, 0.72, 0.60))
		c.circle(dp, 2.0, Color(0.50, 0.44, 0.36))


static func drummer(i: int) -> Vector2:
	return DRUM_STAND.position + Vector2(24.0, 18.0 + float(i) * 28.0)


# The blocks either side: Les Corts' flat roofs (terrats) seen from above,
# with their tanks, lift housings, laundry and aerials, the wall face down to
# the sidewalk, and the block's inner garden further back. On the east side
# past STADIUM_Y0, the stadium instead.
static func _draw_blocks(m: Node2D, c: ShapeBatch, top: float, bot: float) -> void:
	var stop: float = m.GATE_Y - 30.0
	for side: float in [-1.0, 1.0]:
		var k0 := parcel(maxf(top - 200.0, stop), side)
		var k1 := parcel(bot + 200.0, side)
		for k in range(k0, k1 + 1):
			var y0 := float(k) * PARCEL - (0.0 if side < 0.0 else 57.0)
			var y1 := y0 + PARCEL
			y0 = maxf(y0, stop)
			if side > 0.0:
				# north of STADIUM_Y0 the east side is the stadium
				if y1 <= STADIUM_Y0:
					continue
				y0 = maxf(y0, STADIUM_Y0)
			if y1 <= y0:
				continue
			_parcel(m, c, k, side, y0, y1)
	if bot > m.GATE_Y and top < STADIUM_Y0:
		_draw_stadium_side(m, c, top, minf(bot, STADIUM_Y0))


# points along the building line between y0 and y1, pushed `off` into the block
static func _front(m: Node2D, side: float, y0: float, y1: float, off: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := y0
	while true:
		var yy := minf(y, y1)
		var e: Vector2 = m.walk_edges(yy)
		pts.append(Vector2((e.x - off) if side < 0.0 else (e.y + off), yy))
		if yy >= y1:
			break
		y += 20.0
	return pts


static func _band(m: Node2D, c: ShapeBatch, side: float, y0: float, y1: float, a: float, b: float, col: Color) -> void:
	var inner := _front(m, side, y0, y1, a)
	var outer := _front(m, side, y0, y1, b)
	var poly := PackedVector2Array(inner)
	for i in range(outer.size() - 1, -1, -1):
		poly.append(outer[i])
	c.polygon(poly, col)


static func _parcel(m: Node2D, c: ShapeBatch, k: int, side: float, y0: float, y1: float) -> void:
	var roof: Color = ROOF_COLS[int(_h(float(k), side)) % ROOF_COLS.size()]
	# the next street's roofs, the block's inner garden, then this roof
	_band(m, c, side, y0, y1, 560.0, 900.0, roof.darkened(0.12))
	_band(m, c, side, y0, y1, 230.0, 560.0, Color(0.40, 0.48, 0.32))
	_band(m, c, side, y0, y1, 0.0, 230.0, roof)
	# the wall face down to the street, darkest at its foot, and the parapet
	for i in range(4):
		var t := float(i) / 3.0
		_band(m, c, side, y0, y1, 4.0 * float(i), 4.0 * float(i) + 4.5, roof.darkened(0.55 - t * 0.35))
	_band(m, c, side, y0, y1, 16.0, 21.0, roof.lightened(0.25))
	# the garden's trees, now and then
	var h := _h(float(k), side + 3.0)
	var mid := (y0 + y1) * 0.5
	var e: Vector2 = m.walk_edges(mid)
	var line: float = e.x if side < 0.0 else e.y
	var out := side   # away from the street, into the block
	if int(h) % 2 == 1:
		var tp := Vector2(line + out * (320.0 + fmod(h * 4.0, 160.0)), mid)
		c.circle(tp + LIGHT * 14.0, 34.0, SHADOW)
		c.circle(tp, 34.0, Color(0.26, 0.40, 0.22))
		c.circle(tp - LIGHT * 10.0, 20.0, Color(0.34, 0.48, 0.26))
	if y1 - y0 < PARCEL * 0.5:
		return
	# the party wall to the next parcel
	var fy0: Vector2 = m.walk_edges(y0)
	var l0: float = fy0.x if side < 0.0 else fy0.y
	c.line(Vector2(l0 + out * 18.0, y0), Vector2(l0 + out * 230.0, y0), roof.darkened(0.28), 3.0)
	# terrat tiles on some
	if int(h) % 3 == 0:
		var ty := y0 + 10.0
		while ty < y1 - 4.0:
			var et: Vector2 = m.walk_edges(ty)
			var lt: float = et.x if side < 0.0 else et.y
			c.line(Vector2(lt + out * 26.0, ty), Vector2(lt + out * 228.0, ty), roof.darkened(0.08), 1.0)
			ty += 13.0
	# the lift and stair housing, with its shadow
	var hx := line + out * (90.0 + fmod(h * 3.0, 60.0))
	var hb := Rect2(minf(hx, hx + out * 46.0), mid - 20.0 + fmod(h, 20.0) - 10.0, 46.0, 40.0)
	c.rect(Rect2(hb.position + LIGHT * 14.0, hb.size), SHADOW)
	c.rect(hb, roof.lightened(0.12))
	c.rect(Rect2(hb.position, Vector2(hb.size.x, 4.0)), roof.lightened(0.3))
	c.rect(Rect2(hb.position + Vector2(8.0, 12.0), Vector2(14.0, 10.0)), roof.darkened(0.2))
	# the water tank: a drum on legs, on most roofs, wherever it was put
	if int(h * 7.0) % 3 != 1:
		var tp2 := Vector2(line + out * (44.0 + fmod(h * 7.3, 150.0)), y0 + 24.0 + fmod(h * 1.7, PARCEL - 48.0))
		c.circle(tp2 + LIGHT * 9.0, 13.0, SHADOW)
		c.circle(tp2, 13.0, Color(0.80, 0.80, 0.78))
		c.circle(tp2, 10.5, Color(0.88, 0.88, 0.86))
		c.circle(tp2 + Vector2(-3, -3), 5.0, Color(0.95, 0.95, 0.93))
	# an air-conditioning box or two, not on every roof
	for i in range(int(h * 3.1) % 3):
		var ay := y0 + 26.0 + fmod(h * 5.0 + float(i) * 47.0, PARCEL - 52.0)
		var ea: Vector2 = m.walk_edges(ay)
		var ap := Vector2((ea.x if side < 0.0 else ea.y) + out * (34.0 + fmod(h * 9.0 + float(i) * 31.0, 60.0)), ay)
		c.rect(Rect2(ap - Vector2(8, 6) + LIGHT * 4.0, Vector2(16, 12)), SHADOW)
		c.rect(Rect2(ap - Vector2(8, 6), Vector2(16, 12)), Color(0.82, 0.82, 0.80))
		c.circle(ap + Vector2(-2.0, 0.0), 4.0, Color(0.46, 0.46, 0.48))
	# a laundry line, with whatever is drying on it
	if int(h) % 2 == 0:
		var lx := line + out * (160.0 + fmod(h * 2.0, 40.0))
		var ly0 := y0 + 14.0
		var ly1 := y1 - 16.0
		c.line(Vector2(lx, ly0), Vector2(lx, ly1), Color(0.30, 0.30, 0.30), 1.0)
		var wy := ly0 + 8.0
		var j := 0
		var cols: Array[Color] = [Color(0.94, 0.94, 0.92), HOME_CLARET, Color(0.40, 0.56, 0.76), HOME_BLUE, Color(0.90, 0.70, 0.30)]
		while wy < ly1 - 10.0:
			c.rect(Rect2(lx - 5.0, wy, 10.0, 12.0), cols[(j + int(h)) % cols.size()])
			wy += 18.0
			j += 1
	# solar panels on some roofs, a roof garden of pots on others, skylights
	var px0 := line + out * (130.0 + fmod(h * 1.3, 30.0))
	var feat := int(_h(float(k) * 1.7, side + 11.0)) % 5
	if feat == 1:
		for row in range(2):
			for col in range(3):
				var pr := Rect2(minf(px0, px0 + out * 24.0) + out * float(col) * 27.0, y0 + 20.0 + float(row) * 30.0, 24.0, 26.0)
				c.rect(Rect2(pr.position + LIGHT * 4.0, pr.size), SHADOW)
				c.rect(pr, Color(0.18, 0.24, 0.40))
				c.line(Vector2(pr.position.x, pr.get_center().y), Vector2(pr.end.x, pr.get_center().y), Color(0.36, 0.44, 0.62), 1.0)
				c.line(Vector2(pr.get_center().x, pr.position.y), Vector2(pr.get_center().x, pr.end.y), Color(0.36, 0.44, 0.62), 1.0)
	elif feat == 3:
		for i in range(7):
			var gp := Vector2(line + out * (40.0 + fmod(float(i) * 23.0 + h, 120.0)), y0 + 16.0 + float(i) * 14.0)
			c.circle(gp + LIGHT * 3.0, 7.0, SHADOW)
			c.circle(gp, 6.5, Color(0.62, 0.36, 0.24))
			c.circle(gp, 5.0, Color(0.28, 0.46, 0.24).lightened(float(i % 3) * 0.06))
		var awn := Rect2(minf(line + out * 30.0, line + out * 74.0), y1 - 40.0, 44.0, 26.0)
		c.rect(awn, Color(0.92, 0.88, 0.78))
		c.rect(Rect2(awn.position, Vector2(awn.size.x, 4.0)), Color(0.80, 0.30, 0.24))
	else:
		var sk := Rect2(minf(px0, px0 + out * 30.0), y0 + 30.0 + fmod(h * 2.3, 40.0), 30.0, 22.0)
		c.rect(sk, roof.darkened(0.2))
		c.rect(sk.grow(-3.0), Color(0.56, 0.66, 0.72))
		c.line(sk.position + Vector2(5, 5), sk.position + Vector2(14, 5), Color(0.86, 0.92, 0.96, 0.8), 2.0)
	# an aerial
	var ap2 := Vector2(line + out * 120.0, y1 - 30.0)
	c.line(ap2, ap2 + Vector2(out * 30.0, -10.0), Color(0.36, 0.36, 0.38), 2.0)
	for i in range(3):
		var q := ap2 + Vector2(out * (8.0 + float(i) * 8.0), -2.7 * float(i + 1))
		c.line(q + Vector2(0, -7), q + Vector2(0, 7), Color(0.36, 0.36, 0.38), 1.5)
	# BAR LA PENYA's frontage: the door's warm light and the TV through the
	# window (its sign board is overhead)
	if side < 0.0 and mid < BAR_Y1 + 70.0 and mid > BAR_Y0 - 70.0:
		var bl: float = m.walk_edges(-1960.0).x
		c.rect(Rect2(bl - 10.0, -1990.0, 10.0, 34.0), Color(0.96, 0.78, 0.44))
		c.rect(Rect2(bl - 8.0, -1920.0, 8.0, 50.0), Color(0.30, 0.50, 0.80))


const PARCEL := 130.0


static func parcel(y: float, side: float) -> int:
	return int(floorf((y + (0.0 if side < 0.0 else 57.0)) / PARCEL))


static func _h(k: float, salt: float) -> float:
	var n := sin(k * 12.9898 + salt * 78.233) * 43758.5453
	return absf(n - floorf(n)) * 100.0


# The stadium along the east of the approach: its wall face, the gates in it,
# the stair towers, and the huge roof beyond with L'ESTADI painted on it.
static func _draw_stadium_side(m: Node2D, c: ShapeBatch, top: float, bot: float) -> void:
	var t0 := maxf(top, m.GATE_Y - 30.0)
	_band(m, c, 1.0, t0, bot, 86.0, 800.0, Color(0.74, 0.74, 0.73))
	_band(m, c, 1.0, t0, bot, 86.0, 96.0, HOME_CLARET)
	_band(m, c, 1.0, t0, bot, 96.0, 102.0, Color(0.56, 0.56, 0.56))
	_band(m, c, 1.0, t0, bot, 26.0, 86.0, Color(0.62, 0.60, 0.57))
	_band(m, c, 1.0, t0, bot, 0.0, 26.0, Color(0.46, 0.44, 0.43))
	_band(m, c, 1.0, t0, bot, 0.0, 6.0, Color(0.32, 0.31, 0.30))
	# roof ribs, and the stair towers spiralling up the outside
	var ry := floorf(top / 44.0) * 44.0
	while ry < bot:
		var ex2: float = m.walk_edges(ry).y
		c.line(Vector2(ex2 + 104.0, ry), Vector2(ex2 + 700.0, ry), Color(0.62, 0.62, 0.62), 3.0)
		c.line(Vector2(ex2 + 104.0, ry + 3.0), Vector2(ex2 + 700.0, ry + 3.0), Color(0.84, 0.84, 0.83), 1.5)
		ry += 44.0
	var ty := floorf(top / 300.0) * 300.0 + 150.0
	while ty < bot:
		if ty < STADIUM_Y0 - 80.0 and ty > m.GATE_Y + 40.0:
			var tc := Vector2(m.walk_edges(ty).y + 56.0, ty)
			c.circle(tc + LIGHT * 16.0, 34.0, SHADOW)
			c.circle(tc, 34.0, Color(0.44, 0.42, 0.40))
			c.circle(tc, 29.0, Color(0.60, 0.58, 0.55))
			c.circle(tc, 11.0, Color(0.40, 0.38, 0.36))
			for k in range(6):
				var a := float(k) * TAU / 6.0
				c.line(tc + Vector2.from_angle(a) * 12.0, tc + Vector2.from_angle(a + 0.6) * 27.0, Color(0.46, 0.44, 0.42), 2.5)
		ty += 300.0
	# the gates: an opening in the wall, the turnstiles' row, the number
	for i in range(GATE_YS.size()):
		var gy: float = GATE_YS[i]
		if gy < top - 60.0 or gy > bot + 60.0:
			continue
		var ex3: float = m.walk_edges(gy).y
		c.rect(Rect2(ex3, gy - 30.0, 20.0, 60.0), Color(0.14, 0.14, 0.16))
		for k in range(4):
			c.rect(Rect2(ex3 + 4.0, gy - 26.0 + float(k) * 14.0, 10.0, 4.0), STEEL)
		c.rect(Rect2(ex3 + 30.0, gy - 14.0, 52.0, 28.0), HOME_CLARET)
		letters(c, "PORTA " + GATE_NUMS[i], Vector2(ex3 + 56.0, gy + 6.0), 10.0, STAR_WHITE, 2.0, 48.0)
	var ly := -3960.0
	if ly > top - 60.0 and ly < bot + 60.0:
		var lx: float = m.walk_edges(ly).y + 180.0
		letters(c, "L'ESTADI", Vector2(lx, ly + 20.0), 40.0, Color(0.36, 0.36, 0.40), 6.0, 170.0)


# --- drawing: what moves (the world pass) ---------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var t := AnimClock.msec() / 1000.0
	# smoke off the sausage grill, drifting up the street
	if SAUSAGE.end.y > vt - 120.0 and SAUSAGE.position.y < vb + 60.0:
		for i in range(5):
			var f := fmod(t * 0.35 + float(i) * 0.2, 1.0)
			var p := Vector2(SAUSAGE.position.x + 9.0 - f * 30.0 + sin(t * 1.3 + float(i)) * 6.0, SAUSAGE.get_center().y - f * 90.0)
			wc.circle(p, 6.0 + f * 12.0, Color(0.86, 0.86, 0.86, 0.32 * (1.0 - f)))
	# the drummers' sticks, beating
	if DRUM_STAND.end.y > vt - 60.0 and DRUM_STAND.position.y < vb + 60.0:
		for i in range(4):
			var dp := drummer(i) + Vector2(25.0, 0.0)
			for s: float in [-1.0, 1.0]:
				var lift := 0.5 + 0.5 * sin(t * 9.0 + float(i) * 1.7 + (0.0 if s < 0.0 else PI))
				var tip := dp + Vector2(-2.0 + lift * 4.0, s * (3.0 + lift * 5.0))
				wc.line(drummer(i) + Vector2(8.0, s * 7.0), tip, Color(0.86, 0.78, 0.56), 2.0)


# A cast-iron bollard: what a dog marks on a city corner.
static func draw_bollard(wc: ShapeBatch, h: Dictionary) -> void:
	var p: Vector2 = h.pos
	var done: bool = h.done
	wc.circle(p + LIGHT * 7.0, 8.0, SHADOW)
	wc.circle(p, 8.5, Color(0.22, 0.20, 0.18))
	wc.circle(p, 6.5, Color(0.36, 0.30, 0.26) if not done else Color(0.40, 0.36, 0.22))
	wc.circle(p + Vector2(-2, -2), 2.6, Color(0.56, 0.50, 0.44))
	if not done and float(h.progress) > 0.0:
		wc.draw_arc(p, 14.0, -PI / 2.0, -PI / 2.0 + TAU * float(h.progress) / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# The police van at the corner: navy, a light bar on the cab roof and its
# blue lights turning; no insignia.
static func draw_police_van(m: Node2D, wc: ShapeBatch, v: Vector2) -> void:
	var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)
	_box_shadow(wc, body, 24.0)
	for w: Vector2 in [Vector2(-35, -42), Vector2(29, -42), Vector2(-35, 28), Vector2(29, 28)]:
		wc.polygon(_rr(Rect2(v.x + w.x, v.y + w.y, 6.0, 17.0), 2.5), Color(0.10, 0.10, 0.12))
	wc.polygon(_rr(body, 12.0), POLICE_NAVY.darkened(0.3))
	wc.polygon(_rr(Rect2(body.position, body.size - Vector2(3, 3)), 12.0), POLICE_NAVY)
	wc.polygon(_rr(Rect2(body.position + Vector2(8, 36), Vector2(48, 82)), 6.0), Color(0.90, 0.90, 0.88))
	wc.polygon(PackedVector2Array([v + Vector2(-27, -62), v + Vector2(27, -62), v + Vector2(24, -43), v + Vector2(-24, -43)]),
		Color(0.27, 0.35, 0.43))
	wc.rect(Rect2(v.x - 31.0, v.y + 10.0, 61.0, 6.0), Color(0.86, 0.20, 0.18))
	for mx: float in [-1.0, 1.0]:
		wc.polygon(_rr(Rect2(v.x + mx * 38.0 - 3.0, v.y - 52.0, 6.0, 9.0), 2.5), Color(0.20, 0.20, 0.22))
	# the light bar, two blue lamps taking turns
	var ph := fmod(AnimClock.msec() / 260.0, 2.0)
	wc.polygon(_rr(Rect2(v.x - 20.0, v.y - 38.0, 40.0, 10.0), 3.0), Color(0.20, 0.20, 0.24))
	for i in range(2):
		var on := (ph < 1.0) == (i == 0)
		var lp := v + Vector2(-10.0 + float(i) * 20.0, -33.0)
		wc.circle(lp, 5.0, Color(0.30, 0.50, 1.0, 0.95) if on else Color(0.18, 0.26, 0.48))
		if on:
			wc.circle(lp, 14.0, Color(0.36, 0.56, 1.0, 0.22 if not Game.night else 0.4))


# --- drawing: overhead (the cached overhead layer) ------------------------------

# What hangs over the street, above everyone: the balconies with their home
# flags, the banners strung across, bunting over the avenue, and the stalls'
# and the bar's name boards.
static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	var c := ShapeBatch.new(ci)
	# balconies along both fronts, from the start to the stadium
	var y: float = m.START_Y - 40.0
	var k := 0
	while y > PORTES_Y1:
		var e: Vector2 = m.walk_edges(y)
		for side: float in [-1.0, 1.0]:
			if side > 0.0 and y < STADIUM_Y0 + 40.0:
				continue
			var kk := k * 2 + (0 if side < 0.0 else 1)
			if int(_h(float(kk), 9.0)) % 4 == 3:
				continue
			var line: float = e.x if side < 0.0 else e.y
			var slab := Rect2(line if side < 0.0 else line - 14.0, y - 24.0, 14.0, 48.0)
			c.rect(Rect2(slab.position + Vector2(side * -1.0, 0) + LIGHT * 8.0, slab.size), Color(0.05, 0.05, 0.08, 0.14))
			c.rect(slab, Color(0.80, 0.78, 0.72))
			var rail_x: float = slab.end.x - 1.0 if side < 0.0 else slab.position.x + 1.0
			c.line(Vector2(rail_x, slab.position.y), Vector2(rail_x, slab.end.y), Color(0.14, 0.14, 0.16), 2.0)
			for ry in range(5):
				c.circle(Vector2(rail_x, slab.position.y + 4.0 + float(ry) * 9.0), 1.2, Color(0.14, 0.14, 0.16))
			var pick := int(_h(float(kk), 4.0)) % 5
			if pick <= 1:
				_flag(c, Vector2(rail_x, y + 4.0), 14.0, side < 0.0)
			elif pick == 2:
				# a pot of geraniums, as every balcony in the city has
				c.circle(Vector2(slab.get_center().x, y - 10.0), 4.5, Color(0.70, 0.38, 0.24))
				c.circle(Vector2(slab.get_center().x, y - 10.0), 3.0, Color(0.86, 0.18, 0.22))
		y -= 70.0
		k += 1
	# SEMPRE AMB TU, strung across the side street
	_banner(c, m, -260.0, "SEMPRE AMB TU", HOME_BLUE, STAR_WHITE)
	# bunting across the avenue
	for by: float in [-1480.0, -2620.0]:
		var e2: Vector2 = m.walk_edges(by)
		c.line(Vector2(e2.x, by), Vector2(e2.y, by + 10.0), Color(0.24, 0.24, 0.24), 1.5)
		var bx := e2.x + 14.0
		var j := 0
		while bx < e2.y - 14.0:
			var f := (bx - e2.x) / (e2.y - e2.x)
			var q := Vector2(bx, by + 10.0 * f + sin(f * PI) * 14.0)
			c.polygon(PackedVector2Array([q + Vector2(-8, 0), q + Vector2(8, 0), q + Vector2(0, 16)]),
				HOME_BLUE if j % 2 == 0 else HOME_CLARET)
			bx += 26.0
			j += 1
	# FINS AL FINAL, across the stadium's paving from the blocks to its wall
	_banner(c, m, -3540.0, "FINS AL FINAL", HOME_CLARET, STAR_WHITE)
	# the name boards
	_board(c, Vector2(m.walk_edges(-1950.0).x + 20.0, -1950.0), "BAR LA PENYA", 108.0,
		Color(0.16, 0.18, 0.20), Color(0.96, 0.82, 0.46))
	_board(c, Vector2(SCARF_STALL.get_center().x, SCARF_STALL.position.y - 12.0), "BUFANDES", 74.0, HOME_BLUE, STAR_WHITE)
	_board(c, Vector2(SAUSAGE.get_center().x, SAUSAGE.position.y - 12.0), "ENTREPANS", 80.0, Color(0.86, 0.80, 0.66),
		Color(0.40, 0.16, 0.12))
	_board(c, Vector2(CART.get_center().x + 6.0, CART.position.y - 14.0), "PIPES I AIGUA", 86.0, Color(0.94, 0.80, 0.24),
		Color(0.24, 0.18, 0.10))
	_board(c, Vector2(TAQUILLES.get_center().x + 14.0, TAQUILLES.position.y - 12.0), "TAQUILLES", 84.0, HOME_CLARET, STAR_WHITE)
	c.flush()


static func _banner(c: ShapeBatch, m: Node2D, y: float, txt: String, cloth: Color, ink: Color) -> void:
	var e: Vector2 = m.walk_edges(y)
	var mid := (e.x + e.y) * 0.5
	var w := minf(220.0, (e.y - e.x) * 0.5)
	c.line(Vector2(e.x - 6.0, y), Vector2(mid - w * 0.5, y + 6.0), Color(0.20, 0.20, 0.20), 1.5)
	c.line(Vector2(mid + w * 0.5, y + 6.0), Vector2(e.y + 6.0, y), Color(0.20, 0.20, 0.20), 1.5)
	var r := Rect2(mid - w * 0.5, y - 10.0, w, 32.0)
	c.rect(Rect2(r.position + LIGHT * 18.0, r.size), Color(0.05, 0.05, 0.08, 0.14))
	c.rect(r, cloth)
	c.rect(Rect2(r.position, Vector2(r.size.x, 3.0)), cloth.lightened(0.2))
	letters(c, txt, r.get_center() + Vector2(0, 7.0), 14.0, ink, 2.6, w - 20.0)


static func _board(c: ShapeBatch, at: Vector2, txt: String, w: float, bg: Color, ink: Color) -> void:
	var r := Rect2(at.x - w * 0.5, at.y - 9.0, w, 18.0)
	c.rect(Rect2(r.position + LIGHT * 10.0, r.size), Color(0.05, 0.05, 0.08, 0.16))
	c.rect(r.grow(1.5), bg.darkened(0.35))
	c.rect(r, bg)
	letters(c, txt, r.get_center() + Vector2(0, 4.5), 9.0, ink, 1.8, w - 10.0)


# --- drawing: the square and the stadium (the cached freedom layer) -------------

static func draw_freedom(m: Node2D, ci: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var c := ShapeBatch.new()
	_draw_stadium_bowl(m, c, r)
	# the square: granite slabs, the stadium's apron along the top
	c.rect(r, CONCOURSE)
	var gx := r.position.x
	while gx < r.end.x:
		c.line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), PAVING_JOINT, 1.5)
		gx += 60.0
	var gy := r.position.y
	var n := 0
	while gy < r.end.y:
		c.line(Vector2(r.position.x, gy), Vector2(r.end.x, gy), PAVING_JOINT if n % 5 != 0 else Color(0.54, 0.52, 0.50), 1.5 if n % 5 != 0 else 6.0)
		gy += 60.0
		n += 1
	c.circle(r.get_center() + Vector2(-80.0, 40.0), 150.0, Color(0.80, 0.78, 0.72, 0.35))
	# the club shop's shutters down the west side, down for the match; a row of
	# scooters on the east
	var sy := r.position.y + 30.0
	while sy < r.end.y - 60.0:
		var sh := Rect2(r.position.x - 36.0, sy, 36.0, 110.0)
		c.rect(sh, Color(0.56, 0.58, 0.60))
		var ly := sh.position.y + 4.0
		while ly < sh.end.y:
			c.line(Vector2(sh.position.x, ly), Vector2(sh.end.x, ly), Color(0.46, 0.48, 0.50), 1.5)
			ly += 6.0
		c.rect(Rect2(sh.end.x - 4.0, sh.position.y, 4.0, sh.size.y), HOME_CLARET)
		sy += 130.0
	var scy := r.position.y + 90.0
	while scy < r.end.y - 120.0:
		var sp := Vector2(r.end.x - 22.0, scy)
		c.polygon(_rr(Rect2(sp - Vector2(14, 6), Vector2(28, 12)), 5.0), [HOME_BLUE, Color(0.86, 0.86, 0.84), Color(0.20, 0.20, 0.22)][int(scy) % 3])
		c.circle(sp + Vector2(-14, 0), 4.0, Color(0.10, 0.10, 0.12))
		c.circle(sp + Vector2(14, 0), 4.0, Color(0.10, 0.10, 0.12))
		scy += 34.0
	# the plane trees' grates
	for t: Vector2 in m.trees:
		c.rect(Rect2(t - Vector2(22, 22), Vector2(44, 44)), Color(0.52, 0.50, 0.46))
		c.rect(Rect2(t - Vector2(18, 18), Vector2(36, 36)), Color(0.34, 0.27, 0.20))
	# the fountain: a stone basin a dog can get into
	var fr: Rect2 = load("res://world/level_build.gd").placa_fountain(m)
	c.rect(fr.grow(12.0), Color(0.62, 0.60, 0.56))
	c.rect(fr.grow(8.0), Color(0.78, 0.76, 0.70))
	c.rect(fr, Color(0.30, 0.50, 0.58))
	c.rect(Rect2(fr.position, Vector2(fr.size.x, 8.0)), Color(0.22, 0.40, 0.48))
	c.circle(fr.get_center(), 9.0, Color(0.70, 0.68, 0.62))
	c.circle(fr.get_center(), 4.0, Color(0.84, 0.94, 0.98))
	c.flush(ci)
	m._draw_freedom_benches(ci, r, Color(0.36, 0.30, 0.24))
	m._freedom_sign(ci, r, m.gate_text, "goal square, off leash")


# The bowl past the square's top edge: its apron, the outer wall curving away,
# the stair towers, the great roof with its ribs and L'ESTADI on it, the
# stands' tiers inside and the floodlights' glow at night.
static func _draw_stadium_bowl(_m: Node2D, c: ShapeBatch, r: Rect2) -> void:
	var top := r.position.y
	c.rect(Rect2(-400.0, top - 900.0, 2100.0, 900.0), CONCOURSE.darkened(0.06))
	var ctr := Vector2(640.0, top - 1340.0)
	var rings: Array = [[1300.0, 1272.0, Color(0.46, 0.44, 0.43)], [1272.0, 1200.0, Color(0.66, 0.64, 0.61)],
		[1200.0, 960.0, Color(0.88, 0.88, 0.86)], [960.0, 940.0, Color(0.60, 0.60, 0.62)],
		[940.0, 700.0, HOME_CLARET.darkened(0.25)], [700.0, 0.0, Color(0.30, 0.52, 0.28)]]
	var a0 := deg_to_rad(28.0)
	var a1 := deg_to_rad(152.0)
	var steps := 48
	for ring: Array in rings:
		var ro: float = ring[0]
		var ri: float = ring[1]
		for i in range(steps):
			var t0 := lerpf(a0, a1, float(i) / float(steps))
			var t1 := lerpf(a0, a1, float(i + 1) / float(steps))
			c.polygon(PackedVector2Array([ctr + Vector2.from_angle(t0) * ro, ctr + Vector2.from_angle(t1) * ro,
				ctr + Vector2.from_angle(t1) * ri, ctr + Vector2.from_angle(t0) * ri]), ring[2])
	# the stands: blue sections between the claret, and the rows
	for i in range(steps):
		if i % 4 == 1:
			var t0 := lerpf(a0, a1, float(i) / float(steps))
			var t1 := lerpf(a0, a1, float(i + 1) / float(steps))
			c.polygon(PackedVector2Array([ctr + Vector2.from_angle(t0) * 940.0, ctr + Vector2.from_angle(t1) * 940.0,
				ctr + Vector2.from_angle(t1) * 700.0, ctr + Vector2.from_angle(t0) * 700.0]), HOME_BLUE.darkened(0.2))
	# the roof's ribs
	for i in range(0, steps + 1, 2):
		var t := lerpf(a0, a1, float(i) / float(steps))
		c.line(ctr + Vector2.from_angle(t) * 1198.0, ctr + Vector2.from_angle(t) * 962.0, Color(0.74, 0.74, 0.74), 2.5)
	# stair towers round the outside
	for i in range(1, 8):
		var t := lerpf(a0, a1, float(i) / 8.0)
		var tc := ctr + Vector2.from_angle(t) * 1316.0
		c.circle(tc + LIGHT * 16.0, 34.0, SHADOW)
		c.circle(tc, 34.0, Color(0.56, 0.54, 0.52))
		c.circle(tc, 26.0, Color(0.68, 0.66, 0.63))
		c.circle(tc, 10.0, Color(0.50, 0.48, 0.46))
	letters(c, "L'ESTADI", ctr + Vector2(0.0, 1110.0), 54.0, Color(0.36, 0.36, 0.40), 8.0, 300.0)
	if Game.night:
		for i in range(6):
			var t := lerpf(a0, a1, (float(i) + 0.5) / 6.0)
			c.circle(ctr + Vector2.from_angle(t) * 955.0, 70.0, Color(1.0, 0.96, 0.80, 0.18))
			c.circle(ctr + Vector2.from_angle(t) * 955.0, 22.0, Color(1.0, 0.98, 0.90, 0.6))
