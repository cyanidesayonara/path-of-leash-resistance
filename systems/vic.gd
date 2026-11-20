class_name Vic
extends RefCounted

# WALK: VIC — the inland market town on a winter morning in thick fog.
#
# Up the screen:
# - Start in a narrow old street of stone houses, shutters closed, fog thick.
# - Into the Plaça Major (el Mercadal): arcaded square, Saturday market stalls
#   of cured sausage (fuet / llonganissa hanging), cheeses, vegetables and
#   winter coats.
# - Past the cathedral and its Romanesque bell tower, half lost in the fog.
# - Out over the old Roman-era bridge over the river Mèder, frost on its
#   parapet.
# - Finish off the leash on the riverside meadow.
#
# The fog is the walk: the campaign sky is fog + morning (Game.fog_amount),
# and a soft distance veil (ShapeBatch.band / glow) fades far things without
# banding. Market people stay out; sunbathers and picnics already stay in.
#
# Signature live event: a loose fuet. The stallholder cries "Ai, ai!" while
# it swings on its hook (>= 0.8 s), then it drops and rolls. Carry it back
# to the stall for a reward; wolf it for a candy-style bleh penalty.
#
# No chase, no boss.

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
const HALF := 300.0
const START := 260.0
const GATE := -5000.0
const SHADOW := Color(0.08, 0.10, 0.16, 0.28)

# --- route zones --------------------------------------------------------------
const STREET_END := -780.0
const MARKET_END := -2100.0
const CATHEDRAL_END := -3180.0
const BRIDGE_END := -4200.0

const STREET_HALF := 168.0
const PLAZA_HALF := 310.0
const BRIDGE_HALF := 120.0
const MEADOW_HALF := 260.0

# --- colours ------------------------------------------------------------------
const STONE := Color(0.72, 0.68, 0.62)
const STONE_LIT := Color(0.82, 0.78, 0.72)
const STONE_DARK := Color(0.48, 0.44, 0.40)
const SETTS := Color(0.58, 0.56, 0.52)
const SETTS_JOINT := Color(0.40, 0.38, 0.36, 0.55)
const PLAZA := Color(0.82, 0.76, 0.64)
const PLAZA_LIT := Color(0.90, 0.84, 0.70)
const PLAZA_SETT := Color(0.74, 0.68, 0.56)
const EARTH := Color(0.42, 0.34, 0.24)
const EARTH_LIT := Color(0.56, 0.46, 0.32)
const REED := Color(0.36, 0.48, 0.28)
const REED_DK := Color(0.24, 0.36, 0.20)
const BANK_STONE := Color(0.58, 0.54, 0.48)
const SHUTTER := Color(0.42, 0.28, 0.18)
const SHUTTER_DK := Color(0.28, 0.18, 0.12)
const WHITEWASH := Color(0.90, 0.88, 0.84)
const TERRACOTTA := Color(0.62, 0.34, 0.22)
const ARCADE := Color(0.70, 0.66, 0.58)
const ARCADE_SHADE := Color(0.42, 0.40, 0.36)
const COLUMN := Color(0.76, 0.72, 0.64)
const COLUMN_DK := Color(0.52, 0.48, 0.42)
const CANVAS := Color(0.86, 0.78, 0.58)
const CANVAS_DK := Color(0.62, 0.52, 0.34)
const WOOD := Color(0.48, 0.32, 0.18)
const WOOD_LIT := Color(0.62, 0.44, 0.26)
const FUET := Color(0.62, 0.28, 0.18)
const FUET_LIT := Color(0.78, 0.40, 0.24)
const CHEESE := Color(0.94, 0.82, 0.42)
const CHEESE_RIND := Color(0.78, 0.62, 0.28)
const VEG_GREEN := Color(0.28, 0.52, 0.24)
const VEG_ORANGE := Color(0.90, 0.48, 0.14)
const COAT_NAVY := Color(0.18, 0.28, 0.42)
const CATH_STONE := Color(0.68, 0.64, 0.58)
const CATH_DK := Color(0.42, 0.38, 0.34)
const TOWER_TOP := Color(0.58, 0.54, 0.50)
const RIVER := Color(0.22, 0.48, 0.58)
const RIVER_LIT := Color(0.38, 0.68, 0.74)
const FROST := Color(0.92, 0.95, 0.98, 0.72)
const GRASS := Color(0.34, 0.46, 0.28)
const GRASS_LIT := Color(0.46, 0.58, 0.34)
const GRASS_DK := Color(0.22, 0.34, 0.20)
const FOG_VEIL := Color(0.78, 0.80, 0.84)
const PILONA := Color(0.18, 0.18, 0.20)
const BIN_GREEN := Color(0.18, 0.42, 0.28)

# --- landmarks ----------------------------------------------------------------
const DARE_POS := Vector2(780.0, -2380.0)

const PRIZE := Vector2(460.0, -2680.0)
const PRIZE_TEXT := "nab the mató off the cheese stall"

const STALL_FUET := Vector2(520.0, -1320.0)
const STALL_CHEESE := Vector2(760.0, -1580.0)
const STALL_VEG := Vector2(500.0, -1760.0)
const STALL_COATS := Vector2(780.0, -1180.0)
const STALL_FUET2 := Vector2(700.0, -1080.0)
const STALL_CHEESE2 := Vector2(540.0, -1500.0)
const STALL_VEG2 := Vector2(780.0, -1880.0)
const STALL_COATS2 := Vector2(520.0, -1980.0)
const STALLS: Array[Vector2] = [
	STALL_FUET, STALL_CHEESE, STALL_VEG, STALL_COATS,
	STALL_FUET2, STALL_CHEESE2, STALL_VEG2, STALL_COATS2,
]
const STALL_KINDS: Array[String] = [
	"fuet", "cheese", "veg", "coats", "fuet", "cheese", "veg", "coats",
]

const CATHEDRAL_RECT := Rect2(720.0, -2920.0, 220.0, 380.0)
const CLOISTER := Rect2(960.0, -2860.0, 130.0, 200.0)
const TOWER_BASE := Vector2(790.0, -2780.0)
const TOWER_BARK_R := 210.0

const BRIDGE_Y0 := -3480.0
const BRIDGE_Y1 := -4020.0
const RIVER_L := 420.0
const RIVER_R := 860.0

# Arcade columns (poles to wrap / mark) along both sides of the Mercadal
const ARCADE_COLS: Array[Vector2] = [
	Vector2(360.0, -900.0), Vector2(360.0, -1080.0), Vector2(360.0, -1260.0),
	Vector2(360.0, -1440.0), Vector2(360.0, -1620.0), Vector2(360.0, -1800.0),
	Vector2(360.0, -1980.0),
	Vector2(920.0, -900.0), Vector2(920.0, -1080.0), Vector2(920.0, -1260.0),
	Vector2(920.0, -1440.0), Vector2(920.0, -1620.0), Vector2(920.0, -1800.0),
	Vector2(920.0, -1980.0),
]
const COL_R := 14.0

const STREET_LAMPS: Array[Vector2] = [
	Vector2(480.0, -120.0), Vector2(800.0, -320.0), Vector2(480.0, -520.0),
	Vector2(800.0, -700.0),
	Vector2(400.0, -2400.0), Vector2(880.0, -2600.0),
	Vector2(500.0, -3400.0), Vector2(780.0, -4100.0),
]

const PLANE_TREES: Array[Vector2] = [
	Vector2(430.0, -950.0), Vector2(850.0, -1100.0), Vector2(450.0, -1900.0),
	Vector2(830.0, -2050.0), Vector2(470.0, -4400.0), Vector2(810.0, -4600.0),
	Vector2(560.0, -4800.0), Vector2(720.0, -4900.0),
]

const PILONES: Array[Vector2] = [
	Vector2(520.0, -760.0), Vector2(760.0, -760.0),
	Vector2(540.0, -2140.0), Vector2(740.0, -2140.0),
]

const BINS: Array[Vector2] = [
	Vector2(470.0, -400.0), Vector2(810.0, -1000.0),
	Vector2(470.0, -1700.0), Vector2(810.0, -2500.0),
	Vector2(560.0, -3800.0),
]

# Parapet blocks on the bridge (solids + frost drawn on top)
const PARAPETS: Array[Rect2] = [
	Rect2(500.0, -3520.0, 22.0, 480.0),
	Rect2(758.0, -3520.0, 22.0, 480.0),
]

# --- sausage event ------------------------------------------------------------
const SAUSAGE_WARN := 1.05
const SAUSAGE_ROLL := 2.4
const SAUSAGE_COOLDOWN := 14.0
const SAUSAGE_FIRST := 3.5
const SAUSAGE_CATCH_R := 28.0
const SAUSAGE_RETURN_R := 48.0
const SAUSAGE_EAT_HOLD := 0.55

# --- fog find-your-human ------------------------------------------------------
const LOST_R := 300.0
const FOUND_R := 95.0


static func _h(k: int) -> float:
	return fposmod(absf(sin(float(k) * 12.9898 + 4.13) * 43758.5453), 1.0)


static func _is_in(list: Array[Vector2], p: Vector2) -> bool:
	for q: Vector2 in list:
		if p.distance_squared_to(q) < 4.0:
			return true
	return false


# --- corridor -----------------------------------------------------------------

static func edge_nodes(_m: Node2D = null) -> Array:
	return [
		{"y": START, "cx": CX, "half": STREET_HALF},
		{"y": -600.0, "cx": CX, "half": STREET_HALF},
		{"y": STREET_END, "cx": CX, "half": PLAZA_HALF},
		{"y": MARKET_END, "cx": CX, "half": PLAZA_HALF},
		{"y": -2400.0, "cx": CX + 40.0, "half": 250.0},
		{"y": CATHEDRAL_END, "cx": CX, "half": 220.0},
		{"y": BRIDGE_Y0, "cx": CX, "half": BRIDGE_HALF},
		{"y": BRIDGE_Y1, "cx": CX, "half": BRIDGE_HALF},
		# soft widen into the meadow (extra nodes so the corridor does not stair-step)
		{"y": BRIDGE_Y1 - 80.0, "cx": CX, "half": 150.0},
		{"y": BRIDGE_Y1 - 180.0, "cx": CX, "half": 200.0},
		{"y": -4500.0, "cx": CX, "half": MEADOW_HALF},
		{"y": GATE, "cx": CX, "half": MEADOW_HALF},
	]


static func _edges_at(y: float) -> Vector2:
	return EdgePath.edges(edge_nodes(), y, CX, HALF)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = [CATHEDRAL_RECT, CLOISTER]
	out.append_array(PARAPETS)
	# arcade back walls (outside the colonnade)
	out.append(Rect2(250.0, MARKET_END - 20.0, 70.0, STREET_END - MARKET_END + 40.0))
	out.append(Rect2(960.0, MARKET_END - 20.0, 70.0, STREET_END - MARKET_END + 40.0))
	# stall bodies
	for s: Vector2 in STALLS:
		out.append(Rect2(s.x - 36.0, s.y - 22.0, 72.0, 44.0))
	# narrow street house fronts (from start down to the plaça mouth)
	out.append(Rect2(250.0, -720.0, 55.0, 980.0))
	out.append(Rect2(975.0, -720.0, 55.0, 980.0))
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = solids(m)
	for c: Vector2 in ARCADE_COLS:
		out.append(Rect2(c.x - COL_R, c.y - COL_R, COL_R * 2.0, COL_R * 2.0))
	return out


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(PLANE_TREES, p):
		return m.TREE_PLANE
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(STREET_LAMPS, p)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		# riverside meadow off-leash
		if p.x > RIVER_L and p.x < RIVER_R and p.y > float(m.GATE_Y) - 280.0:
			return Surfaces.S.WATER
		return Surfaces.S.GRASS
	# bridge river under the span
	if p.y <= BRIDGE_Y0 and p.y >= BRIDGE_Y1:
		var e := _edges_at(p.y)
		if p.x < e.x - 2.0 or p.x > e.y + 2.0:
			return Surfaces.S.WATER
		return Surfaces.S.PAVEMENT
	# meadow approach
	if p.y <= BRIDGE_END:
		return Surfaces.S.GRASS
	# cathedral apron: stone
	if CATHEDRAL_RECT.grow(40.0).has_point(p):
		return Surfaces.S.PAVEMENT
	# plaza + street: town paving (panot / setts)
	var e2 := _edges_at(p.y)
	if p.x >= e2.x - 8.0 and p.x <= e2.y + 8.0:
		return Surfaces.S.PAVEMENT
	if p.y >= STREET_END:
		return Surfaces.S.PAVEMENT
	return Surfaces.S.GRASS


# --- build --------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PRAT DE VIC"
	m.gate_l = 420.0
	m.gate_r = 860.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(640.0, -1500.0)], TYPE_VECTOR2, &"", null)

	m.vic_sausage = {
		"state": "idle", "t": SAUSAGE_FIRST, "pos": STALL_FUET + Vector2(0.0, 8.0),
		"vel": Vector2.ZERO, "swing": 0.0, "carried": false, "eaten": false,
		"returned": false, "eat_t": 0.0, "said": false,
	}
	m.vic_sausage_returned = 0
	m.vic_sausage_eaten = 0
	m.vic_found_human = 0
	m.vic_lost = false
	m.vic_cols_marked = {}
	m.vic_tower_barked = false
	m.vic_sniffs = {}

	for c: Vector2 in ARCADE_COLS:
		m.poles.append(c)
	for lp: Vector2 in STREET_LAMPS:
		m.poles.append(lp)
	for t: Vector2 in PLANE_TREES:
		m.poles.append(t)
	for p: Vector2 in PILONES:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	m.bins = Array(BINS.duplicate(), TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(420.0, -1200.0), Vector2(860.0, -1680.0),
		Vector2(500.0, -2500.0),
		Vector2(520.0, -4480.0), Vector2(760.0, -4620.0), Vector2(600.0, -4780.0),
	], TYPE_VECTOR2, &"", null)

	# mark spots: arcade columns + bridge parapet ends + meadow post
	var marks: Array[Vector2] = []
	for c: Vector2 in ARCADE_COLS:
		marks.append(c)
	marks.append(Vector2(520.0, -3600.0))
	marks.append(Vector2(760.0, -3900.0))
	marks.append(Vector2(640.0, -4700.0))
	marks.append(TOWER_BASE + Vector2(-40.0, 60.0))

	var snacks: Array[Vector2] = [
		Vector2(580.0, -1100.0), Vector2(700.0, -1650.0),
		Vector2(600.0, -2550.0), Vector2(640.0, -3750.0),
		Vector2(620.0, -4500.0),
	]
	return [marks, snacks]


# --- tick ---------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position

	_tick_fog_find(m, dp, hp)
	_tick_sniffs(m, dp)
	_tick_sausage(m, delta, dp)
	_tick_column_marks(m)


static func _tick_fog_find(m: Node2D, dp: Vector2, hp: Vector2) -> void:
	if Game.fog_amount() < 0.35:
		m.vic_lost = false
		return
	var dist := dp.distance_to(hp)
	if not bool(m.vic_lost) and dist >= LOST_R and m.phase == "walk":
		m.vic_lost = true
		m.feed.say(I18n.t("w_where_d_your_human_go"), EventFeed.Tone.LOUD)
	elif bool(m.vic_lost) and dist <= FOUND_R:
		m.vic_lost = false
		m.vic_found_human += 1
		m.award_points(3, I18n.t("w_found_them_3"))
		m.feed.say(I18n.t("w_found_your_human"), EventFeed.Tone.GOOD)
		m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_there_you_are"), Color(0.96, 0.94, 0.88), m.POP_SAY)
		_sfx(m, "star", 1.0)


static func _tick_sniffs(m: Node2D, dp: Vector2) -> void:
	for i in range(STALLS.size()):
		if m.vic_sniffs.has(i):
			continue
		if dp.distance_to(STALLS[i]) < 42.0 and m.dog.velocity.length() < 90.0:
			m.vic_sniffs[i] = true
			m.award_points(1, I18n.t("w_market_sniff_1"))
			_sfx(m, "rustle", 1.05)


static func _tick_column_marks(m: Node2D) -> void:
	# marks near arcade columns count toward the column goal
	for i in range(ARCADE_COLS.size()):
		if m.vic_cols_marked.has(i):
			continue
		var c: Vector2 = ARCADE_COLS[i]
		for spot: Vector2 in m.marks:
			if spot.distance_to(c) < 36.0:
				m.vic_cols_marked[i] = true
				break


static func _tick_sausage(m: Node2D, delta: float, dp: Vector2) -> void:
	var st: Dictionary = m.vic_sausage
	if st.is_empty():
		return
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))
	var pos: Vector2 = st.get("pos", STALL_FUET)

	match state:
		"idle":
			t -= delta
			st["t"] = t
			# arm when the pair is near the fuet stall
			if t <= 0.0 and dp.distance_to(STALL_FUET) < 420.0:
				st["state"] = "swing"
				st["t"] = SAUSAGE_WARN
				st["swing"] = 0.0
				st["said"] = true
				st["pos"] = STALL_FUET + Vector2(0.0, -18.0)
				st["vel"] = Vector2.ZERO
				st["carried"] = false
				st["eaten"] = false
				st["returned"] = false
				st["eat_t"] = 0.0
				m.float_text(STALL_FUET + Vector2(0.0, -40.0), I18n.t("w_ai_ai"), Color(1.0, 0.92, 0.78), m.POP_SAY)
				m.feed.say(I18n.t("w_fuet_coming_loose"), EventFeed.Tone.LOUD)
				_sfx(m, "hiss", 0.7)
		"swing":
			t -= delta
			st["t"] = t
			st["swing"] = sin((1.0 - t / SAUSAGE_WARN) * TAU * 2.2) * 18.0
			st["pos"] = STALL_FUET + Vector2(float(st["swing"]), -18.0)
			if t <= 0.0:
				st["state"] = "roll"
				st["t"] = SAUSAGE_ROLL
				st["vel"] = Vector2(110.0, 55.0)
				st["pos"] = STALL_FUET + Vector2(8.0, 6.0)
				_sfx(m, "hiss", 0.85)
		"roll":
			t -= delta
			st["t"] = t
			var v: Vector2 = st["vel"]
			pos = Vector2(st["pos"]) + v * delta
			v.y = move_toward(v.y, 40.0, 30.0 * delta)
			v.x = move_toward(v.x, 0.0, 18.0 * delta)
			var e := _edges_at(pos.y)
			pos.x = clampf(pos.x, e.x + 20.0, e.y - 20.0)
			st["pos"] = pos
			st["vel"] = v
			_sausage_interact(m, st, dp, delta)
			if t <= 0.0 and not bool(st.get("carried", false)) and not bool(st.get("eaten", false)):
				st["state"] = "ground"
				st["t"] = 0.0
		"ground":
			_sausage_interact(m, st, dp, delta)
			if bool(st.get("eaten", false)) or bool(st.get("returned", false)):
				st["state"] = "done"
				st["t"] = SAUSAGE_COOLDOWN
		"carry":
			st["pos"] = dp + Vector2(0.0, -10.0)
			if dp.distance_to(STALL_FUET) < SAUSAGE_RETURN_R:
				st["carried"] = false
				st["returned"] = true
				st["state"] = "done"
				st["t"] = SAUSAGE_COOLDOWN
				st["pos"] = STALL_FUET + Vector2(0.0, 10.0)
				m.vic_sausage_returned += 1
				m.award_points(5, I18n.t("w_fuet_returned_5"))
				m.combo.add("DELIVERY", 4)
				m.feed.say(I18n.t("w_fuet_back_on_the_hook"), EventFeed.Tone.GOOD)
				m.float_text(STALL_FUET + Vector2(0.0, -36.0), I18n.t("w_gracies_gos"), Color(0.96, 0.94, 0.88), m.POP_SAY)
				_sfx(m, "star", 1.1)
		"done":
			t -= delta
			st["t"] = t
			if t <= 0.0 and not bool(st.get("returned", false)):
				# only re-arm if it was eaten or rolled away unused
				st["state"] = "idle"
				st["t"] = SAUSAGE_COOLDOWN
				st["eaten"] = false
				st["returned"] = false
				st["carried"] = false
	m.vic_sausage = st


static func _sausage_interact(m: Node2D, st: Dictionary, dp: Vector2, delta: float) -> void:
	if bool(st.get("eaten", false)) or bool(st.get("returned", false)) or bool(st.get("carried", false)):
		return
	var pos: Vector2 = st["pos"]
	if dp.distance_to(pos) > SAUSAGE_CATCH_R:
		st["eat_t"] = 0.0
		return
	# pickup / auto-walk: carry it back
	if m.auto_walk or Input.is_action_pressed("pickup") or Input.is_action_just_pressed("pickup"):
		st["carried"] = true
		st["state"] = "carry"
		m.float_text(pos, I18n.t("w_got_the_fuet"), Color(0.85, 1.0, 0.85))
		_sfx(m, "pickup", 0.95)
		return
	# lingering on it without picking up: temptation, candy-style bleh
	st["eat_t"] = float(st.get("eat_t", 0.0)) + delta
	if float(st["eat_t"]) >= SAUSAGE_EAT_HOLD:
		st["eaten"] = true
		st["state"] = "done"
		st["t"] = SAUSAGE_COOLDOWN
		m.vic_sausage_eaten += 1
		m.bones = maxi(0, m.bones - 3)
		m.shake_t = maxf(float(m.shake_t), 0.4)
		m.float_text(pos, I18n.t("w_bleh_not_for_dogs_3"), Color(1.0, 0.5, 0.45))
		m.feed.say(I18n.t("w_ate_the_fuet"), EventFeed.Tone.BAD)
		_sfx(m, "tangle", 0.7)
		m._update_hud()


static func idle_status(m: Node2D) -> String:
	var st := String(m.vic_sausage.get("state", "idle"))
	if st == "swing":
		return I18n.t("vic_fuet_swinging")
	if st == "roll" or st == "ground":
		return I18n.t("vic_fuet_loose")
	if st == "carry":
		return I18n.t("vic_fuet_carry")
	if bool(m.vic_lost):
		return I18n.t("vic_find_human")
	return ""


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	if not bool(m.vic_tower_barked) and p.distance_to(TOWER_BASE) < TOWER_BARK_R:
		m.vic_tower_barked = true
		m.award_points(2, I18n.t("w_bell_tower_bark_2"))
		m.float_text(TOWER_BASE + Vector2(-20.0, -30.0), I18n.t("w_clang"), Color(1.0, 0.92, 0.62), m.POP_SAY)
		_sfx(m, "bell", 0.9)
		return true
	return false


static func _sfx(_m: Node2D, sfx_name: String, pitch: float = 1.0) -> void:
	Sfx.play(sfx_name, pitch)


# --- draw ---------------------------------------------------------------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	_draw_street_houses(b, vt, vb)
	_draw_plaza_arcades(b, vt, vb)
	_draw_cathedral_edges(b, vt, vb)
	_draw_river_banks(b, vt, vb)
	_draw_meadow(b, m, vt, vb)
	b.lod = keep_lod


static func _draw_street_houses(b: ShapeBatch, vt: float, vb: float) -> void:
	# Old street from above: stone houses with tiled roofs, eaves, balconies
	# and shutters, close on both sides.
	var lo := maxf(vt - 40.0, STREET_END)
	var hi := minf(vb + 40.0, START + 40.0)
	if hi <= lo:
		return
	# town blocks fill past the houses (never flat grey)
	b.rect(Rect2(140.0, lo, CX - STREET_HALF - 140.0 - 40.0, hi - lo), STONE_DARK)
	b.rect(Rect2(CX + STREET_HALF + 40.0, lo, 1140.0 - (CX + STREET_HALF + 40.0), hi - lo), STONE_DARK)
	var plot_y := floorf(lo / 130.0) * 130.0
	var idx := int(absf(plot_y) / 130.0)
	while plot_y < hi:
		var y0 := plot_y
		var y1 := minf(plot_y + 130.0, hi)
		if y1 > lo:
			_stone_house(b, Vector2(CX - STREET_HALF - 72.0, (y0 + y1) * 0.5),
				-1.0, 110.0, y1 - y0 - 6.0, idx)
			_stone_house(b, Vector2(CX + STREET_HALF + 72.0, (y0 + y1) * 0.5),
				1.0, 110.0, y1 - y0 - 6.0, idx + 3)
		idx += 1
		plot_y += 130.0


static func _stone_house(b: ShapeBatch, p: Vector2, side: float, deep: float, along: float, seed_i: int) -> void:
	var r := Rect2(p.x - deep * 0.5, p.y - along * 0.5, deep, along)
	b.rect(Rect2(r.position + Vector2(10.0, 12.0), r.size), SHADOW)
	var body := STONE_LIT if seed_i % 3 == 1 else (WHITEWASH if seed_i % 3 == 2 else STONE)
	# path-facing wall strip
	var face_x := r.end.x - 16.0 if side < 0.0 else r.position.x
	b.rect(Rect2(face_x, r.position.y, 16.0, along), body.darkened(0.18))
	b.rect(Rect2(face_x + (2.0 if side > 0.0 else 0.0), r.position.y + 3.0, 12.0, along - 6.0), body)
	# door + shutters on the wall face
	b.rect(Rect2(face_x + 3.0, r.position.y + along * 0.55, 10.0, 22.0), WOOD)
	b.rect(Rect2(face_x + 2.0, r.position.y + 14.0, 12.0, 16.0), SHUTTER)
	b.rect(Rect2(face_x + 3.0, r.position.y + 15.0, 4.0, 6.0), SHUTTER_DK)
	b.rect(Rect2(face_x + 3.0, r.position.y + 23.0, 4.0, 6.0), SHUTTER_DK)
	# balcony rail
	b.rect(Rect2(face_x - (10.0 if side < 0.0 else -2.0), r.position.y + along * 0.28, 12.0, 3.0), Color(0.22, 0.22, 0.26))
	# tiled roof covering the footprint + eaves
	var roof := r.grow(10.0)
	b.rect(roof, TERRACOTTA.darkened(0.12))
	b.rect(roof.grow(-3.0), TERRACOTTA)
	b.rect(Rect2(roof.position.x, roof.position.y, roof.size.x * 0.5, roof.size.y), TERRACOTTA.lightened(0.12))
	b.line(Vector2(roof.get_center().x, roof.position.y + 3.0),
		Vector2(roof.get_center().x, roof.end.y - 3.0), TERRACOTTA.darkened(0.22), 3.0)
	for i in range(5):
		var lx := roof.position.x + 8.0 + float(i) * (roof.size.x / 5.5)
		b.rect(Rect2(lx, roof.position.y + 4.0, 4.0, roof.size.y - 8.0), TERRACOTTA.lightened(0.08))
	# chimney
	b.rect(Rect2(r.position.x + deep * 0.55, r.position.y + along * 0.18, 12.0, 14.0), STONE_DARK)
	b.rect(Rect2(r.position.x + deep * 0.55 - 2.0, r.position.y + along * 0.18 - 3.0, 16.0, 5.0), STONE)


static func _draw_plaza_arcades(b: ShapeBatch, vt: float, vb: float) -> void:
	# Mercadal porticoes from above: roof over the arcade, shade beneath,
	# columns at the edge, shopfronts and café tables behind.
	var lo := maxf(vt - 40.0, MARKET_END)
	var hi := minf(vb + 40.0, STREET_END + 20.0)
	if hi <= lo:
		return
	const WEST_COL := 360.0
	const EAST_COL := 920.0
	const BACK_W := 200.0
	const BACK_E := 1080.0
	# town blocks behind the arcade (never flat grey)
	b.rect(Rect2(140.0, lo, BACK_W - 140.0, hi - lo), STONE_DARK)
	b.rect(Rect2(BACK_E, lo, 1140.0 - BACK_E, hi - lo), STONE_DARK)
	# shade under the portico (floor of the arcade)
	b.rect(Rect2(WEST_COL - 80.0, lo, 80.0, hi - lo), ARCADE_SHADE)
	b.rect(Rect2(EAST_COL, lo, 80.0, hi - lo), ARCADE_SHADE)
	# shopfront wall behind the arcade
	b.rect(Rect2(BACK_W, lo, WEST_COL - 80.0 - BACK_W, hi - lo), STONE_DARK)
	b.rect(Rect2(EAST_COL + 80.0, lo, BACK_E - (EAST_COL + 80.0), hi - lo), STONE_DARK)
	var sy := floorf(lo / 150.0) * 150.0
	var si := 0
	while sy < hi:
		var y1 := minf(sy + 150.0, hi)
		var shop := Color(0.55, 0.30, 0.22) if si % 3 == 0 else (Color(0.28, 0.38, 0.48) if si % 3 == 1 else Color(0.46, 0.36, 0.22))
		if y1 > lo:
			var y0 := maxf(sy, lo)
			b.rect(Rect2(BACK_W + 10.0, y0 + 12.0, 40.0, y1 - y0 - 24.0), shop)
			b.rect(Rect2(BACK_E - 50.0, y0 + 12.0, 40.0, y1 - y0 - 24.0), shop.darkened(0.05))
			# café tables under the arcade
			var tx := WEST_COL - 50.0
			b.circle(Vector2(tx, y0 + 40.0) + Vector2(4.0, 4.0), 10.0, SHADOW)
			b.circle(Vector2(tx, y0 + 40.0), 9.0, WOOD_LIT)
			b.circle(Vector2(EAST_COL + 50.0, y0 + 55.0), 9.0, WOOD_LIT)
		si += 1
		sy += 150.0
	# roof over the whole portico (eaves toward the square)
	var west_roof := Rect2(BACK_W - 6.0, lo, WEST_COL - BACK_W + 18.0, hi - lo)
	var east_roof := Rect2(EAST_COL - 12.0, lo, BACK_E - EAST_COL + 18.0, hi - lo)
	b.rect(Rect2(west_roof.position + Vector2(8.0, 6.0), west_roof.size), SHADOW)
	b.rect(west_roof, TERRACOTTA.darkened(0.1))
	b.rect(west_roof.grow(-4.0), TERRACOTTA)
	b.rect(Rect2(west_roof.position.x, west_roof.position.y, west_roof.size.x * 0.45, west_roof.size.y),
		TERRACOTTA.lightened(0.1))
	b.rect(Rect2(east_roof.position + Vector2(8.0, 6.0), east_roof.size), SHADOW)
	b.rect(east_roof, TERRACOTTA.darkened(0.1))
	b.rect(east_roof.grow(-4.0), TERRACOTTA)
	b.rect(Rect2(east_roof.position.x + east_roof.size.x * 0.55, east_roof.position.y,
		east_roof.size.x * 0.45, east_roof.size.y), TERRACOTTA.lightened(0.1))
	# columns at the arcade edge (drawn again in draw_column; silhouette here)
	for c: Vector2 in ARCADE_COLS:
		if c.y < lo - 20.0 or c.y > hi + 20.0:
			continue
		b.circle(c + Vector2(4.0, 5.0), COL_R + 2.0, SHADOW)
		b.circle(c, COL_R, COLUMN_DK)
		b.circle(c + Vector2(-3.0, -3.0), COL_R * 0.65, COLUMN)


static func _draw_cathedral_edges(b: ShapeBatch, vt: float, vb: float) -> void:
	var lo := maxf(vt - 40.0, CATHEDRAL_END)
	var hi := minf(vb + 40.0, MARKET_END)
	if hi <= lo:
		return
	# stone town closing in toward the cathedral apron
	b.rect(Rect2(180.0, lo, 140.0, hi - lo), STONE_DARK)
	b.rect(Rect2(960.0, lo, 140.0, hi - lo), STONE_DARK)
	var y := floorf(lo / 110.0) * 110.0
	var i := 0
	while y < hi:
		_stone_house(b, Vector2(250.0, y + 55.0), -1.0, 100.0, 96.0, i)
		_stone_house(b, Vector2(1030.0, y + 55.0), 1.0, 100.0, 96.0, i + 2)
		i += 1
		y += 110.0


static func _draw_river_banks(b: ShapeBatch, vt: float, vb: float) -> void:
	# Mèder: soft water and earth banks. y grows down the screen; the bridge
	# runs BRIDGE_Y0 (nearer start) → BRIDGE_Y1 (further along). Water stays
	# OFF the deck (west strip and east strip only).
	if vb < BRIDGE_Y1 - 100.0 or vt > BRIDGE_Y0 + 100.0:
		return
	# top = further along (more negative); bot = toward the start
	var top := maxf(vt - 20.0, BRIDGE_Y1 - 100.0)
	var bot := minf(vb + 20.0, BRIDGE_Y0 + 100.0)
	if bot <= top:
		return
	var deck_l := CX - BRIDGE_HALF
	var deck_r := CX + BRIDGE_HALF
	# riverside earth fills the void either side (never flat grey)
	b.rect(Rect2(140.0, top, deck_l - 140.0, bot - top), EARTH)
	b.rect(Rect2(deck_r, top, 1140.0 - deck_r, bot - top), EARTH)
	b.rect(Rect2(150.0, top, deck_l - 160.0, bot - top), EARTH_LIT)
	b.rect(Rect2(deck_r + 10.0, top, 1130.0 - deck_r, bot - top), EARTH_LIT)
	# soft water west of the deck
	b.band(PackedVector2Array([
		Vector2(RIVER_L - 30.0, top), Vector2(deck_l - 4.0, top),
		Vector2(RIVER_L - 20.0, (top + bot) * 0.5), Vector2(deck_l - 4.0, (top + bot) * 0.5),
		Vector2(RIVER_L - 30.0, bot), Vector2(deck_l - 4.0, bot),
	]), 2, Color(RIVER.r, RIVER.g, RIVER.b, 0.95),
		PackedFloat32Array([0.5, 1.0, 0.5]), PackedFloat32Array([0.25, 1.0]))
	# soft water east of the deck
	b.band(PackedVector2Array([
		Vector2(deck_r + 4.0, top), Vector2(RIVER_R + 30.0, top),
		Vector2(deck_r + 4.0, (top + bot) * 0.5), Vector2(RIVER_R + 20.0, (top + bot) * 0.5),
		Vector2(deck_r + 4.0, bot), Vector2(RIVER_R + 30.0, bot),
	]), 2, Color(RIVER.r, RIVER.g, RIVER.b, 0.95),
		PackedFloat32Array([0.5, 1.0, 0.5]), PackedFloat32Array([1.0, 0.25]))
	# sheen + darker under the span (still off the deck)
	var u0 := maxf(top, BRIDGE_Y1)
	var u1 := minf(bot, BRIDGE_Y0)
	if u1 > u0:
		b.glow(Vector2((RIVER_L + deck_l) * 0.5, (u0 + u1) * 0.5), 55.0,
			Color(RIVER.r * 0.45, RIVER.g * 0.45, RIVER.b * 0.45, 0.55), 0.35)
		b.glow(Vector2((deck_r + RIVER_R) * 0.5, (u0 + u1) * 0.5), 55.0,
			Color(RIVER.r * 0.45, RIVER.g * 0.45, RIVER.b * 0.45, 0.55), 0.35)
		b.glow(Vector2((RIVER_L + deck_l) * 0.5, (u0 + u1) * 0.5), 36.0,
			Color(RIVER_LIT.r, RIVER_LIT.g, RIVER_LIT.b, 0.3), 0.4)
		b.glow(Vector2((deck_r + RIVER_R) * 0.5, (u0 + u1) * 0.5), 36.0,
			Color(RIVER_LIT.r, RIVER_LIT.g, RIVER_LIT.b, 0.3), 0.4)
	# banks: stones and reeds
	var by := floorf(top / 28.0) * 28.0
	while by < bot:
		b.coarse(Vector2(RIVER_L - 18.0 - _h(int(by)) * 20.0, by + 6.0), 7.0 + _h(int(by) + 1) * 5.0, BANK_STONE)
		b.coarse(Vector2(RIVER_R + 18.0 + _h(int(by) + 2) * 20.0, by + 8.0), 6.0 + _h(int(by) + 3) * 5.0, BANK_STONE)
		b.capsule(Vector2(RIVER_L - 8.0, by), Vector2(RIVER_L + 6.0, by + 10.0), 2.5, REED_DK)
		b.capsule(Vector2(RIVER_R + 8.0, by + 2.0), Vector2(RIVER_R - 4.0, by + 12.0), 2.5, REED)
		if int(absf(by) / 28.0) % 3 == 0:
			b.coarse(Vector2(RIVER_L - 40.0, by + 4.0), 10.0, REED)
			b.coarse(Vector2(RIVER_R + 40.0, by + 6.0), 10.0, REED_DK)
		by += 28.0
	# ripples only in the water strips
	var tsec := float(AnimClock.msec()) * 0.001
	for i in range(4):
		var ry := lerpf(top + 20.0, bot - 20.0, _h(i * 7 + 2))
		var west_x := lerpf(RIVER_L, deck_l - 10.0, 0.55) + sin(tsec * 0.6 + float(i)) * 8.0
		var east_x := lerpf(deck_r + 10.0, RIVER_R, 0.55) + cos(tsec * 0.5 + float(i)) * 8.0
		b.band(PackedVector2Array([
			Vector2(west_x - 28.0, ry - 2.0), Vector2(west_x + 28.0, ry - 2.0),
			Vector2(west_x - 28.0, ry + 2.0), Vector2(west_x + 28.0, ry + 2.0),
		]), 2, Color(RIVER_LIT.r, RIVER_LIT.g, RIVER_LIT.b, 0.28),
			PackedFloat32Array([0.15, 0.15]), PackedFloat32Array([0.0, 1.0]))
		b.band(PackedVector2Array([
			Vector2(east_x - 28.0, ry - 2.0), Vector2(east_x + 28.0, ry - 2.0),
			Vector2(east_x - 28.0, ry + 2.0), Vector2(east_x + 28.0, ry + 2.0),
		]), 2, Color(RIVER_LIT.r, RIVER_LIT.g, RIVER_LIT.b, 0.28),
			PackedFloat32Array([0.15, 0.15]), PackedFloat32Array([0.0, 1.0]))


static func _draw_meadow(b: ShapeBatch, m: Node2D, vt: float, vb: float) -> void:
	# meadow lies past the bridge (more negative than BRIDGE_Y1) down to GATE
	if vb < GATE - 40.0 or vt > BRIDGE_Y1 + 80.0:
		return
	var top := maxf(vt - 20.0, GATE - 20.0)
	var bot := minf(vb + 20.0, BRIDGE_Y1 + 60.0)
	if bot <= top:
		return
	# soft grass field that covers the corridor's widen (no stair-step edge)
	b.quad(Vector2(140.0, top), Vector2(1140.0, top), Vector2(1140.0, bot), Vector2(140.0, bot), GRASS)
	b.band(PackedVector2Array([
		Vector2(180.0, top), Vector2(1100.0, top),
		Vector2(200.0, bot), Vector2(1080.0, bot),
	]), 2, GRASS_LIT, PackedFloat32Array([0.45, 0.95]), PackedFloat32Array([1.0, 1.0]))
	# feather toward the bridge so the join is soft, not stepped blocks
	b.band(PackedVector2Array([
		Vector2(200.0, bot - 60.0), Vector2(1080.0, bot - 60.0),
		Vector2(160.0, bot + 20.0), Vector2(1120.0, bot + 20.0),
	]), 2, GRASS, PackedFloat32Array([0.95, 0.0]), PackedFloat32Array([1.0, 1.0]))
	# river bank on the west (soft), dry-stone wall + hedge on the east
	b.band(PackedVector2Array([
		Vector2(RIVER_L - 40.0, top), Vector2(RIVER_L + 50.0, top),
		Vector2(RIVER_L - 40.0, bot), Vector2(RIVER_L + 50.0, bot),
	]), 2, EARTH_LIT, PackedFloat32Array([0.7, 0.7]), PackedFloat32Array([0.0, 0.9]))
	b.rect(Rect2(980.0, top, 18.0, bot - top), STONE_DARK)
	var wy := floorf(top / 36.0) * 36.0
	while wy < bot:
		b.rect(Rect2(976.0, wy + 4.0, 26.0, 10.0), STONE)
		b.rect(Rect2(982.0, wy + 16.0, 8.0, 14.0), STONE_LIT)
		# hedge clumps inside the wall
		b.coarse(Vector2(960.0, wy + 10.0), 12.0, REED)
		wy += 36.0
	# frost on the grass (campaign sky is fog+morning; still frost on clear day)
	for i in range(18):
		var fx := lerpf(260.0, 940.0, _h(i * 5 + 2))
		var fy := lerpf(top + 10.0, bot - 10.0, _h(i * 11 + 4))
		b.circle(Vector2(fx, fy), 2.5 + _h(i * 3 + 1) * 3.5, FROST)
	# benches are drawn by main from m.benches; meadow poplars are poles
	if m != null and float(m.GATE_Y) < vb + 40.0:
		b.glow(Vector2(640.0, float(m.GATE_Y) - 140.0), 160.0, Color(RIVER.r, RIVER.g, RIVER.b, 0.45), 0.4)


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, _ctop: float, vt: float, vb: float) -> void:
	# path surface: street setts, Mercadal sand setts (not Barcelona panots),
	# bridge stone, meadow grass
	var y := minf(vb + 20.0, START)
	var top := maxf(vt - 20.0, GATE)
	while y > top:
		var y2 := maxf(y - 40.0, top)
		var ea := _edges_at(y)
		var eb := _edges_at(y2)
		var mid := (y + y2) * 0.5
		var col := PLAZA if mid < STREET_END and mid > MARKET_END else SETTS
		if mid <= BRIDGE_END:
			col = GRASS_LIT
		elif mid <= BRIDGE_Y0 and mid >= BRIDGE_Y1:
			col = STONE_LIT
		elif mid >= STREET_END:
			col = SETTS
		wc.quad(Vector2(ea.x, y2), Vector2(ea.y, y2), Vector2(eb.y, y), Vector2(eb.x, y), col)
		# sett joints: old street dark; Mercadal pale sand joints
		if mid >= STREET_END:
			wc.line(Vector2(ea.x + 4.0, mid), Vector2(ea.y - 4.0, mid), SETTS_JOINT, 1.0)
		elif mid < STREET_END and mid > MARKET_END:
			wc.line(Vector2(ea.x + 6.0, mid), Vector2(ea.y - 6.0, mid), PLAZA_SETT, 1.2)
			# short cross joints so it reads as sand-coloured setts, not a slab
			var jx := ea.x + 30.0 + fposmod(mid * 0.1, 40.0)
			while jx < ea.y - 20.0:
				wc.line(Vector2(jx, mid - 16.0), Vector2(jx, mid + 16.0), PLAZA_SETT, 1.0)
				jx += 48.0
		y = y2
	# bridge: deck of setts between parapets; cutwaters into the river
	if vt < BRIDGE_Y0 + 40.0 and vb > BRIDGE_Y1 - 40.0:
		_draw_bridge(wc, vt, vb)
	# cathedral body
	if vt < CATHEDRAL_RECT.end.y + 80.0 and vb > CATHEDRAL_RECT.position.y - 80.0:
		_draw_cathedral(wc)


static func _draw_bridge(wc: ShapeBatch, vt: float, vb: float) -> void:
	# From above: deck of setts between two parapets with coping; cutwaters
	# (pointed piers) poke into the river on both sides; arches show only as
	# darker water and shadow beside the piers. Nothing round on the deck.
	var deck_l := CX - BRIDGE_HALF
	var deck_r := CX + BRIDGE_HALF
	var y0 := maxf(vt, BRIDGE_Y1)
	var y1 := minf(vb, BRIDGE_Y0)
	if y1 <= y0:
		return
	# stone deck
	wc.rect(Rect2(deck_l, y0, deck_r - deck_l, y1 - y0), STONE_LIT)
	var gy := BRIDGE_Y1 + 18.0
	while gy < BRIDGE_Y0:
		if gy >= vt and gy <= vb:
			wc.line(Vector2(deck_l + 4.0, gy), Vector2(deck_r - 4.0, gy), SETTS_JOINT, 1.2)
			var jx := deck_l + 28.0
			while jx < deck_r - 20.0:
				wc.line(Vector2(jx, gy - 14.0), Vector2(jx, gy + 14.0), SETTS_JOINT, 1.0)
				jx += 36.0
		gy += 34.0
	# cutwaters poke into the river on both sides; arches read as darker
	# water beside them. No band or circle on the deck itself.
	for i in range(3):
		var ay := BRIDGE_Y0 - 80.0 - float(i) * 145.0
		if ay < vt - 40.0 or ay > vb + 40.0:
			continue
		var west := PackedVector2Array([
			Vector2(deck_l, ay - 18.0), Vector2(deck_l - 54.0, ay), Vector2(deck_l, ay + 18.0),
		])
		var east := PackedVector2Array([
			Vector2(deck_r, ay - 18.0), Vector2(deck_r + 54.0, ay), Vector2(deck_r, ay + 18.0),
		])
		wc.polygon(west, STONE_DARK)
		wc.polygon(PackedVector2Array([
			west[0] + Vector2(-3.0, 5.0), west[1] + Vector2(8.0, 0.0), west[2] + Vector2(-3.0, -5.0),
		]), STONE)
		wc.polygon(east, STONE_DARK)
		wc.polygon(PackedVector2Array([
			east[0] + Vector2(3.0, 5.0), east[1] + Vector2(-8.0, 0.0), east[2] + Vector2(3.0, -5.0),
		]), STONE)
		# arch shadow in the water only
		wc.glow(Vector2(deck_l - 34.0, ay), 22.0, Color(0.05, 0.08, 0.12, 0.5), 0.35)
		wc.glow(Vector2(deck_r + 34.0, ay), 22.0, Color(0.05, 0.08, 0.12, 0.5), 0.35)
		wc.glow(Vector2(deck_l - 34.0, ay), 14.0, Color(RIVER.r * 0.55, RIVER.g * 0.55, RIVER.b * 0.55, 0.45), 0.4)
		wc.glow(Vector2(deck_r + 34.0, ay), 14.0, Color(RIVER.r * 0.55, RIVER.g * 0.55, RIVER.b * 0.55, 0.45), 0.4)
	# parapets with coping and frost
	for r: Rect2 in PARAPETS:
		if r.end.y < vt or r.position.y > vb:
			continue
		wc.rect(Rect2(r.position + Vector2(3, 4), r.size), SHADOW)
		wc.rect(r, STONE_DARK)
		wc.rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 4.0, r.size.y - 4.0), STONE)
		wc.rect(Rect2(r.position.x - 3.0, r.position.y, r.size.x + 6.0, 10.0), FROST)
		for k in range(8):
			var fy := r.position.y + 30.0 + float(k) * 55.0
			if fy < vt or fy > vb:
				continue
			wc.circle(Vector2(r.get_center().x, fy), 3.0, FROST)


static func _draw_cathedral(wc: ShapeBatch) -> void:
	var r := CATHEDRAL_RECT
	# long shadow thrown by the mass
	wc.rect(Rect2(r.position + Vector2(18.0, 22.0), r.size + Vector2(40.0, 30.0)), SHADOW)
	# apron paving
	wc.rect(Rect2(r.position.x - 36.0, r.position.y - 24.0, r.size.x + 72.0, r.size.y + 70.0), STONE)
	# nave walls under a pitched tiled roof
	wc.rect(r, CATH_DK)
	wc.rect(r.grow(-8.0), CATH_STONE)
	# pitched roof with ridge along the nave
	var roof := r.grow(12.0)
	wc.rect(roof, TERRACOTTA.darkened(0.08))
	wc.rect(Rect2(roof.position.x, roof.position.y, roof.size.x * 0.5, roof.size.y), TERRACOTTA.lightened(0.1))
	wc.rect(Rect2(roof.position.x + roof.size.x * 0.5, roof.position.y, roof.size.x * 0.5, roof.size.y), TERRACOTTA.darkened(0.12))
	wc.line(Vector2(roof.get_center().x, roof.position.y + 4.0),
		Vector2(roof.get_center().x, roof.end.y - 4.0), TERRACOTTA.lightened(0.22), 4.0)
	for i in range(6):
		var lx := roof.position.x + 12.0 + float(i) * (roof.size.x / 6.5)
		wc.rect(Rect2(lx, roof.position.y + 6.0, 5.0, roof.size.y - 12.0), TERRACOTTA.lightened(0.06))
	# rounded apse at the north (more negative y) end
	var apse := Vector2(r.get_center().x, r.position.y)
	wc.circle(apse + Vector2(8.0, 8.0), r.size.x * 0.42, SHADOW)
	wc.circle(apse, r.size.x * 0.42, TERRACOTTA.darkened(0.05))
	wc.circle(apse - Vector2(4.0, 4.0), r.size.x * 0.30, TERRACOTTA.lightened(0.08))
	# facade steps at the south end
	for k in range(4):
		var sw := r.size.x - 30.0 - float(k) * 12.0
		wc.rect(Rect2(r.get_center().x - sw * 0.5, r.end.y - 6.0 - float(k) * 9.0, sw, 9.0),
			STONE_LIT if k % 2 == 0 else STONE_DARK)
	# cloister beside the nave (west): open square with arcade roof around a garth
	var cl := CLOISTER
	wc.rect(Rect2(cl.position + Vector2(8.0, 10.0), cl.size), SHADOW)
	wc.rect(cl, STONE_DARK)
	wc.rect(cl.grow(-22.0), GRASS_DK)
	wc.rect(cl.grow(-28.0), GRASS)
	# cloister walk roof as a ring
	wc.rect(Rect2(cl.position.x, cl.position.y, cl.size.x, 18.0), TERRACOTTA)
	wc.rect(Rect2(cl.position.x, cl.end.y - 18.0, cl.size.x, 18.0), TERRACOTTA)
	wc.rect(Rect2(cl.position.x, cl.position.y, 18.0, cl.size.y), TERRACOTTA)
	wc.rect(Rect2(cl.end.x - 18.0, cl.position.y, 18.0, cl.size.y), TERRACOTTA)
	# Romanesque bell tower: square shaft, arched openings, pyramid roof
	var fog := Game.fog_amount()
	var base := TOWER_BASE
	wc.rect(Rect2(base.x - 42.0 + 10.0, base.y - 300.0 + 12.0, 84.0, 300.0), SHADOW)
	wc.rect(Rect2(base.x - 42.0, base.y - 300.0, 84.0, 300.0), CATH_DK)
	wc.rect(Rect2(base.x - 34.0, base.y - 288.0, 68.0, 280.0), CATH_STONE)
	# arched openings on every side of the shaft
	for k in range(5):
		var ty := base.y - 60.0 - float(k) * 46.0
		wc.rect(Rect2(base.x - 18.0, ty, 12.0, 22.0), Color(0.14, 0.14, 0.16, 0.85))
		wc.rect(Rect2(base.x + 6.0, ty, 12.0, 22.0), Color(0.14, 0.14, 0.16, 0.85))
		wc.circle(Vector2(base.x - 12.0, ty), 6.0, Color(0.14, 0.14, 0.16, 0.85))
		wc.circle(Vector2(base.x + 12.0, ty), 6.0, Color(0.14, 0.14, 0.16, 0.85))
	# pyramid roof
	var peak := PackedVector2Array([
		Vector2(base.x - 48.0, base.y - 300.0),
		Vector2(base.x, base.y - 360.0),
		Vector2(base.x + 48.0, base.y - 300.0),
	])
	wc.polygon(peak, TOWER_TOP.darkened(0.1))
	wc.polygon(PackedVector2Array([
		peak[0] + Vector2(8.0, 0.0), peak[1] + Vector2(0.0, 8.0), peak[2] + Vector2(-8.0, 0.0),
	]), TOWER_TOP)
	wc.line(peak[1], Vector2(base.x, base.y - 300.0), TOWER_TOP.lightened(0.15), 2.0)
	# fog eats only the top; the base stays clear
	if fog > 0.25:
		var a := clampf(fog, 0.0, 1.0) * 0.55
		wc.glow(base + Vector2(0.0, -330.0), 100.0, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a), 0.35)
		wc.glow(base + Vector2(0.0, -370.0), 120.0, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a * 0.85), 0.35)


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(ARCADE_COLS, p):
		wc.circle(p, COL_R + 2.0, SHADOW)
		wc.circle(p, COL_R, COLUMN_DK)
		wc.circle(p + Vector2(-3.0, -3.0), COL_R * 0.7, COLUMN)
		return
	if _is_in(PILONES, p):
		# Barcelona pilona
		wc.circle(p, 9.0, SHADOW)
		wc.circle(p, 8.0, PILONA)
		wc.circle(p + Vector2(-2.0, -2.0), 3.0, Color(0.35, 0.35, 0.38))
		return
	if _is_in(STREET_LAMPS, p):
		wc.circle(p, 6.0, SHADOW)
		wc.circle(p, 5.0, Color(0.28, 0.28, 0.30))
		return


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	# marking spots: a cast-iron pilona (or waymarker on the meadow)
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# a dropped fuet snack on the paving
	wc.circle(kp + Vector2(1.5, 1.5), 7.0, SHADOW)
	wc.circle(kp, 6.0, FUET)
	wc.circle(kp + Vector2(-2.0, -2.0), 3.0, FUET_LIT)


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_stalls(wc, vt, vb)
	_draw_sausage(m, wc, vt, vb)
	_draw_market_people(m, wc, vt, vb)
	_draw_fog_veil(m, wc, vt, vb)


static func _draw_stalls(wc: ShapeBatch, vt: float, vb: float) -> void:
	for i in range(STALLS.size()):
		var s: Vector2 = STALLS[i]
		if s.y < vt - 40.0 or s.y > vb + 40.0:
			continue
		var kind := STALL_KINDS[i]
		wc.rect(Rect2(s.x - 46.0 + 5.0, s.y - 34.0 + 5.0, 92.0, 60.0), SHADOW)
		# striped awning
		wc.rect(Rect2(s.x - 46.0, s.y - 34.0, 92.0, 18.0), CANVAS)
		for stripe in range(8):
			var sx := s.x - 44.0 + float(stripe) * 11.0
			wc.rect(Rect2(sx, s.y - 32.0, 6.0, 14.0), CANVAS_DK if stripe % 2 == 0 else CANVAS.lightened(0.1))
		# counter
		wc.rect(Rect2(s.x - 40.0, s.y - 12.0, 80.0, 34.0), WOOD)
		wc.rect(Rect2(s.x - 38.0, s.y - 10.0, 76.0, 6.0), WOOD_LIT)
		match kind:
			"fuet":
				for k in range(7):
					var hx := s.x - 30.0 + float(k) * 10.0
					wc.line(Vector2(hx, s.y - 34.0), Vector2(hx, s.y - 16.0), Color(0.18, 0.16, 0.14), 1.4)
					wc.capsule(Vector2(hx, s.y - 16.0), Vector2(hx + 2.0, s.y - 2.0), 5.5, FUET)
					wc.circle(Vector2(hx - 1.0, s.y - 18.0), 3.0, FUET_LIT)
			"cheese":
				for k in range(5):
					var cx := s.x - 26.0 + float(k) * 13.0
					wc.circle(Vector2(cx, s.y + 2.0), 10.0, CHEESE_RIND)
					wc.circle(Vector2(cx - 2.0, s.y), 7.0, CHEESE)
			"veg":
				wc.rect(Rect2(s.x - 28.0, s.y - 2.0, 22.0, 16.0), WOOD_LIT)
				wc.circle(s + Vector2(-16.0, 4.0), 8.0, VEG_GREEN)
				wc.circle(s + Vector2(-2.0, 8.0), 7.0, VEG_ORANGE)
				wc.circle(s + Vector2(14.0, 3.0), 8.0, VEG_GREEN)
				wc.circle(s + Vector2(4.0, -2.0), 5.0, Color(0.72, 0.22, 0.18))
				wc.circle(s + Vector2(22.0, 6.0), 6.0, VEG_ORANGE)
			"coats":
				wc.line(Vector2(s.x - 28.0, s.y - 14.0), Vector2(s.x + 28.0, s.y - 14.0), Color(0.2, 0.2, 0.22), 2.0)
				wc.rect(Rect2(s.x - 26.0, s.y - 12.0, 18.0, 28.0), COAT_NAVY)
				wc.rect(Rect2(s.x - 4.0, s.y - 12.0, 18.0, 28.0), Color(0.42, 0.22, 0.18))
				wc.rect(Rect2(s.x + 16.0, s.y - 10.0, 16.0, 26.0), Color(0.28, 0.32, 0.28))


static func _draw_sausage(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var st: Dictionary = m.vic_sausage
	if st.is_empty():
		return
	var state := String(st.get("state", "idle"))
	if state == "idle" or state == "done":
		return
	if bool(st.get("eaten", false)) or bool(st.get("returned", false)):
		return
	var p: Vector2 = st["pos"]
	if p.y < vt - 30.0 or p.y > vb + 30.0:
		return
	var swing := float(st.get("swing", 0.0))
	# larger silhouette so the swing and roll read through fog
	if state == "swing":
		wc.line(STALL_FUET + Vector2(swing * 0.4, -30.0), p, Color(0.18, 0.16, 0.14), 2.0)
		wc.glow(p, 22.0, Color(FUET_LIT.r, FUET_LIT.g, FUET_LIT.b, 0.28))
	elif state == "roll" or state == "loose":
		wc.glow(p, 18.0, Color(FUET.r, FUET.g, FUET.b, 0.22))
	wc.circle(p + Vector2(3.0, 3.0), 12.0, SHADOW)
	wc.capsule(p + Vector2(-8.0, 0.0), p + Vector2(8.0, 2.0), 7.0, FUET)
	wc.circle(p + Vector2(-3.0, -3.0), 4.5, FUET_LIT)
	wc.circle(p + Vector2(0.0, -8.0), 2.5, Color(0.88, 0.88, 0.82))


static func _draw_market_people(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if not Outdoors.shops_open(Game.weather, Game.hour):
		return
	# stallholders behind each stall + shoppers queuing in the square
	var folks: Array = []
	for i in range(STALLS.size()):
		folks.append(STALLS[i] + Vector2(-42.0 if i % 2 == 0 else 44.0, 6.0))
		folks.append(STALLS[i] + Vector2(0.0, 38.0 + float(i % 3) * 14.0))
		folks.append(STALLS[i] + Vector2(18.0, 52.0 + float((i + 1) % 3) * 12.0))
	folks.append_array([
		Vector2(640.0, -1400.0), Vector2(600.0, -1850.0), Vector2(680.0, -1200.0),
		Vector2(610.0, -1600.0), Vector2(700.0, -1750.0),
	])
	var cam: Vector2 = m.dog.global_position if m.dog != null else Vector2(CX, (vt + vb) * 0.5)
	var fog := Game.fog_amount()
	for i in range(folks.size()):
		var p: Vector2 = folks[i]
		if p.y < vt - 20.0 or p.y > vb + 20.0:
			continue
		var dist := cam.distance_to(p)
		if fog > 0.35 and dist > 340.0:
			continue
		NpcFigure.person(wc, p, Vector2(0.0, -1.0), 5100 + i, -1.0, {"arms": NpcFigure.Arms.SIDE})


static func _draw_fog_veil(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	# Soft distance veil ahead of the pair. Near ground (telegraph distance) stays
	# clear so hazards and the loose fuet never vanish into the grey.
	var fog := Game.fog_amount()
	if fog < 0.15:
		return
	var cam_y: float = m.dog.global_position.y if m.dog != null else (vt + vb) * 0.5
	# veil starts beyond ~280 px (past bark / plant telegraph)
	var ahead := cam_y - 320.0
	if ahead < vb + 40.0 and ahead > vt - 100.0:
		var a := fog * 0.38
		var y0 := ahead - 90.0
		var y1 := ahead + 40.0
		wc.band(PackedVector2Array([
			Vector2(180.0, y0), Vector2(1100.0, y0),
			Vector2(180.0, y1), Vector2(1100.0, y1),
		]), 2, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a),
			PackedFloat32Array([0.0, 1.0]), PackedFloat32Array([1.0, 1.0]))
	# tower top only, and only when she is still far from it
	if fog > 0.4 and TOWER_BASE.y < vb + 40.0 and TOWER_BASE.y > vt - 80.0:
		var near := absf(cam_y - TOWER_BASE.y)
		if near > 260.0:
			wc.glow(TOWER_BASE + Vector2(0.0, -220.0), 100.0,
				Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, fog * 0.40))


static func draw_overhead(m: Node2D, ci: Object) -> void:
	# arcade awning strips + tree crowns are drawn via tree_kind / poles;
	# soft fog glow over the far cathedral when overhead follows the camera
	var fog := Game.fog_amount()
	if fog < 0.25:
		return
	var c: ShapeBatch = ci if ci is ShapeBatch else null
	if c == null:
		return
	c.glow(TOWER_BASE + Vector2(0.0, -160.0), 100.0,
		Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, fog * 0.35))


static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var specs: Array = [
		[-200.0, true, "home"], [-400.0, false, "shop"], [-600.0, true, "home"],
		[-1000.0, true, "shop"], [-1400.0, false, "bar"], [-2300.0, false, "tv"],
	]
	for i in range(specs.size()):
		var s: Array = specs[i]
		var e := _edges_at(float(s[0]))
		var west: bool = s[1]
		out.append(NightFronts.front(
			Vector2(e.x if west else e.y, float(s[0])),
			1.0 if west else -1.0,
			String(s[2]), 5200 + i))
	return out


static func draw_freedom(m: Node2D, c: Object) -> void:
	# riverside meadow: frost on the grass, soft dark river edge
	var r: Rect2 = m._freedom_rect()
	var gy := r.end.y
	var top := r.position.y
	var b := ShapeBatch.new()
	b.lod = true
	b.rect(Rect2(r.position.x - 40.0, top - 20.0, r.size.x + 80.0, r.size.y + 40.0), GRASS)
	b.rect(r.grow(-20.0), GRASS_LIT)
	# frost sparkle on the grass
	for i in range(28):
		var fx := lerpf(r.position.x + 20.0, r.end.x - 20.0, _h(i * 3 + 1))
		var fy := lerpf(top + 20.0, gy - 20.0, _h(i * 7 + 3))
		b.circle(Vector2(fx, fy), 2.0 + _h(i * 9 + 5) * 2.0, FROST)
	b.band(PackedVector2Array([
		Vector2(RIVER_L, top - 10.0), Vector2(RIVER_R, top - 10.0),
		Vector2(RIVER_L, gy + 10.0), Vector2(RIVER_R, gy + 10.0),
	]), 2, RIVER, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.9, 0.15]))
	b.glow(Vector2(640.0, (top + gy) * 0.5), 140.0, Color(RIVER.r, RIVER.g, RIVER.b, 0.35))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_riverside_meadow_off_leash"))
