class_name Horta
extends RefCounted

# WALK 23: EL LABERINT D'HORTA (the cypress maze)
# The oldest garden in the city, at the foot of Collserola: an 18th-century
# neoclassical garden with a romantic one beside it. In from the gate past
# the Desvalls palace; along the romantic garden's canal under the big trees;
# into the clipped cypress maze, where the path splits round one hedge block
# after another, your human keeping to one side and then the other, and Eros
# stands on his plinth in the clearing at its heart; then up the terraces'
# steps between the balustrades, the pavilion on one side and the nymph's
# pool on the other, and out at the back gate into the wood.
#
# The maze is what she plays: the hedges are solid and the leash goes round
# them; Eros is a real pole to tetherball your human round; one lap of him
# with your human near is the walk's own goal (tick). The gardener clipping
# the hedge in the clearing has left his bocadillo on the wheelbarrow.
#
# Static functions over main's state (main.WALK_MODULES). The gravel, the
# hedges, Eros and the balustrades are drawn on the world canvas each frame
# (draw_cross_section); the palace, the lawns, the canal, the rest of the
# maze and the pavilion on the cached edge layer (draw_edge_layer).

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.06, 0.05, 0.24)

# --- colors ------------------------------------------------------------------
const GRAVEL := Color(0.80, 0.74, 0.62)         # the garden's raked sauló
const GRAVEL_DARK := Color(0.70, 0.64, 0.52)
const GRAVEL_FLECK := Color(0.90, 0.86, 0.78)
const HEDGE := Color(0.17, 0.33, 0.20)          # clipped cypress, dark and dense
const HEDGE_LIT := Color(0.26, 0.45, 0.27)
const HEDGE_TOP := Color(0.33, 0.54, 0.32)
const HEDGE_DEEP := Color(0.10, 0.22, 0.13)
const LAWN := Color(0.42, 0.58, 0.32)
const LAWN_DARK := Color(0.36, 0.51, 0.28)
const STONE := Color(0.86, 0.83, 0.76)          # Montjuïc sandstone, weathered pale
const STONE_SHADE := Color(0.70, 0.67, 0.60)
const STONE_DARK := Color(0.55, 0.52, 0.46)
const WATER := Color(0.30, 0.46, 0.44)          # the canal, green with the trees in it
const WATER_LIT := Color(0.46, 0.62, 0.58)
const ROOF := Color(0.72, 0.42, 0.30)
const STUCCO := Color(0.92, 0.84, 0.70)
const STUCCO_SHADE := Color(0.78, 0.70, 0.56)
const BRONZE := Color(0.46, 0.40, 0.28)
const CYPRESS := Color(0.12, 0.26, 0.16)

# --- layout ------------------------------------------------------------------
const HALF := 300.0
# the maze: straight between its hedge walls, MAZE_X0..MAZE_X1, from its
# mouth at MAZE_BOT up to its far side at MAZE_TOP. Everything outside those
# walls is more maze, solid from the walls to the level's sides.
const MAZE_BOT := -1640.0
const MAZE_TOP := -3900.0
const MAZE_X0 := 340.0
const MAZE_X1 := 940.0
const OUTER_X0 := 90.0                  # the level walls' inner faces
const OUTER_X1 := 1190.0
# the hedge blocks down the middle, each an island your human keeps to one
# side of, alternating, so the way through is a serpentine
const BLOCKS: Array[Rect2] = [
	Rect2(540.0, -2120.0, 200.0, 280.0),
	Rect2(540.0, -3160.0, 200.0, 280.0),
	Rect2(540.0, -3700.0, 200.0, 240.0),
]
const BLOCK_SIDES: Array[float] = [1.0, 1.0, -1.0]
const ISLAND_LEAD := 400.0              # the whole cross aisle before a block
const ISLAND_STEER := 1.4               # and cut across it at El Mercat's rate
# Eros on his plinth in the clearing at the maze's heart: a pole with a fat
# rope radius, and a solid round plinth
const EROS := Vector2(640.0, -2500.0)
const EROS_R := 30.0
const EROS_SIDE := -1.0
const LAP_R := 190.0                    # she is going round him inside this
const LAP_REACH := 340.0                # with your human this close to him
# the gardener clipping the clearing's east wall, his barrow beside him
const GARDENER := Vector2(906.0, -2610.0)
const BARROW := Vector2(862.0, -2548.0)
# the romantic garden's canal, west of the path under the trees
const CANAL := Rect2(250.0, -1450.0, 56.0, 760.0)
# the terraces: steps across the path at each rise, balustrades at the sides
const STEPS: Array[float] = [-4080.0, -4400.0, -4700.0]
const STEP_DEPTH := 54.0
const BALUSTRADE_Y0 := -4380.0          # the middle terrace's east balustrade,
const BALUSTRADE_Y1 := -4110.0          # the one to grind
# the pavilion on the top terrace, east, and the nymph's pool, west
const PAVILION := Rect2(1000.0, -4720.0, 150.0, 120.0)
const POOL := Rect2(140.0, -4690.0, 170.0, 120.0)
# the Desvalls palace by the gate, east
const PALACE := Rect2(990.0, -320.0, 230.0, 300.0)

const PRIZE := Vector2(866.0, -2552.0)
const PRIZE_TEXT := "nick the gardener's bocadillo off his wheelbarrow"


# Walk order, down the level: the avenue past the palace, the romantic
# garden's bends along the canal, the maze dead straight between its walls,
# the terraces, the back gate.
static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 230.0},
		{"y": -560.0, "cx": 640.0, "half": 230.0},
		{"y": -880.0, "cx": 610.0, "half": 210.0},
		{"y": -1240.0, "cx": 670.0, "half": 205.0},
		{"y": -1480.0, "cx": 640.0, "half": 250.0},
		{"y": MAZE_BOT + 40.0, "cx": 640.0, "half": HALF},
		{"y": MAZE_TOP - 40.0, "cx": 640.0, "half": HALF},
		{"y": -4060.0, "cx": 640.0, "half": 260.0},
		{"y": -4600.0, "cx": 640.0, "half": 270.0},
		{"y": m.GATE_Y + 140.0, "cx": 640.0, "half": 250.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 250.0},
	]


static func _east(m: Node2D, y: float, inset: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2(e.y - inset, y)


static func _west(m: Node2D, y: float, inset: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2(e.x + inset, y)


static func in_maze(y: float) -> bool:
	return y < MAZE_BOT and y > MAZE_TOP


# Everything solid: the hedge blocks, the maze walls out to the level's
# sides, and Eros's plinth (round: main adds it as a circle body).
static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in BLOCKS:
		out.append(r)
	out.append(Rect2(OUTER_X0, MAZE_TOP, MAZE_X0 - OUTER_X0, MAZE_BOT - MAZE_TOP))
	out.append(Rect2(MAZE_X1, MAZE_TOP, OUTER_X1 - MAZE_X1, MAZE_BOT - MAZE_TOP))
	return out


# what the leash goes round: the blocks, and the maze walls' corners at the
# mouth and the far side, where she can drag it round a hedge end
static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in BLOCKS:
		out.append(r)
	for y: float in [MAZE_BOT - 30.0, MAZE_TOP]:
		out.append(Rect2(MAZE_X0 - 30.0, y, 30.0, 30.0))
		out.append(Rect2(MAZE_X1, y, 30.0, 30.0))
	return out


static func islands() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(BLOCKS.size()):
		out.append({"rect": BLOCKS[i].grow(20.0), "side": BLOCK_SIDES[i],
			"lead": ISLAND_LEAD, "steer": ISLAND_STEER, "face": true})
	out.append({"rect": Rect2(EROS - Vector2(EROS_R + 24.0, EROS_R + 24.0), Vector2(EROS_R + 24.0, EROS_R + 24.0) * 2.0),
		"side": EROS_SIDE, "lead": ISLAND_LEAD, "steer": ISLAND_STEER, "face": true})
	return out


# The big trees of the romantic garden and the avenue: deco poles, oaks.
static func garden_trees(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y: float in [-120.0, -460.0]:
		out.append(_west(m, y, 24.0))
	for y: float in [-780.0, -1300.0]:
		out.append(_east(m, y, 26.0))
	# one out on the gravel where the path swings round it
	out.append(Vector2(560.0, -1060.0))
	for y: float in [-4240.0, -4560.0]:
		out.append(_west(m, y, 30.0))
	return out


static func build(m: Node2D) -> Array:
	m.gate_text = "COLLSEROLA"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	for tp: Vector2 in garden_trees(m):
		m.poles.append(tp)
	m.deco_pole_count = m.poles.size()
	# Eros: the one real pole in the maze
	m.poles.append(EROS)
	m.islands = islands()
	m.owner_keepouts.clear()
	for r: Rect2 in BLOCKS:
		m.owner_keepouts.append(r)
	m.cone_spots = Array([_west(m, -620.0, 60.0), _east(m, -4520.0, 70.0)], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		_east(m, -360.0, 26.0), _west(m, -1420.0, 30.0), _east(m, -4640.0, 28.0),
	], TYPE_VECTOR2, &"", null)
	# a bench by the canal, two on the terraces facing the view down the garden
	m.benches = Array([
		_west(m, -1000.0, 18.0), _west(m, -4500.0, 18.0), _east(m, -4250.0, 18.0),
	], TYPE_VECTOR2, &"", null)
	# a stone font in the middle terrace's retaining wall
	m.fountains = Array([_east(m, -4330.0, 22.0)], TYPE_VECTOR2, &"", null)
	# where the gravel holds the rain: the canal path's low spot, the maze's
	# far corner, the terrace foot
	m.patches = Array([
		{"y": -1180.0, "at": 0.30, "rx": 46.0, "ry": 24.0, "seed": 1.70, "kind": "mud"},
		{"y": -3820.0, "at": 0.78, "rx": 40.0, "ry": 22.0, "seed": 2.90, "kind": "mud"},
		{"y": -4000.0, "at": 0.40, "rx": 44.0, "ry": 22.0, "seed": 4.10, "kind": "mud"},
	], TYPE_DICTIONARY, &"", null)
	# Mark spots: the stone urns on their pedestals, at the avenue, along the
	# canal, in the maze's aisles and on the terraces
	var marks: Array[Vector2] = [
		_east(m, -620.0, 34.0),
		_west(m, -1180.0, 30.0),
		Vector2(MAZE_X1 - 30.0, -1980.0),
		Vector2(MAZE_X0 + 30.0, -2780.0),
		Vector2(MAZE_X1 - 30.0, -3600.0),
		_west(m, -4300.0, 34.0),
		_east(m, -4800.0, 34.0),
	]
	# dropped snacks: a bit of ensaïmada from somebody's picnic
	var snacks: Array[Vector2] = [
		_west(m, -820.0, 80.0),
		Vector2(MAZE_X0 + 90.0, -3300.0),
		_east(m, -4180.0, 90.0),
	]
	return [marks, snacks]


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the garden's big trees are broadleaves; Eros is a statue, not a tree
static func tree_kind(m: Node2D, p: Vector2) -> int:
	return m.TREE_NONE if p == EROS else m.TREE_OAK


static func tick(m: Node2D, _delta: float) -> void:
	# going round Eros: the angle she sweeps round him while she is close and
	# your human is near, one whole lap either way
	if bool(m.get_meta("horta_eros", false)):
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	if dp.distance_to(EROS) > LAP_R or hp.distance_to(EROS) > LAP_REACH:
		m.set_meta("horta_lap", 0.0)
		m.set_meta("horta_last", INF)
		return
	var a := (dp - EROS).angle()
	var last: float = float(m.get_meta("horta_last", INF))
	var lap: float = float(m.get_meta("horta_lap", 0.0))
	if last < INF:
		lap += wrapf(a - last, -PI, PI)
	m.set_meta("horta_last", a)
	m.set_meta("horta_lap", lap)
	if absf(lap) >= TAU:
		m.set_meta("horta_eros", true)
		m.bones += 5
		m.combo.add("ROUND EROS", 4)
		m.float_text(hp + Vector2(0, -34), "Is that Cupid? Or Eros?", Color(1, 1, 1, 0.9), m.POP_SAY)
		m.float_text(dp + Vector2(0, -30), "round eros! +5", Color(0.96, 0.86, 0.32))
		m.feed.say("ROUND EROS!", EventFeed.Tone.GOOD)
		m.get_node("/root/Sfx").play("prize", 1.1)


static func eros_lapped(m: Node2D) -> bool:
	return bool(m.get_meta("horta_eros", false))


# The ground, every frame, culled to the view: the gravel between the edges,
# the terrace steps, the clearing round Eros, the hedge blocks and Eros, and
# the balustrades.
static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 30.0, ctop)
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	var step := 24.0
	var y := floorf(hi / step) * step
	var eb: Vector2 = m.walk_edges(y + step)
	while y > lo - step:
		var ea: Vector2 = m.walk_edges(y)
		wc.polygon(PackedVector2Array([Vector2(ea.x, y), Vector2(ea.y, y), Vector2(eb.y, y + step), Vector2(eb.x, y + step)]), GRAVEL)
		# the raked edge, darker where the feet do not go
		wc.line(Vector2(ea.x + 4.0, y), Vector2(eb.x + 4.0, y + step), GRAVEL_DARK, 8.0)
		wc.line(Vector2(ea.y - 4.0, y), Vector2(eb.y - 4.0, y + step), GRAVEL_DARK, 8.0)
		var w: float = ea.y - ea.x
		var k := int(absf(y) / step)
		var h := fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)
		wc.circle(Vector2(ea.x + 16.0 + h * (w - 32.0), y + h * step), 2.0, GRAVEL_FLECK)
		wc.circle(Vector2(ea.x + 28.0 + fmod(h * 7.3, 1.0) * (w - 56.0), y + step * 0.5), 1.8, GRAVEL_DARK)
		eb = ea
		y -= step
	if EROS.y > vt - 260.0 and EROS.y < vb + 260.0:
		_draw_clearing(wc)
	for sy: float in STEPS:
		if sy > vt - STEP_DEPTH and sy < vb + STEP_DEPTH:
			_draw_steps(m, wc, sy)
	for r: Rect2 in BLOCKS:
		if r.end.y > vt - 20.0 and r.position.y < vb + 20.0:
			_draw_hedge(wc, r, true)
	if in_maze(vt) or in_maze(vb) or (vt < MAZE_TOP and vb > MAZE_BOT):
		_draw_maze_walls(wc, vt, vb)
	if EROS.y > vt - 60.0 and EROS.y < vb + 60.0:
		_draw_eros(wc)
	if BALUSTRADE_Y1 > vt - 20.0 and BALUSTRADE_Y0 < vb + 20.0:
		_draw_balustrades(m, wc)


# a clipped hedge seen from above: its shadow, the dense dark body, the
# lit clipped top, and the shears' flat facets along it
static func _draw_hedge(wc: ShapeBatch, r: Rect2, inner: bool) -> void:
	wc.rect(Rect2(r.position + LIGHT * 9.0, r.size), SHADOW)
	wc.rect(r, HEDGE)
	var top := r.grow(-5.0)
	wc.rect(top, HEDGE_LIT)
	wc.rect(Rect2(top.position.x, top.position.y, top.size.x, 6.0), HEDGE_TOP)
	wc.rect(Rect2(top.position.x, top.position.y, 6.0, top.size.y), HEDGE_TOP)
	if not inner:
		return
	# the clipping's texture: a regular pattern of small clumps
	var k := 0
	var yy := top.position.y + 12.0
	while yy < top.end.y - 6.0:
		var xx := top.position.x + 10.0 + float(k % 2) * 9.0
		while xx < top.end.x - 6.0:
			wc.circle(Vector2(xx, yy), 4.5, HEDGE if (k + int(xx)) % 3 == 0 else HEDGE_TOP)
			xx += 22.0
		yy += 16.0
		k += 1


# the maze's walls along the path, the faces she runs between
static func _draw_maze_walls(wc: ShapeBatch, vt: float, vb: float) -> void:
	var y0 := maxf(MAZE_TOP, vt - 40.0)
	var y1 := minf(MAZE_BOT, vb + 40.0)
	if y1 <= y0:
		return
	for x: float in [MAZE_X0 - 34.0, MAZE_X1]:
		var r := Rect2(x, y0, 34.0, y1 - y0)
		wc.rect(Rect2(r.position + LIGHT * 9.0, r.size), SHADOW)
		wc.rect(r, HEDGE)
		wc.rect(r.grow(-5.0), HEDGE_LIT)
		var yy := floorf(y0 / 18.0) * 18.0
		while yy < y1 - 6.0:
			if yy > y0 + 4.0:
				wc.circle(Vector2(x + 17.0 + sin(yy * 0.37) * 6.0, yy), 4.0, HEDGE_TOP)
			yy += 18.0
	# the ends of the walls at the mouth and the far side, clipped square
	for y: float in [MAZE_BOT - 30.0, MAZE_TOP]:
		if y > vt - 40.0 and y < vb + 40.0:
			for x: float in [OUTER_X0, MAZE_X1]:
				_draw_hedge(wc, Rect2(x, y, MAZE_X0 - OUTER_X0, 30.0), false)


# the clearing at the heart of the maze: a ring of paler raked gravel round
# the plinth, and the rake's circles
static func _draw_clearing(wc: ShapeBatch) -> void:
	wc.circle(EROS, 230.0, GRAVEL_DARK)
	wc.circle(EROS, 224.0, GRAVEL)
	for r: float in [70.0, 120.0, 170.0]:
		wc.draw_arc(EROS, r, 0.0, TAU, 48, GRAVEL_FLECK, 1.5)


# Eros on his plinth: a round stone drum, its moulding, and the winged boy
# with his bow, seen from above
static func _draw_eros(wc: ShapeBatch) -> void:
	wc.circle(EROS + LIGHT * 12.0, EROS_R + 4.0, SHADOW)
	wc.circle(EROS, EROS_R + 4.0, STONE_DARK)
	wc.circle(EROS, EROS_R, STONE)
	wc.circle(EROS - LIGHT * 4.0, EROS_R - 8.0, STONE_SHADE)
	wc.circle(EROS, EROS_R - 10.0, STONE)
	# the wings, swept back from his shoulders, feathers drawn along them
	var back := Vector2(0.0, 1.0)
	for sd: float in [-1.0, 1.0]:
		var root := EROS + Vector2(sd * 4.0, 2.0)
		var tip := EROS + Vector2(sd * 20.0, 14.0)
		wc.polygon(PackedVector2Array([root, root + Vector2(sd * 10.0, -6.0), tip, root + back * 10.0]), Color(0.95, 0.93, 0.87))
		for f in range(3):
			var u := 0.35 + float(f) * 0.22
			wc.line(root.lerp(tip, u), root.lerp(tip, u) + back * 5.0, STONE_SHADE, 1.0)
	# his shoulders and head, turned to aim
	wc.circle(EROS + Vector2(0, 1), 6.5, Color(0.88, 0.85, 0.78))
	wc.circle(EROS + Vector2(1, -4), 4.0, Color(0.93, 0.90, 0.84))
	wc.circle(EROS + Vector2(0, -6), 2.4, Color(0.78, 0.72, 0.58))
	# the bow, held out to his left, and the arrow nocked
	wc.draw_arc(EROS + Vector2(-9, -9), 9.0, PI * 1.05, PI * 1.95, 10, BRONZE, 2.0)
	wc.line(EROS + Vector2(-17.5, -11), EROS + Vector2(-0.5, -11), Color(0.96, 0.94, 0.88, 0.8), 1.0)
	wc.line(EROS + Vector2(-9, -2), EROS + Vector2(-9, -22), BRONZE.lightened(0.2), 1.4)


# a flight of steps across the path: treads lit at their nosings
static func _draw_steps(m: Node2D, wc: ShapeBatch, sy: float) -> void:
	var e: Vector2 = m.walk_edges(sy)
	var n := 4
	for i in range(n):
		var ty := sy - STEP_DEPTH * 0.5 + float(i) * STEP_DEPTH / float(n)
		wc.rect(Rect2(e.x, ty, e.y - e.x, STEP_DEPTH / float(n)), STONE if i % 2 == 0 else STONE_SHADE)
		wc.line(Vector2(e.x, ty), Vector2(e.y, ty), Color(1, 1, 1, 0.35), 1.5)
	# the newel posts at each end
	for x: float in [e.x + 6.0, e.y - 6.0]:
		wc.rect(Rect2(x - 9.0, sy - STEP_DEPTH * 0.5 - 6.0, 18.0, 18.0), STONE_DARK)
		wc.rect(Rect2(x - 7.0, sy - STEP_DEPTH * 0.5 - 4.0, 14.0, 14.0), STONE)


# the terraces' balustrades along both edges: the coping, and the balusters'
# round tops showing through it
static func _draw_balustrades(m: Node2D, wc: ShapeBatch) -> void:
	for side: float in [-1.0, 1.0]:
		var y := BALUSTRADE_Y0
		while y < BALUSTRADE_Y1:
			var e: Vector2 = m.walk_edges(y)
			var x: float = e.y - 8.0 if side > 0.0 else e.x + 8.0
			wc.rect(Rect2(x - 5.0 + LIGHT.x * 6.0, y + LIGHT.y * 6.0, 10.0, 15.0), SHADOW)
			wc.rect(Rect2(x - 5.0, y, 10.0, 15.0), STONE)
			wc.circle(Vector2(x, y + 7.5), 2.6, STONE_SHADE)
			y += 15.0


# What does not move: the palace and its lawn by the gate, the romantic
# garden's lawns and canal, the rest of the maze beyond its walls, the
# terraces' pavilion, pool and cypresses.
static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	_draw_lawns(m, b, top, bot)
	if CANAL.end.y > top and CANAL.position.y < bot:
		_draw_canal(b)
	if MAZE_BOT > top and MAZE_TOP < bot:
		_draw_outer_maze(b, maxf(top, MAZE_TOP), minf(bot, MAZE_BOT))
	if PALACE.end.y > top - 60.0 and PALACE.position.y < bot + 60.0:
		_draw_palace(b)
	if POOL.end.y > top - 60.0 and POOL.position.y < bot + 60.0:
		_draw_pool(b)
	if PAVILION.end.y > top - 60.0 and PAVILION.position.y < bot + 60.0:
		_draw_pavilion(b)
	_draw_cypresses(m, b, top, bot)


# the lawns either side of the path outside the maze, mown in stripes, and
# the low box edging along the gravel, following every bend
static func _draw_lawns(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var stripe := 40.0
	var y := floorf(top / stripe) * stripe
	while y < bot:
		if not in_maze(y + stripe * 0.5):
			var col := LAWN if int(absf(y) / stripe) % 2 == 0 else LAWN_DARK
			b.rect(Rect2(-200.0, y, 1680.0, stripe + 1.0), col)
		y += stripe
	var step := 12.0
	y = floorf(top / step) * step
	var ea: Vector2 = m.walk_edges(y)
	while y < bot:
		var eb: Vector2 = m.walk_edges(y + step)
		if not in_maze(y + step * 0.5):
			b.line(Vector2(ea.x - 9.0, y), Vector2(eb.x - 9.0, y + step), HEDGE, 11.0)
			b.line(Vector2(ea.y + 9.0, y), Vector2(eb.y + 9.0, y + step), HEDGE, 11.0)
			b.line(Vector2(ea.x - 10.0, y), Vector2(eb.x - 10.0, y + step), HEDGE_LIT, 5.0)
			b.line(Vector2(ea.y + 8.0, y), Vector2(eb.y + 8.0, y + step), HEDGE_LIT, 5.0)
		ea = eb
		y += step


static func _draw_canal(b: ShapeBatch) -> void:
	var r := CANAL
	b.rect(r.grow(8.0), STONE_SHADE)
	b.rect(r.grow(4.0), STONE)
	b.rect(r, WATER)
	var y := r.position.y + 30.0
	var k := 0
	while y < r.end.y - 10.0:
		b.line(Vector2(r.position.x + 10.0 + float(k % 3) * 9.0, y), Vector2(r.position.x + 24.0 + float(k % 3) * 9.0, y), WATER_LIT, 1.6)
		y += 46.0
		k += 1
	# a little stone footbridge over it, halfway
	var by := r.get_center().y
	b.rect(Rect2(r.position.x - 14.0, by - 16.0, r.size.x + 28.0, 32.0), STONE_SHADE)
	b.rect(Rect2(r.position.x - 12.0, by - 13.0, r.size.x + 24.0, 26.0), STONE)
	b.line(Vector2(r.position.x - 12.0, by - 13.0), Vector2(r.end.x + 12.0, by - 13.0), STONE_DARK, 2.0)
	b.line(Vector2(r.position.x - 12.0, by + 13.0), Vector2(r.end.x + 12.0, by + 13.0), STONE_DARK, 2.0)


# The rest of the maze, past its walls on both sides: hedges with gravel
# alleys between, laid on a grid that is the same each visit. Solid (solids):
# it is the maze she can see over the walls and not get into.
static func _draw_outer_maze(b: ShapeBatch, top: float, bot: float) -> void:
	for xs: Vector2 in [Vector2(OUTER_X0 - 60.0, MAZE_X0 - 34.0), Vector2(MAZE_X1 + 34.0, OUTER_X1 + 160.0)]:
		b.rect(Rect2(xs.x, top, xs.y - xs.x, bot - top), HEDGE)
		var cell := 64.0
		var cy := floorf(top / cell) * cell
		while cy < bot:
			var row := int(absf(cy) / cell)
			var cx := floorf(xs.x / cell) * cell
			while cx < xs.y:
				var col := int(cx / cell)
				var h := fmod(absf(sin(float(row * 37 + col * 11) * 12.9898) * 43758.5453), 1.0)
				# an alley along the cell's top or its left side, or both
				var a0 := Vector2(maxf(cx + 12.0, xs.x), cy + 12.0)
				if h < 0.62:
					var x1 := minf(cx + cell + 12.0, xs.y - 8.0)
					if x1 > a0.x:
						b.rect(Rect2(a0.x, a0.y, x1 - a0.x, 22.0), GRAVEL_DARK)
				if h > 0.38 and cx + 12.0 > xs.x and cx + 34.0 < xs.y:
					b.rect(Rect2(cx + 12.0, cy + 12.0, 22.0, minf(cell + 12.0, bot - cy - 12.0)), GRAVEL_DARK)
				cx += cell
			cy += cell


# The Desvalls palace: the villa's hipped roof of terracotta, its tower, the
# stucco terrace to the avenue.
static func _draw_palace(b: ShapeBatch) -> void:
	var r := PALACE
	b.rect(Rect2(r.position + LIGHT * 14.0, r.size), SHADOW)
	b.rect(r.grow(10.0), STUCCO_SHADE)
	b.rect(r, ROOF)
	var c := r.get_center()
	b.polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(c.x, c.y - 60.0)]), ROOF.lightened(0.12))
	b.polygon(PackedVector2Array([Vector2(r.position.x, r.end.y), r.end, Vector2(c.x, c.y + 60.0)]), ROOF.darkened(0.15))
	b.polygon(PackedVector2Array([r.position, Vector2(c.x, c.y - 60.0), Vector2(c.x, c.y + 60.0), Vector2(r.position.x, r.end.y)]), ROOF.lightened(0.04))
	b.line(Vector2(c.x, c.y - 60.0), Vector2(c.x, c.y + 60.0), ROOF.lightened(0.25), 2.0)
	# the tower on the corner, its own little roof
	var t := Rect2(r.position.x - 10.0, r.position.y - 10.0, 70.0, 70.0)
	b.rect(Rect2(t.position + LIGHT * 18.0, t.size), SHADOW)
	b.rect(t, STUCCO)
	b.polygon(PackedVector2Array([t.position + Vector2(6, 6), Vector2(t.end.x - 6.0, t.position.y + 6.0), t.get_center()]), ROOF.lightened(0.15))
	b.polygon(PackedVector2Array([Vector2(t.end.x - 6.0, t.position.y + 6.0), t.end - Vector2(6, 6), t.get_center()]), ROOF.darkened(0.2))
	b.polygon(PackedVector2Array([t.end - Vector2(6, 6), Vector2(t.position.x + 6.0, t.end.y - 6.0), t.get_center()]), ROOF.darkened(0.1))
	b.polygon(PackedVector2Array([Vector2(t.position.x + 6.0, t.end.y - 6.0), t.position + Vector2(6, 6), t.get_center()]), ROOF)
	# the terrace along the avenue, its urns
	b.rect(Rect2(r.position.x - 34.0, r.position.y + 40.0, 24.0, r.size.y - 60.0), STUCCO)
	for k in range(4):
		b.circle(Vector2(r.position.x - 22.0, r.position.y + 70.0 + float(k) * 60.0), 6.0, STONE_SHADE)


# the nymph's pool on the top terrace: a stone basin, still water, the grotto
# at its back
static func _draw_pool(b: ShapeBatch) -> void:
	var r := POOL
	b.rect(r.grow(10.0), STONE_SHADE)
	b.rect(r.grow(6.0), STONE)
	b.rect(r, WATER)
	b.line(r.position + Vector2(20, 30), r.position + Vector2(60, 30), WATER_LIT, 1.6)
	b.line(r.position + Vector2(80, 76), r.position + Vector2(130, 76), WATER_LIT, 1.6)
	# the grotto's rockwork along the west side, the nymph in her niche
	for k in range(6):
		b.circle(Vector2(r.position.x - 6.0, r.position.y + 10.0 + float(k) * 20.0), 14.0, STONE_DARK)
	b.circle(Vector2(r.position.x + 8.0, r.get_center().y), 8.0, Color(0.94, 0.92, 0.86))


# The pavilion: a little neoclassical temple, its roof seen from above, the
# columns of its portico to the path.
static func _draw_pavilion(b: ShapeBatch) -> void:
	var r := PAVILION
	b.rect(Rect2(r.position + LIGHT * 16.0, r.size), SHADOW)
	b.rect(r.grow(12.0), STONE_SHADE)
	b.rect(r, STONE)
	var c := r.get_center()
	b.polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, c.y), Vector2(r.position.x, c.y)]), STONE.lightened(0.06))
	b.polygon(PackedVector2Array([Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), r.end, Vector2(r.position.x, r.end.y)]), STONE_SHADE)
	b.line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), STONE_DARK, 2.0)
	for k in range(5):
		var cy := r.position.y + 12.0 + float(k) * (r.size.y - 24.0) / 4.0
		b.circle(Vector2(r.position.x - 6.0 + LIGHT.x * 4.0, cy + LIGHT.y * 4.0), 6.0, SHADOW)
		b.circle(Vector2(r.position.x - 6.0, cy), 6.0, Color(0.96, 0.94, 0.88))
	# its steps down to the terrace
	for k in range(3):
		b.rect(Rect2(r.position.x - 20.0 - float(k) * 6.0, r.position.y + 10.0, 6.0, r.size.y - 20.0), STONE if k % 2 == 0 else STONE_SHADE)


# cypresses: the garden's other trees, tall and narrow, round from above,
# in rows along the terraces and the avenue
static func _draw_cypresses(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var y := floorf(top / 70.0) * 70.0
	while y < bot:
		var ok := not in_maze(y) and not (y > PALACE.position.y - 40.0 and y < PALACE.end.y + 40.0)
		if ok:
			var e: Vector2 = m.walk_edges(y)
			for x: float in [e.x - 46.0, e.y + 46.0]:
				if POOL.grow(30.0).has_point(Vector2(x, y)) or PAVILION.grow(30.0).has_point(Vector2(x, y)) \
						or CANAL.grow(30.0).has_point(Vector2(x, y)):
					continue
				b.circle(Vector2(x, y) + LIGHT * 10.0, 13.0, SHADOW)
				b.circle(Vector2(x, y), 13.0, CYPRESS)
				b.circle(Vector2(x, y) - LIGHT * 3.0, 8.0, HEDGE)
				b.circle(Vector2(x, y) - LIGHT * 5.0, 3.5, HEDGE_LIT)
		y += 70.0


# a stone urn on its pedestal for a hydrant: the square plinth, the round
# bowl, the progress ring while she marks it
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.cast_shadow(wc, hp, 10.0, 22.0)
	var stone := STONE if not h.done else STONE.darkened(0.18)
	wc.rect(Rect2(hp.x - 10.0, hp.y - 10.0, 20.0, 20.0), stone.darkened(0.22))
	wc.rect(Rect2(hp.x - 9.0, hp.y - 9.0, 18.0, 18.0), stone)
	wc.circle(hp, 8.0, stone.darkened(0.1))
	wc.circle(hp, 6.0, Color(0.30, 0.24, 0.18))
	wc.circle(hp + Vector2(-1.5, -1.5), 3.5, Color(0.36, 0.52, 0.30))
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 18.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# a dropped snack: a torn piece of ensaïmada, the spiral and its sugar
static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 10.0, 3.0, 0.20)
	wc.circle(kp, 9.0, Color(0.86, 0.66, 0.38))
	wc.draw_arc(kp, 6.0, 0.0, PI * 1.6, 10, Color(0.72, 0.50, 0.26), 1.6)
	wc.draw_arc(kp, 3.0, PI, PI * 2.6, 8, Color(0.72, 0.50, 0.26), 1.4)
	wc.circle(kp + Vector2(-3, -3), 2.2, Color(0.98, 0.97, 0.94))
	wc.circle(kp + Vector2(4, 1), 1.8, Color(0.98, 0.97, 0.94))


# the font in the terrace wall: a stone mask, the spout, the basin below
static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var c: ShapeBatch = m._wc
	c.rect(Rect2(f.x - 18.0 + 5.0, f.y - 14.0 + 8.0, 40.0, 30.0), SHADOW)
	c.rect(Rect2(f.x + 6.0, f.y - 22.0, 16.0, 44.0), STONE_SHADE)
	c.circle(Vector2(f.x + 14.0, f.y), 7.0, STONE)
	c.circle(Vector2(f.x + 12.0, f.y), 2.0, STONE_DARK)
	c.rect(Rect2(f.x - 18.0, f.y - 12.0, 26.0, 24.0), STONE_DARK)
	c.rect(Rect2(f.x - 15.0, f.y - 9.0, 20.0, 18.0), WATER)
	c.rect(Rect2(f.x - 13.0, f.y - 7.0, 8.0, 6.0), WATER_LIT)
	c.line(Vector2(f.x + 8.0, f.y), Vector2(f.x - 2.0, f.y + 1.0), Color(0.82, 0.92, 0.96, 0.8), 2.0)


# The gardener at the clearing's east wall with his shears, and his barrow of
# clippings with the bocadillo on it until she has it.
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if GARDENER.y < vt - 60.0 or GARDENER.y > vb + 60.0:
		return
	var t: float = AnimClock.msec() / 1000.0
	# the barrow: tray, wheel, handles, a heap of clippings
	var bw := BARROW
	m.contact_shadow(wc, bw + Vector2(2, 4), 22.0, 6.0, 0.22)
	wc.rect(Rect2(bw.x - 18.0, bw.y - 14.0, 36.0, 28.0), Color(0.30, 0.42, 0.52))
	wc.rect(Rect2(bw.x - 15.0, bw.y - 11.0, 30.0, 22.0), Color(0.22, 0.32, 0.40))
	for k in range(5):
		wc.circle(bw + Vector2(-9.0 + float(k % 3) * 9.0, -5.0 + floorf(float(k) / 3.0) * 9.0), 6.0, HEDGE_LIT if k % 2 == 0 else HEDGE_TOP)
	wc.line(bw + Vector2(-14, 14), bw + Vector2(-18, 30), Color(0.40, 0.30, 0.20), 3.0)
	wc.line(bw + Vector2(14, 14), bw + Vector2(18, 30), Color(0.40, 0.30, 0.20), 3.0)
	wc.circle(bw + Vector2(0, -18), 6.0, Color(0.18, 0.18, 0.18))
	if not m.prize_taken:
		# the bocadillo in its paper: a baguette end, the paper folded back
		wc.rect(Rect2(PRIZE.x - 12.0, PRIZE.y - 5.0, 24.0, 10.0), Color(0.96, 0.95, 0.90))
		wc.circle(PRIZE + Vector2(-8, 0), 5.0, Color(0.82, 0.58, 0.30))
		wc.rect(Rect2(PRIZE.x - 8.0, PRIZE.y - 5.0, 12.0, 10.0), Color(0.82, 0.58, 0.30))
		wc.line(PRIZE + Vector2(-6, -2), PRIZE + Vector2(2, -2), Color(0.70, 0.30, 0.26), 2.0)
	# the gardener, facing the hedge: hat, shoulders, the shears working
	var g := GARDENER
	m.contact_shadow(wc, g + Vector2(2, 4), 14.0, 5.0, 0.24)
	wc.circle(g, 12.0, Color(0.26, 0.38, 0.30))
	wc.circle(g + Vector2(2, 0), 8.0, Color(0.86, 0.80, 0.62))
	wc.circle(g + Vector2(2, 0), 4.0, Color(0.74, 0.66, 0.46))
	var snip := 0.35 + 0.25 * sin(t * 9.0)
	for s: float in [-1.0, 1.0]:
		wc.line(g + Vector2(10, s * 4.0), g + Vector2(24, s * 4.0 * (1.0 - snip)), Color(0.70, 0.72, 0.74), 2.0)
