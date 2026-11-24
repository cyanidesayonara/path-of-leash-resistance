extends RefCounted

# The clinic round El Veterinari's corridor (systems/vet.gd): the rooms either
# side with their roofs off, everyone in them at work, and what stands in the
# corridor itself. Drawn only: the walls, poles and solids are vet.gd's. The
# rooms are built once each and kept.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const WALL_L := 360.0
const WALL_R := 920.0
const DEPTH := 330.0
const PART := 400.0              # a room's length down the corridor
const TOP := 200.0               # the first room's south end
const SHADE := Color(0.05, 0.08, 0.10, 0.20)
const WALL := Color(0.93, 0.95, 0.94)
const WALL_DK := Color(0.66, 0.73, 0.72)
const TEAL := Color(0.16, 0.56, 0.52)
const STEEL := Color(0.74, 0.78, 0.81)
const STEEL_LIT := Color(0.90, 0.93, 0.95)
const STEEL_DK := Color(0.46, 0.50, 0.54)
const WHITE := Color(0.97, 0.98, 0.98)
const WOOD := Color(0.76, 0.60, 0.42)
const SCRUBS: Array[Color] = [Color(0.16, 0.60, 0.56), Color(0.30, 0.46, 0.74), Color(0.62, 0.36, 0.58)]
const SKIN: Array[Color] = [Color(0.94, 0.78, 0.64), Color(0.74, 0.54, 0.40), Color(0.52, 0.36, 0.26), Color(0.88, 0.70, 0.54)]
const HAIR: Array[Color] = [Color(0.20, 0.14, 0.10), Color(0.48, 0.30, 0.16), Color(0.72, 0.56, 0.30), Color(0.40, 0.40, 0.42)]
const FUR: Array[Color] = [Color(0.62, 0.42, 0.24), Color(0.26, 0.24, 0.24), Color(0.90, 0.84, 0.74), Color(0.76, 0.56, 0.32), Color(0.52, 0.50, 0.48)]

# what each room is, from the street end; west then east. The doors in vet.gd
# open into the rooms that bear their names.
const WEST := ["shop", "bath", "kennels", "consult", "cats", "xray", "office", "pharmacy", "kennels", "surgery", "staff", "store", "laundry"]
const EAST := ["waiting", "consult", "cats", "store", "consult", "bath", "lab", "pharmacy", "kennels", "quarantine", "cats", "staff", "laundry"]

static var _kept := {}


static func _h(k: int) -> float:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h ^ (h >> 16)) % 100003) / 100003.0


static func draw(b: ShapeBatch, vt: float, vb: float, north: float) -> void:
	# from the street door in: the last of the shop and the waiting room first
	for i in range(-1, WEST.size()):
		var y1 := TOP - PART * float(i) if i >= 0 else TOP + 260.0
		var y0 := maxf(TOP - PART * float(i + 1), north)
		if y0 > vb + 20.0 or y1 < vt - 20.0 or y1 - y0 < 60.0:
			continue
		for side: float in [-1.0, 1.0]:
			var key := [i, side, y0]
			var rec: ShapeBatch = _kept.get(key)
			if rec == null:
				rec = ShapeBatch.new()
				rec.lod = true
				_room(rec, (WEST if side < 0.0 else EAST)[maxi(i, 0)], side, y0, y1, i * 37 + (5 if side > 0.0 else 0))
				_kept[key] = rec
			rec.append_to(b)


# `at(u, v)` is a place in the room: u out from the corridor wall (0..1), v
# down it (0..1), whichever side it is on
static func _room(b: ShapeBatch, what: String, side: float, y0: float, y1: float, k: int) -> void:
	var w := WALL_L - 10.0 if side < 0.0 else WALL_R + 10.0
	var far := w + side * DEPTH
	var r := Rect2(minf(w, far), y0 + 9.0, DEPTH, y1 - y0 - 18.0)
	# outside: the clinic's yard wall and the street behind, dim
	b.rect(Rect2(minf(far, far + side * 520.0), y0, 520.0, y1 - y0), Color(0.40, 0.44, 0.40))
	b.rect(Rect2(minf(far + side * 12.0, far + side * 70.0), y0, 58.0, y1 - y0), Color(0.34, 0.46, 0.30))
	var hy := y0 + 18.0
	while hy < y1:
		b.circle(Vector2(far + side * 42.0, hy), 20.0, Color(0.26, 0.40, 0.25))
		b.circle(Vector2(far + side * 38.0, hy - 4.0), 10.0, Color(0.40, 0.55, 0.33))
		hy += 34.0
	b.rect(Rect2(minf(far + side * 70.0, far + side * 520.0), y0, 450.0, y1 - y0), Color(0.30, 0.31, 0.33))
	# the floor, by the room
	var floor_c: Color = {"shop": Color(0.86, 0.82, 0.72), "waiting": Color(0.84, 0.82, 0.76), "kennels": Color(0.70, 0.74, 0.72), "cats": Color(0.82, 0.80, 0.86),
		"surgery": Color(0.70, 0.84, 0.84), "xray": Color(0.62, 0.66, 0.72), "bath": Color(0.74, 0.86, 0.90), "staff": Color(0.82, 0.72, 0.58),
		"quarantine": Color(0.90, 0.84, 0.62), "office": Color(0.80, 0.72, 0.60)}.get(what, Color(0.84, 0.88, 0.88))
	b.rect(r, floor_c)
	var ty := r.position.y + 36.0
	while ty < r.end.y:
		b.line(Vector2(r.position.x, ty), Vector2(r.end.x, ty), floor_c.darkened(0.08), 1.2)
		ty += 36.0
	var tx := r.position.x + 36.0
	while tx < r.end.x:
		b.line(Vector2(tx, r.position.y), Vector2(tx, r.end.y), floor_c.darkened(0.08), 1.2)
		tx += 36.0
	b.glow(r.get_center(), 190.0, Color(1.0, 0.99, 0.94, 0.30))
	var at := func(u: float, v: float) -> Vector2: return Vector2(w + side * u * DEPTH, lerpf(r.position.y, r.end.y, v))
	match what:
		"consult":
			_table(b, at.call(0.42, 0.5), k)
			_person(b, at.call(0.42, 0.5) + Vector2(0, -44), Vector2.DOWN, k, 0)
			_person(b, at.call(0.42, 0.5) + Vector2(-34, 40), Vector2.UP, k + 3, -1)
			_counter(b, Rect2(at.call(0.90 if side > 0.0 else 1.0, 0.10), Vector2(33, 220)), k)
			_desk(b, at.call(0.50, 0.12), k)
			_lamp(b, at.call(0.42, 0.5) + Vector2(30, -20))
			_plant(b, at.call(0.12, 0.92))
		"surgery":
			_table(b, at.call(0.45, 0.46), k)
			for q: Array in [[Vector2(0, -44), Vector2.DOWN], [Vector2(0, 44), Vector2.UP], [Vector2(58, 0), Vector2.LEFT]]:
				_person(b, at.call(0.45, 0.46) + q[0], q[1], k + int((q[0] as Vector2).y), 0, true)
			_lamp(b, at.call(0.45, 0.46) + Vector2(-6, -6), 26.0)
			_cart(b, at.call(0.74, 0.40))
			_cart(b, at.call(0.20, 0.30))
			_counter(b, Rect2(at.call(0.90 if side > 0.0 else 1.0, 0.08), Vector2(33, 260)), k)
		"xray":
			_table(b, at.call(0.45, 0.45), k)
			b.rect(Rect2(at.call(0.45, 0.45) - Vector2(16, 60), Vector2(32, 34)), STEEL_DK)
			b.rect(Rect2(at.call(0.45, 0.45) - Vector2(13, 57), Vector2(26, 24)), STEEL)
			b.circle(at.call(0.45, 0.45) - Vector2(0, 30), 11.0, Color(0.20, 0.26, 0.34))
			# the films up on the light box: somebody swallowed a ball
			for q in range(3):
				var f := Rect2(at.call(0.5, 0.0) + Vector2(-70.0 + 48.0 * float(q), 8.0), Vector2(40, 26))
				b.rect(f.grow(2.0), STEEL_DK)
				b.rect(f, Color(0.12, 0.20, 0.30))
				b.capsule(f.position + Vector2(9, 13), f.position + Vector2(31, 13), 2.2, Color(0.80, 0.90, 0.98))
				for n in range(4):
					b.line(f.position + Vector2(12.0 + 5.0 * float(n), 7.0), f.position + Vector2(12.0 + 5.0 * float(n), 19.0), Color(0.72, 0.84, 0.94), 1.4)
				if q == 1:
					b.circle(f.position + Vector2(22, 16), 5.0, Color(0.95, 0.98, 1.0))
			_person(b, at.call(0.16, 0.80), Vector2(0, -1), k, 1)
			_desk(b, at.call(0.20, 0.70), k)
		"kennels":
			# a run either side, a dog in most of them
			for row in range(2):
				for q in range(4):
					var c := Rect2(at.call(0.5, 0.0).x - 140.0 + 72.0 * float(q), lerpf(r.position.y, r.end.y, 0.03 + 0.66 * float(row)), 66.0, 100.0)
					b.rect(c, Color(0.58, 0.63, 0.62))
					b.rect(Rect2(c.position + Vector2(8, 60 if row == 0 else 8), Vector2(50, 32)), [Color(0.72, 0.42, 0.40), Color(0.42, 0.52, 0.66), Color(0.74, 0.66, 0.42)][(q + row) % 3])
					b.circle(c.position + Vector2(52, 14 if row == 0 else 88), 6.0, Color(0.30, 0.52, 0.70))
					if _h(k + q * 7 + row) < 0.8:
						_dog(b, c.position + Vector2(33, 74 if row == 0 else 26), Vector2(0.3, 1.0 if row == 0 else -1.0).normalized(), k + q * 3 + row, _h(k + q + row * 5) < 0.5)
					var gy := c.end.y if row == 0 else c.position.y
					b.line(Vector2(c.position.x, gy), Vector2(c.end.x, gy), STEEL_DK, 4.0)
					for n in range(8):
						b.circle(Vector2(c.position.x + 5.0 + 8.0 * float(n), gy), 2.0, STEEL_LIT)
					b.rect(Rect2(c.end.x, c.position.y, 6.0, c.size.y), WALL_DK)
			_person(b, at.call(0.5, 0.5), Vector2(-side, 0), k, 2)
			b.circle(at.call(0.7, 0.52), 12.0, Color(0.36, 0.52, 0.66))
			b.circle(at.call(0.7, 0.52), 9.0, Color(0.70, 0.84, 0.92))
		"cats":
			# a wall of cages, a tower, and their eyes
			for q in range(6):
				var c := Rect2(at.call(0.97 if side < 0.0 else 0.84, 0.04 + 0.15 * float(q)), Vector2(42, 48))
				b.rect(c, STEEL_DK)
				b.rect(c.grow(-3.0), Color(0.30, 0.30, 0.36))
				if _h(k + q) < 0.75:
					_cat(b, c.get_center(), k + q)
				for n in range(5):
					b.line(c.position + Vector2(6.0 + 7.5 * float(n), 2), c.position + Vector2(6.0 + 7.5 * float(n), 46), Color(STEEL_LIT, 0.8), 1.2)
			var t: Vector2 = at.call(0.40, 0.34)
			b.circle(t + Vector2(5, 8), 34.0, SHADE)
			b.circle(t, 32.0, Color(0.72, 0.60, 0.46))
			b.circle(t, 24.0, Color(0.82, 0.72, 0.58))
			b.circle(t + Vector2(14, -10), 15.0, Color(0.66, 0.52, 0.38))
			_cat(b, t + Vector2(12, -10), k + 9)
			_cat(b, at.call(0.36, 0.72), k + 12)
			b.circle(at.call(0.20, 0.60), 6.0, Color(0.86, 0.36, 0.42))
			b.line(at.call(0.20, 0.60), at.call(0.30, 0.64), Color(0.86, 0.36, 0.42), 1.6)
		"bath":
			var t: Vector2 = at.call(0.45, 0.45)
			b.polygon(_round(Rect2(t - Vector2(60, 34) + Vector2(5, 8), Vector2(120, 68)), 22.0), SHADE)
			b.polygon(_round(Rect2(t - Vector2(60, 34), Vector2(120, 68)), 22.0), WHITE)
			b.polygon(_round(Rect2(t - Vector2(52, 26), Vector2(104, 52)), 18.0), Color(0.56, 0.78, 0.88))
			_dog(b, t, Vector2(1, 0), k, false)
			for q in range(16):
				var p := t + Vector2((_h(k + q) - 0.5) * 92.0, (_h(k + q * 3) - 0.5) * 42.0)
				b.circle(p, 4.0 + 5.0 * _h(q), Color(0.96, 0.98, 1.0, 0.92))
			_person(b, t + Vector2(0, -50), Vector2.DOWN, k, 1)
			_counter(b, Rect2(at.call(0.90 if side > 0.0 else 1.0, 0.10), Vector2(33, 200)), k)
			for q in range(3):
				b.polygon(_round(Rect2(at.call(0.15, 0.80) + Vector2(0, 16.0 * float(q) - 16.0), Vector2(44, 13)), 4.0), [Color(0.92, 0.50, 0.46), Color(0.50, 0.70, 0.86), Color(0.96, 0.86, 0.56)][q])
		"shop", "pharmacy", "store":
			var food := what != "pharmacy"
			for s in range(3):
				var sh := Rect2(at.call(0.5, 0.0).x - 130.0, lerpf(r.position.y, r.end.y, 0.10 + 0.30 * float(s)), 260.0, 40.0)
				b.rect(Rect2(sh.position + Vector2(5, 8), sh.size), SHADE)
				b.rect(sh, WOOD.darkened(0.15) if food else WHITE.darkened(0.12))
				b.rect(sh.grow(-3.0), WOOD if food else WHITE)
				var x := sh.position.x + 8.0
				var q := 0
				while x < sh.end.x - 22.0:
					var col: Color = [Color(0.82, 0.28, 0.26), Color(0.24, 0.46, 0.66), Color(0.92, 0.74, 0.26), Color(0.34, 0.58, 0.40), Color(0.60, 0.38, 0.62)][int(_h(k + s * 11 + q) * 5.0) % 5]
					if food:
						b.polygon(_round(Rect2(x, sh.position.y + 6.0, 22, 28), 4.0), col)
						b.rect(Rect2(x + 4.0, sh.position.y + 13.0, 14, 10), WHITE)
						b.circle(Vector2(x + 11.0, sh.position.y + 18.0), 3.0, col.darkened(0.3))
						x += 27.0
					else:
						for n in range(2):
							b.circle(Vector2(x + 5.0, sh.position.y + 12.0 + 16.0 * float(n)), 5.0, col)
							b.circle(Vector2(x + 5.0, sh.position.y + 12.0 + 16.0 * float(n)), 2.6, WHITE)
						x += 14.0
					q += 1
			_person(b, at.call(0.30, 0.94 if food else 0.90), Vector2(0, -1), k, -1 if food else 1)
		"waiting":
			b.polygon(_round(Rect2(at.call(0.5, 0.5) - Vector2(96, 90), Vector2(192, 180)), 26.0), Color(0.36, 0.58, 0.58))
			b.polygon(_round(Rect2(at.call(0.5, 0.5) - Vector2(86, 80), Vector2(172, 160)), 22.0), Color(0.46, 0.68, 0.66))
			b.circle(at.call(0.5, 0.5), 26.0, WOOD.darkened(0.2))
			b.circle(at.call(0.5, 0.5), 23.0, WOOD)
			b.rect(Rect2(at.call(0.5, 0.5) - Vector2(12, 8), Vector2(16, 12)), Color(0.86, 0.40, 0.36))
			for q in range(4):
				var d := Vector2.from_angle(TAU * float(q) / 4.0 + 0.4)
				var p: Vector2 = at.call(0.5, 0.5) + d * 70.0
				b.polygon(_round(Rect2(p - Vector2(20, 20), Vector2(40, 40)), 10.0), [Color(0.24, 0.46, 0.70), Color(0.88, 0.50, 0.26)][q % 2])
				if q != 2:
					_person(b, p, -d, k + q * 5, -1)
			_dog(b, at.call(0.5, 0.5) + Vector2(-46, 62), Vector2(1, -0.4).normalized(), k, true)
			_plant(b, at.call(0.90, 0.10))
			_plant(b, at.call(0.90, 0.90))
		"lab":
			_counter(b, Rect2(at.call(0.90 if side > 0.0 else 1.0, 0.06), Vector2(33, 300)), k)
			var ct := Rect2(at.call(0.5, 0.2) - Vector2(70, 0), Vector2(140, 44))
			b.rect(Rect2(ct.position + Vector2(5, 8), ct.size), SHADE)
			b.rect(ct, WHITE)
			for q in range(8):
				b.circle(ct.position + Vector2(14.0 + 16.0 * float(q), 14), 4.6, [Color(0.86, 0.30, 0.34), Color(0.96, 0.82, 0.36), Color(0.44, 0.70, 0.86)][q % 3])
			b.circle(ct.position + Vector2(110, 30), 10.0, Color(0.22, 0.24, 0.28))
			b.line(ct.position + Vector2(110, 30), ct.position + Vector2(122, 16), STEEL_DK, 4.0)
			_person(b, at.call(0.5, 0.2) + Vector2(30, 64), Vector2.UP, k, 1)
			_desk(b, at.call(0.35, 0.75), k)
		"quarantine":
			for q in range(5):
				var p0: Vector2 = at.call(0.02, 0.1 + 0.18 * float(q))
				b.polygon(PackedVector2Array([p0, p0 + Vector2(side * 18, 0), p0 + Vector2(side * 30, 18), p0 + Vector2(side * 12, 18)]), Color(0.16, 0.16, 0.18))
			var c := Rect2(at.call(0.5, 0.4) - Vector2(70, 60), Vector2(140, 120))
			b.polygon(_round(c, 12.0), Color(0.68, 0.84, 0.92, 0.75))
			b.polygon(_round(c.grow(-8.0), 10.0), Color(0.82, 0.92, 0.96, 0.75))
			_dog(b, c.get_center(), Vector2(0.4, 0.9).normalized(), k, false)
			b.circle(c.get_center() + Vector2(4, 16), 14.0, Color(0.92, 0.95, 0.98, 0.7))
			_person(b, at.call(0.5, 0.74), Vector2.UP, k, 0, true)
		"office", "staff":
			_desk(b, at.call(0.45, 0.25), k)
			_person(b, at.call(0.45, 0.25) + Vector2(0, 40), Vector2.UP, k, 2)
			var so: Rect2 = Rect2(at.call(0.5, 0.75) - Vector2(70, 22), Vector2(140, 44))
			b.polygon(_round(Rect2(so.position + Vector2(5, 8), so.size), 12.0), SHADE)
			b.polygon(_round(so, 12.0), Color(0.62, 0.34, 0.32))
			for q in range(2):
				b.polygon(_round(Rect2(so.position + Vector2(8.0 + 64.0 * float(q), 12), Vector2(58, 28)), 8.0), Color(0.74, 0.44, 0.40))
			if what == "staff":
				_person(b, so.get_center() + Vector2(-30, 6), Vector2.DOWN, k + 6, 0)
			_cat(b, so.get_center() + Vector2(34, 4), k)
			_plant(b, at.call(0.88, 0.12))
			_plant(b, at.call(0.10, 0.90))
		_:
			for q in range(3):
				var mc := Rect2(at.call(0.5, 0.06) + Vector2(-100.0 + 70.0 * float(q), 0), Vector2(60, 58))
				b.polygon(_round(Rect2(mc.position + Vector2(5, 8), mc.size), 6.0), SHADE)
				b.polygon(_round(mc, 6.0), WHITE)
				b.circle(mc.get_center() + Vector2(0, 4), 20.0, STEEL_DK)
				b.circle(mc.get_center() + Vector2(0, 4), 16.0, Color(0.56, 0.76, 0.86))
				b.circle(mc.get_center() + Vector2(3, 6), 7.0, [Color(0.92, 0.92, 0.9), Color(0.86, 0.56, 0.5), Color(0.5, 0.66, 0.8)][q])
			for q in range(5):
				b.polygon(_round(Rect2(at.call(0.5, 0.6) + Vector2(-80, 14.0 * float(q)), Vector2(120, 12)), 4.0), [Color(0.92, 0.50, 0.46), Color(0.50, 0.70, 0.86), Color(0.96, 0.86, 0.56), Color(0.56, 0.74, 0.60), Color(0.80, 0.80, 0.84)][q])
	_walls(b, r, w, far, side, y0, y1)


# the partition walls, thick and lit along their tops, their shade on the floor
static func _walls(b: ShapeBatch, r: Rect2, w: float, far: float, side: float, y0: float, y1: float) -> void:
	b.rect(Rect2(r.position, Vector2(r.size.x, 14.0)), SHADE)
	b.rect(Rect2(r.position, Vector2(10.0, r.size.y)), SHADE)
	var x0 := minf(w, far)
	for y: float in [y0, y1]:
		b.rect(Rect2(x0 - 6.0, y - 9.0, DEPTH + 12.0, 18.0), WALL_DK)
		b.rect(Rect2(x0 - 6.0, y - 8.0, DEPTH + 12.0, 12.0), WALL)
	# the corridor's wall is the thick one, and the outside one
	for x: float in [w, far]:
		b.rect(Rect2(x - 10.0, y0, 20.0, y1 - y0), WALL_DK)
		b.rect(Rect2(x - 9.0, y0, 14.0, y1 - y0), WALL)
	# a window in the outside wall, daylight coming in
	for v: float in [0.3, 0.7]:
		var yy := lerpf(y0, y1, v)
		b.rect(Rect2(far - 8.0, yy - 34.0, 16.0, 68.0), Color(0.58, 0.78, 0.88))
		b.line(Vector2(far, yy - 34.0), Vector2(far, yy + 34.0), WHITE, 2.0)
		b.band(PackedVector2Array([Vector2(far - side * 8.0, yy - 32.0), Vector2(far - side * 8.0, yy + 32.0), Vector2(far - side * 120.0, yy - 10.0), Vector2(far - side * 120.0, yy + 70.0)]),
			2, Color(1.0, 0.97, 0.84), PackedFloat32Array([0.34, 0.0]))


static func _round(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var k := minf(rad, minf(r.size.x, r.size.y) * 0.5)
	for c: Array in [[Vector2(r.end.x - k, r.position.y + k), -PI * 0.5], [r.end - Vector2(k, k), 0.0], [Vector2(r.position.x + k, r.end.y - k), PI * 0.5], [r.position + Vector2(k, k), PI]]:
		for s in range(4):
			pts.append((c[0] as Vector2) + Vector2.from_angle(float(c[1]) + float(s) * PI / 6.0) * k)
	return pts


# --- people and patients ------------------------------------------------------------

# `staff` picks the scrubs, -1 is somebody's owner; `cap` is for theatre
static func _person(b: ShapeBatch, p: Vector2, face: Vector2, k: int, staff: int, cap := false) -> void:
	var s := face.orthogonal()
	var shirt: Color = SCRUBS[staff % SCRUBS.size()] if staff >= 0 else [Color(0.80, 0.40, 0.34), Color(0.36, 0.50, 0.72), Color(0.90, 0.78, 0.46), Color(0.46, 0.56, 0.44)][absi(k) % 4]
	var skin: Color = SKIN[int(_h(k + 1) * 4.0) % 4]
	b.ellipse(p + Vector2(4, 6), 17.0, 13.0, SHADE)
	for sd: float in [-1.0, 1.0]:
		b.capsule(p + s * sd * 13.0, p + s * sd * 9.0 + face * 15.0, 4.2, shirt.darkened(0.12))
		b.circle(p + s * sd * 8.0 + face * 18.0, 3.8, skin)
	b.capsule(p - s * 10.0, p + s * 10.0, 8.5, shirt)
	b.circle(p + face * 2.0, 9.0, skin)
	if cap:
		b.circle(p, 9.4, Color(0.42, 0.72, 0.74))
		b.circle(p - Vector2(2, 2), 5.0, Color(0.56, 0.82, 0.83))
	else:
		var hair: Color = HAIR[int(_h(k + 2) * 4.0) % 4]
		b.circle(p - face * 2.0, 8.8, hair)
		b.circle(p - face * 2.0 - Vector2(2, 2.4), 4.2, hair.lightened(0.14))


static func _dog(b: ShapeBatch, p: Vector2, face: Vector2, k: int, lying: bool) -> void:
	var fur: Color = FUR[int(_h(k + 4) * 5.0) % 5]
	var s := face.orthogonal()
	b.ellipse(p + Vector2(4, 6), 18.0, 12.0, SHADE)
	b.capsule(p - face * 18.0, p - face * 28.0 + s * 6.0, 2.6, fur.darkened(0.15))
	for e: float in [-1.0, 1.0]:
		for q: float in [-12.0, 10.0]:
			b.circle(p + face * q + s * e * (9.0 if not lying else 12.0), 4.2, fur.darkened(0.2))
	b.capsule(p - face * 12.0, p + face * 10.0, 9.5, fur)
	b.capsule(p - face * 10.0 - Vector2(2, 3), p + face * 6.0 - Vector2(2, 3), 4.0, fur.lightened(0.14))
	var hd := p + face * 21.0
	b.circle(hd, 8.0, fur)
	b.circle(hd + face * 7.0, 4.6, fur.lightened(0.10))
	b.circle(hd + face * 10.5, 2.2, Color(0.12, 0.10, 0.10))
	for e: float in [-1.0, 1.0]:
		b.circle(hd + s * e * 7.0 - face * 2.0, 4.2, fur.darkened(0.28))


static func _cat(b: ShapeBatch, p: Vector2, k: int) -> void:
	var fur: Color = FUR[int(_h(k + 8) * 5.0) % 5]
	b.ellipse(p + Vector2(2, 4), 12.0, 10.0, SHADE)
	b.circle(p, 11.0, fur)
	b.arc(p, 12.0, 0.4, 2.8, 8, fur.darkened(0.2), 4.5)
	var hd := p + Vector2(-5, -6)
	b.circle(hd, 6.6, fur.lightened(0.06))
	for e: float in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([hd + Vector2(e * 6.0, -3), hd + Vector2(e * 5.0, -10), hd + Vector2(e * 1.0, -6)]), fur.darkened(0.15))
		b.circle(hd + Vector2(e * 2.4, 0), 1.2, Color(0.94, 0.86, 0.24))


# --- furniture -----------------------------------------------------------------------

static func _table(b: ShapeBatch, p: Vector2, k: int) -> void:
	b.polygon(_round(Rect2(p - Vector2(46, 25) + Vector2(5, 9), Vector2(92, 50)), 8.0), SHADE)
	b.polygon(_round(Rect2(p - Vector2(46, 25), Vector2(92, 50)), 8.0), STEEL_DK)
	b.polygon(_round(Rect2(p - Vector2(43, 22), Vector2(86, 43)), 6.0), STEEL)
	b.polygon(_round(Rect2(p - Vector2(40, 20), Vector2(46, 14)), 4.0), STEEL_LIT)
	_dog(b, p, Vector2(1, 0) if _h(k) < 0.5 else Vector2(-1, 0), k, true)


static func _lamp(b: ShapeBatch, p: Vector2, r := 16.0) -> void:
	b.glow(p, r * 4.2, Color(1.0, 1.0, 0.94, 0.5))
	b.line(p, p + Vector2(34, -40), STEEL_DK, 4.0)
	b.circle(p, r, Color(STEEL, 0.75))
	b.circle(p, r * 0.75, Color(1.0, 1.0, 0.96, 0.8))


static func _counter(b: ShapeBatch, r: Rect2, k: int) -> void:
	b.rect(Rect2(r.position + Vector2(4, 6), r.size), SHADE)
	b.rect(r, TEAL.darkened(0.25))
	b.rect(Rect2(r.position, r.size - Vector2(4, 0)), WHITE)
	var y := r.position.y + 16.0
	var i := 0
	while y < r.end.y - 22.0:
		match int(_h(k + i) * 4.0):
			0:
				b.polygon(_round(Rect2(r.position.x + 5, y - 8, 20, 26), 5.0), STEEL_DK)
				b.polygon(_round(Rect2(r.position.x + 8, y - 5, 14, 20), 4.0), Color(0.60, 0.80, 0.88))
			1:
				for q in range(3):
					b.circle(Vector2(r.position.x + 15.0, y - 6.0 + 10.0 * float(q)), 4.6, [Color(0.86, 0.56, 0.20), WHITE.darkened(0.15), Color(0.26, 0.50, 0.78)][q])
			2:
				b.rect(Rect2(r.position.x + 6, y - 6, 18, 14), Color(0.20, 0.22, 0.26))
				b.rect(Rect2(r.position.x + 8, y - 4, 14, 10), Color(0.36, 0.62, 0.72))
			_:
				b.rect(Rect2(r.position.x + 7, y - 4, 16, 18), Color(0.94, 0.90, 0.78))
		y += 42.0
		i += 1


static func _desk(b: ShapeBatch, p: Vector2, k: int) -> void:
	b.rect(Rect2(p - Vector2(44, 18) + Vector2(4, 7), Vector2(88, 36)), SHADE)
	b.rect(Rect2(p - Vector2(44, 18), Vector2(88, 36)), WOOD.darkened(0.2))
	b.rect(Rect2(p - Vector2(42, 17), Vector2(84, 30)), WOOD)
	b.rect(Rect2(p - Vector2(18, 15), Vector2(36, 7)), Color(0.16, 0.17, 0.20))
	b.rect(Rect2(p - Vector2(14, 4), Vector2(28, 9)), Color(0.84, 0.85, 0.87))
	b.rect(Rect2(p + Vector2(22, -10), Vector2(14, 18)), Color(0.98, 0.97, 0.92))
	b.circle(p + Vector2(-32, -4), 4.6, [Color(0.80, 0.30, 0.30), Color(0.28, 0.46, 0.66)][absi(k) % 2])
	b.circle(p + Vector2(-32, -4), 3.0, Color(0.30, 0.18, 0.12))


static func _cart(b: ShapeBatch, p: Vector2) -> void:
	b.rect(Rect2(p - Vector2(15, 22) + Vector2(4, 6), Vector2(30, 44)), SHADE)
	b.rect(Rect2(p - Vector2(15, 22), Vector2(30, 44)), STEEL_DK)
	b.rect(Rect2(p - Vector2(13, 20), Vector2(26, 40)), STEEL_LIT)
	for q in range(4):
		b.line(p + Vector2(-9, -14.0 + 9.0 * float(q)), p + Vector2(8, -14.0 + 9.0 * float(q)), STEEL_DK, 1.8)


static func _plant(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(4, 7), 15.0, SHADE)
	b.circle(p, 11.0, Color(0.86, 0.84, 0.80))
	for q in range(8):
		var d := Vector2.from_angle(float(q) * TAU / 8.0 + 0.3)
		b.polygon(PackedVector2Array([p, p + d * 11.0 + d.orthogonal() * 4.5, p + d * 22.0, p + d * 11.0 - d.orthogonal() * 4.5]), Color(0.24, 0.48, 0.28) if q % 2 == 0 else Color(0.34, 0.58, 0.34))


# --- the corridor ----------------------------------------------------------------------

# The floor: vinyl in big tiles, a coloured line of paws to each room, the
# pools of the ceiling lights. `top` down to `vb`.
static func floor(b: ShapeBatch, top: float, vb: float) -> void:
	b.rect(Rect2(WALL_L, top, WALL_R - WALL_L, vb - top), Color(0.70, 0.77, 0.76))
	var y := floorf(top / 40.0) * 40.0
	while y < vb:
		var y0 := maxf(y, top)
		var row := int(absf(y) / 40.0)
		for i in range(14):
			var h := _h(row * 31 + i * 7)
			var c := Color(0.84, 0.89, 0.88).lerp(Color(0.77, 0.84, 0.83), h * 0.7)
			b.rect(Rect2(WALL_L + 40.0 * float(i), y0, 39.2, y + 39.2 - y0), c)
		y += 40.0
	# the three ways: teal to the consultations, blue to the wards, coral to theatre
	for q in range(3):
		var x := 596.0 + 44.0 * float(q)
		var col: Color = [Color(0.20, 0.62, 0.58), Color(0.32, 0.50, 0.78), Color(0.90, 0.46, 0.40)][q]
		b.rect(Rect2(x - 3.0, top, 6.0, vb - top), Color(col, 0.42))
		var py := floorf(top / 150.0) * 150.0 + 50.0 * float(q)
		while py < vb:
			if py > top:
				b.circle(Vector2(x, py), 13.0, Color(0.84, 0.89, 0.88))
				b.ellipse(Vector2(x, py + 3.0), 5.4, 4.4, col)
				for t in range(4):
					b.circle(Vector2(x, py + 2.0) + Vector2.from_angle(-PI * 0.5 + (float(t) - 1.5) * 0.62) * 8.4, 2.3, col)
			py += 150.0
	# the ceiling lights, in the shine of the floor
	var ly := floorf(top / 320.0) * 320.0
	while ly < vb + 100.0:
		if ly > top + 60.0:
			for x: float in [500.0, 780.0]:
				b.glow(Vector2(x, ly), 110.0, Color(1.0, 1.0, 0.97, 0.42))
				b.polygon(_round(Rect2(x - 16.0, ly - 46.0, 32.0, 92.0), 10.0), Color(1, 1, 1, 0.26))
		ly += 320.0
	# the skirting and its shade
	for side: float in [-1.0, 1.0]:
		var e := WALL_L if side < 0.0 else WALL_R
		b.rect(Rect2(minf(e, e - side * 14.0), top, 14.0, vb - top), SHADE)
		b.rect(Rect2(minf(e, e - side * 6.0), top, 6.0, vb - top), TEAL)
		b.rect(Rect2(minf(e - side * 6.0, e - side * 8.0), top, 2.0, vb - top), TEAL.lightened(0.35))


# a drip stand from above: five castors, the pole, the hook and its two bags
static func drip(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(5, 8), 15.0, SHADE)
	for q in range(5):
		var d := Vector2.from_angle(float(q) * TAU / 5.0 - 0.4)
		b.line(p, p + d * 15.0, STEEL_DK, 4.0)
		b.circle(p + d * 15.0, 3.4, Color(0.16, 0.17, 0.20))
	b.circle(p, 7.5, STEEL_DK)
	b.circle(p - Vector2(1, 1), 5.4, STEEL_LIT)
	b.line(p - Vector2(13, 0), p + Vector2(13, 0), STEEL, 3.0)
	for sd: float in [-1.0, 1.0]:
		b.polygon(_round(Rect2(p + Vector2(sd * 14.0 - 5.0, -8.0), Vector2(10, 17)), 4.0), Color(0.80, 0.92, 0.96))
		b.rect(Rect2(p + Vector2(sd * 14.0 - 3.6, 0.0), Vector2(7.2, 7.0)), Color(0.60, 0.80, 0.88) if sd < 0.0 else Color(0.94, 0.72, 0.50))


# a pair of waiting chairs against the wall, someone's magazine on one
static func chairs(b: ShapeBatch, p: Vector2) -> void:
	var side := -1.0 if p.x < 640.0 else 1.0
	b.polygon(_round(Rect2(p - Vector2(18, 34) + Vector2(4, 7), Vector2(36, 68)), 8.0), SHADE)
	b.rect(Rect2(p.x - 3.0, p.y - 34.0, 6.0, 68.0), STEEL_DK)
	for q in range(2):
		var c := p + Vector2(0.0, -17.0 + 34.0 * float(q))
		var col: Color = [Color(0.22, 0.46, 0.72), Color(0.90, 0.50, 0.24)][q]
		b.polygon(_round(Rect2(c - Vector2(15, 15), Vector2(30, 30)), 8.0), col)
		b.polygon(_round(Rect2(c - Vector2(11 + side * 2.0, 11), Vector2(22, 22)), 6.0), col.lightened(0.16))
		b.polygon(_round(Rect2(c.x + side * 10.0 - 4.0, c.y - 15.0, 8.0, 30.0), 4.0), col.darkened(0.22))
	b.rect(Rect2(p + Vector2(-8, 10), Vector2(13, 10)), Color(0.95, 0.94, 0.90))
	b.rect(Rect2(p + Vector2(-6, 12), Vector2(9, 4)), Color(0.80, 0.34, 0.40))


static func bin(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(4, 6), 13.0, SHADE)
	b.polygon(_round(Rect2(p - Vector2(12, 12), Vector2(24, 24)), 6.0), STEEL_DK)
	b.polygon(_round(Rect2(p - Vector2(11, 11), Vector2(22, 20)), 5.0), Color(0.96, 0.82, 0.24))
	b.circle(p - Vector2(0, 1), 4.6, Color(0.20, 0.20, 0.22))
	b.rect(Rect2(p + Vector2(-4, 11), Vector2(8, 4)), Color(0.20, 0.20, 0.22))
