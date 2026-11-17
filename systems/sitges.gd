class_name Sitges
extends RefCounted

# WALK 39: SITGES, the whitewashed seaside town south of Barcelona, walked on
# a windy afternoon along Passeig de la Ribera, past the palms and the cove,
# round the bend where big waves clear the seawall, up the stone steps to
# La Punta and Sant Bartomeu i Santa Tecla on its rock above the sea, then
# down onto Platja de la Fragata off the leash.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const Panot := preload("res://world/panot.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EdgePath := preload("res://world/edge_path.gd")
const Passeig := preload("res://systems/passeig.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const CurrentFlow := preload("res://systems/current_flow.gd")
const NearMiss := preload("res://systems/near_miss.gd")
const SkyLook := preload("res://systems/sky.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")
const Sunhat := preload("res://entities/sunhat.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const OVERHEAD_FOLLOWS_CAMERA := true
const HALF := 270.0
const START := 260.0
const GATE := -5000.0
const EAST_WALL := 910.0

# Key landmarks and stretches
const KITE_BAY_Y0 := -1320.0
const KITE_BAY_Y1 := -1600.0
const KITE_POS := Vector2(444.0, -1460.0)

const WAVE_Y0 := -2620.0
const WAVE_Y1 := -2180.0
const WAVE_WALL_X := 445.0
const WAVE_REACH_X := 770.0     # dry sanctuary strip from 770..910 along east houses
const WAVE_WARN_S := 0.95       # >= 0.8 s telegraph (spray plume before wash)
const WAVE_WASH_S := 2.10
const WAVE_RECEDE_S := 1.15
const WAVE_COOLDOWN_S := 4.40

const STEPS_UP_Y0 := -3520.0
const STEPS_UP_Y1 := -3840.0
const PUNTA_Y0 := -3840.0
const PUNTA_Y1 := -4620.0
const STEPS_DN_Y0 := -4620.0
const STEPS_DN_Y1 := -4900.0

const CHURCH_RECT := Rect2(684.0, -4480.0, 226.0, 430.0)
const BELL_POS := Vector2(720.0, -4375.0)
const BELL_BARK_R := 195.0
const PRIZE := Vector2(658.0, -4300.0)
const PRIZE_TEXT := "snatch the plate of xató off the beach bar"

const NAPKIN_MAX := 10
const NAPKIN_CATCH_R := 26.0
const HAT_BLOW_Y := -1120.0
const HAT_WARN_S := 0.85

# Palette — Sitges Mediterranean bright stone, whitewash, cobalt shutters, ochre church
const SEA_DEEP := Color(0.08, 0.34, 0.56)
const SEA_MID := Color(0.11, 0.45, 0.66)
const SEA_SHALLOW := Color(0.18, 0.60, 0.74)
const SEA_FOAM := Color(0.92, 0.96, 0.98)
const SAND_WET := Color(0.76, 0.68, 0.50)
const SAND_DRY := Color(0.91, 0.84, 0.64)
const SAND_LIGHT := Color(0.95, 0.89, 0.72)
const PAVE_WARM := Color(0.84, 0.79, 0.70)
const PAVE_STONE := Color(0.78, 0.75, 0.69)
const PANOT_INK := Color(0.68, 0.63, 0.54, 0.45)
const PANOT_SHINE := Color(0.92, 0.88, 0.80, 0.35)
const ROCK_DARK := Color(0.62, 0.58, 0.50)
const ROCK_MID := Color(0.76, 0.72, 0.63)
const ROCK_TOP := Color(0.86, 0.82, 0.74)
const WHITEWASH := Color(0.96, 0.95, 0.92)
const WHITE_SHADE := Color(0.85, 0.84, 0.82)
const SITGES_BLUE := Color(0.14, 0.42, 0.74)
const SITGES_BLUE_DK := Color(0.09, 0.28, 0.52)
const OCHRE_STONE := Color(0.84, 0.68, 0.42)
const OCHRE_DARK := Color(0.68, 0.52, 0.30)
const BOUGAINVILLEA := Color(0.84, 0.16, 0.48)
const BOUGAINVILLEA_LT := Color(0.94, 0.34, 0.62)
const LEAF_GREEN := Color(0.18, 0.44, 0.22)
const PALM_TRUNK := Color(0.46, 0.34, 0.22)
const PALM_FROND := Color(0.22, 0.52, 0.24)
const PALM_FROND_LT := Color(0.32, 0.64, 0.30)
const TERRACOTTA := Color(0.76, 0.38, 0.22)
const RAIL_BLUE := Color(0.16, 0.42, 0.68)
const SHADOW := Color(0.06, 0.08, 0.14, 0.20)
const DRINK_VERMUT := Color(0.58, 0.14, 0.12)
const DRINK_CAVA := Color(0.92, 0.84, 0.46)

const HOUSE_TILES: Array[Color] = [
	Color(0.76, 0.39, 0.24),
	Color(0.72, 0.35, 0.22),
	Color(0.80, 0.46, 0.28),
	Color(0.74, 0.42, 0.26),
]

const CAFE_YS: Array[float] = [-320.0, -640.0, -960.0, -1840.0, -2140.0, -3060.0, -3380.0]
const PALM_SPOTS: Array[Vector2] = [
	Vector2(458.0, -160.0), Vector2(458.0, -480.0), Vector2(458.0, -780.0), Vector2(458.0, -1080.0),
	Vector2(458.0, -1760.0), Vector2(458.0, -2020.0),
	Vector2(458.0, -2880.0), Vector2(458.0, -3180.0), Vector2(458.0, -3460.0),
	Vector2(534.0, -3910.0), Vector2(534.0, -4560.0),
]
const PARASOL_COLORS: Array[Color] = [
	Color(0.92, 0.34, 0.26), Color(0.16, 0.56, 0.78),
	Color(0.94, 0.72, 0.18), Color(0.22, 0.62, 0.44),
]

static var _nodes_cache: Array = []


static func _h(i: float, s: float = 1.0) -> float:
	var v := sin(i * 12.9898 + s * 78.233) * 43758.5453
	return v - floor(v)


static func _edge_node(y: float, lx: float, rx: float) -> Dictionary:
	return {"y": y, "cx": (lx + rx) * 0.5, "half": (rx - lx) * 0.5}


static func edge_nodes(_m: Node2D = null) -> Array:
	if _nodes_cache.is_empty():
		_nodes_cache = [
			_edge_node(360.0, 400.0, 910.0),
			_edge_node(-1260.0, 400.0, 910.0),
			_edge_node(-1360.0, 340.0, 910.0),
			_edge_node(-1560.0, 340.0, 910.0),
			_edge_node(-1660.0, 400.0, 910.0),
			_edge_node(-2120.0, 400.0, 910.0),
			_edge_node(-2260.0, 445.0, 910.0),
			_edge_node(-2600.0, 445.0, 910.0),
			_edge_node(-2740.0, 400.0, 910.0),
			_edge_node(-3520.0, 400.0, 910.0),
			_edge_node(-3840.0, 480.0, 910.0),
			_edge_node(-4620.0, 480.0, 910.0),
			_edge_node(-4900.0, 430.0, 930.0),
			_edge_node(-5080.0, 430.0, 930.0),
		]
	return _nodes_cache


static func edges_at(y: float) -> Vector2:
	return EdgePath.edges(edge_nodes(), y, 655.0, HALF)


static func shore_x(y: float) -> float:
	if y > -3520.0:
		var cov := sin(y * 0.0022) * 14.0
		if y < -2100.0 and y > -2760.0:
			cov += 18.0
		return 236.0 + cov
	if y > -4680.0:
		# waves cream right at the base of La Punta limestone cliff
		return 370.0 + sin(y * 0.015) * 14.0
	return 260.0 + (y + 4680.0) * 0.06


static func _wave_front_x(m: Node2D, y: float) -> float:
	var w: Dictionary = m.sitges_wave if m != null and m.get("sitges_wave") is Dictionary else {}
	if str(w.get("state", "wait")) != "wash":
		return -999.0
	if y < WAVE_Y0 or y > WAVE_Y1:
		return -999.0
	var t := float(w.get("t", 0.0))
	var frac := clampf(t / 0.45, 0.0, 1.0)
	if t > WAVE_WASH_S - 0.35:
		frac = clampf((WAVE_WASH_S - t) / 0.35, 0.0, 1.0)
	var span := sin(clampf((y - WAVE_Y0) / (WAVE_Y1 - WAVE_Y0), 0.0, 1.0) * PI)
	return lerpf(WAVE_WALL_X, WAVE_REACH_X, ease(frac, -1.6) * (0.65 + 0.35 * span))


static func solids(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = [CHURCH_RECT]
	# Seafront low walls / balustrade rails (broken open at Kite Bay ramp so beach stays reachable)
	out.append(Rect2(384.0, -1260.0, 14.0, 1620.0))     # +360 down to -1260
	out.append(Rect2(384.0, -2120.0, 14.0, 460.0))      # -1660 to -2120
	out.append(Rect2(429.0, -2600.0, 14.0, 340.0))      # seawall at the wave bend (-2260..-2600)
	out.append(Rect2(384.0, -3520.0, 14.0, 780.0))      # -2740 to -3520
	out.append(Rect2(340.0, -4620.0, 138.0, 780.0))     # La Punta cliff drop + balustrade (-3840..-4620)
	# East town facades & rock terraces strictly outside EAST_WALL (910)
	out.append(Rect2(912.0, -4880.0, 38.0, 5240.0))
	return out


static func wrap_rects(m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = [CHURCH_RECT]
	for r: Rect2 in solids(m):
		if r.position.x < 600.0:
			out.append(r)
	return out


static func build(m: Node2D) -> Array:
	m.water.assign([Rect2(-500.0, -5200.0, 725.0, 5700.0)])
	m.islands.append({"rect": CHURCH_RECT, "side": -1.0, "lead": 280.0})
	m.gate_text = "PLATJA DE LA FRAGATA"
	m.gate_l = 450.0
	m.gate_r = 890.0

	m.sitges_wave = {
		"state": "wait", "t": 0.0, "cooldown": 0.0,
		"threatened": false, "hit": false,
		"warned": false, "chime_t": 0.0,
		"hat_state": "ready", "hat_t": 0.0,
	}
	m.sitges_napkins = []
	m.sitges_waves_dodged = 0
	m.sitges_napkins_caught = 0
	m.sitges_church_barked = false
	m.sitges_diners = []
	m.sitges_tables_list = []

	# Palms (poles to wrap/mark + animated wind fronds in draw_overhead)
	for p: Vector2 in PALM_SPOTS:
		m.poles.append(p)
		m.trees.append(p)

	# Promenade & plaza iron lamp-posts (inside walk_edges, clear of church)
	for ly: float in [140.0, -340.0, -700.0, -1160.0, -1380.0, -1580.0, -1880.0, -2420.0, -3040.0, -3420.0, -3980.0, -4520.0]:
		var px := 788.0 if ly > -3600.0 else 650.0
		m.poles.append(Vector2(px, ly))
	m.deco_pole_count = m.poles.size()

	# Café tables on the east terrace (outside the dry wave sanctuary strip)
	for i in range(CAFE_YS.size()):
		var cy: float = CAFE_YS[i]
		var ta := Vector2(856.0, cy - 22.0)
		var tb := Vector2(856.0, cy + 28.0)
		for tpos: Vector2 in [ta, tb]:
			m.tables.append(tpos)
			m.sitges_tables_list.append(tpos)
			m.chairs.append(tpos + Vector2(-24.0, 0.0))
			m.chairs.append(tpos + Vector2(24.0, 0.0))
		if Outdoors.terrace_patrons(Game.weather, Game.hour):
			m.sitges_diners.append({"pos": ta + Vector2(-20.0, 0.0), "face": Vector2.RIGHT, "key": 900 + i * 2, "drink": i % 2})
			if i % 2 == 0:
				m.sitges_diners.append({"pos": tb + Vector2(20.0, 0.0), "face": Vector2.LEFT, "key": 901 + i * 2, "drink": (i + 1) % 2})

	# Promenade benches & seafront lookouts (all clear of wave path & church)
	m.benches.append(Vector2(506.0, -40.0))
	m.benches.append(Vector2(506.0, -640.0))
	m.benches.append(Vector2(506.0, -1200.0))
	m.benches.append(Vector2(506.0, -1900.0))
	m.benches.append(Vector2(832.0, -2420.0))     # dry-side bend bench overlooking wave splash
	m.benches.append(Vector2(506.0, -3260.0))
	m.benches.append(Vector2(548.0, -4180.0))     # La Punta sea outlook bench

	# Recycling / waste bins
	for bp: Vector2 in [
		Vector2(492.0, -280.0), Vector2(860.0, -820.0), Vector2(492.0, -1240.0),
		Vector2(860.0, -1660.0), Vector2(850.0, -2540.0), Vector2(492.0, -3080.0),
		Vector2(538.0, -4020.0), Vector2(538.0, -4580.0),
	]:
		m.bins.append(bp)

	# Drinking fountains (promenade + La Punta plaza)
	m.fountains.append(Vector2(746.0, -860.0))
	m.fountains.append(Vector2(792.0, -2040.0))
	m.fountains.append(Vector2(598.0, -4420.0))

	# Cast-iron hydrants (>= 3)
	var hyd_list: Array[Vector2] = [
		Vector2(760.0, -220.0),
		Vector2(520.0, -1380.0),
		Vector2(800.0, -2860.0),
		Vector2(620.0, -4080.0),
	]

	# Dropped snacks/churros/tapas along the café promenade (avoiding church & sand)
	var keb_list: Array[Vector2] = [
		Vector2(794.0, -340.0),
		Vector2(764.0, -660.0),
		Vector2(804.0, -980.0),
		Vector2(780.0, -1860.0),
		Vector2(812.0, -2160.0),
		Vector2(790.0, -3080.0),
		Vector2(620.0, -4240.0),
	]

	# Seaside buskers / street performers on wide promenade spots
	m.performers.append(Vector2(690.0, -1080.0))
	m.performers.append(Vector2(590.0, -4320.0))

	# Cones & loose beach bottles/balls (extra bottles/balls in wave wash -2560..-2240!)
	for cp: Vector2 in [
		Vector2(580.0, -120.0), Vector2(610.0, -1650.0),
		Vector2(520.0, -2260.0), Vector2(560.0, -2380.0), Vector2(535.0, -2490.0), Vector2(610.0, -2550.0),
		Vector2(650.0, -3140.0), Vector2(595.0, -4460.0),
	]:
		m.cone_spots.append(cp)

	# Park props (>= 8, with >= 2 dig, >= 1 solid, >= 3 markable)
	m.park_props.append({"pos": Vector2(440.0, -1380.0), "kind": "sandpile", "dig": true, "solid": false, "mark": false})
	m.park_props.append({"pos": Vector2(416.0, -1520.0), "kind": "driftwood", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(490.0, -1540.0), "kind": "sandpile", "dig": true, "solid": false, "mark": false})
	m.park_props.append({"pos": Vector2(560.0, -280.0), "kind": "bollard", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(560.0, -880.0), "kind": "planter", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(620.0, -1720.0), "kind": "bollard", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(630.0, -2780.0), "kind": "planter", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(560.0, -3420.0), "kind": "bollard", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(616.0, -4120.0), "kind": "planter", "dig": false, "solid": true, "mark": true})
	m.park_props.append({"pos": Vector2(520.0, -4960.0), "kind": "sandpile", "dig": true, "solid": false, "mark": false})

	# Beach towels on Platja de la Ribera sand cove (outside sea water)
	if Outdoors.sunbathers(Game.weather, Game.hour) or Game.weather == "wind":
		for i in range(6):
			var ty := -260.0 - float(i) * 320.0
			if ty < -1240.0 and ty > -1640.0:
				ty -= 460.0
			var tx := 296.0 + float((i * 19) % 36)
			m.towels.append({
				"pos": Vector2(tx, ty),
				"rect": Rect2(tx - 13.0, ty - 24.0, 26.0, 48.0),
				"col": PARASOL_COLORS[i % PARASOL_COLORS.size()],
				"bather": Outdoors.sunbathers(Game.weather, Game.hour) and (i % 3) != 2,
				"cd": 0.0,
			})

	return [hyd_list, keb_list]


static func surface(m: Node2D, p: Vector2) -> int:
	if p.x < shore_x(p.y):
		return Surfaces.S.WATER
	# Active wave wash across the bend acts as water so splashes & wetting agree
	if p.y >= WAVE_Y0 and p.y <= WAVE_Y1 and p.x >= WAVE_WALL_X - 4.0 and p.x <= _wave_front_x(m, p.y):
		return Surfaces.S.WATER
	# Fragata off-leash beach below north steps
	if p.y <= STEPS_DN_Y1:
		return Surfaces.S.SAND
	# Steps descending off La Punta onto Fragata: firm stone -> PAVEMENT
	if p.y <= PUNTA_Y1 and p.y > STEPS_DN_Y1:
		return Surfaces.S.PAVEMENT
	# La Punta headland plaza & cliff rock: firm stone -> PAVEMENT (never grass)
	if p.y <= PUNTA_Y0 and p.y > PUNTA_Y1:
		return Surfaces.S.PAVEMENT
	# Steps up to La Punta
	if p.y <= STEPS_UP_Y0 and p.y > STEPS_UP_Y1:
		return Surfaces.S.PAVEMENT
	# Kite bay sand apron inside walk_edges (-1320..-1600, x < 474)
	if p.y <= KITE_BAY_Y0 and p.y >= KITE_BAY_Y1 and p.x < 474.0:
		return Surfaces.S.SAND
	# Ribera beach strip west of the promenade retaining wall
	var e := edges_at(p.y)
	if p.x < e.x:
		return Surfaces.S.SAND
	return Surfaces.S.PAVEMENT


static func takes_prints(m: Node2D, p: Vector2) -> bool:
	return m.surface_at(p) == Surfaces.S.SAND


static func tree_kind(_m: Node2D, _p: Vector2) -> int:
	return 0     # sitges draws its own wind-leaning palms + animated fronds in draw_live/draw_overhead


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return p.x > 640.0


# --- live gameplay: wave break, wind gust & hat, blowing napkins -------------

static func tick(m: Node2D, delta: float) -> void:
	var w: Dictionary = m.sitges_wave
	if float(w.get("chime_t", 0.0)) > 0.0:
		w["chime_t"] = maxf(0.0, float(w["chime_t"]) - delta)
	_tick_wave(m, delta)
	_tick_hat_gust(m, delta)
	_tick_napkins(m, delta)


static func _tick_wave(m: Node2D, delta: float) -> void:
	var w: Dictionary = m.sitges_wave
	var dog_y: float = m.dog.global_position.y
	var hum_y: float = m.human.global_position.y
	var near := minf(dog_y, hum_y) < WAVE_Y1 + 260.0 and maxf(dog_y, hum_y) > WAVE_Y0 - 260.0
	var st: String = str(w.get("state", "wait"))

	match st:
		"wait":
			if float(w.get("cooldown", 0.0)) > 0.0:
				w["cooldown"] = float(w["cooldown"]) - delta
			elif near:
				w["state"] = "spray"
				w["t"] = 0.0
				var hy: float = m.human.global_position.y
				w["threatened"] = hy <= WAVE_Y1 + 40.0 and hy >= WAVE_Y0 - 40.0 and m.human.global_position.x < WAVE_REACH_X + 12.0
				w["hit"] = false
				w["warned"] = false
				Sfx.play("hiss", 0.55, -8.0)
		"spray":
			w["t"] = float(w["t"]) + delta
			var dy: float = m.human.global_position.y
			if dy <= WAVE_Y1 + 40.0 and dy >= WAVE_Y0 - 40.0 and m.human.global_position.x < WAVE_REACH_X + 12.0:
				w["threatened"] = true
			if not bool(w.get("warned", false)) and m.human.global_position.distance_to(Vector2(540.0, -2400.0)) < 460.0:
				w["warned"] = true
				m.float_text(m.human.global_position + Vector2(0.0, -34.0), "BIG WAVE! PULL CLEAR!", Color(0.90, 0.96, 1.0), m.POP_SAY)
			if float(w["t"]) >= WAVE_WARN_S:
				w["state"] = "wash"
				w["t"] = 0.0
				Sfx.play("splash", 0.9, -4.0)
		"wash":
			w["t"] = float(w["t"]) + delta
			var push_dir := Vector2(1.0, 0.14).normalized()
			var hpos: Vector2 = m.human.global_position
			var dpos: Vector2 = m.dog.global_position
			var hfx := _wave_front_x(m, hpos.y)
			var dfx := _wave_front_x(m, dpos.y)
			var h_in := hpos.y >= WAVE_Y0 and hpos.y <= WAVE_Y1 and hpos.x >= WAVE_WALL_X - 8.0 and hpos.x <= hfx
			var d_in := dpos.y >= WAVE_Y0 and dpos.y <= WAVE_Y1 and dpos.x >= WAVE_WALL_X - 8.0 and dpos.x <= dfx
			if hpos.y >= WAVE_Y0 - 40.0 and hpos.y <= WAVE_Y1 + 40.0 and hpos.x < WAVE_REACH_X + 12.0:
				w["threatened"] = true
			if h_in:
				w["hit"] = true
				m.human_soak = minf(1.0, float(m.human_soak) + delta * 0.45)
				CurrentFlow.shove_body(m.human, true, push_dir, 145.0, 60.0, false, delta)
			if d_in:
				m.dog.slick = true
				CurrentFlow.shove_body(m.dog, true, push_dir, 180.0, 50.0, m.dog.planted, delta)
			# Slide loose bottles/balls/cones eastward with the wave
			if m.get_tree() != null:
				for c in m.get_tree().get_nodes_in_group("cones"):
					if is_instance_valid(c):
						var cp: Vector2 = c.global_position
						if cp.y >= WAVE_Y0 and cp.y <= WAVE_Y1 and cp.x >= WAVE_WALL_X and cp.x <= _wave_front_x(m, cp.y):
							c.vel = c.vel.lerp(push_dir * 220.0, clampf(delta * 8.0, 0.0, 1.0))
							c.spin += delta * 6.0
			# Slide napkins inside the wash eastward too
			for n: Dictionary in m.sitges_napkins:
				var np: Vector2 = n.pos
				if np.y >= WAVE_Y0 and np.y <= WAVE_Y1 and np.x >= WAVE_WALL_X and np.x <= _wave_front_x(m, np.y):
					n["vel"] = (n.vel as Vector2).lerp(push_dir * 240.0, clampf(delta * 10.0, 0.0, 1.0))
			if float(w["t"]) >= WAVE_WASH_S:
				var close_now := hpos.y >= WAVE_Y0 - 40.0 and hpos.y <= WAVE_Y1 + 40.0 and hpos.x < WAVE_REACH_X + 12.0
				var nm: Dictionary = NearMiss.consider(close_now, bool(w.get("hit", false)), bool(w.get("threatened", false)), false)
				if bool(nm.get("dodge", false)):
					m.sitges_waves_dodged += 1
					m.combo.add("WAVE DODGED", 45)
					m.award_points(45, "stayed dry! +45")
					m.float_text(hpos + Vector2(0.0, -34.0), "Missed me!", Color(0.75, 0.96, 1.0), m.POP_SAY)
				w["state"] = "recede"
				w["t"] = 0.0
		"recede":
			w["t"] = float(w["t"]) + delta
			if float(w["t"]) >= WAVE_RECEDE_S:
				w["state"] = "wait"
				w["t"] = 0.0
				w["cooldown"] = WAVE_COOLDOWN_S


static func _tick_hat_gust(m: Node2D, delta: float) -> void:
	if m.auto_walk or Game.night or m.human.hat_off:
		return
	var w: Dictionary = m.sitges_wave
	var hs: String = str(w.get("hat_state", "ready"))
	if hs == "done" or Outdoors.wind_strength(Game.weather) < 0.85:
		return
	if hs == "ready":
		var hy_hat: float = m.human.global_position.y
		if hy_hat <= HAT_BLOW_Y and hy_hat >= HAT_BLOW_Y - 260.0 and not m.human.is_fallen():
			w["hat_state"] = "warn"
			w["hat_t"] = 0.0
			m.float_text(m.human.global_position + Vector2(0.0, -34.0), "Hold onto that hat!", Color(1.0, 0.96, 0.88), m.POP_SAY)
	elif hs == "warn":
		w["hat_t"] = float(w["hat_t"]) + delta
		if float(w["hat_t"]) >= HAT_WARN_S:
			w["hat_state"] = "done"
			if not m.human.is_fallen():
				m.human.hat_off = true
				var hat := Node2D.new()
				hat.set_script(Sunhat)
				m.add_child(hat)
				hat.setup(m, m.human.global_position + Vector2(0.0, -6.0), Vector2(1.0, -0.24).normalized() * 210.0)
				Sfx.play("hiss", 0.7, -6.0)


static func _tick_napkins(m: Node2D, delta: float) -> void:
	if not Outdoors.blowing_napkins(Game.weather, Game.hour):
		m.sitges_napkins.clear()
		return
	var w_mul := Outdoors.wind_strength(Game.weather)
	var base_vel := Vector2(125.0, -32.0) * w_mul
	if m.sitges_napkins.size() < NAPKIN_MAX:
		for i in range(NAPKIN_MAX - m.sitges_napkins.size()):
			var idx: int = m.sitges_napkins.size() + i
			var cy: float = CAFE_YS[idx % CAFE_YS.size()] + (_h(float(idx), 7.0) - 0.5) * 180.0
			m.sitges_napkins.append({
				"pos": Vector2(460.0 + _h(float(idx), 2.0) * 320.0, cy),
				"vel": base_vel + Vector2((_h(float(idx), 3.0) - 0.5) * 30.0, (_h(float(idx), 4.0) - 0.5) * 28.0),
				"spin": _h(float(idx), 5.0) * TAU,
				"hop": _h(float(idx), 6.0) * TAU,
			})
	var dpos: Vector2 = m.dog.global_position
	var i: int = m.sitges_napkins.size() - 1
	while i >= 0:
		var n: Dictionary = m.sitges_napkins[i]
		n["vel"] = (n.vel as Vector2).lerp(base_vel + Vector2(0.0, sin(float(n.hop)) * 26.0), clampf(delta * 2.4, 0.0, 1.0))
		n["pos"] = (n.pos as Vector2) + (n.vel as Vector2) * delta
		n["spin"] = float(n.spin) + delta * (3.2 + 1.8 * w_mul)
		n["hop"] = float(n.hop) + delta * 5.0
		var np: Vector2 = n.pos
		var e := edges_at(np.y)
		if np.x > e.y - 16.0 or np.x < e.x - 10.0 or np.y < GATE + 120.0 or np.y > START + 40.0:
			var rcy: float = CAFE_YS[(i + int(absf(float(m.elapsed) * 3.0))) % CAFE_YS.size()]
			n["pos"] = Vector2(e.x + 30.0 + _h(float(i), float(m.elapsed)) * 140.0, rcy + 40.0)
			n["vel"] = base_vel
		if dpos.distance_to(n.pos as Vector2) < NAPKIN_CATCH_R and not m.dog.is_tumbling():
			m.sitges_napkins_caught += 1
			m.combo.add("NAPKIN", 20)
			m.award_points(20, "caught napkin! +20")
			Sfx.play("rustle", 1.15, -5.0)
			var rcy: float = CAFE_YS[(i + 2) % CAFE_YS.size()]
			n["pos"] = Vector2(edges_at(rcy).x + 40.0, rcy + 50.0)
			n["vel"] = base_vel
		i -= 1


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> bool:
	var p: Vector2 = m.dog.global_position if pos == Vector2.ZERO else pos
	if p.distance_to(BELL_POS) <= BELL_BARK_R:
		var w: Dictionary = m.sitges_wave
		w["chime_t"] = 1.4
		Sfx.play("church_bell", 1.0, -3.0)
		if not bool(m.sitges_church_barked):
			m.sitges_church_barked = true
			m.combo.add("CHURCH BELL", 40)
			m.award_points(40, "la Punta bell! +40")
			m.float_text(BELL_POS + Vector2(-46.0, 12.0), "CLANG!", Color(1.0, 0.92, 0.62), m.POP_SAY)
		else:
			m.float_text(BELL_POS + Vector2(-46.0, 12.0), "clang", Color(0.95, 0.90, 0.72), m.POP_SAY)
		return true
	return false


static func idle_status(m: Node2D) -> String:
	var w: Dictionary = m.sitges_wave
	if str(w.get("state", "wait")) == "spray" and absf(m.dog.global_position.y - -2400.0) < 360.0:
		return "WAVE INCOMING! GET INLAND!"
	if m.dog.global_position.y < PUNTA_Y0 and m.dog.global_position.y > PUNTA_Y1 and not m.sitges_church_barked:
		return "SANT BARTOMEU: BARK FOR THE BELL!"
	return ""


# --- ground & sea cross-section (recorded once per chunk) -----------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, maxf(ctop, float(m.GATE_Y) - 260.0))
	var hi := minf(vb + 40.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_ground(m, wc, lo, hi)
	wc.lod = keep_lod


static func _promenade_poly(lo: float, hi: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := hi
	while true:
		var e := edges_at(y)
		left.append(Vector2(e.x, y))
		right.append(Vector2(e.y, y))
		if y <= lo:
			break
		y = maxf(lo, y - 80.0)
	right.reverse()
	left.append_array(right)
	return left


static func _ground(m: Node2D, wc: ShapeBatch, lo: float, hi: float) -> void:
	# 1. Open sea on the west, stepping gently into shallower turquoise near shore
	wc.rect(Rect2(-520.0, lo, 940.0, hi - lo), SEA_DEEP)
	wc.rect(Rect2(70.0, lo, 290.0, hi - lo), SEA_MID)
	wc.rect(Rect2(160.0, lo, 260.0, hi - lo), SEA_SHALLOW)

	# 2. Ribera dry sand & Fragata beach (and kite bay apron)
	var sand_lo := maxf(lo, STEPS_DN_Y1)
	if hi > STEPS_UP_Y1:
		wc.rect(Rect2(236.0, maxf(lo, STEPS_UP_Y0), 210.0, hi - maxf(lo, STEPS_UP_Y0)), SAND_WET)
		wc.rect(Rect2(268.0, maxf(lo, STEPS_UP_Y0), 210.0, hi - maxf(lo, STEPS_UP_Y0)), SAND_DRY)
	if lo < STEPS_DN_Y1:
		var frag_col := Color(0.88, 0.81, 0.64)
		wc.rect(Rect2(236.0, lo, 1460.0, minf(hi, STEPS_DN_Y1) - lo), SAND_DRY)
		wc.rect(Rect2(268.0, lo, 1420.0, minf(hi, STEPS_DN_Y1) - lo), frag_col)
	if lo < KITE_BAY_Y0 and hi > KITE_BAY_Y1:
		var by0 := maxf(lo, KITE_BAY_Y1)
		var by1 := minf(hi, KITE_BAY_Y0)
		wc.rect(Rect2(268.0, by0, 212.0, by1 - by0), SAND_DRY)
		wc.rect(Rect2(340.0, by0, 134.0, by1 - by0), SAND_LIGHT)

	# 3. Promenade paving from START down to STEPS_UP_Y0 (3520), stopping outside Kite Bay sand
	if hi > STEPS_UP_Y0:
		var plo := maxf(lo, STEPS_UP_Y0)
		var phi := hi
		wc.polygon(_promenade_poly(plo, phi), PAVE_WARM)
		# Keep Kite Bay sand exposed west of 474
		if plo < KITE_BAY_Y0 and phi > KITE_BAY_Y1:
			var k0 := maxf(plo, KITE_BAY_Y1)
			var k1 := minf(phi, KITE_BAY_Y0)
			wc.rect(Rect2(340.0, k0, 134.0, k1 - k0), SAND_LIGHT)
		# Panot strip along the east promenade café zone
		Panot.flor(wc, 740.0, EAST_WALL, plo, phi, PANOT_INK, PANOT_SHINE)
		# Promenade curb / seafront stone sill along west edge
		var sy := ceilf(plo / 60.0) * 60.0
		while sy < phi:
			var e := edges_at(sy)
			if not (sy <= KITE_BAY_Y0 and sy >= KITE_BAY_Y1):
				wc.rect(Rect2(e.x - 10.0, sy - 60.0, 12.0, 60.0), PAVE_STONE)
				wc.line(Vector2(e.x + 2.0, sy - 60.0), Vector2(e.x + 2.0, sy), Color(0.62, 0.56, 0.48), 1.4)
			else:
				# Timber boardwalk ramp into the kite bay
				if absf(sy - (-1460.0)) < 36.0:
					Passeig._access_ramp(m, wc, 474.0, 412.0, -1460.0, 34.0)
			sy += 60.0

	# 4. La Punta limestone rock headland & cliff face (3520..4900)
	if lo < STEPS_UP_Y0 and hi > STEPS_DN_Y1:
		var rlo := maxf(lo, STEPS_DN_Y1)
		var rhi := minf(hi, STEPS_UP_Y0)
		# Craggy pale stone cliff ledges dipping west into the sea
		wc.rect(Rect2(358.0, rlo, 140.0, rhi - rlo), ROCK_DARK)
		wc.rect(Rect2(394.0, rlo, 110.0, rhi - rlo), ROCK_MID)
		wc.rect(Rect2(436.0, rlo, 76.0, rhi - rlo), ROCK_TOP)
		var ry := ceilf(rlo / 48.0) * 48.0
		while ry < rhi:
			var jag := _h(ry, 11.0) * 28.0
			wc.polygon(PackedVector2Array([
				Vector2(344.0 + jag, ry - 44.0),
				Vector2(448.0, ry - 48.0),
				Vector2(448.0, ry),
				Vector2(336.0 + _h(ry + 12.0, 13.0) * 32.0, ry),
			]), ROCK_MID)
			wc.line(Vector2(362.0 + jag, ry - 22.0), Vector2(468.0, ry - 18.0), ROCK_DARK, 2.0)
			ry += 48.0
		# La Punta main stone plaza
		wc.polygon(_promenade_poly(rlo, rhi), PAVE_STONE)
		Panot.flor(wc, 560.0, 684.0, maxf(rlo, PUNTA_Y1), minf(rhi, PUNTA_Y0), PANOT_INK, PANOT_SHINE)

	# 5. Broad stone staircases onto and off La Punta
	if lo < STEPS_UP_Y0 and hi > STEPS_UP_Y1:
		_draw_steps(wc, maxf(lo, STEPS_UP_Y1), minf(hi, STEPS_UP_Y0), true)
	if lo < STEPS_DN_Y0 and hi > STEPS_DN_Y1:
		_draw_steps(wc, maxf(lo, STEPS_DN_Y1), minf(hi, STEPS_DN_Y0), false)

	# 6. Beach towels on Ribera cove sand
	if m.get("towels") is Array:
		for i in range(m.towels.size()):
			var tw: Dictionary = m.towels[i]
			var tr: Rect2 = tw.rect
			if tr.end.y >= lo - 20.0 and tr.position.y <= hi + 20.0:
				var tcol: Color = tw.col
				wc.rect(tr, tcol)
				wc.rect(Rect2(tr.position.x, tr.position.y + 7.0, tr.size.x, 4.0), Color(1.0, 1.0, 1.0, 0.55))
				wc.rect(Rect2(tr.position.x, tr.end.y - 11.0, tr.size.x, 4.0), Color(1.0, 1.0, 1.0, 0.55))
				if bool(tw.get("bather", false)):
					var c := tr.get_center()
					wc.capsule(c + Vector2(0.0, -8.0), c + Vector2(0.0, 14.0), 5.5, Passeig.TOWEL_SKINS[i % 4])
					wc.rect(Rect2(c.x - 5.5, c.y + 1.0, 11.0, 6.0), Passeig.TOWEL_SUITS[i % 4])
					wc.circle(c + Vector2(0.0, -17.0), 5.0, Passeig.TOWEL_HAIR[i % 4])

	# 7. Windblown sand wisps over seaward paving edges (reuse Passeig look)
	var wy := ceilf(maxf(lo, -3460.0) / 70.0) * 70.0
	while wy < minf(hi, START + 200.0):
		if _h(wy, 19.0) < 0.42:
			var ex := edges_at(wy).x
			wc.capsule(Vector2(ex, wy), Vector2(ex + 26.0 + _h(wy, 21.0) * 34.0, wy - 8.0), 3.0, Color(0.92, 0.85, 0.65, 0.36))
		wy += 70.0


static func _draw_steps(wc: ShapeBatch, lo: float, hi: float, climbing: bool) -> void:
	var y := lo
	while y < hi:
		var e := edges_at(y)
		var w := e.y - e.x
		wc.rect(Rect2(e.x, y, w, 18.0), Color(0.68, 0.64, 0.56))
		wc.rect(Rect2(e.x, y + (15.0 if climbing else 0.0), w, 3.0), Color(0.42, 0.39, 0.33))
		y += 22.0


# --- east houses, shutters, bougainvillea & church facade backdrop ----------

static func draw_edge_layer(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	var lo := maxf(vt - 280.0, GATE - 40.0)
	var hi := minf(vb + 280.0, START + 560.0)
	if hi > lo:
		# Coastal town wall base ends cleanly before Platja de la Fragata (-4720)
		var town_lo := maxf(lo, -4900.0)
		if hi > town_lo:
			b.rect(Rect2(EAST_WALL, town_lo, 620.0, hi - town_lo), WHITEWASH)
		# East church transept & whitewashed parish cloister behind La Punta
		if lo < CHURCH_RECT.end.y + 40.0 and hi > CHURCH_RECT.position.y - 40.0:
			var apse := Rect2(EAST_WALL, CHURCH_RECT.position.y + 34.0, 210.0, CHURCH_RECT.size.y - 68.0)
			b.rect(apse, WHITEWASH)
			b.rect(apse.grow(-14.0), TERRACOTTA)
			b.circle(Vector2(apse.end.x - 18.0, apse.get_center().y), 36.0, TERRACOTTA.darkened(0.08))
			b.line(Vector2(apse.position.x, apse.get_center().y), Vector2(apse.end.x - 16.0, apse.get_center().y), TERRACOTTA.lightened(0.18), 5.0)
		var plot_y := floorf(maxf(lo, -4680.0) / 150.0) * 150.0
		var idx := int(absf(plot_y) / 150.0)
		var town_hi := minf(hi, START + 560.0)
		while plot_y < town_hi:
			var y0 := plot_y
			var y1 := plot_y + 150.0
			if y1 > -4680.0 and not (y1 > CHURCH_RECT.position.y - 30.0 and y0 < CHURCH_RECT.end.y + 30.0):
				var tile: Color = HOUSE_TILES[idx % HOUSE_TILES.size()]
				var depth := 220.0 + _h(float(idx), 5.0) * 80.0
				b.rect(Rect2(EAST_WALL + 4.0, y0 + 2.0, depth, 146.0), tile)
				# Barrel-tile light & shadow flutes
				for rx in range(6):
					var lx := EAST_WALL + 16.0 + float(rx) * 34.0
					b.rect(Rect2(lx, y0 + 3.0, 8.0, 144.0), tile.lightened(0.08))
					b.line(Vector2(lx + 16.0, y0 + 4.0), Vector2(lx + 16.0, y1 - 4.0), tile.darkened(0.16), 2.0)
				# Whitewash terrace parapets + chimney pot
				b.rect(Rect2(EAST_WALL - 8.0, y0 + 2.0, 14.0, 146.0), WHITEWASH)
				b.rect(Rect2(EAST_WALL - 14.0, y0 + 6.0, 8.0, 138.0), SHADOW)
				b.rect(Rect2(EAST_WALL + 64.0, y0 + 18.0 + _h(float(idx), 3.0) * 60.0, 18.0, 18.0), WHITE_SHADE)
				# Cobalt-blue shutters sticking cleanly from whitewash windows
				for wy_off: float in [32.0, 108.0]:
					var sy := y0 + wy_off
					b.rect(Rect2(EAST_WALL - 3.0, sy - 11.0, 9.0, 22.0), SITGES_BLUE_DK)
					b.rect(Rect2(EAST_WALL + 1.0, sy - 10.0, 5.0, 9.0), SITGES_BLUE)
					b.rect(Rect2(EAST_WALL + 1.0, sy + 1.0, 5.0, 9.0), SITGES_BLUE)
				# Wrought-iron balcony + cascading magenta bougainvillea over the facade edge
				if _h(float(idx), 9.0) < 0.78:
					var by := y0 + 70.0
					b.rect(Rect2(EAST_WALL - 15.0, by - 22.0, 16.0, 44.0), Color(0.16, 0.18, 0.22))
					b.rect(Rect2(EAST_WALL - 13.0, by - 20.0, 12.0, 40.0), Color(0.84, 0.82, 0.78))
					b.circle(Vector2(EAST_WALL - 14.0, by - 12.0), 11.0, LEAF_GREEN)
					b.circle(Vector2(EAST_WALL - 16.0, by + 4.0), 12.0, LEAF_GREEN)
					b.circle(Vector2(EAST_WALL - 15.0, by - 13.0), 6.5, BOUGAINVILLEA)
					b.circle(Vector2(EAST_WALL - 12.0, by + 2.0), 7.5, BOUGAINVILLEA_LT)
					b.circle(Vector2(EAST_WALL - 20.0, by + 9.0), 5.5, BOUGAINVILLEA)
			idx += 1
			plot_y += 150.0
	b.lod = keep_lod


# --- live ground-level details: surf, railings, parasols, wave, church, palms, napkins ---

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	var t_sec := float(AnimClock.msec()) * 0.001

	# 1. Animated Mediterranean surf & foam crests along shore_x
	var wy := floorf(maxf(vt - 40.0, GATE - 40.0) / 28.0) * 28.0
	var whi := minf(vb + 40.0, START + 220.0)
	while wy < whi:
		var sx := shore_x(wy) + sin(t_sec * 2.1 + wy * 0.025) * 8.0
		var nx := shore_x(wy + 28.0) + sin(t_sec * 2.1 + (wy + 28.0) * 0.025) * 8.0
		b.line(Vector2(sx, wy), Vector2(nx, wy + 28.0), SEA_FOAM, 9.0 + 3.0 * cos(t_sec * 1.7 + wy * 0.03))
		b.line(Vector2(sx - 38.0, wy + 4.0), Vector2(nx - 34.0, wy + 24.0), Color(1.0, 1.0, 1.0, 0.32), 2.2)
		wy += 28.0

	# 2. Beach parasols on Ribera sand cove
	var parasols_open := Outdoors.beach_parasols_open(Game.weather, Game.hour)
	for i in range(6):
		var py := -220.0 - float(i) * 320.0
		if py < vt - 60.0 or py > vb + 60.0:
			continue
		if py < -1240.0 and py > -1640.0:
			py -= 460.0
		var px := 284.0 + float((i * 23) % 34)
		var col: Color = PARASOL_COLORS[i % PARASOL_COLORS.size()]
		if parasols_open:
			b.circle(Vector2(px + 6.0, py + 7.0), 22.0, SHADOW)
			b.circle(Vector2(px, py), 22.0, col)
			for q in range(4):
				var ang := float(q) * PI * 0.5 + float(i) * 0.3
				b.polygon(PackedVector2Array([
					Vector2(px, py),
					Vector2(px, py) + Vector2.from_angle(ang) * 22.0,
					Vector2(px, py) + Vector2.from_angle(ang + PI * 0.25) * 22.0,
				]), Color(0.98, 0.96, 0.90))
			b.circle(Vector2(px, py), 3.0, OCHRE_DARK)
		else:
			# Furled parasol in wind / night / rain
			b.capsule(Vector2(px - 2.0, py - 10.0), Vector2(px + 2.0, py + 10.0), 4.0, col.darkened(0.2))

	# 3. Seafront railings & low parapets along solids (draw crisp 14 px coping along walkway edge)
	for r: Rect2 in solids(m):
		if r.position.x < 600.0 and r.end.y >= vt - 40.0 and r.position.y <= vb + 40.0:
			var rail := Rect2(r.end.x - 14.0, r.position.y, 14.0, r.size.y)
			b.rect(Rect2(rail.position + Vector2(3.0, 4.0), rail.size), SHADOW)
			b.rect(rail, WHITEWASH)
			b.rect(Rect2(rail.position.x + 2.0, rail.position.y, 4.0, rail.size.y), RAIL_BLUE)
			var post_y := rail.position.y + 18.0
			while post_y < rail.end.y - 8.0:
				b.circle(Vector2(rail.get_center().x, post_y), 4.5, RAIL_BLUE.darkened(0.15))
				post_y += 56.0

	# 4. Wind-leaning palm trunks & sandy root plinths
	for p: Vector2 in PALM_SPOTS:
		if p.y < vt - 80.0 or p.y > vb + 80.0:
			continue
		var lean := Vector2(18.0 + sin(t_sec * 2.4 + p.y * 0.02) * 3.0, -28.0)
		b.circle(p, 14.0, Color(0.68, 0.62, 0.50))
		b.circle(p, 11.0, SAND_DRY)
		b.line(p + Vector2(6.0, 5.0), p + lean + Vector2(14.0, 12.0), SHADOW, 7.0)
		b.line(p, p + lean, PALM_TRUNK, 9.0)
		b.circle(p + lean, 5.5, PALM_TRUNK.lightened(0.12))

	# 5. Live breaking wave spray & wash at the bend
	_draw_wave(m, b, vt, vb, t_sec)

	# 6. Church of Sant Bartomeu i Santa Tecla base walls, steps & prize bowl
	if CHURCH_RECT.end.y >= vt - 80.0 and CHURCH_RECT.position.y <= vb + 80.0:
		_draw_church_base(m, b)
	if not bool(m.prize_taken) and PRIZE.y >= vt - 40.0 and PRIZE.y <= vb + 40.0:
		b.glow(PRIZE, 20.0, Color(1.0, 0.88, 0.50, 0.25))
		b.circle(PRIZE + Vector2(2.0, 2.0), 8.0, SHADOW)
		b.circle(PRIZE, 8.0, Color(0.95, 0.94, 0.88))
		b.circle(PRIZE, 5.5, Color(0.32, 0.60, 0.26))
		b.circle(PRIZE + Vector2(1.0, -1.0), 3.0, Color(0.84, 0.34, 0.16))

	# 7. Blowing café napkins along the promenade
	for n: Dictionary in m.sitges_napkins:
		var np: Vector2 = n.pos
		if np.y < vt - 40.0 or np.y > vb + 40.0:
			continue
		var lift := absf(sin(float(n.hop))) * 7.0
		var ax := Vector2.from_angle(float(n.spin)) * 6.5
		var ay := ax.orthogonal() * 0.75
		b.circle(np + Vector2(2.0, 3.0), 4.5, Color(0.08, 0.08, 0.12, 0.16))
		var c := np + Vector2(0.0, -lift)
		b.quad(c - ax - ay, c + ax - ay, c + ax + ay, c - ax + ay, WHITEWASH)
		b.line(c - ax, c + ax, Color(0.76, 0.78, 0.82), 1.0)

	b.lod = keep_lod


static func _draw_wave(m: Node2D, b: ShapeBatch, vt: float, vb: float, t_sec: float) -> void:
	if WAVE_Y1 < vt - 60.0 or WAVE_Y0 > vb + 60.0:
		return
	var w: Dictionary = m.sitges_wave
	var st: String = str(w.get("state", "wait"))
	var t := float(w.get("t", 0.0))
	if st == "spray":
		var prog := clampf(t / WAVE_WARN_S, 0.0, 1.0)
		# Telegraphing surge outside seawall + flying white mist plumes across parapet
		b.rect(Rect2(WAVE_WALL_X - 44.0, WAVE_Y0, 42.0, WAVE_Y1 - WAVE_Y0), SEA_FOAM)
		var sy := WAVE_Y0 + 18.0
		while sy < WAVE_Y1 - 10.0:
			var jitter := (_h(sy, 41.0) - 0.5) * 14.0
			var puff := Vector2(WAVE_WALL_X + prog * (22.0 + _h(sy, 42.0) * 36.0) + sin(t_sec * 14.0 + sy) * 6.0, sy + jitter)
			b.circle(puff, 6.0 + 7.0 * prog, Color(1.0, 1.0, 1.0, 0.80))
			b.line(Vector2(WAVE_WALL_X - 4.0, sy), puff + Vector2(24.0 * prog, -6.0), Color(0.92, 0.98, 1.0, 0.65), 3.0)
			sy += 28.0
		var band_col := Color(0.20, 0.66, 0.86, 0.20 + 0.10 * sin(prog * PI * 4.0))
		b.band(PackedVector2Array([
			Vector2(WAVE_WALL_X, WAVE_Y0), Vector2(WAVE_REACH_X, WAVE_Y0),
			Vector2(WAVE_WALL_X, WAVE_Y1), Vector2(WAVE_REACH_X, WAVE_Y1),
		]), 2, band_col, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	elif st == "wash":
		var poly := PackedVector2Array()
		var steps := 14
		for i in range(steps + 1):
			var py := lerpf(WAVE_Y0, WAVE_Y1, float(i) / float(steps))
			poly.append(Vector2(WAVE_WALL_X, py))
		for i in range(steps, -1, -1):
			var py := lerpf(WAVE_Y0, WAVE_Y1, float(i) / float(steps))
			var fx := maxf(WAVE_WALL_X, _wave_front_x(m, py))
			poly.append(Vector2(fx + sin(t_sec * 11.0 + py * 0.04) * 6.0, py))
		b.polygon(poly, Color(0.14, 0.56, 0.76, 0.72))
		# Frothy white crest along the advancing inland edge
		for i in range(steps):
			var py := lerpf(WAVE_Y0, WAVE_Y1, (float(i) + 0.5) / float(steps))
			var fx := _wave_front_x(m, py)
			if fx > WAVE_WALL_X + 6.0:
				b.circle(Vector2(fx, py), 10.0, Color(0.95, 0.98, 1.0, 0.88))
	elif st == "recede":
		var fade := 1.0 - clampf(t / WAVE_RECEDE_S, 0.0, 1.0)
		var w_rec := (WAVE_REACH_X - WAVE_WALL_X) * fade * 0.75
		b.rect(Rect2(WAVE_WALL_X, WAVE_Y0, w_rec, WAVE_Y1 - WAVE_Y0), Color(0.20, 0.54, 0.70, 0.22 * fade))


static func _draw_church_base(m: Node2D, b: ShapeBatch) -> void:
	# West stone steps leading up to the church portal
	for s in range(4):
		var sx := CHURCH_RECT.position.x - 16.0 + float(s) * 4.0
		b.rect(Rect2(sx, -4320.0, 16.0 - float(s) * 4.0, 120.0), PAVE_STONE.lightened(0.04 * float(s)))
	# Long southeast shadow thrown across the plaza/roof edge
	b.rect(Rect2(CHURCH_RECT.position + Vector2(-8.0, 8.0), CHURCH_RECT.size), SHADOW)
	# Lower stone plinth & whitewashed nave walls with ochre sandstone trim
	b.rect(CHURCH_RECT, WHITEWASH)
	b.rect(Rect2(CHURCH_RECT.position.x, CHURCH_RECT.position.y, 20.0, CHURCH_RECT.size.y), OCHRE_STONE)
	b.rect(Rect2(CHURCH_RECT.position.x + 20.0, CHURCH_RECT.position.y + 4.0, 10.0, CHURCH_RECT.size.y - 8.0), WHITE_SHADE)
	# Grand recessed west portal arch overlooking the plaza
	b.rect(Rect2(CHURCH_RECT.position.x - 2.0, -4292.0, 16.0, 64.0), OCHRE_DARK)
	b.rect(Rect2(CHURCH_RECT.position.x + 4.0, -4282.0, 12.0, 44.0), Color(0.24, 0.16, 0.12))
	# Terracotta pitched nave roof & ridge line
	var roof := CHURCH_RECT.grow(-22.0)
	b.rect(roof, TERRACOTTA)
	b.line(Vector2(roof.get_center().x, roof.position.y), Vector2(roof.get_center().x, roof.end.y), TERRACOTTA.lightened(0.18), 5.0)
	var ry := roof.position.y + 18.0
	while ry < roof.end.y - 10.0:
		b.line(Vector2(roof.position.x + 4.0, ry), Vector2(roof.end.x - 4.0, ry), TERRACOTTA.darkened(0.14), 1.6)
		ry += 24.0
	# Plaza-side buttresses & side rose window bay
	for by: float in [-4370.0, -4270.0, -4170.0]:
		b.rect(Rect2(CHURCH_RECT.position.x - 4.0, by - 8.0, 12.0, 16.0), OCHRE_DARK)
	b.circle(Vector2(CHURCH_RECT.position.x + 12.0, -4260.0), 11.0, Color(0.18, 0.24, 0.36))
	b.circle(Vector2(CHURCH_RECT.position.x + 12.0, -4260.0), 7.5, SITGES_BLUE)
	# Bark ripple round the bell tower when chiming
	var w: Dictionary = m.sitges_wave
	var ct := float(w.get("chime_t", 0.0))
	if ct > 0.0:
		var prog := 1.0 - ct / 1.4
		b.circle(BELL_POS, 26.0 + prog * 90.0, Color(1.0, 0.88, 0.44, 0.45 * (1.0 - prog)))


static func draw_top(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep_lod := b.lod
	b.lod = true
	for d: Dictionary in m.sitges_diners:
		var p: Vector2 = d.pos
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var f: Vector2 = d.face
		NpcFigure.person(b, p, f, int(d.key), -1.0, {"arms": NpcFigure.Arms.READY})
		var hand: Vector2 = p + f * 6.5 + f.orthogonal() * 4.0
		b.circle(hand, 2.4, DRINK_VERMUT if int(d.drink) == 0 else DRINK_CAVA)
	b.lod = keep_lod


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if is_lamp(m, p):
		m._draw_lamppost(p)
	else:
		# Base of palm drawn cleanly in draw_live; small shadow contact here
		wc.circle(p, 9.0, Color(0.46, 0.34, 0.22, 0.55))


static func draw_bin(m: Node2D, wc: ShapeBatch, bn: Vector2) -> void:
	Passeig._recycling_station(m, wc, bn)


static func draw_table(m: Node2D, wc: ShapeBatch, tb: Vector2) -> void:
	m.contact_shadow(wc, tb, 14.0, 9.0, 0.20)
	wc.circle(tb, 12.5, WHITEWASH)
	wc.circle(tb, 10.5, Color(0.90, 0.88, 0.84))
	wc.circle(tb + Vector2(-3.0, -2.0), 3.0, Color(0.98, 0.96, 0.90))
	wc.circle(tb + Vector2(3.5, 2.5), 2.4, DRINK_CAVA)


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 6.0, 4.0, 0.16)
	wc.circle(kp, 6.0, WHITEWASH)
	wc.circle(kp, 3.8, Color(0.84, 0.54, 0.24))


# --- overhead: wind-swept palm crowns, awnings, church cupola & bell tower --

static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	var t_sec := float(AnimClock.msec()) * 0.001
	var w_mul := Outdoors.wind_strength(Game.weather)
	var lit := Game.lamp_glow()
	var tint: Color = m.night_cm.color if m.get("night_cm") != null else Color.WHITE

	# 1. Blue-and-white striped café awnings along east houses
	for i in range(CAFE_YS.size()):
		var cy: float = CAFE_YS[i]
		var aw := Rect2(EAST_WALL - 34.0, cy - 42.0, 34.0, 84.0)
		b.rect(Rect2(aw.position + Vector2(-4.0, 5.0), aw.size), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.14))
		var sy := aw.position.y
		var stripe := 0
		while sy < aw.end.y - 0.5:
			var h := minf(12.0, aw.end.y - sy)
			b.rect(Rect2(aw.position.x, sy, aw.size.x, h), SITGES_BLUE if stripe % 2 == 0 else WHITEWASH)
			sy += 12.0
			stripe += 1
		if lit > 0.0:
			b.glow(Vector2(EAST_WALL - 18.0, cy), 40.0, SkyLook.light(Color(1.0, 0.86, 0.58, 0.26 * lit), tint), 0.25)

	# 2. Wind-bent palm fronds swaying smoothly inland
	for p: Vector2 in PALM_SPOTS:
		var sway := sin(t_sec * (2.6 + w_mul * 1.4) + p.y * 0.025) * (0.14 + 0.10 * w_mul)
		var top := p + Vector2(18.0 + sin(t_sec * 2.4 + p.y * 0.02) * 3.0, -28.0)
		b.circle(top + Vector2(18.0, 20.0), 22.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.14))
		for k in range(7):
			var ang := -0.55 + float(k) * 0.44 + sway
			if k >= 5:
				ang += 1.65
			var fwd := Vector2.from_angle(ang)
			var side := fwd.orthogonal()
			var tip := top + fwd * 38.0 + Vector2(8.0 * w_mul, 2.0)
			var mid := top.lerp(tip, 0.46) + side * 4.0
			b.polygon(PackedVector2Array([
				top - side * 2.5,
				mid - side * 7.5,
				tip,
				mid + side * 6.5,
				top + side * 2.5,
			]), PALM_FROND if k % 2 == 0 else PALM_FROND_LT)
			b.line(top, tip, PALM_FROND.darkened(0.25), 1.6)

	# 3. Church upper cupola, two-tone tower gables & clock bell tower
	var c_cen := CHURCH_RECT.get_center()
	# Glazed blue-and-ochre crossing dome
	b.circle(c_cen + Vector2(5.0, 6.0), 28.0, SHADOW)
	b.circle(c_cen, 26.0, OCHRE_STONE)
	b.circle(c_cen, 21.0, SITGES_BLUE)
	b.circle(c_cen, 11.0, SITGES_BLUE_DK)
	b.circle(c_cen, 4.5, WHITEWASH)
	# North-west iconic tall Campanar (bell tower)
	b.rect(Rect2(BELL_POS - Vector2(22.0, 22.0) + Vector2(7.0, 8.0), Vector2(44.0, 44.0)), SHADOW)
	b.rect(Rect2(BELL_POS - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), WHITEWASH)
	b.rect(Rect2(BELL_POS - Vector2(22.0, 22.0), Vector2(6.0, 44.0)), OCHRE_STONE)
	b.rect(Rect2(BELL_POS + Vector2(16.0, -22.0), Vector2(6.0, 44.0)), OCHRE_STONE)
	b.circle(BELL_POS, 14.0, OCHRE_DARK)
	b.circle(BELL_POS, 11.0, WHITEWASH)
	b.circle(BELL_POS, 5.0, Color(0.84, 0.66, 0.24))     # brass bell cap inside belfry
	# Smaller south-west clock turret
	var tur := Vector2(716.0, -4090.0)
	b.rect(Rect2(tur - Vector2(14.0, 14.0) + Vector2(4.0, 5.0), Vector2(28.0, 28.0)), SHADOW)
	b.rect(Rect2(tur - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), WHITEWASH)
	b.circle(tur, 9.0, Color(0.92, 0.90, 0.84))
	b.line(tur, tur + Vector2(0.0, -5.0), Color(0.18, 0.18, 0.22), 1.4)
	b.line(tur, tur + Vector2(4.0, 2.0), Color(0.18, 0.18, 0.22), 1.4)
	if lit > 0.0:
		b.glow(BELL_POS, 56.0, SkyLook.light(Color(1.0, 0.86, 0.56, 0.30 * lit), tint), 0.25)

	# 4. Wind gust streaks sweeping off the sea
	if w_mul >= 0.65:
		var cam_y: float = m.cam.position.y if m.get("cam") != null else m.dog.global_position.y
		var sy := floorf((cam_y - 460.0) / 160.0) * 160.0
		var s_end := sy + 960.0
		while sy < s_end:
			var drift := fmod(t_sec * 420.0 + _h(sy, 31.0) * 600.0, 960.0)
			var wx := 260.0 + drift
			b.line(Vector2(wx, sy), Vector2(wx + 52.0, sy - 10.0), Color(1.0, 1.0, 1.0, 0.22 * w_mul), 1.6)
			sy += 160.0

	b.flush()


# --- the street after dark (world/night_fronts.gd) ---------------------------

static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(CAFE_YS.size()):
		out.append(NightFronts.front(Vector2(EAST_WALL, CAFE_YS[i]), -1.0, "bar", 4100 + i))
	var y := 120.0
	var j := 0
	while y > -3500.0:
		var near_cafe := false
		for cy: float in CAFE_YS:
			if absf(cy - y) < 85.0:
				near_cafe = true
				break
		if not near_cafe:
			var kind := NightFronts.kind_of(4200 + j)
			if kind != "" and kind != "bar":
				out.append(NightFronts.front(Vector2(EAST_WALL, y), -1.0, kind, 4200 + j))
		y -= 210.0
		j += 1
	return out
