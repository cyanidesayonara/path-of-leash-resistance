class_name Santpau
extends RefCounted

# WALK 37: SANT PAU (Recinte Modernista de Sant Pau).
#
# Domènech i Montaner's garden hospital, walked at dusk: in from Avinguda de
# Gaudí's end past the gate lodges, up the central stone garden axis between
# symmetrical red-brick modernista pavilions with glazed ceramic domes and
# corner turrets, flanked by grass garden beds of lavender and bitter-orange
# trees, up to the Administration pavilion's clock tower and out into the
# off-leash garden courtyard (Jardins de Sant Pau).
#
# A calm, scenic walk: no chase, no boss.
#
# Live event: as the pair approaches the upper garden cross-axis, the clock
# tower chimes the hour (WARN >= 0.8 s, golden ripples and bells) and a school
# tour group streams east across the axis behind its guide's raised umbrella.
# Bump or bark rules match the other crowd events.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const Panot := preload("res://world/panot.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const NearMiss := preload("res://systems/near_miss.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")

const CX := 640.0
const HALF := 370.0
const WALL_L := CX - HALF           # 270.0
const WALL_R := CX + HALF           # 1010.0
const START := 260.0
const GATE := -5000.0
const SUN := Vector2(0.6, 0.8)

# --- solid pavilions (rope wraps on their corners, bodies keep everyone out) ---
const GATE_LODGE_L := Rect2(320.0, -400.0, 110.0, 130.0)
const GATE_LODGE_R := Rect2(850.0, -400.0, 110.0, 130.0)

const PAV_SW := Rect2(280.0, -1080.0, 150.0, 320.0)
const PAV_SE := Rect2(850.0, -1080.0, 150.0, 320.0)
const PAV_MW := Rect2(280.0, -2140.0, 150.0, 340.0)
const PAV_ME := Rect2(850.0, -2140.0, 150.0, 340.0)
const PAV_NW := Rect2(280.0, -3240.0, 150.0, 340.0)
const PAV_NE := Rect2(850.0, -3240.0, 150.0, 340.0)

const ADMIN_W := Rect2(280.0, -4680.0, 210.0, 280.0)
const ADMIN_E := Rect2(790.0, -4680.0, 210.0, 280.0)

const PAVILIONS: Array[Rect2] = [
	GATE_LODGE_L, GATE_LODGE_R,
	PAV_SW, PAV_SE,
	PAV_MW, PAV_ME,
	PAV_NW, PAV_NE,
	ADMIN_W, ADMIN_E,
]

# The Clock Tower sits on the inner corner of the Administration Pavilion's west wing.
const CLOCK_TOWER_POS := Vector2(448.0, -4510.0)
const CLOCK_CHIME_R := 1200.0
const CLOCK_WARN_T := 1.0
const CLOCK_CHIME_T := 3.6
const HOME_CHIME_Y := -4100.0

# --- garden beds along the central axis (handle as Surfaces.S.GRASS) ----------
const GARDEN_BEDS: Array[Rect2] = [
	Rect2(452.0, -740.0, 96.0, 290.0),
	Rect2(732.0, -740.0, 96.0, 290.0),
	Rect2(452.0, -1080.0, 96.0, 310.0),
	Rect2(732.0, -1080.0, 96.0, 310.0),
	Rect2(452.0, -1460.0, 96.0, 260.0),
	Rect2(732.0, -1460.0, 96.0, 260.0),
	Rect2(452.0, -2140.0, 96.0, 360.0),
	Rect2(732.0, -2140.0, 96.0, 360.0),
	Rect2(452.0, -2860.0, 96.0, 380.0),
	Rect2(732.0, -2860.0, 96.0, 380.0),
	Rect2(452.0, -3240.0, 96.0, 340.0),
	Rect2(732.0, -3240.0, 96.0, 340.0),
	Rect2(452.0, -4200.0, 96.0, 580.0),
	Rect2(732.0, -4200.0, 96.0, 580.0),
]

# Off-leash courtyard garden beds (Jardins de Sant Pau, inside y < GATE)
const COURTYARD_BEDS: Array[Rect2] = [
	Rect2(140.0, -5315.0, 350.0, 235.0),
	Rect2(790.0, -5315.0, 320.0, 235.0),
	Rect2(140.0, -5575.0, 350.0, 170.0),
	Rect2(790.0, -5575.0, 320.0, 170.0),
]
const COURTYARD_FOUNTAIN := Vector2(640.0, -5360.0)

# --- key spots & props -------------------------------------------------------
const FOUNTAIN_AXIS := Vector2(640.0, -2310.0)
const DARE_POS := Vector2(780.0, -1580.0)
const PRIZE := Vector2(548.0, -4320.0)
const PRIZE_TEXT := "snatch the candied orange off the garden bench"

# Bitter-orange trees standing in the garden beds (registered as TREE_PIT poles)
const ORANGE_TREES: Array[Vector2] = [
	Vector2(500.0, -595.0), Vector2(780.0, -595.0),
	Vector2(500.0, -925.0), Vector2(780.0, -925.0),
	Vector2(500.0, -1330.0), Vector2(780.0, -1330.0),
	Vector2(500.0, -1960.0), Vector2(780.0, -1960.0),
	Vector2(500.0, -2670.0), Vector2(780.0, -2670.0),
	Vector2(500.0, -3070.0), Vector2(780.0, -3070.0),
	Vector2(500.0, -3910.0), Vector2(780.0, -3910.0),
]

# Ornamental Modernista wrought-iron garden lampposts along the central stone walk
const LAMPS: Array[Vector2] = [
	Vector2(552.0, -190.0), Vector2(728.0, -190.0),
	Vector2(552.0, -480.0), Vector2(728.0, -480.0),
	Vector2(552.0, -820.0), Vector2(728.0, -820.0),
	Vector2(552.0, -1160.0), Vector2(728.0, -1160.0),
	Vector2(552.0, -1560.0), Vector2(728.0, -1560.0),
	Vector2(552.0, -1840.0), Vector2(728.0, -1840.0),
	Vector2(552.0, -2200.0), Vector2(728.0, -2200.0),
	Vector2(552.0, -2560.0), Vector2(728.0, -2560.0),
	Vector2(552.0, -2960.0), Vector2(728.0, -2960.0),
	Vector2(552.0, -3340.0), Vector2(728.0, -3340.0),
	Vector2(552.0, -3720.0), Vector2(728.0, -3720.0),
	Vector2(552.0, -4140.0), Vector2(728.0, -4140.0),
	Vector2(530.0, -4450.0), Vector2(750.0, -4450.0),
	Vector2(530.0, -4760.0), Vector2(750.0, -4760.0),
]

# Bench positions along the stone walk (keep clear of garden beds & solid pavilions)
const BENCH_SPOTS: Array[Vector2] = [
	Vector2(442.0, -1180.0), Vector2(838.0, -1180.0),
	Vector2(442.0, -1620.0), Vector2(838.0, -2420.0),
	Vector2(442.0, -3490.0), Vector2(838.0, -3490.0),
	Vector2(442.0, -4320.0), Vector2(838.0, -4320.0),
]

# Architecture sketchers / photographers standing on stone terraces (gated by Outdoors.sketchers_out)
const SKETCHER_SPOTS: Array[Dictionary] = [
	{"pos": Vector2(476.0, -1140.0), "face": Vector2(-0.8, 0.6), "key": 3701},
	{"pos": Vector2(804.0, -2380.0), "face": Vector2(0.8, 0.6), "key": 3702},
	{"pos": Vector2(478.0, -3550.0), "face": Vector2(-0.7, 0.7), "key": 3703},
]

# --- tour event constants -----------------------------------------------------
const TOUR_CROSS_Y := -3410.0
const TOUR_TRIGGER_Y := -3050.0
const TOUR_START_X := 295.0
const TOUR_END_X := 1020.0
const TOUR_SPEED := 96.0
const TOUR_WARN := 1.0           # >= 0.8 s warning telegraph before stepping onto axis
const TOUR_COUNT := 8            # schoolkids behind the guide
const TOUR_GAP := 30.0
const TOUR_SWAY := 6.0
const TOUR_BUMP_R := 24.0
const TOUR_THREAT_R := 72.0
const TOUR_BOOP_R := 26.0
const TOUR_BARK_R := 180.0
const TOUR_SNATCH_R := 24.0
const TOUR_PATIENCE_COST := 0.12

# --- colours (Trencadis + Sant Pau brick & glaze palette) ---------------------
const SHADOW := Color(0.05, 0.04, 0.09, 0.24)
const STONE_PAVE := Color(0.74, 0.69, 0.61)
const STONE_LIT := Color(0.80, 0.75, 0.67)
const STONE_JOINT := Color(0.58, 0.53, 0.46, 0.55)
const KERB_STONE := Color(0.84, 0.80, 0.72)
const PANOT_BASE := Color(0.64, 0.66, 0.68)
const PANOT_INK := Color(0.10, 0.12, 0.18, 0.14)
const PANOT_SHINE := Color(0.96, 0.97, 1.0, 0.10)

const GRASS_BASE := Color(0.24, 0.40, 0.22)
const GRASS_LIT := Color(0.31, 0.49, 0.27)
const SAGE := Color(0.35, 0.46, 0.34)
const LAVENDER := Color(0.55, 0.43, 0.73)
const LAVENDER_LIT := Color(0.70, 0.58, 0.85)
const ORANGE_FRUIT := Color(0.94, 0.52, 0.14)
const ORANGE_LEAF := Color(0.23, 0.45, 0.21)

const BRICK := Color(0.68, 0.31, 0.22)
const BRICK_LIT := Color(0.78, 0.40, 0.29)
const BRICK_DARK := Color(0.47, 0.20, 0.15)
const LIMESTONE := Color(0.88, 0.84, 0.75)
const LIMESTONE_DARK := Color(0.68, 0.64, 0.56)
const ROOF_CLAY := Color(0.63, 0.31, 0.21)
const ROOF_CLAY_LIT := Color(0.73, 0.38, 0.26)
const TILE_TURQUOISE := Color(0.14, 0.62, 0.58)
const TILE_TURQUOISE_LIT := Color(0.26, 0.76, 0.70)
const TILE_SAFFRON := Color(0.95, 0.68, 0.16)
const TILE_MAGENTA := Color(0.76, 0.25, 0.44)
const TILE_CREAM := Color(0.95, 0.91, 0.82)
const IRON := Color(0.16, 0.17, 0.20)
const WATER := Color(0.20, 0.52, 0.64)
const WATER_LIT := Color(0.34, 0.68, 0.78)
const CLOCK_FACE := Color(0.98, 0.94, 0.80)
const CLOCK_GLOW := Color(1.0, 0.84, 0.44)

const UMBRELLA_A := Color(0.96, 0.68, 0.16)
const UMBRELLA_B := Color(0.84, 0.24, 0.46)
const GUIDE_SHIRT := Color(0.16, 0.40, 0.56)
const UNIFORM := Color(0.18, 0.24, 0.38)
const PACK_COLS: Array[Color] = [
	Color(0.95, 0.68, 0.16), Color(0.16, 0.70, 0.64),
	Color(0.88, 0.28, 0.48), Color(0.55, 0.78, 0.28),
]
const HAIR_COLS: Array[Color] = [
	Color(0.20, 0.14, 0.10), Color(0.52, 0.34, 0.18),
	Color(0.12, 0.10, 0.10), Color(0.78, 0.60, 0.34),
]
const PASTRY := Color(0.90, 0.68, 0.34)


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


# --- shape & solids -----------------------------------------------------------

static func edge_nodes(_m: Node2D = null) -> Array:
	return [
		{"y": START, "cx": CX, "half": 330.0},
		{"y": -200.0, "cx": CX, "half": 330.0},
		{"y": -340.0, "cx": CX, "half": HALF},
		{"y": -4680.0, "cx": CX, "half": HALF},
		{"y": -4840.0, "cx": CX, "half": 260.0},
		{"y": GATE, "cx": CX, "half": 260.0},
	]


static func solids(_m: Node2D = null) -> Array[Rect2]:
	return PAVILIONS.duplicate()


static func wrap_rects() -> Array[Rect2]:
	return PAVILIONS.duplicate()


static func _is_orange_tree(p: Vector2) -> bool:
	for tp: Vector2 in ORANGE_TREES:
		if p.distance_squared_to(tp) < 4.0:
			return true
	return false


static func _is_lamp_pos(p: Vector2) -> bool:
	for lp: Vector2 in LAMPS:
		if p.distance_squared_to(lp) < 4.0:
			return true
	return false


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_orange_tree(p):
		return m.TREE_PIT
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_lamp_pos(p)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		for bed: Rect2 in COURTYARD_BEDS:
			if bed.has_point(p):
				return Surfaces.S.GRASS
		return Surfaces.S.PAVEMENT
	for bed: Rect2 in GARDEN_BEDS:
		if bed.has_point(p):
			return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT


# --- tour event class ---------------------------------------------------------

class SchoolTour:
	extends RefCounted
	enum State { IDLE, TELEGRAPH, CROSSING, GONE }

	var state: State = State.IDLE
	var timer := 0.0
	var lead_x := TOUR_START_X
	var walk_t := 0.0
	var human_hit := false
	var booped := false
	var cheered := false
	var cheer_t := 0.0
	var dodged := false
	var threatened := false
	var snack_dropped := false
	var snack_taken := false
	var snack_pos := Vector2.ZERO

	func member_pos(k: int) -> Vector2:
		var x := lead_x - float(k) * TOUR_GAP
		var y := TOUR_CROSS_Y + sin(walk_t * 2.4 + float(k) * 1.5) * TOUR_SWAY * (0.0 if k == 0 else 1.0) \
			+ (float(k % 2) - 0.5) * 18.0 * (0.0 if k == 0 else 1.0)
		return Vector2(x, y)

	func active() -> bool:
		return state == State.CROSSING

	func tick(m: Node2D, delta: float) -> void:
		var dog_p: Vector2 = m.dog.global_position
		var human_p: Vector2 = m.human.global_position
		cheer_t = maxf(0.0, cheer_t - delta)
		if snack_dropped and not snack_taken and dog_p.distance_to(snack_pos) < TOUR_SNATCH_R:
			snack_taken = true
			m.kebabs_eaten += 1
			m.award_points(2, "brioche! +2")
			Santpau._sfx(m, "snack", 1.1)

		match state:
			State.IDLE:
				if m.phase == "out" and human_p.y < TOUR_TRIGGER_Y and human_p.y > TOUR_CROSS_Y - 300.0:
					state = State.TELEGRAPH
					timer = TOUR_WARN
					m.santpau_chime_t = CLOCK_CHIME_T
					m.santpau_chime_out = true
					m.float_text(CLOCK_TOWER_POS + Vector2(0.0, -34.0), "DONG! DONG!", CLOCK_GLOW)
					m.float_text(Vector2(TOUR_START_X + 60.0, TOUR_CROSS_Y - 52.0), "Two by two! Follow the umbrella!", Color(0.98, 0.92, 0.80), m.POP_SAY)
					m.feed.say("BELLS CHIMING! SCHOOL TOUR CROSSING", EventFeed.Tone.LOUD)
					Santpau._sfx(m, "church_bell", 1.12)
			State.TELEGRAPH:
				timer -= delta
				if timer <= 0.0:
					state = State.CROSSING
					Santpau._sfx(m, "church_bell", 1.12)
			State.CROSSING:
				walk_t += delta
				lead_x += TOUR_SPEED * delta
				var last := member_pos(TOUR_COUNT)
				if not snack_dropped and last.x > CX:
					snack_dropped = true
					snack_pos = last + Vector2(-8.0, 20.0)
				if not human_hit:
					for k in range(TOUR_COUNT + 1):
						if human_p.distance_to(member_pos(k)) < TOUR_BUMP_R:
							human_hit = true
							m.human.bumped((human_p - member_pos(k)).normalized())
							m.human.lose_patience(TOUR_PATIENCE_COST)
							m.float_text(human_p + Vector2(0.0, -34.0), "Excuse me, kids!", Color(1.0, 0.65, 0.55), m.POP_SAY)
							m.float_text(member_pos(0) + Vector2(0.0, -32.0), "Careful, everyone!", Color(0.98, 0.92, 0.80), m.POP_SAY)
							Santpau._sfx(m, "grunt", 0.95)
							break
				if not booped and dog_p.distance_to(member_pos(0)) < TOUR_BOOP_R:
					booped = true
					m.award_points(2, "guide boop! +2")
					m.float_text(member_pos(0) + Vector2(0.0, -40.0), "Careful, pup, you'll join the tour!", Color(0.98, 0.92, 0.80), m.POP_SAY)
					Santpau._sfx(m, "whoop", 1.2)
				if member_pos(TOUR_COUNT).x > TOUR_END_X:
					state = State.GONE
			State.GONE:
				pass

		if state == State.CROSSING or state == State.GONE:
			var close := false
			if state == State.CROSSING:
				for k in range(TOUR_COUNT + 1):
					if human_p.distance_to(member_pos(k)) < TOUR_THREAT_R:
						close = true
						break
			var step: Dictionary = NearMiss.consider(close, human_hit, threatened, dodged)
			threatened = bool(step["threatened"])
			if bool(step["dodge"]):
				dodged = true
				m.saves_done += 1
				m.award_points(2, "cleared the class! +2")
				Santpau._sfx(m, "save", 1.0)

	func on_bark(m: Node2D, pos: Vector2) -> bool:
		if cheered or (state != State.CROSSING and state != State.TELEGRAPH):
			return false
		for k in range(TOUR_COUNT + 1):
			if pos.distance_to(member_pos(k)) < TOUR_BARK_R:
				cheered = true
				cheer_t = 1.6
				m.combo.add("SCHOOL CHEER", 3)
				m.award_points(3, "class cheered! +3")
				m.float_text(member_pos(2) + Vector2(0.0, -36.0), "Look, a puppy!!", Color(0.98, 0.94, 0.78), m.POP_SAY)
				Santpau._sfx(m, "whoop", 1.25)
				return true
		return false

	func draw(b: ShapeBatch, vt: float, vb: float, dog_p: Vector2) -> void:
		if TOUR_CROSS_Y + 90.0 < vt or TOUR_CROSS_Y - 90.0 > vb:
			return
		if snack_dropped and not snack_taken:
			b.circle(snack_pos + Vector2(2.0, 2.0), 6.0, SHADOW)
			b.circle(snack_pos, 6.0, PASTRY.darkened(0.18))
			b.circle(snack_pos, 4.5, PASTRY)
			b.circle(snack_pos + Vector2(-1.2, -1.2), 1.6, Color(0.98, 0.94, 0.84))
		if state == State.IDLE or state == State.GONE:
			return
		for k in range(TOUR_COUNT, -1, -1):
			var p := member_pos(k)
			b.circle(p + Vector2(3.5, 5.0), 9.0 if k == 0 else 7.2, SHADOW)
			if k == 0:
				b.circle(p, 10.0, GUIDE_SHIRT)
				b.circle(p + Vector2(1.0, 0.0), 6.0, Color(0.28, 0.18, 0.12))
				# Raised colourful umbrella held aloft so the class can follow
				var u := p + Vector2(10.0, -8.0)
				b.line(p + Vector2(4.0, -2.0), u, IRON, 2.0)
				for i in range(8):
					var a := TAU * float(i) / 8.0 + walk_t * 0.5
					b.quad(u, u + Vector2.from_angle(a) * 11.5,
						u + Vector2.from_angle(a + TAU / 16.0) * 13.0,
						u + Vector2.from_angle(a + TAU / 8.0) * 11.5,
						UMBRELLA_A if i % 2 == 0 else UMBRELLA_B)
				b.circle(u, 1.8, IRON)
				continue
			var pack: Color = PACK_COLS[k % PACK_COLS.size()]
			var hair: Color = HAIR_COLS[(k * 3) % HAIR_COLS.size()]
			b.rect(Rect2(p + Vector2(-8.0, -4.0), Vector2(5.0, 8.0)), pack)
			b.circle(p, 7.2, UNIFORM)
			b.circle(p + Vector2(1.0, 0.0), 4.8, hair)
			if cheer_t > 0.0:
				var to_dog := (dog_p - p).normalized()
				var wave := sin(cheer_t * 14.0 + float(k)) * 3.0
				b.line(p, p + to_dog * 10.0 + to_dog.orthogonal() * wave, Color(0.92, 0.76, 0.62), 2.2)


# --- build -------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "JARDINS DE SANT PAU"
	m.gate_l = 440.0
	m.gate_r = 840.0

	m.santpau_tour = SchoolTour.new()
	m.santpau_chime_t = 0.0
	m.santpau_chime_out = false
	m.santpau_chime_home = false
	m.santpau_chime_howled = false
	m.santpau_beds_visited = {}
	m.santpau_sitters = []
	m.santpau_sketchers = []

	for tp: Vector2 in ORANGE_TREES:
		m.poles.append(tp)
	for lp: Vector2 in LAMPS:
		m.poles.append(lp)
	m.deco_pole_count = m.poles.size()

	# Grindable low limestone kerbs along the inner edge of the garden beds
	for bed: Rect2 in GARDEN_BEDS:
		var gx := bed.end.x + 2.0 if bed.position.x < CX else bed.position.x - 2.0
		m.rails.append({"pts": PackedVector2Array([Vector2(gx, bed.position.y + 8.0), Vector2(gx, bed.end.y - 8.0)])})

	m.benches = Array(BENCH_SPOTS, TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(544.0, -320.0), Vector2(736.0, -1120.0),
		Vector2(544.0, -2110.0), Vector2(736.0, -3300.0),
		Vector2(544.0, -4360.0),
	], TYPE_VECTOR2, &"", null)
	if "fountains" in m:
		m.fountains = Array([FOUNTAIN_AXIS], TYPE_VECTOR2, &"", null)

	# Outdoor visitors seated on benches & sketching the pavilions per Outdoors rules
	var weather: String = Game.weather
	var hour: String = Game.hour
	var sit_share: float = Outdoors.garden_sitters(weather, hour)
	for i in range(BENCH_SPOTS.size()):
		if _h(i * 19 + 7) < sit_share:
			var bp: Vector2 = BENCH_SPOTS[i]
			var face := Vector2.RIGHT if bp.x < CX else Vector2.LEFT
			m.santpau_sitters.append({"pos": bp + Vector2(0.0, -6.0), "face": face, "key": 3800 + i * 13})

	var sketch_pos: Array[Vector2] = []
	if Outdoors.sketchers_out(weather, hour):
		for sk: Dictionary in SKETCHER_SPOTS:
			var sp: Vector2 = sk["pos"]
			sketch_pos.append(sp)
			m.santpau_sketchers.append(sk)
	m.performers = Array(sketch_pos, TYPE_VECTOR2, &"", null)

	var hyd_list: Array[Vector2] = [
		Vector2(544.0, -240.0), Vector2(736.0, -760.0),
		Vector2(544.0, -1490.0), Vector2(736.0, -2450.0),
		Vector2(544.0, -3270.0), Vector2(736.0, -4230.0),
	]
	var keb_list: Array[Vector2] = [
		Vector2(610.0, -900.0), Vector2(675.0, -1720.0),
		Vector2(605.0, -2780.0), Vector2(665.0, -3840.0),
	]
	return [hyd_list, keb_list]


# --- per frame ----------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	if m.santpau_chime_t > 0.0:
		m.santpau_chime_t = maxf(0.0, float(m.santpau_chime_t) - delta)
	if m.phase == "home" and not m.santpau_chime_home and float(m.human.global_position.y) > HOME_CHIME_Y and float(m.human.global_position.y) < HOME_CHIME_Y + 120.0:
		m.santpau_chime_home = true
		m.santpau_chime_t = CLOCK_CHIME_T
		m.float_text(CLOCK_TOWER_POS + Vector2(0.0, -34.0), "DONG!", CLOCK_GLOW)
		_sfx(m, "church_bell", 1.0)
	if m.santpau_tour != null:
		m.santpau_tour.tick(m, delta)
	# Track lavender garden beds visited along the walk
	var dog_p: Vector2 = m.dog.global_position
	for i in range(GARDEN_BEDS.size()):
		if GARDEN_BEDS[i].has_point(dog_p) and not m.santpau_beds_visited.has(i):
			m.santpau_beds_visited[i] = true
			if m.santpau_beds_visited.size() <= 3:
				m.award_points(1, "lavender! +1")


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = m.dog.global_position if pos == Vector2.ZERO else pos
	var handled := false
	if float(m.santpau_chime_t) > 0.0 and not m.santpau_chime_howled and p.distance_to(CLOCK_TOWER_POS) <= CLOCK_CHIME_R:
		m.santpau_chime_howled = true
		m.combo.add("CHIME HOWL", 3)
		m.award_points(3, "chimed in! +3")
		m.float_text(p + Vector2(0.0, -28.0), "Awooo!", Color(0.98, 0.92, 0.72), m.POP_SAY)
		handled = true
	if m.santpau_tour != null and m.santpau_tour.on_bark(m, p):
		handled = true
	return handled


static func _sfx(m: Node2D, name: String, pitch: float) -> void:
	var sfx: Node = m.get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play(name, pitch, -4.0)


# --- ground pass (cached by ground_layer) -------------------------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo: float = maxf(vt - 40.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi: float = minf(vb + 40.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_draw_ground(wc, lo, hi)
	wc.lod = keep_lod


static func _corridor_poly(lo: float, hi: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var ys: Array[float] = [hi]
	for yy: float in [-200.0, -340.0, -4680.0, -4840.0]:
		if yy < hi and yy > lo:
			ys.append(yy)
	ys.append(lo)
	ys.sort()
	ys.reverse()
	for yy: float in ys:
		var h := _half_at(yy)
		left.append(Vector2(CX - h, yy))
		right.append(Vector2(CX + h, yy))
	var out := PackedVector2Array()
	for i in range(ys.size()):
		out.append(left[i])
	for i in range(ys.size() - 1, -1, -1):
		out.append(right[i])
	return out


static func _half_at(y: float) -> float:
	if y >= -200.0:
		return 330.0
	if y >= -340.0:
		return lerpf(HALF, 330.0, (y + 340.0) / 140.0)
	if y >= -4680.0:
		return HALF
	if y >= -4840.0:
		return lerpf(260.0, HALF, (y + 4840.0) / 160.0)
	return 260.0


static func _draw_ground(wc: ShapeBatch, lo: float, hi: float) -> void:
	# Base warm stone paving across the precinct
	wc.polygon(_corridor_poly(lo, hi), STONE_PAVE)

	# Avinguda de Gaudí entrance esplanade (y >= -260): Gaudí hexagonal panots on the flanks
	if hi > -260.0:
		var e_lo := maxf(lo, -260.0)
		var e_hi := hi
		wc.rect(Rect2(CX - 330.0, e_lo, 220.0, e_hi - e_lo), PANOT_BASE)
		wc.rect(Rect2(CX + 110.0, e_lo, 220.0, e_hi - e_lo), PANOT_BASE)
		Panot.gaudi(wc, func(y: float) -> Vector2:
			return Vector2(CX - _half_at(y) + 4.0, CX - 114.0), e_lo, e_hi, PANOT_INK, PANOT_SHINE)
		Panot.gaudi(wc, func(y: float) -> Vector2:
			return Vector2(CX + 114.0, CX + _half_at(y) - 4.0), e_lo, e_hi, PANOT_INK, PANOT_SHINE)

	# Central stone promenade (x = 556..724) with ashlar joints and subtle panot edge bands
	var pl := 556.0
	var pr := 724.0
	wc.rect(Rect2(pl, lo, pr - pl, hi - lo), STONE_LIT)
	wc.rect(Rect2(pl - 4.0, lo, 4.0, hi - lo), KERB_STONE)
	wc.rect(Rect2(pr, lo, 4.0, hi - lo), KERB_STONE)
	var row := int(floorf(lo / 64.0))
	var sy := float(row) * 64.0
	while sy < hi:
		wc.line(Vector2(pl, sy), Vector2(pr, sy), STONE_JOINT, 1.2)
		var off := 0.0 if row % 2 == 0 else 42.0
		var sx := pl + off + 42.0
		while sx < pr - 2.0:
			wc.line(Vector2(sx, sy), Vector2(sx, sy + 64.0), STONE_JOINT, 1.0)
			sx += 84.0
		row += 1
		sy += 64.0

	# Garden beds: carved stone kerbs, grass turf, lavender rows, and fallen bitter oranges
	for i in range(GARDEN_BEDS.size()):
		var bed: Rect2 = GARDEN_BEDS[i]
		if bed.end.y < lo - 20.0 or bed.position.y > hi + 20.0:
			continue
		_draw_garden_bed(wc, bed, i)

	# Cast shadows & stone plinth steps beneath each solid pavilion
	for r: Rect2 in PAVILIONS:
		if r.end.y < lo - 40.0 or r.position.y > hi + 40.0:
			continue
		wc.rect(Rect2(r.position + SUN * 14.0, r.size), SHADOW)
		wc.rect(r.grow(5.0), LIMESTONE_DARK)

	# Scattered fallen oranges under the garden orange trees
	for tp: Vector2 in ORANGE_TREES:
		if tp.y < lo - 30.0 or tp.y > hi + 30.0:
			continue
		for k in range(3):
			var a := _h(int(absf(tp.y)) + k * 13) * TAU
			var d := 11.0 + _h(int(absf(tp.y)) + k * 7) * 9.0
			var op := tp + Vector2.from_angle(a) * d
			wc.circle(op + Vector2(1.0, 1.2), 2.8, SHADOW)
			wc.circle(op, 2.6, ORANGE_FRUIT)


static func _draw_garden_bed(b: ShapeBatch, bed: Rect2, idx: int) -> void:
	b.rect(bed.grow(4.0), KERB_STONE)
	b.rect(bed, GRASS_BASE)
	b.rect(bed.grow(-6.0), GRASS_LIT)
	# Neat rows of lavender along the outer and inner garden edges
	var ly := bed.position.y + 18.0
	var row := 0
	while ly < bed.end.y - 14.0:
		for lx: float in [bed.position.x + 16.0, bed.end.x - 16.0]:
			var lp := Vector2(lx, ly)
			b.circle(lp, 9.0, SAGE)
			for k in range(3):
				var off := Vector2.from_angle(float(k + row + idx) * 2.1) * 3.4
				b.circle(lp + off, 3.2, LAVENDER if (k + row) % 2 == 0 else LAVENDER_LIT)
		ly += 34.0
		row += 1


# --- outer campus wings (cached by edge_layer) -------------------------------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 280.0, GATE - 40.0)
	var hi := minf(vb + 280.0, START + 560.0)
	if hi > lo:
		_draw_outer_grounds(b, lo, hi)
	b.lod = keep_lod


static func _draw_outer_grounds(b: ShapeBatch, lo: float, hi: float) -> void:
	# Outer hospital precinct lawns across full width (ground_layer draws the walk polygon on top,
	# including the narrowing gate neck above -4680 so no void shows on either flank)
	b.rect(Rect2(-460.0, lo, 2220.0, hi - lo), Color(0.20, 0.32, 0.19))
	# Brick flanking terraces bridging the gate neck (-5000..-4680) to the courtyard wall
	var neck_lo := maxf(lo, -5000.0)
	var neck_hi := minf(hi, -4680.0)
	if neck_hi > neck_lo:
		b.rect(Rect2(WALL_L, neck_lo, 110.0, neck_hi - neck_lo), BRICK_DARK)
		b.rect(Rect2(WALL_L + 8.0, neck_lo, 94.0, neck_hi - neck_lo), ROOF_CLAY)
		b.rect(Rect2(900.0, neck_lo, 110.0, neck_hi - neck_lo), BRICK_DARK)
		b.rect(Rect2(908.0, neck_lo, 94.0, neck_hi - neck_lo), ROOF_CLAY)
	# Red-brick campus boundary walls & terracotta coping
	for side: float in [-1.0, 1.0]:
		var wx := WALL_L if side < 0.0 else WALL_R
		var x0 := (wx - 18.0) if side < 0.0 else wx
		b.rect(Rect2(x0, lo, 18.0, hi - lo), BRICK_DARK)
		b.rect(Rect2(x0 + 4.0, lo, 10.0, hi - lo), ROOF_CLAY)
		# Outer side-pavilion terracotta roof blocks outside the perimeter
		var ry := floorf(lo / 320.0) * 320.0
		var k := 0
		while ry < hi:
			var bx := (wx - 240.0) if side < 0.0 else (wx + 36.0)
			var br := Rect2(bx, ry + 24.0, 204.0, 250.0)
			b.rect(Rect2(br.position + SUN * 10.0, br.size), SHADOW)
			b.rect(br, ROOF_CLAY if k % 2 == 0 else BRICK)
			b.rect(br.grow(-16.0), ROOF_CLAY_LIT)
			b.line(Vector2(br.get_center().x, br.position.y + 12.0), Vector2(br.get_center().x, br.end.y - 12.0), TILE_SAFFRON, 4.0)
			ry += 320.0
			k += 1


# --- static overhead architecture: pavilion roofs, glazed domes, turrets, clock tower ---

static func draw_overhead(_m: Node2D, ci: CanvasItem) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	for i in range(PAVILIONS.size()):
		var r: Rect2 = PAVILIONS[i]
		if i < 2:
			_draw_gate_lodge(b, r, i == 0)
		elif i >= 8:
			_draw_admin_wing(b, r, i == 8)
		else:
			_draw_pavilion(b, r, i)
	# Slender open wrought-iron arch over the Avinguda de Gaudí entrance
	_draw_entry_arch(b)
	# Administration Clock Tower rising on ADMIN_W's inner corner
	_draw_clock_tower(b, CLOCK_TOWER_POS)
	b.flush()


static func _draw_gate_lodge(b: ShapeBatch, r: Rect2, west: bool) -> void:
	b.rect(r, BRICK)
	b.rect(r.grow(-5.0), LIMESTONE)
	b.rect(r.grow(-9.0), ROOF_CLAY)
	# Steep pyramidal turquoise-and-saffron glazed roof
	var c := r.get_center()
	var inner := r.grow(-12.0)
	b.quad(inner.position, Vector2(inner.end.x, inner.position.y), c, Vector2(inner.position.x, inner.end.y), ROOF_CLAY_LIT)
	b.quad(Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y), c, ROOF_CLAY.darkened(0.14))
	_draw_dome(b, c, 24.0, true)
	# Corner turret on the central-axis corner
	var tx := (r.end.x - 14.0) if west else (r.position.x + 14.0)
	_draw_turret(b, Vector2(tx, r.position.y + 16.0), 15.0)


static func _draw_entry_arch(b: ShapeBatch) -> void:
	var y := -335.0
	b.line(Vector2(430.0, y), Vector2(850.0, y), IRON, 5.0)
	b.line(Vector2(430.0, y - 5.0), Vector2(850.0, y - 5.0), TILE_SAFFRON, 2.0)
	for k in range(7):
		var lx := lerpf(470.0, 810.0, float(k) / 6.0)
		b.circle(Vector2(lx, y - 2.0), 4.5, IRON)
		b.circle(Vector2(lx, y - 2.0), 2.5, TILE_TURQUOISE)


static func _draw_pavilion(b: ShapeBatch, r: Rect2, idx: int) -> void:
	# Red-brick walls with limestone cornice & pitched terracotta roof
	b.rect(r, BRICK)
	b.rect(r.grow(-5.0), LIMESTONE)
	var roof := r.grow(-9.0)
	var mid_x := roof.get_center().x
	b.rect(Rect2(roof.position.x, roof.position.y, roof.size.x * 0.5, roof.size.y), ROOF_CLAY_LIT)
	b.rect(Rect2(mid_x, roof.position.y, roof.size.x * 0.5, roof.size.y), ROOF_CLAY)
	# Roof tile courses
	var ty := roof.position.y + 16.0
	while ty < roof.end.y - 12.0:
		b.line(Vector2(roof.position.x + 4.0, ty), Vector2(roof.end.x - 4.0, ty), BRICK_DARK, 1.4)
		ty += 18.0
	# Glazed saffron ceramic ridge cresting
	b.line(Vector2(mid_x, roof.position.y + 6.0), Vector2(mid_x, roof.end.y - 6.0), TILE_SAFFRON, 5.0)
	b.line(Vector2(mid_x, roof.position.y + 6.0), Vector2(mid_x, roof.end.y - 6.0), TILE_CREAM, 1.8)

	# Central glazed-tile Modernista ward dome
	_draw_dome(b, r.get_center(), 36.0, idx % 2 == 0)

	# Corner turrets facing the central garden axis
	var west := r.get_center().x < CX
	var ix := (r.end.x - 16.0) if west else (r.position.x + 16.0)
	_draw_turret(b, Vector2(ix, r.position.y + 22.0), 18.0)
	_draw_turret(b, Vector2(ix, r.end.y - 22.0), 18.0)


static func _draw_admin_wing(b: ShapeBatch, r: Rect2, west: bool) -> void:
	b.rect(r, BRICK)
	b.rect(r.grow(-6.0), LIMESTONE)
	var roof := r.grow(-11.0)
	b.rect(roof, ROOF_CLAY)
	b.rect(Rect2(roof.position.x, roof.position.y, roof.size.x * 0.52, roof.size.y), ROOF_CLAY_LIT)
	# Trencadis cornice band along the south garden-facing eaves
	var ey := roof.end.y - 8.0
	var sx := roof.position.x + 8.0
	var k := 0
	while sx < roof.end.x - 12.0:
		var tc := TILE_TURQUOISE if k % 3 == 0 else (TILE_SAFFRON if k % 3 == 1 else TILE_MAGENTA)
		b.rect(Rect2(sx, ey, 14.0, 6.0), tc)
		sx += 16.0
		k += 1
	b.line(Vector2(roof.position.x + 8.0, roof.get_center().y), Vector2(roof.end.x - 8.0, roof.get_center().y), TILE_SAFFRON, 5.0)
	_draw_dome(b, r.get_center() + Vector2(-18.0 if west else 18.0, 0.0), 38.0, west)
	var ox := (r.position.x + 22.0) if west else (r.end.x - 22.0)
	_draw_turret(b, Vector2(ox, r.end.y - 24.0), 20.0)


static func _draw_dome(b: ShapeBatch, c: Vector2, rad: float, turquoise_lead: bool) -> void:
	b.circle(c + SUN * 5.0, rad, SHADOW)
	b.circle(c, rad, LIMESTONE)
	b.circle(c, rad - 4.0, BRICK_DARK)
	var primary := TILE_TURQUOISE if turquoise_lead else TILE_MAGENTA
	var accent := TILE_SAFFRON if turquoise_lead else TILE_TURQUOISE
	b.circle(c, rad - 7.0, primary)
	b.circle(c - SUN * 4.0, rad - 13.0, primary.lightened(0.18))
	b.circle(c, rad * 0.45, accent)
	for i in range(8):
		var a := float(i) * TAU / 8.0
		b.line(c + Vector2.from_angle(a) * 4.0, c + Vector2.from_angle(a) * (rad - 6.0), TILE_CREAM, 1.8)
	b.circle(c, 5.5, TILE_SAFFRON)
	b.circle(c - Vector2(1.2, 1.2), 2.5, TILE_CREAM)


static func _draw_turret(b: ShapeBatch, c: Vector2, rad: float) -> void:
	b.circle(c + SUN * 4.0, rad, SHADOW)
	b.circle(c, rad, LIMESTONE)
	b.circle(c, rad - 3.0, TILE_TURQUOISE)
	b.circle(c - SUN * 2.5, rad - 7.0, TILE_TURQUOISE_LIT)
	for i in range(6):
		var a := float(i) * TAU / 6.0
		b.line(c, c + Vector2.from_angle(a) * (rad - 3.0), TILE_SAFFRON, 1.4)
	b.circle(c, 3.6, TILE_SAFFRON)


static func _draw_clock_tower(b: ShapeBatch, c: Vector2) -> void:
	var half := 36.0
	var base := Rect2(c - Vector2(half, half), Vector2(half * 2.0, half * 2.0))
	b.rect(Rect2(base.position + SUN * 10.0, base.size), SHADOW)
	b.rect(base, LIMESTONE)
	b.rect(base.grow(-5.0), BRICK)
	# Four-sided glazed turquoise pyramidal spire
	var spire := base.grow(-9.0)
	b.quad(spire.position, Vector2(spire.end.x, spire.position.y), c, Vector2(spire.position.x, spire.end.y), TILE_TURQUOISE_LIT)
	b.quad(Vector2(spire.end.x, spire.position.y), spire.end, Vector2(spire.position.x, spire.end.y), c, TILE_TURQUOISE)
	b.line(spire.position, spire.end, TILE_SAFFRON, 2.2)
	b.line(Vector2(spire.end.x, spire.position.y), Vector2(spire.position.x, spire.end.y), TILE_SAFFRON, 2.2)
	# Illuminated clock face facing south along the central garden axis
	var dial := c + Vector2(0.0, half - 4.0)
	b.circle(dial, 11.0, LIMESTONE)
	b.circle(dial, 8.5, CLOCK_FACE)
	b.line(dial, dial + Vector2(0.0, -5.5), IRON, 1.8)
	b.line(dial, dial + Vector2(4.2, 1.5), IRON, 1.4)
	b.circle(c, 5.0, TILE_SAFFRON)


# --- live pass, furniture & night lighting ------------------------------------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# Clock tower golden chime rings while striking
	if float(m.santpau_chime_t) > 0.0 and CLOCK_TOWER_POS.y + 180.0 >= vt and CLOCK_TOWER_POS.y - 180.0 <= vb:
		var pulse := fmod(float(m.santpau_chime_t) * 1.6, 1.0)
		var ring_r := 30.0 + (1.0 - pulse) * 90.0
		b.circle(CLOCK_TOWER_POS, ring_r, Color(CLOCK_GLOW.r, CLOCK_GLOW.g, CLOCK_GLOW.b, 0.16 * pulse))
		b.circle(CLOCK_TOWER_POS, 24.0, Color(CLOCK_GLOW.r, CLOCK_GLOW.g, CLOCK_GLOW.b, 0.35 * pulse))

	# Garden visitors sitting on benches
	for s: Dictionary in m.santpau_sitters:
		var sp: Vector2 = s["pos"]
		if sp.y < vt - 40.0 or sp.y > vb + 40.0:
			continue
		NpcFigure.person(b, sp, s["face"], int(s["key"]), -1.0, {"arms": NpcFigure.Arms.SIDE})

	# Unique walk prize: candied orange on the garden bench table
	if not bool(m.prize_taken) and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		b.glow(PRIZE, 20.0, Color(1.0, 0.86, 0.45, 0.25))
		b.circle(PRIZE + Vector2(1.5, 2.0), 7.5, SHADOW)
		b.circle(PRIZE, 7.5, TILE_CREAM)
		b.circle(PRIZE, 5.0, ORANGE_FRUIT)
		b.circle(PRIZE - Vector2(1.4, 1.4), 1.8, TILE_SAFFRON)

	# School tour live event
	if m.santpau_tour != null:
		m.santpau_tour.draw(b, vt, vb, m.dog.global_position)


static func draw_performer(m: Node2D, wc: ShapeBatch, pf: Vector2, idx: int) -> void:
	if idx >= m.santpau_sketchers.size():
		return
	if pf.y < m.view_lo(60.0) or pf.y > m.view_hi(60.0):
		return
	var sk: Dictionary = m.santpau_sketchers[idx]
	var face: Vector2 = sk["face"]
	NpcFigure.person(wc, pf, face, int(sk["key"]), -1.0, {"arms": NpcFigure.Arms.READY})
	# Sketchpad held toward the pavilion
	var pad := pf + face * 10.0
	wc.rect(Rect2(pad - Vector2(5.0, 4.0), Vector2(10.0, 8.0)), TILE_CREAM)


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_lamp_pos(p):
		m._draw_lamppost(p)
	else:
		m._draw_pilona(wc, p, false)


static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	# Warm stained-glass doorway & window glow spilling from the pavilions onto the stone paths
	var out: Array[Dictionary] = []
	for i in range(PAVILIONS.size()):
		var r: Rect2 = PAVILIONS[i]
		var west := r.get_center().x < CX
		var door_x := r.end.x if west else r.position.x
		var dir := 1.0 if west else -1.0
		out.append(NightFronts.front(Vector2(door_x, r.get_center().y), dir, "home", 3710 + i))
		if r.size.y >= 260.0:
			out.append(NightFronts.front(Vector2(door_x, r.get_center().y - 90.0), dir, "shop", 3730 + i))
	return out


# --- off-leash garden courtyard: JARDINS DE SANT PAU --------------------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect() if m.has_method("_freedom_rect") else Rect2(70.0, -5620.0, 1110.0, 590.0)
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else GATE
	var b := ShapeBatch.new()

	# Outer hospital roofs & brick cloister surround beyond the courtyard (stop at r.end.y
	# so the approach corridor below the gate meets the walk seamlessly without a brown band)
	var cloister_lo := gate_y - 2400.0
	b.rect(Rect2(-420.0, cloister_lo, 2140.0, r.end.y - cloister_lo), Color(0.24, 0.16, 0.15))
	b.rect(Rect2(-420.0, r.end.y, 2140.0, gate_y - r.end.y + 4.0), Color(0.20, 0.32, 0.19))
	var ry := r.position.y - 320.0
	while ry < r.end.y + 40.0:
		b.rect(Rect2(-400.0, ry, r.position.x + 380.0, 62.0), ROOF_CLAY)
		b.rect(Rect2(r.end.x + 20.0, ry, 1680.0 - r.end.x, 62.0), ROOF_CLAY)
		if ry < r.position.y - 24.0:
			b.rect(Rect2(-400.0, ry, 2100.0, 62.0), ROOF_CLAY)
			b.line(Vector2(-400.0, ry + 31.0), Vector2(1700.0, ry + 31.0), TILE_SAFFRON, 2.5)
		ry += 78.0

	# Stone courtyard paving base & continuous gate threshold
	var gl: float = float(m.gate_l) if "gate_l" in m else 440.0
	var gr: float = float(m.gate_r) if "gate_r" in m else 840.0
	b.rect(Rect2(gl - 16.0, r.end.y - 8.0, gr - gl + 32.0, gate_y - r.end.y + 12.0), STONE_PAVE)
	b.rect(Rect2(556.0, r.end.y - 8.0, 168.0, gate_y - r.end.y + 12.0), STONE_LIT)
	b.rect(r, STONE_PAVE)
	b.rect(Rect2(490.0, r.position.y, 300.0, r.size.y), STONE_LIT)
	b.rect(Rect2(r.position.x, -5405.0, r.size.x, 90.0), STONE_LIT)

	# Four lush grass, lavender & orange-tree quadrant beds (matching COURTYARD_BEDS)
	for bed: Rect2 in COURTYARD_BEDS:
		_draw_garden_bed(b, bed, 10)
		var mid := bed.get_center()
		for dx: float in [-85.0, 85.0]:
			var tp := Vector2(mid.x + dx, mid.y)
			b.circle(tp + SUN * 5.0, 19.0, SHADOW)
			b.circle(tp, 18.0, ORANGE_LEAF.darkened(0.18))
			b.circle(tp - SUN * 2.5, 13.0, ORANGE_LEAF)
			b.circle(tp + Vector2(-4.0, -3.0), 2.8, ORANGE_FRUIT)
			b.circle(tp + Vector2(5.0, 2.5), 2.6, ORANGE_FRUIT)
			b.circle(tp + Vector2(1.5, -6.0), 2.4, ORANGE_FRUIT)

	# Central octagonal Modernista tiled garden fountain
	var fp := COURTYARD_FOUNTAIN
	b.circle(fp + SUN * 6.0, 44.0, SHADOW)
	b.circle(fp, 42.0, LIMESTONE)
	b.circle(fp, 36.0, TILE_TURQUOISE)
	b.circle(fp, 30.0, WATER)
	b.circle(fp - SUN * 3.0, 18.0, WATER_LIT)
	b.circle(fp, 9.0, LIMESTONE)
	b.circle(fp, 5.0, TILE_SAFFRON)

	# Brick-and-limestone courtyard perimeter walls
	var ww := 20.0
	b.rect(Rect2(r.position.x - ww, r.position.y - ww, r.size.x + ww * 2.0, ww), BRICK)
	b.rect(Rect2(r.position.x - ww, r.position.y, ww, r.size.y), BRICK)
	b.rect(Rect2(r.end.x, r.position.y, ww, r.size.y), BRICK)
	b.rect(Rect2(r.position.x - ww, r.end.y - 8.0, gl - r.position.x + ww - 16.0, 14.0), BRICK)
	b.rect(Rect2(gr + 16.0, r.end.y - 8.0, r.end.x - gr + ww - 16.0, 14.0), BRICK)

	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, KERB_STONE)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, "The modernista garden courtyard, off leash")
