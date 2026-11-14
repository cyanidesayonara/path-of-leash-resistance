class_name AeroportCabin
extends RefCounted

# L'Aeroport's off-leash space: the cabin of the jet at the end of the bridge,
# mid-boarding, with a dog loose in it. Seen from above with the roof off: the
# hull and its windows, three blocks of seats and two wide aisles, the bins
# along the walls, a galley forward and the lavatories aft, and the mess. The
# seats are low: she goes over them, which is the point. What is solid are the
# drinks trolleys (the space's "planter" props); bags are what she digs in,
# roller cases what she sniffs and marks, a heap of blankets the shrub.
# Static, on the cached freedom canvas; nothing here reads the clock.

const ShapeBatch := preload("res://systems/shape_batch.gd")

# the cabin's floor, to the walls she can reach (world/level_build.gd
# build_walls: x 90..1190, the top wall at GATE_Y - 650, the door sill at -30)
const X0 := 90.0
const X1 := 1190.0
const TOP_OFF := -644.0
const BOT_OFF := -30.0
const HULL := 26.0                # the wall's thickness, drawn outside the floor
const PITCH := 46.0               # seat rows, nose to tail
const SEAT_H := 30.0              # seats across a row
const ROW_X0 := 176.0
const ROWS := 20
const BUSINESS_ROWS := 3
# across the cabin, from the top wall: a block of three, an aisle, five, an
# aisle, three
const BLOCK_N := Vector2(6.0, 96.0)
const BLOCK_C := Vector2(232.0, 382.0)
const BLOCK_S := Vector2(518.0, 608.0)
# the door from the bridge, and the mat inside it where the sign's letters lie
const DOOR := Vector2(380.0, 900.0)
const MAT := Rect2(366.0, -5166.0, 548.0, 136.0)

const CARPET := Color(0.47, 0.52, 0.64)
const CARPET_DARK := Color(0.41, 0.46, 0.58)
const CARPET_FLECK := Color(0.56, 0.61, 0.72)
const MAT_COL := Color(0.20, 0.22, 0.26)
const HULL_WHITE := Color(0.95, 0.96, 0.97)
const HULL_SHADE := Color(0.80, 0.82, 0.86)
const LINER := Color(0.88, 0.87, 0.83)
const SEAT := Color(0.24, 0.34, 0.56)
const SEAT_LIGHT := Color(0.32, 0.44, 0.68)
const SEAT_BIZ := Color(0.50, 0.22, 0.26)
const SEAT_BIZ_LIGHT := Color(0.64, 0.30, 0.32)
const HEADREST := Color(0.94, 0.90, 0.80)
const ARM := Color(0.16, 0.18, 0.24)
const BIN := Color(0.90, 0.90, 0.88)
const BIN_EDGE := Color(0.70, 0.71, 0.72)
const STEEL := Color(0.66, 0.69, 0.73)
const STEEL_DARK := Color(0.40, 0.43, 0.48)
const MASK := Color(0.98, 0.84, 0.16)
const VEST := Color(0.98, 0.78, 0.10)
const JUICE := Color(0.94, 0.72, 0.30, 0.28)
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08)


static func floor_rect(m: Node2D) -> Rect2:
	var gy: float = m.GATE_Y
	return Rect2(X0, gy + TOP_OFF, X1 - X0, BOT_OFF - TOP_OFF)


static func _row_x(i: int) -> float:
	return ROW_X0 + float(i) * PITCH


# is there a seat row here? The door's vestibule has none on the south side,
# and a cross aisle runs through the centre block at the door
static func _has_block(i: int, block: int) -> bool:
	var x := _row_x(i)
	if block == 2 and x > MAT.position.x - 30.0 and x < MAT.end.x + 30.0:
		return false
	if block == 1 and x > 596.0 and x < 690.0:
		return false
	return true


# The wing on the bridge's side, drawn by the terminal's edge layer where it
# runs back over the apron below the gate (the freedom canvas hides the rest),
# and by the cabin for the other side. `sy` is -1 for the wing above the hull.
static func wing(b: ShapeBatch, root_y: float, sy: float) -> void:
	var at := func(x: float, o: float) -> Vector2: return Vector2(x, root_y + sy * o)
	var sh := LIGHT * 18.0
	var poly := PackedVector2Array([at.call(960.0, 0.0), at.call(1240.0, 0.0), at.call(1640.0, 640.0), at.call(1540.0, 646.0)])
	var shp := PackedVector2Array()
	for p: Vector2 in poly:
		shp.append(p + sh)
	b.polygon(shp, Color(SHADOW, 0.20))
	# the engine, hung ahead of the leading edge: nose cowl toward the gate
	var ec: Vector2 = at.call(1010.0, 150.0)
	var et: Vector2 = at.call(1150.0, 150.0)
	b.capsule(ec + sh, et + sh, 38.0, Color(SHADOW, 0.20))
	b.capsule(ec, et, 37.0, AeroportArt.PLANE_SHADE)
	b.polygon(poly, AeroportArt.WING)
	# flaps and slats: the panel lines a wing is made of
	b.line(at.call(1218.0, 6.0), at.call(1612.0, 636.0), AeroportArt.WING_DARK, 4.0)
	b.line(at.call(1176.0, 6.0), at.call(1584.0, 640.0), Color(AeroportArt.WING_DARK, 0.5), 1.5)
	b.line(at.call(972.0, 6.0), at.call(1546.0, 640.0), AeroportArt.PLANE_WHITE, 4.0)
	for k in range(1, 5):
		var f := float(k) / 5.0
		b.line(at.call(lerpf(960.0, 1540.0, f), 646.0 * f), at.call(lerpf(1240.0, 1640.0, f), 640.0 * f), Color(AeroportArt.WING_DARK, 0.45), 1.4)
	b.capsule(ec, at.call(1110.0, 150.0), 36.0, AeroportArt.PLANE_WHITE)
	b.capsule(ec + Vector2(0.0, -8.0), at.call(1110.0, 150.0) + Vector2(0.0, -8.0), 22.0, Color(1.0, 1.0, 1.0))
	b.circle(ec + Vector2(-4.0, 0.0), 37.0, AeroportArt.LIVERIES[0])
	b.circle(ec + Vector2(-10.0, 0.0), 30.0, AeroportArt.COCKPIT)
	# the fan: blades round the spinner, a spiral painted on it
	for k in range(12):
		var a := TAU * float(k) / 12.0
		b.line(ec + Vector2(-10.0, 0.0) + Vector2.from_angle(a) * 8.0, ec + Vector2(-10.0, 0.0) + Vector2.from_angle(a + 0.35) * 28.0, Color(0.30, 0.33, 0.38), 3.0)
	b.circle(ec + Vector2(-10.0, 0.0), 9.0, AeroportArt.STEEL)
	b.line(ec + Vector2(-10.0, 0.0), ec + Vector2(-5.0, -5.0), AeroportArt.PLANE_WHITE, 2.4)
	# the pylon up to the wing, the no-step red round the intake
	b.line(at.call(1120.0, 150.0), at.call(1200.0, 150.0), AeroportArt.WING_DARK, 10.0)
	for s: float in [-1.0, 1.0]:
		b.line(ec + Vector2(22.0, s * 37.0), ec + Vector2(60.0, s * 37.0), AeroportArt.PAINT_RED, 2.0)


static func south_wing(b: ShapeBatch, gate_y: float) -> void:
	wing(b, gate_y + BOT_OFF + HULL, 1.0)


static func draw(m: Node2D, c: Object) -> void:
	var f := floor_rect(m)
	var b := ShapeBatch.new()
	var top := f.position.y
	var bot := f.end.y
	# the apron the jet stands on, and its other wing
	AeroportArt._apron_ground(b, -400.0, 1700.0, top - 1800.0, bot + HULL + 40.0)
	b.rect(Rect2(-400.0, top - 330.0, 2100.0, 5.0), AeroportArt.PAINT_YELLOW)
	wing(b, top - HULL, -1.0)
	AeroportArt.cone(b, Vector2(900.0, top - 260.0))
	AeroportArt.cone(b, Vector2(980.0, top - 300.0))
	AeroportArt.dolly(b, Vector2(520.0, top - 150.0), 0.2, 91)
	AeroportArt.dolly(b, Vector2(566.0, top - 142.0), 0.2, 92)
	AeroportArt.tug(b, Vector2(612.0, top - 132.0), 0.2)
	AeroportArt.person(b, Vector2(450.0, top - 110.0), 1.2, AeroportArt.HIVIS, AeroportArt.pick(AeroportArt.HAIR, 3), AeroportArt.pick(AeroportArt.SKIN, 1))
	_hull(m, b, f)
	_floor(m, b, f)
	_galley(m, b, f)
	_lavatories(m, b, f)
	_seats(m, b, f)
	_bins(b, f)
	_havoc(m, b, f)
	_jump_seat(b, m.gate_bench)
	b.flush(c)
	# the place's name over the forward bulkhead, as every space has one
	c.draw_string(m.font, Vector2(0.0, top - 44.0), String(m.gate_text), HORIZONTAL_ALIGNMENT_CENTER, 1280, 22, Color(0.20, 0.22, 0.28))
	c.draw_string(m.font, Vector2(0.0, top - 26.0), "The cabin, off leash", HORIZONTAL_ALIGNMENT_CENTER, 1280, 14, Color(0.20, 0.22, 0.28, 0.8))


# the fuselage: skin, the stripe down it, the wall's inner liner, a window to
# every row with its shade somewhere between up and down
static func _hull(_m: Node2D, b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	var bot := f.end.y
	var sh := LIGHT * 18.0
	b.rect(Rect2(-400.0 + sh.x, top - HULL + sh.y, 2100.0, f.size.y + HULL * 2.0), Color(SHADOW, 0.20))
	b.rect(Rect2(-400.0, top - HULL, 2100.0, f.size.y + HULL * 2.0), HULL_SHADE)
	b.rect(Rect2(-400.0, top - HULL + 3.0, 2100.0, f.size.y + HULL * 2.0 - 8.0), HULL_WHITE)
	for wy: float in [top - HULL + 15.0, bot + HULL - 19.0]:
		b.rect(Rect2(-400.0, wy, 2100.0, 4.0), AeroportArt.LIVERIES[0])
	# past the bulkheads the hull goes on: the flight deck forward, the tail aft
	b.rect(Rect2(-400.0, top, X0 + 400.0, f.size.y), Color(0.24, 0.26, 0.30))
	b.rect(Rect2(X1, top, 600.0, f.size.y), Color(0.24, 0.26, 0.30))
	b.rect(Rect2(f.position - Vector2(6.0, 6.0), f.size + Vector2(12.0, 12.0)), LINER)
	# windows
	for i in range(-1, ROWS + 2):
		var x := _row_x(i) - 8.0
		for side in range(2):
			if side == 1 and x > DOOR.x - 30.0 and x < DOOR.y + 30.0:
				continue
			var wy := top - 14.0 if side == 0 else bot + 14.0
			b.capsule(Vector2(x - 5.0, wy), Vector2(x + 5.0, wy), 6.5, Color(0.30, 0.33, 0.38))
			b.capsule(Vector2(x - 5.0, wy), Vector2(x + 5.0, wy), 5.0, Color(0.66, 0.86, 0.98))
			var shade := AeroportArt.h(i * 2 + side + 40)
			if shade < 0.35:
				b.capsule(Vector2(x - 5.0, wy), Vector2(x + 5.0 - shade * 20.0, wy), 5.0, Color(0.92, 0.91, 0.86))
			else:
				b.circle(Vector2(x - 4.0, wy - 1.5), 1.8, Color(1.0, 1.0, 1.0, 0.9))
				# its daylight on the cabin floor
				if side == 0:
					b.band(PackedVector2Array([Vector2(x - 12.0, top), Vector2(x + 12.0, top),
						Vector2(x + 34.0, top + 92.0), Vector2(x + 62.0, top + 92.0)]), 2,
						Color(1.0, 0.97, 0.86, 0.34), PackedFloat32Array([1.0, 0.0]))


static func _floor(m: Node2D, b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	b.rect(f, CARPET)
	# the weave: a darker band under each block of seats, flecks in the aisles
	for blk: Vector2 in [BLOCK_N, BLOCK_C, BLOCK_S]:
		b.rect(Rect2(f.position.x, top + blk.x - 4.0, f.size.x, blk.y - blk.x + 8.0), CARPET_DARK)
	for k in range(260):
		var p := Vector2(f.position.x + AeroportArt.h(k * 3) * f.size.x, top + AeroportArt.h(k * 3 + 1) * f.size.y)
		AeroportArt.box(b, p, AeroportArt.h(k) * PI, 4.0, 1.0, CARPET_FLECK)
	# the floor-path lights along each aisle: follow them to an exit
	for ay: float in [BLOCK_N.y + 8.0, BLOCK_C.x - 8.0, BLOCK_C.y + 8.0, BLOCK_S.x - 8.0]:
		var x := f.position.x + 70.0
		while x < f.end.x - 60.0:
			if not (ay > BLOCK_C.y and x > MAT.position.x - 10.0 and x < MAT.end.x + 10.0 and ay > BLOCK_S.x - 20.0):
				b.rect(Rect2(x, top + ay - 1.5, 9.0, 3.0), Color(0.98, 0.90, 0.56, 0.75))
			x += 23.0
	# the mat inside the door: dark studded rubber, hazard tape at the sill.
	# The sign's letters lie on it (main.build_signs), white on dark.
	b.polygon(m.round_rect_pts(MAT.grow(5.0), 14.0), STEEL_DARK)
	b.polygon(m.round_rect_pts(MAT, 10.0), MAT_COL)
	var sx := MAT.position.x + 14.0
	while sx < MAT.end.x - 6.0:
		var sy := MAT.position.y + 12.0
		while sy < MAT.end.y - 6.0:
			b.rect(Rect2(sx, sy, 2.0, 2.0), Color(0.28, 0.30, 0.35))
			sy += 14.0
		sx += 14.0
	# the door itself: the sill plate, and the plug door swung in against the wall
	b.rect(Rect2(DOOR.x, f.end.y - 6.0, DOOR.y - DOOR.x, HULL + 12.0), STEEL)
	var hx := DOOR.x
	while hx < DOOR.y:
		b.quad(Vector2(hx, f.end.y + 6.0), Vector2(hx + 10.0, f.end.y + 6.0), Vector2(hx + 20.0, f.end.y - 6.0), Vector2(hx + 10.0, f.end.y - 6.0), AeroportArt.SIGN_INK)
		hx += 26.0
	b.rect(Rect2(DOOR.x, f.end.y - 6.0, DOOR.y - DOOR.x, 2.0), AeroportArt.PAINT_YELLOW)
	for dx: float in [DOOR.x - 26.0, DOOR.y + 4.0]:
		b.rect(Rect2(dx, f.end.y - 70.0, 22.0, 74.0), HULL_SHADE)
		b.rect(Rect2(dx + 3.0, f.end.y - 66.0, 16.0, 66.0), HULL_WHITE)
		b.capsule(Vector2(dx + 11.0, f.end.y - 46.0), Vector2(dx + 11.0, f.end.y - 36.0), 5.0, Color(0.66, 0.86, 0.98))
		b.rect(Rect2(dx + 5.0, f.end.y - 20.0, 12.0, 4.0), AeroportArt.PAINT_RED)
	# EXIT, lit green, over the door (laid flat like every sign here)
	var ex := Rect2(616.0, f.end.y - 28.0, 48.0, 15.0)
	b.glow(ex.get_center(), 40.0, Color(0.30, 0.95, 0.50, 0.25), 0.2)
	b.rect(ex, Color(0.12, 0.56, 0.30))
	b.draw_string(m.font, Vector2(ex.position.x, ex.end.y - 3.5), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, ex.size.x, 11, Color(0.96, 1.0, 0.96))


# forward: the galley across the bulkhead, the flight-deck door in the middle
static func _galley(m: Node2D, b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	var x := f.position.x
	b.rect(Rect2(x, top, 62.0, f.size.y), Color(0.36, 0.38, 0.42))
	for half in range(2):
		var y0 := top + 8.0 if half == 0 else top + f.size.y * 0.5 + 44.0
		var hgt := f.size.y * 0.5 - 52.0
		var unit := Rect2(x + 4.0, y0, 40.0, hgt)
		b.rect(Rect2(unit.position + LIGHT * 6.0, unit.size), Color(SHADOW, 0.22))
		b.rect(unit, STEEL_DARK)
		b.rect(unit.grow(-2.5), STEEL)
		# the worktop's kit: coffee pots on their plates, an oven's door, a
		# sink, the bays the trolleys came out of
		var k := 0
		var uy := unit.position.y + 14.0
		while uy < unit.end.y - 14.0:
			var cp := Vector2(unit.position.x + 14.0, uy)
			match k % 4:
				0:
					b.circle(cp, 8.0, Color(0.20, 0.20, 0.22))
					b.circle(cp, 6.0, Color(0.36, 0.22, 0.14))
					b.line(cp + Vector2(6.0, 0.0), cp + Vector2(13.0, 0.0), Color(0.16, 0.16, 0.18), 3.0)
				1:
					b.rect(Rect2(cp - Vector2(10.0, 9.0), Vector2(22.0, 18.0)), Color(0.20, 0.21, 0.24))
					b.rect(Rect2(cp - Vector2(7.0, 6.0), Vector2(16.0, 12.0)), Color(0.98, 0.62, 0.20, 0.7))
				2:
					b.rect(Rect2(cp - Vector2(10.0, 9.0), Vector2(22.0, 18.0)), Color(0.50, 0.53, 0.58))
					b.circle(cp + Vector2(1.0, 0.0), 2.0, Color(0.20, 0.20, 0.22))
				_:
					for n in range(3):
						b.circle(cp + Vector2(-6.0 + float(n) * 7.0, (float(n % 2) - 0.5) * 6.0), 3.2, Color(0.98, 0.98, 0.96))
			uy += 30.0
			k += 1
		b.rect(Rect2(unit.end.x - 3.0, unit.position.y, 3.0, unit.size.y), Color(0.86, 0.88, 0.90))
	# the flight-deck door: shut, a keypad, the sign nobody argues with
	var dr := Rect2(x - 6.0, top + f.size.y * 0.5 - 30.0, 10.0, 60.0)
	b.rect(dr, Color(0.60, 0.62, 0.66))
	b.rect(Rect2(dr.position.x + 3.0, dr.position.y + 4.0, 4.0, 52.0), Color(0.46, 0.48, 0.52))
	b.circle(Vector2(dr.end.x + 6.0, dr.position.y - 8.0), 3.0, AeroportArt.PAINT_RED)
	# the crew, backed up against the galley with a coffee pot and a look
	var at := Vector2(x + 74.0, top + f.size.y * 0.5 - 70.0)
	AeroportArt.person(b, at, 0.4, AeroportArt.SIGN_NAVY, AeroportArt.pick(AeroportArt.HAIR, 2), AeroportArt.pick(AeroportArt.SKIN, 3))
	b.line(at + Vector2(-2.0, 7.0), at + Vector2(-2.0, 10.0), AeroportArt.PAINT_RED, 2.6)
	b.circle(at + Vector2(12.0, 12.0), 5.0, Color(0.20, 0.20, 0.22))
	b.circle(at + Vector2(12.0, 12.0), 3.4, Color(0.36, 0.22, 0.14))
	# the curtain between the galley and the cabin, half torn off its rail
	var cx := x + 62.0
	b.rect(Rect2(cx, top, 3.0, f.size.y), STEEL_DARK)
	for seg: Vector2 in [Vector2(top + 6.0, top + BLOCK_N.y + 20.0), Vector2(top + BLOCK_C.x - 10.0, top + BLOCK_C.y - 30.0)]:
		var y := seg.x
		var k := 0
		while y < seg.y:
			b.circle(Vector2(cx + 2.0 + (4.0 if k % 2 == 0 else 0.0), y), 6.0, Color(0.30, 0.20, 0.44))
			b.circle(Vector2(cx + 1.0 + (4.0 if k % 2 == 0 else 0.0), y - 1.5), 3.0, Color(0.42, 0.30, 0.58))
			y += 9.0
			k += 1
	# and the rest of it, pulled down and dragged into the aisle
	var drag := PackedVector2Array([Vector2(cx + 4.0, top + BLOCK_C.y - 26.0), Vector2(cx + 30.0, top + BLOCK_C.y + 10.0),
		Vector2(cx + 76.0, top + BLOCK_C.y + 26.0), Vector2(cx + 96.0, top + BLOCK_C.y + 58.0), Vector2(cx + 52.0, top + BLOCK_C.y + 66.0),
		Vector2(cx + 14.0, top + BLOCK_C.y + 40.0)])
	b.polygon(drag, Color(0.30, 0.20, 0.44))
	b.line(drag[1], drag[4], Color(0.42, 0.30, 0.58), 3.0)
	b.line(drag[0], drag[2], Color(0.24, 0.15, 0.36), 2.0)


# aft: two lavatories and the rear galley between them
static func _lavatories(m: Node2D, b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	for half in range(2):
		var r := Rect2(f.end.x - 64.0, top + 6.0 if half == 0 else f.end.y - 116.0, 64.0, 110.0)
		b.rect(Rect2(r.position + LIGHT * 7.0, r.size), Color(SHADOW, 0.22))
		b.rect(r, HULL_SHADE)
		b.rect(r.grow(-3.0), Color(0.90, 0.92, 0.94))
		# the bowl, the basin, a roll on the wall
		b.capsule(r.get_center() + Vector2(8.0, -14.0), r.get_center() + Vector2(8.0, 0.0), 11.0, Color(0.98, 0.98, 0.99))
		b.capsule(r.get_center() + Vector2(8.0, -12.0), r.get_center() + Vector2(8.0, -4.0), 6.5, Color(0.70, 0.84, 0.92))
		b.circle(r.get_center() + Vector2(8.0, 30.0), 9.0, STEEL)
		b.circle(r.get_center() + Vector2(8.0, 30.0), 6.0, Color(0.80, 0.84, 0.88))
		# the folding door, ajar, and whether anyone is in
		var dy := r.end.y - 30.0 if half == 0 else r.position.y + 30.0
		b.line(Vector2(r.position.x, dy - 16.0), Vector2(r.position.x - 12.0, dy), Color(0.70, 0.72, 0.76), 4.0)
		b.line(Vector2(r.position.x - 12.0, dy), Vector2(r.position.x, dy + 16.0), Color(0.70, 0.72, 0.76), 4.0)
		b.rect(Rect2(r.position.x + 4.0, dy - 28.0, 12.0, 6.0), Color(0.22, 0.74, 0.40) if half == 0 else AeroportArt.PAINT_RED)
	# the paper from the near one, all the way up the aisle
	var roll := Vector2(f.end.x - 30.0, top + 96.0)
	var pts := PackedVector2Array()
	for k in range(22):
		var t := float(k) / 21.0
		pts.append(Vector2(roll.x - t * 420.0, roll.y + 40.0 + t * 46.0 + sin(t * 17.0) * 14.0 * (0.3 + t)))
	for k in range(pts.size() - 1):
		b.line(pts[k] + LIGHT * 2.0, pts[k + 1] + LIGHT * 2.0, Color(SHADOW, 0.12), 7.0)
		b.line(pts[k], pts[k + 1], Color(0.99, 0.99, 0.97), 6.0)
	for k in range(0, pts.size() - 1, 2):
		var mid := pts[k].lerp(pts[k + 1], 0.5)
		var n := (pts[k + 1] - pts[k]).normalized().orthogonal()
		b.line(mid - n * 3.0, mid + n * 3.0, Color(0.84, 0.84, 0.82), 1.0)
	b.circle(pts[pts.size() - 1], 7.0, Color(0.99, 0.99, 0.97))
	b.circle(pts[pts.size() - 1], 3.0, Color(0.70, 0.62, 0.50))
	# the rear galley's counter
	var g := Rect2(f.end.x - 40.0, top + 126.0, 34.0, f.size.y - 252.0)
	b.rect(g, STEEL_DARK)
	b.rect(g.grow(-2.5), STEEL)
	var uy := g.position.y + 16.0
	var k2 := 0
	while uy < g.end.y - 10.0:
		if k2 % 2 == 0:
			b.rect(Rect2(g.position.x + 6.0, uy - 9.0, 22.0, 18.0), Color(0.50, 0.53, 0.58))
		else:
			b.circle(Vector2(g.get_center().x, uy), 7.0, Color(0.20, 0.20, 0.22))
			b.circle(Vector2(g.get_center().x, uy), 5.0, Color(0.36, 0.22, 0.14))
		uy += 28.0
		k2 += 1


# one seat facing forward (west): cushion, the back and its headrest cover
# behind it, an armrest either side
static func _seat(b: ShapeBatch, p: Vector2, h: float, biz: bool, recline: float) -> void:
	var base := SEAT_BIZ if biz else SEAT
	var lit := SEAT_BIZ_LIGHT if biz else SEAT_LIGHT
	var w := 38.0 if biz else 32.0
	b.rect(Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h), ARM)
	b.rect(Rect2(p.x - w * 0.5, p.y - h * 0.5 + 2.5, w - 10.0, h - 5.0), base)
	b.rect(Rect2(p.x - w * 0.5 + 2.0, p.y - h * 0.5 + 4.5, w - 15.0, h - 9.0), lit)
	# the back, further aft the more it is reclined
	var bx := p.x + w * 0.5 - 11.0 + recline * 7.0
	b.rect(Rect2(bx, p.y - h * 0.5 + 2.0, 11.0, h - 4.0), base.darkened(0.12))
	b.rect(Rect2(bx + 3.0, p.y - h * 0.5 + 5.0, 6.0, h - 10.0), HEADREST)


static func _seats(m: Node2D, b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	for i in range(ROWS):
		var x := _row_x(i)
		var biz := i < BUSINESS_ROWS
		for block in range(3):
			if not _has_block(i, block):
				continue
			var span: Vector2 = [BLOCK_N, BLOCK_C, BLOCK_S][block]
			var n := int(roundf((span.y - span.x) / SEAT_H))
			if biz:
				n = 2 if block != 1 else 3
			var sh := (span.y - span.x) / float(n)
			b.rect(Rect2(x - 16.0 + LIGHT.x * 6.0, top + span.x + LIGHT.y * 6.0, 34.0, span.y - span.x), Color(SHADOW, 0.16))
			for k in range(n):
				var sp := Vector2(x, top + span.x + (float(k) + 0.5) * sh)
				var seed := i * 37 + block * 11 + k
				_seat(b, sp, sh - 2.0, biz, AeroportArt.h(seed + 5) if AeroportArt.h(seed + 6) < 0.3 else 0.0)
				var roll := AeroportArt.h(seed)
				if roll < 0.30:
					_passenger(b, sp + Vector2(2.0, 0.0), seed)
				elif roll < 0.42:
					# a tray down with dinner on it, nobody watching it
					var tp := sp + Vector2(-13.0, 0.0)
					b.rect(Rect2(tp - Vector2(7.0, 9.0), Vector2(14.0, 18.0)), Color(0.78, 0.79, 0.80))
					b.rect(Rect2(tp - Vector2(4.0, 6.0), Vector2(8.0, 7.0)), Color(0.94, 0.80, 0.50))
					b.circle(tp + Vector2(0.0, 5.0), 2.8, Color(0.98, 0.98, 0.96))
				elif roll < 0.50:
					AeroportArt.box(b, sp + Vector2(-2.0, 0.0), AeroportArt.h(seed) * 0.8, 8.0, 6.0, AeroportArt.pick(AeroportArt.BAGS, seed))
	# the curtain rail between business and the rest
	var cx := _row_x(BUSINESS_ROWS) - PITCH * 0.5
	for span: Vector2 in [BLOCK_N, BLOCK_C, BLOCK_S]:
		b.rect(Rect2(cx - 2.0, top + span.x - 2.0, 4.0, span.y - span.x + 4.0), Color(0.30, 0.20, 0.44))
		b.rect(Rect2(cx - 2.0, top + span.x - 2.0, 1.5, span.y - span.x + 4.0), Color(0.42, 0.30, 0.58))


# someone in their seat, facing forward, taking it one of five ways
static func _passenger(b: ShapeBatch, p: Vector2, seed: int) -> void:
	var shirt := AeroportArt.pick(AeroportArt.CLOTHES, seed)
	var skin := AeroportArt.pick(AeroportArt.SKIN, seed * 3)
	var hair := AeroportArt.pick(AeroportArt.HAIR, seed * 5)
	b.capsule(p + Vector2(-9.0, -4.0), p + Vector2(-15.0, -4.0), 3.2, shirt.darkened(0.45))
	b.capsule(p + Vector2(-9.0, 4.0), p + Vector2(-15.0, 4.0), 3.2, shirt.darkened(0.45))
	b.capsule(p + Vector2(0.0, -6.0), p + Vector2(0.0, 6.0), 5.6, shirt)
	b.circle(p + Vector2(1.0, 0.0), 5.4, hair)
	b.circle(p + Vector2(-1.4, 0.0), 4.0, skin)
	match seed % 5:
		0:
			# asleep through all of it, eye mask on
			b.line(p + Vector2(-2.6, -4.0), p + Vector2(-2.6, 4.0), Color(0.14, 0.14, 0.20), 2.6)
		1:
			# arms up, a shriek
			b.line(p + Vector2(0.0, -7.0), p + Vector2(-9.0, -14.0), skin, 3.2)
			b.line(p + Vector2(0.0, 7.0), p + Vector2(-9.0, 14.0), skin, 3.2)
			for k in range(3):
				var d := Vector2.from_angle(PI + (float(k) - 1.0) * 0.5)
				b.line(p + d * 13.0, p + d * 19.0, Color(1.0, 1.0, 1.0, 0.9), 2.0)
		2:
			# filming it
			AeroportArt.box(b, p + Vector2(-12.0, 0.0), 0.0, 2.6, 4.4, Color(0.10, 0.11, 0.13))
			AeroportArt.box(b, p + Vector2(-12.0, 0.0), 0.0, 1.8, 3.6, Color(0.62, 0.80, 0.96))
		3:
			# headphones, has noticed nothing
			b.line(p + Vector2(1.0, -5.6), p + Vector2(1.0, 5.6), Color(0.12, 0.12, 0.14), 2.2)
			b.circle(p + Vector2(1.0, -5.8), 2.4, Color(0.80, 0.20, 0.20))
			b.circle(p + Vector2(1.0, 5.8), 2.4, Color(0.80, 0.20, 0.20))
		_:
			# holding a drink well out of reach
			b.line(p + Vector2(0.0, -6.0), p + Vector2(-6.0, -14.0), skin, 3.0)
			b.circle(p + Vector2(-7.0, -15.0), 3.2, Color(0.98, 0.98, 0.96))
			b.circle(p + Vector2(-7.0, -15.0), 2.0, Color(0.90, 0.50, 0.16))


# the overhead bins: a strip along each wall and a spine over the middle
# block, a door per row, some of them popped with a strap hanging out
static func _bins(b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	var strips: Array = [[top + 0.0, 0], [top + (BLOCK_C.x + BLOCK_C.y) * 0.5 - 7.0, 1], [f.end.y - 14.0, 2]]
	for st: Array in strips:
		var y: float = st[0]
		var block: int = st[1]
		for i in range(ROWS):
			if not _has_block(i, block):
				continue
			var x := _row_x(i)
			var r := Rect2(x - PITCH * 0.5 + 1.0, y, PITCH - 2.0, 14.0)
			var open := AeroportArt.h(i * 7 + block * 3 + 1) < 0.28
			b.rect(Rect2(r.position + LIGHT * 5.0, r.size), Color(SHADOW, 0.16))
			if open:
				b.rect(r, Color(0.16, 0.17, 0.20))
				AeroportArt.box(b, r.get_center() + Vector2(-6.0, 0.0), 0.0, 9.0, 5.0, AeroportArt.pick(AeroportArt.BAGS, i + block))
				AeroportArt.box(b, r.get_center() + Vector2(11.0, 1.0), 0.2, 6.0, 4.5, AeroportArt.pick(AeroportArt.BAGS, i * 3 + block))
				# a coat sleeve, hanging down into the row
				var sgn := 1.0 if block != 2 else -1.0
				b.line(r.get_center() + Vector2(2.0, 0.0), r.get_center() + Vector2(6.0, sgn * 22.0), AeroportArt.pick(AeroportArt.CLOTHES, i + 9), 5.0)
			else:
				b.rect(r, BIN_EDGE)
				b.rect(r.grow(-1.5), BIN)
				b.rect(Rect2(r.get_center().x - 5.0, r.end.y - 4.5 if block != 2 else r.position.y + 1.5, 10.0, 3.0), BIN_EDGE)


# the mess: masks down over three rows, a drinks run gone wrong, a life vest
# somebody pulled the cord on, snacks, a paw-print trail
static func _havoc(m: Node2D, b: ShapeBatch, f: Rect2) -> void:
	var top := f.position.y
	# oxygen masks, dropped: a yellow cup on its tube over each seat
	for i in [9, 10, 11, 15]:
		for block in range(3):
			if not _has_block(i, block):
				continue
			var span: Vector2 = [BLOCK_N, BLOCK_C, BLOCK_S][block]
			var n := int(roundf((span.y - span.x) / SEAT_H))
			for k in range(n):
				var sp := Vector2(_row_x(i) - 16.0, top + span.x + (float(k) + 0.5) * SEAT_H)
				var sw := Vector2(AeroportArt.h(i * 9 + k) * 8.0 - 4.0, AeroportArt.h(i * 5 + k) * 8.0 - 4.0)
				b.line(sp + Vector2(14.0, 0.0), sp + sw, Color(0.96, 0.96, 0.94, 0.9), 1.2)
				b.circle(sp + sw + LIGHT * 2.0, 4.6, Color(SHADOW, 0.2))
				b.circle(sp + sw, 4.6, MASK)
				b.circle(sp + sw, 2.4, MASK.darkened(0.25))
	# the spill in the north aisle: juice, ice, cans rolled every way
	var sp2 := Vector2(640.0, top + (BLOCK_N.y + BLOCK_C.x) * 0.5 + 10.0)
	for k in range(5):
		var o := Vector2(AeroportArt.h(k + 20) * 110.0 - 55.0, AeroportArt.h(k + 30) * 60.0 - 30.0)
		b.glow(sp2 + o, 30.0 + AeroportArt.h(k) * 24.0, JUICE, 0.55)
	for k in range(9):
		var cp := sp2 + Vector2(AeroportArt.h(k + 50) * 220.0 - 110.0, AeroportArt.h(k + 60) * 100.0 - 50.0)
		var a := AeroportArt.h(k + 70) * PI
		var col: Color = [Color(0.82, 0.16, 0.16), Color(0.16, 0.52, 0.30), Color(0.94, 0.94, 0.92), Color(0.96, 0.56, 0.12)][k % 4]
		AeroportArt.box(b, cp + LIGHT * 2.0, a, 6.5, 3.6, Color(SHADOW, 0.2))
		AeroportArt.box(b, cp, a, 6.5, 3.6, col)
		AeroportArt.box(b, cp + Vector2.from_angle(a) * 5.5, a, 1.0, 3.6, STEEL)
	for k in range(12):
		var ip := sp2 + Vector2(AeroportArt.h(k + 80) * 150.0 - 75.0, AeroportArt.h(k + 90) * 70.0 - 35.0)
		AeroportArt.box(b, ip, AeroportArt.h(k) * PI, 2.6, 2.6, Color(0.90, 0.96, 1.0, 0.85))
	# a tray and its cups where the run ended
	AeroportArt.box(b, sp2 + Vector2(-96.0, 34.0), 0.5, 15.0, 10.0, Color(0.60, 0.62, 0.66))
	for k in range(4):
		b.circle(sp2 + Vector2(-104.0 + float(k) * 8.0, 30.0 + float(k % 2) * 9.0), 3.0, Color(0.98, 0.98, 0.96))
	# snacks: pretzel packets up and down both aisles
	for k in range(26):
		var ay := (BLOCK_N.y + 14.0 + AeroportArt.h(k + 100) * 108.0) if k % 2 == 0 else (BLOCK_C.y + 14.0 + AeroportArt.h(k + 100) * 100.0)
		var pp := Vector2(f.position.x + 90.0 + AeroportArt.h(k + 110) * (f.size.x - 190.0), top + ay)
		if MAT.grow(10.0).has_point(pp):
			continue
		var a2 := AeroportArt.h(k + 120) * PI
		AeroportArt.box(b, pp + LIGHT * 1.5, a2, 5.0, 3.4, Color(SHADOW, 0.18))
		AeroportArt.box(b, pp, a2, 5.0, 3.4, Color(0.86, 0.24, 0.20) if k % 3 != 0 else Color(0.20, 0.44, 0.76))
		AeroportArt.box(b, pp, a2, 2.0, 3.4, Color(0.98, 0.94, 0.80))
	# the life vest, inflated, by the second door
	var vp := Vector2(980.0, top + BLOCK_C.y + 96.0)
	b.capsule(vp + Vector2(-9.0, -10.0) + LIGHT * 3.0, vp + Vector2(-9.0, 12.0) + LIGHT * 3.0, 8.0, Color(SHADOW, 0.2))
	b.capsule(vp + Vector2(-9.0, -10.0), vp + Vector2(-9.0, 12.0), 8.0, VEST)
	b.capsule(vp + Vector2(9.0, -10.0), vp + Vector2(9.0, 12.0), 8.0, VEST)
	b.capsule(vp + Vector2(-9.0, -14.0), vp + Vector2(9.0, -14.0), 6.0, VEST.darkened(0.08))
	b.line(vp + Vector2(-9.0, -8.0), vp + Vector2(-9.0, 10.0), Color(1.0, 0.92, 0.5), 3.0)
	b.line(vp + Vector2(12.0, 14.0), vp + Vector2(20.0, 26.0), AeroportArt.PAINT_RED, 2.0)
	b.circle(vp + Vector2(20.0, 26.0), 2.4, AeroportArt.PAINT_RED)
	# a neck pillow, a magazine face down, someone's shoe
	var np := Vector2(330.0, top + BLOCK_C.y + 60.0)
	for k in range(7):
		b.circle(np + Vector2.from_angle(0.6 + float(k) * 0.66) * 9.0, 4.6, Color(0.50, 0.42, 0.66))
	AeroportArt.box(b, Vector2(840.0, top + BLOCK_N.y + 40.0), 0.4, 10.0, 7.5, Color(0.96, 0.95, 0.90))
	AeroportArt.box(b, Vector2(840.0, top + BLOCK_N.y + 40.0), 0.4, 10.0, 2.0, Color(0.20, 0.60, 0.76))
	b.capsule(Vector2(1050.0, top + BLOCK_N.y + 70.0), Vector2(1060.0, top + BLOCK_N.y + 74.0), 4.0, Color(0.50, 0.30, 0.18))
	# paw prints out of the juice and off up the aisle
	for k in range(9):
		var pw := sp2 + Vector2(60.0 + float(k) * 34.0, 20.0 + sin(float(k) * 1.3) * 16.0 + (6.0 if k % 2 == 0 else -6.0))
		var fade := 0.6 - float(k) * 0.055
		b.circle(pw, 3.6, Color(0.86, 0.46, 0.10, fade))
		for t in range(3):
			b.circle(pw + Vector2(5.0, (float(t) - 1.0) * 3.4), 1.6, Color(0.86, 0.46, 0.10, fade))


# where your human waits: the crew's fold-down seat by the door, straps and all
static func _jump_seat(b: ShapeBatch, p: Vector2) -> void:
	b.rect(Rect2(p.x - 24.0 + LIGHT.x * 6.0, p.y - 12.0 + LIGHT.y * 6.0, 48.0, 24.0), Color(SHADOW, 0.22))
	b.rect(Rect2(p.x - 24.0, p.y - 13.0, 48.0, 7.0), STEEL_DARK)
	b.rect(Rect2(p.x - 21.0, p.y - 8.0, 42.0, 19.0), Color(0.16, 0.18, 0.24))
	b.rect(Rect2(p.x - 19.0, p.y - 6.0, 38.0, 14.0), Color(0.26, 0.30, 0.40))
	for sx: float in [-9.0, 9.0]:
		b.line(Vector2(p.x + sx, p.y - 12.0), Vector2(p.x + sx * 0.4, p.y + 6.0), Color(0.86, 0.52, 0.12), 2.4)
	b.rect(Rect2(p.x - 3.0, p.y + 3.0, 6.0, 5.0), STEEL)


# --- the space's furniture, as a cabin has it --------------------------------

# Draws one of the space's props (main._draw_park_props asks first); true if
# it was drawn here.
static func draw_prop(m: Node2D, c: Object, pp: Dictionary) -> bool:
	var p: Vector2 = pp.pos
	var prog := float(pp.prog)
	var done: bool = pp.done
	var seed := int(p.x) * 3 + int(p.y)
	match String(pp.kind):
		"dig":
			_bag_to_dig(c, p, prog, done, seed)
		"planter":
			_trolley(m, c, p, seed)
		"post":
			_carry_on(c, p, seed, done)
		"shrub":
			_blankets(c, p, seed, done)
		"trough":
			_ice_bucket(c, p)
		_:
			return false
	if not done and prog > 0.05 and String(pp.kind) != "dig":
		for i in range(2):
			var rr := 16.0 + prog * 12.0 + float(i) * 7.0
			c.draw_arc(p, rr, 0, TAU, 16, Color(0.95, 0.96, 0.85, 0.34 * (1.0 - float(i) * 0.4)), 1.5)
	return true


# someone's holdall, unzipped: the deeper she goes the more of it is on the
# floor, and at the bottom is the sandwich
static func _bag_to_dig(c: Object, p: Vector2, prog: float, done: bool, seed: int) -> void:
	var col := AeroportArt.pick(AeroportArt.BAGS, seed)
	var open := prog if not done else 1.0
	var body := Rect2(p - Vector2(22.0, 13.0), Vector2(44.0, 26.0))
	c.draw_colored_polygon(MillieSide.ellipse(p + LIGHT * 5.0, Vector2(26.0, 15.0)), Color(SHADOW, 0.20))
	# what has come out so far
	for k in range(int(open * 7.0)):
		var a := TAU * AeroportArt.h(seed + k * 3) + float(k)
		var q := p + Vector2.from_angle(a) * (30.0 + AeroportArt.h(seed + k) * 14.0)
		match k % 3:
			0:
				c.draw_circle(q, 6.0, AeroportArt.pick(AeroportArt.CLOTHES, seed + k))
				c.draw_circle(q + Vector2(-1.5, -1.5), 2.6, AeroportArt.pick(AeroportArt.CLOTHES, seed + k).lightened(0.25))
			1:
				c.draw_rect(Rect2(q - Vector2(5.0, 3.5), Vector2(10.0, 7.0)), Color(0.96, 0.95, 0.90))
				c.draw_rect(Rect2(q - Vector2(5.0, 3.5), Vector2(3.0, 7.0)), Color(0.80, 0.30, 0.24))
			_:
				c.draw_line(q - Vector2(5.0, 0.0), q + Vector2(5.0, 2.0), Color(0.30, 0.60, 0.86), 3.0)
	# the bag: a boxy holdall, end panels, two webbing handles over the top
	c.draw_colored_polygon(_round(body, 8.0), col.darkened(0.32))
	c.draw_colored_polygon(_round(body.grow(-2.0), 6.5), col)
	for ex: float in [body.position.x + 2.0, body.end.x - 9.0]:
		c.draw_rect(Rect2(ex, body.position.y + 4.0, 7.0, body.size.y - 8.0), col.darkened(0.18))
	for hy: float in [-7.0, 7.0]:
		c.draw_line(p + Vector2(-11.0, hy), p + Vector2(11.0, hy), Color(0.14, 0.14, 0.16), 3.0)
	# the zip down the middle, its two flaps folded back as she digs
	var gape := open * 8.0
	if gape > 0.6:
		c.draw_rect(Rect2(p.x - 13.0, p.y - gape, 26.0, gape * 2.0), Color(0.08, 0.08, 0.10))
		c.draw_rect(Rect2(p.x - 13.0, p.y - gape - 2.5, 26.0, 2.5), col.lightened(0.3))
		c.draw_rect(Rect2(p.x - 13.0, p.y + gape, 26.0, 2.5), col.lightened(0.3))
		# a sleeve and a sock, on their way out
		c.draw_line(p + Vector2(-6.0, 0.0), p + Vector2(-10.0, -gape - 9.0), AeroportArt.pick(AeroportArt.CLOTHES, seed + 5), 4.0)
		c.draw_circle(p + Vector2(7.0, gape * 0.4), 3.4, AeroportArt.pick(AeroportArt.CLOTHES, seed + 9))
	else:
		c.draw_line(p + Vector2(-14.0, 0.0), p + Vector2(14.0, 0.0), Color(0.86, 0.80, 0.50), 1.6)
		c.draw_rect(Rect2(p.x + 12.0, p.y - 2.5, 4.0, 5.0), Color(0.86, 0.80, 0.50))
	# its tag
	c.draw_line(body.position + Vector2(40.0, 6.0), body.position + Vector2(50.0, 0.0), Color(0.20, 0.20, 0.22), 1.0)
	c.draw_rect(Rect2(body.position + Vector2(48.0, -4.0), Vector2(8.0, 5.0)), Color(0.98, 0.97, 0.92))
	if done:
		# the prize, unwrapped
		c.draw_rect(Rect2(p - Vector2(8.0, 4.0), Vector2(16.0, 8.0)), Color(0.90, 0.78, 0.52))
		c.draw_rect(Rect2(p - Vector2(8.0, 1.0), Vector2(16.0, 2.5)), Color(0.86, 0.36, 0.32))
		c.draw_rect(Rect2(p - Vector2(8.0, -1.5), Vector2(16.0, 1.5)), Color(0.40, 0.66, 0.30))
	elif prog > 0.05:
		c.draw_arc(p, 30.0, -PI / 2.0, -PI / 2.0 + TAU * prog / 1.1, 18, Color(1, 0.9, 0.5), 3.0)


# a rounded rect's outline (main.round_rect_pts without a main to ask)
static func _round(r: Rect2, rad: float) -> PackedVector2Array:
	var k := minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var cs := [Vector2(r.end.x - k, r.position.y + k), Vector2(r.end.x - k, r.end.y - k),
		Vector2(r.position.x + k, r.end.y - k), Vector2(r.position.x + k, r.position.y + k)]
	var pts := PackedVector2Array()
	for ci in range(4):
		for s in range(4):
			pts.append(cs[ci] + Vector2.from_angle(-PI * 0.5 + float(ci) * PI * 0.5 + float(s) * PI / 6.0) * k)
	return pts


# the drinks trolley, brakes on: solid, go round it. Bottles and cans on top,
# the drawers' handles down its side.
static func _trolley(m: Node2D, c: Object, p: Vector2, seed: int) -> void:
	var r := Rect2(p - Vector2(17.0, 17.0), Vector2(34.0, 34.0))
	c.draw_rect(Rect2(r.position + LIGHT * 8.0, r.size), Color(SHADOW, 0.22))
	c.draw_rect(r, STEEL_DARK)
	c.draw_rect(r.grow(-2.0), STEEL)
	c.draw_rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, 30.0, 3.0), Color(0.90, 0.92, 0.94))
	c.draw_rect(r.grow(-6.0), Color(0.30, 0.32, 0.36))
	for k in range(9):
		var q := r.position + Vector2(10.0 + float(k % 3) * 7.0, 10.0 + float(k / 3) * 7.0)
		var kind := int(AeroportArt.h(seed + k) * 4.0)
		var col: Color = [Color(0.82, 0.16, 0.16), Color(0.20, 0.50, 0.26), Color(0.96, 0.60, 0.14), Color(0.94, 0.94, 0.92)][kind]
		c.draw_circle(q, 3.0, col)
		c.draw_circle(q + Vector2(-0.8, -0.8), 1.1, col.lightened(0.5))
	# the push bar at each end
	for ey: float in [r.position.y - 3.0, r.end.y + 1.0]:
		c.draw_rect(Rect2(r.position.x + 6.0, ey, 22.0, 2.0), Color(0.20, 0.21, 0.24))


# a roller case stood in the aisle with its handle up: what every dog in the
# cabin has to stop at
static func _carry_on(c: Object, p: Vector2, seed: int, done: bool) -> void:
	var col := AeroportArt.pick(AeroportArt.BAGS, seed + 2)
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-9.0, 4.0), p + Vector2(9.0, 4.0),
		p + Vector2(9.0, 4.0) + LIGHT * 26.0, p + Vector2(-9.0, 4.0) + LIGHT * 26.0]), Color(SHADOW, 0.16))
	c.draw_rect(Rect2(p.x - 10.0, p.y - 7.0, 20.0, 14.0), col.darkened(0.3))
	c.draw_rect(Rect2(p.x - 8.5, p.y - 6.0, 17.0, 11.0), col)
	c.draw_rect(Rect2(p.x - 8.5, p.y - 6.0, 17.0, 2.5), col.lightened(0.25))
	# the handle's two tubes and its grip, standing over it
	c.draw_line(p + Vector2(-5.0, -4.0), p + Vector2(-5.0, -18.0), Color(0.60, 0.62, 0.66), 1.6)
	c.draw_line(p + Vector2(5.0, -4.0), p + Vector2(5.0, -18.0), Color(0.60, 0.62, 0.66), 1.6)
	c.draw_line(p + Vector2(-6.5, -18.0), p + Vector2(6.5, -18.0), Color(0.12, 0.12, 0.14), 3.4)
	# a tag on a loop
	c.draw_line(p + Vector2(7.0, -2.0), p + Vector2(13.0, 3.0), Color(0.20, 0.20, 0.22), 1.0)
	c.draw_rect(Rect2(p.x + 11.0, p.y + 2.0, 7.0, 5.0), Color(0.98, 0.97, 0.92))
	if done:
		c.draw_circle(p + Vector2(-9.0, 9.0), 2.6, Color(0.85, 0.85, 0.6, 0.7))


# the airline's blankets and little pillows, in a heap worth a good long sniff
static func _blankets(c: Object, p: Vector2, seed: int, done: bool) -> void:
	c.draw_circle(p + LIGHT * 5.0, 19.0, Color(SHADOW, 0.16))
	var navy := Color(0.20, 0.26, 0.48)
	for k in range(5):
		var a := TAU * float(k) / 5.0 + AeroportArt.h(seed) * 2.0
		c.draw_circle(p + Vector2.from_angle(a) * 8.0, 10.5, navy.darkened(0.15))
	for k in range(5):
		var a2 := TAU * float(k) / 5.0 + AeroportArt.h(seed) * 2.0
		c.draw_circle(p + Vector2.from_angle(a2) * 8.0 - LIGHT * 2.5, 7.5, navy)
		# the blanket stitch along a fold
		c.draw_line(p + Vector2.from_angle(a2) * 4.0, p + Vector2.from_angle(a2 + 0.5) * 15.0, Color(0.36, 0.44, 0.70), 1.4)
	for k in range(2):
		var q := p + Vector2(-5.0 + float(k) * 11.0, -3.0 + float(k) * 6.0)
		c.draw_rect(Rect2(q - Vector2(6.0, 4.5), Vector2(12.0, 9.0)), Color(0.80, 0.80, 0.78))
		c.draw_rect(Rect2(q - Vector2(5.0, 3.5), Vector2(10.0, 7.0)), Color(0.98, 0.98, 0.96))
	if done:
		c.draw_circle(p + Vector2(11.0, -12.0), 2.6, Color(0.85, 0.85, 0.6, 0.7))


# the galley's ice bucket, set down on the mat: melted enough to drink from
static func _ice_bucket(c: Object, p: Vector2) -> void:
	c.draw_circle(p + LIGHT * 5.0, 19.0, Color(SHADOW, 0.22))
	c.draw_circle(p, 19.0, STEEL_DARK)
	c.draw_circle(p, 17.0, STEEL)
	c.draw_arc(p, 17.0, PI * 1.05, PI * 1.9, 14, Color(0.94, 0.96, 0.98), 2.0)
	c.draw_circle(p, 13.5, Color(0.30, 0.52, 0.66))
	c.draw_circle(p + Vector2(1.0, 1.5), 11.0, Color(0.44, 0.66, 0.80))
	for k in range(5):
		var q := p + Vector2.from_angle(float(k) * 1.4) * (4.0 + float(k % 2) * 4.0)
		c.draw_rect(Rect2(q - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color(0.90, 0.97, 1.0, 0.85))
	c.draw_line(p + Vector2(-19.0, 0.0), p + Vector2(-25.0, 0.0), STEEL_DARK, 3.0)
	c.draw_line(p + Vector2(19.0, 0.0), p + Vector2(25.0, 0.0), STEEL_DARK, 3.0)


# the gate: no park gate here, the door is drawn with the cabin. Only the
# bridge's last lip, over the walk's floor.
static func draw_gate(m: Node2D, b: ShapeBatch) -> void:
	var gy: float = m.GATE_Y
	b.rect(Rect2(DOOR.x, gy - 4.0, DOOR.y - DOOR.x, 8.0), AeroportArt.STEEL_DARK)
	b.rect(Rect2(DOOR.x, gy - 4.0, DOOR.y - DOOR.x, 2.0), AeroportArt.STEEL)
