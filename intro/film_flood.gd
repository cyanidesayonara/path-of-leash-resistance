class_name FilmFlood
extends RefCounted

# El Besòs's film, "The river's up": the telegraph to run as the walk turns
# for home (systems/home_chase.gd plays it through intro/film_player.gd; the
# beats are FilmKit's). The river park at Sant Adrià under a heavy sky, the
# three chimneys on the skyline, the channel calm below the path. The first
# drops; the warning light on its pole starts flashing and the siren goes:
# her ears go up and she looks back upstream. Down the channel comes the
# surge, a wall of grey-green water with a curling white lip, spilling up
# onto the grass and carrying a branch, a traffic cone and an unbothered
# duck. A push in on her stare; she bolts, your human is yanked off after
# her, and RUN! slams in with the wave breaking over the frame.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.08, 0.10, 0.12)
const FEET := 640.0              # the grass path along the flood plain
const BANK := 700.0              # where the plain drops into the channel
const WALL_TOP := 400.0          # the embankment, low enough to show the skyline
const CREST := 170.0             # how far the surge's crest stands over the plain
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const RAIN_AT := 0.7
const DEEP := Color(0.08, 0.20, 0.28)
const WATER := Color(0.16, 0.34, 0.40)
const PALE := Color(0.62, 0.80, 0.78)
const FOAM := Color(0.93, 0.97, 0.96)
const GRASS := Color(0.42, 0.56, 0.30)
const CONCRETE := Color(0.62, 0.62, 0.60)
const INK := IntroKit.INK
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[RAIN_AT, "rustle", 0.6, -14.0],
	[FilmKit.HEAR_AT, "whistle", 0.8, -4.0],
	[2.3, "roar", 0.4, -8.0],
	[3.4, "splash", 0.6, -6.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "splash", 0.45, -2.0],
]


# the camera: on the pair; a pan back up the channel when she looks round,
# held as the surge rolls down; a whip to her stare; wide on the bolt and
# running right with them; the card square on.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 460.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.3, 220.0, "io"], [3.9, 320.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 460.0], [2.3, 450.0, "io"], [3.9, 460.0], [4.2, 510.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.3, 0.88, "io"], [3.9, 0.98, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# where the surge's leading lip is
static func surge_x(t: float) -> float:
	return Anim.k(t, [[0.0, -1500.0], [2.2, -900.0], [3.9, 180.0, "out"], [BOLT_AT, 380.0], [TITLE_AT, 1100.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var rain := Anim.span(t_real, RAIN_AT, RAIN_AT + 1.2)
	_park(c, t_real, rain)
	FilmKit.pair(c, t_real, FEET)
	_channel(c, t_real)
	_surge(c, surge_x(t_real), t_real, FEET + 18.0)
	_rain(c, t_real, rain)
	FilmKit.fades(c, t_real)


# a heavy sky, Sant Adrià's three chimneys on the skyline, the embankment
# wall at the back of the park, and the warning light on its pole
static func _park(c: CanvasItem, t: float, rain: float) -> void:
	for i in range(9):
		var f := float(i) / 8.0
		c.draw_rect(Rect2(-1800, -900.0 + f * 1340.0, 4800, 170.0),
			Color(0.46, 0.52, 0.58).lerp(Color(0.70, 0.72, 0.72), f).darkened(0.18 * rain))
	# the far shore: low blocks and the three chimneys
	var far := Color(0.52, 0.56, 0.60).darkened(0.1 * rain)
	var x := -1700.0
	var k := 0
	while x < 2900.0:
		var w := 70.0 + fmod(float(k) * 41.0, 80.0)
		var h := 30.0 + fmod(float(k) * 57.0, 70.0)
		c.draw_rect(Rect2(x, 380.0 - h, w, h + 60.0), far)
		x += w
		k += 1
	for cx: float in [1060.0, 1150.0, 1240.0]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 22.0, 420.0), Vector2(cx - 13.0, -200.0),
			Vector2(cx + 13.0, -200.0), Vector2(cx + 22.0, 420.0)]), far.darkened(0.12))
		c.draw_rect(Rect2(cx - 15.0, 200.0, 30.0, 10.0), far.lightened(0.12))
	# the embankment wall, with its rail along the top
	c.draw_rect(Rect2(-1800, WALL_TOP, 4800, FEET - 60.0 - WALL_TOP), CONCRETE)
	c.draw_rect(Rect2(-1800, WALL_TOP, 4800, 12), CONCRETE.lightened(0.15))
	for px in range(-16, 29):
		c.draw_line(Vector2(float(px) * 170.0, WALL_TOP + 12.0), Vector2(float(px) * 170.0, FEET - 60.0), CONCRETE.darkened(0.12), 3.0)
	c.draw_line(Vector2(-1800, WALL_TOP - 24.0), Vector2(3000, WALL_TOP - 24.0), INK, 3.0)
	for px in range(-36, 60):
		c.draw_line(Vector2(float(px) * 80.0, WALL_TOP - 24.0), Vector2(float(px) * 80.0, WALL_TOP), INK, 2.0)
	# the flood plain's grass and its gravel path
	c.draw_rect(Rect2(-1800, FEET - 60.0, 4800, BANK - FEET + 70.0), GRASS)
	c.draw_rect(Rect2(-1800, FEET - 22.0, 4800, 40.0), Color(0.74, 0.68, 0.56))
	for px in range(-40, 70):
		var gx := float(px) * 70.0 + fmod(float(px) * 23.0, 30.0)
		c.draw_line(Vector2(gx, FEET - 60.0), Vector2(gx + 6.0, FEET - 74.0), GRASS.darkened(0.2), 3.0)
	# the warning light: amber, flashing from when she hears the siren
	var pole := Vector2(980.0, FEET - 50.0)
	c.draw_rect(Rect2(pole.x - 5.0, pole.y - 320.0, 10.0, 320.0), INK)
	c.draw_rect(Rect2(pole.x - 36.0, pole.y - 330.0, 46.0, 34.0), Color(0.86, 0.86, 0.84))
	c.draw_colored_polygon(PackedVector2Array([pole + Vector2(10, -320), pole + Vector2(44, -336),
		pole + Vector2(44, -290), pole + Vector2(10, -306)]), Color(0.30, 0.32, 0.36))
	var on := t > FilmKit.HEAR_AT and fposmod(t * 2.4, 1.0) < 0.5
	var lamp := pole + Vector2(-13, -342)
	if on:
		c.draw_circle(lamp, 46.0, Color(1.0, 0.70, 0.15, 0.30))
	c.draw_circle(lamp, 12.0, Color(1.0, 0.72, 0.18) if on else Color(0.55, 0.42, 0.20))
	# the siren's rings off the horn
	if t > FilmKit.HEAR_AT:
		for r in range(3):
			var f := fposmod(t * 1.6 + float(r) / 3.0, 1.0)
			c.draw_arc(pole + Vector2(46, -313), 14.0 + f * 70.0, -0.7, 0.7, 10, Color(INK, 0.5 * (1.0 - f)), 3.0)


# the channel below the bank: calm, rain-pocked water and reeds
static func _channel(c: CanvasItem, t: float) -> void:
	c.draw_rect(Rect2(-1800, BANK, 4800, 18), Color(0.34, 0.40, 0.26))
	c.draw_rect(Rect2(-1800, BANK + 18.0, 4800, 500), WATER)
	for k in range(14):
		var wx := fmod(float(k) * 233.0 + t * 30.0, 4600.0) - 1800.0
		c.draw_line(Vector2(wx, BANK + 50.0 + float(k % 4) * 26.0), Vector2(wx + 60.0, BANK + 50.0 + float(k % 4) * 26.0),
			PALE.darkened(0.2), 2.0)
	for k in range(26):
		var rx := float(k) * 190.0 - 1700.0 + fmod(float(k) * 61.0, 80.0)
		var sway := sin(t * 2.0 + float(k)) * 4.0
		for j in range(3):
			c.draw_line(Vector2(rx + float(j) * 7.0, BANK + 14.0), Vector2(rx + float(j) * 9.0 + sway, BANK - 30.0 - float(j) * 8.0),
				Color(0.30, 0.42, 0.22), 3.0)


# the surge: a body of water up to `level` that rises CREST over it to a
# curling lip at x, foam along the crest and round the lip, and what it carries
static func _surge(c: CanvasItem, x: float, t: float, level: float, crest := CREST) -> void:
	if x < -1400.0:
		return
	var top := level - crest
	var pts := PackedVector2Array()
	var left := x - 2600.0
	pts.append(Vector2(left, BANK + 600.0))
	var n := 48
	for i in range(n + 1):
		var px := left + (x - left) * float(i) / float(n)
		pts.append(Vector2(px, _surface(px, x, t, level, crest)))
	# the lip curls over and hangs; the face falls away under it
	pts.append_array(PackedVector2Array([Vector2(x + 34.0, top - 16.0), Vector2(x + 84.0, top + 4.0),
		Vector2(x + 104.0, top + 46.0), Vector2(x + 84.0, top + 52.0), Vector2(x + 56.0, top + 34.0),
		Vector2(x + 52.0, top + crest * 0.45), Vector2(x + 86.0, level + 16.0), Vector2(x + 140.0, BANK + 600.0)]))
	c.draw_colored_polygon(pts, DEEP)
	# the paler, lit face under the lip
	c.draw_colored_polygon(PackedVector2Array([Vector2(x - 200.0, level - crest * 0.25), Vector2(x - 10.0, top + 24.0),
		Vector2(x + 50.0, top + 40.0), Vector2(x + 48.0, top + crest * 0.5), Vector2(x + 78.0, level + 14.0),
		Vector2(x - 200.0, level + 24.0)]), WATER)
	for k in range(4):
		var sx := x - 150.0 + float(k) * 50.0
		c.draw_line(Vector2(sx, level - crest * 0.1 - float(k) * 24.0), Vector2(sx + 40.0, level + 10.0), PALE.darkened(0.1), 3.0)
	# foam along the crest and a heap of it round the lip
	for i in range(24):
		var fx := x - 520.0 + float(i) / 23.0 * 560.0
		var near := clampf(1.0 - (x - fx) / 320.0, 0.0, 1.0)
		c.draw_circle(Vector2(fx, _surface(fx, x, t, level, crest)), 7.0 + 10.0 * near + sin(t * 9.0 + float(i)) * 2.0,
			Color(FOAM, 0.5 + 0.45 * near))
	for k in range(9):
		var a := -2.0 + float(k) * 0.42
		c.draw_circle(Vector2(x + 62.0, top + 18.0) + Vector2.from_angle(a) * 42.0, 13.0 + sin(t * 11.0 + float(k)) * 3.0, FOAM)
	# spray thrown off the lip
	for p in range(12):
		var f := fposmod(t * 2.2 + float(p) / 12.0, 1.0)
		c.draw_circle(Vector2(x + 90.0 + f * 150.0, top + 10.0 - f * 70.0 + f * f * 200.0 + sin(float(p) * 2.7) * 16.0),
			6.0 * (1.0 - f) + 1.0, Color(FOAM, 1.0 - f))
	# riding it: a branch, a traffic cone on its side, and a duck, unbothered
	var bob := sin(t * 5.0) * 5.0
	var bx := x - 330.0
	var br := Vector2(bx, _surface(bx, x, t, level, crest) - 6.0 + bob)
	c.draw_line(br + Vector2(-70, 12), br + Vector2(70, -14), Color(0.32, 0.22, 0.12), 9.0)
	c.draw_line(br + Vector2(10, -2), br + Vector2(40, -40), Color(0.32, 0.22, 0.12), 5.0)
	c.draw_circle(br + Vector2(44, -44), 12.0, Color(0.36, 0.50, 0.24))
	var cx := x - 170.0
	var cone := Vector2(cx, _surface(cx, x, t, level, crest) - 4.0 - bob)
	c.draw_colored_polygon(PackedVector2Array([cone + Vector2(-34, -14), cone + Vector2(30, -4), cone + Vector2(-34, 10)]),
		Color(0.98, 0.50, 0.10))
	c.draw_line(cone + Vector2(-14, -10), cone + Vector2(-14, 7), FOAM, 6.0)
	var dx := x - 40.0
	var duck := Vector2(dx, _surface(dx, x, t, level, crest) - 14.0 + sin(t * 4.0 + 1.0) * 4.0)
	c.draw_colored_polygon(MillieSide.ellipse(duck, Vector2(26, 13)), Color(0.50, 0.40, 0.30))
	c.draw_circle(duck + Vector2(20, -18), 11.0, Color(0.16, 0.36, 0.22))
	c.draw_colored_polygon(PackedVector2Array([duck + Vector2(29, -20), duck + Vector2(42, -16), duck + Vector2(29, -13)]),
		Color(0.96, 0.74, 0.20))
	c.draw_circle(duck + Vector2(23, -21), 2.0, INK)


# the surge's surface at px: the body's level, rising in the last stretch to
# its crest
static func _surface(px: float, x: float, t: float, level: float, crest: float) -> float:
	var near := clampf(1.0 - (x - px) / 320.0, 0.0, 1.0)
	return level - crest * near * near - sin(px * 0.02 + t * 6.0) * 6.0


# rain: streaks slanting down the frame, thickening as it sets in
static func _rain(c: CanvasItem, t: float, rain: float) -> void:
	if rain <= 0.0:
		return
	var n := int(70.0 * rain)
	for i in range(n):
		var fx := fmod(float(i) * 137.0, 4200.0) - 1500.0
		var fy := fposmod(float(i) * 89.0 + t * 900.0, 1500.0) - 500.0
		var p := Vector2(fx - fy * 0.18, fy)
		c.draw_line(p, p + Vector2(-8.0, 34.0), Color(0.86, 0.92, 0.96, 0.45), 2.0)


# the card: the wave breaking in from the left, its foam across the bottom,
# the duck still riding it
static func _title(c: CanvasItem, t: float) -> void:
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(-200, f * 720.0, 1680, 104.0), Color(0.56, 0.62, 0.66).lerp(Color(0.30, 0.38, 0.44), f))
	var d := t - TITLE_AT
	c.draw_set_transform(Vector2(-160.0 + d * 120.0, -560.0 + sin(t * 9.0) * 4.0), 0.0, Vector2(1.6, 1.6))
	_surge(c, 300.0, t, 700.0, 230.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_rain(c, t, 1.0)
	FilmKit.slam(c, t, "RUN!", Vector2(880, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
