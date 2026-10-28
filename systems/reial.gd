class_name Reial
extends RefCounted

# WALK 19: PLAÇA REIAL (The Arcaded Royal Square)
# Set in the heart of Barcelona's Gothic Quarter: an elegant 19th-century
# neoclassical royal plaza bounded by continuous arched colonnades (porxos),
# towering Washingtonia royal palm trees, Antoni Gaudí's six-armed dragon-helmet
# streetlamps (Fanals de Gaudí), the ornate Font de les Tres Gràcies central
# fountain, outdoor tapas terraces, and a Spanish guitar busker.

const Letters := preload("res://world/sign_letters.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)

# --- colors ------------------------------------------------------------------
const STONE_PLAZA := Color(0.74, 0.72, 0.68)
const STONE_DARK := Color(0.58, 0.56, 0.52)
const BAND_CREAM := Color(0.85, 0.83, 0.77)
const ARCADE_TILE := Color(0.68, 0.36, 0.26)
const ARCADE_PILLAR := Color(0.82, 0.78, 0.70)
const ARCADE_SHADOW := Color(0.12, 0.10, 0.10, 0.75)
const PALM_TRUNK := Color(0.46, 0.35, 0.25)
const PALM_BARK := Color(0.36, 0.26, 0.18)
const PALM_LEAF := Color(0.22, 0.50, 0.26)
const PALM_LEAF_LIGHT := Color(0.36, 0.66, 0.32)
const GAUDI_BRONZE := Color(0.20, 0.24, 0.22)
const GAUDI_MARBLE := Color(0.54, 0.26, 0.24)
const GAUDI_GOLD := Color(0.86, 0.72, 0.24)
const GAUDI_GLOBE := Color(1.0, 0.92, 0.65)
const FOUNTAIN_IRON := Color(0.18, 0.20, 0.22)
const FOUNTAIN_WATER := Color(0.35, 0.68, 0.84, 0.75)
const FOUNTAIN_STONE := Color(0.70, 0.68, 0.64)
const CHURRO_GOLD := Color(0.88, 0.68, 0.28)
const CHOCOLATE_DARK := Color(0.22, 0.12, 0.08)
const GUITAR_WOOD := Color(0.78, 0.46, 0.22)

# --- corridor layout ---------------------------------------------------------
const WEST_ARCADE_X := 350.0
const EAST_ARCADE_X := 930.0
const CORRIDOR_L := 350.0
const CORRIDOR_R := 930.0

# Antoni Gaudí's 6-armed dragon-helmet lampposts (Fanals de Gaudí)
const GAUDI_POSTS: Array[Vector2] = [
	Vector2(640.0, -1700.0),
	Vector2(640.0, -3300.0),
]

# The central Font de les Tres Gràcies fountain
const FOUNTAIN_POS := Vector2(640.0, -2500.0)
const FOUNTAIN_RADIUS := 44.0
# main._bodily's drinking reach on this walk, and how far into the drink
# (dog.drinking eases 0 to 1) the goal counts it
const FOUNTAIN_DRINK_R := 68.0
const DRINK_CREDIT := 0.5

# Washingtonia royal palm trees framing the central square
const PALMS: Array[Vector2] = [
	Vector2(460.0, -950.0),
	Vector2(820.0, -950.0),
	Vector2(460.0, -1550.0),
	Vector2(820.0, -1550.0),
	Vector2(460.0, -2150.0),
	Vector2(820.0, -2150.0),
	Vector2(460.0, -2850.0),
	Vector2(820.0, -2850.0),
	Vector2(460.0, -3450.0),
	Vector2(820.0, -3450.0),
	Vector2(460.0, -4150.0),
	Vector2(820.0, -4150.0),
]

# Dining terraces with bistro tables under the portico arcades
const TERRACES: Array[Rect2] = [
	Rect2(352.0, -1250.0, 78.0, 160.0),
	Rect2(850.0, -1250.0, 78.0, 160.0),
	Rect2(352.0, -2650.0, 78.0, 160.0),
	Rect2(850.0, -2650.0, 78.0, 160.0),
	Rect2(352.0, -3850.0, 78.0, 160.0),
	Rect2(850.0, -3850.0, 78.0, 160.0),
]

# Spanish guitar busker under the west arcade
const BUSKER_POS := Vector2(385.0, -1950.0)

# Hot churros and chocolate prize on an outdoor terrace table
const PRIZE := Vector2(890.0, -2700.0)
const PRIZE_TEXT := "snatch the hot churros from the terrace table"

# Plaza pigeons pecking breadcrumbs
const PIGEON_SPOTS: Array[Vector2] = [
	Vector2(640.0, -1100.0),
	Vector2(520.0, -1900.0),
	Vector2(760.0, -2300.0),
	Vector2(580.0, -3100.0),
	Vector2(700.0, -3700.0),
]


static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 290.0},
		{"y": -600.0, "cx": 640.0, "half": 290.0},
		{"y": -1200.0, "cx": 640.0, "half": 290.0},
		{"y": -2200.0, "cx": 640.0, "half": 290.0},
		{"y": -3200.0, "cx": 640.0, "half": 290.0},
		{"y": -4200.0, "cx": 640.0, "half": 290.0},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": 290.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 290.0},
	]


static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t: Rect2 in TERRACES:
		out.append(t)
	return out


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t: Rect2 in TERRACES:
		out.append(t)
	# Central fountain collision footprint
	out.append(Rect2(FOUNTAIN_POS.x - FOUNTAIN_RADIUS, FOUNTAIN_POS.y - FOUNTAIN_RADIUS,
		FOUNTAIN_RADIUS * 2.0, FOUNTAIN_RADIUS * 2.0))
	return out


# Round rope poles. Their radii are not set here: world/level_build.gd gives
# every round post the same radius once the level's poles are all in.
static func setup_poles(m: Node2D) -> void:
	for p: Vector2 in GAUDI_POSTS:
		m.poles.append(p)
	# Fountain center ring poles
	for i in range(8):
		var a := float(i) * (TAU / 8.0)
		m.poles.append(FOUNTAIN_POS + Vector2(cos(a), sin(a)) * FOUNTAIN_RADIUS)
	# Palm tree trunks
	for p: Vector2 in PALMS:
		m.poles.append(p)


static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA REIAL"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([FOUNTAIN_POS], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(365.0, -1400.0),
		Vector2(915.0, -1400.0),
		Vector2(365.0, -3200.0),
		Vector2(915.0, -3200.0),
	], TYPE_VECTOR2, &"", null)

	# The fountain island directs owner around the central fountain (east side)
	m.islands = Array([{"rect": Rect2(FOUNTAIN_POS - Vector2(FOUNTAIN_RADIUS + 24.0, FOUNTAIN_RADIUS + 24.0), Vector2((FOUNTAIN_RADIUS + 24.0) * 2.0, (FOUNTAIN_RADIUS + 24.0) * 2.0)), "side": 1.0, "lead": 180.0}], TYPE_DICTIONARY, &"", null)

	setup_poles(m)

	# Sniffable landmarks (hydrants)
	var marks: Array[Vector2] = [
		Vector2(640.0, -1700.0),
		Vector2(640.0, -3300.0),
		Vector2(640.0, -2500.0 - FOUNTAIN_RADIUS - 6.0),
		Vector2(385.0, -1950.0),
		Vector2(850.0, -2650.0),
	]

	# Snacks: dropped churros and tapas crumbs
	var snacks: Array[Vector2] = [
		Vector2(480.0, -1250.0),
		Vector2(800.0, -2650.0),
		Vector2(520.0, -2150.0),
		Vector2(750.0, -3850.0),
	]

	return [marks, snacks]


static func draw_edge_layer(m: Node2D, b: ShapeBatch, _vt: float = 0.0, _vb: float = 0.0) -> void:
	if m.lvl != "reial":
		return
	# Arcade portico flooring on the flanks (terracotta tiles)
	b.rect(Rect2(200.0, -4800.0, 150.0, 5200.0), ARCADE_TILE)
	b.rect(Rect2(930.0, -4800.0, 150.0, 5200.0), ARCADE_TILE)

	# Main plaza flagstones (polished granite)
	b.rect(Rect2(CORRIDOR_L, -4800.0, CORRIDOR_R - CORRIDOR_L, 5200.0), STONE_PLAZA)

	# Decorative radial stone bands across the plaza
	for y: float in [-1300.0, -2100.0, -2900.0, -3700.0]:
		b.rect(Rect2(CORRIDOR_L, y, CORRIDOR_R - CORRIDOR_L, 8.0), BAND_CREAM)
		b.rect(Rect2(CORRIDOR_L, y + 2.0, CORRIDOR_R - CORRIDOR_L, 4.0), STONE_DARK)

	# Radial starburst paving around the central Three Graces fountain
	for i in range(12):
		var a := float(i) * (TAU / 12.0)
		var dir := Vector2(cos(a), sin(a))
		b.line(FOUNTAIN_POS + dir * (FOUNTAIN_RADIUS + 4.0), FOUNTAIN_POS + dir * 110.0, BAND_CREAM, 3.5)

	# Fountain base and water
	b.circle(FOUNTAIN_POS + LIGHT * 8.0, FOUNTAIN_RADIUS + 4.0, SHADOW)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS, FOUNTAIN_STONE)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS - 6.0, FOUNTAIN_IRON)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS - 10.0, FOUNTAIN_WATER)
	# Inner pedestal and Three Graces column
	b.circle(FOUNTAIN_POS, 18.0, FOUNTAIN_STONE)
	b.circle(FOUNTAIN_POS, 12.0, FOUNTAIN_IRON)

	# Gaudí 6-armed lampposts
	for gp: Vector2 in GAUDI_POSTS:
		# Marble plinth and shadow
		b.circle(gp + LIGHT * 6.0, 24.0, SHADOW)
		b.circle(gp, 20.0, GAUDI_MARBLE)
		b.circle(gp, 14.0, GAUDI_BRONZE)
		# Six arms with glass globes
		for i in range(6):
			var a := float(i) * (TAU / 6.0)
			var arm := gp + Vector2(cos(a), sin(a)) * 26.0
			b.line(gp, arm, GAUDI_BRONZE, 3.0)
			b.circle(arm + LIGHT * 2.0, 5.0, SHADOW)
			b.circle(arm, 4.5, GAUDI_GLOBE)
		# Central winged dragon-helmet finial
		b.circle(gp, 6.0, GAUDI_GOLD)

	# Palm tree trunks and base grates
	for p: Vector2 in PALMS:
		b.circle(p + LIGHT * 5.0, 16.0, SHADOW)
		b.circle(p, 16.0, STONE_DARK)
		b.circle(p, 12.0, PALM_TRUNK)
		b.circle(p, 7.0, PALM_BARK)

	# Dining terraces under the arcades
	for tr: Rect2 in TERRACES:
		b.rect(Rect2(tr.position + LIGHT * 4.0, tr.size), SHADOW)
		b.rect(tr, Color(0.15, 0.16, 0.18, 0.45))
		# Bistro tables
		var cols := 2
		var rows := int(tr.size.y / 48.0)
		for r in range(rows):
			for c in range(cols):
				var tp := tr.position + Vector2(16.0 + float(c) * 44.0, 24.0 + float(r) * 48.0)
				b.circle(tp + LIGHT * 3.0, 12.0, SHADOW)
				b.circle(tp, 11.0, Color(0.92, 0.90, 0.86)) # white marble top
				b.circle(tp, 3.0, Color(0.20, 0.18, 0.16))   # plate

	# Spanish guitar busker
	b.circle(BUSKER_POS + LIGHT * 4.0, 14.0, SHADOW)
	b.circle(BUSKER_POS, 12.0, Color(0.25, 0.28, 0.35)) # blue shirt
	# Wooden guitar
	var gp := BUSKER_POS + Vector2(12.0, -4.0)
	b.circle(gp + Vector2(0, 4), 6.0, GUITAR_WOOD)
	b.circle(gp + Vector2(0, -3), 4.5, GUITAR_WOOD)
	b.line(gp + Vector2(0, -3), gp + Vector2(0, -12), Color(0.2, 0.15, 0.1), 2.0)
	# Open guitar case with tossed coins
	var cp := BUSKER_POS + Vector2(24.0, 10.0)
	b.rect(Rect2(cp.x - 6.0, cp.y - 12.0, 12.0, 24.0), Color(0.12, 0.10, 0.14))
	b.circle(cp + Vector2(0, -4), 2.0, Color(0.94, 0.82, 0.25)) # gold coin
	b.circle(cp + Vector2(2, 4), 1.8, Color(0.90, 0.80, 0.30))  # gold coin

	# Hot churros and chocolate prize
	b.circle(PRIZE + LIGHT * 3.0, 10.0, SHADOW)
	b.circle(PRIZE, 9.0, Color(0.95, 0.94, 0.90)) # ceramic plate
	b.circle(PRIZE + Vector2(-3, -2), 3.5, CHOCOLATE_DARK) # chocolate cup
	b.line(PRIZE + Vector2(0, 2), PRIZE + Vector2(6, -4), CHURRO_GOLD, 3.0) # churro
	b.line(PRIZE + Vector2(2, 4), PRIZE + Vector2(7, 0), CHURRO_GOLD, 3.0)  # churro

	# Arcade colonnade stone pillars
	for y: float in [-1000.0, -1600.0, -2200.0, -2800.0, -3400.0, -4000.0]:
		b.rect(Rect2(WEST_ARCADE_X - 12.0, y - 12.0, 24.0, 24.0), STONE_DARK)
		b.rect(Rect2(WEST_ARCADE_X - 10.0, y - 10.0, 20.0, 20.0), ARCADE_PILLAR)
		b.rect(Rect2(EAST_ARCADE_X - 12.0, y - 12.0, 24.0, 24.0), STONE_DARK)
		b.rect(Rect2(EAST_ARCADE_X - 10.0, y - 10.0, 20.0, 20.0), ARCADE_PILLAR)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "reial":
		return
	# Towering palm fronds overhead, one batch: forty lines a palm
	var b := ShapeBatch.new(ci)
	var t: float = AnimClock.msec() / 1000.0
	for p: Vector2 in PALMS:
		for i in range(10):
			var a := float(i) * (TAU / 10.0) + sin(t * 1.5 + p.y * 0.01) * 0.05
			var leaf_len := 55.0 + sin(float(i) * 2.4) * 8.0
			var dir := Vector2(cos(a), sin(a))
			var end_p := p + dir * leaf_len
			b.line(p, end_p, PALM_LEAF, 4.0)
			# the lit midrib runs the inner seven tenths of the frond
			b.line(p, p + dir * leaf_len * 0.7, PALM_LEAF_LIGHT, 2.5)
			# Frond tip leaflet feathers
			var norm := Vector2(-sin(a), cos(a)) * 5.0
			b.line(end_p, end_p - norm, PALM_LEAF_LIGHT, 1.5)
			b.line(end_p, end_p + norm, PALM_LEAF_LIGHT, 1.5)
	b.flush()


static func tick(m: Node2D, _delta: float) -> void:
	if m.lvl != "reial":
		return
	# The fountain goal is a real drink: main._bodily sets dog.drinking at
	# the rim (its 68 px reach on this walk), standing still. The Gaudi goal
	# is a real wrap and is set by main._tick_vault on a static contact.
	if not m.reial_fountain_drank and m.dog.drinking > DRINK_CREDIT:
		if m.dog.global_position.distance_to(FOUNTAIN_POS) < FOUNTAIN_DRINK_R:
			m.reial_fountain_drank = true

	# Check barking at busker
	if not bool(m.get("reial_busker_barked")):
		if m.dog.global_position.distance_to(BUSKER_POS) < 110.0:
			if m.dog.bark_anim > 0.0:
				m.set("reial_busker_barked", true)
				m.float_text(m.dog.global_position + Vector2(0, -28), "¡Olé!", Color(0.96, 0.88, 0.35))
				m.feed.say("A DUET WITH THE BUSKER!", EventFeed.Tone.GOOD)

# main.surface_at, through walk_mod: the ground here, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1
