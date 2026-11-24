extends RefCounted

# Barcelona's rooftops, for every walk whose blocks are the city's own: what
# there is past the building line, out to the edge of the screen.
#
# A block is houses along the street, the yard inside the island behind them,
# and the backs of the next street's houses. A house is a terrat (a flat roof
# of fired tiles inside its parapet, with the stair's little house, a tank, a
# skylight over the stairwell, washing, pots, an awning on cane, solar panels,
# aerials, never all at once) or, now and then, a pitched roof of pantiles.
# Nothing here is random: each house is its own by a hash, so it is the same
# every time it comes back into view.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const DARK := Color(0.16, 0.13, 0.14)
const SHADE := Color(0.05, 0.04, 0.08, 0.24)
const PARAPET: Array[Color] = [Color(0.80, 0.74, 0.64), Color(0.74, 0.66, 0.56), Color(0.84, 0.80, 0.72), Color(0.70, 0.60, 0.52)]
const FIRED: Array[Color] = [Color(0.68, 0.42, 0.32), Color(0.62, 0.38, 0.30), Color(0.72, 0.48, 0.36), Color(0.60, 0.46, 0.40), Color(0.66, 0.54, 0.46)]
const FELT: Array[Color] = [Color(0.52, 0.51, 0.50), Color(0.60, 0.58, 0.54), Color(0.46, 0.47, 0.49)]
const PANTILE: Array[Color] = [Color(0.66, 0.36, 0.24), Color(0.60, 0.32, 0.23), Color(0.71, 0.42, 0.29)]
const WASH: Array[Color] = [Color(0.92, 0.91, 0.87), Color(0.40, 0.54, 0.72), Color(0.82, 0.36, 0.36), Color(0.90, 0.76, 0.40), Color(0.46, 0.64, 0.52), Color(0.88, 0.86, 0.90)]
const CANVAS_COL: Array[Color] = [Color(0.86, 0.78, 0.60), Color(0.80, 0.46, 0.34), Color(0.50, 0.66, 0.62)]
const LEAF := Color(0.26, 0.42, 0.26)
const LEAF_LIT := Color(0.40, 0.56, 0.34)
const BLOOM: Array[Color] = [Color(0.88, 0.26, 0.34), Color(0.94, 0.60, 0.26), Color(0.78, 0.42, 0.76)]


static func _h(k: int) -> float:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h ^ (h >> 16)) % 100003) / 100003.0


# How lit the lamps are, asked of the autoload by its node: a test may load
# this script before the autoloads have names.
static func _glow() -> float:
	var loop := Engine.get_main_loop()
	var game: Node = (loop as SceneTree).root.get_node_or_null("Game") if loop is SceneTree else null
	return float(game.lamp_glow()) if game != null else 0.0


static func _pick(list: Array[Color], k: int) -> Color:
	return list[int(_h(k) * float(list.size())) % list.size()]


# One module of a street's edge: the block from `inner_x`, the roofs' street
# side, out to `far`, between y0 and y1.
static func module(b: ShapeBatch, inner_x: float, side: float, far: float, y0: float, y1: float, salt: int) -> void:
	var front := 132.0 + 28.0 * _h(salt * 7 + 1)
	var yard := 64.0 + 30.0 * _h(salt * 7 + 2)
	var x_at := func(d: float) -> float: return inner_x + side * d
	_row(b, x_at.call(0.0), x_at.call(front), y0, y1, salt * 31 + 3)
	_yard(b, _span(x_at.call(front), x_at.call(front + yard), y0, y1), salt * 13)
	_row(b, x_at.call(front + yard), x_at.call(front + yard + 130.0), y0, y1, salt * 31 + 11)
	if far > front + yard + 130.0:
		# the next street, its shade, and the block across it
		var s := front + yard + 130.0
		b.rect(_span(x_at.call(s), x_at.call(minf(far, s + 46.0)), y0, y1), Color(0.24, 0.23, 0.26))
		if far > s + 46.0:
			_row(b, x_at.call(s + 46.0), x_at.call(far), y0, y1, salt * 31 + 23)


# The same, kept: built once per place and lamplight, whoever asks.
static var _kept := {}


static func kept_module(b: ShapeBatch, inner_x: float, side: float, far: float, y0: float, y1: float, salt: int) -> void:
	var key := [inner_x, far * side, y0, y1, salt, snappedf(_glow(), 0.1)]
	var rec: ShapeBatch = _kept.get(key)
	if rec == null:
		if _kept.size() > 120:
			_kept.clear()
		rec = ShapeBatch.new()
		rec.lod = true
		module(rec, inner_x, side, far, y0, y1, salt)
		_kept[key] = rec
	rec.append_to(b)


static func _span(xa: float, xb: float, y0: float, y1: float) -> Rect2:
	return Rect2(minf(xa, xb), y0, absf(xb - xa), y1 - y0)


# a row of houses side by side along y, their depth from xa to xb
static func _row(b: ShapeBatch, xa: float, xb: float, y0: float, y1: float, salt: int) -> void:
	var y := y0
	var i := 0
	while y < y1 - 1.0:
		var h := 74.0 + 56.0 * _h(salt + i * 5)
		if y1 - y - h < 60.0:
			h = y1 - y
		house(b, _span(xa, xb, y, y + h), salt * 3 + i * 17)
		y += h
		i += 1


# fill any rectangle with houses: behind a park, over the way you came in
static func quarter(b: ShapeBatch, r: Rect2, salt: int) -> void:
	b.rect(r, DARK)
	var y := r.position.y
	var row := 0
	while y < r.end.y - 1.0:
		var h := 112.0 + 46.0 * _h(salt + row * 13)
		if r.end.y - y - h < 60.0:
			h = r.end.y - y
		var x := r.position.x
		var col := 0
		while x < r.end.x - 1.0:
			var w := 92.0 + 62.0 * _h(salt * 5 + row * 29 + col * 3)
			if r.end.x - x - w < 60.0:
				w = r.end.x - x
			house(b, Rect2(x, y, w, h), salt * 7 + row * 41 + col * 11)
			x += w
			col += 1
		y += h
		row += 1


static func house(b: ShapeBatch, r: Rect2, k: int) -> void:
	if r.size.x < 16.0 or r.size.y < 16.0:
		b.rect(r, DARK)
		return
	if _h(k + 1) < 0.16:
		_pitched(b, r, k)
	else:
		_terrat(b, r, k)
	# a taller neighbour's shade across one side of it
	if _h(k + 2) < 0.35:
		var w := 10.0 + 14.0 * _h(k + 3)
		b.band(PackedVector2Array([r.position, r.position + Vector2(w, 0), Vector2(r.position.x, r.end.y), Vector2(r.position.x + w, r.end.y)]),
			2, Color(0.04, 0.03, 0.07), PackedFloat32Array([0.34, 0.34]), PackedFloat32Array([1.0, 0.0]))


static func _pitched(b: ShapeBatch, r: Rect2, k: int) -> void:
	var tile := _pick(PANTILE, k + 5)
	var c := r.get_center()
	b.rect(r, DARK)
	var q := r.grow(-1.5)
	b.rect(Rect2(q.position.x, q.position.y, c.x - q.position.x, q.size.y), tile.lightened(0.10))
	b.rect(Rect2(c.x, q.position.y, q.end.x - c.x, q.size.y), tile.darkened(0.16))
	var y := q.position.y + 5.0
	while y < q.end.y:
		b.line(Vector2(q.position.x, y), Vector2(c.x - 2.0, y), tile.darkened(0.08), 1.6)
		b.line(Vector2(c.x + 2.0, y), Vector2(q.end.x, y), tile.darkened(0.30), 1.6)
		y += 9.0
	b.line(Vector2(c.x, q.position.y), Vector2(c.x, q.end.y), tile.lightened(0.28), 3.0)
	_stack(b, Vector2(lerpf(q.position.x, c.x, 0.5), lerpf(q.position.y, q.end.y, 0.25 + 0.4 * _h(k + 6))))
	if _h(k + 7) < 0.4:
		_glass(b, Rect2(c.x + q.size.x * 0.14, q.position.y + q.size.y * 0.4, 16.0, 20.0), k)


static func _stack(b: ShapeBatch, p: Vector2) -> void:
	b.rect(Rect2(p + Vector2(4, 6), Vector2(16, 12)), SHADE)
	b.rect(Rect2(p, Vector2(14, 11)), Color(0.50, 0.36, 0.30))
	b.rect(Rect2(p, Vector2(14, 3)), Color(0.62, 0.46, 0.38))
	for i in range(2):
		b.circle(p + Vector2(4.0 + 6.0 * float(i), 6.5), 2.2, Color(0.16, 0.11, 0.10))


static func _glass(b: ShapeBatch, r: Rect2, k: int) -> void:
	var lit := _glow()
	b.rect(Rect2(r.position + Vector2(3, 4), r.size), SHADE)
	b.rect(r, Color(0.30, 0.32, 0.36))
	var on := lit > 0.05 and _h(k + 9) < 0.6
	b.rect(r.grow(-2.0), Color(0.98, 0.82, 0.50) if on else Color(0.50, 0.64, 0.72))
	b.line(Vector2(r.get_center().x, r.position.y + 2.0), Vector2(r.get_center().x, r.end.y - 2.0), Color(0.30, 0.32, 0.36), 1.4)
	b.line(Vector2(r.position.x + 2.0, r.get_center().y), Vector2(r.end.x - 2.0, r.get_center().y), Color(0.30, 0.32, 0.36), 1.4)
	if on:
		b.glow(r.get_center(), 32.0, Color(1.0, 0.80, 0.46, 0.22 * lit))
	else:
		b.polygon(PackedVector2Array([r.position + Vector2(3, 3), r.position + Vector2(r.size.x * 0.5, 3), r.position + Vector2(3, r.size.y * 0.55)]), Color(1, 1, 1, 0.22))


static func _pot(b: ShapeBatch, p: Vector2, k: int) -> void:
	b.circle(p + Vector2(1.5, 2.5), 5.0, SHADE)
	b.circle(p, 4.6, Color(0.60, 0.34, 0.24))
	b.circle(p, 3.9, LEAF)
	b.circle(p - Vector2(1.0, 1.2), 2.0, LEAF_LIT)
	if _h(k) < 0.6:
		b.circle(p + Vector2(1.0, 0.6), 1.6, _pick(BLOOM, k + 1))


static func _terrat(b: ShapeBatch, r: Rect2, k: int) -> void:
	var par := _pick(PARAPET, k + 11)
	var fired := _h(k + 12) < 0.72
	var ground := _pick(FIRED, k + 13) if fired else _pick(FELT, k + 13)
	b.rect(r, par.darkened(0.34))
	var cap := r.grow(-0.8)
	b.rect(cap, par)
	var q := r.grow(-5.0)
	b.rect(q, ground)
	# its tiles, or its felt in strips
	var step := 13.0 if fired else 24.0
	var y := q.position.y + step
	while y < q.end.y:
		b.line(Vector2(q.position.x, y), Vector2(q.end.x, y), ground.darkened(0.11), 1.1)
		y += step
	if fired:
		var x := q.position.x + step
		while x < q.end.x:
			b.line(Vector2(x, q.position.y), Vector2(x, q.end.y), ground.darkened(0.08), 1.0)
			x += step
	# the parapet's shade, from up and to the left
	b.rect(Rect2(q.position, Vector2(q.size.x, 5.0)), SHADE)
	b.rect(Rect2(q.position + Vector2(0, 5), Vector2(4.0, q.size.y - 5.0)), SHADE)
	if q.size.x < 44.0 or q.size.y < 40.0:
		return
	# the stair's little house, in one corner or another
	var corner := int(_h(k + 14) * 4.0) % 4
	var hs := Vector2(30.0 + 10.0 * _h(k + 15), 24.0 + 8.0 * _h(k + 16))
	var hp := Vector2(q.position.x + 6.0 if corner % 2 == 0 else q.end.x - hs.x - 6.0,
		q.position.y + 8.0 if corner < 2 else q.end.y - hs.y - 6.0)
	b.rect(Rect2(hp + Vector2(7, 11), hs), SHADE)
	b.rect(Rect2(hp, hs), par.darkened(0.22))
	b.rect(Rect2(hp, hs - Vector2(0, 5)), _pick(PANTILE, k + 17) if _h(k + 18) < 0.5 else par.lightened(0.08))
	b.rect(Rect2(hp + Vector2(hs.x * 0.36, hs.y - 5.0), Vector2(9, 5)), Color(0.34, 0.24, 0.20))
	var lo := q.position + Vector2(10, 12)
	var hi := q.end - Vector2(10, 10)
	var at := func(u: float, v: float) -> Vector2: return Vector2(lerpf(lo.x, hi.x, u), lerpf(lo.y, hi.y, v))
	# what else is up here, in the half the stair is not
	var fu := 0.70 if corner % 2 == 0 else 0.28
	var fv := 0.74 if corner < 2 else 0.24
	match int(_h(k + 19) * 6.0) % 6:
		0:
			# washing across it
			var a: Vector2 = at.call(0.04, fv)
			var z: Vector2 = at.call(0.96, fv + 0.05)
			b.line(a, z, Color(0.86, 0.86, 0.84, 0.9), 1.1)
			var n := int(a.distance_to(z) / 15.0)
			for i in range(n):
				if _h(k * 3 + i) < 0.2:
					continue
				var p := a.lerp(z, (float(i) + 0.5) / float(n))
				var dh := 9.0 + 8.0 * _h(k + i * 7)
				b.rect(Rect2(p + Vector2(-3.0, 5.0), Vector2(11, dh)), SHADE)
				b.rect(Rect2(p - Vector2(5.5, 0.0), Vector2(11, dh)), _pick(WASH, k * 5 + i))
		1:
			# solar panels, tilted to the sun
			for i in range(2 + int(_h(k + 20) * 2.0)):
				var p: Vector2 = at.call(clampf(fu - 0.22 + 0.24 * float(i), 0.0, 0.8), fv - 0.1)
				var pr := Rect2(p, Vector2(19, 25)).intersection(q.grow(-3.0))
				if pr.size.x < 8.0 or pr.size.y < 8.0:
					continue
				b.rect(Rect2(pr.position + Vector2(4, 5), pr.size), SHADE)
				b.rect(pr, Color(0.74, 0.76, 0.80))
				b.rect(pr.grow(-1.5), Color(0.14, 0.22, 0.40))
				b.line(Vector2(pr.position.x, pr.get_center().y), Vector2(pr.end.x, pr.get_center().y), Color(0.42, 0.52, 0.70), 1.0)
				b.line(Vector2(pr.get_center().x, pr.position.y), Vector2(pr.get_center().x, pr.end.y), Color(0.42, 0.52, 0.70), 1.0)
		2:
			# a table under canvas, and pots round it
			var p: Vector2 = at.call(fu, fv)
			var tr := Rect2(p - Vector2(20, 16), Vector2(40, 32)).intersection(q.grow(-3.0))
			if tr.size.x > 14.0 and tr.size.y > 14.0:
				var cc := _pick(CANVAS_COL, k + 21)
				b.rect(Rect2(tr.position + Vector2(6, 9), tr.size), SHADE)
				b.rect(tr, cc)
				var sx := tr.position.x
				var si := 0
				while sx < tr.end.x - 1.0:
					if si % 2 == 0:
						b.rect(Rect2(sx, tr.position.y, minf(7.0, tr.end.x - sx), tr.size.y), cc.lightened(0.24))
					sx += 7.0
					si += 1
				b.rect(Rect2(tr.position, Vector2(tr.size.x, 2.0)), cc.lightened(0.35))
			for i in range(4):
				_pot(b, at.call(0.02 + 0.32 * float(i), 1.0 if corner < 2 else 0.0), k * 3 + i)
		3:
			# the water tank and its pipe, and a couple of machines humming
			var p: Vector2 = at.call(fu, fv)
			b.circle(p + Vector2(5, 8), 13.0, SHADE)
			b.circle(p, 13.0, Color(0.66, 0.67, 0.68))
			b.circle(p - Vector2(1.5, 2.0), 11.0, Color(0.80, 0.81, 0.80))
			b.circle(p, 4.0, Color(0.58, 0.59, 0.60))
			for i in range(2):
				var m: Vector2 = at.call(clampf(fu + (0.28 if corner % 2 == 1 else -0.34), 0.0, 0.9), clampf(fv - 0.12 + 0.24 * float(i), 0.0, 0.9))
				b.rect(Rect2(m + Vector2(4, 5), Vector2(19, 14)), SHADE)
				b.rect(Rect2(m, Vector2(19, 14)), Color(0.80, 0.81, 0.82))
				b.circle(m + Vector2(8, 7), 5.0, Color(0.36, 0.38, 0.40))
				b.circle(m + Vector2(8, 7), 1.6, Color(0.70, 0.71, 0.72))
		4:
			# a light well down the middle of the house, a pane over the stairs
			var p: Vector2 = at.call(fu, fv)
			var w := Rect2(p - Vector2(16, 13), Vector2(32, 26)).intersection(q.grow(-3.0))
			if w.size.x > 12.0 and w.size.y > 12.0:
				b.rect(w.grow(3.0), par)
				b.rect(w, DARK)
				b.rect(Rect2(w.position, Vector2(w.size.x, w.size.y * 0.4)), par.darkened(0.55))
				b.rect(Rect2(w.position + Vector2(5, w.size.y * 0.12), Vector2(5, 6)), Color(0.94, 0.80, 0.50) if _glow() > 0.05 else Color(0.36, 0.42, 0.50))
			_glass(b, Rect2(at.call(0.5, 0.5) - Vector2(8, 8), Vector2(16, 18)), k)
		_:
			# a garden, kept by somebody
			for i in range(7):
				_pot(b, at.call(fmod(0.02 + 0.17 * float(i), 1.0), (0.98 if i % 2 == 0 else 0.86) if corner < 2 else (0.02 if i % 2 == 0 else 0.14)), k * 7 + i)
			var p: Vector2 = at.call(fu, 0.5)
			b.circle(p + Vector2(4, 6), 11.0, SHADE)
			b.circle(p, 10.0, LEAF)
			b.circle(p - Vector2(2.5, 3.0), 6.0, LEAF_LIT)
	# an aerial on the stair house
	if _h(k + 23) < 0.5:
		var a := hp + Vector2(hs.x * 0.7, 6.0)
		b.line(a, a + Vector2(0, -17), Color(0.30, 0.30, 0.33), 1.4)
		for i in range(3):
			b.line(a + Vector2(-7, -6.0 - 4.5 * float(i)), a + Vector2(7, -6.0 - 4.5 * float(i)), Color(0.30, 0.30, 0.33), 1.0)
	if _h(k + 24) < 0.45:
		_stack(b, at.call(1.0 - fu, 1.0 - fv))


# The inside of the island: galleries' shade, flags, a tree or two, a patio
# with someone's chairs, a shed roof
static func _yard(b: ShapeBatch, r: Rect2, k: int) -> void:
	b.rect(r, Color(0.40, 0.38, 0.35))
	var y := r.position.y
	var i := 0
	while y < r.end.y - 1.0:
		var h := minf(88.0, r.end.y - y)
		var p := Rect2(r.position.x + 3.0, y + 3.0, r.size.x - 6.0, h - 6.0)
		var what := _h(k + i * 9)
		if what < 0.30:
			b.rect(p, Color(0.44, 0.52, 0.32))
		elif what < 0.55:
			b.rect(p, Color(0.56, 0.52, 0.45))
		else:
			b.rect(p, Color(0.50, 0.46, 0.42))
			var sy := p.position.y + 6.0
			while sy < p.end.y:
				b.line(Vector2(p.position.x, sy), Vector2(p.end.x, sy), Color(0.40, 0.37, 0.34), 1.6)
				sy += 8.0
		b.rect(Rect2(p.position.x, p.end.y, p.size.x, 4.0), Color(0.66, 0.58, 0.48))
		if what < 0.55:
			var t := p.get_center() + Vector2((_h(k + i) - 0.5) * p.size.x * 0.4, (_h(k + i + 4) - 0.5) * p.size.y * 0.4)
			var rr := minf(p.size.x, p.size.y) * (0.24 + 0.12 * _h(k + i * 3))
			b.circle(t + Vector2(6, 9), rr, SHADE)
			b.circle(t, rr, LEAF)
			for q in range(5):
				b.circle(t + Vector2.from_angle(float(q) * TAU / 5.0 + _h(k + q) * 2.0) * rr * 0.52, rr * 0.5, LEAF.lerp(LEAF_LIT, 0.2 + 0.4 * _h(k + q * 5)))
		y += h
		i += 1
	for e: float in [r.position.x, r.end.x - 9.0]:
		b.rect(Rect2(e, r.position.y, 9.0, r.size.y), Color(0.05, 0.04, 0.08, 0.30))
