class_name Mercat
extends RefCounted

# El Mercat's furniture beyond the stall blocks (#153): the floor drain in
# the middle aisle, the fish counter drawn as a counter, what stands along
# the hall's walls between the wall stalls, and the approach street outside
# the arch. Level space throughout: the market is not fitted to a corridor.
# Everything here is static; what is solid is listed by solids(), which
# level_build turns into bodies and bypasser blockers.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := [
	"draw_column", "draw_edge_layer", "draw_freedom_beyond", "draw_live",
	"draw_over_walkway", "draw_overhead", "draw_stall", "draw_threshold", "draw_van", "draw_yard", "surface",
]
const SOFT_WEAR := true


const LevelBuild := preload("res://world/level_build.gd")
const Surfaces := preload("res://world/surfaces.gd")
const Gotic := preload("res://world/gotic.gd")
const WALL_D := 24.0
const HALL_ROOF_W := 240.0
const STREET_SLAB_W := 80.0
const STREET_SLAB_H := 56.0
const PLACA_PAVE := Color(0.66, 0.60, 0.52)
const PLACA_JOINT := Color(0.56, 0.50, 0.43, 0.5)
const STREET_PAVE := Color(0.71, 0.67, 0.60)
const STREET_DOORS: Array = [
	[-30.0, -1.0], [140.0, -1.0], [-270.0, 1.0], [10.0, 1.0],
	[-4910.0, -1.0], [-4910.0, 1.0],
]
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
# (kept clear of the walk's name on the ground by the start, main.NAME_Y)
const APPROACH_CRATES: Array[Vector2] = [Vector2(426.0, -190.0), Vector2(856.0, -110.0), Vector2(858.0, -260.0)]
const APPROACH_CRATE_SIZE := Vector2(44.0, 40.0)
# [north y, south y, west side?, stripe colour]
const AWNINGS: Array = [
	[-230.0, -110.0, true, 0], [-510.0, -400.0, true, 1],
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


# The plaça past the hall is paved stone from wall to wall, not the lawn a
# park's dog run would be: only the earth of its tree pits, planters and
# shrubs is soft. The hall itself falls through to main.
static func surface(m: Node2D, p: Vector2) -> int:
	return Surfaces.paved_past_gate(m, p, LevelBuild.placa_trees(m))


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
	if m.mercat_cart != null:
		_draw_handcart(m, b, vt, vb)


static func draw_approach(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if vb < -700.0:
		return
	for i in range(APPROACH_CRATES.size()):
		var c: Vector2 = APPROACH_CRATES[i]
		if c.y < vt - 60.0 or c.y > vb + 60.0:
			continue
		draw_crate_stack(b, Rect2(c - APPROACH_CRATE_SIZE * 0.5, APPROACH_CRATE_SIZE), i + 3)
	# the awnings' shadows on the ground; the awnings themselves are
	# overhead (main.draw_overhead_piece, draw_awning)
	for i in range(AWNINGS.size()):
		var r := awning_rect(m, i)
		if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
			continue
		b.rect(Rect2(r.position + Shade.light * 18.0, r.size), SHADOW)


# where awning i hangs, out from its wall over the pavement
static func awning_rect(m: Node2D, i: int) -> Rect2:
	var aw: Array = AWNINGS[i]
	var y0 := float(aw[0])
	var y1 := float(aw[1])
	var e: Vector2 = m.walk_edges((y0 + y1) * 0.5)
	var wall: float = e.x if bool(aw[2]) else e.y
	return Rect2(minf(wall, wall + (1.0 if bool(aw[2]) else -1.0) * AWNING_DEPTH), y0, AWNING_DEPTH, y1 - y0)


# a striped shop awning out over the pavement, its scalloped edge at the
# front: overhead, above the dog, the owner and the leash
static func draw_awning(m: Node2D, b: ShapeBatch, i: int) -> void:
	var aw: Array = AWNINGS[i]
	var y0 := float(aw[0])
	var y1 := float(aw[1])
	var west := bool(aw[2])
	var aw_type := int(aw[3])
	var col: Color = AWNING_COLS[aw_type % AWNING_COLS.size()]
	var e: Vector2 = m.walk_edges((y0 + y1) * 0.5)
	var wall: float = e.x if west else e.y
	var out := 1.0 if west else -1.0
	var front: float = wall + out * AWNING_DEPTH
	var x0 := minf(wall, front)

	if aw_type == 1:
		# corrugated zinc / galvanized sheet canopy
		b.rect(Rect2(x0, y0, AWNING_DEPTH, y1 - y0), Color(0.68, 0.70, 0.72))
		var fl: float = y0 + 3.0
		while fl < y1 - 2.0:
			b.line(Vector2(x0, fl), Vector2(x0 + AWNING_DEPTH, fl), Color(0.52, 0.54, 0.56), 1.5)
			b.line(Vector2(x0, fl + 1.5), Vector2(x0 + AWNING_DEPTH, fl + 1.5), Color(0.82, 0.84, 0.86), 1.0)
			fl += 6.0
		b.rect(Rect2(minf(front - 2.0, front), y0, 3.0, y1 - y0), Color(0.48, 0.50, 0.52))
		var rv: float = y0 + 6.0
		while rv < y1 - 4.0:
			b.circle(Vector2(front - out * 1.5, rv), 1.2, Color(0.88, 0.90, 0.92))
			rv += 16.0
	elif aw_type == 2:
		# dark green grocer/bakery canvas canopy with gold trim
		b.rect(Rect2(x0, y0, AWNING_DEPTH, y1 - y0), Color(0.18, 0.38, 0.24))
		b.rect(Rect2(minf(front - 4.0, front), y0, 4.0, y1 - y0), Color(0.14, 0.30, 0.18))
		b.line(Vector2(front, y0), Vector2(front, y1), Color(0.92, 0.82, 0.38), 2.0)
		var y := y0
		while y < y1:
			b.line(Vector2(x0, y), Vector2(front, y), Color(0.14, 0.30, 0.18), 1.5)
			y += 24.0
	else:
		# classical striped canvas awning with scalloped valance
		var y := y0
		var k := 0
		while y < y1:
			var h := minf(12.0, y1 - y)
			b.rect(Rect2(x0, y, AWNING_DEPTH, h), col if k % 2 == 0 else AWNING_CANVAS)
			b.circle(Vector2(front, y + h * 0.5), h * 0.5, (col if k % 2 == 0 else AWNING_CANVAS).darkened(0.08))
			y += 12.0
			k += 1

	# the roller box along the wall, and the fold lit along the top
	b.rect(Rect2(wall - (6.0 if west else 0.0), y0, 6.0, y1 - y0), Color(0.30, 0.28, 0.26))
	b.line(Vector2(wall + out * 8.0, y0), Vector2(wall + out * 8.0, y1), Color(1, 1, 1, 0.18), 2.0)


# wooden fruit crates and plastic ones, two high, the top one set back so
# the stack has height
static func draw_crate_stack(b: ShapeBatch, r: Rect2, seed: int) -> void:
	b.rect(Rect2(r.position + Shade.light * 12.0, r.size), SHADOW)
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
	var top := Rect2(r.position + Vector2(4.0, 4.0 + (r.size.y * 0.18 if long_y else 0.0)) - Shade.light * 5.0,
		Vector2(r.size.x - 8.0, (r.size.y * 0.5 if long_y else r.size.y) - 6.0))
	b.rect(Rect2(top.position + Shade.light * 4.0, top.size), Color(0.05, 0.05, 0.08, 0.22))
	_crate(b, top, CRATE_PLASTIC[(seed + 2) % CRATE_PLASTIC.size()].lightened(0.08), seed % 2 == 0, seed + 5)


static func _crate(b: ShapeBatch, cr: Rect2, col: Color, full: bool, seed: int) -> void:
	b.rect(cr, col.darkened(0.28))
	b.rect(cr.grow(-2.5), col.darkened(0.12) if full else col.darkened(0.40))
	if full:
		var mode: int = seed % 4
		if mode == 1:
			# fresh catch on crushed ice bed: silver fish, prawns, lemon
			b.rect(cr.grow(-3.0), Color(0.82, 0.90, 0.94))
			var fx := cr.position.x + 8.0
			while fx < cr.end.x - 6.0:
				var fy := cr.position.y + 7.0
				while fy < cr.end.y - 6.0:
					b.line(Vector2(fx - 4.0, fy), Vector2(fx + 4.0, fy), Color(0.50, 0.64, 0.72), 2.5)
					b.circle(Vector2(fx + 3.0, fy), 1.4, Color(0.78, 0.88, 0.94))
					fy += 9.0
				fx += 11.0
			b.circle(Vector2(cr.end.x - 7.0, cr.end.y - 7.0), 3.0, Color(0.96, 0.86, 0.22))
		elif mode == 2:
			# bakery / pa de pagès: crusty loaves and baguettes
			b.rect(cr.grow(-3.0), Color(0.48, 0.36, 0.24))
			var bx := cr.position.x + 8.0
			while bx < cr.end.x - 5.0:
				var by := cr.position.y + 8.0
				while by < cr.end.y - 5.0:
					b.circle(Vector2(bx, by), 4.2, Color(0.76, 0.54, 0.30))
					b.circle(Vector2(bx - 1.0, by - 1.0), 2.2, Color(0.92, 0.88, 0.80))
					by += 10.0
				bx += 11.0
		elif mode == 3:
			# verdures / vegetables: purple artichokes and calçots
			b.rect(cr.grow(-3.0), Color(0.38, 0.28, 0.18))
			var vx := cr.position.x + 7.0
			while vx < cr.end.x - 5.0:
				var vy := cr.position.y + 7.0
				while vy < cr.end.y - 5.0:
					b.circle(Vector2(vx, vy), 4.0, Color(0.38, 0.52, 0.30))
					b.circle(Vector2(vx + 1.0, vy - 1.0), 2.2, Color(0.56, 0.32, 0.48))
					vy += 9.0
				vx += 10.0
		else:
			# classic orchard fruit: oranges, lemons, apples
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
	b.rect(Rect2(c + Vector2(-9.0, -11.0) + Shade.light * 7.0, Vector2(18.0, 22.0)), SHADOW)
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
	b.rect(Rect2(r.position + Shade.light * 9.0, r.size), SHADOW)
	# the frame: two rails from the wheels at the wall end out to the handles
	var base_x := c.x - out * 13.0
	for ry: float in [-12.0, 12.0]:
		b.line(Vector2(base_x, c.y + ry), Vector2(c.x + out * 15.0, c.y + ry * 0.8), Color(0.20, 0.30, 0.46), 2.4)
		b.rect(Rect2(base_x - 3.0, c.y + ry - 5.0 + (ry * 0.6), 6.0, 10.0), Color(0.10, 0.10, 0.12))
	b.line(Vector2(base_x, c.y - 14.0), Vector2(base_x, c.y + 14.0), Color(0.36, 0.36, 0.38), 3.0)
	_crate(b, Rect2(c.x - 11.0, c.y - 14.0, 22.0, 28.0), CRATE_WOOD, true, seed)
	_crate(b, Rect2(c.x - 9.0 - Shade.light.x * 3.0, c.y - 12.0 - Shade.light.y * 3.0, 18.0, 22.0),
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


# A wall stall, its back to the hall wall and its counter to the aisle, laid
# out as its trade, with its customers queueing at the counter. One batch.
static func draw_stall(m: Node2D, st: Vector2, kind: String, i: int) -> void:
	var b := ShapeBatch.new()
	var r := Rect2(st.x - m.STALL_BODY_SIZE.x * 0.5, st.y - m.STALL_BODY_SIZE.y * 0.5, m.STALL_BODY_SIZE.x, m.STALL_BODY_SIZE.y)
	var aisle_right := st.x < 640.0
	m.box_shadow(b, r, 5.0, 12.0)
	if kind == "fish":
		draw_fish_counter(b, r, aisle_right, i)
	else:
		_counter(b, r, aisle_right, kind, i)
	m._draw_browsers(b, r, i)
	b.flush(m._wc)


# the counter: a dark back shelf against the wall, the display, and a lit
# lip along the customer's edge
static func _counter(b: ShapeBatch, r: Rect2, aisle_right: bool, kind: String, i: int) -> void:
	var wood := Color(0.50, 0.36, 0.24)
	b.rect(r, wood.darkened(0.30))
	b.rect(r.grow(-2.0), wood)
	var shelf := Rect2(r.position.x + 2.0 if aisle_right else r.end.x - 18.0, r.position.y + 2.0, 16.0, r.size.y - 4.0)
	b.rect(shelf, wood.darkened(0.42))
	var disp := Rect2(shelf.end.x + 2.0 if aisle_right else r.position.x + 4.0, r.position.y + 4.0, r.size.x - 24.0, r.size.y - 8.0)
	var lip_x: float = r.end.x - 3.0 if aisle_right else r.position.x + 1.0
	match kind:
		"fruit":
			# raked crates, two rows of three, each its own fruit
			for k in range(6):
				var cr := Rect2(disp.position.x + float(k % 3) * disp.size.x / 3.0, disp.position.y + float(k / 3) * disp.size.y * 0.5,
					disp.size.x / 3.0, disp.size.y * 0.5).grow(-1.0)
				b.rect(cr, CRATE_WOOD.darkened(0.25))
				var fc: Color = PRODUCE[(k + i) % PRODUCE.size()]
				var fy := cr.position.y + 5.0
				while fy < cr.end.y - 3.0:
					var fx := cr.position.x + 5.0
					while fx < cr.end.x - 3.0:
						b.circle(Vector2(fx, fy), 3.4, fc)
						b.circle(Vector2(fx - 1.0, fy - 1.1), 1.1, fc.lightened(0.35))
						fx += 7.0
					fy += 7.0
			# the bottles of the wall shelf: oil and wine
			for k in range(4):
				b.circle(shelf.position + Vector2(8.0, 7.0 + float(k) * 13.0), 3.0, [Color(0.34, 0.46, 0.16), Color(0.42, 0.10, 0.14)][k % 2])
		"juice":
			# the juice bar: rows of cups in every colour on the ice, fruit halves behind
			b.rect(disp, Color(0.86, 0.92, 0.94))
			var juices := [Color(0.96, 0.42, 0.56), Color(0.98, 0.62, 0.16), Color(0.52, 0.78, 0.26), Color(0.86, 0.16, 0.22),
				Color(0.98, 0.86, 0.30), Color(0.56, 0.26, 0.52)]
			for k in range(15):
				var cp := disp.position + Vector2(7.0 + float(k % 5) * (disp.size.x - 12.0) / 4.0, 8.0 + float(k / 5) * (disp.size.y - 14.0) / 2.0)
				var jc: Color = juices[(k + i) % juices.size()]
				b.circle(cp, 4.4, Color(0.96, 0.97, 0.98))
				b.circle(cp, 3.4, jc)
				b.circle(cp + Vector2(-1.0, -1.0), 1.0, jc.lightened(0.4))
			for k in range(3):
				var hp := shelf.position + Vector2(8.0, 9.0 + float(k) * 17.0)
				b.circle(hp, 5.5, [Color(0.36, 0.24, 0.16), Color(0.30, 0.56, 0.22), Color(0.96, 0.56, 0.12)][k])
				b.circle(hp, 3.6, [Color(0.96, 0.95, 0.90), Color(0.92, 0.32, 0.30), Color(0.99, 0.80, 0.40)][k])
		"jamon":
			# legs of ham hung along the wall, one on its stand being carved, and paper cones of slices
			for k in range(4):
				var hp := shelf.position + Vector2(8.0, 7.0 + float(k) * 14.0)
				_ham(b, hp, Vector2.RIGHT if aisle_right else Vector2.LEFT, 0.7)
			var board := Rect2(disp.position.x + 4.0, disp.position.y + 4.0, disp.size.x * 0.6, 18.0)
			b.rect(board, Color(0.70, 0.52, 0.32))
			_ham(b, board.get_center(), Vector2.LEFT if aisle_right else Vector2.RIGHT, 1.0)
			for k in range(4):
				var cp := Vector2(disp.position.x + 10.0 + float(k) * 14.0, disp.end.y - 12.0)
				b.polygon(PackedVector2Array([cp + Vector2(-5.0, -5.0), cp + Vector2(5.0, -5.0), cp + Vector2(0.0, 7.0)]), Color(0.96, 0.94, 0.88))
				b.circle(cp + Vector2(0.0, -3.5), 3.6, Color(0.76, 0.26, 0.26))
		"olives":
			# steel trays of olives, pickles and peppers, three by two
			var olive := [Color(0.42, 0.50, 0.18), Color(0.14, 0.10, 0.12), Color(0.56, 0.62, 0.26), Color(0.62, 0.30, 0.38),
				Color(0.80, 0.22, 0.14), Color(0.70, 0.66, 0.30)]
			for k in range(6):
				var tr := Rect2(disp.position.x + float(k % 3) * disp.size.x / 3.0, disp.position.y + float(k / 3) * disp.size.y * 0.5,
					disp.size.x / 3.0, disp.size.y * 0.5).grow(-1.5)
				b.rect(tr, Color(0.70, 0.73, 0.76))
				b.rect(tr.grow(-1.5), olive[(k + i) % olive.size()].darkened(0.35))
				for n in range(7):
					var op := tr.position + Vector2(3.5 + fmod(float(n) * 7.3 + float(k) * 3.1, tr.size.x - 7.0), 3.5 + fmod(float(n) * 5.1, tr.size.y - 7.0))
					b.circle(op, 2.3, olive[(k + i) % olive.size()])
			for k in range(3):
				b.circle(shelf.position + Vector2(8.0, 10.0 + float(k) * 17.0), 5.0, Color(0.88, 0.90, 0.86, 0.85))
		_:
			# sweets: trays of jellies and wrapped sweets, jars on the shelf
			var sweet := [Color(0.98, 0.36, 0.52), Color(0.36, 0.72, 0.96), Color(0.98, 0.84, 0.24), Color(0.48, 0.82, 0.38),
				Color(0.96, 0.56, 0.18), Color(0.70, 0.40, 0.86)]
			b.rect(disp, Color(0.96, 0.94, 0.90))
			for k in range(24):
				var jit := Vector2(fmod(float(k) * 5.3, 3.0) - 1.5, fmod(float(k) * 3.7, 3.0) - 1.5)
				var sp := disp.position + Vector2(5.0 + float(k % 6) * (disp.size.x - 10.0) / 5.0, 5.0 + float(k / 6) * (disp.size.y - 10.0) / 3.0) + jit
				var sc: Color = sweet[(k * 5 + i) % sweet.size()]
				if k % 3 == 0:
					b.line(sp - Vector2(3.0, 0.0), sp + Vector2(3.0, 0.0), sc.darkened(0.2), 3.0)
				b.circle(sp, 2.4, sc)
			for k in range(3):
				var jp := shelf.position + Vector2(8.0, 10.0 + float(k) * 17.0)
				b.circle(jp, 6.0, Color(0.86, 0.92, 0.96, 0.8))
				b.circle(jp, 4.0, sweet[(k * 2 + i) % sweet.size()])
	b.line(Vector2(lip_x + 1.0, r.position.y + 2.0), Vector2(lip_x + 1.0, r.end.y - 2.0), Color(1, 1, 1, 0.24), 2.4)
	b.line(Vector2(r.position.x + 2.0, r.end.y - 1.5), Vector2(r.end.x - 2.0, r.end.y - 1.5), Color(0, 0, 0, 0.26), 3.0)


# a leg of ham from above: the dark cured skin, the fat, the hoof and its cord
static func _ham(b: ShapeBatch, p: Vector2, dir: Vector2, s: float) -> void:
	var n := dir.orthogonal()
	var pts := PackedVector2Array()
	for k in range(10):
		var a := TAU * float(k) / 10.0
		var along := cos(a) * 14.0 * s
		var w := sin(a) * 6.0 * s * (0.55 + 0.45 * clampf(0.5 - along / (14.0 * s), 0.0, 1.0))
		pts.append(p + dir * along + n * w)
	b.polygon(pts, Color(0.46, 0.20, 0.14))
	b.circle(p - dir * 4.0 * s, 3.4 * s, Color(0.86, 0.62, 0.54))
	b.line(p + dir * 12.0 * s, p + dir * 17.0 * s, Color(0.24, 0.14, 0.10), 2.4 * s)


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
	b.rect(Rect2(sc - Vector2(8.0, 8.0) + Shade.light * 3.0, Vector2(16.0, 16.0)), Color(0, 0, 0, 0.20))
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
	b.rect(Rect2(body.position + Shade.light * 24.0, body.size), Color(0.05, 0.05, 0.08, 0.16))
	b.rect(Rect2(body.position + Shade.light * 14.0, body.size), Color(0.05, 0.05, 0.08, 0.14))
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


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

static func _batch_for(target: Object) -> ShapeBatch:
	if target is ShapeBatch:
		return target as ShapeBatch
	return ShapeBatch.new(target)


# Street flagstones outside the hall, indoor terrazzo bay dividers, the
# granite threshold sills under both arches, and the plaça stone-flag apron
# carrying into the gateposts (cached on ground_layer).
static func draw_over_walkway(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := _batch_for(wc)
	var gate_y: float = float(m.GATE_Y)
	var arch_y: float = LevelBuild.MERCAT_ARCH_Y
	var door_y: float = LevelBuild.MERCAT_DOOR_Y
	var y_lo := maxf(vt - 80.0, gate_y - 40.0)
	var y_hi := minf(vb + 80.0, float(m.START_Y) + 560.0)
	if y_hi <= y_lo:
		if not (wc is ShapeBatch):
			b.flush()
		return

	# 1. Plaça stone flags carried from freedomlayer's bottom (-5030) to the stone sill (-5000)
	if y_lo < gate_y and y_hi > gate_y - 40.0:
		var t0 := maxf(y_lo, gate_y - 40.0)
		var t1 := minf(y_hi, gate_y)
		var ge0: Vector2 = m.walk_edges(t0)
		var ge1: Vector2 = m.walk_edges(t1)
		var pad := 4.0 if t0 < gate_y - 30.0 else 0.0
		b.polygon(PackedVector2Array([
			Vector2(ge0.x - pad, t0), Vector2(ge0.y + pad, t0),
			Vector2(ge1.y, t1), Vector2(ge1.x, t1),
		]), PLACA_PAVE)
		var gx := 70.0 + ceilf((maxf(ge0.x, ge1.x) - 70.0) / 56.0) * 56.0
		var gx_max := minf(ge0.y, ge1.y) - 2.0
		while gx <= gx_max:
			b.line(Vector2(gx, t0), Vector2(gx, t1), PLACA_JOINT, 1.5)
			gx += 56.0

	# 2. Outdoor stone flagstones on the approach street and exit street
	if y_hi > arch_y:
		_draw_street_slabs(m, b, maxf(y_lo, arch_y), y_hi)
	if y_lo < door_y and y_hi > gate_y:
		_draw_street_slabs(m, b, maxf(y_lo, gate_y), minf(y_hi, door_y))

	# 3. Indoor terrazzo bay divider strips and aisle bands inside the hall
	if y_lo < arch_y and y_hi > door_y:
		_draw_terrazzo_bays(m, b, maxf(y_lo, door_y), minf(y_hi, arch_y))

	# 4. Wall-foot shadows cast onto the paving (west wall casts east; east wall subtle AO)
	var sy := maxf(y_lo, gate_y)
	var sh_col := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.12)
	while sy < y_hi - 0.1:
		var sy_next := minf(sy + 32.0, y_hi)
		if sy < door_y and sy_next > door_y:
			sy_next = door_y
		elif sy < arch_y and sy_next > arch_y:
			sy_next = arch_y
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sy_next)
		b.polygon(PackedVector2Array([
			Vector2(ea.x, sy), Vector2(ea.x + 12.0, sy),
			Vector2(eb.x + 12.0, sy_next), Vector2(eb.x, sy_next),
		]), sh_col)
		b.polygon(PackedVector2Array([
			Vector2(ea.y - 5.0, sy), Vector2(ea.y, sy),
			Vector2(eb.y, sy_next), Vector2(eb.y - 5.0, sy_next),
		]), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.08))
		sy = sy_next

	# 5. Projecting granite doorway steps on the outdoor street
	for d: Array in STREET_DOORS:
		var dy := float(d[0])
		if dy < y_lo - 30.0 or dy > y_hi + 30.0:
			continue
		var side := float(d[1])
		var de: Vector2 = m.walk_edges(dy)
		var wx: float = de.x if side < 0.0 else de.y
		var sx := wx if side < 0.0 else wx - 12.0
		b.rect(Rect2(sx, dy - 16.0, 12.0, 32.0), Color(0.60, 0.57, 0.52))
		var rim_x := wx + 10.0 if side < 0.0 else wx - 12.0
		b.rect(Rect2(rim_x, dy - 16.0, 2.0, 32.0), Color(0.74, 0.70, 0.64))
		var dsh_x := wx + 2.0 if side < 0.0 else wx - 14.0
		b.rect(Rect2(dsh_x, dy - 15.0, 12.0, 30.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.13))

	# 6. Dressed granite threshold sills and iron grate channels under both arches
	for ty: float in [arch_y, door_y]:
		if ty > y_lo - 44.0 and ty < y_hi + 44.0:
			_draw_arch_sill(m, b, ty)

	if not (wc is ShapeBatch):
		b.flush()


static func _draw_street_slabs(m: Node2D, b: ShapeBatch, y0: float, y1: float) -> void:
	if y1 <= y0 + 0.1:
		return
	var row := int(floorf(y0 / STREET_SLAB_H))
	var ry := float(row) * STREET_SLAB_H
	while ry < y1 - 0.1:
		var r_top := maxf(ry, y0)
		var r_bot := minf(ry + STREET_SLAB_H, y1)
		if r_bot > r_top + 0.1:
			var e0: Vector2 = m.walk_edges(r_top)
			var e1: Vector2 = m.walk_edges(r_bot)
			b.polygon(PackedVector2Array([
				Vector2(e0.x, r_top), Vector2(e0.y, r_top),
				Vector2(e1.y, r_bot), Vector2(e1.x, r_bot),
			]), STREET_PAVE)
			var off := STREET_SLAB_W * 0.5 if posmod(row, 2) == 1 else 0.0
			var in_l := maxf(e0.x, e1.x) + 2.0
			var in_r := minf(e0.y, e1.y) - 2.0
			var max_r := maxf(e0.y, e1.y)
			var rx := floorf(minf(e0.x, e1.x) / STREET_SLAB_W) * STREET_SLAB_W + off
			if r_bot - r_top >= 20.0:
				var cx := rx
				while cx < max_r:
					if cx >= in_l and cx + STREET_SLAB_W <= in_r:
						var h := Gotic.roof_hash(int(floorf(cx / STREET_SLAB_W)), row) % 11
						if h < 2:
							b.rect(Rect2(cx + 1.0, r_top + 1.0, STREET_SLAB_W - 2.0, r_bot - r_top - 2.0), STREET_PAVE.lightened(0.032))
						elif h == 2:
							b.rect(Rect2(cx + 1.0, r_top + 1.0, STREET_SLAB_W - 2.0, r_bot - r_top - 2.0), STREET_PAVE.darkened(0.035))
					cx += STREET_SLAB_W
			if absf(r_top - ry) < 0.5 and r_top > y0 + 2.0:
				b.line(Vector2(e0.x, r_top), Vector2(e0.y, r_top), Color(0, 0, 0, 0.085), 1.6)
				b.line(Vector2(e0.x, r_top + 1.5), Vector2(e0.y, r_top + 1.5), Color(1, 1, 1, 0.045), 1.0)
			var vx := rx
			while vx < max_r:
				if vx > in_l and vx < in_r:
					b.line(Vector2(vx, r_top), Vector2(vx, r_bot), Color(0, 0, 0, 0.085), 1.6)
				vx += STREET_SLAB_W
		ry += STREET_SLAB_H
		row += 1


static func _draw_terrazzo_bays(m: Node2D, b: ShapeBatch, y0: float, y1: float) -> void:
	if y1 <= y0 + 0.1:
		return
	var strip := Color(0.56, 0.51, 0.43, 0.22)
	var brass := Color(0.84, 0.76, 0.56, 0.16)
	var ty := ceilf(y0 / 150.0) * 150.0
	while ty < y1 - 1.0:
		var e: Vector2 = m.walk_edges(ty)
		b.line(Vector2(e.x + 2.0, ty), Vector2(e.y - 2.0, ty), strip, 2.0)
		b.line(Vector2(e.x + 2.0, ty + 1.5), Vector2(e.y - 2.0, ty + 1.5), brass, 1.0)
		ty += 150.0
	var straight_top := maxf(y0, LevelBuild.MERCAT_DOOR_Y + 160.0)
	var straight_bot := minf(y1, LevelBuild.MERCAT_ARCH_Y - 120.0)
	if straight_bot > straight_top:
		for lx: float in [390.0, 520.0, 760.0, 890.0]:
			b.line(Vector2(lx, straight_top), Vector2(lx, straight_bot), strip, 1.8)


static func _draw_arch_sill(m: Node2D, b: ShapeBatch, ty: float) -> void:
	var half := 36.0
	var et: Vector2 = m.walk_edges(ty - half)
	var eb: Vector2 = m.walk_edges(ty + half)
	b.polygon(PackedVector2Array([
		Vector2(et.x, ty - half), Vector2(et.y, ty - half),
		Vector2(eb.y, ty + half), Vector2(eb.x, ty + half),
	]), Color(0.64, 0.60, 0.54))
	# Outer dressed granite border courses visible either side of the 52 px arch
	var et_in: Vector2 = m.walk_edges(ty - 26.0)
	var eb_in: Vector2 = m.walk_edges(ty + 26.0)
	b.polygon(PackedVector2Array([
		Vector2(et.x, ty - half), Vector2(et.y, ty - half),
		Vector2(et_in.y, ty - 26.0), Vector2(et_in.x, ty - 26.0),
	]), Color(0.68, 0.64, 0.57))
	b.polygon(PackedVector2Array([
		Vector2(eb_in.x, ty + 26.0), Vector2(eb_in.y, ty + 26.0),
		Vector2(eb.y, ty + half), Vector2(eb.x, ty + half),
	]), Color(0.60, 0.56, 0.50))
	var x0 := maxf(et.x, eb.x) + 4.0
	var x1 := minf(et.y, eb.y) - 4.0
	var sx := x0 + 36.0
	while sx < x1 - 4.0:
		b.line(Vector2(sx, ty - half), Vector2(sx, ty + half), Color(0.46, 0.43, 0.38, 0.55), 1.5)
		sx += 36.0
	b.line(Vector2(et.x, ty - half), Vector2(et.y, ty - half), Color(0.78, 0.74, 0.67), 2.0)
	b.line(Vector2(eb.x, ty + half), Vector2(eb.y, ty + half), Color(0, 0, 0, 0.18), 2.0)
	var em: Vector2 = m.walk_edges(ty)
	b.line(Vector2(em.x + 2.0, ty), Vector2(em.y - 2.0, ty), Color(0.24, 0.24, 0.26), 3.0)


# Soldier course of granite setts laid flush against the south face of the
# stone gate sill at GATE_Y, tying the exit street into Plaça dels Gossos.
static func draw_threshold(m: Node2D, b: ShapeBatch) -> void:
	var gate_y: float = float(m.GATE_Y)
	var e: Vector2 = m.walk_edges(gate_y + 12.0)
	var y0 := gate_y + 6.0
	var h := 14.0
	b.rect(Rect2(e.x, y0, e.y - e.x, h), Color(0.56, 0.52, 0.46))
	var sx := e.x
	while sx < e.y - 2.0:
		var w := minf(22.0, e.y - sx)
		var odd := int(floorf(sx / 22.0)) % 2
		b.rect(Rect2(sx + 1.0, y0 + 1.0, w - 2.0, h - 2.0), Color(0.65, 0.61, 0.54) if odd == 0 else Color(0.61, 0.57, 0.50))
		sx += 22.0
	b.rect(Rect2(e.x, y0 + h, e.y - e.x, 3.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))


# Continuous edge layer: street-hugging old-town roofs outside the market hall,
# the glazed iron-truss hall roof cleanly bounded to MERCAT_DOOR_Y..MERCAT_ARCH_Y,
# smooth angled wall faces along the entrance/exit flares, and the north
# plaça cornice return at GATE_Y - 30.
static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b := _batch_for(c)
	var gate_top: float = float(m.GATE_Y) - 30.0
	var arch_y: float = LevelBuild.MERCAT_ARCH_Y
	var door_y: float = LevelBuild.MERCAT_DOOR_Y
	var y_lo := maxf(vt - 320.0, gate_top)
	var y_hi := vb + 320.0
	if y_hi <= y_lo:
		if not (c is ShapeBatch):
			b.flush()
		return

	var base := Color(0.44, 0.38, 0.34)
	# 1. Continuous masonry base fill following walk_edges smoothly
	var sy := y_lo
	while sy < y_hi - 0.1:
		var sy_next := minf(sy + 40.0, y_hi)
		if sy < door_y and sy_next > door_y:
			sy_next = door_y
		elif sy < arch_y and sy_next > arch_y:
			sy_next = arch_y
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sy_next)
		b.quad(Vector2(-900.0, sy), Vector2(ea.x, sy), Vector2(eb.x, sy_next), Vector2(-900.0, sy_next), base)
		b.quad(Vector2(ea.y, sy), Vector2(2200.0, sy), Vector2(2200.0, sy_next), Vector2(eb.y, sy_next), base)
		sy = sy_next

	# 2. Outer old-town roofscape (everywhere outside the hall wings)
	var hall_out_l: float = 640.0 - LevelBuild.MERCAT_HALL_HALF - WALL_D - 5.0 - HALL_ROOF_W
	var hall_out_r: float = 640.0 + LevelBuild.MERCAT_HALL_HALF + WALL_D + 5.0 + HALL_ROOF_W
	var iy0 := int(floorf((y_lo - Gotic.ROOF_Y0) / Gotic.ROOF_H))
	var iy1 := int(ceilf((y_hi - Gotic.ROOF_Y0) / Gotic.ROOF_H))
	for iy in range(iy0, iy1):
		var r0 := maxf(float(iy) * Gotic.ROOF_H + Gotic.ROOF_Y0, gate_top)
		var r1 := minf(float(iy + 1) * Gotic.ROOF_H + Gotic.ROOF_Y0, y_hi)
		if r1 - r0 < 12.0:
			continue
		# Split roof rows cleanly at door_y and arch_y so outdoor blocks never bleed into the hall
		var segs: Array[Vector2] = []
		if r0 < door_y and r1 > door_y:
			segs.append(Vector2(r0, door_y))
			segs.append(Vector2(door_y, r1))
		elif r0 < arch_y and r1 > arch_y:
			segs.append(Vector2(r0, arch_y))
			segs.append(Vector2(arch_y, r1))
		else:
			segs.append(Vector2(r0, r1))
		for seg: Vector2 in segs:
			var sa := seg.x
			var sb := seg.y
			if sb - sa < 10.0:
				continue
			var mid := (sa + sb) * 0.5
			if mid > door_y and mid < arch_y:
				_draw_roof_row(m, b, iy, -900.0, hall_out_l, sa, sb)
				_draw_roof_row(m, b, iy, hall_out_r, 2200.0, sa, sb)
			else:
				var lim_l := INF
				var lim_r := -INF
				for t: float in [0.0, 0.5, 1.0]:
					var e: Vector2 = m.walk_edges(lerpf(sa, sb, t))
					lim_l = minf(lim_l, e.x)
					lim_r = maxf(lim_r, e.y)
				_draw_roof_row(m, b, iy, -900.0, lim_l - 110.0, sa, sb)
				_draw_roof_row(m, b, iy, lim_r + 110.0, 2200.0, sa, sb)
				_draw_front_terracotta(m, b, iy, sa, sb, lim_l - 110.0, lim_r + 110.0)

	# 3. Market hall glazed iron-truss roof wings (strictly door_y .. arch_y)
	if y_lo < arch_y and y_hi > door_y:
		_draw_hall_roof_wings(m, b, maxf(y_lo, door_y), minf(y_hi, arch_y), hall_out_l, hall_out_r)

	# 4. Smooth inclined masonry wall faces and coping along walk_edges
	_draw_wall_faces(m, b, y_lo, y_hi, base)

	# 5. Recessed shop/street doorways on the outdoor stretches
	for d: Array in STREET_DOORS:
		var dy := float(d[0])
		if dy < y_lo - 40.0 or dy > y_hi + 40.0:
			continue
		var side := float(d[1])
		var wx: float = m.walk_edges(dy).x if side < 0.0 else m.walk_edges(dy).y
		b.rect(Rect2(minf(wx, wx + side * 24.0), dy - 20.0, 24.0, 40.0), Color(0.52, 0.46, 0.40))
		b.rect(Rect2(minf(wx, wx + side * 22.0), dy - 18.0, 22.0, 36.0), Color(0.22, 0.19, 0.17))
		var leaf_x := wx + side * 15.0
		b.rect(Rect2(minf(leaf_x, leaf_x + side * 7.0), dy - 15.0, 7.0, 30.0), Color(0.16, 0.12, 0.10))
		b.rect(Rect2(minf(leaf_x, leaf_x + side * 7.0), dy - 15.0, 2.0, 30.0), Color(0.30, 0.23, 0.18))
		b.circle(Vector2(leaf_x + side * 3.0, dy + 7.0), 1.6, Color(0.80, 0.70, 0.42))

	# 6. North Plaça cornice return and corner quoin piers at GATE_Y - 30
	if y_lo <= gate_top + 16.0 and y_hi >= gate_top - 4.0:
		var ge: Vector2 = m.walk_edges(float(m.GATE_Y))
		var coping_col := Color(0.70, 0.65, 0.57)
		var frieze_col := Color(0.52, 0.47, 0.40)
		var soffit_col := Color(0.32, 0.28, 0.24)
		b.rect(Rect2(-900.0, gate_top, ge.x + 900.0, 5.0), coping_col)
		b.rect(Rect2(-900.0, gate_top + 5.0, ge.x + 900.0, 5.0), frieze_col)
		b.line(Vector2(-900.0, gate_top + 10.0), Vector2(ge.x, gate_top + 10.0), soffit_col, 2.0)
		b.rect(Rect2(ge.y, gate_top, 2200.0 - ge.y, 5.0), coping_col)
		b.rect(Rect2(ge.y, gate_top + 5.0, 2200.0 - ge.y, 5.0), frieze_col)
		b.line(Vector2(ge.y, gate_top + 10.0), Vector2(2200.0, gate_top + 10.0), soffit_col, 2.0)
		b.rect(Rect2(ge.x - WALL_D - 5.0, gate_top, WALL_D + 5.0, 30.0), Color(0.60, 0.55, 0.47))
		b.rect(Rect2(ge.x - WALL_D - 2.0, gate_top + 3.0, WALL_D - 1.0, 24.0), Color(0.68, 0.63, 0.55))
		b.rect(Rect2(ge.y, gate_top, WALL_D + 5.0, 30.0), Color(0.60, 0.55, 0.47))
		b.rect(Rect2(ge.y + 3.0, gate_top + 3.0, WALL_D - 1.0, 24.0), Color(0.68, 0.63, 0.55))

	if not (c is ShapeBatch):
		b.flush()


static func _draw_roof_row(m: Node2D, b: ShapeBatch, iy: int, x_lo: float, x_hi: float, y_lo: float, y_hi: float) -> void:
	if x_hi - x_lo < 34.0 or y_hi - y_lo < 26.0:
		return
	var off := float(Gotic.roof_hash(7, iy) % int(Gotic.ROOF_W))
	var ix0 := int(floorf((x_lo - off) / Gotic.ROOF_W))
	var ix1 := int(ceilf((x_hi - off) / Gotic.ROOF_W))
	for ix in range(ix0, ix1):
		var x0 := maxf(off + float(ix) * Gotic.ROOF_W, x_lo)
		var x1 := minf(off + float(ix + 1) * Gotic.ROOF_W, x_hi)
		if x1 - x0 >= 30.0:
			Gotic.draw_block(m, b, Rect2(x0 + 2.0, y_lo + 2.0, x1 - x0 - 4.0, y_hi - y_lo - 4.0), Gotic.roof_hash(ix, iy))


static func _draw_front_terracotta(m: Node2D, b: ShapeBatch, iy: int, y0: float, y1: float, out_l: float, out_r: float) -> void:
	var tile_l: Color = Gotic.TILE[Gotic.roof_hash(iy, 11) % Gotic.TILE.size()]
	var tile_r: Color = Gotic.TILE[Gotic.roof_hash(iy, 23) % Gotic.TILE.size()]
	var sy := y0
	while sy < y1 - 0.1:
		var sy_next := minf(sy + 24.0, y1)
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sy_next)
		var in_la := ea.x - WALL_D - 5.0
		var in_lb := eb.x - WALL_D - 5.0
		var in_ra := ea.y + WALL_D + 5.0
		var in_rb := eb.y + WALL_D + 5.0
		if in_la > out_l + 4.0 and in_lb > out_l + 4.0:
			b.quad(Vector2(out_l, sy), Vector2(in_la, sy), Vector2(in_lb, sy_next), Vector2(out_l, sy_next), tile_l)
		if out_r > in_ra + 4.0 and out_r > in_rb + 4.0:
			b.quad(Vector2(in_ra, sy), Vector2(out_r, sy), Vector2(out_r, sy_next), Vector2(in_rb, sy_next), tile_r)
		sy = sy_next
	var cy := y0 + 6.0
	while cy < y1 - 1.0:
		var ec: Vector2 = m.walk_edges(cy)
		if ec.x - WALL_D - 6.0 > out_l + 2.0:
			b.line(Vector2(out_l + 2.0, cy), Vector2(ec.x - WALL_D - 6.0, cy), tile_l.darkened(0.22), 1.8)
		if out_r - 2.0 > ec.y + WALL_D + 6.0:
			b.line(Vector2(ec.y + WALL_D + 6.0, cy), Vector2(out_r - 2.0, cy), tile_r.darkened(0.22), 1.8)
		cy += 12.5
	b.line(Vector2(out_l + 4.5, y0), Vector2(out_l + 4.5, y1), tile_l.lightened(0.26), 4.0)
	b.line(Vector2(out_r - 4.5, y0), Vector2(out_r - 4.5, y1), tile_r.lightened(0.26), 4.0)


static func _draw_hall_roof_wings(m: Node2D, b: ShapeBatch, y0: float, y1: float, out_l: float, out_r: float) -> void:
	if y1 <= y0 + 0.1:
		return
	var door_y: float = LevelBuild.MERCAT_DOOR_Y
	var arch_y: float = LevelBuild.MERCAT_ARCH_Y
	var glass := Color(0.58, 0.64, 0.64)
	var sy := y0
	while sy < y1 - 0.1:
		var sy_next := minf(sy + 24.0, y1)
		var ea: Vector2 = m.walk_edges(sy)
		var eb: Vector2 = m.walk_edges(sy_next)
		b.quad(Vector2(out_l, sy), Vector2(ea.x - WALL_D - 5.0, sy),
			Vector2(eb.x - WALL_D - 5.0, sy_next), Vector2(out_l, sy_next), glass)
		b.quad(Vector2(ea.y + WALL_D + 5.0, sy), Vector2(out_r, sy),
			Vector2(out_r, sy_next), Vector2(eb.y + WALL_D + 5.0, sy_next), glass)
		sy = sy_next
	# Longitudinal iron purlins along the side bays
	var iron_dark := Color(0.50, 0.18, 0.14)
	for px: float in [80.0, 165.0]:
		b.line(Vector2(px, y0), Vector2(px, y1), iron_dark, 6.0)
		b.line(Vector2(1280.0 - px, y0), Vector2(1280.0 - px, y1), iron_dark, 6.0)
	# Transverse red iron trusses every 48 px aligned to the hall
	var iron := Color(0.56, 0.20, 0.16)
	var glint := Color(0.80, 0.86, 0.86, 0.45)
	var ty := door_y + ceilf((y0 - door_y) / 48.0) * 48.0
	while ty <= y1 + 0.5:
		var et: Vector2 = m.walk_edges(clampf(ty, door_y, arch_y))
		var lx_in := et.x - WALL_D - 5.0
		var rx_in := et.y + WALL_D + 5.0
		b.line(Vector2(out_l, ty), Vector2(lx_in, ty), iron, 5.0)
		b.line(Vector2(rx_in, ty), Vector2(out_r, ty), iron, 5.0)
		if ty + 5.0 < y1:
			b.line(Vector2(out_l, ty + 5.0), Vector2(lx_in, ty + 5.0), glint, 1.5)
			b.line(Vector2(rx_in, ty + 5.0), Vector2(out_r, ty + 5.0), glint, 1.5)
		ty += 48.0
	# Outer iron eave beams and arch-line gable headers at door_y and arch_y
	var beam := Color(0.46, 0.16, 0.13)
	b.line(Vector2(out_l + 3.0, y0), Vector2(out_l + 3.0, y1), beam, 6.0)
	b.line(Vector2(out_r - 3.0, y0), Vector2(out_r - 3.0, y1), beam, 6.0)
	for gy: float in [door_y, arch_y]:
		if gy >= y0 - 4.0 and gy <= y1 + 4.0:
			var eg: Vector2 = m.walk_edges(gy)
			b.line(Vector2(out_l, gy), Vector2(eg.x - WALL_D - 5.0, gy), beam, 7.0)
			b.line(Vector2(eg.y + WALL_D + 5.0, gy), Vector2(out_r, gy), beam, 7.0)


static func _draw_wall_faces(m: Node2D, b: ShapeBatch, y0: float, y1: float, base: Color) -> void:
	var arch_y: float = LevelBuild.MERCAT_ARCH_Y
	var door_y: float = LevelBuild.MERCAT_DOOR_Y
	var wy := y0
	while wy < y1 - 0.1:
		var wy_next := minf(wy + 24.0, y1)
		if wy < door_y and wy_next > door_y:
			wy_next = door_y
		elif wy < arch_y and wy_next > arch_y:
			wy_next = arch_y
		var ea: Vector2 = m.walk_edges(wy)
		var eb: Vector2 = m.walk_edges(wy_next)
		for i in range(6):
			var t0 := float(i) / 6.0
			var t1 := float(i + 1) / 6.0
			var lo0 := -WALL_D + WALL_D * t0
			var lo1 := -WALL_D + WALL_D * t1 + 0.6
			b.quad(Vector2(ea.x + lo0, wy), Vector2(ea.x + lo1, wy),
				Vector2(eb.x + lo1, wy_next), Vector2(eb.x + lo0, wy_next), base.darkened(0.52 - t0 * 0.34))
			var hi0 := WALL_D - WALL_D * t1 - 0.6
			var hi1 := WALL_D - WALL_D * t0
			b.quad(Vector2(ea.y + hi0, wy), Vector2(ea.y + hi1, wy),
				Vector2(eb.y + hi1, wy_next), Vector2(eb.y + hi0, wy_next), base.darkened(0.56 - t0 * 0.34))
		b.quad(Vector2(ea.x - WALL_D - 5.0, wy), Vector2(ea.x - WALL_D, wy),
			Vector2(eb.x - WALL_D, wy_next), Vector2(eb.x - WALL_D - 5.0, wy_next), base.lightened(0.30))
		b.quad(Vector2(ea.y + WALL_D, wy), Vector2(ea.y + WALL_D + 5.0, wy),
			Vector2(eb.y + WALL_D + 5.0, wy_next), Vector2(eb.y + WALL_D, wy_next), base.lightened(0.24))
		wy = wy_next


# Roofs round the plaça on freedomlayer: keep main's northern roofs, and fill
# the west and east margins past the plaça's side house fronts.
static func draw_freedom_beyond(m: Node2D, c: Object) -> void:
	m._draw_freedom_beyond(c)
	var r: Rect2 = m._freedom_rect()
	var b := _batch_for(c)
	var iy0 := int(floorf((r.position.y - 46.0 - Gotic.ROOF_Y0) / Gotic.ROOF_H))
	var iy1 := int(ceilf((r.end.y - Gotic.ROOF_Y0) / Gotic.ROOF_H))
	for iy in range(iy0, iy1):
		var y0 := maxf(float(iy) * Gotic.ROOF_H + Gotic.ROOF_Y0, r.position.y - 46.0)
		var y1 := minf(float(iy + 1) * Gotic.ROOF_H + Gotic.ROOF_Y0, r.end.y)
		if y1 - y0 >= 26.0:
			_draw_roof_row(m, b, iy, -400.0, r.position.x - 40.0, y0, y1)
			_draw_roof_row(m, b, iy, r.end.x + 40.0, 1700.0, y0, y1)
	if not (c is ShapeBatch):
		b.flush()


# Close the 70 px south-corner house fronts on the plaça's flanks where main's
# 130 px module loop stops short of GATE_Y - 30.
static func draw_yard(m: Node2D, c: Object, r: Rect2) -> void:
	var corner_y := r.end.y - 70.0
	m._draw_house_front(c, Vector2(r.position.x - 40.0, corner_y), Vector2.DOWN, Vector2.RIGHT, 70.0, 40.0, 2)
	m._draw_house_front(c, Vector2(r.end.x + 40.0, corner_y), Vector2.DOWN, Vector2.LEFT, 70.0, 40.0, 2)


# the hall's arches over the walk: MERCAT at the street end, PLAÇA at the
# square end
static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	_arch(m, c, LevelBuild.MERCAT_ARCH_Y, "MERCAT")
	_arch(m, c, LevelBuild.MERCAT_DOOR_Y, "PLAÇA")


# the hall's floor, its stall blocks and what stands along its walls, up to
# the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_floor_and_stalls(m, maxf(vt, m.GATE_Y - 30.0), vb)


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	# the hall's cast-iron columns, painted green, on a flared foot
	m.cast_shadow(wc, p, 10.0, 40.0, 0.2)
	wc.draw_circle(p, 13.0, Color(0.16, 0.26, 0.22))
	wc.draw_circle(p, 9.0, Color(0.22, 0.36, 0.30))
	wc.draw_circle(p + Vector2(-2.5, -2.5), 4.0, Color(0.36, 0.52, 0.44))


# El Mercat's arches, drawn over everyone: an iron span across the street
# with a fan of stained glass in it and the name in iron letters
static func _arch(m: Node2D, c: CanvasItem, y: float, sign: String) -> void:
	var e: Vector2 = m.walk_edges(y)
	var b := ShapeBatch.new(c)
	var r := Rect2(e.x - 40.0, y - 26.0, e.y - e.x + 80.0, 52.0)
	b.rect(Rect2(r.position + Vector2(0, 60.0), r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	b.rect(r, Color(0.46, 0.16, 0.13))
	var glass := [Color(0.86, 0.30, 0.22), Color(0.96, 0.78, 0.26), Color(0.26, 0.52, 0.72), Color(0.34, 0.62, 0.32)]
	var x := r.position.x + 10.0
	var k := 0
	while x < r.end.x - 14.0:
		b.rect(Rect2(x, y - 18.0, 20.0, 36.0), glass[k % 4])
		b.rect(Rect2(x, y - 18.0, 20.0, 5.0), Color(1, 1, 1, 0.2))
		x += 24.0
		k += 1
	b.rect(Rect2(r.position.x, y - 26.0, r.size.x, 6.0), Color(0.34, 0.12, 0.10))
	b.rect(Rect2(r.position.x, y + 20.0, r.size.x, 6.0), Color(0.34, 0.12, 0.10))
	# the name board in the middle of the span
	var nb := Rect2(r.get_center().x - 90.0, y - 16.0, 180.0, 32.0)
	b.rect(nb, Color(0.12, 0.10, 0.10))
	b.flush()
	c.draw_string(m.font, Vector2(nb.position.x, y + 8.0), sign, HORIZONTAL_ALIGNMENT_CENTER, nb.size.x, 22,
		Color(0.96, 0.86, 0.56))


static func _draw_floor_and_stalls(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var top: float = LevelBuild.MERCAT_ARCH_Y
	var bot: float = LevelBuild.MERCAT_DOOR_Y
	# terrazzo: the hall floor, chips of stone set in the pale slab
	var y0 := maxf(vt - 20.0, bot)
	var y1 := minf(vb + 20.0, top)
	var yy := floorf(y0 / 37.0) * 37.0
	while yy < y1:
		var e: Vector2 = m.walk_edges(yy)
		var xx := e.x + fmod(absf(yy) * 0.37, 29.0)
		while xx < e.y:
			var n := fmod(absf(xx * 12.9898 + yy * 78.233), 7.0)
			b.circle(Vector2(xx, yy), 1.4 + n * 0.25, [Color(0.52, 0.48, 0.44, 0.5), Color(0.66, 0.42, 0.36, 0.45),
				Color(0.40, 0.44, 0.40, 0.45)][int(n) % 3])
			xx += 29.0 + n * 3.0
		yy += 37.0
	# sawdust in front of the fish and the ham, where the floor gets swept
	for i in range(LevelBuild.MERCAT_WALL_STALLS.size()):
		var kind := String(LevelBuild.MERCAT_WALL_STALLS[i][2])
		if kind != "fish" and kind != "jamon":
			continue
		var f := LevelBuild.mercat_stall_front(m, i)
		if f.y < vt - 80.0 or f.y > vb + 80.0:
			continue
		for k in range(22):
			var sp := f + Vector2(fmod(float(k) * 37.3, 90.0) - 45.0, fmod(float(k) * 23.7, 70.0) - 35.0)
			b.circle(sp, 1.6, Color(0.86, 0.74, 0.50, 0.7))
	# the stall blocks down the middle: counters facing both aisles round a
	# back wall, each side its own trade, with its sign in Catalan
	var signs := ["VERDURES", "FORMATGES", "FRUITES", "OUS", "BACALLÀ", "ESPÈCIES", "XARCUTERIA", "BOLETS"]
	for bi in range(LevelBuild.MERCAT_BLOCKS.size()):
		var blk: Rect2 = LevelBuild.MERCAT_BLOCKS[bi]
		if blk.end.y < vt - 80.0 or blk.position.y > vb + 80.0:
			continue
		b.rect(Rect2(blk.position + Shade.light * 14.0, blk.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		b.rect(blk, Color(0.40, 0.30, 0.22))
		var mid := blk.get_center().x
		b.rect(Rect2(mid - 6.0, blk.position.y + 6.0, 12.0, blk.size.y - 12.0), Color(0.30, 0.22, 0.16))
		for side in [-1.0, 1.0]:
			var cx: float = mid + side * 50.0
			var trade := (bi * 2 + (0 if side < 0.0 else 1)) % 8
			var pal: Array = [[Color(0.34, 0.60, 0.22), Color(0.56, 0.74, 0.30), Color(0.86, 0.40, 0.20)],
				[Color(0.96, 0.84, 0.46), Color(0.92, 0.72, 0.36), Color(0.98, 0.92, 0.70)],
				[Color(0.96, 0.56, 0.12), Color(0.78, 0.14, 0.12), Color(0.96, 0.86, 0.26)],
				[Color(0.96, 0.92, 0.82), Color(0.84, 0.66, 0.46), Color(0.96, 0.92, 0.82)],
				[Color(0.88, 0.86, 0.80), Color(0.76, 0.74, 0.68), Color(0.88, 0.86, 0.80)],
				[Color(0.80, 0.36, 0.14), Color(0.92, 0.70, 0.20), Color(0.56, 0.30, 0.18)],
				[Color(0.56, 0.22, 0.18), Color(0.82, 0.46, 0.40), Color(0.92, 0.84, 0.74)],
				[Color(0.62, 0.46, 0.30), Color(0.84, 0.72, 0.52), Color(0.46, 0.34, 0.22)]][trade]
			var ty := blk.position.y + 18.0
			while ty < blk.end.y - 18.0:
				b.rect(Rect2(cx - 36.0, ty - 12.0, 72.0, 26.0), Color(0.62, 0.50, 0.36))
				for f in range(8):
					b.circle(Vector2(cx - 30.0 + float(f % 4) * 20.0, ty - 5.0 + float(f / 4) * 12.0), 5.0,
						pal[(f + int(ty)) % 3])
				ty += 34.0
		b.flush(m._wc)
		b = ShapeBatch.new()
		for side in [-1.0, 1.0]:
			var trade := (bi * 2 + (0 if side < 0.0 else 1)) % 8
			var sx: float = mid + side * 50.0
			m._wc.draw_rect(Rect2(sx - 38.0, blk.position.y - 4.0, 76.0, 16.0), Color(0.12, 0.26, 0.20))
			m._wc.draw_string(m.font, Vector2(sx - 38.0, blk.position.y + 8.0), String(signs[trade]),
				HORIZONTAL_ALIGNMENT_CENTER, 76.0, 11, Color(0.96, 0.90, 0.72))
	# the floor drain in the middle aisle
	var dr: Vector2 = LevelBuild.MERCAT_DRAIN
	if dr.y > vt - 60.0 and dr.y < vb + 60.0:
		draw_floor_drain(b, dr)
	# what stands along the walls, and the street outside the arch
	draw_hall(m, b, vt, vb)
	draw_approach(m, b, vt, vb)
	b.flush(m._wc)


# The fruit handcart crossing the aisle: wooden bed, wheels, fruit crates, porter, and dropped orange
static func _draw_handcart(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var cart: MercatCart = m.mercat_cart
	var cp := cart.pos
	if cp.y < vt - 60.0 or cp.y > vb + 60.0:
		return
	# cart shadow
	b.rect(Rect2(cp.x - 24.0 + Shade.light.x * 6.0, cp.y - 15.0 + Shade.light.y * 6.0, 48.0, 30.0), SHADOW)
	# two iron-rimmed wooden wheels
	b.rect(Rect2(cp.x - 12.0, cp.y - 18.0, 24.0, 4.0), Color(0.18, 0.19, 0.22))
	b.rect(Rect2(cp.x - 12.0, cp.y + 14.0, 24.0, 4.0), Color(0.18, 0.19, 0.22))
	b.rect(Rect2(cp.x - 10.0, cp.y - 17.0, 20.0, 2.0), Color(0.55, 0.42, 0.28))
	b.rect(Rect2(cp.x - 10.0, cp.y + 15.0, 20.0, 2.0), Color(0.55, 0.42, 0.28))
	# timber cart frame and deck
	b.rect(Rect2(cp.x - 22.0, cp.y - 13.0, 44.0, 26.0), Color(0.66, 0.50, 0.32))
	b.line(Vector2(cp.x - 22.0, cp.y - 4.0), Vector2(cp.x + 22.0, cp.y - 4.0), Color(0.52, 0.38, 0.22), 1.2)
	b.line(Vector2(cp.x - 22.0, cp.y + 5.0), Vector2(cp.x + 22.0, cp.y + 5.0), Color(0.52, 0.38, 0.22), 1.2)
	# cart handles
	b.line(Vector2(cp.x - 22.0, cp.y - 9.0), Vector2(cp.x - 34.0, cp.y - 9.0), Color(0.48, 0.34, 0.20), 2.5)
	b.line(Vector2(cp.x - 22.0, cp.y + 9.0), Vector2(cp.x - 34.0, cp.y + 9.0), Color(0.48, 0.34, 0.20), 2.5)
	# fruit crates
	_crate(b, Rect2(cp.x - 18.0, cp.y - 11.0, 18.0, 22.0), CRATE_WOOD, true, 2)
	_crate(b, Rect2(cp.x + 1.0, cp.y - 11.0, 18.0, 22.0), CRATE_WOOD, true, 4)
	# bright oranges in top layer
	for ox in [-12.0, -5.0, 6.0, 13.0]:
		for oy in [-5.0, 5.0]:
			b.circle(cp + Vector2(ox, oy), 3.0, Color(0.96, 0.56, 0.12))
	# the porter pushing the cart
	var pp := Vector2(cp.x - 34.0, cp.y)
	b.circle(pp + Shade.light * 5.0, 7.5, SHADOW)
	b.circle(pp, 7.5, Color(0.24, 0.44, 0.68))
	b.circle(pp + Vector2(2.0, 0.0), 5.5, Color(0.85, 0.72, 0.58))
	b.circle(pp + Vector2(2.5, -1.0), 4.5, Color(0.18, 0.26, 0.38))
	b.line(pp + Vector2(5.0, -1.5), pp + Vector2(7.5, 0.5), Color(0.12, 0.16, 0.24), 2.0)
	b.circle(Vector2(cp.x - 33.0, cp.y - 9.0), 2.2, Color(0.85, 0.72, 0.58))
	b.circle(Vector2(cp.x - 33.0, cp.y + 9.0), 2.2, Color(0.85, 0.72, 0.58))

	# dropped orange on the floor
	if cart.orange_dropped and not cart.orange_eaten:
		var op := cart.orange_pos
		b.circle(op + Shade.light * 2.0, 3.5, SHADOW)
		b.circle(op, 3.8, Color(0.96, 0.56, 0.12))
		b.circle(op + Vector2(-1.2, -2.0), 1.4, Color(0.32, 0.60, 0.24))
		b.circle(op + Vector2(1.0, -1.0), 1.0, Color(1.0, 0.80, 0.40))
