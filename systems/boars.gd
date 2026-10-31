class_name Boars
extends RefCounted

# WALK 25: ELS SENGLARS (Collserola). A dirt trail up through the holm oaks to
# El Mirador, the same wood as El Bosc (systems/bosc.gd draws it), with the
# boars' own business along it: two dumpsters they have tipped over, the
# picnic table they raid, fallen oaks across the path and the mud they wallow
# in. On the way home the sounder comes down the trail after you; the
# dumpsters are where it stops to feed (home_chase.BOAR_BANDS).

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")

const HALF := 260.0
const WALL_L := 380.0
const WALL_R := 900.0

const PRIZE := Vector2(640.0, -4420.0)
const PRIZE_TEXT := "find the golden acorn on the trail"

const DIRT_DARK := Color(0.28, 0.20, 0.12)
const MUD_BROWN := Color(0.22, 0.16, 0.10)
const WOOD_BARK := Color(0.32, 0.22, 0.14)
const WOOD_SAWN := Color(0.65, 0.52, 0.36)
const BIN_GREEN := Color(0.20, 0.42, 0.26)
const BIN_DARK := Color(0.12, 0.28, 0.17)
const BIN_LID := Color(0.16, 0.34, 0.21)
const LITTER: Array[Color] = [
	Color(0.92, 0.90, 0.84), Color(0.86, 0.36, 0.22), Color(0.95, 0.80, 0.30),
	Color(0.40, 0.62, 0.80), Color(0.78, 0.78, 0.74),
]

# The dumpsters the chase snags on (home_chase.BOAR_BANDS: -3400 and -1900)
const DUMPSTER_SIZE := Vector2(90.0, 50.0)
const DUMPSTER_JAM_1 := Vector2(500.0, -3400.0)
const DUMPSTER_JAM_2 := Vector2(780.0, -1900.0)

# Fallen oaks across part of the trail
const LOG_1 := Rect2(410.0, -1250.0, 160.0, 32.0)
const LOG_2 := Rect2(710.0, -2700.0, 160.0, 32.0)
const PICNIC_TABLE := Rect2(580.0, -3440.0, 120.0, 60.0)

# the mud wallows (main.patches, kind "mud")
const MUD_SPOTS: Array[Vector2] = [Vector2(610.0, -1100.0), Vector2(670.0, -2300.0), Vector2(630.0, -3100.0)]
const MUD_SPEED := 140.0
const MUD_CD := 0.8

# Holm oaks along the trail edge, then a few standing out on the path itself:
# the ones to swing round
const BOAR_TREES: Array[Vector2] = [
	Vector2(395.0, -400.0), Vector2(885.0, -420.0),
	Vector2(400.0, -850.0), Vector2(880.0, -920.0),
	Vector2(390.0, -1450.0), Vector2(890.0, -1500.0),
	Vector2(405.0, -2100.0), Vector2(875.0, -2150.0),
	Vector2(395.0, -2650.0), Vector2(885.0, -2750.0),
	Vector2(400.0, -3250.0), Vector2(880.0, -3320.0),
	Vector2(390.0, -3850.0), Vector2(890.0, -3900.0),
	Vector2(405.0, -4350.0), Vector2(875.0, -4400.0),
	Vector2(560.0, -700.0), Vector2(720.0, -1650.0),
	Vector2(560.0, -2950.0), Vector2(730.0, -3950.0),
]


static func build(m: Node2D) -> Array:
	m.gate_text = "EL MIRADOR"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 420.0
	m.gate_r = 860.0

	# the oaks are the drawn poles (forest trees, main.pole_tree); the log ends
	# and the table's corners after them are wrap points, drawn with their props
	for tp: Vector2 in BOAR_TREES:
		m.poles.append(tp)
	m.deco_pole_count = m.poles.size()
	m.poles.append(Vector2(LOG_1.position.x + 10.0, LOG_1.get_center().y))
	m.poles.append(Vector2(LOG_1.end.x - 10.0, LOG_1.get_center().y))
	m.poles.append(Vector2(LOG_2.position.x + 10.0, LOG_2.get_center().y))
	m.poles.append(Vector2(LOG_2.end.x - 10.0, LOG_2.get_center().y))
	m.poles.append(Vector2(PICNIC_TABLE.position.x + 10.0, PICNIC_TABLE.position.y + 10.0))
	m.poles.append(Vector2(PICNIC_TABLE.end.x - 10.0, PICNIC_TABLE.position.y + 10.0))
	m.poles.append(Vector2(PICNIC_TABLE.position.x + 10.0, PICNIC_TABLE.end.y - 10.0))
	m.poles.append(Vector2(PICNIC_TABLE.end.x - 10.0, PICNIC_TABLE.end.y - 10.0))

	m.benches = Array([
		Vector2(420.0, -1800.0),
		Vector2(860.0, -3440.0),  # clear of the oak at -3320
		Vector2(640.0, -4300.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(420.0, -600.0),
		Vector2(860.0, -2200.0),
		Vector2(420.0, -3600.0),
	], TYPE_VECTOR2, &"", null)

	var seeds: Array[float] = [1.7, 2.4, 3.9]
	var rx: Array[float] = [80.0, 90.0, 85.0]
	for i in range(MUD_SPOTS.size()):
		var mp: Vector2 = MUD_SPOTS[i]
		m.patches.append({
			"y": mp.y, "at": (mp.x - WALL_L) / (WALL_R - WALL_L), "rx": rx[i], "ry": rx[i] * 0.44,
			"seed": seeds[i], "kind": "mud", "pin": mp,
		})

	# the chase's respites, on the near side of each dumpster as it comes down
	m.chase_jams.clear()
	for d: Vector2 in [DUMPSTER_JAM_1, DUMPSTER_JAM_2]:
		m.chase_jams.append(Vector2(d.x, d.y - DUMPSTER_SIZE.y * 0.5 - 4.0))

	# way marker posts for hydrants
	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 30.0, -500.0),
		Vector2(WALL_R - 30.0, -1600.0),  # clear of the oak at -1500
		Vector2(WALL_L + 30.0, -2500.0),
		Vector2(WALL_R - 30.0, -3500.0),
		Vector2(WALL_L + 30.0, -4300.0),
	]

	# dropped bocadillos
	var keb_list: Array[Vector2] = [
		Vector2(620.0, -1600.0),
		Vector2(700.0, -2900.0),
		Vector2(550.0, -3700.0),
	]

	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT
	return [hyd_list, keb_list]


const DUMPSTERS: Array[Rect2] = [
	Rect2(DUMPSTER_JAM_1 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE),
	Rect2(DUMPSTER_JAM_2 - DUMPSTER_SIZE * 0.5, DUMPSTER_SIZE),
]
const LOGS: Array[Rect2] = [LOG_1, LOG_2]


static func dumpsters() -> Array[Rect2]:
	return DUMPSTERS


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = [LOG_1, LOG_2, PICNIC_TABLE]
	out.append_array(dumpsters())
	return out


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_FOREST


# --- main's walk hooks: El Bosc's wood and trail edges, Els Senglars' props ---

static func grass_blocked(m: Node2D, p: Vector2) -> bool:
	return Bosc.grass_blocked(m, p)


# the trail's frayed verges in place of main's kerbs, on the edges main walks
static func draw_path_edges(m: Node2D, left: PackedVector2Array, right: PackedVector2Array, col: Color) -> void:
	Bosc._draw_edges(m, left, right, col)


static func draw_scenery(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	Bosc._draw_wood(m, vt, vb)
	for lr: Rect2 in LOGS:
		if lr.end.y > vt - 60.0 and lr.position.y < vb + 60.0:
			Bosc._draw_fallen_log(m, lr)
	var b := ShapeBatch.new()
	if PICNIC_TABLE.end.y > vt - 80.0 and PICNIC_TABLE.position.y < vb + 80.0:
		_draw_picnic(m, b)
	for i in range(2):
		var d: Rect2 = DUMPSTERS[i]
		if d.end.y > vt - 80.0 and d.position.y < vb + 80.0:
			_draw_dumpster(m, b, d, i)
	for mp: Vector2 in MUD_SPOTS:
		if mp.y > vt - 80.0 and mp.y < vb + 80.0:
			_draw_wallow(b, mp)
	b.flush(m._wc)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	Bosc.draw_bocadillo(m, wc, kp)


# the picnic table, raided: benches either side, a cloth half off, a basket
# on its side and its crumbs trodden into the dirt
static func _draw_picnic(m: Node2D, b: ShapeBatch) -> void:
	var t := PICNIC_TABLE
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)
	b.rect(Rect2(t.position + m.LIGHT * 8.0, t.size), sh)
	for by: float in [t.position.y - 14.0, t.end.y + 4.0]:
		b.rect(Rect2(t.position.x + 6.0, by + 3.0, t.size.x - 12.0, 10.0), sh)
		b.rect(Rect2(t.position.x + 6.0, by, t.size.x - 12.0, 10.0), WOOD_BARK)
		b.rect(Rect2(t.position.x + 6.0, by, t.size.x - 12.0, 3.0), WOOD_SAWN.darkened(0.2))
	b.rect(t, WOOD_SAWN.darkened(0.12))
	var py := t.position.y + 4.0
	while py < t.end.y - 2.0:
		b.rect(Rect2(t.position.x + 2.0, py, t.size.x - 4.0, 11.0), WOOD_SAWN)
		py += 14.0
	# the cloth, dragged half off the end
	b.polygon(PackedVector2Array([
		t.position + Vector2(18, 6), t.position + Vector2(70, 2), t.position + Vector2(84, 40),
		t.position + Vector2(64, 74), t.position + Vector2(30, 62),
	]), Color(0.86, 0.28, 0.24))
	for k in range(4):
		b.line(t.position + Vector2(24 + k * 14, 8), t.position + Vector2(36 + k * 12, 66), Color(0.96, 0.94, 0.90, 0.8), 2.0)
	# the basket on its side, and what came out of it
	var bk := t.position + Vector2(96, 42)
	b.circle(bk + m.LIGHT * 3.0, 13.0, sh)
	b.circle(bk, 12.0, Color(0.62, 0.44, 0.24))
	b.circle(bk + Vector2(-2, -2), 8.0, Color(0.72, 0.54, 0.30))
	for k in range(5):
		var cp := bk + Vector2(14 + k * 7, -8 + (k % 3) * 9)
		b.circle(cp, 2.4, LITTER[k % LITTER.size()])


# a green municipal dumpster on its side, the lid flung open and rubbish
# spilled out of its mouth across the trail
static func _draw_dumpster(m: Node2D, b: ShapeBatch, d: Rect2, i: int) -> void:
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.30)
	var mouth := -1.0 if i == 0 else 1.0
	b.rect(Rect2(d.position + m.LIGHT * 9.0, d.size), sh)
	b.rect(d, BIN_DARK)
	b.rect(d.grow(-3.0), BIN_GREEN)
	for k in range(4):
		var rx := d.position.x + 14.0 + float(k) * 20.0
		b.line(Vector2(rx, d.position.y + 5.0), Vector2(rx, d.end.y - 5.0), BIN_DARK, 2.5)
	b.rect(Rect2(d.position.x + 4.0, d.position.y + 4.0, d.size.x - 8.0, 6.0), BIN_GREEN.lightened(0.18))
	# the wheels, in the air
	for wx: float in [d.position.x + 12.0, d.end.x - 12.0]:
		b.circle(Vector2(wx, d.end.y - 2.0), 6.0, Color(0.12, 0.12, 0.13))
		b.circle(Vector2(wx, d.end.y - 2.0), 2.5, Color(0.38, 0.38, 0.40))
	# the lid, flung open on its hinge
	var hx: float = d.end.x if mouth > 0.0 else d.position.x
	b.polygon(PackedVector2Array([
		Vector2(hx, d.position.y + 4.0), Vector2(hx + mouth * 30.0, d.position.y - 10.0),
		Vector2(hx + mouth * 38.0, d.end.y - 18.0), Vector2(hx, d.end.y - 4.0),
	]), BIN_LID)
	# the spill
	for k in range(9):
		var h := fmod(absf(sin(float(k) * 12.9898 + float(i) * 7.1) * 43758.5453), 1.0)
		var sp := Vector2(hx + mouth * (16.0 + h * 46.0), d.get_center().y + (float(k) - 4.0) * 7.0 + (h - 0.5) * 8.0)
		b.circle(sp + m.LIGHT * 1.5, 4.0, sh)
		b.circle(sp, 3.0 + h * 2.0, LITTER[k % LITTER.size()])
	b.polygon(PackedVector2Array([
		Vector2(hx + mouth * 12.0, d.get_center().y - 8.0), Vector2(hx + mouth * 34.0, d.get_center().y - 14.0),
		Vector2(hx + mouth * 40.0, d.get_center().y + 2.0), Vector2(hx + mouth * 16.0, d.get_center().y + 8.0),
	]), Color(0.14, 0.14, 0.15))


# hoof prints churned round the wallow, which main draws as a mud patch
static func _draw_wallow(b: ShapeBatch, at: Vector2) -> void:
	for k in range(10):
		var a := float(k) * (TAU / 10.0) + 0.3
		var p := at + Vector2(cos(a) * 104.0, sin(a) * 48.0)
		var r := Vector2.from_angle(a + PI * 0.5) * 3.0
		b.circle(p - r, 2.6, DIRT_DARK)
		b.circle(p + r, 2.6, DIRT_DARK)


static func tick(m: Node2D, delta: float) -> void:
	# mud: once per wallow she hits at speed, not every frame she is in it
	m.boar_mud_cd = maxf(0.0, m.boar_mud_cd - delta)
	if m.boar_mud_cd <= 0.0 and m.dog.velocity.length() > MUD_SPEED \
			and m.surface_at(m.dog.global_position) == Surfaces.S.MUD:
		m.boar_mud_splashes += 1
		m.boar_mud_cd = MUD_CD
		Sfx.play("squelch", 0.9)
		m.combo.add("WALLOW", 3)
		m.float_text(m.dog.global_position + Vector2(0, -26), "splat!", Color(0.72, 0.56, 0.36))
	# a pole swing landed round one of the oaks
	if m.vaults_landed > m.boar_vaults_seen:
		m.boar_vaults_seen = m.vaults_landed
		for tp: Vector2 in BOAR_TREES:
			if tp.distance_to(m.vault_done_pole) < 4.0:
				m.boar_swings += 1
				break
