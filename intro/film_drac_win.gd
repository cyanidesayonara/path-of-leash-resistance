class_name FilmDracWin
extends RefCounted

# Park Güell / El Mosaic victory film, "El Drac del Mosaic":
# The celebratory payoff scene after settling the mosaic salamander boss.
# High noon at Park Güell by the grand staircase:
# The stepped grotto fountain, trencadís balustrades, and the salamander
# having slid down the steps onto the landing.
# The dog trots up, reaches out, and boops his colorful snout with a bark!
# A burst of sparks: his amber eye lights up, content.
# He slithers cheerfully back up the steps and perches on the fountain plinth.
# From the plinth, he shoots a glorious celebratory water fountain arching high
# into the Mediterranean sun, creating a sparkling rainbow mist!
# Your human catches up, smiling warmly.
# Trencadís mosaic sparkles drift down, and the celebratory title card slams in:
# EL DRAC! / VICTÒRIA AL MOSAIC / EL MOSAIC IS YOURS.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.55, 0.80, 0.96)
const FEET := 640.0
const PLINTH_X := 160.0
const PLINTH_TOP := FEET - 130.0
const DRAC_SLIDE_X := 520.0
const DRAC_K := 1.05

# Timing beats
const BOOP_AT := 1.3
const STAND_AT := 1.9
const CLIMB_AT := 2.4
const ON_PLINTH_AT := 3.2
const FOUNTAIN_AT := 3.4
const HUMAN_STOP := 2.2
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

const DRAC_BLUE := Color(0.18, 0.58, 0.76)
const DRAC_CYAN := Color(0.24, 0.74, 0.82)
const DRAC_GREEN := Color(0.24, 0.70, 0.44)
const DRAC_YELLOW := Color(0.96, 0.84, 0.22)
const DRAC_ORANGE := Color(0.94, 0.52, 0.18)
const DRAC_WHITE := Color(0.94, 0.94, 0.90)

# Sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.2, "whoop", 1.0, -6.0],
	[BOOP_AT, "bark", 1.25, -2.0],
	[BOOP_AT + 0.05, "star", 1.1, -2.0],
	[CLIMB_AT, "drac_click", 1.2, -6.0],
	[ON_PLINTH_AT, "drum", 0.5, -2.0],
	[ON_PLINTH_AT + 0.1, "splash", 0.9, -6.0],
	[FOUNTAIN_AT, "drac_jet", 1.1, -2.0],
	[3.8, "whoop", 1.2, -3.0],
	[4.3, "whoop", 1.3, -4.0],
	[4.7, "bark", 1.35, -3.0],
	[TITLE_AT, "drac_jet", 0.9, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 89.0), sin(t * 67.0)) * 10.0 * (1.0 - Anim.span(t, ON_PLINTH_AT, ON_PLINTH_AT + 0.35)) \
		if t >= ON_PLINTH_AT else Vector2.ZERO
	if t < STAND_AT:
		return [Vector2(620.0, 460.0), 0.98]
	elif t < ON_PLINTH_AT:
		var f := Anim.span(t, STAND_AT, ON_PLINTH_AT)
		return [Vector2(lerpf(620.0, 460.0, f), lerpf(460.0, 390.0, f)) + shake, lerpf(0.98, 0.88, f)]
	else:
		var f := Anim.span(t, ON_PLINTH_AT, TITLE_AT)
		return [Vector2(lerpf(460.0, 490.0, f), 390.0) + shake, lerpf(0.88, 0.84, f)]


static func drac_at(t: float) -> Vector2:
	if t < CLIMB_AT:
		return Vector2(DRAC_SLIDE_X, FEET)
	elif t < ON_PLINTH_AT:
		var f := Anim.span(t, CLIMB_AT, ON_PLINTH_AT)
		var x := lerpf(DRAC_SLIDE_X, PLINTH_X, f)
		var y := lerpf(FEET, PLINTH_TOP, f * f) - sin(f * PI) * 32.0
		return Vector2(x, y)
	else:
		return Vector2(PLINTH_X, PLINTH_TOP)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_terrace(c, t_real)
	_plinth(c, t)

	var awake := Anim.span(t, BOOP_AT, BOOP_AT + 0.25)
	var walking := t >= CLIMB_AT and t < ON_PLINTH_AT
	var spout := Anim.span(t, FOUNTAIN_AT, FOUNTAIN_AT + 1.2) if t >= FOUNTAIN_AT else 0.0

	var dpos := drac_at(t)
	var face: float = -1.0 if (t >= CLIMB_AT and t < ON_PLINTH_AT) else 1.0
	var snout_tip := drac_figure(c, dpos, DRAC_K, t_real, awake, walking, spout, face)

	# Water fountain & rainbow
	if t_real >= FOUNTAIN_AT:
		_fountain(c, t_real, snout_tip)
		_rainbow(c, t_real, snout_tip)

	_dog(c, t_real, snout_tip)
	_human(c, t_real)

	# Boop spark ring at the snout tip
	if t_real >= BOOP_AT and t_real < BOOP_AT + 0.6:
		_boop_spark(c, t_real, snout_tip)

	if t_real >= FOUNTAIN_AT:
		_sparkles(c, t_real)

	FilmKit.fades(c, t_real)


static func _terrace(c: CanvasItem, _t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1000.0 + 200.0), Color(0.48, 0.76, 0.94), Color(0.86, 0.94, 0.98))
	# Distant park hill with pine trees
	var hill := PackedVector2Array([Vector2(-1200, FEET - 120), Vector2(0, FEET - 220), Vector2(800, FEET - 190),
		Vector2(2000, FEET - 130), Vector2(2000, FEET), Vector2(-1200, FEET)])
	c.draw_colored_polygon(hill, Color(0.38, 0.56, 0.32))
	# Trencadís undulating terrace balustrade
	var bal := PackedVector2Array()
	var bal_pts := 32
	for i in range(bal_pts):
		var x := lerpf(-800.0, 1800.0, float(i) / float(bal_pts - 1))
		var y := FEET - 140.0 + sin(float(i) * 0.7) * 16.0
		bal.append(Vector2(x, y))
	c.draw_polyline(bal, STONE, 32.0)
	c.draw_polyline(bal, Color(0.92, 0.90, 0.84), 22.0)
	for i in range(bal.size()):
		var col := DRAC_BLUE if i % 3 == 0 else (DRAC_YELLOW if i % 3 == 1 else DRAC_GREEN)
		c.draw_circle(bal[i] + Vector2(0, -2), 6.0, col)
	c.draw_rect(Rect2(-1600, FEET, 4600, 600.0), GRAVEL)
	c.draw_line(Vector2(-1600, FEET), Vector2(3000, FEET), STONE_DARK, 4.0)


static func _plinth(c: CanvasItem, t: float) -> void:
	var p := Vector2(PLINTH_X, FEET)
	c.draw_rect(Rect2(p.x - 120.0, p.y - 45.0, 240.0, 45.0), STONE)
	c.draw_rect(Rect2(p.x - 100.0, p.y - 90.0, 200.0, 45.0), STONE_LIT)
	c.draw_rect(Rect2(p.x - 80.0, p.y - 135.0, 160.0, 45.0), STONE)
	c.draw_line(Vector2(p.x - 120.0, p.y - 45.0), Vector2(p.x + 120.0, p.y - 45.0), STONE_DARK, 3.0)
	c.draw_line(Vector2(p.x - 100.0, p.y - 90.0), Vector2(p.x + 100.0, p.y - 90.0), STONE_DARK, 3.0)
	var basin := Vector2(p.x + 30.0, p.y - 15.0)
	c.draw_circle(basin, 30.0, FOUNTAIN_LIP)
	for k in range(12):
		var a := float(k) * TAU / 12.0
		var col := DRAC_BLUE if k % 2 == 0 else DRAC_YELLOW
		c.draw_circle(basin + Vector2(cos(a), sin(a)) * 26.0, 4.0, col)
	c.draw_circle(basin, 22.0, WATER)
	var flow := sin(t * 18.0) * 2.0
	c.draw_line(Vector2(p.x - 10.0, p.y - 110.0), basin + Vector2(flow, -12.0), Color(0.70, 0.88, 0.96, 0.8), 4.0)


static func drac_figure(c: CanvasItem, pos: Vector2, k: float, t: float, awake: float, walking: bool, spout: float, face: float) -> Vector2:
	var bob := sin(t * 14.0) * 4.0 if walking else 0.0
	var bp := pos + Vector2(0.0, bob)
	var sh_w := 80.0 * k
	c.draw_colored_polygon(MillieSide.ellipse(bp + Vector2(10.0 * face, 0.0), Vector2(sh_w, 12.0 * k)), Color(0.12, 0.10, 0.08, 0.30))

	# Legs
	var leg_anim := sin(t * 14.0) if walking else 0.0
	var f_leg := bp + Vector2(30.0 * face * k, -18.0 * k)
	var b_leg := bp + Vector2(-30.0 * face * k, -18.0 * k)
	for side: float in [-1.0, 1.0]:
		var lk: float = side * 0.3 + 0.7
		var f_foot := f_leg + Vector2(20.0 * side * k + leg_anim * 10.0 * side, 18.0 * k)
		var b_foot := b_leg + Vector2(-18.0 * side * k - leg_anim * 10.0 * side, 18.0 * k)
		c.draw_line(f_leg, f_foot, INK, 11.0 * k)
		c.draw_line(f_leg, f_foot, DRAC_BLUE.darkened(0.2 * (1.0 - lk)), 7.0 * k)
		c.draw_line(b_leg, b_foot, INK, 11.0 * k)
		c.draw_line(b_leg, b_foot, DRAC_GREEN.darkened(0.2 * (1.0 - lk)), 7.0 * k)

	# Tail
	var tail_pts := PackedVector2Array()
	var tail_wave := sin(t * 8.0) * 10.0 * k
	for i in range(8):
		var frac := float(i) / 7.0
		var tx := -30.0 * face * k - frac * 70.0 * face * k
		var ty := -25.0 * k - sin(frac * PI * 0.8) * 40.0 * k + frac * tail_wave
		tail_pts.append(bp + Vector2(tx, ty))
	c.draw_polyline(tail_pts, INK, 20.0 * k)
	c.draw_polyline(tail_pts, DRAC_BLUE, 14.0 * k)

	# Body
	var body_pts := PackedVector2Array([
		bp + Vector2(-40.0 * face * k, -22.0 * k),
		bp + Vector2(-15.0 * face * k, -48.0 * k),
		bp + Vector2(22.0 * face * k, -44.0 * k),
		bp + Vector2(45.0 * face * k, -25.0 * k),
		bp + Vector2(25.0 * face * k, -10.0 * k),
		bp + Vector2(-25.0 * face * k, -10.0 * k),
	])
	c.draw_colored_polygon(body_pts, INK)
	var body_inner := PackedVector2Array([
		bp + Vector2(-37.0 * face * k, -22.0 * k),
		bp + Vector2(-14.0 * face * k, -44.0 * k),
		bp + Vector2(20.0 * face * k, -40.0 * k),
		bp + Vector2(40.0 * face * k, -24.0 * k),
		bp + Vector2(23.0 * face * k, -12.0 * k),
		bp + Vector2(-23.0 * face * k, -12.0 * k),
	])
	c.draw_colored_polygon(body_inner, DRAC_CYAN)

	# Dorsal crest
	for i in range(5):
		var cx := lerpf(-15.0 * face * k, 30.0 * face * k, float(i) / 4.0)
		var cy := lerpf(-46.0 * k, -36.0 * k, float(i) / 4.0)
		var spike := PackedVector2Array([
			bp + Vector2(cx - 4.0 * k, cy),
			bp + Vector2(cx, cy - 12.0 * k),
			bp + Vector2(cx + 4.0 * k, cy),
		])
		c.draw_colored_polygon(spike, DRAC_ORANGE if i % 2 == 0 else DRAC_YELLOW)

	# Scales
	var spots: Array[Array] = [
		[Vector2(-15.0, -28.0), DRAC_YELLOW, 5.0],
		[Vector2(-2.0, -35.0), DRAC_GREEN, 6.0],
		[Vector2(10.0, -30.0), DRAC_BLUE, 6.0],
		[Vector2(24.0, -22.0), DRAC_ORANGE, 5.0],
	]
	for sp: Array in spots:
		var p_off: Vector2 = sp[0]
		var col: Color = sp[1]
		var r: float = float(sp[2])
		c.draw_circle(bp + Vector2(p_off.x * face, p_off.y) * k, r * k, col)

	# Head
	var hp := bp + Vector2(48.0 * face * k, -32.0 * k)
	var snout_pts := PackedVector2Array([
		hp + Vector2(-8.0 * face * k, -15.0 * k),
		hp + Vector2(22.0 * face * k, -8.0 * k),
		hp + Vector2(28.0 * face * k, 2.0 * k),
		hp + Vector2(16.0 * face * k, 10.0 * k),
		hp + Vector2(-4.0 * face * k, 6.0 * k),
	])
	c.draw_colored_polygon(snout_pts, INK)
	var snout_inner := PackedVector2Array([
		hp + Vector2(-6.0 * face * k, -13.0 * k),
		hp + Vector2(20.0 * face * k, -6.0 * k),
		hp + Vector2(25.0 * face * k, 2.0 * k),
		hp + Vector2(14.0 * face * k, 8.0 * k),
		hp + Vector2(-3.0 * face * k, 5.0 * k),
	])
	c.draw_colored_polygon(snout_inner, DRAC_BLUE)

	var eye_p := hp + Vector2(5.0 * face * k, -6.0 * k)
	c.draw_circle(eye_p, 8.0 * k * awake, Color(1.0, 0.85, 0.3, 0.3))
	c.draw_circle(eye_p, 6.0 * k * awake, INK)
	c.draw_circle(eye_p, 4.5 * k * awake, EYE_AMBER)
	c.draw_circle(eye_p + Vector2(1.0 * face * k, 0.0), 2.0 * k * awake, EYE_PUPIL)

	return hp + Vector2(26.0 * face * k, 0.0)


static func _dog(c: CanvasItem, t: float, tip: Vector2) -> void:
	var dx: float = Anim.k(t, [[0.0, 720.0], [BOOP_AT, 580.0, "out"], [STAND_AT, 580.0], [TITLE_AT, 620.0]])
	var trot := 1.0 - Anim.span(t, BOOP_AT - 0.2, BOOP_AT)
	var wag := sin(t * 16.0) * 0.6 if t >= BOOP_AT else 0.0
	var pose := {
		"lean": 0.15, "crouch": 0.1, "reach": sin(t * 12.0) * 0.4 * trot,
		"push": -sin(t * 12.0) * 0.4 * trot, "ear": 1.1, "tail": 0.6 + wag,
		"mouth": 0.4 if t >= BOOP_AT else 0.1, "brow": 0.3,
	}
	var mpos := Vector2(dx, FEET)
	IntroKit.millie(c, mpos, FilmKit.S * 0.92, -1.0, Vector2.ONE, pose, FEET)


static func _human(c: CanvasItem, t: float) -> void:
	var hx: float = Anim.k(t, [[0.0, 920.0], [HUMAN_STOP, 800.0, "out"], [TITLE_AT, 800.0]])
	var stride := t * 6.0 if t < HUMAN_STOP else 0.0
	var hpose := {
		"stride": stride, "stride_amp": 0.4 if t < HUMAN_STOP else 0.0,
		"phone": 0.4, "glow": 0.0, "reach": 0.2, "lean": 0.05, "head": -0.1,
	}
	IntroKit.human(c, Vector2(hx, FEET), FilmKit.S, -1.0, Vector2.ONE, hpose, 0.0, FEET)


static func _boop_spark(c: CanvasItem, t: float, p: Vector2) -> void:
	var f := Anim.span(t, BOOP_AT, BOOP_AT + 0.5)
	var r := f * 42.0
	c.draw_circle(p, r, Color(1.0, 0.95, 0.50, (1.0 - f) * 0.45))
	for k in range(8):
		var a := float(k) * TAU / 8.0
		var sp := p + Vector2(cos(a), sin(a)) * (r + 8.0)
		c.draw_circle(sp, 3.5 * (1.0 - f), Color(1.0, 0.92, 0.35, 1.0 - f))


static func _fountain(c: CanvasItem, t: float, tip: Vector2) -> void:
	var dt := t - FOUNTAIN_AT
	var f := clampf(dt / 0.4, 0.0, 1.0)
	var jet_pts := PackedVector2Array()
	for i in range(12):
		var frac := float(i) / 11.0
		var jx := tip.x + frac * 220.0
		var jy := tip.y - sin(frac * PI * 0.85) * 160.0 * f + frac * frac * 60.0
		jet_pts.append(Vector2(jx, jy))
	c.draw_polyline(jet_pts, Color(0.88, 0.96, 1.0, 0.9), 8.0)
	c.draw_polyline(jet_pts, WATER, 4.5)
	for j in range(2, 11):
		c.draw_circle(jet_pts[j] + Vector2(sin(t * 18.0 + float(j)) * 8.0, 0.0), 4.0, Color(0.92, 0.98, 1.0, 0.85))


static func _rainbow(c: CanvasItem, t: float, tip: Vector2) -> void:
	var dt := t - FOUNTAIN_AT
	var f := clampf(Anim.span(dt, 0.2, 0.6) * (1.0 - Anim.span(t, TITLE_AT - 0.2, TITLE_AT)), 0.0, 1.0) * 0.35
	var arc_center := tip + Vector2(110.0, -20.0)
	var r_colors: Array[Color] = [
		Color(0.96, 0.30, 0.30), Color(0.96, 0.62, 0.22), Color(0.96, 0.90, 0.24),
		Color(0.28, 0.82, 0.40), Color(0.22, 0.68, 0.96), Color(0.62, 0.32, 0.92)
	]
	for i in range(r_colors.size()):
		var col: Color = r_colors[i]
		c.draw_arc(arc_center, 100.0 + float(i) * 6.0, -PI * 0.85, -PI * 0.15, 32,
			Color(col.r, col.g, col.b, f), 4.5)


static func _sparkles(c: CanvasItem, t: float) -> void:
	var dt := t - FOUNTAIN_AT
	var cols: Array[Color] = [DRAC_BLUE, DRAC_YELLOW, DRAC_ORANGE, DRAC_GREEN, DRAC_WHITE]
	for i in range(28):
		var seed_i := float(i) * 107.3
		var cx := fmod(seed_i * 19.3, 1280.0)
		var cy := fmod(seed_i * 31.7 + dt * (100.0 + sin(seed_i) * 35.0), 720.0)
		var col: Color = cols[i % cols.size()]
		c.draw_circle(Vector2(cx, cy), 3.0 + sin(dt * 6.0 + seed_i) * 1.5, Color(col.r, col.g, col.b, 0.75))


static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(0.96, 0.98, 0.88), Color(0.35, 0.65, 0.72))
	var d := t - TITLE_AT
	drac_figure(c, Vector2(-360.0 + d * 50.0, 1180.0), 1.9, t, 1.0, false, 1.0, 1.0)
	FilmKit.slam(c, t, "EL DRAC!", Vector2(640, 210))
	IntroTitle.word(c, "VICTORIA AL MOSAIC", Vector2(640, 410), 46)
	IntroTitle.word(c, "EL MOSAIC IS YOURS", Vector2(640, 480), 30)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.98, 0.90))
