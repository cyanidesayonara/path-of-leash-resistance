class_name FilmLleona
extends RefCounted

# Girona's film, "La Lleona": the stone lioness's wake (docs/BOSSES.md), played
# as the dog first comes to her column (systems/boss_lleona.gd), before the
# walk's own wake. Plaça de Sant Feliu in the rain at dusk, side on: the
# Basílica's blunt bell tower, the Onyar's painted houses, lit arcades, and the
# lioness clinging to her column over the iron kissing steps. The two of them
# walk past, your human on the phone. A crack: the dog looks back. Two gold
# eyes open, the stone head turns, she roars, and she drops off the column
# onto the wet paving. A pigeon flaps up between them; she only looks at it,
# and it falls out of the air as a stone pigeon. The dog plants herself between
# her and your human, barking. LA LLEONA! slams in, her eyes lit.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.10, 0.11, 0.22)
const FEET := 640.0
const COL_X := -150.0
const COL_W := 104.0
const CLING_Y := 360.0           # the bottom of her hold on the column
const EYES_AT := 2.0
const TURN_AT := 2.12
const ROAR_AT := 2.36
const LEAP_AT := 2.75
const LAND_AT := 3.05
const BIRD_AT := 3.1             # the pigeon flaps up
const GAZE_AT := 3.42
const STONE_AT := 3.52           # it is stone
const CLUNK_AT := 3.86
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const LLEONA_K := 1.06
const BIRD_POS := Vector2(345.0, 440.0)
const INK := IntroKit.INK
const STONE := Color(0.72, 0.66, 0.56)
const STONE_DARK := Color(0.50, 0.45, 0.40)
const STONE_DEEP := Color(0.36, 0.33, 0.32)
const STONE_LIT := Color(0.90, 0.85, 0.73)
const CARVE := Color(0.44, 0.39, 0.35)
const MOSS := Color(0.36, 0.44, 0.28, 0.75)
const EYE_GOLD := Color(1.0, 0.82, 0.30)
const MOUTH := Color(0.30, 0.10, 0.11)
const IRON := Color(0.14, 0.14, 0.19)
const HOUSES: Array[Color] = [
	Color(0.62, 0.36, 0.24), Color(0.68, 0.52, 0.26), Color(0.56, 0.28, 0.24),
	Color(0.48, 0.46, 0.34), Color(0.64, 0.44, 0.36),
]
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.1, "hiss", 0.55, -16.0],
	[1.30, "crack", 1.2, -9.0],
	[EYES_AT, "bell", 0.5, -8.0],
	[TURN_AT + 0.05, "grit", 0.6, -6.0],
	[ROAR_AT, "lion_roar", 0.85, -1.0],
	[LEAP_AT, "fling", 0.6, -6.0],
	[LAND_AT, "drum", 0.4, 0.0],
	[LAND_AT + 0.05, "crack", 0.6, -5.0],
	[BIRD_AT, "rustle", 1.3, -6.0],
	[GAZE_AT, "ooooh", 0.5, -5.0],
	[STONE_AT, "crack", 1.5, -4.0],
	[CLUNK_AT, "drum", 1.1, -3.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[BOLT_AT + 0.75, "bark", 1.0, -4.0],
	[TITLE_AT, "lion_roar", 0.75, -1.0],
]


# the camera: on the pair; up to the column as the dog looks round, held on the
# eyes and the roar; down with the leap; the pigeon; her stare; the stand-off
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2.ZERO
	var ml := Engine.get_main_loop()
	var gm: Node = ml.root.get_node_or_null("Game") if ml != null and ml is SceneTree else null
	if gm == null or bool(gm.screen_shake):
		if t >= LAND_AT:
			shake = Vector2(sin(t * 87.0), sin(t * 61.0)) * 15.0 * (1.0 - Anim.span(t, LAND_AT, LAND_AT + 0.35))
		elif t >= ROAR_AT and t < LEAP_AT:
			shake = Vector2(sin(t * 71.0), sin(t * 93.0)) * 4.0
	if t >= BOLT_AT:
		return [Vector2(390.0, 430.0) + shake, Anim.k(t, [[BOLT_AT, 1.0], [TITLE_AT, 0.92, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.5, 640.0, "io"], [1.98, 0.0, "io"], [LEAP_AT, 0.0], [3.15, 150.0, "io"],
		[3.9, 250.0, "io"], [4.2, 470.0, "io"], [BOLT_AT, 520.0]])
	var y: float = Anim.k(t, [[0.0, 470.0], [1.5, 470.0], [1.98, 110.0, "io"], [LEAP_AT, 110.0], [3.15, 450.0, "io"],
		[3.9, 450.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.5, 1.25, "io"], [1.98, 1.25, "io"], [LEAP_AT, 1.42, "io"], [3.15, 0.96, "io"],
		[3.9, 1.0, "io"], [4.2, 1.32, "io"], [BOLT_AT, 1.42]])
	return [Vector2(x, y) + shake, z]


# where she is: her hold on the column, the drop, then across the paving
static func lleona_at(t: float) -> Vector2:
	if t < LEAP_AT:
		return Vector2(COL_X, CLING_Y)
	if t < LAND_AT:
		var f := Anim.span(t, LEAP_AT, LAND_AT)
		return Vector2(lerpf(COL_X, COL_X + 110.0, f), lerpf(CLING_Y, FEET, f * f) - sin(f * PI) * 50.0)
	return Vector2(Anim.k(t, [[LAND_AT, COL_X + 110.0], [LAND_AT + 0.2, COL_X + 112.0], [3.9, -14.0], [BOLT_AT, -8.0],
		[TITLE_AT, 0.0]]), FEET)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	placa(c, t_real, 1.0)
	column(c, COL_X, FEET)
	var gaze := Anim.span(t, GAZE_AT, GAZE_AT + 0.08) * (1.0 - Anim.span(t, CLUNK_AT - 0.08, CLUNK_AT + 0.05))
	var glint := Anim.span(t, BOLT_AT, TITLE_AT)
	var at := lleona_at(t)
	var roar := Anim.span(t, ROAR_AT, ROAR_AT + 0.1) * (1.0 - Anim.span(t, LEAP_AT - 0.08, LEAP_AT + 0.05))
	var walking := t > LAND_AT + 0.2 and t < 3.9 and gaze < 0.5
	var o := {
		"cling": 1.0 - Anim.span(t, LEAP_AT, LEAP_AT + 0.14),
		"eye": Anim.span(t, EYES_AT, EYES_AT + 0.18),
		"turn": Anim.span(t, TURN_AT, TURN_AT + 0.25),
		"jaw": maxf(roar, 0.7 * Anim.span(t, 3.95, 4.3)),
		"walking": walking,
		"crouch": Anim.k(t, [[LAND_AT, 0.0], [LAND_AT + 0.06, 1.0, "out"], [LAND_AT + 0.35, 0.25, "io"], [BOLT_AT, 0.4]]),
		"gaze": maxf(gaze, glint * 0.8), "tilt": 0.05 * sin(t_real * 40.0) * roar, "ground": FEET,
	}
	lleona(c, at, LLEONA_K, t_real, o)
	# stone dust shaken off as the head turns and as she lands
	if t >= TURN_AT and t < TURN_AT + 0.8:
		for i in range(8):
			var f := fposmod(t * 1.6 + float(i) * 0.13, 1.0)
			c.draw_circle(Vector2(COL_X + 60.0 + float(i) * 12.0, 40.0 + f * 190.0), 5.0 * (1.0 - f) + 1.5, Color(STONE_LIT, 1.0 - f))
	if t >= LAND_AT and t < LAND_AT + 0.6:
		var f := Anim.span(t, LAND_AT, LAND_AT + 0.6)
		for i in range(9):
			var a := float(i) / 8.0 * PI
			IntroKit.puff(c, at + Vector2(cos(a) * (130.0 + f * 170.0), -sin(a) * 18.0 - 8.0), 26.0 * (1.0 - f), 1.0 - f)
	var eye_at := eye_pos(at, LLEONA_K, o)
	_bird(c, t, t_real)
	if gaze > 0.0:
		# it stops at what it looks at: the dog and your human are not in it
		var to := _bird_at(t) - eye_at
		beam(c, eye_at, to.angle(), to.length() + 16.0, 0.12, 0.9 * gaze)
		halo(c, _bird_at(t), 60.0, Color(1.0, 0.86, 0.46, 0.7 * gaze))
	FilmKit.pair(c, t_real, FEET, true)
	rain(c, t_real, 1.0)
	FilmKit.fades(c, t_real)


# --- the pigeon -----------------------------------------------------------------

static func _bird_at(t: float) -> Vector2:
	if t < STONE_AT:
		var f := Anim.span(t, BIRD_AT, STONE_AT)
		return Vector2(lerpf(330.0, BIRD_POS.x, f), lerpf(FEET - 14.0, BIRD_POS.y, sin(f * PI * 0.5)))
	var g := Anim.span(t, STONE_AT + 0.06, CLUNK_AT)
	return Vector2(BIRD_POS.x, lerpf(BIRD_POS.y, FEET - 14.0, g * g))


static func _bird(c: CanvasItem, t: float, t_real: float) -> void:
	if t < 1.0:
		return
	pigeon(c, _bird_at(t), t_real, t >= BIRD_AT and t < STONE_AT, t >= STONE_AT)
	if t >= CLUNK_AT and t < CLUNK_AT + 0.4:
		var f := Anim.span(t, CLUNK_AT, CLUNK_AT + 0.4)
		for s: float in [-1.0, 1.0]:
			IntroKit.puff(c, Vector2(BIRD_POS.x + s * (18.0 + f * 46.0), FEET - 6.0), 12.0 * (1.0 - f), 1.0 - f)


# a pigeon side on: pottering, flapping, or a small statue of one caught flapping
static func pigeon(c: CanvasItem, at: Vector2, t: float, flying: bool, stone: bool) -> void:
	var body := Color(0.46, 0.48, 0.56)
	var dark := Color(0.30, 0.31, 0.38)
	var neck := Color(0.28, 0.48, 0.44)
	if stone:
		body = STONE
		dark = STONE_DARK
		neck = STONE_LIT
	var wing := sin(t * 34.0) if flying else (0.8 if stone else -0.2)
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(-2, 0), Vector2(23, 15), -0.25), INK)
	c.draw_colored_polygon(MillieSide.ellipse(at, Vector2(20, 12), -0.25), body)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-14, 0), at + Vector2(-36, 8), at + Vector2(-30, 14), at + Vector2(-10, 9)]), dark)
	c.draw_circle(at + Vector2(17, -13), 10.0, INK)
	c.draw_circle(at + Vector2(17, -13), 8.0, neck)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(24, -14), at + Vector2(33, -10), at + Vector2(24, -8)]), Color(0.86, 0.64, 0.36) if not stone else STONE_DARK)
	c.draw_circle(at + Vector2(19, -15), 2.2, INK)
	if flying or stone:
		for s: float in [-9.0, 5.0]:
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(s - 8.0, -5), at + Vector2(s + 10.0, -6), at + Vector2(s - 8.0, -12.0 - 34.0 * wing)]), INK)
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(s - 5.0, -5), at + Vector2(s + 7.0, -6), at + Vector2(s - 6.0, -10.0 - 29.0 * wing)]), dark if s < 0.0 else body)
	else:
		c.draw_line(at + Vector2(-12, -2), at + Vector2(8, 1), dark, 5.0)
	if not flying:
		for s: float in [-3.0, 5.0]:
			c.draw_line(at + Vector2(s, 9), at + Vector2(s, 15), Color(0.80, 0.44, 0.42) if not stone else STONE_DARK, 2.5)


# --- the place -------------------------------------------------------------------

# Plaça de Sant Feliu at dusk. `wet` is 1 in the rain, 0 with the sun come out
# under the cloud (the victory film's).
static func placa(c: CanvasItem, t: float, wet: float) -> void:
	var dry := 1.0 - wet
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1400.0), Color(0.12, 0.13, 0.28).lerp(Color(0.34, 0.40, 0.66), dry),
		Color(0.56, 0.36, 0.42).lerp(Color(1.0, 0.74, 0.42), dry))
	# the Basílica's blunt tower, its spire cut off short, and the nave
	var far := Color(0.24, 0.22, 0.32).lerp(Color(0.52, 0.40, 0.40), dry)
	var lit := far.lightened(0.12)
	c.draw_rect(Rect2(620, -330, 190, 900), far)
	c.draw_rect(Rect2(620, -330, 34, 900), lit)
	c.draw_colored_polygon(PackedVector2Array([Vector2(632, -330), Vector2(798, -330), Vector2(752, -520), Vector2(678, -520)]), far)
	c.draw_colored_polygon(PackedVector2Array([Vector2(632, -330), Vector2(662, -330), Vector2(690, -520), Vector2(678, -520)]), lit)
	for x: float in [632.0, 798.0]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 14, -330), Vector2(x + 14, -330), Vector2(x, -410)]), lit)
	for yy: float in [-270.0, -130.0]:
		for x: float in [676.0, 740.0]:
			_arch(c, Vector2(x, yy + 90.0), 22.0, 90.0, Color(0.11, 0.11, 0.20))
	c.draw_colored_polygon(PackedVector2Array([Vector2(810, 60), Vector2(1500, 130), Vector2(1500, 560), Vector2(810, 560)]), far.darkened(0.08))
	for i in range(5):
		_arch(c, Vector2(900.0 + float(i) * 130.0, 330.0), 26.0, 120.0, Color(0.96, 0.66, 0.32, 0.55))
	# the Onyar's painted houses to the left, windows lit
	for i in range(9):
		var x := -1560.0 + float(i) * 240.0
		var top := 40.0 - float((i * 53) % 130)
		var col: Color = HOUSES[i % HOUSES.size()].lerp(Color(0.16, 0.16, 0.30), 0.42 * wet)
		c.draw_rect(Rect2(x, top, 236, 560.0 - top), col)
		c.draw_rect(Rect2(x - 4, top - 12, 244, 14), col.darkened(0.35))
		c.draw_rect(Rect2(x, top, 18, 560.0 - top), col.lightened(0.06))
		for r in range(3):
			for q in range(3):
				var w := Rect2(x + 34.0 + float(q) * 66.0, top + 46.0 + float(r) * 120.0, 34, 62)
				var on := (i * 7 + r * 5 + q * 3) % 4 != 0
				c.draw_rect(w.grow(4.0), col.darkened(0.3))
				c.draw_rect(w, Color(1.0, 0.76, 0.40) if on else Color(0.14, 0.15, 0.26))
				c.draw_rect(Rect2(w.position.x - 14.0, w.position.y, 10, 62), col.darkened(0.5))
				c.draw_line(w.position + Vector2(-8, 72), w.position + Vector2(42, 72), IRON, 4.0)
	# the paving, wet: the last light and the windows lying in it
	c.draw_rect(Rect2(-1600, 552, 4600, 20), Color(0.20, 0.19, 0.26).lerp(Color(0.46, 0.38, 0.34), dry))
	IntroKit.vgrad(c, Rect2(-1600, 570, 4600, 700), Color(0.36, 0.33, 0.42).lerp(Color(0.74, 0.60, 0.48), dry),
		Color(0.16, 0.16, 0.26).lerp(Color(0.40, 0.32, 0.32), dry))
	for i in range(22):
		var rx := -1540.0 + float(i) * 190.0
		var ra := 0.16 + 0.05 * sin(t * 1.7 + float(i) * 2.1)
		IntroKit.vgrad(c, Rect2(rx, 574, 34, 170), Color(1.0, 0.72, 0.38, ra), Color(1.0, 0.72, 0.38, 0.0))
	for row in range(5):
		var y := 590.0 + float(row * row) * 13.0 + float(row) * 16.0
		c.draw_line(Vector2(-1600, y), Vector2(3000, y), Color(0.10, 0.10, 0.18, 0.40), 2.5)
		for i in range(34):
			var jx := -1600.0 + float(i) * 140.0 + float(row % 2) * 70.0
			c.draw_line(Vector2(jx, y), Vector2(jx - 10.0, y + 18.0 + float(row) * 24.0), Color(0.10, 0.10, 0.18, 0.30), 2.0)
	# a street lamp at the right, its halo
	c.draw_line(Vector2(1120, 600), Vector2(1120, 190), IRON, 12.0)
	c.draw_line(Vector2(1120, 200), Vector2(1060, 190), IRON, 8.0)
	c.draw_rect(Rect2(1034, 190, 48, 60), IRON)
	c.draw_rect(Rect2(1041, 198, 34, 44), Color(1.0, 0.86, 0.54))
	halo(c, Vector2(1058, 220), 190.0, Color(1.0, 0.78, 0.42, 0.50))


static func _arch(c: CanvasItem, foot: Vector2, hw: float, h: float, col: Color) -> void:
	var pts := PackedVector2Array([foot + Vector2(hw, 0), foot + Vector2(-hw, 0)])
	for i in range(11):
		var a := PI + PI * float(i) / 10.0
		pts.append(foot + Vector2(cos(a) * hw, -h + hw + sin(a) * hw))
	c.draw_colored_polygon(pts, col)


# a soft round light: a fan whose rim has faded to nothing
static func halo(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	var n := 28
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var b := TAU * float(i + 1) / float(n)
		c.draw_polygon(PackedVector2Array([at, at + Vector2.from_angle(a) * r, at + Vector2.from_angle(b) * r]),
			PackedColorArray([col, Color(col, 0.0), Color(col, 0.0)]))


# her column: base, shaft and capital, and the iron steps the town climbs
static func column(c: CanvasItem, x: float, feet: float) -> void:
	var w := COL_W
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(x + 10.0, feet + 6.0), Vector2(150, 15)), Color(0, 0, 0, 0.35))
	var shaft := Rect2(x - w * 0.5, -70.0, w, feet + 70.0)
	c.draw_rect(shaft.grow(5.0), INK)
	c.draw_rect(shaft, STONE_DARK)
	c.draw_rect(Rect2(x - w * 0.5 + 12.0, -70.0, w * 0.46, feet + 70.0), STONE)
	c.draw_rect(Rect2(x - w * 0.5 + 18.0, -70.0, 14, feet + 70.0), STONE_LIT)
	var y := 10.0
	var i := 0
	while y < feet - 60.0:
		c.draw_line(Vector2(x - w * 0.5, y), Vector2(x + w * 0.5, y), CARVE, 3.5)
		if i % 2 == 0:
			c.draw_line(Vector2(x + 16.0, y + 20.0), Vector2(x + 34.0, y + 62.0), Color(CARVE, 0.8), 3.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(x + 30.0 - float(i % 3) * 24.0, y + 6.0), Vector2(18, 8)), MOSS)
		y += 92.0
		i += 1
	for b: Array in [[-112.0, 40.0, w + 64.0], [-72.0, 26.0, w + 34.0], [feet - 44.0, 44.0, w + 80.0], [feet - 70.0, 26.0, w + 40.0]]:
		var r := Rect2(x - float(b[2]) * 0.5, float(b[0]), float(b[2]), float(b[1]))
		c.draw_rect(r.grow(5.0), INK)
		c.draw_rect(r, STONE)
		c.draw_rect(Rect2(r.position, Vector2(r.size.x, 7.0)), STONE_LIT)
	# a landing at the kissing height and one step up to it
	for st: Array in [[96.0, 200.0, 46.0], [302.0, 60.0, 23.0]]:
		var sx := x + float(st[0])
		var sw := float(st[1])
		var sy := feet - float(st[2])
		for lx: float in [sx + 8.0, sx + sw - 8.0]:
			c.draw_line(Vector2(lx, sy), Vector2(lx, feet), IRON, 7.0)
		c.draw_rect(Rect2(sx, sy, sw, 9), IRON)
		c.draw_line(Vector2(sx + 2.0, sy + 1.0), Vector2(sx + sw - 2.0, sy + 1.0), Color(0.48, 0.50, 0.58), 2.0)


static func rain(c: CanvasItem, t: float, k: float) -> void:
	if k <= 0.0:
		return
	for i in range(130):
		var seed_i := float(i)
		var x := -900.0 + fposmod(seed_i * 197.3 - t * 160.0, 2900.0)
		var y := -300.0 + fposmod(seed_i * 331.7 + t * (1250.0 + float(i % 5) * 120.0), 1250.0)
		var d := Vector2(-5.0, 38.0 + float(i % 4) * 8.0)
		c.draw_line(Vector2(x, y), Vector2(x, y) + d, Color(0.78, 0.86, 1.0, (0.20 + 0.06 * float(i % 4)) * k), 2.2)
	for i in range(26):
		var f := fposmod(t * 1.9 + float(i) * 0.37, 1.0)
		var at := Vector2(-900.0 + fposmod(float(i) * 271.9 + floorf(t * 1.9 + float(i) * 0.37) * 133.0, 2600.0), 610.0 + float((i * 37) % 90))
		var el := MillieSide.ellipse(at, Vector2(4.0 + f * 22.0, 1.5 + f * 5.0))
		el.append(el[0])
		c.draw_polyline(el, Color(0.80, 0.88, 1.0, 0.45 * (1.0 - f) * k), 2.0)


# the gaze: a cone of light that thins out with distance, white at its heart
static func beam(c: CanvasItem, from: Vector2, ang: float, length: float, half: float, a: float) -> void:
	for s: Array in [[half, Color(1.0, 0.74, 0.24, 0.55 * a)], [half * 0.45, Color(1.0, 0.94, 0.66, 0.75 * a)]]:
		var h: float = s[0]
		var col: Color = s[1]
		for sd: float in [-1.0, 1.0]:
			c.draw_polygon(PackedVector2Array([from, from + Vector2.from_angle(ang) * length, from + Vector2.from_angle(ang + sd * h) * length]),
				PackedColorArray([col, Color(col, col.a * 0.35), Color(col, 0.0)]))
	halo(c, from, 70.0, Color(1.0, 0.88, 0.50, 0.85 * a))


# --- the lioness -------------------------------------------------------------------

# Her joints in each pose, in her own frame: feet (or the bottom of her hold)
# at the origin, facing right. Stalking, clinging to a column at x 0, sitting.
const RUMP := [Vector2(-96, -150), Vector2(76, -84), Vector2(-66, -74)]
const CHEST := [Vector2(84, -158), Vector2(72, -262), Vector2(24, -178)]
const HEAD := [Vector2(176, -204), Vector2(112, -362), Vector2(74, -262)]
const HIPS := [[Vector2(-74, -124), Vector2(46, -78), Vector2(-74, -46)], [Vector2(66, -124), Vector2(50, -250), Vector2(20, -146)],
	[Vector2(-106, -124), Vector2(78, -70), Vector2(-60, -46)], [Vector2(96, -124), Vector2(76, -256), Vector2(40, -146)]]
const PAWS := [[Vector2(-56, -6), Vector2(-36, -26), Vector2(-26, -12)], [Vector2(62, -6), Vector2(-40, -318), Vector2(30, -6)],
	[Vector2(-112, -6), Vector2(18, -8), Vector2(0, -12)], [Vector2(104, -6), Vector2(20, -300), Vector2(58, -6)]]


static func _pose(a: Array, o: Dictionary) -> Vector2:
	return (a[0] as Vector2).lerp(a[1], o.get("cling", 0.0)).lerp(a[2], o.get("sit", 0.0))


static func head_pos(o: Dictionary) -> Vector2:
	var cr: float = o.get("crouch", 0.0)
	return _pose(HEAD, o) + Vector2(10.0, 46.0) * cr * (1.0 - float(o.get("cling", 0.0))) + Vector2(0.0, 34.0) * float(o.get("slump", 0.0))


# her head's own turn: tipped up the column as carved, down and out once awake
static func head_rot(o: Dictionary) -> float:
	var cling: float = o.get("cling", 0.0)
	return lerpf(0.12, lerpf(-0.95, 0.35, o.get("turn", 0.0)), cling) + float(o.get("tilt", 0.0)) + 0.5 * float(o.get("slump", 0.0)) \
		- 0.28 * float(o.get("jaw", 0.0))


static func eye_pos(at: Vector2, k: float, o: Dictionary) -> Vector2:
	return at + (head_pos(o) + Vector2(24, -14).rotated(head_rot(o))) * k


static func nose_pos(at: Vector2, k: float, o: Dictionary) -> Vector2:
	return at + (head_pos(o) + Vector2(76, 10).rotated(head_rot(o))) * k


static func rear_pos(at: Vector2, k: float, o: Dictionary) -> Vector2:
	return at + (_pose(RUMP, o) + Vector2(0.0, 60.0).rotated(-0.9 * float(o.get("cling", 0.0)))) * k


# `o`: cling 1 on her column, sit on her haunches, crouch low to the ground,
# walking, eye 0 carved shut to 1 open, turn the head round off the column,
# jaw open, gaze her eyes lit, happy the eyes closed smiling, slump the head
# hanging, tilt the head turned, soft the brow lifted, ground where her shadow lies.
static func lleona(c: CanvasItem, at: Vector2, k: float, t: float, o: Dictionary) -> void:
	var cling: float = o.get("cling", 0.0)
	var crouch: float = float(o.get("crouch", 0.0)) * (1.0 - cling)
	var sit: float = o.get("sit", 0.0)
	var walking: bool = o.get("walking", false)
	var p := func(v: Vector2) -> Vector2: return at + v * k
	var low := Vector2(0.0, 44.0) * crouch
	var rump := _pose(RUMP, o) + low * 0.6
	var chest := _pose(CHEST, o) + low
	if cling < 0.5:
		var gy: float = o.get("ground", at.y)
		var near_k := clampf(1.0 - (gy - at.y) / 420.0, 0.25, 1.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(at.x, gy + 6.0 * k), Vector2(190, 15) * k * near_k), Color(0, 0, 0, 0.36 * near_k))
	# the tail: a carved rope ending in a leaf; on the column it winds down it
	var tail := PackedVector2Array()
	for i in range(11):
		var f := float(i) / 10.0
		var st := Vector2(-140.0 - sin(f * 2.6) * 66.0, -150.0 - f * 110.0 + sin(t * 4.0 + f * 3.0) * 10.0 * f)
		var cl := Vector2(96.0 - f * 92.0 + sin(f * PI) * 34.0, -30.0 + f * 96.0)
		var si := Vector2(-120.0 - sin(f * PI) * 70.0, -22.0 - f * 10.0)
		tail.append(p.call(st.lerp(cl, cling).lerp(si, sit)))
	c.draw_polyline(tail, INK, 26.0 * k)
	c.draw_polyline(tail, STONE_DARK, 17.0 * k)
	for i in range(1, 10):
		var n := (tail[i + 1] - tail[i - 1]).normalized().orthogonal() * 8.0 * k
		c.draw_line(tail[i] - n, tail[i] + n * 0.6, CARVE, 3.0 * k)
	var trot := (tail[10] - tail[9]).angle()
	c.draw_colored_polygon(MillieSide.ellipse(tail[10], Vector2(34, 21) * k, trot), INK)
	c.draw_colored_polygon(MillieSide.ellipse(tail[10], Vector2(29, 16) * k, trot), STONE)
	c.draw_line(tail[10] - Vector2.from_angle(trot) * 20.0 * k, tail[10] + Vector2.from_angle(trot) * 22.0 * k, CARVE, 3.5 * k)
	# legs, the far pair first and darker, then the body over them
	for i in range(4):
		if i == 2:
			_body(c, p, rump, chest, k)
		var near := i >= 2
		var hind := i % 2 == 0
		var col := STONE if near else STONE_DEEP
		var hip := _pose(HIPS[i], o) + low * (0.6 if hind else 1.0)
		var paw := _pose(PAWS[i], o)
		if walking:
			var ph: float = t * 8.0 + float([0.0, PI, PI, 0.0][i])
			paw += Vector2(sin(ph) * 30.0, -maxf(0.0, cos(ph)) * 18.0)
		var bend := Vector2(-28.0, 12.0) if hind else Vector2(14.0, 4.0)
		bend = bend.lerp(Vector2(40.0, -6.0) if hind else Vector2(44.0, -2.0), cling)
		var knee := hip.lerp(paw, 0.55) + bend * (1.0 + 0.9 * crouch) * (1.0 - sit * 0.6)
		var leg := PackedVector2Array([p.call(hip), p.call(knee), p.call(paw)])
		# two strokes, rounded at the knee: a polyline's corner comes out square
		c.draw_line(leg[0], leg[1], INK, 52.0 * k)
		c.draw_line(leg[1], leg[2], INK, 48.0 * k)
		c.draw_circle(p.call(hip), (48.0 if hind else 36.0) * k, INK)
		c.draw_circle(p.call(knee), 26.0 * k, INK)
		c.draw_line(leg[0], leg[1], col, 42.0 * k)
		c.draw_line(leg[1], leg[2], col, 38.0 * k)
		c.draw_circle(p.call(hip), (43.0 if hind else 31.0) * k, col)
		c.draw_circle(p.call(knee), 21.0 * k, col)
		if near:
			c.draw_circle(p.call(hip + Vector2(-7, -9)), (27.0 if hind else 18.0) * k, STONE_LIT.lerp(STONE, 0.35))
			c.draw_line(p.call(hip + Vector2(-8, 4)), p.call(knee + Vector2(-8, -2)), STONE_LIT, 9.0 * k)
			# the mason's curls on the shoulder and the haunch
			for q in range(2):
				c.draw_arc(p.call(hip + Vector2(6, 8)), (15.0 + float(q) * 12.0) * k, 0.3, 3.6, 14, CARVE, 3.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(paw + Vector2(10, 0)), Vector2(38, 21) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(paw + Vector2(10, 0)), Vector2(33, 16) * k), col.lightened(0.05))
		for n in range(3):
			var tx := 14.0 + float(n) * 11.0
			c.draw_line(p.call(paw + Vector2(tx, -5)), p.call(paw + Vector2(tx + 3.0, 11)), INK, 3.0 * k)
			c.draw_colored_polygon(PackedVector2Array([p.call(paw + Vector2(tx + 2.0, 6)), p.call(paw + Vector2(tx + 16.0, 14)),
				p.call(paw + Vector2(tx + 6.0, 15))]), STONE_LIT)
	_head(c, at + head_pos(o) * k, k, head_rot(o), t, o)


static func _body(c: CanvasItem, p: Callable, rump: Vector2, chest: Vector2, k: float) -> void:
	var ax := (chest - rump).normalized()
	# her back is the side away from her legs: over a standing body, off the column's
	var back := Vector2(ax.y, -ax.x)
	if back.dot(Vector2(0.45, -1.0)) < 0.0:
		back = -back
	c.draw_line(p.call(rump), p.call(chest), INK, 118.0 * k)
	c.draw_circle(p.call(rump), 66.0 * k, INK)
	c.draw_circle(p.call(chest), 68.0 * k, INK)
	c.draw_line(p.call(rump), p.call(chest), STONE, 107.0 * k)
	c.draw_circle(p.call(rump), 60.5 * k, STONE)
	c.draw_circle(p.call(chest), 62.5 * k, STONE)
	c.draw_line(p.call(rump - back * 32.0), p.call(chest - back * 34.0), STONE_DARK, 42.0 * k)
	c.draw_line(p.call(rump + back * 27.0), p.call(chest + back * 28.0), STONE_LIT.lerp(STONE, 0.4), 44.0 * k)
	c.draw_line(p.call(rump + back * 46.0), p.call(chest + back * 46.0), STONE_LIT, 8.0 * k)
	var ln := rump.distance_to(chest)
	# ribs cut as a row of arcs, moss where the rain never dries, one long crack
	for i in range(6):
		var o: Vector2 = rump + ax * (24.0 + float(i) * (ln - 48.0) / 5.0)
		c.draw_polyline(PackedVector2Array([p.call(o + back * 32.0), p.call(o + ax * 9.0), p.call(o - back * 34.0)]), CARVE, 3.6 * k)
	for i in range(3):
		c.draw_colored_polygon(MillieSide.ellipse(p.call(rump + ax * (18.0 + float(i) * 62.0) + back * (36.0 - float(i) * 22.0)), Vector2(24, 12) * k), MOSS)
	c.draw_polyline(PackedVector2Array([p.call(chest + back * 40.0), p.call(chest - ax * 22.0 + back * 12.0), p.call(chest - ax * 12.0 - back * 10.0),
		p.call(chest - ax * 34.0 - back * 34.0)]), STONE_DEEP, 4.0 * k)


static func _head(c: CanvasItem, at: Vector2, k: float, rot: float, t: float, o: Dictionary) -> void:
	var jaw: float = o.get("jaw", 0.0)
	var open: float = o.get("eye", 0.0)
	var lit: float = o.get("gaze", 0.0)
	var happy: bool = o.get("happy", false)
	var h := func(v: Vector2) -> Vector2: return at + v.rotated(rot) * k
	# the ruff: a collar of stone curls round the back of the head, Romanesque
	# and tidy, that has the town arguing whether she is a lion
	for i in range(9):
		var a := PI * (0.46 + 1.06 * float(i) / 8.0)
		c.draw_circle(h.call(Vector2(-14, 4) + Vector2.from_angle(a) * 56.0), 25.0 * k, INK)
	for i in range(9):
		var a := PI * (0.46 + 1.06 * float(i) / 8.0)
		var cc: Vector2 = h.call(Vector2(-14, 4) + Vector2.from_angle(a) * 56.0)
		c.draw_circle(cc, 20.0 * k, STONE_DARK if i % 2 == 0 else STONE)
		c.draw_arc(cc, 10.0 * k, a, a + 4.6, 12, CARVE, 4.0 * k)
	# the lower jaw, under the muzzle, dropped to roar
	var hinge := Vector2(6, 22)
	var j := func(v: Vector2) -> Vector2: return h.call(hinge + v.rotated(jaw * 0.85))
	if jaw > 0.04:
		c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(0, 14)), h.call(Vector2(74, 22)), j.call(Vector2(60, 6)), j.call(Vector2(0, 14))]), MOUTH)
	c.draw_colored_polygon(MillieSide.ellipse(j.call(Vector2(28, 14)), Vector2(40, 18) * k, rot + jaw * 0.85), INK)
	c.draw_colored_polygon(MillieSide.ellipse(j.call(Vector2(28, 14)), Vector2(35, 13) * k, rot + jaw * 0.85), STONE_DARK)
	if jaw > 0.12:
		for fx: float in [34.0, 50.0]:
			c.draw_colored_polygon(PackedVector2Array([j.call(Vector2(fx - 5, 6)), j.call(Vector2(fx + 1, -18.0 * minf(1.0, jaw * 1.5))), j.call(Vector2(fx + 7, 6))]), STONE_LIT)
	# skull, round ear, muzzle
	c.draw_circle(at, 56.0 * k, INK)
	c.draw_circle(at, 51.0 * k, STONE)
	c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(-8, -18)), Vector2(34, 24) * k, rot), STONE_LIT.lerp(STONE, 0.3))
	for e: Array in [[24.0, INK], [18.5, STONE], [10.0, CARVE]]:
		c.draw_circle(h.call(Vector2(-26, -46)), float(e[0]) * k, e[1])
	c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(48, 12)), Vector2(40, 29) * k, rot), INK)
	c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(47, 11)), Vector2(35, 24) * k, rot), STONE)
	c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(44, 2)), Vector2(27, 11) * k, rot), STONE_LIT)
	c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(66, -8)), h.call(Vector2(88, -4)), h.call(Vector2(80, 14))]), STONE_DEEP.darkened(0.35))
	if jaw > 0.12:
		for fx: float in [48.0, 66.0]:
			c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(fx - 6, 28)), h.call(Vector2(fx, 30.0 + 22.0 * minf(1.0, jaw * 1.4))), h.call(Vector2(fx + 7, 27))]), STONE_LIT)
		# the lip drawn back in creases
		for q in range(3):
			c.draw_line(h.call(Vector2(22.0 + float(q) * 10.0, -4.0 + float(q) * 2.0)), h.call(Vector2(34.0 + float(q) * 10.0, 8)), CARVE, 3.0 * k)
	else:
		c.draw_polyline(PackedVector2Array([h.call(Vector2(80, 16)), h.call(Vector2(58, 27 if not happy else 31)), h.call(Vector2(32, 24 if not happy else 26)), h.call(Vector2(22, 24 if not happy else 12))]), STONE_DEEP, 4.5 * k)
	for q in range(4):
		c.draw_circle(h.call(Vector2(44.0 + float(q % 2) * 12.0, 8.0 + float(q / 2) * 9.0)), 2.2 * k, CARVE)
	# the eye: shut, a carved lid; awake, gold under a brow that comes down on it
	var ey := Vector2(24, -14)
	if happy:
		c.draw_arc(h.call(ey + Vector2(0, 6)), 13.0 * k, rot + PI * 1.1, rot + PI * 1.9, 12, INK, 5.0 * k)
	elif open <= 0.0:
		c.draw_line(h.call(ey + Vector2(-13, 0)), h.call(ey + Vector2(13, 3)), INK, 5.5 * k)
		c.draw_line(h.call(ey + Vector2(-12, -9)), h.call(ey + Vector2(12, -7)), CARVE, 4.0 * k)
	else:
		c.draw_colored_polygon(MillieSide.ellipse(h.call(ey), Vector2(18, 14.5 * open) * k, rot), INK)
		c.draw_colored_polygon(MillieSide.ellipse(h.call(ey), Vector2(14, 10.5 * open) * k, rot), EYE_GOLD.lerp(Color(1.0, 0.97, 0.80), lit))
		if lit < 0.7:
			c.draw_colored_polygon(MillieSide.ellipse(h.call(ey + Vector2(3, 0)), Vector2(3.4, 9.0 * open) * k, rot), INK)
		if bool(o.get("soft", false)):
			c.draw_arc(h.call(ey + Vector2(0, -4)), 22.0 * k, rot + PI * 1.2, rot + PI * 1.75, 10, STONE_DARK, 5.0 * k)
		else:
			c.draw_colored_polygon(PackedVector2Array([h.call(ey + Vector2(-24, -24)), h.call(ey + Vector2(22, -10)), h.call(ey + Vector2(22, -2)), h.call(ey + Vector2(-20, -12))]), INK)
			c.draw_line(h.call(ey + Vector2(-20, -21)), h.call(ey + Vector2(18, -9)), STONE_DARK, 4.0 * k)
		if lit > 0.0:
			halo(c, h.call(ey), (46.0 + 6.0 * sin(t * 24.0)) * k, Color(1.0, 0.86, 0.46, 0.85 * lit))
		elif open < 1.0 or bool(o.get("glow", false)):
			halo(c, h.call(ey), 40.0 * k, Color(1.0, 0.80, 0.34, 0.6))


# the card: the dusk gone gold behind LA LLEONA!, her head filling the left of
# the frame, the gaze straight out across it
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, -100.0, 1680, 924.0), Color(0.14, 0.13, 0.32), Color(0.90, 0.54, 0.30))
	var d := t - TITLE_AT
	var o := {"eye": 1.0, "jaw": 1.0, "gaze": 0.9, "crouch": 0.35, "turn": 1.0}
	var at := Vector2(-270.0 + d * 60.0, 1010.0)
	lleona(c, at, 2.7, t, o)
	beam(c, eye_pos(at, 2.7, o), 0.10 + 0.10 * sin(d * 2.2), 1500.0, 0.10, 0.75)
	FilmKit.slam(c, t, "LA LLEONA!", Vector2(740, 200))
	var ml := Engine.get_main_loop()
	var gm: Node = ml.root.get_node_or_null("Game") if ml != null and ml is SceneTree else null
	if gm == null or bool(gm.flashes):
		IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
