class_name Superilla
extends RefCounted

# WALK 29: LA SUPERILLA (The Poblenou Superblock)
#
# A sunny Mediterranean afternoon in Barcelona's innovative Poblenou Superblock
# (Carrer de Sancho d'Avila / Carrer de la Ciutat de Granada).
# Once a grid of vehicular intersections, the interior streets have been reclaimed
# as a green, pedestrian-first urban oasis flanked by 19th-century red-brick
# steam mills (vapors) and modern 22@ studios, ending at Passatge del Vapor.
#
# Hallmarks of the Superblock:
# - Tactical urbanism ground art: wide dark asphalt painted with huge circular
#   graphics in turquoise, sunflower yellow, terracotta, and lime green, plus
#   painted play grids, 10 km/h roundels, and diagonal kerb bars.
# - Timber tree planter boxes: large square boxes with olive trees, lavender,
#   and fragrant Mediterranean rosemary forming natural leash wrapping obstacles.
# - Concrete ping-pong tables: solid recreational tables with paddles and ball.
# - Orxateria del Poblenou terrace deck with marble bistro tables and horchata.
# - Signature live event: El Patí de Càrrega - a front-loading family cargo trike
#   gliding along the green cycle lane, ringing a cheerful bell ("ding-ding!").

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

# Poblenou industrial brick & 22@ studio palette
const BRICK_MILL := Color(0.58, 0.31, 0.23)
const BRICK_DARK := Color(0.42, 0.22, 0.16)
const BRICK_LIGHT := Color(0.70, 0.42, 0.31)
const CORTEN_STEEL := Color(0.48, 0.28, 0.20)
const STUDIO_ZINC := Color(0.42, 0.45, 0.48)
const SKYLIGHT_GLASS := Color(0.54, 0.68, 0.76, 0.88)
const SOLAR_BLUE := Color(0.18, 0.28, 0.42)

# Tactical urbanism paint palette
const PAINT_TURQUOISE := Color(0.22, 0.68, 0.72, 0.85)
const PAINT_YELLOW := Color(0.95, 0.78, 0.24, 0.85)
const PAINT_TERRACOTTA := Color(0.84, 0.38, 0.28, 0.85)
const PAINT_GREEN := Color(0.38, 0.72, 0.42, 0.85)
const PAINT_WHITE := Color(0.94, 0.94, 0.92, 0.90)
const CYCLE_GREEN := Color(0.24, 0.58, 0.36, 0.88)

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
const SIDEWALK_W := 64.0
const ROAD_L := WALL_L + SIDEWALK_W
const ROAD_R := WALL_R - SIDEWALK_W

# Reclaimed cross-street intersections (Sancho d'Avila / Boronat / Almogavers)
const CROSS_YS: Array[float] = [-1200.0, -2200.0, -3800.0]
const CROSS_HALF := 88.0

# Concrete ping-pong tables (solid rectangular obstacles)
const PINGPONG_1 := Rect2(470.0, -1640.0, 70.0, 110.0)
const PINGPONG_2 := Rect2(740.0, -3240.0, 70.0, 110.0)

# Unique Superblock prize (Artisanal Horchata at the Orxateria table)
const PRIZE := Vector2(740.0, -4520.0)
const PRIZE_TEXT := "snatch the horchata off the orxateria table"

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

	if "fountains" in m:
		m.fountains = Array([
			Vector2(374.0, -1500.0),
			Vector2(906.0, -3650.0),
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


static func tree_kind(_m: Node2D, _p: Vector2) -> int:
	return 0


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


static func _in_cross_street(y: float) -> bool:
	for cy: float in CROSS_YS:
		if absf(y - cy) < CROSS_HALF:
			return true
	return false


# --- edge layer: Poblenou red-brick factory lofts, 22@ studios & cross-streets -

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -4800.0
	var start_y: float = float(m.START_Y) if "START_Y" in m else 200.0
	var y_top := maxf(vt - 280.0, gate_y - 30.0)
	var y_bot := minf(vb + 280.0, start_y + 560.0)
	if y_bot > y_top:
		# Base masonry fill behind both urban edges
		b.rect(Rect2(-440.0, y_top, WALL_L + 440.0, y_bot - y_top), BRICK_DARK)
		b.rect(Rect2(WALL_R, y_top, 800.0, y_bot - y_top), BRICK_DARK)

		# Draw intersecting Poblenou cross-streets at y = -1200, -2200, -3800
		for cy: float in CROSS_YS:
			if cy + CROSS_HALF < y_top or cy - CROSS_HALF > y_bot:
				continue
			_draw_side_street(b, cy)

		# Draw Poblenou industrial loft / 22@ building modules between cross-streets
		var mod := 200.0
		var sy := floorf(y_top / mod) * mod
		while sy < y_bot:
			var r_top := maxf(sy, gate_y - 30.0)
			var r_bot := minf(sy + mod, start_y + 560.0)
			# Clip module against cross-street mouths
			for cy: float in CROSS_YS:
				var c0 := cy - CROSS_HALF
				var c1 := cy + CROSS_HALF
				if r_top < c1 and r_bot > c0:
					if r_top < c0:
						r_bot = c0
					else:
						r_top = c1
			if r_bot - r_top >= 44.0:
				var k := absi(int(floorf(sy / mod)))
				_draw_poblenou_block(b, Rect2(-420.0, r_top, WALL_L + 420.0, r_bot - r_top), -1.0, k)
				_draw_poblenou_block(b, Rect2(WALL_R, r_top, 760.0, r_bot - r_top), 1.0, k + 5)
			sy += mod

	# Keep tactical circles painted on edge_layer too for test coverage
	for circ: Dictionary in PAINT_CIRCLES:
		var p: Vector2 = circ["pos"]
		var r: float = circ["r"]
		if p.y + r >= vt and p.y - r <= vb:
			var col: Color = circ["col"]
			b.circle(p, r, col)
			b.circle(p, r - 6.0, col.lightened(0.12))


static func _draw_side_street(b: ShapeBatch, cy: float) -> void:
	var sw := 26.0
	var road_h := (CROSS_HALF - sw) * 2.0
	for side_rect: Rect2 in [
		Rect2(-440.0, cy - CROSS_HALF, WALL_L + 440.0, CROSS_HALF * 2.0),
		Rect2(WALL_R, cy - CROSS_HALF, 800.0, CROSS_HALF * 2.0),
	]:
		# Sidewalks along top and bottom of the cross-street
		b.rect(side_rect, SIDEWALK_PANOT)
		# Curb shadow and stone curb lines
		b.rect(Rect2(side_rect.position.x, cy - CROSS_HALF + sw - 4.0, side_rect.size.x, 4.0), CURB_STONE)
		b.rect(Rect2(side_rect.position.x, cy + CROSS_HALF - sw, side_rect.size.x, 4.0), CURB_STONE)
		# Reclaimed asphalt carriageway
		b.rect(Rect2(side_rect.position.x, cy - CROSS_HALF + sw, side_rect.size.x, road_h), ASPHALT_DARK)
		# Sidewalk slab joints
		var jx := floorf(side_rect.position.x / 40.0) * 40.0
		while jx < side_rect.end.x:
			b.line(Vector2(jx, cy - CROSS_HALF), Vector2(jx, cy - CROSS_HALF + sw - 4.0), Color(0, 0, 0, 0.10), 1.5)
			b.line(Vector2(jx, cy + CROSS_HALF - sw + 4.0), Vector2(jx, cy + CROSS_HALF), Color(0, 0, 0, 0.10), 1.5)
			jx += 40.0

	if is_equal_approx(cy, -2200.0):
		# Green cargo-bike cycle track running east-west across the intersection
		for x_span: Vector2 in [Vector2(-440.0, WALL_L), Vector2(WALL_R, 1740.0)]:
			var w := x_span.y - x_span.x
			b.rect(Rect2(x_span.x, cy - 22.0, w, 44.0), CYCLE_GREEN)
			b.line(Vector2(x_span.x, cy - 22.0), Vector2(x_span.y, cy - 22.0), PAINT_WHITE, 2.0)
			b.line(Vector2(x_span.x, cy + 22.0), Vector2(x_span.y, cy + 22.0), PAINT_WHITE, 2.0)
			var cx := x_span.x + 36.0
			while cx < x_span.y - 30.0:
				b.line(Vector2(cx - 8.0, cy - 7.0), Vector2(cx + 2.0, cy), PAINT_WHITE, 2.2)
				b.line(Vector2(cx - 8.0, cy + 7.0), Vector2(cx + 2.0, cy), PAINT_WHITE, 2.2)
				cx += 72.0
	else:
		# Superblock entry gateways on the side streets: zebra bars, bollards & timber planters
		var accent := PAINT_YELLOW if is_equal_approx(cy, -1200.0) else PAINT_TURQUOISE
		for dir: float in [-1.0, 1.0]:
			var gx := WALL_L - 28.0 if dir < 0.0 else WALL_R + 28.0
			# White crosswalk stripes at the mouth
			for s in range(-2, 3):
				var sy := cy + float(s) * 20.0 - 5.0
				b.rect(Rect2(gx - 12.0, sy, 24.0, 10.0), PAINT_WHITE)
			# Painted tactical circle in the side street
			var sp := Vector2(gx + dir * 74.0, cy)
			b.circle(sp, 32.0, accent)
			b.circle(sp, 24.0, ASPHALT_DARK)
			b.circle(sp, 16.0, accent)
			# Timber barrier planter in the side street
			var pr := Rect2(gx + dir * 40.0 - 14.0, cy - 16.0, 28.0, 32.0)
			b.rect(Rect2(pr.position + LIGHT * 5.0, pr.size), SHADOW)
			b.rect(pr, TIMBER_BOX)
			b.rect(pr.grow(-3.0), PLANTER_SOIL)
			b.circle(pr.get_center(), 10.0, OLIVE_LEAF)
			b.circle(pr.get_center() - LIGHT * 3.0, 5.5, OLIVE_LEAF.lightened(0.14))


static func _draw_poblenou_block(b: ShapeBatch, r: Rect2, side: float, k: int) -> void:
	var inner_x := r.end.x if side < 0.0 else r.position.x
	var face := 20.0
	var roof_r := Rect2(r.position.x, r.position.y, r.size.x - face, r.size.y) if side < 0.0 \
		else Rect2(r.position.x + face, r.position.y, r.size.x - face, r.size.y)

	# Foreshortened brick wall face rising from the sidewalk edge
	for i in range(4):
		var t := float(i) / 3.0
		var wx := (inner_x - face + face * t) if side < 0.0 else (inner_x + face - face * (t + 0.25))
		b.rect(Rect2(wx, r.position.y, face * 0.28, r.size.y), BRICK_MILL.darkened(0.42 - t * 0.28))
	# Stone cornice parapet cap
	var cap_x := (inner_x - face - 5.0) if side < 0.0 else (inner_x + face)
	b.rect(Rect2(cap_x, r.position.y, 5.0, r.size.y), Color(0.76, 0.70, 0.62))
	# Arched factory window lintels along the wall face
	var wy := r.position.y + 22.0
	while wy < r.end.y - 24.0:
		var wx := (inner_x - face * 0.65) if side < 0.0 else (inner_x + face * 0.25)
		b.rect(Rect2(wx, wy, 7.0, 18.0), Color(0.16, 0.18, 0.22))
		b.rect(Rect2(wx + (1.0 if side < 0.0 else 4.0), wy + 2.0, 2.0, 14.0), Color(0.72, 0.80, 0.86, 0.45))
		wy += 36.0

	var style := k % 3
	if style != 2:
		# 19th-century Poblenou red-brick steam mill (vapor) with sawtooth factory roofs
		var brick := BRICK_MILL.lightened(float(k % 2) * 0.05)
		b.rect(roof_r, brick)
		var bay_h := 46.0
		var by := roof_r.position.y + 6.0
		var bay_x0 := (inner_x - face - 210.0) if side < 0.0 else (inner_x + face + 10.0)
		var bay_w := 200.0
		while by + bay_h <= roof_r.end.y - 4.0:
			# Terracotta pantile slope
			b.rect(Rect2(bay_x0, by, bay_w, bay_h * 0.62), BRICK_LIGHT)
			b.line(Vector2(bay_x0, by), Vector2(bay_x0 + bay_w, by), Color(0.84, 0.58, 0.44), 2.5)
			# North-light factory skylight glazing
			var sky_r := Rect2(bay_x0, by + bay_h * 0.62, bay_w, bay_h * 0.32)
			b.rect(sky_r, SKYLIGHT_GLASS)
			var gx := sky_r.position.x + 24.0
			while gx < sky_r.end.x - 8.0:
				b.line(Vector2(gx, sky_r.position.y), Vector2(gx, sky_r.end.y), Color(0.28, 0.32, 0.36), 1.6)
				gx += 28.0
			b.line(Vector2(bay_x0, sky_r.end.y), Vector2(bay_x0 + bay_w, sky_r.end.y), BRICK_DARK, 2.5)
			by += bay_h
		# Brick pilaster buttresses along the cornice
		var py := roof_r.position.y + 12.0
		while py < roof_r.end.y - 10.0:
			b.rect(Rect2(cap_x - (3.0 if side < 0.0 else -3.0), py, 7.0, 8.0), BRICK_DARK)
			py += 46.0
	else:
		# Modern 22@ Poblenou design loft: zinc & Corten roof, solar array, rooftop terrace
		b.rect(roof_r, STUDIO_ZINC)
		var ter_x := (inner_x - face - 150.0) if side < 0.0 else (inner_x + face + 12.0)
		var ter_r := Rect2(ter_x, roof_r.position.y + 14.0, 138.0, roof_r.size.y - 28.0)
		b.rect(ter_r, CORTEN_STEEL)
		b.rect(ter_r.grow(-4.0), Color(0.58, 0.44, 0.30))
		# Photovoltaic solar panels on the studio roof
		for s in range(3):
			var sy2 := ter_r.position.y + 12.0 + float(s) * 42.0
			if sy2 + 28.0 < ter_r.end.y - 8.0:
				var pan := Rect2(ter_r.position.x + 12.0, sy2, 64.0, 26.0)
				b.rect(Rect2(pan.position + LIGHT * 4.0, pan.size), SHADOW)
				b.rect(pan.grow(1.4), Color(0.72, 0.76, 0.80))
				b.rect(pan, SOLAR_BLUE)
				b.line(Vector2(pan.position.x, pan.get_center().y), Vector2(pan.end.x, pan.get_center().y), Color(0.55, 0.68, 0.82, 0.55), 1.2)
		# Rooftop olive bush in planter
		var gp := Vector2(ter_r.end.x - 26.0, ter_r.get_center().y)
		b.circle(gp + LIGHT * 4.0, 14.0, SHADOW)
		b.circle(gp, 13.0, OLIVE_LEAF.darkened(0.12))
		b.circle(gp - LIGHT * 3.0, 8.0, OLIVE_LEAF.lightened(0.14))


# --- ground layer: panot sidewalks, reclaimed asphalt & tactical urbanism ----

static func draw_cross_section(m: Node2D, wc: Object, _top: float, bottom: float, _ctop: float, vt: float, vb: float) -> void:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -4800.0
	var y0 := maxf(vt - 80.0, gate_y - 40.0)
	var y1 := minf(vb + 80.0, bottom)
	if y1 <= y0:
		return

	var b := ShapeBatch.new()

	# 1. Base dark reclaimed Poblenou asphalt across the corridor
	b.rect(Rect2(WALL_L, y0, WALL_R - WALL_L, y1 - y0), ASPHALT_DARK)
	# Subtle central asphalt paver seam and aggregate tonal bands
	var seam_y := floorf(y0 / 160.0) * 160.0
	while seam_y < y1:
		b.rect(Rect2(ROAD_L + 8.0, seam_y, ROAD_R - ROAD_L - 16.0, 72.0), ASPHALT_LIGHT)
		b.line(Vector2(ROAD_L, seam_y), Vector2(ROAD_R, seam_y), Color(0.16, 0.16, 0.18, 0.45), 1.5)
		seam_y += 160.0
	b.line(Vector2(640.0, y0), Vector2(640.0, y1), Color(0.18, 0.18, 0.20, 0.35), 1.5)

	# 2. Flanking Barcelona panot sidewalks (interrupted at cross-street mouths)
	var slab := 40.0
	var sy := floorf(y0 / slab) * slab
	while sy < y1:
		if not _in_cross_street(sy + slab * 0.5):
			var row := absi(int(floorf(sy / slab)))
			var tone := SIDEWALK_PANOT.lightened(0.03) if row % 2 == 0 else SIDEWALK_PANOT.darkened(0.02)
			# Left and right sidewalk slabs
			b.rect(Rect2(WALL_L, sy, SIDEWALK_W, slab - 1.5), tone)
			b.rect(Rect2(ROAD_R, sy, SIDEWALK_W, slab - 1.5), tone)
			# Mid-sidewalk longitudinal joint
			b.line(Vector2(WALL_L + SIDEWALK_W * 0.5, sy), Vector2(WALL_L + SIDEWALK_W * 0.5, sy + slab), Color(0, 0, 0, 0.09), 1.2)
			b.line(Vector2(ROAD_R + SIDEWALK_W * 0.5, sy), Vector2(ROAD_R + SIDEWALK_W * 0.5, sy + slab), Color(0, 0, 0, 0.09), 1.2)
			# Granite curb stones
			b.rect(Rect2(ROAD_L - 5.0, sy, 5.0, slab - 1.0), CURB_STONE)
			b.rect(Rect2(ROAD_R, sy, 5.0, slab - 1.0), CURB_STONE)
			# Gutter shadow line
			b.line(Vector2(ROAD_L + 1.0, sy), Vector2(ROAD_L + 1.0, sy + slab), Color(0, 0, 0, 0.25), 2.0)
			b.line(Vector2(ROAD_R - 1.0, sy), Vector2(ROAD_R - 1.0, sy + slab), Color(0, 0, 0, 0.20), 1.5)
			# Cast-iron gutter storm grate every 8 slabs
			if row % 8 == 3:
				for gx: float in [ROAD_L + 7.0, ROAD_R - 7.0]:
					b.rect(Rect2(gx - 5.0, sy + 10.0, 10.0, 18.0), Color(0.16, 0.17, 0.19))
					for gi in range(3):
						var gy := sy + 13.0 + float(gi) * 5.0
						b.line(Vector2(gx - 3.5, gy), Vector2(gx + 3.5, gy), Color(0.06, 0.06, 0.08), 1.4)
			# West building cast shadow across the west sidewalk
			b.rect(Rect2(WALL_L, sy, 26.0, slab), Color(0.04, 0.04, 0.07, 0.14))
			b.rect(Rect2(WALL_R - 8.0, sy, 8.0, slab), Color(0.04, 0.04, 0.07, 0.10))
		sy += slab

	# 3. Tactile paving & corner curb ramps at the 3 cross-street intersections
	for cy: float in CROSS_YS:
		if cy + CROSS_HALF + 30.0 < y0 or cy - CROSS_HALF - 30.0 > y1:
			continue
		for dy: float in [-CROSS_HALF - 10.0, CROSS_HALF + 2.0]:
			var ty := cy + dy
			# Terracotta tactile blister paving strip across both sidewalk ramps
			b.rect(Rect2(WALL_L + 6.0, ty, SIDEWALK_W - 12.0, 8.0), Color(0.76, 0.34, 0.26))
			b.rect(Rect2(ROAD_R + 6.0, ty, SIDEWALK_W - 12.0, 8.0), Color(0.76, 0.34, 0.26))
		# Diagonal tactical-urbanism intersection corner chevrons
		var c_col := PAINT_YELLOW if not is_equal_approx(cy, -3800.0) else PAINT_TURQUOISE
		for cx: float in [ROAD_L + 22.0, ROAD_R - 22.0]:
			for cdy: float in [-CROSS_HALF + 16.0, CROSS_HALF - 16.0]:
				var cp := Vector2(cx, cy + cdy)
				b.circle(cp, 8.0, c_col)
				b.circle(cp, 3.5, PAINT_WHITE)

	# 4. Green cycle lane across the y = -2200 intersection (El Patí de Càrrega's route)
	if -2200.0 + 40.0 >= y0 and -2200.0 - 40.0 <= y1:
		var cy := -2200.0
		b.rect(Rect2(WALL_L, cy - 22.0, WALL_R - WALL_L, 44.0), CYCLE_GREEN)
		var dx := WALL_L + 8.0
		while dx < WALL_R - 8.0:
			b.rect(Rect2(dx, cy - 23.0, 18.0, 3.0), PAINT_WHITE)
			b.rect(Rect2(dx, cy + 20.0, 18.0, 3.0), PAINT_WHITE)
			dx += 32.0
		for bx: float in [450.0, 560.0, 720.0, 830.0]:
			# Directional cycle chevrons and bike wheel stencils
			b.line(Vector2(bx - 8.0, cy - 8.0), Vector2(bx + 3.0, cy), PAINT_WHITE, 2.4)
			b.line(Vector2(bx - 8.0, cy + 8.0), Vector2(bx + 3.0, cy), PAINT_WHITE, 2.4)
			b.circle(Vector2(bx - 18.0, cy + 5.0), 4.5, PAINT_WHITE)
			b.circle(Vector2(bx - 18.0, cy + 5.0), 2.5, CYCLE_GREEN)
			b.circle(Vector2(bx - 6.0, cy + 5.0), 4.5, PAINT_WHITE)
			b.circle(Vector2(bx - 6.0, cy + 5.0), 2.5, CYCLE_GREEN)

	# 5. Tactical urbanism painted asphalt circles (the 9 PAINT_CIRCLES)
	for i in range(PAINT_CIRCLES.size()):
		var circ: Dictionary = PAINT_CIRCLES[i]
		var p: Vector2 = circ["pos"]
		var r: float = circ["r"]
		if p.y + r + 20.0 < y0 or p.y - r - 20.0 > y1:
			continue
		var col: Color = circ["col"]
		# Outer stencil ring + main circle + lighter inner ring
		b.circle(p, r + 5.0, PAINT_WHITE)
		b.circle(p, r + 2.0, ASPHALT_DARK)
		b.circle(p, r, col)
		b.circle(p, r * 0.72, col.lightened(0.14))
		b.circle(p, r * 0.42, ASPHALT_DARK)
		b.circle(p, r * 0.34, col.lightened(0.22))
		# 12 radial white stencil dots around the perimeter ring
		for seg in range(12):
			var a := float(seg) * TAU / 12.0
			var sp := p + Vector2(cos(a), sin(a)) * (r * 0.86)
			b.circle(sp, 4.0, PAINT_WHITE)
		# Inner geometric star / superblock cross motif
		for arm in range(4):
			var a2 := float(arm) * PI * 0.5 + float(i % 2) * PI * 0.25
			var dir := Vector2(cos(a2), sin(a2))
			b.line(p - dir * (r * 0.26), p + dir * (r * 0.26), PAINT_WHITE, 3.0)
		b.circle(p, 5.5, PAINT_WHITE)

	# 6. Tactical urbanism painted play courts, diagonal curb bars & 10 km/h roundels
	for court_y: float in [-360.0, -1480.0, -3050.0, -3540.0]:
		if court_y + 90.0 < y0 or court_y - 90.0 > y1:
			continue
		_draw_tactical_play_grid(b, Vector2(640.0, court_y), int(absf(court_y)))

	for bar_y: float in [-520.0, -960.0, -1960.0, -2780.0, -3380.0, -4120.0, -4640.0]:
		if bar_y + 60.0 < y0 or bar_y - 60.0 > y1:
			continue
		_draw_tactical_curb_bars(b, bar_y)

	# 7. Concrete Poblenou ping-pong tables (PINGPONG_1, PINGPONG_2)
	for r: Rect2 in [PINGPONG_1, PINGPONG_2]:
		if r.end.y + 24.0 >= y0 and r.position.y - 24.0 <= y1:
			_draw_pingpong_table(b, r)

	# 8. Orxateria del Poblenou terrace deck and bistro tables at PRIZE (740, -4520)
	if -4420.0 >= y0 and -4620.0 <= y1:
		_draw_orxateria_terrace(b)

	b.flush(wc)


static func _draw_tactical_play_grid(b: ShapeBatch, at: Vector2, seed_i: int) -> void:
	# Painted hopscotch (xarranca) and geometric superblock street game grid
	var col1 := PAINT_YELLOW if seed_i % 2 == 0 else PAINT_TURQUOISE
	var col2 := PAINT_TERRACOTTA if seed_i % 2 == 0 else PAINT_GREEN
	var sq := 24.0
	for step in range(-2, 3):
		var cy := at.y + float(step) * (sq + 3.0)
		if absi(step) % 2 == 1:
			for sx: float in [-sq * 0.55, sq * 0.55]:
				var r := Rect2(at.x + sx - sq * 0.45, cy - sq * 0.45, sq * 0.9, sq * 0.9)
				b.rect(r.grow(2.0), PAINT_WHITE)
				b.rect(r, col1 if step < 0 else col2)
		else:
			var r2 := Rect2(at.x - sq * 0.45, cy - sq * 0.45, sq * 0.9, sq * 0.9)
			b.rect(r2.grow(2.0), PAINT_WHITE)
			b.rect(r2, col2 if step == 0 else col1)
	# Semicircle "CEL" crown at the top of the hopscotch
	b.circle(Vector2(at.x, at.y - 3.0 * sq), sq * 0.65, PAINT_WHITE)
	b.circle(Vector2(at.x, at.y - 3.0 * sq), sq * 0.50, col1)


static func _draw_tactical_curb_bars(b: ShapeBatch, y: float) -> void:
	# Diagonal painted superblock buffer stripes along both road margins + speed roundel
	var cols: Array[Color] = [PAINT_YELLOW, PAINT_TURQUOISE, PAINT_TERRACOTTA, PAINT_GREEN]
	var idx := absi(int(y / 100.0))
	var c: Color = cols[idx % cols.size()]
	for side: float in [-1.0, 1.0]:
		var x0 := ROAD_L + 8.0 if side < 0.0 else ROAD_R - 36.0
		for k in range(5):
			var by := y - 32.0 + float(k) * 16.0
			b.polygon(PackedVector2Array([
				Vector2(x0, by),
				Vector2(x0 + 28.0, by - 6.0 * side),
				Vector2(x0 + 28.0, by - 6.0 * side + 7.0),
				Vector2(x0, by + 7.0),
			]), c if k % 2 == 0 else PAINT_WHITE)
	# Painted "10" superblock speed-limit roundel on the asphalt
	if idx % 2 == 1:
		var rp := Vector2(540.0 if idx % 4 == 1 else 740.0, y)
		b.circle(rp, 22.0, PAINT_TERRACOTTA)
		b.circle(rp, 16.5, PAINT_WHITE)
		b.circle(rp, 14.5, ASPHALT_DARK)
		# "1" and "0" stencil bars inside the roundel
		b.rect(Rect2(rp.x - 7.0, rp.y - 7.0, 3.0, 14.0), PAINT_YELLOW)
		b.circle(rp + Vector2(3.5, 0.0), 6.0, PAINT_YELLOW)
		b.circle(rp + Vector2(3.5, 0.0), 3.0, ASPHALT_DARK)


static func _draw_pingpong_table(b: ShapeBatch, r: Rect2) -> void:
	# Painted court apron under the table
	b.rect(r.grow(15.5), PAINT_YELLOW)
	b.rect(r.grow(13.5), Color(0.20, 0.22, 0.25, 0.85))
	# Drop shadow and heavy precast concrete trestle legs
	b.rect(Rect2(r.position.x + 8.0, r.position.y + 10.0, r.size.x, r.size.y), SHADOW)
	b.rect(Rect2(r.position.x + 6.0, r.position.y + 10.0, r.size.x - 12.0, 10.0), PINGPONG_CONCRETE.darkened(0.28))
	b.rect(Rect2(r.position.x + 6.0, r.end.y - 20.0, r.size.x - 12.0, 10.0), PINGPONG_CONCRETE.darkened(0.28))
	# Concrete beveled table slab rim
	b.rect(r.grow(3.0), PINGPONG_CONCRETE)
	b.rect(Rect2(r.position.x - 3.0, r.end.y, r.size.x + 6.0, 4.0), PINGPONG_CONCRETE.darkened(0.22))
	# Marine-blue playing surface and crisp white boundary line
	b.rect(r, PINGPONG_LINE)
	b.rect(r.grow(-2.2), PINGPONG_TOP)
	b.rect(Rect2(r.position.x + 3.0, r.position.y + 3.0, r.size.x * 0.45, r.size.y * 0.42), PINGPONG_TOP.lightened(0.06))
	b.line(Vector2(r.get_center().x, r.position.y + 2.0), Vector2(r.get_center().x, r.end.y - 2.0), Color(0.94, 0.94, 0.96, 0.55), 1.4)
	# Perforated galvanized steel net and net brackets
	var mid_y := r.get_center().y
	b.line(Vector2(r.position.x - 3.0, mid_y + 3.0), Vector2(r.end.x + 3.0, mid_y + 3.0), SHADOW, 3.0)
	b.line(Vector2(r.position.x - 3.0, mid_y), Vector2(r.end.x + 3.0, mid_y), PINGPONG_NET, 3.5)
	b.circle(Vector2(r.position.x - 3.0, mid_y), 3.5, Color(0.32, 0.34, 0.36))
	b.circle(Vector2(r.end.x + 3.0, mid_y), 3.5, Color(0.32, 0.34, 0.36))
	# Two table-tennis paddles (red and black rubber) and a white ball resting on the corner
	var pad1 := r.position + Vector2(16.0, 18.0)
	b.circle(pad1 + Vector2(1.0, 1.5), 6.0, SHADOW)
	b.line(pad1 + Vector2(3.0, 3.0), pad1 + Vector2(8.0, 8.0), Color(0.68, 0.48, 0.28), 2.8)
	b.circle(pad1, 5.8, Color(0.82, 0.20, 0.18))
	var pad2 := r.end - Vector2(18.0, 18.0)
	b.circle(pad2 + Vector2(1.0, 1.5), 6.0, SHADOW)
	b.line(pad2 - Vector2(3.0, 3.0), pad2 - Vector2(8.0, 8.0), Color(0.68, 0.48, 0.28), 2.8)
	b.circle(pad2, 5.8, Color(0.18, 0.18, 0.20))
	b.circle(pad1 + Vector2(11.0, -3.0), 2.4, Color(0.98, 0.98, 0.96))


static func _draw_orxateria_terrace(b: ShapeBatch) -> void:
	# Slatted wooden terrace platform outside the Poblenou Orxateria (around PRIZE = 740, -4520)
	var deck := Rect2(708.0, -4584.0, 168.0, 128.0)
	b.rect(Rect2(deck.position + LIGHT * 6.0, deck.size), SHADOW)
	b.rect(deck, TIMBER_BOX.darkened(0.15))
	b.rect(deck.grow(-3.0), TIMBER_BOX)
	var py := deck.position.y + 6.0
	while py < deck.end.y - 4.0:
		b.line(Vector2(deck.position.x + 4.0, py), Vector2(deck.end.x - 4.0, py), TIMBER_BOX.darkened(0.22), 1.4)
		py += 8.0
	# Corner rosemary trough planters framing the terrace deck
	for cr: Rect2 in [
		Rect2(deck.position.x + 4.0, deck.position.y + 4.0, 42.0, 14.0),
		Rect2(deck.position.x + 4.0, deck.end.y - 18.0, 42.0, 14.0),
	]:
		b.rect(cr, Color(0.20, 0.22, 0.24))
		b.rect(cr.grow(-2.0), PLANTER_SOIL)
		for k in range(3):
			b.circle(Vector2(cr.position.x + 9.0 + float(k) * 12.0, cr.get_center().y), 5.0, OLIVE_LEAF)
	# Cafe chairs around the two marble tables
	for ch: Vector2 in [
		PRIZE + Vector2(-24.0, -6.0), PRIZE + Vector2(24.0, 6.0), PRIZE + Vector2(0.0, 24.0),
		Vector2(826.0, -4514.0), Vector2(826.0, -4462.0), Vector2(800.0, -4488.0),
	]:
		b.circle(ch + LIGHT * 3.0, 7.5, SHADOW)
		b.circle(ch, 7.2, Color(0.24, 0.54, 0.58))
		b.circle(ch - LIGHT * 1.5, 5.0, Color(0.32, 0.66, 0.70))
	# White-marble bistro tables (PRIZE table at 740, -4520 and companion table at 826, -4488)
	for tb: Vector2 in [PRIZE, Vector2(826.0, -4488.0)]:
		b.circle(tb + LIGHT * 4.5, 17.0, SHADOW)
		b.circle(tb, 16.5, Color(0.22, 0.22, 0.25))
		b.circle(tb - LIGHT * 0.6, 14.8, Color(0.94, 0.92, 0.88))
		b.circle(tb - LIGHT * 3.0, 9.0, Color(0.98, 0.97, 0.94))
	# Companion table service: pitcher of horchata and napkins
	var comp := Vector2(826.0, -4488.0)
	b.circle(comp + Vector2(-3.0, -2.0), 4.5, Color(0.96, 0.93, 0.84))
	b.circle(comp + Vector2(5.0, 3.0), 3.0, Color(0.86, 0.62, 0.32))
	# Striped Mediterranean awning projecting from the east shopfront over the sidewalk
	var aw := Rect2(864.0, -4576.0, 76.0, 112.0)
	b.rect(Rect2(aw.position + LIGHT * 8.0, aw.size), SHADOW)
	b.rect(aw, Color(0.96, 0.94, 0.88))
	var ay := aw.position.y + 4.0
	while ay < aw.end.y - 4.0:
		b.rect(Rect2(aw.position.x, ay, aw.size.x, 9.0), Color(0.20, 0.52, 0.68))
		ay += 18.0
	b.line(Vector2(aw.position.x, aw.position.y), Vector2(aw.position.x, aw.end.y), Color(0.14, 0.36, 0.48), 2.5)


# --- custom furniture hooks (cached in main's furniture section) -------------

static func draw_column(_m: Node2D, wc: Object, p: Vector2) -> void:
	var b := ShapeBatch.new()
	_draw_planter_olive(b, p)
	b.flush(wc)


static func _draw_planter_olive(b: ShapeBatch, p: Vector2) -> void:
	var hs := PLANTER_SIZE * 0.5
	var pr := Rect2(p.x - hs, p.y - hs, PLANTER_SIZE, PLANTER_SIZE)
	# Cast shadow
	b.rect(Rect2(pr.position + LIGHT * 8.0, pr.size), SHADOW)
	b.circle(p + LIGHT * 12.0, 26.0, SHADOW)
	# Heavy modular Douglas-fir timber walls with corner steel brackets
	b.rect(pr.grow(2.0), TIMBER_BOX.darkened(0.28))
	b.rect(pr, TIMBER_BOX)
	b.rect(Rect2(pr.position.x, pr.position.y, pr.size.x, 4.0), TIMBER_LIT)
	b.rect(Rect2(pr.position.x, pr.position.y, 4.0, pr.size.y), TIMBER_LIT)
	for cx: float in [pr.position.x + 2.0, pr.end.x - 5.0]:
		for cy: float in [pr.position.y + 2.0, pr.end.y - 5.0]:
			b.rect(Rect2(cx, cy, 3.0, 3.0), Color(0.20, 0.20, 0.22))
	# Dark Mediterranean soil bed
	b.rect(pr.grow(-4.5), PLANTER_SOIL)
	# Fragrant lavender and rosemary bushes at the four corners
	for lx: float in [-14.5, 14.5]:
		for ly: float in [-14.5, 14.5]:
			var lp := p + Vector2(lx, ly)
			b.circle(lp, 6.2, Color(0.28, 0.42, 0.28))
			b.circle(lp - LIGHT * 1.2, 4.2, LAVENDER_PURPLE)
			b.circle(lp + Vector2(1.8, -1.5), 2.2, LAVENDER_PURPLE.lightened(0.22))
	# Gnarled olive trunk and silvery-green Mediterranean olive canopy
	b.circle(p + Vector2(1.0, 1.5), 7.0, OLIVE_TRUNK.darkened(0.25))
	b.circle(p, 5.5, OLIVE_TRUNK)
	for off: Vector2 in [
		Vector2(-10.0, -6.0), Vector2(10.0, -5.0),
		Vector2(-9.0, 8.0), Vector2(9.0, 7.0), Vector2(0.0, -11.0), Vector2(0.0, 10.0),
	]:
		b.circle(p + off + LIGHT * 2.0, 12.5, OLIVE_LEAF.darkened(0.20))
	for off2: Vector2 in [
		Vector2(0.0, 0.0), Vector2(-9.0, -6.0), Vector2(9.0, -5.0),
		Vector2(-8.0, 7.0), Vector2(8.0, 6.0), Vector2(0.0, -10.0),
	]:
		b.circle(p + off2, 11.5, OLIVE_LEAF)
	for lit_off: Vector2 in [Vector2(-7.0, -7.0), Vector2(2.0, -9.0), Vector2(-8.0, 2.0)]:
		b.circle(p + lit_off, 7.5, OLIVE_LEAF.lightened(0.16))
	# Dark purple-black Arbequina olives glinting in the crown
	for ol: Vector2 in [Vector2(-5.0, -3.0), Vector2(6.0, -2.0), Vector2(-2.0, 6.0)]:
		b.circle(p + ol, 1.8, Color(0.22, 0.16, 0.24))


static func draw_bollard(_m: Node2D, wc: Object, h: Dictionary) -> void:
	var hp: Vector2 = h.pos
	var done := bool(h.get("done", false))
	var prog := float(h.get("progress", 0.0))
	var b := ShapeBatch.new()
	# Cast shadow
	b.circle(hp + LIGHT * 9.0, 9.0, SHADOW)
	b.line(hp, hp + LIGHT * 9.0, SHADOW, 15.0)
	# Base granite collar
	b.circle(hp, 11.5, Color(0.36, 0.36, 0.38))
	# Barcelona Superblock tactical bollard: anthracite steel with yellow reflective band
	var body := Color(0.24, 0.25, 0.27) if done else Color(0.18, 0.20, 0.22)
	b.circle(hp, 9.0, body)
	b.circle(hp - LIGHT * 1.2, 7.6, PAINT_YELLOW.darkened(0.22) if done else PAINT_YELLOW)
	b.circle(hp - LIGHT * 1.8, 5.4, body.lightened(0.08))
	b.circle(hp - LIGHT * 2.8, 2.4, Color(0.64, 0.66, 0.68))
	if not done and prog > 0.0:
		var segs := maxi(2, int(ceilf(16.0 * prog / 0.8)))
		var prev := hp + Vector2(0.0, -16.0)
		for i in range(1, segs + 1):
			var ang := -PI * 0.5 + TAU * (prog / 0.8) * (float(i) / float(segs))
			var nxt := hp + Vector2(cos(ang), sin(ang)) * 16.0
			b.line(prev, nxt, Color(1.0, 0.95, 0.70), 3.0)
			prev = nxt
	b.flush(wc)


static func draw_bin(_m: Node2D, wc: Object, bn: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(bn + LIGHT * 8.0, 12.5, SHADOW)
	# Slatted wood-and-iron Barcelona Superblock waste drum
	b.circle(bn, 13.0, Color(0.20, 0.20, 0.22))
	b.circle(bn, 11.5, TIMBER_BOX)
	for i in range(6):
		var a := float(i) * TAU / 6.0
		b.line(bn + Vector2(cos(a), sin(a)) * 7.5, bn + Vector2(cos(a), sin(a)) * 11.2, TIMBER_LIT, 2.2)
	b.circle(bn, 8.2, Color(0.24, 0.26, 0.28))
	b.circle(bn + Vector2(0.8, 1.0), 5.6, Color(0.10, 0.11, 0.12))
	# Green organic/selective ring accent
	b.circle(bn - LIGHT * 2.5, 2.4, PAINT_GREEN)
	b.flush(wc)


static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var b := ShapeBatch.new()
	# Wet splash patch on the panot sidewalk
	b.circle(f + Vector2(10.0, 7.0), 9.0, Color(0.36, 0.52, 0.62, 0.42))
	b.circle(f + LIGHT * 7.0, 12.0, SHADOW)
	# Stone drain basin with iron grate
	b.circle(f, 13.0, CURB_STONE.darkened(0.18))
	b.circle(f, 10.5, Color(0.26, 0.38, 0.46))
	b.line(f + Vector2(-7.0, -3.0), f + Vector2(7.0, -3.0), Color(0.18, 0.20, 0.22), 1.6)
	b.line(f + Vector2(-7.0, 3.0), f + Vector2(7.0, 3.0), Color(0.18, 0.20, 0.22), 1.6)
	# Classic dark-green Barcelona cast-iron column and brass tap
	var col_p := f + Vector2(0.0, -6.0)
	b.circle(col_p, 6.8, Color(0.14, 0.26, 0.20))
	b.circle(col_p - LIGHT * 1.5, 4.4, Color(0.22, 0.38, 0.28))
	b.line(col_p, f + Vector2(0.0, 2.0), Color(0.82, 0.68, 0.32), 2.6)
	b.circle(f + Vector2(0.0, 2.5), 2.2, Color(0.76, 0.90, 0.98, 0.90))
	b.flush(m._wc)


static func draw_snack(_m: Node2D, wc: Object, kp: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(kp + LIGHT * 3.0, 10.0, SHADOW)
	# Crumpled bakery wax paper napkin
	b.polygon(PackedVector2Array([
		kp + Vector2(-11.0, 2.0), kp + Vector2(-6.0, -9.0),
		kp + Vector2(8.0, -7.0), kp + Vector2(11.0, 4.0), kp + Vector2(-1.0, 9.0),
	]), Color(0.95, 0.92, 0.84))
	# Two golden Poblenou fartons (glazed sweet pastries) with sugar glaze
	b.line(kp + Vector2(-6.0, -3.0), kp + Vector2(5.0, -1.0), Color(0.78, 0.52, 0.22), 4.6)
	b.line(kp + Vector2(-5.0, -3.2), kp + Vector2(3.0, -1.6), Color(0.98, 0.96, 0.92, 0.85), 2.0)
	b.line(kp + Vector2(-5.0, 3.0), kp + Vector2(6.0, 5.0), Color(0.74, 0.48, 0.20), 4.4)
	b.line(kp + Vector2(-3.5, 2.8), kp + Vector2(4.0, 4.2), Color(0.98, 0.96, 0.92, 0.85), 1.8)
	b.flush(wc)


# --- live pass: un-taken artisan horchata prize & El Patí de Càrrega ---------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# If called standalone in a unit test without ground_layer, keep planter/pingpong draw coverage
	if not ("ground_layer" in m):
		for r: Rect2 in [PINGPONG_1, PINGPONG_2]:
			if r.end.y >= vt and r.position.y <= vb:
				_draw_pingpong_table(b, r)
		for p: Vector2 in PLANTER_POSITIONS:
			if p.y + 50.0 >= vt and p.y - 50.0 <= vb:
				_draw_planter_olive(b, p)

	# Draw the artisan horchata & fartons on the Orxateria table while un-taken
	var taken: bool = bool(m.prize_taken) if "prize_taken" in m else false
	if not taken and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		b.glow(PRIZE, 24.0, Color(1.0, 0.88, 0.42, 0.26))
		# Ceramic plate with two glazed fartons beside the tall horchata glass
		var saucer := PRIZE + Vector2(-4.5, 3.5)
		b.circle(saucer, 5.5, Color(0.86, 0.84, 0.80))
		b.line(saucer + Vector2(-4.0, -1.5), saucer + Vector2(4.0, 0.5), Color(0.80, 0.54, 0.24), 2.8)
		b.line(saucer + Vector2(-3.5, 2.0), saucer + Vector2(4.5, 3.5), Color(0.76, 0.50, 0.22), 2.6)
		# Tall frosted glass of creamy white horchata (orxata de xufa) with cinnamon & straw
		var gl := PRIZE + Vector2(3.5, -2.5)
		b.circle(gl + Vector2(1.0, 1.5), 5.2, SHADOW)
		b.circle(gl, 5.2, Color(0.78, 0.88, 0.94))
		b.circle(gl, 4.0, Color(0.98, 0.96, 0.88))
		b.circle(gl + Vector2(-1.0, -0.5), 1.4, Color(0.68, 0.42, 0.20))
		b.line(gl + Vector2(1.0, -1.0), gl + Vector2(6.5, -7.5), Color(0.88, 0.24, 0.22), 2.0)

	# Draw cargo trike live event
	if m.cargo != null:
		m.cargo.draw(b, vt, vb)


static func draw_overhead(_m: Node2D, _wc: Object) -> void:
	pass


# --- off-leash area: PASSATGE DEL VAPOR (historic steam-mill courtyard) ------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect() if m.has_method("_freedom_rect") else Rect2(70.0, -5420.0, 1110.0, 590.0)
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -4800.0
	var b := ShapeBatch.new()

	# 1. Outer Poblenou industrial brick roofscape beyond the courtyard perimeter
	b.rect(Rect2(-420.0, gate_y - 2400.0, 2140.0, 2400.0), BRICK_DARK)
	var by := r.position.y - 240.0
	var bk := 0
	while by < r.end.y + 40.0:
		for sx: Vector2 in [Vector2(-380.0, r.position.x - 24.0), Vector2(r.end.x + 24.0, 1680.0)]:
			var w := sx.y - sx.x
			b.rect(Rect2(sx.x, by, w, 52.0), BRICK_MILL if bk % 2 == 0 else BRICK_LIGHT)
			b.rect(Rect2(sx.x, by + 52.0, w, 24.0), SKYLIGHT_GLASS)
			b.line(Vector2(sx.x, by + 52.0), Vector2(sx.y, by + 52.0), Color(0.84, 0.62, 0.48), 2.0)
		by += 84.0
		bk += 1
	# North sawtooth mill wing behind the far courtyard wall
	var nx := -260.0
	while nx < 1540.0:
		b.rect(Rect2(nx, r.position.y - 210.0, 164.0, 168.0), BRICK_MILL)
		b.rect(Rect2(nx + 10.0, r.position.y - 150.0, 144.0, 32.0), SKYLIGHT_GLASS)
		b.rect(Rect2(nx + 10.0, r.position.y - 92.0, 144.0, 32.0), SKYLIGHT_GLASS)
		nx += 180.0

	# 2. West (70..300) and East (980..1180) green rain-garden beds (Surfaces.S.GRASS)
	var grass_base := Color(0.30, 0.46, 0.28)
	var grass_lit := Color(0.36, 0.54, 0.32)
	b.rect(r, grass_base)
	for side_bed: Rect2 in [
		Rect2(r.position.x + 14.0, r.position.y + 16.0, 286.0 - r.position.x, r.size.y - 32.0),
		Rect2(980.0, r.position.y + 16.0, r.end.x - 994.0, r.size.y - 32.0),
	]:
		b.rect(side_bed, grass_lit)
		# Grass tufts and Mediterranean wildflowers in the rain gardens
		for ti in range(16):
			var tx := side_bed.position.x + 18.0 + fmod(float(ti) * 67.0, maxf(20.0, side_bed.size.x - 36.0))
			var ty := side_bed.position.y + 22.0 + fmod(float(ti) * 97.0, maxf(20.0, side_bed.size.y - 44.0))
			b.circle(Vector2(tx, ty), 6.0, grass_base.darkened(0.10))
			if ti % 3 == 0:
				b.circle(Vector2(tx + 2.0, ty - 2.0), 2.5, PAINT_YELLOW if ti % 6 == 0 else LAVENDER_PURPLE)

	# 3. Central Passatge del Vapor brick-and-stone courtyard (x = 300..980, Surfaces.S.PAVEMENT)
	var court := Rect2(300.0, r.position.y, 680.0, r.size.y)
	var pave_warm := Color(0.68, 0.58, 0.48)
	var pave_terra := Color(0.64, 0.44, 0.34)
	b.rect(court, pave_warm)
	# Corten-steel and granite edging between courtyard paving and rain-garden beds
	b.rect(Rect2(294.0, r.position.y, 8.0, r.size.y), CORTEN_STEEL)
	b.rect(Rect2(978.0, r.position.y, 8.0, r.size.y), CORTEN_STEEL)
	# Terracotta brick herringbone bands and granite runner strips
	var cy := r.position.y + 36.0
	var row_i := 0
	while cy < r.end.y - 20.0:
		if row_i % 2 == 0:
			b.rect(Rect2(316.0, cy, 648.0, 28.0), pave_terra.lightened(0.08))
		b.line(Vector2(304.0, cy), Vector2(976.0, cy), Color(0.46, 0.36, 0.28, 0.38), 1.5)
		cy += 48.0
		row_i += 1
	for gx: float in [316.0, 480.0, 640.0, 800.0, 964.0]:
		b.line(Vector2(gx, r.position.y + 14.0), Vector2(gx, r.end.y - 8.0), Color(0.54, 0.48, 0.42, 0.45), 2.5)

	# 4. Iconic 19th-century octagonal factory chimney (Xemeneia del Vapor) in the courtyard
	var chim := Vector2(640.0, r.position.y + 240.0)
	# Concentric brick courtyard medallion around the chimney plinth
	b.circle(chim, 76.0, CURB_STONE)
	b.circle(chim, 70.0, pave_terra)
	b.circle(chim, 52.0, pave_warm.lightened(0.08))
	for spoke in range(8):
		var sa := float(spoke) * TAU / 8.0
		b.line(chim + Vector2(cos(sa), sin(sa)) * 28.0, chim + Vector2(cos(sa), sin(sa)) * 70.0, CURB_STONE, 2.0)
	# Long cast shadow of the tall brick smokestack
	b.polygon(PackedVector2Array([
		chim + Vector2(-18.0, 12.0),
		chim + Vector2(18.0, -12.0),
		chim + LIGHT * 88.0 + Vector2(14.0, -8.0),
		chim + LIGHT * 88.0 + Vector2(-14.0, 8.0),
	]), SHADOW)
	b.circle(chim + LIGHT * 88.0, 15.0, SHADOW)
	# Stepped square brick pedestal base
	var ped := Rect2(chim.x - 28.0, chim.y - 28.0, 56.0, 56.0)
	b.rect(Rect2(ped.position + LIGHT * 6.0, ped.size), SHADOW)
	b.rect(ped, BRICK_DARK)
	b.rect(ped.grow(-4.0), BRICK_MILL)
	b.rect(ped.grow(-8.0), Color(0.76, 0.70, 0.62))
	# Octagonal tapering red-brick chimney shaft with wrought-iron tension bands
	b.circle(chim, 22.0, BRICK_DARK)
	b.circle(chim - LIGHT * 1.5, 19.0, BRICK_MILL)
	b.circle(chim - LIGHT * 2.5, 15.0, Color(0.18, 0.18, 0.20))
	b.circle(chim - LIGHT * 3.0, 13.5, BRICK_LIGHT)
	b.circle(chim - LIGHT * 4.5, 8.5, Color(0.10, 0.09, 0.09))

	# 5. Perimeter converted red-brick factory walls (north, west, east, and gate wall)
	var wall_w := 22.0
	b.rect(Rect2(r.position.x - wall_w, r.position.y - wall_w, r.size.x + wall_w * 2.0, wall_w), BRICK_MILL)
	b.rect(Rect2(r.position.x - wall_w, r.position.y, wall_w, r.size.y), BRICK_MILL)
	b.rect(Rect2(r.end.x, r.position.y, wall_w, r.size.y), BRICK_MILL)
	var gl: float = float(m.gate_l) if "gate_l" in m else 440.0
	var gr: float = float(m.gate_r) if "gate_r" in m else 840.0
	b.rect(Rect2(r.position.x - wall_w, r.end.y - 8.0, gl - r.position.x + wall_w - 16.0, 14.0), BRICK_MILL)
	b.rect(Rect2(gr + 16.0, r.end.y - 8.0, r.end.x - gr + wall_w - 16.0, 14.0), BRICK_MILL)
	# Arched industrial casement windows along the north brick factory facade
	var wx := r.position.x + 36.0
	while wx < r.end.x - 36.0:
		if absf(wx - 640.0) > 160.0:
			b.rect(Rect2(wx - 16.0, r.position.y - 18.0, 32.0, 14.0), Color(0.16, 0.20, 0.24))
			b.rect(Rect2(wx - 14.0, r.position.y - 6.0, 28.0, 4.0), Color(0.76, 0.70, 0.62))
		wx += 76.0

	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, BENCH_WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, "The old steam-mill courtyard, off leash")


static func surface(m: Node2D, p: Vector2) -> int:
	var gate_y: float = float(m.GATE_Y) if "GATE_Y" in m else -4800.0
	if p.y < gate_y:
		if p.x >= 300.0 and p.x <= 980.0:
			return Surfaces.S.PAVEMENT
		return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT
