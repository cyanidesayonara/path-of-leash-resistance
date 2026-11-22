class_name Tarragona
extends RefCounted

# WALK 47: TARRAGONA — Roman stones above the sea, at dusk.
#
# South to north: Balcó del Mediterrani (rail above the sea and railway) ->
# amphitheatre rim (path along the oval, not into the arena) -> Rambla Nova
# (plane trees, benches, lamps, casteller monument) -> casteller practice
# plaça (soft crowd crawl) -> Roman walls and old-town arches -> cathedral
# square off the leash.
#
# No chase, no boss. Campaign sky clear dusk.

const HOOKS := ["draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer", "draw_freedom", "draw_grove", "draw_live", "draw_overhead", "draw_snack", "idle_status", "is_lamp", "night_fronts", "on_bark", "surface", "tick", "tree_kind"]
# draw_bollard receives the hydrant Dictionary (main._draw_world), not a Vector2

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const Panot := preload("res://world/panot.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EdgePath := preload("res://world/edge_path.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const Stones := preload("res://world/stones.gd")
const OVERHEAD_FOLLOWS_CAMERA := true
const CX := 640.0
const HALF := 280.0
const START := 260.0
const GATE := -5000.0
const SHADOW := Color(0.06, 0.05, 0.10, 0.28)

# --- colours: warm dusk stone, saffron sea, deep navy shade -----------------
const SEA_DEEP := Color(0.14, 0.40, 0.74)
const SEA_MID := Color(0.20, 0.56, 0.80)
const SEA_GOLD := Color(0.96, 0.80, 0.62, 0.16)
const PAVE := Color(0.78, 0.72, 0.62)
const PAVE_WARM := Color(0.86, 0.76, 0.58)
const PANOT_INK := Color(0.62, 0.56, 0.46, 0.42)
const PANOT_SHINE := Color(0.94, 0.88, 0.72, 0.32)
const STONE := Color(0.70, 0.64, 0.54)
const STONE_LIT := Color(0.88, 0.78, 0.58)
const STONE_DARK := Color(0.42, 0.38, 0.32)
const ROMAN := Color(0.62, 0.54, 0.44)
const ROMAN_LIT := Color(0.78, 0.68, 0.52)
const PLANE_TRUNK := Color(0.48, 0.36, 0.24)
const PLANE_CROWN := Color(0.22, 0.42, 0.22)
const PLANE_LIT := Color(0.36, 0.54, 0.28)
const RAIL := Color(0.28, 0.30, 0.34)
const LAMP_IRON := Color(0.18, 0.18, 0.22)
const FASCIA := Color(0.82, 0.74, 0.62)
const ARCH := Color(0.58, 0.50, 0.42)
const SASH := Color(0.78, 0.18, 0.22)
const SASH_B := Color(0.14, 0.32, 0.62)

# --- zones -------------------------------------------------------------------
const BALCO_Y0 := 200.0
const BALCO_Y1 := -900.0
const AMPHI_Y0 := -900.0
const AMPHI_Y1 := -1800.0
const AMPHI_CENTER := Vector2(780.0, -1350.0)
# the cavea's outer wall and the arena's podium: an oval whose long axis runs
# with the coast, as the real one's does
const AMPHI_RX := 220.0
const AMPHI_RY := 290.0
const ARENA_RX := 105.0
const ARENA_RY := 160.0
# the Balcó's railing (the solid's west face) and the coast below it
const RAIL_X := 768.0
const RAIL_TOP := -1060.0
const RAMBLA_Y0 := -1800.0
const RAMBLA_Y1 := -3000.0
const CASTELL_Y0 := -3000.0
const CASTELL_Y1 := -3400.0
const CASTELL_CENTER := Vector2(640.0, -3200.0)
const WALLS_Y0 := -3400.0
const WALLS_Y1 := -4600.0
const CATH_Y0 := -4600.0

const BALCO_SPOT := Vector2(700.0, -420.0)
const BALCO_R := 78.0
const VIEW_STILL := 22.0
const VIEW_REACH := 110.0
const VIEW_HOLD := 1.35

const CROWD_RECT := Rect2(520.0, -3340.0, 240.0, 280.0)
const EDGE_LANE_W := 70.0
const CRAWL_PACE := 0.18
const CASTELL_WARN := 1.05
const CASTELL_BUILD := 3.4
const CASTELL_HOLD := 2.2
const CASTELL_COOLDOWN := 14.0
const CASTELL_FIRST := 2.5

const DARE_POS := Vector2(640.0, -2120.0)
const PRIZE := Vector2(580.0, -4100.0)
const PRIZE_TEXT := "swipe the olive bowl off the cathedral steps"

const ROMAN_STONES: Array[Vector2] = [
	Vector2(520.0, -3560.0), Vector2(760.0, -3720.0), Vector2(500.0, -3920.0),
	Vector2(780.0, -4120.0), Vector2(540.0, -4320.0),
]

const PLANE_SPOTS: Array[Vector2] = [
	Vector2(480.0, -1900.0), Vector2(800.0, -1900.0),
	Vector2(480.0, -2140.0), Vector2(800.0, -2140.0),
	Vector2(480.0, -2380.0), Vector2(800.0, -2380.0),
	Vector2(480.0, -2620.0), Vector2(800.0, -2620.0),
	Vector2(480.0, -2860.0), Vector2(800.0, -2860.0),
]

const LAMP_SPOTS: Array[Vector2] = [
	Vector2(500.0, -200.0), Vector2(748.0, -200.0),
	Vector2(500.0, -620.0), Vector2(748.0, -620.0),
	Vector2(500.0, -1520.0), Vector2(760.0, -1680.0),
	Vector2(500.0, -2040.0), Vector2(780.0, -2040.0),
	Vector2(500.0, -2480.0), Vector2(780.0, -2480.0),
	Vector2(500.0, -2920.0), Vector2(780.0, -2920.0),
	Vector2(560.0, -3600.0), Vector2(720.0, -3900.0),
	Vector2(560.0, -4200.0), Vector2(720.0, -4480.0),
]

const MONUMENT := Vector2(640.0, -2700.0)


static func _h(i: float, s: float = 1.0) -> float:
	var v := sin(i * 12.9898 + s * 78.233) * 43758.5453
	return v - floor(v)


static func edge_nodes(_m: Node2D = null) -> Array:
	return [
		{"y": START, "cx": 640.0, "half": 270.0},
		{"y": -700.0, "cx": 620.0, "half": 260.0},
		{"y": -1100.0, "cx": 580.0, "half": 220.0},
		{"y": -1600.0, "cx": 560.0, "half": 210.0},
		{"y": -1900.0, "cx": 640.0, "half": 280.0},
		{"y": -3000.0, "cx": 640.0, "half": 280.0},
		{"y": -3200.0, "cx": 640.0, "half": 300.0},
		{"y": -3500.0, "cx": 640.0, "half": 200.0},
		{"y": -4200.0, "cx": 640.0, "half": 180.0},
		{"y": -4600.0, "cx": 640.0, "half": 220.0},
		{"y": GATE, "cx": 640.0, "half": 260.0},
	]


static func edges_at(y: float) -> Vector2:
	return EdgePath.edges(edge_nodes(), y, CX, HALF)


# the Balcó's railing, from the start to where the amphitheatre takes over
const RAIL_RECT := Rect2(RAIL_X, RAIL_TOP, 14.0, 1360.0)
# the Roman wall on the left of the old town, and the houses' wall on the right
const WALL_L := Rect2(360.0, -4580.0, 70.0, 1100.0)
const WALL_R := Rect2(850.0, -4580.0, 70.0, 1100.0)
# the emperor's podium at the top of the old town
const PODIUM := Rect2(560.0, -4980.0, 160.0, 220.0)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	# Extend the railing solid eastward across the cliff and railway so routes
	# never imagine a walkable lane behind it, while wrap_rects keeps RAIL_RECT.
	var out: Array[Rect2] = [Rect2(RAIL_X, RAIL_TOP, 180.0, 1360.0)]
	# The arena, inside its podium wall: bands that stay within the oval, so
	# the dog stops at the wall that is drawn rather than at a box round it
	# (top, height, half width) of each band, down from the oval's centre
	for band: Vector3 in [Vector3(-60.0, 120.0, 97.0), Vector3(-110.0, 50.0, 76.0), Vector3(60.0, 50.0, 76.0),
			Vector3(-145.0, 35.0, 44.0), Vector3(110.0, 35.0, 44.0)]:
		out.append(Rect2(AMPHI_CENTER.x - band.z, AMPHI_CENTER.y + band.x, band.z * 2.0, band.y))
	out.append(WALL_L)
	out.append(WALL_R)
	out.append(PODIUM)
	return out


# the rope wraps the railing and the walls, not the arena or the podium
static func wrap_rects(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = [RAIL_RECT, WALL_L, WALL_R]
	return out


static func build(m: Node2D) -> Array:
	# the sea past the shingle under the Balcó, and past the beach below the
	# amphitheatre (shore_x)
	m.water.assign([Rect2(884.0, -820.0, 900.0, 1220.0), Rect2(1102.0, -1800.0, 700.0, 980.0)])
	m.gate_text = "PLAÇA DE LA SEU"
	m.gate_l = 420.0
	m.gate_r = 860.0

	m.tarragona_castell = {
		"state": "idle", "t": CASTELL_FIRST, "tier": 0, "rewarded": false,
		"pulled": false, "planted": false, "in_crowd": false, "warned": false,
	}
	m.tarragona_balco = false
	m.tarragona_balco_t = 0.0
	m.tarragona_stones = {}
	m.tarragona_sitters = []

	for p: Vector2 in PLANE_SPOTS:
		m.poles.append(p)
		m.trees.append(p)
	for lp: Vector2 in LAMP_SPOTS:
		m.poles.append(lp)
	for sp: Vector2 in ROMAN_STONES:
		m.poles.append(sp)
	# Casteller monument base posts (wrap)
	m.poles.append(MONUMENT + Vector2(-18.0, 8.0))
	m.poles.append(MONUMENT + Vector2(18.0, 8.0))
	m.deco_pole_count = m.poles.size()

	for by: float in [-280.0, -560.0, -3680.0, -4040.0, -4400.0]:
		m.benches.append(Vector2(520.0, by))
		# on the Balcó the right-hand benches stand back from the railing
		m.benches.append(Vector2(728.0 if by > BALCO_Y1 else 760.0, by))
	# Rambla Nova benches sit along the tree/lamp kerb strip, clear of trees,
	# lamps, bins and the central pedestrian and pair lanes
	for by: float in [-1970.0, -2260.0, -2740.0]:
		m.benches.append(Vector2(490.0, by))
		m.benches.append(Vector2(790.0, by))

	for bp: Vector2 in [
		Vector2(490.0, -360.0), Vector2(742.0, -820.0), Vector2(490.0, -2100.0),
		Vector2(790.0, -2500.0), Vector2(530.0, -3620.0), Vector2(750.0, -4180.0),
	]:
		m.bins.append(bp)

	m.fountains.append(Vector2(640.0, -2560.0))
	m.fountains.append(Vector2(640.0, -4480.0))

	# Pilones / bollards along the Rambla kerbs, well clear of the central
	# monument and main walking lanes
	for py: float in [-1880.0, -2080.0, -2280.0, -2480.0]:
		m.park_props.append({"pos": Vector2(536.0, py), "kind": "bollard", "dig": false, "solid": true, "mark": true})
		m.park_props.append({"pos": Vector2(744.0, py), "kind": "bollard", "dig": false, "solid": true, "mark": true})

	m.park_props.append({"pos": Vector2(700.0, -480.0), "kind": "planter", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(580.0, -1600.0), "kind": "planter", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(640.0, -4780.0), "kind": "dig", "dig": true, "solid": false, "mark": false})
	m.park_props.append({"pos": Vector2(520.0, -4860.0), "kind": "dig", "dig": true, "solid": false, "mark": false})
	m.park_props.append({"pos": Vector2(760.0, -4860.0), "kind": "rock", "dig": false, "solid": true, "mark": true})

	var sit_share := Outdoors.promenade_sitters(Game.weather, Game.hour)
	for i in range(m.benches.size()):
		if _h(float(i) * 17.0 + 5.0) < sit_share:
			var bp: Vector2 = m.benches[i]
			m.tarragona_sitters.append({"pos": bp + Vector2(0.0, -4.0), "face": Vector2.RIGHT if bp.x < 640.0 else Vector2.LEFT, "key": 4700 + i * 13})

	var hyd_list: Array[Vector2] = [
		Vector2(700.0, -180.0), Vector2(540.0, -1100.0), Vector2(760.0, -2200.0),
		Vector2(540.0, -2800.0), Vector2(700.0, -3800.0), Vector2(580.0, -4500.0),
	]
	var keb_list: Array[Vector2] = [
		Vector2(620.0, -480.0), Vector2(660.0, -1700.0), Vector2(600.0, -2300.0),
		Vector2(680.0, -3100.0), Vector2(620.0, -4000.0),
	]
	return [hyd_list, keb_list]


static func surface(_m: Node2D, p: Vector2) -> int:
	if p.y > AMPHI_Y1 and p.x > shore_x(p.y):
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


# The railway along the coast: under the Balcó's cliff, then bending out round
# the amphitheatre to run along its beach
static func rail_x(y: float) -> float:
	return lerpf(818.0, 1036.0, smoothstep(-820.0, -1080.0, y))


# where the sea begins: past the railway and its strip of shingle or sand
static func shore_x(y: float) -> float:
	return rail_x(y) + 66.0


static func tree_kind(m: Node2D, p: Vector2) -> int:
	for q: Vector2 in PLANE_SPOTS:
		if p.distance_squared_to(q) < 4.0:
			return m.TREE_PLANE
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	for q: Vector2 in LAMP_SPOTS:
		if p.distance_squared_to(q) < 4.0:
			return true
	return false


static func view_taken(m: Node2D) -> bool:
	return bool(m.tarragona_balco)


static func stones_marked(m: Node2D) -> int:
	var n := 0
	for sp: Vector2 in ROMAN_STONES:
		if m.marks.has(sp) or m.tarragona_stones.has(sp):
			n += 1
			continue
		for mk in m.marks:
			if mk is Vector2 and (mk as Vector2).distance_to(sp) < 28.0:
				n += 1
				m.tarragona_stones[sp] = true
				break
	return n


static func castell_rewarded(m: Node2D) -> int:
	return 1 if bool(m.tarragona_castell.get("rewarded", false)) else 0


# --- live: Balcó view + casteller practice -----------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		m.human.walk_pace = 1.0
		return
	_tick_balco(m, delta)
	_tick_castell(m, delta)
	_tick_stones(m)


static func _tick_balco(m: Node2D, delta: float) -> void:
	if bool(m.tarragona_balco):
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	var near: bool = dp.distance_to(BALCO_SPOT) < BALCO_R and m.dog.velocity.length() < VIEW_STILL \
		and dp.distance_to(hp) < VIEW_REACH
	var held: float = float(m.tarragona_balco_t) + delta if near else 0.0
	m.tarragona_balco_t = held
	if held >= VIEW_HOLD:
		m.tarragona_balco = true
		m.bones += 5
		m.combo.add("THE VIEW", 4)
		m.float_text(hp + Vector2(0, -34), I18n.t("w_oh_wow"), Color(1, 1, 1, 0.9), m.POP_SAY)
		m.float_text(dp + Vector2(0, -30), I18n.t("w_the_view_5"), Color(0.96, 0.86, 0.32))
		m.feed.say(I18n.t("w_your_human_looked_up"), EventFeed.Tone.GOOD)
		_sfx(m, "prize", 1.05)


static func _tick_stones(m: Node2D) -> void:
	for sp: Vector2 in ROMAN_STONES:
		if m.tarragona_stones.has(sp):
			continue
		for mk in m.marks:
			if mk is Vector2 and (mk as Vector2).distance_to(sp) < 28.0:
				m.tarragona_stones[sp] = true
				break


static func _tick_castell(m: Node2D, delta: float) -> void:
	var st: Dictionary = m.tarragona_castell
	if st.is_empty():
		st = {"state": "idle", "t": CASTELL_FIRST, "tier": 0, "rewarded": false, "pulled": false, "planted": false, "in_crowd": false, "warned": false}
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))
	var hp: Vector2 = m.human.global_position
	var dp: Vector2 = m.dog.global_position
	var near: bool = minf(hp.y, dp.y) < CASTELL_Y0 + 80.0 and maxf(hp.y, dp.y) > CASTELL_Y1 - 80.0
	var in_crowd: bool = CROWD_RECT.has_point(hp)
	var on_edge: bool = near and not in_crowd and absf(hp.x - CASTELL_CENTER.x) > 90.0
	st["in_crowd"] = in_crowd

	match state:
		"idle":
			m.human.walk_pace = 1.0
			t -= delta
			if t <= 0.0 and near:
				st["state"] = "telegraph"
				t = CASTELL_WARN
				st["tier"] = 0
				st["pulled"] = false
				st["planted"] = false
				st["warned"] = false
				st["rewarded"] = bool(st.get("rewarded", false))
		"telegraph":
			m.human.walk_pace = 1.0
			if not bool(st.get("warned", false)):
				st["warned"] = true
				m.float_text(CASTELL_CENTER + Vector2(0, -40), I18n.t("w_gralla_hush"), Color(0.96, 0.92, 0.78), m.POP_SAY)
				m.feed.say(I18n.t("w_gralla_starts"), EventFeed.Tone.LOUD)
				_sfx(m, "whistle", 1.55)
			t -= delta
			if t <= 0.0:
				st["state"] = "build"
				t = CASTELL_BUILD
				st["tier"] = 1
		"build":
			t -= delta
			var prog := 1.0 - clampf(t / CASTELL_BUILD, 0.0, 1.0)
			st["tier"] = clampi(1 + int(prog * 3.0), 1, 4)
			_apply_crowd_pace(m, in_crowd)
			_note_castell_play(m, st, on_edge, dp, hp)
			if t <= 0.0:
				st["state"] = "crowned"
				t = CASTELL_HOLD
				st["tier"] = 4
				_sfx(m, "whoop", 1.1)
				m.feed.say(I18n.t("w_castell_up"), EventFeed.Tone.GOOD)
		"crowned":
			t -= delta
			_apply_crowd_pace(m, in_crowd)
			_note_castell_play(m, st, on_edge, dp, hp)
			if not bool(st.get("rewarded", false)) and (bool(st.get("pulled", false)) or bool(st.get("planted", false))):
				st["rewarded"] = true
				m.bones += 8
				m.combo.add("CASTELL", 5)
				m.award_points(8, I18n.t("w_castell_cheer_8"))
				m.float_text(CASTELL_CENTER + Vector2(0, -60), I18n.t("w_ole"), Color(0.98, 0.86, 0.30))
				_sfx(m, "prize", 1.0)
			if t <= 0.0:
				st["state"] = "idle"
				t = CASTELL_COOLDOWN
				st["tier"] = 0
				m.human.walk_pace = 1.0
		_:
			m.human.walk_pace = 1.0
	st["t"] = t
	m.tarragona_castell = st


static func _apply_crowd_pace(m: Node2D, in_crowd: bool) -> void:
	m.human.walk_pace = CRAWL_PACE if in_crowd else 1.0


static func _note_castell_play(m: Node2D, st: Dictionary, on_edge: bool, dp: Vector2, hp: Vector2) -> void:
	if on_edge and (m.dog.dragged or dp.distance_to(hp) > 90.0):
		st["pulled"] = true
	if m.dog.planted and not CROWD_RECT.has_point(dp) and dp.distance_to(CASTELL_CENTER) < 220.0:
		st["planted"] = true


static func idle_status(m: Node2D) -> String:
	var st := String(m.tarragona_castell.get("state", "idle"))
	if st == "telegraph":
		return I18n.t("walk_tarragona_gralla")
	if st == "build" or st == "crowned":
		return I18n.t("walk_tarragona_castell")
	return ""


static func on_bark(_m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	return false


static func _sfx(m: Node2D, name: String, pitch: float) -> void:
	var sfx: Node = m.get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play(name, pitch, -4.0)


# --- drawing -----------------------------------------------------------------
#
# Three layers, each cached where it can be: the edge layer (behind the
# world) holds the coast, the gardens, the walls and the houses with their
# pavements and terraces; the ground layer (draw_cross_section) holds the
# paving the pair walks on, the amphitheatre's tiers and whatever stands on
# the paving without moving (the railing, the monuments); draw_live holds
# what moves. Neither cached layer reads the animation clock.

enum Z { BALCO, AMPHI, RAMBLA, PLACA, WALLS, SEU }

# the ground, in Tarragona's own stone: the creamy limestone of the Mèdol
# quarry for the promenades, grey setts in the Part Alta
const FLAG_BALCO := Color(0.80, 0.75, 0.66)
const SAULO := Color(0.76, 0.70, 0.58)
const FLAG_RAMBLA := Color(0.82, 0.78, 0.70)
const LANE := Color(0.52, 0.50, 0.48)
const SIDEWALK := Color(0.70, 0.67, 0.62)
const PLACA_STONE := Color(0.78, 0.72, 0.62)
const SETT := Color(0.58, 0.54, 0.49)
const SEU_STONE := Color(0.72, 0.66, 0.56)
const KERB := Color(0.46, 0.44, 0.42)
const JOINT := Color(0.18, 0.14, 0.10, 0.22)
const SHEEN := Color(1.0, 0.97, 0.90, 0.10)
const STAIN := Color(0.25, 0.20, 0.14, 0.07)
# [unit width, row height, units per stamped piece, joint width]
const FLAGS := [54.0, 34.0, 3, 1.4]
const SETTS := [22.0, 14.0, 4, 1.5]
const SLABS := [56.0, 56.0, 2, 1.5]
const PAVERS := [26.0, 26.0, 1, 1.2]

const GAP := Color(0.24, 0.21, 0.19)
const LAWN := Color(0.36, 0.46, 0.26)
const LAWN_LIT := Color(0.48, 0.58, 0.32)
const PALM_LEAF := Color(0.26, 0.42, 0.22)
const PALM_LIT := Color(0.44, 0.58, 0.30)
const CYPRESS := Color(0.14, 0.26, 0.16)
const CYPRESS_LIT := Color(0.26, 0.40, 0.24)
const SEA_SHALLOW := Color(0.28, 0.72, 0.82)
const FOAM := Color(0.94, 0.96, 0.96)
const SHINGLE := Color(0.66, 0.62, 0.56)
const BEACH := Color(0.86, 0.78, 0.62)
const BALLAST := Color(0.44, 0.41, 0.38)
const SLEEPER := Color(0.30, 0.26, 0.22)
const STEEL := Color(0.70, 0.72, 0.74)
const CLIFF := Color(0.56, 0.48, 0.38)
const IRON := Color(0.16, 0.17, 0.19)
const BRONZE := Color(0.34, 0.26, 0.17)
const BRONZE_LIT := Color(0.64, 0.50, 0.30)
const PATINA := Color(0.32, 0.46, 0.40)
# the colla's shirt: one colour for a whole colla, as on the day
const COLLA := Color(0.46, 0.22, 0.52)
const COLLA_LIT := Color(0.60, 0.34, 0.66)
const FAIXA := Color(0.10, 0.09, 0.10)
const MOCADOR := Color(0.72, 0.16, 0.18)
# the houses: flat roofs of the Rambla's blocks, Part Alta tiles (Gotic's)
const TERRAT: Array[Color] = [Color(0.74, 0.70, 0.62), Color(0.66, 0.62, 0.58), Color(0.78, 0.66, 0.52),
	Color(0.62, 0.58, 0.54), Color(0.70, 0.60, 0.50)]
const FACADE: Array[Color] = [Color(0.86, 0.80, 0.68), Color(0.80, 0.70, 0.56), Color(0.90, 0.86, 0.78),
	Color(0.74, 0.58, 0.46), Color(0.84, 0.76, 0.60)]
const SHUTTER: Array[Color] = [Color(0.24, 0.40, 0.30), Color(0.44, 0.32, 0.22), Color(0.30, 0.40, 0.50),
	Color(0.52, 0.48, 0.40)]
const AWNING: Array[Color] = [Color(0.70, 0.20, 0.20), Color(0.18, 0.40, 0.36), Color(0.86, 0.64, 0.22),
	Color(0.22, 0.30, 0.52), Color(0.58, 0.30, 0.48)]
const PARASOL: Array[Color] = [Color(0.92, 0.90, 0.84), Color(0.78, 0.26, 0.22), Color(0.20, 0.42, 0.40)]

static var _plots: Array = []
static var _meshes := {}


static func _zone(y: float) -> int:
	if y > BALCO_Y1:
		return Z.BALCO
	if y > AMPHI_Y1:
		return Z.AMPHI
	if y > RAMBLA_Y1:
		return Z.RAMBLA
	if y > CASTELL_Y1:
		return Z.PLACA
	if y > WALLS_Y1:
		return Z.WALLS
	return Z.SEU


# a zone's (bottom, top) along the walk
static func _zone_span(z: int) -> Vector2:
	match z:
		Z.BALCO: return Vector2(START + 640.0, BALCO_Y1)
		Z.AMPHI: return Vector2(BALCO_Y1, AMPHI_Y1)
		Z.RAMBLA: return Vector2(AMPHI_Y1, RAMBLA_Y1)
		Z.PLACA: return Vector2(RAMBLA_Y1, CASTELL_Y1)
		Z.WALLS: return Vector2(CASTELL_Y1, WALLS_Y1)
	return Vector2(WALLS_Y1, GATE - 40.0)


# How far each side's houses stand back from the paving's edge: the strip
# between holds their pavement, terraces and arcades, out of the pair's way
static func _strip(z: int, side: int, y: float) -> float:
	if side == 0:
		match z:
			Z.BALCO: return 40.0
			Z.RAMBLA: return 46.0
			Z.PLACA: return 30.0
		return 12.0
	match z:
		Z.RAMBLA: return 46.0
		Z.PLACA: return 54.0
		Z.WALLS: return 32.0 if y < FORUM_Y else 14.0
	return 12.0


# where the arcades of the Plaça del Fòrum begin, up the right of the old town
const FORUM_Y := -4240.0


# The house plots down each side, fixed for the walk: [top, bottom, hash,
# zone]. Lengths come from a hash of the plot's index, never the RNG.
static func _all_plots(side: int) -> Array:
	if _plots.is_empty():
		var zones := [[Z.BALCO, Z.RAMBLA, Z.PLACA, Z.SEU], [Z.RAMBLA, Z.PLACA, Z.WALLS, Z.SEU]]
		for s in range(2):
			var out: Array = []
			var k := 0
			for z: int in zones[s]:
				var span := _zone_span(z)
				if z == Z.PLACA and s == 0:
					# the Ajuntament fills the plaça's left side
					out.append([span.y, span.x, Gotic.roof_hash(901, 3), z])
					continue
				var y := span.x
				while y > span.y + 1.0:
					var h := Gotic.roof_hash(k, 31 + s * 7)
					var old: bool = z == Z.SEU or z == Z.WALLS or z == Z.PLACA
					var length := (64.0 + float(h % 5) * 17.0) if old else (98.0 + float(h % 5) * 21.0)
					var top := y - length
					if top - span.y < 54.0:
						top = span.y
					out.append([top, y, h, z])
					y = top
					k += 1
			_plots.append(out)
	return _plots[side]


# the house front's line for a plot: back from the paving's edge by the strip
static func _face(side: int, top: float, bot: float, strip: float) -> float:
	var a := edges_at(top)
	var b := edges_at(bot)
	var c := edges_at((top + bot) * 0.5)
	if side == 0:
		return minf(a.x, minf(b.x, c.x)) - strip
	return maxf(a.y, maxf(b.y, c.y)) + strip


static func _quad(tris: PackedVector2Array, r: Rect2) -> void:
	tris.append_array(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
		r.position, r.end, Vector2(r.position.x, r.end.y)]))


# One stamped piece of a stretcher-bond pavement: its joints, and a few
# faces a shade lighter or darker, as cut stone is. Built once per variant.
static func _piece(spec: Array, v: int) -> Array:
	var key := "%s/%d" % [str(spec), v]
	if _meshes.has(key):
		return _meshes[key]
	var w: float = spec[0]
	var hh: float = spec[1]
	var n: int = spec[2]
	var jw: float = spec[3]
	var joints := PackedVector2Array()
	var lit := PackedVector2Array()
	var dark := PackedVector2Array()
	for i in range(n):
		var x := float(i) * w
		_quad(joints, Rect2(x, 0.0, jw, hh))
		var t := _h(float(i * 7 + v * 13) + w, 3.0)
		var face := Rect2(x + jw + 1.0, 1.0, w - jw - 2.0, hh - 2.0)
		if t < 0.30:
			_quad(lit, face)
		elif t > 0.78:
			_quad(dark, face)
	var out := [joints, lit, dark]
	_meshes[key] = out
	return out


# Lays a pavement of `spec` over the rows from lo to hi, between x_lo and
# x_hi and (with `follow`) inside the paving's edges, so no joint runs past a
# slanting edge. Whole pieces are stamped; the part pieces at the ends get
# their joints as lines.
static func _lay(wc: ShapeBatch, lo: float, hi: float, x_lo: float, x_hi: float, spec: Array, follow := true, ink := JOINT) -> void:
	var w: float = spec[0]
	var hh: float = spec[1]
	var n: int = spec[2]
	var jw: float = spec[3]
	var pw := w * float(n)
	var y := floorf(lo / hh) * hh
	while y < hi:
		var y0 := maxf(y, lo)
		var y1 := minf(y + hh, hi)
		var xa := x_lo
		var xb := x_hi
		if follow:
			var e0 := edges_at(y0)
			var e1 := edges_at(y1)
			xa = maxf(xa, maxf(e0.x, e1.x))
			xb = minf(xb, minf(e0.y, e1.y))
		if y1 - y0 > 2.0 and xb - xa > w:
			var row := int(floorf(y / hh))
			if y >= lo:
				wc.line(Vector2(xa, y), Vector2(xb, y), ink, jw)
			var off := (w * 0.5) if posmod(row, 2) == 1 else 0.0
			var col := int(ceilf((xa - off) / pw))
			var x := float(col) * pw + off
			var jx := x - w
			while jx > xa + 2.0:
				wc.line(Vector2(jx, y0), Vector2(jx, y1), ink, jw)
				jx -= w
			var xf := Transform2D(Vector2(1.0, 0.0), Vector2(0.0, (y1 - y0) / hh), Vector2(x, y0))
			while x + pw <= xb:
				var ms: Array = _piece(spec, posmod(col * 5 + row * 3, 4))
				xf.origin = Vector2(x, y0)
				wc.stamp(ms[0], xf, ink)
				wc.stamp(ms[1], xf, SHEEN)
				wc.stamp(ms[2], xf, STAIN)
				x += pw
				col += 1
			while x < xb - 2.0:
				wc.line(Vector2(x, y0), Vector2(x, y1), ink, jw)
				x += w
		y += hh


static func _path_poly(lo: float, hi: float, clip_r := INF) -> PackedVector2Array:
	# clip_r: the railing's line, which the paving stops at
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := hi
	while true:
		var e := edges_at(y)
		left.append(Vector2(e.x, y))
		right.append(Vector2(minf(e.y, clip_r), y))
		if y <= lo:
			break
		y = maxf(lo, y - 40.0)
	right.reverse()
	left.append_array(right)
	return left


static func _fill(wc: ShapeBatch, lo: float, hi: float, z: int, col: Color) -> Vector2:
	var span := _zone_span(z)
	var a := maxf(lo, span.y)
	var b := minf(hi, span.x)
	if b > a:
		# the paving stops at the railing wherever the railing runs
		if a < RAIL_TOP and b > RAIL_TOP:
			wc.polygon(_path_poly(a, RAIL_TOP), col)
			wc.polygon(_path_poly(RAIL_TOP, b, RAIL_X), col)
		else:
			wc.polygon(_path_poly(a, b, RAIL_X if a >= RAIL_TOP else INF), col)
	return Vector2(a, b)


static func draw_cross_section(_m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, maxf(ctop, GATE - 40.0))
	var hi := minf(vb + 40.0, START + 560.0)
	if hi <= lo:
		wc.lod = keep
		return
	# the Balcó: big limestone flags up to the railing, a granite kerb along it
	var r := _fill(wc, lo, hi, Z.BALCO, FLAG_BALCO)
	if r.y > r.x:
		_lay(wc, r.x, r.y, -INF, RAIL_X - 16.0, FLAGS)
		wc.rect(Rect2(RAIL_X - 16.0, r.x, 16.0, r.y - r.x), KERB.lightened(0.18))
		wc.line(Vector2(RAIL_X - 16.0, r.x), Vector2(RAIL_X - 16.0, r.y), JOINT, 1.5)
	# along the amphitheatre: a sauló path, its granite sand raked fine
	r = _fill(wc, lo, hi, Z.AMPHI, SAULO)
	if r.y > r.x:
		_saulo(wc, r.x, r.y)
	# the Rambla Nova: setts in the side lanes, flags down the promenade
	r = _fill(wc, lo, hi, Z.RAMBLA, SIDEWALK)
	if r.y > r.x:
		_rambla_ground(wc, r.x, r.y)
	# the plaça: big square slabs inside a border of darker stone
	r = _fill(wc, lo, hi, Z.PLACA, PLACA_STONE)
	if r.y > r.x:
		_lay(wc, r.x, r.y, -INF, INF, SLABS)
		_border(wc, r.x, r.y)
	# the Part Alta: grey setts, worn smooth down the middle
	r = _fill(wc, lo, hi, Z.WALLS, SETT)
	if r.y > r.x:
		_lay(wc, r.x, r.y, -INF, INF, SETTS, true, Color(0.14, 0.12, 0.10, 0.30))
		_wear(wc, r.x, r.y)
	r = _fill(wc, lo, hi, Z.SEU, SEU_STONE)
	if r.y > r.x:
		_lay(wc, r.x, r.y, -INF, INF, FLAGS)
		_wear(wc, r.x, r.y)
	# a granite band across the walk wherever one paving meets the next
	for by: float in [BALCO_Y1, AMPHI_Y1, RAMBLA_Y1, CASTELL_Y1, WALLS_Y1]:
		if by > lo - 10.0 and by < hi + 10.0:
			var e := edges_at(by)
			wc.rect(Rect2(e.x, by - 5.0, (minf(e.y, RAIL_X) if by >= RAIL_TOP else e.y) - e.x, 10.0), KERB)
			wc.line(Vector2(e.x, by + 5.0), Vector2(e.y, by + 5.0), Color(1, 1, 1, 0.10), 1.5)
	# the amphitheatre, its west tiers under the path
	if lo < AMPHI_CENTER.y + AMPHI_RY + 30.0 and hi > AMPHI_CENTER.y - AMPHI_RY - 30.0:
		_draw_amphi(wc)
	_house_shade(wc, lo, hi)
	# what stands on the paving and never moves
	if hi > RAIL_TOP and lo < START + 560.0:
		_draw_rail(wc, maxf(lo, RAIL_TOP), minf(hi, START + 300.0))
	if lo < AMPHI_CENTER.y + AMPHI_RY and hi > AMPHI_CENTER.y - AMPHI_RY:
		_visitor_rail(wc)
	if MONUMENT.y > lo - 200.0 and MONUMENT.y < hi + 200.0:
		_draw_monument(wc)
	if PODIUM.end.y > lo - 200.0 and PODIUM.position.y < hi + 200.0:
		_draw_podium(wc)
	wc.lod = keep


static func _saulo(wc: ShapeBatch, lo: float, hi: float) -> void:
	# the grain of the sand and the rake marks, and an edging of stone
	var y := floorf(lo / 22.0) * 22.0
	while y < hi:
		var e := edges_at(y)
		if y > RAIL_TOP:
			e.y = minf(e.y, RAIL_X)
		for k in range(6):
			var hx := _h(y * 0.31 + float(k) * 5.3, 9.0)
			var p := Vector2(lerpf(e.x + 8.0, e.y - 8.0, hx), y + _h(y + float(k), 4.0) * 22.0)
			wc.circle(p, 1.2 + _h(p.x, 2.0) * 1.6, Color(0.40, 0.34, 0.26, 0.22) if k % 2 == 0 else Color(1, 1, 1, 0.16))
		if posmod(int(y / 22.0), 3) == 0:
			wc.line(Vector2(e.x + 14.0, y), Vector2(e.y - 14.0, y), Color(0.40, 0.34, 0.26, 0.06), 2.0)
		y += 22.0
	var a := edges_at(lo)
	var b := edges_at(hi)
	wc.line(Vector2(a.x + 3.0, lo), Vector2(b.x + 3.0, hi), KERB.lightened(0.2), 6.0)


static func _rambla_ground(wc: ShapeBatch, lo: float, hi: float) -> void:
	# Rows down the Rambla: the side lanes in setts with their kerbs, the
	# central promenade in flags between the plane trees
	var y := floorf(lo / 34.0) * 34.0
	while y < hi:
		var y0 := maxf(y, lo)
		var y1 := minf(y + 34.0, hi)
		var e0 := edges_at(y0)
		var e1 := edges_at(y1)
		var l := maxf(e0.x, e1.x)
		var rr := minf(e0.y, e1.y)
		var ll := maxf(l + 24.0, minf(470.0, l + 110.0))
		var rl := minf(rr - 24.0, maxf(810.0, rr - 110.0))
		if ll < 470.0:
			wc.rect(Rect2(ll, y0, 470.0 - ll, y1 - y0), LANE)
			wc.rect(Rect2(ll, y0, 4.0, y1 - y0), KERB.lightened(0.12))
		if rl > 810.0:
			wc.rect(Rect2(810.0, y0, rl - 810.0, y1 - y0), LANE)
			wc.rect(Rect2(rl - 4.0, y0, 4.0, y1 - y0), KERB.lightened(0.12))
		wc.rect(Rect2(470.0, y0, 340.0, y1 - y0), FLAG_RAMBLA)
		y += 34.0
	_lay(wc, lo, hi, 470.0, 810.0, FLAGS, false)
	_lay(wc, lo, hi, 380.0, 470.0, SETTS, true, Color(0.10, 0.10, 0.10, 0.30))
	_lay(wc, lo, hi, 810.0, 900.0, SETTS, true, Color(0.10, 0.10, 0.10, 0.30))
	# the promenade's kerbs, lit on the west and shaded on the east
	wc.rect(Rect2(466.0, lo, 6.0, hi - lo), KERB.lightened(0.3))
	wc.rect(Rect2(808.0, lo, 6.0, hi - lo), KERB)


static func _border(wc: ShapeBatch, lo: float, hi: float) -> void:
	# a band of darker stone round the plaça's paving, following its edges
	var y := lo
	while y < hi:
		var y1 := minf(y + 40.0, hi)
		var e0 := edges_at(y)
		var e1 := edges_at(y1)
		var col := KERB.lightened(0.2)
		wc.quad(Vector2(e0.x, y), Vector2(e0.x + 18.0, y), Vector2(e1.x + 18.0, y1), Vector2(e1.x, y1), col)
		wc.quad(Vector2(e0.y - 18.0, y), Vector2(e0.y, y), Vector2(e1.y, y1), Vector2(e1.y - 18.0, y1), col)
		wc.line(Vector2(e0.x + 18.0, y), Vector2(e1.x + 18.0, y1), JOINT, 1.4)
		wc.line(Vector2(e0.y - 18.0, y), Vector2(e1.y - 18.0, y1), JOINT, 1.4)
		y = y1


# a paler run down the middle where centuries of feet have polished it,
# as a soft band with no edge
static func _wear(wc: ShapeBatch, lo: float, hi: float) -> void:
	var pts := PackedVector2Array()
	var y := lo
	var rows := 0
	while true:
		var e := edges_at(y)
		var c := (e.x + e.y) * 0.5
		var w := (e.y - e.x) * 0.36
		for f: float in [-1.0, -0.4, 0.4, 1.0]:
			pts.append(Vector2(c + w * f, y))
		rows += 1
		if y >= hi:
			break
		y = minf(hi, y + 120.0)
	var ra := PackedFloat32Array()
	ra.resize(rows)
	ra.fill(1.0)
	wc.band(pts, 4, Color(1.0, 0.96, 0.88, 0.10), ra, PackedFloat32Array([0.0, 1.0, 1.0, 0.0]))


# The houses' shade lying across the paving from the left, long at dusk and
# dawn, feathered to nothing (the light comes from the west)
static func _house_shade(wc: ShapeBatch, lo: float, hi: float) -> void:
	var reach := 26.0 + 50.0 * Shade.throw * (1.5 if Game.hour == "dusk" or Game.hour == "dawn" else 1.0)
	var pts := PackedVector2Array()
	var ra := PackedFloat32Array()
	var y := lo
	while true:
		var e := edges_at(y)
		var z := _zone(y)
		# the garden by the amphitheatre has palms, not walls: a lighter shade
		var a := 0.45 if z == Z.AMPHI else 1.0
		pts.append_array(PackedVector2Array([Vector2(e.x, y), Vector2(e.x + reach * 0.4, y), Vector2(e.x + reach, y)]))
		ra.append(a)
		if y >= hi:
			break
		y = minf(hi, y + 60.0)
	wc.band(pts, 3, Color(0.05, 0.04, 0.10, 0.30), ra, PackedFloat32Array([1.0, 0.5, 0.0]))


static func _ell(rx: float, ry: float, a: float) -> Vector2:
	return AMPHI_CENTER + Vector2(cos(a) * rx, sin(a) * ry)


const TIERS := 8
const SEGS := 60


# The amphitheatre from above: the cavea's tiers stepping down to the arena,
# each tread's riser lit where it faces the light and dark where it faces
# away, the seaward tiers broken where the sea took them; the arena with its
# podium wall, the cross of the fossae and the ruined church in the middle.
static func _draw_amphi(wc: ShapeBatch) -> void:
	var c := AMPHI_CENTER
	var L := Shade.SUN
	# the ground the ruin stands on, and its shadow round the outer wall
	wc.glow(c + Vector2(12.0, 18.0), AMPHI_RY + 30.0, Color(0.05, 0.04, 0.10, 0.16), 0.75)
	var base := PackedVector2Array()
	for i in range(SEGS):
		base.append(_ell(AMPHI_RX + 10.0, AMPHI_RY + 10.0, TAU * float(i) / float(SEGS)))
	wc.polygon(base, Color(0.56, 0.50, 0.40))
	for t in range(TIERS):
		var f0 := float(t) / float(TIERS)
		var f1 := float(t + 1) / float(TIERS)
		var rx0 := lerpf(ARENA_RX + 12.0, AMPHI_RX, f0)
		var ry0 := lerpf(ARENA_RY + 12.0, AMPHI_RY, f0)
		var rx1 := lerpf(ARENA_RX + 12.0, AMPHI_RX, f1)
		var ry1 := lerpf(ARENA_RY + 12.0, AMPHI_RY, f1)
		var tread := STONE.lerp(STONE_LIT, 0.15 + 0.5 * f0)
		for i in range(SEGS):
			var a0 := TAU * float(i) / float(SEGS)
			var a1 := TAU * float(i + 1) / float(SEGS)
			var am := (a0 + a1) * 0.5
			# the seaward side: only the lowest tiers survive whole
			var p00 := _ell(rx0, ry0, a0)
			var p01 := _ell(rx0, ry0, a1)
			var p10 := _ell(rx1, ry1, a0)
			var p11 := _ell(rx1, ry1, a1)
			if cos(am) > 0.42 and t >= 3 and _h(float((i / 3) * 11 + t), 5.0) < 0.2 + 0.14 * float(t - 3):
				# fallen: the vaults' rubble and the scrub grown over it
				wc.quad(p00, p10, p11, p01, Color(0.52, 0.47, 0.38).darkened(0.08 * _h(float(i), 7.0)))
				if i % 2 == 0:
					Stones.stone(wc, (p00 + p11) * 0.5, 5.0, STONE.darkened(0.1), _h(float(i + t), 3.0))
				continue
			var tone := tread.darkened(0.06 * _h(float(i * 3 + t * 17), 2.0))
			wc.quad(p00, p10, p11, p01, tone)
			# the riser down to the tier below, a sliver at the tread's inner
			# edge: lit facing the light, dark facing away
			var n := Vector2(cos(am) / rx0, sin(am) / ry0).normalized()
			var lit := n.dot(L)
			var k := 4.0 / maxf(rx0, 1.0)
			var q00 := _ell(rx0 * (1.0 + k), ry0 * (1.0 + k), a0)
			var q01 := _ell(rx0 * (1.0 + k), ry0 * (1.0 + k), a1)
			wc.quad(p00, q00, q01, p01, STONE_LIT if lit > 0.15 else (STONE_DARK if lit < -0.15 else STONE))
			if lit < 0.0:
				# the step above shades the tread below it
				var s00 := _ell(rx0 * (1.0 - k * 1.6), ry0 * (1.0 - k * 1.6), a0)
				var s01 := _ell(rx0 * (1.0 - k * 1.6), ry0 * (1.0 - k * 1.6), a1)
				wc.quad(s00, p00, p01, s01, Color(0.05, 0.04, 0.10, 0.22 * -lit))
			# a seat joint now and then
			if (i + t) % 4 == 0:
				wc.line(p00, p10, Color(0.30, 0.26, 0.22, 0.45), 1.2)
	# the outer wall's top, and the vomitoria through it on the axes
	for i in range(SEGS):
		var a0 := TAU * float(i) / float(SEGS)
		var a1 := TAU * float(i + 1) / float(SEGS)
		if i % 15 == 0:
			continue
		if cos((a0 + a1) * 0.5) > 0.42 and _h(float(i), 6.0) < 0.5:
			continue
		wc.quad(_ell(AMPHI_RX, AMPHI_RY, a0), _ell(AMPHI_RX + 9.0, AMPHI_RY + 9.0, a0),
			_ell(AMPHI_RX + 9.0, AMPHI_RY + 9.0, a1), _ell(AMPHI_RX, AMPHI_RY, a1), ROMAN_LIT)
	# the arena floor, its podium wall and the shade the wall throws on it
	var floor_pts := PackedVector2Array()
	for i in range(SEGS):
		floor_pts.append(_ell(ARENA_RX, ARENA_RY, TAU * float(i) / float(SEGS)))
	wc.polygon(floor_pts, Color(0.82, 0.70, 0.52))
	for i in range(SEGS):
		var a0 := TAU * float(i) / float(SEGS)
		var a1 := TAU * float(i + 1) / float(SEGS)
		var am := (a0 + a1) * 0.5
		var n := Vector2(cos(am) / ARENA_RX, sin(am) / ARENA_RY).normalized()
		var lit := n.dot(L)
		if lit < 0.0:
			wc.quad(_ell(ARENA_RX, ARENA_RY, a0), _ell(ARENA_RX - 16.0, ARENA_RY - 16.0, a0),
				_ell(ARENA_RX - 16.0, ARENA_RY - 16.0, a1), _ell(ARENA_RX, ARENA_RY, a1), Color(0.05, 0.04, 0.10, 0.10 * -lit))
			wc.quad(_ell(ARENA_RX, ARENA_RY, a0), _ell(ARENA_RX - 7.0, ARENA_RY - 7.0, a0),
				_ell(ARENA_RX - 7.0, ARENA_RY - 7.0, a1), _ell(ARENA_RX, ARENA_RY, a1), Color(0.05, 0.04, 0.10, 0.16 * -lit))
		var wall := ROMAN_LIT if lit > 0.2 else (ROMAN.darkened(0.12) if lit < -0.2 else ROMAN)
		wc.quad(_ell(ARENA_RX, ARENA_RY, a0), _ell(ARENA_RX + 12.0, ARENA_RY + 12.0, a0),
			_ell(ARENA_RX + 12.0, ARENA_RY + 12.0, a1), _ell(ARENA_RX, ARENA_RY, a1), wall)
		if i % 3 == 0:
			wc.line(_ell(ARENA_RX, ARENA_RY, a0), _ell(ARENA_RX + 12.0, ARENA_RY + 12.0, a0), STONE_DARK, 1.2)
	# the fossae: the cross of trenches the beasts came up from
	var pit := Color(0.26, 0.20, 0.16)
	wc.rect(Rect2(c.x - 9.0, c.y - 120.0, 18.0, 240.0), pit)
	wc.rect(Rect2(c.x - 64.0, c.y + 30.0, 128.0, 16.0), pit)
	wc.rect(Rect2(c.x - 9.0, c.y - 120.0, 4.0, 240.0), Color(0.05, 0.04, 0.10, 0.35))
	wc.rect(Rect2(c.x + 9.0, c.y - 120.0, 2.0, 240.0), Color(1, 1, 1, 0.18))
	# the church of Santa Maria del Miracle, roofless in the arena: its walls,
	# its apse to the east, the stumps of its piers
	var ch := Rect2(c.x - 62.0, c.y - 92.0, 104.0, 56.0)
	var wall_c := Color(0.70, 0.62, 0.50)
	wc.rect(Rect2(ch.position + Vector2(3.0, 5.0), Vector2(ch.size.x, 6.0)), Color(0.05, 0.04, 0.10, 0.25))
	wc.rect(Rect2(ch.position.x + 3.0, ch.end.y + 3.0, ch.size.x, 6.0), Color(0.05, 0.04, 0.10, 0.25))
	wc.rect(Rect2(ch.position, Vector2(ch.size.x, 6.0)), wall_c)
	wc.rect(Rect2(ch.position.x, ch.end.y - 6.0, ch.size.x, 6.0), wall_c)
	wc.rect(Rect2(ch.position, Vector2(6.0, ch.size.y)), wall_c)
	wc.rect(Rect2(ch.position.x, ch.position.y, ch.size.x, 2.0), Color(1, 1, 1, 0.25))
	var ac := Vector2(ch.end.x, ch.get_center().y)
	for i in range(8):
		var a := -PI * 0.5 + PI * float(i) / 8.0
		var a1 := -PI * 0.5 + PI * float(i + 1) / 8.0
		wc.line(ac + Vector2(cos(a), sin(a)) * 25.0, ac + Vector2(cos(a1), sin(a1)) * 25.0, wall_c, 6.0)
	for px: float in [ch.position.x + 34.0, ch.position.x + 68.0]:
		for py: float in [ch.position.y + 18.0, ch.end.y - 18.0]:
			wc.rect(Rect2(px - 4.0 + 3.0, py - 4.0 + 4.0, 8.0, 8.0), Color(0.05, 0.04, 0.10, 0.25))
			wc.rect(Rect2(px - 4.0, py - 4.0, 8.0, 8.0), wall_c.lightened(0.08))
	# the low sun gilding the western tiers
	wc.glow(c + Vector2(-AMPHI_RX * 0.55, -AMPHI_RY * 0.2), 150.0, Color(1.0, 0.86, 0.60, 0.10))


# the Balcó's railing on its stone coping: iron balusters, a top rail worn
# bright where everyone touches it for luck, and its shade on the drop below
static func _draw_rail(wc: ShapeBatch, lo: float, hi: float) -> void:
	var x0 := RAIL_X
	wc.band(PackedVector2Array([Vector2(x0 + 14.0, lo), Vector2(x0 + 40.0, lo), Vector2(x0 + 80.0, lo),
		Vector2(x0 + 14.0, hi), Vector2(x0 + 40.0, hi), Vector2(x0 + 80.0, hi)]), 3,
		Color(0.05, 0.04, 0.10, 0.32), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.5, 0.0]))
	wc.rect(Rect2(x0, lo, 14.0, hi - lo), Color(0.84, 0.80, 0.72))
	wc.rect(Rect2(x0, lo, 3.0, hi - lo), Color(0.96, 0.93, 0.86))
	wc.rect(Rect2(x0 + 11.0, lo, 3.0, hi - lo), Color(0.56, 0.52, 0.46))
	var y := ceilf(lo / 14.0) * 14.0
	while y < hi:
		wc.rect(Rect2(x0 + 4.0, y - 1.5, 6.0, 3.0), IRON)
		if posmod(int(y / 14.0), 6) == 0:
			wc.circle(Vector2(x0 + 7.0, y), 4.0, IRON)
			wc.circle(Vector2(x0 + 6.0, y - 1.0), 1.6, IRON.lightened(0.5))
		y += 14.0
	wc.line(Vector2(x0 + 7.0, lo), Vector2(x0 + 7.0, hi), IRON, 2.5)
	wc.line(Vector2(x0 + 6.0, lo), Vector2(x0 + 6.0, hi), IRON.lightened(0.35), 1.0)
	# tocar ferro: the stretch of rail worn to a shine at the view
	if BALCO_SPOT.y > lo - 60.0 and BALCO_SPOT.y < hi + 60.0:
		wc.line(Vector2(x0 + 6.5, BALCO_SPOT.y - 50.0), Vector2(x0 + 6.5, BALCO_SPOT.y + 50.0), Color(0.86, 0.80, 0.62), 2.0)
		wc.glow(Vector2(x0 + 6.5, BALCO_SPOT.y), 40.0, Color(1.0, 0.90, 0.60, 0.20))


# the amphitheatre's visitor railing where the path stops on the cavea
static func _visitor_rail(wc: ShapeBatch) -> void:
	var y := AMPHI_CENTER.y + AMPHI_RY
	var prev := Vector2.INF
	while y > AMPHI_CENTER.y - AMPHI_RY:
		var x := edges_at(y).y
		var d := Vector2((x - AMPHI_CENTER.x) / ARENA_RX, (y - AMPHI_CENTER.y) / ARENA_RY)
		var p := Vector2(x, y)
		if d.length() < 1.12:
			prev = Vector2.INF
		else:
			if prev != Vector2.INF:
				wc.line(prev + Vector2(3.0, 4.0), p + Vector2(3.0, 4.0), Color(0.05, 0.04, 0.10, 0.22), 2.5)
				wc.line(prev, p, IRON, 2.2)
			wc.circle(p, 2.6, IRON)
			prev = p
		y -= 26.0


static func _soft_shadow_band(b: ShapeBatch, origin: Vector2, tip: Vector2, half0: float, half1: float, col: Color, three_rows := false) -> void:
	var span := tip - origin
	if span.length_squared() < 1.0:
		return
	var side := span.normalized().orthogonal()
	var ts := [0.0, 0.5, 1.0] if three_rows else [0.0, 0.35, 0.72, 1.0]
	var ra := PackedFloat32Array([0.85, 0.45, 0.0] if three_rows else [0.90, 0.65, 0.30, 0.0])
	var pts := PackedVector2Array()
	for t: float in ts:
		var q := origin.lerp(tip, t)
		var hw := lerpf(half0, half1, t)
		pts.append_array(PackedVector2Array([q - side * hw, q - side * hw * 0.48, q + side * hw * 0.48, q + side * hw]))
	b.band(pts, 4, col, ra, PackedFloat32Array([0.0, 1.0, 1.0, 0.0]))


# El Monument als Castellers' idea, our own figures: a human tower in bronze
# on a stepped plinth, the pinya round its foot and each storey above drawn
# a little further up the screen, so the tower stands up out of the paving
static func _draw_monument(wc: ShapeBatch) -> void:
	var p := MONUMENT
	var L := Shade.light
	wc.glow(p + L * 8.0, 56.0, Color(0.05, 0.04, 0.10, 0.24), 0.55)
	_soft_shadow_band(wc, p, p + L * 170.0, 38.0, 14.0, Color(0.05, 0.04, 0.10, 0.26))
	for st: Array in [[46.0, Color(0.66, 0.62, 0.56)], [36.0, Color(0.74, 0.70, 0.64)]]:
		var hw: float = st[0]
		var col: Color = st[1]
		wc.glow(p + Vector2(4.0, 6.0), hw * 1.4, Color(0.05, 0.04, 0.10, 0.18), 0.55)
		wc.rect(Rect2(p.x - hw, p.y - hw, hw * 2.0, hw * 2.0), col)
		wc.rect(Rect2(p.x - hw, p.y - hw, hw * 2.0, 3.0), col.lightened(0.2))
		wc.rect(Rect2(p.x - hw, p.y - hw, 3.0, hw * 2.0), col.lightened(0.12))
		wc.rect(Rect2(p.x - hw, p.y + hw - 3.0, hw * 2.0, 3.0), col.darkened(0.2))
	# a bronze plaque on the plinth's south face
	wc.rect(Rect2(p.x - 14.0, p.y + 38.0, 28.0, 6.0), BRONZE)
	# storeys: [figures, ring radius, lift up the screen, scale]
	var storeys := [[12, 25.0, 0.0, 1.0], [8, 17.0, 10.0, 0.95], [5, 11.0, 20.0, 0.9], [4, 8.0, 30.0, 0.85],
		[3, 6.0, 40.0, 0.8], [2, 4.0, 49.0, 0.72], [1, 0.0, 57.0, 0.62], [1, 0.0, 64.0, 0.5]]
	for s in range(storeys.size()):
		var spec: Array = storeys[s]
		var n: int = spec[0]
		var rad: float = spec[1]
		var lift: float = spec[2]
		var sc: float = spec[3]
		for i in range(n):
			var a := TAU * float(i) / float(n) + 0.3 * float(s)
			var q := p + Vector2(cos(a) * rad, sin(a) * rad * 0.75 - lift)
			_bronze_figure(wc, q, sc, s == storeys.size() - 1)


static func _bronze_figure(wc: ShapeBatch, q: Vector2, sc: float, top: bool) -> void:
	wc.circle(q + Vector2(2.0, 3.0) * sc, 6.2 * sc, Color(0.05, 0.04, 0.10, 0.30))
	wc.circle(q, 6.0 * sc, BRONZE)
	wc.circle(q + Vector2(-1.6, -1.4) * sc, 3.6 * sc, BRONZE_LIT.lerp(PATINA, 0.3))
	wc.circle(q + Vector2(0.0, -5.5) * sc, 3.4 * sc, BRONZE.lightened(0.1))
	wc.circle(q + Vector2(-0.8, -6.3) * sc, 1.6 * sc, BRONZE_LIT)
	if top:
		# the enxaneta's hand up: the tower is loaded
		wc.line(q + Vector2(2.0, -4.0) * sc, q + Vector2(6.0, -14.0) * sc, BRONZE_LIT, 2.2 * sc)


# Augustus on his podium at the top of the old town: three steps up, a
# cypress at each corner of the terrace, the emperor in bronze in the middle
# with his arm out, and his long shadow down the steps
static func _draw_podium(wc: ShapeBatch) -> void:
	var r := PODIUM
	var L := Shade.light
	wc.glow(r.get_center() + Vector2(10.0, 14.0), 135.0, Color(0.05, 0.04, 0.10, 0.24), 0.65)
	wc.band(PackedVector2Array([
		Vector2(r.end.x - 2.0, r.position.y + 4.0), Vector2(r.end.x + 18.0, r.position.y + 10.0),
		Vector2(r.end.x - 2.0, r.end.y), Vector2(r.end.x + 18.0, r.end.y + 16.0),
	]), 2, Color(0.05, 0.04, 0.10, 0.22), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	wc.band(PackedVector2Array([
		Vector2(r.position.x + 4.0, r.end.y - 2.0), Vector2(r.end.x, r.end.y - 2.0),
		Vector2(r.position.x + 12.0, r.end.y + 20.0), Vector2(r.end.x + 16.0, r.end.y + 20.0),
	]), 2, Color(0.05, 0.04, 0.10, 0.22), PackedFloat32Array([1.0, 0.0]), PackedFloat32Array([1.0, 1.0]))
	for k in range(3):
		var s := r.grow(-float(k) * 11.0)
		var col := Color(0.70, 0.64, 0.54).lightened(0.05 * float(k))
		wc.rect(s, col)
		wc.rect(Rect2(s.position, Vector2(s.size.x, 3.0)), col.lightened(0.22))
		wc.rect(Rect2(s.position, Vector2(3.0, s.size.y)), col.lightened(0.14))
		wc.rect(Rect2(s.position.x, s.end.y - 4.0, s.size.x, 4.0), col.darkened(0.25))
		wc.rect(Rect2(s.end.x - 3.0, s.position.y, 3.0, s.size.y), col.darkened(0.18))
	var top := r.grow(-33.0)
	wc.rect(top, Color(0.62, 0.58, 0.50))
	_lay_rect(wc, top, 22.0)
	for cp: Vector2 in [top.position + Vector2(12.0, 12.0), Vector2(top.end.x - 12.0, top.position.y + 12.0),
			top.end - Vector2(12.0, 12.0), Vector2(top.position.x + 12.0, top.end.y - 12.0)]:
		_cypress(wc, cp, 10.0)
	var c := r.get_center() + Vector2(0.0, 10.0)
	_soft_shadow_band(wc, c, c + L * 120.0, 14.0, 7.0, Color(0.05, 0.04, 0.10, 0.24))
	wc.rect(Rect2(c.x - 15.0, c.y - 15.0, 30.0, 30.0), Color(0.86, 0.82, 0.74))
	wc.rect(Rect2(c.x - 15.0, c.y + 11.0, 30.0, 4.0), Color(0.60, 0.56, 0.50))
	wc.rect(Rect2(c.x - 8.0, c.y + 16.0, 16.0, 3.0), BRONZE)
	# the emperor: toga, the arm raised in address, his head
	var f := c + Vector2(0.0, -10.0)
	wc.circle(f + Vector2(3.0, 4.0), 10.0, Color(0.05, 0.04, 0.10, 0.30))
	wc.circle(f, 10.0, BRONZE)
	wc.circle(f + Vector2(-2.5, -2.0), 6.0, BRONZE_LIT.lerp(PATINA, 0.4))
	wc.line(f + Vector2(-6.0, 3.0), f + Vector2(5.0, -5.0), BRONZE.darkened(0.2), 2.0)
	wc.line(f + Vector2(6.0, -4.0), f + Vector2(16.0, -16.0), BRONZE, 3.2)
	wc.circle(f + Vector2(16.0, -16.0), 2.2, BRONZE_LIT)
	wc.circle(f + Vector2(0.0, -9.0), 5.2, BRONZE.lightened(0.08))
	wc.circle(f + Vector2(-1.2, -10.2), 2.6, BRONZE_LIT)
	# the inscription on the podium's face
	var pl := Rect2(r.get_center().x - 34.0, r.end.y - 9.0, 68.0, 7.0)
	wc.rect(pl, Color(0.88, 0.84, 0.76))
	for k in range(4):
		wc.rect(Rect2(pl.position.x + 5.0 + float(k) * 15.0, pl.position.y + 2.5, 11.0, 2.0), Color(0.30, 0.26, 0.22))


static func _lay_rect(wc: ShapeBatch, r: Rect2, t: float) -> void:
	var x := r.position.x + t
	while x < r.end.x - 1.0:
		wc.line(Vector2(x, r.position.y), Vector2(x, r.end.y), JOINT, 1.0)
		x += t
	var y := r.position.y + t
	while y < r.end.y - 1.0:
		wc.line(Vector2(r.position.x, y), Vector2(r.end.x, y), JOINT, 1.0)
		y += t


static func _cypress(wc: ShapeBatch, p: Vector2, r: float) -> void:
	# tall and narrow: from above a tight crown, and a long soft feathered shadow
	var L := Shade.light
	wc.glow(p + L * r * 0.6, r * 1.45, Color(0.04, 0.04, 0.08, 0.18), 0.45)
	_soft_shadow_band(wc, p, p + L * r * 5.2, r * 0.85, r * 0.35, Color(0.04, 0.04, 0.08, 0.28), true)
	wc.circle(p, r, CYPRESS)
	wc.circle(p + Vector2(-r * 0.25, -r * 0.3), r * 0.6, CYPRESS_LIT)
	wc.circle(p + Vector2(-r * 0.35, -r * 0.45), r * 0.25, CYPRESS_LIT.lightened(0.15))


static func _palm(b: ShapeBatch, p: Vector2, r: float, h: float) -> void:
	# a palm from above: its trunk's shadow long across the lawn, a star of
	# fronds, each lit along its sunward edge
	var L := Shade.light
	b.capsule(p, p + L * r * 4.0, 3.0, Color(0.05, 0.04, 0.10, 0.20))
	var sp := p + L * r * 4.0
	for k in range(9):
		var a := TAU * float(k) / 9.0 + h * 2.0
		b.line(sp, sp + Vector2.from_angle(a) * r * 0.9, Color(0.05, 0.04, 0.10, 0.16), 5.0)
	for k in range(9):
		var a := TAU * float(k) / 9.0 + h * 2.0
		var d := Vector2.from_angle(a)
		var mid := p + d * r * 0.55 + d.orthogonal() * 2.0
		var end := p + d * r + d.orthogonal() * 5.0
		b.line(p, mid, PALM_LEAF, 6.0)
		b.line(mid, end, PALM_LEAF, 4.0)
		if d.dot(Vector2(-0.5, -0.86)) > -0.2:
			b.line(p + d * 3.0, mid, PALM_LIT, 2.4)
	b.circle(p, 4.5, Color(0.40, 0.32, 0.20))


# --- the edge layer: coast, gardens, walls and houses -------------------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep := b.lod
	b.lod = true
	var lo := maxf(vt - 280.0, GATE - 40.0)
	var hi := minf(vb + 280.0, START + 640.0)
	if hi <= lo:
		b.lod = keep
		return
	b.rect(Rect2(-400.0, lo, 2200.0, hi - lo), GAP)
	if hi > AMPHI_Y1:
		_coast(b, maxf(lo, AMPHI_Y1), hi)
	if lo < BALCO_Y1 and hi > AMPHI_Y1:
		_garden(m, b, maxf(lo, AMPHI_Y1), minf(hi, BALCO_Y1))
	for side in range(2):
		for p: Array in _all_plots(side):
			if float(p[1]) < lo or float(p[0]) > hi:
				continue
			_draw_plot(m, b, side, p)
	if lo < WALLS_Y0 and hi > WALLS_Y1:
		_roman_wall(b, maxf(lo, WALLS_Y1), minf(hi, WALLS_Y0))
	b.lod = keep


# The coast under the Balcó and past the amphitheatre: the cliff, the
# railway in its cutting, the shingle and beach, and the sea deepening away
# from the shore in soft bands. Static: the surf is draw_live's.
static func _coast(b: ShapeBatch, lo: float, hi: float) -> void:
	var y := floorf(lo / 20.0) * 20.0
	# the sea: luminous deep blue everywhere, then wider shallows and warm sunset
	# sky reflections laid across the visible water from the shore out
	b.rect(Rect2(shore_x(hi) - 30.0, lo, 1400.0, hi - lo), SEA_DEEP)
	var pts := PackedVector2Array()
	var dusk_pts := PackedVector2Array()
	var coral_pts := PackedVector2Array()
	var rows := 0
	var yy := lo
	while true:
		var sx := shore_x(yy)
		pts.append_array(PackedVector2Array([Vector2(sx - 8.0, yy), Vector2(sx + 55.0, yy), Vector2(sx + 170.0, yy), Vector2(sx + 360.0, yy)]))
		dusk_pts.append_array(PackedVector2Array([Vector2(sx + 24.0, yy), Vector2(sx + 120.0, yy), Vector2(sx + 260.0, yy), Vector2(sx + 480.0, yy)]))
		coral_pts.append_array(PackedVector2Array([Vector2(sx + 70.0, yy), Vector2(sx + 210.0, yy), Vector2(sx + 420.0, yy)]))
		rows += 1
		if yy >= hi:
			break
		yy = minf(hi, yy + 40.0)
	var ra := PackedFloat32Array()
	ra.resize(rows)
	ra.fill(1.0)
	b.band(pts, 4, SEA_MID, ra, PackedFloat32Array([1.0, 1.0, 0.72, 0.0]))
	b.band(pts, 4, SEA_SHALLOW, ra, PackedFloat32Array([1.0, 0.85, 0.12, 0.0]))
	var sunset := 1.0 if (Game.hour == "dusk" or Game.hour == "dawn") else (0.18 if Game.hour == "night" else 0.42)
	b.band(dusk_pts, 4, Color(SEA_GOLD.r, SEA_GOLD.g, SEA_GOLD.b, SEA_GOLD.a * sunset), ra, PackedFloat32Array([0.0, 0.85, 0.60, 0.0]))
	b.band(coral_pts, 3, Color(0.96, 0.76, 0.60, 0.12 * sunset), ra, PackedFloat32Array([0.0, 0.85, 0.30]))
	# warm dusk glow continuing out toward the horizon
	var far := PackedVector2Array([Vector2(1220.0, lo), Vector2(1420.0, lo), Vector2(1750.0, lo),
		Vector2(1220.0, hi), Vector2(1420.0, hi), Vector2(1750.0, hi)])
	b.band(far, 3, Color(SEA_GOLD.r, SEA_GOLD.g, SEA_GOLD.b, 0.15 * sunset), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.85, 0.45]))
	while y < hi:
		var y1 := y + 20.0
		var r0 := rail_x(y)
		var r1 := rail_x(y1)
		var s0 := shore_x(y)
		var s1 := shore_x(y1)
		# from the rail (or the amphitheatre's wall) out to the railway: the
		# cliff's rock under the Balcó, a slope of pines and scrub below the
		# ruin
		var inner := RAIL_X + 14.0 if y > RAIL_TOP else AMPHI_CENTER.x
		b.quad(Vector2(inner, y), Vector2(r0 - 24.0, y), Vector2(r1 - 24.0, y1), Vector2(inner, y1),
			CLIFF if y > RAIL_TOP else Color(0.50, 0.46, 0.34))
		if y > RAIL_TOP and _h(y, 3.0) < 0.6:
			Stones.stone(b, Vector2(lerpf(inner, r0 - 26.0, _h(y, 5.0)), y + 10.0), 6.0 + _h(y, 7.0) * 5.0, CLIFF.darkened(0.15), _h(y, 9.0))
		# the shingle (Balcó) or sand (below the amphitheatre) to the sea
		var beach := SHINGLE.lerp(BEACH, smoothstep(-820.0, -1080.0, y))
		b.quad(Vector2(r0 + 22.0, y), Vector2(s0 + 6.0, y), Vector2(s1 + 6.0, y1), Vector2(r1 + 22.0, y1), beach)
		b.quad(Vector2(s0 - 10.0, y), Vector2(s0 + 6.0, y), Vector2(s1 + 6.0, y1), Vector2(s1 - 10.0, y1), beach.darkened(0.18))
		# the ballast and the two rails on their sleepers
		b.quad(Vector2(r0 - 24.0, y), Vector2(r0 + 22.0, y), Vector2(r1 + 22.0, y1), Vector2(r1 - 24.0, y1), BALLAST)
		var d := Vector2(r1 - r0, 20.0).normalized()
		var n := Vector2(d.y, -d.x)
		for k in range(2):
			var sy := y + 4.0 + float(k) * 10.0
			var sx := lerpf(r0, r1, (sy - y) / 20.0)
			b.line(Vector2(sx, sy) - n * 17.0, Vector2(sx, sy) + n * 17.0, SLEEPER, 4.0)
		for off: float in [-9.0, 9.0]:
			b.line(Vector2(r0 + off, y), Vector2(r1 + off, y1), STEEL.darkened(0.3), 2.6)
			b.line(Vector2(r0 + off - 0.6, y), Vector2(r1 + off - 0.6, y1), STEEL, 1.0)
		# a catenary mast now and then, with its shadow
		if posmod(int(y / 20.0), 7) == 0:
			b.line(Vector2(r0 + 28.0, y), Vector2(r0 + 28.0, y) + Shade.light * 30.0, Color(0.05, 0.04, 0.10, 0.25), 3.0)
			b.rect(Rect2(r0 + 25.0, y - 3.0, 6.0, 6.0), Color(0.26, 0.28, 0.30))
			b.line(Vector2(r0 + 28.0, y), Vector2(r0 - 2.0, y), Color(0.26, 0.28, 0.30), 1.5)
		y = y1
	# the pines on the slope below the ruin, between it and the railway
	var py := floorf(lo / 90.0) * 90.0
	while py < hi:
		if py < RAIL_TOP and py > AMPHI_Y1 + 40.0:
			var px := lerpf(AMPHI_CENTER.x + 30.0, rail_x(py) - 40.0, _h(py, 13.0))
			var d2 := Vector2((px - AMPHI_CENTER.x) / AMPHI_RX, (py - AMPHI_CENTER.y) / AMPHI_RY)
			if d2.length() > 1.15:
				_pine(b, Vector2(px, py), 22.0 + _h(py, 14.0) * 10.0)
		py += 90.0


static func _pine(b: ShapeBatch, p: Vector2, r: float) -> void:
	b.glow(p + Shade.light * r * 0.9, r * 1.35, Color(0.05, 0.04, 0.10, 0.22), 0.55)
	b.circle(p, r, Color(0.20, 0.34, 0.20))
	b.circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.62, Color(0.30, 0.46, 0.26))
	b.circle(p + Vector2(r * 0.35, r * 0.2), r * 0.4, Color(0.18, 0.30, 0.18))


# The garden terrace above the amphitheatre (the Passeig de les Palmeres'
# kind): a stone balustrade on the path's edge, palms on a lawn, beds of
# flowers, and the Part Alta's roofs climbing behind
static func _garden(m: Node2D, b: ShapeBatch, lo: float, hi: float) -> void:
	# the houses behind the garden
	var y := floorf(lo / 100.0) * 100.0
	while y < hi:
		var h := Gotic.roof_hash(int(y / 100.0), 77)
		Gotic.draw_block(m, b, Rect2(-120.0, y + 2.0, 330.0 - float(h % 3) * 20.0, 96.0), h)
		y += 100.0
	var pts := PackedVector2Array()
	var rows := 0
	var yy := lo
	while true:
		var e := edges_at(yy)
		pts.append_array(PackedVector2Array([Vector2(200.0, yy), Vector2(240.0, yy), Vector2(e.x - 20.0, yy), Vector2(e.x + 4.0, yy)]))
		rows += 1
		if yy >= hi:
			break
		yy = minf(hi, yy + 50.0)
	var ra := PackedFloat32Array()
	ra.resize(rows)
	ra.fill(1.0)
	b.band(pts, 4, LAWN, ra, PackedFloat32Array([0.0, 1.0, 1.0, 1.0]))
	b.band(pts, 4, LAWN_LIT, ra, PackedFloat32Array([0.0, 0.0, 0.5, 0.0]))
	# a gravel walk through the garden, and the beds along it
	y = floorf(lo / 40.0) * 40.0
	while y < hi:
		var e := edges_at(y)
		var gx := e.x - 70.0
		b.rect(Rect2(gx - 10.0, y, 20.0, 40.0), SAULO.darkened(0.05))
		if posmod(int(y / 40.0), 4) == 1:
			for k in range(5):
				var fp := Vector2(gx + 22.0 + _h(y + float(k), 3.0) * 16.0, y + float(k) * 8.0)
				b.circle(fp, 3.4, [Color(0.86, 0.30, 0.40), Color(0.96, 0.82, 0.30), Color(0.92, 0.92, 0.94)][k % 3])
		# the balustrade: balusters under a coping, on the path's edge
		b.rect(Rect2(e.x - 12.0, y, 10.0, 40.0), Color(0.86, 0.82, 0.74))
		b.rect(Rect2(e.x - 4.0, y, 3.0, 40.0), Color(0.05, 0.04, 0.10, 0.20))
		for k in range(4):
			b.circle(Vector2(e.x - 7.0, y + 5.0 + float(k) * 10.0), 2.4, Color(0.70, 0.66, 0.58))
		y += 40.0
	# palms down the terrace
	var py := floorf(lo / 130.0) * 130.0
	while py < hi:
		var e := edges_at(py)
		_palm(b, Vector2(e.x - 36.0 - _h(py, 3.0) * 12.0, py + 40.0), 30.0, _h(py, 7.0))
		if _h(py, 11.0) < 0.5:
			_palm(b, Vector2(e.x - 120.0, py + 100.0), 26.0, _h(py, 8.0))
		py += 130.0


static func _draw_plot(m: Node2D, b: ShapeBatch, side: int, p: Array) -> void:
	var top: float = p[0]
	var bot: float = p[1]
	var h: int = p[2]
	var z: int = p[3]
	var mid := (top + bot) * 0.5
	var strip := _strip(z, side, mid)
	var face := _face(side, top, bot, strip)
	var dir := 1.0 if side == 0 else -1.0
	var depth := 230.0 + float((h >> 5) % 4) * 24.0
	var r := Rect2(face - depth, top, depth, bot - top) if side == 0 else Rect2(face, top, depth, bot - top)
	# the pavement in front, out under the paving's edge
	var ea := edges_at(top)
	var eb := edges_at(bot)
	var sw := Rect2(face, top, maxf(ea.x, eb.x) + 6.0 - face, bot - top) if side == 0 		else Rect2(minf(ea.y, eb.y) - 6.0, top, face - minf(ea.y, eb.y) + 6.0, bot - top)
	b.rect(sw, SIDEWALK.darkened(0.04) if z == Z.WALLS or z == Z.SEU else SIDEWALK)
	var jy := ceilf(top / 26.0) * 26.0
	while jy < bot:
		b.line(Vector2(sw.position.x, jy), Vector2(sw.end.x, jy), JOINT, 1.0)
		jy += 26.0
	var arcade := z == Z.PLACA and side == 1 or z == Z.WALLS and side == 1 and mid < FORUM_Y
	var modern := z == Z.BALCO or z == Z.RAMBLA
	if z == Z.PLACA and side == 0:
		_ajuntament(b, r, face)
	elif modern:
		_modern(b, r, h, face, dir)
	else:
		var roof := r
		if arcade:
			roof = Rect2(r.position.x + (0.0 if side == 0 else 26.0), r.position.y, r.size.x - 26.0, r.size.y)
		Gotic.draw_block(m, b, roof.grow_individual(0.0, -1.0, 0.0, -1.0), h)
		if arcade:
			_arcade(b, face, top, bot, dir)
		_old_front(b, face + (26.0 * dir if arcade else 0.0), top, bot, h, dir)
	# a terrace on the pavement where there is room for one
	if strip >= 40.0 and (h >> 3) % 3 != 0:
		_terrace(b, face + dir * (strip - 18.0), top, bot, h, dir)


# A Rambla block from above: its flat terrat inside a parapet, tiled, with
# the stair hut, water tanks, a solar array or a line of washing; balconies
# along its front and a shop's awning at the foot
static func _modern(b: ShapeBatch, r: Rect2, h: int, face: float, dir: float) -> void:
	var L := Shade.light
	b.rect(Rect2(r.position + L * 20.0, r.size), Color(0.05, 0.04, 0.10, 0.20))
	var roof: Color = TERRAT[h % TERRAT.size()]
	var fac: Color = FACADE[(h >> 4) % FACADE.size()]
	b.rect(r, fac)
	var fl := r.grow(-6.0)
	b.rect(fl, roof)
	b.rect(Rect2(fl.position, Vector2(fl.size.x, 5.0)), Color(0.05, 0.04, 0.10, 0.16))
	b.rect(Rect2(fl.position, Vector2(5.0, fl.size.y)), Color(0.05, 0.04, 0.10, 0.16))
	b.rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), fac.darkened(0.22))
	var gx := fl.position.x + 18.0
	while gx < fl.end.x:
		b.line(Vector2(gx, fl.position.y), Vector2(gx, fl.end.y), roof.darkened(0.08), 1.0)
		gx += 18.0
	var gy := fl.position.y + 18.0
	while gy < fl.end.y:
		b.line(Vector2(fl.position.x, gy), Vector2(fl.end.x, gy), roof.darkened(0.08), 1.0)
		gy += 18.0
	# the stair and lift hut, back from the street
	var hx := (fl.position.x + 30.0 + float((h >> 7) % 4) * 18.0) if dir > 0.0 else (fl.end.x - 70.0 - float((h >> 7) % 4) * 18.0)
	var hut := Rect2(hx, fl.position.y + 10.0 + float((h >> 9) % 3) * 10.0, 40.0, minf(34.0, fl.size.y - 24.0))
	b.rect(Rect2(hut.position + L * 12.0, hut.size), Color(0.05, 0.04, 0.10, 0.26))
	b.rect(hut, fac.lightened(0.06))
	b.rect(Rect2(hut.position, Vector2(hut.size.x, 4.0)), fac.lightened(0.24))
	var g := Game.lamp_glow()
	if g > 0.05 and (h >> 6) % 2 == 0:
		b.rect(Rect2(hut.position.x + 6.0, hut.end.y - 6.0, 10.0, 4.0), Color(1.0, 0.82, 0.48, 0.6 * g))
	var extra := (h >> 11) % 4
	var spot := Vector2(hx + (60.0 if dir > 0.0 else -40.0), fl.position.y + fl.size.y * 0.55)
	spot.x = clampf(spot.x, fl.position.x + 16.0, fl.end.x - 40.0)
	match extra:
		0:
			# a solar array in rows, angled to the south
			for k in range(3):
				var pr := Rect2(spot.x - 10.0, spot.y - 22.0 + float(k) * 14.0, 46.0, 10.0)
				if pr.end.y < fl.end.y - 4.0:
					b.rect(Rect2(pr.position + Vector2(2.0, 4.0), pr.size), Color(0.05, 0.04, 0.10, 0.25))
					b.rect(pr, Color(0.18, 0.24, 0.36))
					b.line(pr.position + Vector2(0.0, 2.0), Vector2(pr.end.x, pr.position.y + 2.0), Color(0.50, 0.62, 0.78), 1.0)
		1:
			# water tanks on their stand
			for k in range(2):
				var tp := spot + Vector2(float(k) * 20.0, 0.0)
				b.circle(tp + L * 8.0, 8.0, Color(0.05, 0.04, 0.10, 0.25))
				b.circle(tp, 8.0, Color(0.80, 0.80, 0.78))
				b.circle(tp - Vector2(2.0, 2.0), 3.4, Color(0.94, 0.94, 0.92))
		2:
			# washing on a line, across the terrat
			b.line(Vector2(fl.position.x + 12.0, spot.y), Vector2(fl.end.x - 12.0, spot.y), Color(0.30, 0.28, 0.26), 1.0)
			var wx := fl.position.x + 18.0
			var k2 := 0
			while wx < fl.end.x - 18.0:
				b.rect(Rect2(wx, spot.y, 9.0, 11.0), [Color(0.80, 0.30, 0.35), Color(0.30, 0.50, 0.70), Color(0.92, 0.88, 0.66), Color(0.94, 0.94, 0.94)][(k2 + h) % 4])
				wx += 15.0
				k2 += 1
		_:
			# air conditioners and an aerial
			for k in range(3):
				var ap := spot + Vector2(float(k) * 16.0, float(k % 2) * 12.0)
				b.rect(Rect2(ap + Vector2(2.0, 3.0), Vector2(12.0, 9.0)), Color(0.05, 0.04, 0.10, 0.25))
				b.rect(Rect2(ap, Vector2(12.0, 9.0)), Color(0.82, 0.82, 0.80))
				b.circle(ap + Vector2(6.0, 4.5), 3.0, Color(0.52, 0.52, 0.54))
	b.line(spot + Vector2(-30.0, -20.0), spot + Vector2(-30.0, -20.0) + L * 28.0, Color(0.05, 0.04, 0.10, 0.22), 1.5)
	b.line(spot + Vector2(-38.0, -20.0), spot + Vector2(-22.0, -20.0), Color(0.30, 0.30, 0.32), 1.5)
	b.circle(spot + Vector2(-30.0, -20.0), 2.0, Color(0.30, 0.30, 0.32))
	# balconies down the front: a run of glazed galleries on some blocks,
	# single iron balconies on the rest
	var y := r.position.y + 8.0
	var long := (h >> 13) % 3 == 0
	while y < r.end.y - 20.0:
		var bl := (r.end.y - 8.0 - y) if long else 16.0
		var slab := Rect2(face, y, 8.0 * dir, bl).abs()
		b.rect(Rect2(slab.position + Vector2(3.0, 4.0), slab.size), Color(0.05, 0.04, 0.10, 0.22))
		b.rect(slab, fac.lightened(0.10))
		var ox := face + 8.0 * dir
		b.line(Vector2(ox, y), Vector2(ox, y + bl), IRON, 1.6)
		if g > 0.05 and _h(y + float(h % 97), 2.0) < 0.6:
			b.rect(Rect2(minf(face, face + 5.0 * dir), y + 3.0, 5.0, bl - 6.0), Color(1.0, 0.80, 0.46, 0.45 * g))
		if long:
			break
		y += 26.0


# a Part Alta house front: narrow iron balconies with shutters either side
# and pots of geraniums, a door with a step
static func _old_front(b: ShapeBatch, face: float, top: float, bot: float, h: int, dir: float) -> void:
	var sh: Color = SHUTTER[h % SHUTTER.size()]
	var g := Game.lamp_glow()
	var y := top + 10.0 + float(h % 3) * 4.0
	var k := 0
	while y < bot - 18.0:
		var slab := Rect2(face, y, 6.0 * dir, 14.0).abs()
		b.rect(Rect2(slab.position + Vector2(2.0, 3.0), slab.size), Color(0.05, 0.04, 0.10, 0.22))
		b.rect(slab, Color(0.74, 0.70, 0.62))
		b.line(Vector2(face + 6.0 * dir, y), Vector2(face + 6.0 * dir, y + 14.0), IRON, 1.4)
		b.rect(Rect2(minf(face, face + 3.0 * dir), y - 5.0, 3.0, 5.0), sh)
		b.rect(Rect2(minf(face, face + 3.0 * dir), y + 14.0, 3.0, 5.0), sh)
		if (h >> k) % 3 == 0:
			b.circle(Vector2(face + 4.0 * dir, y + 4.0), 2.6, Color(0.28, 0.46, 0.24))
			b.circle(Vector2(face + 4.0 * dir, y + 4.0), 1.3, Color(0.88, 0.22, 0.26))
		if g > 0.05 and (h >> (k + 2)) % 3 != 0:
			b.rect(Rect2(minf(face, face + 2.0 * dir), y + 2.0, 2.0, 10.0), Color(1.0, 0.80, 0.46, 0.55 * g))
		y += 30.0
		k += 1


# porxos: the arcade under the houses, its columns and the dark gallery
static func _arcade(b: ShapeBatch, face: float, top: float, bot: float, dir: float) -> void:
	var gal := Rect2(face, top, 26.0 * dir, bot - top).abs()
	b.rect(gal, Color(0.26, 0.22, 0.20))
	b.rect(Rect2(gal.position.x, gal.position.y, gal.size.x, gal.size.y), Color(0.05, 0.04, 0.10, 0.10))
	var y := top + 14.0
	while y < bot - 6.0:
		var cp := Vector2(face + 4.0 * dir, y)
		b.circle(cp + Vector2(2.0, 3.0), 4.6, Color(0.05, 0.04, 0.10, 0.30))
		b.circle(cp, 4.4, Color(0.78, 0.72, 0.62))
		b.circle(cp + Vector2(-1.0, -1.0), 2.2, Color(0.92, 0.88, 0.80))
		b.line(Vector2(face + 3.0 * dir, y + 5.0), Vector2(face + 3.0 * dir, y + 22.0), Color(0.70, 0.64, 0.54), 2.0)
		y += 28.0
	var g := Game.lamp_glow()
	if g > 0.05:
		b.band(PackedVector2Array([Vector2(face + 24.0 * dir, top), Vector2(face + 6.0 * dir, top),
			Vector2(face + 24.0 * dir, bot), Vector2(face + 6.0 * dir, bot)]), 2,
			Color(1.0, 0.78, 0.44, 0.40 * g), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))


# The Ajuntament on the plaça: a long hipped roof of tiles, its clock turret
# with the flag, the balustrade along the front and a portico at the door
static func _ajuntament(b: ShapeBatch, r: Rect2, face: float) -> void:
	var L := Shade.light
	r = r.grow_individual(0.0, -6.0, 0.0, -6.0)
	b.rect(Rect2(r.position + L * 22.0, r.size), Color(0.05, 0.04, 0.10, 0.22))
	b.rect(r, Color(0.86, 0.80, 0.68))
	var roof := r.grow(-10.0)
	var tile := Color(0.62, 0.36, 0.26)
	var ridge_x0 := roof.position.x + roof.size.x * 0.5
	var c0 := Vector2(ridge_x0, roof.position.y + roof.size.x * 0.5)
	var c1 := Vector2(ridge_x0, roof.end.y - roof.size.x * 0.5)
	b.polygon(PackedVector2Array([roof.position, Vector2(roof.end.x, roof.position.y), c0]), tile.lightened(0.10))
	b.polygon(PackedVector2Array([roof.position, c0, c1, Vector2(roof.position.x, roof.end.y)]), tile.lightened(0.04))
	b.polygon(PackedVector2Array([Vector2(roof.end.x, roof.position.y), roof.end, c1, c0]), tile.darkened(0.14))
	b.polygon(PackedVector2Array([Vector2(roof.position.x, roof.end.y), c1, roof.end]), tile.darkened(0.22))
	b.line(c0, c1, tile.lightened(0.3), 3.0)
	var cy := roof.position.y + 12.0
	while cy < roof.end.y - 6.0:
		b.line(Vector2(roof.position.x + 6.0, cy), Vector2(roof.end.x - 6.0, cy), tile.darkened(0.25), 1.0)
		cy += 11.0
	b.line(roof.position, c0, tile.lightened(0.3), 2.0)
	b.line(Vector2(roof.end.x, roof.position.y), c0, tile.lightened(0.3), 2.0)
	b.line(Vector2(roof.position.x, roof.end.y), c1, tile.lightened(0.3), 2.0)
	b.line(roof.end, c1, tile.lightened(0.3), 2.0)
	# the balustrade along the cornice over the plaça
	var y := r.position.y + 4.0
	while y < r.end.y - 4.0:
		b.circle(Vector2(face - 5.0, y), 2.2, Color(0.94, 0.90, 0.80))
		y += 8.0
	# the turret over the middle, its clock face to the plaça, the flag
	var t := Rect2(face - 66.0, r.get_center().y - 26.0, 52.0, 52.0)
	var tc := t.get_center()
	b.glow(tc + L * 18.0, 42.0, Color(0.05, 0.04, 0.10, 0.24), 0.45)
	_soft_shadow_band(b, tc, tc + L * 54.0, 38.0, 30.0, Color(0.05, 0.04, 0.10, 0.26), true)
	b.rect(t, Color(0.90, 0.86, 0.76))
	b.polygon(PackedVector2Array([t.position + Vector2(6, 6), Vector2(t.end.x - 6.0, t.position.y + 6.0), tc]), Color(0.42, 0.44, 0.46))
	b.polygon(PackedVector2Array([t.position + Vector2(6, 6), tc, Vector2(t.position.x + 6.0, t.end.y - 6.0)]), Color(0.48, 0.50, 0.52))
	b.polygon(PackedVector2Array([Vector2(t.end.x - 6.0, t.position.y + 6.0), t.end - Vector2(6, 6), tc]), Color(0.32, 0.34, 0.36))
	b.polygon(PackedVector2Array([Vector2(t.position.x + 6.0, t.end.y - 6.0), tc, t.end - Vector2(6, 6)]), Color(0.28, 0.30, 0.32))
	b.circle(Vector2(t.end.x + 2.0, tc.y), 8.0, Color(0.96, 0.94, 0.88))
	b.circle(Vector2(t.end.x + 2.0, tc.y), 6.0, Color(0.86, 0.84, 0.78))
	b.line(Vector2(t.end.x + 2.0, tc.y), Vector2(t.end.x + 2.0, tc.y - 4.5), Color(0.1, 0.1, 0.1), 1.2)
	b.line(Vector2(t.end.x + 2.0, tc.y), Vector2(t.end.x + 5.0, tc.y + 1.0), Color(0.1, 0.1, 0.1), 1.2)
	# the senyera on its pole over the door
	var fp := Vector2(face + 4.0, tc.y + 44.0)
	b.line(fp, fp + Vector2(14.0, -10.0), Color(0.30, 0.30, 0.30), 1.6)
	var fr := Rect2(fp + Vector2(14.0, -18.0), Vector2(16.0, 10.0))
	b.rect(fr, Color(0.96, 0.80, 0.18))
	for k in range(4):
		b.rect(Rect2(fr.position.x, fr.position.y + 1.2 + float(k) * 2.4, fr.size.x, 1.1), Color(0.80, 0.14, 0.16))
	# the portico: four columns and the steps down onto the pavement
	for k in range(3):
		b.rect(Rect2(face + float(k) * 6.0, tc.y - 40.0 + float(k) * 2.0, 6.0, 80.0 - float(k) * 4.0), Color(0.82, 0.78, 0.70).lightened(0.04 * float(k)))
	for k in range(4):
		var cp := Vector2(face + 4.0, tc.y - 30.0 + float(k) * 20.0)
		b.circle(cp + Vector2(2.0, 3.0), 4.4, Color(0.05, 0.04, 0.10, 0.3))
		b.circle(cp, 4.2, Color(0.94, 0.90, 0.82))


# A café's terrace on a pavement: tables with their chairs, people at some
# of them as the hour and weather say, and parasols over some
static func _terrace(b: ShapeBatch, x: float, top: float, bot: float, h: int, dir: float) -> void:
	var fill := Outdoors.terrace_diners(Game.weather, Game.hour)
	var open := Outdoors.terrace_parasols(Game.weather, Game.hour)
	var y := top + 22.0
	var k := 0
	while y < bot - 18.0:
		var tp := Vector2(x, y)
		var kk := h + k * 7
		for s: float in [-1.0, 1.0]:
			var chair := tp + Vector2(0.0, s * 11.0)
			b.rect(Rect2(chair.x - 4.0, chair.y - 4.0, 8.0, 8.0), Color(0.36, 0.34, 0.32))
			if _h(float(kk) + s, 3.0) < fill:
				NpcFigure.person(b, chair, Vector2(0.0, -s), kk * 3 + int(s + 1.0), -1.0, {"arms": NpcFigure.Arms.READY})
		b.circle(tp + Vector2(2.0, 3.0), 7.5, Color(0.05, 0.04, 0.10, 0.25))
		b.circle(tp, 7.0, Color(0.86, 0.86, 0.84))
		b.circle(tp + Vector2(-2.0, -1.0), 1.8, Color(0.90, 0.70, 0.30))
		if open and (kk >> 2) % 3 == 0:
			var col: Color = PARASOL[(h >> 3) % PARASOL.size()]
			b.circle(tp + Shade.light * 16.0, 17.0, Color(0.05, 0.04, 0.10, 0.18))
			b.circle(tp, 17.0, col)
			for q in range(4):
				var a := float(q) * PI * 0.5 + 0.4
				b.polygon(PackedVector2Array([tp, tp + Vector2.from_angle(a) * 17.0, tp + Vector2.from_angle(a + PI * 0.25) * 17.0]), col.lightened(0.16))
			b.circle(tp, 2.0, col.darkened(0.3))
		y += 40.0
		k += 1
	# the planters that mark the terrace off from the walk
	var py := top + 6.0
	while py < bot - 6.0:
		var pp := Vector2(x + 18.0 * dir, py + 12.0)
		b.rect(Rect2(pp.x - 4.0, pp.y - 10.0, 8.0, 20.0), Color(0.44, 0.40, 0.36))
		b.circle(pp + Vector2(0.0, -4.0), 4.0, Color(0.28, 0.44, 0.24))
		b.circle(pp + Vector2(0.0, 4.0), 4.2, Color(0.24, 0.40, 0.22))
		py += 40.0


# The Roman wall up the left of the old town: its top of huge rough
# megaliths, the face toward the street in shade, square towers standing out
# from it to the west, a gate through it, and the archaeological promenade's
# garden of cypresses beyond
static func _roman_wall(b: ShapeBatch, lo: float, hi: float) -> void:
	var x0 := WALL_L.position.x - 4.0
	var x1 := WALL_L.end.x + 2.0
	# the garden beyond
	b.band(PackedVector2Array([Vector2(-200.0, lo), Vector2(150.0, lo), Vector2(x0, lo),
		Vector2(-200.0, hi), Vector2(150.0, hi), Vector2(x0, hi)]), 3, LAWN, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 1.0, 1.0]))
	b.rect(Rect2(190.0, lo, 22.0, hi - lo), SAULO)
	var y := floorf(lo / 64.0) * 64.0
	while y < hi:
		_cypress(b, Vector2(250.0 + _h(y, 2.0) * 20.0, y + 20.0), 9.0 + _h(y, 4.0) * 3.0)
		if _h(y, 5.0) < 0.4:
			_cypress(b, Vector2(150.0, y + 40.0), 10.0)
		y += 64.0
	# the wall's top: megaliths packed in their rows, with dark gaps
	b.rect(Rect2(x0, lo, x1 - x0, hi - lo), Color(0.30, 0.26, 0.22))
	y = floorf(lo / 22.0) * 22.0
	while y < hi:
		var row := int(y / 22.0)
		for k in range(3):
			var cx := x0 + 14.0 + float(k) * 24.0 + (8.0 if row % 2 == 0 else 0.0) + (_h(y + float(k), 3.0) - 0.5) * 6.0
			if cx > x1 - 8.0:
				continue
			var hv := _h(y * 0.7 + float(k) * 3.0, 6.0)
			Stones.lit_stone(b, Vector2(cx, y + 11.0), 12.0 + hv * 4.0, ROMAN.lerp(STONE, hv * 0.5), Color(0.18, 0.15, 0.12), hv)
		y += 22.0
	# its face toward the street, coursed and in shade
	b.rect(Rect2(x1, lo, 40.0, hi - lo), Color(0.40, 0.36, 0.32))
	y = floorf(lo / 18.0) * 18.0
	while y < hi:
		var e := edges_at(y)
		b.line(Vector2(x1, y), Vector2(e.x, y), Color(0.24, 0.20, 0.18), 1.4)
		var jx := x1 + 6.0 + _h(y, 8.0) * 14.0
		b.line(Vector2(jx, y), Vector2(jx, y + 18.0), Color(0.24, 0.20, 0.18), 1.2)
		y += 18.0
	b.line(Vector2(x1, lo), Vector2(x1, hi), ROMAN_LIT, 2.0)
	# the towers, square and buttressed, their tops paved and their
	# parapets toothed, each throwing its shadow on the garden
	var ty := floorf(lo / 330.0) * 330.0
	while ty < hi + 100.0:
		if ty < WALLS_Y0 - 60.0 and ty > WALLS_Y1 + 60.0:
			var t := Rect2(x0 - 62.0, ty - 38.0, 70.0, 76.0)
			var tc := t.get_center()
			b.glow(tc + Shade.light * 20.0, 54.0, Color(0.05, 0.04, 0.10, 0.22), 0.5)
			_soft_shadow_band(b, tc, tc + Shade.light * 80.0, 50.0, 38.0, Color(0.05, 0.04, 0.10, 0.26))
			b.rect(t, ROMAN)
			var tt := t.grow(-7.0)
			b.rect(tt, Color(0.66, 0.60, 0.50))
			_lay_rect(b, tt, 14.0)
			b.rect(Rect2(tt.position, Vector2(tt.size.x, 4.0)), Color(0.05, 0.04, 0.10, 0.18))
			var mx := t.position.x + 2.0
			while mx < t.end.x - 4.0:
				b.rect(Rect2(mx, t.position.y + 1.0, 7.0, 5.0), ROMAN_LIT)
				b.rect(Rect2(mx, t.end.y - 6.0, 7.0, 5.0), ROMAN.darkened(0.1))
				mx += 14.0
			b.rect(Rect2(t.position.x, t.position.y, 3.0, t.size.y), ROMAN_LIT)
		ty += 330.0
	# the Portal del Roser: a gate through the wall, its arch and the garden
	# seen through it
	var gy := -3760.0
	if gy > lo - 60.0 and gy < hi + 60.0:
		b.rect(Rect2(x0, gy - 22.0, x1 - x0 + 2.0, 44.0), Color(0.16, 0.13, 0.11))
		b.rect(Rect2(x0, gy - 12.0, x1 - x0, 24.0), SAULO.darkened(0.25))
		for k in range(9):
			var a := -PI * 0.5 + PI * float(k) / 8.0
			b.circle(Vector2(x1 - 2.0, gy) + Vector2(cos(a) * 6.0, sin(a) * 24.0), 4.0, ROMAN_LIT)
		b.rect(Rect2(x0 - 4.0, gy - 28.0, 10.0, 56.0), ROMAN_LIT)


# --- what moves -----------------------------------------------------------------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep := b.lod
	b.lod = true
	var t_sec := float(AnimClock.msec()) * 0.001
	if vb > AMPHI_Y1 - 40.0:
		_surf(b, maxf(vt - 40.0, AMPHI_Y1), minf(vb + 40.0, START + 300.0), t_sec)
	if vb > BALCO_Y1 and vt < START + 300.0:
		_lookers(b, vt, vb)
		if BALCO_SPOT.y >= vt - 60.0 and BALCO_SPOT.y <= vb + 60.0 and not bool(m.tarragona_balco):
			b.glow(BALCO_SPOT, BALCO_R * 0.8, Color(1.0, 0.80, 0.44, 0.10 + 0.04 * sin(t_sec * 2.0)))
	_strollers(b, vt, vb, t_sec)
	# the live casteller practice
	var cst: Dictionary = m.tarragona_castell
	var cstate := String(cst.get("state", "idle"))
	if CASTELL_CENTER.y >= vt - 160.0 and CASTELL_CENTER.y <= vb + 160.0:
		if cstate == "telegraph" or cstate == "build" or cstate == "crowned":
			_draw_crowd(b, cst, t_sec)
			var tier := int(cst.get("tier", 0))
			if tier > 0:
				_draw_castell(b, CASTELL_CENTER, tier, t_sec, cstate == "crowned")
		_draw_band(b, CASTELL_CENTER + Vector2(-118.0, 70.0), cstate, t_sec)
	for s: Dictionary in m.tarragona_sitters:
		var sp: Vector2 = s.pos
		if sp.y < vt - 40.0 or sp.y > vb + 40.0:
			continue
		NpcFigure.person(b, sp, s.face, int(s.key), -1.0, {"arms": NpcFigure.Arms.READY})
	if not bool(m.prize_taken) and PRIZE.y >= vt - 40.0 and PRIZE.y <= vb + 40.0:
		# a doorstep, and on it the bowl of olives
		b.rect(Rect2(PRIZE.x - 18.0 + 3.0, PRIZE.y - 12.0 + 4.0, 36.0, 24.0), Color(0.05, 0.04, 0.10, 0.22))
		b.rect(Rect2(PRIZE.x - 18.0, PRIZE.y - 12.0, 36.0, 24.0), Color(0.76, 0.70, 0.60))
		b.rect(Rect2(PRIZE.x - 18.0, PRIZE.y - 12.0, 36.0, 3.0), Color(0.88, 0.84, 0.76))
		b.glow(PRIZE, 22.0, Color(1.0, 0.88, 0.50, 0.20 + 0.06 * sin(t_sec * 3.0)))
		b.circle(PRIZE + Vector2(1.5, 2.0), 8.0, Color(0.05, 0.04, 0.10, 0.25))
		b.circle(PRIZE, 8.0, Color(0.92, 0.88, 0.78))
		b.circle(PRIZE, 6.0, Color(0.30, 0.22, 0.14))
		for k in range(5):
			b.circle(PRIZE + Vector2.from_angle(float(k) * 1.3) * 3.0, 2.0, Color(0.36, 0.46, 0.20) if k % 2 == 0 else Color(0.22, 0.18, 0.12))
	b.lod = keep


# the surf along the shore and the evening light glinting off the swell
static func _surf(b: ShapeBatch, lo: float, hi: float, t: float) -> void:
	var y := floorf(lo / 24.0) * 24.0
	while y < hi:
		var y1 := y + 24.0
		var s0 := shore_x(y) + sin(t * 1.7 + y * 0.03) * 5.0
		var s1 := shore_x(y1) + sin(t * 1.7 + y1 * 0.03) * 5.0
		b.line(Vector2(s0, y), Vector2(s1, y1), Color(FOAM.r, FOAM.g, FOAM.b, 0.80), 4.2 + 2.0 * sin(t * 1.3 + y * 0.05))
		var w0 := s0 + 18.0 + 10.0 * sin(t * 0.9 + y * 0.02)
		var w1 := s1 + 18.0 + 10.0 * sin(t * 0.9 + y1 * 0.02)
		b.line(Vector2(w0, y), Vector2(w1, y1), Color(0.92, 0.98, 1.0, 0.34), 2.2)
		y = y1
	var glint_col := Color(0.84, 0.92, 1.0, 0.36) if Game.hour == "night" else Color(1.0, 0.88, 0.64, 0.56 if (Game.hour == "dusk" or Game.hour == "dawn") else 0.42)
	for k in range(20):
		var gy := lo + fposmod(_h(float(k), 3.0) * (hi - lo) + t * 6.0, hi - lo)
		var gx := shore_x(gy) + 24.0 + _h(float(k), 5.0) * 280.0
		var a := 0.45 + 0.55 * sin(t * 2.8 + float(k) * 1.7)
		var half_len := 5.0 + _h(float(k), 7.0) * 6.0
		b.line(Vector2(gx - half_len, gy), Vector2(gx + half_len, gy), Color(glint_col.r, glint_col.g, glint_col.b, glint_col.a * a), 2.0)


# people at the Balcó's railing looking out to sea; one touches the rail
static func _lookers(b: ShapeBatch, vt: float, vb: float) -> void:
	var n := Outdoors.crowd_here(7, 2)
	for i in range(n):
		var y := 180.0 - float(i) * 150.0 - _h(float(i), 4.0) * 60.0
		if y < BALCO_Y1 + 20.0 or y < vt - 40.0 or y > vb + 40.0:
			continue
		var p := Vector2(RAIL_X - 12.0, y)
		var arms := NpcFigure.Arms.READY if i % 3 == 0 else (NpcFigure.Arms.UP if i % 3 == 1 else NpcFigure.Arms.BEHIND)
		NpcFigure.person(b, p, Vector2(1.0, (_h(float(i), 6.0) - 0.5) * 0.6), 4300 + i * 7, -1.0, {"arms": arms})
		if i % 2 == 1:
			NpcFigure.person(b, p + Vector2(-4.0, 16.0), Vector2(1.0, -0.2), 4301 + i * 7, -1.0, {"arms": NpcFigure.Arms.SIDE})


# Strollers on the promenades, each pacing its own stretch and back: the
# evening paseo. Never in the pair's way for long; nothing touches them.
const STROLLS := [
	[420.0, -60.0, -760.0, 4200], [640.0, -260.0, -840.0, 4210],
	[400.0, -1000.0, -1640.0, 4220],
	[560.0, -1880.0, -2960.0, 4230], [720.0, -1900.0, -2980.0, 4240], [600.0, -2000.0, -2900.0, 4250],
	[700.0, -2100.0, -2700.0, 4260], [430.0, -1900.0, -2900.0, 4270], [850.0, -1950.0, -2950.0, 4280],
	[480.0, -3420.0, -4400.0, 4290], [780.0, -3500.0, -4500.0, 4300], [620.0, -4500.0, -4740.0, 4310],
]


static func _strollers(b: ShapeBatch, vt: float, vb: float, t: float) -> void:
	var n := Outdoors.crowd_here(STROLLS.size(), 3)
	for i in range(n):
		var s: Array = STROLLS[i]
		var y0: float = s[1]
		var y1: float = s[2]
		var key: int = s[3]
		var span := absf(y1 - y0)
		var speed := 30.0 + _h(float(key), 2.0) * 12.0
		var d := fposmod(t * speed + _h(float(key), 3.0) * span * 2.0, span * 2.0)
		var up := d < span
		var y := y0 - d if up else y1 + (d - span)
		if y < vt - 40.0 or y > vb + 40.0:
			continue
		var x: float = s[0] + sin(t * 0.3 + float(key)) * 10.0
		var p := Vector2(x, y)
		NpcFigure.person(b, p, Vector2(0.0, -1.0 if up else 1.0), key, t * 8.0 + float(key))
		if key % 20 == 0:
			# a couple, arm in arm
			NpcFigure.person(b, p + Vector2(14.0, 2.0), Vector2(0.0, -1.0 if up else 1.0), key + 1, t * 8.0 + float(key) + 0.6)


# the colla's band: grallers and a drummer by the plaça's corner, playing
# from the hush until the tower is down
static func _draw_band(b: ShapeBatch, p: Vector2, state: String, t: float) -> void:
	var playing := state == "telegraph" or state == "build" or state == "crowned"
	for k in range(3):
		var q := p + Vector2(float(k) * 18.0, float(k % 2) * 8.0)
		NpcFigure.person(b, q, Vector2(0.4, -1.0), 4400 + k, -1.0, {"arms": NpcFigure.Arms.READY, "top": COLLA})
		if k < 2:
			var tip := q + Vector2(5.0 + sin(t * 14.0 + float(k)) * (1.5 if playing else 0.0), -14.0)
			b.line(q + Vector2(1.0, -5.0), tip, Color(0.62, 0.48, 0.30), 2.4)
			b.circle(tip, 2.4, Color(0.70, 0.56, 0.34))
			if playing:
				b.glow(tip, 14.0 + sin(t * 10.0 + float(k)) * 4.0, Color(1.0, 0.92, 0.55, 0.30 if state == "telegraph" else 0.14))
		else:
			b.circle(q + Vector2(0.0, -9.0), 5.5, Color(0.80, 0.70, 0.52))
			b.circle(q + Vector2(0.0, -9.0), 4.0, Color(0.92, 0.88, 0.80))
			if playing:
				var beat := absf(sin(t * 6.0))
				b.circle(q + Vector2(0.0, -9.0), 7.0 + beat * 3.0, Color(1, 1, 1, 0.12 * beat))


static func _draw_crowd(b: ShapeBatch, cst: Dictionary, t_sec: float) -> void:
	# the crowd packs in round the tower in a ring you can see, and hushes
	var st := String(cst.get("state", "idle"))
	var pack := 0.35
	if st == "build":
		pack = 0.55 + 0.35 * (1.0 - clampf(float(cst.get("t", 0.0)) / CASTELL_BUILD, 0.0, 1.0))
	elif st == "crowned":
		pack = 0.95
	b.glow(CASTELL_CENTER + Vector2(4.0, 8.0), 110.0 + pack * 40.0, Color(0.05, 0.04, 0.10, 0.10 + pack * 0.10), 0.5)
	var n := int(16.0 + pack * 22.0)
	for i in range(n):
		var a := TAU * float(i) / float(n) + 0.2 * _h(float(i), 2.0)
		var r := 62.0 + _h(float(i), 8.0) * 40.0 * (1.2 - pack)
		var p := CASTELL_CENTER + Vector2(cos(a) * r * 0.9, sin(a) * r)
		if not CROWD_RECT.grow(36.0).has_point(p):
			continue
		var face := (CASTELL_CENTER - p).normalized()
		var cheer := st == "crowned" and (i + int(t_sec * 3.0)) % 3 == 0
		NpcFigure.person(b, p, face, 4500 + i * 5, -1.0, {"arms": NpcFigure.Arms.UP if cheer else NpcFigure.Arms.SIDE})


static func _casteller(b: ShapeBatch, q: Vector2, sc: float, face: Vector2) -> void:
	b.circle(q + Vector2(2.0, 3.0) * sc, 8.0 * sc, Color(0.05, 0.04, 0.10, 0.30))
	b.circle(q, 7.6 * sc, COLLA)
	b.circle(q + Vector2(-1.8, -1.6) * sc, 4.0 * sc, COLLA_LIT)
	b.line(q + face.orthogonal() * 6.5 * sc + face * 1.5, q - face.orthogonal() * 6.5 * sc + face * 1.5, FAIXA, 2.4 * sc)
	b.circle(q + face * 2.0 * sc, 4.2 * sc, Color(0.84, 0.66, 0.52))
	b.circle(q + face * 1.0 * sc, 4.0 * sc, MOCADOR)


static func _draw_castell(b: ShapeBatch, at: Vector2, tiers: int, t_sec: float, crowned: bool) -> void:
	# the pinya packed round the foot, arms in; then each storey up the
	# screen, swaying a touch while it is loaded
	var wob := sin(t_sec * 3.0) * 1.6
	b.glow(at + Vector2(6.0, 10.0), 52.0, Color(0.05, 0.04, 0.10, 0.30), 0.4)
	for ring: Array in [[16, 34.0], [10, 22.0]]:
		var nn: int = ring[0]
		var rad: float = ring[1]
		for i in range(nn):
			var a := TAU * float(i) / float(nn) + rad * 0.01
			var q := at + Vector2(cos(a) * rad, sin(a) * rad * 0.8 + 6.0)
			_casteller(b, q, 0.9, (at - q).normalized())
	var storeys := [[4, 11.0], [3, 9.0], [2, 6.0], [1, 0.0]]
	var lift := 10.0
	for s in range(mini(tiers, storeys.size())):
		var spec: Array = storeys[s]
		var nn: int = spec[0]
		var rad: float = spec[1]
		for i in range(nn):
			var a := TAU * float(i) / float(maxi(nn, 1)) + 0.5
			var q := at + Vector2(cos(a) * rad + wob * float(s) * 0.5, sin(a) * rad * 0.7 - lift)
			_casteller(b, q, 0.85 - 0.06 * float(s), Vector2.DOWN)
		lift += 13.0
	if tiers >= 4:
		# the enxaneta at the top, small, her hand up when it is crowned
		var tip := at + Vector2(wob * 2.0, -lift - 2.0)
		b.circle(tip + Vector2(2.0, 2.0), 5.0, Color(0.05, 0.04, 0.10, 0.3))
		b.circle(tip, 4.8, COLLA_LIT)
		b.circle(tip + Vector2(0.0, -4.0), 3.2, Color(0.86, 0.68, 0.54))
		b.circle(tip + Vector2(0.0, -4.6), 2.6, MOCADOR)
		if crowned:
			b.line(tip + Vector2(2.0, -3.0), tip + Vector2(6.0, -13.0 - absf(sin(t_sec * 6.0)) * 2.0), Color(0.86, 0.68, 0.54), 2.0)


static func draw_overhead(_m: Node2D, ci: CanvasItem) -> void:
	# warm pools under the Rambla's and the Balcó's lamps as they come on
	var glow := Game.lamp_glow()
	if glow <= 0.02:
		return
	var b := ShapeBatch.new(ci)
	for lp: Vector2 in LAMP_SPOTS:
		b.glow(lp + Vector2(0, 6), 46.0 + glow * 20.0, Color(1.0, 0.78, 0.42, 0.10 * glow))
	b.flush()


static func draw_grove(m: Node2D, c: Object, p: Vector2, i: int) -> void:
	if p.y >= m.GATE_Y:
		return
	# Cathedral square holm oaks planted in Mèdol limestone ashlar escocells
	# with iron grates, never protruding woodland forest roots on stone slabs.
	var b := ShapeBatch.new()
	b.lod = true
	b.glow(p + Shade.light * 7.0, 26.0, Color(0.05, 0.04, 0.10, 0.22), 0.45)
	b.rect(Rect2(p.x - 19.0, p.y - 19.0, 38.0, 38.0), STONE)
	b.rect(Rect2(p.x - 19.0, p.y - 19.0, 38.0, 3.0), STONE_LIT)
	b.rect(Rect2(p.x - 19.0, p.y - 19.0, 3.0, 38.0), STONE_LIT.lerp(STONE, 0.35))
	b.rect(Rect2(p.x - 19.0, p.y + 16.0, 38.0, 3.0), STONE_DARK)
	b.rect(Rect2(p.x + 16.0, p.y - 19.0, 3.0, 38.0), STONE_DARK)
	# ashlar kerb corner joints
	for s: float in [-1.0, 1.0]:
		b.line(Vector2(p.x + s * 10.0, p.y - 19.0), Vector2(p.x + s * 10.0, p.y - 14.5), JOINT, 1.1)
		b.line(Vector2(p.x + s * 10.0, p.y + 14.5), Vector2(p.x + s * 10.0, p.y + 19.0), JOINT, 1.1)
	b.rect(Rect2(p.x - 14.5, p.y - 14.5, 29.0, 29.0), Color(0.20, 0.17, 0.14))
	b.rect(Rect2(p.x - 13.0, p.y - 13.0, 26.0, 26.0), Color(0.32, 0.26, 0.19))
	# cast-iron grate bars and inner collar ring
	for gi in range(4):
		var a := float(gi) * PI * 0.25
		var d := Vector2.from_angle(a) * 12.5
		b.line(p - d, p + d, Color(0.16, 0.17, 0.19, 0.85), 1.6)
	b.draw_arc(p, 11.5, 0.0, TAU, 16, Color(0.16, 0.17, 0.19, 0.80), 1.6)
	b.circle(p, 8.2, Color(0.26, 0.20, 0.14))
	# scattered fallen leaves / limestone grit varied by tree index
	for k in range(2):
		var a := _h(float(i), 11.0 + float(k) * 7.0) * TAU
		var r := 7.0 + _h(float(i), 19.0 + float(k) * 5.0) * 5.0
		var col := PLANE_LIT.lerp(STONE_LIT, 0.35) if (i + k) % 2 == 0 else Color(0.56, 0.44, 0.24)
		b.circle(p + Vector2.from_angle(a) * r, 1.8, col)
	b.flush(c)
	m.broadleaf_grove(c, p)


# Pla de la Seu, off the leash: the cathedral's front at the top of its
# stair, the square laid in old flags, Roman stones and a café's tables
static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	b.rect(Rect2(r.position.x - 400.0, r.position.y - 400.0, r.size.x + 800.0, r.size.y + 600.0), Color(0.36, 0.32, 0.28))
	b.rect(r, SEU_STONE)
	var y := r.position.y
	var row := 0
	while y < r.end.y:
		var hh := 34.0
		b.line(Vector2(r.position.x, y), Vector2(r.end.x, y), JOINT, 1.4)
		var x := r.position.x + (27.0 if row % 2 == 1 else 0.0)
		while x < r.end.x:
			b.line(Vector2(x, y), Vector2(x, minf(y + hh, r.end.y)), JOINT, 1.4)
			var hv := _h(x * 0.3 + y, 4.0)
			if hv < 0.25:
				b.rect(Rect2(x + 2.0, y + 2.0, 50.0, hh - 4.0), SHEEN)
			elif hv > 0.85:
				b.rect(Rect2(x + 2.0, y + 2.0, 50.0, hh - 4.0), STAIN)
			x += 54.0
		y += hh
		row += 1
	# the wear down the middle, toward the stair
	b.band(PackedVector2Array([Vector2(420.0, r.position.y), Vector2(560.0, r.position.y), Vector2(720.0, r.position.y), Vector2(860.0, r.position.y),
		Vector2(420.0, r.end.y), Vector2(560.0, r.end.y), Vector2(720.0, r.end.y), Vector2(860.0, r.end.y)]), 4,
		Color(1.0, 0.96, 0.88, 0.10), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 1.0, 0.0]))
	_cathedral(b, r)
	# Roman fragments set out along the square's sides
	var frags := [Vector2(r.position.x + 150.0, r.position.y + 260.0), Vector2(r.end.x - 160.0, r.position.y + 300.0),
		Vector2(r.position.x + 110.0, r.end.y - 120.0), Vector2(r.end.x - 120.0, r.end.y - 160.0)]
	for i in range(frags.size()):
		_fragment(b, frags[i], i + 1)
	# a café's tables in the square's corner
	var fill := Outdoors.terrace_diners(Game.weather, Game.hour)
	for i in range(4):
		var tp := Vector2(r.end.x - 260.0 + float(i % 2) * 60.0, r.position.y + 200.0 + float(i >> 1) * 60.0)
		for s: float in [-1.0, 1.0]:
			var ch := tp + Vector2(s * 12.0, 0.0)
			b.rect(Rect2(ch.x - 4.0, ch.y - 4.0, 8.0, 8.0), Color(0.36, 0.34, 0.32))
			if _h(float(i) + s, 9.0) < fill:
				NpcFigure.person(b, ch, Vector2(-s, 0.0), 4700 + i * 3 + int(s + 1.0), -1.0, {"arms": NpcFigure.Arms.READY})
		b.circle(tp + Vector2(2.0, 3.0), 8.0, Color(0.05, 0.04, 0.10, 0.25))
		b.circle(tp, 7.5, Color(0.88, 0.88, 0.86))
	var glow_a := Game.lamp_glow()
	if glow_a > 0.05:
		b.glow(Vector2(640.0, r.position.y + 20.0), 220.0, Color(1.0, 0.80, 0.46, 0.14 * glow_a))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, Color(0.42, 0.32, 0.22))
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_cathedral_square_off_leash"))


# The cathedral from the square: its nave roof running away north, the
# front with the great rose over the Gothic door, buttresses either side,
# the bell tower to the east, and the stair down from the door, every step's
# tread lit and its riser dark, with people sitting on them
static func _cathedral(b: ShapeBatch, r: Rect2) -> void:
	var cx := 640.0
	var top := r.position.y
	var L := Shade.light
	# the nave and aisles' roofs, beyond the front
	var nave := Rect2(cx - 130.0, top - 300.0, 260.0, 230.0)
	b.glow(nave.get_center() + L * 18.0, 185.0, Color(0.05, 0.04, 0.10, 0.22), 0.65)
	b.band(PackedVector2Array([
		Vector2(nave.end.x - 2.0, nave.position.y + 4.0), Vector2(nave.end.x + 26.0 * maxf(L.x, 0.2), nave.position.y + 12.0),
		Vector2(nave.end.x - 2.0, nave.end.y), Vector2(nave.end.x + 26.0 * maxf(L.x, 0.2), nave.end.y),
	]), 2, Color(0.05, 0.04, 0.10, 0.20), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	b.rect(Rect2(nave.position.x, nave.position.y, 70.0, nave.size.y), Color(0.60, 0.36, 0.26))
	b.rect(Rect2(nave.end.x - 70.0, nave.position.y, 70.0, nave.size.y), Color(0.50, 0.30, 0.22))
	b.rect(Rect2(cx - 60.0, nave.position.y, 60.0, nave.size.y), Color(0.66, 0.40, 0.28))
	b.rect(Rect2(cx, nave.position.y, 60.0, nave.size.y), Color(0.54, 0.32, 0.24))
	b.line(Vector2(cx, nave.position.y), Vector2(cx, nave.end.y), Color(0.80, 0.56, 0.40), 3.0)
	var ry := nave.position.y + 10.0
	while ry < nave.end.y:
		b.line(Vector2(nave.position.x, ry), Vector2(nave.end.x, ry), Color(0.40, 0.22, 0.16, 0.5), 1.0)
		ry += 11.0
	# the bell tower, octagonal, to the east
	var bt := Vector2(cx + 190.0, top - 120.0)
	b.glow(bt + L * 26.0, 48.0, Color(0.05, 0.04, 0.10, 0.22), 0.45)
	_soft_shadow_band(b, bt, bt + L * 68.0, 38.0, 22.0, Color(0.05, 0.04, 0.10, 0.24))
	var oct := PackedVector2Array()
	for k in range(8):
		oct.append(bt + Vector2.from_angle(TAU * (float(k) + 0.5) / 8.0) * 34.0)
	b.polygon(oct, Color(0.78, 0.70, 0.56))
	var oct2 := PackedVector2Array()
	for k in range(8):
		oct2.append(bt + Vector2.from_angle(TAU * (float(k) + 0.5) / 8.0) * 24.0 + Vector2(-2.0, -4.0))
	b.polygon(oct2, Color(0.88, 0.80, 0.66))
	b.circle(bt + Vector2(-3.0, -6.0), 9.0, Color(0.52, 0.54, 0.56))
	b.circle(bt + Vector2(-5.0, -8.0), 4.0, Color(0.70, 0.72, 0.74))
	# the front, seen a little from the south: its face and buttresses
	var f := Rect2(cx - 150.0, top - 76.0, 300.0, 70.0)
	b.rect(Rect2(f.position + Vector2(0.0, 6.0), f.size), Color(0.05, 0.04, 0.10, 0.28))
	b.rect(f, Color(0.84, 0.76, 0.60))
	b.rect(Rect2(f.position.x, f.position.y, f.size.x, 6.0), Color(0.94, 0.88, 0.74))
	for bx: float in [f.position.x, cx - 64.0, cx + 50.0, f.end.x - 14.0]:
		b.rect(Rect2(bx, f.position.y - 4.0, 14.0, f.size.y + 10.0), Color(0.90, 0.82, 0.66))
		b.rect(Rect2(bx + 10.0, f.position.y - 4.0, 4.0, f.size.y + 10.0), Color(0.62, 0.54, 0.42))
	# the rose window and the pointed door under it
	var rose := Vector2(cx, f.position.y + 24.0)
	b.circle(rose, 18.0, Color(0.62, 0.54, 0.42))
	b.circle(rose, 15.0, Color(0.30, 0.34, 0.46))
	for k in range(8):
		b.line(rose, rose + Vector2.from_angle(TAU * float(k) / 8.0) * 15.0, Color(0.62, 0.54, 0.42), 1.6)
	b.circle(rose, 4.0, Color(0.62, 0.54, 0.42))
	var g := Game.lamp_glow()
	if g > 0.05:
		b.glow(rose, 22.0, Color(1.0, 0.74, 0.40, 0.35 * g))
	b.polygon(PackedVector2Array([Vector2(cx - 22.0, f.end.y), Vector2(cx - 22.0, f.end.y - 18.0), Vector2(cx, f.end.y - 30.0),
		Vector2(cx + 22.0, f.end.y - 18.0), Vector2(cx + 22.0, f.end.y)]), Color(0.36, 0.28, 0.22))
	b.polygon(PackedVector2Array([Vector2(cx - 14.0, f.end.y), Vector2(cx - 14.0, f.end.y - 14.0), Vector2(cx, f.end.y - 22.0),
		Vector2(cx + 14.0, f.end.y - 14.0), Vector2(cx + 14.0, f.end.y)]), Color(0.18, 0.14, 0.12))
	for dx: float in [-100.0, 100.0]:
		b.rect(Rect2(cx + dx - 10.0, f.end.y - 20.0, 20.0, 20.0), Color(0.30, 0.24, 0.20))
	# the stair: each step a lit tread and a riser in shade, wider as it
	# comes down into the square
	var sy := f.end.y
	for k in range(9):
		var w := 220.0 + float(k) * 22.0
		var step := Rect2(cx - w * 0.5, sy, w, 12.0)
		b.rect(step, Color(0.80, 0.74, 0.64).lightened(0.02 * float(k)))
		b.rect(Rect2(step.position.x, step.position.y, step.size.x, 2.0), Color(0.96, 0.92, 0.84))
		b.rect(Rect2(step.position.x, step.end.y - 4.0, step.size.x, 4.0), Color(0.50, 0.44, 0.38))
		b.rect(Rect2(step.position.x, step.end.y, step.size.x, 3.0), Color(0.05, 0.04, 0.10, 0.16))
		sy += 12.0
	# people sitting on the steps in the evening
	var fill := Outdoors.terrace_diners(Game.weather, Game.hour)
	for k in range(8):
		if _h(float(k), 12.0) > fill:
			continue
		var sp := Vector2(cx - 150.0 + _h(float(k), 13.0) * 300.0, f.end.y + 20.0 + float(k % 4) * 24.0)
		if absf(sp.x - cx) < 30.0:
			continue
		NpcFigure.person(b, sp, Vector2(0.0, 1.0), 4800 + k * 5, -1.0, {"arms": NpcFigure.Arms.READY})


# --- posts, stones and small things ----------------------------------------------

static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if is_lamp(m, p):
		m._draw_lamppost(p)
		return
	for i in range(ROMAN_STONES.size()):
		if p.distance_squared_to(ROMAN_STONES[i]) < 4.0:
			_fragment(wc, p, i)
			return
	# the castellers' monument's posts are inside its plinth: nothing to draw


# A Roman fragment: a fluted column drum, a Corinthian capital, an inscribed
# altar, a cornice block with its dentils, or a drum lying on its side
static func _fragment(wc: ShapeBatch, p: Vector2, kind: int) -> void:
	var L := Shade.light
	var sh := Color(0.05, 0.04, 0.10, 0.28)
	var st := Color(0.82, 0.76, 0.64)
	var lit := Color(0.94, 0.90, 0.80)
	var dk := Color(0.56, 0.50, 0.42)
	match kind % 5:
		0:
			wc.capsule(p, p + L * 16.0, 13.0, sh)
			wc.circle(p, 14.0, dk)
			wc.circle(p + Vector2(-1.0, -1.5), 12.5, st)
			for k in range(12):
				var a := TAU * float(k) / 12.0
				wc.line(p + Vector2.from_angle(a) * 9.0, p + Vector2.from_angle(a) * 13.0, dk, 1.4)
			wc.circle(p + Vector2(-3.0, -3.5), 5.0, lit)
		1:
			wc.rect(Rect2(p.x - 14.0 + L.x * 12.0, p.y - 14.0 + L.y * 12.0, 28.0, 28.0), sh)
			wc.rect(Rect2(p.x - 14.0, p.y - 14.0, 28.0, 28.0), dk)
			wc.rect(Rect2(p.x - 13.0, p.y - 13.0, 25.0, 25.0), st)
			for cpt: Vector2 in [Vector2(-9.0, -9.0), Vector2(9.0, -9.0), Vector2(-9.0, 9.0), Vector2(9.0, 9.0)]:
				wc.circle(p + cpt, 4.0, lit)
				wc.circle(p + cpt, 1.8, dk)
			wc.circle(p, 6.5, Color(0.74, 0.68, 0.56))
			for k in range(6):
				wc.line(p, p + Vector2.from_angle(TAU * float(k) / 6.0) * 6.5, dk, 1.0)
		2:
			wc.rect(Rect2(p.x - 12.0 + L.x * 16.0, p.y - 15.0 + L.y * 16.0, 24.0, 30.0), sh)
			wc.rect(Rect2(p.x - 13.0, p.y - 16.0, 26.0, 32.0), dk)
			wc.rect(Rect2(p.x - 11.0, p.y - 14.0, 22.0, 28.0), st)
			wc.rect(Rect2(p.x - 11.0, p.y - 14.0, 22.0, 3.0), lit)
			for k in range(4):
				wc.rect(Rect2(p.x - 8.0, p.y - 7.0 + float(k) * 5.0, 16.0 - float(k % 2) * 5.0, 1.8), Color(0.34, 0.28, 0.22))
		3:
			wc.rect(Rect2(p.x - 18.0 + L.x * 8.0, p.y - 9.0 + L.y * 8.0, 36.0, 18.0), sh)
			wc.rect(Rect2(p.x - 18.0, p.y - 9.0, 36.0, 18.0), st)
			wc.rect(Rect2(p.x - 18.0, p.y - 9.0, 36.0, 4.0), lit)
			var dx := p.x - 16.0
			while dx < p.x + 16.0:
				wc.rect(Rect2(dx, p.y + 3.0, 4.0, 6.0), dk)
				dx += 7.0
		_:
			wc.capsule(p + Vector2(-14.0, 0.0) + L * 6.0, p + Vector2(14.0, 0.0) + L * 6.0, 9.0, sh)
			wc.capsule(p + Vector2(-14.0, 0.0), p + Vector2(14.0, 0.0), 9.0, st)
			wc.line(p + Vector2(-14.0, -5.0), p + Vector2(14.0, -5.0), lit, 3.0)
			wc.circle(p + Vector2(14.0, 0.0), 9.0, dk)
			wc.circle(p + Vector2(14.0, 0.0), 6.0, st)


static func draw_bollard(_m: Node2D, wc: ShapeBatch, h) -> void:
	# a cast-iron bollard the dog marks
	var p: Vector2 = h.pos if h is Dictionary else h
	var done: bool = bool(h.done) if h is Dictionary else false
	wc.circle(p + Vector2(1.5, 1.5), 7.0, SHADOW)
	wc.circle(p, 6.5, Color(0.55, 0.55, 0.54) if done else Color(0.72, 0.72, 0.70))
	wc.circle(p + Vector2(0, -4), 5.0, Color(0.82, 0.82, 0.80))
	wc.circle(p + Vector2(0, -8), 4.0, Color(0.40, 0.40, 0.40))
	if h is Dictionary and not done and float(h.progress) > 0.0:
		wc.draw_arc(p, 14.0, -PI / 2.0, -PI / 2.0 + TAU * float(h.progress) / 0.8, 16, Color(1, 0.95, 0.7), 2.5)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	wc.circle(kp + Vector2(1, 1), 5.0, SHADOW)
	wc.circle(kp, 4.5, Color(0.86, 0.62, 0.28))
	wc.circle(kp + Vector2(-1, -1), 2.0, Color(0.94, 0.78, 0.40))


# the lit fronts after dark: a doorway on each house plot, by the same hash
# as every walk's, none on the coast, the garden or the Roman wall
static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for side in range(2):
		for p: Array in _all_plots(side):
			var top: float = p[0]
			var bot: float = p[1]
			var h: int = p[2]
			var z: int = p[3]
			var k := h % 9973 + side * 7 + 47 * 101
			var kind := NightFronts.kind_of(k)
			if kind == "":
				continue
			var mid := (top + bot) * 0.5
			var face := _face(side, top, bot, _strip(z, side, mid))
			out.append(NightFronts.front(Vector2(face, mid), 1.0 if side == 0 else -1.0, kind, k))
	return out
