class_name AeroportArt
extends RefCounted

# L'Aeroport's picture (systems/aeroport.gd owns the walk's rules and solids).
# Terminal 1's pier, seen from above:
# - west of the concourse, through the glass curtain wall: the apron. A
#   head-of-stand road right under the windows, jets parked nose in with their
#   bridges across the road, stand paint, carts and cones.
# - east: the gate side. Glazed holdrooms B20 to B30 with their seating and
#   boarding doors, the duty-free shop, a cafe, and the far windows.
# - the floor between: terrazzo, sun through the glass, roof-beam shadows,
#   carpet at the gates, the queue at B22 the cart tangles in.
# Everything here that does not move is drawn on a cached canvas (the edge
# layer and the ground layer), so it costs a frame nothing. Nothing reads the
# clock except the functions named *_live.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const WALL_L := 380.0
const WALL_R := 900.0
const EAST_GLASS := 1100.0         # the holdrooms' far windows
const PIER_END := -4640.0          # past here the concourse is the jet bridge
const SECURITY_Y := -350.0

# stands: the y of each jet's centreline
const WEST_STANDS: Array[float] = [-1450.0, -2850.0, -4150.0]
const WEST_EMPTY := 1              # this one's jet has not arrived
const WEST_NOSE_X := 296.0
const EAST_NOSE_X := 1180.0
const ROAD_W := Vector2(310.0, 368.0)
const ROAD_E := Vector2(1108.0, 1162.0)

# the gates, by desk (Aeroport.GATE_DESKS): number, and the holdroom's span
const GATE_NUMBERS: Array[String] = ["B20", "B22", "B24", "B26", "B28", "B30"]
const DESK_YS: Array[float] = [-1120.0, -1720.0, -2520.0, -3120.0, -3720.0, -4320.0]
const HOLD_UP := 260.0
const HOLD_DOWN := 200.0
const SHOP := Rect2(900.0, -980.0, 200.0, 560.0)       # duty free
const CAFE := Rect2(900.0, -2300.0, 200.0, 260.0)

# the queue the cart tangles in on the way home (Aeroport.STANCHION_JAM_Y)
const QUEUE_Y := -1900.0

const APRON := Color(0.71, 0.72, 0.71)
const APRON_JOINT := Color(0.62, 0.63, 0.63)
const APRON_STAIN := Color(0.50, 0.50, 0.50, 0.22)
const ROAD := Color(0.43, 0.44, 0.47)
const PAINT_YELLOW := Color(0.96, 0.80, 0.16)
const PAINT_WHITE := Color(0.94, 0.94, 0.92)
const PAINT_RED := Color(0.82, 0.22, 0.18)
const GRASS := Color(0.44, 0.56, 0.36)
const PLANE_WHITE := Color(0.96, 0.97, 0.98)
const PLANE_SHADE := Color(0.84, 0.86, 0.90)
const WING := Color(0.80, 0.82, 0.85)
const WING_DARK := Color(0.62, 0.65, 0.70)
const COCKPIT := Color(0.12, 0.16, 0.22)
const LIVERIES: Array[Color] = [Color(0.10, 0.52, 0.58), Color(0.90, 0.38, 0.24), Color(0.16, 0.26, 0.56), Color(0.86, 0.68, 0.16)]
const GLASS := Color(0.70, 0.84, 0.92, 0.55)
const FRAME := Color(0.30, 0.33, 0.38)
const FRAME_LIGHT := Color(0.56, 0.60, 0.66)
const TERRAZZO := Color(0.87, 0.87, 0.86)
const TERRAZZO_WARM := Color(0.82, 0.81, 0.78)
const GRANITE := Color(0.46, 0.47, 0.50)
const JOINT := Color(0.74, 0.74, 0.74)
const CARPET := Color(0.27, 0.35, 0.50)
const CARPET_LINE := Color(0.34, 0.43, 0.60)
const CARPET_EDGE := Color(0.60, 0.62, 0.66)
const SEAT := Color(0.20, 0.22, 0.27)
const SEAT_PAD := Color(0.30, 0.33, 0.40)
const STEEL := Color(0.62, 0.65, 0.70)
const STEEL_DARK := Color(0.38, 0.41, 0.46)
const SIGN_YELLOW := Color(0.98, 0.82, 0.10)
const SIGN_INK := Color(0.10, 0.11, 0.13)
const SIGN_NAVY := Color(0.09, 0.14, 0.26)
const BELT_RED := Color(0.80, 0.14, 0.16)
const HIVIS := Color(0.86, 0.94, 0.20)
const HIVIS_ORANGE := Color(0.98, 0.52, 0.12)
const SKIN: Array[Color] = [Color(0.93, 0.76, 0.62), Color(0.80, 0.60, 0.44), Color(0.56, 0.38, 0.26), Color(0.97, 0.84, 0.72)]
const HAIR: Array[Color] = [Color(0.16, 0.12, 0.10), Color(0.42, 0.26, 0.14), Color(0.80, 0.66, 0.34), Color(0.62, 0.62, 0.64), Color(0.60, 0.22, 0.12)]
const CLOTHES: Array[Color] = [Color(0.22, 0.30, 0.48), Color(0.72, 0.24, 0.22), Color(0.90, 0.88, 0.82), Color(0.24, 0.50, 0.42),
	Color(0.92, 0.70, 0.22), Color(0.48, 0.34, 0.58), Color(0.30, 0.32, 0.36), Color(0.94, 0.56, 0.62)]
const BAGS: Array[Color] = [Color(0.82, 0.20, 0.18), Color(0.18, 0.42, 0.80), Color(0.16, 0.17, 0.20), Color(0.94, 0.74, 0.16),
	Color(0.22, 0.58, 0.44), Color(0.86, 0.44, 0.66), Color(0.54, 0.56, 0.60)]
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08)


# a steady 0..1 from an integer: placement that never rolls the RNG
static func h(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 4.1) * 43758.5453, 1.0)


static func pick(arr: Array, i: int) -> Color:
	return arr[int(h(i) * 997.0) % arr.size()]


# --- people and their luggage, from above ------------------------------------

# Someone standing or walking, facing `dir`: shoulders, a head of hair, the
# face showing at the front of it. `swing` (-1..1) puts a foot and an arm out.
static func person(b: ShapeBatch, p: Vector2, dir: float, shirt: Color, hair: Color, skin: Color, swing := 0.0, k := 1.0) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	b.circle(p + LIGHT * 5.0 * k, 9.0 * k, Color(SHADOW, 0.20))
	if swing != 0.0:
		# feet, striding
		b.circle(p + f * 7.0 * swing * k + s * 4.0 * k, 3.4 * k, shirt.darkened(0.55))
		b.circle(p - f * 7.0 * swing * k - s * 4.0 * k, 3.4 * k, shirt.darkened(0.55))
	b.capsule(p - s * 7.0 * k, p + s * 7.0 * k, 6.2 * k, shirt.darkened(0.22))
	b.capsule(p - s * 6.4 * k - f * 0.8 * k, p + s * 6.4 * k - f * 0.8 * k, 5.0 * k, shirt)
	if swing != 0.0:
		b.circle(p + s * 10.0 * k - f * 5.0 * swing * k, 2.8 * k, skin)
	b.circle(p, 5.8 * k, hair)
	b.circle(p + f * 2.4 * k, 4.2 * k, skin)


# a box lying along `dir`: a suitcase, a crate, a cart bed
static func box(b: ShapeBatch, p: Vector2, dir: float, half_len: float, half_w: float, col: Color) -> void:
	var f := Vector2.from_angle(dir) * half_len
	var s := Vector2.from_angle(dir).orthogonal() * half_w
	b.quad(p - f - s, p + f - s, p + f + s, p - f + s, col)


# a roller case from above: shell, a rib, the handle out behind, two wheels
static func roller(b: ShapeBatch, p: Vector2, dir: float, col: Color, k := 1.0) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	box(b, p + LIGHT * 3.0, dir, 10.0 * k, 7.0 * k, Color(SHADOW, 0.22))
	b.line(p, p + f * 17.0 * k, Color(0.14, 0.14, 0.16), 2.0 * k)
	b.line(p + f * 17.0 * k - s * 4.0 * k, p + f * 17.0 * k + s * 4.0 * k, Color(0.14, 0.14, 0.16), 2.4 * k)
	box(b, p, dir, 10.0 * k, 7.0 * k, col.darkened(0.25))
	box(b, p - f * 0.6 * k, dir, 8.6 * k, 5.6 * k, col)
	b.line(p - s * 5.0 * k, p + s * 5.0 * k, col.darkened(0.3), 1.4 * k)
	b.line(p - f * 5.0 * k - s * 5.0 * k, p - f * 5.0 * k + s * 5.0 * k, col.lightened(0.25), 1.2 * k)
	for w: float in [-1.0, 1.0]:
		b.circle(p - f * 10.0 * k + s * w * 5.0 * k, 1.8 * k, Color(0.08, 0.08, 0.09))


# A traveller late for a flight: leaning into it, one arm back on the case's
# handle, the case bouncing along behind, a boarding pass in the other hand.
static func runner(b: ShapeBatch, p: Vector2, dir: float, i: int, t: float) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	var stride := sin(t * 15.0 + float(i) * 1.9)
	var shirt := pick(CLOTHES, i * 7 + 3)
	var bag := pick(BAGS, i * 5 + 1)
	# the case, yawing on its two wheels as it is hauled
	var yaw := sin(t * 9.0 + float(i) * 2.3) * 0.28
	var cpos := p - f * 30.0 + s * (7.0 + sin(t * 9.0 + float(i)) * 3.0)
	roller(b, cpos, dir + yaw, bag, 1.15)
	# speed strokes off the case
	for k in range(3):
		var o := cpos - f * (16.0 + float(k) * 9.0) + s * (float(k) - 1.0) * 6.0
		b.line(o, o - f * 12.0, Color(1.0, 1.0, 1.0, 0.5 - float(k) * 0.14), 2.0)
	# the arm back to the handle
	b.line(p + s * 7.0, cpos + f * 19.0, pick(SKIN, i), 3.4)
	person(b, p + f * 3.0, dir, shirt, pick(HAIR, i * 3), pick(SKIN, i), stride, 1.25)
	# a tie or a scarf streaming back, and the pass held out ahead
	if i % 2 == 0:
		b.line(p - f * 2.0, p - f * 15.0 + s * stride * 4.0, Color(0.76, 0.16, 0.20), 3.0)
	var hand := p + f * 13.0 - s * 9.0
	b.line(p - s * 8.0, hand, pick(SKIN, i), 3.4)
	box(b, hand + f * 4.0, dir + 0.3, 5.0, 3.0, Color(0.98, 0.98, 0.94))
	# sweat
	var fl := fposmod(t * 2.2 + float(i) * 0.31, 1.0)
	b.circle(p - f * (8.0 + fl * 14.0) - s * (8.0 + fl * 6.0), 2.2 * (1.0 - fl) + 0.6, Color(0.70, 0.88, 1.0, 0.8 * (1.0 - fl)))


# someone sitting, facing `dir`: knees out front, maybe a phone or a paper
static func sitter(b: ShapeBatch, p: Vector2, dir: float, i: int) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	var shirt := pick(CLOTHES, i)
	var skin := pick(SKIN, i * 3 + 1)
	b.capsule(p + f * 6.0 - s * 3.6, p + f * 11.0 - s * 3.6, 3.0, shirt.darkened(0.45))
	b.capsule(p + f * 6.0 + s * 3.6, p + f * 11.0 + s * 3.6, 3.0, shirt.darkened(0.45))
	b.capsule(p - s * 5.6, p + s * 5.6, 5.4, shirt)
	b.circle(p - f * 0.5, 5.2, pick(HAIR, i * 5 + 2))
	b.circle(p + f * 1.8, 3.8, skin)
	match i % 4:
		0:
			box(b, p + f * 9.0, dir, 2.6, 4.2, Color(0.10, 0.11, 0.13))       # a phone
			box(b, p + f * 9.0, dir, 1.8, 3.4, Color(0.62, 0.80, 0.96))
		1:
			box(b, p + f * 10.0, dir, 4.5, 8.0, Color(0.95, 0.94, 0.90))      # a newspaper
			b.line(p + f * 6.0, p + f * 14.0, Color(0.70, 0.70, 0.68), 1.0)
		2:
			b.circle(p + f * 9.0 + s * 4.0, 2.6, Color(0.96, 0.96, 0.94))     # a coffee
			b.circle(p + f * 9.0 + s * 4.0, 1.6, Color(0.36, 0.24, 0.16))


# --- the apron ---------------------------------------------------------------

# A jet parked nose toward the terminal, from above. `nose` is the tip of the
# radome; `sx` is +1 for a nose pointing east (the west stands), -1 for west.
static func jet(b: ShapeBatch, nose: Vector2, sx: float, tint: Color) -> void:
	var at := func(d: float, o: float) -> Vector2: return Vector2(nose.x - sx * d, nose.y + o)
	var sh := LIGHT * 16.0
	b.capsule(at.call(34.0, 0.0) + sh, at.call(900.0, 0.0) + sh, 34.0, Color(SHADOW, 0.20))
	for s: float in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([at.call(150.0, s * 28.0) + sh, at.call(300.0, s * 28.0) + sh,
			at.call(520.0, s * 380.0) + sh, at.call(470.0, s * 385.0) + sh]), Color(SHADOW, 0.18))
	for s: float in [-1.0, 1.0]:
		# the engine hangs ahead of the wing: nacelle, the cowl's painted lip,
		# the intake and its spinner
		b.capsule(at.call(140.0, s * 125.0), at.call(230.0, s * 125.0), 19.0, PLANE_SHADE)
		b.polygon(PackedVector2Array([at.call(150.0, s * 28.0), at.call(300.0, s * 28.0),
			at.call(520.0, s * 380.0), at.call(470.0, s * 385.0)]), WING)
		b.line(at.call(285.0, s * 30.0), at.call(506.0, s * 376.0), WING_DARK, 3.0)
		b.line(at.call(160.0, s * 34.0), at.call(474.0, s * 380.0), PLANE_WHITE, 3.0)
		b.capsule(at.call(140.0, s * 125.0), at.call(200.0, s * 125.0), 18.0, PLANE_WHITE)
		b.circle(at.call(138.0, s * 125.0), 18.5, tint)
		b.circle(at.call(134.0, s * 125.0), 14.0, COCKPIT)
		b.circle(at.call(133.0, s * 125.0), 5.0, STEEL)
		# the winglet, turned up, seen as a sliver
		b.line(at.call(470.0, s * 385.0), at.call(522.0, s * 381.0), tint, 5.0)
	b.capsule(at.call(34.0, 0.0), at.call(900.0, 0.0), 34.0, PLANE_SHADE)
	b.capsule(at.call(34.0, -3.0), at.call(900.0, -3.0), 30.0, PLANE_WHITE)
	for s: float in [-1.0, 1.0]:
		b.line(at.call(62.0, s * 28.0), at.call(900.0, s * 28.0), tint, 4.0)
		# the forward door, and the hold door further back
		b.line(at.call(58.0, s * 32.5), at.call(72.0, s * 32.5), COCKPIT, 3.0)
	# the cockpit's wrap of glass and its glare, the radome's seam
	b.capsule(at.call(21.0, -14.0), at.call(21.0, 14.0), 5.5, COCKPIT)
	b.line(at.call(20.0, -11.0), at.call(20.0, -3.0), Color(0.60, 0.78, 0.92), 2.2)
	b.line(at.call(9.0, -19.0), at.call(9.0, 19.0), PLANE_SHADE, 1.5)
	# the roof: a red beacon and two aerials
	b.circle(at.call(240.0, 0.0), 3.4, PAINT_RED)
	b.line(at.call(120.0, 0.0), at.call(134.0, 0.0), STEEL_DARK, 2.0)
	b.line(at.call(330.0, 0.0), at.call(344.0, 0.0), STEEL_DARK, 2.0)


# a cone: orange with its white band, and a little shadow
static func cone(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + LIGHT * 3.0, 5.0, Color(SHADOW, 0.2))
	b.circle(p, 5.0, HIVIS_ORANGE)
	b.circle(p, 3.0, PAINT_WHITE)
	b.circle(p, 1.6, HIVIS_ORANGE)


# a baggage dolly: a flat bed with its rails, loaded
static func dolly(b: ShapeBatch, p: Vector2, dir: float, i: int, loaded := true) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	box(b, p + LIGHT * 5.0, dir, 17.0, 11.0, Color(SHADOW, 0.22))
	box(b, p, dir, 17.0, 11.0, STEEL_DARK)
	box(b, p, dir, 15.0, 9.0, Color(0.26, 0.28, 0.32))
	if loaded:
		for k in range(4):
			var o := f * (float(k % 2) * 14.0 - 7.0) + s * (float(k / 2) * 9.0 - 4.5)
			box(b, p + o, dir + h(i * 4 + k) * 0.5 - 0.25, 6.0, 4.0, pick(BAGS, i * 4 + k))
	b.line(p - f * 17.0, p - f * 23.0, STEEL_DARK, 2.0)


# a tug: the little tractor that pulls the dollies, its driver in hi-vis
static func tug(b: ShapeBatch, p: Vector2, dir: float) -> void:
	var f := Vector2.from_angle(dir)
	var s := f.orthogonal()
	box(b, p + LIGHT * 5.0, dir, 15.0, 10.0, Color(SHADOW, 0.24))
	for w: float in [-1.0, 1.0]:
		box(b, p + f * 9.0 + s * w * 10.0, dir, 4.5, 2.4, Color(0.08, 0.08, 0.09))
		box(b, p - f * 9.0 + s * w * 10.0, dir, 4.5, 2.4, Color(0.08, 0.08, 0.09))
	box(b, p, dir, 15.0, 9.0, PAINT_YELLOW.darkened(0.2))
	box(b, p + f * 8.0, dir, 6.0, 8.0, PAINT_YELLOW)
	box(b, p - f * 5.0, dir, 6.5, 7.0, Color(0.20, 0.21, 0.24))
	b.circle(p - f * 4.0, 5.0, HIVIS)
	b.circle(p - f * 3.0, 3.6, Color(0.96, 0.96, 0.94))       # a hard hat
	b.circle(p + f * 14.0 + s * 6.0, 1.8, Color(1.0, 0.98, 0.80))
	b.circle(p + f * 14.0 - s * 6.0, 1.8, Color(1.0, 0.98, 0.80))


static func _apron_ground(b: ShapeBatch, x0: float, x1: float, vt: float, vb: float) -> void:
	b.rect(Rect2(x0, vt, x1 - x0, vb - vt), APRON)
	# the slabs, poured in bays
	var jx := floorf(x0 / 150.0) * 150.0
	while jx <= x1:
		if jx > x0:
			b.rect(Rect2(jx, vt, 1.5, vb - vt), APRON_JOINT)
		jx += 150.0
	var jy := floorf(vt / 150.0) * 150.0
	while jy <= vb:
		b.rect(Rect2(x0, jy, x1 - x0, 1.5), APRON_JOINT)
		# what years of aircraft leave: a drip here, a tyre scuff there
		var k := int(jy / 150.0)
		if h(k * 3 + int(x0)) < 0.5:
			var sp := Vector2(lerpf(x0 + 40.0, x1 - 40.0, h(k * 7 + 1)), jy + h(k * 5) * 120.0)
			b.glow(sp, 16.0 + h(k) * 22.0, APRON_STAIN, 0.3)
		jy += 150.0


static func _road(b: ShapeBatch, road: Vector2, vt: float, vb: float) -> void:
	b.rect(Rect2(road.x, vt, road.y - road.x, vb - vt), ROAD)
	b.rect(Rect2(road.x, vt, 3.0, vb - vt), PAINT_WHITE)
	b.rect(Rect2(road.y - 3.0, vt, 3.0, vb - vt), PAINT_WHITE)


# the paint and the kit round one stand; `sx` as for jet()
static func _stand(m: Node2D, b: ShapeBatch, nose: Vector2, sx: float, label: String, parked: bool, i: int) -> void:
	var at := func(d: float, o: float) -> Vector2: return Vector2(nose.x - sx * d, nose.y + o)
	# the lead-in line and the stop bar it ends at
	var far: Vector2 = at.call(1200.0, 0.0)
	b.rect(Rect2(minf(far.x, nose.x), nose.y - 2.5, absf(far.x - nose.x), 5.0), PAINT_YELLOW)
	b.rect(Rect2(at.call(-2.0, 0.0) - Vector2(2.5, 22.0), Vector2(5.0, 44.0)), PAINT_YELLOW)
	# the keep-clear box the bridge swings over: red hatching
	var kc: Vector2 = at.call(60.0, -150.0)
	var kr := Rect2(minf(kc.x, kc.x + sx * 74.0), kc.y, 74.0, 96.0)
	b.rect(kr, Color(PAINT_RED, 0.30))
	for k in range(7):
		var yy := kr.position.y + float(k) * 16.0
		b.line(Vector2(kr.position.x, yy), Vector2(kr.end.x, minf(yy + 30.0, kr.end.y)), Color(PAINT_RED, 0.75), 2.5)
	# the stand's number, painted where a pilot reads it
	var lb: Vector2 = at.call(30.0, 120.0)
	var lr := Rect2(lb - Vector2(26.0, 13.0), Vector2(52.0, 26.0))
	b.rect(lr, PAINT_YELLOW)
	b.draw_string(m.font, Vector2(lr.position.x, lr.end.y - 6.0), label, HORIZONTAL_ALIGNMENT_CENTER, lr.size.x, 17, SIGN_INK)
	if parked:
		jet(b, nose, sx, LIVERIES[i % LIVERIES.size()])
		# chocked and coned, the ground power cart plugged in under the nose
		cone(b, at.call(-10.0, -46.0))
		cone(b, at.call(-10.0, 46.0))
		cone(b, at.call(118.0, 158.0))
		cone(b, at.call(118.0, -158.0))
		var gpu: Vector2 = at.call(40.0, 78.0)
		b.line(gpu, at.call(46.0, 30.0), Color(0.10, 0.10, 0.12), 2.5)
		box(b, gpu + LIGHT * 4.0, 0.0, 15.0, 10.0, Color(SHADOW, 0.22))
		box(b, gpu, 0.0, 15.0, 10.0, PAINT_YELLOW.darkened(0.15))
		box(b, gpu, 0.0, 11.0, 6.0, PAINT_YELLOW)
		b.line(gpu + Vector2(-8.0, 0.0), gpu + Vector2(8.0, 0.0), Color(0.20, 0.20, 0.22), 2.0)
		# a belt loader up at the forward hold, and the dollies waiting on it
		var bl: Vector2 = at.call(120.0, 64.0)
		box(b, bl, PI * 0.5, 30.0, 7.0, STEEL_DARK)
		box(b, bl, PI * 0.5, 28.0, 4.5, Color(0.14, 0.14, 0.16))
		box(b, bl + Vector2(0.0, 16.0), PI * 0.5, 5.0, 3.5, pick(BAGS, i * 3))
		box(b, bl + Vector2(0.0, 30.0), 0.0, 10.0, 12.0, PAINT_WHITE.darkened(0.08))
		dolly(b, at.call(96.0, 128.0), 0.0, i * 11)
		person(b, at.call(70.0, 104.0), PI * 1.3, HIVIS, pick(HAIR, i), pick(SKIN, i))
	else:
		# waiting on its jet: a marshaller with the wands up, dollies lined up
		var mp: Vector2 = at.call(-4.0, 0.0)
		person(b, mp, PI if sx > 0.0 else 0.0, HIVIS_ORANGE, pick(HAIR, i), pick(SKIN, i + 2))
		b.line(mp + Vector2(0.0, -8.0), mp + Vector2(-sx * 10.0, -26.0), HIVIS_ORANGE, 3.0)
		b.line(mp + Vector2(0.0, 8.0), mp + Vector2(-sx * 10.0, 26.0), HIVIS_ORANGE, 3.0)
		for k in range(3):
			dolly(b, at.call(60.0 + float(k) * 44.0, 96.0), 0.0, i * 13 + k, k != 1)
		cone(b, at.call(40.0, -40.0))
		cone(b, at.call(40.0, 40.0))


# the yard between two stands: hatched bays with what waits there
static func _yard(b: ShapeBatch, x0: float, x1: float, y: float, i: int) -> void:
	var r := Rect2(x0, y - 110.0, x1 - x0, 220.0)
	for e: float in [r.position.y, r.end.y - 3.0]:
		b.rect(Rect2(r.position.x, e, r.size.x, 3.0), PAINT_WHITE)
	var hx := r.position.x - 40.0
	while hx < r.end.x:
		var a := Vector2(maxf(hx, r.position.x), r.position.y + (maxf(hx, r.position.x) - hx))
		var c := Vector2(minf(hx + 220.0, r.end.x), r.position.y + (minf(hx + 220.0, r.end.x) - hx))
		b.line(a, c, Color(PAINT_WHITE, 0.30), 2.0)
		hx += 46.0
	# cargo cans in a row, a spare dolly, a fuel bowser on the odd ones
	var n := int((x1 - x0) / 52.0)
	for k in range(n):
		var cp := Vector2(x0 + 30.0 + float(k) * 52.0, y - 62.0)
		if h(i * 17 + k) < 0.25:
			continue
		box(b, cp + LIGHT * 6.0, 0.0, 20.0, 18.0, Color(SHADOW, 0.22))
		box(b, cp, 0.0, 20.0, 18.0, STEEL_DARK)
		box(b, cp + Vector2(-1.0, -1.0), 0.0, 18.0, 16.0, STEEL.lightened(h(i + k) * 0.15))
		b.line(cp + Vector2(-18.0, -6.0), cp + Vector2(18.0, -6.0), STEEL_DARK, 1.2)
		box(b, cp + Vector2(0.0, 6.0), 0.0, 7.0, 4.0, pick(LIVERIES, i * 3 + k))
	if i % 2 == 0:
		var fp := Vector2(lerpf(x0, x1, 0.5), y + 48.0)
		box(b, fp + LIGHT * 7.0, 0.0, 44.0, 15.0, Color(SHADOW, 0.22))
		b.capsule(fp + Vector2(-22.0, 0.0), fp + Vector2(22.0, 0.0), 15.0, Color(0.88, 0.89, 0.90))
		b.line(fp + Vector2(-26.0, -5.0), fp + Vector2(26.0, -5.0), PLANE_WHITE, 4.0)
		b.line(fp + Vector2(-30.0, 9.0), fp + Vector2(30.0, 9.0), PAINT_RED, 3.0)
		box(b, fp + Vector2(48.0, 0.0), 0.0, 10.0, 13.0, PAINT_RED.darkened(0.1))
		box(b, fp + Vector2(52.0, 0.0), 0.0, 4.0, 10.0, COCKPIT)
	else:
		for k in range(2):
			dolly(b, Vector2(lerpf(x0, x1, 0.35) + float(k) * 44.0, y + 50.0), 0.0, i * 19 + k, k == 0)


# A boarding bridge from the terminal wall out to a jet's door: the rotunda at
# the wall, the ribbed tunnel, the cab with its bellows against the fuselage,
# the wheeled leg under it. It crosses the head-of-stand road above the
# traffic, so it is drawn over the tugs (draw_bridges, in the world pass).
static func bridge(b: ShapeBatch, a: Vector2, d: Vector2) -> void:
	var f := (d - a).normalized()
	var s := f.orthogonal()
	var sh := LIGHT * 14.0
	b.line(a + sh, d + sh, Color(SHADOW, 0.20), 30.0)
	# the leg and its bogie, out to one side of the tunnel
	var leg := a.lerp(d, 0.62)
	b.line(leg - s * 24.0, leg + s * 24.0, STEEL_DARK, 6.0)
	for w: float in [-1.0, 1.0]:
		box(b, leg + s * w * 24.0, f.angle(), 8.0, 4.0, Color(0.08, 0.08, 0.09))
	b.line(a, d, FRAME, 30.0)
	b.line(a, d - f * 4.0, Color(0.82, 0.83, 0.85), 26.0)
	b.line(a - s * 6.0, d - s * 6.0 - f * 4.0, Color(0.92, 0.93, 0.94), 6.0)
	var n := int(a.distance_to(d) / 14.0)
	for k in range(1, n):
		var q := a.lerp(d, float(k) / float(n))
		b.line(q - s * 13.0, q + s * 13.0, Color(0.66, 0.68, 0.72), 1.4)
	# a strip of the airline's colour down the roof, the stand's light on top
	b.line(a.lerp(d, 0.2) + s * 8.0, a.lerp(d, 0.8) + s * 8.0, PAINT_YELLOW, 3.0)
	# the cab: wider, dark bellows at the door
	box(b, d - f * 12.0, f.angle(), 13.0, 19.0, FRAME)
	box(b, d - f * 13.0, f.angle(), 10.0, 16.0, Color(0.76, 0.78, 0.80))
	box(b, d - f * 1.0, f.angle(), 3.0, 17.0, COCKPIT)
	# the rotunda
	b.circle(a + sh * 0.6, 21.0, Color(SHADOW, 0.18))
	b.circle(a, 21.0, FRAME)
	b.circle(a, 18.0, Color(0.86, 0.87, 0.89))
	b.circle(a - LIGHT * 5.0, 8.0, Color(0.95, 0.95, 0.96))


static func _west_bridge(i: int) -> Array:
	var cy := WEST_STANDS[i]
	if i == WEST_EMPTY:
		return [Vector2(352.0, cy - 150.0), Vector2(262.0, cy - 176.0)]
	return [Vector2(352.0, cy - 150.0), Vector2(WEST_NOSE_X - 64.0, cy - 50.0)]


static func _east_bridge(i: int) -> Array:
	var cy := DESK_YS[i] + 30.0
	return [Vector2(EAST_GLASS + 22.0, cy - 130.0), Vector2(EAST_NOSE_X + 64.0, cy - 50.0)]


static func draw_bridges(b: ShapeBatch, vt: float, vb: float) -> void:
	for i in range(WEST_STANDS.size()):
		if WEST_STANDS[i] - 260.0 > vb or WEST_STANDS[i] + 60.0 < vt:
			continue
		var w := _west_bridge(i)
		bridge(b, w[0], w[1])
	for i in range(DESK_YS.size()):
		if DESK_YS[i] - 240.0 > vb or DESK_YS[i] + 90.0 < vt:
			continue
		var e := _east_bridge(i)
		bridge(b, e[0], e[1])


# what moves out on the apron: a tug and its string of dollies on each road,
# one heading up the pier and one down it
static func draw_apron_live(b: ShapeBatch, vt: float, vb: float) -> void:
	var t := AnimClock.msec() / 1000.0
	var span := 5600.0
	for lane in range(2):
		var x := 339.0 if lane == 0 else 1135.0
		var dirn := 1.0 if lane == 0 else -1.0
		var y := (-5100.0 + fposmod(t * 64.0 + float(lane) * 2300.0, span)) if lane == 0 else (500.0 - fposmod(t * 58.0 + 900.0, span))
		if y < vt - 220.0 or y > vb + 220.0:
			continue
		var ang := PI * 0.5 * dirn
		for k in range(3, 0, -1):
			var wob := sin(t * 3.0 + float(k)) * 1.4
			dolly(b, Vector2(x + wob, y - dirn * float(k) * 46.0), ang, lane * 31 + k)
		tug(b, Vector2(x, y), ang)


# --- the edge layer: everything either side of the concourse ----------------

static func draw_edge(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var gate_y: float = m.GATE_Y
	var top := maxf(vt, gate_y - 60.0)
	var bot := minf(vb, float(m.START_Y) + 620.0)
	if bot <= top:
		return
	_west(m, b, top, bot)
	_east(m, b, top, bot)
	_jet_bridge_walls(b, top, bot)


static func _west(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# far out, for the widest screens: grass, then the runway and its paint
	b.rect(Rect2(-900.0, vt, 500.0, vb - vt), Color(0.30, 0.31, 0.33))
	var ry := floorf(vt / 240.0) * 240.0
	while ry <= vb:
		b.rect(Rect2(-640.0, ry, 8.0, 150.0), PAINT_WHITE)
		ry += 240.0
	b.rect(Rect2(-420.0, vt, 180.0, vb - vt), GRASS)
	b.rect(Rect2(-424.0, vt, 5.0, vb - vt), PAINT_WHITE)
	_apron_ground(b, -240.0, ROAD_W.x, vt, vb)
	# the taxilane behind the tails, with its green centre lights
	b.rect(Rect2(-180.0, vt, 5.0, vb - vt), PAINT_YELLOW)
	var ly := floorf(vt / 90.0) * 90.0
	while ly <= vb:
		b.circle(Vector2(-177.5, ly), 3.0, Color(0.30, 0.90, 0.50))
		ly += 90.0
	_road(b, ROAD_W, vt, vb)
	# under the windows: the kerb, and a zebra at each stand's crossing
	b.rect(Rect2(ROAD_W.y, vt, WALL_L - 8.0 - ROAD_W.y, vb - vt), APRON_JOINT)
	for i in range(WEST_STANDS.size()):
		var cy := WEST_STANDS[i]
		if cy - 480.0 > vb or cy + 480.0 < vt:
			continue
		for k in range(5):
			b.rect(Rect2(ROAD_W.x + 6.0 + float(k) * 10.0, cy - 232.0, 6.0, 30.0), PAINT_WHITE)
		_stand(m, b, Vector2(WEST_NOSE_X, cy), 1.0, ["B21", "B25", "B29"][i], i != WEST_EMPTY, i)
	# the yards between stands
	var yards: Array[float] = [-150.0, -760.0, -2150.0, -3500.0, -4760.0]
	for i in range(yards.size()):
		if yards[i] - 140.0 > vb or yards[i] + 140.0 < vt:
			continue
		_yard(b, 60.0, ROAD_W.x - 14.0, yards[i], i)
	_glass_wall(b, WALL_L, -1.0, vt, minf(vb, 1000.0), PIER_END)


# A floor-to-ceiling glass wall along x, seen from above: the sill, the pane's
# thickness with the sky in it, a mullion every bay and a heavier post every
# fourth. `out` is the side the weather is on. Stops at `stop_y` (the pier end).
static func _glass_wall(b: ShapeBatch, x: float, out: float, vt: float, vb: float, stop_y: float) -> void:
	var top := maxf(vt, stop_y)
	if vb <= top:
		return
	var x0 := x + out * 10.0 if out < 0.0 else x
	b.rect(Rect2(x0, top, 10.0, vb - top), FRAME)
	b.rect(Rect2(x0 + 2.5, top, 5.0, vb - top), GLASS)
	b.rect(Rect2(x0 + 3.5, top, 1.5, vb - top), Color(1.0, 1.0, 1.0, 0.55))
	var my := floorf(top / 80.0) * 80.0
	while my <= vb:
		if my >= top:
			var heavy := int(roundf(my / 80.0)) % 4 == 0
			var w := 16.0 if heavy else 12.0
			b.rect(Rect2(x0 + 5.0 - w * 0.5, my - (3.0 if heavy else 1.5), w, 6.0 if heavy else 3.0), FRAME)
			if heavy:
				b.rect(Rect2(x0 + 5.0 - 5.0, my - 2.0, 10.0, 2.0), FRAME_LIGHT)
		my += 80.0


static func _east(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# beyond the far windows: apron, the road, a jet at every gate
	_apron_ground(b, EAST_GLASS, 1900.0, vt, vb)
	_road(b, ROAD_E, vt, vb)
	for i in range(DESK_YS.size()):
		var cy := DESK_YS[i] + 30.0
		if cy - 480.0 > vb or cy + 480.0 < vt:
			continue
		_stand(m, b, Vector2(EAST_NOSE_X, cy), -1.0, GATE_NUMBERS[i], true, i + 1)
	# the building: a plain floor first, then each room over it
	var room_top := maxf(vt, PIER_END)
	if vb > room_top:
		b.rect(Rect2(WALL_R, room_top, EAST_GLASS - WALL_R, vb - room_top), TERRAZZO_WARM)
		_security(m, b, vt, vb)
		_shop(m, b, vt, vb)
		_cafe(m, b, vt, vb)
		for i in range(DESK_YS.size()):
			_holdroom(m, b, i, vt, vb)
		_between_rooms(m, b, vt, vb)
		_glass_wall(b, EAST_GLASS, 1.0, vt, vb, PIER_END)
		# the pier's end wall
		if PIER_END > vt - 20.0:
			b.rect(Rect2(WALL_R, PIER_END - 10.0, EAST_GLASS + 10.0 - WALL_R, 10.0), FRAME)
			b.rect(Rect2(WALL_R, PIER_END - 8.0, EAST_GLASS + 10.0 - WALL_R, 3.0), FRAME_LIGHT)
	# past the pier's end: the jet this bridge is on. Its wing and an engine,
	# the same wing the cabin sits over (systems/aeroport_cabin.gd)
	if vt < PIER_END:
		AeroportCabin.south_wing(b, float(m.GATE_Y))
		_apron_crew(b, 1.0)


# the glazed partition between a room and the concourse, with a doorway
static func _partition(b: ShapeBatch, y0: float, y1: float, door0: float, door1: float) -> void:
	for seg: Vector2 in [Vector2(y0, door0), Vector2(door1, y1)]:
		if seg.y - seg.x < 4.0:
			continue
		b.rect(Rect2(WALL_R, seg.x, 8.0, seg.y - seg.x), FRAME)
		b.rect(Rect2(WALL_R + 2.0, seg.x, 4.0, seg.y - seg.x), GLASS)
		b.rect(Rect2(WALL_R + 3.0, seg.x, 1.2, seg.y - seg.x), Color(1.0, 1.0, 1.0, 0.5))
		var py := seg.x
		while py <= seg.y:
			b.rect(Rect2(WALL_R - 1.0, py - 1.5, 10.0, 3.0), FRAME)
			py += 60.0
	# the doorway's posts
	for dy: float in [door0, door1]:
		b.rect(Rect2(WALL_R - 2.0, dy - 3.0, 12.0, 6.0), STEEL)


# a cross wall between two rooms, a lit advertisement on its end
static func _cross_wall(b: ShapeBatch, y: float, i: int) -> void:
	b.rect(Rect2(WALL_R, y - 6.0, EAST_GLASS - WALL_R, 12.0), Color(0.90, 0.90, 0.88))
	b.rect(Rect2(WALL_R, y - 6.0, EAST_GLASS - WALL_R, 3.0), Color(0.98, 0.98, 0.97))
	b.rect(Rect2(WALL_R, y + 4.0, EAST_GLASS - WALL_R, 2.0), Color(0.70, 0.70, 0.70))
	# the lightbox facing the concourse
	var ad := Rect2(WALL_R - 2.0, y - 30.0, 10.0, 60.0)
	b.glow(Vector2(WALL_R - 14.0, y), 54.0, Color(1.0, 0.96, 0.84, 0.16), 0.2)
	b.rect(ad, FRAME)
	var cols: Array[Color] = [Color(0.20, 0.62, 0.80), Color(0.94, 0.62, 0.20), Color(0.80, 0.28, 0.46), Color(0.34, 0.66, 0.40)]
	b.rect(ad.grow(-2.0), cols[i % cols.size()])
	b.rect(Rect2(ad.position.x + 2.0, ad.position.y + 8.0, 6.0, 10.0), Color(1.0, 1.0, 1.0, 0.8))


static func _holdroom(m: Node2D, b: ShapeBatch, i: int, vt: float, vb: float) -> void:
	var dy := DESK_YS[i]
	var y0 := dy - HOLD_UP
	var y1 := dy + HOLD_DOWN
	if y0 > vb or y1 < vt:
		return
	var room := Rect2(WALL_R + 8.0, y0, EAST_GLASS - WALL_R - 8.0, y1 - y0)
	# carpet: a field with a woven stripe, a lighter border
	b.rect(room, CARPET_EDGE)
	b.rect(room.grow(-5.0), CARPET)
	var sy := room.position.y + 17.0
	while sy < room.end.y - 8.0:
		b.rect(Rect2(room.position.x + 5.0, sy, room.size.x - 10.0, 2.0), CARPET_LINE)
		sy += 24.0
	# the afternoon through the far windows does not reach here; the near
	# glass throws a soft bar of light across the carpet instead
	b.band(PackedVector2Array([Vector2(room.position.x, y0 + 40.0), Vector2(room.end.x, y0 + 100.0),
		Vector2(room.position.x, y0 + 110.0), Vector2(room.end.x, y0 + 170.0),
		Vector2(room.position.x, y0 + 180.0), Vector2(room.end.x, y0 + 240.0)]), 2,
		Color(1.0, 0.97, 0.86), PackedFloat32Array([0.0, 0.13, 0.0]))
	# two beams of seats back to back, a gap for the way through to the door
	for bx: float in [962.0, 1040.0]:
		for run: Vector2 in [Vector2(y0 + 26.0, dy - 46.0), Vector2(dy + 96.0, y1 - 22.0)]:
			_seat_beam(b, bx, run.x, run.y, i * 100 + int(bx))
	# the boarding door in the far glass, its mat, and the queue for it
	var door := Vector2(EAST_GLASS, dy + 30.0)
	b.rect(Rect2(door.x - 26.0, door.y - 24.0, 30.0, 48.0), Color(0.20, 0.22, 0.26))
	b.rect(Rect2(door.x - 2.0, door.y - 22.0, 14.0, 44.0), Color(0.12, 0.13, 0.16))
	for k in range(4):
		b.rect(Rect2(door.x - 24.0 + float(k) * 6.0, door.y - 22.0, 2.0, 44.0), PAINT_YELLOW.darkened(0.1))
	var queue := 2 + int(h(i * 9) * 4.0)
	for k in range(queue):
		var qp := Vector2(door.x - 40.0 - float(k) * 20.0, door.y + (h(i * 13 + k) - 0.5) * 8.0)
		if k % 2 == 1:
			roller(b, qp + Vector2(4.0, 13.0), PI, pick(BAGS, i * 7 + k), 0.85)
		person(b, qp, 0.0, pick(CLOTHES, i * 5 + k), pick(HAIR, i + k * 3), pick(SKIN, i * 2 + k))
	# the gate's number on a blade over the door to the concourse, and a
	# screen with the flight on it
	var blade := Rect2(WALL_R + 12.0, dy - 58.0, 84.0, 34.0)
	b.rect(Rect2(blade.position + LIGHT * 6.0, blade.size), Color(SHADOW, 0.25))
	b.rect(blade, SIGN_INK)
	b.rect(Rect2(blade.position, Vector2(34.0, blade.size.y)), SIGN_YELLOW)
	# a little plane on the yellow: fuselage, wings, tail
	var pc := blade.position + Vector2(17.0, 17.0)
	b.line(pc + Vector2(-10.0, 0.0), pc + Vector2(10.0, 0.0), SIGN_INK, 4.0)
	b.polygon(PackedVector2Array([pc + Vector2(3.0, 0.0), pc + Vector2(-5.0, -11.0), pc + Vector2(-9.0, -11.0), pc + Vector2(-4.0, 0.0),
		pc + Vector2(-9.0, 11.0), pc + Vector2(-5.0, 11.0)]), SIGN_INK)
	b.draw_string(m.font, Vector2(blade.position.x + 34.0, blade.end.y - 9.0), GATE_NUMBERS[i], HORIZONTAL_ALIGNMENT_CENTER, 50.0, 20, SIGN_YELLOW)
	# doorway through the partition beside the desk
	_partition(b, y0, y1, dy - 44.0, dy - 4.0)
	# a charging post and a plant in the corners
	_plant(b, Vector2(room.end.x - 22.0, y0 + 22.0), i)
	b.circle(Vector2(room.position.x + 20.0, y1 - 22.0), 7.0, STEEL_DARK)
	b.circle(Vector2(room.position.x + 20.0, y1 - 22.0), 5.0, STEEL)
	b.circle(Vector2(room.position.x + 20.0, y1 - 22.0), 2.0, Color(0.30, 0.86, 0.50))


# a run of airport seats on one beam, back to back, with who is waiting
static func _seat_beam(b: ShapeBatch, x: float, y0: float, y1: float, seed: int) -> void:
	if y1 - y0 < 24.0:
		return
	b.rect(Rect2(x - 20.0 + LIGHT.x * 6.0, y0 + LIGHT.y * 6.0, 40.0, y1 - y0), Color(SHADOW, 0.18))
	b.rect(Rect2(x - 2.0, y0 - 3.0, 4.0, y1 - y0 + 6.0), STEEL)
	var y := y0
	var k := 0
	while y + 20.0 <= y1:
		for side: float in [-1.0, 1.0]:
			var sp := Vector2(x + side * 11.0, y + 10.0)
			b.rect(Rect2(sp - Vector2(9.0, 9.0), Vector2(18.0, 18.0)), SEAT)
			b.rect(Rect2(sp - Vector2(7.0, 7.5) + Vector2(side * 1.5, 0.0), Vector2(14.0, 15.0)), SEAT_PAD)
			# the back, toward the beam
			b.rect(Rect2(sp.x - side * 9.0 - 2.0, sp.y - 9.0, 4.0, 18.0), SEAT.lightened(0.12))
			var roll := h(seed * 3 + k * 2 + int(side))
			if roll < 0.34:
				sitter(b, sp, 0.0 if side > 0.0 else PI, seed + k * 2 + int(side))
			elif roll < 0.46:
				box(b, sp, h(seed + k) * 0.6, 7.0, 5.0, pick(BAGS, seed + k))     # a bag keeping a seat
		b.rect(Rect2(x - 20.0, y + 19.0, 40.0, 2.0), STEEL_DARK)
		y += 21.0
		k += 1


static func _plant(b: ShapeBatch, p: Vector2, i: int) -> void:
	b.circle(p + LIGHT * 6.0, 14.0, Color(SHADOW, 0.2))
	b.circle(p, 11.0, STEEL_DARK)
	b.circle(p, 9.0, Color(0.30, 0.24, 0.18))
	for k in range(7):
		var a := TAU * float(k) / 7.0 + h(i) * 2.0
		b.capsule(p, p + Vector2.from_angle(a) * 14.0, 3.6, Color(0.20, 0.44, 0.26))
		b.line(p, p + Vector2.from_angle(a) * 13.0, Color(0.34, 0.60, 0.34), 1.6)


static func _shop(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if SHOP.position.y > vb or SHOP.end.y < vt:
		return
	# duty free: a white gloss floor with a gold inlay, lit from every shelf
	b.rect(SHOP, Color(0.96, 0.95, 0.92))
	b.rect(Rect2(SHOP.position.x + 14.0, SHOP.position.y + 14.0, SHOP.size.x - 28.0, SHOP.size.y - 28.0), Color(0.90, 0.78, 0.40, 0.5))
	b.rect(Rect2(SHOP.position.x + 17.0, SHOP.position.y + 17.0, SHOP.size.x - 34.0, SHOP.size.y - 34.0), Color(0.97, 0.96, 0.94))
	# the back wall's shelves: perfume, in rows of little bottles
	var wall := Rect2(SHOP.end.x - 26.0, SHOP.position.y + 10.0, 20.0, SHOP.size.y - 20.0)
	b.rect(wall, Color(0.24, 0.20, 0.26))
	b.glow(wall.get_center() - Vector2(30.0, 0.0), 150.0, Color(1.0, 0.86, 0.94, 0.20), 0.1)
	var by := wall.position.y + 8.0
	var k := 0
	while by < wall.end.y - 4.0:
		for col in range(2):
			var bp := Vector2(wall.position.x + 6.0 + float(col) * 9.0, by)
			var tint: Color = [Color(0.94, 0.52, 0.76), Color(0.96, 0.80, 0.36), Color(0.56, 0.80, 0.94), Color(0.76, 0.60, 0.92)][(k + col) % 4]
			b.circle(bp, 3.4, tint)
			b.circle(bp + Vector2(-1.0, -1.0), 1.2, Color(1.0, 1.0, 1.0, 0.9))
		by += 9.0
		k += 1
	# gondolas across the floor: chocolate, spirits, sunglasses
	for g in range(4):
		var gr := Rect2(SHOP.position.x + 44.0, SHOP.position.y + 60.0 + float(g) * 122.0, 96.0, 34.0)
		b.rect(Rect2(gr.position + LIGHT * 6.0, gr.size), Color(SHADOW, 0.18))
		b.rect(gr, Color(0.22, 0.20, 0.22))
		b.rect(gr.grow(-3.0), Color(0.94, 0.92, 0.88))
		for n in range(8):
			var ip := gr.position + Vector2(10.0 + float(n % 4) * 25.0, 10.0 + float(n / 4) * 15.0)
			match g % 3:
				0:
					b.polygon(PackedVector2Array([ip + Vector2(-9.0, 4.0), ip + Vector2(9.0, 4.0), ip + Vector2(0.0, -5.0)]), Color(0.90, 0.74, 0.22))
					b.line(ip + Vector2(-5.0, 2.0), ip + Vector2(5.0, 2.0), Color(0.72, 0.20, 0.16), 1.6)
				1:
					b.circle(ip, 4.6, Color(0.20, 0.36, 0.26) if n % 2 == 0 else Color(0.56, 0.30, 0.14))
					b.circle(ip, 1.8, Color(0.86, 0.72, 0.30))
				_:
					b.capsule(ip + Vector2(-4.0, 0.0), ip + Vector2(4.0, 0.0), 3.0, Color(0.12, 0.12, 0.14))
					b.line(ip + Vector2(-3.0, -1.0), ip + Vector2(-1.0, -1.0), Color(0.6, 0.8, 0.9), 1.0)
	# the till by the way in, someone at it
	var till := Rect2(SHOP.position.x + 18.0, SHOP.end.y - 70.0, 60.0, 22.0)
	b.rect(till, Color(0.20, 0.18, 0.20))
	b.rect(till.grow(-2.0), Color(0.90, 0.78, 0.40))
	b.rect(Rect2(till.position.x + 8.0, till.position.y + 5.0, 14.0, 11.0), Color(0.14, 0.15, 0.18))
	person(b, till.get_center() + Vector2(8.0, 22.0), -PI * 0.5, Color(0.12, 0.12, 0.14), pick(HAIR, 4), pick(SKIN, 1))
	person(b, till.get_center() + Vector2(-2.0, -26.0), PI * 0.5, pick(CLOTHES, 5), pick(HAIR, 2), pick(SKIN, 3))
	# browsers
	person(b, Vector2(SHOP.position.x + 150.0, SHOP.position.y + 150.0), 0.0, pick(CLOTHES, 2), pick(HAIR, 7), pick(SKIN, 4))
	person(b, Vector2(SHOP.position.x + 30.0, SHOP.position.y + 260.0), 0.3, pick(CLOTHES, 9), pick(HAIR, 1), pick(SKIN, 0))
	roller(b, Vector2(SHOP.position.x + 30.0, SHOP.position.y + 278.0), PI * 0.5, pick(BAGS, 3), 0.9)
	# its front to the concourse: gold posts, and the name over the way in
	for py: float in [SHOP.position.y, SHOP.position.y + 190.0, SHOP.position.y + 370.0, SHOP.end.y]:
		b.rect(Rect2(WALL_R - 3.0, py - 7.0, 14.0, 14.0), Color(0.90, 0.78, 0.40))
		b.rect(Rect2(WALL_R - 1.0, py - 5.0, 10.0, 10.0), Color(0.99, 0.92, 0.62))
	var sign := Rect2(WALL_R + 16.0, SHOP.position.y + 198.0, 34.0, 164.0)
	b.rect(sign, SIGN_INK)
	b.draw_set_transform(Vector2(sign.position.x + 9.0, sign.position.y), PI * 0.5, Vector2.ONE)
	b.draw_string(m.font, Vector2(0.0, 0.0), "DUTY FREE", HORIZONTAL_ALIGNMENT_CENTER, sign.size.y, 20, Color(0.99, 0.88, 0.50))
	b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _cafe(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if CAFE.position.y > vb or CAFE.end.y < vt:
		return
	# a warm timber floor, the counter along the back, tables out front
	b.rect(CAFE, Color(0.70, 0.56, 0.40))
	var py := CAFE.position.y
	while py < CAFE.end.y:
		b.rect(Rect2(CAFE.position.x, py, CAFE.size.x, 1.5), Color(0.58, 0.45, 0.32))
		py += 18.0
	b.glow(CAFE.get_center() + Vector2(40.0, 0.0), 170.0, Color(1.0, 0.86, 0.56, 0.20), 0.1)
	var bar := Rect2(CAFE.end.x - 56.0, CAFE.position.y + 16.0, 26.0, CAFE.size.y - 32.0)
	b.rect(Rect2(bar.position + LIGHT * 6.0, bar.size), Color(SHADOW, 0.2))
	b.rect(bar, Color(0.24, 0.18, 0.14))
	b.rect(bar.grow(-3.0), Color(0.92, 0.90, 0.84))
	# the machine, the cups, a tray of ensaimades under glass
	b.rect(Rect2(bar.position.x + 5.0, bar.position.y + 12.0, 16.0, 30.0), STEEL)
	b.rect(Rect2(bar.position.x + 7.0, bar.position.y + 14.0, 12.0, 8.0), STEEL_DARK)
	for k in range(4):
		b.circle(Vector2(bar.position.x + 13.0, bar.position.y + 56.0 + float(k) * 9.0), 3.2, Color(0.98, 0.98, 0.96))
	var tray := Rect2(bar.position.x + 4.0, bar.end.y - 84.0, 18.0, 64.0)
	b.rect(tray, Color(0.70, 0.84, 0.90, 0.6))
	for k in range(5):
		var ep := Vector2(tray.get_center().x, tray.position.y + 9.0 + float(k) * 12.0)
		b.circle(ep, 5.0, Color(0.92, 0.76, 0.48))
		b.circle(ep, 2.6, Color(0.98, 0.92, 0.80))
	person(b, Vector2(bar.end.x + 12.0, bar.get_center().y - 20.0), PI, Color(0.20, 0.20, 0.22), pick(HAIR, 3), pick(SKIN, 2))
	for k in range(3):
		var tp := Vector2(CAFE.position.x + 48.0 + float(k % 2) * 46.0, CAFE.position.y + 48.0 + float(k) * 82.0)
		b.circle(tp + LIGHT * 6.0, 15.0, Color(SHADOW, 0.2))
		for c in range(2):
			var cp := tp + Vector2(0.0, -22.0 if c == 0 else 22.0)
			b.circle(cp, 7.5, Color(0.26, 0.20, 0.16))
			b.circle(cp, 5.8, Color(0.80, 0.34, 0.24))
			if h(k * 2 + c) < 0.6:
				sitter(b, cp, PI * 0.5 if c == 0 else -PI * 0.5, 40 + k * 2 + c)
		b.circle(tp, 14.0, Color(0.30, 0.22, 0.16))
		b.circle(tp, 12.0, Color(0.86, 0.80, 0.70))
		b.circle(tp + Vector2(-4.0, -2.0), 3.0, Color(0.98, 0.98, 0.96))
		b.circle(tp + Vector2(-4.0, -2.0), 1.8, Color(0.36, 0.24, 0.16))
		b.circle(tp + Vector2(5.0, 3.0), 4.0, Color(0.92, 0.76, 0.48))
	# the chalkboard out front, and the name on the fascia
	var sign := Rect2(WALL_R + 14.0, CAFE.position.y + 70.0, 30.0, 120.0)
	b.rect(sign, Color(0.20, 0.30, 0.24))
	b.draw_set_transform(Vector2(sign.position.x + 7.0, sign.position.y), PI * 0.5, Vector2.ONE)
	b.draw_string(m.font, Vector2(0.0, 0.0), "CAFÈ", HORIZONTAL_ALIGNMENT_CENTER, sign.size.y, 20, Color(0.98, 0.96, 0.88))
	b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for ey: float in [CAFE.position.y, CAFE.end.y]:
		b.rect(Rect2(WALL_R - 3.0, ey - 6.0, 14.0, 12.0), Color(0.30, 0.22, 0.16))


# Before the pier: the security hall. Two lanes of rollers and trays into the
# scanners, the arch you walk through, the staff, the bins of forbidden water.
static func _security(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top := SECURITY_Y - 60.0
	var bot := float(m.START_Y) + 620.0
	if top > vb or bot < vt:
		return
	b.rect(Rect2(WALL_R, top, EAST_GLASS - WALL_R, bot - top), Color(0.78, 0.79, 0.80))
	var jy := top
	while jy < bot:
		b.rect(Rect2(WALL_R, jy, EAST_GLASS - WALL_R, 1.2), Color(0.68, 0.69, 0.70))
		jy += 60.0
	for lane in range(3):
		var ly := -240.0 + float(lane) * 190.0
		var belt := Rect2(WALL_R + 26.0, ly, 150.0, 30.0)
		b.rect(Rect2(belt.position + LIGHT * 6.0, belt.size), Color(SHADOW, 0.2))
		b.rect(belt, STEEL_DARK)
		b.rect(belt.grow(-3.0), Color(0.16, 0.16, 0.18))
		var rx := belt.position.x + 6.0
		while rx < belt.end.x - 4.0:
			b.rect(Rect2(rx, belt.position.y + 3.0, 1.5, belt.size.y - 6.0), Color(0.34, 0.35, 0.38))
			rx += 7.0
		# trays: a laptop in one, shoes in another, a coat
		for k in range(3):
			var tp := Vector2(belt.position.x + 20.0 + float(k) * 26.0, belt.get_center().y)
			if h(lane * 5 + k) < 0.2:
				continue
			box(b, tp, 0.0, 10.0, 11.0, Color(0.56, 0.58, 0.62))
			box(b, tp, 0.0, 8.0, 9.0, Color(0.70, 0.72, 0.76))
			match (lane + k) % 3:
				0: box(b, tp, 0.2, 6.0, 4.5, Color(0.18, 0.19, 0.22))
				1:
					b.capsule(tp + Vector2(-3.0, -3.0), tp + Vector2(-3.0, 3.0), 2.4, Color(0.50, 0.32, 0.20))
					b.capsule(tp + Vector2(3.0, -3.0), tp + Vector2(3.0, 3.0), 2.4, Color(0.50, 0.32, 0.20))
				_: b.circle(tp, 6.0, pick(CLOTHES, lane + k))
		# the scanner's hood over the belt, its lead curtain, the screen
		var hood := Rect2(belt.position.x + 92.0, belt.position.y - 8.0, 44.0, 46.0)
		b.rect(Rect2(hood.position + LIGHT * 8.0, hood.size), Color(SHADOW, 0.22))
		b.rect(hood, Color(0.86, 0.87, 0.88))
		b.rect(Rect2(hood.position, Vector2(hood.size.x, 6.0)), Color(0.96, 0.96, 0.97))
		b.rect(Rect2(hood.position.x, hood.position.y + 8.0, 4.0, 30.0), Color(0.14, 0.14, 0.16))
		b.rect(Rect2(hood.position.x + 12.0, hood.position.y + 12.0, 20.0, 12.0), SIGN_NAVY)
		b.rect(Rect2(hood.position.x + 14.0, hood.position.y + 14.0, 8.0, 5.0), Color(0.30, 0.86, 0.50))
		# the arch beside it, and an officer waving the next one through
		var arch := Vector2(belt.position.x + 114.0, belt.end.y + 34.0)
		b.rect(Rect2(arch.x - 4.0, arch.y - 22.0, 8.0, 6.0), STEEL_DARK)
		b.rect(Rect2(arch.x - 4.0, arch.y + 16.0, 8.0, 6.0), STEEL_DARK)
		b.rect(Rect2(arch.x - 2.0, arch.y - 18.0, 4.0, 36.0), Color(0.60, 0.90, 0.70, 0.5))
		person(b, arch + Vector2(26.0, 0.0), PI, SIGN_NAVY, pick(HAIR, lane), pick(SKIN, lane + 1))
		person(b, arch + Vector2(-30.0, 2.0), 0.0, pick(CLOTHES, lane * 3 + 1), pick(HAIR, lane + 4), pick(SKIN, lane))
	# where the water goes
	for k in range(2):
		var bp := Vector2(WALL_R + 26.0 + float(k) * 24.0, top + 34.0)
		b.circle(bp + LIGHT * 5.0, 10.0, Color(SHADOW, 0.2))
		b.circle(bp, 10.0, STEEL_DARK)
		b.circle(bp, 8.0, Color(0.56, 0.78, 0.92) if k == 0 else Color(0.20, 0.20, 0.22))
	_partition(b, top, bot, -120.0, 40.0)
	b.rect(Rect2(WALL_R, top - 6.0, EAST_GLASS - WALL_R, 12.0), Color(0.90, 0.90, 0.88))


# what stands between the rooms: cross walls with their adverts, and where
# there is no room at all, a blank wall with vending machines against it
static func _between_rooms(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var spans: Array[Vector2] = [Vector2(SHOP.position.y, SHOP.end.y), Vector2(CAFE.position.y, CAFE.end.y)]
	for dy: float in DESK_YS:
		spans.append(Vector2(dy - HOLD_UP, dy + HOLD_DOWN))
	spans.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.x < c.x)
	var prev := PIER_END
	var k := 0
	for sp: Vector2 in spans:
		if sp.x - prev > 30.0 and prev < vb and sp.x > vt:
			# a stretch of plain wall: vending, a defibrillator, a map
			b.rect(Rect2(WALL_R, prev, 12.0, sp.x - prev), Color(0.92, 0.92, 0.90))
			b.rect(Rect2(WALL_R + 12.0, prev, EAST_GLASS - WALL_R - 12.0, sp.x - prev), Color(0.66, 0.67, 0.70))
			var vy := prev + 24.0
			var n := 0
			while vy + 40.0 < sp.x:
				var vr := Rect2(WALL_R - 22.0, vy, 22.0, 36.0)
				b.rect(Rect2(vr.position + LIGHT * 5.0, vr.size), Color(SHADOW, 0.2))
				var body: Color = [Color(0.80, 0.16, 0.16), Color(0.16, 0.36, 0.70), Color(0.94, 0.94, 0.92)][(k + n) % 3]
				b.rect(vr, body)
				b.rect(Rect2(vr.position.x + 2.0, vr.position.y + 3.0, 6.0, 30.0), Color(0.12, 0.13, 0.16))
				for d in range(4):
					b.circle(Vector2(vr.position.x + 5.0, vr.position.y + 7.0 + float(d) * 7.0), 1.6, pick(BAGS, k + n + d))
				b.glow(Vector2(vr.position.x - 8.0, vr.get_center().y), 34.0, Color(body, 0.14), 0.2)
				vy += 52.0
				n += 1
		if sp.x > vt - 40.0 and sp.x < vb + 40.0:
			_cross_wall(b, sp.x, k)
		if sp.y > vt - 40.0 and sp.y < vb + 40.0:
			_cross_wall(b, sp.y, k + 1)
		prev = sp.y
		k += 1


# the last stretch is the bridge out to the jet: ribbed steel walls either
# side with slit windows, the apron below
static func _jet_bridge_walls(b: ShapeBatch, vt: float, vb: float) -> void:
	if vt >= PIER_END:
		return
	var top := vt
	var bot := minf(vb, PIER_END)
	if vt < PIER_END:
		_apron_ground(b, ROAD_W.x - 400.0, WALL_L, top, bot)
		_apron_crew(b, -1.0)
	for side: float in [-1.0, 1.0]:
		var x := WALL_L - 22.0 if side < 0.0 else WALL_R
		b.rect(Rect2(x + LIGHT.x * 14.0, top, 22.0, bot - top), Color(SHADOW, 0.18))
		b.rect(Rect2(x, top, 22.0, bot - top), FRAME)
		b.rect(Rect2(x + 3.0, top, 16.0, bot - top), Color(0.82, 0.83, 0.85))
		b.rect(Rect2(x + 5.0, top, 4.0, bot - top), Color(0.93, 0.93, 0.94))
		var ry := floorf(top / 16.0) * 16.0
		while ry < bot:
			b.rect(Rect2(x + 3.0, ry, 16.0, 1.4), Color(0.66, 0.68, 0.72))
			ry += 16.0
		var wy := floorf(top / 110.0) * 110.0
		while wy < bot:
			if wy > top + 10.0 and wy < bot - 50.0:
				var inner := x + 16.0 if side < 0.0 else x
				b.rect(Rect2(inner, wy, 6.0, 44.0), GLASS)
				b.rect(Rect2(inner + 2.0, wy, 1.4, 44.0), Color(1.0, 1.0, 1.0, 0.6))
			wy += 110.0
	# the bellows where the bridge meets the pier
	b.rect(Rect2(WALL_L - 26.0, PIER_END - 16.0, 30.0, 16.0), COCKPIT)
	b.rect(Rect2(WALL_R - 4.0, PIER_END - 16.0, 30.0, 16.0), COCKPIT)


# the ground crew under the bridge, either side of it
static func _apron_crew(b: ShapeBatch, side: float) -> void:
	if side < 0.0:
		# a catering truck backed up, its box raised on the scissor lift
		var tp := Vector2(250.0, -4860.0)
		box(b, tp + LIGHT * 12.0, 0.0, 52.0, 22.0, Color(SHADOW, 0.22))
		box(b, tp, 0.0, 52.0, 22.0, STEEL_DARK)
		box(b, tp + Vector2(6.0, 0.0), 0.0, 44.0, 20.0, PLANE_WHITE)
		b.line(tp + Vector2(-34.0, -14.0), tp + Vector2(46.0, -14.0), LIVERIES[0], 5.0)
		box(b, tp + Vector2(-46.0, 0.0), 0.0, 8.0, 17.0, COCKPIT)
		cone(b, tp + Vector2(70.0, 34.0))
		cone(b, tp + Vector2(-66.0, 34.0))
		person(b, Vector2(318.0, -4790.0), 0.6, HIVIS, pick(HAIR, 8), pick(SKIN, 2))
		for k in range(2):
			dolly(b, Vector2(200.0 + float(k) * 46.0, -4712.0), 0.0, 60 + k)
	else:
		person(b, Vector2(968.0, -4700.0), -1.0, HIVIS_ORANGE, pick(HAIR, 5), pick(SKIN, 1))
		cone(b, Vector2(940.0, -4760.0))
		cone(b, Vector2(1010.0, -4690.0))


# --- the concourse floor (the cached ground layer) ---------------------------

static func draw_floor(m: Node2D, b: ShapeBatch, vt: float, vb: float, ctop: float, bottom: float) -> void:
	var top := maxf(vt, ctop + 36.0)
	var bot := minf(vb, bottom)
	if bot <= top:
		return
	var w := WALL_R - WALL_L
	b.rect(Rect2(WALL_L, top, w, bot - top), TERRAZZO)
	# big slabs, laid in courses, every other one a shade warmer
	var sy := floorf(top / 130.0) * 130.0
	while sy < bot:
		var row := int(roundf(sy / 130.0))
		for col in range(4):
			if (row + col) % 2 == 0:
				b.rect(Rect2(WALL_L + float(col) * 130.0, sy, 130.0, 130.0), Color(TERRAZZO_WARM, 0.55))
		b.rect(Rect2(WALL_L, sy, w, 1.2), JOINT)
		sy += 130.0
	for col in range(1, 4):
		b.rect(Rect2(WALL_L + float(col) * 130.0, top, 1.2, bot - top), JOINT)
	# a granite border round the walkway's pit
	var z := Aeroport.WALKWAY_RECT
	if z.end.y + 60.0 > top and z.position.y - 60.0 < bot:
		var pit := z.grow_individual(22.0, 46.0, 22.0, 46.0)
		b.rect(pit, GRANITE)
		b.rect(pit.grow(-5.0), Color(0.56, 0.57, 0.60))
	# the tactile path for a cane: a ribbed strip down the west lane
	b.rect(Rect2(498.0, top, 14.0, bot - top), Color(0.80, 0.79, 0.74))
	for k in range(3):
		b.rect(Rect2(500.5 + float(k) * 4.0, top, 1.6, bot - top), Color(0.66, 0.65, 0.60))
	# carpet where a gate's seats stand in the concourse
	for i in range(DESK_YS.size()):
		var dy := DESK_YS[i]
		if dy - HOLD_UP > bot or dy + HOLD_DOWN < top:
			continue
		var cr := Rect2(742.0, dy - HOLD_UP + 30.0, WALL_R - 742.0, HOLD_UP + HOLD_DOWN - 60.0)
		b.polygon(m.round_rect_pts(cr.grow(4.0), 18.0), CARPET_EDGE)
		b.polygon(m.round_rect_pts(cr, 15.0), CARPET)
		var ly := cr.position.y + 16.0
		while ly < cr.end.y - 10.0:
			b.rect(Rect2(cr.position.x + 8.0, ly, cr.size.x - 8.0, 2.0), CARPET_LINE)
			ly += 24.0
		# and the lane to the desk, taped off on the floor
		b.rect(Rect2(760.0, dy + 66.0, 130.0, 3.0), PAINT_YELLOW)
		b.rect(Rect2(760.0, dy - 8.0, 130.0, 3.0), PAINT_YELLOW)
	_jet_bridge_floor(b, top, bot)
	_roof_light(b, top, bot)
	_floor_signs(m, b, top, bot)
	_queue(b, top, bot)
	_furniture(m, b, top, bot)


# What the roof does to the floor: sun through the west glass in a slanted bar
# per bay, a beam's shadow across the hall at every pair of columns, and the
# long rooflight's soft bright band between them. Gradients, never bars.
static func _roof_light(b: ShapeBatch, vt: float, vb: float) -> void:
	var top := maxf(vt, PIER_END)
	if vb <= top:
		return
	var by := floorf(top / 80.0) * 80.0 - 80.0
	while by < vb:
		if by + 80.0 > PIER_END:
			var y0 := by + 8.0
			var y1 := by + 72.0
			b.band(PackedVector2Array([Vector2(WALL_L, y0), Vector2(WALL_L + 150.0, y0 + 86.0),
				Vector2(WALL_L, y1), Vector2(WALL_L + 150.0, y1 + 86.0)]), 2,
				Color(1.0, 0.96, 0.82, 0.30), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
		by += 80.0
	var py := floorf(top / 600.0) * 600.0 - 600.0
	while py < vb + 600.0:
		if py > PIER_END - 10.0 and py < 400.0:
			# the beam between a pair of columns, its shadow thrown down-right
			b.band(PackedVector2Array([Vector2(WALL_L, py + 8.0), Vector2(WALL_R, py + 8.0),
				Vector2(WALL_L, py + 30.0), Vector2(WALL_R, py + 30.0),
				Vector2(WALL_L, py + 58.0), Vector2(WALL_R, py + 58.0)]), 2,
				Color(SHADOW, 0.16), PackedFloat32Array([0.0, 1.0, 0.0]))
			# purlins, thinner, between the beams
			for k in range(1, 4):
				var qy := py + float(k) * 150.0
				b.band(PackedVector2Array([Vector2(WALL_L, qy), Vector2(WALL_R, qy),
					Vector2(WALL_L, qy + 9.0), Vector2(WALL_R, qy + 9.0),
					Vector2(WALL_L, qy + 18.0), Vector2(WALL_R, qy + 18.0)]), 2,
					Color(SHADOW, 0.07), PackedFloat32Array([0.0, 1.0, 0.0]))
			# the rooflight between this beam and the next
			b.band(PackedVector2Array([Vector2(430.0, py + 150.0), Vector2(850.0, py + 150.0),
				Vector2(430.0, py + 300.0), Vector2(850.0, py + 300.0),
				Vector2(430.0, py + 450.0), Vector2(850.0, py + 450.0)]), 2,
				Color(1.0, 1.0, 0.98, 0.20), PackedFloat32Array([0.0, 1.0, 0.0]))
		py += 600.0
	# downlights mirrored in the polish, down both lanes
	var gy := floorf(top / 200.0) * 200.0
	while gy < vb:
		if gy > PIER_END + 40.0:
			b.glow(Vector2(452.0, gy + 100.0), 30.0, Color(1.0, 1.0, 1.0, 0.22), 0.1)
			b.glow(Vector2(800.0, gy + 100.0), 30.0, Color(1.0, 1.0, 1.0, 0.22), 0.1)
		gy += 200.0


static func _jet_bridge_floor(b: ShapeBatch, vt: float, vb: float) -> void:
	if vt >= PIER_END:
		return
	var bot := minf(vb, PIER_END)
	b.rect(Rect2(WALL_L, vt, WALL_R - WALL_L, bot - vt), Color(0.42, 0.44, 0.48))
	var ry := floorf(vt / 12.0) * 12.0
	while ry < bot:
		b.rect(Rect2(WALL_L, ry, WALL_R - WALL_L, 1.6), Color(0.34, 0.36, 0.40))
		ry += 12.0
	# a runner of blue carpet down the middle, yellow at the walls
	b.rect(Rect2(500.0, vt, 280.0, bot - vt), CARPET.darkened(0.1))
	b.rect(Rect2(500.0, vt, 4.0, bot - vt), CARPET_LINE)
	b.rect(Rect2(776.0, vt, 4.0, bot - vt), CARPET_LINE)
	for x: float in [WALL_L + 6.0, WALL_R - 12.0]:
		b.rect(Rect2(x, vt, 6.0, bot - vt), PAINT_YELLOW)
	# the telescoping joints: a steel lip across, hazard-striped
	for jy: float in [PIER_END - 6.0, PIER_END - 190.0]:
		if jy < vt - 10.0 or jy > vb:
			continue
		b.rect(Rect2(WALL_L, jy - 6.0, WALL_R - WALL_L, 12.0), STEEL)
		var hx := WALL_L
		while hx < WALL_R:
			b.quad(Vector2(hx, jy + 6.0), Vector2(hx + 10.0, jy + 6.0), Vector2(hx + 20.0, jy - 6.0), Vector2(hx + 10.0, jy - 6.0), SIGN_INK)
			hx += 26.0
	# daylight from the slit windows
	var wy := floorf(vt / 110.0) * 110.0
	while wy < bot:
		if wy > vt + 10.0 and wy < bot - 50.0:
			b.band(PackedVector2Array([Vector2(WALL_L, wy), Vector2(WALL_L + 110.0, wy + 64.0),
				Vector2(WALL_L, wy + 44.0), Vector2(WALL_L + 110.0, wy + 108.0)]), 2,
				Color(1.0, 0.96, 0.82, 0.22), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.0]))
		wy += 110.0


# what is set into the floor: where the gates are, and which way
static func _floor_signs(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	for sy: float in [-700.0, -2000.0, -3300.0]:
		if sy - 80.0 > vb or sy + 80.0 < vt:
			continue
		var r := Rect2(398.0, sy - 34.0, 92.0, 68.0)
		b.polygon(m.round_rect_pts(r, 8.0), SIGN_YELLOW)
		b.polygon(m.round_rect_pts(r.grow(-3.0), 6.0), Color(0.99, 0.87, 0.24))
		# an arrow up the pier
		var ac := r.position + Vector2(20.0, 34.0)
		b.line(ac + Vector2(0.0, 18.0), ac + Vector2(0.0, -10.0), SIGN_INK, 6.0)
		b.polygon(PackedVector2Array([ac + Vector2(-13.0, -6.0), ac + Vector2(13.0, -6.0), ac + Vector2(0.0, -22.0)]), SIGN_INK)
		b.draw_string(m.font, Vector2(r.position.x + 36.0, r.position.y + 30.0), "B20", HORIZONTAL_ALIGNMENT_LEFT, 56.0, 19, SIGN_INK)
		b.draw_string(m.font, Vector2(r.position.x + 36.0, r.position.y + 54.0), "B30", HORIZONTAL_ALIGNMENT_LEFT, 56.0, 19, SIGN_INK)
	# feet painted at each end of the walkway: stand right, walk left
	var z := Aeroport.WALKWAY_RECT
	for ey: float in [z.end.y + 30.0, z.position.y - 30.0]:
		if ey < vt - 30.0 or ey > vb + 30.0:
			continue
		for k in range(2):
			var fp := Vector2(z.get_center().x + 36.0 + float(k) * 12.0, ey)
			b.capsule(fp + Vector2(0.0, -5.0), fp + Vector2(0.0, 5.0), 4.0, Color(PAINT_YELLOW, 0.85))


# The queue at gate B22: posts and red belts in a switchback, and a closed
# lane across the west side, so a line of tape runs the width of the hall at
# QUEUE_Y. It is what the security squad runs into on the way home. Belts
# hang at knee height: she goes under, and it never stops your human.
static func _queue(b: ShapeBatch, vt: float, vb: float) -> void:
	if QUEUE_Y - 220.0 > vb or QUEUE_Y + 60.0 < vt:
		return
	var runs: Array = []
	# the switchback from the desk down to the line
	for k in range(3):
		var y := QUEUE_Y - 150.0 + float(k) * 75.0
		runs.append([Vector2(748.0, y), Vector2(884.0, y)])
	runs.append([Vector2(748.0, QUEUE_Y - 150.0), Vector2(748.0, QUEUE_Y)])
	# the closed lane west of the walkway
	runs.append([Vector2(398.0, QUEUE_Y), Vector2(536.0, QUEUE_Y)])
	for run: Array in runs:
		var a: Vector2 = run[0]
		var c: Vector2 = run[1]
		var n := maxi(1, int(roundf(a.distance_to(c) / 68.0)))
		for k in range(n):
			var p0 := a.lerp(c, float(k) / float(n))
			var p1 := a.lerp(c, float(k + 1) / float(n))
			b.line(p0 + LIGHT * 7.0, p1 + LIGHT * 7.0, Color(SHADOW, 0.14), 4.0)
			b.line(p0, p1, BELT_RED.darkened(0.25), 5.0)
			b.line(p0, p1, BELT_RED, 3.4)
		for k in range(n + 1):
			stanchion(b, a.lerp(c, float(k) / float(n)))
	# the sign on the closed lane
	var sp := Vector2(467.0, QUEUE_Y - 16.0)
	box(b, sp, 0.0, 24.0, 8.0, SIGN_INK)
	box(b, sp, 0.0, 22.0, 6.0, PAINT_RED)
	b.line(sp + Vector2(-14.0, 0.0), sp + Vector2(14.0, 0.0), PAINT_WHITE, 3.0)
	# who is in the queue
	for k in range(4):
		var qp := Vector2(770.0 + float(k) * 28.0, QUEUE_Y - 112.0 + (h(k + 70) - 0.5) * 10.0)
		person(b, qp, 0.0, pick(CLOTHES, k + 71), pick(HAIR, k + 72), pick(SKIN, k + 73))
		if k % 2 == 0:
			roller(b, qp + Vector2(-13.0, 4.0), PI, pick(BAGS, k + 74), 0.85)


# a queue post: weighted base, chrome post, the belt's cassette on top
static func stanchion(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + LIGHT * 4.0, 8.0, Color(SHADOW, 0.22))
	b.circle(p, 8.0, Color(0.16, 0.16, 0.18))
	b.circle(p, 6.4, Color(0.26, 0.27, 0.30))
	b.circle(p, 3.6, STEEL)
	b.circle(p - LIGHT * 1.2, 1.6, Color(0.96, 0.96, 0.98))


# what stands on the floor and never moves: the desks, the two islands, the
# carousel's housing
static func _furniture(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	for i in range(Aeroport.GATE_DESKS.size()):
		var d: Rect2 = Aeroport.GATE_DESKS[i]
		if d.end.y < vt - 40.0 or d.position.y > vb + 40.0:
			continue
		_desk(m, b, d, i)
	var per: Rect2 = Aeroport.PERFUME_ISLAND
	if per.end.y > vt - 60.0 and per.position.y < vb + 60.0:
		_perfume(m, b, per)
	var cho: Rect2 = Aeroport.CHOCOLATE_ISLAND
	if cho.end.y > vt - 60.0 and cho.position.y < vb + 60.0:
		_chocolate(m, b, cho)
	var car: Rect2 = Aeroport.CAROUSEL_RECT
	if car.end.y > vt - 60.0 and car.position.y < vb + 60.0:
		_carousel(m, b, car)


static func _desk(m: Node2D, b: ShapeBatch, d: Rect2, i: int) -> void:
	m.box_shadow(b, d, 4.0, 8.0)
	b.polygon(m.round_rect_pts(d, 5.0), SIGN_NAVY)
	b.polygon(m.round_rect_pts(Rect2(d.position + Vector2(8.0, 3.0), d.size - Vector2(11.0, 6.0)), 4.0), Color(0.84, 0.85, 0.87))
	# the front the passenger sees: a band of yellow with the gate on it
	b.rect(Rect2(d.position.x, d.position.y + 4.0, 7.0, d.size.y - 8.0), SIGN_YELLOW)
	# two screens, a boarding-pass reader, a phone, a stack of tags
	for k in range(2):
		var sp := Vector2(d.position.x + 30.0, d.position.y + 16.0 + float(k) * 28.0)
		box(b, sp, 0.0, 3.0, 9.0, SIGN_INK)
		box(b, sp + Vector2(-1.0, 0.0), 0.0, 1.4, 7.5, Color(0.50, 0.76, 0.96))
		box(b, sp + Vector2(-11.0, 0.0), 0.0, 4.0, 7.0, Color(0.30, 0.31, 0.34))
	b.circle(Vector2(d.position.x + 14.0, d.get_center().y), 3.0, Color(0.20, 0.86, 0.46))
	# the agent behind it, facing the hall
	var agent := Vector2(d.end.x - 4.0, d.position.y + 18.0 + float(i % 2) * 24.0)
	b.capsule(agent + Vector2(0.0, -6.0), agent + Vector2(0.0, 6.0), 5.4, SIGN_NAVY.lightened(0.12))
	b.circle(agent, 5.4, pick(HAIR, i * 3 + 1))
	b.circle(agent + Vector2(-2.2, 0.0), 4.0, pick(SKIN, i))
	b.line(agent + Vector2(-4.0, 5.0), agent + Vector2(-4.0, 8.0), PAINT_RED, 2.4)      # a neckerchief


static func _perfume(m: Node2D, b: ShapeBatch, r: Rect2) -> void:
	# the pyramid: glass tiers stepping up to one enormous bottle, under lights
	b.glow(r.get_center(), 96.0, Color(1.0, 0.80, 0.92, 0.22), 0.2)
	m.box_shadow(b, r, 6.0, 10.0)
	b.polygon(m.round_rect_pts(r, 6.0), Color(0.20, 0.17, 0.22))
	b.polygon(m.round_rect_pts(r.grow(-3.0), 5.0), Color(0.96, 0.94, 0.95))
	for tier in range(3):
		var tr := r.grow(-8.0 - float(tier) * 9.0)
		b.rect(Rect2(tr.position + LIGHT * 2.5, tr.size), Color(SHADOW, 0.14))
		b.rect(tr, Color(0.80, 0.90, 0.95, 0.75))
		b.rect(Rect2(tr.position, Vector2(tr.size.x, 1.5)), Color(1.0, 1.0, 1.0, 0.9))
		var n := 7 - tier * 2
		for k in range(n):
			for row in range(2):
				var bp := Vector2(lerpf(tr.position.x + 5.0, tr.end.x - 5.0, float(k) / float(maxi(1, n - 1))),
					tr.position.y + 4.0 if row == 0 else tr.end.y - 4.0)
				var tint: Color = [Color(0.94, 0.46, 0.72), Color(0.98, 0.80, 0.36), Color(0.60, 0.50, 0.90), Color(0.50, 0.82, 0.86)][(k + tier + row) % 4]
				b.circle(bp, 3.2, tint)
				b.circle(bp + Vector2(0.0, -2.6 if row == 0 else 2.6), 1.3, Color(0.92, 0.78, 0.30))
				b.circle(bp + Vector2(-0.9, -0.9), 1.0, Color(1.0, 1.0, 1.0, 0.9))
	var c := r.get_center()
	b.circle(c, 9.0, Color(0.92, 0.78, 0.30))
	b.circle(c, 7.4, Color(0.96, 0.52, 0.76))
	b.circle(c + Vector2(-2.2, -2.2), 2.6, Color(1.0, 0.90, 0.96))
	b.rect(Rect2(c.x - 2.5, c.y - 12.0, 5.0, 5.0), Color(0.92, 0.78, 0.30))


static func _chocolate(m: Node2D, b: ShapeBatch, r: Rect2) -> void:
	b.glow(r.get_center(), 86.0, Color(1.0, 0.88, 0.56, 0.20), 0.2)
	m.box_shadow(b, r, 6.0, 10.0)
	b.polygon(m.round_rect_pts(r, 6.0), Color(0.30, 0.20, 0.14))
	b.polygon(m.round_rect_pts(r.grow(-3.0), 5.0), Color(0.48, 0.32, 0.20))
	# the giant bars in a fan, gold card with the red lettering stripe
	for k in range(5):
		var a := -0.5 + float(k) * 0.25
		var cp := r.get_center() + Vector2((float(k) - 2.0) * 13.0, 3.0 - absf(float(k) - 2.0) * 2.0)
		var f := Vector2.from_angle(a - PI * 0.5)
		var s := f.orthogonal()
		b.polygon(PackedVector2Array([cp - s * 6.0 + f * 16.0, cp + s * 6.0 + f * 16.0, cp + s * 6.0 - f * 14.0, cp - s * 6.0 - f * 14.0]),
			Color(0.90, 0.72, 0.20) if k % 2 == 0 else Color(0.96, 0.82, 0.34))
		b.line(cp - s * 5.0 + f * 4.0, cp + s * 5.0 + f * 4.0, Color(0.76, 0.16, 0.14), 3.0)
		b.line(cp - s * 3.6 - f * 10.0, cp - s * 3.6 + f * 14.0, Color(1.0, 0.94, 0.62), 1.2)
	# a ribbon across the front and a price on a spike
	b.rect(Rect2(r.position.x + 4.0, r.end.y - 11.0, r.size.x - 8.0, 5.0), Color(0.76, 0.16, 0.14))
	b.circle(Vector2(r.end.x - 12.0, r.position.y + 10.0), 6.0, PAINT_YELLOW)
	b.circle(Vector2(r.end.x - 12.0, r.position.y + 10.0), 4.2, PAINT_RED)


# the carousel's housing: a steel skirt round the track of overlapping black
# plates, the island in the middle with the chute the bags come up
static func _carousel(m: Node2D, b: ShapeBatch, r: Rect2) -> void:
	m.box_shadow(b, r, 20.0, 10.0)
	b.polygon(m.round_rect_pts(r, 34.0), STEEL_DARK)
	b.polygon(m.round_rect_pts(r.grow(-3.0), 31.0), STEEL)
	b.polygon(m.round_rect_pts(r.grow(-7.0), 28.0), Color(0.12, 0.12, 0.14))
	# the plates, as crescents round the loop
	for k in range(40):
		var a := TAU * float(k) / 40.0
		var p0 := Aeroport._carousel_pos(r, rad_to_deg(a))
		var out := (p0 - r.get_center()).normalized()
		b.line(p0 - out * 9.0, p0 + out * 9.0, Color(0.24, 0.24, 0.27), 1.4)
	var isl := r.grow(-27.0)
	b.polygon(m.round_rect_pts(isl, 14.0), STEEL_DARK)
	b.polygon(m.round_rect_pts(isl.grow(-2.5), 12.0), Color(0.76, 0.78, 0.82))
	# the chute and its rubber flaps, the reclaim's number
	var ch := Rect2(isl.get_center().x - 13.0, isl.position.y + 8.0, 26.0, 30.0)
	b.rect(ch, Color(0.10, 0.10, 0.12))
	for k in range(5):
		b.rect(Rect2(ch.position.x + float(k) * 5.4, ch.end.y - 9.0, 4.4, 9.0), Color(0.22, 0.22, 0.25))
	var sg := Rect2(isl.get_center().x - 15.0, isl.end.y - 32.0, 30.0, 22.0)
	b.rect(sg, SIGN_YELLOW)
	b.draw_string(m.font, Vector2(sg.position.x, sg.end.y - 5.0), "07", HORIZONTAL_ALIGNMENT_CENTER, sg.size.x, 15, SIGN_INK)


# --- overhead: what hangs from the roof --------------------------------------

# A hanging sign seen from below-and-above at once, as the game's signs are:
# the board laid flat, its two drop rods, a shadow on the floor far beneath.
static func hanging_sign(m: Node2D, c: CanvasItem, r: Rect2, fill: Color) -> void:
	c.draw_rect(Rect2(r.position + LIGHT * 26.0, r.size), Color(SHADOW, 0.10))
	c.draw_rect(Rect2(r.position.x + 8.0, r.position.y - 7.0, 3.0, 7.0), STEEL_DARK)
	c.draw_rect(Rect2(r.end.x - 11.0, r.position.y - 7.0, 3.0, 7.0), STEEL_DARK)
	c.draw_rect(r, SIGN_INK)
	c.draw_rect(r.grow(-2.0), fill)


static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	var font: Font = m.font
	# the way to the gates, in the airport's yellow, over the walkway's start
	var way := Rect2(548.0, -872.0, 184.0, 42.0)
	hanging_sign(m, c, way, SIGN_YELLOW)
	c.draw_string(font, Vector2(way.position.x + 40.0, way.end.y - 13.0), "B20 - B30", HORIZONTAL_ALIGNMENT_LEFT, 140.0, 21, SIGN_INK)
	var ac := way.position + Vector2(22.0, 21.0)
	c.draw_line(ac + Vector2(0.0, 12.0), ac + Vector2(0.0, -6.0), SIGN_INK, 5.0)
	c.draw_colored_polygon(PackedVector2Array([ac + Vector2(-10.0, -3.0), ac + Vector2(10.0, -3.0), ac + Vector2(0.0, -15.0)]), SIGN_INK)
	# the departures board over the west lane: rows of flights, one flashing
	# through its last call
	for by: float in [-470.0, -2250.0, -3560.0]:
		var board := Rect2(392.0, by, 150.0, 74.0)
		hanging_sign(m, c, board, Color(0.07, 0.08, 0.10))
		c.draw_rect(Rect2(board.position.x + 4.0, board.position.y + 4.0, board.size.x - 8.0, 11.0), SIGN_YELLOW)
		c.draw_string(font, Vector2(board.position.x + 8.0, board.position.y + 13.5), "SORTIDES", HORIZONTAL_ALIGNMENT_LEFT, 90.0, 10, SIGN_INK)
		c.draw_string(font, Vector2(board.position.x + 78.0, board.position.y + 13.5), "Departures", HORIZONTAL_ALIGNMENT_LEFT, 70.0, 9, SIGN_INK)
		for row in range(5):
			var ry := board.position.y + 21.0 + float(row) * 10.0
			var seed := int(by) + row
			c.draw_rect(Rect2(board.position.x + 7.0, ry, 22.0, 5.0), Color(0.98, 0.84, 0.30))
			c.draw_rect(Rect2(board.position.x + 34.0, ry, 30.0 + h(seed) * 30.0, 5.0), Color(0.90, 0.90, 0.86))
			c.draw_rect(Rect2(board.position.x + 104.0, ry, 14.0, 5.0), Color(0.90, 0.90, 0.86))
			var late := h(seed * 3) < 0.3
			c.draw_rect(Rect2(board.position.x + 124.0, ry, 18.0, 5.0), Color(0.94, 0.30, 0.24) if late else Color(0.36, 0.86, 0.50))
	# the security arch you come in under
	var arch := Rect2(WALL_L, SECURITY_Y - 14.0, WALL_R - WALL_L, 28.0)
	c.draw_rect(Rect2(arch.position + LIGHT * 20.0, arch.size), Color(SHADOW, 0.12))
	c.draw_rect(arch, FRAME)
	c.draw_rect(arch.grow_individual(0.0, -3.0, 0.0, -3.0), Color(0.90, 0.91, 0.92))
	c.draw_rect(Rect2(arch.position.x, arch.position.y + 3.0, arch.size.x, 4.0), Color(0.98, 0.98, 0.99))
	var plate := Rect2(560.0, SECURITY_Y - 11.0, 160.0, 22.0)
	c.draw_rect(plate, SIGN_NAVY)
	c.draw_string(font, Vector2(plate.position.x, plate.end.y - 6.0), "PORTES · Gates", HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 14, Color(0.98, 0.98, 0.94))
