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
const Panot := preload("res://world/panot.gd")
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
const PLAZA := Color(0.78, 0.74, 0.66)
const PLAZA_LIT := Color(0.86, 0.82, 0.74)
const PANOT_INK := Color(0.62, 0.58, 0.50, 0.42)
const PANOT_SHINE := Color(0.92, 0.88, 0.80, 0.28)
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
const RIVER := Color(0.28, 0.42, 0.48)
const RIVER_LIT := Color(0.42, 0.58, 0.62)
const FROST := Color(0.92, 0.95, 0.98, 0.72)
const GRASS := Color(0.34, 0.46, 0.28)
const GRASS_LIT := Color(0.46, 0.58, 0.34)
const GRASS_DK := Color(0.22, 0.34, 0.20)
const FOG_VEIL := Color(0.78, 0.80, 0.84)
const PILONA := Color(0.18, 0.18, 0.20)
const BIN_GREEN := Color(0.18, 0.42, 0.28)

# --- landmarks ----------------------------------------------------------------
const DARE_POS := Vector2(820.0, -1480.0)
const PRIZE := Vector2(460.0, -2680.0)
const PRIZE_TEXT := "nab the mató off the cheese stall"

const STALL_FUET := Vector2(520.0, -1320.0)
const STALL_CHEESE := Vector2(760.0, -1580.0)
const STALL_VEG := Vector2(500.0, -1760.0)
const STALL_COATS := Vector2(780.0, -1180.0)
const STALLS: Array[Vector2] = [STALL_FUET, STALL_CHEESE, STALL_VEG, STALL_COATS]
const STALL_KINDS: Array[String] = ["fuet", "cheese", "veg", "coats"]

const CATHEDRAL_RECT := Rect2(720.0, -2920.0, 220.0, 380.0)
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
		{"y": -4500.0, "cx": CX, "half": MEADOW_HALF},
		{"y": GATE, "cx": CX, "half": MEADOW_HALF},
	]


static func _edges_at(y: float) -> Vector2:
	return EdgePath.edges(edge_nodes(), y, CX, HALF)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = [CATHEDRAL_RECT]
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
		Vector2(500.0, -2500.0), Vector2(560.0, -4550.0),
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
	var y := minf(vb + 40.0, START + 40.0)
	var top := maxf(vt - 40.0, GATE - 40.0)
	while y > top:
		var y2 := maxf(y - 48.0, top)
		var ea := _edges_at(y)
		var eb := _edges_at(y2)
		_draw_side(b, y, y2, ea, eb, true)
		_draw_side(b, y, y2, ea, eb, false)
		y = y2
	_draw_river_banks(b, vt, vb)
	_draw_meadow(b, m, vt, vb)


static func _draw_side(b: ShapeBatch, y: float, y2: float, ea: Vector2, eb: Vector2, west: bool) -> void:
	var x0 := (ea.x if west else ea.y)
	var x1 := (eb.x if west else eb.y)
	var mid_y := (y + y2) * 0.5
	if mid_y >= STREET_END:
		# stone house front
		var wall_x := x0 + (-55.0 if west else 0.0)
		var wall_w := 55.0
		b.quad(Vector2(wall_x, y2), Vector2(wall_x + wall_w, y2), Vector2(wall_x + wall_w, y), Vector2(wall_x, y), STONE)
		# closed shutters
		var sy := y - 16.0
		while sy > y2 + 10.0:
			var sx := wall_x + (12.0 if west else 18.0)
			b.rect(Rect2(sx, sy - 14.0, 22.0, 18.0), SHUTTER)
			b.rect(Rect2(sx + 2.0, sy - 12.0, 8.0, 14.0), SHUTTER_DK)
			b.rect(Rect2(sx + 12.0, sy - 12.0, 8.0, 14.0), SHUTTER_DK)
			sy -= 70.0
	elif mid_y >= MARKET_END:
		# arcade outer wall
		var ax := x0 + (-80.0 if west else 10.0)
		b.quad(Vector2(ax, y2), Vector2(ax + 70.0, y2), Vector2(ax + 70.0, y), Vector2(ax, y), ARCADE_SHADE)
	elif mid_y >= CATHEDRAL_END:
		b.quad(
			Vector2(x0 + (-40.0 if west else 0.0), y2),
			Vector2(x0 + (0.0 if west else 40.0), y2),
			Vector2(x1 + (0.0 if west else 40.0), y),
			Vector2(x1 + (-40.0 if west else 0.0), y),
			STONE_DARK)
	elif mid_y >= BRIDGE_Y1:
		pass  # river drawn separately
	else:
		# meadow verge
		var gx := x0 + (-90.0 if west else 0.0)
		b.quad(Vector2(gx, y2), Vector2(gx + 90.0, y2), Vector2(gx + 90.0, y), Vector2(gx, y), GRASS)


static func _draw_river_banks(b: ShapeBatch, vt: float, vb: float) -> void:
	if vb < BRIDGE_Y1 - 20.0 or vt > BRIDGE_Y0 + 20.0:
		return
	# soft river under the bridge, feathered edges (no stacked flat bands)
	var top := maxf(vt, BRIDGE_Y1)
	var bot := minf(vb, BRIDGE_Y0)
	b.rect(Rect2(RIVER_L, top, RIVER_R - RIVER_L, bot - top), RIVER)
	b.band(PackedVector2Array([
		Vector2(RIVER_L, top), Vector2(RIVER_R, top),
		Vector2(RIVER_L, bot), Vector2(RIVER_R, bot),
	]), 2, RIVER_LIT, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.85, 0.0]))


static func _draw_meadow(b: ShapeBatch, m: Node2D, vt: float, vb: float) -> void:
	if vb < GATE - 40.0 or vt > BRIDGE_END + 40.0:
		return
	var top := maxf(vt, GATE - 20.0)
	var bot := minf(vb, BRIDGE_END)
	if bot <= top:
		return
	b.quad(Vector2(200.0, top), Vector2(1080.0, top), Vector2(1080.0, bot), Vector2(200.0, bot), GRASS)
	# soft river tongue into the meadow
	if m != null and float(m.GATE_Y) < vb + 40.0:
		b.glow(Vector2(640.0, float(m.GATE_Y) - 140.0), 160.0, Color(RIVER.r, RIVER.g, RIVER.b, 0.55))


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, _ctop: float, vt: float, vb: float) -> void:
	# path surface
	var y := minf(vb + 20.0, START)
	var top := maxf(vt - 20.0, GATE)
	while y > top:
		var y2 := maxf(y - 40.0, top)
		var ea := _edges_at(y)
		var eb := _edges_at(y2)
		var mid := (y + y2) * 0.5
		var col := PLAZA if mid < STREET_END and mid > MARKET_END else STONE
		if mid <= BRIDGE_END:
			col = GRASS_LIT
		elif mid <= BRIDGE_Y0 and mid >= BRIDGE_Y1:
			col = STONE_LIT
		wc.quad(Vector2(ea.x, y2), Vector2(ea.y, y2), Vector2(eb.y, y), Vector2(eb.x, y), col)
		y = y2
	# panot on the Mercadal (town pavement that is not setts/stone/indoor)
	if vt < STREET_END and vb > MARKET_END:
		var e0 := _edges_at(clampf((vt + vb) * 0.5, MARKET_END, STREET_END))
		Panot.flor(wc, e0.x + 8.0, e0.y - 8.0, maxf(vt, MARKET_END), minf(vb, STREET_END),
			PANOT_INK, PANOT_SHINE)
	# bridge deck frost strip
	if vt < BRIDGE_Y0 and vb > BRIDGE_Y1:
		for r: Rect2 in PARAPETS:
			if r.end.y < vt or r.position.y > vb:
				continue
			wc.rect(r, STONE_DARK)
			wc.rect(Rect2(r.position.x - 2.0, r.position.y, r.size.x + 4.0, 8.0), FROST)
	# cathedral body
	if vt < CATHEDRAL_RECT.end.y and vb > CATHEDRAL_RECT.position.y:
		_draw_cathedral(wc)


static func _draw_cathedral(wc: ShapeBatch) -> void:
	var r := CATHEDRAL_RECT
	wc.rect(r, CATH_STONE)
	wc.rect(Rect2(r.position.x + 10.0, r.position.y + 20.0, r.size.x - 20.0, 30.0), CATH_DK)
	# Romanesque bell tower — upper third fades into fog
	var fog := Game.fog_amount()
	var base := TOWER_BASE
	wc.rect(Rect2(base.x - 28.0, base.y - 200.0, 56.0, 200.0), CATH_DK)
	wc.rect(Rect2(base.x - 32.0, base.y - 220.0, 64.0, 24.0), TOWER_TOP)
	# soft fog veil over the tower top (gradient glow, not stacked discs)
	if fog > 0.2:
		var a := clampf(fog, 0.0, 1.0) * 0.72
		wc.glow(base + Vector2(0.0, -210.0), 70.0, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a))
		wc.glow(base + Vector2(0.0, -250.0), 90.0, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a * 0.85))


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
		# canvas awning
		wc.rect(Rect2(s.x - 40.0, s.y - 28.0, 80.0, 14.0), CANVAS)
		wc.rect(Rect2(s.x - 38.0, s.y - 26.0, 76.0, 4.0), CANVAS_DK)
		# counter
		wc.rect(Rect2(s.x - 36.0, s.y - 8.0, 72.0, 28.0), WOOD)
		wc.rect(Rect2(s.x - 34.0, s.y - 6.0, 68.0, 6.0), WOOD_LIT)
		match kind:
			"fuet":
				for k in range(5):
					var hx := s.x - 24.0 + float(k) * 12.0
					wc.circle(Vector2(hx, s.y - 20.0), 5.0, FUET)
					wc.circle(Vector2(hx - 1.5, s.y - 21.5), 2.5, FUET_LIT)
					wc.line(Vector2(hx, s.y - 28.0), Vector2(hx, s.y - 20.0), Color(0.2, 0.2, 0.2), 1.0)
			"cheese":
				for k in range(3):
					var cx := s.x - 16.0 + float(k) * 16.0
					wc.circle(Vector2(cx, s.y + 2.0), 9.0, CHEESE_RIND)
					wc.circle(Vector2(cx - 2.0, s.y), 6.5, CHEESE)
			"veg":
				wc.circle(s + Vector2(-14.0, 4.0), 7.0, VEG_GREEN)
				wc.circle(s + Vector2(0.0, 6.0), 6.0, VEG_ORANGE)
				wc.circle(s + Vector2(14.0, 3.0), 7.0, VEG_GREEN)
			"coats":
				wc.rect(Rect2(s.x - 20.0, s.y - 4.0, 16.0, 22.0), COAT_NAVY)
				wc.rect(Rect2(s.x + 4.0, s.y - 4.0, 16.0, 22.0), Color(0.42, 0.22, 0.18))


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
	if state == "swing":
		# hook line
		wc.line(STALL_FUET + Vector2(swing * 0.3, -28.0), p, Color(0.2, 0.2, 0.2), 1.2)
	wc.circle(p + Vector2(1.5, 1.5), 8.0, SHADOW)
	wc.circle(p, 7.0, FUET)
	wc.circle(p + Vector2(-2.0, -2.0), 3.5, FUET_LIT)
	# string end
	wc.circle(p + Vector2(0.0, -6.0), 2.0, Color(0.85, 0.85, 0.80))


static func _draw_market_people(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if not Outdoors.shops_open(Game.weather, Game.hour):
		return
	# a few stallholders and shoppers that loom out of fog as she nears
	var folks: Array = [
		STALL_FUET + Vector2(-50.0, 10.0),
		STALL_CHEESE + Vector2(48.0, 8.0),
		STALL_VEG + Vector2(-48.0, 12.0),
		Vector2(640.0, -1400.0),
		Vector2(600.0, -1850.0),
	]
	var cam: Vector2 = m.dog.global_position if m.dog != null else Vector2(CX, (vt + vb) * 0.5)
	var fog := Game.fog_amount()
	for i in range(folks.size()):
		var p: Vector2 = folks[i]
		if p.y < vt - 20.0 or p.y > vb + 20.0:
			continue
		var dist := cam.distance_to(p)
		if fog > 0.35 and dist > 340.0:
			continue  # faded into the grey; they loom only as she nears
		NpcFigure.person(wc, p, Vector2(0.0, -1.0), 5100 + i, -1.0, {"arms": NpcFigure.Arms.SIDE})


static func _draw_fog_veil(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	# Soft distance veil: far strip of the viewport fades toward grey using
	# ShapeBatch.band (gradient), never a stack of flat bands. Strength follows
	# Game.fog_amount so clear-day shots stay clean.
	var fog := Game.fog_amount()
	if fog < 0.15:
		return
	var cam_y: float = m.dog.global_position.y if m.dog != null else (vt + vb) * 0.5
	var ahead := cam_y - 300.0
	if ahead < vb + 40.0 and ahead > vt - 100.0:
		var a := fog * 0.40
		var y0 := ahead - 70.0
		var y1 := ahead + 70.0
		wc.band(PackedVector2Array([
			Vector2(180.0, y0), Vector2(1100.0, y0),
			Vector2(180.0, y1), Vector2(1100.0, y1),
		]), 2, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a),
			PackedFloat32Array([0.0, 1.0]), PackedFloat32Array([1.0, 1.0]))
	# soft pools around distant landmarks
	if fog > 0.4 and TOWER_BASE.y < vb + 40.0 and TOWER_BASE.y > vt - 80.0:
		wc.glow(TOWER_BASE + Vector2(0.0, -180.0), 120.0,
			Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, fog * 0.45))


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
	# riverside meadow: soft grass and a river edge
	var r: Rect2 = m._freedom_rect()
	var gy := r.end.y
	var top := r.position.y
	var b := ShapeBatch.new()
	b.rect(Rect2(r.position.x - 40.0, top - 20.0, r.size.x + 80.0, r.size.y + 40.0), GRASS)
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
