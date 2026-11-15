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
# benches, a Bicing dock and a kiosk; then the tram's grass track (la via
# verda) with its rails and catenary masts. The grass holds the best smells;
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
const MAST_X := 828.0                  # catenary masts on the grass edge
const ROAD_W := 78.0                   # the side road each side
const WALK_W := 36.0                   # the pavement along the blocks
const BLOCK_L := WALL_L - ROAD_W - WALK_W   # where the blocks are cut off
const BLOCK_R := WALL_R + ROAD_W + WALK_W

# the grid: blocks BLOCK wide on a PITCH lattice turned 45 degrees,
# chamfered corners CHAMFER deep, built DEPTH deep round a courtyard
const PITCH := 430.0
const BLOCK := 340.0
const CHAMFER := 56.0
const DEPTH := 96.0

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

const KIOSK := Rect2(372.0, -2330.0, 58.0, 84.0)
const BICING := Rect2(372.0, -3560.0, 34.0, 160.0)
const PRIZE := Vector2(470.0, -3180.0)
const PRIZE_TEXT := "snatch the bocadillo off the bench"

const PROMENADE := Color(0.74, 0.72, 0.67)
const PROMENADE_JOINT := Color(0.64, 0.62, 0.58)
const SAULO := Color(0.80, 0.72, 0.56)
const TRACK_GRASS := Color(0.38, 0.56, 0.28)
const TRACK_GRASS_LIT := Color(0.46, 0.64, 0.34)
const RAIL := Color(0.62, 0.62, 0.64)
const RAIL_DARK := Color(0.30, 0.30, 0.32)
const KERB := Color(0.60, 0.59, 0.56)
const ASPHALT := Color(0.27, 0.27, 0.29)
const LANE_LINE := Color(0.88, 0.87, 0.82, 0.85)
const PAVEMENT := Color(0.70, 0.67, 0.62)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
const ROOF_TONES: Array[Color] = [
	Color(0.74, 0.46, 0.34), Color(0.80, 0.56, 0.40), Color(0.70, 0.50, 0.40),
	Color(0.84, 0.76, 0.62), Color(0.66, 0.42, 0.32),
]
const PARAPET := Color(0.88, 0.84, 0.76)
const COURTYARD := Color(0.36, 0.48, 0.32)
const HEDGE := Color(0.24, 0.40, 0.24)
const TRAM_WHITE := Color(0.95, 0.95, 0.93)
const TRAM_GREEN := Color(0.22, 0.62, 0.40)
const TRAM_GLASS := Color(0.20, 0.28, 0.34)
const SIGNAL_OFF := Color(0.30, 0.26, 0.18)
const SIGNAL_ON := Color(1.0, 0.72, 0.16)


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
	if p.x > TRACK_L:
		return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT


static func on_track(p: Vector2) -> bool:
	return p.x > TRACK_X - TRAM_HALF_W - 6.0 and p.x < TRACK_X + TRAM_HALF_W + 6.0


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
			if not (KIOSK.grow(50.0).has_point(Vector2(tx, ty)) or BICING.grow(50.0).has_point(Vector2(tx, ty))):
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
		Vector2(WALL_L + 92.0, -760.0), Vector2(WALL_L + 92.0, -1880.0),
		Vector2(TRACK_L - 84.0, -2760.0), Vector2(WALL_L + 92.0, -3180.0),
		Vector2(TRACK_L - 84.0, -4180.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(WALL_L + 24.0, -420.0), Vector2(TRACK_L - 24.0, -1560.0),
		Vector2(WALL_L + 24.0, -2980.0), Vector2(TRACK_L - 24.0, -3900.0),
	], TYPE_VECTOR2, &"", null)
	if "fountains" in m:
		m.fountains = Array([Vector2(WALL_L + 30.0, -1300.0), Vector2(WALL_L + 30.0, -4420.0)], TYPE_VECTOR2, &"", null)
	# marking spots: pilones on the promenade, and two on the grass by the
	# rails, where the smells are and the tram is
	var hyd: Array[Vector2] = [
		Vector2(WALL_L + 20.0, -240.0), Vector2(TRACK_L + 18.0, -1180.0),
		Vector2(WALL_L + 20.0, -2160.0), Vector2(TRACK_L + 18.0, -3360.0),
		Vector2(WALL_L + 20.0, -4560.0),
	]
	var keb: Array[Vector2] = [
		Vector2(560.0, -900.0), Vector2(700.0, -2500.0), Vector2(600.0, -3800.0), Vector2(880.0, -4300.0),
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
		return "OFF THE TRACKS! THE TRAM"
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
	# granite slabs, staggered rows
	var row := int(floorf(lo / 64.0))
	var sy := float(row) * 64.0
	while sy < hi:
		wc.line(Vector2(WALL_L, sy), Vector2(TRACK_L, sy), PROMENADE_JOINT, 1.3)
		var sx := WALL_L + (0.0 if row % 2 == 0 else 48.0)
		while sx < TRACK_L:
			wc.line(Vector2(sx, sy), Vector2(sx, sy + 64.0), PROMENADE_JOINT, 1.1)
			sx += 96.0
		row += 1
		sy += 64.0
	# a strip of sauló down each row of plane trees
	for tx: float in [WALL_L + 44.0, TRACK_L - 40.0]:
		wc.rect(Rect2(tx - 22.0, lo, 44.0, hi - lo), SAULO)
	# the track: grass between and beside the rails, a kerb on its edge
	wc.rect(Rect2(TRACK_L, lo, WALL_R - TRACK_L, hi - lo), TRACK_GRASS)
	var gy := floorf(lo / 46.0) * 46.0
	var gi := 0
	while gy < hi:
		var gx := TRACK_L + 10.0 + _h(int(gy) + gi) * (WALL_R - TRACK_L - 20.0)
		wc.circle(Vector2(gx, gy), 7.0 + _h(gi + int(gy) * 3) * 6.0, TRACK_GRASS_LIT)
		gy += 46.0
		gi += 1
	wc.rect(Rect2(TRACK_L - 4.0, lo, 6.0, hi - lo), KERB)
	for s: float in [-1.0, 1.0]:
		var rx := TRACK_X + s * RAIL_GAP
		wc.rect(Rect2(rx - 3.0, lo, 6.0, hi - lo), RAIL_DARK)
		wc.rect(Rect2(rx - 1.5, lo, 3.0, hi - lo), RAIL)


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
	# the side roads with their lane lines, a kerb on the promenade's side
	for side: float in [-1.0, 1.0]:
		var wall := WALL_L if side < 0.0 else WALL_R
		var road_mid := wall + side * ROAD_W * 0.5
		var dy := floorf(lo / 80.0) * 80.0
		while dy < hi:
			b.rect(Rect2(road_mid - 2.0, dy, 4.0, 40.0), LANE_LINE)
			dy += 80.0
		b.rect(Rect2(wall - (8.0 if side > 0.0 else 0.0), lo, 8.0, hi - lo), KERB)
		var walk_x := wall + side * ROAD_W
		b.rect(Rect2(minf(walk_x, walk_x + side * WALK_W), lo, WALK_W, hi - lo), PAVEMENT)
	_blocks(b, lo, hi)


# The blocks on the turned lattice. Each is a chamfered square (the cut
# corners) BLOCK wide, built DEPTH deep round a courtyard, and clipped where
# the avenue cuts it.
static func _blocks(b: ShapeBatch, lo: float, hi: float) -> void:
	var r2 := sqrt(0.5)
	var u := Vector2(r2, r2)
	var v := Vector2(-r2, r2)
	var d := PITCH * r2
	var a0 := int(floorf((lo - PITCH) / d))
	var a1 := int(ceilf((hi + PITCH) / d))
	var left_clip := PackedVector2Array([Vector2(-1200.0, lo - 600.0), Vector2(BLOCK_L, lo - 600.0),
		Vector2(BLOCK_L, hi + 600.0), Vector2(-1200.0, hi + 600.0)])
	var right_clip := PackedVector2Array([Vector2(BLOCK_R, lo - 600.0), Vector2(2500.0, lo - 600.0),
		Vector2(2500.0, hi + 600.0), Vector2(BLOCK_R, hi + 600.0)])
	# a block's corners reach this far from its middle, along x
	var reach := BLOCK * 0.5 * (u.x + absf(v.x))
	for a in range(a0, a1 + 1):
		# far enough out to fill the turned view's corners, no further
		for bb in range(-6, 7):
			if (a + bb) % 2 != 0:
				continue
			var c := Vector2(CX + float(bb) * d, float(a) * d)
			var left := c.x + reach < BLOCK_L
			var right := c.x - reach > BLOCK_R
			# wholly on one side: drawn as it is. Under the avenue: not at
			# all. Cut by it: clipped, the only blocks that pay for a clip.
			if left or right:
				_block(b, c, u, v, a * 31 + bb * 7, PackedVector2Array())
			elif c.x - reach < BLOCK_L:
				_block(b, c, u, v, a * 31 + bb * 7, left_clip)
			elif c.x + reach > BLOCK_R:
				_block(b, c, u, v, a * 31 + bb * 7, right_clip)


# one block: roofs round a courtyard, a parapet along the street front, a
# few trees inside; clipped to `clip` when the avenue cuts it (empty: whole)
static func _block(b: ShapeBatch, c: Vector2, u: Vector2, v: Vector2, salt: int, clip: PackedVector2Array) -> void:
	var shapes: Array = [
		[_octagon(c, u, v, BLOCK * 0.5, CHAMFER), ROOF_TONES[absi(salt) % ROOF_TONES.size()]],
		[_octagon(c, u, v, BLOCK * 0.5 - DEPTH, CHAMFER * 0.5), COURTYARD],
	]
	for sh: Array in shapes:
		var polys: Array = [sh[0]] if clip.is_empty() else Geometry2D.intersect_polygons(sh[0], clip)
		for poly: PackedVector2Array in polys:
			b.polygon(poly, sh[1])
	var rim := _octagon(c, u, v, BLOCK * 0.5 - 6.0, CHAMFER - 4.0)
	var rims: Array = [rim] if clip.is_empty() else Geometry2D.intersect_polygons(rim, clip)
	for poly: PackedVector2Array in rims:
		for i in range(poly.size()):
			b.line(poly[i], poly[(i + 1) % poly.size()], PARAPET, 2.0)
	for i in range(3):
		var tp := c + u * (_h(salt + i) - 0.5) * (BLOCK - DEPTH * 2.0) * 0.8 \
			+ v * (_h(salt * 3 + i) - 0.5) * (BLOCK - DEPTH * 2.0) * 0.8
		if clip.is_empty() or Geometry2D.is_point_in_polygon(tp, clip):
			b.circle(tp, 18.0, HEDGE)


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


# --- live: the tram, its bell and the signals ------------------------------------------

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
			var sp := Vector2(MAST_X + 14.0, y + 10.0)
			wc.circle(sp, 6.0, RAIL_DARK)
			wc.circle(sp, 4.0, SIGNAL_ON.lerp(Color.WHITE, 0.2 * pulse) if lit and pulse > 0.4 else SIGNAL_OFF)
			if lit:
				wc.glow(sp, 22.0, Color(SIGNAL_ON.r, SIGNAL_ON.g, SIGNAL_ON.b, 0.35 * pulse))
		y -= 380.0
	if not t.running:
		return
	var r := tram_rect(t)
	if r.end.y < vt - 60.0 or r.position.y > vb + 60.0:
		return
	# two articulated cars, white with the green band, glass all round
	wc.rect(Rect2(r.position + Vector2(6.0, 8.0), r.size), SHADOW)
	var car := TRAM_LEN * 0.5 - 4.0
	for i in range(2):
		var cr := Rect2(r.position.x, r.position.y + float(i) * (car + 8.0), r.size.x, car)
		wc.rect(cr, TRAM_WHITE)
		wc.rect(Rect2(cr.position.x + 4.0, cr.position.y + 6.0, cr.size.x - 8.0, cr.size.y - 12.0), TRAM_GLASS)
		wc.rect(Rect2(cr.position.x + 10.0, cr.position.y + 12.0, cr.size.x - 20.0, cr.size.y - 24.0), TRAM_WHITE.darkened(0.06))
		wc.rect(Rect2(cr.position.x, cr.position.y + cr.size.y * 0.5 - 5.0, cr.size.x, 10.0), TRAM_GREEN)
	# the bellows between the cars, the pantograph on the roof
	wc.rect(Rect2(r.position.x + 8.0, r.position.y + car, r.size.x - 16.0, 8.0), RAIL_DARK)
	var pan := Vector2(TRACK_X, r.position.y + car * 0.5)
	wc.line(pan + Vector2(-16.0, 0.0), pan + Vector2(16.0, 0.0), RAIL_DARK, 3.0)
	# headlights on the leading end, a red tail on the other
	var fy := r.position.y if t.dir < 0.0 else r.end.y
	var ty := r.end.y if t.dir < 0.0 else r.position.y
	for s: float in [-1.0, 1.0]:
		wc.circle(Vector2(TRACK_X + s * 26.0, fy), 5.0, Color(1.0, 0.98, 0.86))
		wc.circle(Vector2(TRACK_X + s * 26.0, ty), 4.0, Color(0.92, 0.18, 0.14))
	wc.glow(Vector2(TRACK_X, fy + t.dir * 30.0), 70.0, Color(1.0, 0.95, 0.75, 0.22))


# --- overhead: the catenary wire down the track --------------------------------------

static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	var b := ShapeBatch.new(c)
	var top := float(m.GATE_Y) + 60.0
	var bot := float(m.START_Y) + 400.0
	b.line(Vector2(TRACK_X, top), Vector2(TRACK_X, bot), Color(0.12, 0.12, 0.14, 0.75), 1.6)
	var y := 40.0
	while y > float(m.GATE_Y) + 80.0:
		# each mast's arm out over the track
		b.line(Vector2(MAST_X, y), Vector2(TRACK_X + 6.0, y), Color(0.20, 0.20, 0.22, 0.9), 3.0)
		y -= 380.0
	b.flush()
