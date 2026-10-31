class_name Gracia
extends RefCounted

# WALK 26: FESTA DE GRÀCIA. A narrow street of the vila in festival week, the
# low tiled houses either side (main's oldtown roofscape), papier-mâché arches
# and bunting strung across it, the stalls, a churro stand and the castellers'
# practice stage. On the way home the correfoc comes down the street after you
# (entities/correfoc_threat.gd); it stops at the stage and the churro stand
# (home_chase.GRACIA_BANDS).

const ShapeBatch := preload("res://systems/shape_batch.gd")

const HALF := 220.0
const WALL_L := 420.0
const WALL_R := 860.0

const PRIZE := Vector2(640.0, -4420.0)
const PRIZE_TEXT := "claim the festival award banner before the plaça"

const BANNER_BLUE := Color(0.20, 0.48, 0.78)
const BANNER_GOLD := Color(0.92, 0.75, 0.22)
const BANNER_RED := Color(0.85, 0.22, 0.18)
const BANNER_GREEN := Color(0.25, 0.65, 0.35)
const BANNER_WHITE := Color(0.94, 0.92, 0.86)
const FLAGS: Array[Color] = [BANNER_RED, BANNER_GOLD, BANNER_BLUE, BANNER_GREEN, BANNER_WHITE]
const CHURRO_CART := Color(0.82, 0.35, 0.20)
const CHURRO_GOLD := Color(0.86, 0.62, 0.30)
const CASTELL_MAT := Color(0.62, 0.46, 0.30)
const CASTELLER_SHIRT := Color(0.42, 0.62, 0.36)   # the Castellers de la Vila de Gràcia's green
const FAIXA := Color(0.10, 0.10, 0.12)
const STALL_CLOTH: Array[Color] = [BANNER_BLUE, BANNER_GREEN]

# The respites the correfoc stops at (home_chase.GRACIA_BANDS: -3300, -1900)
const CASTELL_STAGE := Rect2(560.0, -3340.0, 160.0, 70.0)
const CHURRO_STAND := Rect2(440.0, -1940.0, 100.0, 60.0)
const FESTIVAL_STALL_1 := Rect2(740.0, -1200.0, 90.0, 50.0)
const FESTIVAL_STALL_2 := Rect2(450.0, -2600.0, 90.0, 50.0)

# The decorated arches across the street, each street its own theme
const ARCHES: Array[float] = [-800.0, -1500.0, -2350.0, -3000.0, -3900.0]
const ARCH_COLS: Array[Color] = [
	Color(0.24, 0.52, 0.80), Color(0.92, 0.62, 0.20), Color(0.70, 0.28, 0.56),
	Color(0.28, 0.62, 0.44), Color(0.86, 0.30, 0.24),
]
const ARCH_REACH := 16.0
# bunting between the arches
const BUNTING_STEP := 170.0

# she sits pretty this long at the churro stand and gets one
const BEG_T := 1.5
const BEG_REACH := 60.0
const BEG_STILL := 25.0

# Festival lampposts for wrapping and slalom
const GRACIA_POSTS: Array[Vector2] = [
	Vector2(440.0, -500.0), Vector2(840.0, -500.0),
	Vector2(440.0, -1000.0), Vector2(840.0, -1000.0),
	Vector2(440.0, -1600.0), Vector2(840.0, -1600.0),
	Vector2(440.0, -2200.0), Vector2(840.0, -2200.0),
	Vector2(440.0, -2900.0), Vector2(840.0, -2900.0),
	Vector2(440.0, -3700.0), Vector2(840.0, -3700.0),
	Vector2(440.0, -4200.0), Vector2(840.0, -4200.0),
]


static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DE LA VIRREINA"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 440.0
	m.gate_r = 840.0

	# the lampposts are the drawn poles; the stage's corners are wrap points
	# drawn with the stage
	for p: Vector2 in GRACIA_POSTS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()
	m.poles.append(Vector2(CASTELL_STAGE.position.x + 8.0, CASTELL_STAGE.get_center().y))
	m.poles.append(Vector2(CASTELL_STAGE.end.x - 8.0, CASTELL_STAGE.get_center().y))

	m.benches = Array([
		Vector2(450.0, -750.0),
		Vector2(830.0, -2050.0),
		Vector2(450.0, -3450.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(440.0, -600.0),
		Vector2(840.0, -1700.0),
		Vector2(440.0, -3000.0),
		Vector2(840.0, -4100.0),
	], TYPE_VECTOR2, &"", null)

	# the chase's respites, on the near side of the stage and the stand
	m.chase_jams.clear()
	for r: Rect2 in [CASTELL_STAGE, CHURRO_STAND]:
		m.chase_jams.append(Vector2(r.get_center().x, r.position.y - 4.0))

	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 25.0, -450.0),
		Vector2(WALL_R - 25.0, -1350.0),
		Vector2(WALL_L + 25.0, -2400.0),
		Vector2(WALL_R - 25.0, -3200.0),
		Vector2(WALL_L + 25.0, -4000.0),
	]

	# dropped pintxos
	var keb_list: Array[Vector2] = [
		Vector2(680.0, -1300.0),
		Vector2(680.0, -2700.0),
		Vector2(580.0, -3600.0),
	]

	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT
	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [CASTELL_STAGE, CHURRO_STAND, FESTIVAL_STALL_1, FESTIVAL_STALL_2]


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


# --- main's walk hooks -------------------------------------------------------

static func draw_scenery(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)
	if _in_view(CASTELL_STAGE, vt, vb):
		_draw_stage(b, sh)
	if _in_view(CHURRO_STAND, vt, vb):
		_draw_churros(m, b, sh)
	var stalls: Array[Rect2] = [FESTIVAL_STALL_1, FESTIVAL_STALL_2]
	for i in range(stalls.size()):
		if _in_view(stalls[i], vt, vb):
			_draw_stall(b, stalls[i], STALL_CLOTH[i], sh)
	# the arches' feet on the pavement, and their shadow across it
	for i in range(ARCHES.size()):
		var ay: float = ARCHES[i]
		if ay < vt - 60.0 or ay > vb + 60.0:
			continue
		b.rect(Rect2(WALL_L, ay - 4.0 + 18.0, WALL_R - WALL_L, 14.0), Color(sh.r, sh.g, sh.b, 0.14))
		for fx: float in [WALL_L + 6.0, WALL_R - 6.0]:
			b.circle(Vector2(fx, ay) + m.LIGHT * 5.0, 11.0, sh)
			b.circle(Vector2(fx, ay), 9.0, ARCH_COLS[i].darkened(0.35))
	b.flush(m._wc)


static func _in_view(r: Rect2, vt: float, vb: float) -> bool:
	return r.end.y > vt - 80.0 and r.position.y < vb + 80.0


# the castellers' practice stage: the mat, and a pinya of green shirts round
# the base of a tower, the anxaneta's little helmet at the top
static func _draw_stage(b: ShapeBatch, sh: Color) -> void:
	var r := CASTELL_STAGE
	b.rect(Rect2(r.position + Vector2(6, 8), r.size), sh)
	b.rect(r, CASTELL_MAT.darkened(0.3))
	b.rect(r.grow(-3.0), CASTELL_MAT)
	var plank := r.position.x + 3.0 + 18.0
	while plank < r.end.x - 4.0:
		b.rect(Rect2(plank, r.position.y + 3.0, 1.5, r.size.y - 6.0), CASTELL_MAT.darkened(0.18))
		plank += 18.0
	# the colla's banner hung along the stage front
	b.rect(Rect2(r.position.x + 20.0, r.end.y - 10.0, r.size.x - 40.0, 8.0), CASTELLER_SHIRT.darkened(0.1))
	b.rect(Rect2(r.position.x + 20.0, r.end.y - 7.0, r.size.x - 40.0, 2.0), BANNER_WHITE)
	var c := r.get_center() + Vector2(0.0, -4.0)
	for k in range(10):
		var a := float(k) * (TAU / 10.0)
		var p := c + Vector2(cos(a) * 26.0, sin(a) * 18.0)
		b.circle(p + Vector2(2, 3), 8.0, sh)
		b.circle(p, 7.5, CASTELLER_SHIRT)
		b.circle(p - Vector2(cos(a), sin(a)) * 3.0, 4.0, Color(0.24, 0.18, 0.14))
	for k in range(4):
		var a := float(k) * (TAU / 4.0) + 0.4
		var p := c + Vector2(cos(a) * 11.0, sin(a) * 8.0)
		b.circle(p, 6.5, CASTELLER_SHIRT.lightened(0.08))
		b.circle(p, 3.0, FAIXA)
	b.circle(c, 6.0, BANNER_WHITE)
	b.circle(c, 3.5, BANNER_RED)


# the churro stand: a red cart under a striped awning, the fryer, a paper
# cone of churros on the counter
static func _draw_churros(m: Node2D, b: ShapeBatch, sh: Color) -> void:
	var r := CHURRO_STAND
	b.rect(Rect2(r.position + m.LIGHT * 8.0, r.size), sh)
	b.rect(r, CHURRO_CART.darkened(0.25))
	var sx := r.position.x
	var k := 0
	while sx < r.end.x - 1.0:
		b.rect(Rect2(sx, r.position.y, minf(12.5, r.end.x - sx), r.size.y - 14.0), CHURRO_CART if k % 2 == 0 else BANNER_WHITE)
		sx += 12.5
		k += 1
	b.rect(Rect2(r.position.x, r.end.y - 14.0, r.size.x, 14.0), Color(0.70, 0.66, 0.60))
	b.circle(Vector2(r.position.x + 22.0, r.end.y - 7.0), 6.0, Color(0.22, 0.20, 0.20))
	b.circle(Vector2(r.position.x + 22.0, r.end.y - 7.0), 4.0, Color(0.72, 0.52, 0.20))
	var cone := Vector2(r.end.x - 24.0, r.end.y - 7.0)
	b.polygon(PackedVector2Array([cone + Vector2(-6, -4), cone + Vector2(6, -4), cone + Vector2(0, 7)]), BANNER_WHITE)
	for d: float in [-3.0, 0.0, 3.0]:
		b.line(cone + Vector2(d, -3), cone + Vector2(d * 1.6, -12), CHURRO_GOLD, 2.5)


static func _draw_stall(b: ShapeBatch, r: Rect2, cloth: Color, sh: Color) -> void:
	b.rect(Rect2(r.position + Vector2(6, 8), r.size), sh)
	b.rect(r, cloth.darkened(0.3))
	b.rect(Rect2(r.position + Vector2(3, 3), r.size - Vector2(6, 16)), cloth)
	for k in range(int(r.size.x / 18.0)):
		b.circle(Vector2(r.position.x + 9.0 + float(k) * 18.0, r.end.y - 7.0), 4.0, FLAGS[k % FLAGS.size()])


# The arches and the bunting, over everyone. The overhead layer draws once and
# is never redrawn, so this covers the whole street and holds still.
static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "gracia":
		return
	var b := ShapeBatch.new(ci)
	var y := -400.0
	while y > m.GATE_Y + 120.0:
		var near_arch := false
		for ay: float in ARCHES:
			if absf(ay - y) < 60.0:
				near_arch = true
		if not near_arch:
			_draw_bunting(b, y, int(absf(y) / BUNTING_STEP))
		y -= BUNTING_STEP
	for i in range(ARCHES.size()):
		_draw_arch(b, ARCHES[i], ARCH_COLS[i], i)
	b.flush()


static func _draw_bunting(b: ShapeBatch, y: float, k: int) -> void:
	var sag := 10.0
	var n := 11
	var prev := Vector2(WALL_L, y)
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var p := Vector2(lerpf(WALL_L, WALL_R, t), y + sin(t * PI) * sag)
		b.line(prev, p, Color(0.20, 0.18, 0.16, 0.8), 1.5)
		var mid := (prev + p) * 0.5
		b.polygon(PackedVector2Array([prev.lerp(p, 0.15), prev.lerp(p, 0.85), mid + Vector2(0, 11)]), FLAGS[(i + k) % FLAGS.size()])
		prev = p


# a papier-mâché arch: a deck across the street on two pillars, scalloped
# along both edges, paper flowers on it and lanterns hanging under it
static func _draw_arch(b: ShapeBatch, ay: float, col: Color, i: int) -> void:
	var deck := Rect2(WALL_L - 4.0, ay - 12.0, WALL_R - WALL_L + 8.0, 24.0)
	b.rect(Rect2(deck.position + Vector2(8, 14), deck.size), Color(0.04, 0.05, 0.08, 0.18))
	b.rect(deck, col.darkened(0.25))
	b.rect(deck.grow(-3.0), col)
	var sx := deck.position.x + 10.0
	while sx < deck.end.x - 4.0:
		b.circle(Vector2(sx, deck.position.y), 6.0, col.lightened(0.2))
		b.circle(Vector2(sx, deck.end.y), 6.0, col.darkened(0.12))
		sx += 20.0
	for k in range(9):
		var fp := Vector2(deck.position.x + 30.0 + float(k) * 48.0, ay)
		var fc: Color = FLAGS[(k + i) % FLAGS.size()]
		for pe in range(5):
			b.circle(fp + Vector2.from_angle(float(pe) * TAU / 5.0 + float(i)) * 5.0, 4.0, fc)
		b.circle(fp, 3.0, BANNER_GOLD.lightened(0.2))
	for fx: float in [WALL_L + 6.0, WALL_R - 6.0]:
		b.circle(Vector2(fx, ay), 12.0, col.darkened(0.4))
		b.circle(Vector2(fx, ay) - Vector2(3, 3), 7.0, col.lightened(0.1))


static func tick(m: Node2D, delta: float) -> void:
	var dp: Vector2 = m.dog.global_position
	# zooming under an arch, once an arch, either way along the street
	if m.dog.turbo_active:
		for i in range(ARCHES.size()):
			var bit := 1 << i
			if m.gracia_arch_mask & bit == 0 and absf(dp.y - ARCHES[i]) < ARCH_REACH:
				m.gracia_arch_mask |= bit
				m.gracia_arches_zoomed += 1
				m.combo.add("ARCH", 2)
				m.float_text(dp + Vector2(0, -26), "under the arch! +2", ARCH_COLS[i].lightened(0.3))
	# sitting pretty in front of the churro stand
	if m.churros_eaten == 0:
		var front := Vector2(CHURRO_STAND.end.x + 24.0, CHURRO_STAND.get_center().y)
		if dp.distance_to(front) < BEG_REACH and m.dog.velocity.length() < BEG_STILL:
			m.gracia_beg_t += delta
			if m.gracia_beg_t >= BEG_T:
				m.churros_eaten = 1
				Sfx.play("snack")
				m.combo.add("CHURRO", 3)
				m.float_text(dp + Vector2(0, -26), "churro! +3", CHURRO_GOLD)
		else:
			m.gracia_beg_t = 0.0
