class_name FilmMolina
extends RefCounted

# La Molina's film, "The brake": the telegraph to run as the walk turns for
# home (systems/home_chase.gd plays it through intro/film_player.gd).
# The piste side on, in falling snow: the white Pyrenees behind, firs heavy
# with snow, the slope rising away to the left to a crest. The two of them
# walking down, your human on the phone. Up on the crest behind them the big
# red groomer sits parked, dark. A clunk: the brake. Her ears go up and she
# looks back. Its lamps blink on, two eyes under a scowling visor, the amber
# beacon starts going round, the engine coughs black, and it tips over the
# crest and comes down the slope at them, blade down, the berm of snow in
# front of it spraying, a snowball bounding on ahead. A push in on her face.
# She spins, digs in and bolts; the leash snaps taut, your human is yanked
# off after her, and RUN! slams in with the blade coming at the frame.

const Groomer := preload("res://entities/groomer_threat.gd")

const LENGTH := FilmKit.LENGTH
const BG := Color(0.66, 0.76, 0.90)
const FEET := 640.0               # the piste the pair walks on
const CREST_X := -60.0            # the crest the groomer is parked on
const CREST_Y := 380.0            # its height, where the tracks sit
const CLUNK_AT := 1.25            # the brake lets go
const LAMPS_AT := 1.75            # its eyes come on
const OUT_AT := 2.4               # it tips over the crest
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const K := 1.5                    # the machine's scale against the pair
const SNOW := Groomer.SNOW
const SNOW_SHADE := Groomer.SNOW_SHADE
const SNOW_DEEP := Groomer.SNOW_DEEP
const INK := IntroKit.INK
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[CLUNK_AT, "crack", 0.55, -3.0],
	[LAMPS_AT, "ui", 0.6, -8.0],
	[LAMPS_AT + 0.2, "diesel", 0.8, -3.0],
	[OUT_AT, "diesel", 1.0, -2.0],
	[OUT_AT + 0.4, "poof", 0.7, -5.0],
	[3.3, "diesel", 1.2, -4.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "poof", 0.5, -2.0],
]


# the camera: [centre, zoom]. On the pair; a pan back and up to the crest
# when she looks round, held as it wakes and tips over; a whip to a close-up
# of her; a cut wide on the bolt that runs right with them; the card.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 220.0, "io"], [3.9, 380.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 390.0, "io"], [3.9, 450.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.86, "io"], [3.9, 0.98, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# the slope's surface, rising to the crest on the left and running out flat
# where the pair walks
static func ground_y(x: float) -> float:
	if x >= 420.0:
		return FEET
	var f := clampf((420.0 - x) / (420.0 - CREST_X), 0.0, 1.0)
	return lerpf(FEET, CREST_Y, f * f * (3.0 - 2.0 * f))


# where the groomer's front is: parked on the crest, then down the slope
# and along the flat after them
static func groomer_x(t: float) -> float:
	return Anim.k(t, [[OUT_AT, CREST_X], [3.9, 230.0, "in"], [BOLT_AT, 330.0], [TITLE_AT, 1300.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_mountain(c, t_real)
	var gt := Anim.twos(t_real)
	var gx := groomer_x(gt)
	var slope := (ground_y(gx + 40.0) - ground_y(gx - 120.0)) / 160.0
	machine(c, Vector2(gx, ground_y(gx)), K, t_real, atan(slope), t_real >= LAMPS_AT,
		t_real >= OUT_AT, t_real >= CLUNK_AT and t_real < OUT_AT)
	if t_real >= OUT_AT + 0.3:
		var bo := Anim.span(t_real, OUT_AT + 0.3, OUT_AT + 1.2)
		var bx := lerpf(gx + 140.0, gx + 380.0, bo)
		var hop := absf(sin(t_real * 6.0)) * 40.0 * (1.0 - bo * 0.5)
		snowball(c, Vector2(bx, ground_y(bx) - 30.0 - hop), 30.0 + bo * 12.0, t_real * 5.0)
	FilmKit.pair(c, t_real, FEET)
	_flakes(c, t_real, 1.0)
	FilmKit.fades(c, t_real)


# the mountain in snow: the sky, the far white peaks, firs, the slope
static func _mountain(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1500.0), Color(0.56, 0.68, 0.86), Color(0.90, 0.93, 0.97))
	# the far Pyrenees: blue rock under white
	for k in range(14):
		var x := -1500.0 + float(k) * 340.0 + sin(float(k) * 1.7) * 80.0
		var h := 280.0 + sin(float(k) * 2.3) * 90.0
		var w := 420.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w, 600.0), Vector2(x, 600.0 - h), Vector2(x + w, 600.0)]), Color(0.60, 0.66, 0.80))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.36, 600.0 - h * 0.64), Vector2(x, 600.0 - h),
			Vector2(x + w * 0.36, 600.0 - h * 0.64), Vector2(x + w * 0.12, 600.0 - h * 0.70), Vector2(x - w * 0.10, 600.0 - h * 0.60)]),
			Color(0.95, 0.96, 0.99))
	c.draw_rect(Rect2(-1600, 560.0, 4600, 200.0), Color(0.80, 0.85, 0.94))
	# far firs along the snowfield
	for k in range(40):
		var x := -1550.0 + float(k) * 118.0 + sin(float(k) * 3.1) * 30.0
		fir(c, x, 590.0, 0.45, Color(0.40, 0.50, 0.58))
	# the slope and the piste
	var slope := PackedVector2Array()
	slope.append(Vector2(-1600, 900.0))
	slope.append(Vector2(-1600, CREST_Y))
	var x := CREST_X - 400.0
	while x <= 3000.0:
		slope.append(Vector2(x, ground_y(x) - 26.0))
		x += 40.0
	slope.append(Vector2(3000, 900.0))
	c.draw_colored_polygon(slope, SNOW)
	# the corduroy, a band along the surface
	var x2 := CREST_X - 400.0
	while x2 < 3000.0:
		c.draw_line(Vector2(x2, ground_y(x2) - 18.0), Vector2(x2 + 40.0, ground_y(x2 + 40.0) - 18.0), SNOW_SHADE, 4.0)
		x2 += 40.0
	c.draw_rect(Rect2(-1600, FEET + 20.0, 4600, 400.0), SNOW_SHADE.lerp(SNOW, 0.5))
	# near firs by the piste
	for px: float in [560.0, 1650.0, 2300.0]:
		fir(c, px, FEET - 30.0, 1.0, Groomer.SNOW_DEEP.darkened(0.6))
	fir(c, -520.0, ground_y(-520.0) - 30.0, 1.2, Groomer.SNOW_DEEP.darkened(0.6))
	# piste markers
	for k in range(20):
		var mx := -1400.0 + float(k) * 260.0
		var my := ground_y(mx) - 20.0
		c.draw_line(Vector2(mx, my), Vector2(mx, my - 90.0), Molina.MARKER_ORANGE, 7.0)
		for s in range(3):
			c.draw_line(Vector2(mx, my - 14.0 - float(s) * 24.0), Vector2(mx, my - 24.0 - float(s) * 24.0), Molina.MARKER_BLACK, 7.0)


# a fir side on: a dark spire of boughs with snow lying on each tier
static func fir(c: CanvasItem, x: float, foot: float, k: float, col: Color) -> void:
	c.draw_rect(Rect2(x - 8.0 * k, foot - 40.0 * k, 16.0 * k, 40.0 * k), Color(0.32, 0.22, 0.16))
	for s in range(4):
		var base := foot - 30.0 * k - float(s) * 62.0 * k
		var w := (110.0 - float(s) * 24.0) * k
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w, base), Vector2(x, base - 110.0 * k), Vector2(x + w, base)]), col)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.8, base - 6.0 * k), Vector2(x - w * 0.2, base - 26.0 * k),
			Vector2(x + w * 0.5, base - 8.0 * k), Vector2(x + w * 0.85, base - 2.0 * k)]), SNOW)


# snow falling across the whole frame, in front of everything
static func _flakes(c: CanvasItem, t: float, a: float) -> void:
	for i in range(70):
		var fx := fposmod(float(i) * 173.3 + t * 30.0 + sin(t * 1.3 + float(i)) * 20.0, 2600.0) - 700.0
		var fy := fposmod(float(i) * 97.1 + t * 90.0, 900.0) - 60.0
		c.draw_circle(Vector2(fx, fy), 2.0 + float(i % 3), Color(1, 1, 1, 0.8 * a))


# The groomer side on, facing right, its front track wheel's foot at `at`, at
# scale k, tilted down the slope by `tilt`: the tracks and their wheels, the
# red cab and white roof, the windscreen with nobody at the wheel, the lamps
# under a scowling visor (lit: its eyes), the beacon, the blade lowered in
# front with the berm of snow it pushes, the tiller behind. `rolling` sprays
# the berm and turns the tracks; `jolt` shudders it as the brake lets go.
# The walk's machine (entities/groomer_threat.gd) from the side; the card uses it.
static func machine(c: CanvasItem, at: Vector2, k: float, t: float, tilt: float, lit: bool, rolling: bool, jolt: bool) -> void:
	var sh := Vector2(sin(t * 60.0) * 3.0, 0.0) if jolt else Vector2.ZERO
	var xf := Transform2D(tilt, at + sh)
	var p := func(v: Vector2) -> Vector2: return xf * (v * k)
	var poly := func(pts: Array, col: Color) -> void:
		var out := PackedVector2Array()
		for v: Vector2 in pts:
			out.append(p.call(v))
		c.draw_colored_polygon(out, col)
	# the tracks: a long rounded belt, the wheels in it
	poly.call([Vector2(-230, -10), Vector2(-250, -40), Vector2(-230, -70), Vector2(20, -70), Vector2(40, -40), Vector2(20, -10)], Groomer.TRACK)
	for i in range(5):
		var wx := -210.0 + float(i) * 52.0
		c.draw_circle(p.call(Vector2(wx, -40)), 22.0 * k, Groomer.TRACK_LUG)
		c.draw_circle(p.call(Vector2(wx, -40)), 10.0 * k, Color(0.60, 0.62, 0.66))
		var a := (t * 8.0 if rolling else 0.0) + float(i)
		c.draw_line(p.call(Vector2(wx, -40)), p.call(Vector2(wx, -40) + Vector2.from_angle(a) * 18.0), Groomer.TRACK, 4.0 * k)
	# the lugs along the belt's top run
	for i in range(12):
		var lx := -225.0 + fposmod(float(i) * 21.0 + (t * 90.0 if rolling else 0.0), 245.0)
		poly.call([Vector2(lx, -76), Vector2(lx + 10, -76), Vector2(lx + 10, -68), Vector2(lx, -68)], Groomer.TRACK_LUG)
	# the tiller behind, combing corduroy
	poly.call([Vector2(-300, -30), Vector2(-250, -30), Vector2(-250, -70), Vector2(-300, -60)], Groomer.TILLER)
	if rolling:
		for j in range(4):
			var f := fposmod(t * 3.0 + float(j) * 0.25, 1.0)
			IntroKit.puff(c, p.call(Vector2(-300 - f * 60.0, -40 - f * 40.0)), (10.0 + f * 16.0) * k, 0.8 * (1.0 - f))
	# the cab: red body, white roof, glass
	poly.call([Vector2(-210, -70), Vector2(-210, -190), Vector2(-150, -210), Vector2(-10, -210), Vector2(20, -150), Vector2(20, -70)], Groomer.CAB_DARK)
	poly.call([Vector2(-200, -76), Vector2(-200, -184), Vector2(-146, -202), Vector2(-14, -202), Vector2(12, -150), Vector2(12, -76)], Groomer.CAB)
	poly.call([Vector2(-150, -210), Vector2(-10, -210), Vector2(-14, -228), Vector2(-146, -228)], Groomer.ROOF)
	poly.call([Vector2(-60, -196), Vector2(-16, -196), Vector2(6, -152), Vector2(-60, -152)], Groomer.GLASS)
	c.draw_line(p.call(Vector2(-40, -190)), p.call(Vector2(-20, -160)), Color(Groomer.GLASS_LIT, 0.7), 4.0 * k)
	# the visor: a scowl across the front over the lamps
	poly.call([Vector2(-20, -146), Vector2(30, -126), Vector2(30, -116), Vector2(-20, -132)], Groomer.CAB_DARK.darkened(0.4))
	# the lamps, its eyes
	var eye: Vector2 = p.call(Vector2(14, -108))
	if lit:
		var flick := 1.0 if t > LAMPS_AT + 0.25 or int(t * 20.0) % 2 == 0 else 0.0
		c.draw_circle(eye + Vector2(60.0, 10.0).rotated(tilt) * k, 70.0 * k, Color(1.0, 0.95, 0.70, 0.22 * flick))
		c.draw_circle(eye, 14.0 * k, Groomer.CAB_DARK.darkened(0.5))
		c.draw_circle(eye, 11.0 * k, Groomer.LAMP if flick > 0.0 else Groomer.LAMP.darkened(0.6))
		c.draw_circle(eye + Vector2(3.0, 2.0) * k, 4.0 * k, Color(0.2, 0.16, 0.10))
	else:
		c.draw_circle(eye, 14.0 * k, Groomer.CAB_DARK.darkened(0.5))
		c.draw_circle(eye, 11.0 * k, Color(0.40, 0.38, 0.32))
	# the beacon, going round once it wakes
	var bc: Vector2 = p.call(Vector2(-80, -238))
	c.draw_circle(bc, 10.0 * k, Groomer.BEACON.darkened(0.3))
	if lit:
		var ba := t * 9.0
		c.draw_circle(bc + Vector2(cos(ba) * 6.0 * k, 0.0), 8.0 * k, Groomer.BEACON.lightened(0.3))
		c.draw_circle(bc, 40.0 * k, Color(Groomer.BEACON, 0.18 + 0.12 * sin(ba)))
	# the exhaust stack, coughing black once it wakes
	poly.call([Vector2(-170, -228), Vector2(-160, -228), Vector2(-160, -270), Vector2(-170, -270)], Groomer.TRACK)
	if t >= LAMPS_AT:
		for j in range(4):
			var f := fposmod(t * 1.8 + float(j) * 0.25, 1.0)
			c.draw_circle(p.call(Vector2(-165 - f * 40.0, -280 - f * 90.0)), (10.0 + f * 24.0) * k, Color(0.16, 0.16, 0.18, 0.5 * (1.0 - f)))
	# the blade's arms and the blade, down in front, its teeth along the foot
	c.draw_line(p.call(Vector2(10, -60)), p.call(Vector2(70, -40)), Groomer.BLADE_DARK, 10.0 * k)
	poly.call([Vector2(60, 0), Vector2(70, -110), Vector2(96, -116), Vector2(90, 0)], Groomer.BLADE)
	poly.call([Vector2(70, -110), Vector2(96, -116), Vector2(100, -104), Vector2(76, -98)], Groomer.BLADE_LIT)
	for i in range(4):
		var tx := 62.0 + float(i) * 7.5
		poly.call([Vector2(tx, 0), Vector2(tx + 7.0, 0), Vector2(tx + 3.5, 10)], Groomer.TOOTH)
	# the berm in front of the blade, spraying when it rolls
	var hump := (50.0 + sin(t * 6.0) * 8.0) if rolling else 30.0
	c.draw_circle(p.call(Vector2(120, -20)), hump * k, SNOW_SHADE)
	c.draw_circle(p.call(Vector2(112, -30)), hump * 0.8 * k, SNOW)
	if rolling:
		for j in range(6):
			var f := fposmod(t * 2.6 + float(j) * 0.17, 1.0)
			c.draw_circle(p.call(Vector2(140 + f * 120.0, -60 - sin(f * PI) * 90.0)), (9.0 - f * 5.0) * k, Color(1, 1, 1, 1.0 - f))


# a snowball, turning, shared with the card
static func snowball(c: CanvasItem, at: Vector2, r: float, spin: float) -> void:
	c.draw_circle(at, r + 4.0, INK)
	c.draw_circle(at, r, SNOW_SHADE)
	c.draw_circle(at + Vector2(-0.2, -0.26) * r, r * 0.76, SNOW)
	for d in range(5):
		var a := spin + float(d) * 1.25
		c.draw_circle(at + Vector2.from_angle(a) * r * 0.55, r * 0.16, SNOW_SHADE if sin(a) > 0.0 else Color.WHITE)


# the card: the slope gone ice-bright behind RUN!, the groomer coming in from
# the left of the frame blade first, a snowball bounding ahead of it
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.86, 0.94, 1.0), Color(0.46, 0.58, 0.82))
	var d := t - TITLE_AT
	for p in range(8):
		var f := fposmod(t * 1.6 + float(p) * 0.125, 1.0)
		IntroKit.puff(c, Vector2(-60.0 + f * 220.0, 620.0 - f * 160.0 + sin(float(p) * 2.0) * 40.0), 40.0 + f * 60.0,
			0.8 * (1.0 - f))
	machine(c, Vector2(150.0 + d * 160.0, 700.0), 1.55, t, -0.06, true, true, false)
	snowball(c, Vector2(620.0 + d * 200.0, 610.0 - absf(sin(d * 8.0)) * 60.0), 62.0, t * 6.0)
	_flakes(c, t, 0.7)
	FilmKit.slam(c, t, "RUN!", Vector2(900, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(0.92, 0.96, 1.0))
