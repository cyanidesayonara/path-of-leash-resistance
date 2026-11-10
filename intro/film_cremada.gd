class_name FilmCremada
extends RefCounted

# La Cremada's film, "El Dimoni": the telegraph to run as the walk turns for
# home (systems/home_chase.gd plays it through intro/film_player.gd).
# Badalona's beach on the Nit del Dimoni, side on: the night sea, the Pont del
# Petroli running out on its legs with its lamps, the town behind. The two of
# them heading home along the sand, your human on the phone, past the Dimoni
# enthroned on his float, dark and waiting to be burned. A fizz: his crown
# sparks, and her ears go up. His eyes light. Fire runs round the float, the
# brake cracks and he lurches, then rolls after them, his fork spraying, and a
# rocket bursts over their heads. A push in on her face. She spins, digs in
# and bolts; the leash snaps taut, your human is yanked off after her, and
# RUN! slams in under his grin, the fireworks bursting across the card.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.05, 0.05, 0.12)
const FEET := 640.0              # the sand the pair walks on
const DIMONI_X := -60.0          # where the float stands, behind them
const LIGHT_AT := 2.05           # his eyes light
const FIRE_AT := 2.35            # the float catches
const ROLL_AT := 2.7             # the brake gives
const ROCKET_AT := 3.0           # the first rocket goes up
const BURST_AT := 3.45           # and bursts over them
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const K := 1.55
# the walk's colours (entities/dimoni_threat.gd)
const DEVIL := Color(0.80, 0.14, 0.10)
const DEVIL_DARK := Color(0.50, 0.07, 0.06)
const DEVIL_BLACK := Color(0.10, 0.08, 0.08)
const HORN := Color(0.96, 0.80, 0.34)
const TEETH := Color(0.98, 0.95, 0.86)
const EYE := Color(1.0, 0.92, 0.30)
const DECK := Color(0.40, 0.27, 0.16)
const SKIRT := Color(0.78, 0.16, 0.12)
const SKIRT_GOLD := Color(0.95, 0.74, 0.22)
const WHEEL := Color(0.10, 0.09, 0.08)
const FLAME := Color(1.0, 0.56, 0.12)
const FLAME_CORE := Color(1.0, 0.90, 0.46)
const SPARK_YELLOW := Color(0.98, 0.94, 0.40)
const SPARK_ORANGE := Color(0.96, 0.52, 0.12)
const SAND := Color(0.52, 0.46, 0.40)
const SEA := Color(0.08, 0.12, 0.24)
const INK := IntroKit.INK
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "hiss", 1.4, -8.0],
	[1.70, "hiss", 1.6, -6.0],
	[LIGHT_AT, "groan", 0.7, -6.0],
	[FIRE_AT, "cracker", 0.8, -4.0],
	[ROLL_AT, "crack", 0.7, -2.0],
	[ROCKET_AT, "whistle", 1.6, -8.0],
	[BURST_AT, "cracker", 1.0, -2.0],
	[BURST_AT + 0.12, "cracker", 1.3, -6.0],
	[4.40, "cracker", 1.1, -6.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "cracker", 0.6, -2.0],
]


# the camera: [centre, zoom]. On the pair; a pan back along the beach to the
# Dimoni as she looks round, held as he lights and lurches; up with the
# rocket; a whip to a close-up of her; a cut wide on the bolt that runs right
# with them; the card.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 640.0, "io"], [2.1, 260.0, "io"], [3.0, 380.0, "io"],
		[3.45, 520.0, "io"], [3.9, 560.0, "io"], [4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.1, 400.0, "io"], [3.0, 400.0], [3.45, 330.0, "io"], [3.9, 440.0, "io"],
		[4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.1, 0.86, "io"], [3.45, 0.8, "io"], [3.9, 0.96, "io"],
		[4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# where the front of the float is: still, then rolling after them
static func float_x(t: float) -> float:
	return Anim.k(t, [[ROLL_AT, DIMONI_X], [ROLL_AT + 0.25, DIMONI_X + 30.0, "in"], [BOLT_AT, DIMONI_X + 260.0],
		[TITLE_AT, DIMONI_X + 1200.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_beach(c, t_real)
	dimoni(c, Vector2(float_x(t_real), FEET - 40.0), K, t_real, _lit(t_real), _burning(t_real))
	FilmKit.pair(c, t_real, FEET)
	_rocket(c, t_real)
	FilmKit.fades(c, t_real)


static func _lit(t: float) -> float:
	return Anim.span(t, LIGHT_AT, LIGHT_AT + 0.15)


static func _burning(t: float) -> float:
	return Anim.span(t, FIRE_AT, FIRE_AT + 0.3)


# Badalona's beach at night: the sky, the moon, the sea with the Pont del
# Petroli on its legs and its lamps, the town's lights on the far left, the
# promenade wall behind the sand, and the sand
static func _beach(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1000.0 + 200.0), Color(0.04, 0.05, 0.16), Color(0.20, 0.16, 0.32))
	c.draw_circle(Vector2(1500.0, -120.0), 60.0, Color(0.96, 0.94, 0.84))
	c.draw_circle(Vector2(1500.0, -120.0), 110.0, Color(0.96, 0.94, 0.84, 0.10))
	# the sea to the horizon
	var hz := 300.0
	c.draw_rect(Rect2(-1600, hz, 4600, FEET - hz), SEA)
	for i in range(14):
		var y := hz + 14.0 + float(i) * 22.0
		var off := fposmod(t * 30.0 + float(i) * 57.0, 160.0)
		var xx := -1600.0 - off
		while xx < 3000.0:
			c.draw_line(Vector2(xx, y), Vector2(xx + 60.0, y), Color(0.30, 0.36, 0.52, 0.35), 2.0)
			xx += 160.0
	# the moon's path on the water
	for i in range(10):
		var y := hz + 10.0 + float(i) * 26.0
		c.draw_line(Vector2(1440.0 - float(i) * 6.0, y), Vector2(1560.0 + float(i) * 6.0, y), Color(0.96, 0.94, 0.84, 0.22), 3.0)
	# the Pont del Petroli: a long deck out to sea on thin legs, its lamps lit
	var px0 := 300.0
	var px1 := 2400.0
	var dy := hz - 26.0
	c.draw_rect(Rect2(px0, dy, px1 - px0, 10.0), Color(0.62, 0.62, 0.66))
	var lx := px0
	while lx < px1:
		c.draw_line(Vector2(lx, dy + 10.0), Vector2(lx, hz + 40.0), Color(0.40, 0.40, 0.46), 4.0)
		lx += 70.0
	lx = px0 + 30.0
	while lx < px1:
		c.draw_line(Vector2(lx, dy), Vector2(lx, dy - 30.0), Color(0.30, 0.30, 0.34), 2.0)
		c.draw_circle(Vector2(lx, dy - 32.0), 4.0, Color(1.0, 0.86, 0.5))
		c.draw_circle(Vector2(lx, dy - 32.0), 12.0, Color(1.0, 0.86, 0.5, 0.18))
		lx += 140.0
	# the town's lights along the left, past the Dimoni
	for i in range(18):
		var tx := -1500.0 + float(i) * 70.0
		c.draw_rect(Rect2(tx, hz - 90.0 - float(i % 4) * 30.0, 54.0, 90.0 + float(i % 4) * 30.0), Color(0.10, 0.10, 0.18))
		if i % 2 == 0:
			c.draw_rect(Rect2(tx + 14.0, hz - 70.0 - float(i % 4) * 20.0, 10.0, 12.0), Color(1.0, 0.82, 0.48))
	# the sand, the waterline foam
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), SAND)
	for i in range(3):
		var y := FEET - 40.0 + float(i) * 4.0
		c.draw_line(Vector2(-1600, y), Vector2(3000, y), Color(0.80, 0.84, 0.90, 0.5 - float(i) * 0.15), 3.0)
	for p in range(-20, 40):
		var sx := float(p) * 90.0 + fposmod(float(p) * 37.0, 40.0)
		c.draw_circle(Vector2(sx, FEET + 60.0 + fposmod(float(p) * 53.0, 300.0)), 3.0, SAND.darkened(0.15))
	# the float's firelight on the sand, once it burns
	var fire := _burning(t)
	if fire > 0.0:
		var flick := 0.8 + 0.2 * sin(t * 23.0) * sin(t * 7.0)
		for r in range(4):
			c.draw_circle(Vector2(float_x(t) + 120.0, FEET - 120.0), 220.0 + float(r) * 110.0, Color(1.0, 0.55, 0.15, 0.09 * fire * flick))


# The Dimoni on his float, side on, facing right: the timber float on its
# iron wheels with its painted skirt; the devil seated high on it, red and
# grinning, horns up, one arm holding the fork crammed with fireworks; `lit`
# lights his eyes and the fuse in his crown, `burning` the fire round the
# float and the fork's fountain. `at` is the float's front edge on the ground.
static func dimoni(c: CanvasItem, at: Vector2, k: float, t: float, lit: float, burning: float) -> void:
	var p := func(v: Vector2) -> Vector2: return at + v * k
	var w := 330.0
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-w * 0.5, 4)), Vector2(w * 0.6, 14) * k), Color(0, 0, 0, 0.35))
	# the wheels, turning once he rolls
	var spin := t * 6.0 if t > ROLL_AT else 0.0
	for wx: float in [-w + 50.0, -60.0]:
		var wc: Vector2 = p.call(Vector2(wx, -34))
		c.draw_circle(wc, 36.0 * k, WHEEL)
		c.draw_circle(wc, 26.0 * k, DECK.darkened(0.3))
		for s in range(6):
			c.draw_line(wc, wc + Vector2.from_angle(spin + float(s) * TAU / 6.0) * 26.0 * k, WHEEL, 4.0 * k)
	# the deck and skirt with its gold fringe
	c.draw_rect(Rect2(p.call(Vector2(-w, -120)), Vector2(w, 60) * k), INK)
	c.draw_rect(Rect2(p.call(Vector2(-w + 4, -116)), Vector2(w - 8, 52) * k), SKIRT)
	for i in range(int(w / 22.0)):
		c.draw_circle(p.call(Vector2(-w + 12.0 + float(i) * 22.0, -62)), 6.0 * k, SKIRT_GOLD)
	c.draw_rect(Rect2(p.call(Vector2(-w - 6, -136)), Vector2(w + 12, 18) * k), DECK)
	# the throne
	c.draw_rect(Rect2(p.call(Vector2(-w + 40, -330)), Vector2(70, 200) * k), DECK.darkened(0.2))
	# the Dimoni seated: legs over the front, body, the belly
	var sway := sin(t * 3.0) * 4.0 if t > ROLL_AT else 0.0
	var hip: Vector2 = p.call(Vector2(-150 + sway, -150))
	c.draw_line(hip, p.call(Vector2(-60, -150)), DEVIL_DARK, 46.0 * k)
	c.draw_line(p.call(Vector2(-60, -150)), p.call(Vector2(-50, -60)), DEVIL_DARK, 40.0 * k)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-32, -58)), Vector2(34, 16) * k), DEVIL_BLACK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-170 + sway, -250)), Vector2(78, 108) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-170 + sway, -250)), Vector2(72, 102) * k), DEVIL)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-150 + sway, -230)), Vector2(40, 62) * k), DEVIL_DARK)
	# the arm up with the fork, and its fireworks
	var sh: Vector2 = p.call(Vector2(-140 + sway, -310))
	var hand: Vector2 = p.call(Vector2(-60 + sway, -400))
	c.draw_line(sh, hand, DEVIL, 34.0 * k)
	c.draw_circle(hand, 20.0 * k, DEVIL_DARK)
	var tip: Vector2 = hand + Vector2(40.0, -140.0) * k
	c.draw_line(hand + Vector2(-20.0, 70.0) * k, tip, DEVIL_BLACK, 8.0 * k)
	for px: float in [-22.0, 0.0, 22.0]:
		var prong := tip + Vector2(px, 0.0) * k
		c.draw_line(prong, prong + Vector2(px * 0.4, -46.0) * k, DEVIL_BLACK, 6.0 * k)
		c.draw_rect(Rect2(prong + Vector2(px * 0.4 - 7.0, -64.0) * k, Vector2(14, 22) * k), SKIRT_GOLD if px != 0.0 else SKIRT)
		if burning > 0.0:
			sparks(c, prong + Vector2(px * 0.4, -70.0) * k, t + px * 0.01, k * burning, Vector2(px * 0.03, -1.0), 10)
	# the head: horns, big grin, eyes, the beard
	var hd: Vector2 = p.call(Vector2(-150 + sway, -400))
	for s: float in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([hd + Vector2(s * 30.0 - 10.0, -50.0) * k, hd + Vector2(s * 30.0 + 14.0, -50.0) * k,
			hd + Vector2(s * 60.0, -130.0) * k]), HORN)
	c.draw_colored_polygon(MillieSide.ellipse(hd, Vector2(70, 72) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(hd, Vector2(64, 66) * k), DEVIL)
	c.draw_colored_polygon(PackedVector2Array([hd + Vector2(-10, 60) * k, hd + Vector2(40, 54) * k,
		hd + Vector2(20, 120) * k]), DEVIL_BLACK)
	# the brows, the eyes (dark until lit)
	c.draw_line(hd + Vector2(-6, -16) * k, hd + Vector2(56, -30) * k, DEVIL_BLACK, 12.0 * k)
	var eye := Color(0.25, 0.08, 0.06).lerp(EYE, lit)
	c.draw_circle(hd + Vector2(34, -6) * k, 12.0 * k, eye)
	if lit > 0.0:
		c.draw_circle(hd + Vector2(34, -6) * k, 30.0 * k, Color(EYE, 0.25 * lit))
	c.draw_circle(hd + Vector2(38, -6) * k, 5.0 * k, DEVIL_BLACK)
	# the grin, teeth showing
	c.draw_colored_polygon(PackedVector2Array([hd + Vector2(0, 20) * k, hd + Vector2(64, 14) * k,
		hd + Vector2(54, 40) * k, hd + Vector2(10, 40) * k]), DEVIL_BLACK)
	for i in range(5):
		c.draw_rect(Rect2(hd + Vector2(8.0 + float(i) * 10.0, 20.0) * k, Vector2(7, 8) * k), TEETH)
	# the fuse in his crown, fizzing from the first hiss
	var fizz := Anim.span(t, 1.3, 1.45)
	if fizz > 0.0:
		sparks(c, hd + Vector2(-10, -78) * k, t, k * 0.7, Vector2(0.2, -1.0), 12)
	# the fire round the float
	if burning > 0.0:
		for i in range(9):
			var fx := -w + 20.0 + float(i) * (w - 40.0) / 8.0
			var flick := 0.6 + 0.4 * sin(t * 13.0 + float(i) * 2.1)
			var base: Vector2 = p.call(Vector2(fx, -136))
			var hgt := (50.0 + float(i % 3) * 22.0) * flick * burning
			c.draw_colored_polygon(PackedVector2Array([base + Vector2(-18, 0) * k, base + Vector2(18, 0) * k,
				base + Vector2(sin(t * 9.0 + float(i)) * 8.0, -hgt) * k]), FLAME)
			c.draw_colored_polygon(PackedVector2Array([base + Vector2(-9, 0) * k, base + Vector2(9, 0) * k,
				base + Vector2(0, -hgt * 0.55) * k]), FLAME_CORE)


# the first rocket: off the fork, up over them, and its burst
static func _rocket(c: CanvasItem, t: float) -> void:
	if t < ROCKET_AT or t > BURST_AT + 0.9:
		return
	var from := Vector2(float_x(t) - 60.0 * K, FEET - 40.0 - 600.0 * K)
	var to := Vector2(620.0, 120.0)
	if t < BURST_AT:
		var k := Anim.span(t, ROCKET_AT, BURST_AT)
		var head := from.lerp(to, k) + Vector2(0.0, -sin(k * PI) * 160.0)
		for j in range(6):
			var kk := maxf(0.0, k - float(j + 1) * 0.035)
			var tp := from.lerp(to, kk) + Vector2(0.0, -sin(kk * PI) * 160.0)
			c.draw_circle(tp, 8.0 - float(j), Color(0.6, 0.55, 0.6, 0.5 - float(j) * 0.07))
		c.draw_circle(head, 10.0, SPARK_ORANGE)
		c.draw_circle(head, 5.0, SPARK_YELLOW)
		return
	var b := Anim.span(t, BURST_AT, BURST_AT + 0.9)
	c.draw_circle(to, 60.0 + b * 160.0, Color(1.0, 0.85, 0.5, 0.25 * (1.0 - b)))
	for i in range(24):
		var a := float(i) * TAU / 24.0
		var r := 30.0 + b * 240.0
		var pt := to + Vector2.from_angle(a) * r + Vector2(0.0, b * b * 90.0)
		c.draw_circle(pt, 7.0 * (1.0 - b) + 1.5, SPARK_YELLOW if i % 2 == 0 else Color(0.95, 0.30, 0.25))


# a fountain of sparks off `at`, sprayed along `dir`, falling as they go
static func sparks(c: CanvasItem, at: Vector2, t: float, k: float, dir: Vector2, n: int) -> void:
	c.draw_circle(at, 10.0 * k, Color(1.0, 0.90, 0.50, 0.9))
	c.draw_circle(at, 26.0 * k, Color(1.0, 0.65, 0.20, 0.25))
	var d := dir.normalized()
	for i in range(n):
		var f := fposmod(t * 1.9 + float(i) / float(n), 1.0)
		var spread := d.rotated(sin(float(i) * 2.37) * 0.9)
		var pos := at + spread * f * 130.0 * k + Vector2(0, f * f * 110.0) * k
		c.draw_circle(pos, (4.0 * (1.0 - f) + 1.0) * k, SPARK_YELLOW if i % 2 == 0 else SPARK_ORANGE)


# the card: the night lit orange behind RUN!, the Dimoni rolling in from the
# left, fork up and spraying, bursts going off across the sky
static func _title(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.16, 0.08, 0.20), Color(0.92, 0.42, 0.14))
	var d := t - TITLE_AT
	for i in range(4):
		var bt := fposmod(d * 1.3 + float(i) * 0.27, 1.0)
		var at := Vector2(500.0 + float(i) * 260.0, 140.0 + float(i % 2) * 120.0)
		for s in range(16):
			var a := float(s) * TAU / 16.0
			c.draw_circle(at + Vector2.from_angle(a) * (20.0 + bt * 130.0) + Vector2(0.0, bt * bt * 60.0),
				5.0 * (1.0 - bt) + 1.0, SPARK_YELLOW if (s + i) % 2 == 0 else Color(0.95, 0.30, 0.25))
	dimoni(c, Vector2(-80.0 + d * 140.0, 1180.0), 1.9, t, 1.0, 1.0)
	FilmKit.slam(c, t, "RUN!", Vector2(900, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
