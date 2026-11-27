class_name Xemeneies
extends RefCounted

# WALK: LES TRES XEMENEIES — Paral·lel's industrial chimneys, murals & skate plaza.
#
# Up the screen:
# - Paral·lel Approach (260..-900): panot de flor paving, painted concrete
#   barriers, theatre-district houses along both sides.
# - Mural Gallery & Concrete Plaza (-900..-2550): free-standing legal-graffiti
#   walls in bold trencadis hues, waxed skate ledges, muralists at work.
# - Three Brick Chimneys Terrace (-2550..-4050): three towering circular
#   red-brick chimneys bound in iron rings casting dusk shadows across the
#   sunken plaza, plus concrete amphitheatre tiers.
# - Turbine Garden Lead-Out (-4050..-5000): steel overhead gantry girders and
#   planter curbs opening into Jardí de les Xemeneies off leash.
#
# Signature live event: a muralist shakes a rattle can for 1.0 s
# ("Tss-taka-taka!" + pulsing chalk drop zone) before spraying a bright burst
# onto the concrete. Stay clear to score a clean dodge.

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
const HALF := 300.0
const START := 260.0
const GATE := -5000.0
const SIDES: Array[float] = [-1.0, 1.0]
const FAR_L := -300.0
const FAR_R := 1580.0
const FACE := 18.0
const CHUNK := 160.0

# --- route zones --------------------------------------------------------------
const APPROACH_END := -900.0
const MURAL_START := -1100.0
const MURAL_END := -2550.0
const CHIMNEY_START := -2750.0
const CHIMNEY_END := -4050.0
const GARDEN_START := -4250.0

# --- colours ------------------------------------------------------------------
const CONCRETE := Color(0.56, 0.56, 0.58)
const CONCRETE_LT := Color(0.68, 0.67, 0.68)
const CONCRETE_DK := Color(0.42, 0.42, 0.45)
const APRON := Color(0.48, 0.49, 0.52)
const PANOT_INK := Color(0.12, 0.12, 0.14, 0.14)
const PANOT_SHINE := Color(0.95, 0.96, 1.0, 0.08)
const BRICK := Color(0.62, 0.27, 0.21)
const BRICK_LT := Color(0.76, 0.38, 0.28)
const BRICK_DK := Color(0.38, 0.16, 0.13)
const STEEL := Color(0.22, 0.24, 0.28)
const STEEL_LT := Color(0.42, 0.46, 0.52)
const SHADOW := Color(0.06, 0.06, 0.10, 0.28)
const MURAL_PAL: Array[Color] = [
	Color(0.95, 0.64, 0.16),
	Color(0.10, 0.66, 0.64),
	Color(0.84, 0.22, 0.48),
	Color(0.68, 0.86, 0.24),
	Color(0.24, 0.48, 0.88),
]

# --- landmarks & props --------------------------------------------------------
const DARE_POS := Vector2(690.0, -1620.0)
const PRIZE := Vector2(506.0, -2180.0)
const PRIZE_TEXT := "nab the muralist's rattle can"

const MURAL_WALLS: Array[Rect2] = [
	Rect2(440.0, -1480.0, 44.0, 120.0),
	Rect2(796.0, -1840.0, 44.0, 120.0),
	Rect2(440.0, -2240.0, 44.0, 120.0),
]

const CHIMNEY_RECTS: Array[Rect2] = [
	Rect2(472.0, -3088.0, 56.0, 56.0),
	Rect2(752.0, -3448.0, 56.0, 56.0),
	Rect2(482.0, -3808.0, 56.0, 56.0),
]

const SKATE_LEDGES: Array[Rect2] = [
	Rect2(760.0, -1380.0, 22.0, 104.0),
	Rect2(490.0, -4560.0, 22.0, 108.0),
]

const TREES: Array[Vector2] = [
	Vector2(455.0, -180.0), Vector2(825.0, -180.0),
	Vector2(455.0, -640.0), Vector2(825.0, -640.0),
	Vector2(440.0, -4380.0), Vector2(840.0, -4380.0),
	Vector2(440.0, -4780.0), Vector2(840.0, -4780.0),
]

const LAMPS: Array[Vector2] = [
	Vector2(465.0, -420.0), Vector2(815.0, -820.0),
	Vector2(415.0, -1340.0), Vector2(865.0, -1700.0),
	Vector2(415.0, -2080.0), Vector2(865.0, -2420.0),
	Vector2(385.0, -3260.0), Vector2(895.0, -3960.0),
]

const PILONES: Array[Vector2] = [
	Vector2(540.0, -1000.0), Vector2(740.0, -1000.0),
	Vector2(540.0, -2640.0), Vector2(740.0, -2640.0),
]

const BINS: Array[Vector2] = [
	Vector2(465.0, -520.0), Vector2(855.0, -1180.0),
	Vector2(425.0, -2480.0), Vector2(885.0, -3520.0),
	Vector2(455.0, -4680.0),
]

const FOUNTAINS: Array[Vector2] = [
	Vector2(860.0, -2860.0),
]

# --- live spray event ---------------------------------------------------------
const SPRAY_WARN := 1.0
const SPRAY_R := 66.0
const SPRAY_LIFE := 5.0
const SPRAY_COOLDOWN := 7.0
const ARTIST_SPOTS: Array[Vector2] = [
	Vector2(506.0, -1420.0),
	Vector2(772.0, -1780.0),
	Vector2(506.0, -2180.0),
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
		{"y": MURAL_START, "cx": CX, "half": 265.0},
		{"y": MURAL_END, "cx": CX, "half": 265.0},
		{"y": CHIMNEY_START, "cx": CX, "half": HALF},
		{"y": CHIMNEY_END, "cx": CX, "half": HALF},
		{"y": GARDEN_START, "cx": CX, "half": 235.0},
		{"y": GATE, "cx": CX, "half": 235.0},
	]


static func _edges_at(y: float) -> Vector2:
	if _nodes.is_empty():
		_nodes = edge_nodes()
	return EdgePath.edges(_nodes, y, CX, HALF)


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.append_array(MURAL_WALLS)
	out.append_array(CHIMNEY_RECTS)
	out.append_array(SKATE_LEDGES)
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = solids(m)
	for lp: Vector2 in LAMPS:
		out.append(Rect2(lp.x - 10.0, lp.y - 10.0, 20.0, 20.0))
	return out


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if _is_in(TREES, p):
		return m.TREE_STREET
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
	m.gate_text = "JARDÍ DE LES XEMENEIES"
	m.gate_l = 420.0
	m.gate_r = 860.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([
		Vector2(600.0, -520.0), Vector2(690.0, -1240.0),
		Vector2(570.0, -1960.0), Vector2(680.0, -2940.0),
		Vector2(610.0, -3640.0), Vector2(670.0, -4520.0),
	], TYPE_VECTOR2, &"", null)
	m.fountains = Array(FOUNTAINS.duplicate(), TYPE_VECTOR2, &"", null)

	m.xemeneies_spray = {
		"state": "idle", "idx": 0, "t": 1.2,
		"artist": ARTIST_SPOTS[0], "target": ARTIST_SPOTS[0] + Vector2(56.0, 20.0),
		"hit": false,
	}
	m.xemeneies_sprays_dodged = 0
	m.xemeneies_chimneys_marked = {}
	m.xemeneies_murals_sniffed = {}
	m.xemeneies_echo_barked = false

	for t: Vector2 in TREES:
		m.poles.append(t)
	for lp: Vector2 in LAMPS:
		m.poles.append(lp)
	for pl: Vector2 in PILONES:
		m.poles.append(pl)
	m.deco_pole_count = m.poles.size()

	m.bins = Array(BINS.duplicate(), TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(455.0, -700.0), Vector2(855.0, -1540.0),
		Vector2(425.0, -2380.0), Vector2(390.0, -3420.0),
		Vector2(890.0, -3720.0), Vector2(455.0, -4480.0),
	], TYPE_VECTOR2, &"", null)

	var marks: Array[Vector2] = []
	for ch: Rect2 in CHIMNEY_RECTS:
		marks.append(ch.get_center())
	for pl: Vector2 in PILONES:
		marks.append(pl)
	for i in range(4):
		marks.append(LAMPS[i * 2])

	var snacks: Array[Vector2] = [
		Vector2(590.0, -600.0), Vector2(680.0, -1600.0),
		Vector2(620.0, -2520.0), Vector2(640.0, -3340.0),
		Vector2(610.0, -4420.0),
	]
	return [marks, snacks]


# --- tick & bark --------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	_tick_chimneys(m)
	_tick_murals(m, dp)
	_tick_spray(m, delta, dp, hp)


static func _tick_chimneys(m: Node2D) -> void:
	for i in range(CHIMNEY_RECTS.size()):
		if m.xemeneies_chimneys_marked.has(i):
			continue
		var c := CHIMNEY_RECTS[i].get_center()
		for spot: Vector2 in m.marks:
			if spot.distance_to(c) < 52.0:
				m.xemeneies_chimneys_marked[i] = true
				break


static func _tick_murals(m: Node2D, dp: Vector2) -> void:
	for i in range(MURAL_WALLS.size()):
		if m.xemeneies_murals_sniffed.has(i):
			continue
		var r := MURAL_WALLS[i].grow(36.0)
		if r.has_point(dp) and m.dog.velocity.length() < 95.0:
			m.xemeneies_murals_sniffed[i] = true
			m.award_points(2, I18n.t("w_mural_sniff_2"))
			Sfx.play("rustle", 1.0)


static func _tick_spray(m: Node2D, delta: float, dp: Vector2, hp: Vector2) -> void:
	var st: Dictionary = m.xemeneies_spray
	if st.is_empty():
		return
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))

	match state:
		"idle":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				for i in range(ARTIST_SPOTS.size()):
					var ap: Vector2 = ARTIST_SPOTS[i]
					if dp.distance_to(ap) < 280.0 and i >= int(st.get("idx", 0)):
						var step_dir := Vector2(1.0 if ap.x < CX else -1.0, 0.15).normalized()
						var tgt := dp if dp.distance_to(ap) < 160.0 else (ap + step_dir * 64.0)
						var e := _edges_at(tgt.y)
						tgt.x = clampf(tgt.x, e.x + 56.0, e.y - 56.0)
						st["state"] = "warn"
						st["idx"] = i + 1
						st["t"] = SPRAY_WARN
						st["artist"] = ap
						st["target"] = tgt
						st["hit"] = false
						m.float_text(ap + Vector2(0.0, -34.0), I18n.t("w_tss_taka"), Color(0.96, 0.90, 0.42), m.POP_SAY)
						m.feed.say(I18n.t("w_wet_paint_spray"), EventFeed.Tone.LOUD)
						Sfx.play("grit", 1.1)
						break
		"warn":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				var tgt: Vector2 = st["target"]
				st["state"] = "spray"
				st["t"] = SPRAY_LIFE
				Sfx.play("hiss", 1.2)
				var hit_dog := dp.distance_to(tgt) < SPRAY_R
				var hit_human := hp.distance_to(tgt) < SPRAY_R * 0.9
				if hit_dog or hit_human:
					st["hit"] = true
					m.bones = maxi(0, m.bones - 2)
					m.shake_t = maxf(float(m.shake_t), 0.35)
					m.float_text(tgt, I18n.t("w_neon_paws"), Color(0.96, 0.42, 0.72))
					m.feed.say(I18n.t("w_sprayed_with_paint"), EventFeed.Tone.BAD)
					m._update_hud()
				else:
					m.xemeneies_sprays_dodged += 1
					m.award_points(4, I18n.t("w_spray_dodge_4"))
					if m.combo != null:
						m.combo.add("SAVE", 4)
					m.feed.say(I18n.t("w_spray_dodged_clean"), EventFeed.Tone.GOOD)
		"spray":
			t -= delta
			st["t"] = t
			if t <= 0.0:
				st["state"] = "idle"
				st["t"] = SPRAY_COOLDOWN
	m.xemeneies_spray = st


static func idle_status(m: Node2D) -> String:
	if String(m.xemeneies_spray.get("state", "idle")) == "warn":
		return I18n.t("xemeneies_spray_warn")
	return ""


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	if not bool(m.xemeneies_echo_barked):
		for ch: Rect2 in CHIMNEY_RECTS:
			if p.distance_to(ch.get_center()) < 160.0:
				m.xemeneies_echo_barked = true
				m.award_points(2, I18n.t("w_chimney_echo_2"))
				m.float_text(ch.get_center() + Vector2(0.0, -34.0), I18n.t("w_boom_boom"), Color(0.98, 0.86, 0.56), m.POP_SAY)
				Sfx.play("bell", 0.72)
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


# --- edge layer (Paral·lel roofs & industrial turbine hall yard) --------------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_rec_valid()
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 60.0, GATE - 60.0)
	var hi := minf(vb + 60.0, START + 760.0)
	if hi > lo:
		for side: float in SIDES:
			_outside(b, side, lo, hi, Color(0.20, 0.20, 0.23))
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
				if ym <= CHIMNEY_START and ym >= CHIMNEY_END and side < 0.0:
					# sunken industrial courtyard & amphitheatre tiers outside west wall
					_outside(b, -1.0, ya, yb, Color(0.32, 0.34, 0.36))
					var tier := Rect2(ex - 110.0, ya + 6.0, 96.0, yb - ya - 12.0)
					for step in range(3):
						b.rect(Rect2(tier.position.x + float(step) * 30.0, tier.position.y, 26.0, tier.size.y), CONCRETE_DK.lightened(0.06 * float(step)))
					CityRoofs.kept_module(b, ex - 124.0, -1.0, maxf(far - 124.0, 60.0), ya, yb, 7200 + s * 2)
				else:
					b.rect(Rect2(ex if side > 0.0 else (ex - FACE), ya, FACE, yb - ya), Color(0.70, 0.66, 0.62))
					CityRoofs.kept_module(b, ex + side * FACE, side, far, ya, yb, 7200 + s * 2 + (1 if side > 0.0 else 0))
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
	for i in range(MURAL_WALLS.size()):
		var r: Rect2 = MURAL_WALLS[i]
		if r.end.y > lo - 40.0 and r.position.y < hi + 40.0:
			_cached(wc, ["mural", i], _draw_mural_wall.bind(r, i))
	for i in range(CHIMNEY_RECTS.size()):
		var r: Rect2 = CHIMNEY_RECTS[i]
		if r.end.y > lo - 120.0 and r.position.y < hi + 120.0:
			_cached(wc, ["chimney", i], _draw_chimney.bind(r, i))
	for i in range(SKATE_LEDGES.size()):
		var r: Rect2 = SKATE_LEDGES[i]
		if r.end.y > lo - 40.0 and r.position.y < hi + 40.0:
			_cached(wc, ["ledge", i], _draw_skate_ledge.bind(r))
	wc.lod = keep_lod


static func _pave_chunk(wc: ShapeBatch, a: float, z: float) -> void:
	if z <= a:
		return
	var mid := (a + z) * 0.5
	if mid >= APPROACH_END:
		_corridor(wc, a, z, CONCRETE_LT)
		var ry := floorf(a / Panot.FLOR) * Panot.FLOR
		while ry < z:
			var e := _edges_at(ry + Panot.FLOR * 0.5)
			Panot.flor_row(wc, e.x + 8.0, e.y - 8.0, ry, e.x + 8.0, PANOT_INK, PANOT_SHINE)
			ry += Panot.FLOR
	else:
		# brushed concrete skate & chimney plaza with expansion joints
		_corridor(wc, a, z, CONCRETE if mid >= GARDEN_START else APRON)
		var y := floorf(a / 72.0) * 72.0
		while y < z:
			if y > a:
				var e := _edges_at(y)
				wc.line(Vector2(e.x, y), Vector2(e.y, y), CONCRETE_DK, 1.5)
			y += 72.0
		# painted court stripes down the skate terrace
		if mid <= MURAL_START and mid >= CHIMNEY_END:
			wc.line(Vector2(CX, a), Vector2(CX, z), Color(0.95, 0.72, 0.24, 0.28), 3.0)
		# bold ground mural splash under each chimney
		for ch: Rect2 in CHIMNEY_RECTS:
			if ch.get_center().y >= a - 60.0 and ch.get_center().y <= z + 60.0:
				wc.circle(ch.get_center(), 46.0, CONCRETE_DK)


static func _draw_mural_wall(wc: ShapeBatch, r: Rect2, idx: int) -> void:
	wc.rect(Rect2(r.position + Vector2(8.0, 9.0), r.size), SHADOW)
	wc.rect(r, Color(0.14, 0.14, 0.18))
	var face := r.grow(-3.5)
	wc.rect(face, CONCRETE_LT)
	# geometric graffiti colour blocks across the whole freestanding wall with dark mortar mullions & spray dots
	var bands := 4
	var bh := face.size.y / float(bands)
	for b in range(bands):
		var col := MURAL_PAL[(idx * 2 + b) % MURAL_PAL.size()]
		var br := Rect2(face.position.x, face.position.y + float(b) * bh, face.size.x, bh - 3.0)
		wc.rect(br, col)
		wc.line(Vector2(br.position.x + 3.0, br.position.y + 3.0), Vector2(br.end.x - 3.0, br.end.y - 3.0), Color(0.12, 0.12, 0.16), 2.4)
		wc.circle(br.get_center() + Vector2(-7.0 if b % 2 == 0 else 7.0, 0.0), 4.0, Color(0.98, 0.96, 0.90))
	wc.circle(face.get_center(), 11.0, MURAL_PAL[(idx + 4) % MURAL_PAL.size()])
	wc.circle(face.get_center(), 5.0, Color(0.98, 0.96, 0.90))


static func _draw_chimney(wc: ShapeBatch, r: Rect2, _idx: int) -> void:
	var c := r.get_center()
	# long dusk chimney shadow sweeping down-right across the plaza
	wc.capsule(c + Vector2(10.0, 8.0), c + Shade.light * 130.0, 24.0, Color(0.05, 0.05, 0.09, 0.28))
	# octagonal dressed-stone plinth matching r exactly for ghost_check contrast
	wc.rect(r, CONCRETE_DK)
	wc.rect(r.grow(-4.0), STEEL)
	# red-brick tapered shaft rings & iron hoop bands
	wc.circle(c, 26.0, BRICK_DK)
	wc.circle(c, 23.0, BRICK)
	wc.circle(c + Vector2(-3.0, -3.0), 17.0, BRICK_LT)
	wc.arc(c, 22.0, 0.0, TAU, 24, STEEL, 2.2)
	wc.arc(c, 15.0, 0.0, TAU, 20, STEEL, 1.8)
	wc.circle(c, 10.0, Color(0.14, 0.12, 0.13))


static func _draw_skate_ledge(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Vector2(4.0, 5.0), r.size), SHADOW)
	wc.rect(r, CONCRETE_DK)
	wc.rect(r.grow(-2.5), CONCRETE_LT)
	# steel angle-iron coping + wax scuff marks
	wc.line(Vector2(r.position.x + 2.0, r.position.y + 2.0), Vector2(r.position.x + 2.0, r.end.y - 2.0), Color(0.86, 0.88, 0.92), 3.0)
	wc.line(Vector2(r.end.x - 2.0, r.position.y + 2.0), Vector2(r.end.x - 2.0, r.end.y - 2.0), MURAL_PAL[0], 2.0)


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_in(LAMPS, p):
		wc.circle(p + Vector2(3.0, 4.0), 8.5, SHADOW)
		wc.circle(p, 8.5, STEEL)
		wc.circle(p + Vector2(-1.5, -1.5), 4.0, STEEL_LT)
		return
	if _is_in(PILONES, p):
		wc.circle(p + Vector2(2.5, 3.0), 8.0, SHADOW)
		wc.circle(p, 8.0, MURAL_PAL[1])
		wc.circle(p, 4.0, Color(0.95, 0.95, 0.96))


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# skate-session street snack: half bocadillo in foil wrap
	wc.polygon(PackedVector2Array([kp + Vector2(-9, -4), kp + Vector2(8, -5), kp + Vector2(9, 4), kp + Vector2(-8, 5)]), Color(0.78, 0.80, 0.84))
	wc.capsule(kp + Vector2(-6.0, 0.0), kp + Vector2(6.0, 0.0), 3.0, Color(0.82, 0.56, 0.28))


# --- live pass & overhead -----------------------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var t := float(AnimClock.msec()) * 0.001
	var spray: Dictionary = m.xemeneies_spray
	var sstate := String(spray.get("state", "idle"))
	# mural artists at each wall
	for i in range(ARTIST_SPOTS.size()):
		var ap: Vector2 = ARTIST_SPOTS[i]
		if ap.y < vt - 40.0 or ap.y > vb + 40.0:
			continue
		var dir := Vector2(-1.0 if ap.x > CX else 1.0, 0.0)
		var active := sstate == "warn" and ap.distance_to(spray.get("artist", Vector2.ZERO)) < 8.0
		var shake := sin(t * 32.0) * 3.0 if active else 0.0
		NpcFigure.person(wc, ap, dir, 7100 + i, -1.0, {
			"top": MURAL_PAL[i % MURAL_PAL.size()],
			"headwear": "cap",
			"arms": NpcFigure.Arms.READY,
		})
		wc.circle(ap + dir * 13.0 + Vector2(0.0, shake), 3.6, MURAL_PAL[(i + 1) % MURAL_PAL.size()])
	if sstate == "warn":
		var tgt: Vector2 = spray.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var frac := clampf(1.0 - float(spray.get("t", 0.0)) / SPRAY_WARN, 0.0, 1.0)
			wc.glow(tgt, SPRAY_R * (0.55 + 0.45 * frac), Color(0.84, 0.22, 0.48, 0.34))
			wc.arc(tgt, SPRAY_R, 0.0, TAU * frac, 24, Color(0.95, 0.64, 0.16), 3.0)
	elif sstate == "spray":
		var tgt: Vector2 = spray.get("target", Vector2.ZERO)
		if tgt.y > vt - 90.0 and tgt.y < vb + 90.0:
			var fade := clampf(float(spray.get("t", 0.0)) / SPRAY_LIFE, 0.25, 1.0)
			wc.glow(tgt, SPRAY_R * 0.9, Color(0.84, 0.22, 0.48, 0.48 * fade))
			wc.glow(tgt + Vector2(12.0, -8.0), SPRAY_R * 0.5, Color(0.10, 0.66, 0.64, 0.40 * fade))
	# strollers & skaters admiring the chimneys
	var span := APPROACH_END - CHIMNEY_END
	for k in range(Outdoors.crowd_here(5, 2)):
		var dir := -1.0 if k % 2 == 0 else 1.0
		var off := fposmod(_h(k * 23) * span + t * 26.0 * (0.85 + _h(k * 9) * 0.35), span)
		var sy := (APPROACH_END - off) if dir < 0.0 else (CHIMNEY_END + off)
		if sy < vt - 30.0 or sy > vb + 30.0:
			continue
		var sx := CX + (-72.0 if k % 2 == 0 else 72.0)
		NpcFigure.person(wc, Vector2(sx, sy), Vector2(0.0, dir), 7200 + k, t * 5.8 + float(k), {})
	wc.lod = keep_lod


static func draw_overhead(_m: Node2D, ci: Object) -> void:
	# overhead steel turbine gantry beams crossing the northern garden approach
	var b: ShapeBatch = ci if ci is ShapeBatch else null
	if b == null:
		return
	for gy: float in [-4340.0, -4720.0]:
		b.rect(Rect2(390.0, gy - 6.0, 500.0, 12.0), Color(0.14, 0.16, 0.20, 0.62))
		b.line(Vector2(390.0, gy), Vector2(890.0, gy), STEEL_LT, 2.0)


static func draw_yard(_m: Node2D, c: Object, r: Rect2) -> void:
	# Jardí de les Xemeneies: concrete turbine perimeter walkway + painted mural planter strip
	var b := ShapeBatch.new()
	b.lod = true
	var pad := Rect2(r.position.x + 16.0, r.position.y + 18.0, r.size.x - 32.0, 44.0)
	b.rect(pad, CONCRETE)
	b.rect(pad.grow(-4.0), CONCRETE_LT)
	var strip := Rect2(r.position.x + 36.0, r.position.y + 24.0, r.size.x - 72.0, 8.0)
	b.rect(strip, MURAL_PAL[1])
	b.flush(c)


# --- after dark ---------------------------------------------------------------

static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	for ch: Rect2 in CHIMNEY_RECTS:
		var c := ch.get_center()
		out.append(Vector3(c.x, c.y, 165.0))
	return out


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	return NightFronts.along_edges(m, START, GATE, 220.0, 0.0, 7100)
