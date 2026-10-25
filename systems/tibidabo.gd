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

const Letters := preload("res://world/sign_letters.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Arrival := preload("res://systems/arrival.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)

# --- colors ------------------------------------------------------------------
const ROAD_ASPHALT := Color(0.38, 0.37, 0.36)
const ROAD_KERB := Color(0.72, 0.70, 0.66)
const BALUSTRADE_STONE := Color(0.82, 0.80, 0.76)
const BALUSTRADE_SHADOW := Color(0.18, 0.16, 0.15, 0.55)
const PINE_NEEDLES := Color(0.24, 0.38, 0.22)
const PINE_TRUNK := Color(0.44, 0.28, 0.18)
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

const HILLSIDE := Color(0.30, 0.36, 0.24)
const CITY_HAZE := Color(0.50, 0.56, 0.62)
const CITY_BLOCK := Color(0.42, 0.47, 0.54)

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
const PRIZE_TEXT := "snatch the spun sugar stick from the fairground cart"

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
	# the drop to the city on the west, the hillside on the east
	b.rect(Rect2(-400.0, top, 760.0, bot - top), CITY_HAZE)
	var cy := floorf(bot / 90.0) * 90.0
	while cy > top - 90.0:
		var k := int(absf(cy) / 90.0)
		b.rect(Rect2(40.0 + float((k * 37) % 120), cy, 70.0 + float((k * 53) % 60), 46.0), CITY_BLOCK)
		cy -= 90.0
	b.rect(Rect2(900.0, top, 700.0, bot - top), HILLSIDE)

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
		ky -= 38.0

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

	# Aleppo pines on the hillside
	for pp: Vector2 in PINES:
		if pp.y < top - PINE_R * 2.0 or pp.y > bot + PINE_R * 2.0:
			continue
		b.circle(pp + LIGHT * 10.0, PINE_R + 4.0, SHADOW)
		b.circle(pp, 6.0, PINE_TRUNK)
		b.circle(pp + Vector2(-8.0, -6.0), PINE_R * 0.7, PINE_NEEDLES)
		b.circle(pp + Vector2(9.0, -2.0), PINE_R * 0.75, PINE_NEEDLES)
		b.circle(pp + Vector2(0.0, 8.0), PINE_R * 0.65, PINE_NEEDLES.lightened(0.08))

	# Stone cliffside balustrade on the west edge overlooking Barcelona
	var by := floorf(bot / 70.0) * 70.0 - 40.0
	while by > top - 70.0:
		var we: Vector2 = m.walk_edges(by)
		var bx: float = we.x - 8.0
		b.rect(Rect2(bx - 8.0, by, 16.0, 60.0), BALUSTRADE_STONE)
		b.circle(Vector2(bx, by + 30.0), 10.0, BALUSTRADE_STONE)
		b.circle(Vector2(bx + LIGHT.x * 3.0, by + 30.0 + LIGHT.y * 3.0), 10.0, BALUSTRADE_SHADOW)
		by -= 70.0

	# Panoramic viewfinders (coin binoculars)
	for vf: Vector2 in VIEWFINDERS:
		if vf.y < top - 20.0 or vf.y > bot + 20.0:
			continue
		b.circle(vf + LIGHT * 4.0, 14.0, SHADOW)
		b.circle(vf, 12.0, BALUSTRADE_STONE)
		b.circle(vf, 6.0, VIEWFINDER_METAL)
		b.line(vf + Vector2(-6.0, -4.0), vf + Vector2(-6.0, 6.0), VIEWFINDER_METAL, 4.0)
		b.line(vf + Vector2(6.0, -4.0), vf + Vector2(6.0, 6.0), VIEWFINDER_METAL, 4.0)
		b.circle(vf + Vector2(-6.0, -4.0), 3.0, VIEWFINDER_BRASS)
		b.circle(vf + Vector2(6.0, -4.0), 3.0, VIEWFINDER_BRASS)

	# the cotton candy cart with the prize
	if PRIZE.y > top - 30.0 and PRIZE.y < bot + 30.0:
		b.rect(Rect2(PRIZE.x - 22.0 + LIGHT.x * 4.0, PRIZE.y - 14.0 + LIGHT.y * 4.0, 44.0, 28.0), SHADOW)
		b.rect(Rect2(PRIZE.x - 20.0, PRIZE.y - 12.0, 40.0, 24.0), FUNICULAR_CREAM)
		b.rect(Rect2(PRIZE.x - 22.0, PRIZE.y - 14.0, 44.0, 6.0), Color(0.88, 0.22, 0.20))
		b.circle(PRIZE + Vector2(-6.0, -2.0), 8.0, COTTON_CANDY_PINK)
		b.circle(PRIZE + Vector2(6.0, -2.0), 8.0, COTTON_CANDY_PINK.lightened(0.12))


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
	b.rect(Rect2(plat.position + LIGHT * 5.0, plat.size), SHADOW)
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
		b.rect(Rect2(body.position + LIGHT * 6.0, body.size), SHADOW)
		b.rect(body, FUNICULAR_RED)
		b.rect(body.grow_individual(-4.0, -8.0, -4.0, -8.0), FUNICULAR_CREAM)
		for wi in range(5):
			var wy := body.position.y + 14.0 + float(wi) * 18.0
			b.rect(Rect2(body.position.x + 6.0, wy, CAR_W - 12.0, 12.0), FUNICULAR_GLASS)
	if SIGNAL_POS.y > vt - 40.0 and SIGNAL_POS.y < vb + 40.0:
		var lit := signal_lit(m)
		var alt := fmod(AnimClock.msec() / 1000.0 * 3.0, 2.0) < 1.0
		var off := Color(0.35, 0.1, 0.1)
		var on := Color(0.95, 0.2, 0.2)
		b.circle(SIGNAL_POS + LIGHT * 3.0, 8.0, SHADOW)
		b.circle(SIGNAL_POS, 7.0, Color(0.18, 0.18, 0.20))
		b.circle(SIGNAL_POS + Vector2(-4, 0), 3.0, on if lit and alt else off)
		b.circle(SIGNAL_POS + Vector2(4, 0), 3.0, on if lit and not alt else off)


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
				m.float_text(dp + Vector2(0, -30), "panorama! +5", Color(0.96, 0.86, 0.32))
				m.feed.say("BARCELONA, ALL OF IT!", EventFeed.Tone.GOOD)
				m.get_node("/root/Sfx").play("prize", 1.1)
				break
	# the funicular: at the road's east side as the carriage passes level
	if not m.tibidabo_funicular_seen:
		var cy := carriage_y(m.elapsed)
		if dp.x > WATCH_X and absf(cy - dp.y) < WATCH_DY and cy < CAR_BOTTOM_Y - WATCH_OFF_STATION:
			m.tibidabo_funicular_seen = true
			m.bones += 3
			m.float_text(dp + Vector2(0, -28), "funicular! +3", Color(0.85, 0.35, 0.32))
			m.feed.say("THE FUNICULAR GOES BY!", EventFeed.Tone.GOOD)

# main.surface_at, through walk_mod: the ground here, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1
