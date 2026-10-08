class_name Mercat
extends RefCounted

# El Mercat's furniture beyond the stall blocks (#153): the floor drain in
# the middle aisle, the fish counter drawn as a counter, what stands along
# the hall's walls between the wall stalls, and the approach street outside
# the arch. Level space throughout: the market is not fitted to a corridor.
# Everything here is static; what is solid is listed by solids(), which
# level_build turns into bodies and bypasser blockers.

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08, 0.20)

# along the hall's walls, in the stretches between the wall stalls:
# [y, west wall?, kind]
const WALL_DRESSING: Array = [
	[-1400.0, true, "shoppers"], [-1800.0, true, "trolleys"], [-2640.0, true, "crates"],
	[-2780.0, true, "shoppers"], [-3390.0, true, "crates"], [-3540.0, true, "porter"],
	[-3660.0, true, "crates"], [-4210.0, true, "crates"],
	[-1390.0, false, "crates"], [-1530.0, false, "trolleys"], [-2010.0, false, "shoppers"],
	[-2250.0, false, "crates"], [-2410.0, false, "porter"], [-2900.0, false, "crates"],
	[-3150.0, false, "shoppers"], [-3300.0, false, "crates"], [-3800.0, false, "trolleys"],
	[-4060.0, false, "crates"], [-4200.0, false, "porter"],
]
# each kind's footprint against the wall: (out from the wall, along it)
const DRESS_SIZE := {
	"crates": Vector2(52.0, 74.0), "trolleys": Vector2(30.0, 56.0),
	"shoppers": Vector2(40.0, 52.0), "porter": Vector2(34.0, 50.0),
}

# the approach street before the arch: a greengrocer's delivery van at the
# west kerb (one of main's vans, so it is solid and wraps like the others),
# crate stacks by the shop doors, and the shops' awnings
const VAN := Vector2(438.0, -300.0)
const APPROACH_CRATES: Array[Vector2] = [Vector2(426.0, -190.0), Vector2(856.0, 10.0), Vector2(858.0, -260.0)]
const APPROACH_CRATE_SIZE := Vector2(44.0, 40.0)
# [north y, south y, west side?, stripe colour]
const AWNINGS: Array = [
	[-60.0, 60.0, true, 0], [-510.0, -400.0, true, 1],
	[70.0, 180.0, false, 2], [-170.0, -50.0, false, 1], [-480.0, -360.0, false, 0],
]
const AWNING_DEPTH := 34.0
const AWNING_COLS: Array[Color] = [Color(0.18, 0.42, 0.30), Color(0.70, 0.18, 0.18), Color(0.86, 0.56, 0.16)]
const AWNING_CANVAS := Color(0.94, 0.91, 0.82)

const TARTANS: Array[Color] = [Color(0.66, 0.16, 0.18), Color(0.16, 0.30, 0.52), Color(0.24, 0.42, 0.26)]
const CRATE_WOOD := Color(0.66, 0.50, 0.32)
const CRATE_PLASTIC: Array[Color] = [Color(0.22, 0.42, 0.66), Color(0.26, 0.52, 0.34), CRATE_WOOD]
const PRODUCE: Array[Color] = [Color(0.96, 0.56, 0.12), Color(0.52, 0.72, 0.20), Color(0.78, 0.14, 0.12),
	Color(0.96, 0.86, 0.26)]


static func dress_rect(m: Node2D, i: int) -> Rect2:
	var d: Array = WALL_DRESSING[i]
	var y := float(d[0])
	var sz: Vector2 = DRESS_SIZE[String(d[2])]
	var e: Vector2 = m.walk_edges(y)
	var x0: float = e.x if bool(d[1]) else e.y - sz.x
	return Rect2(x0, y - sz.y * 0.5, sz.x, sz.y)


# everything this file adds that the dog, the owner and the passers-by have
# to go round (the van is one of main's vans and has its own body)
static func solids(m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i in range(WALL_DRESSING.size()):
		out.append(dress_rect(m, i))
	for c: Vector2 in APPROACH_CRATES:
		out.append(Rect2(c - APPROACH_CRATE_SIZE * 0.5, APPROACH_CRATE_SIZE))
	return out


# --- drawing -----------------------------------------------------------------

static func draw_hall(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	for i in range(WALL_DRESSING.size()):
		var r := dress_rect(m, i)
		if r.end.y < vt - 60.0 or r.position.y > vb + 60.0:
			continue
		var west := bool(WALL_DRESSING[i][1])
		match String(WALL_DRESSING[i][2]):
			"crates": draw_crate_stack(b, r, i)
			"trolleys": _draw_trolleys(b, r, west, i)
			"shoppers": _draw_shoppers(m, b, r, west, i)
			"porter": _draw_porter(b, r, west, i)


static func draw_approach(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if vb < -700.0:
		return
	for i in range(APPROACH_CRATES.size()):
		var c: Vector2 = APPROACH_CRATES[i]
		if c.y < vt - 60.0 or c.y > vb + 60.0:
			continue
		draw_crate_stack(b, Rect2(c - APPROACH_CRATE_SIZE * 0.5, APPROACH_CRATE_SIZE), i + 3)
	for aw: Array in AWNINGS:
		var y0 := float(aw[0])
		var y1 := float(aw[1])
		if y1 < vt - 40.0 or y0 > vb + 40.0:
			continue
		_draw_awning(m, b, y0, y1, bool(aw[2]), AWNING_COLS[int(aw[3])])


# a striped shop awning out over the pavement, its scalloped edge at the
# front and its shadow on the ground under it
static func _draw_awning(m: Node2D, b: ShapeBatch, y0: float, y1: float, west: bool, col: Color) -> void:
	var e: Vector2 = m.walk_edges((y0 + y1) * 0.5)
	var wall: float = e.x if west else e.y
	var out := 1.0 if west else -1.0
	var front: float = wall + out * AWNING_DEPTH
	var x0 := minf(wall, front)
	b.rect(Rect2(x0 + LIGHT.x * 18.0, y0 + LIGHT.y * 18.0, AWNING_DEPTH, y1 - y0), SHADOW)
	var y := y0
	var k := 0
	while y < y1:
		var h := minf(12.0, y1 - y)
		b.rect(Rect2(x0, y, AWNING_DEPTH, h), col if k % 2 == 0 else AWNING_CANVAS)
		# the scallop hanging off the front edge
		b.circle(Vector2(front, y + h * 0.5), h * 0.5, (col if k % 2 == 0 else AWNING_CANVAS).darkened(0.08))
		y += 12.0
		k += 1
	# the roller box along the wall, and the fold lit along the top
	b.rect(Rect2(wall - (6.0 if west else 0.0), y0, 6.0, y1 - y0), Color(0.30, 0.28, 0.26))
	b.line(Vector2(wall + out * 8.0, y0), Vector2(wall + out * 8.0, y1), Color(1, 1, 1, 0.18), 2.0)


# wooden fruit crates and plastic ones, two high, the top one set back so
# the stack has height
static func draw_crate_stack(b: ShapeBatch, r: Rect2, seed: int) -> void:
	b.rect(Rect2(r.position + LIGHT * 12.0, r.size), SHADOW)
	var long_y := r.size.y >= r.size.x
	var n := 2
	for k in range(n):
		var cr: Rect2
		if long_y:
			cr = Rect2(r.position.x, r.position.y + float(k) * r.size.y / float(n), r.size.x, r.size.y / float(n))
		else:
			cr = Rect2(r.position.x + float(k) * r.size.x / float(n), r.position.y, r.size.x / float(n), r.size.y)
		var col: Color = CRATE_PLASTIC[(seed + k) % CRATE_PLASTIC.size()]
		_crate(b, cr.grow(-1.0), col, (seed + k) % 3 == 0, seed + k)
	# the top tier: one crate up, nudged towards the light
	var top := Rect2(r.position + Vector2(4.0, 4.0 + (r.size.y * 0.18 if long_y else 0.0)) - LIGHT * 5.0,
		Vector2(r.size.x - 8.0, (r.size.y * 0.5 if long_y else r.size.y) - 6.0))
	b.rect(Rect2(top.position + LIGHT * 4.0, top.size), Color(0.05, 0.05, 0.08, 0.22))
	_crate(b, top, CRATE_PLASTIC[(seed + 2) % CRATE_PLASTIC.size()].lightened(0.08), seed % 2 == 0, seed + 5)


static func _crate(b: ShapeBatch, cr: Rect2, col: Color, full: bool, seed: int) -> void:
	b.rect(cr, col.darkened(0.28))
	b.rect(cr.grow(-2.5), col.darkened(0.12) if full else col.darkened(0.40))
	if full:
		var fc: Color = PRODUCE[seed % PRODUCE.size()]
		var fx := cr.position.x + 7.0
		while fx < cr.end.x - 4.0:
			var fy := cr.position.y + 7.0
			while fy < cr.end.y - 4.0:
				b.circle(Vector2(fx, fy), 3.6, fc)
				b.circle(Vector2(fx - 1.0, fy - 1.2), 1.2, fc.lightened(0.35))
				fy += 8.0
			fx += 8.0
	else:
		# an empty one: the slats of its floor
		var sx := cr.position.x + 5.0
		while sx < cr.end.x - 4.0:
			b.line(Vector2(sx, cr.position.y + 3.0), Vector2(sx, cr.end.y - 3.0), col.darkened(0.25), 1.5)
			sx += 6.0
	b.line(cr.position + Vector2(1.0, 1.0), Vector2(cr.end.x - 1.0, cr.position.y + 1.0), col.lightened(0.25), 1.6)


# two shopping trolleys (the two-wheeled tartan kind) parked by the wall
# while their owners queue at a counter
static func _draw_trolleys(b: ShapeBatch, r: Rect2, west: bool, seed: int) -> void:
	for k in range(2):
		var c := Vector2(r.get_center().x, r.position.y + r.size.y * (0.27 + 0.46 * float(k)))
		_trolley(b, c, west, TARTANS[(seed + k) % TARTANS.size()])


static func _trolley(b: ShapeBatch, c: Vector2, west: bool, col: Color) -> void:
	var out := 1.0 if west else -1.0
	b.rect(Rect2(c + Vector2(-9.0, -11.0) + LIGHT * 7.0, Vector2(18.0, 22.0)), SHADOW)
	# the wheels against the wall, the handle reaching out to the aisle
	for wy: float in [-8.0, 8.0]:
		b.rect(Rect2(c.x - out * 10.0 - 2.5, c.y + wy - 4.0, 5.0, 8.0), Color(0.10, 0.10, 0.12))
	b.line(c + Vector2(out * 6.0, -6.0), c + Vector2(out * 15.0, -5.0), Color(0.30, 0.30, 0.32), 2.0)
	b.line(c + Vector2(out * 6.0, 6.0), c + Vector2(out * 15.0, 5.0), Color(0.30, 0.30, 0.32), 2.0)
	b.line(c + Vector2(out * 15.0, -6.0), c + Vector2(out * 15.0, 6.0), Color(0.12, 0.12, 0.14), 3.0)
	# the bag, checked, with leeks sticking out of the top
	var bag := Rect2(c - Vector2(8.0, 10.0), Vector2(16.0, 20.0))
	b.rect(bag, col)
	for k in range(3):
		b.line(Vector2(bag.position.x, bag.position.y + 4.0 + float(k) * 6.0),
			Vector2(bag.end.x, bag.position.y + 4.0 + float(k) * 6.0), col.darkened(0.35), 1.4)
		b.line(Vector2(bag.position.x + 4.0 + float(k) * 4.0, bag.position.y),
			Vector2(bag.position.x + 4.0 + float(k) * 4.0, bag.end.y), Color(0.95, 0.88, 0.40, 0.55), 1.0)
	b.circle(c + Vector2(-3.0, -2.0), 3.0, Color(0.36, 0.60, 0.26))
	b.circle(c + Vector2(2.0, 1.0), 2.6, Color(0.92, 0.94, 0.86))


# two shoppers stopped for a chat by the wall, a basket on one arm
static func _draw_shoppers(m: Node2D, b: ShapeBatch, r: Rect2, west: bool, seed: int) -> void:
	var cx := r.get_center().x + (-2.0 if west else 2.0)
	var pts := [Vector2(cx, r.position.y + 13.0), Vector2(cx + (4.0 if west else -4.0), r.end.y - 13.0)]
	for k in range(2):
		var p: Vector2 = pts[k]
		var other: Vector2 = pts[1 - k]
		var face := (other - p).normalized().rotated((0.35 if west else -0.35) * (1.0 if k == 0 else -1.0))
		var h := (seed * 5 + k * 11) % 97
		b.circle(p + Vector2(3, 4), 10.0, Color(0, 0, 0, 0.16))
		HumanAppearance.draw_torso(b, p, face, Vector2(8.0, 10.5), m.BROWSER_SHIRTS[h % m.BROWSER_SHIRTS.size()])
		HumanAppearance.draw_head(b, p + face * 3.0, face, 6.0, m.BROWSER_SKIN[h % m.BROWSER_SKIN.size()],
			m.BROWSER_HAIR[(h / 3) % m.BROWSER_HAIR.size()], ["short", "bun", "curly", "long"][h % 4])
	# a wicker basket by the first one's side, bread and greens showing
	var bk: Vector2 = pts[0] + Vector2(13.0 if west else -13.0, 9.0)
	b.circle(bk + Vector2(2, 3), 7.0, Color(0, 0, 0, 0.14))
	b.circle(bk, 7.0, Color(0.62, 0.44, 0.22))
	b.circle(bk, 5.4, Color(0.74, 0.56, 0.30))
	b.line(bk + Vector2(-4.0, -2.0), bk + Vector2(3.0, 2.0), Color(0.90, 0.74, 0.44), 3.0)
	b.circle(bk + Vector2(2.0, -2.0), 2.4, Color(0.36, 0.60, 0.26))


# a porter's sack truck, left by the wall with two crates still on it
static func _draw_porter(b: ShapeBatch, r: Rect2, west: bool, seed: int) -> void:
	var out := 1.0 if west else -1.0
	var c := r.get_center()
	b.rect(Rect2(r.position + LIGHT * 9.0, r.size), SHADOW)
	# the frame: two rails from the wheels at the wall end out to the handles
	var base_x := c.x - out * 13.0
	for ry: float in [-12.0, 12.0]:
		b.line(Vector2(base_x, c.y + ry), Vector2(c.x + out * 15.0, c.y + ry * 0.8), Color(0.20, 0.30, 0.46), 2.4)
		b.rect(Rect2(base_x - 3.0, c.y + ry - 5.0 + (ry * 0.6), 6.0, 10.0), Color(0.10, 0.10, 0.12))
	b.line(Vector2(base_x, c.y - 14.0), Vector2(base_x, c.y + 14.0), Color(0.36, 0.36, 0.38), 3.0)
	_crate(b, Rect2(c.x - 11.0, c.y - 14.0, 22.0, 28.0), CRATE_WOOD, true, seed)
	_crate(b, Rect2(c.x - 9.0 - LIGHT.x * 3.0, c.y - 12.0 - LIGHT.y * 3.0, 18.0, 22.0),
		CRATE_PLASTIC[seed % CRATE_PLASTIC.size()].lightened(0.06), true, seed + 1)


# the floor drain in the middle aisle: a steel grate flush with the
# terrazzo, the floor darker where the hose water runs to it
static func draw_floor_drain(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(5.0, 7.0), 34.0, Color(0.34, 0.38, 0.42, 0.16))
	b.circle(p, 25.0, Color(0.36, 0.40, 0.44, 0.20))
	var fr := Rect2(p - Vector2(16.0, 16.0), Vector2(32.0, 32.0))
	b.rect(fr, Color(0.50, 0.52, 0.54))
	b.rect(fr.grow(-3.0), Color(0.12, 0.13, 0.14))
	for k in range(5):
		b.rect(Rect2(fr.position.x + 4.5 + float(k) * 5.0, fr.position.y + 4.0, 2.4, 24.0), Color(0.60, 0.62, 0.64))
	b.line(fr.position + Vector2(0.0, 1.0), Vector2(fr.end.x, fr.position.y + 1.0), Color(1, 1, 1, 0.30), 2.0)
	b.line(fr.position + Vector2(1.0, 0.0), Vector2(fr.position.x + 1.0, fr.end.y), Color(1, 1, 1, 0.22), 2.0)


# the fish counter: a steel counter with a glass guard along the customer's
# side, the catch laid out on banked crushed ice (whole fish, red mullet,
# prawns, mussels), lemon, price cards in the ice, and the scale on the end
static func draw_fish_counter(b: ShapeBatch, r: Rect2, aisle_right: bool, i: int) -> void:
	var fwd := Vector2.RIGHT if aisle_right else Vector2.LEFT
	b.rect(r, Color(0.44, 0.47, 0.50))
	b.rect(r.grow(-2.5), Color(0.66, 0.69, 0.72))
	var ice := r.grow(-6.0)
	b.rect(ice, Color(0.78, 0.86, 0.90))
	# banked higher at the back, so lighter there
	var back := Rect2(ice.position.x if aisle_right else ice.end.x - 26.0, ice.position.y, 26.0, ice.size.y)
	b.rect(back, Color(0.88, 0.94, 0.96))
	for k in range(30):
		var cp := ice.position + Vector2(fmod(float(k) * 29.7 + float(i) * 7.0, ice.size.x - 4.0) + 2.0,
			fmod(float(k) * 17.3, ice.size.y - 4.0) + 2.0)
		b.circle(cp, 1.1 + float(k % 3) * 0.5, Color(1, 1, 1, 0.75) if k % 2 == 0 else Color(0.70, 0.82, 0.88, 0.8))
	# whole fish at the back, heads to the customer, slightly fanned
	var bx := back.get_center().x + fwd.x * 4.0
	for k in range(4):
		var fp := Vector2(bx, ice.position.y + 6.0 + float(k) * 10.5)
		var dir := fwd.rotated((0.18 if k % 2 == 0 else -0.14))
		_fish(b, fp, dir, 26.0, 8.0, Color(0.72, 0.76, 0.80), Color(0.36, 0.44, 0.52))
	# price cards stuck in the ice beside them
	for k in range(3):
		var cp := Vector2(bx + fwd.x * 13.0, ice.position.y + 6.0 + float(k) * 14.0)
		b.rect(Rect2(cp - Vector2(4.0, 2.5), Vector2(8.0, 5.0)), Color(0.98, 0.98, 0.96))
		b.line(cp + Vector2(-2.5, 0.0), cp + Vector2(2.5, 0.0), Color(0.12, 0.12, 0.14), 1.0)
	# the front half: the scale on the front corner with a red mullet pair
	# beside it, then a tray of prawns and a tray of mussels
	var mid := ice.get_center().x + fwd.x * 2.0
	var front := ice.end.x if aisle_right else ice.position.x
	var col_a := mid + fwd.x * 10.0
	var col_b := front - fwd.x * 10.0
	for k in range(2):
		_fish(b, Vector2(col_a, ice.position.y + 6.0 + float(k) * 9.0), fwd.rotated(0.12 - 0.24 * float(k)), 17.0, 6.0,
			Color(0.88, 0.42, 0.38), Color(0.72, 0.26, 0.24))
	var sc := Vector2(col_b, ice.position.y + 9.0)
	b.rect(Rect2(sc - Vector2(8.0, 8.0) + LIGHT * 3.0, Vector2(16.0, 16.0)), Color(0, 0, 0, 0.20))
	b.rect(Rect2(sc - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), Color(0.94, 0.94, 0.92))
	b.circle(sc + Vector2(-fwd.x * 2.0, -1.5), 5.2, Color(0.54, 0.58, 0.62))
	b.circle(sc + Vector2(-fwd.x * 2.0, -1.5), 4.0, Color(0.78, 0.82, 0.86))
	b.rect(Rect2(sc.x - 5.0, sc.y + 4.0, 10.0, 3.0), Color(0.10, 0.14, 0.12))
	b.rect(Rect2(sc.x - 3.0, sc.y + 4.6, 5.0, 1.8), Color(0.40, 0.90, 0.50))
	var trays_y := ice.position.y + 21.0
	var prawns := Rect2(col_a - 9.0, trays_y, 18.0, 20.0)
	b.rect(prawns, Color(0.94, 0.96, 0.96))
	for k in range(6):
		var pp := prawns.position + Vector2(4.5 + float(k % 2) * 8.0, 4.0 + float(k / 2) * 6.0)
		b.circle(pp, 2.6, Color(0.96, 0.52, 0.36))
		b.circle(pp + Vector2(1.0, 1.2), 1.5, Color(0.98, 0.72, 0.58))
	var mussels := Rect2(col_b - 9.0, trays_y, 18.0, 20.0)
	b.rect(mussels, Color(0.94, 0.96, 0.96))
	for k in range(6):
		var mp := mussels.position + Vector2(4.5 + float(k % 2) * 8.0, 4.0 + float(k / 2) * 6.0)
		b.circle(mp, 2.8, Color(0.10, 0.12, 0.18))
		b.circle(mp + Vector2(-0.8, -0.8), 0.9, Color(0.40, 0.46, 0.60))
	# lemon halves and a sprig of parsley
	for lp: Vector2 in [Vector2(bx + fwd.x * 13.0, ice.end.y - 3.0), Vector2(mid - fwd.x * 1.0, ice.end.y - 3.0)]:
		b.circle(lp, 3.4, Color(0.98, 0.86, 0.26))
		b.circle(lp, 2.2, Color(0.99, 0.94, 0.64))
	b.circle(Vector2(mid, ice.position.y + 3.0), 2.4, Color(0.30, 0.56, 0.24))
	# the glass guard along the customer's side
	var gx: float = r.end.x - 4.0 if aisle_right else r.position.x + 1.0
	b.rect(Rect2(gx, r.position.y + 2.0, 3.0, r.size.y - 4.0), Color(0.78, 0.92, 0.98, 0.70))


static func _fish(b: ShapeBatch, p: Vector2, dir: Vector2, length: float, width: float, col: Color, back: Color) -> void:
	var n := dir.orthogonal()
	var pts := PackedVector2Array()
	for k in range(10):
		var a := TAU * float(k) / 10.0
		var along := cos(a) * length * 0.5
		# fuller at the head, tapering to the tail
		var w := sin(a) * width * 0.5 * (0.65 + 0.35 * clampf(along / (length * 0.5) + 0.6, 0.0, 1.0))
		pts.append(p + dir * along + n * w)
	b.polygon(pts, col)
	var tail := p - dir * length * 0.46
	b.polygon(PackedVector2Array([tail, tail - dir * 6.0 + n * 4.0, tail - dir * 6.0 - n * 4.0]), col.darkened(0.18))
	b.line(p + dir * length * 0.28 - n * width * 0.12, p - dir * length * 0.36 - n * width * 0.12, back, width * 0.32)
	b.line(p + dir * length * 0.30, p + dir * length * 0.30 + n * width * 0.3, col.darkened(0.3), 1.0)
	b.circle(p + dir * length * 0.36 + n * width * 0.12, 1.3, Color(0.08, 0.08, 0.10))


# the greengrocer's delivery van, nose to the hall, back doors open on the
# crates it has just unloaded
static func draw_van(m: Node2D, c: Object, v: Vector2) -> void:
	var b := ShapeBatch.new()
	var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)
	b.rect(Rect2(body.position + LIGHT * 24.0, body.size), Color(0.05, 0.05, 0.08, 0.16))
	b.rect(Rect2(body.position + LIGHT * 14.0, body.size), Color(0.05, 0.05, 0.08, 0.14))
	for w: Vector2 in [Vector2(-35, -44), Vector2(29, -44), Vector2(-35, 26), Vector2(29, 26)]:
		b.rect(Rect2(v.x + w.x, v.y + w.y, 6.0, 18.0), Color(0.10, 0.10, 0.12))
	# the back doors, swung right open
	for s: float in [-1.0, 1.0]:
		var hinge := Vector2(v.x + s * 31.0, body.end.y - 1.0)
		b.line(hinge, hinge + Vector2(s * 6.0, 28.0), Color(0.30, 0.30, 0.32), 5.0)
		b.line(hinge, hinge + Vector2(s * 6.0, 28.0), Color(0.86, 0.86, 0.82), 3.0)
	b.rect(body, Color(0.80, 0.80, 0.78))
	b.rect(body.grow(-3.0), Color(0.92, 0.92, 0.89))
	# the cab and its windscreen at the front (north)
	b.polygon(PackedVector2Array([v + Vector2(-27, -60), v + Vector2(27, -60), v + Vector2(25, -44), v + Vector2(-25, -44)]),
		Color(0.22, 0.29, 0.36))
	b.polygon(PackedVector2Array([v + Vector2(-25, -59), v + Vector2(-14, -59), v + Vector2(-19, -45), v + Vector2(-24, -45)]),
		Color(0.58, 0.68, 0.76, 0.5))
	for s: float in [-1.0, 1.0]:
		b.rect(Rect2(v.x + s * 37.0 - 3.0, v.y - 56.0, 6.0, 8.0), Color(0.24, 0.24, 0.26))
		b.circle(v + Vector2(s * 21.0, -65.0), 3.4, Color(0.98, 0.94, 0.78))
	# the box: ribs across the roof, the green livery band, a crate painted on
	for k in range(6):
		var ry := v.y - 30.0 + float(k) * 16.0
		b.line(Vector2(body.position.x + 4.0, ry), Vector2(body.end.x - 4.0, ry), Color(0.80, 0.80, 0.77), 1.6)
	b.rect(Rect2(body.position.x + 3.0, v.y - 18.0, 58.0, 30.0), Color(0.20, 0.46, 0.28))
	for k in range(3):
		b.circle(Vector2(v.x - 14.0 + float(k) * 14.0, v.y + 22.0), 5.0, PRODUCE[k])
		b.circle(Vector2(v.x - 15.0 + float(k) * 14.0, v.y + 21.0), 1.6, PRODUCE[k].lightened(0.4))
	b.flush(c)
	c.draw_string(m.font, Vector2(body.position.x + 3.0, v.y + 2.0), "FRUITES", HORIZONTAL_ALIGNMENT_CENTER, 58.0, 12,
		Color(0.96, 0.92, 0.78))
