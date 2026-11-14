extends RefCounted

# THE FIRST WALK's own ground (systems/tutorial.gd has the lessons): the
# stations' furniture, the dressing that makes each one a finished corner of
# a park rather than props on bare sand, and the ghost of the move the
# current lesson asks for. Static functions over main's state, drawn by
# main._draw on the world canvas after El Barri's ground.
#
# Everything here is flat on the ground or as low as a bench: nothing the
# dog or your human could walk under, so nothing needs an overhead pass.
# Cosmetic shapes are placed by fixed numbers, never randf, so a shot sweep
# is the same every time; the pulse of a ghost reads AnimClock.

const TUT := preload("res://systems/tutorial.gd")
const LevelBuild := preload("res://world/level_build.gd")
const Rails := preload("res://systems/rails.gd")

const CHALK := Color(0.96, 0.95, 0.90)
const HINT := Color(1.0, 0.86, 0.42)
const SETT := Color(0.58, 0.56, 0.53)
const SETT_LINE := Color(0.46, 0.44, 0.42)
const SOIL := Color(0.36, 0.26, 0.18)
const TIMBER := Color(0.48, 0.34, 0.22)
const TIMBER_LIT := Color(0.62, 0.47, 0.31)
const YARD_FLOOR := Color(0.62, 0.46, 0.33, 0.42)
# the flowers in the beds, cycled
const BLOOMS: Array[Color] = [Color(0.93, 0.42, 0.42), Color(0.98, 0.83, 0.36), Color(0.96, 0.96, 0.92),
	Color(0.74, 0.52, 0.86), Color(0.98, 0.60, 0.30)]
# where the flowerbeds stand on each lawn: inside the camera's view of a
# 1280-wide window (about x 140 to 1140), well off the path
const BED_WEST := 230.0
const BED_EAST := 1050.0
# the chalk paw prints from the start line's sign up to the first bench
const PAWS_FROM := -30.0
const PAWS_TO := -200.0
const PAW_STEP := 46.0
# how long a ghost takes to come up once its lesson is
const GHOST_IN := 0.5


static func draw(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	_paws(b, vt, vb)
	for i in range(TUT.step_count()):
		_station_dressing(m, b, i, vt, vb)
	_yard(m, b, vt, vb)
	_pond(m, b, vt, vb)
	_ledges(m, b, vt, vb)
	_benches(m, b, vt, vb)
	_ghost(m, b, vt, vb)
	b.flush(wc)


static func _seen(y0: float, y1: float, vt: float, vb: float) -> bool:
	return y1 >= vt - 60.0 and y0 <= vb + 60.0


# A cheap, fixed scatter: the same number for the same inputs, every frame.
static func _h(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


# A trail of chalk paw prints up the path from the start line: somebody's
# kid has been here, and it points the way.
static func _paws(b: ShapeBatch, vt: float, vb: float) -> void:
	if not _seen(PAWS_TO, PAWS_FROM, vt, vb):
		return
	var y := PAWS_FROM
	var k := 0
	while y > PAWS_TO:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector2(640.0 + side * 14.0 + sin(y * 0.01) * 30.0, y)
		var c := Color(CHALK.r, CHALK.g, CHALK.b, 0.55)
		b.circle(p, 6.0, c)
		for t in range(3):
			b.circle(p + Vector2(-6.0 + t * 6.0, -9.0 + absf(t - 1.0) * 2.0), 2.4, c)
		y -= PAW_STEP
		k += 1


# Each station's corner of the park: a flowerbed and shrubs out on the lawn,
# away from where any lesson sends her, on alternating sides.
static func _station_dressing(m: Node2D, b: ShapeBatch, i: int, vt: float, vb: float) -> void:
	var st: Dictionary = TUT.step(i)
	if bool(st.get("yard", false)) and String(st.id) != "practice":
		return
	var y := float(st["at"]) + 40.0
	if y < float(m.GATE_Y) + 80.0 or not _seen(y - 120.0, y + 120.0, vt, vb):
		return
	var west := i % 2 == 0
	# the nose lesson's snack and the poop lesson's grass are on the west
	# lawn, the brink's pond on the east: the dressing goes the other way
	match String(st.id):
		"nose", "poop":
			west = false
		"teeter":
			west = true
	var bx := BED_WEST if west else BED_EAST
	var bed := Rect2(bx - 56.0, y - 30.0, 112.0, 60.0)
	b.rect(Rect2(bed.position + Vector2(4.0, 5.0), bed.size), Color(0.0, 0.0, 0.0, 0.14))
	b.rect(bed.grow(4.0), Color(0.70, 0.67, 0.60))
	b.rect(bed, SOIL)
	for f in range(18):
		var fp := bed.position + Vector2(8.0 + _h(i, f) * (bed.size.x - 16.0), 8.0 + _h(f, i + 3.0) * (bed.size.y - 16.0))
		b.circle(fp, 5.0, Color(0.24, 0.42, 0.22))
		b.circle(fp + Vector2(-1.0, -1.0), 3.0, BLOOMS[(f + i) % BLOOMS.size()])
	# shrubs beside the bed, toward the path
	var sx := bx + (100.0 if west else -100.0)
	for s in range(3):
		var sp := Vector2(sx + (_h(s, i) - 0.5) * 40.0, y - 50.0 + s * 46.0)
		var r := 15.0 + _h(i, s + 9.0) * 7.0
		b.circle(sp + Vector2(4.0, 5.0), r, Color(0.0, 0.0, 0.0, 0.16))
		b.circle(sp, r, Color(0.22, 0.40, 0.22))
		b.circle(sp + Vector2(-r * 0.25, -r * 0.25), r * 0.66, Color(0.32, 0.52, 0.28))


# The practice yard: a packed-earth floor framed in timber across the path,
# chalk rings round the lampposts' feet and a chalk line along the ledge.
static func _yard(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var bench: Vector2 = TUT.practice_bench(m)
	var e: Vector2 = m.walk_edges(bench.y)
	var r := Rect2(e.x + 18.0, bench.y - 410.0, e.y - e.x - 36.0, 460.0)
	if not _seen(r.position.y, r.end.y, vt, vb):
		return
	b.rect(r, YARD_FLOOR)
	for side in [Rect2(r.position.x - 6.0, r.position.y - 6.0, r.size.x + 12.0, 6.0),
			Rect2(r.position.x - 6.0, r.end.y, r.size.x + 12.0, 6.0)]:
		var sr: Rect2 = side
		b.rect(sr, TIMBER)
		b.rect(Rect2(sr.position, Vector2(sr.size.x, 2.0)), TIMBER_LIT)
	for sx: float in [r.position.x - 6.0, r.end.x]:
		b.rect(Rect2(sx, r.position.y, 6.0, r.size.y), TIMBER)
		b.rect(Rect2(sx, r.position.y, 2.0, r.size.y), TIMBER_LIT)
	var ch := Color(CHALK.r, CHALK.g, CHALK.b, 0.6)
	for p: Vector2 in TUT.yard_poles(m):
		_dashed_ring(b, p, 30.0, 18, ch, 2.0)
	var yl: PackedVector2Array = TUT.yard_ledge(m)
	b.line(yl[0] + Vector2(-16.0, 0.0), yl[1] + Vector2(-16.0, 0.0), ch, 2.0)
	_dashed_ring(b, TUT.yard_hydrant(m), 26.0, 14, ch, 2.0)


# The brink lesson's pond: a muddy bank, the water, stones, reeds and lily
# pads, like a corner of El Parc's lake.
static func _pond(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var r: Rect2 = LevelBuild.tutorial_pond(m)
	if not _seen(r.position.y, r.end.y, vt, vb):
		return
	var c := r.get_center()
	var rx := r.size.x * 0.5
	var ry := r.size.y * 0.5
	b.polygon(_oval(c, rx * 1.10, ry * 1.10, 0.0), Color(0.40, 0.36, 0.28))
	b.polygon(_oval(c, rx * 0.95, ry * 0.95, 0.4), Color(0.31, 0.44, 0.52))
	b.polygon(_oval(c + Vector2(6.0, 4.0), rx * 0.66, ry * 0.62, 1.1), Color(0.27, 0.40, 0.50))
	# a glint that drifts on the water
	var t := AnimClock.msec() / 1000.0
	b.glow(c + Vector2(sin(t * 0.4) * rx * 0.3, -ry * 0.3), 24.0, Color(0.85, 0.93, 1.0, 0.18))
	for k in range(14):
		var a := TAU * float(k) / 14.0 + 0.2
		var sp := c + Vector2(cos(a) * rx * 1.04, sin(a) * ry * 1.04)
		b.circle(sp, 4.0 + _h(k, 2.0) * 3.0, Color(0.60, 0.58, 0.54))
		b.circle(sp + Vector2(-1.0, -1.0), 2.5, Color(0.74, 0.72, 0.68))
	for k in range(4):
		var lp := c + Vector2((_h(k, 5.0) - 0.5) * rx * 1.1, (_h(5.0, k) - 0.5) * ry * 1.0)
		b.circle(lp, 9.0, Color(0.30, 0.52, 0.30))
		b.circle(lp + Vector2(2.0, -2.0), 2.0, Color(0.95, 0.80, 0.86))
	# reeds on the far bank
	for k in range(9):
		var a := lerpf(-0.6, 0.6, float(k) / 8.0)
		var root := c + Vector2(cos(a) * rx * 1.02, sin(a) * ry * 1.02)
		b.line(root, root + Vector2(4.0 + _h(k, 1.0) * 6.0, -18.0 - _h(1.0, k) * 10.0), Color(0.36, 0.48, 0.26), 2.0)


static func _oval(c: Vector2, rx: float, ry: float, wob: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(28):
		var a := TAU * float(k) / 28.0
		var f := 1.0 + 0.05 * sin(a * 3.0 + wob) + 0.03 * sin(a * 5.0 + wob * 2.0)
		pts.append(c + Vector2(cos(a) * rx * f, sin(a) * ry * f))
	return pts


# The grind lesson's stone ledge and the yard's: long low walls, the coping
# pale and worn smooth, made to be ridden (systems/rails.gd).
static func _ledges(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var at := TUT.at("grind")
	var runs: Array[Rect2] = [Rect2(Rails.TUT_LEDGE_X - 9.0, at - Rails.TUT_LEDGE_HALF, 18.0, Rails.TUT_LEDGE_HALF * 2.0)]
	var yl: PackedVector2Array = TUT.yard_ledge(m)
	runs.append(Rect2(yl[0].x - 9.0, yl[1].y, 18.0, yl[0].y - yl[1].y))
	for r: Rect2 in runs:
		if not _seen(r.position.y, r.end.y, vt, vb):
			continue
		b.rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.18))
		b.rect(r, Color(0.62, 0.58, 0.52))
		b.rect(Rect2(r.position.x + 2.0, r.position.y, r.size.x - 4.0, r.size.y), Color(0.80, 0.77, 0.70))
		var y := r.position.y + 30.0
		while y < r.end.y:
			b.rect(Rect2(r.position.x, y, r.size.x, 2.0), Color(0.52, 0.48, 0.42))
			y += 30.0


# The benches your human waits on at the quiet lessons (LevelBuild.
# tutorial_benches), each on a little apron of setts: slats across,
# cast-iron ends, the backrest on the south side so whoever sits there faces
# the lesson.
static func _benches(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	for r: Rect2 in LevelBuild.tutorial_benches(m):
		if r.end.y < vt - 60.0 or r.position.y > vb + 60.0:
			continue
		var apron := Rect2(r.position.x - 22.0, r.position.y - 8.0, r.size.x + 44.0, r.size.y + 26.0)
		b.rect(apron.grow(3.0), Color(0.70, 0.67, 0.60))
		b.rect(apron, SETT)
		var sy := apron.position.y + 8.0
		while sy < apron.end.y:
			b.rect(Rect2(apron.position.x, sy, apron.size.x, 1.2), SETT_LINE)
			sy += 8.0
		b.rect(Rect2(r.position + Shade.light * 7.0, r.size + Vector2(0, 6)),
			Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		for ex: float in [r.position.x + 3.0, r.end.x - 7.0]:
			b.rect(Rect2(ex, r.position.y - 1.0, 4.0, r.size.y + 8.0), Color(0.16, 0.16, 0.17))
		for si in range(3):
			var sl := Rect2(r.position.x, r.position.y + float(si) * 5.0, r.size.x, 4.2)
			var wc := Color(0.56, 0.41, 0.27).lightened(0.10 if si == 0 else 0.0)
			b.rect(sl, wc.darkened(0.25))
			b.rect(Rect2(sl.position, sl.size - Vector2(0.0, 1.2)), wc)
		var back := Rect2(r.position.x, r.end.y + 2.0, r.size.x, 5.0)
		b.rect(back, Color(0.46, 0.33, 0.21))
		b.rect(Rect2(back.position, Vector2(back.size.x, 1.5)), Color(0.66, 0.50, 0.34))


static func _dashed_ring(b: ShapeBatch, c: Vector2, r: float, n: int, col: Color, w: float) -> void:
	for k in range(n):
		var a0 := TAU * float(k) / float(n)
		var a1 := a0 + TAU / float(n) * 0.55
		b.line(c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r, col, w)


# A dotted arc from angle a0 to a1 (radians, either way round), with an
# arrowhead at the end: the path a move takes.
static func _dotted_arc(b: ShapeBatch, c: Vector2, r0: float, r1: float, a0: float, a1: float, col: Color) -> void:
	var n := maxi(6, int(absf(a1 - a0) * maxf(r0, r1) / 16.0))
	for k in range(n):
		var f := float(k) / float(n)
		var a := lerpf(a0, a1, f)
		b.circle(c + Vector2(cos(a), sin(a)) * lerpf(r0, r1, f), 3.0, col)
	var tip := c + Vector2(cos(a1), sin(a1)) * r1
	var dir := Vector2(-sin(a1), cos(a1)) * signf(a1 - a0)
	var side := Vector2(-dir.y, dir.x)
	b.polygon(PackedVector2Array([tip + dir * 10.0, tip - dir * 4.0 + side * 7.0, tip - dir * 4.0 - side * 7.0]), col)


# The ghost of the move the current lesson asks for, pulsing gently: where
# the chalk ring is, which hydrant, which patch of grass, the arc round the
# lamppost, the wind round the post, the run along the ledge.
static func _ghost(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if not bool(m.started) or bool(m.finished):
		return
	var st: Dictionary = TUT.step(int(m.tut_step))
	var kind := String(st.get("ghost", ""))
	if kind == "":
		return
	var pulse := 0.65 + 0.35 * sin(AnimClock.msec() / 260.0)
	var a := clampf(float(m.tut_card_t) / GHOST_IN, 0.0, 1.0) * pulse
	var hint := Color(HINT.r, HINT.g, HINT.b, 0.85 * a)
	match kind:
		"ring":
			var rc: Vector2 = m.tut_ring
			if rc.x == INF or not _seen(rc.y - 80.0, rc.y + 80.0, vt, vb):
				return
			_dashed_ring(b, rc, TUT.RING_R, 22, Color(CHALK.r, CHALK.g, CHALK.b, 0.9), 3.0)
			_dashed_ring(b, rc, TUT.RING_R - 7.0, 22, Color(CHALK.r, CHALK.g, CHALK.b, 0.35 + 0.3 * a), 1.5)
		"hydrant":
			var hi := 0 if String(st.id) == "pee" else 1
			if hi >= m.hydrants.size():
				return
			var hp: Vector2 = m.hydrants[hi].pos
			b.glow(hp, 54.0, Color(HINT.r, HINT.g, HINT.b, 0.30 * a))
			_dashed_ring(b, hp, 34.0, 16, hint, 2.0)
		"grass":
			var gp: Vector2 = TUT.poop_grass(m)
			b.glow(gp, 60.0, Color(HINT.r, HINT.g, HINT.b, 0.24 * a))
			_dashed_ring(b, gp, 40.0, 18, hint, 2.0)
		"swing":
			var vp: Vector2 = TUT.vault_post()
			# in from the south-west, round the far side, out to the east
			_dotted_arc(b, vp, 84.0, 84.0, PI * 0.75, PI * 2.1, hint)
		"wind":
			var fp: Vector2 = Vector2(640.0, TUT.at("fling"))
			_dotted_arc(b, fp, 54.0, 96.0, PI * 0.5, PI * 0.5 + TAU * 2.0, Color(hint.r, hint.g, hint.b, hint.a * 0.8))
		"ledge":
			var at := TUT.at("grind")
			var y := at + Rails.TUT_LEDGE_HALF - 20.0
			var x := Rails.TUT_LEDGE_X
			while y > at - Rails.TUT_LEDGE_HALF:
				var cx := x - 30.0
				b.polygon(PackedVector2Array([Vector2(cx - 11.0, y + 9.0), Vector2(cx, y - 6.0),
					Vector2(cx + 11.0, y + 9.0), Vector2(cx, y + 2.0)]), hint)
				y -= 46.0
