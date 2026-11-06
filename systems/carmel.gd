class_name Carmel
extends RefCounted

# WALK 28: ELS BÚNQUERS DEL CARMEL (The Sunset Overlook)
#
# Turó de la Rovira at dusk: Spanish Civil War anti-aircraft bunker battery (1937)
# perched 262 m above Barcelona, later surrounded by the post-war shantytown of
# Les Barraques del Carmel and preserved today as an open-air hilltop museum.
# The climb begins along Baixada de la Glòria with the outdoor escalators
# rising beside terraced stone walls. The path winds up sauló gravel switchbacks
# lined with Aleppo pines, rosemary, agaves, and dry-stone retaining walls.
#
# At the summit plateau, the circular Vickers 105 mm cannon emplacements, command
# post bunker, brick-and-tile barraques floor remnants, and 360-degree panoramic
# view over the Eixample grid, Diagonal, and Mediterranean sea glowing under the
# golden-hour sunset.
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
const SAULO_WARM := Color(0.82, 0.71, 0.55)
const SAULO_RUT := Color(0.68, 0.58, 0.44)
const SAULO_EDGE := Color(0.60, 0.52, 0.38)
const PEBBLE := Color(0.86, 0.80, 0.70)
const PEBBLE_DARK := Color(0.54, 0.46, 0.35)
const CONCRETE_BASE := Color(0.64, 0.62, 0.58)  # 1937 weathered bunker concrete
const CONCRETE_WARM := Color(0.72, 0.66, 0.58)
const CONCRETE_LIT := Color(0.84, 0.78, 0.68)   # lit by golden sunset
const CONCRETE_DARK := Color(0.42, 0.40, 0.38)
const CONCRETE_PIT := Color(0.32, 0.30, 0.29)
const CONCRETE_LIP := Color(0.74, 0.72, 0.66)
const BRICK_TERRA := Color(0.68, 0.39, 0.28)    # barraques hollow-brick red
const BRICK_DARK := Color(0.48, 0.27, 0.20)
const TILE_CREAM := Color(0.84, 0.78, 0.66)
const TILE_BLUE := Color(0.38, 0.49, 0.58)
const TILE_OCHRE := Color(0.78, 0.58, 0.32)
const STONE_WALL := Color(0.52, 0.47, 0.41)
const STONE_TOP := Color(0.68, 0.62, 0.54)
const STONE_MORTAR := Color(0.36, 0.32, 0.28)
const SCRUB_DARK := Color(0.24, 0.31, 0.20)     # hillside maquis & pine shadow
const SCRUB_MID := Color(0.30, 0.39, 0.24)
const SCRUB_OLIVE := Color(0.39, 0.46, 0.28)
const SCRUB_EARTH := Color(0.46, 0.39, 0.30)
const BROOM_GOLD := Color(0.88, 0.72, 0.24)     # yellow ginesta broom
const PINE_CROWN := Color(0.24, 0.38, 0.22)
const PINE_TRUNK := Color(0.44, 0.28, 0.18)
const AGAVE_LEAF := Color(0.38, 0.52, 0.46)
const AGAVE_TIP := Color(0.26, 0.38, 0.33)
const TIMBER := Color(0.52, 0.38, 0.24)
const TIMBER_LIT := Color(0.64, 0.49, 0.32)
const CORTEN := Color(0.54, 0.28, 0.18)         # MUHBA rusted Corten steel
const CORTEN_LIT := Color(0.68, 0.38, 0.24)
const STEEL_RAIL := Color(0.24, 0.24, 0.26)
const STEEL_DECK := Color(0.52, 0.54, 0.57)
const STEEL_COMB := Color(0.76, 0.72, 0.62)
const TREAD_DARK := Color(0.20, 0.21, 0.23)
const TREAD_RIB := Color(0.34, 0.35, 0.38)
const HAZE_SUNSET := Color(0.76, 0.60, 0.54)    # warm rose-gold sunset haze
const HAZE_DEEP := Color(0.56, 0.44, 0.46)
const SEA_HORIZON := Color(0.86, 0.56, 0.46)
const SEA_WATER := Color(0.44, 0.50, 0.60)
const CITY_BLOCK := Color(0.68, 0.54, 0.50)
const CITY_SHADE := Color(0.60, 0.47, 0.45)
const CITY_COURT := Color(0.50, 0.39, 0.39)
const SEA_GLINT := Color(0.98, 0.86, 0.66, 0.70)

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

# Distant skyline landmarks visible in the west Eixample grid (x, y, kind: 0 = temple spires, 1 = tower)
const SKYLINE_LANDMARKS: Array[Vector3] = [
	Vector3(235.0, -640.0, 0.0),
	Vector3(215.0, -1520.0, 1.0),
	Vector3(240.0, -2420.0, 0.0),
	Vector3(220.0, -3380.0, 1.0),
	Vector3(238.0, -4320.0, 0.0),
]


static func _hash(n: int) -> float:
	return fmod(absf(sin(float(n) * 12.9898 + 78.233) * 43758.5453), 1.0)


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


static func solids(_m: Node2D) -> Array[Rect2]:
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
		Vector2(420.0, -4500.0),
		Vector2(840.0, -4500.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(850.0, -800.0),
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


static func surface(_m: Node2D, p: Vector2) -> int:
	# Bunker concrete summits and escalators
	if ESCALATOR_ZONE.has_point(p):
		return Surfaces.S.TILE
	for c: Vector3 in cannons():
		if p.distance_to(Vector2(c.x, c.y)) < c.z:
			return Surfaces.S.TILE
	if BUNKER.has_point(p):
		return Surfaces.S.TILE
	return Surfaces.S.SAND  # sauló granite grit


static func takes_prints(_m: Node2D, _p: Vector2) -> bool:
	return false


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


# --- edge layer: sunset Barcelona panorama (west) + Turó hillside (east) -----

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return

	_draw_city_panorama(m, b, top, bot)
	_draw_hillside_slopes(m, b, top, bot)


static func _draw_city_panorama(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	# Warm rose-gold sunset haze over the city basin, Mediterranean sea on the far left
	b.rect(Rect2(-460.0, top, 1120.0, bot - top), HAZE_SUNSET)
	b.rect(Rect2(-460.0, top, 636.0, bot - top), SEA_WATER)
	# Sunset horizon glow & beachfront strip at x = 176
	b.band(PackedVector2Array([
		Vector2(110.0, top), Vector2(180.0, top),
		Vector2(110.0, bot), Vector2(180.0, bot),
	]), 2, SEA_HORIZON, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	b.rect(Rect2(174.0, top, 6.0, bot - top), Color(0.88, 0.78, 0.64))
	b.band(PackedVector2Array([
		Vector2(176.0, top), Vector2(320.0, top),
		Vector2(176.0, bot), Vector2(320.0, bot),
	]), 2, Color(1.0, 0.80, 0.48, 0.28), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))

	# Sun glints on the Mediterranean water (visible at the left edge of the viewport)
	var gy := floorf(top / 90.0) * 90.0
	while gy < bot:
		var gk := int(absf(gy) / 90.0)
		var gx := 146.0 + float((gk * 7) % 22)
		b.line(Vector2(gx, gy + 18.0), Vector2(gx - 4.0, gy + 42.0), SEA_GLINT, 1.6)
		gy += 90.0

	# Miniature Eixample octagonal blocks (chamfered corners + inner courtyard), sliced by the Diagonal
	var cell := 22.0
	var cy := floorf(top / cell) * cell
	while cy < bot:
		var e: Vector2 = m.walk_edges(clampf(cy, m.GATE_Y, float(m.START_Y)))
		var x_end: float = e.x - 92.0
		var row := int(absf(cy) / cell)
		if row % 8 != 0:
			var cx := 186.0
			while cx + 16.0 < x_end:
				var col := int((cx - 186.0) / cell)
				var dg := absf(float(col) - fmod(float(row) * 0.45, 7.0))
				if col % 6 != 0 and dg > 0.65:
					var h := _hash(row * 31 + col * 17)
					var o := Vector2(cx, cy)
					b.polygon(PackedVector2Array([
						o + Vector2(3, 0), o + Vector2(13, 0), o + Vector2(16, 3), o + Vector2(16, 13),
						o + Vector2(13, 16), o + Vector2(3, 16), o + Vector2(0, 13), o + Vector2(0, 3),
					]), CITY_BLOCK if h > 0.35 else CITY_SHADE)
					if h > 0.62:
						b.rect(Rect2(o.x + 5.0, o.y + 5.0, 6.0, 6.0), CITY_COURT)
				cx += cell
		cy += cell

	# Generic skyline landmarks rising from the Eixample grid
	for lm: Vector3 in SKYLINE_LANDMARKS:
		if lm.y < top - 40.0 or lm.y > bot + 40.0:
			continue
		var at := Vector2(lm.x, lm.y)
		if int(lm.z) == 0:
			b.rect(Rect2(at.x - 12.0, at.y - 18.0, 24.0, 36.0), CITY_SHADE)
			for sp: Vector2 in [Vector2(-7, -11), Vector2(7, -11), Vector2(-7, 11), Vector2(7, 11), Vector2(0, 0), Vector2(0, -5)]:
				b.coarse(at + sp + LIGHT * 3.0, 3.5, Color(0.32, 0.24, 0.26, 0.38))
				b.coarse(at + sp, 3.2, Color(0.90, 0.78, 0.62))
		else:
			b.coarse(at + LIGHT * 5.0, 9.0, Color(0.32, 0.24, 0.26, 0.38))
			b.coarse(at, 8.5, Color(0.68, 0.56, 0.58))
			b.coarse(at - LIGHT * 2.5, 4.5, Color(0.92, 0.78, 0.64))


static func _slope_drop(k: int) -> float:
	return 82.0 + sin(float(k) * 0.65) * 10.0


static func _draw_hillside_slopes(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	# East hillside backdrop
	b.rect(Rect2(640.0, top, 1080.0, bot - top), SCRUB_DARK)

	var strip := 32.0
	var y := floorf(bot / strip) * strip
	var k_prev := int(absf(y + strip) / strip)
	var eb: Vector2 = m.walk_edges(clampf(y + strip, m.GATE_Y, float(m.START_Y)))
	var drop_b := _slope_drop(k_prev)

	while y > top - strip:
		var yc := clampf(y, m.GATE_Y, float(m.START_Y))
		var ea: Vector2 = m.walk_edges(yc)
		var k := int(absf(y) / strip)
		var drop_a := _slope_drop(k)
		var h1 := _hash(k * 11 + 1)
		var h2 := _hash(k * 23 + 7)

		# Smooth continuous west cliff scrub slope right below the trail edge
		b.polygon(PackedVector2Array([
			Vector2(ea.x - drop_a, y),
			Vector2(ea.x + 2.0, y),
			Vector2(eb.x + 2.0, y + strip),
			Vector2(eb.x - drop_b, y + strip),
		]), SCRUB_DARK)
		b.polygon(PackedVector2Array([
			Vector2(ea.x - drop_a * 0.55, y),
			Vector2(ea.x + 2.0, y),
			Vector2(eb.x + 2.0, y + strip),
			Vector2(eb.x - drop_b * 0.55, y + strip),
		]), SCRUB_MID)

		# Continuous dry-stone retaining terrace wall along the west slope
		var tw_a := ea.x - drop_a * 0.48
		var tw_b := eb.x - drop_b * 0.48
		b.line(Vector2(tw_a, y), Vector2(tw_b, y + strip), STONE_WALL, 4.5)
		b.line(Vector2(tw_a + 1.8, y), Vector2(tw_b + 1.8, y + strip), STONE_TOP, 2.0)

		# Smooth continuous east uphill cut bank and terraced hillside
		b.polygon(PackedVector2Array([
			Vector2(ea.y - 2.0, y),
			Vector2(ea.y + 115.0 + drop_a * 0.3, y),
			Vector2(eb.y + 115.0 + drop_b * 0.3, y + strip),
			Vector2(eb.y - 2.0, y + strip),
		]), SCRUB_MID)

		# Dry-stone retaining walls stepping up the eastern Turó de la Rovira slope
		for wall_off: float in [22.0, 96.0, 178.0]:
			var wx_a := ea.y + wall_off + sin(float(k) * 0.4 + wall_off) * 5.0
			var wx_b := eb.y + wall_off + sin(float(k - 1) * 0.4 + wall_off) * 5.0
			b.line(Vector2(wx_a, y), Vector2(wx_b, y + strip), STONE_WALL, 5.5)
			b.line(Vector2(wx_a - 2.0, y), Vector2(wx_b - 2.0, y + strip), STONE_TOP, 2.2)

		# Organic olive/rosemary scrub & yellow broom clusters on both slopes
		var vy := y + strip * 0.5
		var vx_w := ea.x - 18.0 - h1 * (drop_a - 28.0)
		b.coarse(Vector2(vx_w, vy), 9.0 + h2 * 5.0, SCRUB_OLIVE)
		if k % 3 == 0:
			b.coarse(Vector2(vx_w + 5.0, vy - 3.0), 4.2, BROOM_GOLD)
		if k % 5 == 1:
			_draw_agave(b, Vector2(ea.x - 24.0, vy), 9.5 + h1 * 3.5)

		var vx_e := ea.y + 42.0 + h1 * 44.0
		b.coarse(Vector2(vx_e, vy), 12.0 + h1 * 6.0, PINE_CROWN)
		b.coarse(Vector2(vx_e - 3.0, vy - 2.0), 7.0 + h2 * 4.0, SCRUB_OLIVE)
		var vx_e2 := ea.y + 122.0 + h2 * 48.0
		b.coarse(Vector2(vx_e2, vy), 13.0 + h2 * 6.0, SCRUB_OLIVE if k % 2 == 0 else PINE_CROWN)
		if k % 2 == 0:
			b.coarse(Vector2(vx_e + 14.0, vy + 4.0), 4.8, BROOM_GOLD)
		if k % 4 == 2:
			_draw_agave(b, Vector2(ea.y + 34.0 + h2 * 18.0, vy), 11.5)

		# Barraques del Carmel tiled/brick foundation remnants on the eastern terraces
		if k % 7 == 3 and y < -280.0 and y > m.GATE_Y + 180.0:
			_draw_barraca_ruin(b, Vector2(ea.y + 38.0, y - 4.0), k)

		# Watchers sitting on the western sunset parapet wall near the summit (outside walk area)
		if y <= -3100.0 and y >= -4680.0 and k % 4 == 0:
			_draw_sunset_watcher(b, Vector2(ea.x - 12.0, vy), k)

		eb = ea
		drop_b = drop_a
		y -= strip


static func _draw_agave(b: ShapeBatch, p: Vector2, r: float) -> void:
	b.coarse(p + LIGHT * 2.5, r * 0.75, SHADOW)
	for i in range(7):
		var a := float(i) * TAU / 7.0 + 0.2
		var dir := Vector2(cos(a), sin(a))
		var tip := p + dir * r
		var perp := Vector2(-dir.y, dir.x) * (r * 0.22)
		b.polygon(PackedVector2Array([p + perp, p - perp, tip]), AGAVE_LEAF if i % 2 == 0 else AGAVE_TIP)
	b.coarse(p, r * 0.22, AGAVE_LEAF.lightened(0.18))


static func _draw_barraca_ruin(b: ShapeBatch, pos: Vector2, seed_k: int) -> void:
	var rw := 52.0 + _hash(seed_k * 17) * 14.0
	var rh := 32.0
	var r := Rect2(pos.x, pos.y, rw, rh)
	b.rect(Rect2(r.position + LIGHT * 3.0, r.size), SHADOW)
	# Outer broken hollow-brick wall stub
	b.rect(r, BRICK_DARK)
	b.rect(r.grow(-3.5), TILE_CREAM)
	# Checkerboard hydraulic floor tiles inside the former room
	var tw := (rw - 7.0) / 4.0
	var th := (rh - 7.0) / 2.0
	var tc := TILE_BLUE if seed_k % 2 == 0 else TILE_OCHRE
	for ix in range(4):
		for iy in range(2):
			if (ix + iy) % 2 == 0:
				b.rect(Rect2(r.position.x + 3.5 + float(ix) * tw, r.position.y + 3.5 + float(iy) * th, tw - 1.0, th - 1.0), tc)
	# Broken terracotta brick course along top & left wall
	b.line(r.position, Vector2(r.end.x - 10.0, r.position.y), BRICK_TERRA, 3.5)
	b.line(r.position, Vector2(r.position.x, r.end.y - 6.0), BRICK_TERRA, 3.5)


static func _draw_sunset_watcher(b: ShapeBatch, pos: Vector2, seed_k: int) -> void:
	var shirt_cols: Array[Color] = [
		Color(0.84, 0.42, 0.34),
		Color(0.32, 0.54, 0.68),
		Color(0.88, 0.72, 0.34),
		Color(0.46, 0.62, 0.44),
	]
	var shirt: Color = shirt_cols[seed_k % shirt_cols.size()]
	var hair := Color(0.18, 0.14, 0.12) if seed_k % 2 == 0 else Color(0.42, 0.28, 0.18)
	# Legs dangling westward toward the sunset view
	b.line(pos + Vector2(-3.0, -3.0), pos + Vector2(-11.0, -3.0), Color(0.22, 0.26, 0.36), 3.5)
	b.line(pos + Vector2(-3.0, 3.0), pos + Vector2(-11.0, 3.0), Color(0.22, 0.26, 0.36), 3.5)
	# Shoulders & head facing west
	b.coarse(pos + LIGHT * 2.5, 7.5, SHADOW)
	b.coarse(pos, 7.0, shirt)
	b.coarse(pos + Vector2(-2.0, 0.0), 4.8, Color(0.92, 0.76, 0.64))
	b.coarse(pos + Vector2(-1.0, 0.0), 4.4, hair)


# --- cross section: sauló trail, stone rigoles, summit battery slabs ---------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 30.0, ctop)
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	var step := 24.0
	var y := floorf(hi / step) * step
	var eb: Vector2 = m.walk_edges(y + step)

	while y > lo - step:
		var ea: Vector2 = m.walk_edges(y)
		var k := int(absf(y) / step)
		var h := _hash(k)
		var h2 := _hash(k * 7 + 13)
		var base_col := SAULO.lerp(SAULO_WARM, h * 0.40)
		wc.polygon(PackedVector2Array([
			Vector2(ea.x, y), Vector2(ea.y, y),
			Vector2(eb.y, y + step), Vector2(eb.x, y + step),
		]), base_col)

		# Shaded compacted shoulders along both edges
		var sh_w := 24.0
		wc.polygon(PackedVector2Array([
			Vector2(ea.x, y), Vector2(ea.x + sh_w, y),
			Vector2(eb.x + sh_w, y + step), Vector2(eb.x, y + step),
		]), SAULO_RUT)
		wc.polygon(PackedVector2Array([
			Vector2(ea.y - sh_w, y), Vector2(ea.y, y),
			Vector2(eb.y, y + step), Vector2(eb.y - sh_w, y + step),
		]), SAULO_RUT)

		# Sunset-lit stone coping along the west drop & dry-stone curb along the east cut
		wc.line(Vector2(ea.x + 3.0, y), Vector2(eb.x + 3.0, y + step), STONE_TOP, 5.5)
		wc.line(Vector2(ea.x + 7.0, y), Vector2(eb.x + 7.0, y + step), SAULO_EDGE, 2.5)
		wc.line(Vector2(ea.y - 3.0, y), Vector2(eb.y - 3.0, y + step), STONE_WALL, 6.0)

		# Summit battery concrete platform slabs above y = -3050
		if y < -3050.0:
			var pad_l := ea.x + 36.0
			var pad_r := ea.y - 42.0
			if k % 4 != 0:
				wc.rect(Rect2(pad_l, y, pad_r - pad_l, step + 0.5), CONCRETE_WARM.lerp(SAULO, 0.35))
				wc.line(Vector2(pad_l, y), Vector2(pad_r, y), CONCRETE_DARK, 1.4)
				var mid_x := lerpf(pad_l, pad_r, 0.50)
				wc.line(Vector2(mid_x, y), Vector2(mid_x, y + step), CONCRETE_DARK, 1.4)
		else:
			# Walking ruts along the sauló switchbacks
			for f: float in [0.36, 0.64]:
				wc.line(
					Vector2(lerpf(ea.x, ea.y, f), y - 0.5),
					Vector2(lerpf(eb.x, eb.y, f), y + step + 0.5),
					SAULO_RUT, 8.0
				)

		# Diagonal stone water-bar drainage channels (rigoles) across the switchbacks
		if y < -980.0 and y > -3020.0 and k % 14 == 0:
			var p0 := Vector2(ea.x + 14.0, y + 4.0)
			var p1 := Vector2(ea.y - 14.0, y + step - 2.0)
			wc.line(p0, p1, STONE_MORTAR, 6.5)
			wc.line(p0 + Vector2(0.0, -2.0), p1 + Vector2(0.0, -2.0), STONE_TOP, 2.8)

		# Scattered granite grit pebbles
		var w: float = ea.y - ea.x
		wc.circle(Vector2(ea.x + 22.0 + h * (w - 44.0), y + h2 * step), 2.2, PEBBLE)
		wc.circle(Vector2(ea.x + 28.0 + h2 * (w - 56.0), y + h * step), 1.8, PEBBLE_DARK)

		eb = ea
		y -= step

	_draw_barraques_inlays(m, wc, vt, vb)
	_draw_mirador_terrace(wc, vt, vb)
	_draw_cannons(wc, vt, vb)
	_draw_bunker(wc, vt, vb)
	_draw_fence(m, wc, vt, vb)
	_draw_overhead_into(m, wc, vt, vb)


static func _draw_barraques_inlays(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	# Historic tiled floor thresholds from Les Barraques del Carmel along the trail shoulders
	var spots: Array[Vector3] = [
		Vector3(465.0, -1380.0, 0.0),
		Vector3(775.0, -2340.0, 1.0),
		Vector3(790.0, -3300.0, 0.0),
		Vector3(785.0, -4020.0, 1.0),
	]
	for s: Vector3 in spots:
		if s.y + 40.0 < vt or s.y - 40.0 > vb:
			continue
		var ea: Vector2 = m.walk_edges(s.y)
		var px := clampf(s.x, ea.x + 28.0, ea.y - 78.0)
		var r := Rect2(px, s.y - 15.0, 44.0, 30.0)
		wc.rect(r.grow(2.0), BRICK_TERRA)
		wc.rect(r, TILE_CREAM)
		var col_a := TILE_BLUE if int(s.z) == 0 else TILE_OCHRE
		for ix in range(4):
			for iy in range(3):
				if (ix + iy) % 2 == 0:
					wc.rect(Rect2(r.position.x + 2.0 + float(ix) * 10.0, r.position.y + 2.0 + float(iy) * 9.0, 9.0, 8.0), col_a)
		wc.line(r.position, Vector2(r.end.x, r.position.y), BRICK_DARK, 2.0)


static func _draw_mirador_terrace(wc: ShapeBatch, vt: float, vb: float) -> void:
	var mp := Vector2(MIRADOR_SPOT.x - 16.0, MIRADOR_SPOT.y)
	var mr := 48.0
	if mp.y + mr + 30.0 < vt or mp.y - mr - 30.0 > vb:
		return

	# Golden sunset glow over the western overlook balcony (clear of the bench at (420, -4500))
	wc.glow(mp + Vector2(-10.0, 0.0), mr * 1.45, Color(1.0, 0.80, 0.44, 0.24))
	wc.circle(mp + LIGHT * 4.0, mr + 3.0, SHADOW)
	wc.circle(mp, mr + 2.0, STONE_WALL)
	wc.circle(mp, mr - 3.0, CONCRETE_LIT)
	wc.circle(mp, mr - 10.0, CONCRETE_WARM)

	# Radial stone paving joints on the mirador balcony
	for i in range(7):
		var a := float(i) * PI / 6.0 + PI * 0.5
		var dir := Vector2(cos(a), sin(a))
		wc.line(mp + dir * 14.0, mp + dir * (mr - 4.0), CONCRETE_DARK, 1.6)

	# Compass rose / panoramic orientation plaque at the mirador center
	wc.circle(mp, 13.0, CORTEN)
	wc.circle(mp, 9.5, STEEL_COMB)
	for i in range(4):
		var a := float(i) * PI * 0.5
		var dir := Vector2(cos(a), sin(a))
		wc.line(mp - dir * 8.0, mp + dir * 8.0, CORTEN, 1.8)


# --- custom escalator (conveyor hook replaces generic yellow chevrons) -------

static func draw_conveyor(_m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var z: Rect2 = ESCALATOR_ZONE
	if z.end.y < vt - 30.0 or z.position.y > vb + 30.0:
		return

	# Terraced stone retaining wall housing the outdoor escalator trench
	wc.rect(z.grow(10.0), SHADOW)
	wc.rect(z.grow(7.0), STONE_WALL)
	wc.rect(z.grow(4.0), STONE_TOP)

	# Companion stone stairway steps along the left side of the escalator casing
	var stair_x := z.position.x - 20.0
	wc.rect(Rect2(stair_x, z.position.y, 14.0, z.size.y), STONE_WALL)
	var sy := maxf(z.position.y, floorf((vt - 20.0) / 16.0) * 16.0)
	var sy_end := minf(z.end.y, vb + 20.0)
	while sy < sy_end:
		wc.line(Vector2(stair_x + 1.0, sy), Vector2(stair_x + 13.0, sy), STONE_TOP, 2.0)
		sy += 16.0

	# Brushed stainless-steel escalator pit and side skirts
	wc.rect(z, STEEL_DECK)
	wc.rect(Rect2(z.position.x + 7.0, z.position.y, z.size.x - 14.0, z.size.y), TREAD_DARK)

	# Scrolling grooved metal treads (moving upward toward -Y)
	var step_h := 16.0
	var t_offset := step_h - fmod(AnimClock.msec() * 0.05, step_h)
	var ty := maxf(z.position.y + 18.0, floorf((vt - 20.0) / step_h) * step_h + t_offset)
	var ty_end := minf(z.end.y - 18.0, vb + 20.0)
	while ty < ty_end:
		if ty > z.position.y + 16.0:
			wc.line(Vector2(z.position.x + 8.0, ty), Vector2(z.end.x - 8.0, ty), TREAD_RIB, 3.0)
			wc.line(Vector2(z.position.x + 8.0, ty + 2.5), Vector2(z.end.x - 8.0, ty + 2.5), Color(0.76, 0.72, 0.42, 0.55), 1.2)
		ty += step_h

	# Top and bottom stainless comb-plate landings with yellow safety teeth
	for ly: float in [z.position.y, z.end.y - 16.0]:
		var lr := Rect2(z.position.x + 5.0, ly, z.size.x - 10.0, 16.0)
		wc.rect(lr, STEEL_DECK.lightened(0.16))
		wc.line(Vector2(lr.position.x, lr.position.y + 8.0), Vector2(lr.end.x, lr.position.y + 8.0), STEEL_COMB, 2.5)

	# Brushed steel balustrades & black rubber handrails with sunset highlight
	for hx: float in [z.position.x + 3.5, z.end.x - 3.5]:
		wc.line(Vector2(hx, z.position.y - 4.0), Vector2(hx, z.end.y + 4.0), STEEL_RAIL, 7.0)
		wc.line(Vector2(hx, z.position.y - 4.0), Vector2(hx, z.end.y + 4.0), Color(0.10, 0.10, 0.12), 4.5)
		wc.line(Vector2(hx - 1.0, z.position.y - 4.0), Vector2(hx - 1.0, z.end.y + 4.0), Color(0.92, 0.78, 0.58, 0.45), 1.4)


# --- 1937 Vickers anti-aircraft cannon emplacements & command bunker ---------

static func _draw_cannons(wc: ShapeBatch, vt: float, vb: float) -> void:
	for c: Vector3 in cannons():
		var cp := Vector2(c.x, c.y)
		var cr := c.z
		if cp.y + cr < vt - 30.0 or cp.y - cr > vb + 30.0:
			continue

		# Cast shadow & weathered concrete circular parapet
		wc.circle(cp + LIGHT * 7.0, cr + 4.0, SHADOW)
		wc.circle(cp, cr, CONCRETE_BASE)
		wc.circle(cp - LIGHT * 2.5, cr - 2.0, CONCRETE_LIT)
		wc.circle(cp, cr - 6.0, CONCRETE_WARM)

		# Radial expansion joints & brick repair patches on the parapet rim
		for i in range(6):
			var a := float(i) * TAU / 6.0 + 0.35
			var dir := Vector2(cos(a), sin(a))
			wc.line(cp + dir * (cr - 14.0), cp + dir * (cr - 1.0), CONCRETE_DARK, 2.0)
			if i == 1 or i == 4:
				var bp := cp + dir * (cr - 7.0)
				wc.circle(bp, 4.5, BRICK_TERRA)

		# Sunken circular gun pit
		var pit_r := cr - 13.0
		wc.circle(cp + LIGHT * 2.0, pit_r, CONCRETE_DARK)
		wc.circle(cp, pit_r - 2.0, CONCRETE_PIT)

		# Recessed ammunition ready-locker niches carved into the inner parapet wall
		for i in range(6):
			var a := float(i) * TAU / 6.0
			var np := cp + Vector2(cos(a), sin(a)) * (pit_r - 2.0)
			wc.circle(np, 4.2, Color(0.18, 0.17, 0.16))

		# Steel azimuth traverse ring & central Vickers 105 mm pedestal mount
		wc.circle(cp, pit_r - 8.0, STEEL_RAIL)
		wc.circle(cp, pit_r - 10.5, CONCRETE_PIT)
		wc.circle(cp + LIGHT * 2.0, 15.0, SHADOW)
		wc.circle(cp, 15.0, CONCRETE_LIP)
		wc.circle(cp, 10.0, CORTEN)
		wc.circle(cp, 6.0, STEEL_RAIL)
		for i in range(6):
			var a := float(i) * TAU / 6.0
			wc.circle(cp + Vector2(cos(a), sin(a)) * 8.0, 1.3, CONCRETE_LIT)


static func _draw_bunker(wc: ShapeBatch, vt: float, vb: float) -> void:
	var b := BUNKER
	if b.end.y < vt - 30.0 or b.position.y > vb + 30.0:
		return

	# Cast shadow
	wc.rect(Rect2(b.position + LIGHT * 9.0, b.size), SHADOW)
	# Heavy reinforced-concrete command blockhouse
	wc.rect(b, CONCRETE_DARK)
	wc.rect(b.grow(-3.0), CONCRETE_BASE)
	# Golden sunset-lit west and north roof bevels
	wc.rect(Rect2(b.position.x + 2.0, b.position.y + 2.0, b.size.x - 4.0, 14.0), CONCRETE_LIT)
	wc.rect(Rect2(b.position.x + 2.0, b.position.y + 2.0, 14.0, b.size.y - 4.0), CONCRETE_LIT)

	# Concrete roof slab with board-marked formwork seams & brick patches
	var roof := b.grow(-12.0)
	wc.rect(roof, CONCRETE_WARM)
	for sy_off: float in [22.0, 48.0, 74.0]:
		wc.line(
			Vector2(roof.position.x, b.position.y + sy_off),
			Vector2(roof.end.x, b.position.y + sy_off),
			CONCRETE_DARK, 1.5
		)
	wc.rect(Rect2(b.end.x - 32.0, b.position.y + 18.0, 16.0, 10.0), BRICK_TERRA)

	# West-facing armored rangefinder observation slit
	wc.rect(Rect2(b.position.x - 2.0, b.position.y + 26.0, 10.0, 48.0), Color(0.14, 0.13, 0.12))
	wc.line(Vector2(b.position.x + 8.0, b.position.y + 24.0), Vector2(b.position.x + 8.0, b.position.y + 76.0), CONCRETE_LIT, 3.0)

	# Sunken blast-wall entrance steps on the south side
	var door_x := b.position.x + b.size.x * 0.5 - 20.0
	wc.rect(Rect2(door_x, b.end.y - 16.0, 40.0, 16.0), Color(0.15, 0.14, 0.13))
	for st in range(3):
		var sy := b.end.y - 14.0 + float(st) * 4.5
		wc.line(Vector2(door_x + 3.0, sy), Vector2(door_x + 37.0, sy), CONCRETE_BASE.darkened(float(st) * 0.15), 2.5)

	# MUHBA Corten-steel historical lectern stand beside the bunker
	var lp := Vector2(b.end.x - 22.0, b.end.y - 22.0)
	wc.rect(Rect2(lp - Vector2(7.0, 5.0), Vector2(14.0, 10.0)), CORTEN)
	wc.rect(Rect2(lp - Vector2(5.0, 3.5), Vector2(10.0, 7.0)), CORTEN_LIT)


static func _draw_fence(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var posts := fence_posts(m)
	for i in range(posts.size()):
		var p: Vector2 = posts[i]
		if p.y < vt - FENCE_STEP or p.y > vb + FENCE_STEP:
			continue
		if i + 1 < posts.size():
			var q: Vector2 = posts[i + 1]
			if absf(q.y - p.y) < FENCE_STEP * 1.6:
				wc.line(p + Vector2(-4, 0), q + Vector2(-4, 0), TIMBER, 3.5)
				wc.line(p + Vector2(-1, 0), q + Vector2(-1, 0), TIMBER_LIT, 2.0)
		wc.circle(p + LIGHT * 4.0, 6.0, SHADOW)
		wc.circle(p, 5.5, TIMBER)
		wc.circle(p - LIGHT * 1.5, 3.0, TIMBER_LIT)


# --- custom props: MUHBA Corten marker posts, hillside fountains, bravas -----

static func draw_bollard(_m: Node2D, wc: ShapeBatch, h) -> void:
	var p: Vector2 = h.pos
	wc.circle(p + LIGHT * 4.0, 11.0, SHADOW)
	# Stone plinth base
	wc.circle(p, 10.5, STONE_WALL)
	wc.circle(p - LIGHT * 1.0, 8.5, STONE_TOP)
	# Rusted Corten-steel MUHBA battery marker post
	var post_col := CORTEN if not h.done else CORTEN.darkened(0.22)
	var top_col := CORTEN_LIT if not h.done else CORTEN_LIT.darkened(0.22)
	wc.rect(Rect2(p - Vector2(5.5, 5.5), Vector2(11.0, 11.0)), post_col)
	wc.rect(Rect2(p - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), top_col)
	wc.line(p + Vector2(-3.0, -1.5), p + Vector2(3.0, -1.5), TILE_CREAM, 1.6)
	wc.line(p + Vector2(-3.0, 1.5), p + Vector2(2.0, 1.5), TILE_CREAM, 1.4)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(p, 18.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1.0, 0.95, 0.70), 3.0)


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	# Aleppo pine ground shadow, roots across the trail shoulder, and red-bark trunk
	var e: Vector2 = m.walk_edges(p.y)
	var edge_side := 1.0 if p.x < e.x + 80.0 else -1.0
	wc.circle(p + LIGHT * 26.0, 32.0, Color(0.04, 0.05, 0.07, 0.18))
	for ri in range(3):
		var a := (float(ri) - 1.0) * 0.52
		var d := Vector2(edge_side, 0.0).rotated(a)
		var tip := p + d * (28.0 + float(ri % 2) * 10.0)
		wc.line(p, tip, Color(0.33, 0.25, 0.16), 3.6 - float(ri % 2))
		wc.line(p + Vector2(0.0, -1.0), tip + Vector2(0.0, -1.0), Color(0.44, 0.35, 0.23), 1.2)
	wc.circle(p, 6.5, PINE_TRUNK)
	wc.circle(p - LIGHT * 1.2, 4.0, PINE_TRUNK.lightened(0.22))


static func draw_bin(_m: Node2D, wc: ShapeBatch, bn: Vector2) -> void:
	# Park Güell / Carmel hillside timber-slatted drum bin on Corten post
	wc.circle(bn + LIGHT * 6.0, 14.0, SHADOW)
	wc.circle(bn, 13.0, CORTEN)
	wc.circle(bn, 11.2, TIMBER)
	wc.circle(bn - LIGHT * 1.5, 9.2, TIMBER_LIT)
	wc.circle(bn + Vector2(0.8, 1.2), 6.8, Color(0.12, 0.14, 0.12))
	wc.circle(bn + Vector2(11.5, 5.5), 3.8, Color(0.78, 0.78, 0.74, 0.85))


static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var c: ShapeBatch = m._wc
	# Semicircular hillside stone apron & drain basin (static for furniture cache)
	c.circle(f + LIGHT * 5.0, 20.0, SHADOW)
	c.circle(f, 19.0, STONE_WALL)
	c.circle(f, 16.0, STONE_TOP)
	c.circle(f + Vector2(0.0, 5.0), 10.5, STONE_MORTAR)
	c.circle(f + Vector2(0.0, 5.0), 8.5, Color(0.24, 0.56, 0.74, 0.80))
	# Dark green/iron Barcelona mountain column & brass tap
	c.rect(Rect2(f + Vector2(-5.5, -11.0), Vector2(11.0, 12.0)), Color(0.18, 0.24, 0.20))
	c.circle(f + Vector2(0.0, -7.0), 4.5, Color(0.28, 0.36, 0.30))
	c.line(f + Vector2(0.0, -2.0), f + Vector2(0.0, 4.0), STEEL_COMB, 2.5)
	c.circle(f + Vector2(0.0, 5.0), 4.2, Color(0.55, 0.85, 1.0, 0.55))


static func draw_snack(_m: Node2D, wc: ShapeBatch, pos: Vector2) -> void:
	# Cardboard boat tray of golden patates braves with salsa brava and aioli
	wc.circle(pos + Vector2(2.0, 3.0), 10.0, SHADOW)
	wc.rect(Rect2(pos - Vector2(9.0, 6.5), Vector2(18.0, 13.0)), Color(0.86, 0.78, 0.64))
	wc.rect(Rect2(pos - Vector2(7.5, 5.0), Vector2(15.0, 10.0)), Color(0.76, 0.66, 0.52))
	for off: Vector2 in [Vector2(-4.0, -2.0), Vector2(1.0, -2.5), Vector2(4.5, 1.0), Vector2(-2.0, 2.0), Vector2(2.0, 2.5)]:
		wc.circle(pos + off, 3.0, Color(0.92, 0.68, 0.24))
	# Spicy red salsa brava & white garlic aioli drizzle
	wc.circle(pos + Vector2(-2.0, -1.0), 2.0, Color(0.84, 0.22, 0.16))
	wc.circle(pos + Vector2(2.5, 1.0), 1.8, Color(0.96, 0.94, 0.86))


# --- live entities & sunset picnic prize -------------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float = -6000.0, vb: float = 600.0) -> void:
	if not m.prize_taken and PRIZE.y > vt - 40.0 and PRIZE.y < vb + 40.0:
		_draw_picnic_prize(wc, PRIZE)
	if m.guitarrista != null:
		m.guitarrista.draw(wc)


static func _draw_picnic_prize(wc: ShapeBatch, p: Vector2) -> void:
	# Woven sunset picnic blanket with terracotta cazuela of patates braves
	var br := Rect2(p - Vector2(20.0, 15.0), Vector2(40.0, 30.0))
	wc.rect(Rect2(br.position + LIGHT * 3.0, br.size), SHADOW)
	wc.rect(br, Color(0.78, 0.30, 0.24))
	wc.rect(br.grow(-3.0), Color(0.90, 0.82, 0.68))
	for sx: float in [-12.0, -4.0, 4.0, 12.0]:
		wc.line(Vector2(p.x + sx, br.position.y + 2.0), Vector2(p.x + sx, br.end.y - 2.0), Color(0.78, 0.30, 0.24, 0.55), 2.0)
	# Terracotta dish of bravas at center + two sunset drinks
	wc.circle(p + Vector2(-4.0, 1.0), 8.5, BRICK_DARK)
	wc.circle(p + Vector2(-4.0, 1.0), 6.8, Color(0.94, 0.70, 0.24))
	wc.circle(p + Vector2(-5.5, 0.0), 2.5, Color(0.86, 0.22, 0.16))
	wc.circle(p + Vector2(-2.0, 2.0), 2.2, Color(0.96, 0.95, 0.88))
	wc.circle(p + Vector2(10.0, -5.0), 3.6, Color(0.32, 0.52, 0.30))
	wc.circle(p + Vector2(11.0, 5.0), 3.2, Color(0.92, 0.72, 0.28))


static func _draw_overhead_into(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# Aleppo pine umbrella canopies along the switchback margins
	for i in range(PINES.size()):
		var p: Vector2 = PINES[i]
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		var r := 38.0
		b.circle(p + Vector2(2.0, 3.0), r, Color(0.20, 0.26, 0.14, 0.90))
		for k in range(7):
			var a := TAU * float(k) / 7.0 + float(i) * 0.7
			var lr := r * (0.56 + 0.12 * float((k + i) % 3))
			b.circle(p + Vector2.from_angle(a) * lr, r * 0.36, PINE_CROWN)
		for k in range(4):
			var a := TAU * float(k) / 4.0 + float(i) * 1.3
			var lp := p + Vector2.from_angle(a) * r * 0.38 - LIGHT * 5.0
			b.circle(lp, r * 0.24, SCRUB_OLIVE)
		b.circle(p - LIGHT * r * 0.45, r * 0.20, Color(0.54, 0.56, 0.32))

	# Warm festival string lights over the sunset mirador summit
	var my := MIRADOR_Y
	if my >= vt - 80.0 and my <= vb + 80.0:
		var p0 := Vector2(m.walk_edges(my).x, my)
		var p1 := Vector2(m.walk_edges(my).y, my)
		b.line(p0, p1, Color(0.25, 0.22, 0.20), 1.5)
		for i in range(12):
			var f := float(i) / 11.0
			var lp: Vector2 = p0.lerp(p1, f) + Vector2(0.0, sin(f * PI) * 18.0)
			b.glow(lp, 9.0, Color(1.0, 0.82, 0.42, 0.32))
			b.circle(lp, 3.5, Color(1.0, 0.88, 0.45, 0.90))


static func draw_overhead(m: Node2D, ci: Object) -> void:
	var b := ShapeBatch.new()
	var vt: float = m.cam.position.y - 520.0 if m.get("cam") != null else -6000.0
	var vb: float = m.cam.position.y + 520.0 if m.get("cam") != null else 600.0
	_draw_overhead_into(m, b, vt, vb)
	b.flush(ci)


# --- off-leash summit battery esplanade (y = -5000 .. -5620) -----------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var gy: float = r.end.y
	var top: float = r.position.y
	var free_h: float = r.size.y
	var b := ShapeBatch.new()

	# 360-degree dusk horizon beyond the summit ridge
	b.rect(Rect2(-460.0, top - 320.0, 2200.0, 340.0), HAZE_DEEP)
	b.band(PackedVector2Array([
		Vector2(-460.0, top - 220.0), Vector2(1740.0, top - 220.0),
		Vector2(-460.0, top), Vector2(1740.0, top),
	]), 2, Color(0.94, 0.62, 0.46, 0.65), PackedFloat32Array([0.0, 1.0]))

	# Outer Turó de la Rovira summit slopes (west & east scrub wings: GRASS surface for x < 300 or x > 980)
	b.rect(Rect2(50.0, top, 1180.0, free_h), SCRUB_MID)
	b.rect(Rect2(64.0, top + 12.0, 236.0, free_h - 24.0), SCRUB_OLIVE)
	b.rect(Rect2(980.0, top + 12.0, 236.0, free_h - 24.0), SCRUB_OLIVE)

	# Terraced dry-stone contours and rosemary/broom clumps on the grass wings
	for row in range(6):
		var ry := top + 55.0 + float(row) * 86.0
		b.line(Vector2(76.0, ry), Vector2(284.0, ry + 14.0), STONE_WALL, 4.0)
		b.line(Vector2(996.0, ry + 12.0), Vector2(1196.0, ry), STONE_WALL, 4.0)
		b.coarse(Vector2(140.0 + float(row % 3) * 42.0, ry - 18.0), 14.0, PINE_CROWN)
		b.coarse(Vector2(1045.0 + float((row + 1) % 3) * 44.0, ry - 16.0), 14.0, PINE_CROWN)
		if row % 2 == 0:
			b.coarse(Vector2(210.0, ry + 20.0), 6.0, BROOM_GOLD)
			b.coarse(Vector2(1120.0, ry + 18.0), 6.0, BROOM_GOLD)

	# Central summit battery concrete/stone esplanade (x = 300 .. 980 -> PAVEMENT surface)
	var plat := Rect2(300.0, top + 14.0, 680.0, free_h - 24.0)
	b.rect(plat.grow(6.0), STONE_WALL)
	b.rect(plat, CONCRETE_BASE)
	b.rect(plat.grow(-10.0), CONCRETE_WARM)

	# Concrete slab expansion grid across the summit battery platform
	var gx := 380.0
	while gx < 960.0:
		b.line(Vector2(gx, plat.position.y + 8.0), Vector2(gx, plat.end.y - 8.0), CONCRETE_DARK, 1.6)
		gx += 85.0
	var gy_line := top + 90.0
	while gy_line < gy - 30.0:
		b.line(Vector2(plat.position.x + 8.0, gy_line), Vector2(plat.end.x - 8.0, gy_line), CONCRETE_DARK, 1.6)
		gy_line += 85.0

	# Sunken circular searchlight / rangefinder ring flush in the west-center pavement (clear of trees)
	var ring_c := Vector2(455.0, gy - 320.0)
	b.circle(ring_c, 62.0, STONE_WALL)
	b.circle(ring_c, 55.0, CONCRETE_LIT)
	b.circle(ring_c, 44.0, CONCRETE_DARK)
	b.circle(ring_c, 38.0, CONCRETE_BASE)
	b.circle(ring_c, 28.0, STEEL_RAIL)
	b.circle(ring_c, 25.5, CONCRETE_BASE)
	b.circle(ring_c, 11.0, CORTEN)
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var dir := Vector2(cos(a), sin(a))
		b.line(ring_c + dir * 13.0, ring_c + dir * 38.0, CONCRETE_DARK, 1.8)

	# Barraques del Carmel mosaic floor remnants inlaid into the battery platform
	for bp: Vector2 in [Vector2(336.0, gy - 195.0), Vector2(855.0, gy - 415.0)]:
		var br := Rect2(bp, Vector2(64.0, 42.0))
		b.rect(br.grow(2.5), STONE_WALL)
		b.rect(br, CONCRETE_LIT)
		for ix in range(4):
			for iy in range(3):
				if (ix + iy) % 2 == 0:
					b.rect(Rect2(bp.x + 4.0 + float(ix) * 14.0, bp.y + 4.0 + float(iy) * 11.5, 12.0, 10.0), TILE_BLUE)

	# Stone tree-pit rings around the summit pines
	for t: Vector2 in m.trees:
		if t.y < gy:
			b.circle(t + Vector2(3.0, 4.0), 25.0, SHADOW)
			b.circle(t, 23.0, STONE_WALL)
			b.circle(t, 18.0, SCRUB_EARTH)

	# Low dry-stone summit parapet wall around the north, west, and east perimeter
	b.rect(Rect2(56.0, top, 1168.0, 16.0), STONE_WALL)
	b.rect(Rect2(60.0, top + 2.0, 1160.0, 8.0), STONE_TOP)
	b.rect(Rect2(56.0, top, 14.0, free_h), STONE_WALL)
	b.rect(Rect2(1210.0, top, 14.0, free_h), STONE_WALL)
	# South parapet flanking the stone gate opening
	var gap_l: float = m.gate_l - 12.0
	var gap_r: float = m.gate_r + 12.0
	b.rect(Rect2(56.0, gy - 12.0, gap_l - 56.0, 14.0), STONE_WALL)
	b.rect(Rect2(gap_r, gy - 12.0, 1224.0 - gap_r, 14.0), STONE_WALL)
	b.line(Vector2(60.0, gy - 9.0), Vector2(gap_l, gy - 9.0), STONE_TOP, 3.0)
	b.line(Vector2(gap_r, gy - 9.0), Vector2(1220.0, gy - 9.0), STONE_TOP, 3.0)
	b.flush(c)
	m._draw_freedom_benches(c, r, Color(0.46, 0.36, 0.26))
	m._freedom_sign(c, r, m.gate_text, "the summit battery, off leash")
