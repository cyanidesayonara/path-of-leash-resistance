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

const HOOKS := ["draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer", "draw_freedom", "draw_live", "draw_overhead", "draw_snack", "idle_status", "is_lamp", "night_fronts", "on_bark", "surface", "tick", "tree_kind"]
# draw_bollard receives the hydrant Dictionary (main._draw_world), not a Vector2

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const Panot := preload("res://world/panot.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EdgePath := preload("res://world/edge_path.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const OVERHEAD_FOLLOWS_CAMERA := true
const CX := 640.0
const HALF := 280.0
const START := 260.0
const GATE := -5000.0
const SHADOW := Color(0.06, 0.05, 0.10, 0.28)

# --- colours: warm dusk stone, saffron sea, deep navy shade -----------------
const SEA_DEEP := Color(0.10, 0.22, 0.42)
const SEA_MID := Color(0.18, 0.40, 0.58)
const SEA_GOLD := Color(0.72, 0.48, 0.28, 0.45)
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
const AMPHI_RX := 280.0
const AMPHI_RY := 210.0
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
	Vector2(500.0, -200.0), Vector2(780.0, -200.0),
	Vector2(500.0, -620.0), Vector2(780.0, -620.0),
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


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	# Balcó rail (west of sea)
	out.append(Rect2(768.0, -880.0, 14.0, 980.0))
	# Amphitheatre arena (unwalkable oval approximated as centre block)
	out.append(Rect2(AMPHI_CENTER.x - 120.0, AMPHI_CENTER.y - 130.0, 240.0, 260.0))
	# Roman wall stretches either side of the old-town pinch
	out.append(Rect2(360.0, -4580.0, 70.0, 1100.0))
	out.append(Rect2(850.0, -4580.0, 70.0, 1100.0))
	# Cathedral mass at the finish
	out.append(Rect2(560.0, -4980.0, 160.0, 220.0))
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in solids(m):
		if r.size.x < 100.0 or r.position.x < 500.0:
			out.append(r)
	return out


static func build(m: Node2D) -> Array:
	m.water.assign([Rect2(780.0, -1900.0, 900.0, 2300.0)])
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

	for by: float in [-200.0, -560.0, -1960.0, -2280.0, -2600.0, -2920.0, -3680.0, -4040.0, -4400.0]:
		m.benches.append(Vector2(520.0, by))
		m.benches.append(Vector2(760.0, by))

	for bp: Vector2 in [
		Vector2(490.0, -360.0), Vector2(790.0, -820.0), Vector2(490.0, -2100.0),
		Vector2(790.0, -2500.0), Vector2(530.0, -3620.0), Vector2(750.0, -4180.0),
	]:
		m.bins.append(bp)

	m.fountains.append(Vector2(640.0, -2560.0))
	m.fountains.append(Vector2(640.0, -4480.0))

	# Pilones / bollards on the Rambla
	for i in range(6):
		var py := -1880.0 - float(i) * 160.0
		m.park_props.append({"pos": Vector2(560.0, py), "kind": "bollard", "dig": false, "solid": true, "mark": true})
		m.park_props.append({"pos": Vector2(720.0, py), "kind": "bollard", "dig": false, "solid": true, "mark": true})

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
	if p.y > BALCO_Y1 and p.x > 780.0:
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


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

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, maxf(ctop, GATE - 40.0))
	var hi := minf(vb + 40.0, START + 560.0)
	if hi <= lo:
		wc.lod = keep
		return
	# Sea east of the Balcó / amphitheatre
	if hi > AMPHI_Y1:
		var slo := maxf(lo, AMPHI_Y1)
		wc.rect(Rect2(780.0, slo, 900.0, hi - slo), SEA_DEEP)
		wc.band(PackedVector2Array([
			Vector2(780.0, slo), Vector2(980.0, slo), Vector2(1180.0, slo),
			Vector2(780.0, hi), Vector2(980.0, hi), Vector2(1180.0, hi),
		]), 3, SEA_MID, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.55, 0.0]))
		# Low dusk sun band on the water
		wc.band(PackedVector2Array([
			Vector2(820.0, slo), Vector2(1100.0, slo),
			Vector2(820.0, hi), Vector2(1100.0, hi),
		]), 2, SEA_GOLD, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.55, 0.0]))
	# Path paving
	wc.polygon(_path_poly(lo, hi), PAVE_WARM if lo > RAMBLA_Y1 else PAVE)
	if hi > RAMBLA_Y1 and lo < RAMBLA_Y0:
		Panot.flor(wc, 500.0, 780.0, maxf(lo, RAMBLA_Y1), minf(hi, RAMBLA_Y0), PANOT_INK, PANOT_SHINE)
	if hi > CASTELL_Y1 and lo < CASTELL_Y0:
		Panot.flor(wc, 480.0, 800.0, maxf(lo, CASTELL_Y1), minf(hi, CASTELL_Y0), PANOT_INK, PANOT_SHINE)
	# Amphitheatre tiers (rim path stays walkable west of arena)
	if lo < AMPHI_Y0 and hi > AMPHI_Y1:
		_draw_amphi(wc, maxf(lo, AMPHI_Y1), minf(hi, AMPHI_Y0))
	# Old-town stone setts feel
	if lo < WALLS_Y0 and hi > WALLS_Y1:
		wc.rect(Rect2(460.0, maxf(lo, WALLS_Y1), 360.0, minf(hi, WALLS_Y0) - maxf(lo, WALLS_Y1)), STONE)
	wc.lod = keep


static func _path_poly(lo: float, hi: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := hi
	while true:
		var e := edges_at(y)
		left.append(Vector2(e.x, y))
		right.append(Vector2(e.y, y))
		if y <= lo:
			break
		y = maxf(lo, y - 80.0)
	right.reverse()
	left.append_array(right)
	return left


static func _draw_amphi(wc: ShapeBatch, lo: float, hi: float) -> void:
	# Oval of stone tiers stepping down to the arena by the shore — big enough
	# to recognise from above; path runs along the west rim.
	var c := AMPHI_CENTER
	wc.circle(c + Vector2(10.0, 14.0), AMPHI_RX * 0.95, SHADOW)
	for ring in range(6):
		var t0 := 0.42 + float(ring) * 0.09
		var t1 := t0 + 0.085
		var pts := PackedVector2Array()
		for i in range(28):
			var a := TAU * float(i) / 28.0
			pts.append(c + Vector2(cos(a) * AMPHI_RX * t1, sin(a) * AMPHI_RY * t1))
		for i in range(27, -1, -1):
			var a := TAU * float(i) / 28.0
			pts.append(c + Vector2(cos(a) * AMPHI_RX * t0, sin(a) * AMPHI_RY * t0))
		var col := STONE.lerp(STONE_LIT, float(ring) * 0.14).darkened(0.04 * float(5 - ring))
		wc.polygon(pts, col)
		# course joint every other ring
		if ring % 2 == 0:
			for i in range(0, 28, 2):
				var a := TAU * float(i) / 28.0
				var p0 := c + Vector2(cos(a) * AMPHI_RX * t0, sin(a) * AMPHI_RY * t0)
				var p1 := c + Vector2(cos(a) * AMPHI_RX * t1, sin(a) * AMPHI_RY * t1)
				wc.line(p0, p1, STONE_DARK, 1.5)
	var arena := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		arena.append(c + Vector2(cos(a) * AMPHI_RX * 0.38, sin(a) * AMPHI_RY * 0.38))
	wc.polygon(arena, STONE_DARK.darkened(0.08))
	wc.glow(c, 40.0, Color(STONE_LIT.r, STONE_LIT.g, STONE_LIT.b, 0.18))


static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep := b.lod
	b.lod = true
	var lo := maxf(vt - 280.0, GATE - 40.0)
	var hi := minf(vb + 280.0, START + 560.0)
	if hi <= lo:
		b.lod = keep
		return
	# Sea cliff east of the Balcó: deep water, gold dusk band, railway below
	if hi > BALCO_Y1 and lo < BALCO_Y0:
		var slo := maxf(lo, BALCO_Y1)
		var shi := minf(hi, BALCO_Y0)
		b.rect(Rect2(790.0, slo, 900.0, shi - slo), SEA_DEEP)
		b.band(PackedVector2Array([
			Vector2(800.0, slo), Vector2(1050.0, slo), Vector2(1300.0, slo),
			Vector2(800.0, shi), Vector2(1050.0, shi), Vector2(1300.0, shi),
		]), 3, SEA_MID, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.5, 0.0]))
		b.band(PackedVector2Array([
			Vector2(860.0, slo), Vector2(1200.0, slo),
			Vector2(860.0, shi), Vector2(1200.0, shi),
		]), 2, SEA_GOLD, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.6, 0.0]))
		# railway cutting under the rail
		b.rect(Rect2(792.0, slo, 36.0, shi - slo), Color(0.16, 0.16, 0.18))
		var ry := ceilf(slo / 40.0) * 40.0
		while ry < shi:
			b.line(Vector2(794.0, ry), Vector2(826.0, ry), Color(0.55, 0.52, 0.42), 2.2)
			ry += 40.0
	# Town fronts with roofs, depth and warm dusk windows
	b.rect(Rect2(-200.0, lo, 560.0, hi - lo), Color(0.32, 0.28, 0.24))
	b.rect(Rect2(920.0, lo, 500.0, hi - lo), Color(0.34, 0.30, 0.26))
	var plot := floorf(lo / 120.0) * 120.0
	var idx := 0
	while plot < hi:
		_town_front(b, Vector2(280.0, plot + 50.0), -1.0, idx)
		_town_front(b, Vector2(1000.0, plot + 40.0), 1.0, idx + 3)
		idx += 1
		plot += 120.0
	# Roman wall blocks in the old-town stretch
	if lo < WALLS_Y0 and hi > WALLS_Y1:
		_draw_roman_walls(b, maxf(lo, WALLS_Y1), minf(hi, WALLS_Y0))
	b.lod = keep


static func _town_front(b: ShapeBatch, p: Vector2, side: float, seed_i: int) -> void:
	var w := 100.0 + _h(float(seed_i), 2.0) * 40.0
	var h := 80.0 + _h(float(seed_i), 5.0) * 30.0
	var r := Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h)
	b.rect(Rect2(r.position + Vector2(8.0, 10.0), r.size), SHADOW)
	b.rect(r, FASCIA.darkened(0.05 * float(seed_i % 3)))
	b.rect(Rect2(r.position.x - 6.0, r.position.y - 14.0, r.size.x + 12.0, 16.0), STONE_DARK)
	# lit windows at dusk
	var glow_a := Game.lamp_glow()
	for k in range(3):
		for col in range(2):
			var wx := r.position.x + 14.0 + float(col) * (r.size.x * 0.4)
			var wy := r.position.y + 16.0 + float(k) * 20.0
			b.rect(Rect2(wx, wy, 14.0, 12.0), Color(0.22, 0.18, 0.14))
			if glow_a > 0.1 and (seed_i + k + col) % 3 != 0:
				b.rect(Rect2(wx + 1.0, wy + 1.0, 12.0, 10.0), Color(1.0, 0.82, 0.45, 0.35 + 0.4 * glow_a))
	# balcony
	b.rect(Rect2(r.position.x + 10.0, r.position.y + h * 0.35, r.size.x - 20.0, 6.0), Color(0.40, 0.38, 0.36))


static func _draw_roman_walls(b: ShapeBatch, lo: float, hi: float) -> void:
	# Huge rough courses with joints; a gate through them; narrow street beyond
	var y := floorf(lo / 56.0) * 56.0
	while y < hi:
		for side: float in [-1.0, 1.0]:
			var x := 340.0 if side < 0.0 else 840.0
			var course := 0
			var cy := y
			while cy < y + 52.0:
				var bw := 72.0 + _h(cy * 0.13 + side, 2.0) * 22.0
				var bh := 18.0 + _h(cy * 0.09, 3.0) * 8.0
				var ox := _h(cy * 0.2 + side, 7.0) * 8.0
				b.rect(Rect2(x + ox + 4.0, cy + 4.0, bw, bh), SHADOW)
				b.rect(Rect2(x + ox, cy, bw, bh), ROMAN.darkened(0.04 * float(course % 3)))
				b.rect(Rect2(x + ox + 3.0, cy + 2.0, bw * 0.4, bh * 0.45), ROMAN_LIT)
				b.line(Vector2(x + ox, cy + bh), Vector2(x + ox + bw, cy + bh), STONE_DARK, 2.0)
				cy += bh + 2.0
				course += 1
		# Gate / arch every stretch
		if int(absf(y) / 56.0) % 4 == 0:
			b.rect(Rect2(420.0, y + 4.0, 440.0, 14.0), ARCH.darkened(0.1))
			b.circle(Vector2(640.0, y + 10.0), 56.0, ARCH)
			b.circle(Vector2(640.0, y + 10.0), 40.0, PAVE)
			# balcony over the arch
			b.rect(Rect2(600.0, y - 18.0, 80.0, 10.0), Color(0.55, 0.48, 0.40))
			b.rect(Rect2(610.0, y - 28.0, 12.0, 12.0), Color(0.70, 0.22, 0.22, 0.5))
			b.rect(Rect2(658.0, y - 28.0, 12.0, 12.0), Color(0.70, 0.22, 0.22, 0.5))
		y += 56.0


static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep := b.lod
	b.lod = true
	var t_sec := float(AnimClock.msec()) * 0.001
	# Balcó del Mediterrani: continuous rail on the cliff, people at the view
	if vb > BALCO_Y1 and vt < BALCO_Y0:
		var ry := maxf(vt, BALCO_Y1)
		var rhi := minf(vb, BALCO_Y0)
		b.rect(Rect2(760.0, ry, 22.0, rhi - ry), RAIL.darkened(0.1))
		b.rect(Rect2(764.0, ry, 6.0, rhi - ry), RAIL.lightened(0.15))
		while ry < rhi:
			b.rect(Rect2(758.0, ry, 18.0, 10.0), RAIL)
			b.circle(Vector2(767.0, ry + 2.0), 4.0, RAIL.lightened(0.25))
			# viewpoint lingerers every stretch
			if int(absf(ry) / 36.0) % 3 == 0:
				var vp := Vector2(740.0, ry + 8.0)
				b.circle(vp + Vector2(2, 2), 8.0, SHADOW)
				b.circle(vp, 7.5, Color(0.40, 0.36, 0.48))
				b.circle(vp + Vector2(0, -8), 4.5, Color(0.86, 0.70, 0.56))
			ry += 36.0
		# Balcó view spot glow
		if BALCO_SPOT.y >= vt - 40.0 and BALCO_SPOT.y <= vb + 40.0:
			b.glow(BALCO_SPOT, BALCO_R * 0.7, Color(1.0, 0.78, 0.40, 0.12))
	# Rambla Nova: benches, kiosks between the plane trees
	if vb > RAMBLA_Y1 and vt < RAMBLA_Y0:
		_draw_rambla_props(b, maxf(vt, RAMBLA_Y1), minf(vb, RAMBLA_Y0))
	# Long dusk shadows from plane trees
	for p: Vector2 in PLANE_SPOTS:
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		b.capsule(p, p + Vector2(56.0, 28.0), 12.0, SHADOW)
		b.circle(p, 13.0, PLANE_TRUNK)
		b.circle(p + Vector2(2, -2), 9.0, PLANE_TRUNK.lightened(0.12))
		b.circle(p + Vector2(0, -10), 32.0, PLANE_CROWN)
		b.circle(p + Vector2(-12, -16), 18.0, PLANE_LIT)
		b.circle(p + Vector2(10, -14), 14.0, PLANE_CROWN.lightened(0.08))
	# Casteller monument (group of figures in depth, not dots)
	if MONUMENT.y >= vt - 80.0 and MONUMENT.y <= vb + 80.0:
		_draw_castellers(b, MONUMENT, 5, t_sec, false)
	# Live casteller practice
	var cst: Dictionary = m.tarragona_castell
	var cstate := String(cst.get("state", "idle"))
	if CASTELL_CENTER.y >= vt - 120.0 and CASTELL_CENTER.y <= vb + 120.0:
		if cstate == "telegraph" or cstate == "build" or cstate == "crowned":
			_draw_crowd(b, cst, t_sec)
			# gralla telegraph: visible as well as heard
			if cstate == "telegraph":
				_draw_gralla(b, CASTELL_CENTER + Vector2(-70.0, 20.0), t_sec)
			var tier := int(cst.get("tier", 0))
			if tier > 0:
				_draw_castellers(b, CASTELL_CENTER, tier, t_sec, true)
	# Bench sitters
	for s: Dictionary in m.tarragona_sitters:
		var sp: Vector2 = s.pos
		if sp.y < vt - 40.0 or sp.y > vb + 40.0:
			continue
		_draw_sitter(b, sp, s.face)
	# Prize
	if not bool(m.prize_taken) and PRIZE.y >= vt - 40.0 and PRIZE.y <= vb + 40.0:
		b.glow(PRIZE, 18.0, Color(1.0, 0.88, 0.50, 0.22))
		b.circle(PRIZE, 7.0, Color(0.92, 0.90, 0.82))
		b.circle(PRIZE, 4.0, Color(0.28, 0.48, 0.22))
	b.lod = keep


static func _draw_rambla_props(b: ShapeBatch, lo: float, hi: float) -> void:
	var y := floorf(lo / 200.0) * 200.0
	var i := 0
	while y < hi:
		# bench on the centre strip
		var bx := CX + (20.0 if i % 2 == 0 else -30.0)
		var bp := Vector2(bx, y + 40.0)
		if bp.y >= lo and bp.y <= hi:
			b.rect(Rect2(bp.x - 22.0 + 4.0, bp.y - 6.0 + 4.0, 44.0, 14.0), SHADOW)
			b.rect(Rect2(bp.x - 22.0, bp.y - 6.0, 44.0, 14.0), Color(0.42, 0.32, 0.22))
			b.rect(Rect2(bp.x - 20.0, bp.y - 10.0, 40.0, 5.0), Color(0.50, 0.38, 0.26))
		# kiosk every other bay
		if i % 2 == 0:
			var kx := CX + (90.0 if i % 4 == 0 else -100.0)
			var kp := Vector2(kx, y + 100.0)
			if kp.y >= lo and kp.y <= hi:
				b.rect(Rect2(kp.x - 18.0 + 5.0, kp.y - 16.0 + 5.0, 36.0, 32.0), SHADOW)
				b.rect(Rect2(kp.x - 18.0, kp.y - 16.0, 36.0, 32.0), Color(0.62, 0.28, 0.22))
				b.rect(Rect2(kp.x - 20.0, kp.y - 22.0, 40.0, 10.0), Color(0.78, 0.72, 0.55))
				b.rect(Rect2(kp.x - 12.0, kp.y - 8.0, 24.0, 10.0), Color(0.90, 0.88, 0.78, 0.55))
		y += 200.0
		i += 1


static func _draw_gralla(b: ShapeBatch, p: Vector2, t_sec: float) -> void:
	# Musician with a high gralla: visible telegraph before the tower rises
	b.circle(p + Vector2(3, 3), 11.0, SHADOW)
	b.circle(p, 10.0, Color(0.18, 0.32, 0.55))
	b.circle(p + Vector2(0, -10), 5.5, Color(0.86, 0.70, 0.56))
	var tip := p + Vector2(18.0 + sin(t_sec * 14.0) * 2.0, -16.0)
	b.line(p + Vector2(4, -6), tip, Color(0.72, 0.62, 0.40), 3.0)
	b.glow(tip, 16.0 + sin(t_sec * 10.0) * 4.0, Color(1.0, 0.92, 0.55, 0.35))


static func _draw_sitter(b: ShapeBatch, p: Vector2, face: Vector2) -> void:
	b.circle(p + Vector2(2, 2), 10.0, SHADOW)
	b.circle(p, 9.0, Color(0.35, 0.42, 0.55))
	b.circle(p + face * 2.0 + Vector2(0, -10), 5.5, Color(0.86, 0.70, 0.58))


static func _draw_crowd(b: ShapeBatch, cst: Dictionary, t_sec: float) -> void:
	# Crowd packs in a readable ring around the tower
	var pack := 0.35
	var st := String(cst.get("state", "idle"))
	if st == "build":
		pack = 0.55 + 0.35 * (1.0 - clampf(float(cst.get("t", 0.0)) / CASTELL_BUILD, 0.0, 1.0))
	elif st == "crowned":
		pack = 0.95
	elif st == "telegraph":
		pack = 0.35
	# ground disc so the ring reads as a gathering
	b.circle(CASTELL_CENTER + Vector2(4, 6), 70.0 + pack * 40.0, Color(0.08, 0.08, 0.12, 0.18 + pack * 0.12))
	var n := int(14.0 + pack * 22.0)
	for i in range(n):
		var a := TAU * float(i) / float(n) + t_sec * 0.12
		var r := 42.0 + _h(float(i), 8.0) * 55.0 * pack
		var p := CASTELL_CENTER + Vector2(cos(a) * r * 0.85, sin(a) * r)
		if not CROWD_RECT.grow(30.0).has_point(p):
			continue
		var shirt := SASH if i % 2 == 0 else SASH_B
		b.circle(p + Vector2(2.0, 2.0), 8.5, SHADOW)
		b.circle(p, 8.0, shirt)
		b.circle(p + Vector2(0, -9), 4.8, Color(0.86, 0.68, 0.54))


static func _draw_castellers(b: ShapeBatch, at: Vector2, tiers: int, t_sec: float, live: bool) -> void:
	# Tower in tiers of figures with depth and shadow; pinya base, then rising
	var wob := sin(t_sec * (3.0 if live else 1.2)) * (2.4 if live else 0.7)
	b.circle(at + Vector2(8, 10), 34.0, SHADOW)
	# Pinya (base ring) — packed bodies reading as a platform
	for i in range(8):
		var a := TAU * float(i) / 8.0 + 0.15
		var p := at + Vector2(cos(a) * 28.0, sin(a) * 16.0 + 8.0)
		b.circle(p + Vector2(2, 2), 9.0, SHADOW)
		b.circle(p, 8.5, SASH if i % 2 == 0 else SASH_B)
		b.circle(p + Vector2(0, -8), 5.0, Color(0.84, 0.66, 0.52))
	var y := -10.0
	for t in range(mini(tiers, 4)):
		var n := 4 if t == 0 else (3 if t == 1 else (2 if t < 3 else 1))
		for i in range(n):
			var x := (float(i) - float(n - 1) * 0.5) * 15.0 + wob * (1.0 if t > 0 else 0.0)
			var p := at + Vector2(x, y)
			var col := SASH_B if (t + i) % 2 == 0 else SASH
			b.circle(p + Vector2(2, 3), 8.0 - float(t) * 0.4, SHADOW)
			b.circle(p, 7.5 - float(t) * 0.4, col)
			b.circle(p + Vector2(0, -8), 4.4 - float(t) * 0.2, Color(0.86, 0.68, 0.54))
		y -= 20.0
	if tiers >= 4:
		var tip := at + Vector2(wob, y - 4.0)
		b.circle(tip + Vector2(2, 2), 6.0, SHADOW)
		b.circle(tip, 5.5, Color(0.94, 0.94, 0.96))
		b.circle(tip + Vector2(0, -8), 3.8, Color(0.88, 0.70, 0.56))
		b.line(tip + Vector2(0, -11), tip + Vector2(0, -22), Color(0.94, 0.94, 0.96), 2.2)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	var glow := Game.lamp_glow()
	if glow <= 0.02:
		return
	var b := ShapeBatch.new(ci)
	for lp: Vector2 in LAMP_SPOTS:
		b.glow(lp + Vector2(0, -18), 34.0 + glow * 20.0, Color(1.0, 0.78, 0.42, 0.18 * glow))
		b.circle(lp + Vector2(0, -18), 4.0, Color(1.0, 0.88, 0.55, 0.7 * glow))
	b.flush()


static func draw_freedom(m: Node2D, c: Object) -> void:
	# Plaça de la Seu: cathedral steps and facade, square's own paving
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	b.rect(Rect2(r.position.x - 80.0, r.position.y - 120.0, r.size.x + 160.0, r.size.y + 200.0), Color(0.40, 0.36, 0.30))
	b.rect(r, STONE.lightened(0.06))
	Panot.flor(b, r.position.x + 10.0, r.end.x - 10.0, r.position.y + 10.0, r.end.y - 10.0, PANOT_INK, PANOT_SHINE)
	# cathedral facade at the north end
	var facade := Rect2(r.position.x + 80.0, r.position.y - 40.0, r.size.x - 160.0, 90.0)
	b.rect(Rect2(facade.position + Vector2(10, 12), facade.size), SHADOW)
	b.rect(facade, STONE_LIT)
	b.rect(Rect2(facade.position.x + 20.0, facade.position.y + 20.0, facade.size.x - 40.0, 50.0), STONE_DARK)
	# rose window
	b.circle(facade.get_center() + Vector2(0, -8), 22.0, Color(0.55, 0.70, 0.82, 0.55))
	b.circle(facade.get_center() + Vector2(0, -8), 10.0, Color(0.70, 0.82, 0.90, 0.4))
	# twin towers
	b.rect(Rect2(facade.position.x - 10.0, facade.position.y - 70.0, 36.0, 80.0), STONE)
	b.rect(Rect2(facade.end.x - 26.0, facade.position.y - 70.0, 36.0, 80.0), STONE)
	b.rect(Rect2(facade.position.x - 6.0, facade.position.y - 78.0, 28.0, 12.0), STONE_LIT)
	b.rect(Rect2(facade.end.x - 22.0, facade.position.y - 78.0, 28.0, 12.0), STONE_LIT)
	# steps down into the square
	for s in range(5):
		var sy := facade.end.y + float(s) * 10.0
		b.rect(Rect2(facade.position.x + 30.0 - float(s) * 8.0, sy, facade.size.x - 60.0 + float(s) * 16.0, 9.0),
			STONE.lerp(STONE_LIT, float(s) * 0.08))
	var glow_a := Game.lamp_glow()
	if glow_a > 0.05:
		b.glow(facade.get_center(), 70.0, Color(1.0, 0.82, 0.45, 0.15 * glow_a))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, Color(0.42, 0.32, 0.22))
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_cathedral_square_off_leash"))


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	# Plane trunks are drawn in draw_live; lamps here
	if is_lamp(_m, p):
		wc.rect(Rect2(p.x - 3.0, p.y - 28.0, 6.0, 28.0), LAMP_IRON)
		wc.circle(p + Vector2(0, -30), 7.0, LAMP_IRON)
		var g := Game.lamp_glow()
		if g > 0.05:
			wc.circle(p + Vector2(0, -30), 4.0, Color(1.0, 0.86, 0.5, 0.55 + 0.4 * g))
		return
	for sp: Vector2 in ROMAN_STONES:
		if p.distance_squared_to(sp) < 4.0:
			wc.rect(Rect2(p.x - 14.0, p.y - 10.0, 28.0, 20.0), ROMAN)
			wc.rect(Rect2(p.x - 10.0, p.y - 6.0, 12.0, 8.0), ROMAN_LIT)
			return


static func draw_bollard(_m: Node2D, wc: ShapeBatch, h) -> void:
	# Barcelona pilona: cast-iron bollard the dog marks
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


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	return NightFronts.along_edges(m, START, GATE + 80.0, 220.0, 24.0, 47)
