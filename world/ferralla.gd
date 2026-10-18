class_name Ferralla
extends RefCounted

# La Ferralla's dressing (#158): the wreck stacks as four kinds of car in
# faded paint and rust, each stack turned a little its own way; the crane as
# a crawler crane, its lattice jib and hook block overhead; oily gravel and
# the odd weed along the fences instead of a lawn; rust that streaks the shed
# roofs rather than sitting on them in rows; and the yard past the gate as a
# scrapyard's back lot - tyre stacks, oil drums, lengths of pipe, a wreck.
# Draw-only apart from the yard's wreck (yard_wreck), and every variation is a
# hash of position, so a walk looks the same every run.

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08, 0.24)

# faded paint, then how far each car has gone to rust
const PAINT: Array[Color] = [
	Color(0.66, 0.20, 0.16), Color(0.86, 0.84, 0.76), Color(0.30, 0.48, 0.70), Color(0.78, 0.64, 0.24),
	Color(0.22, 0.22, 0.24), Color(0.84, 0.46, 0.16), Color(0.30, 0.46, 0.30), Color(0.52, 0.34, 0.54),
]
const RUST := Color(0.48, 0.28, 0.16)
const GLASSLESS := Color(0.11, 0.11, 0.12)
const SEAT := Color(0.30, 0.26, 0.22)
# the gravel along the fences, and the oil soaked into it
const GRAVEL := Color(0.34, 0.32, 0.29)
const OIL := Color(0.10, 0.10, 0.12, 0.5)
const CRANE_YELLOW := Color(0.92, 0.70, 0.12)

# the wreck in the yard's north-west corner, parked side on against the fences
const YARD_WRECK_SIZE := Vector2(132.0, 64.0)


static func _h(a: float, b: float) -> float:
	var n := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return n - floorf(n)


static func _quad(c: Vector2, half: Vector2, ang: float) -> PackedVector2Array:
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	return PackedVector2Array([c - ax * half.x - ay * half.y, c + ax * half.x - ay * half.y,
		c + ax * half.x + ay * half.y, c - ax * half.x + ay * half.y])


# a rect in a car's own frame (x across, y along, nose at -y) to world points
static func _part(c: Vector2, ang: float, r: Rect2) -> PackedVector2Array:
	var ax := Vector2.from_angle(ang)
	var ay := ax.orthogonal()
	var pts := PackedVector2Array()
	for q: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		pts.append(c + ax * q.x + ay * q.y)
	return pts


static func _pt(c: Vector2, ang: float, q: Vector2) -> Vector2:
	var ax := Vector2.from_angle(ang)
	return c + ax * q.x + ax.orthogonal() * q.y


# One wrecked car from above, nose up, in its own frame. kind: 0 saloon,
# 1 hatchback, 2 estate van, 3 crushed into a bale. `top` adds what only the
# top of a stack shows: the dents, the rust, a wheel left lying on the roof.
static func draw_car(b: Object, c: Vector2, ang: float, kind: int, paint: Color, seed: float, top: bool) -> void:
	var len := [122.0, 104.0, 126.0, 92.0][kind] as float
	var wid := 56.0 if kind != 3 else 60.0
	var hl := len * 0.5
	var hw := wid * 0.5
	var lo := paint.darkened(0.22)
	var hi := paint.lightened(0.14)
	if kind == 3:
		# a crushed car: a bale of folded metal, the paint in stripes where
		# the panels were pressed flat, and a wheel arch still in it
		b.polygon(_part(c, ang, Rect2(-hw, -hl, wid, len)), lo)
		for s in range(7):
			var y := -hl + 6.0 + float(s) * (len - 12.0) / 6.0
			var col: Color = paint if s % 2 == 0 else PAINT[int(seed * 7.0 + float(s)) % PAINT.size()].darkened(0.1)
			b.polygon(_part(c, ang, Rect2(-hw + 3.0, y - 5.0 + _h(seed, float(s)) * 3.0, wid - 6.0, 8.0)), col.lerp(RUST, 0.25))
			b.line(_pt(c, ang, Vector2(-hw + 3.0, y + 4.0)), _pt(c, ang, Vector2(hw - 3.0, y + 3.0)), Color(0, 0, 0, 0.35), 1.5)
		b.circle(_pt(c, ang, Vector2(hw - 14.0, -hl + 22.0)), 9.0, GLASSLESS)
		return
	# the body, rounded at the corners by a cut on each
	var body := PackedVector2Array([
		_pt(c, ang, Vector2(-hw + 6.0, -hl)), _pt(c, ang, Vector2(hw - 6.0, -hl)),
		_pt(c, ang, Vector2(hw, -hl + 8.0)), _pt(c, ang, Vector2(hw, hl - 6.0)),
		_pt(c, ang, Vector2(hw - 5.0, hl)), _pt(c, ang, Vector2(-hw + 5.0, hl)),
		_pt(c, ang, Vector2(-hw, hl - 6.0)), _pt(c, ang, Vector2(-hw, -hl + 8.0))])
	b.polygon(body, lo)
	b.polygon(_part(c, ang, Rect2(-hw + 3.0, -hl + 3.0, wid - 6.0, len - 6.0)), paint)
	# where the glass was: windscreen, roof, rear window, by kind
	var ws := [-hl + 34.0, -hl + 26.0, -hl + 22.0][kind] as float      # windscreen top
	var rf := [-hl + 52.0, -hl + 42.0, -hl + 38.0][kind] as float      # roof front
	var rb := [hl - 34.0, hl - 18.0, hl - 8.0][kind] as float          # roof back
	b.polygon(_part(c, ang, Rect2(-hw + 6.0, ws, wid - 12.0, rf - ws)), GLASSLESS)
	b.polygon(_part(c, ang, Rect2(-hw + 9.0, ws + 3.0, 12.0, rf - ws - 4.0)), SEAT)
	b.polygon(_part(c, ang, Rect2(hw - 21.0, ws + 3.0, 12.0, rf - ws - 4.0)), SEAT)
	b.polygon(_part(c, ang, Rect2(-hw + 5.0, rf, wid - 10.0, rb - rf)), hi)
	if kind == 2:
		for rib in range(4):
			var ry := rf + 10.0 + float(rib) * (rb - rf - 20.0) / 3.0
			b.line(_pt(c, ang, Vector2(-hw + 7.0, ry)), _pt(c, ang, Vector2(hw - 7.0, ry)), lo, 2.0)
	else:
		b.polygon(_part(c, ang, Rect2(-hw + 7.0, rb, wid - 14.0, (hl - 12.0) - rb if kind == 0 else 8.0)), GLASSLESS)
	# the bonnet's crease, the bumper gone on one end
	b.line(_pt(c, ang, Vector2(0.0, -hl + 6.0)), _pt(c, ang, Vector2(0.0, ws - 4.0)), lo, 1.5)
	if int(seed * 10.0) % 2 == 0:
		b.polygon(_part(c, ang, Rect2(-hw + 4.0, -hl - 3.0, wid - 8.0, 4.0)), Color(0.20, 0.20, 0.21))
	if not top:
		return
	# rust come through the paint, dents, a door missing
	for i in range(3):
		var q := Vector2((_h(seed, float(i)) - 0.5) * (wid - 16.0), (_h(float(i), seed) - 0.5) * (len - 24.0))
		var rp := PackedVector2Array()
		for j in range(6):
			var a := TAU * float(j) / 6.0
			var rr := (4.0 + float(i) * 2.0) * (0.7 + _h(seed + float(j), float(i)) * 0.6)
			rp.append(_pt(c, ang, q + Vector2(cos(a), sin(a) * 1.4) * rr))
		b.polygon(rp, RUST.lerp(paint, 0.15))
	b.polygon(_part(c, ang, Rect2(-hw * 0.4, rf + 6.0, 10.0, 8.0)), lo.darkened(0.2))
	if int(seed * 13.0) % 3 == 0:
		var side := -1.0 if int(seed * 17.0) % 2 == 0 else 1.0
		b.polygon(_part(c, ang, Rect2(side * hw - (4.0 if side > 0.0 else 0.0), ws, 4.0, 34.0)), GLASSLESS)
	if int(seed * 19.0) % 3 == 1:
		var wp := _pt(c, ang, Vector2(hw * 0.2, (rf + rb) * 0.5))
		b.circle(wp + LIGHT * 3.0, 12.0, SHADOW)
		b.circle(wp, 11.0, Color(0.12, 0.12, 0.13))
		b.circle(wp, 5.5, Color(0.52, 0.52, 0.54))


# A stack of three, each car a different kind and colour and turned its own
# way, so no two stacks down the lane read as the same picture. The shadow
# falls from the whole stack, which stands well over head height.
static func draw_wreck_stack(b: Object, v: Vector2, idx: int) -> void:
	var seed := _h(v.x * 0.01, v.y * 0.01)
	var base_ang := (seed - 0.5) * 0.16
	b.polygon(_quad(v + Vector2(26.0, 34.0), Vector2(31.0, 64.0), base_ang), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.28))
	for layer in range(3):
		var ls := _h(seed * 31.0, float(layer))
		var kind := int(ls * 4.0) % 4
		var paint: Color = PAINT[int(ls * 61.0) % PAINT.size()]
		if layer == 2:
			# the top is what reads: down the lane it goes saloon, hatchback,
			# van, bales, never the same colour twice running
			kind = idx % 4
			paint = PAINT[(idx * 3) % PAINT.size()]
		paint = paint.lerp(RUST, 0.10 + 0.25 * _h(ls, 3.0)).darkened(0.16 * float(2 - layer))
		var off := Vector2((_h(ls, 1.0) - 0.5) * 10.0, (_h(ls, 2.0) - 0.5) * 12.0) * (1.0 - float(layer) * 0.4)
		var ang := base_ang + (_h(ls, 4.0) - 0.5) * 0.18
		if _h(ls, 5.0) > 0.5:
			ang += PI          # facing the other way
		draw_car(b, v + off, ang, kind, paint, ls, layer == 2)


# Oil under and behind the stacks, as stains with a sheen, not puddles.
static func draw_oil(b: Object, c: Vector2, rx: float, ry: float, seed: float) -> void:
	for i in range(3):
		var pts := PackedVector2Array()
		var k := 1.0 - float(i) * 0.3
		for j in range(10):
			var a := TAU * float(j) / 10.0
			var rr := 0.75 + _h(seed + float(i), float(j)) * 0.4
			pts.append(c + Vector2(cos(a) * rx * rr * k, sin(a) * ry * rr * k) + Vector2(float(i) * 3.0, float(i) * 2.0))
		b.polygon(pts, Color(OIL.r, OIL.g, OIL.b, 0.18 + 0.1 * float(i)))
	b.line(c + Vector2(-rx * 0.3, -ry * 0.2), c + Vector2(rx * 0.1, -ry * 0.35), Color(0.46, 0.36, 0.60, 0.25), 2.0)


# The crane on the ground: two crawler tracks, the house slewed toward the
# jib with its counterweight striped at the back and the cab glazed at the
# front, and the jib's long shadow and the hook's lying across the lane.
# The jib itself is overhead (draw_crane_overhead).
static func draw_crane_ground(b: Object, cb: Vector2, tip: Vector2) -> void:
	var dir := (tip - cb).normalized()
	var ang := dir.angle()
	var sh := Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.20)
	# the jib's shadow and the hook's, thrown down-light from their height
	var lift := LIGHT * 70.0
	b.line(cb + LIGHT * 40.0, tip + lift, sh, 14.0)
	b.circle(tip + lift + LIGHT * 30.0, 12.0, sh)
	# the tracks run north-south, under the house
	b.rect(Rect2(cb.x - 52.0 + 14.0, cb.y - 64.0 + 20.0, 104.0, 128.0), sh)
	for tx: float in [-38.0, 38.0]:
		b.rect(Rect2(cb.x + tx - 14.0, cb.y - 62.0, 28.0, 124.0), Color(0.14, 0.14, 0.15))
		var cy := cb.y - 58.0
		while cy < cb.y + 58.0:
			b.line(Vector2(cb.x + tx - 13.0, cy), Vector2(cb.x + tx + 13.0, cy), Color(0.26, 0.26, 0.27), 2.0)
			cy += 7.0
		b.rect(Rect2(cb.x + tx - 5.0, cb.y - 52.0, 10.0, 104.0), Color(0.36, 0.36, 0.38))
	# the house, slewed to face along the jib
	b.polygon(_quad(cb + LIGHT * 8.0, Vector2(40.0, 30.0), ang), sh)
	b.polygon(_quad(cb, Vector2(40.0, 30.0), ang), CRANE_YELLOW.darkened(0.15))
	b.polygon(_quad(cb + dir * 2.0, Vector2(36.0, 26.0), ang), CRANE_YELLOW)
	# the counterweight at the back, striped
	var cw := cb - dir * 34.0
	b.polygon(_quad(cw, Vector2(10.0, 30.0), ang), Color(0.30, 0.30, 0.32))
	for s in range(5):
		var o := dir.orthogonal() * (-24.0 + float(s) * 12.0)
		b.line(cw + o - dir * 8.0, cw + o + dir * 4.0 + dir.orthogonal() * 6.0, CRANE_YELLOW, 3.0)
	# engine grille and exhaust
	for g in range(4):
		var gp := cb - dir * 12.0 + dir.orthogonal() * (8.0 + float(g) * 4.0)
		b.line(gp - dir * 8.0, gp + dir * 8.0, CRANE_YELLOW.darkened(0.35), 1.5)
	b.circle(cb - dir * 18.0 - dir.orthogonal() * 14.0, 3.5, Color(0.18, 0.18, 0.19))
	# the cab on the front corner, glazed, a roof light on top
	var cab := cb + dir * 22.0 - dir.orthogonal() * 16.0
	b.polygon(_quad(cab, Vector2(14.0, 11.0), ang), Color(0.26, 0.26, 0.28))
	b.polygon(_quad(cab + dir * 2.0, Vector2(10.0, 8.0), ang), Color(0.42, 0.56, 0.64))
	b.polygon(_quad(cab - dir * 2.0 - dir.orthogonal() * 3.0, Vector2(4.0, 3.0), ang), Color(0.70, 0.82, 0.88, 0.7))
	b.circle(cab - dir * 6.0, 2.5, Color(0.96, 0.56, 0.14))
	# the jib's foot pins at the front of the house
	b.polygon(_quad(cb + dir * 38.0, Vector2(6.0, 14.0), ang), Color(0.30, 0.30, 0.32))


# The lattice jib from the house out over the lane: two chords tapering to
# the tip, laced with diagonals, the pendant ropes back to the A-frame, and
# the hook block hanging under the tip on its falls. Overhead: walkers pass
# under it.
static func draw_crane_overhead(b: Object, cb: Vector2, tip: Vector2) -> void:
	var dir := (tip - cb).normalized()
	var nrm := dir.orthogonal()
	var foot := cb + dir * 38.0
	var span := foot.distance_to(tip)
	var dark := CRANE_YELLOW.darkened(0.35)
	var n := int(span / 22.0)
	var prev_l := Vector2.ZERO
	var prev_r := Vector2.ZERO
	for k in range(n + 1):
		var f := float(k) / float(n)
		var half := lerpf(12.0, 5.0, f)
		var p := foot.lerp(tip, f)
		var l := p + nrm * half
		var r := p - nrm * half
		if k > 0:
			# lacing: a zigzag between the chords, then the chords over it
			b.line(prev_l, r, dark, 1.5)
			b.line(prev_l, l, CRANE_YELLOW, 3.0)
			b.line(prev_r, r, CRANE_YELLOW, 3.0)
		b.line(l, r, dark, 1.5)
		prev_l = l
		prev_r = r
	# the pendants from the A-frame on the house to the tip
	var af := cb - dir * 6.0
	b.line(af + nrm * 6.0, tip + nrm * 3.0, Color(0.20, 0.20, 0.22, 0.85), 1.2)
	b.line(af - nrm * 6.0, tip - nrm * 3.0, Color(0.20, 0.20, 0.22, 0.85), 1.2)
	b.polygon(_quad(af, Vector2(5.0, 9.0), dir.angle()), dark)
	# the sheave at the tip, the falls down to the hook block below it
	b.circle(tip, 6.0, Color(0.30, 0.30, 0.32))
	b.circle(tip, 3.0, CRANE_YELLOW)
	var hook := tip + Vector2(0.0, 22.0)
	b.line(tip + Vector2(-2.0, 0.0), hook + Vector2(-2.0, -6.0), Color(0.22, 0.22, 0.24), 1.5)
	b.line(tip + Vector2(2.0, 0.0), hook + Vector2(2.0, -6.0), Color(0.22, 0.22, 0.24), 1.5)
	b.rect(Rect2(hook.x - 8.0, hook.y - 8.0, 16.0, 12.0), CRANE_YELLOW)
	for s in range(3):
		b.line(Vector2(hook.x - 8.0 + float(s) * 6.0, hook.y + 4.0), Vector2(hook.x - 4.0 + float(s) * 6.0, hook.y - 8.0),
			Color(0.14, 0.14, 0.15), 2.0)
	# the hook, open toward the light
	b.line(hook + Vector2(0, 4), hook + Vector2(0, 10), Color(0.34, 0.34, 0.36), 3.0)
	b.line(hook + Vector2(0, 10), hook + Vector2(5, 14), Color(0.34, 0.34, 0.36), 3.0)
	b.line(hook + Vector2(5, 14), hook + Vector2(8, 10), Color(0.34, 0.34, 0.36), 3.0)


# One cell of the strip along the fences: gravel and oil, and only now and
# then a weed - dandelion leaves, a thistle - pushing up through it.
static func draw_verge_cell(c: Object, p: Vector2, h: float) -> void:
	var kind := int(h * 1000.0) % 23
	if kind < 3:
		c.draw_circle(p, 9.0 + h * 8.0, Color(OIL.r, OIL.g, OIL.b, 0.22))
	elif kind < 5:
		# a weed: a rosette of leaves, the odd one a thistle head
		for l in range(5):
			var a := TAU * float(l) / 5.0 + h * 3.0
			c.draw_line(p, p + Vector2.from_angle(a) * (6.0 + float(l % 2) * 2.0), Color(0.30, 0.38, 0.20, 0.9), 2.4)
		if kind == 4:
			c.draw_circle(p + Vector2(1.0, -2.0), 2.2, Color(0.52, 0.36, 0.56))
	elif kind < 11:
		# grit: a few stones, light and dark
		for s in range(3):
			var o := Vector2(_h(h, float(s)) - 0.5, _h(float(s), h) - 0.5) * 14.0
			c.draw_circle(p + o, 1.4 + float(s) * 0.4, GRAVEL.lightened(0.18) if s % 2 == 0 else GRAVEL.darkened(0.3))
	elif kind == 11:
		# a rusted bolt or a washer, lost here
		c.draw_circle(p, 2.6, RUST)
		c.draw_circle(p, 1.0, GRAVEL.darkened(0.2))


# The shed roofs' rust: streaks running down the corrugations from the
# ridge, each its own length and width, and only on some roofs a patch where
# the sheet has gone through. Never a grid.
static func draw_roof_rust(b: Object, r: Rect2, inner_x: float, side: float, k: int) -> void:
	var streaks := 2 + int(_h(float(k), 1.0) * 4.0)
	for s in range(streaks):
		var sx := r.position.x + 4.0 + _h(float(k), float(s) + 2.0) * (r.size.x - 8.0)
		var sy := r.position.y + _h(float(s), float(k) + 5.0) * r.size.y * 0.6
		var ln := 30.0 + _h(float(k) + 3.0, float(s)) * 120.0
		var w := 3.0 + _h(float(s) + 7.0, float(k)) * 6.0
		b.line(Vector2(sx, sy), Vector2(sx + (_h(float(s), 9.0) - 0.5) * 6.0, minf(sy + ln, r.end.y)),
			Color(0.50, 0.29, 0.17, 0.45 + 0.25 * _h(float(k), float(s) + 11.0)), w)
	if int(_h(float(k), 13.0) * 10.0) % 3 == 0:
		var pc := Vector2(inner_x + side * (20.0 + _h(float(k), 17.0) * 40.0), r.position.y + 40.0 + _h(float(k), 19.0) * 140.0)
		var pts := PackedVector2Array()
		for j in range(8):
			var a := TAU * float(j) / 8.0
			var rr := 9.0 + _h(float(k) + float(j), 23.0) * 9.0
			pts.append(pc + Vector2(cos(a) * rr * 0.8, sin(a) * rr * 1.3))
		b.polygon(pts, Color(0.44, 0.24, 0.14, 0.75))
		b.circle(pc, 4.0, Color(0.10, 0.09, 0.09, 0.8))


# What stands in the yard where a park would have trees: a stack of tyres or
# a group of oil drums, on the grove's spot and the size of its trunk, so the
# rope still winds on it.
static func draw_yard_pile(b: Object, p: Vector2, i: int) -> void:
	if i % 2 == 0:
		# tyres, stacked a little off true
		b.circle(p + LIGHT * 10.0, 19.0, SHADOW)
		for t in range(4):
			var tp := p + Vector2(float(t % 2) * 3.0 - 1.5, -float(t) * 3.0)
			b.circle(tp, 17.0, Color(0.10, 0.10, 0.11).lightened(0.04 * float(t)))
			b.circle(tp, 8.0, Color(0.20, 0.19, 0.18))
		var top := p + Vector2(1.5, -9.0)
		for g in range(10):
			var a := TAU * float(g) / 10.0
			b.line(top + Vector2.from_angle(a) * 10.0, top + Vector2.from_angle(a) * 16.0, Color(0.22, 0.22, 0.24), 2.0)
		b.circle(top, 6.0, Color(0.30, 0.34, 0.36, 0.7))       # rainwater in the top one
	else:
		# oil drums: one standing on the spot, two beside it, one on its side
		var cols := [Color(0.22, 0.32, 0.46), Color(0.52, 0.20, 0.16), Color(0.30, 0.38, 0.26)]
		b.circle(p + LIGHT * 10.0, 18.0, SHADOW)
		draw_oil(b, p + Vector2(10.0, 16.0), 22.0, 12.0, float(i))
		for d in range(3):
			var dp := p + [Vector2(0, 0), Vector2(-22, 10), Vector2(18, 14)][d] as Vector2
			var col: Color = (cols[(i + d) % 3] as Color).lerp(RUST, 0.2 * float(d))
			# from above a drum is its lid: the rolled rim, a pressed ring,
			# the two bungs
			var dr := 12.0 if d == 0 else 10.0
			b.circle(dp, dr, col.darkened(0.35))
			b.circle(dp, dr - 1.5, col.lightened(0.12))
			b.circle(dp, dr - 3.5, col)
			b.circle(dp, dr - 5.0, col.lightened(0.06))
			b.circle(dp + Vector2(-dr * 0.45, -dr * 0.3), 1.8, Color(0.18, 0.18, 0.19))
			b.circle(dp + Vector2(dr * 0.5, dr * 0.25), 1.2, Color(0.18, 0.18, 0.19))
		var lp := p + Vector2(4.0, -24.0)
		b.polygon(_quad(lp, Vector2(16.0, 10.0), 0.3), (cols[(i + 1) % 3] as Color).lerp(RUST, 0.4))
		for e: float in [-8.0, 8.0]:
			b.line(lp + Vector2.from_angle(0.3) * e + Vector2.from_angle(0.3).orthogonal() * -10.0,
				lp + Vector2.from_angle(0.3) * e + Vector2.from_angle(0.3).orthogonal() * 10.0, Color(0, 0, 0, 0.3), 1.5)


# A length of steel pipe lying in the yard, where a park would have a log:
# the same footprint, rust on it, its bore dark at the end.
static func draw_pipe(b: Object, p: Vector2) -> void:
	b.rect(Rect2(p.x - 30.0 + 3.0, p.y - 9.0 + 5.0, 60.0, 18.0), SHADOW)
	b.rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 18.0), Color(0.40, 0.30, 0.24))
	b.rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 5.0), Color(0.56, 0.44, 0.36))
	b.rect(Rect2(p.x - 12.0, p.y - 9.0, 9.0, 18.0), RUST)
	b.circle(Vector2(p.x + 30.0, p.y), 9.0, Color(0.46, 0.40, 0.36))
	b.circle(Vector2(p.x + 30.0, p.y), 6.0, Color(0.08, 0.08, 0.09))


# The yard's own wreck: one car left where it died, no wheels, on blocks.
static func yard_wreck(fr: Rect2) -> Rect2:
	return Rect2(fr.position + Vector2(8.0, 8.0), YARD_WRECK_SIZE)


static func draw_yard_wreck(b: Object, fr: Rect2) -> void:
	var r := yard_wreck(fr)
	var c := r.get_center()
	draw_oil(b, c + Vector2(30.0, 20.0), 50.0, 20.0, 3.0)
	b.rect(Rect2(r.position + Vector2(8.0, 12.0), r.size), SHADOW)
	for bx: float in [-42.0, 42.0]:
		for by: float in [-24.0, 24.0]:
			b.rect(Rect2(c.x + bx - 7.0, c.y + by - 5.0, 14.0, 10.0), Color(0.56, 0.54, 0.50))
	draw_car(b, c, -PI * 0.5 + 0.03, 0, Color(0.66, 0.60, 0.40).lerp(RUST, 0.3), 0.37, true)
