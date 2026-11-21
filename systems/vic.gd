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
# the rest of the Saturday market, filling out the two rows
const STALL_BREAD := Vector2(530.0, -1150.0)
const STALL_FLOWERS := Vector2(780.0, -1420.0)
const STALL_VEG3 := Vector2(510.0, -1630.0)
const STALL_BREAD2 := Vector2(770.0, -1740.0)
const STALLS: Array[Vector2] = [
	STALL_FUET, STALL_CHEESE, STALL_VEG, STALL_COATS,
	STALL_FUET2, STALL_CHEESE2, STALL_VEG2, STALL_COATS2,
	STALL_BREAD, STALL_FLOWERS, STALL_VEG3, STALL_BREAD2,
]
const STALL_KINDS: Array[String] = [
	"fuet", "cheese", "veg", "coats", "fuet", "cheese", "veg", "coats",
	"bread", "flowers", "veg", "bread",
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
	Vector2(540.0, -4150.0),
]

# Parapet blocks on the bridge (solids + frost drawn on top)
const PARAPETS: Array[Rect2] = [
	Rect2(498.0, BRIDGE_Y1, 22.0, BRIDGE_Y0 - BRIDGE_Y1),
	Rect2(760.0, BRIDGE_Y1, 22.0, BRIDGE_Y0 - BRIDGE_Y1),
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
	if _nodes.is_empty():
		_nodes = edge_nodes()
	return EdgePath.edges(_nodes, y, CX, HALF)


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
	# by the cathedral's west wall, out on the square
	marks.append(Vector2(696.0, -2600.0))

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
#
# Three passes, each the walk's existing batch: the edge layer (everything
# past the corridor: the houses, the cathedral precinct, the tanneries, the
# Mèder and the fields; cached), the ground (the corridor's paving, the
# portico shade, the stalls, the cathedral and the bridge; cached), and the
# live pass (the loose fuet, the people, the water's glints, the fog veil).
# Variety comes from hashes of position, never the RNG.

const SIDES: Array[float] = [-1.0, 1.0]
const FAR_L := -300.0
const FAR_R := 1580.0
const FACE := 20.0                     # the house fronts, seen a little from the street
const LOT_H := 112.0
const PRECINCT_Y0 := -2560.0           # east of the cathedral: its precinct, from here
const PRECINCT_Y1 := -3010.0           # up to here
const BANK_S := -3440.0                # the south bank, down to the water at BRIDGE_Y0
const BANK_N := -4070.0                # the north bank, from the water at BRIDGE_Y1
const RAMP_END := -4200.0              # the bridge's cobbled ramp gives way to grass
# the cathedral inside CATHEDRAL_RECT: the nave, its apse, the Romanesque tower
const NAVE := Rect2(742.0, -2858.0, 146.0, 296.0)
const APSE_R := 56.0
const TOWER_RECT := Rect2(866.0, -2916.0, 70.0, 70.0)
const PIERS: Array[float] = [-3615.0, -3750.0, -3885.0]

const WARM := Color(1.0, 0.86, 0.62)
const COOL := Color(0.52, 0.58, 0.76)
const SOCLE := Color(0.46, 0.42, 0.38)
const WINDOW_DARK := Color(0.16, 0.15, 0.16)
const IRON := Color(0.15, 0.15, 0.17)
const GERANIUM := Color(0.88, 0.20, 0.24)
const LEAF := Color(0.24, 0.42, 0.24)
const RIME := Color(0.90, 0.94, 0.98, 0.42)
const PATI := Color(0.46, 0.43, 0.38)
const RIVER_DEEP := Color(0.16, 0.30, 0.34)
const RIVER_SHALLOW := Color(0.34, 0.46, 0.42)
const GRAVEL := Color(0.66, 0.62, 0.54)
const MUD := Color(0.36, 0.30, 0.24)
const FIELD := Color(0.44, 0.34, 0.24)
const FIELD_LIT := Color(0.54, 0.43, 0.30)
const HIDE := Color(0.70, 0.54, 0.38)
const VAT := Color(0.30, 0.20, 0.14)
const LIMESTONE := Color(0.80, 0.76, 0.68)
const LIMESTONE_DK := Color(0.68, 0.64, 0.57)
const SAND_SETT: Array[Color] = [Color(0.86, 0.79, 0.64), Color(0.83, 0.76, 0.61), Color(0.88, 0.82, 0.68), Color(0.80, 0.73, 0.59)]
const GREY_SETT: Array[Color] = [Color(0.56, 0.54, 0.51), Color(0.60, 0.57, 0.53), Color(0.52, 0.50, 0.48), Color(0.58, 0.54, 0.48)]
const DECK_SETT: Array[Color] = [Color(0.74, 0.70, 0.63), Color(0.70, 0.66, 0.59), Color(0.77, 0.73, 0.66)]
const FLAG_COLS: Array[Color] = [Color(0.76, 0.72, 0.65), Color(0.72, 0.68, 0.61), Color(0.79, 0.75, 0.68), Color(0.70, 0.65, 0.58)]
# stone and render down the old street and by the cathedral
const STONES: Array[Color] = [
	Color(0.76, 0.70, 0.60), Color(0.70, 0.66, 0.60), Color(0.84, 0.78, 0.66),
	Color(0.78, 0.66, 0.52), Color(0.72, 0.62, 0.54), Color(0.80, 0.74, 0.64),
]
# the Mercadal's painted fronts over the porticoes
const PLAZA_RENDERS: Array[Color] = [
	Color(0.92, 0.78, 0.52), Color(0.90, 0.71, 0.62), Color(0.93, 0.89, 0.79),
	Color(0.80, 0.83, 0.76), Color(0.88, 0.63, 0.45), Color(0.85, 0.80, 0.84),
]
const ROOF_TILES: Array[Color] = [
	Color(0.62, 0.36, 0.25), Color(0.56, 0.33, 0.24), Color(0.66, 0.42, 0.30), Color(0.54, 0.35, 0.28),
]
const SHUTTERS: Array[Color] = [Color(0.40, 0.27, 0.17), Color(0.26, 0.40, 0.31), Color(0.33, 0.23, 0.19), Color(0.52, 0.38, 0.24)]
const DOORS: Array[Color] = [Color(0.34, 0.22, 0.14), Color(0.22, 0.32, 0.27), Color(0.42, 0.27, 0.16), Color(0.26, 0.26, 0.34)]
const SHOP_SIGNS: Array[Color] = [Color(0.62, 0.20, 0.18), Color(0.18, 0.34, 0.46), Color(0.24, 0.42, 0.30), Color(0.56, 0.40, 0.18), Color(0.36, 0.22, 0.34)]
# striped awnings: [stripe, ground]
const AWNINGS: Array = [
	[Color(0.78, 0.18, 0.16), Color(0.95, 0.93, 0.88)],
	[Color(0.18, 0.46, 0.32), Color(0.94, 0.92, 0.86)],
	[Color(0.20, 0.36, 0.62), Color(0.95, 0.94, 0.90)],
	[Color(0.90, 0.66, 0.16), Color(0.96, 0.93, 0.84)],
	[Color(0.62, 0.20, 0.36), Color(0.95, 0.92, 0.88)],
]
const COAT_COLS: Array[Color] = [Color(0.18, 0.26, 0.40), Color(0.44, 0.22, 0.18), Color(0.30, 0.34, 0.28), Color(0.56, 0.46, 0.32), Color(0.22, 0.22, 0.24), Color(0.60, 0.20, 0.24)]
const WINTER_TOPS: Array[Color] = [Color(0.20, 0.26, 0.38), Color(0.46, 0.24, 0.20), Color(0.30, 0.36, 0.30), Color(0.62, 0.52, 0.38), Color(0.24, 0.24, 0.27), Color(0.52, 0.30, 0.42), Color(0.70, 0.66, 0.58)]
const BLOOMS: Array[Color] = [Color(0.90, 0.24, 0.30), Color(0.96, 0.84, 0.30), Color(0.94, 0.94, 0.96), Color(0.70, 0.40, 0.80)]
const BREAD := Color(0.80, 0.56, 0.28)
const HATS: Array[Color] = [Color(0.70, 0.20, 0.20), Color(0.22, 0.30, 0.50), Color(0.86, 0.84, 0.78), Color(0.30, 0.42, 0.30)]

static var _nodes: Array = []
static var _recs := {}
static var _recs_key: Array = []
const CHUNK := 156.0


static func _hi(k: int) -> int:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16)) % 1000003


static func _lot_hash(k: int, side: float, salt: int) -> int:
	return _hi(k * 7919 + int(side + 2.0) * 104729 + salt * 1299709)


# rime on everything out in the open: the fog morning is a frosty one
static func _frosty() -> bool:
	return Game.fog_amount() >= 0.3 or Game.weather == "snow"


# shadows soften in the fog: the light is everywhere
static func _shade_a(a: float) -> float:
	return a * (1.0 - clampf(Game.fog_amount(), 0.0, 1.0) * 0.55)


static func _edge_x(y: float, side: float) -> float:
	var e := _edges_at(y)
	return e.x if side < 0.0 else e.y


# The corridor between y0 and y1 (y0 above) in quads 20 px tall, each joining
# the edges at its own top and bottom, so a widening reads as a curve.
static func _corridor(wc: ShapeBatch, y0: float, y1: float, col: Color, inset := 0.0) -> void:
	var y := y0
	var ea := _edges_at(y)
	while y < y1:
		var yn := minf(y + 20.0, y1)
		var eb := _edges_at(yn)
		wc.quad(Vector2(ea.x + inset, y), Vector2(ea.y - inset, y), Vector2(eb.y - inset, yn), Vector2(eb.x + inset, yn), col)
		ea = eb
		y = yn


# Everything from the corridor's edge (plus `from`) out past the screen on one
# side, in the same 20 px quads.
static func _outside(b: ShapeBatch, side: float, y0: float, y1: float, col: Color, from := 0.0) -> void:
	var far := FAR_L if side < 0.0 else FAR_R
	var y := y0
	var xa := _edge_x(y, side) + side * from
	while y < y1:
		var yn := minf(y + 20.0, y1)
		var xb := _edge_x(yn, side) + side * from
		b.quad(Vector2(xa, y), Vector2(far, y), Vector2(far, yn), Vector2(xb, yn), col)
		xa = xb
		y = yn


# Setts laid in courses across the corridor, each stone its own shade of the
# palette over a joint-coloured bed. Rows are `rh` deep and stones `sw` long,
# every course offset from the last.
static func _setts(wc: ShapeBatch, y0: float, y1: float, rh: float, sw: float, cols: Array[Color], joint: Color, salt: int, x_lo := -INF, x_hi := INF) -> void:
	if y1 <= y0:
		return
	_corridor(wc, y0, y1, joint)
	var r := int(floorf(y0 / rh))
	var ry := float(r) * rh
	while ry < y1:
		var a := maxf(ry, y0)
		var z := minf(ry + rh, y1)
		# the joint only where the course really ends, not where a chunk cuts it
		var ti := 1.0 if a == ry else 0.0
		var bi := 1.0 if z == ry + rh else 0.0
		if z - a > 0.5:
			var e := _edges_at(ry + rh * 0.5)
			var xl := maxf(e.x + 1.0, x_lo)
			var xr := minf(e.y - 1.0, x_hi)
			var row_w := sw * (0.82 + 0.36 * float(_hi(r * 17 + salt) % 100) / 100.0)
			var off := float(_hi(r * 31 + salt) % 1000) / 1000.0 * row_w
			var x := floorf((xl - off) / row_w) * row_w + off
			var i := 0
			while x < xr:
				var sx0 := maxf(x + 1.0, xl)
				var sx1 := minf(x + row_w - 1.0, xr)
				if sx1 - sx0 > 1.5:
					var hk := _hi(r * 131 + i * 7 + salt)
					var c: Color = cols[hk % cols.size()]
					var t := float((hk / 7) % 11) / 10.0 - 0.5
					c = c.lightened(t * 0.12) if t > 0.0 else c.darkened(-t * 0.12)
					wc.rect(Rect2(sx0, a + ti, sx1 - sx0, z - a - ti - bi), c)
					if ti > 0.0:
						# the worn top of the stone catches the light on its upper edge
						wc.rect(Rect2(sx0, a + 1.0, sx1 - sx0, 1.2), Color(1.0, 0.98, 0.92, 0.10))
				x += row_w
				i += 1
		r += 1
		ry += rh


# Large flagstones in staggered courses, for the cathedral square and the
# arcades' floors.
static func _flags(wc: ShapeBatch, y0: float, y1: float, x0: float, x1: float, rh: float, fw: float, cols: Array[Color], joint: Color, salt: int) -> void:
	if y1 <= y0 or x1 <= x0:
		return
	wc.rect(Rect2(x0, y0, x1 - x0, y1 - y0), joint)
	var r := int(floorf(y0 / rh))
	var ry := float(r) * rh
	while ry < y1:
		var a := maxf(ry, y0)
		var z := minf(ry + rh, y1)
		var off := fw * 0.5 * float(r % 2)
		var x := floorf((x0 - off) / fw) * fw + off
		var i := 0
		while x < x1:
			var w := fw * (0.7 + 0.6 * float(_hi(r * 53 + i * 11 + salt) % 100) / 100.0)
			var sx0 := maxf(x + 1.5, x0)
			var sx1 := minf(x + w - 1.5, x1)
			var ti := 1.5 if a == ry else 0.0
			var bi := 1.5 if z == ry + rh else 0.0
			if sx1 - sx0 > 2.0 and z - a > 0.5:
				var hk := _hi(r * 97 + i * 13 + salt)
				var c: Color = cols[hk % cols.size()]
				wc.rect(Rect2(sx0, a + ti, sx1 - sx0, z - a - ti - bi), c)
				if ti > 0.0:
					wc.rect(Rect2(sx0, a + 1.5, sx1 - sx0, 1.5), Color(1.0, 0.98, 0.92, 0.12))
				if hk % 7 == 0 and ti > 0.0 and bi > 0.0:
					# an old crack across the slab
					wc.line(Vector2(sx0 + 3.0, a + 4.0), Vector2(sx1 - 4.0, z - 4.0), Color(0.30, 0.27, 0.24, 0.30), 1.0)
			x += w
			i += 1
		r += 1
		ry += rh


static func _sweep_shadow(b: ShapeBatch, r: Rect2, v: Vector2, col: Color) -> void:
	# a box's shadow thrown along v (down and to the right): its footprint
	# swept along the light, as one convex hexagon
	b.polygon(PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y) + v,
		r.end + v, Vector2(r.position.x, r.end.y) + v, Vector2(r.position.x, r.end.y),
	]), col)


# --- the edge layer -------------------------------------------------------------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 60.0, GATE - 60.0)
	var hi := minf(vb + 60.0, START + 760.0)
	if hi > lo:
		# a dark bed under the roofs, so no gap between houses shows through
		var town_lo := maxf(lo, CATHEDRAL_END)
		if hi > town_lo:
			for side: float in SIDES:
				_outside(b, side, town_lo, hi, Color(0.24, 0.21, 0.20))
			for side: float in SIDES:
				_town(b, side, lo, hi)
			if hi > PRECINCT_Y1 and lo < PRECINCT_Y0:
				_cached(b, ["precinct"], _precinct.bind(-1.0e9, 1.0e9))
		if hi > CATHEDRAL_END and lo < BRIDGE_Y0:
			_cached(b, ["riverside"], _riverside.bind(-1.0e9, 1.0e9))
		if hi > BRIDGE_Y1 - 10.0 and lo < BRIDGE_Y0 + 10.0:
			_cached(b, ["river"], _river.bind(-1.0e9, 1.0e9))
		if hi > GATE - 60.0 and lo < BRIDGE_Y1:
			_cached(b, ["meadow"], _meadow.bind(-1.0e9, 1.0e9))
	b.lod = keep_lod


static func _lot_y(k: int, side: float) -> float:
	return float(k) * LOT_H + float(_lot_hash(k, side, 1) % 40) - 20.0


static func _town(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	var top := CATHEDRAL_END
	var bot := START + 760.0
	var k0 := int(floorf(maxf(lo, top) / LOT_H)) - 1
	var k1 := int(floorf(minf(hi, bot) / LOT_H)) + 1
	for k in range(k0, k1 + 1):
		var y0 := maxf(_lot_y(k, side), top)
		var y1 := minf(_lot_y(k + 1, side), bot)
		if side > 0.0 and y1 > PRECINCT_Y1 and y0 < PRECINCT_Y0:
			# the precinct owns its stretch; a house it cuts into stops at it
			if y0 < PRECINCT_Y1 - 30.0:
				y1 = PRECINCT_Y1
			elif y1 > PRECINCT_Y0 + 30.0:
				y0 = PRECINCT_Y0
			else:
				continue
		if y1 - y0 < 24.0 or y1 < lo - 20.0 or y0 > hi + 20.0:
			continue
		_cached(b, ["house", side, k, y0, y1], _house.bind(side, k, y0, y1))


# how many storeys a house stands over its neighbours' eaves
static func _storeys(k: int, side: float) -> int:
	return _lot_hash(k, side, 11) % 3


# One town house from above: its front a little seen from the street, the
# tiled roof over it, the pati behind and the next street's roofs beyond.
# Down the old street they are stone with wooden eaves and shutters; round
# the Mercadal the painted fronts over the porticoes; by the cathedral,
# canons' houses in dressed stone.
static func _house(b: ShapeBatch, side: float, k: int, y0: float, y1: float) -> void:
	var ym := (y0 + y1) * 0.5
	var style := 0 if ym > STREET_END else (1 if ym > MARKET_END else 2)
	var far := FAR_L if side < 0.0 else FAR_R
	var h := _lot_hash(k, side, 3)
	var e0 := _edge_x(y0, side)
	var e1 := _edge_x(y1, side)
	var f0 := e0 + side * FACE
	var f1 := e1 + side * FACE
	var len := y1 - y0
	var skew := (e1 - e0) / maxf(1.0, len)
	var frosty := _frosty()
	var pal: Array[Color] = PLAZA_RENDERS if style == 1 else STONES
	var wall: Color = pal[h % pal.size()]
	# the east row's fronts look west, toward the light
	var lit := side > 0.0
	wall = wall.lightened(0.04).lerp(WARM, 0.06) if lit else wall.darkened(0.16).lerp(COOL, 0.08)
	b.quad(Vector2(e0, y0), Vector2(f0, y0), Vector2(f1, y1), Vector2(e1, y1), wall)
	if style != 1:
		# dressed stone: the courses run along the front, the joints between
		for c in range(1, 4):
			var t := float(c) / 4.0
			b.line(Vector2(e0 + side * FACE * t, y0), Vector2(e1 + side * FACE * t, y1), wall.darkened(0.14), 1.0)
			var jy := y0 + 9.0 + float(c * 13 % 23)
			while jy < y1 - 4.0:
				var jx := e0 + skew * (jy - y0) + side * FACE * (t - 0.25)
				b.line(Vector2(jx, jy), Vector2(jx + side * FACE * 0.25, jy), wall.darkened(0.12), 1.0)
				jy += 22.0
	else:
		# a painted band under the cornice, and the portico's shade at its foot
		b.line(Vector2(e0 + side * FACE * 0.82, y0), Vector2(e1 + side * FACE * 0.82, y1), wall.lightened(0.18), 2.0)
		b.line(Vector2(e0 + side * 2.0, y0), Vector2(e1 + side * 2.0, y1), Color(0.10, 0.09, 0.10, 0.45), 4.0)
	b.line(Vector2(e0 + side * 1.0, y0), Vector2(e1 + side * 1.0, y1), SOCLE, 2.0)
	# windows, a pair to a house, each with its shutters open or closed
	var shut_col: Color = SHUTTERS[(h / 5) % SHUTTERS.size()]
	var nwin := 2 if len > 86.0 else 1
	for wi in range(nwin):
		var wy := ym if nwin == 1 else lerpf(y0, y1, 0.28 + 0.44 * float(wi))
		var wx := e0 + skew * (wy - y0)
		var x0 := wx + side * FACE * 0.22
		var x1 := wx + side * FACE * 0.86
		var r := Rect2(minf(x0, x1), wy - 7.0, absf(x1 - x0), 14.0)
		b.rect(r.grow(1.5), wall.lightened(0.20))
		var closed := (h + wi * 3) % 3 == 0
		if closed:
			b.rect(r, shut_col)
			for si in range(3):
				b.line(Vector2(r.position.x, wy - 4.0 + float(si) * 4.0), Vector2(r.end.x, wy - 4.0 + float(si) * 4.0), shut_col.darkened(0.3), 1.0)
		else:
			b.rect(r, WINDOW_DARK)
			b.rect(Rect2(r.position.x, wy - 13.0, r.size.x, 6.0), shut_col.lightened(0.08))
			b.rect(Rect2(r.position.x, wy + 7.0, r.size.x, 6.0), shut_col)
			b.line(Vector2(r.position.x, wy), Vector2(r.end.x, wy), Color(0.84, 0.82, 0.76, 0.45), 1.0)
		# a balcony on the first floor: its slab, the iron rail, geraniums
		if (style == 1 and (h + wi) % 3 != 1) or (style == 0 and (h + wi) % 4 == 1):
			var bx0 := wx + side * 2.0
			var bx1 := wx + side * FACE * 0.55
			var br := Rect2(minf(bx0, bx1), wy - 13.0, absf(bx1 - bx0), 26.0)
			b.rect(Rect2(br.position + Vector2(side * 2.0, 3.0), br.size), Color(0.05, 0.05, 0.08, 0.22))
			b.rect(br, wall.darkened(0.08))
			b.line(Vector2(bx0, wy - 13.0), Vector2(bx0, wy + 13.0), IRON, 1.6)
			b.line(Vector2(bx0, wy - 13.0), Vector2(bx1, wy - 13.0), IRON, 1.2)
			b.line(Vector2(bx0, wy + 13.0), Vector2(bx1, wy + 13.0), IRON, 1.2)
			if (h + wi) % 2 == 0:
				for pi in range(3):
					var pp := Vector2(bx0 + side * 3.0, wy - 8.0 + float(pi) * 8.0)
					b.circle(pp, 2.6, LEAF)
					b.circle(pp + Vector2(0.0, -0.6), 1.5, GERANIUM if pi != 1 else Color(0.96, 0.62, 0.74))
	# the street door on its step, between the windows
	if h % 2 == 1 and len > 70.0:
		var dy := lerpf(y0, y1, 0.5 + (0.1 if h % 4 == 1 else -0.1))
		var dxe := e0 + skew * (dy - y0)
		var dr := Rect2(minf(dxe, dxe + side * 7.0), dy - 8.0, 7.0, 16.0)
		b.rect(dr.grow(1.2), wall.lightened(0.22))
		b.rect(dr, DOORS[h % DOORS.size()])
	# a senyera hung from a balcony on the square, now and then
	if style == 1 and h % 5 == 2:
		var sy := ym
		var sx := e0 + skew * (sy - y0) + side * FACE * 0.5
		var fr := Rect2(minf(sx, sx - side * 14.0), sy - 6.0, 14.0, 12.0)
		b.rect(fr, Color(0.96, 0.80, 0.18))
		for st in range(4):
			b.line(Vector2(fr.position.x, sy - 4.5 + float(st) * 3.0), Vector2(fr.end.x, sy - 4.5 + float(st) * 3.0), Color(0.80, 0.14, 0.12), 1.2)

	# the roof: a pitched tile roof, its ridge along the street or across it
	var d := 120.0 + float(_lot_hash(k, side, 2) % 60)
	var back0 := f0 + side * d
	var back1 := f1 + side * d
	var tile: Color = ROOF_TILES[h % ROOF_TILES.size()]
	var toward := tile.lightened(0.12).lerp(WARM, 0.06)
	var away := tile.darkened(0.17).lerp(COOL, 0.06)
	var across := h % 4 == 3 and len > 60.0
	if across:
		# a gable to the street: one slope up the screen toward the light, one down
		b.quad(Vector2(f0, y0), Vector2(back0, y0), Vector2(back0 + skew * len * 0.5, ym), Vector2(f0 + skew * len * 0.5, ym), toward)
		b.quad(Vector2(f0 + skew * len * 0.5, ym), Vector2(back0 + skew * len * 0.5, ym), Vector2(back1, y1), Vector2(f1, y1), away)
		var cx := 6.0
		while cx < d - 3.0:
			b.line(Vector2(f0 + side * cx, y0 + 2.0), Vector2(f0 + side * cx + skew * len * 0.5, ym - 2.0), toward.darkened(0.11), 1.0)
			b.line(Vector2(f0 + side * cx + skew * len * 0.5, ym + 2.0), Vector2(f1 + side * cx, y1 - 1.0), away.darkened(0.11), 1.0)
			cx += 7.0
		if frosty:
			b.quad(Vector2(f0 + skew * len * 0.5, ym + 2.0), Vector2(back0 + skew * len * 0.5, ym + 2.0), Vector2(back1, y1), Vector2(f1, y1), RIME)
		b.line(Vector2(f0, ym + 2.0), Vector2(back0, ym + 2.0), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(f0 + skew * len * 0.5, ym), Vector2(back0 + skew * len * 0.5, ym), tile.lightened(0.26), 3.0)
	else:
		var r0 := f0 + side * d * 0.5
		var r1 := f1 + side * d * 0.5
		var front := toward if side > 0.0 else away
		var rear := away if side > 0.0 else toward
		b.quad(Vector2(f0, y0), Vector2(r0, y0), Vector2(r1, y1), Vector2(f1, y1), front)
		b.quad(Vector2(r0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(r1, y1), rear)
		# the Arab tiles' channels, down each slope from the ridge
		var ry := y0 + 4.0
		while ry < y1 - 2.0:
			var fx := f0 + skew * (ry - y0)
			b.line(Vector2(fx + side * 2.0, ry), Vector2(fx + side * (d * 0.5 - 2.0), ry), front.darkened(0.11), 1.0)
			b.line(Vector2(fx + side * (d * 0.5 + 2.0), ry), Vector2(fx + side * (d - 1.0), ry), rear.darkened(0.11), 1.0)
			ry += 7.0
		if frosty:
			# rime stays on the slope the low sun has not reached
			if side > 0.0:
				b.quad(Vector2(r0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(r1, y1), RIME)
			else:
				b.quad(Vector2(f0, y0), Vector2(r0, y0), Vector2(r1, y1), Vector2(f1, y1), RIME)
		# tiles replaced over the years, paler or darker than the rest
		for j in range(4):
			var hp := _lot_hash(k * 5 + j, side, 23)
			var px := f0 + skew * len * 0.5 + side * (8.0 + float(hp % int(d - 24.0)))
			var py := y0 + 6.0 + float((hp / 7) % int(maxf(8.0, len - 18.0)))
			b.rect(Rect2(px - 5.0, py, 10.0, 6.0), Color(1.0, 0.9, 0.8, 0.10) if hp % 2 == 0 else Color(0.1, 0.05, 0.05, 0.12))
		b.line(Vector2(r0 + 2.5, y0), Vector2(r1 + 2.5, y1), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(r0, y0), Vector2(r1, y1), tile.lightened(0.26), 3.0)
		if h % 3 == 0:
			# a stone chimney on the back slope, its cap and its shadow
			var cp := Vector2((r0 + back0) * 0.5, ym - 10.0)
			b.quad(cp + Vector2(-7.0, 7.0), cp + Vector2(7.0, -7.0), cp + Vector2(7.0, -7.0) + Shade.light * 18.0, cp + Vector2(-7.0, 7.0) + Shade.light * 18.0, Color(0.04, 0.05, 0.08, _shade_a(0.24)))
			b.rect(Rect2(cp - Vector2(7, 7), Vector2(14, 14)), Color(0.66, 0.62, 0.56))
			b.rect(Rect2(cp - Vector2(7, 7), Vector2(14, 3)), Color(0.84, 0.80, 0.72))
			b.rect(Rect2(cp - Vector2(7, 7), Vector2(3, 14)), Color(0.84, 0.80, 0.72))
			b.rect(Rect2(cp - Vector2(3.5, 3.5), Vector2(8, 8)), Color(0.20, 0.17, 0.16))
			if frosty:
				# the stove's been lit: a wisp of smoke drifts off
				b.glow(cp + Vector2(10.0, -8.0), 16.0, Color(0.86, 0.86, 0.88, 0.35))
		elif h % 7 == 4:
			# a rooflight over the stair
			var sp := Vector2((f0 + r0) * 0.5, ym + 12.0)
			b.rect(Rect2(sp - Vector2(8, 10), Vector2(16, 20)), Color(0.30, 0.28, 0.28))
			b.rect(Rect2(sp - Vector2(6, 8), Vector2(12, 16)), Color(0.46, 0.56, 0.60))
			b.quad(sp + Vector2(-6, -8), sp + Vector2(-1, -8), sp + Vector2(-6, 1), sp + Vector2(-6, 1), Color(0.78, 0.86, 0.90))
	# the eave: wooden brackets down the old street, a cornice elsewhere
	b.line(Vector2(f0 + side * 1.5, y0), Vector2(f1 + side * 1.5, y1), tile.darkened(0.38), 2.4)
	if style == 0:
		var by := y0 + 5.0
		while by < y1 - 3.0:
			var bxx := f0 + skew * (by - y0)
			b.line(Vector2(bxx - side * 3.0, by), Vector2(bxx + side * 1.0, by), Color(0.36, 0.24, 0.15), 1.6)
			by += 9.0
	else:
		b.line(Vector2(f0 - side * 0.5, y0), Vector2(f1 - side * 0.5, y1), wall.lightened(0.28), 2.4)
	# a taller house up the street throws its shade down onto this one's roof
	var over := _storeys(k - 1, side) - _storeys(k, side)
	if over > 0:
		var sw := 8.0 * float(over)
		b.quad(Vector2(f0, y0), Vector2(back0, y0), Vector2(back0 + skew * sw, y0 + sw), Vector2(f0 + skew * sw, y0 + sw), Color(0.05, 0.04, 0.10, _shade_a(0.26)))
	# the party wall down to the next house
	b.line(Vector2(f0, y0), Vector2(back0, y0), Color(0.62, 0.58, 0.52), 2.0)

	# the pati behind the house, down in the block's shade
	var pw := 34.0 + float(_lot_hash(k, side, 13) % 28)
	var p0 := back0 + side * pw
	var p1 := back1 + side * pw
	b.quad(Vector2(back0, y0), Vector2(p0, y0), Vector2(p1, y1), Vector2(back1, y1), PATI)
	b.quad(Vector2(back0, y0), Vector2(back0 + side * pw * 0.45, y0), Vector2(back1 + side * pw * 0.45, y1), Vector2(back1, y1), Color(0.05, 0.05, 0.12, 0.28))
	var pc := Vector2((back0 + p0 + back1 + p1) * 0.25, ym)
	match _lot_hash(k, side, 17) % 3:
		0:
			# a fig or a lemon tree
			b.circle(pc + Shade.light * 5.0, 13.0, Color(0.04, 0.05, 0.08, _shade_a(0.22)))
			b.circle(pc, 13.0, LEAF.darkened(0.12))
			b.circle(pc - Vector2(3.0, 4.0), 8.0, LEAF.lightened(0.10))
		1:
			# the washing out on a line
			var wa := Vector2(pc.x - side * pw * 0.3, y0 + 10.0)
			var wb := Vector2(pc.x - side * pw * 0.3, y1 - 10.0)
			b.line(wa, wb, Color(0.30, 0.30, 0.32), 1.0)
			for wi2 in range(3):
				var wp := wa.lerp(wb, 0.2 + 0.3 * float(wi2))
				b.rect(Rect2(wp.x - 1.0, wp.y - 5.0, 9.0 * side, 10.0).abs(), [Color(0.94, 0.93, 0.90), Color(0.56, 0.66, 0.80), Color(0.86, 0.58, 0.52)][(wi2 + h) % 3])
		_:
			# pots and a bench on the flags
			b.rect(Rect2(pc.x - 6.0, ym - 14.0, 12.0, 28.0), Color(0.60, 0.52, 0.44))
			b.circle(pc + Vector2(0.0, -20.0), 4.0, Color(0.70, 0.38, 0.22))
			b.circle(pc + Vector2(0.0, -20.5), 3.2, LEAF)
	# the back of the next street's row, and its roofs beyond
	var h2 := _lot_hash(k, side, 19)
	var tile2: Color = ROOF_TILES[h2 % ROOF_TILES.size()]
	var d2 := 150.0 + float(h2 % 40)
	var q0 := p0 + side * d2
	var q1 := p1 + side * d2
	var m0 := p0 + side * d2 * 0.5
	var m1 := p1 + side * d2 * 0.5
	var near2 := (tile2.lightened(0.06) if side > 0.0 else tile2.darkened(0.20)).darkened(0.06)
	var far2 := (tile2.darkened(0.20) if side > 0.0 else tile2.lightened(0.06)).darkened(0.06)
	b.quad(Vector2(p0, y0), Vector2(m0, y0), Vector2(m1, y1), Vector2(p1, y1), near2)
	b.quad(Vector2(m0, y0), Vector2(q0, y0), Vector2(q1, y1), Vector2(m1, y1), far2)
	b.quad(Vector2(q0, y0), Vector2(far, y0), Vector2(far, y1), Vector2(q1, y1), tile2.darkened(0.30))
	var ry2 := y0 + 6.0
	while ry2 < y1 - 2.0:
		var px2 := p0 + skew * (ry2 - y0)
		b.line(Vector2(px2 + side * 2.0, ry2), Vector2(px2 + side * (d2 * 0.5 - 2.0), ry2), near2.darkened(0.10), 1.0)
		b.line(Vector2(px2 + side * (d2 * 0.5 + 2.0), ry2), Vector2(px2 + side * (d2 - 1.0), ry2), far2.darkened(0.10), 1.0)
		ry2 += 9.0
	if frosty:
		if side > 0.0:
			b.quad(Vector2(m0, y0), Vector2(q0, y0), Vector2(q1, y1), Vector2(m1, y1), Color(RIME.r, RIME.g, RIME.b, 0.30))
		else:
			b.quad(Vector2(p0, y0), Vector2(m0, y0), Vector2(m1, y1), Vector2(p1, y1), Color(RIME.r, RIME.g, RIME.b, 0.30))
	b.line(Vector2(m0, y0), Vector2(m1, y1), tile2.lightened(0.16), 2.6)
	b.line(Vector2(p0, y0), Vector2(p1, y1), Color(0.80, 0.74, 0.64), 2.0)
	b.line(Vector2(e0, y0), Vector2(far, y0), Color(0.18, 0.13, 0.10, 0.45), 2.0)


# East of the cathedral: the precinct's flagged court, the Gothic cloister
# round its garth, and the bishop's palace beyond.
static func _precinct(b: ShapeBatch, lo: float, hi: float) -> void:
	if hi < PRECINCT_Y1 or lo > PRECINCT_Y0:
		return
	var y0 := PRECINCT_Y1
	var y1 := PRECINCT_Y0
	# the court, flagged in the same limestone as the square
	_outside(b, 1.0, y0, y1, LIMESTONE_DK)
	var fy := y0 + 4.0
	while fy < y1:
		var ex := _edge_x(fy, 1.0)
		b.line(Vector2(ex, fy), Vector2(1110.0, fy), Color(0.50, 0.47, 0.42, 0.55), 1.0)
		var fx := ex + float(_hi(int(fy)) % 30)
		while fx < 1110.0:
			b.line(Vector2(fx, fy), Vector2(fx, fy + 26.0), Color(0.50, 0.47, 0.42, 0.45), 1.0)
			fx += 38.0
		fy += 26.0
	# the bishop's palace: a long block with a hipped roof round its own court
	var pal := Rect2(1110.0, y0, FAR_R - 1110.0, y1 - y0)
	var tile: Color = ROOF_TILES[2]
	b.rect(pal, tile.darkened(0.08))
	b.quad(pal.position, Vector2(pal.end.x, pal.position.y), Vector2(pal.end.x, pal.position.y + 60.0), Vector2(pal.position.x + 60.0, pal.position.y + 60.0), tile.lightened(0.12))
	b.quad(pal.position, Vector2(pal.position.x + 60.0, pal.position.y + 60.0), Vector2(pal.position.x + 60.0, pal.end.y - 60.0), Vector2(pal.position.x, pal.end.y), tile.lightened(0.06))
	b.quad(Vector2(pal.position.x, pal.end.y), Vector2(pal.position.x + 60.0, pal.end.y - 60.0), Vector2(pal.end.x, pal.end.y - 60.0), pal.end, tile.darkened(0.16))
	var court := Rect2(pal.position.x + 60.0, pal.position.y + 60.0, pal.size.x - 60.0, pal.size.y - 120.0)
	b.rect(court, LIMESTONE)
	b.rect(Rect2(court.position, Vector2(court.size.x, 14.0)), Color(0.05, 0.05, 0.10, _shade_a(0.24)))
	b.rect(Rect2(court.position, Vector2(14.0, court.size.y)), Color(0.05, 0.05, 0.10, _shade_a(0.24)))
	b.line(pal.position + Vector2(60.0, 60.0), Vector2(pal.end.x, pal.position.y + 60.0), tile.lightened(0.24), 2.0)
	b.line(pal.position + Vector2(60.0, 60.0), Vector2(pal.position.x + 60.0, pal.end.y - 60.0), tile.lightened(0.24), 2.0)
	b.line(Vector2(pal.position.x + 60.0, pal.end.y - 60.0), Vector2(pal.end.x, pal.end.y - 60.0), tile.lightened(0.18), 2.0)
	if _frosty():
		b.quad(Vector2(pal.position.x, pal.end.y), Vector2(pal.position.x + 60.0, pal.end.y - 60.0), Vector2(pal.end.x, pal.end.y - 60.0), pal.end, RIME)
	# the palace's shadow on the court
	b.rect(Rect2(1110.0 - 2.0, y0, 2.0, y1 - y0), Color(0.10, 0.08, 0.08, 0.6))
	_cloister(b)


static func _cloister(b: ShapeBatch) -> void:
	var cl := CLOISTER
	var frosty := _frosty()
	_sweep_shadow(b, cl, Shade.light * 22.0, Color(0.04, 0.05, 0.08, _shade_a(0.24)))
	b.rect(cl, CATH_DK)
	var walk := 28.0
	var garth := cl.grow(-walk)
	# the galleries' lean-to roofs, sloping in toward the garth
	var tile: Color = ROOF_TILES[0]
	var lit := tile.lightened(0.12)
	var shade := tile.darkened(0.14)
	var o := cl.position
	var e := cl.end
	var go := garth.position
	var ge := garth.end
	b.quad(o, Vector2(e.x, o.y), Vector2(ge.x, go.y), go, shade)               # north range, its slope faces south... into shade
	b.quad(Vector2(o.x, e.y), go + Vector2(0.0, garth.size.y), ge, e, lit)
	b.quad(o, go, Vector2(go.x, ge.y), Vector2(o.x, e.y), shade.lightened(0.05))
	b.quad(Vector2(e.x, o.y), e, ge, Vector2(ge.x, go.y), lit.darkened(0.04))
	# tile channels on each range
	var t := 6.0
	while t < cl.size.x - 6.0:
		b.line(Vector2(o.x + t, o.y + 2.0), Vector2(o.x + t, go.y - 2.0), shade.darkened(0.10), 1.0)
		b.line(Vector2(o.x + t, ge.y + 2.0), Vector2(o.x + t, e.y - 2.0), lit.darkened(0.10), 1.0)
		t += 7.0
	t = 6.0
	while t < cl.size.y - 6.0:
		b.line(Vector2(o.x + 2.0, o.y + t), Vector2(go.x - 2.0, o.y + t), shade.darkened(0.08), 1.0)
		b.line(Vector2(ge.x + 2.0, o.y + t), Vector2(e.x - 2.0, o.y + t), lit.darkened(0.10), 1.0)
		t += 7.0
	# hips at the corners
	b.line(o, go, tile.lightened(0.24), 2.0)
	b.line(Vector2(e.x, o.y), Vector2(ge.x, go.y), tile.lightened(0.24), 2.0)
	b.line(Vector2(o.x, e.y), Vector2(go.x, ge.y), tile.lightened(0.24), 2.0)
	b.line(e, ge, tile.lightened(0.24), 2.0)
	if frosty:
		b.quad(o, Vector2(e.x, o.y), Vector2(ge.x, go.y), go, RIME)
	# the garth: the gallery's shade along its north and west, box hedges,
	# the well, and a cypress
	b.rect(garth, GRASS.darkened(0.05))
	b.rect(garth.grow(-6.0), GRASS_LIT if not frosty else GRASS_LIT.lerp(Color(0.82, 0.86, 0.84), 0.45))
	b.rect(Rect2(go, Vector2(garth.size.x, 10.0)), Color(0.05, 0.05, 0.10, _shade_a(0.28)))
	b.rect(Rect2(go, Vector2(10.0, garth.size.y)), Color(0.05, 0.05, 0.10, _shade_a(0.28)))
	var gc := garth.get_center()
	b.line(Vector2(gc.x, go.y + 6.0), Vector2(gc.x, ge.y - 6.0), Color(0.80, 0.74, 0.62), 4.0)
	b.line(Vector2(go.x + 6.0, gc.y), Vector2(ge.x - 6.0, gc.y), Color(0.80, 0.74, 0.62), 4.0)
	b.circle(gc + Shade.light * 3.0, 9.0, Color(0.04, 0.05, 0.08, 0.25))
	b.circle(gc, 9.0, LIMESTONE)
	b.circle(gc, 6.0, Color(0.12, 0.16, 0.18))
	var cyp := gc + Vector2(-22.0, -40.0)
	b.capsule(cyp + Shade.light * 8.0, cyp + Shade.light * 30.0, 6.0, Color(0.04, 0.05, 0.08, _shade_a(0.24)))
	b.circle(cyp, 9.0, Color(0.14, 0.28, 0.18))
	b.circle(cyp + Vector2(-2.0, -2.0), 5.5, Color(0.22, 0.38, 0.24))
	# the gallery's columns on the garth's edge
	var c := 10.0
	while c < garth.size.x - 4.0:
		b.circle(Vector2(go.x + c, go.y), 2.4, LIMESTONE)
		b.circle(Vector2(go.x + c, ge.y), 2.4, LIMESTONE)
		c += 14.0
	c = 10.0
	while c < garth.size.y - 4.0:
		b.circle(Vector2(go.x, go.y + c), 2.4, LIMESTONE)
		b.circle(Vector2(ge.x, go.y + c), 2.4, LIMESTONE)
		c += 14.0


# From the cathedral down to the water: on the west the old tanneries along
# the Mèder, their yards of vats and hides drying on frames; on the east the
# riverside kitchen gardens behind a dry-stone wall.
static func _riverside(b: ShapeBatch, lo: float, hi: float) -> void:
	var top := BRIDGE_Y0
	var bot := CATHEDRAL_END
	if hi < top or lo > bot:
		return
	var a := maxf(lo, top)
	var z := minf(hi, bot)
	var frosty := _frosty()
	# the ground both sides: beaten earth on the tanneries' side, soil on the gardens'
	_outside(b, -1.0, a, z, Color(0.50, 0.44, 0.36))
	_outside(b, 1.0, a, z, Color(0.40, 0.34, 0.26))
	# the bank: a stone embankment along the water, the path's lane above it
	for side: float in SIDES:
		var far := FAR_L if side < 0.0 else FAR_R
		var ea := _edge_x(BANK_S, side)
		var eb := _edge_x(BRIDGE_Y0, side)
		b.quad(Vector2(ea, BANK_S), Vector2(far, BANK_S), Vector2(far, BRIDGE_Y0), Vector2(eb, BRIDGE_Y0), Color(0.58, 0.55, 0.50))
		b.line(Vector2(ea, BANK_S + 1.0), Vector2(far, BANK_S + 1.0), Color(0.72, 0.69, 0.63), 3.0)
		var sx := minf(ea, far)
		var sx1 := maxf(ea, far)
		var x := sx - fposmod(sx, 26.0)
		while x < sx1:
			b.line(Vector2(x, BANK_S - 3.0), Vector2(x, BRIDGE_Y0), Color(0.42, 0.40, 0.37, 0.7), 1.0)
			x += 26.0
		b.line(Vector2(minf(ea, far), (BANK_S + BRIDGE_Y0) * 0.5), Vector2(maxf(ea, far), (BANK_S + BRIDGE_Y0) * 0.5), Color(0.42, 0.40, 0.37, 0.7), 1.0)
		if frosty:
			b.line(Vector2(ea, BANK_S + 2.0), Vector2(far, BANK_S + 2.0), Color(0.92, 0.95, 0.98, 0.6), 2.0)
	# west: the tanneries, three long blocks gable-end to the river
	var blocks: Array[Vector3] = [Vector3(-3300.0, -3200.0, 0.0), Vector3(-3420.0, -3320.0, 1.0)]
	for bk: Vector3 in blocks:
		var ty0 := bk.x
		var ty1 := bk.y
		if ty1 < a - 40.0 or ty0 > z + 40.0:
			continue
		var ex := _edge_x(ty1, -1.0) - 34.0
		var r := Rect2(ex - 300.0, ty0, 300.0, ty1 - ty0 - 14.0)
		_sweep_shadow(b, r, Shade.light * 24.0, Color(0.04, 0.05, 0.08, _shade_a(0.26)))
		var tile: Color = ROOF_TILES[int(bk.z) + 1]
		var rm := r.get_center().y
		b.rect(Rect2(r.position.x, r.position.y, r.size.x, rm - r.position.y), tile.lightened(0.10))
		b.rect(Rect2(r.position.x, rm, r.size.x, r.end.y - rm), tile.darkened(0.16))
		var cx := r.position.x + 4.0
		while cx < r.end.x - 2.0:
			b.line(Vector2(cx, r.position.y + 2.0), Vector2(cx, rm - 2.0), tile.darkened(0.02), 1.0)
			b.line(Vector2(cx, rm + 2.0), Vector2(cx, r.end.y - 1.0), tile.darkened(0.26), 1.0)
			cx += 7.0
		if frosty:
			b.rect(Rect2(r.position.x, rm, r.size.x, r.end.y - rm), RIME)
		b.line(Vector2(r.position.x, rm), Vector2(r.end.x, rm), tile.lightened(0.28), 3.0)
		# the open drying loft under the eaves: a dark slot with its timber posts
		b.rect(Rect2(r.end.x - 2.0, r.position.y + 4.0, 10.0, r.size.y - 8.0), Color(0.18, 0.14, 0.12))
		var py := r.position.y + 8.0
		while py < r.end.y - 6.0:
			b.rect(Rect2(r.end.x - 1.0, py, 8.0, 3.0), Color(0.50, 0.36, 0.22))
			py += 14.0
		# hides hung out along the loft
		for hi2 in range(4):
			var hp := Vector2(r.end.x + 16.0, r.position.y + 12.0 + float(hi2) * 18.0)
			if hp.y > r.end.y - 6.0:
				break
			b.polygon(PackedVector2Array([hp + Vector2(-6, -6), hp + Vector2(7, -7), hp + Vector2(8, 6), hp + Vector2(-5, 7)]), HIDE.darkened(0.05 * float(hi2 % 2)))
	# the tannery yard: the vats along the bank
	if a < BANK_S + 10.0 and z > -3440.0 - 120.0:
		for vi in range(5):
			var vc := Vector2(_edge_x(-3420.0, -1.0) - 70.0 - float(vi) * 48.0, -3404.0 + float(vi % 2) * 6.0)
			b.rect(Rect2(vc - Vector2(17, 13), Vector2(34, 26)), Color(0.56, 0.52, 0.46))
			b.rect(Rect2(vc - Vector2(14, 10), Vector2(28, 20)), VAT.lightened(0.06 * float(vi % 3)))
			b.rect(Rect2(vc - Vector2(14, 10), Vector2(28, 4)), Color(0.05, 0.04, 0.04, 0.35))
	# east: kitchen gardens in frosted rows behind a dry-stone wall
	var gy := floorf(maxf(a, BANK_S + 10.0) / 22.0) * 22.0
	while gy < z - 24.0:
		if gy > BANK_S + 6.0:
			var ex2 := _edge_x(gy, 1.0)
			var gx0 := ex2 + 46.0
			var row := int(absf(gy) / 22.0)
			var crop := LEAF.lightened(0.06) if row % 3 != 2 else Color(0.38, 0.50, 0.30)
			if frosty:
				crop = crop.lerp(Color(0.80, 0.86, 0.84), 0.35)
			var cx2 := gx0 + float(row % 2) * 7.0
			while cx2 < 1300.0:
				b.circle(Vector2(cx2, gy + 11.0), 4.2 + float(_hi(row * 7 + int(cx2)) % 3), crop)
				cx2 += 15.0
		gy += 22.0
	# the wall between the lane and the gardens: rough stones, unmortared
	var wy := floorf(maxf(a, BANK_S) / 12.0) * 12.0
	while wy < z:
		var wx := _edge_x(wy, 1.0) + 24.0
		var s := 5.0 + float(_hi(int(wy) * 3) % 4)
		b.coarse(Vector2(wx + float(_hi(int(wy)) % 5) - 2.0, wy), s, Color(0.62, 0.58, 0.52).darkened(0.08 * float(_hi(int(wy) + 7) % 3)))
		wy += 10.0
	# a garden hut and its water butt
	if a < -3250.0 and z > -3330.0:
		var hut := Rect2(_edge_x(-3300.0, 1.0) + 150.0, -3330.0, 46.0, 40.0)
		_sweep_shadow(b, hut, Shade.light * 12.0, Color(0.04, 0.05, 0.08, _shade_a(0.24)))
		b.rect(hut, Color(0.46, 0.48, 0.50))
		var hx := hut.position.x
		while hx < hut.end.x:
			b.line(Vector2(hx, hut.position.y), Vector2(hx, hut.end.y), Color(0.36, 0.38, 0.40), 1.0)
			hx += 6.0
		b.circle(hut.position + Vector2(-12.0, 30.0), 8.0, Color(0.22, 0.30, 0.40))
		b.circle(hut.position + Vector2(-12.0, 30.0), 6.0, Color(0.14, 0.20, 0.26))


# The Mèder, flowing west to east under the bridge: deep and dark down its
# middle, shallow and paler at the banks, a gravel bar and reeds, the old
# weir's sill with white water under it. Still; its glints are the live pass's.
static func _river(b: ShapeBatch, lo: float, hi: float) -> void:
	var top := BRIDGE_Y1
	var bot := BRIDGE_Y0
	if hi < top - 10.0 or lo > bot + 10.0:
		return
	var frosty := _frosty()
	b.rect(Rect2(FAR_L, top, FAR_R - FAR_L, bot - top), RIVER_DEEP)
	b.band(PackedVector2Array([
		Vector2(FAR_L, top), Vector2(FAR_R, top),
		Vector2(FAR_L, top + 110.0), Vector2(FAR_R, top + 110.0),
		Vector2(FAR_L, bot - 110.0), Vector2(FAR_R, bot - 110.0),
		Vector2(FAR_L, bot), Vector2(FAR_R, bot),
	]), 2, RIVER_SHALLOW, PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
	# the current's long lines
	for i in range(26):
		var ly := lerpf(top + 30.0, bot - 30.0, _h(i * 13 + 5))
		var lx := lerpf(FAR_L, FAR_R, _h(i * 7 + 1))
		var ll := 40.0 + _h(i * 3 + 2) * 80.0
		b.band(PackedVector2Array([
			Vector2(lx, ly - 1.5), Vector2(lx + ll * 0.5, ly - 1.5), Vector2(lx + ll, ly - 1.5),
			Vector2(lx, ly + 1.5), Vector2(lx + ll * 0.5, ly + 1.5), Vector2(lx + ll, ly + 1.5),
		]), 3, Color(0.62, 0.74, 0.76, 0.32), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
	# the gravel bar against the north bank, west of the bridge
	var bar := PackedVector2Array([
		Vector2(140.0, top + 4.0), Vector2(420.0, top + 4.0), Vector2(380.0, top + 40.0),
		Vector2(300.0, top + 62.0), Vector2(200.0, top + 58.0), Vector2(120.0, top + 30.0),
	])
	b.polygon(bar, GRAVEL)
	for gi in range(16):
		b.coarse(Vector2(lerpf(150.0, 380.0, _h(gi * 5 + 3)), top + 10.0 + _h(gi * 9 + 4) * 40.0), 2.0 + _h(gi * 2 + 1) * 2.5, GRAVEL.darkened(0.15 + 0.1 * _h(gi)))
	# the weir east of the bridge: a stone sill slanting across, foam below it
	var w0 := Vector2(980.0, top)
	var w1 := Vector2(1240.0, bot)
	b.line(w0, w1, Color(0.64, 0.61, 0.56), 10.0)
	b.line(w0 + Vector2(-2.0, 0.0), w1 + Vector2(-2.0, 0.0), Color(0.76, 0.73, 0.67), 3.0)
	b.band(PackedVector2Array([
		w0 + Vector2(6.0, 0.0), w0 + Vector2(40.0, 0.0),
		w1 + Vector2(6.0, 0.0), w1 + Vector2(40.0, 0.0),
	]), 2, Color(0.92, 0.95, 0.96, 0.8), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	# reeds along both banks, thinning out toward the bridge
	for side_y: float in [top, bot]:
		var into := 1.0 if side_y == top else -1.0
		var rx := FAR_L + 10.0
		var n := 0
		while rx < FAR_R:
			if absf(rx - CX) > 190.0:
				var rh := _h(n * 11 + int(side_y))
				if rh < 0.7:
					var base := Vector2(rx, side_y + into * (4.0 + rh * 10.0))
					var col := REED if n % 2 == 0 else REED_DK
					if frosty:
						col = col.lerp(Color(0.78, 0.78, 0.70), 0.35)
					for s in range(3):
						var tip := base + Vector2(-5.0 + float(s) * 5.0 + rh * 4.0, into * (12.0 + float(s) * 3.0))
						b.line(base, tip, col, 1.6)
			rx += 14.0
			n += 1
	if frosty:
		# thin ice at the edges of the still water
		for side_y: float in [top, bot]:
			var into := 1.0 if side_y == top else -1.0
			b.band(PackedVector2Array([
				Vector2(FAR_L, side_y), Vector2(FAR_R, side_y),
				Vector2(FAR_L, side_y + into * 14.0), Vector2(FAR_R, side_y + into * 14.0),
			]), 2, Color(0.86, 0.92, 0.96, 0.55), PackedFloat32Array([1.0, 0.0]))


# Past the bridge: the north bank and the meadow, rimed grass with the
# poplars along the water, dry-stone walls and ploughed fields of the Plana
# beyond, and a masia's roof to the east.
static func _meadow(b: ShapeBatch, lo: float, hi: float) -> void:
	var top := GATE - 60.0
	var bot := BRIDGE_Y1
	if hi < top or lo > bot:
		return
	var a := maxf(lo, top)
	var z := minf(hi, bot)
	var frosty := _frosty()
	var grass := GRASS.lerp(Color(0.66, 0.72, 0.68), 0.40) if frosty else GRASS
	b.rect(Rect2(FAR_L, a, FAR_R - FAR_L, z - a), grass)
	# soft swathes of lighter and darker grass, so the field is never flat
	for i in range(14):
		var gp := Vector2(lerpf(FAR_L + 200.0, FAR_R - 200.0, _h(i * 17 + 3)), lerpf(top, BANK_N, _h(i * 29 + 7)))
		if gp.y < a - 200.0 or gp.y > z + 200.0:
			continue
		var gcol := (GRASS_LIT if i % 2 == 0 else GRASS_DK)
		if frosty:
			gcol = gcol.lerp(Color(0.86, 0.90, 0.88), 0.45 if i % 2 == 0 else 0.2)
		b.glow(gp, 120.0 + _h(i * 5) * 120.0, Color(gcol.r, gcol.g, gcol.b, 0.45))
	# the north bank: mud and stones at the water's edge, feathering into grass
	b.band(PackedVector2Array([
		Vector2(FAR_L, bot), Vector2(FAR_R, bot),
		Vector2(FAR_L, BANK_N), Vector2(FAR_R, BANK_N),
	]), 2, MUD, PackedFloat32Array([1.0, 0.0]))
	for si in range(20):
		var sp := Vector2(lerpf(FAR_L, FAR_R, _h(si * 3 + 11)), bot - 6.0 - _h(si * 5 + 2) * 22.0)
		if absf(sp.x - CX) > 150.0:
			b.coarse(sp, 4.0 + _h(si) * 5.0, BANK_STONE.darkened(0.1 * _h(si * 7)))
	# the ploughed field west, its furrows holding the frost
	var fld := PackedVector2Array([Vector2(FAR_L, -4820.0), Vector2(250.0, -4780.0), Vector2(300.0, -4240.0), Vector2(FAR_L, -4200.0)])
	if a < -4200.0 and z > -4820.0:
		b.polygon(fld, FIELD)
		var fy := -4800.0
		while fy < -4220.0:
			var fx1 := lerpf(250.0, 300.0, (fy + 4780.0) / 540.0)
			b.line(Vector2(FAR_L, fy), Vector2(fx1 - 6.0, fy + 4.0), FIELD_LIT if not frosty else Color(0.84, 0.86, 0.86, 0.8), 2.0)
			b.line(Vector2(FAR_L, fy + 5.0), Vector2(fx1 - 6.0, fy + 9.0), FIELD.darkened(0.2), 2.0)
			fy += 14.0
	# dry-stone walls: one along each side of the path, with gaps, and the
	# field's wall west
	for side: float in SIDES:
		var wy := floorf(a / 11.0) * 11.0
		while wy < minf(z, BANK_N - 10.0):
			if wy > top + 20.0:
				var gap := int(absf(wy) / 260.0) % 3 == 1 and fposmod(wy, 260.0) < 50.0
				if not gap:
					var wx := _edge_x(wy, side) + side * (36.0 + 8.0 * sin(wy * 0.013))
					var s := 4.5 + float(_hi(int(wy) * 5 + int(side)) % 4)
					var sc := Color(0.66, 0.63, 0.57).darkened(0.07 * float(_hi(int(wy) + 3) % 3))
					b.coarse(Vector2(wx + side * 3.0, wy + 3.0) + Shade.light * 3.0, s, Color(0.05, 0.06, 0.08, _shade_a(0.22)))
					b.coarse(Vector2(wx + float(_hi(int(wy)) % 5) - 2.0, wy), s, sc)
					if frosty and _hi(int(wy) * 7) % 3 == 0:
						b.circle(Vector2(wx - 1.0, wy - 1.5), s * 0.5, Color(0.94, 0.96, 0.98, 0.7))
			wy += 9.0
	# poplars along the bank, bare in winter: a twiggy crown and a long shadow
	for pi in range(16):
		var px := lerpf(FAR_L + 40.0, FAR_R - 40.0, float(pi) / 15.0) + (_h(pi * 7) - 0.5) * 30.0
		if absf(px - CX) < 260.0:
			continue
		var pp := Vector2(px, BANK_N - 24.0 - _h(pi * 3) * 30.0)
		if pp.y < a - 120.0 or pp.y > z + 120.0:
			continue
		_bare_tree(b, pp, 22.0 + _h(pi * 5) * 8.0, pi)
	# the masia to the east: big hipped roof, the farmyard and its straw bales
	if a < -4440.0 and z > -4800.0:
		var mr := Rect2(1010.0, -4760.0, 230.0, 170.0)
		_sweep_shadow(b, mr, Shade.light * 40.0, Color(0.04, 0.05, 0.08, _shade_a(0.26)))
		var tile: Color = ROOF_TILES[3]
		var mc := mr.get_center()
		var inset := 70.0
		var ra := Vector2(mr.position.x + inset, mc.y)
		var rb := Vector2(mr.end.x - inset, mc.y)
		b.polygon(PackedVector2Array([mr.position, Vector2(mr.end.x, mr.position.y), rb, ra]), tile.lightened(0.12))
		b.polygon(PackedVector2Array([Vector2(mr.position.x, mr.end.y), ra, rb, mr.end]), tile.darkened(0.16))
		b.polygon(PackedVector2Array([mr.position, ra, Vector2(mr.position.x, mr.end.y)]), tile.lightened(0.04))
		b.polygon(PackedVector2Array([Vector2(mr.end.x, mr.position.y), mr.end, rb]), tile.darkened(0.08))
		if frosty:
			b.polygon(PackedVector2Array([Vector2(mr.position.x, mr.end.y), ra, rb, mr.end]), RIME)
		for hip: Vector2 in [mr.position, Vector2(mr.end.x, mr.position.y), Vector2(mr.position.x, mr.end.y), mr.end]:
			b.line(hip, ra if hip.x < mc.x else rb, tile.lightened(0.24), 2.0)
		b.line(ra, rb, tile.lightened(0.28), 3.0)
		var yard := Rect2(mr.position.x - 10.0, mr.end.y + 8.0, 200.0, 90.0)
		b.rect(yard, Color(0.56, 0.50, 0.40))
		for bi in range(4):
			var bp := yard.position + Vector2(130.0 + float(bi % 2) * 30.0, 18.0 + float(bi / 2) * 34.0)
			b.rect(Rect2(bp + Shade.light * 5.0, Vector2(26.0, 18.0)), Color(0.04, 0.05, 0.08, _shade_a(0.22)))
			b.rect(Rect2(bp, Vector2(26.0, 18.0)), Color(0.86, 0.74, 0.42))
			b.line(bp + Vector2(0.0, 6.0), bp + Vector2(26.0, 6.0), Color(0.70, 0.58, 0.30), 1.0)
			b.line(bp + Vector2(0.0, 12.0), bp + Vector2(26.0, 12.0), Color(0.70, 0.58, 0.30), 1.0)


static func _bare_tree(b: ShapeBatch, p: Vector2, r: float, k: int) -> void:
	# its shadow first, thrown long and thin along the light
	b.capsule(p + Shade.light * 10.0, p + Shade.light * (r * 3.2), r * 0.32, Color(0.04, 0.05, 0.08, _shade_a(0.16)))
	b.circle(p, r * 0.75, Color(0.42, 0.36, 0.30, 0.25))
	for i in range(9):
		var ang := TAU * float(i) / 9.0 + _h(k * 13 + i) * 0.6
		var tip := p + Vector2.from_angle(ang) * r * (0.7 + _h(k * 7 + i) * 0.4)
		b.line(p, tip, Color(0.36, 0.30, 0.24), 1.6)
		b.line(tip, tip + Vector2.from_angle(ang + 0.6) * r * 0.3, Color(0.42, 0.36, 0.30), 1.0)
	b.circle(p, 3.0, Color(0.30, 0.24, 0.20))
	if _frosty():
		b.circle(p + Vector2(-2.0, -2.0), r * 0.5, Color(0.92, 0.94, 0.96, 0.28))


# --- the ground ------------------------------------------------------------------

static func draw_cross_section(_m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, _ctop: float, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 30.0, GATE - 40.0)
	var hi := vb + 30.0
	# the paving, built once a chunk at a time and kept
	var c0 := int(floorf(lo / CHUNK))
	var c1 := int(floorf(hi / CHUNK))
	for c in range(c0, c1 + 1):
		_cached(wc, ["pave", c], _pave.bind(float(c) * CHUNK, float(c + 1) * CHUNK))
	if lo < STREET_END + 160.0 and hi > MARKET_END - 160.0:
		_plaza_marks(wc, lo, hi)
	if lo < BRIDGE_Y0 + 40.0 and hi > BRIDGE_Y1 - 40.0:
		_cached(wc, ["bridge"], _draw_bridge.bind(-1.0e9, 1.0e9))
	if lo < BRIDGE_Y1 and hi > RAMP_END - 60.0:
		_ramp(wc, maxf(lo, RAMP_END - 60.0), minf(hi, BRIDGE_Y1))
	# the corridor's own shade: the west row's houses throw it across the paving
	_west_shade(wc, lo, hi)
	if lo < MARKET_END + 40.0 and hi > STREET_END - 40.0:
		_porticoes(wc, maxf(lo, MARKET_END), minf(hi, STREET_END))
		for i in range(STALLS.size()):
			var s: Vector2 = STALLS[i]
			if s.y > lo - 60.0 and s.y < hi + 60.0:
				_cached(wc, ["stall", i], _stall.bind(i))
	if lo < CATHEDRAL_RECT.end.y + 200.0 and hi > CATHEDRAL_RECT.position.y - 300.0:
		_cached(wc, ["cathedral"], _draw_cathedral)
	wc.lod = keep_lod


# the corridor's paving between a and z exactly, so chunks meet without a seam
static func _pave(wc: ShapeBatch, a: float, z: float) -> void:
	# the old street: grey setts, a run of slabs down its middle
	_setts(wc, maxf(a, STREET_END), z, 13.0, 21.0, GREY_SETT, Color(0.34, 0.32, 0.30), 11)
	_street_slabs(wc, maxf(a, STREET_END), minf(z, START + 760.0))
	# the Mercadal: pale sand setts, flagged walks under the porticoes
	var pa := maxf(a, MARKET_END)
	var pz := minf(z, STREET_END)
	if pz > pa:
		var e := _edges_at(-1400.0)
		var walk := 58.0
		_setts(wc, pa, pz, 15.0, 26.0, SAND_SETT, Color(0.68, 0.61, 0.49), 41, e.x + walk, e.y - walk)
		_flags(wc, pa, pz, e.x, e.x + walk, 34.0, 46.0, FLAG_COLS, Color(0.48, 0.45, 0.40), 5)
		_flags(wc, pa, pz, e.y - walk, e.y, 34.0, 46.0, FLAG_COLS, Color(0.48, 0.45, 0.40), 9)
		wc.line(Vector2(e.x + walk, pa), Vector2(e.x + walk, pz), Color(0.56, 0.52, 0.46), 3.0)
		wc.line(Vector2(e.y - walk, pa), Vector2(e.y - walk, pz), Color(0.56, 0.52, 0.46), 3.0)
	# the cathedral's square: big limestone flags
	_flags_in_corridor(wc, maxf(a, CATHEDRAL_END), minf(z, MARKET_END))
	# the lane down to the bridge: setts again, narrowing
	_setts(wc, maxf(a, BRIDGE_Y0), minf(z, CATHEDRAL_END), 13.0, 21.0, GREY_SETT, Color(0.34, 0.32, 0.30), 23)
	# the bridge's deck and the cobbled ramp off it
	_setts(wc, maxf(a, BRIDGE_Y1), minf(z, BRIDGE_Y0), 12.0, 20.0, DECK_SETT, Color(0.46, 0.43, 0.39), 53)
	_setts(wc, maxf(a, RAMP_END), minf(z, BRIDGE_Y1), 13.0, 20.0, DECK_SETT, Color(0.44, 0.42, 0.38), 61)
	_meadow_path(wc, maxf(a, GATE - 40.0), minf(z, RAMP_END))


static func _rec_valid() -> void:
	var key := [Game.weather, Game.hour, snappedf(Game.fog_amount(), 0.05), Shade.throw]
	if key != _recs_key:
		_recs.clear()
		_recs_key = key


# a static piece drawn once into its own recording and replayed into the
# caller's batch after that: the same pixels, none of the work
static func _cached(wc: ShapeBatch, key: Array, fn: Callable) -> void:
	var rec: ShapeBatch = _recs.get(key)
	if rec == null:
		rec = ShapeBatch.new()
		rec.lod = true
		fn.call(rec)
		_recs[key] = rec
	rec.append_to(wc)


# a run of limestone slabs down the old street's middle, its gutter
static func _street_slabs(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var w := 30.0
	wc.rect(Rect2(CX - w * 0.5 - 1.5, a, w + 3.0, z - a), Color(0.36, 0.34, 0.31))
	var y := floorf(a / 38.0) * 38.0
	var i := int(y / 38.0)
	while y < z:
		var s0 := maxf(y + 1.0, a)
		var s1 := minf(y + 37.0, z)
		if s1 > s0:
			var c: Color = FLAG_COLS[_hi(i * 7 + 3) % FLAG_COLS.size()]
			wc.rect(Rect2(CX - w * 0.5, s0, w, s1 - s0), c.darkened(0.06))
			wc.rect(Rect2(CX - w * 0.5, s0, w, 1.5), Color(1.0, 0.98, 0.92, 0.12))
		y += 38.0
		i += 1
	# the gutter worn down the slabs' middle
	wc.line(Vector2(CX, a), Vector2(CX, z), Color(0.30, 0.28, 0.26, 0.45), 3.0)
	wc.line(Vector2(CX + 1.5, a), Vector2(CX + 1.5, z), Color(1.0, 1.0, 1.0, 0.08), 1.0)


static func _plaza_marks(wc: ShapeBatch, lo: float, hi: float) -> void:
	var e := _edges_at(-1400.0)
	# a Saturday's wear: the aisles trodden darker, the stalls' pitches paler
	for i in range(12):
		var p := Vector2(lerpf(e.x + 120.0, e.y - 120.0, _h(i * 5 + 1)), lerpf(MARKET_END + 60.0, STREET_END - 60.0, _h(i * 9 + 2)))
		if p.y < lo - 160.0 or p.y > hi + 160.0:
			continue
		wc.glow(p, 90.0 + _h(i) * 70.0, Color(0.52, 0.44, 0.32, 0.12) if i % 2 == 0 else Color(1.0, 0.97, 0.88, 0.10))
	# the square's kerbs where the streets come in
	for ky: float in [STREET_END, MARKET_END]:
		if ky >= lo and ky <= hi:
			var ek := _edges_at(ky)
			wc.line(Vector2(ek.x, ky), Vector2(ek.y, ky), Color(0.46, 0.43, 0.39), 4.0)
			wc.line(Vector2(ek.x, ky - 2.0), Vector2(ek.y, ky - 2.0), Color(0.82, 0.78, 0.70), 1.5)


# limestone flags across the corridor, for the cathedral's square
static func _flags_in_corridor(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	_corridor(wc, a, z, Color(0.50, 0.47, 0.42))
	var rh := 30.0
	var fw := 44.0
	var r := int(floorf(a / rh))
	var ry := float(r) * rh
	while ry < z:
		var ra := maxf(ry, a)
		var rz := minf(ry + rh, z)
		var e := _edges_at(ry + rh * 0.5)
		var ti := 1.5 if ra == ry else 0.0
		var bi := 1.5 if rz == ry + rh else 0.0
		var off := fw * 0.5 * float(r % 2)
		var x := floorf((e.x - off) / fw) * fw + off
		var i := 0
		while x < e.y:
			var w := fw * (0.7 + 0.6 * float(_hi(r * 53 + i * 11) % 100) / 100.0)
			var sx0 := maxf(x + 1.5, e.x + 1.0)
			var sx1 := minf(x + w - 1.5, e.y - 1.0)
			if sx1 - sx0 > 2.0 and rz - ra > 0.5:
				var hk := _hi(r * 97 + i * 13 + 77)
				var c: Color = FLAG_COLS[hk % FLAG_COLS.size()]
				wc.rect(Rect2(sx0, ra + ti, sx1 - sx0, rz - ra - ti - bi), c)
				if ti > 0.0:
					wc.rect(Rect2(sx0, ra + 1.5, sx1 - sx0, 1.5), Color(1.0, 0.98, 0.92, 0.12))
				if hk % 9 == 0 and ti > 0.0 and bi > 0.0:
					wc.line(Vector2(sx0 + 3.0, ra + 4.0), Vector2(sx1 - 4.0, rz - 4.0), Color(0.30, 0.27, 0.24, 0.30), 1.0)
			x += w
			i += 1
		r += 1
		ry += rh


static func _ramp(wc: ShapeBatch, a: float, z: float) -> void:
	# the cobbles run out into the grass: a soft edge, a few stray stones beyond
	var grass := _path_grass()
	if a < RAMP_END + 60.0:
		var e0 := _edges_at(RAMP_END - 40.0)
		var e1 := _edges_at(RAMP_END + 50.0)
		wc.band(PackedVector2Array([
			Vector2(e0.x, RAMP_END - 40.0), Vector2(e0.y, RAMP_END - 40.0),
			Vector2(e1.x, RAMP_END + 50.0), Vector2(e1.y, RAMP_END + 50.0),
		]), 2, grass, PackedFloat32Array([1.0, 0.0]))
		for i in range(14):
			var p := Vector2(lerpf(e0.x + 20.0, e0.y - 20.0, _h(i * 7 + 3)), RAMP_END - 50.0 + _h(i * 11 + 5) * 70.0)
			wc.rect(Rect2(p, Vector2(9.0 + _h(i) * 6.0, 6.0)), DECK_SETT[i % DECK_SETT.size()].darkened(0.1))


static func _path_grass() -> Color:
	return GRASS.lerp(Color(0.66, 0.72, 0.68), 0.40) if _frosty() else GRASS


static func _meadow_path(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var grass := _path_grass()
	_corridor(wc, a, z, grass)
	# the track the walkers have worn, wandering a little
	var ys := PackedFloat32Array([a])
	var y := floorf(a / 40.0) * 40.0 + 40.0
	while y < z:
		ys.append(y)
		y += 40.0
	ys.append(z)
	var pts := PackedVector2Array()
	var rows := 0
	for yy: float in ys:
		var cx := CX + 22.0 * sin(yy * 0.0045) + 10.0 * sin(yy * 0.013)
		pts.append(Vector2(cx - 34.0, yy))
		pts.append(Vector2(cx, yy))
		pts.append(Vector2(cx + 34.0, yy))
		rows += 1
	var ra := PackedFloat32Array()
	for i in range(rows):
		ra.append(1.0)
	var worn := Color(0.62, 0.60, 0.46) if not _frosty() else Color(0.74, 0.76, 0.70)
	wc.band(pts, 3, Color(worn.r, worn.g, worn.b, 0.55), ra, PackedFloat32Array([0.0, 1.0, 0.0]))


# the west row's houses throw their shade across the paving, the low sun
# being behind them
static func _west_shade(wc: ShapeBatch, lo: float, hi: float) -> void:
	var a := maxf(lo, CATHEDRAL_END)
	var z := minf(hi, START + 400.0)
	if z <= a:
		return
	var wdt := 46.0 * Shade.throw
	var col := Color(0.05, 0.06, 0.12, _shade_a(0.26))
	var y := a
	while y < z:
		var yn := minf(y + 40.0, z)
		var ea := _edges_at(y).x
		var eb := _edges_at(yn).x
		wc.band(PackedVector2Array([
			Vector2(ea, y), Vector2(ea + wdt, y),
			Vector2(eb, yn), Vector2(eb + wdt, yn),
		]), 2, col, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
		y = yn


# Under the porticoes: the shopfronts along the back, the deep shade beneath
# the houses' upper floors, and the cafés' tables between the columns.
static func _porticoes(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var night := Game.hour == "night"
	for side: float in SIDES:
		var ex := _edge_x((a + z) * 0.5, side)
		# the shopfronts, a window and a door to each bay
		var y := floorf(a / 60.0) * 60.0
		while y < z:
			var k := int(absf(y) / 60.0) + (0 if side < 0.0 else 50)
			var y0 := maxf(y + 4.0, a)
			var y1 := minf(y + 56.0, z)
			if y1 - y0 > 6.0:
				var sign_col: Color = SHOP_SIGNS[_hi(k * 3) % SHOP_SIGNS.size()]
				var x0 := minf(ex, ex - side * 7.0)
				wc.rect(Rect2(x0, y0, 7.0, y1 - y0), sign_col.darkened(0.25))
				wc.rect(Rect2(minf(ex - side * 2.0, ex - side * 6.0), y0 + 4.0, 4.0, (y1 - y0) * 0.6), Color(0.96, 0.84, 0.56) if not night else Color(1.0, 0.80, 0.46))
				wc.glow(Vector2(ex - side * 8.0, (y0 + y1) * 0.5), 22.0, Color(1.0, 0.84, 0.56, 0.22 if not night else 0.42))
			y += 60.0
		# the portico's shade on the flags, deepest at the back
		var sw := 64.0
		wc.band(PackedVector2Array([
			Vector2(ex, a), Vector2(ex - side * sw * 0.5, a), Vector2(ex - side * sw, a),
			Vector2(ex, z), Vector2(ex - side * sw * 0.5, z), Vector2(ex - side * sw, z),
		]), 3, Color(0.06, 0.06, 0.12, 0.46), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.55, 0.0]))
	# the cafés' tables under the arches, between the columns
	var ty := -990.0
	while ty > MARKET_END:
		if ty > a - 30.0 and ty < z + 30.0:
			for side: float in SIDES:
				var k := int(absf(ty)) + (0 if side < 0.0 else 7)
				if _hi(k) % 3 == 0:
					continue
				var tx := _edge_x(ty, side) - side * 25.0
				for dy: float in [-34.0, 34.0]:
					_cafe_table(wc, Vector2(tx, ty + dy), k + int(dy))
		ty -= 180.0


static func _cafe_table(wc: ShapeBatch, p: Vector2, k: int) -> void:
	wc.circle(p + Shade.light * 3.0, 8.0, Color(0.04, 0.05, 0.08, 0.18))
	for s: float in [-1.0, 1.0]:
		var cp := p + Vector2(0.0, s * 12.0)
		wc.rect(Rect2(cp - Vector2(5.0, 4.0), Vector2(10.0, 8.0)), Color(0.30, 0.26, 0.24) if k % 2 == 0 else Color(0.62, 0.64, 0.66))
		wc.rect(Rect2(cp.x - 5.0, cp.y + (2.5 if s > 0.0 else -4.0), 10.0, 1.5), Color(0.18, 0.16, 0.15))
	wc.circle(p, 7.0, Color(0.86, 0.85, 0.82))
	wc.circle(p + Vector2(-1.5, -1.5), 4.5, Color(0.94, 0.94, 0.92))
	if k % 3 != 2:
		# a cup and its saucer
		wc.circle(p + Vector2(2.0, 1.0), 2.4, Color(1.0, 1.0, 1.0))
		wc.circle(p + Vector2(2.0, 1.0), 1.3, Color(0.36, 0.22, 0.14))


# --- the market ---------------------------------------------------------------

static func _stalls(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(STALLS.size()):
		var s: Vector2 = STALLS[i]
		if s.y < lo - 60.0 or s.y > hi + 60.0:
			continue
		_stall(wc, i)


static func _xr(x0: float, x1: float, y: float, h: float) -> Rect2:
	return Rect2(minf(x0, x1), y, absf(x1 - x0), h)


# One stall from above: a trestle counter laid out with its goods toward the
# aisle, the striped awning over its back half, the scalloped valance along
# the awning's front and, at a charcutier's, the fuets hung from it.
static func _stall(wc: ShapeBatch, i: int) -> void:
	var s: Vector2 = STALLS[i]
	var kind: String = STALL_KINDS[i]
	var face := 1.0 if s.x < CX else -1.0
	var aw: Array = AWNINGS[_hi(i * 13 + 5) % AWNINGS.size()]
	var stripe: Color = aw[0]
	var cloth: Color = aw[1]
	var xb := s.x - face * 40.0          # the back, where the stallholder stands
	var xm := s.x + face * 2.0           # the awning's front edge
	var xf := s.x + face * 38.0          # the counter's front, on the aisle
	var foot := _xr(xb, xf, s.y - 27.0, 54.0)
	_sweep_shadow(wc, foot, Shade.light * 16.0, Color(0.04, 0.05, 0.08, _shade_a(0.24)))
	# the counter: trestles under a cloth
	var counter := _xr(xm - face * 6.0, xf, s.y - 23.0, 46.0)
	wc.rect(counter, WOOD)
	wc.rect(counter.grow(-2.0), cloth.darkened(0.08) if kind != "fuet" else Color(0.86, 0.84, 0.78))
	wc.rect(_xr(xf, xf - face * 3.0, s.y - 23.0, 46.0), WOOD_LIT)
	var gx0 := xm + face * 3.0
	var gx1 := xf - face * 4.0
	var gw := absf(gx1 - gx0)
	var gl := minf(gx0, gx1)
	match kind:
		"fuet":
			# fuets bundled in a basket, a llonganissa laid long, one cut
			var bk := Rect2(gl + 1.0, s.y - 19.0, gw - 2.0, 18.0)
			wc.rect(bk, Color(0.56, 0.40, 0.22))
			for j in range(5):
				var fy := bk.position.y + 3.0 + float(j) * 3.2
				wc.capsule(Vector2(bk.position.x + 4.0, fy), Vector2(bk.end.x - 4.0, fy + 0.6), 1.7, FUET if j % 2 == 0 else FUET.darkened(0.1))
				wc.circle(Vector2(bk.position.x + 6.0 + float(j % 3) * 7.0, fy), 0.8, Color(0.94, 0.92, 0.86))
			wc.capsule(Vector2(gl + 4.0, s.y + 6.0), Vector2(gl + gw - 4.0, s.y + 9.0), 3.4, FUET.darkened(0.05))
			wc.capsule(Vector2(gl + 4.0, s.y + 16.0), Vector2(gl + gw * 0.6, s.y + 17.0), 3.0, FUET)
			for sl in range(3):
				var sp := Vector2(gl + gw * 0.72 + float(sl) * 3.5, s.y + 16.0)
				wc.circle(sp, 3.0, Color(0.86, 0.52, 0.48))
				wc.circle(sp + Vector2(-0.8, -0.5), 0.8, Color(0.98, 0.94, 0.90))
		"cheese":
			# wheels in two stacks, one cut open, and the mató in its cups
			for j in range(3):
				var cp := Vector2(gl + 10.0 + float(j % 2) * 12.0, s.y - 12.0 + float(j) * 11.0)
				wc.circle(cp + Vector2(1.5, 1.5), 8.5, Color(0.04, 0.05, 0.08, 0.2))
				wc.circle(cp, 8.5, CHEESE_RIND.darkened(0.08 * float(j)))
				wc.circle(cp, 6.5, CHEESE_RIND.lightened(0.10))
				wc.circle(cp + Vector2(-1.5, -1.5), 3.0, CHEESE_RIND.lightened(0.22))
			var cut := Vector2(gl + gw - 9.0, s.y - 10.0)
			wc.circle(cut, 8.0, CHEESE_RIND)
			wc.circle(cut, 5.5, CHEESE)
			wc.polygon(PackedVector2Array([cut, cut + Vector2(8.0, 0.0), cut + Vector2(5.6, 5.6)]), counter_col(kind, cloth))
			for j in range(4):
				var mp := Vector2(gl + gw - 12.0 + float(j % 2) * 7.0, s.y + 8.0 + float(j / 2) * 7.0)
				wc.circle(mp, 3.2, Color(0.70, 0.70, 0.72))
				wc.circle(mp, 2.4, Color(0.98, 0.97, 0.94))
		"veg":
			# crates of tomatoes, peppers, cabbages and carrots, leeks in front
			for j in range(4):
				var cr := Rect2(gl + 1.0 + float(j % 2) * (gw * 0.5), s.y - 21.0 + float(j / 2) * 21.0, gw * 0.5 - 2.0, 19.0)
				wc.rect(cr, Color(0.66, 0.50, 0.30))
				wc.rect(cr.grow(-2.0), Color(0.36, 0.26, 0.16))
				var ci := (j + i) % 4
				var col: Color = [Color(0.86, 0.20, 0.14), VEG_GREEN, Color(0.62, 0.76, 0.48), VEG_ORANGE][ci]
				var rr := 4.2 if ci == 2 else 3.0
				var n := 0
				for py in range(3):
					for px in range(3):
						var pp := cr.position + Vector2(4.0 + float(px) * (cr.size.x - 8.0) / 2.0, 4.0 + float(py) * 5.5)
						wc.circle(pp, rr, col.darkened(0.08 * float(n % 3)))
						n += 1
			wc.capsule(Vector2(gl + 4.0, s.y + 21.0), Vector2(gl + gw - 4.0, s.y + 20.0), 2.2, Color(0.86, 0.90, 0.80))
			wc.line(Vector2(gl + gw * 0.55, s.y + 20.5), Vector2(gl + gw - 4.0, s.y + 20.0), Color(0.30, 0.52, 0.26), 4.0)
		"coats":
			# a rail of winter coats, and jumpers folded in piles
			wc.line(Vector2(gl + gw * 0.5, s.y - 22.0), Vector2(gl + gw * 0.5, s.y + 22.0), Color(0.26, 0.26, 0.28), 2.0)
			for j in range(6):
				var cy := s.y - 19.0 + float(j) * 7.4
				wc.rect(Rect2(gl + gw * 0.5 - 9.0, cy, 18.0, 6.6), COAT_COLS[(j + i) % COAT_COLS.size()])
				wc.rect(Rect2(gl + gw * 0.5 - 9.0, cy, 18.0, 1.4), Color(1.0, 1.0, 1.0, 0.10))
			for j in range(3):
				var pr := Rect2(gl + (2.0 if face < 0.0 else gw * 0.72), s.y - 18.0 + float(j) * 13.0, gw * 0.26, 10.0)
				wc.rect(pr, COAT_COLS[(j * 2 + i + 1) % COAT_COLS.size()].lightened(0.12))
				wc.line(Vector2(pr.position.x, pr.get_center().y), Vector2(pr.end.x, pr.get_center().y), Color(0, 0, 0, 0.15), 1.0)
		"bread":
			# round pa de pagès with its cross, long loaves and a coca
			for j in range(3):
				var bp := Vector2(gl + 9.0 + float(j % 2) * 13.0, s.y - 13.0 + float(j) * 9.0)
				wc.circle(bp, 6.5, BREAD)
				wc.circle(bp + Vector2(-1.5, -1.5), 4.0, BREAD.lightened(0.12))
				wc.line(bp + Vector2(-3.5, 0.0), bp + Vector2(3.5, 0.0), BREAD.darkened(0.25), 1.0)
				wc.line(bp + Vector2(0.0, -3.5), bp + Vector2(0.0, 3.5), BREAD.darkened(0.25), 1.0)
			for j in range(3):
				var ly := s.y + 9.0 + float(j) * 5.0
				wc.capsule(Vector2(gl + 4.0, ly), Vector2(gl + gw - 6.0, ly), 2.2, BREAD.darkened(0.06 * float(j)))
			wc.rect(Rect2(gl + gw - 14.0, s.y - 18.0, 10.0, 20.0), Color(0.86, 0.66, 0.36))
			wc.rect(Rect2(gl + gw - 13.0, s.y - 17.0, 8.0, 18.0), Color(0.94, 0.86, 0.60))
		"flowers":
			# buckets of flowers and the season's poinsettias
			for j in range(6):
				var fp := Vector2(gl + 7.0 + float(j % 2) * (gw - 14.0), s.y - 15.0 + float(j / 2) * 15.0)
				wc.circle(fp, 6.0, Color(0.44, 0.46, 0.50))
				wc.circle(fp, 5.0, LEAF)
				for q in range(5):
					wc.circle(fp + Vector2.from_angle(float(q) * 1.26 + float(j)) * 2.8, 1.8, BLOOMS[(j + q) % BLOOMS.size()])
			for j in range(2):
				var pp := Vector2(gl + gw * 0.5, s.y - 8.0 + float(j) * 16.0)
				for q in range(6):
					wc.line(pp, pp + Vector2.from_angle(float(q) * 1.047 + 0.3) * 6.0, Color(0.84, 0.10, 0.14), 3.0)
				wc.circle(pp, 1.5, Color(0.96, 0.84, 0.30))
	# the awning over the back half, striped from the back down to the front
	var awn := _xr(xb, xm, s.y - 28.0, 56.0)
	wc.rect(awn, cloth)
	var sy := awn.position.y
	var j2 := 0
	while sy < awn.end.y - 1.0:
		if j2 % 2 == 0:
			wc.rect(Rect2(awn.position.x, sy, awn.size.x, minf(7.0, awn.end.y - sy)), stripe)
		sy += 7.0
		j2 += 1
	# it slopes down to its front edge, so the front is in its own shade
	wc.band(PackedVector2Array([
		awn.position, Vector2(awn.end.x, awn.position.y),
		Vector2(awn.position.x, awn.end.y), awn.end,
	]), 2, Color(0.08, 0.06, 0.08, 0.22), PackedFloat32Array([1.0, 1.0]),
		PackedFloat32Array([0.0, 1.0]) if face > 0.0 else PackedFloat32Array([1.0, 0.0]))
	wc.line(Vector2(xb, awn.position.y), Vector2(xb, awn.end.y), stripe.darkened(0.25), 2.0)
	# the valance: a scalloped hem along the front
	var vy := awn.position.y + 3.5
	var vj := 0
	while vy < awn.end.y:
		wc.circle(Vector2(xm + face * 1.5, vy), 3.6, stripe if vj % 2 == 0 else cloth)
		vy += 7.0
		vj += 1
	if kind == "fuet":
		# the fuets and llonganisses hung from the awning's front bar
		wc.line(Vector2(xm, awn.position.y + 2.0), Vector2(xm, awn.end.y - 2.0), Color(0.22, 0.20, 0.18), 1.6)
		for j in range(7):
			var hy := awn.position.y + 6.0 + float(j) * 7.2
			var ln := 9.0 + float(_hi(i * 9 + j) % 6)
			wc.capsule(Vector2(xm + face * 2.0, hy), Vector2(xm + face * ln, hy + 1.0), 2.0 if j % 3 != 1 else 2.8, FUET.darkened(0.06 * float(j % 2)))
			wc.circle(Vector2(xm + face * 3.0, hy - 0.6), 0.8, Color(0.96, 0.94, 0.88))
	# a crate or two stacked behind
	var cbx := xb - face * 2.0
	wc.rect(_xr(cbx, cbx - face * 14.0, s.y + 12.0, 14.0), Color(0.62, 0.46, 0.28))
	wc.rect(_xr(cbx - face * 2.0, cbx - face * 12.0, s.y + 14.0, 10.0), Color(0.40, 0.28, 0.16))


static func counter_col(kind: String, cloth: Color) -> Color:
	return cloth.darkened(0.08) if kind != "fuet" else Color(0.86, 0.84, 0.78)


# --- the bridge -------------------------------------------------------------------

# Pont de Queralt from above: a humped deck of setts between two parapets of
# coped stone, the piers' cutwaters pointing upstream (west) into the
# current, blunt spurs downstream, the arches' shade on the water, and the
# wing walls splaying out onto each bank. Nothing round on the deck.
static func _draw_bridge(wc: ShapeBatch, lo: float, hi: float) -> void:
	var deck_l := CX - BRIDGE_HALF
	var deck_r := CX + BRIDGE_HALF
	var y0 := maxf(lo, BRIDGE_Y1 - 30.0)
	var y1 := minf(hi, BRIDGE_Y0 + 30.0)
	if y1 <= y0:
		return
	var frosty := _frosty()
	var pw := 22.0
	# the bridge's shade on the water, to the east, and under each arch
	wc.band(PackedVector2Array([
		Vector2(deck_r + pw, BRIDGE_Y1), Vector2(deck_r + pw + 70.0 * Shade.throw, BRIDGE_Y1),
		Vector2(deck_r + pw, BRIDGE_Y0), Vector2(deck_r + pw + 70.0 * Shade.throw, BRIDGE_Y0),
	]), 2, Color(0.02, 0.06, 0.08, _shade_a(0.40)), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	var spans: Array[float] = [BRIDGE_Y0, PIERS[0], PIERS[1], PIERS[2], BRIDGE_Y1]
	for si in range(spans.size() - 1):
		var sa := spans[si + 1] + 26.0
		var sb := spans[si] - 26.0
		for side: float in SIDES:
			var x0 := (deck_l - pw) if side < 0.0 else (deck_r + pw)
			wc.band(PackedVector2Array([
				Vector2(x0, sa), Vector2(x0 + side * 26.0, sa),
				Vector2(x0, sb), Vector2(x0 + side * 26.0, sb),
			]), 2, Color(0.02, 0.05, 0.07, 0.35), PackedFloat32Array([1.0, 1.0]),
				PackedFloat32Array([1.0, 0.0]))
	# the piers: cutwaters upstream, spurs downstream
	for py: float in PIERS:
		if py < y0 - 80.0 or py > y1 + 80.0:
			continue
		var wl := deck_l - pw
		var tipw := Vector2(wl - 64.0, py)
		wc.polygon(PackedVector2Array([Vector2(wl, py - 26.0), tipw, Vector2(wl, py)]), STONE_LIT)
		wc.polygon(PackedVector2Array([Vector2(wl, py), tipw, Vector2(wl, py + 26.0)]), STONE_DARK)
		wc.polygon(PackedVector2Array([Vector2(wl - 3.0, py - 20.0), tipw + Vector2(12.0, 0.0), Vector2(wl - 3.0, py + 20.0)]), STONE)
		wc.line(tipw + Vector2(12.0, 0.0), Vector2(wl - 3.0, py), STONE_LIT.lightened(0.1), 1.5)
		# the current breaking white on its point
		wc.band(PackedVector2Array([
			tipw + Vector2(-18.0, -24.0), tipw + Vector2(-2.0, -2.0),
			tipw + Vector2(-18.0, 24.0), tipw + Vector2(-2.0, 2.0),
		]), 2, Color(0.92, 0.96, 0.96, 0.55), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0]))
		var wr := deck_r + pw
		var spur := PackedVector2Array([Vector2(wr, py - 26.0), Vector2(wr + 30.0, py - 14.0), Vector2(wr + 36.0, py), Vector2(wr + 30.0, py + 14.0), Vector2(wr, py + 26.0)])
		wc.polygon(spur, STONE_DARK)
		wc.polygon(PackedVector2Array([Vector2(wr, py - 21.0), Vector2(wr + 25.0, py - 11.0), Vector2(wr + 30.0, py), Vector2(wr, py)]), STONE)
		# an eddy behind the spur
		wc.band(PackedVector2Array([
			Vector2(wr + 36.0, py - 18.0), Vector2(wr + 110.0, py - 24.0),
			Vector2(wr + 36.0, py + 18.0), Vector2(wr + 110.0, py + 24.0),
		]), 2, Color(0.62, 0.74, 0.76, 0.22), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	# the deck: setts, the crown of the hump lighter, the middle worn smooth
	var mid := (BRIDGE_Y0 + BRIDGE_Y1) * 0.5
	wc.band(PackedVector2Array([
		Vector2(deck_l, BRIDGE_Y1), Vector2(deck_r, BRIDGE_Y1),
		Vector2(deck_l, mid), Vector2(deck_r, mid),
		Vector2(deck_l, BRIDGE_Y0), Vector2(deck_r, BRIDGE_Y0),
	]), 2, Color(1.0, 0.98, 0.92, 0.14), PackedFloat32Array([0.0, 1.0, 0.0]))
	wc.band(PackedVector2Array([
		Vector2(CX - 50.0, BRIDGE_Y1), Vector2(CX, BRIDGE_Y1), Vector2(CX + 50.0, BRIDGE_Y1),
		Vector2(CX - 50.0, BRIDGE_Y0), Vector2(CX, BRIDGE_Y0), Vector2(CX + 50.0, BRIDGE_Y0),
	]), 3, Color(1.0, 0.98, 0.92, 0.10), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
	# the west parapet's shade across the deck
	wc.band(PackedVector2Array([
		Vector2(deck_l, BRIDGE_Y1), Vector2(deck_l + 18.0 * Shade.throw, BRIDGE_Y1),
		Vector2(deck_l, BRIDGE_Y0), Vector2(deck_l + 18.0 * Shade.throw, BRIDGE_Y0),
	]), 2, Color(0.05, 0.06, 0.12, _shade_a(0.30)), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	# the parapets: a wall of dressed stone under a coping of long blocks
	for side: float in SIDES:
		var px0 := (deck_l - pw) if side < 0.0 else deck_r
		wc.rect(Rect2(px0, BRIDGE_Y1, pw, BRIDGE_Y0 - BRIDGE_Y1), STONE_DARK)
		var by := BRIDGE_Y1
		var bi := 0
		while by < BRIDGE_Y0:
			var bl := 26.0 + float(_hi(bi * 5 + int(side + 2.0)) % 14)
			var b1 := minf(by + bl, BRIDGE_Y0)
			if b1 > y0 - 10.0 and by < y1 + 10.0:
				var bc := STONE.darkened(0.06 * float(_hi(bi * 3 + int(side + 4.0)) % 3))
				wc.rect(Rect2(px0 + 2.0, by + 1.0, pw - 4.0, b1 - by - 2.0), bc)
				wc.rect(Rect2(px0 + 2.0, by + 1.0, pw - 4.0, 2.0), STONE_LIT)
				wc.rect(Rect2(px0 + 2.0, by + 1.0, 2.0, b1 - by - 2.0), STONE_LIT.lerp(bc, 0.4))
				if frosty:
					wc.rect(Rect2(px0 + 3.0, by + 2.0, pw - 7.0, b1 - by - 5.0), Color(0.93, 0.96, 0.99, 0.55))
			by = b1
			bi += 1
		# the wall's outer face down to the water
		var ox := px0 + (0.0 if side < 0.0 else pw) + side * 1.5
		wc.line(Vector2(ox, BRIDGE_Y1), Vector2(ox, BRIDGE_Y0), Color(0.30, 0.28, 0.26), 3.0)
		# the wing walls splaying out onto each bank, and the posts at the ends
		for end_y: float in [BRIDGE_Y0, BRIDGE_Y1]:
			var into := 1.0 if end_y == BRIDGE_Y0 else -1.0
			var mid_x := px0 + pw * 0.5
			var tip := Vector2(mid_x + side * 34.0, end_y + into * 44.0)
			wc.line(Vector2(mid_x, end_y), tip, STONE_DARK, pw)
			wc.line(Vector2(mid_x, end_y), tip, STONE, pw - 6.0)
			if frosty:
				wc.line(Vector2(mid_x, end_y), tip, Color(0.93, 0.96, 0.99, 0.5), pw - 10.0)
			var post := Rect2(px0 - 3.0, end_y - 14.0, pw + 6.0, 28.0)
			wc.rect(Rect2(post.position + Shade.light * 6.0, post.size), Color(0.04, 0.05, 0.08, _shade_a(0.24)))
			wc.rect(post, STONE_DARK)
			wc.rect(post.grow(-3.0), STONE_LIT)
			wc.rect(Rect2(post.position + Vector2(3.0, 3.0), Vector2(post.size.x * 0.45, post.size.y - 6.0)), STONE_LIT.lightened(0.08))


# --- the cathedral ------------------------------------------------------------------

# Sant Pere: the long nave under its pitched roof, side chapels under
# lean-tos, the rounded apse, the facade and its steps on the square, and
# the square Romanesque bell tower with its pyramid roof. The cloister and
# the bishop's palace are the edge layer's.
static func _draw_cathedral(wc: ShapeBatch) -> void:
	var r := CATHEDRAL_RECT
	var frosty := _frosty()
	var sh := Color(0.04, 0.05, 0.10, _shade_a(0.28))
	# the long shadows: the church's, and the tower's longest of all
	_sweep_shadow(wc, r, Shade.light * 56.0, sh)
	_sweep_shadow(wc, TOWER_RECT, Shade.light * 190.0, sh)
	# the steps up to the door, across the square's end
	for k in range(4):
		var sw := NAVE.size.x + 18.0 - float(k) * 8.0
		var sr := Rect2(NAVE.get_center().x - sw * 0.5, r.end.y + 22.0 - float(k) * 8.0, sw, 8.0)
		wc.rect(sr, LIMESTONE_DK)
		wc.rect(Rect2(sr.position, Vector2(sr.size.x, 2.5)), LIMESTONE.lightened(0.08))
		wc.rect(Rect2(sr.position.x, sr.end.y - 1.5, sr.size.x, 1.5), Color(0.20, 0.18, 0.16, 0.5))
	# the side chapels and the sacristy under their lean-tos, filling the plot
	wc.rect(r, CATH_DK)
	var tile: Color = ROOF_TILES[1]
	var lit := tile.lightened(0.12).lerp(WARM, 0.06)
	var shade := tile.darkened(0.16).lerp(COOL, 0.06)
	var wl := Rect2(r.position.x + 3.0, NAVE.position.y + 8.0, NAVE.position.x - r.position.x - 3.0, NAVE.size.y - 16.0)
	var el := Rect2(NAVE.end.x, TOWER_RECT.end.y + 4.0, r.end.x - NAVE.end.x - 3.0, NAVE.end.y - TOWER_RECT.end.y - 12.0)
	wc.rect(wl, lit)
	wc.rect(el, shade)
	var cy := wl.position.y + 4.0
	while cy < wl.end.y:
		wc.line(Vector2(wl.position.x + 1.0, cy), Vector2(wl.end.x - 1.0, cy), lit.darkened(0.10), 1.0)
		cy += 7.0
	cy = el.position.y + 4.0
	while cy < el.end.y:
		wc.line(Vector2(el.position.x + 1.0, cy), Vector2(el.end.x - 1.0, cy), shade.darkened(0.10), 1.0)
		cy += 7.0
	if frosty:
		wc.rect(el, RIME)
	# the chapels' party walls, the buttresses between them
	var by := NAVE.position.y + 40.0
	while by < NAVE.end.y - 20.0:
		wc.rect(Rect2(r.position.x + 2.0, by - 2.0, NAVE.position.x - r.position.x, 4.0), CATH_STONE)
		if by > el.position.y:
			wc.rect(Rect2(NAVE.end.x, by - 2.0, r.end.x - NAVE.end.x - 2.0, 4.0), CATH_STONE.darkened(0.1))
		by += 52.0
	# the sacristy in the north-west corner, a little hipped roof
	var sac := Rect2(r.position.x + 2.0, r.position.y + 2.0, NAVE.position.x - r.position.x + 18.0, NAVE.position.y - r.position.y + 6.0)
	wc.rect(sac, lit.darkened(0.04))
	wc.line(sac.position, sac.end, tile.lightened(0.2), 1.5)
	# the nave: its walls' tops, then the long pitched roof
	wc.rect(NAVE.grow(3.0), CATH_STONE)
	var ridge := NAVE.get_center().x
	wc.rect(Rect2(NAVE.position.x, NAVE.position.y, ridge - NAVE.position.x, NAVE.size.y), lit)
	wc.rect(Rect2(ridge, NAVE.position.y, NAVE.end.x - ridge, NAVE.size.y), shade)
	var ty := NAVE.position.y + 4.0
	while ty < NAVE.end.y - 2.0:
		wc.line(Vector2(NAVE.position.x + 2.0, ty), Vector2(ridge - 2.0, ty), lit.darkened(0.10), 1.0)
		wc.line(Vector2(ridge + 2.0, ty), Vector2(NAVE.end.x - 2.0, ty), shade.darkened(0.10), 1.0)
		ty += 7.0
	if frosty:
		wc.rect(Rect2(ridge, NAVE.position.y, NAVE.end.x - ridge, NAVE.size.y), RIME)
	wc.line(Vector2(ridge + 3.0, NAVE.position.y), Vector2(ridge + 3.0, NAVE.end.y), Color(0.05, 0.04, 0.08, 0.22), 3.0)
	wc.line(Vector2(ridge, NAVE.position.y), Vector2(ridge, NAVE.end.y), tile.lightened(0.30), 3.5)
	# the apse: a half-cone of tiles round the east end's curve
	var ac := Vector2(ridge, NAVE.position.y)
	var segs := 10
	for si in range(segs):
		var a0 := PI + PI * float(si) / float(segs)
		var a1 := PI + PI * float(si + 1) / float(segs)
		var p0 := ac + Vector2.from_angle(a0) * APSE_R
		var p1 := ac + Vector2.from_angle(a1) * APSE_R
		var nrm := Vector2.from_angle((a0 + a1) * 0.5)
		var f := clampf(0.5 - nrm.dot(Shade.SUN) * 0.5, 0.0, 1.0)
		var col := shade.lerp(lit, f)
		wc.polygon(PackedVector2Array([ac, p0, p1]), col)
		wc.line(ac.lerp(p0, 0.15), p0, col.darkened(0.12), 1.0)
		if frosty and f < 0.5:
			wc.polygon(PackedVector2Array([ac, p0, p1]), RIME)
	for si in range(segs):
		var q0 := ac + Vector2.from_angle(PI + PI * float(si) / float(segs)) * (APSE_R + 2.0)
		var q1 := ac + Vector2.from_angle(PI + PI * float(si + 1) / float(segs)) * (APSE_R + 2.0)
		wc.line(q0, q1, CATH_STONE, 3.0)
	# the facade on the square: a stone front with its pediment's ridge
	var fac := Rect2(NAVE.position.x - 8.0, NAVE.end.y - 6.0, NAVE.size.x + 16.0, 14.0)
	wc.rect(Rect2(fac.position + Vector2(0.0, 6.0), fac.size), Color(0.04, 0.05, 0.10, 0.25))
	wc.rect(fac, LIMESTONE_DK)
	wc.rect(Rect2(fac.position, Vector2(fac.size.x, 5.0)), LIMESTONE)
	wc.line(Vector2(fac.position.x + 6.0, fac.end.y - 2.0), Vector2(fac.get_center().x, fac.position.y + 2.0), LIMESTONE.lightened(0.1), 2.0)
	wc.line(Vector2(fac.get_center().x, fac.position.y + 2.0), Vector2(fac.end.x - 6.0, fac.end.y - 2.0), LIMESTONE.darkened(0.1), 2.0)
	# the bell tower: walls, then the pyramid roof to its point
	var tr := TOWER_RECT
	wc.rect(tr.grow(2.0), CATH_DK)
	wc.rect(tr, CATH_STONE)
	wc.rect(tr.grow(-4.0), CATH_DK.lightened(0.06))
	var tc := tr.get_center()
	var inner := tr.grow(-6.0)
	var roof_col := Color(0.58, 0.40, 0.30)
	var tl := inner.position
	var tre := Vector2(inner.end.x, inner.position.y)
	var bl := Vector2(inner.position.x, inner.end.y)
	var brc := inner.end
	wc.polygon(PackedVector2Array([tl, tre, tc]), roof_col.lightened(0.16))
	wc.polygon(PackedVector2Array([tl, tc, bl]), roof_col.lightened(0.08))
	wc.polygon(PackedVector2Array([tre, brc, tc]), roof_col.darkened(0.16))
	wc.polygon(PackedVector2Array([bl, tc, brc]), roof_col.darkened(0.24))
	if frosty:
		wc.polygon(PackedVector2Array([tre, brc, tc]), RIME)
		wc.polygon(PackedVector2Array([bl, tc, brc]), RIME)
	for c: Vector2 in [tl, tre, bl, brc]:
		wc.line(c, tc, roof_col.lightened(0.30), 1.6)
	# the belfry's arched openings, under the eaves on two faces
	for k in range(3):
		var o := lerpf(tr.position.x + 16.0, tr.end.x - 16.0, float(k) / 2.0)
		wc.rect(Rect2(o - 3.0, tr.end.y - 3.0, 6.0, 3.0), Color(0.12, 0.11, 0.12))
		wc.rect(Rect2(tr.position.x, lerpf(tr.position.y + 16.0, tr.end.y - 16.0, float(k) / 2.0) - 3.0, 3.0, 6.0), Color(0.12, 0.11, 0.12))
	# the cross on the point
	wc.line(tc + Vector2(-4.0, 0.0), tc + Vector2(4.0, 0.0), IRON, 1.6)
	wc.line(tc + Vector2(0.0, -6.0), tc + Vector2(0.0, 4.0), IRON, 1.6)


# --- the props the walk draws for main ------------------------------------------

static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(ARCADE_COLS, p):
		# a portico's column: its shadow on the flags, the square plinth, the shaft
		wc.capsule(p + Shade.light * 6.0, p + Shade.light * 24.0, COL_R * 0.8, Color(0.04, 0.05, 0.10, _shade_a(0.22)))
		wc.rect(Rect2(p - Vector2(COL_R, COL_R), Vector2(COL_R * 2.0, COL_R * 2.0)), COLUMN_DK)
		wc.rect(Rect2(p - Vector2(COL_R - 2.0, COL_R - 2.0), Vector2(COL_R * 2.0 - 4.0, 3.0)), COLUMN)
		wc.circle(p, COL_R - 3.0, COLUMN)
		wc.circle(p + Vector2(-2.5, -2.5), COL_R * 0.45, COLUMN.lightened(0.14))
		return
	if _is_in(PILONES, p):
		# an iron bollard at the square's mouth
		wc.circle(p + Shade.light * 3.0, 8.0, Color(0.04, 0.05, 0.10, 0.22))
		wc.circle(p, 8.0, PILONA)
		wc.circle(p + Vector2(-2.0, -2.0), 3.0, Color(0.35, 0.35, 0.38))
		return
	if _is_in(STREET_LAMPS, p):
		wc.circle(p, 6.0, SHADOW)
		wc.circle(p, 5.0, Color(0.28, 0.28, 0.30))
		return


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	# marking spots: the walk's waymarker
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# an end of fuet dropped on its paper
	wc.polygon(PackedVector2Array([kp + Vector2(-9, -5), kp + Vector2(6, -7), kp + Vector2(9, 5), kp + Vector2(-7, 6)]), Color(0.92, 0.90, 0.84))
	wc.capsule(kp + Vector2(-5.0, 1.0), kp + Vector2(5.0, -1.0), 3.0, FUET)
	wc.capsule(kp + Vector2(-4.0, 0.0), kp + Vector2(3.0, -1.5), 1.2, FUET_LIT)


# --- the live pass ------------------------------------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_glints(wc, vt, vb)
	_draw_sausage(m, wc, vt, vb)
	_draw_people(m, wc, vt, vb)
	_draw_fog_veil(m, wc, vt, vb)


# the Mèder's surface catching what light the morning has, drifting east
static func _draw_glints(wc: ShapeBatch, vt: float, vb: float) -> void:
	if vb < BRIDGE_Y1 or vt > BRIDGE_Y0:
		return
	var t := float(AnimClock.msec()) * 0.001
	for i in range(10):
		var y := lerpf(BRIDGE_Y1 + 40.0, BRIDGE_Y0 - 40.0, _h(i * 19 + 3))
		var span := FAR_R - FAR_L
		var x := FAR_L + fposmod(_h(i * 7 + 1) * span + t * (18.0 + _h(i) * 14.0), span)
		if absf(x - CX) < BRIDGE_HALF + 30.0:
			continue
		var a := 0.18 + 0.12 * sin(t * 1.3 + float(i))
		wc.band(PackedVector2Array([
			Vector2(x - 26.0, y - 2.0), Vector2(x, y - 2.0), Vector2(x + 26.0, y - 2.0),
			Vector2(x - 26.0, y + 2.0), Vector2(x, y + 2.0), Vector2(x + 26.0, y + 2.0),
		]), 3, Color(0.86, 0.92, 0.94, a), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))


# Who is out on a Saturday morning: a stallholder at every stall and
# customers at its counter, shoppers working the aisles with their baskets,
# coffee under the porticoes, a neighbour on her doorstep down the old
# street, and someone crossing the bridge with the dog's own interest in
# the river. Wrapped up for the cold.
static func _draw_people(_m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var open := Outdoors.shops_open(Game.weather, Game.hour)
	var t := float(AnimClock.msec()) * 0.001
	if open and vt < STREET_END + 60.0 and vb > MARKET_END - 60.0:
		for i in range(STALLS.size()):
			var s: Vector2 = STALLS[i]
			if s.y < vt - 60.0 or s.y > vb + 60.0:
				continue
			var face := 1.0 if s.x < CX else -1.0
			# the stallholder, behind the counter under the awning's edge
			_folk(wc, s + Vector2(-face * 14.0, -6.0 + float(i % 3) * 6.0), Vector2(face, 0.0), 5100 + i, -1.0, {"arms": NpcFigure.Arms.READY})
			# customers at the counter, one or two
			var c1 := s + Vector2(face * 52.0, -12.0 + float(i % 2) * 8.0)
			_folk(wc, c1, Vector2(-face, 0.1), 5200 + i * 3, -1.0, {"arms": NpcFigure.Arms.READY})
			_basket(wc, c1 + Vector2(face * 3.0, 9.0))
			if i % 3 != 2:
				_folk(wc, s + Vector2(face * 58.0, 18.0), Vector2(-face, -0.3), 5201 + i * 3, -1.0, {})
		# shoppers working the aisles, up and down past the fountain
		for k in range(6):
			var lane_x := 586.0 if k % 2 == 0 else 694.0
			var span := STREET_END - MARKET_END - 120.0
			var dir := -1.0 if k % 2 == 0 else 1.0
			var off := fposmod(_h(k * 11) * span + t * 26.0 * (0.8 + _h(k) * 0.4), span)
			var y := (STREET_END - 60.0 - off) if dir < 0.0 else (MARKET_END + 60.0 + off)
			if y < vt - 30.0 or y > vb + 30.0:
				continue
			var p := Vector2(lane_x + sin(t * 0.6 + float(k)) * 6.0, y)
			_folk(wc, p, Vector2(0.0, dir), 5300 + k, t * 6.0 + float(k), {})
			_basket(wc, p + Vector2(7.0, 0.0))
		# coffee under the porticoes
		if Outdoors.terrace_diners(Game.weather, Game.hour) > 0.0 or Game.weather == "clear" or Game.fog_amount() > 0.3:
			var ty := -990.0
			while ty > MARKET_END:
				if ty > vt - 40.0 and ty < vb + 40.0:
					for side: float in SIDES:
						var k := int(absf(ty)) + (0 if side < 0.0 else 7)
						if _hi(k) % 3 == 0 or _hi(k + 3) % 2 == 0:
							continue
						var tx := _edge_x(ty, side) - side * 25.0
						_folk(wc, Vector2(tx, ty - 34.0 - 14.0), Vector2(0.0, 1.0), 5400 + k, -1.0, {"size": 0.92, "arms": NpcFigure.Arms.READY})
				ty -= 180.0
	if Game.hour != "night":
		# a neighbour on her step, sweeping, down the old street
		var np := Vector2(_edge_x(-180.0, 1.0) - 14.0, -180.0)
		if np.y > vt - 30.0 and np.y < vb + 30.0:
			_folk(wc, np, Vector2(-1.0, 0.2), 5501, -1.0, {"arms": NpcFigure.Arms.READY, "headwear": "none"})
			var bt := np + Vector2(-10.0, 6.0 + sin(t * 2.4) * 4.0)
			wc.line(np + Vector2(-4.0, 2.0), bt, Color(0.50, 0.36, 0.20), 1.6)
			wc.capsule(bt + Vector2(0.0, -4.0), bt + Vector2(0.0, 4.0), 2.4, Color(0.80, 0.68, 0.36))
		# an old man in his cap on a bench by the cathedral, watching the square
		var op := Vector2(_edge_x(-2460.0, -1.0) + 22.0, -2460.0)
		if op.y > vt - 30.0 and op.y < vb + 30.0:
			_folk(wc, op, Vector2(1.0, 0.0), 5502, -1.0, {"headwear": "cap", "headwear_col": Color(0.28, 0.24, 0.22), "hair_style": "bald"})
			wc.line(op + Vector2(6.0, 4.0), op + Vector2(14.0, 10.0), Color(0.36, 0.24, 0.14), 1.8)
		# someone stopped on the bridge, leaning on the parapet over the water
		var bp := Vector2(CX + BRIDGE_HALF - 12.0, -3830.0)
		if bp.y > vt - 30.0 and bp.y < vb + 30.0:
			_folk(wc, bp, Vector2(1.0, 0.0), 5503, -1.0, {"arms": NpcFigure.Arms.READY})


static func _folk(wc: ShapeBatch, p: Vector2, facing: Vector2, key: int, stride: float, o: Dictionary) -> void:
	var opts := o.duplicate()
	if not opts.has("top"):
		opts["top"] = WINTER_TOPS[key % WINTER_TOPS.size()]
	if not opts.has("headwear") and (Game.fog_amount() > 0.3 or Game.weather == "snow") and key % 3 != 0:
		opts["headwear"] = "beanie"
		opts["headwear_col"] = HATS[(key / 3) % HATS.size()]
	NpcFigure.person(wc, p, facing, key, stride, opts)


static func _basket(wc: ShapeBatch, p: Vector2) -> void:
	wc.rect(Rect2(p - Vector2(4.0, 3.0), Vector2(8.0, 6.0)), Color(0.62, 0.44, 0.24))
	wc.rect(Rect2(p - Vector2(3.0, 2.0), Vector2(6.0, 4.0)), Color(0.36, 0.56, 0.26))
	wc.line(p + Vector2(-4.0, -3.0), p + Vector2(4.0, -3.0), Color(0.46, 0.30, 0.16), 1.2)


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


static func draw_overhead(_m: Node2D, ci: Object) -> void:
	# the bell tower's top lost in the fog, over everyone
	var fog := Game.fog_amount()
	if fog < 0.25:
		return
	var c: ShapeBatch = ci if ci is ShapeBatch else null
	if c == null:
		return
	c.glow(TOWER_RECT.get_center() + Vector2(0.0, -40.0), 110.0,
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
	# the riverside meadow: rimed grass, the Mèder's backwater by the gate in
	# its reeds (where it handles as water), bare poplars along it
	var r: Rect2 = m._freedom_rect()
	var gy := r.end.y
	var top := r.position.y
	var b := ShapeBatch.new()
	b.lod = true
	var grass := _path_grass()
	b.rect(Rect2(r.position.x - 200.0, top - 40.0, r.size.x + 400.0, r.size.y + 80.0), grass)
	for i in range(10):
		var gp := Vector2(lerpf(r.position.x, r.end.x, _h(i * 13 + 2)), lerpf(top, gy, _h(i * 7 + 9)))
		var gcol := GRASS_LIT if i % 2 == 0 else GRASS_DK
		if _frosty():
			gcol = gcol.lerp(Color(0.86, 0.90, 0.88), 0.4)
		b.glow(gp, 110.0 + _h(i) * 90.0, Color(gcol.r, gcol.g, gcol.b, 0.40))
	if _frosty():
		for i in range(40):
			var fp := Vector2(lerpf(r.position.x + 20.0, r.end.x - 20.0, _h(i * 3 + 1)), lerpf(top + 20.0, gy - 20.0, _h(i * 7 + 3)))
			b.circle(fp, 1.5 + _h(i * 9 + 5) * 2.0, FROST)
	# the backwater: matches surface(), x RIVER_L..RIVER_R, 280 px past the gate
	var gate := float(m.GATE_Y)
	var w := Rect2(RIVER_L, gate - 280.0, RIVER_R - RIVER_L, 280.0)
	b.rect(w.grow(10.0), MUD)
	b.rect(w, RIVER_DEEP)
	b.band(PackedVector2Array([
		w.position, Vector2(w.end.x, w.position.y),
		Vector2(w.position.x, w.position.y + 60.0), Vector2(w.end.x, w.position.y + 60.0),
		Vector2(w.position.x, w.end.y - 60.0), Vector2(w.end.x, w.end.y - 60.0),
		Vector2(w.position.x, w.end.y), w.end,
	]), 2, RIVER_SHALLOW, PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
	b.band(PackedVector2Array([
		w.position, w.position + Vector2(50.0, 0.0),
		Vector2(w.position.x, w.end.y), Vector2(w.position.x + 50.0, w.end.y),
	]), 2, RIVER_SHALLOW, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	b.band(PackedVector2Array([
		Vector2(w.end.x - 50.0, w.position.y), Vector2(w.end.x, w.position.y),
		Vector2(w.end.x - 50.0, w.end.y), w.end,
	]), 2, RIVER_SHALLOW, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0]))
	if _frosty():
		b.rect(Rect2(w.position, Vector2(w.size.x, 10.0)), Color(0.86, 0.92, 0.96, 0.5))
	var x := w.position.x - 6.0
	var n := 0
	while x < w.end.x + 6.0:
		for ey: float in [w.position.y, w.end.y]:
			var base := Vector2(x, ey)
			var col := REED if n % 2 == 0 else REED_DK
			for s in range(3):
				b.line(base, base + Vector2(-4.0 + float(s) * 4.0, -10.0 - float(s) * 3.0), col, 1.5)
		x += 16.0
		n += 1
	for pi in range(6):
		var px := lerpf(r.position.x + 40.0, r.end.x - 40.0, float(pi) / 5.0)
		if px > RIVER_L - 40.0 and px < RIVER_R + 40.0:
			continue
		_bare_tree(b, Vector2(px, top + 60.0 + _h(pi * 3) * 40.0), 24.0, pi + 40)
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_riverside_meadow_off_leash"))
