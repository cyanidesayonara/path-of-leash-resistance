class_name Montjuic
extends RefCounted

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["build_layer", "draw_bollard", "draw_conveyor", "draw_edge_layer", "draw_freedom", "draw_ground", "draw_live", "draw_threshold", "grass_blocked", "surface", "tick"]


const EventFeed := preload("res://hud/event_feed.gd")
const CableCar := preload("res://systems/cable_car.gd")
const Detour := preload("res://systems/detour.gd")
const Surfaces := preload("res://world/surfaces.gd")

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
# a paper bag lifts on a gust past LITTER_CLIMB, one loose at a time and
# LITTER_MAX a walk, from LITTER_UPWIND upwind of her
const LITTER_CLIMB := 0.15
const LITTER_MAX := 3
const LITTER_UPWIND := 260.0
const Litter := preload("res://entities/litter.gd")
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


# The first wall is one step up from the start, not at it: the walk's name is
# laid out on the open path where the start's wall used to cross it.
static func terrace_ys(m: Node2D) -> Array[float]:
	var out: Array[float] = []
	var y: float = m.START_Y - 260.0 - TERRACE_STEP
	while y > m.GATE_Y + 200.0:
		out.append(y)
		y -= TERRACE_STEP
	return out


static func on_steps(m: Node2D, y: float) -> bool:
	var k := maxf(1.0, roundf((m.START_Y - 260.0 - y) / TERRACE_STEP))
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
		m.feed.say(I18n.t("w_the_magic_fountain"), EventFeed.Tone.GOOD)
		m.float_text(m.dog.global_position + Vector2(0, -30), I18n.t("w_in_the_show_5"), Color(0.75, 0.9, 1.0))


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
			m.feed.say(I18n.t("w_ow_cactus"), EventFeed.Tone.BAD)
			m.float_text(dp + Vector2(0, -28), I18n.t("w_prickly"), Color(1, 0.8, 0.7))
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
			m.float_text(CACTI[0] + Vector2(0, -40), I18n.t("w_a_very_careful_sniff_4"), Color(0.85, 1.0, 0.7))
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
			m.float_text(Vector2(edge, TRAIN_Y - 40.0), I18n.t("w_ding_ding_2"), Color(1, 0.95, 0.75), m.POP_SAY)


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
			if h > LITTER_CLIMB and not m.auto_walk:
				blow_litter(m)
		return
	m.wind_next -= delta
	if m.wind_next <= 0.0 and h > 0.12:
		m.wind_warn = GUST_WARN
		m.wind_next = m.wind_rng.randf_range(GUST_EVERY.x, GUST_EVERY.y) * lerpf(1.3, 0.75, h)
		# off the sea, mostly: from one side, a little down the hill
		var s := -1.0 if m.wind_rng.randf() < 0.65 else 1.0
		m.wind_dir = Vector2(s, m.wind_rng.randf_range(0.0, 0.35)).normalized()
		Sfx.play("hiss", 0.45, -8.0)
		m.float_text(m.dog.global_position + Vector2(-s * 60.0, -30.0), I18n.t("w_whoooosh"), Color(0.92, 0.95, 1.0))


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
	m.float_text(m.human.global_position + Vector2(0, -34), I18n.t("w_my_hat_come_back"), Color(1, 1, 1), m.POP_SAY)
	Sfx.play("hiss", 0.7, -6.0)
	return true


# A gust lifts a paper bag upwind of her and sends it skittering along the
# path (entities/litter.gd); main.on_litter_caught is her pouncing on it.
static func blow_litter(m: Node2D) -> bool:
	var n: int = int(m.get_meta("litter_n", 0))
	if n >= LITTER_MAX:
		return false
	if m.has_meta("litter") and is_instance_valid(m.get_meta("litter")):
		return false
	var dir: Vector2 = m.wind_dir if m.wind_dir.length() > 0.1 else Vector2.RIGHT
	var at: Vector2 = m.dog.global_position - Vector2(dir.x, 0.0).normalized() * LITTER_UPWIND + Vector2(0, -60)
	var bag := Node2D.new()
	bag.set_script(Litter)
	m.add_child(bag)
	bag.setup(m, at, dir * 160.0)
	m.set_meta("litter", bag)
	m.set_meta("litter_n", n + 1)
	Sfx.play("rustle", 1.2, -8.0)
	return true


# --- drawing --------------------------------------------------------------------

const RAMPART := Color(0.62, 0.56, 0.46)
const CANNON := Color(0.18, 0.18, 0.20)

static func _hill_rim_xs(m: Node2D, y: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	var cx := (e.x + e.y) * 0.5
	var hh := hill_half(m, y) + sin(y * 0.013) * 26.0
	# flare the hilltop out over the last 220px to cradle the esplanade's ramparts
	var top_t := smoothstep(m.GATE_Y + 220.0, m.GATE_Y - 30.0, y)
	return Vector2(lerpf(cx - hh, 36.0, top_t), lerpf(cx + hh, 1214.0, top_t))


# Past the esplanade's top edge: the castle, a stone rampart with its
# crenellations, a bastion's point jutting out, the gate and the flag; the sea
# out past the west side, the city's haze past the east.
static func draw_castle_beyond(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var top := r.position.y
	var bot := r.end.y
	var b := ShapeBatch.new()
	b.rect(Rect2(-400.0, top - 2000.0, r.position.x + 400.0, 2000.0 + r.size.y), SEA)
	# feather sea & city haze at the south edge to match draw_edge_layer at h = 1.0
	var edge_sea := SEA.lerp(HAZE, 0.73 * 0.8)
	var sea_pts := PackedVector2Array([
		Vector2(-400.0, bot - 480.0), Vector2(r.position.x, bot - 480.0),
		Vector2(-400.0, bot), Vector2(r.position.x, bot),
	])
	b.band(sea_pts, 2, edge_sea, PackedFloat32Array([0.0, 1.0]))
	b.rect(Rect2(r.position.x - 70.0, top - 2000.0, 40.0, 2000.0 + r.size.y - 160.0), SEA.lightened(0.12))
	var shelf_pts := PackedVector2Array([
		Vector2(r.position.x - 70.0, bot - 160.0), Vector2(r.position.x - 30.0, bot - 160.0),
		Vector2(r.position.x - 70.0, bot), Vector2(r.position.x - 30.0, bot),
	])
	b.band(shelf_pts, 2, SEA.lightened(0.12), PackedFloat32Array([1.0, 0.0]))
	b.rect(Rect2(r.end.x, top - 2000.0, 700.0, 2000.0 + r.size.y), HAZE.darkened(0.08))
	var edge_city := CITY_STREET.lerp(HAZE, 0.73)
	var haze_pts := PackedVector2Array([
		Vector2(r.end.x, bot - 400.0), Vector2(r.end.x + 700.0, bot - 400.0),
		Vector2(r.end.x, bot), Vector2(r.end.x + 700.0, bot),
	])
	b.band(haze_pts, 2, edge_city, PackedFloat32Array([0.0, 1.0]))
	# continue the hill-rim shadow up along the outer west & east ramparts so
	# _rim_shadow does not start with a horizontal line at y = -5030
	var wx := r.position.x - 34.0
	var ex := r.end.x + 34.0
	b.band(PackedVector2Array([
		Vector2(wx, top), Vector2(wx - RIM_SHADE_W, top),
		Vector2(wx, bot), Vector2(wx - RIM_SHADE_W, bot),
	]), 2, Color(0.10, 0.12, 0.16, 0.30), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	b.band(PackedVector2Array([
		Vector2(ex, top), Vector2(ex + RIM_SHADE_W * 1.4, top),
		Vector2(ex, bot), Vector2(ex + RIM_SHADE_W * 1.4, bot),
	]), 2, Color(0.10, 0.12, 0.16, 0.38), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
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
	b.glow(r.get_center() + Vector2(-80.0, 40.0), 260.0, Color(0.82, 0.76, 0.64, 0.40), 0.3)
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
	m._freedom_sign(c, r, "L'ESPLANADA", I18n.t("w_the_castle_esplanade_off_leash"))


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
# crossing over the path, stone viaduct parapets where it clears the hill rims,
# and a post each side with two red lights that flash in turn while the train is coming.
static func draw_road(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if TRAIN_Y + 46.0 < vt or TRAIN_Y - 46.0 > vb:
		return
	var e: Vector2 = m.walk_edges(TRAIN_Y)
	var rim := _hill_rim_xs(m, TRAIN_Y)
	# across the whole view and on down the hill either side, so the train
	# arrives along it rather than appearing at the hillside's rim
	var cx := 640.0
	var hh := 980.0
	var x0 := cx - hh
	var x1 := cx + hh
	# viaduct shadow and piers where the road bridges past the hill's rims
	for span: Vector2 in [Vector2(x0, rim.x), Vector2(rim.y, x1)]:
		if span.y - span.x < 4.0:
			continue
		b.rect(Rect2(span.x, TRAIN_Y + 26.0, span.y - span.x, 16.0), Color(0.0, 0.0, 0.0, 0.24))
		var px := span.x + 40.0
		while px < span.y - 20.0:
			b.rect(Rect2(px - 8.0, TRAIN_Y + 26.0, 16.0, 20.0), STONE.darkened(0.32))
			px += 140.0
	b.rect(Rect2(x0, TRAIN_Y - 26.0, hh * 2.0, 52.0), Color(0.36, 0.36, 0.38))
	# hillside stone kerbs along the road, thickening into bridge parapets past the rims
	for seg: Vector2 in [Vector2(x0, rim.x), Vector2(rim.y, x1)]:
		if seg.y - seg.x < 2.0:
			continue
		b.rect(Rect2(seg.x, TRAIN_Y - 30.0, seg.y - seg.x, 6.0), STONE)
		b.rect(Rect2(seg.x, TRAIN_Y - 30.0, seg.y - seg.x, 2.0), STONE.lightened(0.22))
		b.rect(Rect2(seg.x, TRAIN_Y + 24.0, seg.y - seg.x, 6.0), STONE.darkened(0.14))
		b.rect(Rect2(seg.x, TRAIN_Y + 24.0, seg.y - seg.x, 2.0), STONE.lightened(0.14))
	for seg: Vector2 in [Vector2(rim.x, e.x), Vector2(e.y, rim.y)]:
		if seg.y - seg.x < 2.0:
			continue
		b.rect(Rect2(seg.x, TRAIN_Y - 27.0, seg.y - seg.x, 3.5), STONE.darkened(0.14))
		b.rect(Rect2(seg.x, TRAIN_Y - 27.0, seg.y - seg.x, 1.5), STONE.lightened(0.12))
		b.rect(Rect2(seg.x, TRAIN_Y + 23.5, seg.y - seg.x, 3.5), STONE.darkened(0.18))
		b.rect(Rect2(seg.x, TRAIN_Y + 23.5, seg.y - seg.x, 1.5), STONE.lightened(0.08))
	# stone crossing kerb aprons and stop bars where the path meets the road
	b.rect(Rect2(e.x - 4.0, TRAIN_Y - 26.0, 6.0, 52.0), STONE)
	b.rect(Rect2(e.y - 2.0, TRAIN_Y - 26.0, 6.0, 52.0), STONE)
	b.rect(Rect2(e.x - 14.0, TRAIN_Y - 22.0, 3.0, 44.0), Color(0.92, 0.90, 0.84, 0.72))
	b.rect(Rect2(e.y + 11.0, TRAIN_Y - 22.0, 3.0, 44.0), Color(0.92, 0.90, 0.84, 0.72))
	var x := x0 + 20.0
	while x < x1 - 30.0:
		if x < e.x - 28.0 or x > e.y + 18.0:
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
			var on := warn > 0.0 and (true if not Game.flashes else blink == k)
			b.circle(pp + Vector2(-7.0 + 14.0 * float(k), -1.0), 4.0,
				Color(1.0, 0.25, 0.2) if on else Color(0.35, 0.12, 0.10))


# The cactus garden's bed: pale gravel, raked ridges, terracotta curbs, botanical plaques, and a little sign.
static func draw_cactus_bed(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var r := CACTUS_BED
	if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
		return
	# gravel approach apron from the path's east edge into the garden's west edge
	var entry_y := r.position.y + 82.0
	var ce: Vector2 = m.walk_edges(entry_y + 24.0)
	if r.position.x > ce.y - 2.0:
		b.rect(Rect2(ce.y - 4.0, entry_y - 3.0, r.position.x - ce.y + 6.0, 54.0), STONE.darkened(0.08))
		b.rect(Rect2(ce.y - 4.0, entry_y, r.position.x - ce.y + 8.0, 48.0), Color(0.84, 0.77, 0.62))
	b.rect(r.grow(8.0), STONE.darkened(0.20))
	b.rect(r.grow(6.0), STONE.darkened(0.1))
	b.rect(r, Color(0.86, 0.80, 0.66))

	# raked gravel ridges across the bed
	for gy in range(4):
		var yline := r.position.y + 25.0 + float(gy) * 50.0
		b.line(Vector2(r.position.x + 8.0, yline), Vector2(r.end.x - 8.0, yline), Color(0.80, 0.74, 0.60), 1.6)

	for i in range(18):
		var sp := r.position + Vector2(fmod(float(i) * 53.0, r.size.x - 10.0) + 5.0, fmod(float(i) * 37.0, r.size.y - 10.0) + 5.0)
		b.circle(sp, 2.0 + float(i % 3), Color(0.70, 0.64, 0.54))

	# terracotta border curb tiles, open at the path entry on the west side
	b.rect(Rect2(r.position.x, r.position.y, 3.0, entry_y - r.position.y), Color(0.72, 0.44, 0.30))
	b.rect(Rect2(r.position.x, entry_y + 48.0, 3.0, r.end.y - (entry_y + 48.0)), Color(0.72, 0.44, 0.30))
	b.rect(Rect2(r.end.x - 3.0, r.position.y, 3.0, r.size.y), Color(0.72, 0.44, 0.30))
	for side_y: float in [r.position.y, r.end.y - 3.0]:
		b.rect(Rect2(r.position.x, side_y, r.size.x, 3.0), Color(0.72, 0.44, 0.30))

	# botanical wooden stakes with identification plaques
	for bi in range(2):
		var bp := r.position + Vector2(30.0 + float(bi) * 110.0, 18.0 + float(bi) * 120.0)
		b.rect(Rect2(bp.x - 1.0, bp.y, 2.0, 8.0), Color(0.40, 0.32, 0.22))
		b.rect(Rect2(bp.x - 7.0, bp.y - 7.0, 14.0, 7.0), Color(0.94, 0.92, 0.84))
		b.line(Vector2(bp.x - 5.0, bp.y - 3.5), Vector2(bp.x + 5.0, bp.y - 3.5), Color(0.28, 0.24, 0.20), 1.0)

	# garden title south of the bed, clear of the -2100 shadow and the corner pine
	b.draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 58.0, r.end.y + 20.0), "JARDÍ DE CACTUS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.24, 0.22, 0.16))


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

# The Font Màgica: a stone rim and steps, the basin, submerged illumination rings,
# and its jets - a ring of small ones round a great central plume - rising and falling
# with the show, in waves. By night the water is lit in slow-turning colours.
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

	var c0 := r.get_center()

	# Carles Buïgas concentric brass jet manifolds below water
	# outer first: each ring's water fill would cover a ring inside it
	for ring_frac: float in [0.36, 0.20]:
		var rad_x := r.size.x * ring_frac
		var rad_y := r.size.y * (ring_frac * 0.92)
		b.polygon(_oval_pts(c0, rad_x + 1.8, rad_y + 1.8, 40), Color(0.14, 0.28, 0.40, 0.45))
		b.polygon(_oval_pts(c0, rad_x, rad_y, 40), Color(0.74, 0.66, 0.36, 0.60))
		b.polygon(_oval_pts(c0, rad_x - 1.8, rad_y - 1.8, 40), deep)

	# submerged illumination projector glow radiating through the water
	var glow_tint := Color(0.30, 0.78, 0.92) if not night else Color.from_hsv(fmod(t * 0.05, 1.0), 0.6, 1.0)
	b.glow(c0, r.size.y * 0.5, Color(glow_tint.r, glow_tint.g, glow_tint.b, 0.20 * (0.35 + lv)), 0.2)

	# ripples, more of them in the show
	for i in range(6):
		var ry := r.position.y + 18.0 + float(i) * 26.0
		var rx := r.position.x + 20.0 + fmod(t * (14.0 + 10.0 * lv) + float(i) * 37.0, r.size.x - 60.0)
		b.rect(Rect2(rx, ry, 26.0, 2.0), Color(1, 1, 1, 0.18 + 0.2 * lv))
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
static func draw_conveyor(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var z: Rect2 = m.conveyor_zone
	if z.end.y < vt - 60.0 or z.position.y > vb + 60.0:
		return
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c as CanvasItem)
	# stone landing aprons at bottom and top so the flight joins the sandy path
	for ly: float in [z.position.y - 18.0, z.end.y]:
		var le: Vector2 = m.walk_edges(ly + 9.0)
		b.rect(Rect2(le.x + 2.0, ly, le.y - le.x - 4.0, 18.0), STONE)
		b.rect(Rect2(le.x + 2.0, ly, le.y - le.x - 4.0, 2.5), STONE.lightened(0.22))
		b.rect(Rect2(le.x + 2.0, ly + 15.0, le.y - le.x - 4.0, 3.0), STONE.darkened(0.22))
		var lx := le.x + 28.0
		while lx < le.y - 20.0:
			b.line(Vector2(lx, ly + 2.0), Vector2(lx, ly + 16.0), STONE.darkened(0.22), 1.2)
			lx += 36.0
	# stairs either side, hugging the path's real edges and fitted evenly to z.size.y
	var n_steps := maxi(1, int(roundf(z.size.y / (ESC_TREAD * 2.0))))
	var step_h := z.size.y / float(n_steps)
	for si in range(n_steps):
		var sy := z.position.y + float(si) * step_h
		var se: Vector2 = m.walk_edges(sy + step_h * 0.5)
		for seg: Vector2 in [Vector2(se.x + 2.0, z.position.x - 10.0), Vector2(z.end.x + 10.0, se.y - 2.0)]:
			if seg.y - seg.x < 4.0:
				continue
			b.rect(Rect2(seg.x, sy, seg.y - seg.x, step_h), STONE)
			b.rect(Rect2(seg.x, sy + step_h - 4.0, seg.y - seg.x, 4.0), STONE.darkened(0.25))
			b.rect(Rect2(seg.x, sy, seg.y - seg.x, 2.0), STONE.lightened(0.2))
		# stone cheek curbs framing the stair flight against the path edges
		b.rect(Rect2(se.x + 1.0, sy, 4.0, step_h + 1.0), STONE.darkened(0.14))
		b.rect(Rect2(se.y - 5.0, sy, 4.0, step_h + 1.0), STONE.darkened(0.14))
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
const CITY_STREET := Color(0.50, 0.49, 0.48)
const CITY_SHADE := Color(0.34, 0.33, 0.34)
const RIM_SHADE_W := 70.0
const ESPLANADE_EARTH_R := 24.0     # a tree pit's earth, as draw_esplanade rings it


# The hillside, under the path: a polygon between its rims, which narrow as it
# climbs and flare at the top to meet the castle esplanade. (Past the rims the
# edge layer shows the city below.)
static func draw_ground(m: Node2D, c: Object, vt: float, vb: float) -> void:
	# trapezoidal quads between rims so steep upper flares have no stair-step edge
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var gate_top: float = float(m.GATE_Y) - 30.0
	var y := maxf(floorf((vt - 60.0) / 20.0) * 20.0, gate_top)
	var y1 := vb + 60.0
	if y <= y1:
		var rx0 := _hill_rim_xs(m, y)
		left.append(Vector2(rx0.x, y))
		right.append(Vector2(rx0.y, y))
		while y < y1:
			var yn := y + 20.0
			var rx1 := _hill_rim_xs(m, yn)
			if c.has_method("draw_colored_polygon"):
				c.draw_colored_polygon(PackedVector2Array([
					Vector2(rx0.x, y), Vector2(rx0.y, y),
					Vector2(rx1.y, yn), Vector2(rx1.x, yn),
				]), HILL)
			else:
				c.draw_rect(Rect2(rx0.x, y, rx0.y - rx0.x, 21.0), HILL)
			left.append(Vector2(rx1.x, yn))
			right.append(Vector2(rx1.y, yn))
			y = yn
			rx0 = rx1
	# the rim: rock breaking out where the hill drops away. A view that
	# does not include the hill, such as the esplanade, leaves these empty,
	# and a polyline needs two points.
	for pts: PackedVector2Array in [left, right]:
		if pts.size() < 2:
			continue
		c.draw_polyline(pts, Color(0.36, 0.33, 0.27), 7.0)
		c.draw_polyline(pts, Color(0.58, 0.54, 0.44), 3.0)


# Boarding terrace & path spur linking a telefèric station cleanly to the hill path.
static func _draw_station_pad(m: Node2D, b: ShapeBatch, st: Vector2, on_left: bool) -> void:
	var pad := Rect2(st + Vector2(-46.0, -32.0), Vector2(92.0, 62.0))
	var se: Vector2 = m.walk_edges(st.y)
	var spur_x0 := pad.end.x - 4.0 if on_left else se.y - 4.0
	var spur_x1 := se.x + 4.0 if on_left else pad.position.x + 4.0
	if spur_x1 > spur_x0:
		b.rect(Rect2(spur_x0, st.y - 16.0, spur_x1 - spur_x0, 32.0), STONE.darkened(0.10))
		b.rect(Rect2(spur_x0, st.y - 13.0, spur_x1 - spur_x0, 26.0), SAULO)
	b.rect(pad.grow(4.0), STONE.darkened(0.14))
	b.rect(pad, STONE)
	b.rect(pad.grow(-4.0), SAULO.darkened(0.04))


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
	if m.cable_low != Vector2.ZERO and m.cable_low.y > vt - 60.0 and m.cable_low.y < vb + 60.0:
		_draw_station_pad(m, b, m.cable_low, true)
	if m.cable_top != Vector2.ZERO and m.cable_top.y > vt - 60.0 and m.cable_top.y < vb + 60.0:
		_draw_station_pad(m, b, m.cable_top, false)
	var mirador_y := -1500.0
	var mir_e: Vector2 = m.walk_edges(mirador_y)
	var mir_p := Vector2(mir_e.y + 24.0, mirador_y)
	for wy: float in terrace_ys(m):
		if wy < vt - 80.0 or wy > vb + 80.0:
			continue
		var e: Vector2 = m.walk_edges(wy)
		var rim := _hill_rim_xs(m, wy)
		var is_mirador: bool = absf(wy - mirador_y) < 1.0
		var is_top_station: bool = absf(wy - CableCar.TOP_Y) < 1.0 and m.cable_top != Vector2.ZERO
		var right_start: float = mir_p.x + 18.0 if is_mirador else (float(m.cable_top.x) + 44.0 if is_top_station else e.y + 4.0)
		# the wall: its cap along the top, its face below in shadow, and the
		# shade it throws on the terrace beneath
		for seg: Vector2 in [Vector2(rim.x, e.x - 4.0), Vector2(right_start, rim.y)]:
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

			# trailing ivy (heura) tendrils cascading over the wall face
			var iv_x := seg.x + 14.0
			while iv_x < seg.y - 14.0:
				var iv_h := 8.0 + float(int(absf(iv_x * 7.0 + wy)) % 11)
				b.line(Vector2(iv_x, wy + 1.0), Vector2(iv_x, wy + iv_h), Color(0.22, 0.40, 0.20), 2.0)
				b.circle(Vector2(iv_x - 1.2, wy + iv_h * 0.5), 2.2, Color(0.28, 0.48, 0.24))
				b.circle(Vector2(iv_x + 1.0, wy + iv_h), 2.0, Color(0.32, 0.54, 0.26))
				iv_x += 48.0

		# the flight of steps where the path cuts through it, with angled cheek curbs
		for k in range(4):
			var sy := wy - float(k) * (STEP_H / 4.0)
			var se: Vector2 = m.walk_edges(sy)
			b.rect(Rect2(se.x - 3.0, sy - 5.0, 4.0, STEP_H / 4.0 + 1.0), STONE.darkened(0.14))
			b.rect(Rect2(se.y - 1.0, sy - 5.0, 4.0, STEP_H / 4.0 + 1.0), STONE.darkened(0.14))
			b.rect(Rect2(se.x, sy - 3.0, se.y - se.x, 3.0), SAULO.darkened(0.22))
			b.rect(Rect2(se.x, sy - 5.0, se.y - se.x, 2.0), SAULO.lightened(0.12))

		# pier ends where the wall meets the path with terracotta flowerpots
		var pier_xs: Array[float] = [e.x - 8.0]
		if not is_mirador and not is_top_station:
			pier_xs.append(e.y + 2.0)
		for px: float in pier_xs:
			b.rect(Rect2(px, wy - 8.0, 8.0, 24.0), STONE.darkened(0.12))
			var pot_p := Vector2(px + 4.0, wy + 4.0)
			b.circle(pot_p, 5.0, Color(0.70, 0.40, 0.26))
			b.circle(pot_p, 3.8, Color(0.24, 0.45, 0.22))
			b.circle(pot_p + Vector2(-1.0, -1.0), 1.6, Color(0.92, 0.18, 0.22))

		# sentinel Italian cypress trees (xiprers) at the outer terrace edges
		if int(absf(wy)) % 600 == 0:
			_cypress(b, Vector2(rim.x + 18.0, wy - 10.0))
			_cypress(b, Vector2(rim.y - 18.0, wy - 10.0))

		# the height, cut in a stone post at every third wall (east side if near low station)
		var k3 := int(roundf((m.START_Y - 260.0 - wy) / TERRACE_STEP))
		if k3 % 3 == 1:
			var post := Vector2(e.x - 30.0, wy - 26.0)
			if m.cable_low != Vector2.ZERO and post.distance_to(m.cable_low) < 90.0:
				post = Vector2(e.y + 30.0, wy - 26.0)
			b.rect(Rect2(post.x - 12.0, post.y - 10.0, 24.0, 20.0), STONE.darkened(0.08))
			b.rect(Rect2(post.x - 12.0, post.y - 10.0, 24.0, 3.0), STONE.lightened(0.2))
			var metres := int(roundf(climb(m, wy) * TOP_M / 5.0) * 5.0)
			b.draw_string(ThemeDB.fallback_font, post + Vector2(-10, 5), "%dm" % metres,
				HORIZONTAL_ALIGNMENT_LEFT, 24, 11, Color(0.22, 0.18, 0.14))

	# scenic mirador viewpoint with balustrade and viewing telescope overlooking the city
	if mirador_y > vt - 60.0 and mirador_y < vb + 60.0:
		b.rect(Rect2(mir_e.y - 2.0, mirador_y - 11.0, mir_p.x - mir_e.y + 2.0, 22.0), STONE)
		b.rect(Rect2(mir_e.y - 2.0, mirador_y - 8.0, mir_p.x - mir_e.y + 2.0, 16.0), SAULO)
		b.circle(mir_p, 22.0, STONE)
		b.circle(mir_p, 18.0, SAULO)
		for bi in range(6):
			var ba := -0.95 + float(bi) * 0.38
			var bp := mir_p + Vector2.from_angle(ba) * 20.0
			b.circle(bp, 2.4, STONE.lightened(0.15))
			b.circle(bp, 1.5, STONE.darkened(0.25))
		b.circle(mir_p, 5.5, Color(0.22, 0.24, 0.26))
		b.rect(Rect2(mir_p.x - 2.0, mir_p.y - 7.0, 4.0, 9.0), Color(0.60, 0.62, 0.66))
		b.line(mir_p + Vector2(-3.0, -7.0), mir_p + Vector2(7.0, -13.0), Color(0.76, 0.80, 0.84), 4.0)
		b.circle(mir_p + Vector2(7.0, -13.0), 2.8, Color(0.35, 0.72, 0.88, 0.85))
	# agaves and prickly pears on the terraces, pines leaning out over the rim
	var y := floorf((vt - 120.0) / 140.0) * 140.0
	while y < vb + 120.0:
		var e2: Vector2 = m.walk_edges(y)
		var rim2 := _hill_rim_xs(m, y)
		var k := int(absf(y) / 140.0)
		for s: float in [-1.0, 1.0]:
			var inner: float = e2.x - 50.0 if s < 0.0 else e2.y + 50.0
			var outer: float = (rim2.x + 40.0) if s < 0.0 else (rim2.y - 40.0)
			if (outer - inner) * s < 60.0:
				continue
			var f := float((k * 7 + int(s + 1.0) * 3) % 10) / 10.0
			var p := Vector2(lerpf(inner, outer, 0.25 + 0.6 * f), y + float(k % 3) * 20.0)
			if FONT.grow(40.0).has_point(p) or CACTUS_BED.grow(40.0).has_point(p):
				continue
			if absf(p.y - TRAIN_Y) < 42.0 or p.distance_to(mir_p) < 44.0:
				continue
			if (m.cable_low != Vector2.ZERO and p.distance_to(m.cable_low) < 72.0) or (m.cable_top != Vector2.ZERO and p.distance_to(m.cable_top) < 72.0):
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
	# ripe cactus figs (figues de moro) on paddle rims
	b.circle(p + Vector2(8, -15), 2.4, Color(0.86, 0.32, 0.38))
	b.circle(p + Vector2(-11, -12), 2.2, Color(0.92, 0.36, 0.28))
	b.circle(p + Vector2(3, -22), 2.2, Color(0.88, 0.28, 0.42))


static func _cypress(b: ShapeBatch, p: Vector2) -> void:
	# tall slender Italian cypress (xiprer): long shadow downhill, slender dark evergreen crown
	b.polygon(PackedVector2Array([p + Vector2(2.0, 4.0), p + Vector2(9.0, 42.0), p + Vector2(-7.0, 42.0)]), Color(0, 0, 0, 0.18))
	b.polygon(PackedVector2Array([p + Vector2(0.0, -26.0), p + Vector2(7.5, 6.0), p + Vector2(5.5, 18.0), p + Vector2(-5.5, 18.0), p + Vector2(-7.5, 6.0)]), Color(0.12, 0.24, 0.14))
	b.polygon(PackedVector2Array([p + Vector2(0.0, -22.0), p + Vector2(5.5, 4.0), p + Vector2(-5.5, 4.0)]), Color(0.18, 0.34, 0.20))
	b.polygon(PackedVector2Array([p + Vector2(0.0, -14.0), p + Vector2(3.5, 10.0), p + Vector2(-3.5, 10.0)]), Color(0.24, 0.44, 0.26))
	b.circle(p + Vector2(0.0, 14.0), 5.5, Color(0.16, 0.28, 0.16))


static func _oval_pts(center: Vector2, rx: float, ry: float, segs := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


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
static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# up to the esplanade's south wall (-5030): past it freedomlayer draws sea & haze
	var gate_bot: float = m.GATE_Y - 30.0
	var y := floorf((maxf(vt, gate_bot) - 300.0) / 60.0) * 60.0
	y = maxf(y, gate_bot)
	var street := CITY_STREET
	while y < vb + 300.0:
		var h := climb(m, y + 30.0)
		var haze := 0.18 + 0.55 * h * h
		var rx := _hill_rim_xs(m, y + 30.0)
		var sea_to := lerpf(-900.0, rx.x - 10.0, clampf((h - 0.45) / 0.4, 0.0, 1.0))
		b.rect(Rect2(-400.0, y, 2100.0, 61.0), street.lerp(HAZE, haze))
		if sea_to > -400.0:
			b.rect(Rect2(-400.0, y, sea_to + 400.0, 61.0), SEA.lerp(HAZE, haze * 0.8))
		y += 60.0
	# the blocks, on their own grid so they do not jump between strips
	var cell := 64.0
	var lit: float = Game.lamp_glow()
	var by := maxf(floorf((vt - 300.0) / cell) * cell, gate_bot + 4.0)
	while by < vb + 300.0:
		var h2 := climb(m, by)
		var haze2 := 0.18 + 0.55 * h2 * h2
		var s := lerpf(1.0, 0.45, h2)            # further below, smaller
		var rx2 := _hill_rim_xs(m, by)
		var sea2 := lerpf(-900.0, rx2.x - 10.0, clampf((h2 - 0.45) / 0.4, 0.0, 1.0))
		var step := cell * s
		# the camera never leaves 0..1280 on this walk: nothing wider is seen
		var bx := -40.0
		while bx < 1320.0:
			if (bx + step < rx2.x + 26.0 or bx > rx2.y - 26.0) and bx > sea2 + 6.0:
				_block(b, Vector2(bx, by), step, haze2)
				if lit > 0.0 and (int(bx / step) + int(by / step)) % 2 == 0:
					b.glow(Vector2(bx, by), 5.0 + 9.0 * s, Color(1.0, 0.86, 0.56, lit * (1.0 - haze2 * 0.3)), 0.5)
			bx += step
		by += step
	_rim_shadow(m, b, vt, vb)
	b.flush(c)


# The hill's shade on the city below, just past each rim: one feathered strip
# a side, following the rim's wobble as draw_ground draws it.
static func _rim_shadow(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var y := maxf(floorf((vt - 300.0) / 20.0) * 20.0, m.GATE_Y - 30.0)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var rows := PackedFloat32Array()
	while y < vb + 300.0:
		var rx := _hill_rim_xs(m, y)
		left.append_array([Vector2(rx.x, y), Vector2(rx.x - RIM_SHADE_W, y)])
		right.append_array([Vector2(rx.y, y), Vector2(rx.y + RIM_SHADE_W * 1.4, y)])
		rows.append(1.0)
		y += 20.0
	if rows.size() < 2:
		return
	var fade := PackedFloat32Array([1.0, 0.0])
	b.band(left, 2, Color(0.10, 0.12, 0.16, 0.30), rows, fade)
	b.band(right, 2, Color(0.10, 0.12, 0.16, 0.38), rows, fade)


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
	var drop := Vector2(step * 0.05, step * 0.07)
	var shade := PackedVector2Array()
	for q: Vector2 in oct:
		shade.append(q + drop)
	b.polygon(shade, CITY_SHADE.lerp(HAZE, haze))
	b.polygon(oct, roof.lerp(HAZE, haze))
	# the sunlit north-west half of the ring, a shade lighter than the rest
	b.polygon(PackedVector2Array([oct[7], oct[0], oct[1], o + Vector2(w * 0.5, w * 0.5), oct[6]]),
		roof.lightened(0.10).lerp(HAZE, haze))
	var yard := w * 0.42
	var yo := o + Vector2((w - yard) * 0.5, (w - yard) * 0.5)
	b.rect(Rect2(yo, Vector2(yard, yard)), Color(0.40, 0.50, 0.34).lerp(HAZE, haze))
	b.rect(Rect2(yo, Vector2(yard, yard * 0.22)), CITY_SHADE.lerp(HAZE, haze))


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

static func build_layer(m: Node2D) -> void:
	CableCar.build(m)
	Detour.build_layer(m)


static func tick(m: Node2D, delta: float) -> void:
	tick_wind(m, delta)
	CableCar.tick(m, delta)
	Detour.tick(m, delta)


# the things on the hill, up to the gate; the kites fly over the esplanade too
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	draw_on_hill(m, wc, maxf(vt, m.GATE_Y - 30.0), vb)
	draw_kites(m, wc, vt, vb)
	if m.botanic != null:
		m.botanic.draw(m, wc, vt, vb)


static func draw_freedom(m: Node2D, c: Object) -> void:
	draw_castle_beyond(m, c)
	draw_esplanade(m, c)


# Join the castle esplanade to the hill: continue the side ramparts into a
# stone south parapet flanking the gateposts, and feather the path's sand
# smoothly into the esplanade's gravel through the gate.
static func draw_threshold(m: Node2D, b: ShapeBatch) -> void:
	var r: Rect2 = m._freedom_rect()
	var wall_y: float = float(m.GATE_Y) - 30.0
	var ge: Vector2 = m.walk_edges(m.GATE_Y - 16.0)
	var gl := maxf(float(m.gate_l), ge.x)
	var gr := minf(float(m.gate_r), ge.y)
	var esp_col := Color(0.74, 0.68, 0.56)
	# cover the ribbon's last 10px kerb stubs inside the esplanade and feather into SAULO
	b.rect(Rect2(gl - 4.0, wall_y - 14.0, gr - gl + 8.0, 22.0), esp_col)
	var grad := PackedVector2Array([
		Vector2(gl, wall_y + 8.0), Vector2(gr, wall_y + 8.0),
		Vector2(gl, m.GATE_Y + 6.0), Vector2(gr, m.GATE_Y + 6.0),
	])
	b.band(grad, 2, esp_col, PackedFloat32Array([1.0, 0.0]))
	for i in range(14):
		var px := lerpf(gl + 16.0, gr - 16.0, fmod(float(i) * 0.37 + 0.11, 1.0))
		var py := lerpf(wall_y - 6.0, m.GATE_Y + 12.0, fmod(float(i) * 0.61 + 0.17, 1.0))
		b.circle(Vector2(px, py), 1.8 + float(i % 2) * 0.7, Color(0.62, 0.56, 0.46, 0.55))
	# south rampart wall flanking the stone gateposts, turning cleanly at the side corners
	for seg: Vector2 in [Vector2(r.position.x - 34.0, gl - 26.0), Vector2(gr + 26.0, r.end.x + 34.0)]:
		if seg.y - seg.x < 8.0:
			continue
		b.rect(Rect2(seg.x, wall_y + 24.0, seg.y - seg.x, 18.0), Color(0, 0, 0, 0.18))
		b.rect(Rect2(seg.x, wall_y, seg.y - seg.x, 24.0), RAMPART)
		b.rect(Rect2(seg.x, wall_y, seg.y - seg.x, 5.0), RAMPART.lightened(0.14))
		b.rect(Rect2(seg.x, wall_y + 18.0, seg.y - seg.x, 6.0), RAMPART.darkened(0.24))
		var jx := seg.x + 28.0
		while jx < seg.y - 8.0:
			b.line(Vector2(jx, wall_y + 5.0), Vector2(jx, wall_y + 18.0), RAMPART.darkened(0.32), 1.3)
			jx += 32.0
	for cx: float in [r.position.x - 34.0, r.end.x]:
		b.rect(Rect2(cx, wall_y - 4.0, 34.0, 30.0), RAMPART)
		b.rect(Rect2(cx + 4.0, wall_y, 26.0, 22.0), RAMPART.lightened(0.10))


# The esplanade is gravel from parapet to parapet: it handles as paving, bar
# the soft ground of its tree pits and planters; the hill road is paved too.
static func surface(m: Node2D, p: Vector2) -> int:
	if absf(p.y - TRAIN_Y) < 26.0:
		return Surfaces.S.PAVEMENT
	return Surfaces.paved_past_gate(m, p, m.trees, ESPLANADE_EARTH_R)


# no grass on the cactus bed (or its path entry), round the fountain, on the
# hill road, on the telefèric station pads, or past the rims
static func grass_blocked(m: Node2D, p: Vector2) -> bool:
	if absf(p.y - TRAIN_Y) < 34.0:
		return true
	if CACTUS_BED.grow(8.0).has_point(p) or FONT.grow(16.0).has_point(p):
		return true
	var cactus_entry := Rect2(CACTUS_BED.position.x - 56.0, CACTUS_BED.position.y + 78.0, 60.0, 56.0)
	if cactus_entry.has_point(p):
		return true
	if m.cable_low != Vector2.ZERO and Rect2(m.cable_low + Vector2(-50.0, -36.0), Vector2(140.0, 72.0)).has_point(p):
		return true
	if m.cable_top != Vector2.ZERO and Rect2(m.cable_top + Vector2(-90.0, -36.0), Vector2(140.0, 72.0)).has_point(p):
		return true
	var rx := _hill_rim_xs(m, p.y)
	return p.x < rx.x + 16.0 or p.x > rx.y - 16.0


# a way marker post for a hydrant (main._draw_waymarker, shared with El Bosc)
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)
