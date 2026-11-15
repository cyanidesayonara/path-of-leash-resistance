extends RefCounted

# Panots: Barcelona's pavement tiles, pressed cement squares of 20 cm laid by
# the million since 1906. Two of them, drawn here once for every walk:
#
# - the flor de Barcelona, a four-petal flower in a square tile (flor): the
#   city's ordinary pavement;
# - Gaudí's hexagon from Passeig de Gràcia (gaudi): blue-grey, each tile
#   carrying a third of an ammonite, a starfish and a seaweed, so the whole
#   figures appear where three tiles meet.
#
# Both are a relief over whatever the pavement's own colour is: `ink` darkens
# the grooves and joints, `shine` lifts what catches the light. The walk
# fills its pavement first and says where the tiles go. Everything goes into
# the caller's ShapeBatch (the cached ground or edge layer), as figures built
# once and stamped: no draw call of its own, no triangulation per tile.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const FLOR := 40.0          # one flower tile
const HEX := 24.0           # a Gaudí hexagon, centre to corner
const HEX_W := 41.569       # across its flats (sqrt(3) * HEX)
const HEX_ROW := 36.0       # from one row of hexagons to the next (1.5 * HEX)

# dry pavement by day; a wet or lamp-lit walk passes its own
const INK := Color(0.10, 0.08, 0.06, 0.11)
const SHINE := Color(1.0, 0.98, 0.94, 0.09)

static var _flower := PackedVector2Array()
static var _button := PackedVector2Array()
static var _hex := PackedVector2Array()
static var _motifs: Array[PackedVector2Array] = []


# --- flor de Barcelona -------------------------------------------------------

# Flower tiles over the rect x0..x1, top..bot. The grid is fixed in the world
# down the walk and starts whole at x0; a last column too narrow for a flower
# is left as a cut tile. Each joint is one line the length of the rect. `t` is
# the tile's size, for a narrow pavement that would not take two of FLOR.
static func flor(b: ShapeBatch, x0: float, x1: float, top: float, bot: float, ink := INK, shine := SHINE, t := FLOR) -> void:
	if x1 - x0 < t * 0.75 or bot <= top:
		return
	_build()
	var joint := Color(ink.r, ink.g, ink.b, ink.a * 0.7)
	var x := x0 + t
	while x < x1 - 1.0:
		b.line(Vector2(x, top), Vector2(x, bot), joint, 1.0)
		x += t
	var y := floorf(top / t) * t
	while y < bot:
		if y > top:
			b.line(Vector2(x0, y), Vector2(x1, y), joint, 1.0)
		var cy := y + t * 0.5
		if cy > top + t * 0.3 and cy < bot - t * 0.3:
			_flowers(b, x0, x1, cy, x0, ink, shine, t)
		y += t


# One row of flower tiles from xa to xb with its top at y, for a pavement
# whose edges move (a chamfer, a bend): the joint above the row, the joints
# between its tiles and their flowers. `ax` is where the grid's columns start,
# the same for every row so the tiles line up down the walk.
static func flor_row(b: ShapeBatch, xa: float, xb: float, y: float, ax: float, ink := INK, shine := SHINE, t := FLOR) -> void:
	if xb - xa < t * 0.75:
		return
	_build()
	var joint := Color(ink.r, ink.g, ink.b, ink.a * 0.7)
	b.line(Vector2(xa, y), Vector2(xb, y), joint, 1.0)
	var x := ax + ceilf((xa - ax) / t) * t
	while x < xb:
		if x > xa + 1.0:
			b.line(Vector2(x, y), Vector2(x, y + t), joint, 1.0)
		x += t
	_flowers(b, xa, xb, y + t * 0.5, ax, ink, shine, t)


static func _flowers(b: ShapeBatch, xa: float, xb: float, cy: float, ax: float, ink: Color, shine: Color, t: float) -> void:
	var r := t * 0.37
	var x := ax + (floorf((xa - ax) / t) + 0.5) * t
	while x < xb:
		if x - r > xa and x + r < xb:
			b.stamp(_flower, Transform2D(Vector2(r, 0.0), Vector2(0.0, r), Vector2(x, cy)), ink)
			b.stamp(_button, Transform2D(Vector2(r, 0.0), Vector2(0.0, r), Vector2(x, cy)), shine)
		x += t


# --- Gaudí's hexagon ---------------------------------------------------------

# Hexagons over the rows from top to bot. `span` gives the pavement's left and
# right edge at a height (Callable(y) -> Vector2), so a strip, a chamfer or
# two strips either side of a road are all the same call; a tile is laid only
# where it fits whole. The tile faces are lifted with `shine`, which leaves
# the pavement's own colour as the joints; the reliefs are pressed in `ink`.
static func gaudi(b: ShapeBatch, span: Callable, top: float, bot: float, ink := INK, shine := SHINE) -> void:
	_build()
	var face := Transform2D(Vector2(HEX - 1.0, 0.0), Vector2(0.0, HEX - 1.0), Vector2.ZERO)
	var relief := Transform2D(Vector2(HEX * 0.5, 0.0), Vector2(0.0, HEX * 0.5), Vector2.ZERO)
	var row := int(floorf(top / HEX_ROW))
	var last := int(ceilf(bot / HEX_ROW))
	while row <= last:
		var cy := float(row) * HEX_ROW
		# the edges at the tile's widest reach up and down, so no corner
		# pokes past a slanting edge
		var e0: Vector2 = span.call(cy - HEX * 0.5)
		var e1: Vector2 = span.call(cy + HEX * 0.5)
		var xa := maxf(e0.x, e1.x) + HEX_W * 0.5
		var xb := minf(e0.y, e1.y) - HEX_W * 0.5
		var off := HEX_W * 0.5 if posmod(row, 2) == 1 else 0.0
		var col := int(ceilf((xa - off) / HEX_W))
		while float(col) * HEX_W + off <= xb:
			var c := Vector2(float(col) * HEX_W + off, cy)
			# a faint tone of its own per tile, as cast cement has
			var tone := 0.55 + 0.9 * _h(col * 73 + row * 151)
			face.origin = c
			b.stamp(_hex, face, Color(shine.r, shine.g, shine.b, shine.a * tone))
			# the figure at the tile's top corner, where three tiles meet; the
			# three take turns so that every tile touches one of each
			relief.origin = c - Vector2(0.0, HEX)
			b.stamp(_motifs[figure_at(col, row)], relief, ink)
			col += 1
		row += 1


# Which figure (0 ammonite, 1 starfish, 2 seaweed) sits on the top corner of
# the hexagon in this column and row. A tile's other two figured corners are
# the top corners of the two tiles below it, and the three always differ.
static func figure_at(col: int, row: int) -> int:
	return posmod(col - (row - posmod(row, 2)) / 2 - row, 3)


static func _h(i: int) -> float:
	return fmod(absf(sin(float(i) * 12.9898) * 43758.5453), 1.0)


# --- the figures, built once round the origin at radius one --------------------

static func _build() -> void:
	if not _flower.is_empty():
		return
	# The flower as it is pressed into the tile: four round petals on the
	# diagonals, each a ring of groove round a raised face, and in the middle
	# a ring round a raised button that lies over the petals' inner ends.
	_flower = PackedVector2Array()
	_arc(_flower, Vector2.ZERO, CORE_R - GROOVE, CORE_R, 14, 0.0)
	for k in range(4):
		_arc(_flower, Vector2.from_angle(TAU * (float(k) + 0.5) / 4.0) * PETAL_D, PETAL_R - GROOVE, PETAL_R, 18, CORE_R)
	_button = _fan(_ring(CORE_R - GROOVE - 0.03, 8))
	var hex := PackedVector2Array()
	for k in range(6):
		hex.append(Vector2.from_angle(TAU * (float(k) + 0.5) / 6.0))
	_hex = _fan(hex)
	_motifs = [_ammonite(), _starfish(), _seaweed()]


# the flower's measures, in a unit that reaches from the tile's middle to the
# petals' tips: where the petals' centres sit, a petal's outer radius (two
# neighbours just touch on the tile's axis), the middle ring's, the groove
const PETAL_D := 0.59
const PETAL_R := 0.415
const CORE_R := 0.34
const GROOVE := 0.115


# A ring of groove round c, from radius r0 to r1 in n sectors, left out where
# it would run inside `hole` of the origin (under the middle ring). Sectors
# share their edges, so translucent ink never doubles.
static func _arc(tris: PackedVector2Array, c: Vector2, r0: float, r1: float, n: int, hole: float) -> void:
	for k in range(n):
		var a0 := TAU * float(k) / float(n)
		var a1 := TAU * float(k + 1) / float(n)
		if hole > 0.0 and (c + Vector2.from_angle((a0 + a1) * 0.5) * (r0 + r1) * 0.5).length() < hole + (r1 - r0) * 0.5:
			continue
		var p0 := Vector2.from_angle(a0)
		var p1 := Vector2.from_angle(a1)
		tris.append_array(PackedVector2Array([c + p0 * r0, c + p0 * r1, c + p1 * r1,
			c + p0 * r0, c + p1 * r1, c + p1 * r0]))


static func _ring(r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(n):
		pts.append(Vector2.from_angle(TAU * float(k) / float(n)) * r)
	return pts


# a closed outline that is star-shaped round the origin, as triangles
static func _fan(rim: PackedVector2Array) -> PackedVector2Array:
	var tris := PackedVector2Array()
	for k in range(rim.size()):
		tris.append(Vector2.ZERO)
		tris.append(rim[k])
		tris.append(rim[(k + 1) % rim.size()])
	return tris


# a stroke of width w through the points, as triangles
static func _stroke(tris: PackedVector2Array, pts: PackedVector2Array, w: float) -> void:
	for k in range(pts.size() - 1):
		var t := (pts[k + 1] - pts[k]).orthogonal().normalized() * w * 0.5
		tris.append_array(PackedVector2Array([pts[k] + t, pts[k] - t, pts[k + 1] - t,
			pts[k] + t, pts[k + 1] - t, pts[k + 1] + t]))


# the ammonite: a shell coiling out from the middle
static func _ammonite() -> PackedVector2Array:
	var tris := PackedVector2Array()
	var pts := PackedVector2Array()
	for k in range(19):
		var a := TAU * float(k) / 9.0
		pts.append(Vector2.from_angle(a) * (0.14 + 0.72 * float(k) / 18.0))
	_stroke(tris, pts, 0.17)
	return tris


# the starfish: five arms
static func _starfish() -> PackedVector2Array:
	var rim := PackedVector2Array()
	for k in range(10):
		var a := TAU * float(k) / 10.0 - PI * 0.5
		rim.append(Vector2.from_angle(a) * (0.92 if k % 2 == 0 else 0.30))
	return _fan(rim)


# the seaweed: fronds curling out from the middle, all the same way
static func _seaweed() -> PackedVector2Array:
	var tris := PackedVector2Array()
	for arm in range(6):
		var a0 := TAU * float(arm) / 6.0
		var pts := PackedVector2Array()
		for k in range(5):
			var t := float(k) / 4.0
			pts.append(Vector2.from_angle(a0 + t * 1.1) * (0.16 + 0.74 * t))
		_stroke(tris, pts, 0.15)
	tris.append_array(_fan(_ring(0.2, 6)))
	return tris
