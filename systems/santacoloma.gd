class_name SantaColoma
extends RefCounted

# WALK: SANTA COLOMA — steep hillside streets, Mercat del Fondo & domino plazas.
#
# Up the screen:
# - Besòs Bridgehead Climb (260..-950): sunlit slope chevrons rising off the
#   riverbank between terracotta balconies and tiled apartment bays.
# - Mercat del Fondo & Barber Street (-950..-2600): spice sacks, tropical fruit,
#   empanada bakeries, striped barber poles, and laundry strung overhead.
# - Plaça del Rellotge (-2600..-3950): wide tile square centred on the glazed
#   clock tower plinth and shaded neighborhood domino tables.
# - Hillside Terrace Lead-Out (-3950..-5000): terraced steps rising cleanly
#   into Mirador del Fondo off leash.
#
# Signature live event: a domino elder hoists the winning double-six for 1.0 s
# ("Capicua!" + pulsing chalk ring) before slamming it down and rattling the
# flagstones. Pull clear to score a clean dodge; bark by the clock tower for a
# neighborhood chime.

const HOOKS := [
	"draw_bollard",
	"draw_column",
	"draw_cross_section",
	"draw_edge_layer",
	"draw_live",
	"draw_overhead",
	"draw_snack",
	"draw_yard",
	"idle_status",
	"is_lamp",
	"night_fronts",
	"night_lights",
	"on_bark",
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
const HILL_END := -950.0
const FONDO_START := -1150.0
const FONDO_END := -2600.0
const RELLOTGE_START := -2800.0
const RELLOTGE_END := -3950.0
const TERRACE_START := -4150.0

# --- colours ------------------------------------------------------------------
const PAVE_WARM := Color(0.75, 0.70, 0.64)
const PAVE_TILE := Color(0.84, 0.77, 0.66)
const PAVE_KERB := Color(0.54, 0.48, 0.43)
const PANOT_INK := Color(0.18, 0.14, 0.10, 0.14)
const PANOT_SHINE := Color(1.0, 0.96, 0.88, 0.10)
const SAFFRON := Color(0.95, 0.72, 0.18)
const PAPRIKA := Color(0.84, 0.28, 0.22)
const MINT := Color(0.18, 0.62, 0.50)
const BAIZE := Color(0.16, 0.44, 0.28)
const WOOD := Color(0.48, 0.31, 0.18)
const WOOD_LT := Color(0.66, 0.45, 0.28)
const STONE := Color(0.74, 0.71, 0.65)
const STONE_DK := Color(0.50, 0.47, 0.43)
const SHADOW := Color(0.06, 0.07, 0.11, 0.26)
const IRON := Color(0.18, 0.19, 0.22)

# --- landmarks & props --------------------------------------------------------
const DARE_POS := Vector2(730.0, -1960.0)
const PRIZE := Vector2(525.0, -1380.0)
const PRIZE_TEXT := "nab an empanada from El Fondo market"

const SPICE_STALLS: Array = [
	[Vector2(475.0, -1380.0), "spices"],
	[Vector2(805.0, -1720.0), "bakery"],
	[Vector2(475.0, -2060.0), "produce"],
	[Vector2(805.0, -2400.0), "tea"],
]

const CLOCK_PLINTH := Rect2(438.0, -3380.0, 64.0, 64.0)

const DOMINO_TABLES: Array[Rect2] = [
	Rect2(790.0, -3100.0, 52.0, 44.0),
	Rect2(790.0, -3620.0, 52.0, 44.0),
]

const BARBER_POLES: Array[Vector2] = [
	Vector2(455.0, -1540.0),
	Vector2(825.0, -2200.0),
	Vector2(455.0, -4420.0),
]

const TREES: Array[Vector2] = [
	Vector2(465.0, -200.0), Vector2(815.0, -200.0),
	Vector2(465.0, -660.0), Vector2(815.0, -660.0),
	Vector2(440.0, -4320.0), Vector2(840.0, -4320.0),
	Vector2(440.0, -4780.0), Vector2(840.0, -4780.0),
]

const LAMPS: Array[Vector2] = [
	Vector2(465.0, -420.0), Vector2(815.0, -840.0),
	Vector2(425.0, -1240.0), Vector2(855.0, -1880.0),
	Vector2(425.0, -2480.0), Vector2(860.0, -3340.0),
	Vector2(445.0, -4120.0), Vector2(835.0, -4620.0),
]

const PILONES: Array[Vector2] = [
	Vector2(540.0, -1000.0), Vector2(740.0, -1000.0),
	Vector2(540.0, -2640.0), Vector2(740.0, -2640.0),
]

const BINS: Array[Vector2] = [
	Vector2(475.0, -540.0), Vector2(845.0, -1500.0),
	Vector2(435.0, -2280.0), Vector2(885.0, -2960.0),
	Vector2(465.0, -4680.0),
]

const FOUNTAINS: Array[Vector2] = [
	Vector2(420.0, -3780.0),
]

# --- domino slam live event ---------------------------------------------------
const DOMINO_WARN := 1.0
const DOMINO_R := 64.0
const DOMINO_LIFE := 4.5
const DOMINO_COOLDOWN := 7.0
const DOMINO_SPOTS: Array[Vector2] = [
	Vector2(552.0, -1660.0),
	Vector2(746.0, -3078.0),
	Vector2(746.0, -3598.0),
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
		{"y": START, "cx": CX, "half": 210.0},
		{"y": HILL_END, "cx": CX, "half": 210.0},
		{"y": FONDO_START, "cx": CX, "half": 245.0},
		{"y": FONDO_END, "cx": CX, "half": 245.0},
		{"y": RELLOTGE_START, "cx": CX, "half": HALF},
		{"y": RELLOTGE_END, "cx": CX, "half": HALF},
		{"y": TERRACE_START, "cx": CX, "half": 225.0},
		{"y": GATE, "cx": CX, "half": 225.0},
	]


static func _edges_at(y: float) -> Vector2:
	if _nodes.is_empty():
		_nodes = edge_nodes()
	return EdgePath.edges(_nodes, y, CX, HALF)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for s: Array in SPICE_STALLS:
		var pos: Vector2 = s[0]
		out.append(Rect2(pos.x - 36.0, pos.y - 22.0, 72.0, 44.0))
	out.append(CLOCK_PLINTH)
	out.append_array(DOMINO_TABLES)
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = solids(m)
	for lp: Vector2 in LAMPS:
		out.append(Rect2(lp.x - 10.0, lp.y - 10.0, 20.0, 20.0))
	for bp: Vector2 in BARBER_POLES:
		out.append(Rect2(bp.x - 9.0, bp.y - 9.0, 18.0, 18.0))
	return out


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(TREES, p):
		return m.TREE_PALM
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(LAMPS, p)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return -1
	var e := _edges_at(p.y)
	if p.x >= e.x - 8.0 and p.x <= e.y + 8.0:
		return Surfaces.S.PAVEMENT
	return Surfaces.S.GRASS


# --- build --------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "MIRADOR DEL FONDO"
	m.gate_l = 420.0
	m.gate_r = 860.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([
		Vector2(600.0, -480.0), Vector2(680.0, -880.0),
		Vector2(580.0, -1820.0), Vector2(680.0, -2460.0),
		Vector2(620.0, -3520.0), Vector2(660.0, -4560.0),
	], TYPE_VECTOR2, &"", null)
	m.fountains = Array(FOUNTAINS.duplicate(), TYPE_VECTOR2, &"", null)

	m.santacoloma_domino = {
		"state": "idle", "idx": 0, "t": 1.2,
		"spot": DOMINO_SPOTS[0], "target": DOMINO_SPOTS[0] + Vector2(38.0, 18.0),
		"hit": false,
	}
	m.santacoloma_slams_dodged = 0
	m.santacoloma_spices_sniffed = {}
	m.santacoloma_poles_marked = {}
	m.santacoloma_clock_barked = false

	for t: Vector2 in TREES:
		m.poles.append(t)
	for lp: Vector2 in LAMPS:
		m.poles.append(lp)
	for bp: Vector2 in BARBER_POLES:
		m.poles.append(bp)
	for pl: Vector2 in PILONES:
		m.poles.append(pl)
	m.deco_pole_count = m.poles.size()

	m.bins = Array(BINS.duplicate(), TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(465.0, -320.0), Vector2(845.0, -1580.0),
		Vector2(430.0, -1880.0), Vector2(395.0, -3100.0),
		Vector2(880.0, -3840.0), Vector2(455.0, -4560.0),
	], TYPE_VECTOR2, &"", null)

	var marks: Array[Vector2] = []
	for bp: Vector2 in BARBER_POLES:
		marks.append(bp)
	for pl: Vector2 in PILONES:
		marks.append(pl)
	for i in range(4):
		marks.append(LAMPS[i * 2])

	var snacks: Array[Vector2] = [
		Vector2(590.0, -600.0), Vector2(670.0, -1480.0),
		Vector2(590.0, -2200.0), Vector2(640.0, -3340.0),
		Vector2(600.0, -4460.0),
	]
	return [marks, snacks]


# --- tick & bark --------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	_tick_poles(m)
	_tick_spices(m, dp)
	_tick_domino(m, delta, dp, hp)


static func _tick_poles(m: Node2D) -> void:
	for i in range(BARBER_POLES.size()):
		if m.santacoloma_poles_marked.has(i):
			continue
		var bp: Vector2 = BARBER_POLES[i]
		for spot: Vector2 in m.marks:
			if spot.distance_to(bp) < 38.0:
				m.santacoloma_poles_marked[i] = true
				break


static func _tick_spices(m: Node2D, dp: Vector2) -> void:
	for i in range(SPICE_STALLS.size()):
		if m.santacoloma_spices_sniffed.has(i):
			continue
		var pos: Vector2 = SPICE_STALLS[i][0]
		if dp.distance_to(pos) < 62.0 and m.dog.velocity.length() < 95.0:
			m.santacoloma_spices_sniffed[i] = true
			m.award_points(1, I18n.t("w_fondo_spice_1"))
			Sfx.play("rustle", 1.05)


static func _tick_domino(m: Node2D, delta: float, dp: Vector2, hp: Vector2) -> void:
	var st: Dictionary = m.santacoloma_domino
	if st.is_empty():
		return
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))

	match state:
		"idle":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				for i in range(DOMINO_SPOTS.size()):
					var sp: Vector2 = DOMINO_SPOTS[i]
					if dp.distance_to(sp) < 280.0 and i >= int(st.get("idx", 0)):
						var step_dir := Vector2(1.0 if sp.x < CX else -1.0, 0.15).normalized()
						var tgt := dp if dp.distance_to(sp) < 160.0 else (sp + step_dir * 66.0)
						var e := _edges_at(tgt.y)
						tgt.x = clampf(tgt.x, e.x + 56.0, e.y - 56.0)
						st["state"] = "warn"
						st["idx"] = i + 1
						st["t"] = DOMINO_WARN
						st["spot"] = sp
						st["target"] = tgt
						st["hit"] = false
						m.float_text(sp + Vector2(0.0, -34.0), I18n.t("w_capicua"), SAFFRON, m.POP_SAY)
						m.feed.say(I18n.t("w_domino_slam_coming"), EventFeed.Tone.LOUD)
						Sfx.play("count", 1.15)
						break
		"warn":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				var tgt: Vector2 = st["target"]
				st["state"] = "slam"
				st["t"] = DOMINO_LIFE
				Sfx.play("crack", 0.9)
				var hit_dog := dp.distance_to(tgt) < DOMINO_R
				var hit_human := hp.distance_to(tgt) < DOMINO_R * 0.9
				if hit_dog or hit_human:
					st["hit"] = true
					m.bones = maxi(0, m.bones - 2)
					m.shake_t = maxf(float(m.shake_t), 0.35)
					m.float_text(tgt, I18n.t("w_domino_scatter"), PAPRIKA)
					m.feed.say(I18n.t("w_dominoes_flew_everywhere"), EventFeed.Tone.BAD)
					m._update_hud()
				else:
					m.santacoloma_slams_dodged += 1
					m.award_points(4, I18n.t("w_domino_dodge_4"))
					if m.combo != null:
						m.combo.add("SAVE", 4)
					m.feed.say(I18n.t("w_domino_dodged_clean"), EventFeed.Tone.GOOD)
		"slam":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				st["state"] = "idle"
				st["t"] = DOMINO_COOLDOWN
	m.santacoloma_domino = st


static func idle_status(m: Node2D) -> String:
	if String(m.santacoloma_domino.get("state", "idle")) == "warn":
		return I18n.t("santacoloma_domino_warn")
	return ""


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	if not bool(m.santacoloma_clock_barked):
		if p.distance_to(CLOCK_PLINTH.get_center()) < 165.0:
			m.santacoloma_clock_barked = true
			m.award_points(2, I18n.t("w_clock_chime_2"))
			m.float_text(CLOCK_PLINTH.get_center() + Vector2(0.0, -34.0), I18n.t("w_rellotge_ding_dong"), SAFFRON, m.POP_SAY)
			Sfx.play("church_bell", 1.1)
			return true
	return false


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


# --- edge layer (dense hillside blocks & rooftop balconies) -------------------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 60.0, GATE - 60.0)
	var hi := minf(vb + 60.0, START + 760.0)
	if hi > lo:
		for side: float in SIDES:
			_outside(b, side, lo, hi, Color(0.24, 0.21, 0.20))
		var seg := 220.0
		var s0 := int(floorf(lo / seg))
		var s1 := int(floorf(hi / seg))
		for s in range(s0, s1 + 1):
			var ya := maxf(float(s) * seg, GATE - 40.0)
			var yb := minf(float(s + 1) * seg, START + 760.0)
			if yb <= ya:
				continue
			var ym := (ya + yb) * 0.5
			for side: float in SIDES:
				var ex := _edge_x(ym, side)
				var far := absf((FAR_L if side < 0.0 else FAR_R) - ex)
				b.rect(Rect2(ex if side > 0.0 else (ex - FACE), ya, FACE, yb - ya), Color(0.84, 0.72, 0.58))
				CityRoofs.kept_module(b, ex + side * FACE, side, far, ya, yb, 9100 + s * 2 + (1 if side > 0.0 else 0))
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
	for s in SPICE_STALLS:
		var pos: Vector2 = s[0]
		if pos.y > lo - 70.0 and pos.y < hi + 70.0:
			_cached(wc, ["stall", pos.x, pos.y], _draw_spice_stall.bind(pos, String(s[1])))
	if CLOCK_PLINTH.end.y > lo - 50.0 and CLOCK_PLINTH.position.y < hi + 50.0:
		_cached(wc, ["clock"], _draw_clock_plinth)
	for i in range(DOMINO_TABLES.size()):
		var r: Rect2 = DOMINO_TABLES[i]
		if r.end.y > lo - 40.0 and r.position.y < hi + 40.0:
			_cached(wc, ["domino", i], _draw_domino_table.bind(r))
	wc.lod = keep_lod


static func _pave_chunk(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var mid := (a + z) * 0.5
	var in_rellotge := mid <= RELLOTGE_START and mid >= RELLOTGE_END
	var base := PAVE_TILE if in_rellotge else PAVE_WARM
	_corridor(wc, a, z, base)
	# hillside gradient chevrons on bottom climb and top steps
	if mid >= HILL_END or mid <= TERRACE_START:
		var sy := floorf(a / 84.0) * 84.0
		while sy < z:
			if sy > a:
				var e := _edges_at(sy)
				wc.line(Vector2(e.x + 28.0, sy + 14.0), Vector2(CX, sy), PAVE_KERB, 2.2)
				wc.line(Vector2(CX, sy), Vector2(e.y - 28.0, sy + 14.0), PAVE_KERB, 2.2)
			sy += 84.0
	var ry := floorf(a / Panot.FLOR) * Panot.FLOR
	while ry < z:
		var e := _edges_at(ry + Panot.FLOR * 0.5)
		Panot.flor_row(wc, e.x + 8.0, e.y - 8.0, ry, e.x + 8.0, PANOT_INK, PANOT_SHINE)
		ry += Panot.FLOR
	# sunburst tile inlay in Plaça del Rellotge
	if a <= -3280.0 and z >= -3420.0:
		var cc := Vector2(CX, -3350.0)
		wc.circle(cc, 46.0, STONE_DK)
		wc.circle(cc, 38.0, PAVE_TILE)
		for h_i in range(12):
			var tip := cc + Vector2.from_angle(float(h_i) * TAU / 12.0) * 34.0
			wc.line(cc, tip, SAFFRON if h_i % 3 == 0 else MINT, 2.4)


static func _draw_spice_stall(wc: ShapeBatch, pos: Vector2, kind: String) -> void:
	var r := Rect2(pos.x - 36.0, pos.y - 22.0, 72.0, 44.0)
	wc.rect(Rect2(r.position + Vector2(6.0, 7.0), r.size), SHADOW)
	wc.rect(r, WOOD)
	var top := r.grow(-3.0)
	wc.rect(top, Color(0.94, 0.90, 0.80))
	for i in range(6):
		var sc := PAPRIKA if i % 2 == 0 else SAFFRON
		if kind == "tea":
			sc = MINT if i % 2 == 0 else Color(0.96, 0.92, 0.82)
		wc.rect(Rect2(top.position.x + float(i) * 11.0, top.position.y, 11.0, 17.0), sc)
	match kind:
		"spices":
			var cols := [SAFFRON, PAPRIKA, Color(0.66, 0.44, 0.14), MINT]
			for b in range(4):
				var sp := Vector2(top.position.x + 11.0 + float(b) * 15.0, top.position.y + 28.0)
				wc.circle(sp, 5.8, IRON)
				wc.circle(sp, 4.4, cols[b])
		"bakery":
			for b in range(4):
				var bp := Vector2(top.position.x + 11.0 + float(b) * 15.0, top.position.y + 28.0)
				wc.capsule(bp + Vector2(-4.0, 1.0), bp + Vector2(4.0, -1.0), 3.0, Color(0.84, 0.54, 0.22))
		"produce":
			var cols := [SAFFRON, PAPRIKA, Color(0.28, 0.62, 0.22), Color(0.92, 0.44, 0.22)]
			for b in range(4):
				var pp := Vector2(top.position.x + 11.0 + float(b) * 15.0, top.position.y + 28.0)
				wc.circle(pp, 5.5, cols[b])
		"tea":
			for b in range(3):
				var tp := Vector2(top.position.x + 14.0 + float(b) * 19.0, top.position.y + 28.0)
				wc.circle(tp, 5.5, Color(0.76, 0.78, 0.82))
				wc.circle(tp, 3.4, MINT)


static func _draw_clock_plinth(wc: ShapeBatch) -> void:
	var r := CLOCK_PLINTH
	wc.rect(Rect2(r.position + Vector2(8.0, 10.0), r.size), SHADOW)
	wc.rect(r, STONE_DK)
	wc.rect(r.grow(-4.0), STONE)
	var c := r.get_center()
	wc.circle(c, 21.0, Color(0.86, 0.72, 0.34))
	wc.circle(c, 17.0, Color(0.96, 0.94, 0.88))
	wc.line(c, c + Vector2(0.0, -11.0), IRON, 2.4)
	wc.line(c, c + Vector2(9.0, 4.0), IRON, 2.0)
	wc.circle(c, 3.0, PAPRIKA)


static func _draw_domino_table(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Vector2(5.0, 6.0), r.size), SHADOW)
	wc.rect(r, WOOD)
	wc.rect(r.grow(-4.0), BAIZE)
	var c := r.get_center()
	for i in range(4):
		var tp := c + Vector2(float(i - 1.5) * 9.0, (-4.0 if i % 2 == 0 else 4.0))
		wc.rect(Rect2(tp - Vector2(3.5, 5.5), Vector2(7.0, 11.0)), Color(0.96, 0.95, 0.92))
		wc.circle(tp + Vector2(0.0, -2.5), 1.0, IRON)
		wc.circle(tp + Vector2(0.0, 2.5), 1.0, IRON)


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(LAMPS, p):
		wc.circle(p + Vector2(3.0, 4.0), 8.5, SHADOW)
		wc.circle(p, 8.5, IRON)
		wc.circle(p + Vector2(-1.5, -1.5), 4.2, SAFFRON)
		return
	if _is_in(BARBER_POLES, p):
		var spin := float(AnimClock.msec()) * 0.005
		wc.circle(p + Vector2(3.0, 4.0), 9.0, SHADOW)
		wc.circle(p, 9.0, IRON)
		wc.circle(p, 7.2, Color(0.96, 0.96, 0.98))
		wc.arc(p, 6.5, spin, spin + PI * 0.65, 8, PAPRIKA, 3.6)
		wc.arc(p, 6.5, spin + PI, spin + PI * 1.65, 8, Color(0.18, 0.38, 0.78), 3.6)
		return
	if _is_in(PILONES, p):
		wc.circle(p + Vector2(2.5, 3.0), 8.0, SHADOW)
		wc.circle(p, 8.0, IRON)
		wc.circle(p, 3.8, SAFFRON)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# warm folded empanada with crimped golden crust
	wc.circle(kp + Vector2(1.0, 1.5), 7.5, SHADOW)
	wc.arc(kp + Vector2(0.0, 3.0), 7.5, PI, TAU, 10, Color(0.86, 0.58, 0.24), 5.0)
	wc.line(kp + Vector2(-7.0, 2.5), kp + Vector2(7.0, 2.5), Color(0.72, 0.42, 0.14), 2.4)


# --- live pass & overhead -----------------------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var t := float(AnimClock.msec()) * 0.001
	var dom: Dictionary = m.santacoloma_domino
	var dstate := String(dom.get("state", "idle"))
	# domino elders & street domino spotters
	for i in range(DOMINO_SPOTS.size()):
		var sp: Vector2 = DOMINO_SPOTS[i]
		if sp.y < vt - 40.0 or sp.y > vb + 40.0:
			continue
		var dir := Vector2(1.0 if sp.x < CX else -1.0, 0.12).normalized()
		var active := dstate == "warn" and sp.distance_to(dom.get("spot", Vector2.ZERO)) < 8.0
		NpcFigure.person(wc, sp, dir, 9100 + i, -1.0, {
			"top": Color(0.88, 0.84, 0.74) if i % 2 == 0 else BAIZE,
			"headwear": "cap",
			"arms": NpcFigure.Arms.READY,
		})
		var shake := sin(t * 30.0) * 4.0 if active else 0.0
		var bone_p := sp + dir * 13.0 + Vector2(0.0, shake)
		wc.rect(Rect2(bone_p - Vector2(3.5, 5.0), Vector2(7.0, 10.0)), Color(0.96, 0.95, 0.92))
		wc.circle(bone_p, 1.4, IRON)
	if dstate == "warn":
		var tgt: Vector2 = dom.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var frac := clampf(1.0 - float(dom.get("t", 0.0)) / DOMINO_WARN, 0.0, 1.0)
			wc.glow(tgt, DOMINO_R * (0.55 + 0.45 * frac), Color(SAFFRON.r, SAFFRON.g, SAFFRON.b, 0.34))
			wc.arc(tgt, DOMINO_R, 0.0, TAU * frac, 24, PAPRIKA, 3.0)
	elif dstate == "slam":
		var tgt: Vector2 = dom.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var fade := clampf(float(dom.get("t", 0.0)) / DOMINO_LIFE, 0.25, 1.0)
			wc.glow(tgt, DOMINO_R * 0.85, Color(SAFFRON.r, SAFFRON.g, SAFFRON.b, 0.32 * fade))
			for j in range(5):
				var dp := tgt + Vector2.from_angle(float(j) * 1.2 + 0.3) * 18.0
				wc.rect(Rect2(dp - Vector2(3.5, 5.0), Vector2(7.0, 10.0)), Color(0.96, 0.95, 0.92, fade))
	# neighbors shopping along Mercat del Fondo
	var span := HILL_END - FONDO_END
	for k in range(Outdoors.crowd_here(5, 2)):
		var dir := -1.0 if k % 2 == 0 else 1.0
		var off := fposmod(_h(k * 21) * span + t * 24.0 * (0.85 + _h(k * 13) * 0.3), span)
		var sy := (HILL_END - off) if dir < 0.0 else (FONDO_END + off)
		if sy < vt - 30.0 or sy > vb + 30.0:
			continue
		var sx := CX + (-52.0 if k % 2 == 0 else 52.0)
		NpcFigure.person(wc, Vector2(sx, sy), Vector2(0.0, dir), 9200 + k, t * 5.6 + float(k), {})
	wc.lod = keep_lod


static func draw_overhead(_m: Node2D, ci: Object) -> void:
	# balcony washing lines strung across the market street with fluttering shirts
	var b: ShapeBatch = ci if ci is ShapeBatch else null
	if b == null:
		return
	var t := float(AnimClock.msec()) * 0.003
	var cols: Array[Color] = [SAFFRON, PAPRIKA, MINT, Color(0.96, 0.95, 0.90), Color(0.32, 0.54, 0.86)]
	for wy: float in [-1280.0, -1680.0, -2100.0, -2500.0]:
		var e := _edges_at(wy)
		b.line(Vector2(e.x + 8.0, wy), Vector2(e.y - 8.0, wy + 12.0), Color(0.76, 0.74, 0.70, 0.55), 1.6)
		for i in range(6):
			var f := (float(i) + 0.5) / 6.0
			var sx := lerpf(e.x + 28.0, e.y - 28.0, f)
			var sy := wy + f * 12.0 + sin(f * PI) * 6.0
			var sway := sin(t + float(i) + wy * 0.01) * 4.0
			var col := cols[(i + int(absf(wy))) % cols.size()]
			b.rect(Rect2(sx - 8.0 + sway, sy, 16.0, 14.0), Color(col.r, col.g, col.b, 0.78))


static func draw_yard(_m: Node2D, c: Object, r: Rect2) -> void:
	# Mirador del Fondo: concrete overlook rail & colorful tiled bench strip above the Besòs
	var b := ShapeBatch.new()
	b.lod = true
	var pad := Rect2(r.position.x + 16.0, r.position.y + 18.0, r.size.x - 32.0, 42.0)
	b.rect(pad, STONE_DK)
	b.rect(pad.grow(-4.0), STONE)
	var strip := Rect2(r.position.x + 36.0, r.position.y + 24.0, r.size.x - 72.0, 8.0)
	b.rect(strip, SAFFRON)
	b.flush(c)


# --- after dark ---------------------------------------------------------------

static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	for s in SPICE_STALLS:
		var p: Vector2 = s[0]
		out.append(Vector3(p.x, p.y, 130.0))
	out.append(Vector3(CLOCK_PLINTH.get_center().x, CLOCK_PLINTH.get_center().y, 155.0))
	return out


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	return NightFronts.along_edges(m, START, GATE, 220.0, 0.0, 9100)
