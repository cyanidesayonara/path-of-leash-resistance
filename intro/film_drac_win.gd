class_name FilmDracWin
extends RefCounted

# El Mosaic's victory film, "El Drac del Mosaic": the payoff after the
# salamander is settled (docs/BOSSES.md). Park Guell at noon again, side on:
# he lies sprawled on the gravel where his slide down the stair left him,
# seeing stars. She trots up, stretches, and boops his snout with a bark:
# sparks, his eye goes soft, and his tongue flicks out and catches her on
# the nose. He scuttles back up the grotto fountain, turns, curls his tail
# over his back and settles head down as he has lain since 1903; the water
# runs from his mouth again, then rises into a full arc with a rainbow in
# it. Your human catches up and takes the photograph everyone takes. The
# card slams in: EL DRAC! / VICTORIA AL MOSAIC / EL MOSAIC IS YOURS.
#
# The salamander, the stair and the park are FilmDrac's.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const LENGTH := FilmKit.LENGTH
const BG := FilmDrac.BG
const FEET := FilmDrac.FEET
const PLINTH_X := 230.0
const PLINTH_TOP := FEET - 160.0
const SPRAWL_X := 470.0
const DRAC_K := 2.1
const S := 1.45

const BOOP_AT := 1.3
const LICK_AT := 1.65
const CLIMB_AT := 2.3            # he scuttles for the fountain
const ON_PLINTH_AT := 3.0        # up, and settles
const FLOW_AT := 3.3             # the water runs again
const ARC_AT := 3.7              # and rises into the arc
const PHOTO_AT := 4.6
const HUMAN_STOP := 2.4
const TITLE_AT := FilmKit.TITLE_AT
const INK := IntroKit.INK

# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.2, "whoop", 1.0, -6.0],
	[BOOP_AT, "bark", 1.25, -2.0],
	[BOOP_AT + 0.05, "star", 1.1, -2.0],
	[LICK_AT, "squelch", 1.4, -6.0],
	[CLIMB_AT, "drac_click", 1.2, -6.0],
	[CLIMB_AT + 0.2, "drac_click", 1.4, -8.0],
	[ON_PLINTH_AT, "drum", 0.5, -3.0],
	[FLOW_AT, "splash", 1.3, -9.0],
	[ARC_AT, "drac_jet", 1.1, -2.0],
	[ARC_AT + 0.15, "splash", 0.9, -6.0],
	[4.0, "whoop", 1.2, -4.0],
	[PHOTO_AT, "pickup", 1.4, -6.0],
	[4.9, "bark", 1.35, -3.0],
	[TITLE_AT, "drac_jet", 0.9, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 89.0), sin(t * 67.0)) * 8.0 * (1.0 - Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.3)) \
		if t >= ON_PLINTH_AT else Vector2.ZERO
	# close on the boop, then back and up for the fountain and the photograph
	var f := Anim.curve("io", Anim.span(t, CLIMB_AT, ARC_AT))
	return [Vector2(lerpf(700.0, 640.0, f), lerpf(470.0, 400.0, f)) + shake, lerpf(1.05, 0.8, f)]


# where his belly is: sprawled on the gravel, the scuttle up the fountain's
# face, then lying along its top
static func drac_at(t: float) -> Vector2:
	if t < CLIMB_AT:
		return Vector2(SPRAWL_X, FEET)
	if t < ON_PLINTH_AT:
		var f := Anim.span(t, CLIMB_AT, ON_PLINTH_AT)
		return Vector2(lerpf(SPRAWL_X, PLINTH_X, f), lerpf(FEET, PLINTH_TOP, f) - sin(f * PI) * 50.0)
	return Vector2(PLINTH_X, PLINTH_TOP)


static func _pose(t: float, t_real: float) -> Dictionary:
	var booped := t >= BOOP_AT
	var climbing := t >= CLIMB_AT and t < ON_PLINTH_AT
	var up := t >= ON_PLINTH_AT
	# he faces her (left, then) until he turns for the stair; on top he faces right again
	var o := {
		"dazed": not booped, "happy": booped and not climbing, "eye": 1.0,
		"rise": 0.7 if climbing else 0.0,
		"tilt": -0.35 if climbing else (0.22 if up else 0.0),
		"curl": lerpf(0.6, 2.5, Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.4)) if up else (0.9 if climbing else 0.4),
		"wag": 0.8 if (booped and not up) else 0.0,
		"walk": t_real * 16.0 if climbing else -1.0,
		"lift": 0.5 * Anim.span(t, BOOP_AT - 0.1, BOOP_AT + 0.1) * (1.0 - Anim.span(t, LICK_AT + 0.3, CLIMB_AT)),
		"tongue": Anim.span(t, LICK_AT, LICK_AT + 0.08) * (1.0 - Anim.span(t, LICK_AT + 0.2, LICK_AT + 0.3)),
		"mouth": 0.3 if t_real >= FLOW_AT else 0.0,
	}
	if t_real >= ARC_AT:
		o["mouth"] = 0.8
		o["spout"] = 200.0 * Anim.curve("out", Anim.span(t_real, ARC_AT, ARC_AT + 0.4))
	return o


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	FilmDrac.park(c, t_real)
	FilmDrac.stair(c, t_real, PLINTH_X, PLINTH_TOP)
	var o := _pose(t, t_real)
	# facing her where he lies, round for the stair, then facing out from the top
	var face := 1.0 if t < CLIMB_AT else (-1.0 if t < ON_PLINTH_AT else 1.0)
	var at := drac_at(t)
	if t < CLIMB_AT and t >= BOOP_AT:
		# a happy wriggle where he lies
		at.x += sin(t_real * 14.0) * 3.0
	var lip := FilmDrac.side(c, at, DRAC_K, face, t_real, o)
	if t_real >= FLOW_AT and t_real < ARC_AT:
		var basin := Vector2(PLINTH_X + 300.0, FEET - 28.0)
		var k := Anim.span(t_real, FLOW_AT, FLOW_AT + 0.2)
		var pts := PackedVector2Array()
		for i in range(8):
			var u := float(i) / 7.0 * k
			pts.append(lip.lerp(basin, u) + Vector2(14.0 * sin(u * PI), 0.0))
		c.draw_polyline(pts, Color(FilmDrac.WATER, 0.85), 7.0)
		c.draw_polyline(pts, Color(FilmDrac.SPRAY, 0.9), 3.0)
	if t_real >= ARC_AT:
		_rainbow(c, t_real, lip)
		_splash(c, t_real, lip)
	if t < CLIMB_AT and not o["happy"] and o["dazed"]:
		_stars(c, t_real, at + Vector2(110.0, -80.0) * DRAC_K * 0.5)
	_dog(c, t_real, at)
	_human(c, t_real)
	if t_real >= BOOP_AT and t_real < BOOP_AT + 0.6:
		_boop_spark(c, t_real - BOOP_AT, at + Vector2(80.0 * DRAC_K, -22.0 * DRAC_K))
	if t_real >= ARC_AT:
		_sparkles(c, t_real)
	FilmKit.fades(c, t_real)


static func _stars(c: CanvasItem, t: float, at: Vector2) -> void:
	for k in range(3):
		var a := t * 6.0 + float(k) * TAU / 3.0
		var sp := at + Vector2(cos(a) * 46.0, sin(a) * 16.0)
		c.draw_circle(sp, 8.0, INK)
		c.draw_circle(sp, 6.0, Color(1.0, 0.92, 0.42))
		c.draw_line(sp - Vector2(11.0, 0.0), sp + Vector2(11.0, 0.0), Color(1.0, 0.98, 0.80), 2.5)
		c.draw_line(sp - Vector2(0.0, 11.0), sp + Vector2(0.0, 11.0), Color(1.0, 0.98, 0.80), 2.5)


# The dog: trots in from the right to his nose, stretches up and boops it,
# flinches at the lick with a happy shake, then follows him to the stair
# and stands proud, barking
static func _dog(c: CanvasItem, t: float, drac: Vector2) -> void:
	var nose_x := drac.x + 80.0 * DRAC_K
	var mx: float
	var trot := 0.0
	var stretch := 0.0
	var proud := 0.0
	var face := -1.0
	var stop := nose_x + 100.0
	if t < BOOP_AT:
		mx = Anim.k(t, [[0.0, 1300.0], [BOOP_AT - 0.2, stop + 10.0, "io"], [BOOP_AT, stop]])
		trot = 1.0 - Anim.span(t, BOOP_AT - 0.3, BOOP_AT)
		stretch = Anim.span(t, BOOP_AT - 0.12, BOOP_AT)
	elif t < CLIMB_AT:
		mx = stop + 26.0 * Anim.span(t, LICK_AT, LICK_AT + 0.1)
		stretch = 1.0 - Anim.span(t, BOOP_AT + 0.2, BOOP_AT + 0.4)
	else:
		mx = lerpf(stop + 26.0, 860.0, Anim.span(t, CLIMB_AT, ON_PLINTH_AT))
		proud = 1.0
	var lick := Anim.span(t, LICK_AT, LICK_AT + 0.08) * (1.0 - Anim.span(t, LICK_AT + 0.3, LICK_AT + 0.6))
	var yap := absf(sin(t * 14.0)) if (proud > 0.0 and t >= 4.85) or stretch > 0.8 else 0.0
	var pose := {
		"gait": trot,
		"phase": mx * TAU / (48.0 * S),
		"crouch": 0.15 * stretch + 0.25 * lick,
		"lean": -0.25 * stretch + 0.1 * proud - 0.3 * lick,
		"reach": 0.55 * stretch + 0.1 * trot,
		"push": 0.35 * stretch + 0.1 * trot,
		"head_up": 0.3 * stretch + 0.65 * proud + 0.4 * lick,
		"ear": 1.2 * proud + 0.9 * stretch - 0.6 * lick,
		"tail": 0.7 * proud + sin(t * 18.0) * 0.4 * (proud + stretch + lick) + sin(t * 12.0) * 0.3 * trot,
		"mouth": 0.3 + 0.6 * yap if (proud > 0.0 or stretch > 0.0) else 0.0,
		"brow": 0.7 * proud + 0.5 * stretch + lick,
	}
	IntroKit.millie(c, Vector2(mx, FEET), S * 1.05, face, Anim.squash(1.0 + 0.15 * stretch - 0.12 * lick), pose, FEET)


# Your human: strolls up, looks up from the phone for once, takes the photo
static func _human(c: CanvasItem, t: float) -> void:
	var hx: float = Anim.k(t, [[0.0, 1560.0], [HUMAN_STOP, 1180.0, "io"], [LENGTH, 1180.0]])
	var walking := t < HUMAN_STOP
	var aim := Anim.span(t, ARC_AT, PHOTO_AT)
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
		var gb := ShapeBatch.new(c)
		gb.glow(hand + Vector2(-12.0, -18.0), 420.0 * (1.0 - f * 0.5), Color(1.0, 0.98, 0.88, 0.9 * (1.0 - f)))
		gb.flush()
		c.draw_circle(hand + Vector2(-12.0, -18.0), 70.0 * (1.0 - f), Color(1.0, 1.0, 1.0, 1.0 - f))


static func _boop_spark(c: CanvasItem, dt: float, at: Vector2) -> void:
	var f := clampf(dt / 0.55, 0.0, 1.0)
	var r := 52.0 * sin(f * PI * 0.5)
	c.draw_arc(at, r, 0.0, TAU, 24, Color(1.0, 0.90, 0.35, (1.0 - f) * 0.85), 3.5)
	for i in range(8):
		var d := Vector2.from_angle(float(i) * TAU / 8.0)
		var col: Color = BossDrac.TILES[i % BossDrac.TILES.size()]
		c.draw_line(at + d * r * 0.6, at + d * (r + 10.0), Color(1.0, 0.98, 0.80, 1.0 - f), 3.0)
		c.draw_rect(Rect2(at + d * (r + 16.0) - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color(col, 1.0 - f))


# where the arc lands, and the rainbow standing in its spray
static func _splash(c: CanvasItem, t: float, lip: Vector2) -> void:
	var land := lip + Vector2(200.0 * DRAC_K * 0.96, 200.0 * DRAC_K * 0.18)
	for i in range(8):
		var u := fposmod(t * 2.2 + float(i) * 0.125, 1.0)
		var a := PI + float(i) / 7.0 * PI
		c.draw_circle(land + Vector2(cos(a) * (14.0 + u * 50.0), sin(a) * (10.0 + u * 40.0) + u * u * 50.0), 5.0 - u * 3.0, Color(FilmDrac.SPRAY, 1.0 - u))


static func _rainbow(c: CanvasItem, t: float, lip: Vector2) -> void:
	var f := Anim.span(t, ARC_AT + 0.2, ARC_AT + 0.7) * (1.0 - Anim.span(t, TITLE_AT - 0.2, TITLE_AT)) * 0.4
	var centre := lip + Vector2(230.0, 120.0)
	var cols: Array[Color] = [Color(0.96, 0.30, 0.30), Color(0.96, 0.62, 0.22), Color(0.96, 0.90, 0.24),
		Color(0.28, 0.82, 0.40), Color(0.22, 0.68, 0.96), Color(0.62, 0.32, 0.92)]
	for i in range(cols.size()):
		c.draw_arc(centre, 250.0 - float(i) * 9.0, -PI * 0.92, -PI * 0.12, 36, Color(cols[i], f), 8.0)


# chips of tile glinting down through the air
static func _sparkles(c: CanvasItem, t: float) -> void:
	var dt := t - ARC_AT
	for i in range(32):
		var seed_i := float(i) * 113.7
		var cx := fmod(seed_i * 17.1, 1600.0) - 160.0
		var cy := fmod(seed_i * 29.3 + dt * (130.0 + sin(seed_i) * 40.0), 760.0) - 40.0
		var col: Color = BossDrac.TILES[i % BossDrac.TILES.size()]
		c.draw_set_transform(Vector2(cx, cy), dt * 3.5 + seed_i, Vector2.ONE)
		c.draw_colored_polygon(PackedVector2Array([Vector2(-5, -3), Vector2(4, -4), Vector2(5, 3), Vector2(-3, 4)]), col)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# the card: his head big from the left, eye shut in a smile, the arc rising
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(0.96, 0.98, 0.86), Color(0.24, 0.58, 0.72))
	var d := t - TITLE_AT
	FilmDrac.side(c, Vector2(-30.0 + d * 40.0, 640.0), 4.0, 1.0, t, {"happy": true, "rise": 0.5, "tilt": -0.18,
		"curl": 1.0, "mouth": 0.8, "spout": 110.0 + d * 30.0, "lift": 0.5})
	FilmKit.slam(c, t, "EL DRAC!", Vector2(700, 200))
	IntroTitle.word(c, "VICTORIA AL MOSAIC", Vector2(700, 400), 46)
	IntroTitle.word(c, "EL MOSAIC IS YOURS", Vector2(700, 470), 30)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.98, 0.90))
