extends RefCounted

# SARRIÀ: the old village Barcelona swallowed, walked at first light.
#
# Up Carrer Major de Sarrià, the narrow pedestrian street, between low
# two-storey village houses with green shutters and balconies of geraniums;
# past a bakery setting out its crates and the Mercat de Sarrià with a
# delivery tricycle at its door; out into the Plaça de Sarrià, where the
# church of Sant Vicenç stands with its bell tower, plane trees down one side
# and the pigeons on the stones; up the street again past the balcony
# gardener and the second bakery, to the little Plaça de Sant Vicenç.
#
# The live event is the bells. As the pair comes up to the plaça the tower
# clock whirs and clunks (0.8 s, the telegraph every owner event gets), then
# Sant Vicenç strikes the hour: every pigeon on the square goes up, your
# human looks up from the phone, and a dog near the tower goes BARKY. Howl
# along while it rings. On the way home it strikes the quarter.
#
# Who is out follows the sky (systems/outdoors.gd): the bakers and their
# crates, the shutters, the sweeper, the joggers and the gardener each have
# their rule there.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EdgePath := preload("res://world/edge_path.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Mood := preload("res://systems/mood.gd")
const Panot := preload("res://world/panot.gd")
const Surfaces := preload("res://world/surfaces.gd")

const CX := 640.0
const HALF := 400.0                    # the plaça, wall to wall; the street is narrower
const WALL_L := CX - HALF
const WALL_R := CX + HALF
const FACE := 22.0                     # the house fronts, seen a little from the street
const FAR_L := -460.0
const FAR_R := 1740.0

# the street's shape: Carrer Major, the market's apron, the plaça, the
# street again, and the little square at the gate
const NODES: Array = [
	{"y": 260.0, "cx": 640.0, "half": 200.0},
	{"y": -500.0, "cx": 640.0, "half": 190.0},
	{"y": -950.0, "cx": 615.0, "half": 185.0},
	{"y": -1180.0, "cx": 625.0, "half": 185.0},
	{"y": -1280.0, "cx": 660.0, "half": 230.0},
	{"y": -1640.0, "cx": 660.0, "half": 230.0},
	{"y": -1740.0, "cx": 645.0, "half": 190.0},
	{"y": -2200.0, "cx": 650.0, "half": 190.0},
	{"y": -2370.0, "cx": 640.0, "half": 400.0},
	{"y": -3090.0, "cx": 640.0, "half": 400.0},
	{"y": -3250.0, "cx": 630.0, "half": 185.0},
	{"y": -3700.0, "cx": 610.0, "half": 180.0},
	{"y": -4150.0, "cx": 655.0, "half": 180.0},
	{"y": -4520.0, "cx": 640.0, "half": 190.0},
	{"y": -4660.0, "cx": 640.0, "half": 250.0},
	{"y": -5000.0, "cx": 640.0, "half": 250.0},
]

# the plaça and what stands round it
const PLACA_Y0 := -2370.0              # its south edge (the street opens out below)
const PLACA_Y1 := -3090.0              # its north edge
const NAVE := Rect2(-300.0, -2900.0, 540.0, 240.0)
# the bell tower stands out into the plaça at the church's corner: solid,
# and the leash winds round it like any post
const TOWER := Rect2(240.0, -2660.0, 110.0, 110.0)
const DOOR_Y := -2780.0                # the church door on the plaça
const MARKET := Rect2(890.0, -1640.0, 620.0, 360.0)
const MARKET_DOOR_Y := -1450.0
const FOUNTAIN := Vector2(770.0, -2560.0)
const SQUARE_Y := -4600.0              # Plaça de Sant Vicenç opens here
# the saint on his stone column in the little square, off to one side
const SAINT := Rect2(456.0, -4842.0, 44.0, 44.0)

# the solids: the bread crates at each bakery door, the market's fruit
# crates and the delivery tricycle parked at its door
const CRATES_1 := Rect2(446.0, -752.0, 34.0, 56.0)
const CRATES_2 := Rect2(778.0, -3990.0, 34.0, 56.0)
const FRUIT := Rect2(838.0, -1570.0, 44.0, 70.0)
const TRIKE := Rect2(842.0, -1384.0, 40.0, 78.0)

# the bells: the clock whirs WARN before the first strike; the strikes come
# STRIKE_GAP apart. Outward they ring as she comes up to the plaça, homeward
# as she comes back down into it.
const BELL_OUT_Y := -1950.0
const BELL_HOME_Y := -3350.0
const WARN := 0.8
const STRIKE_GAP := 0.95
const STRIKES := {"dawn": 7, "day": 10, "dusk": 7, "night": 9}
const QUARTER := 2
const BARKY_R := 1100.0                # a dog this near the tower goes BARKY
const HOWL_R := 900.0                  # and can howl along from here
const SCATTER := Rect2(240.0, -3140.0, 800.0, 900.0)   # the pigeons this covers go up

# her nose at the bakery doors, and the gardener's balcony
const SNIFF_R := 54.0
const SNIFF_T := 1.0
const SNIFF_STILL := 40.0
const BALCONY_Y := -3480.0
const GARDENER_BARK_R := 230.0

# the cast's pace
const SWEEP_SPEED := 26.0
const SWEEP_Y0 := 120.0
const SWEEP_Y1 := -1120.0
const JOG_SPEED := 150.0
const JOG_Y0 := 160.0
const JOG_Y1 := -2150.0
const JOG_CLEAR := 64.0
const SHUTTER_NEAR := 620.0
const SHUTTER_T := 2.2

const PRIZE := Vector2(866.0, -1452.0)
const PRIZE_TEXT := "pinch the bag of croissants on the market step"

# the shops along the street: y, side (-1 west, 1 east), kind. Bakeries are
# open before anyone else; the rest roll up their shutters as she comes.
const SHOPS: Array = [
	[-330.0, 1.0, "fruit"], [-720.0, -1.0, "forn"], [-1900.0, -1.0, "farmacia"],
	[-3330.0, 1.0, "llibreria"], [-3960.0, 1.0, "forn"], [-4340.0, -1.0, "cafe"],
]
const SHOP_LEN := 118.0

# colours
const SETT := Color(0.62, 0.60, 0.57)
const SETT_LIT := Color(0.66, 0.64, 0.61)
const SETT_JOINT := Color(0.48, 0.46, 0.44, 0.55)
const CHANNEL := Color(0.50, 0.48, 0.46)
const FLAG := Color(0.76, 0.71, 0.63)
const FLAG_ALT := Color(0.73, 0.68, 0.60)
const FLAG_JOINT := Color(0.58, 0.54, 0.48, 0.6)
const PANOT_BASE := Color(0.70, 0.67, 0.62)
const STEP := Color(0.72, 0.68, 0.60)
const STONE := Color(0.70, 0.64, 0.54)
const STONE_LIT := Color(0.80, 0.74, 0.63)
const STONE_DARK := Color(0.55, 0.50, 0.42)
const RENDERS: Array[Color] = [
	Color(0.90, 0.82, 0.64), Color(0.93, 0.89, 0.80), Color(0.88, 0.74, 0.62),
	Color(0.84, 0.78, 0.66), Color(0.92, 0.84, 0.74), Color(0.80, 0.70, 0.56),
]
const SOCLE := Color(0.54, 0.50, 0.46)
const SHUTTER_GREEN := Color(0.24, 0.44, 0.34)
const SHUTTER_GREEN_LIT := Color(0.32, 0.54, 0.42)
const WINDOW_DARK := Color(0.20, 0.18, 0.18)
const ROOF_TILES: Array[Color] = [
	Color(0.70, 0.38, 0.24), Color(0.64, 0.34, 0.22), Color(0.74, 0.44, 0.28), Color(0.60, 0.33, 0.24),
]
const TERRAT := Color(0.78, 0.62, 0.50)
const PARAPET := Color(0.90, 0.86, 0.78)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
const IRON := Color(0.14, 0.14, 0.15)
const GERANIUM := Color(0.90, 0.20, 0.26)
const GERANIUM_PINK := Color(0.96, 0.46, 0.62)
const LEAF := Color(0.22, 0.46, 0.22)
const POT := Color(0.72, 0.38, 0.22)
const BRONZE := Color(0.62, 0.46, 0.22)
const BRONZE_LIT := Color(0.84, 0.66, 0.34)
const BELL_BEAM := Color(0.36, 0.26, 0.18)
const BRICK := Color(0.66, 0.34, 0.24)
const BRICK_LIT := Color(0.76, 0.42, 0.30)
const GLASS := Color(0.62, 0.74, 0.78)
const SHUTTER_METAL := Color(0.58, 0.60, 0.62)
const SHUTTER_SLAT := Color(0.44, 0.46, 0.48)
const SHOP_LIGHT := Color(1.0, 0.86, 0.60)
const CRATE := Color(0.70, 0.52, 0.30)
const CRATE_DARK := Color(0.50, 0.36, 0.20)
const BREAD := Color(0.86, 0.62, 0.30)
const BREAD_LIT := Color(0.96, 0.78, 0.46)
const WATER := Color(0.40, 0.62, 0.74)
const WET := Color(0.10, 0.14, 0.20, 0.16)
const HI_VIS := Color(0.98, 0.84, 0.10)
const PHARMACY := Color(0.20, 0.82, 0.36)


# --- the walk's own state, on main as m.sarria --------------------------------------

class State:
	extends RefCounted
	var bell := "idle"               # idle, warn, ring
	var bell_t := 0.0
	var strikes_left := 0
	var strike_t := 0.0
	var rung_out := false
	var rung_home := false
	var swing_t := 0.0               # how long the bell has swung, for its arc
	var howled := false
	var sniff_t := 0.0
	var bread_mask := 0
	var greeted := false
	var shutters: Array[float] = []  # how far up each shop's shutter is, 0..1
	var rolled: Array[bool] = []
	var sweep_y := -300.0
	var sweep_dir := -1.0
	var sweep_said := false
	var jog_y := -1600.0
	var jog_dir := 1.0
	var jog_x := 640.0
	var jog_said := false
	var drip_t := 0.0


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898 + 4.1) * 43758.5453), 1.0)


static func edges_at(y: float) -> Vector2:
	return EdgePath.edges(NODES, y, CX, HALF)


static func edge_nodes(_m: Node2D) -> Array:
	return NODES.duplicate(true)


static func in_placa(p: Vector2) -> bool:
	return p.y < PLACA_Y0 and p.y > PLACA_Y1


static func tower_top() -> Vector2:
	return TOWER.get_center()


# --- who is out ---------------------------------------------------------------------

static func _hour() -> String:
	return String(Game.hour)


static func _weather() -> String:
	return String(Game.weather)


static func crates_out() -> bool:
	return Outdoors.bakery_open(_weather(), _hour())


static func market_open() -> bool:
	return Outdoors.shops_open(_weather(), _hour())


# --- build --------------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DE SANT VICENÇ"
	m.walk_cx = CX
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = CX - 200.0
	m.gate_r = CX + 200.0
	var st := State.new()
	for i in range(SHOPS.size()):
		var forn := String(SHOPS[i][2]) == "forn"
		st.shutters.append(1.0 if forn and crates_out() else 0.0)
		st.rolled.append(forn)
	m.sarria = st

	# the plaça's plane trees: a row down the east side, one at each corner
	# on the church side, and one by the north mouth
	for p: Vector2 in TREES:
		m.poles.append(p)
	# the plaça's two lamps, and the pilones that keep the vans out where the
	# street opens into a square
	for p: Vector2 in LAMPS:
		m.poles.append(p)
	for p: Vector2 in pilones():
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	m.benches = Array([
		Vector2(910.0, -2530.0), Vector2(910.0, -2850.0), Vector2(330.0, -2960.0),
	], TYPE_VECTOR2, &"", null)
	var bins: Array[Vector2] = []
	for yb: float in [-520.0, -1860.0, -3640.0, -4480.0]:
		var e := edges_at(yb)
		var west := yb == -520.0 or yb == -4480.0
		bins.append(Vector2(e.x + 22.0 if west else e.y - 22.0, yb))
	bins.append(Vector2(262.0, -3060.0))
	m.bins = Array(bins, TYPE_VECTOR2, &"", null)
	if "fountains" in m:
		m.fountains = Array([FOUNTAIN, Vector2(edges_at(-4250.0).y - 24.0, -4250.0)], TYPE_VECTOR2, &"", null)

	# marking spots: the city's cast-iron pilones by the doors, and the
	# tower's corner
	var hyd: Array[Vector2] = []
	for spec: Array in [[-260.0, -1.0], [-1060.0, 1.0], [-2080.0, -1.0], [-3420.0, 1.0], [-4120.0, -1.0], [-4760.0, 1.0]]:
		var e := edges_at(float(spec[0]))
		hyd.append(Vector2(e.x + 20.0 if float(spec[1]) < 0.0 else e.y - 20.0, float(spec[0])))
	hyd.insert(3, Vector2(TOWER.end.x + 26.0, TOWER.end.y + 26.0))
	# what drops on a village street at breakfast time
	var keb: Array[Vector2] = [
		Vector2(600.0, -1010.0), Vector2(690.0, -2860.0), Vector2(580.0, -4300.0),
	]
	return [hyd, keb]


const TREES: Array[Vector2] = [
	Vector2(985.0, -2450.0), Vector2(985.0, -2610.0), Vector2(985.0, -2770.0), Vector2(985.0, -2930.0),
	Vector2(330.0, -2440.0), Vector2(330.0, -3040.0), Vector2(905.0, -3045.0),
]
const LAMPS: Array[Vector2] = [Vector2(470.0, -2420.0), Vector2(780.0, -3050.0)]


# the pilones: a pair at each mouth of the plaça and at the street's foot,
# and singles by the doors further up
static func pilones() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y: float in [130.0, -2250.0, -3200.0]:
		var e := edges_at(y)
		out.append(Vector2(e.x + 18.0, y))
		out.append(Vector2(e.y - 18.0, y))
	for spec: Array in [[-1240.0, -1.0], [-2650.0, 1.0], [-3780.0, -1.0], [-4560.0, 1.0]]:
		var y: float = spec[0]
		var e := edges_at(y)
		out.append(Vector2(e.x + 16.0 if float(spec[1]) < 0.0 else e.y - 16.0, y))
	return out


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = [TRIKE, TOWER, SAINT]
	if crates_out():
		out.append(CRATES_1)
		out.append(CRATES_2)
	if market_open():
		out.append(FRUIT)
	return out


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


static func flock_ys() -> Array[float]:
	return [-2480.0, -2700.0, -2940.0]


# Everything here is paved, the square past the gate included: what is not
# water (main asks that first) handles as pavement
static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return Surfaces.S.PAVEMENT
	return -1


static func tree_kind(m: Node2D, p: Vector2) -> int:
	for t: Vector2 in TREES:
		if t.distance_to(p) < 1.0:
			return m.TREE_STREET
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	for l: Vector2 in LAMPS:
		if l.distance_to(p) < 1.0:
			return true
	return false


# the bakery doors, where the bread smells strongest: in front of the crates
static func bakery_doors() -> Array[Vector2]:
	return [
		Vector2(CRATES_1.end.x + 26.0, CRATES_1.get_center().y),
		Vector2(CRATES_2.position.x - 26.0, CRATES_2.get_center().y),
	]


static func gardener_pos() -> Vector2:
	return Vector2(edges_at(BALCONY_Y).x - 10.0, BALCONY_Y)


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var y := float(m.GATE_Y) + 80.0
	var i := 0
	while y < float(m.START_Y):
		if in_placa(Vector2(0.0, y)):
			y += 150.0
			continue
		var e := edges_at(y)
		for side: float in [-1.0, 1.0]:
			var k := i * 2 + (0 if side < 0.0 else 1) + 1311
			var kind := NightFronts.kind_of(k)
			if kind != "":
				out.append(NightFronts.front(Vector2(e.x - 4.0 if side < 0.0 else e.y + 4.0, y), -side, kind, k))
		y += 150.0
		i += 1
	# the bar on the plaça, its door open late, under the trees
	out.append(NightFronts.front(Vector2(WALL_R + 2.0, -2690.0), -1.0, "bar", 9001))
	return out


# --- per frame -----------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	var st: State = m.sarria
	if st == null or m.get("frozen") == true:
		return
	var dog: Vector2 = m.dog.global_position
	_tick_bells(m, st, delta, dog)
	if m.phase == "freedom":
		return
	_tick_bread(m, st, delta, dog)
	_tick_shutters(m, st, delta, dog)
	_tick_sweeper(m, st, delta, dog)
	_tick_jogger(m, st, delta, dog)
	st.drip_t += delta


static func _tick_bells(m: Node2D, st: State, delta: float, dog: Vector2) -> void:
	match st.bell:
		"idle":
			var home: bool = m.phase == "home"
			if not st.rung_out and m.phase == "out" and dog.y < BELL_OUT_Y and dog.y > PLACA_Y1:
				st.rung_out = true
				_warn_bells(m, st, int(STRIKES.get(_hour(), 7)))
			elif not st.rung_home and home and dog.y > BELL_HOME_Y and dog.y < PLACA_Y1 + 600.0:
				st.rung_home = true
				_warn_bells(m, st, QUARTER)
		"warn":
			st.bell_t -= delta
			if st.bell_t <= 0.0:
				st.bell = "ring"
				st.strike_t = 0.0
				st.swing_t = 0.0
				_first_strike(m, dog)
		"ring":
			st.swing_t += delta
			st.strike_t -= delta
			if st.strike_t <= 0.0:
				if st.strikes_left <= 0:
					st.bell = "idle"
					return
				st.strikes_left -= 1
				st.strike_t = STRIKE_GAP
				Sfx.play("church_bell", 1.0, -2.0)
				m.float_text(tower_top() + Vector2(46.0, -30.0), "DONG", Color(1.0, 0.86, 0.50))


# The clock whirs and clunks before the hammer falls: 0.8 s, as every event
static func _warn_bells(m: Node2D, st: State, strikes: int) -> void:
	st.bell = "warn"
	st.bell_t = WARN
	st.strikes_left = strikes
	Sfx.play("head_bump", 0.7, -6.0)
	m.float_text(tower_top() + Vector2(40.0, -40.0), "whirr... clunk!", Color(0.96, 0.94, 0.88))
	m.feed.say("THE BELLS! HOLD ON TIGHT", EventFeed.Tone.LOUD)


# The first strike: the pigeons go up off the square, your human looks up
# from the phone, and a dog near the tower is all bark
static func _first_strike(m: Node2D, dog: Vector2) -> void:
	for p in m.get_tree().get_nodes_in_group("pigeons"):
		var n := p as Node2D
		if n != null and SCATTER.has_point(n.global_position) and n.has_method("scare"):
			n.scare()
			n.set("fly_dir", (n.global_position - tower_top()).normalized().rotated(randf_range(-0.4, 0.4)))
	if dog.distance_to(tower_top()) < BARKY_R:
		m.mood.bump(Mood.M.BARKY, 0.6)
	if m.human.has_method("say_line"):
		var line := "Seven already?" if _hour() == "dawn" else "Is that the time?"
		if m.sarria.rung_home and m.phase == "home":
			line = "Quarter past. Come on."
		m.human.say_line(line)


static func ringing(m: Node2D) -> bool:
	return m.sarria != null and (m.sarria as State).bell == "ring"


static func _tick_bread(m: Node2D, st: State, delta: float, dog: Vector2) -> void:
	var doors := bakery_doors()
	var near := -1
	for i in range(doors.size()):
		if st.bread_mask & (1 << i) == 0 and dog.distance_to(doors[i]) < SNIFF_R:
			near = i
	if near < 0 or m.dog.velocity.length() > SNIFF_STILL:
		st.sniff_t = 0.0
		return
	st.sniff_t += delta
	if st.sniff_t >= SNIFF_T:
		st.sniff_t = 0.0
		st.bread_mask |= 1 << near
		Sfx.play("snack", 1.2, -6.0)
		m.combo.add("BREAD", 2)
		m.award_points(2, "fresh bread! +2")
		var said := "Not for dogs!" if crates_out() else "Smells good, huh?"
		m.float_text(doors[near] + Vector2(0.0, -34.0), said, Color(0.96, 0.94, 0.88), m.POP_SAY)


static func bread_sniffed(m: Node2D) -> int:
	if m.sarria == null:
		return 0
	var mask: int = (m.sarria as State).bread_mask
	return (mask & 1) + ((mask >> 1) & 1)


static func _tick_shutters(m: Node2D, st: State, delta: float, dog: Vector2) -> void:
	var open := Outdoors.shops_open(_weather(), _hour())
	for i in range(SHOPS.size()):
		var y: float = SHOPS[i][0]
		var forn := String(SHOPS[i][2]) == "forn"
		if forn:
			st.shutters[i] = 1.0 if crates_out() else 0.0
			continue
		if not open:
			continue
		if not st.rolled[i] and absf(dog.y - y) < SHUTTER_NEAR:
			st.rolled[i] = true
			var e := edges_at(y)
			var fx: float = e.x if float(SHOPS[i][1]) < 0.0 else e.y
			if absf(dog.y - y) < 520.0:
				m.float_text(Vector2(fx, y - 30.0), "rrrattle", Color(0.86, 0.86, 0.88))
				Sfx.play("grit", 0.6, -12.0)
		if st.rolled[i] and st.shutters[i] < 1.0:
			st.shutters[i] = minf(1.0, st.shutters[i] + delta / SHUTTER_T)


# The sweeper: a municipal escombriaire in hi-vis brushing the gutter by
# the east fronts of the lower street, up and back. He steps in to the wall
# for anyone passing, and says good morning to her once.
static func _tick_sweeper(m: Node2D, st: State, delta: float, dog: Vector2) -> void:
	if not Outdoors.street_sweeping(_weather(), _hour()):
		return
	var p := sweeper_pos(st)
	var close: bool = dog.distance_to(p) < 70.0 or m.human.global_position.distance_to(p) < 70.0
	if not close:
		st.sweep_y += st.sweep_dir * SWEEP_SPEED * delta
		if st.sweep_y < SWEEP_Y1:
			st.sweep_dir = 1.0
		elif st.sweep_y > SWEEP_Y0:
			st.sweep_dir = -1.0
	elif not st.sweep_said and dog.distance_to(p) < 70.0:
		st.sweep_said = true
		m.float_text(p + Vector2(0.0, -30.0), "Bon dia! Mind the broom", Color(0.96, 0.94, 0.88), m.POP_SAY)


static func sweeper_pos(st: State) -> Vector2:
	return Vector2(edges_at(st.sweep_y).y - 24.0, st.sweep_y)


# The jogger: up and down the lower street at a steady trot, keeping to
# whichever side your human is not on, and swerving round her
static func _tick_jogger(m: Node2D, st: State, delta: float, dog: Vector2) -> void:
	if not Outdoors.jogging(_weather(), _hour()):
		return
	st.jog_y += st.jog_dir * JOG_SPEED * delta
	if st.jog_y < JOG_Y1:
		st.jog_dir = 1.0
	elif st.jog_y > JOG_Y0:
		st.jog_dir = -1.0
	var e := edges_at(st.jog_y)
	var hum: Vector2 = m.human.global_position
	var mid := (e.x + e.y) * 0.5
	var want := e.y - JOG_CLEAR if hum.x < mid else e.x + JOG_CLEAR
	# swerve round her if she is in the way
	if absf(dog.y - st.jog_y) < 90.0 and absf(dog.x - want) < 60.0:
		want = clampf(dog.x + (70.0 if want > dog.x else -70.0), e.x + 30.0, e.y - 30.0)
	st.jog_x = move_toward(st.jog_x, clampf(want, e.x + 30.0, e.y - 30.0), 120.0 * delta)
	if not st.jog_said and Vector2(st.jog_x, st.jog_y).distance_to(dog) < 60.0:
		st.jog_said = true
		m.float_text(Vector2(st.jog_x, st.jog_y - 30.0), "Morning, pup!", Color(0.96, 0.94, 0.88), m.POP_SAY)


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> void:
	var st: State = m.sarria
	if st == null:
		return
	var bp: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	# howl along with the bells
	if not st.howled and st.bell == "ring" and bp.distance_to(tower_top()) < HOWL_R:
		st.howled = true
		m.combo.add("HOWL", 3)
		m.award_points(3, "howl along! +3")
		m.float_text(bp + Vector2(0.0, -30.0), "awooo", Color(1.0, 0.86, 0.5))
		return
	# good morning to the gardener on her balcony
	if not st.greeted and bp.distance_to(gardener_pos()) < GARDENER_BARK_R:
		st.greeted = true
		m.award_points(2, "good morning! +2")
		var reply := "Shh! It's late, rei." if _hour() == "night" else "Bon dia, rei! Good dog."
		m.float_text(gardener_pos() + Vector2(10.0, -34.0), reply, Color(0.96, 0.94, 0.88), m.POP_SAY)


static func idle_status(m: Node2D) -> String:
	if m.sarria != null and (m.sarria as State).bell == "ring":
		return "THE BELLS! HOWL ALONG"
	return ""


# --- the ground: the street's setts, the panot strips, the plaça's flags ------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 40.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi: float = minf(vb + 40.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	var b := ShapeBatch.new()
	var step := 40.0
	var y := floorf(lo / step) * step
	while y < hi:
		var y2 := y + step
		var ea := edges_at(y)
		var eb := edges_at(y2)
		var ym := y + step * 0.5
		var row := absi(int(floorf(y / step)))
		if _square(ym):
			# big sandstone flags laid square, a tone each
			b.quad(Vector2(ea.x, y), Vector2(ea.y, y), Vector2(eb.y, y2), Vector2(eb.x, y2), FLAG)
			if row % 2 == 0:
				b.line(Vector2(minf(ea.x, eb.x), y), Vector2(maxf(ea.y, eb.y), y), FLAG_JOINT, 1.5)
			var fx := floorf(WALL_L / 80.0) * 80.0
			while fx < WALL_R:
				var ex0 := maxf(ea.x, eb.x)
				var ex1 := minf(ea.y, eb.y)
				if fx > ex0 and fx < ex1:
					if (int(fx / 80.0) + row / 2) % 3 == 0:
						b.rect(Rect2(fx + 1.0, y, minf(79.0, ex1 - fx - 1.0), step), FLAG_ALT)
					b.line(Vector2(fx, y), Vector2(fx, y2), FLAG_JOINT, 1.2)
				fx += 80.0
		else:
			# the street: granite setts in courses across it, a drainage
			# channel down the middle, the panot strip along each house front
			var col := SETT if row % 2 == 0 else SETT_LIT
			b.quad(Vector2(ea.x, y), Vector2(ea.y, y), Vector2(eb.y, y2), Vector2(eb.x, y2), col)
			b.line(Vector2(ea.x, y), Vector2(ea.y, y), SETT_JOINT, 1.4)
			b.line(Vector2(ea.x, y + 20.0), Vector2(ea.y, y + 20.0), SETT_JOINT, 1.0)
			var off := 0.0 if row % 2 == 0 else 22.0
			var sx := ea.x + 52.0 + off
			while sx < ea.y - 52.0:
				b.line(Vector2(sx, y), Vector2(sx, y + 20.0), SETT_JOINT, 1.0)
				b.line(Vector2(sx + 22.0, y + 20.0), Vector2(sx + 22.0, y2), SETT_JOINT, 1.0)
				sx += 44.0
			var ca := (ea.x + ea.y) * 0.5
			var cb := (eb.x + eb.y) * 0.5
			b.line(Vector2(ca, y), Vector2(cb, y2), CHANNEL, 12.0)
			b.line(Vector2(ca, y), Vector2(cb, y2), CHANNEL.darkened(0.25), 3.0)
			for side: float in [-1.0, 1.0]:
				var a0 := ea.x if side < 0.0 else ea.y - 80.0
				var b0 := eb.x if side < 0.0 else eb.y - 80.0
				b.quad(Vector2(a0, y), Vector2(a0 + 80.0, y), Vector2(b0 + 80.0, y2), Vector2(b0, y2), PANOT_BASE)
				var kerb := ea.x + 80.0 if side < 0.0 else ea.y - 80.0
				var kerb2 := eb.x + 80.0 if side < 0.0 else eb.y - 80.0
				b.line(Vector2(kerb, y), Vector2(kerb2, y2), STONE_DARK, 2.0)
			# the flower tiles, a row at a time so the strip follows the bend
			for side: float in [-1.0, 1.0]:
				var xa := ea.x if side < 0.0 else ea.y - 80.0
				Panot.flor_row(b, xa, xa + 80.0, y, xa)
		y = y2
	_ground_extras(m, b, lo, hi)
	b.flush(wc)


static func _square(y: float) -> bool:
	return (y < PLACA_Y0 + 40.0 and y > PLACA_Y1 - 40.0) or y < SQUARE_Y + 30.0


static func _ground_extras(_m: Node2D, b: ShapeBatch, lo: float, hi: float) -> void:
	# the church steps down into the plaça, and the tower's long shadow
	if DOOR_Y + 120.0 > lo and DOOR_Y - 120.0 < hi:
		for k in range(3):
			var w := 30.0 - float(k) * 9.0
			b.rect(Rect2(WALL_L, DOOR_Y - 70.0 + float(k) * 4.0, w, 140.0 - float(k) * 8.0), STEP.darkened(0.04 * float(k)))
			b.line(Vector2(WALL_L + w, DOOR_Y - 70.0 + float(k) * 4.0), Vector2(WALL_L + w, DOOR_Y + 70.0 - float(k) * 4.0), STEP.darkened(0.22), 1.5)
	if TOWER.end.y + 260.0 > lo and TOWER.position.y - 40.0 < hi:
		var d := Shade.light * 210.0
		var a := Vector2(TOWER.end.x, TOWER.position.y)
		var c := TOWER.end
		var e := Vector2(TOWER.position.x, TOWER.end.y)
		b.polygon(PackedVector2Array([a, a + d, c + d, e + d, e, c]), Color(0.04, 0.05, 0.07, 0.14))
		_tower(b)
	if SAINT.end.y + 80.0 > lo and SAINT.position.y - 40.0 < hi:
		_saint(b)
	# the wet ring round the fountain, and the gutter under the gardener's pots
	if FOUNTAIN.y + 60.0 > lo and FOUNTAIN.y - 60.0 < hi:
		b.circle(FOUNTAIN + Vector2(10.0, 12.0), 30.0, WET)
	if BALCONY_Y + 60.0 > lo and BALCONY_Y - 60.0 < hi:
		var gx := edges_at(BALCONY_Y).x + 22.0
		b.circle(Vector2(gx, BALCONY_Y), 18.0, WET)
		b.circle(Vector2(gx + 10.0, BALCONY_Y + 12.0), 12.0, WET)


# --- the houses, the church and the market (the edge layer: static) ------------------

const LOT_H := 104.0
const FRONT_D := 120.0


static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)
	var lo := maxf(vt - 260.0, float(m.GATE_Y) - 40.0)
	var hi := minf(vb + 260.0, float(m.START_Y) + 600.0)
	if hi > lo:
		for side: float in [-1.0, 1.0]:
			_lots(b, side, lo, hi)
		if NAVE.end.y + 40.0 > lo and NAVE.position.y - 40.0 < hi:
			_church(b)
		if MARKET.end.y + 40.0 > lo and MARKET.position.y - 40.0 < hi:
			_market(b)
	if not (c is ShapeBatch):
		b.flush()


# true where a lot is taken by the church, the tower or the market
static func _taken(side: float, y0: float, y1: float) -> bool:
	if side < 0.0 and y1 > NAVE.position.y - 4.0 and y0 < TOWER.end.y + 4.0:
		return true
	if side > 0.0 and y1 > MARKET.position.y and y0 < MARKET.end.y:
		return true
	return false


static func _lot_hash(k: int, side: float, salt: int) -> int:
	var h := (k * 73856093) ^ (int(side + 2.0) * 19349663) ^ (salt * 83492791)
	return absi(h) % 1000


static func _front_x(y: float, side: float) -> float:
	var e := edges_at(y)
	return e.x if side < 0.0 else e.y


static func _lots(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	var far := FAR_L if side < 0.0 else FAR_R
	var k0 := int(floorf(lo / LOT_H)) - 1
	var k1 := int(floorf(hi / LOT_H)) + 1
	for k in range(k0, k1 + 1):
		var y0 := float(k) * LOT_H + float(_lot_hash(k, side, 1) % 30) - 15.0
		var y1 := float(k + 1) * LOT_H + float(_lot_hash(k + 1, side, 1) % 30) - 15.0
		if y1 < float(-5040.0) or y0 > 900.0:
			continue
		if _taken(side, y0, y1):
			continue
		var h := _lot_hash(k, side, 3)
		var e0 := _front_x(y0, side)
		var e1 := _front_x(y1, side)
		# the house front, seen a little from the street: render, a stone
		# socle at the pavement, shuttered windows and a balcony door
		var f0 := e0 + side * FACE
		var f1 := e1 + side * FACE
		var render: Color = RENDERS[h % RENDERS.size()]
		b.quad(Vector2(e0, y0), Vector2(f0, y0), Vector2(f1, y1), Vector2(e1, y1), render)
		b.line(Vector2(e0, y0), Vector2(e1, y1), SOCLE, 4.0)
		var ym := (y0 + y1) * 0.5
		var mx := (e0 + e1) * 0.5 + side * FACE * 0.55
		var shut := h % 3 == 0
		for wy: float in [ym - 24.0, ym + 22.0]:
			if absf(wy - ym) > (y1 - y0) * 0.5 - 10.0:
				continue
			# a window or balcony door with its pair of green shutters,
			# folded back against the wall or closed over it
			b.rect(Rect2(mx - 4.0, wy - 9.0, 8.0, 18.0), WINDOW_DARK if not shut else SHUTTER_GREEN)
			if not shut:
				b.rect(Rect2(mx - 4.0, wy - 17.0, 8.0, 7.0), SHUTTER_GREEN_LIT)
				b.rect(Rect2(mx - 4.0, wy + 10.0, 8.0, 7.0), SHUTTER_GREEN)
			else:
				b.line(Vector2(mx - 4.0, wy), Vector2(mx + 4.0, wy), SHUTTER_GREEN.darkened(0.3), 1.0)
		# the roof: front slope, ridge, back slope; a flat terrat on some
		var d := FRONT_D + float(_lot_hash(k, side, 2) % 60)
		var back0 := f0 + side * d
		var back1 := f1 + side * d
		var tile: Color = ROOF_TILES[h % ROOF_TILES.size()]
		b.quad(Vector2(back0, y0), Vector2(far, y0), Vector2(far, y1), Vector2(back1, y1), tile.darkened(0.16))
		if h % 5 == 2:
			b.quad(Vector2(f0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(f1, y1), TERRAT)
			b.line(Vector2(f0 + side * 3.0, y0), Vector2(f1 + side * 3.0, y1), PARAPET, 4.0)
			b.line(Vector2(f0, y0 + 2.0), Vector2(back0, y0 + 2.0), PARAPET, 3.0)
			b.line(Vector2(f1, y1 - 2.0), Vector2(back1, y1 - 2.0), PARAPET, 3.0)
			# pots of geraniums along the parapet, a washing line behind
			for pi in range(3):
				var pp := Vector2(f0, y0).lerp(Vector2(f1, y1), 0.22 + 0.28 * float(pi)) + Vector2(side * 10.0, 0.0)
				b.circle(pp, 4.0, POT)
				b.circle(pp + Vector2(0.0, -1.0), 3.2, GERANIUM if (pi + h) % 2 == 0 else LEAF)
			if h % 2 == 0:
				var wa := Vector2(f0 + side * 34.0, ym)
				var wb := Vector2(back0 - side * 14.0, ym)
				b.line(wa, wb, Color(0.30, 0.30, 0.32), 1.0)
				for wi in range(3):
					var wp := wa.lerp(wb, 0.2 + 0.3 * float(wi))
					b.rect(Rect2(wp.x - 5.0, ym, 10.0, 9.0), [Color(0.94, 0.93, 0.90), Color(0.56, 0.72, 0.84), Color(0.92, 0.62, 0.56)][(wi + h) % 3])
		else:
			var r0 := f0 + side * d * 0.5
			var r1 := f1 + side * d * 0.5
			var lit := tile.lightened(0.10) if side > 0.0 else tile.darkened(0.04)
			var shade := tile.darkened(0.14) if side > 0.0 else tile.lightened(0.04)
			b.quad(Vector2(f0, y0), Vector2(r0, y0), Vector2(r1, y1), Vector2(f1, y1), lit)
			b.quad(Vector2(r0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(r1, y1), shade)
			var dd := 10.0
			while dd < d - 4.0:
				if absf(dd - d * 0.5) > 4.0:
					b.line(Vector2(f0 + side * dd, y0 + 2.0), Vector2(f1 + side * dd, y1 - 2.0), (lit if dd < d * 0.5 else shade).darkened(0.10), 1.2)
				dd += 11.0
			b.line(Vector2(r0, y0), Vector2(r1, y1), tile.lightened(0.22), 3.0)
			b.line(Vector2(f0, y0), Vector2(f1, y1), tile.darkened(0.30), 2.5)
			if h % 3 == 0:
				var cp := Vector2((r0 + back0) * 0.5, ym - 10.0)
				b.rect(Rect2(cp + Shade.light * 7.0 - Vector2(7, 7), Vector2(14, 14)), SHADOW)
				b.rect(Rect2(cp - Vector2(7, 7), Vector2(14, 14)), Color(0.86, 0.80, 0.70))
				b.rect(Rect2(cp - Vector2(4, 4), Vector2(8, 8)), Color(0.26, 0.22, 0.20))
		# the party wall down to the next house
		b.line(Vector2(e0, y0), Vector2(far, y0), Color(0.18, 0.13, 0.10, 0.5), 2.0)


# the monument in Plaça de Sant Vicenç: a stepped stone base, the column,
# and the saint on top with his palm, seen from above
static func _saint(b: ShapeBatch) -> void:
	var c := SAINT.get_center()
	b.circle(c + Shade.light * 30.0, 18.0, Color(0.04, 0.05, 0.07, 0.18))
	b.rect(SAINT, STONE_DARK)
	b.rect(SAINT.grow(-4.0), STONE)
	b.rect(SAINT.grow(-10.0), STONE_LIT)
	b.circle(c, 9.0, STONE_DARK)
	b.circle(c, 7.0, Color(0.52, 0.48, 0.44))
	b.circle(c + Vector2(-1.0, -1.0), 4.0, Color(0.64, 0.60, 0.56))
	b.line(c + Vector2(2.0, 0.0), c + Vector2(9.0, -6.0), Color(0.36, 0.48, 0.30), 2.5)


# Sant Vicenç de Sarrià: the nave's long tiled roof running back from the
# plaça, its stone front on the square with the rose window, and the apse
static func _church(b: ShapeBatch) -> void:
	var r := NAVE
	var ridge := r.get_center().y
	b.rect(Rect2(r.position + Shade.light * 10.0, r.size), SHADOW)
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, ridge - r.position.y), ROOF_TILES[1].darkened(0.08))
	b.rect(Rect2(r.position.x, ridge, r.size.x, r.end.y - ridge), ROOF_TILES[0].lightened(0.06))
	var ty := r.position.y + 10.0
	while ty < r.end.y - 6.0:
		if absf(ty - ridge) > 5.0:
			b.line(Vector2(r.position.x + 4.0, ty), Vector2(r.end.x - 30.0, ty), Color(0.0, 0.0, 0.0, 0.10), 1.2)
		ty += 12.0
	b.line(Vector2(r.position.x, ridge), Vector2(r.end.x - 26.0, ridge), ROOF_TILES[2].lightened(0.25), 4.0)
	# the apse at the far end, a half-round of tile
	b.circle(Vector2(r.position.x, ridge), r.size.y * 0.42, ROOF_TILES[3])
	b.circle(Vector2(r.position.x - 6.0, ridge), r.size.y * 0.30, ROOF_TILES[3].lightened(0.08))
	# the front: stone, the gable, the rose window over the door
	var fx := r.end.x - 30.0
	b.rect(Rect2(fx, r.position.y - 6.0, 30.0, r.size.y + 12.0), STONE)
	b.rect(Rect2(fx + 22.0, r.position.y - 6.0, 8.0, r.size.y + 12.0), STONE_LIT)
	b.circle(Vector2(fx + 15.0, ridge - 30.0), 13.0, STONE_DARK)
	b.circle(Vector2(fx + 15.0, ridge - 30.0), 10.0, Color(0.30, 0.34, 0.52))
	for k in range(8):
		var a := float(k) * TAU / 8.0
		b.line(Vector2(fx + 15.0, ridge - 30.0), Vector2(fx + 15.0, ridge - 30.0) + Vector2.from_angle(a) * 10.0, STONE_LIT, 1.4)
	b.rect(Rect2(fx + 8.0, DOOR_Y - 26.0, 22.0, 52.0), STONE_DARK)
	b.rect(Rect2(fx + 14.0, DOOR_Y - 20.0, 16.0, 40.0), Color(0.30, 0.20, 0.14))
	b.line(Vector2(fx + 14.0, DOOR_Y), Vector2(fx + 30.0, DOOR_Y), Color(0.20, 0.14, 0.10), 1.5)
	# the sacristy's low roof between the nave and the tower's foot
	var sy := r.end.y
	b.rect(Rect2(FAR_L, sy, WALL_L - FAR_L, TOWER.end.y + 12.0 - sy), ROOF_TILES[3].darkened(0.06))
	b.line(Vector2(FAR_L, sy + (TOWER.end.y + 12.0 - sy) * 0.5), Vector2(WALL_L - FACE, sy + (TOWER.end.y + 12.0 - sy) * 0.5), ROOF_TILES[2].lightened(0.15), 3.0)
	b.rect(Rect2(WALL_L - FACE, sy, FACE, TOWER.end.y + 12.0 - sy), STONE)
	# the rectory and the houses behind the church to the north
	b.rect(Rect2(FAR_L, r.position.y - 200.0, WALL_L - FAR_L, 196.0), ROOF_TILES[2].darkened(0.1))
	b.rect(Rect2(WALL_L - FACE, r.position.y - 200.0, FACE, 196.0), RENDERS[1])


# the bell tower: square stone shaft, a parapet with pinnacles at the
# corners, and the belfry's frame open to the sky (the bell is drawn live)
static func _tower(b: ShapeBatch) -> void:
	var r := TOWER
	b.rect(r, STONE_DARK)
	b.rect(r.grow(-8.0), STONE)
	b.rect(Rect2(r.position.x + 8.0, r.position.y + 8.0, r.size.x - 16.0, 8.0), STONE_LIT)
	b.rect(r.grow(-20.0), Color(0.24, 0.20, 0.18))
	var c := r.get_center()
	b.line(Vector2(r.position.x + 20.0, c.y), Vector2(r.end.x - 20.0, c.y), BELL_BEAM, 7.0)
	b.line(Vector2(c.x, r.position.y + 20.0), Vector2(c.x, r.end.y - 20.0), BELL_BEAM.darkened(0.2), 3.0)
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var p := corner + (c - corner).normalized() * 9.0
		b.circle(p + Shade.light * 5.0, 9.0, SHADOW)
		b.circle(p, 8.0, STONE_LIT)
		b.circle(p, 4.0, STONE)
	# the clock on the plaça side
	var ck := Vector2(r.end.x - 2.0, c.y + 30.0)
	b.circle(ck, 11.0, STONE_DARK)
	b.circle(ck, 9.0, Color(0.94, 0.92, 0.86))
	b.line(ck, ck + Vector2(0.0, -6.0), IRON, 1.5)
	b.line(ck, ck + Vector2(4.0, 0.0), IRON, 1.5)


# El Mercat de Sarrià: the brick hall with its long roof and a glazed
# lantern down the ridge; three arches on the street, the middle one open
static func _market(b: ShapeBatch) -> void:
	var r := MARKET
	var fx := r.position.x
	b.rect(Rect2(fx + FACE, r.position.y, r.size.x - FACE, r.size.y), BRICK.darkened(0.14))
	var ridge := fx + FACE + (r.size.x - FACE) * 0.5
	b.rect(Rect2(fx + FACE, r.position.y + 8.0, ridge - fx - FACE, r.size.y - 16.0), Color(0.56, 0.36, 0.28))
	b.rect(Rect2(ridge, r.position.y + 8.0, r.end.x - ridge, r.size.y - 16.0), Color(0.48, 0.30, 0.24))
	var lx := fx + FACE + 40.0
	while lx < r.end.x - 20.0:
		if absf(lx - ridge) > 30.0:
			b.line(Vector2(lx, r.position.y + 10.0), Vector2(lx, r.end.y - 10.0), Color(0.0, 0.0, 0.0, 0.10), 1.4)
		lx += 26.0
	b.rect(Rect2(ridge - 24.0, r.position.y + 20.0, 48.0, r.size.y - 40.0), GLASS)
	var gy := r.position.y + 30.0
	while gy < r.end.y - 30.0:
		b.line(Vector2(ridge - 24.0, gy), Vector2(ridge + 24.0, gy), IRON, 1.2)
		gy += 18.0
	b.line(Vector2(ridge, r.position.y + 20.0), Vector2(ridge, r.end.y - 20.0), IRON, 2.0)
	# the brick front on the street, its cornice and the three arches
	b.rect(Rect2(fx, r.position.y, FACE, r.size.y), BRICK)
	b.line(Vector2(fx + FACE, r.position.y), Vector2(fx + FACE, r.end.y), BRICK_LIT, 3.0)
	b.line(Vector2(fx, r.position.y), Vector2(fx, r.end.y), BRICK.darkened(0.3), 3.0)
	for ay: float in [MARKET_DOOR_Y - 130.0, MARKET_DOOR_Y, MARKET_DOOR_Y + 130.0]:
		var open := absf(ay - MARKET_DOOR_Y) < 1.0
		b.rect(Rect2(fx + 2.0, ay - 34.0, FACE - 4.0, 68.0), BRICK.darkened(0.35))
		b.rect(Rect2(fx + 4.0, ay - 28.0, FACE - 8.0, 56.0), SHOP_LIGHT.darkened(0.25) if open else GLASS.darkened(0.35))
		b.circle(Vector2(fx + FACE * 0.5, ay - 34.0), 6.0, BRICK_LIT)


# --- the furniture --------------------------------------------------------------

# A pilona: Barcelona's cast-iron bollard; the plaça's lamps stand on a
# fluted iron base
static func draw_column(m: Node2D, wc: Object, p: Vector2) -> void:
	var b := ShapeBatch.new()
	if is_lamp(m, p):
		b.circle(p + Shade.light * 8.0, 11.0, SHADOW)
		b.circle(p, 10.0, IRON)
		b.circle(p - Vector2(1.5, 1.5), 6.0, Color(0.30, 0.30, 0.32))
		b.circle(p - Vector2(2.0, 2.0), 2.4, Color(0.50, 0.50, 0.52))
	else:
		b.circle(p + Shade.light * 6.0, 8.0, SHADOW)
		b.circle(p, 7.5, Color(0.20, 0.21, 0.22))
		b.circle(p - Vector2(1.2, 1.2), 5.0, Color(0.34, 0.35, 0.37))
		b.circle(p - Vector2(2.0, 2.0), 2.0, Color(0.56, 0.57, 0.58))
	b.flush(wc)


# the village fountain: a stone post with its bronze spout and the basin
# under it (the water's glint is live)
static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(f + Shade.light * 10.0, 20.0, SHADOW)
	b.circle(f, 20.0, STONE_DARK)
	b.circle(f, 16.0, STONE)
	b.circle(f + Vector2(4.0, 4.0), 11.0, WATER)
	b.rect(Rect2(f.x - 8.0, f.y - 16.0, 16.0, 12.0), STONE_LIT)
	b.line(f + Vector2(0.0, -6.0), f + Vector2(0.0, 2.0), BRONZE, 3.0)
	b.flush(m._wc)


# --- live: the bell, the shops, the crates, the cast -------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var st: State = m.sarria
	if st == null:
		return
	var t: float = AnimClock.msec() / 1000.0
	if TOWER.end.y + 200.0 > vt and TOWER.position.y - 200.0 < vb:
		_bell(wc, st)
	for i in range(SHOPS.size()):
		var y: float = SHOPS[i][0]
		if y + 120.0 > vt and y - 120.0 < vb:
			_shop(wc, i, float(SHOPS[i][1]), String(SHOPS[i][2]), y, st.shutters[i])
	var crates := crates_out()
	if crates:
		if CRATES_1.end.y + 60.0 > vt and CRATES_1.position.y - 60.0 < vb:
			_crates(wc, CRATES_1)
			_baker(wc, t)
		if CRATES_2.end.y + 60.0 > vt and CRATES_2.position.y - 60.0 < vb:
			_crates(wc, CRATES_2)
	if MARKET.end.y > vt and MARKET.position.y < vb:
		if market_open():
			_fruit(wc)
		_trike(wc, t)
	if FOUNTAIN.y + 60.0 > vt and FOUNTAIN.y - 60.0 < vb:
		var ph := fmod(t * 1.6, 1.0)
		wc.circle(FOUNTAIN + Vector2(4.0, 6.0), 3.0 + ph * 7.0, Color(0.90, 0.97, 1.0, 0.5 * (1.0 - ph)))
		wc.line(FOUNTAIN + Vector2(0.0, 2.0), FOUNTAIN + Vector2(3.0, 6.0), Color(0.86, 0.96, 1.0, 0.8), 2.0)
	if BALCONY_Y + 120.0 > vt and BALCONY_Y - 120.0 < vb:
		_gardener(wc, st, t)
	if m.phase != "freedom":
		if Outdoors.street_sweeping(_weather(), _hour()):
			var sp := sweeper_pos(st)
			if sp.y > vt - 40.0 and sp.y < vb + 40.0:
				_sweeper(wc, sp, st, t)
		if Outdoors.jogging(_weather(), _hour()) and st.jog_y > vt - 40.0 and st.jog_y < vb + 40.0:
			var jp := Vector2(st.jog_x, st.jog_y)
			NpcFigure.person(wc, jp, Vector2(0.0, st.jog_dir), 23, t * 11.0,
				{"top": Color(0.20, 0.66, 0.78), "legs": Color(0.14, 0.14, 0.16), "arms": NpcFigure.Arms.READY, "headwear": "cap", "headwear_col": Color(0.92, 0.32, 0.30)})


# the bell in its frame, swinging while it rings; each strike sends a ring
# of sound out over the plaça
static func _bell(wc: ShapeBatch, st: State) -> void:
	var c := tower_top()
	var swing := 0.0
	if st.bell == "ring":
		swing = sin(st.swing_t * TAU / (STRIKE_GAP * 2.0)) * 16.0
	elif st.bell == "warn":
		swing = sin((WARN - st.bell_t) * 30.0) * 2.0
	var bp := c + Vector2(swing, 0.0)
	wc.circle(bp + Vector2(2.0, 3.0), 17.0, Color(0.0, 0.0, 0.0, 0.35))
	wc.circle(bp, 16.0, BRONZE)
	wc.circle(bp - Vector2(3.0, 3.0), 11.0, BRONZE_LIT)
	wc.circle(bp, 4.0, BRONZE.darkened(0.4))
	if st.bell == "ring":
		var ph := fmod(st.swing_t, STRIKE_GAP) / STRIKE_GAP
		for k in range(2):
			var r := 30.0 + (ph + float(k) * 0.5) * 220.0
			var a := 0.30 * (1.0 - fmod(ph + float(k) * 0.5, 1.0))
			_ring(wc, c, r, Color(1.0, 0.92, 0.70, a))


static func _ring(wc: ShapeBatch, c: Vector2, r: float, col: Color) -> void:
	var n := 28
	var prev := c + Vector2(r, 0.0)
	for i in range(1, n + 1):
		var p := c + Vector2.from_angle(float(i) * TAU / float(n)) * r
		# only the half that opens over the plaça (the east)
		if p.x > c.x - r * 0.2:
			wc.line(prev, p, col, 3.0)
		prev = p


# A shop on the house front: its sign colour, its lit interior and goods,
# and the roller shutter that rolls up the face as it opens
static func _shop(wc: ShapeBatch, i: int, side: float, kind: String, y: float, up: float) -> void:
	var e := _front_x(y, side)
	var x0 := e if side > 0.0 else e - FACE
	var r := Rect2(x0, y - SHOP_LEN * 0.5, FACE, SHOP_LEN)
	wc.rect(r.grow(2.0), STONE_DARK)
	wc.rect(r, SHOP_LIGHT.darkened(0.18))
	var goods: Array[Color] = []
	match kind:
		"fruit": goods = [Color(0.92, 0.56, 0.16), Color(0.86, 0.18, 0.16), Color(0.50, 0.70, 0.22), Color(0.96, 0.84, 0.24)]
		"forn": goods = [BREAD, BREAD_LIT, Color(0.78, 0.52, 0.26)]
		"farmacia": goods = [Color(0.94, 0.94, 0.96), PHARMACY]
		"llibreria": goods = [Color(0.72, 0.20, 0.20), Color(0.20, 0.36, 0.62), Color(0.90, 0.80, 0.40), Color(0.24, 0.50, 0.32)]
		_: goods = [Color(0.40, 0.26, 0.18), Color(0.94, 0.92, 0.88)]
	var gy := r.position.y + 10.0
	var k := 0
	while gy < r.end.y - 8.0:
		wc.circle(Vector2(r.get_center().x, gy), 4.0, goods[(k + i) % goods.size()])
		gy += 11.0
		k += 1
	# the shutter rolls up toward the roof, away from the street
	var cover := FACE * (1.0 - up)
	if cover > 0.5:
		var sx := (x0 + FACE - cover) if side > 0.0 else x0
		wc.rect(Rect2(sx, r.position.y, cover, SHOP_LEN), SHUTTER_METAL)
		var ly := r.position.y + 4.0
		while ly < r.end.y:
			wc.line(Vector2(sx, ly), Vector2(sx + cover, ly), SHUTTER_SLAT, 1.0)
			ly += 6.0
	# the shutter box over the opening
	var bx := (x0 + FACE - 3.0) if side > 0.0 else x0
	wc.rect(Rect2(bx, r.position.y - 2.0, 3.0, SHOP_LEN + 4.0), SHUTTER_SLAT.darkened(0.3))


static func _crates(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Shade.light * 6.0, r.size), SHADOW)
	var h := r.size.y / 2.0
	for k in range(2):
		var cr := Rect2(r.position.x, r.position.y + float(k) * h, r.size.x, h - 2.0)
		wc.rect(cr, CRATE_DARK)
		wc.rect(cr.grow(-2.5), CRATE)
		# the loaves in it: barres de pa and a round pagès
		for j in range(3):
			var ly := cr.position.y + 6.0 + float(j) * 8.0
			wc.capsule(Vector2(cr.position.x + 6.0, ly), Vector2(cr.end.x - 6.0, ly), 3.0, BREAD if (j + k) % 2 == 0 else BREAD_LIT)
		if k == 1:
			wc.circle(cr.get_center() + Vector2(0.0, 2.0), 7.0, BREAD.darkened(0.08))
			wc.line(cr.get_center() + Vector2(-4.0, 2.0), cr.get_center() + Vector2(4.0, 2.0), BREAD.darkened(0.3), 1.2)


# the baker in his doorway, a crate on his arms, stooping to the stack and
# straightening again
static func _baker(wc: ShapeBatch, t: float) -> void:
	var door := Vector2(_front_x(CRATES_1.get_center().y - 48.0, -1.0) - 6.0, CRATES_1.position.y - 22.0)
	var lean := maxf(0.0, sin(t * 1.3)) * 10.0
	var p := door + Vector2(lean, lean * 0.6)
	NpcFigure.person(wc, p, Vector2(1.0, 0.4), 41, -1.0,
		{"top": Color(0.96, 0.95, 0.92), "legs": Color(0.30, 0.30, 0.34), "arms": NpcFigure.Arms.READY, "hair_style": "bald"})
	wc.rect(Rect2(p.x + 6.0, p.y - 7.0, 12.0, 14.0), CRATE)
	wc.capsule(p + Vector2(8.0, -3.0), p + Vector2(16.0, -3.0), 2.4, BREAD_LIT)


static func _fruit(wc: ShapeBatch) -> void:
	var r := FRUIT
	wc.rect(Rect2(r.position + Shade.light * 6.0, r.size), SHADOW)
	var cols: Array[Color] = [Color(0.92, 0.56, 0.16), Color(0.86, 0.18, 0.16), Color(0.50, 0.70, 0.22), Color(0.96, 0.84, 0.24)]
	for k in range(3):
		var cr := Rect2(r.position.x, r.position.y + float(k) * r.size.y / 3.0, r.size.x, r.size.y / 3.0 - 2.0)
		wc.rect(cr, CRATE_DARK)
		wc.rect(cr.grow(-2.0), CRATE)
		for j in range(4):
			wc.circle(Vector2(cr.position.x + 7.0 + float(j) * 10.0, cr.get_center().y), 4.2, cols[(k + j) % cols.size()])


# the delivery tricycle at the market door: a cargo box over the two front
# wheels, the saddle and the back wheel; its rider in the doorway with a box
static func _trike(wc: ShapeBatch, t: float) -> void:
	var r := TRIKE
	wc.rect(Rect2(r.position + Shade.light * 6.0, r.size), SHADOW)
	var box := Rect2(r.position.x, r.position.y, r.size.x, 40.0)
	wc.rect(box, Color(0.16, 0.42, 0.62))
	wc.rect(box.grow(-3.0), Color(0.22, 0.52, 0.74))
	wc.rect(Rect2(box.position.x + 6.0, box.position.y + 12.0, box.size.x - 12.0, 14.0), Color(0.94, 0.92, 0.86))
	for wx: float in [r.position.x - 2.0, r.end.x - 2.0]:
		wc.rect(Rect2(wx, box.position.y + 6.0, 4.0, 14.0), IRON)
	var cx := r.get_center().x
	wc.line(Vector2(cx, box.end.y), Vector2(cx, r.end.y - 6.0), IRON, 3.0)
	wc.rect(Rect2(cx - 2.0, r.end.y - 14.0, 4.0, 14.0), IRON)
	wc.capsule(Vector2(cx - 5.0, box.end.y + 18.0), Vector2(cx + 5.0, box.end.y + 18.0), 3.0, Color(0.10, 0.10, 0.10))
	wc.line(Vector2(cx - 12.0, box.end.y + 4.0), Vector2(cx + 12.0, box.end.y + 4.0), IRON, 2.0)
	if Outdoors.shops_open(_weather(), _hour()):
		var door := Vector2(MARKET.position.x + 6.0, MARKET_DOOR_Y + 20.0 + sin(t * 0.9) * 6.0)
		NpcFigure.person(wc, door, Vector2(-1.0, 0.0), 57, -1.0,
			{"top": Color(0.22, 0.52, 0.74), "arms": NpcFigure.Arms.READY})
		wc.rect(Rect2(door.x - 16.0, door.y - 6.0, 10.0, 12.0), Color(0.70, 0.56, 0.36))


# the gardener on her balcony with the watering can, the water falling
# into the pots and dripping on the street
static func _gardener(wc: ShapeBatch, st: State, t: float) -> void:
	var g := gardener_pos()
	if _hour() == "night":
		wc.rect(Rect2(g.x - 6.0, g.y - 10.0, 10.0, 20.0), SHOP_LIGHT.darkened(0.1))
		return
	NpcFigure.person(wc, g + Vector2(-6.0, 0.0), Vector2(1.0, 0.0), 88, -1.0,
		{"top": Color(0.52, 0.36, 0.56), "legs": Color(0.26, 0.24, 0.30), "hair": Color(0.86, 0.86, 0.88), "hair_style": "bun", "arms": NpcFigure.Arms.READY, "size": 0.92})
	if Outdoors.watering_plants(_weather(), _hour()):
		# the can held out past the railing (the balcony itself is overhead),
		# her arm reaching over the pots to it
		var can := g + Vector2(32.0, -2.0 + sin(t * 1.4) * 3.0)
		wc.line(g + Vector2(-2.0, 4.0), can + Vector2(-4.0, 2.0), Color(0.52, 0.36, 0.56), 3.0)
		wc.rect(Rect2(can.x - 5.0, can.y - 5.0, 11.0, 10.0), Color(0.36, 0.56, 0.42))
		wc.rect(Rect2(can.x - 5.0, can.y - 5.0, 11.0, 3.0), Color(0.46, 0.68, 0.52))
		wc.line(can + Vector2(5.0, 0.0), can + Vector2(16.0, -5.0), Color(0.36, 0.56, 0.42), 2.2)
		for k in range(5):
			var ph := fmod(st.drip_t * 0.9 + float(k) * 0.2, 1.0)
			wc.circle(can + Vector2(17.0 + ph * 8.0, -4.0 + ph * 18.0), 1.8 - ph * 0.6, Color(0.74, 0.88, 0.98, 0.9 * (1.0 - ph * 0.5)))


static func _sweeper(wc: ShapeBatch, p: Vector2, st: State, t: float) -> void:
	var f := Vector2(0.0, st.sweep_dir)
	NpcFigure.person(wc, p, f, 66, t * 4.0,
		{"top": HI_VIS, "legs": Color(0.18, 0.24, 0.36), "arms": NpcFigure.Arms.READY, "headwear": "cap", "headwear_col": Color(0.20, 0.30, 0.46)})
	var sw := sin(t * 3.2) * 9.0
	var head := p + Vector2(-14.0 + sw * 0.3, -st.sweep_dir * 16.0 + sw)
	wc.line(p + Vector2(-2.0, 0.0), head, Color(0.50, 0.38, 0.24), 2.2)
	wc.capsule(head + Vector2(0.0, -6.0), head + Vector2(0.0, 6.0), 3.0, Color(0.30, 0.26, 0.20))


# --- overhead: balconies, the bakery awnings and the pharmacy's green cross ---------

static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "sarria":
		return
	var b := ShapeBatch.new(ci)
	for side: float in [-1.0, 1.0]:
		var y := 200.0
		var k := 0
		while y > float(m.GATE_Y) + 60.0:
			k += 1
			var gardener := side < 0.0 and absf(y - BALCONY_Y) < 60.0
			if not in_placa(Vector2(0.0, y)) and not (y < SQUARE_Y + 40.0) and (_lot_hash(k, side, 5) % 3 == 0 or gardener) \
					and not _taken(side, y - 30.0, y + 30.0) and not _near_shop(y, side):
				var yy := BALCONY_Y if gardener else y
				_balcony(b, side, yy, k, gardener)
			y -= LOT_H * 0.5
	for i in range(SHOPS.size()):
		var y: float = SHOPS[i][0]
		var side: float = SHOPS[i][1]
		var e := _front_x(y, side)
		match String(SHOPS[i][2]):
			"forn":
				# a striped canvas awning over the bakery door
				var x0 := e if side < 0.0 else e - 12.0
				var stripe := 0
				var sy := y - SHOP_LEN * 0.5
				while sy < y + SHOP_LEN * 0.5:
					b.rect(Rect2(x0, sy, 12.0, minf(12.0, y + SHOP_LEN * 0.5 - sy)), Color(0.80, 0.22, 0.20) if stripe % 2 == 0 else Color(0.96, 0.92, 0.84))
					sy += 12.0
					stripe += 1
				b.line(Vector2(x0 + (12.0 if side < 0.0 else 0.0), y - SHOP_LEN * 0.5), Vector2(x0 + (12.0 if side < 0.0 else 0.0), y + SHOP_LEN * 0.5), Color(0.60, 0.16, 0.14), 2.0)
			"farmacia":
				# the green cross on its bracket, out over the street
				var cp := Vector2(e + side * -18.0, y - 40.0)
				b.line(Vector2(e, cp.y), cp, IRON, 2.0)
				b.rect(Rect2(cp.x - 9.0, cp.y - 3.0, 18.0, 6.0), PHARMACY)
				b.rect(Rect2(cp.x - 3.0, cp.y - 9.0, 6.0, 18.0), PHARMACY)
	b.flush()


static func _near_shop(y: float, side: float) -> bool:
	for s: Array in SHOPS:
		if float(s[1]) == side and absf(float(s[0]) - y) < SHOP_LEN * 0.5 + 20.0:
			return true
	return false


static func _balcony(b: ShapeBatch, side: float, y: float, k: int, gardener: bool) -> void:
	var e := _front_x(y, side)
	var depth := 14.0
	var x0 := e if side < 0.0 else e - depth
	var len := 50.0 if gardener else 38.0
	b.rect(Rect2(x0 - side * 6.0 + Shade.light.x * 6.0, y - len * 0.5 + Shade.light.y * 6.0, depth, len), Color(0.04, 0.05, 0.07, 0.18))
	b.rect(Rect2(x0, y - len * 0.5, depth, len), STONE_LIT)
	# the wrought-iron railing on the outer edge
	var rx := x0 + (depth if side < 0.0 else 0.0)
	b.line(Vector2(rx, y - len * 0.5), Vector2(rx, y + len * 0.5), IRON, 2.0)
	b.line(Vector2(x0, y - len * 0.5), Vector2(x0 + depth, y - len * 0.5), IRON, 1.6)
	b.line(Vector2(x0, y + len * 0.5), Vector2(x0 + depth, y + len * 0.5), IRON, 1.6)
	var n := 5 if gardener else 2 + k % 2
	for i in range(n):
		var pp := Vector2(x0 + depth * 0.5, y - len * 0.5 + 6.0 + float(i) * (len - 12.0) / maxf(1.0, float(n - 1)))
		b.circle(pp, 4.2, POT)
		b.circle(pp + Vector2(0.0, -1.0), 3.8, LEAF)
		b.circle(pp + Vector2(0.6, -1.5), 2.4, GERANIUM if (i + k) % 3 != 0 else GERANIUM_PINK)
