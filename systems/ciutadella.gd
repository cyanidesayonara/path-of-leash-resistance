class_name Ciutadella
extends RefCounted

# WALK 11: LA CIUTADELLA ("The old citadel's park, and its mammoth"), the
# first statue boss (docs/BOSSES.md). South to north:
#   1. Passeig de Lluís Companys: the wide terracotta promenade from under the
#      red-brick Arc de Triomf, its bench-lamps in two rows (y 260 .. -860)
#   2. The park gate: iron railings between stone piers (y -860 .. -1040)
#   3. The avenue: a gravel path between lawns and plane trees, the
#      crenellated brick Castell dels Tres Dragons to the west and the iron
#      and glass Hivernacle to the east (y -1040 .. -2160)
#   4. The mammoth's lawn by the boating lake (y -2160 .. -3300): El Mamut,
#      the stone mammoth, the fight (systems/boss_mamut.gd). Your human waits
#      at BossMamut.HOLD_Y until he is settled.
#   5. La Cascada: the monumental fountain to the west, its pool lapping the
#      path, the golden chariot on top (y -3300 .. -3990)
#   6. The zoo wall to the east, giraffes looking over it, the Parliament to
#      the west, palms full of monk parakeets (y -3990 .. -5000). The live
#      event: the parakeets mob your human's croissant; bark them off.
#   7. The dog area past the gate, off the leash.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const BossMamut := preload("res://systems/boss_mamut.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const OVERHEAD_FOLLOWS_CAMERA := true
const HALF := 300.0
const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# zone boundaries, south to north
const PASSEIG_TOP := -860.0
const GATE_TOP := -1040.0
const AVENUE_TOP := -2160.0
const ARENA_TOP := -3300.0
const CASCADA_TOP := -3990.0

# the Arc de Triomf: its two piers stand in the promenade's edges
const ARC_Y := -80.0
const ARC_PIERS: Array[Rect2] = [Rect2(296.0, -150.0, 96.0, 140.0), Rect2(888.0, -150.0, 96.0, 140.0)]
# the Passeig's bench-lamps, both rows
const LAMPS: Array[Vector2] = [
	Vector2(372.0, 120.0), Vector2(908.0, 120.0), Vector2(372.0, -300.0), Vector2(908.0, -300.0),
	Vector2(372.0, -520.0), Vector2(908.0, -520.0), Vector2(372.0, -740.0), Vector2(908.0, -740.0),
]
const GATE_PIERS: Array[Vector2] = [Vector2(488.0, -950.0), Vector2(792.0, -950.0)]
const AVENUE_TREES: Array[Vector2] = [
	Vector2(428.0, -1200.0), Vector2(852.0, -1300.0), Vector2(428.0, -1480.0), Vector2(852.0, -1600.0),
	Vector2(428.0, -1780.0), Vector2(852.0, -1900.0), Vector2(428.0, -2060.0),
]
const CASCADA_PALMS: Array[Vector2] = [Vector2(915.0, -3440.0), Vector2(915.0, -3700.0), Vector2(915.0, -3930.0)]
const ZOO_PALMS: Array[Vector2] = [
	Vector2(430.0, -4180.0), Vector2(850.0, -4300.0), Vector2(430.0, -4440.0),
	Vector2(850.0, -4560.0), Vector2(430.0, -4700.0), Vector2(850.0, -4800.0),
]
const CASTLE := Rect2(-260.0, -1820.0, 600.0, 560.0)
const HIVERNACLE := Rect2(910.0, -1960.0, 520.0, 680.0)
# La Cascada's pool, lapping the path's west edge
const POOL_TOP := -3820.0
const POOL_BOT := -3470.0
const POOL_LIP := 44.0
const CASCADA_C := Vector2(230.0, -3650.0)
const DRINK := Vector2(512.0, -3650.0)
const ZOO_WALL_X := 896.0
const GIRAFFES: Array[Vector2] = [Vector2(1010.0, -4240.0), Vector2(1060.0, -4520.0), Vector2(990.0, -4760.0)]
# the live event: where the flock waits, and when it goes for the croissant
const BIRDS_HOME := Vector2(850.0, -4300.0)
const BIRDS_Y := -4200.0
const BIRDS_WARN := 0.8
const SWOOP_TIME := 3.2
const SHOO_R := 180.0
const FLOCK := 7


static func edge_nodes(_m: Node2D) -> Array:
	return [
		{"y": 260.0, "cx": 640.0, "half": 300.0},
		{"y": -720.0, "cx": 640.0, "half": 300.0},
		{"y": -890.0, "cx": 640.0, "half": 170.0},
		{"y": -1030.0, "cx": 640.0, "half": 170.0},
		{"y": -1140.0, "cx": 640.0, "half": 240.0},
		{"y": -2080.0, "cx": 640.0, "half": 240.0},
		{"y": -2200.0, "cx": 645.0, "half": 325.0},
		{"y": -3200.0, "cx": 645.0, "half": 325.0},
		{"y": -3440.0, "cx": 720.0, "half": 230.0},
		{"y": -3920.0, "cx": 720.0, "half": 230.0},
		{"y": -4120.0, "cx": 640.0, "half": 240.0},
		{"y": -4860.0, "cx": 640.0, "half": 240.0},
		{"y": -5000.0, "cx": 640.0, "half": 260.0},
	]


static func build(m: Node2D) -> Array:
	m.gate_text = "ÀREA DE GOSSOS"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.mamut_dodges = 0
	m.mamut_splashed = false
	m.mamut_tripped = false
	m.mamut_bonked = false
	m.mamut_bowled = false
	m.mamut_booped = false
	m.mamut_sat = false
	m.mamut_settled = false
	m.ciut_shooed = false
	m.ciut_birds = {"state": "perched", "t": 0.0, "done": false}

	for lp: Vector2 in LAMPS:
		m.poles.append(lp)
	for gp: Vector2 in GATE_PIERS:
		m.poles.append(gp)
	for tr: Vector2 in AVENUE_TREES:
		m.poles.append(tr)
	for tr: Vector2 in BossMamut.ARENA_TREES:
		m.poles.append(tr)
	for pl: Vector2 in CASCADA_PALMS:
		m.poles.append(pl)
	for pl: Vector2 in ZOO_PALMS:
		m.poles.append(pl)
	m.deco_pole_count = m.poles.size()

	m.fountains = Array([DRINK], TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(372.0, -190.0), Vector2(908.0, -190.0), Vector2(372.0, -630.0), Vector2(908.0, -630.0),
		Vector2(420.0, -1380.0), Vector2(860.0, -1720.0), Vector2(420.0, -4560.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(372.0, -410.0), Vector2(908.0, -40.0), Vector2(860.0, -1240.0),
		Vector2(420.0, -1920.0), Vector2(905.0, -3560.0), Vector2(860.0, -4420.0),
	], TYPE_VECTOR2, &"", null)
	# your human steps round the plinth once the mammoth is back on it
	m.islands.append({"rect": Rect2(BossMamut.PLINTH - BossMamut.PLINTH_HALF - Vector2(20.0, 16.0),
		BossMamut.PLINTH_HALF * 2.0 + Vector2(40.0, 32.0)), "side": -1.0, "lead": 220.0})

	var mamut := BossMamut.new()
	mamut.setup(m)
	m.mamut = mamut

	var marks: Array[Vector2] = [
		Vector2(400.0, 60.0), Vector2(880.0, -380.0), Vector2(520.0, -960.0),
		Vector2(450.0, -1560.0), Vector2(830.0, -1960.0), Vector2(370.0, -2360.0),
		BossMamut.PLINTH + Vector2(-BossMamut.PLINTH_HALF.x - 10.0, 30.0),
		Vector2(540.0, -3420.0), Vector2(900.0, -3820.0), Vector2(455.0, -4300.0),
		Vector2(830.0, -4660.0),
	]
	var snacks: Array[Vector2] = [
		Vector2(700.0, -600.0), Vector2(560.0, -1650.0), Vector2(800.0, -3600.0), Vector2(560.0, -4460.0),
	]
	return [marks, snacks]


static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in ARC_PIERS:
		out.append(r)
	return out


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in ARC_PIERS:
		out.append(r)
	out.append(Rect2(BossMamut.PLINTH - BossMamut.PLINTH_HALF, BossMamut.PLINTH_HALF * 2.0))
	return out


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y <= float(m.GATE_Y):
		return -1
	if p.y > GATE_TOP:
		return Surfaces.S.PAVEMENT
	var e: Vector2 = m.walk_edges(p.y)
	var cx := (e.x + e.y) * 0.5
	if p.y > AVENUE_TOP or p.y < CASCADA_TOP:
		return Surfaces.S.PAVEMENT if absf(p.x - cx) < 165.0 else Surfaces.S.GRASS
	if p.y > ARENA_TOP:
		if Rect2(BossMamut.PLINTH - BossMamut.PLINTH_HALF, BossMamut.PLINTH_HALF * 2.0).grow(8.0).has_point(p):
			return Surfaces.S.PAVEMENT
		return Surfaces.S.PAVEMENT if p.x < e.x + 54.0 else Surfaces.S.GRASS
	if p.y > POOL_TOP and p.y < POOL_BOT and p.x < e.x + POOL_LIP:
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


static func tree_kind(m: Node2D, p: Vector2) -> int:
	if p.y > GATE_TOP:
		return m.TREE_NONE
	if p.y < ARENA_TOP:
		return m.TREE_PALM
	return m.TREE_PLANE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return p.y > PASSEIG_TOP


static func draw_column(m: Node2D, wc: Object, p: Vector2) -> void:
	if p.y > PASSEIG_TOP:
		m._draw_lamppost(p)
		return
	# a gate pier: dressed stone, a cap and an iron lantern on it
	var b: ShapeBatch = wc as ShapeBatch if wc is ShapeBatch else ShapeBatch.new(wc)
	b.rect(Rect2(p + Vector2(-16.0, -16.0) + Shade.light * 8.0, Vector2(32.0, 32.0)), SHADOW)
	b.rect(Rect2(p - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), Color(0.62, 0.58, 0.52))
	b.rect(Rect2(p - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), Color(0.74, 0.70, 0.64))
	b.circle(p, 7.0, Color(0.14, 0.15, 0.17))
	b.circle(p - Vector2(1.5, 1.5), 3.0, Color(0.96, 0.86, 0.56))
	if not (wc is ShapeBatch):
		b.flush(wc)


# --- The walk's tick and bark --------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.mamut != null:
		m.mamut.tick_state(delta)
	_tick_birds(m, delta)


static func on_bark(m: Node2D, pos: Vector2) -> bool:
	if m.mamut != null and m.mamut.on_bark_action(pos):
		return true
	var bd: Dictionary = m.ciut_birds
	if String(bd.state) == "swoop" and m.human.global_position.distance_to(m.dog.global_position) < SHOO_R:
		bd.state = "fled"
		bd.t = 0.0
		m.ciut_shooed = true
		Sfx.play("squawk", 1.1, -4.0)
		Sfx.play("star", 1.15, -5.0)
		m.award_points(3, "shoo! +3")
		m.combo.add("SHOO", 3)
		m.feed.say("SHOO! THE CROISSANT IS SAFE", EventFeed.Tone.GOOD)
		m.human.say_line("Thanks, pup.")
		return true
	if String(bd.state) == "perched" and pos.distance_to(BIRDS_HOME) < 160.0:
		Sfx.play("squawk", 1.0, -6.0)
		bd.ruffle = 1.0
	return false


static func idle_status(m: Node2D) -> String:
	return m.mamut.status() if m.mamut != null else ""


static func urgent_status(m: Node2D) -> String:
	if m.mamut != null:
		# the whole of what he asks of her, over the bladder and the reel
		var s: String = m.mamut.status()
		if s != "":
			return s
	var bd: Dictionary = m.ciut_birds
	if String(bd.state) == "swoop" and m.dog.global_position.distance_to(m.human.global_position) < 520.0:
		return Prompts.fill("PARAKEETS! {bark} TO SHOO THEM")
	return ""


static func hush_banner(m: Node2D) -> bool:
	return m.mamut != null and m.mamut.hush_banner()


static func cam_lean(m: Node2D) -> float:
	return m.mamut.lean if m.mamut != null else 0.0


# The monk parakeets of the zoo palms: as your human passes BIRDS_Y they
# notice them (the telegraph), then the flock swoops round their head for the
# croissant for SWOOP_TIME. A bark near your human shoos them; otherwise
# the croissant goes. Once a walk.
static func _tick_birds(m: Node2D, delta: float) -> void:
	var bd: Dictionary = m.ciut_birds
	bd.t = float(bd.t) + delta
	bd.ruffle = maxf(0.0, float(bd.get("ruffle", 0.0)) - delta)
	match String(bd.state):
		"perched":
			if not bool(bd.done) and m.human.global_position.y < BIRDS_Y and not m.human.homeward:
				bd.state = "warn"
				bd.t = 0.0
				bd.done = true
				m.human.notice("Ooh, parakeets!", BIRDS_WARN + 0.4)
				Sfx.play("squawk", 1.2, -6.0)
		"warn":
			if float(bd.t) >= BIRDS_WARN:
				bd.state = "swoop"
				bd.t = 0.0
				Sfx.play("squawk", 0.95, -3.0)
		"swoop":
			if fmod(float(bd.t), 0.5) < delta:
				Sfx.play("squawk", 0.9 + randf() * 0.3, -8.0)
			if float(bd.t) >= SWOOP_TIME:
				bd.state = "fled"
				bd.t = 0.0
				bd.stole = true
				m.human.notice("Hey! My croissant!", 1.8)
				Sfx.play("squawk", 1.3, -3.0)
		"fled":
			if float(bd.t) > 3.0:
				bd.state = "home"


# --- The ground: cached with the walk's cross-section -----------------------

static func draw_cross_section(m: Node2D, wc: Object, _top: float, bottom: float, _ctop: float,
		vt: float, vb: float) -> void:
	var gate_y: float = float(m.GATE_Y)
	var y0 := maxf(vt - 80.0, gate_y - 40.0)
	var y1 := minf(vb + 80.0, bottom)
	if y1 <= y0:
		return
	var b := ShapeBatch.new()
	var step := 32.0
	var sy := floorf(y0 / step) * step
	while sy < y1:
		var sb := minf(sy + step, y1)
		var ym := (sy + sb) * 0.5
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sb)
		var row := absi(int(floorf(sy / step)))
		var cxa := (ea.x + ea.y) * 0.5
		var cxb := (eb.x + eb.y) * 0.5
		if ym > PASSEIG_TOP:
			# terracotta tiles in courses, a pale stone band down the middle
			var col := Color(0.72, 0.50, 0.40) if row % 2 == 0 else Color(0.69, 0.47, 0.38)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), col)
			b.rect(Rect2(cxa - 90.0, sy, 180.0, sb - sy), Color(0.80, 0.74, 0.64))
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.56, 0.36, 0.28, 0.45), 1.4)
			var jx := ea.x + 32.0
			while jx < ea.y:
				if absf(jx - cxa) > 90.0:
					b.line(Vector2(jx, sy), Vector2(jx, sb), Color(0.56, 0.36, 0.28, 0.30), 1.2)
				jx += 32.0
			for kx: float in [ea.x + 64.0, ea.y - 64.0]:
				b.line(Vector2(kx, sy), Vector2(kx, sb), Color(0.86, 0.82, 0.74), 4.0)
			if row % 8 == 0:
				# the mosaic star set in the stone band
				var c := Vector2(cxa, ym)
				b.circle(c, 30.0, Color(0.62, 0.42, 0.30))
				b.circle(c, 24.0, Color(0.88, 0.82, 0.70))
				for i in range(8):
					var d := Vector2.from_angle(float(i) * TAU / 8.0)
					b.line(c, c + d * 22.0, Color(0.62, 0.42, 0.30), 3.0)
				b.circle(c, 6.0, Color(0.86, 0.58, 0.22))
		elif ym > GATE_TOP:
			var g := Color(0.60, 0.58, 0.55) if row % 2 == 0 else Color(0.57, 0.55, 0.52)
			b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), g)
			b.line(Vector2(ea.x, sy), Vector2(ea.y, sy), Color(0.42, 0.40, 0.38, 0.6), 1.6)
		elif ym > AVENUE_TOP or ym < CASCADA_TOP:
			_lawn(b, ea, eb, sy, sb, row)
			_gravel(b, cxa - 165.0, cxa + 165.0, cxb - 165.0, cxb + 165.0, sy, sb, row)
		elif ym > ARENA_TOP:
			_lawn(b, ea, eb, sy, sb, row)
			# the promenade along the west of the lawn
			_gravel(b, ea.x, ea.x + 54.0, eb.x, eb.x + 54.0, sy, sb, row)
		else:
			_gravel(b, ea.x, ea.y, eb.x, eb.y, sy, sb, row)
			if ym > POOL_TOP and ym < POOL_BOT:
				# the Cascada's pool comes right up to the path, behind a low lip
				b.rect(Rect2(ea.x, sy, POOL_LIP, sb - sy), Color(0.30, 0.56, 0.68))
				b.rect(Rect2(ea.x, sy, POOL_LIP - 10.0, sb - sy), Color(0.36, 0.64, 0.76))
				if row % 2 == 0:
					b.line(Vector2(ea.x + 6.0, ym), Vector2(ea.x + 26.0, ym), Color(0.80, 0.92, 0.98, 0.6), 1.6)
				b.line(Vector2(ea.x + POOL_LIP, sy), Vector2(eb.x + POOL_LIP, sb), Color(0.78, 0.74, 0.66), 5.0)
		sy += step

	# the Arc de Triomf's piers: red brick on a stone plinth
	for r: Rect2 in ARC_PIERS:
		if r.end.y < y0 or r.position.y > y1:
			continue
		b.rect(Rect2(r.position + Shade.light * 14.0, r.size), SHADOW)
		b.rect(r.grow(6.0), Color(0.70, 0.66, 0.58))
		b.rect(r, Color(0.66, 0.30, 0.20))
		var by := r.position.y + 6.0
		var k := 0
		while by < r.end.y - 4.0:
			b.line(Vector2(r.position.x, by), Vector2(r.end.x, by), Color(0.50, 0.22, 0.15), 1.4)
			var bx := r.position.x + (8.0 if k % 2 == 0 else 20.0)
			while bx < r.end.x:
				b.line(Vector2(bx, by), Vector2(bx, by + 8.0), Color(0.50, 0.22, 0.15), 1.0)
				bx += 24.0
			by += 8.0
			k += 1
		b.rect(Rect2(r.position + Vector2(14.0, 14.0), r.size - Vector2(28.0, 28.0)), Color(0.76, 0.40, 0.28))

	# the gate line: railings to either side of the opening
	if -950.0 > y0 and -950.0 < y1:
		var e: Vector2 = m.walk_edges(-950.0)
		for side: float in [-1.0, 1.0]:
			var x0 := e.x if side < 0.0 else e.y
			b.line(Vector2(x0, -950.0), Vector2(x0 + side * 4.0, -950.0), Color(0.14, 0.15, 0.17), 4.0)

	# off-leash threshold band at the gate
	if gate_y - 90.0 <= y1 and gate_y + 60.0 >= y0:
		var te: Vector2 = m.walk_edges(gate_y)
		b.rect(Rect2(te.x - 10.0, gate_y - 80.0, te.y - te.x + 20.0, 118.0), Color(0.42, 0.32, 0.22))
		b.rect(Rect2(te.x - 4.0, gate_y - 74.0, te.y - te.x + 8.0, 106.0), Color(0.26, 0.24, 0.22))
	b.flush(wc)


static func _lawn(b: ShapeBatch, ea: Vector2, eb: Vector2, sy: float, sb: float, row: int) -> void:
	var g := Color(0.38, 0.58, 0.28) if (row / 2) % 2 == 0 else Color(0.35, 0.55, 0.26)
	b.quad(Vector2(ea.x, sy), Vector2(ea.y, sy), Vector2(eb.y, sb), Vector2(eb.x, sb), g)
	if row % 3 == 0:
		var x := ea.x + 18.0 + float((row * 37) % 50)
		while x < ea.y - 10.0:
			b.line(Vector2(x, sy + 10.0), Vector2(x + 3.0, sy + 4.0), Color(0.46, 0.66, 0.32), 1.5)
			x += 58.0


static func _gravel(b: ShapeBatch, xa0: float, xa1: float, xb0: float, xb1: float, sy: float, sb: float, row: int) -> void:
	# sauló: the park's packed sandy gravel, with a darker worn edge
	var col := Color(0.80, 0.71, 0.54) if row % 2 == 0 else Color(0.78, 0.69, 0.52)
	b.quad(Vector2(xa0, sy), Vector2(xa1, sy), Vector2(xb1, sb), Vector2(xb0, sb), col)
	b.line(Vector2(xa0, sy), Vector2(xb0, sb), Color(0.62, 0.54, 0.40), 3.0)
	b.line(Vector2(xa1, sy), Vector2(xb1, sb), Color(0.62, 0.54, 0.40), 3.0)
	var x := xa0 + 9.0 + float((row * 23) % 31)
	while x < xa1 - 6.0:
		b.circle(Vector2(x, sy + float((int(x) * 7) % 26) + 3.0), 1.6, Color(0.64, 0.56, 0.42))
		x += 29.0


# --- What flanks the walk: cached on the edge layer --------------------------

static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)
	var gate_y: float = float(m.GATE_Y)
	var y_top := maxf(vt - 240.0, gate_y - 30.0)
	var y_bot := minf(vb + 240.0, float(m.START_Y) + 560.0)
	if y_bot <= y_top:
		return
	var step := 48.0
	var sy := floorf(y_top / step) * step
	while sy < y_bot:
		var sb := minf(sy + step, y_bot)
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sb)
		var ym := (sy + sb) * 0.5
		var row := absi(int(floorf(sy / step)))
		if ym > PASSEIG_TOP:
			# the promenade's side carriageways, then the city blocks
			for side: float in [-1.0, 1.0]:
				var xa := ea.x if side < 0.0 else ea.y
				var xb := eb.x if side < 0.0 else eb.y
				var far := -480.0 if side < 0.0 else 1760.0
				b.quad(Vector2(xa, sy), Vector2(far, sy), Vector2(far, sb), Vector2(xb, sb), Color(0.30, 0.31, 0.33))
				b.line(Vector2(xa, sy), Vector2(xb, sb), Color(0.80, 0.76, 0.68), 6.0)
				if row % 2 == 0:
					b.line(Vector2(xa + side * 110.0, sy), Vector2(xa + side * 110.0, sy + 24.0), Color(0.86, 0.84, 0.76), 3.0)
				var bx := xa + side * 200.0
				b.rect(Rect2(minf(bx, far), sy, absf(far - bx), sb - sy), Color(0.86, 0.80, 0.68) if row % 5 != 0 else Color(0.80, 0.74, 0.62))
				b.line(Vector2(bx, sy), Vector2(bx, sb), Color(0.62, 0.56, 0.46), 4.0)
				if row % 2 == 1:
					b.rect(Rect2(bx + (6.0 if side > 0.0 else -22.0), sy + 10.0, 16.0, 26.0), Color(0.42, 0.34, 0.28))
				# palms on the carriageway's verge
				if row % 3 == 0:
					var pp := Vector2(xa + side * 54.0, ym)
					b.circle(pp + Shade.light * 10.0, 24.0, SHADOW)
					for i in range(7):
						var d := Vector2.from_angle(float(i) * TAU / 7.0 + float(row))
						b.line(pp, pp + d * 30.0, Color(0.22, 0.48, 0.24), 6.0)
					b.circle(pp, 6.0, Color(0.46, 0.36, 0.24))
		elif ym > GATE_TOP:
			for side: float in [-1.0, 1.0]:
				var xa := ea.x if side < 0.0 else ea.y
				var xb := eb.x if side < 0.0 else eb.y
				var far := -480.0 if side < 0.0 else 1760.0
				b.quad(Vector2(xa, sy), Vector2(far, sy), Vector2(far, sb), Vector2(xb, sb), Color(0.34, 0.52, 0.28))
			if absf(ym + 950.0) < 30.0:
				# the iron railings along the park's edge
				for side: float in [-1.0, 1.0]:
					var x0 := ea.x if side < 0.0 else ea.y
					var x1 := -480.0 if side < 0.0 else 1760.0
					b.line(Vector2(x0, -950.0), Vector2(x1, -950.0), Color(0.14, 0.15, 0.17), 4.0)
					var x := x0
					while (x > x1) if side < 0.0 else (x < x1):
						b.circle(Vector2(x, -950.0), 3.0, Color(0.22, 0.23, 0.26))
						b.circle(Vector2(x, -950.0), 1.4, Color(0.74, 0.62, 0.30))
						x += side * 18.0
		else:
			for side: float in [-1.0, 1.0]:
				var xa := ea.x if side < 0.0 else ea.y
				var xb := eb.x if side < 0.0 else eb.y
				var far := -480.0 if side < 0.0 else 1760.0
				var lawn := Color(0.34, 0.53, 0.26) if (row / 2) % 2 == 0 else Color(0.32, 0.51, 0.25)
				b.quad(Vector2(xa, sy), Vector2(far, sy), Vector2(far, sb), Vector2(xb, sb), lawn)
				b.line(Vector2(xa, sy), Vector2(xb, sb), Color(0.26, 0.42, 0.20), 3.0)
				# a low box hedge along the lawn's edge
				b.line(Vector2(xa + side * 10.0, sy), Vector2(xb + side * 10.0, sb), Color(0.20, 0.38, 0.18), 9.0)
		sy += step

	_draw_castle(b, y_top, y_bot)
	_draw_hivernacle(b, y_top, y_bot)
	_draw_lake(b, y_top, y_bot)
	_draw_cascada(b, y_top, y_bot)
	_draw_zoo(b, y_top, y_bot)
	_draw_parlament(b, y_top, y_bot)
	if not (c is ShapeBatch):
		b.flush(c)


# Domènech's Castell dels Tres Dragons from above: red brick round a court,
# crenellated, corner towers, white ceramic shields on the parapet.
static func _draw_castle(b: ShapeBatch, y0: float, y1: float) -> void:
	var r := CASTLE
	if r.end.y < y0 or r.position.y > y1:
		return
	b.rect(Rect2(r.position + Shade.light * 24.0, r.size), SHADOW)
	b.rect(r, Color(0.62, 0.28, 0.20))
	b.rect(r.grow(-26.0), Color(0.72, 0.42, 0.30))
	b.rect(r.grow(-70.0), Color(0.58, 0.54, 0.48))
	var x := r.position.x
	while x < r.end.x:
		for yy: float in [r.position.y, r.end.y - 10.0]:
			b.rect(Rect2(x, yy, 14.0, 10.0), Color(0.78, 0.38, 0.26))
		x += 24.0
	var y := r.position.y
	while y < r.end.y:
		b.rect(Rect2(r.end.x - 10.0, y, 10.0, 14.0), Color(0.78, 0.38, 0.26))
		y += 24.0
	for i in range(6):
		var sp := Vector2(r.end.x - 4.0, r.position.y + 60.0 + float(i) * 88.0)
		b.circle(sp, 9.0, Color(0.94, 0.94, 0.92))
		b.circle(sp, 5.0, Color(0.28, 0.46, 0.72))
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		b.rect(Rect2(corner - Vector2(36.0, 36.0), Vector2(72.0, 72.0)), Color(0.56, 0.24, 0.17))
		b.rect(Rect2(corner - Vector2(26.0, 26.0), Vector2(52.0, 52.0)), Color(0.70, 0.40, 0.28))
		b.circle(corner, 12.0, Color(0.42, 0.44, 0.36))
	# the central tower over the entrance
	var tc := Vector2(r.end.x - 60.0, r.get_center().y)
	b.rect(Rect2(tc - Vector2(44.0, 44.0), Vector2(88.0, 88.0)), Color(0.56, 0.24, 0.17))
	b.rect(Rect2(tc - Vector2(32.0, 32.0), Vector2(64.0, 64.0)), Color(0.76, 0.46, 0.32))
	b.circle(tc, 14.0, Color(0.88, 0.76, 0.30))


# The Hivernacle: three glass halls in an iron frame, plants inside.
static func _draw_hivernacle(b: ShapeBatch, y0: float, y1: float) -> void:
	var r := HIVERNACLE
	if r.end.y < y0 or r.position.y > y1:
		return
	b.rect(Rect2(r.position + Shade.light * 18.0, r.size), SHADOW)
	b.rect(r, Color(0.20, 0.24, 0.24))
	var halls: Array[Rect2] = [
		Rect2(r.position.x + 10.0, r.position.y + 10.0, r.size.x - 20.0, 200.0),
		Rect2(r.position.x + 10.0, r.position.y + 230.0, r.size.x - 20.0, 220.0),
		Rect2(r.position.x + 10.0, r.position.y + 470.0, r.size.x - 20.0, r.size.y - 480.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1884
	for h: Rect2 in halls:
		b.rect(h, Color(0.62, 0.80, 0.78))
		for i in range(10):
			var pp := h.position + Vector2(rng.randf_range(20.0, h.size.x - 20.0), rng.randf_range(20.0, h.size.y - 20.0))
			b.circle(pp, rng.randf_range(12.0, 24.0), Color(0.30, 0.56, 0.34, 0.75))
		var gx := h.position.x
		while gx < h.end.x:
			b.line(Vector2(gx, h.position.y), Vector2(gx, h.end.y), Color(0.86, 0.94, 0.92, 0.55), 2.0)
			gx += 30.0
		b.line(Vector2(h.position.x, h.get_center().y), Vector2(h.end.x, h.get_center().y), Color(0.18, 0.22, 0.22), 4.0)
		b.rect(Rect2(h.position, Vector2(h.size.x, 24.0)), Color(0.80, 0.92, 0.94, 0.35))


# The boating lake east of the mammoth's lawn, its stone lip and an islet.
static func _draw_lake(b: ShapeBatch, y0: float, y1: float) -> void:
	var top := BossMamut.LAKE_TOP
	var bot := BossMamut.LAKE_BOT
	if bot < y0 or top > y1:
		return
	var sx := BossMamut.SHORE_X
	b.rect(Rect2(sx - 6.0, top - 20.0, 900.0, bot - top + 40.0), Color(0.72, 0.68, 0.60))
	b.rect(Rect2(sx, top, 900.0, bot - top), Color(0.30, 0.52, 0.62))
	b.band(PackedVector2Array([
		Vector2(sx, top), Vector2(sx + 900.0, top), Vector2(sx, top + 160.0), Vector2(sx + 900.0, top + 160.0),
	]), 2, Color(0.46, 0.66, 0.74), PackedFloat32Array([0.6, 0.0]))
	var y := top + 40.0
	var k := 0
	while y < bot - 20.0:
		var x := sx + 40.0 + float((k * 53) % 90)
		while x < sx + 860.0:
			b.line(Vector2(x, y), Vector2(x + 26.0, y), Color(0.62, 0.80, 0.88, 0.45), 1.6)
			x += 120.0
		y += 46.0
		k += 1
	# lily pads by the shore
	for lp: Vector2 in [Vector2(sx + 40.0, -2420.0), Vector2(sx + 70.0, -2440.0), Vector2(sx + 30.0, -3050.0)]:
		b.circle(lp, 10.0, Color(0.28, 0.52, 0.28))
		b.circle(lp + Vector2(3.0, -2.0), 2.5, Color(0.96, 0.72, 0.80))
	# the islet with its little round temple
	var isl := Vector2(sx + 420.0, -2720.0)
	b.circle(isl + Shade.light * 10.0, 90.0, Color(0.10, 0.20, 0.26, 0.3))
	b.circle(isl, 90.0, Color(0.38, 0.54, 0.28))
	b.circle(isl, 36.0, Color(0.82, 0.78, 0.70))
	b.circle(isl, 26.0, Color(0.70, 0.66, 0.58))
	for i in range(8):
		b.circle(isl + Vector2.from_angle(float(i) * TAU / 8.0) * 30.0, 4.0, Color(0.92, 0.90, 0.84))


# La Cascada: Fontserè's monumental fountain from above, west of the path:
# the basin lapping the path's lip, the water falling over the rockwork in
# foam, the carved roof with its balustrades and urns, the grotto's dark
# arches facing the path, and on top the gilded Quadriga de l'Aurora, four
# horses rearing toward the path.
static func _draw_cascada(b: ShapeBatch, y0: float, y1: float) -> void:
	var c := CASCADA_C
	if c.y + 420.0 < y0 or c.y - 420.0 > y1:
		return
	var e_x := 490.0
	var mon := Rect2(c.x - 320.0, c.y - 250.0, 300.0, 500.0)
	var fall_x := mon.end.x
	# the basin, from the foot of the falls to the path's lip
	b.rect(Rect2(fall_x, POOL_TOP - 30.0, e_x - fall_x, POOL_BOT - POOL_TOP + 60.0), Color(0.74, 0.70, 0.62))
	b.rect(Rect2(fall_x, POOL_TOP, e_x - fall_x, POOL_BOT - POOL_TOP), Color(0.30, 0.56, 0.68))
	b.band(PackedVector2Array([
		Vector2(fall_x, POOL_TOP), Vector2(fall_x, POOL_BOT), Vector2(fall_x + 150.0, POOL_TOP), Vector2(fall_x + 150.0, POOL_BOT),
	]), 2, Color(0.78, 0.92, 0.98), PackedFloat32Array([0.55, 0.0]))
	for i in range(7):
		var ry := POOL_TOP + 26.0 + float(i) * 50.0
		b.line(Vector2(fall_x + 170.0, ry), Vector2(e_x - 20.0, ry + 6.0), Color(0.78, 0.92, 0.98, 0.35), 2.0)
	# the monument's sides run on north and south as balustraded terraces
	b.rect(Rect2(-480.0, c.y - 330.0, fall_x + 480.0, 80.0), Color(0.78, 0.74, 0.64))
	b.rect(Rect2(-480.0, c.y + 250.0, fall_x + 480.0, 80.0), Color(0.78, 0.74, 0.64))
	for yy: float in [c.y - 254.0, c.y + 254.0]:
		var bx := -470.0
		while bx < fall_x:
			b.circle(Vector2(bx, yy), 3.0, Color(0.92, 0.89, 0.82))
			bx += 14.0
	b.rect(Rect2(mon.position + Shade.light * 26.0, mon.size), SHADOW)
	b.rect(mon, Color(0.64, 0.58, 0.48))
	b.rect(mon.grow(-14.0), Color(0.80, 0.75, 0.63))
	b.rect(mon.grow(-44.0), Color(0.72, 0.67, 0.56))
	# balustrade round the roof and urns on its corners
	var bx2 := mon.position.x + 20.0
	while bx2 < mon.end.x - 14.0:
		for yy: float in [mon.position.y + 7.0, mon.end.y - 7.0]:
			b.circle(Vector2(bx2, yy), 3.0, Color(0.94, 0.91, 0.84))
		bx2 += 14.0
	for corner: Vector2 in [mon.position, Vector2(mon.end.x, mon.position.y), Vector2(mon.position.x, mon.end.y), mon.end]:
		b.circle(corner, 16.0, Color(0.58, 0.52, 0.42))
		b.circle(corner, 10.0, Color(0.86, 0.80, 0.68))
	# the grotto: dark arches in the face toward the path
	for i in range(3):
		var ay := c.y - 120.0 + float(i) * 120.0
		b.circle(Vector2(fall_x - 8.0, ay), 30.0, Color(0.26, 0.22, 0.20))
		b.rect(Rect2(fall_x - 8.0, ay - 30.0, 10.0, 60.0), Color(0.26, 0.22, 0.20))
	# the rockwork the water falls over, and its foam in the basin
	var rng := RandomNumberGenerator.new()
	rng.seed = 1881
	b.rect(Rect2(fall_x, c.y - 170.0, 70.0, 340.0), Color(0.66, 0.84, 0.94))
	for i in range(12):
		var rp := Vector2(fall_x + rng.randf_range(4.0, 66.0), c.y + rng.randf_range(-160.0, 160.0))
		b.circle(rp, rng.randf_range(12.0, 22.0), Color(0.50, 0.42, 0.32))
		b.circle(rp - Shade.light * 4.0, rng.randf_range(6.0, 10.0), Color(0.62, 0.54, 0.42))
	for i in range(18):
		var fp := Vector2(fall_x + 74.0 + rng.randf_range(0.0, 30.0), c.y + rng.randf_range(-170.0, 170.0))
		b.circle(fp, rng.randf_range(6.0, 12.0), Color(0.96, 0.99, 1.0, 0.85))
	# twin stairs climbing to the terraces
	for sd: float in [-1.0, 1.0]:
		var sr := Rect2(fall_x - 10.0, c.y + sd * 290.0 - 30.0, 90.0, 60.0)
		b.rect(sr, Color(0.72, 0.66, 0.56))
		var sx := sr.position.x
		while sx < sr.end.x:
			b.line(Vector2(sx, sr.position.y), Vector2(sx, sr.end.y), Color(0.58, 0.52, 0.44), 2.0)
			sx += 10.0
	# the Quadriga de l'Aurora: the chariot, Aurora in it, four horses fanned out ahead
	var q := Vector2(mon.get_center().x - 10.0, c.y)
	b.circle(q + Shade.light * 14.0, 70.0, SHADOW)
	b.circle(q, 44.0, Color(0.56, 0.50, 0.40))
	var gold := Color(0.86, 0.68, 0.24)
	var gold_lit := Color(0.98, 0.86, 0.44)
	b.rect(Rect2(q - Vector2(30.0, 22.0), Vector2(34.0, 44.0)), gold.darkened(0.2))
	b.circle(q + Vector2(-14.0, 0.0), 10.0, gold_lit)
	for i in range(4):
		var a := lerpf(-0.75, 0.75, float(i) / 3.0)
		var d := Vector2.from_angle(a)
		var hip := q + Vector2(10.0, lerpf(-18.0, 18.0, float(i) / 3.0))
		var body := hip + d * 34.0
		b.capsule(hip + d * 10.0, body, 9.0, gold.darkened(0.1))
		b.capsule(hip + d * 12.0, body, 6.5, gold)
		b.capsule(body, body + d * 18.0 + d.orthogonal() * 3.0, 5.0, gold)
		b.circle(body + d * 22.0, 6.0, gold_lit)


static func _draw_zoo(b: ShapeBatch, y0: float, y1: float) -> void:
	if y1 < CASCADA_TOP - 900.0 or y0 > CASCADA_TOP:
		return
	var top := maxf(y0, -4900.0)
	var bot := minf(y1, CASCADA_TOP - 60.0)
	if bot <= top:
		return
	# the enclosure's sand beyond the wall, the wall with its tiled coping
	b.rect(Rect2(ZOO_WALL_X + 34.0, top, 900.0, bot - top), Color(0.82, 0.72, 0.52))
	b.rect(Rect2(ZOO_WALL_X, top, 34.0, bot - top), Color(0.86, 0.72, 0.50))
	b.rect(Rect2(ZOO_WALL_X, top, 8.0, bot - top), Color(0.62, 0.30, 0.20))
	var y := floorf(top / 40.0) * 40.0
	while y < bot:
		b.line(Vector2(ZOO_WALL_X + 8.0, y), Vector2(ZOO_WALL_X + 34.0, y), Color(0.72, 0.58, 0.40), 1.4)
		y += 40.0
	# acacia crowns and a feeding rack in the giraffe yard
	for ap: Vector2 in [Vector2(1180.0, -4380.0), Vector2(1240.0, -4680.0)]:
		if ap.y > top - 80.0 and ap.y < bot + 80.0:
			b.circle(ap + Shade.light * 10.0, 60.0, SHADOW)
			b.circle(ap, 60.0, Color(0.36, 0.52, 0.26))
			b.circle(ap - Shade.light * 10.0, 36.0, Color(0.46, 0.62, 0.32))


static func _draw_parlament(b: ShapeBatch, y0: float, y1: float) -> void:
	var r := Rect2(-380.0, -4760.0, 640.0, 420.0)
	if r.end.y < y0 or r.position.y > y1:
		return
	b.rect(Rect2(r.position + Shade.light * 22.0, r.size), SHADOW)
	b.rect(r, Color(0.84, 0.80, 0.70))
	b.rect(r.grow(-30.0), Color(0.56, 0.58, 0.62))
	b.rect(Rect2(r.end.x - 40.0, r.position.y, 40.0, r.size.y), Color(0.90, 0.86, 0.76))
	var cy := r.position.y + 20.0
	while cy < r.end.y - 10.0:
		b.circle(Vector2(r.end.x - 20.0, cy), 7.0, Color(0.96, 0.94, 0.88))
		cy += 36.0
	# the pond in front, and the flagpole
	b.rect(Rect2(r.end.x + 20.0, r.position.y + 100.0, 90.0, 220.0), Color(0.72, 0.68, 0.60))
	b.rect(Rect2(r.end.x + 26.0, r.position.y + 106.0, 78.0, 208.0), Color(0.34, 0.58, 0.70))
	var fp := Vector2(r.end.x - 70.0, r.get_center().y)
	b.circle(fp, 5.0, Color(0.60, 0.60, 0.62))
	for i in range(4):
		b.rect(Rect2(fp + Vector2(4.0, -2.0 + float(i) * 5.0), Vector2(40.0, 2.5)),
			Color(0.88, 0.16, 0.14) if i % 2 == 0 else Color(0.98, 0.82, 0.18))


# --- What moves: the mammoth, the crowd, the giraffes, the parakeets --------

static func draw_live(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)
	var t: float = AnimClock.msec() / 1000.0
	var mam: BossMamut = m.mamut
	if mam != null and BossMamut.PLINTH.y > vt - 600.0 and BossMamut.PLINTH.y < vb + 600.0:
		mam.draw_ground(b, vt, vb)
		mam.draw_warnings(b, t)
		mam.draw_crowd(b, vt, vb, t)
		if mam.pos.y > vt - 240.0 and mam.pos.y < vb + 240.0:
			mam.draw_mamut(b, t)
		mam.draw_rings(b, t)
		mam.draw_bits(b, vt, vb)
		mam.draw_health_bar(b)
	_draw_giraffes(b, vt, vb, t)
	_draw_birds(m, b, vt, vb, t)
	if not (c is ShapeBatch):
		b.flush(c)


static func _draw_giraffes(b: ShapeBatch, vt: float, vb: float, t: float) -> void:
	for i in range(GIRAFFES.size()):
		var g: Vector2 = GIRAFFES[i]
		if g.y < vt - 160.0 or g.y > vb + 160.0:
			continue
		var sway := sin(t * 0.7 + float(i) * 2.1) * 0.25
		# the body in the yard, the neck reaching over the wall toward the path
		b.polygon(BossMamut._ellipse(g + Shade.light * 18.0, Vector2.LEFT, 46.0, 26.0, 14), SHADOW)
		b.polygon(BossMamut._ellipse(g, Vector2.LEFT, 44.0, 24.0, 14), Color(0.88, 0.66, 0.32))
		for k in range(6):
			b.circle(g + Vector2(-26.0 + float(k) * 11.0, float((k * 7) % 11) - 6.0), 5.0, Color(0.56, 0.34, 0.16))
		var neck_dir := Vector2.LEFT.rotated(sway)
		var head := g + neck_dir * 120.0 + Vector2(0.0, -10.0)
		b.line(g + Vector2(-30.0, 0.0), head, Color(0.86, 0.64, 0.30), 14.0)
		for k in range(4):
			var np := (g + Vector2(-30.0, 0.0)).lerp(head, 0.2 + float(k) * 0.2)
			b.circle(np, 4.0, Color(0.56, 0.34, 0.16))
		b.polygon(BossMamut._ellipse(head + neck_dir * 10.0, neck_dir, 18.0, 10.0, 12), Color(0.90, 0.70, 0.36))
		for sd: float in [-1.0, 1.0]:
			b.circle(head + neck_dir.orthogonal() * sd * 7.0 - neck_dir * 4.0, 3.0, Color(0.40, 0.26, 0.14))
		b.circle(head + neck_dir * 24.0, 3.0, Color(0.30, 0.20, 0.12))


static func _draw_birds(m: Node2D, b: ShapeBatch, vt: float, vb: float, t: float) -> void:
	if BIRDS_HOME.y < vt - 700.0 or BIRDS_HOME.y > vb + 700.0:
		return
	var bd: Dictionary = m.ciut_birds
	var st := String(bd.state)
	var bt := float(bd.t)
	var hh: Vector2 = m.human.global_position + Vector2(0.0, -26.0)
	for i in range(FLOCK):
		var ph := float(i) * TAU / float(FLOCK)
		var home := BIRDS_HOME + Vector2(cos(ph) * 18.0, sin(ph) * 12.0)
		var p := home
		var flap := 0.0
		match st:
			"perched", "home", "warn":
				p = home + Vector2(sin(t * 3.0 + ph) * 2.0, 0.0)
				if float(bd.get("ruffle", 0.0)) > 0.0:
					p += Vector2.from_angle(ph) * 22.0 * float(bd.ruffle)
					flap = 1.0
			"swoop":
				var k := clampf(bt / 0.6, 0.0, 1.0)
				var orbit := hh + Vector2.from_angle(ph + t * 5.0) * (34.0 + sin(t * 7.0 + ph) * 8.0)
				p = home.lerp(orbit, k)
				flap = 1.0
			"fled":
				var away := Vector2.from_angle(ph * 0.3 - 1.9)
				p = hh + away * bt * 260.0
				flap = 1.0
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		var w := absf(sin(t * 22.0 + ph)) * 7.0 * flap + 3.0
		b.line(p + Vector2(-w, -2.0), p + Vector2(w, -2.0), Color(0.18, 0.56, 0.26), 3.0)
		b.circle(p, 5.0, Color(0.36, 0.72, 0.30))
		b.circle(p + Vector2(0.0, 2.0), 3.2, Color(0.74, 0.86, 0.48))
		b.circle(p + Vector2(0.0, -4.0), 3.0, Color(0.40, 0.76, 0.34))
		b.circle(p + Vector2(0.0, -6.5), 1.4, Color(0.98, 0.72, 0.40))
	# the croissant in your human's hand while it is still theirs
	if st == "warn" or st == "swoop":
		var cp: Vector2 = m.human.global_position + Vector2(12.0, -8.0)
		b.capsule(cp - Vector2(6.0, 0.0), cp + Vector2(6.0, 0.0), 4.0, Color(0.86, 0.60, 0.26))
		b.circle(cp, 3.2, Color(0.94, 0.74, 0.38))


# --- Overhead: the Arc de Triomf's span ---------------------------------------

static func draw_overhead(m: Node2D, wc: Object) -> void:
	var vt: float = m.view_lo(320.0)
	var vb: float = m.view_hi(320.0)
	if ARC_Y + 120.0 < vt or ARC_Y - 120.0 > vb:
		return
	var b := ShapeBatch.new()
	var r := Rect2(296.0, ARC_Y - 70.0, 688.0, 90.0)
	b.rect(Rect2(r.position + Shade.light * 20.0, r.size), Color(0.04, 0.03, 0.07, 0.26))
	b.rect(r, Color(0.62, 0.28, 0.19))
	b.rect(r.grow(-8.0), Color(0.72, 0.36, 0.24))
	# the stone frieze along its face and the bats' crown at the middle
	b.rect(Rect2(r.position.x + 20.0, r.end.y - 22.0, r.size.x - 40.0, 12.0), Color(0.84, 0.78, 0.66))
	var x := r.position.x + 30.0
	while x < r.end.x - 30.0:
		b.rect(Rect2(x, r.position.y + 10.0, 12.0, 18.0), Color(0.80, 0.42, 0.28))
		x += 30.0
	var mid := Vector2(r.get_center().x, r.position.y + 30.0)
	b.circle(mid, 22.0, Color(0.84, 0.70, 0.30))
	b.circle(mid, 14.0, Color(0.92, 0.80, 0.42))
	for sd: float in [-1.0, 1.0]:
		b.line(mid + Vector2(sd * 20.0, 0.0), mid + Vector2(sd * 44.0, -10.0), Color(0.84, 0.70, 0.30), 5.0)
	b.flush(wc)
