class_name Barri
extends RefCounted

# WALK 1: EL BARRI (a neighbourhood square). Its drawing as static functions
# over main's state (main.WALK_MODULES): the square's paving and plane trees,
# the petanca pitch and its players, the playground, the fountain, and the
# pipica past the gate. The tutorial is laid out on El Barri (main.lvl is
# "barri" there too), so every hook here also runs in the tutorial.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const LIGHT := Vector2(0.5, 0.866)       # as main.LIGHT: the direction shadows fall

const PIPICA_GROUND := Color(0.72, 0.64, 0.48)
const PIPICA_FENCE := Color(0.20, 0.38, 0.27)


# EL BARRI: the petanca pitch with its boules, and the playground. Nothing
# here is anywhere in particular.
static func _draw_square(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# cast-iron tree grates (escocells) under the square's London plane trees
	for tp: Vector2 in m.LevelBuild.BARRI_TREES:
		if tp.y > vt - 60.0 and tp.y < vb + 60.0:
			b.circle(tp, 20.0, Color(0.32, 0.30, 0.28))
			b.circle(tp, 17.0, Color(0.24, 0.20, 0.16))
			b.circle(tp, 14.0, Color(0.38, 0.36, 0.34))
			b.circle(tp, 12.6, Color(0.24, 0.20, 0.16))
			for ri in range(8):
				var ra := TAU * float(ri) / 8.0
				b.line(tp + Vector2.from_angle(ra) * 9.0, tp + Vector2.from_angle(ra) * 19.0, Color(0.18, 0.18, 0.20), 1.0)
	var pp: Rect2 = m.LevelBuild.BARRI_PETANCA
	if pp.end.y > vt - 40.0 and pp.position.y < vb + 40.0:
		# raked sauló inside a timber edging, lying on the square's gravel
		b.rect(Rect2(pp.position + LIGHT * 3.0, pp.size).grow(5.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.14))
		b.rect(pp.grow(5.0), Color(0.44, 0.32, 0.20))
		b.rect(Rect2(pp.position - Vector2(5.0, 5.0), Vector2(pp.size.x + 10.0, 2.0)), Color(0.60, 0.46, 0.30))
		b.rect(Rect2(pp.position - Vector2(5.0, 5.0), Vector2(2.0, pp.size.y + 10.0)), Color(0.60, 0.46, 0.30))
		b.rect(pp, Color(0.80, 0.71, 0.53))
		var rake := Color(0.72, 0.63, 0.46, 0.55)
		var ry := pp.position.y + 16.0
		while ry < pp.end.y - 8.0:
			b.line(Vector2(pp.position.x + 6.0, ry), Vector2(pp.end.x - 6.0, ry), rake, 1.2)
			ry += 22.0
		# the throwing circle scratched in at the south end, under the thrower
		var tc := Vector2(pp.position.x + 52.0, pp.end.y - 30.0)
		b.circle(tc, 19.0, Color(0.62, 0.52, 0.36))
		b.circle(tc, 17.0, Color(0.78, 0.69, 0.51))
		# the jack at the far end, and the boules gathered round it
		var jack := pp.position + Vector2(58.0, 30.0)
		for bo: Vector2 in [Vector2(16, 8), Vector2(-12, 14), Vector2(6, -13), Vector2(26, -4), Vector2(-20, -6), Vector2(38, 22)]:
			_boule(m, b, jack + bo)
		# yellow measuring tape (cinta mètrica) measuring distance to closest boule
		b.line(jack, jack + Vector2(6.0, -13.0), Color(0.96, 0.84, 0.18), 1.2)
		b.circle(jack + Vector2(9.0, -17.0) + LIGHT * 1.5, 3.2, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
		b.circle(jack + Vector2(9.0, -17.0), 3.0, Color(0.94, 0.82, 0.16))
		b.circle(jack + Vector2(9.0, -17.0), 1.6, Color(0.20, 0.20, 0.22))
		b.circle(jack + Vector2(0.6, 1.0), 3.4, Color(0, 0, 0, 0.22))
		b.circle(jack, 3.0, Color(0.88, 0.32, 0.20))
		# scoreboard on the west timber rail
		var sb_pos := Vector2(pp.position.x - 14.0, pp.position.y + 40.0)
		b.rect(Rect2(sb_pos + LIGHT * 2.5, Vector2(6.0, 24.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.16))
		b.rect(Rect2(sb_pos, Vector2(6.0, 24.0)), Color(0.50, 0.38, 0.24))
		b.rect(Rect2(sb_pos + Vector2(1.0, 2.0), Vector2(4.0, 20.0)), Color(0.18, 0.20, 0.18))
		b.circle(sb_pos + Vector2(3.0, 6.0), 1.0, Color(0.92, 0.92, 0.90, 0.8))
		b.circle(sb_pos + Vector2(3.0, 16.0), 1.0, Color(0.92, 0.92, 0.90, 0.8))
		# leather boule carrying pouch on the south rail
		var bag_pos := Vector2(pp.position.x + 24.0, pp.end.y + 1.0)
		b.rect(Rect2(bag_pos + LIGHT * 2.0, Vector2(16.0, 9.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
		b.rect(Rect2(bag_pos, Vector2(16.0, 9.0)), Color(0.48, 0.30, 0.18))
		b.circle(bag_pos + Vector2(3.0, 4.5), 3.0, Color(0.56, 0.36, 0.22))
		b.circle(bag_pos + Vector2(8.0, 4.5), 3.0, Color(0.56, 0.36, 0.22))
		b.circle(bag_pos + Vector2(13.0, 4.5), 3.0, Color(0.56, 0.36, 0.22))
		b.line(bag_pos + Vector2(2.0, 0.0), bag_pos + Vector2(14.0, 0.0), Color(0.24, 0.14, 0.08), 1.5)
		# the next two, waiting at the feet of the man whose turn is next
		_boule(m, b, pp.position + Vector2(112.0, pp.size.y - 30.0))
		_boule(m, b, pp.position + Vector2(118.0, pp.size.y - 40.0))
	var pg: Rect2 = m.LevelBuild.BARRI_PLAYGROUND
	if pg.end.y > vt - 40.0 and pg.position.y < vb + 40.0:
		m._playground(b, pg)
	b.flush(m._wc)


static func _boule(m: Node2D, b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(1, 2), 5.0, Color(0, 0, 0, 0.2))
	b.circle(p, 5.0, Color(0.58, 0.58, 0.60))
	# engraved identification grooves (estriat) on steel boules
	b.circle(p, 3.4, Color(0.44, 0.44, 0.46))
	b.circle(p, 2.8, Color(0.58, 0.58, 0.60))
	b.circle(p, 1.8, Color(0.44, 0.44, 0.46))
	b.circle(p, 1.3, Color(0.58, 0.58, 0.60))
	b.circle(p + Vector2(-1.5, -1.5), 1.6, Color(0.88, 0.88, 0.90))


# El Barri's drinking fountain: a green cast-iron column with its push button,
# the spout over a grate let into the gravel, a dog's bowl at its foot, and
# the gravel darkened all round by the water that misses
static func _font(m: Node2D, f: Vector2) -> void:
	var b := ShapeBatch.new()
	b.circle(f + Vector2(18, 4), 22.0, Color(0.50, 0.44, 0.34, 0.38))
	# the grate under the spout
	var g := Rect2(f + Vector2(9.0, -10.0), Vector2(20.0, 20.0))
	b.rect(g.grow(1.2), Color(0.34, 0.34, 0.36))
	b.rect(g, Color(0.20, 0.20, 0.21))
	for k in range(4):
		b.rect(Rect2(g.position.x + 2.0 + float(k) * 4.6, g.position.y + 2.0, 2.4, 16.0), Color(0.36, 0.36, 0.38))
	# the dog's bowl: a little iron basin at the foot of the column
	b.circle(f + Vector2(1.0, 17.0), 6.5, Color(0.12, 0.24, 0.18))
	b.circle(f + Vector2(0.5, 16.5), 4.5, Color(0.36, 0.56, 0.66))
	# expanding water ripple ring in bowl
	b.circle(f + Vector2(0.5, 16.5), 3.0, Color(0.55, 0.76, 0.88, 0.5))
	b.circle(f + Vector2(0.5, 16.5), 2.2, Color(0.36, 0.56, 0.66))
	b.circle(f + Vector2(-1.0, 15.0), 1.4, Color(0.82, 0.92, 0.98, 0.8))
	# the column's shadow, long, away from the light
	var side := LIGHT.orthogonal()
	var tip := f + LIGHT * 46.0
	b.polygon(PackedVector2Array([f + side * 7.0, f - side * 7.0, tip - side * 4.0, tip + side * 4.0]),
		Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24))
	# the column, its fluted cap and the knob on top
	var iron := Color(0.15, 0.31, 0.23)
	b.circle(f, 9.5, iron.darkened(0.25))
	b.circle(f, 8.0, iron)
	b.circle(f + Vector2(-2.0, -2.0), 5.0, iron.lightened(0.18))
	b.circle(f, 2.6, Color(0.70, 0.62, 0.30))
	# Barcelona City crest (escut de Barcelona) embossed in relief on column
	b.rect(Rect2(f.x - 2.5, f.y + 1.0, 5.0, 6.0), Color(0.72, 0.64, 0.34))
	b.line(Vector2(f.x, f.y + 1.0), Vector2(f.x, f.y + 7.0), Color(0.38, 0.32, 0.16), 0.8)
	b.line(Vector2(f.x - 2.5, f.y + 4.0), Vector2(f.x + 2.5, f.y + 4.0), Color(0.38, 0.32, 0.16), 0.8)
	# the spout, reaching out over the grate, and its drip
	b.line(f + Vector2(7.0, 0.0), f + Vector2(18.0, 0.0), iron.darkened(0.15), 3.0)
	b.circle(f + Vector2(19.0, 0.0), 2.2, Color(0.66, 0.58, 0.28))
	b.circle(f + Vector2(19.0, 3.0), 1.6, Color(0.78, 0.90, 0.98, 0.9))
	b.flush(m._wc)


static func _draw_pipica(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.rect(r, PIPICA_GROUND)
	b.circle(r.get_center() + Vector2(0.0, 40.0), 190.0, Color(0.62, 0.54, 0.40, 0.30))
	b.circle(Vector2(640.0, r.end.y - 30.0), 110.0, Color(0.62, 0.54, 0.40, 0.40))
	# grit and pebbles in the sauló
	for gi in range(160):
		var gp := Vector2(r.position.x + fmod(float(gi) * 197.0, r.size.x),
			r.position.y + fmod(float(gi) * 331.0 + float(gi % 7) * 13.0, r.size.y))
		b.circle(gp, 1.4 + float(gi % 3) * 0.5, Color(0.56, 0.49, 0.37, 0.7) if gi % 2 == 0 else Color(0.82, 0.76, 0.62, 0.7))
	# paw prints, in runs, where somebody's dog went
	for k in range(9):
		var o := Vector2(r.position.x + 120.0 + fmod(float(k) * 263.0, r.size.x - 240.0),
			r.position.y + 90.0 + fmod(float(k) * 157.0, r.size.y - 180.0))
		var dir := Vector2.from_angle(float(k) * 1.7)
		for st in range(4):
			var pp := o + dir * float(st) * 16.0 + dir.orthogonal() * (4.0 if st % 2 == 0 else -4.0)
			b.circle(pp, 2.6, Color(0.56, 0.48, 0.35, 0.55))
	# the fence: across the top and down both sides (the run along the walk's
	# end is drawn with the gate)
	_fence(m, b, r.position, Vector2(r.end.x, r.position.y))
	_fence(m, b, r.position, Vector2(r.position.x, r.end.y))
	_fence(m, b, Vector2(r.end.x, r.position.y), r.end)
	# inside the gate: the bag dispenser on its post, and a bin
	var dp := Vector2(m.gate_r + 46.0, r.end.y - 34.0)
	b.polygon(PackedVector2Array([dp + Vector2(-4, 0), dp + Vector2(4, 0), dp + LIGHT * 30.0 + Vector2(3, 0),
		dp + LIGHT * 30.0 - Vector2(3, 0)]), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	b.rect(Rect2(dp - Vector2(8.0, 10.0), Vector2(16.0, 14.0)), PIPICA_FENCE.darkened(0.2))
	b.rect(Rect2(dp - Vector2(6.0, 8.0), Vector2(12.0, 10.0)), PIPICA_FENCE.lightened(0.15))
	b.rect(Rect2(dp.x - 4.0, dp.y - 3.0, 8.0, 3.0), Color(0.30, 0.30, 0.32))
	b.circle(dp + Vector2(0.0, 1.0), 2.0, Color(0.20, 0.60, 0.30))
	var bn := Vector2(m.gate_r + 78.0, r.end.y - 30.0)
	b.circle(bn + LIGHT * 6.0, 10.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	b.circle(bn, 10.0, Color(0.28, 0.30, 0.32))
	b.circle(bn, 7.5, Color(0.16, 0.17, 0.18))
	b.flush(c)
	m._draw_freedom_benches(c, r, Color(0.42, 0.30, 0.20))
	m._freedom_sign(c, r, m.gate_text, "the off-leash dog park")


# a run of the pipicà's fence, a to b: green steel posts and a welded mesh
# panel between them, its shadow on the ground beside it
static func _fence(m: Node2D, b: ShapeBatch, a: Vector2, z: Vector2) -> void:
	if a.distance_to(z) < 2.0:
		return
	b.line(a + LIGHT * 5.0, z + LIGHT * 5.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18), 4.0)
	b.line(a, z, Color(PIPICA_FENCE.r, PIPICA_FENCE.g, PIPICA_FENCE.b, 0.35), 7.0)
	b.line(a, z, PIPICA_FENCE, 2.5)
	var n := maxi(1, int(a.distance_to(z) / 46.0))
	for k in range(n + 1):
		var q := a.lerp(z, float(k) / float(n))
		b.rect(Rect2(q - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), PIPICA_FENCE.darkened(0.35))
		b.rect(Rect2(q - Vector2(3.0, 3.0), Vector2(3.0, 3.0)), PIPICA_FENCE.lightened(0.25))


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the lawn runs to the frame's edge, drawn by the world over the edge layer;
# a city block here only ever showed as a grey slab inside the pipica gate
static func draw_edge_layer(_m: Node2D, _c: Object, _vt: float, _vb: float) -> void:
	pass


# no grass on the petanca pitch or the playground
static func grass_blocked(_m: Node2D, p: Vector2) -> bool:
	return LevelBuild.BARRI_PETANCA.grow(8.0).has_point(p) or LevelBuild.BARRI_PLAYGROUND.grow(8.0).has_point(p)


# the square, up to the gate; the tutorial lays its stations out instead
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.tutorial_mode:
		return
	_draw_square(m, maxf(vt, m.GATE_Y - 30.0), vb)


static func draw_freedom_ground(m: Node2D, c: Object) -> void:
	_draw_pipica(m, c)


static func draw_fountain(m: Node2D, f: Vector2) -> void:
	_font(m, f)


# the pipica's fence along the walk's end, out to its corners (main._draw_gate)
static func draw_gate_fence(m: Node2D, b: ShapeBatch, gl: float, gr: float, gy: float) -> void:
	# the pipicà's fence along the walk's end, out to its corners, on the
	# line its collider runs (LevelBuild.build_walls); the off-leash
	# canvas stops under the walk's lawn, so this run is drawn here
	var fr: Rect2 = m._freedom_rect()
	var fy: float = m.GATE_Y - 30.0
	var sy: float = m.GATE_Y - 41.0
	b.rect(Rect2(fr.position.x, sy, m.gate_l - 20.0 - fr.position.x, fy - sy), PIPICA_GROUND)
	b.rect(Rect2(m.gate_r + 20.0, sy, fr.end.x - m.gate_r - 20.0, fy - sy), PIPICA_GROUND)
	_fence(m, b, Vector2(fr.position.x, fy), Vector2(m.gate_l - 20.0, fy))
	_fence(m, b, Vector2(m.gate_r + 20.0, fy), Vector2(fr.end.x, fy))
	_fence(m, b, Vector2(m.gate_l - 20.0, fy), Vector2(gl - 10.0, gy))
	_fence(m, b, Vector2(m.gate_r + 20.0, fy), Vector2(gr + 10.0, gy))
	for fx: float in [fr.position.x, fr.end.x]:
		_fence(m, b, Vector2(fx, m.GATE_Y - 44.0), Vector2(fx, fy))


static func draw_performer(m: Node2D, wc: ShapeBatch, pf: Vector2, idx: int) -> void:
	# an old man at the petanca, flat cap, hands behind his back
	m.contact_shadow(wc, pf, 12.0, 5.0, 0.2)
	wc.draw_circle(pf, 12.0, [Color(0.42, 0.40, 0.36), Color(0.30, 0.34, 0.42), Color(0.50, 0.44, 0.34)][idx % 3])
	wc.draw_circle(pf + Vector2(0, -4), 6.5, Color(0.84, 0.68, 0.56))
	wc.draw_circle(pf + Vector2(0, -5), 6.8, Color(0.30, 0.28, 0.26))
	wc.draw_rect(Rect2(pf.x - 5.0, pf.y - 14.0, 10.0, 4.0), Color(0.26, 0.24, 0.22))
