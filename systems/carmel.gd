class_name Carmel
extends RefCounted

# WALK 28: ELS BÚNQUERS DEL CARMEL (The Sunset Overlook)
#
# Turó de la Rovira at dusk: Spanish Civil War anti-aircraft bunker battery (1937)
# perched 262 m above Barcelona. The climb begins along Baixada de la Glòria with the
# iconic outdoor escalators (Les Escales Mecàniques) rising beside the street. The path
# transitions into winding sauló gravel switchbacks lined with Aleppo pines, rosemary,
# and timber balustrades.
#
# At the summit plateau, the concrete cylindrical cannon emplacements, observation post
# bunker slabs, and 360-degree panoramic view over the whole city grid, Sagrada Família,
# and Mediterranean sea glowing under the brilliant golden hour sunset.
#
# Gameplay features:
# - Circular concrete cannon parapets: cylindrical concrete obstacles that catch and wrap the rope.
# - Escalator handrails: grindable rails (systems/rails.gd) running along the lower stretch.
# - The sunset mirador: standing still at the overlook with your human triggers the view goal.
# - Live event: El Guitarrista del Carmel (systems/guitarrista.gd) playing sunset rumba.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Guitarrista := preload("res://systems/guitarrista.gd")
const Surfaces := preload("res://world/surfaces.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.07, 0.24)

# --- colors ------------------------------------------------------------------
const SAULO := Color(0.78, 0.68, 0.52)          # pale decomposed granite grit
const SAULO_RUT := Color(0.68, 0.58, 0.44)
const SAULO_EDGE := Color(0.60, 0.52, 0.38)
const PEBBLE := Color(0.86, 0.80, 0.70)
const CONCRETE_BASE := Color(0.64, 0.62, 0.58)  # 1937 weathered bunker concrete
const CONCRETE_LIT := Color(0.84, 0.78, 0.68)   # lit by golden sunset
const CONCRETE_DARK := Color(0.42, 0.40, 0.38)
const CONCRETE_LIP := Color(0.74, 0.72, 0.66)
const PINE_CROWN := Color(0.24, 0.38, 0.22)
const PINE_TRUNK := Color(0.44, 0.28, 0.18)
const AGAVE_LEAF := Color(0.38, 0.52, 0.46)
const TIMBER := Color(0.52, 0.38, 0.24)
const TIMBER_LIT := Color(0.64, 0.49, 0.32)
const STEEL_RAIL := Color(0.24, 0.24, 0.26)
const TREAD_RIB := Color(0.30, 0.30, 0.32)
const HAZE_SUNSET := Color(0.76, 0.62, 0.58)    # warm rose sunset haze
const CITY_BLOCK := Color(0.74, 0.64, 0.60)
const SEA_GLINT := Color(0.96, 0.86, 0.70, 0.65)

# --- layout ------------------------------------------------------------------
const HALF := 280.0

# Lower outdoor escalators
const ESCALATOR_ZONE := Rect2(820.0, -960.0, 68.0, 880.0)

# Circular cannon battery emplacements (cylindrical parapets)
const CANNON_1 := Vector2(530.0, -3200.0)
const CANNON_1_R := 54.0
const CANNON_2 := Vector2(740.0, -3750.0)
const CANNON_2_R := 54.0
const CANNON_3 := Vector2(640.0, -4550.0)
const CANNON_3_R := 60.0

# Command observation bunker (concrete block with doorway recess)
const BUNKER := Rect2(470.0, -4200.0, 130.0, 100.0)

# The sunset mirador: wide bulge on the drop side at the summit
const MIRADOR_Y := -4550.0
const MIRADOR_SPOT := Vector2(400.0, -4550.0)
const MIRADOR_R := 74.0
const VIEW_STILL := 18.0
const VIEW_HOLD := 1.0
const VIEW_REACH := 260.0

# Summit picnic prize
const PRIZE := Vector2(710.0, -4520.0)
const PRIZE_TEXT := "snatch the bravas from the sunset picnic blanket"

const FENCE_STEP := 160.0
const FENCE_IN := 6.0

# Aleppo pines along the mountain edges
const PINES: Array[Vector2] = [
	Vector2(410.0, -620.0), Vector2(870.0, -1180.0),
	Vector2(400.0, -1640.0), Vector2(880.0, -2150.0),
	Vector2(410.0, -2650.0), Vector2(880.0, -3050.0),
	Vector2(880.0, -4200.0),
]


static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 240.0},
		{"y": -520.0, "cx": 630.0, "half": 240.0},
		{"y": -1120.0, "cx": 650.0, "half": 235.0},
		{"y": -1700.0, "cx": 600.0, "half": 230.0},
		{"y": -2280.0, "cx": 670.0, "half": 235.0},
		{"y": -2880.0, "cx": 610.0, "half": 240.0},
		{"y": -3480.0, "cx": 660.0, "half": 250.0},
		{"y": -4080.0, "cx": 620.0, "half": 260.0},
		{"y": -4550.0, "cx": 640.0, "half": 275.0},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": 270.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 275.0},
	]


static func solids(m: Node2D) -> Array[Rect2]:
	return [BUNKER]


static func cannons() -> Array[Vector3]:
	return [
		Vector3(CANNON_1.x, CANNON_1.y, CANNON_1_R),
		Vector3(CANNON_2.x, CANNON_2.y, CANNON_2_R),
		Vector3(CANNON_3.x, CANNON_3.y, CANNON_3_R),
	]


static func fence_posts(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var y: float = m.START_Y - 140.0
	while y > m.GATE_Y + 160.0:
		if y > -1000.0:
			y -= FENCE_STEP
			continue
		var e: Vector2 = m.walk_edges(y)
		out.append(Vector2(e.x + FENCE_IN, y))
		y -= FENCE_STEP
	return out


static func build(m: Node2D) -> Array:
	m.gate_text = "BUNQUERS DEL CARMEL"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)

	# The live event guitarist
	if not m.tutorial_mode:
		m.guitarrista = Guitarrista.new()

	# Static solid bodies: the command bunker
	m.conveyor_dir = Vector2(0, -1)
	m.conveyor_zone = ESCALATOR_ZONE

	# Poles: Aleppo pines, fence posts, and cannon battery cylinders
	for pp: Vector2 in PINES:
		m.poles.append(pp)
	m.deco_pole_count = m.poles.size()

	for fp: Vector2 in fence_posts(m):
		m.poles.append(fp)

	# Circular cannon battery parapets as thick rope poles
	m.poles.append(CANNON_1)
	m.poles.append(CANNON_2)
	m.poles.append(CANNON_3)

	# Benches along viewpoint edges
	m.benches = Array([
		Vector2(430.0, -1800.0),
		Vector2(850.0, -2700.0),
		Vector2(410.0, -3650.0),
		Vector2(420.0, -4500.0),
		Vector2(840.0, -4500.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(850.0, -800.0),
		Vector2(430.0, -2100.0),
		Vector2(860.0, -3400.0),
		Vector2(430.0, -4400.0),
	], TYPE_VECTOR2, &"", null)

	m.fountains = Array([
		Vector2(440.0, -1200.0),
		Vector2(830.0, -4600.0),
	], TYPE_VECTOR2, &"", null)

	# Mark spots: bunker corners, cannon rings, water font
	var marks: Array[Vector2] = [
		Vector2(440.0, -1200.0),
		Vector2(430.0, -2100.0),
		CANNON_1 + Vector2(0.0, -CANNON_1_R - 10.0),
		CANNON_2 + Vector2(0.0, -CANNON_2_R - 10.0),
		BUNKER.position + Vector2(16.0, 16.0),
		CANNON_3 + Vector2(0.0, -CANNON_3_R - 10.0),
		PRIZE,
	]

	# Dropped snacks: patates braves, churros, sunflower seeds
	var snacks: Array[Vector2] = [
		Vector2(580.0, -1450.0),
		Vector2(720.0, -2450.0),
		Vector2(510.0, -3350.0),
		Vector2(670.0, -4250.0),
	]

	return [marks, snacks]


static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_FOREST


static func surface(m: Node2D, p: Vector2) -> int:
	# Bunker concrete summits and escalators
	if ESCALATOR_ZONE.has_point(p):
		return Surfaces.S.TILE
	for c: Vector3 in cannons():
		if p.distance_to(Vector2(c.x, c.y)) < c.z:
			return Surfaces.S.TILE
	if BUNKER.has_point(p):
		return Surfaces.S.TILE
	return Surfaces.S.SAND  # sauló granite grit


static func tick(m: Node2D, delta: float) -> void:
	if m.guitarrista != null:
		m.guitarrista.tick(m, delta)

	# The sunset view goal: keep still at the mirador with your human
	if bool(m.get_meta("carmel_view", false)):
		return

	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	var near: bool = dp.distance_to(MIRADOR_SPOT) < MIRADOR_R and m.dog.velocity.length() < VIEW_STILL \
		and dp.distance_to(hp) < VIEW_REACH
	var held: float = float(m.get_meta("carmel_still", 0.0)) + delta if near else 0.0
	m.set_meta("carmel_still", held)
	if held >= VIEW_HOLD:
		m.set_meta("carmel_view", true)
		m.bones += 5
		m.combo.add("THE SUNSET", 5)
		m.float_text(hp + Vector2(0, -34), "Look at that sunset...", Color(1.0, 0.95, 0.90, 0.9), m.POP_SAY)
		m.float_text(dp + Vector2(0, -30), "sunset view! +5", Color(0.96, 0.86, 0.32))
		m.feed.say("YOUR HUMAN LOOKED UP!", EventFeed.Tone.GOOD)
		m.get_node("/root/Sfx").play("star", 1.1)


static func view_taken(m: Node2D) -> bool:
	return bool(m.get_meta("carmel_view", false))


static func on_bark(m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	if m.guitarrista != null:
		return m.guitarrista.on_bark(m)
	return false


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 30.0, ctop)
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	var step := 24.0
	var y := floorf(hi / step) * step
	var eb: Vector2 = m.walk_edges(y + step)

	while y > lo - step:
		var ea: Vector2 = m.walk_edges(y)
		wc.polygon(PackedVector2Array([Vector2(ea.x, y), Vector2(ea.y, y), Vector2(eb.y, y + step), Vector2(eb.x, y + step)]), SAULO)
		wc.line(Vector2(ea.x + 3.0, y), Vector2(eb.x + 3.0, y + step), SAULO_EDGE, 6.0)
		wc.line(Vector2(ea.y - 3.0, y), Vector2(eb.y - 3.0, y + step), SAULO_EDGE, 6.0)

		# Walking ruts along the trail
		for f: float in [0.38, 0.62]:
			wc.line(Vector2(lerpf(ea.x, ea.y, f), y - 0.5), Vector2(lerpf(eb.x, eb.y, f), y + step + 0.5), SAULO_RUT, 8.0)

		var w: float = ea.y - ea.x
		var k := int(absf(y) / step)
		var h := fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)
		wc.circle(Vector2(ea.x + 20.0 + h * (w - 40.0), y + h * step), 2.2, PEBBLE)
		eb = ea
		y -= step

	_draw_escalators(m, wc, vt, vb)
	_draw_cannons(wc, vt, vb)
	_draw_bunker(wc, vt, vb)
	_draw_fence(m, wc, vt, vb)


static func _draw_escalators(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var z: Rect2 = ESCALATOR_ZONE
	if z.end.y < vt - 20.0 or z.position.y > vb + 20.0:
		return

	# Escalator pit and frame
	wc.rect(z, STEEL_RAIL)
	wc.rect(z.grow(-3.0), CONCRETE_BASE)

	# Moving step treads
	var t_offset := fmod(AnimClock.msec() * 0.06, 20.0)
	var ty := z.position.y + t_offset
	while ty < z.end.y:
		wc.line(Vector2(z.position.x + 4.0, ty), Vector2(z.end.x - 4.0, ty), TREAD_RIB, 2.5)
		ty += 20.0

	# Handrails (black rubber on stainless balustrade)
	for hx: float in [z.position.x + 3.0, z.end.x - 3.0]:
		wc.line(Vector2(hx, z.position.y), Vector2(hx, z.end.y), Color(0.12, 0.12, 0.14), 5.0)


static func _draw_cannons(wc: ShapeBatch, vt: float, vb: float) -> void:
	for c: Vector3 in cannons():
		var cp := Vector2(c.x, c.y)
		var cr := c.z
		if cp.y + cr < vt - 30.0 or cp.y - cr > vb + 30.0:
			continue

		# Parapet shadow
		wc.circle(cp + LIGHT * 6.0, cr + 4.0, SHADOW)
		# Outer concrete wall
		wc.circle(cp, cr, CONCRETE_BASE)
		wc.circle(cp - LIGHT * 3.0, cr - 2.0, CONCRETE_LIT)
		# Inner emplacement pit
		wc.circle(cp, cr - 12.0, CONCRETE_DARK)
		# Center pivot mount
		wc.circle(cp, 14.0, CONCRETE_LIP)
		wc.circle(cp, 7.0, STEEL_RAIL)


static func _draw_bunker(wc: ShapeBatch, vt: float, vb: float) -> void:
	var b := BUNKER
	if b.end.y < vt - 30.0 or b.position.y > vb + 30.0:
		return

	# Cast shadow
	wc.rect(Rect2(b.position + LIGHT * 8.0, b.size), SHADOW)
	# Heavy concrete blockhouse
	wc.rect(b, CONCRETE_DARK)
	wc.rect(Rect2(b.position, Vector2(b.size.x, 14.0)), CONCRETE_LIT)
	wc.rect(Rect2(b.position.x, b.position.y, 14.0, b.size.y), CONCRETE_LIT)
	# Doorway recess
	wc.rect(Rect2(b.position.x + b.size.x * 0.5 - 18.0, b.end.y - 14.0, 36.0, 14.0), Color(0.15, 0.14, 0.13))


static func _draw_fence(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var posts := fence_posts(m)
	for i in range(posts.size()):
		var p: Vector2 = posts[i]
		if p.y < vt - FENCE_STEP or p.y > vb + FENCE_STEP:
			continue
		if i + 1 < posts.size():
			var q: Vector2 = posts[i + 1]
			if absf(q.y - p.y) < FENCE_STEP * 1.6:
				wc.line(p + Vector2(-4, 0), q + Vector2(-4, 0), TIMBER, 3.0)
				wc.line(p + Vector2(-1, 0), q + Vector2(-1, 0), TIMBER_LIT, 2.0)
		wc.circle(p + LIGHT * 4.0, 6.0, SHADOW)
		wc.circle(p, 5.5, TIMBER)
		wc.circle(p - LIGHT * 1.5, 3.0, TIMBER_LIT)


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return

	# Panoramic Barcelona grid and sunset sea far below to the west
	b.rect(Rect2(-400.0, top, 1100.0, bot - top), HAZE_SUNSET)
	b.rect(Rect2(-400.0, top, 410.0, bot - top), Color(0.85, 0.52, 0.44))

	var gy := floorf(top / 90.0) * 90.0
	while gy < bot:
		var gk := int(absf(gy) / 90.0)
		var h := fmod(absf(sin(float(gk) * 17.13) * 31415.9), 1.0)
		var bx := lerpf(-260.0, 240.0, h)
		b.rect(Rect2(bx, gy + 15.0, 64.0, 55.0), CITY_BLOCK)
		gy += 90.0


static func draw_live(m: Node2D, wc: ShapeBatch, _vt: float = 0.0, _vb: float = 0.0) -> void:
	if m.guitarrista != null:
		m.guitarrista.draw(wc)


static func draw_overhead(m: Node2D, wc: ShapeBatch) -> void:
	# Bunting and lanterns over the sunset mirador summit
	var my := MIRADOR_Y
	var p0 := Vector2(m.walk_edges(my).x, my)
	var p1 := Vector2(m.walk_edges(my).y, my)
	wc.line(p0, p1, Color(0.25, 0.22, 0.20), 1.5)
	for i in range(12):
		var f := float(i) / 11.0
		var lp: Vector2 = p0.lerp(p1, f) + Vector2(0.0, sin(f * PI) * 18.0)
		wc.circle(lp, 3.5, Color(1.0, 0.88, 0.45, 0.85))
