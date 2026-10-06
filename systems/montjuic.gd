class_name Montjuic
extends RefCounted

const EventFeed := preload("res://hud/event_feed.gd")

# MONTJUÏC, the climb (La Pujada). A top-down view has no up, so the climb is
# sold by everything round it at once:
# - the path winds left and right up the hill (the walk's edge_nodes);
# - terraces: stone retaining walls across the hillside, each casting its
#   shadow down onto the one below, with a short flight of steps where the
#   path cuts through, handrail posts the rope can catch on;
# - the hill narrows as it rises and the city falls away past its rim, the
#   rooftops smaller and hazier the higher she gets, the port and the sea
#   opening up near the top;
# - effort: your human slows on the way up (a dog leading on the leash helps,
#   through the leash conversation's give) and speeds up on the way home;
# - stone posts give the height in metres;
# - wind that rises with the climb, in gusts, each one telegraphed by leaves
#   streaking past and a whoosh before it shoves;
# - the outdoor escalators up the last straight to the castle, stone stairs
#   either side: your human rides, the dog races them or rides along, and
#   going home the up escalator is the cheeky way down;
# - the Font Màgica at the foot of the hill: a great basin beside the path
#   whose jets rise into a show every few seconds. It is water, so she can get
#   in; in during the show, once a walk, is a treat;
# - the cactus garden on a terrace beside the path: the cacti are posts the
#   leash wraps, running into one at speed is a prick and a bounce, and a
#   careful, still sniff at the great barrel cactus is a sniff worth having;
# - el trenet, the tourist road train, crossing the path on the hill road: it
#   rings its bell and the crossing lights flash before it gets there, and a
#   human it catches goes over like one a bike catches;
# - and at the top, off the leash: the castle's esplanade, gravel inside low
#   parapets with old cannons on them, the bastioned walls beyond, the sea past
#   the west parapet, and kites riding the wind over it all (the plaça's
#   mechanics, the castle's look).
# Static functions over main's state, like the other systems.

const TOP_M := 173.0              # the castle's height, near enough
const UPHILL := 0.72              # your human's pace on the climb
const DOWNHILL := 1.22            # ...and on the way back down
const STEPS_SLOW := 0.82          # on a flight of steps, going up
const DOG_SLOPE := 0.5            # the dog feels half of it
const TERRACE_STEP := 300.0       # a retaining wall every this far up
const STEP_H := 34.0              # the flight of steps where the path cuts a wall
const HILL_BOTTOM := 820.0        # the hill's half-width at the foot...
const HILL_TOP := 400.0           # ...and at the top
const GUST_WARN := 0.8            # the telegraph, as every hazard has
const GUST_S := 0.9
const GUST_FORCE := 300.0         # px/s/s on the dog at the top
const GUST_EVERY := Vector2(6.0, 11.0)
# once a walk, a gust this far up the climb takes your human's sunhat, and
# sends it off downwind at HAT_SPEED
const HAT_CLIMB := 0.4
const HAT_SPEED := 300.0
const Sunhat := preload("res://entities/sunhat.gd")
# the escalators: up the middle of the last straight (x 640 from y -4600 to the
# gate), clear of the last terrace's steps; main's conveyor carries on them
const ESC_BOTTOM := -4560.0
const ESC_TOP := -4900.0
const ESC_W := 120.0
const ESC_TREAD := 14.0
# the Font Màgica, at the foot of the hill east of the path, and its show:
# calm, the jets rising, the full show in waves, falling, calm again
const FONT := Rect2(870.0, -240.0, 230.0, 170.0)
const SHOW_PERIOD := 16.0
const SHOW_RISE := Vector2(5.0, 7.0)      # from, to (seconds into the period)
const SHOW_FALL := Vector2(12.0, 14.0)
# the cactus garden: its gravel bed, right of the path below the -2100 wall,
# clear of the telefèric's pylons; the cacti in it (the first is the great
# barrel cactus); how fast a run into one pricks, and the sniff it rewards
const CACTUS_BED := Rect2(720.0, -2060.0, 200.0, 205.0)
const CACTI: Array[Vector2] = [Vector2(820.0, -1960.0), Vector2(760.0, -2010.0), Vector2(880.0, -2020.0),
	Vector2(755.0, -1895.0), Vector2(890.0, -1890.0)]
const PRICK_R := 24.0
const PRICK_SPEED := 130.0
const PRICK_BOUNCE := 260.0
const CACTUS_SNIFF_S := 1.4
# the road train: the road it crosses on, how near the pair must be before it
# runs, how often, and how long before it reaches the path it rings
const TRAIN_Y := -2850.0
const TRAIN_NEAR := 800.0
const TRAIN_EVERY := Vector2(14.0, 20.0)
const TRAIN_WARN := 1.4
const RoadTrain := preload("res://entities/road_train.gd")


static func is_on(m: Node2D) -> bool:
	return m.lvl == "montjuic"


# 0 at the foot of the hill, 1 at the castle gate
static func climb(m: Node2D, y: float) -> float:
	return clampf((m.START_Y - y) / (m.START_Y - m.GATE_Y), 0.0, 1.0)


static func hill_half(m: Node2D, y: float) -> float:
	return lerpf(HILL_BOTTOM, HILL_TOP, climb(m, y))


static func terrace_ys(m: Node2D) -> Array[float]:
	var out: Array[float] = []
	var y: float = m.START_Y - 260.0
	while y > m.GATE_Y + 200.0:
		out.append(y)
		y -= TERRACE_STEP
	return out


static func on_steps(m: Node2D, y: float) -> bool:
	var k := roundf((m.START_Y - 260.0 - y) / TERRACE_STEP)
	var wy: float = m.START_Y - 260.0 - k * TERRACE_STEP
	return y <= wy + 6.0 and y >= wy - STEP_H - 6.0


# Pace on the slope: uphill out, downhill home, slower again on the steps.
# Exactly 1.0 on every other walk.
static func slope_mult(m: Node2D, y: float, fwd_y: float) -> float:
	if not is_on(m) or y > m.START_Y or y < m.GATE_Y:
		return 1.0
	if fwd_y < 0.0:
		return UPHILL * (STEPS_SLOW if on_steps(m, y) else 1.0)
	return DOWNHILL


static func dog_slope_mult(m: Node2D, y: float, vel_y: float) -> float:
	if not is_on(m) or absf(vel_y) < 20.0:
		return 1.0
	return lerpf(1.0, slope_mult(m, y, signf(vel_y)), DOG_SLOPE)


# --- the build -----------------------------------------------------------------

# The path, winding up: each turn as sharp as level_check allows (a peak
# slope under 0.85 through the smoothstep), half the width of a park path.
static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 200.0},
		{"y": -500.0, "cx": 430.0, "half": 175.0},
		{"y": -1350.0, "cx": 850.0, "half": 170.0},
		{"y": -2200.0, "cx": 430.0, "half": 165.0},
		{"y": -3050.0, "cx": 850.0, "half": 165.0},
		{"y": -3900.0, "cx": 430.0, "half": 170.0},
		{"y": -4600.0, "cx": 640.0, "half": 190.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 200.0},
	]


static func build(m: Node2D) -> Array:
	m.gate_text = "EL CASTELL"
	# Aleppo pines along the path's edges (the rope wraps them), in the 300..980
	# authored space the corridor fit maps onto the bends
	var y := -380.0
	var side := 0
	while y > m.GATE_Y + 260.0:
		if not on_steps(m, y):
			m.poles.append(Vector2(300.0 if side % 2 == 0 else 980.0, y))
		y -= 230.0
		side += 1
	# the handrails up each flight of steps: a post each side, top and bottom
	for wy: float in terrace_ys(m):
		for px: float in [300.0, 980.0]:
			m.poles.append(Vector2(px, wy - STEP_H - 2.0))
	m.deco_pole_count = m.poles.size()
	m.bins = Array([Vector2(m.sw_l + 30, -700), Vector2(m.sw_r - 30, -2900), Vector2(m.sw_l + 30, -4400)],
		TYPE_VECTOR2, &"", null)
	# benches where the view is, on the outside of the bends
	m.benches = Array([Vector2(960, -1350), Vector2(320, -2200), Vector2(960, -3050)], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([Vector2(700, -1700), Vector2(560, -3500)], TYPE_VECTOR2, &"", null)
	# a drinking fountain at the halfway viewpoint, as the hill's paths have
	m.fountains = Array([Vector2(m.sw_r - 50, -2650)], TYPE_VECTOR2, &"", null)
	# the escalators, carrying up (main's conveyor, as L'Estacio's walkway)
	m.conveyor_zone = Rect2(640.0 - ESC_W * 0.5, ESC_TOP, ESC_W, ESC_BOTTOM - ESC_TOP)
	m.conveyor_dir = Vector2(0, -1)
	# waymarker posts where hydrants stand in town
	return [
		Vector2(m.sw_l + 45, -900), Vector2(m.sw_r - 45, -1900), Vector2(m.sw_l + 45, -3300),
		Vector2(m.sw_r - 45, -4300),
	]


# --- the wind -------------------------------------------------------------------

# How high the show is now, 0 calm to 1 at its height, on the walk's clock.
static func show_level(m: Node2D) -> float:
	var t := fmod(float(m.elapsed), SHOW_PERIOD)
	if t < SHOW_RISE.x or t > SHOW_FALL.y:
		return 0.0
	if t < SHOW_RISE.y:
		return smoothstep(SHOW_RISE.x, SHOW_RISE.y, t)
	if t > SHOW_FALL.x:
		return 1.0 - smoothstep(SHOW_FALL.x, SHOW_FALL.y, t)
	return 1.0


# In the fountain while the show is on: once a walk, a treat.
static func tick_font(m: Node2D) -> void:
	if m.has_meta("font_show_done") or m.auto_walk:
		return
	if FONT.grow(-8.0).has_point(m.dog.global_position) and show_level(m) > 0.6:
		m.set_meta("font_show_done", true)
		m.bones += 5
		m.combo.add("SHOW", 4)
		m.feed.say("THE MAGIC FOUNTAIN!", EventFeed.Tone.GOOD)
		m.float_text(m.dog.global_position + Vector2(0, -30), "in the show! +5", Color(0.75, 0.9, 1.0))


# The cacti: a prick for a dog who runs into one, and a careful sniff at the
# great barrel cactus for one who stands still beside it.
static func tick_cacti(m: Node2D, delta: float) -> void:
	var dp: Vector2 = m.dog.global_position
	if not CACTUS_BED.grow(60.0).has_point(dp):
		return
	var cool: float = float(m.get_meta("cactus_cool", 0.0)) - delta
	m.set_meta("cactus_cool", cool)
	for c: Vector2 in CACTI:
		if cool <= 0.0 and dp.distance_to(c) < PRICK_R and m.dog.velocity.length() > PRICK_SPEED:
			m.set_meta("cactus_cool", 1.2)
			m.dog.velocity = (dp - c).normalized() * PRICK_BOUNCE
			m.combo.bail()
			Sfx.play("grunt", 1.6, -4.0)
			m.feed.say("OW! CACTUS", EventFeed.Tone.BAD)
			m.float_text(dp + Vector2(0, -28), "prickly", Color(1, 0.8, 0.7))
			return
	if m.has_meta("cactus_sniffed"):
		return
	if dp.distance_to(CACTI[0]) < 52.0 and m.dog.velocity.length() < 30.0:
		var t: float = float(m.get_meta("cactus_sniff_t", 0.0)) + delta
		m.set_meta("cactus_sniff_t", t)
		if t >= CACTUS_SNIFF_S:
			m.set_meta("cactus_sniffed", true)
			m.sniffs_done += 1
			m.bones += 4
			m.combo.add("CAREFUL", 3)
			Sfx.play("mark", 1.1)
			m.float_text(CACTI[0] + Vector2(0, -40), "a very careful sniff +4", Color(0.85, 1.0, 0.7))
			m._update_hud()
	else:
		m.set_meta("cactus_sniff_t", 0.0)


# The road train: one at a time, while the pair is near the road, on its own
# seeded clock; the bell and the crossing lights before it reaches the path.
static func tick_train(m: Node2D, delta: float) -> void:
	var near := absf(m.dog.global_position.y - TRAIN_Y) < TRAIN_NEAR
	# (a meta set to null is erased, and get_meta's null default means none)
	# a freed train cannot even be assigned to a typed variable: check it first
	# (and a freed one compares equal to null, so is_instance_valid alone decides)
	var held: Variant = m.get_meta("train") if m.has_meta("train") else null
	var train: Node2D = null
	if is_instance_valid(held):
		train = held
	elif m.has_meta("train"):
		m.remove_meta("train")
	m.set_meta("train_warn", maxf(0.0, float(m.get_meta("train_warn", 0.0)) - delta))
	if train == null:
		if not near:
			return
		if not m.has_meta("train_rng"):
			var rng := RandomNumberGenerator.new()
			rng.seed = 0x7E4E
			m.set_meta("train_rng", rng)
			m.set_meta("train_next", rng.randf_range(2.0, 5.0))
			m.set_meta("train_dir", 1.0)
		var next: float = float(m.get_meta("train_next")) - delta
		m.set_meta("train_next", next)
		if next > 0.0:
			return
		var going: float = m.get_meta("train_dir")
		m.set_meta("train_dir", -going)
		var rng2: RandomNumberGenerator = m.get_meta("train_rng")
		m.set_meta("train_next", rng2.randf_range(TRAIN_EVERY.x, TRAIN_EVERY.y))
		var tr := Node2D.new()
		tr.set_script(RoadTrain)
		tr.position = Vector2(-180.0 if going > 0.0 else 1460.0, TRAIN_Y)
		m.add_child(tr)
		tr.setup(m, going)
		m.set_meta("train", tr)
		m.set_meta("train_rang", false)
		return
	# the bell, once, as the nose comes within TRAIN_WARN of the path
	var e: Vector2 = m.walk_edges(TRAIN_Y)
	var edge: float = e.x - 12.0 if train.dir > 0.0 else e.y + 12.0
	var eta: float = (edge - train.nose_x()) / (train.dir * RoadTrain.SPEED)
	if not bool(m.get_meta("train_rang")) and eta < TRAIN_WARN:
		m.set_meta("train_rang", true)
		m.set_meta("train_warn", TRAIN_WARN + train.length() / RoadTrain.SPEED + (e.y - e.x) / RoadTrain.SPEED)
		Sfx.play("pickup", 1.6, -4.0)
		if near:
			m.float_text(Vector2(edge, TRAIN_Y - 40.0), "ding ding!", Color(1, 0.95, 0.75), m.POP_SAY)


static func is_cactus(p: Vector2) -> bool:
	for c: Vector2 in CACTI:
		if c.distance_squared_to(p) < 1.0:
			return true
	return false


static func tick_wind(m: Node2D, delta: float) -> void:
	if not is_on(m) or m.phase == "freedom" or m.frozen:
		return
	tick_font(m)
	tick_train(m, delta)
	if not m.auto_walk:
		tick_cacti(m, delta)
	if m.wind_rng_seeded == false:
		m.wind_rng.seed = 0x4D4A
		m.wind_rng_seeded = true
		m.wind_next = m.wind_rng.randf_range(GUST_EVERY.x, GUST_EVERY.y)
	var h := climb(m, m.dog.global_position.y)
	if m.wind_gust > 0.0:
		m.wind_gust -= delta
		var f := 0.3 + 0.7 * h
		var swell := sin(PI * clampf(1.0 - m.wind_gust / GUST_S, 0.0, 1.0))
		m.dog.velocity += m.wind_dir * GUST_FORCE * f * swell * delta
		m.human.velocity += m.wind_dir * GUST_FORCE * 0.3 * f * swell * delta
		return
	if m.wind_warn > 0.0:
		m.wind_warn -= delta
		if m.wind_warn <= 0.0:
			m.wind_gust = GUST_S
			if h > HAT_CLIMB and not m.auto_walk:
				blow_hat(m)
		return
	m.wind_next -= delta
	if m.wind_next <= 0.0 and h > 0.12:
		m.wind_warn = GUST_WARN
		m.wind_next = m.wind_rng.randf_range(GUST_EVERY.x, GUST_EVERY.y) * lerpf(1.3, 0.75, h)
		# off the sea, mostly: from one side, a little down the hill
		var s := -1.0 if m.wind_rng.randf() < 0.65 else 1.0
		m.wind_dir = Vector2(s, m.wind_rng.randf_range(0.0, 0.35)).normalized()
		Sfx.play("hiss", 0.45, -8.0)
		m.float_text(m.dog.global_position + Vector2(-s * 60.0, -30.0), "whoooosh", Color(0.92, 0.95, 1.0))


# The gust takes your human's sunhat: once a walk, and never while they are
# down. It goes off downwind (entities/sunhat.gd); main.on_hat_returned is
# her bringing it back.
static func blow_hat(m: Node2D) -> bool:
	if m.has_meta("hat_done") or m.human.is_fallen():
		return false
	m.set_meta("hat_done", true)
	m.human.hat_off = true
	var hat := Node2D.new()
	hat.set_script(Sunhat)
	m.add_child(hat)
	var dir: Vector2 = m.wind_dir if m.wind_dir.length() > 0.1 else Vector2(-1, 0.2).normalized()
	hat.setup(m, m.human.global_position + Vector2(0, -6), dir * HAT_SPEED)
	m.float_text(m.human.global_position + Vector2(0, -34), "my hat!", Color(1, 1, 1), m.POP_SAY)
	Sfx.play("hiss", 0.7, -6.0)
	return true


# --- drawing --------------------------------------------------------------------

const RAMPART := Color(0.62, 0.56, 0.46)
const CANNON := Color(0.18, 0.18, 0.20)

# Past the esplanade's top edge: the castle, a stone rampart with its
# crenellations, a bastion's point jutting out, the gate and the flag; the sea
# out past the west side, the city's haze past the east.
static func draw_castle_beyond(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var top := r.position.y
	var b := ShapeBatch.new()
	b.rect(Rect2(-400.0, top - 2000.0, r.position.x + 400.0, 2000.0 + r.size.y), SEA)
	b.rect(Rect2(r.position.x - 70.0, top - 2000.0, 40.0, 2000.0 + r.size.y), SEA.lightened(0.12))
	b.rect(Rect2(r.end.x, top - 2000.0, 700.0, 2000.0 + r.size.y), HAZE.darkened(0.08))
	# the rampart, thick, along the whole top
	b.rect(Rect2(r.position.x - 30.0, top - 230.0, r.size.x + 60.0, 190.0), RAMPART.darkened(0.12))
	b.rect(Rect2(r.position.x - 30.0, top - 64.0, r.size.x + 60.0, 24.0), RAMPART)
	var cx := r.position.x - 24.0
	while cx < r.end.x + 24.0:
		b.rect(Rect2(cx, top - 76.0, 22.0, 14.0), RAMPART.lightened(0.1))
		cx += 40.0
	# a bastion's point, out over the esplanade's corner
	var bp := Vector2(r.position.x + r.size.x * 0.22, top - 40.0)
	b.polygon(PackedVector2Array([bp + Vector2(-90, -150), bp + Vector2(90, -150), bp + Vector2(0, 30)]), RAMPART.darkened(0.04))
	b.polygon(PackedVector2Array([bp + Vector2(-70, -150), bp + Vector2(70, -150), bp + Vector2(0, 8)]), RAMPART.lightened(0.06))
	# the gate, and the flag over it: four red stripes on gold
	var gp := Vector2(r.get_center().x + 160.0, top - 64.0)
	b.rect(Rect2(gp.x - 26.0, gp.y - 20.0, 52.0, 44.0), Color(0.18, 0.14, 0.12))
	b.rect(Rect2(gp.x - 3.0, gp.y - 150.0, 6.0, 110.0), Color(0.30, 0.28, 0.26))
	var fl := Rect2(gp.x + 3.0, gp.y - 150.0, 54.0, 34.0)
	b.rect(fl, Color(0.96, 0.80, 0.22))
	for k in range(4):
		b.rect(Rect2(fl.position.x, fl.position.y + 4.0 + float(k) * 8.0, fl.size.x, 4.0), Color(0.80, 0.16, 0.14))
	b.flush(c)


# The esplanade itself: gravel, a paved margin, low parapets down both sides
# with old cannons trained over them, planters round the trees, the cistern
# that is the plaça's fountain here, benches and the sign.
static func draw_esplanade(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.rect(r, Color(0.74, 0.68, 0.56))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 18.0), STONE)
	for i in range(140):
		var sp := r.position + Vector2(fmod(float(i) * 97.0, r.size.x), fmod(float(i) * 61.0, r.size.y))
		b.circle(sp, 1.6 + float(i % 3) * 0.6, Color(0.62, 0.56, 0.46, 0.6))
	b.circle(r.get_center() + Vector2(-80.0, 40.0), 150.0, Color(0.80, 0.74, 0.62, 0.35))
	for sx: float in [r.position.x - 34.0, r.end.x]:
		b.rect(Rect2(sx, r.position.y, 34.0, r.size.y), RAMPART)
		b.rect(Rect2(sx + (28.0 if sx < r.position.x else 0.0), r.position.y, 6.0, r.size.y), RAMPART.darkened(0.25))
		var cy := r.position.y + 90.0
		while cy < r.end.y - 60.0:
			var out := -1.0 if sx < r.position.x else 1.0
			var base := Vector2(sx + 17.0, cy)
			b.rect(Rect2(base.x - 12.0, base.y - 9.0, 24.0, 18.0), Color(0.40, 0.30, 0.20))
			b.line(base, base + Vector2(out * 34.0, 0.0), CANNON, 10.0)
			b.circle(base + Vector2(out * 34.0, 0.0), 6.0, CANNON.lightened(0.2))
			cy += 170.0
	for t: Vector2 in m.trees:
		b.circle(t + Vector2(3, 4), 26.0, Color(0, 0, 0, 0.15))
		b.circle(t, 24.0, STONE)
		b.circle(t, 19.0, Color(0.36, 0.28, 0.20))
	# loaded, not preloaded: level_build itself refers to Montjuic
	var fr: Rect2 = load("res://world/level_build.gd").placa_fountain(m)
	b.rect(fr.grow(12.0), STONE.darkened(0.1))
	b.rect(fr.grow(6.0), STONE)
	b.rect(fr, Color(0.28, 0.46, 0.54))
	b.rect(Rect2(fr.position, Vector2(fr.size.x, 8.0)), Color(0.20, 0.36, 0.44))
	b.flush(c)
	m._draw_freedom_benches(c, r, Color(0.36, 0.30, 0.24))
	m._freedom_sign(c, r, "L'ESPLANADA", "the castle esplanade, off leash")


# Kites over the esplanade, riding the wind: each on its string down to its
# flyer at the edge, bobbing, leaning downwind, its tail ribbons streaming,
# and its shadow on the gravel below.
const KITES := [
	[Vector2(260.0, -5260.0), Vector2(150.0, -5060.0), Color(0.90, 0.30, 0.26)],
	[Vector2(560.0, -5420.0), Vector2(430.0, -5130.0), Color(0.26, 0.56, 0.86)],
	[Vector2(900.0, -5300.0), Vector2(1080.0, -5100.0), Color(0.96, 0.78, 0.22)],
	[Vector2(1040.0, -5480.0), Vector2(1110.0, -5200.0), Color(0.42, 0.74, 0.40)],
]


static func draw_kites(m: Node2D, c: Object, vt: float, vb: float) -> void:
	if vt > m.GATE_Y:
		return
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c as CanvasItem)
	var t := AnimClock.msec() / 1000.0
	var lean: Vector2 = m.wind_dir * (14.0 if float(m.wind_gust) > 0.0 else 6.0)
	for i in range(KITES.size()):
		var k: Array = KITES[i]
		var p: Vector2 = k[0] + lean + Vector2(sin(t * 0.9 + float(i)) * 14.0, cos(t * 1.3 + float(i) * 2.0) * 9.0)
		var f: Vector2 = k[1]
		var col: Color = k[2]
		if p.y > vb + 80.0 or f.y < vt - 80.0:
			continue
		# the flyer: a head and shoulders, arms up to the string
		b.circle(f + Vector2(3, 4), 10.0, Color(0, 0, 0, 0.18))
		b.circle(f, 10.0, Color(0.30 + 0.1 * float(i % 2), 0.34, 0.50))
		b.circle(f, 5.5, Color(0.50, 0.36, 0.26))
		# the string, sagging a little
		var mid := (f + p) * 0.5 + Vector2(10.0, 18.0)
		b.line(f, mid, Color(1, 1, 1, 0.55), 1.0)
		b.line(mid, p, Color(1, 1, 1, 0.55), 1.0)
		# its shadow, then the kite: a diamond with its spars, and a tail
		var a := sin(t * 1.7 + float(i)) * 0.25
		var dia := PackedVector2Array()
		for v: Vector2 in [Vector2(0, -20), Vector2(14, 0), Vector2(0, 26), Vector2(-14, 0)]:
			dia.append(p + v.rotated(a))
		var sh := PackedVector2Array()
		for q: Vector2 in dia:
			sh.append(q + Vector2(46, 70))
		b.polygon(sh, Color(0, 0, 0, 0.12))
		b.polygon(dia, col)
		b.line(dia[0], dia[2], col.darkened(0.35), 1.4)
		b.line(dia[1], dia[3], col.darkened(0.35), 1.4)
		var prev := dia[2]
		for j in range(5):
			var tp := dia[2] + Vector2(sin(t * 4.0 + float(j) * 0.9) * 6.0, 10.0 + float(j) * 9.0).rotated(a) - lean * 0.2 * float(j)
			b.line(prev, tp, col.lightened(0.2), 2.0)
			prev = tp
	if b != c:
		b.flush()

# The hill road the train runs on: asphalt across the hillside, a striped
# crossing over the path, and a post each side with two red lights that
# flash in turn while the train is coming.
static func draw_road(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if TRAIN_Y + 40.0 < vt or TRAIN_Y - 40.0 > vb:
		return
	var e: Vector2 = m.walk_edges(TRAIN_Y)
	# across the whole view and on down the hill either side, so the train
	# arrives along it rather than appearing at the hillside's rim
	var cx := 640.0
	var hh := 980.0
	b.rect(Rect2(cx - hh, TRAIN_Y - 26.0, hh * 2.0, 52.0), Color(0.36, 0.36, 0.38))
	b.rect(Rect2(cx - hh, TRAIN_Y - 26.0, hh * 2.0, 3.0), Color(0.55, 0.53, 0.50))
	b.rect(Rect2(cx - hh, TRAIN_Y + 23.0, hh * 2.0, 3.0), Color(0.55, 0.53, 0.50))
	var x := cx - hh + 20.0
	while x < cx + hh - 30.0:
		if x < e.x - 20.0 or x > e.y + 10.0:
			b.rect(Rect2(x, TRAIN_Y - 1.5, 26.0, 3.0), Color(0.92, 0.88, 0.70, 0.8))
		x += 52.0
	var sx := e.x + 8.0
	while sx < e.y - 16.0:
		b.rect(Rect2(sx, TRAIN_Y - 22.0, 12.0, 44.0), Color(0.94, 0.94, 0.92, 0.85))
		sx += 24.0
	var warn: float = float(m.get_meta("train_warn", 0.0))
	var blink := int(AnimClock.msec() / 350) % 2
	for px: float in [e.x - 22.0, e.y + 22.0]:
		var pp := Vector2(px, TRAIN_Y - 40.0)
		b.rect(Rect2(pp.x - 3.0, pp.y, 6.0, 14.0), Color(0.25, 0.25, 0.27))
		b.rect(Rect2(pp.x - 14.0, pp.y - 6.0, 28.0, 10.0), Color(0.12, 0.12, 0.13))
		for k in range(2):
			var on := warn > 0.0 and blink == k
			b.circle(pp + Vector2(-7.0 + 14.0 * float(k), -1.0), 4.0,
				Color(1.0, 0.25, 0.2) if on else Color(0.35, 0.12, 0.10))


# The cactus garden's bed: pale gravel, a few stones, and a little sign.
static func draw_cactus_bed(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var r := CACTUS_BED
	if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
		return
	b.rect(r.grow(6.0), STONE.darkened(0.1))
	b.rect(r, Color(0.86, 0.80, 0.66))
	for i in range(18):
		var sp := r.position + Vector2(fmod(float(i) * 53.0, r.size.x - 10.0) + 5.0, fmod(float(i) * 37.0, r.size.y - 10.0) + 5.0)
		b.circle(sp, 2.0 + float(i % 3), Color(0.70, 0.64, 0.54))
	b.draw_string(ThemeDB.fallback_font, r.position + Vector2(4, -10), "JARDÍ DE CACTUS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.30, 0.26, 0.20))


# A cactus from above: the great barrel cactus (ribs and a crown of yellow
# flowers), or a column with arms; spines as pale ticks either way.
static func draw_cactus(c: Object, p: Vector2, big: bool) -> void:
	var green := Color(0.30, 0.52, 0.30)
	var dark := Color(0.20, 0.38, 0.22)
	var spine := Color(0.96, 0.93, 0.78)
	c.draw_circle(p + Vector2(5, 7), 20.0 if big else 14.0, Color(0, 0, 0, 0.18))
	if big:
		c.draw_circle(p, 20.0, dark)
		c.draw_circle(p, 17.0, green)
		for k in range(12):
			var a := TAU * float(k) / 12.0
			c.draw_line(p + Vector2.from_angle(a) * 5.0, p + Vector2.from_angle(a) * 17.0, dark, 1.4)
			c.draw_line(p + Vector2.from_angle(a + 0.13) * 18.0, p + Vector2.from_angle(a + 0.13) * 23.0, spine, 1.0)
		for k in range(5):
			c.draw_circle(p + Vector2.from_angle(TAU * float(k) / 5.0) * 4.0, 2.6, Color(0.98, 0.84, 0.30))
		return
	c.draw_circle(p, 12.0, dark)
	c.draw_circle(p, 9.5, green)
	for arm: Vector2 in [Vector2(-1, 0.3), Vector2(1, -0.4)]:
		var q := p + arm * 15.0
		c.draw_circle(q, 6.0, dark)
		c.draw_circle(q, 4.5, green)
	for k in range(8):
		var a2 := TAU * float(k) / 8.0
		c.draw_line(p + Vector2.from_angle(a2) * 12.0, p + Vector2.from_angle(a2) * 16.0, spine, 1.0)

# The Font Màgica: a stone rim and steps, the basin, and its jets - a ring of
# small ones round a great central plume - rising and falling with the show,
# in waves. By night the water is lit in slow-turning colours.
static func draw_font(m: Node2D, c: Object, vt: float, vb: float) -> void:
	if FONT.end.y < vt - 60.0 or FONT.position.y > vb + 60.0:
		return
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c as CanvasItem)
	var r := FONT
	b.rect(r.grow(22.0), STONE.darkened(0.15))
	b.rect(r.grow(14.0), STONE)
	b.rect(r.grow(4.0), STONE.lightened(0.18))
	var lv := show_level(m)
	var t := float(m.elapsed)
	var night: bool = Game.night
	var deep := Color(0.20, 0.42, 0.58) if not night else Color(0.10, 0.18, 0.32)
	b.rect(r, deep)
	# ripples, more of them in the show
	for i in range(6):
		var ry := r.position.y + 18.0 + float(i) * 26.0
		var rx := r.position.x + 20.0 + fmod(t * (14.0 + 10.0 * lv) + float(i) * 37.0, r.size.x - 60.0)
		b.rect(Rect2(rx, ry, 26.0, 2.0), Color(1, 1, 1, 0.18 + 0.2 * lv))
	var c0 := r.get_center()
	var tint := Color(1, 1, 1)
	if night:
		tint = Color.from_hsv(fmod(t * 0.05, 1.0), 0.55, 1.0)
	# the ring of small jets, each rising on its own beat in the wave
	for i in range(10):
		var a := TAU * float(i) / 10.0
		var p := c0 + Vector2(cos(a) * r.size.x * 0.36, sin(a) * r.size.y * 0.34)
		var wave := 0.5 + 0.5 * sin(t * 3.0 - float(i) * 0.9)
		var h := 3.0 + lv * (6.0 + 9.0 * wave)
		b.circle(p, h + 3.0, Color(tint.r, tint.g, tint.b, 0.16))
		b.circle(p, h, Color(tint.r, tint.g, tint.b, 0.45))
		b.circle(p, maxf(1.5, h * 0.4), Color(1, 1, 1, 0.85))
	# the great plume in the middle, and its falling spray
	var big := 6.0 + lv * (22.0 + 6.0 * sin(t * 1.7))
	b.circle(c0, big + 10.0, Color(tint.r, tint.g, tint.b, 0.12 * (0.3 + lv)))
	b.circle(c0, big, Color(tint.r, tint.g, tint.b, 0.4))
	b.circle(c0, big * 0.55, Color(1, 1, 1, 0.8))
	if lv > 0.2:
		for i in range(14):
			var a2 := TAU * float(i) / 14.0 + t * 0.6
			var d := big + 8.0 + fmod(t * 40.0 + float(i) * 11.0, 26.0)
			b.circle(c0 + Vector2(cos(a2), sin(a2) * 0.8) * d, 1.8, Color(1, 1, 1, 0.55 * lv))
	if b != c:
		b.flush()

# The escalators and the stairs beside them: two steel runs with black rubber
# handrails, treads scrolling up, comb plates at either end, and stone steps
# filling the rest of the path's width.
static func draw_escalator(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var z: Rect2 = m.conveyor_zone
	if z.end.y < vt - 40.0 or z.position.y > vb + 40.0:
		return
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c as CanvasItem)
	var e: Vector2 = m.walk_edges(z.get_center().y)
	# the stairs either side: treads every ESC_TREAD * 2, a shadow under each nose
	var sy := z.position.y
	while sy < z.end.y:
		for seg: Vector2 in [Vector2(e.x + 6.0, z.position.x - 10.0), Vector2(z.end.x + 10.0, e.y - 6.0)]:
			b.rect(Rect2(seg.x, sy, seg.y - seg.x, ESC_TREAD * 2.0), STONE)
			b.rect(Rect2(seg.x, sy + ESC_TREAD * 2.0 - 4.0, seg.y - seg.x, 4.0), STONE.darkened(0.25))
			b.rect(Rect2(seg.x, sy, seg.y - seg.x, 2.0), STONE.lightened(0.2))
		sy += ESC_TREAD * 2.0
	# the casing, a steel strip down the middle between the two runs
	b.rect(Rect2(z.position.x - 10.0, z.position.y - 8.0, z.size.x + 20.0, z.size.y + 16.0), Color(0.38, 0.40, 0.43))
	var half := z.size.x * 0.5
	for run in range(2):
		var x0 := z.position.x + float(run) * (half + 4.0)
		var w := half - 4.0
		b.rect(Rect2(x0, z.position.y, w, z.size.y), Color(0.24, 0.25, 0.27))
		# treads, moving up the hill
		var scroll := fmod(AnimClock.msec() / 1000.0 * 118.0, ESC_TREAD)
		var ty := z.position.y + ESC_TREAD - scroll
		while ty < z.end.y:
			b.rect(Rect2(x0 + 2.0, ty, w - 4.0, 2.0), Color(0.50, 0.52, 0.55))
			ty += ESC_TREAD
		# the handrails, black rubber, each side of the run
		b.rect(Rect2(x0 - 3.0, z.position.y - 6.0, 4.0, z.size.y + 12.0), Color(0.08, 0.08, 0.09))
		b.rect(Rect2(x0 + w - 1.0, z.position.y - 6.0, 4.0, z.size.y + 12.0), Color(0.08, 0.08, 0.09))
	# comb plates, top and bottom
	for py: float in [z.position.y - 8.0, z.end.y]:
		b.rect(Rect2(z.position.x, py, z.size.x, 8.0), Color(0.72, 0.68, 0.30))
	if b != c:
		b.flush()


const SAULO := Color(0.78, 0.70, 0.54)        # the paths' packed sand
const HILL := Color(0.46, 0.50, 0.30)         # dry Mediterranean scrub
const STONE := Color(0.70, 0.64, 0.54)
const HAZE := Color(0.72, 0.78, 0.84)
const SEA := Color(0.30, 0.50, 0.68)


# The hillside, under the path: a polygon between its rims, which narrow as it
# climbs. (Past the rims the edge layer shows the city below.)
static func draw_hill(m: Node2D, c: Object, vt: float, vb: float) -> void:
	# in horizontal strips, rim to rim (a single long polygon with wavy sides
	# does not always triangulate)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	# up to the gate only: past it is the castle's esplanade, freedomlayer's
	var y := floorf((maxf(vt, m.GATE_Y - 30.0) - 60.0) / 20.0) * 20.0
	y = maxf(y, m.GATE_Y - 40.0)
	var y1 := vb + 60.0
	while y <= y1:
		var e: Vector2 = m.walk_edges(y + 10.0)
		var cx := (e.x + e.y) * 0.5
		var hh := hill_half(m, y + 10.0) + sin((y + 10.0) * 0.013) * 26.0
		c.draw_rect(Rect2(cx - hh, y, hh * 2.0, 21.0), HILL)
		left.append(Vector2(cx - hh, y + 10.0))
		right.append(Vector2(cx + hh, y + 10.0))
		y += 20.0
	# the rim: rock breaking out where the hill drops away
	for pts: PackedVector2Array in [left, right]:
		c.draw_polyline(pts, Color(0.36, 0.33, 0.27), 7.0)
		c.draw_polyline(pts, Color(0.58, 0.54, 0.44), 3.0)


# What stands on the hill: the terraces and their steps, pines and agaves,
# the height posts, and, in a gust, the wind itself.
static func draw_on_hill(m: Node2D, c: Object, vt: float, vb: float) -> void:
	# straight onto the world's canvas batch: it can pass text through
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c as CanvasItem)
	draw_font(m, b, vt, vb)
	draw_road(m, b, vt, vb)
	draw_cactus_bed(m, b, vt, vb)
	if CACTUS_BED.end.y > vt - 40.0 and CACTUS_BED.position.y < vb + 40.0:
		for i in range(CACTI.size()):
			draw_cactus(b, CACTI[i], i == 0)
	for wy: float in terrace_ys(m):
		if wy < vt - 80.0 or wy > vb + 80.0:
			continue
		var e: Vector2 = m.walk_edges(wy)
		var cx := (e.x + e.y) * 0.5
		var hh := hill_half(m, wy) + sin(wy * 0.013) * 26.0
		# the wall: its cap along the top, its face below in shadow, and the
		# shade it throws on the terrace beneath
		for seg: Vector2 in [Vector2(cx - hh, e.x - 4.0), Vector2(e.y + 4.0, cx + hh)]:
			if seg.y - seg.x < 8.0:
				continue
			b.rect(Rect2(seg.x, wy + 14.0, seg.y - seg.x, 22.0), Color(0, 0, 0, 0.16))
			b.rect(Rect2(seg.x, wy, seg.y - seg.x, 14.0), STONE.darkened(0.30))
			b.rect(Rect2(seg.x, wy - 6.0, seg.y - seg.x, 7.0), STONE)
			b.rect(Rect2(seg.x, wy - 6.0, seg.y - seg.x, 2.0), STONE.lightened(0.25))
			var jx := seg.x + 18.0
			while jx < seg.y - 6.0:
				b.line(Vector2(jx, wy + 1.0), Vector2(jx, wy + 13.0), STONE.darkened(0.42), 1.2)
				jx += 26.0
		# the flight of steps where the path cuts through it
		for k in range(4):
			var sy := wy - float(k) * (STEP_H / 4.0)
			var se: Vector2 = m.walk_edges(sy)
			b.rect(Rect2(se.x, sy - 3.0, se.y - se.x, 3.0), SAULO.darkened(0.22))
			b.rect(Rect2(se.x, sy - 5.0, se.y - se.x, 2.0), SAULO.lightened(0.12))
		# pier ends where the wall meets the path
		for px: float in [e.x - 8.0, e.y + 2.0]:
			b.rect(Rect2(px, wy - 8.0, 8.0, 24.0), STONE.darkened(0.12))
		# the height, cut in a stone post at every third wall
		var k3 := int(roundf((m.START_Y - 260.0 - wy) / TERRACE_STEP))
		if k3 % 3 == 1:
			var post := Vector2(e.x - 30.0, wy - 26.0)
			b.rect(Rect2(post.x - 12.0, post.y - 10.0, 24.0, 20.0), STONE.darkened(0.08))
			b.rect(Rect2(post.x - 12.0, post.y - 10.0, 24.0, 3.0), STONE.lightened(0.2))
			var metres := int(roundf(climb(m, wy) * TOP_M / 5.0) * 5.0)
			b.draw_string(ThemeDB.fallback_font, post + Vector2(-10, 5), "%dm" % metres,
				HORIZONTAL_ALIGNMENT_LEFT, 24, 11, Color(0.22, 0.18, 0.14))
	# agaves and prickly pears on the terraces, pines leaning out over the rim
	var y := floorf((vt - 120.0) / 140.0) * 140.0
	while y < vb + 120.0:
		var e2: Vector2 = m.walk_edges(y)
		var cx2 := (e2.x + e2.y) * 0.5
		var hh2 := hill_half(m, y)
		var k := int(absf(y) / 140.0)
		for s: float in [-1.0, 1.0]:
			var inner: float = e2.x - 50.0 if s < 0.0 else e2.y + 50.0
			var outer := cx2 + s * (hh2 - 40.0)
			if absf(outer - inner) < 60.0:
				continue
			var f := float((k * 7 + int(s + 1.0) * 3) % 10) / 10.0
			var p := Vector2(lerpf(inner, outer, 0.25 + 0.6 * f), y + float(k % 3) * 20.0)
			if FONT.grow(40.0).has_point(p) or CACTUS_BED.grow(40.0).has_point(p):
				continue
			if k % 3 == 0:
				_agave(b, p)
			elif k % 3 == 1:
				_prickly_pear(b, p)
			else:
				_pine(b, Vector2(outer - s * 20.0, y), s)
		y += 140.0
	# the wind, seen: leaves and streaks across the view while a gust is
	# coming and while it blows
	var w: float = m.wind_warn + m.wind_gust
	if w > 0.0:
		var t := AnimClock.msec() / 1000.0
		var a: float = 0.5 if m.wind_gust > 0.0 else 0.35 * (1.0 - m.wind_warn / GUST_WARN)
		var d: Vector2 = m.wind_dir
		var cam: Vector2 = m.cam.global_position
		for i in range(18):
			var row := float(i) / 18.0
			var run := fmod(t * 520.0 + float(i) * 173.0, 1500.0) - 750.0
			var p0 := cam + Vector2(-d.x * run, (row - 0.5) * 680.0 + d.y * run * 0.3)
			b.line(p0, p0 + d * 46.0, Color(1, 1, 1, a * 0.6), 1.5)
			if i % 3 == 0:
				b.circle(p0 + d * 50.0, 3.0, Color(0.56, 0.58, 0.28, a))
	if b != c:
		b.flush()


static func _agave(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(4, 5), 12.0, Color(0, 0, 0, 0.14))
	for i in range(7):
		var a := TAU * float(i) / 7.0
		b.line(p, p + Vector2.from_angle(a) * 15.0, Color(0.42, 0.58, 0.52), 4.0)
	b.circle(p, 4.0, Color(0.50, 0.66, 0.58))


static func _prickly_pear(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(4, 5), 12.0, Color(0, 0, 0, 0.14))
	for q: Vector2 in [Vector2(0, 0), Vector2(-9, -8), Vector2(8, -9), Vector2(2, -17)]:
		b.circle(p + q, 7.0, Color(0.34, 0.52, 0.30))
		b.circle(p + q + Vector2(-1.5, -1.5), 3.5, Color(0.42, 0.60, 0.36))
	b.circle(p + Vector2(8, -15), 2.2, Color(0.86, 0.36, 0.40))


static func _pine(b: ShapeBatch, p: Vector2, s: float) -> void:
	# an umbrella crown, leaning out over the drop
	var crown := p + Vector2(s * 16.0, -6.0)
	b.circle(crown + Vector2(10, 12), 24.0, Color(0, 0, 0, 0.16))
	b.line(p, crown, Color(0.42, 0.30, 0.20), 4.0)
	b.circle(crown, 22.0, Color(0.20, 0.34, 0.20))
	b.circle(crown + Vector2(-5, -5), 14.0, Color(0.26, 0.42, 0.24))


# The city below, past the rims (drawn on the edge layer, behind the hill):
# the Eixample's grid of chamfered blocks round their courtyards, streets
# between, shrinking and hazing with height; from halfway up, the port and
# the sea open on the left.
static func draw_below(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# up to the gate: past it the esplanade draws its own sea and haze
	var y := floorf((maxf(vt, m.GATE_Y) - 300.0) / 60.0) * 60.0
	y = maxf(y, m.GATE_Y - 60.0)
	var street := Color(0.60, 0.58, 0.56)
	while y < vb + 300.0:
		var h := climb(m, y + 30.0)
		var haze := 0.18 + 0.55 * h
		var e: Vector2 = m.walk_edges(y + 30.0)
		var cx := (e.x + e.y) * 0.5
		var hh := hill_half(m, y + 30.0) - 30.0
		var sea_to := lerpf(-900.0, cx - hh - 40.0, clampf((h - 0.45) / 0.4, 0.0, 1.0))
		b.rect(Rect2(-400.0, y, 2100.0, 61.0), street.lerp(HAZE, haze))
		if sea_to > -400.0:
			b.rect(Rect2(-400.0, y, sea_to + 400.0, 61.0), SEA.lerp(HAZE, haze * 0.8))
		y += 60.0
	# the blocks, on their own grid so they do not jump between strips
	var cell := 64.0
	var by := maxf(floorf((vt - 300.0) / cell) * cell, m.GATE_Y - 40.0)
	while by < vb + 300.0:
		var h2 := climb(m, by)
		var haze2 := 0.18 + 0.55 * h2
		var s := lerpf(1.0, 0.45, h2)            # further below, smaller
		var e2: Vector2 = m.walk_edges(by)
		var cx2 := (e2.x + e2.y) * 0.5
		var hh2 := hill_half(m, by) - 30.0
		var sea2 := lerpf(-900.0, cx2 - hh2 - 40.0, clampf((h2 - 0.45) / 0.4, 0.0, 1.0))
		var step := cell * s
		# the camera never leaves 0..1280 on this walk: nothing wider is seen
		var bx := -40.0
		while bx < 1320.0:
			if (bx + step < cx2 - hh2 or bx > cx2 + hh2) and bx > sea2 + 6.0:
				_block(b, Vector2(bx, by), step, haze2)
			bx += step
		by += step
	b.flush(c)


# one Eixample block from above: chamfered corners, a ring of roofs, the
# courtyard green in the middle
static func _block(b: ShapeBatch, at: Vector2, step: float, haze: float) -> void:
	var w := step * 0.78
	var ch := w * 0.22
	var o := at + Vector2(step * 0.11, step * 0.11)
	var n := sin(at.x * 12.9898 + at.y * 78.233) * 43758.5
	n -= floorf(n)
	var roof: Color = [Color(0.74, 0.46, 0.34), Color(0.70, 0.64, 0.56), Color(0.80, 0.68, 0.50)][int(n * 3.0)]
	var oct := PackedVector2Array([o + Vector2(ch, 0), o + Vector2(w - ch, 0), o + Vector2(w, ch), o + Vector2(w, w - ch),
		o + Vector2(w - ch, w), o + Vector2(ch, w), o + Vector2(0, w - ch), o + Vector2(0, ch)])
	b.polygon(oct, roof.lerp(HAZE, haze))
	var yard := w * 0.42
	b.rect(Rect2(o + Vector2((w - yard) * 0.5, (w - yard) * 0.5), Vector2(yard, yard)),
		Color(0.40, 0.50, 0.34).lerp(HAZE, haze))
