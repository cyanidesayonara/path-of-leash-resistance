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
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 380.0, "io"], [3.9, 420.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.82, "io"], [3.9, 0.92, "io"], [4.2, 1.7, "io"]])
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
	mamut(c, mamut_at(t), MAMUT_K, t_real, awake, walking, trunk, ear)
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
	var bx := -620.0
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


# The mammoth side on, facing right, his feet at `at`: a domed, shaggy body
# on four column legs, the high head with its small ear, the long curved
# tusk and the trunk. `awake` opens his eye; `walking` swings the legs;
# `trunk` curls the trunk up; `ear` twitches the ear. Shared with the card.
static func mamut(c: CanvasItem, at: Vector2, k: float, t: float, awake: float, walking: bool,
		trunk: float, ear := 0.0) -> void:
	var p := func(v: Vector2) -> Vector2: return at + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(0, 4) * k, Vector2(230, 16) * k), Color(0, 0, 0, 0.35))
	# legs, the far pair darker, thick as columns
	for i in range(4):
		var hip: Vector2 = [Vector2(-130, -100), Vector2(90, -100), Vector2(-96, -100), Vector2(124, -100)][i]
		var swing := sin(t * 5.0 + float(i) * 1.6) * 0.18 if walking else 0.0
		var foot: Vector2 = hip + Vector2.from_angle(PI * 0.5 + swing) * 96.0
		var col := STONE_DARK if i < 2 else STONE
		c.draw_line(p.call(hip), p.call(foot), INK, 100.0 * k)
		c.draw_line(p.call(hip), p.call(foot), col, 92.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot), Vector2(50, 16) * k), col.darkened(0.1))
		for n in range(3):
			c.draw_circle(p.call(foot + Vector2(-24.0 + float(n) * 24.0, -6.0)), 8.0 * k, TUSK.darkened(0.15))
	# the body: a domed back, the shaggy fringe hanging under it
	var bc := Vector2(-10, -230)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(226, 156) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(220, 150) * k), STONE)
	for i in range(16):
		var fx := -200.0 + float(i) * 27.0
		var fy := -100.0 + absf(float(i) - 7.5) * 5.0
		c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(fx - 18, fy - 40)), p.call(Vector2(fx + 18, fy - 40)),
			p.call(Vector2(fx + 4, fy + 8 + float(i % 3) * 8.0))]), FUR.darkened(0.08))
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(-40, -70)), Vector2(130, 56) * k), STONE_LIT)
	for i in range(7):
		var sx := -150.0 + float(i) * 45.0
		c.draw_line(p.call(bc + Vector2(sx, -60)), p.call(bc + Vector2(sx + 10, 40)), FUR.darkened(0.15), 4.0 * k)
	c.draw_circle(p.call(bc + Vector2(70, -40)), 14.0 * k, Color(0.40, 0.52, 0.30, 0.6))
	# the head, high and domed, and the small ear
	var hc := Vector2(200, -320)
	c.draw_circle(p.call(hc), 104.0 * k, INK)
	c.draw_circle(p.call(hc), 98.0 * k, STONE)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(-10, -50)), Vector2(70, 40) * k), STONE_LIT)
	var ec := hc + Vector2(-50, 10)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(ec), Vector2(34, 46 + ear * 6.0) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(ec), Vector2(28, 40 + ear * 6.0) * k), FUR)
	# the eye: shut, a stone lid; awake, amber under a heavy brow
	var eye := hc + Vector2(40, -14)
	if awake <= 0.0:
		c.draw_line(p.call(eye + Vector2(-14, 0)), p.call(eye + Vector2(14, 2)), INK, 5.0 * k)
	else:
		c.draw_circle(p.call(eye), 24.0 * k * awake, Color(1.0, 0.78, 0.3, 0.25))
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye), Vector2(13, 11 * awake) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(eye), Vector2(10, 8 * awake) * k), EYE_AMBER)
		c.draw_circle(p.call(eye + Vector2(2, 0)), 4.0 * k, INK)
		c.draw_line(p.call(eye + Vector2(-18, -20)), p.call(eye + Vector2(18, -12)), INK, 6.0 * k)
	# the tusk: out, down and curling up again
	var tusk := PackedVector2Array()
	for i in range(10):
		var f := float(i) / 9.0
		tusk.append(p.call(hc + Vector2(60.0 + f * 150.0, 60.0 + sin(f * PI * 0.9) * 90.0 - f * f * 150.0)))
	c.draw_polyline(tusk, INK, 26.0 * k)
	c.draw_polyline(tusk, TUSK, 18.0 * k)
	# the trunk: hanging and curled at the tip, or raised high to trumpet
	var trunk_pts := PackedVector2Array()
	for i in range(12):
		var f := float(i) / 11.0
		var hang := Vector2(80.0 + f * 40.0 + sin(f * PI) * 20.0, 60.0 + f * 220.0 - f * f * 40.0)
		var up := Vector2(80.0 + f * 160.0, 40.0 - f * 260.0 + f * f * 60.0)
		trunk_pts.append(p.call(hc + hang.lerp(up, trunk)))
	c.draw_polyline(trunk_pts, INK, 50.0 * k)
	c.draw_polyline(trunk_pts, STONE, 42.0 * k)
	for i in range(2, 11, 2):
		c.draw_circle(trunk_pts[i], 6.0 * k, STONE_DARK)


# the card: the lawn gone gold behind EL MAMUT!, his head filling the frame
# from the left, trunk raised, eye blazing
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.92, 0.96, 0.82), Color(0.42, 0.58, 0.40))
	var d := t - TITLE_AT
	mamut(c, Vector2(-430.0 + d * 80.0, 1240.0), 2.2, t, 1.0, false, 1.0)
	FilmKit.slam(c, t, "EL MAMUT!", Vector2(660, 200))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.98, 0.90))
