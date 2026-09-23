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
		"park": half = 300.0     # a dirt path through grass
		"beach": half = 340.0    # bespoke cross-section, left alone
		"rain": half = 320.0
		"market": half = 270.0   # stalls crowd the aisle
		"oldtown": half = 225.0  # the tightest: a medieval alley
		"trail": half = 250.0    # a single-file woodland trail
		"station": half = 390.0  # the widest: an open concourse
		"site": half = 295.0     # squeezed by the works
		"spook": half = 275.0
		"scrap": half = 305.0
		"guell": half = 300.0   # terraces, wide enough to carve on
	m.walk_cx = 640.0
	m.walk_half = half
	m.sw_l = m.walk_cx - m.walk_half
	m.sw_r = m.walk_cx + m.walk_half
	# The SHAPE of the corridor, on top of its width. Empty means a straight
	# pair of vertical lines at exactly sw_l/sw_r, which is what most levels
	# still are. See edge_path.gd; walk_edges(y) is what everything should ask.
	m.edge_nodes = []
	if m.lvl == "guell":
		# EL PARC. The serpentine, and the point of the whole level: Gaudi did
		# not draw a straight line and neither does this path. It is a longer,
		# deeper weave than El Bosc's - a bench terrace that swings right
		# across the level and back, so carving it is the walk.
		#
		# Kept inside the slope the self-test allows (0.85) so it can be run
		# rather than merely admired, and both ends sit centred so the start
		# line and the gate still line up.
		m.edge_nodes = [
			{"y": m.START_Y, "cx": 640.0, "half": 300.0},
			{"y": -700.0, "cx": 486.0, "half": 292.0},
			{"y": -1500.0, "cx": 792.0, "half": 268.0},
			{"y": -2300.0, "cx": 470.0, "half": 300.0},
			{"y": -3100.0, "cx": 806.0, "half": 262.0},
			{"y": -3900.0, "cx": 520.0, "half": 296.0},
			{"y": -4600.0, "cx": 700.0, "half": 300.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 300.0},
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
			{"y": m.START_Y, "cx": 640.0, "half": 250.0},
			{"y": -900.0, "cx": 566.0, "half": 250.0},
			{"y": -2000.0, "cx": 716.0, "half": 212.0},   # the pinch
			{"y": -3100.0, "cx": 578.0, "half": 246.0},
			{"y": -4200.0, "cx": 668.0, "half": 250.0},
			{"y": m.GATE_Y, "cx": 640.0, "half": 250.0},
		]


static func fit_x(m: Node2D, x: float, lo: float, hi: float) -> float:
	var f := clampf((x - 300.0) / 680.0, 0.0, 1.0)
	return lerpf(lo, hi, f)


static func fit_props_to_corridor(m: Node2D) -> void:
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
			m.guard_posts, m.candy_spots, m.fountains]:
		for i in range(arr.size()):
			var p: Vector2 = arr[i]
			var e = m.walk_edges(p.y)
			# remap proportionally so left-side props stay left, right stay right
			arr[i] = Vector2(fit_x(m, p.x, e.x + pad, e.y - pad), p.y)
	# the dictionary-based pickups need the same treatment
	for list in [m.hydrants, m.kebabs, m.candy]:
		for d in list:
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
	if m.lvl == "rain" or m.lvl == "station" or m.lvl == "site" or m.lvl == "scrap":
		geo = "street"
	elif m.lvl == "oldtown" or m.lvl == "spook":
		geo = "market"
	elif m.lvl == "trail" or m.lvl == "guell":
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
			# the pond bites into the path; the strip past it is the bridge
			m.pond = Rect2(m.sw_l, -2950, 360, 470)
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
	elif m.lvl == "park":
		m.fountains = Array([Vector2(944, -3300), Vector2(724, -2440)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "rain":
		# El Aguacero: get-out-of-the-rain gate, storm drains gaping open
		# down the middle of the road (open holes, lethal in a downpour),
		# a huddle of umbrella-toting pedestrians clogging the walkway, and
		# a fountain nobody needs today
		m.gate_text = "SHELTER"
		m.manholes.append_array([Vector2(640, -1500), Vector2(600, -2650), Vector2(680, -3900)])
		# a huddle of umbrellas clogging the walkway - dense enough to make
		# you thread it, with gaps left so it is never a wall
		m.performers.append_array([
			Vector2(500, -2250), Vector2(790, -2320),
			Vector2(560, -3560), Vector2(760, -3520),
		])
		m.fountains = Array([Vector2(335, -3350)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "oldtown":
		# El Gotic: a tight medieval alley. Wall cats perched on ledges up
		# both walls, laundry strung overhead, lanterns. Extra poles pinch
		# the channel so threading the owner through is the real work.
		m.gate_text = "PLACA"
		m.wallcat_spots = Array([
			Vector2(360, -900), Vector2(920, -1450), Vector2(360, -2100),
			Vector2(920, -2750), Vector2(360, -3350), Vector2(920, -3950),
		], TYPE_VECTOR2, &"", null)
		m.laundry_lines = Array([-1250.0, -2000.0, -2850.0, -3650.0, -4300.0], TYPE_FLOAT, &"", null)
		for yy in [-1150.0, -1700.0, -2500.0, -3200.0, -3800.0, -4400.0]:
			m.poles.append(Vector2(m.walk_cx + (70.0 if int(yy) % 2 == 0 else -70.0), yy))
		m.fountains = Array([Vector2(345, -2600.0)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "trail":
		# El Bosc: a forest trail. No bars out here, so the owner is forever
		# stopping to hunt for a signal (see human.gd); muddy patches slow
		# the going, and a stream to drink from. Calm, stop-start rhythm.
		m.gate_text = "CLEARING"
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
		], TYPE_DICTIONARY, &"", null)
		m.fountains = Array([Vector2(360.0, -2400.0)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "station":
		# L'Estacio: a concourse with a moving walkway. On it you get carried
		# toward the platforms (north) - a boost on the way out, a shove to
		# fight on the way home. Luggage carts clutter the floor.
		m.gate_text = "PLATFORM"
		m.conveyor_zone = Rect2(m.walk_cx - 90.0, -3400.0, 180.0, 1500.0)
		m.conveyor_dir = Vector2(0, -1)
		m.vans = Array([Vector2(380, -1500), Vector2(900, -2600), Vector2(400, -4200)], TYPE_VECTOR2, &"", null)
		m.fountains = Array([Vector2(1005, -3550)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "spook":
		# La Castanyada: the autumn festival at night. Sweets everywhere -
		# and here's the cruelty: chocolate is poison to dogs, so the one
		# thing you want most is the one thing you must NOT eat. Steer past
		# the candy strewn across your path; real treats are still fair game.
		m.gate_text = "PLACA"
		m.candy_spots = Array([
			Vector2(560, -1100), Vector2(700, -1400), Vector2(600, -1750),
			Vector2(720, -2200), Vector2(560, -2600), Vector2(690, -2950),
			Vector2(600, -3400), Vector2(720, -3800), Vector2(560, -4200),
		], TYPE_VECTOR2, &"", null)
		m.performers.append_array([Vector2(400, -2100), Vector2(880, -3300)])
	elif m.lvl == "site":
		# Les Obres: a roadworks detour. Wet cement laid across the walkway
		# slows you AND takes a paw-print trail that follows you the rest of
		# the walk (the evidence). Extra cones and a parked works van.
		m.gate_text = "DETOUR"
		# WET CEMENT, poured in patches rather than laid across the whole
		# footway. A full-width slab is a wall with a paint penalty; poured
		# patches are a line to pick through, and a works that has done half a
		# job is more like a real works anyway. Same primitive as El Bosc's
		# puddles - only the substance differs, which is the point of it.
		m.cement_zones = Array([], TYPE_RECT2, &"", null)
		m.patches = Array([
			{"y": -1660.0, "at": 0.24, "rx": 96.0, "ry": 54.0, "seed": 2.05, "kind": "cement"},
			{"y": -1810.0, "at": 0.70, "rx": 78.0, "ry": 46.0, "seed": 4.60, "kind": "cement"},
			{"y": -3290.0, "at": 0.62, "rx": 104.0, "ry": 58.0, "seed": 1.35, "kind": "cement"},
			{"y": -3460.0, "at": 0.30, "rx": 72.0, "ry": 42.0, "seed": 5.85, "kind": "cement"},
		], TYPE_DICTIONARY, &"", null)
		m.cone_spots = Array([Vector2(520, -1650), Vector2(760, -1650), Vector2(560, -2020), Vector2(720, -2020), Vector2(600, -3250), Vector2(700, -3650)], TYPE_VECTOR2, &"", null)
		m.vans = Array([Vector2(900, -2500)], TYPE_VECTOR2, &"", null)
		m.fountains = Array([Vector2(335, -4200)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "guell":
		# El Parc: Gaudi's terraces. Broken-tile mosaic underfoot, which is
		# fast and slippery to run on, laid in organic sweeps rather than
		# slabs - the patch primitive was already the right shape for it.
		m.gate_text = "TERRACE"
		# It inherits the park's cross-section, which brings the park's pond
		# with it - and the pond is authored against a STRAIGHT corridor, so on
		# a serpentine it ends up swallowing whatever the path now runs over.
		# The self-test caught a fountain and a cone standing in it. The
		# terraces do their water as a fountain instead.
		m.pond = Rect2()
		m.patches = Array([
			{"y": -640.0, "at": 0.44, "rx": 150.0, "ry": 86.0, "seed": 1.42, "kind": "tile"},
			{"y": -1460.0, "at": 0.56, "rx": 168.0, "ry": 94.0, "seed": 3.07, "kind": "tile"},
			{"y": -2280.0, "at": 0.40, "rx": 158.0, "ry": 90.0, "seed": 4.61, "kind": "tile"},
			{"y": -3080.0, "at": 0.60, "rx": 174.0, "ry": 98.0, "seed": 0.88, "kind": "tile"},
			{"y": -3880.0, "at": 0.46, "rx": 156.0, "ry": 88.0, "seed": 2.35, "kind": "tile"},
		], TYPE_DICTIONARY, &"", null)
		m.fountains = Array([Vector2(m.walk_cx - 150.0, -2650.0)], TYPE_VECTOR2, &"", null)
	elif m.lvl == "scrap":
		# El Desguas: the scrapyard shortcut. Sleeping guard dogs, sweeping
		# cameras, laser tripwires - and your stealth partner is a glowing,
		# ringing phone zombie on the other end of the rope. Slow is silent;
		# getting caught is embarrassing, not fatal.
		m.gate_text = "BACK GATE"
		m.guard_posts = Array([
			Vector2(380, -1350), Vector2(900, -2250),
			Vector2(390, -3150), Vector2(880, -4050),
		], TYPE_VECTOR2, &"", null)
		m.cameras = Array([
			{"pos": Vector2(330, -1900), "base": 0.0, "range": 0.9, "speed": 0.7, "cd": 0.0},
			{"pos": Vector2(950, -3500), "base": PI, "range": 0.9, "speed": 0.55, "cd": 0.0},
		], TYPE_DICTIONARY, &"", null)
		m.lasers = Array([
			{"x0": m.sw_l, "x1": m.sw_r, "y_lo": -2750.0, "y_hi": -2550.0, "speed": 1.1, "cd": 0.0},
			{"x0": m.sw_l, "x1": m.sw_r, "y_lo": -4450.0, "y_hi": -4250.0, "speed": 0.8, "cd": 0.0},
		], TYPE_DICTIONARY, &"", null)
		# scrap heaps: wrecked cars (vans) and junk drums (cones)
		m.vans = Array([Vector2(880, -1600), Vector2(390, -2650), Vector2(900, -4400)], TYPE_VECTOR2, &"", null)
		m.cone_spots = Array([Vector2(560, -1950), Vector2(720, -3050), Vector2(600, -3900)], TYPE_VECTOR2, &"", null)
		m.fountains = Array([Vector2(1005, -2950)], TYPE_VECTOR2, &"", null)
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
		# a generous supply of practice apparatus, spread out and unhurried
		hyd_list = [Vector2(360.0, -700.0), Vector2(915.0, -1250.0), Vector2(360.0, -1900.0)]
		keb_list = [Vector2(640.0, -1500.0), Vector2(700.0, -2400.0)]
		m.poles.append(Vector2(500.0, -2100.0))
		m.poles.append(Vector2(790.0, -2750.0))
		m.deco_pole_count = m.poles.size()
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
	for cp in m.candy_spots:
		m.candy.append({"pos": cp, "eaten": false})
	build_ground_detail(m)
	build_freedom_area(m)
	lift_props_out_of_water(m)
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
	# THE FUR-GONETA, on the two walks a mobile groomer would actually work:
	# the market (a trade in nervous poodles) and the boulevard. Position only
	# here - wrap flanks are appended AFTER the corridor fit so body, draw,
	# blocker, scent and rope contacts share one fitted centre.
	if m.lvl == "market":
		m.furgoneta = Vector2(m.sw_r - 74.0, -2150.0)
	elif m.lvl == "street":
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
			m.prize_pos = Vector2(640.0, -2050.0)  # by the drain in the middle aisle
			m.prize_text = "grab the churro by the open drain"
		"rain":
			m.prize_pos = Vector2(640.0, -1500.0)  # right on a gaping storm drain
			m.prize_text = "snatch the toy off the storm drain"
		"oldtown":
			m.prize_pos = Vector2(920.0, -2750.0)  # under a smug wall cat, up the wall
			m.prize_text = "steal the sardine under the cat's ledge"
		"trail":
			m.prize_pos = Vector2(300.0, -3400.0)  # a pinecone off in the muddy brush
			m.prize_text = "dig the pinecone out of the mud"
		"station":
			m.prize_pos = Vector2(640.0, -2650.0)  # a dropped sandwich mid-walkway
			m.prize_text = "grab the sandwich off the moving walkway"
		"site":
			m.prize_pos = Vector2(640.0, -3130.0)  # a trowel dropped in the wet cement
			m.prize_text = "fish the trowel out of the wet cement"
		"spook":
			m.prize_pos = Vector2(640.0, -2350.0)  # a dog-safe pumpkin treat, ringed by candy
			m.prize_text = "get the pumpkin treat without eating the candy"
		"scrap":
			m.prize_pos = Vector2(925.0, -2270.0)  # right beside a sleeping guard dog
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
			m.carry_pickup = Vector2(915.0, -1250.0)
			m.carry_drop = Vector2(360.0, -3050.0)
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
			# a park has verge on both sides, and the verge is the whole point
			m.verge_items = Array([
				{"pos": Vector2(vl, -760.0), "kind": "picnic"},
				{"pos": Vector2(vr, -1500.0), "kind": "picnic"},
				{"pos": Vector2(vl - 18.0, -2260.0), "kind": "stump"},
				{"pos": Vector2(vr + 10.0, -3100.0), "kind": "picnic"},
				{"pos": Vector2(vl + 16.0, -3820.0), "kind": "bush"},
			], TYPE_DICTIONARY, &"", null)
		"trail":
			# out here it is fallen wood and undergrowth, not tablecloths
			m.verge_items = Array([
				{"pos": Vector2(vl, -700.0), "kind": "stump"},
				{"pos": Vector2(vr, -1450.0), "kind": "bush"},
				{"pos": Vector2(vl + 18.0, -2200.0), "kind": "bush"},
				{"pos": Vector2(vr - 14.0, -2950.0), "kind": "stump"},
				{"pos": Vector2(vl - 16.0, -3700.0), "kind": "bush"},
				{"pos": Vector2(vr + 12.0, -4300.0), "kind": "stump"},
			], TYPE_DICTIONARY, &"", null)
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
		m.substance_zones.append({"rect": m.patch_bounds(pt), "patch": pt,
			"kind": String(pt["kind"]), "slow": true})
	for cz in m.cement_zones:
		m.substance_zones.append({"rect": cz, "kind": "cement", "slow": true})
	var w = m.sw_r - m.sw_l
	match m.lvl:
		"site":
			# a works has wet paint as well as wet cement
			m.substance_zones.append({"rect": Rect2(m.sw_l + 20.0, -2500.0, w * 0.4, 150.0), "kind": "paint"})
		"beach":
			# the whole sand side, which is most of the beach
			m.substance_zones.append({"rect": Rect2(230.0, m.GATE_Y, 150.0, absf(m.GATE_Y) + 400.0), "kind": "sand"})
		"market":
			# the fishmonger's patch, and everyone will know about it
			m.substance_zones.append({"rect": Rect2(m.sw_l + 30.0, -3050.0, w * 0.35, 130.0), "kind": "fish"})
		"scrap":
			m.substance_zones.append({"rect": Rect2(m.sw_l + 40.0, -1850.0, w * 0.45, 140.0), "kind": "oil"})
		"spook":
			m.substance_zones.append({"rect": Rect2(m.sw_l + 25.0, -2150.0, w * 0.5, 160.0), "kind": "confetti"})
		"trail":
			m.substance_zones.append({"rect": Rect2(m.sw_l + 20.0, -3650.0, w * 0.5, 150.0), "kind": "mud", "slow": true})
	# snow turns the whole walk to slush underfoot, whatever the level
	if Game.weather == "snow":
		m.substance_zones.append({"rect": Rect2(m.sw_l, m.GATE_Y, w, absf(m.GATE_Y) + 500.0), "kind": "slush"})


static func build_freedom_area(m: Node2D) -> void:
	m.freedom_kind = String(m.FREEDOM_KINDS.get(m.lvl, "yard"))
	m.water.clear()
	if m.pond.size.x > 0.0:
		m.water.append(m.pond)
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
		"street", "rain": wall_sides = [-1.0]
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
	for c in m.cellars:
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


static func spawn_junk(m: Node2D, at: Vector2, kind: String) -> void:
	var jn := Node2D.new()
	jn.set_script(load("res://entities/cone.gd"))
	jn.position = at
	jn.z_index = 11
	m.add_child(jn)
	jn.setup(m, m.dog, m.human, kind)
