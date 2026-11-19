extends RefCounted

# EL METRO: out of the rain and one stop on the metro, at rush hour. The
# game's third indoor walk, after El Veterinari and L'Aeroport.
#
# Walked north, down and through:
# - a rainy street, its pavement laid in panots, to the stair mouth
# - the wet stairs down, a handrail up the middle of them
# - the ticket hall: machines, the attendant's booth, and the turnstiles,
#   where your human fumbles for their card (telegraphed) and a dog slips
#   under the bar
# - the escalator down beside the stairs (main's conveyor carries on it)
# - a tiled passage with a busker in a niche
# - the Paraigües platform: the rush-hour surge, a train emptying onto it
# - the car: one stop, its doors at both ends chiming 0.8 s before they
#   close, the leash caught if it is still across one, the car swaying
# - the Sant Gos platform, the escalator up, the stairs, the street again
#
# The way home is the same in reverse: the train waits at whichever end she
# comes from, the surge pours the same way (now with her), and the turnstile
# fumble happens again from the other side.
#
# No operator's branding: the line roundels, their letters and colours and
# both station names are this walk's own.
#
# The underground is lit by its own lamps, so the world's tint and the sky's
# grade ease from the street's weather and hour to the station's own light
# on the stairs (tick, _apply_light). Rain shows at the two entrances and in
# the wet footprints tracked into the hall.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_bench", "draw_bin", "draw_bollard", "draw_column", "draw_conveyor", "draw_cross_section", "draw_edge_layer", "draw_live", "draw_overhead", "idle_status", "is_lamp", "night_fronts", "on_bark", "surface", "tick", "tree_kind"]


const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const SkyLook := preload("res://systems/sky.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const CurrentFlow := preload("res://systems/current_flow.gd")

# the overhead (the car's outside, the tunnel over the platforms during the
# ride) changes with the train: redrawn at 30 fps (world/overheadlayer.gd)
const OVERHEAD_FOLLOWS_CAMERA := true

const CX := 640.0
const HALF := 260.0                    # the envelope: the ticket hall, wall to wall

# --- the sections, south to north (y grows south; the walk goes north) -------
# Where the width changes the walls splay (the level check holds a corridor
# to 0.85 px sideways per px), and the art lays tile over the corners.
const STREET_HALF := 220.0
const STAIR_TOP := -420.0              # the stair mouth in the pavement
const STAIR_HALF := 150.0
const STAIR_FOOT := -660.0             # the foot of the stairs, the hall splaying out
const TURN_Y := -1230.0                # the turnstile line
const HALL_Y1 := -1560.0               # the hall's far end: escalator and stairs down
const ESC_HALF := 230.0
const PASS_Y0 := -2080.0               # the tiled passage
const PASS_HALF := 165.0
const NICHE_Y0 := -2200.0              # the busker's niche, in the passage's east wall
const NICHE_Y1 := -2440.0
const PLAT_A0 := -2560.0               # Paraigües platform
const PLAT_HALF := 240.0
const CAR_S := -3300.0                 # the car's south end door
const CAR_N := -3900.0                 # its north end door
const CAR_HALF := 150.0
const PLAT_B1 := -4455.0               # Sant Gos platform ends: escalator up
const ESC_B_HALF := 200.0
const STAIR_B0 := -4795.0              # the stairs up
const STREET_B := -4870.0              # back at street level, at the gate

const CAR_L := CX - CAR_HALF           # 490
const CAR_R := CX + CAR_HALF           # 790
const DOOR_HALF := 62.0                # an end door's opening, half its width
const DOOR_L := CX - DOOR_HALF
const DOOR_R := CX + DOOR_HALF
const SEAT_D := 30.0                   # the bench seats along the car's sides
const TRACK_X := 950.0                 # the other track, east of the platforms

# the drawn floors: [north y, south y, west x, east x, kind]. Each taper lies
# inside the wider of the two sections it joins.
const SECTIONS := [
	[STAIR_TOP, 820.0, 420.0, 860.0, "street"],
	[STAIR_FOOT, STAIR_TOP, 490.0, 790.0, "stairs"],
	[HALL_Y1, STAIR_FOOT, 380.0, 900.0, "hall"],
	[PASS_Y0, HALL_Y1, 410.0, 870.0, "esc_a"],
	[PLAT_A0, PASS_Y0, 475.0, 855.0, "passage"],
	[CAR_S - 5.0, PLAT_A0, 400.0, 880.0, "plat_a"],
	[CAR_N + 5.0, CAR_S - 5.0, 490.0, 790.0, "car"],
	[PLAT_B1, CAR_N + 5.0, 400.0, 880.0, "plat_b"],
	[STAIR_B0, PLAT_B1, 440.0, 840.0, "esc_b"],
	[STREET_B, STAIR_B0, 490.0, 790.0, "stairs_b"],
	[-5040.0, STREET_B, 420.0, 860.0, "street_b"],
]

# --- the hall's turnstiles ----------------------------------------------------
# steel cabinets across the hall, each gap between two a gate with a tripod
# bar the dog slips under; the wide gate at the east end is glass flaps
const CAB_W := 26.0
const CAB_D := 56.0
const CAB_XS: Array[float] = [393.0, 477.0, 561.0, 645.0, 729.0]
const CAB_END := Rect2(860.0, TURN_Y - 28.0, 40.0, 56.0)
const GATE_XS: Array[float] = [435.0, 519.0, 603.0, 687.0]
const HUMAN_GATE := 2                  # your human's gate: x 603
const WIDE_GATE := Vector2(742.0, 860.0)
const MACHINES := Rect2(382.0, -1120.0, 34.0, 200.0)
const BOOTH := Rect2(830.0, -1130.0, 68.0, 170.0)
const HALL_COLS: Array[Vector2] = [Vector2(520.0, -1060.0), Vector2(760.0, -1400.0)]
const STAIR_RAIL := Rect2(634.0, -640.0, 12.0, 200.0)
const FUMBLE_WARN := 0.8               # the bubble this long before they stop
const FUMBLE_T := 2.0                  # how long the card takes to find
const FUMBLE_D := 100.0                # how far short of the line they say so

# --- escalators -----------------------------------------------------------
const BAL_A := Rect2(712.0, -1950.0, 16.0, 380.0)
const ESC_A := Rect2(728.0, -1946.0, 142.0, 372.0)
const BAL_B := Rect2(574.0, -4690.0, 16.0, 230.0)
const ESC_B := Rect2(440.0, -4686.0, 134.0, 222.0)

# --- the busker, the platforms ------------------------------------------------
const BUSKER := Vector2(836.0, -2320.0)
const BUSKER_R := Rect2(822.0, -2334.0, 28.0, 28.0)
const BUSKER_BARK_R := 130.0
const PILLARS_A: Array[Vector2] = [Vector2(470.0, -2800.0), Vector2(470.0, -2960.0), Vector2(470.0, -3110.0)]
const PILLARS_B: Array[Vector2] = [Vector2(470.0, -4120.0), Vector2(470.0, -4280.0)]
const CAR_POLES: Array[Vector2] = [Vector2(585.0, -3430.0), Vector2(695.0, -3545.0), Vector2(585.0, -3665.0), Vector2(695.0, -3790.0)]
const VENDING := Rect2(402.0, -4360.0, 40.0, 60.0)
const LAMPS: Array[Vector2] = [Vector2(436.0, 150.0), Vector2(436.0, -200.0)]
const ROUNDEL_POSTS: Array[Vector2] = [Vector2(470.0, -300.0), Vector2(820.0, -4985.0)]
const PRIZE := Vector2(450.0, -2870.0)
const PRIZE_TEXT := "swipe the croissant off the platform bench"

# --- the train ------------------------------------------------------------
const BOARD_IN := 70.0                 # this far inside the car, they are aboard
const CHIME_T := 0.8                   # the chime, then the doors close
const CLOSE_T := 0.5
const CAUGHT_T := 0.6                  # the doors clamp a leash this long
const REOPEN_T := 0.4
const RETRY_T := 1.6                   # after a catch, before they try again
const RIDE_T := 6.0
const BRAKE_T := 1.0
const OPEN_T := 0.5
const TUNNEL_SPEED := 900.0            # the tunnel going by, px/s
const SWAY := 46.0                     # the car's sway, as a shove, px/s
const LURCH := 150.0                   # pulling away and braking, px/s
const HOLD_D := 110.0                  # your human waits this close to a shut door
const CATCH_PULL := 260.0
const DWELL_T := 3.0                   # doors open at a station: nobody is shut in getting off
const PINCH := 6.0                     # half the slot the caught leaves leave the strap (the rope keeps 3 px off a rect)
const DOOR_CLEAR := 10.0               # a body this close to a doorway's line holds the doors

# --- the surge: a train in on the other track, and its crowd ------------------
const SURGE_IN_T := 1.6
const SURGE_OPEN_T := 0.8              # the doors' chime, then the crowd
const SURGE_POUR_T := 3.2              # how long they keep stepping off
const SURGE_STAY_T := 6.0              # the train stands this long after
const SURGE_OUT_T := 2.0
const SURGE_N := 26
const SURGE_DOORS: Array[float] = [-2720.0, -2840.0, -2960.0, -3080.0, -3180.0]
const BOTH: Array[int] = [0, 1]       # her, then your human
const PERSON_R := 13.0
const DOG_R := 12.0
const HUMAN_R := 15.0
const HOLD_NEED := 1.2                 # planted against the crowd this long
const FLOW_MIN := 120.0
const FLOW_MAX := 170.0

# the hall and passage's commuters: down to the platform and up from it, by
# these routes (through a turnstile, down the stairs, along the passage)
const ROUTE_DOWN: Array[Vector2] = [Vector2(700.0, -760.0), Vector2(687.0, -1150.0), Vector2(687.0, -1300.0),
	Vector2(600.0, -1520.0), Vector2(600.0, -1580.0), Vector2(600.0, -1950.0), Vector2(620.0, -2090.0),
	Vector2(600.0, -2560.0), Vector2(760.0, -2700.0), Vector2(830.0, -2800.0)]
const ROUTE_UP: Array[Vector2] = [Vector2(800.0, -2780.0), Vector2(700.0, -2620.0), Vector2(690.0, -2560.0),
	Vector2(690.0, -2100.0), Vector2(560.0, -1950.0), Vector2(560.0, -1580.0), Vector2(519.0, -1480.0),
	Vector2(519.0, -1300.0), Vector2(519.0, -1150.0), Vector2(560.0, -760.0)]
const AMBIENT_N := 6
const AMBIENT_SPEED := 104.0

# --- the light ---------------------------------------------------------------
const UNDER_TINT := Color(0.99, 0.98, 0.95)


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


# --- state ---------------------------------------------------------------------

class Train:
	extends RefCounted
	enum St { DOCKED, CHIME, CLOSING, CAUGHT, REOPEN, RIDE, BRAKE, OPENING }
	var state := St.DOCKED
	var t := 0.0
	# the end whose door is open: 1 the south (docked at Paraigües, about to
	# ride north), -1 the north (docked at Sant Gos)
	var open_end := 1
	var gap_s := 1.0           # the south door: 0 shut .. 1 open
	var gap_n := 0.0
	var cool := 0.0
	var travel := 0.0          # the tunnel gone by, px
	var speed := 0.0
	var rides := 0
	var announced := false
	var caught_gap := 0.0
	var pinch_x := 0.0         # where the caught leaves close on the strap
	var pinch: Array[Rect2] = []   # the caught leaves, while they are in main.rope_rects
	var body_s: CollisionShape2D = null
	var body_n: CollisionShape2D = null
	var solid_s := false       # what each door body was last set to
	var solid_n := false


class Surge:
	extends RefCounted
	enum St { IDLE, ARRIVE, OPEN, POUR, STAY, LEAVE }
	var state := St.IDLE
	var t := 0.0
	var done_out := false
	var done_home := false
	var spawned := 0
	var spawn_due := 0.0
	var n := SURGE_N
	var held_t := 0.0
	var sorry_said := false
	var rng := RandomNumberGenerator.new()


class Turnstile:
	extends RefCounted
	var stage := 0             # 0 waiting, 1 warned, 2 fumbling, 3 through
	var t := 0.0
	var done_out := false
	var done_home := false
	var bar := 0.0             # your human's gate's bar: 0 across .. 1 swung
	var dog_y := 0.0


class State:
	extends RefCounted
	var train := Train.new()
	var surge := Surge.new()
	var gate := Turnstile.new()
	# everyone on foot: dictionaries {p, v, key, mode, t, hop, route, leg, dir}
	var people: Array[Dictionary] = []
	var ambient_due := 0.0
	var ambient_key := 400
	var rng := RandomNumberGenerator.new()
	var under := -1.0          # the light last applied: 0 street .. 1 underground
	var under_on := -1         # which grade was last applied
	var push_human := Vector2.ZERO


# --- corridor -------------------------------------------------------------------

static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": CX, "half": STREET_HALF},
		{"y": -290.0, "cx": CX, "half": STREET_HALF},
		{"y": STAIR_TOP, "cx": CX, "half": STAIR_HALF},
		{"y": STAIR_FOOT, "cx": CX, "half": STAIR_HALF},
		{"y": -860.0, "cx": CX, "half": HALF},
		{"y": -1500.0, "cx": CX, "half": HALF},
		{"y": HALL_Y1, "cx": CX, "half": ESC_HALF},
		{"y": -1960.0, "cx": CX, "half": ESC_HALF},
		{"y": PASS_Y0, "cx": CX, "half": PASS_HALF},
		{"y": NICHE_Y0, "cx": CX, "half": PASS_HALF},
		{"y": -2290.0, "cx": CX + 25.0, "half": PASS_HALF + 25.0},
		{"y": -2350.0, "cx": CX + 25.0, "half": PASS_HALF + 25.0},
		{"y": NICHE_Y1, "cx": CX, "half": PASS_HALF},
		{"y": PLAT_A0, "cx": CX, "half": PASS_HALF},
		{"y": -2770.0, "cx": CX, "half": PLAT_HALF},
		{"y": -3140.0, "cx": CX, "half": PLAT_HALF},
		{"y": CAR_S - 5.0, "cx": CX, "half": CAR_HALF},
		{"y": CAR_N + 5.0, "cx": CX, "half": CAR_HALF},
		{"y": -4060.0, "cx": CX, "half": PLAT_HALF},
		{"y": -4380.0, "cx": CX, "half": PLAT_HALF},
		{"y": PLAT_B1, "cx": CX, "half": ESC_B_HALF},
		{"y": -4700.0, "cx": CX, "half": ESC_B_HALF},
		{"y": STAIR_B0, "cx": CX, "half": STAIR_HALF},
		{"y": STREET_B, "cx": CX, "half": STAIR_HALF},
		{"y": m.GATE_Y, "cx": CX, "half": STREET_HALF},
	]


static func cab_rect(x: float) -> Rect2:
	return Rect2(x - CAB_W * 0.5, TURN_Y - CAB_D * 0.5, CAB_W, CAB_D)


# the car's end walls either side of each door, and its bench seats
static func car_walls() -> Array[Rect2]:
	return [
		Rect2(CAR_L, CAR_S - 6.0, DOOR_L - CAR_L, 12.0), Rect2(DOOR_R, CAR_S - 6.0, CAR_R - DOOR_R, 12.0),
		Rect2(CAR_L, CAR_N - 6.0, DOOR_L - CAR_L, 12.0), Rect2(DOOR_R, CAR_N - 6.0, CAR_R - DOOR_R, 12.0),
	]


static func seats() -> Array[Rect2]:
	return [
		Rect2(CAR_L, -3560.0, SEAT_D, 216.0), Rect2(CAR_L, -3856.0, SEAT_D, 216.0),
		Rect2(CAR_R - SEAT_D, -3560.0, SEAT_D, 216.0), Rect2(CAR_R - SEAT_D, -3856.0, SEAT_D, 216.0),
	]


static func door_rect(end: int) -> Rect2:
	var y := CAR_S if end > 0 else CAR_N
	return Rect2(DOOR_L, y - 6.0, DOOR_R - DOOR_L, 12.0)


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for x: float in CAB_XS:
		out.append(cab_rect(x))
	out.append(CAB_END)
	out.append_array([MACHINES, BOOTH, STAIR_RAIL, BAL_A, BAL_B, VENDING])
	# the busker is a body only while he is there to play
	if Outdoors.underground_busker(Game.weather, Game.hour):
		out.append(BUSKER_R)
	out.append_array(car_walls())
	out.append_array(seats())
	return out


# what the rope winds round or snags on, beyond the poles: the turnstile
# cabinets, the handrails, the escalators' balustrades and the car's seats
static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for x: float in CAB_XS:
		out.append(cab_rect(x))
	out.append(CAB_END)
	out.append_array([STAIR_RAIL, BAL_A, BAL_B])
	out.append_array(car_walls())
	out.append_array(seats())
	return out


# --- build ---------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DE SANT GOS"
	m.gate_l = CX - 200.0
	m.gate_r = CX + 200.0
	var st := State.new()
	st.rng.seed = 5150
	st.surge.rng.seed = 2207
	st.surge.n = Outdoors.underground_crowd(SURGE_N, Game.weather, Game.hour)
	m.metro = st
	m.metro_turnstile_slipped = false
	m.metro_surge_held = false
	m.metro_door_catches = 0
	m.metro_busker_cheered = false
	m.patches.clear()
	m.stalls.clear()
	m.stall_kinds.clear()
	m.tables.clear()
	m.chairs.clear()
	m.parasols.clear()
	m.cellars.clear()
	m.lane_ys = Array([], TYPE_FLOAT, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.vans = Array([], TYPE_VECTOR2, &"", null)
	m.performers = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([], TYPE_VECTOR2, &"", null)
	m.poles.clear()
	for p: Vector2 in LAMPS:
		m.poles.append(p)
	for p: Vector2 in ROUNDEL_POSTS:
		m.poles.append(p)
	m.poles.append(Vector2(CX, STAIR_RAIL.position.y - 4.0))
	m.poles.append(Vector2(CX, STAIR_RAIL.end.y + 4.0))
	for p: Vector2 in HALL_COLS:
		m.poles.append(p)
	for p: Vector2 in PILLARS_A:
		m.poles.append(p)
	for p: Vector2 in CAR_POLES:
		m.poles.append(p)
	for p: Vector2 in PILLARS_B:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()
	m.conveyor_zone = ESC_A
	m.conveyor_dir = Vector2(0, -1)
	m.benches = Array([Vector2(420.0, -2880.0), Vector2(420.0, -3035.0), Vector2(420.0, -4200.0)], TYPE_VECTOR2, &"", null)
	m.bins = Array([Vector2(446.0, 20.0), Vector2(400.0, -1440.0), Vector2(424.0, -2760.0),
		Vector2(420.0, -4070.0), Vector2(830.0, -4978.0)], TYPE_VECTOR2, &"", null)
	# a wet-floor sign at the foot of the stairs, where the rain comes in
	m.cone_spots = Array([Vector2(752.0, -790.0)], TYPE_VECTOR2, &"", null)
	if Outdoors.tracks_wet(Game.weather):
		# the drips off a hundred umbrellas: a film on the hall's tiles
		m.patches.append({"y": -800.0, "at": 0.66, "rx": 32.0, "ry": 20.0, "seed": 9.3,
			"kind": "puddle", "spill": true, "splashes": true})
		if Game.weather == "rain":
			# and a real puddle on the street, where the paving dips by the kerb
			m.patches.append({"y": 60.0, "at": 0.18, "rx": 40.0, "ry": 24.0, "seed": 9.4,
				"kind": "puddle", "splashes": true})
	# the underground is under cover: no rain falls on her there
	m.shelters.append(Rect2(-600.0, STREET_B + 40.0, 2480.0, (STAIR_TOP - 60.0) - (STREET_B + 40.0)))
	# your human goes through the middle gate, keeps to the stairs beside the
	# escalators, and lines up for each of the car's doors
	var g: float = GATE_XS[HUMAN_GATE]
	m.narrows = Array([
		{"y0": TURN_Y - 14.0, "y1": TURN_Y + 14.0, "x0": g - 14.0, "x1": g + 14.0},
		{"y0": CAR_S - 14.0, "y1": CAR_S + 14.0, "x0": DOOR_L + 18.0, "x1": DOOR_R - 18.0},
		{"y0": CAR_N - 14.0, "y1": CAR_N + 14.0, "x0": DOOR_L + 18.0, "x1": DOOR_R - 18.0},
	], TYPE_DICTIONARY, &"", null)
	m.islands = Array([
		{"rect": STAIR_RAIL, "side": -1.0},
		{"rect": BAL_A, "side": -1.0},
		{"rect": BAL_B, "side": 1.0},
	], TYPE_DICTIONARY, &"", null)
	# the waiting passengers on both platforms, by the edge and the pillars
	for w: Vector2 in [Vector2(800.0, -2790.0), Vector2(792.0, -2930.0), Vector2(806.0, -3050.0),
		Vector2(540.0, -2880.0), Vector2(796.0, -3130.0), Vector2(800.0, -4120.0), Vector2(540.0, -4330.0)]:
		st.people.append({"p": w, "v": Vector2.ZERO, "key": 200 + st.people.size() * 7, "mode": "wait",
			"t": 0.0, "hop": 0.0, "face": Vector2.RIGHT if w.x > 700.0 else Vector2.UP})
	# marking spots: a pilona on each street, and underground the fire
	# extinguisher stands along the walls (MetroArt.draw_bollard)
	var hyd: Array[Vector2] = [
		Vector2(444.0, 90.0), Vector2(398.0, -1330.0), Vector2(492.0, -2150.0),
		Vector2(416.0, -2985.0), Vector2(862.0, -4190.0), Vector2(452.0, -4975.0),
	]
	var keb: Array[Vector2] = [
		Vector2(588.0, -880.0), Vector2(720.0, -2420.0), Vector2(700.0, -3020.0), Vector2(640.0, -3720.0), Vector2(620.0, -4250.0),
	]
	return [hyd, keb]


# the dynamic door bodies, one at each end of the car (after the walls)
static func add_doors(m: Node2D) -> void:
	var st: State = m.metro
	if st == null:
		return
	for end: int in [1, -1]:
		var r := door_rect(end)
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		sb.position = r.get_center()
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = r.size
		cs.shape = sh
		sb.add_child(cs)
		m.add_child(sb)
		if end > 0:
			st.train.body_s = cs
		else:
			st.train.body_n = cs
		cs.disabled = true
	_set_door_bodies(m, st.train)


# A door is a body once it is nearly shut, and set only when that changes.
# It never shuts onto someone standing in the doorway: CLOSING reopens for
# them first, and a body stays off while one is there.
static func _set_door_bodies(m: Node2D, tr: Train) -> void:
	var want_s := tr.gap_s <= 0.15 and not door_occupied(m, 1)
	var want_n := tr.gap_n <= 0.15 and not door_occupied(m, -1)
	if want_s != tr.solid_s:
		tr.solid_s = want_s
		if tr.body_s != null:
			tr.body_s.set_deferred("disabled", not want_s)
	if want_n != tr.solid_n:
		tr.solid_n = want_n
		if tr.body_n != null:
			tr.body_n.set_deferred("disabled", not want_n)


# her or your human standing in a doorway's line
static func door_occupied(m: Node2D, end: int) -> bool:
	var y := CAR_S if end > 0 else CAR_N
	for who: int in BOTH:
		var body: Node2D = m.dog if who == 0 else m.human
		if body == null:
			continue    # the walls are built before the pair
		var r := DOG_R if who == 0 else HUMAN_R
		var p: Vector2 = body.global_position
		if absf(p.y - y) < 6.0 + r + DOOR_CLEAR and p.x > DOOR_L - r and p.x < DOOR_R + r:
			return true
	return false


# --- hooks: what things are --------------------------------------------------------

static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return -1
	# the streets, the stone stairs, the car's rubber floor and the
	# escalators' steel: ordinary footing. Everywhere else, glazed tile.
	if p.y > STAIR_FOOT or p.y < STAIR_B0:
		return Surfaces.S.PAVEMENT
	if p.y < CAR_S and p.y > CAR_N:
		return Surfaces.S.PAVEMENT
	if ESC_A.has_point(p) or ESC_B.has_point(p) or in_stairs(p):
		return Surfaces.S.PAVEMENT
	return Surfaces.S.TILE


# on the fixed stairs beside an escalator
static func in_stairs(p: Vector2) -> bool:
	if p.y < HALL_Y1 and p.y > PASS_Y0:
		return p.x < BAL_A.position.x
	if p.y < PLAT_B1 and p.y > STAIR_B0:
		return p.x > BAL_B.end.x
	return false


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return p in LAMPS


static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_NONE


# the street's shopfronts, after dark (world/night_fronts.gd): along the
# east side of the street at the way in, where the shops are. The street at
# Sant Gos is only the stair head below the plaça, and underground has
# none: its light is its own, at every hour.
static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var NF: GDScript = load("res://world/night_fronts.gd")
	var k := 31
	for y: float in [200.0, 40.0, -140.0, -320.0]:
		var kind: String = NF.kind_of(k)
		if kind != "":
			out.append(NF.front(Vector2(CX + STREET_HALF + 4.0, y), -1.0, kind, k))
		k += 3
	return out


# --- per frame --------------------------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	var st: State = m.metro
	if st == null:
		return
	_apply_light(m, st)
	if m.phase == "freedom" or m.frozen:
		return
	# main's conveyor carries on whichever escalator she is nearer
	m.conveyor_zone = ESC_A if m.dog.global_position.y > (CAR_S + CAR_N) * 0.5 else ESC_B
	st.push_human = Vector2.ZERO
	_tick_gate(m, st, delta)
	_tick_train(m, st, delta)
	_tick_surge(m, st, delta)
	_tick_ambient(m, st, delta)
	_tick_people(m, st, delta)
	if st.push_human != Vector2.ZERO:
		m.human.move_and_collide(st.push_human * delta)


# 0 on the street, 1 underground: eased down the stairs at each end
static func under_at(y: float) -> float:
	if y > STAIR_TOP:
		return 0.0
	if y > STAIR_FOOT - 60.0:
		return smoothstep(STAIR_TOP, STAIR_FOOT - 60.0, y)
	if y > STAIR_B0:
		return 1.0
	if y > STREET_B - 30.0:
		return 1.0 - smoothstep(STAIR_B0, STREET_B - 30.0, y)
	return 0.0


# The world's tint and the grade follow the pair down the stairs: the
# street's weather and hour above, the station's own light below. The
# rain on the screen fades out with them.
static func _apply_light(m: Node2D, st: State) -> void:
	if m.phase == "freedom":
		if st.under != 0.0:
			st.under = 0.0
			m.apply_sky()
			st.under_on = 0
		return
	var y: float = (m.dog.global_position.y + m.human.global_position.y) * 0.5
	var u := under_at(y)
	if absf(u - st.under) > 0.002:
		st.under = u
		var sky := SkyLook.tint(m.lvl, Game.sky, Game.time)
		m.night_cm.color = sky.lerp(UNDER_TINT, u)
		if m.weather_fx != null:
			m.weather_fx.modulate.a = 1.0 - u
			m.weather_fx.visible = u < 0.98
	var on := 1 if u > 0.5 else 0
	if on != st.under_on:
		st.under_on = on
		var w: String = "clear" if on == 1 else Game.sky
		var h: String = "day" if on == 1 else Game.time
		m.sky_mod = SkyLook.grade_mod(m.lvl, w, h)
		if m.grade_rect != null and m.mood != null:
			SkyLook.apply(m.grade_rect.material, SkyLook.compose(m.mood.grade(), m.sky_mod))


# The turnstile: a bubble FUMBLE_WARN before they stop at the gate, then the
# card hunt. A dog that crosses the line meanwhile has slipped under a bar.
static func _tick_gate(m: Node2D, st: State, delta: float) -> void:
	var g := st.gate
	var dog: Vector2 = m.dog.global_position
	var hum: Vector2 = m.human.global_position
	var home: bool = m.human.homeward
	var fwd := 1.0 if home else -1.0
	var crossed: bool = (st.gate.dog_y - TURN_Y) * (dog.y - TURN_Y) < 0.0 and (dog.y - TURN_Y) * fwd > 0.0
	g.dog_y = dog.y
	var gx: float = GATE_XS[HUMAN_GATE]
	match g.stage:
		0:
			if (g.done_home if home else g.done_out):
				g.bar = move_toward(g.bar, 0.0, delta * 3.0)
				return
			var short := (TURN_Y - hum.y) * fwd
			if short > 0.0 and short < FUMBLE_D and absf(hum.x - gx) < 120.0:
				g.stage = 1
				g.t = 0.0
				m.human.notice(I18n.t("w_where_s_my_card"), FUMBLE_WARN + FUMBLE_T)
		1, 2:
			g.t += delta
			if g.stage == 1 and g.t >= FUMBLE_WARN:
				g.stage = 2
				g.t = 0.0
			if g.stage == 2:
				m.human.halt_t = maxf(m.human.halt_t, 0.1)
				if g.t >= FUMBLE_T:
					g.stage = 3
					g.t = 0.0
					Sfx.play("ui", 1.6, -8.0)
					m.float_text(Vector2(gx, TURN_Y - 30.0), I18n.t("w_beep"), Color(0.7, 1.0, 0.7))
			if crossed and not m.metro_turnstile_slipped:
				m.metro_turnstile_slipped = true
				m.combo.add("UNDER", 3)
				m.award_points(3, I18n.t("w_under_the_bar_3"))
				m.feed.say(I18n.t("w_under_the_turnstile"), EventFeed.Tone.GOOD)
		3:
			g.bar = move_toward(g.bar, 1.0, delta * 4.0)
			g.t += delta
			if (hum.y - TURN_Y) * fwd > 60.0 or g.t > 4.0:
				g.stage = 0
				if home:
					g.done_home = true
				else:
					g.done_out = true


static func human_in_car(m: Node2D) -> bool:
	var hy: float = m.human.global_position.y
	return hy < CAR_S - 8.0 and hy > CAR_N + 8.0


static func dog_in_car(m: Node2D) -> bool:
	var dy: float = m.dog.global_position.y
	return dy < CAR_S - 8.0 and dy > CAR_N + 8.0


# The end they get on by: the south door on the way out, the north door on
# the way home. The train only leaves with that door open, so a car that has
# just arrived waits for them to get off.
static func boarding_end(m: Node2D) -> int:
	return -1 if m.human.homeward else 1


# the rope across a door's line, inside its opening
static func rope_through(m: Node2D, end: int) -> bool:
	return is_finite(rope_cross_x(m, end))


# where the rope crosses a door's line inside its opening, or INF
static func rope_cross_x(m: Node2D, end: int) -> float:
	var y := CAR_S if end > 0 else CAR_N
	var pts: Array[Vector2] = m.leash.pts
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		if (a.y - y) * (b.y - y) < 0.0:
			var x := lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
			if x > DOOR_L - 6.0 and x < DOOR_R + 6.0:
				return x
	return INF


static func _gap(tr: Train, end: int) -> float:
	return tr.gap_s if end > 0 else tr.gap_n


static func _set_gap(tr: Train, end: int, v: float) -> void:
	if end > 0:
		tr.gap_s = v
	else:
		tr.gap_n = v


static func _tick_train(m: Node2D, st: State, delta: float) -> void:
	var tr := st.train
	var hum: Vector2 = m.human.global_position
	var end := tr.open_end
	var door_y := CAR_S if end > 0 else CAR_N
	var inside := human_in_car(m)
	tr.t += delta
	match tr.state:
		Train.St.DOCKED:
			_set_gap(tr, end, move_toward(_gap(tr, end), 1.0, delta / OPEN_T))
			tr.cool = maxf(0.0, tr.cool - delta)
			# a train always waits at the end she comes to: arriving at the
			# shut end (a walk started past the car, the way home after a
			# ride that never happened), it is the next one in, doors opening
			var far_y := CAR_N if end > 0 else CAR_S
			var beyond := (far_y - hum.y) * float(end) > 40.0 and absf(far_y - hum.y) < 500.0
			if beyond:
				_set_gap(tr, end, 0.0)
				tr.open_end = -end
				tr.state = Train.St.OPENING
				tr.t = 0.0
				Sfx.play("door_chime", 1.12, -6.0)
			elif inside and tr.cool <= 0.0 and end == boarding_end(m) and absf(hum.y - door_y) > BOARD_IN \
					and not door_occupied(m, end):
				tr.state = Train.St.CHIME
				tr.t = 0.0
				Sfx.play("door_chime", 1.0, -4.0)
				m.float_text(Vector2(CX, door_y + 20.0 * float(end)), I18n.t("w_doors_closing"), Color(1, 1, 1), m.POP_SAY)
		Train.St.CHIME:
			if not inside or end != boarding_end(m):
				tr.state = Train.St.DOCKED
				tr.cool = 1.0
			elif tr.t >= CHIME_T:
				tr.state = Train.St.CLOSING
				tr.t = 0.0
		Train.St.CLOSING:
			var g := 1.0 - clampf(tr.t / CLOSE_T, 0.0, 1.0)
			_set_gap(tr, end, g)
			if not inside or door_occupied(m, end):
				# someone stepped back into the doorway: the doors give way
				tr.state = Train.St.REOPEN
				tr.t = 0.0
			elif g < 0.75 and rope_through(m, end):
				_catch(m, tr, end, g)
			elif g <= 0.0 and not dog_in_car(m):
				# shut with her outside and the strap not across the door
				# (round a doorpost): open up rather than ride without her
				tr.state = Train.St.REOPEN
				tr.t = 0.0
			elif g <= 0.0:
				tr.state = Train.St.RIDE
				tr.t = 0.0
				tr.travel = 0.0
				tr.announced = false
				Sfx.play("train_rumble", 1.0, -6.0)
		Train.St.CAUGHT:
			_set_gap(tr, end, tr.caught_gap)
			if tr.t >= CAUGHT_T:
				_unpinch(m, tr)
				tr.state = Train.St.REOPEN
				tr.t = 0.0
		Train.St.REOPEN:
			_set_gap(tr, end, move_toward(_gap(tr, end), 1.0, delta / REOPEN_T))
			if _gap(tr, end) >= 1.0:
				tr.state = Train.St.DOCKED
				tr.cool = RETRY_T
		Train.St.RIDE:
			_keep_aboard(m)
			tr.speed = TUNNEL_SPEED * clampf(tr.t / 1.5, 0.0, 1.0)
			tr.travel += tr.speed * delta
			# pulling away, then the sway: whoever is standing is thrown about
			var dir := -float(end)
			if tr.t < 0.5:
				_shove(m, Vector2(0.0, -dir), LURCH, delta)
			else:
				_shove(m, Vector2(signf(sin(tr.t * 2.4)), 0.0), SWAY * absf(sin(tr.t * 2.4)), delta)
			if not tr.announced and tr.t > RIDE_T * 0.45:
				tr.announced = true
				var next := "Sant Gos" if end > 0 else "Paraigües"
				m.float_text(Vector2(CX, (CAR_S + CAR_N) * 0.5), I18n.t("w_next_station") % next, Color(1.0, 0.9, 0.6), m.POP_SAY)
			if tr.t >= RIDE_T:
				tr.state = Train.St.BRAKE
				tr.t = 0.0
				Sfx.play("groan", 0.7, -10.0)
		Train.St.BRAKE:
			_keep_aboard(m)
			tr.speed = TUNNEL_SPEED * (1.0 - clampf(tr.t / BRAKE_T, 0.0, 1.0))
			tr.travel += tr.speed * delta
			_shove(m, Vector2(0.0, float(-end)), LURCH, delta)
			if tr.t >= BRAKE_T:
				tr.state = Train.St.OPENING
				tr.t = 0.0
				tr.open_end = -end
				tr.rides += 1
				Sfx.play("door_chime", 1.12, -6.0)
				var here := "Sant Gos" if end > 0 else "Paraigües"
				m.float_text(Vector2(CX, CAR_N - 30.0 if end > 0 else CAR_S + 30.0), here + "!", Color(1.0, 0.9, 0.6))
		Train.St.OPENING:
			_set_gap(tr, end, move_toward(_gap(tr, end), 1.0, delta / OPEN_T))
			# the other end stays shut behind them
			_set_gap(tr, -end, 0.0)
			if _gap(tr, end) >= 1.0:
				tr.state = Train.St.DOCKED
				tr.t = 0.0
				# the stop: time to get off before anyone else gets on
				tr.cool = DWELL_T
	_set_door_bodies(m, tr)
	# your human waits at a shut door ahead of them, inside the car
	if inside:
		var ahead := 1 if m.human.homeward else -1
		var ay := CAR_S if ahead > 0 else CAR_N
		if _gap(tr, ahead) < 0.7 and absf(hum.y - ay) < HOLD_D:
			m.human.halt_t = maxf(m.human.halt_t, 0.1)


static func _catch(m: Node2D, tr: Train, end: int, g: float) -> void:
	tr.state = Train.St.CAUGHT
	tr.t = 0.0
	tr.caught_gap = g
	m.metro_door_catches += 1
	_pinch(m, tr, end)
	var door := Vector2(CX, CAR_S if end > 0 else CAR_N)
	Sfx.play("crack", 0.7, -6.0)
	m.feed.say(I18n.t("w_the_doors_caught_the_leash"), EventFeed.Tone.LOUD)
	m.float_text(door, I18n.t("w_thunk"), Color(1.0, 0.85, 0.6))
	var to_door: Vector2 = door - m.dog.global_position
	if to_door.length() > 1.0 and m.dog.tumble_t <= 0.0:
		m.dog.velocity = to_door.normalized() * CATCH_PULL
	m.human.patience = maxf(0.0, m.human.patience - 0.25)
	m.human.notice(I18n.t("w_hey_the_doors"), 1.4)


# The caught leaves close on the strap: while CAUGHT they are two solid
# rects in main.rope_rects, the same list the rope's solver keeps out of
# every stall and bench, with PINCH either side of where it crosses. Each
# reaches across its end wall to the car's side, so a strap pulled sideways
# is put back toward the slot rather than past a leaf's outer edge. The
# rope is pressed into that slot by its own solver; nothing else holds it.
static func _pinch(m: Node2D, tr: Train, end: int) -> void:
	_unpinch(m, tr)
	var y := CAR_S if end > 0 else CAR_N
	var x := rope_cross_x(m, end)
	if not is_finite(x):
		x = CX
	x = clampf(x, DOOR_L + PINCH + 4.0, DOOR_R - PINCH - 4.0)
	tr.pinch_x = x
	tr.pinch = [Rect2(CAR_L, y - 6.0, x - PINCH - CAR_L, 12.0), Rect2(x + PINCH, y - 6.0, CAR_R - x - PINCH, 12.0)]
	m.rope_rects.append_array(tr.pinch)


static func _unpinch(m: Node2D, tr: Train) -> void:
	for r: Rect2 in tr.pinch:
		var i: int = m.rope_rects.rfind(r)
		if i >= 0:
			m.rope_rects.remove_at(i)
	tr.pinch.clear()


# Riding, both of them are aboard. If a door ever shut with her on the
# platform side (pushed through it in a crush), she is put back in the car
# beside your human rather than left a carriage away on a stretched leash.
static func _keep_aboard(m: Node2D) -> void:
	if dog_in_car(m):
		return
	var hum: Vector2 = m.human.global_position
	var y := clampf(hum.y + (40.0 if hum.y < (CAR_S + CAR_N) * 0.5 else -40.0), CAR_N + 30.0, CAR_S - 30.0)
	m.dog.global_position = Vector2(clampf(hum.x + 30.0, CAR_L + SEAT_D + DOG_R, CAR_R - SEAT_D - DOG_R), y)
	m.dog.velocity = Vector2.ZERO
	m.leash.resnap()


# the car throwing everyone in it about; a planted dog stands it better
static func _shove(m: Node2D, dir: Vector2, speed: float, delta: float) -> void:
	if not human_in_car(m):
		return
	var planted: bool = m.dog.planted
	CurrentFlow.shove_body(m.dog, true, dir, speed, speed * 0.3, planted, delta)
	CurrentFlow.shove_body(m.human, true, dir, speed * 0.6, speed * 0.6, false, delta)


# The surge: a train in on the other track, the chime, and 0.8 s later its
# crowd pours off and down the platform to the passage, against her on the
# way out and with her on the way home.
static func _tick_surge(m: Node2D, st: State, delta: float) -> void:
	var s := st.surge
	var hum: Vector2 = m.human.global_position
	var home: bool = m.human.homeward
	s.t += delta
	match s.state:
		Surge.St.IDLE:
			var due := false
			if home:
				due = not s.done_home and hum.y > CAR_S + 90.0 and hum.y < PLAT_A0 - 200.0
			else:
				due = not s.done_out and hum.y < PLAT_A0 - 90.0 and hum.y > CAR_S + 120.0
			if due:
				if home:
					s.done_home = true
				else:
					s.done_out = true
				s.state = Surge.St.ARRIVE
				s.t = 0.0
				s.spawned = 0
				s.held_t = 0.0
				s.sorry_said = false
				Sfx.play("train_rumble", 0.8, -4.0)
				m.feed.say(I18n.t("w_train_in_here_comes_rush_hour"), EventFeed.Tone.LOUD)
		Surge.St.ARRIVE:
			if s.t >= SURGE_IN_T:
				s.state = Surge.St.OPEN
				s.t = 0.0
				Sfx.play("door_chime", 0.94, -4.0)
				m.float_text(Vector2(880.0, hum.y - 40.0), I18n.t("w_ding_dong"), Color(1.0, 0.92, 0.6))
		Surge.St.OPEN:
			if s.t >= SURGE_OPEN_T:
				s.state = Surge.St.POUR
				s.t = 0.0
				s.spawn_due = 0.0
		Surge.St.POUR:
			s.spawn_due += delta * float(s.n) / SURGE_POUR_T
			while s.spawn_due >= 1.0 and s.spawned < s.n:
				s.spawn_due -= 1.0
				_spawn_off(st, s)
			# the platform's waiting passengers get on once the crowd is off
			if s.t > 1.6:
				for p: Dictionary in st.people:
					if p.mode == "wait" and float(p.p.y) > CAR_S and float(p.p.y) < PLAT_A0:
						p.mode = "board"
						p.t = 0.0
			if s.spawned >= s.n:
				s.state = Surge.St.STAY
				s.t = 0.0
		Surge.St.STAY:
			if s.t >= SURGE_STAY_T:
				s.state = Surge.St.LEAVE
				s.t = 0.0
				Sfx.play("door_chime", 0.94, -8.0)
				Sfx.play("train_rumble", 0.9, -8.0)
		Surge.St.LEAVE:
			if s.t >= SURGE_OUT_T:
				s.state = Surge.St.IDLE
				s.t = 0.0
	# dug in against the crowd while it is pouring past her
	if s.state == Surge.St.POUR or s.state == Surge.St.STAY:
		if m.dog.planted and _crowd_near(st, m.dog.global_position, PERSON_R + DOG_R + 10.0):
			s.held_t += delta
			if s.held_t >= HOLD_NEED and not m.metro_surge_held:
				m.metro_surge_held = true
				m.combo.add("ROCK", 4)
				m.award_points(4, I18n.t("w_rock_solid_4"))
				m.feed.say(I18n.t("w_rock_solid_in_the_rush"), EventFeed.Tone.GOOD)


static func surge_live(m: Node2D) -> bool:
	var s: Surge = m.metro.surge if m.metro != null else null
	return s != null and s.state != Surge.St.IDLE


static func _crowd_near(st: State, p: Vector2, r: float) -> bool:
	for q: Dictionary in st.people:
		if q.mode == "flow" and (q.p as Vector2).distance_to(p) < r:
			return true
	return false


static func _spawn_off(st: State, s: Surge) -> void:
	var dy: float = SURGE_DOORS[s.spawned % SURGE_DOORS.size()] + s.rng.randf_range(-24.0, 24.0)
	var lane := s.rng.randf_range(520.0, 880.0)
	st.people.append({"p": Vector2(908.0, dy), "v": Vector2(-150.0, 0.0), "key": 600 + s.spawned * 11,
		"mode": "off", "t": 0.0, "hop": 0.0, "lane": lane, "speed": s.rng.randf_range(FLOW_MIN, FLOW_MAX),
		"face": Vector2.LEFT})
	s.spawned += 1


# the hall's own commuters, down to the platform and up from it, spawned out
# of sight (and fewer after dark or at first light: Outdoors)
static func _tick_ambient(m: Node2D, st: State, delta: float) -> void:
	st.ambient_due -= delta
	if st.ambient_due > 0.0:
		return
	st.ambient_due = 2.6
	var n := 0
	for p: Dictionary in st.people:
		if p.mode == "route":
			n += 1
	if n >= Outdoors.underground_crowd(AMBIENT_N, Game.weather, Game.hour):
		return
	var cy: float = m.cam.position.y
	var down := st.rng.randf() < 0.5
	var route: Array[Vector2] = ROUTE_DOWN if down else ROUTE_UP
	# start at whichever end of the route is out of view
	var i0 := 0
	if absf(route[0].y - cy) < 520.0:
		if absf(route[route.size() - 1].y - cy) < 520.0:
			return
		i0 = route.size() - 1
	st.ambient_key += 13
	st.people.append({"p": route[i0], "v": Vector2.ZERO, "key": st.ambient_key, "mode": "route",
		"t": 0.0, "hop": 0.0, "down": down, "i": i0, "step": 1 if i0 == 0 else -1,
		"off": Vector2(st.rng.randf_range(-16.0, 16.0), 0.0), "face": Vector2.DOWN})


static func _tick_people(m: Node2D, st: State, delta: float) -> void:
	var dog: Vector2 = m.dog.global_position
	var hum: Vector2 = m.human.global_position
	var taut: bool = m.leash.taut
	var pts: Array[Vector2] = m.leash.pts
	var keep: Array[Dictionary] = []
	for p: Dictionary in st.people:
		p.t = float(p.t) + delta
		p.hop = maxf(0.0, float(p.hop) - delta)
		var pos: Vector2 = p.p
		var want := Vector2.ZERO
		match String(p.mode):
			"wait":
				pass
			"board":
				# to the train's doors and in
				want = Vector2(1.0, 0.0) * 90.0
				if pos.x > 930.0:
					continue
			"off":
				want = Vector2(-1.0, 0.0) * 150.0
				if pos.x < float(p.lane):
					p.mode = "flow"
			"flow":
				var sp: float = p.speed
				var weave := sin(float(p.t) * 1.7 + float(p.key)) * 22.0
				want = Vector2((float(p.lane) - pos.x) * 1.4 + weave, sp)
				if pos.y > PASS_Y0 + 120.0 or float(p.t) > 22.0:
					continue
			"route":
				var route: Array[Vector2] = ROUTE_DOWN if bool(p.down) else ROUTE_UP
				var i := int(p.i)
				var tgt: Vector2 = route[i] + (p.off as Vector2)
				if pos.distance_to(tgt) < 14.0:
					i += int(p.step)
					if i < 0 or i >= route.size():
						continue
					p.i = i
					tgt = route[i] + (p.off as Vector2)
				want = (tgt - pos).normalized() * AMBIENT_SPEED
				if absf(pos.y - float(m.cam.position.y)) > 1400.0:
					continue
		# step round her and your human, and shove them
		for who: int in BOTH:
			var body: Vector2 = dog if who == 0 else hum
			var r := PERSON_R + (DOG_R if who == 0 else HUMAN_R)
			var d := pos - body
			var dl := d.length()
			if dl < r and dl > 0.01:
				var n := d / dl
				var over := r - dl
				pos += n * over * (0.7 if who == 0 and m.dog.planted else 0.45)
				if String(p.mode) == "wait":
					continue
				if who == 0:
					var k := 0.25 if m.dog.planted else 0.9
					m.dog.move_and_collide(-n * over * k + Vector2(0.0, signf(want.y)) * 40.0 * k * delta)
				else:
					st.push_human += -n * over * 6.0
					if not st.surge.sorry_said and String(p.mode) == "flow":
						st.surge.sorry_said = true
						m.float_text(pos + Vector2(0, -24), I18n.t("w_sorry"), Color(1, 1, 1), m.POP_SAY)
		# a taut leash across their way: a hop over it, and the pair carried a little with them
		if taut and String(p.mode) == "flow" and float(p.hop) <= 0.0:
			for i in range(0, pts.size() - 1, 2):
				if Geometry2D.get_closest_point_to_segment(pos, pts[i], pts[i + 1]).distance_to(pos) < 9.0:
					p.hop = 0.32
					var carry := Vector2(0.0, 1.0) * 22.0
					st.push_human += carry
					m.dog.move_and_collide(carry * delta)
					break
		pos += want * delta
		# within the walls
		var e: Vector2 = m.walk_edges(pos.y)
		if String(p.mode) != "off" and String(p.mode) != "board":
			pos.x = clampf(pos.x, e.x + PERSON_R, e.y - PERSON_R)
		if want.length() > 1.0:
			p.face = (p.face as Vector2).slerp(want.normalized(), minf(1.0, 8.0 * delta))
		p.v = want
		p.p = pos
		keep.append(p)
	st.people = keep


# --- barks, the banner -----------------------------------------------------------

static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.metro_busker_cheered or pos.distance_to(BUSKER) > BUSKER_BARK_R:
		return
	if not Outdoors.underground_busker(Game.weather, Game.hour):
		return
	m.metro_busker_cheered = true
	m.float_text(BUSKER + Vector2(0, -30), I18n.t("w_oompah"), Color(1.0, 0.92, 0.6))
	m.award_points(2, I18n.t("w_encore_2"))


static func idle_status(m: Node2D) -> String:
	var st: State = m.metro
	if st == null:
		return ""
	var tr := st.train
	if (tr.state == Train.St.CHIME or tr.state == Train.St.CLOSING) and rope_through(m, tr.open_end):
		return I18n.t("walk_metro_doors")
	if st.surge.state == Surge.St.OPEN or st.surge.state == Surge.St.POUR:
		return I18n.t("walk_metro_rush")
	return ""


# --- drawing: systems/metro_art.gd -------------------------------------------------------

# loaded, not preloaded: the art preloads this script for its layout
static func _art() -> GDScript:
	return load("res://systems/metro_art.gd")


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	_art().draw_ground(m, wc, ctop, vt, vb)


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	_art().draw_edges(m, b, vt, vb)


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	_art().draw_live(m, wc, vt, vb)


static func draw_conveyor(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	_art().draw_escalators(m, wc, vt, vb)


static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	_art().draw_overhead(m, c)


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	_art().draw_column(m, wc, p)


static func draw_bench(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	_art().draw_bench(m, wc, p)


static func draw_bin(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	_art().draw_bin(m, wc, p)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	_art().draw_bollard(m, wc, h)
