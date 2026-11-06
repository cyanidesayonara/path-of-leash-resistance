class_name Espanya
extends RefCounted

# WALK 31: PLAÇA D'ESPANYA (Avinguda Maria Cristina & La Font Màgica)
#
# The grand ceremonial avenue ascending from the twin Venetian Towers of Plaça d'Espanya,
# along Avinguda de la Reina Maria Cristina past exhibition palaces and monumental columns,
# to the colossal Magic Fountain (La Font Màgica) with choreographed dancing water jets,
# and up the grand cascading stairs towards the Palau Nacional.
#
# Distinctive features:
# - Torres Venecianes: twin imposing Venetian brick towers flanking the avenue entrance.
# - Les Quatre Columnes de Puig i Cadafalch: four monumental ionic columns forming
#   a classic gateway and tight leash wrapping challenge.
# - La Font Màgica de Montjuïc: colossal circular fountain basin with dancing
#   multitudes of water jets and illuminated sprays (Surfaces.S.WATER).
# - Palau Cascades & Outdoor Escalators: running water cascade basins flanked by
#   escalator conveyors carrying the pair up the hillside terrace.
# - Signature live event: El Bufador de Bombolles (EspanyaBubble) releasing giant
#   shimmering soap bubbles across the avenue.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EspanyaBubble := preload("res://systems/espanya_bubble.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)

# --- colors ------------------------------------------------------------------
const PAVING_STONE := Color(0.72, 0.70, 0.66)
const PAVING_JOINT := Color(0.56, 0.54, 0.50)
const PALACE_MARBLE := Color(0.86, 0.84, 0.78)
const PALACE_STONE_DARK := Color(0.60, 0.58, 0.54)
const BALUSTRADE_STONE := Color(0.76, 0.74, 0.70)

# Venetian brick tower colors
const TOWER_BRICK := Color(0.68, 0.32, 0.22)
const TOWER_STONE := Color(0.82, 0.78, 0.72)
const TOWER_ROOF := Color(0.35, 0.42, 0.36)

# Fountain & water colors
const WATER_DEEP := Color(0.14, 0.42, 0.65)
const WATER_SHALLOW := Color(0.24, 0.58, 0.78)
const WATER_SPRAY := Color(0.92, 0.96, 1.0, 0.75)
const FOUNTAIN_RIM := Color(0.82, 0.80, 0.76)

# Senyera & banner colors
const FLAG_GOLD := Color(0.94, 0.78, 0.18)
const FLAG_RED := Color(0.85, 0.18, 0.14)

# Escalator colors
const ESCALATOR_FRAME := Color(0.32, 0.34, 0.38)
const ESCALATOR_TREAD := Color(0.48, 0.50, 0.54)
const ESCALATOR_BELT := Color(0.18, 0.18, 0.20)

# --- layout constants --------------------------------------------------------
const HALF := 260.0
const WALL_L := 380.0
const WALL_R := 900.0

# Venetian towers at the lower gateway
const TOWER_WEST := Rect2(390.0, -480.0, 52.0, 72.0)
const TOWER_EAST := Rect2(838.0, -480.0, 52.0, 72.0)

# Les Quatre Columnes de Puig i Cadafalch (y = -2250.0)
const COLUMNS_Y := -2250.0
const COLUMN_POSTS: Array[Vector2] = [
	Vector2(520.0, COLUMNS_Y),
	Vector2(600.0, COLUMNS_Y),
	Vector2(680.0, COLUMNS_Y),
	Vector2(760.0, COLUMNS_Y),
]

# Magic Fountain layout (y = -3200.0)
const FOUNTAIN_CENTER := Vector2(640.0, -3200.0)
const FOUNTAIN_RADIUS := 105.0
const FOUNTAIN_TERRACE_RADIUS := 160.0
const FOUNTAIN_PEDESTAL := Rect2(616.0, -3224.0, 48.0, 48.0)

# Grand cascade pools & flanking escalators
const CASCADE_TOP := -4400.0
const CASCADE_BOT := -3900.0
const ESCALATOR_L := Rect2(410.0, -4250.0, 44.0, 220.0)
const ESCALATOR_R := Rect2(826.0, -4250.0, 44.0, 220.0)

# Unique walk prize
const PRIZE := Vector2(640.0, -4400.0)
const PRIZE_TEXT := "snatch the crystal fountain finial from the palace cascade balustrade"

# Monumental flagpoles along the avenue
const FLAGPOLES: Array[Vector2] = [
	Vector2(430.0, -850.0),
	Vector2(850.0, -850.0),
	Vector2(430.0, -1700.0),
	Vector2(850.0, -1700.0),
	Vector2(430.0, -2650.0),
	Vector2(850.0, -2650.0),
]


static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA D'ESPANYA"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 400.0
	m.gate_r = 880.0

	# Reset tracking state
	m.espanya_bubbles_popped = 0
	m.espanya_fountain_splashed = 0
	m.espanya_columns_wrapped = 0
	m.espanya_escalator_ridden = 0
	m.espanya_bubble = EspanyaBubble.new()

	# Leash wrapping poles: flagpoles and monumental columns
	for p: Vector2 in FLAGPOLES:
		m.poles.append(p)
	for col_p: Vector2 in COLUMN_POSTS:
		m.poles.append(col_p)
	m.deco_pole_count = m.poles.size()

	# Fountain pedestal corners wrap points
	m.poles.append(Vector2(FOUNTAIN_PEDESTAL.position.x + 8.0, FOUNTAIN_PEDESTAL.get_center().y))
	m.poles.append(Vector2(FOUNTAIN_PEDESTAL.end.x - 8.0, FOUNTAIN_PEDESTAL.get_center().y))

	m.benches = Array([
		Vector2(430.0, -1100.0),
		Vector2(850.0, -1100.0),
		Vector2(430.0, -2000.0),
		Vector2(850.0, -2000.0),
		Vector2(470.0, -3500.0),
		Vector2(810.0, -3500.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(420.0, -700.0),
		Vector2(860.0, -700.0),
		Vector2(420.0, -1800.0),
		Vector2(860.0, -2500.0),
		Vector2(420.0, -3700.0),
		Vector2(860.0, -3700.0),
	], TYPE_VECTOR2, &"", null)

	var hyd_list: Array[Vector2] = [
		Vector2(430.0, -1350.0),
		Vector2(850.0, -1350.0),
		Vector2(430.0, -2800.0),
		Vector2(850.0, -2800.0),
	]
	var keb_list: Array[Vector2] = [
		Vector2(640.0, -1550.0),
		Vector2(530.0, -2950.0),
		Vector2(750.0, -3650.0),
	]
	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	# Venetian towers
	out.append(TOWER_WEST)
	out.append(TOWER_EAST)
	# Central fountain pedestal
	out.append(FOUNTAIN_PEDESTAL)
	return out


static func surface(_m: Node2D, p: Vector2) -> int:
	# Inside circular Magic Fountain basin
	if p.distance_to(FOUNTAIN_CENTER) <= FOUNTAIN_RADIUS:
		return Surfaces.S.WATER

	# Inside central cascade water pools
	if p.y >= CASCADE_TOP and p.y <= CASCADE_BOT:
		if p.x >= 580.0 and p.x <= 700.0:
			return Surfaces.S.WATER
		# Flanking escalators and grand stone stairs
		return Surfaces.S.TILE

	# Fountain terrace stone surround
	if p.distance_to(FOUNTAIN_CENTER) <= FOUNTAIN_TERRACE_RADIUS:
		return Surfaces.S.TILE

	# Column plaza
	if absf(p.y - COLUMNS_Y) < 60.0 and p.x >= 480.0 and p.x <= 800.0:
		return Surfaces.S.TILE

	return Surfaces.S.PAVEMENT


static func tick(m: Node2D, delta: float) -> void:
	# 1. Escalator propulsion impulse (conveyor moving upwards)
	for esc: Rect2 in [ESCALATOR_L, ESCALATOR_R]:
		if esc.has_point(m.dog.global_position):
			m.dog.global_position.y -= 140.0 * delta
			if m.espanya_escalator_ridden == 0:
				m.espanya_escalator_ridden = 1
				m.award_points(2, "escalator glide! +2")
		if esc.has_point(m.human.global_position):
			m.human.global_position.y -= 100.0 * delta

	# 2. Splash in Magic Fountain
	if m.dog.global_position.distance_to(FOUNTAIN_CENTER) <= FOUNTAIN_RADIUS:
		if m.espanya_fountain_splashed == 0:
			m.espanya_fountain_splashed = 1
			m.award_points(2, "magic fountain splash! +2")

	# 3. Columns wrapping check
	if m.espanya_columns_wrapped == 0 and m.leash != null:
		for col_p: Vector2 in COLUMN_POSTS:
			if m.leash.has_contact_with(col_p):
				m.espanya_columns_wrapped = 1
				m.award_points(2, "columns wrap! +2")
				break

	# 4. Bubble performer live event tick
	if m.espanya_bubble != null:
		var d_pos: Vector2 = m.dog.global_position
		var d_vel: Vector2 = m.dog.velocity if "velocity" in m.dog else Vector2.ZERO
		var h_pos: Vector2 = m.human.global_position
		var ev: Dictionary = m.espanya_bubble.tick(delta, d_pos, d_vel, h_pos)

		if ev.get("telegraph", false):
			m.float_text(m.espanya_bubble.pos + Vector2(0.0, -42.0), "Bombolles!", Color(0.96, 0.94, 0.88), m.POP_SAY)
		if ev.get("bump_hazard", false):
			m.human.patience = maxf(0.0, m.human.patience - 8.0)
			m.float_text(m.human.global_position + Vector2(0.0, -32.0), "Ugh, the bucket!", Color(0.95, 0.40, 0.35), m.POP_SAY)
			m.play_sfx("bump")
		if ev.get("bubble_pop", false):
			m.espanya_bubbles_popped += 1
			m.award_points(2, "bubble pop! +2")
			m.play_sfx("splash")
		if ev.get("soapy_slide", false):
			m.award_points(2, "soapy slide! +2")
		if ev.get("dodge_save", false):
			m.saves_done += 1
			m.award_points(2, "espanya dodge! +2")


static func on_bark(m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	if m.espanya_bubble != null and m.espanya_bubble.on_bark(m.dog.global_position):
		m.float_text(m.espanya_bubble.pos + Vector2(0.0, -42.0), "Molt bé!", Color(0.96, 0.94, 0.88), m.POP_SAY)
		m.award_points(2, "bubble cheer! +2")
		return true
	return false


# --- drawing -----------------------------------------------------------------

static func draw_edge_layer(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)

	# 1. Avenue paving stones & joint grid
	var py := floorf(vt / 120.0) * 120.0
	while py < vb + 120.0:
		b.rect(Rect2(WALL_L, py, WALL_R - WALL_L, 2.0), PAVING_JOINT)
		py += 120.0

	var px := WALL_L + 130.0
	while px < WALL_R - 20.0:
		b.rect(Rect2(px, vt - 40.0, 2.0, (vb - vt) + 80.0), PAVING_JOINT)
		px += 130.0

	# 2. Magic Fountain circular stone terrace & basin
	if FOUNTAIN_CENTER.y + FOUNTAIN_TERRACE_RADIUS > vt - 80.0 and FOUNTAIN_CENTER.y - FOUNTAIN_TERRACE_RADIUS < vb + 80.0:
		# Ground shadow
		b.circle(FOUNTAIN_CENTER + Vector2(6, 8), FOUNTAIN_TERRACE_RADIUS, sh)
		# Outer stone terrace ring
		b.circle(FOUNTAIN_CENTER, FOUNTAIN_TERRACE_RADIUS, PALACE_MARBLE)
		b.circle(FOUNTAIN_CENTER, FOUNTAIN_TERRACE_RADIUS - 12.0, PALACE_STONE_DARK)
		b.circle(FOUNTAIN_CENTER, FOUNTAIN_RADIUS + 8.0, FOUNTAIN_RIM)
		# Deep blue fountain pool
		b.circle(FOUNTAIN_CENTER, FOUNTAIN_RADIUS, WATER_DEEP)
		b.circle(FOUNTAIN_CENTER, FOUNTAIN_RADIUS - 20.0, WATER_SHALLOW)

	# 3. Grand Palace Cascades & Stairs (y = -3900 to -4450)
	if CASCADE_BOT > vt - 80.0 and CASCADE_TOP < vb + 80.0:
		var grand_rect := Rect2(WALL_L + 20.0, CASCADE_TOP, (WALL_R - WALL_L) - 40.0, CASCADE_BOT - CASCADE_TOP)
		b.rect(Rect2(grand_rect.position + Vector2(4, 6), grand_rect.size), sh)
		b.rect(grand_rect, PALACE_STONE_DARK)
		b.rect(grand_rect.grow(-6.0), PALACE_MARBLE)

		# Stepped cascade water pools down center
		var step_y := CASCADE_TOP + 40.0
		while step_y < CASCADE_BOT - 40.0:
			if step_y >= vt - 60.0 and step_y <= vb + 60.0:
				var pool_rect := Rect2(580.0, step_y, 120.0, 60.0)
				b.rect(Rect2(pool_rect.position + Vector2(3, 4), pool_rect.size), sh)
				b.rect(pool_rect, BALUSTRADE_STONE)
				b.rect(pool_rect.grow(-4.0), WATER_DEEP)
				b.rect(Rect2(586.0, step_y + 4.0, 108.0, 16.0), WATER_SHALLOW)
			step_y += 85.0

	b.flush(wc)


static func draw_live(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)
	var t: float = float(AnimClock.msec()) * 0.001

	# 1. Venetian Towers (lower gateway at y = -480.0)
	for tw_rect: Rect2 in [TOWER_WEST, TOWER_EAST]:
		if tw_rect.end.y > vt - 80.0 and tw_rect.position.y < vb + 80.0:
			b.rect(Rect2(tw_rect.position + Vector2(8, 12), tw_rect.size), sh)
			b.rect(tw_rect, TOWER_BRICK)
			b.rect(tw_rect.grow(-4.0), TOWER_BRICK.lightened(0.12))
			# Arched stone windows & cornice band
			b.rect(Rect2(tw_rect.position.x + 8.0, tw_rect.position.y + 12.0, tw_rect.size.x - 16.0, 6.0), TOWER_STONE)
			b.rect(Rect2(tw_rect.position.x + 12.0, tw_rect.position.y + 28.0, tw_rect.size.x - 24.0, 18.0), PALACE_STONE_DARK)

	# 2. Monumental Columns of Puig i Cadafalch (y = -2250.0)
	if COLUMNS_Y > vt - 80.0 and COLUMNS_Y < vb + 80.0:
		for col_p: Vector2 in COLUMN_POSTS:
			b.circle(col_p + Vector2(4, 6), 14.0, sh)
			b.circle(col_p, 12.0, PALACE_STONE_DARK)
			b.circle(col_p, 10.0, PALACE_MARBLE)
			b.circle(col_p, 5.0, PALACE_STONE_DARK)

	# 3. Magic Fountain central pedestal and choreographed dancing water jets
	if FOUNTAIN_CENTER.y + FOUNTAIN_RADIUS > vt - 80.0 and FOUNTAIN_CENTER.y - FOUNTAIN_RADIUS < vb + 80.0:
		# Central pedestal
		b.rect(Rect2(FOUNTAIN_PEDESTAL.position + Vector2(4, 6), FOUNTAIN_PEDESTAL.size), sh)
		b.rect(FOUNTAIN_PEDESTAL, PALACE_STONE_DARK)
		b.rect(FOUNTAIN_PEDESTAL.grow(-4.0), PALACE_MARBLE)

		# Dancing water jets animation (illuminated concentric fountains)
		var pulse: float = sin(t * 4.0) * 0.5 + 0.5
		# Inner jet ring
		for i in range(8):
			var angle: float = float(i) * (TAU / 8.0) + t * 0.8
			var jet_pos := FOUNTAIN_CENTER + Vector2(cos(angle), sin(angle)) * (35.0 + pulse * 12.0)
			b.circle(jet_pos, 5.0 + pulse * 3.0, WATER_SPRAY)
			b.circle(jet_pos, 2.5, Color.WHITE)

		# Outer jet ring
		for i in range(12):
			var angle: float = float(i) * (TAU / 12.0) - t * 0.5
			var jet_pos := FOUNTAIN_CENTER + Vector2(cos(angle), sin(angle)) * (70.0 + (1.0 - pulse) * 15.0)
			b.circle(jet_pos, 6.0 + (1.0 - pulse) * 4.0, WATER_SPRAY)
			b.circle(jet_pos, 3.0, Color.WHITE)

	# 4. Flanking Outdoor Escalators
	for esc: Rect2 in [ESCALATOR_L, ESCALATOR_R]:
		if esc.end.y > vt - 80.0 and esc.position.y < vb + 80.0:
			b.rect(Rect2(esc.position + Vector2(3, 4), esc.size), sh)
			b.rect(esc, ESCALATOR_FRAME)
			b.rect(esc.grow(-3.0), ESCALATOR_TREAD)
			# Handrail belts
			b.rect(Rect2(esc.position.x, esc.position.y, 4.0, esc.size.y), ESCALATOR_BELT)
			b.rect(Rect2(esc.end.x - 4.0, esc.position.y, 4.0, esc.size.y), ESCALATOR_BELT)
			# Moving step treads
			var step_y: float = esc.position.y + fposmod(-t * 80.0, 18.0)
			while step_y < esc.end.y - 4.0:
				b.rect(Rect2(esc.position.x + 5.0, step_y, esc.size.x - 10.0, 2.0), ESCALATOR_FRAME)
				step_y += 18.0

	# 5. Flagpoles along the avenue
	for fp: Vector2 in FLAGPOLES:
		if fp.y > vt - 80.0 and fp.y < vb + 80.0:
			b.circle(fp + Vector2(2, 3), 6.0, sh)
			b.circle(fp, 4.0, PALACE_STONE_DARK)
			b.circle(fp, 2.0, PALACE_MARBLE)

	# 6. Signature live event: El Bufador de Bombolles
	if m.espanya_bubble != null:
		m.espanya_bubble.draw(b)

	b.flush(wc)


static func draw_overhead(m: Node2D, wc: Object) -> void:
	var b := ShapeBatch.new()
	var cam_y: float = m.camera.position.y if m.camera != null else -1500.0

	# 1. Venetian Tower pyramid roofs and bellfrys (when lower gateway in view)
	if cam_y > -1000.0:
		for tw_rect: Rect2 in [TOWER_WEST, TOWER_EAST]:
			var roof_rect := Rect2(tw_rect.position.x - 4.0, tw_rect.position.y - 18.0, tw_rect.size.x + 8.0, 22.0)
			b.rect(roof_rect, TOWER_ROOF)
			b.rect(roof_rect.grow(-3.0), TOWER_ROOF.lightened(0.15))
			b.circle(tw_rect.get_center() + Vector2(0.0, -18.0), 4.0, TOWER_STONE)

	# 2. Senyera flags fluttering from monumental flagpoles
	for fp: Vector2 in FLAGPOLES:
		if absf(cam_y - fp.y) < 600.0:
			var flag_rect := Rect2(fp.x + 4.0, fp.y - 16.0, 28.0, 16.0)
			# 4 red stripes on golden background
			b.rect(flag_rect, FLAG_GOLD)
			b.rect(Rect2(flag_rect.position.x, flag_rect.position.y + 2.0, flag_rect.size.x, 2.5), FLAG_RED)
			b.rect(Rect2(flag_rect.position.x, flag_rect.position.y + 6.0, flag_rect.size.x, 2.5), FLAG_RED)
			b.rect(Rect2(flag_rect.position.x, flag_rect.position.y + 10.0, flag_rect.size.x, 2.5), FLAG_RED)
			b.rect(Rect2(flag_rect.position.x, flag_rect.position.y + 13.5, flag_rect.size.x, 2.5), FLAG_RED)

	b.flush(wc)
