class_name Vet
extends RefCounted

# WALK 20: EL VETERINARI (The Clinic Escape Chase)
# An indoor veterinary clinic in Barcelona (Clínica Veterinària).
# Linoleum tile flooring with glossy light highlights, wall tiles, consultation
# room portholes, tandem waiting chairs with nervous pets in carriers, a digital
# pet scale, reception counter with treat jars, and automatic sliding glass doors.
# On the return leg, Millie panics at the consultation room threshold and bolts
# south while clinic assistants with giant cones of shame give chase!

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_bench", "draw_bin", "draw_bollard", "draw_edge_layer", "draw_live", "draw_overhead", "draw_threshold", "on_bark", "surface", "tick"]


const Rooms := preload("res://systems/vet_rooms.gd")
const Letters := preload("res://world/sign_letters.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

const SHADOW := Color(0.04, 0.05, 0.08, 0.18)

# --- colors ------------------------------------------------------------------

const WALL_BASEBOARD := Color(0.30, 0.60, 0.55)
const WALL_TRIM := Color(0.20, 0.45, 0.42)


const SCALE_BASE := Color(0.35, 0.38, 0.42)
const SCALE_MAT := Color(0.18, 0.20, 0.22)
const SCALE_DISPLAY := Color(0.12, 0.14, 0.16)
const SCALE_DIGITS := Color(0.25, 0.90, 0.40)

const COUNTER_WOOD := Color(0.68, 0.52, 0.38)
const COUNTER_TOP := Color(0.92, 0.90, 0.86)
const GLASS_PARTITION := Color(0.65, 0.85, 0.92, 0.45)

# the back door out to the recovery yard: an aluminium sill in the back wall,
# then a concrete apron through the gate, worn on into the grass
const SILL := Color(0.76, 0.78, 0.78)
const SILL_GROOVE := Color(0.52, 0.55, 0.56)
const APRON := Color(0.72, 0.72, 0.68)
const APRON_EDGE := Color(0.58, 0.58, 0.54)
const APRON_D := 30.0          # from the back wall to the yard's fence line

const DOOR_WOOD := Color(0.58, 0.42, 0.30)
const DOOR_FRAME := Color(0.35, 0.28, 0.22)
const PORTHOLE_GLASS := Color(0.70, 0.88, 0.92, 0.6)

const PILL_SHELF := Color(0.88, 0.88, 0.90)
const BOTTLE_AMBER := Color(0.85, 0.55, 0.18)
const BOTTLE_WHITE := Color(0.95, 0.95, 0.95)
const BOTTLE_BLUE := Color(0.20, 0.50, 0.80)

# --- corridor layout ---------------------------------------------------------
const WALL_L := 360.0
const WALL_R := 920.0
const CORRIDOR_HALF := 280.0

# Support / IV drip poles registered in m.poles (rope wrap and slingshot)
const IV_POLES: Array[Vector2] = [
	Vector2(420.0, -1000.0),
	Vector2(860.0, -1000.0),
	Vector2(420.0, -2100.0),
	Vector2(860.0, -2100.0),
	Vector2(420.0, -3200.0),
	Vector2(860.0, -3200.0),
	Vector2(420.0, -4100.0),
	Vector2(860.0, -4100.0),
]

# Digital pet scale platform at y = -1600.0
const SCALE_POS := Vector2(490.0, -1600.0)
const SCALE_SIZE := Vector2(74.0, 52.0)

# Reception desk counter at y = -2500.0
const RECEPTION_DESK := Rect2(362.0, -2540.0, 160.0, 70.0)

# Waiting chairs: pairs of molded clinic chairs along the east and west walls
const CHAIR_PAIRS: Array[Vector2] = [
	Vector2(395.0, -750.0),
	Vector2(885.0, -750.0),
	Vector2(885.0, -1350.0),
	Vector2(395.0, -1950.0),
	Vector2(885.0, -1950.0),
	Vector2(885.0, -2850.0),
	Vector2(395.0, -3550.0),
	Vector2(885.0, -3550.0),
]

# Medicine display cabinets (solid obstacles against walls)
const CABINET_WEST := Rect2(362.0, -3150.0, 50.0, 110.0)
const CABINET_EAST := Rect2(868.0, -3150.0, 50.0, 110.0)

# Consultation doors along walls (portholes)
const DOORS: Array[Dictionary] = [
	{"pos": Vector2(360.0, -1200.0), "name": "CONSULTA 1", "east": false},
	{"pos": Vector2(920.0, -1650.0), "name": "CONSULTA 2", "east": true},
	{"pos": Vector2(360.0, -2200.0), "name": "RADIOGRAFIA", "east": false},
	{"pos": Vector2(920.0, -2400.0), "name": "LABORATORI", "east": true},
	{"pos": Vector2(360.0, -3800.0), "name": "CIRURGIA", "east": false},
	{"pos": Vector2(920.0, -3800.0), "name": "QUARANTENA", "east": true},
]

# Hazardous prize: Liver treat jar on the reception desk
const PRIZE := Vector2(440.0, -2510.0)
const PRIZE_TEXT := "raid the liver treat jar on the reception desk"

# Where the chase home holds them (home_chase.VET_BANDS): a cat hissing in its
# carrier on the west wall, then a patient on the scale. They had none before:
# the bands named jams that were never placed.
const CHASE_JAMS: Array[Vector2] = [Vector2(395.0, -3600.0), Vector2(490.0, -1650.0)]

# Cat carrier spots (nervous cats that hiss when barked at or approached)
const CAT_CARRIERS: Array[Vector2] = [
	Vector2(885.0, -1350.0),
	Vector2(395.0, -3550.0),
]


static func letters(c: ShapeBatch, txt: String, at: Vector2, h: float, col: Color, w: float = 1.6, max_w: float = INF) -> void:
	var lay: Array = Letters.layout(txt, at, h, max_w)
	for pl: PackedVector2Array in lay[0]:
		for i in range(pl.size()):
			c.circle(pl[i], w * 0.5, col)
			if i > 0:
				c.line(pl[i - 1], pl[i], col, w)


# --- corridor geometry -------------------------------------------------------
static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": -600.0, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": -1200.0, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": -2200.0, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": -3200.0, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": -4200.0, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": CORRIDOR_HALF},
		{"y": m.GATE_Y, "cx": 640.0, "half": CORRIDOR_HALF},
	]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [
		RECEPTION_DESK,
		CABINET_WEST,
		CABINET_EAST,
	]


static func wrap_rects() -> Array[Rect2]:
	return [
		RECEPTION_DESK,
		CABINET_WEST,
		CABINET_EAST,
	]


# --- build -------------------------------------------------------------------
static func build(m: Node2D) -> Array:
	m.gate_text = "CLÍNICA VETERINÀRIA"
	m.chase_jams.clear()
	for j: Vector2 in CHASE_JAMS:
		m.chase_jams.append(j)
	m.patches.clear()
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(880.0, -2250.0)], TYPE_VECTOR2, &"", null)  # water cooler dispenser
	if not m.tutorial_mode:
		m.cone_dog = ConeDog.new()

	# Clinical waste bins (sanitary pedal bins with yellow/grey lids)
	m.bins = Array([
		Vector2(390.0, -900.0),
		Vector2(890.0, -1800.0),
		Vector2(390.0, -2700.0),
		Vector2(890.0, -3700.0),
	], TYPE_VECTOR2, &"", null)

	# Benches: waiting chairs
	m.benches = Array([], TYPE_VECTOR2, &"", null)
	for cp: Vector2 in CHAIR_PAIRS:
		m.benches.append(cp)

	# IV poles and support columns registered in m.poles for wrapping and slingshots
	for p: Vector2 in IV_POLES:
		m.poles.append(p)

	# Sniffable landmarks (hydrants):
	# 1. Entrance registration bell
	# 2. Digital pet scale
	# 3. Cat carrier
	# 4. Medicine cabinet
	# 5. Examination room threshold
	var marks: Array[Vector2] = [
		Vector2(450.0, -780.0),
		SCALE_POS,
		CAT_CARRIERS[0],
		Vector2(420.0, -3150.0),
		Vector2(640.0, -4400.0),
	]

	# Snacks: dropped liver treats, dog biscuits, and pill pockets
	var snacks: Array[Vector2] = [
		Vector2(580.0, -850.0),
		Vector2(740.0, -1700.0),
		Vector2(550.0, -2650.0),
		Vector2(480.0, -3600.0),
	]

	# just mopped: two wet patches on the linoleum, each with its yellow
	# wet-floor sign stood beside it (LevelBuild.CONE_KINDS). Drawn as a thin
	# glossy film (main._draw_spill), not an outdoor puddle.
	var spills: Array[Dictionary] = [
		{"y": -1450.0, "at": 0.35, "rx": 34.0, "ry": 24.0, "seed": 7.1,
			"kind": "puddle", "spill": true, "splashes": true},
		{"y": -2850.0, "at": 0.65, "rx": 36.0, "ry": 26.0, "seed": 7.2,
			"kind": "puddle", "spill": true, "splashes": true},
	]
	var signs: Array[Vector2] = []
	for sp: Dictionary in spills:
		m.patches.append(sp)
		var c: Vector2 = m.patch_centre(sp)
		signs.append(c + Vector2(float(sp["rx"]) + 18.0, -float(sp["ry"]) * 0.4))
	m.cone_spots = Array(signs, TYPE_VECTOR2, &"", null)

	return [marks, snacks]


# --- drawing -----------------------------------------------------------------
static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float = 0.0, vb: float = 0.0) -> void:
	if m.lvl != "vet":
		return

	# the clinic ends at its back wall on the gate line; the recovery yard's
	# grass is beyond it, so nothing of the corridor runs on past it
	var back: float = m.GATE_Y
	var top := maxf(vt, back)
	if top < vb:
		Rooms.draw(b, vt, vb, back)
		Rooms.floor(b, top, vb)
	if back >= vt - 40.0 and back <= vb + 40.0:
		_draw_back_wall(b, back)

	# Consultation room door frames and signs
	for d: Dictionary in DOORS:
		var dp: Vector2 = d["pos"]
		if dp.y < vt - 80.0 or dp.y > vb + 80.0:
			continue
		var is_east: bool = d["east"]
		var door_rect := Rect2(dp.x - 4.0 if not is_east else dp.x - 12.0, dp.y - 35.0, 16.0, 70.0)
		b.rect(door_rect, DOOR_WOOD)
		# porthole window
		var porthole_c := Vector2(dp.x + (4.0 if not is_east else -4.0), dp.y)
		b.circle(porthole_c, 10.0, DOOR_FRAME)
		b.circle(porthole_c, 8.0, PORTHOLE_GLASS)
		# brass door handle
		b.circle(Vector2(dp.x + (10.0 if not is_east else -10.0), dp.y + 14.0), 3.0, Color(0.85, 0.72, 0.25))

	# Pet scale drawing
	if SCALE_POS.y >= vt - 80.0 and SCALE_POS.y <= vb + 80.0:
		var sr := Rect2(SCALE_POS - SCALE_SIZE * 0.5, SCALE_SIZE)
		b.rect(sr.grow(3.0), SHADOW)
		b.rect(sr, SCALE_BASE)
		b.rect(sr.grow(-4.0), SCALE_MAT)
		# ribbed rubber mat lines
		for i in range(5):
			var ly := sr.position.y + 10.0 + i * 8.0
			b.line(Vector2(sr.position.x + 8.0, ly), Vector2(sr.end.x - 8.0, ly), Color(0.12, 0.14, 0.15), 1.5)
		# digital LCD display
		var dr := Rect2(sr.position.x + sr.size.x * 0.5 - 18.0, sr.position.y - 12.0, 36.0, 14.0)
		b.rect(dr, SCALE_DISPLAY)
		# digital readout
		var weight_text := "14.2" if m.get("vet_scale_weighed") else "--.-"
		letters(b, weight_text, Vector2(dr.position.x + 4.0, dr.position.y + 3.0), 7.0, SCALE_DIGITS, 1.2)

	# Reception desk drawing
	if RECEPTION_DESK.position.y >= vt - 120.0 and RECEPTION_DESK.end.y <= vb + 120.0:
		b.rect(RECEPTION_DESK.grow(4.0), SHADOW)
		b.rect(RECEPTION_DESK, COUNTER_WOOD)
		b.rect(Rect2(RECEPTION_DESK.position.x + 2.0, RECEPTION_DESK.position.y + 2.0, RECEPTION_DESK.size.x - 4.0, 16.0), COUNTER_TOP)
		b.rect(Rect2(RECEPTION_DESK.position.x + 12.0, RECEPTION_DESK.position.y - 10.0, RECEPTION_DESK.size.x - 24.0, 10.0), GLASS_PARTITION)
		# reception bell
		b.circle(Vector2(RECEPTION_DESK.position.x + 30.0, RECEPTION_DESK.position.y + 8.0), 5.0, Color(0.85, 0.75, 0.25))
		b.circle(Vector2(RECEPTION_DESK.position.x + 30.0, RECEPTION_DESK.position.y + 8.0), 2.0, Color(0.4, 0.35, 0.15))

	# Medicine display cabinets
	for cab: Rect2 in [CABINET_WEST, CABINET_EAST]:
		if cab.position.y >= vt - 120.0 and cab.end.y <= vb + 120.0:
			b.rect(cab.grow(4.0), SHADOW)
			b.rect(cab, PILL_SHELF)
			# colorful pill boxes on shelves
			for row in range(3):
				var sy := cab.position.y + 16.0 + row * 32.0
				b.line(Vector2(cab.position.x + 4.0, sy), Vector2(cab.end.x - 4.0, sy), Color(0.75, 0.78, 0.80), 2.0)
				b.rect(Rect2(cab.position.x + 8.0, sy - 14.0, 10.0, 12.0), BOTTLE_AMBER)
				b.rect(Rect2(cab.position.x + 22.0, sy - 12.0, 8.0, 10.0), BOTTLE_WHITE)
				b.rect(Rect2(cab.position.x + 34.0, sy - 15.0, 10.0, 13.0), BOTTLE_BLUE)

	# Cat carriers on waiting chairs
	for ccp: Vector2 in CAT_CARRIERS:
		if ccp.y < vt - 60.0 or ccp.y > vb + 60.0:
			continue
		var cr := Rect2(ccp - Vector2(14.0, 10.0), Vector2(28.0, 20.0))
		b.rect(cr.grow(2.0), SHADOW)
		b.rect(cr, Color(0.20, 0.55, 0.50))
		# carrier grill door
		b.rect(Rect2(cr.position.x + 2.0, cr.position.y + 2.0, 8.0, cr.size.y - 4.0), Color(0.2, 0.22, 0.25))
		for g in range(3):
			var gx := cr.position.x + 3.0 + g * 2.0
			b.line(Vector2(gx, cr.position.y + 3.0), Vector2(gx, cr.end.y - 3.0), Color(0.7, 0.72, 0.75), 1.0)
		# nervous glowing cat eyes behind grill
		b.circle(Vector2(cr.position.x + 5.0, ccp.y - 2.0), 1.2, Color(0.95, 0.90, 0.20))
		b.circle(Vector2(cr.position.x + 5.0, ccp.y + 2.0), 1.2, Color(0.95, 0.90, 0.20))


# the clinic's back wall along the yard, either side of the door: the
# corridor's skirting turns the corner and runs along it, and the wall's
# foot settles into the grass instead of a ruled line
static func _draw_back_wall(b: ShapeBatch, y: float) -> void:
	for run: Vector2 in [Vector2(-400.0, WALL_L), Vector2(WALL_R, 1700.0)]:
		b.band(PackedVector2Array([Vector2(run.x, y - 16.0), Vector2(run.y, y - 16.0),
			Vector2(run.x, y), Vector2(run.y, y)]), 2, SHADOW, PackedFloat32Array([0.0, 1.0]))
		b.rect(Rect2(run.x, y, run.y - run.x, 8.0), WALL_BASEBOARD)
		b.line(Vector2(run.x, y), Vector2(run.y, y), WALL_TRIM, 2.0)


# main._draw_threshold: the back door. The floor stops at an aluminium sill in
# the back wall; a short concrete apron runs through the gate to the yard's
# fence line, and the way everyone walks out wears on into the grass.
static func draw_threshold(m: Node2D, b: ShapeBatch) -> void:
	var y: float = m.GATE_Y
	var x0 := WALL_L - 8.0
	var x1 := WALL_R + 8.0
	var ay := y - APRON_D
	b.rect(Rect2(x0, ay, x1 - x0, APRON_D), APRON)
	var jx := WALL_L + 60.0
	while jx < WALL_R - 1.0:
		b.line(Vector2(jx, ay), Vector2(jx, y), APRON_EDGE, 1.2)
		jx += 60.0
	b.rect(Rect2(x0, ay, x1 - x0, 2.5), APRON_EDGE)
	b.glow(Vector2(640.0, ay - 6.0), 96.0, Color(APRON.r, APRON.g, APRON.b, 0.42), 0.35)
	# grass over the apron's far edge, by a hash along it
	var tx := x0 + 6.0
	while tx < x1 - 6.0:
		var hh := fmod(sin(tx * 12.9898) * 43758.5453, 1.0)
		hh = hh if hh >= 0.0 else hh + 1.0
		if hh > 0.35 and absf(tx - 640.0) > 70.0:
			var g := Color(0.30, 0.46, 0.29).darkened(0.12 * hh)
			b.line(Vector2(tx, ay - 2.0), Vector2(tx - 3.0, ay + 4.0 + hh * 4.0), g, 2.0)
			b.line(Vector2(tx, ay - 2.0), Vector2(tx + 3.0, ay + 3.0 + hh * 3.0), g, 2.0)
		tx += 9.0 + hh * 8.0
	b.rect(Rect2(WALL_L, y - 3.0, WALL_R - WALL_L, 7.0), SILL)
	b.rect(Rect2(WALL_L, y - 3.0, WALL_R - WALL_L, 1.5), SILL.lightened(0.2))
	b.line(Vector2(WALL_L, y + 1.0), Vector2(WALL_R, y + 1.0), SILL_GROOVE, 1.2)
	b.rect(Rect2(WALL_L, y + 4.0, WALL_R - WALL_L, 2.0), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.12))


# --- interactive checks (scale, cat hiss) -----------------------------------
const EventFeed := preload("res://hud/event_feed.gd")
const CAT_HISS_R := 85.0
const HISS_COLOR := Color(0.95, 0.90, 0.20)
const BEEP_COLOR := Color(0.25, 0.90, 0.40)


# The cone dog moves, so she is drawn on the world pass, not the cached edge.
# the waiting chairs are what there is to sit on
static func draw_bench(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	Rooms.chairs(wc, p)


# a pedal bin, yellow for clinical waste
static func draw_bin(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	Rooms.bin(wc, p)


# only marks that have nothing of their own to show are drawn: the rest are
# the scale, a carrier and a cabinet
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var p: Vector2 = h.pos
	if p.distance_to(SCALE_POS) > 10.0 and p.distance_to(CAT_CARRIERS[0]) > 10.0 and absf(p.y + 3150.0) > 10.0:
		# a rubber plant in its pot, every dog's first choice
		Rooms._plant(wc, p)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(p, 26.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
	elif h.done:
		wc.ellipse(p + Vector2(5, 13), 11.0, 4.5, Color(0.92, 0.84, 0.40, 0.5))


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	for p: Vector2 in IV_POLES:
		if p.y > vt - 40.0 and p.y < vb + 40.0:
			Rooms.drip(wc, p)
	if m.cone_dog != null:
		m.cone_dog.draw(m, wc, vt, vb)


static func tick(m: Node2D, _delta: float) -> void:
	if m.lvl != "vet":
		return
	# the pet scale weighs her once a walk
	if not m.vet_scale_weighed:
		var sr := Rect2(SCALE_POS - SCALE_SIZE * 0.5, SCALE_SIZE)
		if sr.has_point(m.dog.global_position):
			m.vet_scale_weighed = true
			m.feed.say(I18n.t("w_weigh_in_14_2_kg"), EventFeed.Tone.GOOD)
			m.float_text(SCALE_POS, I18n.t("w_beep"), BEEP_COLOR)


# main.on_bark: a bark beside a cat carrier gets a hiss back, every time
static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lvl != "vet":
		return
	for ccp: Vector2 in CAT_CARRIERS:
		if pos.distance_to(ccp) < CAT_HISS_R:
			m.float_text(ccp, I18n.t("w_hisss"), HISS_COLOR)

# main.surface_at, through walk_mod: the ground here, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


# nothing overhead in the clinic's street; defined so main draws none of its own
static func draw_overhead(_m: Node2D, _ci: CanvasItem) -> void:
	pass
