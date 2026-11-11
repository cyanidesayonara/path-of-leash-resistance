class_name FilmDrac
extends RefCounted

# Park Güell / El Mosaic's film, "El Drac": the salamander boss's wake,
# played as she first passes his fountain stair (systems/boss_drac.gd).
# High noon at the park: warm stone steps, trencadís mosaic balustrades,
# the stepped grotto fountain with its trickling water, and the colorful
# ceramic salamander sleeping on his plinth.
# The two of them walk past, your human on the phone.
# The fountain sputters and ceramic clicks echo: her ears go up and she
# looks back. His amber eyes open, his trencadís scales ripple; he hops down
# off the fountain steps with a splash and a hiss of water onto the gravel.
# She does not run: she dashes back and plants herself between your human
# and the dragon, barking!
# EL DRAC! slams in as water arcs high into the Mediterranean sun.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.55, 0.80, 0.96)
const FEET := 640.0
const PLINTH_X := -160.0
const PLINTH_TOP := FEET - 130.0
const DRAC_K := 1.1

const JET_AT := 1.25
const CRACK_AT := 1.30
const EYES_AT := 2.05
const HOP_AT := 2.75
const DROP_AT := 3.05
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT

# Colors
const INK := IntroKit.INK
const STONE := Color(0.74, 0.68, 0.58)
const STONE_DARK := Color(0.48, 0.42, 0.35)
const STONE_LIT := Color(0.88, 0.82, 0.72)
const GRAVEL := Color(0.84, 0.76, 0.62)
const WATER := Color(0.32, 0.62, 0.74)
const FOUNTAIN_LIP := Color(0.92, 0.88, 0.80)
const EYE_AMBER := Color(1.0, 0.78, 0.22)
const EYE_PUPIL := Color(0.10, 0.08, 0.06)

# Mosaic ceramic shards
const DRAC_BLUE := Color(0.18, 0.58, 0.76)
const DRAC_CYAN := Color(0.24, 0.74, 0.82)
const DRAC_GREEN := Color(0.24, 0.70, 0.44)
const DRAC_YELLOW := Color(0.96, 0.84, 0.22)
const DRAC_ORANGE := Color(0.94, 0.52, 0.18)
const DRAC_WHITE := Color(0.94, 0.94, 0.90)

# Sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[JET_AT, "drac_jet", 1.1, -8.0],
	[CRACK_AT, "drac_click", 1.2, -8.0],
	[EYES_AT, "drac_click", 1.5, -6.0],
	[HOP_AT, "drum", 0.6, -6.0],
	[DROP_AT, "drum", 0.45, -2.0],
	[DROP_AT + 0.05, "splash", 0.8, -8.0],
	[DROP_AT + 0.1, "drac_jet", 0.9, -6.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[BOLT_AT + 0.75, "bark", 1.0, -4.0],
	[TITLE_AT, "drac_jet", 0.85, -2.0],
	[TITLE_AT + 0.05, "crack", 0.8, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 91.0), sin(t * 67.0)) * 14.0 * (1.0 - Anim.span(t, DROP_AT, DROP_AT + 0.35)) \
		if t >= DROP_AT else Vector2.ZERO
	if t >= BOLT_AT:
		return [Vector2(420.0, 440.0) + shake, Anim.k(t, [[BOLT_AT, 1.0], [TITLE_AT, 0.9, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 170.0, "io"], [3.9, 300.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 390.0, "io"], [3.9, 430.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.86, "io"], [3.9, 0.94, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y) + shake, z]


static func drac_at(t: float) -> Vector2:
	if t < HOP_AT:
		return Vector2(PLINTH_X, PLINTH_TOP)
	if t < DROP_AT:
		var f := Anim.span(t, HOP_AT, DROP_AT)
		return Vector2(lerpf(PLINTH_X, PLINTH_X + 130.0, f), lerpf(PLINTH_TOP, FEET, f * f) - sin(f * PI) * 60.0)
	return Vector2(Anim.k(t, [[DROP_AT, PLINTH_X + 130.0], [3.9, 50.0, "out"], [BOLT_AT, 30.0],
		[TITLE_AT, 20.0]]), FEET)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_terrace(c, t_real)
	_plinth(c, t)
	var awake := Anim.span(t, EYES_AT, EYES_AT + 0.25)
	var walking := t >= DROP_AT + 0.1 and t < 3.9
	var spout := Anim.span(t, JET_AT, JET_AT + 0.5) + Anim.span(t, DROP_AT + 0.1, DROP_AT + 0.6)
	drac(c, drac_at(t), DRAC_K, t_real, awake, walking, spout)
	if t >= DROP_AT and t < DROP_AT + 0.55:
		var f := Anim.span(t, DROP_AT, DROP_AT + 0.55)
		for k in range(8):
			var a := float(k) / 7.0 * PI
			IntroKit.puff(c, drac_at(t) + Vector2(cos(a) * (90.0 + f * 110.0), -sin(a) * 16.0 - 8.0), 22.0 * (1.0 - f), 1.0 - f)
	FilmKit.pair(c, t_real, FEET, true)


static func _terrace(c: CanvasItem, _t: float) -> void:
	# Noon Mediterranean sky gradient
	IntroKit.vgrad(c, Rect2(-800, -100, 2400, FEET + 100), Color(0.48, 0.76, 0.94), Color(0.86, 0.94, 0.98))
	# Distant park hill with pine trees
	var hill := PackedVector2Array([Vector2(-600, FEET - 120), Vector2(0, FEET - 220), Vector2(700, FEET - 190),
		Vector2(1400, FEET - 130), Vector2(1400, FEET), Vector2(-600, FEET)])
	c.draw_colored_polygon(hill, Color(0.38, 0.56, 0.32))
	# Trencadís undulating terrace balustrade in the background
	var bal := PackedVector2Array()
	var bal_pts := 24
	for i in range(bal_pts):
		var x := lerpf(-400.0, 1200.0, float(i) / float(bal_pts - 1))
		var y := FEET - 140.0 + sin(float(i) * 0.8) * 16.0
		bal.append(Vector2(x, y))
	c.draw_polyline(bal, STONE, 32.0)
	c.draw_polyline(bal, Color(0.92, 0.90, 0.84), 22.0)
	# Ceramic mosaic shard spots on balustrade
	for i in range(bal.size()):
		var col := DRAC_BLUE if i % 3 == 0 else (DRAC_YELLOW if i % 3 == 1 else DRAC_GREEN)
		c.draw_circle(bal[i] + Vector2(0, -2), 6.0, col)
	# Ground gravel
	c.draw_rect(Rect2(-800, FEET, 2400, 400), GRAVEL)
	c.draw_line(Vector2(-800, FEET), Vector2(1600, FEET), STONE_DARK, 4.0)


static func _plinth(c: CanvasItem, t: float) -> void:
	# Stepped grotto stone fountain with basin
	var p := Vector2(PLINTH_X, FEET)
	# 3 fountain tiers
	c.draw_rect(Rect2(p.x - 120.0, p.y - 45.0, 220.0, 45.0), STONE)
	c.draw_rect(Rect2(p.x - 100.0, p.y - 90.0, 180.0, 45.0), STONE_LIT)
	c.draw_rect(Rect2(p.x - 80.0, p.y - 135.0, 140.0, 45.0), STONE)
	c.draw_line(Vector2(p.x - 120.0, p.y - 45.0), Vector2(p.x + 100.0, p.y - 45.0), STONE_DARK, 3.0)
	c.draw_line(Vector2(p.x - 100.0, p.y - 90.0), Vector2(p.x + 80.0, p.y - 90.0), STONE_DARK, 3.0)
	# Water basin with trencadis rim
	var basin := Vector2(p.x + 30.0, p.y - 15.0)
	c.draw_circle(basin, 30.0, FOUNTAIN_LIP)
	for k in range(12):
		var a := float(k) * TAU / 12.0
		var col := DRAC_BLUE if k % 2 == 0 else DRAC_YELLOW
		c.draw_circle(basin + Vector2(cos(a), sin(a)) * 26.0, 4.0, col)
	c.draw_circle(basin, 22.0, WATER)
	# Fountain water trickle / splash
	var flow := sin(t * 18.0) * 2.0
	c.draw_line(Vector2(p.x - 10.0, p.y - 110.0), basin + Vector2(flow, -12.0), Color(0.70, 0.88, 0.96, 0.8), 4.0)


static func drac(c: CanvasItem, pos: Vector2, k: float, t: float, awake: float, walking: bool, spout: float) -> void:
	var bob := sin(t * 14.0) * 5.0 if walking else 0.0
	var bp := pos + Vector2(0.0, bob)
	# Shadow under salamander
	var sh_w := 90.0 * k
	c.draw_colored_polygon(MillieSide.ellipse(bp + Vector2(10.0, 0.0), Vector2(sh_w, 14.0 * k)), Color(0.12, 0.10, 0.08, 0.35))

	# Legs: 4 splayed lizard legs
	var leg_anim := sin(t * 14.0) if walking else 0.0
	var f_leg := bp + Vector2(35.0 * k, -20.0 * k)
	var b_leg := bp + Vector2(-35.0 * k, -20.0 * k)
	for side: float in [-1.0, 1.0]:
		var lk: float = side * 0.3 + 0.7
		var f_foot := f_leg + Vector2(25.0 * side * k + leg_anim * 12.0 * side, 20.0 * k)
		var b_foot := b_leg + Vector2(-20.0 * side * k - leg_anim * 12.0 * side, 20.0 * k)
		c.draw_line(f_leg, f_foot, INK, 12.0 * k)
		c.draw_line(f_leg, f_foot, DRAC_BLUE.darkened(0.2 * (1.0 - lk)), 8.0 * k)
		c.draw_line(b_leg, b_foot, INK, 12.0 * k)
		c.draw_line(b_leg, b_foot, DRAC_GREEN.darkened(0.2 * (1.0 - lk)), 8.0 * k)
		# Claws
		for c_off: float in [-4.0, 0.0, 4.0]:
			c.draw_line(f_foot, f_foot + Vector2(c_off * k, 5.0 * k), INK, 3.0 * k)
			c.draw_line(b_foot, b_foot + Vector2(c_off * k, 5.0 * k), INK, 3.0 * k)

	# Tail: curving upward behind him
	var tail_pts := PackedVector2Array()
	var tail_segs := 8
	var tail_wave := sin(t * 8.0) * 12.0 * k
	for i in range(tail_segs):
		var frac := float(i) / float(tail_segs - 1)
		var tx := -35.0 * k - frac * 75.0 * k
		var ty := -30.0 * k - sin(frac * PI * 0.8) * 45.0 * k + frac * tail_wave
		tail_pts.append(bp + Vector2(tx, ty))
	c.draw_polyline(tail_pts, INK, 22.0 * k)
	c.draw_polyline(tail_pts, DRAC_BLUE, 16.0 * k)
	for i in range(1, tail_pts.size() - 1):
		c.draw_circle(tail_pts[i], 5.0 * k, DRAC_YELLOW if i % 2 == 0 else DRAC_GREEN)

	# Body: arched trencadís ceramic torso
	var body_pts := PackedVector2Array([
		bp + Vector2(-45.0 * k, -25.0 * k),
		bp + Vector2(-20.0 * k, -55.0 * k),
		bp + Vector2(25.0 * k, -50.0 * k),
		bp + Vector2(50.0 * k, -28.0 * k),
		bp + Vector2(30.0 * k, -12.0 * k),
		bp + Vector2(-30.0 * k, -12.0 * k),
	])
	c.draw_colored_polygon(body_pts, INK)
	var body_inner := PackedVector2Array([
		bp + Vector2(-42.0 * k, -25.0 * k),
		bp + Vector2(-18.0 * k, -51.0 * k),
		bp + Vector2(23.0 * k, -46.0 * k),
		bp + Vector2(46.0 * k, -28.0 * k),
		bp + Vector2(28.0 * k, -15.0 * k),
		bp + Vector2(-28.0 * k, -15.0 * k),
	])
	c.draw_colored_polygon(body_inner, DRAC_CYAN)

	# Dorsal ceramic crest spikes
	for i in range(5):
		var cx := lerpf(-20.0 * k, 35.0 * k, float(i) / 4.0)
		var cy := lerpf(-53.0 * k, -40.0 * k, float(i) / 4.0)
		var spike := PackedVector2Array([
			bp + Vector2(cx - 5.0 * k, cy),
			bp + Vector2(cx, cy - 14.0 * k),
			bp + Vector2(cx + 5.0 * k, cy),
		])
		c.draw_colored_polygon(spike, DRAC_ORANGE if i % 2 == 0 else DRAC_YELLOW)

	# Trencadís mosaic scales on body
	var spots: Array[Array] = [
		[Vector2(-20.0, -32.0), DRAC_YELLOW, 6.0],
		[Vector2(-5.0, -40.0), DRAC_GREEN, 7.0],
		[Vector2(12.0, -35.0), DRAC_BLUE, 7.0],
		[Vector2(28.0, -26.0), DRAC_ORANGE, 5.0],
		[Vector2(-10.0, -22.0), DRAC_WHITE, 5.0],
		[Vector2(10.0, -20.0), DRAC_YELLOW, 6.0],
	]
	for sp: Array in spots:
		var p_off: Vector2 = sp[0]
		var col: Color = sp[1]
		var r: float = float(sp[2])
		c.draw_circle(bp + p_off * k, r * k, col)
		c.draw_arc(bp + p_off * k, r * k, 0.0, TAU, 8, INK, 1.5 * k)

	# Head: elongated blunt snout
	var hp := bp + Vector2(55.0 * k, -36.0 * k)
	var jaw_open := minf(1.0, spout * 1.5 + (0.4 if walking else 0.0))
	var snout_pts := PackedVector2Array([
		hp + Vector2(-10.0 * k, -18.0 * k),
		hp + Vector2(25.0 * k, -10.0 * k),
		hp + Vector2(34.0 * k, 2.0 * k),
		hp + Vector2(20.0 * k, 12.0 * k + jaw_open * 10.0 * k),
		hp + Vector2(-5.0 * k, 8.0 * k),
	])
	c.draw_colored_polygon(snout_pts, INK)
	var snout_inner := PackedVector2Array([
		hp + Vector2(-8.0 * k, -15.0 * k),
		hp + Vector2(23.0 * k, -8.0 * k),
		hp + Vector2(30.0 * k, 2.0 * k),
		hp + Vector2(18.0 * k, 9.0 * k + jaw_open * 8.0 * k),
		hp + Vector2(-4.0 * k, 6.0 * k),
	])
	c.draw_colored_polygon(snout_inner, DRAC_BLUE)

	# Eye: asleep lid or alert blazing amber eye
	var eye_p := hp + Vector2(6.0 * k, -8.0 * k)
	if awake <= 0.0:
		c.draw_line(eye_p + Vector2(-7.0 * k, 0.0), eye_p + Vector2(7.0 * k, 0.0), INK, 4.0 * k)
	else:
		c.draw_circle(eye_p, 10.0 * k * awake, Color(1.0, 0.85, 0.3, 0.3))
		c.draw_circle(eye_p, 7.0 * k * awake, INK)
		c.draw_circle(eye_p, 5.5 * k * awake, EYE_AMBER)
		c.draw_circle(eye_p + Vector2(1.5 * k, 0.0), 2.5 * k * awake, EYE_PUPIL)

	# Water spout / jet from mouth
	if spout > 0.0:
		var mouth := hp + Vector2(32.0 * k, 5.0 * k)
		var jet_pts := PackedVector2Array()
		for i in range(8):
			var frac := float(i) / 7.0
			var jx := mouth.x + frac * 140.0 * k
			var jy := mouth.y - sin(frac * PI * 0.9) * 35.0 * k + frac * 20.0 * k
			jet_pts.append(Vector2(jx, jy))
		c.draw_polyline(jet_pts, Color(0.85, 0.95, 1.0, 0.9 * spout), 6.0 * k)
		c.draw_polyline(jet_pts, WATER, 3.5 * k)
		for j in range(2, 7):
			c.draw_circle(jet_pts[j] + Vector2(sin(t * 20.0 + float(j)) * 6.0, 0.0), 3.0 * k, Color(0.9, 0.96, 1.0, 0.8))


static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.96, 0.92, 0.75), Color(0.20, 0.55, 0.65))
	var d := t - TITLE_AT
	drac(c, Vector2(-360.0 + d * 70.0, 1160.0), 2.2, t, 1.0, false, 1.0)
	FilmKit.slam(c, t, "EL DRAC!", Vector2(660, 200))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.98, 0.90))
