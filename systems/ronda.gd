class_name Ronda
extends RefCounted

# WALK 43: CAMÍ DE RONDA (Costa Brava cliff path, Calella de Palafrugell / Llafranc).
#
# The old smugglers' and coastguards' footpath along the Costa Brava cliffs on a
# day of tramuntana (the hard north wind):
# - Start in the fishing village above a cove: whitewashed houses with arched
#   arcades (les voltes), cobbles, and fishing boats pulled up on the shingle.
# - Climb stone steps cut into the rock round two headlands, with a low
#   dry-stone wall and wooden rail on the sea side, umbrella pines leaning over
#   the path, and turquoise coves below.
# - Drop down stone steps through a pine wood (pinar) carpeted in needles.
# - Finish off the leash on a small shingle cove (Cala del Pinar).
#
# No chase, no boss.
#
# Signature live event: a telegraphed tramuntana gust (>= 1.2 s warning where
# the pines ahead bow and dust & pine needles lift off the path toward you).
# Then the gust shoves everyone seaward; your human staggers toward the cliff
# rail and their phone is at risk unless the dog plants on the landward side
# to anchor them on the leash. Nobody ever goes over the cliff edge.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer", "draw_freedom", "draw_live", "draw_overhead", "draw_snack", "idle_status", "is_lamp", "night_fronts", "on_bark", "surface", "tick", "tree_kind"]


const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EdgePath := preload("res://world/edge_path.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")

const OVERHEAD_FOLLOWS_CAMERA := true

const CX := 640.0
const HALF := 320.0
const START := 260.0
const GATE := -5000.0
const SUN := Vector2(0.55, 0.83)
const SHADOW := Color(0.05, 0.05, 0.09, 0.24)

# --- colours ------------------------------------------------------------------
const SEA_DEEP := Color(0.07, 0.30, 0.48)
const SEA_TURQ := Color(0.14, 0.56, 0.64)
const SEA_SHALLOW := Color(0.32, 0.74, 0.74)
const FOAM := Color(0.95, 0.98, 0.99, 0.72)
const SHINGLE := Color(0.76, 0.71, 0.62)
const SHINGLE_LIT := Color(0.84, 0.79, 0.69)
const SHINGLE_DARK := Color(0.58, 0.53, 0.45)

const VILLAGE_STONE := Color(0.75, 0.71, 0.64)
const VILLAGE_JOINT := Color(0.58, 0.54, 0.48, 0.6)
const WHITEWASH := Color(0.94, 0.92, 0.87)
const WHITEWASH_SHADE := Color(0.82, 0.80, 0.75)
const TERRACOTTA := Color(0.70, 0.36, 0.23)
const TERRACOTTA_LIT := Color(0.80, 0.44, 0.28)
const TERRACOTTA_DARK := Color(0.52, 0.25, 0.16)
const SHUTTER_BLUE := Color(0.18, 0.44, 0.62)

const CLIFF_TOP := Color(0.66, 0.58, 0.47)
const CLIFF_ROCK := Color(0.54, 0.46, 0.37)
const CLIFF_DARK := Color(0.36, 0.30, 0.25)
const ROCK_LIT := Color(0.78, 0.71, 0.60)
const PATH_DIRT := Color(0.74, 0.62, 0.45)
const PATH_EDGE := Color(0.60, 0.50, 0.36)
const STEP_STONE := Color(0.78, 0.73, 0.64)
const STEP_RISER := Color(0.42, 0.36, 0.30)
const DRYSTONE := Color(0.62, 0.57, 0.49)
const DRYSTONE_JOINT := Color(0.38, 0.34, 0.29)
const TIMBER := Color(0.48, 0.33, 0.20)
const TIMBER_LIT := Color(0.64, 0.46, 0.28)

const NEEDLE_BED := Color(0.34, 0.40, 0.22)
const NEEDLE_DARK := Color(0.24, 0.30, 0.17)
const NEEDLE_LIT := Color(0.48, 0.48, 0.26)
const PINE_DARK := Color(0.16, 0.28, 0.14)
const PINE_MID := Color(0.24, 0.40, 0.18)
const PINE_LIT := Color(0.36, 0.50, 0.23)
const PINE_TRUNK := Color(0.44, 0.26, 0.16)
const SCRUB_GREEN := Color(0.28, 0.38, 0.21)
const BROOM_GOLD := Color(0.92, 0.78, 0.22)

const BOAT_HULL_A := Color(0.93, 0.92, 0.88)
const BOAT_TRIM_A := Color(0.14, 0.42, 0.66)
const BOAT_HULL_B := Color(0.78, 0.30, 0.22)
const BOAT_TRIM_B := Color(0.94, 0.72, 0.22)
const WOOD_THWART := Color(0.58, 0.40, 0.24)

# --- route zones & landmarks --------------------------------------------------
const VILLAGE_END_Y := -720.0
const WOOD_START_Y := -3550.0

const STEP_BANDS: Array[Vector2] = [
	Vector2(-790.0, -680.0),
	Vector2(-1140.0, -1040.0),
	Vector2(-1500.0, -1400.0),
	Vector2(-1860.0, -1760.0),
	Vector2(-2590.0, -2490.0),
	Vector2(-2980.0, -2880.0),
	Vector2(-3380.0, -3280.0),
	Vector2(-3770.0, -3670.0),
	Vector2(-4180.0, -4080.0),
	Vector2(-4620.0, -4520.0),
]

const COVE_OVERLOOKS: Array[Vector2] = [
	Vector2(725.0, -480.0),
	Vector2(710.0, -2230.0),
	Vector2(725.0, -3560.0),
]
const OVERLOOK_VIEW_R := 88.0
const OVERLOOK_BARK_R := 230.0

const DARE_POS := Vector2(655.0, -2150.0)
const PRIZE := Vector2(805.0, -3050.0)
const PRIZE_TEXT := "nab the anchovy bocadillo off the wall"

# Coves along the east coast: [y_top, y_bot, cove_depth_x_extra, has_boats]
const COVES := [
	[-640.0, -120.0, 180.0, 2],
	[-2440.0, -1860.0, 175.0, 1],
	[-3880.0, -3340.0, 170.0, 1],
]

# Solid dry-stone parapet wall blocks along the sea edge + trail rock outcrops
const SOLID_ROCKS: Array[Rect2] = [
	Rect2(455.0, -1270.0, 42.0, 42.0),
	Rect2(475.0, -2860.0, 42.0, 42.0),
]
const WALL_YS: Array[float] = [-480.0, -1450.0, -2250.0, -3050.0]

# Village wrought-iron lamps (only these return true in is_lamp)
const VILLAGE_LAMPS: Array[Vector2] = [
	Vector2(368.0, -80.0),
	Vector2(368.0, -340.0),
	Vector2(368.0, -600.0),
	Vector2(742.0, -220.0),
]

# Off-leash shingle cove water edge (east side of the cove, non-walkable)
const COVE_WATER_X := 1090.0

# --- tramuntana gust tuning --------------------------------------------------
const GUST_WARN := 1.25          # >= 1.0 s telegraph before gust shoves
const GUST_BLOW := 1.65          # active shove duration
const GUST_COOLDOWN := 11.5      # time between gusts on exposed cliffs
const GUST_FIRST_WAIT := 4.5     # quick first gust once past the village
const GUST_Y_MAX := -760.0       # sheltered in village south of this
const GUST_Y_MIN := -4760.0      # sheltered near cove gate north of this
const GUST_DIR := Vector2(0.94, 0.34)  # seaward (east) and southward
const GUST_DOG_FORCE := 430.0
const GUST_HUMAN_FORCE := 520.0
const GUST_RAIL_MARGIN := 38.0
const GUST_PATIENCE_COST := 0.16

const WIND_PROP_STEP := 6.5      # seconds between blowing hat/map spawns
const WIND_PROP_CATCH_R := 26.0


static func _h(k: int) -> float:
	return fposmod(absf(sin(float(k) * 12.9898 + 4.13) * 43758.5453), 1.0)


# --- corridor geometry -------------------------------------------------------

static func edge_nodes(_m: Node2D = null) -> Array:
	return [
		{"y": START, "cx": 560.0, "half": 215.0},
		{"y": -680.0, "cx": 560.0, "half": 215.0},
		{"y": -1020.0, "cx": 615.0, "half": 190.0},
		{"y": -1450.0, "cx": 685.0, "half": 185.0},
		{"y": -1950.0, "cx": 575.0, "half": 195.0},
		{"y": -2250.0, "cx": 555.0, "half": 205.0},
		{"y": -2650.0, "cx": 635.0, "half": 190.0},
		{"y": -3050.0, "cx": 695.0, "half": 185.0},
		{"y": -3550.0, "cx": 575.0, "half": 195.0},
		{"y": -4150.0, "cx": 575.0, "half": 205.0},
		{"y": -4750.0, "cx": 590.0, "half": 205.0},
		{"y": GATE, "cx": 590.0, "half": 205.0},
	]


static func _edges_at(y: float) -> Vector2:
	return EdgePath.edges(edge_nodes(), y, CX, HALF)


static func _wall_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for wy: float in WALL_YS:
		var e := _edges_at(wy)
		out.append(Rect2(e.y - 18.0, wy - 44.0, 14.0, 88.0))
	return out


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = SOLID_ROCKS.duplicate()
	out.append_array(_wall_rects())
	return out


static func wrap_rects(_m: Node2D = null) -> Array[Rect2]:
	return solids()


# --- poles: pines, lamps, wooden rail posts, coastal boulders ----------------

static func _pine_poles() -> Array[Vector2]:
	var specs: Array = [
		[-880.0, true, 30.0],
		[-1260.0, true, 28.0],
		[-1720.0, true, 28.0],
		[-2080.0, true, 30.0],
		[-2460.0, true, 30.0],
		[-2820.0, true, 28.0],
		[-3260.0, true, 28.0],
		[-3640.0, true, 32.0],
		[-3880.0, false, 34.0],
		[-4040.0, true, 34.0],
		[-4260.0, false, 34.0],
		[-4440.0, true, 34.0],
		[-4680.0, false, 34.0],
		[-4860.0, true, 32.0],
	]
	var out: Array[Vector2] = []
	for s: Array in specs:
		var y: float = s[0]
		var e := _edges_at(y)
		var x := (e.x + float(s[2])) if bool(s[1]) else (e.y - float(s[2]))
		out.append(Vector2(x, y))
	return out


static func _rail_posts() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var y := -800.0
	while y >= -4880.0:
		var skip := false
		for wy: float in WALL_YS:
			if absf(y - wy) < 70.0:
				skip = true
				break
		if not skip and absf(y - PRIZE.y) > 55.0:
			var e := _edges_at(y)
			out.append(Vector2(e.y - 11.0, y))
		y -= 170.0
	return out


static func _boulder_poles() -> Array[Vector2]:
	var spots: Array = [
		[-1580.0, 0.32],
		[-2020.0, 0.72],
		[-2360.0, 0.68],
		[-3180.0, 0.34],
		[-3960.0, 0.42],
	]
	var out: Array[Vector2] = []
	for s: Array in spots:
		var y: float = s[0]
		var e := _edges_at(y)
		out.append(Vector2(lerpf(e.x, e.y, float(s[1])), y))
	return out


static func _is_in(list: Array[Vector2], p: Vector2) -> bool:
	for q: Vector2 in list:
		if p.distance_squared_to(q) < 4.0:
			return true
	return false


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(_pine_poles(), p):
		return m.TREE_FOREST
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(VILLAGE_LAMPS, p)


# --- cliff & cove walls (neither walkers nor rope can cross) -----------------

static func build_cliff_walls(m: Node2D) -> void:
	# Continuous SegmentShape2D walls along both walk edges all the way from
	# START_Y + 200 through GATE_Y - 30 (sealing the gap above GATE_Y + 120),
	# plus the east cove waterline wall in the off-leash cove.
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var y := float(m.START_Y) + 200.0
	var top := float(m.GATE_Y) - 30.0
	while y > top:
		var y2 := maxf(y - 60.0, top)
		var ea := _edges_at(y)
		var eb := _edges_at(y2)
		# East cliff edge: solid right at the edge
		var seg_e := SegmentShape2D.new()
		seg_e.a = Vector2(ea.y + 2.0, y)
		seg_e.b = Vector2(eb.y + 2.0, y2)
		var cs_e := CollisionShape2D.new()
		cs_e.shape = seg_e
		body.add_child(cs_e)
		# West house/rock wall
		var seg_w := SegmentShape2D.new()
		seg_w.a = Vector2(ea.x - 2.0, y)
		seg_w.b = Vector2(eb.x - 2.0, y2)
		var cs_w := CollisionShape2D.new()
		cs_w.shape = seg_w
		body.add_child(cs_w)
		y = y2
	# East sea edge of the off-leash shingle cove (non-walkable sea)
	var cove_seg := SegmentShape2D.new()
	cove_seg.a = Vector2(COVE_WATER_X, float(m.GATE_Y) - 30.0)
	cove_seg.b = Vector2(COVE_WATER_X, float(m.GATE_Y) - 640.0)
	var cove_cs := CollisionShape2D.new()
	cove_cs.shape = cove_seg
	body.add_child(cove_cs)
	m.add_child(body)


static func add_cliff_rope(m: Node2D) -> void:
	# Pure Rect2 entries in m.rope_rects (without adding hundreds of points to
	# m.poles) keep every rope segment strictly inside the cliff edge while
	# leaving m.poles clean for marking and dare trick checks.
	var y := float(m.START_Y) + 180.0
	var top := float(m.GATE_Y) - 30.0
	while y > top:
		var y2 := maxf(y - 36.0, top)
		var ea := _edges_at(y)
		var eb := _edges_at(y2)
		var ex := minf(ea.y, eb.y) + 4.0
		m.rope_rects.append(Rect2(ex, y2 - 1.0, 420.0, y - y2 + 2.0))
		y = y2
	# Sea edge in the off-leash cove
	m.rope_rects.append(Rect2(COVE_WATER_X + 2.0, float(m.GATE_Y) - 640.0, 400.0, 620.0))


# --- surfaces ----------------------------------------------------------------

static func _on_steps(y: float) -> bool:
	for b: Vector2 in STEP_BANDS:
		if y >= b.x and y <= b.y:
			return true
	return false


static func _cove_shore_x(y: float) -> float:
	for cv: Array in COVES:
		var y0: float = cv[0]
		var y1: float = cv[1]
		if y >= y0 and y <= y1:
			var f := sin((y - y0) / (y1 - y0) * PI)
			return _edges_at(y).y + 52.0 + float(cv[2]) * 0.55 * f
	return -INF


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		if p.x >= COVE_WATER_X:
			return Surfaces.S.WATER
		if p.x < 130.0 or p.y < float(m.GATE_Y) - 590.0:
			return Surfaces.S.GRASS
		return Surfaces.S.SAND
	var e := _edges_at(p.y)
	if p.x > e.y + 4.0:
		var shore := _cove_shore_x(p.y)
		if shore > -INF:
			if p.x <= shore:
				return Surfaces.S.SAND
			return Surfaces.S.WATER
		if p.x <= e.y + 42.0:
			return Surfaces.S.PAVEMENT
		return Surfaces.S.WATER
	if p.x < e.x - 4.0:
		if p.y >= VILLAGE_END_Y:
			return Surfaces.S.PAVEMENT
		if p.y <= WOOD_START_Y:
			return Surfaces.S.GRASS
		return Surfaces.S.PAVEMENT
	# On the path itself
	if p.y >= VILLAGE_END_Y or _on_steps(p.y):
		return Surfaces.S.PAVEMENT
	if p.y <= WOOD_START_Y:
		# Pine-needle flanks handle as grass; central packed trail as dirt
		var mid := (e.x + e.y) * 0.5
		if absf(p.x - mid) > 96.0:
			return Surfaces.S.GRASS
		return Surfaces.S.SAND
	# Headland stone wall & overlook aprons are stone; footpath is dirt
	for r: Rect2 in SOLID_ROCKS:
		if r.grow(10.0).has_point(p):
			return Surfaces.S.PAVEMENT
	for ov: Vector2 in COVE_OVERLOOKS:
		if p.distance_to(ov) < 52.0:
			return Surfaces.S.PAVEMENT
	return Surfaces.S.SAND


# --- build -------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "CALA DEL PINAR"
	m.gate_l = 415.0
	m.gate_r = 765.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)

	m.ronda_gust = {"state": "idle", "t": GUST_FIRST_WAIT, "saved": false, "hit": false, "bow": 0.0}
	m.ronda_gust_held = 0
	m.ronda_coves_seen = {}
	m.ronda_boats_barked = {}
	m.ronda_wind_props = []
	m.ronda_wind_caught = 0
	m.ronda_wind_next = 3.0
	m.ronda_sitters = []

	for pp: Vector2 in _pine_poles():
		m.poles.append(pp)
	for lp: Vector2 in VILLAGE_LAMPS:
		m.poles.append(lp)
	for rp: Vector2 in _rail_posts():
		m.poles.append(rp)
	for bp: Vector2 in _boulder_poles():
		m.poles.append(bp)
	m.deco_pole_count = m.poles.size()

	# Grindable wooden cliff rail along two headland stretches
	for seg_y: Array in [[-1620.0, -1300.0], [-3220.0, -2900.0]]:
		var pts := PackedVector2Array()
		var ry: float = float(seg_y[1])
		while ry >= float(seg_y[0]):
			pts.append(Vector2(_edges_at(ry).y - 12.0, ry))
			ry -= 80.0
		m.rails.append({"pts": pts})

	m.benches = Array([
		Vector2(746.0, -380.0),
		Vector2(384.0, -2290.0),
		Vector2(516.0, -3130.0),
		Vector2(404.0, -4380.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(410.0, -560.0),
		Vector2(405.0, -2180.0),
		Vector2(545.0, -3100.0),
		Vector2(750.0, -4780.0),
	], TYPE_VECTOR2, &"", null)

	m.fountains = Array([Vector2(385.0, -510.0)], TYPE_VECTOR2, &"", null)

	m.cone_spots = Array([
		Vector2(540.0, -960.0),
		Vector2(620.0, -2640.0),
	], TYPE_VECTOR2, &"", null)

	# Outdoor hikers / sightseers per Outdoors rules
	var weather: String = Game.weather
	var hour: String = Game.hour
	var hiker_share := Outdoors.coastal_hikers(weather, hour)
	for i in range(m.benches.size()):
		if _h(i * 23 + 11) < hiker_share:
			var bp: Vector2 = m.benches[i]
			m.ronda_sitters.append({"pos": bp + Vector2(0.0, -6.0), "face": Vector2.RIGHT, "key": 4300 + i * 17})

	var hyd_list: Array[Vector2] = [
		Vector2(736.0, -140.0),
		Vector2(465.0, -960.0),
		Vector2(785.0, -1620.0),
		Vector2(405.0, -2420.0),
		Vector2(820.0, -2960.0),
		Vector2(435.0, -3840.0),
		Vector2(745.0, -4560.0),
	]
	var keb_list: Array[Vector2] = [
		Vector2(575.0, -360.0),
		Vector2(650.0, -1350.0),
		Vector2(550.0, -2520.0),
		Vector2(670.0, -3380.0),
		Vector2(590.0, -4300.0),
	]
	return [hyd_list, keb_list]


# --- per frame: tramuntana gust, blowing hats & maps, cove overlooks ---------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position

	# 1. Cove overlooks: pause or step onto a cliffside lookout over a cove
	for i in range(COVE_OVERLOOKS.size()):
		if m.ronda_coves_seen.has(i):
			continue
		if dp.distance_to(COVE_OVERLOOKS[i]) < OVERLOOK_VIEW_R:
			m.ronda_coves_seen[i] = true
			m.award_points(2, I18n.t("w_cove_vista_2"))
			_sfx(m, "pickup", 1.1)

	# 2. Blowing hats and maps in wind weather (deterministic, no global RNG)
	if Game.weather == "wind":
		_tick_wind_props(m, delta, dp, hp)

	# 3. Signature live event: the telegraphed tramuntana gust
	var st: Dictionary = m.ronda_gust
	if st.is_empty():
		st = {"state": "idle", "t": GUST_FIRST_WAIT, "saved": false, "hit": false, "bow": 0.0}
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))
	var exposed := hp.y < GUST_Y_MAX and hp.y > GUST_Y_MIN

	match state:
		"idle":
			st["bow"] = move_toward(float(st.get("bow", 0.0)), 0.0, delta * 1.8)
			if exposed:
				t -= delta
				if t <= 0.0:
					st["state"] = "telegraph"
					st["t"] = GUST_WARN
					st["saved"] = false
					st["hit"] = false
					_sfx(m, "hiss", 0.52)
					m.feed.say(I18n.t("w_tramuntana_gust_plant_landward"), EventFeed.Tone.LOUD)
					if m.human.can_warn_external():
						m.human.notice(I18n.t("w_whoa_feel_that_wind"), 1.2)
					m.float_text(dp + Vector2(30.0, -56.0), I18n.t("w_whoooosh"), Color(0.90, 0.96, 1.0))
				else:
					st["t"] = t
		"telegraph":
			t -= delta
			var prog := clampf(1.0 - t / GUST_WARN, 0.0, 1.0)
			st["bow"] = prog * 0.65
			st["t"] = t
			if t <= 0.0:
				st["state"] = "blowing"
				st["t"] = GUST_BLOW
				_sfx(m, "hiss", 0.72)
		"blowing":
			t -= delta
			st["t"] = t
			var blow_k := clampf(1.0 - t / GUST_BLOW, 0.0, 1.0)
			var swell := sin(PI * blow_k)
			st["bow"] = 0.65 + 0.35 * swell
			var gdir := GUST_DIR.normalized()
			var dog_planted_landward: bool = bool(m.dog.planted) and dp.x < hp.x
			if not bool(m.dog.planted):
				m.dog.velocity += gdir * GUST_DOG_FORCE * swell * delta
			if dog_planted_landward and m.human.state != m.human.HState.FALLEN:
				# Leash anchors the human against the seaward shove
				m.human.velocity.x = minf(m.human.velocity.x, 20.0)
				if not bool(st.get("saved", false)):
					st["saved"] = true
					m.ronda_gust_held += 1
					m.saves_done += 1
					m.award_points(4, I18n.t("w_held_the_gust_4"))
					m.combo.add("ANCHOR", 3)
					m.feed.say(I18n.t("w_held_the_tramuntana"), EventFeed.Tone.GOOD)
					m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_good_catch"), Color(0.98, 0.96, 0.88), m.POP_SAY)
					_sfx(m, "save", 1.05)
			else:
				m.human.velocity += gdir * GUST_HUMAN_FORCE * swell * delta
				var edge_r := _edges_at(hp.y).y
				if not bool(st.get("hit", false)) and not bool(st.get("saved", false)):
					if hp.x >= edge_r - GUST_RAIL_MARGIN or blow_k >= 0.58:
						st["hit"] = true
						if not m.auto_walk and m.human.state != m.human.HState.FALLEN:
							m.human.bumped(gdir)
							m.human.lose_patience(GUST_PATIENCE_COST)
							m.human.fall("tramuntana")
							m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_whoa_my_phone"), Color(1.0, 0.65, 0.55), m.POP_SAY)
							m.feed.say(I18n.t("w_shoved_to_the_rail"), EventFeed.Tone.BAD)
			if t <= 0.0:
				st["state"] = "idle"
				st["t"] = GUST_COOLDOWN
	m.ronda_gust = st


static func _tick_wind_props(m: Node2D, delta: float, dp: Vector2, hp: Vector2) -> void:
	var props: Array = m.ronda_wind_props
	var gust_on: bool = String(m.ronda_gust.get("state", "idle")) == "blowing"
	var nxt: float = float(m.ronda_wind_next) - delta
	if nxt <= 0.0 and hp.y < 120.0 and hp.y > GATE + 340.0 and props.size() < 2:
		nxt = WIND_PROP_STEP
		var idx := int(absf(m.elapsed) * 7.0 + float(m.ronda_wind_caught))
		var sy := hp.y - 360.0
		var e := _edges_at(sy)
		var sx := lerpf(e.x + 34.0, e.y - 44.0, _h(idx * 19 + 3))
		var kind := "hat" if idx % 2 == 0 else "map"
		props.append({"pos": Vector2(sx, sy), "vel": Vector2(45.0, 125.0), "kind": kind, "spin": _h(idx) * TAU})
	m.ronda_wind_next = nxt

	var dir := GUST_DIR.normalized()
	for i in range(props.size() - 1, -1, -1):
		var it: Dictionary = props[i]
		var v: Vector2 = it["vel"]
		var target := dir * (240.0 if gust_on else 135.0)
		v = v.move_toward(target, 180.0 * delta)
		var p: Vector2 = Vector2(it["pos"]) + v * delta
		var e := _edges_at(p.y)
		p.x = clampf(p.x, e.x + 18.0, e.y - 18.0)
		it["pos"] = p
		it["vel"] = v
		it["spin"] = float(it["spin"]) + delta * (5.2 if gust_on else 2.8)
		if p.distance_to(dp) < WIND_PROP_CATCH_R and not m.dog.is_tumbling():
			m.ronda_wind_caught += 1
			var label := I18n.t("w_caught_a_hat_2") if String(it["kind"]) == "hat" else I18n.t("w_caught_a_map_2")
			m.award_points(2, label)
			_sfx(m, "rustle", 1.15)
			props.remove_at(i)
			continue
		if p.y > hp.y + 420.0 or p.y < GATE:
			props.remove_at(i)


static func idle_status(m: Node2D) -> String:
	var st := String(m.ronda_gust.get("state", "idle"))
	if st == "telegraph":
		return I18n.t("ronda_gust_coming")
	if st == "blowing":
		return I18n.t("ronda_tramuntana")
	return ""


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = m.dog.global_position if pos == Vector2.ZERO else pos
	for i in range(COVE_OVERLOOKS.size()):
		if not m.ronda_boats_barked.has(i) and p.distance_to(COVE_OVERLOOKS[i]) <= OVERLOOK_BARK_R:
			m.ronda_boats_barked[i] = true
			m.award_points(2, I18n.t("w_ahoy_boat_2"))
			m.combo.add("COVE ECHO", 2)
			m.float_text(COVE_OVERLOOKS[i] + Vector2(64.0, -18.0), I18n.t("w_woof_woof"), Color(0.90, 0.96, 1.0))
			_sfx(m, "whoop", 1.15)
			return true
	return false


static func _sfx(m: Node2D, name: String, pitch: float) -> void:
	var sfx: Node = m.get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play(name, pitch, -4.0)


# --- cached edge layer: sea, coves, boats, cliffs, village houses -----------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 280.0, GATE - 40.0)
	var hi := minf(vb + 280.0, START + 560.0)
	if hi > lo:
		_draw_sea_and_cliffs(b, lo, hi)
		_draw_coves(b, lo, hi)
		_draw_land_flank(b, lo, hi)
	b.lod = keep_lod


static func _draw_sea_and_cliffs(b: ShapeBatch, lo: float, hi: float) -> void:
	# Deep Mediterranean sea across the east half, then smooth turquoise gradient toward shore
	b.rect(Rect2(560.0, lo, 1200.0, hi - lo), SEA_DEEP)
	b.band(PackedVector2Array([
		Vector2(660.0, lo), Vector2(1060.0, lo), Vector2(1380.0, lo),
		Vector2(660.0, hi), Vector2(1060.0, hi), Vector2(1380.0, hi),
	]), 3, SEA_TURQ, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.48, 0.0]))
	# Cliff face dropping along the east path edge
	var step := 28.0
	var y := floorf(lo / step) * step
	var ea := _edges_at(y)
	while y < hi:
		var eb := _edges_at(y + step)
		var k := int(absf(y) / step)
		var w_a := 36.0 + _h(k * 7) * 14.0
		var w_b := 36.0 + _h((k + 1) * 7) * 14.0
		# Soft shallow turquoise glow against the base of the cliff rocks
		b.band(PackedVector2Array([
			Vector2(ea.y + w_a * 0.7, y), Vector2(ea.y + w_a + 70.0, y),
			Vector2(eb.y + w_b * 0.7, y + step), Vector2(eb.y + w_b + 70.0, y + step),
		]), 2, SEA_SHALLOW, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.65, 0.0]))
		# Steep rocky cliff strata (upper lit rock, lower shaded rock face)
		b.quad(Vector2(ea.y - 2.0, y), Vector2(ea.y + w_a, y), Vector2(eb.y + w_b, y + step + 1.0), Vector2(eb.y - 2.0, y + step + 1.0), CLIFF_DARK)
		b.quad(Vector2(ea.y - 2.0, y), Vector2(ea.y + w_a * 0.56, y), Vector2(eb.y + w_b * 0.56, y + step + 1.0), Vector2(eb.y - 2.0, y + step + 1.0), CLIFF_ROCK)
		b.quad(Vector2(ea.y - 2.0, y), Vector2(ea.y + 12.0, y), Vector2(eb.y + 12.0, y + step + 1.0), Vector2(eb.y - 2.0, y + step + 1.0), CLIFF_TOP)
		if k % 3 == 0:
			var rx := ea.y + w_a + 18.0 + _h(k * 13) * 30.0
			var rr := 8.0 + _h(k * 19) * 8.0
			var ro := Vector2(rx, y + 14.0)
			# Jagged sea stack + leeward white foam trail
			var stack := PackedVector2Array()
			var crown := PackedVector2Array()
			for vi in range(6):
				var ang := TAU * float(vi) / 6.0 + _h(k * 29 + vi) * 0.45
				var vr := rr * (0.72 + _h(k * 31 + vi) * 0.48)
				stack.append(ro + Vector2.from_angle(ang) * vr)
				crown.append(ro - Vector2(2.0, 2.0) + Vector2.from_angle(ang) * (vr * 0.55))
			b.line(ro - Vector2(0.0, rr * 0.6), ro + Vector2(3.0, rr * 1.9), Color(FOAM.r, FOAM.g, FOAM.b, 0.36), rr * 0.75)
			b.polygon(stack, CLIFF_DARK)
			b.polygon(crown, CLIFF_ROCK)
		ea = eb
		y += step


static func _draw_coves(b: ShapeBatch, lo: float, hi: float) -> void:
	for ci in range(COVES.size()):
		var cv: Array = COVES[ci]
		var y0: float = cv[0]
		var y1: float = cv[1]
		if y1 < lo - 60.0 or y0 > hi + 60.0:
			continue
		var depth: float = cv[2]
		var n := 16
		var beach_pts := PackedVector2Array()
		var shallow_pts := PackedVector2Array()
		for i in range(n + 1):
			var f := float(i) / float(n)
			var yy := lerpf(y0, y1, f)
			var e := _edges_at(yy)
			var arc := sin(f * PI)
			beach_pts.append(Vector2(e.y + 24.0, yy))
			shallow_pts.append(Vector2(e.y + 52.0 + depth * 0.55 * arc, yy))
		# Scalloped shingle bay & smooth shallow cove water gradient
		var poly := PackedVector2Array()
		for p: Vector2 in beach_pts:
			poly.append(p)
		for i in range(n, -1, -1):
			poly.append(shallow_pts[i])
		b.polygon(poly, SHINGLE)
		var band_pts := PackedVector2Array()
		var row_a := PackedFloat32Array()
		row_a.resize(n + 1)
		for i in range(n + 1):
			var f := float(i) / float(n)
			row_a[i] = pow(sin(PI * f), 0.55)
			band_pts.append(shallow_pts[i] - Vector2(6.0, 0.0))
			band_pts.append(shallow_pts[i] + Vector2(90.0, 0.0))
		b.band(band_pts, 2, SEA_SHALLOW, row_a, PackedFloat32Array([0.85, 0.0]))
		# Shingle texture pebbles
		for k in range(28):
			var f := _h(ci * 97 + k * 11)
			var yy := lerpf(y0 + 36.0, y1 - 36.0, f)
			var arc := sin(f * PI)
			var e := _edges_at(yy)
			var px := lerpf(e.y + 32.0, e.y + 44.0 + depth * 0.45 * arc, _h(ci * 53 + k * 7))
			b.coarse(Vector2(px, yy), 2.5 + _h(k * 3) * 2.5, SHINGLE_LIT if k % 2 == 0 else SHINGLE_DARK)
		# Fishing boats (llaguts) pulled up on the cove shingle
		var boats: int = int(cv[3])
		for bi in range(boats):
			var bf := 0.42 if boats == 1 else (0.34 if bi == 0 else 0.66)
			var by := lerpf(y0, y1, bf)
			var e := _edges_at(by)
			var bx := e.y + 52.0 + depth * 0.30 * sin(bf * PI)
			_draw_llagut(b, Vector2(bx, by), -0.35 + float(bi) * 0.5, bi % 2 == 0)


static func _draw_llagut(b: ShapeBatch, at: Vector2, rot: float, blue_trim: bool) -> void:
	var ax := Vector2.from_angle(rot)
	var ay := ax.orthogonal()
	var hull := BOAT_HULL_A if blue_trim else BOAT_HULL_B
	var trim := BOAT_TRIM_A if blue_trim else BOAT_TRIM_B
	var pts := PackedVector2Array([
		at + ax * 26.0, at + ax * 14.0 + ay * 9.0, at - ax * 14.0 + ay * 8.5,
		at - ax * 25.0, at - ax * 14.0 - ay * 8.5, at + ax * 14.0 - ay * 9.0,
	])
	var sh := PackedVector2Array()
	for p: Vector2 in pts:
		sh.append(p + SUN * 5.0)
	b.polygon(sh, SHADOW)
	b.polygon(pts, trim)
	var inner := PackedVector2Array([
		at + ax * 21.0, at + ax * 12.0 + ay * 6.8, at - ax * 12.0 + ay * 6.5,
		at - ax * 20.0, at - ax * 12.0 - ay * 6.5, at + ax * 12.0 - ay * 6.8,
	])
	b.polygon(inner, hull)
	for off: float in [-7.0, 0.0, 7.0]:
		b.line(at + ax * off - ay * 5.5, at + ax * off + ay * 5.5, WOOD_THWART, 3.0)
	b.circle(at + ax * 12.0, 3.0, Color(0.76, 0.64, 0.44))


static func _draw_land_flank(b: ShapeBatch, lo: float, hi: float) -> void:
	# West slope backdrop: village plaster, rock cuts, pine wood floor
	b.rect(Rect2(-420.0, lo, 980.0, hi - lo), CLIFF_ROCK)
	# Village whitewashed houses along the west side (y >= VILLAGE_END_Y)
	if hi > VILLAGE_END_Y:
		var v_lo := maxf(lo, VILLAGE_END_Y)
		b.rect(Rect2(-420.0, v_lo, 960.0, hi - v_lo), WHITEWASH_SHADE)
		var hy := floorf(v_lo / 180.0) * 180.0
		var hk := 0
		while hy < hi:
			var e := _edges_at(hy + 90.0)
			var wall_r := e.x
			# Arched arcade bay (les voltes) stepping onto the village side
			var bay := Rect2(wall_r - 36.0, hy + 10.0, 36.0, 158.0)
			b.rect(bay, WHITEWASH)
			for ai in range(3):
				var ay := hy + 28.0 + float(ai) * 48.0
				b.circle(Vector2(wall_r - 4.0, ay), 13.0, Color(0.24, 0.21, 0.19, 0.45))
				b.rect(Rect2(wall_r - 20.0, ay - 11.0, 16.0, 22.0), Color(0.24, 0.21, 0.19, 0.35))
			# House roof block set behind the arcade
			var house := Rect2(wall_r - 240.0, hy + 12.0, 200.0, 154.0)
			b.rect(Rect2(house.position + SUN * 8.0, house.size), SHADOW)
			b.rect(house, WHITEWASH)
			var roof := house.grow(-8.0)
			b.rect(Rect2(roof.position.x, roof.position.y, roof.size.x * 0.5, roof.size.y), TERRACOTTA_LIT)
			b.rect(Rect2(roof.get_center().x, roof.position.y, roof.size.x * 0.5, roof.size.y), TERRACOTTA)
			b.line(Vector2(roof.get_center().x, roof.position.y + 6.0), Vector2(roof.get_center().x, roof.end.y - 6.0), TERRACOTTA_DARK, 3.0)
			# Blue shutters on east wall
			b.rect(Rect2(wall_r - 40.0, hy + 50.0, 5.0, 18.0), SHUTTER_BLUE)
			b.rect(Rect2(wall_r - 40.0, hy + 114.0, 5.0, 18.0), SHUTTER_BLUE)
			hy += 180.0
			hk += 1
	# Coastal cliffs & pine wood west of the path (y < VILLAGE_END_Y)
	var c_hi := minf(hi, VILLAGE_END_Y)
	if c_hi > lo:
		var step := 32.0
		var y := floorf(lo / step) * step
		var ea := _edges_at(y)
		while y < c_hi:
			var eb := _edges_at(y + step)
			var k := int(absf(y) / step)
			var hk := _h(k * 17)
			var wood := y <= WOOD_START_Y
			var base_col := NEEDLE_DARK if wood else CLIFF_ROCK
			b.quad(Vector2(-420.0, y), Vector2(ea.x, y), Vector2(eb.x, y + step + 1.0), Vector2(-420.0, y + step + 1.0), base_col)
			# Cut rock shoulder or mossy bank right along e.x
			var bank := 26.0 + hk * 12.0
			b.quad(Vector2(ea.x - bank, y), Vector2(ea.x + 2.0, y), Vector2(eb.x + 2.0, y + step + 1.0), Vector2(eb.x - bank, y + step + 1.0), NEEDLE_BED if wood else CLIFF_TOP)
			# Coastal maquis scrub & yellow broom
			if not wood:
				b.coarse(Vector2(ea.x - 56.0 - hk * 40.0, y + 16.0), 16.0 + hk * 8.0, SCRUB_GREEN)
				if k % 3 == 1:
					b.coarse(Vector2(ea.x - 42.0 - hk * 24.0, y + 10.0), 7.5, BROOM_GOLD)
			else:
				b.coarse(Vector2(ea.x - 62.0 - hk * 50.0, y + 16.0), 22.0 + hk * 10.0, PINE_DARK)
			ea = eb
			y += step


# --- ground pass (cached by ground_layer; never read AnimClock here) ----------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi := minf(vb + 40.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_draw_path_ribbon(wc, lo, hi)
		_draw_steps(wc, lo, hi)
		_draw_overlooks(wc, lo, hi)
		_draw_cliff_rail(wc, lo, hi)
		_draw_solids(wc, lo, hi)
	wc.lod = keep_lod


static func _draw_path_ribbon(wc: ShapeBatch, lo: float, hi: float) -> void:
	var step := 24.0
	var y := floorf(hi / step) * step
	var eb := _edges_at(y + step)
	while y > lo - step:
		var ea := _edges_at(y)
		var k := int(absf(y) / step)
		var hk := _h(k * 13 + 5)
		var poly := PackedVector2Array([
			Vector2(ea.x, y), Vector2(ea.y, y), Vector2(eb.y, y + step + 0.5), Vector2(eb.x, y + step + 0.5),
		])
		if y >= VILLAGE_END_Y:
			wc.polygon(poly, VILLAGE_STONE)
			if k % 2 == 0:
				wc.line(Vector2(ea.x + 4.0, y), Vector2(ea.y - 4.0, y), VILLAGE_JOINT, 1.2)
		elif y <= WOOD_START_Y:
			# Pine wood: needle-carpeted flanks (S.GRASS) with packed earth path down the middle
			wc.polygon(poly, NEEDLE_BED)
			var mid_a := (ea.x + ea.y) * 0.5
			var mid_b := (eb.x + eb.y) * 0.5
			wc.quad(Vector2(mid_a - 96.0, y), Vector2(mid_a + 96.0, y), Vector2(mid_b + 96.0, y + step + 0.5), Vector2(mid_b - 96.0, y + step + 0.5), PATH_DIRT)
			wc.line(Vector2(mid_a - 96.0, y), Vector2(mid_b - 96.0, y + step), NEEDLE_DARK, 3.0)
			wc.line(Vector2(mid_a + 96.0, y), Vector2(mid_b + 96.0, y + step), NEEDLE_DARK, 3.0)
			# Fallen pine needle streaks on the flanks
			for ni in range(2):
				var nx := (ea.x + 26.0 + _h(k * 11 + ni) * 58.0) if ni == 0 else (ea.y - 26.0 - _h(k * 17 + ni) * 58.0)
				var ny := y + _h(k * 23 + ni) * step
				wc.line(Vector2(nx - 5.0, ny - 2.0), Vector2(nx + 5.0, ny + 2.0), NEEDLE_LIT if k % 2 == 0 else NEEDLE_DARK, 1.6)
		else:
			wc.polygon(poly, PATH_DIRT)
			wc.line(Vector2(ea.x + 4.0, y), Vector2(eb.x + 4.0, y + step), PATH_EDGE, 6.0)
			wc.line(Vector2(ea.y - 4.0, y), Vector2(eb.y - 4.0, y + step), PATH_EDGE, 6.0)
			if k % 2 == 0:
				var px := lerpf(ea.x + 28.0, ea.y - 36.0, hk)
				wc.coarse(Vector2(px, y + hk * step), 2.4, STEP_STONE)
		eb = ea
		y -= step


static func _draw_steps(wc: ShapeBatch, lo: float, hi: float) -> void:
	for b: Vector2 in STEP_BANDS:
		if b.y < lo - 20.0 or b.x > hi + 20.0:
			continue
		var sy := b.y
		while sy >= b.x:
			var ea := _edges_at(sy)
			var eb := _edges_at(sy - 16.0)
			wc.quad(Vector2(ea.x + 12.0, sy), Vector2(ea.y - 18.0, sy), Vector2(eb.y - 18.0, sy - 16.0), Vector2(eb.x + 12.0, sy - 16.0), STEP_STONE)
			wc.line(Vector2(ea.x + 12.0, sy), Vector2(ea.y - 18.0, sy), STEP_RISER, 3.0)
			sy -= 20.0


static func _draw_overlooks(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(COVE_OVERLOOKS.size()):
		var ov: Vector2 = COVE_OVERLOOKS[i]
		if ov.y < lo - 70.0 or ov.y > hi + 70.0:
			continue
		wc.circle(ov, 44.0, STEP_STONE)
		wc.circle(ov, 36.0, VILLAGE_STONE)
		wc.circle(ov, 14.0, DRYSTONE)
		wc.circle(ov, 6.0, SEA_TURQ)


static func _draw_cliff_rail(wc: ShapeBatch, lo: float, hi: float) -> void:
	var posts := _rail_posts()
	for i in range(posts.size() - 1):
		var a := posts[i]
		var b := posts[i + 1]
		if maxf(a.y, b.y) < lo - 40.0 or minf(a.y, b.y) > hi + 40.0:
			continue
		if a.distance_to(b) > 220.0:
			continue
		wc.line(a + Vector2(3.0, 4.0), b + Vector2(3.0, 4.0), SHADOW, 4.0)
		wc.line(a, b, TIMBER, 4.5)
		wc.line(a + Vector2(-1.0, 0.0), b + Vector2(-1.0, 0.0), TIMBER_LIT, 1.8)


static func _draw_solids(wc: ShapeBatch, lo: float, hi: float) -> void:
	for r: Rect2 in _wall_rects():
		if r.end.y < lo - 20.0 or r.position.y > hi + 20.0:
			continue
		wc.rect(Rect2(r.position + SUN * 6.0, r.size), SHADOW)
		wc.rect(r, DRYSTONE_JOINT)
		wc.rect(r.grow(-2.0), DRYSTONE)
		var sy := r.position.y + 10.0
		while sy < r.end.y - 6.0:
			wc.line(Vector2(r.position.x + 2.0, sy), Vector2(r.end.x - 2.0, sy), DRYSTONE_JOINT, 1.4)
			sy += 14.0
	for r: Rect2 in SOLID_ROCKS:
		if r.end.y < lo - 20.0 or r.position.y > hi + 20.0:
			continue
		var c := r.get_center()
		wc.circle(c + SUN * 7.0, 22.0, SHADOW)
		wc.circle(c, 21.0, CLIFF_DARK)
		wc.circle(c - Vector2(2.0, 2.0), 17.0, CLIFF_ROCK)
		wc.circle(c - Vector2(6.0, 6.0), 9.0, ROCK_LIT)


# --- poles: wooden rail posts & coastal rock bollards -----------------------

static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(_boulder_poles(), p):
		wc.circle(p + SUN * 5.0, 12.0, SHADOW)
		wc.circle(p, 11.5, CLIFF_DARK)
		wc.circle(p - Vector2(1.0, 1.0), 9.5, CLIFF_ROCK)
		wc.circle(p - Vector2(3.0, 3.0), 4.5, ROCK_LIT)
		return
	# Timber rail post on the cliff edge
	wc.circle(p + SUN * 5.0, 6.5, SHADOW)
	wc.circle(p, 6.0, TIMBER.darkened(0.25))
	wc.circle(p, 4.6, TIMBER)
	wc.circle(p - Vector2(1.2, 1.2), 2.2, TIMBER_LIT)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 11.0, 3.0, 0.20)
	wc.polygon(PackedVector2Array([kp + Vector2(-11, -5), kp + Vector2(5, -7), kp + Vector2(9, 4), kp + Vector2(-9, 6)]), Color(0.92, 0.90, 0.84))
	wc.capsule(kp + Vector2(-4, 0), kp + Vector2(9, -2), 4.4, Color(0.84, 0.64, 0.36))
	wc.capsule(kp + Vector2(-2, -1), kp + Vector2(7, -3), 1.8, Color(0.46, 0.56, 0.64))


# --- live pass: whitecaps, blowing hats/maps, gust particles, prize, sitters -

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var wt := float(AnimClock.msec()) * 0.001

	# 1. Sea whitecaps on the open water east of the cliff edge
	var wy := floorf(maxf(vt, GATE) / 110.0) * 110.0
	var w_hi := minf(vb, START + 400.0)
	while wy < w_hi:
		var k := int(absf(wy) / 110.0)
		var e := _edges_at(wy)
		var drift := fmod(wt * 42.0 + _h(k * 31) * 180.0, 180.0)
		var wx := e.y + 115.0 + _h(k * 17) * 140.0 + drift * 0.45
		var wpy := wy + drift * 0.16
		var crest := 12.0 + sin(wt * 2.6 + float(k)) * 4.0
		wc.line(Vector2(wx - crest, wpy - 2.0), Vector2(wx + crest, wpy + 3.0), FOAM, 2.8)
		wc.line(Vector2(wx - crest * 0.5, wpy + 4.0), Vector2(wx + crest * 0.4, wpy + 7.0), Color(1.0, 1.0, 1.0, 0.40), 1.6)
		wy += 110.0

	# 2. Bench hikers (Outdoors.coastal_hikers)
	for s: Dictionary in m.ronda_sitters:
		var sp: Vector2 = s["pos"]
		if sp.y < vt - 40.0 or sp.y > vb + 40.0:
			continue
		NpcFigure.person(wc, sp, s["face"], int(s["key"]), -1.0, {"arms": NpcFigure.Arms.SIDE})

	# 3. Blowing hats & maps along the path
	for it: Dictionary in m.ronda_wind_props:
		var p: Vector2 = it["pos"]
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var sp := float(it["spin"])
		wc.circle(p + Vector2(3.0, 4.0), 8.0, SHADOW)
		if String(it["kind"]) == "hat":
			wc.circle(p, 9.5, Color(0.92, 0.83, 0.60))
			wc.circle(p, 5.4, Color(0.84, 0.72, 0.48))
			wc.circle(p + Vector2.from_angle(sp) * 1.4, 2.4, Color(0.24, 0.34, 0.52))
		else:
			var ax := Vector2.from_angle(sp)
			var ay := ax.orthogonal()
			var pts := PackedVector2Array([p - ax * 9.0 - ay * 6.0, p + ax * 9.0 - ay * 6.0, p + ax * 9.0 + ay * 6.0, p - ax * 9.0 + ay * 6.0])
			wc.polygon(pts, Color(0.96, 0.94, 0.86))
			wc.line(p - ax * 6.0, p + ax * 6.0, Color(0.84, 0.24, 0.20), 1.6)
			wc.line(p + ay * 2.5 - ax * 5.0, p + ay * 2.5 + ax * 5.0, SEA_TURQ, 1.8)

	# 4. Tramuntana gust telegraph & active dust/needles lifting toward you
	var gst := String(m.ronda_gust.get("state", "idle"))
	if gst == "telegraph" or gst == "blowing":
		var intensity := 0.55 if gst == "telegraph" else 1.0
		var hp: Vector2 = m.human.global_position
		var gdir := GUST_DIR.normalized()
		for j in range(22):
			var phase := fposmod(wt * (1.8 if gst == "telegraph" else 3.2) + float(j) * 0.173, 1.0)
			var py := hp.y - 340.0 + phase * 520.0 + (_h(j * 11) - 0.5) * 60.0
			var e := _edges_at(py)
			var px := lerpf(e.x + 16.0, e.y - 16.0, _h(j * 29 + 3)) + phase * 70.0
			var pos := Vector2(px, py)
			if pos.y < vt - 40.0 or pos.y > vb + 40.0:
				continue
			var len_s := 18.0 + 18.0 * intensity
			var col := Color(0.92, 0.88, 0.78, 0.55 * intensity) if j % 2 == 0 else Color(0.46, 0.42, 0.24, 0.75 * intensity)
			wc.line(pos - gdir * len_s, pos + gdir * len_s, col, 2.2 if j % 2 == 0 else 1.8)
			wc.coarse(pos, 2.4, Color(0.84, 0.76, 0.58, 0.45 * intensity))

	# 5. Unique walk prize: anchovy bocadillo on the headland parapet
	if not bool(m.prize_taken) and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		wc.glow(PRIZE, 20.0, Color(1.0, 0.88, 0.48, 0.26))
		wc.circle(PRIZE + Vector2(1.5, 2.0), 7.5, SHADOW)
		wc.rect(Rect2(PRIZE - Vector2(9.0, 5.0), Vector2(18.0, 10.0)), Color(0.96, 0.94, 0.88))
		wc.capsule(PRIZE + Vector2(-5.0, 0.0), PRIZE + Vector2(5.0, 0.0), 4.0, Color(0.88, 0.68, 0.36))
		wc.line(PRIZE + Vector2(-4.0, -1.0), PRIZE + Vector2(4.0, -1.0), Color(0.32, 0.46, 0.58), 2.0)


# --- overhead: leaning swaying/bowing umbrella pines & village eaves ---------

static func draw_overhead(m: Node2D, ci: Object) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	var vt: float = m.view_lo(160.0) if m.has_method("view_lo") else -6000.0
	var vb: float = m.view_hi(160.0) if m.has_method("view_hi") else 600.0
	var wt := float(AnimClock.msec()) * 0.001
	var bow := float(m.ronda_gust.get("bow", 0.0))
	var wind_mult := 1.0 if Game.weather == "wind" else 0.4

	# Leaning coastal umbrella pines rooted on the landward side, reaching over the path
	var py := -760.0
	var idx := 0
	while py > GATE + 80.0:
		if py >= vt - 100.0 and py <= vb + 100.0:
			var e := _edges_at(py)
			var root := Vector2(e.x - 16.0, py)
			var sway := sin(wt * 2.2 + float(idx) * 1.4) * (5.0 * wind_mult + 5.0 * bow)
			var lean := Vector2(34.0 + bow * 22.0 + sway, 8.0 + bow * 14.0)
			var crown := root + lean
			b.line(root, crown, PINE_TRUNK, 7.0)
			b.line(root + Vector2(-1.0, -1.0), crown + Vector2(-1.0, -1.0), PINE_TRUNK.lightened(0.2), 2.5)
			var r := 32.0 + _h(idx * 13) * 10.0
			b.circle(crown + Vector2(2.0, 3.0), r, PINE_DARK)
			b.circle(crown - Vector2(2.0, 2.0), r * 0.82, PINE_MID)
			b.circle(crown - Vector2(6.0, 6.0), r * 0.52, PINE_LIT)
		py -= 230.0
		idx += 1
	b.flush()


static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hy := -620.0
	var hk := 0
	while hy < 220.0:
		var e := _edges_at(hy)
		var kind := "bar" if hk % 3 == 0 else "home"
		out.append(NightFronts.front(Vector2(e.x, hy), 1.0, kind, 4310 + hk))
		hy += 180.0
		hk += 1
	return out


# --- off-leash shingle cove: CALA DEL PINAR ---------------------------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var gy := r.end.y
	var top := r.position.y
	var b := ShapeBatch.new()

	# 1. Sea & coastal horizon around the east and north of the cove
	b.rect(Rect2(-420.0, top - 2400.0, 2140.0, 2400.0), SEA_DEEP)
	b.rect(Rect2(COVE_WATER_X - 30.0, top - 20.0, 640.0, r.size.y + 40.0), SEA_DEEP)
	b.band(PackedVector2Array([
		Vector2(COVE_WATER_X - 10.0, top - 20.0), Vector2(COVE_WATER_X + 180.0, top - 20.0),
		Vector2(COVE_WATER_X - 10.0, gy + 20.0), Vector2(COVE_WATER_X + 180.0, gy + 20.0),
	]), 2, SEA_TURQ, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	b.band(PackedVector2Array([
		Vector2(COVE_WATER_X - 6.0, top - 20.0), Vector2(COVE_WATER_X + 55.0, top - 20.0),
		Vector2(COVE_WATER_X - 6.0, gy + 20.0), Vector2(COVE_WATER_X + 55.0, gy + 20.0),
	]), 2, SEA_SHALLOW, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.9, 0.0]))

	# 2. Sheltered shingle beach across the cove
	b.rect(Rect2(r.position.x, top, COVE_WATER_X - r.position.x, r.size.y + 20.0), SHINGLE)
	# Approach threshold connecting seamlessly from GATE_Y
	b.rect(Rect2(385.0, gy - 8.0, 410.0, float(m.GATE_Y) - gy + 16.0), PATH_DIRT)
	# Pine-needle verge along west & north rocky rim
	b.rect(Rect2(-420.0, top - 20.0, 550.0, r.size.y + 40.0), NEEDLE_BED)
	b.rect(Rect2(130.0, top - 26.0, COVE_WATER_X - 130.0, 40.0), CLIFF_ROCK)
	b.rect(Rect2(130.0, top - 10.0, COVE_WATER_X - 130.0, 18.0), CLIFF_TOP)

	# Shingle texture stones & cove foam line
	for k in range(36):
		var sx := lerpf(180.0, COVE_WATER_X - 24.0, _h(k * 41 + 9))
		var sy := lerpf(top + 28.0, gy - 28.0, _h(k * 67 + 3))
		b.coarse(Vector2(sx, sy), 2.5 + _h(k * 5) * 3.0, SHINGLE_LIT if k % 2 == 0 else SHINGLE_DARK)
	b.line(Vector2(COVE_WATER_X - 4.0, top + 6.0), Vector2(COVE_WATER_X - 4.0, gy - 6.0), FOAM, 5.0)

	# 3. Fishing boat pulled up on the cove shingle
	_draw_llagut(b, Vector2(COVE_WATER_X - 58.0, top + 84.0), -0.45, true)

	# 4. South rock rim flanking the cove gate, tapering seaward toward the east headland
	var gl: float = float(m.gate_l) if "gate_l" in m else 415.0
	var gr: float = float(m.gate_r) if "gate_r" in m else 765.0
	b.rect(Rect2(r.position.x, gy - 10.0, gl - r.position.x - 14.0, 14.0), CLIFF_ROCK)
	b.polygon(PackedVector2Array([
		Vector2(gr + 14.0, gy - 12.0),
		Vector2(COVE_WATER_X + 6.0, gy - 4.0),
		Vector2(COVE_WATER_X - 24.0, gy + 16.0),
		Vector2(gr + 14.0, gy + 10.0),
	]), CLIFF_ROCK)

	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, TIMBER)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_shingle_cove_off_leash"))
