class_name Montserrat
extends RefCounted

# WALK 38: MONTSERRAT (the mountain path up to the monastery)
# A ledge path up the serrated mountain: the drop to the Llobregat valley on
# the west, the pinkish-grey conglomerate wall and its domes on the east,
# agulles (rock needles) and pines standing in the path to wind the leash on,
# stone steps all the way up.
#
# At y = -2600 the Sant Joan funicular crosses on the level: the bell and the
# lamps give 0.8 s, the carriage crosses, waits at its far station and comes
# back.
#
# Higher up, the mel i mató stall (y = -3300), then the stair onto Plaça de
# Santa Maria, the atrium's arcade and the Font del Portal.
#
# On the way home the goat herd (entities/goat_threat.gd) comes down after
# them, kicking boulders loose.

const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const HALF := 260.0
const SHADOW := Color(0.06, 0.05, 0.08, 0.28)

# Montserrat's conglomerate: pinkish grey, rounded pebbles of every stone the
# old river carried set in it. entities/goat_threat.gd and the film use these.
const ROCK := Color(0.74, 0.66, 0.63)
const ROCK_LIT := Color(0.87, 0.80, 0.75)
const ROCK_SHADE := Color(0.56, 0.48, 0.47)
const ROCK_DEEP := Color(0.38, 0.32, 0.34)
const PEBBLES: Array[Color] = [
	Color(0.92, 0.89, 0.84), Color(0.62, 0.60, 0.61), Color(0.72, 0.50, 0.42),
	Color(0.46, 0.42, 0.43), Color(0.84, 0.74, 0.60),
]
const WALL_FACE := Color(0.80, 0.71, 0.67)
# the path
const TRAIL := Color(0.69, 0.66, 0.62)
const TRAIL_LIT := Color(0.79, 0.76, 0.71)
const TRAIL_DARK := Color(0.58, 0.55, 0.52)
const STEP_TOP := Color(0.84, 0.81, 0.76)
const STEP_FACE := Color(0.46, 0.42, 0.41)
const STEP_EVERY := 160.0
const KERB := Color(0.78, 0.74, 0.69)
# the valley below
const VALLEY := Color(0.50, 0.61, 0.56)
const VALLEY_WOOD := Color(0.36, 0.49, 0.42)
const HAZE := Color(0.80, 0.86, 0.92)
# what grows on the rock
const OAK := Color(0.19, 0.31, 0.20)
const OAK_LIT := Color(0.33, 0.45, 0.25)
const SCRUB := Color(0.40, 0.47, 0.31)
const BLOSSOM := Color(0.66, 0.62, 0.86)
const BROOM := Color(0.93, 0.78, 0.24)
const PINE_NEEDLE := Color(0.22, 0.37, 0.22)
const PINE_LIT := Color(0.42, 0.54, 0.28)
const PINE_TRUNK := Color(0.44, 0.29, 0.19)
# the monastery
const MONASTERY_WALL := Color(0.84, 0.78, 0.68)
const MONASTERY_ROOF := Color(0.76, 0.40, 0.27)
const PLACA := Color(0.82, 0.79, 0.74)
const PLACA_JOINT := Color(0.60, 0.57, 0.54, 0.75)
const CHEESE_CREAM := Color(0.96, 0.94, 0.86)
const HONEY_GOLD := Color(0.92, 0.68, 0.18)
# the funicular
const FUNICULAR_RED := Color(0.82, 0.18, 0.16)
const FUNICULAR_CREAM := Color(0.95, 0.92, 0.83)
const FUNICULAR_GLASS := Color(0.55, 0.78, 0.88)
const RAIL_STEEL := Color(0.80, 0.82, 0.86)
const RAIL_WOOD := Color(0.36, 0.26, 0.20)
const RAIL_IRON := Color(0.20, 0.21, 0.24)
const BALLAST := Color(0.52, 0.48, 0.47)
const DECK := Color(0.50, 0.37, 0.25)
const PLATFORM := Color(0.76, 0.74, 0.71)
const SHELTER_ROOF := Color(0.30, 0.44, 0.40)

# Conglomerate rock spires (round rope wrap poles)
const SPIRES: Array[Vector2] = [
	Vector2(450.0, -500.0),
	Vector2(830.0, -950.0),
	Vector2(440.0, -1400.0),
	Vector2(840.0, -1850.0),
	Vector2(430.0, -2300.0),
	Vector2(850.0, -2800.0),
	Vector2(455.0, -3170.0),   # clear of the mel i mató stall
	Vector2(830.0, -3700.0),
	Vector2(440.0, -4150.0),
	Vector2(826.0, -4490.0),   # clear of the arcade
]
const SPIRE_R := 28.0
# how far north of its foot a needle's top is drawn, and how long its shadow
const SPIRE_LEAN := 34.0
const SPIRE_SHADOW := 96.0

# Pines
const PINES: Array[Vector2] = [
	Vector2(390.0, -300.0),
	Vector2(890.0, -750.0),
	Vector2(380.0, -1200.0),
	Vector2(900.0, -1650.0),
	Vector2(370.0, -2100.0),
	Vector2(910.0, -3050.0),
	Vector2(380.0, -3500.0),
	Vector2(890.0, -3950.0),
	Vector2(370.0, -4400.0),
]
const PINE_R := 24.0
const PINE_CROWN := 44.0

# The Funicular Crossing
const CROSSING_Y := -2600.0
const CROSSING_TRACK_W := 56.0
const FUNICULAR_SPEED := 120.0
const FUNICULAR_CAR_W := 80.0
const FUNICULAR_CAR_H := 36.0
# the four signal masts, one at each corner of the crossing
const SIGNALS: Array[Vector2] = [
	Vector2(396.0, -2546.0), Vector2(884.0, -2546.0),
	Vector2(396.0, -2654.0), Vector2(884.0, -2654.0),
]
const BARRIER_LEN := 78.0

# Mel i Mató Stall
const CHEESE_STALL_POS := Vector2(465.0, -3300.0)
const CHEESE_STALL_RECT := Rect2(430.0, -3325.0, 70.0, 50.0)

# Summit Prize: The Jar of Mountain Honey with Fresh Mató Cheese
const PRIZE := Vector2(640.0, -4680.0)
const PRIZE_TEXT := "snatch the artisanal honey and mato cheese jar"

# Plaça de Santa Maria starts at the head of the last stair; the atrium's
# inlaid ring lies beyond the arcade
const TERRACE_Y := -4300.0
const ATRIUM := Vector2(640.0, -4830.0)

# Monastery Arcade Walls
const ARCADE_LEFT := Rect2(380.0, -4620.0, 90.0, 44.0)
const ARCADE_RIGHT := Rect2(810.0, -4620.0, 90.0, 44.0)

# the old trail gate's two stone piers
const GATE_PIERS: Array[Rect2] = [
	Rect2(390.0, -1920.0, 40.0, 40.0),
	Rect2(850.0, -1920.0, 40.0, 40.0),
]

# Respite / Solid Obstacles
static func solids(_m: Node2D) -> Array[Rect2]:
	return [
		CHEESE_STALL_RECT,
		GATE_PIERS[0],
		GATE_PIERS[1],
		ARCADE_LEFT,
		ARCADE_RIGHT,
	]


static func wrap_rects() -> Array[Rect2]:
	return [
		CHEESE_STALL_RECT,
		GATE_PIERS[0],
		GATE_PIERS[1],
		ARCADE_LEFT,
		ARCADE_RIGHT,
	]


static func build(m: Node2D) -> Array:
	m.gate_text = "MONESTIR DE MONTSERRAT"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([
		Vector2(560.0, -1600.0),
		Vector2(720.0, -3100.0),
	], TYPE_VECTOR2, &"", null)
	m.fountains = Array([
		Vector2(510.0, -4500.0), # Font del Portal
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(430.0, -1100.0),
		Vector2(850.0, -2100.0),
		Vector2(430.0, -3450.0),
		Vector2(840.0, -4400.0),
	], TYPE_VECTOR2, &"", null)

	# Poles: Rock spires and pines
	for sp: Vector2 in SPIRES:
		m.poles.append(sp)
	for pn: Vector2 in PINES:
		m.poles.append(pn)

	# Mark / Hydrant spots (at least 6 for sniff goals)
	var marks: Array[Vector2] = [
		Vector2(480.0, -400.0),
		Vector2(800.0, -1200.0),
		Vector2(490.0, -2000.0),
		Vector2(790.0, -2900.0),
		CHEESE_STALL_POS,
		Vector2(510.0, -4500.0), # Font del Portal
		PRIZE,
	]

	# Snacks: drops along the trail
	var snacks: Array[Vector2] = [
		Vector2(520.0, -800.0),
		Vector2(760.0, -1700.0),
		Vector2(580.0, -2800.0),
		Vector2(530.0, -3350.0), # Mató cheese crumb
		Vector2(690.0, -4200.0),
	]

	return [marks, snacks]


# The carriage crosses, waits off the path at the far side, and comes back:
# a passing train with gaps to cross in, not a wall. Walk time (main.elapsed)
# drives it, so a seeded walk replays.
const FUNICULAR_FROM := 240.0
const FUNICULAR_TO := 1040.0
const FUNICULAR_PAUSE := 6.0
# the path's span the carriage can hit, and the bell's lead before it does
const PATH_L := 640.0 - HALF
const PATH_R := 640.0 + HALF
const FUNICULAR_WARN := 0.8
const FUNICULAR_HIT_HALF := 28.0
const FUNICULAR_INVOLVED := 260.0


static func funicular_car_x(elapsed: float) -> float:
	var run := (FUNICULAR_TO - FUNICULAR_FROM) / FUNICULAR_SPEED
	var leg := run + FUNICULAR_PAUSE
	var t := fmod(elapsed, leg * 2.0)
	if t < run:
		return FUNICULAR_FROM + t * FUNICULAR_SPEED
	if t < leg:
		return FUNICULAR_TO
	if t < leg + run:
		return FUNICULAR_TO - (t - leg) * FUNICULAR_SPEED
	return FUNICULAR_FROM


static func funicular_on_path(elapsed: float) -> bool:
	var cx := funicular_car_x(elapsed)
	return cx + FUNICULAR_CAR_W * 0.5 > PATH_L and cx - FUNICULAR_CAR_W * 0.5 < PATH_R


# the bell rings from FUNICULAR_WARN before the carriage reaches the path
# until it has left it
static func funicular_near_crossing(elapsed: float) -> bool:
	return funicular_on_path(elapsed) or funicular_on_path(elapsed + FUNICULAR_WARN)


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "montserrat":
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	var fun: Dictionary = m.montserrat_funicular
	var car_x := funicular_car_x(m.elapsed)
	var near := funicular_near_crossing(m.elapsed)
	# the half barriers, for show: down with the bell, up when it stops
	fun["barrier"] = move_toward(float(fun.get("barrier", 0.0)), 1.0 if near else 0.0, delta * 3.0)

	if String(fun.get("state", "waiting")) == "waiting":
		if near:
			fun["state"] = "crossing"
			fun["t"] = 0.0
			fun["hit"] = false
			fun["involved"] = false
			Sfx.play("crossing_bell", 1.0)
		return
	fun["t"] = float(fun.get("t", 0.0)) + delta
	if absf(hp.y - CROSSING_Y) < FUNICULAR_INVOLVED or absf(dp.y - CROSSING_Y) < FUNICULAR_INVOLVED:
		fun["involved"] = true
	if not near:
		fun["state"] = "waiting"
		# a pass that came by the pair and touched neither: waited out or dodged
		if bool(fun.get("involved", false)) and not bool(fun.get("hit", false)) and not m.montserrat_funicular_dodged:
			m.montserrat_funicular_dodged = true
			m.award_points(3, "funicular cleared! +3")
			m.feed.say("CLEAR OF THE FUNICULAR!", EventFeed.Tone.GOOD)
		return
	# the bell's lead is the warning: nothing is hit before the carriage is on the path
	if not funicular_on_path(m.elapsed) or bool(fun.get("hit", false)):
		return
	var half_w := FUNICULAR_CAR_W * 0.5
	var dog_hit := absf(dp.y - CROSSING_Y) < FUNICULAR_HIT_HALF and absf(dp.x - car_x) < half_w
	var human_hit := absf(hp.y - CROSSING_Y) < FUNICULAR_HIT_HALF and absf(hp.x - car_x) < half_w
	if not dog_hit and not human_hit:
		return
	fun["hit"] = true
	m.feed.say("MIND THE FUNICULAR!", EventFeed.Tone.LOUD)
	if dog_hit:
		m.dog.knocked(Vector2(signf(dp.x - car_x), 0.0), "funicular")
	if human_hit:
		m.human.patience = maxf(0.0, m.human.patience - m.LIVE_EVENT_BUMP_PATIENCE)
		m.human.bumped(Vector2(signf(hp.x - car_x), 0.0))


static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lvl != "montserrat":
		return
	# Bark near mel i mató cheese stall
	if pos.distance_to(CHEESE_STALL_POS) < 140.0:
		if not m.montserrat_mato_barked:
			m.montserrat_mato_barked = true
			m.bones += 3
			m.float_text(pos + Vector2(0, -30), "mel i mato! +3", HONEY_GOLD)
			m.feed.say("TASTA EL MEL I MATO!", EventFeed.Tone.GOOD)
			m.get_node("/root/Sfx").play("prize", 1.1)


# --- drawing ---------------------------------------------------------------
# The mountain is the edge layer (cached): the drop to the valley on the west,
# the conglomerate wall and its domes on the east, the monastery's blocks at
# the top. The path, its steps, the railway and everything standing on the
# path that never moves are the cross-section (cached with the ground). Only
# the carriage and the signals are drawn live.

static func _h(n: float) -> float:
	return fposmod(sin(n * 12.9898 + 4.1) * 43758.5453, 1.0)


# 0..1: how far the west rim is pushed out for the lower station's shelf
static func _shelf(y: float) -> float:
	return 1.0 - smoothstep(70.0, 190.0, absf(y - CROSSING_Y))


# where the rock ends and the drop begins, west of the path
static func _rim_x(y: float) -> float:
	var x := 316.0 + 15.0 * sin(y * 0.011) + 9.0 * sin(y * 0.037 + 1.3)
	x = lerpf(x, 128.0, _shelf(y))
	if y < TERRACE_Y + 40.0:
		x = lerpf(x, 150.0, smoothstep(0.0, 80.0, TERRACE_Y + 40.0 - y))
	return x


# a lump of conglomerate from above: rounded, lit from the north-west, with
# the pebbles that are set in it
static func _dome(b: ShapeBatch, p: Vector2, r: float, seed_n: float, lit := 1.0) -> void:
	b.circle(p + Shade.light * (r * 0.30), r * 1.02, Color(ROCK_DEEP, 0.55))
	b.circle(p, r, ROCK)
	b.circle(p - Shade.light * (r * 0.20), r * 0.76, ROCK.lerp(ROCK_LIT, 0.75 * lit))
	b.circle(p - Shade.light * (r * 0.42), r * 0.40, ROCK_LIT.lerp(Color.WHITE, 0.10 * lit))
	var n := 2 + int(r / 18.0)
	for i in range(n):
		var a := _h(seed_n + float(i) * 1.7) * TAU
		var d := r * (0.20 + 0.62 * _h(seed_n * 3.1 + float(i)))
		var pr := 1.8 + _h(seed_n + float(i) * 5.3) * minf(4.5, r * 0.07)
		var at := p + Vector2.from_angle(a) * d
		b.coarse(at, pr, PEBBLES[int(_h(seed_n * 7.0 + float(i)) * 5.0) % 5])


static func _oak(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * (r * 0.5), r, Color(0.08, 0.10, 0.12, 0.34))
	b.coarse(p, r, OAK)
	for i in range(4):
		var a := seed_n + float(i) * 1.7
		b.coarse(p + Vector2.from_angle(a) * r * 0.55, r * 0.55, OAK.lerp(OAK_LIT, 0.35 + 0.2 * float(i % 2)))
	b.coarse(p - Shade.light * (r * 0.35), r * 0.42, OAK_LIT)


static func _scrub(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * 3.0, r, Color(0.08, 0.10, 0.12, 0.28))
	b.coarse(p, r, SCRUB)
	b.coarse(p + Vector2(-r * 0.4, -r * 0.3), r * 0.6, SCRUB.lightened(0.14))
	if _h(seed_n) > 0.5:
		b.coarse(p + Vector2(r * 0.3, -r * 0.2), 2.2, BLOSSOM)
		b.coarse(p + Vector2(-r * 0.2, r * 0.4), 1.8, BLOSSOM)
	elif _h(seed_n) > 0.3:
		b.coarse(p + Vector2(r * 0.2, r * 0.1), 2.6, BROOM)


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	# hundreds of rounded rocks: sides by size, not 64 each (ShapeBatch.lod)
	var was := b.lod
	b.lod = true
	_draw_valley(b, top, bot)
	_draw_west_rim(b, top, bot)
	_draw_east_wall(b, top, bot)
	_draw_stations(b, top, bot)
	_draw_monastery(m, b, top, bot)
	b.lod = was


# far below: the valley in its haze, the road and the river winding through
# it, a cloud or two under your feet
static func _draw_valley(b: ShapeBatch, top: float, bot: float) -> void:
	b.rect(Rect2(-460.0, top, 860.0, bot - top), VALLEY)
	var strip := 60.0
	var y := floorf(bot / strip) * strip + strip
	while y > top - strip:
		var k := absf(y) / strip
		# fields and woods, small with distance
		for i in range(3):
			var hx := _h(k * 3.0 + float(i) * 9.1)
			var fx := -420.0 + hx * 700.0
			var fy := y + _h(k + float(i) * 2.3) * strip
			if i == 0:
				b.rect(Rect2(fx, fy, 34.0 + hx * 30.0, 16.0), VALLEY.lerp(Color(0.66, 0.68, 0.48), 0.5))
			else:
				b.coarse(Vector2(fx, fy), 7.0 + hx * 9.0, VALLEY_WOOD)
				b.coarse(Vector2(fx + 9.0, fy + 4.0), 5.0 + hx * 5.0, VALLEY_WOOD.lightened(0.06))
		var r0 := 190.0 + 46.0 * sin(y * 0.0052) + 14.0 * sin(y * 0.021)
		var r1 := 190.0 + 46.0 * sin((y - strip) * 0.0052) + 14.0 * sin((y - strip) * 0.021)
		b.line(Vector2(r0, y), Vector2(r1, y - strip), Color(0.84, 0.82, 0.74), 3.0)
		var w0 := -130.0 + 60.0 * sin(y * 0.0031 + 2.0)
		var w1 := -130.0 + 60.0 * sin((y - strip) * 0.0031 + 2.0)
		b.line(Vector2(w0, y), Vector2(w1, y - strip), Color(0.58, 0.70, 0.78), 22.0)
		y -= strip
	# the air between here and there
	b.rect(Rect2(-460.0, top, 860.0, bot - top), Color(HAZE, 0.30))
	var cy := floorf(bot / 520.0) * 520.0 + 520.0
	while cy > top - 520.0:
		var ck := absf(cy) / 520.0
		var cp := Vector2(40.0 + _h(ck) * 190.0, cy + _h(ck * 2.0) * 300.0)
		b.glow(cp, 150.0, Color(1.0, 1.0, 1.0, 0.50), 0.2)
		b.glow(cp + Vector2(-110.0, 46.0), 110.0, Color(1.0, 1.0, 1.0, 0.42), 0.2)
		b.glow(cp + Vector2(70.0, -60.0), 90.0, Color(1.0, 1.0, 1.0, 0.36), 0.2)
		cy -= 520.0


# the ledge the path runs on: its rounded lip, the face falling away into
# shadow, rosemary and holm oak holding on at the rim, the iron rail
static func _draw_west_rim(b: ShapeBatch, top: float, bot: float) -> void:
	var strip := 40.0
	var y0 := floorf(bot / strip) * strip + strip
	var y := y0
	while y > top - strip:
		var ra := _rim_x(y - strip)
		var rb := _rim_x(y)
		# the face below the lip, darkening as it drops out of the light
		b.band(PackedVector2Array([
			Vector2(ra - 96.0, y - strip), Vector2(ra - 30.0, y - strip), Vector2(ra + 2.0, y - strip),
			Vector2(rb - 96.0, y), Vector2(rb - 30.0, y), Vector2(rb + 2.0, y),
		]), 3, Color(0.20, 0.17, 0.25), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.50, 0.78]))
		b.quad(Vector2(ra, y - strip), Vector2(384.0, y - strip), Vector2(384.0, y), Vector2(rb, y), ROCK)
		y -= strip
	y = y0
	while y > top - strip:
		var k := absf(y) / strip
		var rx := _rim_x(y - strip * 0.5)
		var h1 := _h(k)
		var h2 := _h(k * 2.7 + 5.0)
		# the lip is lumps of the same rock, not a ruled line
		_dome(b, Vector2(rx + 8.0 + h1 * 6.0, y - strip * 0.5), 17.0 + h2 * 9.0, k * 1.3)
		if rx < 330.0 and h2 > 0.55:
			_dome(b, Vector2(rx + 34.0 + h1 * (350.0 - rx) * 0.6, y - h2 * strip), 12.0 + h1 * 10.0, k * 2.9, 0.6)
		y -= strip
	y = y0
	while y > top - strip:
		var k := absf(y) / strip
		var rx := _rim_x(y - strip * 0.5)
		var h1 := _h(k * 5.1 + 2.0)
		var h2 := _h(k * 1.9 + 8.0)
		if _shelf(y) < 0.2 and y > TERRACE_Y:
			if int(k) % 5 == 2:
				_oak(b, Vector2(rx - 6.0 + h1 * 10.0, y - 20.0), 19.0 + h2 * 8.0, k)
			elif h1 > 0.45:
				_scrub(b, Vector2(rx + 6.0 + h2 * (352.0 - rx), y - h1 * strip), 7.0 + h2 * 5.0, k)
		y -= strip
	# the rail along the drop: posts, the top bar and its shadow
	var ry := floorf(bot / 80.0) * 80.0 + 80.0
	b.line(Vector2(375.5, top), Vector2(375.5, bot), Color(0.10, 0.09, 0.12, 0.30), 2.5)
	b.line(Vector2(372.0, top), Vector2(372.0, bot), RAIL_IRON, 2.6)
	while ry > top - 80.0:
		b.circle(Vector2(372.0, ry), 3.6, RAIL_IRON)
		b.circle(Vector2(371.3, ry - 0.8), 1.6, RAIL_IRON.lightened(0.35))
		ry -= 80.0


# the wall on the uphill side: a lit face at the path, then the tops of the
# domes it is made of, one behind another, with oaks in the gullies between
static func _draw_east_wall(b: ShapeBatch, top: float, bot: float) -> void:
	b.rect(Rect2(896.0, top, 830.0, bot - top), ROCK_SHADE)
	var strip := 80.0
	var y0 := floorf((bot + 200.0) / strip) * strip
	var y := y0
	# far domes first, so the near ones stand in front
	for row in range(1, -1, -1):
		y = y0
		while y > top - 200.0:
			var k := absf(y) / strip + float(row) * 37.0
			var h1 := _h(k)
			var h2 := _h(k * 3.3 + 1.0)
			var r := 54.0 + h2 * 30.0 + float(row) * 22.0
			var x := 972.0 + float(row) * 170.0 + h1 * 60.0
			var p := Vector2(x, y - h2 * 40.0)
			if not (_in_cutting(p, r) or (y < TERRACE_Y + 60.0 and x - r < 1150.0)):
				_dome(b, p, r, k)
				if h1 > 0.55:
					_oak(b, p + Vector2(-r * 0.9, r * 0.75), 15.0 + h2 * 10.0, k)
				elif h1 < 0.3:
					_scrub(b, p + Vector2(-r * 0.8, r * 0.8), 8.0 + h2 * 4.0, k)
			y -= strip
	# the face at the path: lit from the west, runnels down it, a rounded brow
	var fs := 56.0
	y = floorf(bot / fs) * fs + fs
	while y > top - fs:
		var k := absf(y) / fs
		var h1 := _h(k * 4.3)
		var h2 := _h(k * 6.1 + 3.0)
		if absf(y - fs * 0.5 - CROSSING_Y) > 48.0 and y > TERRACE_Y:
			_dome(b, Vector2(936.0 + h1 * 10.0, y - fs * 0.5), 28.0 + h2 * 12.0, k * 1.9)
		y -= fs
	fs = 40.0
	b.rect(Rect2(896.0, top, 22.0, bot - top), WALL_FACE)
	b.rect(Rect2(916.0, top, 4.0, bot - top), ROCK_LIT)
	y = floorf(bot / fs) * fs + fs
	while y > top - fs:
		var k := absf(y) / fs
		b.line(Vector2(898.0, y - _h(k) * fs), Vector2(916.0, y - _h(k) * fs + 3.0), Color(ROCK_SHADE, 0.7), 2.0)
		b.line(Vector2(904.0, y - _h(k * 2.2) * fs), Vector2(917.0, y - _h(k * 2.2) * fs + 2.0), Color(ROCK_DEEP, 0.4), 1.4)
		b.coarse(Vector2(900.0 + _h(k * 3.0) * 14.0, y - _h(k * 5.0) * fs), 2.6, PEBBLES[int(k) % 5])
		y -= fs


# the notch the upper station sits in
static func _in_cutting(p: Vector2, r: float) -> bool:
	return p.x - r < 1170.0 and absf(p.y - (CROSSING_Y - 30.0)) < 96.0 + r


# the Sant Joan funicular's two ends: the track out to its buffers, a platform
# and a shelter at each, where the carriage waits between passes
static func _draw_stations(b: ShapeBatch, top: float, bot: float) -> void:
	if CROSSING_Y < top - 160.0 or CROSSING_Y > bot + 160.0:
		return
	# the cutting floor on the uphill side, its north wall's shadow across it
	b.rect(Rect2(896.0, CROSSING_Y - 112.0, 264.0, 164.0), ROCK_SHADE.lerp(ROCK, 0.5))
	b.band(PackedVector2Array([
		Vector2(896.0, CROSSING_Y - 112.0), Vector2(1160.0, CROSSING_Y - 112.0),
		Vector2(896.0, CROSSING_Y - 84.0), Vector2(1160.0, CROSSING_Y - 84.0),
	]), 2, Color(0.14, 0.11, 0.16), PackedFloat32Array([0.55, 0.0]))
	_track(b, 150.0, 384.0)
	_track(b, 896.0, 1130.0)
	for s: float in [-1.0, 1.0]:
		var end_x := 640.0 + s * 492.0
		# the buffer stop
		b.rect(Rect2(end_x - 5.0, CROSSING_Y - 22.0, 10.0, 44.0), Color(0.20, 0.20, 0.22))
		for i in range(4):
			b.rect(Rect2(end_x - 4.0, CROSSING_Y - 20.0 + float(i) * 10.0, 8.0, 5.0),
				FUNICULAR_RED if i % 2 == 0 else FUNICULAR_CREAM)
		# the platform, north of the track, with its yellow line
		var px0 := 940.0 if s > 0.0 else 160.0
		var plat := Rect2(px0, CROSSING_Y - 76.0, 180.0, 46.0)
		b.rect(Rect2(plat.position + Shade.light * 4.0, plat.size), SHADOW)
		b.rect(plat, PLATFORM)
		b.rect(Rect2(plat.position.x, plat.end.y - 7.0, plat.size.x, 4.0), Color(0.93, 0.78, 0.22))
		for i in range(1, 6):
			var jx := plat.position.x + float(i) * 30.0
			b.line(Vector2(jx, plat.position.y), Vector2(jx, plat.end.y - 8.0), Color(PLATFORM.darkened(0.14), 0.7), 1.2)
		# the shelter: a pitched roof, the bench under its eave
		var roof := Rect2(plat.position.x + 34.0, plat.position.y - 20.0, 112.0, 44.0)
		b.rect(Rect2(roof.position + Shade.light * 12.0, roof.size), Color(0.06, 0.05, 0.08, 0.34))
		b.rect(Rect2(roof.position.x + 8.0, roof.end.y + 1.0, roof.size.x - 16.0, 6.0), Color(0.46, 0.32, 0.20))
		b.rect(roof, SHELTER_ROOF.darkened(0.16))
		b.rect(Rect2(roof.position, Vector2(roof.size.x, roof.size.y * 0.5)), SHELTER_ROOF)
		b.line(Vector2(roof.position.x, roof.get_center().y), Vector2(roof.end.x, roof.get_center().y), SHELTER_ROOF.lightened(0.3), 2.0)
		for i in range(1, 8):
			var sx := roof.position.x + float(i) * 14.0
			b.line(Vector2(sx, roof.position.y + 1.0), Vector2(sx, roof.end.y - 1.0), Color(0.10, 0.14, 0.14, 0.22), 1.0)
		# the station's name board, blue with its white band
		b.rect(Rect2(roof.position.x + 30.0, roof.position.y - 9.0, 52.0, 8.0), Color(0.16, 0.28, 0.52))
		b.rect(Rect2(roof.position.x + 34.0, roof.position.y - 6.5, 44.0, 3.0), Color(0.94, 0.94, 0.92))
		# a lamp at the platform's path end
		var lamp := Vector2(plat.position.x + (8.0 if s > 0.0 else plat.size.x - 8.0), plat.position.y + 8.0)
		b.circle(lamp, 4.0, RAIL_IRON)
		b.circle(lamp, 2.2, Color(0.98, 0.94, 0.78))


# a length of the inclined railway: ballast, sleepers, the two running rails
# and the haul cable on its rollers down the middle
static func _track(b: ShapeBatch, x0: float, x1: float) -> void:
	b.rect(Rect2(x0, CROSSING_Y - 27.0, x1 - x0, 54.0), BALLAST.darkened(0.12))
	b.rect(Rect2(x0, CROSSING_Y - 24.0, x1 - x0, 48.0), BALLAST)
	var n := int((x1 - x0) / 9.0)
	for i in range(n):
		var hx := _h(float(i) * 1.3 + x0)
		b.coarse(Vector2(x0 + (float(i) + hx) * 9.0, CROSSING_Y - 22.0 + _h(float(i) * 2.9 + x0) * 44.0), 1.6,
			BALLAST.lightened(0.16) if i % 2 == 0 else BALLAST.darkened(0.2))
	var sx := floorf(x0 / 22.0) * 22.0 + 11.0
	while sx < x1 - 4.0:
		if sx > x0 + 4.0:
			b.rect(Rect2(sx - 4.0, CROSSING_Y - 19.0, 9.0, 40.0), Color(0.10, 0.08, 0.08, 0.35))
			b.rect(Rect2(sx - 5.0, CROSSING_Y - 20.0, 9.0, 40.0), RAIL_WOOD)
			b.rect(Rect2(sx - 5.0, CROSSING_Y - 20.0, 9.0, 3.0), RAIL_WOOD.lightened(0.14))
		sx += 22.0
	for ry: float in [-12.0, 12.0]:
		b.line(Vector2(x0, CROSSING_Y + ry + 1.6), Vector2(x1, CROSSING_Y + ry + 1.6), Color(0.08, 0.07, 0.09, 0.45), 3.0)
		b.line(Vector2(x0, CROSSING_Y + ry), Vector2(x1, CROSSING_Y + ry), RAIL_STEEL.darkened(0.3), 4.4)
		b.line(Vector2(x0, CROSSING_Y + ry - 0.6), Vector2(x1, CROSSING_Y + ry - 0.6), RAIL_STEEL, 1.8)
	b.line(Vector2(x0, CROSSING_Y), Vector2(x1, CROSSING_Y), Color(0.16, 0.16, 0.18), 2.0)
	var px := floorf(x0 / 66.0) * 66.0 + 33.0
	while px < x1 - 6.0:
		if px > x0 + 6.0:
			b.rect(Rect2(px - 5.0, CROSSING_Y - 4.0, 10.0, 8.0), Color(0.22, 0.22, 0.25))
			b.circle(Vector2(px, CROSSING_Y), 2.6, Color(0.70, 0.72, 0.76))
		px += 66.0


# the monastery's blocks either side of the plaça: tiled roofs from above, and
# down the face that looks onto the square, a row of arched windows
static func _draw_monastery(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var y1: float = TERRACE_Y - 36.0
	var y0: float = m.GATE_Y - 40.0
	if y1 < top - 60.0 or y0 > bot:
		return
	for s: float in [-1.0, 1.0]:
		var x_lo := 140.0 if s < 0.0 else 902.0
		var w := 238.0 if s < 0.0 else 258.0
		b.rect(Rect2(x_lo + Shade.light.x * 16.0, y0 + Shade.light.y * 16.0, w, y1 - y0 + 30.0), Color(0.06, 0.05, 0.08, 0.36))
		# the south gable end, in the light: four windows under the eave
		b.rect(Rect2(x_lo, y1, w, 30.0), MONASTERY_WALL.darkened(0.06))
		b.rect(Rect2(x_lo, y1 + 27.0, w, 3.0), MONASTERY_WALL.darkened(0.22))
		for i in range(4):
			_arch(b, Vector2(x_lo + 32.0 + float(i) * (w - 64.0) / 3.0, y1 + 25.0), 8.0, 17.0)
		# the roof: two pitches off a ridge, the tile courses across them
		b.rect(Rect2(x_lo, y0, w, y1 - y0), MONASTERY_ROOF.darkened(0.14))
		b.rect(Rect2(x_lo, y0, w * 0.5, y1 - y0), MONASTERY_ROOF)
		var ty := floorf(minf(y1, bot + 14.0) / 14.0) * 14.0
		while ty > maxf(y0, top - 14.0):
			b.line(Vector2(x_lo, ty), Vector2(x_lo + w, ty), Color(0.40, 0.18, 0.12, 0.30), 1.4)
			ty -= 14.0
		b.line(Vector2(x_lo + w * 0.5, y0), Vector2(x_lo + w * 0.5, y1), MONASTERY_ROOF.lightened(0.28), 4.0)
		b.line(Vector2(x_lo, y1 - 1.0), Vector2(x_lo + w, y1 - 1.0), MONASTERY_ROOF.lightened(0.2), 3.0)
		# the face on the plaça: stone, and an arched window to each bay. The
		# west block's looks east, away from the light
		var fx := x_lo + w - 22.0 if s < 0.0 else x_lo
		var edge_x := fx if s < 0.0 else fx + 22.0
		b.rect(Rect2(fx, y0, 22.0, y1 - y0), MONASTERY_WALL.darkened(0.16) if s < 0.0 else MONASTERY_WALL)
		b.line(Vector2(edge_x, y0), Vector2(edge_x, y1), MONASTERY_ROOF.lightened(0.24), 2.4)
		var wy := floorf(y1 / 58.0) * 58.0 - 20.0
		while wy > y0 + 10.0:
			b.rect(Rect2(fx + 5.0, wy - 8.0, 12.0, 16.0), Color(0.16, 0.13, 0.14))
			b.circle(Vector2(fx + 11.0, wy - 8.0), 6.0, Color(0.16, 0.13, 0.14))
			b.rect(Rect2(fx + 3.0, wy + 8.0, 16.0, 2.5), MONASTERY_WALL.lightened(0.16))
			wy -= 58.0
	# a cypress by each gable, as the square has
	for cp: Vector2 in [Vector2(350.0, TERRACE_Y + 24.0), Vector2(934.0, TERRACE_Y + 24.0)]:
		b.coarse(cp + Shade.light * 12.0, 13.0, Color(0.06, 0.08, 0.10, 0.34))
		b.coarse(cp, 13.0, Color(0.13, 0.24, 0.17))
		b.coarse(cp - Shade.light * 3.0, 8.0, Color(0.20, 0.33, 0.22))
		b.coarse(cp - Shade.light * 5.0, 3.6, Color(0.30, 0.44, 0.28))


# a round-headed opening seen on a wall face, its foot at `foot`
static func _arch(b: ShapeBatch, foot: Vector2, hw: float, h: float) -> void:
	var dark := Color(0.15, 0.12, 0.13)
	b.rect(Rect2(foot.x - hw, foot.y - h + hw, hw * 2.0, h - hw), dark)
	b.circle(Vector2(foot.x, foot.y - h + hw), hw, dark)
	b.rect(Rect2(foot.x - hw - 1.5, foot.y - 2.0, hw * 2.0 + 3.0, 2.0), MONASTERY_WALL.lightened(0.18))


# --- cross section: the path and what stands on it ---------------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 60.0, ctop)
	var hi: float = minf(vb + 60.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	var was := wc.lod
	wc.lod = true
	_draw_trail(wc, maxf(lo, TERRACE_Y), hi)
	_draw_placa(wc, lo, minf(hi, TERRACE_Y))
	_draw_trail_sides(wc, lo, hi)
	_draw_crossing(wc, lo, hi)
	_draw_gate_piers(wc, lo, hi)
	_draw_stall(wc, lo, hi)
	_draw_arcades(wc, lo, hi)
	wc.lod = was


# stone and gravel, climbing: a riser of cut blocks every flight, its face and
# shadow on the downhill side, flags worn into the middle, scree at the sides
static func _draw_trail(wc: ShapeBatch, lo: float, hi: float) -> void:
	if hi <= lo:
		return
	wc.rect(Rect2(PATH_L, lo, PATH_R - PATH_L, hi - lo), TRAIL)
	var strip := 40.0
	var y := floorf(hi / strip) * strip + strip
	while y > lo - strip:
		var k := absf(y) / strip
		# worn flags, never two rows alike
		for i in range(3):
			var hx := _h(k * 2.1 + float(i) * 7.7)
			var hy := _h(k * 5.3 + float(i) * 3.1)
			var fw := 34.0 + hx * 40.0
			var fx := PATH_L + 40.0 + _h(k + float(i) * 11.0) * (PATH_R - PATH_L - 80.0 - fw)
			var fy := y - strip + hy * (strip - 18.0)
			var tone := TRAIL_LIT if (i + int(k)) % 2 == 0 else TRAIL_DARK
			# set flush in the gravel: a joint round it, no height
			wc.rect(Rect2(fx - 1.0, fy - 1.0, fw + 2.0, 17.0 + hx * 6.0), Color(TRAIL_DARK, 0.55))
			wc.rect(Rect2(fx, fy, fw, 15.0 + hx * 6.0), TRAIL.lerp(tone, 0.30))
		# gravel
		for i in range(5):
			var gp := Vector2(PATH_L + 14.0 + _h(k * 3.7 + float(i) * 13.0) * (PATH_R - PATH_L - 28.0), y - _h(k * 9.1 + float(i)) * strip)
			wc.coarse(gp, 1.4 + _h(k + float(i)) * 1.6, PEBBLES[(int(k) + i) % 5].lerp(TRAIL, 0.35))
		y -= strip
	# the flights
	var sy := floorf(hi / STEP_EVERY) * STEP_EVERY + STEP_EVERY
	while sy > lo - STEP_EVERY:
		if absf(sy - CROSSING_Y) > 90.0 and sy < 200.0 and sy > TERRACE_Y + 30.0:
			_riser(wc, sy, PATH_L, PATH_R, absf(sy))
		sy -= STEP_EVERY


# one step across the path at y: the tread's lit edge, the riser's face below
# it, and the shadow it throws down the slope
static func _riser(wc: ShapeBatch, y: float, x0: float, x1: float, seed_n: float) -> void:
	wc.band(PackedVector2Array([
		Vector2(x0, y + 15.0), Vector2(x1, y + 15.0),
		Vector2(x0, y + 46.0), Vector2(x1, y + 46.0),
	]), 2, Color(0.12, 0.10, 0.14), PackedFloat32Array([0.30, 0.0]))
	wc.rect(Rect2(x0, y + 8.0, x1 - x0, 8.0), STEP_FACE)
	wc.rect(Rect2(x0, y, x1 - x0, 9.0), STEP_TOP)
	wc.rect(Rect2(x0, y, x1 - x0, 2.5), STEP_TOP.lightened(0.22))
	var x := x0
	var i := 0
	while x < x1 - 20.0:
		x += 38.0 + _h(seed_n + float(i) * 3.3) * 34.0
		i += 1
		if x < x1 - 8.0:
			wc.line(Vector2(x, y + 1.0), Vector2(x, y + 15.0), Color(STEP_FACE.darkened(0.3), 0.8), 1.6)
			if i % 3 == 0:
				wc.rect(Rect2(x - 30.0, y, 24.0, 9.0), STEP_TOP.darkened(0.07))


# Plaça de Santa Maria: pale flags in courses, the broad stair up onto it, and
# behind the arcade the atrium's ring of inlaid marble
static func _draw_placa(wc: ShapeBatch, lo: float, hi: float) -> void:
	if hi <= lo:
		return
	wc.rect(Rect2(PATH_L, lo, PATH_R - PATH_L, hi - lo), PLACA)
	var course := 52.0
	var y := floorf(hi / course) * course
	while y > lo - course:
		var k := int(absf(y) / course)
		wc.line(Vector2(PATH_L, y), Vector2(PATH_R, y), PLACA_JOINT, 1.6)
		var x := PATH_L + (26.0 if k % 2 == 0 else 0.0)
		var i := 0
		while x < PATH_R:
			var fx := maxf(x, PATH_L) + 1.0
			var fw := minf(x + 52.0, PATH_R) - fx - 1.0
			if _h(float(k) * 3.1 + float(i) * 1.7) > 0.62:
				wc.rect(Rect2(fx, y + 1.0, fw, course - 2.0), PLACA.darkened(0.05))
			elif _h(float(k) * 1.3 + float(i) * 4.9) > 0.72:
				wc.rect(Rect2(fx, y + 1.0, fw, course - 2.0), PLACA.lightened(0.06))
			if x > PATH_L:
				wc.line(Vector2(x, y), Vector2(x, y + course), PLACA_JOINT, 1.4)
			x += 52.0
			i += 1
		y -= course
	# the atrium's inlay, north of the arcade
	if ATRIUM.y > lo - 120.0 and ATRIUM.y < hi + 120.0:
		wc.circle(ATRIUM, 96.0, Color(0.36, 0.34, 0.36))
		wc.circle(ATRIUM, 91.0, Color(0.93, 0.91, 0.86))
		for i in range(24):
			var a := TAU * float(i) / 24.0
			var d0 := Vector2.from_angle(a)
			var d1 := Vector2.from_angle(a + TAU / 48.0)
			var d2 := Vector2.from_angle(a + TAU / 24.0)
			wc.polygon(PackedVector2Array([ATRIUM + d0 * 62.0, ATRIUM + d1 * 88.0, ATRIUM + d2 * 62.0]), Color(0.40, 0.42, 0.46))
			if i % 2 == 0:
				wc.polygon(PackedVector2Array([ATRIUM + d0 * 34.0, ATRIUM + d1 * 60.0, ATRIUM + d2 * 34.0, ATRIUM + d1 * 22.0]),
					Color(0.74, 0.50, 0.40))
		wc.circle(ATRIUM, 20.0, Color(0.36, 0.34, 0.36))
		wc.circle(ATRIUM, 16.0, Color(0.88, 0.76, 0.42))
		wc.circle(ATRIUM, 8.0, Color(0.93, 0.91, 0.86))
	# the stair up from the trail: three steps the width of the square
	for i in range(3):
		var sy := TERRACE_Y + float(i) * 22.0 - 8.0
		if sy > lo - 60.0 and sy < hi + 60.0:
			_riser(wc, sy, PATH_L, PATH_R, 900.0 + float(i))


# what holds the path's two sides: the kerb of set stones along the drop, the
# fallen scree at the foot of the wall
static func _draw_trail_sides(wc: ShapeBatch, lo: float, hi: float) -> void:
	# the kerb's shadow, then the kerb
	wc.band(PackedVector2Array([
		Vector2(PATH_L + 8.0, lo), Vector2(PATH_L + 30.0, lo),
		Vector2(PATH_L + 8.0, hi), Vector2(PATH_L + 30.0, hi),
	]), 2, Color(0.12, 0.10, 0.14), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.26, 0.0]))
	wc.rect(Rect2(PATH_L, lo, 9.0, hi - lo), KERB.darkened(0.2))
	wc.rect(Rect2(PATH_L, lo, 7.0, hi - lo), KERB)
	wc.rect(Rect2(PATH_L, lo, 2.0, hi - lo), KERB.lightened(0.2))
	var y := floorf(hi / 26.0) * 26.0 + 26.0
	while y > lo - 26.0:
		var k := absf(y) / 26.0
		wc.line(Vector2(PATH_L, y + _h(k) * 6.0), Vector2(PATH_L + 8.0, y + _h(k) * 6.0), Color(KERB.darkened(0.45), 0.8), 1.4)
		y -= 26.0
	# scree under the wall, thinning toward the middle; none on the plaça
	y = floorf(hi / 30.0) * 30.0 + 30.0
	while y > maxf(lo, TERRACE_Y) - 30.0:
		var k := absf(y) / 30.0
		if absf(y - CROSSING_Y) > 60.0 and y > TERRACE_Y + 10.0:
			for i in range(3):
				var d := _h(k * 2.3 + float(i) * 5.0)
				var p := Vector2(PATH_R - 4.0 - d * d * 34.0, y - _h(k * 7.7 + float(i)) * 30.0)
				var r := 2.2 + (1.0 - d) * 4.2
				wc.coarse(p + Vector2(1.2, 1.6), r, Color(0.12, 0.10, 0.14, 0.30))
				wc.coarse(p, r, ROCK.lerp(PEBBLES[(int(k) + i) % 5], 0.45))
				wc.coarse(p - Shade.light * (r * 0.3), r * 0.5, ROCK_LIT)
		y -= 30.0


# the level crossing: the track through, a timber deck between and beside the
# rails, yellow edges, a hatched box and a stop line either side
static func _draw_crossing(wc: ShapeBatch, lo: float, hi: float) -> void:
	if CROSSING_Y < lo - 120.0 or CROSSING_Y > hi + 120.0:
		return
	_track(wc, PATH_L - 4.0, PATH_R + 4.0)
	for strip: Vector2 in [Vector2(-25.0, -15.0), Vector2(-9.0, 9.0), Vector2(15.0, 25.0)]:
		wc.rect(Rect2(PATH_L + 8.0, CROSSING_Y + strip.x, PATH_R - PATH_L - 12.0, strip.y - strip.x), DECK)
		wc.rect(Rect2(PATH_L + 8.0, CROSSING_Y + strip.x, PATH_R - PATH_L - 12.0, 1.6), DECK.lightened(0.16))
		var x := PATH_L + 8.0
		while x < PATH_R - 6.0:
			wc.line(Vector2(x, CROSSING_Y + strip.x), Vector2(x, CROSSING_Y + strip.y), Color(DECK.darkened(0.4), 0.7), 1.2)
			wc.coarse(Vector2(x + 5.0, CROSSING_Y + (strip.x + strip.y) * 0.5), 1.1, DECK.darkened(0.45))
			x += 43.0
	for s: float in [-1.0, 1.0]:
		wc.rect(Rect2(PATH_L + 8.0, CROSSING_Y + s * 29.5 - 2.5, PATH_R - PATH_L - 12.0, 5.0), Color(0.93, 0.78, 0.22))
		var y0 := CROSSING_Y + s * 36.0
		var y1 := CROSSING_Y + s * 58.0
		var hx := PATH_L + 22.0
		while hx < PATH_R - 30.0:
			wc.line(Vector2(hx, y0), Vector2(hx + 22.0, y1), Color(0.93, 0.78, 0.22, 0.55), 3.0)
			hx += 30.0
		wc.rect(Rect2(PATH_L + 12.0, CROSSING_Y + s * 66.0 - 3.0, PATH_R - PATH_L - 20.0, 6.0), Color(0.95, 0.94, 0.90, 0.85))
	# the signal masts' feet and shadows (their lamps are live)
	for sp: Vector2 in SIGNALS:
		wc.line(sp, sp + Shade.light * 30.0, Color(0.08, 0.07, 0.10, 0.30), 5.0)
		wc.rect(Rect2(sp.x - 7.0, sp.y - 7.0, 14.0, 14.0), Color(0.55, 0.53, 0.52))
		wc.rect(Rect2(sp.x - 7.0, sp.y - 7.0, 14.0, 3.0), Color(0.70, 0.68, 0.66))


# the old trail gate at the foot of the upper path: two stone piers with
# capstones, a stub of wall to the path's edge, the red and white waymark
static func _draw_gate_piers(wc: ShapeBatch, lo: float, hi: float) -> void:
	for r: Rect2 in GATE_PIERS:
		if r.end.y < lo - 40.0 or r.position.y > hi + 40.0:
			continue
		var to_edge := Rect2(PATH_L, r.position.y + 10.0, r.position.x - PATH_L, 20.0) if r.position.x < 640.0 \
			else Rect2(r.end.x, r.position.y + 10.0, PATH_R - r.end.x, 20.0)
		wc.rect(Rect2(r.position + Shade.light * 9.0, r.size), SHADOW)
		wc.rect(to_edge, KERB.darkened(0.12))
		wc.rect(Rect2(to_edge.position, Vector2(to_edge.size.x, 5.0)), KERB.lightened(0.1))
		wc.rect(r, KERB.darkened(0.22))
		wc.rect(Rect2(r.position, Vector2(r.size.x, r.size.y - 9.0)), KERB)
		wc.rect(Rect2(r.position.x + 7.0, r.position.y + 7.0, r.size.x - 14.0, r.size.y - 23.0), KERB.lightened(0.14))
		var apex := r.get_center() + Vector2(0.0, -4.5)
		for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y - 9.0), Vector2(r.end.x, r.end.y - 9.0)]:
			wc.line(corner, apex, Color(KERB.darkened(0.3), 0.5), 1.2)
		# the waymark on its face
		wc.rect(Rect2(r.get_center().x - 8.0, r.end.y - 7.0, 16.0, 2.5), Color(0.95, 0.95, 0.93))
		wc.rect(Rect2(r.get_center().x - 8.0, r.end.y - 4.5, 16.0, 2.5), Color(0.82, 0.18, 0.16))


# the mel i mató stall: a striped awning over a trestle, bowls of mató with
# honey run over them, jars of honey, the price slate
static func _draw_stall(wc: ShapeBatch, lo: float, hi: float) -> void:
	var sr := CHEESE_STALL_RECT
	if sr.end.y < lo - 60.0 or sr.position.y > hi + 60.0:
		return
	wc.rect(Rect2(sr.position + Shade.light * 10.0, sr.size), SHADOW)
	# the trestle and its cloth
	wc.rect(sr, Color(0.40, 0.28, 0.18))
	wc.rect(Rect2(sr.position.x + 34.0, sr.position.y + 2.0, 34.0, sr.size.y - 4.0), CHEESE_CREAM)
	wc.rect(Rect2(sr.position.x + 34.0, sr.position.y + 2.0, 34.0, 3.0), Color(1.0, 1.0, 0.98))
	for i in range(3):
		# a bowl of mató, honey over it
		var bp := Vector2(sr.position.x + 44.0, sr.position.y + 10.0 + float(i) * 15.0)
		wc.circle(bp + Vector2(1.0, 1.5), 7.0, Color(0.10, 0.08, 0.08, 0.30))
		wc.circle(bp, 6.6, Color(0.70, 0.38, 0.22))
		wc.circle(bp, 5.2, Color(0.99, 0.98, 0.94))
		wc.line(bp + Vector2(-3.0, -1.0), bp + Vector2(2.0, 2.0), HONEY_GOLD, 1.8)
		wc.circle(bp + Vector2(1.5, -1.5), 1.4, HONEY_GOLD)
		# a jar of honey
		var jp := Vector2(sr.position.x + 59.0, sr.position.y + 9.0 + float(i) * 15.0)
		wc.circle(jp + Vector2(1.0, 1.5), 5.4, Color(0.10, 0.08, 0.08, 0.30))
		wc.circle(jp, 5.0, HONEY_GOLD.darkened(0.18))
		wc.circle(jp, 3.8, HONEY_GOLD)
		wc.circle(jp - Shade.light * 1.2, 1.5, Color(1.0, 0.92, 0.6))
	# the awning, striped, its valance scalloped toward the path
	var aw := Rect2(sr.position.x - 4.0, sr.position.y - 5.0, 40.0, sr.size.y + 10.0)
	wc.rect(Rect2(aw.position + Shade.light * 5.0, aw.size), Color(0.06, 0.05, 0.08, 0.30))
	for i in range(6):
		var col := HONEY_GOLD if i % 2 == 0 else CHEESE_CREAM
		var ry := aw.position.y + float(i) * aw.size.y / 6.0
		wc.rect(Rect2(aw.position.x, ry, aw.size.x, aw.size.y / 6.0), col)
		wc.circle(Vector2(aw.end.x, ry + aw.size.y / 12.0), aw.size.y / 12.0, col)
	wc.rect(Rect2(aw.position.x, aw.position.y, 5.0, aw.size.y), Color(1.0, 1.0, 1.0, 0.22))
	wc.line(Vector2(aw.position.x + 20.0, aw.position.y), Vector2(aw.position.x + 20.0, aw.end.y), Color(0.30, 0.20, 0.10, 0.22), 1.6)
	# the slate, propped at the south end
	wc.rect(Rect2(sr.end.x + 3.0, sr.end.y - 14.0, 13.0, 17.0), Color(0.34, 0.24, 0.16))
	wc.rect(Rect2(sr.end.x + 5.0, sr.end.y - 12.0, 9.0, 13.0), Color(0.14, 0.16, 0.16))
	wc.line(Vector2(sr.end.x + 6.5, sr.end.y - 9.0), Vector2(sr.end.x + 12.5, sr.end.y - 9.0), Color(0.92, 0.92, 0.88), 1.2)
	wc.line(Vector2(sr.end.x + 6.5, sr.end.y - 5.0), Vector2(sr.end.x + 11.0, sr.end.y - 5.0), HONEY_GOLD, 1.2)


# the atrium's arcade, a wing either side of the way through: a tiled roof
# from above, and under its eave three round Romanesque arches on their piers
static func _draw_arcades(wc: ShapeBatch, lo: float, hi: float) -> void:
	for arc: Rect2 in [ARCADE_LEFT, ARCADE_RIGHT]:
		if arc.end.y < lo - 60.0 or arc.position.y > hi + 60.0:
			continue
		var face_y := arc.position.y + 16.0
		wc.rect(Rect2(arc.position + Shade.light * 12.0, arc.size), Color(0.06, 0.05, 0.08, 0.36))
		# the roof
		wc.rect(Rect2(arc.position.x - 2.0, arc.position.y - 6.0, arc.size.x + 4.0, 23.0), MONASTERY_ROOF.darkened(0.10))
		wc.rect(Rect2(arc.position.x - 2.0, arc.position.y - 6.0, arc.size.x + 4.0, 11.0), MONASTERY_ROOF)
		wc.line(Vector2(arc.position.x - 2.0, arc.position.y + 5.0), Vector2(arc.end.x + 2.0, arc.position.y + 5.0), MONASTERY_ROOF.lightened(0.3), 2.2)
		for i in range(1, 9):
			var tx := arc.position.x - 2.0 + float(i) * (arc.size.x + 4.0) / 9.0
			wc.line(Vector2(tx, arc.position.y - 5.0), Vector2(tx, arc.position.y + 16.0), Color(0.40, 0.18, 0.12, 0.34), 1.2)
		# the face: stone, the cornice, three arches with the dark behind them
		wc.rect(Rect2(arc.position.x, face_y, arc.size.x, arc.end.y - face_y), MONASTERY_WALL)
		wc.rect(Rect2(arc.position.x - 2.0, face_y, arc.size.x + 4.0, 3.0), MONASTERY_WALL.lightened(0.2))
		for ai in range(3):
			var ax := arc.position.x + 16.0 + float(ai) * 29.0
			# the arch's ring of voussoirs, then the opening, the plaça's light on its sill
			wc.circle(Vector2(ax, arc.end.y - 12.0), 12.0, MONASTERY_WALL.darkened(0.14))
			_arch(wc, Vector2(ax, arc.end.y), 9.5, 21.5)
			wc.band(PackedVector2Array([
				Vector2(ax - 9.5, arc.end.y - 9.0), Vector2(ax + 9.5, arc.end.y - 9.0),
				Vector2(ax - 9.5, arc.end.y), Vector2(ax + 9.5, arc.end.y),
			]), 2, PLACA, PackedFloat32Array([0.0, 0.5]))
		for pi in range(4):
			var px := arc.position.x + 1.5 + float(pi) * 29.0
			wc.rect(Rect2(px - 3.5, arc.end.y - 13.0, 7.0, 13.0), MONASTERY_WALL.lightened(0.10))
			wc.rect(Rect2(px - 5.0, arc.end.y - 15.0, 10.0, 3.0), MONASTERY_WALL.lightened(0.24))
			wc.rect(Rect2(px - 5.0, arc.end.y - 2.5, 10.0, 2.5), MONASTERY_WALL.darkened(0.12))


# --- what stands on the path: needles, pines, the fountain -------------------

static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_NONE


static func _is_spire(p: Vector2) -> bool:
	for sp: Vector2 in SPIRES:
		if sp.distance_squared_to(p) < 4.0:
			return true
	return false


# a pole's foot: an agulla's base and the long shadow of its height, or a
# pine's trunk, roots and the shade of its crown
static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_spire(p):
		var tip := p + Shade.light * SPIRE_SHADOW
		var side := Shade.SUN.orthogonal()
		wc.polygon(PackedVector2Array([
			p + side * SPIRE_R, p - side * SPIRE_R,
			tip - side * SPIRE_R * 0.7, tip + side * SPIRE_R * 0.7,
		]), Color(0.08, 0.07, 0.11, 0.26))
		wc.circle(tip, SPIRE_R * 0.7, Color(0.08, 0.07, 0.11, 0.26))
		# rubble at its foot
		for i in range(6):
			var a := float(i) * 1.05 + p.y * 0.01
			var rp := p + Vector2.from_angle(a) * (SPIRE_R + 3.0)
			wc.coarse(rp + Vector2(1.0, 1.5), 4.5, Color(0.10, 0.08, 0.12, 0.3))
			wc.coarse(rp, 4.0 + float(i % 3), ROCK.lerp(PEBBLES[i % 5], 0.35))
		wc.circle(p, SPIRE_R + 1.5, ROCK_DEEP)
		wc.circle(p, SPIRE_R, ROCK_SHADE)
		return
	wc.glow(p + Shade.light * 20.0, PINE_CROWN * 1.25, Color(0.05, 0.07, 0.10, 0.30), 0.45)
	for ri in range(4):
		var d := Vector2.from_angle(float(ri) * 1.6 + p.y * 0.02)
		wc.line(p, p + d * (13.0 + float(ri % 2) * 6.0), PINE_TRUNK.darkened(0.2), 3.2)
	wc.circle(p, 7.5, PINE_TRUNK.darkened(0.25))
	wc.circle(p, 6.2, PINE_TRUNK)
	wc.circle(p - Shade.light * 1.6, 3.4, PINE_TRUNK.lightened(0.2))


# Font del Portal: a carved stone back, a spout, the basin
static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var c: ShapeBatch = m._wc
	c.circle(f + Shade.light * 6.0, 21.0, SHADOW)
	c.rect(Rect2(f.x - 22.0, f.y - 22.0, 44.0, 14.0), MONASTERY_WALL.darkened(0.16))
	c.rect(Rect2(f.x - 22.0, f.y - 22.0, 44.0, 9.0), MONASTERY_WALL)
	c.circle(Vector2(f.x, f.y - 20.0), 9.0, MONASTERY_WALL.lightened(0.10))
	c.circle(f, 19.0, KERB.darkened(0.20))
	c.circle(f, 17.0, KERB)
	c.circle(f, 13.0, Color(0.20, 0.42, 0.52))
	c.circle(f - Shade.light * 2.0, 10.0, Color(0.36, 0.62, 0.72))
	c.circle(f + Vector2(-3.0, -3.0), 3.0, Color(0.80, 0.92, 0.96, 0.7))
	c.line(Vector2(f.x, f.y - 14.0), Vector2(f.x, f.y - 4.0), Color(0.78, 0.92, 0.98, 0.85), 2.0)
	c.circle(Vector2(f.x, f.y - 15.0), 2.6, Color(0.62, 0.50, 0.24))


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "montserrat":
		return
	if CROSSING_Y < vt - 120.0 or CROSSING_Y > vb + 120.0:
		return
	var ringing := funicular_near_crossing(m.elapsed)
	var beat := int(AnimClock.msec() / 260) % 2
	var swing := sin(float(AnimClock.msec()) * 0.045) * 2.2 if ringing else 0.0
	var down: float = float(m.montserrat_funicular.get("barrier", 0.0))
	_draw_car(wc, funicular_car_x(m.elapsed), m.elapsed)
	for sp: Vector2 in SIGNALS:
		var south := sp.y > CROSSING_Y
		# the half barrier: up along the path's edge, down across it with the bell
		var inward := 1.0 if sp.x < 640.0 else -1.0
		var pivot := Vector2(sp.x, sp.y + (12.0 if south else -12.0))
		var ang := lerpf(PI * 0.5 if south else -PI * 0.5, 0.0, down)
		var dir := Vector2(inward * cos(ang), sin(ang))
		wc.line(pivot + Shade.light * 4.0, pivot + dir * BARRIER_LEN + Shade.light * 4.0, Color(0.06, 0.05, 0.08, 0.28), 4.0)
		for si in range(6):
			wc.line(pivot + dir * (BARRIER_LEN * float(si) / 6.0), pivot + dir * (BARRIER_LEN * float(si + 1) / 6.0),
				Color(0.86, 0.16, 0.14) if si % 2 == 0 else Color(0.96, 0.95, 0.92), 4.0)
		wc.circle(pivot, 4.0, Color(0.22, 0.22, 0.25))
		# the mast head: a black backboard, the two red lamps, the bell on top
		wc.rect(Rect2(sp.x - 13.0, sp.y - 6.0, 26.0, 12.0), Color(0.10, 0.10, 0.12))
		wc.rect(Rect2(sp.x - 13.0, sp.y - 6.0, 26.0, 2.0), Color(0.90, 0.80, 0.24))
		for li in range(2):
			var lp := sp + Vector2(-6.5 + float(li) * 13.0, 0.5)
			var on := ringing and li == beat
			if on:
				wc.glow(lp, 20.0, Color(1.0, 0.25, 0.18, 0.55))
			wc.circle(lp, 4.6, Color(0.98, 0.26, 0.18) if on else Color(0.36, 0.09, 0.08))
			wc.circle(lp - Vector2(1.2, 1.2), 1.5, Color(1.0, 0.8, 0.7, 0.9 if on else 0.25))
		var bell := Vector2(sp.x + swing, sp.y - 11.0)
		wc.circle(bell, 4.4, Color(0.62, 0.48, 0.20))
		wc.circle(bell - Vector2(1.0, 1.0), 2.0, Color(0.92, 0.80, 0.44))


# the carriage from above: red sides, a cream roof with its ridge and vents,
# the windows down each side, headlamps at the end it is running toward
static func _draw_car(wc: ShapeBatch, car_x: float, elapsed: float) -> void:
	var hw := FUNICULAR_CAR_W * 0.5
	var hh := FUNICULAR_CAR_H * 0.5
	var c := Vector2(car_x, CROSSING_Y)
	var r := Rect2(c.x - hw, c.y - hh, FUNICULAR_CAR_W, FUNICULAR_CAR_H)
	wc.rect(Rect2(r.position + Shade.light * 9.0, r.size), Color(0.06, 0.05, 0.08, 0.34))
	# the body, its corners eased
	wc.rect(r.grow_individual(2.0, -3.0, 2.0, -3.0), FUNICULAR_RED.darkened(0.28))
	wc.rect(r, FUNICULAR_RED.darkened(0.28))
	wc.rect(r.grow_individual(-1.5, -1.5, -1.5, -1.5), FUNICULAR_RED)
	# the windows along each side, a passenger's head in some
	for side: float in [-1.0, 1.0]:
		var wy := c.y + side * (hh - 5.5)
		wc.rect(Rect2(r.position.x + 3.0, wy - 2.6, FUNICULAR_CAR_W - 6.0, 5.2), Color(0.12, 0.14, 0.18))
		for wi in range(5):
			var wx := r.position.x + 5.0 + float(wi) * 14.6
			wc.rect(Rect2(wx, wy - 2.0, 12.0, 4.0), FUNICULAR_GLASS)
			wc.rect(Rect2(wx, wy - 2.0, 12.0, 1.3), Color(1.0, 1.0, 1.0, 0.35))
			if (wi + (1 if side > 0.0 else 0)) % 3 == 0:
				wc.circle(Vector2(wx + 6.0, wy), 2.0, Color(0.30, 0.22, 0.18))
	# the roof
	var roof := r.grow_individual(-2.0, -8.5, -2.0, -8.5)
	wc.rect(roof, FUNICULAR_CREAM.darkened(0.10))
	wc.rect(Rect2(roof.position, Vector2(roof.size.x, roof.size.y * 0.5)), FUNICULAR_CREAM)
	wc.line(Vector2(roof.position.x + 3.0, c.y), Vector2(roof.end.x - 3.0, c.y), Color(1.0, 1.0, 0.98), 1.6)
	for vi in range(3):
		var vx := c.x - 22.0 + float(vi) * 22.0
		wc.rect(Rect2(vx - 5.0, c.y - 3.5, 10.0, 7.0), Color(0.62, 0.62, 0.60))
		wc.rect(Rect2(vx - 4.0, c.y - 2.5, 8.0, 2.0), Color(0.80, 0.80, 0.78))
	wc.rect(Rect2(roof.position.x + 2.0, roof.position.y + 1.0, roof.size.x - 4.0, 1.6), FUNICULAR_RED)
	wc.rect(Rect2(roof.position.x + 2.0, roof.end.y - 2.6, roof.size.x - 4.0, 1.6), FUNICULAR_RED)
	# headlamps toward the way it is going, tail lamps behind
	var run := (FUNICULAR_TO - FUNICULAR_FROM) / FUNICULAR_SPEED
	var going := 1.0 if fmod(elapsed, (run + FUNICULAR_PAUSE) * 2.0) < run + FUNICULAR_PAUSE else -1.0
	for side: float in [-1.0, 1.0]:
		wc.circle(Vector2(c.x + going * (hw - 1.0), c.y + side * 9.0), 2.6, Color(1.0, 0.95, 0.70))
		wc.circle(Vector2(c.x - going * (hw - 1.0), c.y + side * 9.0), 2.2, Color(0.70, 0.12, 0.10))
	if funicular_near_crossing(elapsed):
		wc.glow(Vector2(c.x + going * (hw + 18.0), c.y), 34.0, Color(1.0, 0.95, 0.72, 0.30))


# over the pair: the needles' upper halves, standing north of their feet as
# tall things do from here, and the pines' crowns
static func draw_overhead(m: Node2D, ci: Object) -> void:
	if m.lvl != "montserrat":
		return
	var b := ShapeBatch.new()
	b.lod = true
	for i in range(SPIRES.size()):
		_draw_spire_top(b, SPIRES[i], float(i))
	for i in range(PINES.size()):
		_draw_pine_crown(b, PINES[i], float(i))
	b.flush(ci)


# an agulla: a rounded finger of conglomerate, drawn as it leans away from the
# eye: the flank with its bedding lines and pebbles, the lit dome of its top
static func _draw_spire_top(b: ShapeBatch, p: Vector2, seed_n: float) -> void:
	var top := p + Vector2(0.0, -SPIRE_LEAN)
	var rt := SPIRE_R * 0.86
	b.capsule(p, top, SPIRE_R + 1.5, ROCK_DEEP)
	b.capsule(p, top, SPIRE_R, ROCK_SHADE)
	b.quad(p + Vector2(-SPIRE_R, 0.0), p + Vector2(SPIRE_R * 0.25, 0.0), top + Vector2(rt * 0.2, 0.0), top + Vector2(-rt, 0.0), ROCK)
	b.circle(p + Vector2(-SPIRE_R * 0.38, 0.0), SPIRE_R * 0.62, ROCK)
	# the beds it is laid down in, sagging round the flank
	for i in range(4):
		var f := (float(i) + 0.6) / 4.6
		var c := p.lerp(top, f)
		var w := lerpf(SPIRE_R, rt, f) - 2.0
		b.line(c + Vector2(-w, 4.0), c + Vector2(-w * 0.3, 9.0), Color(ROCK_DEEP, 0.34), 1.6)
		b.line(c + Vector2(-w * 0.3, 9.0), c + Vector2(w, 4.0), Color(ROCK_DEEP, 0.48), 1.6)
	for i in range(9):
		var f := _h(seed_n * 3.0 + float(i))
		var c := p.lerp(top, f * 0.8)
		var at := c + Vector2((_h(seed_n + float(i) * 2.3) - 0.5) * SPIRE_R * 1.6, 6.0 + _h(float(i)) * 8.0)
		b.coarse(at + Vector2(0.6, 0.9), 2.6, Color(ROCK_DEEP, 0.5))
		b.coarse(at, 2.0 + _h(seed_n * 5.0 + float(i)) * 2.2, PEBBLES[i % 5])
	_dome(b, top, rt, seed_n * 9.0 + 3.0)
	# a tuft growing out of the top, as they do
	if int(seed_n) % 3 != 1:
		b.coarse(top + Vector2(5.0, 3.0), 5.0, SCRUB)
		b.coarse(top + Vector2(3.5, 1.5), 3.0, SCRUB.lightened(0.18))


# a mountain pine: a flat, spreading crown in clumps, the needles lit from
# the north-west
static func _draw_pine_crown(b: ShapeBatch, p: Vector2, seed_n: float) -> void:
	var r := PINE_CROWN
	b.circle(p + Vector2(2.0, 3.0), r * 0.80, Color(PINE_NEEDLE.darkened(0.42), 0.94))
	for k in range(8):
		var a := TAU * float(k) / 8.0 + seed_n * 0.7
		var lr := r * (0.50 + 0.14 * float((k + int(seed_n)) % 3))
		var lp := p + Vector2.from_angle(a) * lr
		b.circle(lp, r * 0.38, PINE_NEEDLE)
		b.circle(lp - Shade.light * (r * 0.10), r * 0.26, PINE_NEEDLE.lightened(0.10))
	for k in range(5):
		var a := TAU * float(k) / 5.0 + seed_n * 1.3
		var lp := p + Vector2.from_angle(a) * r * 0.30 - Shade.light * 4.0
		b.circle(lp, r * 0.28, PINE_NEEDLE.lightened(0.07))
		b.circle(lp - Shade.light * 3.0, r * 0.15, PINE_LIT)
	# cones
	for k in range(3):
		var a := seed_n * 2.1 + float(k) * 2.3
		b.coarse(p + Vector2.from_angle(a) * r * 0.55, 2.4, Color(0.46, 0.32, 0.20))


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


# What a dog marks on the mountain: a cairn, the stack of stones walkers
# leave to show the path, in the pink conglomerate the mountain is made of.
# Marked, the stones darken with the wet. (A town walk has a hydrant here.)
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.cast_shadow(wc, hp, 10.0, 16.0)
	var wet := 0.16 if h.done else 0.0
	var stones: Array = [
		[Vector2(0.0, 3.0), 11.0, 0.0],
		[Vector2(-1.5, -2.5), 8.0, 0.4],
		[Vector2(1.0, -6.5), 5.6, 0.8],
		[Vector2(-0.5, -9.5), 3.4, 1.3],
	]
	for st: Array in stones:
		var p: Vector2 = hp + (st[0] as Vector2)
		var r: float = float(st[1])
		var tone := ROCK.lerp(ROCK_SHADE, fmod(float(st[2]) * 0.7, 0.5))
		wc.circle(p, r + 1.2, ROCK_DEEP.darkened(wet))
		wc.circle(p, r, tone.darkened(wet))
		wc.circle(p + Vector2(-r * 0.30, -r * 0.30), r * 0.5, ROCK_LIT.darkened(wet))
	# the pebbles set in the conglomerate, on the biggest stone
	for k in range(3):
		wc.circle(hp + Vector2(-5.0 + float(k) * 4.5, 7.0 - float(k % 2) * 2.0), 1.3, PEBBLES[k % PEBBLES.size()].darkened(wet))
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 19.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# a dropped snack: a carquinyoli (the almond biscuit sold by the monastery)
# spilt from its paper bag
static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 11.0, 3.0, 0.20)
	wc.polygon(PackedVector2Array([kp + Vector2(-12, -7), kp + Vector2(0, -9), kp + Vector2(2, 5), kp + Vector2(-11, 6)]), Color(0.86, 0.80, 0.68))
	wc.line(kp + Vector2(-12, -7), kp + Vector2(0, -9), Color(0.66, 0.58, 0.46), 1.4)
	for i in range(3):
		var bp := kp + Vector2(4.0 + float(i) * 3.5, -2.0 + float(i % 2) * 5.0)
		var along := Vector2.from_angle(0.5 + float(i) * 0.9)
		wc.capsule(bp - along * 4.0, bp + along * 4.0, 2.6, Color(0.70, 0.48, 0.24))
		wc.capsule(bp - along * 3.2, bp + along * 3.2, 1.6, Color(0.86, 0.64, 0.36))
		wc.circle(bp + along * 1.0, 0.9, Color(0.96, 0.90, 0.78))
