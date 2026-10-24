extends RefCounted

# Where every walk begins and ends (systems/arrival.gd): not a door standing
# alone on the path but the thing the door belongs to, closing off the south
# end of the walk. Seen from above like every building in the game: the roof,
# the wall face toward the street lit from the up-left, a bright cap along the
# roof edge (main._draw_edges).
#   apartment  a Barcelona finca across the street: shops and balconies along
#              its front, the portal with its door, a flat terrat of tiles
#              with a water tank, chimneys and the washing
#   station    the concourse front, glass doors under a glass canopy, ESTACIÓ
#   funicular  the low station house at the foot of the hill, FUNICULAR
#   metro      the stair down into the pavement, railings, the red M totem
#   trailhead  a timber rail fence with its gate, the trail map, the car park
#   ramp       the flood wall with the ramp up through it to the river path
# The fixed part is built once per walk into a ShapeBatch that is appended
# every frame (one draw call); only the door leaf and the lights are live.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Letters := preload("res://world/sign_letters.gd")

const LIGHT := Vector2(-0.6, -0.8)
const SHADOW := Color(0.05, 0.04, 0.07, 0.22)
# the front edge of a building is this far south of the door's centre
const FRONT := 14.0
# the wall face between the street and the roof, as on the walk's edges
const FACE := 22.0
const CAP := 5.0
# far enough left, right and south to fill any view of the start
const LEFT := -260.0
const RIGHT := 1540.0
const DEEP := 620.0
const PORTAL_HALF := 30.0
const MODULE := 92.0

# facade wall and roof by walk, for the apartment block
const FACADES := {
	"oldtown": [Color(0.52, 0.46, 0.40), Color(0.56, 0.36, 0.28)],
	"spook": [Color(0.46, 0.40, 0.36), Color(0.50, 0.32, 0.26)],
	"neteja": [Color(0.58, 0.48, 0.40), Color(0.60, 0.38, 0.30)],
	"beach": [Color(0.90, 0.88, 0.84), Color(0.82, 0.78, 0.70)],
	"port": [Color(0.84, 0.70, 0.50), Color(0.76, 0.66, 0.54)],
	"barri": [Color(0.66, 0.40, 0.32), Color(0.62, 0.44, 0.36)],
	"tutorial": [Color(0.66, 0.40, 0.32), Color(0.62, 0.44, 0.36)],
	"park": [Color(0.70, 0.56, 0.42), Color(0.64, 0.46, 0.36)],
	"guell": [Color(0.80, 0.68, 0.52), Color(0.68, 0.44, 0.34)],
	"site": [Color(0.62, 0.60, 0.56), Color(0.54, 0.52, 0.50)],
	"scrap": [Color(0.50, 0.48, 0.46), Color(0.44, 0.42, 0.40)],
	"market": [Color(0.72, 0.58, 0.44), Color(0.62, 0.42, 0.32)],
	"reial": [Color(0.84, 0.76, 0.62), Color(0.70, 0.48, 0.36)],
	"vet": [Color(0.78, 0.74, 0.66), Color(0.62, 0.46, 0.38)],
}
const FACADE_DEFAULT := [Color(0.80, 0.66, 0.48), Color(0.66, 0.43, 0.33)]
const AWNINGS: Array[Color] = [
	Color(0.20, 0.45, 0.36), Color(0.72, 0.22, 0.20), Color(0.18, 0.34, 0.56),
	Color(0.86, 0.62, 0.20), Color(0.40, 0.30, 0.48),
]
const WASHING: Array[Color] = [
	Color(0.92, 0.92, 0.94), Color(0.36, 0.52, 0.78), Color(0.86, 0.40, 0.36),
	Color(0.96, 0.82, 0.30), Color(0.40, 0.66, 0.44),
]
const METRO_RED := Color(0.80, 0.12, 0.14)
const GLASS := Color(0.60, 0.76, 0.86, 0.55)
const RAIL := Color(0.24, 0.26, 0.30)
const TIMBER := Color(0.48, 0.34, 0.20)


# --- the fixed part, built once per walk ---------------------------------------

static func static_geometry(m: Node2D, c: Vector2, place: String, weather: String) -> ShapeBatch:
	var key := "%s|%s|%.0f|%.0f|%s" % [String(m.lvl), place, c.x, c.y, weather]
	if m.has_meta("exit_portal_key") and String(m.get_meta("exit_portal_key")) == key:
		return m.get_meta("exit_portal_geom")
	var b := ShapeBatch.new()
	match place:
		"station":
			_station(b, m, c)
		"funicular":
			_funicular(b, m, c)
		"metro":
			_metro(b, m, c)
		"trailhead":
			_trailhead(b, m, c)
		"ramp":
			_ramp(b, m, c)
		_:
			_apartment(b, m, c, weather)
	m.set_meta("exit_portal_key", key)
	m.set_meta("exit_portal_geom", b)
	return b


# A block of buildings whose front runs along y = front, from LEFT to RIGHT,
# leaving the gap [gap_l, gap_r] in its wall face for the way in.
static func _block(b: ShapeBatch, m: Node2D, front: float, wall: Color, roof: Color,
		gap_l := INF, gap_r := -INF) -> void:
	var bottom: float = float(m.START_Y) + DEEP
	# the wall face, dark at the street and lighter up toward the roof
	for i in range(6):
		var t := float(i) / 5.0
		b.rect(Rect2(LEFT, front + FACE * t * 5.0 / 6.0, RIGHT - LEFT, FACE / 6.0 + 1.0), wall.darkened(0.42 - t * 0.32))
	# the roof edge's lit cap, then the roof
	b.rect(Rect2(LEFT, front + FACE, RIGHT - LEFT, CAP), roof.lightened(0.28))
	b.rect(Rect2(LEFT, front + FACE + CAP, RIGHT - LEFT, bottom - front - FACE - CAP), roof)
	# the gap: the reveal the way in is set back into
	if gap_r > gap_l:
		b.rect(Rect2(gap_l, front, gap_r - gap_l, FACE + CAP), wall.darkened(0.62))


# Roof clutter on a flat terrat: tile joints, a water tank, chimneys, a
# skylight, an aerial and a line of washing, all clear of the portal.
static func _terrat(b: ShapeBatch, m: Node2D, front: float, roof: Color, c: Vector2) -> void:
	var top := front + FACE + CAP
	var bottom: float = float(m.START_Y) + DEEP
	var joint := roof.darkened(0.12)
	var y := top + 22.0
	while y < bottom:
		b.line(Vector2(LEFT, y), Vector2(RIGHT, y), joint, 1.0)
		y += 22.0
	var x := floorf(LEFT / 22.0) * 22.0
	while x < RIGHT:
		b.line(Vector2(x, top), Vector2(x, bottom), joint, 1.0)
		x += 22.0
	# party walls between the neighbouring buildings
	for px: float in [c.x - 330.0, c.x + 300.0, c.x - 690.0, c.x + 660.0]:
		b.rect(Rect2(px - 3.0, top, 6.0, bottom - top), roof.darkened(0.25))
	# the water tank, its shadow and its lid
	var tank := Vector2(c.x + 170.0, top + 70.0)
	b.circle(tank - LIGHT * 10.0, 26.0, SHADOW)
	b.circle(tank, 24.0, Color(0.70, 0.72, 0.74))
	b.circle(tank, 9.0, Color(0.56, 0.58, 0.60))
	# chimneys, each with its shadow
	for cp: Vector2 in [Vector2(c.x - 140.0, top + 40.0), Vector2(c.x + 60.0, top + 120.0), Vector2(c.x - 420.0, top + 90.0), Vector2(c.x + 430.0, top + 50.0)]:
		b.rect(Rect2(cp + Vector2(5.0, 6.0), Vector2(22.0, 16.0)), SHADOW)
		b.rect(Rect2(cp, Vector2(22.0, 16.0)), roof.darkened(0.35))
		b.rect(Rect2(cp + Vector2(5.0, 4.0), Vector2(12.0, 8.0)), Color(0.16, 0.14, 0.14))
	# a skylight over the stairwell, behind the portal
	b.rect(Rect2(c.x - 24.0, top + 46.0, 48.0, 30.0), roof.darkened(0.3))
	b.rect(Rect2(c.x - 20.0, top + 50.0, 40.0, 22.0), GLASS)
	# an aerial
	var ae := Vector2(c.x + 250.0, top + 150.0)
	b.line(ae, ae + Vector2(0.0, -26.0), RAIL, 2.0)
	for k in range(3):
		b.line(ae + Vector2(-12.0, -8.0 - k * 7.0), ae + Vector2(12.0, -8.0 - k * 7.0), RAIL, 1.5)
	# the washing, pegged out across the terrat
	var wa := Vector2(c.x - 260.0, top + 120.0)
	var wb := Vector2(c.x - 90.0, top + 110.0)
	b.line(wa, wb, Color(0.86, 0.86, 0.84), 1.2)
	for k in range(6):
		var p := wa.lerp(wb, (float(k) + 0.6) / 6.6)
		b.rect(Rect2(p.x - 7.0, p.y, 14.0, 10.0 + float(k % 3) * 4.0), WASHING[k % WASHING.size()])


# Along a block's front: shop awnings over the pavement and balconies with a
# pot, module by module, leaving the portal clear.
static func _frontage(b: ShapeBatch, front: float, wall: Color, c: Vector2) -> void:
	var x := c.x + PORTAL_HALF + 14.0
	var k := 0
	while x < RIGHT:
		_front_module(b, front, wall, x, k)
		x += MODULE
		k += 1
	x = c.x - PORTAL_HALF - 14.0 - MODULE
	k = 2
	while x > LEFT - MODULE:
		_front_module(b, front, wall, x, k)
		x -= MODULE
		k += 1


static func _front_module(b: ShapeBatch, front: float, wall: Color, x: float, k: int) -> void:
	if k % 3 == 1:
		# a balcony: its slab, the railing and a pot of geraniums
		b.rect(Rect2(x + 14.0, front - 9.0, MODULE - 28.0, 9.0), wall.darkened(0.15))
		b.line(Vector2(x + 14.0, front - 9.0), Vector2(x + MODULE - 14.0, front - 9.0), RAIL, 2.0)
		for r in range(5):
			var rx := x + 14.0 + float(r) * (MODULE - 28.0) / 4.0
			b.line(Vector2(rx, front - 9.0), Vector2(rx, front), RAIL, 1.0)
		b.circle(Vector2(x + 28.0, front - 4.0), 4.5, Color(0.72, 0.22, 0.24))
		b.circle(Vector2(x + 28.0, front - 4.0), 2.0, Color(0.30, 0.52, 0.28))
		return
	# a shop: the window glowing in the wall face, its awning over the pavement
	var col: Color = AWNINGS[k % AWNINGS.size()]
	b.rect(Rect2(x + 10.0, front + 4.0, MODULE - 20.0, 9.0), Color(0.94, 0.86, 0.62, 0.6))
	var aw := Rect2(x + 6.0, front - 14.0, MODULE - 12.0, 14.0)
	b.rect(Rect2(aw.position + Vector2(3.0, 4.0), aw.size), SHADOW)
	var stripes := 6
	for s in range(stripes):
		var sw := aw.size.x / float(stripes)
		b.rect(Rect2(aw.position.x + sw * float(s), aw.position.y, sw, aw.size.y), col if s % 2 == 0 else col.lightened(0.55))
	b.rect(Rect2(aw.position.x, aw.position.y, aw.size.x, 3.0), col.darkened(0.3))


static func _apartment(b: ShapeBatch, m: Node2D, c: Vector2, weather: String) -> void:
	var pal: Array = FACADES.get(String(m.lvl), FACADE_DEFAULT)
	var wall: Color = pal[0]
	var roof: Color = pal[1]
	if weather == "rain":
		wall = wall.darkened(0.14)
		roof = roof.darkened(0.18)
	var front := c.y + FRONT
	_block(b, m, front, wall, roof, c.x - PORTAL_HALF + 4.0, c.x + PORTAL_HALF - 4.0)
	if String(m.lvl) != "scrap":
		_terrat(b, m, front, roof, c)
	if String(m.lvl) != "reial":
		_frontage(b, front, wall, c)
	_dress(b, m, c, front, wall, roof)
	# the portal: stone jambs and a lintel, the step out onto the pavement
	var stone := Color(0.74, 0.70, 0.62)
	b.rect(Rect2(c.x - PORTAL_HALF, front - 2.0, 8.0, FACE + 4.0), stone)
	b.rect(Rect2(c.x + PORTAL_HALF - 8.0, front - 2.0, 8.0, FACE + 4.0), stone)
	b.rect(Rect2(c.x - PORTAL_HALF - 2.0, front + FACE - 2.0, PORTAL_HALF * 2.0 + 4.0, 6.0), stone.lightened(0.12))
	b.rect(Rect2(c.x - PORTAL_HALF + 2.0, front - 7.0, PORTAL_HALF * 2.0 - 4.0, 6.0), stone.darkened(0.08))
	# the house number on its blue enamel plaque, the intercom, two pots
	b.rect(Rect2(c.x + PORTAL_HALF + 4.0, front + 6.0, 12.0, 9.0), Color(0.96, 0.96, 0.96))
	b.rect(Rect2(c.x + PORTAL_HALF + 5.0, front + 7.0, 10.0, 7.0), Color(0.16, 0.30, 0.62))
	b.rect(Rect2(c.x - PORTAL_HALF - 12.0, front + 6.0, 6.0, 10.0), Color(0.18, 0.18, 0.20))
	b.circle(Vector2(c.x - PORTAL_HALF - 9.0, front + 9.0), 1.6, Color(0.72, 0.62, 0.28))
	for side: float in [-1.0, 1.0]:
		var pp := Vector2(c.x + side * (PORTAL_HALF + 12.0), front - 8.0)
		b.circle(pp + Vector2(2.0, 3.0), 7.0, SHADOW)
		b.circle(pp, 7.0, Color(0.56, 0.32, 0.22))
		b.circle(pp, 5.0, Color(0.28, 0.50, 0.26))
		b.circle(pp + Vector2(-1.5, -1.5), 2.0, Color(0.80, 0.24, 0.26))



# What makes one walk's home its own, on top of its facade colours: the
# arcade of Plaça Reial, the old town's studded door, the seafront's shutters
# and towels, Gràcia's trencadís, the market's crates, the scaffold at the
# works, the scrapyard's tin roof, the pharmacy near the vet.
static func _dress(b: ShapeBatch, m: Node2D, c: Vector2, front: float, wall: Color, roof: Color) -> void:
	match String(m.lvl):
		"reial":
			# the arcade: a porch of stone pillars along the front, its shade
			b.rect(Rect2(LEFT, front - 26.0, RIGHT - LEFT, 26.0), Color(0.05, 0.04, 0.07, 0.16))
			var x := c.x + PORTAL_HALF + 22.0
			while x < RIGHT:
				_pillar(b, Vector2(x, front - 22.0), wall)
				x += 52.0
			x = c.x - PORTAL_HALF - 22.0
			while x > LEFT:
				_pillar(b, Vector2(x, front - 22.0), wall)
				x -= 52.0
		"oldtown", "spook", "neteja":
			# a lantern on its iron bracket over the portal
			var lp := Vector2(c.x + PORTAL_HALF + 18.0, front - 12.0)
			b.line(Vector2(lp.x, front), lp, RAIL, 2.0)
			b.rect(Rect2(lp - Vector2(5.0, 6.0), Vector2(10.0, 12.0)), RAIL)
			b.rect(Rect2(lp - Vector2(3.0, 4.0), Vector2(6.0, 8.0)), Color(1.0, 0.86, 0.52))
		"beach", "port":
			# blue shutters by every window, towels over the balconies, and a
			# striped parasol up on the roof terrace
			var x := LEFT + 30.0
			while x < RIGHT:
				if absf(x - c.x) > PORTAL_HALF + 30.0:
					b.rect(Rect2(x - 12.0, front + 5.0, 6.0, 11.0), Color(0.22, 0.42, 0.66))
					b.rect(Rect2(x + 6.0, front + 5.0, 6.0, 11.0), Color(0.22, 0.42, 0.66))
				x += MODULE * 0.5
			for k in range(-5, 6):
				var tx := c.x + float(k) * MODULE * 3.0 + 120.0
				b.rect(Rect2(tx, front - 13.0, 22.0, 6.0), AWNINGS[(k + 5) % AWNINGS.size()].lightened(0.2))
			var pa := Vector2(c.x - 210.0, front + FACE + CAP + 70.0)
			b.circle(pa - LIGHT * 10.0, 30.0, SHADOW)
			for s in range(8):
				var a0 := float(s) * TAU / 8.0
				var pts := PackedVector2Array([pa, pa + Vector2.from_angle(a0) * 28.0, pa + Vector2.from_angle(a0 + TAU / 8.0) * 28.0])
				b.polygon(pts, Color(0.92, 0.30, 0.26) if s % 2 == 0 else Color(0.97, 0.95, 0.90))
		"guell":
			# a band of trencadís along the top of the wall face
			var x := LEFT
			var k := 0
			while x < RIGHT:
				b.rect(Rect2(x, front + FACE - 6.0, 8.0, 5.0), WASHING[k % WASHING.size()].lightened(0.1))
				x += 9.0
				k += 1
		"market":
			# crates of fruit out in front of the shops
			for k in range(-4, 5):
				var cx := c.x + float(k) * MODULE * 1.5 + 70.0
				if absf(cx - c.x) < PORTAL_HALF + 40.0:
					continue
				var cr := Rect2(cx, front - 30.0, 26.0, 18.0)
				b.rect(Rect2(cr.position + Vector2(3.0, 4.0), cr.size), SHADOW)
				b.rect(cr, TIMBER.lightened(0.15))
				var fruit: Color = [Color(0.94, 0.56, 0.16), Color(0.86, 0.20, 0.18), Color(0.56, 0.74, 0.26)][abs(k) % 3]
				for f in range(3):
					b.circle(cr.position + Vector2(6.0 + float(f) * 7.0, 9.0), 4.0, fruit)
		"site":
			# scaffold up the front of the block across the road, its net
			var x0 := c.x + PORTAL_HALF + 40.0
			b.rect(Rect2(x0, front - 18.0, 420.0, FACE + 18.0), Color(0.30, 0.58, 0.36, 0.45))
			var x := x0
			while x <= x0 + 420.0:
				b.line(Vector2(x, front - 18.0), Vector2(x, front + FACE), Color(0.72, 0.72, 0.74), 2.5)
				x += 60.0
			b.line(Vector2(x0, front - 16.0), Vector2(x0 + 420.0, front - 16.0), Color(0.72, 0.72, 0.74), 2.5)
			b.line(Vector2(x0, front - 6.0), Vector2(x0 + 420.0, front - 6.0), TIMBER.lightened(0.2), 4.0)
		"scrap":
			# a tin roof, ridged, over the terrat's tiles
			var top := front + FACE + CAP
			b.rect(Rect2(LEFT, top, RIGHT - LEFT, 360.0), Color(0.52, 0.54, 0.55))
			var y := top
			while y < top + 360.0:
				b.line(Vector2(LEFT, y), Vector2(RIGHT, y), Color(0.40, 0.42, 0.44), 2.0)
				y += 9.0
			b.rect(Rect2(c.x + 120.0, top + 60.0, 70.0, 40.0), Color(0.55, 0.32, 0.20, 0.8))
		"vet":
			# the pharmacy on the corner, its green cross lit
			var px := c.x - PORTAL_HALF - 110.0
			b.rect(Rect2(px - 14.0, front - 22.0, 28.0, 28.0), Color(0.12, 0.14, 0.12))
			b.rect(Rect2(px - 4.0, front - 18.0, 8.0, 20.0), Color(0.30, 0.86, 0.40))
			b.rect(Rect2(px - 10.0, front - 12.0, 20.0, 8.0), Color(0.30, 0.86, 0.40))


static func _pillar(b: ShapeBatch, at: Vector2, wall: Color) -> void:
	b.circle(at + Vector2(4.0, 5.0), 8.0, SHADOW)
	b.circle(at, 8.0, wall.lightened(0.08))
	b.circle(at, 5.0, wall.lightened(0.22))

static func _station(b: ShapeBatch, m: Node2D, c: Vector2) -> void:
	var wall := Color(0.66, 0.66, 0.68)
	var roof := Color(0.52, 0.53, 0.56)
	var front := c.y + FRONT
	var half := 120.0
	_block(b, m, front, wall, roof, c.x - half, c.x + half)
	# the concourse roof: long glazed strips and the plant on top
	var top := front + FACE + CAP
	for k in range(-4, 5):
		b.rect(Rect2(c.x + float(k) * 110.0 - 40.0, top + 40.0, 80.0, 260.0), GLASS.darkened(0.15))
		b.line(Vector2(c.x + float(k) * 110.0, top + 40.0), Vector2(c.x + float(k) * 110.0, top + 300.0), RAIL, 1.5)
	for hv: Vector2 in [Vector2(c.x - 380.0, top + 360.0), Vector2(c.x + 330.0, top + 340.0)]:
		b.rect(Rect2(hv + Vector2(6.0, 6.0), Vector2(60.0, 40.0)), SHADOW)
		b.rect(Rect2(hv, Vector2(60.0, 40.0)), Color(0.70, 0.71, 0.72))
		b.circle(hv + Vector2(30.0, 20.0), 14.0, Color(0.36, 0.37, 0.40))
	# glass doors across the entrance, their frames, the warm concourse behind
	b.rect(Rect2(c.x - half, front, half * 2.0, FACE + CAP), Color(1.0, 0.90, 0.70, 0.5))
	for k in range(6):
		var dx := c.x - half + 10.0 + float(k) * (half * 2.0 - 20.0) / 5.0
		b.line(Vector2(dx, front), Vector2(dx, front + FACE + CAP), RAIL, 2.0)
	# the canopy over the pavement: glass on steel, its posts, and the sign
	var can := Rect2(c.x - half - 30.0, front - 46.0, half * 2.0 + 60.0, 46.0)
	b.rect(Rect2(can.position + Vector2(6.0, 8.0), can.size), Color(0.05, 0.04, 0.07, 0.12))
	b.rect(can, GLASS)
	for k in range(9):
		var gx := can.position.x + float(k) * can.size.x / 8.0
		b.line(Vector2(gx, can.position.y), Vector2(gx, can.end.y), RAIL, 1.5)
	b.line(can.position, Vector2(can.end.x, can.position.y), RAIL, 3.0)
	for px: float in [can.position.x + 6.0, can.end.x - 6.0]:
		b.circle(Vector2(px, can.position.y + 4.0), 4.0, RAIL)
	_sign(b, "ESTACIÓ", Vector2(c.x, can.position.y - 6.0), 16.0, 200.0, Color(0.16, 0.20, 0.30), Color(0.96, 0.92, 0.80))
	# the station clock on its post, a bike rack
	var ck := Vector2(c.x + half + 70.0, front - 30.0)
	b.line(ck, ck + Vector2(0.0, 24.0), RAIL, 3.0)
	b.circle(ck, 11.0, Color(0.92, 0.90, 0.84))
	b.circle(ck, 9.0, Color(0.98, 0.97, 0.94))
	b.line(ck, ck + Vector2(0.0, -7.0), RAIL, 1.5)
	b.line(ck, ck + Vector2(5.0, 0.0), RAIL, 1.5)
	for k in range(5):
		var rx := c.x - half - 150.0 + float(k) * 16.0
		b.line(Vector2(rx, front - 26.0), Vector2(rx, front - 6.0), RAIL, 2.5)


static func _funicular(b: ShapeBatch, m: Node2D, c: Vector2) -> void:
	var wall := Color(0.82, 0.76, 0.64)
	var roof := Color(0.58, 0.40, 0.30)
	var front := c.y + FRONT
	var half := 54.0
	_block(b, m, front, wall, roof, c.x - half, c.x + half)
	_terrat(b, m, front, roof, c)
	# the station house: a pitched roof over the hall, the rails running in
	var hall := Rect2(c.x - 90.0, front + FACE + CAP, 180.0, 170.0)
	b.rect(Rect2(hall.position + Vector2(8.0, 10.0), hall.size), SHADOW)
	b.rect(Rect2(hall.position, Vector2(hall.size.x * 0.5, hall.size.y)), roof.darkened(0.08))
	b.rect(Rect2(hall.position + Vector2(hall.size.x * 0.5, 0.0), Vector2(hall.size.x * 0.5, hall.size.y)), roof.lightened(0.10))
	b.line(Vector2(hall.get_center().x, hall.position.y), Vector2(hall.get_center().x, hall.end.y), roof.lightened(0.3), 3.0)
	# glass doors and turnstiles in the entrance, the hall lit behind them
	b.rect(Rect2(c.x - half, front, half * 2.0, FACE + CAP), Color(1.0, 0.90, 0.70, 0.5))
	for k in range(4):
		var dx := c.x - half + 8.0 + float(k) * (half * 2.0 - 16.0) / 3.0
		b.rect(Rect2(dx - 3.0, front + 6.0, 6.0, 10.0), RAIL)
	# the canopy and the name over it
	var can := Rect2(c.x - half - 16.0, front - 30.0, half * 2.0 + 32.0, 30.0)
	b.rect(Rect2(can.position + Vector2(5.0, 6.0), can.size), Color(0.05, 0.04, 0.07, 0.12))
	b.rect(can, Color(0.70, 0.22, 0.18))
	b.rect(Rect2(can.position.x, can.end.y - 4.0, can.size.x, 4.0), Color(0.52, 0.14, 0.12))
	_sign(b, "FUNICULAR", Vector2(c.x, can.position.y + 22.0), 12.0, can.size.x - 16.0, Color(0, 0, 0, 0), Color(0.98, 0.94, 0.84))


static func _metro(b: ShapeBatch, m: Node2D, c: Vector2) -> void:
	# the stair is cut into the pavement, going down to the south; the city
	# block behind it closes the street
	var front := c.y + 120.0
	var wall := Color(0.78, 0.66, 0.50)
	var roof := Color(0.62, 0.44, 0.34)
	_block(b, m, front, wall, roof)
	_terrat(b, m, front, roof, Vector2(c.x, c.y + 120.0 - FRONT))
	_frontage(b, front, wall, Vector2(c.x + 2000.0, c.y))
	var well := Rect2(c.x - 34.0, c.y - 10.0, 68.0, 96.0)
	b.rect(Rect2(well.position - Vector2(6.0, 6.0), well.size + Vector2(12.0, 12.0)), Color(0.62, 0.60, 0.58))
	var steps := 12
	for k in range(steps):
		var t := float(k) / float(steps - 1)
		var sy := well.position.y + well.size.y * float(k) / float(steps)
		b.rect(Rect2(well.position.x, sy, well.size.x, well.size.y / float(steps) + 0.5), Color(0.58, 0.57, 0.56).darkened(t * 0.75))
		b.line(Vector2(well.position.x, sy), Vector2(well.end.x, sy), Color(0.86, 0.80, 0.30, 0.55 * (1.0 - t)), 1.5)
	# railings round three sides, open to the north where you go in
	for x: float in [well.position.x - 4.0, well.end.x + 4.0]:
		b.line(Vector2(x, well.position.y), Vector2(x, well.end.y + 4.0), RAIL, 3.0)
		for k in range(5):
			b.circle(Vector2(x, well.position.y + float(k) * well.size.y / 4.0), 2.5, RAIL)
	b.line(Vector2(well.position.x - 4.0, well.end.y + 4.0), Vector2(well.end.x + 4.0, well.end.y + 4.0), RAIL, 3.0)
	# the totem: a red square with the white M, on its pole, and its shadow
	var tp := Vector2(c.x + 62.0, c.y - 14.0)
	b.line(tp + Vector2(4.0, 6.0), tp + Vector2(18.0, 26.0), SHADOW, 6.0)
	b.line(tp, tp + Vector2(0.0, 30.0), RAIL, 4.0)
	b.rect(Rect2(tp - Vector2(15.0, 15.0), Vector2(30.0, 30.0)), METRO_RED)
	var mm := PackedVector2Array([tp + Vector2(-9, 8), tp + Vector2(-9, -8), tp + Vector2(0, 2), tp + Vector2(9, -8), tp + Vector2(9, 8)])
	for i in range(mm.size() - 1):
		b.line(mm[i], mm[i + 1], Color(1, 1, 1), 3.0)


static func _trailhead(b: ShapeBatch, m: Node2D, c: Vector2) -> void:
	var front := c.y + FRONT
	var bottom: float = float(m.START_Y) + DEEP
	# the car park beyond the fence: gravel, its bays and a parked car
	b.rect(Rect2(LEFT, front, RIGHT - LEFT, bottom - front), Color(0.60, 0.56, 0.48))
	for k in range(-6, 7):
		var bx := c.x + float(k) * 70.0
		if absf(bx - c.x) < 60.0:
			continue
		b.line(Vector2(bx, front + 60.0), Vector2(bx, front + 150.0), Color(0.88, 0.86, 0.80, 0.7), 2.0)
	var car := Rect2(c.x + 145.0, front + 70.0, 46.0, 76.0)
	b.rect(Rect2(car.position + Vector2(6.0, 8.0), car.size), SHADOW)
	b.rect(car, Color(0.30, 0.46, 0.62))
	b.rect(Rect2(car.position + Vector2(5.0, 14.0), Vector2(36.0, 16.0)), GLASS.darkened(0.3))
	b.rect(Rect2(car.position + Vector2(5.0, 50.0), Vector2(36.0, 12.0)), GLASS.darkened(0.3))
	# pines round the car park
	for tp: Vector2 in [Vector2(c.x - 300.0, front + 120.0), Vector2(c.x - 200.0, front + 230.0), Vector2(c.x + 320.0, front + 200.0), Vector2(c.x - 420.0, front + 60.0), Vector2(c.x + 450.0, front + 90.0)]:
		b.circle(tp - LIGHT * 14.0, 36.0, SHADOW)
		b.circle(tp, 34.0, Color(0.20, 0.36, 0.20))
		b.circle(tp + Vector2(-8.0, -8.0), 20.0, Color(0.26, 0.44, 0.24))
	# the fence: posts and two rails, open at the gate
	for x0: float in [LEFT, c.x + 40.0]:
		var x1: float = c.x - 40.0 if x0 == LEFT else RIGHT
		var x := x0
		while x <= x1:
			b.rect(Rect2(x - 4.0, front - 6.0, 8.0, 12.0), TIMBER.darkened(0.2))
			x += 60.0
		b.line(Vector2(x0, front - 2.0), Vector2(x1, front - 2.0), TIMBER, 4.0)
		b.line(Vector2(x0, front + 4.0), Vector2(x1, front + 4.0), TIMBER.darkened(0.1), 3.0)
	# the gate posts, the gate swung back against the fence
	for side: float in [-1.0, 1.0]:
		b.rect(Rect2(c.x + side * 40.0 - 6.0, front - 9.0, 12.0, 18.0), TIMBER.darkened(0.3))
	b.line(Vector2(c.x + 40.0, front - 4.0), Vector2(c.x + 96.0, front - 16.0), TIMBER.lightened(0.1), 5.0)
	# the trail map board on its two legs, and a red-and-white waymarker
	var board := Rect2(c.x - 132.0, front - 34.0, 64.0, 24.0)
	b.rect(Rect2(board.position + Vector2(5.0, 6.0), board.size), SHADOW)
	b.rect(board.grow(3.0), TIMBER.darkened(0.25))
	b.rect(board, Color(0.86, 0.84, 0.70))
	b.line(board.position + Vector2(6.0, 18.0), board.position + Vector2(24.0, 8.0), Color(0.80, 0.22, 0.20), 2.0)
	b.line(board.position + Vector2(24.0, 8.0), board.position + Vector2(56.0, 14.0), Color(0.80, 0.22, 0.20), 2.0)
	b.circle(board.position + Vector2(40.0, 6.0), 4.0, Color(0.36, 0.56, 0.78))
	var wm := Vector2(c.x + 66.0, front - 22.0)
	b.circle(wm + Vector2(3.0, 4.0), 7.0, SHADOW)
	b.circle(wm, 6.0, Color(0.96, 0.96, 0.94))
	b.circle(wm, 3.0, Color(0.84, 0.18, 0.16))


static func _ramp(b: ShapeBatch, m: Node2D, c: Vector2) -> void:
	var front := c.y + FRONT
	var bottom: float = float(m.START_Y) + DEEP
	var concrete := Color(0.62, 0.60, 0.56)
	# the flood wall's top, then the river path and the grass up above
	_block(b, m, front, concrete, concrete.lightened(0.06), c.x - 34.0, c.x + 34.0)
	b.rect(Rect2(LEFT, front + 70.0, RIGHT - LEFT, 70.0), Color(0.80, 0.74, 0.60))
	b.rect(Rect2(LEFT, front + 140.0, RIGHT - LEFT, bottom - front - 140.0), Color(0.40, 0.56, 0.30))
	for k in range(-6, 7):
		var tp := Vector2(c.x + float(k) * 150.0 + 40.0, front + 210.0 + float(k % 2) * 40.0)
		b.circle(tp - LIGHT * 12.0, 30.0, SHADOW)
		b.circle(tp, 28.0, Color(0.30, 0.48, 0.26))
	# the ramp up through the wall: grooved concrete and its two handrails
	var ramp := Rect2(c.x - 30.0, front - 4.0, 60.0, 74.0)
	b.rect(ramp, concrete.lightened(0.1))
	var y := ramp.position.y + 6.0
	while y < ramp.end.y:
		b.line(Vector2(ramp.position.x, y), Vector2(ramp.end.x, y), concrete.darkened(0.2), 1.5)
		y += 7.0
	for x: float in [ramp.position.x - 3.0, ramp.end.x + 3.0]:
		b.line(Vector2(x, ramp.position.y - 6.0), Vector2(x, ramp.end.y), Color(0.72, 0.62, 0.22), 3.0)
	# the park's sign on the wall, a bike rack beside the ramp
	_sign(b, "PARC FLUVIAL", Vector2(c.x - 150.0, front + 16.0), 10.0, 150.0, Color(0.20, 0.36, 0.30), Color(0.94, 0.94, 0.88))
	for k in range(4):
		var rx := c.x + 70.0 + float(k) * 16.0
		b.line(Vector2(rx, front - 26.0), Vector2(rx, front - 6.0), RAIL, 2.5)


# A sign: stroke letters on a band (band colour alpha 0 for none).
static func _sign(b: ShapeBatch, txt: String, at: Vector2, h: float, max_w: float, band: Color, ink: Color) -> void:
	var lay: Array = Letters.layout(txt, at, h, max_w)
	var used: float = lay[1]
	var w := minf(Letters.width(txt.to_upper(), used), max_w)
	if band.a > 0.0:
		b.rect(Rect2(at.x - w * 0.5 - 8.0, at.y - used - 6.0, w + 16.0, used + 12.0), band)
	for pl: PackedVector2Array in lay[0]:
		for i in range(pl.size() - 1):
			b.line(pl[i], pl[i + 1], ink, maxf(1.6, used * 0.16))


# --- the live part, every frame ------------------------------------------------

# The apartment's door leaf (shut along the threshold, swinging out as it
# opens) and the hall light behind it; a lit transit entrance at night.
static func draw_live(b: ShapeBatch, m: Node2D, c: Vector2, place: String, open: float, night: bool) -> void:
	var front := c.y + FRONT
	if place != "apartment":
		return
	# the old town's doors are studded oak; everywhere else the usual green
	var green := Color(0.42, 0.28, 0.18) if String(m.lvl) in ["oldtown", "spook", "neteja"] else Color(0.30, 0.52, 0.41)
	if open > 0.05 or night:
		b.rect(Rect2(c.x - PORTAL_HALF + 8.0, front, PORTAL_HALF * 2.0 - 16.0, FACE), Color(1.0, 0.86, 0.62, 0.55 * maxf(open, 0.5 if night else 0.0)))
	var hinge := Vector2(c.x - PORTAL_HALF + 8.0, front + 2.0)
	var ang := open * PI * 0.5
	var tip := hinge + Vector2(cos(ang), -sin(ang)) * (PORTAL_HALF * 2.0 - 16.0)
	b.line(hinge, tip, green, 6.0)
	b.circle(hinge.lerp(tip, 0.85), 1.8, Color(0.80, 0.70, 0.30))
