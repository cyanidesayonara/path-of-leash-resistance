class_name Tibidabo
extends RefCounted

# WALK 21: EL TIBIDABO (the mountain funicular and the overlook)
# A winding mountain road up Tibidabo: a stone balustrade on the west over the
# drop to the city, and on the east, off the road among the pines, the
# funicular track. The carriage runs up and down it on the walk clock
# (carriage_y), drawn every frame by world/funicular_layer.gd; the funicular
# goal reads the same position, so it fires on the carriage the player sees.
# Three coin viewfinders stand on plinths along the balustrade, and a trackside
# signal at the road's edge flashes while the carriage is near it. The summit
# has pennant bunting and a cotton candy cart with the prize.

# its off-leash area's worn patch is soft at the edge (main.soft_wear)
const SOFT_WEAR := true
# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["build_layer", "draw_edge_layer", "draw_grove", "draw_live", "draw_overhead", "night_lights", "surface", "tick"]


const Letters := preload("res://world/sign_letters.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const Woods := preload("res://world/woods.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Arrival := preload("res://systems/arrival.gd")

const SHADOW := Color(0.04, 0.05, 0.08, 0.22)
# wall lamps on the mirador's house fronts, past the gate, down each side as
# fractions of its depth; under main.NIGHT_LAMP_R, so the light layer draws
# each its bracket
const MIRADOR_LAMPS: Array[float] = [0.25, 0.6]
const MIRADOR_FRONT := 30.0
const MIRADOR_LAMP_R := 140.0

# --- colors ------------------------------------------------------------------
const ROAD_ASPHALT := Color(0.38, 0.37, 0.36)
const ROAD_KERB := Color(0.72, 0.70, 0.66)
const BALUSTRADE_STONE := Color(0.82, 0.80, 0.76)
const BALUSTRADE_SHADOW := Color(0.18, 0.16, 0.15, 0.55)
const TRACK_BALLAST := Color(0.52, 0.48, 0.44)
const TRACK_SLEEPER := Color(0.32, 0.24, 0.18)
const TRACK_RAIL := Color(0.78, 0.80, 0.82)
const TRACK_CABLE := Color(0.28, 0.30, 0.32)
const FUNICULAR_RED := Color(0.82, 0.18, 0.16)
const FUNICULAR_CREAM := Color(0.94, 0.92, 0.84)
const FUNICULAR_GLASS := Color(0.55, 0.78, 0.88, 0.75)
const VIEWFINDER_METAL := Color(0.26, 0.30, 0.34)
const VIEWFINDER_BRASS := Color(0.86, 0.72, 0.24)
const COTTON_CANDY_PINK := Color(0.96, 0.62, 0.78)
const CHURRO_GOLD := Color(0.88, 0.68, 0.28)
const BUNTING_COLORS: Array[Color] = [
	Color(0.88, 0.22, 0.20),
	Color(0.22, 0.55, 0.88),
	Color(0.95, 0.82, 0.24),
	Color(0.32, 0.75, 0.36),
	Color(0.92, 0.48, 0.20)
]

const HILLSIDE := Color(0.33, 0.37, 0.22)
const ROCK := Color(0.50, 0.44, 0.36)
# far below, in the haze
const CITY_STREET := Color(0.66, 0.67, 0.67)
const CITY_ROOFS: Array[Color] = [Color(0.64, 0.51, 0.46), Color(0.67, 0.57, 0.50), Color(0.60, 0.53, 0.52), Color(0.70, 0.62, 0.55)]
const CITY_HAZE := Color(0.60, 0.68, 0.76)
const CITY_PITCH := 34.0      # one block and its street
const CITY_TILE := 8          # blocks to a kept row
const SLOPE_STEP := 48.0
const SLOPE_FOOT := 196.0     # how far out from the balustrade the wood stops

# --- track layout ----------------------------------------------------------------
# The track runs off the road on the east, past its widest edge (x 920), so
# the carriage never passes over anyone. Nothing crosses it.
const TRACK_X := 968.0
const TRACK_W := 60.0
# the trackside signal at the road's edge, a mark spot; it flashes while the
# carriage is within SIGNAL_NEAR of it
const SIGNAL_POS := Vector2(840.0, -2450.0)
const SIGNAL_NEAR := 420.0
# the carriage climbs from the bottom station, beside the walk's door, to the
# top and back, a full round trip every CAR_PERIOD seconds of walk time
const CAR_BOTTOM_Y := 340.0
const CAR_TOP_Y := -4700.0
const CAR_PERIOD := 40.0
const CAR_W := 38.0
const CAR_L := 110.0
# the carriage's nose at the head of its climb, where the top buffer stops it
const TOP_STATION_Y := CAR_TOP_Y - CAR_L * 0.5
# the mirador's terrace coping and the depth its shadow feathers down over
const COPING_H := 12.0
const COPING_FALL := 28.0
# the funicular goal: the dog at the road's east side with the carriage
# passing level with her
const WATCH_X := 680.0
const WATCH_DY := 120.0
# and on its way: not parked at the bottom station, by the start line
const WATCH_OFF_STATION := 300.0
# Aleppo pines on the hillside beyond the track; they catch the rope
const PINES: Array[Vector2] = [
	Vector2(1040.0, -600.0), Vector2(1040.0, -1200.0), Vector2(1040.0, -1800.0),
	Vector2(1040.0, -2600.0), Vector2(1040.0, -3200.0), Vector2(1040.0, -3800.0),
	Vector2(1040.0, -4400.0),
]
const PINE_R := 26.0
# a viewfinder counts once she stands still at it
const VIEW_R := 36.0
const VIEW_STILL := 20.0

# Panoramic coin-operated viewfinders along the balustrade
const VIEWFINDERS: Array[Vector2] = [
	Vector2(415.0, -1400.0),
	Vector2(405.0, -2800.0),
	Vector2(375.0, -4200.0),
]

# Summit fairground prize
const PRIZE := Vector2(490.0, -4600.0)
const PRIZE_TEXT := "swipe the cotton candy off the fairground cart"

# Winding corridor geometry: ascending the mountain
static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 250.0},
		{"y": -700.0, "cx": 610.0, "half": 240.0},
		{"y": -1400.0, "cx": 650.0, "half": 240.0},
		{"y": -2100.0, "cx": 610.0, "half": 240.0},
		{"y": -2800.0, "cx": 640.0, "half": 240.0},
		{"y": -3500.0, "cx": 670.0, "half": 250.0},
		{"y": -4200.0, "cx": 630.0, "half": 260.0},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": 270.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 280.0},
	]


static func build(m: Node2D) -> Array:
	m.gate_text = "MIRADOR DEL TIBIDABO"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([
		Vector2(520.0, -1800.0),
		Vector2(700.0, -3400.0),
	], TYPE_VECTOR2, &"", null)
	if not m.tutorial_mode:
		m.unicyclist = Unicyclist.new()
	m.fountains = Array([
		Vector2(450.0, -2100.0),
		Vector2(800.0, -4350.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(420.0, -1100.0),
		Vector2(830.0, -2250.0),
		Vector2(420.0, -3250.0),
		Vector2(820.0, -4450.0),
	], TYPE_VECTOR2, &"", null)

	# Round rope poles. Their radii come from world/level_build.gd, which
	# gives every round post the same radius once the level's poles are in.
	for pp: Vector2 in PINES:
		m.poles.append(pp)
	for vf: Vector2 in VIEWFINDERS:
		m.poles.append(vf)

	# Mark spots: the viewfinders, the trackside signal, the cotton candy cart
	var marks: Array[Vector2] = [
		VIEWFINDERS[0],
		VIEWFINDERS[1],
		VIEWFINDERS[2],
		SIGNAL_POS,
		PRIZE,
	]

	# Snacks: dropped churro and cotton candy bites
	var snacks: Array[Vector2] = [
		Vector2(470.0, -1350.0),
		Vector2(550.0, -2350.0),
		Vector2(430.0, -3150.0),
		Vector2(580.0, -4250.0),
	]

	return [marks, snacks]


# The carriage's y on the track at walk time t: up from the bottom station
# and back down, eased in and out at each end.
static func carriage_y(t: float) -> float:
	var f := fmod(t, CAR_PERIOD) / CAR_PERIOD
	var up := 1.0 - absf(2.0 * f - 1.0)
	return lerpf(CAR_BOTTOM_Y, CAR_TOP_Y, smoothstep(0.0, 1.0, up))


static func signal_lit(m: Node2D) -> bool:
	return absf(carriage_y(m.elapsed) - SIGNAL_POS.y) < SIGNAL_NEAR


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float = 0.0, vb: float = 0.0) -> void:
	if m.lvl != "tibidabo":
		return
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, m.START_Y + 400.0)
	if bot <= top:
		return
	_city(b, top, bot)
	_hill(b, top, bot)

	# the road surface, its dashed center line and curbs, following the bends
	b.rect(Rect2(360.0, top, 560.0, bot - top), ROAD_ASPHALT)
	var ly := floorf(bot / 64.0) * 64.0
	while ly > top - 64.0:
		var e_dash: Vector2 = m.walk_edges(ly)
		var c_dash := (e_dash.x + e_dash.y) * 0.5
		b.line(Vector2(c_dash, ly), Vector2(c_dash, ly - 32.0), Color(0.92, 0.78, 0.25), 3.0)
		ly -= 64.0
	var ky := floorf(bot / 38.0) * 38.0
	while ky > top - 38.0:
		var ke: Vector2 = m.walk_edges(ky)
		b.line(Vector2(ke.x, ky), Vector2(ke.x, ky - 40.0), ROAD_KERB, 5.0)
		b.line(Vector2(ke.y, ky), Vector2(ke.y, ky - 40.0), ROAD_KERB, 5.0)
		# no road past its curbs
		var kn: Vector2 = m.walk_edges(ky - 40.0)
		b.quad(Vector2(ke.y + 2.5, ky), Vector2(kn.y + 2.5, ky - 40.0), Vector2(922.0, ky - 40.0), Vector2(922.0, ky), HILLSIDE)
		ky -= 38.0
	_slope(m, b, top, bot)

	# the funicular track: ballast, sleepers, rails and the haulage cable
	var t_top: float = maxf(top, CAR_TOP_Y - 80.0)
	var t_bot: float = minf(bot, CAR_BOTTOM_Y + 80.0)
	if t_bot > t_top:
		b.rect(Rect2(TRACK_X - TRACK_W * 0.5, t_top, TRACK_W, t_bot - t_top), TRACK_BALLAST)
		var sy := floorf(t_bot / 22.0) * 22.0
		while sy > t_top:
			b.rect(Rect2(TRACK_X - 26.0, sy - 3.0, 52.0, 6.0), TRACK_SLEEPER)
			sy -= 22.0
		b.line(Vector2(TRACK_X - 18.0, t_bot), Vector2(TRACK_X - 18.0, t_top), TRACK_RAIL, 4.0)
		b.line(Vector2(TRACK_X + 18.0, t_bot), Vector2(TRACK_X + 18.0, t_top), TRACK_RAIL, 4.0)
		b.line(Vector2(TRACK_X, t_bot), Vector2(TRACK_X, t_top), TRACK_CABLE, 2.0)
		# Cable guide rollers / pulleys along center
		var py := floorf(t_bot / 120.0) * 120.0
		while py > t_top:
			b.circle(Vector2(TRACK_X, py), 3.5, Color(0.20, 0.20, 0.22))
			b.circle(Vector2(TRACK_X, py), 1.5, Color(0.70, 0.72, 0.75))
			py -= 120.0
	if TOP_STATION_Y >= top and TOP_STATION_Y < bot:
		_top_station(m, b)

	# Aleppo pines on the hillside
	for pp: Vector2 in PINES:
		if pp.y < top - PINE_R * 2.0 or pp.y > bot + PINE_R * 2.0:
			continue
		Woods.crown(b, Woods.K.ALEPPO, pp, PINE_R * 1.5, int(absf(pp.y)))
	# Stone cliffside balustrade on the west edge overlooking Barcelona
	var by := floorf(bot / 70.0) * 70.0 - 40.0
	while by > top - 70.0:
		var we: Vector2 = m.walk_edges(by)
		var bx: float = we.x - 8.0
		b.rect(Rect2(bx - 8.0, by, 16.0, 60.0), BALUSTRADE_STONE)
		b.circle(Vector2(bx, by + 30.0), 10.0, BALUSTRADE_STONE)
		b.circle(Vector2(bx + Shade.light.x * 3.0, by + 30.0 + Shade.light.y * 3.0), 10.0, BALUSTRADE_SHADOW)
		by -= 70.0
	var edge_y: float = m.GATE_Y - 40.0
	if edge_y >= top and edge_y < bot:
		_terrace_edge(m, b, edge_y)

	# Panoramic viewfinders (coin binoculars)
	for vf: Vector2 in VIEWFINDERS:
		if vf.y < top - 20.0 or vf.y > bot + 20.0:
			continue
		b.circle(vf + Shade.light * 4.0, 14.0, SHADOW)
		b.circle(vf, 12.0, BALUSTRADE_STONE)
		b.circle(vf, 6.0, VIEWFINDER_METAL)
		b.line(vf + Vector2(-6.0, -4.0), vf + Vector2(-6.0, 6.0), VIEWFINDER_METAL, 4.0)
		b.line(vf + Vector2(6.0, -4.0), vf + Vector2(6.0, 6.0), VIEWFINDER_METAL, 4.0)
		b.circle(vf + Vector2(-6.0, -4.0), 3.0, VIEWFINDER_BRASS)
		b.circle(vf + Vector2(6.0, -4.0), 3.0, VIEWFINDER_BRASS)

	# the cotton candy cart with the prize
	if PRIZE.y > top - 30.0 and PRIZE.y < bot + 30.0:
		b.rect(Rect2(PRIZE.x - 22.0 + Shade.light.x * 4.0, PRIZE.y - 14.0 + Shade.light.y * 4.0, 44.0, 28.0), SHADOW)
		b.rect(Rect2(PRIZE.x - 20.0, PRIZE.y - 12.0, 40.0, 24.0), FUNICULAR_CREAM)
		b.rect(Rect2(PRIZE.x - 22.0, PRIZE.y - 14.0, 44.0, 6.0), Color(0.88, 0.22, 0.20))
		b.circle(PRIZE + Vector2(-6.0, -2.0), 8.0, COTTON_CANDY_PINK)
		b.circle(PRIZE + Vector2(6.0, -2.0), 8.0, COTTON_CANDY_PINK.lightened(0.12))

# The city far below on the west: the Eixample's chamfered blocks round their
# yards, a park, a tower, all in the haze and paling with distance.
static func _city(b: ShapeBatch, top: float, bot: float) -> void:
	b.rect(Rect2(-460.0, top, 860.0, bot - top), CITY_STREET)
	var size := CITY_PITCH * float(CITY_TILE)
	var y := (floorf(top / CITY_PITCH) + 1.0) * CITY_PITCH
	while y < bot:
		for tx in range(3):
			var k := posmod(int(y / CITY_PITCH) * 5 + tx * 7, 23)
			var rec: ShapeBatch = _city_kept.get(k)
			if rec == null:
				rec = ShapeBatch.new()
				rec.lod = true
				_city_row(rec, k)
				_city_kept[k] = rec
			b._points.append_array(Transform2D(0.0, Vector2(-460.0 + size * float(tx), y)) * rec._points)
			b._colors.append_array(rec._colors)
		y += CITY_PITCH
	# the avenues that cut across the grid
	var ay := floorf(bot / 1150.0) * 1150.0
	while ay > top - 700.0:
		var a := Vector2(-460.0, ay + 640.0)
		var z := Vector2(400.0, ay + 60.0)
		if ay + 60.0 > top + 16.0:
			b.line(a, z, CITY_STREET.darkened(0.06), 17.0)
			b.line(a, z, Color(0.46, 0.55, 0.44), 3.0)
		ay -= 1150.0
	var veil := PackedVector2Array()
	for vy: float in [top, bot]:
		for x: float in [-460.0, -60.0, 180.0, 380.0]:
			veil.append(Vector2(x, vy))
	b.band(veil, 4, CITY_HAZE, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.62, 0.36, 0.2, 0.14]))


static var _city_kept := {}


static func _city_row(b: ShapeBatch, t: int) -> void:
	for i in range(CITY_TILE):
		var k := t * 977 + i * 31
		var o := Vector2(float(i) * CITY_PITCH, 0.0) + Vector2(3.0, 3.0)
		var s := CITY_PITCH - 7.0
		var ch := 5.0
		var park := Woods._h(k) < 0.06
		var col: Color = Color(0.42, 0.52, 0.40) if park else CITY_ROOFS[int(Woods._h(k + 1) * 4.0) % 4]
		var pts := PackedVector2Array()
		for q: Vector2 in [Vector2(ch, 0), Vector2(s - ch, 0), Vector2(s, ch), Vector2(s, s - ch), Vector2(s - ch, s), Vector2(ch, s), Vector2(0, s - ch), Vector2(0, ch)]:
			pts.append(o + q)
		var sh := pts.duplicate()
		for q in range(sh.size()):
			sh[q] += Shade.light * 2.4
		b.polygon(sh, Color(0.30, 0.34, 0.42, 0.45))
		b.polygon(pts, col)
		if park:
			for q in range(5):
				b.circle(o + Vector2(4.0 + (s - 8.0) * Woods._h(k + q * 3), 4.0 + (s - 8.0) * Woods._h(k + q * 5 + 1)), 3.6, Color(0.32, 0.44, 0.34))
			continue
		# the houses' party walls, and the yard they stand round
		for q in range(4):
			var x := o.x + s * (0.2 + 0.2 * float(q))
			b.line(Vector2(x, o.y), Vector2(x, o.y + 8.0), col.darkened(0.16), 1.0)
			b.line(Vector2(x, o.y + s - 8.0), Vector2(x, o.y + s), col.darkened(0.16), 1.0)
		b.rect(Rect2(o + Vector2(9.0, 9.0), Vector2(s - 18.0, s - 18.0)), Color(0.44, 0.46, 0.46) if Woods._h(k + 2) < 0.5 else Color(0.44, 0.51, 0.42))
		if Woods._h(k + 3) < 0.05:
			var c := o + Vector2(s, s) * 0.5
			b.line(c, c + Shade.light * 18.0, Color(0.30, 0.34, 0.42, 0.5), 8.0)
			b.circle(c, 6.0, Color(0.74, 0.78, 0.82))
			b.circle(c, 3.0, Color(0.56, 0.64, 0.72))


# The drop under the balustrade: rock, then a wood falling away below, its
# crowns smaller and hazier the further down they are.
static func _slope(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var y := floorf(bot / SLOPE_STEP) * SLOPE_STEP
	while y > top - SLOPE_STEP:
		var e0: float = (m.walk_edges(y) as Vector2).x - 4.0
		var e1: float = (m.walk_edges(y + SLOPE_STEP) as Vector2).x - 4.0
		var foot := PackedVector2Array()
		for p: Vector2 in [Vector2(e0, maxf(y, top)), Vector2(e1, y + SLOPE_STEP)]:
			for d: float in [0.0, -120.0, -SLOPE_FOOT + 40.0, -SLOPE_FOOT - 20.0]:
				foot.append(Vector2(p.x + d, p.y))
		b.band(foot, 4, Color(0.25, 0.31, 0.20), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 1.0, 0.75, 0.0]))
		y -= SLOPE_STEP
	y = floorf(bot / SLOPE_STEP) * SLOPE_STEP
	while y >= top:
		var e: float = (m.walk_edges(y + 24.0) as Vector2).x - 14.0
		var row := int(absf(y) / SLOPE_STEP)
		for j in range(8):
			var k := row * 41 + j * 13
			var f := 1.0 - float(j) / 7.0      # 1 far down, 0 under the wall
			var p := Vector2(e - lerpf(34.0, SLOPE_FOOT, f) + 14.0 * Woods._h(k), y + SLOPE_STEP * Woods._h(k + 1))
			var kinds: Array = [Woods.K.HOLM, Woods.K.PINE, Woods.K.ALEPPO]
			Woods.crown(b, int(kinds[int(Woods._h(k + 2) * 3.0) % 3]), p, lerpf(27.0, 12.0, f) * (0.85 + 0.3 * Woods._h(k + 3)), k)
		y -= SLOPE_STEP
	# the haze over the far ones, then the rock the wall is built on
	y = floorf(bot / SLOPE_STEP) * SLOPE_STEP
	while y > top - SLOPE_STEP:
		var e0: float = (m.walk_edges(y) as Vector2).x
		var e1: float = (m.walk_edges(y + SLOPE_STEP) as Vector2).x
		var y0 := maxf(y, top)
		var y1 := y + SLOPE_STEP
		b.band(PackedVector2Array([
			Vector2(e0 - SLOPE_FOOT - 40.0, y0), Vector2(e0 - 130.0, y0), Vector2(e0 - 50.0, y0),
			Vector2(e1 - SLOPE_FOOT - 40.0, y1), Vector2(e1 - 130.0, y1), Vector2(e1 - 50.0, y1)]), 3, CITY_HAZE,
			PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.24, 0.0]))
		var row := int(absf(y) / SLOPE_STEP)
		var jag := 16.0 * Woods._h(row * 7)
		b.polygon(PackedVector2Array([Vector2(e0 - 4.0, y0), Vector2(e0 - 30.0 - jag, y0 + 6.0), Vector2(e0 - 40.0 + jag, y0 + (y1 - y0) * 0.55), Vector2(e1 - 28.0, y1), Vector2(e1 - 4.0, y1)]), ROCK.darkened(0.12))
		b.polygon(PackedVector2Array([Vector2(e0 - 4.0, y0), Vector2(e0 - 22.0, y0 + 4.0), Vector2(e0 - 24.0 + jag * 0.5, y0 + (y1 - y0) * 0.5), Vector2(e1 - 18.0, y1), Vector2(e1 - 4.0, y1)]), ROCK.lightened(0.1))
		b.line(Vector2(e0 - 20.0, y0 + 10.0), Vector2(e0 - 32.0, y0 + (y1 - y0) * 0.7), ROCK.darkened(0.4), 1.6)
		if row % 3 == 0:
			b.circle(Vector2(e0 - 30.0, y0 + 20.0), 8.0, Color(0.30, 0.38, 0.20))
			b.circle(Vector2(e0 - 32.0, y0 + 18.0), 5.0, Color(0.44, 0.52, 0.28))
		y -= SLOPE_STEP


# The hillside on the east: grass and stones either side of the track, and the
# mountain's wood above it.
static func _hill(b: ShapeBatch, top: float, bot: float) -> void:
	b.rect(Rect2(900.0, top, 800.0, bot - top), HILLSIDE)
	var tile := 240.0
	var floor_c: Color = (Woods.LOOKS["collserola"] as Dictionary).floor
	var ty := floorf(top / tile) * tile
	while ty < bot:
		var k := int(absf(ty) / tile)
		for i in range(14):
			var p := Vector2(920.0 + 190.0 * Woods._h(k * 61 + i * 3), ty + tile * Woods._h(k * 47 + i * 5))
			if p.y < top + 10.0 or p.y > bot:
				continue
			match i % 4:
				0:
					b.glow(p, minf(46.0, p.y - top), Color(0.48, 0.46, 0.28, 0.5))
				1:
					b.circle(p + Vector2(2, 3), 5.0, Color(0, 0, 0, 0.2))
					b.circle(p, 5.0, Color(0.56, 0.52, 0.45))
					b.circle(p - Vector2(1.4, 1.6), 2.6, Color(0.72, 0.68, 0.60))
				_:
					for f in range(3):
						b.line(p, p + Vector2.from_angle(-PI * 0.5 + (float(f) - 1.0) * 0.5) * 9.0, Color(0.48, 0.56, 0.28), 1.8)
		var y0 := maxf(ty, top)
		var y1 := minf(ty + tile, bot)
		b.band(PackedVector2Array([Vector2(1066.0, y0), Vector2(1130.0, y0), Vector2(1700.0, y0), Vector2(1066.0, y1), Vector2(1130.0, y1), Vector2(1700.0, y1)]),
			3, floor_c, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 1.0]))
		ty += tile
	var y := floorf(top / 56.0) * 56.0 + 56.0
	while y < bot:
		var row := int(absf(y) / 56.0)
		Woods.kept_row(b, "collserola", 1088.0 + 22.0 * Woods._h(row * 3), 1.0, y, 56.0, 470.0, row)
		y += 56.0


# The mirador's terrace edge, where the drop to the city and the hillside
# meet its paving: a coping course out from the balustrade and the kerb, the
# balustrade's posts turning the corner along it on the west, and the
# terrace's shadow feathering down off it.
static func _terrace_edge(m: Node2D, b: ShapeBatch, y: float) -> void:
	var e: Vector2 = m.walk_edges(y)
	var runs: Array[Vector2] = [Vector2(-400.0, e.x - 22.0), Vector2(e.y + 3.0, 1600.0)]
	for run: Vector2 in runs:
		var fall := PackedVector2Array([
			Vector2(run.x, y + COPING_H), Vector2(run.y, y + COPING_H),
			Vector2(run.x, y + COPING_H + COPING_FALL), Vector2(run.y, y + COPING_H + COPING_FALL),
		])
		b.band(fall, 2, SHADOW, PackedFloat32Array([1.0, 0.0]))
		b.rect(Rect2(run.x, y, run.y - run.x, COPING_H), BALUSTRADE_STONE)
		b.rect(Rect2(run.x, y + COPING_H - 3.0, run.y - run.x, 3.0), BALUSTRADE_STONE.darkened(0.2))
	var px := e.x - 22.0 - 28.0
	while px > -400.0:
		b.circle(Vector2(px, y + COPING_H * 0.5), 7.0, BALUSTRADE_STONE.lightened(0.06))
		px -= 56.0


# The top station, level with the carriage at the head of its climb: a
# platform from the road's kerb out to the rails, and a buffer stop past the
# carriage's nose, as at the bottom.
static func _top_station(m: Node2D, b: ShapeBatch) -> void:
	var kerb: float = (m.walk_edges(CAR_TOP_Y) as Vector2).y + 3.0
	var plat := Rect2(kerb, CAR_TOP_Y - 40.0, TRACK_X - TRACK_W * 0.5 - kerb, 80.0)
	b.rect(Rect2(plat.position + Shade.light * 5.0, plat.size), SHADOW)
	b.rect(plat, BALUSTRADE_STONE)
	b.rect(Rect2(plat.position.x, plat.end.y - 5.0, plat.size.x, 5.0), BALUSTRADE_STONE.darkened(0.25))
	b.rect(Rect2(plat.end.x - 6.0, plat.position.y, 4.0, plat.size.y), Color(0.92, 0.78, 0.25))
	var stop_y := TOP_STATION_Y - 14.0
	b.rect(Rect2(TRACK_X - 24.0, stop_y - 4.0, 48.0, 4.0), SHADOW)
	b.rect(Rect2(TRACK_X - 24.0, stop_y, 48.0, 8.0), FUNICULAR_RED)


# Where the carriage is drawn: on the walk clock, except that once the pair
# are walking in to the bottom station (systems/arrival.gd) it comes down to
# meet them, docked by the time Millie is through, and stays docked.
static func shown_carriage_y(m: Node2D) -> float:
	var running := carriage_y(m.elapsed)
	if m.finished:
		return CAR_BOTTOM_Y
	if m.arriving:
		var u := clampf(float(m.arrival_t) / (Arrival.PULL + Arrival.DOG_IN), 0.0, 1.0)
		return lerpf(running, CAR_BOTTOM_Y, smoothstep(0.0, 1.0, u))
	return running


# The bottom station, drawn by systems/arrival.gd at the walk's door (c, on
# the road's east edge): a platform out to the track under a canopy, with a
# buffer stop at the foot of the rails.
static func draw_station(b: ShapeBatch, c: Vector2) -> void:
	var plat := Rect2(c.x - 30.0, c.y - 22.0, TRACK_X - TRACK_W * 0.5 - (c.x - 30.0), 44.0)
	b.rect(Rect2(plat.position + Shade.light * 5.0, plat.size), SHADOW)
	b.rect(plat, BALUSTRADE_STONE)
	b.rect(Rect2(plat.position.x, plat.end.y - 5.0, plat.size.x, 5.0), BALUSTRADE_STONE.darkened(0.25))
	# the yellow edge line along the track side
	b.rect(Rect2(plat.end.x - 6.0, plat.position.y, 4.0, plat.size.y), Color(0.92, 0.78, 0.25))
	# canopy posts and roof edge
	for px: float in [plat.position.x + 8.0, plat.end.x - 14.0]:
		b.circle(Vector2(px, plat.position.y + 4.0), 4.0, VIEWFINDER_METAL)
	b.rect(Rect2(plat.position.x - 4.0, plat.position.y - 12.0, plat.size.x + 8.0, 8.0), FUNICULAR_RED.darkened(0.2))
	# buffer stop at the foot of the rails
	b.rect(Rect2(TRACK_X - 24.0, CAR_BOTTOM_Y + CAR_L * 0.5 + 6.0, 48.0, 8.0), FUNICULAR_RED)
	b.rect(Rect2(TRACK_X - 24.0, CAR_BOTTOM_Y + CAR_L * 0.5 + 14.0, 48.0, 4.0), SHADOW)


# The moving parts, every frame (world/funicular_layer.gd): the carriage and
# the trackside signal.
static func draw_moving(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var car_y := shown_carriage_y(m)
	if car_y > vt - CAR_L and car_y < vb + CAR_L:
		var body := Rect2(TRACK_X - CAR_W * 0.5, car_y - CAR_L * 0.5, CAR_W, CAR_L)
		b.rect(Rect2(body.position + Shade.light * 6.0, body.size), SHADOW)
		b.rect(body, FUNICULAR_RED)
		b.rect(body.grow_individual(-4.0, -8.0, -4.0, -8.0), FUNICULAR_CREAM)
		for wi in range(5):
			var wy := body.position.y + 14.0 + float(wi) * 18.0
			b.rect(Rect2(body.position.x + 6.0, wy, CAR_W - 12.0, 12.0), FUNICULAR_GLASS)
	if SIGNAL_POS.y > vt - 40.0 and SIGNAL_POS.y < vb + 40.0:
		var lit := signal_lit(m)
		var alt := fmod(AnimClock.msec() / 1000.0 * 3.0, 2.0) < 1.0
		var _ml := Engine.get_main_loop()
		var _gm: Node = _ml.root.get_node_or_null("Game") if _ml != null and _ml is SceneTree else null
		var flashes_on := true if _gm == null else bool(_gm.flashes)
		var off := Color(0.35, 0.1, 0.1)
		var on := Color(0.95, 0.2, 0.2)
		b.circle(SIGNAL_POS + Shade.light * 3.0, 8.0, SHADOW)
		b.circle(SIGNAL_POS, 7.0, Color(0.18, 0.18, 0.20))
		b.circle(SIGNAL_POS + Vector2(-4, 0), 3.0, on if lit and (not flashes_on or alt) else off)
		b.circle(SIGNAL_POS + Vector2(4, 0), 3.0, on if lit and (not flashes_on or not alt) else off)


static func build_layer(m: Node2D) -> void:
	var layer := Node2D.new()
	layer.set_script(load("res://world/funicular_layer.gd"))
	m.add_child(layer)
	layer.setup(m)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "tibidabo":
		return
	# Pennant bunting strung across the road near the summit, one batch.
	# The overhead layer is cached, so the pennants hang still.
	var b := ShapeBatch.new(ci)
	for y: float in [-4100.0, -4350.0, -4600.0]:
		var p1 := Vector2(410.0, y)
		var p2 := Vector2(850.0, y)
		b.line(p1, p2, Color(0.30, 0.28, 0.26), 1.5)
		for i in range(12):
			var frac := float(i) / 11.0
			var bx := lerpf(p1.x, p2.x, frac)
			var by := y + sin(frac * PI) * 14.0
			var col: Color = BUNTING_COLORS[i % BUNTING_COLORS.size()]
			b.polygon(PackedVector2Array([Vector2(bx - 6.0, by), Vector2(bx + 6.0, by), Vector2(bx, by + 12.0)]), col)
	b.flush()


# The unicyclist moves, so he is drawn on the world pass, not the cached edge.
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.unicyclist != null:
		m.unicyclist.draw(m, wc, vt, vb)


static func tick(m: Node2D, _delta: float) -> void:
	if m.lvl != "tibidabo":
		return
	var dp: Vector2 = m.dog.global_position
	# a viewfinder: standing still at one
	if not m.tibidabo_viewfinder_gazed:
		for vf: Vector2 in VIEWFINDERS:
			if dp.distance_to(vf) < VIEW_R and m.dog.velocity.length() < VIEW_STILL:
				m.tibidabo_viewfinder_gazed = true
				m.bones += 5
				m.combo.add("PANORAMA", 4)
				m.float_text(dp + Vector2(0, -30), I18n.t("w_panorama_5"), Color(0.96, 0.86, 0.32))
				m.feed.say(I18n.t("w_barcelona_all_of_it"), EventFeed.Tone.GOOD)
				m.get_node("/root/Sfx").play("prize", 1.1)
				break
	# the funicular: at the road's east side as the carriage passes level
	if not m.tibidabo_funicular_seen:
		var cy := carriage_y(m.elapsed)
		if dp.x > WATCH_X and absf(cy - dp.y) < WATCH_DY and cy < CAR_BOTTOM_Y - WATCH_OFF_STATION:
			m.tibidabo_funicular_seen = true
			m.bones += 3
			m.float_text(dp + Vector2(0, -28), I18n.t("w_funicular_3"), Color(0.85, 0.35, 0.32))
			m.feed.say(I18n.t("w_the_funicular_goes_by"), EventFeed.Tone.GOOD)

# main.surface_at, through walk_mod: the ground here, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	# the mirador is paved: soft only in its tree pits and planters
	var s := Surfaces.paved_past_gate(m, p, m.trees)
	return Surfaces.S.PAVEMENT if s < 0 else s


# the mirador's trees are broadleaves standing in their pits
static func draw_grove(m: Node2D, c: Object, p: Vector2, _i: int) -> void:
	m.broadleaf_grove(c, p)


# the street's lamps, and wall lamps on the mirador's house fronts
static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	out.append_array(m.freedom_side_lamps(MIRADOR_LAMPS, MIRADOR_FRONT, MIRADOR_LAMP_R))
	return out
