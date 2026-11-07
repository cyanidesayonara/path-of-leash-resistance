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

	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [MUSEUM_PODIUM_S, MUSEUM_PODIUM_N, CONVENT_PLINTH]


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

	# Goal 3: Steal a dropped churro (from plaza snacks or the bailing skater)
	if not m.angels_churro_stolen and m.kebabs_eaten > 0:
		m.angels_churro_stolen = true


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


static func _draw_raval_flanks(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	if bot <= top:
		return
	var mod := 160.0
	var sy := floorf(top / mod) * mod
	while sy < bot:
		var r0 := maxf(sy, top)
		var r1 := minf(sy + mod - 4.0, bot)
		if r1 - r0 >= 28.0:
			var e: Vector2 = m.walk_edges((r0 + r1) * 0.5) if m.has_method("walk_edges") else Vector2(425.0, 855.0)
			var k := absi(int(floorf(sy / mod)))
			_draw_raval_house(b, Rect2(-420.0, r0, e.x + 420.0, r1 - r0), -1.0, k)
			_draw_raval_house(b, Rect2(e.y, r0, 1720.0 - e.y, r1 - r0), 1.0, k + 3)
		sy += mod


static func _draw_raval_house(b: ShapeBatch, r: Rect2, side: float, k: int) -> void:
	var cols: Array[Color] = [RAVAL_OCHRE, RAVAL_TERRA, RAVAL_SLATE, Color(0.74, 0.68, 0.58)]
	var wall_c: Color = cols[k % cols.size()]
	var inner_x := r.end.x if side < 0.0 else r.position.x
	var face := 18.0
	b.rect(r, wall_c.darkened(0.18))
	var roof_r := Rect2(r.position.x, r.position.y + 3.0, r.size.x - face, r.size.y - 6.0) if side < 0.0 \
		else Rect2(r.position.x + face, r.position.y + 3.0, r.size.x - face, r.size.y - 6.0)
	b.rect(roof_r, wall_c)
	b.rect(roof_r.grow(-10.0), wall_c.darkened(0.08))
	# Foreshortened street facade and wrought-iron Raval balconies
	var fx := (inner_x - face) if side < 0.0 else inner_x
	b.rect(Rect2(fx, r.position.y, face, r.size.y), wall_c.darkened(0.32))
	var by := r.position.y + 20.0
	while by < r.end.y - 20.0:
		var bx := (inner_x - 7.0) if side < 0.0 else (inner_x + 2.0)
		b.rect(Rect2(bx, by, 5.0, 18.0), Color(0.14, 0.16, 0.18))
		b.line(Vector2(inner_x, by - 2.0), Vector2(inner_x, by + 20.0), Color(0.22, 0.24, 0.26), 2.0)
		by += 38.0
	# Rooftop terrat skylight or water tank
	var c_pos := Vector2(inner_x - 76.0 if side < 0.0 else inner_x + 76.0, r.get_center().y)
	b.rect(Rect2(c_pos - Vector2(18.0, 14.0), Vector2(36.0, 28.0)), Color(0.36, 0.44, 0.50))
	b.line(c_pos + Vector2(-16.0, 0.0), c_pos + Vector2(16.0, 0.0), Color(0.78, 0.84, 0.88, 0.55), 1.5)


static func _draw_white_museum(b: ShapeBatch, vt: float, vb: float) -> void:
	var m_top := -3540.0
	var m_bot := -1260.0
	if m_bot < vt or m_top > vb:
		return

	# Monumental white modernist museum mass on the west side of the plaza (x = -420 .. 220)
	var body := Rect2(-420.0, m_top, WALL_L + 420.0, m_bot - m_top)
	b.rect(Rect2(body.position + LIGHT * 14.0, body.size), SHADOW)
	b.rect(body, MUSEUM_SHADE)
	b.rect(Rect2(-400.0, m_top + 8.0, WALL_L + 394.0, (m_bot - m_top) - 16.0), MUSEUM_WHITE)

	# Crisp geometric white architectural panel grid and louvers across the visible roof (x = 140 .. 220)
	var py := m_top + 60.0
	while py < m_bot - 40.0:
		if py >= vt - 40.0 and py <= vb + 40.0:
			b.line(Vector2(-380.0, py), Vector2(WALL_L - 6.0, py), MUSEUM_DEEP, 2.0)
			b.rect(Rect2(142.0, py + 8.0, 44.0, 18.0), MUSEUM_SHADE)
			b.line(Vector2(144.0, py + 17.0), Vector2(184.0, py + 17.0), MUSEUM_DEEP, 1.5)
		py += 72.0
	for px: float in [-260.0, -120.0, 20.0, 140.0, 188.0]:
		b.line(Vector2(px, maxf(m_top, vt - 40.0)), Vector2(px, minf(m_bot, vb + 40.0)), MUSEUM_DEEP, 2.0)

	# Long continuous glass curtain wall along the museum edge (x = 188 .. 220)
	var glass_r := Rect2(WALL_L - 32.0, m_top + 24.0, 32.0, (m_bot - m_top) - 48.0)
	b.rect(glass_r, MUSEUM_GLASS_DARK)
	b.rect(glass_r.grow(-2.5), MUSEUM_GLASS)
	var my := m_top + 44.0
	while my < m_bot - 44.0:
		if my >= vt - 50.0 and my <= vb + 50.0:
			b.line(Vector2(glass_r.position.x, my), Vector2(glass_r.end.x, my), MUSEUM_WHITE, 2.4)
			b.line(Vector2(glass_r.position.x + 4.0, my + 8.0), Vector2(glass_r.end.x - 4.0, my + 32.0), MUSEUM_GLINT, 2.2)
		my += 44.0


static func _draw_convent_east(b: ShapeBatch, vt: float, vb: float) -> void:
	# 16th-century Gothic-Renaissance stone chapel (Convent dels Àngels) on the east side
	var c_top := -2880.0
	var c_bot := -1620.0
	if c_bot >= vt - 60.0 and c_top <= vb + 60.0:
		var nave := Rect2(WALL_R, c_top, 460.0, c_bot - c_top)
		b.rect(Rect2(nave.position + LIGHT * 10.0, nave.size), SHADOW)
		b.rect(nave, CONVENT_DARK)
		b.rect(nave.grow(-5.0), CONVENT_STONE)

		# Terracotta gable roof over the chapel nave (starts at WALL_R + 14 so it is clearly visible in frame)
		var roof := Rect2(WALL_R + 14.0, c_top + 28.0, 320.0, (c_bot - c_top) - 56.0)
		b.rect(roof, CONVENT_ROOF_DARK)
		b.rect(Rect2(roof.position.x, roof.position.y, 56.0, roof.size.y), CONVENT_ROOF)
		var ty := roof.position.y + 16.0
		while ty < roof.end.y - 12.0:
			b.line(Vector2(roof.position.x, ty), Vector2(roof.end.x, ty), CONVENT_ROOF_DARK.darkened(0.22), 2.0)
			ty += 20.0
		b.line(Vector2(WALL_R + 70.0, roof.position.y), Vector2(WALL_R + 70.0, roof.end.y), CONVENT_STONE, 4.0)

		# Stone buttresses projecting along the west chapel wall (x = WALL_R)
		var by := c_top + 40.0
		while by <= c_bot - 40.0:
			b.rect(Rect2(WALL_R - 8.0, by - 11.0, 24.0, 22.0), CONVENT_DARK)
			b.rect(Rect2(WALL_R - 6.0, by - 9.0, 20.0, 18.0), CONVENT_STONE.lightened(0.10))
			by += 120.0

		# Arched Renaissance portal and rose window trace at y = -2250
		var port_y := -2250.0
		b.rect(Rect2(WALL_R - 6.0, port_y - 44.0, 22.0, 88.0), CONVENT_DARK)
		b.rect(Rect2(WALL_R - 2.0, port_y - 34.0, 16.0, 68.0), Color(0.18, 0.14, 0.12))
		b.circle(Vector2(WALL_R + 22.0, port_y), 16.0, CONVENT_DARK)
		b.circle(Vector2(WALL_R + 22.0, port_y), 12.0, ROSE_GLASS)
		b.circle(Vector2(WALL_R + 22.0, port_y), 5.0, Color(0.88, 0.68, 0.42, 0.75))

	# Flanking Raval stone buildings north and south of the convent on the east plaza edge
	for span: Vector2 in [Vector2(-1600.0, -1200.0), Vector2(-3560.0, -2900.0)]:
		if span.y >= vt - 40.0 and span.x <= vb + 40.0:
			_draw_raval_house(b, Rect2(WALL_R, span.x, 460.0, span.y - span.x), 1.0, int(absf(span.x)))


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

	# 4. Warm dusk lamp pools around the plaza lamp posts
	for lp: Vector2 in LAMP_POSTS:
		if lp.y + 90.0 >= y0 and lp.y - 90.0 <= y1:
			b.glow(lp, 68.0, LAMP_WARM)

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

		# Projecting white modernist museum gallery canopy & long glass curtain wall (x = 220 .. 264)
		var fac := Rect2(WALL_L, p_top, 44.0, p_bot - p_top)
		b.rect(Rect2(fac.position + LIGHT * 6.0, fac.size), SHADOW)
		b.rect(fac, MUSEUM_SHADE)
		b.rect(Rect2(WALL_L, p_top, 30.0, p_bot - p_top), MUSEUM_WHITE)
		# Long glass curtain wall strip (x = 248 .. 264) with white mullions & sky glints
		var gl := Rect2(WALL_L + 28.0, p_top, 16.0, p_bot - p_top)
		b.rect(gl, MUSEUM_GLASS_DARK)
		b.rect(gl.grow(-1.5), MUSEUM_GLASS)
		var gy_m := floorf(p_top / 44.0) * 44.0
		while gy_m < p_bot:
			if gy_m >= p_top and gy_m <= p_bot:
				b.line(Vector2(WALL_L, gy_m), Vector2(WALL_L + 44.0, gy_m), MUSEUM_WHITE, 2.0)
				b.line(Vector2(gl.position.x + 2.0, gy_m + 6.0), Vector2(gl.end.x - 2.0, gy_m + 26.0), MUSEUM_GLINT, 1.8)
			gy_m += 44.0

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


static func _draw_plaza_skaters(b: ShapeBatch, y0: float, y1: float) -> void:
	# Visual-only local skaters sitting/chatting on the podium edge with boards beside them
	var spots: Array[Vector3] = [
		Vector3(312.0, -1580.0, 0.0),
		Vector3(312.0, -2220.0, 1.0),
		Vector3(312.0, -3120.0, 2.0),
		Vector3(948.0, -2160.0, 3.0),
	]
	var shirts: Array[Color] = [
		Color(0.86, 0.32, 0.26),
		Color(0.24, 0.56, 0.68),
		Color(0.92, 0.76, 0.24),
		Color(0.36, 0.66, 0.44),
	]
	for sp: Vector3 in spots:
		if sp.y + 30.0 < y0 or sp.y - 30.0 > y1:
			continue
		var p := Vector2(sp.x, sp.y)
		var idx := int(sp.z)
		b.circle(p + LIGHT * 3.0, 8.5, SHADOW)
		b.circle(p, 8.0, shirts[idx % shirts.size()])
		b.circle(p + Vector2(0.0, -2.0), 5.2, Color(0.88, 0.72, 0.58))
		b.circle(p + Vector2(0.0, -3.2), 4.6, Color(0.18, 0.16, 0.15))


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

	if m.angels_skate != null:
		m.angels_skate.draw(b, vt, vb)


static func draw_overhead(_m: Node2D, _wc: Object) -> void:
	pass


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
