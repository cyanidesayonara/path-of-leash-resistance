class_name FilmLleonsWin
extends RefCounted

# El Port's victory film, "Els Lleons del Port": the payoff after the two
# bronze lions are settled (docs/BOSSES.md). The harbour at dusk again, side
# on, the column between them: both lions sat on the quay in front of their
# plinths, face to face, heads coming down to her. She trots in between them
# and boops one nose with a bark, then turns and boops the other: sparks, and
# each goes soft-eyed and rumbling. They get up, bound back onto their
# plinths with a thump apiece and lie down as they have lain since 1888. The
# quay's lamps come on one after another; a gull lands on a mane, gets one
# amber look, and is allowed to stay. Your human catches up and takes the
# photograph. The card slams in:
# ELS LLEONS! / VICTORIA AL PORT / EL PORT IS YOURS.
#
# The lions, the harbour and the monument are FilmLleons's.

const LENGTH := FilmKit.LENGTH
const BG := FilmLleons.BG
const FEET := FilmLleons.FEET
const COLUMN_X := 575.0
const PLINTH_A := 110.0
const PLINTH_B := 1040.0
const PLINTH_TOP := FEET - 140.0
const SIT_A := 330.0
const SIT_B := 820.0
const LION_K := 0.8
const S := 1.45

const BOOP_A := 1.2              # the left nose
const BOOP_B := 1.9              # the right nose
const STAND_AT := 2.4            # they get up
const CLIMB_AT := 2.6            # and bound for their plinths
const ON_PLINTH_AT := 3.25       # the thump
const LAMPS_AT := 3.5            # the first lamp; one every LAMP_STEP after
const LAMP_STEP := 0.15
const GULL_AT := 4.3             # the gull lands
const PHOTO_AT := 4.6            # the photograph
const HUMAN_STOP := 2.2
const TITLE_AT := FilmKit.TITLE_AT
const INK := IntroKit.INK
const LAMPS: Array[float] = [-170.0, 330.0, 820.0, 1320.0]

# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.2, "whoop", 1.0, -6.0],
	[BOOP_A, "bark", 1.25, -2.0],
	[BOOP_A + 0.05, "star", 1.1, -2.0],
	[BOOP_A + 0.2, "gat_purr", 0.75, -4.0],
	[BOOP_B, "bark", 1.3, -2.0],
	[BOOP_B + 0.05, "star", 1.25, -2.0],
	[BOOP_B + 0.2, "gat_purr", 0.85, -4.0],
	[CLIMB_AT, "grunt", 0.7, -7.0],
	[ON_PLINTH_AT, "drum", 0.4, -1.0],
	[ON_PLINTH_AT + 0.08, "drum", 0.5, -3.0],
	[LAMPS_AT, "chime", 1.0, -9.0],
	[LAMPS_AT + LAMP_STEP, "chime", 1.12, -9.0],
	[LAMPS_AT + LAMP_STEP * 2.0, "chime", 1.26, -9.0],
	[LAMPS_AT + LAMP_STEP * 3.0, "chime", 1.5, -9.0],
	[3.9, "whoop", 1.2, -4.0],
	[GULL_AT, "squawk", 1.2, -8.0],
	[PHOTO_AT, "pickup", 1.4, -6.0],
	[4.9, "bark", 1.35, -3.0],
	[TITLE_AT, "lion_roar", 0.95, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 89.0), sin(t * 67.0)) * 10.0 * (1.0 - Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.35)) \
		if t >= ON_PLINTH_AT else Vector2.ZERO
	# close on the three of them, then back and up for the plinths and the lamps
	var f := Anim.curve("io", Anim.span(t, STAND_AT, ON_PLINTH_AT))
	return [Vector2(575.0, lerpf(470.0, 395.0, f)) + shake, lerpf(1.0, 0.8, f)]


# where a lion's feet are: sat on the quay, then the bound up onto his plinth
static func lion_at(t: float, a: bool) -> Vector2:
	var sat := SIT_A if a else SIT_B
	var home := PLINTH_A if a else PLINTH_B
	if t < CLIMB_AT:
		return Vector2(sat, FEET)
	if t < ON_PLINTH_AT:
		var f := Anim.span(t, CLIMB_AT, ON_PLINTH_AT)
		return Vector2(lerpf(sat, home, f), lerpf(FEET, PLINTH_TOP, f) - sin(f * PI) * 120.0)
	return Vector2(home, PLINTH_TOP)


# a lion's pose at t; `boop_at` is when his nose is booped
static func _pose(t: float, t_real: float, boop_at: float, a: bool) -> Dictionary:
	var booped := t >= boop_at
	var dip: float = Anim.span(t, boop_at - 0.6, boop_at - 0.2) * (1.0 - 0.7 * Anim.span(t, boop_at + 0.1, boop_at + 0.5))
	dip *= 1.0 - Anim.span(t, STAND_AT, STAND_AT + 0.15)
	# flinch at the boop: the head knocked back a touch
	var flinch := Anim.span(t, boop_at, boop_at + 0.06) * (1.0 - Anim.span(t, boop_at + 0.06, boop_at + 0.3))
	var o := {
		"up": 1.0 - Anim.span(t, ON_PLINTH_AT + 0.05, ON_PLINTH_AT + 0.4),
		"sit": 1.0 - Anim.span(t, STAND_AT, STAND_AT + 0.2),
		"dip": dip, "eye": 1.0, "look": Vector2(1.0, 0.6), "brow": 0.6,
		"happy": booped, "tilt": -0.2 * flinch,
		"swish": 0.5 + 0.5 * float(booped), "walking": false,
		"jaw": 0.25 * Anim.span(t, boop_at + 0.15, boop_at + 0.4) * (1.0 - Anim.span(t, STAND_AT, CLIMB_AT)),
	}
	if a and t >= GULL_AT + 0.1 and t < GULL_AT + 0.7:
		# one look up at the gull
		o["happy"] = false
		o["look"] = Vector2(-0.4, -1.0)
		o["brow"] = 1.0
	if t >= CLIMB_AT and t < ON_PLINTH_AT:
		o["swish"] = 0.0
	o["t"] = t_real
	return o


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	var on := PackedFloat32Array()
	for i in range(LAMPS.size()):
		var lt := LAMPS_AT + float(i) * LAMP_STEP
		# a flicker, then steady
		on.append(Anim.span(t_real, lt, lt + 0.08) * (0.75 + 0.25 * Anim.span(t_real, lt + 0.12, lt + 0.3)))
	FilmLleons.harbour(c, t_real, LAMPS, on)
	FilmLleons.monument(c, COLUMN_X)
	FilmLleons.plinth(c, PLINTH_A, PLINTH_TOP, FilmLleons.PLINTH_W)
	FilmLleons.plinth(c, PLINTH_B, PLINTH_TOP, FilmLleons.PLINTH_W)

	var oa := _pose(t, t_real, BOOP_A, true)
	var ob := _pose(t, t_real, BOOP_B, false)
	var pa := lion_at(t, true)
	var pb := lion_at(t, false)
	FilmLleons.lion(c, pa, LION_K, 1.0, t_real, oa)
	FilmLleons.lion(c, pb, LION_K, -1.0, t_real + 1.3, ob)
	var nose_a := FilmLleons.nose_at(pa, LION_K, 1.0, oa)
	var nose_b := FilmLleons.nose_at(pb, LION_K, -1.0, ob)

	if t >= ON_PLINTH_AT and t < ON_PLINTH_AT + 0.55:
		var f := Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.55)
		for px: float in [PLINTH_A, PLINTH_B]:
			for k in range(7):
				var a := float(k) / 6.0 * PI
				IntroKit.puff(c, Vector2(px + cos(a) * (130.0 + f * 90.0), PLINTH_TOP - sin(a) * 16.0), 22.0 * (1.0 - f), 1.0 - f)
	# the rumble: soft rings rising off each booped lion while he sits
	for who in range(2):
		var at: float = [BOOP_A, BOOP_B][who]
		if t_real > at + 0.15 and t_real < STAND_AT + 0.2:
			var head: Vector2 = ([nose_a, nose_b][who] as Vector2) + Vector2(-70.0 if who == 0 else 70.0, -90.0)
			for h in range(3):
				var ht := fposmod((t_real - at) * 1.5 + float(h) * 0.7, 2.1)
				var hp := head + Vector2(sin(ht * 4.0) * 16.0, -ht * 46.0)
				var ha := clampf(1.0 - ht / 2.1, 0.0, 1.0) * 0.8 * (1.0 - Anim.span(t_real, STAND_AT, STAND_AT + 0.2))
				c.draw_arc(hp, 7.0 + ht * 5.0, 0.0, TAU, 16, Color(1.0, 0.86, 0.60, ha), 3.0)

	_gull(c, t_real, pa)
	_dog(c, t_real, nose_a, nose_b)
	_human(c, t_real)
	for who in range(2):
		var at: float = [BOOP_A, BOOP_B][who]
		if t_real >= at and t_real < at + 0.6:
			_boop_spark(c, t_real - at, [nose_a, nose_b][who])
	FilmKit.fades(c, t_real)


# The dog: trots in between them, stretches up to the left nose, turns and
# does the right one, then stands in the middle of it all, barking
static func _dog(c: CanvasItem, t: float, nose_a: Vector2, nose_b: Vector2) -> void:
	var xa := nose_a.x + 114.0
	var xb := nose_b.x - 114.0
	var mx: float
	var face := -1.0
	var trot := 0.0
	var stretch := 0.0
	var proud := 0.0
	if t < BOOP_A:
		mx = Anim.k(t, [[0.0, 1120.0], [BOOP_A - 0.2, xa + 10.0, "io"], [BOOP_A, xa]])
		trot = 1.0 - Anim.span(t, BOOP_A - 0.3, BOOP_A)
		stretch = Anim.span(t, BOOP_A - 0.12, BOOP_A)
	elif t < BOOP_A + 0.4:
		mx = xa
		stretch = 1.0 - Anim.span(t, BOOP_A + 0.2, BOOP_A + 0.4)
	elif t < STAND_AT:
		mx = lerpf(xa, xb, Anim.span(t, BOOP_A + 0.4, BOOP_B - 0.15))
		face = 1.0
		trot = 0.6 * (1.0 - Anim.span(t, BOOP_B - 0.3, BOOP_B - 0.1))
		stretch = Anim.span(t, BOOP_B - 0.12, BOOP_B) * (1.0 - Anim.span(t, BOOP_B + 0.2, STAND_AT))
	else:
		mx = lerpf(xb, COLUMN_X, Anim.span(t, STAND_AT, CLIMB_AT))
		face = 1.0
		proud = 1.0
	var yap := absf(sin(t * 14.0)) if (proud > 0.0 and t >= 4.85) or stretch > 0.8 else 0.0
	var pose := {
		"gait": trot,
		"phase": mx * TAU / (48.0 * S),
		"crouch": 0.15 * stretch,
		"lean": -0.25 * stretch + 0.1 * proud,
		"reach": 0.55 * stretch + 0.1 * trot,
		"push": 0.35 * stretch + 0.1 * trot,
		"head_up": 0.5 * stretch + 0.65 * proud,
		"ear": 1.2 * proud + 0.9 * stretch,
		"tail": 0.7 * proud + sin(t * 18.0) * 0.35 * (proud + stretch) + sin(t * 12.0) * 0.3 * trot,
		"mouth": 0.3 + 0.6 * yap if (proud > 0.0 or stretch > 0.0) else 0.0,
		"brow": 0.7 * proud + 0.5 * stretch,
	}
	IntroKit.millie(c, Vector2(mx, FEET), S * 1.05, face, Anim.squash(1.0 + 0.15 * stretch), pose, FEET)


# Your human: strolls up, looks up from the phone for once, and takes the
# photograph
static func _human(c: CanvasItem, t: float) -> void:
	var hx: float = Anim.k(t, [[0.0, 1520.0], [HUMAN_STOP, 1275.0, "io"], [LENGTH, 1275.0]])
	var walking := t < HUMAN_STOP
	var aim := Anim.span(t, ON_PLINTH_AT + 0.3, PHOTO_AT)
	var proud := Anim.span(t, PHOTO_AT, PHOTO_AT + 0.4)
	var hpose := {
		"stride": t * 7.5 if walking else 0.0,
		"stride_amp": 0.7 if walking else 0.0,
		"phone": 1.0,
		"glow": 0.5 if t < PHOTO_AT else 0.1,
		"reach": 0.35 + 0.45 * aim,
		"lean": -0.15 * aim + 0.1 * proud,
		"head": -0.25 * aim - 0.1 * proud,
		"mouth": 0.4 * aim + 0.8 * proud,
	}
	var hand := IntroKit.human(c, Vector2(hx, FEET), S, -1.0, Vector2.ONE, hpose, 0.0, FEET)
	if t >= PHOTO_AT and t < PHOTO_AT + 0.4:
		var f := Anim.span(t, PHOTO_AT, PHOTO_AT + 0.4)
		var gb := FilmLleons.ShapeBatch.new(c)
		gb.glow(hand + Vector2(-12.0, -18.0), 420.0 * (1.0 - f * 0.5), Color(1.0, 0.98, 0.88, 0.9 * (1.0 - f)))
		gb.flush()
		c.draw_circle(hand + Vector2(-12.0, -18.0), 70.0 * (1.0 - f), Color(1.0, 1.0, 1.0, 1.0 - f))


# A gull: in on the evening air, down onto the left lion's mane, wings folded
static func _gull(c: CanvasItem, t: float, lion_pos: Vector2) -> void:
	if t < GULL_AT - 0.7:
		return
	var perch := lion_pos + Vector2(72.0, -246.0) * LION_K
	var f := Anim.curve("out", Anim.span(t, GULL_AT - 0.7, GULL_AT))
	var at := Vector2(lerpf(940.0, perch.x, f), lerpf(40.0, perch.y, f) - sin(f * PI) * 60.0)
	var flying := t < GULL_AT
	var white := Color(0.97, 0.95, 0.92)
	var grey := Color(0.62, 0.64, 0.72)
	if flying:
		var flap := sin(t * 26.0)
		for sd: float in [-1.0, 1.0]:
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(-6.0, -4.0), at + Vector2(sd * 12.0 + 6.0, -30.0 * flap - 8.0),
				at + Vector2(sd * 8.0 + 22.0, -18.0 * flap), at + Vector2(12.0, 0.0)]), INK if sd < 0.0 else grey)
	else:
		c.draw_line(at + Vector2(-4.0, 10.0), at + Vector2(-4.0, 20.0), Color(0.95, 0.62, 0.24), 3.0)
		c.draw_line(at + Vector2(4.0, 10.0), at + Vector2(4.0, 20.0), Color(0.95, 0.62, 0.24), 3.0)
	c.draw_colored_polygon(MillieSide.ellipse(at, Vector2(24.0, 14.0)), INK)
	c.draw_colored_polygon(MillieSide.ellipse(at, Vector2(21.0, 11.0)), white)
	if not flying:
		c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(6.0, -2.0), Vector2(15.0, 7.0), 0.15), grey)
		c.draw_line(at + Vector2(16.0, 0.0), at + Vector2(28.0, 3.0), INK, 4.0)
	var bob := sin(t * 7.0) * 1.5 if not flying else 0.0
	var head := at + Vector2(-18.0, -12.0 + bob)
	c.draw_circle(head, 11.0, INK)
	c.draw_circle(head, 8.5, white)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(-7.0, -2.0), head + Vector2(-22.0, 3.0), head + Vector2(-7.0, 5.0)]), Color(0.98, 0.72, 0.20))
	c.draw_circle(head + Vector2(-3.0, -2.0), 2.0, INK)


static func _boop_spark(c: CanvasItem, dt: float, at: Vector2) -> void:
	var f := clampf(dt / 0.55, 0.0, 1.0)
	var r := 52.0 * sin(f * PI * 0.5)
	c.draw_arc(at, r, 0.0, TAU, 24, Color(1.0, 0.90, 0.35, (1.0 - f) * 0.85), 3.5)
	for i in range(8):
		var a := float(i) * (TAU / 8.0)
		var d := Vector2.from_angle(a)
		c.draw_line(at + d * r * 0.6, at + d * (r + 10.0), Color(1.0, 0.98, 0.80, 1.0 - f), 3.0)
		c.draw_circle(at + d * (r + 14.0), 3.5 * (1.0 - f), Color(1.0, 1.0, 0.85, 1.0 - f))


# the card: both lions in from the corners again, purring this time
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(1.0, 0.76, 0.46), Color(0.36, 0.20, 0.44))
	var d := t - TITLE_AT
	var o := {"up": 1.0, "happy": true, "jaw": 0.3, "tilt": -0.08 + sin(t * 5.0) * 0.03, "swish": 1.0}
	FilmLleons.lion(c, Vector2(-210.0 + d * 40.0, 1100.0), 2.1, 1.0, t, o)
	FilmLleons.lion(c, Vector2(1490.0 - d * 40.0, 1100.0), 2.1, -1.0, t + 0.7, o)
	FilmKit.slam(c, t, "ELS LLEONS!", Vector2(640, 200))
	IntroTitle.word(c, "VICTORIA AL PORT", Vector2(640, 400), 46)
	IntroTitle.word(c, "EL PORT IS YOURS", Vector2(640, 470), 30)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.95, 0.85))
