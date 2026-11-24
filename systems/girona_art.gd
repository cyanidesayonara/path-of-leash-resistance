extends RefCounted

# What stands round Girona's path (systems/girona.gd): the Onyar and its
# painted houses, the old town's roofs, the Basílica, the city walls and their
# gardens, and the stone the path itself is laid in. Drawn only: the walk's
# edges, solids and surfaces are girona.gd's, and nothing here moves.
#
# Everything is cached by girona.gd, a region at a time. A roof is tiles on two
# slopes with the light on one; a facade is a strip of the house's own front
# along the path or the water, with its shutters, balconies and flowers; and
# every house on the river lays its colour in the water in front of it.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const FAR_L := -320.0
const FAR_R := 1600.0
const START := 260.0
const SOUTH := START + 760.0
const RAMBLA_END := -720.0
const BRIDGE_Y0 := -940.0
const BRIDGE_Y1 := -1560.0
const PLACA_Y0 := -2780.0
const PLACA_Y1 := -3820.0
const GATE := -5000.0

# the river along the Rambla, between its west bank's houses and the quay
const RIVER_W := 176.0
const QUAY_X := 372.0
# the river below the square, between its far bank and the parapet
const FELIU_W := 56.0
const FELIU_E := 310.0
const ROW := 104.0               # how deep a house on the river is

const WATER := Color(0.18, 0.31, 0.36)
const WATER_LIT := Color(0.36, 0.50, 0.55)
const WATER_DK := Color(0.10, 0.18, 0.24)
const STONE := Color(0.64, 0.60, 0.53)
const STONE_LIT := Color(0.80, 0.75, 0.66)
const STONE_DK := Color(0.42, 0.39, 0.36)
const JOINT := Color(0.13, 0.12, 0.15, 0.55)
const IRON := Color(0.15, 0.16, 0.20)
const DARK := Color(0.11, 0.10, 0.13)
const GLASS := Color(0.17, 0.20, 0.27)
const LIT := Color(1.0, 0.80, 0.46)
const SHADOW := Color(0.04, 0.05, 0.10, 0.30)
const MOSS := Color(0.34, 0.42, 0.26)
const LAWN := Color(0.33, 0.45, 0.27)
const LAWN_LIT := Color(0.44, 0.56, 0.33)
const LAWN_DK := Color(0.24, 0.35, 0.22)
const LEAF := Color(0.19, 0.34, 0.23)
const LEAF_LIT := Color(0.32, 0.48, 0.29)
# the painted houses of the Onyar
const PAINT: Array[Color] = [
	Color(0.86, 0.56, 0.28), Color(0.80, 0.36, 0.26), Color(0.90, 0.76, 0.44), Color(0.72, 0.28, 0.24),
	Color(0.84, 0.62, 0.50), Color(0.62, 0.66, 0.50), Color(0.92, 0.84, 0.66), Color(0.74, 0.48, 0.36),
]
const OLD_STONE: Array[Color] = [
	Color(0.62, 0.57, 0.49), Color(0.55, 0.50, 0.44), Color(0.68, 0.62, 0.52), Color(0.58, 0.55, 0.50),
]
const SHUTTER: Array[Color] = [
	Color(0.24, 0.42, 0.36), Color(0.28, 0.36, 0.48), Color(0.44, 0.26, 0.18), Color(0.34, 0.44, 0.30),
]
const TILE: Array[Color] = [
	Color(0.62, 0.34, 0.24), Color(0.55, 0.30, 0.22), Color(0.68, 0.40, 0.28), Color(0.50, 0.29, 0.23), Color(0.60, 0.38, 0.30),
]
const FLOWERS: Array[Color] = [
	Color(0.94, 0.32, 0.46), Color(0.98, 0.76, 0.28), Color(0.74, 0.44, 0.86), Color(0.96, 0.94, 0.90), Color(0.96, 0.48, 0.24),
]


static func _h(k: int) -> float:
	var h := k * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h ^ (h >> 16)) % 100003) / 100003.0


static func _pick(list: Array, k: int) -> Color:
	return list[int(_h(k) * float(list.size())) % list.size()]


# --- roofs -----------------------------------------------------------------------

# A pitched tile roof: the ridge down the middle, the slope to the light warm,
# the other in shade, the tiles' channels running off it, a drip edge
static func roof(b: ShapeBatch, r: Rect2, tile: Color, ridge_y: bool, rib := 9.0) -> void:
	if r.size.x < 6.0 or r.size.y < 6.0:
		return
	var lit := tile.lightened(0.10)
	var shade := tile.darkened(0.20)
	var c := r.get_center()
	b.rect(r, DARK)
	if ridge_y:
		b.rect(Rect2(r.position.x, r.position.y, c.x - r.position.x, r.size.y), lit)
		b.rect(Rect2(c.x, r.position.y, r.end.x - c.x, r.size.y), shade)
		var y := r.position.y + rib * 0.5
		while y < r.end.y:
			b.line(Vector2(r.position.x + 1.0, y), Vector2(c.x - 2.0, y), lit.darkened(0.16), 1.5)
			b.line(Vector2(c.x + 2.0, y), Vector2(r.end.x - 1.0, y), shade.darkened(0.16), 1.5)
			y += rib
		b.line(Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), tile.lightened(0.26), 3.0)
	else:
		b.rect(Rect2(r.position.x, r.position.y, r.size.x, c.y - r.position.y), lit)
		b.rect(Rect2(r.position.x, c.y, r.size.x, r.end.y - c.y), shade)
		var x := r.position.x + rib * 0.5
		while x < r.end.x:
			b.line(Vector2(x, r.position.y + 1.0), Vector2(x, c.y - 2.0), lit.darkened(0.16), 1.5)
			b.line(Vector2(x, c.y + 2.0), Vector2(x, r.end.y - 1.0), shade.darkened(0.16), 1.5)
			x += rib
		b.line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), tile.lightened(0.26), 3.0)
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), shade.darkened(0.30))


static func _chimney(b: ShapeBatch, p: Vector2) -> void:
	b.rect(Rect2(p + Vector2(3.0, 5.0), Vector2(15.0, 13.0)), SHADOW)
	b.rect(Rect2(p, Vector2(13.0, 11.0)), STONE_DK)
	b.rect(Rect2(p + Vector2(1.5, 1.5), Vector2(10.0, 8.0)), STONE)
	b.rect(Rect2(p + Vector2(4.0, 3.5), Vector2(5.0, 4.0)), DARK)


static func _skylight(b: ShapeBatch, p: Vector2, lit: bool, glow: float) -> void:
	b.rect(Rect2(p - Vector2(8.0, 10.0), Vector2(16.0, 20.0)), IRON)
	b.rect(Rect2(p - Vector2(6.0, 8.0), Vector2(12.0, 16.0)), LIT if lit else GLASS)
	b.line(p - Vector2(0.0, 8.0), p + Vector2(0.0, 8.0), IRON, 1.6)
	if lit and glow > 0.05:
		b.glow(p, 34.0, Color(LIT, 0.20 * glow))


# a roof terrace: tiles underfoot, a parapet, washing or pots on it
static func _terrace(b: ShapeBatch, r: Rect2, k: int) -> void:
	var floor_c := Color(0.58, 0.42, 0.34).lerp(STONE, _h(k + 3) * 0.6)
	b.rect(r, STONE_DK)
	b.rect(r.grow(-4.0), floor_c)
	var y := r.position.y + 14.0
	while y < r.end.y - 5.0:
		b.line(Vector2(r.position.x + 5.0, y), Vector2(r.end.x - 5.0, y), floor_c.darkened(0.14), 1.2)
		y += 13.0
	b.rect(Rect2(r.position + Vector2(4.0, 4.0), Vector2(r.size.x - 8.0, 6.0)), Color(0.0, 0.0, 0.0, 0.18))
	if r.size.x > 46.0 and r.size.y > 40.0:
		if _h(k + 7) < 0.5:
			var ya := r.position.y + r.size.y * 0.4
			b.line(Vector2(r.position.x + 9.0, ya), Vector2(r.end.x - 9.0, ya), Color(0.80, 0.80, 0.82, 0.7), 1.2)
			var n := int((r.size.x - 26.0) / 14.0)
			for i in range(n):
				var wc: Color = [Color(0.88, 0.88, 0.86), Color(0.44, 0.56, 0.70), Color(0.78, 0.42, 0.40), Color(0.86, 0.78, 0.52)][int(_h(k * 5 + i) * 4.0) % 4]
				b.rect(Rect2(r.position.x + 14.0 + float(i) * 14.0, ya - 1.0, 10.0, 11.0 + 6.0 * _h(k + i)), wc.darkened(0.12))
		else:
			for i in range(4):
				var q := r.position + Vector2(13.0 + float(i) * (r.size.x - 26.0) / 3.0, r.size.y - 13.0)
				_pot(b, q, k * 3 + i)
	if r.size.x > 60.0:
		b.rect(Rect2(r.end.x - 30.0, r.position.y + 8.0, 22.0, 18.0), STONE)
		b.rect(Rect2(r.end.x - 30.0, r.position.y + 22.0, 22.0, 4.0), STONE_DK)


# a courtyard let into the roofs: the well's dark edge, flags, one tree
static func _patio(b: ShapeBatch, r: Rect2, k: int) -> void:
	b.rect(r, DARK)
	b.rect(r.grow(-5.0), STONE_DK)
	b.rect(Rect2(r.position + Vector2(5.0, 5.0), Vector2(r.size.x - 10.0, 12.0)), Color(0, 0, 0, 0.35))
	_bush(b, r.get_center(), minf(r.size.x, r.size.y) * 0.26, k)


static func _pot(b: ShapeBatch, p: Vector2, k: int) -> void:
	b.circle(p + Vector2(2.0, 3.0), 6.0, SHADOW)
	b.circle(p, 5.5, Color(0.56, 0.32, 0.22))
	b.circle(p, 4.6, LEAF)
	for i in range(3):
		b.circle(p + Vector2.from_angle(float(i) * 2.1 + float(k)) * 2.8, 1.9, _pick(FLOWERS, k))


static func _bush(b: ShapeBatch, p: Vector2, r: float, k: int) -> void:
	b.circle(p + Vector2(r * 0.4, r * 0.55), r * 1.05, SHADOW)
	b.circle(p, r, LEAF)
	for i in range(5):
		var a := float(i) * TAU / 5.0 + _h(k) * 6.0
		b.circle(p + Vector2.from_angle(a) * r * 0.55, r * 0.52, LEAF.lerp(LEAF_LIT, 0.25 + 0.3 * _h(k + i)))
	b.circle(p - Vector2(r * 0.28, r * 0.34), r * 0.40, LEAF_LIT)


# a tall dark cypress seen from above, its shadow thrown long
static func _cypress(b: ShapeBatch, p: Vector2, r: float) -> void:
	b.capsule(p + Vector2(4.0, 6.0), p + Vector2(22.0, 34.0), r * 0.8, Color(SHADOW, 0.22))
	b.circle(p, r, Color(0.12, 0.22, 0.17))
	b.circle(p - Vector2(1.5, 2.0), r * 0.72, Color(0.17, 0.30, 0.21))
	b.circle(p - Vector2(3.0, 3.5), r * 0.36, Color(0.25, 0.40, 0.27))


# One quarter of the old town: plots of roofs, terraces and wells filling a
# rectangle, no two alike, dark lanes between. `face` is the side its fronts
# are on (the plots line up with it): -1 the left, 1 the right, 0 neither.
static func quarter(b: ShapeBatch, r: Rect2, salt: int) -> void:
	if r.size.x < 12.0 or r.size.y < 12.0:
		return
	var glow := Game.lamp_glow()
	b.rect(r, DARK)
	var y := r.position.y
	var row := 0
	while y < r.end.y - 6.0:
		var h := 92.0 + 46.0 * _h(salt + row * 31)
		if r.end.y - y - h < 46.0:
			h = r.end.y - y
		var x := r.position.x
		var col := 0
		while x < r.end.x - 6.0:
			var k := salt * 977 + row * 131 + col * 17
			var w := 88.0 + 74.0 * _h(k + 1)
			if r.end.x - x - w < 50.0:
				w = r.end.x - x
			var p := Rect2(x, y, w, h).grow(-1.5)
			var kind := _h(k + 2)
			if kind < 0.66:
				var tall := _h(k + 6) < 0.5
				roof(b, p, _pick(TILE, k + 3), tall, 8.0 + 2.0 * _h(k + 8))
				if _h(k + 4) < 0.55:
					_chimney(b, p.position + Vector2(p.size.x * (0.2 + 0.5 * _h(k + 9)), p.size.y * 0.18))
				if _h(k + 5) < 0.30:
					_skylight(b, p.get_center() + Vector2(-p.size.x * 0.24, p.size.y * 0.22), _h(k + 11) < 0.6, glow)
			elif kind < 0.90:
				_terrace(b, p, k)
			else:
				roof(b, p, _pick(TILE, k + 3), true)
				var s := Vector2(minf(p.size.x, p.size.y), minf(p.size.x, p.size.y)) * 0.56
				_patio(b, Rect2(p.get_center() - s * 0.5, s), k)
			# the taller neighbour's shadow on this one
			if _h(k + 12) < 0.4:
				b.rect(Rect2(p.position, Vector2(10.0 + 12.0 * _h(k + 13), p.size.y)), Color(0.0, 0.0, 0.03, 0.22))
			x += w
			col += 1
		y += h
		row += 1


# --- fronts ----------------------------------------------------------------------

# A house's front seen from above and a little forward: a strip of wall with its
# floor line, shuttered windows, some lit, and a balcony or two with flowers.
# Runs from a to c along the front; `out` points from the wall to the street or
# the water, `deep` is how much wall shows.
static func front(b: ShapeBatch, a: Vector2, c: Vector2, out: Vector2, deep: float, wall: Color, k: int, over := true) -> void:
	var along := (c - a).normalized()
	var ln := a.distance_to(c)
	if ln < 14.0:
		return
	var glow := Game.lamp_glow()
	var lit_side := wall.lightened(0.06) if out.x < 0.0 or out.y < 0.0 else wall.darkened(0.06)
	b.quad(a, c, c - out * deep, a - out * deep, lit_side)
	# the eaves over it, and the foot of the wall
	b.line(a - out * (deep - 1.5), c - out * (deep - 1.5), lit_side.darkened(0.35), 3.0)
	b.line(a - out * 1.0, c - out * 1.0, lit_side.darkened(0.28), 2.0)
	b.line(a + along, a + along - out * deep, lit_side.darkened(0.25), 1.6)
	var n := maxi(1, int(ln / 30.0))
	for i in range(n):
		var p := a + along * (ln * (float(i) + 0.5) / float(n)) - out * deep * 0.56
		if not over and _h(k * 17 + i * 3) < 0.40:
			# an old doorway under its arch, or ivy over the wall
			if _h(k * 19 + i) < 0.5:
				b.quad(p - along * 9.0 - out * 4.0, p + along * 9.0 - out * 4.0, p + along * 9.0 + out * deep * 0.5, p - along * 9.0 + out * deep * 0.5, STONE_LIT)
				b.circle(p - out * 4.0, 9.0, STONE_LIT)
				b.circle(p - out * 3.0, 6.4, Color(0.30, 0.19, 0.13))
				b.quad(p - along * 6.4 - out * 3.0, p + along * 6.4 - out * 3.0, p + along * 6.4 + out * deep * 0.5, p - along * 6.4 + out * deep * 0.5, Color(0.30, 0.19, 0.13))
			else:
				for f in range(16):
					var ip := p + along * (_h(k + f * 3) - 0.5) * 30.0 + out * (_h(k + f * 7) - 0.5) * deep * 0.86
					b.circle(ip, 3.0 + 3.0 * _h(f + k), LEAF.lerp(LEAF_LIT, _h(f * 5 + k)))
			continue
		var hw := 5.0
		var hd := deep * 0.24
		var lit := _h(k * 7 + i * 13) < 0.62
		var sh := _pick(SHUTTER, k + 5)
		for s: float in [-1.0, 1.0]:
			var sp := p + along * s * (hw + 3.2)
			b.quad(sp - along * 2.6 - out * hd, sp + along * 2.6 - out * hd, sp + along * 2.6 + out * hd, sp - along * 2.6 + out * hd, sh)
		b.quad(p - along * hw - out * hd, p + along * hw - out * hd, p + along * hw + out * hd, p - along * hw + out * hd, LIT if lit else GLASS)
		b.line(p - out * hd, p + out * hd, IRON, 1.2)
		if lit and glow > 0.05:
			b.glow(p + out * deep * 0.6, 24.0, Color(LIT, 0.22 * glow))
		if _h(k * 11 + i * 5) < 0.42:
			# an iron balcony out over the street, its pots spilling
			var q := p + out * (deep * 0.56 + 3.0 if over else deep * 0.30)
			b.quad(q - along * 13.0 - out * 3.5, q + along * 13.0 - out * 3.5, q + along * 13.0 + out * 4.5, q - along * 13.0 + out * 4.5, IRON)
			b.quad(q - along * 11.5 - out * 3.0, q + along * 11.5 - out * 3.0, q + along * 11.5 + out * 2.5, q - along * 11.5 + out * 2.5, STONE_DK)
			for f in range(5):
				var fp := q + along * (-10.0 + float(f) * 5.0) + out * 3.0
				b.circle(fp, 2.8, LEAF)
				b.circle(fp + out * 0.8, 1.9, _pick(FLOWERS, k * 3 + f))


# --- the Onyar --------------------------------------------------------------------

# water between two lines, its light lying along the middle
static func _water(b: ShapeBatch, r: Rect2, flows_x: bool, soft_top := false) -> void:
	b.rect(r, WATER)
	var c := r.get_center()
	if flows_x:
		b.band(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, c.y), Vector2(r.end.x, c.y),
			Vector2(r.position.x, r.end.y), r.end]), 2, WATER_LIT, PackedFloat32Array([0.0, 0.75, 0.0]))
		# shade under each bank, but for where the river bends off south
		for e: Array in [[r.position.y, r.position.y + 70.0, r.position.x, r.position.x + 90.0, r.end.x, 1.0, 1.0],
				[r.end.y, r.end.y - 70.0, r.position.x, RIVER_W - 90.0, RIVER_W + 20.0, 1.0, 0.0],
				[r.end.y, r.end.y - 70.0, QUAY_X - 20.0, QUAY_X + 90.0, r.end.x, 0.0, 1.0]]:
			b.band(PackedVector2Array([Vector2(e[2], e[0]), Vector2(e[3], e[0]), Vector2(e[4], e[0]), Vector2(e[2], e[1]), Vector2(e[3], e[1]), Vector2(e[4], e[1])]),
				3, WATER_DK, PackedFloat32Array([0.9, 0.0]), PackedFloat32Array([e[5], 1.0, e[6]]))
	else:
		var y1 := r.position.y + 240.0
		var top := 0.0 if soft_top else 1.0
		for e: Array in [[r.position.x, c.x, r.end.x, WATER_LIT, 0.0, 0.75, 0.0],
				[r.position.x, r.position.x + 23.0, r.position.x + 46.0, WATER_DK, 0.9, 0.45, 0.0],
				[r.end.x - 40.0, r.end.x - 20.0, r.end.x, WATER_DK, 0.0, 0.4, 0.8]]:
			b.band(PackedVector2Array([Vector2(e[0], r.position.y), Vector2(e[1], r.position.y), Vector2(e[2], r.position.y),
				Vector2(e[0], y1), Vector2(e[1], y1), Vector2(e[2], y1), Vector2(e[0], r.end.y), Vector2(e[1], r.end.y), Vector2(e[2], r.end.y)]),
				3, e[3], PackedFloat32Array([top, 1.0, 1.0]), PackedFloat32Array([e[4], e[5], e[6]]))


# the current: short pale strokes along the flow
static func _ripples(b: ShapeBatch, r: Rect2, flows_x: bool, salt: int, per := 7200.0) -> void:
	var n := int(r.size.x * r.size.y / per)
	for i in range(n):
		var p := r.position + Vector2(_h(salt + i * 3) * r.size.x, _h(salt + i * 7 + 1) * r.size.y)
		var ln := 10.0 + 22.0 * _h(salt + i * 5)
		var d := Vector2(ln, 0.0) if flows_x else Vector2(0.0, ln)
		var q := (p + d).clamp(r.position, r.end)
		b.line(p, q, Color(0.66, 0.78, 0.86, 0.10 + 0.10 * _h(i + salt)), 1.6)


# a house's colour lying in the water before it, broken by the current
static func _reflect(b: ShapeBatch, a: Vector2, c: Vector2, out: Vector2, col: Color, k: int, reach: float) -> void:
	var o := out * reach
	b.band(PackedVector2Array([a, c, a + o * 0.5, c + o * 0.5, a + o, c + o]), 2, col, PackedFloat32Array([0.62, 0.36, 0.0]))
	var along := (c - a)
	for i in range(3):
		var u := 0.2 + 0.3 * float(i)
		var off := out * reach * (0.22 + 0.5 * _h(k + i * 9))
		b.line(a + along * (u - 0.14) + off, a + along * (u + 0.14) + off, Color(WATER_DK, 0.55), 2.4)
		if _h(k * 7 + i) < 0.6:
			var w := a + along * u + out * (12.0 + 14.0 * _h(k + i))
			b.line(w, w + out * 22.0, Color(LIT, 0.26 * Game.lamp_glow()), 4.0)


# A row of the painted houses along the water, from p along `along` for `ln`,
# the water on the `out` side: each narrow and its own colour, some stepping out
# over the river on corbels, a pitched roof behind, the colour in the water.
static func houses(b: ShapeBatch, p: Vector2, along: Vector2, ln: float, out: Vector2, salt: int, reach := 110.0) -> void:
	var at := 0.0
	var i := 0
	while at < ln - 8.0:
		var k := salt * 613 + i * 37
		var w := 46.0 + 30.0 * _h(k)
		if ln - at - w < 30.0:
			w = ln - at
		var paint := _pick(PAINT, k + 1)
		var step := 6.0 + 16.0 * _h(k + 2)
		var a := p + along * (at + 0.8) + out * step
		var c := p + along * (at + w - 0.8) + out * step
		_reflect(b, a, c, out, paint, k, reach * (0.75 + 0.4 * _h(k + 3)))
		b.quad(a, c, c + out * 12.0, a + out * 12.0, Color(0.02, 0.04, 0.08, 0.42))
		# the roof, running back from the front
		var deep := 30.0 + 8.0 * _h(k + 4)
		var back := p - out * ROW
		var r := Rect2(back + along * at, Vector2.ZERO).expand(c - out * deep)
		r = r.expand(a - out * deep)
		roof(b, r.grow(-0.6), _pick(TILE, k + 5), absf(out.x) < 0.5, 7.0)
		if _h(k + 6) < 0.5:
			_chimney(b, r.position + r.size * Vector2(0.32, 0.30))
		front(b, a, c, out, deep, paint, k)
		# corbels under the ones that step out
		if step > 13.0:
			var m := int(w / 15.0)
			for q in range(m):
				var cp := a + along * (w - 2.0) * (float(q) + 0.5) / float(m)
				b.line(cp, cp + out * 6.0, Color(0.34, 0.24, 0.18), 3.6)
		at += w
		i += 1


# a stone quay between the paving and the river: coping, joints, a drop of shade
static func _quay(b: ShapeBatch, r: Rect2, water_left: bool) -> void:
	b.rect(r, STONE_DK)
	b.rect(r.grow(-3.0), STONE)
	var y := r.position.y
	while y < r.end.y:
		b.line(Vector2(r.position.x + 3.0, y), Vector2(r.end.x - 3.0, y), JOINT, 1.4)
		y += 34.0
	var x := r.position.x if water_left else r.end.x - 5.0
	b.rect(Rect2(x, r.position.y, 5.0, r.size.y), STONE_LIT)
	var sx := r.position.x - 16.0 if water_left else r.end.x
	b.rect(Rect2(sx, r.position.y, 16.0, r.size.y), Color(0.02, 0.04, 0.08, 0.30))


# --- the regions -------------------------------------------------------------------

# The Rambla's two sides: the river and its painted far bank to the west, the
# arcaded fronts and the roofs of the old town to the east.
static func rambla(b: ShapeBatch) -> void:
	var top := BRIDGE_Y0
	var river := Rect2(RIVER_W - 30.0, top - 8.0, QUAY_X - RIVER_W + 60.0, SOUTH - top + 8.0)
	_water(b, river, false, true)
	_ripples(b, Rect2(RIVER_W + 30.0, top, QUAY_X - RIVER_W - 40.0, SOUTH - top), false, 41)
	quarter(b, Rect2(FAR_L, top + ROW + 6.0, RIVER_W - ROW - FAR_L, SOUTH - top), 11)
	houses(b, Vector2(RIVER_W, top + ROW * 0.6), Vector2.DOWN, SOUTH - top - ROW * 0.6, Vector2.RIGHT, 13, 120.0)
	_quay(b, Rect2(QUAY_X, RAMBLA_END, 38.0, SOUTH - RAMBLA_END), true)
	# the corner by the bridge: the quay runs on to its abutment
	b.polygon(PackedVector2Array([Vector2(QUAY_X, RAMBLA_END), Vector2(412.0, RAMBLA_END), Vector2(506.0, BRIDGE_Y0), Vector2(506.0, BRIDGE_Y0 + 2.0), Vector2(QUAY_X, BRIDGE_Y0)]), STONE_DK)
	b.polygon(PackedVector2Array([Vector2(QUAY_X + 6.0, RAMBLA_END), Vector2(408.0, RAMBLA_END), Vector2(492.0, BRIDGE_Y0 + 10.0), Vector2(QUAY_X + 6.0, BRIDGE_Y0 + 10.0)]), STONE)
	b.rect(Rect2(QUAY_X, BRIDGE_Y0, 5.0, RAMBLA_END - BRIDGE_Y0), STONE_LIT)
	b.rect(Rect2(QUAY_X, BRIDGE_Y0, 134.0, 6.0), STONE_LIT)
	for i in range(6):
		b.line(Vector2(QUAY_X + 5.0, BRIDGE_Y0 + 30.0 + 34.0 * float(i)), Vector2(480.0 - 13.0 * float(i), BRIDGE_Y0 + 30.0 + 34.0 * float(i)), JOINT, 1.4)
	for i in range(4):
		_bush(b, Vector2(398.0 + float(i) * 15.0, -800.0 - float(i) * 34.0), 12.0, 60 + i)
	# the east side
	var fx := 870.0
	var y := RAMBLA_END
	var i2 := 0
	while y < SOUTH - 4.0:
		var k := 2203 + i2 * 29
		var h := 72.0 + 42.0 * _h(k)
		if SOUTH - y - h < 40.0:
			h = SOUTH - y
		_arcade(b, fx, y, h, k)
		front(b, Vector2(fx + 62.0, y + 0.8), Vector2(fx + 62.0, y + h - 0.8), Vector2.LEFT, 28.0, _pick(PAINT, k + 1), k)
		roof(b, Rect2(fx + 62.0, y, 44.0 + 12.0 * _h(k + 2), h).grow(-1.0), _pick(TILE, k + 3), false, 8.0)
		y += h
		i2 += 1
	quarter(b, Rect2(fx + 108.0, BRIDGE_Y0 + ROW + 8.0, FAR_R - fx - 108.0, SOUTH - BRIDGE_Y0 - ROW), 17)
	# the corner house by the bridge, and the little court it keeps
	b.polygon(PackedVector2Array([Vector2(772.0, BRIDGE_Y0), Vector2(870.0, RAMBLA_END), Vector2(980.0, RAMBLA_END), Vector2(980.0, BRIDGE_Y0)]), STONE_DK)
	b.polygon(PackedVector2Array([Vector2(790.0, BRIDGE_Y0 + 8.0), Vector2(876.0, RAMBLA_END - 8.0), Vector2(970.0, RAMBLA_END - 8.0), Vector2(970.0, BRIDGE_Y0 + 8.0)]), STONE)
	for i in range(5):
		_pot(b, Vector2(862.0 - float(i) * 11.0, -770.0 - float(i) * 24.0), 31 + i)
	_bush(b, Vector2(918.0, -800.0), 26.0, 9)


# One house's bay of the Rambla's arcade: pillars and dark arches, a lit shop
# deep in each, and what it keeps out front: a striped awning, the florist's
# buckets, the bookshop's boxes
static func _arcade(b: ShapeBatch, fx: float, y: float, h: float, k: int) -> void:
	var glow := Game.lamp_glow()
	b.rect(Rect2(fx + 12.0, y, 50.0, h), STONE_DK)
	var n := maxi(1, int(h / 46.0))
	var bay := h / float(n)
	for i in range(n):
		var by := y + bay * float(i)
		var k2 := k * 7 + i
		# the arch, its floor going back into the dark, the shop's light in it
		b.rect(Rect2(fx + 14.0, by + 7.0, 46.0, bay - 14.0), Color(0.17, 0.14, 0.15))
		b.rect(Rect2(fx + 14.0, by + 9.0, 16.0, bay - 18.0), Color(0.36, 0.31, 0.29))
		if _h(k2 + 3) < 0.72:
			b.band(PackedVector2Array([Vector2(fx + 14.0, by + 10.0), Vector2(fx + 50.0, by + 10.0), Vector2(fx + 14.0, by + bay - 10.0), Vector2(fx + 50.0, by + bay - 10.0)]),
				2, Color(LIT, 0.25 + 0.5 * glow), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.15, 1.0]))
		var what := _h(k2 + 5)
		if what < 0.34:
			# an awning over the mouth
			var ac: Color = [Color(0.72, 0.22, 0.20), Color(0.20, 0.42, 0.40), Color(0.80, 0.60, 0.26), Color(0.30, 0.34, 0.54)][int(_h(k2 + 9) * 4.0) % 4]
			var m := maxi(4, int((bay - 10.0) / 6.0))
			var sw := (bay - 10.0) / float(m)
			b.rect(Rect2(fx + 13.0, by + 8.0, 30.0, bay - 10.0), SHADOW)
			for q in range(m):
				b.rect(Rect2(fx + 16.0, by + 5.0 + sw * float(q), 28.0, sw), ac if q % 2 == 0 else Color(0.92, 0.88, 0.80))
			b.rect(Rect2(fx + 16.0, by + 5.0, 3.0, bay - 10.0), ac.darkened(0.3))
		elif what < 0.60:
			for q in range(4):
				var p := Vector2(fx + 19.0 + 9.0 * float(q % 2), by + 14.0 + float(q) * (bay - 28.0) / 3.0)
				b.circle(p, 6.0, Color(0.40, 0.44, 0.48))
				for f in range(5):
					b.circle(p + Vector2.from_angle(float(f) * 1.26 + float(k2)) * 3.4, 2.5, _pick(FLOWERS, k2 + q))
		elif what < 0.80:
			b.rect(Rect2(fx + 16.0, by + 11.0, 16.0, bay - 22.0), Color(0.42, 0.28, 0.18))
			var q2 := by + 13.0
			while q2 < by + bay - 14.0:
				b.rect(Rect2(fx + 18.0, q2, 12.0, 2.6), [Color(0.80, 0.34, 0.28), Color(0.86, 0.78, 0.58), Color(0.32, 0.46, 0.58), Color(0.46, 0.58, 0.36)][int(_h(int(q2) * 3 + k2) * 4.0) % 4])
				q2 += 3.6
	# a pillar between every two arches
	for i in range(n + 1):
		var py := clampf(y + bay * float(i) - 7.0, y, y + h - 14.0)
		b.rect(Rect2(fx + 12.0, py + 3.0, 22.0, 14.0), SHADOW)
		b.rect(Rect2(fx + 12.0, py, 20.0, 14.0), STONE)
		b.rect(Rect2(fx + 12.0, py, 5.0, 14.0), STONE_LIT)


# The crossing: the Onyar wide under the iron bridge, houses the length of both
# banks, the river bending off south beside the Rambla
static func crossing(b: ShapeBatch) -> void:
	var r := Rect2(FAR_L, BRIDGE_Y1, FAR_R - FAR_L, BRIDGE_Y0 - BRIDGE_Y1)
	_water(b, r, true)
	_ripples(b, r.grow(-40.0), true, 71, 6800.0)
	# gravel bars, as the Onyar shows them, grass on their backs
	for g: Array in [[Vector2(120.0, -1230.0), 150.0, 30.0], [Vector2(1130.0, -1300.0), 190.0, 34.0], [Vector2(1400.0, -1140.0), 110.0, 22.0]]:
		b.ellipse((g[0] as Vector2) + Vector2(0.0, 8.0), float(g[1]), float(g[2]), Color(WATER_DK, 0.6))
		b.ellipse(g[0], float(g[1]) * 0.94, float(g[2]) * 0.86, Color(0.40, 0.38, 0.35))
		b.ellipse((g[0] as Vector2) - Vector2(8.0, 4.0), float(g[1]) * 0.7, float(g[2]) * 0.5, MOSS.darkened(0.12))
		for q in range(9):
			b.circle((g[0] as Vector2) + Vector2((_h(q * 3 + int(g[1])) - 0.5) * float(g[1]) * 1.7, (_h(q * 7) - 0.5) * float(g[2])), 3.0 + 3.0 * _h(q), Color(0.54, 0.52, 0.48))
	houses(b, Vector2(FAR_L, BRIDGE_Y0), Vector2.RIGHT, RIVER_W - FAR_L - 6.0, Vector2.UP, 23)
	houses(b, Vector2(800.0, BRIDGE_Y0), Vector2.RIGHT, FAR_R - 800.0, Vector2.UP, 29)
	houses(b, Vector2(FAR_L, BRIDGE_Y1), Vector2.RIGHT, 480.0 - FAR_L, Vector2.DOWN, 31)
	houses(b, Vector2(800.0, BRIDGE_Y1), Vector2.RIGHT, FAR_R - 800.0, Vector2.DOWN, 37)
	# the bridge's stone abutments and the shade it lays on the river
	b.rect(Rect2(500.0, BRIDGE_Y1, 18.0, BRIDGE_Y0 - BRIDGE_Y1), Color(0.02, 0.03, 0.06, 0.4))
	b.band(PackedVector2Array([Vector2(800.0, BRIDGE_Y1), Vector2(884.0, BRIDGE_Y1), Vector2(800.0, BRIDGE_Y0), Vector2(884.0, BRIDGE_Y0)]),
		2, Color(0.02, 0.03, 0.06, 0.45), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
	for x: float in [470.0, 780.0]:
		for yy: float in [BRIDGE_Y0 - 22.0, BRIDGE_Y1]:
			b.rect(Rect2(x, yy, 34.0, 22.0), STONE_DK)
			b.rect(Rect2(x + 3.0, yy + 3.0, 28.0, 8.0), STONE_LIT)


# The old town either side of the steps: stone fronts along the path, following
# its edge, and the quarter's roofs behind
static func barri_vell(b: ShapeBatch, edge: Callable) -> void:
	var top := PLACA_Y0
	var bot := BRIDGE_Y1 - ROW
	quarter(b, Rect2(FAR_L, top, 384.0 - FAR_L, bot - top), 43)
	quarter(b, Rect2(896.0, top, FAR_R - 896.0, bot - top), 47)
	for side: float in [-1.0, 1.0]:
		var out := Vector2(-side, 0.0)
		# between the fronts and the quarters, whatever the path leaves
		var y := top
		while y < BRIDGE_Y1 - 1.0:
			var yn := minf(y + 20.0, BRIDGE_Y1)
			var x0: float = edge.call(y, side)
			var x1: float = edge.call(yn, side)
			var wall := 384.0 if side < 0.0 else 896.0
			b.quad(Vector2(x0, y), Vector2(wall, y), Vector2(wall, yn), Vector2(x1, yn), TILE[3].darkened(0.30))
			y = yn
		y = top
		var i := 0
		while y < BRIDGE_Y1 - 30.0:
			var k := 4409 + i * 41 + int(side) * 7
			var h := 74.0 + 44.0 * _h(k)
			if BRIDGE_Y1 - y - h < 40.0:
				h = BRIDGE_Y1 - y
			var xa: float = edge.call(y, side)
			var xb: float = edge.call(y + h, side)
			var deep := 30.0
			var a := Vector2(xa + side * deep, y + 0.8)
			var c := Vector2(xb + side * deep, y + h - 0.8)
			front(b, Vector2(xa, y + 0.8), Vector2(xb, y + h - 0.8), out, deep, _pick(OLD_STONE, k + 1), k, false)
			# the dressed stones of it
			for q in range(5):
				var p := a.lerp(c, 0.12 + 0.18 * float(q)) + out * (6.0 + 16.0 * _h(k + q))
				b.rect(Rect2(p - Vector2(5.0, 2.5), Vector2(10.0, 5.0)), Color(1.0, 0.96, 0.86, 0.10))
			# its roof, up to the quarter behind
			var wall2 := 384.0 if side < 0.0 else 896.0
			var inner := maxf(a.x, c.x) if side > 0.0 else minf(a.x, c.x)
			var rr := Rect2(minf(inner, wall2), y, absf(wall2 - inner), h)
			if rr.size.x > 10.0:
				roof(b, rr.grow(-1.0), _pick(TILE, k + 3), false, 8.0)
			y += h
			i += 1


# The square's two sides: the Onyar below the parapet, bending in under a row
# of houses and out past the walls; the Basílica, its cloister and its blunt
# tower over the paving to the east
static func sant_feliu(b: ShapeBatch) -> void:
	var r := Rect2(FELIU_W - 20.0, PLACA_Y1 - 10.0, FELIU_E - FELIU_W + 30.0, PLACA_Y0 - PLACA_Y1 + 20.0)
	_water(b, r, false)
	_ripples(b, r.grow(-24.0), false, 83)
	quarter(b, Rect2(FAR_L, PLACA_Y1, FELIU_W - ROW - FAR_L, PLACA_Y0 - PLACA_Y1), 53)
	houses(b, Vector2(FELIU_W, PLACA_Y1), Vector2.DOWN, PLACA_Y0 - PLACA_Y1, Vector2.RIGHT, 59, 130.0)
	# the bank it comes out from under, at the old town's end
	houses(b, Vector2(FAR_L + 250.0, PLACA_Y0 + 4.0), Vector2.RIGHT, FELIU_E - FAR_L - 250.0, Vector2.UP, 61, 80.0)
	# and a low stone weir under the walls, the water white over it
	b.rect(Rect2(FELIU_W - 8.0, PLACA_Y1 - 4.0, FELIU_E - FELIU_W + 8.0, 18.0), STONE_DK)
	b.rect(Rect2(FELIU_W - 8.0, PLACA_Y1 - 4.0, FELIU_E - FELIU_W + 8.0, 6.0), STONE_LIT)
	b.band(PackedVector2Array([Vector2(FELIU_W, PLACA_Y1 + 14.0), Vector2(FELIU_E, PLACA_Y1 + 14.0), Vector2(FELIU_W, PLACA_Y1 + 56.0), Vector2(FELIU_E, PLACA_Y1 + 56.0)]),
		2, Color(0.86, 0.94, 0.98, 0.6), PackedFloat32Array([1.0, 0.0]))
	# the parapet
	var p := Rect2(306.0, PLACA_Y1, 24.0, PLACA_Y0 - PLACA_Y1)
	b.rect(Rect2(p.position.x - 18.0, p.position.y, 18.0, p.size.y), Color(0.02, 0.04, 0.08, 0.36))
	b.rect(p, STONE_DK)
	b.rect(p.grow_individual(-3.0, 0.0, -3.0, 0.0), STONE)
	var y := p.position.y + 10.0
	while y < p.end.y:
		b.line(Vector2(p.position.x + 3.0, y), Vector2(p.end.x - 3.0, y), JOINT, 1.4)
		y += 30.0
	b.rect(Rect2(p.position.x + 3.0, p.position.y, 4.0, p.size.y), STONE_LIT)
	_basilica(b)


static func _basilica(b: ShapeBatch) -> void:
	var x0 := 952.0
	quarter(b, Rect2(1330.0, PLACA_Y1, FAR_R - 1330.0, PLACA_Y0 - PLACA_Y1), 67)
	# the ground it stands on
	b.rect(Rect2(x0, PLACA_Y1, 378.0, PLACA_Y0 - PLACA_Y1), STONE_DK)
	b.rect(Rect2(x0 + 4.0, PLACA_Y1, 372.0, PLACA_Y0 - PLACA_Y1), STONE.darkened(0.16))
	var gy := PLACA_Y1 + 20.0
	while gy < PLACA_Y0:
		b.line(Vector2(x0, gy), Vector2(1330.0, gy), JOINT, 1.2)
		gy += 40.0
	# the nave: a long tiled roof, the aisles lower down each side
	var nave := Rect2(x0 + 66.0, -3660.0, 200.0, 560.0)
	b.rect(Rect2(nave.position + Vector2(26.0, 40.0), nave.size + Vector2(60.0, 0.0)), Color(SHADOW, 0.34))
	for a: Rect2 in [Rect2(nave.position.x - 52.0, nave.position.y + 30.0, 54.0, nave.size.y - 60.0), Rect2(nave.end.x - 2.0, nave.position.y + 30.0, 54.0, nave.size.y - 60.0)]:
		b.rect(a.grow(3.0), STONE_DK)
		b.rect(a, STONE)
		roof(b, a.grow(-6.0), TILE[3], true, 8.0)
	b.rect(nave.grow(4.0), STONE_DK)
	b.rect(nave, STONE_LIT)
	roof(b, nave.grow(-8.0), TILE[1], true, 9.0)
	# the apse at the north end, a fan of slopes
	var ac := Vector2(nave.get_center().x, nave.position.y)
	for i in range(7):
		var a0 := PI + PI * float(i) / 7.0
		var a1 := PI + PI * float(i + 1) / 7.0
		b.polygon(PackedVector2Array([ac, ac + Vector2.from_angle(a0) * 104.0, ac + Vector2.from_angle(a1) * 104.0]), STONE_DK)
		b.polygon(PackedVector2Array([ac, ac + Vector2.from_angle(a0) * 94.0, ac + Vector2.from_angle(a1) * 94.0]), TILE[1].lightened(0.10 - 0.05 * float(i)))
		b.line(ac, ac + Vector2.from_angle(a0) * 94.0, TILE[1].lightened(0.22), 2.0)
	# buttresses down the side that faces the square, a lancet window between each
	var glow := Game.lamp_glow()
	var y := nave.position.y + 44.0
	while y < nave.end.y - 40.0:
		b.rect(Rect2(x0 + 4.0, y + 5.0, 18.0, 22.0), SHADOW)
		b.rect(Rect2(x0 - 4.0, y, 24.0, 20.0), STONE_DK)
		b.rect(Rect2(x0 - 2.0, y + 2.0, 20.0, 9.0), STONE_LIT)
		b.rect(Rect2(x0 + 8.0, y + 36.0, 7.0, 22.0), Color(0.96, 0.66, 0.36) if glow > 0.05 else GLASS)
		if glow > 0.05:
			b.glow(Vector2(x0 - 2.0, y + 47.0), 34.0, Color(0.98, 0.64, 0.34, 0.26 * glow))
		y += 74.0
	# the octagonal bell tower, its spire cut off short, the tower's shadow long
	var tc := Vector2(x0 + 62.0, -3020.0)
	b.capsule(tc + Vector2(20.0, 30.0), tc + Vector2(110.0, 150.0), 44.0, Color(SHADOW, 0.30))
	for ring: Array in [[62.0, STONE_DK], [57.0, STONE], [46.0, STONE_DK], [42.0, STONE_LIT], [30.0, STONE_DK], [26.0, STONE]]:
		var oct := PackedVector2Array()
		for i in range(8):
			oct.append(tc + Vector2.from_angle(TAU * (float(i) + 0.5) / 8.0) * float(ring[0]))
		b.polygon(oct, ring[1])
	for i in range(8):
		var d := Vector2.from_angle(TAU * (float(i) + 0.5) / 8.0)
		b.line(tc + d * 28.0, tc + d * 56.0, STONE_DK, 2.4)
		b.circle(tc + d * 56.0, 7.0, STONE_DK)
		b.circle(tc + d * 56.0 - Vector2(1.5, 1.5), 4.5, STONE_LIT)
	b.circle(tc, 12.0, DARK)
	# the cloister garden at the south end, and the sacristy at the north
	var cl := Rect2(x0 + 150.0, -2990.0, 190.0, 180.0)
	b.rect(cl.grow(4.0), STONE_DK)
	roof(b, Rect2(cl.position, Vector2(cl.size.x, 34.0)), TILE[0], false)
	roof(b, Rect2(cl.position + Vector2(0.0, cl.size.y - 34.0), Vector2(cl.size.x, 34.0)), TILE[0], false)
	roof(b, Rect2(cl.position, Vector2(34.0, cl.size.y)), TILE[2], true)
	roof(b, Rect2(cl.position + Vector2(cl.size.x - 34.0, 0.0), Vector2(34.0, cl.size.y)), TILE[2], true)
	b.rect(cl.grow(-34.0), LAWN)
	b.line(cl.get_center() - Vector2(60.0, 0.0), cl.get_center() + Vector2(60.0, 0.0), STONE, 8.0)
	b.line(cl.get_center() - Vector2(0.0, 56.0), cl.get_center() + Vector2(0.0, 56.0), STONE, 8.0)
	b.circle(cl.get_center(), 13.0, STONE_LIT)
	b.circle(cl.get_center(), 8.0, WATER_LIT)
	for s: Vector2 in [Vector2(-32, -32), Vector2(32, -32), Vector2(-32, 32), Vector2(32, 32)]:
		_cypress(b, cl.get_center() + s, 9.0)
	roof(b, Rect2(x0 + 20.0, PLACA_Y1 + 6.0, 150.0, 84.0), TILE[4], false)
	roof(b, Rect2(x0 + 190.0, PLACA_Y1 + 6.0, 180.0, 70.0), TILE[2], true)
	for i in range(3):
		_cypress(b, Vector2(x0 + 36.0, -2940.0 + float(i) * 48.0), 12.0)


# The wall walk: the old city's ramparts down both sides with their towers, and
# the gardens they keep: lawns, gravel, cypress and olive, terrace walls
static func muralles(b: ShapeBatch, edge: Callable) -> void:
	var top := GATE - 80.0
	var bot := PLACA_Y1
	for side: float in [-1.0, 1.0]:
		var far := FAR_L if side < 0.0 else FAR_R
		# the cross wall that shuts the town off from its gardens
		var cw := Rect2(FAR_L, bot - 34.0, 330.0 - FAR_L, 34.0) if side < 0.0 else Rect2(950.0, bot - 34.0, FAR_R - 950.0, 34.0)
		var y := top
		while y < bot - 1.0:
			var yn := minf(y + 24.0, bot)
			b.quad(Vector2(edge.call(y, side), y), Vector2(far, y), Vector2(far, yn), Vector2(edge.call(yn, side), yn), LAWN)
			y = yn
		var in_x := 340.0 if side < 0.0 else 940.0
		# the lawn, mown soft and dark in patches
		for i in range(16):
			var gp := Vector2(lerpf(in_x + side * 60.0, far, _h(i * 11 + int(side) * 3 + 500)), lerpf(top, bot, _h(i * 7 + int(side) * 5 + 900)))
			b.glow(gp, 120.0 + 90.0 * _h(i), Color(LAWN_LIT if i % 2 == 0 else LAWN_DK, 0.5))
		# a gravel walk along it and the terrace walls across
		var wx := in_x + side * 150.0
		b.rect(Rect2(wx - 26.0, top, 52.0, bot - top), Color(0.46, 0.42, 0.36))
		b.rect(Rect2(wx - 22.0, top, 44.0, bot - top), Color(0.52, 0.48, 0.41))
		var ty := top + 120.0
		var n := 0
		while ty < bot - 40.0:
			var x0 := minf(in_x + side * 30.0, far)
			var wall := Rect2(x0, ty, absf(far - in_x) - 30.0, 13.0)
			if side < 0.0:
				wall.position.x = far
			b.rect(Rect2(wall.position + Vector2(0.0, 12.0), Vector2(wall.size.x, 12.0)), Color(SHADOW, 0.30))
			b.rect(wall, STONE_DK)
			b.rect(Rect2(wall.position + Vector2(0.0, 2.0), Vector2(wall.size.x, 5.0)), STONE)
			b.rect(Rect2(wx - 20.0, ty - 4.0, 40.0, 22.0), STONE)
			for q in range(3):
				b.line(Vector2(wx - 20.0, ty + 2.0 + float(q) * 6.0), Vector2(wx + 20.0, ty + 2.0 + float(q) * 6.0), STONE_DK, 1.6)
			for s: float in [-1.0, 1.0]:
				for q in range(8):
					var fp := Vector2(wx + s * 34.0, ty - 34.0 - 17.0 * float(q))
					b.circle(fp, 8.0, LEAF)
					b.circle(fp + Vector2(2.0, -2.0), 3.0, _pick(FLOWERS, q + n * 7 + int(s)))
					b.circle(fp + Vector2(-3.0, 2.0), 2.6, _pick(FLOWERS, q * 3 + n))
			for q in range(7):
				var bp := Vector2(lerpf(in_x + side * 60.0, far, (float(q) + 0.5 * _h(q + n)) / 7.0), ty - 46.0 - 60.0 * _h(q * 5 + n))
				if absf(bp.x - wx) < 66.0:
					continue
				if (q + n) % 3 == 0:
					_bush(b, bp, 22.0 + 8.0 * _h(q + n * 3), q + n)
				else:
					_cypress(b, bp, 13.0 + 4.0 * _h(q))
			ty += 230.0
			n += 1
		b.rect(Rect2(cw.position - Vector2(0.0, 14.0), Vector2(cw.size.x, 14.0)), SHADOW)
		b.rect(cw, STONE_DK)
		b.rect(cw.grow_individual(0.0, -4.0, 0.0, -10.0), STONE)
		var cx := cw.position.x + 8.0
		while cx < cw.end.x - 18.0:
			b.rect(Rect2(cx, cw.end.y - 15.0, 18.0, 13.0), STONE_DK)
			b.rect(Rect2(cx + 1.5, cw.end.y - 13.5, 13.0, 9.0), STONE_LIT)
			cx += 34.0
		# the rampart: the walk's own wall, its crenels, a round tower now and then
		var w0 := 340.0 if side < 0.0 else 882.0
		var wr := Rect2(w0, -4860.0, 58.0, 820.0)
		b.rect(Rect2(wr.position + Vector2(side * 16.0 + 6.0, 10.0), wr.size), Color(SHADOW, 0.34))
		b.rect(wr, STONE_DK)
		b.rect(wr.grow_individual(-5.0, 0.0, -5.0, 0.0), STONE)
		var jy := wr.position.y
		var jn := 0
		while jy < wr.end.y:
			b.line(Vector2(wr.position.x + 5.0, jy), Vector2(wr.end.x - 5.0, jy), JOINT, 1.4)
			b.line(Vector2(wr.position.x + 16.0 + 22.0 * float(jn % 2), jy), Vector2(wr.position.x + 16.0 + 22.0 * float(jn % 2), jy + 22.0), JOINT, 1.4)
			if _h(jn * 3 + int(side) + 40) < 0.2:
				b.ellipse(Vector2(wr.get_center().x + 12.0 * (_h(jn) - 0.5), jy + 10.0), 12.0, 6.0, Color(MOSS, 0.6))
			jy += 22.0
			jn += 1
		var mx := wr.position.x if side < 0.0 else wr.end.x - 13.0
		var my := wr.position.y + 6.0
		while my < wr.end.y - 14.0:
			b.rect(Rect2(mx + 2.0, my + 3.0, 13.0, 18.0), SHADOW)
			b.rect(Rect2(mx, my, 13.0, 18.0), STONE_DK)
			b.rect(Rect2(mx + 1.5, my + 1.5, 10.0, 12.0), STONE_LIT)
			my += 34.0
		for ty2: float in [-4780.0, -4430.0, -4100.0]:
			var tp := Vector2(wr.get_center().x + side * 34.0, ty2)
			b.circle(tp + Vector2(12.0, 18.0), 54.0, Color(SHADOW, 0.32))
			b.circle(tp, 50.0, STONE_DK)
			b.circle(tp, 46.0, STONE)
			b.circle(tp, 33.0, STONE_DK)
			b.circle(tp, 30.0, STONE.darkened(0.14))
			for q in range(12):
				var d := Vector2.from_angle(float(q) * TAU / 12.0)
				b.circle(tp + d * 43.0, 6.4, STONE_DK)
				b.circle(tp + d * 43.0 - Vector2(1.2, 1.2), 4.6, STONE_LIT)
			b.circle(tp + Vector2(-6.0, 4.0), 8.0, DARK)


# --- the path's own stone ------------------------------------------------------------

# A kerb along both edges of the path, following them: it covers the sawn ends
# of the paving where the path bends in or out
static func kerbs(wc: ShapeBatch, a: float, z: float, edge: Callable) -> void:
	for side: float in [-1.0, 1.0]:
		var y := a
		while y < z - 0.5:
			var yn := minf(y + 13.0, z)
			var x0: float = edge.call(y, side)
			var x1: float = edge.call(yn, side)
			wc.quad(Vector2(x0 - side * 13.0, y), Vector2(x0, y), Vector2(x1, yn), Vector2(x1 - side * 13.0, yn), STONE_DK)
			wc.quad(Vector2(x0 - side * 11.0, y), Vector2(x0 - side * 3.0, y), Vector2(x1 - side * 3.0, yn), Vector2(x1 - side * 11.0, yn), STONE.darkened(0.10))
			y = yn
		y = floorf(a / 39.0) * 39.0
		while y < z:
			if y >= a:
				var x0: float = edge.call(y, side)
				wc.line(Vector2(x0 - side * 11.0, y), Vector2(x0 - side * 2.0, y), JOINT, 1.4)
			y += 39.0


# The square's own paving: rings of cobbles round the lioness, a spoked rose,
# the drain that carries the rain off to the parapet
static func placa_rose(wc: ShapeBatch, c: Vector2) -> void:
	wc.circle(c, 158.0, Color(STONE_DK, 0.85))
	wc.circle(c, 152.0, Color(0.50, 0.48, 0.50))
	for ring in range(5):
		var r := 144.0 - float(ring) * 21.0
		var n := int(TAU * r / 19.0)
		for i in range(n):
			var a := TAU * (float(i) + 0.5 * float(ring % 2)) / float(n)
			var d := Vector2.from_angle(a)
			var s := d.orthogonal()
			var g := _h(ring * 71 + i * 13)
			var col := Color(0.46, 0.44, 0.46).lerp(Color(0.66, 0.62, 0.58), g)
			var p := c + d * r
			wc.quad(p - d * 8.6 - s * 7.6, p + d * 8.6 - s * 8.6, p + d * 8.6 + s * 8.6, p - d * 8.6 + s * 7.6, col)
	for i in range(8):
		var d := Vector2.from_angle(float(i) * TAU / 8.0)
		wc.line(c + d * 52.0, c + d * 152.0, Color(STONE_LIT, 0.55), 5.0)
	var y := c.y + 6.0
	wc.line(Vector2(332.0, y), Vector2(c.x - 158.0, y), Color(0.16, 0.16, 0.20, 0.7), 9.0)
	wc.line(Vector2(332.0, y - 5.0), Vector2(c.x - 158.0, y - 5.0), Color(STONE_LIT, 0.35), 1.6)


# a puddle lying in a low place, the lamps and the sky in it
static func puddle(wc: ShapeBatch, p: Vector2, rx: float, ry: float, warm: float) -> void:
	for o: Array in [[Vector2.ZERO, 1.0, 1.0], [Vector2(rx * 0.55, ry * 0.35), 0.6, 0.7], [Vector2(-rx * 0.6, -ry * 0.2), 0.55, 0.6]]:
		wc.ellipse(p + (o[0] as Vector2), rx * float(o[1]), ry * float(o[2]), Color(0.36, 0.42, 0.52, 0.30))
	wc.ellipse(p - Vector2(rx * 0.08, ry * 0.12), rx * 0.80, ry * 0.66, Color(0.62, 0.68, 0.78, 0.20))
	wc.ellipse(p - Vector2(rx * 0.24, ry * 0.30), rx * 0.36, ry * 0.18, Color(0.94, 0.95, 0.98, 0.30))
	if warm > 0.02:
		wc.glow(p + Vector2(rx * 0.2, 0.0), rx * 0.8, Color(LIT, 0.24 * warm))


# what Temps de Flors leaves on the steps: pots up both sides, and the petals
# the rain has brought down
static func step_flowers(wc: ShapeBatch, edge: Callable, top: float, bot: float) -> void:
	var y := top + 20.0
	var i := 0
	while y < bot:
		for side: float in [-1.0, 1.0]:
			var x: float = edge.call(y, side)
			_pot(wc, Vector2(x + side * 8.0, y + 12.0 * side), i * 3 + int(side))
			if i % 2 == 0:
				_pot(wc, Vector2(x + side * 9.0, y + 12.0 * side + 13.0), i * 5 + int(side))
		y += 66.0
		i += 1
	for q in range(70):
		var py := lerpf(top, bot, _h(q * 3 + 11))
		var l: float = edge.call(py, -1.0)
		var r: float = edge.call(py, 1.0)
		var u := _h(q * 7 + 5)
		u = u * u * 0.4 if q % 2 == 0 else 1.0 - u * u * 0.4
		wc.ellipse(Vector2(lerpf(l + 18.0, r - 18.0, u), py), 2.4, 1.5, Color(_pick(FLOWERS, q), 0.8))
