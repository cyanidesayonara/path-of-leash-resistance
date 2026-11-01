class_name FilmGracia
extends RefCounted

# Festa de Gràcia's film, "Correfoc": the telegraph to run as the walk turns
# for home (systems/home_chase.gd plays it through intro/film_player.gd).
# Night in a narrow street of the vila in festival week, side on: low houses
# with balconies, bunting and paper lanterns strung across. The two of them
# heading home, your human on the phone. A drum booms and a banger cracks:
# her ears go up and she looks back. Round the corner come the fire devils,
# the walk's line seen side on, red and black with horned hoods, each with a
# fork of fireworks held high spraying a fountain of sparks; behind them the
# Drac de Gràcia on its bearers' legs, wings up, breathing sparks. A push in
# on her face. She spins, digs in and bolts; the leash snaps taut, your human
# is yanked off after her, and RUN! slams in with the Drac's jaws spraying
# fire across the card.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.06, 0.05, 0.10)
const FEET := 640.0              # the street the pair walks on
const CORNER_X := -120.0         # the corner the correfoc comes round
const OUT_AT := 2.3              # the first devil rounds the corner
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const DEVIL_K := 1.4
const DRAC_K := 1.7
# the walk's colours (entities/correfoc_threat.gd)
const DEVIL_RED := Color(0.85, 0.18, 0.14)
const DEVIL_BLACK := Color(0.12, 0.12, 0.15)
const DEVIL_HORN := Color(0.92, 0.88, 0.60)
const DRAGON_GREEN := Color(0.22, 0.56, 0.28)
const DRAGON_BELLY := Color(0.78, 0.72, 0.35)
const DRAGON_EYE := Color(0.95, 0.25, 0.15)
const SPARK_YELLOW := Color(0.98, 0.94, 0.40)
const SPARK_ORANGE := Color(0.96, 0.52, 0.12)
const DRUM_WOOD := Color(0.55, 0.38, 0.22)
const SKIN := Color(0.90, 0.72, 0.58)
const INK := IntroKit.INK
# the devils, as the walk's line seen side on: [x behind the lead, far rank,
# order round the corner]
const DEVILS := [[-300.0, true, 3], [-110.0, true, 1], [-390.0, false, 4], [-200.0, false, 2], [0.0, false, 0]]
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "drum", 0.8, -4.0],
	[1.45, "cracker", 1.0, -6.0],
	[1.90, "drum", 0.8, -4.0],
	[OUT_AT, "cracker", 0.9, -4.0],
	[OUT_AT + 0.15, "cracker", 1.2, -6.0],
	[2.70, "drum", 0.8, -4.0],
	[3.10, "roar", 0.7, -6.0],
	[3.50, "cracker", 1.1, -6.0],
	[4.55, "whistle", 1.3, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "cracker", 0.6, -2.0],
]


# the camera: [centre, zoom]. On the pair; a pan back down the street when she
# looks round, held as the devils and the Drac come on; a whip to a close-up
# of her; a cut wide on the bolt that runs right with them; the card.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 220.0, "io"], [3.9, 340.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 430.0, "io"], [3.9, 440.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.88, "io"], [3.9, 0.96, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# where the lead devil's feet are; the line and the Drac come on behind
static func lead_x(t: float) -> float:
	return Anim.k(t, [[OUT_AT, CORNER_X], [3.9, 120.0, "out"], [BOLT_AT, 220.0], [TITLE_AT, 1350.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_street(c, t_real)
	if t_real >= OUT_AT:
		_correfoc(c, Anim.twos(t_real), t_real)
	_corner(c)
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


# the vila at night: a deep blue sky, the low houses with their balconies and
# lit windows, bunting and paper lanterns across the street, the glow of the
# correfoc coming up the street before it shows
static func _street(c: CanvasItem, t: float) -> void:
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(-1600, -900.0 + f * 1000.0, 4600, 130.0), Color(0.08, 0.08, 0.20).lerp(Color(0.22, 0.14, 0.28), f))
	var wall := Color(0.66, 0.50, 0.40)
	c.draw_rect(Rect2(-1600, -60, 4600, FEET - 40.0 + 60.0), wall.darkened(0.35))
	var x := -1500.0
	var k := 0
	while x < 2800.0:
		var w := 260.0
		var tone := wall.darkened(0.25 + 0.12 * float(k % 3))
		c.draw_rect(Rect2(x, -20.0 - float(k % 2) * 60.0, w - 6.0, FEET - 20.0 + float(k % 2) * 60.0), tone)
		for fl in range(2):
			var wy := 60.0 + float(fl) * 220.0
			var win := Rect2(x + 70.0, wy, 110.0, 150.0)
			c.draw_rect(win.grow(6.0), tone.darkened(0.25))
			c.draw_rect(win, Color(1.0, 0.82, 0.48) if (k + fl) % 3 != 1 else Color(0.18, 0.16, 0.22))
			# a balcony, its rail and a flag hung over it
			c.draw_rect(Rect2(x + 54.0, wy + 150.0, 142.0, 10.0), INK)
			for r in range(6):
				c.draw_line(Vector2(x + 60.0 + float(r) * 26.0, wy + 110.0), Vector2(x + 60.0 + float(r) * 26.0, wy + 150.0), INK, 3.0)
			c.draw_line(Vector2(x + 54.0, wy + 110.0), Vector2(x + 196.0, wy + 110.0), INK, 4.0)
			if (k + fl) % 2 == 0:
				for s in range(4):
					c.draw_rect(Rect2(x + 100.0 + float(s) * 12.0, wy + 112.0, 12.0, 60.0),
						Color(0.95, 0.80, 0.20) if s % 2 == 0 else Color(0.80, 0.16, 0.16))
		x += w
		k += 1
	# the correfoc's glow, up the street on the left, flickering, before it shows
	var glow := Anim.span(t, FilmKit.HEAR_AT, OUT_AT) * (0.6 + 0.4 * sin(t * 23.0) * sin(t * 7.0))
	if glow > 0.0:
		for r in range(4):
			c.draw_circle(Vector2(CORNER_X - 300.0, FEET - 200.0), 200.0 + float(r) * 90.0, Color(1.0, 0.55, 0.15, 0.10 * glow))
	# bunting and lanterns strung across
	for line_y: float in [-40.0, 120.0]:
		var xx := -1500.0
		var i := 0
		while xx < 2800.0:
			var y0 := line_y + sin(xx * 0.004) * 30.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(xx, y0), Vector2(xx + 40.0, y0), Vector2(xx + 20.0, y0 + 40.0)]),
				[Color(0.95, 0.80, 0.20), Color(0.80, 0.16, 0.16), Color(0.25, 0.50, 0.85), Color(0.30, 0.70, 0.35)][i % 4])
			if i % 5 == 2:
				c.draw_circle(Vector2(xx + 20.0, y0 + 70.0), 22.0, Color(1.0, 0.70, 0.30, 0.9))
				c.draw_circle(Vector2(xx + 20.0, y0 + 70.0), 34.0, Color(1.0, 0.70, 0.30, 0.18))
			xx += 52.0
			i += 1
		c.draw_line(Vector2(-1600, line_y), Vector2(3000, line_y), Color(0.2, 0.2, 0.22), 2.0)
	# the street
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), Color(0.36, 0.34, 0.38))
	for px in range(-15, 30):
		c.draw_line(Vector2(float(px) * 120.0, FEET - 40.0), Vector2(float(px) * 120.0 - 50.0, FEET + 200.0),
			Color(0.30, 0.28, 0.32), 2.0)


# the corner house they come round, in front of the procession
static func _corner(c: CanvasItem) -> void:
	c.draw_rect(Rect2(CORNER_X - 900.0, -300.0, 780.0, FEET - 40.0 + 300.0), Color(0.40, 0.30, 0.26))
	c.draw_rect(Rect2(CORNER_X - 140.0, -300.0, 20.0, FEET - 40.0 + 300.0), Color(0.30, 0.22, 0.20))


# the correfoc coming down the street: the Drac first (it is behind them),
# then the devils, the far rank a step smaller, each one round the corner in
# its turn
static func _correfoc(c: CanvasItem, t: float, t_real: float) -> void:
	var lx := lead_x(t)
	var drac_out := Anim.span(t, OUT_AT + 0.5, OUT_AT + 1.0)
	if drac_out > 0.0:
		drac(c, Vector2(lerpf(CORNER_X - 200.0, lx - 330.0, drac_out), FEET - 40.0), DRAC_K * 0.92, t_real)
	for st: Array in DEVILS:
		var out := Anim.span(t, OUT_AT + float(st[2]) * 0.1, OUT_AT + float(st[2]) * 0.1 + 0.3)
		if out <= 0.0:
			continue
		var far: bool = st[1]
		var k := DEVIL_K * (0.88 if far else 1.0)
		var feet := FEET - (18.0 if far else 0.0)
		devil(c, Vector2(lerpf(CORNER_X, lx + float(st[0]), out), feet), k, t_real + float(st[0]) * 0.01)


# a fire devil side on, facing right: red and black, a horned hood, the fork
# of fireworks held high and forward spraying its fountain of sparks
static func devil(c: CanvasItem, at: Vector2, k: float, t: float) -> void:
	var pose := {
		"stride": t * 12.0, "stride_amp": 1.0, "phone": 0.0, "lean": 0.12, "head": -0.2, "reach": 1.0, "lift": 0.0,
		"skin": SKIN, "shirt": DEVIL_RED, "trousers": DEVIL_BLACK, "hair": DEVIL_BLACK, "shoe": DEVIL_BLACK,
	}
	var hand := IntroKit.human(c, at, k, 1.0, Vector2.ONE, pose, 0.0, at.y)
	# the hood over the head, its horns, a painted face
	var up := Vector2.UP.rotated(0.12)
	var head := at + (up * 94.0 + Vector2(0.0, -98.0) + Vector2(4.0, -16.0)) * k
	c.draw_colored_polygon(MillieSide.ellipse(head + Vector2(-4, -2) * k, Vector2(24, 26) * k), DEVIL_BLACK)
	for s: float in [-1.0, 1.0]:
		var base := head + Vector2(s * 12.0 - 2.0, -16.0) * k
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-5, 0) * k, base + Vector2(5, 0) * k,
			base + Vector2(s * 12.0, -24.0) * k]), DEVIL_HORN)
	c.draw_colored_polygon(MillieSide.ellipse(head + Vector2(10, 6) * k, Vector2(9, 10) * k), SKIN)
	c.draw_line(head + Vector2(6, 2) * k, head + Vector2(15, 4) * k, INK, 2.5 * k)
	# the fork, up and forward, and the fountain off its wheel
	var tip := hand + Vector2(64.0, -88.0) * k
	c.draw_line(hand, tip, DRUM_WOOD, 6.0 * k)
	c.draw_line(tip, tip + Vector2(-12.0, -18.0) * k, DRUM_WOOD, 4.0 * k)
	c.draw_line(tip, tip + Vector2(14.0, -16.0) * k, DRUM_WOOD, 4.0 * k)
	sparks(c, tip + Vector2(0, -14) * k, t, k, Vector2(0.6, -1.0), 22)


# a fountain of sparks off `at`, sprayed along `dir`, falling as they go
static func sparks(c: CanvasItem, at: Vector2, t: float, k: float, dir: Vector2, n: int) -> void:
	c.draw_circle(at, 12.0 * k, Color(1.0, 0.90, 0.50, 0.9))
	c.draw_circle(at, 30.0 * k, Color(1.0, 0.65, 0.20, 0.25))
	var d := dir.normalized()
	for p in range(n):
		var f := fposmod(t * 1.9 + float(p) / float(n), 1.0)
		var spread := d.rotated(sin(float(p) * 2.37) * 1.1)
		var pos := at + spread * f * 150.0 * k + Vector2(0, f * f * 120.0) * k
		c.draw_circle(pos, (4.0 * (1.0 - f) + 1.0) * k, SPARK_YELLOW if p % 2 == 0 else SPARK_ORANGE)


# the Drac de Gràcia side on, facing right, on its bearers' legs: the long
# green scaled body with its ridge, wings up, the neck rising to the head with
# its horns and red eye, jaws open breathing sparks, the tail curling behind
static func drac(c: CanvasItem, at: Vector2, k: float, t: float) -> void:
	var bob := sin(t * 6.0) * 6.0 * k
	var o := at - Vector2(0.0, bob)
	var p := func(v: Vector2) -> Vector2: return o + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(0, 4) * k, Vector2(200, 12) * k), Color(0, 0, 0, 0.35))
	# the bearers' legs under the skirt, in step
	for i in range(4):
		var lx := -120.0 + float(i) * 80.0
		var sw := sin(t * 12.0 + float(i) * 1.7) * 14.0
		c.draw_line(p.call(Vector2(lx, -70)), p.call(Vector2(lx + sw, 0)), DEVIL_BLACK, 14.0 * k)
		c.draw_line(p.call(Vector2(lx + 22, -70)), p.call(Vector2(lx + 22 - sw, 0)), DEVIL_BLACK.lightened(0.1), 14.0 * k)
	# the tail
	var tail := PackedVector2Array()
	for i in range(8):
		var f := float(i) / 7.0
		tail.append(p.call(Vector2(-170.0 - f * 120.0, -120.0 - sin(f * PI + t * 3.0) * 40.0 - f * 30.0)))
	c.draw_polyline(tail, INK, 26.0 * k)
	c.draw_polyline(tail, DRAGON_GREEN.darkened(0.1), 20.0 * k)
	# the body and its skirt
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-20, -130)), Vector2(190, 70) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-20, -130)), Vector2(184, 64) * k), DRAGON_GREEN)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-20, -100)), Vector2(170, 30) * k), DRAGON_BELLY)
	c.draw_rect(Rect2(p.call(Vector2(-180, -88)), Vector2(330, 22) * k), Color(0.80, 0.16, 0.16))
	for i in range(9):
		var sx := -170.0 + float(i) * 38.0
		c.draw_arc(p.call(Vector2(sx, -140)), 16.0 * k, PI, TAU, 8, DRAGON_GREEN.darkened(0.25), 3.0 * k)
	for i in range(10):
		var sx := -170.0 + float(i) * 34.0
		c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(sx, -190)), p.call(Vector2(sx + 14, -224)),
			p.call(Vector2(sx + 28, -192))]), DRAGON_BELLY)
	# a wing, up and beating
	var flap := sin(t * 5.0) * 0.25
	var wroot: Vector2 = p.call(Vector2(10, -180))
	var wing := PackedVector2Array([wroot])
	for i in range(5):
		var a := -2.1 + float(i) * 0.32 + flap
		wing.append(wroot + Vector2.from_angle(a) * (150.0 - float(i % 2) * 40.0) * k)
	c.draw_colored_polygon(wing, DRAGON_GREEN.darkened(0.2))
	wing.append(wroot)
	c.draw_polyline(wing, INK, 4.0 * k)
	# the neck and the head
	var neck := PackedVector2Array([p.call(Vector2(120, -160)), p.call(Vector2(170, -260)), p.call(Vector2(210, -250)),
		p.call(Vector2(180, -130))])
	c.draw_colored_polygon(neck, DRAGON_GREEN)
	var hd: Vector2 = p.call(Vector2(225, -270))
	var jaw := 0.25 + 0.15 * sin(t * 8.0)
	c.draw_colored_polygon(PackedVector2Array([hd + Vector2(-40, -30) * k, hd + Vector2(30, -36) * k, hd + Vector2(80, -18) * k,
		hd + Vector2(82, -4) * k, hd + Vector2(-30, 10) * k]), DRAGON_GREEN)
	c.draw_colored_polygon(PackedVector2Array([hd + Vector2(-30, 10) * k, hd + Vector2(78, 4) * k,
		hd + Vector2(70, 4 + 60.0 * jaw) * k, hd + Vector2(-20, 24) * k]), DRAGON_GREEN.darkened(0.15))
	c.draw_colored_polygon(PackedVector2Array([hd + Vector2(-20, 8) * k, hd + Vector2(72, 2) * k,
		hd + Vector2(66, 2 + 50.0 * jaw) * k]), Color(0.45, 0.06, 0.08))
	for s in range(5):
		c.draw_colored_polygon(PackedVector2Array([hd + Vector2(10 + s * 14, 2) * k, hd + Vector2(18 + s * 14, 2) * k,
			hd + Vector2(14 + s * 14, 12) * k]), Color.WHITE)
	for s: float in [0.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([hd + Vector2(-26 + s * 18, -30) * k, hd + Vector2(-14 + s * 18, -30) * k,
			hd + Vector2(-34 + s * 14, -70) * k]), DEVIL_HORN)
	c.draw_circle(hd + Vector2(12, -18) * k, 10.0 * k, INK)
	c.draw_circle(hd + Vector2(12, -18) * k, 7.5 * k, DRAGON_EYE)
	c.draw_line(hd + Vector2(-2, -32) * k, hd + Vector2(26, -26) * k, INK, 6.0 * k)
	sparks(c, hd + Vector2(84, 10 + 20.0 * jaw) * k, t, k * 1.2, Vector2(1.0, 0.15), 28)


# the card: the street gone white-hot behind RUN!, the Drac's head in from
# the left, jaws wide, spraying its sparks across the frame
static func _title(c: CanvasItem, t: float) -> void:
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(-200, f * 720.0, 1680, 104.0), Color(1.0, 0.86, 0.50).lerp(Color(0.80, 0.30, 0.14), f))
	var d := t - TITLE_AT
	drac(c, Vector2(-520.0 + d * 120.0, 1140.0), 2.6, t)
	FilmKit.slam(c, t, "RUN!", Vector2(900, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
