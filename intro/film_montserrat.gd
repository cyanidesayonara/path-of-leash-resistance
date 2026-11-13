class_name FilmMontserrat
extends RefCounted

# Montserrat's film, "The herd": the telegraph to run as the walk turns for
# home (systems/home_chase.gd plays it through intro/film_player.gd).
# The mountain path side on, a clear morning: the serrated ridge of agulles
# behind, the monastery under it, a pine or two, the kerb and the drop. The
# two of them heading home, your human on the phone. A bleat off the rock:
# her ears go up and she looks back. On top of the crag behind them stands
# the big billy, horns against the sky. He stamps; a stone goes; and down off
# the crag comes the herd, the walk's line of goats seen side on: the billy
# huge, his horns curled right round, yellow eyes with a slot of a pupil, the
# nannies and the young ones after him, a boulder bounding ahead of them all.
# A push in on her face. She spins, digs in and bolts; the leash snaps taut,
# your human is yanked off after her, and RUN! slams in with the billy
# coming at the frame horns first.

const Goats := preload("res://entities/goat_threat.gd")

const LENGTH := FilmKit.LENGTH
const BG := Color(0.42, 0.62, 0.86)
const FEET := 640.0              # the path the pair walks on
const CRAG_X := -40.0            # the crag the herd comes down off
const CRAG_TOP := 250.0          # its top, where the billy stands
const OUT_AT := 2.3              # the stone goes and they come down
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const GOAT_K := 1.45             # the billy's scale: his back level with your human's chest
# the walk's colours (systems/montserrat.gd, entities/goat_threat.gd)
const ROCK := Montserrat.ROCK
const ROCK_LIT := Montserrat.ROCK_LIT
const ROCK_SHADE := Montserrat.ROCK_SHADE
const ROCK_DEEP := Montserrat.ROCK_DEEP
const TRAIL := Montserrat.TRAIL
const PINE := Montserrat.PINE_NEEDLE
const INK := IntroKit.INK
# the herd, as the walk's line seen side on: [x behind the billy, far, scale,
# coat (0 pale .. 1 dark), gallop phase, order off the crag]
const HERD := [
	[-330.0, true, 0.70, 0.45, 1.3, 2],
	[-180.0, true, 0.66, 0.30, 0.8, 1],
	[0.0, false, 1.0, 0.80, 0.0, 0],
	[-270.0, false, 0.50, 0.15, 2.1, 4],
	[-120.0, false, 0.52, 0.0, 0.4, 3],
]
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "bleat", 1.0, -4.0],
	[2.00, "bleat", 0.7, -4.0],
	[OUT_AT, "crack", 0.7, -5.0],
	[OUT_AT + 0.12, "bleat", 1.1, -5.0],
	[3.10, "crack", 1.0, -8.0],
	[3.60, "bleat", 1.2, -7.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "crack", 0.6, -3.0],
]


# the camera: [centre, zoom]. On the pair; a pan back and up to the crag when
# she looks round, held as the billy stamps and the herd comes down; a whip
# to a close-up of her; a cut wide on the bolt that runs right with them; the
# title card square on.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 250.0, "io"], [3.9, 360.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 400.0, "io"], [3.9, 450.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.86, "io"], [3.9, 0.98, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# where the billy's feet are; the herd runs behind him
static func billy_x(t: float) -> float:
	return Anim.k(t, [[OUT_AT, CRAG_X], [3.9, 150.0, "out"], [BOLT_AT, 240.0], [TITLE_AT, 1300.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_mountain(c)
	_crag(c, t_real)
	if t_real >= OUT_AT:
		_herd(c, Anim.twos(t_real), t_real)
	FilmKit.pair(c, t_real, FEET)
	_rail(c)
	FilmKit.fades(c, t_real)


# one agulla side on: a rounded finger of conglomerate, lit from the left,
# its beds sagging across it and the pebbles set in it
static func _needle(c: CanvasItem, x: float, foot: float, w: float, h: float, col: Color, lit: Color, detail: bool) -> void:
	var top := foot - h
	var body := PackedVector2Array()
	body.append(Vector2(x - w * 0.62, foot))
	body.append(Vector2(x - w * 0.50, top + w * 0.5))
	for i in range(9):
		var a := PI + PI * float(i) / 8.0
		body.append(Vector2(x, top + w * 0.5) + Vector2(cos(a), sin(a)) * w * 0.5)
	body.append(Vector2(x + w * 0.50, top + w * 0.5))
	body.append(Vector2(x + w * 0.66, foot))
	c.draw_colored_polygon(body, col)
	# the lit side
	var side := PackedVector2Array()
	side.append(Vector2(x - w * 0.62, foot))
	side.append(Vector2(x - w * 0.50, top + w * 0.5))
	for i in range(5):
		var a := PI + PI * 0.5 * float(i) / 4.0
		side.append(Vector2(x, top + w * 0.5) + Vector2(cos(a), sin(a)) * w * 0.5)
	side.append(Vector2(x - w * 0.12, top + w * 0.3))
	side.append(Vector2(x - w * 0.20, foot))
	c.draw_colored_polygon(side, lit)
	if not detail:
		return
	var n := int(h / 46.0)
	for i in range(n):
		var y := top + w * 0.5 + float(i) * 46.0 + sin(x + float(i)) * 8.0
		c.draw_polyline(PackedVector2Array([Vector2(x - w * 0.52, y), Vector2(x - w * 0.1, y + 9.0), Vector2(x + w * 0.54, y - 2.0)]),
			Color(ROCK_DEEP, 0.45), 2.5)
		for p in range(3):
			var px := x + (fposmod(sin(x * 0.7 + float(i * 3 + p)) * 43.7, 1.0) - 0.5) * w * 0.8
			c.draw_circle(Vector2(px, y + 16.0 + float(p) * 7.0), 3.0 + float(p), Montserrat.PEBBLES[(i + p) % 5])


# the morning on the mountain: the sky, the far serrated ridge in its haze,
# the nearer needles with the monastery under them, the pines, the path
static func _mountain(c: CanvasItem) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1500.0), Color(0.36, 0.60, 0.88), Color(0.88, 0.93, 0.96))
	# the far ridge: the saw the mountain is named for
	var haze := Color(0.70, 0.74, 0.84)
	for k in range(34):
		var x := -1560.0 + float(k) * 132.0
		var h := 250.0 + sin(float(k) * 1.9) * 70.0 + sin(float(k) * 0.6) * 60.0
		_needle(c, x, 620.0, 150.0, h, haze, haze.lightened(0.14), false)
	c.draw_rect(Rect2(-1600, 470.0, 4600, 200.0), haze)
	# the nearer needles
	for k in range(15):
		var x := -1500.0 + float(k) * 300.0 + sin(float(k) * 2.3) * 60.0
		if absf(x - 1260.0) < 230.0:
			continue
		var h := 330.0 + sin(float(k) * 1.3) * 90.0
		_needle(c, x + 150.0, 620.0, 190.0, h * 0.8, ROCK_SHADE.lerp(haze, 0.35), ROCK.lerp(haze, 0.25), false)
		_needle(c, x, 620.0, 230.0, h, ROCK.lerp(haze, 0.12), ROCK_LIT.lerp(haze, 0.08), true)
	# the monastery under them: a long stone block, its roof, its rows of windows
	c.draw_rect(Rect2(1040.0, 380.0, 440.0, 240.0), Montserrat.MONASTERY_WALL.darkened(0.06))
	c.draw_rect(Rect2(1040.0, 380.0, 150.0, 240.0), Montserrat.MONASTERY_WALL)
	c.draw_colored_polygon(PackedVector2Array([Vector2(1026.0, 384.0), Vector2(1060.0, 350.0), Vector2(1460.0, 350.0), Vector2(1494.0, 384.0)]),
		Montserrat.MONASTERY_ROOF)
	for row in range(3):
		for col in range(9):
			var wp := Vector2(1070.0 + float(col) * 46.0, 420.0 + float(row) * 62.0)
			c.draw_rect(Rect2(wp.x - 8.0, wp.y, 16.0, 26.0), Color(0.20, 0.17, 0.18))
			c.draw_circle(Vector2(wp.x, wp.y), 8.0, Color(0.20, 0.17, 0.18))
	# pines by the path
	for px: float in [520.0, 1700.0, 2350.0]:
		_pine(c, px, FEET - 36.0, 1.0)
	_pine(c, -640.0, FEET - 36.0, 1.2)
	# the path: its kerb of set stones behind, the worn stone, a step now and then
	c.draw_rect(Rect2(-1600, FEET - 44.0, 4600, 14.0), Montserrat.KERB)
	c.draw_rect(Rect2(-1600, FEET - 32.0, 4600, 6.0), Montserrat.KERB.darkened(0.25))
	for k in range(70):
		c.draw_line(Vector2(-1580.0 + float(k) * 66.0, FEET - 44.0), Vector2(-1580.0 + float(k) * 66.0, FEET - 30.0),
			Color(ROCK_DEEP, 0.5), 2.0)
	c.draw_rect(Rect2(-1600, FEET - 26.0, 4600, 600.0), TRAIL)
	c.draw_line(Vector2(-1600, FEET + 30.0), Vector2(3000, FEET + 30.0), Montserrat.TRAIL_DARK, 5.0)
	c.draw_line(Vector2(-1600, FEET + 74.0), Vector2(3000, FEET + 74.0), Montserrat.TRAIL_DARK, 4.0)
	for k in range(60):
		var lx := -1500.0 + float(k) * 73.0
		var ly := FEET - 14.0 + fposmod(float(k) * 37.0, 100.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(lx, ly), Vector2(8, 3.5)), Montserrat.PEBBLES[k % 5].lerp(TRAIL, 0.3))


# a mountain pine side on: a leaning trunk and flat shelves of needles
static func _pine(c: CanvasItem, x: float, foot: float, k: float) -> void:
	c.draw_colored_polygon(PackedVector2Array([Vector2(x - 11.0 * k, foot), Vector2(x + 11.0 * k, foot),
		Vector2(x + 24.0 * k, foot - 250.0 * k), Vector2(x + 12.0 * k, foot - 250.0 * k)]), Montserrat.PINE_TRUNK.darkened(0.15))
	for s in range(4):
		var cy := foot - 200.0 * k - float(s) * 46.0 * k
		var cw := (150.0 - float(s) * 26.0) * k
		var cx := x + 16.0 * k + sin(float(s) * 2.0 + x) * 18.0 * k
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx, cy + 8.0 * k), Vector2(cw, 30.0 * k)), PINE.darkened(0.3))
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx - 6.0 * k, cy), Vector2(cw * 0.94, 26.0 * k)), PINE)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx - 22.0 * k, cy - 8.0 * k), Vector2(cw * 0.6, 13.0 * k)), Montserrat.PINE_LIT)


# the crag behind them, and the billy on top of it against the sky until the
# herd comes down: he climbs into view at the bleat, and stamps a stone loose
static func _crag(c: CanvasItem, t: float) -> void:
	_needle(c, CRAG_X - 250.0, FEET - 26.0, 260.0, 470.0, ROCK_SHADE, ROCK, true)
	if t >= FilmKit.HEAR_AT - 0.25 and t < OUT_AT + 0.12:
		var up := Anim.span(t, FilmKit.HEAR_AT - 0.25, FilmKit.HEAR_AT)
		var stamp := absf(sin(maxf(t - 1.9, 0.0) * 16.0)) * 10.0 * Anim.span(t, 1.9, 2.0)
		goat(c, Vector2(CRAG_X - 40.0, CRAG_TOP + 4.0 + (1.0 - up) * 150.0 - stamp), GOAT_K * 0.9, t, 0.8, true, 0.0)
	_needle(c, CRAG_X - 30.0, FEET - 26.0, 300.0, FEET - 26.0 - CRAG_TOP, ROCK, ROCK_LIT, true)
	# broom and rosemary on its ledges
	for k in range(4):
		var bp := Vector2(CRAG_X - 160.0 + float(k) * 82.0, FEET - 60.0 - float(k % 2) * 16.0)
		c.draw_circle(bp, 34.0, Montserrat.SCRUB.darkened(0.2))
		c.draw_circle(bp + Vector2(-10, -12), 22.0, Montserrat.SCRUB)
		c.draw_circle(bp + Vector2(8, -18), 5.0, Montserrat.BROOM if k % 2 == 0 else Montserrat.BLOSSOM)
	# the stone he stamps loose, and the grit that goes with it
	var go := Anim.span(t, OUT_AT - 0.3, OUT_AT + 0.5)
	if go > 0.0 and go < 1.0:
		for p in range(8):
			var a := -PI * 0.5 + (float(p) / 7.0 - 0.5) * 2.2
			var at := Vector2(CRAG_X + 60.0, CRAG_TOP + 20.0) + Vector2.from_angle(a) * (20.0 + go * 150.0) + Vector2(0, go * go * 330.0)
			c.draw_circle(at, 7.0 - float(p % 3) * 2.0, Montserrat.PEBBLES[p % 5])


# the herd coming down off the crag and along the path at a gallop, the far
# rank a step smaller and higher, each one down in its turn, the boulder
# bounding on ahead of them
static func _herd(c: CanvasItem, t: float, t_real: float) -> void:
	var bx := billy_x(t)
	for st: Array in HERD:
		var out := Anim.span(t, OUT_AT + float(st[5]) * 0.12, OUT_AT + float(st[5]) * 0.12 + 0.34)
		if out <= 0.0:
			continue
		var far: bool = st[1]
		var k := GOAT_K * float(st[2]) * (0.9 if far else 1.0)
		var feet := FEET - (22.0 if far else 0.0)
		var x := lerpf(CRAG_X, bx + float(st[0]), out)
		# the leap down: off the top, an arc, onto the path
		var y := lerpf(CRAG_TOP, feet, out * out) - sin(out * PI) * 70.0
		if out >= 1.0:
			for p in range(4):
				var f := fposmod(t_real * 2.4 + float(p) * 0.25 + float(st[4]), 1.0)
				IntroKit.puff(c, Vector2(x - 110.0 * k - f * 120.0, feet - 10.0 - f * 50.0), (13.0 + f * 20.0) * k, 0.7 * (1.0 - f))
		goat(c, Vector2(x, y), k, t_real + float(st[4]), float(st[3]), float(st[2]) >= 1.0, 1.0)
	# the boulder, ahead of the billy, bouncing
	var bo := Anim.span(t, OUT_AT + 0.1, OUT_AT + 0.5)
	if bo > 0.0:
		var rx := lerpf(CRAG_X + 80.0, bx + 250.0, bo)
		var hop := absf(sin(t_real * 7.0))
		var ry := lerpf(CRAG_TOP + 60.0, FEET - 52.0, bo * bo) - hop * 90.0 * bo
		boulder(c, Vector2(rx, ry), 52.0, t_real * 6.0)
		if hop < 0.25 and bo >= 1.0:
			IntroKit.puff(c, Vector2(rx - 30.0, FEET - 12.0), 30.0, 0.8)


# a boulder of the mountain's rock, turning: shared with the card
static func boulder(c: CanvasItem, at: Vector2, r: float, spin: float) -> void:
	c.draw_circle(at, r + 4.0, INK)
	c.draw_circle(at, r, ROCK)
	c.draw_circle(at + Vector2(-0.2, -0.26) * r, r * 0.72, ROCK_LIT)
	for d in range(8):
		var a := spin + float(d) * 0.8
		var pd := r * (0.28 + 0.5 * fposmod(float(d) * 0.37, 1.0))
		c.draw_circle(at + Vector2.from_angle(a) * pd, r * (0.07 + 0.03 * float(d % 3)), Montserrat.PEBBLES[d % 5])


# a wild goat side on, facing right, its feet at `at`, at scale k: the shaggy
# barrel and its dark spine, thin legs at a gallop (run 0 stands it still),
# the scut up, the long face down to a pale muzzle and a beard, a yellow eye
# with a slot of a pupil under a scowl, and the horn curled right round on
# itself. `billy` is the big one: darker beard, heavier horn. The walk's
# animal (entities/goat_threat.gd) from the side; shared with the card.
static func goat(c: CanvasItem, at: Vector2, k: float, t: float, tone: float, billy: bool, run: float) -> void:
	var fur: Color = Goats.GOAT_FUR.lerp(Goats.GOAT_DARK, tone)
	var bob := absf(sin(t * 9.0)) * 8.0 * k * run
	var o := at - Vector2(0.0, bob)
	var p := func(v: Vector2) -> Vector2: return o + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(0, 2) * k, Vector2(96, 9) * k), Color(0.05, 0.04, 0.06, 0.30))
	# legs, the far pair first: thin, knobbly, black to the knee
	for i in range(4):
		var hip: Vector2 = [Vector2(-58, -52), Vector2(46, -52), Vector2(-42, -52), Vector2(62, -52)][i]
		var swing := sin(t * 18.0 + float(i) * 1.6) * 0.7 * run
		var knee: Vector2 = hip + Vector2.from_angle(PI * 0.5 + swing) * 28.0
		var foot: Vector2 = knee + Vector2.from_angle(PI * 0.5 + swing * 0.4 - 0.15 * run) * 28.0
		var col := fur.darkened(0.3) if i < 2 else fur
		c.draw_line(p.call(hip), p.call(knee), INK, 13.0 * k)
		c.draw_line(p.call(knee), p.call(foot), INK, 10.0 * k)
		c.draw_line(p.call(hip), p.call(knee), col, 8.5 * k)
		c.draw_circle(p.call(foot), 5.5 * k, INK)
	# the scut
	var flick := sin(t * 14.0) * 5.0 * run
	c.draw_line(p.call(Vector2(-88, -96)), p.call(Vector2(-102, -116 + flick)), INK, 11.0 * k)
	c.draw_line(p.call(Vector2(-88, -96)), p.call(Vector2(-101, -114 + flick)), Goats.GOAT_BELLY, 5.0 * k)
	# the barrel, the shoulders over it, the shag hanging under
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-6, -84)), Vector2(92, 44) * k), INK)
	for s in range(8):
		var sx := -72.0 + float(s) * 18.0
		c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(sx, -52)), p.call(Vector2(sx + 9, -34 - float(s % 2) * 6.0)),
			p.call(Vector2(sx + 18, -52))]), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-6, -84)), Vector2(87, 39) * k), fur)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(40, -98)), Vector2(52, 38) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(40, -98)), Vector2(47, 33) * k), fur)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-8, -66)), Vector2(64, 15) * k), Goats.GOAT_BELLY.lerp(fur, 0.45))
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-10, -116)), Vector2(74, 9) * k), Goats.GOAT_DARK.darkened(0.35))
	# the neck up to the head, the long face, the ear
	c.draw_line(p.call(Vector2(66, -108)), p.call(Vector2(96, -140)), INK, 46.0 * k)
	c.draw_line(p.call(Vector2(66, -108)), p.call(Vector2(96, -140)), fur, 37.0 * k)
	var head := PackedVector2Array()
	for v: Vector2 in [Vector2(78, -166), Vector2(112, -164), Vector2(152, -134), Vector2(158, -118), Vector2(140, -110),
			Vector2(98, -122), Vector2(80, -138)]:
		head.append(p.call(v))
	c.draw_colored_polygon(head, fur)
	head.append(head[0])
	c.draw_polyline(head, INK, 4.5 * k)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(148, -122)), Vector2(12, 10) * k), Goats.GOAT_BELLY)
	c.draw_circle(p.call(Vector2(154, -126)), 2.2 * k, INK)
	c.draw_line(p.call(Vector2(140, -112)), p.call(Vector2(154, -114)), INK, 2.5 * k)
	c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(84, -150)), p.call(Vector2(58, -146)),
		p.call(Vector2(82, -138))]), fur.darkened(0.2))
	# the beard, streaming
	c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(126, -112)), p.call(Vector2(142, -110)),
		p.call(Vector2(120 - 10.0 * run, -76 + flick))]), Goats.GOAT_DARK.darkened(0.3) if billy else Goats.GOAT_BELLY.darkened(0.12))
	# the horn: up off the brow, back, down and round to a point by the jaw
	var hk := 1.3 if billy else 1.0
	var centre := Vector2(84.0, -158.0) + Vector2(-20.0, 4.0) * hk
	var pts := PackedVector2Array()
	var n := 14
	for i in range(n + 1):
		var f := float(i) / float(n)
		var a := -0.35 - f * PI * 1.7
		pts.append(p.call(centre + Vector2.from_angle(a) * (30.0 - f * 15.0) * hk))
	for i in range(n):
		c.draw_line(pts[i], pts[i + 1], INK, (17.0 - float(i) * 0.85) * hk * k)
		c.draw_circle(pts[i + 1], (17.0 - float(i) * 0.85) * hk * k * 0.5, INK)
	for i in range(n):
		var w := (11.5 - float(i) * 0.72) * hk * k
		var col: Color = Goats.GOAT_HORN.lerp(Goats.GOAT_HORN_TIP, float(i) / float(n))
		c.draw_line(pts[i], pts[i + 1], col, w)
		c.draw_circle(pts[i + 1], w * 0.5, col)
		if i % 2 == 0 and i < n - 2:
			var dir := (pts[i + 1] - pts[i]).normalized().orthogonal()
			c.draw_line(pts[i + 1] - dir * w * 0.5, pts[i + 1] + dir * w * 0.5, Goats.GOAT_HORN_RIDGE, 2.0 * k)
	# the eye under its scowl
	c.draw_circle(p.call(Vector2(118, -146)), 8.0 * k, INK)
	c.draw_circle(p.call(Vector2(118, -146)), 6.0 * k, Goats.GOAT_EYE)
	c.draw_line(p.call(Vector2(113, -146)), p.call(Vector2(123, -146)), INK, 3.0 * k)
	c.draw_line(p.call(Vector2(102, -160)), p.call(Vector2(132, -150)), INK, 6.5 * k)
	# a snort off the nose
	var sn := fposmod(t * 2.0, 1.0)
	if sn < 0.5 and run > 0.0:
		IntroKit.puff(c, p.call(Vector2(172 + sn * 60.0, -124 - sn * 26.0)), (7.0 + sn * 18.0) * k, 1.0 - sn * 2.0)


# the iron rail along the drop, in front of everything: posts and a top bar
static func _rail(c: CanvasItem) -> void:
	c.draw_line(Vector2(-1600, FEET + 44.0), Vector2(3000, FEET + 44.0), Color(0.14, 0.14, 0.17), 7.0)
	for k in range(34):
		var x := -1560.0 + float(k) * 140.0
		c.draw_rect(Rect2(x - 5.0, FEET + 40.0, 10.0, 120.0), Color(0.14, 0.14, 0.17))


# the card: the mountain gone white-hot behind RUN!, the billy coming in from
# the left of the frame horns first, his boulder bounding ahead of him
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.99, 0.90, 0.80), Color(0.72, 0.52, 0.48))
	var d := t - TITLE_AT
	for k in range(7):
		_needle(c, -120.0 + float(k) * 250.0, 760.0, 210.0, 300.0 + sin(float(k) * 1.7) * 90.0,
			Color(0.80, 0.62, 0.58, 0.55), Color(0.90, 0.74, 0.68, 0.55), false)
	for p in range(8):
		var f := fposmod(t * 1.6 + float(p) * 0.125, 1.0)
		IntroKit.puff(c, Vector2(-80.0 + f * 200.0, 640.0 - f * 160.0 + sin(float(p) * 2.0) * 40.0), 40.0 + f * 60.0,
			0.8 * (1.0 - f))
	goat(c, Vector2(-80.0 + d * 150.0, 716.0), 2.5, t, 0.8, true, 1.0)
	boulder(c, Vector2(470.0 + d * 190.0, 600.0 - absf(sin(d * 8.0)) * 60.0), 64.0, t * 6.0)
	FilmKit.slam(c, t, "RUN!", Vector2(900, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
