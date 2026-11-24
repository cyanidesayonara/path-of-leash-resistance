class_name Reial
extends RefCounted

# WALK 19: PLAÇA REIAL (The Arcaded Royal Square)
# Set in the heart of Barcelona's Gothic Quarter: an elegant 19th-century
# neoclassical royal plaza bounded by continuous arched colonnades (porxos)
# all round, towering Washingtonia royal palm trees, Antoni Gaudí's six-armed
# dragon-helmet streetlamps (Fanals de Gaudí), the ornate Font de les Tres
# Gràcies central fountain, late-night arcade bar terraces, buskers, and
# street sellers with goods on a blanket who fold up and run at the whistle.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const CityRoofs := preload("res://world/city_roofs.gd")
const HOOKS := ["build_layer", "draw_edge_layer", "draw_live", "draw_overhead", "night_fronts", "night_lights", "surface", "tick"]


const NightFronts := preload("res://world/night_fronts.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Detour := preload("res://systems/detour.gd")
const Outdoors := preload("res://systems/outdoors.gd")

const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# --- colors ------------------------------------------------------------------
const STONE_PLAZA := Color(0.72, 0.70, 0.66)
const STONE_JOINT := Color(0.62, 0.60, 0.56, 0.55)
const STONE_DARK := Color(0.56, 0.54, 0.50)
const BAND_CREAM := Color(0.84, 0.81, 0.74)
const PANOT_BORDER := Color(0.60, 0.57, 0.52)
const ARCADE_TILE := Color(0.64, 0.34, 0.24)
const ARCADE_TILE_JOINT := Color(0.50, 0.25, 0.17, 0.55)
const ARCADE_PILLAR := Color(0.84, 0.79, 0.70)
const ARCADE_FACADE := Color(0.76, 0.66, 0.52)
const ARCADE_ROOF := Color(0.46, 0.34, 0.26)
const ARCADE_PARAPET := Color(0.80, 0.72, 0.58)
const PILONA_IRON := Color(0.16, 0.18, 0.20)
const PALM_TRUNK := Color(0.46, 0.35, 0.25)
const PALM_BARK := Color(0.36, 0.26, 0.18)
const PALM_LEAF := Color(0.22, 0.50, 0.26)
const PALM_LEAF_LIGHT := Color(0.36, 0.66, 0.32)
const GAUDI_BRONZE := Color(0.20, 0.24, 0.22)
const GAUDI_MARBLE := Color(0.54, 0.26, 0.24)
const GAUDI_GOLD := Color(0.88, 0.74, 0.26)
const GAUDI_GLOBE := Color(1.0, 0.94, 0.72)
const FOUNTAIN_IRON := Color(0.18, 0.20, 0.22)
const FOUNTAIN_WATER := Color(0.34, 0.68, 0.84, 0.78)
const FOUNTAIN_STONE := Color(0.72, 0.70, 0.66)
const CHURRO_GOLD := Color(0.88, 0.68, 0.28)
const CHOCOLATE_DARK := Color(0.22, 0.12, 0.08)
const GUITAR_WOOD := Color(0.78, 0.46, 0.22)

# --- corridor layout ---------------------------------------------------------
const WEST_ARCADE_X := 350.0
const EAST_ARCADE_X := 930.0
const CORRIDOR_L := 350.0
const CORRIDOR_R := 930.0
const ARCADE_BACK_W := 240.0
const ARCADE_BACK_E := 1040.0
const PILLAR_STEP := 200.0

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

# The arcade end-wings framing the square's archways: tiled blocks with a row
# of pillars along their outer face. The south pair stands past the start
# line; the north pair is solid (walls, rope and the owner's keep-outs), and
# the archway between them is the way on.
const WING_SOUTH_Y := 290.0
const WING_NORTH_Y := -4580.0
const WING_PILLARS_X: Array[float] = [405.0, 460.0, 515.0, 765.0, 820.0, 875.0]
const NORTH_WINGS: Array[Rect2] = [
	Rect2(CORRIDOR_L, WING_NORTH_Y - 10.0, 175.0, 70.0),
	Rect2(755.0, WING_NORTH_Y - 10.0, CORRIDOR_R - 755.0, 70.0),
]

# Cast-iron Barcelona pilones at the south entrance and flanking the north
# archway, just clear of the wings so they are seen where they wrap the leash
const PILONES: Array[Vector2] = [
	Vector2(506.0, 220.0),
	Vector2(774.0, 220.0),
	Vector2(542.0, -4494.0),
	Vector2(738.0, -4494.0),
]

# Late-night bar terraces with marble bistro tables under the portico arcades
const TERRACES: Array[Rect2] = [
	Rect2(352.0, -1250.0, 78.0, 160.0),
	Rect2(850.0, -1250.0, 78.0, 160.0),
	Rect2(352.0, -2650.0, 78.0, 160.0),
	Rect2(850.0, -2650.0, 78.0, 160.0),
	Rect2(352.0, -3850.0, 78.0, 160.0),
	Rect2(850.0, -3850.0, 78.0, 160.0),
]

# Spanish guitar busker under the west arcade + sax/cajon busker under the east arcade
const BUSKER_POS := Vector2(385.0, -1950.0)
const BUSKER2_POS := Vector2(895.0, -3550.0)

# Hot churros and chocolate prize by the east terrace
const PRIZE := Vector2(890.0, -2700.0)
const PRIZE_TEXT := "nab the hot churros off the terrace table"

# Plaza pigeons pecking breadcrumbs
const PIGEON_SPOTS: Array[Vector2] = [
	Vector2(640.0, -1100.0),
	Vector2(520.0, -1900.0),
	Vector2(760.0, -2300.0),
	Vector2(580.0, -3100.0),
	Vector2(700.0, -3700.0),
]

# Night-time street sellers with goods on a white sheet (fold up & run at the whistle)
# to the nearest arch of the arcade, just inside the colonnade
const SELLER_SPECS: Array = [
	[Rect2(495.0, -1490.0, 72.0, 50.0), "glow"],
	[Rect2(715.0, -2250.0, 72.0, 50.0), "shades"],
	[Rect2(495.0, -3050.0, 72.0, 50.0), "bags"],
]
const SELLER_WARN_DURATION := 0.8
const SELLER_WHISTLE_FIRST := 16.0
const SELLER_WHISTLE_EVERY := 28.0
const SELLER_RUN_SPEED := 155.0
const SELLER_AWAY_TIME := 6.0
const SELLER_RUN_DY := 160.0
const SELLER_ARCH_INSET := 14.0
const GLOW_COLS: Array[Color] = [Color(0.35, 0.95, 0.90), Color(0.98, 0.45, 0.75), Color(0.98, 0.92, 0.32)]
const BAG_COLS: Array[Color] = [Color(0.76, 0.28, 0.24), Color(0.24, 0.46, 0.68), Color(0.82, 0.66, 0.26)]
const CHAIR_DY: Array[float] = [-13.0, 13.0]

const PATRON_COATS: Array[Color] = [
	Color(0.24, 0.28, 0.38),
	Color(0.56, 0.26, 0.26),
	Color(0.24, 0.40, 0.30),
	Color(0.46, 0.36, 0.24),
	Color(0.36, 0.26, 0.42),
]
const PATRON_HAIR: Array[Color] = [
	Color(0.18, 0.14, 0.12),
	Color(0.38, 0.24, 0.16),
	Color(0.68, 0.56, 0.36),
	Color(0.54, 0.52, 0.50),
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
	for w: Rect2 in NORTH_WINGS:
		out.append(w)
	return out


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t: Rect2 in TERRACES:
		out.append(t)
	# Central fountain collision footprint
	out.append(Rect2(FOUNTAIN_POS.x - FOUNTAIN_RADIUS, FOUNTAIN_POS.y - FOUNTAIN_RADIUS,
		FOUNTAIN_RADIUS * 2.0, FOUNTAIN_RADIUS * 2.0))
	for w: Rect2 in NORTH_WINGS:
		out.append(w)
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
	# Entrance pilones
	for p: Vector2 in PILONES:
		m.poles.append(p)


static func _seller_home(r: Rect2) -> Vector2:
	var inward := 1.0 if r.get_center().x < 640.0 else -1.0
	return Vector2(r.get_center().x + inward * (r.size.x * 0.5 + 15.0), r.get_center().y)


static func _init_sellers(m: Node2D) -> void:
	var list: Array[Dictionary] = []
	for si in range(SELLER_SPECS.size()):
		var sp_item: Array = SELLER_SPECS[si]
		var r: Rect2 = sp_item[0]
		var home := _seller_home(r)
		list.append({
			"rect": r,
			"goods": String(sp_item[1]),
			"run_dy": -SELLER_RUN_DY if si % 2 == 0 else SELLER_RUN_DY,
			"home": home,
			"pos": home,
			"to": Vector2.ZERO,
			"state": "laid",
			"t": 0.0,
			"cd": 0.0,
			"bump_cd": 0.0,
		})
	m.set_meta("reial_sellers", list)
	m.set_meta("reial_whistle_t", SELLER_WHISTLE_FIRST)


static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA REIAL"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([FOUNTAIN_POS], TYPE_VECTOR2, &"", null)
	if not m.tutorial_mode:
		m.waiter = Waiter.new()
	m.bins = Array([
		Vector2(365.0, -1400.0),
		Vector2(915.0, -1400.0),
		Vector2(365.0, -3200.0),
		Vector2(915.0, -3200.0),
	], TYPE_VECTOR2, &"", null)

	# The fountain island directs owner around the central fountain (east side)
	m.islands = Array([{"rect": Rect2(FOUNTAIN_POS - Vector2(FOUNTAIN_RADIUS + 24.0, FOUNTAIN_RADIUS + 24.0), Vector2((FOUNTAIN_RADIUS + 24.0) * 2.0, (FOUNTAIN_RADIUS + 24.0) * 2.0)), "side": 1.0, "lead": 180.0}], TYPE_DICTIONARY, &"", null)

	setup_poles(m)
	# the owner aims through the north archway, not into a wing's end
	for w: Rect2 in NORTH_WINGS:
		m.owner_keepouts.append(w)
	_init_sellers(m)

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


static func _draw_pilona(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Shade.light * 3.0, 7.5, SHADOW)
	b.circle(p, 7.0, PILONA_IRON)
	b.circle(p, 4.5, Color(0.28, 0.30, 0.33))
	b.circle(p, 2.2, GAUDI_GOLD)


static func _draw_terrace(b: ShapeBatch, tr: Rect2, ti: int, patrons: bool) -> void:
	var on_west := tr.get_center().x < 640.0
	b.rect(Rect2(tr.position + Shade.light * 4.0, tr.size), SHADOW)
	# Warm slate-wood terrace deck and brass rail border
	b.rect(tr, Color(0.20, 0.17, 0.16, 0.72))
	b.rect(Rect2(tr.position + Vector2(3.0, 3.0), tr.size - Vector2(6.0, 6.0)), Color(0.28, 0.22, 0.19, 0.82))
	# Striped bar awning strip hugging the arcade side
	var ax := tr.position.x if on_west else tr.end.x - 14.0
	for s in range(8):
		var sy := tr.position.y + float(s) * (tr.size.y / 8.0)
		var acol := Color(0.58, 0.20, 0.18) if s % 2 == 0 else Color(0.88, 0.82, 0.68)
		b.rect(Rect2(ax, sy, 14.0, tr.size.y / 8.0 - 1.0), acol)
	# Bistro tables, tucked chairs, candle lanterns and late-night patrons
	var cols := 2
	var rows := int(tr.size.y / 48.0)
	for r in range(rows):
		for c in range(cols):
			var tp := tr.position + Vector2(18.0 + float(c) * 42.0, 26.0 + float(r) * 48.0)
			# Bistro chairs north & south
			for dy: float in CHAIR_DY:
				b.circle(tp + Vector2(0.0, dy), 5.0, Color(0.18, 0.16, 0.16))
			b.circle(tp + Shade.light * 3.0, 11.5, SHADOW)
			b.circle(tp, 10.5, Color(0.92, 0.90, 0.86)) # marble top
			# Small table candle & drinks (never food-crawl trays)
			b.circle(tp + Vector2(0.0, -1.0), 2.5, Color(1.0, 0.86, 0.45))
			b.circle(tp + Vector2(4.0, 3.0), 2.2, Color(0.84, 0.56, 0.22))
			b.circle(tp + Vector2(-4.0, 2.5), 2.0, Color(0.75, 0.88, 0.94))
			# Seated late-night patron at alternate chairs
			var idx := ti * 7 + r * 2 + c
			if patrons and idx % 3 != 0:
				var side_y := -14.0 if idx % 2 == 0 else 14.0
				var sp := tp + Vector2(0.0, side_y)
				b.circle(sp + Vector2(1.5, 2.5), 8.5, SHADOW)
				b.circle(sp, 8.0, PATRON_COATS[idx % PATRON_COATS.size()])
				b.circle(sp + Vector2(0.0, -1.5), 4.8, PATRON_HAIR[idx % PATRON_HAIR.size()])


static func _draw_busker_scene(b: ShapeBatch, pos: Vector2, is_guitar: bool, t: float) -> void:
	# Stool / performer shadow
	b.circle(pos + Shade.light * 4.0, 14.0, SHADOW)
	b.circle(pos, 12.0, Color(0.24, 0.28, 0.36) if is_guitar else Color(0.32, 0.22, 0.26))
	b.circle(pos + Vector2(0.0, -3.0), 6.5, Color(0.22, 0.16, 0.12))
	var strum := sin(t * 7.0) * 1.6
	if is_guitar:
		var gp := pos + Vector2(12.0, -4.0 + strum * 0.4)
		b.circle(gp + Vector2(0, 4), 6.0, GUITAR_WOOD)
		b.circle(gp + Vector2(0, -3), 4.5, GUITAR_WOOD)
		b.line(gp + Vector2(0, -3), gp + Vector2(0, -13), Color(0.2, 0.15, 0.1), 2.0)
	else:
		# Brass saxophone glint
		var sx := pos + Vector2(-11.0, -3.0 + strum * 0.4)
		b.line(sx, sx + Vector2(-4.0, 10.0), GAUDI_GOLD, 3.0)
		b.circle(sx + Vector2(-5.0, 11.0), 3.5, GAUDI_GOLD)
	# Open instrument case with tossed coins
	var cp := pos + (Vector2(24.0, 10.0) if is_guitar else Vector2(-24.0, 10.0))
	b.rect(Rect2(cp.x - 6.0, cp.y - 12.0, 12.0, 24.0), Color(0.12, 0.10, 0.14))
	b.circle(cp + Vector2(0, -4), 2.0, Color(0.94, 0.82, 0.25))
	b.circle(cp + Vector2(2, 4), 1.8, Color(0.90, 0.80, 0.30))
	# Two onlookers listening
	if not Outdoors.busker_onlookers(Game.weather, Game.hour):
		return
	var dir := 1.0 if is_guitar else -1.0
	for k in range(2):
		var lp := pos + Vector2(dir * (38.0 + float(k) * 10.0), -14.0 + float(k) * 28.0)
		b.circle(lp + Vector2(2, 3), 9.0, SHADOW)
		b.circle(lp, 8.5, PATRON_COATS[(k + (0 if is_guitar else 2)) % PATRON_COATS.size()])
		b.circle(lp + Vector2(0.0, -2.0), 5.0, PATRON_HAIR[(k + 1) % PATRON_HAIR.size()])


# Where the square's paving, arcades and roofs stop at the north end: the
# corridor's own line at the gate, so no strip of plain street shows between
# the archway and the off-leash plaça.
static func _north_end(m: Node2D) -> float:
	return float(m.GATE_Y) - 40.0


static func draw_edge_layer(m: Node2D, b: ShapeBatch, _vt: float = 0.0, _vb: float = 0.0) -> void:
	if m.lvl != "reial":
		return
	var top := _north_end(m)
	# the palace blocks behind the arcades: their cornice, then their roofs
	var ry := floorf(maxf(_vt - 260.0, top) / 220.0) * 220.0
	while ry < minf(_vb + 60.0, 400.0):
		var r0 := maxf(ry, top)
		for side: float in [-1.0, 1.0]:
			var f := ARCADE_BACK_W if side < 0.0 else ARCADE_BACK_E
			b.rect(Rect2(minf(f, f + side * 16.0), r0, 16.0, ry + 220.0 - r0), Color(0.80, 0.70, 0.52))
			b.rect(Rect2(minf(f + side * 12.0, f + side * 16.0), r0, 4.0, ry + 220.0 - r0), Color(0.94, 0.86, 0.68))
			CityRoofs.kept_module(b, f + side * 16.0, side, 460.0, r0, ry + 220.0, 900 + int(absf(ry) / 220.0) * 2 + (1 if side > 0.0 else 0))
		ry += 220.0
	# Arcade portico flooring on the flanks (terracotta tiles)
	b.rect(Rect2(ARCADE_BACK_W, top, WEST_ARCADE_X - ARCADE_BACK_W, 400.0 - top), ARCADE_TILE)
	b.rect(Rect2(EAST_ARCADE_X, top, ARCADE_BACK_E - EAST_ARCADE_X, 400.0 - top), ARCADE_TILE)
	# Subtle arcade bay floor joints
	var ty := -4900.0
	while ty < 380.0:
		b.line(Vector2(ARCADE_BACK_W, ty), Vector2(WEST_ARCADE_X, ty), ARCADE_TILE_JOINT, 1.5)
		b.line(Vector2(EAST_ARCADE_X, ty), Vector2(ARCADE_BACK_E, ty), ARCADE_TILE_JOINT, 1.5)
		ty += PILLAR_STEP

	# Main plaza flagstones (polished granite)
	b.rect(Rect2(CORRIDOR_L, top, CORRIDOR_R - CORRIDOR_L, 400.0 - top), STONE_PLAZA)

	# Panot threshold strips along west and east arcade colonnades
	b.rect(Rect2(CORRIDOR_L - 4.0, top, 16.0, 380.0 - top), PANOT_BORDER)
	b.rect(Rect2(CORRIDOR_R - 12.0, top, 16.0, 380.0 - top), PANOT_BORDER)

	# the flags, big and worn, each its own gray, warmed toward the middle
	var fy := floorf(maxf(_vt - 80.0, top) / 60.0) * 60.0
	while fy < minf(_vb + 80.0, 380.0):
		var row := int(absf(fy) / 60.0)
		var fx := CORRIDOR_L + 12.0 - (40.0 if row % 2 == 0 else 0.0)
		while fx < CORRIDOR_R - 12.0:
			var x0 := maxf(fx, CORRIDOR_L + 12.0)
			var x1 := minf(fx + 80.0, CORRIDOR_R - 12.0)
			var h := fposmod(sin(float(row * 53) + fx * 0.71) * 43758.5, 1.0)
			if x1 - x0 > 3.0 and fy > top:
				b.rect(Rect2(x0 + 0.8, fy + 0.8, x1 - x0 - 1.6, 58.4), STONE_PLAZA.lerp(Color(0.86, 0.78, 0.66), 0.10 + 0.30 * h) if h > 0.4 else STONE_PLAZA.darkened(0.08 * h + 0.02))
			fx += 80.0
		fy += 60.0

	# Square flagstone ashlar grid across the royal plaza
	for gx: float in [430.0, 510.0, 590.0, 690.0, 770.0, 850.0]:
		b.line(Vector2(gx, top), Vector2(gx, 340.0), STONE_JOINT, 1.2)
	var gy := -4960.0
	while gy < 340.0:
		b.line(Vector2(CORRIDOR_L + 12.0, gy), Vector2(CORRIDOR_R - 12.0, gy), STONE_JOINT, 1.2)
		gy += 120.0

	# Decorative limestone bands framing the square's bays
	for y: float in [-1300.0, -2100.0, -2900.0, -3700.0]:
		b.rect(Rect2(CORRIDOR_L + 12.0, y, CORRIDOR_R - CORRIDOR_L - 24.0, 8.0), BAND_CREAM)
		b.rect(Rect2(CORRIDOR_L + 12.0, y + 2.0, CORRIDOR_R - CORRIDOR_L - 24.0, 4.0), STONE_DARK)

	# Radial starburst paving around the central Three Graces fountain
	for i in range(12):
		var a := float(i) * (TAU / 12.0)
		var dir := Vector2(cos(a), sin(a))
		b.line(FOUNTAIN_POS + dir * (FOUNTAIN_RADIUS + 4.0), FOUNTAIN_POS + dir * 116.0, BAND_CREAM, 3.5)

	# Fountain base, basin, and central Three Graces pedestal
	b.circle(FOUNTAIN_POS + Shade.light * 8.0, FOUNTAIN_RADIUS + 5.0, SHADOW)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS + 2.0, BAND_CREAM)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS - 1.0, FOUNTAIN_STONE)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS - 7.0, FOUNTAIN_IRON)
	b.circle(FOUNTAIN_POS, FOUNTAIN_RADIUS - 10.0, FOUNTAIN_WATER)
	# Three Graces pedestal lobes and upper bowl
	for g in range(3):
		var ga := float(g) * (TAU / 3.0) - PI * 0.5
		b.circle(FOUNTAIN_POS + Vector2(cos(ga), sin(ga)) * 11.0, 6.0, FOUNTAIN_STONE)
	b.circle(FOUNTAIN_POS, 16.0, FOUNTAIN_STONE)
	b.circle(FOUNTAIN_POS, 10.0, FOUNTAIN_IRON)
	b.circle(FOUNTAIN_POS, 4.5, GAUDI_GOLD)

	# Gaudí 6-armed lampposts (Fanals de Gaudí)
	for gp: Vector2 in GAUDI_POSTS:
		b.circle(gp, 48.0, BAND_CREAM)
		b.circle(gp, 42.0, STONE_PLAZA)
		b.circle(gp + Shade.light * 6.0, 24.0, SHADOW)
		b.circle(gp, 20.0, GAUDI_MARBLE)
		b.circle(gp, 14.0, GAUDI_BRONZE)
		for i in range(6):
			var a := float(i) * (TAU / 6.0)
			var arm := gp + Vector2(cos(a), sin(a)) * 26.0
			b.line(gp, arm, GAUDI_BRONZE, 3.2)
			b.circle(arm + Shade.light * 2.0, 5.2, SHADOW)
			b.circle(arm, 4.8, GAUDI_GLOBE)
		b.circle(gp, 6.5, GAUDI_GOLD)

	# Palm tree trunks and iron grates
	for p: Vector2 in PALMS:
		b.circle(p + Shade.light * 5.0, 16.0, SHADOW)
		b.circle(p, 16.0, STONE_DARK)
		b.circle(p, 12.0, PALM_TRUNK)
		b.circle(p, 7.0, PALM_BARK)

	# Cast-iron Barcelona pilones at the south and north archways
	for pl: Vector2 in PILONES:
		_draw_pilona(b, pl)

	# Dining terraces under the arcades, their tables empty when it is wet
	var patrons := Outdoors.terrace_patrons(Game.weather, Game.hour)
	for ti in range(TERRACES.size()):
		_draw_terrace(b, TERRACES[ti], ti, patrons)

	# Hot churros and chocolate prize
	b.circle(PRIZE + Shade.light * 3.0, 10.0, SHADOW)
	b.circle(PRIZE, 9.0, Color(0.95, 0.94, 0.90))
	b.circle(PRIZE + Vector2(-3, -2), 3.5, CHOCOLATE_DARK)
	b.line(PRIZE + Vector2(0, 2), PRIZE + Vector2(6, -4), CHURRO_GOLD, 3.0)
	b.line(PRIZE + Vector2(2, 4), PRIZE + Vector2(7, 0), CHURRO_GOLD, 3.0)

	# Continuous neoclassical arcade colonnade pillars (every 200 px) & end wings
	var py := -4800.0
	while py <= 300.0:
		# Cast shadow from pillar into the arcade
		b.rect(Rect2(WEST_ARCADE_X - 18.0, py - 10.0, 12.0, 20.0), Color(0.10, 0.08, 0.08, 0.35))
		b.rect(Rect2(EAST_ARCADE_X + 6.0, py - 10.0, 12.0, 20.0), Color(0.10, 0.08, 0.08, 0.35))
		b.rect(Rect2(WEST_ARCADE_X - 12.0, py - 12.0, 24.0, 24.0), STONE_DARK)
		b.rect(Rect2(WEST_ARCADE_X - 10.0, py - 10.0, 20.0, 20.0), ARCADE_PILLAR)
		b.rect(Rect2(EAST_ARCADE_X - 12.0, py - 12.0, 24.0, 24.0), STONE_DARK)
		b.rect(Rect2(EAST_ARCADE_X - 10.0, py - 10.0, 20.0, 20.0), ARCADE_PILLAR)
		py += PILLAR_STEP

	# South and north arcade end-wings framing the square's grand archways
	for ey: float in [WING_SOUTH_Y, WING_NORTH_Y]:
		b.rect(Rect2(CORRIDOR_L, ey, 165.0, 60.0), ARCADE_TILE)
		b.rect(Rect2(765.0, ey, 165.0, 60.0), ARCADE_TILE)
		for ex: float in WING_PILLARS_X:
			b.rect(Rect2(ex - 10.0, ey - 10.0, 20.0, 20.0), STONE_DARK)
			b.rect(Rect2(ex - 8.0, ey - 8.0, 16.0, 16.0), ARCADE_PILLAR)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "reial":
		return
	var b := ShapeBatch.new(ci)
	var t: float = AnimClock.msec() / 1000.0
	# Arcade roof cornice & ochre parapet framing west and east sides of the square
	var top := _north_end(m)
	# the palace's long roof over each arcade: tiles down its two slopes, a
	# balustrade along the front, a dormer lit over each bay, chimneys between
	for side: float in [-1.0, 1.0]:
		var f := 240.0 if side < 0.0 else 1040.0
		var x := func(a: float, z: float) -> Rect2: return Rect2(minf(f + side * a, f + side * z), top, absf(z - a), 400.0 - top)
		b.rect(x.call(8.0, 64.0), ARCADE_ROOF.lightened(0.10 if side > 0.0 else -0.12))
		b.rect(x.call(64.0, 118.0), ARCADE_ROOF.lightened(-0.12 if side > 0.0 else 0.10))
		var ty := top + 6.0
		while ty < 400.0:
			b.line(Vector2(f + side * 9.0, ty), Vector2(f + side * 117.0, ty), ARCADE_ROOF.darkened(0.24), 1.4)
			ty += 10.0
		b.rect(x.call(62.0, 66.0), ARCADE_ROOF.lightened(0.28))
		b.rect(x.call(-8.0, 8.0), ARCADE_PARAPET)
		b.rect(x.call(-8.0, -5.0), ARCADE_PARAPET.lightened(0.18))
		var by := top + 8.0
		while by < 396.0:
			b.circle(Vector2(f, by), 2.6, ARCADE_PARAPET.darkened(0.32))
			by += 13.0
		var wy := -4800.0
		while wy < 300.0:
			var d := Vector2(f + side * 36.0, wy)
			b.rect(Rect2(d - Vector2(17, 15) + Shade.light * 6.0, Vector2(34, 30)), Color(0.04, 0.03, 0.06, 0.3))
			b.rect(Rect2(d - Vector2(17, 15), Vector2(34, 30)), ARCADE_FACADE)
			b.rect(Rect2(d.x - side * 15.0 - 3.0, d.y - 10.0, 6.0, 20.0), Color(1.0, 0.82, 0.50) if int(absf(wy) / 200.0) % 3 != 1 else Color(0.22, 0.22, 0.28))
			b.line(Vector2(d.x - 17.0, wy), Vector2(d.x + 17.0, wy), ARCADE_ROOF.lightened(0.22), 2.4)
			var ch := Vector2(f + side * 84.0, wy + 100.0)
			b.rect(Rect2(ch - Vector2(9, 12) + Shade.light * 7.0, Vector2(18, 24)), Color(0.04, 0.03, 0.06, 0.3))
			b.rect(Rect2(ch - Vector2(9, 12), Vector2(18, 24)), ARCADE_FACADE.darkened(0.30))
			for q in range(3):
				b.circle(ch + Vector2(0.0, -7.0 + 7.0 * float(q)), 2.4, Color(0.14, 0.10, 0.10))
			wy += 200.0

	# Towering palm fronds overhead
	for p: Vector2 in PALMS:
		for layer in range(2):
			var n := 11 if layer == 0 else 8
			for i in range(n):
				var a := float(i) * (TAU / float(n)) + sin(t * 1.5 + p.y * 0.01 + float(i)) * 0.04 + p.x * 0.1 + float(layer) * 0.3
				var ln := (62.0 if layer == 0 else 42.0) + sin(float(i) * 2.4) * 8.0
				var d := Vector2.from_angle(a)
				var o := d.orthogonal()
				var col := PALM_LEAF if layer == 0 else PALM_LEAF_LIGHT
				b.polygon(PackedVector2Array([p, p + d * ln * 0.35 + o * 7.5, p + d * ln * 0.75 + o * 4.5, p + d * ln, p + d * ln * 0.75 - o * 4.5, p + d * ln * 0.35 - o * 7.5]), col)
				b.line(p, p + d * ln * 0.9, col.darkened(0.28), 1.4)
		b.circle(p, 8.0, PALM_TRUNK)
		b.circle(p - Vector2(1.5, 1.5), 4.6, PALM_BARK)
	b.flush()


static func _draw_seller_good(b: ShapeBatch, goods: String, gp: Vector2, k: int) -> void:
	match goods:
		"glow":
			b.circle(gp, 3.8, GLOW_COLS[k % GLOW_COLS.size()])
			b.circle(gp, 1.6, Color(1.0, 1.0, 0.95))
		"shades":
			b.rect(Rect2(gp.x - 5.0, gp.y - 2.0, 4.0, 3.0), Color(0.14, 0.14, 0.18))
			b.rect(Rect2(gp.x + 1.0, gp.y - 2.0, 4.0, 3.0), Color(0.14, 0.14, 0.18))
			b.line(gp + Vector2(-1.0, -1.0), gp + Vector2(1.0, -1.0), Color(0.86, 0.72, 0.28), 1.2)
		_:
			b.rect(Rect2(gp.x - 4.0, gp.y - 3.5, 8.0, 7.0), BAG_COLS[k % BAG_COLS.size()])


static func _draw_sellers(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if not Outdoors.street_sellers(Game.weather, Game.hour):
		return
	if not m.has_meta("reial_sellers"):
		return
	var sellers: Array = m.get_meta("reial_sellers")
	for si in range(sellers.size()):
		var sl: Dictionary = sellers[si]
		var r: Rect2 = sl["rect"]
		if r.end.y < vt - 220.0 or r.position.y > vb + 220.0:
			continue
		var st := String(sl["state"])
		var sp: Vector2 = sl["pos"]
		if st == "laid" or st == "warn":
			b.rect(Rect2(r.position + Vector2(2.0, 3.0), r.size), SHADOW)
			var shrink := 0.0 if st == "laid" else clampf(float(sl["t"]) / SELLER_WARN_DURATION, 0.0, 0.65)
			var sr := r.grow(-shrink * 16.0)
			b.rect(sr, Color(0.92, 0.91, 0.88))
			b.line(Vector2(sr.get_center().x, sr.position.y + 2.0), Vector2(sr.get_center().x, sr.end.y - 2.0), Color(0.82, 0.80, 0.76), 1.4)
			# Corner cords gathered toward seller's hand
			_sheet_cord(b, sr.position, sp)
			_sheet_cord(b, Vector2(sr.end.x, sr.position.y), sp)
			_sheet_cord(b, Vector2(sr.position.x, sr.end.y), sp)
			_sheet_cord(b, sr.end, sp)
			var goods := String(sl["goods"])
			for gi in range(6):
				var gp := sr.position + Vector2(14.0 + float(gi % 3) * 21.0, 14.0 + float(gi / 3) * 20.0)
				_draw_seller_good(b, goods, gp, gi + si)
		elif st == "unpack":
			b.rect(Rect2(r.get_center() - Vector2(18.0, 12.0), Vector2(36.0, 24.0)), Color(0.88, 0.86, 0.82))
		# Seller figure
		b.circle(sp + Vector2(2.0, 3.0), 10.5, SHADOW)
		b.circle(sp, 10.0, Color(0.20, 0.24, 0.32))
		b.circle(sp + Vector2(0.0, -3.0), 6.0, Color(0.36, 0.24, 0.17))
		if st == "carry" or st == "away" or st == "back":
			# Bundled sheet slung over shoulder
			b.circle(sp + Vector2(11.0, 3.0), 12.0, Color(0.88, 0.86, 0.82))
			b.circle(sp + Vector2(9.0, 1.0), 8.0, Color(0.94, 0.93, 0.90))


static func _sheet_cord(b: ShapeBatch, corner: Vector2, sp: Vector2) -> void:
	b.line(corner, corner.lerp(sp, 0.42), Color(0.28, 0.28, 0.32, 0.8), 1.2)


# The waiter, buskers, water ripples and street sellers draw on the live world pass.
# A busker is out only in busking weather (Outdoors.busking); in the wet the
# arches stand empty.
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var t: float = AnimClock.msec() / 1000.0
	if FOUNTAIN_POS.y > vt - 120.0 and FOUNTAIN_POS.y < vb + 120.0:
		var rip := 20.0 + fposmod(t * 14.0, 12.0)
		wc.circle(FOUNTAIN_POS, rip, Color(0.75, 0.92, 0.98, 0.22 * (1.0 - (rip - 20.0) / 12.0)))
	if Outdoors.busking(Game.weather, Game.hour):
		if BUSKER_POS.y > vt - 120.0 and BUSKER_POS.y < vb + 120.0:
			_draw_busker_scene(wc, BUSKER_POS, true, t)
		if BUSKER2_POS.y > vt - 120.0 and BUSKER2_POS.y < vb + 120.0:
			_draw_busker_scene(wc, BUSKER2_POS, false, t)
	_draw_sellers(m, wc, vt, vb)
	if m.waiter != null:
		m.waiter.draw(m, wc, vt, vb)


static func build_layer(m: Node2D) -> void:
	Detour.build_layer(m)


static func _tick_sellers(m: Node2D, delta: float) -> void:
	if not Outdoors.street_sellers(Game.weather, Game.hour):
		return
	if not m.has_meta("reial_sellers"):
		return
	var sellers: Array = m.get_meta("reial_sellers")
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	var cam_y: float = m.cam.position.y if m.cam != null else hp.y

	# Whistle timer: telegraphs 0.8s before sellers fold up and run
	var wt := float(m.get_meta("reial_whistle_t", SELLER_WHISTLE_FIRST)) - delta
	if wt <= 0.0:
		var near_laid: Array[Dictionary] = []
		for sl: Dictionary in sellers:
			if String(sl["state"]) == "laid" and absf((sl["rect"] as Rect2).get_center().y - cam_y) < 460.0:
				near_laid.append(sl)
		if near_laid.is_empty():
			wt = 5.0
		else:
			wt = SELLER_WHISTLE_EVERY
			m.float_text(Vector2(640.0, cam_y - 200.0), I18n.t("w_phweet"), Color(0.9, 0.95, 1.0))
			m.feed.say(I18n.t("w_phweet_sellers_pack_up"), EventFeed.Tone.LOUD)
			for sl: Dictionary in near_laid:
				sl["state"] = "warn"
				sl["t"] = 0.0
				m.float_text(Vector2(sl["pos"]) + Vector2(0, -24), I18n.t("w_pack_up"), Color(1.0, 0.88, 0.65), m.POP_SAY)
	m.set_meta("reial_whistle_t", wt)

	for sl: Dictionary in sellers:
		sl["cd"] = maxf(0.0, float(sl["cd"]) - delta)
		sl["bump_cd"] = maxf(0.0, float(sl["bump_cd"]) - delta)
		var r: Rect2 = sl["rect"]
		var st := String(sl["state"])
		if st == "laid":
			if m.dog.bark_anim > 0.0 and dp.distance_to(r.get_center()) < 90.0:
				sl["state"] = "warn"
				sl["t"] = 0.0
				m.float_text(Vector2(sl["pos"]) + Vector2(0, -24), I18n.t("w_pack_up"), Color(1.0, 0.88, 0.65), m.POP_SAY)
			elif r.grow(4.0).has_point(dp) and float(sl["cd"]) <= 0.0:
				sl["cd"] = 3.0
				m.float_text(Vector2(sl["pos"]) + Vector2(0, -22), I18n.t("w_hey_careful_2"), Color(1.0, 0.9, 0.75), m.POP_SAY)
			continue

		sl["t"] = float(sl["t"]) + delta
		var sp: Vector2 = sl["pos"]
		var home: Vector2 = sl["home"]
		match st:
			"warn":
				if float(sl["t"]) >= SELLER_WARN_DURATION:
					# into the nearest arch: a bay's middle, between two pillars
					var to_west := r.get_center().x < 640.0
					var ax := CORRIDOR_L + SELLER_ARCH_INSET if to_west else CORRIDOR_R - SELLER_ARCH_INSET
					var ay := clampf(r.get_center().y + float(sl["run_dy"]), float(m.GATE_Y) + 120.0, float(m.START_Y) - 120.0)
					ay = roundf((ay + 4500.0) / PILLAR_STEP) * PILLAR_STEP - 4500.0
					sl["to"] = Vector2(ax, ay)
					sl["state"] = "carry"
					sl["t"] = 0.0
			"carry":
				sp = sp.move_toward(sl["to"], SELLER_RUN_SPEED * delta)
				sl["pos"] = sp
				if float(sl["bump_cd"]) <= 0.0 and sp.distance_to(hp) < 24.0:
					sl["bump_cd"] = 2.0
					m.human.patience = maxf(0.0, m.human.patience - 0.08)
					m.float_text(hp + Vector2(0, -32), I18n.t("w_watch_out"), Color(1.0, 0.78, 0.55), m.POP_SAY)
				if sp.distance_to(sl["to"]) < 2.0:
					sl["state"] = "away"
					sl["t"] = 0.0
			"away":
				if float(sl["t"]) >= SELLER_AWAY_TIME:
					sl["state"] = "back"
					sl["t"] = 0.0
			"back":
				sp = sp.move_toward(home, SELLER_RUN_SPEED * 0.7 * delta)
				sl["pos"] = sp
				if sp.distance_to(home) < 2.0:
					sl["state"] = "unpack"
					sl["t"] = 0.0
			"unpack":
				if float(sl["t"]) >= 0.6:
					sl["state"] = "laid"
					sl["t"] = 0.0


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "reial":
		return
	# The fountain goal is a real drink: main._bodily sets dog.drinking at
	# the rim (its 68 px reach on this walk), standing still. The Gaudi goal
	# is a real wrap and is set by main._tick_vault on a static contact.
	if not m.reial_fountain_drank and m.dog.drinking > DRINK_CREDIT:
		if m.dog.global_position.distance_to(FOUNTAIN_POS) < FOUNTAIN_DRINK_R:
			m.reial_fountain_drank = true

	# Check barking at either busker
	if not bool(m.get("reial_busker_barked")) and m.dog.bark_anim > 0.0 and Outdoors.busking(Game.weather, Game.hour):
		if m.dog.global_position.distance_to(BUSKER_POS) < 110.0 or m.dog.global_position.distance_to(BUSKER2_POS) < 110.0:
			m.set("reial_busker_barked", true)
			m.float_text(m.dog.global_position + Vector2(0, -28), I18n.t("w_ole"), Color(0.96, 0.88, 0.35))
			m.feed.say(I18n.t("w_a_duet_with_the_busker"), EventFeed.Tone.GOOD)

	_tick_sellers(m, delta)
	Detour.tick(m, delta)


# main.surface_at, through walk_mod: the ground here, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


# The street after dark (world/night_fronts.gd): warm bar and cafe openings
# along the back walls of both portico arcades, spilling out through the arches.
static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var y := float(m.GATE_Y) + 120.0
	var i := 0
	while y < float(m.START_Y) - 60.0:
		# West arcade back wall (skip El Colom gallery doorway around y = -2050)
		if absf(y - Detour.COLOM_DOOR_Y) > 90.0:
			var wkind := "bar" if i % 2 == 0 else "shop"
			out.append(NightFronts.front(Vector2(ARCADE_BACK_W, y), 1.0, wkind, i * 2 + 201))
		# East arcade back wall
		var ekind := "bar" if (i + 1) % 2 == 0 else "shop"
		out.append(NightFronts.front(Vector2(ARCADE_BACK_E, y), -1.0, ekind, i * 2 + 202))
		y += 260.0
		i += 1
	return out


# Warm pools drawn by world/light_layer.gd in its one batch: Gaudí's
# six-armed lampposts, the central fountain uplight, and arcade bar lanterns.
static func night_lights(_m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for gp: Vector2 in GAUDI_POSTS:
		out.append(Vector3(gp.x, gp.y, 250.0))
	out.append(Vector3(FOUNTAIN_POS.x, FOUNTAIN_POS.y, 195.0))
	for tr: Rect2 in TERRACES:
		var lx := 275.0 if tr.get_center().x < 640.0 else 1005.0
		out.append(Vector3(lx, tr.get_center().y, 200.0))
	if Outdoors.busking(Game.weather, Game.hour):
		out.append(Vector3(BUSKER_POS.x, BUSKER_POS.y, 190.0))
		out.append(Vector3(BUSKER2_POS.x, BUSKER2_POS.y, 190.0))
	return out
