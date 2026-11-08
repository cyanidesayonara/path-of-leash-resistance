class_name Angels
extends RefCounted

# WALK 32: ELS ÀNGELS (Plaça dels Àngels in El Raval)
#
# The wide open stone plaza outside a monumental white modernist museum with a
# long glass curtain wall and an inclined access ramp, opposite the 16th-century
# sandstone Convent dels Àngels chapel. Narrow Raval alleys lead in from the
# south and pinch again at the north end toward the historic university cloister
# courtyard (Claustre de les Lletres, off leash).
#
# Hallmarks of Els Àngels:
# - Path shape: narrow Raval street at the start, bulging wide into the open
#   granite skate plaza, and pinching back into a narrow Raval street at the gate.
# - Real grindables (systems/rails.gd): the museum's two long low granite skate
#   ledges, the podium stair-set steel handrail, and the east convent stone ledge.
# - Street skaters cruising the plaza slabs, lamp posts to wrap, and spare
#   skateboards resting by the ledges to sniff.
# - Signature live event: AngelsSkate (systems/angels_skate.gd) — a skater bails
#   with a 0.8 s "Board!" warning and their runaway board shoots across the plaza.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const AngelsSkate := preload("res://systems/angels_skate.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.07, 0.24)

# --- colors ------------------------------------------------------------------
const GRANITE_LIGHT := Color(0.74, 0.73, 0.70)
const GRANITE_MID := Color(0.68, 0.67, 0.64)
const GRANITE_DARK := Color(0.56, 0.55, 0.52)
const GRANITE_JOINT := Color(0.46, 0.45, 0.43)
const RAVAL_SETT := Color(0.58, 0.55, 0.50)
const RAVAL_CURB := Color(0.48, 0.46, 0.42)

# White modernist museum palette (west side of plaza)
const MUSEUM_WHITE := Color(0.95, 0.96, 0.97)
const MUSEUM_SHADE := Color(0.84, 0.86, 0.89)
const MUSEUM_DEEP := Color(0.70, 0.73, 0.77)
const MUSEUM_GLASS := Color(0.36, 0.52, 0.64, 0.88)
const MUSEUM_GLASS_DARK := Color(0.20, 0.30, 0.40, 0.92)
const MUSEUM_GLINT := Color(0.88, 0.95, 1.0, 0.55)
const PODIUM_STONE := Color(0.78, 0.77, 0.74)
const LEDGE_GRANITE := Color(0.62, 0.61, 0.58)
const LEDGE_WAX := Color(0.92, 0.90, 0.82, 0.80)
const RAIL_STEEL := Color(0.86, 0.88, 0.92)

# 16th-century Convent dels Àngels palette (east side of plaza)
const CONVENT_STONE := Color(0.76, 0.66, 0.52)
const CONVENT_DARK := Color(0.56, 0.47, 0.36)
const CONVENT_ROOF := Color(0.64, 0.38, 0.26)
const CONVENT_ROOF_DARK := Color(0.48, 0.28, 0.19)
const ROSE_GLASS := Color(0.32, 0.24, 0.36)

# Raval apartments & cloister palette
const RAVAL_OCHRE := Color(0.78, 0.64, 0.46)
const RAVAL_TERRA := Color(0.72, 0.44, 0.34)
const RAVAL_SLATE := Color(0.52, 0.54, 0.56)
const CLOISTER_STONE := Color(0.82, 0.74, 0.60)
const CLOISTER_ARCH := Color(0.66, 0.58, 0.46)
const ORANGE_LEAF := Color(0.26, 0.46, 0.24)
const ORANGE_FRUIT := Color(0.94, 0.54, 0.16)
const BENCH_STONE := Color(0.64, 0.62, 0.58)

# Skate & furniture palette
const LAMP_IRON := Color(0.20, 0.22, 0.25)
const LAMP_WARM := Color(1.0, 0.86, 0.48, 0.26)
const DECK_MAPLE := Color(0.84, 0.66, 0.42)
const DECK_GRIP := Color(0.16, 0.17, 0.19)
const CHURRO_GOLD := Color(0.84, 0.58, 0.24)
const CHURRO_SUGAR := Color(0.96, 0.92, 0.82)

# --- layout constants --------------------------------------------------------
const HALF := 420.0
const WALL_L := 220.0
const WALL_R := 1060.0

# Solid stone blocks inside the plaza (kept well clear of the grindable rail lines
# at x = 340, x = 450, and x = 920 so zoomie grinds are never obstructed)
const MUSEUM_PODIUM_S := Rect2(250.0, -1780.0, 64.0, 150.0)
const MUSEUM_PODIUM_N := Rect2(250.0, -2960.0, 64.0, 150.0)
const CONVENT_PLINTH := Rect2(960.0, -2560.0, 64.0, 130.0)
# Plane trees in square concrete planters, and a bike rack by the convent: solid,
# and the rope wraps them. Clear of the rail lines and of the runaway board's
# crossing at y = -2400.
const PLANTERS: Array[Rect2] = [
	Rect2(972.0, -1596.0, 64.0, 64.0),
	Rect2(972.0, -3116.0, 64.0, 64.0),
	Rect2(728.0, -2012.0, 64.0, 64.0),
	Rect2(528.0, -2812.0, 64.0, 64.0),
]
const BIKE_RACK := Rect2(1000.0, -2880.0, 46.0, 120.0)

# Plaza lamp posts and stone bollards for leash wrapping
const LAMP_POSTS: Array[Vector2] = [
	Vector2(455.0, -550.0),
	Vector2(825.0, -550.0),
	Vector2(510.0, -1520.0),
	Vector2(860.0, -1520.0),
	Vector2(540.0, -2250.0),
	Vector2(860.0, -2250.0),
	Vector2(510.0, -3100.0),
	Vector2(860.0, -3100.0),
	Vector2(455.0, -4250.0),
	Vector2(825.0, -4250.0),
]

# Five skateboards left on the ground around the plaza (hyd_list / sniff spots)
const DECK_SPOTS: Array[Vector2] = [
	Vector2(465.0, -720.0),
	Vector2(380.0, -1680.0),
	Vector2(885.0, -2080.0),
	Vector2(380.0, -2840.0),
	Vector2(815.0, -4120.0),
]

# Dropped churro snacks in paper cones
const CHURRO_SPOTS: Array[Vector2] = [
	Vector2(590.0, -820.0),
	Vector2(660.0, -1760.0),
	Vector2(580.0, -2880.0),
	Vector2(650.0, -4080.0),
]

# Walk prize: a warm bag of churros left on the stone bench outside the convent
const PRIZE := Vector2(820.0, -3420.0)
const PRIZE_TEXT := "snatch the churro bag off the plaza ledge"


static func edge_nodes(m: Node2D) -> Array:
	var start_y: float = float(m.START_Y) if "START_Y" in m else 260.0
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	return [
		{"y": start_y, "cx": 640.0, "half": 215.0},
		{"y": -420.0, "cx": 640.0, "half": 215.0},
		{"y": -900.0, "cx": 640.0, "half": 225.0},
		{"y": -1280.0, "cx": 640.0, "half": 420.0},
		{"y": -2400.0, "cx": 640.0, "half": 420.0},
		{"y": -3520.0, "cx": 640.0, "half": 420.0},
		{"y": -3900.0, "cx": 640.0, "half": 225.0},
		{"y": -4450.0, "cx": 640.0, "half": 215.0},
		{"y": gate_y + 120.0, "cx": 640.0, "half": 215.0},
		{"y": gate_y, "cx": 640.0, "half": 215.0},
	]


static func build(m: Node2D) -> Array:
	m.gate_text = "CLAUSTRE DE LES LLETRES"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 440.0
	m.gate_r = 840.0

	for p: Vector2 in LAMP_POSTS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	for r: Rect2 in [MUSEUM_PODIUM_S, MUSEUM_PODIUM_N, CONVENT_PLINTH]:
		m.poles.append(Vector2(r.position.x + 8.0, r.get_center().y))
		m.poles.append(Vector2(r.end.x - 8.0, r.get_center().y))

	m.benches = Array([
		Vector2(455.0, -1040.0),
		Vector2(885.0, -1720.0),
		Vector2(885.0, -3320.0),
		Vector2(455.0, -4020.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(445.0, -640.0),
		Vector2(895.0, -1420.0),
		Vector2(895.0, -2960.0),
		Vector2(825.0, -4340.0),
	], TYPE_VECTOR2, &"", null)

	if "fountains" in m:
		m.fountains = Array([
			Vector2(890.0, -1340.0),
			Vector2(450.0, -3780.0),
		], TYPE_VECTOR2, &"", null)

	var hyd_list: Array[Vector2] = []
	for dp: Vector2 in DECK_SPOTS:
		hyd_list.append(dp)

	var keb_list: Array[Vector2] = []
	for cp: Vector2 in CHURRO_SPOTS:
		keb_list.append(cp)

	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT

	m.angels_skate = AngelsSkate.new()
	m.angels_ledge_ground = false
	m.angels_decks_sniffed = 0
	m.angels_decks_visited = {}
	m.angels_churro_stolen = false
	m.angels_lamps_wrapped = {}

	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = [MUSEUM_PODIUM_S, MUSEUM_PODIUM_N, CONVENT_PLINTH, BIKE_RACK]
	out.append_array(PLANTERS)
	return out


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


static func tree_kind(_m: Node2D, _p: Vector2) -> int:
	return 0


static func tick(m: Node2D, delta: float) -> void:
	if m.angels_skate != null:
		m.angels_skate.tick(m, delta)

	# Goal 1: Grind a museum ledge (or handrail)
	if not m.angels_ledge_ground:
		if m.grinds_landed > 0 or (m.grind != null and m.grind.active):
			m.angels_ledge_ground = true

	# Goal 2: Sniff 3 skateboards left on the ground
	var sniff_done := 0
	for h in m.hydrants:
		if typeof(h) == TYPE_DICTIONARY and bool(h.get("done", false)):
			sniff_done += 1
	var dog_p: Vector2 = m.dog.global_position
	for i in range(DECK_SPOTS.size()):
		if dog_p.distance_to(DECK_SPOTS[i]) <= 36.0 and not m.angels_decks_visited.has(i):
			m.angels_decks_visited[i] = true
			if m.angels_decks_visited.size() == 3:
				m.combo.add("DECK INSPECTOR", 2)
				m.float_text(dog_p + Vector2(0.0, -28.0), "deck inspector! +2", Color(0.42, 0.88, 0.96))
	m.angels_decks_sniffed = maxi(sniff_done, m.angels_decks_visited.size())

	# Goal 3: wrap the leash round three of the plaza's lamp posts (the
	# pole the rope is wound on, as Port's bollards and Reial's Gaudi posts)
	if "leash" in m and m.leash != null:
		var pole: Vector2 = m.leash.contact_pole
		if pole.x < INF and int(m.leash.static_contacts) > 0 and bool(m.leash.contact_static):
			var li := LAMP_POSTS.find(pole)
			if li >= 0 and not m.angels_lamps_wrapped.has(li):
				m.angels_lamps_wrapped[li] = true
				m.combo.add("LAMP WRAP", 1)
				m.float_text(pole + Vector2(0.0, -26.0), "wrapped! +1", Color(0.96, 0.86, 0.44))


static func on_bark(m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	if m.angels_skate != null:
		return m.angels_skate.on_bark(m)
	return false


# --- edge layer: white modernist museum, Convent dels Àngels, Raval blocks ---

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	var start_y: float = float(m.START_Y) if "START_Y" in m else 260.0
	var y_top := maxf(vt - 280.0, gate_y - 30.0)
	var y_bot := minf(vb + 280.0, start_y + 560.0)
	if y_bot <= y_top:
		return

	# Base dark urban block fill outside the corridor
	b.rect(Rect2(-460.0, y_top, 1100.0, y_bot - y_top), Color(0.24, 0.22, 0.20))
	b.rect(Rect2(640.0, y_top, 1120.0, y_bot - y_top), Color(0.24, 0.22, 0.20))

	# 1. South and North narrow Raval street apartment blocks
	_draw_raval_flanks(m, b, maxf(y_top, -1180.0), y_bot)
	_draw_raval_flanks(m, b, y_top, minf(y_bot, -3620.0))

	# 2. West side of the plaza (y = -3620 .. -1180): the big white modernist museum
	if y_top < -1140.0 and y_bot > -3660.0:
		_draw_white_museum(b, y_top, y_bot)

	# 3. East side of the plaza (y = -3620 .. -1180): Convent dels Àngels & Raval facades
	if y_top < -1140.0 and y_bot > -3660.0:
		_draw_convent_east(b, y_top, y_bot)

	# where the street widens into the plaza, the building fronts step out to
	# the walk's edge: no gap of bare block between
	for span: Vector2 in [Vector2(-1290.0, -1170.0), Vector2(-3630.0, -3510.0)]:
		var yy := maxf(span.x, y_top)
		while yy < minf(span.y, y_bot):
			var e: Vector2 = m.walk_edges(yy + 5.0) if m.has_method("walk_edges") else Vector2(WALL_L, WALL_R)
			if e.x > WALL_L:
				b.rect(Rect2(WALL_L, yy, e.x - WALL_L, 10.0), MUSEUM_SHADE)
			if e.y < WALL_R:
				b.rect(Rect2(e.y, yy, WALL_R - e.y, 10.0), RAVAL_TERRA.darkened(0.30))
			yy += 10.0


static func _h(k: int) -> float:
	return fposmod(sin(float(k) * 12.9898 + 4.1) * 43758.5453, 1.0)


# Narrow Raval houses, one lot every RAVAL_LOT px, each its own color and roof:
# a terracotta pitched roof, or a flat terrat with washing, a water tank and a
# stair hut. The street face is a strip of balconies with iron rails and pots.
const RAVAL_LOT := 84.0
const RAVAL_WALLS: Array[Color] = [
	Color(0.80, 0.66, 0.48), Color(0.74, 0.46, 0.36), Color(0.62, 0.64, 0.62),
	Color(0.86, 0.78, 0.62), Color(0.70, 0.56, 0.62), Color(0.58, 0.66, 0.70),
]
const WASHING: Array[Color] = [
	Color(0.94, 0.94, 0.92), Color(0.86, 0.30, 0.26), Color(0.28, 0.48, 0.76),
	Color(0.96, 0.80, 0.30), Color(0.42, 0.68, 0.46), Color(0.92, 0.56, 0.70),
]


static func _draw_raval_flanks(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	if bot <= top:
		return
	var sy := floorf(top / RAVAL_LOT) * RAVAL_LOT
	while sy < bot:
		var r0 := maxf(sy, top)
		var r1 := minf(sy + RAVAL_LOT, bot)
		if r1 - r0 >= 8.0:
			# reach the walk's edge across the whole lot (the ground is drawn
			# over this layer), so a lot where the street widens leaves no gap
			var e := Vector2(425.0, 855.0)
			if m.has_method("walk_edges"):
				var ea: Vector2 = m.walk_edges(r0)
				var eb: Vector2 = m.walk_edges(r1)
				e = Vector2(maxf(ea.x, eb.x), minf(ea.y, eb.y))
			var k := int(floorf(sy / RAVAL_LOT))
			_draw_raval_house(b, Rect2(-420.0, r0, e.x + 420.0, r1 - r0), -1.0, k * 7 + 1)
			_draw_raval_house(b, Rect2(e.y, r0, 1720.0 - e.y, r1 - r0), 1.0, k * 7 + 4)
		sy += RAVAL_LOT


static func _draw_raval_house(b: ShapeBatch, r: Rect2, side: float, k: int) -> void:
	var wall_c: Color = RAVAL_WALLS[int(_h(k) * 997.0) % RAVAL_WALLS.size()]
	var inner_x := r.end.x if side < 0.0 else r.position.x
	var face := 22.0
	# party wall between lots
	b.rect(r, wall_c.darkened(0.42))
	var body := Rect2(r.position.x, r.position.y + 2.0, r.size.x, maxf(r.size.y - 4.0, 1.0))
	# the street face, foreshortened: balconies stacked floor over floor
	var fx := (inner_x - face) if side < 0.0 else inner_x
	b.rect(Rect2(fx, body.position.y, face, body.size.y), wall_c.darkened(0.22))
	var wy := body.position.y + 10.0
	var wn := 0
	while wy + 22.0 < body.end.y:
		var wx := fx + 4.0
		# shutter pair either side of a dark balcony door
		b.rect(Rect2(wx, wy, 14.0, 20.0), Color(0.16, 0.15, 0.15))
		var shut := Color(0.24, 0.42, 0.34) if (k + wn) % 3 != 0 else Color(0.52, 0.30, 0.22)
		b.rect(Rect2(wx, wy - 2.0, 14.0, 3.0), shut)
		b.rect(Rect2(wx, wy + 19.0, 14.0, 3.0), shut)
		# iron balcony rail on the street side, a pot on some
		var rx := (fx + 1.0) if side > 0.0 else (fx + face - 3.0)
		b.rect(Rect2(rx, wy - 3.0, 2.0, 26.0), Color(0.12, 0.13, 0.14))
		if _h(k * 13 + wn) > 0.55:
			b.circle(Vector2(rx + 1.0, wy + 4.0), 3.2, Color(0.30, 0.52, 0.26))
			b.circle(Vector2(rx + 1.0, wy + 3.0), 1.6, Color(0.90, 0.30, 0.34))
		wy += 32.0
		wn += 1
	# cornice between the face and the roof
	var cx := (fx - 3.0) if side < 0.0 else (fx + face)
	b.rect(Rect2(cx, body.position.y, 3.0, body.size.y), wall_c.lightened(0.18))
	# the roof, out to the block's far side
	var roof := Rect2(r.position.x, body.position.y, r.size.x - face - 3.0, body.size.y) if side < 0.0 \
		else Rect2(fx + face + 3.0, body.position.y, r.end.x - fx - face - 3.0, body.size.y)
	if roof.size.x <= 4.0 or roof.size.y <= 4.0:
		return
	var kind := int(_h(k * 19 + 5) * 3.0)
	if kind == 0:
		# terracotta pitched roof: tile courses across the lot, a ridge along it
		var tile := Color(0.70, 0.40, 0.28).lerp(wall_c, 0.15)
		b.rect(roof, tile)
		var mid := roof.position.y + roof.size.y * 0.5
		b.rect(Rect2(roof.position.x, mid, roof.size.x, roof.end.y - mid), tile.darkened(0.16))
		var tx := roof.position.x + 3.0
		while tx < roof.end.x:
			b.line(Vector2(tx, roof.position.y + 2.0), Vector2(tx, roof.end.y - 2.0), tile.darkened(0.30), 1.2)
			tx += 7.0
		b.line(Vector2(roof.position.x, mid), Vector2(roof.end.x, mid), tile.lightened(0.22), 2.4)
	else:
		# flat terrat: clay tiles in a grid, a parapet, a stair hut and a tank
		var tc := Color(0.78, 0.66, 0.54) if kind == 1 else Color(0.70, 0.68, 0.64)
		b.rect(roof, wall_c.lightened(0.10))
		var inner := roof.grow(-4.0)
		b.rect(inner, tc)
		var gx := inner.position.x + 12.0
		while gx < inner.end.x:
			b.line(Vector2(gx, inner.position.y), Vector2(gx, inner.end.y), tc.darkened(0.10), 1.0)
			gx += 12.0
		var gy := inner.position.y + 12.0
		while gy < inner.end.y:
			b.line(Vector2(inner.position.x, gy), Vector2(inner.end.x, gy), tc.darkened(0.10), 1.0)
			gy += 12.0
		var near := (inner.end.x - 46.0) if side < 0.0 else (inner.position.x + 30.0)
		# stair hut with its shadow
		var hut := Rect2(near - 8.0 + side * 30.0, inner.position.y + 6.0, 26.0, minf(30.0, inner.size.y - 12.0))
		if hut.size.y > 8.0:
			b.rect(Rect2(hut.position + LIGHT * 6.0, hut.size), SHADOW)
			b.rect(hut, wall_c.lightened(0.04))
			b.rect(Rect2(hut.position.x, hut.position.y, hut.size.x, 5.0), wall_c.darkened(0.12))
		# water tank or a dish
		var tp := Vector2(near + side * 82.0, inner.end.y - 16.0)
		if tp.y > inner.position.y + 8.0:
			b.circle(tp + LIGHT * 4.0, 9.0, SHADOW)
			b.circle(tp, 8.5, Color(0.64, 0.68, 0.70))
			b.circle(tp - LIGHT * 2.0, 5.0, Color(0.78, 0.82, 0.84))
		# a washing line with the week's laundry
		if kind == 1 and inner.size.y > 30.0:
			var ly := inner.position.y + inner.size.y * 0.5 + 6.0
			var la := near - side * 4.0
			var lb := la - side * 70.0
			var lx0 := minf(la, lb)
			var lx1 := maxf(la, lb)
			b.line(Vector2(lx0, ly), Vector2(lx1, ly), Color(0.86, 0.86, 0.84), 1.0)
			var px := lx0 + 4.0
			var pi := 0
			while px < lx1 - 8.0:
				var wc: Color = WASHING[(k + pi) % WASHING.size()]
				var pw := 7.0 + 4.0 * _h(k * 5 + pi)
				b.rect(Rect2(px, ly - 1.0, pw, 9.0 + 4.0 * _h(k + pi * 3)), wc)
				px += pw + 3.0
				pi += 1
		else:
			# planters along the parapet
			for pp in range(3):
				var py := inner.position.y + 8.0 + float(pp) * (inner.size.y - 16.0) * 0.5
				var ppx := (inner.position.x + 6.0) if side > 0.0 else (inner.end.x - 6.0)
				b.circle(Vector2(ppx, py), 4.5, Color(0.30, 0.50, 0.28))


static func _draw_white_museum(b: ShapeBatch, vt: float, vb: float) -> void:
	var m_top := -3620.0
	var m_bot := -1180.0
	if m_bot < vt or m_top > vb:
		return
	var y0 := maxf(m_top, vt - 60.0)
	var y1 := minf(m_bot, vb + 60.0)

	# The white museum fills the whole west side of the plaza. Read from the
	# far side in: a low roof with skylight strips, the taller gallery volume
	# casting its shadow, a band of white sun louvers, and the glass atrium
	# facing the plaza with the white ramps zigzagging up behind it.
	var body := Rect2(-420.0, m_top, WALL_L + 420.0, m_bot - m_top)
	b.rect(body, MUSEUM_WHITE)
	# the low roof's grey membrane inside a white parapet
	b.rect(Rect2(-420.0, m_top + 10.0, 450.0, (m_bot - m_top) - 20.0), Color(0.76, 0.78, 0.80))

	# low roof: panel grid and long skylight strips
	var py := floorf(y0 / 48.0) * 48.0
	while py < y1:
		if py > m_top + 6.0 and py < m_bot - 6.0:
			b.line(Vector2(-420.0, py), Vector2(30.0, py), Color(0.70, 0.72, 0.75), 1.2)
		py += 48.0
	var sk := m_top + 90.0
	while sk < m_bot - 120.0:
		if sk + 140.0 >= y0 and sk <= y1:
			b.rect(Rect2(-40.0, sk, 18.0, 140.0), MUSEUM_GLASS_DARK)
			b.rect(Rect2(-38.0, sk + 2.0, 14.0, 136.0), MUSEUM_GLASS)
			b.line(Vector2(-36.0, sk + 10.0), Vector2(-26.0, sk + 40.0), MUSEUM_GLINT, 1.6)
			# a plant box on the roof beside it
			b.rect(Rect2(-6.0, sk + 30.0, 22.0, 30.0), Color(0.78, 0.80, 0.82))
			b.rect(Rect2(-3.0, sk + 33.0, 16.0, 24.0), Color(0.62, 0.64, 0.66))
		sk += 260.0

	# the taller gallery volume (x = 40 .. 132): brighter, edged, casting a
	# shadow band over the louvers in the sun's direction
	var gal := Rect2(28.0, m_top + 60.0, 92.0, (m_bot - m_top) - 300.0)
	b.rect(Rect2(gal.position + Vector2(-16.0, 0.0), Vector2(16.0, gal.size.y)), Color(0.86, 0.88, 0.90))
	b.rect(Rect2(gal.position + Vector2(14.0, 24.0), gal.size), Color(0.22, 0.26, 0.34, 0.42))
	b.rect(gal, Color(0.99, 0.99, 1.0))
	b.rect(Rect2(gal.position.x, gal.position.y, 3.0, gal.size.y), MUSEUM_DEEP)
	b.rect(Rect2(gal.end.x - 3.0, gal.position.y, 3.0, gal.size.y), MUSEUM_DEEP)
	b.rect(Rect2(gal.position.x, gal.position.y, gal.size.x, 3.0), MUSEUM_DEEP)
	var rl := floorf(maxf(gal.position.y, y0) / 64.0) * 64.0 + 20.0
	while rl < minf(gal.end.y - 20.0, y1):
		if rl > gal.position.y + 16.0:
			b.rect(Rect2(gal.position.x + 14.0, rl, 64.0, 22.0), MUSEUM_DEEP)
			b.rect(Rect2(gal.position.x + 17.0, rl + 3.0, 58.0, 16.0), MUSEUM_GLASS)
			b.line(Vector2(gal.position.x + 20.0, rl + 5.0), Vector2(gal.position.x + 34.0, rl + 17.0), MUSEUM_GLINT, 2.0)
		rl += 64.0

	# white sun louvers (x = 120 .. 140), blades across, shade between
	b.rect(Rect2(120.0, y0, 20.0, y1 - y0), MUSEUM_DEEP)
	var lv := floorf(y0 / 9.0) * 9.0
	while lv < y1:
		b.rect(Rect2(120.0, lv, 20.0, 5.0), MUSEUM_WHITE)
		lv += 9.0

	# the glass atrium (x = 140 .. 194) with the ramps behind it
	var gl := Rect2(140.0, m_top + 40.0, 54.0, (m_bot - m_top) - 80.0)
	b.rect(Rect2(gl.position.x, maxf(gl.position.y, y0), gl.size.x, minf(gl.end.y, y1) - maxf(gl.position.y, y0)), MUSEUM_GLASS_DARK)
	var ry := m_top + 120.0
	var rk := 0
	while ry < m_bot - 260.0:
		if ry + 300.0 >= y0 and ry <= y1:
			# one ramp run, its landing, and the next run back the other way
			var xa := gl.position.x + 6.0
			var xb := gl.end.x - 6.0
			var rw := 24.0
			var rc := Color(0.94, 0.95, 0.97)
			if rk % 2 == 0:
				b.quad(Vector2(xa, ry + 22.0), Vector2(xa + rw, ry + 22.0), Vector2(xb, ry + 230.0), Vector2(xb - rw, ry + 230.0), rc)
				b.line(Vector2(xa + rw, ry + 22.0), Vector2(xb, ry + 230.0), MUSEUM_DEEP, 2.0)
			else:
				b.quad(Vector2(xb - rw, ry + 22.0), Vector2(xb, ry + 22.0), Vector2(xa + rw, ry + 230.0), Vector2(xa, ry + 230.0), rc)
				b.line(Vector2(xb - rw, ry + 22.0), Vector2(xa, ry + 230.0), MUSEUM_DEEP, 2.0)
			b.rect(Rect2(xa, ry + 228.0, xb - xa, 24.0), MUSEUM_SHADE)
			b.rect(Rect2(xa, ry + 228.0, xb - xa, 4.0), MUSEUM_WHITE)
			# a visitor or two on the ramp, seen through the glass
			var vp := Vector2(lerpf(xa + rw * 0.5, xb - rw * 0.5, 0.4 if rk % 2 == 0 else 0.6), ry + 22.0 + 208.0 * 0.4)
			b.circle(vp, 4.5, SKATER_SHIRTS[rk % SKATER_SHIRTS.size()].darkened(0.2))
			b.circle(vp, 2.6, SKIN[rk % SKIN.size()].darkened(0.2))
		ry += 250.0
		rk += 1
	# glass over it all: a tint, mullions, sky glints
	b.rect(Rect2(gl.position.x, maxf(gl.position.y, y0), gl.size.x, minf(gl.end.y, y1) - maxf(gl.position.y, y0)), Color(0.42, 0.62, 0.78, 0.30))
	var my := floorf(maxf(gl.position.y, y0) / 44.0) * 44.0
	while my < minf(gl.end.y, y1):
		if my >= gl.position.y:
			b.line(Vector2(gl.position.x, my), Vector2(gl.end.x, my), Color(0.94, 0.96, 0.98), 2.0)
			if int(absf(my / 44.0)) % 3 == 0:
				b.line(Vector2(gl.position.x + 8.0, my + 6.0), Vector2(gl.position.x + 26.0, my + 38.0), MUSEUM_GLINT, 3.0)
		my += 44.0
	b.line(Vector2(gl.position.x + gl.size.x * 0.5, maxf(gl.position.y, y0)), Vector2(gl.position.x + gl.size.x * 0.5, minf(gl.end.y, y1)), Color(0.90, 0.93, 0.96), 1.4)
	# the white roof edge cantilevered over the atrium, the face the plaza sees
	b.rect(Rect2(194.0, y0, WALL_L - 194.0, y1 - y0), Color(0.99, 0.99, 1.0))
	b.rect(Rect2(194.0, y0, 3.0, y1 - y0), MUSEUM_DEEP)
	var fj := floorf(y0 / 120.0) * 120.0
	while fj < y1:
		b.line(Vector2(197.0, fj), Vector2(WALL_L, fj), MUSEUM_SHADE, 1.5)
		fj += 120.0

	# the white drum at the south end, where the street opens into the plaza
	var drum := Vector2(70.0, -1440.0)
	if drum.y + 120.0 >= vt and drum.y - 120.0 <= vb:
		b.circle(drum + Vector2(14.0, 22.0), 104.0, Color(0.30, 0.34, 0.40, 0.30))
		b.circle(drum, 104.0, MUSEUM_SHADE)
		b.circle(drum - Vector2(6.0, 9.0), 96.0, Color(0.99, 0.99, 1.0))
		b.circle(drum, 62.0, MUSEUM_DEEP)
		b.circle(drum, 58.0, Color(0.88, 0.90, 0.92))
		# light slots round its rim
		for i in range(12):
			var ang := TAU * float(i) / 12.0
			var d := Vector2(cos(ang), sin(ang))
			b.line(drum + d * 70.0, drum + d * 88.0, MUSEUM_GLASS, 4.0)

	# a dark annex box at the north end, for contrast
	var ax := Rect2(-260.0, m_top + 6.0, 300.0, 200.0)
	if ax.end.y >= vt and ax.position.y <= vb:
		b.rect(Rect2(ax.position + Vector2(10.0, 16.0), ax.size), Color(0.30, 0.34, 0.40, 0.30))
		b.rect(ax, Color(0.20, 0.21, 0.23))
		b.rect(ax.grow(-6.0), Color(0.26, 0.27, 0.30))
		var ah := ax.position.x + 30.0
		while ah < ax.end.x - 20.0:
			b.line(Vector2(ah, ax.position.y + 10.0), Vector2(ah, ax.end.y - 10.0), Color(0.34, 0.35, 0.38), 2.0)
			ah += 30.0


static func _draw_convent_east(b: ShapeBatch, vt: float, vb: float) -> void:
	# The 16th-century chapel of the Convent dels Àngels: a plain sandstone
	# face on the plaza, buttresses, a pointed portal under a rose window, a
	# bell gable at its north end, the terracotta nave roof behind.
	var c_top := -2880.0
	var c_bot := -1620.0
	if c_bot >= vt - 60.0 and c_top <= vb + 60.0:
		var nave := Rect2(WALL_R, c_top, 460.0, c_bot - c_top)
		b.rect(nave, CONVENT_DARK)
		# terracotta nave roof: tile courses along the nave, the ridge in the middle
		var roof := Rect2(WALL_R + 34.0, c_top + 20.0, 400.0, (c_bot - c_top) - 40.0)
		b.rect(roof, CONVENT_ROOF)
		var ridge := roof.position.x + roof.size.x * 0.5
		b.rect(Rect2(ridge, roof.position.y, roof.end.x - ridge, roof.size.y), CONVENT_ROOF_DARK)
		var ty := floorf(maxf(roof.position.y, vt - 60.0) / 9.0) * 9.0
		while ty < minf(roof.end.y, vb + 60.0):
			if ty > roof.position.y:
				b.line(Vector2(roof.position.x, ty), Vector2(roof.end.x, ty), CONVENT_ROOF_DARK.darkened(0.25), 1.4)
			ty += 9.0
		b.line(Vector2(ridge, roof.position.y), Vector2(ridge, roof.end.y), CONVENT_ROOF.lightened(0.25), 3.0)
		# the stone face (x = WALL_R .. +34): ashlar courses
		var face := Rect2(WALL_R, c_top, 34.0, c_bot - c_top)
		b.rect(face, CONVENT_STONE)
		var cy := floorf(maxf(c_top, vt - 60.0) / 12.0) * 12.0
		while cy < minf(c_bot, vb + 60.0):
			if cy > c_top:
				b.line(Vector2(face.position.x, cy), Vector2(face.end.x, cy), CONVENT_DARK.lightened(0.10), 1.0)
				var off := 9.0 if int(absf(cy / 12.0)) % 2 == 0 else 20.0
				b.line(Vector2(face.position.x + off, cy), Vector2(face.position.x + off, cy + 12.0), CONVENT_DARK.lightened(0.10), 1.0)
			cy += 12.0
		b.rect(Rect2(face.end.x - 4.0, c_top, 4.0, c_bot - c_top), CONVENT_DARK)
		# buttresses stepping out onto the plaza edge
		var by := c_top + 60.0
		while by <= c_bot - 60.0:
			if absf(by - -2250.0) > 70.0:
				b.rect(Rect2(WALL_R - 10.0, by - 13.0, 26.0, 26.0), CONVENT_DARK)
				b.rect(Rect2(WALL_R - 8.0, by - 11.0, 22.0, 20.0), CONVENT_STONE.lightened(0.08))
			by += 150.0
		# the portal: pointed arch, dark doors, voussoirs, the rose window over it
		var port_y := -2250.0
		b.rect(Rect2(WALL_R - 4.0, port_y - 46.0, 30.0, 92.0), CONVENT_DARK)
		b.rect(Rect2(WALL_R - 1.0, port_y - 36.0, 18.0, 72.0), Color(0.30, 0.20, 0.14))
		b.line(Vector2(WALL_R - 1.0, port_y), Vector2(WALL_R + 17.0, port_y), Color(0.20, 0.13, 0.09), 2.0)
		for v in range(5):
			var vy := port_y - 44.0 + float(v) * 22.0
			b.line(Vector2(WALL_R - 4.0, vy), Vector2(WALL_R + 2.0, vy), CONVENT_STONE.lightened(0.15), 1.6)
		# the rose window in the face above the portal
		var rose := Vector2(WALL_R + 16.0, port_y - 78.0)
		b.circle(rose, 16.0, CONVENT_DARK)
		b.circle(rose, 12.5, ROSE_GLASS)
		for i in range(8):
			var ang := TAU * float(i) / 8.0
			b.line(rose, rose + Vector2(cos(ang), sin(ang)) * 12.0, CONVENT_STONE, 1.4)
		b.circle(rose, 3.6, Color(0.88, 0.68, 0.42))
		# bell gable over the north end, two bells in their openings
		var bg := Rect2(WALL_R + 20.0, c_top + 4.0, 70.0, 26.0)
		b.rect(Rect2(bg.position + LIGHT * 8.0, bg.size), SHADOW)
		b.rect(bg, CONVENT_STONE.lightened(0.06))
		b.rect(Rect2(bg.position.x, bg.position.y, bg.size.x, 4.0), CONVENT_DARK)
		for bx: float in [bg.position.x + 20.0, bg.position.x + 50.0]:
			b.circle(Vector2(bx, bg.get_center().y + 2.0), 8.0, Color(0.18, 0.14, 0.12))
			b.circle(Vector2(bx, bg.get_center().y + 2.0), 5.0, Color(0.70, 0.54, 0.26))

	# Raval houses either side of the chapel on the east plaza edge
	for span: Vector2 in [Vector2(-1620.0, -1180.0), Vector2(-3620.0, -2880.0)]:
		if span.y >= vt - 100.0 and span.x <= vb + 100.0:
			var sy := span.x
			var k := int(absf(span.x)) / 40
			while sy < span.y:
				var h := minf(RAVAL_LOT, span.y - sy)
				if sy + h >= vt - 100.0 and sy <= vb + 100.0:
					_draw_raval_house(b, Rect2(WALL_R, sy, 660.0, h), 1.0, k)
				sy += RAVAL_LOT
				k += 1


# --- ground layer: Raval alleys, granite skate plaza, ledges & stair set -----

static func draw_cross_section(m: Node2D, wc: Object, _top: float, bottom: float, _ctop: float, vt: float, vb: float) -> void:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	var y0 := maxf(vt - 80.0, gate_y - 40.0)
	var y1 := minf(vb + 80.0, bottom)
	if y1 <= y0:
		return

	var b := ShapeBatch.new()

	# 1. Stepped stone paving following the corridor shape (narrow Raval street -> wide plaza -> narrow street)
	var step := 40.0
	var sy := floorf(y0 / step) * step
	while sy < y1:
		var e0: Vector2 = m.walk_edges(sy) if m.has_method("walk_edges") else Vector2(WALL_L, WALL_R)
		var e1: Vector2 = m.walk_edges(sy + step) if m.has_method("walk_edges") else Vector2(WALL_L, WALL_R)
		var row := absi(int(floorf(sy / step)))
		var in_plaza := sy < -1180.0 and sy > -3620.0
		var col: Color
		if in_plaza:
			col = GRANITE_LIGHT if row % 2 == 0 else GRANITE_MID
		else:
			col = RAVAL_SETT.lightened(0.03) if row % 2 == 0 else RAVAL_SETT.darkened(0.02)

		b.polygon(PackedVector2Array([
			Vector2(e0.x, sy), Vector2(e0.y, sy),
			Vector2(e1.y, sy + step), Vector2(e1.x, sy + step),
		]), col)

		# Transverse stone slab joints
		b.line(Vector2(e0.x, sy), Vector2(e0.y, sy), GRANITE_JOINT if in_plaza else RAVAL_CURB, 1.5)

		# Narrow Raval street sidewalks and central drainage channel
		if not in_plaza:
			var sw := 34.0
			b.line(Vector2(e0.x + sw, sy), Vector2(e1.x + sw, sy + step), RAVAL_CURB, 2.5)
			b.line(Vector2(e0.y - sw, sy), Vector2(e1.y - sw, sy + step), RAVAL_CURB, 2.5)
			b.line(Vector2(640.0, sy), Vector2(640.0, sy + step), Color(0.20, 0.19, 0.18, 0.30), 1.6)
		else:
			# Longitudinal granite slab seams and dark porphyry inlay bands across the skate plaza
			for lx: float in [360.0, 480.0, 600.0, 720.0, 840.0, 960.0]:
				if lx > e0.x + 12.0 and lx < e0.y - 12.0:
					b.line(Vector2(lx, sy), Vector2(lx, sy + step), GRANITE_JOINT, 1.3)
			# slab to slab the granite varies a little, lighter and darker
			for ci in range(9):
				var xa := maxf(240.0 + 120.0 * float(ci), e0.x + 2.0)
				var xb := minf(360.0 + 120.0 * float(ci), e0.y - 2.0)
				if xb - xa < 8.0:
					continue
				var t := _h(row * 31 + ci)
				if t > 0.62:
					b.rect(Rect2(xa + 1.0, sy + 1.0, xb - xa - 2.0, step - 2.0), Color(1.0, 1.0, 1.0, 0.07))
				elif t < 0.28:
					b.rect(Rect2(xa + 1.0, sy + 1.0, xb - xa - 2.0, step - 2.0), Color(0.10, 0.10, 0.12, 0.06))
			if row % 6 == 0:
				b.rect(Rect2(e0.x + 16.0, sy + 4.0, (e0.y - e0.x) - 32.0, 8.0), GRANITE_DARK)
			# Polyurethane wheel skid marks and board wax streaks near the grind ledges
			if row % 3 == 1:
				b.line(Vector2(356.0, sy + 6.0), Vector2(368.0, sy + 32.0), Color(0.18, 0.18, 0.20, 0.28), 2.0)
				b.line(Vector2(464.0, sy + 10.0), Vector2(458.0, sy + 34.0), Color(0.18, 0.18, 0.20, 0.24), 1.8)
		sy += step

	# 2. West Museum Podium Terrace, Grindable Granite Ledges (x = 340), and Stair Set with Handrail (x = 450)
	if y0 < -1360.0 and y1 > -3380.0:
		_draw_museum_podium_and_ledges(b, y0, y1)

	# 3. East Convent Stone Terrace, Plinth, and Grindable Convent Ledge (x = 920)
	if y0 < -1760.0 and y1 > -2760.0:
		_draw_convent_terrace(b, y0, y1)

	# 4. Lamp pools round the plaza lamp posts, as lit as the hour says
	# the autoload by node: a preloaded walk module compiles before Game is a global
	var game: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	var lit: float = float(game.call("lamp_glow")) if game != null else 0.0
	if lit > 0.0:
		var lc := Color(LAMP_WARM.r, LAMP_WARM.g, LAMP_WARM.b, LAMP_WARM.a * lit)
		for lp: Vector2 in LAMP_POSTS:
			if lp.y + 90.0 >= y0 and lp.y - 90.0 <= y1:
				b.glow(lp, 68.0, lc)

	# 4b. Plane trees in planters, the bike rack, and what skaters leave lying about
	_draw_planters(b, y0, y1)
	_draw_bike_rack(b, y0, y1)
	_draw_plaza_gear(b, y0, y1)

	# 5. Stationary street skaters hanging out by the museum steps and convent wall
	_draw_plaza_skaters(b, y0, y1)

	b.flush(wc)


static func _draw_museum_podium_and_ledges(b: ShapeBatch, y0: float, y1: float) -> void:
	# Elevated white modernist museum podium & cantilevered gallery front along the west side (x = 220 .. 340)
	var p_top := maxf(-3320.0, y0)
	var p_bot := minf(-1420.0, y1)
	if p_bot > p_top:
		var pod := Rect2(WALL_L, p_top, 120.0, p_bot - p_top)
		b.rect(Rect2(pod.position + Vector2(6.0, 6.0), pod.size), SHADOW)
		b.rect(pod, PODIUM_STONE)

		# the museum is tall: its shadow lies across the podium's near edge
		b.rect(Rect2(WALL_L, p_top, 34.0, p_bot - p_top), Color(0.24, 0.28, 0.36, 0.22))
		var pj := floorf(p_top / 40.0) * 40.0
		while pj < p_bot:
			if pj >= p_top:
				b.line(Vector2(WALL_L, pj), Vector2(WALL_L + 120.0, pj), GRANITE_JOINT, 1.2)
			pj += 40.0
		b.line(Vector2(WALL_L + 120.0, p_top), Vector2(WALL_L + 120.0, p_bot), GRANITE_DARK, 2.0)

		# Signature inclined white modernist museum entry ramp (x = 264 .. 324, y = -2620 .. -2120)
		var r_top := maxf(-2620.0, y0)
		var r_bot := minf(-2120.0, y1)
		if r_bot > r_top:
			var ramp := Rect2(264.0, r_top, 60.0, r_bot - r_top)
			b.rect(Rect2(ramp.position + LIGHT * 5.0, ramp.size), SHADOW)
			b.rect(ramp, MUSEUM_SHADE)
			b.rect(Rect2(272.0, r_top, 44.0, r_bot - r_top), PODIUM_STONE.lightened(0.08))
			# Bright white modernist parapet walls on both sides of the ramp
			b.rect(Rect2(264.0, r_top, 8.0, r_bot - r_top), MUSEUM_WHITE)
			b.rect(Rect2(316.0, r_top, 8.0, r_bot - r_top), MUSEUM_WHITE)
			b.line(Vector2(272.0, r_top), Vector2(272.0, r_bot), MUSEUM_DEEP, 1.5)
			b.line(Vector2(316.0, r_top), Vector2(316.0, r_bot), MUSEUM_DEEP, 1.5)
			var r_step := floorf(r_top / 32.0) * 32.0
			while r_step < r_bot:
				if r_step >= r_top:
					b.line(Vector2(273.0, r_step), Vector2(315.0, r_step), GRANITE_JOINT, 1.3)
				r_step += 32.0
			# Podium steps leading down to the plaza at the foot of the ramp
			for s in range(3):
				var sx := 324.0 + float(s) * 5.0
				b.line(Vector2(sx, r_top), Vector2(sx, r_bot), GRANITE_DARK if s % 2 == 0 else MUSEUM_WHITE, 2.0)

	# Two long low granite skate ledges along x = 340 (matching Systems/Rails "LEDGE GRIND")
	for ledge_span: Vector2 in [Vector2(-2120.0, -1480.0), Vector2(-3260.0, -2620.0)]:
		if ledge_span.y >= y0 - 20.0 and ledge_span.x <= y1 + 20.0:
			var lr := Rect2(328.0, ledge_span.x, 24.0, ledge_span.y - ledge_span.x)
			b.rect(Rect2(lr.position + LIGHT * 6.0, lr.size), SHADOW)
			b.rect(lr, GRANITE_DARK)
			b.rect(lr.grow(-2.5), LEDGE_GRANITE)
			# Waxed steel/granite coping edge along x = 340 (the exact grind line)
			b.rect(Rect2(337.0, lr.position.y, 6.0, lr.size.y), RAIL_STEEL)
			b.line(Vector2(340.0, lr.position.y + 8.0), Vector2(340.0, lr.end.y - 8.0), LEDGE_WAX, 2.5)
			# Dark skate truck grind marks along the coping
			var gy := lr.position.y + 28.0
			while gy < lr.end.y - 28.0:
				b.line(Vector2(338.5, gy), Vector2(341.5, gy + 18.0), Color(0.22, 0.24, 0.26, 0.70), 2.0)
				gy += 52.0

	# Solid stone podium blocks on the upper terrace (MUSEUM_PODIUM_S & MUSEUM_PODIUM_N)
	for pr: Rect2 in [MUSEUM_PODIUM_S, MUSEUM_PODIUM_N]:
		if pr.end.y >= y0 - 20.0 and pr.position.y <= y1 + 20.0:
			b.rect(Rect2(pr.position + LIGHT * 7.0, pr.size), SHADOW)
			b.rect(pr, MUSEUM_DEEP)
			b.rect(pr.grow(-3.0), MUSEUM_WHITE)
			b.rect(pr.grow(-9.0), PODIUM_STONE)

	# Famous museum stair-set projection and polished steel handrail at x = 450, y = -2100 .. -1840
	var stair_r := Rect2(340.0, -2100.0, 118.0, 260.0)
	if stair_r.end.y >= y0 - 30.0 and stair_r.position.y <= y1 + 30.0:
		b.rect(Rect2(stair_r.position + LIGHT * 6.0, stair_r.size), SHADOW)
		b.rect(stair_r, GRANITE_MID)
		# 7 granite stair treads stepping down eastward toward the plaza center
		for st in range(7):
			var tx := 346.0 + float(st) * 14.0
			b.rect(Rect2(tx, stair_r.position.y + 4.0, 12.0, stair_r.size.y - 8.0), PODIUM_STONE if st % 2 == 0 else GRANITE_LIGHT)
			b.line(Vector2(tx + 12.0, stair_r.position.y + 4.0), Vector2(tx + 12.0, stair_r.end.y - 4.0), GRANITE_DARK, 2.0)
		# Grindable steel stair-set handrail along x = 450 (matching Systems/Rails "HANDRAIL")
		b.line(Vector2(450.0, -2100.0) + LIGHT * 5.0, Vector2(450.0, -1840.0) + LIGHT * 5.0, SHADOW, 6.0)
		for py: float in [-2092.0, -1970.0, -1848.0]:
			b.circle(Vector2(450.0, py), 5.0, LAMP_IRON)
		b.line(Vector2(450.0, -2100.0), Vector2(450.0, -1840.0), LAMP_IRON, 7.0)
		b.line(Vector2(450.0, -2100.0), Vector2(450.0, -1840.0), RAIL_STEEL, 4.2)
		b.line(Vector2(449.0, -2094.0), Vector2(449.0, -1846.0), Color(1.0, 1.0, 1.0, 0.75), 1.6)


static func _draw_convent_terrace(b: ShapeBatch, y0: float, y1: float) -> void:
	# East Convent dels Àngels stone bench-ledge along x = 920, y = -2420 .. -1900 ("LEDGE GRIND")
	var cl := Rect2(910.0, -2420.0, 22.0, 520.0)
	if cl.end.y >= y0 - 20.0 and cl.position.y <= y1 + 20.0:
		b.rect(Rect2(cl.position + LIGHT * 5.0, cl.size), SHADOW)
		b.rect(cl, CONVENT_DARK)
		b.rect(cl.grow(-2.5), CONVENT_STONE)
		b.rect(Rect2(917.0, cl.position.y, 6.0, cl.size.y), RAIL_STEEL)
		b.line(Vector2(920.0, cl.position.y + 8.0), Vector2(920.0, cl.end.y - 8.0), LEDGE_WAX, 2.2)

	# Solid stone convent plinth at CONVENT_PLINTH (960, -2560, 64, 130)
	if CONVENT_PLINTH.end.y >= y0 - 20.0 and CONVENT_PLINTH.position.y <= y1 + 20.0:
		b.rect(Rect2(CONVENT_PLINTH.position + LIGHT * 6.0, CONVENT_PLINTH.size), SHADOW)
		b.rect(CONVENT_PLINTH, CONVENT_DARK)
		b.rect(CONVENT_PLINTH.grow(-3.0), CONVENT_STONE)
		b.rect(CONVENT_PLINTH.grow(-8.0), CONVENT_STONE.lightened(0.10))


const SKATER_SHIRTS: Array[Color] = [
	Color(0.86, 0.32, 0.26), Color(0.24, 0.56, 0.68), Color(0.92, 0.76, 0.24),
	Color(0.36, 0.66, 0.44), Color(0.16, 0.17, 0.20), Color(0.94, 0.94, 0.92),
]
const SKATER_HAIR: Array[Color] = [
	Color(0.18, 0.14, 0.12), Color(0.36, 0.24, 0.14), Color(0.80, 0.30, 0.20),
	Color(0.10, 0.10, 0.12), Color(0.82, 0.70, 0.40),
]
const SKIN: Array[Color] = [
	Color(0.90, 0.74, 0.60), Color(0.70, 0.50, 0.36), Color(0.48, 0.32, 0.22), Color(0.84, 0.66, 0.50),
]


# Skaters sitting on the ledges and standing about, boards beside them:
# x, y, kind (0 sitting facing east, 1 sitting facing west, 2 standing).
const HANGERS: Array[Vector3] = [
	Vector3(364.0, -1600.0, 0.0), Vector3(364.0, -1990.0, 0.0),
	Vector3(364.0, -2760.0, 0.0), Vector3(364.0, -3170.0, 0.0),
	Vector3(898.0, -2010.0, 1.0), Vector3(898.0, -2310.0, 1.0),
	Vector3(300.0, -1460.0, 2.0), Vector3(292.0, -3290.0, 2.0),
	Vector3(946.0, -2700.0, 2.0),
]

# Boards, backpacks, a bottle, a speaker, a cone: lying where skaters leave
# them, off the grind lines and the board's crossing.
const GEAR: Array[Vector3] = [
	Vector3(384.0, -1640.0, 0.0), Vector3(384.0, -2800.0, 0.0), Vector3(880.0, -2060.0, 0.0),
	Vector3(612.0, -1352.0, 0.0), Vector3(706.0, -3200.0, 0.0),
	Vector3(380.0, -1572.0, 1.0), Vector3(380.0, -3050.0, 1.0), Vector3(884.0, -2250.0, 1.0),
	Vector3(394.0, -1610.0, 2.0), Vector3(890.0, -2346.0, 2.0), Vector3(398.0, -3200.0, 2.0),
	Vector3(400.0, -2190.0, 3.0), Vector3(770.0, -2620.0, 4.0), Vector3(470.0, -2620.0, 4.0),
]


static func _draw_skater_body(b: ShapeBatch, p: Vector2, facing: Vector2, k: int, sitting: bool) -> void:
	var side := Vector2(-facing.y, facing.x)
	var shirt: Color = SKATER_SHIRTS[k % SKATER_SHIRTS.size()]
	var hair: Color = SKATER_HAIR[(k * 3 + 1) % SKATER_HAIR.size()]
	var skin: Color = SKIN[(k * 5 + 2) % SKIN.size()]
	b.circle(p + LIGHT * 4.0, 10.0, SHADOW)
	if sitting:
		# legs out in front, sneakers at the end
		var jeans := Color(0.24, 0.32, 0.46) if k % 2 == 0 else Color(0.16, 0.16, 0.18)
		b.line(p + side * 4.0, p + side * 4.0 + facing * 15.0, jeans, 5.0)
		b.line(p - side * 4.0, p - side * 4.0 + facing * 15.0, jeans, 5.0)
		b.circle(p + side * 4.0 + facing * 17.0, 3.0, Color(0.95, 0.95, 0.94))
		b.circle(p - side * 4.0 + facing * 17.0, 3.0, Color(0.95, 0.95, 0.94))
	b.capsule(p + side * 7.0, p - side * 7.0, 5.5, shirt)
	b.line(p + side * 7.0, p + side * 9.0 + facing * 7.0, skin, 3.0)
	b.line(p - side * 7.0, p - side * 9.0 + facing * 7.0, skin, 3.0)
	b.circle(p - facing * 1.0, 5.4, skin)
	if k % 3 == 0:
		# a beanie
		b.circle(p - facing * 2.2, 5.0, Color(0.82, 0.26, 0.20) if k % 2 == 0 else Color(0.20, 0.40, 0.30))
	else:
		b.circle(p - facing * 2.0, 4.6, hair)


static func _draw_board(b: ShapeBatch, p: Vector2, along: Vector2, k: int) -> void:
	var side := Vector2(-along.y, along.x)
	b.capsule(p - along * 11.0 + LIGHT * 2.5, p + along * 11.0 + LIGHT * 2.5, 4.6, SHADOW)
	b.capsule(p - along * 11.0, p + along * 11.0, 4.6, DECK_GRIP if k % 2 == 0 else Color(0.56, 0.28, 0.24))
	b.line(p - along * 6.0 - side * 3.0, p - along * 6.0 + side * 3.0, RAIL_STEEL, 1.4)
	b.line(p + along * 6.0 - side * 3.0, p + along * 6.0 + side * 3.0, RAIL_STEEL, 1.4)


static func _draw_plaza_skaters(b: ShapeBatch, y0: float, y1: float) -> void:
	for i in range(HANGERS.size()):
		var hp: Vector3 = HANGERS[i]
		if hp.y + 30.0 < y0 or hp.y - 30.0 > y1:
			continue
		var p := Vector2(hp.x, hp.y)
		match int(hp.z):
			0:
				_draw_skater_body(b, p, Vector2.RIGHT, i, true)
			1:
				_draw_skater_body(b, p, Vector2.LEFT, i, true)
			_:
				_draw_board(b, p + Vector2(0.0, 18.0), Vector2.RIGHT, i)
				_draw_skater_body(b, p, Vector2(0.6, 0.8).normalized(), i, false)


static func _draw_plaza_gear(b: ShapeBatch, y0: float, y1: float) -> void:
	for i in range(GEAR.size()):
		var g: Vector3 = GEAR[i]
		if g.y + 20.0 < y0 or g.y - 20.0 > y1:
			continue
		var p := Vector2(g.x, g.y)
		match int(g.z):
			0:
				var ang := _h(i * 17) * PI
				_draw_board(b, p, Vector2(cos(ang), sin(ang)), i)
			1:
				# a backpack, flap and straps
				var bc: Color = [Color(0.20, 0.30, 0.46), Color(0.50, 0.20, 0.18), Color(0.22, 0.24, 0.22)][i % 3]
				b.rect(Rect2(p + Vector2(-7.0, -6.0) + LIGHT * 3.0, Vector2(14.0, 13.0)), SHADOW)
				b.rect(Rect2(p + Vector2(-7.0, -6.0), Vector2(14.0, 13.0)), bc)
				b.rect(Rect2(p + Vector2(-7.0, -6.0), Vector2(14.0, 5.0)), bc.darkened(0.25))
				b.line(p + Vector2(-4.0, 7.0), p + Vector2(-4.0, 10.0), bc.darkened(0.35), 1.6)
				b.line(p + Vector2(4.0, 7.0), p + Vector2(4.0, 10.0), bc.darkened(0.35), 1.6)
			2:
				# a water bottle on its side
				b.capsule(p + Vector2(-5.0, 0.0), p + Vector2(5.0, 0.0), 2.6, Color(0.62, 0.82, 0.92, 0.85))
				b.circle(p + Vector2(6.5, 0.0), 1.8, Color(0.22, 0.48, 0.80))
			3:
				# a little speaker
				b.rect(Rect2(p + Vector2(-8.0, -5.0) + LIGHT * 3.0, Vector2(16.0, 10.0)), SHADOW)
				b.rect(Rect2(p + Vector2(-8.0, -5.0), Vector2(16.0, 10.0)), Color(0.12, 0.12, 0.14))
				b.circle(p + Vector2(-3.5, 0.0), 3.2, Color(0.30, 0.30, 0.34))
				b.circle(p + Vector2(3.5, 0.0), 3.2, Color(0.30, 0.30, 0.34))
			_:
				# a traffic cone set out as an obstacle line
				b.rect(Rect2(p + Vector2(-7.0, -7.0) + LIGHT * 3.0, Vector2(14.0, 14.0)), SHADOW)
				b.rect(Rect2(p + Vector2(-7.0, -7.0), Vector2(14.0, 14.0)), Color(0.92, 0.42, 0.14))
				b.circle(p, 4.5, Color(0.96, 0.94, 0.90))
				b.circle(p, 2.4, Color(0.92, 0.42, 0.14))


static func _draw_planters(b: ShapeBatch, y0: float, y1: float) -> void:
	for i in range(PLANTERS.size()):
		var r: Rect2 = PLANTERS[i]
		if r.end.y + 40.0 < y0 or r.position.y - 40.0 > y1:
			continue
		b.rect(Rect2(r.position + LIGHT * 5.0, r.size), SHADOW)
		b.rect(r, Color(0.66, 0.66, 0.64))
		b.rect(r.grow(-5.0), Color(0.36, 0.28, 0.20))
		b.rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), Color(0.80, 0.80, 0.78))
		# the plane tree's crown, lit on the sun side
		var c := r.get_center()
		b.circle(c + LIGHT * 12.0, 40.0, Color(0.04, 0.06, 0.04, 0.22))
		b.circle(c, 40.0, Color(0.28, 0.42, 0.22))
		b.circle(c + Vector2(-14.0, -10.0), 24.0, Color(0.36, 0.52, 0.26))
		b.circle(c + Vector2(16.0, -4.0), 20.0, Color(0.32, 0.48, 0.24))
		b.circle(c + Vector2(-2.0, 16.0), 22.0, Color(0.30, 0.45, 0.23))
		b.circle(c + Vector2(-18.0, -16.0), 10.0, Color(0.48, 0.64, 0.34))
		b.circle(c + Vector2(10.0, -14.0), 8.0, Color(0.46, 0.62, 0.32))


static func _draw_bike_rack(b: ShapeBatch, y0: float, y1: float) -> void:
	var r := BIKE_RACK
	if r.end.y + 20.0 < y0 or r.position.y - 20.0 > y1:
		return
	# three steel hoops along the convent wall, two bikes locked to them
	for i in range(4):
		var hy := r.position.y + 12.0 + float(i) * 32.0
		b.line(Vector2(r.position.x + 4.0, hy), Vector2(r.end.x - 4.0, hy), RAIL_STEEL, 3.0)
		b.circle(Vector2(r.position.x + 4.0, hy), 2.2, LAMP_IRON)
		b.circle(Vector2(r.end.x - 4.0, hy), 2.2, LAMP_IRON)
	for bk in range(2):
		var by := r.position.y + 28.0 + float(bk) * 64.0
		var col := Color(0.20, 0.44, 0.62) if bk == 0 else Color(0.74, 0.22, 0.20)
		b.line(Vector2(r.position.x - 2.0, by) + LIGHT * 3.0, Vector2(r.end.x + 2.0, by) + LIGHT * 3.0, SHADOW, 6.0)
		b.circle(Vector2(r.position.x + 2.0, by), 7.0, Color(0.10, 0.10, 0.11))
		b.circle(Vector2(r.end.x - 2.0, by), 7.0, Color(0.10, 0.10, 0.11))
		b.circle(Vector2(r.position.x + 2.0, by), 4.5, Color(0.40, 0.40, 0.42))
		b.circle(Vector2(r.end.x - 2.0, by), 4.5, Color(0.40, 0.40, 0.42))
		b.line(Vector2(r.position.x + 2.0, by), Vector2(r.end.x - 2.0, by), col, 3.0)
		b.line(Vector2(r.end.x - 6.0, by - 5.0), Vector2(r.end.x - 6.0, by + 5.0), Color(0.16, 0.16, 0.18), 2.0)


# Three skaters rolling laps of the open plaza, out of the pair's way: each
# leans off when the dog or your human comes near.
const ROLLERS: Array[Vector4] = [
	# center x, center y, radius x, radius y
	Vector4(995.0, -2020.0, 14.0, 330.0),
	Vector4(690.0, -3020.0, 120.0, 150.0),
	Vector4(700.0, -1440.0, 110.0, 80.0),
]


static func _draw_rollers(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var t := float(AnimClock.msec()) * 0.001
	var dog_p: Vector2 = m.dog.global_position if "dog" in m and m.dog != null else Vector2(INF, INF)
	var hum_p: Vector2 = m.human.global_position if "human" in m and m.human != null else Vector2(INF, INF)
	for i in range(ROLLERS.size()):
		var rl: Vector4 = ROLLERS[i]
		if rl.y + rl.w + 30.0 < vt or rl.y - rl.w - 30.0 > vb:
			continue
		var w := 0.55 + 0.12 * float(i)
		var a := t * w + float(i) * 2.1
		var p := Vector2(rl.x + cos(a) * rl.z, rl.y + sin(a) * rl.w)
		var v := Vector2(-sin(a) * rl.z, cos(a) * rl.w)
		var along := v.normalized() if v.length() > 0.01 else Vector2.UP
		for q: Vector2 in [dog_p, hum_p]:
			var d := p.distance_to(q)
			if d < 70.0 and d > 0.01:
				p += (p - q) / d * (70.0 - d)
		_draw_board(b, p, along, i + 2)
		# standing on it, sideways to the way it rolls, arms out for balance
		var side := Vector2(-along.y, along.x)
		var k := i + 3
		var shirt: Color = SKATER_SHIRTS[k % SKATER_SHIRTS.size()]
		var skin: Color = SKIN[k % SKIN.size()]
		b.circle(p + LIGHT * 4.0, 9.0, SHADOW)
		b.capsule(p + along * 6.0, p - along * 6.0, 5.5, shirt)
		var sway := sin(t * 3.0 + float(i)) * 3.0
		b.line(p + along * 6.0, p + along * 15.0 + side * sway, skin, 3.0)
		b.line(p - along * 6.0, p - along * 15.0 - side * sway, skin, 3.0)
		b.circle(p + side * 1.0, 5.2, skin)
		b.circle(p + side * 2.0, 4.6, SKATER_HAIR[k % SKATER_HAIR.size()])


# --- custom furniture hooks (cached in main's furniture pass) ----------------

static func draw_column(_m: Node2D, wc: Object, p: Vector2) -> void:
	var b := ShapeBatch.new()
	# Modernist anthracite steel plaza lamp post with twin luminaire arms
	b.circle(p + LIGHT * 9.0, 11.0, SHADOW)
	b.line(p, p + LIGHT * 28.0, SHADOW, 8.0)
	b.circle(p, 11.0, GRANITE_DARK)
	b.circle(p, 8.5, LAMP_IRON)
	b.circle(p - LIGHT * 1.5, 5.5, LAMP_IRON.lightened(0.18))
	b.line(p + Vector2(-12.0, 0.0), p + Vector2(12.0, 0.0), LAMP_IRON, 3.2)
	b.circle(p + Vector2(-12.0, 0.0), 3.6, Color(1.0, 0.92, 0.66))
	b.circle(p + Vector2(12.0, 0.0), 3.6, Color(1.0, 0.92, 0.66))
	b.flush(wc)


static func draw_bollard(_m: Node2D, wc: Object, h: Dictionary) -> void:
	# A skateboard left resting upside-down / sideways on the plaza stone (sniff spot)
	var hp: Vector2 = h.pos
	var done := bool(h.get("done", false))
	var prog := float(h.get("progress", 0.0))
	var b := ShapeBatch.new()
	b.rect(Rect2(hp.x - 14.0, hp.y + 3.0, 28.0, 9.0), SHADOW)
	var deck_c := DECK_MAPLE.darkened(0.20) if done else DECK_MAPLE
	var grip_c := DECK_GRIP.lightened(0.12) if done else DECK_GRIP
	b.rect(Rect2(hp.x - 12.0, hp.y - 4.5, 24.0, 9.0), deck_c)
	b.circle(hp + Vector2(-12.0, 0.0), 4.5, deck_c)
	b.circle(hp + Vector2(12.0, 0.0), 4.5, deck_c)
	b.rect(Rect2(hp.x - 10.5, hp.y - 3.4, 21.0, 6.8), grip_c)
	# Trucks & bright urethane wheels
	for wx: float in [-9.0, 9.0]:
		b.line(hp + Vector2(wx, -4.8), hp + Vector2(wx, 4.8), RAIL_STEEL, 2.0)
		b.circle(hp + Vector2(wx, -5.2), 2.2, Color(0.92, 0.32, 0.24))
		b.circle(hp + Vector2(wx, 5.2), 2.2, Color(0.92, 0.32, 0.24))
	if not done and prog > 0.0:
		var segs := maxi(2, int(ceilf(16.0 * prog / 0.8)))
		var prev := hp + Vector2(0.0, -16.0)
		for i in range(1, segs + 1):
			var ang := -PI * 0.5 + TAU * (prog / 0.8) * (float(i) / float(segs))
			var nxt := hp + Vector2(cos(ang), sin(ang)) * 16.0
			b.line(prev, nxt, Color(1.0, 0.95, 0.70), 3.0)
			prev = nxt
	b.flush(wc)


static func draw_bin(_m: Node2D, wc: Object, bn: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(bn + LIGHT * 7.0, 12.0, SHADOW)
	b.circle(bn, 12.5, LAMP_IRON)
	b.circle(bn, 10.5, Color(0.32, 0.34, 0.38))
	b.circle(bn + Vector2(0.8, 1.0), 6.2, Color(0.10, 0.11, 0.12))
	b.circle(bn - LIGHT * 2.5, 2.2, RAIL_STEEL)
	b.flush(wc)


static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(f + Vector2(9.0, 6.0), 9.0, Color(0.36, 0.52, 0.62, 0.40))
	b.circle(f + LIGHT * 6.0, 12.0, SHADOW)
	b.circle(f, 12.5, GRANITE_DARK)
	b.circle(f, 10.0, Color(0.24, 0.36, 0.44))
	var col_p := f + Vector2(0.0, -5.5)
	b.circle(col_p, 6.5, LAMP_IRON)
	b.line(col_p, f + Vector2(0.0, 2.0), Color(0.82, 0.68, 0.32), 2.5)
	b.circle(f + Vector2(0.0, 2.5), 2.2, Color(0.78, 0.92, 0.98, 0.90))
	b.flush(m._wc)


static func draw_snack(_m: Node2D, wc: Object, kp: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(kp + LIGHT * 3.0, 9.5, SHADOW)
	# Paper cone with two golden sugared churros
	b.polygon(PackedVector2Array([
		kp + Vector2(-10.0, 2.0), kp + Vector2(-4.0, -8.0),
		kp + Vector2(7.0, -5.0), kp + Vector2(3.0, 6.0),
	]), CHURRO_SUGAR)
	b.line(kp + Vector2(-3.0, -3.0), kp + Vector2(8.0, 2.0), CHURRO_GOLD, 4.2)
	b.line(kp + Vector2(-2.0, 1.0), kp + Vector2(9.0, 5.0), CHURRO_GOLD.darkened(0.08), 4.0)
	b.line(kp + Vector2(-2.0, -3.0), kp + Vector2(6.0, 1.0), CHURRO_SUGAR, 1.4)
	b.flush(wc)


# --- live pass: un-taken churro bag prize & runaway skateboard event ---------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var taken: bool = bool(m.prize_taken) if "prize_taken" in m else false
	if not taken and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		b.glow(PRIZE, 24.0, Color(1.0, 0.88, 0.42, 0.28))
		b.circle(PRIZE + LIGHT * 3.5, 11.0, SHADOW)
		# Stone ledge plinth under the prize bag
		b.rect(Rect2(PRIZE - Vector2(14.0, 10.0), Vector2(28.0, 20.0)), GRANITE_DARK)
		b.rect(Rect2(PRIZE - Vector2(12.0, 8.0), Vector2(24.0, 16.0)), PODIUM_STONE)
		# Striped xurreria paper bag overflowing with golden churros
		b.rect(Rect2(PRIZE - Vector2(7.0, 5.0), Vector2(14.0, 11.0)), CHURRO_SUGAR)
		for st: float in [-4.0, 1.0, 5.0]:
			b.line(PRIZE + Vector2(st, -3.0), PRIZE + Vector2(st + 4.0, -9.0), CHURRO_GOLD, 3.2)

	_draw_rollers(m, b, vt, vb)
	if m.angels_skate != null:
		m.angels_skate.draw(b, vt, vb)


# Washing hung across the narrow Raval streets, balcony to balcony, over
# everyone's heads. Drawn once for the whole walk.
const WASH_YS: Array[float] = [-250.0, -660.0, -3760.0, -4150.0]


static func draw_overhead(m: Node2D, wc: Object) -> void:
	if not m.has_method("walk_edges"):
		return
	var b := ShapeBatch.new()
	for i in range(WASH_YS.size()):
		var y: float = WASH_YS[i]
		var e: Vector2 = m.walk_edges(y)
		var a := Vector2(e.x - 12.0, y)
		var c := Vector2(e.y + 12.0, y + 18.0)
		var sag := (a + c) * 0.5 + Vector2(0.0, 12.0)
		var cord := Color(0.88, 0.88, 0.86, 0.9)
		b.line(a, sag, cord, 1.3)
		b.line(sag, c, cord, 1.3)
		var u := 0.06 + 0.05 * _h(i * 29)
		var n := 0
		while u < 0.94:
			var q := a.lerp(sag, u * 2.0) if u < 0.5 else sag.lerp(c, (u - 0.5) * 2.0)
			var col: Color = WASHING[(i * 3 + n) % WASHING.size()]
			var kind := int(_h(i * 13 + n * 7) * 4.0)
			var w := 14.0
			match kind:
				0:
					# a T-shirt pegged by its hem
					w = 18.0
					b.rect(Rect2(q + Vector2(3.0, 4.0), Vector2(12.0, 16.0)), Color(0.0, 0.0, 0.0, 0.16))
					b.rect(Rect2(q + Vector2(3.0, 0.0), Vector2(12.0, 16.0)), col)
					b.rect(Rect2(q + Vector2(0.0, 10.0), Vector2(18.0, 6.0)), col.darkened(0.08))
				1:
					# trousers, two legs
					w = 14.0
					b.rect(Rect2(q + Vector2(2.0, 4.0), Vector2(12.0, 20.0)), Color(0.0, 0.0, 0.0, 0.16))
					var tc := Color(0.24, 0.32, 0.48) if n % 2 == 0 else Color(0.66, 0.58, 0.44)
					b.rect(Rect2(q, Vector2(12.0, 6.0)), tc)
					b.rect(Rect2(q + Vector2(0.0, 5.0), Vector2(5.0, 15.0)), tc)
					b.rect(Rect2(q + Vector2(7.0, 5.0), Vector2(5.0, 15.0)), tc)
				2:
					# a towel
					w = 22.0
					b.rect(Rect2(q + Vector2(2.0, 4.0), Vector2(20.0, 14.0)), Color(0.0, 0.0, 0.0, 0.16))
					b.rect(Rect2(q, Vector2(20.0, 14.0)), col)
					b.rect(Rect2(q + Vector2(0.0, 10.0), Vector2(20.0, 2.0)), col.lightened(0.3))
				_:
					# a pair of socks
					w = 10.0
					b.rect(Rect2(q, Vector2(3.0, 8.0)), col)
					b.rect(Rect2(q + Vector2(5.0, 0.0), Vector2(3.0, 8.0)), col)
			u += (w + 12.0 + 26.0 * _h(i * 3 + n * 11)) / (c.x - a.x)
			n += 1
	b.flush(wc)


# --- off-leash area: CLAUSTRE DE LES LLETRES (the university courtyard) ------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect() if m.has_method("_freedom_rect") else Rect2(70.0, -5620.0, 1110.0, 590.0)
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	var b := ShapeBatch.new()

	# 1. Outer historic university roofscape beyond the cloister walls
	b.rect(Rect2(-420.0, gate_y - 2400.0, 2140.0, 2400.0), CONVENT_DARK)
	var ry := r.position.y - 220.0
	while ry < r.end.y + 40.0:
		for sx: Vector2 in [Vector2(-380.0, r.position.x - 24.0), Vector2(r.end.x + 24.0, 1680.0)]:
			var w := sx.y - sx.x
			b.rect(Rect2(sx.x, ry, w, 58.0), CONVENT_ROOF)
			b.line(Vector2(sx.x, ry + 29.0), Vector2(sx.y, ry + 29.0), CONVENT_STONE, 2.5)
		ry += 76.0

	# 2. Cloister garden lawn beds on the west (x < 300) and east (x > 980) wings (Surfaces.S.GRASS)
	var grass_base := Color(0.28, 0.45, 0.26)
	var grass_lit := Color(0.34, 0.52, 0.30)
	b.rect(r, grass_base)
	for bed: Rect2 in [
		Rect2(r.position.x + 18.0, r.position.y + 20.0, 282.0 - r.position.x, r.size.y - 40.0),
		Rect2(980.0, r.position.y + 20.0, r.end.x - 998.0, r.size.y - 40.0),
	]:
		b.rect(bed, grass_lit)
		# Bitter-orange trees and clipped boxwood parterre rings in the cloister beds
		for ti in range(4):
			var ty := bed.position.y + 70.0 + float(ti) * 125.0
			var tp := Vector2(bed.get_center().x, ty)
			b.circle(tp + LIGHT * 6.0, 22.0, SHADOW)
			b.circle(tp, 21.0, ORANGE_LEAF.darkened(0.18))
			b.circle(tp - LIGHT * 3.0, 15.0, ORANGE_LEAF)
			b.circle(tp + Vector2(-5.0, -4.0), 3.0, ORANGE_FRUIT)
			b.circle(tp + Vector2(6.0, 3.0), 2.8, ORANGE_FRUIT)
			b.circle(tp + Vector2(2.0, -7.0), 2.6, ORANGE_FRUIT)

	# 3. Central sandstone cloister walkway & courtyard (x = 300 .. 980 -> Surfaces.S.PAVEMENT)
	var court := Rect2(300.0, r.position.y, 680.0, r.size.y)
	b.rect(court, CLOISTER_STONE)
	b.rect(Rect2(294.0, r.position.y, 8.0, r.size.y), CLOISTER_ARCH)
	b.rect(Rect2(978.0, r.position.y, 8.0, r.size.y), CLOISTER_ARCH)

	# Cloister stone flagstone grid and arcaded gallery column bases along x = 336 and x = 944
	var cy := r.position.y + 40.0
	while cy < r.end.y - 20.0:
		b.line(Vector2(304.0, cy), Vector2(976.0, cy), CLOISTER_ARCH.darkened(0.12), 1.5)
		for col_x: float in [336.0, 944.0]:
			var cp := Vector2(col_x, cy)
			b.circle(cp + LIGHT * 4.0, 9.5, SHADOW)
			b.rect(Rect2(cp - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), CLOISTER_ARCH)
			b.circle(cp, 6.5, CLOISTER_STONE.lightened(0.08))
		cy += 64.0
	for gx: float in [372.0, 506.0, 640.0, 774.0, 908.0]:
		b.line(Vector2(gx, r.position.y + 12.0), Vector2(gx, r.end.y - 12.0), CLOISTER_ARCH.darkened(0.10), 1.5)

	# 4. Octagonal Renaissance stone fountain basin in the north-center of the cloister
	var f_pos := Vector2(640.0, r.position.y + 220.0)
	b.circle(f_pos + LIGHT * 6.0, 46.0, SHADOW)
	b.circle(f_pos, 44.0, CLOISTER_ARCH)
	b.circle(f_pos, 38.0, CLOISTER_STONE.lightened(0.06))
	b.circle(f_pos, 30.0, Color(0.22, 0.44, 0.56))
	b.circle(f_pos - LIGHT * 4.0, 18.0, Color(0.34, 0.58, 0.70, 0.65))
	b.circle(f_pos, 9.0, CLOISTER_ARCH)
	b.circle(f_pos - LIGHT * 1.5, 5.5, CLOISTER_STONE.lightened(0.12))

	# 5. Perimeter Romanesque/Renaissance sandstone cloister walls
	var wall_w := 22.0
	b.rect(Rect2(r.position.x - wall_w, r.position.y - wall_w, r.size.x + wall_w * 2.0, wall_w), CLOISTER_ARCH)
	b.rect(Rect2(r.position.x - wall_w, r.position.y, wall_w, r.size.y), CLOISTER_ARCH)
	b.rect(Rect2(r.end.x, r.position.y, wall_w, r.size.y), CLOISTER_ARCH)
	var gl: float = float(m.gate_l) if "gate_l" in m else 440.0
	var gr: float = float(m.gate_r) if "gate_r" in m else 840.0
	b.rect(Rect2(r.position.x - wall_w, r.end.y - 8.0, gl - r.position.x + wall_w - 16.0, 14.0), CLOISTER_ARCH)
	b.rect(Rect2(gr + 16.0, r.end.y - 8.0, r.end.x - gr + wall_w - 16.0, 14.0), CLOISTER_ARCH)

	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, BENCH_STONE)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, "the university courtyard, off leash")


static func surface(m: Node2D, p: Vector2) -> int:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	if p.y < gate_y:
		if p.x >= 300.0 and p.x <= 980.0:
			return Surfaces.S.PAVEMENT
		return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT
