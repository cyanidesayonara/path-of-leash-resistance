class_name Girona
extends RefCounted

# WALK 41: GIRONA — the Onyar's coloured houses, Eiffel's red iron bridge,
# the old-town steps, and La Lleona de Girona on her column at Plaça de
# Sant Feliu. Rain at dusk.
#
# South to north:
# - Rambla de la Llibertat (260 .. -720): wet dusk paving beside the Onyar
#   quay parapet on the west and hanging coloured houses + arcade porticoes on
#   the east; a bakery tray holds the prized xuixo.
# - Pont de les Peixateries Velles (-940 .. -1560): Eiffel's crimson riveted
#   iron lattice bridge crossing the River Onyar, coloured house reflections
#   shimmering on the rain-dimpled water below and iron trusses overhead.
# - Barri Vell & Old-Town Steps (-1760 .. -2560): limestone steps rising past
#   Temps de Flors blooms and covered side alcoves; a gargoyle rain-spout
#   sends telegraphed rainwater cascading down the centre of the stairs.
# - Plaça de Sant Feliu (-2780 .. -3820): wide medieval square around
#   La Lleona de Girona clinging to her Romanesque column and kissing-steps.
# - Passeig Arqueològic & Muralles (-4040 .. -4860) -> off leash in Jardins
#   dels Alemanys (y < -5000).

const SOFT_WEAR := true
const OVERHEAD_FOLLOWS_CAMERA := true

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["cam_lean", "draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer", "draw_freedom", "draw_live", "draw_overhead", "draw_snack", "hush_banner", "idle_status", "is_lamp", "night_fronts", "night_lights", "on_bark", "surface", "tick", "tree_kind", "urgent_status"]

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EdgePath := preload("res://world/edge_path.gd")
const Panot := preload("res://world/panot.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const BossLleona := preload("res://systems/boss_lleona.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")

const CX := 640.0
const HALF := 280.0
const START := 260.0
const GATE := -5000.0
const SHADOW := Color(0.05, 0.05, 0.10, 0.28)

# --- route zones --------------------------------------------------------------
const RAMBLA_END := -720.0
const BRIDGE_Y0 := -940.0
const BRIDGE_Y1 := -1560.0
const STEPS_Y0 := -1760.0
const STEPS_Y1 := -2560.0
const PLACA_Y0 := -2780.0
const PLACA_Y1 := -3820.0
const MURALLES_Y0 := -4040.0
const MURALLES_Y1 := -4860.0

const RAMBLA_HALF := 230.0
const BRIDGE_HALF := 140.0
const STEPS_HALF := 210.0
const PLACA_HALF := 310.0
const MURALLES_HALF := 240.0

# --- colours: rainy dusk stone, Onyar pigments, Eiffel crimson ---------------
const WATER_DEEP := Color(0.07, 0.13, 0.22)
const WATER_MID := Color(0.11, 0.21, 0.32)
const WATER_BANK := Color(0.16, 0.26, 0.36)
const PAVE_DUSK := Color(0.36, 0.36, 0.42)
const PAVE_LIT := Color(0.46, 0.45, 0.50)
const STEP_STONE := Color(0.54, 0.52, 0.48)
const STEP_LIT := Color(0.68, 0.64, 0.56)
const STEP_DARK := Color(0.32, 0.31, 0.30)
const FLAG_COLS: Array[Color] = [
	Color(0.52, 0.50, 0.48), Color(0.48, 0.46, 0.45),
	Color(0.56, 0.53, 0.50), Color(0.44, 0.43, 0.44),
]
const EIFFEL_RED := Color(0.68, 0.16, 0.14)
const EIFFEL_LIT := Color(0.84, 0.26, 0.22)
const EIFFEL_DK := Color(0.38, 0.09, 0.09)
const DECK_WOOD := Color(0.36, 0.26, 0.19)
const DECK_WET := Color(0.24, 0.18, 0.14)
const LIMESTONE := Color(0.66, 0.62, 0.54)
const LIMESTONE_LIT := Color(0.80, 0.75, 0.66)
const LIMESTONE_DK := Color(0.42, 0.39, 0.36)
const ROOF_DARK := Color(0.42, 0.24, 0.19)
const ROOF_LIT := Color(0.54, 0.32, 0.24)
const IRON := Color(0.14, 0.15, 0.19)
const LAMP_WARM := Color(1.0, 0.80, 0.46)
const GRASS_MOSS := Color(0.24, 0.36, 0.22)
const GRASS_LIT := Color(0.34, 0.48, 0.28)
const GRASS_DK := Color(0.16, 0.25, 0.16)
const ONYAR_PIGMENTS: Array[Color] = [
	Color(0.92, 0.72, 0.28), # saffron ochre
	Color(0.86, 0.44, 0.28), # burnt terracotta
	Color(0.90, 0.56, 0.46), # salmon coral
	Color(0.92, 0.86, 0.70), # warm cream
	Color(0.84, 0.58, 0.64), # faded rose
	Color(0.76, 0.48, 0.26), # sienna
]
const FLOWER_COLS: Array[Color] = [
	Color(0.94, 0.34, 0.52),
	Color(0.98, 0.76, 0.22),
	Color(0.86, 0.26, 0.24),
	Color(0.56, 0.40, 0.84),
	Color(0.96, 0.94, 0.88),
]

# --- landmarks & props --------------------------------------------------------
const DARE_POS := Vector2(474.0, -2140.0)
const PRIZE := Vector2(785.0, -480.0)
const PRIZE_TEXT := "nab the xuixo off the bakery tray"

const LLEONA_COL := Vector2(640.0, -3320.0)
const LLEONA_PLINTH := Rect2(618.0, -3342.0, 44.0, 44.0)

const RAMBLA_QUAY := Rect2(372.0, RAMBLA_END, 36.0, START - RAMBLA_END)
const RAMBLA_EAST_WALL := Rect2(872.0, RAMBLA_END, 60.0, START - RAMBLA_END)
const BRIDGE_WALL_L := Rect2(476.0, BRIDGE_Y1 + 5.0, 22.0, (BRIDGE_Y0 - BRIDGE_Y1) - 10.0)
const BRIDGE_WALL_R := Rect2(782.0, BRIDGE_Y1 + 5.0, 22.0, (BRIDGE_Y0 - BRIDGE_Y1) - 10.0)
const STEPS_WALL_L := Rect2(368.0, STEPS_Y1, 60.0, STEPS_Y0 - STEPS_Y1)
const STEPS_WALL_R := Rect2(852.0, STEPS_Y1, 60.0, STEPS_Y0 - STEPS_Y1)
const PLACA_PARAPET_L := Rect2(308.0, PLACA_Y1, 20.0, PLACA_Y0 - PLACA_Y1)
const PLACA_WALL_R := Rect2(952.0, PLACA_Y1, 70.0, PLACA_Y0 - PLACA_Y1)
const MURALLES_WALL_L := Rect2(340.0, MURALLES_Y1, 58.0, MURALLES_Y0 - MURALLES_Y1)
const MURALLES_WALL_R := Rect2(882.0, MURALLES_Y1, 58.0, MURALLES_Y0 - MURALLES_Y1)

const ARCADE_COLS: Array[Vector2] = [
	Vector2(816.0, -60.0), Vector2(816.0, -210.0), Vector2(816.0, -360.0),
	Vector2(816.0, -510.0), Vector2(816.0, -660.0),
]

const STEP_POSTS: Array[Vector2] = [
	Vector2(462.0, -1880.0), Vector2(818.0, -1960.0),
	Vector2(462.0, -2260.0), Vector2(818.0, -2380.0),
]

const STREET_LAMPS: Array[Vector2] = [
	Vector2(442.0, -120.0), Vector2(442.0, -440.0),
	Vector2(516.0, -880.0), Vector2(764.0, -880.0),
	Vector2(516.0, -1620.0), Vector2(764.0, -1620.0),
	Vector2(462.0, -2060.0), Vector2(818.0, -2160.0),
	Vector2(410.0, -2960.0), Vector2(870.0, -2960.0),
	Vector2(410.0, -3680.0), Vector2(870.0, -3680.0),
	Vector2(440.0, -4220.0), Vector2(840.0, -4560.0),
]

const CYPRESS_TREES: Array[Vector2] = [
	Vector2(436.0, -4120.0), Vector2(844.0, -4280.0),
	Vector2(436.0, -4460.0), Vector2(844.0, -4640.0),
	Vector2(442.0, -4800.0), Vector2(838.0, -4820.0),
]

const PILONES: Array[Vector2] = [
	Vector2(536.0, -760.0), Vector2(744.0, -760.0),
	Vector2(536.0, -1720.0), Vector2(744.0, -1720.0),
]

const HOUSE_SNIFFS: Array[Vector2] = [
	Vector2(842.0, -180.0),
	Vector2(842.0, -520.0),
	Vector2(455.0, -1880.0),
	Vector2(825.0, -2060.0),
	Vector2(455.0, -2420.0),
]

# --- old-town steps cascade live event ----------------------------------------
const SPOUT_TOP := -2460.0
const SPOUT_BOT := -1800.0
const SPOUT_X0 := 520.0
const SPOUT_X1 := 760.0
const SPOUT_FIRST := 2.2
const SPOUT_WARN := 1.0
const SPOUT_RUSH := 2.6
const SPOUT_COOLDOWN := 11.0

const CHUNK := 156.0
const SIDES: Array[float] = [-1.0, 1.0]
const FAR_L := -320.0
const FAR_R := 1600.0

static var _nodes: Array = []
static var _recs := {}
static var _recs_key: Array = []


static func _h(k: int) -> float:
	return fposmod(absf(sin(float(k) * 12.9898 + 4.13) * 43758.5453), 1.0)


static func _hi(k: int) -> int:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16)) % 1000003


static func _is_in(list: Array[Vector2], p: Vector2) -> bool:
	for q: Vector2 in list:
		if p.distance_squared_to(q) < 4.0:
			return true
	return false


# --- corridor -----------------------------------------------------------------

static func edge_nodes(_m: Node2D = null) -> Array:
	return [
		{"y": START, "cx": CX, "half": RAMBLA_HALF},
		{"y": RAMBLA_END, "cx": CX, "half": RAMBLA_HALF},
		{"y": BRIDGE_Y0, "cx": CX, "half": BRIDGE_HALF},
		{"y": BRIDGE_Y1, "cx": CX, "half": BRIDGE_HALF},
		{"y": STEPS_Y0, "cx": CX, "half": STEPS_HALF},
		{"y": STEPS_Y1, "cx": CX, "half": STEPS_HALF},
		{"y": PLACA_Y0, "cx": CX, "half": PLACA_HALF},
		{"y": PLACA_Y1, "cx": CX, "half": PLACA_HALF},
		{"y": MURALLES_Y0, "cx": CX, "half": MURALLES_HALF},
		{"y": MURALLES_Y1, "cx": CX, "half": MURALLES_HALF},
		{"y": GATE, "cx": CX, "half": 260.0},
	]


static func _edges_at(y: float) -> Vector2:
	if _nodes.is_empty():
		_nodes = edge_nodes()
	return EdgePath.edges(_nodes, y, CX, HALF)


static func _edge_x(y: float, side: float) -> float:
	var e := _edges_at(y)
	return e.x if side < 0.0 else e.y


static func solids(_m: Node2D = null) -> Array[Rect2]:
	return [
		RAMBLA_QUAY,
		RAMBLA_EAST_WALL,
		BRIDGE_WALL_L,
		BRIDGE_WALL_R,
		STEPS_WALL_L,
		STEPS_WALL_R,
		PLACA_PARAPET_L,
		PLACA_WALL_R,
		LLEONA_PLINTH,
		BossLleona.PLANTERS[0],
		BossLleona.PLANTERS[1],
		MURALLES_WALL_L,
		MURALLES_WALL_R,
	]


static func wrap_rects(_m: Node2D = null) -> Array[Rect2]:
	return [
		RAMBLA_QUAY,
		BRIDGE_WALL_L,
		BRIDGE_WALL_R,
		LLEONA_PLINTH,
	]


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(CYPRESS_TREES, p):
		return m.TREE_FOREST
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(STREET_LAMPS, p)


static func _rush_bot(m: Node2D) -> float:
	if m == null or not (m.get("girona_spout") is Dictionary):
		return SPOUT_TOP
	var st: Dictionary = m.girona_spout
	if String(st.get("state", "idle")) != "rush":
		return SPOUT_TOP
	var elapsed := clampf(SPOUT_RUSH - float(st.get("t", 0.0)), 0.0, SPOUT_RUSH)
	var frac := clampf(elapsed / 0.55, 0.0, 1.0)
	return lerpf(SPOUT_TOP, SPOUT_BOT, frac)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return Surfaces.S.GRASS
	# River Onyar along Rambla west bank
	if p.y > BRIDGE_Y0 and p.x < 370.0:
		return Surfaces.S.WATER
	# River Onyar sweeping east-west beneath Eiffel's red iron bridge
	if p.y <= BRIDGE_Y0 and p.y >= BRIDGE_Y1:
		if p.x < 476.0 or p.x > 804.0:
			return Surfaces.S.WATER
		return Surfaces.S.PAVEMENT
	# River Onyar west of Plaça de Sant Feliu terrace
	if p.y <= PLACA_Y0 and p.y >= PLACA_Y1 and p.x < 306.0:
		return Surfaces.S.WATER
	# Active cascade sheet pouring down the middle of the old-town steps
	if m != null and m.get("girona_spout") is Dictionary:
		var st: Dictionary = m.girona_spout
		if String(st.get("state", "idle")) == "rush":
			if p.y >= SPOUT_TOP and p.y <= _rush_bot(m) and p.x >= SPOUT_X0 and p.x <= SPOUT_X1:
				return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


# --- build --------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.water.assign([
		Rect2(-400.0, BRIDGE_Y0, 770.0, 1340.0),
		Rect2(-400.0, BRIDGE_Y1, 876.0, BRIDGE_Y0 - BRIDGE_Y1),
		Rect2(804.0, BRIDGE_Y1, 876.0, BRIDGE_Y0 - BRIDGE_Y1),
		Rect2(-400.0, PLACA_Y1, 706.0, PLACA_Y0 - PLACA_Y1),
	])
	m.islands.append({
		"rect": LLEONA_PLINTH.grow(16.0),
		"side": -1.0,
		"lead": 180.0,
	})
	m.gate_text = "JARDINS DELS ALEMANYS"
	m.gate_l = 420.0
	m.gate_r = 860.0

	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(415.0, -3320.0)], TYPE_VECTOR2, &"", null)

	m.girona_spout = {
		"state": "idle", "t": SPOUT_FIRST, "threatened": false,
		"hit": false, "warned": false, "saved_this": false,
	}
	m.girona_steps_saved = 0
	m.girona_houses_sniffed = {}
	m.lleona_dodges = 0
	m.lleona_hides = 0
	m.lleona_tripped = false
	m.lleona_blinded = false
	m.lleona_bowled = false
	m.lleona_booped = false
	m.lleona_kissed = false
	m.lleona_sat = false
	m.lleona_settled = false
	var lleona := BossLleona.new()
	lleona.setup(m)
	m.lleona = lleona

	for c: Vector2 in ARCADE_COLS:
		m.poles.append(c)
	for sp: Vector2 in STEP_POSTS:
		m.poles.append(sp)
	for lp: Vector2 in STREET_LAMPS:
		m.poles.append(lp)
	for tr: Vector2 in CYPRESS_TREES:
		m.poles.append(tr)
	for pi: Vector2 in PILONES:
		m.poles.append(pi)
	m.deco_pole_count = m.poles.size()

	m.bins = Array([
		Vector2(440.0, -400.0), Vector2(812.0, -680.0),
		Vector2(455.0, -2460.0), Vector2(870.0, -2840.0),
		Vector2(440.0, -4680.0),
	], TYPE_VECTOR2, &"", null)

	m.benches = Array([
		Vector2(446.0, -280.0), Vector2(446.0, -580.0),
		# clear of La Lleona's square, where they would only snag the leash
		Vector2(400.0, -2860.0), Vector2(400.0, -3760.0),
		Vector2(880.0, -3760.0), Vector2(440.0, -4320.0),
		Vector2(840.0, -4480.0),
	], TYPE_VECTOR2, &"", null)

	m.cone_spots = Array([
		Vector2(580.0, -160.0), Vector2(690.0, -540.0),
		Vector2(610.0, -1120.0), Vector2(680.0, -1420.0),
		Vector2(560.0, -2340.0), Vector2(760.0, -3040.0),
		Vector2(500.0, -3560.0), Vector2(660.0, -4380.0),
	], TYPE_VECTOR2, &"", null)

	var marks: Array[Vector2] = []
	for c: Vector2 in ARCADE_COLS:
		marks.append(c)
	marks.append(Vector2(450.0, -190.0))
	marks.append(Vector2(470.0, -2000.0))
	marks.append(Vector2(800.0, -2420.0))
	marks.append(Vector2(575.0, -3320.0))
	marks.append(Vector2(820.0, -4400.0))

	var snacks: Array[Vector2] = [
		Vector2(660.0, -340.0), Vector2(640.0, -1260.0),
		Vector2(795.0, -2080.0), Vector2(520.0, -3200.0),
		Vector2(680.0, -4240.0),
	]
	return [marks, snacks]


# --- live gameplay ------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	if m.lleona != null:
		m.lleona.tick_state(delta)
	_tick_house_sniffs(m, dp)
	_tick_spout(m, delta, dp, hp)


static func _tick_house_sniffs(m: Node2D, dp: Vector2) -> void:
	var speed := 0.0
	if m.dog.get("velocity") is Vector2:
		speed = (m.dog.velocity as Vector2).length()
	for i in range(HOUSE_SNIFFS.size()):
		if m.girona_houses_sniffed.has(i):
			continue
		if dp.distance_to(HOUSE_SNIFFS[i]) < 52.0 and speed < 110.0:
			m.girona_houses_sniffed[i] = true
			m.award_points(1, I18n.t("w_onyar_scent_1"))
			_sfx(m, "rustle", 1.05)


static func _tick_spout(m: Node2D, delta: float, dp: Vector2, hp: Vector2) -> void:
	var st: Dictionary = m.girona_spout
	if st.is_empty():
		st = {"state": "idle", "t": SPOUT_FIRST, "threatened": false, "hit": false, "warned": false, "saved_this": false}
		m.girona_spout = st
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))
	var near := minf(dp.y, hp.y) < STEPS_Y0 + 140.0 and maxf(dp.y, hp.y) > STEPS_Y1 - 140.0

	match state:
		"idle":
			t -= delta
			if t <= 0.0 and near:
				state = "warn"
				t = SPOUT_WARN
				st["threatened"] = hp.y <= STEPS_Y0 + 60.0 and hp.y >= STEPS_Y1 - 60.0
				st["hit"] = false
				st["saved_this"] = false
				st["warned"] = true
				m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_watch_the_steps"), Color(0.92, 0.96, 1.0), m.POP_SAY)
				m.feed.say(I18n.t("w_rain_cascade_on_the_steps"), EventFeed.Tone.LOUD)
				_sfx(m, "hiss", 0.72)
		"warn":
			t -= delta
			if hp.y <= STEPS_Y0 + 60.0 and hp.y >= STEPS_Y1 - 60.0:
				st["threatened"] = true
			if t <= 0.0:
				state = "rush"
				t = SPOUT_RUSH
				_sfx(m, "splash", 0.92)
		"rush":
			t -= delta
			st["t"] = t
			if hp.y <= STEPS_Y0 + 60.0 and hp.y >= STEPS_Y1 - 60.0:
				st["threatened"] = true
			var front := _rush_bot(m)
			var h_in_band := hp.y >= SPOUT_TOP and hp.y <= front and hp.x >= SPOUT_X0 and hp.x <= SPOUT_X1
			if h_in_band and not bool(st.get("hit", false)):
				st["hit"] = true
				m.human_soak = minf(1.0, float(m.human_soak) + 0.25)
				m.shake_t = maxf(float(m.shake_t), 0.35)
				m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_my_shoes"), Color(0.76, 0.90, 1.0), m.POP_SAY)
				m.feed.say(I18n.t("w_soaked_on_the_steps"), EventFeed.Tone.BAD)
				_sfx(m, "splash", 1.15)
			elif bool(st.get("threatened", false)) and not bool(st.get("hit", false)) and not bool(st.get("saved_this", false)):
				var h_safe := (hp.x < SPOUT_X0 - 12.0 or hp.x > SPOUT_X1 + 12.0) and hp.y <= STEPS_Y0 + 40.0 and hp.y >= STEPS_Y1 - 40.0
				if h_safe and t <= SPOUT_RUSH * 0.45:
					_award_steps_save(m, st, hp)
			if t <= 0.0:
				if bool(st.get("threatened", false)) and not bool(st.get("hit", false)) and not bool(st.get("saved_this", false)):
					_award_steps_save(m, st, hp)
				state = "idle"
				t = SPOUT_COOLDOWN
				st["warned"] = false

	st["state"] = state
	st["t"] = t
	m.girona_spout = st


static func _award_steps_save(m: Node2D, st: Dictionary, hp: Vector2) -> void:
	st["saved_this"] = true
	m.girona_steps_saved += 1
	m.bones += 5
	m.award_points(4, I18n.t("w_dry_landing_4"))
	m.combo.add("DRY SAVE", 4)
	m.feed.say(I18n.t("w_kept_dry_on_the_steps"), EventFeed.Tone.GOOD)
	m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_saved_my_shoes"), Color(0.96, 0.94, 0.88), m.POP_SAY)
	_sfx(m, "star", 1.05)


# the whole of what she asks of the dog, over the bladder and the reel
static func urgent_status(m: Node2D) -> String:
	return m.lleona.status() if m.lleona != null else ""


static func hush_banner(m: Node2D) -> bool:
	return m.lleona != null and m.lleona.hush_banner()


static func cam_lean(m: Node2D) -> float:
	return m.lleona.lean if m.lleona != null else 0.0


static func idle_status(m: Node2D) -> String:
	var st: Dictionary = m.girona_spout if m.get("girona_spout") is Dictionary else {}
	var state := String(st.get("state", "idle"))
	if state == "warn":
		return I18n.t("girona_cascade_warn")
	if state == "rush":
		return I18n.t("girona_cascade_rush")
	return ""


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	if m.lleona != null and m.lleona.on_bark_action(p):
		return true
	var acted := false
	for i in range(HOUSE_SNIFFS.size()):
		if not m.girona_houses_sniffed.has(i) and p.distance_to(HOUSE_SNIFFS[i]) < 78.0:
			m.girona_houses_sniffed[i] = true
			m.award_points(1, I18n.t("w_onyar_scent_1"))
			acted = true
	return acted


static func _sfx(m: Node2D, sfx_name: String, pitch: float = 1.0) -> void:
	var sfx: Node = m.get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play(sfx_name, pitch, -3.0)
	else:
		Sfx.play(sfx_name, pitch)


# --- caching ------------------------------------------------------------------

static func _rec_valid() -> void:
	var key := [Game.weather, Game.hour, snappedf(Game.lamp_glow(), 0.05), Shade.throw]
	if key != _recs_key:
		_recs.clear()
		_recs_key = key


static func _cached(wc: ShapeBatch, key: Array, fn: Callable) -> void:
	var rec: ShapeBatch = _recs.get(key)
	if rec == null:
		rec = ShapeBatch.new()
		rec.lod = true
		fn.call(rec)
		_recs[key] = rec
	rec.append_to(wc)


static func _outside(b: ShapeBatch, side: float, y0: float, y1: float, col: Color, from := 0.0) -> void:
	var far := FAR_L if side < 0.0 else FAR_R
	var y := y0
	var xa := _edge_x(y, side) + side * from
	while y < y1:
		var yn := minf(y + 24.0, y1)
		var xb := _edge_x(yn, side) + side * from
		b.quad(Vector2(xa, y), Vector2(far, y), Vector2(far, yn), Vector2(xb, yn), col)
		xa = xb
		y = yn


static func _corridor(wc: ShapeBatch, y0: float, y1: float, col: Color, inset := 0.0) -> void:
	var y := y0
	var ea := _edges_at(y)
	while y < y1:
		var yn := minf(y + 24.0, y1)
		var eb := _edges_at(yn)
		wc.quad(Vector2(ea.x + inset, y), Vector2(ea.y - inset, y), Vector2(eb.y - inset, yn), Vector2(eb.x + inset, yn), col)
		ea = eb
		y = yn


static func _sweep_shadow(b: ShapeBatch, r: Rect2, v: Vector2, col: Color) -> void:
	b.polygon(PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y) + v,
		r.end + v, Vector2(r.position.x, r.end.y) + v, Vector2(r.position.x, r.end.y),
	]), col)


# --- edge layer: Onyar river, hanging coloured houses, Barri Vell, Sant Feliu, Muralles

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 80.0, GATE - 80.0)
	var hi := minf(vb + 80.0, START + 760.0)
	if hi > lo:
		# South Onyar river & hanging facades across from Rambla (260..-940)
		if hi > BRIDGE_Y0 - 40.0 and lo < START + 760.0:
			_cached(b, ["onyar_south"], _draw_onyar_south.bind(-1.0e9, 1.0e9))
		# River Onyar spanning under Eiffel bridge + coloured house banks (-940..-1560)
		if hi > BRIDGE_Y1 - 120.0 and lo < BRIDGE_Y0 + 120.0:
			_cached(b, ["onyar_crossing"], _draw_onyar_crossing)
		# Barri Vell medieval houses & stone flanks (-1560..-2780)
		if hi > PLACA_Y0 - 60.0 and lo < BRIDGE_Y1 + 20.0:
			_cached(b, ["barri_vell"], _draw_barri_vell)
		# Plaça de Sant Feliu river flank west, Gothic church & bell tower east (-2780..-3820)
		if hi > MURALLES_Y0 - 60.0 and lo < PLACA_Y0 + 60.0:
			_cached(b, ["sant_feliu"], _draw_sant_feliu)
		# Muralles & Jardins walls (-3820..-5080)
		if hi > GATE - 80.0 and lo < PLACA_Y1 + 60.0:
			_cached(b, ["muralles"], _draw_muralles)
	b.lod = keep_lod


static func _draw_onyar_house_row(b: ShapeBatch, x0: float, x1: float, bank_y: float, into_water_dir: float, salt: int) -> void:
	# Row of narrow coloured Onyar houses overhanging the water along `bank_y`
	var x := x0
	var idx := 0
	var glow := Game.lamp_glow()
	while x < x1 - 12.0:
		var w := 48.0 + float(_hi(idx * 17 + salt) % 24)
		var w_use := minf(w, x1 - x)
		var col := ONYAR_PIGMENTS[_hi(idx * 13 + salt) % ONYAR_PIGMENTS.size()]
		var overhang := 18.0 + float(_hi(idx * 7 + salt) % 14)
		var depth := 98.0
		var y_water := bank_y + into_water_dir * overhang
		var y_back := bank_y - into_water_dir * depth
		var r := Rect2(x, minf(y_water, y_back), w_use - 2.0, absf(y_water - y_back))
		# Soft water drop shadow under cantilever
		b.rect(Rect2(r.position.x, bank_y, r.size.x, into_water_dir * (overhang + 10.0)).abs(), Color(0.03, 0.05, 0.10, 0.36))
		# Facade overhang + pitched terracotta roof
		b.rect(r, col.darkened(0.08))
		var roof_r := Rect2(r.position.x, minf(y_back, bank_y), r.size.x, depth)
		b.rect(roof_r, ROOF_DARK if idx % 2 == 0 else ROOF_LIT)
		b.line(Vector2(roof_r.position.x, roof_r.get_center().y), Vector2(roof_r.end.x, roof_r.get_center().y), ROOF_LIT.lightened(0.18), 2.5)
		# Windows on overhanging river face
		var win_y := y_water - into_water_dir * 12.0
		var nwin := 2 if w_use > 44.0 else 1
		for wi in range(nwin):
			var wx := x + w_use * (0.30 if nwin == 2 and wi == 0 else (0.70 if nwin == 2 else 0.50))
			var wr := Rect2(wx - 4.5, win_y - 4.0, 9.0, 8.0)
			var lit := (_hi(idx * 31 + wi + salt) % 3) != 0
			b.rect(wr.grow(1.2), col.lightened(0.18))
			b.rect(wr, LAMP_WARM if lit else Color(0.14, 0.16, 0.22))
			if lit and glow > 0.05:
				b.glow(Vector2(wx, win_y), 14.0, Color(LAMP_WARM.r, LAMP_WARM.g, LAMP_WARM.b, 0.18 * glow))
		x += w
		idx += 1


static func _draw_onyar_south(b: ShapeBatch, _lo: float, _hi_y: float) -> void:
	# West bank: Onyar river and overhanging opposite houses on far western bank
	b.rect(Rect2(FAR_L, BRIDGE_Y0, 410.0 - FAR_L, (START + 760.0) - BRIDGE_Y0), WATER_DEEP)
	b.band(PackedVector2Array([
		Vector2(310.0, BRIDGE_Y0), Vector2(376.0, BRIDGE_Y0),
		Vector2(310.0, START + 760.0), Vector2(376.0, START + 760.0),
	]), 2, WATER_BANK, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0]))
	# Far west bank coloured Onyar houses peeking in along x = -320 .. 190
	var y := -860.0
	var k := 0
	var glow := Game.lamp_glow()
	while y < START + 720.0:
		var h := 74.0 + float(_hi(k * 11 + 5) % 28)
		var pig := ONYAR_PIGMENTS[_hi(k * 19 + 3) % ONYAR_PIGMENTS.size()]
		var face_x := 178.0 + float(_hi(k * 7 + 2) % 26)
		# coloured house wall overhanging the river
		b.rect(Rect2(FAR_L, y, face_x - FAR_L, h - 2.0), ROOF_DARK if k % 2 == 0 else ROOF_LIT)
		b.rect(Rect2(face_x - 24.0, y, 24.0, h - 2.0), pig)
		b.rect(Rect2(face_x, y, 8.0, h - 2.0), Color(0.03, 0.05, 0.10, 0.30))
		# warm window + water reflection hint
		var wy := y + h * 0.5
		b.rect(Rect2(face_x - 14.0, wy - 7.0, 8.0, 14.0), LAMP_WARM if k % 3 != 0 else Color(0.14, 0.16, 0.22))
		if glow > 0.05 and k % 3 != 0:
			b.glow(Vector2(face_x + 14.0, wy), 20.0, Color(pig.r, pig.g, pig.b, 0.16 * glow))
		y += h
		k += 1

	# East side of Rambla: tall painted facades and pitched roofs
	_outside(b, 1.0, BRIDGE_Y0, START + 760.0, Color(0.20, 0.17, 0.18))
	y = -740.0
	k = 0
	while y < START + 720.0:
		var h := 88.0 + float(_hi(k * 23 + 9) % 34)
		var y1 := minf(y + h, START + 740.0)
		var ex0 := _edge_x(y, 1.0)
		var ex1 := _edge_x(y1, 1.0)
		var col := ONYAR_PIGMENTS[_hi(k * 13 + 7) % ONYAR_PIGMENTS.size()]
		b.quad(Vector2(ex0, y), Vector2(ex0 + 22.0, y), Vector2(ex1 + 22.0, y1), Vector2(ex1, y1), col.darkened(0.10))
		b.quad(Vector2(ex0 + 22.0, y), Vector2(FAR_R, y), Vector2(FAR_R, y1), Vector2(ex1 + 22.0, y1), ROOF_DARK if k % 2 == 0 else ROOF_LIT)
		b.line(Vector2(ex0 + 92.0, y), Vector2(ex1 + 92.0, y1), ROOF_LIT.lightened(0.2), 2.5)
		b.line(Vector2(ex0, y), Vector2(FAR_R, y), Color(0.12, 0.10, 0.12, 0.5), 2.0)
		var wy := (y + y1) * 0.5
		var wx := (ex0 + ex1) * 0.5 + 10.0
		b.rect(Rect2(wx - 4.0, wy - 7.0, 8.0, 14.0), LAMP_WARM if k % 2 == 0 else Color(0.15, 0.17, 0.22))
		y += h
		k += 1


static func _draw_onyar_crossing(b: ShapeBatch) -> void:
	# Wide Onyar river flowing east-west across the screen under Eiffel's red iron bridge
	var top := BRIDGE_Y1
	var bot := BRIDGE_Y0
	b.rect(Rect2(FAR_L, top - 16.0, FAR_R - FAR_L, (bot - top) + 32.0), WATER_DEEP)
	b.band(PackedVector2Array([
		Vector2(FAR_L, top), Vector2(FAR_R, top),
		Vector2(FAR_L, top + 90.0), Vector2(FAR_R, top + 90.0),
		Vector2(FAR_L, bot - 90.0), Vector2(FAR_R, bot - 90.0),
		Vector2(FAR_L, bot), Vector2(FAR_R, bot),
	]), 2, WATER_MID, PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
	# Stone embankments flanking the bridge abutments
	for y_bank: float in [bot, top]:
		var s := 1.0 if y_bank == bot else -1.0
		b.rect(Rect2(FAR_L, y_bank - (0.0 if s > 0.0 else 14.0), 480.0 - FAR_L, 14.0), LIMESTONE_DK)
		b.rect(Rect2(800.0, y_bank - (0.0 if s > 0.0 else 14.0), FAR_R - 800.0, 14.0), LIMESTONE_DK)
	# The famous Cases de l'Onyar lining both banks either side of the bridge!
	_draw_onyar_house_row(b, FAR_L, 466.0, bot, -1.0, 11)
	_draw_onyar_house_row(b, 814.0, FAR_R, bot, -1.0, 29)
	_draw_onyar_house_row(b, FAR_L, 466.0, top, 1.0, 47)
	_draw_onyar_house_row(b, 814.0, FAR_R, top, 1.0, 71)


static func _draw_barri_vell(b: ShapeBatch) -> void:
	# Medieval stone houses + Temps de Flors balconies flanking the Barri Vell steps
	var top := PLACA_Y0
	var bot := BRIDGE_Y1
	for side: float in SIDES:
		_outside(b, side, top, bot, Color(0.22, 0.20, 0.21))
		var y := top
		var k := 0
		while y < bot - 20.0:
			var h := 96.0 + float(_hi(k * 13 + int(side + 3.0)) % 36)
			var y1 := minf(y + h, bot)
			var e0 := _edge_x(y, side)
			var e1 := _edge_x(y1, side)
			var col := LIMESTONE if k % 3 != 0 else LIMESTONE_DK.lightened(0.08)
			if side > 0.0:
				col = col.lightened(0.05)
			else:
				col = col.darkened(0.10)
			b.quad(Vector2(e0, y), Vector2(e0 + side * 22.0, y), Vector2(e1 + side * 22.0, y1), Vector2(e1, y1), col)
			var far := FAR_L if side < 0.0 else FAR_R
			b.quad(Vector2(e0 + side * 22.0, y), Vector2(far, y), Vector2(far, y1), Vector2(e1 + side * 22.0, y1), ROOF_DARK if k % 2 == 0 else ROOF_LIT)
			b.line(Vector2(e0, y), Vector2(far, y), Color(0.14, 0.12, 0.13, 0.45), 2.0)
			# Flower-decked Temps de Flors stone balconies
			var wy := (y + y1) * 0.5
			var wx := (e0 + e1) * 0.5 + side * 9.0
			b.rect(Rect2(wx - 4.0, wy - 7.0, 8.0, 14.0), LAMP_WARM if (k + int(side)) % 2 == 0 else Color(0.16, 0.18, 0.22))
			if k % 2 == 0:
				for fi in range(3):
					var fcol := FLOWER_COLS[(k + fi) % FLOWER_COLS.size()]
					b.circle(Vector2(wx - side * 5.0, wy - 6.0 + float(fi) * 6.0), 3.0, fcol)
			y += h
			k += 1


static func _draw_sant_feliu(b: ShapeBatch) -> void:
	# West flank: Onyar river below the Sant Feliu parapet
	b.rect(Rect2(FAR_L, PLACA_Y1 - 20.0, 330.0 - FAR_L, (PLACA_Y0 - PLACA_Y1) + 40.0), WATER_DEEP)
	b.band(PackedVector2Array([
		Vector2(240.0, PLACA_Y1), Vector2(312.0, PLACA_Y1),
		Vector2(240.0, PLACA_Y0), Vector2(312.0, PLACA_Y0),
	]), 2, WATER_BANK, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0]))
	b.rect(PLACA_PARAPET_L, LIMESTONE)
	b.rect(Rect2(PLACA_PARAPET_L.position.x + 2.0, PLACA_PARAPET_L.position.y, 4.0, PLACA_PARAPET_L.size.y), LIMESTONE_LIT)

	# East flank: Basílica de Sant Feliu Gothic nave, buttresses and bell spire
	_outside(b, 1.0, PLACA_Y1, PLACA_Y0, Color(0.24, 0.22, 0.22))
	var ch := Rect2(954.0, PLACA_Y1 + 120.0, 420.0, (PLACA_Y0 - PLACA_Y1) - 240.0)
	_sweep_shadow(b, ch, Shade.light * 36.0, SHADOW)
	b.rect(ch, LIMESTONE_DK)
	b.rect(ch.grow(-6.0), ROOF_DARK)
	b.line(Vector2(ch.position.x + 90.0, ch.position.y), Vector2(ch.position.x + 90.0, ch.end.y), ROOF_LIT.lightened(0.2), 3.0)
	var by := ch.position.y + 40.0
	while by < ch.end.y - 30.0:
		b.rect(Rect2(ch.position.x - 10.0, by, 18.0, 14.0), LIMESTONE_LIT)
		by += 72.0
	# Bell tower octagon on south-west corner of basilica
	var tc := Vector2(1010.0, -3040.0)
	var oct := PackedVector2Array()
	for oi in range(8):
		oct.append(tc + Vector2.from_angle(TAU * (float(oi) + 0.5) / 8.0) * 34.0)
	b.polygon(oct, LIMESTONE)
	b.circle(tc, 18.0, Color(0.46, 0.44, 0.44))


static func _draw_muralles(b: ShapeBatch) -> void:
	# City battlements lining Passeig Arqueològic up to the gate
	for side: float in SIDES:
		_outside(b, side, GATE - 80.0, PLACA_Y1 + 60.0, GRASS_MOSS.darkened(0.15))
		var wall := MURALLES_WALL_L if side < 0.0 else MURALLES_WALL_R
		b.rect(wall, LIMESTONE_DK)
		b.rect(Rect2(wall.position.x + 5.0, wall.position.y, wall.size.x - 10.0, wall.size.y), LIMESTONE)
		var wy := wall.position.y + 8.0
		while wy < wall.end.y - 12.0:
			var mx := wall.position.x + (wall.size.x - 12.0 if side < 0.0 else 4.0)
			b.rect(Rect2(mx, wy, 8.0, 16.0), LIMESTONE_LIT)
			wy += 32.0


# --- ground pass: paving, bridge iron deck, steps, square, La Lleona column ---

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, _ctop: float, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, GATE - 40.0)
	var hi := vb + 40.0
	var c0 := int(floorf(lo / CHUNK))
	var c1 := int(floorf(hi / CHUNK))
	for c in range(c0, c1 + 1):
		_cached(wc, ["pave", c], _draw_pave.bind(float(c) * CHUNK, float(c + 1) * CHUNK))
	if lo < RAMBLA_END + 60.0 and hi > BRIDGE_Y1 - 60.0:
		_cached(wc, ["bridge_ground"], _draw_bridge_ground)
	if lo < STEPS_Y0 + 40.0 and hi > STEPS_Y1 - 40.0:
		_cached(wc, ["steps_ground"], _draw_steps_ground)
	if lo < PLACA_Y0 + 60.0 and hi > PLACA_Y1 - 60.0:
		_cached(wc, ["placa_ground"], _draw_placa_ground)
	_draw_wet_sheen(m, wc, lo, hi)
	wc.lod = keep_lod


static func _draw_pave(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	_corridor(wc, a, z, PAVE_DUSK)
	# Subtle panot paving along Rambla de la Llibertat
	var ra := maxf(a, BRIDGE_Y0)
	var rz := minf(z, START + 60.0)
	if rz > ra:
		var ry := floorf(ra / Panot.FLOR) * Panot.FLOR
		while ry < rz:
			var e := _edges_at(ry + Panot.FLOR * 0.5)
			Panot.flor_row(wc, e.x + 2.0, e.y - 2.0, ry, e.x + 2.0, Color(0.18, 0.18, 0.24, 0.28), Color(0.68, 0.72, 0.80, 0.14))
			ry += Panot.FLOR
	# Quay parapet + east arcade overhang on Rambla
	var rqa := maxf(a, RAMBLA_END)
	var rqz := minf(z, START)
	if rqz > rqa:
		wc.rect(Rect2(RAMBLA_QUAY.position.x, rqa, RAMBLA_QUAY.size.x, rqz - rqa), LIMESTONE)
		wc.rect(Rect2(RAMBLA_QUAY.end.x - 4.0, rqa, 4.0, rqz - rqa), LIMESTONE_LIT)
		wc.band(PackedVector2Array([
			Vector2(812.0, rqa), Vector2(870.0, rqa),
			Vector2(812.0, rqz), Vector2(870.0, rqz),
		]), 2, Color(0.06, 0.06, 0.12, 0.42), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0]))
	# Stone flagstones in Plaça de Sant Feliu and Passeig Arqueològic
	var pa := maxf(a, GATE - 40.0)
	var pz := minf(z, STEPS_Y1)
	if pz > pa:
		var fy := floorf(pa / 36.0) * 36.0
		var row := int(fy / 36.0)
		while fy < pz:
			var ya := maxf(fy, pa)
			var yz := minf(fy + 36.0, pz)
			if yz - ya > 1.0:
				var e := _edges_at(fy + 18.0)
				var fw := 52.0
				var off := fw * 0.5 * float(row % 2)
				var x := floorf((e.x - off) / fw) * fw + off
				var col_i := 0
				while x < e.y:
					var x0 := maxf(x + 1.5, e.x + 1.5)
					var x1 := minf(x + fw - 1.5, e.y - 1.5)
					if x1 - x0 > 2.0:
						var fc := FLAG_COLS[_hi(row * 71 + col_i * 19) % FLAG_COLS.size()]
						wc.rect(Rect2(x0, ya + 1.0, x1 - x0, yz - ya - 2.0), fc)
						if ya == fy:
							wc.rect(Rect2(x0, ya + 1.0, x1 - x0, 1.4), Color(0.86, 0.88, 0.94, 0.14))
					x += fw
					col_i += 1
			fy += 36.0
			row += 1


static func _draw_bridge_ground(wc: ShapeBatch) -> void:
	# Pont de les Peixateries Velles: dark wet planks between Eiffel's crimson iron lattice trusses
	var deck := Rect2(CX - BRIDGE_HALF, BRIDGE_Y1, BRIDGE_HALF * 2.0, BRIDGE_Y0 - BRIDGE_Y1)
	wc.rect(deck, DECK_WOOD)
	var y := BRIDGE_Y1 + 8.0
	var i := 0
	while y < BRIDGE_Y0 - 6.0:
		var col := DECK_WOOD if i % 2 == 0 else DECK_WET
		wc.rect(Rect2(deck.position.x + 2.0, y, deck.size.x - 4.0, 12.0), col)
		wc.line(Vector2(deck.position.x + 2.0, y), Vector2(deck.end.x - 2.0, y), Color(0.14, 0.10, 0.08, 0.65), 1.4)
		y += 14.0
		i += 1
	# Wet dusk centre shine along bridge planks
	wc.band(PackedVector2Array([
		Vector2(CX - 60.0, BRIDGE_Y1), Vector2(CX, BRIDGE_Y1), Vector2(CX + 60.0, BRIDGE_Y1),
		Vector2(CX - 60.0, BRIDGE_Y0), Vector2(CX, BRIDGE_Y0), Vector2(CX + 60.0, BRIDGE_Y0),
	]), 3, Color(0.76, 0.82, 0.94, 0.12), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
	# Crimson Eiffel lattice side walls
	for wall: Rect2 in [BRIDGE_WALL_L, BRIDGE_WALL_R]:
		wc.rect(Rect2(wall.position + Shade.light * 5.0, wall.size), SHADOW)
		wc.rect(wall, EIFFEL_DK)
		wc.rect(wall.grow(-3.0), EIFFEL_RED)
		wc.rect(Rect2(wall.position.x + 3.0, wall.position.y, 4.0, wall.size.y), EIFFEL_LIT)
		var ly := wall.position.y + 12.0
		while ly < wall.end.y - 16.0:
			wc.line(Vector2(wall.position.x + 2.0, ly), Vector2(wall.end.x - 2.0, ly + 18.0), EIFFEL_DK, 2.0)
			wc.line(Vector2(wall.end.x - 2.0, ly), Vector2(wall.position.x + 2.0, ly + 18.0), EIFFEL_LIT, 1.4)
			ly += 22.0


static func _draw_steps_ground(wc: ShapeBatch) -> void:
	# Pujada de Sant Domènec style old-town steps + dry covered side alcoves
	var y := -2480.0
	var idx := 0
	while y < -1840.0:
		var tread := 22.0
		var e := _edges_at(y + tread * 0.5)
		var r := Rect2(e.x + 4.0, y, (e.y - e.x) - 8.0, tread - 2.0)
		var c := STEP_STONE if idx % 2 == 0 else STEP_STONE.darkened(0.06)
		wc.rect(r, c)
		wc.rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), STEP_LIT)
		wc.rect(Rect2(r.position.x, r.end.y, r.size.x, 2.6), STEP_DARK)
		y += tread
		idx += 1
	# Covered dry side alcoves along west and east margins (clear visual safe zones!)
	for side: float in SIDES:
		var ax := (430.0 if side < 0.0 else 772.0)
		wc.rect(Rect2(ax, -2460.0, 78.0, 680.0), Color(0.56, 0.52, 0.46, 0.38))
		var edge_line_x := 508.0 if side < 0.0 else 772.0
		wc.line(Vector2(edge_line_x, -2460.0), Vector2(edge_line_x, -1780.0), Color(0.88, 0.80, 0.62, 0.50), 2.0)
	# Carved gargoyle rain-spout head at top of the steps (y = SPOUT_TOP)
	wc.rect(Rect2(CX - 28.0, SPOUT_TOP - 22.0, 56.0, 22.0), LIMESTONE_DK)
	wc.rect(Rect2(CX - 20.0, SPOUT_TOP - 16.0, 40.0, 14.0), LIMESTONE)
	wc.circle(Vector2(CX, SPOUT_TOP - 4.0), 7.0, Color(0.14, 0.18, 0.24))


static func _draw_placa_ground(wc: ShapeBatch) -> void:
	# Plaça de Sant Feliu centrepiece: La Lleona's plinth, iron kissing-steps,
	# fluted limestone column (the lioness on it is drawn by systems/boss_lleona.gd)
	var pl := LLEONA_PLINTH
	_sweep_shadow(wc, pl, Shade.light * 18.0, SHADOW)
	wc.rect(pl.grow(6.0), LIMESTONE_DK)
	wc.rect(pl, LIMESTONE)
	wc.rect(Rect2(pl.position.x, pl.position.y, pl.size.x, 4.0), LIMESTONE_LIT)
	# Little wrought-iron kissing steps on the east side of the plinth
	for si in range(3):
		var sx := pl.end.x + 2.0 + float(si) * 6.0
		wc.rect(Rect2(sx, pl.get_center().y - 10.0, 5.0, 20.0), IRON)
		wc.line(Vector2(sx, pl.get_center().y - 10.0), Vector2(sx + 5.0, pl.get_center().y - 10.0), Color(0.45, 0.48, 0.54), 1.5)
	# Column shaft & Romanesque capital
	var c := LLEONA_COL
	wc.circle(c + Shade.light * 10.0, 17.0, SHADOW)
	wc.circle(c, 16.0, LIMESTONE_DK)
	wc.circle(c, 13.5, LIMESTONE)
	wc.circle(c + Vector2(-2.5, -2.5), 7.0, LIMESTONE_LIT)


static func _draw_wet_sheen(_m: Node2D, wc: ShapeBatch, lo: float, hi: float) -> void:
	# Subtle dusk rain puddle reflections along the stone walk
	var y := floorf(maxf(lo, GATE) / 220.0) * 220.0
	while y < minf(hi, START):
		var k := int(absf(y) / 220.0)
		if k % 2 == 0:
			var e := _edges_at(y)
			var px := lerpf(e.x + 60.0, e.y - 60.0, _h(k * 17 + 9))
			var col := ONYAR_PIGMENTS[k % ONYAR_PIGMENTS.size()]
			wc.glow(Vector2(px, y), 24.0, Color(col.r, col.g, col.b, 0.08))
		y += 220.0


# --- live pass: Onyar water glints, steps cascade, lioness glint, bakery xuixo

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := wc.lod
	wc.lod = true
	var t := float(AnimClock.msec()) * 0.001
	_draw_onyar_glints(wc, vt, vb, t)
	_draw_steps_cascade(m, wc, vt, vb, t)
	_draw_house_sniff_prompts(m, wc, vt, vb)
	_draw_townsfolk(m, wc, vt, vb)
	if m.lleona != null and LLEONA_COL.y > vt - 760.0 and LLEONA_COL.y < vb + 760.0:
		m.lleona.draw(wc, vt, vb, t)
	wc.lod = keep_lod


static func _draw_townsfolk(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	# Dusk walkers & visitors: bakery browser, bridge gazer, tourist at La Lleona's steps
	var folk: Array = [
		[Vector2(832.0, -490.0), Vector2(-1.0, 0.0), 4101, Color(0.24, 0.34, 0.48), false],
		[Vector2(522.0, -1240.0), Vector2(-1.0, 0.0), 4102, Color(0.56, 0.24, 0.22), true],
		[Vector2(760.0, -1380.0), Vector2(1.0, 0.0), 4103, Color(0.26, 0.38, 0.30), true],
		[Vector2(686.0, -3320.0), Vector2(-1.0, 0.0), 4104, Color(0.30, 0.32, 0.46), false],
	]
	for i in range(folk.size()):
		var f: Array = folk[i]
		var p: Vector2 = f[0]
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		# the tourist at the kissing steps does not stay for the fight
		if i == 3 and m.lleona != null and m.lleona.in_fight():
			continue
		_cached(wc, ["folk", i], _folk_one.bind(p, f[1], int(f[2]), f[3], bool(f[4])))


static func _folk_one(wc: ShapeBatch, p: Vector2, facing: Vector2, key: int, coat: Color, brolly: bool) -> void:
	NpcFigure.person(wc, p, facing, key, -1.0, {"top": coat, "arms": NpcFigure.Arms.READY})
	if brolly and Game.weather == "rain":
		wc.circle(p + Vector2(2.0, 2.0), 15.0, SHADOW)
		wc.circle(p, 14.0, coat.darkened(0.18))
		wc.circle(p - Vector2(3.0, 3.0), 6.0, coat.lightened(0.18))
		wc.circle(p, 2.0, Color(0.76, 0.74, 0.70))


static func _draw_onyar_glints(wc: ShapeBatch, vt: float, vb: float, t: float) -> void:
	if vb < BRIDGE_Y1 - 20.0 or vt > START + 40.0:
		return
	# Coloured house reflections + rain-dimple rings on the Onyar under Eiffel bridge
	if vt < BRIDGE_Y0 + 40.0 and vb > BRIDGE_Y1 - 40.0:
		for i in range(16):
			var px := lerpf(FAR_L + 80.0, FAR_R - 80.0, _h(i * 19 + 3))
			if px > 456.0 and px < 824.0:
				continue
			var y := lerpf(BRIDGE_Y1 + 50.0, BRIDGE_Y0 - 50.0, _h(i * 11 + 7)) + sin(t * 1.4 + float(i)) * 4.0
			var col := ONYAR_PIGMENTS[i % ONYAR_PIGMENTS.size()]
			wc.rect(Rect2(px - 10.0, y - 16.0, 20.0, 32.0), Color(col.r, col.g, col.b, 0.14))
			var ring_r := 4.0 + fposmod(t * 12.0 + _h(i * 5) * 18.0, 14.0)
			wc.draw_arc(Vector2(px, y), ring_r, 0.0, TAU, 14, Color(0.72, 0.82, 0.94, 0.20), 1.2)


static func _draw_steps_cascade(m: Node2D, wc: ShapeBatch, vt: float, vb: float, t: float) -> void:
	if vb < SPOUT_TOP - 40.0 or vt > SPOUT_BOT + 40.0:
		return
	var st: Dictionary = m.girona_spout if m.get("girona_spout") is Dictionary else {}
	var state := String(st.get("state", "idle"))
	if state == "warn":
		var rem := float(st.get("t", SPOUT_WARN))
		var fill := 1.0 - clampf(rem / SPOUT_WARN, 0.0, 1.0)
		wc.glow(Vector2(CX, SPOUT_TOP), 34.0 + fill * 24.0, Color(0.45, 0.78, 0.98, 0.28 + fill * 0.25))
		wc.draw_arc(Vector2(CX, SPOUT_TOP), 28.0, -PI * 0.5, -PI * 0.5 + TAU * fill, 20, Color(0.86, 0.96, 1.0, 0.85), 3.0)
		# Channel guide stripes showing where the rainwater cascade will pour
		var cy := SPOUT_TOP + 20.0
		while cy < SPOUT_BOT:
			wc.rect(Rect2(SPOUT_X0, cy, SPOUT_X1 - SPOUT_X0, 20.0), Color(0.40, 0.74, 0.96, 0.10 + fill * 0.12))
			cy += 44.0
	elif state == "rush":
		var bot := _rush_bot(m)
		wc.rect(Rect2(SPOUT_X0, SPOUT_TOP, SPOUT_X1 - SPOUT_X0, bot - SPOUT_TOP), Color(0.20, 0.56, 0.88, 0.68))
		wc.band(PackedVector2Array([
			Vector2(SPOUT_X0, SPOUT_TOP), Vector2(CX, SPOUT_TOP), Vector2(SPOUT_X1, SPOUT_TOP),
			Vector2(SPOUT_X0, bot), Vector2(CX, bot), Vector2(SPOUT_X1, bot),
		]), 3, Color(0.80, 0.94, 1.0, 0.52), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
		# Moving white foam streaks racing down the steps
		var fy := SPOUT_TOP + fposmod(t * 280.0, 48.0)
		while fy < bot - 12.0:
			wc.line(Vector2(SPOUT_X0 + 16.0, fy), Vector2(SPOUT_X1 - 16.0, fy + 6.0), Color(0.95, 0.99, 1.0, 0.78), 2.8)
			fy += 48.0


static func _draw_house_sniff_prompts(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	for i in range(HOUSE_SNIFFS.size()):
		if m.girona_houses_sniffed.has(i):
			continue
		var p := HOUSE_SNIFFS[i]
		if p.y < vt - 30.0 or p.y > vb + 30.0:
			continue
		var col := FLOWER_COLS[i % FLOWER_COLS.size()]
		wc.glow(p, 16.0, Color(col.r, col.g, col.b, 0.22))
		for k in range(4):
			wc.circle(p + Vector2.from_angle(TAU * float(k) / 4.0) * 5.0, 2.2, col)


# --- overhead: Eiffel red iron bridge arches + dusk lamp pools ---------------

static func draw_overhead(_m: Node2D, ci: CanvasItem) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	# Crimson Eiffel bridge overhead iron X-trusses spanning x = 478..802
	var xl := CX - BRIDGE_HALF - 18.0
	var xr := CX + BRIDGE_HALF + 18.0
	for ty: float in [-1040.0, -1180.0, -1320.0, -1460.0]:
		b.line(Vector2(xl, ty + 4.0), Vector2(xr, ty + 4.0), Color(0.04, 0.04, 0.08, 0.22), 10.0)
		b.line(Vector2(xl, ty), Vector2(xr, ty), EIFFEL_DK, 8.0)
		b.line(Vector2(xl, ty), Vector2(xr, ty), EIFFEL_RED, 4.5)
		b.line(Vector2(xl + 16.0, ty - 28.0), Vector2(xr - 16.0, ty + 28.0), Color(EIFFEL_RED.r, EIFFEL_RED.g, EIFFEL_RED.b, 0.55), 3.0)
		b.line(Vector2(xl + 16.0, ty + 28.0), Vector2(xr - 16.0, ty - 28.0), Color(EIFFEL_LIT.r, EIFFEL_LIT.g, EIFFEL_LIT.b, 0.55), 2.6)
	# Warm dusk pools under every streetlamp
	var glow := Game.lamp_glow()
	if glow > 0.02:
		for lp: Vector2 in STREET_LAMPS:
			b.glow(lp + Vector2(0.0, 4.0), 48.0 + glow * 22.0, Color(LAMP_WARM.r, LAMP_WARM.g, LAMP_WARM.b, 0.13 * glow))
	b.flush()


# --- props drawn for main -----------------------------------------------------

static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(ARCADE_COLS, p):
		wc.capsule(p + Shade.light * 5.0, p + Shade.light * 18.0, 12.0, SHADOW)
		wc.rect(Rect2(p - Vector2(13.0, 13.0), Vector2(26.0, 26.0)), LIMESTONE_DK)
		wc.circle(p, 11.0, LIMESTONE)
		wc.circle(p + Vector2(-2.0, -2.0), 5.0, LIMESTONE_LIT)
		return
	if _is_in(STEP_POSTS, p) or _is_in(PILONES, p):
		wc.circle(p + Shade.light * 3.0, 8.5, SHADOW)
		wc.circle(p, 8.0, IRON)
		wc.circle(p + Vector2(-2.0, -2.0), 3.0, Color(0.36, 0.38, 0.44))
		return
	if _is_in(STREET_LAMPS, p):
		wc.circle(p + Shade.light * 3.0, 7.0, SHADOW)
		wc.circle(p, 6.0, IRON)
		wc.circle(p, 3.0, LAMP_WARM)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# A crisp sugared xuixo pastry dropped on bakery paper
	wc.polygon(PackedVector2Array([kp + Vector2(-8, -5), kp + Vector2(7, -6), kp + Vector2(8, 5), kp + Vector2(-6, 6)]), Color(0.92, 0.90, 0.84))
	wc.capsule(kp + Vector2(-5.0, 1.0), kp + Vector2(5.0, -1.0), 3.2, Color(0.80, 0.54, 0.24))
	wc.circle(kp + Vector2(-1.0, -1.0), 1.8, Color(0.96, 0.92, 0.82))


# --- lighting after dark ------------------------------------------------------

static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	for p: Vector2 in HOUSE_SNIFFS:
		out.append(Vector3(p.x, p.y, 110.0))
	return out


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append_array(NightFronts.along_edges(m, START, RAMBLA_END + 60.0, 140.0, 4.0, 41))
	out.append_array(NightFronts.along_edges(m, STEPS_Y0, STEPS_Y1 + 60.0, 150.0, 4.0, 43))
	return out


# --- off the leash: Jardins dels Alemanys -------------------------------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	b.rect(Rect2(r.position.x - 300.0, r.position.y - 300.0, r.size.x + 600.0, r.size.y + 420.0), GRASS_MOSS)
	for i in range(12):
		var gp := Vector2(lerpf(r.position.x + 40.0, r.end.x - 40.0, _h(i * 11 + 3)), lerpf(r.position.y + 40.0, r.end.y - 40.0, _h(i * 7 + 5)))
		var gcol := GRASS_LIT if i % 2 == 0 else GRASS_DK
		b.glow(gp, 110.0 + _h(i * 3) * 80.0, Color(gcol.r, gcol.g, gcol.b, 0.42))
	# Flagged garden cross-walks & ruined stone arches of Jardins dels Alemanys
	b.rect(Rect2(CX - 38.0, r.position.y + 40.0, 76.0, r.size.y - 40.0), LIMESTONE_DK)
	b.rect(Rect2(r.position.x + 120.0, r.get_center().y - 26.0, r.size.x - 240.0, 52.0), LIMESTONE_DK)
	# Old walled garden battlements around the north & side edges
	b.rect(Rect2(r.position.x - 20.0, r.position.y - 16.0, r.size.x + 40.0, 26.0), LIMESTONE)
	for sx: float in [r.position.x + 90.0, r.end.x - 130.0]:
		var ruin := Rect2(sx, r.position.y + 70.0, 44.0, 18.0)
		b.rect(Rect2(ruin.position + Shade.light * 6.0, ruin.size), SHADOW)
		b.rect(ruin, LIMESTONE)
		b.rect(Rect2(ruin.position.x + 4.0, ruin.position.y + 3.0, ruin.size.x - 8.0, 5.0), LIMESTONE_LIT)
	# Rain puddles catching dusk sky light
	for pi in range(5):
		var pp := Vector2(lerpf(r.position.x + 150.0, r.end.x - 150.0, _h(pi * 13 + 4)), lerpf(r.position.y + 120.0, r.end.y - 120.0, _h(pi * 17 + 8)))
		b.glow(pp, 26.0, Color(0.32, 0.46, 0.66, 0.34))
	var glow := Game.lamp_glow()
	if glow > 0.05:
		for lx: float in [r.position.x + 180.0, r.end.x - 180.0]:
			b.glow(Vector2(lx, r.position.y + 90.0), 90.0, Color(LAMP_WARM.r, LAMP_WARM.g, LAMP_WARM.b, 0.16 * glow))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, Color(0.42, 0.30, 0.20))
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_alemanys_gardens_off_leash"))
