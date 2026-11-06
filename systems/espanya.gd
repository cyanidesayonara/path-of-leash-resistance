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
const PRIZE_TEXT := "snatch the crystal finial off the cascade"

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
	# the leash caught on a column, read the way every walk reads a wrapped
	# pole (main._tick_vault)
	if m.espanya_columns_wrapped == 0 and m.leash != null:
		var pole: Vector2 = m.leash.contact_pole
		if pole.x < INF and m.leash.static_contacts > 0 and m.leash.contact_static and _is_column(pole):
			m.espanya_columns_wrapped = 1
			m.award_points(2, "columns wrap! +2")

	# 4. Bubble performer live event tick
	if m.espanya_bubble != null:
		var d_pos: Vector2 = m.dog.global_position
		var d_vel: Vector2 = m.dog.velocity if "velocity" in m.dog else Vector2.ZERO
		var h_pos: Vector2 = m.human.global_position
		var ev: Dictionary = m.espanya_bubble.tick(delta, d_pos, d_vel, h_pos)

		if ev.get("telegraph", false):
			m.float_text(m.espanya_bubble.pos + Vector2(0.0, -42.0), "Bubbles coming!", Color(0.96, 0.94, 0.88), m.POP_SAY)
		if ev.get("bump_hazard", false):
			m.human.patience = maxf(0.0, m.human.patience - 8.0)
			m.float_text(m.human.global_position + Vector2(0.0, -32.0), "Ugh, the bucket!", Color(0.95, 0.40, 0.35), m.POP_SAY)
			_play_sfx(m, "bump")
		if ev.get("bubble_pop", false):
			m.espanya_bubbles_popped += 1
			m.award_points(2, "bubble pop! +2")
			_play_sfx(m, "splash")
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

# --- drawing -----------------------------------------------------------------
# The walk climbs the real axis: Plaça d'Espanya's round paving between the two
# brick towers, Avinguda de la Reina Maria Cristina between the exhibition
# halls (granite slabs, a median of lit fountain grates), the Four Columns'
# platform, the Magic Fountain's plaza, the stairs and cascade with the outdoor
# escalators, and the palace terrace. The corridor ground is draw_cross_section
# (static: recorded once per stretch); what flanks it is draw_edge_layer.

const PLAZA_C := Vector2(640.0, 760.0)      # centre of the round plaza, behind the start
const PLAZA_TOP := -560.0                    # where the plaza's paving gives way to the avenue
const AVENUE_TOP := -2900.0                  # the avenue ends at the fountain plaza
const FOUNTAIN_PLAZA_TOP := -3500.0
const PALACE_Y := -4560.0                    # the palace wings start here, up to the gate

const GRANITE_A := Color(0.77, 0.75, 0.71)
const GRANITE_B := Color(0.72, 0.70, 0.66)
const GRANITE_C := Color(0.81, 0.79, 0.75)
const GRANITE_JOINT := Color(0.58, 0.56, 0.52)
const CURB := Color(0.50, 0.49, 0.47)
const MEDIAN := Color(0.66, 0.62, 0.55)
const GRATE := Color(0.26, 0.28, 0.30)
const GRATE_GLOW := Color(0.98, 0.92, 0.66, 0.55)
const PLAZA_LIGHT := Color(0.84, 0.81, 0.75)
const PLAZA_DARK := Color(0.74, 0.71, 0.66)
const STEP_EDGE := Color(0.62, 0.60, 0.56)
const FOAM := Color(0.96, 0.98, 1.0, 0.85)

const ASPHALT := Color(0.29, 0.30, 0.32)
const LANE := Color(0.88, 0.86, 0.80, 0.85)
const SAULO := Color(0.80, 0.72, 0.57)
const LAWN := Color(0.40, 0.56, 0.30)
const LAWN_STRIPE := Color(0.45, 0.61, 0.34)
const HEDGE := Color(0.20, 0.36, 0.20)
const HEDGE_TOP := Color(0.27, 0.45, 0.25)
const CROWN := Color(0.28, 0.44, 0.24)
const CROWN_LIT := Color(0.38, 0.55, 0.30)
const CYPRESS := Color(0.16, 0.30, 0.18)
const HALL_ROOF := Color(0.85, 0.79, 0.67)
const HALL_PARAPET := Color(0.70, 0.63, 0.51)
const HALL_SKYLIGHT := Color(0.58, 0.66, 0.70)
const PALACE_ROOF := Color(0.62, 0.52, 0.42)
const DOME := Color(0.50, 0.58, 0.56)

# the exhibition halls either side of the avenue, as (top, bottom) in y
const HALLS: Array[Vector2] = [
	Vector2(-1320.0, -640.0),
	Vector2(-2040.0, -1400.0),
	Vector2(-2900.0, -2440.0),
]


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


static func tree_kind(m: Node2D, _p: Vector2) -> int:
	# the columns and the flag masts are drawn as themselves, never as trees
	return m.TREE_NONE


static func is_lamp(_m: Node2D, _p: Vector2) -> bool:
	# no lamp head on a column or a flag mast; the night falls back to wall lamps
	return false


static func _is_column(p: Vector2) -> bool:
	# the columns are the poles on their row: the walk fits every pole's x to
	# the corridor after build, so the authored x never matches in play
	return absf(p.y - COLUMNS_Y) < 1.0


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_column(p):
		# an ionic column from above: its long shadow, the square plinth, the
		# fluted drum, the capital's abacus with a volute at each corner
		wc.capsule(p + Vector2(4.0, 6.0), p + LIGHT * 46.0, 12.0, SHADOW)
		wc.rect(Rect2(p - Vector2(19.0, 19.0), Vector2(38.0, 38.0)), PALACE_STONE_DARK)
		wc.rect(Rect2(p - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), BALUSTRADE_STONE)
		wc.circle(p, 14.0, PALACE_STONE_DARK)
		wc.circle(p, 12.5, PALACE_MARBLE)
		for k in range(12):
			wc.circle(p + Vector2.from_angle(TAU * float(k) / 12.0) * 10.5, 1.3, PALACE_STONE_DARK)
		wc.rect(Rect2(p - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), PALACE_MARBLE.lightened(0.06))
		for cx: float in [-1.0, 1.0]:
			for cy: float in [-1.0, 1.0]:
				var v := p + Vector2(cx, cy) * 9.0
				wc.circle(v, 3.4, PALACE_STONE_DARK)
				wc.circle(v, 2.2, PALACE_MARBLE)
		wc.circle(p, 4.0, PALACE_STONE_DARK.lightened(0.1))
		return
	# a flag mast: a stone footing, the white mast, a gilt finial
	wc.circle(p + Vector2(3.0, 4.0), 8.0, SHADOW)
	wc.rect(Rect2(p - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), PALACE_STONE_DARK)
	wc.circle(p, 4.5, Color(0.92, 0.92, 0.90))
	wc.circle(p, 2.2, FLAG_GOLD)


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 30.0, ctop)
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	wc.rect(Rect2(WALL_L, lo, WALL_R - WALL_L, hi - lo), GRANITE_A)
	if hi > PLAZA_TOP:
		_plaza_paving(wc, maxf(lo, PLAZA_TOP), hi)
	if lo < PLAZA_TOP and hi > AVENUE_TOP:
		_slabs(wc, maxf(lo, AVENUE_TOP), minf(hi, PLAZA_TOP), 104.0, 60.0, 0)
		_median(wc, maxf(lo, AVENUE_TOP), minf(hi, PLAZA_TOP))
	if COLUMNS_Y + 70.0 > lo and COLUMNS_Y - 70.0 < hi:
		_column_platform(wc)
	if lo < AVENUE_TOP and hi > FOUNTAIN_PLAZA_TOP:
		_slabs(wc, maxf(lo, FOUNTAIN_PLAZA_TOP), minf(hi, AVENUE_TOP), 130.0, 90.0, 40)
	if FOUNTAIN_CENTER.y + FOUNTAIN_TERRACE_RADIUS + 120.0 > lo and FOUNTAIN_CENTER.y - FOUNTAIN_TERRACE_RADIUS - 120.0 < hi:
		_fountain_ground(wc)
	if lo < FOUNTAIN_PLAZA_TOP and hi > CASCADE_BOT:
		_slabs(wc, maxf(lo, CASCADE_BOT), minf(hi, FOUNTAIN_PLAZA_TOP), 130.0, 90.0, 80)
	if lo < CASCADE_BOT and hi > CASCADE_TOP:
		_stairs(wc, maxf(lo, CASCADE_TOP), minf(hi, CASCADE_BOT))
	if lo < CASCADE_TOP:
		_slabs(wc, lo, minf(hi, CASCADE_TOP), 130.0, 130.0, 120)
	# the kerb along both sides, all the way up
	wc.rect(Rect2(WALL_L, lo, 8.0, hi - lo), CURB)
	wc.rect(Rect2(WALL_R - 8.0, lo, 8.0, hi - lo), CURB)


# the round plaza's paving: bands of light and dark stone on circles round the
# plaza's centre, clipped to the walk (the last band ends at PLAZA_TOP)
static func _plaza_paving(wc: ShapeBatch, lo: float, hi: float) -> void:
	var half := (WALL_R - WALL_L) * 0.5
	var r := 300.0
	var band := 0
	while r + 32.0 <= PLAZA_C.y - PLAZA_TOP:
		var r2 := r + 32.0
		var top_y := PLAZA_C.y - r2
		var low_y := PLAZA_C.y - sqrt(maxf(r * r - half * half, 0.0))
		if top_y < hi and low_y > lo:
			var pts := PackedVector2Array()
			var n := 10
			for i in range(n + 1):
				var x := lerpf(WALL_L, WALL_R, float(i) / float(n))
				pts.append(Vector2(x, PLAZA_C.y - sqrt(maxf(r2 * r2 - pow(x - PLAZA_C.x, 2.0), 0.0))))
			for i in range(n, -1, -1):
				var x := lerpf(WALL_L, WALL_R, float(i) / float(n))
				pts.append(Vector2(x, PLAZA_C.y - sqrt(maxf(r * r - pow(x - PLAZA_C.x, 2.0), 0.0))))
			wc.polygon(pts, PLAZA_LIGHT if band % 2 == 0 else PLAZA_DARK)
			for i in range(n):
				wc.line(pts[i], pts[i + 1], GRANITE_JOINT, 1.5)
		r = r2
		band += 1
	# radial joints out from the centre, inside the walk
	for k in range(-2, 3):
		var d := Vector2.from_angle(-PI * 0.5 + float(k) * 0.085)
		var p1 := PLAZA_C + d * ((PLAZA_C.y - PLAZA_TOP) / -d.y)
		wc.line(PLAZA_C + d * 300.0, p1, Color(GRANITE_JOINT.r, GRANITE_JOINT.g, GRANITE_JOINT.b, 0.6), 1.2)


# big granite slabs in a running bond, three tones, from lo to hi
static func _slabs(wc: ShapeBatch, lo: float, hi: float, sw: float, sh: float, salt: int) -> void:
	if hi <= lo:
		return
	var row := int(floorf(lo / sh))
	var y := float(row) * sh
	while y < hi:
		var off := (sw * 0.5) if row % 2 != 0 else 0.0
		var x := WALL_L - off
		var col := 0
		while x < WALL_R:
			var x0 := maxf(x, WALL_L)
			var x1 := minf(x + sw, WALL_R)
			var y0 := maxf(y, lo)
			var y1 := minf(y + sh, hi)
			if x1 > x0 and y1 > y0:
				var hv := _h(row * 31 + col * 7 + salt)
				if hv > 0.62:
					wc.rect(Rect2(x0, y0, x1 - x0, y1 - y0), GRANITE_B if hv < 0.84 else GRANITE_C)
				wc.rect(Rect2(x0, y0, 2.0, y1 - y0), GRANITE_JOINT)
			x += sw
			col += 1
		if y >= lo:
			wc.rect(Rect2(WALL_L, y, WALL_R - WALL_L, 2.0), GRANITE_JOINT)
		y += sh
		row += 1


# the avenue's median: a warm stone strip with a lit fountain grate every 180
static func _median(wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.rect(Rect2(612.0, lo, 56.0, hi - lo), MEDIAN)
	wc.rect(Rect2(612.0, lo, 3.0, hi - lo), CURB)
	wc.rect(Rect2(665.0, lo, 3.0, hi - lo), CURB)
	var gy := floorf(lo / 180.0) * 180.0
	while gy < hi:
		if gy > lo and absf(gy - COLUMNS_Y) > 120.0:
			wc.circle(Vector2(640.0, gy), 13.0, CURB)
			wc.circle(Vector2(640.0, gy), 11.0, GRATE)
			wc.glow(Vector2(640.0, gy), 10.0, GRATE_GLOW)
			for k in range(4):
				var d := Vector2.from_angle(TAU * float(k) / 4.0 + PI / 4.0)
				wc.line(Vector2(640.0, gy) - d * 10.0, Vector2(640.0, gy) + d * 10.0, GRATE, 1.4)
		gy += 180.0


# the Four Columns stand on a raised marble platform across the avenue
static func _column_platform(wc: ShapeBatch) -> void:
	var r := Rect2(470.0, COLUMNS_Y - 64.0, 340.0, 128.0)
	wc.rect(Rect2(r.position + Vector2(5.0, 7.0), r.size), SHADOW)
	wc.rect(r, PALACE_STONE_DARK)
	wc.rect(r.grow(-5.0), PALACE_MARBLE)
	wc.rect(r.grow(-14.0), BALUSTRADE_STONE)
	wc.rect(r.grow(-18.0), PALACE_MARBLE.lightened(0.03))
	# the two steps up, front and back
	for sy: float in [r.position.y + 5.0, r.end.y - 9.0]:
		wc.rect(Rect2(r.position.x + 5.0, sy, r.size.x - 10.0, 4.0), STEP_EDGE)


# the Magic Fountain's plaza: radial paving, the stone terrace, the rim, the
# basin's water and the nozzles that rest under it between shows
static func _fountain_ground(wc: ShapeBatch) -> void:
	var c := FOUNTAIN_CENTER
	for k in range(28):
		var d := Vector2.from_angle(TAU * float(k) / 28.0)
		wc.line(c + d * (FOUNTAIN_TERRACE_RADIUS + 4.0), c + d * 250.0, GRANITE_JOINT, 1.6)
	wc.circle(c + Vector2(6.0, 8.0), FOUNTAIN_TERRACE_RADIUS, SHADOW)
	wc.circle(c, FOUNTAIN_TERRACE_RADIUS, PALACE_STONE_DARK)
	wc.circle(c, FOUNTAIN_TERRACE_RADIUS - 4.0, PALACE_MARBLE)
	for k in range(24):
		var d := Vector2.from_angle(TAU * float(k) / 24.0)
		wc.line(c + d * (FOUNTAIN_RADIUS + 12.0), c + d * (FOUNTAIN_TERRACE_RADIUS - 6.0), BALUSTRADE_STONE, 1.4)
	wc.circle(c, FOUNTAIN_RADIUS + 10.0, PALACE_STONE_DARK)
	wc.circle(c, FOUNTAIN_RADIUS + 7.0, FOUNTAIN_RIM)
	wc.circle(c, FOUNTAIN_RADIUS, WATER_DEEP)
	wc.glow(c, FOUNTAIN_RADIUS - 6.0, WATER_SHALLOW, 0.2)
	# the inner basin step and the nozzle rings
	wc.circle(c, 50.0, Color(WATER_DEEP.r, WATER_DEEP.g, WATER_DEEP.b, 0.55))
	for k in range(16):
		wc.circle(c + Vector2.from_angle(TAU * float(k) / 16.0) * 78.0, 2.2, Color(0.10, 0.22, 0.32))
	for k in range(8):
		wc.circle(c + Vector2.from_angle(TAU * float(k) / 8.0) * 40.0, 2.2, Color(0.10, 0.22, 0.32))


# the stairs up to the palace, each tread's nosing, a landing at every pool,
# and the cascade down the middle in stepped basins with a lip of foam
static func _stairs(wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.rect(Rect2(WALL_L, lo, WALL_R - WALL_L, hi - lo), PALACE_MARBLE)
	var sy := floorf(lo / 14.0) * 14.0
	while sy < hi:
		if sy >= lo:
			var landing := fposmod(sy - (CASCADE_TOP + 40.0), 85.0) < 28.0
			if not landing:
				wc.rect(Rect2(WALL_L, sy, 580.0 - WALL_L - 14.0, 3.0), STEP_EDGE)
				wc.rect(Rect2(714.0, sy, WALL_R - 714.0, 3.0), STEP_EDGE)
		sy += 14.0
	# the balustrades either side of the cascade
	wc.rect(Rect2(562.0, lo, 14.0, hi - lo), BALUSTRADE_STONE)
	wc.rect(Rect2(704.0, lo, 14.0, hi - lo), BALUSTRADE_STONE)
	var by := floorf(lo / 12.0) * 12.0
	while by < hi:
		wc.circle(Vector2(569.0, by), 3.0, PALACE_STONE_DARK)
		wc.circle(Vector2(711.0, by), 3.0, PALACE_STONE_DARK)
		by += 12.0
	wc.rect(Rect2(580.0, lo, 120.0, hi - lo), PALACE_STONE_DARK)
	var py := CASCADE_TOP + 40.0
	while py < CASCADE_BOT - 40.0:
		if py + 60.0 > lo and py < hi:
			var pool := Rect2(580.0, py, 120.0, 60.0)
			wc.rect(pool, BALUSTRADE_STONE)
			wc.rect(pool.grow(-4.0), WATER_DEEP)
			wc.rect(Rect2(586.0, py + 4.0, 108.0, 16.0), WATER_SHALLOW)
			# the sheet of water falling over the lip into the next basin
			wc.rect(Rect2(586.0, py + 56.0, 108.0, 6.0), FOAM)
			wc.rect(Rect2(586.0, py + 62.0, 108.0, 23.0), Color(WATER_SHALLOW.r, WATER_SHALLOW.g, WATER_SHALLOW.b, 0.8))
		py += 85.0


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, float(m.GATE_Y) - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	for side: float in [-1.0, 1.0]:
		var x_in := WALL_L if side < 0.0 else WALL_R
		var x_out := -420.0 if side < 0.0 else 1700.0
		var fx := minf(x_in, x_out)
		var fw := absf(x_out - x_in)
		# the base: lawn, under everything that follows
		b.rect(Rect2(fx, top, fw, bot - top), LAWN)
		# the round plaza's traffic ring at the bottom
		if bot > PLAZA_TOP:
			_traffic_ring(b, side, maxf(top, PLAZA_TOP), bot)
		# the avenue: a sauló strip of plane trees, then the halls
		if top < PLAZA_TOP and bot > AVENUE_TOP:
			_avenue_side(b, side, maxf(top, AVENUE_TOP), minf(bot, PLAZA_TOP))
		# the gardens round the fountain and the terraces up to the palace
		if top < AVENUE_TOP:
			_gardens(b, side, top, minf(bot, AVENUE_TOP))
		if top < PALACE_Y:
			_palace_wing(b, side)


static func _xs(side: float, a: float, w: float) -> Rect2:
	# a strip from a px to a + w px outward of the walk's edge on that side
	if side < 0.0:
		return Rect2(WALL_L - a - w, 0.0, w, 0.0)
	return Rect2(WALL_R + a, 0.0, w, 0.0)


static func _strip(side: float, a: float, w: float, y0: float, y1: float) -> Rect2:
	var r := _xs(side, a, w)
	return Rect2(r.position.x, y0, r.size.x, y1 - y0)


static func _traffic_ring(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	b.rect(_strip(side, 30.0, 900.0, lo, hi), ASPHALT)
	b.rect(_strip(side, 0.0, 30.0, lo, hi), PLAZA_LIGHT)
	b.rect(_strip(side, 26.0, 4.0, lo, hi), CURB)
	# lane dashes on circles round the plaza
	for rr: float in [880.0, 980.0, 1080.0]:
		for k in range(40):
			var a0 := -PI * 0.5 + side * (0.30 + float(k) * 0.025)
			var p0 := PLAZA_C + Vector2.from_angle(a0) * rr
			var p1 := PLAZA_C + Vector2.from_angle(a0 + side * 0.012) * rr
			if p0.y > lo and p0.y < hi and (p0.x < WALL_L - 34.0 or p0.x > WALL_R + 34.0):
				b.line(p0, p1, LANE, 3.0)
	# a zebra crossing into the plaza beside each tower
	var zy := -380.0
	if zy > lo and zy < hi:
		for k in range(7):
			b.rect(_strip(side, 40.0, 70.0, zy - 40.0 + float(k) * 12.0, zy - 34.0 + float(k) * 12.0), LANE)


static func _avenue_side(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	b.rect(_strip(side, 0.0, 70.0, lo, hi), SAULO)
	b.rect(_strip(side, 0.0, 4.0, lo, hi), CURB)
	# the road behind the trees, and past it the halls
	b.rect(_strip(side, 70.0, 66.0, lo, hi), ASPHALT)
	var dy := floorf(lo / 60.0) * 60.0
	while dy < hi:
		b.rect(_strip(side, 101.0, 4.0, dy, dy + 28.0), LANE)
		dy += 60.0
	b.rect(_strip(side, 136.0, 900.0, lo, hi), PLAZA_LIGHT)
	for hall: Vector2 in HALLS:
		if hall.y > lo - 40.0 and hall.x < hi + 40.0:
			_hall(b, side, hall.x, hall.y)
	# plane trees down the sauló strip
	var ty := floorf(lo / 140.0) * 140.0 + 70.0
	while ty < hi + 40.0:
		if absf(ty - COLUMNS_Y) > 140.0:
			var tx := (WALL_L - 36.0) if side < 0.0 else (WALL_R + 36.0)
			var k := int(absf(ty) / 140.0) + (0 if side < 0.0 else 11)
			var rr := 28.0 + _h(k) * 6.0
			b.circle(Vector2(tx + 10.0, ty + 14.0), rr, SHADOW)
			b.circle(Vector2(tx, ty), rr, CROWN)
			b.circle(Vector2(tx - 6.0, ty - 7.0), rr * 0.62, CROWN_LIT)
			b.circle(Vector2(tx + 8.0, ty + 5.0), rr * 0.35, CROWN.darkened(0.15))
		ty += 140.0


# an exhibition hall's roof from above: parapet, cream roof, a row of glazed
# skylights, a lantern over the entrance, and the colonnade facing the avenue
static func _hall(b: ShapeBatch, side: float, y0: float, y1: float) -> void:
	var r := _strip(side, 150.0, 300.0, y0, y1)
	b.rect(Rect2(r.position + Vector2(10.0, 14.0), r.size), SHADOW)
	b.rect(r, HALL_PARAPET)
	b.rect(r.grow(-7.0), HALL_ROOF)
	var sk := r.grow(-34.0)
	var sy := sk.position.y
	while sy < sk.end.y - 30.0:
		b.rect(Rect2(sk.position.x, sy, sk.size.x, 26.0), HALL_SKYLIGHT)
		b.rect(Rect2(sk.position.x, sy + 11.0, sk.size.x, 3.0), HALL_SKYLIGHT.lightened(0.25))
		sy += 48.0
	var cy := (y0 + y1) * 0.5
	var cx := r.position.x + 40.0 if side > 0.0 else r.end.x - 40.0
	b.circle(Vector2(cx + 6.0, cy + 8.0), 30.0, SHADOW)
	b.circle(Vector2(cx, cy), 30.0, HALL_PARAPET)
	b.circle(Vector2(cx, cy), 25.0, DOME)
	b.circle(Vector2(cx - 7.0, cy - 8.0), 10.0, DOME.lightened(0.2))
	# the colonnade along the avenue front
	var fx := r.end.x + 8.0 if side < 0.0 else r.position.x - 8.0
	b.rect(Rect2(fx - 6.0, y0, 12.0, y1 - y0), HALL_PARAPET.lightened(0.1))
	var py := y0 + 10.0
	while py < y1 - 6.0:
		b.circle(Vector2(fx, py), 4.0, PALACE_MARBLE)
		py += 22.0


static func _gardens(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	if hi <= lo:
		return
	# a paved promenade along the walk, then mown lawns in stripes
	b.rect(_strip(side, 0.0, 40.0, lo, hi), PLAZA_LIGHT)
	b.rect(_strip(side, 0.0, 4.0, lo, hi), CURB)
	var sy := floorf(lo / 48.0) * 48.0
	while sy < hi:
		if int(absf(sy) / 48.0) % 2 == 0:
			b.rect(_strip(side, 52.0, 900.0, maxf(sy, lo), minf(sy + 24.0, hi)), LAWN_STRIPE)
		sy += 48.0
	# clipped hedges edging the lawns, and terrace walls up the hill
	b.rect(_strip(side, 40.0, 12.0, lo, hi), HEDGE)
	b.rect(_strip(side, 42.0, 8.0, lo, hi), HEDGE_TOP)
	var wy := floorf(lo / 160.0) * 160.0
	while wy < hi:
		if wy < FOUNTAIN_PLAZA_TOP and wy > lo:
			b.rect(_strip(side, 52.0, 900.0, wy, wy + 8.0), PALACE_STONE_DARK)
			b.rect(_strip(side, 52.0, 900.0, wy, wy + 3.0), PALACE_MARBLE)
		wy += 160.0
	# rows of cypresses
	var cy := floorf(lo / 70.0) * 70.0
	while cy < hi + 20.0:
		var cxp := (WALL_L - 120.0) if side < 0.0 else (WALL_R + 120.0)
		if cy > lo - 20.0:
			b.circle(Vector2(cxp + 6.0, cy + 9.0), 13.0, SHADOW)
			b.circle(Vector2(cxp, cy), 13.0, CYPRESS)
			b.circle(Vector2(cxp - 3.0, cy - 4.0), 7.0, HEDGE_TOP)
		cy += 70.0


# the palace's wings either side of the gate, with a domed corner tower each
static func _palace_wing(b: ShapeBatch, side: float) -> void:
	var r := _strip(side, 60.0, 520.0, -5040.0, PALACE_Y)
	b.rect(Rect2(r.position + Vector2(12.0, 16.0), r.size), SHADOW)
	b.rect(r, PALACE_STONE_DARK)
	b.rect(r.grow(-6.0), PALACE_ROOF)
	b.rect(r.grow(-22.0), PALACE_ROOF.lightened(0.08))
	# the terrace balustrade along its front
	b.rect(Rect2(r.position.x, r.end.y - 14.0, r.size.x, 14.0), BALUSTRADE_STONE)
	var bx := r.position.x + 6.0
	while bx < r.end.x:
		b.circle(Vector2(bx, r.end.y - 7.0), 3.0, PALACE_STONE_DARK)
		bx += 12.0
	var tc := Vector2(r.end.x - 40.0 if side < 0.0 else r.position.x + 40.0, r.end.y - 60.0)
	b.rect(Rect2(tc - Vector2(34.0, 34.0) + Vector2(8.0, 10.0), Vector2(68.0, 68.0)), SHADOW)
	b.rect(Rect2(tc - Vector2(34.0, 34.0), Vector2(68.0, 68.0)), PALACE_STONE_DARK)
	b.rect(Rect2(tc - Vector2(29.0, 29.0), Vector2(58.0, 58.0)), PALACE_MARBLE)
	b.circle(tc, 22.0, DOME)
	b.circle(tc + Vector2(-6.0, -7.0), 8.0, DOME.lightened(0.22))
	b.circle(tc, 4.0, FLAG_GOLD)


static func draw_live(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var t: float = float(AnimClock.msec()) * 0.001

	# 1. the Venetian towers: brick shafts with stone quoins and a cornice,
	# their pyramid roofs drawn overhead
	for tw_rect: Rect2 in [TOWER_WEST, TOWER_EAST]:
		if tw_rect.end.y > vt - 120.0 and tw_rect.position.y < vb + 120.0:
			b.polygon(PackedVector2Array([tw_rect.position, tw_rect.position + Vector2(tw_rect.size.x, 0.0),
				tw_rect.end + LIGHT * 70.0, Vector2(tw_rect.position.x, tw_rect.end.y) + LIGHT * 70.0]), SHADOW)
			b.rect(tw_rect, TOWER_STONE)
			b.rect(tw_rect.grow(-4.0), TOWER_BRICK)
			var cy := tw_rect.position.y + 8.0
			while cy < tw_rect.end.y - 6.0:
				b.rect(Rect2(tw_rect.position.x + 4.0, cy, tw_rect.size.x - 8.0, 1.5), TOWER_BRICK.darkened(0.18))
				cy += 7.0
			for q: Vector2 in [tw_rect.position, tw_rect.position + Vector2(tw_rect.size.x - 8.0, 0.0),
					Vector2(tw_rect.position.x, tw_rect.end.y - 8.0), tw_rect.end - Vector2(8.0, 8.0)]:
				b.rect(Rect2(q, Vector2(8.0, 8.0)), TOWER_STONE.lightened(0.08))

	# 2. the Magic Fountain's show: a ring of tall jets rising and falling in
	# turn round a central plume, spray drifting off each
	if FOUNTAIN_CENTER.y + FOUNTAIN_RADIUS > vt - 80.0 and FOUNTAIN_CENTER.y - FOUNTAIN_RADIUS < vb + 80.0:
		var c := FOUNTAIN_CENTER
		b.rect(Rect2(FOUNTAIN_PEDESTAL.position + Vector2(4.0, 6.0), FOUNTAIN_PEDESTAL.size), SHADOW)
		b.rect(FOUNTAIN_PEDESTAL, PALACE_STONE_DARK)
		b.rect(FOUNTAIN_PEDESTAL.grow(-4.0), PALACE_MARBLE)
		var pulse: float = sin(t * 1.6) * 0.5 + 0.5
		for k in range(16):
			var a := TAU * float(k) / 16.0
			var lift: float = 0.5 + 0.5 * sin(t * 2.2 - float(k) * 0.8)
			var jp := c + Vector2.from_angle(a) * 78.0
			b.glow(jp, 9.0 + lift * 9.0, WATER_SPRAY)
			b.circle(jp, 2.0 + lift * 1.5, Color.WHITE)
		for k in range(8):
			var a := TAU * float(k) / 8.0 + t * 0.4
			var jp := c + Vector2.from_angle(a) * (40.0 + pulse * 6.0)
			b.glow(jp, 8.0 + pulse * 6.0, WATER_SPRAY)
		b.glow(c, 30.0 + pulse * 14.0, Color(1.0, 1.0, 1.0, 0.65))

	# 3. the outdoor escalators beside the stairs
	for esc: Rect2 in [ESCALATOR_L, ESCALATOR_R]:
		if esc.end.y > vt - 80.0 and esc.position.y < vb + 80.0:
			b.rect(Rect2(esc.position + Vector2(3.0, 4.0), esc.size), SHADOW)
			b.rect(esc, ESCALATOR_FRAME)
			b.rect(esc.grow(-3.0), ESCALATOR_TREAD)
			b.rect(Rect2(esc.position.x, esc.position.y, 4.0, esc.size.y), ESCALATOR_BELT)
			b.rect(Rect2(esc.end.x - 4.0, esc.position.y, 4.0, esc.size.y), ESCALATOR_BELT)
			var step_y: float = esc.position.y + fposmod(-t * 80.0, 18.0)
			while step_y < esc.end.y - 4.0:
				b.rect(Rect2(esc.position.x + 5.0, step_y, esc.size.x - 10.0, 2.0), ESCALATOR_FRAME)
				step_y += 18.0

	# 4. the bubble performer
	if m.espanya_bubble != null:
		m.espanya_bubble.draw(b)

	b.flush(wc)


static func draw_overhead(m: Node2D, wc: Object) -> void:
	var b := ShapeBatch.new()
	var cam_y: float = m.camera.position.y if m.camera != null else -1500.0

	# 1. the towers' pyramid roofs, lit side and shaded side, and a finial
	if cam_y > -1100.0:
		for tw_rect: Rect2 in [TOWER_WEST, TOWER_EAST]:
			var rr := tw_rect.grow(2.0)
			var apex := rr.get_center()
			var a := rr.position
			var bb := Vector2(rr.end.x, rr.position.y)
			var cc := rr.end
			var d := Vector2(rr.position.x, rr.end.y)
			b.polygon(PackedVector2Array([a, bb, apex]), TOWER_ROOF.lightened(0.18))
			b.polygon(PackedVector2Array([bb, cc, apex]), TOWER_ROOF)
			b.polygon(PackedVector2Array([cc, d, apex]), TOWER_ROOF.darkened(0.2))
			b.polygon(PackedVector2Array([d, a, apex]), TOWER_ROOF.lightened(0.06))
			b.circle(apex, 4.0, FLAG_GOLD)

	# 2. a senyera on each flag mast, rippling
	var t: float = float(AnimClock.msec()) * 0.001
	for fp: Vector2 in FLAGPOLES:
		if absf(cam_y - fp.y) < 600.0:
			var dir := 1.0 if fp.x < 640.0 else -1.0
			for s in range(6):
				var x0 := fp.x + dir * (3.0 + float(s) * 5.0)
				var wob := sin(t * 5.0 + float(s) * 0.9 + fp.y * 0.01) * 1.6
				var col := Rect2(minf(x0, x0 + dir * 5.0), fp.y - 18.0 + wob, 5.0, 18.0)
				b.rect(col, FLAG_GOLD)
				for k in range(4):
					b.rect(Rect2(col.position.x, col.position.y + 2.0 + float(k) * 4.0, 5.0, 2.0), FLAG_RED)

	b.flush(wc)


# the Sfx autoload looked up at run time, as systems/detour.gd does, so a test
# that loads this script on its own still compiles it
static func _play_sfx(m: Node2D, sound: String) -> void:
	if m != null and m.has_node("/root/Sfx"):
		m.get_node("/root/Sfx").play(sound)
