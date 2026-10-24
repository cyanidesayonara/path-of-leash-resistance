class_name Tibidabo
extends RefCounted

# WALK 21: EL TIBIDABO (The Mountain Funicular & Fairground Overlook)
# Winding scenic mountain highway ascending Mount Tibidabo high above Barcelona,
# flanked by a stone cliffside balustrade overlooking the skyline and sea on the
# west, and the historic Funicular tracks (Cuca de Llum) climbing alongside the
# pine-covered hillside on the east.
#
# Features:
# - Historic funicular railway track running along the eastern flank with passing
#   vintage funicular train carriage (red/cream livery, panoramic glass).
#   Level crossing with clanging bell and flashing crossing signals at CROSSING_Y.
# - Vintage coin-operated panoramic binoculars (viewfinders) mounted on stone plinths
#   along the cliffside balustrade ("PANORAMA! +5").
# - Fairground summit with candy floss / churros stalls, festive pennant bunting,
#   and fairground treats.
# - Golden bone prize on the vintage carousel food cart.

const Letters := preload("res://world/sign_letters.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

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

# --- track and crossing layout ------------------------------------------------
const TRACK_X := 880.0
const TRACK_W := 60.0
const CROSSING_Y := -2400.0
const CROSSING_H := 80.0

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

	# Mountain Aleppo pines along the slopes and balustrade posts
	for y: float in [-600.0, -1200.0, -1800.0, -2600.0, -3200.0, -3800.0, -4400.0]:
		m.poles.append(Vector2(930.0, y))
		m.rope_radii.append(16.0)

	# Viewfinders (solid pedestals the leash can wrap)
	for vf: Vector2 in VIEWFINDERS:
		m.poles.append(vf)
		m.rope_radii.append(12.0)

	# Sniffable landmarks (hiking waymarkers & mountain lookout posts)
	var marks: Array[Vector2] = [
		VIEWFINDERS[0],
		VIEWFINDERS[1],
		VIEWFINDERS[2],
		Vector2(840.0, CROSSING_Y - 50.0), # Crossing bell post
		Vector2(490.0, -4600.0),            # Fairground cart
	]

	# Snacks: dropped churros and cotton candy bites
	var snacks: Array[Vector2] = [
		Vector2(470.0, -1350.0),
		Vector2(550.0, -2350.0),
		Vector2(430.0, -3150.0),
		Vector2(580.0, -4250.0),
	]

	return [marks, snacks]


static func draw_edge_layer(m: Node2D, b: ShapeBatch, _vt: float = 0.0, _vb: float = 0.0) -> void:
	if m.lvl != "tibidabo":
		return

	# Roadway asphalt base
	b.rect(Rect2(360.0, -4850.0, 560.0, 5250.0), ROAD_ASPHALT)

	# Funicular track bed ballast on the east flank
	b.rect(Rect2(TRACK_X - TRACK_W * 0.5, -4850.0, TRACK_W, 5250.0), TRACK_BALLAST)

	# Wooden track sleepers
	var sy := -50.0
	while sy > -4800.0:
		b.rect(Rect2(TRACK_X - 26.0, sy - 3.0, 52.0, 6.0), TRACK_SLEEPER)
		sy -= 22.0

	# Steel track rails
	b.line(Vector2(TRACK_X - 18.0, 200.0), Vector2(TRACK_X - 18.0, -4850.0), TRACK_RAIL, 4.0)
	b.line(Vector2(TRACK_X + 18.0, 200.0), Vector2(TRACK_X + 18.0, -4850.0), TRACK_RAIL, 4.0)
	# Central traction steel cable
	b.line(Vector2(TRACK_X, 200.0), Vector2(TRACK_X, -4850.0), TRACK_CABLE, 2.0)

	# Mountain road yellow dividing dashed center line
	var ly := -20.0
	while ly > -4800.0:
		if absf(ly - CROSSING_Y) > 60.0:
			var e_dash: Vector2 = m.walk_edges(ly)
			var c_dash := (e_dash.x + e_dash.y) * 0.5
			b.line(Vector2(c_dash, ly), Vector2(c_dash, ly - 32.0), Color(0.92, 0.78, 0.25), 3.0)
		ly -= 64.0

	# Road asphalt kerbs following the mountain corridor
	var ky := 200.0
	while ky > -4800.0:
		var ke: Vector2 = m.walk_edges(ky)
		b.line(Vector2(ke.x, ky), Vector2(ke.x, ky - 40.0), ROAD_KERB, 5.0)
		b.line(Vector2(ke.y, ky), Vector2(ke.y, ky - 40.0), ROAD_KERB, 5.0)
		ky -= 38.0

	# Level crossing asphalt ramp and white warning crosshatching
	b.rect(Rect2(TRACK_X - TRACK_W * 0.5, CROSSING_Y - CROSSING_H * 0.5, TRACK_W, CROSSING_H), ROAD_ASPHALT)
	for i in range(4):
		var cy := CROSSING_Y - 30.0 + float(i) * 20.0
		b.line(Vector2(TRACK_X - 24.0, cy), Vector2(TRACK_X + 24.0, cy), Color(0.95, 0.95, 0.90), 3.5)

	# Stone cliffside balustrade on the west edge overlooking Barcelona
	var by := -40.0
	while by > -4800.0:
		var we: Vector2 = m.walk_edges(by)
		var bx: float = we.x - 8.0
		b.rect(Rect2(bx - 8.0, by, 16.0, 60.0), BALUSTRADE_STONE)
		b.circle(Vector2(bx, by + 30.0), 10.0, BALUSTRADE_STONE)
		b.circle(Vector2(bx + LIGHT.x * 3.0, by + 30.0 + LIGHT.y * 3.0), 10.0, BALUSTRADE_SHADOW)
		by -= 70.0

	# Funicular carriage (Cuca de Llum) moving along the track
	var t: float = AnimClock.msec() / 1000.0
	# Cycle period 24 seconds: ascending from y = 100 down to y = -4700
	var cycle := fmod(t, 24.0) / 24.0
	var car_y := lerpf(100.0, -4700.0, cycle)
	var car_w := 38.0
	var car_l := 110.0
	var car_pos := Vector2(TRACK_X, car_y)

	# Carriage shadow and body
	b.rect(Rect2(car_pos.x - car_w * 0.5 + LIGHT.x * 6.0, car_pos.y - car_l * 0.5 + LIGHT.y * 6.0, car_w, car_l), SHADOW)
	b.rect(Rect2(car_pos.x - car_w * 0.5, car_pos.y - car_l * 0.5, car_w, car_l), FUNICULAR_RED)
	b.rect(Rect2(car_pos.x - car_w * 0.5 + 4.0, car_pos.y - car_l * 0.5 + 8.0, car_w - 8.0, car_l - 16.0), FUNICULAR_CREAM)
	# Panoramic glass windows
	for wi in range(5):
		var wy := car_pos.y - car_l * 0.5 + 14.0 + float(wi) * 18.0
		b.rect(Rect2(car_pos.x - car_w * 0.5 + 6.0, wy, car_w - 12.0, 12.0), FUNICULAR_GLASS)

	# Panoramic viewfinders (coin binoculars)
	for vf: Vector2 in VIEWFINDERS:
		# Stone circular pedestal
		b.circle(vf + LIGHT * 4.0, 14.0, SHADOW)
		b.circle(vf, 12.0, BALUSTRADE_STONE)
		# Twin binocular barrels and brass eye pieces
		b.circle(vf, 6.0, VIEWFINDER_METAL)
		b.line(vf + Vector2(-6.0, -4.0), vf + Vector2(-6.0, 6.0), VIEWFINDER_METAL, 4.0)
		b.line(vf + Vector2(6.0, -4.0), vf + Vector2(6.0, 6.0), VIEWFINDER_METAL, 4.0)
		b.circle(vf + Vector2(-6.0, -4.0), 3.0, VIEWFINDER_BRASS)
		b.circle(vf + Vector2(6.0, -4.0), 3.0, VIEWFINDER_BRASS)

	# Crossing warning signal lights at CROSSING_Y
	var blink := fmod(t * 3.0, 2.0) < 1.0
	var sig_pos := Vector2(TRACK_X - 35.0, CROSSING_Y - 45.0)
	b.circle(sig_pos + LIGHT * 3.0, 8.0, SHADOW)
	b.circle(sig_pos, 7.0, Color(0.18, 0.18, 0.20))
	b.circle(sig_pos + Vector2(-4, 0), 3.0, Color(0.95, 0.2, 0.2) if blink else Color(0.35, 0.1, 0.1))
	b.circle(sig_pos + Vector2(4, 0), 3.0, Color(0.35, 0.1, 0.1) if blink else Color(0.95, 0.2, 0.2))

	# Fairground candy cart and prize (cotton candy stick)
	b.rect(Rect2(PRIZE.x - 22.0 + LIGHT.x * 4.0, PRIZE.y - 14.0 + LIGHT.y * 4.0, 44.0, 28.0), SHADOW)
	b.rect(Rect2(PRIZE.x - 20.0, PRIZE.y - 12.0, 40.0, 24.0), FUNICULAR_CREAM)
	b.rect(Rect2(PRIZE.x - 22.0, PRIZE.y - 14.0, 44.0, 6.0), Color(0.88, 0.22, 0.20))
	# Cotton candy clouds
	b.circle(PRIZE + Vector2(-6.0, -2.0), 8.0, COTTON_CANDY_PINK)
	b.circle(PRIZE + Vector2(6.0, -2.0), 8.0, COTTON_CANDY_PINK.lightened(0.12))


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "tibidabo":
		return
	# Festive pennant bunting strung between poles near the fairground summit
	var t: float = AnimClock.msec() / 1000.0
	for y: float in [-4100.0, -4350.0, -4600.0]:
		var p1 := Vector2(410.0, y)
		var p2 := Vector2(850.0, y)
		ci.draw_line(p1, p2, Color(0.30, 0.28, 0.26), 1.5)
		for i in range(12):
			var frac := float(i) / 11.0
			var bx := lerpf(p1.x, p2.x, frac)
			var sag := sin(frac * PI) * 14.0 + sin(t * 2.0 + float(i)) * 2.0
			var by := y + sag
			var col: Color = BUNTING_COLORS[i % BUNTING_COLORS.size()]
			var pts := PackedVector2Array([
				Vector2(bx - 6.0, by),
				Vector2(bx + 6.0, by),
				Vector2(bx, by + 12.0)
			])
			ci.draw_colored_polygon(pts, col)


static func update_tibidabo(m: Node2D, _delta: float) -> void:
	if m.lvl != "tibidabo":
		return

	# Viewfinder interaction: stepping up to any panoramic binoculars
	if not m.tibidabo_viewfinder_gazed:
		for vf: Vector2 in VIEWFINDERS:
			if m.dog.global_position.distance_to(vf) < 36.0:
				if m.dog.velocity.length() < 20.0:
					m.tibidabo_viewfinder_gazed = true
					m.bones += 5
					m.combo.add("PANORAMA", 4)
					m.float_text(m.dog.global_position + Vector2(0, -30), "PANORAMA! +5", Color(0.96, 0.86, 0.32))
					m.feed.say("BARCELONA PANORAMA!", EventFeed.Tone.GOOD)
					Sfx.play("prize", 1.1)
					break

	# Funicular crossing check: watching the carriage pass near the crossing
	if not m.tibidabo_funicular_seen:
		var t: float = AnimClock.msec() / 1000.0
		var cycle := fmod(t, 24.0) / 24.0
		var car_y := lerpf(100.0, -4700.0, cycle)
		if absf(car_y - m.dog.global_position.y) < 120.0 and m.dog.global_position.x > 680.0:
			m.tibidabo_funicular_seen = true
			m.bones += 3
			m.float_text(m.dog.global_position + Vector2(0, -28), "CUCA DE LLUM! +3", Color(0.85, 0.35, 0.32))
			m.feed.say("FUNICULAR DE TIBIDABO!", EventFeed.Tone.GOOD)
