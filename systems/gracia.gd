class_name Gracia
extends RefCounted

# WALK 25: FESTA DE GRÀCIA (The Decorated Festival Street Run)
# The famous festival streets of Vila de Gràcia (Carrer Verdi / Mozart).
# Covered from balcony to balcony in handmade theme decorations: papier-mâché
# arches, paper lanterns, jellyfish streamers, festival stalls, and castellers.
# On the return leg, the Correfoc fire devils charge down the street!

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")

const HALF := 220.0
const WALL_L := 420.0
const WALL_R := 860.0

const PRIZE := Vector2(640.0, -4420.0)
const PRIZE_TEXT := "claim the festival award banner from Plaça de la Virreina"

# Colors
const PAVING_WARM := Color(0.72, 0.68, 0.62)
const KERB_STONE := Color(0.55, 0.52, 0.48)
const BANNER_BLUE := Color(0.20, 0.48, 0.78)
const BANNER_GOLD := Color(0.92, 0.75, 0.22)
const BANNER_RED := Color(0.85, 0.22, 0.18)
const BANNER_GREEN := Color(0.25, 0.65, 0.35)
const CHURRO_CART := Color(0.82, 0.35, 0.20)
const CASTELL_MAT := Color(0.25, 0.42, 0.65)
const LANTERN_GLOW := Color(0.98, 0.90, 0.55, 0.50)

# Respite Solids matching GRACIA_BANDS
const CASTELL_STAGE := Rect2(560.0, -3340.0, 160.0, 70.0)
const CHURRO_STAND := Rect2(440.0, -1940.0, 100.0, 60.0)
const FESTIVAL_STALL_1 := Rect2(740.0, -1200.0, 90.0, 50.0)
const FESTIVAL_STALL_2 := Rect2(450.0, -2600.0, 90.0, 50.0)

# Festival lampposts for wrapping and slalom
const GRACIA_POSTS: Array[Vector2] = [
	Vector2(440.0, -500.0), Vector2(840.0, -500.0),
	Vector2(440.0, -1000.0), Vector2(840.0, -1000.0),
	Vector2(440.0, -1600.0), Vector2(840.0, -1600.0),
	Vector2(440.0, -2200.0), Vector2(840.0, -2200.0),
	Vector2(440.0, -2900.0), Vector2(840.0, -2900.0),
	Vector2(440.0, -3700.0), Vector2(840.0, -3700.0),
	Vector2(440.0, -4200.0), Vector2(840.0, -4200.0),
]


static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DE LA VIRREINA"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 440.0
	m.gate_r = 840.0

	# 1. Poles (festival lampposts & stall corners)
	for p: Vector2 in GRACIA_POSTS:
		m.poles.append(p)
	# Castell stage corners
	m.poles.append(Vector2(CASTELL_STAGE.position.x + 8.0, CASTELL_STAGE.get_center().y))
	m.poles.append(Vector2(CASTELL_STAGE.end.x - 8.0, CASTELL_STAGE.get_center().y))
	m.deco_pole_count = m.poles.size()

	# 2. Benches & Bins
	m.benches = Array([
		Vector2(450.0, -750.0),
		Vector2(830.0, -2050.0),
		Vector2(450.0, -3450.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(440.0, -600.0),
		Vector2(840.0, -1700.0),
		Vector2(440.0, -3000.0),
		Vector2(840.0, -4100.0),
	], TYPE_VECTOR2, &"", null)

	# 3. Hydrants: Ornate Gràcia cast-iron fountain posts
	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 25.0, -450.0),
		Vector2(WALL_R - 25.0, -1350.0),
		Vector2(WALL_L + 25.0, -2400.0),
		Vector2(WALL_R - 25.0, -3200.0),
		Vector2(WALL_L + 25.0, -4000.0),
	]

	# 4. Kebabs: Fresh hot churros & festival pintxos
	var keb_list: Array[Vector2] = [
		Vector2(550.0, -1900.0),  # Right by the churro stand
		Vector2(680.0, -2700.0),
		Vector2(580.0, -3600.0),
	]

	# 5. Prize
	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT

	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [
		CASTELL_STAGE,
		CHURRO_STAND,
		FESTIVAL_STALL_1,
		FESTIVAL_STALL_2,
	]


static func wrap_rects() -> Array[Rect2]:
	return [
		CASTELL_STAGE,
		CHURRO_STAND,
		FESTIVAL_STALL_1,
		FESTIVAL_STALL_2,
	]


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# Draw street kerbs, festival stalls, castell practice stage
	var step := 60.0
	var sy := floorf(vt / step) * step
	while sy < vb:
		# Street edge kerb lines
		b.rect(Rect2(WALL_L - 8.0, sy, 8.0, step), KERB_STONE)
		b.rect(Rect2(WALL_R, sy, 8.0, step), KERB_STONE)
		sy += step

	# Castell stage
	if vb > CASTELL_STAGE.position.y and vt < CASTELL_STAGE.end.y:
		b.rect(CASTELL_STAGE, CASTELL_MAT)
		b.rect(Rect2(CASTELL_STAGE.position.x + 4.0, CASTELL_STAGE.position.y + 4.0, CASTELL_STAGE.size.x - 8.0, CASTELL_STAGE.size.y - 8.0), Color(0.32, 0.52, 0.78))

	# Churro stand
	if vb > CHURRO_STAND.position.y and vt < CHURRO_STAND.end.y:
		b.rect(CHURRO_STAND, CHURRO_CART)
		b.rect(Rect2(CHURRO_STAND.position.x + 4.0, CHURRO_STAND.position.y + 4.0, CHURRO_STAND.size.x - 8.0, CHURRO_STAND.size.y - 8.0), BANNER_GOLD)

	# Festival stalls
	if vb > FESTIVAL_STALL_1.position.y and vt < FESTIVAL_STALL_1.end.y:
		b.rect(FESTIVAL_STALL_1, BANNER_BLUE)
	if vb > FESTIVAL_STALL_2.position.y and vt < FESTIVAL_STALL_2.end.y:
		b.rect(FESTIVAL_STALL_2, BANNER_GREEN)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m == null or ci == null:
		return
	var b := ShapeBatch.new()
	var vt: float = m.cam.position.y - 400.0
	var vb: float = m.cam.position.y + 400.0
	var step := 120.0
	var sy := floorf(vt / step) * step
	while sy < vb:
		var line_y := sy + 40.0
		b.rect(Rect2(WALL_L, line_y, WALL_R - WALL_L, 3.0), BANNER_GOLD)
		for i in range(5):
			var lx := WALL_L + 45.0 + float(i) * 85.0
			var col: Color = BANNER_BLUE if i % 4 == 0 else (BANNER_RED if i % 4 == 1 else (BANNER_GREEN if i % 4 == 2 else BANNER_GOLD))
			b.circle(Vector2(lx, line_y + 12.0), 8.0, col)
			b.circle(Vector2(lx, line_y + 12.0), 12.0, LANTERN_GLOW)
		sy += step
	b.flush(ci)


static func tick(m: Node2D, _delta: float) -> void:
	if m == null or m.dog == null:
		return
	var dp: Vector2 = m.dog.global_position
	# Track passing under decorations for goal
	if fmod(absf(dp.y), 120.0) < 25.0:
		var cur_val = m.get("gracia_decor_brushed")
		m.set("gracia_decor_brushed", (int(cur_val) if cur_val != null else 0) + 1)
