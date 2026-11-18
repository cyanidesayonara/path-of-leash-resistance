extends RefCounted

# LA DIAGONAL: the avenue that cuts the Eixample grid at 45 degrees, walked
# up its central promenade toward Plaça de les Glòries.
#
# The world runs north-south like every walk; the camera turns 45 degrees
# (LevelBuild.CAM_ROT), so the promenade climbs to the upper right of the
# screen and the grid around it, drawn at 45 degrees in the world, reads
# square on screen with the avenue slicing across it, as on the map.
#
# Across the walk (world x): the promenade's granite with its plane trees,
# a bike lane inside each tree line, benches, a Bicing dock and a kiosk;
# then the tram's grass track (la via verda) with its rails and catenary
# masts. Three roads cross it all, square to the walk, under traffic lights. The grass holds the best smells;
# the tram rings its bell well ahead, glides through and bumps a dog on the
# rails aside. It brakes for your human, never hits them. Beyond the walls:
# the side roads, then the blocks, cut off by the avenue.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const CX := 640.0
const HALF := 300.0                    # wall to wall
const WALL_L := CX - HALF              # 340
const WALL_R := CX + HALF              # 940
const TRACK_L := 820.0                 # the grass track, to the right wall
const TRACK_X := 880.0                 # between the rails
const RAIL_GAP := 32.0                 # each rail this far off TRACK_X
const MAST_X := 820.0                  # catenary masts on the track's kerb, clear of the tram
const ROAD_W := 78.0                   # the side road each side
const WALK_W := 36.0                   # the pavement along the blocks
const BLOCK_L := WALL_L - ROAD_W - WALK_W   # where the blocks are cut off
const BLOCK_R := WALL_R + ROAD_W + WALK_W

# the grid: blocks BLOCK wide on a PITCH lattice turned 45 degrees,
# chamfered corners CHAMFER deep, built DEPTH deep round a courtyard
# (in the block's own units: GRID_SCALE of them to a world pixel, so a
# block is as big as one of L'Eixample's and its roofs are drawn as large)
const PITCH := 400.0
const BLOCK := 340.0
const CHAMFER := 56.0
const DEPTH := 96.0
const GRID_SCALE := 3.0
const GRID_D := PITCH * GRID_SCALE * 0.70710678   # lattice step along x and y

# where the lattice puts a crossing of the grid's streets on the avenue,
# a road crosses the promenade and the track, square to them, under lights
const CROSSINGS: Array[float] = [-GRID_D, -GRID_D * 3.0, -GRID_D * 5.0]
const CROSS_HALF := 37.5               # half a cross street's roadway
const BIKE_L := WALL_L + 68.0          # the bike lanes, inside each tree line
const BIKE_R := TRACK_L - 108.0
const BIKE_W := 44.0                   # two-way, as the Diagonal's are
# The walk's name and gloss lie across the promenade like every walk's, but
# centred between the two bike lanes and fitted inside them, not on the
# middle of the walls with the lanes under their ends.
const NAME_X := (BIKE_L + BIKE_W + BIKE_R) * 0.5
const NAME_ROOM := BIKE_R - (BIKE_L + BIKE_W) - 24.0
# the turned camera puts the usual spot under the top bar: a little nearer
const NAME_DOWN := 70.0

# the tram: on a timer, a bell RING_LEAD before it reaches her stretch
const TRAM_LEN := 300.0
const TRAM_HALF_W := 46.0
const TRAM_SPEED := 470.0
const TRAM_GAP_MIN := 9.0
const TRAM_GAP_MAX := 14.0
const RING_LEAD := 2.0               # the bell this long before it reaches her
const TRAM_FROM := 1500.0              # it appears this far up or down the track
const DODGE_WINDOW := 1.0              # on the rails this recently, then off: a dodge
const DODGE_PAY := 3
const HUMAN_STOP := 150.0              # it brakes this far short of your human

const KIOSK := Rect2(464.0, -2330.0, 58.0, 84.0)
const BICING := Rect2(372.0, -3560.0, 34.0, 160.0)
const PRIZE := Vector2(486.0, -3180.0)
const PRIZE_TEXT := "snatch the bocadillo off the bench"

const PROMENADE := Color(0.74, 0.72, 0.67)
const PROMENADE_LIT := Color(0.77, 0.75, 0.70)
const PROMENADE_DIM := Color(0.71, 0.69, 0.65)
const PROMENADE_JOINT := Color(0.63, 0.61, 0.57)
const SAULO := Color(0.80, 0.72, 0.56)
const SAULO_LIT := Color(0.86, 0.79, 0.64)
const SAULO_DARK := Color(0.72, 0.63, 0.47)
const SAULO_EDGE := Color(0.62, 0.60, 0.56)
const TRACK_GRASS := Color(0.38, 0.56, 0.28)
const TRACK_GRASS_MOWN := Color(0.41, 0.59, 0.30)
const TRACK_GRASS_LIT := Color(0.46, 0.64, 0.34)
const TRACK_GRASS_DARK := Color(0.32, 0.50, 0.25)
const SLEEPER := Color(0.30, 0.44, 0.24, 0.55)
const DAISY := Color(0.96, 0.95, 0.88)
const RAIL := Color(0.66, 0.66, 0.68)
const RAIL_LIT := Color(0.86, 0.86, 0.88)
const RAIL_DARK := Color(0.30, 0.30, 0.32)
const RAIL_BED := Color(0.27, 0.38, 0.22)
const KERB := Color(0.60, 0.59, 0.56)
const KERB_LIT := Color(0.70, 0.69, 0.66)
const ASPHALT := Color(0.27, 0.27, 0.29)
const ASPHALT_LIT := Color(0.30, 0.30, 0.32)
const LANE_LINE := Color(0.88, 0.87, 0.82, 0.85)
const ZEBRA := Color(0.90, 0.89, 0.84, 0.92)
const PAVEMENT := Color(0.71, 0.68, 0.63)
const PAVEMENT_JOINT := Color(0.60, 0.57, 0.52, 0.7)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
const IRON := Color(0.16, 0.17, 0.18)

# the roofscape, in L'Eixample's palette (systems/eixample.gd)
const ROOF_TONES: Array[Color] = [
	Color(0.72, 0.52, 0.40), Color(0.80, 0.66, 0.50), Color(0.66, 0.46, 0.38),
	Color(0.76, 0.60, 0.48), Color(0.74, 0.44, 0.32), Color(0.82, 0.70, 0.56),
	Color(0.70, 0.48, 0.36),
]
const FLAT_TONES: Array[Color] = [
	Color(0.70, 0.68, 0.64), Color(0.62, 0.61, 0.60), Color(0.78, 0.75, 0.68), Color(0.66, 0.60, 0.54),
]
const SHED_TONES: Array[Color] = [
	Color(0.62, 0.64, 0.66), Color(0.56, 0.57, 0.58), Color(0.70, 0.58, 0.48), Color(0.66, 0.66, 0.62),
]
const TERRAT := Color(0.74, 0.44, 0.32)
const PARAPET := Color(0.88, 0.84, 0.76)
const PARTY_WALL := Color(0.84, 0.80, 0.72)
const CORNICE := Color(0.92, 0.89, 0.82)
const COURTYARD := Color(0.36, 0.48, 0.32)
const COURTYARD_LIT := Color(0.42, 0.55, 0.35)
const HEDGE := Color(0.24, 0.40, 0.24)
const HEDGE_LIT := Color(0.32, 0.50, 0.30)
const STREET_TREE := Color(0.28, 0.44, 0.24)
const STREET_TREE_LIT := Color(0.38, 0.55, 0.30)
const STAIR_HOUSE := Color(0.84, 0.80, 0.72)
const TANK := Color(0.82, 0.82, 0.80)
const LIGHT_WELL := Color(0.17, 0.15, 0.16)
const SKYLIGHT := Color(0.56, 0.70, 0.76)
const SOLAR := Color(0.14, 0.20, 0.36)
const SOLAR_LINE := Color(0.50, 0.58, 0.72)
const WASH_LINE := Color(0.25, 0.25, 0.25, 0.7)
const WASHING: Array[Color] = [
	Color(0.94, 0.93, 0.90), Color(0.56, 0.72, 0.84), Color(0.92, 0.62, 0.56), Color(0.96, 0.86, 0.52),
]
const CUPOLA := Color(0.36, 0.44, 0.48)
const CUPOLA_LIT := Color(0.52, 0.62, 0.66)
const WATER := Color(0.40, 0.60, 0.64)
const AVENUE_DEPTH := 88.0             # the houses that front the avenue on a cut block
const CAR_TONES: Array[Color] = [
	Color(0.72, 0.18, 0.16), Color(0.86, 0.86, 0.84), Color(0.18, 0.24, 0.36),
	Color(0.52, 0.54, 0.56), Color(0.12, 0.12, 0.14), Color(0.90, 0.78, 0.22),
]
const CAR_GLASS := Color(0.22, 0.28, 0.34)

# the landmarks: which lattice block each one stands on (a, bb in _blocks)
const PUNXES_AT := Vector2i(-2, 0)
const GLORIES_AT := Vector2i(-6, 0)
const PUNXES_BRICK := Color(0.70, 0.40, 0.28)
const PUNXES_ROOF := Color(0.52, 0.27, 0.20)
const PUNXES_SPIRE := Color(0.46, 0.25, 0.20)
const PLAZA := Color(0.78, 0.76, 0.71)
const PLAZA_JOINT := Color(0.66, 0.64, 0.60)
const TORRE_FRAME := Color(0.30, 0.34, 0.40)
const TORRE_DOME := Color(0.56, 0.68, 0.78)
const TORRE_DOME_LIT := Color(0.74, 0.84, 0.90)
const TORRE_WARM: Array[Color] = [
	Color(0.78, 0.20, 0.18), Color(0.90, 0.42, 0.20), Color(0.66, 0.14, 0.24), Color(0.94, 0.62, 0.26),
]
const TORRE_COOL: Array[Color] = [
	Color(0.20, 0.36, 0.72), Color(0.36, 0.58, 0.84), Color(0.16, 0.24, 0.52), Color(0.62, 0.78, 0.90),
]

const BIKE_LANE := Color(0.60, 0.33, 0.28)
const BIKE_LANE_LINE := Color(0.93, 0.91, 0.86, 0.9)
const LIGHT_RED := Color(0.95, 0.20, 0.16)
const LIGHT_AMBER := Color(1.0, 0.72, 0.16)
const LIGHT_GREEN := Color(0.30, 0.86, 0.42)
const KIOSK_GREEN := Color(0.18, 0.36, 0.30)
const MAGAZINES: Array[Color] = [
	Color(0.90, 0.26, 0.22), Color(0.96, 0.84, 0.30), Color(0.26, 0.52, 0.80),
	Color(0.94, 0.94, 0.90), Color(0.92, 0.52, 0.70), Color(0.34, 0.68, 0.44),
]
const DOCK_BASE := Color(0.58, 0.58, 0.60)
const DOCK_BAR := Color(0.36, 0.37, 0.40)
const BICING_RED := Color(0.86, 0.14, 0.16)

const TRAM_WHITE := Color(0.95, 0.95, 0.93)
const TRAM_ROOF := Color(0.84, 0.85, 0.85)
const TRAM_GREEN := Color(0.22, 0.62, 0.40)
const TRAM_GLASS := Color(0.20, 0.28, 0.34)
const TRAM_GLASS_LIT := Color(1.0, 0.86, 0.54)
const TRAM_DOOR := Color(0.74, 0.76, 0.76)
const TRAM_EQUIP := Color(0.68, 0.70, 0.72)
const BELLOWS := Color(0.20, 0.20, 0.22)
const PANTO_CARBON := Color(0.72, 0.46, 0.24)
const HEADLIGHT := Color(1.0, 0.96, 0.80)
const TAIL_LIGHT := Color(0.90, 0.16, 0.12)
const SIGNAL_OFF := Color(0.30, 0.26, 0.18)
const SIGNAL_ON := Color(1.0, 0.72, 0.16)
const SIGNAL_BAR := Color(0.92, 0.92, 0.88)
const WIRE := Color(0.12, 0.12, 0.14, 0.75)
const MAST_ARM := Color(0.22, 0.24, 0.24, 0.95)
const INSULATOR := Color(0.80, 0.78, 0.72)


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


# --- the tram ----------------------------------------------------------------------

class Tram:
	extends RefCounted
	var y := 0.0                 # its middle along the track
	var dir := -1.0              # -1 up the walk (toward the gate), 1 down it
	var running := false
	var wait := 6.0              # to the next one
	var rang := false
	var ring_t := 0.0            # the bell's flash, for the signals
	var braking := false
	var rng := RandomNumberGenerator.new()
	var on_track_t := 99.0       # since she was last on the rails
	var passed := false          # its front has gone by her this run
	var hit_this_run := false


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return -1
	if p.x > TRACK_L and not on_cross(p):
		return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT


# no tufts where the tram runs (they would stand through its roof) or on
# the roads across the track
static func grass_blocked(_m: Node2D, p: Vector2) -> bool:
	return on_track(p) or on_cross(p, 8.0)


static func on_track(p: Vector2) -> bool:
	return p.x > TRACK_X - TRAM_HALF_W - 6.0 and p.x < TRACK_X + TRAM_HALF_W + 6.0


# on (or within `margin` of) the roadway of a road that crosses the avenue
static func on_cross(p: Vector2, margin := 0.0) -> bool:
	for y0: float in CROSSINGS:
		if absf(p.y - y0) < CROSS_HALF + margin:
			return true
	return false


# in the mouth of one of the grid's streets, where it reaches the side roads
static func _in_mouth(p: Vector2, margin: float) -> bool:
	for y0: float in CROSSINGS:
		var dx := p.x - CX
		var dy := p.y - y0
		if absf(dy) < 700.0 and minf(absf(dx + dy), absf(dy - dx)) * 0.70710678 < CROSS_HALF + margin:
			return true
	return false


static func tram_rect(t: Tram) -> Rect2:
	return Rect2(TRACK_X - TRAM_HALF_W, t.y - TRAM_LEN * 0.5, TRAM_HALF_W * 2.0, TRAM_LEN)


# --- build -------------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DE LES GLÒRIES"
	m.gate_l = CX - 200.0
	m.gate_r = CX + 200.0
	var tram := Tram.new()
	tram.rng.seed = 7341
	tram.wait = 5.0
	m.diagonal_tram = tram
	m.diagonal_tram_dodges = 0
	m.diagonal_tram_hits = 0
	m.diagonal_kiosk_barked = false
	# the plane trees, two rows down the promenade
	var y := 120.0
	var k := 0
	while y > m.GATE_Y + 120.0:
		for tx: float in [WALL_L + 44.0, TRACK_L - 40.0]:
			var ty := y + (10.0 if k % 2 == 0 else -10.0)
			if not (KIOSK.grow(50.0).has_point(Vector2(tx, ty)) or BICING.grow(50.0).has_point(Vector2(tx, ty)) \
					or on_cross(Vector2(tx, ty), 34.0)):
				m.poles.append(Vector2(tx, ty))
		y -= 190.0
		k += 1
	m.deco_pole_count = m.poles.size()
	# the catenary masts on the grass edge: real poles, the leash winds them
	y = 40.0
	while y > m.GATE_Y + 80.0:
		m.poles.append(Vector2(MAST_X, y))
		y -= 380.0
	m.benches = Array([
		Vector2(WALL_L + 136.0, -760.0), Vector2(WALL_L + 136.0, -1880.0),
		Vector2(TRACK_L - 132.0, -2760.0), Vector2(WALL_L + 136.0, -3180.0),
		Vector2(TRACK_L - 132.0, -4180.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(WALL_L + 24.0, -420.0), Vector2(TRACK_L - 24.0, -1560.0),
		Vector2(WALL_L + 24.0, -2980.0), Vector2(TRACK_L - 24.0, -3900.0),
	], TYPE_VECTOR2, &"", null)
	if "fountains" in m:
		m.fountains = Array([Vector2(WALL_L + 30.0, -1300.0), Vector2(WALL_L + 30.0, -4420.0)], TYPE_VECTOR2, &"", null)
	# marking spots: pilones on the promenade, two of them at the track's
	# kerb. Nothing stands on the track itself: the tram's path is clear.
	var hyd: Array[Vector2] = [
		Vector2(WALL_L + 20.0, -240.0), Vector2(TRACK_L - 14.0, -1180.0),
		Vector2(WALL_L + 20.0, -2160.0), Vector2(TRACK_L - 14.0, -3340.0),
		Vector2(WALL_L + 20.0, -4560.0),
	]
	var keb: Array[Vector2] = [
		Vector2(560.0, -900.0), Vector2(700.0, -2500.0), Vector2(600.0, -3800.0), Vector2(700.0, -4300.0),
	]
	return [hyd, keb]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [KIOSK, BICING]


static func wrap_rects() -> Array[Rect2]:
	return [KIOSK]


static func tree_kind(m: Node2D, p: Vector2) -> int:
	return m.TREE_NONE if absf(p.x - MAST_X) < 1.0 else m.TREE_STREET


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return absf(p.x - MAST_X) < 1.0


# --- per frame ---------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	var t: Tram = m.diagonal_tram
	if t == null or m.phase == "freedom" or m.get("frozen") == true:
		return
	var dog: Vector2 = m.dog.global_position
	var her_y := dog.y
	t.on_track_t = 0.0 if on_track(dog) else t.on_track_t + delta
	t.ring_t = maxf(0.0, t.ring_t - delta)
	if not t.running:
		t.wait -= delta
		if t.wait <= 0.0:
			# the bell as it comes into the stretch, just off the screen: it
			# reaches her RING_LEAD later, so the bell means now
			t.dir = -1.0 if t.rng.randf() < 0.5 else 1.0
			t.rang = true
			t.ring_t = RING_LEAD
			Sfx.play("crossing_bell", 1.0, -4.0)
			m.feed.say("TRAM COMING! OFF THE TRACKS", EventFeed.Tone.LOUD)
			m.float_text(Vector2(TRACK_X, her_y - 60.0), "ding ding!", Color(1.0, 0.9, 0.5))
			t.running = true
			t.passed = false
			t.hit_this_run = false
			t.y = her_y - t.dir * (TRAM_SPEED * RING_LEAD + TRAM_LEN * 0.5)
		return
	# brake for your human on the rails
	var hum: Vector2 = m.human.global_position
	var front := t.y + t.dir * TRAM_LEN * 0.5
	var ahead := (hum.y - front) * t.dir
	t.braking = on_track(hum) and ahead > 0.0 and ahead < HUMAN_STOP
	if t.braking:
		if t.ring_t <= 0.0:
			t.ring_t = 0.6
			Sfx.play("bell", 0.9, -6.0)
	else:
		t.y += t.dir * TRAM_SPEED * delta
	var r := tram_rect(t)
	# a dog on the rails as it comes through is bumped off them
	if not t.hit_this_run and r.grow(4.0).has_point(dog) and m.dog.tumble_t <= 0.0:
		t.hit_this_run = true
		m.diagonal_tram_hits += 1
		var side := -1.0 if dog.x < TRACK_X + 10.0 else 1.0
		m.dog.knocked(Vector2(side, t.dir * 0.4).normalized(), "tram")
		m.feed.say("CLANG! THE TRAM BUMPED YOU", EventFeed.Tone.LOUD)
	# its front going by her: off the rails just in time is a dodge
	if not t.passed and (front - her_y) * t.dir > 0.0:
		t.passed = true
		if not t.hit_this_run and t.on_track_t > 0.0 and t.on_track_t < DODGE_WINDOW:
			m.diagonal_tram_dodges += 1
			m.combo.add("TRAM", DODGE_PAY)
			m.award_points(DODGE_PAY, "close shave! +%d" % DODGE_PAY)
	# gone out the far side: the next one
	if (t.y - her_y) * t.dir > TRAM_FROM:
		t.running = false
		t.rang = false
		t.wait = t.rng.randf_range(TRAM_GAP_MIN, TRAM_GAP_MAX)


# --- riders: the two bike lanes and the lights at the crossings --------------------

# The lights at the crossings, on the walk's own clock so riders and the
# lamps agree in every run: green for the promenade, amber, then red while
# the cross street goes. 0 red, 1 amber, 2 green.
const LIGHT_CYCLE := 14.0
const GREEN_T := 6.0
const AMBER_T := 1.0
const STOP_BACK := 8.0                 # a rider's stop line, this far short of the roadway
const OVERRUN := 16.0                  # how far over the line a stopping rider may roll
const AMBER_GO := 70.0                 # nearer the line than this on amber, they ride on


static func light(m: Node2D) -> int:
	var ph := fmod(float(m.get("elapsed")), LIGHT_CYCLE)
	if ph < GREEN_T:
		return 2
	return 1 if ph < GREEN_T + AMBER_T else 0


# Riders on the Diagonal keep to its two bike lanes, inside the tree lines,
# both of them two-way: a commuter, a courier, a Bicing, now and then a kid.
static func rider_lane(_m: Node2D, _up: bool) -> Dictionary:
	var kid := randf() < 0.12
	var speed := randf_range(80.0, 120.0) if kid else randf_range(280.0, 400.0)
	var bx := BIKE_L if randf() < 0.5 else BIKE_R
	var lo := bx + 7.0
	var hi := bx + BIKE_W - 7.0
	return {"kid": kid, "speed": speed, "x": randf_range(lo, hi), "lo": lo, "hi": hi}


# How far a rider at `p` riding along `fwd` is from the stop line they must
# stop at, or -1 to ride on: the lights at the next crossing ahead, red, or
# amber with room to stop. A rider who has come a touch over it while
# stopping still stops there; one well over (in the crossing) rides on.
static func rider_hold(m: Node2D, p: Vector2, fwd: Vector2) -> float:
	if absf(fwd.y) < 0.5:
		return -1.0
	var lt := light(m)
	if lt == 2:
		return -1.0
	var best := -1.0
	for y0: float in CROSSINGS:
		var line_y := y0 - signf(fwd.y) * (CROSS_HALF + STOP_BACK)
		var d := (line_y - p.y) * signf(fwd.y)
		if d < -OVERRUN or d > 600.0:
			continue
		if lt == 1 and d < AMBER_GO:
			continue
		if best < 0.0 or d < best:
			best = maxf(d, 0.0)
	return best


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = m.dog.global_position if pos == Vector2.ZERO else pos
	if not m.diagonal_kiosk_barked and KIOSK.grow(70.0).has_point(p):
		m.diagonal_kiosk_barked = true
		m.award_points(2, "woof at the news! +2")
		return true
	return false


static func idle_status(m: Node2D) -> String:
	var t: Tram = m.diagonal_tram
	if t != null and t.rang and on_track(m.dog.global_position):
		return I18n.t("walk_diagonal_tram")
	return ""


# --- ground: the promenade and the track ---------------------------------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo: float = maxf(vt - 30.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_ground(wc, lo, hi)
	wc.lod = keep_lod


static func _ground(wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.rect(Rect2(WALL_L, lo, TRACK_L - WALL_L, hi - lo), PROMENADE)
	# granite slabs in staggered rows, no two quite the same grey
	var row := int(floorf(lo / 64.0))
	var sy := float(row) * 64.0
	while sy < hi:
		var sx := WALL_L + (0.0 if row % 2 == 0 else 48.0) - 96.0
		var col := 0
		while sx < TRACK_L:
			var h := _h(row * 53 + col * 17)
			var x0 := maxf(sx, WALL_L)
			var x1 := minf(sx + 96.0, TRACK_L)
			if h > 0.5 and x1 > x0:
				wc.rect(Rect2(x0, sy, x1 - x0, 64.0), PROMENADE_LIT if h > 0.78 else PROMENADE_DIM)
			if sx > WALL_L:
				wc.line(Vector2(sx, sy), Vector2(sx, sy + 64.0), PROMENADE_JOINT, 1.1)
			sx += 96.0
			col += 1
		wc.line(Vector2(WALL_L, sy), Vector2(TRACK_L, sy), PROMENADE_JOINT, 1.3)
		row += 1
		sy += 64.0
	# a strip of sauló down each row of plane trees, edged in stone
	for tx: float in [WALL_L + 44.0, TRACK_L - 40.0]:
		wc.rect(Rect2(tx - 24.0, lo, 48.0, hi - lo), SAULO_EDGE)
		wc.rect(Rect2(tx - 21.0, lo, 42.0, hi - lo), SAULO)
		var py := floorf(lo / 22.0) * 22.0
		while py < hi:
			var k := int(py) * 3 + int(tx)
			wc.circle(Vector2(tx - 17.0 + _h(k) * 34.0, py + _h(k * 3) * 18.0), 1.4 + _h(k * 7) * 1.8,
				SAULO_DARK if _h(k * 5) > 0.45 else SAULO_LIT)
			py += 22.0
	# the bike lanes inside each tree line: red asphalt between white
	# lines, a dashed middle, a bike painted on it now and then
	for bx: float in [BIKE_L, BIKE_R]:
		wc.rect(Rect2(bx, lo, BIKE_W, hi - lo), BIKE_LANE)
		wc.rect(Rect2(bx, lo, 1.6, hi - lo), BIKE_LANE_LINE)
		wc.rect(Rect2(bx + BIKE_W - 1.6, lo, 1.6, hi - lo), BIKE_LANE_LINE)
		var by := floorf(lo / 40.0) * 40.0
		while by < hi:
			wc.rect(Rect2(bx + BIKE_W * 0.5 - 0.6, by, 1.2, 18.0), BIKE_LANE_LINE)
			by += 40.0
		by = floorf(lo / 520.0) * 520.0 + 130.0
		while by < hi + 40.0:
			for s: float in [-1.0, 1.0]:
				var g := Vector2(bx + BIKE_W * 0.5 + s * 11.0, by + s * 60.0)
				# the arrow of that side's direction, ahead of its bike
				var tip := g + Vector2(0.0, s * 34.0)
				wc.line(g + Vector2(0.0, s * 14.0), tip - Vector2(0.0, s * 6.0), BIKE_LANE_LINE, 1.6)
				wc.polygon(PackedVector2Array([tip, tip + Vector2(-4.5, -s * 8.0), tip + Vector2(4.5, -s * 8.0)]), BIKE_LANE_LINE)
				wc.circle(g + Vector2(0.0, -5.0), 3.2, BIKE_LANE_LINE)
				wc.circle(g + Vector2(0.0, -5.0), 2.0, BIKE_LANE)
				wc.circle(g + Vector2(0.0, 5.0), 3.2, BIKE_LANE_LINE)
				wc.circle(g + Vector2(0.0, 5.0), 2.0, BIKE_LANE)
				wc.line(g + Vector2(0.0, -5.0), g + Vector2(0.0, 5.0), BIKE_LANE_LINE, 1.2)
				wc.line(g + Vector2(-2.5, s * -2.0), g + Vector2(2.5, s * -2.0), BIKE_LANE_LINE, 1.2)
			by += 520.0
	# la via verda: mown grass, the sleepers showing faintly through it
	wc.rect(Rect2(TRACK_L, lo, WALL_R - TRACK_L, hi - lo), TRACK_GRASS)
	var my := floorf(lo / 150.0) * 150.0
	while my < hi:
		wc.rect(Rect2(TRACK_L, my, WALL_R - TRACK_L, 75.0), TRACK_GRASS_MOWN)
		my += 150.0
	var ty := floorf(lo / 34.0) * 34.0
	while ty < hi:
		wc.rect(Rect2(TRACK_X - RAIL_GAP - 13.0, ty, RAIL_GAP * 2.0 + 26.0, 9.0), SLEEPER)
		ty += 34.0
	var gy := floorf(lo / 23.0) * 23.0
	while gy < hi:
		var gk := int(gy)
		var gx := TRACK_L + 8.0 + _h(gk) * (WALL_R - TRACK_L - 16.0)
		var gh := _h(gk * 3 + 1)
		if gh < 0.5:
			wc.circle(Vector2(gx, gy), 5.0 + gh * 12.0, TRACK_GRASS_LIT)
		elif gh < 0.8:
			wc.circle(Vector2(gx, gy), 3.0 + gh * 5.0, TRACK_GRASS_DARK)
		else:
			# daisies in the grass
			for i in range(3):
				wc.circle(Vector2(gx + _h(gk + i) * 14.0, gy + _h(gk * 5 + i) * 12.0), 1.5, DAISY)
		gy += 23.0
	# the kerb between the paving and the grass, stone by stone
	wc.rect(Rect2(TRACK_L - 5.0, lo, 8.0, hi - lo), KERB)
	wc.rect(Rect2(TRACK_L - 5.0, lo, 2.0, hi - lo), KERB_LIT)
	var ky := floorf(lo / 48.0) * 48.0
	while ky < hi:
		wc.rect(Rect2(TRACK_L - 5.0, ky, 8.0, 1.2), PROMENADE_JOINT)
		ky += 48.0
	for y0: float in CROSSINGS:
		if y0 + 60.0 > lo and y0 - 60.0 < hi:
			_cross_ground(wc, y0)
	# grooved rails set flush in the grass (and in the roadway)
	for s: float in [-1.0, 1.0]:
		var rx := TRACK_X + s * RAIL_GAP
		wc.rect(Rect2(rx - 4.5, lo, 9.0, hi - lo), RAIL_BED)
		wc.rect(Rect2(rx - 2.5, lo, 5.0, hi - lo), RAIL_DARK)
		wc.rect(Rect2(rx - 2.5, lo, 2.6, hi - lo), RAIL)
		wc.rect(Rect2(rx - 2.0, lo, 0.9, hi - lo), RAIL_LIT)
	if KIOSK.end.y + 30.0 > lo and KIOSK.position.y - 30.0 < hi:
		_kiosk(wc)
	if BICING.end.y + 30.0 > lo and BICING.position.y - 30.0 < hi:
		_bicing(wc)


# a crossing: a roadway between kerbs straight across the promenade and
# the track, stop lines, and a zebra for the promenade's walkers
static func _cross_ground(wc: ShapeBatch, y0: float) -> void:
	var w := WALL_R - WALL_L
	wc.rect(Rect2(WALL_L, y0 - CROSS_HALF - 5.0, w, CROSS_HALF * 2.0 + 10.0), KERB)
	wc.rect(Rect2(WALL_L, y0 - CROSS_HALF - 5.0, w, 1.6), KERB_LIT)
	wc.rect(Rect2(WALL_L, y0 - CROSS_HALF, w, CROSS_HALF * 2.0), ASPHALT_LIT)
	const Z0 := 470.0
	const Z1 := 694.0
	for i in range(5):
		wc.rect(Rect2(Z0, y0 - 31.0 + float(i) * 13.5, Z1 - Z0, 8.0), ZEBRA)
	for x: float in [Z0 - 16.0, Z1 + 12.0]:
		wc.rect(Rect2(x, y0 - CROSS_HALF + 3.0, 4.0, CROSS_HALF * 2.0 - 6.0), LANE_LINE)
	# the bike lanes cross between dashes of their own
	for bx: float in [BIKE_L, BIKE_R]:
		for e: float in [bx - 1.0, bx + BIKE_W - 3.0]:
			for i in range(5):
				wc.rect(Rect2(e, y0 - 33.0 + float(i) * 14.5, 4.0, 8.0), BIKE_LANE_LINE)


# the newspaper kiosk: a green iron box under a ribbed roof, its shutters
# folded out into racks of magazines on the promenade's side
static func _kiosk(wc: ShapeBatch) -> void:
	var r := KIOSK
	var l: Vector2 = Shade.light
	wc.rect(Rect2(r.position + l * 14.0 - Vector2(3.0, 3.0), r.size + Vector2(18.0, 6.0)), SHADOW)
	# the racks: the long side and both ends
	wc.rect(Rect2(r.end.x, r.position.y + 4.0, 15.0, r.size.y - 8.0), KIOSK_GREEN.darkened(0.45))
	var my := r.position.y + 7.0
	var i := 0
	while my < r.end.y - 12.0:
		for j in range(2):
			wc.rect(Rect2(r.end.x + 1.5 + float(j) * 6.5, my, 5.5, 7.5), MAGAZINES[(i * 3 + j * 5) % MAGAZINES.size()])
		my += 9.5
		i += 1
	for e: float in [r.position.y - 7.0, r.end.y]:
		wc.rect(Rect2(r.position.x + 6.0, e, r.size.x - 12.0, 7.0), KIOSK_GREEN.darkened(0.45))
		for j in range(5):
			wc.rect(Rect2(r.position.x + 8.0 + float(j) * 8.6, e + 1.0, 7.0, 5.0), MAGAZINES[(j * 2 + int(e)) % MAGAZINES.size()])
	# the roof: an overhanging rim, ribs, a raised lantern down the middle
	wc.rect(r.grow(3.0), KIOSK_GREEN.darkened(0.3))
	wc.rect(r, KIOSK_GREEN)
	var ry := r.position.y + 8.0
	while ry < r.end.y - 4.0:
		wc.rect(Rect2(r.position.x + 2.0, ry, r.size.x - 4.0, 1.4), KIOSK_GREEN.darkened(0.18))
		ry += 9.0
	wc.rect(Rect2(r.position.x + 17.0, r.position.y + 10.0, r.size.x - 34.0, r.size.y - 20.0), KIOSK_GREEN.darkened(0.2))
	wc.rect(Rect2(r.position.x + 19.0, r.position.y + 12.0, r.size.x - 38.0, r.size.y - 24.0), KIOSK_GREEN.lightened(0.16))
	wc.rect(Rect2(r.position.x - 3.0, r.position.y - 3.0, 2.0, r.size.y + 6.0), KIOSK_GREEN.lightened(0.25))
	wc.circle(r.get_center(), 3.5, Color(0.86, 0.72, 0.30))


# the Bicing dock: a row of red-and-white bikes nosed into their posts,
# the terminal at the end
static func _bicing(wc: ShapeBatch) -> void:
	var r := BICING
	var l: Vector2 = Shade.light
	wc.rect(r, DOCK_BASE)
	wc.rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, 5.0, r.size.y - 4.0), DOCK_BAR)
	wc.rect(Rect2(r.position + Vector2(3.0, 3.0) + l * 6.0, Vector2(13.0, 13.0)), SHADOW)
	wc.rect(Rect2(r.position + Vector2(3.0, 3.0), Vector2(13.0, 13.0)), IRON)
	wc.rect(Rect2(r.position + Vector2(5.0, 5.0), Vector2(9.0, 5.0)), BICING_RED)
	for i in range(7):
		var by := r.position.y + 28.0 + float(i) * 19.0
		var x := r.position.x
		wc.circle(Vector2(x + 4.5, by), 3.0, IRON)
		if _h(i * 7 + 2) < 0.22:
			continue        # this one is out on a ride
		wc.line(Vector2(x + 8.0, by) + l * 4.0, Vector2(x + 33.0, by) + l * 4.0, SHADOW, 5.0)
		wc.line(Vector2(x + 7.0, by), Vector2(x + 15.0, by), IRON, 3.0)
		wc.line(Vector2(x + 25.0, by), Vector2(x + 33.0, by), IRON, 3.0)
		wc.line(Vector2(x + 11.0, by), Vector2(x + 29.0, by), BICING_RED, 2.6)
		wc.line(Vector2(x + 24.0, by), Vector2(x + 33.0, by), TRAM_WHITE, 1.6)
		wc.line(Vector2(x + 12.0, by - 5.5), Vector2(x + 12.0, by + 5.5), IRON, 1.8)
		wc.rect(Rect2(x + 6.0, by - 3.5, 4.5, 7.0), BICING_RED.darkened(0.2))
		wc.circle(Vector2(x + 23.0, by), 2.6, IRON)


# --- beyond the walls: roads, pavements and the grid cut off by the avenue -------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 400.0, float(m.GATE_Y) - 40.0)
	var hi := minf(vb + 400.0, float(m.START_Y) + 700.0)
	if hi > lo:
		_edges(b, lo, hi)
	b.lod = keep_lod


static func _edges(b: ShapeBatch, lo: float, hi: float) -> void:
	# the streets of the grid show wherever there is no block
	b.rect(Rect2(-900.0, lo, 3080.0, hi - lo), ASPHALT)
	# the side roads: a lane line, a kerb on the promenade's side, a row of
	# parked cars and motos along the panot pavement under the blocks
	for side: float in [-1.0, 1.0]:
		var wall := WALL_L if side < 0.0 else WALL_R
		var walk_x := wall + side * ROAD_W
		var road_mid := walk_x - side * 37.0     # the parking lane's line
		b.rect(Rect2(minf(wall, wall + side * ROAD_W), lo, ROAD_W, hi - lo), ASPHALT_LIT)
		var dy := floorf(lo / 80.0) * 80.0
		while dy < hi:
			b.rect(Rect2(road_mid - 1.5, dy, 3.0, 40.0), LANE_LINE)
			dy += 80.0
		b.rect(Rect2(wall - (8.0 if side > 0.0 else 0.0), lo, 8.0, hi - lo), KERB)
		b.rect(Rect2(wall - (8.0 if side > 0.0 else -6.0), lo, 2.0, hi - lo), KERB_LIT)
		var wx := minf(walk_x, walk_x + side * WALK_W)
		b.rect(Rect2(wx, lo, WALK_W, hi - lo), PAVEMENT)
		b.rect(Rect2(walk_x - (3.0 if side < 0.0 else 0.0), lo, 3.0, hi - lo), KERB)
		var jy := floorf(lo / 18.0) * 18.0
		while jy < hi:
			b.rect(Rect2(wx, jy, WALK_W, 1.0), PAVEMENT_JOINT)
			jy += 18.0
		b.rect(Rect2(wx + 18.0, lo, 1.0, hi - lo), PAVEMENT_JOINT)
		# the parking lane
		var park_x := walk_x - side * 19.0
		var slot := int(floorf(lo / 112.0))
		while float(slot) * 112.0 < hi:
			var h := _h(slot * 29 + (7 if side > 0.0 else 3))
			var py := float(slot) * 112.0
			if on_cross(Vector2(park_x, py + 54.0), 60.0) or _in_mouth(Vector2(park_x, py + 20.0), 30.0) \
					or _in_mouth(Vector2(park_x, py + 90.0), 30.0):
				pass
			elif h < 0.52:
				_car(b, Vector2(park_x, py + 54.0), CAR_TONES[int(h * 97.0) % CAR_TONES.size()])
			elif h < 0.72:
				for i in range(4):
					_moto(b, Vector2(park_x - side * 3.0, py + 22.0 + float(i) * 20.0), side, slot * 5 + i)
			slot += 1
	# the cross streets come through the pavements to the avenue
	var r2 := sqrt(0.5)
	var span := PackedVector2Array([Vector2(BLOCK_L - 4.0, lo), Vector2(BLOCK_R + 4.0, lo),
		Vector2(BLOCK_R + 4.0, hi), Vector2(BLOCK_L - 4.0, hi)])
	for y0: float in CROSSINGS:
		if y0 + 900.0 < lo or y0 - 900.0 > hi:
			continue
		for f: Transform2D in [Transform2D(Vector2(r2, r2), Vector2(-r2, r2), Vector2(CX, y0)),
				Transform2D(Vector2(-r2, r2), Vector2(-r2, -r2), Vector2(CX, y0))]:
			var band := f * PackedVector2Array([Vector2(-700.0, -CROSS_HALF), Vector2(700.0, -CROSS_HALF),
				Vector2(700.0, CROSS_HALF), Vector2(-700.0, CROSS_HALF)])
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(band, span):
				b.polygon(poly, ASPHALT)
		# and the road across the avenue opens through both kerbs
		b.rect(Rect2(WALL_L - 2.0, y0 - CROSS_HALF, WALL_R - WALL_L + 4.0, CROSS_HALF * 2.0), ASPHALT_LIT)
	_blocks(b, lo, hi)


static func _car(b: ShapeBatch, p: Vector2, col: Color) -> void:
	var l: Vector2 = Shade.light
	b.rect(Rect2(p - Vector2(15.0, 41.0) + l * 5.0, Vector2(30.0, 82.0)), SHADOW)
	b.rect(Rect2(p - Vector2(15.0, 37.0), Vector2(30.0, 74.0)), col)
	b.rect(Rect2(p - Vector2(13.0, 41.0), Vector2(26.0, 82.0)), col)
	b.rect(Rect2(p - Vector2(12.0, 22.0), Vector2(24.0, 46.0)), CAR_GLASS)
	b.rect(Rect2(p - Vector2(11.0, 11.0), Vector2(22.0, 26.0)), col.lightened(0.12))
	b.rect(Rect2(p - Vector2(13.0, 41.0), Vector2(26.0, 2.0)), col.darkened(0.25))


static func _moto(b: ShapeBatch, p: Vector2, side: float, k: int) -> void:
	var a := p - Vector2(side * 11.0, 3.0)
	var c := p + Vector2(side * 11.0, 3.0)
	b.line(a + Shade.light * 3.0, c + Shade.light * 3.0, SHADOW, 6.0)
	b.line(a, c, IRON, 4.0)
	b.line(a.lerp(c, 0.3), a.lerp(c, 0.75), CAR_TONES[k % CAR_TONES.size()], 5.5)
	b.circle(a.lerp(c, 0.42), 3.0, IRON)


# --- the grid ------------------------------------------------------------------------

# what is kept of a block the avenue cuts: everything left of the left
# pavement (cs < 0) or right of the right one (cs > 0); 0 is a whole block
static var _clip_l := PackedVector2Array([Vector2(-9000.0, -90000.0), Vector2(BLOCK_L, -90000.0),
	Vector2(BLOCK_L, 90000.0), Vector2(-9000.0, 90000.0)])
static var _clip_r := PackedVector2Array([Vector2(BLOCK_R, -90000.0), Vector2(9000.0, -90000.0),
	Vector2(9000.0, 90000.0), Vector2(BLOCK_R, 90000.0)])


static func _in(p: Vector2, cs: int, pad := 0.0) -> bool:
	if cs == 0:
		return true
	return p.x + pad < BLOCK_L if cs < 0 else p.x - pad > BLOCK_R


# a polygon, clipped only if the avenue really crosses it
static func _cpoly(b: ShapeBatch, pts: PackedVector2Array, col: Color, cs: int) -> void:
	if cs != 0:
		var n := 0
		for p: Vector2 in pts:
			if _in(p, cs):
				n += 1
		if n == 0:
			return
		if n < pts.size():
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(pts, _clip_l if cs < 0 else _clip_r):
				b.polygon(poly, col)
			return
	b.polygon(pts, col)


# a rectangle along a frame's own axes (a block's, a side's): turned in the
# world, square on screen
static func _lq(b: ShapeBatch, f: Transform2D, x0: float, y0: float, x1: float, y1: float, col: Color, cs: int, off := Vector2.ZERO) -> void:
	off *= f.x.length()
	var p0 := f * Vector2(x0, y0) + off
	var p1 := f * Vector2(x1, y0) + off
	var p2 := f * Vector2(x1, y1) + off
	var p3 := f * Vector2(x0, y1) + off
	if cs != 0:
		var n := int(_in(p0, cs)) + int(_in(p1, cs)) + int(_in(p2, cs)) + int(_in(p3, cs))
		if n == 0:
			return
		if n < 4:
			_cpoly(b, PackedVector2Array([p0, p1, p2, p3]), col, cs)
			return
	b.quad(p0, p1, p2, p3, col)


static func _ld(b: ShapeBatch, f: Transform2D, x: float, y: float, r: float, col: Color, cs: int, off := Vector2.ZERO) -> void:
	var k := f.x.length()
	r *= k
	var p := f * Vector2(x, y) + off * k
	if _in(p, cs, r):
		b.circle(p, r, col)


static func _ll(b: ShapeBatch, f: Transform2D, x0: float, y0: float, x1: float, y1: float, col: Color, w: float, cs: int) -> void:
	var p0 := f * Vector2(x0, y0)
	var p1 := f * Vector2(x1, y1)
	if _in(p0, cs) and _in(p1, cs):
		b.line(p0, p1, col, w * f.x.length())


static var _row_cache := {}


# 0 = wholly inside the clip half-plane, 2 = wholly outside (skip), cs = straddling
static func _box_cs(f: Transform2D, x0: float, y0: float, x1: float, y1: float, cs: int, pad := 0.0) -> int:
	if cs == 0:
		return 0
	var ax := f.x.x * (x0 - pad)
	var bx := f.x.x * (x1 + pad)
	var cy := f.y.x * (y0 - pad)
	var dy := f.y.x * (y1 + pad)
	var xmin := f.origin.x + minf(ax, bx) + minf(cy, dy)
	var xmax := f.origin.x + maxf(ax, bx) + maxf(cy, dy)
	if cs < 0:
		if xmin >= BLOCK_L:
			return 2
		if xmax < BLOCK_L:
			return 0
	else:
		if xmax <= BLOCK_R:
			return 2
		if xmin > BLOCK_R:
			return 0
	return cs


static func _row(b: ShapeBatch, a: int, u: Vector2, v: Vector2, d: float, reach: float) -> void:
	# far enough out to fill the turned view's corners, no further
	for bb in range(-2, 3):
		var c := Vector2(CX + float(bb) * d, float(a) * d)
		if (a + bb) % 2 != 0:
			if bb != 0:
				_crossing(b, Transform2D(u, v, c), -1 if c.x < CX else 1)
			continue
		# wholly on one side: drawn as it is. Cut by the avenue:
		# clipped, the only blocks that pay for a clip; one the avenue
		# runs through the middle of leaves a wedge on each side.
		if c.x + reach < BLOCK_L or c.x - reach > BLOCK_R:
			_block(b, c, u, v, a * 31 + bb * 7, 0)
			continue
		for cs: int in [-1, 1]:
			if (cs < 0 and c.x - reach >= BLOCK_L) or (cs > 0 and c.x + reach <= BLOCK_R):
				continue
			if cs < 0 and a == PUNXES_AT.x and bb == PUNXES_AT.y:
				_punxes(b, c, u, v)
			elif cs > 0 and a == GLORIES_AT.x and bb == GLORIES_AT.y:
				_glories(b, c, u, v)
			else:
				_block(b, c, u, v, a * 31 + bb * 7 + cs, cs)


# The blocks on the turned lattice, and the crossings between them. Each
# block is a chamfered square BLOCK wide, built DEPTH deep round a
# courtyard, and clipped where the avenue cuts it.
static func _blocks(b: ShapeBatch, lo: float, hi: float) -> void:
	var r2 := sqrt(0.5)
	var u := Vector2(r2, r2)
	var v := Vector2(-r2, r2)
	var d := GRID_D
	u *= GRID_SCALE
	v *= GRID_SCALE
	# a block's corners reach this far from its middle, along x and y
	var reach := BLOCK * GRID_SCALE * r2
	var a0 := int(floorf((lo - reach - 80.0) / d))
	var a1 := int(ceilf((hi + reach + 80.0) / d))
	for a in range(a0, a1 + 1):
		var key := [a, Shade.light, b.lod]
		var rec: ShapeBatch = _row_cache.get(key)
		if rec == null:
			if _row_cache.size() > 64:
				_row_cache.clear()
			rec = ShapeBatch.new()
			rec.lod = b.lod
			_row(rec, a, u, v, d, reach)
			_row_cache[key] = rec
		rec.append_to(b)


# where four chamfers face each other: a zebra across each street mouth
static func _crossing(b: ShapeBatch, f: Transform2D, cs: int) -> void:
	for arm in range(4):
		var g := f * Transform2D(float(arm) * PI * 0.5, Vector2.ZERO)
		if not (_in(g * Vector2(88.0, -12.0), cs, 40.0) and _in(g * Vector2(100.0, 12.0), cs, 40.0)):
			continue
		for i in range(5):
			var y := -10.6 + float(i) * 4.6
			_lq(b, g, 88.0, y, 100.0, y + 2.6, ZEBRA, 0)


# one block from above: a ring of houses round a courtyard, each plot its
# own terrat inside its parapets, the corner houses on the chamfers, plane
# trees along the pavement; where the avenue cuts it, a row of houses
# fronting the avenue. Everything is built along the block's own axes.
static func _block(b: ShapeBatch, c: Vector2, u: Vector2, v: Vector2, salt: int, cs: int) -> void:
	var s := BLOCK * 0.5
	var l: Vector2 = Shade.light
	var f := Transform2D(u, v, c)
	_cpoly(b, _octagon(c, u, v, s + 18.6, CHAMFER + 9.6), KERB, cs)
	_cpoly(b, _octagon(c, u, v, s + 17.5, CHAMFER + 9.0), PAVEMENT, cs)
	var oct := _octagon(c, u, v, s, CHAMFER)
	var kept: Array = [oct] if cs == 0 else Geometry2D.intersect_polygons(oct, _clip_l if cs < 0 else _clip_r)
	for poly: PackedVector2Array in kept:
		b.polygon(Transform2D(0.0, l * 44.0) * poly, SHADOW)
		b.polygon(poly, PARTY_WALL)
	_cpoly(b, _octagon(c, u, v, s - DEPTH * 0.6, 44.0), COURTYARD, cs)
	_courtyard(b, f, salt, cs)
	for r in range(4):
		_side(b, f * Transform2D(float(r) * PI * 0.5, Vector2.ZERO), salt * 4 + r, cs)
	if cs != 0:
		_avenue_front(b, c, oct, salt, cs)


# inside the block: a garden with sauló paths, or the low workshop roofs
# that fill so many Eixample courtyards, and trees either way
static func _courtyard(b: ShapeBatch, f: Transform2D, salt: int, cs: int) -> void:
	cs = _box_cs(f, -80.0, -80.0, 80.0, 80.0, cs, 20.0)
	if cs == 2:
		return
	var l: Vector2 = Shade.light
	var trees := 5
	if _h(salt * 13 + 5) < 0.4:
		trees = 2
		for i in range(3):
			for j in range(3):
				var k := salt * 9 + i * 3 + j
				if _h(k) < 0.25:
					continue
				var x0 := -62.0 + float(i) * 42.0
				var y0 := -62.0 + float(j) * 42.0
				var tone: Color = SHED_TONES[int(_h(k * 3) * 97.0) % SHED_TONES.size()]
				_lq(b, f, x0, y0, x0 + 40.0, y0 + 40.0, tone.darkened(0.2), cs)
				_lq(b, f, x0 + 1.5, y0 + 1.5, x0 + 38.5, y0 + 38.5, tone, cs)
				if _h(k * 5) < 0.5:
					_lq(b, f, x0 + 19.0, y0 + 1.5, x0 + 21.0, y0 + 38.5, tone.darkened(0.14), cs)
					_lq(b, f, x0 + 1.5, y0 + 1.5, x0 + 19.0, y0 + 38.5, tone.lightened(0.07), cs)
				else:
					_lq(b, f, x0 + 8.0, y0 + 14.0, x0 + 32.0, y0 + 24.0, SKYLIGHT, cs)
					_lq(b, f, x0 + 19.5, y0 + 14.0, x0 + 20.5, y0 + 24.0, tone.darkened(0.2), cs)
	else:
		_lq(b, f, -66.0, -5.0, 66.0, 5.0, SAULO, cs)
		_lq(b, f, -5.0, -66.0, 5.0, 66.0, SAULO, cs)
		_ld(b, f, 0.0, 0.0, 15.0, SAULO, cs)
		_ld(b, f, 0.0, 0.0, 7.0, HEDGE_LIT if _h(salt) < 0.5 else WATER, cs)
		for q: Vector2 in [Vector2(-34.0, -34.0), Vector2(34.0, 34.0)]:
			_lq(b, f, q.x - 20.0, q.y - 20.0, q.x + 20.0, q.y + 20.0, COURTYARD_LIT, cs)
	for i in range(trees):
		var tx := (_h(salt + i * 3) - 0.5) * 104.0
		var ty := (_h(salt * 3 + i * 7) - 0.5) * 104.0
		var tr := 8.0 + _h(salt + i) * 4.0
		_ld(b, f, tx, ty, tr, SHADOW, cs, l * 7.0)
		_ld(b, f, tx, ty, tr, HEDGE, cs)
		_ld(b, f, tx, ty, tr * 0.62, HEDGE_LIT, cs, -l * 3.5)


# one side of the block in its own frame: the street front along y = s, the
# plots between the two corner houses, this side's corner house, the plane
# trees on the pavement
static func _side(b: ShapeBatch, f: Transform2D, salt: int, cs: int) -> void:
	cs = _box_cs(f, -115.0, BLOCK * 0.5 - DEPTH * 1.2 - 16.0, BLOCK * 0.5 + 16.0, BLOCK * 0.5 + 28.0, cs, 16.0)
	if cs == 2:
		return
	var s := BLOCK * 0.5
	var l: Vector2 = Shade.light
	var x := -60.0
	var i := 0
	while x < 59.0:
		var w := 25.0 + _h(salt * 11 + i) * 17.0
		if 60.0 - (x + w) < 20.0:
			w = 60.0 - x
		var dd := DEPTH * (0.78 + _h(salt * 5 + i) * 0.36)
		_plot(b, f, x, x + w, s - dd, s, salt * 7 + i, cs)
		x += w
		i += 1
	_corner(b, f, salt, cs)
	for t in range(7):
		var tx := -99.0 + float(t) * 33.0
		_ld(b, f, tx, s + 10.5, 8.0, SHADOW, cs, l * 4.0)
		_ld(b, f, tx, s + 10.5, 8.0, STREET_TREE, cs)
		_ld(b, f, tx, s + 10.5, 5.0, STREET_TREE_LIT, cs, -l * 1.6)


# one house's roof: x0..x1 along the street, y0 (the courtyard) to y1 (the
# street). A tiled terrat or a flat gravel roof inside its parapet, with
# the stair house, a light well, a water tank and whatever else is up there.
static func _plot(b: ShapeBatch, f: Transform2D, x0: float, x1: float, y0: float, y1: float, k: int, cs: int) -> void:
	cs = _box_cs(f, x0, y0, x1, y1, cs, 12.0)
	if cs == 2:
		return
	var l: Vector2 = Shade.light
	var w := x1 - x0
	var dd := y1 - y0
	var kind := _h(k * 3 + 1)
	var tone: Color = ROOF_TONES[int(_h(k) * 97.0) % ROOF_TONES.size()]
	if kind > 0.62:
		tone = FLAT_TONES[int(_h(k * 7) * 97.0) % FLAT_TONES.size()]
	_lq(b, f, x0 + 1.4, y0 + 1.4, x1 - 1.4, y1 - 2.6, tone, cs)
	if kind <= 0.62:
		# courses of rajola across the terrat
		var ly := y0 + 9.0
		while ly < y1 - 6.0:
			_lq(b, f, x0 + 1.4, ly, x1 - 1.4, ly + 0.6, tone.darkened(0.07), cs)
			ly += 8.0
	else:
		_lq(b, f, x0 + 4.0, y0 + 4.0, x1 - 4.0, y1 - 5.0, tone.lightened(0.05), cs)
	# the cornice over the street
	_lq(b, f, x0, y1 - 2.6, x1, y1, CORNICE, cs)
	var xm := (x0 + x1) * 0.5
	# the light well
	if dd > 84.0:
		var wy := y0 + dd * 0.42
		_lq(b, f, xm - 5.5, wy - 7.0, xm + 5.5, wy + 7.0, PARTY_WALL, cs)
		_lq(b, f, xm - 4.0, wy - 5.5, xm + 4.0, wy + 5.5, LIGHT_WELL, cs)
	# the stair house against one party wall, its tank beside it
	var left := _h(k * 5 + 2) < 0.5
	var sx := x0 + 3.0 if left else x1 - 15.0
	var sy := y0 + dd * 0.66
	_lq(b, f, sx, sy, sx + 12.0, sy + 11.0, SHADOW, cs, l * 5.0)
	_lq(b, f, sx, sy, sx + 12.0, sy + 11.0, STAIR_HOUSE, cs)
	_lq(b, f, sx, sy, sx + 12.0, sy + 3.0, STAIR_HOUSE.darkened(0.13), cs)
	if _h(k * 11) < 0.7:
		var tx := sx + (16.5 if left else -4.5)
		_ld(b, f, tx, sy + 5.0, 3.8, SHADOW, cs, l * 3.5)
		_ld(b, f, tx, sy + 5.0, 3.8, TANK, cs)
		_ld(b, f, tx, sy + 5.0, 2.2, TANK.lightened(0.1), cs, -l)
	# and by the courtyard: solar panels, washing, pots, or nothing
	var e := _h(k * 13 + 4)
	var ey := y0 + 7.0
	if e < 0.2 and w > 22.0:
		for j in range(2):
			_lq(b, f, xm - 9.0, ey + float(j) * 9.0, xm + 9.0, ey + 7.5 + float(j) * 9.0, SOLAR, cs)
			_lq(b, f, xm - 0.5, ey + float(j) * 9.0, xm + 0.5, ey + 7.5 + float(j) * 9.0, SOLAR_LINE, cs)
	elif e < 0.42:
		_lq(b, f, x0 + 4.0, ey + 3.0, x1 - 4.0, ey + 3.8, WASH_LINE, cs)
		var n := int(w / 8.0)
		for j in range(n - 1):
			_lq(b, f, x0 + 6.0 + float(j) * 7.0, ey + 3.8, x0 + 11.0 + float(j) * 7.0, ey + 9.0,
				WASHING[(k + j * 3) % WASHING.size()], cs)
	elif e < 0.62:
		for j in range(3):
			_ld(b, f, x0 + 6.0 + _h(k + j * 5) * (w - 12.0), ey + _h(k * 3 + j) * 10.0, 2.8, HEDGE_LIT if j == 1 else HEDGE, cs)
	elif e < 0.74:
		_lq(b, f, xm - 6.0, ey, xm + 6.0, ey + 8.0, SKYLIGHT, cs)
		_lq(b, f, xm - 0.5, ey, xm + 0.5, ey + 8.0, PARTY_WALL, cs)


# the corner house on the chamfer: a deeper roof, its terrat, and on some
# a slate cupola over the cut corner as the modernista corners have
static func _corner(b: ShapeBatch, f: Transform2D, salt: int, cs: int) -> void:
	cs = _box_cs(f, 52.0, 52.0, BLOCK * 0.5 + 8.0, BLOCK * 0.5 + 8.0, cs, 20.0)
	if cs == 2:
		return
	var s := BLOCK * 0.5
	var k := s - CHAMFER
	var l: Vector2 = Shade.light
	var tone: Color = ROOF_TONES[int(_h(salt * 17 + 3) * 97.0) % ROOF_TONES.size()]
	var pts := f * PackedVector2Array([Vector2(61.4, s - 2.6), Vector2(k - 1.0, s - 2.6), Vector2(s - 2.6, k - 1.0),
		Vector2(s - 2.6, 61.4), Vector2(84.6, 61.4), Vector2(61.4, 84.6)])
	_cpoly(b, pts, tone, cs)
	# the cornice round the chamfer
	_cpoly(b, f * PackedVector2Array([Vector2(k - 1.0, s - 2.6), Vector2(k, s), Vector2(s, k), Vector2(s - 2.6, k - 1.0)]), CORNICE, cs)
	_lq(b, f, 60.0, s - 2.6, k, s, CORNICE, cs)
	_lq(b, f, s - 2.6, 60.0, s, k, CORNICE, cs)
	_lq(b, f, 82.0, 82.0, 116.0, 116.0, PARTY_WALL, cs)
	_lq(b, f, 84.0, 84.0, 114.0, 114.0, TERRAT, cs)
	_lq(b, f, 86.0, 86.0, 98.0, 97.0, SHADOW, cs, l * 5.0)
	_lq(b, f, 86.0, 86.0, 98.0, 97.0, STAIR_HOUSE, cs)
	_lq(b, f, 86.0, 86.0, 98.0, 89.0, STAIR_HOUSE.darkened(0.13), cs)
	var h := _h(salt * 19 + 7)
	if h < 0.4:
		_ld(b, f, 134.0, 134.0, 10.0, SHADOW, cs, l * 7.0)
		_ld(b, f, 134.0, 134.0, 10.0, CUPOLA, cs)
		_ld(b, f, 134.0, 134.0, 6.5, CUPOLA_LIT, cs, -l * 2.0)
		_ld(b, f, 134.0, 134.0, 2.0, PARAPET, cs)
	elif h < 0.7:
		for j in range(3):
			_ld(b, f, 122.0 + float(j) * 8.0, 146.0 - float(j) * 8.0, 3.2, HEDGE if j != 1 else HEDGE_LIT, cs)


# the houses that front the avenue where it cuts the block: a row of
# plots along the cut, square to the avenue
static func _avenue_front(b: ShapeBatch, c: Vector2, oct: PackedVector2Array, salt: int, cs: int) -> void:
	var edge := BLOCK_L if cs < 0 else BLOCK_R
	var f := Transform2D(Vector2(0.0, GRID_SCALE), Vector2(-float(cs) * GRID_SCALE, 0.0), Vector2(edge, 0.0))
	var reach := BLOCK * 0.5 * sqrt(2.0)
	var y := c.y / GRID_SCALE - reach
	var end := c.y / GRID_SCALE + reach
	var i := 0
	while y < end:
		var w := 30.0 + _h(salt * 23 + i) * 16.0
		var dd := AVENUE_DEPTH * (0.8 + _h(salt * 29 + i) * 0.2)
		var cell := f * PackedVector2Array([Vector2(y, -dd), Vector2(y + w, -dd), Vector2(y + w, 0.0), Vector2(y, 0.0)])
		var whole := true
		for p: Vector2 in cell:
			whole = whole and Geometry2D.is_point_in_polygon(p - Vector2(float(cs) * 0.5, 0.0), oct)
		if whole:
			b.polygon(cell, PARTY_WALL)
			_plot(b, f, y, y + w, -dd, 0.0, salt * 37 + i, 0)
		else:
			var tone: Color = ROOF_TONES[int(_h(salt * 41 + i) * 97.0) % ROOF_TONES.size()]
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(oct, cell):
				b.polygon(poly, PARTY_WALL)
				for q: PackedVector2Array in Geometry2D.offset_polygon(poly, -1.6 * GRID_SCALE):
					b.polygon(q, tone)
		y += w
		i += 1


# a chamfered square centred on c with axes u and v, half-side s, its
# corners cut ch deep: the eight points round it
static func _octagon(c: Vector2, u: Vector2, v: Vector2, s: float, ch: float) -> PackedVector2Array:
	var k := s - ch
	var local: Array[Vector2] = [
		Vector2(k, s), Vector2(-k, s), Vector2(-s, k), Vector2(-s, -k),
		Vector2(-k, -s), Vector2(k, -s), Vector2(s, -k), Vector2(s, k),
	]
	var pts := PackedVector2Array()
	for q: Vector2 in local:
		pts.append(c + u * q.x + v * q.y)
	return pts


# --- the landmarks -----------------------------------------------------------------------

# Casa de les Punxes fills the wedge the avenue leaves of its block: brick
# walls, steep tiled roofs, and the six towers under their pointed spires
static func _punxes(b: ShapeBatch, c: Vector2, u: Vector2, v: Vector2) -> void:
	var s := BLOCK * 0.5
	var l: Vector2 = Shade.light
	_cpoly(b, _octagon(c, u, v, s + 18.6, CHAMFER + 9.6), KERB, -1)
	_cpoly(b, _octagon(c, u, v, s + 17.5, CHAMFER + 9.0), PAVEMENT, -1)
	var kept := Geometry2D.intersect_polygons(_octagon(c, u, v, s, CHAMFER), _clip_l)
	if kept.is_empty():
		return
	var poly: PackedVector2Array = kept[0]
	b.polygon(Transform2D(0.0, l * 50.0) * poly, SHADOW)
	b.polygon(poly, PUNXES_BRICK)
	var cen := Vector2.ZERO
	for p: Vector2 in poly:
		cen += p
	cen /= float(poly.size())
	var roofs := Geometry2D.offset_polygon(poly, -12.0)
	if roofs.is_empty():
		return
	var roof: PackedVector2Array = roofs[0]
	b.polygon(roof, PUNXES_ROOF)
	# the roofs pitch up from the walls to a ridge round the patio: the
	# sunward pitches lit, hips running in from every corner
	var ridge := PackedVector2Array()
	for p: Vector2 in roof:
		ridge.append(p.lerp(cen, 0.45))
	for i in range(roof.size()):
		var j := (i + 1) % roof.size()
		var out := ((roof[i] + roof[j]) * 0.5 - cen).normalized()
		b.polygon(PackedVector2Array([roof[i], roof[j], ridge[j], ridge[i]]),
			PUNXES_ROOF.lightened(0.10) if out.dot(l) < 0.0 else PUNXES_ROOF.darkened(0.10))
		b.line(roof[i], ridge[i], PUNXES_ROOF.darkened(0.3), 3.0)
	b.polygon(ridge, PUNXES_ROOF.darkened(0.16))
	var patio := PackedVector2Array()
	for p: Vector2 in roof:
		patio.append(p.lerp(cen, 0.74))
	b.polygon(patio, LIGHT_WELL)
	# the towers: one on every corner, one midway along each long wall; the
	# great one on the corner nearest the avenue's far end
	var spots: Array[Vector2] = []
	for i in range(poly.size()):
		var j := (i + 1) % poly.size()
		spots.append(poly[i].lerp(cen, 0.09))
		if poly[i].distance_to(poly[j]) > 250.0:
			spots.append(((poly[i] + poly[j]) * 0.5).lerp(cen, 0.07))
	var top := 0
	for i in range(spots.size()):
		if spots[i].y < spots[top].y:
			top = i
	for i in range(spots.size()):
		if i != top:
			_spire(b, spots[i], 27.0)
	_spire(b, spots[top], 40.0)


# a round tower under a pointed spire, from above: the cone's shadow thrown
# long and sharp, the lit and shaded halves, the finial
static func _spire(b: ShapeBatch, p: Vector2, r: float) -> void:
	var l: Vector2 = Shade.light
	var ln := l.normalized()
	var side := ln.orthogonal()
	b.polygon(PackedVector2Array([p + side * r, p + l * r * 4.2, p - side * r]), SHADOW)
	b.circle(p + l * 3.0, r + 1.5, SHADOW)
	b.circle(p, r + 1.5, PUNXES_BRICK.lightened(0.12))
	b.circle(p, r - 1.0, PUNXES_SPIRE)
	# the half that faces the sun
	var lit := PackedVector2Array([p])
	for i in range(9):
		lit.append(p + (-ln).rotated(-PI * 0.5 + PI * float(i) / 8.0) * (r - 1.0))
	b.polygon(lit, PUNXES_SPIRE.lightened(0.16))
	for i in range(8):
		b.line(p, p + Vector2.from_angle(TAU * float(i) / 8.0 + 0.2) * (r - 1.0), PUNXES_SPIRE.darkened(0.25), 1.6)
	b.circle(p, r * 0.22, PARAPET)
	b.circle(p, r * 0.1, IRON)


# Torre Glòries on its plaza by the end of the walk: the bullet's round
# plan, the coloured skin under its glass louvres, the dome on top, and the
# long tapering shadow of a tower that height
static func _glories(b: ShapeBatch, c: Vector2, u: Vector2, v: Vector2) -> void:
	var s := BLOCK * 0.5
	var l: Vector2 = Shade.light
	_cpoly(b, _octagon(c, u, v, s + 18.6, CHAMFER + 9.6), KERB, 1)
	_cpoly(b, _octagon(c, u, v, s + 17.5, CHAMFER + 9.0), PLAZA, 1)
	var f := Transform2D(u, v, c)
	for i in range(7):
		_lq(b, f, -s, -s + 24.0 + float(i) * 48.0, s, -s + 24.8 + float(i) * 48.0, PLAZA_JOINT, 1)
		_lq(b, f, -s + 24.0 + float(i) * 48.0, -s, -s + 24.8 + float(i) * 48.0, s, PLAZA_JOINT, 1)
	var tc := Vector2(BLOCK_R + 128.0, c.y)
	b.circle(tc, 118.0, TRACK_GRASS)
	b.circle(tc, 98.0, PLAZA)
	for i in range(12):
		var tp := tc + Vector2.from_angle(TAU * float(i) / 12.0) * 108.0
		b.circle(tp + l * 9.0, 15.0, SHADOW)
		b.circle(tp, 15.0, STREET_TREE)
		b.circle(tp - l * 4.0, 9.0, STREET_TREE_LIT)
	const R := 84.0
	# the shadow: the plan at the foot, narrowing to the dome's tip
	var hull := PackedVector2Array()
	for i in range(24):
		var d := Vector2.from_angle(TAU * float(i) / 24.0)
		hull.append(tc + d * R)
		hull.append(tc + l * 260.0 + d * R * 0.35)
	for poly: PackedVector2Array in Geometry2D.intersect_polygons(Geometry2D.convex_hull(hull), _clip_r):
		b.polygon(poly, SHADOW)
	# the skin: panels from earth reds at one side round to sky blues
	b.circle(tc, R, TORRE_FRAME)
	const N := 36
	for i in range(N):
		var a0 := TAU * float(i) / float(N)
		var a1 := TAU * (float(i) + 0.86) / float(N)
		var warm := 0.5 + 0.5 * cos(a0 - 2.2)
		var col: Color = TORRE_WARM[i % TORRE_WARM.size()] if _h(i * 7 + 3) < warm else TORRE_COOL[i % TORRE_COOL.size()]
		b.quad(tc + Vector2.from_angle(a0) * (R - 1.5), tc + Vector2.from_angle(a1) * (R - 1.5),
			tc + Vector2.from_angle(a1) * (R - 18.0), tc + Vector2.from_angle(a0) * (R - 18.0), col)
	# the louvres over them, and the glass dome closing the top
	b.circle(tc, R, Color(0.72, 0.84, 0.92, 0.22))
	b.circle(tc, R - 18.0, TORRE_FRAME)
	b.circle(tc, R - 20.5, TORRE_DOME)
	b.circle(tc - l * 9.0, R - 36.0, TORRE_DOME_LIT)
	for i in range(12):
		var d := Vector2.from_angle(TAU * float(i) / 12.0)
		b.line(tc + d * 12.0, tc + d * (R - 20.5), Color(TORRE_FRAME.r, TORRE_FRAME.g, TORRE_FRAME.b, 0.55), 1.6)
	b.circle(tc, 40.0, Color(TORRE_FRAME.r, TORRE_FRAME.g, TORRE_FRAME.b, 0.25))
	b.circle(tc, 38.0, TORRE_DOME_LIT)
	b.circle(tc - l * 6.0, 20.0, Color(1.0, 1.0, 1.0, 0.35))
	b.circle(tc, 12.0, TORRE_FRAME)
	b.circle(tc, 9.0, PARAPET)


# --- live: the tram, its bell and the signals ------------------------------------------

# a cab's plan from its nose (y = 0) back to the joint (y = CAB_LEN): flat
# across the front, rounded into the sides
static var _cab := PackedVector2Array()
const CAB_LEN := 76.0
const NOSE := 30.0
const MODULES: Array[Vector2] = [Vector2(80.0, 116.0), Vector2(120.0, 180.0), Vector2(184.0, 220.0)]


static func _cab_pts() -> PackedVector2Array:
	if _cab.is_empty():
		var right := PackedVector2Array()
		for i in range(9):
			var t := NOSE * float(i) / 8.0
			var k := (NOSE - t) / NOSE
			right.append(Vector2(TRAM_HALF_W * (0.56 + 0.44 * sqrt(1.0 - k * k)), t))
		right.append(Vector2(TRAM_HALF_W, CAB_LEN))
		for p: Vector2 in right:
			_cab.append(p)
		for i in range(right.size() - 1, -1, -1):
			_cab.append(Vector2(-right[i].x, right[i].y))
	return _cab


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var t: Tram = m.diagonal_tram
	if t == null:
		return
	var pulse := 0.5 + 0.5 * sin(AnimClock.msec() / 90.0)
	# the track signals by the masts: amber while the bell rings
	var lit := t.rang and t.ring_t > 0.0 or t.braking
	var y := 40.0
	while y > float(m.GATE_Y) + 80.0:
		if y > vt - 40.0 and y < vb + 40.0:
			var sp := Vector2(MAST_X - 13.0, y + 12.0)
			wc.rect(Rect2(sp.x - 6.0, sp.y - 8.0, 12.0, 20.0).grow(1.0), SHADOW)
			wc.rect(Rect2(sp.x - 6.0, sp.y - 8.0, 12.0, 20.0), IRON)
			wc.rect(Rect2(sp.x - 7.5, sp.y - 9.0, 15.0, 3.0), RAIL_DARK)
			wc.circle(sp, 4.0, SIGNAL_ON.lerp(Color.WHITE, 0.2 * pulse) if lit and pulse > 0.4 else SIGNAL_OFF)
			wc.rect(Rect2(sp.x - 1.0, sp.y + 6.0, 2.0, 4.5), SIGNAL_BAR if not lit else SIGNAL_OFF)
			if lit:
				wc.glow(sp, 24.0, Color(SIGNAL_ON.r, SIGNAL_ON.g, SIGNAL_ON.b, 0.35 * pulse))
		y -= 380.0
	# the traffic lights at the corners of each road across the avenue
	var on := light(m)
	for y0: float in CROSSINGS:
		if y0 + 120.0 < vt or y0 - 120.0 > vb:
			continue
		for i in range(4):
			var p := Vector2(WALL_L + 14.0 if i < 2 else TRACK_L - 14.0, y0 + (-58.0 if i % 2 == 0 else 58.0))
			wc.rect(Rect2(p.x - 5.0, p.y - 12.0, 10.0, 24.0).grow(1.5), SHADOW)
			wc.rect(Rect2(p.x - 5.0, p.y - 12.0, 10.0, 24.0), IRON)
			for j in range(3):
				var lc: Color = [LIGHT_RED, LIGHT_AMBER, LIGHT_GREEN][j]
				var lp := p + Vector2(0.0, -7.5 + float(j) * 7.5)
				wc.circle(lp, 2.8, lc if j == on else lc.darkened(0.72))
				if j == on:
					wc.glow(lp, 11.0, Color(lc.r, lc.g, lc.b, 0.4))
	if not t.running:
		return
	var r := tram_rect(t)
	if r.end.y < vt - 80.0 or r.position.y > vb + 80.0:
		return
	_tram(wc, r, t.dir, t.braking)


# The tram from above, inside tram_rect: five articulated modules, white
# with the green band, glass along the sides, the gear on the roof, the
# pantograph up at the wire. `a` is the frame from the leading nose back,
# `z` the same from the tail.
static func _tram(wc: ShapeBatch, r: Rect2, dir: float, braking: bool) -> void:
	var l: Vector2 = Shade.light
	var glow: float = Game.lamp_glow()
	var fy := r.position.y if dir < 0.0 else r.end.y
	var ty := r.end.y if dir < 0.0 else r.position.y
	var a := Transform2D(Vector2(1.0, 0.0), Vector2(0.0, -dir), Vector2(TRACK_X, fy))
	var z := Transform2D(Vector2(1.0, 0.0), Vector2(0.0, dir), Vector2(TRACK_X, ty))
	var cab := _cab_pts()
	var glass := TRAM_GLASS.lerp(TRAM_GLASS_LIT, 0.8 * glow)
	var hw := TRAM_HALF_W
	# the shadow of the whole train
	var sh := Transform2D(0.0, l * 9.0)
	wc.polygon(sh * (a * cab), SHADOW)
	wc.polygon(sh * (z * cab), SHADOW)
	_lq(wc, a, -hw, CAB_LEN, hw, TRAM_LEN - CAB_LEN, SHADOW, 0, l * 9.0)
	# after dark the lit saloon spills out of the windows onto the grass
	if glow > 0.0:
		for ly: float in [40.0, 98.0, 150.0, 202.0, 260.0]:
			for s: float in [-1.0, 1.0]:
				wc.glow(a * Vector2(s * (hw + 4.0), ly), 40.0, Color(1.0, 0.86, 0.54, 0.26 * glow))
	# the bellows between the modules
	for j: float in [76.0, 116.0, 180.0, 220.0]:
		_lq(wc, a, -hw + 7.0, j, hw - 7.0, j + 4.0, BELLOWS, 0)
		_lq(wc, a, -hw + 7.0, j + 1.5, hw - 7.0, j + 2.5, BELLOWS.lightened(0.12), 0)
	# the three modules between the cabs
	for mod: Vector2 in MODULES:
		_lq(wc, a, -hw, mod.x, hw, mod.y, TRAM_GREEN, 0)
		_lq(wc, a, -hw + 2.6, mod.x, hw - 2.6, mod.y, TRAM_WHITE.darkened(0.08), 0)
		_lq(wc, a, -hw + 4.0, mod.x + 2.0, hw - 4.0, mod.y - 2.0, glass, 0)
		_lq(wc, a, -hw + 9.5, mod.x, hw - 9.5, mod.y, TRAM_WHITE, 0)
		_lq(wc, a, -hw + 12.0, mod.x + 2.0, hw - 12.0, mod.y - 2.0, TRAM_ROOF, 0)
	# the doors of the long middle module
	for dy: float in [130.0, 157.0]:
		for s: float in [-1.0, 1.0]:
			_lq(wc, a, s * (hw - 9.5), dy, s * (hw - 3.2), dy + 13.0, TRAM_DOOR, 0)
			_lq(wc, a, s * (hw - 9.5), dy + 6.0, s * (hw - 3.2), dy + 7.0, glass, 0)
	# roof gear: the air conditioning on the middle, a ribbed box on the fourth
	_roof_box(wc, a, 134.0, 166.0, 22.0, true)
	_roof_box(wc, a, 190.0, 214.0, 20.0, false)
	for i in range(4):
		_lq(wc, a, -16.0, 194.0 + float(i) * 5.0, 16.0, 195.2 + float(i) * 5.0, TRAM_EQUIP.darkened(0.2), 0)
	# the cabs, nose and tail
	for e in range(2):
		var f := a if e == 0 else z
		wc.polygon(f * cab, TRAM_GREEN)
		wc.polygon(f * (Transform2D(Vector2(0.945, 0.0), Vector2(0.0, 0.975), Vector2(0.0, 1.9)) * cab), TRAM_WHITE.darkened(0.08))
		wc.polygon(f * (Transform2D(Vector2(0.9, 0.0), Vector2(0.0, 0.95), Vector2(0.0, 3.8)) * cab), glass)
		wc.polygon(f * (Transform2D(Vector2(0.79, 0.0), Vector2(0.0, 0.74), Vector2(0.0, 19.8)) * cab), TRAM_WHITE)
		wc.polygon(f * (Transform2D(Vector2(0.73, 0.0), Vector2(0.0, 0.68), Vector2(0.0, 22.6)) * cab), TRAM_ROOF)
		# the windscreen's pillar, the cab door each side, the cab's own cooler
		_lq(wc, f, -0.8, 4.0, 0.8, 19.0, TRAM_WHITE.darkened(0.08), 0)
		for s: float in [-1.0, 1.0]:
			_lq(wc, f, s * (hw - 9.5), 52.0, s * (hw - 3.2), 65.0, TRAM_DOOR, 0)
			_lq(wc, f, s * (hw - 9.5), 58.0, s * (hw - 3.2), 59.0, glass, 0)
		_roof_box(wc, f, 38.0, 62.0, 18.0, true)
		# a green flash across the nose
		_lq(wc, f, -20.0, 25.0, 20.0, 28.5, TRAM_GREEN, 0)
	# the pantograph on the second module: its frame, the arm folded back,
	# the head across the wire
	_lq(wc, a, -13.0, 86.0, 13.0, 110.0, TRAM_EQUIP.darkened(0.12), 0)
	for s: float in [-1.0, 1.0]:
		_ld(wc, a, s * 9.0, 89.0, 2.2, PARAPET, 0)
		_ld(wc, a, s * 9.0, 107.0, 2.2, PARAPET, 0)
		_ll(wc, a, s * 7.0, 107.0, 0.0, 88.0, IRON, 1.8, 0)
	_ll(wc, a, 0.0, 88.0, 0.0, 101.0, IRON, 2.4, 0)
	_ll(wc, a, -21.0, 101.0, 21.0, 101.0, IRON, 4.0, 0)
	_ll(wc, a, -17.0, 101.0, 17.0, 101.0, PANTO_CARBON, 1.6, 0)
	# headlights on the leading nose, red tails on the other
	for s: float in [-1.0, 1.0]:
		_ld(wc, a, s * 24.0, 4.2, 4.2, HEADLIGHT, 0)
		_ld(wc, a, s * 24.0, 4.2, 2.2, Color.WHITE, 0)
		_ld(wc, z, s * 24.0, 4.2, 3.6, TAIL_LIGHT if not braking else TAIL_LIGHT.lightened(0.3), 0)
		wc.glow(a * Vector2(s * 24.0, -6.0), 26.0 + 14.0 * glow, Color(1.0, 0.95, 0.75, 0.30 + 0.25 * glow))
		if braking or glow > 0.0:
			wc.glow(z * Vector2(s * 24.0, 2.0), 16.0, Color(1.0, 0.2, 0.12, 0.45 if braking else 0.3 * glow))
	wc.glow(a * Vector2(0.0, -34.0), 74.0 + 30.0 * glow, Color(1.0, 0.95, 0.75, 0.20 + 0.16 * glow))


# a box of roof gear between y0 and y1, half-width hw: its shadow, its lid,
# and the two fans of an air conditioner if it is one
static func _roof_box(wc: ShapeBatch, f: Transform2D, y0: float, y1: float, hw: float, fans: bool) -> void:
	_lq(wc, f, -hw, y0, hw, y1, Color(0.0, 0.0, 0.0, 0.16), 0, Shade.light * 3.0)
	_lq(wc, f, -hw, y0, hw, y1, TRAM_EQUIP.darkened(0.14), 0)
	_lq(wc, f, -hw + 1.5, y0 + 1.5, hw - 1.5, y1 - 1.5, TRAM_EQUIP, 0)
	if fans:
		for s: float in [-1.0, 1.0]:
			_ld(wc, f, s * hw * 0.45, (y0 + y1) * 0.5, minf(hw * 0.34, (y1 - y0) * 0.36), TRAM_EQUIP.darkened(0.3), 0)
			_ld(wc, f, s * hw * 0.45, (y0 + y1) * 0.5, 1.8, TRAM_EQUIP.lightened(0.1), 0)


# --- overhead: the catenary down the track ---------------------------------------------

static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	var b := ShapeBatch.new(c)
	var top := float(m.GATE_Y) + 60.0
	var bot := float(m.START_Y) + 400.0
	# the messenger wire straight down the middle; the contact wire under it
	# staggered from mast to mast, as it is strung to spare the pantograph
	b.line(Vector2(TRACK_X, top), Vector2(TRACK_X, bot), Color(WIRE.r, WIRE.g, WIRE.b, 0.4), 1.0)
	var prev := Vector2(TRACK_X, bot)
	var y := 40.0
	var k := 0
	while y > float(m.GATE_Y) + 80.0:
		var p := Vector2(TRACK_X + (6.0 if k % 2 == 0 else -6.0), y)
		b.line(prev, p, WIRE, 1.6)
		# each mast's bracket: the tube out over the track, the stay above
		# it, the insulators, the steady arm that holds the wire
		b.line(Vector2(MAST_X, y), Vector2(TRACK_X + 16.0, y), MAST_ARM, 3.2)
		b.line(Vector2(MAST_X, y - 12.0), Vector2(TRACK_X - 2.0, y), MAST_ARM, 1.6)
		b.line(Vector2(MAST_X, y - 12.0), Vector2(MAST_X, y), MAST_ARM, 3.2)
		b.line(Vector2(TRACK_X + 16.0, y), p + Vector2(0.0, 7.0), MAST_ARM, 1.4)
		b.line(p + Vector2(0.0, 7.0), p, MAST_ARM, 1.4)
		for ix: float in [MAST_X + 9.0, MAST_X + 15.0]:
			b.circle(Vector2(ix, y), 2.6, INSULATOR)
		b.circle(p, 2.0, MAST_ARM)
		prev = p
		y -= 380.0
		k += 1
	b.line(prev, Vector2(TRACK_X, top), WIRE, 1.6)
	b.flush()


# where main lays the walk's name and gloss (main.name_place)
static func name_place(_m: Node2D) -> Dictionary:
	return {"x": NAME_X, "room": NAME_ROOM, "down": NAME_DOWN}
