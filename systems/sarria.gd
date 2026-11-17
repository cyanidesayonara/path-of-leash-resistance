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
# his beat along the east gutter, short of the pilona at the street's foot
# (y 130) and the marking post below the market (y -1060)
const SWEEP_Y0 := 70.0
const SWEEP_Y1 := -990.0
const JOG_SPEED := 150.0
const JOG_Y0 := 160.0
const JOG_Y1 := -2150.0
const JOG_CLEAR := 64.0
const JOG_SIDE := 220.0                # his sideways speed changing line
const JOG_LOOK := 6                    # he picks a line clear this many steps ahead
const JOG_LOOK_STEP := 20.0
const JOG_WALL := 30.0                 # how close to the house fronts he runs
const DOG_CLEAR := 36.0                # he never comes nearer her than this
const CAST_R := 14.0                   # a passer-by's body, kept clear of things
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
const SETT_DARK := Color(0.30, 0.29, 0.30, 0.16)
const SETT_PALE := Color(0.92, 0.90, 0.86, 0.14)
const CRACK := Color(0.40, 0.36, 0.32, 0.55)
const FLAG_EDGE := Color(1.0, 0.97, 0.90, 0.16)
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
const IRON_SOFT := Color(0.20, 0.20, 0.22, 0.85)
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
# what the draw loops iterate, kept as consts so a frame allocates nothing
const SIDES: Array[float] = [-1.0, 1.0]
const WINDOW_ROWS: Array[float] = [-24.0, 22.0]
const MARKET_ARCHES: Array[float] = [-130.0, 0.0, 130.0]
const FRUIT_COLS: Array[Color] = [Color(0.92, 0.56, 0.16), Color(0.86, 0.18, 0.16), Color(0.50, 0.70, 0.22), Color(0.96, 0.84, 0.24)]
const GOODS_FORN: Array[Color] = [BREAD, BREAD_LIT, Color(0.78, 0.52, 0.26)]
const GOODS_FARMACIA: Array[Color] = [Color(0.94, 0.94, 0.96), PHARMACY]
const GOODS_LLIBRERIA: Array[Color] = [Color(0.72, 0.20, 0.20), Color(0.20, 0.36, 0.62), Color(0.90, 0.80, 0.40), Color(0.24, 0.50, 0.32)]
const GOODS_CAFE: Array[Color] = [Color(0.40, 0.26, 0.18), Color(0.94, 0.92, 0.88)]
const LAUNDRY: Array[Color] = [Color(0.94, 0.93, 0.90), Color(0.56, 0.72, 0.84), Color(0.92, 0.62, 0.56), Color(0.90, 0.82, 0.52)]
const DOORS: Array[Color] = [Color(0.34, 0.22, 0.14), Color(0.20, 0.34, 0.28), Color(0.42, 0.26, 0.16), Color(0.24, 0.26, 0.36)]
const BLOOMS: Array[Color] = [GERANIUM, GERANIUM_PINK, GERANIUM, Color(0.96, 0.94, 0.90)]
const FLAG_WARM := Color(0.79, 0.74, 0.65)
const FLAG_COOL := Color(0.71, 0.67, 0.61)
const COOL := Color(0.50, 0.55, 0.76)
const WARM := Color(1.0, 0.84, 0.58)
const PATI := Color(0.44, 0.41, 0.36)
const GRATE := Color(0.25, 0.25, 0.26)
const GRATE_LIT := Color(0.40, 0.40, 0.41)
const TREE_GRATE := Color(0.50, 0.47, 0.44)
const FLOUR := Color(0.98, 0.96, 0.90)
# street ironwork, where the paving is broken by the city's services: the
# round sewer covers and the gutter grates down the channel
const MANHOLES: Array[Vector2] = [
	Vector2(716.0, -150.0), Vector2(566.0, -880.0), Vector2(712.0, -2010.0), Vector2(600.0, -2700.0),
	Vector2(560.0, -3580.0), Vector2(704.0, -4400.0), Vector2(730.0, -4800.0),
]
const DRAINS: Array[float] = [-60.0, -640.0, -1120.0, -1880.0, -3420.0, -3900.0, -4420.0]
# where the paving is marked by use: x, y, radius, and what marked it
# (0 damp or grime, 1 flour at a bakery door)
const STAINS: Array = [
	[470.0, -520.0, 44.0, 0], [826.0, -1860.0, 40.0, 0], [796.0, -3640.0, 40.0, 0], [470.0, -4480.0, 40.0, 0],
	[262.0, -3060.0, 46.0, 0], [900.0, -2530.0, 60.0, 0], [900.0, -2850.0, 60.0, 0], [340.0, -2960.0, 56.0, 0],
	[860.0, -1530.0, 62.0, 0], [846.0, -1340.0, 54.0, 0], [640.0, -2390.0, 90.0, 0], [640.0, -3080.0, 90.0, 0],
	[506.0, -724.0, 58.0, 1], [752.0, -3962.0, 58.0, 1],
]
# the tower's ground shadow, filled in place each frame
static var _shadow_buf := PackedVector2Array()
# a wall's soft shadow on the paving: three rows of two points, reused
static var _band_buf := PackedVector2Array()
static var _band_alpha := PackedFloat32Array([1.0, 0.5, 0.0])


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
	var jog_line := 640.0            # the line he is running on, or changing to
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
		for side: float in SIDES:
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


# A passer-by of the walk's own (the sweeper, the jogger) standing at p is
# clear of everything solid: the solids, the poles and pilones, the marking
# posts, the bins, the benches and the fountains
static func cast_clear(m: Node2D, p: Vector2) -> bool:
	for r: Rect2 in m.solid_rects:
		if r.grow(CAST_R).has_point(p):
			return false
	for q: Vector2 in m.poles:
		if p.distance_to(q) < CAST_R + float(m.POLE_RADIUS):
			return false
	for h in m.hydrants:
		if p.distance_to(h.pos) < CAST_R + float(m.HYDRANT_RADIUS):
			return false
	for q: Vector2 in m.bins:
		if p.distance_to(q) < CAST_R + 12.0:
			return false
	for q: Vector2 in m.benches:
		if p.distance_to(q) < CAST_R + 30.0:
			return false
	for q: Vector2 in m.fountains:
		if p.distance_to(q) < CAST_R + 30.0:
			return false
	return true


# the jogger's footing at p: on the paving, off the solids and off the dog
static func _jog_ok(m: Node2D, p: Vector2, dog: Vector2) -> bool:
	var e := edges_at(p.y)
	if p.x < e.x + JOG_WALL - 0.5 or p.x > e.y - JOG_WALL + 0.5:
		return false
	return p.distance_to(dog) >= DOG_CLEAR and cast_clear(m, p)


# a line at x is clear for the next stretch of his run
static func _jog_line_ok(m: Node2D, x: float, y: float, dir: float, dog: Vector2) -> bool:
	for k in range(1, JOG_LOOK + 1):
		if not _jog_ok(m, Vector2(x, y + dir * float(k) * JOG_LOOK_STEP), dog):
			return false
	return true


# The jogger: up and down the lower street at a steady trot, keeping to
# whichever side your human is not on. He picks a line that is clear a
# little way ahead (the crates, the market's fruit and tricycle, the posts,
# and her), changes line at a run, and jogs on the spot if she is right in
# his way: he never runs through anything, her included.
static func _tick_jogger(m: Node2D, st: State, delta: float, dog: Vector2) -> void:
	if not Outdoors.jogging(_weather(), _hour()):
		return
	if st.jog_y < JOG_Y1:
		st.jog_dir = 1.0
	elif st.jog_y > JOG_Y0:
		st.jog_dir = -1.0
	var e := edges_at(st.jog_y)
	var hum: Vector2 = m.human.global_position
	var mid := (e.x + e.y) * 0.5
	var want := e.y - JOG_CLEAR if hum.x < mid else e.x + JOG_CLEAR
	# the line he wants if it is clear, else the one he is on if that still
	# is, else the clear line nearest the one he wants, searched outward
	var line := st.jog_line
	if _jog_line_ok(m, want, st.jog_y, st.jog_dir, dog):
		line = want
	elif not _jog_line_ok(m, line, st.jog_y, st.jog_dir, dog):
		var off := 20.0
		var found := false
		while off <= e.y - e.x and not found:
			for s: float in SIDES:
				var x := want + s * off
				if x >= e.x + JOG_WALL and x <= e.y - JOG_WALL and _jog_line_ok(m, x, st.jog_y, st.jog_dir, dog):
					line = x
					found = true
					break
			off += 20.0
	st.jog_line = line
	var nx := move_toward(st.jog_x, line, JOG_SIDE * delta)
	var here := Vector2(st.jog_x, st.jog_y)
	var ok_here := _jog_ok(m, here, dog)
	if not ok_here or _jog_ok(m, Vector2(nx, st.jog_y), dog):
		st.jog_x = nx
	var ahead := Vector2(st.jog_x, st.jog_y + st.jog_dir * JOG_SPEED * delta)
	if _jog_ok(m, ahead, dog) or (not ok_here and ahead.distance_to(dog) >= here.distance_to(dog)):
		st.jog_y = ahead.y
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
		var reply := "Bon dia, rei! Good dog."
		if _hour() == "night":
			reply = "Shh! It's late, rei."
		elif not Outdoors.gardener_on_balcony(_weather(), _hour()):
			reply = "Bon dia, rei! Stay dry."
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
	var sun := _sun()
	var reach := 34.0 + 30.0 * sun
	var shade_col := Color(0.05, 0.06, 0.12, 0.10 + 0.16 * sun)
	var foot_col := Color(0.05, 0.06, 0.12, 0.16)
	_band_buf.resize(6)
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
				b.line(Vector2(minf(ea.x, eb.x), y + 1.5), Vector2(maxf(ea.y, eb.y), y + 1.5), FLAG_EDGE, 1.0)
			var fx := floorf(WALL_L / 80.0) * 80.0
			while fx < WALL_R:
				var ex0 := maxf(ea.x, eb.x)
				var ex1 := minf(ea.y, eb.y)
				if fx > ex0 and fx < ex1:
					# a tone to each flag, as quarried; here and there one that
					# has cracked across, and one relaid paler
					var hv := _lot_hash(int(fx / 80.0), float((row + 1) / 2), 9) % 9
					var fw := minf(79.0, ex1 - fx - 1.0)
					if hv < 3:
						b.rect(Rect2(fx + 1.0, y, fw, step), FLAG_ALT if hv == 0 else (FLAG_WARM if hv == 1 else FLAG_COOL))
					elif hv == 3 and fw > 70.0:
						if row % 2 == 0:
							b.line(Vector2(fx + 14.0, y + 12.0), Vector2(fx + 40.0, y + step), CRACK, 1.0)
						else:
							b.line(Vector2(fx + 40.0, y), Vector2(fx + 52.0, y + 26.0), CRACK, 1.0)
					elif hv == 4 and fw > 70.0 and row % 2 == 0:
						b.quad(Vector2(fx + 1.0, y + 1.0), Vector2(fx + 10.0, y + 1.0), Vector2(fx + 1.0, y + 9.0), Vector2(fx + 1.0, y + 9.0), FLAG_JOINT)
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
			var sx0 := ea.x + 52.0 + off
			var sx := sx0
			while sx < ea.y - 52.0:
				b.line(Vector2(sx, y), Vector2(sx, y + 20.0), SETT_JOINT, 1.0)
				b.line(Vector2(sx + 22.0, y + 20.0), Vector2(sx + 22.0, y2), SETT_JOINT, 1.0)
				sx += 44.0
			# setts of another tone, as granite comes: a few to a course
			for j in range(3):
				var hs := _lot_hash(row, float(j), 21)
				var gx := sx0 + float(hs % maxi(1, int((ea.y - ea.x - 150.0) / 44.0))) * 44.0
				if gx < ea.y - 100.0:
					var low := hs % 2 == 0
					b.rect(Rect2(gx + (22.0 if low else 0.0) + 1.0, y + (20.0 if low else 0.0) + 1.0, 42.0, 18.0), SETT_DARK if hs % 3 == 0 else SETT_PALE)
			# the drainage channel: dished stone, a lit lip on the sunny side
			var ca := (ea.x + ea.y) * 0.5
			var cb := (eb.x + eb.y) * 0.5
			b.line(Vector2(ca, y), Vector2(cb, y2), CHANNEL, 12.0)
			b.line(Vector2(ca + 5.0, y), Vector2(cb + 5.0, y2), CHANNEL.lightened(0.16), 1.4)
			b.line(Vector2(ca - 5.0, y), Vector2(cb - 5.0, y2), CHANNEL.darkened(0.16), 1.4)
			b.line(Vector2(ca, y), Vector2(cb, y2), CHANNEL.darkened(0.25), 3.0)
			for side: float in SIDES:
				var a0 := ea.x if side < 0.0 else ea.y - 80.0
				var b0 := eb.x if side < 0.0 else eb.y - 80.0
				b.quad(Vector2(a0, y), Vector2(a0 + 80.0, y), Vector2(b0 + 80.0, y2), Vector2(b0, y2), PANOT_BASE)
				var kerb := ea.x + 80.0 if side < 0.0 else ea.y - 80.0
				var kerb2 := eb.x + 80.0 if side < 0.0 else eb.y - 80.0
				b.line(Vector2(kerb, y), Vector2(kerb2, y2), STONE_DARK, 2.0)
			# the flower tiles, a row at a time so the strip follows the bend
			for side: float in SIDES:
				var xa := ea.x if side < 0.0 else ea.y - 80.0
				Panot.flor_row(b, xa, xa + 80.0, y, xa)
		# the houses' shade on the paving: long from the west fronts, which
		# stand between the street and the low sun, and a line of it where
		# the east fronts meet the ground
		if ym > float(m.GATE_Y):
			_band_buf[0] = Vector2(ea.x, y)
			_band_buf[1] = Vector2(eb.x, y2)
			_band_buf[2] = Vector2(ea.x + reach * 0.45, y)
			_band_buf[3] = Vector2(eb.x + reach * 0.45, y2)
			_band_buf[4] = Vector2(ea.x + reach, y)
			_band_buf[5] = Vector2(eb.x + reach, y2)
			b.band(_band_buf, 2, shade_col, _band_alpha)
			_band_buf[0] = Vector2(ea.y, y)
			_band_buf[1] = Vector2(eb.y, y2)
			_band_buf[2] = Vector2(ea.y - 5.0, y)
			_band_buf[3] = Vector2(eb.y - 5.0, y2)
			_band_buf[4] = Vector2(ea.y - 12.0, y)
			_band_buf[5] = Vector2(eb.y - 12.0, y2)
			b.band(_band_buf, 2, foot_col, _band_alpha)
		y = y2
	_ground_extras(m, b, lo, hi)
	b.flush(wc)


# How hard the sun throws a shadow: all of it on a clear day, a little of it
# under cloud, and next to none after dark (Shade.throw)
static func _sun() -> float:
	var w := _weather()
	return Shade.throw * (0.4 if w == "rain" or w == "snow" else 1.0)


static func _square(y: float) -> bool:
	return (y < PLACA_Y0 + 40.0 and y > PLACA_Y1 - 40.0) or y < SQUARE_Y + 30.0


static func _ground_extras(_m: Node2D, b: ShapeBatch, lo: float, hi: float) -> void:
	var sun := _sun()
	# where the paving is marked by use: the damp under the bins and benches,
	# the mouths of the plaça, and flour trodden out of the bakery doors
	for s: Array in STAINS:
		var sy: float = s[1]
		var sr: float = s[2]
		if sy + sr < lo or sy - sr > hi:
			continue
		if int(s[3]) == 1:
			if crates_out():
				b.glow(Vector2(float(s[0]), sy), sr, Color(FLOUR.r, FLOUR.g, FLOUR.b, 0.20), 0.1)
				for j in range(7):
					var fp := Vector2(float(s[0]) + (_h(j * 3 + int(sy)) - 0.5) * sr * 1.5, sy + (_h(j * 5 + 2 + int(sy)) - 0.5) * sr * 1.3)
					b.circle(fp, 1.4 + _h(j) * 1.2, Color(FLOUR.r, FLOUR.g, FLOUR.b, 0.5))
		else:
			b.glow(Vector2(float(s[0]), sy), sr, Color(0.10, 0.09, 0.10, 0.10), 0.15)
	# the iron in the paving: sewer covers, and grates down the channel
	for p: Vector2 in MANHOLES:
		if p.y + 20.0 > lo and p.y - 20.0 < hi:
			b.circle(p, 15.0, GRATE)
			b.circle(p, 13.0, GRATE_LIT)
			b.circle(p, 11.5, GRATE)
			b.circle(p, 6.0, GRATE_LIT)
			b.circle(p, 4.6, GRATE)
			b.line(p + Vector2(-10.0, 0.0), p + Vector2(10.0, 0.0), GRATE_LIT, 1.2)
			b.line(p + Vector2(0.0, -10.0), p + Vector2(0.0, 10.0), GRATE_LIT, 1.2)
	for dy: float in DRAINS:
		if dy + 20.0 > lo and dy - 20.0 < hi:
			var e := edges_at(dy)
			var dx := (e.x + e.y) * 0.5
			b.rect(Rect2(dx - 9.0, dy - 15.0, 18.0, 30.0), GRATE_LIT)
			b.rect(Rect2(dx - 7.5, dy - 13.5, 15.0, 27.0), GRATE)
			for j in range(5):
				b.line(Vector2(dx - 6.0, dy - 10.0 + float(j) * 5.0), Vector2(dx + 6.0, dy - 10.0 + float(j) * 5.0), Color(0.06, 0.06, 0.07), 2.0)
	# the plane trees' iron grates, and what the pigeons leave under them
	for i in range(TREES.size()):
		var t := TREES[i]
		if t.y + 40.0 < lo or t.y - 40.0 > hi:
			continue
		b.rect(Rect2(t.x - 29.0, t.y - 29.0, 58.0, 58.0), STONE_DARK)
		b.rect(Rect2(t.x - 26.0, t.y - 26.0, 52.0, 52.0), TREE_GRATE)
		for j in range(9):
			var o := -22.0 + float(j) * 5.5
			b.line(Vector2(t.x + o, t.y - 24.0), Vector2(t.x + o, t.y + 24.0), TREE_GRATE.darkened(0.30), 1.6)
		b.line(Vector2(t.x - 26.0, t.y), Vector2(t.x + 26.0, t.y), TREE_GRATE.lightened(0.12), 3.0)
		b.circle(t, 13.0, Color(0.34, 0.27, 0.20))
		for j in range(5):
			var a := _h(i * 11 + j) * TAU
			var dp := t + Vector2.from_angle(a) * (40.0 + _h(i * 7 + j * 3) * 26.0)
			b.circle(dp, 1.6 + _h(i + j) * 1.4, Color(0.96, 0.96, 0.94, 0.55))
	# the church steps down into the plaça, the church's own shade at its
	# foot, and the tower's long shadow
	if DOOR_Y + 160.0 > lo and DOOR_Y - 160.0 < hi:
		var sh := Shade.light * 44.0
		b.quad(Vector2(WALL_L, NAVE.position.y - 6.0), Vector2(WALL_L, NAVE.end.y + 6.0),
			Vector2(WALL_L + sh.x, NAVE.end.y + 6.0 + sh.y), Vector2(WALL_L + sh.x, NAVE.position.y - 6.0 + sh.y), Color(0.05, 0.06, 0.12, 0.16 * sun))
		for k in range(3):
			var w := 36.0 - float(k) * 11.0
			var y0 := DOOR_Y - 78.0 + float(k) * 6.0
			var y1 := DOOR_Y + 78.0 - float(k) * 6.0
			b.rect(Rect2(WALL_L + Shade.light.x * 4.0, y0 + Shade.light.y * 4.0, w, y1 - y0), Color(0.05, 0.06, 0.12, 0.16))
			b.rect(Rect2(WALL_L, y0, w, y1 - y0), STEP.lightened(0.05 * float(k)))
			b.line(Vector2(WALL_L + w, y0), Vector2(WALL_L + w, y1), STEP.darkened(0.26), 1.6)
			b.line(Vector2(WALL_L, y0), Vector2(WALL_L + w, y0), STEP.lightened(0.20), 1.2)
			b.line(Vector2(WALL_L, y1), Vector2(WALL_L + w, y1), STEP.darkened(0.22), 1.4)
	if TOWER.end.y + 260.0 > lo and TOWER.position.y - 40.0 < hi:
		var d := Shade.light * 210.0
		var a := Vector2(TOWER.end.x, TOWER.position.y)
		var c := TOWER.end
		var e := Vector2(TOWER.position.x, TOWER.end.y)
		_shadow_buf.resize(6)
		_shadow_buf[0] = a
		_shadow_buf[1] = a + d
		_shadow_buf[2] = c + d
		_shadow_buf[3] = e + d
		_shadow_buf[4] = e
		_shadow_buf[5] = c
		b.polygon(_shadow_buf, Color(0.05, 0.06, 0.12, 0.10 + 0.10 * sun))
		_tower(b)
	if SAINT.end.y + 80.0 > lo and SAINT.position.y - 40.0 < hi:
		_saint(b)
	# the wet round the fountain, running off toward the channel, and the
	# gutter under the gardener's pots
	if FOUNTAIN.y + 80.0 > lo and FOUNTAIN.y - 80.0 < hi:
		b.glow(FOUNTAIN + Vector2(8.0, 10.0), 52.0, Color(WET.r, WET.g, WET.b, 0.30), 0.35)
		b.glow(FOUNTAIN + Vector2(-34.0, 30.0), 30.0, Color(WET.r, WET.g, WET.b, 0.22), 0.2)
		b.glow(FOUNTAIN + Vector2(-64.0, 44.0), 20.0, Color(WET.r, WET.g, WET.b, 0.16), 0.2)
	if BALCONY_Y + 60.0 > lo and BALCONY_Y - 60.0 < hi:
		var gx := edges_at(BALCONY_Y).x + 24.0
		b.glow(Vector2(gx, BALCONY_Y), 30.0, Color(WET.r, WET.g, WET.b, 0.30), 0.3)
		b.glow(Vector2(gx + 14.0, BALCONY_Y + 22.0), 20.0, Color(WET.r, WET.g, WET.b, 0.24), 0.2)


# --- the houses, the church and the market (the edge layer: static) ------------------

const LOT_H := 104.0
const FRONT_D := 120.0


static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)
	var lo := maxf(vt - 260.0, float(m.GATE_Y) - 40.0)
	var hi := minf(vb + 260.0, float(m.START_Y) + 600.0)
	if hi > lo:
		for side: float in SIDES:
			_lots(b, side, lo, hi)
		if NAVE.end.y + 160.0 > lo and NAVE.position.y - 240.0 < hi:
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


# the stretch of a side the church (with its rectory and sacristy) or the
# market draws for itself; the houses either end are built up to it
static func _own(side: float) -> Vector2:
	if side < 0.0:
		return Vector2(NAVE.position.y - 200.0, TOWER.end.y + 12.0)
	return Vector2(MARKET.position.y, MARKET.end.y)


static func _lot_hash(k: int, side: float, salt: int) -> int:
	var h := (k * 73856093) ^ (int(side + 2.0) * 19349663) ^ (salt * 83492791)
	return absi(h) % 1000


static func _front_x(y: float, side: float) -> float:
	var e := edges_at(y)
	return e.x if side < 0.0 else e.y


static func _lots(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	var own := _own(side)
	var k0 := int(floorf(lo / LOT_H)) - 1
	var k1 := int(floorf(hi / LOT_H)) + 1
	for k in range(k0, k1 + 1):
		var y0 := float(k) * LOT_H + float(_lot_hash(k, side, 1) % 30) - 15.0
		var y1 := float(k + 1) * LOT_H + float(_lot_hash(k + 1, side, 1) % 30) - 15.0
		if y1 < float(-5040.0) or y0 > 900.0:
			continue
		# a house boundary that falls just short of the church or the market
		# moves up to it, so no gap is left between them
		if y0 >= own.y and y0 < own.y + 24.0:
			y0 = own.y
		if y1 <= own.x and y1 > own.x - 24.0:
			y1 = own.x
		if y1 > own.x and y0 < own.y:
			# a house the church or the market cuts into is built up to it
			if y0 <= own.x - 24.0:
				y1 = own.x
			elif y1 >= own.y + 24.0:
				y0 = own.y
			else:
				continue
		_lot(b, side, k, y0, y1)


# how many storeys a house stands over its neighbours' eaves
static func _storeys(k: int, side: float) -> int:
	return _lot_hash(k, side, 11) % 3


# One village house: its front seen a little from the street, the roof over
# it, the pati behind and the back of the next street's row beyond that.
# The sun is low on the west: what faces it is warm, what faces away is cool.
static func _lot(b: ShapeBatch, side: float, k: int, y0: float, y1: float) -> void:
	var far := FAR_L if side < 0.0 else FAR_R
	var h := _lot_hash(k, side, 3)
	var e0 := _front_x(y0, side)
	var e1 := _front_x(y1, side)
	var f0 := e0 + side * FACE
	var f1 := e1 + side * FACE
	var len := y1 - y0
	var skew := (e1 - e0) / maxf(1.0, len)
	var render: Color = RENDERS[h % RENDERS.size()]
	render = render.lightened(0.05).lerp(WARM, 0.08) if side > 0.0 else render.darkened(0.12).lerp(COOL, 0.10)
	b.quad(Vector2(e0, y0), Vector2(f0, y0), Vector2(f1, y1), Vector2(e1, y1), render)
	# rising damp over the socle, and the eave's shade under the cornice
	b.line(Vector2(e0 + side * 5.0, y0), Vector2(e1 + side * 5.0, y1), Color(0.0, 0.0, 0.0, 0.07), 5.0)
	b.line(Vector2(f0 - side * 3.0, y0), Vector2(f1 - side * 3.0, y1), Color(0.05, 0.06, 0.12, 0.22), 5.0)
	b.line(Vector2(e0, y0), Vector2(e1, y1), SOCLE, 4.0)
	var ym := (y0 + y1) * 0.5
	var mx := (e0 + e1) * 0.5 + side * FACE * 0.55
	var shut := h % 3 == 0
	var frame := render.lightened(0.22)
	for wo: float in WINDOW_ROWS:
		var wy := ym + wo
		if absf(wy - ym) > len * 0.5 - 10.0:
			continue
		var wx := mx + skew * wo
		# a window or balcony door in its stone surround, with its pair of
		# green shutters folded back against the wall or closed over it
		b.rect(Rect2(wx - 5.5, wy - 10.5, 11.0, 21.0), frame)
		b.rect(Rect2(wx - 4.0, wy - 9.0, 8.0, 18.0), WINDOW_DARK if not shut else SHUTTER_GREEN)
		if not shut:
			b.rect(Rect2(wx - 4.0, wy - 17.0, 8.0, 7.0), SHUTTER_GREEN_LIT)
			b.rect(Rect2(wx - 4.0, wy + 10.0, 8.0, 7.0), SHUTTER_GREEN)
			b.line(Vector2(wx - 4.0, wy), Vector2(wx + 4.0, wy), Color(0.86, 0.84, 0.78, 0.5), 1.0)
		else:
			for si in range(3):
				b.line(Vector2(wx - 4.0, wy - 5.0 + float(si) * 5.0), Vector2(wx + 4.0, wy - 5.0 + float(si) * 5.0), SHUTTER_GREEN.darkened(0.3), 1.0)
	# the street door between them, on its stone step
	if h % 2 == 1 and len > 72.0:
		var ex := (e0 + e1) * 0.5
		var dx := ex if side > 0.0 else ex - 12.0
		b.rect(Rect2(dx - 1.5, ym - 8.0, 15.0, 16.0), frame)
		b.rect(Rect2(dx, ym - 6.0, 12.0, 12.0), DOORS[h % DOORS.size()])
		b.line(Vector2(dx, ym), Vector2(dx + 12.0, ym), Color(0.0, 0.0, 0.0, 0.3), 1.0)
		b.rect(Rect2(ex - 5.0 if side > 0.0 else ex, ym - 9.0, 5.0, 18.0), STEP)
		b.line(Vector2(ex - side * 5.0, ym - 9.0), Vector2(ex - side * 5.0, ym + 9.0), STEP.darkened(0.25), 1.0)
	# a downpipe from the gutter to the pavement
	if h % 4 == 0:
		b.line(Vector2(e0 + skew * 4.0, y0 + 4.0), Vector2(f0 + skew * 4.0, y0 + 4.0), Color(0.36, 0.38, 0.40), 1.6)

	# the roof: front slope, ridge, back slope; a flat terrat on some
	var d := FRONT_D + float(_lot_hash(k, side, 2) % 60)
	var back0 := f0 + side * d
	var back1 := f1 + side * d
	var tile: Color = ROOF_TILES[h % ROOF_TILES.size()]
	var toward := tile.lightened(0.12).lerp(WARM, 0.07)
	var away := tile.darkened(0.17).lerp(COOL, 0.05)
	if h % 5 == 2:
		_terrat(b, side, h, y0, y1, f0, f1, back0, back1)
	else:
		var r0 := f0 + side * d * 0.5
		var r1 := f1 + side * d * 0.5
		var front := toward if side > 0.0 else away
		var rear := away if side > 0.0 else toward
		b.quad(Vector2(f0, y0), Vector2(r0, y0), Vector2(r1, y1), Vector2(f1, y1), front)
		b.quad(Vector2(r0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(r1, y1), rear)
		# the Arab tiles' channels, running down each slope from the ridge
		var front_rib := front.darkened(0.11)
		var rear_rib := rear.darkened(0.11)
		var ry := y0 + 5.0
		while ry < y1 - 2.0:
			var fx := f0 + skew * (ry - y0)
			b.line(Vector2(fx + side * 2.0, ry), Vector2(fx + side * (d * 0.5 - 2.0), ry), front_rib, 1.0)
			b.line(Vector2(fx + side * (d * 0.5 + 2.0), ry), Vector2(fx + side * (d - 1.0), ry), rear_rib, 1.0)
			ry += 7.0
		# tiles replaced over the years, paler or darker than the rest
		for j in range(4):
			var hp := _lot_hash(k * 5 + j, side, 23)
			var px := f0 + skew * len * 0.5 + side * (8.0 + float(hp % int(d - 24.0)))
			var py := y0 + 8.0 + float((hp / 7) % int(maxf(8.0, len - 22.0)))
			b.rect(Rect2(px - 5.0, py, 10.0, 6.0), Color(1.0, 0.9, 0.8, 0.10) if hp % 2 == 0 else Color(0.1, 0.05, 0.05, 0.12))
		b.line(Vector2(r0 + 2.5, y0), Vector2(r1 + 2.5, y1), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(r0, y0), Vector2(r1, y1), tile.lightened(0.26), 3.0)
		if h % 3 == 0:
			# a chimney on the back slope, its cap and its shadow
			var cp := Vector2((r0 + back0) * 0.5, ym - 10.0)
			b.quad(cp + Vector2(-7.0, 7.0), cp + Vector2(7.0, -7.0), cp + Vector2(7.0, -7.0) + Shade.light * 18.0, cp + Vector2(-7.0, 7.0) + Shade.light * 18.0, SHADOW)
			b.rect(Rect2(cp - Vector2(7, 7), Vector2(14, 14)), Color(0.74, 0.68, 0.58))
			b.rect(Rect2(cp - Vector2(7, 7), Vector2(14, 3)), Color(0.90, 0.85, 0.74))
			b.rect(Rect2(cp - Vector2(7, 7), Vector2(3, 14)), Color(0.90, 0.85, 0.74))
			b.rect(Rect2(cp - Vector2(3.5, 3.5), Vector2(8, 8)), Color(0.22, 0.18, 0.17))
		if h % 7 == 3:
			# a rooflight over the stair
			var sp := Vector2((f0 + r0) * 0.5, ym + 14.0)
			b.rect(Rect2(sp - Vector2(9, 11), Vector2(18, 22)), Color(0.30, 0.28, 0.28))
			b.rect(Rect2(sp - Vector2(7, 9), Vector2(14, 18)), GLASS.darkened(0.30))
			b.quad(sp + Vector2(-7, -9), sp + Vector2(-1, -9), sp + Vector2(-7, 1), sp + Vector2(-7, 1), GLASS.lightened(0.25))
		if h % 4 == 1:
			# a television aerial on the ridge, and its shadow down the tiles
			var ap := Vector2((r0 + r1) * 0.5, ym + 26.0)
			_aerial(b, ap + Shade.light * 16.0, SHADOW)
			_aerial(b, ap, Color(0.80, 0.80, 0.84))
	# the cornice and the gutter along the eave
	b.line(Vector2(f0 + side * 1.5, y0), Vector2(f1 + side * 1.5, y1), tile.darkened(0.36), 2.0)
	b.line(Vector2(f0 - side * 0.5, y0), Vector2(f1 - side * 0.5, y1), render.lightened(0.30), 2.4)
	# a taller house up the street throws its shade down onto this one's roof
	var over := _storeys(k - 1, side) - _storeys(k, side)
	if over > 0:
		var sw := 7.0 * float(over)
		b.quad(Vector2(f0, y0), Vector2(back0, y0), Vector2(back0 + skew * sw, y0 + sw), Vector2(f0 + skew * sw, y0 + sw), Color(0.05, 0.04, 0.10, 0.24))

	# the pati behind the house, down in the block's shade
	var pw := 38.0 + float(_lot_hash(k, side, 13) % 26)
	var p0 := back0 + side * pw
	var p1 := back1 + side * pw
	b.quad(Vector2(back0, y0), Vector2(p0, y0), Vector2(p1, y1), Vector2(back1, y1), PATI)
	var wx0 := minf(back0, p0)
	var wx1 := minf(back1, p1)
	b.quad(Vector2(wx0, y0), Vector2(wx0 + pw * 0.45, y0), Vector2(wx1 + pw * 0.45, y1), Vector2(wx1, y1), Color(0.05, 0.05, 0.12, 0.30))
	var pc := Vector2((back0 + p0 + back1 + p1) * 0.25, ym)
	match _lot_hash(k, side, 17) % 4:
		0:
			# a lemon tree
			b.circle(pc + Shade.light * 5.0, 15.0, SHADOW)
			b.circle(pc, 15.0, LEAF.darkened(0.15))
			b.circle(pc - Vector2(3.0, 4.0), 10.0, LEAF.lightened(0.08))
			b.circle(pc + Vector2(5.0, 2.0), 2.0, Color(0.96, 0.84, 0.24))
			b.circle(pc + Vector2(-6.0, 5.0), 2.0, Color(0.96, 0.84, 0.24))
		1:
			# a paved pati, a table and pots
			b.rect(Rect2(pc.x - pw * 0.5 + 4.0, y0 + 8.0, pw - 8.0, len - 16.0), Color(0.62, 0.52, 0.44))
			b.circle(pc + Vector2(0.0, -8.0), 6.0, Color(0.90, 0.88, 0.82))
			b.circle(pc + Vector2(-7.0, 18.0), 4.0, POT)
			b.circle(pc + Vector2(-7.0, 17.0), 3.2, LEAF)
			b.circle(pc + Vector2(6.0, 24.0), 4.0, POT)
			b.circle(pc + Vector2(6.0, 23.0), 3.2, GERANIUM)
		2:
			# a lean-to wash house
			b.rect(Rect2(pc.x - pw * 0.5 + 3.0, y0 + 6.0, pw - 6.0, len * 0.42), tile.darkened(0.24))
			b.line(Vector2(pc.x - pw * 0.5 + 3.0, y0 + 6.0 + len * 0.42), Vector2(pc.x + pw * 0.5 - 3.0, y0 + 6.0 + len * 0.42), tile.darkened(0.4), 1.6)
			b.circle(pc + Vector2(0.0, 22.0), 8.0, LEAF.darkened(0.1))
		_:
			# a kitchen garden in rows
			b.rect(Rect2(pc.x - pw * 0.5 + 5.0, y0 + 10.0, pw - 10.0, len - 20.0), Color(0.36, 0.30, 0.22))
			var gy := y0 + 16.0
			while gy < y1 - 14.0:
				b.line(Vector2(pc.x - pw * 0.5 + 8.0, gy), Vector2(pc.x + pw * 0.5 - 8.0, gy), LEAF.lightened(0.04), 3.0)
				gy += 9.0
	# the back of the next street's row, and the roofs beyond it
	var h2 := _lot_hash(k, side, 19)
	var tile2: Color = ROOF_TILES[h2 % ROOF_TILES.size()]
	var d2 := 150.0 + float(h2 % 40)
	var q0 := p0 + side * d2
	var q1 := p1 + side * d2
	var m0 := p0 + side * d2 * 0.5
	var m1 := p1 + side * d2 * 0.5
	var near2 := (tile2.lightened(0.08) if side > 0.0 else tile2.darkened(0.20)).darkened(0.06)
	var far2 := (tile2.darkened(0.20) if side > 0.0 else tile2.lightened(0.08)).darkened(0.06)
	b.quad(Vector2(p0, y0), Vector2(m0, y0), Vector2(m1, y1), Vector2(p1, y1), near2)
	b.quad(Vector2(m0, y0), Vector2(q0, y0), Vector2(q1, y1), Vector2(m1, y1), far2)
	b.quad(Vector2(q0, y0), Vector2(far, y0), Vector2(far, y1), Vector2(q1, y1), tile2.darkened(0.30))
	var ry2 := y0 + 6.0
	while ry2 < y1 - 2.0:
		var px2 := p0 + skew * (ry2 - y0)
		b.line(Vector2(px2 + side * 2.0, ry2), Vector2(px2 + side * (d2 * 0.5 - 2.0), ry2), near2.darkened(0.10), 1.0)
		b.line(Vector2(px2 + side * (d2 * 0.5 + 2.0), ry2), Vector2(px2 + side * (d2 - 1.0), ry2), far2.darkened(0.10), 1.0)
		ry2 += 9.0
	b.line(Vector2(m0, y0), Vector2(m1, y1), tile2.lightened(0.16), 2.6)
	b.line(Vector2(p0, y0), Vector2(p1, y1), Color(0.86, 0.80, 0.70), 2.0)
	if h2 % 3 == 1:
		var cp2 := Vector2((m0 + q0) * 0.5, ym + 8.0)
		b.rect(Rect2(cp2 + Shade.light * 8.0 - Vector2(6, 6), Vector2(12, 12)), SHADOW)
		b.rect(Rect2(cp2 - Vector2(6, 6), Vector2(12, 12)), Color(0.70, 0.64, 0.56))
		b.rect(Rect2(cp2 - Vector2(3, 3), Vector2(6, 6)), Color(0.22, 0.18, 0.17))
	# the party wall down to the next house
	b.line(Vector2(e0, y0), Vector2(far, y0), Color(0.18, 0.13, 0.10, 0.5), 2.0)


# a flat roof terrace: fired tiles inside a whitewashed parapet, the stair
# hut, pots of geraniums along the street side and the washing out
static func _terrat(b: ShapeBatch, side: float, h: int, y0: float, y1: float, f0: float, f1: float, back0: float, back1: float) -> void:
	var ym := (y0 + y1) * 0.5
	b.quad(Vector2(f0, y0), Vector2(back0, y0), Vector2(back1, y1), Vector2(f1, y1), TERRAT)
	var gx := 18.0
	var d := absf(back0 - f0)
	while gx < d:
		b.line(Vector2(f0 + side * gx, y0), Vector2(f1 + side * gx, y1), TERRAT.darkened(0.09), 1.0)
		gx += 18.0
	var gy := y0 + 18.0
	while gy < y1:
		b.line(Vector2(minf(f0, back0), gy), Vector2(maxf(f0, back0), gy), TERRAT.darkened(0.09), 1.0)
		gy += 18.0
	# the parapet's shade inside it, on the sun's side
	var wx := minf(f0, back0)
	b.rect(Rect2(wx, y0 + 2.0, d, 7.0), Color(0.05, 0.04, 0.10, 0.20))
	b.rect(Rect2(wx, y0 + 2.0, 6.0, y1 - y0 - 4.0), Color(0.05, 0.04, 0.10, 0.20))
	b.line(Vector2(f0 + side * 3.0, y0), Vector2(f1 + side * 3.0, y1), PARAPET, 4.0)
	b.line(Vector2(back0 - side * 2.0, y0), Vector2(back1 - side * 2.0, y1), PARAPET.darkened(0.08), 3.0)
	b.line(Vector2(f0, y0 + 2.0), Vector2(back0, y0 + 2.0), PARAPET, 3.0)
	b.line(Vector2(f1, y1 - 2.0), Vector2(back1, y1 - 2.0), PARAPET.darkened(0.08), 3.0)
	# the stair hut in the back corner
	var hut := Rect2((back0 - 34.0) if side > 0.0 else (back0 + 6.0), y0 + 8.0, 28.0, 24.0)
	b.rect(Rect2(hut.position + Shade.light * 12.0, hut.size), SHADOW)
	b.rect(hut, PARAPET.darkened(0.10))
	b.rect(hut.grow(-3.0), PARAPET)
	b.rect(Rect2(hut.position.x + 9.0, hut.end.y - 3.0, 10.0, 3.0), DOORS[h % DOORS.size()])
	for pi in range(4):
		var pp := Vector2(f0, y0).lerp(Vector2(f1, y1), 0.16 + 0.22 * float(pi)) + Vector2(side * 11.0, 0.0)
		b.circle(pp + Shade.light * 3.0, 4.4, SHADOW)
		b.circle(pp, 4.4, POT)
		b.circle(pp + Vector2(0.0, -1.0), 4.0, LEAF)
		b.circle(pp + Vector2(-1.0, -1.6), 2.2, BLOOMS[(pi + h) % BLOOMS.size()])
	if h % 2 == 0:
		var wa := Vector2(f0 + side * 34.0, ym + 14.0)
		var wb := Vector2(back0 - side * 14.0, ym + 14.0)
		for wi in range(4):
			var wp := wa.lerp(wb, 0.14 + 0.24 * float(wi))
			b.rect(Rect2(wp.x - 5.0 + Shade.light.x * 9.0, wp.y + Shade.light.y * 9.0, 11.0, 3.0), SHADOW)
		b.line(wa, wb, Color(0.30, 0.30, 0.32), 1.0)
		for wi in range(4):
			var wp := wa.lerp(wb, 0.14 + 0.24 * float(wi))
			b.rect(Rect2(wp.x - 5.0, wp.y, 11.0, 9.0), LAUNDRY[(wi + h) % LAUNDRY.size()])
			b.line(Vector2(wp.x - 5.0, wp.y), Vector2(wp.x + 6.0, wp.y), Color(1.0, 1.0, 1.0, 0.35), 1.2)
	else:
		# a folding chair and a table left out
		var tp := Vector2((f0 + back0) * 0.5, ym + 16.0)
		b.circle(tp + Shade.light * 4.0, 8.0, SHADOW)
		b.circle(tp, 8.0, Color(0.92, 0.90, 0.84))
		b.rect(Rect2(tp.x + 12.0, tp.y - 5.0, 9.0, 9.0), Color(0.30, 0.48, 0.62))


static func _aerial(b: ShapeBatch, p: Vector2, col: Color) -> void:
	b.line(p + Vector2(-9.0, 0.0), p + Vector2(11.0, 0.0), col, 1.2)
	b.line(p + Vector2(-6.0, -5.0), p + Vector2(-6.0, 5.0), col, 1.0)
	b.line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), col, 1.0)
	b.line(p + Vector2(6.0, -3.0), p + Vector2(6.0, 3.0), col, 1.0)


# An octagon by its inradius, as three convex pieces: no polygon to
# triangulate, so the tower's ground pass allocates nothing
static func _oct(b: ShapeBatch, c: Vector2, r: float, col: Color) -> void:
	var a := r * 0.41421356
	b.rect(Rect2(c.x - a, c.y - r, a * 2.0, r * 2.0), col)
	b.quad(Vector2(c.x - r, c.y - a), Vector2(c.x - a, c.y - r), Vector2(c.x - a, c.y + r), Vector2(c.x - r, c.y + a), col)
	b.quad(Vector2(c.x + a, c.y - r), Vector2(c.x + r, c.y - a), Vector2(c.x + r, c.y + a), Vector2(c.x + a, c.y + r), col)


# A pitched tile roof over r, its ridge running along x or along y: the
# slope toward the sun (up the screen, and west) warm, the other in shade,
# the tiles' channels running down from the ridge
static func _roof(b: ShapeBatch, r: Rect2, tile: Color, along_x: bool, rib := 8.0) -> void:
	var lit := tile.lightened(0.12).lerp(WARM, 0.07)
	var shade := tile.darkened(0.17).lerp(COOL, 0.05)
	var c := r.get_center()
	if along_x:
		b.rect(Rect2(r.position.x, r.position.y, r.size.x, c.y - r.position.y), lit)
		b.rect(Rect2(r.position.x, c.y, r.size.x, r.end.y - c.y), shade)
		var x := r.position.x + rib * 0.5
		while x < r.end.x:
			b.line(Vector2(x, r.position.y + 1.0), Vector2(x, c.y - 2.0), lit.darkened(0.11), 1.0)
			b.line(Vector2(x, c.y + 2.0), Vector2(x, r.end.y - 1.0), shade.darkened(0.11), 1.0)
			x += rib
		b.line(Vector2(r.position.x, c.y + 2.5), Vector2(r.end.x, c.y + 2.5), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), tile.lightened(0.28), 3.0)
	else:
		b.rect(Rect2(r.position.x, r.position.y, c.x - r.position.x, r.size.y), lit)
		b.rect(Rect2(c.x, r.position.y, r.end.x - c.x, r.size.y), shade)
		var y := r.position.y + rib * 0.5
		while y < r.end.y:
			b.line(Vector2(r.position.x + 1.0, y), Vector2(c.x - 2.0, y), lit.darkened(0.11), 1.0)
			b.line(Vector2(c.x + 2.0, y), Vector2(r.end.x - 1.0, y), shade.darkened(0.11), 1.0)
			y += rib
		b.line(Vector2(c.x + 2.5, r.position.y), Vector2(c.x + 2.5, r.end.y), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), tile.lightened(0.28), 3.0)


# the monument in Plaça de Sant Vicenç: a stepped stone base, the column,
# and the saint on top with his palm, seen from above
static func _saint(b: ShapeBatch) -> void:
	var c := SAINT.get_center()
	# the column is tall: its shadow runs long across the flags
	b.capsule(c + Shade.light * 10.0, c + Shade.light * 78.0, 8.0, Color(0.05, 0.06, 0.12, 0.16))
	b.circle(c + Shade.light * 84.0, 11.0, Color(0.05, 0.06, 0.12, 0.16))
	b.rect(Rect2(SAINT.position + Shade.light * 5.0, SAINT.size), SHADOW)
	b.rect(SAINT, STONE_DARK)
	b.rect(Rect2(SAINT.position, Vector2(SAINT.size.x, 3.0)), STONE_LIT)
	b.rect(Rect2(SAINT.position, Vector2(3.0, SAINT.size.y)), STONE_LIT)
	b.rect(SAINT.grow(-5.0), STONE)
	b.rect(Rect2(SAINT.position + Vector2(5.0, 5.0), Vector2(SAINT.size.x - 10.0, 2.0)), STONE_LIT)
	b.rect(SAINT.grow(-10.0), STONE_LIT)
	b.rect(Rect2(SAINT.position + Vector2(10.0, SAINT.size.y - 13.0), Vector2(SAINT.size.x - 20.0, 3.0)), STONE.darkened(0.1))
	_oct(b, c + Vector2(1.5, 2.0), 10.0, Color(0.0, 0.0, 0.0, 0.25))
	_oct(b, c, 9.5, STONE_DARK)
	_oct(b, c, 8.0, Color(0.74, 0.70, 0.62))
	# the saint: shoulders, head, the palm in his hand
	b.capsule(c + Vector2(-4.0, 1.0), c + Vector2(4.0, 1.0), 3.6, Color(0.50, 0.47, 0.44))
	b.circle(c + Vector2(0.0, -0.5), 3.4, Color(0.66, 0.63, 0.59))
	b.circle(c + Vector2(-0.8, -1.3), 1.8, Color(0.78, 0.75, 0.70))
	b.line(c + Vector2(5.0, 1.0), c + Vector2(11.0, -6.0), Color(0.36, 0.48, 0.30), 2.2)
	b.line(c + Vector2(11.0, -6.0), c + Vector2(13.0, -10.0), Color(0.44, 0.58, 0.34), 1.4)


# Sant Vicenç de Sarrià: the nave's long tiled roof running back from the
# plaça over its two aisles, the buttresses between the chapels, the stone
# front on the square with its gable, the rose window over the door, and
# the rectory and its garden up the street
static func _church(b: ShapeBatch) -> void:
	var r := NAVE
	var ridge := r.get_center().y
	var aisle := 38.0
	var tile: Color = ROOF_TILES[0]
	var x0 := r.position.x
	var fx := r.end.x - 30.0
	# the rectory up the street: its roof, its walled garden and a cypress
	var rect_top := r.position.y - 200.0
	_roof(b, Rect2(FAR_L, rect_top, WALL_L - FACE - FAR_L, 190.0), ROOF_TILES[2], false, 9.0)
	var garden := Rect2(52.0, rect_top + 34.0, 96.0, 118.0)
	b.rect(garden.grow(4.0), PARAPET.darkened(0.12))
	b.rect(garden, Color(0.40, 0.44, 0.30))
	b.rect(Rect2(garden.position, Vector2(garden.size.x * 0.4, garden.size.y)), Color(0.05, 0.05, 0.12, 0.26))
	b.rect(Rect2(garden.position.x + 40.0, garden.position.y + 8.0, 12.0, garden.size.y - 16.0), Color(0.66, 0.60, 0.50))
	b.circle(garden.position + Vector2(74.0, 34.0) + Shade.light * 8.0, 15.0, SHADOW)
	b.circle(garden.position + Vector2(74.0, 34.0), 15.0, Color(0.16, 0.32, 0.22))
	b.circle(garden.position + Vector2(71.0, 30.0), 9.0, Color(0.22, 0.42, 0.28))
	b.circle(garden.position + Vector2(74.0, 88.0), 11.0, LEAF.darkened(0.1))
	b.circle(garden.position + Vector2(72.0, 85.0), 7.0, LEAF.lightened(0.1))
	var rec := RENDERS[1].darkened(0.12).lerp(COOL, 0.10)
	b.rect(Rect2(WALL_L - FACE, rect_top, FACE, 196.0), rec)
	b.line(Vector2(WALL_L - 3.0, rect_top), Vector2(WALL_L - 3.0, rect_top + 196.0), Color(0.0, 0.0, 0.0, 0.07), 5.0)
	b.line(Vector2(WALL_L - FACE + 3.0, rect_top), Vector2(WALL_L - FACE + 3.0, rect_top + 196.0), Color(0.05, 0.06, 0.12, 0.22), 5.0)
	b.line(Vector2(WALL_L, rect_top), Vector2(WALL_L, rect_top + 196.0), SOCLE, 4.0)
	for wi in range(4):
		var wy := rect_top + 30.0 + float(wi) * 44.0
		b.rect(Rect2(WALL_L - 17.5, wy - 10.5, 11.0, 21.0), rec.lightened(0.22))
		b.rect(Rect2(WALL_L - 16.0, wy - 9.0, 8.0, 18.0), SHUTTER_GREEN if wi % 2 == 0 else WINDOW_DARK)
	b.line(Vector2(WALL_L - FACE - 0.5, rect_top), Vector2(WALL_L - FACE - 0.5, rect_top + 196.0), rec.lightened(0.30), 2.4)

	# the church's shadow on the lower roofs to the south of it
	b.rect(Rect2(x0, r.end.y, r.size.x, 16.0), Color(0.05, 0.04, 0.10, 0.22))
	# the aisles: lean-to roofs either side, a storey under the nave's eaves
	var north := tile.lightened(0.08).lerp(WARM, 0.05)
	var south := tile.darkened(0.22).lerp(COOL, 0.05)
	b.rect(Rect2(x0, r.position.y, fx - x0, aisle), north)
	b.rect(Rect2(x0, r.end.y - aisle, fx - x0, aisle), south)
	var ax := x0 + 5.0
	while ax < fx:
		b.line(Vector2(ax, r.position.y + 1.0), Vector2(ax, r.position.y + aisle - 2.0), north.darkened(0.11), 1.0)
		b.line(Vector2(ax, r.end.y - aisle + 2.0), Vector2(ax, r.end.y - 1.0), south.darkened(0.11), 1.0)
		ax += 8.0
	# the nave over them, and the shade its wall drops on the south aisle
	_roof(b, Rect2(x0, r.position.y + aisle, fx - x0, r.size.y - aisle * 2.0), tile, true)
	b.rect(Rect2(x0, r.end.y - aisle, fx - x0, 12.0), Color(0.05, 0.04, 0.10, 0.28))
	b.line(Vector2(x0, r.position.y + aisle), Vector2(fx, r.position.y + aisle), STONE_LIT, 3.0)
	b.line(Vector2(x0, r.end.y - aisle), Vector2(fx, r.end.y - aisle), STONE, 3.0)
	# buttresses between the chapels, capped in stone
	var bx := x0 + 30.0
	while bx < fx - 30.0:
		b.rect(Rect2(bx - 6.0 + Shade.light.x * 6.0, r.end.y - 9.0 + Shade.light.y * 6.0, 12.0, 16.0), SHADOW)
		b.rect(Rect2(bx - 6.0, r.position.y - 7.0, 12.0, 16.0), STONE)
		b.rect(Rect2(bx - 6.0, r.position.y - 7.0, 12.0, 4.0), STONE_LIT)
		b.rect(Rect2(bx - 6.0, r.end.y - 9.0, 12.0, 16.0), STONE.darkened(0.08))
		b.rect(Rect2(bx - 6.0, r.end.y - 9.0, 12.0, 4.0), STONE_LIT.darkened(0.06))
		bx += 86.0
	b.line(Vector2(x0, r.position.y), Vector2(fx, r.position.y), STONE_DARK, 2.0)
	b.line(Vector2(x0, r.end.y), Vector2(fx, r.end.y), STONE_DARK, 2.0)
	# the apse at the far end, a half-round of tile
	b.circle(Vector2(x0, ridge), r.size.y * 0.42, ROOF_TILES[3])
	b.circle(Vector2(x0 - 6.0, ridge), r.size.y * 0.30, ROOF_TILES[3].lightened(0.08))

	# the sacristy's low roof between the nave and the tower's foot
	var sy := r.end.y
	var sh := TOWER.end.y + 12.0 - sy
	_roof(b, Rect2(FAR_L, sy + 16.0, WALL_L - FACE - FAR_L, sh - 16.0), ROOF_TILES[3], true, 9.0)
	b.rect(Rect2(FAR_L, sy, WALL_L - FACE - FAR_L, 16.0), ROOF_TILES[3].darkened(0.24))
	b.rect(Rect2(WALL_L - FACE, sy, FACE, sh), STONE.darkened(0.10))
	b.line(Vector2(WALL_L - FACE, sy), Vector2(WALL_L - FACE, sy + sh), STONE_LIT, 2.0)

	# the front on the plaça: dressed stone between pilasters, in its own
	# shade at this hour; the gable's coping stands over the roof behind
	var top := r.position.y - 6.0
	var bot := r.end.y + 6.0
	b.quad(Vector2(fx, ridge - 78.0) + Shade.light * 7.0, Vector2(fx - 20.0, ridge) + Shade.light * 7.0, Vector2(fx, ridge + 78.0) + Shade.light * 7.0, Vector2(fx, ridge) + Shade.light * 7.0, SHADOW)
	b.quad(Vector2(fx, ridge - 78.0), Vector2(fx - 20.0, ridge), Vector2(fx, ridge + 78.0), Vector2(fx, ridge), STONE_LIT)
	b.quad(Vector2(fx, ridge - 60.0), Vector2(fx - 13.0, ridge), Vector2(fx, ridge + 60.0), Vector2(fx, ridge), STONE)
	b.rect(Rect2(fx, top, 30.0, bot - top), STONE.lerp(COOL, 0.08))
	for ci in range(3):
		b.line(Vector2(fx + 8.0 + float(ci) * 7.0, top), Vector2(fx + 8.0 + float(ci) * 7.0, bot), Color(0.36, 0.32, 0.28, 0.20), 1.0)
	for po: float in PILASTERS:
		b.rect(Rect2(fx + 2.0, ridge + po - 6.0, 28.0, 12.0), STONE_LIT.lerp(COOL, 0.06))
		b.rect(Rect2(fx + 2.0, ridge + po + 4.0, 28.0, 2.0), STONE_DARK)
	b.rect(Rect2(fx + 3.0, top, 5.0, bot - top), Color(0.05, 0.06, 0.12, 0.22))
	b.rect(Rect2(fx - 2.0, top - 2.0, 5.0, bot - top + 4.0), STONE_LIT)
	b.rect(Rect2(fx + 26.0, top, 4.0, bot - top), STONE_DARK)
	# the cross on the gable's point
	b.line(Vector2(fx - 26.0, ridge), Vector2(fx - 14.0, ridge), IRON, 2.0)
	b.line(Vector2(fx - 21.0, ridge - 4.0), Vector2(fx - 21.0, ridge + 4.0), IRON, 2.0)
	# the door in its arch, the rose window over it, a lancet either side
	b.rect(Rect2(fx + 12.0, DOOR_Y - 22.0, 18.0, 44.0), STONE_DARK)
	b.rect(Rect2(fx + 15.0, DOOR_Y - 17.0, 15.0, 34.0), Color(0.34, 0.22, 0.14))
	b.rect(Rect2(fx + 15.0, DOOR_Y - 17.0, 15.0, 16.0), Color(0.40, 0.27, 0.17))
	b.line(Vector2(fx + 15.0, DOOR_Y), Vector2(fx + 30.0, DOOR_Y), Color(0.16, 0.10, 0.07), 1.5)
	b.circle(Vector2(fx + 24.0, DOOR_Y - 3.0), 1.3, BRONZE_LIT)
	b.circle(Vector2(fx + 24.0, DOOR_Y + 3.0), 1.3, BRONZE_LIT)
	var rose := Vector2(fx + 3.0, DOOR_Y)
	b.circle(rose, 10.0, STONE_DARK)
	b.circle(rose, 8.4, STONE_LIT)
	b.circle(rose, 7.0, Color(0.20, 0.24, 0.46))
	for k in range(8):
		var a := float(k) * TAU / 8.0 + 0.39
		b.circle(rose + Vector2.from_angle(a) * 4.4, 1.7, ROSE_GLASS[k % ROSE_GLASS.size()])
	for k in range(4):
		var a := float(k) * TAU / 8.0
		b.line(rose - Vector2.from_angle(a) * 7.0, rose + Vector2.from_angle(a) * 7.0, STONE_LIT, 1.0)
	b.circle(rose, 2.0, STONE_LIT)
	for lo: float in LANCETS:
		b.rect(Rect2(fx + 9.0, DOOR_Y + lo - 5.0, 13.0, 10.0), STONE_DARK)
		b.rect(Rect2(fx + 11.0, DOOR_Y + lo - 3.0, 10.0, 6.0), Color(0.22, 0.28, 0.48))


const PILASTERS: Array[float] = [-116.0, -44.0, 44.0, 116.0]
const LANCETS: Array[float] = [-80.0, 80.0]
const ROSE_GLASS: Array[Color] = [Color(0.86, 0.24, 0.22), Color(0.94, 0.76, 0.26), Color(0.30, 0.52, 0.86), Color(0.36, 0.70, 0.44)]


# The bell tower: the square stone shaft ends in a terrace behind its
# parapet, pinnacles at the corners, and the eight-sided belfry stands on
# it, open to the sky (the bell is drawn live). The clock faces the plaça
# and shows the hour the bells are about to strike.
static func _tower(b: ShapeBatch) -> void:
	var r := TOWER
	var c := r.get_center()
	b.rect(r, STONE_DARK)
	b.rect(Rect2(r.position, Vector2(r.size.x, 3.0)), STONE_LIT)
	b.rect(Rect2(r.position, Vector2(3.0, r.size.y)), STONE_LIT)
	b.rect(r.grow(-6.0), STONE)
	# the parapet's shade on the terrace, and its balusters
	b.rect(Rect2(r.position.x + 6.0, r.position.y + 6.0, r.size.x - 12.0, 6.0), Color(0.05, 0.05, 0.12, 0.26))
	b.rect(Rect2(r.position.x + 6.0, r.position.y + 6.0, 6.0, r.size.y - 12.0), Color(0.05, 0.05, 0.12, 0.26))
	for i in range(1, 10):
		var o := float(i) * 11.0
		b.line(Vector2(r.position.x + o, r.position.y), Vector2(r.position.x + o, r.position.y + 6.0), STONE_DARK.darkened(0.2), 1.2)
		b.line(Vector2(r.position.x + o, r.end.y - 6.0), Vector2(r.position.x + o, r.end.y), STONE.darkened(0.3), 1.2)
		b.line(Vector2(r.position.x, r.position.y + o), Vector2(r.position.x + 6.0, r.position.y + o), STONE_DARK.darkened(0.2), 1.2)
		b.line(Vector2(r.end.x - 6.0, r.position.y + o), Vector2(r.end.x, r.position.y + o), STONE.darkened(0.3), 1.2)
	# the belfry: its shadow on the terrace, its wall, the dark inside
	_oct(b, c + Shade.light * 12.0, 42.0, Color(0.05, 0.05, 0.12, 0.34))
	_oct(b, c, 42.0, STONE_DARK)
	_oct(b, c - Vector2(1.0, 1.5), 40.0, STONE_LIT)
	_oct(b, c + Vector2(1.5, 2.0), 37.0, STONE)
	_oct(b, c, 31.0, Color(0.27, 0.23, 0.21))
	_oct(b, c + Vector2(3.0, 5.0), 26.0, Color(0.34, 0.29, 0.26))
	# the openings the sound goes out by, one to each side of the compass
	b.rect(Rect2(c.x - 8.0, c.y - 41.0, 16.0, 10.0), STONE_DARK.darkened(0.25))
	b.rect(Rect2(c.x - 8.0, c.y + 31.0, 16.0, 10.0), STONE_DARK.darkened(0.25))
	b.rect(Rect2(c.x - 41.0, c.y - 8.0, 10.0, 16.0), STONE_DARK.darkened(0.25))
	b.rect(Rect2(c.x + 31.0, c.y - 8.0, 10.0, 16.0), STONE_DARK.darkened(0.25))
	b.line(Vector2(c.x - 31.0, c.y), Vector2(c.x + 31.0, c.y), BELL_BEAM, 7.0)
	b.line(Vector2(c.x - 31.0, c.y - 2.5), Vector2(c.x + 31.0, c.y - 2.5), BELL_BEAM.lightened(0.2), 1.5)
	b.line(Vector2(c.x, c.y - 31.0), Vector2(c.x, c.y + 31.0), BELL_BEAM.darkened(0.2), 3.0)
	for ci in range(4):
		# the corners in turn: top left, top right, bottom right, bottom left
		var corner := Vector2(r.end.x if ci == 1 or ci == 2 else r.position.x, r.end.y if ci >= 2 else r.position.y)
		var p := corner + (c - corner).normalized() * 11.0
		b.capsule(p + Shade.light * 4.0, p + Shade.light * 16.0, 6.0, Color(0.05, 0.05, 0.12, 0.30))
		b.rect(Rect2(p - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), STONE_DARK)
		b.rect(Rect2(p - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), STONE_LIT)
		# a pinnacle is a little pyramid: two faces lit, two not
		b.quad(p + Vector2(-7.0, 7.0), p + Vector2(7.0, 7.0), p + Vector2(7.0, -7.0), p, STONE.darkened(0.12))
		b.circle(p, 2.2, STONE_LIT.lightened(0.2))
	# the clock on the plaça side, in its stone round
	var ck := Vector2(r.end.x - 2.0, c.y + 30.0)
	b.circle(ck + Shade.light * 3.0, 13.0, Color(0.05, 0.05, 0.12, 0.28))
	b.circle(ck, 13.0, STONE_DARK)
	b.circle(ck, 11.5, STONE_LIT)
	b.circle(ck, 9.6, Color(0.95, 0.93, 0.86))
	for k in range(12):
		var ta := float(k) * TAU / 12.0
		b.line(ck + Vector2.from_angle(ta) * (6.6 if k % 3 == 0 else 7.8), ck + Vector2.from_angle(ta) * 9.0, IRON, 1.6 if k % 3 == 0 else 1.0)
	var hour := float(int(STRIKES.get(_hour(), 7)))
	b.line(ck, ck + Vector2.from_angle(hour * TAU / 12.0 - PI * 0.5) * 5.0, IRON, 2.0)
	b.line(ck, ck + Vector2(0.0, -7.6), IRON, 1.4)
	b.circle(ck, 1.5, BRONZE)


# El Mercat de Sarrià: the brick hall under its long roof, a glazed lantern
# down the ridge, gables at either end; three stone-ringed arches on the
# street, the middle one open
static func _market(b: ShapeBatch) -> void:
	var r := MARKET
	var fx := r.position.x
	var roof := Rect2(fx + FACE, r.position.y + 8.0, r.size.x - FACE, r.size.y - 16.0)
	_roof(b, roof, Color(0.60, 0.36, 0.28), false, 9.0)
	var ridge := roof.get_center().x
	# purlins across the tiles, as a market hall's long roof shows them
	var lx := fx + FACE + 46.0
	while lx < r.end.x - 20.0:
		if absf(lx - ridge) > 34.0:
			b.line(Vector2(lx, roof.position.y), Vector2(lx, roof.end.y), Color(0.0, 0.0, 0.0, 0.10), 1.4)
		lx += 46.0
	# the lantern: iron and glass, the panes toward the sun bright
	var lan := Rect2(ridge - 26.0, r.position.y + 22.0, 52.0, r.size.y - 44.0)
	b.rect(Rect2(lan.position + Shade.light * 9.0, lan.size), Color(0.05, 0.04, 0.10, 0.26))
	b.rect(lan.grow(2.0), IRON)
	b.rect(Rect2(lan.position.x, lan.position.y, 26.0, lan.size.y), GLASS.lightened(0.14))
	b.rect(Rect2(ridge, lan.position.y, 26.0, lan.size.y), GLASS.darkened(0.22))
	var gy := lan.position.y + 16.0
	var pane := 0
	while gy < lan.end.y - 4.0:
		b.line(Vector2(lan.position.x, gy), Vector2(lan.end.x, gy), IRON, 1.2)
		if pane % 3 == 1:
			b.rect(Rect2(lan.position.x + 2.0, gy + 2.0, 22.0, 12.0), Color(1.0, 1.0, 1.0, 0.16))
		gy += 16.0
		pane += 1
	b.line(Vector2(ridge, lan.position.y), Vector2(ridge, lan.end.y), IRON, 2.4)
	# the gables: brick, capped in stone
	b.rect(Rect2(fx + FACE, r.position.y, r.size.x - FACE, 8.0), BRICK.darkened(0.10))
	b.line(Vector2(fx + FACE, r.position.y + 1.5), Vector2(r.end.x, r.position.y + 1.5), STONE_LIT, 3.0)
	b.rect(Rect2(fx + FACE, r.end.y - 8.0, r.size.x - FACE, 8.0), BRICK.darkened(0.22))
	b.line(Vector2(fx + FACE, r.end.y - 6.5), Vector2(r.end.x, r.end.y - 6.5), STONE, 3.0)
	b.rect(Rect2(fx + FACE, r.position.y + 8.0, r.size.x - FACE, 8.0), Color(0.05, 0.04, 0.10, 0.22))
	# the brick front on the street, toward the sun: courses, piers, a stone
	# base and cornice, and the three arches
	b.rect(Rect2(fx, r.position.y, FACE, r.size.y), BRICK.lightened(0.05).lerp(WARM, 0.08))
	for ci in range(3):
		b.line(Vector2(fx + 6.0 + float(ci) * 5.0, r.position.y), Vector2(fx + 6.0 + float(ci) * 5.0, r.end.y), BRICK.darkened(0.14), 1.0)
	b.line(Vector2(fx + FACE - 3.0, r.position.y), Vector2(fx + FACE - 3.0, r.end.y), Color(0.05, 0.06, 0.12, 0.22), 5.0)
	b.line(Vector2(fx + FACE, r.position.y), Vector2(fx + FACE, r.end.y), STONE_LIT, 3.0)
	b.line(Vector2(fx, r.position.y), Vector2(fx, r.end.y), STONE_DARK, 4.0)
	for po: float in MARKET_PIERS:
		b.rect(Rect2(fx + 2.0, MARKET_DOOR_Y + po - 7.0, FACE - 3.0, 14.0), BRICK_LIT.lerp(WARM, 0.10))
		b.rect(Rect2(fx + 2.0, MARKET_DOOR_Y + po + 5.0, FACE - 3.0, 2.0), BRICK.darkened(0.3))
	for ao: float in MARKET_ARCHES:
		var ay := MARKET_DOOR_Y + ao
		var open := absf(ay - MARKET_DOOR_Y) < 1.0
		# the arch's stone ring, its head toward the cornice
		b.rect(Rect2(fx + 1.0, ay - 36.0, FACE - 9.0, 72.0), STONE_LIT)
		b.circle(Vector2(fx + FACE - 9.0, ay), 12.0, STONE_LIT)
		b.rect(Rect2(fx + 2.0, ay - 30.0, FACE - 10.0, 60.0), SHOP_LIGHT.darkened(0.12) if open else GLASS.darkened(0.30))
		b.circle(Vector2(fx + FACE - 9.0, ay), 8.0, SHOP_LIGHT.darkened(0.12) if open else GLASS.darkened(0.30))
		if not open:
			b.line(Vector2(fx + 2.0, ay - 10.0), Vector2(fx + FACE - 6.0, ay - 10.0), IRON, 1.0)
			b.line(Vector2(fx + 2.0, ay + 10.0), Vector2(fx + FACE - 6.0, ay + 10.0), IRON, 1.0)
			b.line(Vector2(fx + 8.0, ay - 30.0), Vector2(fx + 8.0, ay + 30.0), IRON, 1.0)
		else:
			b.rect(Rect2(fx + 2.0, ay - 30.0, 4.0, 60.0), Color(0.36, 0.26, 0.18))


const MARKET_PIERS: Array[float] = [-170.0, -65.0, 65.0, 170.0]


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
	b.circle(f - Vector2(1.0, 1.5), 18.5, STONE_LIT)
	b.circle(f + Vector2(0.5, 1.0), 17.0, STONE)
	b.circle(f + Vector2(4.0, 4.0), 12.0, STONE_DARK)
	b.circle(f + Vector2(4.0, 4.0), 11.0, WATER.darkened(0.12))
	b.circle(f + Vector2(3.0, 3.0), 8.0, WATER)
	b.rect(Rect2(f.x - 8.0 + Shade.light.x * 4.0, f.y - 16.0 + Shade.light.y * 4.0, 16.0, 12.0), SHADOW)
	b.rect(Rect2(f.x - 8.0, f.y - 16.0, 16.0, 12.0), STONE)
	b.rect(Rect2(f.x - 8.0, f.y - 16.0, 16.0, 3.0), STONE_LIT)
	b.rect(Rect2(f.x - 8.0, f.y - 16.0, 3.0, 12.0), STONE_LIT)
	b.line(f + Vector2(0.0, -6.0), f + Vector2(0.0, 2.0), BRONZE, 3.0)
	b.circle(f + Vector2(0.0, -8.0), 2.4, BRONZE_LIT)
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
			_crates(wc, CRATES_2, 1)
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
	# the lit depth of the shop behind the glass, and its doorway
	wc.rect(Rect2(x0 + (FACE * 0.5 if side > 0.0 else 0.0), r.position.y, FACE * 0.5, SHOP_LEN), SHOP_LIGHT.darkened(0.30))
	wc.rect(Rect2(x0, y - 11.0, FACE, 22.0), SHOP_LIGHT.darkened(0.06))
	wc.line(Vector2(x0, y - 12.0), Vector2(x0 + FACE, y - 12.0), STONE_DARK, 2.0)
	wc.line(Vector2(x0, y + 12.0), Vector2(x0 + FACE, y + 12.0), STONE_DARK, 2.0)
	var goods: Array[Color] = GOODS_CAFE
	match kind:
		"fruit": goods = FRUIT_COLS
		"forn": goods = GOODS_FORN
		"farmacia": goods = GOODS_FARMACIA
		"llibreria": goods = GOODS_LLIBRERIA
	var gy := r.position.y + 10.0
	var k := 0
	var gx := x0 + (7.0 if side > 0.0 else FACE - 7.0)
	while gy < r.end.y - 8.0:
		if absf(gy - y) > 15.0:
			var g: Color = goods[(k + i) % goods.size()]
			wc.circle(Vector2(gx + 1.0, gy + 1.5), 4.0, Color(0.0, 0.0, 0.0, 0.22))
			wc.circle(Vector2(gx, gy), 4.0, g)
			wc.circle(Vector2(gx - 1.2, gy - 1.2), 1.6, g.lightened(0.35))
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


static func _crates(wc: ShapeBatch, r: Rect2, v := 0) -> void:
	wc.rect(Rect2(r.position + Shade.light * 6.0, r.size), SHADOW)
	var h := r.size.y / 2.0
	for k in range(2):
		var cr := Rect2(r.position.x, r.position.y + float(k) * h, r.size.x, h - 2.0)
		wc.rect(cr, CRATE_DARK)
		wc.rect(cr.grow(-2.5), CRATE)
		wc.line(Vector2(cr.position.x + 2.5, cr.position.y + 3.0), Vector2(cr.end.x - 2.5, cr.position.y + 3.0), CRATE_DARK.darkened(0.15), 1.6)
		if v == 1 and k == 0:
			# the second bakery's top crate: croissants, and a coca dusted
			# with sugar
			for j in range(6):
				var cc := Vector2(cr.position.x + 8.0 + float(j % 3) * 9.0, cr.position.y + 8.0 + float(j / 3) * 9.0)
				wc.capsule(cc + Vector2(-2.5, 1.0), cc + Vector2(2.5, 1.0), 2.6, BREAD)
				wc.circle(cc + Vector2(0.0, -0.5), 2.2, BREAD_LIT)
			continue
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
	var cols: Array[Color] = FRUIT_COLS
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
	for wi in range(2):
		var wx := r.position.x - 2.0 if wi == 0 else r.end.x - 2.0
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
	if not Outdoors.gardener_on_balcony(_weather(), _hour()):
		# kept in by the weather: her balcony door ajar, and her at the gap
		wc.rect(Rect2(g.x - 6.0, g.y - 12.0, 10.0, 24.0), WINDOW_DARK)
		wc.rect(Rect2(g.x - 6.0, g.y - 12.0, 10.0, 9.0), SHUTTER_GREEN)
		wc.rect(Rect2(g.x - 6.0, g.y + 5.0, 10.0, 7.0), SHUTTER_GREEN)
		wc.circle(Vector2(g.x - 1.0, g.y + 1.0), 4.6, Color(0.86, 0.86, 0.88))
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


# --- overhead: balconies, the shops' awnings and signs, the pharmacy's green cross ---

static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "sarria":
		return
	var b := ShapeBatch.new(ci)
	for side: float in SIDES:
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
		var kind := String(SHOPS[i][2])
		match kind:
			"forn":
				_awning(b, e, side, y, 14.0, Color(0.80, 0.22, 0.20), Color(0.96, 0.92, 0.84))
			"fruit":
				_awning(b, e, side, y, 14.0, Color(0.22, 0.48, 0.30), Color(0.94, 0.92, 0.84))
			"cafe":
				_awning(b, e, side, y, 12.0, Color(0.74, 0.44, 0.26), Color(0.74, 0.44, 0.26).lightened(0.12))
			"farmacia":
				# the green cross on its bracket, out over the street
				var cp := Vector2(e + side * -18.0, y - 40.0)
				b.rect(Rect2(cp.x - 9.0 + Shade.light.x * 14.0, cp.y - 3.0 + Shade.light.y * 14.0, 18.0, 6.0), Color(0.05, 0.06, 0.12, 0.14))
				b.rect(Rect2(cp.x - 3.0 + Shade.light.x * 14.0, cp.y - 9.0 + Shade.light.y * 14.0, 6.0, 18.0), Color(0.05, 0.06, 0.12, 0.14))
				b.line(Vector2(e, cp.y), cp, IRON, 2.0)
				b.rect(Rect2(cp.x - 10.0, cp.y - 4.0, 20.0, 8.0), PHARMACY.darkened(0.35))
				b.rect(Rect2(cp.x - 4.0, cp.y - 10.0, 8.0, 20.0), PHARMACY.darkened(0.35))
				b.rect(Rect2(cp.x - 9.0, cp.y - 3.0, 18.0, 6.0), PHARMACY)
				b.rect(Rect2(cp.x - 3.0, cp.y - 9.0, 6.0, 18.0), PHARMACY)
				b.rect(Rect2(cp.x - 2.0, cp.y - 2.0, 4.0, 4.0), PHARMACY.lightened(0.5))
				_fascia(b, e, side, y, Color(0.92, 0.94, 0.92), PHARMACY)
			"llibreria":
				_fascia(b, e, side, y, Color(0.20, 0.28, 0.42), Color(0.90, 0.80, 0.40))
	b.flush()


# A canvas awning out over a shop door: stripes down its length, a
# scalloped valance on the street edge, and its shade on the pavement
static func _awning(b: ShapeBatch, e: float, side: float, y: float, out: float, col: Color, alt: Color) -> void:
	var x0 := e if side < 0.0 else e - out
	var top := y - SHOP_LEN * 0.5
	var bot := y + SHOP_LEN * 0.5
	b.rect(Rect2(x0 + Shade.light.x * 9.0, top + Shade.light.y * 9.0, out, SHOP_LEN), Color(0.05, 0.06, 0.12, 0.18))
	var stripe := 0
	var sy := top
	while sy < bot:
		b.rect(Rect2(x0, sy, out, minf(12.0, bot - sy)), col if stripe % 2 == 0 else alt)
		sy += 12.0
		stripe += 1
	# the canvas sags from the wall to the bar: lit at the wall, a fold of
	# shade toward the street
	var wall := x0 + (0.0 if side < 0.0 else out)
	var edge := x0 + (out if side < 0.0 else 0.0)
	b.line(Vector2(wall + (-side) * 2.0, top), Vector2(wall + (-side) * 2.0, bot), Color(1.0, 1.0, 1.0, 0.16), 4.0)
	b.line(Vector2(edge + side * 2.5, top), Vector2(edge + side * 2.5, bot), Color(0.0, 0.0, 0.0, 0.14), 3.0)
	b.line(Vector2(edge, top), Vector2(edge, bot), col.darkened(0.30), 2.0)
	var vy := top + 6.0
	while vy < bot:
		b.circle(Vector2(edge - side * 1.0, vy), 2.6, col.darkened(0.12) if int(vy - top) % 24 < 12 else alt.darkened(0.10))
		vy += 12.0
	b.line(Vector2(x0, top), Vector2(x0 + out, top), IRON, 1.4)
	b.line(Vector2(x0, bot), Vector2(x0 + out, bot), IRON, 1.4)


# a shop's signboard along the top of its window, with a row of letters
static func _fascia(b: ShapeBatch, e: float, side: float, y: float, col: Color, ink: Color) -> void:
	var x0 := e if side < 0.0 else e - 7.0
	b.rect(Rect2(x0 + Shade.light.x * 5.0, y - SHOP_LEN * 0.5 + Shade.light.y * 5.0, 7.0, SHOP_LEN), Color(0.05, 0.06, 0.12, 0.16))
	b.rect(Rect2(x0, y - SHOP_LEN * 0.5, 7.0, SHOP_LEN), col)
	var ly := y - 36.0
	while ly < y + 38.0:
		b.rect(Rect2(x0 + 2.0, ly, 3.0, 5.0), ink)
		ly += 8.0


static func _near_shop(y: float, side: float) -> bool:
	for s: Array in SHOPS:
		if float(s[1]) == side and absf(float(s[0]) - y) < SHOP_LEN * 0.5 + 20.0:
			return true
	return false


# A balcony over the street: the stone slab, a light iron railing, and
# what its house keeps on it. One in four has the green roller blind let
# down over the rail against the sun, one in four the washing out.
static func _balcony(b: ShapeBatch, side: float, y: float, k: int, gardener: bool) -> void:
	var e := _front_x(y, side)
	var depth := 14.0
	var x0 := e if side < 0.0 else e - depth
	var len := 50.0 if gardener else 38.0
	var top := y - len * 0.5
	var rx := x0 + (depth if side < 0.0 else 0.0)
	var kind := 0 if gardener else _lot_hash(k, side, 29) % 4
	b.rect(Rect2(x0 + Shade.light.x * 10.0, top + Shade.light.y * 10.0, depth, len), Color(0.05, 0.06, 0.12, 0.20))
	b.rect(Rect2(x0, top, depth, len), STONE_LIT)
	b.rect(Rect2(x0 + 1.5, top + 1.5, depth - 3.0, len - 3.0), Color(0.72, 0.56, 0.44))
	# the wrought-iron railing: a rail and its uprights
	b.line(Vector2(rx, top), Vector2(rx, top + len), IRON_SOFT, 1.4)
	b.line(Vector2(x0, top), Vector2(x0 + depth, top), IRON_SOFT, 1.2)
	b.line(Vector2(x0, top + len), Vector2(x0 + depth, top + len), IRON_SOFT, 1.2)
	var uy := top + 4.0
	while uy < top + len - 2.0:
		b.line(Vector2(rx - 1.6, uy), Vector2(rx + 1.6, uy), IRON_SOFT, 1.0)
		uy += 4.0
	if kind == 1:
		# the persiana: green slats rolled down and hung out over the rail
		var px := rx if side < 0.0 else rx - 9.0
		b.rect(Rect2(px, top + 5.0, 9.0, len - 16.0), SHUTTER_GREEN)
		var py := top + 8.0
		while py < top + len - 12.0:
			b.line(Vector2(px, py), Vector2(px + 9.0, py), SHUTTER_GREEN_LIT, 1.0)
			py += 3.0
	elif kind == 3:
		# washing over the rail
		for i in range(2):
			var wx := rx - (0.0 if side < 0.0 else 7.0)
			b.rect(Rect2(wx, top + 5.0 + float(i) * 15.0, 7.0, 11.0), LAUNDRY[(k + i) % LAUNDRY.size()])
	# pots along the rail, spilling over it
	var n := 5 if gardener else (1 if kind == 1 or kind == 3 else 2 + k % 2)
	for i in range(n):
		var t := 0.5 if n == 1 else float(i) / float(n - 1)
		var pp := Vector2(x0 + depth * 0.5 - side * 1.0, top + 7.0 + t * (len - 14.0))
		if n == 1:
			pp.y = top + len - 7.0
		b.circle(pp, 4.0, POT)
		b.circle(pp + Vector2(-side * 1.5, -1.0), 4.6, LEAF)
		b.circle(pp + Vector2(-side * 4.0, 1.5), 3.0, LEAF.lightened(0.08))
		var bloom: Color = BLOOMS[(i + k) % BLOOMS.size()]
		b.circle(pp + Vector2(-side * 2.0, -2.0), 2.0, bloom)
		b.circle(pp + Vector2(-side * 5.0, 1.0), 1.6, bloom)
		b.circle(pp + Vector2(1.0, 2.0), 1.4, bloom.lightened(0.2))
