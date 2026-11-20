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
const DARE_POS := Vector2(780.0, -2380.0)

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
	var keep_lod := b.lod
	b.lod = true
	_draw_street_houses(b, vt, vb)
	_draw_plaza_arcades(b, vt, vb)
	_draw_cathedral_edges(b, vt, vb)
	_draw_river_banks(b, vt, vb)
	_draw_meadow(b, m, vt, vb)
	b.lod = keep_lod


static func _draw_street_houses(b: ShapeBatch, vt: float, vb: float) -> void:
	# Old street: deep stone plots with shutters, balconies and doors, close on both sides.
	var lo := maxf(vt - 40.0, STREET_END)
	var hi := minf(vb + 40.0, START + 40.0)
	if hi <= lo:
		return
	var plot_y := floorf(lo / 140.0) * 140.0
	var idx := int(absf(plot_y) / 140.0)
	while plot_y < hi:
		var y0 := plot_y
		var y1 := minf(plot_y + 140.0, hi)
		if y1 > lo:
			var tile := STONE if idx % 3 != 1 else STONE_LIT
			var tile2 := WHITEWASH if idx % 3 == 2 else tile
			# west plot
			b.rect(Rect2(CX - STREET_HALF - 210.0 + 6.0, y0 + 4.0, 200.0, y1 - y0 - 4.0), SHADOW)
			b.rect(Rect2(CX - STREET_HALF - 210.0, y0, 200.0, y1 - y0), tile2)
			b.rect(Rect2(CX - STREET_HALF - 222.0, y0, 18.0, y1 - y0), TERRACOTTA)
			b.rect(Rect2(CX - STREET_HALF - 8.0, y0, 10.0, y1 - y0), STONE_DARK)
			# east plot
			b.rect(Rect2(CX + STREET_HALF + 4.0 + 6.0, y0 + 4.0, 200.0, y1 - y0 - 4.0), SHADOW)
			b.rect(Rect2(CX + STREET_HALF + 4.0, y0, 200.0, y1 - y0), tile)
			b.rect(Rect2(CX + STREET_HALF + 190.0, y0, 18.0, y1 - y0), TERRACOTTA)
			b.rect(Rect2(CX + STREET_HALF - 2.0, y0, 10.0, y1 - y0), STONE_DARK)
			# shutters, balcony, door on each side
			for side_i in range(2):
				var side: float = -1.0 if side_i == 0 else 1.0
				var edge: float = CX + side * STREET_HALF
				var inward: float = -side
				var sx: float = edge + inward * 28.0 - 11.0
				for wy_off: float in [36.0, 96.0]:
					var sy := y0 + wy_off
					if sy > y1 - 8.0:
						continue
					b.rect(Rect2(sx - 4.0, sy + 10.0, 30.0, 4.0), Color(0.20, 0.20, 0.22))
					b.rect(Rect2(sx - 2.0, sy + 8.0, 26.0, 3.0), Color(0.34, 0.34, 0.38))
					b.rect(Rect2(sx, sy - 12.0, 22.0, 18.0), SHUTTER)
					b.rect(Rect2(sx + 2.0, sy - 10.0, 8.0, 14.0), SHUTTER_DK)
					b.rect(Rect2(sx + 12.0, sy - 10.0, 8.0, 14.0), SHUTTER_DK)
				var dx: float = edge + inward * 22.0 - 7.0
				b.rect(Rect2(dx, y0 + 108.0, 14.0, 24.0), WOOD)
				b.rect(Rect2(dx + 2.0, y0 + 110.0, 10.0, 6.0), WOOD_LIT)
		idx += 1
		plot_y += 140.0


static func _draw_plaza_arcades(b: ShapeBatch, vt: float, vb: float) -> void:
	# Mercadal: continuous arcade floors, shade, shopfronts, columns and arches.
	var lo := maxf(vt - 40.0, MARKET_END)
	var hi := minf(vb + 40.0, STREET_END + 20.0)
	if hi <= lo:
		return
	const WEST_COL := 360.0
	const EAST_COL := 920.0
	const BACK_W := 200.0
	const BACK_E := 1080.0
	# arcade paving + shade under the portico
	b.rect(Rect2(BACK_W, lo, WEST_COL - BACK_W, hi - lo), ARCADE)
	b.rect(Rect2(EAST_COL, lo, BACK_E - EAST_COL, hi - lo), ARCADE)
	b.rect(Rect2(WEST_COL - 70.0, lo, 70.0, hi - lo), ARCADE_SHADE)
	b.rect(Rect2(EAST_COL, lo, 70.0, hi - lo), ARCADE_SHADE)
	# shopfront colour strips behind
	var sy := floorf(lo / 160.0) * 160.0
	var si := 0
	while sy < hi:
		var y1 := minf(sy + 160.0, hi)
		var shop := Color(0.55, 0.30, 0.22) if si % 2 == 0 else Color(0.28, 0.38, 0.48)
		if y1 > lo:
			b.rect(Rect2(BACK_W + 8.0, maxf(sy, lo) + 10.0, 36.0, y1 - maxf(sy, lo) - 20.0), shop)
			b.rect(Rect2(BACK_E - 44.0, maxf(sy, lo) + 10.0, 36.0, y1 - maxf(sy, lo) - 20.0), shop.darkened(0.05))
		si += 1
		sy += 160.0
	# columns + arch openings along both colonnades
	for c: Vector2 in ARCADE_COLS:
		if c.y < lo - 20.0 or c.y > hi + 20.0:
			continue
		b.rect(Rect2(c.x - 16.0, c.y - 10.0, 12.0, 20.0), SHADOW)
		b.rect(Rect2(c.x - 12.0, c.y - 12.0, 24.0, 24.0), COLUMN_DK)
		b.rect(Rect2(c.x - 10.0, c.y - 10.0, 20.0, 20.0), COLUMN)
		# arch void toward the square
		var inward := 1.0 if c.x < CX else -1.0
		b.circle(c + Vector2(inward * 36.0, 0.0), 22.0, ARCADE_SHADE.darkened(0.12))
	# terracotta roof strip over the arcades (depth from above)
	b.rect(Rect2(BACK_W - 8.0, lo, 28.0, hi - lo), TERRACOTTA)
	b.rect(Rect2(BACK_E - 20.0, lo, 28.0, hi - lo), TERRACOTTA)


static func _draw_cathedral_edges(b: ShapeBatch, vt: float, vb: float) -> void:
	var lo := maxf(vt - 40.0, CATHEDRAL_END)
	var hi := minf(vb + 40.0, MARKET_END)
	if hi <= lo:
		return
	# stone walls closing in toward the cathedral apron
	b.rect(Rect2(200.0, lo, 120.0, hi - lo), STONE_DARK)
	b.rect(Rect2(960.0, lo, 120.0, hi - lo), STONE_DARK)
	b.rect(Rect2(300.0, lo, 14.0, hi - lo), STONE)
	b.rect(Rect2(966.0, lo, 14.0, hi - lo), STONE)


static func _draw_river_banks(b: ShapeBatch, vt: float, vb: float) -> void:
	if vb < BRIDGE_Y1 - 40.0 or vt > BRIDGE_Y0 + 40.0:
		return
	# soft river under / beside the bridge, feathered edges
	var top := maxf(vt, BRIDGE_Y1 - 30.0)
	var bot := minf(vb, BRIDGE_Y0 + 30.0)
	b.rect(Rect2(180.0, top, RIVER_L - 180.0, bot - top), RIVER.darkened(0.08))
	b.rect(Rect2(RIVER_R, top, 1100.0 - RIVER_R, bot - top), RIVER.darkened(0.08))
	b.band(PackedVector2Array([
		Vector2(RIVER_L - 40.0, top), Vector2(RIVER_L + 30.0, top),
		Vector2(RIVER_L - 40.0, bot), Vector2(RIVER_L + 30.0, bot),
	]), 2, RIVER_LIT, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.85]))
	b.band(PackedVector2Array([
		Vector2(RIVER_R - 30.0, top), Vector2(RIVER_R + 40.0, top),
		Vector2(RIVER_R - 30.0, bot), Vector2(RIVER_R + 40.0, bot),
	]), 2, RIVER_LIT, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.85, 0.0]))


static func _draw_meadow(b: ShapeBatch, m: Node2D, vt: float, vb: float) -> void:
	if vb < GATE - 40.0 or vt > BRIDGE_END + 40.0:
		return
	var top := maxf(vt, GATE - 20.0)
	var bot := minf(vb, BRIDGE_END)
	if bot <= top:
		return
	b.quad(Vector2(200.0, top), Vector2(1080.0, top), Vector2(1080.0, bot), Vector2(200.0, bot), GRASS)
	# frost patches on the approach
	for i in range(12):
		var fx := lerpf(240.0, 1040.0, _h(i * 5 + 2))
		var fy := lerpf(top + 10.0, bot - 10.0, _h(i * 11 + 4))
		b.circle(Vector2(fx, fy), 3.0 + _h(i * 3 + 1) * 4.0, FROST)
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
		var col := PLAZA if mid < STREET_END and mid > MARKET_END else SETTS
		if mid <= BRIDGE_END:
			col = GRASS_LIT
		elif mid <= BRIDGE_Y0 and mid >= BRIDGE_Y1:
			col = STONE_LIT
		elif mid >= STREET_END:
			col = SETTS
		wc.quad(Vector2(ea.x, y2), Vector2(ea.y, y2), Vector2(eb.y, y), Vector2(eb.x, y), col)
		# sett joints on the old street
		if mid >= STREET_END:
			wc.line(Vector2(ea.x + 4.0, mid), Vector2(ea.y - 4.0, mid), SETTS_JOINT, 1.0)
		y = y2
	# panot on the Mercadal (town pavement that is not setts/stone/indoor)
	if vt < STREET_END and vb > MARKET_END:
		var e0 := _edges_at(clampf((vt + vb) * 0.5, MARKET_END, STREET_END))
		Panot.flor(wc, e0.x + 8.0, e0.y - 8.0, maxf(vt, MARKET_END), minf(vb, STREET_END),
			PANOT_INK, PANOT_SHINE)
	# bridge: stone deck, arched voids in the river, frost on parapets
	if vt < BRIDGE_Y0 + 40.0 and vb > BRIDGE_Y1 - 40.0:
		_draw_bridge(wc, vt, vb)
	# cathedral body
	if vt < CATHEDRAL_RECT.end.y + 80.0 and vb > CATHEDRAL_RECT.position.y - 80.0:
		_draw_cathedral(wc)


static func _draw_bridge(wc: ShapeBatch, vt: float, vb: float) -> void:
	var deck_l := CX - BRIDGE_HALF
	var deck_r := CX + BRIDGE_HALF
	# stone deck flagstones
	wc.rect(Rect2(deck_l, maxf(vt, BRIDGE_Y1), deck_r - deck_l, minf(vb, BRIDGE_Y0) - maxf(vt, BRIDGE_Y1)), STONE_LIT)
	var gy := BRIDGE_Y1 + 20.0
	while gy < BRIDGE_Y0:
		if gy >= vt and gy <= vb:
			wc.line(Vector2(deck_l + 4.0, gy), Vector2(deck_r - 4.0, gy), SETTS_JOINT, 1.2)
		gy += 36.0
	# three stone arches spanning the river (voids read as dark water under)
	for i in range(3):
		var ay := BRIDGE_Y0 - 70.0 - float(i) * 150.0
		if ay < vt - 50.0 or ay > vb + 50.0:
			continue
		wc.circle(Vector2(CX, ay), 58.0, STONE)
		wc.circle(Vector2(CX, ay), 58.0, SHADOW)
		wc.circle(Vector2(CX, ay), 42.0, RIVER.darkened(0.15))
		wc.glow(Vector2(CX, ay), 36.0, Color(RIVER_LIT.r, RIVER_LIT.g, RIVER_LIT.b, 0.35))
	for r: Rect2 in PARAPETS:
		if r.end.y < vt or r.position.y > vb:
			continue
		wc.rect(Rect2(r.position + Vector2(3, 4), r.size), SHADOW)
		wc.rect(r, STONE_DARK)
		wc.rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 4.0, r.size.y - 4.0), STONE)
		# frost along the coping
		wc.rect(Rect2(r.position.x - 3.0, r.position.y, r.size.x + 6.0, 10.0), FROST)
		for k in range(8):
			var fy := r.position.y + 30.0 + float(k) * 55.0
			if fy < vt or fy > vb:
				continue
			wc.circle(Vector2(r.get_center().x, fy), 3.0, FROST)


static func _draw_cathedral(wc: ShapeBatch) -> void:
	var r := CATHEDRAL_RECT
	# apron paving around the facade
	wc.rect(Rect2(r.position.x - 40.0, r.position.y - 20.0, r.size.x + 80.0, r.size.y + 60.0), STONE)
	wc.rect(Rect2(r.position + Vector2(10, 12), r.size), SHADOW)
	wc.rect(r, CATH_STONE)
	# facade steps up to the door
	for k in range(4):
		var sw := r.size.x - 40.0 - float(k) * 10.0
		wc.rect(Rect2(r.get_center().x - sw * 0.5, r.end.y - 8.0 - float(k) * 10.0, sw, 10.0),
			STONE_LIT if k % 2 == 0 else STONE_DARK)
	# rose / nave windows
	wc.circle(Vector2(r.get_center().x, r.position.y + 70.0), 28.0, CATH_DK)
	wc.circle(Vector2(r.get_center().x, r.position.y + 70.0), 18.0, Color(0.35, 0.42, 0.48, 0.55))
	for k in range(3):
		wc.rect(Rect2(r.position.x + 28.0 + float(k) * 55.0, r.position.y + 120.0, 26.0, 70.0), Color(0.30, 0.36, 0.42, 0.6))
	# Romanesque bell tower — big enough to read from above even half lost in fog
	var fog := Game.fog_amount()
	var base := TOWER_BASE
	wc.rect(Rect2(base.x - 38.0 + 8.0, base.y - 280.0 + 10.0, 76.0, 280.0), SHADOW)
	wc.rect(Rect2(base.x - 38.0, base.y - 280.0, 76.0, 280.0), CATH_DK)
	wc.rect(Rect2(base.x - 30.0, base.y - 268.0, 60.0, 260.0), CATH_STONE)
	# staged setbacks so the shaft reads as a tower, not a box
	wc.rect(Rect2(base.x - 26.0, base.y - 200.0, 52.0, 8.0), STONE_LIT)
	wc.rect(Rect2(base.x - 26.0, base.y - 120.0, 52.0, 8.0), STONE_LIT)
	for k in range(4):
		var ty := base.y - 70.0 - float(k) * 48.0
		wc.rect(Rect2(base.x - 16.0, ty, 14.0, 26.0), Color(0.18, 0.18, 0.20, 0.75))
		wc.rect(Rect2(base.x + 4.0, ty, 14.0, 26.0), Color(0.18, 0.18, 0.20, 0.75))
	wc.rect(Rect2(base.x - 44.0, base.y - 300.0, 88.0, 28.0), TOWER_TOP)
	wc.circle(base + Vector2(0.0, -310.0), 12.0, TOWER_TOP.lightened(0.12))
	# fog only eats the very top; the shaft stays readable nearby
	if fog > 0.25:
		var a := clampf(fog, 0.0, 1.0) * 0.55
		wc.glow(base + Vector2(0.0, -290.0), 90.0, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a))
		wc.glow(base + Vector2(0.0, -330.0), 110.0, Color(FOG_VEIL.r, FOG_VEIL.g, FOG_VEIL.b, a * 0.85))


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
		wc.rect(Rect2(s.x - 42.0 + 5.0, s.y - 30.0 + 5.0, 84.0, 52.0), SHADOW)
		# striped awning
		wc.rect(Rect2(s.x - 42.0, s.y - 30.0, 84.0, 16.0), CANVAS)
		for stripe in range(7):
			var sx := s.x - 40.0 + float(stripe) * 12.0
			wc.rect(Rect2(sx, s.y - 28.0, 6.0, 12.0), CANVAS_DK if stripe % 2 == 0 else CANVAS.lightened(0.1))
		# counter
		wc.rect(Rect2(s.x - 38.0, s.y - 10.0, 76.0, 30.0), WOOD)
		wc.rect(Rect2(s.x - 36.0, s.y - 8.0, 72.0, 6.0), WOOD_LIT)
		match kind:
			"fuet":
				# fuet and llonganissa hanging — readable at a glance
				for k in range(6):
					var hx := s.x - 28.0 + float(k) * 11.0
					wc.line(Vector2(hx, s.y - 30.0), Vector2(hx, s.y - 14.0), Color(0.18, 0.16, 0.14), 1.4)
					wc.capsule(Vector2(hx, s.y - 14.0), Vector2(hx + 2.0, s.y - 2.0), 5.5, FUET)
					wc.circle(Vector2(hx - 1.0, s.y - 16.0), 3.0, FUET_LIT)
			"cheese":
				for k in range(4):
					var cx := s.x - 22.0 + float(k) * 14.0
					wc.circle(Vector2(cx, s.y + 2.0), 10.0, CHEESE_RIND)
					wc.circle(Vector2(cx - 2.0, s.y), 7.0, CHEESE)
			"veg":
				wc.circle(s + Vector2(-16.0, 4.0), 8.0, VEG_GREEN)
				wc.circle(s + Vector2(-2.0, 8.0), 7.0, VEG_ORANGE)
				wc.circle(s + Vector2(14.0, 3.0), 8.0, VEG_GREEN)
				wc.circle(s + Vector2(4.0, -2.0), 5.0, Color(0.72, 0.22, 0.18))
			"coats":
				wc.rect(Rect2(s.x - 24.0, s.y - 6.0, 18.0, 26.0), COAT_NAVY)
				wc.rect(Rect2(s.x - 2.0, s.y - 6.0, 18.0, 26.0), Color(0.42, 0.22, 0.18))
				wc.rect(Rect2(s.x + 18.0, s.y - 4.0, 16.0, 24.0), Color(0.28, 0.32, 0.28))


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
