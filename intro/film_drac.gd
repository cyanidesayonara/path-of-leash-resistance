class_name FilmDrac
extends RefCounted

# El Mosaic's film, "El Drac": the salamander's wake (docs/BOSSES.md), played
# as she first passes his fountain stair (systems/boss_drac.gd), before the
# walk's own wake. Park Guell at noon, side on: the gatehouse with its
# mushroom roof, the market hall's columns at the head of the stair, the
# trencadis walls of the flights, and on the grotto fountain in the middle
# the salamander, head down, tail curled up behind, water running from his
# mouth. The two of them walk past, your human on the phone. The fountain
# sputters and stops: her ears go up and she looks back. His eye opens. A
# ripple runs down his tiles from nose to tail; his tongue flicks. He slides
# off the fountain onto the gravel with a splash and comes on, low and
# quick. She does not run: she dashes back and plants herself between your
# human and him, barking. EL DRAC! slams in, the jet arcing over it.
#
# side(), stair() and park() are shared with the win film.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const LENGTH := FilmKit.LENGTH
const BG := Color(0.50, 0.76, 0.95)
const FEET := 640.0
const PLINTH_X := -170.0
const PLINTH_TOP := FEET - 160.0
const DRAC_K := 2.3
const SPUTTER_AT := 1.25         # the fountain from his mouth sputters
const STOP_AT := 1.6             # and stops
const EYES_AT := 2.05            # an eye opens
const RIPPLE_AT := 2.25          # the tiles ripple, nose to tail
const TONGUE_AT := 2.55
const HOP_AT := 2.75             # off the fountain
const DROP_AT := 3.05            # on the gravel: the splash
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const INK := IntroKit.INK
const STONE := Color(0.80, 0.72, 0.58)
const STONE_LIT := Color(0.92, 0.86, 0.74)
const STONE_DARK := Color(0.58, 0.50, 0.40)
const GRAVEL := Color(0.86, 0.78, 0.62)
const WATER := Color(0.40, 0.70, 0.84)
const SPRAY := Color(0.88, 0.96, 1.0)
const EYE_AMBER := Color(1.0, 0.78, 0.22)
const MOUTH := Color(0.50, 0.12, 0.12)
const TONGUE := Color(0.90, 0.36, 0.44)
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[SPUTTER_AT, "drac_jet", 1.3, -10.0],
	[1.30, "drac_click", 1.2, -8.0],
	[STOP_AT, "splash", 1.4, -14.0],
	[EYES_AT, "drac_click", 1.5, -6.0],
	[RIPPLE_AT, "drac_click", 1.0, -7.0],
	[RIPPLE_AT + 0.12, "drac_click", 0.85, -8.0],
	[TONGUE_AT, "hiss", 1.4, -9.0],
	[HOP_AT, "drum", 0.6, -6.0],
	[DROP_AT, "drum", 0.45, -2.0],
	[DROP_AT + 0.05, "splash", 0.8, -6.0],
	[DROP_AT + 0.1, "ooooh", 0.9, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[BOLT_AT + 0.75, "bark", 1.0, -4.0],
	[TITLE_AT, "drac_jet", 0.85, -2.0],
	[TITLE_AT + 0.05, "crack", 0.8, -2.0],
]


# the camera: on the pair; a pan back to the fountain when she looks round,
# held as he wakes and slides down; her stare; wide on the stand-off
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 91.0), sin(t * 67.0)) * 12.0 * (1.0 - Anim.span(t, DROP_AT, DROP_AT + 0.35)) \
		if t >= DROP_AT else Vector2.ZERO
	if t >= BOLT_AT:
		return [Vector2(300.0, 430.0) + shake, Anim.k(t, [[BOLT_AT, 0.92], [TITLE_AT, 0.86, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 40.0, "io"], [3.9, 140.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 420.0, "io"], [3.9, 440.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.86, "io"], [3.9, 0.9, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y) + shake, z]


# where his belly is: lying head down along the fountain's top, the slide
# down its face, then low and quick across the gravel
static func drac_at(t: float) -> Vector2:
	if t < HOP_AT:
		return Vector2(PLINTH_X, PLINTH_TOP)
	if t < DROP_AT:
		var f := Anim.span(t, HOP_AT, DROP_AT)
		return Vector2(lerpf(PLINTH_X, PLINTH_X + 220.0, f), lerpf(PLINTH_TOP, FEET, f * f) - sin(f * PI) * 40.0)
	return Vector2(Anim.k(t, [[DROP_AT, PLINTH_X + 220.0], [3.9, -30.0, "out"], [TITLE_AT, -10.0]]), FEET)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	park(c, t_real)
	stair(c, t_real, PLINTH_X, PLINTH_TOP)
	var on_top := t < HOP_AT
	var f := Anim.span(t, HOP_AT, DROP_AT)
	var o := {
		"eye": Anim.span(t, EYES_AT, EYES_AT + 0.12),
		"rise": 0.0 if t < DROP_AT else Anim.span(t, DROP_AT, DROP_AT + 0.25) * 0.75,
		"tilt": 0.22 if on_top else lerpf(0.22, 0.0, f),
		"curl": lerpf(2.5, 0.9, Anim.span(t, RIPPLE_AT + 0.2, HOP_AT)),
		"ripple": Anim.span(t, RIPPLE_AT, RIPPLE_AT + 0.45),
		"tongue": Anim.span(t, TONGUE_AT, TONGUE_AT + 0.08) * (1.0 - Anim.span(t, TONGUE_AT + 0.16, TONGUE_AT + 0.24)),
		"lift": Anim.span(t, EYES_AT + 0.1, EYES_AT + 0.4) * 0.6,
		"walk": t_real * 13.0 if (t >= DROP_AT + 0.1 and t < 3.9) else -1.0,
		"wag": 0.6 if t >= DROP_AT else 0.0,
	}
	# the fountain from his mouth: running, sputtering, gone
	var flow := 1.0 - Anim.span(t_real, STOP_AT - 0.05, STOP_AT)
	if t_real >= SPUTTER_AT and t_real < STOP_AT:
		flow *= 0.35 + 0.65 * absf(sin(t_real * 40.0))
	if t >= BOLT_AT + 0.3:
		# at her: a warning squirt
		o["mouth"] = 1.0
		o["spout"] = 180.0 * Anim.span(t, BOLT_AT + 0.3, BOLT_AT + 0.45)
	elif flow > 0.0:
		o["mouth"] = 0.25
	var tip := side(c, drac_at(t), DRAC_K, 1.0, t_real, o)
	if flow > 0.0 and t < HOP_AT:
		# the trickle off his lip into the basin
		var basin := Vector2(PLINTH_X + 300.0, FEET - 28.0)
		var pts := PackedVector2Array()
		for i in range(8):
			var u := float(i) / 7.0
			pts.append(tip.lerp(basin, u) + Vector2(14.0 * sin(u * PI), 0.0))
		c.draw_polyline(pts, Color(WATER, 0.85 * flow), 7.0)
		c.draw_polyline(pts, Color(SPRAY, 0.9 * flow), 3.0)
	if t >= DROP_AT and t < DROP_AT + 0.6:
		var g := Anim.span(t, DROP_AT, DROP_AT + 0.6)
		for k in range(9):
			var a := float(k) / 8.0 * PI
			var sp := drac_at(t) + Vector2(cos(a) * (110.0 + g * 130.0), -sin(a) * (30.0 + g * 60.0) + g * g * 80.0)
			c.draw_circle(sp, 9.0 * (1.0 - g) + 2.0, Color(SPRAY, 1.0 - g))
		for k in range(6):
			var a := float(k) / 5.0 * PI
			IntroKit.puff(c, drac_at(t) + Vector2(cos(a) * (120.0 + g * 120.0), -sin(a) * 16.0 - 8.0), 20.0 * (1.0 - g), 1.0 - g)
	FilmKit.pair(c, t_real, FEET, true)
	FilmKit.fades(c, t_real)


# Park Guell at noon: a deep sky, Barcelona and the sea down the hill, the
# pines, the gatehouse with its mushroom roof and spire, the gravel
static func park(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1800.0, -1200.0, 5000.0, 1500.0), Color(0.24, 0.52, 0.90), Color(0.78, 0.90, 0.98))
	var gb := ShapeBatch.new(c)
	gb.glow(Vector2(1180.0, -60.0), 420.0, Color(1.0, 0.98, 0.86, 0.6))
	gb.flush()
	for i in range(5):
		var cx := -1500.0 + float(i) * 760.0 + t * 8.0
		var cy := 40.0 + fposmod(float(i) * 61.0, 90.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx, cy), Vector2(170.0, 26.0)), Color(1.0, 1.0, 1.0, 0.85))
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx + 70.0, cy - 18.0), Vector2(90.0, 24.0)), Color(1.0, 1.0, 1.0, 0.85))
	# the city and the sea, hazy, far below
	c.draw_rect(Rect2(-1800.0, 300.0, 5000.0, 40.0), Color(0.56, 0.74, 0.90))
	for i in range(60):
		var bx := -1800.0 + float(i) * 86.0
		var bh := 10.0 + fposmod(float(i) * 37.0, 26.0)
		c.draw_rect(Rect2(bx, 340.0 - bh, 70.0, bh + 40.0), Color(0.72, 0.74, 0.80))
	c.draw_rect(Rect2(-1800.0, 370.0, 5000.0, 400.0), Color(0.46, 0.60, 0.44))
	# pines along the hill
	for i in range(14):
		var px := -1700.0 + float(i) * 360.0 + fposmod(float(i) * 97.0, 120.0)
		var py := 390.0
		c.draw_line(Vector2(px, py + 40.0), Vector2(px + 10.0, py - 70.0), Color(0.44, 0.32, 0.24), 12.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(px + 10.0, py - 90.0), Vector2(110.0, 38.0)), Color(0.24, 0.40, 0.24))
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(px - 10.0, py - 104.0), Vector2(70.0, 22.0)), Color(0.32, 0.50, 0.28))
	_gatehouse(c, 1150.0)
	# the gravel, raked, with its stones
	IntroKit.vgrad(c, Rect2(-1800.0, FEET - 30.0, 5000.0, 700.0), GRAVEL, GRAVEL.darkened(0.18))
	c.draw_rect(Rect2(-1800.0, FEET - 34.0, 5000.0, 6.0), STONE_DARK)
	for px in range(-24, 44):
		c.draw_circle(Vector2(float(px) * 71.0 + float(px % 3) * 17.0, FEET + 24.0 + float(px % 4) * 28.0), 4.0, GRAVEL.darkened(0.16))


# the gatehouse: stone walls, a roof of white trencadis like icing with blue
# and red bands, the white mushroom on top and the spire with its cross
static func _gatehouse(c: CanvasItem, x: float) -> void:
	var wall := Color(0.82, 0.70, 0.52)
	var base := 520.0
	c.draw_rect(Rect2(x - 150.0, 280.0, 300.0, base - 280.0), INK)
	c.draw_rect(Rect2(x - 146.0, 284.0, 292.0, base - 284.0), wall)
	for row in range(5):
		for col in range(7):
			var sx := x - 140.0 + float(col) * 42.0 + float(row % 2) * 20.0
			c.draw_rect(Rect2(sx, 296.0 + float(row) * 44.0, 36.0, 38.0), wall.darkened(0.06 + 0.04 * float((row + col) % 3)))
	c.draw_rect(Rect2(x - 30.0, 380.0, 60.0, base - 380.0), Color(0.36, 0.26, 0.20))
	c.draw_circle(Vector2(x, 380.0), 30.0, Color(0.36, 0.26, 0.20))
	var roof := PackedVector2Array()
	for i in range(17):
		var u := float(i) / 16.0
		var ang := PI + u * PI
		roof.append(Vector2(x + cos(ang) * 190.0, 290.0 + sin(ang) * 170.0 + sin(u * 22.0) * 10.0))
	c.draw_colored_polygon(roof, INK)
	var inner := PackedVector2Array()
	for p: Vector2 in roof:
		inner.append(Vector2(x, 290.0) + (p - Vector2(x, 290.0)) * 0.96)
	c.draw_colored_polygon(inner, Color(0.97, 0.95, 0.90))
	var bands: Array[Color] = [Color(0.20, 0.42, 0.78), Color(0.80, 0.30, 0.26), Color(0.20, 0.42, 0.78)]
	for band in range(3):
		var r := 60.0 + float(band) * 50.0
		var pts := PackedVector2Array()
		for i in range(15):
			var ang := PI + float(i) / 14.0 * PI
			pts.append(Vector2(x + cos(ang) * r * 1.08, 290.0 + sin(ang) * r * 0.86))
		c.draw_polyline(pts, bands[band], 10.0)
	var dots: Array[Color] = [Color(0.20, 0.42, 0.78), Color(0.98, 0.80, 0.22), Color(0.80, 0.30, 0.26)]
	for i in range(30):
		var a := PI + fposmod(float(i) * 0.6180, 1.0) * PI
		var r := 30.0 + fposmod(float(i) * 0.37, 1.0) * 140.0
		c.draw_circle(Vector2(x + cos(a) * r, 290.0 + sin(a) * r * 0.8), 5.0, dots[i % 3])
	c.draw_rect(Rect2(x - 12.0, 70.0, 24.0, 60.0), INK)
	c.draw_rect(Rect2(x - 8.0, 74.0, 16.0, 56.0), Color(0.97, 0.95, 0.90))
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(x, 70.0), Vector2(52.0, 28.0)), INK)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(x, 68.0), Vector2(48.0, 23.0)), Color(0.97, 0.95, 0.90))
	for k in range(6):
		c.draw_circle(Vector2(x - 34.0 + float(k) * 14.0, 62.0 - absf(float(k) - 2.5) * 2.0), 5.0, Color(0.80, 0.30, 0.26))
	c.draw_line(Vector2(x, 44.0), Vector2(x, -10.0), INK, 8.0)
	c.draw_line(Vector2(x - 16.0, 6.0), Vector2(x + 16.0, 6.0), INK, 8.0)


# The stair: the market hall's Doric columns along its head with the
# serpentine bench on its roof, the flights either side, their walls of
# trencadis, and the grotto fountain in the middle with its tiers of
# dripping stone and the basin at its foot. The fountain's top is at `top`,
# its middle at `x`.
static func stair(c: CanvasItem, t: float, x: float, top: float) -> void:
	for i in range(9):
		var cx := x - 520.0 + float(i) * 130.0
		c.draw_rect(Rect2(cx - 30.0, 120.0, 60.0, 200.0), INK)
		c.draw_rect(Rect2(cx - 26.0, 124.0, 52.0, 196.0), STONE_LIT)
		c.draw_rect(Rect2(cx + 4.0, 124.0, 22.0, 196.0), STONE)
		c.draw_rect(Rect2(cx - 38.0, 110.0, 76.0, 18.0), INK)
		c.draw_rect(Rect2(cx - 34.0, 113.0, 68.0, 12.0), STONE_LIT)
	c.draw_rect(Rect2(x - 600.0, 70.0, 1200.0, 46.0), INK)
	c.draw_rect(Rect2(x - 596.0, 74.0, 1192.0, 38.0), STONE)
	var bench := PackedVector2Array()
	for i in range(30):
		var u := float(i) / 29.0
		bench.append(Vector2(x - 600.0 + u * 1200.0, 62.0 + sin(u * 13.0) * 10.0))
	c.draw_polyline(bench, INK, 30.0)
	c.draw_polyline(bench, Color(0.96, 0.95, 0.90), 22.0)
	var b := ShapeBatch.new(c)
	for i in range(30):
		var h := BossDrac._hash(float(i), 3.0)
		b.quad(bench[i] + Vector2(-11.0, -6.0), bench[i] + Vector2(8.0, -7.0 + h * 3.0), bench[i] + Vector2(10.0, 5.0),
			bench[i] + Vector2(-9.0, 6.0 - h * 3.0), BossDrac.TILES[(i * 7 + int(h * 4.0)) % BossDrac.TILES.size()])
	b.flush()
	# the flights: steps going up either side, seen along their edge
	for sd: float in [-1.0, 1.0]:
		var foot := x + sd * 300.0
		for k in range(10):
			var sy := FEET - 30.0 - float(k) * 30.0
			var sx := foot - sd * float(k) * 8.0
			c.draw_rect(Rect2(sx - 140.0, sy - 30.0, 280.0, 32.0), STONE.darkened(0.04 * float(k % 2)))
			c.draw_line(Vector2(sx - 140.0, sy - 30.0), Vector2(sx + 140.0, sy - 30.0), STONE_LIT, 3.0)
	# the trencadis walls along the flights: a course of tile with a wavy cap
	for sd: float in [-1.0, 1.0]:
		var wx := x + sd * 420.0 + 60.0
		var r := Rect2(wx - 70.0, 430.0, 140.0, FEET - 30.0 - 430.0)
		c.draw_rect(r.grow(4.0), INK)
		c.draw_rect(r, Color(0.86, 0.84, 0.78))
		var wb := ShapeBatch.new(c)
		var yy := 304.0
		var row := 0
		while yy < FEET - 8.0:
			var xx := r.position.x + 2.0
			var ci := 0
			while xx < r.end.x - 4.0:
				var h := BossDrac._hash(wx + xx, yy)
				var w := 11.0 + h * 8.0
				var x1 := minf(xx + w, r.end.x - 2.0)
				var col: Color = BossDrac.TILES[(row * 3 + ci * 2 + int(h * 5.0)) % BossDrac.TILES.size()]
				wb.quad(Vector2(xx, yy), Vector2(x1, yy + h * 2.0), Vector2(x1 - 1.0, yy + 13.0), Vector2(xx + 1.0, yy + 12.0 - h * 2.0), col)
				xx += w + 1.5
				ci += 1
			yy += 14.5
			row += 1
		wb.flush()
		var cap := PackedVector2Array()
		for i in range(9):
			var u := float(i) / 8.0
			cap.append(Vector2(r.position.x - 6.0 + u * (r.size.x + 12.0), 430.0 - sin(u * PI * 2.0) * 12.0))
		c.draw_polyline(cap, INK, 18.0)
		c.draw_polyline(cap, Color(0.98, 0.80, 0.22), 10.0)
	# the grotto fountain: three tiers of dripping stone, stepping down right
	for tier in range(3):
		var tw := 360.0 - float(tier) * 50.0
		var ty := top + float(tier) * 50.0
		var ox := 60.0 * float(tier)
		var tc := STONE_DARK.lerp(STONE, 0.4 + 0.2 * float(tier))
		var shape := PackedVector2Array()
		for i in range(13):
			var u := float(i) / 12.0
			shape.append(Vector2(x - tw * 0.5 + u * tw + ox, ty + sin(u * 31.0 + float(tier)) * 5.0))
		shape.append(Vector2(x + tw * 0.5 + ox, FEET - 20.0))
		shape.append(Vector2(x - tw * 0.5 + ox, FEET - 20.0))
		c.draw_colored_polygon(shape, INK)
		var inner := PackedVector2Array()
		var cen := Vector2(x + ox, (ty + FEET - 20.0) * 0.5)
		for p: Vector2 in shape:
			inner.append(cen + (p - cen) * Vector2(0.97, 0.96))
		c.draw_colored_polygon(inner, tc)
		for i in range(9):
			var dx := x - tw * 0.5 + 18.0 + float(i) * (tw - 36.0) / 8.0 + ox
			var dl := 14.0 + fposmod(float(i) * 0.37 + float(tier) * 0.21, 1.0) * 22.0
			c.draw_line(Vector2(dx, ty + 4.0), Vector2(dx, ty + dl), tc.darkened(0.22), 10.0)
			c.draw_circle(Vector2(dx, ty + dl), 6.0, tc.darkened(0.22))
	var basin := Vector2(x + 300.0, FEET - 20.0)
	c.draw_colored_polygon(MillieSide.ellipse(basin, Vector2(96.0, 30.0)), INK)
	c.draw_colored_polygon(MillieSide.ellipse(basin, Vector2(90.0, 24.0)), Color(0.94, 0.92, 0.86))
	for k in range(14):
		var a := PI + float(k) / 13.0 * PI
		c.draw_circle(basin + Vector2(cos(a) * 84.0, sin(a) * 20.0 + 6.0), 6.0, BossDrac.TILES[k % BossDrac.TILES.size()])
	c.draw_colored_polygon(MillieSide.ellipse(basin + Vector2(0.0, -8.0), Vector2(74.0, 10.0)), WATER)
	c.draw_line(basin + Vector2(-50.0 + sin(t * 2.0) * 10.0, -8.0), basin + Vector2(-20.0 + sin(t * 2.0) * 10.0, -8.0), SPRAY, 3.0)


# The salamander side on, facing `face`, his belly at `at`: a spine from
# snout to curled tail with a girth at every joint, skinned in broken tile
# on mortar like the walk's (BossDrac), four sprawled legs, a bulging eye on
# top of his head. Returns the corner of his mouth.
# The pose `o`: `eye` open, `happy`, `dazed`, `rise` up off his belly, `tilt`
# nose down (radians), `curl` the tail over his back, `wag`, `ripple` a swell
# run down the tiles (0..1 as it runs), `lift` the head, `mouth` open,
# `tongue` out, `spout` a jet of that length, `walk` the legs' phase (-1 still).
static func side(c: CanvasItem, at: Vector2, k: float, face: float, t: float, o: Dictionary) -> Vector2:
	var eye: float = o.get("eye", 1.0)
	var happy: bool = o.get("happy", false)
	var dazed: bool = o.get("dazed", false)
	var rise: float = o.get("rise", 0.0)
	var tilt: float = o.get("tilt", 0.0)
	var curl: float = o.get("curl", 1.0)
	var wag: float = o.get("wag", 0.0)
	var ripple: float = o.get("ripple", 0.0)
	var lift: float = o.get("lift", 0.0)
	var mouth: float = o.get("mouth", 0.0)
	var tongue: float = o.get("tongue", 0.0)
	var spout: float = o.get("spout", 0.0)
	var walk: float = o.get("walk", -1.0)
	var p := func(v: Vector2) -> Vector2: return at + Vector2(v.x * face, v.y).rotated(tilt * face) * k
	var b := ShapeBatch.new(c)
	var hb := lerpf(16.0, 36.0, rise)
	b.polygon(MillieSide.ellipse(at + Vector2(0.0, 2.0), Vector2(150.0, 10.0) * k, tilt * face), Color(0.10, 0.08, 0.06, 0.30))

	# the spine in his frame: x forward, y down
	var sp := PackedVector2Array()
	var rad := PackedFloat32Array()
	for i in range(BossDrac.BODY_N):
		var bx := lerpf(74.0, -36.0, float(i) / float(BossDrac.BODY_N - 1))
		var head := clampf((bx - 30.0) / 44.0, 0.0, 1.0)
		var by := -hb - 2.0 * sin((bx + 36.0) / 110.0 * PI) - head * head * lift * 22.0
		if walk >= 0.0:
			by += sin(walk + bx * 0.04) * 2.0
		sp.append(Vector2(bx, by))
		rad.append(BossDrac._girth(bx) * 0.78)
	var q := sp[BossDrac.BODY_N - 1]
	for j in range(1, BossDrac.TAIL_N + 1):
		var v := float(j) / float(BossDrac.TAIL_N)
		var heading := PI - 0.12 + curl * v * v * 1.4 + wag * sin(t * 6.0 - v * 4.0) * v * 0.5
		q += Vector2.from_angle(heading) * 10.5
		q.y = minf(q.y, -3.0)
		sp.append(q)
		rad.append(lerpf(13.0, 2.6, pow(v, 0.8)))
	var n := sp.size()
	if ripple > 0.0 and ripple < 1.0:
		for i in range(n):
			var u := float(i) / float(n - 1)
			rad[i] *= 1.0 + 0.35 * maxf(0.0, 1.0 - absf(u - ripple) * 7.0)
	var pts := PackedVector2Array()
	var nrm := PackedVector2Array()
	for i in range(n):
		pts.append(p.call(sp[i]))
	for i in range(n):
		var tan := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		nrm.append(tan.orthogonal())
	for i in range(n):
		rad[i] *= k

	var legs: Array = [[26.0, true, false], [-24.0, false, false], [26.0, true, true], [-24.0, false, true]]
	for li in range(2):
		_leg(b, p, legs[li], hb, walk, k, true)
	BossDrac._strip(b, pts, nrm, rad, 3.0 * k, Vector2.ZERO, BossDrac.INK)
	b.circle(pts[0], rad[0] + 3.0 * k, BossDrac.INK)
	BossDrac._strip(b, pts, nrm, rad, 0.0, Vector2.ZERO, BossDrac.GROUT)
	b.circle(pts[0], rad[0], BossDrac.GROUT)
	# the tile: shards between the joints, lit from above
	for i in range(n - 1):
		var r0 := rad[i]
		var r1 := rad[i + 1]
		var cols := clampi(int((r0 + r1) / (13.0 * k)), 1, 4)
		for cc in range(cols):
			var a0 := -1.0 + 2.0 * float(cc) / float(cols)
			var a1 := -1.0 + 2.0 * float(cc + 1) / float(cols)
			var h := BossDrac._hash(float(i), float(cc))
			var pa := pts[i].lerp(pts[i + 1], 0.03 + h * 0.05)
			var pb := pts[i].lerp(pts[i + 1], 0.97 - fmod(h * 7.0, 1.0) * 0.05)
			var la0 := a0 + 0.03 + 0.08 / float(cols) * h
			var la1 := a1 - 0.03 - 0.08 / float(cols) * fmod(h * 3.0, 1.0)
			var col := BossDrac._tile(i, cc, cols, h)
			var up := nrm[i].dot(Vector2.UP) * (a0 + a1) * 0.5
			col = col.lightened(0.18 * up) if up > 0.0 else col.darkened(-0.25 * up)
			b.quad(pa + nrm[i] * r0 * la0 * 0.98, pb + nrm[i + 1] * r1 * la0 * 0.98,
				pb + nrm[i + 1] * r1 * la1 * 0.98, pa + nrm[i] * r0 * la1 * 0.98, col)
	# the crest along his back, and the glaze catching the sun
	for i in range(3, n - 2, 2):
		var up_n: Vector2 = nrm[i] if nrm[i].y < 0.0 else -nrm[i]
		var top: Vector2 = pts[i] + up_n * rad[i] * 0.86
		b.circle(top, 4.2 * k, BossDrac.INK)
		b.circle(top, 3.0 * k, BossDrac.TILE_WHITE)
	for g in range(4):
		var gi := 3 + g * 5
		if gi < n:
			var tw := pow(maxf(0.0, sin(t * 2.3 + float(g) * 1.7)), 6.0)
			b.circle(pts[gi] + Vector2(0.0, -rad[gi] * 0.5), (1.6 + tw * 2.4) * k, Color(1.0, 1.0, 1.0, 0.5 + 0.5 * tw))
	for li in range(2, 4):
		_leg(b, p, legs[li], hb, walk, k, false)

	# the head: the mouth along the snout, the nostril, the eye on top
	var hinge: Vector2 = p.call(Vector2(46.0, sp[3].y + 4.0))
	var lip: Vector2 = p.call(Vector2(76.0, sp[0].y + 5.0))
	if mouth > 0.03:
		var low: Vector2 = hinge + (lip - hinge).rotated(0.5 * mouth * face)
		b.polygon(PackedVector2Array([hinge, lip, low]), MOUTH)
		b.capsule(hinge, low, 4.0 * k, BossDrac.INK)
		b.capsule(hinge, low, 2.6 * k, BossDrac.TILE_YELLOW)
	else:
		b.line(hinge, lip, BossDrac.INK, 2.6 * k)
	if tongue > 0.0:
		var tt: Vector2 = lip + Vector2(face, 0.0).rotated(tilt * face) * 46.0 * k * tongue
		b.line(lip, tt, TONGUE, 3.0 * k)
		b.line(tt, tt + Vector2(face * 10.0, -8.0) * k, TONGUE, 2.4 * k)
		b.line(tt, tt + Vector2(face * 10.0, 8.0) * k, TONGUE, 2.4 * k)
	b.circle(p.call(Vector2(72.0, sp[0].y - 5.0)), 2.0 * k, BossDrac.INK)
	var ep: Vector2 = p.call(Vector2(52.0, sp[3].y - rad[3] / k * 0.85))
	if not (dazed or happy or eye <= 0.05):
		b.glow(ep, 30.0 * k * eye, Color(1.0, 0.80, 0.30, 0.45))
	b.circle(ep, 11.0 * k, BossDrac.INK)
	if dazed:
		b.circle(ep, 8.6 * k, BossDrac.TILE_WHITE)
		for cr: float in [-1.0, 1.0]:
			b.line(ep + Vector2(-5.0, -5.0 * cr) * k, ep + Vector2(5.0, 5.0 * cr) * k, BossDrac.INK, 2.4 * k)
	elif happy or eye <= 0.05:
		b.circle(ep, 8.6 * k, BossDrac.TILE_BLUE)
		b.circle(ep + Vector2(-2.0, -3.0) * k, 4.0 * k, BossDrac.TILE_CYAN)
		if happy:
			b.line(ep + Vector2(-6.0, 2.0) * k, ep + Vector2(0.0, -3.0) * k, BossDrac.INK, 2.6 * k)
			b.line(ep + Vector2(0.0, -3.0) * k, ep + Vector2(6.0, 2.0) * k, BossDrac.INK, 2.6 * k)
		else:
			b.line(ep + Vector2(-7.0, 1.0) * k, ep + Vector2(7.0, 1.0) * k, BossDrac.INK, 2.8 * k)
	else:
		b.circle(ep, 8.6 * k, BossDrac.TILE_WHITE)
		b.circle(ep + Vector2(face * 1.5, 0.0) * k, 6.2 * k * eye, EYE_AMBER)
		b.line(ep + Vector2(face * 1.5, -4.6 * eye) * k, ep + Vector2(face * 1.5, 4.6 * eye) * k, BossDrac.INK, 2.8 * k)
		b.circle(ep + Vector2(-2.5, -3.5) * k, 1.8 * k, Color.WHITE)
		# a lid of orange tile over the eye's back: a glare
		b.line(ep + Vector2(-face * 9.0, -6.0) * k, ep + Vector2(face * 6.0, -9.0) * k, BossDrac.TILE_ORANGE, 4.0 * k)
	b.flush()
	if spout > 0.0:
		_spout(c, lip, Vector2(face, 0.0).rotated(tilt * face - face * 0.35), spout * k, t)
	return lip


# one leg side on: down and out from the body to an elbow, down to a foot
# splayed flat, four toes. `l` is [x along him, front, near].
static func _leg(b: ShapeBatch, p: Callable, l: Array, hb: float, walk: float, k: float, far: bool) -> void:
	var lx: float = l[0]
	var front: bool = l[1]
	var swing := 0.0
	if walk >= 0.0:
		swing = sin(walk + (0.0 if front != far else PI)) * 14.0
	var hip: Vector2 = p.call(Vector2(lx, -hb + 2.0))
	var elbow: Vector2 = p.call(Vector2(lx + (10.0 if front else -10.0) + swing * 0.5, -hb * 0.45 - 6.0))
	var foot: Vector2 = p.call(Vector2(lx + (20.0 if front else -16.0) + swing, -3.0))
	var dark := 0.25 if far else 0.0
	var c1 := BossDrac.TILE_BLUE.darkened(dark)
	var c2 := BossDrac.TILE_CYAN.darkened(dark)
	b.capsule(hip, elbow, 8.6 * k, BossDrac.INK)
	b.capsule(elbow, foot, 7.4 * k, BossDrac.INK)
	b.capsule(hip, elbow, 6.4 * k, c1)
	b.capsule(elbow, foot, 5.4 * k, c2)
	BossDrac._shard(b, hip.lerp(elbow, 0.5), (elbow - hip).normalized(), 4.0 * k, 3.4 * k, BossDrac.TILE_YELLOW.darkened(dark), lx)
	var fwd: Vector2 = (p.call(Vector2(lx + 10.0, -3.0)) - p.call(Vector2(lx, -3.0))).normalized()
	for t2 in range(4):
		var d := fwd.rotated((float(t2) - 1.5) * 0.22 * signf(fwd.x) - 0.1 * signf(fwd.x))
		var ln := (10.0 + float(t2 % 2) * 4.0) * k
		b.capsule(foot, foot + d * ln, 3.6 * k, BossDrac.INK)
		b.capsule(foot, foot + d * ln, 2.2 * k, BossDrac.TILE_ORANGE.darkened(dark) if t2 % 2 == 0 else c1)
		b.circle(foot + d * (ln + 1.0 * k), 3.0 * k, BossDrac.TILE_YELLOW.darkened(dark))


# the jet: a rope of water out and down, breaking into drops
static func _spout(c: CanvasItem, from: Vector2, dir: Vector2, length: float, t: float) -> void:
	var pts := PackedVector2Array()
	for i in range(12):
		var u := float(i) / 11.0
		pts.append(from + dir * length * u + Vector2(0.0, u * u * length * 0.45 + sin(t * 30.0 + u * 8.0) * 2.0 * u))
	c.draw_polyline(pts, Color(WATER, 0.9), 12.0)
	c.draw_polyline(pts, Color(SPRAY, 0.95), 5.0)
	for i in range(7):
		var u := fposmod(t * 2.0 + float(i) * 0.14, 1.0)
		var w := 0.6 + u * 0.5
		var dp := from + dir * length * w + Vector2(sin(float(i) * 2.1) * 14.0, w * w * length * 0.45 + u * 30.0)
		c.draw_circle(dp, 5.0 - u * 2.0, Color(SPRAY, 1.0 - u))


# the card: his head and shoulders big from the left, jaws wide, the jet
# arcing out under the word
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(0.98, 0.94, 0.78), Color(0.22, 0.56, 0.70))
	var d := t - TITLE_AT
	var gb := ShapeBatch.new(c)
	gb.glow(Vector2(400.0, 520.0), 520.0, Color(1.0, 1.0, 0.9, 0.5))
	gb.flush()
	side(c, Vector2(-30.0 + d * 50.0, 640.0), 4.0, 1.0, t, {"eye": 1.0, "rise": 0.5, "tilt": -0.18, "curl": 1.0,
		"mouth": 1.0, "spout": 90.0 + d * 30.0, "lift": 0.5})
	FilmKit.slam(c, t, "EL DRAC!", Vector2(700, 200))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.98, 0.90))
