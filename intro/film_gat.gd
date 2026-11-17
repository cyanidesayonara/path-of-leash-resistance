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
		[4.2, 400.0, "io"], [BOLT_AT, 440.0]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 400.0, "io"], [3.9, 430.0], [4.2, 480.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.88, "io"], [3.9, 0.95, "io"], [4.2, 1.14, "io"], [BOLT_AT, 1.22]])
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
	var hiss := Anim.span(t, DROP_AT + 0.15, DROP_AT + 0.5)
	cat(c, cat_at(t), CAT_K, t_real, awake, walking and t < 3.9, Anim.span(t, CRACK_AT - 0.1, CRACK_AT + 0.15), swat, hiss)
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


# The Raval's bronze cat side on, facing right, his feet at `at`: a heavy old
# tomcat of our own, not anyone's sculpture, swollen to a monument's volume
# with a small smug head on top. A deep chest, the belly hanging,
# a big round haunch over the hind legs, chunky
# forelegs, a thick tail; a broad head with a tom's jowls, whisker pads, a
# nose, ears with their dark insides; all of it cast bronze with the sheen
# rubbed bright where people touch him. `awake` opens his almond eyes;
# `walking` swings the legs and the tail; `stretch` arches him; `swat` lifts
# a front paw, claws out; `hiss` is his threat display: ears pinned back,
# hackles up along his spine, the tail bottle-brushed, the mouth open on his
# fangs. Shared with the card.
static func cat(c: CanvasItem, at: Vector2, k: float, t: float, awake: float, walking: bool, stretch: float,
		swat := 0.0, hiss := 0.0) -> void:
	var arch := sin(stretch * PI) * 30.0 + 16.0 * hiss
	var p := func(v: Vector2) -> Vector2: return at + v * k
	# the upper body rises as he arches; the feet stay down
	var up := func(v: Vector2) -> Vector2: return at + (v + Vector2(0, -arch * clampf(-v.y / 160.0, 0.0, 1.0))) * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(10, 4) * k, Vector2(190, 14) * k), Color(0, 0, 0, 0.35))
	# the tail: thick, up and curling over at its tip; swishing awake, a
	# bottle-brush hissing
	var sw := sin(t * 3.0) * 26.0 * awake
	var tail := PackedVector2Array()
	for i in range(10):
		var f := float(i) / 9.0
		tail.append(up.call(Vector2(-150.0 - f * 70.0 + sin(f * PI) * sw * 0.3 + f * f * 40.0 + sw * f * 0.6,
			-150.0 - f * 170.0 + f * f * 40.0)))
	var tw := 34.0 + 16.0 * hiss
	# hissing, the fur along it puffs out: tufts either side, inked and filled
	var tufts: Array[Vector2] = []
	var tuft_r: Array[float] = []
	if hiss > 0.0:
		for i in range(1, 10):
			var dv := (tail[i] - tail[i - 1]).normalized().orthogonal()
			for sgn: float in [-1.0, 1.0]:
				tufts.append(tail[i] + dv * sgn * (tw * 0.42 + float((i * 3) % 4) * 2.0) * k * hiss)
				tuft_r.append((10.0 + float((i + int(sgn)) % 3) * 3.0) * k * hiss)
	for i in range(tufts.size()):
		c.draw_circle(tufts[i], tuft_r[i] + 4.0 * k, INK)
	for i in range(9):
		var w := lerpf(tw, tw * 0.7, float(i) / 8.0)
		c.draw_line(tail[i], tail[i + 1], INK, (w + 8.0) * k)
		c.draw_circle(tail[i + 1], (w + 8.0) * 0.5 * k, INK)
	for i in range(9):
		var w := lerpf(tw, tw * 0.7, float(i) / 8.0)
		c.draw_line(tail[i], tail[i + 1], BRONZE_BASE, w * k)
		c.draw_circle(tail[i + 1], w * 0.5 * k, BRONZE_BASE)
	for i in range(tufts.size()):
		c.draw_circle(tufts[i], tuft_r[i], BRONZE_BASE)
	c.draw_line(tail[2], tail[7], BRONZE_LIT, 6.0 * k)
	# the far legs, darker
	var stride := sin(t * 7.0) * 14.0 if walking else 0.0
	_cat_leg(c, p, up, Vector2(70, -90), Vector2(70 - stride, 0), k, BRONZE_DARK, 0.0)
	_cat_leg(c, p, up, Vector2(-70, -96), Vector2(-62 + stride, 0), k, BRONZE_DARK, 0.0)
	# the body, inked as one mass and then filled: rump, barrel, chest, the
	# belly hanging under them
	var parts := [[Vector2(-110, -150), Vector2(96, 96)], [Vector2(-10, -176), Vector2(178, 126)],
		[Vector2(100, -168), Vector2(84, 98)], [Vector2(0, -92), Vector2(150, 52)]]
	for pt: Array in parts:
		c.draw_colored_polygon(MillieSide.ellipse(up.call(pt[0]), (pt[1] + Vector2(6, 6)) * k), INK)
	for pt: Array in parts:
		c.draw_colored_polygon(MillieSide.ellipse(up.call(pt[0]), pt[1] * k), BRONZE_BASE)
	# the belly in shade, the back catching the light, the sheen rubbed bright
	c.draw_colored_polygon(MillieSide.ellipse(up.call(Vector2(0, -92)), Vector2(136, 40) * k), BRONZE_DARK)
	c.draw_colored_polygon(MillieSide.ellipse(up.call(Vector2(-30, -250)), Vector2(130, 40) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(up.call(Vector2(-60, -270)), Vector2(56, 12) * k), BRONZE_SPEC)
	# the haunch: a great round thigh over the hind leg
	# (no outline of its own: it is part of him, shaped by a crease along its front)
	c.draw_colored_polygon(MillieSide.ellipse(up.call(Vector2(-110, -134)), Vector2(40, 24) * k), BRONZE_LIT)
	var crease := PackedVector2Array()
	for i in range(8):
		var a := PI * (-0.35 + 0.75 * float(i) / 7.0)
		crease.append(up.call(Vector2(-96, -110) + Vector2(cos(a) * 60.0, sin(a) * 56.0)))
	c.draw_polyline(crease, BRONZE_DARK, 6.0 * k)
	# the near hind leg, down out of the haunch, stepping opposite the foreleg
	_cat_leg(c, p, up, Vector2(-100, -80), Vector2(-106 - stride, 0), k, BRONZE_BASE, 0.0)
	if hiss > 0.0:
		# hackles: a ridge of spiked fur along his back
		for h in range(12):
			var a := PI * (1.12 + 0.07 * float(h))
			var rim := Vector2(-10, -176) + Vector2(cos(a) * 172.0, sin(a) * 122.0)
			var out := Vector2(cos(a) * 0.5, sin(a)).normalized()
			var ln := (20.0 + float(h % 3) * 8.0) * hiss
			var sd := out.orthogonal() * 9.0
			c.draw_colored_polygon(PackedVector2Array([up.call(rim - sd * 1.4 - out * 6.0), up.call(rim + out * (ln + 5.0)),
				up.call(rim + sd * 1.4 - out * 6.0)]), INK)
			c.draw_colored_polygon(PackedVector2Array([up.call(rim - sd - out * 6.0), up.call(rim + out * ln),
				up.call(rim + sd - out * 6.0)]), BRONZE_BASE)
	# the near foreleg; swatting, it comes up and forward with the claws out
	var paw := Vector2(110 + stride, 0)
	if swat > 0.0:
		paw = paw.lerp(Vector2(210, -120), swat)
	_cat_leg(c, p, up, Vector2(104, -96), paw, k, BRONZE_BASE, swat)
	# the head: a tom's jowls and a smug face
	# small on that bulk, as such statues' heads are
	var hc := Vector2(176, -268)
	var hs := 0.8
	var kh := k * hs
	var hp := func(v: Vector2) -> Vector2: return up.call(hc + v * hs)
	for s: float in [-1.0, 1.0]:
		# the ears: up, with their dark insides; hissing, pinned flat back
		var bx := 140.0 if s < 0.0 else 182.0
		var tip := Vector2(bx - 14.0, -350.0).lerp(Vector2(bx - 74.0, -298.0), hiss)
		var ear := PackedVector2Array([hp.call(Vector2(-168, 246) + Vector2(bx - 34.0, -290.0)), hp.call(Vector2(-168, 246) + tip), hp.call(Vector2(-168, 246) + Vector2(bx + 12.0, -300.0))])
		var col := BRONZE_DARK if s < 0.0 else BRONZE_BASE
		var ear_ink := PackedVector2Array([hp.call(Vector2(-168, 246) + Vector2(bx - 40.0, -286.0)), hp.call(Vector2(-168, 246) + tip + Vector2(-2, -7)),
			hp.call(Vector2(-168, 246) + Vector2(bx + 18.0, -298.0))])
		c.draw_colored_polygon(ear_ink, INK)
		c.draw_colored_polygon(ear, col)
		c.draw_colored_polygon(PackedVector2Array([hp.call(Vector2(-168, 246) + Vector2(bx - 24.0, -294.0)), hp.call(Vector2(-168, 246) + tip.lerp(Vector2(bx - 10.0, -300.0), 0.25)),
			hp.call(Vector2(-168, 246) + Vector2(bx + 2.0, -300.0))]), BRONZE_DARK.darkened(0.25))
	c.draw_circle(hp.call(Vector2.ZERO), 72.0 * kh, INK)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(10, 30)), Vector2(84, 52) * kh), INK)
	c.draw_circle(hp.call(Vector2.ZERO), 66.0 * kh, BRONZE_BASE)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(10, 30)), Vector2(78, 46) * kh), BRONZE_BASE)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(-12, -36)), Vector2(40, 20) * kh), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(-20, -44)), Vector2(16, 6) * kh), BRONZE_SPEC)
	# the muzzle: whisker pads, the nose, the chin
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(58, 26)), Vector2(34, 26) * kh), INK)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(58, 26)), Vector2(30, 22) * kh), BRONZE_LIT)
	c.draw_circle(hp.call(Vector2(52, 30)), 13.0 * kh, BRONZE_LIT.lightened(0.06))
	c.draw_circle(hp.call(Vector2(72, 28)), 11.0 * kh, BRONZE_LIT.lightened(0.06))
	for wp in range(3):
		c.draw_circle(hp.call(Vector2(50.0 + float(wp) * 8.0, 28.0 + float(wp % 2) * 6.0)), 1.8 * kh, BRONZE_DARK)
	c.draw_colored_polygon(PackedVector2Array([hp.call(Vector2(76, 6)), hp.call(Vector2(92, 8)),
		hp.call(Vector2(86, 18))]), NOSE_DARK)
	if hiss > 0.0:
		# the hiss: the jaw dropped open under the muzzle, fangs top and bottom
		var gape := 28.0 * hiss
		var mouth := PackedVector2Array([hp.call(Vector2(38, 44)), hp.call(Vector2(84, 36)),
			hp.call(Vector2(78, 46 + gape)), hp.call(Vector2(44, 52 + gape * 0.7))])
		c.draw_colored_polygon(mouth, Color(0.36, 0.10, 0.12))
		c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(60, 48 + gape * 0.8)), Vector2(16, 6) * kh), Color(0.86, 0.42, 0.48))
		mouth.append(mouth[0])
		c.draw_polyline(mouth, INK, 4.0 * kh)
		for fx: float in [52.0, 74.0]:
			c.draw_colored_polygon(PackedVector2Array([hp.call(Vector2(fx - 4, 40)), hp.call(Vector2(fx, 40 + 15.0 * hiss)),
				hp.call(Vector2(fx + 4, 39))]), Color(0.97, 0.95, 0.88))
			c.draw_colored_polygon(PackedVector2Array([hp.call(Vector2(fx - 6, 48 + gape)), hp.call(Vector2(fx - 2, 36 + gape)),
				hp.call(Vector2(fx + 2, 48 + gape))]), Color(0.97, 0.95, 0.88))
	else:
		c.draw_polyline(PackedVector2Array([hp.call(Vector2(84, 20)), hp.call(Vector2(80, 36)),
			hp.call(Vector2(64, 44))]), INK, 3.0 * kh)
	for w in range(3):
		var wy := 26.0 + float(w) * 8.0
		c.draw_line(hp.call(Vector2(70, wy)), hp.call(Vector2(140, wy - 14.0 + float(w) * 12.0)), WHISKER_WIRE, 2.5 * kh)
	# the eye: shut, a bronze lid; awake, an almond of amber with a slit,
	# under a frown that hardens when he hisses
	var eye := Vector2(30, -12)
	if awake <= 0.0:
		c.draw_line(hp.call(eye + Vector2(-16, 2)), hp.call(eye + Vector2(16, 0)), INK, 5.0 * kh)
	else:
		var almond := PackedVector2Array()
		var almond_in := PackedVector2Array()
		for i in range(16):
			var a := float(i) / 16.0 * TAU
			var v := Vector2(cos(a) * 17.0, sin(a) * 11.0 * awake * (1.0 - 0.3 * hiss))
			almond.append(hp.call(eye + v.rotated(-0.18)))
			almond_in.append(hp.call(eye + (v * 0.78).rotated(-0.18)))
		c.draw_colored_polygon(almond, INK)
		c.draw_colored_polygon(almond_in, EYE_AMBER)
		# a smug half-lidded look; hissing, the lids snap open
		var lid := 0.5 * (1.0 - hiss)
		if lid > 0.02:
			# the lid is the eye's top, down to a line `yl`; only points above it
			var yl := 12.0 * awake * (2.0 * lid - 1.0)
			var local := PackedVector2Array()
			for li in range(1, 16):
				var la := PI + float(li) / 16.0 * PI
				var v := Vector2(cos(la) * 18.0, sin(la) * 12.0 * awake)
				if v.y < yl - 0.5:
					local.append(v)
			if local.size() >= 2:
				var lid_pts := PackedVector2Array()
				for v in local:
					lid_pts.append(hp.call(eye + v.rotated(-0.18)))
				var r_end: Vector2 = hp.call(eye + Vector2(local[local.size() - 1].x, yl).rotated(-0.18))
				var l_end: Vector2 = hp.call(eye + Vector2(local[0].x, yl).rotated(-0.18))
				lid_pts.append(r_end)
				lid_pts.append(l_end)
				c.draw_colored_polygon(lid_pts, BRONZE_BASE)
				c.draw_line(l_end, r_end, INK, 4.0 * kh)
		c.draw_colored_polygon(MillieSide.ellipse(hp.call(eye + Vector2(4, 0)), Vector2(2.8 - 1.2 * hiss, 8.0 * awake) * kh), EYE_PUPIL)
		c.draw_circle(hp.call(eye + Vector2(-4, -3)), 2.0 * kh, Color(1, 1, 0.92))
		c.draw_line(hp.call(eye + Vector2(-20, -18 + 4.0 * hiss)), hp.call(eye + Vector2(18, -12 + 5.0 * hiss)), INK, (5.0 + 3.0 * hiss) * kh)


# a foreleg: a thick column from the shoulder down to a round paw; `claws`
# out when it swats
static func _cat_leg(c: CanvasItem, p: Callable, up: Callable, hip: Vector2, paw: Vector2, k: float, col: Color,
		claws: float) -> void:
	var a: Vector2 = up.call(hip)
	var b: Vector2 = p.call(paw + Vector2(0, -14))
	c.draw_line(a, b, INK, 66.0 * k)
	c.draw_line(a, b, col, 58.0 * k)
	c.draw_line(a + Vector2(-10, 0) * k, b + Vector2(-10, -10) * k, col.lightened(0.08), 8.0 * k)
	_cat_paw(c, p, paw + Vector2(0, -4), k, col, 60.0)
	if claws > 0.3:
		for cl in range(3):
			var cb: Vector2 = p.call(paw + Vector2(18.0, -12.0 + float(cl) * 7.0))
			var ct: Vector2 = cb + Vector2(18.0, -4.0 + float(cl) * 4.0) * k * claws
			c.draw_line(cb, ct, INK, 6.0 * k)
			c.draw_line(cb, ct, Color(0.96, 0.94, 0.86), 3.0 * k)


# a paw, toes forward, the creases between them
static func _cat_paw(c: CanvasItem, p: Callable, at: Vector2, k: float, col: Color, w: float) -> void:
	c.draw_colored_polygon(MillieSide.ellipse(p.call(at + Vector2(6, -8)), Vector2(w * 0.5 + 4.0, 17) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(at + Vector2(6, -8)), Vector2(w * 0.5, 13) * k), col)
	for n in range(2):
		var tx := 6.0 + float(n) * 11.0
		c.draw_line(p.call(at + Vector2(tx, -16)), p.call(at + Vector2(tx + 2, -2)), INK, 2.5 * k)


# the card: the rambla gone white-hot behind EL GAT!, his face filling the
# frame from the left, eye blazing, a paw up
static func _title(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(1.0, 0.88, 0.58), Color(0.62, 0.40, 0.26))
	var d := t - TITLE_AT
	cat(c, Vector2(-330.0 + d * 90.0, 1180.0), 2.7, t, 1.0, false, 0.0, 1.0, 1.0)
	FilmKit.slam(c, t, "EL GAT!", Vector2(800, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
