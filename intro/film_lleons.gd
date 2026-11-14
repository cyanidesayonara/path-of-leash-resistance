class_name FilmLleons
extends RefCounted

# El Port's film, "Els Lleons": the wake of the two bronze lions at the foot
# of the Columbus column (docs/BOSSES.md), played as she first passes them
# (systems/boss_lleons.gd), before the walk's own wake. The harbour at dusk,
# side on: the sun going down into Port Vell, masts, Montjuic, the quay's
# lamps coming up, and the iron column on its stone base with a lion lying on
# a plinth either side, face to face. The two of them walk past, your human
# on the phone. A creak of bronze: her ears go up and she looks back. One
# lion yawns, a century wide; the other blinks. They look at each other.
# Then, together, at her. They rise, drop off their plinths with a thump that
# shakes the quay, and come on shoulder to shoulder. She does not run: she
# dashes back and plants herself between your human and them, barking.
# ELS LLEONS! slams in, both of them roaring.
#
# lion(), harbour(), monument() and plinth() are shared with the win film.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const LENGTH := FilmKit.LENGTH
const BG := Color(0.20, 0.18, 0.40)
const FEET := 640.0
const HORIZON := 330.0
const QUAY := 470.0
const COLUMN_X := -280.0
const PLINTH_A := -570.0
const PLINTH_B := 10.0
const PLINTH_TOP := FEET - 140.0
const PLINTH_W := 430.0
const LION_K := 0.9
const YAWN_AT := 1.75            # the left lion yawns
const BLINK_AT := 2.15           # the right lion blinks
const EACH_AT := 2.6             # they look at each other
const HER_AT := 3.0              # then at her, and get up
const STEP_AT := 3.35            # off the plinths
const DROP_AT := 3.65            # on the quay: the thump
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const INK := IntroKit.INK
# the casts: near-black bronze, verdigris down every hollow, bright metal
# only where a century of hands reach
const BRONZE_DEEP := Color(0.17, 0.13, 0.10)
const BRONZE_DARK := Color(0.29, 0.22, 0.14)
const BRONZE := Color(0.43, 0.33, 0.19)
const BRONZE_LIT := Color(0.62, 0.48, 0.26)
const BRONZE_SHINE := Color(0.93, 0.78, 0.44)
const PATINA_DARK := Color(0.18, 0.34, 0.30)
const PATINA := Color(0.36, 0.58, 0.49)
const SUNSET := Color(1.0, 0.62, 0.34)
const MOUTH := Color(0.38, 0.09, 0.08)
const TONGUE := Color(0.78, 0.30, 0.26)
const FANG := Color(0.96, 0.92, 0.80)
const EYE_AMBER := Color(1.0, 0.80, 0.26)
const STONE := Color(0.60, 0.50, 0.52)
const STONE_LIT := Color(0.80, 0.64, 0.56)
const STONE_DARK := Color(0.40, 0.32, 0.40)
const PAVING := Color(0.50, 0.41, 0.44)
const IRON := Color(0.16, 0.14, 0.20)
const LAMPS: Array[float] = [-1010.0, 520.0, 1330.0]
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "gat_clang", 0.55, -9.0],
	[YAWN_AT, "lion_roar", 0.65, -9.0],
	[BLINK_AT, "chime", 1.3, -10.0],
	[EACH_AT, "gat_clang", 0.9, -9.0],
	[HER_AT, "crack", 1.1, -8.0],
	[STEP_AT, "grunt", 0.7, -6.0],
	[DROP_AT, "drum", 0.35, 0.0],
	[DROP_AT + 0.08, "drum", 0.45, -2.0],
	[DROP_AT + 0.05, "ooooh", 0.9, -9.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[BOLT_AT + 0.75, "bark", 1.0, -4.0],
	[TITLE_AT, "lion_roar", 1.0, -1.0],
	[TITLE_AT + 0.12, "lion_roar", 0.84, -3.0],
]


# the camera: on the pair; a pan back to the column when she looks round,
# held as they wake, look and get down; her stare; wide on the stand-off
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 87.0), sin(t * 61.0)) * 16.0 * (1.0 - Anim.span(t, DROP_AT, DROP_AT + 0.4)) \
		if t >= DROP_AT else Vector2.ZERO
	if t >= BOLT_AT:
		return [Vector2(220.0, 420.0) + shake, Anim.k(t, [[BOLT_AT, 0.92], [TITLE_AT, 0.85, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, -200.0, "io"], [3.9, -80.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 400.0, "io"], [3.9, 430.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.8, "io"], [3.9, 0.86, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y) + shake, z]


# where a lion's feet are: on his plinth, the drop, then across the quay.
# The left one (`a`) comes up behind the right one's shoulder.
static func lion_at(t: float, a: bool) -> Vector2:
	var home := PLINTH_A if a else PLINTH_B
	var land := home + 110.0
	var stop := -310.0 if a else 80.0
	var back := -18.0 if a else 0.0
	if t < STEP_AT:
		return Vector2(home, PLINTH_TOP)
	if t < DROP_AT:
		var f := Anim.span(t, STEP_AT, DROP_AT)
		return Vector2(lerpf(home, land, f), lerpf(PLINTH_TOP, FEET + back, f * f) - sin(f * PI) * 46.0)
	return Vector2(Anim.k(t, [[DROP_AT, land], [3.95, stop, "out"], [TITLE_AT, stop + 14.0]]), FEET + back)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	harbour(c, t_real, LAMPS, PackedFloat32Array([1.0, 1.0, 1.0]))
	monument(c, COLUMN_X)
	plinth(c, PLINTH_A, PLINTH_TOP, PLINTH_W)
	plinth(c, PLINTH_B, PLINTH_TOP, PLINTH_W)
	var up := Anim.span(t, HER_AT + 0.05, STEP_AT)
	var walking := t >= DROP_AT + 0.08 and t < 3.95
	var roar := Anim.span(t, BOLT_AT + 0.25, BOLT_AT + 0.45) * (0.75 + 0.25 * absf(sin(t_real * 9.0)))
	var each := Anim.span(t, EACH_AT, EACH_AT + 0.12) * (1.0 - Anim.span(t, HER_AT, HER_AT + 0.1))
	var her := Anim.span(t, HER_AT, HER_AT + 0.12)
	# asleep their eyes are shut; awake they wander, snap to each other, then to her
	var look := Vector2(0.2, -0.5).lerp(Vector2(1.0, -0.1), each).lerp(Vector2(1.0, 0.55), her)
	if t >= DROP_AT:
		look = Vector2(1.0, 0.25)
	# the left one: the yawn, and his eyes open at the end of it
	var a_yawn := Anim.span(t, YAWN_AT, YAWN_AT + 0.3) * (1.0 - Anim.span(t, YAWN_AT + 0.5, YAWN_AT + 0.75))
	var a := {
		"up": up, "jaw": maxf(a_yawn, roar), "eye": Anim.span(t, YAWN_AT + 0.5, YAWN_AT + 0.65),
		"look": look, "walking": walking, "brow": each - her - (1.0 if t >= DROP_AT else 0.0),
		"tilt": -0.28 * a_yawn + 0.10 * each, "swish": Anim.span(t, YAWN_AT, HER_AT),
	}
	# the right one: one eye-blink awake, facing the other until they turn on her
	var b_eye := Anim.span(t, BLINK_AT, BLINK_AT + 0.07) * (1.0 - Anim.span(t, BLINK_AT + 0.13, BLINK_AT + 0.17)) \
		+ Anim.span(t, BLINK_AT + 0.21, BLINK_AT + 0.29)
	var b := {
		"up": up, "jaw": roar, "eye": clampf(b_eye, 0.0, 1.0),
		"look": look, "walking": walking, "brow": each - her - (1.0 if t >= DROP_AT else 0.0),
		"tilt": 0.10 * each, "swish": Anim.span(t, BLINK_AT, HER_AT),
	}
	var b_face := -1.0 if t < HER_AT + 0.16 else 1.0
	lion(c, lion_at(t, true), LION_K, 1.0, t_real, a)
	lion(c, lion_at(t, false), LION_K, b_face, t_real + 1.3, b)
	if t >= DROP_AT and t < DROP_AT + 0.6:
		var f := Anim.span(t, DROP_AT, DROP_AT + 0.6)
		for who: bool in [true, false]:
			for k in range(7):
				var ang := float(k) / 6.0 * PI
				IntroKit.puff(c, lion_at(t, who) + Vector2(cos(ang) * (130.0 + f * 150.0), -sin(ang) * 18.0 - 8.0), 24.0 * (1.0 - f), 1.0 - f)
	FilmKit.pair(c, t_real, FEET, true)
	FilmKit.fades(c, t_real)


# The harbour at dusk: the sky going from indigo down to a band of fire, the
# sun half into the water, Montjuic and its castle, the far quays' windows,
# Port Vell with the sun's road across it and boats at their moorings, the
# quay's edge with its bollards and chain, and the lamps (`lamp_on`, one
# strength per lamp in `lamp_xs`).
static func harbour(c: CanvasItem, t: float, lamp_xs: Array[float], lamp_on: PackedFloat32Array) -> void:
	IntroKit.vgrad(c, Rect2(-1800.0, -1200.0, 5000.0, 1260.0), Color(0.20, 0.18, 0.40), Color(0.60, 0.31, 0.50))
	IntroKit.vgrad(c, Rect2(-1800.0, 60.0, 5000.0, HORIZON - 60.0), Color(0.60, 0.31, 0.50), Color(1.0, 0.68, 0.38))
	var sun := Vector2(960.0, HORIZON - 6.0)
	var gb := ShapeBatch.new(c)
	gb.glow(sun, 520.0, Color(1.0, 0.80, 0.50, 0.55))
	gb.glow(sun, 200.0, Color(1.0, 0.92, 0.70, 0.75))
	gb.flush()
	c.draw_circle(sun, 52.0, Color(1.0, 0.95, 0.78))
	# clouds, lit from under
	for i in range(7):
		var cx := -1400.0 + float(i) * 470.0 + sin(float(i) * 2.3) * 90.0 + t * 6.0
		var cy := 40.0 + fposmod(float(i) * 73.0, 170.0)
		var cw := 190.0 + fposmod(float(i) * 57.0, 120.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx, cy), Vector2(cw, 16.0)), Color(0.50, 0.28, 0.46, 0.75))
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(cx + 14.0, cy + 7.0), Vector2(cw * 0.86, 8.0)), Color(1.0, 0.62, 0.42, 0.8))
	# two gulls going home
	for i in range(2):
		var gp := Vector2(-500.0 + float(i) * 190.0 + t * 46.0, 150.0 + float(i) * 34.0 + sin(t * 2.0 + float(i)) * 6.0)
		var flap := sin(t * 9.0 + float(i) * 2.0) * 9.0
		c.draw_polyline(PackedVector2Array([gp + Vector2(-18.0, -flap), gp, gp + Vector2(18.0, -flap)]), Color(0.24, 0.16, 0.30), 3.5)
	# Montjuic, the castle on its top
	var hill := PackedVector2Array([Vector2(-1800.0, HORIZON)])
	for i in range(13):
		var f := float(i) / 12.0
		hill.append(Vector2(-1800.0 + f * 1500.0, HORIZON - 34.0 - sin(f * PI) * 128.0 - sin(f * 9.0) * 7.0))
	hill.append(Vector2(-300.0, HORIZON))
	c.draw_colored_polygon(hill, Color(0.33, 0.21, 0.40))
	c.draw_rect(Rect2(-1130.0, HORIZON - 186.0, 150.0, 26.0), Color(0.33, 0.21, 0.40))
	c.draw_rect(Rect2(-1090.0, HORIZON - 204.0, 34.0, 20.0), Color(0.33, 0.21, 0.40))
	# the far quays: sheds and blocks, a few windows lit
	for i in range(18):
		var bx := -260.0 + float(i) * 190.0
		var bh := 22.0 + fposmod(float(i) * 37.0, 34.0)
		c.draw_rect(Rect2(bx, HORIZON - bh, 176.0, bh + 2.0), Color(0.36, 0.23, 0.40))
		for w in range(3):
			if (i + w) % 3 != 0:
				c.draw_rect(Rect2(bx + 24.0 + float(w) * 50.0, HORIZON - bh + 8.0, 8.0, 6.0), Color(1.0, 0.82, 0.48, 0.9))
	# the water: the sky in it, the sun's road, the small chop
	IntroKit.vgrad(c, Rect2(-1800.0, HORIZON, 5000.0, QUAY - HORIZON), Color(0.99, 0.63, 0.40), Color(0.23, 0.24, 0.46))
	for i in range(13):
		var ry := HORIZON + 6.0 + float(i) * 10.5
		var half := (26.0 + float(i) * 13.0) * (0.72 + 0.28 * sin(t * 3.2 + float(i) * 1.9))
		c.draw_line(Vector2(sun.x - half, ry), Vector2(sun.x + half, ry), Color(1.0, 0.90, 0.62, 0.78 - float(i) * 0.04), 4.0)
	for i in range(34):
		var wx := -1700.0 + float(i) * 150.0 + sin(t * 0.8 + float(i)) * 12.0
		var wy := HORIZON + 22.0 + float(i % 4) * 30.0
		c.draw_line(Vector2(wx, wy), Vector2(wx + 54.0, wy), Color(1.0, 0.78, 0.60, 0.34), 3.0)
	# boats at their moorings, dark against it
	for i in range(4):
		var bx := -1250.0 + float(i) * 640.0 + fposmod(float(i) * 211.0, 150.0)
		var by := HORIZON + 84.0 + sin(t * 1.6 + float(i) * 1.4) * 3.0
		var tip := sin(t * 1.6 + float(i) * 1.4) * 0.03
		var dark := Color(0.20, 0.15, 0.30)
		c.draw_colored_polygon(PackedVector2Array([Vector2(bx - 82.0, by - 16.0), Vector2(bx + 96.0, by - 16.0),
			Vector2(bx + 66.0, by + 14.0), Vector2(bx - 62.0, by + 14.0)]), dark)
		c.draw_rect(Rect2(bx - 82.0, by - 20.0, 178.0, 6.0), Color(0.86, 0.60, 0.48))
		var top := Vector2(bx + 6.0, by - 16.0) + Vector2.UP.rotated(tip) * 200.0
		c.draw_line(Vector2(bx + 6.0, by - 16.0), top, dark, 5.0)
		c.draw_line(top, Vector2(bx + 92.0, by - 18.0), Color(dark, 0.7), 2.0)
		c.draw_line(top, Vector2(bx - 78.0, by - 18.0), Color(dark, 0.7), 2.0)
		c.draw_line(Vector2(bx + 6.0, by - 44.0), Vector2(bx + 80.0, by - 40.0), Color(0.90, 0.80, 0.74), 9.0)
		c.draw_line(Vector2(bx - 60.0, by + 20.0), Vector2(bx + 64.0, by + 20.0), Color(0.16, 0.14, 0.30, 0.5), 5.0)
	# the quay: its stone edge, the paving, the joints between the slabs
	IntroKit.vgrad(c, Rect2(-1800.0, QUAY + 14.0, 5000.0, 900.0), PAVING, PAVING.darkened(0.30))
	c.draw_rect(Rect2(-1800.0, QUAY, 5000.0, 16.0), STONE_LIT)
	c.draw_rect(Rect2(-1800.0, QUAY + 16.0, 5000.0, 5.0), STONE_DARK)
	for row in range(4):
		var jy := QUAY + 52.0 + float(row) * 62.0
		c.draw_line(Vector2(-1800.0, jy), Vector2(3200.0, jy), Color(0.32, 0.25, 0.32, 0.5), 2.0)
		for i in range(26):
			var jx := -1760.0 + float(i) * 190.0 + float(row % 2) * 95.0
			c.draw_line(Vector2(jx, jy), Vector2(jx, jy + 62.0), Color(0.32, 0.25, 0.32, 0.35), 2.0)
	# bollards and the chain slung between them
	for i in range(16):
		var bx := -1700.0 + float(i) * 300.0
		var sag := PackedVector2Array()
		for k in range(9):
			var f := float(k) / 8.0
			sag.append(Vector2(bx + f * 300.0, QUAY - 26.0 + sin(f * PI) * 22.0))
		c.draw_polyline(sag, IRON, 4.0)
		c.draw_line(Vector2(bx, QUAY + 4.0), Vector2(bx, QUAY - 26.0), IRON, 18.0)
		c.draw_circle(Vector2(bx, QUAY - 30.0), 12.0, IRON)
		c.draw_line(Vector2(bx - 4.0, QUAY - 2.0), Vector2(bx - 4.0, QUAY - 24.0), Color(0.86, 0.52, 0.40, 0.7), 3.0)
	for i in range(lamp_xs.size()):
		_lamp(c, lamp_xs[i], lamp_on[i] if i < lamp_on.size() else 0.0)


# a quay lamp: an iron post, a curled arm either side, a lantern on each
static func _lamp(c: CanvasItem, x: float, on: float) -> void:
	var top := 196.0
	c.draw_line(Vector2(x, QUAY + 30.0), Vector2(x, top), IRON, 12.0)
	c.draw_rect(Rect2(x - 16.0, QUAY + 6.0, 32.0, 28.0), IRON)
	c.draw_circle(Vector2(x, top - 8.0), 9.0, IRON)
	var gb := ShapeBatch.new(c)
	for sd: float in [-1.0, 1.0]:
		var arm := PackedVector2Array()
		for k in range(8):
			var f := float(k) / 7.0
			arm.append(Vector2(x + sd * (f * 56.0), top + 26.0 - sin(f * PI * 0.5) * 30.0 + f * f * 22.0))
		c.draw_polyline(arm, IRON, 6.0)
		var lp := Vector2(x + sd * 56.0, top + 34.0)
		c.draw_colored_polygon(PackedVector2Array([lp + Vector2(-13.0, 0.0), lp + Vector2(13.0, 0.0),
			lp + Vector2(9.0, 30.0), lp + Vector2(-9.0, 30.0)]), IRON)
		c.draw_colored_polygon(PackedVector2Array([lp + Vector2(-9.0, 4.0), lp + Vector2(9.0, 4.0),
			lp + Vector2(6.0, 26.0), lp + Vector2(-6.0, 26.0)]), Color(0.42, 0.36, 0.40).lerp(Color(1.0, 0.92, 0.66), on))
		if on > 0.0:
			gb.glow(lp + Vector2(0.0, 14.0), 150.0, Color(1.0, 0.84, 0.52, 0.55 * on))
			gb.glow(Vector2(x + sd * 56.0, QUAY + 60.0), 190.0, Color(1.0, 0.80, 0.50, 0.16 * on))
	gb.flush()


# The monument's foot: the stepped stone base, the pedestal with its bronze
# relief, and the fluted iron column going up out of shot.
static func monument(c: CanvasItem, x: float) -> void:
	var step := Rect2(x - 300.0, FEET - 46.0, 600.0, 56.0)
	c.draw_rect(step.grow(4.0), INK)
	c.draw_rect(step, STONE)
	c.draw_rect(Rect2(step.position, Vector2(step.size.x, 12.0)), STONE_LIT)
	var ped := Rect2(x - 170.0, 150.0, 340.0, FEET - 46.0 - 150.0)
	c.draw_rect(ped.grow(4.0), INK)
	c.draw_rect(ped, STONE)
	c.draw_rect(Rect2(ped.position.x + ped.size.x * 0.62, ped.position.y, ped.size.x * 0.38, ped.size.y), STONE_LIT.lerp(STONE, 0.4))
	c.draw_rect(Rect2(ped.position.x, ped.position.y, 70.0, ped.size.y), STONE_DARK.lerp(STONE, 0.45))
	for cy: float in [ped.position.y, ped.position.y + 150.0, ped.end.y - 30.0]:
		c.draw_rect(Rect2(ped.position.x - 14.0, cy - 4.0, ped.size.x + 28.0, 26.0), INK)
		c.draw_rect(Rect2(ped.position.x - 10.0, cy, ped.size.x + 20.0, 18.0), STONE_LIT)
	# the relief: a caravel in bronze
	var rel := Rect2(x - 110.0, ped.position.y + 196.0, 220.0, 150.0)
	c.draw_rect(rel.grow(5.0), INK)
	c.draw_rect(rel, BRONZE_DARK)
	c.draw_rect(Rect2(rel.position + Vector2(8.0, 8.0), rel.size - Vector2(16.0, 16.0)), PATINA_DARK.lerp(BRONZE_DARK, 0.4))
	var rc := rel.get_center() + Vector2(0.0, 26.0)
	c.draw_colored_polygon(PackedVector2Array([rc + Vector2(-66.0, -6.0), rc + Vector2(70.0, -12.0),
		rc + Vector2(48.0, 22.0), rc + Vector2(-48.0, 22.0)]), BRONZE)
	c.draw_line(rc + Vector2(0.0, -6.0), rc + Vector2(0.0, -84.0), BRONZE, 5.0)
	c.draw_colored_polygon(PackedVector2Array([rc + Vector2(4.0, -80.0), rc + Vector2(52.0, -50.0), rc + Vector2(4.0, -22.0)]), BRONZE_LIT)
	c.draw_colored_polygon(PackedVector2Array([rc + Vector2(-4.0, -70.0), rc + Vector2(-40.0, -44.0), rc + Vector2(-4.0, -24.0)]), BRONZE_LIT.darkened(0.15))
	for k in range(3):
		c.draw_line(rc + Vector2(-80.0 + float(k) * 56.0, 34.0), rc + Vector2(-44.0 + float(k) * 56.0, 34.0), PATINA, 3.0)
	# the column: its ring, and the fluted shaft, lit down the sunset side
	c.draw_rect(Rect2(x - 92.0, 104.0, 184.0, 50.0), INK)
	c.draw_rect(Rect2(x - 88.0, 108.0, 176.0, 42.0), BRONZE_DARK)
	c.draw_rect(Rect2(x - 88.0, 108.0, 176.0, 10.0), BRONZE)
	c.draw_rect(Rect2(x - 70.0, -1200.0, 140.0, 1306.0), INK)
	c.draw_rect(Rect2(x - 66.0, -1200.0, 132.0, 1306.0), IRON.lerp(BRONZE_DARK, 0.5))
	for k in range(6):
		var fx := x - 56.0 + float(k) * 22.0
		c.draw_rect(Rect2(fx, -1200.0, 8.0, 1306.0), Color(0.12, 0.10, 0.14, 0.55))
	c.draw_rect(Rect2(x + 44.0, -1200.0, 14.0, 1306.0), Color(SUNSET, 0.55))


# a lion's corner plinth, its top at `top`
static func plinth(c: CanvasItem, x: float, top: float, w: float) -> void:
	var r := Rect2(x - w * 0.5, top, w, FEET - top + 10.0)
	c.draw_rect(r.grow(4.0), INK)
	c.draw_rect(r, STONE)
	c.draw_rect(Rect2(r.position.x + r.size.x * 0.7, r.position.y, r.size.x * 0.3, r.size.y), STONE_LIT.lerp(STONE, 0.45))
	c.draw_rect(Rect2(r.position - Vector2(10.0, 0.0), Vector2(r.size.x + 20.0, 20.0)), INK)
	c.draw_rect(Rect2(r.position - Vector2(6.0, -3.0), Vector2(r.size.x + 12.0, 14.0)), STONE_LIT)
	c.draw_rect(Rect2(Vector2(r.position.x - 8.0, FEET - 18.0), Vector2(r.size.x + 16.0, 22.0)), STONE_DARK)
	var plaque := Rect2(x - 56.0, top + 50.0, 112.0, 38.0)
	c.draw_rect(plaque, BRONZE_DEEP)
	c.draw_rect(plaque.grow(-3.0), BRONZE)
	for ly: float in [13.0, 24.0]:
		c.draw_line(Vector2(plaque.position.x + 14.0, plaque.position.y + ly), Vector2(plaque.end.x - 14.0, plaque.position.y + ly), BRONZE_DEEP, 2.5)


# where his head is, in his own frame, for a pose
static func _head_c(o: Dictionary) -> Vector2:
	var up: float = o.get("up", 0.0)
	var sit: float = o.get("sit", 0.0)
	var dip: float = o.get("dip", 0.0)
	return Vector2(112.0, -162.0).lerp(Vector2(136.0, -252.0), up).lerp(Vector2(60.0, -290.0), sit) + Vector2(40.0, 110.0) * dip


# where the tip of his nose is, for a boop
static func nose_at(at: Vector2, k: float, face: float, o: Dictionary) -> Vector2:
	var v := _head_c(o) + Vector2(86.0, 4.0)
	return at + Vector2(v.x * face, v.y) * k


# A lion side on, facing `face`, his feet (or his belly, lying) at `at`.
# The pose `o`: `up` 0 lying like a sphinx to 1 on his feet, `sit` 1 sat on
# his haunches, `dip` his head lowered to her, `jaw` open, `eye` open, `look`
# where the pupil sits, `brow` raised (+) or drawn down (-), `happy` eyes
# shut in a smile, `walking`, `tilt` the head thrown back (-), `swish` how
# much the tail is alive.
static func lion(c: CanvasItem, at: Vector2, k: float, face: float, t: float, o: Dictionary) -> void:
	var up: float = o.get("up", 0.0)
	var sit: float = o.get("sit", 0.0)
	var jaw: float = o.get("jaw", 0.0)
	var eye: float = o.get("eye", 0.0)
	var look: Vector2 = o.get("look", Vector2.ZERO)
	var brow: float = o.get("brow", 0.0)
	var happy: bool = o.get("happy", false)
	var walking: bool = o.get("walking", false)
	var tilt: float = o.get("tilt", 0.0)
	var swish: float = o.get("swish", 0.0)
	var p := func(v: Vector2) -> Vector2: return at + Vector2(v.x * face, v.y) * k
	var pose := func(lie: Vector2, stand: Vector2, sat: Vector2) -> Vector2: return lie.lerp(stand, up).lerp(sat, sit)
	var down := 1.0 - up * (1.0 - sit)      # 1 lying or sat, 0 on his feet
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(-10.0 * face, 4.0) * k, Vector2(lerpf(190.0, 220.0, down), 15.0) * k), Color(0.08, 0.05, 0.14, 0.38))

	var rump: Vector2 = pose.call(Vector2(-82.0, -62.0), Vector2(-88.0, -168.0), Vector2(-70.0, -74.0))
	var rump_r := lerpf(lerpf(58.0, 56.0, up), 68.0, sit)
	var chest: Vector2 = pose.call(Vector2(70.0, -86.0), Vector2(74.0, -176.0), Vector2(22.0, -190.0))
	var chest_r := 60.0
	var hc := _head_c(o)

	# the tail: lying it trails off the plinth and curls; up, it is carried high
	var tail := PackedVector2Array()
	for i in range(10):
		var f := float(i) / 9.0
		var lie := Vector2(-128.0 - f * 96.0, -34.0 + f * 16.0 - f * f * f * 54.0)
		var high := Vector2(-134.0 - sin(f * 2.7) * 62.0, -176.0 - f * 118.0)
		var curl := Vector2(-126.0 - sin(f * PI) * 62.0, -16.0 - f * 12.0)
		var tv := lie.lerp(high, up).lerp(curl, sit)
		tv.y += sin(t * 5.0 + f * 3.0) * 16.0 * f * swish
		tail.append(p.call(tv))
	c.draw_polyline(tail, INK, 24.0 * k)
	c.draw_polyline(tail, BRONZE_DARK, 16.0 * k)
	var tuft: Vector2 = tail[9]
	var tuft_rot := (tail[9] - tail[8]).angle()
	c.draw_colored_polygon(MillieSide.ellipse(tuft, Vector2(32.0, 20.0) * k, tuft_rot), INK)
	c.draw_colored_polygon(MillieSide.ellipse(tuft, Vector2(27.0, 15.0) * k, tuft_rot), PATINA_DARK)
	c.draw_line(tuft - Vector2.from_angle(tuft_rot) * 14.0 * k, tuft + Vector2.from_angle(tuft_rot) * 18.0 * k, PATINA, 3.0 * k)

	# legs: hip and paw for each, the far pair first and darker
	var hips: Array[Vector2] = [
		pose.call(Vector2(-98.0, -44.0), Vector2(-74.0, -140.0), Vector2(-86.0, -50.0)),
		pose.call(Vector2(54.0, -46.0), Vector2(60.0, -140.0), Vector2(14.0, -150.0)),
		pose.call(Vector2(-80.0, -44.0), Vector2(-98.0, -140.0), Vector2(-70.0, -50.0)),
		pose.call(Vector2(72.0, -46.0), Vector2(84.0, -140.0), Vector2(36.0, -150.0)),
	]
	var feet: Array[Vector2] = [
		pose.call(Vector2(-34.0, -16.0), Vector2(-68.0, -4.0), Vector2(-36.0, -14.0)),
		pose.call(Vector2(148.0, -16.0), Vector2(60.0, -4.0), Vector2(24.0, -4.0)),
		pose.call(Vector2(-6.0, -16.0), Vector2(-102.0, -4.0), Vector2(-8.0, -14.0)),
		pose.call(Vector2(176.0, -16.0), Vector2(92.0, -4.0), Vector2(50.0, -4.0)),
	]
	if walking:
		for i in range(4):
			var ph: float = t * 9.0 + float([0.0, PI, PI, 0.0][i])
			feet[i] += Vector2(sin(ph) * 30.0, -maxf(0.0, cos(ph)) * 16.0)
	for i in range(4):
		if i == 2:
			_body(c, p, rump, rump_r, chest, chest_r, k, down)
		var near := i >= 2
		var col := BRONZE_DARK if near else BRONZE_DEEP.lerp(PATINA_DARK, 0.35)
		var hip: Vector2 = hips[i]
		var foot: Vector2 = feet[i]
		var hind := i % 2 == 0
		if hind and near:
			# the haunch: a great round thigh, folded when he is down
			var hr := lerpf(36.0, 50.0, down)
			var hcn: Vector2 = hip + Vector2(-6.0, -18.0 - 14.0 * down)
			c.draw_circle(p.call(hcn), (hr + 5.0) * k, INK)
			c.draw_circle(p.call(hcn), hr * k, col)
			c.draw_circle(p.call(hcn + Vector2(-6.0, -8.0)), hr * 0.62 * k, BRONZE)
		# on his feet the leg bends: the hock back, the wrist a little forward
		var bend := Vector2(-26.0, 10.0) if hind else Vector2(9.0, 0.0)
		var knee: Vector2 = hip.lerp(foot, 0.58) + bend * (1.0 - down)
		var leg := PackedVector2Array([p.call(hip), p.call(knee), p.call(foot)])
		c.draw_polyline(leg, INK, 48.0 * k)
		c.draw_circle(p.call(hip), 30.0 * k, INK)
		c.draw_circle(p.call(knee), 24.0 * k, INK)
		c.draw_polyline(leg, col, 39.0 * k)
		c.draw_circle(p.call(hip), 25.5 * k, col)
		c.draw_circle(p.call(knee), 19.5 * k, col)
		if near:
			c.draw_polyline(PackedVector2Array([p.call(hip + Vector2(-7.0, 0.0)), p.call(knee + Vector2(-7.0, -4.0)),
				p.call(knee.lerp(foot, 0.7) + Vector2(-7.0, -4.0))]), BRONZE, 12.0 * k)
		var paw: Vector2 = foot + Vector2(12.0, 2.0)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(paw), Vector2(36.0, 20.0) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(paw), Vector2(31.0, 15.0) * k), col.lightened(0.06))
		for n in range(3):
			var tx := 6.0 + float(n) * 10.0
			c.draw_line(p.call(paw + Vector2(tx, -3.0)), p.call(paw + Vector2(tx + 3.0, 10.0)), INK, 3.0 * k)
		if near:
			c.draw_colored_polygon(MillieSide.ellipse(p.call(paw + Vector2(12.0, -6.0)), Vector2(12.0, 4.0) * k), BRONZE_SHINE)

	_head(c, p, hc, k, face, t, jaw, eye, look, brow, happy, tilt)


# the trunk of him: rump, barrel and chest as one outline, verdigris run
# down it, the low sun along his back
static func _body(c: CanvasItem, p: Callable, rump: Vector2, rump_r: float, chest: Vector2, chest_r: float,
		k: float, _down: float) -> void:
	var waist := minf(rump_r, chest_r) * 0.86
	c.draw_line(p.call(rump), p.call(chest), INK, (waist * 2.0 + 10.0) * k)
	c.draw_circle(p.call(rump), (rump_r + 5.0) * k, INK)
	c.draw_circle(p.call(chest), (chest_r + 5.0) * k, INK)
	c.draw_line(p.call(rump), p.call(chest), BRONZE_DARK, waist * 2.0 * k)
	c.draw_circle(p.call(rump), rump_r * k, BRONZE_DARK)
	c.draw_circle(p.call(chest), chest_r * k, BRONZE_DARK)
	# the belly, green where the rain never dries
	var under := Vector2(0.0, waist * 0.55)
	c.draw_line(p.call(rump + under), p.call(chest + under), PATINA_DARK, waist * 0.7 * k)
	# the back, lit
	var over := Vector2(0.0, -waist * 0.42)
	c.draw_line(p.call(rump + over), p.call(chest + over), BRONZE, waist * 0.75 * k)
	c.draw_circle(p.call(rump + Vector2(-4.0, -rump_r * 0.3)), rump_r * 0.56 * k, BRONZE)
	c.draw_line(p.call(rump + Vector2(0.0, -waist * 0.78)), p.call(chest + Vector2(-10.0, -waist * 0.78)), BRONZE_LIT, 7.0 * k)
	c.draw_line(p.call(rump + Vector2(-10.0, -waist * 0.90)), p.call(chest + Vector2(-20.0, -waist * 0.90)), Color(SUNSET, 0.55), 3.5 * k)
	# verdigris runs, and the ribs under them
	for i in range(5):
		var f := 0.12 + float(i) * 0.17
		var top: Vector2 = rump.lerp(chest, f) + Vector2(0.0, -waist * 0.30)
		var run_len := waist * (0.9 + 0.3 * sin(float(i) * 2.1))
		c.draw_line(p.call(top), p.call(top + Vector2(-6.0, run_len)), Color(PATINA, 0.70), 7.0 * k)
		c.draw_line(p.call(top + Vector2(9.0, run_len * 0.2)), p.call(top + Vector2(5.0, run_len * 0.75)), Color(PATINA, 0.4), 4.0 * k)


# the mane and the face in it
static func _head(c: CanvasItem, p: Callable, hc_in: Vector2, k: float, face: float, t: float, jaw: float, eye: float,
		look: Vector2, brow: float, happy: bool, tilt: float) -> void:
	# the head thrown back or nodded: everything turns about the neck
	var neck := hc_in + Vector2(-40.0, 30.0)
	var hp := func(v: Vector2) -> Vector2: return p.call(neck + (hc_in + v - neck).rotated(tilt))
	var mc := Vector2(-30.0, 10.0)
	var mr := 80.0
	# the ruff: pointed locks from under the chin, round the back, to the brow
	var n := 13
	var locks: Array = []
	for i in range(n):
		var a := PI * (0.40 + 1.16 * float(i) / float(n - 1))
		var d := Vector2.from_angle(a)
		var tip := mc + d * (mr + 17.0 + float(i % 2) * 9.0 + jaw * 8.0 + sin(t * 30.0 + float(i)) * jaw * 2.0) + Vector2(-8.0, 12.0)
		locks.append([mc + Vector2.from_angle(a - 0.27) * (mr - 6.0), tip, mc + Vector2.from_angle(a + 0.27) * (mr - 6.0)])
	# the bib: locks hanging down the chest
	for i in range(4):
		var bx := -6.0 - float(i) * 26.0
		locks.append([Vector2(bx + 22.0, 64.0), Vector2(bx - 4.0, 132.0 - float(i) * 12.0 + float(i % 2) * 14.0), Vector2(bx - 26.0, 60.0)])
	for l: Array in locks:
		var cen: Vector2 = (l[0] + l[1] + l[2]) / 3.0
		var grown := PackedVector2Array()
		for v: Vector2 in l:
			grown.append(hp.call(cen + (v - cen) * 1.0 + (v - cen).normalized() * 7.0))
		c.draw_colored_polygon(grown, INK)
	c.draw_circle(hp.call(mc), (mr + 5.0) * k, INK)
	for i in range(locks.size()):
		var l: Array = locks[i]
		c.draw_colored_polygon(PackedVector2Array([hp.call(l[0]), hp.call(l[1]), hp.call(l[2])]),
			PATINA_DARK if i % 2 == 0 else BRONZE_DARK)
	c.draw_circle(hp.call(mc), mr * k, BRONZE_DARK)
	c.draw_circle(hp.call(mc + Vector2(-8.0, -12.0)), (mr - 16.0) * k, BRONZE)
	# the cuts between the locks, and the light on their crowns
	for i in range(n):
		var a := PI * (0.40 + 1.16 * float(i) / float(n - 1))
		var d := Vector2.from_angle(a + 0.14)
		c.draw_line(hp.call(mc + d * 34.0), hp.call(mc + d * (mr - 2.0) + Vector2(-4.0, 8.0)), INK, 4.0 * k)
		var d2 := Vector2.from_angle(a - 0.10)
		var lit := d2.y < -0.2
		c.draw_line(hp.call(mc + d2 * 44.0), hp.call(mc + d2 * (mr - 10.0)), BRONZE_LIT if lit else PATINA, (5.0 if lit else 4.0) * k)
	# the ear
	var ear := Vector2(-16.0, -42.0)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(ear), Vector2(19.0, 22.0) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(ear), Vector2(14.0, 17.0) * k), BRONZE)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(ear + Vector2(3.0, 3.0)), Vector2(7.0, 10.0) * k), BRONZE_DEEP)

	# the lower jaw swings from under the ear; the mouth is behind the muzzle
	var hinge := Vector2(14.0, 26.0)
	var swing := jaw * 0.62
	var jp := func(v: Vector2) -> Vector2: return hp.call(hinge + v.rotated(swing))
	if jaw > 0.03:
		c.draw_colored_polygon(PackedVector2Array([hp.call(hinge + Vector2(-6.0, -8.0)), hp.call(Vector2(84.0, 22.0)),
			jp.call(Vector2(62.0, 6.0)), jp.call(Vector2(0.0, 14.0))]), MOUTH)
		c.draw_colored_polygon(MillieSide.ellipse(jp.call(Vector2(36.0, 0.0)), Vector2(26.0, 9.0) * k, swing * face), TONGUE)
	c.draw_colored_polygon(MillieSide.ellipse(jp.call(Vector2(30.0, 12.0)), Vector2(38.0, 16.0) * k, swing * face), INK)
	c.draw_colored_polygon(MillieSide.ellipse(jp.call(Vector2(30.0, 12.0)), Vector2(33.0, 11.5) * k, swing * face), BRONZE)
	c.draw_colored_polygon(PackedVector2Array([jp.call(Vector2(-2.0, 22.0)), jp.call(Vector2(14.0, 54.0)), jp.call(Vector2(24.0, 20.0))]), BRONZE_DARK)
	if jaw > 0.15:
		c.draw_colored_polygon(PackedVector2Array([jp.call(Vector2(48.0, 4.0)), jp.call(Vector2(53.0, -16.0 * jaw - 4.0)), jp.call(Vector2(59.0, 4.0))]), FANG)

	# skull and muzzle
	c.draw_circle(hp.call(Vector2.ZERO), 53.0 * k, INK)
	c.draw_circle(hp.call(Vector2.ZERO), 48.0 * k, BRONZE)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(-6.0, -20.0)), Vector2(34.0, 20.0) * k), BRONZE_LIT.lerp(BRONZE, 0.3))
	var mz := Vector2(48.0, 6.0)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(mz), Vector2(42.0, 29.0) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(mz), Vector2(37.0, 24.0) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(mz + Vector2(-4.0, -9.0)), Vector2(24.0, 9.0) * k), BRONZE_SHINE.lerp(BRONZE_LIT, 0.45))
	c.draw_line(hp.call(Vector2(66.0, -14.0)), hp.call(Vector2(88.0, -4.0)), Color(SUNSET, 0.7), 3.0 * k)
	if jaw > 0.15:
		c.draw_colored_polygon(PackedVector2Array([hp.call(Vector2(66.0, 24.0)), hp.call(Vector2(72.0, 24.0 + 22.0 * jaw + 6.0)), hp.call(Vector2(79.0, 22.0))]), FANG)
	# the nose, rubbed bright; the lip; the whisker pits
	c.draw_colored_polygon(MillieSide.ellipse(hp.call(Vector2(82.0, -4.0)), Vector2(13.0, 11.0) * k), INK)
	c.draw_circle(hp.call(Vector2(80.0, -8.0)), 4.0 * k, BRONZE_SHINE)
	if jaw <= 0.03:
		var lip := PackedVector2Array([hp.call(Vector2(84.0, 8.0)), hp.call(Vector2(70.0, 20.0)), hp.call(Vector2(46.0, 24.0)),
			hp.call(Vector2(28.0, 18.0 - (8.0 if happy else 0.0)))])
		c.draw_polyline(lip, INK, 4.0 * k)
	for w in range(3):
		c.draw_circle(hp.call(Vector2(46.0 + float(w) * 11.0, 8.0 + float(w % 2) * 6.0)), 2.6 * k, BRONZE_DEEP)

	# the eye under its brow
	var ep := Vector2(22.0, -14.0)
	if happy:
		c.draw_polyline(PackedVector2Array([hp.call(ep + Vector2(-13.0, 4.0)), hp.call(ep + Vector2(0.0, -6.0)), hp.call(ep + Vector2(13.0, 4.0))]), INK, 5.0 * k)
	elif eye <= 0.03:
		c.draw_line(hp.call(ep + Vector2(-13.0, 0.0)), hp.call(ep + Vector2(13.0, 3.0)), INK, 5.0 * k)
	else:
		var gb := ShapeBatch.new(c)
		gb.glow(hp.call(ep), 46.0 * k * eye, Color(1.0, 0.76, 0.26, 0.6))
		gb.flush()
		c.draw_colored_polygon(MillieSide.ellipse(hp.call(ep), Vector2(15.0, 13.0 * eye) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(hp.call(ep), Vector2(11.5, 9.5 * eye) * k), EYE_AMBER)
		c.draw_circle(hp.call(ep + Vector2(look.x * 5.0, look.y * 4.0 * eye)), 4.6 * k * minf(1.0, eye + 0.3), INK)
		c.draw_circle(hp.call(ep + Vector2(look.x * 5.0 - 2.0, look.y * 4.0 * eye - 2.0)), 1.6 * k, Color(1.0, 0.98, 0.9))
	if not happy:
		var lift := brow * 9.0
		c.draw_line(hp.call(ep + Vector2(-20.0, -18.0 - lift)), hp.call(ep + Vector2(18.0, -10.0 - lift * 1.4 + minf(brow, 0.0) * -6.0)), INK, 7.0 * k)


# the card: the last of the sunset behind ELS LLEONS!, a lion coming in from
# either side, both roaring, eyes alight
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(1.0, 0.70, 0.40), Color(0.34, 0.18, 0.42))
	var d := t - TITLE_AT
	var o := {"up": 1.0, "jaw": 0.8 + 0.2 * absf(sin(t * 11.0)), "eye": 1.0, "look": Vector2(1.0, -0.2), "brow": -1.0,
		"tilt": -0.12, "swish": 1.0}
	lion(c, Vector2(-190.0 + d * 50.0, 1080.0), 2.1, 1.0, t, o)
	lion(c, Vector2(1470.0 - d * 50.0, 1080.0), 2.1, -1.0, t + 0.7, o)
	FilmKit.slam(c, t, "ELS LLEONS!", Vector2(640, 200))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
