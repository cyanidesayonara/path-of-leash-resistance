class_name Superilla
extends RefCounted

# WALK 29: LA SUPERILLA (The Poblenou Superblock)
#
# A sunny Mediterranean afternoon in Barcelona's innovative Poblenou Superblock
# (Carrer de Sancho d'Avila / Carrer de la Ciutat de Granada).
# Once a grid of vehicular intersections, the interior streets have been reclaimed
# as a green, pedestrian-first urban oasis.
#
# Hallmarks of the Superblock:
# - Tactical urbanism ground art: wide dark asphalt painted with huge circular
#   graphics in turquoise, sunflower yellow, terracotta, and lime green.
# - Timber tree planter boxes: large square boxes with olive trees, oleanders,
#   and fragrant Mediterranean rosemary forming natural leash wrapping obstacles.
# - Concrete ping-pong tables: solid recreational tables where stray ping-pong
#   balls roll across the court, inviting dog boops.
# - Curved timber platform deck benches for community relaxation.
# - Signature live event: El Patí de Càrrega - a front-loading family cargo trike
#   gliding along the green lane, ringing a cheerful bell ("ding-ding!").

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const SuperillaCargo := preload("res://systems/superilla_cargo.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)

# --- colors ------------------------------------------------------------------
const ASPHALT_DARK := Color(0.24, 0.24, 0.26)
const ASPHALT_LIGHT := Color(0.28, 0.28, 0.30)
const SIDEWALK_PANOT := Color(0.68, 0.64, 0.60)
const CURB_STONE := Color(0.52, 0.50, 0.48)

# Tactical urbanism paint palette
const PAINT_TURQUOISE := Color(0.22, 0.68, 0.72, 0.85)
const PAINT_YELLOW := Color(0.95, 0.78, 0.24, 0.85)
const PAINT_TERRACOTTA := Color(0.84, 0.38, 0.28, 0.85)
const PAINT_GREEN := Color(0.38, 0.72, 0.42, 0.85)
const PAINT_WHITE := Color(0.94, 0.94, 0.92, 0.90)

# Planter box & nature colors
const TIMBER_BOX := Color(0.54, 0.38, 0.24)
const TIMBER_LIT := Color(0.66, 0.48, 0.32)
const PLANTER_SOIL := Color(0.34, 0.26, 0.20)
const OLIVE_LEAF := Color(0.42, 0.54, 0.38)
const OLIVE_TRUNK := Color(0.38, 0.32, 0.26)
const LAVENDER_PURPLE := Color(0.56, 0.44, 0.68)

# Furniture colors
const PINGPONG_CONCRETE := Color(0.72, 0.74, 0.72)
const PINGPONG_TOP := Color(0.18, 0.46, 0.58)
const PINGPONG_LINE := Color(0.94, 0.94, 0.96)
const PINGPONG_NET := Color(0.88, 0.88, 0.90)
const BENCH_WOOD := Color(0.60, 0.44, 0.28)

# --- layout constants --------------------------------------------------------
const HALF := 300.0
const WALL_L := 340.0
const WALL_R := 940.0

# Concrete ping-pong tables (solid rectangular obstacles)
const PINGPONG_1 := Rect2(470.0, -1640.0, 70.0, 110.0)
const PINGPONG_2 := Rect2(740.0, -3240.0, 70.0, 110.0)

# Unique Superblock prize (Artisanal Horchata at the Orxateria table)
const PRIZE := Vector2(740.0, -4520.0)
const PRIZE_TEXT := "snatch the artisan horchata from the orxateria table"

# Painted tactical circle center coordinates
const PAINT_CIRCLES: Array[Dictionary] = [
	{"pos": Vector2(640.0, -800.0), "r": 90.0, "col": PAINT_TURQUOISE},
	{"pos": Vector2(530.0, -1200.0), "r": 75.0, "col": PAINT_YELLOW},
	{"pos": Vector2(750.0, -1250.0), "r": 80.0, "col": PAINT_GREEN},
	{"pos": Vector2(640.0, -2200.0), "r": 110.0, "col": PAINT_TERRACOTTA},
	{"pos": Vector2(510.0, -2600.0), "r": 85.0, "col": PAINT_TURQUOISE},
	{"pos": Vector2(770.0, -2650.0), "r": 90.0, "col": PAINT_YELLOW},
	{"pos": Vector2(640.0, -3800.0), "r": 120.0, "col": PAINT_GREEN},
	{"pos": Vector2(540.0, -4250.0), "r": 80.0, "col": PAINT_TERRACOTTA},
	{"pos": Vector2(740.0, -4300.0), "r": 85.0, "col": PAINT_TURQUOISE},
]

# Planter box centers (large square wooden boxes, wrap points)
const PLANTER_POSITIONS: Array[Vector2] = [
	Vector2(460.0, -600.0), Vector2(820.0, -600.0),
	Vector2(460.0, -1800.0), Vector2(820.0, -1800.0),
	Vector2(460.0, -2900.0), Vector2(820.0, -2900.0),
	Vector2(460.0, -4000.0), Vector2(820.0, -4000.0),
]
const PLANTER_SIZE := 44.0


static func build(m: Node2D) -> Array:
	m.gate_text = "PASSATGE DEL VAPOR"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 440.0
	m.gate_r = 840.0

	# Register planter boxes as rope poles (radius 22.0)
	for p: Vector2 in PLANTER_POSITIONS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	# Register corners of ping-pong tables as wrap poles
	for r: Rect2 in [PINGPONG_1, PINGPONG_2]:
		m.poles.append(Vector2(r.position.x + 6.0, r.get_center().y))
		m.poles.append(Vector2(r.end.x - 6.0, r.get_center().y))

	m.benches = Array([
		Vector2(450.0, -1000.0),
		Vector2(830.0, -1400.0),
		Vector2(450.0, -2400.0),
		Vector2(830.0, -3500.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(430.0, -700.0),
		Vector2(850.0, -1700.0),
		Vector2(430.0, -2800.0),
		Vector2(850.0, -3900.0),
	], TYPE_VECTOR2, &"", null)

	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 20.0, -450.0),
		Vector2(WALL_R - 20.0, -1350.0),
		Vector2(WALL_L + 20.0, -2300.0),
		Vector2(WALL_R - 20.0, -3300.0),
		Vector2(WALL_L + 20.0, -4150.0),
	]

	var keb_list: Array[Vector2] = [
		Vector2(620.0, -900.0),
		Vector2(660.0, -2100.0),
		Vector2(600.0, -3100.0),
		Vector2(670.0, -4200.0),
	]

	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT

	m.cargo = SuperillaCargo.new()

	m.superilla_circles_visited = {}
	m.superilla_circles_sprinted = 0
	m.superilla_pingpong_slid = false

	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = [PINGPONG_1, PINGPONG_2]
	for p: Vector2 in PLANTER_POSITIONS:
		out.append(Rect2(p.x - PLANTER_SIZE * 0.5, p.y - PLANTER_SIZE * 0.5, PLANTER_SIZE, PLANTER_SIZE))
	return out


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


static func tick(m: Node2D, delta: float) -> void:
	if m.cargo != null:
		m.cargo.tick(m, delta)

	# Track dog sprint through painted asphalt circles
	var dog_p: Vector2 = m.dog.global_position
	var dog_v: Vector2 = m.dog.velocity if "velocity" in m.dog else Vector2.ZERO
	if dog_v.length() > 180.0:
		for i in range(PAINT_CIRCLES.size()):
			var circ: Dictionary = PAINT_CIRCLES[i]
			var cp: Vector2 = circ["pos"]
			var cr: float = circ["r"]
			if dog_p.distance_to(cp) <= cr:
				if not m.superilla_circles_visited.has(i):
					m.superilla_circles_visited[i] = true
					m.superilla_circles_sprinted = m.superilla_circles_visited.size()
					if m.superilla_circles_sprinted == 3:
						m.combo.add("TACTICAL RUNNER", 2)
						m.float_text(dog_p + Vector2(0, -28), "tactical runner! +2", Color(0.22, 0.85, 0.8))

	# Track dog sliding under ping-pong tables
	if not m.superilla_pingpong_slid:
		for r: Rect2 in [PINGPONG_1, PINGPONG_2]:
			if r.has_point(dog_p):
				m.superilla_pingpong_slid = true
				m.combo.add("PINGPONG SLIDE", 2)
				m.float_text(dog_p + Vector2(0, -28), "table slide! +2", Color(0.96, 0.88, 0.35))
				break


static func on_bark(m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	if m.cargo != null:
		return m.cargo.on_bark(m)
	return false


static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# Draw tactical urbanism painted asphalt circles under the pair
	for circ: Dictionary in PAINT_CIRCLES:
		var p: Vector2 = circ["pos"]
		var r: float = circ["r"]
		if p.y + r >= vt and p.y - r <= vb:
			var col: Color = circ["col"]
			b.circle(p, r, col)
			b.circle(p, r - 6.0, col.lightened(0.12))
			# White graphic accent ring
			for seg in range(6):
				var a := float(seg) * 1.047
				var sp := p + Vector2(cos(a), sin(a)) * (r - 12.0)
				b.circle(sp, 3.5, PAINT_WHITE)


static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# Draw ping-pong tables
	for r: Rect2 in [PINGPONG_1, PINGPONG_2]:
		if r.end.y >= vt and r.position.y <= vb:
			# Drop shadow
			b.rect(Rect2(r.position.x + 8.0, r.position.y + 10.0, r.size.x, r.size.y), SHADOW)
			# Concrete legs
			b.rect(Rect2(r.position.x + 8.0, r.position.y + 6.0, 12.0, r.size.y - 12.0), PINGPONG_CONCRETE.darkened(0.2))
			b.rect(Rect2(r.end.x - 20.0, r.position.y + 6.0, 12.0, r.size.y - 12.0), PINGPONG_CONCRETE.darkened(0.2))
			# Table top (blue marine playing surface)
			b.rect(r, PINGPONG_TOP)
			# White boundary lines
			b.line(r.position + Vector2(2, 2), Vector2(r.end.x - 2, r.position.y + 2), PINGPONG_LINE, 2.0)
			b.line(Vector2(r.position.x + 2, r.end.y - 2), Vector2(r.end.x - 2, r.end.y - 2), PINGPONG_LINE, 2.0)
			b.line(r.position + Vector2(2, 2), Vector2(r.position.x + 2, r.end.y - 2), PINGPONG_LINE, 2.0)
			b.line(Vector2(r.end.x - 2, r.position.y + 2), Vector2(r.end.x - 2, r.end.y - 2), PINGPONG_LINE, 2.0)
			# Center division line
			var mid_y := r.get_center().y
			b.line(Vector2(r.position.x + 2, mid_y), Vector2(r.end.x - 2, mid_y), PINGPONG_NET, 3.0)
			# Net brackets
			b.circle(Vector2(r.position.x - 2, mid_y), 3.0, Color.DARK_GRAY)
			b.circle(Vector2(r.end.x + 2, mid_y), 3.0, Color.DARK_GRAY)

	# Draw planter boxes with olive trees
	for p: Vector2 in PLANTER_POSITIONS:
		if p.y + 50.0 >= vt and p.y - 50.0 <= vb:
			var pr := Rect2(p.x - PLANTER_SIZE * 0.5, p.y - PLANTER_SIZE * 0.5, PLANTER_SIZE, PLANTER_SIZE)
			# Drop shadow
			b.rect(Rect2(pr.position.x + 6.0, pr.position.y + 8.0, pr.size.x, pr.size.y), SHADOW)
			# Timber planter box walls
			b.rect(pr, TIMBER_BOX)
			b.rect(Rect2(pr.position.x + 3.0, pr.position.y + 3.0, pr.size.x - 6.0, pr.size.y - 6.0), PLANTER_SOIL)
			# Lavender flowers at corners
			for lx in [-14.0, 14.0]:
				for ly in [-14.0, 14.0]:
					b.circle(p + Vector2(lx, ly), 5.0, LAVENDER_PURPLE)
			# Olive tree trunk & crown
			b.circle(p, 6.0, OLIVE_TRUNK)
			b.circle(p + Vector2(0, -2), 18.0, OLIVE_LEAF)
			b.circle(p + Vector2(-6, 2), 14.0, OLIVE_LEAF.lightened(0.08))
			b.circle(p + Vector2(6, 2), 14.0, OLIVE_LEAF.darkened(0.08))

	# Draw cargo trike live event
	if m.cargo != null:
		m.cargo.draw(b, vt, vb)


static func draw_overhead(_m: Node2D, _wc: Object) -> void:
	pass


static func surface(_m: Node2D, _p: Vector2) -> int:
	return Surfaces.S.PAVEMENT
