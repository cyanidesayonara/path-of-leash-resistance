class_name Poblenou
extends RefCounted

# WALK: RAMBLA DEL POBLENOU — the leafy village-to-sea boulevard.
#
# Up the screen:
# - Upper Rambla (260..-850): sunlit panot de flor central promenade framed by
#   twin rows of tall plane trees, Catalan Modernisme shopfronts and terraces.
# - Horchata & Terrace Stretch (-850..-2550): tiled horchata kiosk with striped
#   awning, barrel churns and farton trays, café tables in fair weather, wait-staff
#   carrying trays across the cobbles.
# - Plaça de Prim (-2550..-3800): widens into lime-washed cottages, twin flower
#   planters, umbrella-shaded benches, and cobblestone compass inlay.
# - Seaward Promenade (-3800..-5000): palms join the plane trees past a brick
#   textile-mill chimney and ice-cream kiosk out to Plaça del Poblenou off leash.
#
# Signature live event: a café waiter wobbles a tray of horchata & fartons for
# 1.0 s ("Watch out, horchata!" + pulsing splash ring) before spilling it onto
# the tiles. Pull clear for a clean dodge and snatch the dropped farton.

const HOOKS := [
	"draw_bollard",
	"draw_column",
	"draw_cross_section",
	"draw_edge_layer",
	"draw_freedom",
	"draw_live",
	"draw_overhead",
	"draw_snack",
	"idle_status",
	"is_lamp",
	"night_fronts",
	"night_lights",
	"surface",
	"tick",
	"tree_kind",
]

const SOFT_WEAR := true

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EdgePath := preload("res://world/edge_path.gd")
const CityRoofs := preload("res://world/city_roofs.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const Panot := preload("res://world/panot.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const CX := 640.0
const HALF := 290.0
const START := 260.0
const GATE := -5000.0
const SIDES: Array[float] = [-1.0, 1.0]
const FAR_L := -300.0
const FAR_R := 1580.0
const FACE := 18.0
const CHUNK := 160.0

# --- route zones --------------------------------------------------------------
const UPPER_END := -850.0
const HORCHATA_START := -1020.0
const HORCHATA_END := -2550.0
const PRIM_START := -2750.0
const PRIM_END := -3800.0
const SEAWARD_START := -3980.0

# --- colours ------------------------------------------------------------------
const PAVE_WARM := Color(0.76, 0.71, 0.63)
const PAVE_CENTER := Color(0.84, 0.78, 0.68)
const PAVE_KERB := Color(0.56, 0.52, 0.46)
const PRIM_COB := Color(0.72, 0.68, 0.61)
const PRIM_LIGHT := Color(0.85, 0.80, 0.70)
const PANOT_INK := Color(0.18, 0.14, 0.10, 0.14)
const PANOT_SHINE := Color(1.0, 0.97, 0.90, 0.11)
const PLANTER_STONE := Color(0.68, 0.64, 0.58)
const PLANTER_SOIL := Color(0.32, 0.24, 0.16)
const FLOWER_TEAL := Color(0.16, 0.56, 0.52)
const FLOWER_CORAL := Color(0.90, 0.34, 0.36)
const FLOWER_SAFFRON := Color(0.96, 0.78, 0.24)
const BRICK := Color(0.64, 0.30, 0.22)
const BRICK_DK := Color(0.44, 0.20, 0.15)
const HORCHATA_COL := Color(0.96, 0.93, 0.84)
const HORCHATA_STRIPE := Color(0.16, 0.54, 0.40)
const WOOD := Color(0.48, 0.33, 0.20)
const WOOD_LIT := Color(0.64, 0.45, 0.28)
const SHADOW := Color(0.06, 0.08, 0.12, 0.24)
const IRON := Color(0.18, 0.19, 0.22)

# --- landmarks & props --------------------------------------------------------
const DARE_POS := Vector2(760.0, -1480.0)
const PRIZE := Vector2(546.0, -1520.0)
const PRIZE_TEXT := "snatch a farton off the horchata counter"

# [center, kind]
const KIOSKS: Array = [
	[Vector2(780.0, -640.0), "flowers"],
	[Vector2(500.0, -1520.0), "horchata"],
	[Vector2(785.0, -1980.0), "pastry"],
	[Vector2(510.0, -2980.0), "books"],
	[Vector2(770.0, -4240.0), "gelato"],
]

const PRIM_PLANTERS: Array[Rect2] = [
	Rect2(430.0, -3290.0, 68.0, 56.0),
	Rect2(782.0, -3290.0, 68.0, 56.0),
]

const FACTORY_PLINTH := Rect2(760.0, -4640.0, 72.0, 54.0)

const PLANE_TREES: Array[Vector2] = [
	Vector2(455.0, -120.0), Vector2(825.0, -120.0),
	Vector2(455.0, -360.0), Vector2(825.0, -360.0),
	Vector2(455.0, -820.0), Vector2(825.0, -820.0),
	Vector2(445.0, -1240.0), Vector2(835.0, -1240.0),
	Vector2(445.0, -1720.0), Vector2(835.0, -1720.0),
	Vector2(445.0, -2220.0), Vector2(835.0, -2220.0),
	Vector2(445.0, -2460.0), Vector2(835.0, -2460.0),
	Vector2(415.0, -2880.0), Vector2(865.0, -2880.0),
	Vector2(415.0, -3560.0), Vector2(865.0, -3560.0),
]

const PALM_TREES: Array[Vector2] = [
	Vector2(460.0, -4080.0), Vector2(820.0, -4080.0),
	Vector2(460.0, -4480.0), Vector2(820.0, -4480.0),
	Vector2(460.0, -4820.0), Vector2(820.0, -4820.0),
]

const STREET_LAMPS: Array[Vector2] = [
	Vector2(465.0, -240.0), Vector2(815.0, -740.0),
	Vector2(445.0, -1380.0), Vector2(835.0, -1860.0),
	Vector2(420.0, -2640.0), Vector2(860.0, -3420.0),
	Vector2(460.0, -4020.0), Vector2(820.0, -4720.0),
]

const PILONES: Array[Vector2] = [
	Vector2(540.0, -960.0), Vector2(740.0, -960.0),
	Vector2(540.0, -2660.0), Vector2(740.0, -2660.0),
]

const BINS: Array[Vector2] = [
	Vector2(470.0, -460.0), Vector2(810.0, -1100.0),
	Vector2(460.0, -2080.0), Vector2(840.0, -3060.0),
	Vector2(480.0, -4320.0),
]

const FOUNTAINS: Array[Vector2] = [
	Vector2(780.0, -3660.0),
]

# --- tray event constants -----------------------------------------------------
const TRAY_WARN := 1.0
const TRAY_SPLASH_R := 66.0
const TRAY_SPILL_LIFE := 5.5
const TRAY_COOLDOWN := 7.0
const WAITER_SPOTS: Array[Vector2] = [
	Vector2(582.0, -1320.0),
	Vector2(698.0, -1780.0),
	Vector2(582.0, -2260.0),
]

static var _nodes: Array = []
static var _recs: Dictionary = {}
static var _recs_key: Array = []


static func _hi(k: int) -> int:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16)) % 1000003


static func _h(k: int) -> float:
	return float(_hi(k)) / 1000003.0


static func _is_in(list: Array[Vector2], p: Vector2) -> bool:
	for q: Vector2 in list:
		if p.distance_squared_to(q) < 4.0:
			return true
	return false


# --- corridor & surfaces ------------------------------------------------------

static func edge_nodes(_m: Node2D = null) -> Array:
	return [
		{"y": START, "cx": CX, "half": 215.0},
		{"y": UPPER_END, "cx": CX, "half": 215.0},
		{"y": HORCHATA_START, "cx": CX, "half": 245.0},
		{"y": HORCHATA_END, "cx": CX, "half": 245.0},
		{"y": PRIM_START, "cx": CX, "half": HALF},
		{"y": PRIM_END, "cx": CX, "half": HALF},
		{"y": SEAWARD_START, "cx": CX, "half": 225.0},
		{"y": GATE, "cx": CX, "half": 225.0},
	]


static func _edges_at(y: float) -> Vector2:
	if _nodes.is_empty():
		_nodes = edge_nodes()
	return EdgePath.edges(_nodes, y, CX, HALF)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for k: Array in KIOSKS:
		var pos: Vector2 = k[0]
		out.append(Rect2(pos.x - 36.0, pos.y - 22.0, 72.0, 44.0))
	for pr: Rect2 in PRIM_PLANTERS:
		out.append(pr)
	out.append(FACTORY_PLINTH)
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = solids(m)
	for lp: Vector2 in STREET_LAMPS:
		out.append(Rect2(lp.x - 10.0, lp.y - 10.0, 20.0, 20.0))
	for pl: Vector2 in PILONES:
		out.append(Rect2(pl.x - 8.0, pl.y - 8.0, 16.0, 16.0))
	return out


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(PLANE_TREES, p):
		return m.TREE_PLANE
	if _is_in(PALM_TREES, p):
		return m.TREE_PALM
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(STREET_LAMPS, p)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return Surfaces.S.PAVEMENT
	var e := _edges_at(p.y)
	if p.x >= e.x - 8.0 and p.x <= e.y + 8.0:
		return Surfaces.S.PAVEMENT
	return Surfaces.S.GRASS


# --- build --------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DEL POBLENOU"
	m.gate_l = 420.0
	m.gate_r = 860.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([
		Vector2(600.0, -480.0), Vector2(680.0, -900.0),
		Vector2(570.0, -1920.0), Vector2(690.0, -2420.0),
		Vector2(580.0, -3460.0), Vector2(690.0, -4560.0),
	], TYPE_VECTOR2, &"", null)
	m.fountains = Array(FOUNTAINS.duplicate(), TYPE_VECTOR2, &"", null)

	m.poblenou_tray = {
		"state": "idle", "idx": 0, "t": 1.2,
		"waiter": WAITER_SPOTS[0], "target": WAITER_SPOTS[0] + Vector2(36.0, 20.0),
		"farton": Vector2.ZERO, "farton_active": false, "hit": false,
		"said": false, "arm_next": 0.0,
	}
	m.poblenou_trays_dodged = 0
	m.poblenou_trees_marked = {}
	m.poblenou_kiosks_sniffed = {}

	for t: Vector2 in PLANE_TREES:
		m.poles.append(t)
	for pm: Vector2 in PALM_TREES:
		m.poles.append(pm)
	for lp: Vector2 in STREET_LAMPS:
		m.poles.append(lp)
	for pl: Vector2 in PILONES:
		m.poles.append(pl)
	m.deco_pole_count = m.poles.size()

	m.bins = Array(BINS.duplicate(), TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(455.0, -640.0), Vector2(825.0, -1420.0),
		Vector2(465.0, -2140.0), Vector2(450.0, -3100.0),
		Vector2(830.0, -3100.0), Vector2(465.0, -4380.0),
	], TYPE_VECTOR2, &"", null)

	var marks: Array[Vector2] = []
	for i in range(6):
		marks.append(PLANE_TREES[i * 3])
	for pl: Vector2 in PILONES:
		marks.append(pl)

	var snacks: Array[Vector2] = [
		Vector2(560.0, -680.0), Vector2(690.0, -1560.0),
		Vector2(590.0, -2380.0), Vector2(640.0, -3420.0),
		Vector2(580.0, -4440.0),
	]
	return [marks, snacks]


# --- tick ---------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	_tick_trees(m)
	_tick_kiosks(m, dp)
	_tick_tray(m, delta, dp, hp)


static func _tick_trees(m: Node2D) -> void:
	for i in range(PLANE_TREES.size()):
		if m.poblenou_trees_marked.has(i):
			continue
		var tp: Vector2 = PLANE_TREES[i]
		for spot: Vector2 in m.marks:
			if spot.distance_to(tp) < 38.0:
				m.poblenou_trees_marked[i] = true
				break


static func _tick_kiosks(m: Node2D, dp: Vector2) -> void:
	for i in range(KIOSKS.size()):
		if m.poblenou_kiosks_sniffed.has(i):
			continue
		var pos: Vector2 = KIOSKS[i][0]
		if dp.distance_to(pos) < 62.0 and m.dog.velocity.length() < 95.0:
			m.poblenou_kiosks_sniffed[i] = true
			m.award_points(1, I18n.t("w_poblenou_kiosk_1"))
			Sfx.play("rustle", 1.05)


static func _tick_tray(m: Node2D, delta: float, dp: Vector2, hp: Vector2) -> void:
	var st: Dictionary = m.poblenou_tray
	if st.is_empty():
		return
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))

	match state:
		"idle":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				for i in range(WAITER_SPOTS.size()):
					var wp: Vector2 = WAITER_SPOTS[i]
					if dp.distance_to(wp) < 280.0 and i >= int(st.get("idx", 0)):
						var step_dir := Vector2(1.0 if wp.x < CX else -1.0, 0.25).normalized()
						var tgt := dp if dp.distance_to(wp) < 160.0 else (wp + step_dir * 68.0)
						var e := _edges_at(tgt.y)
						tgt.x = clampf(tgt.x, e.x + 56.0, e.y - 56.0)
						st["state"] = "warn"
						st["idx"] = i + 1
						st["t"] = TRAY_WARN
						st["waiter"] = wp
						st["target"] = tgt
						st["hit"] = false
						st["farton_active"] = false
						st["said"] = true
						m.float_text(wp + Vector2(0.0, -34.0), I18n.t("w_watch_out_horchata"), Color(1.0, 0.94, 0.80), m.POP_SAY)
						m.feed.say(I18n.t("w_horchata_tray_tipping"), EventFeed.Tone.LOUD)
						Sfx.play("hiss", 0.78)
						break
		"warn":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				var tgt: Vector2 = st["target"]
				st["state"] = "spill"
				st["t"] = TRAY_SPILL_LIFE
				st["farton"] = tgt + Vector2(22.0 if tgt.x < CX else -22.0, 12.0)
				st["farton_active"] = true
				Sfx.play("splash", 0.9)
				var hit_dog := dp.distance_to(tgt) < TRAY_SPLASH_R
				var hit_human := hp.distance_to(tgt) < TRAY_SPLASH_R * 0.9
				if hit_dog or hit_human:
					st["hit"] = true
					m.bones = maxi(0, m.bones - 2)
					m.shake_t = maxf(float(m.shake_t), 0.35)
					m.float_text(tgt, I18n.t("w_sticky_horchata"), Color(0.95, 0.72, 0.45))
					m.feed.say(I18n.t("w_horchata_spilled_on_you"), EventFeed.Tone.BAD)
					m._update_hud()
				else:
					m.poblenou_trays_dodged += 1
					m.award_points(4, I18n.t("w_tray_dodge_4"))
					if m.combo != null:
						m.combo.add("SAVE", 4)
					m.feed.say(I18n.t("w_tray_dodged_clean"), EventFeed.Tone.GOOD)
		"spill":
			t -= delta
			st["t"] = t
			if bool(st.get("farton_active", false)):
				var fp: Vector2 = st["farton"]
				if dp.distance_to(fp) < 32.0:
					st["farton_active"] = false
					m.award_points(2, I18n.t("w_farton_snatch_2"))
					m.float_text(fp, I18n.t("w_sweet_farton"), Color(0.98, 0.88, 0.56))
					Sfx.play("pickup", 1.1)
					m._update_hud()
			if t <= 0.0:
				st["state"] = "idle"
				st["t"] = TRAY_COOLDOWN
				st["farton_active"] = false
	m.poblenou_tray = st


static func idle_status(m: Node2D) -> String:
	var st := String(m.poblenou_tray.get("state", "idle"))
	if st == "warn":
		return I18n.t("poblenou_tray_warn")
	return ""


# --- draw helpers -------------------------------------------------------------

static func _rec_valid() -> void:
	var key := [Game.weather, Game.hour, snappedf(CityRoofs._glow(), 0.1), Shade.throw]
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


static func _edge_x(y: float, side: float) -> float:
	var e := _edges_at(y)
	return e.x if side < 0.0 else e.y


static func _corridor(wc: ShapeBatch, y0: float, y1: float, col: Color, inset := 0.0) -> void:
	var y := y0
	var ea := _edges_at(y)
	while y < y1:
		var yn := minf(y + 20.0, y1)
		var eb := _edges_at(yn)
		wc.quad(Vector2(ea.x + inset, y), Vector2(ea.y - inset, y), Vector2(eb.y - inset, yn), Vector2(eb.x + inset, yn), col)
		ea = eb
		y = yn


static func _outside(b: ShapeBatch, side: float, y0: float, y1: float, col: Color) -> void:
	var far := FAR_L if side < 0.0 else FAR_R
	var y := y0
	var xa := _edge_x(y, side)
	while y < y1:
		var yn := minf(y + 20.0, y1)
		var xb := _edge_x(yn, side)
		b.quad(Vector2(xa, y), Vector2(far, y), Vector2(far, yn), Vector2(xb, yn), col)
		xa = xb
		y = yn


# --- edge layer (roofs & Plaça de Prim white cottages) -----------------------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 60.0, GATE - 60.0)
	var hi := minf(vb + 60.0, START + 760.0)
	if hi > lo:
		for side: float in SIDES:
			_outside(b, side, lo, hi, Color(0.22, 0.20, 0.21))
		var seg := 220.0
		var s0 := int(floorf(lo / seg))
		var s1 := int(floorf(hi / seg))
		for s in range(s0, s1 + 1):
			var ya := maxf(float(s) * seg, GATE - 40.0)
			var yb := minf(float(s + 1) * seg, START + 760.0)
			if yb <= ya:
				continue
			var ym := (ya + yb) * 0.5
			var tone := "white" if (ym <= PRIM_START and ym >= PRIM_END) else ""
			for side: float in SIDES:
				var ex := _edge_x(ym, side)
				var far := absf((FAR_L if side < 0.0 else FAR_R) - ex)
				b.rect(Rect2(ex if side > 0.0 else (ex - FACE), ya, FACE, yb - ya),
					Color(0.92, 0.90, 0.85) if tone == "white" else Color(0.82, 0.75, 0.65))
				CityRoofs.kept_module(b, ex + side * FACE, side, far, ya, yb, 7100 + s * 2 + (1 if side > 0.0 else 0), tone)
	b.lod = keep_lod


# --- ground & props -----------------------------------------------------------

static func draw_cross_section(_m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, _ctop: float, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 30.0, GATE - 40.0)
	var hi := vb + 30.0
	var c0 := int(floorf(lo / CHUNK))
	var c1 := int(floorf(hi / CHUNK))
	for c in range(c0, c1 + 1):
		_cached(wc, ["pave", c], _pave_chunk.bind(float(c) * CHUNK, float(c + 1) * CHUNK))
	for k in KIOSKS:
		var pos: Vector2 = k[0]
		if pos.y > lo - 70.0 and pos.y < hi + 70.0:
			_cached(wc, ["kiosk", pos.x, pos.y], _draw_kiosk.bind(pos, String(k[1])))
	for pr: Rect2 in PRIM_PLANTERS:
		if pr.end.y > lo - 40.0 and pr.position.y < hi + 40.0:
			_cached(wc, ["planter", pr.position.x, pr.position.y], _draw_planter.bind(pr))
	if FACTORY_PLINTH.end.y > lo - 40.0 and FACTORY_PLINTH.position.y < hi + 40.0:
		_cached(wc, ["chimney"], _draw_chimney_plinth)
	if lo < HORCHATA_START and hi > HORCHATA_END:
		if Outdoors.terrace_patrons(Game.weather, Game.hour):
			_cached(wc, ["terraces"], _draw_horchata_terraces)
	wc.lod = keep_lod


static func _pave_chunk(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var mid := (a + z) * 0.5
	var in_prim := mid <= PRIM_START and mid >= PRIM_END
	var base := PRIM_COB if in_prim else PAVE_WARM
	_corridor(wc, a, z, base)
	# central sunlit boulevard strip
	var cw := 156.0 if not in_prim else 190.0
	wc.rect(Rect2(CX - cw * 0.5, a, cw, z - a), PRIM_LIGHT if in_prim else PAVE_CENTER)
	wc.line(Vector2(CX - cw * 0.5, a), Vector2(CX - cw * 0.5, z), PAVE_KERB, 2.5)
	wc.line(Vector2(CX + cw * 0.5, a), Vector2(CX + cw * 0.5, z), PAVE_KERB, 2.5)
	var ry := floorf(a / Panot.FLOR) * Panot.FLOR
	while ry < z:
		var e := _edges_at(ry + Panot.FLOR * 0.5)
		Panot.flor_row(wc, e.x + 8.0, e.y - 8.0, ry, e.x + 8.0, PANOT_INK, PANOT_SHINE)
		ry += Panot.FLOR
	# Plaça de Prim compass inlay
	if a <= -3240.0 and z >= -3340.0:
		var cc := Vector2(CX, -3290.0)
		wc.circle(cc, 46.0, Color(0.56, 0.50, 0.44))
		wc.circle(cc, 38.0, PAVE_CENTER)
		for k in range(4):
			var ang := float(k) * PI * 0.5
			var tip := cc + Vector2.from_angle(ang) * 34.0
			var side := Vector2.from_angle(ang + PI * 0.5) * 9.0
			wc.polygon(PackedVector2Array([cc + side, tip, cc - side]), Color(0.20, 0.44, 0.46) if k % 2 == 0 else BRICK)


static func _draw_kiosk(wc: ShapeBatch, pos: Vector2, kind: String) -> void:
	var r := Rect2(pos.x - 36.0, pos.y - 22.0, 72.0, 44.0)
	wc.rect(Rect2(r.position + Vector2(6.0, 7.0), r.size), SHADOW)
	wc.rect(r, WOOD)
	var top := r.grow(-3.0)
	match kind:
		"horchata":
			wc.rect(top, HORCHATA_COL)
			for i in range(6):
				var stripe_c := HORCHATA_STRIPE if i % 2 == 0 else HORCHATA_COL
				wc.rect(Rect2(top.position.x + float(i) * 11.0, top.position.y, 11.0, top.size.y * 0.55), stripe_c)
			# white glazed counter + twin copper/wooden horchata tubs
			wc.rect(Rect2(top.position.x + 4.0, top.position.y + 22.0, top.size.x - 8.0, 14.0), Color(0.95, 0.94, 0.90))
			for ti in range(2):
				var tp := Vector2(top.position.x + 18.0 + float(ti) * 30.0, top.position.y + 29.0)
				wc.circle(tp, 6.2, Color(0.46, 0.30, 0.16))
				wc.circle(tp, 4.4, HORCHATA_COL)
		"flowers":
			wc.rect(top, Color(0.92, 0.88, 0.78))
			wc.rect(Rect2(top.position.x, top.position.y, top.size.x, 18.0), Color(0.24, 0.48, 0.32))
			for j in range(4):
				var fp := Vector2(top.position.x + 11.0 + float(j) * 15.0, top.position.y + 28.0)
				wc.circle(fp, 5.5, FLOWER_CORAL if j % 2 == 0 else FLOWER_SAFFRON)
				wc.circle(fp, 2.2, Color(0.98, 0.96, 0.88))
		"pastry":
			wc.rect(top, Color(0.92, 0.76, 0.52))
			for i in range(5):
				wc.rect(Rect2(top.position.x + float(i) * 13.2, top.position.y, 13.2, 18.0),
					Color(0.84, 0.30, 0.26) if i % 2 == 0 else Color(0.96, 0.92, 0.84))
			for k in range(3):
				wc.capsule(Vector2(top.position.x + 10.0 + float(k) * 18.0, top.position.y + 28.0),
					Vector2(top.position.x + 20.0 + float(k) * 18.0, top.position.y + 28.0), 3.0, Color(0.76, 0.54, 0.26))
		"books":
			wc.rect(top, Color(0.32, 0.38, 0.46))
			wc.rect(Rect2(top.position.x + 4.0, top.position.y + 20.0, top.size.x - 8.0, 15.0), Color(0.78, 0.72, 0.58))
			for b in range(5):
				var bp := Rect2(top.position.x + 7.0 + float(b) * 11.0, top.position.y + 22.0, 8.0, 11.0)
				wc.rect(bp, [FLOWER_CORAL, FLOWER_TEAL, FLOWER_SAFFRON, Color(0.94, 0.92, 0.88)][b % 4])
		"gelato":
			wc.rect(top, Color(0.95, 0.93, 0.90))
			for i in range(6):
				wc.rect(Rect2(top.position.x + float(i) * 11.0, top.position.y, 11.0, 18.0),
					Color(0.24, 0.62, 0.78) if i % 2 == 0 else Color(0.96, 0.86, 0.34))
			for j in range(4):
				var gp := Vector2(top.position.x + 12.0 + float(j) * 14.0, top.position.y + 28.0)
				wc.circle(gp, 5.0, [Color(0.96, 0.62, 0.68), Color(0.96, 0.90, 0.66), Color(0.56, 0.34, 0.20), Color(0.68, 0.86, 0.54)][j])


static func _draw_planter(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Vector2(5.0, 6.0), r.size), SHADOW)
	wc.rect(r, PLANTER_STONE)
	wc.rect(r.grow(-4.0), PLANTER_SOIL)
	var c := r.get_center()
	for i in range(5):
		var fp := c + Vector2(float(i - 2) * 10.0, (-6.0 if i % 2 == 0 else 6.0))
		wc.circle(fp, 7.0, FLOWER_TEAL)
		wc.circle(fp + Vector2(-1.5, -1.5), 3.4, FLOWER_CORAL if i % 2 == 0 else FLOWER_SAFFRON)


static func _draw_chimney_plinth(wc: ShapeBatch) -> void:
	var r := FACTORY_PLINTH
	wc.rect(Rect2(r.position + Vector2(7.0, 9.0), r.size), SHADOW)
	wc.rect(r, BRICK_DK)
	wc.rect(r.grow(-4.0), BRICK)
	var c := r.get_center()
	wc.circle(c, 19.0, BRICK_DK)
	wc.circle(c, 15.0, BRICK)
	wc.circle(c, 9.0, Color(0.16, 0.14, 0.14))


static func _draw_horchata_terraces(wc: ShapeBatch) -> void:
	for ty: float in [-1320.0, -1780.0, -2260.0]:
		var tx := 534.0 if ty != -1780.0 else 746.0
		var p := Vector2(tx, ty)
		wc.circle(p + Vector2(3.0, 4.0), 13.0, SHADOW)
		wc.circle(p, 12.0, Color(0.94, 0.92, 0.88))
		wc.circle(p + Vector2(-2.0, -2.0), 4.0, HORCHATA_COL)
		wc.circle(p + Vector2(3.0, 2.0), 2.5, HORCHATA_STRIPE)


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(STREET_LAMPS, p):
		wc.circle(p + Vector2(3.0, 4.0), 8.5, SHADOW)
		wc.circle(p, 8.5, IRON)
		wc.circle(p + Vector2(-1.5, -1.5), 4.2, Color(0.42, 0.44, 0.48))
		return
	if _is_in(PILONES, p):
		wc.circle(p + Vector2(2.5, 3.0), 8.0, SHADOW)
		wc.circle(p, 8.0, IRON)
		wc.circle(p + Vector2(-2.0, -2.0), 3.0, Color(0.40, 0.40, 0.44))


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# crisp golden farton on wax paper
	wc.polygon(PackedVector2Array([kp + Vector2(-8, -5), kp + Vector2(7, -6), kp + Vector2(8, 5), kp + Vector2(-7, 6)]), Color(0.96, 0.94, 0.88))
	wc.capsule(kp + Vector2(-5.5, 0.5), kp + Vector2(5.5, -0.5), 2.8, Color(0.84, 0.62, 0.30))
	wc.capsule(kp + Vector2(-4.0, -0.5), kp + Vector2(4.0, -1.2), 1.4, Color(0.98, 0.96, 0.92))


# --- live pass & overhead -----------------------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var t := float(AnimClock.msec()) * 0.001
	# waiters at WAITER_SPOTS
	for i in range(WAITER_SPOTS.size()):
		var wp: Vector2 = WAITER_SPOTS[i]
		if wp.y < vt - 40.0 or wp.y > vb + 40.0:
			continue
		var dir := Vector2(1.0 if wp.x < CX else -1.0, 0.25).normalized()
		NpcFigure.person(wc, wp, dir, 6100 + i, -1.0, {
			"top": HORCHATA_COL,
			"arms": NpcFigure.Arms.READY,
		})
		# silver tray in hand
		var st: Dictionary = m.poblenou_tray
		var active_waiter := String(st.get("state", "idle")) == "warn" and wp.distance_to(st.get("waiter", Vector2.ZERO)) < 8.0
		var wobble := sin(t * 26.0) * 5.0 if active_waiter else 0.0
		var tray_p := wp + dir * 13.0 + Vector2(wobble, 0.0)
		wc.circle(tray_p, 7.5, Color(0.80, 0.82, 0.86))
		wc.circle(tray_p + Vector2(-2.0, -1.5), 2.5, HORCHATA_COL)
		wc.circle(tray_p + Vector2(2.5, 1.5), 2.5, HORCHATA_COL)
	# active horchata tray warning ring or spill + dropped farton
	var tray: Dictionary = m.poblenou_tray
	var tstate := String(tray.get("state", "idle"))
	if tstate == "warn":
		var tgt: Vector2 = tray.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var frac := clampf(1.0 - float(tray.get("t", 0.0)) / TRAY_WARN, 0.0, 1.0)
			wc.glow(tgt, TRAY_SPLASH_R * (0.55 + 0.45 * frac), Color(0.96, 0.93, 0.84, 0.34))
			wc.arc(tgt, TRAY_SPLASH_R, 0.0, TAU * frac, 24, HORCHATA_STRIPE, 3.0)
	elif tstate == "spill":
		var tgt: Vector2 = tray.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var fade := clampf(float(tray.get("t", 0.0)) / TRAY_SPILL_LIFE, 0.25, 1.0)
			wc.glow(tgt, TRAY_SPLASH_R * 0.95, Color(HORCHATA_COL.r, HORCHATA_COL.g, HORCHATA_COL.b, 0.55 * fade))
			for j in range(5):
				var drop := tgt + Vector2.from_angle(float(j) * 1.25 + 0.4) * (18.0 + float(j % 2) * 14.0)
				wc.circle(drop, 6.0, Color(HORCHATA_COL.r, HORCHATA_COL.g, HORCHATA_COL.b, 0.65 * fade))
		if bool(tray.get("farton_active", false)):
			var fp: Vector2 = tray.get("farton", Vector2.ZERO)
			if fp.y > vt - 30.0 and fp.y < vb + 30.0:
				wc.glow(fp, 18.0, Color(1.0, 0.88, 0.42, 0.32))
				wc.capsule(fp + Vector2(-7.0, 0.5), fp + Vector2(7.0, -0.5), 3.4, Color(0.86, 0.64, 0.30))
				wc.capsule(fp + Vector2(-5.0, -0.5), fp + Vector2(5.0, -1.2), 1.6, Color(0.98, 0.96, 0.92))
	# casual strollers on the Rambla
	var span := UPPER_END - HORCHATA_END
	for k in range(Outdoors.crowd_here(5, 2)):
		var dir := -1.0 if k % 2 == 0 else 1.0
		var off := fposmod(_h(k * 17) * span + t * 24.0 * (0.85 + _h(k * 7) * 0.3), span)
		var sy := (UPPER_END - off) if dir < 0.0 else (HORCHATA_END + off)
		if sy < vt - 30.0 or sy > vb + 30.0:
			continue
		var sx := CX - 42.0 if k % 2 == 0 else CX + 42.0
		NpcFigure.person(wc, Vector2(sx + sin(t * 0.7 + float(k)) * 8.0, sy), Vector2(0.0, dir), 6200 + k, t * 5.6 + float(k), {})
	wc.lod = keep_lod


static func draw_overhead(_m: Node2D, ci: Object) -> void:
	# sea breeze ribbons drifting westward across the sunlit rambla
	if Game.wind_amount() < 0.2:
		return
	var b: ShapeBatch = ci if ci is ShapeBatch else null
	if b == null:
		return
	var t := float(AnimClock.msec()) * 0.001
	for i in range(4):
		var x := CX - 180.0 + fposmod(t * 48.0 + float(i) * 140.0, 420.0)
		var y := -1200.0 - float(i) * 850.0
		b.line(Vector2(x, y), Vector2(x - 36.0, y + 6.0), Color(1.0, 1.0, 1.0, 0.14), 1.4)


static func draw_freedom(m: Node2D, c: Object) -> void:
	# Plaça del Poblenou: sunlit flagstones, panots, palm-ringed fountain, house fronts
	m._draw_freedom_beyond(c)
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	b.rect(r, PRIM_COB)
	Panot.flor(b, r.position.x + 12.0, r.end.x - 12.0, r.position.y + 12.0, r.end.y - 12.0, PANOT_INK, PANOT_SHINE)
	b.circle(r.get_center() + Vector2(-40.0, 20.0), 74.0, Color(HORCHATA_STRIPE.r, HORCHATA_STRIPE.g, HORCHATA_STRIPE.b, 0.14))
	# stone basin matching LevelBuild.placa_fountain
	var fr: Rect2 = Rect2(Vector2(825.0, float(m.GATE_Y) - 470.0), Vector2(150.0, 96.0))
	b.rect(fr.grow(10.0), PLANTER_STONE)
	b.rect(fr, Color(0.28, 0.50, 0.58))
	b.circle(fr.get_center(), 10.0, PLANTER_STONE.lightened(0.08))
	b.circle(fr.get_center(), 4.5, Color(0.84, 0.94, 0.98))
	b.flush(c)
	for t: Vector2 in m.trees:
		c.draw_rect(Rect2(t - Vector2(20.0, 20.0), Vector2(40.0, 40.0)), Color(0.36, 0.28, 0.20))
		c.draw_rect(Rect2(t - Vector2(20.0, 20.0), Vector2(40.0, 40.0)), Color(0.30, 0.30, 0.32), false, 2.0)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_poblenou_freedom"))


# --- after dark ---------------------------------------------------------------

static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	for k in KIOSKS:
		var p: Vector2 = k[0]
		out.append(Vector3(p.x, p.y, 130.0))
	return out


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	return NightFronts.along_edges(m, START, GATE, 220.0, 0.0, 6100)
