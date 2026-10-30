class_name Boars
extends RefCounted

# WALK 20: ELS SENGLARS (Collserola Wild Boar Trail Chase)
# A steep downhill dirt trail through the oak and pine woods of Collserola.
# Features:
# - Dirt / forest floor surface with mud ruts and gravel patches
# - Overturned green dumpsters serving as boar picnic respites at -3400 and -1900
# - Fallen holm oak logs to leap and vault over
# - Picnic benches and stone water fountain (Font de la Budellera)
# - Wooden trail waymarker posts for hydrants
# - Abandoned sandwiches and roasted chestnuts for kebabs
# - Summit lookout prize (El Mirador)

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")

const HALF := 260.0
const WALL_L := 380.0
const WALL_R := 900.0

const PRIZE := Vector2(640.0, -4420.0)
const PRIZE_TEXT := "claim the golden acorn from the summit lookout"

# Colors
const DIRT_BASE := Color(0.38, 0.28, 0.18)
const DIRT_LIGHT := Color(0.48, 0.36, 0.24)
const DIRT_DARK := Color(0.28, 0.20, 0.12)
const MUD_BROWN := Color(0.22, 0.16, 0.10)
const PINE_GREEN := Color(0.14, 0.25, 0.15)
const LEAF_GOLD := Color(0.58, 0.42, 0.18)
const ROCK_GREY := Color(0.45, 0.44, 0.42)
const WOOD_BARK := Color(0.32, 0.22, 0.14)
const WOOD_SAWN := Color(0.65, 0.52, 0.36)

# Dumpster dimensions matching BOAR_BANDS
const DUMPSTER_SIZE := Vector2(90.0, 50.0)
const DUMPSTER_JAM_1 := Vector2(500.0, -3400.0)
const DUMPSTER_JAM_2 := Vector2(780.0, -1900.0)

# Fallen logs across the trail
const LOG_1 := Rect2(410.0, -1250.0, 160.0, 32.0)
const LOG_2 := Rect2(710.0, -2700.0, 160.0, 32.0)
const PICNIC_TABLE := Rect2(580.0, -3440.0, 120.0, 60.0)

# Trail trees along the edges
const BOAR_TREES: Array[Vector2] = [
	Vector2(395.0, -400.0), Vector2(885.0, -420.0),
	Vector2(400.0, -850.0), Vector2(880.0, -920.0),
	Vector2(390.0, -1450.0), Vector2(890.0, -1500.0),
	Vector2(405.0, -2100.0), Vector2(875.0, -2150.0),
	Vector2(395.0, -2650.0), Vector2(885.0, -2750.0),
	Vector2(400.0, -3250.0), Vector2(880.0, -3320.0),
	Vector2(390.0, -3850.0), Vector2(890.0, -3900.0),
	Vector2(405.0, -4350.0), Vector2(875.0, -4400.0),
]


static func build(m: Node2D) -> Array:
	m.gate_text = "EL MIRADOR"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 420.0
	m.gate_r = 860.0

	# 1. Poles (trail trees & picnic posts)
	for tp: Vector2 in BOAR_TREES:
		m.poles.append(tp)
	# Log ends as wrap poles
	m.poles.append(Vector2(LOG_1.position.x + 10.0, LOG_1.get_center().y))
	m.poles.append(Vector2(LOG_1.end.x - 10.0, LOG_1.get_center().y))
	m.poles.append(Vector2(LOG_2.position.x + 10.0, LOG_2.get_center().y))
	m.poles.append(Vector2(LOG_2.end.x - 10.0, LOG_2.get_center().y))
	# Picnic table corner posts
	m.poles.append(Vector2(PICNIC_TABLE.position.x + 10.0, PICNIC_TABLE.position.y + 10.0))
	m.poles.append(Vector2(PICNIC_TABLE.end.x - 10.0, PICNIC_TABLE.position.y + 10.0))
	m.poles.append(Vector2(PICNIC_TABLE.position.x + 10.0, PICNIC_TABLE.end.y - 10.0))
	m.poles.append(Vector2(PICNIC_TABLE.end.x - 10.0, PICNIC_TABLE.end.y - 10.0))
	m.deco_pole_count = m.poles.size()

	# 2. Trail Benches & Bins
	m.benches = Array([
		Vector2(420.0, -1800.0),
		Vector2(860.0, -3350.0),
		Vector2(640.0, -4300.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(420.0, -600.0),
		Vector2(860.0, -2200.0),
		Vector2(420.0, -3600.0),
	], TYPE_VECTOR2, &"", null)

	# 3. Mud patches & gravel patches
	m.patches.append({
		"y": -1100.0, "at": 0.45, "rx": 80.0, "ry": 35.0,
		"seed": 1.7, "kind": "mud", "pin": Vector2(610.0, -1100.0)
	})
	m.patches.append({
		"y": -2300.0, "at": 0.55, "rx": 90.0, "ry": 40.0,
		"seed": 2.4, "kind": "mud", "pin": Vector2(670.0, -2300.0)
	})
	m.patches.append({
		"y": -3100.0, "at": 0.48, "rx": 85.0, "ry": 38.0,
		"seed": 3.9, "kind": "mud", "pin": Vector2(630.0, -3100.0)
	})

	# 4. Hydrants: Wooden waymarker trail posts
	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 30.0, -500.0),
		Vector2(WALL_R - 30.0, -1500.0),
		Vector2(WALL_L + 30.0, -2500.0),
		Vector2(WALL_R - 30.0, -3500.0),
		Vector2(WALL_L + 30.0, -4300.0),
	]

	# 5. Kebabs: Dropped bocadillos & roasted chestnuts
	var keb_list: Array[Vector2] = [
		Vector2(620.0, -1600.0),
		Vector2(700.0, -2900.0),
		Vector2(550.0, -3700.0),
	]

	# 6. Prize
	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT

	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [
		LOG_1,
		LOG_2,
		PICNIC_TABLE,
		Rect2(DUMPSTER_JAM_1 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE),
		Rect2(DUMPSTER_JAM_2 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE),
	]


static func wrap_rects() -> Array[Rect2]:
	return [
		LOG_1,
		LOG_2,
		PICNIC_TABLE,
		Rect2(DUMPSTER_JAM_1 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE),
		Rect2(DUMPSTER_JAM_2 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE),
	]


static func surface(_m: Node2D, p: Vector2) -> int:
	# Check mud patches
	if absf(p.y - (-1100.0)) < 35.0 and absf(p.x - 610.0) < 80.0:
		return Surfaces.S.MUD
	if absf(p.y - (-2300.0)) < 40.0 and absf(p.x - 670.0) < 90.0:
		return Surfaces.S.MUD
	if absf(p.y - (-3100.0)) < 38.0 and absf(p.x - 630.0) < 85.0:
		return Surfaces.S.MUD
	if p.x < WALL_L or p.x > WALL_R:
		return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# Draw hillside dirt verges, pine trunks, and fallen logs
	var step := 70.0
	var sy := floorf(vt / step) * step
	while sy < vb:
		# Left verge trees
		b.circle(Vector2(WALL_L - 40.0, sy + 30.0), 32.0, PINE_GREEN)
		b.circle(Vector2(WALL_L - 15.0, sy + 25.0), 10.0, WOOD_BARK)
		# Right verge trees
		b.circle(Vector2(WALL_R + 40.0, sy + 45.0), 34.0, PINE_GREEN)
		b.circle(Vector2(WALL_R + 15.0, sy + 40.0), 11.0, WOOD_BARK)
		sy += step

	# Draw fallen logs if visible
	if vb > LOG_1.position.y and vt < LOG_1.end.y:
		b.rect(LOG_1, WOOD_BARK)
		b.circle(Vector2(LOG_1.position.x, LOG_1.get_center().y), LOG_1.size.y * 0.5, WOOD_SAWN)
		b.circle(Vector2(LOG_1.end.x, LOG_1.get_center().y), LOG_1.size.y * 0.5, WOOD_SAWN)
	if vb > LOG_2.position.y and vt < LOG_2.end.y:
		b.rect(LOG_2, WOOD_BARK)
		b.circle(Vector2(LOG_2.position.x, LOG_2.get_center().y), LOG_2.size.y * 0.5, WOOD_SAWN)
		b.circle(Vector2(LOG_2.end.x, LOG_2.get_center().y), LOG_2.size.y * 0.5, WOOD_SAWN)

	# Draw picnic table
	if vb > PICNIC_TABLE.position.y and vt < PICNIC_TABLE.end.y:
		b.rect(PICNIC_TABLE, WOOD_SAWN)
		b.rect(Rect2(PICNIC_TABLE.position.x + 6.0, PICNIC_TABLE.position.y + 6.0, PICNIC_TABLE.size.x - 12.0, PICNIC_TABLE.size.y - 12.0), WOOD_BARK)

	# Draw overturned dumpster respites
	var d1 := Rect2(DUMPSTER_JAM_1 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE)
	if vb > d1.position.y and vt < d1.end.y:
		b.rect(d1, Color(0.18, 0.45, 0.25))
		b.rect(Rect2(d1.position.x + 4.0, d1.position.y + 4.0, d1.size.x - 8.0, d1.size.y - 8.0), Color(0.12, 0.32, 0.18))
	var d2 := Rect2(DUMPSTER_JAM_2 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE)
	if vb > d2.position.y and vt < d2.end.y:
		b.rect(d2, Color(0.18, 0.45, 0.25))
		b.rect(Rect2(d2.position.x + 4.0, d2.position.y + 4.0, d2.size.x - 8.0, d2.size.y - 8.0), Color(0.12, 0.32, 0.18))


static func draw_overhead(_m: Node2D, _ci: CanvasItem) -> void:
	pass


static func tick(m: Node2D, _delta: float) -> void:
	if m == null or m.dog == null:
		return
	var dp: Vector2 = m.dog.global_position
	# Track mud splashes for goal
	if surface(m, dp) == Surfaces.S.MUD and m.dog.vel.length() > 140.0:
		var cur_val = m.get("boar_mud_splashes")
		m.set("boar_mud_splashes", (int(cur_val) if cur_val != null else 0) + 1)
