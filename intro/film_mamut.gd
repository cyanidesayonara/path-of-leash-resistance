class_name FilmMamut
extends RefCounted

# La Ciutadella's film, "El Mamut": the first statue boss's wake
# (docs/BOSSES.md), played as she first passes his plinth
# (systems/boss_mamut.gd), before the walk's own wake. A park morning, side
# on: the boating lake behind, a rowing boat, plane trees, and the stone
# mammoth on his plinth by the water. The two of them walk past, your human
# on the phone. A crack: her ears go up and she looks back. His ear twitches,
# an eye opens, the trunk curls up and he trumpets, the rower dropping an oar;
# he steps down off the plinth with a thump that rocks the boat, and comes on
# across the lawn. She does not run: she dashes back and plants herself
# between your human and him, barking. EL MAMUT! slams in, his trunk raised.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.62, 0.80, 0.94)
const FEET := 640.0
const PLINTH_X := -170.0
const PLINTH_TOP := FEET - 150.0
const EAR_AT := 1.8              # an ear twitches
const EYES_AT := 2.05            # an eye opens
const TRUNK_AT := 2.25           # the trunk curls up: the trumpet
const STEP_AT := 2.75            # off the front of the plinth
const DROP_AT := 3.05            # on the lawn: the thump
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const MAMUT_K := 0.95
const STONE := Color(0.53, 0.49, 0.45)
const STONE_DARK := Color(0.37, 0.34, 0.31)
const STONE_LIT := Color(0.68, 0.64, 0.59)
const FUR := Color(0.45, 0.41, 0.37)
const TUSK := Color(0.93, 0.89, 0.79)
const EYE_AMBER := Color(0.98, 0.80, 0.30)
const PLINTH := Color(0.74, 0.71, 0.65)
const LAWN := Color(0.40, 0.60, 0.30)
const GRAVEL := Color(0.80, 0.71, 0.54)
const WATER := Color(0.36, 0.58, 0.70)
const INK := IntroKit.INK
# his outline side on, feet at the origin, after the Ciutadella's: the rump
# low behind, the shoulders a high hump, the chest under the head, and the
# hair at his belly a ragged edge
const MAMUT_BODY := [Vector2(-196, -178), Vector2(-222, -232), Vector2(-216, -292), Vector2(-180, -334),
	Vector2(-110, -366), Vector2(-30, -392), Vector2(40, -404), Vector2(100, -400), Vector2(140, -384),
	Vector2(172, -320), Vector2(172, -240), Vector2(150, -190), Vector2(100, -176), Vector2(70, -164),
	Vector2(40, -176), Vector2(10, -162), Vector2(-20, -176), Vector2(-50, -162), Vector2(-80, -176),
	Vector2(-110, -162), Vector2(-140, -176), Vector2(-170, -164)]
# the ridge of his back, where the hair stands up
const MAMUT_BACK := [Vector2(-200, -300), Vector2(-170, -326), Vector2(-130, -352), Vector2(-90, -372),
	Vector2(-50, -386), Vector2(-10, -396), Vector2(30, -402), Vector2(70, -402), Vector2(110, -396), Vector2(140, -384)]
# painted terracotta, as the Ciutadella's is
const MAMUT := Color(0.74, 0.53, 0.41)
const MAMUT_DARK := Color(0.58, 0.40, 0.30)
const MAMUT_LIT := Color(0.86, 0.67, 0.53)
const MAMUT_RIB := Color(0.60, 0.41, 0.31)
const MAMUT_TUSK := Color(0.88, 0.86, 0.81)
const MAMUT_TUSK_DARK := Color(0.68, 0.66, 0.62)
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "crack", 1.2, -10.0],
	[EAR_AT, "crack", 1.6, -14.0],
	[TRUNK_AT + 0.05, "mamut_trumpet", 1.0, -2.0],
	[STEP_AT + 0.1, "drum", 0.5, -4.0],
	[DROP_AT, "drum", 0.35, 0.0],
	[DROP_AT + 0.05, "ooooh", 0.9, -9.0],
	[DROP_AT + 0.1, "splash", 0.7, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[BOLT_AT + 0.75, "bark", 1.0, -4.0],
	[TITLE_AT, "mamut_trumpet", 0.85, -2.0],
]


# the camera: on the pair; a pan back to the plinth when she looks round,
# held as he wakes, trumpets and steps down; wide on the stand-off; the card
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 87.0), sin(t * 61.0)) * 16.0 * (1.0 - Anim.span(t, DROP_AT, DROP_AT + 0.4)) \
		if t >= DROP_AT else Vector2.ZERO
	if t >= BOLT_AT:
		return [Vector2(400.0, 420.0) + shake, Anim.k(t, [[BOLT_AT, 1.0], [TITLE_AT, 0.9, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 140.0, "io"], [3.9, 280.0, "io"],
		[4.2, 470.0, "io"], [BOLT_AT, 520.0]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 380.0, "io"], [3.9, 420.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.82, "io"], [3.9, 0.92, "io"], [4.2, 1.32, "io"], [BOLT_AT, 1.42]])
	return [Vector2(x, y) + shake, z]


# where his feet are: on the plinth, the step down, then across the lawn
static func mamut_at(t: float) -> Vector2:
	if t < STEP_AT:
		return Vector2(PLINTH_X, PLINTH_TOP)
	if t < DROP_AT:
		var f := Anim.span(t, STEP_AT, DROP_AT)
		return Vector2(lerpf(PLINTH_X, PLINTH_X + 150.0, f), lerpf(PLINTH_TOP, FEET, f * f) - sin(f * PI) * 40.0)
	return Vector2(Anim.k(t, [[DROP_AT, PLINTH_X + 150.0], [3.9, 20.0, "out"], [BOLT_AT, 30.0],
		[TITLE_AT, 40.0]]), FEET)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_park(c, t_real)
	_plinth(c, t)
	var awake := Anim.span(t, EYES_AT, EYES_AT + 0.2)
	var trunk := Anim.span(t, TRUNK_AT, TRUNK_AT + 0.25) * (1.0 - Anim.span(t, STEP_AT, STEP_AT + 0.3))
	if t >= BOLT_AT:
		trunk = Anim.span(t, BOLT_AT + 0.2, BOLT_AT + 0.5) * 0.7
	var ear := sin(t_real * 40.0) * (1.0 - Anim.span(t, EAR_AT, EAR_AT + 0.4)) if t >= EAR_AT else 0.0
	var walking := t >= DROP_AT + 0.1 and t < 3.9
	# off the plinth he charges; where he pulls up at her, he trumpets
	var rage := Anim.span(t, DROP_AT + 0.1, DROP_AT + 0.45)
	if t >= 3.9 and t < BOLT_AT:
		trunk = Anim.span(t, 3.9, 4.1) * 0.9
	mamut(c, mamut_at(t), MAMUT_K, t_real, awake, walking, trunk, ear, rage)
	if t >= DROP_AT and t < DROP_AT + 0.6:
		var f := Anim.span(t, DROP_AT, DROP_AT + 0.6)
		for k in range(9):
			var a := float(k) / 8.0 * PI
			IntroKit.puff(c, mamut_at(t) + Vector2(cos(a) * (150.0 + f * 180.0), -sin(a) * 20.0 - 10.0), 28.0 * (1.0 - f), 1.0 - f)
	FilmKit.pair(c, t_real, FEET, true)
	FilmKit.fades(c, t_real)


# the park in the morning: a pale sky, the far trees, the boating lake with a
# rowing boat that rocks at the thump, the lawn and its gravel path
static func _park(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1000.0 + 200.0), Color(0.62, 0.80, 0.94), Color(0.96, 0.90, 0.78))
	# the far tree line
	for i in range(16):
		var tx := -1500.0 + float(i) * 280.0
		var ty := 170.0 + sin(float(i) * 1.7) * 30.0
		c.draw_circle(Vector2(tx, ty), 150.0, Color(0.30, 0.48, 0.30))
		c.draw_circle(Vector2(tx + 60.0, ty - 50.0), 100.0, Color(0.36, 0.56, 0.34))
	# the lake
	c.draw_rect(Rect2(-1600, 300.0, 4600, 170.0), WATER)
	for i in range(30):
		var wx := -1500.0 + float(i) * 150.0 + sin(t * 0.8 + float(i)) * 10.0
		c.draw_line(Vector2(wx, 340.0 + float(i % 3) * 40.0), Vector2(wx + 60.0, 340.0 + float(i % 3) * 40.0),
			Color(0.70, 0.86, 0.94, 0.6), 4.0)
	# the rowing boat, rocking harder at the thump; the oar dropped at the trumpet
	var rock := sin(t * 2.0) * 3.0 + sin(Anim.span(t, DROP_AT, DROP_AT + 0.8) * PI * 3.0) * 14.0 \
		* (1.0 - Anim.span(t, DROP_AT + 0.4, DROP_AT + 1.2))
	# right of the plinth, in shot while the camera holds on him
	var bx := 420.0
	var by := 400.0 + rock
	c.draw_colored_polygon(PackedVector2Array([Vector2(bx - 120, by - 20), Vector2(bx + 130, by - 20),
		Vector2(bx + 90, by + 30), Vector2(bx - 90, by + 30)]), Color(0.52, 0.30, 0.18))
	c.draw_rect(Rect2(bx - 120, by - 26, 250, 10), Color(0.66, 0.42, 0.24))
	c.draw_rect(Rect2(bx - 18, by - 90, 36, 64), Color(0.86, 0.32, 0.28))
	c.draw_circle(Vector2(bx, by - 108), 20.0, Color(0.92, 0.76, 0.62))
	c.draw_circle(Vector2(bx, by - 116), 18.0, Color(0.36, 0.22, 0.12))
	var oar_drop := Anim.span(t, TRUNK_AT + 0.1, TRUNK_AT + 0.5)
	c.draw_line(Vector2(bx + 10, by - 60), Vector2(bx + 150, by + 10 + oar_drop * 60.0), Color(0.72, 0.58, 0.36), 7.0)
	# the lawn, the gravel path along it
	c.draw_rect(Rect2(-1600, 470.0, 4600, FEET - 470.0 + 10.0), LAWN)
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), GRAVEL)
	for px in range(-20, 40):
		c.draw_circle(Vector2(float(px) * 77.0 + float(px % 3) * 13.0, FEET + 20.0 + float(px % 4) * 26.0), 4.0, GRAVEL.darkened(0.15))
	# a plane tree up close at the right, its mottled trunk
	c.draw_line(Vector2(1180.0, FEET), Vector2(1170.0, 60.0), Color(0.62, 0.58, 0.48), 46.0)
	for k in range(5):
		c.draw_circle(Vector2(1170.0 + float(k % 2) * 10.0, 160.0 + float(k) * 90.0), 12.0, Color(0.80, 0.78, 0.66))
	c.draw_circle(Vector2(1170.0, 0.0), 230.0, Color(0.34, 0.54, 0.30))


static func _plinth(c: CanvasItem, t: float) -> void:
	var r := Rect2(PLINTH_X - 220.0, PLINTH_TOP, 440.0, FEET - PLINTH_TOP + 10.0)
	c.draw_rect(r.grow(4.0), INK)
	c.draw_rect(r, PLINTH)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 18.0)), PLINTH.lightened(0.12))
	c.draw_rect(Rect2(PLINTH_X - 60.0, PLINTH_TOP + 60.0, 120.0, 40.0), Color(0.62, 0.48, 0.26))
	if t >= STEP_AT:
		c.draw_polyline(PackedVector2Array([Vector2(PLINTH_X + 60.0, PLINTH_TOP), Vector2(PLINTH_X + 90.0, PLINTH_TOP + 50.0),
			Vector2(PLINTH_X + 70.0, PLINTH_TOP + 100.0), Vector2(PLINTH_X + 110.0, FEET)]), STONE_DARK.darkened(0.3), 5.0)


# The mammoth side on, facing right, his feet at `at`, drawn after the
# Ciutadella's own (Miquel Dalmau, 1907): painted terracotta, tall on four
# long column legs, the back falling from a high hump to the rump, the head a
# dome with a peak, carved hair running down him in ribs, the trunk hanging
# to the ground and curling at its tip, and two great tusks sweeping out,
# down and round into spirals that end in points. `awake` opens his eye;
# `walking` swings the legs; `trunk` raises the trunk; `ear` twitches the
# hair over his ear; `rage` is his charge: the body leaning in, the head down
# and the tusks levelled, the hair along his back on end, the eye narrowed,
# the mouth open when he trumpets. Shared with the card.
static func mamut(c: CanvasItem, at: Vector2, k: float, t: float, awake: float, walking: bool,
		trunk: float, ear := 0.0, rage := 0.0) -> void:
	var p := func(v: Vector2) -> Vector2: return at + v * k
	# the body and head lean into the charge; the legs stay planted
	var lean := 0.05 * rage
	var q := func(v: Vector2) -> Vector2: return at + v.rotated(lean) * k
	var hd := Vector2(20, 40) * rage    # the head dropped to charge
	var hq := func(v: Vector2) -> Vector2: return at + (v + hd).rotated(lean) * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(10, 4) * k, Vector2(210, 16) * k), Color(0, 0, 0, 0.35))
	# the far tusk, behind everything
	_mamut_tusk(c, hq, Vector2(206, -324), k, rage, 0.9, MAMUT_TUSK_DARK)
	# legs: long columns, the far pair darker, ribbed with hair down to the toenails
	for i in range(4):
		var hip: Vector2 = [Vector2(-150, -190), Vector2(100, -190), Vector2(-112, -190), Vector2(136, -190)][i]
		var swing := sin(t * 5.0 + float(i) * 1.6) * 0.14 if walking else 0.0
		var foot: Vector2 = hip + Vector2.from_angle(PI * 0.5 + swing) * 186.0
		var col := MAMUT_DARK if i < 2 else MAMUT
		c.draw_line(p.call(hip), p.call(foot), INK, 74.0 * k)
		c.draw_line(p.call(hip), p.call(foot), col, 66.0 * k)
		c.draw_line(p.call(hip + Vector2(-14, 0)), p.call(foot + Vector2(-14, -20)), col.lightened(0.08), 14.0 * k)
		for r in range(3):
			var rx := -18.0 + float(r) * 18.0
			c.draw_line(p.call(hip + Vector2(rx, 10)), p.call(hip.lerp(foot, 0.75) + Vector2(rx, 0)), MAMUT_RIB, 3.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot), Vector2(40, 12) * k), col.darkened(0.15))
		for n in range(3):
			c.draw_circle(p.call(foot + Vector2(-18.0 + float(n) * 18.0, -5.0)), 7.0 * k, MAMUT_TUSK.darkened(0.1))
	# the body: one outline, hump high, rump low, the belly's hair a ragged edge
	var body := PackedVector2Array()
	for v: Vector2 in MAMUT_BODY:
		body.append(q.call(v))
	if rage > 0.0:
		# the hair along his back standing on end
		for i in range(MAMUT_BACK.size()):
			var rim: Vector2 = MAMUT_BACK[i]
			var out := Vector2(-0.3, -1.0).normalized()
			var ln := (18.0 + float(i % 3) * 8.0) * rage
			var sd := Vector2(10.0, -3.0)
			c.draw_colored_polygon(PackedVector2Array([q.call(rim - sd * 1.4 + Vector2(0, 8)), q.call(rim + out * (ln + 6.0)),
				q.call(rim + sd * 1.4 + Vector2(0, 8))]), INK)
			c.draw_colored_polygon(PackedVector2Array([q.call(rim - sd + Vector2(0, 8)), q.call(rim + out * ln),
				q.call(rim + sd + Vector2(0, 8))]), MAMUT_DARK)
	c.draw_colored_polygon(body, MAMUT)
	# the light along the hump, the shade under the belly
	c.draw_polyline(PackedVector2Array([q.call(Vector2(-196, -300)), q.call(Vector2(-120, -352)), q.call(Vector2(-40, -384)),
		q.call(Vector2(40, -398)), q.call(Vector2(110, -388))]), MAMUT_LIT, 24.0 * k)
	c.draw_polyline(PackedVector2Array([q.call(Vector2(-200, -200)), q.call(Vector2(-60, -186)), q.call(Vector2(150, -196))]),
		MAMUT_DARK, 26.0 * k)
	# the hair, carved: ribs running from the spine down over the flank
	for i in range(16):
		var sx := -196.0 + float(i) * 22.0
		var top := _mamut_back_y(sx) + 14.0
		var strand := PackedVector2Array()
		for j in range(7):
			var u := float(j) / 6.0
			strand.append(q.call(Vector2(sx + sin(u * 4.0 + float(i) * 0.9) * 5.0 + u * 10.0, lerpf(top, -178.0, u))))
		c.draw_polyline(strand, MAMUT_RIB, 3.5 * k)
	var outline := body.duplicate()
	outline.append(body[0])
	c.draw_polyline(outline, INK, 6.0 * k)
	# the head: a dome with a peak, ribbed with hair like the rest of him
	var hc := Vector2(196, -380)
	c.draw_colored_polygon(MillieSide.ellipse(hq.call(hc + Vector2(-16, -58)), Vector2(58, 46) * k), INK)
	c.draw_circle(hq.call(hc), 88.0 * k, INK)
	c.draw_colored_polygon(MillieSide.ellipse(hq.call(hc + Vector2(-16, -58)), Vector2(52, 40) * k), MAMUT)
	c.draw_circle(hq.call(hc), 82.0 * k, MAMUT)
	c.draw_colored_polygon(MillieSide.ellipse(hq.call(hc + Vector2(-22, -66)), Vector2(34, 22) * k), MAMUT_LIT)
	for i in range(7):
		var a := PI * (1.05 + 0.13 * float(i))
		c.draw_line(hq.call(hc + Vector2.from_angle(a) * 76.0), hq.call(hc + Vector2.from_angle(a) * 40.0 + Vector2(6, 10)),
			MAMUT_RIB, 3.5 * k)
	# the hair falling over where the ear is, stirring
	for i in range(3):
		var ex := -46.0 + float(i) * 12.0
		c.draw_line(hq.call(hc + Vector2(ex, -10)), hq.call(hc + Vector2(ex - 6.0 + ear * 4.0, 50)), MAMUT_RIB, 4.0 * k)
	# the eye: shut, a carved lid; awake, amber under a heavy brow, narrowed
	# to a glare when he charges
	var eye := hc + Vector2(30, -6)
	if awake <= 0.0:
		c.draw_line(hq.call(eye + Vector2(-12, 0)), hq.call(eye + Vector2(12, 2)), INK, 5.0 * k)
	else:
		var sq := 1.0 - 0.4 * rage
		c.draw_colored_polygon(MillieSide.ellipse(hq.call(eye), Vector2(13, 11 * awake * sq) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(hq.call(eye), Vector2(9.5, 8 * awake * sq) * k), EYE_AMBER)
		c.draw_circle(hq.call(eye + Vector2(3, 0)), (4.0 - 1.0 * rage) * k, INK)
		c.draw_circle(hq.call(eye + Vector2(0, -2)), 1.5 * k, Color(1, 1, 0.92))
		c.draw_colored_polygon(PackedVector2Array([hq.call(eye + Vector2(-22, -22 + 4.0 * rage)), hq.call(eye + Vector2(18, -13 + 8.0 * rage)),
			hq.call(eye + Vector2(18, -6 + 8.0 * rage)), hq.call(eye + Vector2(-20, -14 + 4.0 * rage))]), INK)
	# the trunk: hanging to the ground and curling forward at the tip, or
	# raised high to trumpet
	var trunk_pts := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		var hang := Vector2(58.0 + sin(f * PI * 0.5) * 16.0 + maxf(0.0, f - 0.8) * 160.0,
			26.0 + f * 330.0 - maxf(0.0, f - 0.85) * 520.0)
		var up := Vector2(60.0 + f * 170.0, 20.0 - f * 250.0 + f * f * 70.0)
		trunk_pts.append(hq.call(hc + hang.lerp(up, trunk)))
	for i in range(11):
		var w := lerpf(46.0, 22.0, float(i) / 10.0)
		c.draw_line(trunk_pts[i], trunk_pts[i + 1], INK, (w + 8.0) * k)
		c.draw_circle(trunk_pts[i + 1], (w + 8.0) * 0.5 * k, INK)
	for i in range(11):
		var w := lerpf(46.0, 22.0, float(i) / 10.0)
		c.draw_line(trunk_pts[i], trunk_pts[i + 1], MAMUT, w * k)
		c.draw_circle(trunk_pts[i + 1], w * 0.5 * k, MAMUT)
	for i in range(1, 11):
		var dn := (trunk_pts[i + 1] - trunk_pts[i - 1]).normalized().orthogonal()
		var hw := lerpf(20.0, 10.0, float(i) / 10.0) * k
		c.draw_line(trunk_pts[i] - dn * hw, trunk_pts[i] + dn * hw * 0.7, MAMUT_RIB, 3.0 * k)
	if rage > 0.0 and trunk > 0.3:
		# trumpeting: the mouth open under the raised trunk, breath off its tip
		var o := clampf((trunk - 0.3) / 0.4, 0.0, 1.0) * rage
		var mouth := PackedVector2Array([hq.call(hc + Vector2(30, 40)), hq.call(hc + Vector2(76, 30)),
			hq.call(hc + Vector2(66, 56 + 28.0 * o)), hq.call(hc + Vector2(36, 58 + 18.0 * o))])
		c.draw_colored_polygon(mouth, Color(0.48, 0.16, 0.18))
		mouth.append(mouth[0])
		c.draw_polyline(mouth, INK, 4.0 * k)
		var sn := fposmod(t * 2.5, 1.0)
		IntroKit.puff(c, trunk_pts[11] + Vector2(30.0 + sn * 70.0, -20.0 - sn * 50.0) * k, (14.0 + sn * 30.0) * k,
			0.8 * (1.0 - sn) * o)
	# the near tusk, over the trunk
	_mamut_tusk(c, hq, Vector2(232, -312), k, rage, 1.0, MAMUT_TUSK)


# where his back is at x along him, for the hair ribs to start from
static func _mamut_back_y(x: float) -> float:
	var best := -300.0
	for i in range(MAMUT_BACK.size() - 1):
		var a: Vector2 = MAMUT_BACK[i]
		var b: Vector2 = MAMUT_BACK[i + 1]
		if x >= a.x and x <= b.x:
			best = lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
	return best


# A tusk: out of the jaw it sweeps forward and down, then curls up and back
# round into a spiral, tapering to a point. Charging, it is levelled.
static func _mamut_tusk(c: CanvasItem, hq: Callable, root: Vector2, k: float, rage: float, size: float,
		col: Color) -> void:
	var spine := PackedVector2Array()
	var pos := root
	var ang := 1.05 - 0.3 * rage
	for i in range(16):
		spine.append(pos)
		var u := float(i) / 15.0
		pos += Vector2.from_angle(ang) * 33.0 * size * (1.0 - 0.35 * u)
		ang -= 0.29 * (1.0 + 0.5 * u) * (1.0 - 0.25 * rage)
	spine.append(pos)
	var n := spine.size()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(n):
		var dir := (spine[mini(i + 1, n - 1)] - spine[maxi(i - 1, 0)]).normalized()
		var w := 16.0 * size * (1.0 - float(i) / float(n - 1))
		left.append(hq.call(spine[i] + dir.orthogonal() * w))
		right.append(hq.call(spine[i] - dir.orthogonal() * w))
	var poly := PackedVector2Array()
	poly.append_array(left)
	right.reverse()
	poly.append_array(right)
	c.draw_colored_polygon(poly, col)
	# the shade along its underside and the light along its top
	var under := PackedVector2Array()
	for i in range(n - 2):
		under.append(left[i].lerp(hq.call(spine[i]), 0.5))
	c.draw_polyline(under, col.darkened(0.15), 4.0 * k)
	poly.append(poly[0])
	c.draw_polyline(poly, INK, 4.5 * k)


# the card: the lawn gone gold behind EL MAMUT!, his head filling the frame
# from the left, trunk raised, eye blazing
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.92, 0.96, 0.82), Color(0.42, 0.58, 0.40))
	var d := t - TITLE_AT
	mamut(c, Vector2(-420.0 + d * 80.0, 1100.0), 2.0, t, 1.0, false, 0.55, 0.0, 1.0)
	FilmKit.slam(c, t, "EL MAMUT!", Vector2(660, 200))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.98, 0.90))
