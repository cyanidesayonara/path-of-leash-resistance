class_name Port
extends RefCounted

# WALK 18: EL PORT (Port Vell & Barceloneta Wharf)
# Along Moll dels Pescadors and Moll de la Fusta: weathered wooden boardwalk
# decking down the centre, quayside granite flagstones, cast-iron mooring
# bollards with taut ropes, fish market ice crates, wheeling harbour gulls,
# and moored fishing boats rocking gently in the Mediterranean harbor basin.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["cam_lean", "draw_bollard", "draw_edge_layer", "draw_freedom", "draw_live", "draw_overhead", "hush_banner", "idle_status", "on_bark", "surface", "tick", "urgent_status"]


const Letters := preload("res://world/sign_letters.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
# the masts sway and the palms nod
const OVERHEAD_FOLLOWS_CAMERA := true
const CityRoofs := preload("res://world/city_roofs.gd")
const BossLleons := preload("res://systems/boss_lleons.gd")

const SHADOW := Color(0.04, 0.05, 0.08, 0.22)

# --- colors ------------------------------------------------------------------
const WATER_DEEP := Color(0.09, 0.24, 0.40)
const WATER_SHALLOW := Color(0.14, 0.38, 0.52, 0.90)
const WATER_WAVE := Color(0.42, 0.72, 0.88, 0.35)
const COPING_STONE := Color(0.72, 0.70, 0.66)
const COPING_DARK := Color(0.55, 0.53, 0.50)
const HAZARD_YELLOW := Color(0.88, 0.74, 0.18)
const HAZARD_BLACK := Color(0.18, 0.18, 0.20)
const BOARDWALK_TIMBER := Color(0.56, 0.45, 0.35)
const BOARDWALK_PLANK := Color(0.48, 0.38, 0.28)
const BOARDWALK_NAIL := Color(0.30, 0.24, 0.18)
const FLAGSTONE_LIGHT := Color(0.66, 0.64, 0.60)
const FLAGSTONE_DARK := Color(0.56, 0.54, 0.50)
const BOLLARD_IRON := Color(0.16, 0.18, 0.20)
const BOLLARD_RUST := Color(0.42, 0.26, 0.18)
const WAREHOUSE_WALL := Color(0.80, 0.78, 0.73)
const WAREHOUSE_TRIM := Color(0.18, 0.32, 0.48)
const ROPE_MANILA := Color(0.76, 0.66, 0.48)
const BUOY_ORANGE := Color(0.92, 0.35, 0.15)
const BUOY_WHITE := Color(0.95, 0.95, 0.92)
const CRATE_PINE := Color(0.66, 0.50, 0.32)
const CRATE_BAND := Color(0.26, 0.26, 0.28)
const ICE_BED := Color(0.86, 0.92, 0.96)
const FISH_SILVER := Color(0.74, 0.80, 0.86)
const FISH_BLUE := Color(0.30, 0.42, 0.56)
const FISH_RED := Color(0.82, 0.24, 0.20)
const BOAT_WOOD := Color(0.52, 0.36, 0.24)
const BOAT_WHITE := Color(0.92, 0.92, 0.90)
const BOAT_RED := Color(0.76, 0.20, 0.18)
const BOAT_BLUE := Color(0.16, 0.32, 0.58)

# --- corridor layout ---------------------------------------------------------
const WHARF_EDGE_X := 930.0   # east coping edge: harbor basin extends east
const WEST_WALL_X := 350.0    # west building line: warehouses, auction shed
const BOARDWALK_L := 470.0    # central wooden boardwalk strip
const BOARDWALK_R := 810.0
const SHED_STEP := 240.0
const SHED_BACK := 20.0       # the sheds' back wall; the road behind it
const YARD := Color(0.54, 0.53, 0.51)
const SHED_ROOFS: Array[Color] = [Color(0.62, 0.40, 0.31), Color(0.50, 0.55, 0.58), Color(0.66, 0.46, 0.34), Color(0.44, 0.52, 0.52)]
const MARINA_X := 1182.0      # the yachts' pontoon, out in the basin

# cast-iron mooring bollards along the quayside coping (registered in m.poles)
const BOLLARDS: Array[Vector2] = [
	Vector2(905.0, -650.0),
	Vector2(905.0, -1150.0),
	Vector2(905.0, -1650.0),
	Vector2(905.0, -2150.0),
	Vector2(905.0, -2650.0),
	Vector2(905.0, -3150.0),
	Vector2(905.0, -3650.0),
	Vector2(905.0, -4150.0),
]

# palm trees on the west quayside promenade
const PALMS: Array[Vector2] = [
	Vector2(390.0, -950.0),
	Vector2(390.0, -1550.0),
	Vector2(390.0, -2850.0),
	Vector2(390.0, -3450.0),
	Vector2(390.0, -4050.0),
]

# solids: fish crate stacks, auction booth, tavern terrace, net reels
const CRATE_STACK_1 := Rect2(352.0, -1450.0, 72.0, 96.0)
const CRATE_STACK_2 := Rect2(352.0, -2700.0, 68.0, 84.0)
const AUCTION_SHED := Rect2(346.0, -2320.0, 78.0, 130.0)
const TAVERN_TERRACE := Rect2(350.0, -3320.0, 74.0, 150.0)
const NET_REEL := Rect2(352.0, -1880.0, 64.0, 72.0)

# moored boats along the quayside water edge (solid barriers in the basin)
const BOATS: Array[Rect2] = [
	Rect2(942.0, -1400.0, 110.0, 220.0),
	Rect2(942.0, -2450.0, 110.0, 230.0),
	Rect2(942.0, -3550.0, 110.0, 220.0),
]

# prize catch: rare Mediterranean red sea bass on the auction scale
const PRIZE := Vector2(386.0, -2256.0)
const PRIZE_TEXT := "snatch the prize catch from the auction stall"

# gulls perched along the pier. They take off as the live flocks do (the dog
# or the owner within GULL_SCARE_R, a bark within GULL_BARK_R) and count for
# the "gulls" goal. No randomness: the walk's random sequence is untouched.
const GULL_SCARE_R := 70.0
const GULL_BARK_R := 200.0
const GULL_FLY_SPEED := 300.0   # px/s, climbing away
const GULL_FLY_SECS := 1.8      # then out of sight
const GULL_SPOTS: Array[Vector2] = [
	Vector2(880.0, -800.0),
	Vector2(640.0, -1300.0),
	Vector2(890.0, -1900.0),
	Vector2(550.0, -2500.0),
	Vector2(880.0, -3100.0),
	Vector2(620.0, -3700.0),
	Vector2(880.0, -4250.0),
]


# per perched gull: the walk time it took off (-1 perched) and where it flew
static var gull_took_off: PackedFloat32Array = PackedFloat32Array()
static var gull_dir: PackedVector2Array = PackedVector2Array()


static func reset_gulls() -> void:
	gull_took_off.resize(GULL_SPOTS.size())
	gull_took_off.fill(-1.0)
	gull_dir.resize(GULL_SPOTS.size())
	gull_dir.fill(Vector2.UP)


static func tick(m: Node2D, delta: float) -> void:
	if m.lleons != null:
		m.lleons.tick_state(delta)
	if gull_took_off.size() != GULL_SPOTS.size():
		reset_gulls()
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	for i in range(GULL_SPOTS.size()):
		if gull_took_off[i] >= 0.0:
			continue
		var g: Vector2 = GULL_SPOTS[i]
		if g.distance_to(dp) < GULL_SCARE_R:
			startle_gull(m, i, dp)
		elif g.distance_to(hp) < GULL_SCARE_R:
			startle_gull(m, i, hp)


# a bark sends up every perched gull in earshot, as it does the flocks
static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lleons != null and m.lleons.on_bark_action(pos):
		return
	if gull_took_off.size() != GULL_SPOTS.size():
		reset_gulls()
	for i in range(GULL_SPOTS.size()):
		if gull_took_off[i] < 0.0 and GULL_SPOTS[i].distance_to(pos) < GULL_BARK_R:
			startle_gull(m, i, pos)


static func startle_gull(m: Node2D, i: int, from: Vector2) -> void:
	gull_took_off[i] = float(m.elapsed)
	var away: Vector2 = GULL_SPOTS[i] - from
	# out over the water, whichever side it was scared from
	gull_dir[i] = (away.normalized() + Vector2(0.6, -0.4)).normalized() if away.length() > 1.0 else Vector2(0.8, -0.6)
	m.port_gulls_startled += 1


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
		{"y": m.START_Y, "cx": 640.0, "half": 280.0},
		{"y": -600.0, "cx": 640.0, "half": 290.0},
		{"y": -1200.0, "cx": 640.0, "half": 290.0},
		{"y": -2200.0, "cx": 640.0, "half": 290.0},
		{"y": -3200.0, "cx": 640.0, "half": 290.0},
		{"y": -4200.0, "cx": 640.0, "half": 290.0},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": 290.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 290.0},
	]


static func solids(_m: Node2D) -> Array[Rect2]:
	var list: Array[Rect2] = [
		CRATE_STACK_1,
		CRATE_STACK_2,
		AUCTION_SHED,
		TAVERN_TERRACE,
		NET_REEL,
	]
	for b: Rect2 in BOATS:
		list.append(b)
	list.append(Rect2(BossLleons.PLINTH_L - BossLleons.PLINTH_HALF, BossLleons.PLINTH_HALF * 2.0))
	list.append(Rect2(BossLleons.PLINTH_R - BossLleons.PLINTH_HALF, BossLleons.PLINTH_HALF * 2.0))
	# the Golondrina at the pier end, and the harbor crane's legs on the coping
	list.append(BossLleons.GOLONDRINA)
	list.append(Rect2(BossLleons.CRANE_BASE - Vector2(BossLleons.CRANE_HALF, BossLleons.CRANE_HALF), Vector2(BossLleons.CRANE_HALF, BossLleons.CRANE_HALF) * 2.0))
	return list


static func wrap_rects() -> Array[Rect2]:
	return [
		CRATE_STACK_1,
		CRATE_STACK_2,
		AUCTION_SHED,
		TAVERN_TERRACE,
		NET_REEL,
		Rect2(BossLleons.PLINTH_L - BossLleons.PLINTH_HALF, BossLleons.PLINTH_HALF * 2.0),
		Rect2(BossLleons.PLINTH_R - BossLleons.PLINTH_HALF, BossLleons.PLINTH_HALF * 2.0),
	]


# --- build -------------------------------------------------------------------
static func build(m: Node2D) -> Array:
	reset_gulls()
	if not m.tutorial_mode:
		m.fisherman = Fisherman.new()
	m.lleons = BossLleons.new()
	m.lleons.setup(m)
	m.gate_text = "MOLL DE LA FUSTA"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(372.0, -1100.0), Vector2(372.0, -2050.0),
		Vector2(372.0, -3050.0), Vector2(372.0, -3850.0),
	], TYPE_VECTOR2, &"", null)

	# register cast-iron bollards and palms in m.poles so leash wraps round them
	for b: Vector2 in BOLLARDS:
		m.poles.append(b)
	for p: Vector2 in PALMS:
		m.poles.append(p)
	# the post the crane net's trip rope is made fast to: wind the leash on it
	m.poles.append(BossLleons.NET_POST)
	# the lions' arena bollards (the first is the wharf's own last one)
	for bp: Vector2 in BossLleons.ARENA_BOLLARDS:
		if not m.poles.has(bp):
			m.poles.append(bp)

	# sniffable landmarks (hydrants): lifebuoy stand, cleat, auction scale, net hoist, anchor monument
	var marks: Array[Vector2] = [
		Vector2(382.0, -850.0),
		Vector2(895.0, -1350.0),
		Vector2(382.0, -2220.0),
		Vector2(382.0, -3100.0),
		Vector2(640.0, -4380.0),
	]

	# snacks: dropped fish scraps / fresh sardines by fish crates
	var snacks: Array[Vector2] = [
		Vector2(456.0, -1410.0),
		Vector2(448.0, -2260.0),
		Vector2(456.0, -2660.0),
		Vector2(720.0, -3250.0),
	]

	# wet fish water patches by fish crates (leaves fishy paws!)
	m.patches.append({
		"y": -1420.0, "at": 0.0, "rx": 32.0, "ry": 22.0, "seed": 4.1,
		"kind": "fish", "pin": Vector2(452.0, -1420.0)
	})
	m.patches.append({
		"y": -2270.0, "at": 0.0, "rx": 32.0, "ry": 22.0, "seed": 4.2,
		"kind": "fish", "pin": Vector2(446.0, -2270.0)
	})
	m.patches.append({
		"y": -2670.0, "at": 0.0, "rx": 32.0, "ry": 22.0, "seed": 4.3,
		"kind": "fish", "pin": Vector2(452.0, -2670.0)
	})

	# kickables: dock buoys and fruit/fish crates
	var kick_pts: Array[Vector2] = [
		Vector2(460.0, -750.0),
		Vector2(780.0, -1050.0),
		Vector2(480.0, -1650.0),
		Vector2(800.0, -2000.0),
		Vector2(490.0, -2550.0),
		Vector2(780.0, -2950.0),
		Vector2(470.0, -3600.0),
		Vector2(800.0, -4100.0),
	]
	for kp: Vector2 in kick_pts:
		m.cone_spots.append(kp)

	return [marks, snacks]


# --- drawing -----------------------------------------------------------------
static func draw_edge_layer(m: Node2D, c: ShapeBatch, vt: float, vb: float) -> void:
	# the wharf stops at the gate: past it the pier head is draw_freedom's
	vt = maxf(vt, m.GATE_Y - 30.0)
	vb = minf(vb, m.START_Y + 560.0)
	if vb <= vt:
		return
	# 1. Harbor water east of the wharf, paling toward the quay wall
	c.rect(Rect2(WHARF_EDGE_X, vt, 1700.0 - WHARF_EDGE_X, vb - vt), WATER_DEEP)
	_shoal(c, WHARF_EDGE_X, 1.0, vt, vb)

	# Wave ripple accents in the basin
	var step_y := 40.0
	var start_y: float = floorf(vt / step_y) * step_y
	var curr_y: float = start_y
	while curr_y <= vb:
		var wave_w := 36.0 + 18.0 * sin(curr_y * 0.05 + 1.2)
		var wave_x: float = WHARF_EDGE_X + 24.0 + 12.0 * sin(curr_y * 0.03)
		c.line(Vector2(wave_x, curr_y), Vector2(wave_x + wave_w, curr_y), WATER_WAVE, 1.8)
		curr_y += step_y

	# 2. Quayside granite flagstones on the main pier apron (WEST_WALL_X to WHARF_EDGE_X)
	var pier_rect := Rect2(WEST_WALL_X, vt, WHARF_EDGE_X - WEST_WALL_X, vb - vt)
	c.rect(pier_rect, FLAGSTONE_LIGHT)

	# Flagstone joint grid
	var grid_y := floorf(vt / 60.0) * 60.0
	while grid_y <= vb:
		c.line(Vector2(WEST_WALL_X, grid_y), Vector2(WHARF_EDGE_X, grid_y), FLAGSTONE_DARK, 1.0)
		grid_y += 60.0

	# 3. Weathered timber boardwalk running down the centre (BOARDWALK_L to BOARDWALK_R)
	var bw_rect := Rect2(BOARDWALK_L, vt, BOARDWALK_R - BOARDWALK_L, vb - vt)
	c.rect(bw_rect, BOARDWALK_TIMBER)

	# Longitudinal plank borders
	c.line(Vector2(BOARDWALK_L, vt), Vector2(BOARDWALK_L, vb), BOARDWALK_PLANK, 2.0)
	c.line(Vector2(BOARDWALK_R, vt), Vector2(BOARDWALK_R, vb), BOARDWALK_PLANK, 2.0)

	# Transverse wooden planks and nail heads
	var plank_y := floorf(vt / 24.0) * 24.0
	while plank_y <= vb:
		c.line(Vector2(BOARDWALK_L, plank_y), Vector2(BOARDWALK_R, plank_y), BOARDWALK_PLANK, 1.2)
		c.circle(Vector2(BOARDWALK_L + 6.0, plank_y - 12.0), 1.2, BOARDWALK_NAIL)
		c.circle(Vector2(BOARDWALK_R - 6.0, plank_y - 12.0), 1.2, BOARDWALK_NAIL)
		plank_y += 24.0

	# 4. Quayside stone coping along the water edge with yellow/black hazard diagonal stripes
	var coping_rect := Rect2(WHARF_EDGE_X - 16.0, vt, 16.0, vb - vt)
	c.rect(coping_rect, COPING_STONE)
	c.line(Vector2(WHARF_EDGE_X - 16.0, vt), Vector2(WHARF_EDGE_X - 16.0, vb), COPING_DARK, 1.5)
	c.line(Vector2(WHARF_EDGE_X, vt), Vector2(WHARF_EDGE_X, vb), COPING_DARK, 2.0)

	# Hazard stripes on coping
	var haz_y := floorf(vt / 48.0) * 48.0
	while haz_y <= vb:
		c.rect(Rect2(WHARF_EDGE_X - 14.0, haz_y, 12.0, 24.0), HAZARD_YELLOW)
		c.rect(Rect2(WHARF_EDGE_X - 14.0, haz_y + 24.0, 12.0, 24.0), HAZARD_BLACK)
		haz_y += 48.0

	# 5. The fish market's sheds on the west, the service road behind them and
	# the city's roofs across it; out in the basin, the marina's pontoon
	var sy := floorf(vt / SHED_STEP) * SHED_STEP
	while sy < vb:
		_shed(c, sy, vt, vb)
		sy += SHED_STEP
	c.rect(Rect2(WEST_WALL_X - 1.5, vt, 3.0, vb - vt), WAREHOUSE_TRIM)
	_marina(c, vt, vb)

	# 6. Moored fishing boats in the harbor basin
	for b: Rect2 in BOATS:
		if b.position.y + b.size.y >= vt and b.position.y <= vb:
			_draw_boat(c, b)

	# 7. Solids & stalls on the wharf
	if CRATE_STACK_1.position.y + CRATE_STACK_1.size.y >= vt and CRATE_STACK_1.position.y <= vb:
		_draw_crate_stack(c, CRATE_STACK_1, "SARDINES")
	if CRATE_STACK_2.position.y + CRATE_STACK_2.size.y >= vt and CRATE_STACK_2.position.y <= vb:
		_draw_crate_stack(c, CRATE_STACK_2, "LLAGOSTES")
	if AUCTION_SHED.position.y + AUCTION_SHED.size.y >= vt and AUCTION_SHED.position.y <= vb:
		_draw_auction_shed(c, AUCTION_SHED)
	if TAVERN_TERRACE.position.y + TAVERN_TERRACE.size.y >= vt and TAVERN_TERRACE.position.y <= vb:
		_draw_tavern_terrace(c, TAVERN_TERRACE)
	if NET_REEL.position.y + NET_REEL.size.y >= vt and NET_REEL.position.y <= vb:
		_draw_net_reel(c, NET_REEL)


# The basin's shallows, from a quay wall at `x` out to `side`.
static func _shoal(c: ShapeBatch, x: float, side: float, y0: float, y1: float) -> void:
	var pts := PackedVector2Array()
	for y: float in [y0, y1]:
		for d: float in [0.0, 26.0, 90.0, 260.0]:
			pts.append(Vector2(x + side * d, y))
	c.band(pts, 4, WATER_SHALLOW, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.95, 0.6, 0.24, 0.0]))


static func _h(k: int) -> float:
	return CityRoofs._h(k)


# One shed: a long pitched roof running back from the quay, its ridge lit, its
# skylights and vents, and the loading bay under a canopy on the quay side.
static func _shed(c: ShapeBatch, y: float, vt: float, _vb: float) -> void:
	if y < vt and vt <= y + SHED_STEP and y < -4800.0:
		# the shed the gate cuts is open ground: the yard at the wharf's end
		_yard(c, Rect2(-520.0, vt, WEST_WALL_X + 520.0, y + SHED_STEP - vt))
		return
	var k := int(absf(y) / SHED_STEP)
	CityRoofs.kept_module(c, SHED_BACK - 74.0, -1.0, 430.0, y, y + SHED_STEP, 1800 + k)
	# the road behind, its curbs and its dashes
	c.rect(Rect2(SHED_BACK - 74.0, y, 74.0, SHED_STEP), Color(0.30, 0.30, 0.32))
	c.rect(Rect2(SHED_BACK - 80.0, y, 8.0, SHED_STEP), COPING_STONE)
	for d in range(5):
		c.rect(Rect2(SHED_BACK - 38.0, y + 10.0 + 48.0 * float(d), 3.0, 24.0), Color(0.86, 0.84, 0.76, 0.7))
	# the yard between two sheds, then the roof
	c.rect(Rect2(SHED_BACK, y, WEST_WALL_X - SHED_BACK, SHED_STEP), YARD)
	var r := Rect2(SHED_BACK + 6.0, y + 16.0, WEST_WALL_X - 40.0 - SHED_BACK, SHED_STEP - 24.0)
	var col: Color = SHED_ROOFS[k % SHED_ROOFS.size()]
	c.rect(Rect2(r.position + Shade.light * 12.0, r.size), SHADOW)
	var mid := r.get_center().y
	c.rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)), col.lightened(0.10))
	c.rect(Rect2(r.position.x, mid, r.size.x, r.size.y * 0.5), col.darkened(0.10))
	# the slope darkening to each gutter
	for e: Array in [[r.position.y, 34.0], [r.end.y, -34.0]]:
		c.band(PackedVector2Array([Vector2(r.position.x, e[0]), Vector2(r.end.x, e[0]),
			Vector2(r.position.x, e[0] + e[1]), Vector2(r.end.x, e[0] + e[1])]), 2, Color(0.05, 0.04, 0.06), PackedFloat32Array([0.26, 0.0]))
	var rib := r.position.x + 9.0
	while rib < r.end.x:
		c.line(Vector2(rib, r.position.y), Vector2(rib, r.end.y), col.darkened(0.16), 1.2)
		rib += 13.0
	c.rect(Rect2(r.position.x, mid - 3.0, r.size.x, 6.0), col.lightened(0.24))
	c.rect(Rect2(r.position.x, mid + 3.0, r.size.x, 2.0), col.darkened(0.3))
	for q in range(3):
		var sx := r.position.x + 34.0 + float(q) * 82.0
		for half: float in [-62.0, 34.0]:
			c.rect(Rect2(sx, mid + half, 40.0, 26.0), Color(0.30, 0.38, 0.44))
			c.rect(Rect2(sx + 2.0, mid + half + 2.0, 36.0, 22.0), Color(0.58, 0.70, 0.76))
			c.line(Vector2(sx + 20.0, mid + half + 2.0), Vector2(sx + 20.0, mid + half + 24.0), Color(0.36, 0.44, 0.50), 1.6)
		if _h(k * 7 + q) < 0.6:
			var vp := Vector2(sx + 60.0, mid)
			c.circle(vp + Shade.light * 6.0, 9.0, SHADOW)
			c.circle(vp, 9.0, Color(0.62, 0.64, 0.66))
			c.circle(vp, 5.0, Color(0.40, 0.42, 0.45))
	# gulls' work along the ridge
	for q in range(3):
		c.ellipse(Vector2(r.position.x + 260.0 * _h(k * 31 + q), mid + 2.0 + 20.0 * _h(k * 17 + q)), 4.0, 2.4, Color(0.96, 0.96, 0.94, 0.7))
	# the loading bay: a striped canopy over the door, what is waiting by it
	var bay := Rect2(WEST_WALL_X - 34.0, mid - 64.0, 28.0, 128.0)
	c.rect(Rect2(bay.position + Vector2(4.0, 8.0), bay.size), SHADOW)
	for st in range(8):
		c.rect(Rect2(bay.position.x, bay.position.y + 16.0 * float(st), bay.size.x, 16.0), WAREHOUSE_TRIM if st % 2 == 0 else BOAT_WHITE)
	c.band(PackedVector2Array([bay.position, Vector2(bay.end.x, bay.position.y), Vector2(bay.position.x, bay.end.y), bay.end]),
		2, Color(0.05, 0.05, 0.10), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.34, 0.0]))
	_draw_lifebuoy(c, Vector2(WEST_WALL_X - 15.0, mid + 86.0))
	for q in range(2):
		var cr := Rect2(WEST_WALL_X - 30.0, y + 18.0 + 22.0 * float(q), 20.0, 18.0)
		c.rect(Rect2(cr.position + Shade.light * 4.0, cr.size), SHADOW)
		c.rect(cr, CRATE_PINE)
		c.rect(cr.grow(-4.0), ICE_BED if (k + q) % 2 == 0 else CRATE_PINE.darkened(0.3))


# Open ground at the wharf's end: containers in rows, a lane between.
static func _yard(c: ShapeBatch, r: Rect2) -> void:
	c.rect(r, YARD)
	c.rect(Rect2(SHED_BACK - 74.0, r.position.y, 74.0, r.size.y), Color(0.30, 0.30, 0.32))
	var cols: Array[Color] = [Color(0.62, 0.28, 0.22), Color(0.24, 0.40, 0.54), Color(0.74, 0.62, 0.30), Color(0.34, 0.48, 0.40), Color(0.66, 0.66, 0.64)]
	var row := 0
	var y := r.position.y + 14.0
	while y + 38.0 < r.end.y - 6.0:
		var x := r.position.x + 8.0
		var i := 0
		while x + 104.0 < WEST_WALL_X - 20.0:
			var b := Rect2(x, y, 104.0, 38.0)
			if not (b.end.x > SHED_BACK - 80.0 and b.position.x < SHED_BACK + 6.0) and _h(row * 17 + i * 5) > 0.2:
				var col: Color = cols[int(_h(row * 23 + i * 7) * 5.0) % 5]
				c.rect(Rect2(b.position + Shade.light * 9.0, b.size), SHADOW)
				c.rect(b, col)
				for k in range(12):
					c.line(Vector2(b.position.x + 6.0 + 8.4 * float(k), b.position.y + 2.0), Vector2(b.position.x + 6.0 + 8.4 * float(k), b.end.y - 2.0), col.darkened(0.16), 1.6)
				c.rect(Rect2(b.position, Vector2(b.size.x, 3.0)), col.lightened(0.24))
				c.rect(Rect2(b.position.x, b.end.y - 3.0, b.size.x, 3.0), col.darkened(0.3))
			x += 112.0
			i += 1
		y += 46.0
		row += 1


# Moored yachts either side of a floating pontoon, far enough out that the
# fishing boats and the Golondrina lie clear of them.
static func _marina(c: ShapeBatch, vt: float, vb: float) -> void:
	c.rect(Rect2(MARINA_X - 7.0, vt, 26.0, vb - vt), Color(0.03, 0.10, 0.20, 0.45))
	c.rect(Rect2(MARINA_X - 10.0, vt, 20.0, vb - vt), BOARDWALK_TIMBER)
	var py := floorf(vt / 18.0) * 18.0 + 18.0
	while py < vb:
		c.line(Vector2(MARINA_X - 10.0, py), Vector2(MARINA_X + 10.0, py), BOARDWALK_PLANK, 1.2)
		py += 18.0
	var y := floorf(vt / 76.0) * 76.0
	while y < vb + 76.0:
		var k := int(absf(y) / 76.0)
		for side: float in [-1.0, 1.0]:
			var n := k * 2 + (1 if side > 0.0 else 0)
			if _h(n * 13) < 0.22 or y - 22.0 < vt:
				continue
			# a wooden finger out to every berth
			c.rect(Rect2(MARINA_X + (8.0 if side > 0.0 else -42.0), y + 30.0, 34.0, 5.0), BOARDWALK_PLANK)
			_yacht(c, Vector2(MARINA_X + side * 16.0, y), side, 66.0 + 24.0 * _h(n * 17), n)
		y += 76.0


# a yacht moored stern to: its hull, its deck, its cabin, boom and sail cover
static func _yacht(c: ShapeBatch, stern: Vector2, side: float, ln: float, n: int) -> void:
	var w := 13.0 + 4.0 * _h(n * 19)
	var hull := func(grow: float) -> PackedVector2Array:
		var o := PackedVector2Array()
		for q: Vector2 in [Vector2(0, -0.8), Vector2(0.35, -1.0), Vector2(0.72, -0.72), Vector2(1.0, 0), Vector2(0.72, 0.72), Vector2(0.35, 1.0), Vector2(0, 0.8)]:
			o.append(stern + Vector2(side * (q.x * (ln + grow) - grow * 0.4), q.y * (w + grow)))
		return o
	var wet: PackedVector2Array = hull.call(4.0)
	for i in range(wet.size()):
		wet[i] += Shade.light * 5.0
	c.polygon(wet, Color(0.03, 0.10, 0.20, 0.5))
	var trims: Array[Color] = [BOAT_BLUE, BOAT_RED, Color(0.16, 0.36, 0.34), Color(0.90, 0.89, 0.86)]
	c.polygon(hull.call(2.0), trims[n % 4])
	c.polygon(hull.call(-2.0), BOAT_WHITE)
	var cab := Rect2(stern.x + (ln * 0.30 if side > 0.0 else -ln * 0.66), stern.y - w * 0.45, ln * 0.36, w * 0.9)
	c.rect(Rect2(stern.x + (4.0 if side > 0.0 else -ln * 0.26), stern.y - w * 0.5, ln * 0.26 - 4.0, w), Color(0.68, 0.54, 0.38))
	c.rect(cab, Color(0.82, 0.83, 0.84))
	c.rect(cab.grow(-3.0), Color(0.26, 0.36, 0.46))
	var mast := stern + Vector2(side * ln * 0.64, 0.0)
	var covers: Array[Color] = [Color(0.20, 0.32, 0.56), Color(0.92, 0.90, 0.84), Color(0.62, 0.20, 0.20)]
	c.capsule(stern + Vector2(side * 8.0, 0.0), mast, 2.6, covers[n % 3])
	c.circle(mast, 3.0, Color(0.72, 0.74, 0.76))
	c.line(mast, mast + Shade.light * 26.0, Color(0.03, 0.08, 0.16, 0.4), 2.0)


# A date palm on the west quay: the stone ring it grows from, its trunk.
static func _draw_palm(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	wc.circle(p, 21.0, COPING_DARK)
	wc.circle(p, 18.5, COPING_STONE)
	wc.circle(p, 15.0, Color(0.34, 0.27, 0.20))
	m.cast_shadow(wc, p, 11.0, 34.0, 0.2)
	m._palm_trunk(wc, p)


static func _draw_lifebuoy(c: ShapeBatch, p: Vector2) -> void:
	c.circle(p + Shade.light * 3.0, 11.0, SHADOW)
	c.circle(p, 10.0, BUOY_ORANGE)
	c.circle(p, 5.0, YARD)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2(cos(angle), sin(angle))
		c.line(p + dir * 5.0, p + dir * 10.0, BUOY_WHITE, 2.5)


static func _draw_boat(c: ShapeBatch, r: Rect2) -> void:
	c.rect(Rect2(r.position.x - 6.0, r.position.y - 6.0, r.size.x + 12.0, r.size.y + 12.0), Color(0.04, 0.12, 0.22, 0.4))
	c.rect(r, BOAT_WHITE)
	c.rect(Rect2(r.position.x + 8.0, r.position.y + 12.0, r.size.x - 16.0, r.size.y - 24.0), BOAT_WOOD)
	c.line(Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.position.y + r.size.y), BOAT_BLUE, 4.0)
	c.line(Vector2(r.position.x + r.size.x, r.position.y), Vector2(r.position.x + r.size.x, r.position.y + r.size.y), BOAT_RED, 4.0)
	var cabin := Rect2(r.position.x + 20.0, r.position.y + r.size.y * 0.35, r.size.x - 40.0, r.size.y * 0.30)
	c.rect(cabin, BOAT_WHITE)
	c.rect(Rect2(cabin.position.x + 4.0, cabin.position.y + 4.0, cabin.size.x - 8.0, 10.0), Color(0.18, 0.40, 0.60))
	c.line(Vector2(r.position.x, r.position.y + 20.0), Vector2(WHARF_EDGE_X - 10.0, r.position.y + 20.0), ROPE_MANILA, 2.0)
	c.line(Vector2(r.position.x, r.position.y + r.size.y - 20.0), Vector2(WHARF_EDGE_X - 10.0, r.position.y + r.size.y - 20.0), ROPE_MANILA, 2.0)


static func _draw_crate_stack(c: ShapeBatch, r: Rect2, label: String) -> void:
	c.rect(Rect2(r.position + Shade.light * 8.0, r.size), SHADOW)
	c.rect(r, CRATE_PINE)
	c.rect(Rect2(r.position.x + 8.0, r.position.y, 4.0, r.size.y), CRATE_BAND)
	c.rect(Rect2(r.position.x + r.size.x - 12.0, r.position.y, 4.0, r.size.y), CRATE_BAND)
	var ice := Rect2(r.position.x + 14.0, r.position.y + 10.0, r.size.x - 28.0, r.size.y - 20.0)
	c.rect(ice, ICE_BED)
	for k in 4:
		var fy: float = ice.position.y + 8.0 + float(k) * 16.0
		var fx: float = ice.position.x + 12.0
		var col := FISH_RED if k == 1 else FISH_SILVER
		c.line(Vector2(fx, fy), Vector2(fx + 22.0, fy), col, 4.0)
		c.circle(Vector2(fx + 22.0, fy), 2.5, FISH_BLUE)
	letters(c, label, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y - 8.0), 5.5, Color(0.20, 0.16, 0.12, 0.85), 1.2, r.size.x - 12.0)


static func _draw_auction_shed(c: ShapeBatch, r: Rect2) -> void:
	c.rect(Rect2(r.position + Shade.light * 10.0, r.size), SHADOW)
	c.rect(r, WAREHOUSE_WALL)
	c.rect(Rect2(r.position.x, r.position.y, r.size.x, 14.0), WAREHOUSE_TRIM)
	letters(c, "LLOTJA", Vector2(r.position.x + r.size.x * 0.5, r.position.y + 10.0), 7.5, Color.WHITE, 1.6, r.size.x - 16.0)
	var counter := Rect2(r.position.x + 10.0, r.position.y + 30.0, r.size.x - 20.0, r.size.y - 40.0)
	c.rect(counter, Color(0.70, 0.72, 0.75))
	var tray := Rect2(counter.position.x + 6.0, counter.position.y + 10.0, counter.size.x - 12.0, 32.0)
	c.rect(tray, ICE_BED)
	c.line(Vector2(tray.position.x + 6.0, tray.position.y + 16.0), Vector2(tray.position.x + 36.0, tray.position.y + 16.0), Color(0.96, 0.78, 0.22), 5.5)
	c.circle(Vector2(tray.position.x + 36.0, tray.position.y + 16.0), 3.5, Color(0.98, 0.88, 0.40))


static func _draw_tavern_terrace(c: ShapeBatch, r: Rect2) -> void:
	c.rect(Rect2(r.position + Shade.light * 8.0, r.size), SHADOW)
	c.rect(r, BOARDWALK_TIMBER)
	c.rect(Rect2(r.position.x, r.position.y, r.size.x, 4.0), BOARDWALK_PLANK)
	c.rect(Rect2(r.position.x, r.position.y + r.size.y - 4.0, r.size.x, 4.0), BOARDWALK_PLANK)
	for i in 3:
		var tp := Vector2(r.position.x + r.size.x * 0.5, r.position.y + 24.0 + float(i) * 44.0)
		c.circle(tp + Shade.light * 4.0, 14.0, SHADOW)
		c.circle(tp, 13.0, BOAT_BLUE)
		c.circle(tp, 10.0, BOAT_WHITE)
		c.circle(tp, 3.0, Color(0.85, 0.25, 0.20))


static func _draw_net_reel(c: ShapeBatch, r: Rect2) -> void:
	c.rect(Rect2(r.position + Shade.light * 6.0, r.size), SHADOW)
	c.rect(r, Color(0.32, 0.35, 0.38))
	var spool := Rect2(r.position.x + 6.0, r.position.y + 8.0, r.size.x - 12.0, r.size.y - 16.0)
	c.rect(spool, Color(0.24, 0.42, 0.32))
	for n in 5:
		var ny: float = spool.position.y + 6.0 + float(n) * 9.0
		c.line(Vector2(spool.position.x, ny), Vector2(spool.position.x + spool.size.x, ny), Color(0.18, 0.34, 0.24), 2.0)
		c.circle(Vector2(spool.position.x + 8.0 + float(n) * 8.0, ny), 2.0, BUOY_ORANGE)


static func draw_bollard(_m: Node2D, wc: ShapeBatch, h: Dictionary) -> void:
	var p: Vector2 = h.pos
	var is_cleat: bool = String(h.get("kind", "")) == "cleat"
	var done: bool = bool(h.get("done", false))

	wc.circle(p + Shade.light * 6.0, 11.0, SHADOW)

	if is_cleat:
		wc.rect(Rect2(p.x - 14.0, p.y - 4.0, 28.0, 8.0), BOLLARD_IRON)
		wc.circle(Vector2(p.x - 14.0, p.y), 4.0, BOLLARD_IRON)
		wc.circle(Vector2(p.x + 14.0, p.y), 4.0, BOLLARD_IRON)
		if done:
			wc.circle(p, 4.0, Color(0.85, 0.75, 0.30))
	else:
		wc.circle(p, 9.5, BOLLARD_IRON)
		wc.circle(p + Vector2(-1.5, -2.0), 7.0, BOLLARD_RUST if not done else Color(0.48, 0.40, 0.28))
		wc.circle(p + Vector2(-2.5, -3.5), 3.0, Color(0.60, 0.58, 0.54, 0.6))
		wc.line(Vector2(p.x - 13.0, p.y), Vector2(p.x + 13.0, p.y), BOLLARD_IRON, 3.5)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	var c := ShapeBatch.new()
	var t: float = float(m.elapsed) if m != null else 0.0
	for b: Rect2 in BOATS:
		if m != null and absf(b.get_center().y - m.cam.position.y) > 700.0:
			continue
		var mast_base := Vector2(b.position.x + b.size.x * 0.5, b.position.y + b.size.y * 0.5)
		var sway := sin(t * 1.5 + b.position.y * 0.01) * 6.0
		var mast_top := mast_base + Vector2(sway - 18.0, -120.0)
		c.line(mast_base, mast_top, Color(0.88, 0.88, 0.85, 0.9), 3.2)
		c.line(mast_top, Vector2(b.position.x + 4.0, b.position.y + 10.0), Color(0.70, 0.72, 0.75, 0.45), 1.0)
		c.line(mast_top, Vector2(b.position.x + b.size.x - 4.0, b.position.y + 10.0), Color(0.70, 0.72, 0.75, 0.45), 1.0)
		c.line(mast_top, Vector2(b.position.x + b.size.x * 0.5, b.position.y + b.size.y - 10.0), Color(0.70, 0.72, 0.75, 0.45), 1.0)
		var flag_tip := mast_top + Vector2(16.0 + sin(t * 3.0) * 3.0, -2.0)
		c.line(mast_top, flag_tip, BOAT_RED, 2.5)
	for p: Vector2 in PALMS:
		if m != null and absf(p.y - m.cam.position.y) < 560.0:
			m._palm_crown(c, p)
	c.flush(ci)


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	# the wharf stops at the gate: past it, the plaça is the freedom layer's
	vt = maxf(vt, m.GATE_Y - 30.0)
	var t: float = float(m.elapsed) if m != null else 0.0

	for i in 6:
		var sx := WHARF_EDGE_X + 36.0 + float(i) * 20.0
		var sy := vt + fposmod(float(i) * 180.0 + t * 45.0, vb - vt)
		var spark_w := 14.0 + 8.0 * sin(t * 2.0 + float(i))
		wc.line(Vector2(sx, sy), Vector2(sx + spark_w, sy), Color(0.65, 0.88, 1.0, 0.4), 1.4)

	if gull_took_off.size() != GULL_SPOTS.size():
		reset_gulls()
	var anim: float = AnimClock.msec() / 1000.0
	for i in range(GULL_SPOTS.size()):
		var spot: Vector2 = GULL_SPOTS[i]
		if spot.y < vt - 200.0 or spot.y > vb + 200.0:
			continue
		if gull_took_off[i] < 0.0:
			_draw_gull(wc, spot, t)
			continue
		var up: float = t - gull_took_off[i]
		if up < GULL_FLY_SECS:
			_draw_gull_flying(wc, spot, gull_dir[i], up, anim + float(i))
	# the mooring bollards on the coping: wrapped by the leash, so drawn
	for bp: Vector2 in BOLLARDS:
		if bp.y > vt - 40.0 and bp.y < vb + 40.0:
			_draw_mooring_bollard(wc, bp)
	for bp: Vector2 in BossLleons.ARENA_BOLLARDS:
		if not bp in BOLLARDS and bp.y > vt - 40.0 and bp.y < vb + 40.0:
			_draw_mooring_bollard(wc, bp)
	for pp: Vector2 in PALMS:
		if pp.y > vt - 60.0 and pp.y < vb + 60.0:
			_draw_palm(m, wc, pp)
	if m.fisherman != null:
		m.fisherman.draw(wc, vt, vb)
	if m.lleons != null:
		m.lleons.draw(wc, vt, vb)


# A cast-iron mooring bollard seen from above: the squat post, its wide cap
# with the rust of a century of salt, a mooring line made fast round it.
static func _draw_mooring_bollard(wc: ShapeBatch, p: Vector2) -> void:
	wc.circle(p + Shade.light * 7.0, 12.0, SHADOW)
	wc.circle(p, 11.5, BOLLARD_IRON)
	wc.circle(p + Vector2(-1.0, -1.5), 9.0, Color(0.24, 0.26, 0.28))
	wc.circle(p + Vector2(-1.5, -2.0), 6.0, BOLLARD_RUST)
	wc.circle(p + Vector2(-3.0, -4.0), 2.6, Color(0.60, 0.58, 0.54, 0.6))
	wc.line(p + Vector2(8.0, 3.0), p + Vector2(30.0, 7.0), ROPE_MANILA.darkened(0.3), 3.2)
	wc.line(p + Vector2(8.0, 3.0), p + Vector2(30.0, 7.0), ROPE_MANILA, 1.8)


static func _draw_gull(wc: ShapeBatch, p: Vector2, t: float) -> void:
	var bob := sin(t * 3.0 + p.x) * 1.5
	var gp := p + Vector2(0.0, bob)
	wc.circle(p + Shade.light * 4.0, 4.0, SHADOW)
	wc.circle(gp, 4.5, Color(0.95, 0.95, 0.95))
	wc.line(gp + Vector2(-3.0, 1.0), gp + Vector2(3.0, 1.0), Color(0.60, 0.65, 0.70), 2.5)
	wc.line(gp + Vector2(3.0, -1.0), gp + Vector2(7.0, -0.5), Color(0.96, 0.75, 0.15), 1.8)


# wings spread from above and beating as in entities/pigeon.gd; the shadow
# stays on the quay and falls behind as it climbs
static func _draw_gull_flying(wc: ShapeBatch, spot: Vector2, dir: Vector2, up: float, anim: float) -> void:
	var gp := spot + dir * GULL_FLY_SPEED * up
	var lift := minf(1.0, up / GULL_FLY_SECS)
	wc.circle(spot + dir * GULL_FLY_SPEED * up * 0.6 + Shade.light * (4.0 + 26.0 * lift), 4.0 * (1.0 - 0.5 * lift), SHADOW)
	var side := dir.orthogonal()
	var flap := sin(anim * 24.0)
	var s := 1.55
	for sd: float in [-1.0, 1.0]:
		var root := gp + side * sd * 2.0 * s
		var wtip := gp + side * sd * (9.0 + flap * 3.0) * s - dir * (2.0 + flap) * s
		wc.polygon(PackedVector2Array([root + dir * 2.5 * s, wtip, root - dir * 3.0 * s]), Color(0.72, 0.75, 0.80))
		wc.polygon(PackedVector2Array([wtip, wtip.lerp(root + dir * 2.5 * s, 0.3), wtip.lerp(root - dir * 3.0 * s, 0.3)]), Color(0.12, 0.12, 0.14))
	wc.circle(gp, 4.5, Color(0.95, 0.95, 0.95))
	wc.circle(gp + dir * 6.0, 3.0, Color(0.98, 0.98, 0.97))
	wc.line(gp + dir * 8.5, gp + dir * 12.0, Color(0.96, 0.75, 0.15), 1.8)


# Plaça del Far: the pier's head, the harbor all round it, and the green
# light on its mole beyond the rail.
static func draw_freedom(m: Node2D, ci: Object) -> void:
	var c := ShapeBatch.new()
	c.lod = true
	var gy: float = m.GATE_Y - 30.0
	var r: Rect2 = m._freedom_rect()
	var pier := Rect2(r.position.x - 34.0, r.position.y - 30.0, r.size.x + 68.0, gy - r.position.y + 30.0)
	c.rect(Rect2(-520.0, pier.position.y - 1300.0, 2300.0, gy - pier.position.y + 1300.0), WATER_DEEP)
	# the shallows all round it, mitred at the corners
	var ring := PackedVector2Array()
	for d: float in [0.0, 40.0, 110.0, 260.0]:
		ring.append_array([Vector2(pier.position.x - d, gy), pier.position - Vector2(d, d),
			Vector2(pier.end.x + d, pier.position.y - d), Vector2(pier.end.x + d, gy)])
	c.band(ring, 4, WATER_SHALLOW, PackedFloat32Array([0.95, 0.55, 0.22, 0.0]))
	for i in range(130):
		var p := Vector2(-500.0 + 2260.0 * _h(i * 3 + 1), pier.position.y - 900.0 + (gy - pier.position.y + 900.0) * _h(i * 5 + 2))
		if not pier.grow(44.0).has_point(p):
			c.line(p, p + Vector2(22.0 + 22.0 * _h(i), 0.0), WATER_WAVE, 1.8)
	# the quay wall, its coping
	c.rect(Rect2(pier.position + Vector2(8.0, 0.0), pier.size), Color(0.02, 0.08, 0.16, 0.4))
	c.rect(pier, COPING_DARK)
	c.rect(pier.grow_individual(-4.0, -4.0, -4.0, 0.0), COPING_STONE)
	var inner := pier.grow_individual(-18.0, -18.0, -18.0, 0.0)
	c.rect(inner, FLAGSTONE_LIGHT)
	var y := inner.position.y
	var row := 0
	while y < inner.end.y:
		c.line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), FLAGSTONE_DARK, 1.0)
		var x := inner.position.x + (45.0 if row % 2 == 0 else 90.0)
		while x < inner.end.x:
			c.line(Vector2(x, y), Vector2(x, minf(y + 60.0, inner.end.y)), FLAGSTONE_DARK, 1.0)
			if _h(row * 37 + int(x)) < 0.16:
				c.rect(Rect2(x, y, 90.0, 60.0).intersection(inner), Color(FLAGSTONE_DARK, 0.4))
			x += 90.0
		y += 60.0
		row += 1
	# the boardwalk running on round the square
	for d: Rect2 in [Rect2(inner.position.x, inner.position.y, inner.size.x, 46.0),
			Rect2(inner.position.x, inner.position.y + 46.0, 46.0, inner.size.y - 46.0),
			Rect2(inner.end.x - 46.0, inner.position.y + 46.0, 46.0, inner.size.y - 46.0)]:
		c.rect(d, BOARDWALK_TIMBER)
		var along := d.size.x > d.size.y
		var t := 12.0
		while t < (d.size.x if along else d.size.y):
			if along:
				c.line(d.position + Vector2(t, 0), d.position + Vector2(t, d.size.y), BOARDWALK_PLANK, 1.2)
			else:
				c.line(d.position + Vector2(0, t), d.position + Vector2(d.size.x, t), BOARDWALK_PLANK, 1.2)
			t += 24.0
	# its south face, either side of the wharf it joins
	for f: Rect2 in [Rect2(pier.position.x, gy - 14.0, WEST_WALL_X - pier.position.x, 14.0), Rect2(WHARF_EDGE_X, gy - 14.0, pier.end.x - WHARF_EDGE_X, 14.0)]:
		c.rect(f, COPING_STONE)
		c.rect(Rect2(f.position.x, gy - 4.0, f.size.x, 4.0), COPING_DARK)
	# a compass rose set in the paving
	var o := r.get_center() + Vector2(0.0, 40.0)
	c.circle(o, 92.0, FLAGSTONE_DARK)
	c.circle(o, 87.0, FLAGSTONE_LIGHT.lightened(0.08))
	for i in range(8):
		var v := Vector2.from_angle(TAU * float(i) / 8.0)
		var l := 82.0 if i % 2 == 0 else 52.0
		c.polygon(PackedVector2Array([o, o + v.rotated(0.39) * 22.0, o + v * l]), Color(0.36, 0.44, 0.50))
		c.polygon(PackedVector2Array([o, o + v * l, o + v.rotated(-0.39) * 22.0]), Color(0.80, 0.78, 0.72))
	# the rail, and the light on its mole outside it
	var nw := pier.position + Vector2(9.0, 9.0)
	var ne := Vector2(pier.end.x - 9.0, pier.position.y + 9.0)
	for p: Array in [[nw, ne], [nw, Vector2(nw.x, gy)], [ne, Vector2(ne.x, gy)]]:
		var a: Vector2 = p[0]
		var z: Vector2 = p[1]
		c.line(a + Shade.light * 4.0, z + Shade.light * 4.0, SHADOW, 3.0)
		c.line(a, z, WAREHOUSE_TRIM, 3.0)
		var n := int(a.distance_to(z) / 52.0)
		for i in range(n + 1):
			c.circle(a.lerp(z, float(i) / float(n)), 3.6, WAREHOUSE_TRIM.darkened(0.3))
	var lh := Vector2(900.0, pier.position.y - 64.0)
	c.rect(Rect2(lh.x - 34.0, lh.y, 68.0, 66.0), COPING_DARK)
	c.rect(Rect2(lh.x - 30.0, lh.y, 60.0, 66.0), COPING_STONE)
	c.circle(lh + Shade.light * 8.0, 58.0, Color(0.02, 0.08, 0.16, 0.4))
	c.circle(lh, 56.0, COPING_DARK)
	c.circle(lh, 51.0, COPING_STONE)
	c.circle(lh + Shade.light * 16.0, 30.0, SHADOW)
	c.circle(lh, 29.0, Color(0.10, 0.36, 0.24))
	c.circle(lh, 26.0, Color(0.18, 0.54, 0.34))
	c.circle(lh, 18.0, Color(0.94, 0.94, 0.90))
	c.circle(lh, 12.0, Color(0.16, 0.30, 0.26))
	c.circle(lh, 7.0, Color(0.70, 0.98, 0.78))
	c.glow(lh, 90.0, Color(0.50, 1.0, 0.68, 0.22))
	c.flush(ci)
	m._draw_freedom_benches(ci, r, Color(0.36, 0.30, 0.24))
	m._freedom_sign(ci, r, m.gate_text, I18n.t("w_the_lighthouse_square_off_leash"))


# main.surface_at, through walk_mod: the ground here, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	if p.x > WHARF_EDGE_X and p.y > m.GATE_Y - 30.0:
		return Surfaces.S.WATER
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


static func idle_status(m: Node2D) -> String:
	return m.lleons.status() if m.lleons != null else ""


static func urgent_status(m: Node2D) -> String:
	return m.lleons.status() if m.lleons != null else ""


static func hush_banner(m: Node2D) -> bool:
	return m.lleons != null and m.lleons.hush_banner()


static func cam_lean(m: Node2D) -> float:
	return m.lleons.lean if m.lleons != null else 0.0
