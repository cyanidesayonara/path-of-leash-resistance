class_name Poble
extends RefCounted

# WALK: EL POBLE ESPANYOL ("The walled village of copied towns").
# The 1929 Exhibition open-air architectural village on Montjuic:
#   1. Open approach road below the medieval curtain walls (y = 260 .. -460)
#   2. Stone city gate between two huge round crenellated towers (pinch, y = -460 .. -640)
#   3. Narrow winding Castilian street of stone & half-timbered houses with
#      wooden balconies and the glassblower's furnace workshop (y = -640 .. -1740)
#   4. The Plaza Mayor: wide arcaded square (big bulge, y = -1740 .. -3040) with
#      ten wrap-able stone arcade columns, central octagonal stone fountain,
#      cafe tables with seated customers under the arcades, strings of bunting,
#      festival stage at the north end, potter's wheel workshop, and a tour guide
#      with a raised folded umbrella leading tourists
#   5. Whitewashed Andalusian quarter: stepped pebble-mosaic lane, dazzling white
#      walls, cobalt-blue window frames, geranium pots on every sill & balcony,
#      leather workshop, and the PobleBalcony watering-can live event (y = -3040 .. -4320)
#   6. Aragonese Mudejar brick tower with geometric brick reliefs, glazed tile
#      friezes, and pointed spire roof as the far landmark (y = -4320 .. -5000)
#   7. Off-leash area (Jardi dels Olivers): terraced garden on the old bastion
#      walls with gnarled olive trees, dry-stone walls, a low crenellated parapet,
#      and a daytime panoramic view of Barcelona and the sea below (y = -5000 .. -5620)

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const PobleBalcony := preload("res://systems/poble_balcony.gd")

const OVERHEAD_FOLLOWS_CAMERA := true

const HALF := 390.0
const WALL_L := 250.0
const WALL_R := 1030.0
const LIGHT := Vector2(0.6, 0.8)
const SHADOW := Color(0.05, 0.04, 0.08, 0.24)

# Architectural zone boundaries (south to north)
const GATE_PINCH_BOT := -460.0
const GATE_PINCH_TOP := -640.0
const CASTILIAN_TOP := -1740.0
const PLAZA_BOT := -1820.0
const PLAZA_TOP := -3020.0
const ANDALUS_BOT := -3060.0
const ANDALUS_TOP := -4300.0
const ARAGON_BOT := -4320.0

# 1. Medieval City Gate (Portal d'Avila homage): two big round crenellated towers
const GATE_TOWER_L := Vector2(422.0, -550.0)
const GATE_TOWER_R := Vector2(858.0, -550.0)
const GATE_TOWER_R_PX := 68.0
const GATE_ARCH_RECT := Rect2(422.0, -584.0, 436.0, 68.0)
const GATE_COLUMNS: Array[Vector2] = [
	Vector2(496.0, -550.0),
	Vector2(784.0, -550.0),
]

# 2. Plaza Mayor: 10 real stone arcade columns (5 west, 5 east) that the rope wraps
const ARCADE_COLUMNS: Array[Vector2] = [
	Vector2(305.0, -1940.0),
	Vector2(975.0, -1940.0),
	Vector2(305.0, -2150.0),
	Vector2(975.0, -2150.0),
	Vector2(305.0, -2360.0),
	Vector2(975.0, -2360.0),
	Vector2(305.0, -2570.0),
	Vector2(975.0, -2570.0),
	Vector2(305.0, -2780.0),
	Vector2(975.0, -2780.0),
]

# Central stone fountain in Plaza Mayor (real wrap obstacle + drinkable basin)
const FOUNTAIN_POS := Vector2(640.0, -2360.0)
const FOUNTAIN_R := 44.0
const FOUNTAIN_ISLAND := Rect2(590.0, -2410.0, 100.0, 100.0)

# Cafe tables under the west and east arcades of Plaza Mayor
const CAFE_TABLES: Array[Vector2] = [
	Vector2(358.0, -2045.0),
	Vector2(358.0, -2255.0),
	Vector2(358.0, -2465.0),
	Vector2(358.0, -2675.0),
	Vector2(922.0, -2045.0),
	Vector2(922.0, -2465.0),
	Vector2(922.0, -2675.0),
]

# Festival stage at the north end of Plaza Mayor
const STAGE_RECT := Rect2(500.0, -2965.0, 280.0, 72.0)

# Tour guide with raised folded umbrella and tourist group in Plaza Mayor
const GUIDE_POS := Vector2(538.0, -2210.0)
const TOURIST_SPOTS: Array[Vector2] = [
	Vector2(508.0, -2182.0),
	Vector2(548.0, -2174.0),
	Vector2(524.0, -2152.0),
]

# 3. Three craft workshops along the walk (glassblower, potter, leather shop)
const WORKSHOPS: Array[Dictionary] = [
	{
		"id": "glass",
		"name": "glass shop",
		"pos": Vector2(422.0, -1080.0),
		"side": -1.0,
	},
	{
		"id": "pottery",
		"name": "potter's wheel",
		"pos": Vector2(936.0, -2255.0),
		"side": 1.0,
	},
	{
		"id": "leather",
		"name": "leather shop",
		"pos": Vector2(436.0, -3520.0),
		"side": -1.0,
	},
]
const WORKSHOP_SNIFF_R := 74.0

# 4. Aragonese Mudejar brick tower with pointed roof (far landmark)
const TOWER_POS := Vector2(822.0, -4640.0)
const TOWER_RECT := Rect2(752.0, -4710.0, 140.0, 140.0)
const TOWER_COLUMN := Vector2(515.0, -4640.0)

# Unique walk prize: artisan hand-blown glass porron on the master table near the brick tower
const PRIZE := Vector2(515.0, -4480.0)
const PRIZE_TEXT := "swipe the glass porron off the table"


static func edge_nodes(_m: Node2D) -> Array:
	return [
		{"y": 260.0, "cx": 640.0, "half": 280.0},
		{"y": -320.0, "cx": 640.0, "half": 260.0},
		{"y": -460.0, "cx": 640.0, "half": 150.0},
		{"y": -640.0, "cx": 640.0, "half": 150.0},
		{"y": -820.0, "cx": 600.0, "half": 185.0},
		{"y": -1120.0, "cx": 560.0, "half": 185.0},
		{"y": -1480.0, "cx": 700.0, "half": 185.0},
		{"y": -1720.0, "cx": 640.0, "half": 225.0},
		{"y": -1860.0, "cx": 640.0, "half": 390.0},
		{"y": -2980.0, "cx": 640.0, "half": 390.0},
		{"y": -3140.0, "cx": 610.0, "half": 205.0},
		{"y": -3520.0, "cx": 580.0, "half": 195.0},
		{"y": -3960.0, "cx": 665.0, "half": 195.0},
		{"y": -4260.0, "cx": 640.0, "half": 225.0},
		{"y": -4420.0, "cx": 640.0, "half": 260.0},
		{"y": -5000.0, "cx": 640.0, "half": 260.0},
	]


static func build(m: Node2D) -> Array:
	m.gate_text = "JARDÍ DELS OLIVERS"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 420.0
	m.gate_r = 860.0

	# Reset walk-specific goal state
	m.poble_columns_wrapped = {}
	m.poble_workshops_sniffed = {}
	m.poble_shakes = 0
	m.poble_fountain_wrapped = false
	m.poble_balcony = PobleBalcony.new()

	# Real wrap poles: gate pinch piers, 10 Plaza Mayor arcade columns, tower court cross
	for gp: Vector2 in GATE_COLUMNS:
		m.poles.append(gp)
	for col: Vector2 in ARCADE_COLUMNS:
		m.poles.append(col)
	m.poles.append(TOWER_COLUMN)
	m.deco_pole_count = m.poles.size()

	# Central fountain in Plaza Mayor is also a real wrap pole and drinkable water source
	m.poles.append(FOUNTAIN_POS)
	m.fountains = Array([FOUNTAIN_POS], TYPE_VECTOR2, &"", null)

	# Cafe tables and chairs under the Plaza Mayor arcades + prize display table
	m.tables.clear()
	m.chairs.clear()
	for tp: Vector2 in CAFE_TABLES:
		m.tables.append(tp)
		var c_side: float = 1.0 if tp.x < 640.0 else -1.0
		m.chairs.append(tp + Vector2(c_side * 22.0, -14.0))
		m.chairs.append(tp + Vector2(c_side * 22.0, 14.0))
	m.tables.append(PRIZE)

	# Benches and waste bins along the village route
	m.benches = Array([
		Vector2(435.0, -180.0),
		Vector2(845.0, -180.0),
		Vector2(455.0, -1880.0),
		Vector2(825.0, -1880.0),
		Vector2(455.0, -2860.0),
		Vector2(825.0, -2860.0),
		Vector2(450.0, -4780.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(445.0, -340.0),
		Vector2(730.0, -960.0),
		Vector2(330.0, -2000.0),
		Vector2(950.0, -2720.0),
		Vector2(745.0, -3380.0),
		Vector2(440.0, -4560.0),
	], TYPE_VECTOR2, &"", null)

	# Owner route islands around the central Plaza Mayor fountain, north stage, and brick tower
	m.islands.append({"rect": FOUNTAIN_ISLAND, "side": -1.0, "lead": 320.0})
	m.islands.append({"rect": STAGE_RECT, "side": -1.0, "lead": 260.0})
	m.islands.append({"rect": TOWER_RECT, "side": -1.0, "lead": 320.0})

	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT

	# Stone bollards / milestones and craft workshop thresholds for marking and sniffing along the village
	var hyd_list: Array[Vector2] = [
		Vector2(445.0, -120.0),
		Vector2(710.0, -880.0),
		Vector2(436.0, -1080.0),
		Vector2(555.0, -1380.0),
		Vector2(325.0, -2260.0),
		Vector2(920.0, -2255.0),
		Vector2(955.0, -2520.0),
		Vector2(735.0, -3220.0),
		Vector2(450.0, -3520.0),
		Vector2(505.0, -3840.0),
		Vector2(445.0, -4420.0),
	]
	# Dropped village pastries (empanadillas & churros) for snack goal
	var keb_list: Array[Vector2] = [
		Vector2(585.0, -1240.0),
		Vector2(465.0, -2420.0),
		Vector2(785.0, -2620.0),
		Vector2(615.0, -3720.0),
	]
	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.append(STAGE_RECT)
	out.append(TOWER_RECT)
	return out


static func surface(m: Node2D, p: Vector2) -> int:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	if p.y <= gate_y:
		if p.x >= 340.0 and p.x <= 940.0 and p.y >= gate_y - 565.0:
			return Surfaces.S.PAVEMENT
		return Surfaces.S.GRASS
	if p.distance_to(FOUNTAIN_POS) <= FOUNTAIN_R:
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


static func _arcade_col_index(pole: Vector2) -> int:
	for i: int in range(ARCADE_COLUMNS.size()):
		if pole.distance_to(ARCADE_COLUMNS[i]) <= 24.0:
			return i
	return -1


static func tick(m: Node2D, dt: float) -> void:
	if m == null or m.dog == null or m.human == null:
		return
	var dpos: Vector2 = m.dog.global_position

	# 1. Track leash wraps around the Plaza Mayor arcade columns and central fountain
	if m.leash != null and m.leash.static_contacts > 0:
		var sfx = m.get_node_or_null("/root/Sfx")
		for contact_p: Vector2 in [m.leash.contact_pole, m.leash.human_contact_pole]:
			if contact_p.x >= INF:
				continue
			var col_idx: int = _arcade_col_index(contact_p)
			if col_idx >= 0 and not m.poble_columns_wrapped.has(col_idx):
				m.poble_columns_wrapped[col_idx] = true
				if m.has_method("award_points"):
					m.award_points(2, "arcade wrap! +2")
				if m.get("combo") != null:
					m.combo.add("ARCADE WRAP", 2)
				if sfx != null:
					sfx.play("star", 1.15, -5.0)
			elif not m.poble_fountain_wrapped and contact_p.distance_to(FOUNTAIN_POS) <= 28.0:
				m.poble_fountain_wrapped = true
				if m.has_method("award_points"):
					m.award_points(2, "fountain wrap! +2")
				if m.get("combo") != null:
					m.combo.add("FOUNTAIN WRAP", 2)
				if sfx != null:
					sfx.play("star", 1.18, -5.0)

	# 2. Track sniffing the 3 craft workshops (glassblower, potter's wheel, leather shop)
	for i: int in range(WORKSHOPS.size()):
		if m.poble_workshops_sniffed.has(i):
			continue
		var ws: Dictionary = WORKSHOPS[i]
		var wpos: Vector2 = ws["pos"]
		var near_ws: bool = dpos.distance_to(wpos) <= WORKSHOP_SNIFF_R
		if near_ws and (bool(m.dog.sniffing) or m.dog.velocity.length() <= 170.0):
			m.poble_workshops_sniffed[i] = true
			if m.has_method("award_points"):
				m.award_points(2, String(ws["name"]) + "! +2")
			if m.get("combo") != null:
				m.combo.add("CRAFT SNIFF", 2)
			var sfx = m.get_node_or_null("/root/Sfx")
			if sfx != null:
				sfx.play("sniff", 1.15, -4.0)
				sfx.play("star", 1.12, -5.0)

	# 3. Tick the Andalusian balcony watering-can live event
	if m.poble_balcony != null:
		m.poble_balcony.tick(m, dt)


static func on_bark(m: Node2D, bark_pos: Vector2 = Vector2.ZERO) -> bool:
	var bp: Vector2 = bark_pos if bark_pos != Vector2.ZERO else m.dog.global_position
	if m.poble_balcony != null and m.poble_balcony.on_bark(m, bp):
		return true
	# Barking at the tour guide in Plaza Mayor gets a guide announcement
	if bp.distance_to(GUIDE_POS) <= 150.0:
		if m.has_method("float_text"):
			m.float_text(GUIDE_POS + Vector2(0.0, -34.0), "Follow the yellow umbrella!", Color(0.98, 0.95, 0.86), m.POP_SAY)
		return true
	return false


# --- ground layer (cached per chunk via draw_cross_section) ------------------

static func draw_cross_section(m: Node2D, wc: Object, _top: float, bottom: float, _ctop: float, vt: float, vb: float) -> void:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	var y0 := maxf(vt - 80.0, gate_y - 40.0)
	var y1 := minf(vb + 80.0, bottom)
	if y1 <= y0:
		return

	var b := ShapeBatch.new()
	var step := 32.0
	var sy := floorf(y0 / step) * step
	while sy < y1:
		var sb := minf(sy + step, y1)
		var ym := (sy + sb) * 0.5
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sb)
		var row := absi(int(floorf(sy / step)))

		if ym > GATE_PINCH_BOT:
			# 1. Open Montjuic approach road below the walls: warm golden-ochre cobble fan
			var col := Color(0.68, 0.62, 0.52) if row % 2 == 0 else Color(0.64, 0.58, 0.49)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), col)
			b.line(Vector2(ea.x + 18.0, sy), Vector2(eb.x + 18.0, sb), Color(0.48, 0.43, 0.36), 3.0)
			b.line(Vector2(ea.y - 18.0, sy), Vector2(eb.y - 18.0, sb), Color(0.48, 0.43, 0.36), 3.0)
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.50, 0.45, 0.38, 0.45), 1.5)
		elif ym > GATE_PINCH_TOP:
			# 2. Stone city gate threshold: heavy granite flagstones worn by cart wheels
			var g_col := Color(0.52, 0.50, 0.47) if row % 2 == 0 else Color(0.48, 0.46, 0.44)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), g_col)
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.32, 0.30, 0.28, 0.65), 2.0)
			for rut_x: float in [595.0, 685.0]:
				b.line(Vector2(rut_x, sy), Vector2(rut_x, sb), Color(0.36, 0.34, 0.32, 0.55), 3.5)
		elif ym > CASTILIAN_TOP:
			# 3. Winding Castilian street: warm brown-grey stone cobbles with central rain gutter
			var c_col := Color(0.62, 0.55, 0.47) if row % 2 == 0 else Color(0.58, 0.51, 0.44)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), c_col)
			var cxa := (ea.x + ea.y) * 0.5
			var cxb := (eb.x + eb.y) * 0.5
			# Central stone drainage channel (reguera)
			b.line(Vector2(cxa, sy), Vector2(cxb, sb), Color(0.40, 0.35, 0.30), 8.0)
			b.line(Vector2(cxa, sy), Vector2(cxb, sb), Color(0.30, 0.26, 0.22), 2.5)
			# Transverse cobble courses and west overhang shadow
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.44, 0.38, 0.32, 0.45), 1.4)
			b.quad(Vector2(ea.x, sy), Vector2(ea.x + 28.0, sy), Vector2(eb.x + 28.0, sb), Vector2(eb.x, sb), Color(0.05, 0.04, 0.08, 0.16))
		elif ym > PLAZA_TOP:
			# 4. The Plaza Mayor: warm ochre & terracotta stone square with arcade aprons
			var p_col := Color(0.78, 0.68, 0.55) if row % 2 == 0 else Color(0.75, 0.65, 0.52)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), p_col)
			# Shaded stone colonnade aprons under the west (x < 320) and east (x > 960) arcades
			if ea.x < 320.0:
				b.rect(Rect2(ea.x, sy, 320.0 - ea.x, sb - sy), Color(0.62, 0.53, 0.43))
				b.line(Vector2(320.0, sy), Vector2(320.0, sb), Color(0.46, 0.39, 0.32), 2.5)
			if ea.y > 960.0:
				b.rect(Rect2(960.0, sy, ea.y - 960.0, sb - sy), Color(0.62, 0.53, 0.43))
				b.line(Vector2(960.0, sy), Vector2(960.0, sb), Color(0.46, 0.39, 0.32), 2.5)
			# Plaza stone grid seams
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.56, 0.47, 0.38, 0.38), 1.4)
			var jx := 360.0
			while jx < 940.0:
				b.line(Vector2(jx, sy), Vector2(jx, sb), Color(0.56, 0.47, 0.38, 0.30), 1.2)
				jx += 64.0
		elif ym > ANDALUS_TOP:
			# 5. Whitewashed Andalusian quarter: stepped lane with Cordoba pebble-mosaic treads
			var a_col := Color(0.86, 0.83, 0.77) if row % 2 == 0 else Color(0.82, 0.79, 0.73)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), a_col)
			var cxa := (ea.x + ea.y) * 0.5
			var cxb := (eb.x + eb.y) * 0.5
			var cm := Vector2((cxa + cxb) * 0.5, ym)
			# Pebble-mosaic dark border lines flanking the central empedrado cordobés runner
			b.line(Vector2(cxa - 36.0, sy), Vector2(cxb - 36.0, sb), Color(0.28, 0.29, 0.32), 2.5)
			b.line(Vector2(cxa + 36.0, sy), Vector2(cxb + 36.0, sb), Color(0.28, 0.29, 0.32), 2.5)
			# Alternating dark slate & ivory quartz diamond medallions
			b.polygon(PackedVector2Array([
				Vector2(cm.x, ym - 13.0),
				Vector2(cm.x + 18.0, ym),
				Vector2(cm.x, ym + 13.0),
				Vector2(cm.x - 18.0, ym),
			]), Color(0.26, 0.27, 0.30))
			b.polygon(PackedVector2Array([
				Vector2(cm.x, ym - 7.5),
				Vector2(cm.x + 10.0, ym),
				Vector2(cm.x, ym + 7.5),
				Vector2(cm.x - 10.0, ym),
			]), Color(0.93, 0.91, 0.86))
			b.circle(cm, 2.5, Color(0.26, 0.27, 0.30))
			# Every 3rd band (96 px) is a broad whitewashed stone step riser across the lane
			if row % 3 == 0:
				b.line(Vector2(ea.x + 2.0, sy + 3.0), Vector2(ea.y - 2.0, sy + 3.0), Color(0.97, 0.96, 0.94), 5.0)
				b.line(Vector2(ea.x + 2.0, sy + 7.5), Vector2(ea.y - 2.0, sy + 7.5), Color(0.28, 0.26, 0.24, 0.50), 3.5)
				# Terracotta flower pots with scarlet & magenta geraniums beside the walls
				for px_side: float in [ea.x + 10.0, ea.y - 10.0]:
					b.circle(Vector2(px_side, sy + 4.0), 4.2, Color(0.72, 0.34, 0.18))
					b.circle(Vector2(px_side, sy + 2.0), 3.8, Color(0.18, 0.46, 0.20))
					b.circle(Vector2(px_side, sy + 1.0), 2.8, Color(0.92, 0.14, 0.20) if row % 2 == 0 else Color(0.94, 0.24, 0.44))
		else:
			# 6. Aragonese Mudejar brick tower court: warm red-ochre herringbone brick & stone paving
			var t_col := Color(0.72, 0.58, 0.46) if row % 2 == 0 else Color(0.68, 0.54, 0.43)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), t_col)
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.52, 0.36, 0.26, 0.45), 1.8)
			for bx: float in [460.0, 580.0, 700.0]:
				b.line(Vector2(bx, sy), Vector2(bx, sb), Color(0.54, 0.38, 0.28, 0.40), 2.0)

		sy += step

	# The arcades: the ground between the house fronts and the column line is
	# covered, so it lies in a shade that deepens toward the wall, and each bay
	# is marked by its transverse arch, a stone rib from the column to the
	# wall, with a lantern hanging in the middle of the bay
	var arc_lo := maxf(y0, PLAZA_TOP + 80.0)
	var arc_hi := minf(y1, PLAZA_BOT - 40.0)
	if arc_hi > arc_lo:
		for side: float in [-1.0, 1.0]:
			var wall := float(WALL_L) if side < 0.0 else float(WALL_R)
			var col_x := 305.0 if side < 0.0 else 975.0
			var pts := PackedVector2Array([
				Vector2(wall, arc_lo), Vector2(lerpf(wall, col_x, 0.55), arc_lo), Vector2(col_x + side * -14.0, arc_lo),
				Vector2(wall, arc_hi), Vector2(lerpf(wall, col_x, 0.55), arc_hi), Vector2(col_x + side * -14.0, arc_hi),
			])
			b.band(pts, 3, Color(0.10, 0.07, 0.05), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.34, 0.20, 0.04]))
			var prev_y := INF
			for cp: Vector2 in ARCADE_COLUMNS:
				if absf(cp.x - col_x) > 1.0 or cp.y < arc_lo - 120.0 or cp.y > arc_hi + 120.0:
					continue
				b.line(Vector2(wall, cp.y), cp, Color(0.56, 0.47, 0.37), 6.0)
				b.line(Vector2(wall, cp.y - 2.0), cp + Vector2(0.0, -2.0), Color(0.74, 0.65, 0.52), 1.5)
				if prev_y < INF:
					var lp := Vector2(lerpf(wall, col_x, 0.5), (prev_y + cp.y) * 0.5)
					b.line(Vector2(wall, lp.y), lp, Color(0.18, 0.16, 0.14, 0.6), 1.0)
					b.circle(lp + LIGHT * 4.0, 5.0, SHADOW)
					b.circle(lp, 4.5, Color(0.16, 0.14, 0.13))
					b.circle(lp, 2.6, Color(1.0, 0.80, 0.42))
				prev_y = cp.y

	# Concentric decorative stone rings & compass rose around the Plaza Mayor fountain
	if FOUNTAIN_POS.y + 180.0 >= y0 and FOUNTAIN_POS.y - 180.0 <= y1:
		b.circle(FOUNTAIN_POS, 136.0, Color(0.66, 0.55, 0.44))
		b.circle(FOUNTAIN_POS, 128.0, Color(0.82, 0.73, 0.60))
		b.circle(FOUNTAIN_POS, 88.0, Color(0.64, 0.53, 0.42))
		b.circle(FOUNTAIN_POS, 82.0, Color(0.78, 0.68, 0.55))
		for sp_i: int in range(8):
			var ang := float(sp_i) * TAU / 8.0
			var dir := Vector2(cos(ang), sin(ang))
			b.line(FOUNTAIN_POS + dir * 48.0, FOUNTAIN_POS + dir * 134.0, Color(0.58, 0.48, 0.38), 2.5)

	# Draw the Plaza Mayor festival stage at the north end of the square
	if STAGE_RECT.end.y + 30.0 >= y0 and STAGE_RECT.position.y - 30.0 <= y1:
		_draw_plaza_stage(b)

	# Draw the 3 craft workshop ground aprons & workbenches
	for ws: Dictionary in WORKSHOPS:
		var wp: Vector2 = ws["pos"]
		if wp.y + 80.0 >= y0 and wp.y - 80.0 <= y1:
			_draw_workshop(b, ws)

	# Draw the Aragonese Mudejar brick tower landmark in the far court
	if TOWER_POS.y + 180.0 >= y0 and TOWER_POS.y - 220.0 <= y1:
		_draw_aragonese_tower(b)

	# Off-leash threshold band at GATE_Y (-5000): dark slate threshold with terracotta border
	# so the white mosaic azulejo letters "OFF LEASH / JARDÍ DELS OLIVERS" read with crisp contrast
	if -5090.0 <= y1 and -4940.0 >= y0:
		var te_a: Vector2 = m.walk_edges(-5075.0)
		var te_b: Vector2 = m.walk_edges(-4965.0)
		var t_left := minf(te_a.x, te_b.x) - 4.0
		var t_right := maxf(te_a.y, te_b.y) + 4.0
		# Terracotta border course
		b.rect(Rect2(t_left - 6.0, -5080.0, t_right - t_left + 12.0, 118.0), Color(0.66, 0.34, 0.22))
		# Dark charcoal slate threshold slab
		b.rect(Rect2(t_left, -5074.0, t_right - t_left, 106.0), Color(0.25, 0.24, 0.26))
		b.line(Vector2(t_left, -5074.0), Vector2(t_right, -5074.0), Color(0.38, 0.36, 0.38), 2.0)
		b.line(Vector2(t_left, -4968.0), Vector2(t_right, -4968.0), Color(0.16, 0.15, 0.17), 2.5)

	b.flush(wc)


static func _draw_plaza_stage(b: ShapeBatch) -> void:
	var r := STAGE_RECT
	b.rect(Rect2(r.position + LIGHT * 8.0, r.size), SHADOW)
	# Stone plinth and dark timber stage deck
	b.rect(r.grow(4.0), Color(0.46, 0.40, 0.34))
	b.rect(r, Color(0.48, 0.32, 0.20))
	var px := r.position.x + 14.0
	while px < r.end.x - 6.0:
		b.line(Vector2(px, r.position.y + 4.0), Vector2(px, r.end.y - 4.0), Color(0.36, 0.23, 0.14), 1.6)
		px += 16.0
	# Crimson velvet backdrop curtain along the north edge of the stage
	b.rect(Rect2(r.position.x + 8.0, r.position.y + 4.0, r.size.x - 16.0, 14.0), Color(0.68, 0.14, 0.18))
	b.line(Vector2(r.position.x + 8.0, r.position.y + 18.0), Vector2(r.end.x - 8.0, r.position.y + 18.0), Color(0.92, 0.76, 0.32), 2.5)
	# Warm brass footlights along the front edge
	for lx: float in [535.0, 585.0, 640.0, 695.0, 745.0]:
		var lp := Vector2(lx, r.end.y - 6.0)
		b.glow(lp, 18.0, Color(1.0, 0.88, 0.48, 0.25))
		b.circle(lp, 3.5, Color(0.22, 0.20, 0.18))
		b.circle(lp, 2.0, Color(1.0, 0.92, 0.62))
	# Spanish acoustic guitar on stand + wooden flamenco cajon box
	var gp := Vector2(605.0, r.get_center().y + 4.0)
	b.circle(gp, 8.5, Color(0.76, 0.48, 0.22))
	b.circle(gp + Vector2(5.0, -4.0), 6.2, Color(0.76, 0.48, 0.22))
	b.circle(gp + Vector2(2.0, -2.0), 2.5, Color(0.18, 0.12, 0.08))
	b.line(gp + Vector2(5.0, -4.0), gp + Vector2(14.0, -11.0), Color(0.32, 0.20, 0.12), 2.5)
	var caj := Rect2(666.0, r.get_center().y - 6.0, 18.0, 18.0)
	b.rect(caj, Color(0.62, 0.42, 0.24))
	b.rect(caj.grow(-3.0), Color(0.78, 0.58, 0.36))


static func _draw_workshop(b: ShapeBatch, ws: Dictionary) -> void:
	var kind := String(ws["id"])
	var p: Vector2 = ws["pos"]
	var side: float = float(ws["side"])
	# Cobble workshop apron
	b.circle(p + LIGHT * 5.0, 34.0, SHADOW)
	b.circle(p, 33.0, Color(0.56, 0.48, 0.40))
	b.circle(p, 29.0, Color(0.68, 0.60, 0.50))

	if kind == "glass":
		# Glassblower's furnace (Forn de Vidre): beehive brick kiln with glowing glory-hole
		var kiln := p + Vector2(-12.0, -8.0)
		b.glow(kiln + Vector2(8.0, 4.0), 42.0, Color(1.0, 0.52, 0.14, 0.38))
		b.circle(kiln, 16.0, Color(0.58, 0.26, 0.18))
		b.circle(kiln, 12.5, Color(0.72, 0.34, 0.22))
		b.circle(kiln + Vector2(5.0, 2.0), 6.5, Color(1.0, 0.64, 0.18))
		b.circle(kiln + Vector2(6.0, 2.0), 3.8, Color(1.0, 0.94, 0.68))
		# Iron blowpipes resting across the marvering rack
		b.line(kiln + Vector2(4.0, 2.0), p + Vector2(18.0, 12.0), Color(0.32, 0.34, 0.38), 2.2)
		b.circle(p + Vector2(18.0, 12.0), 4.0, Color(1.0, 0.58, 0.16))
		# Display bench with cobalt, emerald, and amber blown-glass pitchers
		var tbl := Rect2(p.x - 6.0, p.y + 8.0, 28.0, 14.0)
		b.rect(tbl, Color(0.46, 0.32, 0.20))
		b.circle(tbl.position + Vector2(6.0, 7.0), 3.8, Color(0.18, 0.44, 0.86))
		b.circle(tbl.position + Vector2(14.0, 6.0), 4.2, Color(0.18, 0.72, 0.48))
		b.circle(tbl.position + Vector2(22.0, 7.5), 3.6, Color(0.92, 0.64, 0.18))
	elif kind == "pottery":
		# Potter's Wheel (Taller de Ceramica): spinning kick-wheel & painted Talavera plates
		var wheel := p + Vector2(-8.0, -4.0)
		b.circle(wheel, 14.0, Color(0.42, 0.30, 0.20))
		b.circle(wheel, 11.0, Color(0.76, 0.72, 0.66))
		b.circle(wheel, 6.5, Color(0.78, 0.42, 0.26))
		b.circle(wheel, 3.0, Color(0.52, 0.26, 0.16))
		# Shelf of hand-painted blue-and-gold ceramic plates and terracotta jugs
		var rack := Rect2(p.x + 6.0, p.y - 18.0, 16.0, 36.0)
		b.rect(rack, Color(0.44, 0.30, 0.18))
		for py_off: float in [-11.0, 0.0, 11.0]:
			var pp := Vector2(rack.get_center().x, p.y + py_off)
			b.circle(pp, 5.2, Color(0.96, 0.94, 0.88))
			b.circle(pp, 3.6, Color(0.18, 0.42, 0.82) if int(absf(py_off)) > 5 else Color(0.90, 0.68, 0.18))
			b.circle(pp, 1.6, Color(0.96, 0.94, 0.88))
	else:
		# Leather Shop (Taller de Cuir): tanned hides, embossed satchels & cobbler's bench
		var bench := Rect2(p.x - 16.0, p.y - 10.0, 32.0, 20.0)
		b.rect(bench, Color(0.48, 0.32, 0.18))
		# Stretched oxblood and saddle-brown leather hides on the table
		b.polygon(PackedVector2Array([
			p + Vector2(-12.0, -6.0), p + Vector2(6.0, -7.0),
			p + Vector2(10.0, 5.0), p + Vector2(-10.0, 6.0),
		]), Color(0.58, 0.26, 0.16))
		# Embossed leather bags and brass buckles on the display rack
		for bx_off: float in [-10.0, 0.0, 10.0]:
			var bp := p + Vector2(bx_off, 16.0 * (-side))
			b.circle(bp, 5.0, Color(0.46, 0.24, 0.12))
			b.circle(bp, 2.0, Color(0.88, 0.74, 0.32))


static func _draw_aragonese_tower(b: ShapeBatch) -> void:
	# Monumental Aragonese Mudejar brick bell tower (Torre d'Arago) with pointed roof spire
	var r := TOWER_RECT
	var c := TOWER_POS
	# Long cast shadow of the tower shaft and pointed spire across the upper plaza
	b.polygon(PackedVector2Array([
		Vector2(r.position.x, r.end.y),
		Vector2(r.end.x, r.position.y),
		c + LIGHT * 145.0 + Vector2(22.0, -22.0),
		c + LIGHT * 185.0,
		c + LIGHT * 145.0 + Vector2(-22.0, 22.0),
	]), Color(0.05, 0.04, 0.08, 0.26))

	# Stepped ashlar limestone plinth
	b.rect(r.grow(10.0), Color(0.56, 0.50, 0.42))
	b.rect(r.grow(4.0), Color(0.66, 0.58, 0.48))
	# Red-ochre Aragonese brick main shaft
	var brick_dark := Color(0.56, 0.25, 0.16)
	var brick_main := Color(0.68, 0.32, 0.20)
	var brick_lit := Color(0.78, 0.42, 0.26)
	b.rect(r, brick_dark)
	b.rect(r.grow(-5.0), brick_main)

	# Mudejar geometric diamond brick reliefs & emerald/white glazed azulejo tile bands
	for ring_inset: float in [10.0, 22.0]:
		var rr := r.grow(-ring_inset)
		b.rect(rr, Color(0.14, 0.52, 0.36) if ring_inset < 15.0 else Color(0.94, 0.92, 0.86))
		b.rect(rr.grow(-3.5), brick_main)
	# Corner brick buttress pilasters and white/green ceramic medallions
	for cx: float in [r.position.x + 8.0, r.end.x - 8.0]:
		for cy: float in [r.position.y + 8.0, r.end.y - 8.0]:
			var cp := Vector2(cx, cy)
			b.circle(cp, 7.5, brick_lit)
			b.circle(cp, 4.5, Color(0.14, 0.54, 0.38))
			b.circle(cp, 2.2, Color(0.96, 0.94, 0.88))

	# Octagonal belfry drum and arched bell openings
	for i: int in range(4):
		var a := float(i) * PI * 0.5
		var bp := c + Vector2(cos(a), sin(a)) * 44.0
		b.circle(bp, 8.0, Color(0.18, 0.12, 0.10))
		b.circle(bp, 4.5, Color(0.78, 0.62, 0.26)) # bronze bell

	# Steep octagonal pointed spire roof clad in terracotta & glazed green tiles
	var spire_tip := c - LIGHT * 18.0
	var oct_r := 52.0
	var oct_pts := PackedVector2Array()
	for i: int in range(8):
		var a := float(i) * TAU / 8.0 + PI / 8.0
		oct_pts.append(c + Vector2(cos(a), sin(a)) * oct_r)
	b.polygon(oct_pts, brick_dark)
	for i: int in range(8):
		var p1: Vector2 = oct_pts[i]
		var p2: Vector2 = oct_pts[(i + 1) % 8]
		var facet_col := brick_lit if i in [3, 4, 5] else (brick_main if i in [2, 6] else brick_dark)
		b.polygon(PackedVector2Array([spire_tip, p1, p2]), facet_col)
		# Glazed green ceramic chevron stripe mid-spire
		var m1 := spire_tip.lerp(p1, 0.58)
		var m2 := spire_tip.lerp(p2, 0.58)
		b.line(m1, m2, Color(0.16, 0.58, 0.40), 3.2)
		b.line(spire_tip, p1, Color(0.42, 0.18, 0.12), 1.8)
	# Wrought-iron cross finial and golden weathervane ball at the pointed peak
	b.circle(spire_tip, 6.5, Color(0.20, 0.20, 0.22))
	b.circle(spire_tip, 4.2, Color(0.94, 0.78, 0.30))


# --- edge layer: regional Spanish facades & medieval gate towers -------------

static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	var start_y: float = float(m.START_Y) if "START_Y" in m else 260.0
	var y_top := maxf(vt - 240.0, gate_y - 30.0)
	var y_bot := minf(vb + 240.0, start_y + 560.0)
	if y_bot <= y_top:
		return

	var step := 48.0
	var sy := floorf(y_top / step) * step
	while sy < y_bot:
		var sb := minf(sy + step, y_bot)
		if sb - sy >= 12.0:
			var ea: Vector2 = m.walk_edges(sy)
			var eb: Vector2 = m.walk_edges(sb)
			var ym := (sy + sb) * 0.5
			var row := absi(int(floorf(sy / step)))

			if ym > GATE_PINCH_BOT:
				# 1. Montjuïc approach road bank below the fortress walls
				b.quad(Vector2(-460.0, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(-460.0, sb), Color(0.32, 0.46, 0.26))
				b.line(Vector2(ea.x, sy), Vector2(eb.x, sb), Color(0.62, 0.54, 0.44), 5.0)
				b.quad(Vector2(ea.y, sy), Vector2(1740.0, sy), Vector2(1740.0, sb), Vector2(eb.y, sb), Color(0.32, 0.46, 0.26))
				b.line(Vector2(ea.y, sy), Vector2(eb.y, sb), Color(0.62, 0.54, 0.44), 5.0)
				if row % 3 == 0:
					for side: float in [-1.0, 1.0]:
						var cx := ea.x - 48.0 if side < 0.0 else ea.y + 48.0
						b.circle(Vector2(cx, ym) + LIGHT * 8.0, 20.0, SHADOW)
						b.circle(Vector2(cx, ym), 19.0, Color(0.18, 0.34, 0.20))
						b.circle(Vector2(cx, ym) - LIGHT * 4.0, 11.0, Color(0.26, 0.44, 0.26))
			elif ym > GATE_PINCH_TOP:
				# 2. Medieval curtain wall flanking the Avila gate towers
				b.quad(Vector2(-460.0, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(-460.0, sb), Color(0.46, 0.40, 0.32))
				b.line(Vector2(ea.x, sy), Vector2(eb.x, sb), Color(0.74, 0.66, 0.54), 6.0)
				b.line(Vector2(ea.x - 22.0, sy), Vector2(eb.x - 22.0, sb), Color(0.64, 0.56, 0.45), 4.0)
				b.quad(Vector2(ea.y, sy), Vector2(1740.0, sy), Vector2(1740.0, sb), Vector2(eb.y, sb), Color(0.46, 0.40, 0.32))
				b.line(Vector2(ea.y, sy), Vector2(eb.y, sb), Color(0.74, 0.66, 0.54), 6.0)
				b.line(Vector2(ea.y + 22.0, sy), Vector2(eb.y + 22.0, sb), Color(0.64, 0.56, 0.45), 4.0)
			elif ym > CASTILIAN_TOP:
				# 3. Winding Castilian half-timbered houses with dark oak balconies
				var face := 24.0
				var plaster := Color(0.84, 0.77, 0.66) if row % 4 < 2 else Color(0.78, 0.70, 0.58)
				var timber := Color(0.28, 0.19, 0.13)
				var roof_tile := Color(0.62, 0.33, 0.22) if row % 2 == 0 else Color(0.56, 0.29, 0.19)
				# West side
				b.quad(Vector2(-460.0, sy), Vector2(ea.x - face, sy), Vector2(eb.x - face, sb), Vector2(-460.0, sb), roof_tile)
				b.line(Vector2(-460.0, sy), Vector2(ea.x - face, sy), roof_tile.darkened(0.20), 1.8)
				b.quad(Vector2(ea.x - face, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(eb.x - face, sb), plaster)
				b.line(Vector2(ea.x - face, sy), Vector2(ea.x, sy), timber, 3.0)
				b.line(Vector2(ea.x, sy), Vector2(eb.x, sb), timber, 4.0)
				b.line(Vector2(ea.x - face, sy), Vector2(eb.x - face, sb), timber, 2.5)
				b.line(Vector2(ea.x - face, sy), Vector2(eb.x, sb), timber, 2.0)
				if row % 3 == 0:
					var bal_m := (ea.x + eb.x) * 0.5
					b.rect(Rect2(bal_m - 4.0, ym - 16.0, 18.0, 32.0), timber.darkened(0.20))
					b.rect(Rect2(bal_m - 2.0, ym - 14.0, 14.0, 28.0), Color(0.46, 0.31, 0.20))
					for by_off: float in [-10.0, 0.0, 10.0]:
						b.line(Vector2(bal_m - 4.0, ym + by_off), Vector2(bal_m + 14.0, ym + by_off), timber, 1.8)
				# East side
				b.quad(Vector2(ea.y, sy), Vector2(ea.y + face, sy), Vector2(eb.y + face, sb), Vector2(eb.y, sb), plaster)
				b.quad(Vector2(ea.y + face, sy), Vector2(1740.0, sy), Vector2(1740.0, sb), Vector2(eb.y + face, sb), roof_tile)
				b.line(Vector2(ea.y + face, sy), Vector2(1740.0, sy), roof_tile.darkened(0.20), 1.8)
				b.line(Vector2(ea.y, sy), Vector2(ea.y + face, sy), timber, 3.0)
				b.line(Vector2(ea.y, sy), Vector2(eb.y, sb), timber, 4.0)
				b.line(Vector2(ea.y + face, sy), Vector2(eb.y + face, sb), timber, 2.5)
				b.line(Vector2(ea.y + face, sy), Vector2(eb.y, sb), timber, 2.0)
				if (row + 1) % 3 == 0:
					var bal_m := (ea.y + eb.y) * 0.5
					b.rect(Rect2(bal_m - 14.0, ym - 16.0, 18.0, 32.0), timber.darkened(0.20))
					b.rect(Rect2(bal_m - 12.0, ym - 14.0, 14.0, 28.0), Color(0.46, 0.31, 0.20))
					for by_off: float in [-10.0, 0.0, 10.0]:
						b.line(Vector2(bal_m - 14.0, ym + by_off), Vector2(bal_m + 4.0, ym + by_off), timber, 1.8)
			elif ym > PLAZA_TOP:
				# 4. Plaza Mayor arcaded colonnade galleries & festival banners
				var gal_w := 64.0
				var stone := Color(0.76, 0.66, 0.52) if row % 2 == 0 else Color(0.72, 0.62, 0.49)
				var roof_tile := Color(0.60, 0.32, 0.21)
				# West arcade
				b.quad(Vector2(-460.0, sy), Vector2(ea.x - gal_w, sy), Vector2(eb.x - gal_w, sb), Vector2(-460.0, sb), roof_tile)
				b.line(Vector2(-460.0, sy), Vector2(ea.x - gal_w, sy), roof_tile.darkened(0.20), 1.8)
				b.quad(Vector2(ea.x - gal_w, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(eb.x - gal_w, sb), stone)
				b.line(Vector2(ea.x, sy), Vector2(eb.x, sb), stone.lightened(0.20), 4.5)
				if row % 2 == 0:
					var mx := (ea.x + eb.x) * 0.5
					b.rect(Rect2(mx - 18.0, ym - 12.0, 14.0, 24.0), Color(0.22, 0.18, 0.15))
					b.rect(Rect2(mx - 8.0, ym - 8.0, 10.0, 16.0), Color(0.76, 0.16, 0.18))
					b.line(Vector2(mx - 3.0, ym - 8.0), Vector2(mx - 3.0, ym + 8.0), Color(0.94, 0.78, 0.28), 2.0)
				# East arcade
				b.quad(Vector2(ea.y, sy), Vector2(ea.y + gal_w, sy), Vector2(eb.y + gal_w, sb), Vector2(eb.y, sb), stone)
				b.quad(Vector2(ea.y + gal_w, sy), Vector2(1740.0, sy), Vector2(1740.0, sb), Vector2(eb.y + gal_w, sb), roof_tile)
				b.line(Vector2(ea.y + gal_w, sy), Vector2(1740.0, sy), roof_tile.darkened(0.20), 1.8)
				b.line(Vector2(ea.y, sy), Vector2(eb.y, sb), stone.lightened(0.20), 4.5)
				if (row + 1) % 2 == 0:
					var my := (ea.y + eb.y) * 0.5
					b.rect(Rect2(my + 4.0, ym - 12.0, 14.0, 24.0), Color(0.22, 0.18, 0.15))
					b.rect(Rect2(my - 2.0, ym - 8.0, 10.0, 16.0), Color(0.76, 0.16, 0.18))
					b.line(Vector2(my + 3.0, ym - 8.0), Vector2(my + 3.0, ym + 8.0), Color(0.94, 0.78, 0.28), 2.0)
			elif ym > ANDALUS_TOP:
				# 5. Dazzling Andalusian whitewashed facades, cobalt-blue zócalos & geranium sills
				var face := 26.0
				var white_cal := Color(0.96, 0.95, 0.92)
				var cobalt := Color(0.14, 0.38, 0.78)
				var terra_roof := Color(0.68, 0.38, 0.24)
				# West side: full roof & azotea terrace fill to the edge
				b.quad(Vector2(-460.0, sy), Vector2(ea.x - face, sy), Vector2(eb.x - face, sb), Vector2(-460.0, sb), terra_roof)
				b.line(Vector2(-460.0, sy), Vector2(ea.x - face, sy), terra_roof.darkened(0.20), 1.8)
				if row % 4 == 0:
					b.line(Vector2(-460.0, sy), Vector2(ea.x - face, sy), white_cal, 4.0)
				b.quad(Vector2(ea.x - face, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(eb.x - face, sb), white_cal)
				b.quad(Vector2(ea.x - 5.0, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(eb.x - 5.0, sb), cobalt)
				b.line(Vector2(ea.x - face, sy), Vector2(eb.x - face, sb), white_cal.lightened(0.12), 2.5)
				if row % 2 == 0:
					var mx := (ea.x + eb.x) * 0.5
					b.rect(Rect2(mx - 18.0, ym - 12.0, 14.0, 24.0), cobalt)
					b.rect(Rect2(mx - 15.5, ym - 9.5, 9.0, 19.0), Color(0.16, 0.22, 0.32))
					for py_off: float in [-6.0, 0.0, 6.0]:
						var gp := Vector2(mx - 3.0, ym + py_off)
						b.circle(gp, 4.2, Color(0.74, 0.36, 0.20))
						b.circle(gp + Vector2(1.5, -1.0), 3.8, Color(0.18, 0.48, 0.22))
						b.circle(gp + Vector2(2.5, -1.5), 3.0, Color(0.90, 0.16, 0.22))
				# East side: full roof & azotea terrace fill to the edge
				b.quad(Vector2(ea.y, sy), Vector2(ea.y + face, sy), Vector2(eb.y + face, sb), Vector2(eb.y, sb), white_cal)
				b.quad(Vector2(ea.y, sy), Vector2(ea.y + 5.0, sy), Vector2(eb.y + 5.0, sb), Vector2(eb.y, sb), cobalt)
				b.quad(Vector2(ea.y + face, sy), Vector2(1740.0, sy), Vector2(1740.0, sb), Vector2(eb.y + face, sb), terra_roof)
				b.line(Vector2(ea.y + face, sy), Vector2(1740.0, sy), terra_roof.darkened(0.20), 1.8)
				if (row + 2) % 4 == 0:
					b.line(Vector2(ea.y + face, sy), Vector2(1740.0, sy), white_cal, 4.0)
				b.line(Vector2(ea.y + face, sy), Vector2(eb.y + face, sb), white_cal.lightened(0.12), 2.5)
				if (row + 1) % 2 == 0:
					var my := (ea.y + eb.y) * 0.5
					b.rect(Rect2(my + 4.0, ym - 12.0, 14.0, 24.0), cobalt)
					b.rect(Rect2(my + 6.5, ym - 9.5, 9.0, 19.0), Color(0.16, 0.22, 0.32))
					for py_off: float in [-6.0, 0.0, 6.0]:
						var gp := Vector2(my + 3.0, ym + py_off)
						b.circle(gp, 4.2, Color(0.74, 0.36, 0.20))
						b.circle(gp + Vector2(-1.5, -1.0), 3.8, Color(0.18, 0.48, 0.22))
						b.circle(gp + Vector2(-2.5, -1.5), 3.0, Color(0.90, 0.16, 0.22))
			else:
				# 6. Aragonese Mudejar palace wings: brick walls, blind arches & ceramic friezes
				var face := 24.0
				var brick := Color(0.64, 0.32, 0.20) if row % 2 == 0 else Color(0.60, 0.29, 0.18)
				# West side
				b.quad(Vector2(-460.0, sy), Vector2(ea.x - face, sy), Vector2(eb.x - face, sb), Vector2(-460.0, sb), Color(0.54, 0.28, 0.18))
				b.quad(Vector2(ea.x - face, sy), Vector2(ea.x, sy), Vector2(eb.x, sb), Vector2(eb.x - face, sb), brick)
				var mx := (ea.x + eb.x) * 0.5
				b.rect(Rect2(mx - 8.0, ym - 8.0, 6.0, 16.0), Color(0.14, 0.54, 0.38) if row % 2 == 0 else Color(0.94, 0.92, 0.86))
				b.line(Vector2(ea.x, sy), Vector2(eb.x, sb), Color(0.78, 0.42, 0.26), 3.0)
				# East side
				b.quad(Vector2(ea.y, sy), Vector2(ea.y + face, sy), Vector2(eb.y + face, sb), Vector2(eb.y, sb), brick)
				b.quad(Vector2(ea.y + face, sy), Vector2(1740.0, sy), Vector2(1740.0, sb), Vector2(eb.y + face, sb), Color(0.54, 0.28, 0.18))
				var my := (ea.y + eb.y) * 0.5
				b.rect(Rect2(my + 2.0, ym - 8.0, 6.0, 16.0), Color(0.14, 0.54, 0.38) if (row + 1) % 2 == 0 else Color(0.94, 0.92, 0.86))
				b.line(Vector2(ea.y, sy), Vector2(eb.y, sb), Color(0.78, 0.42, 0.26), 3.0)

		sy += step

	# The village beyond the house fronts: one roof per house, in each town's
	# style, over the flat fill the rows above lay down
	for section: Array in [[-640.0, CASTILIAN_TOP, 24.0, "castile"], [CASTILIAN_TOP, PLAZA_TOP, 64.0, "plaza"],
			[PLAZA_TOP, ANDALUS_TOP, 26.0, "andalus"], [ANDALUS_TOP, gate_y - 30.0, 24.0, "aragon"]]:
		var s_bot: float = section[0]
		var s_top: float = section[1]
		var lo := maxf(s_top, y_top)
		var hi := minf(s_bot, y_bot)
		if hi - lo < 8.0:
			continue
		for side: float in [-1.0, 1.0]:
			_house_lots(m, b, side, lo, hi, s_top, s_bot, float(section[2]), String(section[3]))

	# The curtain wall runs out from each tower to the frame's edge: grass in
	# front of it, the wall-walk between its two crenellated parapets, and the
	# first lane's paving behind
	if GATE_PINCH_BOT + 40.0 >= y_top and GATE_PINCH_TOP - 40.0 <= y_bot:
		var wy0 := GATE_TOWER_L.y - 34.0
		var wy1 := GATE_TOWER_L.y + 34.0
		for side: float in [-1.0, 1.0]:
			var tx: float = (GATE_TOWER_L.x - GATE_TOWER_R_PX + 8.0) if side < 0.0 else (GATE_TOWER_R.x + GATE_TOWER_R_PX - 8.0)
			var far := -460.0 if side < 0.0 else 1740.0
			var x0 := minf(far, tx)
			var w := absf(far - tx)
			# in front, the grass bank; behind, the town's first paving
			b.rect(Rect2(x0, wy1, w, GATE_PINCH_BOT - wy1 + 4.0), Color(0.32, 0.46, 0.26))
			b.rect(Rect2(x0, GATE_PINCH_TOP - 4.0, w, wy0 - GATE_PINCH_TOP + 4.0), Color(0.60, 0.54, 0.46))
			# the wall's shadow on the grass
			b.rect(Rect2(x0, wy1, w, 16.0), Color(0.05, 0.04, 0.08, 0.28))
			# the wall-walk and its stone courses
			b.rect(Rect2(x0, wy0, w, wy1 - wy0), Color(0.62, 0.55, 0.45))
			var cy := wy0 + 12.0
			while cy < wy1 - 8.0:
				b.line(Vector2(x0, cy), Vector2(x0 + w, cy), Color(0.52, 0.46, 0.38), 1.2)
				cy += 11.0
			# merlons along both parapets, the gaps between them dark
			var mx := x0
			var mi := 0
			while mx < x0 + w:
				var mw := minf(14.0, x0 + w - mx)
				if mi % 2 == 0:
					b.rect(Rect2(mx, wy0 - 4.0, mw, 10.0), Color(0.76, 0.69, 0.57))
					b.rect(Rect2(mx, wy1 - 6.0, mw, 10.0), Color(0.76, 0.69, 0.57))
					b.rect(Rect2(mx + 2.0, wy1 + 4.0, mw, 4.0), Color(0.05, 0.04, 0.08, 0.20))
				else:
					b.rect(Rect2(mx, wy0 - 2.0, mw, 6.0), Color(0.42, 0.37, 0.30))
					b.rect(Rect2(mx, wy1 - 4.0, mw, 6.0), Color(0.42, 0.37, 0.30))
				mx += 14.0
				mi += 1

	# Draw the two big round crenellated stone gate towers flanking the entrance pinch
	if GATE_TOWER_L.y + 140.0 >= y_top and GATE_TOWER_L.y - 140.0 <= y_bot:
		_draw_crenellated_gate_tower(b, GATE_TOWER_L)
		_draw_crenellated_gate_tower(b, GATE_TOWER_R)

	if not (c is ShapeBatch):
		b.flush()


# --- the houses behind the fronts ---------------------------------------------
# Each lot is LOT_H tall down the street (jittered by a hash of its index, so
# the party walls do not line up like a ruler): a front house whose roof runs
# from the facade line back FRONT_D px, and a back row behind it to the frame's
# edge. Pitched tile roofs in Castile, round the plaza and in Aragon: a lit
# slope and a shaded one either side of the ridge, tile courses, chimneys.
# Andalusia's are mostly flat white terraces (azoteas) with parapets, water
# tanks, pots and washing, and the odd tiled one. Some back lots open into a
# patio. Everything is batched into the edge layer's ShapeBatch.
const LOT_H := 128.0
const FRONT_D := 150.0
const ROOF_TILES := {
	"castile": [Color(0.62, 0.33, 0.22), Color(0.56, 0.30, 0.20), Color(0.66, 0.40, 0.26), Color(0.44, 0.42, 0.40)],
	"plaza": [Color(0.66, 0.36, 0.22), Color(0.70, 0.44, 0.28), Color(0.60, 0.32, 0.21), Color(0.72, 0.52, 0.34)],
	"andalus": [Color(0.68, 0.38, 0.24), Color(0.72, 0.42, 0.26)],
	"aragon": [Color(0.58, 0.30, 0.19), Color(0.62, 0.34, 0.21), Color(0.54, 0.28, 0.18)],
}
const AZOTEA := Color(0.95, 0.94, 0.90)
const PATIO_FLOOR := {"castile": Color(0.66, 0.60, 0.52), "plaza": Color(0.70, 0.62, 0.50),
	"andalus": Color(0.86, 0.80, 0.70), "aragon": Color(0.70, 0.52, 0.40)}


static func _lot_hash(k: int, side: float, salt: int) -> int:
	var h := (k * 73856093) ^ (int(side + 2.0) * 19349663) ^ (salt * 83492791)
	return absi(h) % 1000


static func _facade_x(m: Node2D, y: float, side: float, face: float) -> float:
	var e: Vector2 = m.walk_edges(y)
	return (e.x - face) if side < 0.0 else (e.y + face)


static func _house_lots(m: Node2D, b: ShapeBatch, side: float, lo: float, hi: float,
		s_top: float, s_bot: float, face: float, style: String) -> void:
	var far := -460.0 if side < 0.0 else 1740.0
	var k0 := int(floorf(lo / LOT_H)) - 1
	var k1 := int(floorf(hi / LOT_H)) + 1
	for k in range(k0, k1 + 1):
		var jit := float(_lot_hash(k, side, 1) % 40) - 20.0
		var y0 := maxf(float(k) * LOT_H + jit, s_top)
		var y1 := minf(float(k + 1) * LOT_H + float(_lot_hash(k + 1, side, 1) % 40) - 20.0, s_bot)
		if y1 - y0 < 24.0:
			continue
		var f0 := _facade_x(m, y0, side, face)
		var f1 := _facade_x(m, y1, side, face)
		var d := FRONT_D + float(_lot_hash(k, side, 2) % 50)
		var back0 := f0 + side * d
		var back1 := f1 + side * d
		var h := _lot_hash(k, side, 3)
		var flat := style == "andalus" and h % 3 != 0
		var tiles: Array = ROOF_TILES[style]
		var tile: Color = tiles[h % tiles.size()]
		# the back row first, a shade darker, its own ridge
		var back_tile: Color = (tiles[(h / 7) % tiles.size()] as Color).darkened(0.12)
		if style == "andalus" and h % 2 == 0:
			back_tile = AZOTEA.darkened(0.06)
		b.quad(Vector2(back0, y0), Vector2(far, y0), Vector2(far, y1), Vector2(back1, y1), back_tile)
		b.line(Vector2(back0 + side * 70.0, y0), Vector2(back1 + side * 70.0, y1), back_tile.lightened(0.10), 2.5)
		# a patio in some back lots: floor, a lemon tree, its walls' shade
		if h % 4 == 1 and y1 - y0 > 70.0:
			var pa := Rect2(minf(back0 + side * 20.0, back0 + side * 120.0), y0 + 16.0, 100.0, y1 - y0 - 32.0)
			b.rect(pa, PATIO_FLOOR[style])
			if style == "andalus":
				# a checker of glazed tiles and a little round fountain
				var ty := pa.position.y
				var row_i := 0
				while ty < pa.end.y - 1.0:
					var tx := pa.position.x + (10.0 if row_i % 2 == 1 else 0.0)
					while tx < pa.end.x - 1.0:
						b.rect(Rect2(tx, ty, minf(10.0, pa.end.x - tx), minf(10.0, pa.end.y - ty)), Color(0.20, 0.42, 0.72, 0.55))
						tx += 20.0
					ty += 10.0
					row_i += 1
				b.circle(pa.get_center(), 9.0, Color(0.92, 0.90, 0.86))
				b.circle(pa.get_center(), 6.0, Color(0.36, 0.62, 0.80))
			var tc := pa.get_center() + Vector2(side * 22.0, -10.0)
			b.circle(tc + LIGHT * 6.0, 15.0, SHADOW)
			b.circle(tc, 14.0, Color(0.20, 0.40, 0.22))
			b.circle(tc - LIGHT * 4.0, 8.0, Color(0.30, 0.50, 0.28))
			if style != "aragon":
				b.circle(tc + Vector2(4.0, 2.0), 2.2, Color(0.96, 0.82, 0.22))
			b.rect(Rect2(pa.position.x, pa.position.y, pa.size.x, 6.0), Color(0.0, 0.0, 0.0, 0.18))
		if flat:
			# the front house's flat white terrace and its parapet
			b.quad(Vector2(f0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(f1, y1), AZOTEA)
			b.line(Vector2(f0, y0 + 3.0), Vector2(back0, y0 + 3.0), AZOTEA.darkened(0.14), 3.0)
			b.line(Vector2(f1, y1 - 3.0), Vector2(back1, y1 - 3.0), AZOTEA.darkened(0.14), 3.0)
			b.line(Vector2(back0 - side * 3.0, y0), Vector2(back1 - side * 3.0, y1), AZOTEA.darkened(0.14), 3.0)
			b.line(Vector2(f0 + side * 3.0, y0), Vector2(f1 + side * 3.0, y1), AZOTEA.darkened(0.08), 2.0)
			var mid := Vector2((f0 + back0 + f1 + back1) * 0.25, (y0 + y1) * 0.5)
			if h % 5 < 3:
				# the water tank
				var tp := mid + Vector2(-side * 30.0, -14.0)
				b.circle(tp + LIGHT * 5.0, 10.0, SHADOW)
				b.circle(tp, 9.0, Color(0.62, 0.64, 0.66))
				b.circle(tp - LIGHT * 2.0, 5.0, Color(0.74, 0.76, 0.78))
			if h % 2 == 0:
				# washing on a line across the terrace
				var wy := mid.y + 12.0
				var wa := Vector2(f0 + side * 18.0, wy)
				var wb := Vector2(back0 - side * 18.0, wy)
				b.line(wa, wb, Color(0.30, 0.30, 0.32), 1.0)
				var cols := [Color(0.92, 0.36, 0.30), Color(0.30, 0.52, 0.86), Color(0.98, 0.96, 0.90), Color(0.96, 0.78, 0.24)]
				for wi in range(4):
					var wp := wa.lerp(wb, 0.15 + 0.22 * float(wi))
					b.rect(Rect2(wp.x - 5.0, wy, 10.0, 8.0 + float(wi % 2) * 3.0), cols[(wi + h) % 4])
			# pots along the street-side parapet
			for pi in range(3):
				var pp := Vector2(f0, y0).lerp(Vector2(f1, y1), 0.2 + 0.3 * float(pi)) + Vector2(side * 8.0, 0.0)
				b.circle(pp, 3.6, Color(0.72, 0.36, 0.20))
				b.circle(pp + Vector2(0.0, -1.5), 3.0, Color(0.92, 0.18, 0.24) if (pi + h) % 2 == 0 else Color(0.20, 0.50, 0.24))
		else:
			# a pitched roof: the slope toward the street, the ridge, the slope behind
			var r0 := f0 + side * d * 0.5
			var r1 := f1 + side * d * 0.5
			var lit := tile.lightened(0.10) if side > 0.0 else tile.darkened(0.06)
			var shade := tile.darkened(0.14) if side > 0.0 else tile.lightened(0.04)
			b.quad(Vector2(f0, y0), Vector2(r0, y0), Vector2(r1, y1), Vector2(f1, y1), lit)
			b.quad(Vector2(r0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(r1, y1), shade)
			# tile courses, parallel to the ridge
			var dd := 10.0
			while dd < d - 4.0:
				if absf(dd - d * 0.5) > 4.0:
					var cc := (lit if dd < d * 0.5 else shade).darkened(0.10)
					b.line(Vector2(f0 + side * dd, y0 + 2.0), Vector2(f1 + side * dd, y1 - 2.0), cc, 1.2)
				dd += 11.0
			b.line(Vector2(r0, y0), Vector2(r1, y1), tile.lightened(0.22), 3.0)
			# the eaves along the street
			b.line(Vector2(f0, y0), Vector2(f1, y1), tile.darkened(0.28), 2.5)
			if h % 3 == 0:
				# a chimney with its pot, and its shadow on the tiles
				var cp := Vector2((r0 + back0) * 0.5, (y0 + y1) * 0.5 - 12.0)
				b.rect(Rect2(cp + LIGHT * 7.0 - Vector2(7, 7), Vector2(14, 14)), SHADOW)
				b.rect(Rect2(cp - Vector2(7, 7), Vector2(14, 14)), Color(0.80, 0.74, 0.64) if style != "aragon" else Color(0.66, 0.36, 0.24))
				b.rect(Rect2(cp - Vector2(4, 4), Vector2(8, 8)), Color(0.26, 0.22, 0.20))
		# the party wall between this house and the next one down the street
		b.line(Vector2(f0, y0), Vector2(far, y0), Color(0.18, 0.13, 0.10, 0.55), 2.5)
		b.line(Vector2(f0, y0 + 2.5), Vector2(far, y0 + 2.5), Color(1.0, 0.95, 0.85, 0.12), 1.0)


static func _draw_crenellated_gate_tower(b: ShapeBatch, center: Vector2) -> void:
	var rad := GATE_TOWER_R_PX
	# Deep shadow cast by the tall round stone tower
	b.circle(center + LIGHT * 18.0, rad + 4.0, Color(0.04, 0.03, 0.07, 0.34))
	# Sloped stone talus base (escarpa)
	b.circle(center, rad + 6.0, Color(0.46, 0.40, 0.33))
	b.circle(center, rad, Color(0.64, 0.56, 0.45))
	b.circle(center - LIGHT * 3.0, rad - 8.0, Color(0.72, 0.64, 0.52))
	b.circle(center, rad - 18.0, Color(0.54, 0.47, 0.38))
	# Radial stone machicolation corbels and 12 crenellated battlements (merlons)
	for i: int in range(12):
		var a := float(i) * TAU / 12.0
		var dir := Vector2(cos(a), sin(a))
		var p_in := center + dir * (rad - 14.0)
		var p_out := center + dir * (rad + 2.0)
		b.line(p_in, p_out, Color(0.78, 0.70, 0.58), 9.5)
		b.line(p_in, p_out, Color(0.36, 0.30, 0.24), 2.0)
	# Central watchtower flagstone platform & medieval banner pole
	b.circle(center, 18.0, Color(0.48, 0.42, 0.35))
	b.circle(center, 5.0, Color(0.24, 0.20, 0.16))



# --- custom furniture hooks (cached in main's furniture pass) ----------------

static func draw_column(_m: Node2D, wc: Object, p: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(p + LIGHT * 9.0, 14.0, SHADOW)
	if p.distance_to(TOWER_COLUMN) <= 18.0:
		# Aragonese stone wayside cross (creu de terme) on octagonal stepped base
		b.circle(p, 15.0, Color(0.54, 0.48, 0.40))
		b.circle(p, 11.0, Color(0.68, 0.60, 0.50))
		b.circle(p, 6.5, Color(0.78, 0.70, 0.58))
		b.line(p + Vector2(-7.0, 0.0), p + Vector2(7.0, 0.0), Color(0.86, 0.78, 0.66), 3.5)
		b.line(p + Vector2(0.0, -7.0), p + Vector2(0.0, 7.0), Color(0.86, 0.78, 0.66), 3.5)
	elif p.y > -700.0:
		# Heavy medieval stone gate pier with iron torch ring
		b.circle(p, 14.0, Color(0.48, 0.42, 0.35))
		b.circle(p - LIGHT * 1.5, 11.0, Color(0.64, 0.56, 0.46))
		b.circle(p - LIGHT * 2.5, 6.5, Color(0.74, 0.66, 0.54))
	else:
		# Plaza Mayor carved Renaissance stone arcade column on square plinth
		b.rect(Rect2(p.x - 13.0, p.y - 13.0, 26.0, 26.0), Color(0.58, 0.50, 0.40))
		b.circle(p, 12.0, Color(0.70, 0.60, 0.48))
		b.circle(p - LIGHT * 1.8, 9.2, Color(0.82, 0.72, 0.58))
		b.circle(p - LIGHT * 3.0, 5.0, Color(0.90, 0.82, 0.68))
	b.flush(wc)


static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var b := ShapeBatch.new()
	var t: float = AnimClock.msec() / 1000.0
	# Cast shadow of the grand octagonal Plaza Mayor stone fountain
	b.circle(f + LIGHT * 12.0, FOUNTAIN_R + 8.0, SHADOW)
	# Octagonal granite steps and moulded stone basin rim
	var oct_outer := PackedVector2Array()
	var oct_water := PackedVector2Array()
	for i: int in range(8):
		var a := float(i) * TAU / 8.0 + PI / 8.0
		var dir := Vector2(cos(a), sin(a))
		oct_outer.append(f + dir * (FOUNTAIN_R + 6.0))
		oct_water.append(f + dir * (FOUNTAIN_R - 4.0))
	b.polygon(oct_outer, Color(0.64, 0.56, 0.46))
	b.circle(f, FOUNTAIN_R, Color(0.76, 0.68, 0.56))
	# Shimmering turquoise basin water
	b.polygon(oct_water, Color(0.20, 0.54, 0.66))
	b.circle(f - LIGHT * 4.0, FOUNTAIN_R - 10.0, Color(0.28, 0.66, 0.78, 0.65))
	# Four brass lion-head water jets spouting into the basin
	for i: int in range(4):
		var a := float(i) * PI * 0.5 + PI * 0.25
		var dir := Vector2(cos(a), sin(a))
		var jet_end := f + dir * (FOUNTAIN_R - 12.0)
		b.line(f + dir * 12.0, jet_end, Color(0.84, 0.96, 1.0, 0.80), 2.4)
		var rph := fmod(t * 2.2 + float(i) * 0.25, 1.0)
		b.circle(jet_end, 3.0 + rph * 7.0, Color(0.90, 0.98, 1.0, 0.45 * (1.0 - rph)))
	# Central tiered stone pedestal & carved finial urn
	b.circle(f + LIGHT * 4.0, 15.0, SHADOW)
	b.circle(f, 15.0, Color(0.62, 0.54, 0.44))
	b.circle(f - LIGHT * 1.5, 10.5, Color(0.78, 0.70, 0.58))
	b.circle(f - LIGHT * 2.5, 5.5, Color(0.90, 0.82, 0.70))
	b.flush(m._wc)


static func draw_bollard(_m: Node2D, wc: Object, h: Dictionary) -> void:
	var hp: Vector2 = h.pos
	var done := bool(h.get("done", false))
	var prog := float(h.get("progress", 0.0))
	var b := ShapeBatch.new()
	b.circle(hp + LIGHT * 8.0, 9.5, SHADOW)
	# Carved granite village wheel-guard stone (guardacanton) with wrought-iron ring
	var stone := Color(0.52, 0.46, 0.38) if done else Color(0.64, 0.56, 0.46)
	b.circle(hp, 10.5, stone.darkened(0.22))
	b.circle(hp - LIGHT * 1.2, 8.2, stone)
	b.circle(hp - LIGHT * 2.4, 4.2, stone.lightened(0.18))
	b.circle(hp, 2.2, Color(0.22, 0.20, 0.18))
	if not done and prog > 0.0:
		var steps := maxi(2, int(ceil(12.0 * (prog / 0.8))))
		var prev := hp + Vector2(0.0, -15.5)
		for i: int in range(1, steps + 1):
			var ang := -PI * 0.5 + TAU * (prog / 0.8) * float(i) / float(steps)
			var cur := hp + Vector2(cos(ang), sin(ang)) * 15.5
			b.line(prev, cur, Color(1.0, 0.94, 0.68), 3.0)
			prev = cur
	b.flush(wc)


static func draw_bin(_m: Node2D, wc: Object, bn: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(bn + LIGHT * 7.0, 12.0, SHADOW)
	# Wrought-iron and chestnut-slat village waste basket
	b.circle(bn, 12.0, Color(0.18, 0.18, 0.20))
	b.circle(bn, 10.2, Color(0.48, 0.31, 0.18))
	b.circle(bn, 7.0, Color(0.14, 0.14, 0.16))
	b.flush(wc)


static func draw_snack(_m: Node2D, wc: Object, kp: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(kp + LIGHT * 3.0, 9.5, SHADOW)
	# Wax paper square with a golden crimped Spanish empanadilla & sugar-dusted rosquilla
	b.rect(Rect2(kp.x - 9.0, kp.y - 8.0, 18.0, 16.0), Color(0.95, 0.92, 0.84))
	b.circle(kp + Vector2(-2.0, 1.0), 6.0, Color(0.84, 0.58, 0.22))
	b.circle(kp + Vector2(4.0, -2.0), 4.0, Color(0.76, 0.48, 0.18))
	b.circle(kp + Vector2(4.0, -2.0), 1.6, Color(0.95, 0.92, 0.84))
	b.flush(wc)


# --- live pass: cafe patrons, tour guide with umbrella, prize & balcony pour -

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var t: float = AnimClock.msec() / 1000.0

	# 1. Seated cafe customers & tapas plates at the Plaza Mayor arcade tables
	for i: int in range(CAFE_TABLES.size()):
		var tp: Vector2 = CAFE_TABLES[i]
		if tp.y + 45.0 < vt or tp.y - 45.0 > vb:
			continue
		# Ceramic tapas dishes and espresso cups on the marble tabletop
		b.circle(tp + Vector2(-4.0, -3.0), 3.6, Color(0.96, 0.94, 0.90))
		b.circle(tp + Vector2(-4.0, -3.0), 2.0, Color(0.82, 0.32, 0.20))
		b.circle(tp + Vector2(4.5, 3.0), 2.8, Color(0.98, 0.96, 0.92))
		# Seated cafe patron on one of the chairs beside the table
		var c_side: float = 1.0 if tp.x < 640.0 else -1.0
		var seat_p: Vector2 = tp + Vector2(c_side * 22.0, -14.0 if i % 2 == 0 else 14.0)
		var shirt_col := Color(0.24, 0.52, 0.76) if i % 3 == 0 else (Color(0.82, 0.36, 0.28) if i % 3 == 1 else Color(0.32, 0.62, 0.44))
		b.circle(seat_p, 8.5, shirt_col)
		b.circle(seat_p + Vector2(-c_side * 2.0, 0.0), 5.5, Color(0.88, 0.70, 0.56))
		b.circle(seat_p + Vector2(-c_side * 2.5, -0.5), 4.2, Color(0.22, 0.16, 0.12) if i % 2 == 0 else Color(0.68, 0.48, 0.26))

	# 2. Tour guide with raised folded umbrella leading tourists in Plaza Mayor
	if GUIDE_POS.y + 80.0 >= vt and GUIDE_POS.y - 80.0 <= vb:
		var sway := sin(t * 2.4) * 2.0
		# Guide's shoulders, head, and outstretched arm holding the raised yellow-and-red umbrella
		b.circle(GUIDE_POS + LIGHT * 6.0, 10.0, SHADOW)
		b.circle(GUIDE_POS, 9.5, Color(0.20, 0.42, 0.68))
		b.circle(GUIDE_POS, 6.2, Color(0.90, 0.72, 0.58))
		b.circle(GUIDE_POS, 4.6, Color(0.26, 0.18, 0.14))
		var umb_base := GUIDE_POS + Vector2(10.0, -6.0)
		var umb_tip := umb_base + Vector2(4.0 + sway, -22.0)
		b.line(GUIDE_POS + Vector2(5.0, -2.0), umb_base, Color(0.90, 0.72, 0.58), 3.0)
		b.line(umb_base, umb_tip, Color(0.98, 0.84, 0.18), 5.0)
		b.line(umb_base.lerp(umb_tip, 0.45), umb_tip, Color(0.88, 0.20, 0.22), 4.0)
		b.circle(umb_tip, 3.0, Color(0.98, 0.94, 0.82))
		# Small group of tourists facing the guide with cameras and paper village maps
		for ti: int in range(TOURIST_SPOTS.size()):
			var tsp: Vector2 = TOURIST_SPOTS[ti]
			b.circle(tsp + LIGHT * 5.0, 9.5, SHADOW)
			var t_col := Color(0.86, 0.62, 0.24) if ti == 0 else (Color(0.36, 0.66, 0.54) if ti == 1 else Color(0.74, 0.34, 0.52))
			b.circle(tsp, 9.0, t_col)
			b.circle(tsp, 6.0, Color(0.92, 0.76, 0.62))
			# Straw sunhat or camera
			b.circle(tsp, 4.8, Color(0.88, 0.80, 0.56) if ti != 1 else Color(0.32, 0.22, 0.16))
			if ti == 0:
				# Unfolded paper village map held in front
				b.rect(Rect2(tsp.x + 4.0, tsp.y - 10.0, 9.0, 7.0), Color(0.96, 0.94, 0.88))

	# 3. Artisan blown-glass porron prize on the display table near the Aragonese tower
	var taken: bool = bool(m.prize_taken) if "prize_taken" in m else false
	if not taken and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		b.glow(PRIZE, 24.0, Color(1.0, 0.88, 0.42, 0.28))
		b.circle(PRIZE + Vector2(1.0, 1.5), 6.5, SHADOW)
		b.circle(PRIZE, 6.2, Color(0.20, 0.68, 0.52))
		b.circle(PRIZE, 4.0, Color(0.68, 0.16, 0.24))
		b.line(PRIZE, PRIZE + Vector2(8.0, -6.0), Color(0.62, 0.92, 0.82), 2.4)

	# 4. Andalusian balcony watering-can live event & wet meter over human's head
	if m.poble_balcony != null:
		m.poble_balcony.draw(m, b, vt, vb)
	if "human_soak" in m and float(m.human_soak) > 0.08 and m.human != null:
		var hp: Vector2 = m.human.global_position + Vector2(-16.0, -40.0)
		b.rect(Rect2(hp.x, hp.y, 32.0, 5.0), Color(0.08, 0.08, 0.10, 0.72))
		b.rect(Rect2(hp.x, hp.y, 32.0 * float(m.human_soak), 5.0), Color(0.45, 0.68, 0.96) if float(m.human_soak) < 0.5 else Color(0.28, 0.46, 0.88))


# --- overhead layer: medieval gate bridge arch & Plaza Mayor bunting ---------

static func draw_overhead(m: Node2D, wc: Object) -> void:
	var vt: float = m.view_lo(320.0) if m.has_method("view_lo") else -6000.0
	var vb: float = m.view_hi(320.0) if m.has_method("view_hi") else 800.0
	var b := ShapeBatch.new()

	# 1. Crenellated stone gate arch spanning between the two round entrance towers
	if GATE_ARCH_RECT.end.y + 40.0 >= vt and GATE_ARCH_RECT.position.y - 40.0 <= vb:
		var ar := GATE_ARCH_RECT
		b.rect(Rect2(ar.position.x + 48.0, ar.position.y + 12.0, ar.size.x - 96.0, ar.size.y), Color(0.04, 0.03, 0.07, 0.28))
		b.rect(Rect2(ar.position.x + 44.0, ar.position.y, ar.size.x - 88.0, ar.size.y), Color(0.62, 0.54, 0.44))
		b.rect(Rect2(ar.position.x + 44.0, ar.position.y + 8.0, ar.size.x - 88.0, ar.size.y - 16.0), Color(0.70, 0.62, 0.50))
		# Stone merlons along both parapets of the gate bridge
		var mx := ar.position.x + 56.0
		while mx < ar.end.x - 68.0:
			b.rect(Rect2(mx, ar.position.y - 4.0, 18.0, 10.0), Color(0.78, 0.70, 0.58))
			b.rect(Rect2(mx, ar.end.y - 6.0, 18.0, 10.0), Color(0.74, 0.66, 0.54))
			mx += 28.0

	# 2. Strings of festival bunting (banderoles) crisscrossing overhead in Plaza Mayor
	var pennant_cols: Array[Color] = [
		Color(0.86, 0.20, 0.22),
		Color(0.96, 0.78, 0.20),
		Color(0.20, 0.52, 0.84),
		Color(0.96, 0.94, 0.88),
		Color(0.22, 0.66, 0.42),
	]
	for by: float in [-1920.0, -2120.0, -2320.0, -2520.0, -2720.0, -2900.0]:
		if by + 60.0 < vt or by - 60.0 > vb:
			continue
		var x0 := 285.0
		var x1 := 995.0
		var segs := 18
		var prev := Vector2(x0, by)
		for s: int in range(1, segs + 1):
			var u := float(s) / float(segs)
			var sag := sin(u * PI) * 26.0
			var cur := Vector2(lerpf(x0, x1, u), by + sag)
			b.line(prev, cur, Color(0.24, 0.20, 0.18, 0.75), 1.6)
			var mid := (prev + cur) * 0.5
			var pcol: Color = pennant_cols[(s + int(absf(by))) % pennant_cols.size()]
			b.polygon(PackedVector2Array([
				mid + Vector2(-6.0, 0.0),
				mid + Vector2(6.0, 0.0),
				mid + Vector2(0.0, 13.0),
			]), pcol)
			prev = cur

	b.flush(wc)


# --- off-leash area: JARDI DELS OLIVERS (terraced garden on the old walls) ---

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect() if m.has_method("_freedom_rect") else Rect2(70.0, -5620.0, 1110.0, 590.0)
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -5000.0
	var b := ShapeBatch.new()

	# 1. Daytime panoramic view of Barcelona and the Mediterranean Sea beyond the parapet
	var vista_top := gate_y - 2400.0
	var para_y := r.position.y + 18.0
	b.rect(Rect2(-420.0, vista_top, 2140.0, para_y - vista_top), Color(0.58, 0.78, 0.94))
	b.band(PackedVector2Array([
		Vector2(-420.0, vista_top), Vector2(1720.0, vista_top),
		Vector2(-420.0, para_y - 350.0), Vector2(1720.0, para_y - 350.0),
	]), 2, Color(0.84, 0.90, 0.95), PackedFloat32Array([0.0, 1.0]))
	# Sunlit Mediterranean sea band on the far horizon
	b.rect(Rect2(-420.0, para_y - 360.0, 2140.0, 110.0), Color(0.22, 0.54, 0.78))
	b.band(PackedVector2Array([
		Vector2(-420.0, para_y - 360.0), Vector2(1720.0, para_y - 360.0),
		Vector2(-420.0, para_y - 250.0), Vector2(1720.0, para_y - 250.0),
	]), 2, Color(0.38, 0.70, 0.88, 0.75), PackedFloat32Array([0.0, 1.0]))
	# Distant Eixample terracotta city grid & Sagrada Familia / Montjuic silhouette
	b.rect(Rect2(-420.0, para_y - 250.0, 2140.0, 150.0), Color(0.76, 0.62, 0.52))
	for blk_i: int in range(18):
		var bx := -320.0 + float(blk_i) * 110.0
		var bh := 38.0 + float(blk_i % 3) * 18.0
		b.rect(Rect2(bx, para_y - 230.0, 82.0, bh), Color(0.68, 0.44, 0.34) if blk_i % 2 == 0 else Color(0.78, 0.66, 0.54))
	# Wooded green slopes of Montjuic directly below the bastion wall
	b.rect(Rect2(-420.0, para_y - 110.0, 2140.0, 115.0), Color(0.28, 0.44, 0.26))
	b.band(PackedVector2Array([
		Vector2(-420.0, para_y - 110.0), Vector2(1720.0, para_y - 110.0),
		Vector2(-420.0, para_y + 5.0), Vector2(1720.0, para_y + 5.0),
	]), 2, Color(0.20, 0.34, 0.18, 0.85), PackedFloat32Array([0.0, 1.0]))

	# 2. Terraced garden on the old bastion walls (dry-stone walls, thyme & olive groves)
	var grass_med := Color(0.38, 0.50, 0.28)
	var grass_dry := Color(0.46, 0.56, 0.32)
	b.rect(r, grass_med)
	for side_terrace: Rect2 in [
		Rect2(r.position.x + 12.0, r.position.y + 28.0, 260.0, r.size.y - 44.0),
		Rect2(940.0, r.position.y + 28.0, r.end.x - 952.0, r.size.y - 44.0),
	]:
		b.rect(side_terrace, grass_dry)
		# Dry-stone terrace retaining walls (murs de pedra seca) stepping down the slope
		for ty_off: float in [140.0, 290.0, 430.0]:
			var wy := r.position.y + ty_off
			b.rect(Rect2(side_terrace.position.x, wy, side_terrace.size.x, 9.0), Color(0.58, 0.52, 0.42))
			b.line(Vector2(side_terrace.position.x, wy + 9.0), Vector2(side_terrace.end.x, wy + 9.0), SHADOW, 3.0)

	# 3. Central stone bastion promenade & mirador terrace (x = 340..940, Surfaces.S.PAVEMENT)
	var walk_r := Rect2(340.0, r.position.y + 22.0, 600.0, r.size.y - 22.0)
	b.rect(walk_r, Color(0.74, 0.66, 0.54))
	b.rect(Rect2(334.0, walk_r.position.y, 8.0, walk_r.size.y), Color(0.56, 0.48, 0.38))
	b.rect(Rect2(938.0, walk_r.position.y, 8.0, walk_r.size.y), Color(0.56, 0.48, 0.38))
	var sy := walk_r.position.y + 36.0
	while sy < walk_r.end.y - 16.0:
		b.line(Vector2(346.0, sy), Vector2(934.0, sy), Color(0.56, 0.48, 0.38, 0.38), 1.6)
		sy += 44.0

	# Dark slate mosaic apron under the entrance threshold so the white azulejo letters
	# "OFF LEASH" and "JARDÍ DELS OLIVERS" have crisp, high-contrast readability
	b.rect(Rect2(372.0, -5160.0, 536.0, 122.0), Color(0.64, 0.34, 0.22)) # terracotta tile border
	b.rect(Rect2(378.0, -5154.0, 524.0, 110.0), Color(0.24, 0.23, 0.25)) # dark charcoal slate slab
	b.line(Vector2(378.0, -5154.0), Vector2(902.0, -5154.0), Color(0.38, 0.36, 0.38), 2.0)
	b.line(Vector2(378.0, -5044.0), Vector2(902.0, -5044.0), Color(0.16, 0.15, 0.17), 2.5)

	# 4. Gnarled Mediterranean olive trees on the bastion terraces
	for olive_p: Vector2 in [
		Vector2(210.0, r.position.y + 110.0),
		Vector2(230.0, r.position.y + 260.0),
		Vector2(195.0, r.position.y + 410.0),
		Vector2(1045.0, r.position.y + 115.0),
		Vector2(1025.0, r.position.y + 265.0),
		Vector2(1060.0, r.position.y + 415.0),
	]:
		b.circle(olive_p + LIGHT * 12.0, 32.0, SHADOW)
		b.circle(olive_p, 8.0, Color(0.38, 0.28, 0.20))
		for lobe: Vector2 in [
			Vector2(-14.0, -8.0), Vector2(14.0, -7.0),
			Vector2(-12.0, 10.0), Vector2(12.0, 9.0), Vector2(0.0, -14.0),
		]:
			b.circle(olive_p + lobe, 18.0, Color(0.42, 0.54, 0.38))
			b.circle(olive_p + lobe - LIGHT * 3.0, 11.0, Color(0.56, 0.68, 0.50))

	# 5. Low crenellated stone parapet along the old bastion walls
	var wall_col := Color(0.62, 0.54, 0.44)
	b.rect(Rect2(r.position.x - 18.0, r.position.y, r.size.x + 36.0, 22.0), wall_col)
	var mx := r.position.x - 10.0
	while mx < r.end.x + 10.0:
		b.rect(Rect2(mx, r.position.y - 6.0, 24.0, 12.0), wall_col.lightened(0.12))
		mx += 40.0
	b.rect(Rect2(r.position.x - 18.0, r.position.y, 18.0, r.size.y), wall_col)
	b.rect(Rect2(r.end.x, r.position.y, 18.0, r.size.y), wall_col)
	var gl: float = float(m.gate_l) if "gate_l" in m else 420.0
	var gr: float = float(m.gate_r) if "gate_r" in m else 860.0
	b.rect(Rect2(r.position.x - 18.0, r.end.y - 10.0, gl - r.position.x + 2.0, 14.0), wall_col)
	b.rect(Rect2(gr + 16.0, r.end.y - 10.0, r.end.x - gr + 2.0, 14.0), wall_col)

	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, Color(0.48, 0.32, 0.20))
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, "the olive terrace on the old walls, off leash")
