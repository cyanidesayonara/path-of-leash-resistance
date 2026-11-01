class_name FilmSweeper
extends RefCounted

# La Neteja's film, "Here it comes": the telegraph to run as the walk turns
# for home (systems/home_chase.gd plays it through intro/film_player.gd).
# Dawn on an empty street, side on. The two of them heading home, your human
# on the phone. A rumble: her ears go up and she looks back. Round from the
# left comes the street sweeper, beacon turning, brushes whirring, a cloud of
# grit before it and the driver half asleep at the wheel. A push in on her
# face. She spins, digs in and bolts; the leash snaps taut, your human is
# yanked off after her, and RUN! slams in with the brushes filling the frame.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.10, 0.09, 0.12)
const FEET := 650.0              # the pavement the pair walks on
const ROAD := 760.0              # the road in front, where the machine runs
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const SW_K := 1.4               # the machine's scale: it should loom over them
const ORANGE := Color(0.86, 0.47, 0.09)
const ORANGE_LIT := Color(0.98, 0.63, 0.18)
const ORANGE_DARK := Color(0.52, 0.26, 0.05)
const TRIM := Color(0.95, 0.86, 0.62)
const STEEL := Color(0.21, 0.22, 0.25)
const GLASS := Color(0.24, 0.32, 0.44)
const BRISTLE := Color(0.80, 0.72, 0.34)
const INK := IntroKit.INK
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "groan", 0.45, -8.0],
	[2.30, "roar", 0.55, -10.0],
	[3.40, "grit", 0.8, -8.0],
	[4.55, "whistle", 1.3, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "crack", 0.6, -4.0],
]


# the camera: [centre, zoom]. On the pair; a pan back up the street when she
# looks round, held as the machine rolls in; a whip back to a close-up of her;
# a cut wide on the bolt that runs right with them; the title card square on.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.3, 240.0, "io"], [3.9, 330.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.3, 440.0, "io"], [3.9, 450.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.3, 0.88, "io"], [3.9, 0.98, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# where the machine's front bumper is
static func sweeper_x(t: float) -> float:
	return Anim.k(t, [[0.0, -1300.0], [2.2, -760.0], [3.9, 240.0, "out"], [BOLT_AT, 380.0], [TITLE_AT, 1000.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_street(c, t_real)
	FilmKit.pair(c, t_real, FEET)
	# the road and the machine, in front of the pavement
	_road(c)
	_sweeper_at(c, sweeper_x(t_real), t_real, SW_K)
	FilmKit.fades(c, t_real)


# dawn: the sky going from night blue to peach over a row of flats, street
# lamps still lit, every shutter down
static func _street(c: CanvasItem, t: float) -> void:
	for i in range(10):
		var f := float(i) / 9.0
		c.draw_rect(Rect2(-1600, -900.0 + f * 900.0, 4600, 92.0), Color(0.26, 0.30, 0.52).lerp(Color(0.98, 0.74, 0.56), f))
	var wall := Color(0.80, 0.62, 0.46)
	c.draw_rect(Rect2(-1600, -180, 4600, FEET - 70.0 + 180.0), wall)
	c.draw_rect(Rect2(-1600, -196, 4600, 22), wall.lightened(0.12))
	var shut := Color(0.30, 0.48, 0.38)
	var x := -1500.0
	var k := 0
	while x < 2800.0:
		for fl in range(2):
			var wy := -110.0 + float(fl) * 210.0
			var win := Rect2(x + 40.0, wy, 86, 130)
			c.draw_rect(win.grow(6.0), wall.darkened(0.14))
			c.draw_rect(win, shut)
			# one window up early, its light on
			if (k + fl) % 5 == 2:
				c.draw_rect(win.grow(-10.0), Color(1.0, 0.86, 0.52))
			c.draw_rect(Rect2(x + 22.0, wy + 130.0, 122, 9), wall.darkened(0.3))
			c.draw_line(Vector2(x + 24.0, wy + 98.0), Vector2(x + 142.0, wy + 98.0), INK, 3.0)
		# the shop shutter at street level
		c.draw_rect(Rect2(x + 20.0, 400.0, 150.0, FEET - 70.0 - 400.0), Color(0.56, 0.58, 0.60))
		for sl in range(9):
			c.draw_line(Vector2(x + 20.0, 408.0 + float(sl) * 18.0), Vector2(x + 170.0, 408.0 + float(sl) * 18.0),
				Color(0.44, 0.46, 0.48), 2.0)
		x += 230.0
		k += 1
	# street lamps, still burning
	for lx: float in [-700.0, 260.0, 1220.0, 2180.0]:
		c.draw_rect(Rect2(lx - 5.0, 140.0, 10.0, FEET - 60.0 - 140.0), INK)
		c.draw_line(Vector2(lx, 146.0), Vector2(lx + 50.0, 130.0), INK, 6.0)
		c.draw_circle(Vector2(lx + 56.0, 140.0), 34.0, Color(1.0, 0.85, 0.50, 0.25 + 0.04 * sin(t * 3.0)))
		c.draw_circle(Vector2(lx + 56.0, 140.0), 12.0, Color(1.0, 0.93, 0.70))
	# the pavement and the kerb
	c.draw_rect(Rect2(-1600, FEET - 70.0, 4600, ROAD - FEET + 40.0), Color(0.72, 0.68, 0.62))
	for px in range(-15, 30):
		c.draw_line(Vector2(float(px) * 110.0, FEET - 70.0), Vector2(float(px) * 110.0 - 30.0, ROAD - 40.0),
			Color(0.65, 0.61, 0.55), 2.0)


static func _road(c: CanvasItem) -> void:
	c.draw_rect(Rect2(-1600, ROAD - 40.0, 4600, 16), Color(0.58, 0.55, 0.50))
	c.draw_rect(Rect2(-1600, ROAD - 24.0, 4600, 400), Color(0.30, 0.30, 0.33))
	c.draw_rect(Rect2(-1600, ROAD - 24.0, 4600, 6), Color(0.22, 0.22, 0.25))


# the machine at scale k about its front wheel on the road
static func _sweeper_at(c: CanvasItem, x: float, t: float, k: float) -> void:
	var pivot := Vector2(x, ROAD + 30.0)
	c.draw_set_transform(pivot * (1.0 - k), 0.0, Vector2(k, k))
	_sweeper(c, x, t)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# the street sweeper side on, facing right, its front bumper at x: a boxy
# hopper, the cab with its sleepy driver, a turning beacon, a headlight cone
# down the road, and the round side brush out front throwing grit
static func _sweeper(c: CanvasItem, x: float, t: float) -> void:
	if x < -900.0 or x > 3000.0:
		return
	var g := ROAD + 30.0
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(x - 200.0, g + 4.0), Vector2(250, 16)), Color(0.05, 0.05, 0.07, 0.35))
	# the headlight's cone, along the road ahead of it
	var hl := Vector2(x - 16.0, g - 112.0)
	c.draw_colored_polygon(PackedVector2Array([hl, hl + Vector2(560, -70), hl + Vector2(560, 110)]),
		Color(1.0, 0.95, 0.70, 0.16))
	# the hopper and its tank
	IntroKit.box(c, Rect2(x - 430.0, g - 300.0, 280.0, 236.0), 14.0, ORANGE)
	c.draw_rect(Rect2(x - 418.0, g - 288.0, 256.0, 26.0), ORANGE_LIT)
	c.draw_rect(Rect2(x - 430.0, g - 150.0, 280.0, 22.0), TRIM)
	c.draw_rect(Rect2(x - 430.0, g - 128.0, 280.0, 8.0), ORANGE_DARK)
	for r in range(4):
		c.draw_line(Vector2(x - 400.0 + float(r) * 62.0, g - 250.0), Vector2(x - 400.0 + float(r) * 62.0, g - 168.0),
			ORANGE_DARK, 4.0)
	# the cab: glass, the driver nodding off at the wheel, the roof beacon
	IntroKit.box(c, Rect2(x - 160.0, g - 280.0, 150.0, 216.0), 18.0, ORANGE)
	c.draw_colored_polygon(IntroKit.rrect(Rect2(x - 140.0, g - 262.0, 112.0, 90.0), 10.0), GLASS)
	c.draw_colored_polygon(PackedVector2Array([Vector2(x - 120.0, g - 262.0), Vector2(x - 92.0, g - 262.0),
		Vector2(x - 128.0, g - 172.0), Vector2(x - 140.0, g - 172.0), Vector2(x - 140.0, g - 220.0)]), Color(0.60, 0.70, 0.86, 0.35))
	var nod := maxf(0.0, sin(t * 2.2)) * 10.0
	c.draw_circle(Vector2(x - 86.0, g - 210.0 + nod), 20.0, Color(0.78, 0.58, 0.44))
	c.draw_rect(Rect2(x - 108.0, g - 236.0 + nod, 46.0, 12.0), Color(0.20, 0.36, 0.30))
	c.draw_line(Vector2(x - 76.0, g - 206.0 + nod), Vector2(x - 66.0, g - 206.0 + nod), INK, 2.5)
	c.draw_rect(Rect2(x - 160.0, g - 150.0, 150.0, 22.0), TRIM)
	var spin := fposmod(t * 2.6, 1.0)
	var flash := 0.5 + 0.5 * cos(spin * TAU)
	c.draw_circle(Vector2(x - 86.0, g - 300.0), 40.0 * flash + 12.0, Color(1.0, 0.62, 0.15, 0.35 * flash))
	c.draw_rect(Rect2(x - 104.0, g - 306.0, 36.0, 24.0), Color(1.0, 0.55, 0.12).lerp(Color(1.0, 0.85, 0.45), flash))
	c.draw_rect(Rect2(x - 108.0, g - 284.0, 44.0, 6.0), INK)
	# headlight and bumper
	c.draw_circle(hl, 16.0, Color(1.0, 0.95, 0.70, 0.5))
	c.draw_circle(hl, 9.0, Color(1.0, 0.98, 0.88))
	c.draw_rect(Rect2(x - 20.0, g - 82.0, 30.0, 26.0), STEEL)
	# wheels, turning
	for wx: float in [x - 360.0, x - 210.0, x - 90.0]:
		c.draw_circle(Vector2(wx, g - 36.0), 40.0, INK)
		c.draw_circle(Vector2(wx, g - 36.0), 34.0, Color(0.14, 0.14, 0.16))
		c.draw_circle(Vector2(wx, g - 36.0), 15.0, Color(0.62, 0.62, 0.66))
		for s in range(3):
			var a := x * 0.025 + float(s) * TAU / 3.0
			c.draw_line(Vector2(wx, g - 36.0), Vector2(wx, g - 36.0) + Vector2.from_angle(a) * 14.0, STEEL, 3.0)
	# the side brush, out in front at road level, whirring
	var bc := Vector2(x + 34.0, g - 14.0)
	c.draw_line(Vector2(x - 6.0, g - 60.0), bc, STEEL, 9.0)
	for s in range(16):
		var a := -t * 22.0 + float(s) * TAU / 16.0
		var tip := bc + Vector2(cos(a) * 52.0, sin(a) * 14.0)
		c.draw_line(bc, tip, BRISTLE, 3.0)
	c.draw_colored_polygon(MillieSide.ellipse(bc, Vector2(18, 7)), STEEL)
	# grit and dust thrown up ahead of the brush
	for p in range(7):
		var f := fposmod(t * 1.8 + float(p) * 0.143, 1.0)
		var at := bc + Vector2(40.0 + f * 150.0, -f * 70.0 + sin(float(p) * 2.1) * 20.0)
		IntroKit.puff(c, at, 14.0 + f * 22.0, 1.0 - f)
	for p in range(10):
		var f := fposmod(t * 3.1 + float(p) * 0.1, 1.0)
		c.draw_circle(bc + Vector2(30.0 + f * 120.0, -f * 90.0 + f * f * 120.0) + Vector2(0, sin(float(p) * 3.3) * 8.0),
			3.0 * (1.0 - f) + 1.0, Color(0.42, 0.38, 0.30, 1.0 - f))


# the card: the street gone white-hot behind RUN!, the brushes looming in
# from the left of the frame
static func _title(c: CanvasItem, t: float) -> void:
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(-200, f * 720.0, 1680, 104.0), Color(0.99, 0.80, 0.56).lerp(Color(0.86, 0.50, 0.26), f))
	var d := t - TITLE_AT
	# its cab and brush, huge, nosing in from the bottom left
	var bob := sin(t * 18.0) * 3.0
	c.draw_set_transform(Vector2(-130.0 + d * 90.0, -980.0 + bob), 0.0, Vector2(2.1, 2.1))
	_sweeper(c, 300.0, t)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	FilmKit.slam(c, t, "RUN!", Vector2(880, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
