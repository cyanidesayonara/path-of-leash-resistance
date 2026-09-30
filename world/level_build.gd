extends RefCounted

# Builds a walk: the corridor shape, every level's props and furniture (the
# per-level data), the verge, ground patches and dunes, the park props, the
# ground detail, the bypasser blockers, the collision walls, the entities (dog,
# human, leash, layers), the cones and the loose junk.
#
# Static functions over main's state: everything is still built into the same
# fields on main, which drawing, play, level_check.gd and the tests read.
# main.gd keeps a same-name forwarder for each, so _ready calls them exactly as
# before. Typed-array fields are assigned with Array(literal, TYPE, ...): a
# literal assigned through the untyped m would not be typed, and the typed
# field would reject it.




# Per walk: [left strip, width, right strip, width]. Walks not listed (the
# park, the trail, the seafront) have no building line. See main.frontage.
const TUT := preload("res://systems/tutorial.gd")
# the tutorial's pond for the brink lesson, beside the path at its station
const TUT_POND_W := 150.0

const CROSS_SECTIONS := {
	"street": ["road", 160.0, "sidewalk", 120.0],    # a traffic lane; the bike lane side
	"rain": ["none", 0.0, "none", 0.0],             # a shopping street, shopfronts on the paving
	"market": ["none", 0.0, "none", 0.0],             # a market hall: its walls at the aisles
	"oldtown": ["none", 0.0, "none", 0.0],            # an alley: walls at the paving
	"station": ["none", 0.0, "none", 0.0],          # indoors: the walls are the concourse's
	"site": ["sidewalk", 60.0, "sidewalk", 60.0],
	"spook": ["none", 0.0, "none", 0.0],              # an old-town street and its plaça
	"scrap": ["grass", 70.0, "grass", 70.0],          # weeds up to the chain-link
	"guell": ["none", 0.0, "none", 0.0],              # rubble-stone terrace walls
	"neteja": ["none", 0.0, "none", 0.0],             # a back street
}


# the brink lesson's pond, on the grass just off the path's east edge
static func tutorial_pond(m: Node2D) -> Rect2:
	var y: float = TUT.at("teeter")
	var e: Vector2 = m.walk_edges(y)
	return Rect2(e.y + 20.0, y - 90.0, TUT_POND_W, 150.0)


# EL GOTIC, in level space against its own walls
const GOTIC_BRIDGE_Y := -1150.0
const GOTIC_STEPS_Y := -2000.0
const GOTIC_PLACA := Vector2(680.0, -2800.0)


# a point this far in from the west (east=false) or east wall at height y
static func gotic_wall(m: Node2D, y: float, east: bool, inset: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2((e.y - inset) if east else (e.x + inset), y)


static func gotic(m: Node2D) -> void:
	# EL GOTIC: medieval alleys, walls straight onto the paving, laundry
	# overhead, cats on the ledges, bollards where it pinches, steps, the
	# stone bridge between two buildings, flowerpots at the doors, scooters
	# parked against the walls, and the plaça with its fountain. None of the
	# market's stalls.
	m.gate_text = "PLACA"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	m.poles.clear()
	# bollards in the middle where the alley jinks: wind the owner round one
	for y: float in [-650.0, -1580.0, -3500.0, -4050.0]:
		var e: Vector2 = m.walk_edges(y)
		m.poles.append(Vector2((e.x + e.y) * 0.5, y))
	# the plaça's plane tree
	m.poles.append(GOTIC_PLACA + Vector2(-150.0, -60.0))
	m.deco_pole_count = m.poles.size()
	# scooters parked against the walls: solid, and the rope catches them
	m.scooters = Array([gotic_wall(m, -1300.0, false, 26.0), gotic_wall(m, -2100.0, true, 26.0),
		gotic_wall(m, -3650.0, false, 26.0), gotic_wall(m, -4400.0, true, 26.0)], TYPE_VECTOR2, &"", null)
	for sc: Vector2 in m.scooters:
		m.poles.append(sc)
	m.benches = Array([GOTIC_PLACA + Vector2(-250.0, 80.0), GOTIC_PLACA + Vector2(250.0, -80.0)], TYPE_VECTOR2, &"", null)
	m.bins = Array([gotic_wall(m, -900.0, true, 26.0), gotic_wall(m, -3200.0, false, 26.0)], TYPE_VECTOR2, &"", null)
	# the drink is at the basin's rim, where a dog can reach it
	m.fountains = Array([GOTIC_PLACA + Vector2(0.0, 48.0)], TYPE_VECTOR2, &"", null)
	m.performers = Array([GOTIC_PLACA + Vector2(150.0, 110.0)], TYPE_VECTOR2, &"", null)
	m.wallcat_spots = Array([
		gotic_wall(m, -900.0, false, 8.0), gotic_wall(m, -1450.0, true, 8.0),
		gotic_wall(m, -2100.0, false, 8.0), gotic_wall(m, -3350.0, true, 8.0),
		gotic_wall(m, -3950.0, false, 8.0), gotic_wall(m, -4300.0, true, 8.0),
	], TYPE_VECTOR2, &"", null)
	m.laundry_lines = Array([-1000.0, -1850.0, -3450.0, -3900.0, -4400.0], TYPE_FLOAT, &"", null)
	# the owner walks round the fountain, not through it (east side)
	m.islands = Array([{"rect": Rect2(GOTIC_PLACA - Vector2(40.0, 40.0), Vector2(80.0, 80.0)), "side": 1.0}], TYPE_DICTIONARY, &"", null)


# EL MOSAIC: Park Guell's style, walked uphill (docs/LEVEL_DESIGN.md). Sandy
# gravel and rubble stone underfoot; the colour only where Gaudi put it -
# the gatehouse roofs, the salamander, the column medallions and the bench.
const MOSAIC_STAIR_Y0 := -500.0       # the dragon stair, bottom step
const MOSAIC_STAIR_Y1 := -1350.0      # ...and top
const MOSAIC_SALAMANDER := Vector2(640.0, -930.0)
const MOSAIC_SALAMANDER_SIZE := Vector2(110.0, 200.0)
const MOSAIC_HALL_Y0 := -1550.0       # the hypostyle hall
const MOSAIC_HALL_Y1 := -2550.0
const MOSAIC_HALL_COLS: Array[float] = [460.0, 575.0, 705.0, 820.0]
const MOSAIC_HALL_ROWS: Array[float] = [-1660.0, -1860.0, -2060.0, -2260.0, -2460.0]
const MOSAIC_PLAZA_Y0 := -2750.0      # the plaza and its serpentine bench
const MOSAIC_PLAZA_Y1 := -3650.0
const MOSAIC_BAY := 150.0
const MOSAIC_VIADUCT_Y0 := -4100.0    # the viaduct
const MOSAIC_VIADUCT_Y1 := -4650.0
const MOSAIC_VIADUCT_CX := 590.0
const MOSAIC_CALVARY := Vector2(860.0, -4760.0)


static func mosaic(m: Node2D, hyd_list: Array, keb_list: Array) -> void:
	m.gate_text = "EL CALVARI"
	m.pond = Rect2()
	m.patches.clear()
	m.stalls.clear()
	m.stall_kinds.clear()
	m.poles.clear()
	# the hypostyle hall: a grid of fat Doric columns, a clear lane between
	# the middle two for the owner, the best pole forest in the game
	for y: float in MOSAIC_HALL_ROWS:
		for x: float in MOSAIC_HALL_COLS:
			m.poles.append(Vector2(x, y))
	# the viaduct's leaning columns down its east side
	var vy := MOSAIC_VIADUCT_Y0 - 40.0
	while vy > MOSAIC_VIADUCT_Y1 + 20.0:
		m.poles.append(Vector2(m.walk_edges(vy).y - 30.0, vy))
		vy -= 110.0
	m.deco_pole_count = m.poles.size()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	m.benches = Array([], TYPE_VECTOR2, &"", null)
	m.bins = Array([Vector2(m.walk_edges(-300.0).x + 30.0, -300.0), Vector2(m.walk_edges(-3700.0).y - 30.0, -3700.0)],
		TYPE_VECTOR2, &"", null)
	# the drink is the water from the salamander's mouth
	m.fountains = Array([MOSAIC_SALAMANDER + Vector2(0.0, MOSAIC_SALAMANDER_SIZE.y * 0.5 + 18.0)], TYPE_VECTOR2, &"", null)
	# a guitarist in the viaduct, a fan seller on the plaza
	m.performers = Array([Vector2(m.walk_edges(-4400.0).x + 60.0, -4400.0),
		Vector2(m.walk_edges(-3200.0).x + 80.0, -3200.0)], TYPE_VECTOR2, &"", null)
	# agave planters of rubble stone: what gets marked here
	hyd_list.clear()
	for hy: Array in [[-300.0, false], [-1450.0, true], [-2650.0, false], [-3850.0, true], [-4550.0, true]]:
		var e: Vector2 = m.walk_edges(float(hy[0]))
		hyd_list.append(Vector2(e.x + 30.0 if bool(hy[1]) else e.y - 30.0, float(hy[0])))
	# tourists' dropped snacks
	keb_list.clear()
	for k: Vector2 in [Vector2(560.0, -1450.0), Vector2(760.0, -3100.0), Vector2(520.0, -3500.0)]:
		keb_list.append(k)
	# the owner walks round the salamander on its east side
	m.islands = Array([{"rect": Rect2(MOSAIC_SALAMANDER - MOSAIC_SALAMANDER_SIZE * 0.5 - Vector2(24.0, 24.0),
		MOSAIC_SALAMANDER_SIZE + Vector2(48.0, 48.0)), "side": 1.0}], TYPE_DICTIONARY, &"", null)


# LA NETEJA: a narrow back street at dawn, on the morning the sweeper comes
# through. The home leg is a run, so the street stays runnable: what narrows
# it is what a back street has at that hour - dumpsters out at the kerbs
# (solid), scooters parked up, delivery crates stacked by the dumpsters, the
# lampposts, washing overhead, the shops' shutters still down, and the wet
# streaks and puddles the water truck left.
const NETEJA_DUMPSTERS: Array = [[-1000.0, true], [-1900.0, false], [-2800.0, true], [-3600.0, false], [-4300.0, true]]
const NETEJA_DUMPSTER := Vector2(46.0, 90.0)
const NETEJA_SCOOTERS: Array = [[-1450.0, false], [-2350.0, true], [-3200.0, false], [-4000.0, true]]


static func neteja_kerb(m: Node2D, y: float, west: bool, inset: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2(e.x + inset if west else e.y - inset, y)


static func neteja_dumpsters(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for d: Array in NETEJA_DUMPSTERS:
		out.append(neteja_kerb(m, float(d[0]), bool(d[1]), NETEJA_DUMPSTER.x * 0.5 + 6.0))
	return out


static func neteja(m: Node2D) -> void:
	m.gate_text = "PLACA"
	m.stalls = Array([], TYPE_VECTOR2, &"", null)
	m.stall_kinds.clear()
	m.performers = Array([], TYPE_VECTOR2, &"", null)
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.benches = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(640, -3100)], TYPE_VECTOR2, &"", null)
	m.laundry_lines = Array([-900.0, -1700.0, -2500.0, -3300.0, -4100.0], TYPE_FLOAT, &"", null)
	m.poles.clear()
	# a slalom of lampposts down the middle, far enough apart to run between,
	# close enough that a straight line snags the leash
	for yy in [-1300.0, -2200.0, -3700.0, -4500.0]:
		m.poles.append(Vector2(m.walk_cx + (55.0 if int(yy) % 200 == 0 else -55.0), yy))
	m.deco_pole_count = m.poles.size()
	# scooters parked at the kerbs: solid, and the rope catches them
	m.scooters = Array([], TYPE_VECTOR2, &"", null)
	for sc: Array in NETEJA_SCOOTERS:
		var sp := neteja_kerb(m, float(sc[0]), bool(sc[1]), 22.0)
		m.scooters.append(sp)
		m.poles.append(sp)
	# the dumpsters' corners catch the rope too
	for d: Vector2 in neteja_dumpsters(m):
		m.poles.append(d + Vector2(0.0, -NETEJA_DUMPSTER.y * 0.5 + 8.0))
		m.poles.append(d + Vector2(0.0, NETEJA_DUMPSTER.y * 0.5 - 8.0))
	# delivery crates stacked by the dumpsters
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	for d: Vector2 in neteja_dumpsters(m):
		m.cone_spots.append(d + Vector2(0.0, -NETEJA_DUMPSTER.y * 0.5 - 34.0))
	# what the water truck left: puddles in the gutters and down the middle
	for pz: Array in [[-800.0, 0.2], [-1650.0, 0.75], [-2550.0, 0.3], [-3400.0, 0.7], [-4150.0, 0.35]]:
		m.patches.append({"y": float(pz[0]), "at": float(pz[1]), "rx": 60.0, "ry": 34.0,
			"seed": 1.7 + float(pz[1]) * 3.0, "kind": "puddle"})


# LA CASTANYADA: the chestnut festival at night, in an old-town plaça. The
# roaster is the landmark in the middle of the plaça (solid; the owner walks
# round it), a little stage on its west side with the band on it, plane trees
# round it, festival stalls along the street - chestnuts, panellets, roast
# sweet potatoes, sweets - paper-lantern strings overhead, confetti and
# chocolate underfoot (the dog must not eat the chocolate), and hessian sacks
# of chestnuts where a street has hydrants.
const CAST_PLACA := Vector2(640.0, -2700.0)
const CAST_ROASTER := Vector2(110.0, 64.0)
const CAST_LANTERN_YS: Array[float] = [-700.0, -1150.0, -1600.0, -2050.0, -3350.0, -3800.0, -4250.0]
# [y, west side?, kind]
const CAST_STALLS: Array = [
	[-850.0, true, "panellets"], [-1200.0, false, "castanyes"], [-1650.0, true, "moniatos"],
	[-2400.0, false, "panellets"], [-2950.0, false, "sweets"],
	[-3700.0, false, "moniatos"], [-4100.0, true, "sweets"], [-4450.0, false, "castanyes"],
]


static func castanyada_stage(m: Node2D) -> Rect2:
	var e: Vector2 = m.walk_edges(CAST_PLACA.y)
	return Rect2(e.x + 14.0, CAST_PLACA.y - 190.0, 110.0, 300.0)


static func castanyada(m: Node2D, hyd_list: Array, keb_list: Array) -> void:
	m.gate_text = "PLACA"
	m.stalls.clear()
	m.stall_kinds.clear()
	for st: Array in CAST_STALLS:
		var e: Vector2 = m.walk_edges(float(st[0]))
		m.stalls.append(Vector2(e.x + 62.0 if bool(st[1]) else e.y - 62.0, float(st[0])))
		m.stall_kinds.append(String(st[2]))
	m.poles.clear()
	# the plaça's plane trees
	for t: Vector2 in [Vector2(-300.0, -300.0), Vector2(300.0, -330.0), Vector2(310.0, 320.0), Vector2(-180.0, 360.0)]:
		m.poles.append(CAST_PLACA + t)
	m.deco_pole_count = m.poles.size()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.benches = Array([CAST_PLACA + Vector2(240.0, 60.0)], TYPE_VECTOR2, &"", null)
	var eb: Vector2 = m.walk_edges(-1400.0)
	m.bins = Array([Vector2(eb.y - 26.0, -1400.0), Vector2(m.walk_edges(-3950.0).x + 26.0, -3950.0)], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(m.walk_edges(-1000.0).y - 30.0, -1000.0)], TYPE_VECTOR2, &"", null)
	# the band on the stage, and a juggler in the street
	var stage := castanyada_stage(m)
	m.performers = Array([stage.get_center() + Vector2(0.0, -60.0), stage.get_center() + Vector2(0.0, 60.0),
		Vector2(m.walk_edges(-3600.0).x + 70.0, -3600.0)], TYPE_VECTOR2, &"", null)
	# litter round the stalls
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	for i in range(0, m.stalls.size(), 2):
		m.cone_spots.append(m.stalls[i] + Vector2(0.0, -60.0))
	# sweets underfoot everywhere, chocolate among them: steer past it
	m.candy_spots = Array([
		Vector2(560, -1000), Vector2(720, -1450), Vector2(590, -1850),
		CAST_PLACA + Vector2(-130.0, 150.0), CAST_PLACA + Vector2(140.0, 120.0), CAST_PLACA + Vector2(60.0, -200.0),
		Vector2(700, -3500), Vector2(570, -3950), Vector2(710, -4350),
	], TYPE_VECTOR2, &"", null)
	# hessian sacks of chestnuts: what gets marked
	hyd_list.clear()
	for hy: Array in [[-600.0, false], [-1450.0, true], [-2300.0, true], [-3550.0, true], [-4300.0, false]]:
		var e2: Vector2 = m.walk_edges(float(hy[0]))
		hyd_list.append(Vector2(e2.x + 30.0 if bool(hy[1]) else e2.y - 30.0, float(hy[0])))
	# a dropped paper cone of chestnuts, and a panellet off a tray
	keb_list.clear()
	for k: Vector2 in [Vector2(700.0, -1300.0), CAST_PLACA + Vector2(200.0, -120.0), Vector2(580.0, -4000.0)]:
		keb_list.append(k)
	# the owner walks round the roaster on its east side
	m.islands = Array([{"rect": Rect2(CAST_PLACA - CAST_ROASTER * 0.5 - Vector2(20.0, 20.0), CAST_ROASTER + Vector2(40.0, 40.0)),
		"side": 1.0}], TYPE_DICTIONARY, &"", null)


# EL MERCAT: a covered market hall, the Boqueria kind. In under an iron and
# stained-glass arch, then the hall: four blocks of stalls down the middle
# (solid; the owner keeps to one aisle, the dog takes either), an iron column
# at every corner to wind the leash on, stalls along both walls - fruit, the
# fish counter on its ice, jamon, olives, juices, sweets - meltwater and fish
# scales in front of the fish, crates stacked behind the fruit, sawdust, and
# a terrazzo floor. Out through the far door into the plaça.
const MERCAT_ARCH_Y := -700.0
const MERCAT_DOOR_Y := -4650.0
const MERCAT_HALL_HALF := 400.0
const MERCAT_BLOCKS: Array[Rect2] = [
	Rect2(545.0, -1500.0, 190.0, 300.0), Rect2(545.0, -2400.0, 190.0, 300.0),
	Rect2(545.0, -3300.0, 190.0, 300.0), Rect2(545.0, -4200.0, 190.0, 300.0),
]
# [y, west wall?, kind]
const MERCAT_WALL_STALLS: Array = [
	[-1050.0, false, "fruit"], [-1250.0, true, "juice"], [-1750.0, false, "jamon"],
	[-2050.0, true, "fish"], [-2650.0, false, "olives"], [-2950.0, true, "fruit"],
	[-3550.0, false, "sweets"], [-3850.0, true, "jamon"], [-4350.0, false, "fruit"],
	[-4450.0, true, "fish"],
]
const MERCAT_DRAIN := Vector2(640.0, -1920.0)


static func mercat_stall_pos(m: Node2D, i: int) -> Vector2:
	var st: Array = MERCAT_WALL_STALLS[i]
	var e: Vector2 = m.walk_edges(float(st[0]))
	return Vector2(e.x + 62.0 if bool(st[1]) else e.y - 62.0, float(st[0]))


# where a customer (or a dog with a delivery) stands at a wall stall
static func mercat_stall_front(m: Node2D, i: int) -> Vector2:
	var p := mercat_stall_pos(m, i)
	var st: Array = MERCAT_WALL_STALLS[i]
	return p + Vector2(80.0 if bool(st[1]) else -80.0, 0.0)


static func mercat(m: Node2D, hyd_list: Array, keb_list: Array) -> void:
	m.gate_text = "PLACA"
	m.stalls.clear()
	m.stall_kinds.clear()
	for i in range(MERCAT_WALL_STALLS.size()):
		m.stalls.append(mercat_stall_pos(m, i))
		m.stall_kinds.append(String(MERCAT_WALL_STALLS[i][2]))
	m.poles.clear()
	# the hall's iron columns, one at each corner of every stall block
	for blk: Rect2 in MERCAT_BLOCKS:
		for c: Vector2 in [blk.position + Vector2(-26.0, -26.0), Vector2(blk.end.x + 26.0, blk.position.y - 26.0),
				Vector2(blk.position.x - 26.0, blk.end.y + 26.0), blk.end + Vector2(26.0, 26.0)]:
			m.poles.append(c)
	m.deco_pole_count = m.poles.size()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.benches = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([MERCAT_DRAIN], TYPE_VECTOR2, &"", null)
	var ew: Vector2 = m.walk_edges(-2400.0)
	m.bins = Array([Vector2(ew.x + 26.0, -2350.0), Vector2(ew.y - 26.0, -3450.0)], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(m.walk_edges(-900.0).x + 30.0, -900.0)], TYPE_VECTOR2, &"", null)
	# a busker under the arch, where the acoustics are
	m.performers = Array([Vector2(820.0, MERCAT_ARCH_Y + 60.0)], TYPE_VECTOR2, &"", null)
	# crates stacked out behind the fruit stalls
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	for i in range(MERCAT_WALL_STALLS.size()):
		if String(MERCAT_WALL_STALLS[i][2]) == "fruit":
			m.cone_spots.append(mercat_stall_pos(m, i) + Vector2(0.0, -58.0))
	# crate stacks of oranges at the wall between stalls: what gets marked here
	hyd_list.clear()
	for y: float in [-900.0, -1550.0, -2350.0, -3200.0, -4000.0]:
		var e: Vector2 = m.walk_edges(y)
		hyd_list.append(Vector2(e.x + 30.0 if int(absf(y)) % 2 == 0 else e.y - 30.0, y))
	# dropped produce in the aisles
	keb_list.clear()
	for k: Vector2 in [Vector2(470.0, -1300.0), Vector2(810.0, -2000.0), Vector2(470.0, -2800.0),
			Vector2(810.0, -3500.0), Vector2(470.0, -4100.0)]:
		keb_list.append(k)
	# meltwater off the fish counters' ice, and the scales that come with it
	for i in range(MERCAT_WALL_STALLS.size()):
		if String(MERCAT_WALL_STALLS[i][2]) == "fish":
			var f := mercat_stall_front(m, i)
			m.patches.append({"y": f.y, "at": 0.0, "rx": 58.0, "ry": 40.0, "seed": 2.2 + float(i),
				"kind": "puddle", "pin": f + Vector2(0.0, 30.0)})
			m.patches.append({"y": f.y, "at": 0.0, "rx": 34.0, "ry": 24.0, "seed": 3.1 + float(i),
				"kind": "fish", "pin": f + Vector2(0.0, -20.0)})
	# the owner keeps to one aisle round each block, alternating
	var isl: Array[Dictionary] = []
	for i in range(MERCAT_BLOCKS.size()):
		isl.append({"rect": MERCAT_BLOCKS[i].grow(20.0), "side": 1.0 if i % 2 == 0 else -1.0})
	m.islands = isl


# LA FERRALLA. Wreck stacks along both sides of the lane (authored in the
# 300..980 space, fitted to the lane like vans), the crane's base and the
# line of its boom across the yard.
const FERRALLA_STACKS: Array[Vector2] = [
	Vector2(300, -700), Vector2(980, -950), Vector2(300, -1650), Vector2(980, -1800),
	Vector2(300, -2350), Vector2(980, -2900), Vector2(300, -3550), Vector2(980, -3750),
	Vector2(300, -4250), Vector2(980, -4650),
]
const FERRALLA_CRANE := Vector2(1080.0, -2500.0)
const FERRALLA_BOOM_TO := Vector2(420.0, -2380.0)


static func ferralla(m: Node2D) -> void:
	# LA FERRALLA: the scrapyard shortcut. A lane between stacked wrecks,
	# oil pooled behind them, the crane over the yard, the guard dogs asleep
	# by their kennels, cameras and lasers. Slow is silent; getting caught is
	# embarrassing, not fatal. No terrace, no benches, no hydrant grid, no
	# road crossings.
	m.gate_text = "BACK GATE"
	m.lane_ys = Array([], TYPE_FLOAT, &"", null)
	m.tables.clear()
	m.chairs.clear()
	m.parasols.clear()
	m.benches.clear()
	m.cellars.clear()
	m.stalls.clear()
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.performers = Array([], TYPE_VECTOR2, &"", null)
	m.poles.clear()
	# floodlight masts, the only upright things that are not scrap
	for y: float in [-450.0, -1450.0, -2600.0, -3900.0]:
		m.poles.append(Vector2(640.0 + (150.0 if int(-y) % 2 == 0 else -150.0), y))
	m.deco_pole_count = m.poles.size()
	m.vans = Array(FERRALLA_STACKS.duplicate(), TYPE_VECTOR2, &"", null)
	m.bins = Array([Vector2(m.sw_l + 30, -900), Vector2(m.sw_r - 30, -3000)], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(m.sw_r - 40, -2700)], TYPE_VECTOR2, &"", null)   # a rain barrel
	m.cone_spots = Array([Vector2(560, -1950), Vector2(720, -3050), Vector2(600, -3900)], TYPE_VECTOR2, &"", null)
	m.guard_posts = Array([
		Vector2(400, -1350), Vector2(880, -2250),
		Vector2(400, -3150), Vector2(880, -4050),
	], TYPE_VECTOR2, &"", null)
	m.cameras = Array([
		{"pos": Vector2(330, -1900), "base": 0.0, "range": 0.9, "speed": 0.7, "cd": 0.0},
		{"pos": Vector2(950, -3500), "base": PI, "range": 0.9, "speed": 0.55, "cd": 0.0},
	], TYPE_DICTIONARY, &"", null)
	# the lasers run across the lane where it is at their height
	var l1: Vector2 = m.walk_edges(-2650.0)
	var l2: Vector2 = m.walk_edges(-4350.0)
	m.lasers = Array([
		{"x0": l1.x, "x1": l1.y, "y_lo": -2750.0, "y_hi": -2550.0, "speed": 1.1, "cd": 0.0},
		{"x0": l2.x, "x1": l2.y, "y_lo": -4450.0, "y_hi": -4250.0, "speed": 0.8, "cd": 0.0},
	], TYPE_DICTIONARY, &"", null)
	# oil pooled on the lane side of some of the stacks
	m.patches = Array([], TYPE_DICTIONARY, &"", null)
	for i: int in [1, 3, 4, 6, 8]:
		var sv: Vector2 = FERRALLA_STACKS[i]
		m.patches.append({"y": sv.y + 40.0, "at": 0.18 if sv.x < 640.0 else 0.82, "rx": 40.0, "ry": 26.0,
			"seed": float(i) * 0.7, "kind": "oil"})


# L'ESTACIO, in level space (its posts are not fitted to the path)
const ESTACIO_PILLAR_XS: Array[float] = [400.0, 880.0]
const ESTACIO_PILLAR_YS: Array[float] = [-1150.0, -1500.0, -1850.0, -2200.0, -2550.0]
const ESTACIO_WALKWAY := Rect2(550.0, -2750.0, 180.0, 1500.0)
const ESTACIO_BARRIER_Y := -3000.0
# gaps in the barrier line: the owner's in the middle, one either side
const ESTACIO_GAPS: Array[float] = [400.0, 640.0, 880.0]
const ESTACIO_GAP_W := 72.0
const ESTACIO_TRAIN := Rect2(560.0, -4700.0, 160.0, 1450.0)
const ESTACIO_BOARD := Vector2(640.0, -1020.0)


static func estacio(m: Node2D) -> void:
	# L'ESTACIO: inside a station. The departures board over the concourse,
	# fat pillars, bench rows, the moving walkway up the middle, rows of
	# nested trolleys, the ticket barriers, and the train standing between two
	# platforms. No terrace, no crossings, no drains, no lawn: it is indoors.
	m.gate_text = "PLATFORM"
	m.lane_ys = Array([], TYPE_FLOAT, &"", null)
	m.tables.clear()
	m.chairs.clear()
	m.parasols.clear()
	m.cellars.clear()
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	m.poles.clear()
	for y: float in ESTACIO_PILLAR_YS:
		for x: float in ESTACIO_PILLAR_XS:
			m.poles.append(Vector2(x, y))
	# the barrier line: cabinets close enough together that only the gaps pass
	var be: Vector2 = m.walk_edges(ESTACIO_BARRIER_Y)
	var bx := be.x + 14.0
	while bx < be.y - 10.0:
		var in_gap := false
		for g: float in ESTACIO_GAPS:
			in_gap = in_gap or absf(bx - g) < ESTACIO_GAP_W * 0.5
		if not in_gap:
			m.poles.append(Vector2(bx, ESTACIO_BARRIER_Y))
		bx += 34.0
	m.deco_pole_count = m.poles.size()
	m.conveyor_zone = ESTACIO_WALKWAY
	m.conveyor_dir = Vector2(0, -1)
	m.benches = Array([Vector2(336, -1700), Vector2(944, -1700), Vector2(336, -2400), Vector2(944, -2400)], TYPE_VECTOR2, &"", null)
	m.bins = Array([Vector2(m.sw_l + 30, -800), Vector2(m.sw_r - 30, -2000), Vector2(m.sw_l + 30, -4000)], TYPE_VECTOR2, &"", null)
	# rows of nested trolleys, where a street has parked vans
	m.vans = Array([Vector2(360, -1320), Vector2(920, -2750)], TYPE_VECTOR2, &"", null)
	m.performers = Array([Vector2(880, -1150)], TYPE_VECTOR2, &"", null)   # a busker by the pillars
	m.fountains = Array([Vector2(930, -3300)], TYPE_VECTOR2, &"", null)
	# the owner goes through the middle gate, and keeps to the east platform
	m.narrows = Array([{"y0": ESTACIO_BARRIER_Y - 12.0, "y1": ESTACIO_BARRIER_Y + 12.0,
		"x0": ESTACIO_GAPS[1] - ESTACIO_GAP_W * 0.5 + 16.0, "x1": ESTACIO_GAPS[1] + ESTACIO_GAP_W * 0.5 - 16.0}], TYPE_DICTIONARY, &"", null)
	m.islands = Array([{"rect": ESTACIO_TRAIN, "side": 1.0}], TYPE_DICTIONARY, &"", null)


# EL DILUVI. The arcade down the west side: a covered walk behind a row of
# pillars, the one long stretch of dry on the walk.
const DILUVI_ARCADE_Y0 := -3300.0
const DILUVI_ARCADE_Y1 := -1300.0
const DILUVI_ARCADE_W := 84.0          # from the building line to the pillars
# the shop awnings over the east side: [y, length]
const DILUVI_AWNINGS: Array = [[-700.0, 110.0], [-1050.0, 90.0], [-1650.0, 120.0], [-2150.0, 100.0],
	[-2650.0, 110.0], [-3150.0, 90.0], [-3650.0, 120.0], [-4150.0, 100.0], [-4550.0, 90.0]]
const DILUVI_AWNING_D := 56.0


# Where it is dry on El Diluvi: the arcade and under each awning.
static func diluvi_shelters(m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var e: Vector2 = m.walk_edges(DILUVI_ARCADE_Y1)
	out.append(Rect2(e.x - 4.0, DILUVI_ARCADE_Y0, DILUVI_ARCADE_W + 4.0, DILUVI_ARCADE_Y1 - DILUVI_ARCADE_Y0))
	for aw: Array in DILUVI_AWNINGS:
		var ay := float(aw[0])
		var ae: Vector2 = m.walk_edges(ay)
		out.append(Rect2(ae.y - DILUVI_AWNING_D, ay - float(aw[1]) * 0.5, DILUVI_AWNING_D + 4.0, float(aw[1])))
	return out


static func diluvi(m: Node2D) -> void:
	# EL DILUVI: a narrow shopping street in a downpour. Shopfronts straight
	# onto the paving, awnings over the east side, the arcade down the west,
	# puddles everywhere, the gutters running, umbrellas. The terrace is
	# stacked and chained somewhere dry; there is no lawn.
	m.gate_text = "SHELTER"
	m.lane_ys = Array([-900.0, -3900.0], TYPE_FLOAT, &"", null)
	m.tables.clear()
	m.chairs.clear()
	m.parasols.clear()
	m.benches.clear()
	m.cellars.clear()
	m.stalls.clear()
	m.vans.clear()
	m.astands = Array([Vector2(860, -2900)], TYPE_VECTOR2, &"", null)
	# lamp standards down the east side, the arcade's pillars down the west
	m.poles.clear()
	for i in range(8):
		var y := -400.0 - float(i) * 600.0
		var ok := true
		for ly: float in m.lane_ys:
			ok = ok and absf(y - ly) > m.LANE_HALF + 60.0
		if ok:
			m.poles.append(Vector2(980.0, y))
	var e: Vector2 = m.walk_edges(DILUVI_ARCADE_Y1)
	var py := DILUVI_ARCADE_Y1 - 40.0
	while py > DILUVI_ARCADE_Y0 + 30.0:
		m.poles.append(Vector2(e.x + DILUVI_ARCADE_W, py))
		py -= 120.0
	m.deco_pole_count = m.poles.size()
	m.bins = Array([Vector2(m.sw_r - 30, -1500), Vector2(m.sw_r - 30, -3300)], TYPE_VECTOR2, &"", null)
	# storm drains gaping open in the middle of the street
	m.manholes = Array([Vector2(640, -1500), Vector2(600, -2650), Vector2(680, -4300)], TYPE_VECTOR2, &"", null)
	# a huddle of umbrellas clogging the street, gaps left so it is never a wall
	m.performers = Array([Vector2(560, -2250), Vector2(790, -2320), Vector2(600, -3560), Vector2(760, -3520)], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(860, -2000)], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	# puddles on the paving, in the dips where the street was laid badly
	m.patches = Array([
		{"y": -600.0, "at": 0.55, "rx": 60.0, "ry": 34.0, "seed": 1.2, "kind": "puddle"},
		{"y": -1150.0, "at": 0.30, "rx": 74.0, "ry": 40.0, "seed": 2.7, "kind": "puddle"},
		{"y": -1900.0, "at": 0.62, "rx": 56.0, "ry": 30.0, "seed": 3.9, "kind": "puddle"},
		{"y": -2450.0, "at": 0.45, "rx": 84.0, "ry": 46.0, "seed": 0.8, "kind": "puddle"},
		{"y": -3000.0, "at": 0.66, "rx": 62.0, "ry": 34.0, "seed": 4.4, "kind": "puddle"},
		{"y": -3350.0, "at": 0.40, "rx": 70.0, "ry": 38.0, "seed": 5.1, "kind": "puddle"},
		{"y": -4100.0, "at": 0.55, "rx": 90.0, "ry": 48.0, "seed": 2.2, "kind": "puddle"},
		{"y": -4700.0, "at": 0.35, "rx": 58.0, "ry": 32.0, "seed": 3.3, "kind": "puddle"},
	], TYPE_DICTIONARY, &"", null)
	m.shelters = diluvi_shelters(m)


# EL BARRI's pieces, in level space
const BARRI_PETANCA := Rect2(360.0, -1980.0, 150.0, 260.0)
const BARRI_PLAYGROUND := Rect2(790.0, -4000.0, 166.0, 300.0)
const BARRI_PINGPONG := Vector2(760.0, -2560.0)


# LES OBRES. Wet cement poured in rectangular formwork, half the footway
# at a time and alternating sides, so there is always a line past; cones at
# the corners and tape between them. Level space, set against the chicane.
const OBRES_SLABS: Array[Rect2] = [
	Rect2(318.0, -1760.0, 170.0, 190.0),
	Rect2(640.0, -3380.0, 186.0, 200.0),
]
# the freshly painted zebra crossing across the footway
const OBRES_ZEBRA_Y := -2230.0
const OBRES_ZEBRA_H := 64.0
# the trench across the footway, and the plank bridge the owner walks over
const OBRES_TRENCH_Y := -2860.0
const OBRES_TRENCH_H := 44.0
const OBRES_PLANK := 110.0
const OBRES_DIGGER := Vector2(900.0, -1400.0)


static func obres(m: Node2D) -> void:
	m.gate_text = "DETOUR"
	# a side street at each end of the works, with its traffic
	m.lane_ys = Array([-1100.0, -4000.0], TYPE_FLOAT, &"", null)
	m.poles.clear()
	# lamp standards down the edges, clear of the crossings and the works
	for i in range(8):
		var x := 300.0 if i % 2 == 0 else 980.0
		var y := -350.0 - float(i) * 600.0
		var ok := true
		for ly: float in m.lane_ys:
			ok = ok and absf(y - ly) > m.LANE_HALF + 60.0
		ok = ok and absf(y - OBRES_TRENCH_Y) > 120.0 and absf(y - OBRES_ZEBRA_Y) > 90.0
		for sl: Rect2 in OBRES_SLABS:
			ok = ok and not sl.grow(60.0).has_point(Vector2(x, y))
		if ok:
			m.poles.append(Vector2(x, y))
	m.deco_pole_count = m.poles.size()
	m.tables.clear()
	m.chairs.clear()
	m.parasols.clear()
	m.benches.clear()
	m.stalls.clear()
	m.cellars.clear()
	m.bins = Array([Vector2(330, -600), Vector2(950, -2050), Vector2(330, -4450)], TYPE_VECTOR2, &"", null)
	# DESVIAMENT signs where the footway turns off
	m.astands = Array([Vector2(420, -1320), Vector2(860, -3560)], TYPE_VECTOR2, &"", null)
	# the lads in hi-vis, leaning on their shovels
	m.performers = Array([Vector2(820, -1780), Vector2(440, -3300)], TYPE_VECTOR2, &"", null)
	m.vans = Array([OBRES_DIGGER], TYPE_VECTOR2, &"", null)
	m.manholes = Array([Vector2(700, -700), Vector2(560, -4300)], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(335, -4200)], TYPE_VECTOR2, &"", null)
	m.patches.clear()
	m.cement_zones = Array(OBRES_SLABS.duplicate(), TYPE_RECT2, &"", null)
	# cones: the corners of every pour, both ends of the zebra, the trench ends
	var cones: Array[Vector2] = []
	for sl: Rect2 in OBRES_SLABS:
		for c: Vector2 in [sl.position, Vector2(sl.end.x, sl.position.y), sl.end, Vector2(sl.position.x, sl.end.y)]:
			cones.append(c + (c - sl.get_center()).normalized() * 16.0)
	var ze: Vector2 = m.walk_edges(OBRES_ZEBRA_Y)
	cones.append(Vector2(ze.x + 18.0, OBRES_ZEBRA_Y + OBRES_ZEBRA_H * 0.5))
	cones.append(Vector2(ze.y - 18.0, OBRES_ZEBRA_Y + OBRES_ZEBRA_H * 0.5))
	var tr: Vector2 = m.walk_edges(OBRES_TRENCH_Y)
	cones.append(Vector2(tr.x + 16.0, OBRES_TRENCH_Y + OBRES_TRENCH_H + 20.0))
	cones.append(Vector2(tr.y - 16.0, OBRES_TRENCH_Y - 20.0))
	m.cone_spots = Array(cones, TYPE_VECTOR2, &"", null)
	# the trench: open ground either side of the plank (a hole, like a cellar)
	var te: Vector2 = m.walk_edges(OBRES_TRENCH_Y)
	var pc: float = (te.x + te.y) * 0.5
	m.cellars = Array([
		Rect2(te.x - 60.0, OBRES_TRENCH_Y, pc - OBRES_PLANK * 0.5 - (te.x - 60.0), OBRES_TRENCH_H),
		Rect2(pc + OBRES_PLANK * 0.5, OBRES_TRENCH_Y, te.y + 60.0 - (pc + OBRES_PLANK * 0.5), OBRES_TRENCH_H),
	], TYPE_RECT2, &"", null)
	# the owner keeps to the plank (human._walk)
	m.narrows = Array([{"y0": OBRES_TRENCH_Y, "y1": OBRES_TRENCH_Y + OBRES_TRENCH_H,
		"x0": pc - OBRES_PLANK * 0.5 + 12.0, "x1": pc + OBRES_PLANK * 0.5 - 12.0}], TYPE_DICTIONARY, &"", null)


# LA RAMBLA. The square with the round pavement mosaic, halfway down.
const RAMBLA_MOSAIC := Vector2(640.0, -1650.0)
const RAMBLA_MOSAIC_R := 66.0
# stalls along the promenade, in the 300..980 authored space: [pos, kind]
const RAMBLA_STALLS: Array = [
	[Vector2(760.0, -680.0), "kiosk"],
	[Vector2(846.0, -1480.0), "souvenir"],
	[Vector2(470.0, -2440.0), "caricature"],
	[Vector2(800.0, -2380.0), "icecream"],
	[Vector2(446.0, -2980.0), "flowers"],
	[Vector2(446.0, -3110.0), "flowers"],
	[Vector2(560.0, -3200.0), "flowers"],
	[Vector2(470.0, -4560.0), "souvenir"],
]
# sellers' blankets on the paving, goods laid out: [rect, goods]
const RAMBLA_BLANKETS: Array = [
	[Rect2(352.0, -1080.0, 74.0, 52.0), "shades"],
	[Rect2(846.0, -1980.0, 74.0, 52.0), "bags"],
	[Rect2(352.0, -3700.0, 74.0, 52.0), "toys"],
	[Rect2(846.0, -4420.0, 74.0, 52.0), "shades"],
]
# the shell game on its cardboard box, a crowd of shills round it
const RAMBLA_SHELLS := Vector2(806.0, -3300.0)
# the ice cream someone dropped, by the cart
const RAMBLA_ICECREAM := Vector2(744.0, -2318.0)
# the human statues, painted head to foot on their boxes
const RAMBLA_STATUES: Array[Vector2] = [
	Vector2(880.0, -960.0), Vector2(520.0, -2780.0), Vector2(870.0, -4300.0),
]


# La Rambla's own layout on the boulevard base: plane trees in a row down
# both edges of the promenade (the tree grates and the odd lamp standard),
# stalls, sellers' blankets and human statues, the terrace where it is (in
# the middle of the promenade, as the real terraces are), no lawn.
static func rambla(m: Node2D, hyd_list: Array) -> void:
	m.stalls.clear()
	m.stall_kinds.clear()
	for st: Array in RAMBLA_STALLS:
		m.stalls.append(st[0])
		m.stall_kinds.append(String(st[1]))
	m.blankets.clear()
	for bl: Array in RAMBLA_BLANKETS:
		var br: Rect2 = bl[0]
		m.blankets.append({"rect": br, "goods": String(bl[1]), "cd": 0.0,
			"state": "laid", "t": 0.0, "sp": m._seller_pos(br), "to": Vector2.ZERO})
	m.shell_game = {"pos": RAMBLA_SHELLS, "done": false, "t": 0.0}
	# a dropped ice cream by the cart: sticky, and a thief running over it slips
	m.patches.append({"y": RAMBLA_ICECREAM.y, "at": 0.0, "rx": 20.0, "ry": 15.0, "seed": 2.2,
		"kind": "icecream", "pin": RAMBLA_ICECREAM})
	m.statues = RAMBLA_STATUES.duplicate()
	# the poles the boulevard base put up, less the lamp standard that stood
	# where the mosaic is
	var keep: Array[Vector2] = []
	for p: Vector2 in m.poles:
		if p.distance_to(RAMBLA_MOSAIC) > RAMBLA_MOSAIC_R + 40.0 and (p.x > 400.0 and p.x < 880.0):
			keep.append(p)
	# everything the row of trees must keep clear of
	var taken: Array[Vector2] = []
	for arr in [m.bins, m.benches, m.astands, m.vans, m.fountains, m.performers, m.cone_spots,
			m.tables, m.chairs, m.parasols, m.stalls, m.statues, keep]:
		for v: Vector2 in arr:
			taken.append(v)
	for hp: Vector2 in hyd_list:
		taken.append(hp)
	for cl: Rect2 in m.cellars:
		taken.append(cl.get_center())
	for bl: Dictionary in m.blankets:
		taken.append((bl["rect"] as Rect2).get_center())
	taken.append(Vector2(m.sw_l + 66.0, -3560.0))    # the FUR-GONETA
	var y := -300.0
	while y > m.GATE_Y + 260.0:
		for x: float in [300.0, 980.0]:
			var tp := Vector2(x, y)
			var ok := true
			for ly: float in m.lane_ys:
				ok = ok and absf(y - ly) > m.LANE_HALF + 60.0
			for tv: Vector2 in taken:
				ok = ok and tv.distance_to(tp) > 78.0
			if ok:
				keep.append(tp)
		y -= 270.0
	m.poles = Array(keep, TYPE_VECTOR2, &"", null)
	m.deco_pole_count = m.poles.size()


# EL PARC's pieces, all in level space (not fitted to the path: they stand
# on the lawn beside it)
const PARK_LAKE := Rect2(460.0, -2950.0, 360.0, 470.0)
# flowerbeds on the lawns, hedged with box: each long edge is a grind rail
const PARK_BEDS: Array[Rect2] = [
	Rect2(200.0, -1400.0, 78.0, 500.0),
	Rect2(1002.0, -3850.0, 78.0, 500.0),
	Rect2(200.0, -4700.0, 78.0, 450.0),
]
const PARK_BANDSTAND := Vector2(1042.0, -1880.0)
const BANDSTAND_R := 58.0
const BANDSTAND_POSTS := 8
# the Ciutadella mammoth, life size, standing on the west lawn facing north
const PARK_MAMMOTH := Vector2(240.0, -3480.0)
const MAMMOTH_BODY := Vector2(58.0, 112.0)
const PARK_PLAYGROUND := Rect2(958.0, -4460.0, 166.0, 300.0)


static func bandstand_posts() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in range(BANDSTAND_POSTS):
		out.append(PARK_BANDSTAND + Vector2.from_angle(TAU * float(i) / float(BANDSTAND_POSTS) + PI / 8.0) * BANDSTAND_R)
	return out


# El Bosc: trunks along and in the trail, authored in the 300..980 space
# that fit_props_to_corridor maps onto the path at each y (300 = hard
# against the left edge). Closer together at the pinch (-2000), none on the
# footbridge.
const TRAIL_TREES: Array[Vector2] = [
	Vector2(300, -380), Vector2(980, -700), Vector2(300, -960),
	Vector2(600, -1150), Vector2(700, -1300), Vector2(600, -1450),
	Vector2(980, -1180), Vector2(300, -1640), Vector2(980, -1780),
	Vector2(300, -1880), Vector2(980, -1960), Vector2(300, -2060), Vector2(980, -2140),
	Vector2(300, -2760), Vector2(980, -2960), Vector2(640, -3360),
	Vector2(300, -3160), Vector2(980, -3560), Vector2(300, -3720),
	Vector2(980, -4060), Vector2(300, -4300), Vector2(560, -4460), Vector2(720, -4580),
	Vector2(980, -4760),
]
# the stream crosses the trail here, under a footbridge this many px either
# side of it
const TRAIL_STREAM_Y := -2450.0
const TRAIL_BRIDGE_HALF := 44.0
const TRAIL_STREAM_HALF := 32.0
# the wood is solid this far out from the trail's edge: a strip of forest
# floor to nose about in, then trunks and undergrowth you cannot walk into
const TRAIL_WOOD_OUT := 130.0
# the boar family crosses the trail here, west to east
const TRAIL_BOAR_Y := -3250.0
# fallen trunks lying out of the wood across part of the trail: [y, side].
# The owner steps over them (they are on LOW_LAYER, which only the dog
# collides with); the dog has to go round the end, and the rope wraps it.
const TRAIL_LOGS: Array = [[-2640.0, -1.0], [-3440.0, 1.0]]
const LOG_INTO := 110.0        # how far a trunk reaches onto the trail
const LOG_OUT := 70.0          # ...and back into the forest floor
const LOG_THICK := 20.0
const LOW_LAYER := 8           # collision bit for things the owner steps over


static func trail_logs(m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for spec: Array in TRAIL_LOGS:
		var y := float(spec[0])
		var e: Vector2 = m.walk_edges(y)
		var x0: float = (e.x - LOG_OUT) if float(spec[1]) < 0.0 else (e.y - LOG_INTO)
		out.append(Rect2(x0, y - LOG_THICK * 0.5, LOG_OUT + LOG_INTO, LOG_THICK))
	return out


# The stream as water either side of the footbridge: she can jump in off the
# bank and swim, and the owner stays on the boards.
static func trail_stream(m: Node2D) -> Array[Rect2]:
	var e: Vector2 = m.walk_edges(TRAIL_STREAM_Y)
	var y0 := TRAIL_STREAM_Y - TRAIL_STREAM_HALF
	var h := TRAIL_STREAM_HALF * 2.0
	return [Rect2(-400.0, y0, e.x - 12.0 + 400.0, h), Rect2(e.y + 12.0, y0, 1700.0 - e.y - 12.0, h)]


static func apply_corridor(m: Node2D) -> void:
	# ONE width dial per walk. This is what makes the levels stop feeling
	# like the same street redressed: a medieval alley that genuinely
	# pinches, a station concourse that genuinely opens out. It moves the
	# gameplay bounds and the pavement together, and narrow corridors are
	# mechanically harder - less room to thread a distracted owner past a
	# lamppost.
	var half := 340.0
	match m.lvl:
		"street": half = 340.0   # a proper boulevard
		"park": half = 230.0     # a gravel path between lawns
		"barri": half = 240.0    # the little park at the end of the street
		"beach": half = 340.0    # bespoke cross-section, left alone
		"rain": half = 230.0     # a narrow shopping street
		"market": half = 270.0   # stalls crowd the aisle
		"oldtown": half = 225.0  # the tightest: a medieval alley
		"trail": half = 200.0    # a single-file woodland trail
		"station": half = 390.0  # the widest: an open concourse
		"site": half = 295.0     # squeezed by the works
		"spook": half = 275.0
		"scrap": half = 250.0    # a lane between the wreck stacks
		"guell": half = 300.0   # terraces, wide enough to carve on
		# The narrowest walk, on purpose: the sweeper chase lives here (#20),
		# and a street sweeper only reads as a machine bearing down on you in a
		# street it fills. Its body is 276 wide and its brush head is the full
		# corridor, so there is no getting round it - only ahead of it.
		"neteja": half = 185.0
	m.walk_cx = 640.0
	m.walk_half = half
	m.sw_l = m.walk_cx - m.walk_half
	m.sw_r = m.walk_cx + m.walk_half
	# the cross-section either side (#65): [left kind, left width, right kind,
	# right width]. What the real place would have between the path and its
	# buildings - a lawn, a sidewalk, or the wall itself.
	var xs: Array = CROSS_SECTIONS.get(m.lvl, [])
	m.built = not xs.is_empty()
	if m.built:
		m.strip_kind_l = String(xs[0])
		m.strip_l = float(xs[1])
		m.strip_kind_r = String(xs[2])
		m.strip_r = float(xs[3])
	# The SHAPE of the corridor, on top of its width. Empty means a straight
	# pair of vertical lines at exactly sw_l/sw_r, which is what most levels
	# still are. See edge_path.gd; walk_edges(y) is what everything should ask.
	m.edge_nodes = []
	if m.lvl == "guell":
		# EL MOSAIC, walked uphill: the entrance forecourt between the
		# gatehouses, the dragon stair, the hypostyle hall, the plaza edged
		# by the serpentine bench (its edges wave, and the edges are the
		# grind line, so the whole bench can be ground), the viaduct, and the
		# calvary at the top
		var nodes: Array = [
			{"y": m.START_Y, "cx": 640.0, "half": 300.0},
			{"y": MOSAIC_STAIR_Y0 + 60.0, "cx": 640.0, "half": 300.0},
			{"y": MOSAIC_STAIR_Y0 - 60.0, "cx": 640.0, "half": 320.0},
			{"y": MOSAIC_HALL_Y0 + 80.0, "cx": 640.0, "half": 320.0},
			{"y": MOSAIC_HALL_Y0 - 40.0, "cx": 640.0, "half": 360.0},
			{"y": MOSAIC_PLAZA_Y0 + 80.0, "cx": 640.0, "half": 360.0},
		]
		var wy: float = MOSAIC_PLAZA_Y0
		var k := 0
		while wy > MOSAIC_PLAZA_Y1:
			nodes.append({"y": wy, "cx": 640.0, "half": 400.0 if k % 2 == 0 else 370.0})
			wy -= MOSAIC_BAY
			k += 1
		nodes.append({"y": MOSAIC_PLAZA_Y1, "cx": 640.0, "half": 400.0})
		nodes.append({"y": MOSAIC_VIADUCT_Y0, "cx": MOSAIC_VIADUCT_CX, "half": 280.0})
		nodes.append({"y": MOSAIC_VIADUCT_Y1, "cx": MOSAIC_VIADUCT_CX, "half": 280.0})
		nodes.append({"y": m.GATE_Y + 150.0, "cx": 640.0, "half": 300.0})
		nodes.append({"y": m.GATE_Y, "cx": 640.0, "half": 300.0})
		m.edge_nodes = nodes
	elif m.lvl == "oldtown":
		# EL GOTIC: narrow alleys that jink left and right round the old
		# blocks, opening once into the little plaça with its fountain
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 225.0},
			{"y": -400.0, "cx": 640.0, "half": 170.0},
			{"y": -800.0, "cx": 520.0, "half": 170.0},
			{"y": -1400.0, "cx": 520.0, "half": 170.0},
			{"y": -1850.0, "cx": 760.0, "half": 170.0},
			{"y": -2250.0, "cx": 760.0, "half": 170.0},
			{"y": -2650.0, "cx": 680.0, "half": 300.0},
			{"y": -2950.0, "cx": 680.0, "half": 300.0},
			{"y": -3400.0, "cx": 560.0, "half": 170.0},
			{"y": -3800.0, "cx": 560.0, "half": 170.0},
			{"y": -4250.0, "cx": 740.0, "half": 170.0},
			{"y": -4700.0, "cx": 640.0, "half": 225.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 225.0},
		]
	elif m.lvl == "spook":
		# LA CASTANYADA: an old-town street opening into the plaça where the
		# festival is, and narrowing again beyond it
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 250.0},
			{"y": CAST_PLACA.y + 750.0, "cx": 640.0, "half": 250.0},
			{"y": CAST_PLACA.y + 450.0, "cx": 640.0, "half": 440.0},
			{"y": CAST_PLACA.y - 450.0, "cx": 640.0, "half": 440.0},
			{"y": CAST_PLACA.y - 750.0, "cx": 640.0, "half": 250.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 250.0},
		]
	elif m.lvl == "market":
		# EL MERCAT: in off the street under the iron arch, out into the wide
		# hall, and out through the far door into the plaça
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 240.0},
			{"y": MERCAT_ARCH_Y + 180.0, "cx": 640.0, "half": 240.0},
			{"y": MERCAT_ARCH_Y - 120.0, "cx": 640.0, "half": MERCAT_HALL_HALF},
			{"y": MERCAT_DOOR_Y + 160.0, "cx": 640.0, "half": MERCAT_HALL_HALF},
			{"y": MERCAT_DOOR_Y - 160.0, "cx": 640.0, "half": 240.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 240.0},
		]
	elif m.lvl == "scrap":
		# LA FERRALLA: the lane between the wreck stacks shifts one way and
		# the other as the stacks were dumped
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 250.0},
			{"y": -700.0, "cx": 640.0, "half": 250.0},
			{"y": -1400.0, "cx": 570.0, "half": 240.0},
			{"y": -2300.0, "cx": 710.0, "half": 250.0},
			{"y": -3200.0, "cx": 570.0, "half": 240.0},
			{"y": -4100.0, "cx": 700.0, "half": 250.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 250.0},
		]
	elif m.lvl == "station":
		# L'ESTACIO: in off the street through the doors, out into the wide
		# concourse, through the ticket barriers, and down the platforms
		# either side of the train
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 220.0},
			{"y": -650.0, "cx": 640.0, "half": 220.0},
			{"y": -950.0, "cx": 640.0, "half": 420.0},
			{"y": -2900.0, "cx": 640.0, "half": 420.0},
			{"y": -3150.0, "cx": 640.0, "half": 380.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 380.0},
		]
	elif m.lvl == "site":
		# LES OBRES: the footway diverted round the works, a chicane that
		# swings one way past the first pour and back past the second
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 295.0},
			{"y": -1200.0, "cx": 640.0, "half": 295.0},
			{"y": -1700.0, "cx": 590.0, "half": 295.0},
			{"y": -2600.0, "cx": 690.0, "half": 280.0},
			{"y": -3300.0, "cx": 600.0, "half": 295.0},
			{"y": -3900.0, "cx": 640.0, "half": 295.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 295.0},
		]
	elif m.lvl == "street" and not m.tutorial_mode:
		# LA RAMBLA: dead straight, as the real one is, opening out at the
		# square halfway down where the round pavement mosaic is set
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 340.0},
			{"y": RAMBLA_MOSAIC.y + 260.0, "cx": 640.0, "half": 340.0},
			{"y": RAMBLA_MOSAIC.y + 120.0, "cx": 640.0, "half": 400.0},
			{"y": RAMBLA_MOSAIC.y - 120.0, "cx": 640.0, "half": 400.0},
			{"y": RAMBLA_MOSAIC.y - 260.0, "cx": 640.0, "half": 340.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 340.0},
		]
	elif m.lvl == "park":
		# EL PARC OPENS OUT ROUND THE LAKE: the path widens either side of it
		# and the lake sits in the middle as an island (PARK_LAKE), so there is
		# a west shore and an east shore to walk. The owner keeps to the east
		# (main.islands); the dog can take either, which is the game.
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 230.0},
			{"y": -2100.0, "cx": 640.0, "half": 230.0},
			{"y": -2400.0, "cx": 640.0, "half": 400.0},
			{"y": -3030.0, "cx": 640.0, "half": 400.0},
			{"y": -3330.0, "cx": 640.0, "half": 230.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 230.0},
		]
	elif m.lvl == "trail":
		# EL BOSC BENDS - the first walk in the game that is not a straight
		# line. A woodland trail has no business being ruler-drawn: it wanders
		# either side of the centre and pinches where the trees close in, which
		# makes the single-file stretch an actual place rather than a number.
		#
		# It went first because it has no building frontage and no wall
		# blockers, so the bend has only the pavement, the props and the mud to
		# agree with - and all three read walk_edges now, the mud as a band
		# (see band_x) rather than as a rectangle that would hang off the
		# outside of every curve. Both ends sit dead centre at the level's
		# nominal width so the start line and the gate still line up.
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 200.0},
			{"y": -900.0, "cx": 566.0, "half": 200.0},
			{"y": -2000.0, "cx": 716.0, "half": 150.0},   # the pinch
			{"y": -3100.0, "cx": 578.0, "half": 196.0},
			{"y": -4200.0, "cx": 668.0, "half": 200.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 200.0},
		]


static func fit_x(m: Node2D, x: float, lo: float, hi: float) -> float:
	var f := clampf((x - 300.0) / 680.0, 0.0, 1.0)
	return lerpf(lo, hi, f)


static func fit_props_to_corridor(m: Node2D) -> void:
	# El Gotic, El Mercat, La Castanyada and El Mosaic place everything in
	# level space
	if m.lvl == "oldtown" or m.lvl == "market" or m.lvl == "spook" or m.lvl == "guell":
		return
	# Props were all authored for the old fixed 300..980 corridor, so a
	# narrower walk would leave them stranded out on the verge. Pull every
	# placed prop back inside whatever corridor this level declared, keeping
	# its side of the path. The beach is exempt: its sand/boardwalk/bike-path
	# cross-section deliberately places things outside the walkway.
	if m.lvl == "beach":
		return
	# Fitted at each prop's OWN y, so a bend in the path carries its lampposts
	# and bins around with it. Against the straight sw_l/sw_r a curved street
	# would leave a trail of furniture standing out on the grass where the path
	# used to be.
	var pad := 26.0
	for arr in [m.poles, m.tables, m.chairs, m.parasols, m.astands, m.vans, m.stalls, m.bins,
			m.benches, m.performers, m.cone_spots, m.manholes, m.wallcat_spots,
			m.guard_posts, m.candy_spots, m.fountains, m.statues]:
		# Les Obres sets its cones round its pours, and L'Estacio its pillars
		# and barriers, in level space already
		if m.lvl == "site" and arr == m.cone_spots:
			continue
		if m.lvl == "station" and arr == m.poles:
			continue
		for i in range(arr.size()):
			var p: Vector2 = arr[i]
			var e = m.walk_edges(p.y)
			# remap proportionally so left-side props stay left, right stay right
			arr[i] = Vector2(fit_x(m, p.x, e.x + pad, e.y - pad), p.y)
	# the dictionary-based pickups need the same treatment
	for list in [m.hydrants, m.kebabs, m.candy]:
		for d in list:
			if bool(d.get("off_path", false)):
				continue
			var dp: Vector2 = d.pos
			var de = m.walk_edges(dp.y)
			d.pos = Vector2(fit_x(m, dp.x, de.x + pad, de.y - pad), dp.y)
	# FUR-GONETA is authored against sw_l/sw_r already, so it is not remapped
	# here. Its rope flanks are appended after this fit from that same centre.


static func build_level_data(m: Node2D) -> void:
	apply_corridor(m)
	var hyd_list: Array[Vector2] = []
	var keb_list: Array[Vector2] = []
	# a couple of walks reuse a proven layout as a base for now (bespoke
	# geometry is a later pass) and re-theme it below: El Aguacero on the
	# boulevard, El Gotic on the stall-lined market channel.
	var geo = m.lvl
	if m.lvl == "spook" or m.lvl == "neteja":
		geo = "market"
	elif m.lvl == "guell":
		geo = "park"
	match geo:
		"street":
			m.lane_ys = Array([-1200.0, -2600.0, -4000.0], TYPE_FLOAT, &"", null)
			m.gate_text = "PARK"
			for i in range(7):
				var x = m.sw_l + 30.0 if i % 2 == 0 else m.sw_r - 30.0
				var y := -350.0 - i * 640.0
				var near_lane := false
				for ly in m.lane_ys:
					if absf(y - ly) < m.LANE_HALF + 60.0:
						near_lane = true
				if not near_lane:
					m.poles.append(Vector2(x, y))
			for mp in [Vector2(640, -1750), Vector2(700, -2900), Vector2(580, -4250)]:
				m.poles.append(mp)
			# a slalom line of street trees mid-walkway (in grates)
			for sl in [Vector2(590, -1880), Vector2(710, -2010), Vector2(590, -2140), Vector2(710, -2270)]:
				m.poles.append(sl)
			m.deco_pole_count = m.poles.size()
			# cafe terrace: tables join the poles array so they block
			# bodies and snag the leash, but they are drawn as tables.
			# Chairs and umbrellas make it properly hard to thread a dog
			# through, as in life.
			# cafe terrace: keep wrap/body centres >= FURNITURE_MIN_SEP so
			# chair and parasol colliders cannot nest under tension
			m.tables = Array([Vector2(760, -3560), Vector2(840, -3660), Vector2(700, -3700), Vector2(790, -3780)], TYPE_VECTOR2, &"", null)
			m.chairs = Array([
				Vector2(725, -3535), Vector2(830, -3570), Vector2(872, -3690),
				Vector2(700, -3775), Vector2(670, -3672), Vector2(815, -3820),
			], TYPE_VECTOR2, &"", null)
			m.parasols = Array([Vector2(800, -3610), Vector2(745, -3740)], TYPE_VECTOR2, &"", null)
			# off the crossing lanes, by the shopfronts where they belong
			m.astands = Array([Vector2(365, -1600), Vector2(915, -2850), Vector2(372, -4330)], TYPE_VECTOR2, &"", null)
			# a delivery van parked half on the walkway, as they do
			m.vans = Array([Vector2(890, -3050)], TYPE_VECTOR2, &"", null)
			m.performers = Array([Vector2(400, -1550)], TYPE_VECTOR2, &"", null)
			m.cone_spots = Array([Vector2(858, -2975), Vector2(920, -3130)], TYPE_VECTOR2, &"", null)
			m.manholes = Array([
				Vector2(560, -700), Vector2(760, -950), Vector2(480, -1700),
				Vector2(700, -2100), Vector2(600, -3100), Vector2(820, -3450),
				Vector2(520, -4400),
			], TYPE_VECTOR2, &"", null)
			m.cellars = Array([
				Rect2(m.sw_l, -2750, 62, 88), Rect2(m.sw_r - 62, -750, 62, 82),
				Rect2(m.sw_l, -4550, 62, 88),
			], TYPE_RECT2, &"", null)
			m.bins = Array([
				Vector2(m.sw_l + 30, -600), Vector2(m.sw_r - 30, -1400),
				Vector2(m.sw_l + 30, -2150), Vector2(m.sw_r - 30, -3000),
				Vector2(m.sw_l + 30, -3700), Vector2(m.sw_r - 30, -4700),
			], TYPE_VECTOR2, &"", null)
			m.benches = Array([Vector2(336, -1300), Vector2(944, -2450), Vector2(336, -3850)], TYPE_VECTOR2, &"", null)
			hyd_list = [
				Vector2(m.sw_l + 45, -500), Vector2(m.sw_r - 45, -1500),
				Vector2(m.sw_l + 45, -2300), Vector2(m.sw_r - 45, -3300),
				Vector2(m.sw_l + 45, -4600),
				Vector2(m.SHOULDER_R - 12, -1000), Vector2(m.SHOULDER_R - 12, -3600),
			]
			keb_list = [Vector2(640, -1960), Vector2(700, -4200), Vector2(m.SHOULDER_R - 12, -2400)]
		"park":
			m.gate_text = "HOME"
			# El Parc's lake stands in the middle of its widened path; El Mosaic
			# still builds on the old pond's footprint (and then drops it)
			m.pond = PARK_LAKE if m.lvl == "park" else Rect2(m.sw_l, -2950, 360, 470)
			m.duck_ys = Array([randf_range(-2200.0, -1400.0), randf_range(-4300.0, -3400.0)], TYPE_FLOAT, &"", null)
			for i in range(7):
				var x = m.sw_l + 30.0 if i % 2 == 0 else m.sw_r - 30.0
				var y := -350.0 - i * 640.0
				if not m.pond.grow(40.0).has_point(Vector2(x, y)):
					m.poles.append(Vector2(x, y))
			for mp in [Vector2(640, -1750), Vector2(700, -2900), Vector2(580, -4250)]:
				if not m.pond.grow(40.0).has_point(mp):
					m.poles.append(mp)
			# a tree slalom on the path, and repair cones by the bridge
			for sl in [Vector2(570, -1150), Vector2(690, -1280), Vector2(570, -1410), Vector2(690, -1540)]:
				m.poles.append(sl)
			m.deco_pole_count = m.poles.size()
			m.astands = Array([Vector2(350, -2050)], TYPE_VECTOR2, &"", null)
			m.cone_spots = Array([Vector2(720, -2500), Vector2(700, -2960)], TYPE_VECTOR2, &"", null)
			m.bins = Array([
				Vector2(m.sw_l + 30, -600), Vector2(m.sw_r - 30, -1400),
				Vector2(m.sw_l + 30, -2150), Vector2(m.sw_r - 30, -3000),
				Vector2(m.sw_l + 30, -3700), Vector2(m.sw_r - 30, -4700),
			], TYPE_VECTOR2, &"", null)
			m.benches = Array([Vector2(336, -1300), Vector2(944, -2450), Vector2(336, -3850), Vector2(944, -1900)], TYPE_VECTOR2, &"", null)
			hyd_list = [
				Vector2(m.sw_l + 45, -500), Vector2(m.sw_r - 45, -1500),
				Vector2(m.sw_l + 45, -2300), Vector2(m.sw_r - 45, -3300),
				Vector2(m.sw_l + 45, -4600),
			]
			keb_list = [Vector2(620, -1900), Vector2(700, -4200)]
		"trail":
			# EL BOSC, its own wood rather than the park with a bent path. No
			# pond, no lampposts, no park benches: trunks crowding both edges,
			# closer together where the trail pinches, a few standing in it,
			# and the stream crossing under a footbridge (build_freedom_area).
			m.gate_text = "CLEARING"
			for tp: Vector2 in TRAIL_TREES:
				m.poles.append(tp)
			m.deco_pole_count = m.poles.size()
			# the footbridge's four posts: the rope wraps them like any post
			var bl: float = TRAIL_STREAM_Y + TRAIL_BRIDGE_HALF
			var bt: float = TRAIL_STREAM_Y - TRAIL_BRIDGE_HALF
			for bp: Vector2 in [Vector2(300.0, bl), Vector2(980.0, bl), Vector2(300.0, bt), Vector2(980.0, bt)]:
				m.poles.append(bp)
			# litter someone left: a bottle and a can (spawn_cones)
			m.cone_spots = Array([Vector2(720, -1320), Vector2(420, -3480)], TYPE_VECTOR2, &"", null)
			# a bin at the trailhead and one at the viewpoint, and nowhere else
			m.bins = Array([Vector2(m.sw_l + 30, -560), Vector2(m.sw_r - 30, -3760)], TYPE_VECTOR2, &"", null)
			m.benches = Array([Vector2(944, -3880)], TYPE_VECTOR2, &"", null)
			# waymarker posts (red and white bands), where hydrants stand in town
			hyd_list = [
				Vector2(m.sw_l + 45, -500), Vector2(m.sw_r - 45, -1580),
				Vector2(m.sw_l + 45, -2780), Vector2(m.sw_r - 45, -3300),
				Vector2(m.sw_l + 45, -4600),
			]
			# someone's bocadillo, dropped in its foil
			keb_list = [Vector2(620, -1900), Vector2(700, -4200)]
		"oldtown":
			# flowerpots at the doors: geraniums in terracotta
			hyd_list = [gotic_wall(m, -600.0, false, 16.0), gotic_wall(m, -1600.0, true, 16.0),
				gotic_wall(m, -2150.0, false, 16.0), gotic_wall(m, -3550.0, true, 16.0),
				gotic_wall(m, -4450.0, false, 16.0)]
			keb_list = [gotic_wall(m, -1250.0, true, 70.0), gotic_wall(m, -3900.0, false, 70.0)]
		"scrap":
			# tyre stacks where a street has hydrants: what gets marked here
			hyd_list = [
				Vector2(m.sw_l + 40, -500), Vector2(m.sw_r - 40, -1200),
				Vector2(m.sw_l + 40, -2000), Vector2(m.sw_r - 40, -3400),
				Vector2(m.sw_l + 40, -4600),
			]
			keb_list = [Vector2(620, -1700), Vector2(700, -3700)]
		"station":
			# planters where a street has hydrants: the station's potted palms
			hyd_list = [
				Vector2(m.sw_l + 40, -400), Vector2(m.sw_r - 40, -1300),
				Vector2(m.sw_l + 40, -2100), Vector2(m.sw_r - 40, -2600),
				Vector2(m.sw_l + 40, -4500),
			]
			keb_list = [Vector2(460, -1650), Vector2(820, -3900)]
		"rain":
			hyd_list = [
				Vector2(m.sw_l + 110, -500), Vector2(m.sw_r - 40, -1300),
				Vector2(m.sw_r - 40, -2300), Vector2(m.sw_l + 110, -3500),
				Vector2(m.sw_r - 40, -4400),
			]
			keb_list = [Vector2(760, -1800), Vector2(700, -3900)]
		"barri":
			# EL BARRI: the neighbourhood park. Plane trees in rows down both
			# edges of a gravel square, benches facing each other, a
			# ping-pong table, the petanca pitch, a playground, a fountain.
			m.gate_text = "PIPICA"
			var y := -320.0
			var k := 0
			while y > m.GATE_Y + 260.0:
				for x: float in [300.0, 980.0]:
					var tp := Vector2(x, y + (40.0 if (k + int(x)) % 2 == 0 else 0.0))
					if not BARRI_PETANCA.grow(70.0).has_point(tp) and not BARRI_PLAYGROUND.grow(70.0).has_point(tp):
						m.poles.append(tp)
				y -= 380.0
				k += 1
			m.deco_pole_count = m.poles.size()
			m.benches = Array([Vector2(336, -900), Vector2(944, -900), Vector2(336, -2600),
				Vector2(944, -3400), Vector2(336, -4300)], TYPE_VECTOR2, &"", null)
			m.bins = Array([Vector2(m.sw_l + 30, -700), Vector2(m.sw_r - 30, -2200),
				Vector2(m.sw_l + 30, -3700)], TYPE_VECTOR2, &"", null)
			m.stalls = Array([BARRI_PINGPONG], TYPE_VECTOR2, &"", null)
			m.stall_kinds = Array(["pingpong"], TYPE_STRING, &"", null)
			# the petanca players, stood round the pitch
			var pc: Vector2 = BARRI_PETANCA.get_center()
			m.performers = Array([pc + Vector2(-70, -40), pc + Vector2(-66, 50), pc + Vector2(70, 10)], TYPE_VECTOR2, &"", null)
			m.fountains = Array([Vector2(640, -2950)], TYPE_VECTOR2, &"", null)
			hyd_list = [
				Vector2(m.sw_l + 45, -500), Vector2(m.sw_r - 45, -1500),
				Vector2(m.sw_l + 45, -2300), Vector2(m.sw_r - 45, -3100),
				Vector2(m.sw_l + 45, -4600),
			]
			keb_list = [Vector2(600, -1300), Vector2(700, -4000)]
			# the playground's sandpit is sand
			m.patches.append({"y": BARRI_PLAYGROUND.get_center().y + 40.0, "at": 0.0, "rx": 44.0, "ry": 34.0,
				"seed": 3.1, "kind": "sand", "pin": BARRI_PLAYGROUND.get_center() + Vector2(-28.0, 40.0)})
		"site":
			# hydrants at the kerbs, clear of the works; the lads' dropped lunch
			hyd_list = [
				Vector2(m.sw_l + 45, -500), Vector2(m.sw_r - 45, -1500),
				Vector2(m.sw_l + 45, -2500), Vector2(m.sw_r - 45, -3700),
				Vector2(m.sw_l + 45, -4600),
			]
			keb_list = [Vector2(700, -2000), Vector2(560, -3900)]
		"beach":
			# Passeig Maritim: sea | sand | boardwalk | bike path |
			# pavement | palms and cafe terraces. The human walks the
			# pavement; the dog walks wherever a dog walks.
			m.gate_text = "HOME"
			m.walk_cx = 770.0
			m.walk_half = 210.0
			m.gate_l = 560.0
			m.gate_r = 980.0
			m.tut_l = 110.0
			m.tut_r = 1160.0
			# SAND ON THE PAVING. The most characteristic thing about a seafront
			# walk, and the beach had a ruler-straight sand edge with nothing
			# crossing it. Wind and feet carry it inland in tongues that thin
			# out the further they get from the beach, so these run from the
			# sand side and reach in - never across, because a promenade you
			# cannot get a clean line down is a chore rather than a walk.
			#
			# They are real SAND underfoot (surfaces.gd): heavy going, poor
			# grip, and they mark her paws, which feeds the existing substance
			# chain for free. Weaving to keep off them is the whole point.
			m.patches = Array([
				{"y": -620.0, "at": 0.02, "rx": 104.0, "ry": 58.0, "seed": 1.7, "kind": "sand"},
				{"y": -1340.0, "at": 0.10, "rx": 86.0, "ry": 48.0, "seed": 3.4, "kind": "sand"},
				{"y": -2180.0, "at": 0.04, "rx": 118.0, "ry": 64.0, "seed": 5.1, "kind": "sand"},
				{"y": -2960.0, "at": 0.14, "rx": 78.0, "ry": 44.0, "seed": 0.9, "kind": "sand"},
				{"y": -3720.0, "at": 0.06, "rx": 110.0, "ry": 60.0, "seed": 2.6, "kind": "sand"},
				{"y": -4380.0, "at": 0.12, "rx": 92.0, "ry": 52.0, "seed": 4.3, "kind": "sand"},
			], TYPE_DICTIONARY, &"", null)
			# PALMS IN ORDERLY SECTIONS, cut into the paving - exactly how the
			# promenade is planted, and nothing like the six-per-row scattering
			# this had. Two regular ranks at a proper street-tree spacing, kept
			# at the edges of the walk because that is where street trees go and
			# because a rank down the middle would choke a 420px corridor.
			#
			# Kept in their own list as well as in poles, so the paving cut-outs
			# and the benches between them are placed from the same numbers
			# rather than from a second copy that could drift.
			m.palm_spots.clear()
			for i in range(17):
				m.palm_spots.append(Vector2(462.0, -260.0 - i * 300.0))
			for i in range(15):
				m.palm_spots.append(Vector2(1012.0, -380.0 - i * 340.0))
			for ps: Vector2 in m.palm_spots:
				m.poles.append(ps)
			# long benches facing the sea, set between the seaward palms on the
			# concrete - the promenade is lined with them
			for i in range(16):
				m.benches.append(Vector2(524.0, -410.0 - i * 300.0))
			m.deco_pole_count = m.poles.size()
			# terrace tables under canopies, twice along the route
			m.tables = Array([
				Vector2(1040, -1500), Vector2(1110, -1560), Vector2(1050, -1620), Vector2(1120, -1680),
				Vector2(1040, -3300), Vector2(1110, -3360), Vector2(1050, -3420), Vector2(1120, -3480),
			], TYPE_VECTOR2, &"", null)
			m.canopies = Array([Rect2(1015, -1710, 135, 240), Rect2(1015, -3510, 135, 240)], TYPE_RECT2, &"", null)
			m.chairs = Array([
				Vector2(1075, -1470), Vector2(1020, -1560), Vector2(1090, -1640),
				Vector2(1075, -3270), Vector2(1020, -3360), Vector2(1090, -3440),
			], TYPE_VECTOR2, &"", null)
			m.astands = Array([Vector2(600, -1450), Vector2(966, -3250)], TYPE_VECTOR2, &"", null)
			m.vans = Array([Vector2(930, -4050)], TYPE_VECTOR2, &"", null)
			m.performers = Array([Vector2(410, -2200)], TYPE_VECTOR2, &"", null)
			m.cone_spots = Array([Vector2(492, -1500), Vector2(548, -3050)], TYPE_VECTOR2, &"", null)
			# parasols are poles too: windable, markable, brilliant
			m.parasols = Array([Vector2(268, -900), Vector2(300, -2300), Vector2(262, -3700), Vector2(330, -4500)], TYPE_VECTOR2, &"", null)
			var towel_cols := [Color(0.85, 0.4, 0.35), Color(0.35, 0.55, 0.8), Color(0.9, 0.75, 0.3), Color(0.5, 0.7, 0.5)]
			var ty := -800.0
			for i in range(5):
				m.towels.append({
					"rect": Rect2(randf_range(248.0, 330.0), ty, 46, 80),
					"col": towel_cols[i % 4], "bather": i % 2 == 0, "cd": 0.0,
				})
				ty -= randf_range(700.0, 1000.0)
			m.bins = Array([
				Vector2(590, -700), Vector2(950, -1600), Vector2(590, -2500),
				Vector2(950, -3400), Vector2(590, -4300),
			], TYPE_VECTOR2, &"", null)
			m.benches = Array([Vector2(410, -1200), Vector2(410, -2800), Vector2(410, -4200)], TYPE_VECTOR2, &"", null)
			hyd_list = [
				Vector2(578, -1000), Vector2(950, -2200), Vector2(578, -3200), Vector2(950, -4500),
			]
			keb_list = [Vector2(700, -1900), Vector2(860, -4200), Vector2(420, -3000)]
			m.fountains = Array([Vector2(420, -1300), Vector2(1005, -3550)], TYPE_VECTOR2, &"", null)
		"market":
			# El Mercat: stalls line both edges, produce underfoot, the
			# cat is practically guaranteed (fish)
			m.gate_text = "PLAZA"
			m.stalls = Array([
				Vector2(370, -800), Vector2(910, -1150), Vector2(370, -1750),
				Vector2(910, -2300), Vector2(370, -2900), Vector2(910, -3500),
				Vector2(370, -4150), Vector2(910, -4650),
			], TYPE_VECTOR2, &"", null)
			for i in range(7):
				var x = m.sw_l + 30.0 if i % 2 == 0 else m.sw_r - 30.0
				var lp := Vector2(x, -350.0 - i * 640.0)
				var clear := true
				for st in m.stalls:
					if absf(st.x - lp.x) < 75.0 and absf(st.y - lp.y) < 65.0:
						clear = false
				if clear:
					m.poles.append(lp)
			m.deco_pole_count = m.poles.size()
			m.manholes = Array([Vector2(640, -2050), Vector2(560, -3800)], TYPE_VECTOR2, &"", null)
			m.bins = Array([
				Vector2(330, -1400), Vector2(950, -2700),
				Vector2(330, -3300), Vector2(950, -4400),
			], TYPE_VECTOR2, &"", null)
			m.benches = Array([Vector2(336, -2450), Vector2(944, -3850)], TYPE_VECTOR2, &"", null)
			m.astands = Array([
				Vector2(440, -880), Vector2(840, -1230), Vector2(440, -2980), Vector2(840, -3580),
			], TYPE_VECTOR2, &"", null)
			m.performers = Array([Vector2(640, -2600), Vector2(400, -4400)], TYPE_VECTOR2, &"", null)
			m.cone_spots = Array([Vector2(600, -1990), Vector2(690, -2110)], TYPE_VECTOR2, &"", null)
			m.fountains = Array([Vector2(640, -3100)], TYPE_VECTOR2, &"", null)
			# 5, not 3: the "4 good sniffs" goal on this layout (and on El
			# Gotic / La Castanyada, which inherit it) was impossible to
			# complete with only three hydrants. Caught by --selftest.
			hyd_list = [
				Vector2(345, -600), Vector2(935, -1900), Vector2(345, -3600),
				Vector2(935, -2900), Vector2(345, -4400),
			]
			keb_list = [
				Vector2(500, -900), Vector2(780, -1250), Vector2(620, -1800),
				Vector2(540, -2380), Vector2(760, -3000), Vector2(600, -3650),
				Vector2(820, -4250), Vector2(480, -4550),
			]
	if m.lvl == "street":
		m.fountains = Array([Vector2(335, -3350)], TYPE_VECTOR2, &"", null)
		if not m.tutorial_mode:
			rambla(m, hyd_list)
	elif m.lvl == "park":
		# the drinking fountain on the north shore, and one by the bandstand
		m.fountains = Array([Vector2(640, -2390), Vector2(944, -1650)], TYPE_VECTOR2, &"", null)
		# no street A-board in a park
		m.astands = Array([], TYPE_VECTOR2, &"", null)
		# litter, well away from the lake (spawn_cones)
		m.cone_spots = Array([Vector2(560, -1700), Vector2(720, -4000)], TYPE_VECTOR2, &"", null)
		m.islands = Array([{"rect": PARK_LAKE, "side": 1.0}], TYPE_DICTIONARY, &"", null)
		# the playground's sandpit is real sand: slow, and it takes prints
		m.patches.append({"y": PARK_PLAYGROUND.get_center().y + 40.0, "at": 0.0, "rx": 44.0, "ry": 34.0,
			"seed": 1.3, "kind": "sand", "pin": PARK_PLAYGROUND.get_center() + Vector2(-28.0, 40.0)})
	elif m.lvl == "rain":
		diluvi(m)
	elif m.lvl == "oldtown":
		gotic(m)
	elif m.lvl == "market":
		mercat(m, hyd_list, keb_list)
	elif m.lvl == "trail":
		# El Bosc: a forest trail. No bars out here, so the owner is forever
		# stopping to hunt for a signal (see human.gd); muddy patches slow
		# the going, and a stream to drink from. Calm, stop-start rhythm.
		m.signal_prone = true
		# each patch spans the trail where the trail actually IS. A Rect2 cannot
		# bend, so it is measured at the middle of its own band - close enough
		# for a puddle, and far better than three rectangles pinned to where a
		# straight path used to be
		# PUDDLES, not a band across the whole trail. A full-width strip is a
		# wall you have to cross; puddles are things you weave between, which
		# is both more interesting to walk and more like a wood after rain.
		# Placed in pairs so a stretch reads as boggy rather than as one
		# tidy pool, and offset across the path so a careful line gets through.
		m.patches = Array([
			{"y": -1520.0, "at": 0.28, "rx": 84.0, "ry": 46.0, "seed": 1.10, "kind": "mud"},
			{"y": -1660.0, "at": 0.66, "rx": 70.0, "ry": 40.0, "seed": 2.40, "kind": "mud"},
			{"y": -2860.0, "at": 0.72, "rx": 92.0, "ry": 52.0, "seed": 3.75, "kind": "mud"},
			{"y": -3010.0, "at": 0.34, "rx": 66.0, "ry": 38.0, "seed": 5.02, "kind": "mud"},
			{"y": -4080.0, "at": 0.46, "rx": 100.0, "ry": 54.0, "seed": 0.62, "kind": "mud"},
			{"y": -4220.0, "at": 0.82, "rx": 58.0, "ry": 34.0, "seed": 4.18, "kind": "mud"},
			# churned up where feet come off the footbridge
			{"y": TRAIL_STREAM_Y + 104.0, "at": 0.52, "rx": 96.0, "ry": 40.0, "seed": 2.90, "kind": "mud"},
			{"y": TRAIL_STREAM_Y - 100.0, "at": 0.40, "rx": 74.0, "ry": 34.0, "seed": 3.30, "kind": "mud"},
		], TYPE_DICTIONARY, &"", null)
		# the drink is the stream: stand at the bank beside the bridge
		m.fountains = Array([
			Vector2(300.0, TRAIL_STREAM_Y + TRAIL_BRIDGE_HALF + 34.0),
			Vector2(980.0, TRAIL_STREAM_Y - TRAIL_BRIDGE_HALF - 34.0),
		], TYPE_VECTOR2, &"", null)
	elif m.lvl == "station":
		estacio(m)
	elif m.lvl == "spook":
		castanyada(m, hyd_list, keb_list)
	elif m.lvl == "site":
		obres(m)
	elif m.lvl == "neteja":
		neteja(m)
	elif m.lvl == "guell":
		mosaic(m, hyd_list, keb_list)
	elif m.lvl == "scrap":
		ferralla(m)
	if m.tutorial_mode:
		# Take away everything that can hurt, keep everything worth learning.
		# This has to run BEFORE the shared setup below consumes hyd_list /
		# keb_list and builds lane_state from lane_ys - doing it later left a
		# populated lane_state indexing an emptied lane_ys, which is exactly
		# the out-of-bounds it produced.
		m.lane_ys = Array([], TYPE_FLOAT, &"", null)
		m.lane_state = []
		m.manholes = Array([], TYPE_VECTOR2, &"", null)
		m.cellars = Array([], TYPE_RECT2, &"", null)
		m.vans = Array([], TYPE_VECTOR2, &"", null)
		m.astands = Array([], TYPE_VECTOR2, &"", null)
		m.performers = Array([], TYPE_VECTOR2, &"", null)
		# THE STATIONS: El Barri emptied out, and each lesson given only what
		# it needs (systems/tutorial.gd has the order and the spacing)
		m.stalls.clear()
		m.stall_kinds.clear()
		m.benches.clear()
		m.patches.clear()
		m.poles.clear()
		m.poles.append(Vector2(640.0, TUT.at("vault")))
		m.poles.append(Vector2(640.0, TUT.at("fling")))
		m.deco_pole_count = m.poles.size()
		hyd_list = [Vector2(560.0, TUT.at("pee") - 40.0), Vector2(720.0, TUT.at("sniff") - 40.0)]
		keb_list = []
		m.bins = Array([Vector2(m.sw_r - 30.0, TUT.at("bag") - 60.0)], TYPE_VECTOR2, &"", null)
		m.fountains = Array([], TYPE_VECTOR2, &"", null)
	for tb in m.tables:
		m.poles.append(tb)
	for pa in m.parasols:
		m.poles.append(pa)
	for ch in m.chairs:
		m.poles.append(ch)
	# trash bins: bag deposit targets for the owner's chore chain; they
	# also join the poles array, so they block bodies, snag the leash,
	# and can absolutely be marked
	for bn in m.bins:
		m.poles.append(bn)
	# everything past body_pole_count is rope-wrap geometry only: vans
	# and stalls get one solid rectangular body each in _build_walls
	m.body_pole_count = m.poles.size()
	for v in m.vans:
		for off in [-52.0, -26.0, 0.0, 26.0, 52.0]:
			m.poles.append(v + Vector2(0, off))
	# stall wrap circles at the ENDS only: a mid circle made the rope
	# snake weirdly across the tabletop
	for st in m.stalls:
		m.poles.append(st + Vector2(-48, 0))
		m.poles.append(st + Vector2(48, 0))
	m.urge_y = randf_range(-3200.0, -1500.0)
	# rare visitors: a cat some walks, a pigeon flock or two most walks
	# (seagulls at the beach, obviously)
	var cat_p := 0.3
	if m.lvl == "park":
		cat_p = 0.4
	elif m.lvl == "market":
		cat_p = 0.75
	if randf() < cat_p:
		m.cat_y = randf_range(-4200.0, -1200.0)
	m.flock_ys = Array([randf_range(-1800.0, -800.0), randf_range(-4400.0, -2600.0)], TYPE_FLOAT, &"", null)
	if m.lvl != "street":
		m.flock_ys.insert(1, randf_range(-2600.0, -1900.0))
	for hp in hyd_list:
		if m.pond.size.x > 0.0 and m.pond.grow(30.0).has_point(hp):
			continue
		m.hydrants.append({"pos": hp, "done": false, "progress": 0.0})
	for kp in keb_list:
		m.kebabs.append({"pos": kp, "eaten": false})
	if m.tutorial_mode:
		# the nose lesson's snack is out on the grass, off the path, so it is
		# found by smell; the flock waits at the bark station; the urge comes
		# at the business station, and never before it
		var ne: Vector2 = m.walk_edges(TUT.at("nose"))
		m.kebabs.append({"pos": Vector2(ne.x - 110.0, TUT.at("nose") - 80.0), "eaten": false, "off_path": true})
		m.flock_ys = Array([TUT.at("bark") - 60.0], TYPE_FLOAT, &"", null)
		m.duck_ys = Array([], TYPE_FLOAT, &"", null)
		m.cat_y = 0.0
		m.urge_y = TUT.at("bag") + 40.0
	for cp in m.candy_spots:
		m.candy.append({"pos": cp, "eaten": false})
	build_ground_detail(m)
	build_freedom_area(m)
	lift_props_out_of_water(m)
	# The messes that were painted as translucent rectangles (paint, fish,
	# oil, confetti, El Bosc's big mud) are patches like the rest: an organic
	# shape across the path where it is, not a box with an outline.
	var mw: float = m.walk_half * 2.0
	match m.lvl:
		"trail":
			m.patches.append({"y": -3575.0, "at": 0.28, "rx": mw * 0.20, "ry": 62.0, "seed": 5.55, "kind": "mud"})
	# after the water and the holes are known, so a puddle cannot end up in
	# the pond and cement cannot be poured over a manhole
	settle_patches(m)
	build_dunes(m)
	build_park_props(m)
	for i in range(140):
		var side := -1.0 if randf() < 0.5 else 1.0
		var x := 640.0 + side * randf_range(340.0, 620.0)
		m.tufts.append(Vector2(x, randf_range(m.GATE_Y - 600.0, m.START_Y + 150.0)))
	# The grove in the off-leash space. Fourteen is right for a park; a beach
	# with fourteen palms in it is a plantation, and the woods want more than a
	# park does. These are rope-wrap geometry as well as scenery, so the count
	# changes what the space plays like, not just what it looks like.
	# The clearing is ringed with woodland. Placed here rather than drawn as
	# scenery so it is solid, wraps the rope, and reads as the edge of a wood
	# you cannot simply walk out of.
	if m.freedom_kind == "clearing":
		var fr = m._freedom_rect()
		for i in range(14):
			var f := float(i) / 13.0
			var edge := i % 3
			var tp := Vector2.ZERO
			match edge:
				0: tp = Vector2(lerpf(fr.position.x + 40.0, fr.end.x - 40.0, f), fr.position.y + 34.0)
				1: tp = Vector2(fr.position.x + 46.0, lerpf(fr.position.y + 60.0, fr.end.y - 60.0, f))
				_: tp = Vector2(fr.end.x - 46.0, lerpf(fr.position.y + 60.0, fr.end.y - 60.0, f))
			m.trees.append(tp)
	var grove := 14
	# Where they can stand at all. Palms do not grow in the sea or halfway down
	# a beach - they line the back of it - and a clearing is a clearing because
	# the middle of it is empty. The grove is rope-wrap geometry too, so this
	# decides how the space plays as well as how it looks.
	var grove_lo := 200.0
	var grove_hi := 1080.0
	match m.freedom_kind:
		"beach":
			grove = 5
			grove_lo = 800.0     # the back of the beach, inland of the dry sand
			grove_hi = 1060.0
		"clearing":
			grove = 10           # plus the ring the clearing draws
		"lot":
			grove = 6
			grove_lo = 150.0
			grove_hi = 1120.0
	for i in range(grove):
		for attempt in range(20):
			var tx := randf_range(grove_lo, grove_hi)
			if m.freedom_kind == "clearing":
				# outer thirds only: the middle is where the fetching happens
				tx = randf_range(150.0, 340.0) if randf() < 0.5 else randf_range(940.0, 1120.0)
			var tree := Vector2(tx, m.GATE_Y - randf_range(120.0, 550.0))
			var clear := tree.distance_to(m.gate_bench) > 95.0
			for w: Rect2 in m.water:
				clear = clear and not w.grow(30.0).has_point(tree)
			for slot in m.PAIR_PARK_SPOTS:
				var spot: Vector2 = slot.position
				clear = clear and tree.distance_to(spot) > 85.0
			if clear:
				m.trees.append(tree)
				break
	# THE FUR-GONETA, where a mobile groomer would actually work: the
	# boulevard (a trade in nervous poodles). Position only
	# here - wrap flanks are appended AFTER the corridor fit so body, draw,
	# blocker, scent and rope contacts share one fitted centre.
	# (not El Mercat any more: a van has no business inside a market hall)
	if m.lvl == "street":
		m.furgoneta = Vector2(m.sw_l + 66.0, -3560.0)
	for ly in m.lane_ys:
		m.lane_state.append({"t": randf_range(1.0, 2.5), "phase": 0, "dir": 1})
	build_substance_zones(m)
	fit_props_to_corridor(m)
	# after the fit, deliberately: the verge is the one place whose contents
	# must NOT be pulled onto the pavement
	build_verge(m)
	if m.furgoneta.x < INF:
		for off: float in [-52.0, -26.0, 0.0, 26.0, 52.0]:
			m.poles.append(m.furgoneta + Vector2(0.0, off))
	if m.lvl == "station":
		# the train is the biggest thing on the walk: the rope wraps its ends
		# and sides
		var tr := ESTACIO_TRAIN
		var ty := tr.position.y
		while ty <= tr.end.y:
			m.poles.append(Vector2(tr.position.x - 4.0, ty))
			m.poles.append(Vector2(tr.end.x + 4.0, ty))
			ty += 40.0
		for tx: float in [tr.position.x + 40.0, tr.get_center().x, tr.end.x - 40.0]:
			m.poles.append(Vector2(tx, tr.position.y - 4.0))
			m.poles.append(Vector2(tx, tr.end.y + 4.0))
	if m.lvl == "park":
		m.rails.clear()
		for bed: Rect2 in PARK_BEDS:
			for bx: float in [bed.position.x, bed.end.x]:
				m.rails.append({"x": bx, "y0": bed.position.y, "y1": bed.end.y})
		# the lake is the biggest pole on the walk: wrap points round its shore
		var lc: Vector2 = PARK_LAKE.get_center()
		for i in range(36):
			var a := TAU * float(i) / 36.0
			m.poles.append(lc + Vector2(cos(a) * PARK_LAKE.size.x * 0.49, sin(a) * PARK_LAKE.size.y * 0.49))
		for bp: Vector2 in bandstand_posts():
			m.park_posts.append(bp)
			m.poles.append(bp)
		# the mammoth's legs catch the rope, and her front foot can be marked
		for lg: Vector2 in [Vector2(-22, -30), Vector2(22, -30), Vector2(-22, 34), Vector2(22, 34)]:
			m.poles.append(PARK_MAMMOTH + lg)
		m.hydrants.append({"pos": PARK_MAMMOTH + Vector2(34.0, -40.0), "done": false, "progress": 0.0, "kind": "mammoth"})
	# the end of each fallen trunk out on the trail is what the rope catches
	if m.lvl == "trail":
		for i in range(TRAIL_LOGS.size()):
			var lr: Rect2 = trail_logs(m)[i]
			var tip_x: float = lr.end.x if float(TRAIL_LOGS[i][1]) < 0.0 else lr.position.x
			m.poles.append(Vector2(tip_x, lr.get_center().y))
	# The grove is wrap geometry too, so the rope catches on trunks. Appended
	# AFTER the corridor fit on purpose: the trees stand in the open off-leash
	# area, which is full width, so clamping them to the walkway would drag
	# them out of position. They sit past body_pole_count, which is why they
	# get their own collision bodies in _build_walls.
	for t in m.trees:
		m.poles.append(t)
	# the hazardous hard-to-reach collectible: one per level, in a spot
	# that costs you something to reach (deliberately outside the corridor
	# on some walks, so it is exempt from the corridor fit)
	match m.lvl:
		"barri":
			m.prize_pos = BARRI_PINGPONG + Vector2(0.0, 44.0)   # under the ping-pong table
			m.prize_text = "get the ball back from under the ping-pong table"
		"street":
			m.prize_pos = Vector2(m.SHOULDER_R - 12.0, -2400.0)  # far shoulder, across the bike lane
			m.prize_text = "fetch the frisbee across the bike lane"
		"park":
			m.prize_pos = m.pond.get_center() if m.pond.size.x > 0.0 else Vector2(640.0, -2700.0)
			m.prize_text = "fetch the ball from the middle of the pond"
		"beach":
			# In the sea, so she swims for it - but x=20 was OUTSIDE THE FRAME.
			# The camera is zoomed 1.28 and sits on x=640, so only world x
			# 140..1140 is ever visible: the ball was a goal the player could
			# not see. Placed just inside the visible edge instead, still well
			# out past the shoreline.
			m.prize_pos = Vector2(178.0, -2600.0)
			m.prize_text = "swim out for the ball"
		"market":
			m.prize_pos = MERCAT_DRAIN + Vector2(0.0, -40.0)  # by the drain in the middle aisle
			m.prize_text = "grab the churro by the open drain"
		"rain":
			m.prize_pos = Vector2(640.0, -1500.0)  # right on a gaping storm drain
			m.prize_text = "snatch the toy off the storm drain"
		"oldtown":
			m.prize_pos = gotic_wall(m, m.wallcat_spots[3].y, m.wallcat_spots[3].x > m.walk_edges(m.wallcat_spots[3].y).x + 100.0, 34.0)  # under a smug wall cat
			m.prize_text = "steal the sardine under the cat's ledge"
		"trail":
			m.prize_pos = Vector2(300.0, -3400.0)  # a pinecone off in the muddy brush
			m.prize_text = "dig the pinecone out of the mud"
		"station":
			m.prize_pos = ESTACIO_WALKWAY.get_center() + Vector2(0.0, -300.0)  # a dropped sandwich mid-walkway
			m.prize_text = "grab the sandwich off the moving walkway"
		"site":
			m.prize_pos = OBRES_SLABS[1].get_center() if OBRES_SLABS.size() > 1 else Vector2(640.0, -3130.0)  # a trowel dropped in the wet cement
			m.prize_text = "fish the trowel out of the wet cement"
		"spook":
			m.prize_pos = CAST_PLACA + Vector2(0.0, 96.0)  # a panellet off the roaster's tray, ringed by sweets
			m.prize_text = "get the panellet without eating the sweets"
		"scrap":
			m.prize_pos = m.guard_posts[1] + Vector2(-30.0, 22.0)  # right beside a sleeping guard dog
			m.prize_text = "steal the bone from under the guard's nose"
		_:
			m.prize_pos = Vector2(m.SHOULDER_R - 12.0, -2400.0)
			m.prize_text = "fetch the frisbee"
	# carry / delivery mission on some walks: pick it up here, drop it there
	match m.lvl:
		"street":
			m.carry_pickup = Vector2(360.0, -1150.0)
			m.carry_drop = Vector2(905.0, -2850.0)
			m.carry_item = "the newspaper"
			m.carry_text = "deliver the newspaper to the stoop"
		"market":
			# from the fruit stall by the door to the one at the far end
			m.carry_pickup = mercat_stall_front(m, 0)
			m.carry_drop = mercat_stall_front(m, MERCAT_WALL_STALLS.size() - 2)
			m.carry_item = "the crate of oranges"
			m.carry_text = "run the oranges to the far stall"
		_:
			pass


static func build_verge(m: Node2D) -> void:
	# WHAT LIVES ON THE VERGE.
	#
	# The grass either side of the walk was always walkable and always empty,
	# which is why nobody ever went there: it was a different colour and
	# nothing else. Now that grass reads as a surface in its own right (grips
	# better, holds far more smell) it is worth putting the city's own use of
	# it on there - people sitting about on a Sunday, and the things a lawn
	# accumulates.
	#
	# Authored by hand rather than scattered, like every other prop here: a
	# picnic wants to be somewhere that reads as a spot, and hand-placing also
	# keeps it out of the global RNG, which the autowalk determinism depends on.
	m.verge_items = Array([], TYPE_DICTIONARY, &"", null)
	# WHERE THE VERGE ACTUALLY IS ON SCREEN. The camera is zoomed 1.28, so only
	# world x 140..1140 is ever visible - the level is 1200 wide but a fifth of
	# it never appears. The first pass of this put picnics at x=150 and x=1170:
	# one was clipped by the left edge of the frame and the other was
	# completely off screen. So the verge is placed relative to the pavement
	# and then held inside what the camera can see.
	var vl: float = clampf(m.sw_l - 85.0, 195.0, 1085.0)
	var vr: float = clampf(m.sw_r + 85.0, 195.0, 1085.0)
	match m.lvl:
		"street":
			# El Passeig: the boulevard's lawn, all of it on the west side -
			# east of the pavement is the bike lane and the shoulder, and what
			# green is left out there is past the edge of the frame.
			m.verge_items = Array([
				{"pos": Vector2(vl, -520.0), "kind": "picnic"},
				{"pos": Vector2(vl - 22.0, -1180.0), "kind": "stump"},
				{"pos": Vector2(vl + 14.0, -1760.0), "kind": "picnic"},
				{"pos": Vector2(vl - 30.0, -2480.0), "kind": "bush"},
				{"pos": Vector2(vl + 8.0, -3020.0), "kind": "picnic"},
				{"pos": Vector2(vl - 26.0, -3900.0), "kind": "bush"},
				{"pos": Vector2(vl + 12.0, -4420.0), "kind": "picnic"},
			], TYPE_DICTIONARY, &"", null)
		"park":
			# a park has verge on both sides, and the verge is the whole point.
			# Set from the path's edge at each y, so the lake's widening cannot
			# put a picnic on the path, and clear of the beds, the bandstand,
			# the mammoth and the playground
			var pv: Array[Dictionary] = []
			for spec: Array in [[-760.0, -1.0, "picnic"], [-1250.0, 1.0, "picnic"], [-2260.0, -1.0, "stump"],
					[-3860.0, -1.0, "bush"], [-4040.0, 1.0, "picnic"]]:
				var pe: Vector2 = m.walk_edges(float(spec[0]))
				var px: float = (pe.x - 85.0) if float(spec[1]) < 0.0 else (pe.y + 85.0)
				pv.append({"pos": Vector2(clampf(px, 195.0, 1085.0), float(spec[0])), "kind": String(spec[2])})
			m.verge_items = Array(pv, TYPE_DICTIONARY, &"", null)
		"trail":
			# out here it is fallen wood and undergrowth, not tablecloths. Set
			# from the trail's own edge at each y, so a bend cannot leave one
			# standing on the path or inside the solid wood
			var tv: Array[Dictionary] = []
			for spec: Array in [[-700.0, -1.0, "stump"], [-1450.0, 1.0, "bush"], [-2200.0, -1.0, "bush"],
					[-2950.0, 1.0, "stump"], [-3700.0, -1.0, "bush"], [-4300.0, 1.0, "stump"]]:
				var te: Vector2 = m.walk_edges(float(spec[0]))
				var tx: float = (te.x - 62.0) if float(spec[1]) < 0.0 else (te.y + 62.0)
				tv.append({"pos": Vector2(tx, float(spec[0])), "kind": String(spec[2])})
			m.verge_items = Array(tv, TYPE_DICTIONARY, &"", null)
	# La Rambla has no lawn any more, so no picnics on it (the First Walk
	# keeps its boulevard as it was)
	if m.lvl == "street" and not m.tutorial_mode:
		m.verge_items.clear()
	# Nothing on the verge may sit in a bike lane. They are drawn straight
	# across the level, verge included, so the first pass had a tree stump
	# apparently growing out of the tarmac. Pushed clear here rather than
	# hand-avoided in the lists above, so moving a lane later cannot quietly
	# strand a picnic in the middle of it.
	var clear_by = m.LANE_HALF + 52.0
	for i in range(m.verge_items.size()):
		var it: Dictionary = m.verge_items[i]
		var p: Vector2 = it["pos"]
		for ly: float in m.lane_ys:
			if absf(p.y - ly) < clear_by:
				p.y = (ly - clear_by) if p.y <= ly else (ly + clear_by)
		it["pos"] = p
		m.verge_items[i] = it


static func build_substance_zones(m: Node2D) -> void:
	# Each walk offers whatever it would plausibly have lying about. The two
	# that also SLOW her (mud, wet cement) keep doing so; the rest are purely
	# a mess to carry around, which is the fun of them.
	m.substance_zones.clear()
	for pt: Dictionary in m.patches:
		# glazed tile is a surface, not a substance: it is fast and slippery
		# but it does not come away on her paws the way wet cement does
		if not m.SUBSTANCES.has(String(pt["kind"])):
			continue
		var pk := String(pt["kind"])
		m.substance_zones.append({"rect": m.patch_bounds(pt), "patch": pt,
			"kind": pk, "slow": pk in ["mud", "cement", "sand"]})
	for cz in m.cement_zones:
		m.substance_zones.append({"rect": cz, "kind": "cement", "slow": true})
	var w = m.sw_r - m.sw_l
	if m.lvl == "site":
		var ze: Vector2 = m.walk_edges(OBRES_ZEBRA_Y)
		m.substance_zones.append({"rect": Rect2(ze.x, OBRES_ZEBRA_Y, ze.y - ze.x, OBRES_ZEBRA_H), "kind": "paint", "zebra": true})
	match m.lvl:
		"beach":
			# the whole sand side, which is most of the beach
			m.substance_zones.append({"rect": Rect2(230.0, m.GATE_Y, 150.0, absf(m.GATE_Y) + 400.0), "kind": "sand"})
	# snow turns the whole walk to slush underfoot, whatever the level. A band
	# that follows the path, not a rectangle: on the walks that bend (El Bosc,
	# El Mosaic) a rectangle between the nominal edges left the path running
	# out from under the snow and laid slush over the ground beside it.
	if Game.weather == "snow":
		var slush := {"lo": 0.0, "hi": 1.0, "y": m.GATE_Y, "h": absf(m.GATE_Y) + 500.0}
		m.substance_zones.append({"band": slush, "rect": m.band_bounds(slush), "kind": "slush"})


static func build_freedom_area(m: Node2D) -> void:
	m.freedom_kind = String(m.FREEDOM_KINDS.get(m.lvl, "yard"))
	m.water.clear()
	if m.pond.size.x > 0.0:
		m.water.append(m.pond)
	if m.lvl == "trail":
		for r: Rect2 in trail_stream(m):
			m.water.append(r)
	if m.tutorial_mode:
		m.water.append(tutorial_pond(m))
	if m.freedom_kind == "beach":
		# The sea, in two pieces that meet at the gate: a band along the whole
		# passeig (so she can go in ANYWHERE on the walk, which is the first
		# thing anyone tries on a seafront), and the wide bay in the dog beach
		# at the top. The bay uses thin horizontal strips so the diagonal
		# shoreline from beach_shore_x is wet in gameplay, not just on screen.
		m.water.append(Rect2(-360.0, m.GATE_Y - 40.0, 590.0, absf(m.GATE_Y) + 500.0))
		var strip_y = m.freedom_lo - 40.0
		var strip_h := 36.0
		var gate_y = m.GATE_Y - 30.0
		while strip_y < gate_y:
			var shore = m.beach_shore_x(strip_y + strip_h * 0.5)
			m.water.append(Rect2(-330.0, strip_y, shore + 330.0, strip_h + 0.5))
			strip_y += strip_h


static func patch_clear(m: Node2D, pt: Dictionary) -> bool:
	# is this somewhere a patch could sensibly be?
	var b = m.patch_bounds(pt)
	var c = m.patch_centre(pt)
	if m.pond.size.x > 0.0 and m.pond.intersects(b):
		return false
	for w: Rect2 in m.water:
		if w.intersects(b):
			return false
	for mh: Vector2 in m.manholes:
		if b.has_point(mh):
			return false
	for cl: Rect2 in m.cellars:
		if cl.intersects(b):
			return false
	var e = m.walk_edges(c.y)
	return c.x >= e.x and c.x <= e.y


static func settle_patches(m: Node2D) -> void:
	# Patches are authored by eye, and a perfectly plausible y can still land
	# in the pond or on top of an open manhole - which is exactly what the
	# first pass did, and it read as nonsense rather than as a mistake.
	#
	# So each one walks along the path until it finds ground that could hold
	# it, searching outward in both directions from where it was authored. It
	# never invents a position from nothing: the authored spot is the intent
	# and this only moves it as far as it has to. level_check still fails if a
	# patch cannot be placed at all, so nothing is quietly dropped.
	for i in range(m.patches.size()):
		var pt: Dictionary = m.patches[i]
		var y0 := float(pt["y"])
		if patch_clear(m, pt):
			continue
		for step in range(16):
			var off: float = float(step / 2 + 1) * 85.0
			pt["y"] = y0 + (off if step % 2 == 0 else -off)
			if patch_clear(m, pt):
				break
		m.patches[i] = pt


static func lift_props_out_of_water(m: Node2D) -> void:
	# Anything the level data put in a pond or the sea gets pushed to the
	# nearest shore. The walks that reuse another walk's geometry inherit its
	# water but not its prop placement, which is how El Bosc ended up with a
	# roadworks cone standing in the middle of the pond.
	if m.water.is_empty():
		return
	var groups: Array = [m.parasols, m.benches, m.bins, m.tables, m.astands, m.fountains,
		m.cone_spots, m.manholes, m.performers, m.candy_spots, m.wallcat_spots, m.guard_posts]
	for arr: Array in groups:
		for i in range(arr.size()):
			arr[i] = nearest_dry(m, arr[i] as Vector2)
	for k in m.kebabs:
		k.pos = nearest_dry(m, k.pos as Vector2)
	for h in m.hydrants:
		h.pos = nearest_dry(m, h.pos as Vector2)
	for tw in m.towels:
		var tr: Rect2 = tw.rect
		var moved := nearest_dry(m, tr.get_center())
		tw.rect = Rect2(moved - tr.size * 0.5, tr.size)


static func nearest_dry(m: Node2D, at: Vector2) -> Vector2:
	for w: Rect2 in m.water:
		if not w.grow(10.0).has_point(at):
			continue
		# out the closest side, far enough that its footprint is clear too
		var d_left: float = at.x - w.position.x
		var d_right: float = w.end.x - at.x
		var d_top: float = at.y - w.position.y
		var d_bot: float = w.end.y - at.y
		var m_local: float = minf(minf(d_left, d_right), minf(d_top, d_bot))
		if m_local == d_left:
			at.x = w.position.x - 30.0
		elif m_local == d_right:
			at.x = w.end.x + 30.0
		elif m_local == d_top:
			at.y = w.position.y - 30.0
		else:
			at.y = w.end.y + 30.0
	return at


static func build_dunes(m: Node2D) -> void:
	# The dune line is the beach's boundary in place of a fence, so it has to
	# BE one: these get collision below, because a boundary you can stroll
	# through is just a pattern on the floor.
	m.dune_spots.clear()
	if m.freedom_kind != "beach":
		return
	var r = m._freedom_rect()
	for i in range(26):
		var f := float(i) / 25.0
		if i % 2 == 0:
			m.dune_spots.append(Vector2(r.end.x - 70.0,
				lerpf(r.position.y + 60.0, r.end.y - 60.0, f)))
		else:
			m.dune_spots.append(Vector2(lerpf(r.position.x + 60.0, r.end.x - 60.0, f),
				r.position.y + 40.0))


static func build_park_props(m: Node2D) -> void:
	# Spread across the whole width, deliberately AWAY from the straight line
	# between gate and meadow, so poking about off the direct route is what
	# finds things. Local rng, so the deterministic autowalk is untouched.
	m.park_props.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 0xD06BA55
	var flavour := ["log", "dig", "shrub", "post", "dig", "shrub"]
	match m.lvl:
		"beach": flavour = ["driftwood", "dig", "rock", "dig", "rock"]
		"scrap", "site": flavour = ["tyre", "log", "dig", "tyre"]
		"trail", "park": flavour = ["log", "dig", "shrub", "shrub", "post", "dig"]
	var lo = m.freedom_lo + 70.0
	var hi = m.GATE_Y - 90.0
	# Guarantee the essentials rather than hoping the dice provide them: on
	# junk-flavoured walks a random draw left only one dig patch, which the
	# sanity sweep rightly failed. Digs are the main reward for exploring, so
	# they are placed first, spread across the width.
	var dig_xs: Array[float] = [250.0, 640.0, 1030.0]
	if m.freedom_kind == "beach":
		dig_xs = [560.0, 820.0, 1060.0]   # digging in dry sand, not in the sea
	var dig_fs: Array[float] = [0.22, 0.68, 0.42]
	for i in range(3):
		var gy := lerpf(lo + 60.0, hi - 60.0, dig_fs[i])
		m.park_props.append({"pos": Vector2(dig_xs[i], gy), "kind": "dig", "done": false, "prog": 0.0})
	for i in range(14):
		var kind: String = flavour[r.randi() % flavour.size()]
		# bias to the flanks: the middle is the fetch runway
		var side_pick := r.randf()
		var x := 0.0
		if m.freedom_kind == "beach":
			# all of it on the dry sand, east of the tide line
			x = r.randf_range(520.0, 780.0) if side_pick < 0.4 else r.randf_range(800.0, 1120.0)
		elif side_pick < 0.42:
			x = r.randf_range(140.0, 430.0)
		elif side_pick < 0.84:
			x = r.randf_range(860.0, 1150.0)
		else:
			x = r.randf_range(470.0, 820.0)
		var at := Vector2(x, r.randf_range(lo, hi))
		# keep clear of the owner's bench and the park slots
		if at.distance_to(m.gate_bench) < 110.0:
			continue
		# and out of the water: driftwood floating twenty metres out to sea is
		# not a sniffable object, it is a bug
		var in_water := false
		for w: Rect2 in m.water:
			if w.grow(24.0).has_point(at):
				in_water = true
		if in_water:
			continue
		var clear := true
		for slot in m.PAIR_PARK_SPOTS:
			if at.distance_to(slot.position as Vector2) < 90.0:
				clear = false
		if not clear:
			continue
		m.park_props.append({"pos": at, "kind": kind, "done": false, "prog": 0.0})
	# one water trough near the gate, because a romp is thirsty work
	# one water trough near the gate, because a romp is thirsty work - by the
	# shower on the beach, where the tap actually is
	var trough_at := Vector2(m.gate_bench.x - 150.0, m.gate_bench.y + 24.0)
	if m.freedom_kind == "beach":
		trough_at = Vector2(m.BEACH_SEA_R + 172.0, m.freedom_lo + 148.0)
	m.park_props.append({"pos": trough_at, "kind": "trough", "done": false, "prog": 0.0})


static func build_ground_detail(m: Node2D) -> void:
	# a light dusting of wear over the whole walk: hairline cracks, grit,
	# litter, damp stains. Cheap to draw (culled, and the world redraws at
	# 30fps) but it is what stops a paved corridor looking like a colour
	# swatch. Local rng: the global sequence stays byte-identical.
	var r := RandomNumberGenerator.new()
	r.seed = 0x1CEB00DA  # fixed, so a walk wears the same way every visit
	m.ground_detail.clear()
	# stop at the gate: past it the off-leash space draws its own ground, and
	# pavement grit scattered over open water is not wear, it is a bug
	var y = m.START_Y + 200.0
	while y > m.GATE_Y + 20.0:
		y -= r.randf_range(55.0, 130.0)
		var kind := r.randi() % 4
		var x := r.randf_range(m.sw_l + 12.0, m.sw_r - 12.0)
		m.ground_detail.append({
			"pos": Vector2(x, y),
			"kind": kind,
			"rot": r.randf_range(0.0, TAU),
			"len": r.randf_range(14.0, 46.0),
			"sz": r.randf_range(1.4, 3.4),
		})


static func build_bypasser_blockers(m: Node2D) -> void:
	m.bypasser_blockers.clear()
	for i in range(m.body_pole_count):
		m.bypasser_blockers.append({
			"id": "pole_%d" % i,
			"center": m.poles[i],
			"radius": m.POLE_RADIUS,
		})
	for i in range(m.hydrants.size()):
		m.bypasser_blockers.append({
			"id": "hydrant_%d" % i,
			"center": m.hydrants[i].pos,
			"radius": m.HYDRANT_RADIUS,
		})
	for i in range(m.fountains.size()):
		m.bypasser_blockers.append({
			"id": "fountain_%d" % i,
			"center": m.fountains[i],
			"radius": m.FOUNTAIN_RADIUS,
		})
	for i in range(m.performers.size()):
		m.bypasser_blockers.append({
			"id": "performer_%d" % i,
			"center": m.performers[i],
			"radius": m.PERFORMER_RADIUS,
		})
	for i in range(m.statues.size()):
		m.bypasser_blockers.append({
			"id": "statue_%d" % i,
			"center": m.statues[i],
			"radius": m.PERFORMER_RADIUS + 4.0,
		})
	for i in range(m.benches.size()):
		m.bypasser_blockers.append({
			"id": "bench_%d" % i,
			"rect": Rect2(m.benches[i] - m.BENCH_BODY_SIZE * 0.5, m.BENCH_BODY_SIZE),
		})
	for i in range(m.vans.size()):
		m.bypasser_blockers.append({
			"id": "van_%d" % i,
			"rect": Rect2(m.vans[i] - m.VAN_BODY_SIZE * 0.5, m.VAN_BODY_SIZE),
		})
	if m.furgoneta.x < INF:
		m.bypasser_blockers.append({
			"id": "furgoneta",
			"rect": Rect2(m.furgoneta - m.VAN_BODY_SIZE * 0.5, m.VAN_BODY_SIZE),
		})
	for i in range(m.stalls.size()):
		m.bypasser_blockers.append({
			"id": "stall_%d" % i,
			"rect": Rect2(m.stalls[i] - m.STALL_BODY_SIZE * 0.5, m.STALL_BODY_SIZE),
		})
	for i in range(m.manholes.size()):
		m.bypasser_blockers.append({
			"id": "manhole_%d" % i,
			"center": m.manholes[i],
			"radius": m.MANHOLE_RADIUS,
		})
	for i in range(m.cellars.size()):
		m.bypasser_blockers.append({
			"id": "cellar_%d" % i,
			"rect": m.cellars[i],
		})
	if m.pond.size.x > 0.0 and m.pond.size.y > 0.0:
		m.bypasser_blockers.append({
			"id": "pond_0",
			"rect": m.pond,
			"forced_side": "right",
		})


static func build_walls(m: Node2D) -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	var mid_y: float = (m.START_Y + m.GATE_Y) / 2.0
	var span := absf(m.START_Y - m.GATE_Y) + 1600.0
	# the walls sit at the LEVEL edges, not the path edges: the dog is
	# free to roam grass, sand and shoulders; the human stays on the walk
	# by inclination, not by invisible fences
	# On the beach the west wall moves out into the water, so she can actually
	# get in the sea - the whole point of walking a dog along the seafront.
	# Everywhere else it stays at the level edge.
	var west_x := -180.0 if m.lvl == "beach" else 40.0
	var defs := [
		[Vector2(west_x, mid_y), Vector2(100, span)],
		[Vector2(1240.0, mid_y), Vector2(100, span)],
		[Vector2(640, m.START_Y + 160.0), Vector2(1400, 100)],
		[Vector2(640, m.GATE_Y - 700.0), Vector2(1400, 100)],
	]
	for d in defs:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = d[1]
		cs.shape = sh
		cs.position = d[0]
		walls.add_child(cs)
	m.add_child(walls)
	# THE BUILDING LINE is solid (#65): she used to be able to walk out onto
	# the roofs, because the only walls were at the level edges. Segments
	# follow the path where it bends, with gaps where a road crosses, so a
	# side street still leads somewhere.
	if m.built:
		var line := StaticBody2D.new()
		line.collision_layer = 1
		# stops short of the gate, so the gate mouth is exactly as it was: the
		# off-leash area beyond it is wider than the walk, and a wall end right
		# at the gate line caught a dog coming back through it
		var top := float(m.GATE_Y) + 120.0
		var y := float(m.START_Y) + 200.0
		while y > top:
			var y2 := maxf(y - 100.0, top)
			var crossing := false
			for ly: float in m.lane_ys:
				if absf((y + y2) * 0.5 - ly) < float(m.LANE_HALF) + 50.0:
					crossing = true
			if not crossing:
				var fa: Vector2 = m.frontage(y)
				var fb: Vector2 = m.frontage(y2)
				for pair in [[Vector2(fa.x - 6.0, y), Vector2(fb.x - 6.0, y2)], [Vector2(fa.y + 6.0, y), Vector2(fb.y + 6.0, y2)]]:
					var seg := SegmentShape2D.new()
					seg.a = pair[0]
					seg.b = pair[1]
					var cs := CollisionShape2D.new()
					cs.shape = seg
					line.add_child(cs)
			y = y2
		m.add_child(line)
	# EL BOSC'S WOOD LINE: the same kind of segments, TRAIL_WOOD_OUT out from
	# the trail's edge on both sides, so the forest is a place with an inside
	# rather than a lawn with a path across it
	if m.lvl == "trail":
		var wood := StaticBody2D.new()
		wood.collision_layer = 1
		var wtop := float(m.GATE_Y) + 120.0
		var wy := float(m.START_Y) + 200.0
		while wy > wtop:
			var wy2 := maxf(wy - 100.0, wtop)
			var ea: Vector2 = m.walk_edges(wy)
			var eb: Vector2 = m.walk_edges(wy2)
			for pair in [[Vector2(ea.x - TRAIL_WOOD_OUT, wy), Vector2(eb.x - TRAIL_WOOD_OUT, wy2)],
					[Vector2(ea.y + TRAIL_WOOD_OUT, wy), Vector2(eb.y + TRAIL_WOOD_OUT, wy2)]]:
				var seg := SegmentShape2D.new()
				seg.a = pair[0]
				seg.b = pair[1]
				var cs := CollisionShape2D.new()
				cs.shape = seg
				wood.add_child(cs)
			wy = wy2
		m.add_child(wood)
	if m.lvl == "station":
		add_rect_body(m, ESTACIO_TRAIN.get_center(), ESTACIO_TRAIN.size)
	if m.lvl == "oldtown":
		var fb := StaticBody2D.new()
		fb.collision_layer = 1
		fb.position = GOTIC_PLACA
		var fcs := CollisionShape2D.new()
		var fsh := CircleShape2D.new()
		fsh.radius = 34.0
		fcs.shape = fsh
		fb.add_child(fcs)
		m.add_child(fb)
	if m.lvl == "park":
		add_rect_body(m, PARK_MAMMOTH, MAMMOTH_BODY)
		for bp: Vector2 in bandstand_posts():
			var pb := StaticBody2D.new()
			pb.collision_layer = 1
			pb.position = bp
			var pcs := CollisionShape2D.new()
			var psh := CircleShape2D.new()
			psh.radius = m.POLE_RADIUS
			pcs.shape = psh
			pb.add_child(pcs)
			m.add_child(pb)
	if m.lvl == "trail":
		for lr: Rect2 in trail_logs(m):
			var lb := StaticBody2D.new()
			lb.collision_layer = LOW_LAYER
			lb.position = lr.get_center()
			var lcs := CollisionShape2D.new()
			var lsh := RectangleShape2D.new()
			lsh.size = lr.size
			lcs.shape = lsh
			lb.add_child(lcs)
			m.add_child(lb)
	for i in range(m.body_pole_count):
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		sb.position = m.poles[i]
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = m.POLE_RADIUS
		cs.shape = sh
		sb.add_child(cs)
		m.add_child(sb)
	# The grove in the off-leash area used to be pure decoration you could
	# walk straight through - a flat texture, not an object. A tree is a
	# solid trunk with real heft, so it blocks bodies and the leash wraps
	# on it like any other pole.
	for d in m.dune_spots:
		var db := StaticBody2D.new()
		db.collision_layer = 1
		db.position = d
		var dcs := CollisionShape2D.new()
		var dsh := CircleShape2D.new()
		dsh.radius = 22.0
		dcs.shape = dsh
		db.add_child(dcs)
		m.add_child(db)
	for t in m.trees:
		var tb := StaticBody2D.new()
		tb.collision_layer = 1
		tb.position = t
		var tcs := CollisionShape2D.new()
		var tsh := CircleShape2D.new()
		tsh.radius = m.TREE_RADIUS
		tcs.shape = tsh
		tb.add_child(tcs)
		m.add_child(tb)
	# Buildings are solid, so you cannot stroll onto a roof. Only on the sides
	# that really ARE buildings, and only along the walking legs - the
	# off-leash area past the gate stays open. The boulevard and El Aguacero
	# keep their right side open because that is the bike lane and the far
	# shoulder, where the frisbee prize deliberately sits; the green walks and
	# the beach have no buildings at all.
	var wall_sides := []
	match m.lvl:
		"street": wall_sides = [-1.0]
		"rain": wall_sides = []      # its frontage walls are the building line
		"park", "trail", "beach": wall_sides = []
		_: wall_sides = [-1.0, 1.0]
	for ws in wall_sides:
		var bx: float = (m.sw_l - 60.0) if ws < 0.0 else (m.sw_r + 60.0)
		var bb := StaticBody2D.new()
		bb.collision_layer = 1
		bb.position = Vector2(bx, (m.START_Y + m.GATE_Y) / 2.0)
		var bcs := CollisionShape2D.new()
		var bsh := RectangleShape2D.new()
		bsh.size = Vector2(120.0, absf(m.START_Y - m.GATE_Y) + 400.0)
		bcs.shape = bsh
		bb.add_child(bcs)
		m.add_child(bb)
	# the park's solid furniture: you go round a log, not through it. Digs,
	# shrubs and troughs stay walkable so nosing about is never obstructed.
	for pp in m.park_props:
		var pk := String(pp.kind)
		if pk != "log" and pk != "driftwood" and pk != "tyre":
			continue
		var lb := StaticBody2D.new()
		lb.collision_layer = 1
		lb.position = pp.pos
		var lcs := CollisionShape2D.new()
		if pk == "tyre":
			var csh := CircleShape2D.new()
			csh.radius = 16.0
			lcs.shape = csh
		else:
			var rsh := RectangleShape2D.new()
			rsh.size = Vector2(62.0, 18.0)
			lcs.shape = rsh
		lb.add_child(lcs)
		m.add_child(lb)
	# vans and stalls are solid rectangles: no walking over the van roof
	for v in m.vans:
		add_rect_body(m, v, m.VAN_BODY_SIZE)
	if m.furgoneta.x < INF:
		add_rect_body(m, m.furgoneta, m.VAN_BODY_SIZE)
	for st in m.stalls:
		add_rect_body(m, st, m.STALL_BODY_SIZE)
	# El Mosaic's salamander
	if m.lvl == "guell":
		add_rect_body(m, MOSAIC_SALAMANDER, MOSAIC_SALAMANDER_SIZE)
	# La Neteja's dumpsters
	if m.lvl == "neteja":
		for d: Vector2 in neteja_dumpsters(m):
			add_rect_body(m, d, NETEJA_DUMPSTER)
	# La Castanyada's roaster and stage
	if m.lvl == "spook":
		add_rect_body(m, CAST_PLACA, CAST_ROASTER)
		add_rect_body(m, castanyada_stage(m).get_center(), castanyada_stage(m).size)
	# El Mercat's stall blocks down the middle of the hall
	if m.lvl == "market":
		for blk: Rect2 in MERCAT_BLOCKS:
			add_rect_body(m, blk.get_center(), blk.size)
	# La Rambla's statues are people on boxes: solid
	for sp: Vector2 in m.statues:
		var stb := StaticBody2D.new()
		stb.collision_layer = 1
		stb.position = sp
		var scs := CollisionShape2D.new()
		var ssh := CircleShape2D.new()
		ssh.radius = m.PERFORMER_RADIUS + 4.0
		scs.shape = ssh
		stb.add_child(scs)
		m.add_child(stb)
	# performers have mass; you walk around a person, not through them
	for pf in m.performers:
		var pb := StaticBody2D.new()
		pb.collision_layer = 1
		pb.position = pf
		var pcs := CollisionShape2D.new()
		var psh := CircleShape2D.new()
		psh.radius = m.PERFORMER_RADIUS
		pcs.shape = psh
		pb.add_child(pcs)
		m.add_child(pb)


static func add_rect_body(m: Node2D, at: Vector2, size: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.position = at
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	m.add_child(sb)


static func build_entities(m: Node2D) -> void:
	m.leash = Node2D.new()
	m.leash.set_script(load("res://entities/leash.gd"))
	m.leash.z_index = 5
	m.add_child(m.leash)

	m.dog = CharacterBody2D.new()
	m.dog.set_script(load("res://entities/dog.gd"))
	m.dog.position = Vector2(700, m.START_Y)
	m.add_child(m.dog)
	m.dog.setup(m)

	m.human = CharacterBody2D.new()
	m.human.set_script(load("res://entities/human.gd"))
	m.human.position = Vector2(600, m.START_Y - 70.0)
	m.add_child(m.human)
	m.human.setup(m)

	m.leash.setup(m.dog, m.human, m.poles, m.LEASH_LENGTH)
	m.leash.hero = true  # the player's rope draws every frame; NPC ropes at 30fps
	m.leash.furniture_poles = m._furniture_wrap_poles()

	m.edge_layer = Node2D.new()
	m.edge_layer.set_script(load("res://world/edgelayer.gd"))
	m.edge_layer.z_index = -5   # behind everything in the world
	# what hangs over the walk, above everyone (El Gotic's bridge, El Mercat's
	# arches, La Castanyada's lantern strings)
	if m.lvl == "oldtown" or m.lvl == "market" or m.lvl == "spook":
		var ov := Node2D.new()
		ov.set_script(load("res://world/overheadlayer.gd"))
		ov.z_index = 14
		m.add_child(ov)
		ov.setup(m)
	m.add_child(m.edge_layer)
	m.edge_layer.setup(m)
	m.verge_layer = Node2D.new()
	m.verge_layer.set_script(load("res://world/vergelayer.gd"))
	# above the ground pass, below the actors and props
	m.verge_layer.z_index = 1
	m.add_child(m.verge_layer)
	m.verge_layer.setup(m)
	# the off-leash space gets the same treatment: it is a fixed scene, so it
	# is drawn once onto its own canvas rather than thirty times a second
	m.freedomlayer = Node2D.new()
	m.freedomlayer.set_script(load("res://world/freedomlayer.gd"))
	m.freedomlayer.z_index = -9
	m.add_child(m.freedomlayer)
	m.freedomlayer.setup(m)
	m.cam = Camera2D.new()
	m.cam.position_smoothing_enabled = true
	m.cam.position_smoothing_speed = 6.0
	# the walkway is only ~680px of a 1280px frame, so half the screen used
	# to be empty verge and the characters read as specks. Pushing in fills
	# the frame and makes the animation and the rope legible - the single
	# biggest framing win available. Trade-off: less warning time on
	# oncoming hazards, so this is a feel dial (1.0 = the old framing).
	m.cam.zoom = Vector2(m.CAM_ZOOM, m.CAM_ZOOM)
	m.cam.position = Vector2(640, m.START_Y - 120.0)
	m.add_child(m.cam)
	m.cam.make_current()


static func spawn_cones(m: Node2D) -> void:
	# real, kickable cones at every work site plus a few loose ones
	var spots: Array[Vector2] = []
	spots.append_array(m.cone_spots)
	for m_local in m.manholes:
		spots.append(m_local + Vector2(32, -18))
		spots.append(m_local + Vector2(-30, 22))
		spots.append(m_local + Vector2(26, 28))
		spots.append(m_local + Vector2(-26, -26))
	# a cone each end of a cellar hatch; Les Obres' trench sets its own, and
	# two on its plank would be two cones in the owner's way
	for c in m.cellars:
		if m.lvl == "site":
			break
		spots.append(Vector2(c.end.x + 14, c.position.y + 24))
		spots.append(Vector2(c.position.x - 12, c.end.y - 10))
	for s in spots:
		var cn := Node2D.new()
		cn.set_script(load("res://entities/cone.gd"))
		cn.position = s
		cn.z_index = 11
		m.add_child(cn)
		cn.setup(m, m.dog, m.human, "cone")
	# Loose junk scattered down the whole walk, because punting things is one
	# of the reliable joys here and there was only ever cones. Mixed kinds so
	# the heft varies: cans rattle away, sacks barely budge. Local rng, so the
	# deterministic autowalk seed is untouched.
	var jr := RandomNumberGenerator.new()
	jr.seed = 0x7A17B0B
	# the level's background litter, for stretches with nothing else nearby
	var kinds := ["can", "bottle", "sack", "can"]
	match m.lvl:
		"scrap", "site": kinds = ["crate", "sack", "can", "bottle", "crate"]
		"beach": kinds = ["bottle", "ball", "can"]
		"park", "trail": kinds = ["bottle", "ball", "can"]
		"market", "spook": kinds = ["crate", "bottle", "can"]
		"neteja": kinds = ["crate", "crate", "sack", "bottle"]
		"station": kinds = ["can", "bottle", "bottle"]
		"oldtown": kinds = ["sack", "bottle", "can"]
	# Litter accumulates around whatever produced it, so junk is placed by
	# AREA rather than sprinkled evenly: crates pile up behind market stalls,
	# cans and bottles collect around cafe tables and buskers, sacks slump by
	# the bins, crates and cones litter the works. Feels observed rather than
	# randomised, and it makes each stretch of a walk look like somewhere.
	var zones: Array[Dictionary] = []
	for b in m.bins:
		zones.append({"at": b, "pal": ["sack", "sack", "bottle"]})
	for st in m.stalls:
		zones.append({"at": st, "pal": ["crate", "crate", "bottle"]})
	for tb in m.tables:
		zones.append({"at": tb, "pal": ["can", "bottle", "can"]})
	for pf in m.performers:
		zones.append({"at": pf, "pal": ["can", "can", "bottle"]})
	for v in m.vans:
		zones.append({"at": v, "pal": ["crate", "sack", "can"]})
	for bn in m.benches:
		zones.append({"at": bn, "pal": ["can", "bottle", "ball"]})
	for z in zones:
		var pal: Array = z.pal
		for i in range(jr.randi_range(1, 3)):
			var at: Vector2 = z.at
			var off := Vector2(jr.randf_range(-46.0, 46.0), jr.randf_range(-40.0, 46.0))
			var px := clampf(at.x + off.x, m.sw_l + 16.0, m.sw_r - 16.0)
			spawn_junk(m, Vector2(px, at.y + off.y), pal[jr.randi() % pal.size()])
	# then a thin background scatter, so the quiet stretches are not bare
	var jy = m.START_Y - 120.0
	while jy > m.GATE_Y + 160.0:
		jy -= jr.randf_range(260.0, 520.0)
		var jx := jr.randf_range(m.sw_l + 30.0, m.sw_r - 30.0)
		spawn_junk(m, Vector2(jx, jy), kinds[jr.randi() % kinds.size()])
	# A-stands are entities too: light, toppleable, never re-stood. Spawned
	# once here with the rest of the kickable furniture; this loop used to sit
	# in on_junk_kicked, so none stood at the start and every kick added a
	# full duplicate set (#30)
	for a in m.astands:
		var sa := Node2D.new()
		sa.set_script(load("res://entities/astand.gd"))
		sa.position = a
		sa.z_index = 11
		m.add_child(sa)
		sa.setup(m, m.dog, m.human)


static func spawn_junk(m: Node2D, at: Vector2, kind: String) -> void:
	var jn := Node2D.new()
	jn.set_script(load("res://entities/cone.gd"))
	jn.position = at
	jn.z_index = 11
	m.add_child(jn)
	jn.setup(m, m.dog, m.human, kind)
