extends RefCounted

# A wood from above, for every walk that has one beside it or round its
# clearing: crowns of several kinds and every size, in clumps with glades
# between, over a floor of leaf litter, ferns and stones. Each crown is built
# once per kind and shape and stamped after that. Seen only from outside: what
# she can walk among are the walk's own trees.

const ShapeBatch := preload("res://systems/shape_batch.gd")

enum K { HOLM, PINE, ALEPPO, OAK, FIR, SNOW_FIR, OLIVE, CYPRESS }
const SHAPES := 4

# what a place's wood is made of, its floor, and what lies on it
const LOOKS := {
	"collserola": {"kinds": [K.HOLM, K.HOLM, K.PINE, K.ALEPPO, K.OAK], "floor": Color(0.20, 0.25, 0.15), "litter": Color(0.36, 0.31, 0.18), "glade": Color(0.31, 0.38, 0.21)},
	"autumn": {"kinds": [K.OAK, K.OAK, K.HOLM, K.PINE, K.ALEPPO], "floor": Color(0.25, 0.23, 0.15), "litter": Color(0.50, 0.33, 0.16), "glade": Color(0.38, 0.34, 0.20)},
	"garden": {"kinds": [K.HOLM, K.CYPRESS, K.PINE, K.HOLM], "floor": Color(0.19, 0.27, 0.16), "litter": Color(0.30, 0.33, 0.18), "glade": Color(0.34, 0.45, 0.26)},
	"river": {"kinds": [K.OAK, K.ALEPPO, K.OAK, K.OLIVE], "floor": Color(0.22, 0.29, 0.18), "litter": Color(0.34, 0.36, 0.20), "glade": Color(0.36, 0.46, 0.26)},
	"mountain": {"kinds": [K.HOLM, K.ALEPPO, K.PINE, K.HOLM], "floor": Color(0.30, 0.29, 0.22), "litter": Color(0.44, 0.39, 0.29), "glade": Color(0.50, 0.46, 0.36)},
	"dry": {"kinds": [K.PINE, K.OLIVE, K.HOLM, K.ALEPPO], "floor": Color(0.36, 0.34, 0.21), "litter": Color(0.50, 0.44, 0.27), "glade": Color(0.52, 0.48, 0.30)},
	"snow": {"kinds": [K.SNOW_FIR, K.SNOW_FIR, K.SNOW_FIR, K.FIR], "floor": Color(0.74, 0.80, 0.90), "litter": Color(0.62, 0.70, 0.84), "glade": Color(0.90, 0.94, 0.99)},
}
const WALK_LOOK := {
	"trail": "collserola", "boars": "autumn", "aigues": "collserola", "besos": "river", "horta": "garden",
	"guell": "dry", "vic": "river", "girona": "garden", "montserrat": "mountain", "molina": "snow",
}

static var _stamps := {}
static var _kept := {}


static func look(lvl: String) -> String:
	return String(WALK_LOOK.get(lvl, "collserola"))


static func _h(k: int) -> float:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h ^ (h >> 16)) % 100003) / 100003.0


# one crown of radius `r`
static func crown(b: ShapeBatch, kind: int, p: Vector2, r: float, k: int) -> void:
	var key := kind * 10 + k % SHAPES
	var rec: ShapeBatch = _stamps.get(key)
	if rec == null:
		rec = ShapeBatch.new()
		rec.lod = true
		_build(rec, kind, k % SHAPES)
		_stamps[key] = rec
	# built at a hundred px, so that its discs get the corners they need
	b._points.append_array(Transform2D(0.0, Vector2(r, r) * 0.01, 0.0, p) * rec._points)
	b._colors.append_array(rec._colors)


# a disc of as few corners as it can be without showing them at this size
static func _disc(b: ShapeBatch, p: Vector2, r: float, c: Color) -> void:
	var n := 14 if r > 50.0 else (9 if r > 20.0 else 6)
	var pts := PackedVector2Array()
	for i in range(n):
		pts.append(p + Vector2.from_angle(TAU * (float(i) + 0.5) / float(n)) * r)
	b.polygon(pts, c)


static func _build(b: ShapeBatch, kind: int, v: int) -> void:
	var up := -Shade.light
	var s := kind * 101 + v * 17
	_disc(b, Shade.light * 34.0, 92.0, Color(0.03, 0.06, 0.05, 0.32))
	match kind:
		K.PINE:
			# a stone pine: a flat umbrella, its needles in tufts
			_disc(b, Vector2.ZERO, 92.0, Color(0.15, 0.27, 0.19))
			for i in range(11):
				var a := float(i) * TAU / 11.0 + _h(s) * 6.0
				_disc(b, Vector2.from_angle(a) * 76.0, 24.0, Color(0.17, 0.31, 0.21))
			for i in range(9):
				var q := Vector2.from_angle(float(i) * 2.4 + _h(s + 1) * 6.0) * (18.0 + 6.4 * float(i))
				var lit := clampf(0.5 + q.dot(up) / 150.0, 0.0, 1.0)
				_disc(b, q, 24.0, Color(0.19, 0.35, 0.23).lerp(Color(0.38, 0.55, 0.32), lit))
				_disc(b, q + up * 7.0, 11.0, Color(0.24, 0.42, 0.26).lerp(Color(0.50, 0.66, 0.40), lit))
		K.ALEPPO:
			# loose and yellow-green, the ground showing through
			for i in range(10):
				var q := Vector2.from_angle(float(i) * 2.39 + _h(s) * 6.0) * (12.0 + 7.2 * float(i))
				_disc(b, q, 30.0 - float(i), Color(0.24, 0.35, 0.17))
			for i in range(8):
				var q := Vector2.from_angle(float(i) * 2.39 + _h(s) * 6.0) * (10.0 + 8.0 * float(i)) + up * 7.0
				_disc(b, q, 17.0, Color(0.40, 0.52, 0.24) if i % 2 == 0 else Color(0.34, 0.46, 0.21))
				_disc(b, q + up * 5.0, 8.0, Color(0.56, 0.66, 0.32))
		K.OAK:
			# a downy oak, turning
			var warm := _h(s + 3)
			var base := Color(0.34, 0.31, 0.14).lerp(Color(0.46, 0.28, 0.12), warm)
			_disc(b, Vector2.ZERO, 86.0, base.darkened(0.25))
			for i in range(9):
				var q := Vector2.from_angle(float(i) * TAU / 9.0 + _h(s) * 6.0) * 60.0
				_disc(b, q, 36.0, base)
			for i in range(8):
				var q := Vector2.from_angle(float(i) * 2.4 + _h(s + 5) * 6.0) * (14.0 + 6.5 * float(i)) + up * 12.0
				_disc(b, q, 18.0, base.lerp(Color(0.72, 0.52, 0.20), 0.35 + 0.4 * _h(s + i)))
				_disc(b, q + up * 6.0, 8.0, base.lerp(Color(0.86, 0.68, 0.30), 0.6))
		K.FIR, K.SNOW_FIR:
			var snow := kind == K.SNOW_FIR
			for tier in range(3):
				var tr := 92.0 - 28.0 * float(tier)
				var n := 9 - tier
				for i in range(n):
					var d := Vector2.from_angle(float(i) * TAU / float(n) + float(tier) * 0.4 + _h(s))
					var w := d.orthogonal() * tr * 0.24
					var c := up * 5.0 * float(tier)
					b.polygon(PackedVector2Array([c - w, c + d * tr, c + w]), Color(0.13, 0.27, 0.24).lightened(0.06 * float(tier)))
					if snow:
						b.polygon(PackedVector2Array([c - w * 0.55 + up * 4.0, c + d * tr * 0.84 + up * 4.0, c + w * 0.35 + up * 4.0]),
							Color(0.93, 0.96, 1.0) if (i + tier) % 3 != 0 else Color(0.74, 0.82, 0.92))
			_disc(b, up * 12.0, 15.0, Color(0.97, 0.99, 1.0) if snow else Color(0.30, 0.47, 0.36))
		K.OLIVE:
			for i in range(9):
				var q := Vector2.from_angle(float(i) * 2.4 + _h(s) * 6.0) * (8.0 + 7.5 * float(i))
				_disc(b, q, 28.0, Color(0.32, 0.37, 0.28))
			for i in range(8):
				var q := Vector2.from_angle(float(i) * 2.4 + _h(s) * 6.0) * (8.0 + 7.5 * float(i)) + up * 8.0
				_disc(b, q, 14.0, Color(0.52, 0.57, 0.46) if i % 2 == 0 else Color(0.44, 0.50, 0.38))
		K.CYPRESS:
			_disc(b, Vector2.ZERO, 62.0, Color(0.10, 0.20, 0.15))
			for i in range(7):
				var q := Vector2.from_angle(float(i) * TAU / 7.0 + _h(s)) * 40.0
				_disc(b, q, 22.0, Color(0.14, 0.27, 0.19))
			_disc(b, up * 16.0, 34.0, Color(0.19, 0.34, 0.23))
			_disc(b, up * 26.0, 15.0, Color(0.30, 0.46, 0.30))
		_:
			# a holm oak: dense, dark, its leaves in tight domes
			_disc(b, Vector2.ZERO, 88.0, Color(0.10, 0.19, 0.12))
			for i in range(10):
				var q := Vector2.from_angle(float(i) * TAU / 10.0 + _h(s) * 6.0) * 66.0
				_disc(b, q, 30.0, Color(0.14, 0.25, 0.14))
			for i in range(9):
				var q := Vector2.from_angle(float(i) * 2.4 + _h(s + 2) * 6.0) * (10.0 + 6.6 * float(i)) + up * 8.0
				var lit := clampf(0.45 + q.dot(up) / 130.0, 0.0, 1.0)
				_disc(b, q, 23.0, Color(0.16, 0.29, 0.16).lerp(Color(0.28, 0.43, 0.22), lit))
				_disc(b, q + up * 7.0, 9.0, Color(0.22, 0.37, 0.19).lerp(Color(0.42, 0.56, 0.30), lit))


# the floor under them: litter in drifts, ferns, stones, a lit glade
static func ground(b: ShapeBatch, r: Rect2, name: String, salt: int, per := 5200.0) -> void:
	var lk: Dictionary = LOOKS[name]
	var snow := name == "snow"
	b.rect(r, lk.floor)
	var n := int(r.size.x * r.size.y / (per * 5.0))
	for i in range(n):
		var p := r.position + r.size * Vector2(_h(salt + i * 3), _h(salt + i * 7 + 1))
		var rad := minf(60.0 + 70.0 * _h(salt + i), minf(r.size.x, r.size.y) * 0.5)
		p = p.clamp(r.position + Vector2(rad, rad), r.end - Vector2(rad, rad)) if r.size.x > rad * 2.0 and r.size.y > rad * 2.0 else r.get_center()
		b.glow(p, rad, Color(lk.glade if i % 3 == 0 else lk.litter, 0.55))
	n = int(r.size.x * r.size.y / per)
	for i in range(n):
		var p := r.position + Vector2(8, 8) + (r.size - Vector2(16, 16)) * Vector2(_h(salt + i * 11 + 5), _h(salt + i * 13 + 2))
		match int(_h(salt + i * 5) * 4.0):
			0:
				if not snow:
					for f in range(5):
						b.line(p, p + Vector2.from_angle(-PI * 0.5 + (float(f) - 2.0) * 0.6) * (8.0 + 3.0 * float(f % 2)), Color(0.34, 0.50, 0.24, 0.85), 2.0)
			1:
				b.circle(p + Vector2(2, 3), 5.0, Color(0, 0, 0, 0.2))
				b.circle(p, 4.6, Color(0.52, 0.50, 0.46))
				b.circle(p - Vector2(1.2, 1.4), 2.6, Color(0.68, 0.66, 0.62) if not snow else Color(0.95, 0.97, 1.0))
			_:
				b.ellipse(p, 3.4, 2.2, Color((lk.litter as Color).lightened(0.16), 0.8))


# a clearing's own ground: the grass (or the snow) in soft patches, worn where
# everyone runs, tufts and stones, its edge fraying into the wood's floor
static func clearing(b: ShapeBatch, r: Rect2, name: String) -> void:
	var lk: Dictionary = LOOKS[name]
	var g: Color = lk.glade
	b.rect(r, g)
	var c := r.get_center()
	for i in range(26):
		var rad := 90.0 + 90.0 * _h(i * 3 + 1)
		var p := Vector2(lerpf(r.position.x + rad, r.end.x - rad, _h(i * 7)), lerpf(r.position.y + rad, r.end.y - rad, _h(i * 11 + 3)))
		b.glow(p, rad, Color(g.lightened(0.12) if i % 2 == 0 else g.darkened(0.13), 0.6))
	b.glow(c, 260.0, Color(lk.litter, 0.55), 0.2)
	b.glow(c, 130.0, Color((lk.litter as Color).darkened(0.08), 0.5), 0.2)
	for i in range(int(r.size.x * r.size.y / 5200.0)):
		var p := r.position + Vector2(14, 14) + (r.size - Vector2(28, 28)) * Vector2(_h(i * 5 + 40), _h(i * 9 + 41))
		if name == "snow":
			if i % 3 == 0:
				b.ellipse(p + Vector2(2, 3), 9.0, 4.0, Color(0.62, 0.70, 0.84, 0.5))
				b.ellipse(p, 9.0, 4.0, Color(0.97, 0.99, 1.0))
			continue
		for f in range(3):
			b.line(p + Vector2(2.0 * float(f - 1), 0), p + Vector2(3.4 * float(f - 1), -7.0 - 2.0 * float(f % 2)), g.lightened(0.22) if f == 1 else g.darkened(0.25), 1.6)
		if i % 9 == 0:
			b.circle(p + Vector2(4, -4), 1.8, Color(0.96, 0.92, 0.78) if i % 2 == 0 else Color(0.94, 0.76, 0.34))
	# the wood's floor reaching in along all four sides
	var f: Color = lk.floor
	for e: Array in [[r.position, Vector2(r.end.x, r.position.y), Vector2(0, 54)], [Vector2(r.position.x, r.end.y), r.end, Vector2(0, -34)],
			[r.position, Vector2(r.position.x, r.end.y), Vector2(54, 0)], [Vector2(r.end.x, r.position.y), r.end, Vector2(-54, 0)]]:
		b.band(PackedVector2Array([e[0], e[1], (e[0] as Vector2) + e[2], (e[1] as Vector2) + e[2]]), 2, f, PackedFloat32Array([0.9, 0.0]))


# trees over a rectangle, back to front, leaving `keep` clear (a clearing)
static func trees(b: ShapeBatch, r: Rect2, name: String, salt: int, step := 62.0, keep := Rect2()) -> void:
	var kinds: Array = (LOOKS[name] as Dictionary).kinds
	var row := 0
	var y := r.position.y + step * 0.4
	while y < r.end.y + step * 0.2:
		var x := r.position.x + step * (0.2 + 0.5 * float(row % 2))
		var col := 0
		while x < r.end.x:
			var k := salt * 131 + row * 57 + col * 13
			var p := Vector2(x + (_h(k) - 0.5) * step * 0.7, y + (_h(k + 1) - 0.5) * step * 0.6)
			var rad := step * (0.40 + 0.36 * _h(k + 2))
			# a clump every so often, a gap every so often
			if _h(k + 3) > 0.10 and not (keep.has_area() and keep.grow(rad * 0.75).has_point(p)):
				crown(b, int(kinds[int(_h(k + 4) * float(kinds.size())) % kinds.size()]), p, rad, k)
			x += step
			col += 1
		y += step * 0.82
		row += 1


# One row of a wood along a path's edge, outward from `line`, kept.
static func kept_row(b: ShapeBatch, name: String, line: float, side: float, y: float, step: float, depth: float, salt: int, fade := false) -> void:
	var key := [name, line, side, y, depth, fade]
	var rec: ShapeBatch = _kept.get(key)
	if rec == null:
		if _kept.size() > 220:
			_kept.clear()
		rec = ShapeBatch.new()
		rec.lod = true
		_row(rec, name, line, side, y, step, depth, salt)
		_kept[key] = rec
	rec.append_to(b)


static func _row(b: ShapeBatch, name: String, line: float, side: float, y: float, step: float, depth: float, salt: int) -> void:
	var kinds: Array = (LOOKS[name] as Dictionary).kinds
	var n := int(depth / 64.0)
	for j in range(n):
		var k := salt * 71 + j * 19
		var off := 20.0 + 64.0 * float(j) + 34.0 * _h(k)
		var rad := (26.0 + 22.0 * _h(k + 2)) * (0.82 if j == 0 else 1.0)
		if _h(k + 3) < 0.12 and j > 0:
			continue
		crown(b, int(kinds[int(_h(k + 4) * float(kinds.size())) % kinds.size()]), Vector2(line + side * off, y + step * (0.2 + 0.6 * _h(k + 1))), rad, k)
	# undergrowth along the line itself
	for j in range(3):
		var k := salt * 37 + j * 7
		if _h(k + 5) < 0.42:
			continue
		var p := Vector2(line + side * (24.0 * _h(k) - 8.0), y + step * (_h(k + 6) * 0.3 + 0.33 * float(j)))
		var r := 6.0 + 9.0 * _h(k + 1)
		var c: Color = ((LOOKS[name] as Dictionary).glade as Color).darkened(0.18)
		b.circle(p + Shade.light * 4.0, r, Color(0.03, 0.06, 0.05, 0.28))
		b.circle(p, r, c.darkened(0.15))
		b.circle(p - Shade.light * r * 0.35, r * 0.6, c.lightened(0.10))
		if _h(k + 2) < 0.35 and name != "snow":
			b.circle(p - Shade.light * r * 0.2, 1.8, Color(0.86, 0.34, 0.24))
