class_name Montserrat
extends RefCounted

# WALK 38: MONTSERRAT (The Serrated Mountain Trail & Monastery Terrace)
# A rugged mountain ascent winding among Montserrat's legendary conglomerate
# rock needle spires (agulles), pine woodlands, and ancient stone steps.
#
# Mid-way up the trail at y = -2600 lies the Sant Joan Funicular Crossing:
# railway tracks cut horizontally across the path, accompanied by crossing bells,
# flashing warning signals, and a passing red-and-cream carriage.
#
# Higher up stands the Mel i mató artisanal honey and fresh whey cheese stall
# at y = -3300, leading to the grand Romanesque arches of Plaça de Santa Maria
# and the Font del Portal fountain at the summit terrace.
#
# During the home leg, the Wild Goat Herd Leader (entities/goat_threat.gd)
# descends from the high crags, kicking rolling boulders down the trail.

const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const HALF := 260.0
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.06, 0.05, 0.08, 0.28)

# Palette
const ROCK_BASE := Color(0.72, 0.65, 0.55)
const ROCK_DARK := Color(0.55, 0.48, 0.40)
const ROCK_HIGHLIGHT := Color(0.85, 0.78, 0.68)
const TRAIL_GRAVEL := Color(0.78, 0.71, 0.60)
const TRAIL_STONE := Color(0.60, 0.54, 0.46)
const PINE_NEEDLE := Color(0.22, 0.36, 0.20)
const PINE_TRUNK := Color(0.42, 0.28, 0.18)
const MONASTERY_WALL := Color(0.80, 0.74, 0.64)
const MONASTERY_ROOF := Color(0.78, 0.35, 0.22)
const CHEESE_CREAM := Color(0.96, 0.94, 0.86)
const HONEY_GOLD := Color(0.92, 0.68, 0.18)
const FUNICULAR_RED := Color(0.82, 0.18, 0.16)
const FUNICULAR_CREAM := Color(0.94, 0.92, 0.84)
const FUNICULAR_GLASS := Color(0.55, 0.78, 0.88, 0.75)
const RAIL_STEEL := Color(0.78, 0.80, 0.84)
const RAIL_WOOD := Color(0.36, 0.26, 0.20)

# Conglomerate rock spires (round rope wrap poles)
const SPIRES: Array[Vector2] = [
	Vector2(450.0, -500.0),
	Vector2(830.0, -950.0),
	Vector2(440.0, -1400.0),
	Vector2(840.0, -1850.0),
	Vector2(430.0, -2300.0),
	Vector2(850.0, -2800.0),
	Vector2(450.0, -3250.0),
	Vector2(830.0, -3700.0),
	Vector2(440.0, -4150.0),
	Vector2(820.0, -4550.0),
]
const SPIRE_R := 28.0

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

# The Funicular Crossing
const CROSSING_Y := -2600.0
const CROSSING_TRACK_W := 56.0
const FUNICULAR_SPEED := 120.0
const FUNICULAR_CAR_W := 80.0
const FUNICULAR_CAR_H := 36.0

# Mel i Mató Stall
const CHEESE_STALL_POS := Vector2(465.0, -3300.0)
const CHEESE_STALL_RECT := Rect2(430.0, -3325.0, 70.0, 50.0)

# Summit Prize: The Jar of Mountain Honey with Fresh Mató Cheese
const PRIZE := Vector2(640.0, -4680.0)
const PRIZE_TEXT := "snatch the artisanal honey and mato cheese jar"

# Monastery Arcade Walls
const ARCADE_LEFT := Rect2(380.0, -4620.0, 90.0, 44.0)
const ARCADE_RIGHT := Rect2(810.0, -4620.0, 90.0, 44.0)

# Respite / Solid Obstacles
static func solids(_m: Node2D) -> Array[Rect2]:
	return [
		CHEESE_STALL_RECT,
		Rect2(390.0, -1920.0, 40.0, 40.0),   # Funicular left gatepost
		Rect2(850.0, -1920.0, 40.0, 40.0),   # Funicular right gatepost
		ARCADE_LEFT,
		ARCADE_RIGHT,
	]


static func wrap_rects() -> Array[Rect2]:
	return [
		CHEESE_STALL_RECT,
		Rect2(390.0, -1920.0, 40.0, 40.0),
		Rect2(850.0, -1920.0, 40.0, 40.0),
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


# Funicular carriage position at walk time
static func funicular_car_x(elapsed: float) -> float:
	# Carriage travels back and forth across track at CROSSING_Y
	var cycle: float = fmod(elapsed * FUNICULAR_SPEED, 1600.0)
	if cycle < 800.0:
		return 240.0 + cycle
	return 1040.0 - (cycle - 800.0)


static func funicular_near_crossing(elapsed: float) -> bool:
	var cx := funicular_car_x(elapsed)
	return cx > 480.0 and cx < 800.0


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "montserrat":
		return
	var dp: Vector2 = m.dog.global_position

	# Funicular crossing state machine
	var cur_state: String = String(m.montserrat_funicular.get("state", "waiting"))
	var car_x := funicular_car_x(m.elapsed)
	var near := funicular_near_crossing(m.elapsed)

	if cur_state == "waiting":
		if near:
			m.montserrat_funicular["state"] = "crossing"
			m.montserrat_funicular["t"] = 0.0
			m.get_node("/root/Sfx").play("crossing_bell", 1.0)
	elif cur_state == "crossing":
		var t: float = float(m.montserrat_funicular.get("t", 0.0)) + delta
		m.montserrat_funicular["t"] = t
		if not near:
			m.montserrat_funicular["state"] = "waiting"
			# Award dodge if pair made it past crossing without getting clipped
			if not m.montserrat_funicular_dodged and dp.y < CROSSING_Y - 80.0:
				m.montserrat_funicular_dodged = true
				m.bones += 3
				m.float_text(dp + Vector2(0, -30), "funicular cleared! +3", Color(0.96, 0.86, 0.32))
				m.feed.say("CLEAR OF THE FUNICULAR!", EventFeed.Tone.GOOD)

	# Funicular carriage collision with dog / human
	if absf(dp.y - CROSSING_Y) < 28.0 and absf(dp.x - car_x) < FUNICULAR_CAR_W * 0.5:
		if m.dog.has_method("knocked"):
			m.dog.knocked(Vector2(signf(dp.x - car_x), 0.0), "funicular")
		m.feed.say("MIND THE FUNICULAR!", EventFeed.Tone.LOUD)


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


static func draw_scenery(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "montserrat":
		return
	var top: float = maxf(vt, m.GATE_Y - 80.0)
	var bot: float = minf(vb, m.START_Y + 400.0)
	if bot <= top:
		return

	var b: ShapeBatch = wc

	# Mountain trail bedrock and gravel
	b.rect(Rect2(360.0, top, 560.0, bot - top), ROCK_BASE)
	var ty := floorf(bot / 50.0) * 50.0
	while ty > top - 50.0:
		var k := int(absf(ty) / 50.0)
		var step_x := 390.0 + float((k * 43) % 480)
		b.rect(Rect2(step_x, ty, 65.0, 14.0), TRAIL_STONE)
		ty -= 50.0

	# Funicular railway crossing tracks at y = -2600
	if CROSSING_Y > top - 50.0 and CROSSING_Y < bot + 50.0:
		# Track ballast
		b.rect(Rect2(340.0, CROSSING_Y - 24.0, 600.0, 48.0), ROCK_DARK)
		# Sleepers
		var sx := 350.0
		while sx < 930.0:
			b.rect(Rect2(sx, CROSSING_Y - 20.0, 10.0, 40.0), RAIL_WOOD)
			sx += 26.0
		# Steel rails
		b.line(Vector2(340.0, CROSSING_Y - 12.0), Vector2(940.0, CROSSING_Y - 12.0), RAIL_STEEL, 4.0)
		b.line(Vector2(340.0, CROSSING_Y + 12.0), Vector2(940.0, CROSSING_Y + 12.0), RAIL_STEEL, 4.0)

		# Crossing signal posts on sides
		for sig_x: float in [400.0, 880.0]:
			b.circle(Vector2(sig_x, CROSSING_Y - 32.0), 7.0, Color(0.2, 0.2, 0.2))
			var lit := funicular_near_crossing(m.elapsed)
			var blink := fmod(AnimClock.msec() / 250.0, 2.0) < 1.0
			b.circle(Vector2(sig_x, CROSSING_Y - 32.0), 4.0, Color(0.95, 0.2, 0.2) if (lit and blink) else Color(0.4, 0.1, 0.1))

	# Mel i mató Cheese Stall at y = -3300
	if CHEESE_STALL_RECT.position.y > top - 80.0 and CHEESE_STALL_RECT.position.y < bot + 80.0:
		var sr := CHEESE_STALL_RECT
		b.rect(Rect2(sr.position + LIGHT * 6.0, sr.size), SHADOW)
		b.rect(sr, PINE_TRUNK)
		# Striped fabric awning
		for si in range(6):
			var col := HONEY_GOLD if si % 2 == 0 else CHEESE_CREAM
			b.rect(Rect2(sr.position.x + float(si) * 11.5, sr.position.y, 11.5, 14.0), col)
		# Cheese rounds and honey pots on counter
		b.circle(Vector2(sr.position.x + 20.0, sr.position.y + 26.0), 8.0, CHEESE_CREAM)
		b.circle(Vector2(sr.position.x + 40.0, sr.position.y + 26.0), 7.0, HONEY_GOLD)
		b.circle(Vector2(sr.position.x + 55.0, sr.position.y + 26.0), 6.0, Color(0.70, 0.35, 0.15)) # clay pot

	# Conglomerate rock spires
	for sp: Vector2 in SPIRES:
		if sp.y < top - SPIRE_R * 2.0 or sp.y > bot + SPIRE_R * 2.0:
			continue
		b.circle(sp + LIGHT * 12.0, SPIRE_R + 6.0, SHADOW)
		b.circle(sp, SPIRE_R, ROCK_BASE)
		b.circle(sp + LIGHT * 4.0, SPIRE_R * 0.8, ROCK_HIGHLIGHT)
		b.circle(sp - LIGHT * 5.0, SPIRE_R * 0.6, ROCK_DARK)

	# Mountain pines
	for pn: Vector2 in PINES:
		if pn.y < top - PINE_R * 2.0 or pn.y > bot + PINE_R * 2.0:
			continue
		b.circle(pn + LIGHT * 10.0, PINE_R + 4.0, SHADOW)
		b.circle(pn, 6.0, PINE_TRUNK)
		b.circle(pn + Vector2(-6.0, -4.0), PINE_R * 0.7, PINE_NEEDLE)
		b.circle(pn + Vector2(7.0, -2.0), PINE_R * 0.75, PINE_NEEDLE)
		b.circle(pn + Vector2(0.0, 6.0), PINE_R * 0.65, PINE_NEEDLE.lightened(0.08))

	# Monastery Terrace Romanesque Arches (y = -4600)
	for arc: Rect2 in [ARCADE_LEFT, ARCADE_RIGHT]:
		if arc.position.y > top - 50.0 and arc.position.y < bot + 50.0:
			b.rect(Rect2(arc.position + LIGHT * 5.0, arc.size), SHADOW)
			b.rect(arc, MONASTERY_WALL)
			b.rect(Rect2(arc.position.x, arc.position.y, arc.size.x, 8.0), MONASTERY_ROOF)
			# Arches
			for ai in range(3):
				var ax := arc.position.x + 15.0 + float(ai) * 26.0
				b.circle(Vector2(ax, arc.position.y + 24.0), 8.0, Color(0.2, 0.18, 0.16))

	# Prize: Honey and Mató Cheese Jar
	if PRIZE.y > top - 30.0 and PRIZE.y < bot + 30.0:
		b.circle(PRIZE + LIGHT * 4.0, 14.0, SHADOW)
		b.circle(PRIZE, 12.0, CHEESE_CREAM)
		b.circle(PRIZE + Vector2(0, -2.0), 9.0, HONEY_GOLD)
		b.circle(PRIZE + Vector2(0, -6.0), 4.0, Color(0.85, 0.2, 0.2)) # ribbon knot


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "montserrat":
		return
	# Draw moving funicular carriage
	if CROSSING_Y > vt - 50.0 and CROSSING_Y < vb + 50.0:
		var car_x := funicular_car_x(m.elapsed)
		var r := Rect2(car_x - FUNICULAR_CAR_W * 0.5, CROSSING_Y - FUNICULAR_CAR_H * 0.5, FUNICULAR_CAR_W, FUNICULAR_CAR_H)
		wc.rect(Rect2(r.position + LIGHT * 5.0, r.size), SHADOW)
		wc.rect(r, FUNICULAR_RED)
		wc.rect(r.grow_individual(-4.0, -4.0, -4.0, -4.0), FUNICULAR_CREAM)
		for wi in range(4):
			var wx := r.position.x + 8.0 + float(wi) * 18.0
			wc.rect(Rect2(wx, r.position.y + 6.0, 14.0, FUNICULAR_CAR_H - 12.0), FUNICULAR_GLASS)


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "montserrat":
		return
	# Pine canopy overhang near trail edges
	var b := ShapeBatch.new(ci)
	for pn: Vector2 in PINES:
		b.circle(pn + Vector2(0.0, -10.0), PINE_R * 0.9, Color(PINE_NEEDLE.r, PINE_NEEDLE.g, PINE_NEEDLE.b, 0.65))
	b.flush()


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1
