class_name Blai
extends RefCounted

# WALK: CARRER DE BLAI, Poble-sec's pintxos street at the foot of Montjuïc.
#
# One narrow pedestrian street, bar after bar down both sides, walked up to
# Plaça del Sortidor. The terraces spill onto the paving, groups stand out
# with a drink, waiters carry trays through the lot, strings of bulbs hang
# across overhead, and the floor is a dog's paradise: dropped pintxos on
# their napkins all the way up. Two cross streets cut it (their mouths
# closed by pilones), and half way up it opens on the left into a little
# square, the placeta, with its plane trees and the biggest terrace.
#
# Temptation is the walk. Your human does not want her eating off the
# floor: heading for a dropped pintxo gets "Leave it!" (LEAVE_LEAD before
# she can reach it at the speed she is closing, so always at least 0.8 s),
# and eating it while told costs a third of their patience (none in the
# grace after a correction). Leaving it (turning off it, or staying out of
# reach until the telling stands down) pays, and gives a little patience back. A pintxo
# given from a terrace (sit pretty by a diner) or caught in the air is not
# off the floor, and is fine.
#
# Live event: the waiter's tray. Waiters cross from the bar to a terrace
# with a full tray; bump one or bark at one and the tray rocks ("Whoa,
# whoa!", 0.8 s), then goes, six pintxos flying. Catch one before it lands.
# Then your human says leave the rest. The placeta's waiter's tray goes on
# its own the first time she passes (a chair leg), so every walk sees it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const Panot := preload("res://world/panot.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EdgePath := preload("res://world/edge_path.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const SkyLook := preload("res://systems/sky.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")

# --- the street's shape ---------------------------------------------------------
const CX := 640.0
const HALF := 210.0                 # facade to facade
const WALL_L := CX - HALF           # 430
const WALL_R := CX + HALF           # 850
# the placeta opens on the left between these, its back wall at PL_L
const PL_Y0 := -2400.0
const PL_Y1 := -2960.0
const PL_RAMP := 180.0
const PL_L := 290.0
# the cross streets, and how wide their mouths are each side of the line
const XINGS: Array[float] = [-1240.0, -3700.0]
const XHALF := 62.0
const START := 260.0
const GATE := -5000.0

# --- the bars -----------------------------------------------------------------------
# [side, y of the door, half its frontage, always open (a waiter's kitchen),
# a terrace along its wall]
const BARS: Array = [
	[-1.0, -380.0, 60.0, false, false],
	[1.0, -620.0, 70.0, false, true],
	[-1.0, -880.0, 66.0, false, true],
	[1.0, -1060.0, 56.0, false, false],
	[-1.0, -1470.0, 70.0, false, true],
	[1.0, -1620.0, 64.0, true, false],
	[-1.0, -1830.0, 58.0, false, false],
	[1.0, -1990.0, 74.0, false, true],
	[-1.0, -2160.0, 52.0, false, true],
	[-1.0, -2680.0, 84.0, false, false],
	[1.0, -2700.0, 64.0, true, false],
	[1.0, -3200.0, 70.0, false, true],
	[-1.0, -3430.0, 60.0, false, true],
	[1.0, -3990.0, 66.0, false, true],
	[-1.0, -4170.0, 70.0, true, false],
	[1.0, -4420.0, 60.0, false, true],
]
# each bar's awning and sign, by its index
const BAR_COLS: Array[Color] = [
	Color(0.62, 0.16, 0.14), Color(0.16, 0.36, 0.26), Color(0.86, 0.62, 0.18),
	Color(0.20, 0.30, 0.52), Color(0.48, 0.20, 0.36), Color(0.86, 0.44, 0.20),
	Color(0.28, 0.46, 0.44), Color(0.70, 0.22, 0.20),
]
# a terrace: tables this far in from the wall, chairs either side of them
const T_IN := 46.0
const T_PAIR := 36.0
const CHAIR_IN: Array[float] = [16.0, 76.0]
# the placeta's own terrace, in front of its bar, and what the routing
# treats as an island (your human keeps to the far side of it)
const PL_TABLES: Array[Vector2] = [
	Vector2(360.0, -2560.0), Vector2(360.0, -2690.0), Vector2(360.0, -2820.0),
	Vector2(445.0, -2625.0), Vector2(445.0, -2755.0),
]
const PL_TERRACE := Rect2(300.0, -2870.0, 200.0, 350.0)
const PL_TREES: Array[Vector2] = [Vector2(340.0, -2452.0), Vector2(340.0, -2905.0)]
# the waiters' runs: from a kitchen's door to the edge of a terrace across
# the street. The first is the placeta's, whose tray goes on its own once.
const RUNS: Array = [
	[Vector2(832.0, -2700.0), Vector2(500.0, -2690.0)],
	[Vector2(832.0, -1620.0), Vector2(528.0, -1480.0)],
	[Vector2(448.0, -4170.0), Vector2(752.0, -4410.0)],
]
const PRIZE := Vector2(838.0, -2752.0)
const PRIZE_TEXT := "snatch the tortilla pintxo off the bar's window"
# where groups stand with a drink in the evening: [x, y] centres by a door
const STAND_GROUPS: Array[Vector2] = [
	Vector2(476.0, -330.0), Vector2(804.0, -1100.0), Vector2(476.0, -1780.0),
	Vector2(800.0, -2620.0), Vector2(800.0, -3100.0), Vector2(476.0, -4100.0),
	Vector2(804.0, -4800.0),
]
const GROUP_R := 15.0
# the bars whose doorways people shelter in from the rain
const DOORWAY_BARS: Array[int] = [0, 3, 5, 6, 10, 14]

# --- tuning: the floor, the leave-it and the trays ---------------------------------
const LEAVE_SEE := 96.0         # px: the least warning distance, at a dawdle
const LEAVE_LEAD := 0.9         # s: warned this long before she can bite at her closing speed (0.8 s and a margin)
const LEAVE_AIM := 56.0         # px: the pintxo is this near her line of travel: she is on course for it
const LEAVE_REACH_MAX := 720.0  # px: past this nobody is reading her course (a fast dog in turbo needs ~660)
const EAT_R := 26.0             # px: main.gd's floor-food bite radius
const LEAVE_HEAD := 18.0        # px/s toward it that counts as heading for it
const LEAVE_BACKOFF := 40.0     # px back off her nearest approach: she has turned away from it
const LEAVE_CLOSE := 54.0       # px: this close counts whatever she is doing
const LEAVE_HUMAN := 320.0      # px: your human sees this far
const LEAVE_T := 2.2            # s the "Leave it!" stands
const LEAVE_PASS := 140.0       # px from it when the telling stands down: out of reach, she has left it
const LEAVE_SPILL_T := 3.0
const LEAVE_SPILL_R := 150.0
const LEAVE_COST := 0.34        # patience, for eating it while told
const LEAVE_BACK := 0.25        # patience back for leaving it
const LEAVE_PAY := 2
const LEAVE_SPILL_PAY := 4
const LEAVE_COOL := 1.2         # s before the same nag again
const SPILL_WAIT := 2.5         # s the spill's "Leave it! All of it!" waits for your human to be free to say it
const WAITER_SPEED := 118.0
const WAITER_NEAR := 460.0      # px along the street: a run starts once she is this near
const WAITER_REST := 5.0
const WAITER_BUMP := 30.0
const WAITER_BARK := 110.0
const WAITER_YIELD := 46.0
const WOBBLE_T := 0.8           # the tray rocks this long before it goes, as every event
const SPILL_N := 6
const SPILL_ARC := 34.0
const CATCH_R := 24.0
const CATCH_PAY := 3
const TIP_COST := 0.12          # patience: her doing, in front of everyone
const BEG_R := 46.0
const BEG_STILL := 25.0
const BEG_T := 1.4
const BEG_PAY := 3

const BEG_LINES: Array[String] = ["Go on, then.", "Who's a hungry one?", "Just the one!", "Here, sweetie."]

# --- colours -----------------------------------------------------------------------
const PAVE := Color(0.67, 0.64, 0.59)
const PANOT_INK := Color(0.10, 0.08, 0.06, 0.12)
const PANOT_SHINE := Color(1.0, 0.97, 0.92, 0.08)
const SLAB := Color(0.71, 0.69, 0.65)
const SLAB_JOINT := Color(0.56, 0.54, 0.51)
const RIGOLA := Color(0.48, 0.47, 0.46)
const RIGOLA_SETT := Color(0.56, 0.55, 0.53)
const STAIN := Color(0.24, 0.14, 0.12, 0.10)
const NAPKIN := Color(0.95, 0.94, 0.90)
const NAPKIN_SHADE := Color(0.80, 0.78, 0.74)
const TOOTHPICK := Color(0.86, 0.74, 0.52)
const ASPHALT := Color(0.26, 0.26, 0.28)
const SIDE_PAVE := Color(0.62, 0.60, 0.56)
const KERB := Color(0.52, 0.51, 0.49)
const ZEBRA := Color(0.88, 0.87, 0.82, 0.92)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
const ROOF_TONES: Array[Color] = [
	Color(0.74, 0.50, 0.38), Color(0.82, 0.70, 0.56), Color(0.68, 0.46, 0.36),
	Color(0.78, 0.62, 0.50), Color(0.72, 0.60, 0.54), Color(0.86, 0.76, 0.62),
	Color(0.64, 0.52, 0.46),
]
const BACK_TONES: Array[Color] = [
	Color(0.62, 0.46, 0.38), Color(0.70, 0.60, 0.50), Color(0.58, 0.48, 0.42),
]
const PARAPET := Color(0.90, 0.86, 0.78)
const STAIR_HOUSE := Color(0.84, 0.80, 0.72)
const TANK := Color(0.80, 0.80, 0.78)
const BALCONY := Color(0.18, 0.17, 0.16)
const PATIO := Color(0.34, 0.36, 0.32)
const PLANT := Color(0.30, 0.46, 0.26)
const PLANT_LIT := Color(0.40, 0.56, 0.32)
const LAUNDRY: Array[Color] = [
	Color(0.92, 0.90, 0.86), Color(0.36, 0.52, 0.74), Color(0.86, 0.40, 0.36),
	Color(0.94, 0.80, 0.30), Color(0.50, 0.66, 0.46),
]
const SHUTTER := Color(0.56, 0.57, 0.58)
const SHUTTER_RIB := Color(0.44, 0.45, 0.47)
const TAG_COLS: Array[Color] = [
	Color(0.80, 0.24, 0.40), Color(0.20, 0.56, 0.72), Color(0.92, 0.78, 0.20), Color(0.20, 0.20, 0.22),
]
const SILL := Color(0.52, 0.36, 0.22)
const SILL_LIT := Color(0.64, 0.46, 0.28)
const BREAD := Color(0.86, 0.68, 0.40)
const BREAD_DARK := Color(0.68, 0.48, 0.26)
const TOPPINGS: Array[Color] = [
	Color(0.96, 0.82, 0.30),   # tortilla
	Color(0.80, 0.18, 0.16),   # piquillo pepper
	Color(0.62, 0.20, 0.14),   # chorizo
	Color(0.70, 0.46, 0.22),   # croqueta
	Color(0.34, 0.40, 0.24),   # olive and anchovy
]
const PLATE := Color(0.95, 0.94, 0.90)
const MARBLE := Color(0.90, 0.88, 0.84)
const IRON := Color(0.18, 0.18, 0.20)
const BEER := Color(0.94, 0.68, 0.18)
const FOAM := Color(0.98, 0.97, 0.92)
const VERMUT := Color(0.56, 0.12, 0.10)
const TRAY := Color(0.80, 0.82, 0.86)
const TRAY_LIT := Color(0.95, 0.96, 0.98)
const WAITER_SHIRT := Color(0.95, 0.95, 0.94)
const APRON := Color(0.14, 0.14, 0.16)
const CRATE := Color(0.20, 0.42, 0.26)
const KEG := Color(0.70, 0.72, 0.74)
const BULB := Color(1.0, 0.86, 0.52)
const WIRE := Color(0.10, 0.10, 0.11, 0.85)


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


# --- shape -------------------------------------------------------------------------

static func edge_nodes(_m: Node2D = null) -> Array:
	var pl_cx := (PL_L + WALL_R) * 0.5
	var pl_half := (WALL_R - PL_L) * 0.5
	return [
		{"y": START, "cx": CX, "half": HALF},
		{"y": PL_Y0 + PL_RAMP, "cx": CX, "half": HALF},
		{"y": PL_Y0, "cx": pl_cx, "half": pl_half},
		{"y": PL_Y1, "cx": pl_cx, "half": pl_half},
		{"y": PL_Y1 - PL_RAMP, "cx": CX, "half": HALF},
		{"y": GATE, "cx": CX, "half": HALF},
	]


# (left, right) facade at y: what main.walk_edges says, without a main
static func edges_at(y: float) -> Vector2:
	return EdgePath.edges(edge_nodes(), y, CX, HALF)


static func wall_x(y: float, side: float) -> float:
	var e := edges_at(y)
	return e.x if side < 0.0 else e.y


static func in_xing(y: float, pad := 0.0) -> bool:
	for xi: float in XINGS:
		if absf(y - xi) < XHALF + pad:
			return true
	return false


static func in_placeta(p: Vector2) -> bool:
	return p.y < PL_Y0 + 40.0 and p.y > PL_Y1 - 40.0 and p.x < WALL_L


# Whether bar i is open in this sky: every one at night, a hash's share of
# them shuttered by day; a waiter's kitchen is always open.
static func bar_open(i: int, hour: String) -> bool:
	if bool(BARS[i][3]):
		return true
	return _h(i * 7 + 3) >= Outdoors.bar_shutters("clear", hour)


static func door_at(i: int) -> Vector2:
	var side: float = BARS[i][0]
	var y: float = BARS[i][1]
	return Vector2(wall_x(y, side), y)


# the terraces along the walls: [tables, chairs], each chair with its table
static func street_terraces() -> Array:
	var tables: Array[Vector2] = []
	var chairs: Array[Vector2] = []
	var chair_table: Array[Vector2] = []
	for i in range(BARS.size()):
		if not bool(BARS[i][4]):
			continue
		var side: float = BARS[i][0]
		var y: float = BARS[i][1]
		var wx := wall_x(y, side)
		var s_in := -side
		for dy: float in [-T_PAIR, T_PAIR]:
			var tb := Vector2(wx + s_in * T_IN, y + dy)
			tables.append(tb)
			for ci: float in CHAIR_IN:
				chairs.append(Vector2(wx + s_in * ci, y + dy))
				chair_table.append(tb)
	for tb: Vector2 in PL_TABLES:
		tables.append(tb)
		for dx: float in [-30.0, 30.0]:
			chairs.append(tb + Vector2(dx, 0.0))
			chair_table.append(tb)
	return [tables, chairs, chair_table]


# --- build -------------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DEL SORTIDOR"
	m.gate_l = CX - 190.0
	m.gate_r = CX + 190.0
	m.blai_waiters = []
	for i in range(RUNS.size()):
		var w := TrayRun.new()
		w.door = RUNS[i][0]
		w.table = RUNS[i][1]
		w.pos = w.door
		w.key = 401 + i * 37
		w.auto_tip = i == 0
		w.t = 0.5 + float(i)
		m.blai_waiters.append(w)
	m.blai_pieces = []
	m.blai_leave = {}
	m.blai_leave_cool = 0.0
	m.blai_floor_seen = 0
	m.blai_leaves = 0
	m.blai_gobbled = 0
	m.blai_tray_catches = 0
	m.blai_trays_tipped = 0
	m.blai_begged = 0
	m.blai_beg_t = 0.0
	m.blai_spill_at = Vector2.INF
	m.blai_spill_wait = 0.0
	var hour: String = Game.hour
	var weather: String = Game.weather
	m.blai_open = []
	for i in range(BARS.size()):
		m.blai_open.append(bar_open(i, hour))

	# the lamps on their brackets by the walls, clear of the terraces and the
	# doors; the pilones closing the cross streets; the placeta's two trees
	var side := -1.0
	var y := 60.0
	while y > GATE + 220.0:
		var spot := Vector2(wall_x(y, side) - side * 24.0, y)
		if _clear_of_bars(spot, 120.0) and not in_xing(y, 60.0) and not in_placeta(spot):
			m.poles.append(spot)
		side = -side
		y -= 330.0
	for xi: float in XINGS:
		for s: float in [-1.0, 1.0]:
			for dy: float in [-XHALF + 14.0, 0.0, XHALF - 14.0]:
				m.poles.append(Vector2(wall_x(xi, s) - s * 14.0, xi + dy))
	for tp: Vector2 in PL_TREES:
		m.poles.append(tp)
	m.deco_pole_count = m.poles.size()

	var tc: Array = street_terraces()
	m.tables = Array(tc[0], TYPE_VECTOR2, &"", null)
	m.chairs = Array(tc[1], TYPE_VECTOR2, &"", null)
	# the diners: a share of the chairs taken, by the sky, the same chairs
	# every time; each faces the table
	m.blai_diners = []
	var share := Outdoors.terrace_diners(weather, hour)
	var chair_table: Array = tc[2]
	for i in range(m.chairs.size()):
		if _h(i * 13 + 5) < share:
			var c: Vector2 = m.chairs[i]
			var tb: Vector2 = chair_table[i]
			m.blai_diners.append({"pos": c, "face": (tb - c).normalized(), "key": 1100 + i * 7,
				"drink": int(_h(i * 3 + 1) * 3.0), "shared": false})
	# the standers: out in the street in the evening, in the doorways in the
	# rain; each is a performer (a person, solid, never a rope anchor)
	m.blai_standers = []
	var standers: Array[Vector2] = []
	if Outdoors.standers_out(weather, hour):
		if Outdoors.standers_in_doorways(weather, hour):
			# in the doorways of the bars with no terrace, and beside each
			# kitchen's door (always open), clear of the waiter's way out
			for i: int in DOORWAY_BARS:
				if not bool(m.blai_open[i]):
					continue
				var d := door_at(i)
				var s_in: float = -float(BARS[i][0])
				var dys: Array = [34.0, 58.0] if bool(BARS[i][3]) else [-14.0, 14.0]
				for dy: float in dys:
					var at := Vector2(d.x + s_in * 15.0, d.y + dy)
					standers.append(at)
					m.blai_standers.append({"face": Vector2(s_in, 0.0), "key": 2000 + standers.size() * 11,
						"drink": int(_h(standers.size() * 5) * 3.0), "shared": false, "c": at})
		else:
			for gi in range(STAND_GROUPS.size()):
				var c: Vector2 = STAND_GROUPS[gi]
				var n := 3 if _h(gi * 5 + 2) < 0.6 else 2
				for k in range(n):
					var a := float(k) * TAU / float(n) + _h(gi) * 2.0
					var at := c + Vector2.from_angle(a) * GROUP_R
					standers.append(at)
					m.blai_standers.append({"face": (c - at).normalized(), "key": 2000 + standers.size() * 11,
						"drink": int(_h(standers.size() * 5) * 3.0), "shared": false, "c": c})
	m.performers = Array(standers, TYPE_VECTOR2, &"", null)
	# the deliveries: a hand truck of kegs and crates at two doors by day
	m.blai_delivery = []
	if Outdoors.deliveries(weather, hour):
		for i: int in [3, 6]:
			var d := door_at(i)
			var s_in: float = -float(BARS[i][0])
			var at := Vector2(d.x + s_in * 26.0, d.y + 62.0)
			m.blai_delivery.append(Rect2(at - Vector2(17.0, 22.0), Vector2(34.0, 44.0)))
	# the chalkboards out by the doors (they topple)
	m.astands = Array([
		Vector2(WALL_L + 20.0, -470.0), Vector2(WALL_R - 20.0, -1900.0),
		Vector2(WALL_R - 20.0, -3290.0), Vector2(WALL_L + 20.0, -4260.0),
	], TYPE_VECTOR2, &"", null)
	m.benches = Array([Vector2(306.0, -2420.0)], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(WALL_R - 20.0, -150.0), Vector2(WALL_L + 20.0, -1340.0),
		Vector2(WALL_R - 20.0, -2310.0), Vector2(WALL_L + 20.0, -3100.0),
		Vector2(WALL_R - 20.0, -4560.0),
	], TYPE_VECTOR2, &"", null)
	if "fountains" in m:
		m.fountains = Array([Vector2(WALL_R - 22.0, -2880.0)], TYPE_VECTOR2, &"", null)
	m.islands = Array([{"rect": PL_TERRACE, "side": 1.0}], TYPE_DICTIONARY, &"", null)

	# the marking spots: pilones by the walls
	var hyd: Array[Vector2] = [
		Vector2(WALL_L + 18.0, -150.0), Vector2(WALL_R - 18.0, -1360.0),
		Vector2(WALL_L + 18.0, -2050.0), Vector2(WALL_R - 18.0, -3040.0),
		Vector2(WALL_L + 18.0, -3880.0), Vector2(WALL_R - 18.0, -4720.0),
	]
	# the floor: dropped pintxos, near the terraces where they fall
	var keb: Array[Vector2] = [
		Vector2(560.0, -700.0), Vector2(700.0, -1010.0), Vector2(590.0, -1560.0),
		Vector2(710.0, -2080.0), Vector2(600.0, -2560.0), Vector2(690.0, -3260.0),
		Vector2(580.0, -3500.0), Vector2(700.0, -4050.0), Vector2(600.0, -4480.0),
	]
	return [hyd, keb]


static func _clear_of_bars(p: Vector2, r: float) -> bool:
	for i in range(BARS.size()):
		var d := door_at(i)
		if absf(d.x - p.x) < 140.0 and absf(d.y - p.y) < (r if bool(BARS[i][4]) else 70.0):
			return false
	return true


static func solids(m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if m != null and "blai_delivery" in m:
		for r: Rect2 in m.blai_delivery:
			out.append(r)
	return out


static func wrap_rects(m: Node2D) -> Array[Rect2]:
	return solids(m)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		return -1
	return Surfaces.S.PAVEMENT


static func tree_kind(m: Node2D, p: Vector2) -> int:
	for tp: Vector2 in PL_TREES:
		if p.distance_to(tp) < 1.0:
			return m.TREE_STREET
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return not _is_pilona(p) and not (PL_TREES.has(p))


static func _is_pilona(p: Vector2) -> bool:
	return in_xing(p.y, 4.0)


# --- per frame -----------------------------------------------------------------------

class TrayRun:
	extends RefCounted
	enum St { IDLE, OUT, WOBBLE, SPILLED, SERVE, BACK }
	var door := Vector2.ZERO
	var table := Vector2.ZERO
	var pos := Vector2.ZERO
	var st: St = St.IDLE
	var t := 0.0
	var full := true
	var auto_tip := false
	var cause := ""
	var key := 0
	var face := Vector2.LEFT
	var yielded := false
	var tipped := false
	var stride := 0.0


static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	for w: TrayRun in m.blai_waiters:
		_tick_waiter(m, w, delta)
	_tick_pieces(m, delta)
	_tick_spill(m, delta)
	_tick_floor(m, delta)
	_tick_beg(m, delta)


static func _tick_waiter(m: Node2D, w: TrayRun, delta: float) -> void:
	var dog: Vector2 = m.dog.global_position
	match w.st:
		TrayRun.St.IDLE:
			w.t -= delta
			w.face = (w.table - w.door).normalized()
			if w.t <= 0.0 and absf(dog.y - w.door.y) < WAITER_NEAR:
				w.st = TrayRun.St.OUT
				w.full = true
				w.yielded = false
				w.cause = ""
		TrayRun.St.OUT:
			var to := w.table - w.pos
			w.face = to.normalized()
			var hum: Vector2 = m.human.global_position
			if hum.distance_to(w.pos + w.face * 24.0) < WAITER_YIELD:
				if not w.yielded:
					w.yielded = true
					m.float_text(w.pos + Vector2(0.0, -34.0), "After you!", Color(0.96, 0.94, 0.88), m.POP_SAY)
			else:
				var step := WAITER_SPEED * delta
				w.pos = w.table if to.length() <= step else w.pos + w.face * step
				w.stride += delta * 9.0
			if dog.distance_to(w.pos) < WAITER_BUMP and m.dog.tumble_t <= 0.0:
				_wobble(m, w, "bump")
			elif w.auto_tip and not w.tipped and m.phase == "out" \
					and w.pos.distance_to(w.table) < w.door.distance_to(w.table) * 0.5:
				_wobble(m, w, "chair")
			elif w.pos.distance_to(w.table) < 1.0:
				w.st = TrayRun.St.SERVE
				w.t = 1.2
				w.full = false
		TrayRun.St.WOBBLE:
			w.t -= delta
			if w.t <= 0.0:
				_tip(m, w)
		TrayRun.St.SPILLED, TrayRun.St.SERVE:
			w.t -= delta
			if w.t <= 0.0:
				w.st = TrayRun.St.BACK
		TrayRun.St.BACK:
			var back := w.door - w.pos
			w.face = back.normalized() if back.length() > 1.0 else w.face
			var step2 := WAITER_SPEED * delta
			w.pos = w.door if back.length() <= step2 else w.pos + w.face * step2
			w.stride += delta * 9.0
			if w.pos.distance_to(w.door) < 1.0:
				w.st = TrayRun.St.IDLE
				w.t = WAITER_REST + _h(w.key + int(m.elapsed)) * 3.0


# The tray rocks: telegraphed WOBBLE_T before it goes, as every event.
static func _wobble(m: Node2D, w: TrayRun, cause: String) -> void:
	w.st = TrayRun.St.WOBBLE
	w.t = WOBBLE_T
	w.cause = cause
	w.tipped = true
	m.float_text(w.pos + Vector2(0.0, -36.0), "Whoa, whoa!", Color(0.96, 0.94, 0.88), m.POP_SAY)
	m.feed.say("THE TRAY! GET UNDER IT", EventFeed.Tone.LOUD)
	Sfx.play("creak", 1.6, -6.0)


static func _tip(m: Node2D, w: TrayRun) -> void:
	w.st = TrayRun.St.SPILLED
	w.t = 1.6
	w.full = false
	m.blai_trays_tipped += 1
	var tray := w.pos + w.face * 12.0
	m.blai_spill_at = tray + w.face * 70.0
	m.blai_spill_wait = SPILL_WAIT
	for i in range(SPILL_N):
		var a := w.face.angle() + (float(i) - float(SPILL_N - 1) * 0.5) * 0.34
		var dist := 44.0 + 80.0 * _h(w.key + i * 17 + m.blai_trays_tipped)
		var to := tray + Vector2.from_angle(a) * dist
		var e: Vector2 = m.walk_edges(to.y)
		to.x = clampf(to.x, e.x + 18.0, e.y - 18.0)
		m.blai_pieces.append({"from": tray, "to": to, "t": 0.0, "T": 0.42 + 0.14 * _h(i * 5 + w.key),
			"kind": (i + w.key) % TOPPINGS.size()})
	Sfx.play("crack", 1.5, -4.0)
	Sfx.play("bell", 2.2, -10.0)
	m.float_text(tray + Vector2(0.0, -20.0), "CRASH", Color(1.0, 0.96, 0.86))
	m.float_text(w.pos + Vector2(0.0, -36.0), "Mare meva!", Color(0.96, 0.94, 0.88), m.POP_SAY)
	m.feed.say("TRAY DOWN! CATCH ONE", EventFeed.Tone.LOUD)
	# her doing, in front of a full terrace: your human is mortified (short:
	# the spill's leave-it follows as the pintxos land, _tick_spill)
	if w.cause == "bump" or w.cause == "bark":
		m.human.lose_patience(TIP_COST)
		if m.human.can_warn_external():
			m.human.notice("Sorry! Sorry!", 0.4)


static func _tick_pieces(m: Node2D, delta: float) -> void:
	if m.blai_pieces.is_empty():
		return
	var dog: Vector2 = m.dog.global_position
	var keep: Array = []
	for pc: Dictionary in m.blai_pieces:
		pc.t = float(pc.t) + delta
		var f: float = clampf(float(pc.t) / float(pc.T), 0.0, 1.0)
		var at: Vector2 = (pc.from as Vector2).lerp(pc.to as Vector2, f)
		if f > 0.4 and dog.distance_to(at) < CATCH_R:
			m.blai_tray_catches += 1
			m.kebabs_eaten += 1
			m.combo.add("CATCH", CATCH_PAY)
			m.award_points(CATCH_PAY, "caught it! +%d" % CATCH_PAY)
			continue
		if f >= 1.0:
			m.kebabs.append({"pos": pc.to, "eaten": false, "left": false})
			m.blai_floor_seen = _floor_eaten(m)
			continue
		keep.append(pc)
	m.blai_pieces = keep


# The last pintxo down: your human has seen the lot and says leave it, as
# soon as they are free to (the "Sorry!" may still be up), for SPILL_WAIT.
static func _tick_spill(m: Node2D, delta: float) -> void:
	if m.blai_spill_at.x == INF or not m.blai_pieces.is_empty():
		return
	var at: Vector2 = m.blai_spill_at
	if m.human.global_position.distance_to(at) >= LEAVE_HUMAN + 60.0:
		m.blai_spill_at = Vector2.INF
		return
	if m.human.can_warn_external():
		m.blai_spill_at = Vector2.INF
		_start_leave(m, at, LEAVE_SPILL_R, LEAVE_SPILL_T, LEAVE_SPILL_PAY, "Leave it! All of it!", -1)
		return
	m.blai_spill_wait = float(m.blai_spill_wait) - delta
	if m.blai_spill_wait <= 0.0:
		m.blai_spill_at = Vector2.INF


static func _scold(m: Node2D, gobbled: int) -> void:
	m.blai_gobbled += gobbled
	m.human.lose_patience(LEAVE_COST * float(gobbled))
	m.human.glance_t = maxf(float(m.human.glance_t), 2.2)
	m.float_text(m.human.global_position + Vector2(0.0, -34.0), "I said leave it!", Color(1.0, 0.86, 0.80), m.POP_SAY)
	m.feed.say("YOUR HUMAN SAW THAT", EventFeed.Tone.BAD)
	m.blai_leave = {}
	m.blai_leave_cool = LEAVE_COOL


static func _floor_eaten(m: Node2D) -> int:
	var n := 0
	for k: Dictionary in m.kebabs:
		if bool(k.eaten):
			n += 1
	return n


# r is how far off counts as out of reach when the telling stands down;
# told from further off than that, she must also turn away (LEAVE_BACKOFF)
static func _start_leave(m: Node2D, at: Vector2, r: float, t: float, pay: int, line: String, idx: int) -> void:
	var d: float = (m.dog.global_position as Vector2).distance_to(at)
	m.blai_leave = {"at": at, "r": r, "t": t, "pay": pay, "idx": idx, "near": d,
		"clear": maxf(r, d + LEAVE_BACKOFF)}
	m.human.notice(line, 1.3)
	m.human.glance_t = maxf(float(m.human.glance_t), 2.2)
	if m.has_method("owner_news"):
		m.owner_news(I18n.t("owner_leave_it"))


# Floor food and your human: "Leave it!" as she heads for a pintxo, and what
# eating it anyway costs.
static func _tick_floor(m: Node2D, delta: float) -> void:
	var dog: Vector2 = m.dog.global_position
	m.blai_leave_cool = maxf(0.0, float(m.blai_leave_cool) - delta)
	var eaten := _floor_eaten(m)
	var gobbled := eaten - int(m.blai_floor_seen)
	m.blai_floor_seen = eaten
	# eaten while told, or the moment after: a third of their patience
	if gobbled > 0 and (not m.blai_leave.is_empty() or float(m.blai_leave_cool) > 0.0):
		_scold(m, gobbled)
		return
	if not m.blai_leave.is_empty():
		var lv: Dictionary = m.blai_leave
		lv.t = float(lv.t) - delta
		var d: float = dog.distance_to(lv.at as Vector2)
		lv.near = minf(float(lv.near), d)
		# turned away from it: off her nearest approach, or further than she
		# was told from; or out of reach when the telling stands down
		var turned: bool = d >= float(lv.near) + LEAVE_BACKOFF or d >= float(lv.clear)
		if turned or float(lv.t) <= 0.0:
			m.blai_leave = {}
			m.blai_leave_cool = LEAVE_COOL
			# hovering within reach until it stands down is not leaving it
			if not turned and d < float(lv.r):
				return
			var idx: int = int(lv.idx)
			var fresh := idx < 0 or not bool(m.kebabs[idx].get("left", false))
			if idx >= 0:
				m.kebabs[idx]["left"] = true
			if fresh:
				m.blai_leaves += 1
				m.human.patience = minf(1.0, float(m.human.patience) + LEAVE_BACK)
				m.combo.add("LEAVE IT", int(lv.pay))
				m.award_points(int(lv.pay), "left it! +%d" % int(lv.pay))
				if m.human.can_warn_external():
					m.human.notice("Good dog.", 1.0)
		return
	if m.blai_leave_cool > 0.0 or m.blai_spill_at.x < INF or not m.human.can_warn_external():
		return
	if m.human.global_position.distance_to(dog) > LEAVE_HUMAN:
		return
	var vel: Vector2 = m.dog.velocity
	var best := -1
	var best_d := INF
	for i in range(m.kebabs.size()):
		var k: Dictionary = m.kebabs[i]
		if bool(k.eaten):
			continue
		var to: Vector2 = (k.pos as Vector2) - dog
		var d := to.length()
		if d >= best_d or d >= LEAVE_REACH_MAX:
			continue
		if d < LEAVE_CLOSE:
			best = i
			best_d = d
			continue
		# on course for it: closing on it, and it lies near her line of travel
		var closing := vel.dot(to / d)
		if closing <= LEAVE_HEAD:
			continue
		if absf(to.cross(vel.normalized())) > LEAVE_AIM:
			continue
		# told LEAVE_LEAD before she can bite at the speed she is closing
		if d <= leave_reach(closing):
			best = i
			best_d = d
	if best >= 0:
		_start_leave(m, m.kebabs[best].pos, LEAVE_PASS, LEAVE_T, LEAVE_PAY, "Leave it!", best)


# How far off a pintxo she is told, closing on it at this speed: early
# enough to obey (LEAVE_LEAD before the bite), never nearer than LEAVE_SEE.
static func leave_reach(closing: float) -> float:
	return clampf(LEAVE_LEAD * closing + EAT_R, LEAVE_SEE, LEAVE_REACH_MAX)


# Sitting pretty by someone with a plate: they share. Taken from a hand, not
# off the floor, so your human does not mind.
static func _tick_beg(m: Node2D, delta: float) -> void:
	var dog: Vector2 = m.dog.global_position
	if m.dog.velocity.length() > BEG_STILL or bool(m.dog.dragged):
		m.blai_beg_t = 0.0
		return
	var who: Dictionary = {}
	for d: Dictionary in m.blai_diners:
		if not bool(d.shared) and dog.distance_to(d.pos as Vector2) < BEG_R:
			who = d
			break
	if who.is_empty():
		for i in range(m.blai_standers.size()):
			var s: Dictionary = m.blai_standers[i]
			if not bool(s.shared) and i < m.performers.size() and dog.distance_to(m.performers[i]) < BEG_R:
				who = s
				who["pos"] = m.performers[i]
				break
	if who.is_empty():
		m.blai_beg_t = 0.0
		return
	m.blai_beg_t = float(m.blai_beg_t) + delta
	if m.blai_beg_t < BEG_T:
		return
	m.blai_beg_t = 0.0
	who["shared"] = true
	m.blai_begged += 1
	m.kebabs_eaten += 1
	m.combo.add("SHARED", BEG_PAY)
	m.award_points(BEG_PAY, "shared! +%d" % BEG_PAY)
	m.float_text((who.pos as Vector2) + Vector2(0.0, -30.0), BEG_LINES[int(who.key) % BEG_LINES.size()],
		Color(0.96, 0.94, 0.88), m.POP_SAY)


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = m.dog.global_position if pos == Vector2.ZERO else pos
	for w: TrayRun in m.blai_waiters:
		if w.st == TrayRun.St.OUT and w.full and w.pos.distance_to(p) < WAITER_BARK:
			_wobble(m, w, "bark")
			return true
	return false


static func idle_status(m: Node2D) -> String:
	for w: TrayRun in m.blai_waiters:
		if w.st == TrayRun.St.WOBBLE and m.dog.global_position.distance_to(w.pos) < 300.0:
			return I18n.t("walk_blai_tray")
	if not m.blai_leave.is_empty():
		return I18n.t("walk_blai_leave")
	return ""


# --- ground: the street itself (recorded once per stretch) ----------------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo: float = maxf(vt - 30.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_ground(m, wc, lo, hi)
	wc.lod = keep_lod


static func _street_poly(lo: float, hi: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := hi
	while true:
		var e := edges_at(y)
		left.append(Vector2(e.x, y))
		right.append(Vector2(e.y, y))
		if y <= lo:
			break
		y = maxf(lo, y - 30.0 if (y < PL_Y0 + PL_RAMP + 30.0 and y > PL_Y1 - PL_RAMP - 30.0) else y - 400.0)
	right.reverse()
	left.append_array(right)
	return left


static func _ground(m: Node2D, wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.polygon(_street_poly(lo, hi), PAVE)
	# panots de flor along both facades, and all over the placeta
	Panot.flor(wc, WALL_L, WALL_L + 120.0, lo, hi, PANOT_INK, PANOT_SHINE)
	Panot.flor(wc, WALL_R - 120.0, WALL_R, lo, hi, PANOT_INK, PANOT_SHINE)
	if lo < PL_Y0 + PL_RAMP and hi > PL_Y1 - PL_RAMP:
		Panot.flor(wc, PL_L, WALL_L, maxf(lo, PL_Y1 - PL_RAMP), minf(hi, PL_Y0 + PL_RAMP), PANOT_INK, PANOT_SHINE)
	# the granite slabs down the middle, where the road was, with the rigola
	# (the gutter of small setts) down its centre
	var gl := WALL_L + 120.0
	var gr := WALL_R - 120.0
	wc.rect(Rect2(gl, lo, gr - gl, hi - lo), SLAB)
	var row := int(floorf(lo / 90.0))
	var sy := float(row) * 90.0
	while sy < hi:
		wc.line(Vector2(gl, sy), Vector2(gr, sy), SLAB_JOINT, 1.2)
		var sx := gl + (0.0 if row % 2 == 0 else 45.0) + 90.0
		while sx < gr - 2.0:
			wc.line(Vector2(sx, sy), Vector2(sx, sy + 90.0), SLAB_JOINT, 1.0)
			sx += 90.0
		# worn slabs: one darkened by years of spilt drink, a crack across another
		var wx0 := gl + (0.0 if row % 2 == 0 else 45.0) - 90.0
		var col := 0
		while wx0 < gr:
			var key := row * 17 + col
			var a := maxf(wx0, gl)
			var z := minf(wx0 + 90.0, gr)
			if z - a > 20.0:
				if _h(key) < 0.16:
					wc.rect(Rect2(a + 1.0, sy + 1.0, z - a - 2.0, 88.0), Color(0.30, 0.26, 0.22, 0.07))
				elif _h(key) > 0.93:
					var c0 := Vector2(a + 8.0 + _h(key + 3) * 20.0, sy + 6.0)
					var c1 := c0 + Vector2(18.0 + _h(key + 4) * 30.0, 30.0 + _h(key + 5) * 40.0)
					wc.line(c0, c1, SLAB_JOINT, 1.0)
					wc.line(c1, c1 + Vector2(-10.0, 18.0), SLAB_JOINT, 0.8)
			wx0 += 90.0
			col += 1
		row += 1
		sy += 90.0
	wc.rect(Rect2(gl - 2.0, lo, 4.0, hi - lo), SLAB_JOINT)
	wc.rect(Rect2(gr - 2.0, lo, 4.0, hi - lo), SLAB_JOINT)
	wc.rect(Rect2(CX - 9.0, lo, 18.0, hi - lo), RIGOLA)
	var ry := floorf(lo / 12.0) * 12.0
	var ri := 0
	while ry < hi:
		wc.rect(Rect2(CX - 8.0 + (0.0 if ri % 2 == 0 else 4.5), ry + 1.0, 7.0, 10.0), RIGOLA_SETT)
		wc.rect(Rect2(CX + 1.0 + (0.0 if ri % 2 == 0 else -4.5), ry + 1.0, 7.0, 10.0), RIGOLA_SETT)
		ry += 12.0
		ri += 1
	# the cross streets' mouths: the side street's pavement runs in to the
	# line of pilones that closes it
	for xi: float in XINGS:
		if xi + XHALF < lo or xi - XHALF > hi:
			continue
		for s: float in [-1.0, 1.0]:
			var wx := wall_x(xi, s)
			wc.rect(Rect2(minf(wx, wx - s * 26.0), xi - XHALF, 26.0, XHALF * 2.0), Color(0.58, 0.56, 0.53))
	# the facades' shade on the paving at their feet, and the cellar grates
	# along them, damp round the edges
	var cy := floorf(lo / 60.0) * 60.0
	while cy < hi:
		var mid := cy + 30.0
		for s: float in [-1.0, 1.0]:
			if in_xing(mid, 4.0) or (s < 0.0 and mid < PL_Y0 + PL_RAMP + 30.0 and mid > PL_Y1 - PL_RAMP - 30.0):
				continue
			var wx := WALL_L if s < 0.0 else WALL_R
			_wall_shade(wc, wx, -s * 34.0, cy, cy + 60.0, 0.22)
		cy += 60.0
	var gy := floorf(lo / 230.0) * 230.0
	while gy < hi + 230.0:
		for s: float in [-1.0, 1.0]:
			var y := gy + (40.0 if s < 0.0 else 150.0)
			if y < lo - 40.0 or y > hi + 40.0 or in_xing(y, 40.0) or not _clear_of_doors(s, y):
				continue
			if s < 0.0 and y < PL_Y0 + PL_RAMP + 40.0 and y > PL_Y1 - PL_RAMP - 40.0:
				continue
			var wx := WALL_L if s < 0.0 else WALL_R
			var r := Rect2(minf(wx - s * 4.0, wx - s * 16.0), y - 17.0, 12.0, 34.0)
			wc.glow(r.get_center(), 30.0, Color(0.10, 0.10, 0.12, 0.16), 0.3)
			wc.rect(r.grow(1.5), Color(0.40, 0.38, 0.36))
			wc.rect(r, Color(0.12, 0.12, 0.13))
			var gq := r.position.y + 3.0
			while gq < r.end.y - 2.0:
				wc.rect(Rect2(r.position.x + 1.5, gq, r.size.x - 3.0, 1.6), IRON.lightened(0.15))
				gq += 4.5
		gy += 230.0
	# each bar's threshold and its window counter, or its shutter down
	var hour: String = Game.hour
	for i in range(BARS.size()):
		var side: float = BARS[i][0]
		var y: float = BARS[i][1]
		var half: float = BARS[i][2]
		if y + half < lo - 20.0 or y - half > hi + 20.0:
			continue
		_bar_front(wc, i, side, y, half, bar_open(i, hour))
	_litter(m, wc, lo, hi)


static func _clear_of_doors(side: float, y: float) -> bool:
	for i in range(BARS.size()):
		if float(BARS[i][0]) == side and absf(float(BARS[i][1]) - y) < float(BARS[i][2]) + 24.0:
			return false
	return true


# a soft shade along a facade's foot: `a` at the wall, nothing `reach` px out
static var _sp := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
static var _ones2 := PackedFloat32Array([1.0, 1.0])
static var _fade2 := PackedFloat32Array([1.0, 0.0])


static func _wall_shade(wc: ShapeBatch, x: float, reach: float, y0: float, y1: float, a: float) -> void:
	_sp[0] = Vector2(x, y0)
	_sp[1] = Vector2(x + reach, y0)
	_sp[2] = Vector2(x, y1)
	_sp[3] = Vector2(x + reach, y1)
	wc.band(_sp, 2, Color(SHADOW.r, SHADOW.g, SHADOW.b, a), _ones2, _fade2)


# A bar at street level, seen from above: a stone step at the door, and the
# window counter (a wooden ledge with plates of pintxos and a glass or two)
# along the rest of the front; or by day, maybe, the shutter down, its ribs
# and a tag sprayed across it.
static func _bar_front(wc: ShapeBatch, i: int, side: float, y: float, half: float, open: bool) -> void:
	var wx := wall_x(y, side)
	var s_in := -side
	if not open:
		var r := Rect2(minf(wx, wx + s_in * 10.0), y - half, 10.0, half * 2.0)
		wc.rect(Rect2(r.position + Vector2(s_in * 3.0, 3.0), r.size), SHADOW)
		wc.rect(r, SHUTTER)
		var ry := y - half + 4.0
		while ry < y + half - 2.0:
			wc.rect(Rect2(r.position.x, ry, r.size.x, 1.6), SHUTTER_RIB)
			ry += 5.0
		# the tags sprayed over it: a fat letter or two and a scrawl
		for k in range(3):
			var ty := y - half + 10.0 + _h(i * 9 + k) * (half * 2.0 - 20.0)
			var tc := Color(TAG_COLS[(i + k) % TAG_COLS.size()], 0.75)
			wc.rect(Rect2(r.position.x + 1.0, ty, r.size.x - 2.0, 6.0 + _h(i + k) * 10.0), tc)
			var zy := ty + 4.0
			var zx := r.position.x + 2.0
			for q in range(4):
				var nzx := r.end.x - 2.0 if q % 2 == 0 else r.position.x + 2.0
				wc.line(Vector2(zx, zy), Vector2(nzx, zy + 5.0), tc.darkened(0.3), 1.2)
				zx = nzx
				zy += 5.0
		# the bottom rail along the street side, and its two padlocks
		var rail_x := r.position.x + (r.size.x - 3.0 if s_in > 0.0 else 0.0)
		wc.rect(Rect2(rail_x, r.position.y, 3.0, r.size.y), SHUTTER_RIB.darkened(0.3))
		for ly: float in [y - half + 8.0, y + half - 8.0]:
			wc.circle(Vector2(rail_x + 1.5 + s_in * 3.0, ly), 2.4, Color(0.70, 0.58, 0.24))
		return
	# the step at the door
	wc.rect(Rect2(minf(wx, wx + s_in * 12.0), y - 16.0, 12.0, 32.0), Color(0.78, 0.76, 0.72))
	wc.rect(Rect2(minf(wx, wx + s_in * 3.0), y - 14.0, 3.0, 28.0), Color(0.30, 0.24, 0.20))
	# the window counters either side of it
	for s: float in [-1.0, 1.0]:
		var c0 := y + s * 22.0
		var c1 := y + s * (half - 6.0)
		var ledge := Rect2(minf(wx, wx + s_in * 11.0), minf(c0, c1), 11.0, absf(c1 - c0))
		if ledge.size.y < 16.0:
			continue
		wc.rect(Rect2(ledge.position + Vector2(s_in * 3.0, 3.0), ledge.size), SHADOW)
		wc.rect(ledge, SILL)
		wc.rect(Rect2(ledge.position.x + (1.0 if s_in > 0.0 else 7.0), ledge.position.y, 3.0, ledge.size.y), SILL_LIT)
		var py := ledge.position.y + 9.0
		var k := 0
		while py < ledge.end.y - 6.0:
			var pp := Vector2(wx + s_in * 6.0, py)
			if (k + i) % 3 == 2:
				_glass(wc, pp, (k + i) % 2 == 0)
			else:
				wc.circle(pp, 5.0, PLATE)
				_pintxo_top(wc, pp, (i * 3 + k) % TOPPINGS.size(), 0.6)
			py += 14.0
			k += 1


static func _glass(wc: ShapeBatch, p: Vector2, beer: bool) -> void:
	wc.circle(p, 3.6, Color(0.82, 0.88, 0.90, 0.8))
	wc.circle(p, 2.6, BEER if beer else VERMUT)
	if beer:
		wc.circle(p - Vector2(0.6, 0.6), 1.4, FOAM)


# what lies on the floor and is not food: napkins balled up, toothpicks,
# a wine stain, olive stones, round the terraces and doors most of all
static func _litter(_m: Node2D, wc: ShapeBatch, lo: float, hi: float) -> void:
	var y := floorf(lo / 34.0) * 34.0
	while y < hi:
		var k := int(absf(y) / 34.0)
		var e := edges_at(y)
		var near_bar := false
		for i in range(BARS.size()):
			if absf(float(BARS[i][1]) - y) < float(BARS[i][2]) + 40.0:
				near_bar = true
				break
		var n := 2 if near_bar else 1
		for j in range(n):
			var hx := _h(k * 31 + j * 7)
			var x := e.x + 14.0 + hx * (e.y - e.x - 28.0)
			var p := Vector2(x, y + _h(k * 5 + j) * 34.0)
			var kind := int(_h(k * 11 + j * 3) * 6.0)
			match kind:
				0, 1:
					# a paper napkin, crumpled
					var a := _h(k + j) * TAU
					var pts := PackedVector2Array()
					for q in range(6):
						var rr := 4.0 + _h(k * 7 + q + j) * 3.0
						pts.append(p + Vector2.from_angle(a + float(q) * TAU / 6.0) * rr)
					wc.polygon(pts, NAPKIN_SHADE)
					wc.circle(p - Vector2(1.0, 1.0), 3.0, NAPKIN)
				2, 3:
					var d := Vector2.from_angle(_h(k * 3 + j) * TAU) * 6.0
					wc.line(p - d, p + d, TOOTHPICK, 1.2)
				4:
					if near_bar:
						wc.circle(p, 9.0 + _h(k) * 8.0, STAIN)
				_:
					wc.circle(p, 1.8, Color(0.42, 0.36, 0.20))
		y += 34.0


# --- beyond the facades: the roofs of Poble-sec --------------------------------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 300.0, float(m.GATE_Y) - 40.0)
	var hi := minf(vb + 300.0, float(m.START_Y) + 600.0)
	if hi > lo:
		_roofs(m, b, lo, hi)
	b.lod = keep_lod


static func _roofs(m: Node2D, b: ShapeBatch, lo: float, hi: float) -> void:
	b.rect(Rect2(-440.0, lo, 2160.0, hi - lo), BACK_TONES[0])
	for side: float in [-1.0, 1.0]:
		# the plots lie on fixed marks from the start, so they hold still
		var plots: Array = _plot_marks(side, lo - 200.0, hi + 200.0)
		for pi in range(plots.size() - 1):
			var y0: float = plots[pi]
			var y1: float = plots[pi + 1]
			if y1 > hi + 10.0 or y0 < lo - 10.0:
				continue
			_plot(m, b, side, y0, y1, int(absf(y0)) + (0 if side < 0.0 else 9000))
	for xi: float in XINGS:
		if xi + XHALF < lo or xi - XHALF > hi:
			continue
		_side_street(b, xi)


# where one plot ends and the next begins along a side, from START down:
# 90 to 160 px each, broken at the cross streets
static func _plot_marks(side: float, lo: float, hi: float) -> Array:
	var out: Array = []
	var y := START + 600.0
	var k := 0 if side < 0.0 else 1
	while y > GATE - 300.0:
		if y <= hi and y >= lo:
			out.append(y)
		var w := 90.0 + _h(k * 13 + 7) * 70.0
		var ny := y - w
		for xi: float in XINGS:
			if ny < xi + XHALF and y > xi + XHALF:
				ny = xi + XHALF
			elif y <= xi + XHALF and y > xi - XHALF:
				ny = xi - XHALF
		for pb: float in [PL_Y0 + PL_RAMP, PL_Y0, PL_Y1, PL_Y1 - PL_RAMP]:
			if side < 0.0 and ny < pb and y > pb + 30.0:
				ny = pb
		y = ny
		k += 2
	return out


static func _plot(m: Node2D, b: ShapeBatch, side: float, y0: float, y1: float, salt: int) -> void:
	if in_xing((y0 + y1) * 0.5):
		return
	var far := -440.0 if side < 0.0 else 1720.0
	var depth := 200.0 + _h(salt) * 60.0
	var f0 := wall_x(y0, side)
	var f1 := wall_x(y1, side)
	var back0 := f0 + side * depth
	var back1 := f1 + side * depth
	var tone: Color = ROOF_TONES[absi(salt / 7) % ROOF_TONES.size()]
	# the front follows the facade (it curves round the placeta's corners)
	var pts := PackedVector2Array()
	var steps := maxi(1, int(ceilf(absf(y0 - y1) / 20.0)))
	for q in range(steps + 1):
		var yy := lerpf(y0, y1, float(q) / float(steps))
		pts.append(Vector2(wall_x(yy, side), yy))
	pts.append(Vector2(back1, y1))
	pts.append(Vector2(back0, y0))
	b.polygon(pts, tone)
	var straight := absf(f0 - f1) < 0.5
	var ylo := minf(y0, y1)
	var yhi := maxf(y0, y1)
	if straight:
		# the terrat's fired tiles, laid in a grid from the parapet back
		var joint := tone.darkened(0.10)
		var tx := f0 + side * 16.0
		while (tx - back0) * side < 0.0:
			b.rect(Rect2(tx - 0.5, ylo, 1.0, yhi - ylo), joint)
			tx += side * 16.0
		var ty := ceilf(ylo / 16.0) * 16.0
		while ty < yhi:
			b.rect(Rect2(minf(f0, back0), ty - 0.5, depth, 1.0), joint)
			ty += 16.0
		# the parapet's shade on the tiles inside it, and the dividing wall's
		b.rect(Rect2(minf(f0 + side * 2.5, f0 + side * 11.0), ylo, 8.5, yhi - ylo), SHADOW)
		b.rect(Rect2(minf(f0, back0), y1 + 1.5, depth, 6.0), SHADOW)
		# a house taller than the one south of it throws its shade on that roof
		if _h(salt * 7) < 0.3 and not in_xing(y0 + 8.0):
			b.rect(Rect2(minf(f0, back0), y0, depth, 16.0), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.30))
	# the dividing wall to the next plot
	b.line(Vector2(f1, y1), Vector2(back1, y1), PARAPET.darkened(0.15), 3.0)
	# beyond it, the back of the block: lower roofs and an interior patio
	var bt: Color = BACK_TONES[absi(salt / 3) % BACK_TONES.size()]
	b.polygon(PackedVector2Array([Vector2(back0, y0), Vector2(back1, y1), Vector2(far, y1), Vector2(far, y0)]), bt)
	if straight and yhi - ylo > 40.0:
		# the lower roofs behind: pantiles, a terrat or a light well each
		# (world/gotic.gd), laid at a fixed depth so a redraw lays the same ones
		var Gotic: GDScript = load("res://world/gotic.gd")
		var bw := absf(far - back0) - 6.0
		var cut := 150.0 + _h(salt + 31) * 90.0
		var near := Rect2(minf(back0 + side * 3.0, back0 + side * (3.0 + cut)), ylo + 3.0, cut, yhi - ylo - 6.0)
		var rest := Rect2(minf(back0 + side * (cut + 7.0), far), ylo + 3.0, bw - cut - 4.0, yhi - ylo - 6.0)
		Gotic.draw_block(m, b, near, Gotic.roof_hash(salt, 41))
		if rest.size.x > 30.0:
			Gotic.draw_block(m, b, rest, Gotic.roof_hash(salt, 43))
	if _h(salt * 3) < 0.4:
		var pw := 70.0 + _h(salt + 1) * 60.0
		var px := back0 + side * (30.0 + _h(salt + 2) * 60.0)
		var patio := Rect2(minf(px, px + side * pw), minf(y0, y1) + 12.0, pw, absf(y0 - y1) - 24.0)
		if patio.size.y > 20.0:
			b.rect(patio, PATIO)
			b.circle(patio.get_center(), minf(patio.size.x, patio.size.y) * 0.3, PLANT)
	var mid_y := (y0 + y1) * 0.5
	var fm := wall_x(mid_y, side)
	# the stair house and its door, a water tank or two, a skylight
	var sh := Vector2(fm + side * (60.0 + _h(salt + 5) * 70.0), mid_y + (_h(salt + 6) - 0.5) * 30.0)
	b.rect(Rect2(sh + Vector2(4.0, 5.0) - Vector2(16.0, 13.0), Vector2(32.0, 26.0)), SHADOW)
	b.rect(Rect2(sh - Vector2(16.0, 13.0), Vector2(32.0, 26.0)), STAIR_HOUSE)
	b.rect(Rect2(sh - Vector2(16.0, 13.0), Vector2(32.0, 4.0)), STAIR_HOUSE.lightened(0.15))
	# its door onto the terrat, on the street side, and the step outside it
	var dx := sh.x - side * 16.0
	b.rect(Rect2(minf(dx, dx - side * 3.0), sh.y - 6.0, 3.0, 12.0), Color(0.36, 0.26, 0.20))
	b.rect(Rect2(minf(dx - side * 3.0, dx - side * 8.0), sh.y - 7.0, 5.0, 14.0), STAIR_HOUSE.darkened(0.12))
	# an air-conditioning unit by the parapet, or a satellite dish
	var kit := Vector2(fm + side * (26.0 + _h(salt + 21) * 20.0), lerpf(y0, y1, 0.2 + _h(salt + 22) * 0.2))
	if _h(salt + 23) < 0.5:
		b.rect(Rect2(kit + Vector2(2.0, 3.0) - Vector2(9.0, 7.0), Vector2(18.0, 14.0)), SHADOW)
		b.rect(Rect2(kit - Vector2(9.0, 7.0), Vector2(18.0, 14.0)), Color(0.86, 0.86, 0.84))
		b.circle(kit + Vector2(2.0, 0.0), 5.0, Color(0.30, 0.30, 0.32))
		b.circle(kit + Vector2(2.0, 0.0), 1.6, Color(0.70, 0.70, 0.72))
	elif _h(salt + 24) < 0.6:
		b.circle(kit + Vector2(2.0, 3.0), 7.0, SHADOW)
		b.circle(kit, 7.0, Color(0.92, 0.92, 0.90))
		b.circle(kit - Vector2(1.5, 1.5), 4.0, Color(0.98, 0.98, 0.97))
		b.line(kit, kit + Vector2(side * -8.0, -4.0), Color(0.30, 0.30, 0.32), 1.4)
	if _h(salt + 8) < 0.7:
		var tk := sh + Vector2(side * 34.0, (_h(salt + 9) - 0.5) * 20.0)
		b.circle(tk + Vector2(3.0, 4.0), 8.0, SHADOW)
		b.circle(tk, 8.0, TANK)
		b.circle(tk - Vector2(2.0, 2.0), 4.0, TANK.lightened(0.2))
	# washing on a line across the terrat, or a terrat's pots of geraniums
	var span := absf(y0 - y1)
	if _h(salt + 11) < 0.45 and span > 70.0:
		var lx := fm + side * (30.0 + _h(salt + 12) * 30.0)
		var a := Vector2(lx, y0 - 12.0)
		var c := Vector2(lx + side * 50.0, y1 + 12.0)
		b.line(a, c, Color(0.20, 0.20, 0.20, 0.7), 1.0)
		for q in range(4):
			var pq := a.lerp(c, 0.18 + 0.2 * float(q))
			b.rect(Rect2(pq - Vector2(4.0, 3.0), Vector2(8.0, 6.0)), LAUNDRY[(salt + q) % LAUNDRY.size()])
	elif _h(salt + 13) < 0.5:
		for q in range(3):
			var pp := Vector2(fm + side * 16.0, lerpf(y0, y1, 0.25 + 0.25 * float(q)))
			b.circle(pp, 6.0, Color(0.62, 0.34, 0.24))
			b.circle(pp, 4.6, PLANT)
			b.circle(pp - Vector2(1.0, 1.0), 2.2, Color(0.88, 0.24, 0.30))
	# an aerial
	var ae := sh + Vector2(-side * 6.0, -18.0)
	b.line(ae, ae + Vector2(side * 18.0, -10.0), Color(0.24, 0.24, 0.26), 1.4)
	# the parapet along the street, and the balconies under it
	for q in range(steps):
		b.line(pts[q], pts[q + 1], PARAPET, 5.0)
	var dir := (Vector2(f1, y1) - Vector2(f0, y0))
	var len := dir.length()
	if len > 1.0:
		dir /= len
		var t := 14.0
		while t < len - 20.0:
			var p := Vector2(f0, y0) + dir * t + Vector2(side * 6.0, 0.0)
			b.line(p, p + dir * 18.0, BALCONY, 3.0)
			t += 34.0


# a cross street beyond the facades: its pavements, the road, a zebra by
# the mouth and the motorbikes parked along it
static func _side_street(b: ShapeBatch, yi: float) -> void:
	for side: float in [-1.0, 1.0]:
		var wx := wall_x(yi, side)
		var far := -440.0 if side < 0.0 else 1720.0
		var r := Rect2(minf(wx, far), yi - XHALF, absf(far - wx), XHALF * 2.0)
		b.rect(r, SIDE_PAVE)
		var road := Rect2(r.position.x, yi - XHALF + 22.0, r.size.x, XHALF * 2.0 - 44.0)
		b.rect(road, ASPHALT)
		b.rect(Rect2(road.position.x, road.position.y - 2.0, road.size.x, 2.0), KERB)
		b.rect(Rect2(road.position.x, road.end.y, road.size.x, 2.0), KERB)
		var zx := wx + side * 30.0
		var zi := 0
		while zi < 6:
			b.rect(Rect2(minf(zx, zx + side * 26.0), road.position.y + 4.0 + float(zi) * 13.0, 26.0, 7.0), ZEBRA)
			zi += 1
		var mx := wx + side * 110.0
		for q in range(5):
			var mp := Vector2(mx + side * float(q) * 30.0, road.position.y + 9.0)
			b.capsule(mp + Vector2(0.0, -2.0), mp + Vector2(0.0, 12.0), 4.0, TAG_COLS[(q + int(absf(yi))) % TAG_COLS.size()].darkened(0.2))
			b.circle(mp + Vector2(0.0, 1.0), 2.4, Color(0.12, 0.12, 0.14))


# --- standing things, drawn every frame -----------------------------------------------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	_draw_live(m, b, vt, vb)
	b.lod = keep_lod


# the diners at the terraces, over the chairs they sit on (the furniture
# pass draws after draw_live)
static func draw_top(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	for d: Dictionary in m.blai_diners:
		var p: Vector2 = d.pos
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var f: Vector2 = d.face
		NpcFigure.person(b, p, f, int(d.key), -1.0, {"arms": NpcFigure.Arms.READY})
		var hand: Vector2 = p + f * 6.5 + f.orthogonal() * 4.0
		_glass(b, hand, int(d.drink) != 1)
	b.lod = keep_lod


static func _draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# the deliveries: a hand truck, the kegs and crates stacked on it
	for r: Rect2 in m.blai_delivery:
		if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
			continue
		b.rect(Rect2(r.position + Shade.light * 6.0, r.size), SHADOW)
		b.rect(Rect2(r.position.x + 2.0, r.end.y - 6.0, r.size.x - 4.0, 4.0), IRON)
		b.circle(r.position + Vector2(9.0, r.size.y - 6.0), 9.0, KEG.darkened(0.25))
		b.circle(r.position + Vector2(9.0, r.size.y - 6.0), 7.0, KEG)
		b.circle(r.position + Vector2(9.0, r.size.y - 6.0), 2.4, Color(0.34, 0.34, 0.36))
		var cr := Rect2(r.position + Vector2(r.size.x - 18.0, 2.0), Vector2(16.0, 20.0))
		b.rect(cr, CRATE)
		for q in range(3):
			for s in range(2):
				b.circle(cr.position + Vector2(4.0 + float(s) * 8.0, 4.0 + float(q) * 6.0), 2.2, Color(0.40, 0.28, 0.14))
		b.rect(Rect2(r.position + Vector2(2.0, 2.0), Vector2(14.0, 16.0)), CRATE.lightened(0.1))
	# the prize: a wedge of tortilla on its plate on the bar's window counter
	if not bool(m.prize_taken) and PRIZE.y + 40.0 >= vt and PRIZE.y - 40.0 <= vb:
		b.glow(PRIZE, 22.0, Color(1.0, 0.88, 0.50, 0.26))
		b.circle(PRIZE + Vector2(1.5, 2.0), 8.0, SHADOW)
		b.circle(PRIZE, 8.0, PLATE)
		b.polygon(PackedVector2Array([PRIZE + Vector2(-5.0, 4.0), PRIZE + Vector2(5.0, 4.0), PRIZE + Vector2(0.0, -6.0)]), TOPPINGS[0])
		b.line(PRIZE + Vector2(-5.0, 4.0), PRIZE + Vector2(5.0, 4.0), Color(0.80, 0.58, 0.20), 1.6)
		b.line(PRIZE + Vector2(0.0, -1.0), PRIZE + Vector2(3.0, -9.0), TOOTHPICK, 1.2)
	# the waiters and their trays
	for w: TrayRun in m.blai_waiters:
		if w.pos.y < vt - 60.0 or w.pos.y > vb + 60.0:
			continue
		_waiter(b, w, w.st == TrayRun.St.IDLE)
	# the pintxos in the air off a tipped tray, and their shadows on the floor
	for pc: Dictionary in m.blai_pieces:
		var f: float = clampf(float(pc.t) / float(pc.T), 0.0, 1.0)
		var at: Vector2 = (pc.from as Vector2).lerp(pc.to as Vector2, f)
		var hgt := sin(f * PI) * SPILL_ARC
		b.circle(at + Vector2(1.0, 2.0), 5.0 - hgt * 0.06, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.30))
		_pintxo(b, at + Vector2(0.0, -hgt), int(pc.kind), 1.0 + hgt * 0.01, f * 9.0)


static func _waiter(b: ShapeBatch, w: TrayRun, idle: bool) -> void:
	var walking := w.st == TrayRun.St.OUT or w.st == TrayRun.St.BACK
	var pos := w.pos
	NpcFigure.person(b, pos, w.face, w.key, w.stride if walking else -1.0, {
		"top": WAITER_SHIRT, "legs": APRON, "hair_style": "short", "arms": NpcFigure.Arms.UP if w.full else NpcFigure.Arms.SIDE})
	# the long black apron, a band across the front
	b.line(pos + w.face * 4.0 + w.face.orthogonal() * 5.0, pos + w.face * 4.0 - w.face.orthogonal() * 5.0, APRON, 3.0)
	if not w.full or idle:
		return
	# the tray, held up on one hand off the shoulder; rocking while it goes
	var rock := 0.0
	if w.st == TrayRun.St.WOBBLE:
		rock = sin(AnimClock.msec() / 45.0) * 6.0 * (1.0 - w.t / WOBBLE_T * 0.5)
	var side := w.face.orthogonal()
	var tray := pos + w.face * 8.0 + side * 10.0 + side * rock
	b.circle(tray + Shade.light * 6.0, 14.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.18))
	b.circle(tray, 14.0, TRAY.darkened(0.2))
	b.circle(tray, 12.5, TRAY)
	b.circle(tray - Vector2(3.0, 3.0), 5.0, TRAY_LIT)
	for q in range(4):
		var pp := tray + Vector2.from_angle(float(q) * TAU / 4.0 + rock * 0.08) * 6.5
		if q == 3:
			_glass(b, pp, true)
		else:
			_pintxo(b, pp, (w.key + q) % TOPPINGS.size(), 0.75, 0.0)


# a pintxo: a slice of bread, what is on it, and the toothpick through it
static func _pintxo(b: ShapeBatch, p: Vector2, kind: int, s: float, spin: float) -> void:
	var ax := Vector2.from_angle(0.4 + spin)
	var ay := ax.orthogonal()
	var w := 6.0 * s
	var h := 4.2 * s
	b.quad(p - ax * w - ay * h, p + ax * w - ay * h, p + ax * w + ay * h, p - ax * w + ay * h, BREAD_DARK)
	b.quad(p - ax * (w - 1.2) - ay * (h - 1.2), p + ax * (w - 1.2) - ay * (h - 1.2), p + ax * (w - 1.2) + ay * (h - 1.6), p - ax * (w - 1.2) + ay * (h - 1.6), BREAD)
	_pintxo_top(b, p, kind, s)
	b.line(p - ax * 2.0 + ay * 3.0, p + ax * 3.0 - ay * 7.0 * s, TOOTHPICK, 1.1)


static func _pintxo_top(b: ShapeBatch, p: Vector2, kind: int, s: float) -> void:
	var c: Color = TOPPINGS[kind % TOPPINGS.size()]
	match kind % TOPPINGS.size():
		0:
			b.circle(p, 3.6 * s, c)
			b.circle(p - Vector2(1.0, 1.0) * s, 1.6 * s, c.lightened(0.3))
		1:
			b.capsule(p - Vector2(2.6, 0.6) * s, p + Vector2(2.6, -0.6) * s, 2.2 * s, c)
		2:
			b.circle(p - Vector2(1.6, 0.0) * s, 2.2 * s, c)
			b.circle(p + Vector2(1.8, 0.4) * s, 2.2 * s, c.darkened(0.1))
			b.circle(p - Vector2(1.6, 0.0) * s, 0.8 * s, Color(0.96, 0.84, 0.76))
		3:
			b.capsule(p - Vector2(2.4, 0.0) * s, p + Vector2(2.4, 0.0) * s, 2.6 * s, c)
			b.circle(p - Vector2(1.0, 1.0) * s, 1.0 * s, c.lightened(0.25))
		_:
			b.capsule(p - Vector2(3.4, 0.8) * s, p + Vector2(3.4, -0.8) * s, 1.2 * s, Color(0.62, 0.64, 0.66))
			b.circle(p + Vector2(0.0, 1.6) * s, 1.8 * s, c)


# a dropped pintxo on its napkin, on the floor (main's kebabs)
# the napkin and its shadow, reused for every dropped pintxo (the batch
# copies what it is given)
static var _napkin := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
static var _napkin_shadow := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


static func draw_snack(_m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	var k := int(absf(kp.x * 0.37 + kp.y * 0.11))
	var a := _h(k) * TAU
	for q in range(4):
		_napkin[q] = kp + Vector2.from_angle(a + float(q) * TAU / 4.0 + 0.785) * 10.0
		_napkin_shadow[q] = _napkin[q] + Vector2(1.5, 2.0)
	wc.polygon(_napkin_shadow, SHADOW)
	wc.polygon(_napkin, NAPKIN)
	wc.line(_napkin[0].lerp(_napkin[1], 0.5), _napkin[2].lerp(_napkin[3], 0.5), NAPKIN_SHADE, 1.0)
	_pintxo(wc, kp, k % TOPPINGS.size(), 1.15, a)


# A terrace table at Blai: a marble top in its iron rim and, where someone
# is sitting, the round: a plate of pintxos, a caña or a vermut, the
# napkin holder and the pile of used toothpicks (what the bill is counted from).
static func draw_table(m: Node2D, wc: ShapeBatch, tb: Vector2) -> void:
	m.contact_shadow(wc, tb, 14.0, 9.0, 0.20)
	wc.circle(tb + Vector2(0.6, 0.8), 14.0, IRON)
	wc.circle(tb + Vector2(-0.3, -0.3), 12.4, MARBLE)
	var k := int(absf(tb.x * 0.13 + tb.y * 0.07))
	var share := Outdoors.terrace_diners(Game.weather, Game.hour)
	if _h(k) >= share + 0.15:
		if Game.weather == "rain":
			wc.circle(tb + Vector2(-3.0, -2.0), 4.0, Color(0.76, 0.84, 0.90, 0.35))
		return
	wc.circle(tb + Vector2(-2.0, -1.0), 6.6, PLATE)
	for q in range(3):
		_pintxo(wc, tb + Vector2(-2.0, -1.0) + Vector2.from_angle(float(q) * TAU / 3.0 + _h(k + 1)) * 3.2, (k + q) % TOPPINGS.size(), 0.55, float(q))
	_glass(wc, tb + Vector2(6.0, -5.0), k % 2 == 0)
	_glass(wc, tb + Vector2(6.5, 4.5), k % 3 != 0)
	wc.rect(Rect2(tb + Vector2(-8.0, 5.0), Vector2(5.0, 4.0)), Color(0.86, 0.86, 0.88))
	for q in range(3):
		var d := Vector2.from_angle(0.3 + float(q) * 0.25) * 3.5
		var c := tb + Vector2(1.0, 7.0)
		wc.line(c - d, c + d, TOOTHPICK, 0.9)


static func draw_performer(m: Node2D, wc: ShapeBatch, pf: Vector2, idx: int) -> void:
	if idx >= m.blai_standers.size():
		return
	if pf.y < m.view_lo(60.0) or pf.y > m.view_hi(60.0):
		return
	var s: Dictionary = m.blai_standers[idx]
	var f: Vector2 = s.face
	NpcFigure.person(wc, pf, f, int(s.key), -1.0, {"arms": NpcFigure.Arms.READY if idx % 2 == 0 else NpcFigure.Arms.SIDE})
	_glass(wc, pf + f * 6.0 + f.orthogonal() * 4.0, int(s.drink) != 1)


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_pilona(p):
		m._draw_pilona(wc, p, false)
	else:
		m._draw_lamppost(p)


# --- overhead: the strings of bulbs, the awnings and the bar signs ---------------------

static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	var lit: float = Game.lamp_glow()
	var tint: Color = m.night_cm.color if m.get("night_cm") != null else Color.WHITE
	var hour: String = Game.hour
	# the awnings over the bars that are open, and each bar's sign sticking
	# out from the wall (lit after dark)
	for i in range(BARS.size()):
		var side: float = BARS[i][0]
		var y: float = BARS[i][1]
		var half: float = BARS[i][2]
		var wx := wall_x(y, side)
		var s_in := -side
		var col: Color = BAR_COLS[i % BAR_COLS.size()]
		var open := bar_open(i, hour)
		if open:
			var aw := Rect2(minf(wx, wx + s_in * 16.0), y - half + 6.0, 16.0, half * 2.0 - 12.0)
			b.rect(Rect2(aw.position + Vector2(s_in * 4.0 + 3.0, 6.0), aw.size), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.16))
			var sy := aw.position.y
			var k := 0
			while sy < aw.end.y - 0.5:
				var h := minf(10.0, aw.end.y - sy)
				b.rect(Rect2(aw.position.x, sy, aw.size.x, h), col if k % 2 == 0 else Color(0.94, 0.92, 0.86))
				sy += 10.0
				k += 1
			b.rect(Rect2(aw.position.x + (aw.size.x - 3.0 if s_in > 0.0 else 0.0), aw.position.y, 3.0, aw.size.y), col.darkened(0.3))
			# the valance hanging off its front edge, scalloped
			var vx := wx + s_in * 17.5
			var vy := aw.position.y + 3.5
			while vy < aw.end.y - 2.0:
				b.coarse(Vector2(vx, vy), 3.2, col.darkened(0.12))
				vy += 7.0
			# the cranked arm it is wound in by, at its end
			b.line(Vector2(wx, aw.end.y - 2.0), Vector2(wx + s_in * 15.0, aw.end.y - 2.0), IRON, 1.4)
		# the sign: a small board on a bracket, out over the street
		var sp := Vector2(wx + s_in * 20.0, y - half - 4.0)
		b.line(Vector2(wx, sp.y), sp, IRON, 2.0)
		b.rect(Rect2(sp - Vector2(5.0, 9.0), Vector2(10.0, 18.0)), col.darkened(0.2))
		b.rect(Rect2(sp - Vector2(3.0, 7.0), Vector2(6.0, 14.0)), col.lightened(0.25))
		if open and lit > 0.0:
			b.glow(sp, 26.0, SkyLook.light(Color(col.lightened(0.4).r, col.lightened(0.4).g, col.lightened(0.4).b, 0.30 * lit), tint), 0.2)
	# the strings of bulbs, zigzagging from wall to wall up the street
	var y2 := 120.0
	var zig := 0
	while y2 > GATE + 160.0:
		if not in_xing(y2, 30.0):
			var e := edges_at(y2)
			var a := Vector2(e.x, y2)
			var c := Vector2(e.y, y2 - 90.0)
			if zig % 2 == 1:
				a = Vector2(e.y, y2)
				c = Vector2(e.x, y2 - 90.0)
			_string(b, a, c, lit, tint, zig)
		y2 -= 150.0
		zig += 1
	b.flush()


static func _string(b: ShapeBatch, a: Vector2, c: Vector2, lit: float, tint: Color, salt: int) -> void:
	var n := 14
	var prev := a
	var sag := 14.0
	var side := (c - a).orthogonal().normalized()
	for i in range(1, n + 1):
		var f := float(i) / float(n)
		var p := a.lerp(c, f) + side * sin(f * PI) * sag
		b.line(prev, p, WIRE, 1.2)
		prev = p
	for i in range(1, n):
		var f := float(i) / float(n)
		var p := a.lerp(c, f) + side * sin(f * PI) * sag + Vector2(0.0, 3.0)
		var warm := BULB if (i + salt) % 5 != 0 else Color(1.0, 0.62, 0.40)
		if lit > 0.0:
			if i % 2 == 0:
				b.glow(p, 16.0, SkyLook.light(Color(warm.r, warm.g, warm.b, 0.26 * lit), tint), 0.25)
			b.circle(p, 2.6, SkyLook.light(warm, tint))
		else:
			b.circle(p, 2.6, Color(0.92, 0.90, 0.84))
			b.circle(p - Vector2(0.7, 0.7), 1.0, Color(1.0, 1.0, 1.0))


# --- the street after dark (world/night_fronts.gd) -------------------------------------

static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hour: String = Game.hour
	for i in range(BARS.size()):
		if not bar_open(i, hour):
			continue
		var side: float = BARS[i][0]
		var y: float = BARS[i][1]
		out.append(NightFronts.front(Vector2(wall_x(y, side), y), -side, "bar", 3001 + i))
	# the doors between the bars: homes, a television, the odd shop
	var y2 := 140.0
	var j := 0
	while y2 > GATE + 60.0:
		for side: float in [-1.0, 1.0]:
			var near_bar := false
			for i in range(BARS.size()):
				if float(BARS[i][0]) == side and absf(float(BARS[i][1]) - y2) < float(BARS[i][2]) + 50.0:
					near_bar = true
					break
			if near_bar or in_xing(y2, 30.0):
				continue
			var k := j * 2 + (0 if side < 0.0 else 1) + 3100
			var kind := NightFronts.kind_of(k)
			if kind != "" and kind != "bar":
				out.append(NightFronts.front(Vector2(wall_x(y2, side), y2), -side, kind, k))
		y2 -= 170.0
		j += 1
	return out
