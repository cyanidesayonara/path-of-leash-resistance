class_name Barri
extends RefCounted

# WALK 1: EL BARRI (a neighbourhood square). Its drawing as static functions
# over main's state (main.WALK_MODULES): the square's paving and plane trees,
# the petanca pitch and its players, the playground, the fountain, and the
# pipica past the gate. The tutorial is laid out on El Barri (main.lvl is
# "barri" there too), so every hook here also runs in the tutorial.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const Surfaces := preload("res://world/surfaces.gd")

const PIPICA_GROUND := Color(0.72, 0.64, 0.48)
const PIPICA_FENCE := Color(0.20, 0.38, 0.27)


# EL BARRI: the petanca pitch with its boules, and the playground.
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
		b.rect(Rect2(pp.position + Shade.light * 3.0, pp.size).grow(5.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.14))
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
		for bo: Vector2 in [Vector2(16, 8), Vector2(-12, 14), Vector2(26, -4), Vector2(-20, -6), Vector2(38, 22)]:
			_boule(m, b, jack + bo)
		if m.petanca != null:
			_boule(m, b, m.petanca.pos)
		else:
			_boule(m, b, jack + Vector2(6.0, -13.0))
		# yellow measuring tape (cinta mètrica) measuring distance to closest boule
		b.line(jack, jack + Vector2(6.0, -13.0), Color(0.96, 0.84, 0.18), 1.2)
		b.circle(jack + Vector2(9.0, -17.0) + Shade.light * 1.5, 3.2, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
		b.circle(jack + Vector2(9.0, -17.0), 3.0, Color(0.94, 0.82, 0.16))
		b.circle(jack + Vector2(9.0, -17.0), 1.6, Color(0.20, 0.20, 0.22))
		b.circle(jack + Vector2(0.6, 1.0), 3.4, Color(0, 0, 0, 0.22))
		b.circle(jack, 3.0, Color(0.88, 0.32, 0.20))
		# scoreboard on the west timber rail
		var sb_pos := Vector2(pp.position.x - 14.0, pp.position.y + 40.0)
		b.rect(Rect2(sb_pos + Shade.light * 2.5, Vector2(6.0, 24.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.16))
		b.rect(Rect2(sb_pos, Vector2(6.0, 24.0)), Color(0.50, 0.38, 0.24))
		b.rect(Rect2(sb_pos + Vector2(1.0, 2.0), Vector2(4.0, 20.0)), Color(0.18, 0.20, 0.18))
		b.circle(sb_pos + Vector2(3.0, 6.0), 1.0, Color(0.92, 0.92, 0.90, 0.8))
		b.circle(sb_pos + Vector2(3.0, 16.0), 1.0, Color(0.92, 0.92, 0.90, 0.8))
		# leather boule carrying pouch on the south rail
		var bag_pos := Vector2(pp.position.x + 24.0, pp.end.y + 1.0)
		b.rect(Rect2(bag_pos + Shade.light * 2.0, Vector2(16.0, 9.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
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
	var side := Shade.SUN.orthogonal()
	var tip := f + Shade.light * 46.0
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
	b.polygon(PackedVector2Array([dp + Vector2(-4, 0), dp + Vector2(4, 0), dp + Shade.light * 30.0 + Vector2(3, 0),
		dp + Shade.light * 30.0 - Vector2(3, 0)]), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	b.rect(Rect2(dp - Vector2(8.0, 10.0), Vector2(16.0, 14.0)), PIPICA_FENCE.darkened(0.2))
	b.rect(Rect2(dp - Vector2(6.0, 8.0), Vector2(12.0, 10.0)), PIPICA_FENCE.lightened(0.15))
	b.rect(Rect2(dp.x - 4.0, dp.y - 3.0, 8.0, 3.0), Color(0.30, 0.30, 0.32))
	b.circle(dp + Vector2(0.0, 1.0), 2.0, Color(0.20, 0.60, 0.30))
	var bn := Vector2(m.gate_r + 78.0, r.end.y - 30.0)
	b.circle(bn + Shade.light * 6.0, 10.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	b.circle(bn, 10.0, Color(0.28, 0.30, 0.32))
	b.circle(bn, 7.5, Color(0.16, 0.17, 0.18))
	b.flush(c)
	m._draw_freedom_benches(c, r, Color(0.42, 0.30, 0.20))
	m._freedom_sign(c, r, m.gate_text, "The off-leash dog park")


# a run of the pipicà's fence, a to b: green steel posts and a welded mesh
# panel between them, its shadow on the ground beside it
static func _fence(m: Node2D, b: ShapeBatch, a: Vector2, z: Vector2) -> void:
	if a.distance_to(z) < 2.0:
		return
	b.line(a + Shade.light * 5.0, z + Shade.light * 5.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18), 4.0)
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


static func _m_tutorial(m: Node2D) -> bool:
	return m != null and m.tutorial_mode


# no grass on the petanca pitch, the playground or the lawns' beds and pads
static func grass_blocked(m: Node2D, p: Vector2) -> bool:
	return LevelBuild.BARRI_PETANCA.grow(8.0).has_point(p) or LevelBuild.BARRI_PLAYGROUND.grow(8.0).has_point(p) \
		or (not _m_tutorial(m) and _lawn_blocked(p))


# the square, up to the gate, and the neighbourhood round it; the tutorial
# lays its stations out instead
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.tutorial_mode:
		return
	var gb := ShapeBatch.new()
	_draw_gravel(m, gb, vt, vb)
	gb.flush(m._wc)
	_draw_square(m, maxf(vt, m.GATE_Y - 30.0), vb)
	_draw_neighbourhood(m, maxf(vt, _rail_top(m)), minf(vb, _rail_bottom(m)))


# the square's deco poles: plane trees, and the lamp posts between them
static func tree_kind(m: Node2D, p: Vector2) -> int:
	if LevelBuild.BARRI_LAMPS.has(p):
		return m.TREE_NONE
	return m.TREE_PLANE


# the neighbours sitting on some of the benches, drawn over the bench (the
# furniture pass comes after draw_live); the whole walk once, like every
# overhead piece that does not follow the camera
static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	if m.tutorial_mode:
		return
	var b := ShapeBatch.new()
	var looks: Array = [[Color(0.40, 0.40, 0.44), Color(0.84, 0.84, 0.86)], [Color(0.70, 0.36, 0.30), Color(0.30, 0.22, 0.16)],
		[Color(0.32, 0.46, 0.36), Color(0.86, 0.86, 0.88)], [Color(0.86, 0.72, 0.34), Color(0.16, 0.12, 0.10)]]
	for i in range(m.benches.size()):
		var bn: Vector2 = m.benches[i]
		if _h1(i, 41.0) < 0.42:
			continue
		var look: Array = looks[i % looks.size()]
		var at := bn + Vector2(0.0, -10.0 if i % 2 == 0 else 9.0)
		_person(m, b, at, look[0], look[1])
		# what they brought: a newspaper, a bag of bread for the pigeons, a phone
		var thing := at + Vector2(0.0, 18.0 if i % 2 == 0 else -18.0)
		match i % 3:
			0:
				b.rect(Rect2(thing - Vector2(5, 6), Vector2(10, 12)), Color(0.92, 0.90, 0.84))
				b.line(thing + Vector2(-3, -2), thing + Vector2(3, -2), Color(0.5, 0.5, 0.5), 1.0)
			1:
				b.circle(thing, 4.5, Color(0.86, 0.76, 0.56))
			_:
				b.rect(Rect2(thing - Vector2(3, 5), Vector2(6, 10)), Color(0.16, 0.16, 0.20))
	b.flush(c)


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
	if idx == 0 and m.petanca != null and m.petanca.state == Petanca.St.WARN:
		wc.draw_circle(pf + Vector2(6.0, -6.0), 3.4, Color(0.58, 0.58, 0.60))


# --- the neighbourhood round the square ---------------------------------------
# The square's lawns end at the park's cast-iron railing, solid (solids), with
# the neighbourhood beyond it in view. West: the pavement in its panots, the
# kerb, the one-way street with motorbikes parked along it, a Bicing dock, a
# bar's terrace on its platform in the parking lane by the entrance and the
# recycling containers near the pipica; the blocks' rooftop terraces beyond.
# East: no street, the block of flats faces the park across its pavement, its
# balconies over the pavement, shop awnings, a pharmacy's green cross, the
# newspaper kiosk and a corner bar's tables. All of it is past the railing,
# where she cannot go; it is drawn in the world pass so the lawn does not
# cover it. The railing runs from the pipica's fence to the street the walk
# starts from; the First Walk has none of it.
#
# Between the railing and the gravel, the lawns change down the walk so no two
# screens are alike: rosemary and a flower bed at the entrance, the old folks'
# exercise corner and the lavender along the plane-tree avenue, the pergola
# and the kiosk's terrace by the square, the parent's bench across from the
# playground, and the allotment beds and newly planted trees before the pipica.
const RAIL_W := 240.0                    # the west railing, clear of the trees
const RAIL_E := 1050.0                   # the east one, clear of the playground
const OUTER_W := 90.0                    # the level walls' inner faces
const OUTER_E := 1190.0
const PAVE_W := 54.0                     # the pavement past the railing
const STREET_W := 120.0                  # the one-way street past the west kerb
const FACADE_E := RAIL_E + PAVE_W        # the east block's front
const RAILING := Color(0.18, 0.26, 0.21)
const PANOT := Color(0.66, 0.64, 0.60)
const PANOT_DOT := Color(0.58, 0.56, 0.52)
const KERB := Color(0.78, 0.76, 0.72)
const ASPHALT := Color(0.30, 0.30, 0.32)
const TERRAT := Color(0.74, 0.50, 0.38)
const PARAPET := Color(0.86, 0.80, 0.70)
const BICING_RED := Color(0.84, 0.16, 0.14)
const GRANITE := Color(0.70, 0.69, 0.66)
const GRANITE_JOINT := Color(0.56, 0.55, 0.52)
const TIMBER := Color(0.56, 0.40, 0.26)
const TIMBER_LIT := Color(0.68, 0.52, 0.34)
const RUBBER_GREEN := Color(0.30, 0.50, 0.38)
const GYM_STEEL := Color(0.22, 0.46, 0.66)
const GYM_YELLOW := Color(0.94, 0.78, 0.22)
const KIOSK_GREEN := Color(0.20, 0.40, 0.30)
const BOUGAINVILLEA := Color(0.80, 0.22, 0.52)
const ROSEMARY := Color(0.34, 0.44, 0.34)
const LAVENDER := Color(0.58, 0.48, 0.74)
const SOIL := Color(0.36, 0.26, 0.18)
# the gravel's marks, level space: puddle stains (x, y, radius), leaf drifts
# against the edging (x, y, spread), dropped things (x, y, kind)
const PUDDLE_STAINS: Array[Vector3] = [
	Vector3(600.0, -720.0, 26.0), Vector3(742.0, -1650.0, 20.0), Vector3(560.0, -2900.0, 30.0),
	Vector3(690.0, -3900.0, 22.0), Vector3(610.0, -4480.0, 18.0),
]
const LEAF_DRIFTS: Array[Vector3] = [
	Vector3(412.0, -420.0, 10.0), Vector3(866.0, -1010.0, 10.0), Vector3(412.0, -1520.0, 9.0),
	Vector3(866.0, -2380.0, 10.0), Vector3(412.0, -3300.0, 10.0), Vector3(866.0, -3800.0, 9.0),
	Vector3(412.0, -4700.0, 10.0),
]
const LEAF_COLS: Array[Color] = [Color(0.78, 0.56, 0.22), Color(0.66, 0.40, 0.18), Color(0.86, 0.70, 0.30), Color(0.54, 0.46, 0.22)]
const DROPPED: Array[Vector3] = [
	Vector3(470.0, -600.0, 0.0), Vector3(846.0, -3740.0, 1.0), Vector3(430.0, -2570.0, 2.0),
	Vector3(850.0, -1420.0, 3.0), Vector3(860.0, -4180.0, 0.0),
]
# the gates in the railing, and the worn tracks across the lawn to them
const RAIL_GATES: Array[Vector2] = [
	Vector2(RAIL_W, -1420.0), Vector2(RAIL_E, -2160.0), Vector2(RAIL_W, -3380.0), Vector2(RAIL_E, -4260.0),
]
const BICING_Y := -2760.0
const STREET_TREE_STEP := 300.0
const WASHING: Array[Color] = [Color(0.92, 0.90, 0.86), Color(0.40, 0.56, 0.78), Color(0.86, 0.42, 0.40)]

# the lawns' pieces, level space (west lawn 240..400, east lawn 880..1050)
const ROSEMARY_BED := Rect2(262.0, -300.0, 104.0, 330.0)
const FLOWER_BED := Rect2(918.0, -40.0, 100.0, 150.0)
const GYM_PAD := Rect2(906.0, -1070.0, 120.0, 270.0)
const GYM_MACHINES: Array[Vector2] = [
	Vector2(938.0, -1030.0), Vector2(994.0, -980.0), Vector2(940.0, -910.0), Vector2(996.0, -852.0),
]
const LAVENDER_BED := Rect2(266.0, -1330.0, 96.0, 380.0)
const KIOSK := Rect2(950.0, -2490.0, 72.0, 54.0)
const KIOSK_TABLES: Array[Vector2] = [
	Vector2(918.0, -2392.0), Vector2(984.0, -2386.0), Vector2(930.0, -2318.0), Vector2(1000.0, -2312.0),
]
const PERGOLA := Rect2(262.0, -2960.0, 108.0, 230.0)
const PARENT_BENCH := Rect2(300.0, -3884.0, 62.0, 20.0)
const PRAM := Vector2(286.0, -3836.0)
const HORT := Rect2(262.0, -4830.0, 112.0, 300.0)
const ROSE_BED := Rect2(924.0, -740.0, 92.0, 170.0)
const CHESS := Vector2(966.0, -1790.0)
const PICNIC := Rect2(936.0, -3260.0, 64.0, 44.0)
const SPECTATORS := Rect2(300.0, -1900.0, 22.0, 64.0)
const YOUNG_TREES: Array[Vector2] = [Vector2(946.0, -4470.0), Vector2(1004.0, -4640.0), Vector2(944.0, -4810.0)]
const BAG_POST := Vector2(894.0, -4560.0)
# west street: the bar's terrace platform and the recycling containers, in
# the parking lane where motorbikes would otherwise stand
const TERRACE_LANE := Vector2(-150.0, 190.0)     # y from..to
const RECYCLE_LANE := Vector2(-4600.0, -4380.0)
# the east block's ground floor: (y, kind) for its shopfronts
const SHOPS: Array[Vector2] = [
	Vector2(-140.0, 0.0),     # the corner bar, tables out on the pavement
	Vector2(-860.0, 1.0),     # the bakery
	Vector2(-1560.0, 2.0),    # the newspaper kiosk on the pavement
	Vector2(-2900.0, 3.0),    # the pharmacy, its green cross out over the door
	Vector2(-3460.0, 4.0),    # the greengrocer, crates out front
	Vector2(-4200.0, 5.0),    # the hairdresser
	Vector2(-520.0, 6.0),     # the florist, buckets out on the pavement
	Vector2(-2240.0, 0.0),    # a second bar, its terrace by the kiosk gate
	Vector2(-3940.0, 6.0),    # a second florist
	Vector2(-4700.0, 1.0),    # the bakery's other branch, by the pipica
]


# the railing meets the pipica's fence at the top and the street the walk
# starts from at the bottom (the level's bottom wall)
static func _rail_top(m: Node2D) -> float:
	return float(m.GATE_Y) - 30.0


static func _rail_bottom(m: Node2D) -> float:
	return float(m.START_Y) + 160.0


# what is solid past the railings, out to the level walls, and the lawns'
# pieces she cannot walk through; none in the First Walk, which is laid out
# on El Barri without them
static func solids(m: Node2D) -> Array[Rect2]:
	if m.tutorial_mode:
		return []
	var top := _rail_top(m)
	var h := _rail_bottom(m) - top
	var out: Array[Rect2] = [Rect2(OUTER_W, top, RAIL_W - OUTER_W, h), Rect2(RAIL_E, top, OUTER_E - RAIL_E, h)]
	out.append(ROSEMARY_BED)
	out.append(FLOWER_BED)
	for g: Vector2 in GYM_MACHINES:
		out.append(Rect2(g - Vector2(13.0, 13.0), Vector2(26.0, 26.0)))
	out.append(LAVENDER_BED)
	out.append(KIOSK)
	for t: Vector2 in KIOSK_TABLES:
		out.append(Rect2(t - Vector2(12.0, 12.0), Vector2(24.0, 24.0)))
	out.append(PERGOLA)
	out.append(PARENT_BENCH)
	out.append(HORT)
	out.append(ROSE_BED)
	out.append(Rect2(CHESS - Vector2(14.0, 14.0), Vector2(28.0, 28.0)))
	out.append(PICNIC)
	out.append(SPECTATORS)
	for t: Vector2 in YOUNG_TREES:
		out.append(Rect2(t - Vector2(6.0, 6.0), Vector2(12.0, 12.0)))
	return out


# no grass on the lawns' beds, pads and terraces
static func _lawn_blocked(p: Vector2) -> bool:
	for r: Rect2 in [ROSEMARY_BED, FLOWER_BED, GYM_PAD, LAVENDER_BED, PERGOLA, HORT, ROSE_BED, PICNIC]:
		if r.grow(6.0).has_point(p):
			return true
	for g: Vector2 in RAIL_GATES:
		if absf(p.y - g.y) < 24.0:
			return true
	return Rect2(900.0, -2500.0, 136.0, 210.0).has_point(p)


# main.surface_at, through walk_mod: past the railings is the street's
# pavement, or -1 for main's own
static func surface(m: Node2D, p: Vector2) -> int:
	if m.tutorial_mode or p.y <= m.GATE_Y:
		return -1
	if p.x < RAIL_W or p.x > RAIL_E:
		return Surfaces.S.PAVEMENT
	return -1


static func _h1(k: int, salt: float) -> float:
	return fmod(absf(sin(float(k) * 12.9898 + salt) * 43758.5453), 1.0)


static func _shadow(m: Node2D) -> Color:
	return Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20)


# the gravel itself: granite edging along both sides, a track worn down the
# middle by every walk, and a band of setts across each end of the square
static func _draw_gravel(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var lo: float = maxf(top, m.GATE_Y - 30.0)
	var hi: float = minf(bot, _rail_bottom(m))
	if hi <= lo:
		return
	# the worn track: firmer, darker gravel where the feet go, wandering a little
	var y := floorf(lo / 40.0) * 40.0
	while y < hi:
		var cx := 640.0 + sin(y * 0.0021) * 46.0 + sin(y * 0.0057) * 14.0
		b.circle(Vector2(cx, y), 70.0, Color(0.56, 0.48, 0.36, 0.09))
		b.circle(Vector2(cx + 8.0, y + 20.0), 44.0, Color(0.54, 0.46, 0.34, 0.09))
		y += 40.0
	# a scatter of coarser stones and the odd darker patch where water stood
	var k0 := int(floorf(lo / 90.0))
	var k1 := int(ceilf(hi / 90.0))
	for k in range(k0, k1):
		var py := float(k) * 90.0 + _h1(k, 7.0) * 90.0
		var px := 420.0 + _h1(k, 8.0) * 440.0
		if _h1(k, 9.0) > 0.82:
			b.circle(Vector2(px, py), 18.0 + _h1(k, 10.0) * 16.0, Color(0.52, 0.45, 0.34, 0.12))
		for s in range(3):
			var sp := Vector2(px + (_h1(k * 3 + s, 11.0) - 0.5) * 60.0, py + (_h1(k * 3 + s, 12.0) - 0.5) * 60.0)
			b.circle(sp, 1.6, Color(0.86, 0.80, 0.68, 0.7))
			b.circle(sp + Vector2(5.0, 3.0), 1.2, Color(0.50, 0.44, 0.34, 0.6))
	# the trees' shade: dapples of sun through the crown on the gravel
	for tp: Vector2 in LevelBuild.BARRI_TREES:
		if tp.y < lo - 120.0 or tp.y > hi + 80.0:
			continue
		var sc := tp + Shade.light * 50.0
		for d in range(7):
			var dp := sc + Vector2((_h1(int(tp.y) + d, 51.0) - 0.5) * 70.0, (_h1(int(tp.y) + d, 52.0) - 0.5) * 34.0)
			b.circle(dp, 3.0 + _h1(int(tp.y) + d, 53.0) * 4.0, Color(1.0, 0.96, 0.80, 0.10))
		b.circle(sc, 16.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.06))
	# a pram's two wheel tracks down the east side, a bike's single one down
	# the west, wandering as they go
	var ty := floorf(lo / 24.0) * 24.0
	while ty < hi:
		var px := 700.0 + sin(ty * 0.0031) * 40.0
		var px2 := 700.0 + sin((ty + 24.0) * 0.0031) * 40.0
		for o: float in [-7.0, 7.0]:
			b.line(Vector2(px + o, ty), Vector2(px2 + o, ty + 24.0), Color(0.50, 0.43, 0.32, 0.20), 1.4)
		var bx := 540.0 + sin(ty * 0.0043 + 1.0) * 52.0
		var bx2 := 540.0 + sin((ty + 24.0) * 0.0043 + 1.0) * 52.0
		b.line(Vector2(bx, ty), Vector2(bx2, ty + 24.0), Color(0.50, 0.43, 0.32, 0.16), 1.2)
		ty += 24.0
	# where the rain stood: darker stains with a crust of fine silt round them
	for st: Vector3 in PUDDLE_STAINS:
		if st.y < lo - 60.0 or st.y > hi + 60.0:
			continue
		var sp := Vector2(st.x, st.y)
		b.circle(sp, st.z + 3.0, Color(0.80, 0.74, 0.60, 0.16))
		b.circle(sp, st.z, Color(0.50, 0.44, 0.34, 0.24))
		b.circle(sp + Vector2(st.z * 0.5, 2.0), st.z * 0.6, Color(0.50, 0.44, 0.34, 0.20))
		b.circle(sp - Vector2(st.z * 0.4, 1.0), st.z * 0.45, Color(0.46, 0.40, 0.31, 0.18))
	# the gravel raked smooth beside the petanca pitch, the rake's teeth in it
	var pp: Rect2 = LevelBuild.BARRI_PETANCA
	if pp.end.y > lo - 20.0 and pp.position.y < hi + 20.0:
		var rk := Rect2(pp.end.x + 10.0, pp.position.y + 20.0, 64.0, pp.size.y - 40.0)
		b.rect(rk, Color(0.82, 0.74, 0.58, 0.35))
		var ry := rk.position.y + 4.0
		while ry < rk.end.y:
			b.line(Vector2(rk.position.x + 2.0, ry), Vector2(rk.end.x - 2.0, ry), Color(0.60, 0.52, 0.40, 0.30), 1.0)
			ry += 5.0
		# the rake, laid down at its edge
		b.line(Vector2(rk.end.x + 4.0, rk.position.y + 10.0), Vector2(rk.end.x + 4.0, rk.position.y + 70.0), Color(0.58, 0.42, 0.26), 2.2)
		b.rect(Rect2(rk.end.x - 6.0, rk.position.y + 6.0, 20.0, 4.0), Color(0.30, 0.30, 0.32))
	# a band of panots across the gravel at each gate in the railing, where the
	# paved path from the gate meets the square
	for g: Vector2 in RAIL_GATES:
		if g.y < lo - 30.0 or g.y > hi + 30.0:
			continue
		_panots(b, 402.0, 878.0, g.y - 18.0, g.y + 18.0)
		b.rect(Rect2(402.0, g.y - 19.0, 476.0, 1.5), GRANITE_JOINT)
		b.rect(Rect2(402.0, g.y + 18.0, 476.0, 1.5), GRANITE_JOINT)
	# things dropped on the gravel: a ball, a dummy, a glove, drifts of leaves
	# against the edging
	for dr: Vector3 in LEAF_DRIFTS:
		if dr.y < lo - 40.0 or dr.y > hi + 40.0:
			continue
		for li in range(14):
			var lp := Vector2(dr.x + (_h1(int(dr.y) + li, 61.0) - 0.5) * dr.z * 2.0,
				dr.y + (_h1(int(dr.y) + li, 62.0) - 0.5) * dr.z * 3.2)
			b.circle(lp, 3.2, LEAF_COLS[li % LEAF_COLS.size()])
	for dt: Vector3 in DROPPED:
		if dt.y < lo - 20.0 or dt.y > hi + 20.0:
			continue
		var dp2 := Vector2(dt.x, dt.y)
		b.circle(dp2 + Shade.light * 2.0, 5.0, Color(0, 0, 0, 0.16))
		match int(dt.z):
			0:      # a child's ball, red and yellow
				b.circle(dp2, 5.5, Color(0.90, 0.24, 0.20))
				b.circle(dp2 + Vector2(-1.5, -1.5), 2.6, Color(0.96, 0.84, 0.26))
			1:      # a dummy
				b.circle(dp2, 4.0, Color(0.56, 0.78, 0.92))
				b.circle(dp2 + Vector2(4, 0), 2.0, Color(0.96, 0.94, 0.90))
			2:      # a glove
				b.rect(Rect2(dp2 - Vector2(4, 3), Vector2(8, 7)), Color(0.36, 0.30, 0.46))
				for f in range(3):
					b.rect(Rect2(dp2.x - 4.0 + float(f) * 3.0, dp2.y - 7.0, 2.0, 4.0), Color(0.36, 0.30, 0.46))
			_:      # a hair clip, bright pink
				b.rect(Rect2(dp2 - Vector2(4, 1.5), Vector2(8, 3)), Color(0.94, 0.40, 0.66))
	# the setts across each end of the square: three rows, staggered
	for sy: float in [-1560.0, -3330.0]:
		if sy < lo - 40.0 or sy > hi + 40.0:
			continue
		b.rect(Rect2(402.0, sy - 20.0, 476.0, 40.0), GRANITE_JOINT)
		for row in range(3):
			var off := 0.0 if row % 2 == 0 else 13.0
			var sx := 402.0 - off
			while sx < 878.0:
				var x0 := maxf(sx + 1.0, 402.0)
				var x1 := minf(sx + 25.0, 878.0)
				if x1 > x0:
					var g := GRANITE.lerp(Color(0.62, 0.60, 0.57), _h1(int(sx) + row * 97, sy))
					b.rect(Rect2(x0, sy - 19.0 + float(row) * 13.0, x1 - x0, 12.0), g)
				sx += 26.0
	# the granite edging between the gravel and the lawns, its shadow on the gravel
	for side: float in [-1.0, 1.0]:
		var ex: float = 394.0 if side < 0.0 else 880.0
		b.rect(Rect2(ex + (7.0 if side < 0.0 else -2.0), lo, 2.0, hi - lo), Color(0.40, 0.34, 0.26, 0.30))
		b.rect(Rect2(ex, lo, 7.0, hi - lo), Color(0.60, 0.59, 0.56))
		b.rect(Rect2(ex, lo, 7.0, 1.5), Color(0.74, 0.73, 0.70))
		b.rect(Rect2(ex + 1.0, lo, 2.0, hi - lo), Color(0.72, 0.71, 0.68))
		var jy := floorf(lo / 64.0) * 64.0
		while jy < hi:
			b.rect(Rect2(ex, jy, 7.0, 1.5), Color(0.44, 0.43, 0.41))
			jy += 64.0


static func _draw_neighbourhood(m: Node2D, top: float, bot: float) -> void:
	if bot <= top:
		return
	var b := ShapeBatch.new()
	_desire_paths(m, b, top, bot)
	_draw_west_street(m, b, top, bot)
	_draw_east_block(m, b, top, bot)
	for side: float in [-1.0, 1.0]:
		var rail: float = RAIL_E if side > 0.0 else RAIL_W
		# the railing: its rail, a post every few feet
		b.rect(Rect2(rail - 2.0, top, 4.0, bot - top), RAILING)
		var py := floorf(top / 16.0) * 16.0
		while py < bot:
			b.circle(Vector2(rail, py), 2.6, RAILING)
			py += 16.0
	for g: Vector2 in RAIL_GATES:
		if g.y > top - 30.0 and g.y < bot + 30.0:
			var gside := 1.0 if g.x > 640.0 else -1.0
			b.rect(Rect2(g.x - 4.0, g.y - 22.0, 8.0, 44.0), PANOT)
			for gy: float in [g.y - 22.0, g.y + 22.0]:
				b.circle(Vector2(g.x, gy), 4.5, RAILING)
				b.circle(Vector2(g.x, gy), 2.0, RAILING.lightened(0.3))
			b.line(Vector2(g.x, g.y - 20.0), Vector2(g.x + gside * 18.0, g.y - 6.0), RAILING, 2.0)
	_draw_lawns(m, b, top, bot)
	# the street's plane trees on the pavements, crowns over the railing's foot
	for side: float in [-1.0, 1.0]:
		var rail2: float = RAIL_E if side > 0.0 else RAIL_W
		var ty2 := floorf(top / STREET_TREE_STEP) * STREET_TREE_STEP
		while ty2 < bot + 40.0:
			var tp := Vector2(rail2 + side * 28.0, ty2 + (70.0 if side > 0.0 else 0.0))
			if absf(tp.y - BICING_Y) > 150.0 and not (side > 0.0 and _near_shop(tp.y, 60.0)):
				b.circle(tp + Shade.light * 14.0, 30.0, Color(0, 0, 0, 0.18))
				b.circle(tp, 30.0, Color(0.24, 0.40, 0.22))
				b.circle(tp - Shade.light * 8.0, 20.0, Color(0.32, 0.50, 0.28))
				b.circle(tp - Shade.light * 13.0, 9.0, Color(0.42, 0.60, 0.34))
			ty2 += STREET_TREE_STEP
	b.flush(m._wc)


static func _near_shop(y: float, d: float) -> bool:
	for s: Vector2 in SHOPS:
		if absf(y - s.x) < d + 60.0:
			return true
	return false


static func _panots(b: ShapeBatch, x0: float, x1: float, top: float, bot: float) -> void:
	b.rect(Rect2(x0, top, x1 - x0, bot - top), PANOT)
	var cell := 18.0
	var ty := floorf(top / cell) * cell
	while ty < bot:
		b.line(Vector2(x0, ty), Vector2(x1, ty), PANOT_DOT, 1.0)
		var tx := x0
		while tx < x1 - 6.0:
			for d: Vector2 in [Vector2(-4, -4), Vector2(4, -4), Vector2(-4, 4), Vector2(4, 4)]:
				b.circle(Vector2(tx + cell * 0.5, ty + cell * 0.5) + d, 1.6, PANOT_DOT)
			tx += cell
		ty += cell


# West: pavement, kerb, the one-way street, what is parked in its lane, and
# the rooftops of the blocks past it
static func _draw_west_street(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var kerb_x := RAIL_W - PAVE_W
	var far_x := kerb_x - STREET_W
	_panots(b, kerb_x, RAIL_W, top, bot)
	b.rect(Rect2(kerb_x, top, 6.0, bot - top), KERB)
	b.rect(Rect2(far_x, top, STREET_W, bot - top), ASPHALT)
	# the lane's parking bays, painted
	var by := floorf(top / 92.0) * 92.0
	while by < bot:
		b.rect(Rect2(kerb_x - 48.0, by, 48.0, 1.5), Color(0.86, 0.86, 0.82, 0.45))
		by += 92.0
	# motorbikes parked nose to the kerb, a gap here and there
	var my := floorf(top / 46.0) * 46.0
	while my < bot:
		var k := int(absf(my) / 46.0)
		var in_terrace := my > TERRACE_LANE.x - 30.0 and my < TERRACE_LANE.y + 10.0
		var in_recycle := my > RECYCLE_LANE.x - 30.0 and my < RECYCLE_LANE.y + 10.0
		if _h1(k, -1.0) > 0.35 and absf(my - BICING_Y) > 140.0 and not in_terrace and not in_recycle:
			_motorbike(b, Vector2(kerb_x - 26.0, my + 23.0), -1.0, _h1(k, 2.0))
		my += 46.0
	if TERRACE_LANE.y > top and TERRACE_LANE.x < bot:
		_lane_terrace(m, b, kerb_x)
	if RECYCLE_LANE.y > top and RECYCLE_LANE.x < bot:
		_recycling(m, b, kerb_x)
	if BICING_Y > top - 140.0 and BICING_Y < bot + 140.0:
		_bicing(b, Vector2(kerb_x - 22.0, BICING_Y))
	_terrats(b, far_x, -1.0, top, bot)


# The bar across the road from the entrance puts its terrace out on a timber
# platform in the parking lane: a planter at each end, tables and chairs,
# parasols furled by the kerb
static func _lane_terrace(m: Node2D, b: ShapeBatch, kerb_x: float) -> void:
	var r := Rect2(kerb_x - 50.0, TERRACE_LANE.x, 46.0, TERRACE_LANE.y - TERRACE_LANE.x)
	b.rect(Rect2(r.position + Shade.light * 3.0, r.size), _shadow(m))
	b.rect(r, TIMBER)
	var py := r.position.y + 6.0
	while py < r.end.y:
		b.rect(Rect2(r.position.x, py, r.size.x, 1.0), TIMBER.darkened(0.2))
		py += 8.0
	b.rect(Rect2(r.position.x, r.position.y, 3.0, r.size.y), Color(0.86, 0.86, 0.84))
	for pyy: float in [r.position.y + 10.0, r.end.y - 10.0]:
		b.rect(Rect2(r.position.x + 6.0, pyy - 8.0, 34.0, 16.0), Color(0.40, 0.40, 0.42))
		b.circle(Vector2(r.position.x + 14.0, pyy), 6.0, Color(0.26, 0.46, 0.26))
		b.circle(Vector2(r.position.x + 30.0, pyy), 6.0, Color(0.30, 0.52, 0.28))
	var ty := r.position.y + 50.0
	var k := 0
	while ty < r.end.y - 40.0:
		var tc := Vector2(r.get_center().x, ty)
		for cd: Vector2 in [Vector2(-14, 0), Vector2(14, 0)]:
			b.rect(Rect2(tc + cd - Vector2(5, 5), Vector2(10, 10)), Color(0.28, 0.28, 0.30))
		b.circle(tc + Shade.light * 2.0, 9.0, _shadow(m))
		b.circle(tc, 9.0, Color(0.88, 0.88, 0.86))
		b.circle(tc + Vector2(-3, -2), 2.4, Color(0.94, 0.94, 0.92) if k % 2 == 0 else Color(0.62, 0.34, 0.18))
		b.circle(tc + Vector2(3, 2), 2.0, Color(0.96, 0.84, 0.40))
		ty += 52.0
		k += 1


# The containers in the parking lane: yellow packaging, blue paper, the green
# glass igloo, brown organic, grey everything else
static func _recycling(m: Node2D, b: ShapeBatch, kerb_x: float) -> void:
	var cols: Array[Color] = [Color(0.92, 0.76, 0.18), Color(0.20, 0.42, 0.72), Color(0.22, 0.52, 0.30),
		Color(0.48, 0.32, 0.20), Color(0.42, 0.44, 0.46)]
	var y := RECYCLE_LANE.x + 14.0
	for i in range(cols.size()):
		var c := Vector2(kerb_x - 24.0, y + 20.0)
		if i == 2:
			b.circle(c + Shade.light * 4.0, 19.0, _shadow(m))
			b.circle(c, 19.0, cols[i])
			b.circle(c, 12.0, cols[i].lightened(0.12))
			b.circle(c, 4.0, cols[i].darkened(0.3))
		else:
			var r := Rect2(c - Vector2(18.0, 19.0), Vector2(36.0, 38.0))
			b.rect(Rect2(r.position + Shade.light * 4.0, r.size), _shadow(m))
			b.rect(r, cols[i].darkened(0.15))
			b.rect(r.grow(-3.0), cols[i])
			b.rect(Rect2(r.position.x + 3.0, r.get_center().y - 1.0, r.size.x - 6.0, 2.0), cols[i].darkened(0.25))
			b.rect(Rect2(r.position.x - 2.0, r.position.y + 6.0, 3.0, 8.0), Color(0.2, 0.2, 0.22))
		y += 42.0
	# a flattened box someone left beside them
	b.rect(Rect2(kerb_x - 44.0, y + 6.0, 30.0, 20.0), Color(0.70, 0.56, 0.38))
	b.line(Vector2(kerb_x - 44.0, y + 16.0), Vector2(kerb_x - 14.0, y + 16.0), Color(0.56, 0.44, 0.30), 1.0)


# East: the block of flats faces the park across its pavement. From above,
# its front: balconies out over the pavement with their plants, washing and
# air conditioners, shop awnings and signs at street level, and the roofs.
static func _draw_east_block(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	_panots(b, RAIL_E, FACADE_E, top, bot)
	_terrats(b, FACADE_E, 1.0, top, bot)
	# the facade's foot, a line of shade along it
	b.rect(Rect2(FACADE_E - 4.0, top, 4.0, bot - top), Color(0, 0, 0, 0.12))
	# the balconies, one a floor-width apart, skipping the shopfronts
	var y := floorf(top / 58.0) * 58.0
	while y < bot:
		var k := int(absf(y) / 58.0)
		if not _near_shop(y + 20.0, 0.0):
			_balcony(b, Vector2(FACADE_E, y + 10.0), k)
		y += 58.0
	for s: Vector2 in SHOPS:
		if s.x > top - 120.0 and s.x < bot + 120.0:
			_shopfront(m, b, s.x, int(s.y))


static func _balcony(b: ShapeBatch, at: Vector2, k: int) -> void:
	var r := Rect2(at.x - 16.0, at.y, 16.0, 34.0)
	b.rect(Rect2(r.position + Vector2(-3.0, 4.0), r.size), Color(0, 0, 0, 0.14))
	b.rect(r, Color(0.80, 0.76, 0.70))
	b.rect(Rect2(r.position.x, r.position.y, 2.0, r.size.y), Color(0.20, 0.22, 0.24))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), Color(0.20, 0.22, 0.24))
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), Color(0.20, 0.22, 0.24))
	match int(_h1(k, 21.0) * 5.0):
		0:      # geraniums in a row of pots
			for i in range(3):
				var p := Vector2(r.position.x + 6.0, r.position.y + 7.0 + float(i) * 10.0)
				b.circle(p, 3.6, Color(0.62, 0.36, 0.24))
				b.circle(p, 2.8, Color(0.28, 0.50, 0.26))
				b.circle(p + Vector2(-1, -1), 1.4, Color(0.92, 0.22, 0.30))
		1:      # washing on a rack
			for i in range(3):
				b.rect(Rect2(r.position.x + 3.0, r.position.y + 4.0 + float(i) * 10.0, 7.0, 7.0), WASHING[(k + i) % WASHING.size()])
		2:      # the air conditioner's box and a chair
			b.rect(Rect2(r.position.x + 3.0, r.position.y + 4.0, 8.0, 12.0), Color(0.90, 0.90, 0.88))
			b.circle(Vector2(r.position.x + 7.0, r.position.y + 10.0), 3.0, Color(0.60, 0.62, 0.64))
			b.rect(Rect2(r.position.x + 3.0, r.position.y + 21.0, 7.0, 8.0), Color(0.22, 0.34, 0.50))
		3:      # a bike stood on its end, a big leafy plant
			b.line(Vector2(r.position.x + 5.0, r.position.y + 4.0), Vector2(r.position.x + 5.0, r.position.y + 18.0), Color(0.12, 0.12, 0.12), 2.0)
			b.circle(Vector2(r.position.x + 7.0, r.position.y + 26.0), 5.0, Color(0.24, 0.46, 0.24))
			b.circle(Vector2(r.position.x + 6.0, r.position.y + 25.0), 3.0, Color(0.36, 0.58, 0.32))
		_:      # a flag of a striped blind let down
			for i in range(5):
				b.rect(Rect2(r.position.x + 2.0, r.position.y + 2.0 + float(i) * 6.0, 10.0, 3.0),
					Color(0.84, 0.70, 0.36) if i % 2 == 0 else Color(0.92, 0.88, 0.78))


# a shopfront on the east block: an awning or sign out over the pavement, and
# what it sets out in front
static func _shopfront(m: Node2D, b: ShapeBatch, y: float, kind: int) -> void:
	var fx := FACADE_E
	match kind:
		0:      # the corner bar: a green awning and its tables on the pavement
			_awning(b, Rect2(fx - 30.0, y - 70.0, 30.0, 140.0), Color(0.18, 0.44, 0.32), Color(0.92, 0.90, 0.84))
			for i in range(3):
				var tc := Vector2(fx - 42.0, y - 52.0 + float(i) * 52.0)
				b.circle(tc + Shade.light * 2.0, 8.0, _shadow(m))
				b.circle(tc, 8.0, Color(0.74, 0.74, 0.72))
				b.circle(tc + Vector2(-2, -1), 2.2, Color(0.96, 0.84, 0.40))
				for cd: Vector2 in [Vector2(0, -13), Vector2(0, 13)]:
					b.rect(Rect2(tc + cd - Vector2(4.5, 4.5), Vector2(9, 9)), Color(0.84, 0.30, 0.20))
			# the A-board with the menu chalked on it
			b.rect(Rect2(fx - 46.0, y + 86.0, 10.0, 14.0), Color(0.16, 0.16, 0.18))
			b.rect(Rect2(fx - 45.0, y + 88.0, 8.0, 10.0), Color(0.86, 0.86, 0.84, 0.25))
		1:      # the bakery: a cream and brown striped awning, a bench by the door
			_awning(b, Rect2(fx - 28.0, y - 50.0, 28.0, 100.0), Color(0.52, 0.34, 0.20), Color(0.94, 0.88, 0.74))
			b.rect(Rect2(fx - 44.0, y - 26.0, 10.0, 40.0), TIMBER)
			b.rect(Rect2(fx - 43.0, y - 25.0, 3.0, 38.0), TIMBER_LIT)
		2:      # the newspaper kiosk, green steel, its shutters folded open
			var kr := Rect2(fx - 46.0, y - 34.0, 38.0, 68.0)
			b.rect(Rect2(kr.position + Shade.light * 5.0, kr.size), _shadow(m))
			b.rect(kr, KIOSK_GREEN)
			b.rect(kr.grow(-3.0), KIOSK_GREEN.lightened(0.1))
			b.rect(Rect2(kr.position.x - 6.0, kr.position.y + 6.0, 6.0, kr.size.y - 12.0), Color(0.86, 0.86, 0.80))
			for i in range(5):
				b.rect(Rect2(kr.position.x - 5.0, kr.position.y + 9.0 + float(i) * 10.0, 4.0, 8.0),
					[Color(0.86, 0.24, 0.20), Color(0.24, 0.40, 0.70), Color(0.94, 0.80, 0.24), Color(0.92, 0.92, 0.90), Color(0.36, 0.62, 0.36)][i])
			b.rect(Rect2(kr.position.x + 6.0, kr.position.y - 4.0, kr.size.x - 12.0, 4.0), Color(0.86, 0.20, 0.18))
		3:      # the pharmacy: its green cross on a bracket over the door
			b.rect(Rect2(fx - 6.0, y - 40.0, 6.0, 80.0), Color(0.94, 0.94, 0.92))
			var c := Vector2(fx - 18.0, y)
			b.line(Vector2(fx, y), c, Color(0.30, 0.30, 0.32), 2.0)
			b.glow(c, 26.0, Color(0.30, 0.90, 0.40, 0.22 + 0.3 * Game.lamp_glow()))
			b.rect(Rect2(c.x - 9.0, c.y - 3.5, 18.0, 7.0), Color(0.16, 0.66, 0.30))
			b.rect(Rect2(c.x - 3.5, c.y - 9.0, 7.0, 18.0), Color(0.16, 0.66, 0.30))
			b.rect(Rect2(c.x - 2.0, c.y - 7.0, 4.0, 14.0), Color(0.46, 0.92, 0.52))
			b.rect(Rect2(c.x - 7.0, c.y - 2.0, 14.0, 4.0), Color(0.46, 0.92, 0.52))
		4:      # the greengrocer: a green awning and crates of fruit out front
			_awning(b, Rect2(fx - 28.0, y - 60.0, 28.0, 120.0), Color(0.26, 0.52, 0.28), Color(0.90, 0.92, 0.84))
			var fruit: Array[Color] = [Color(0.96, 0.56, 0.14), Color(0.86, 0.18, 0.16), Color(0.94, 0.86, 0.26), Color(0.50, 0.70, 0.24)]
			for i in range(4):
				var cr := Rect2(fx - 48.0, y - 50.0 + float(i) * 26.0, 18.0, 22.0)
				b.rect(Rect2(cr.position + Shade.light * 2.0, cr.size), _shadow(m))
				b.rect(cr, TIMBER_LIT)
				for f in range(4):
					b.circle(cr.position + Vector2(5.0 + float(f % 2) * 8.0, 6.0 + float(f / 2) * 9.0), 3.6, fruit[i])
		6:      # the florist: a pink awning, buckets of flowers out on the pavement
			_awning(b, Rect2(fx - 26.0, y - 50.0, 26.0, 100.0), Color(0.80, 0.36, 0.50), Color(0.96, 0.92, 0.92))
			var blooms: Array[Color] = [Color(0.94, 0.86, 0.22), Color(0.90, 0.26, 0.32), Color(0.96, 0.96, 0.94), Color(0.62, 0.40, 0.80)]
			for i in range(5):
				var bp := Vector2(fx - 38.0 - float(i % 2) * 8.0, y - 44.0 + float(i) * 20.0)
				b.circle(bp + Shade.light * 2.0, 8.0, _shadow(m))
				b.circle(bp, 7.0, Color(0.30, 0.32, 0.36))
				for f in range(5):
					b.circle(bp + Vector2.from_angle(TAU * float(f) / 5.0) * 3.6, 2.6, blooms[i % blooms.size()])
				b.circle(bp, 2.0, Color(0.30, 0.50, 0.26))
		_:      # the hairdresser: a striped blind and a pot by the door
			_awning(b, Rect2(fx - 24.0, y - 40.0, 24.0, 80.0), Color(0.30, 0.30, 0.34), Color(0.86, 0.86, 0.88))
			b.circle(Vector2(fx - 28.0, y + 52.0), 7.0, Color(0.62, 0.36, 0.24))
			b.circle(Vector2(fx - 28.0, y + 52.0), 5.6, Color(0.28, 0.50, 0.26))


# an awning out over the pavement, its stripes across, its scalloped hem
static func _awning(b: ShapeBatch, r: Rect2, a: Color, c: Color) -> void:
	b.rect(Rect2(r.position + Vector2(-4.0, 5.0), r.size), Color(0, 0, 0, 0.16))
	var y := r.position.y
	var i := 0
	while y < r.end.y:
		b.rect(Rect2(r.position.x, y, r.size.x, minf(10.0, r.end.y - y)), a if i % 2 == 0 else c)
		y += 10.0
		i += 1
	var hy := r.position.y + 5.0
	while hy < r.end.y:
		b.circle(Vector2(r.position.x, hy), 3.0, a)
		hy += 10.0


# The lawns' pieces, in the order she meets them
static func _draw_lawns(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	if _in_view(ROSEMARY_BED, top, bot):
		_shrub_bed(m, b, ROSEMARY_BED, ROSEMARY, Color(0.66, 0.70, 0.90), 1)
	if _in_view(FLOWER_BED, top, bot):
		_flower_bed(m, b)
	if _in_view(ROSE_BED, top, bot):
		_shrub_bed(m, b, ROSE_BED, Color(0.24, 0.40, 0.22), Color(0.86, 0.18, 0.24), 3)
	if CHESS.y > top - 60.0 and CHESS.y < bot + 60.0:
		_chess(m, b)
	if _in_view(PICNIC, top, bot):
		_picnic(m, b)
	if _in_view(SPECTATORS, top, bot):
		# the petanca's spectators, on a bench facing the pitch
		var sr := SPECTATORS
		b.rect(Rect2(sr.position + Shade.light * 3.0, sr.size), _shadow(m))
		b.rect(sr, TIMBER)
		b.rect(Rect2(sr.position.x, sr.position.y, 4.0, sr.size.y), TIMBER_LIT)
		_person(m, b, sr.position + Vector2(13.0, 16.0), Color(0.44, 0.40, 0.34), Color(0.30, 0.28, 0.26))
		_person(m, b, sr.position + Vector2(13.0, 46.0), Color(0.30, 0.36, 0.30), Color(0.86, 0.86, 0.88))
		b.circle(sr.position + Vector2(-8.0, 30.0), 4.0, Color(0.52, 0.36, 0.22))
	if _in_view(GYM_PAD, top, bot):
		_gym(m, b)
	if _in_view(LAVENDER_BED, top, bot):
		_shrub_bed(m, b, LAVENDER_BED, Color(0.46, 0.52, 0.44), LAVENDER, 2)
	if top < -2280.0 and bot > -2520.0:
		_kiosk_bar(m, b)
	if _in_view(PERGOLA, top, bot):
		_pergola(m, b)
	if top < -3800.0 and bot > -3920.0:
		_parent_bench(m, b)
	if _in_view(HORT, top, bot):
		_hort(m, b)
	for t: Vector2 in YOUNG_TREES:
		if t.y > top - 40.0 and t.y < bot + 40.0:
			_young_tree(m, b, t)
	if BAG_POST.y > top - 30.0 and BAG_POST.y < bot + 30.0:
		_bag_post(m, b, BAG_POST)


static func _in_view(r: Rect2, top: float, bot: float) -> bool:
	return r.end.y > top - 40.0 and r.position.y < bot + 40.0


# a raised bed edged in timber, clipped shrubs in a double row, in flower
static func _shrub_bed(m: Node2D, b: ShapeBatch, r: Rect2, leaf: Color, bloom: Color, salt: int) -> void:
	b.rect(Rect2(r.position + Shade.light * 4.0, r.size), _shadow(m))
	b.rect(r, TIMBER)
	b.rect(r.grow(-4.0), SOIL)
	var y := r.position.y + 18.0
	var k := 0
	while y < r.end.y - 10.0:
		for col in range(2):
			var p := Vector2(r.position.x + r.size.x * (0.28 + 0.44 * float(col)), y + float(col) * 12.0)
			var rr := (16.0 if salt == 1 else 12.0) + _h1(k * 2 + col, float(salt)) * 4.0
			b.circle(p + Shade.light * 4.0, rr, Color(0, 0, 0, 0.16))
			b.circle(p, rr, leaf.darkened(0.15))
			b.circle(p - Shade.light * 4.0, rr * 0.7, leaf)
			var nf := 4 if salt == 1 else 9
			for f in range(nf):
				var fa := TAU * _h1(k * 16 + col * 8 + f, float(salt) + 3.0)
				var fd := rr * (0.3 + 0.5 * _h1(k * 16 + col * 8 + f, float(salt) + 4.0))
				b.circle(p + Vector2.from_angle(fa) * fd, 2.0 if salt == 1 else 2.4, bloom)
		y += 36.0 if salt == 1 else 26.0
		k += 1


# the flower bed by the entrance: a stone edge, the season's planting in rings
static func _flower_bed(m: Node2D, b: ShapeBatch) -> void:
	var r := FLOWER_BED
	b.rect(Rect2(r.position + Shade.light * 3.0, r.size), _shadow(m))
	m._soft_rect(b, r, 18.0, GRANITE)
	m._soft_rect(b, r.grow(-5.0), 14.0, SOIL)
	var c := r.get_center()
	var rings: Array[Color] = [Color(0.92, 0.80, 0.22), Color(0.88, 0.30, 0.40), Color(0.94, 0.94, 0.92)]
	for i in range(3):
		var ry := r.size.y * 0.38 - float(i) * 18.0
		var rx := r.size.x * 0.34 - float(i) * 12.0
		var n := 18 - i * 4
		for j in range(n):
			var a := TAU * float(j) / float(n)
			var p := c + Vector2(cos(a) * rx, sin(a) * ry)
			b.circle(p, 4.4, Color(0.26, 0.46, 0.24))
			b.circle(p + Vector2(-1, -1), 2.4, rings[i])
	b.circle(c, 9.0, Color(0.22, 0.40, 0.22))
	b.circle(c - Shade.light * 2.0, 5.0, Color(0.34, 0.56, 0.30))


# The old folks' exercise corner on its rubber pad: a pedal machine, a double
# walker, a twisting disc and an arm wheel, two neighbours at them
static func _gym(m: Node2D, b: ShapeBatch) -> void:
	var r := GYM_PAD
	m._soft_rect(b, r.grow(3.0), 10.0, RUBBER_GREEN.darkened(0.25))
	m._soft_rect(b, r, 8.0, RUBBER_GREEN)
	var dot := RUBBER_GREEN.lightened(0.1)
	var y := r.position.y + 10.0
	while y < r.end.y:
		var x := r.position.x + 8.0 + fmod(y, 20.0) * 0.3
		while x < r.end.x - 4.0:
			b.circle(Vector2(x, y), 1.0, dot)
			x += 14.0
		y += 12.0
	for i in range(GYM_MACHINES.size()):
		var p: Vector2 = GYM_MACHINES[i]
		b.circle(p + Shade.light * 8.0, 14.0, _shadow(m))
		b.circle(p, 5.0, GYM_STEEL.darkened(0.2))
		match i:
			0:      # pedals: a seat and the crank
				b.rect(Rect2(p.x - 7.0, p.y + 2.0, 14.0, 9.0), GYM_YELLOW)
				b.circle(p + Vector2(0, -11), 6.0, GYM_STEEL)
				b.circle(p + Vector2(0, -11), 2.5, GYM_YELLOW)
			1:      # the walker: two swinging foot plates under a handle bar
				b.line(p + Vector2(-12, -4), p + Vector2(12, -4), GYM_STEEL, 3.0)
				b.rect(Rect2(p.x - 10.0, p.y + 2.0, 8.0, 12.0), GYM_YELLOW)
				b.rect(Rect2(p.x + 2.0, p.y + 6.0, 8.0, 12.0), GYM_YELLOW)
			2:      # the twisting disc to stand on
				b.circle(p + Vector2(0, 8), 10.0, GYM_YELLOW)
				b.circle(p + Vector2(0, 8), 6.0, GYM_YELLOW.darkened(0.2))
				b.line(p + Vector2(-10, -6), p + Vector2(10, -6), GYM_STEEL, 3.0)
			_:      # the arm wheel on its post
				b.circle(p + Vector2(-9, 0), 9.0, GYM_STEEL)
				b.circle(p + Vector2(-9, 0), 6.0, RUBBER_GREEN)
				b.line(p + Vector2(-17, 0), p + Vector2(-1, 0), GYM_YELLOW, 2.0)
	# two neighbours at it: one pedalling, one on the walker
	_person(m, b, GYM_MACHINES[0] + Vector2(0, 6), Color(0.62, 0.34, 0.46), Color(0.86, 0.86, 0.88))
	_person(m, b, GYM_MACHINES[1] + Vector2(0, 8), Color(0.30, 0.42, 0.62), Color(0.72, 0.70, 0.66))


# the kiosk bar by the square: a little green-and-cream cabin, its shutter up,
# and tables out on the lawn on a gravel pad, a couple of regulars
static func _kiosk_bar(m: Node2D, b: ShapeBatch) -> void:
	var pad := Rect2(900.0, -2500.0, 136.0, 210.0)
	m._soft_rect(b, pad, 16.0, Color(0.70, 0.63, 0.50))
	var kr := KIOSK
	b.rect(Rect2(kr.position + Shade.light * 6.0, kr.size), _shadow(m))
	b.rect(kr, Color(0.90, 0.86, 0.76))
	b.rect(kr.grow(-4.0), KIOSK_GREEN)
	for i in range(4):
		b.rect(Rect2(kr.position.x + 4.0 + float(i) * 16.0, kr.position.y + 4.0, 8.0, kr.size.y - 8.0), KIOSK_GREEN.lightened(0.08))
	# the counter's shutter, propped up over the side to the tables
	b.rect(Rect2(kr.position.x + 8.0, kr.end.y, kr.size.x - 16.0, 10.0), Color(0.92, 0.88, 0.80))
	b.rect(Rect2(kr.position.x + 8.0, kr.end.y + 8.0, kr.size.x - 16.0, 2.0), Color(0.80, 0.30, 0.20))
	# the ice cream sign on its stand
	b.circle(Vector2(kr.end.x + 8.0, kr.position.y + 6.0), 6.0, Color(0.96, 0.92, 0.84))
	b.circle(Vector2(kr.end.x + 8.0, kr.position.y + 3.0), 3.4, Color(0.92, 0.52, 0.62))
	for i in range(KIOSK_TABLES.size()):
		var tc: Vector2 = KIOSK_TABLES[i]
		for cd: Vector2 in [Vector2(-14, 2), Vector2(14, -2)]:
			b.rect(Rect2(tc + cd - Vector2(5, 5), Vector2(10, 10)), Color(0.82, 0.30, 0.20))
		b.circle(tc + Shade.light * 3.0, 11.0, _shadow(m))
		b.circle(tc, 11.0, Color(0.30, 0.32, 0.34))
		b.circle(tc, 9.5, Color(0.86, 0.86, 0.84))
		b.circle(tc + Vector2(-3, -2), 2.4, Color(0.62, 0.34, 0.18))
		if i == 1:
			b.circle(tc + Vector2(4, 3), 2.0, Color(0.96, 0.84, 0.40))
	_person(m, b, KIOSK_TABLES[0] + Vector2(-14, 2), Color(0.40, 0.40, 0.44), Color(0.30, 0.28, 0.26))
	_person(m, b, KIOSK_TABLES[3] + Vector2(14, -2), Color(0.70, 0.56, 0.32), Color(0.84, 0.84, 0.86))


# The pergola on the west lawn: timber posts and beams under a bougainvillea,
# two benches in its shade with the petanca's spectators on them
static func _pergola(m: Node2D, b: ShapeBatch) -> void:
	var r := PERGOLA
	m._soft_rect(b, r.grow(4.0), 8.0, Color(0.70, 0.63, 0.50))
	# the benches under it
	for by: float in [r.position.y + 50.0, r.end.y - 70.0]:
		b.rect(Rect2(r.position.x + 20.0, by, 22.0, 60.0), TIMBER)
		b.rect(Rect2(r.position.x + 21.0, by + 1.0, 4.0, 58.0), TIMBER_LIT)
	_person(m, b, Vector2(r.position.x + 34.0, r.position.y + 72.0), Color(0.36, 0.38, 0.40), Color(0.28, 0.26, 0.24))
	_person(m, b, Vector2(r.position.x + 34.0, r.end.y - 40.0), Color(0.56, 0.30, 0.26), Color(0.86, 0.86, 0.88))
	# the beams, and the vine over them, thick at the posts and thin between
	var beam := Color(0.46, 0.32, 0.20)
	for x: float in [r.position.x + 6.0, r.end.x - 10.0]:
		b.rect(Rect2(x + 3.0, r.position.y + 4.0, 4.0, r.size.y), Color(0, 0, 0, 0.16))
		b.rect(Rect2(x, r.position.y, 4.0, r.size.y), beam)
	var cy := r.position.y + 10.0
	while cy < r.end.y:
		b.rect(Rect2(r.position.x, cy, r.size.x, 3.0), beam.lightened(0.1))
		cy += 22.0
	var k := 0
	for post: Vector2 in [r.position + Vector2(8, 8), Vector2(r.end.x - 8.0, r.position.y + 8.0),
			Vector2(r.position.x + 8.0, r.end.y - 8.0), r.end - Vector2(8, 8)]:
		b.circle(post, 6.0, beam.darkened(0.2))
		for j in range(16):
			var a := TAU * _h1(k * 16 + j, 31.0)
			var d := 6.0 + _h1(k * 16 + j, 32.0) * 44.0
			var p := post + Vector2.from_angle(a) * d
			p = Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
			b.circle(p, 8.0 - d * 0.08, Color(0.24, 0.42, 0.22))
			b.circle(p + Vector2(-1.5, -1.5), 4.0 - d * 0.04, BOUGAINVILLEA)
			b.circle(p + Vector2(2.0, 1.0), 2.4, BOUGAINVILLEA.lightened(0.15))
		k += 1


# across from the playground: a parent on a bench, the pram beside them, a
# scooter dropped on the grass
static func _parent_bench(m: Node2D, b: ShapeBatch) -> void:
	var r := PARENT_BENCH
	b.rect(Rect2(r.position + Shade.light * 3.0, r.size), _shadow(m))
	b.rect(r, TIMBER)
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 4.0), TIMBER_LIT)
	_person(m, b, r.get_center() + Vector2(10, 4), Color(0.86, 0.62, 0.30), Color(0.20, 0.16, 0.14))
	var p := PRAM
	b.rect(Rect2(p + Shade.light * 3.0 - Vector2(10, 14), Vector2(20, 28)), _shadow(m))
	m._soft_rect(b, Rect2(p - Vector2(10, 14), Vector2(20, 28)), 8.0, Color(0.24, 0.30, 0.42))
	m._soft_rect(b, Rect2(p - Vector2(8, 12), Vector2(16, 13)), 6.0, Color(0.32, 0.40, 0.54))
	b.line(p + Vector2(-8, 16), p + Vector2(8, 16), Color(0.18, 0.18, 0.20), 2.0)
	var s := Vector2(352.0, -3790.0)
	b.line(s, s + Vector2(26, 8), Color(0.24, 0.56, 0.86), 3.0)
	b.line(s + Vector2(26, 8), s + Vector2(30, -6), Color(0.24, 0.56, 0.86), 2.0)
	b.circle(s, 3.0, Color(0.14, 0.14, 0.14))
	b.circle(s + Vector2(26, 8), 3.0, Color(0.14, 0.14, 0.14))


# the neighbourhood's allotment by the pipica: raised timber beds with
# lettuces, tomatoes up their canes, and a watering can
static func _hort(m: Node2D, b: ShapeBatch) -> void:
	var r := HORT
	var bed_h := 62.0
	var y := r.position.y
	var k := 0
	while y + bed_h <= r.end.y + 1.0:
		var br := Rect2(r.position.x, y, r.size.x, bed_h)
		b.rect(Rect2(br.position + Shade.light * 4.0, br.size), _shadow(m))
		b.rect(br, TIMBER)
		b.rect(br.grow(-4.0), SOIL)
		match k % 3:
			0:      # lettuces in rows
				for i in range(6):
					for j in range(2):
						var p := br.position + Vector2(14.0 + float(i) * 17.0, 18.0 + float(j) * 24.0)
						b.circle(p, 6.0, Color(0.46, 0.68, 0.30))
						b.circle(p, 3.0, Color(0.62, 0.80, 0.40))
			1:      # tomatoes tied to canes
				for i in range(5):
					var p := br.position + Vector2(16.0 + float(i) * 20.0, br.size.y * 0.5)
					b.circle(p, 9.0, Color(0.24, 0.42, 0.22))
					b.line(p + Vector2(0, -12), p + Vector2(0, 12), Color(0.80, 0.72, 0.50), 1.4)
					b.circle(p + Vector2(4, 3), 2.6, Color(0.86, 0.20, 0.16))
					b.circle(p + Vector2(-3, -4), 2.2, Color(0.90, 0.36, 0.18))
			_:      # chard and a sunflower at the end
				for i in range(4):
					var p := br.position + Vector2(16.0 + float(i) * 20.0, br.size.y * 0.5)
					b.circle(p, 8.0, Color(0.28, 0.50, 0.26))
					b.line(p, p + Vector2(4, -6), Color(0.86, 0.24, 0.30), 1.6)
				var sf := br.position + Vector2(br.size.x - 16.0, br.size.y * 0.5)
				b.circle(sf, 10.0, Color(0.96, 0.78, 0.16))
				b.circle(sf, 5.0, Color(0.36, 0.24, 0.14))
		y += bed_h + 18.0
		k += 1
	# the watering can between the beds
	var wc := Vector2(r.end.x - 20.0, r.position.y + bed_h + 9.0)
	b.circle(wc, 6.0, Color(0.24, 0.56, 0.40))
	b.line(wc, wc + Vector2(-12, -3), Color(0.24, 0.56, 0.40), 2.0)


# the stone chess table, the board inlaid in its top, a game on and two
# players hunched over it
static func _chess(m: Node2D, b: ShapeBatch) -> void:
	var c := CHESS
	b.circle(c + Shade.light * 5.0, 20.0, _shadow(m))
	b.circle(c, 18.0, GRANITE)
	b.rect(Rect2(c - Vector2(10, 10), Vector2(20, 20)), Color(0.86, 0.84, 0.80))
	for i in range(4):
		for j in range(4):
			if (i + j) % 2 == 0:
				b.rect(Rect2(c.x - 10.0 + float(i) * 5.0, c.y - 10.0 + float(j) * 5.0, 5.0, 5.0), Color(0.30, 0.28, 0.26))
	for pc: Vector2 in [Vector2(-6, -7), Vector2(3, -3), Vector2(-2, 6), Vector2(7, 4)]:
		b.circle(c + pc, 1.6, Color(0.96, 0.96, 0.94) if pc.y < 0.0 else Color(0.12, 0.12, 0.12))
	for s: Vector2 in [Vector2(0, -30), Vector2(0, 30)]:
		b.circle(c + s, 8.0, GRANITE.darkened(0.1))
	_person(m, b, c + Vector2(0, -30), Color(0.42, 0.36, 0.30), Color(0.84, 0.84, 0.86))
	_person(m, b, c + Vector2(0, 30), Color(0.26, 0.30, 0.38), Color(0.30, 0.28, 0.26))


# a timber picnic table on the east lawn, its benches, a family's lunch
static func _picnic(m: Node2D, b: ShapeBatch) -> void:
	var r := PICNIC
	b.rect(Rect2(r.position + Shade.light * 4.0, r.size), _shadow(m))
	for by: float in [r.position.y, r.end.y - 9.0]:
		b.rect(Rect2(r.position.x, by, r.size.x, 9.0), TIMBER)
	var t := Rect2(r.position.x + 4.0, r.position.y + 13.0, r.size.x - 8.0, 18.0)
	b.rect(t, TIMBER_LIT)
	for i in range(4):
		b.rect(Rect2(t.position.x, t.position.y + float(i) * 4.5, t.size.x, 1.0), TIMBER)
	b.rect(Rect2(t.position.x + 8.0, t.position.y + 3.0, 14.0, 10.0), Color(0.92, 0.92, 0.90))
	b.circle(t.position + Vector2(34.0, 9.0), 4.0, Color(0.90, 0.36, 0.22))
	b.circle(t.position + Vector2(46.0, 7.0), 3.0, Color(0.96, 0.84, 0.40))
	_person(m, b, Vector2(r.position.x + 16.0, r.position.y + 4.0), Color(0.36, 0.56, 0.70), Color(0.24, 0.18, 0.14))
	_person(m, b, Vector2(r.end.x - 16.0, r.end.y - 4.0), Color(0.88, 0.70, 0.30), Color(0.50, 0.34, 0.20))


# a newly planted tree tied to its two stakes, a ring of bare earth round it
static func _young_tree(m: Node2D, b: ShapeBatch, t: Vector2) -> void:
	b.circle(t, 16.0, SOIL.lightened(0.15))
	b.circle(t + Shade.light * 10.0, 16.0, Color(0, 0, 0, 0.14))
	for sx: float in [-9.0, 9.0]:
		b.circle(t + Vector2(sx, 0), 2.2, Color(0.66, 0.54, 0.36))
		b.line(t + Vector2(sx, 0), t, Color(0.86, 0.80, 0.60), 1.0)
	b.circle(t, 15.0, Color(0.30, 0.50, 0.26))
	b.circle(t - Shade.light * 4.0, 10.0, Color(0.40, 0.62, 0.32))
	b.circle(t, 2.4, Color(0.42, 0.32, 0.22))


# the dog-bag dispenser: a green post, the roll's box, a bin under it
static func _bag_post(m: Node2D, b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Shade.light * 6.0, 7.0, _shadow(m))
	b.circle(p, 3.0, RAILING)
	b.rect(Rect2(p.x - 6.0, p.y - 18.0, 12.0, 12.0), Color(0.20, 0.50, 0.30))
	b.rect(Rect2(p.x - 3.0, p.y - 15.0, 6.0, 6.0), Color(0.94, 0.94, 0.92))
	b.circle(p + Vector2(0, 12), 6.0, Color(0.30, 0.32, 0.34))
	b.circle(p + Vector2(0, 12), 4.0, Color(0.16, 0.16, 0.18))


# a neighbour seen from above, sitting or standing: shoulders, head, hair
static func _person(m: Node2D, b: ShapeBatch, p: Vector2, body: Color, hair: Color) -> void:
	b.circle(p + Shade.light * 3.0, 10.0, _shadow(m))
	b.circle(p, 9.5, body)
	b.circle(p + Vector2(0, 2), 7.0, body.darkened(0.12))
	b.circle(p + Vector2(0, -3), 5.2, Color(0.84, 0.68, 0.56))
	b.circle(p + Vector2(0, -4), 5.0, hair)
	b.circle(p + Vector2(-1.5, -5.5), 1.6, hair.lightened(0.2))


# the paved paths across the lawn from each gate in the railing to the gravel
static func _desire_paths(_m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	for g: Vector2 in RAIL_GATES:
		if g.y < top - 40.0 or g.y > bot + 40.0:
			continue
		var x0: float = minf(g.x, 402.0 if g.x < 640.0 else 878.0)
		var x1: float = maxf(g.x, 402.0 if g.x < 640.0 else 878.0)
		_panots(b, x0, x1, g.y - 18.0, g.y + 18.0)
		b.rect(Rect2(x0, g.y - 20.0, x1 - x0, 2.0), GRANITE)
		b.rect(Rect2(x0, g.y + 18.0, x1 - x0, 2.0), GRANITE)


static func _motorbike(b: ShapeBatch, p: Vector2, side: float, v: float) -> void:
	var col := Color(0.16, 0.18, 0.22)
	if v > 0.66:
		col = Color(0.70, 0.18, 0.16)
	elif v > 0.33:
		col = Color(0.86, 0.84, 0.80)
	var ax := Vector2(side, 0.0)
	b.rect(Rect2(p.x - 18.0 + 3.0, p.y - 4.0 + 5.0, 36.0, 10.0), Color(0, 0, 0, 0.25))
	b.circle(p - ax * 14.0, 5.0, Color(0.10, 0.10, 0.10))
	b.circle(p + ax * 14.0, 5.0, Color(0.10, 0.10, 0.10))
	b.rect(Rect2(p.x - 11.0, p.y - 5.0, 22.0, 10.0), col)
	b.rect(Rect2(p.x - 4.0, p.y - 4.0, 9.0, 8.0), Color(0.12, 0.12, 0.12))
	b.line(p - ax * 13.0 + Vector2(0, -8), p - ax * 13.0 + Vector2(0, 8), Color(0.60, 0.62, 0.64), 2.0)
	# a helmet left on the seat now and then
	if v < 0.2:
		b.circle(p + ax * 3.0, 4.5, Color(0.92, 0.90, 0.30))


# The Bicing dock on the east pavement: the red bikes in their stands
static func _bicing(b: ShapeBatch, at: Vector2) -> void:
	b.rect(Rect2(at.x - 6.0, at.y - 110.0, 12.0, 220.0), Color(0.40, 0.40, 0.42))
	b.rect(Rect2(at.x - 10.0, at.y - 124.0, 20.0, 18.0), Color(0.22, 0.22, 0.24))
	b.rect(Rect2(at.x - 7.0, at.y - 121.0, 14.0, 8.0), Color(0.50, 0.74, 0.86))
	var y := at.y - 96.0
	var k := 0
	while y < at.y + 104.0:
		b.circle(Vector2(at.x, y), 3.0, Color(0.24, 0.24, 0.26))
		if k % 4 != 2:
			b.line(Vector2(at.x - 18.0, y), Vector2(at.x + 18.0, y), BICING_RED, 4.0)
			b.circle(Vector2(at.x - 16.0, y), 4.0, Color(0.12, 0.12, 0.12))
			b.circle(Vector2(at.x + 16.0, y), 4.0, Color(0.12, 0.12, 0.12))
			b.rect(Rect2(at.x + 6.0, y - 4.0, 6.0, 8.0), Color(0.94, 0.94, 0.92))
		y += 24.0
		k += 1


# The rooftop terraces past the street: each building its own depth, a
# parapet round its terrat of red tiles, a water tank, a skylight, and a
# washing line or pots of geraniums along the street front
static func _terrats(b: ShapeBatch, x0: float, side: float, top: float, bot: float) -> void:
	var y := floorf(top / 600.0) * 600.0
	var k := int(absf(y) / 600.0) * 7
	while y < bot:
		var depth := 70.0 + _h1(k, 1.0) * 60.0
		var ny := y + depth
		if ny > top:
			var r := Rect2(x0 if side > 0.0 else x0 - 520.0, y, 520.0, depth)
			var face: float = x0 + side * 6.0
			b.rect(r, PARAPET)
			var inner := r.grow(-6.0)
			var tile := TERRAT.lerp(Color(0.66, 0.44, 0.34), _h1(k, 2.0))
			b.rect(inner, tile)
			var gx := inner.position.x + 14.0
			while gx < inner.end.x:
				b.line(Vector2(gx, inner.position.y), Vector2(gx, inner.end.y), tile.darkened(0.12), 1.0)
				gx += 14.0
			# the party wall to the next building
			b.rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 6.0), PARAPET.darkened(0.15))
			# a water tank and a skylight, near the street front
			var tx := face + side * (40.0 + _h1(k, 3.0) * 60.0)
			b.circle(Vector2(tx, y + depth * 0.5) + Vector2(4, 6), 12.0, Color(0, 0, 0, 0.22))
			b.circle(Vector2(tx, y + depth * 0.5), 12.0, Color(0.84, 0.84, 0.82))
			b.circle(Vector2(tx, y + depth * 0.5), 5.0, Color(0.60, 0.62, 0.64))
			var sx := face + side * (120.0 + _h1(k, 4.0) * 80.0)
			b.rect(Rect2(sx - 14.0, y + 14.0, 28.0, 20.0), Color(0.46, 0.62, 0.70))
			b.line(Vector2(sx - 14.0, y + 24.0), Vector2(sx + 14.0, y + 24.0), Color(0.86, 0.90, 0.92), 1.4)
			if _h1(k, 5.0) > 0.5:
				var lx := face + side * 30.0
				b.line(Vector2(lx, y + 12.0), Vector2(lx, ny - 12.0), Color(0.82, 0.82, 0.80), 1.0)
				var cy := y + 18.0
				var ci := 0
				while cy < ny - 18.0:
					b.rect(Rect2(lx - 5.0, cy, 10.0, 8.0), WASHING[(k + ci) % WASHING.size()])
					cy += 16.0
					ci += 1
			else:
				for pk in range(3):
					var pp := Vector2(face + side * 12.0, y + 14.0 + float(pk) * 16.0)
					if pp.y < ny - 8.0:
						b.circle(pp, 5.0, Color(0.62, 0.36, 0.24))
						b.circle(pp, 3.6, Color(0.30, 0.52, 0.26))
						b.circle(pp + Vector2(1, -1), 1.6, Color(0.90, 0.24, 0.30))
		y = ny
		k += 1
