class_name Llucia
extends RefCounted

# WALK: FIRA DE SANTA LLÚCIA — Barcelona's Cathedral Christmas market at blue hour.
#
# Up the screen:
# - Plaça Nova Approach (260..-900): warm panot de flor cobbles lined with
#   potted winter laurels and iron lanterns under dusk stone.
# - Fira Stalls & Lantern Aisles (-900..-2550): wooden Christmas booths stacked
#   with fresh nativity moss, painted figurines, caganers, mistletoe, and strung
#   fairy lights overhead.
# - Caga Tió Stage & Cathedral Square (-2550..-3900): broad cobble plaza built
#   around the smiling striped Caga Tió log with red barretina and bowls of torró.
# - Pine Nursery Lead-Out (-3900..-5000): potted fir planters and booths
#   opening into Plaça de la Catedral off leash.
#
# Signature live event: a beaming Tió tender taps the log for 1.1 s
# ("Caga tió, torró!" + pulsing festive ring) before showering torró onto the
# cobbles. Pull clear for a clean dodge and snag the dropped almond torró.

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
const HALF := 295.0
const START := 260.0
const GATE := -5000.0
const SIDES: Array[float] = [-1.0, 1.0]
const FAR_L := -300.0
const FAR_R := 1580.0
const FACE := 18.0
const CHUNK := 160.0

# --- route zones --------------------------------------------------------------
const APPROACH_END := -900.0
const FAIR_START := -1100.0
const FAIR_END := -2550.0
const TIO_START := -2750.0
const TIO_END := -3900.0
const PINE_START := -4100.0

# --- colours ------------------------------------------------------------------
const STONE_DARK := Color(0.56, 0.54, 0.52)
const STONE_PLAZA := Color(0.68, 0.64, 0.58)
const STONE_TRIM := Color(0.42, 0.40, 0.39)
const PANOT_INK := Color(0.14, 0.12, 0.14, 0.16)
const PANOT_SHINE := Color(0.95, 0.92, 0.86, 0.08)
const PINE_DARK := Color(0.12, 0.34, 0.20)
const PINE_LIT := Color(0.22, 0.52, 0.28)
const RED_FELT := Color(0.78, 0.18, 0.20)
const GOLD := Color(0.96, 0.78, 0.26)
const WARM_CREAM := Color(0.96, 0.91, 0.78)
const WOOD := Color(0.46, 0.30, 0.18)
const WOOD_LIT := Color(0.64, 0.44, 0.26)
const MOSS_GREEN := Color(0.26, 0.50, 0.22)
const SHADOW := Color(0.05, 0.06, 0.10, 0.28)
const IRON := Color(0.18, 0.19, 0.22)

# --- landmarks & props --------------------------------------------------------
const DARE_POS := Vector2(730.0, -3080.0)
const PRIZE := Vector2(548.0, -2040.0)
const PRIZE_TEXT := "grab a marzipan figure off the stall"

const STALLS: Array = [
	[Vector2(485.0, -1360.0), "moss"],
	[Vector2(795.0, -1700.0), "caganer"],
	[Vector2(485.0, -2040.0), "nativity"],
	[Vector2(795.0, -2380.0), "zambomba"],
	[Vector2(790.0, -4380.0), "mistletoe"],
]

const TIO_STAGE := Rect2(440.0, -3340.0, 96.0, 68.0)

const PINE_PLANTERS: Array[Rect2] = [
	Rect2(442.0, -4240.0, 56.0, 52.0),
	Rect2(442.0, -4640.0, 56.0, 52.0),
]

const TREES: Array[Vector2] = [
	Vector2(465.0, -220.0), Vector2(815.0, -220.0),
	Vector2(465.0, -680.0), Vector2(815.0, -680.0),
	Vector2(450.0, -4480.0), Vector2(830.0, -4480.0),
	Vector2(450.0, -4820.0), Vector2(830.0, -4820.0),
]

const LAMPS: Array[Vector2] = [
	Vector2(465.0, -440.0), Vector2(815.0, -820.0),
	Vector2(420.0, -1200.0), Vector2(860.0, -1860.0),
	Vector2(420.0, -2480.0), Vector2(860.0, -3460.0),
	Vector2(450.0, -4180.0), Vector2(830.0, -4760.0),
]

const PILONES: Array[Vector2] = [
	Vector2(540.0, -960.0), Vector2(740.0, -960.0),
	Vector2(540.0, -2640.0), Vector2(740.0, -2640.0),
]

const BINS: Array[Vector2] = [
	Vector2(470.0, -560.0), Vector2(850.0, -1480.0),
	Vector2(430.0, -2220.0), Vector2(875.0, -3160.0),
	Vector2(460.0, -4760.0),
]

const FOUNTAINS: Array[Vector2] = [
	Vector2(860.0, -3720.0),
]

# --- Caga Tió live event ------------------------------------------------------
const TIO_WARN := 1.1
const TIO_R := 64.0
const TIO_LIFE := 5.5
const TIO_COOLDOWN := 7.0
const TIO_SPOTS: Array[Vector2] = [
	Vector2(575.0, -1460.0),
	Vector2(695.0, -2160.0),
	Vector2(565.0, -3306.0),
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
		{"y": APPROACH_END, "cx": CX, "half": 215.0},
		{"y": FAIR_START, "cx": CX, "half": 250.0},
		{"y": FAIR_END, "cx": CX, "half": 250.0},
		{"y": TIO_START, "cx": CX, "half": HALF},
		{"y": TIO_END, "cx": CX, "half": HALF},
		{"y": PINE_START, "cx": CX, "half": 230.0},
		{"y": GATE, "cx": CX, "half": 230.0},
	]


static func _edges_at(y: float) -> Vector2:
	if _nodes.is_empty():
		_nodes = edge_nodes()
	return EdgePath.edges(_nodes, y, CX, HALF)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for s: Array in STALLS:
		var pos: Vector2 = s[0]
		out.append(Rect2(pos.x - 36.0, pos.y - 22.0, 72.0, 44.0))
	out.append(TIO_STAGE)
	for pr: Rect2 in PINE_PLANTERS:
		out.append(pr)
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = solids(m)
	for lp: Vector2 in LAMPS:
		out.append(Rect2(lp.x - 10.0, lp.y - 10.0, 20.0, 20.0))
	for pl: Vector2 in PILONES:
		out.append(Rect2(pl.x - 8.0, pl.y - 8.0, 16.0, 16.0))
	return out


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(TREES, p):
		return m.TREE_FOREST
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(LAMPS, p)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return Surfaces.S.PAVEMENT
	var e := _edges_at(p.y)
	if p.x >= e.x - 8.0 and p.x <= e.y + 8.0:
		return Surfaces.S.PAVEMENT
	return Surfaces.S.GRASS


# --- build --------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DE LA CATEDRAL"
	m.gate_l = 420.0
	m.gate_r = 860.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([
		Vector2(610.0, -480.0), Vector2(680.0, -880.0),
		Vector2(590.0, -1760.0), Vector2(680.0, -2420.0),
		Vector2(620.0, -3540.0), Vector2(660.0, -4560.0),
	], TYPE_VECTOR2, &"", null)
	m.fountains = Array(FOUNTAINS.duplicate(), TYPE_VECTOR2, &"", null)

	m.llucia_tio = {
		"state": "idle", "idx": 0, "t": 1.2,
		"spot": TIO_SPOTS[0], "target": TIO_SPOTS[0] + Vector2(36.0, 18.0),
		"torro": Vector2.ZERO, "torro_active": false, "hit": false,
	}
	m.llucia_tio_dodged = 0
	m.llucia_stalls_sniffed = {}
	m.llucia_trees_marked = {}

	for t: Vector2 in TREES:
		m.poles.append(t)
	for lp: Vector2 in LAMPS:
		m.poles.append(lp)
	for pl: Vector2 in PILONES:
		m.poles.append(pl)
	m.deco_pole_count = m.poles.size()

	m.bins = Array(BINS.duplicate(), TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(465.0, -340.0), Vector2(845.0, -1520.0),
		Vector2(430.0, -1860.0), Vector2(875.0, -2960.0),
		Vector2(875.0, -3440.0), Vector2(460.0, -4380.0),
	], TYPE_VECTOR2, &"", null)

	var marks: Array[Vector2] = []
	for pl: Vector2 in PILONES:
		marks.append(pl)
	for i in range(6):
		marks.append(LAMPS[i])

	var snacks: Array[Vector2] = [
		Vector2(585.0, -620.0), Vector2(670.0, -1440.0),
		Vector2(585.0, -2140.0), Vector2(650.0, -3260.0),
		Vector2(600.0, -4440.0),
	]
	return [marks, snacks]


# --- tick ---------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	_tick_trees(m)
	_tick_stalls(m, dp)
	_tick_tio(m, delta, dp, hp)


static func _tick_trees(m: Node2D) -> void:
	for i in range(TREES.size()):
		if m.llucia_trees_marked.has(i):
			continue
		var tp: Vector2 = TREES[i]
		for spot: Vector2 in m.marks:
			if spot.distance_to(tp) < 38.0:
				m.llucia_trees_marked[i] = true
				break


static func _tick_stalls(m: Node2D, dp: Vector2) -> void:
	for i in range(STALLS.size()):
		if m.llucia_stalls_sniffed.has(i):
			continue
		var pos: Vector2 = STALLS[i][0]
		if dp.distance_to(pos) < 62.0 and m.dog.velocity.length() < 95.0:
			m.llucia_stalls_sniffed[i] = true
			m.award_points(1, I18n.t("w_llucia_stall_1"))
			Sfx.play("rustle", 1.05)


static func _tick_tio(m: Node2D, delta: float, dp: Vector2, hp: Vector2) -> void:
	var st: Dictionary = m.llucia_tio
	if st.is_empty():
		return
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))

	match state:
		"idle":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				for i in range(TIO_SPOTS.size()):
					var sp: Vector2 = TIO_SPOTS[i]
					if dp.distance_to(sp) < 280.0 and i >= int(st.get("idx", 0)):
						var step_dir := Vector2(1.0 if sp.x < CX else -1.0, 0.18).normalized()
						var tgt := dp if dp.distance_to(sp) < 160.0 else (sp + step_dir * 66.0)
						var e := _edges_at(tgt.y)
						tgt.x = clampf(tgt.x, e.x + 56.0, e.y - 56.0)
						st["state"] = "warn"
						st["idx"] = i + 1
						st["t"] = TIO_WARN
						st["spot"] = sp
						st["target"] = tgt
						st["hit"] = false
						st["torro_active"] = false
						m.float_text(sp + Vector2(0.0, -34.0), I18n.t("w_caga_tio_say"), Color(1.0, 0.90, 0.44), m.POP_SAY)
						m.feed.say(I18n.t("w_tio_shivering"), EventFeed.Tone.LOUD)
						Sfx.play("drum", 1.0)
						break
		"warn":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				var tgt: Vector2 = st["target"]
				st["state"] = "drop"
				st["t"] = TIO_LIFE
				st["torro"] = tgt + Vector2(22.0 if tgt.x < CX else -22.0, 12.0)
				st["torro_active"] = true
				Sfx.play("bell", 1.15)
				var hit_dog := dp.distance_to(tgt) < TIO_R
				var hit_human := hp.distance_to(tgt) < TIO_R * 0.9
				if hit_dog or hit_human:
					st["hit"] = true
					m.bones = maxi(0, m.bones - 2)
					m.shake_t = maxf(float(m.shake_t), 0.35)
					m.float_text(tgt, I18n.t("w_torro_bonk"), Color(0.95, 0.56, 0.42))
					m.feed.say(I18n.t("w_tio_bonked_you"), EventFeed.Tone.BAD)
					m._update_hud()
				else:
					m.llucia_tio_dodged += 1
					m.award_points(4, I18n.t("w_tio_dodge_4"))
					if m.combo != null:
						m.combo.add("SAVE", 4)
					m.feed.say(I18n.t("w_tio_dodged_clean"), EventFeed.Tone.GOOD)
		"drop":
			t -= delta
			st["t"] = t
			if bool(st.get("torro_active", false)):
				var tp: Vector2 = st["torro"]
				if dp.distance_to(tp) < 32.0:
					st["torro_active"] = false
					m.award_points(2, I18n.t("w_torro_snatch_2"))
					m.float_text(tp, I18n.t("w_sweet_torro"), GOLD)
					Sfx.play("pickup", 1.1)
					m._update_hud()
			if t <= 0.0:
				st["state"] = "idle"
				st["t"] = TIO_COOLDOWN
				st["torro_active"] = false
	m.llucia_tio = st


static func idle_status(m: Node2D) -> String:
	if String(m.llucia_tio.get("state", "idle")) == "warn":
		return I18n.t("llucia_tio_warn")
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


# --- edge layer (Gothic Cathedral stone roofs & winter awnings) ---------------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 60.0, GATE - 60.0)
	var hi := minf(vb + 60.0, START + 760.0)
	if hi > lo:
		for side: float in SIDES:
			_outside(b, side, lo, hi, Color(0.18, 0.17, 0.20))
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
				b.rect(Rect2(ex if side > 0.0 else (ex - FACE), ya, FACE, yb - ya), Color(0.68, 0.64, 0.56))
				CityRoofs.kept_module(b, ex + side * FACE, side, far, ya, yb, 8100 + s * 2 + (1 if side > 0.0 else 0))
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
	for s in STALLS:
		var pos: Vector2 = s[0]
		if pos.y > lo - 70.0 and pos.y < hi + 70.0:
			_cached(wc, ["stall", pos.x, pos.y], _draw_stall.bind(pos, String(s[1])))
	if TIO_STAGE.end.y > lo - 40.0 and TIO_STAGE.position.y < hi + 40.0:
		_cached(wc, ["tio_stage"], _draw_tio_stage)
	for pr: Rect2 in PINE_PLANTERS:
		if pr.end.y > lo - 40.0 and pr.position.y < hi + 40.0:
			_cached(wc, ["pine", pr.position.x, pr.position.y], _draw_pine_planter.bind(pr))
	wc.lod = keep_lod


static func _pave_chunk(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var mid := (a + z) * 0.5
	var in_tio := mid <= TIO_START and mid >= TIO_END
	var base := STONE_PLAZA if in_tio else STONE_DARK
	_corridor(wc, a, z, base)
	# woven pine-needle & cobble festive runner down the stall aisles
	if mid <= APPROACH_END and mid >= FAIR_END:
		wc.rect(Rect2(CX - 54.0, a, 108.0, z - a), Color(0.50, 0.22, 0.22, 0.24))
		wc.line(Vector2(CX - 54.0, a), Vector2(CX - 54.0, z), GOLD, 1.8)
		wc.line(Vector2(CX + 54.0, a), Vector2(CX + 54.0, z), GOLD, 1.8)
	var ry := floorf(a / Panot.FLOR) * Panot.FLOR
	while ry < z:
		var e := _edges_at(ry + Panot.FLOR * 0.5)
		Panot.flor_row(wc, e.x + 8.0, e.y - 8.0, ry, e.x + 8.0, PANOT_INK, PANOT_SHINE)
		ry += Panot.FLOR
	# stone rose compass under Caga Tió square
	if a <= -3240.0 and z >= -3370.0:
		var cc := Vector2(CX, -3306.0)
		wc.circle(cc, 48.0, STONE_TRIM)
		wc.circle(cc, 40.0, STONE_PLAZA)
		for k in range(8):
			var tip := cc + Vector2.from_angle(float(k) * TAU / 8.0) * 34.0
			wc.line(cc, tip, RED_FELT if k % 2 == 0 else PINE_DARK, 2.6)


static func _draw_stall(wc: ShapeBatch, pos: Vector2, kind: String) -> void:
	var r := Rect2(pos.x - 36.0, pos.y - 22.0, 72.0, 44.0)
	wc.rect(Rect2(r.position + Vector2(6.0, 7.0), r.size), SHADOW)
	wc.rect(r, Color(0.14, 0.13, 0.16))
	var top := r.grow(-3.5)
	wc.rect(top, Color(0.92, 0.86, 0.72))
	# pine-bough roof strip & crimson-gold scalloped awning
	wc.rect(Rect2(top.position.x, top.position.y, top.size.x, 15.0), PINE_DARK)
	for i in range(6):
		var col := RED_FELT if i % 2 == 0 else WARM_CREAM
		wc.rect(Rect2(top.position.x + float(i) * 10.8, top.position.y + 11.0, 10.8, 6.0), col)
	# string of warm fairy bulbs along the fascia and lower counter sill
	for b in range(5):
		wc.circle(Vector2(top.position.x + 8.0 + float(b) * 12.2, top.position.y + 16.5), 2.5, GOLD)
	wc.line(Vector2(top.position.x, top.end.y - 2.0), Vector2(top.end.x, top.end.y - 2.0), WOOD, 3.0)
	match kind:
		"moss":
			for m_i in range(4):
				var mp := Vector2(top.position.x + 11.0 + float(m_i) * 15.0, top.position.y + 29.0)
				wc.circle(mp, 5.8, MOSS_GREEN)
				wc.circle(mp + Vector2(-1.5, -1.5), 2.4, Color(0.38, 0.64, 0.30))
		"caganer":
			for c_i in range(4):
				var cp := Vector2(top.position.x + 11.0 + float(c_i) * 15.0, top.position.y + 29.0)
				wc.circle(cp, 4.4, Color(0.95, 0.94, 0.92))
				wc.circle(cp + Vector2(0.0, -3.2), 2.6, RED_FELT)
		"nativity":
			wc.rect(Rect2(top.position.x + 8.0, top.position.y + 22.0, top.size.x - 16.0, 13.0), Color(0.76, 0.64, 0.42))
			for n_i in range(4):
				var np := Vector2(top.position.x + 13.0 + float(n_i) * 13.0, top.position.y + 28.0)
				wc.circle(np, 3.6, [GOLD, Color(0.26, 0.50, 0.72), WARM_CREAM, RED_FELT][n_i])
		"zambomba":
			for z_i in range(3):
				var zp := Vector2(top.position.x + 14.0 + float(z_i) * 19.0, top.position.y + 28.0)
				wc.circle(zp, 5.4, Color(0.56, 0.34, 0.18))
				wc.circle(zp, 3.6, Color(0.90, 0.80, 0.60))
				wc.line(zp, zp + Vector2(3.0, -4.0), WOOD, 1.4)
		"mistletoe":
			for g_i in range(4):
				var gp := Vector2(top.position.x + 11.0 + float(g_i) * 15.0, top.position.y + 28.0)
				wc.circle(gp, 5.0, PINE_LIT)
				wc.circle(gp + Vector2(1.5, -1.0), 2.0, RED_FELT)


static func _draw_tio_stage(wc: ShapeBatch) -> void:
	var r := TIO_STAGE
	wc.rect(Rect2(r.position + Vector2(7.0, 9.0), r.size), SHADOW)
	wc.rect(r, Color(0.14, 0.13, 0.16))
	wc.rect(r.grow(-4.0), WARM_CREAM)
	wc.rect(r.grow(-7.0), Color(0.56, 0.36, 0.20))
	# festive corner lanterns so the whole stage perimeter stands out cleanly
	for cp: Vector2 in [
		Vector2(r.position.x + 7.0, r.position.y + 7.0),
		Vector2(r.end.x - 7.0, r.position.y + 7.0),
		Vector2(r.position.x + 7.0, r.end.y - 7.0),
		Vector2(r.end.x - 7.0, r.end.y - 7.0),
	]:
		wc.circle(cp, 4.0, RED_FELT)
		wc.circle(cp, 2.0, GOLD)
	# giant smiling Caga Tió log with striped blanket and red barretina
	var c := r.get_center()
	wc.capsule(c + Vector2(-24.0, 2.0), c + Vector2(20.0, 2.0), 14.0, Color(0.36, 0.22, 0.12))
	wc.rect(Rect2(c.x - 16.0, c.y - 11.0, 24.0, 24.0), RED_FELT)
	for stripe in range(3):
		wc.rect(Rect2(c.x - 12.0 + float(stripe) * 7.0, c.y - 11.0, 3.0, 24.0), GOLD)
	# face end of the log
	wc.circle(c + Vector2(20.0, 2.0), 13.0, Color(0.86, 0.72, 0.50))
	wc.circle(c + Vector2(16.0, -1.0), 2.2, IRON)
	wc.circle(c + Vector2(24.0, -1.0), 2.2, IRON)
	wc.arc(c + Vector2(20.0, 3.5), 5.0, 0.2, PI - 0.2, 8, IRON, 2.0)
	# barretina cap
	wc.capsule(c + Vector2(10.0, -9.0), c + Vector2(26.0, -13.0), 6.0, RED_FELT)


static func _draw_pine_planter(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Vector2(5.0, 6.0), r.size), SHADOW)
	wc.rect(r, Color(0.14, 0.13, 0.16))
	wc.rect(r.grow(-3.5), WARM_CREAM)
	wc.rect(r.grow(-6.5), PINE_DARK)
	var c := r.get_center()
	wc.circle(c, 16.0, PINE_LIT)
	wc.circle(c + Vector2(-3.0, -3.0), 9.0, Color(0.34, 0.66, 0.34))
	for b_i in range(4):
		var bp := c + Vector2.from_angle(float(b_i) * PI * 0.5 + 0.4) * 10.0
		wc.circle(bp, 3.0, RED_FELT if b_i % 2 == 0 else GOLD)


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(LAMPS, p):
		wc.circle(p + Vector2(3.0, 4.0), 8.5, SHADOW)
		wc.circle(p, 8.5, IRON)
		wc.circle(p + Vector2(-1.5, -1.5), 4.2, GOLD)
		return
	if _is_in(PILONES, p):
		wc.circle(p + Vector2(2.5, 3.0), 8.0, SHADOW)
		wc.circle(p, 8.0, IRON)
		wc.circle(p, 3.8, RED_FELT)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# square of almond torró wrapped in gold foil
	wc.rect(Rect2(kp - Vector2(7.0, 5.0), Vector2(14.0, 10.0)), GOLD)
	wc.rect(Rect2(kp - Vector2(5.0, 3.5), Vector2(10.0, 7.0)), WARM_CREAM)
	wc.circle(kp + Vector2(-2.0, 0.0), 1.6, Color(0.54, 0.34, 0.16))
	wc.circle(kp + Vector2(2.5, 1.0), 1.6, Color(0.54, 0.34, 0.16))


# --- live pass & overhead -----------------------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var t := float(AnimClock.msec()) * 0.001
	var tio: Dictionary = m.llucia_tio
	var tstate := String(tio.get("state", "idle"))
	# Tió tenders / street carolers at TIO_SPOTS
	for i in range(TIO_SPOTS.size()):
		var sp: Vector2 = TIO_SPOTS[i]
		if sp.y < vt - 40.0 or sp.y > vb + 40.0:
			continue
		var dir := Vector2(1.0 if sp.x < CX else -1.0, 0.18).normalized()
		var active := tstate == "warn" and sp.distance_to(tio.get("spot", Vector2.ZERO)) < 8.0
		NpcFigure.person(wc, sp, dir, 8100 + i, -1.0, {
			"top": RED_FELT if i % 2 == 0 else PINE_DARK,
			"headwear": "cap",
			"arms": NpcFigure.Arms.READY,
		})
		# small mini Caga Tió log / stick beside helper
		var wobble := sin(t * 28.0) * 4.0 if active else 0.0
		var lp := sp + dir * 13.0 + Vector2(wobble, 0.0)
		wc.capsule(lp + Vector2(-5.0, 0.0), lp + Vector2(5.0, 0.0), 4.2, Color(0.46, 0.28, 0.16))
		wc.circle(lp + Vector2(4.0, 0.0), 3.0, WARM_CREAM)
	if tstate == "warn":
		var tgt: Vector2 = tio.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var frac := clampf(1.0 - float(tio.get("t", 0.0)) / TIO_WARN, 0.0, 1.0)
			wc.glow(tgt, TIO_R * (0.55 + 0.45 * frac), Color(GOLD.r, GOLD.g, GOLD.b, 0.34))
			wc.arc(tgt, TIO_R, 0.0, TAU * frac, 24, RED_FELT, 3.0)
	elif tstate == "drop":
		var tgt: Vector2 = tio.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var fade := clampf(float(tio.get("t", 0.0)) / TIO_LIFE, 0.25, 1.0)
			wc.glow(tgt, TIO_R * 0.9, Color(GOLD.r, GOLD.g, GOLD.b, 0.42 * fade))
		if bool(tio.get("torro_active", false)):
			var tp: Vector2 = tio.get("torro", Vector2.ZERO)
			if tp.y > vt - 30.0 and tp.y < vb + 30.0:
				wc.glow(tp, 18.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.38))
				wc.rect(Rect2(tp - Vector2(7.0, 4.5), Vector2(14.0, 9.0)), GOLD)
				wc.rect(Rect2(tp - Vector2(5.0, 3.0), Vector2(10.0, 6.0)), WARM_CREAM)
	# evening Christmas shoppers carrying gifts & poinsettias
	var span := APPROACH_END - FAIR_END
	for k in range(Outdoors.crowd_here(5, 2)):
		var dir := -1.0 if k % 2 == 0 else 1.0
		var off := fposmod(_h(k * 19) * span + t * 22.0 * (0.85 + _h(k * 11) * 0.3), span)
		var sy := (APPROACH_END - off) if dir < 0.0 else (FAIR_END + off)
		if sy < vt - 30.0 or sy > vb + 30.0:
			continue
		var sx := CX + (-58.0 if k % 2 == 0 else 58.0)
		NpcFigure.person(wc, Vector2(sx, sy), Vector2(0.0, dir), 8200 + k, t * 5.2 + float(k), {})
	wc.lod = keep_lod


static func draw_overhead(_m: Node2D, ci: Object) -> void:
	# strung fairy-light garlands crisscrossing the fair aisles & cathedral square
	var b: ShapeBatch = ci if ci is ShapeBatch else null
	if b == null:
		return
	var t := float(AnimClock.msec()) * 0.004
	for gy: float in [-1200.0, -1550.0, -1900.0, -2250.0, -2900.0, -3250.0, -3600.0]:
		var e := _edges_at(gy)
		b.line(Vector2(e.x + 8.0, gy), Vector2(e.y - 8.0, gy + 16.0), Color(0.16, 0.32, 0.20, 0.72), 2.4)
		for i in range(9):
			var f := (float(i) + 0.5) / 9.0
			var lp := Vector2(lerpf(e.x + 12.0, e.y - 12.0, f), gy + f * 16.0 + sin(f * PI) * 8.0)
			var pulse := 0.7 + 0.3 * sin(t + float(i) + gy * 0.01)
			var col := GOLD if i % 2 == 0 else Color(0.95, 0.42, 0.36)
			b.circle(lp, 3.2, Color(col.r, col.g, col.b, 0.85 * pulse))


static func draw_freedom(m: Node2D, c: Object) -> void:
	# Plaça de la Catedral: stone flagstones, towering lit Christmas tree & fountain
	m._draw_freedom_beyond(c)
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	b.rect(r, STONE_PLAZA)
	Panot.flor(b, r.position.x + 12.0, r.end.x - 12.0, r.position.y + 12.0, r.end.y - 12.0, PANOT_INK, PANOT_SHINE)
	# illuminated Christmas tree mosaic circle in the square center-west
	var tc := Vector2(560.0, float(m.GATE_Y) - 430.0)
	b.circle(tc, 46.0, PINE_DARK)
	b.circle(tc, 34.0, PINE_LIT)
	for b_i in range(8):
		var bp := tc + Vector2.from_angle(float(b_i) * TAU / 8.0) * 26.0
		b.circle(bp, 4.2, GOLD if b_i % 2 == 0 else RED_FELT)
	b.circle(tc, 10.0, GOLD)
	# stone basin matching LevelBuild.placa_fountain
	var fr := Rect2(Vector2(825.0, float(m.GATE_Y) - 470.0), Vector2(150.0, 96.0))
	b.rect(fr.grow(10.0), STONE_TRIM)
	b.rect(fr, Color(0.24, 0.46, 0.56))
	b.circle(fr.get_center(), 10.0, STONE_PLAZA)
	b.circle(fr.get_center(), 4.5, WARM_CREAM)
	b.flush(c)
	for t: Vector2 in m.trees:
		c.draw_rect(Rect2(t - Vector2(20.0, 20.0), Vector2(40.0, 40.0)), Color(0.34, 0.26, 0.18))
		c.draw_rect(Rect2(t - Vector2(20.0, 20.0), Vector2(40.0, 40.0)), STONE_TRIM, false, 2.0)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_llucia_freedom"))


# --- after dark ---------------------------------------------------------------

static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	for s in STALLS:
		var p: Vector2 = s[0]
		out.append(Vector3(p.x, p.y, 135.0))
	out.append(Vector3(TIO_STAGE.get_center().x, TIO_STAGE.get_center().y, 155.0))
	out.append(Vector3(560.0, float(m.GATE_Y) - 430.0, 175.0))
	return out


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	return NightFronts.along_edges(m, START, GATE, 220.0, 0.0, 8100)
