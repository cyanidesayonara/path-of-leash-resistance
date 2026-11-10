class_name FilmGat
extends RefCounted

# The Rambla del Raval's film, "El Gat": the finale's telegraph, played as she
# first passes his plinth (systems/boss_gat.gd), before the walk's own wake.
# Night on the rambla, side on: the palms, the terraces, the onlookers, and
# The Raval's fat bronze cat on his plinth. The two of them walk past, your
# human on the phone. A crack: her ears go up and she looks back. His eyes
# open, amber; he stretches, the plinth splits, and he drops to the paving
# with a thump that shakes the frame, the crowd gasping, and comes on down the
# rambla, tail swishing. A push in on her face. She does not run: she dashes
# back past your human and plants herself between him and the cat, hackles
# up, barking, while he is jerked to a stop still on the phone. EL GAT!
# slams in with the cat's face filling the card.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.05, 0.05, 0.10)
const FEET := 640.0
const PLINTH_X := -150.0
const PLINTH_TOP := FEET - 140.0
const EYES_AT := 2.0             # his eyes open
const CRACK_AT := 2.3            # the plinth splits as he stretches
const DROP_AT := 2.7             # he lands on the paving
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const CAT_K := 1.0
# the walk's bronze (systems/boss_gat.gd)
const BRONZE_BASE := Color(0.30, 0.24, 0.19)
const BRONZE_DARK := Color(0.17, 0.13, 0.11)
const BRONZE_LIT := Color(0.46, 0.37, 0.27)
const BRONZE_SPEC := Color(0.78, 0.64, 0.46, 0.32)
const EYE_AMBER := Color(0.96, 0.78, 0.18)
const EYE_PUPIL := Color(0.12, 0.08, 0.06)
const NOSE_DARK := Color(0.20, 0.15, 0.14)
const WHISKER_WIRE := Color(0.70, 0.64, 0.54)
const STONE := Color(0.74, 0.72, 0.68)
const STONE_DARK := Color(0.56, 0.54, 0.50)
const PANOT := Color(0.66, 0.64, 0.60)
const PALM_TRUNK := Color(0.46, 0.35, 0.25)
const PALM_LEAF := Color(0.20, 0.48, 0.24)
const INK := IntroKit.INK
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "crack", 1.1, -10.0],
	[EYES_AT, "gat_purr", 0.9, -6.0],
	[CRACK_AT, "crack", 0.7, -3.0],
	[DROP_AT, "drum", 0.45, -1.0],
	[DROP_AT + 0.05, "ooooh", 0.9, -8.0],
	[3.20, "gat_roar", 0.8, -4.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[BOLT_AT + 0.75, "bark", 1.0, -4.0],
	[TITLE_AT, "gat_clang", 0.8, -2.0],
]


# the camera: [centre, zoom]. On the pair; a pan back to the plinth when she
# looks round, held as he wakes and drops; a whip to a close-up of her; wide
# on the stand-off; the card.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 91.0), sin(t * 67.0)) * 14.0 * (1.0 - Anim.span(t, DROP_AT, DROP_AT + 0.35)) \
		if t >= DROP_AT else Vector2.ZERO
	if t >= BOLT_AT:
		return [Vector2(420.0, 440.0) + shake, Anim.k(t, [[BOLT_AT, 1.0], [TITLE_AT, 0.9, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 180.0, "io"], [3.9, 300.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 400.0, "io"], [3.9, 430.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.88, "io"], [3.9, 0.95, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y) + shake, z]


# where his feet are: on the plinth, the hop down, then stalking down the
# rambla until he looms over the stand-off
static func cat_at(t: float) -> Vector2:
	if t < CRACK_AT + 0.15:
		return Vector2(PLINTH_X, PLINTH_TOP)
	if t < DROP_AT:
		var f := Anim.span(t, CRACK_AT + 0.15, DROP_AT)
		return Vector2(lerpf(PLINTH_X, PLINTH_X + 120.0, f), lerpf(PLINTH_TOP, FEET, f * f) - sin(f * PI) * 90.0)
	return Vector2(Anim.k(t, [[DROP_AT, PLINTH_X + 120.0], [3.9, 60.0, "out"], [BOLT_AT, 40.0],
		[TITLE_AT, 30.0]]), FEET)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_rambla(c, t_real)
	_plinth(c, t)
	var awake := Anim.span(t, EYES_AT, EYES_AT + 0.2)
	var walking := t >= DROP_AT + 0.1
	var swat := Anim.span(t, BOLT_AT + 0.3, BOLT_AT + 0.6)
	cat(c, cat_at(t), CAT_K, t_real, awake, walking and t < 3.9, Anim.span(t, CRACK_AT - 0.1, CRACK_AT + 0.15), swat)
	if t >= DROP_AT and t < DROP_AT + 0.6:
		var f := Anim.span(t, DROP_AT, DROP_AT + 0.6)
		for k in range(8):
			var a := float(k) / 7.0 * PI
			IntroKit.puff(c, cat_at(t) + Vector2(cos(a) * (120.0 + f * 160.0), -sin(a) * 20.0 - 10.0), 26.0 * (1.0 - f), 1.0 - f)
	FilmKit.pair(c, t_real, FEET, true)
	FilmKit.fades(c, t_real)


# the rambla at night: the deep sky, the facades with lit windows and
# shopfronts, the palms down the middle, the onlookers at the terraces who
# jump at the thump, the panot paving
static func _rambla(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1000.0 + 130.0), Color(0.06, 0.06, 0.16), Color(0.20, 0.14, 0.24))
	var x := -1500.0
	var k := 0
	while x < 2800.0:
		var tone := Color(0.52, 0.40, 0.34).darkened(0.3 + 0.1 * float(k % 3))
		c.draw_rect(Rect2(x, -200.0 - float(k % 2) * 80.0, 300.0, FEET + 200.0), tone)
		for fl in range(3):
			for w in range(2):
				var win := Rect2(x + 50.0 + float(w) * 120.0, -120.0 + float(fl) * 150.0, 80.0, 100.0)
				c.draw_rect(win, Color(1.0, 0.80, 0.46) if (k + fl + w) % 3 != 0 else Color(0.14, 0.12, 0.18))
		c.draw_rect(Rect2(x + 30.0, 330.0, 240.0, 150.0), Color(1.0, 0.86, 0.60, 0.85) if k % 2 == 0 else Color(0.20, 0.18, 0.22))
		x += 300.0
		k += 1
	# the onlookers at the terraces, jumping at the thump
	var jump := sin(Anim.span(t, DROP_AT, DROP_AT + 0.4) * PI) * 18.0
	for i in range(14):
		var ox := -900.0 + float(i) * 190.0 + sin(float(i) * 2.1) * 40.0
		var oy := FEET - 70.0 - jump * (0.6 + 0.4 * sin(float(i)))
		var col := Color(0.12, 0.10, 0.16)
		c.draw_rect(Rect2(ox - 14.0, oy - 70.0, 28.0, 70.0), col)
		c.draw_circle(Vector2(ox, oy - 84.0), 15.0, col)
		if i % 3 == 0:
			c.draw_rect(Rect2(ox + 24.0, FEET - 110.0, 60.0, 8.0), col)
			c.draw_rect(Rect2(ox + 50.0, FEET - 110.0, 6.0, 60.0), col)
	# the palms
	for px: float in [-700.0, 520.0, 1500.0, 2400.0]:
		c.draw_line(Vector2(px, FEET - 40.0), Vector2(px + 30.0, 40.0), PALM_TRUNK, 26.0)
		for f in range(7):
			var a := -PI * 0.5 + (float(f) / 6.0 - 0.5) * 3.0 + sin(t * 1.3 + float(f)) * 0.04
			var tip := Vector2(px + 30.0, 40.0) + Vector2.from_angle(a) * 220.0 + Vector2(0, 60)
			c.draw_line(Vector2(px + 30.0, 40.0), tip, PALM_LEAF, 14.0)
	# the paving
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), PANOT)
	for px in range(-15, 30):
		c.draw_line(Vector2(float(px) * 90.0, FEET - 40.0), Vector2(float(px) * 90.0 - 40.0, FEET + 200.0),
			PANOT.darkened(0.12), 2.0)


# the plinth, splitting as he stretches
static func _plinth(c: CanvasItem, t: float) -> void:
	var r := Rect2(PLINTH_X - 200.0, PLINTH_TOP, 400.0, FEET - PLINTH_TOP + 10.0)
	c.draw_rect(r.grow(4.0), INK)
	c.draw_rect(r, STONE)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 16.0)), STONE.lightened(0.1))
	if t >= CRACK_AT:
		c.draw_polyline(PackedVector2Array([Vector2(PLINTH_X - 20.0, PLINTH_TOP), Vector2(PLINTH_X + 10.0, PLINTH_TOP + 40.0),
			Vector2(PLINTH_X - 16.0, PLINTH_TOP + 80.0), Vector2(PLINTH_X + 24.0, FEET)]), STONE_DARK.darkened(0.3), 5.0)
		c.draw_line(Vector2(PLINTH_X + 10.0, PLINTH_TOP + 40.0), Vector2(PLINTH_X + 80.0, PLINTH_TOP + 60.0),
			STONE_DARK.darkened(0.3), 4.0)
		var f := Anim.span(t, CRACK_AT, CRACK_AT + 0.5)
		if f < 1.0:
			for k in range(10):
				var a := -PI * 0.5 + (float(k) / 9.0 - 0.5) * 2.4
				c.draw_rect(Rect2(Vector2(PLINTH_X, PLINTH_TOP) + Vector2.from_angle(a) * (20.0 + f * 160.0)
					+ Vector2(0, f * f * 140.0), Vector2(10, 8)), STONE_DARK)


# The Raval's bronze cat side on, facing right, his feet at `at`: a great round bronze
# body on stubby legs, the small head with its ears and whiskers, the tail up
# in a curl. `awake` opens his amber eyes; `walking` swings the legs and the
# tail; `stretch` arches him; `swat` lifts a front paw. Shared with the card.
static func cat(c: CanvasItem, at: Vector2, k: float, t: float, awake: float, walking: bool, stretch: float,
		swat := 0.0) -> void:
	var arch := sin(stretch * PI) * 30.0
	var p := func(v: Vector2) -> Vector2: return at + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(0, 4) * k, Vector2(180, 14) * k), Color(0, 0, 0, 0.35))
	# the tail up in a curl, swishing once he is awake
	var sw := sin(t * 3.0) * 30.0 * awake
	var tail := PackedVector2Array()
	for i in range(9):
		var f := float(i) / 8.0
		tail.append(p.call(Vector2(-150.0 - f * 50.0 + sin(f * PI) * sw * 0.3, -150.0 - f * 160.0 - arch * f)
			+ Vector2(sin(f * 4.0) * 20.0 * f + sw * f, 0)))
	c.draw_polyline(tail, INK, 34.0 * k)
	c.draw_polyline(tail, BRONZE_BASE, 26.0 * k)
	# legs, the far pair darker, stubby, swinging as he walks
	for i in range(4):
		var hip: Vector2 = [Vector2(-100, -50), Vector2(70, -50), Vector2(-80, -50), Vector2(90, -50)][i]
		var swing := sin(t * 7.0 + float(i) * 1.6) * 0.4 if walking else 0.0
		var foot: Vector2 = hip + Vector2.from_angle(PI * 0.5 + swing) * 52.0
		if i == 3 and swat > 0.0:
			foot = hip + Vector2(70.0, -40.0) * swat + Vector2(0, 52) * (1.0 - swat)
		var col := BRONZE_DARK if i < 2 else BRONZE_BASE
		c.draw_line(p.call(hip), p.call(foot), INK, 40.0 * k)
		c.draw_line(p.call(hip), p.call(foot), col, 32.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot), Vector2(22, 12) * k), col)
	# the body, round as a cat who is never refused a second breakfast, its bronze sheen
	var bc := Vector2(0, -140 - arch)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(176, 118) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(170, 112) * k), BRONZE_BASE)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(-30, -40)), Vector2(110, 50) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(-60, -64)), Vector2(40, 14) * k), BRONZE_SPEC)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(10, 60)), Vector2(140, 40) * k), BRONZE_DARK)
	# the head, small on that body
	var hc := Vector2(150, -230 - arch * 0.5)
	for s: float in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([p.call(hc + Vector2(-30 + s * 14, -50)), p.call(hc + Vector2(-16 + s * 14, -96)),
			p.call(hc + Vector2(0 + s * 14, -56))]), BRONZE_DARK if s < 0.0 else BRONZE_BASE)
	c.draw_circle(p.call(hc), 72.0 * k, INK)
	c.draw_circle(p.call(hc), 67.0 * k, BRONZE_BASE)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(-14, -26)), Vector2(40, 22) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(44, 22)), Vector2(30, 22) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(68, 10)), Vector2(10, 7) * k), NOSE_DARK)
	for w in range(3):
		var wy := 18.0 + float(w) * 9.0
		c.draw_line(p.call(hc + Vector2(56, wy)), p.call(hc + Vector2(120, wy - 10.0 + float(w) * 10.0)), WHISKER_WIRE, 2.5 * k)
	# the eye: shut, a bronze lid; awake, amber with a slit, under a frown
	var eye := hc + Vector2(30, -8)
	if awake <= 0.0:
		c.draw_line(p.call(eye + Vector2(-14, 0)), p.call(eye + Vector2(14, 2)), INK, 5.0 * k)
	else:
		c.draw_circle(p.call(eye), 26.0 * k * awake, Color(1.0, 0.75, 0.2, 0.25))
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye), Vector2(15, 13 * awake) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye), Vector2(12, 10 * awake) * k), EYE_AMBER)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye + Vector2(3, 0)), Vector2(3, 9 * awake) * k), EYE_PUPIL)
		c.draw_line(p.call(eye + Vector2(-18, -20)), p.call(eye + Vector2(16, -12)), INK, 6.0 * k)


# the card: the rambla gone white-hot behind EL GAT!, his face filling the
# frame from the left, eye blazing, a paw up
static func _title(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(1.0, 0.88, 0.58), Color(0.62, 0.40, 0.26))
	var d := t - TITLE_AT
	cat(c, Vector2(-330.0 + d * 90.0, 1180.0), 2.7, t, 1.0, false, 0.0, 1.0)
	FilmKit.slam(c, t, "EL GAT!", Vector2(800, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
