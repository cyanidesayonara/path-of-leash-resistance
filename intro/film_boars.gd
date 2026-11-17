class_name FilmBoars
extends RefCounted

# Els Senglars' film, "The sounder": the telegraph to run as the walk turns
# for home (systems/home_chase.gd plays it through intro/film_player.gd).
# Dusk on the dirt trail through Collserola's holm oaks, side on. The two of
# them heading home, your human on the phone. The scrub behind them rustles:
# her ears go up and she looks back. A snort; the bushes thrash; a tipped
# bin goes over with a crash, and out of the undergrowth comes the sounder,
# the walk's line of boars seen side on: the mama huge and bristling, tusks
# up, red eyes under a scowl, two big boars and the striped piglets
# scampering after, dust and leaves flying. A push in on her face. She spins,
# digs in and bolts; the leash snaps taut, your human is yanked off after
# her, and RUN! slams in with the mama charging at the frame.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.07, 0.10, 0.07)
const FEET := 640.0              # the trail the pair walks on
const SCRUB_X := -40.0           # the undergrowth the sounder bursts out of
const OUT_AT := 2.3              # the bin goes over and they burst out
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const BOAR_K := 1.5              # the mama's scale: her back level with your human's chest
# the walk's colours (entities/boar_threat.gd)
const FUR_DARK := Color(0.18, 0.16, 0.15)
const FUR_BRISTLE := Color(0.28, 0.24, 0.22)
const SNOUT_PINK := Color(0.72, 0.52, 0.50)
const TUSK_WHITE := Color(0.95, 0.94, 0.88)
const EYE_RED := Color(0.85, 0.20, 0.15)
const HOOF_DARK := Color(0.12, 0.10, 0.09)
const PIG_BASE := Color(0.48, 0.38, 0.28)
const PIG_STRIPE := Color(0.75, 0.65, 0.48)
const BIN_GREEN := Color(0.18, 0.45, 0.25)
const BIN_DARK := Color(0.10, 0.28, 0.15)
const DIRT := Color(0.52, 0.40, 0.28)
const OAK := Color(0.16, 0.30, 0.18)
const INK := IntroKit.INK
# the sounder, as the walk's line seen side on: [x behind the mama, far,
# scale, piglet, gallop phase, order out of the scrub]
# piglets last, scampering in front beside the mama's legs
const SOUNDER := [
	[-300.0, true, 0.9, false, 1.3, 2],
	[-170.0, true, 0.85, false, 0.8, 1],
	[0.0, false, 1.0, false, 0.0, 0],
	[-240.0, false, 0.42, true, 2.1, 4],
	[-30.0, false, 0.4, true, 0.4, 3],
]
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "rustle", 0.7, -6.0],
	[2.00, "snort", 0.8, -6.0],
	[OUT_AT, "crack", 0.5, -4.0],
	[OUT_AT + 0.1, "grunt", 0.6, -4.0],
	[3.10, "snort", 1.1, -8.0],
	[4.55, "whistle", 1.3, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "grunt", 0.45, -3.0],
]


# the camera: [centre, zoom]. On the pair; a pan back down the trail when she
# looks round, held as the scrub thrashes and the sounder comes on; a whip to
# a close-up of her; a cut wide on the bolt that runs right with them; the
# title card square on.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 240.0, "io"], [3.9, 360.0, "io"],
		[4.2, 470.0, "io"], [BOLT_AT, 520.0]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 440.0, "io"], [3.9, 450.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.9, "io"], [3.9, 0.98, "io"], [4.2, 1.32, "io"], [BOLT_AT, 1.42]])
	return [Vector2(x, y), z]


# where the mama's feet are; the herd runs behind her
static func mama_x(t: float) -> float:
	return Anim.k(t, [[OUT_AT, SCRUB_X], [3.9, 140.0, "out"], [BOLT_AT, 230.0], [TITLE_AT, 1300.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_wood(c, t_real)
	_scrub(c, t_real)
	if t_real >= OUT_AT:
		_sounder(c, Anim.twos(t_real), t_real)
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


# dusk through the holm oaks: a low orange sky between dark trunks, the far
# slope in shadow, the dirt trail with its ruts and fallen leaves, and the
# tipped bin by the scrub
static func _wood(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1100.0 + 130.0), Color(0.95, 0.62, 0.34), Color(0.30, 0.22, 0.30))
	# the far slope, and the oaks on it
	c.draw_rect(Rect2(-1600, 300, 4600, FEET), Color(0.14, 0.20, 0.14))
	for k in range(26):
		var ox := -1500.0 + float(k) * 170.0 + sin(float(k) * 2.3) * 40.0
		var oy := 300.0 + sin(float(k) * 1.7) * 30.0
		c.draw_rect(Rect2(ox - 8.0, oy - 40.0, 16.0, 200.0), Color(0.16, 0.12, 0.10))
		c.draw_circle(Vector2(ox, oy - 90.0), 90.0 + sin(float(k)) * 18.0, OAK.darkened(0.35))
		c.draw_circle(Vector2(ox - 40.0, oy - 60.0), 60.0, OAK.darkened(0.3))
	# near oaks, framing the trail
	for ox: float in [-900.0, 480.0, 1500.0, 2400.0]:
		c.draw_rect(Rect2(ox - 22.0, -400.0, 44.0, FEET - 30.0 + 400.0), Color(0.22, 0.16, 0.12))
		c.draw_circle(Vector2(ox, -300.0), 260.0, OAK)
		c.draw_circle(Vector2(ox - 150.0, -200.0), 170.0, OAK.darkened(0.08))
		c.draw_circle(Vector2(ox + 160.0, -220.0), 180.0, OAK.lightened(0.05))
	# the trail
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), DIRT)
	c.draw_line(Vector2(-1600, FEET + 26.0), Vector2(3000, FEET + 26.0), DIRT.darkened(0.15), 6.0)
	c.draw_line(Vector2(-1600, FEET + 70.0), Vector2(3000, FEET + 70.0), DIRT.darkened(0.12), 5.0)
	for k in range(60):
		var lx := -1500.0 + float(k) * 73.0
		var ly := FEET - 20.0 + fposmod(float(k) * 37.0, 110.0)
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(lx, ly), Vector2(7, 3)),
			Color(0.62, 0.42, 0.18) if k % 3 else Color(0.40, 0.48, 0.20))
	# the bin, upright, then over on its side with its rubbish spilled
	var over := Anim.span(t, OUT_AT, OUT_AT + 0.12)
	var bx := SCRUB_X - 220.0
	if over <= 0.0:
		IntroKit.box(c, Rect2(bx - 60.0, FEET - 170.0, 120.0, 140.0), 8.0, BIN_GREEN)
		c.draw_rect(Rect2(bx - 66.0, FEET - 184.0, 132.0, 20.0), BIN_DARK)
	else:
		IntroKit.box(c, Rect2(bx - 90.0, FEET - 110.0, 180.0, 90.0), 8.0, BIN_GREEN)
		c.draw_rect(Rect2(bx + 86.0, FEET - 116.0, 18.0, 100.0), BIN_DARK)
		for k in range(6):
			c.draw_circle(Vector2(bx + 110.0 + float(k) * 22.0, FEET - 30.0 + sin(float(k) * 2.0) * 6.0), 7.0,
				[Color(0.95, 0.55, 0.15), Color(0.90, 0.88, 0.35), Color(0.85, 0.85, 0.82)][k % 3])
		var bang := Anim.span(t, OUT_AT, OUT_AT + 0.35)
		if bang < 1.0:
			for k in range(5):
				var d := Vector2.from_angle(-PI * 0.5 + (float(k) - 2.0) * 0.45)
				c.draw_line(Vector2(bx, FEET - 130.0) + d * (30.0 + bang * 40.0),
					Vector2(bx, FEET - 130.0) + d * (70.0 + bang * 70.0), Color(INK, 1.0 - bang), 5.0)


# the undergrowth at the trail's edge: it rustles at the sound, thrashes
# at the snort, and they burst through it in a spray of leaves
static func _scrub(c: CanvasItem, t: float) -> void:
	var shake := 0.0
	if t >= FilmKit.HEAR_AT:
		shake = 4.0 + 10.0 * Anim.span(t, 2.0, 2.1) * (1.0 - Anim.span(t, OUT_AT + 0.3, OUT_AT + 0.8))
	for k in range(7):
		var sx := SCRUB_X - 160.0 + float(k) * 60.0
		var j := sin(t * 30.0 + float(k) * 1.9) * shake
		c.draw_circle(Vector2(sx + j, FEET - 50.0 - float(k % 2) * 30.0), 62.0, OAK.darkened(0.15))
		c.draw_circle(Vector2(sx + 20.0 + j, FEET - 80.0), 44.0, OAK)
	var burst := Anim.span(t, OUT_AT, OUT_AT + 0.9)
	if burst > 0.0 and burst < 1.0:
		for p in range(14):
			var a := -PI * 0.5 + (float(p) / 13.0 - 0.5) * 2.4
			var at := Vector2(SCRUB_X, FEET - 90.0) + Vector2.from_angle(a) * (40.0 + burst * 260.0) \
				+ Vector2(0, burst * burst * 200.0)
			c.draw_colored_polygon(MillieSide.ellipse(at, Vector2(9, 4)), Color(OAK.lightened(0.2), 1.0 - burst))


# the sounder coming down the trail at a gallop, the far rank a step smaller
# and higher, each one out of the scrub in its turn, dust kicked up behind
static func _sounder(c: CanvasItem, t: float, t_real: float) -> void:
	var mx := mama_x(t)
	for st: Array in SOUNDER:
		var out := Anim.span(t, OUT_AT + float(st[5]) * 0.12, OUT_AT + float(st[5]) * 0.12 + 0.3)
		if out <= 0.0:
			continue
		var far: bool = st[1]
		var k := BOAR_K * float(st[2]) * (0.86 if far else 1.0)
		var feet := FEET - (20.0 if far else 0.0)
		var x := lerpf(SCRUB_X, mx + float(st[0]), out)
		for p in range(4):
			var f := fposmod(t_real * 2.4 + float(p) * 0.25 + float(st[4]), 1.0)
			IntroKit.puff(c, Vector2(x - 120.0 * k - f * 120.0, feet - 10.0 - f * 50.0), (14.0 + f * 22.0) * k,
				0.7 * (1.0 - f))
		boar(c, Vector2(x, feet), k, t_real + float(st[4]), bool(st[3]))


# a boar side on, facing right, its feet at `at`, at scale k: the bristling
# body and its mane, the wedge of a head down to the pink snout disc, a tusk
# curling up, a small red eye under a scowling brow, legs at a gallop, the
# tail up; a piglet is the same shape, striped, no tusks, no scowl. Shared
# with the card.
static func boar(c: CanvasItem, at: Vector2, k: float, t: float, piglet: bool) -> void:
	if not piglet:
		_sow(c, at, k, t)
		return
	var fur := PIG_BASE if piglet else FUR_DARK
	var bob := absf(sin(t * 9.0)) * 8.0 * k
	var o := at - Vector2(0.0, bob)
	var p := func(v: Vector2) -> Vector2: return o + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(0, 2) * k, Vector2(110, 10) * k), Color(0.05, 0.04, 0.03, 0.35))
	# legs, the far pair first, at a gallop
	for i in range(4):
		var hip: Vector2 = [Vector2(-70, -40), Vector2(55, -40), Vector2(-50, -40), Vector2(75, -40)][i]
		var swing := sin(t * 18.0 + float(i) * 1.6) * 0.65
		var foot: Vector2 = hip + Vector2.from_angle(PI * 0.5 + swing) * 46.0
		var col := fur.darkened(0.3) if i < 2 else fur
		c.draw_line(p.call(hip), p.call(foot), INK, 17.0 * k)
		c.draw_line(p.call(hip), p.call(foot), col, 12.0 * k)
		c.draw_circle(p.call(foot), 7.0 * k, HOOF_DARK)
	# the body and the mane bristling along the spine
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-5, -78)), Vector2(110, 52) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-5, -78)), Vector2(105, 47) * k), fur)
	# the heavy shoulders a boar carries high, the rump falling away behind
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(45, -100)), Vector2(62, 44) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(45, -100)), Vector2(57, 39) * k), fur)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(-10, -102)), Vector2(70, 16) * k), fur.lightened(0.10))
	if piglet:
		for s in range(3):
			var sy := -96.0 + float(s) * 18.0
			c.draw_line(p.call(Vector2(-80, sy)), p.call(Vector2(50, sy - 6.0)), PIG_STRIPE, 6.0 * k)
	else:
		for s in range(9):
			var sx := -85.0 + float(s) * 17.0
			c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(sx, -118)), p.call(Vector2(sx + 7, -142 - float(s % 2) * 8.0)),
				p.call(Vector2(sx + 14, -120))]), FUR_BRISTLE)
	# the tail up, its tuft flicking
	var flick := sin(t * 14.0) * 8.0
	c.draw_line(p.call(Vector2(-106, -92)), p.call(Vector2(-128, -112 + flick)), INK, 6.0 * k)
	c.draw_circle(p.call(Vector2(-130, -114 + flick)), 6.0 * k, FUR_BRISTLE)
	# the head, its ear, the snout disc
	var head := PackedVector2Array()
	for v: Vector2 in [Vector2(55, -118), Vector2(104, -104), Vector2(150, -66), Vector2(154, -42), Vector2(118, -30),
			Vector2(66, -42)]:
		head.append(p.call(v))
	c.draw_colored_polygon(head, fur)
	head.append(head[0])
	c.draw_polyline(head, INK, 4.0 * k)
	c.draw_colored_polygon(PackedVector2Array([p.call(Vector2(78, -114)), p.call(Vector2(70, -146)),
		p.call(Vector2(98, -120))]), fur.darkened(0.15))
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(154, -54)), Vector2(9, 15) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(154, -54)), Vector2(7, 13) * k), SNOUT_PINK)
	c.draw_circle(p.call(Vector2(156, -60)), 2.2 * k, INK)
	c.draw_circle(p.call(Vector2(156, -48)), 2.2 * k, INK)
	if piglet:
		c.draw_circle(p.call(Vector2(110, -80)), 6.0 * k, Color.WHITE)
		c.draw_circle(p.call(Vector2(112, -80)), 3.5 * k, INK)
		return
	# a tusk curling up out of the jaw
	var tusk := PackedVector2Array([p.call(Vector2(126, -36)), p.call(Vector2(146, -46)), p.call(Vector2(156, -74)),
		p.call(Vector2(140, -48))])
	c.draw_colored_polygon(tusk, TUSK_WHITE)
	tusk.append(tusk[0])
	c.draw_polyline(tusk, INK, 2.5 * k)
	# the small red eye under a scowl
	c.draw_circle(p.call(Vector2(110, -80)), 7.0 * k, INK)
	c.draw_circle(p.call(Vector2(110, -80)), 5.0 * k, EYE_RED)
	c.draw_line(p.call(Vector2(94, -96)), p.call(Vector2(126, -84)), INK, 7.0 * k)
	# snorting steam off the snout
	var sn := fposmod(t * 2.0, 1.0)
	if sn < 0.5:
		IntroKit.puff(c, p.call(Vector2(170 + sn * 60.0, -60 - sn * 30.0)), (8.0 + sn * 20.0) * k, 1.0 - sn * 2.0)


# The sow, the one that charges: a hump of shoulder carried high and the head
# slung low to hook, the crest along her spine standing up as she runs, two
# tusks curving up past the snout, a small eye burning under a heavy brow, a
# snarl with froth flying back off it, cloven hooves throwing dirt. Grizzled
# dark brown, close to the walk's FUR_DARK so film and walk are one animal.
const SOW_FUR := Color(0.23, 0.18, 0.15)
const SOW_GRIZZLE := Color(0.44, 0.37, 0.31)
const SOW_BELLY := Color(0.13, 0.10, 0.09)
const SOW_CREST := Color(0.33, 0.27, 0.22)
const SOW_GUMS := Color(0.42, 0.14, 0.14)
const EYE_GLOW := Color(1.0, 0.36, 0.12)
const SOW_BACK := [Vector2(-112, -70), Vector2(-104, -100), Vector2(-70, -118), Vector2(-20, -130), Vector2(30, -148),
	Vector2(64, -142), Vector2(92, -118), Vector2(124, -96), Vector2(156, -70), Vector2(178, -58), Vector2(184, -42),
	Vector2(176, -30), Vector2(146, -26), Vector2(112, -34), Vector2(82, -42), Vector2(40, -36), Vector2(-20, -32),
	Vector2(-70, -36), Vector2(-102, -48)]
const SOW_CREST_BASE := [Vector2(-66, -119), Vector2(-46, -124), Vector2(-26, -129), Vector2(-6, -136), Vector2(14, -142),
	Vector2(32, -148), Vector2(50, -146), Vector2(68, -139), Vector2(84, -126), Vector2(98, -114)]
const SOW_STROKES := [Vector2(-80, -84), Vector2(-56, -98), Vector2(-30, -80), Vector2(-6, -104), Vector2(18, -84),
	Vector2(40, -112), Vector2(60, -90), Vector2(-50, -62), Vector2(6, -60), Vector2(84, -70)]


static func _q(o: Vector2, k: float, v: Vector2) -> Vector2:
	return o + v * k


static func _sow(c: CanvasItem, at: Vector2, k: float, t: float) -> void:
	var gait := t * 18.0
	var bob := absf(sin(t * 9.0)) * 9.0 * k
	var o := at - Vector2(0.0, bob)
	# the head dips into each stride, a hooking toss
	var toss := sin(gait) * 4.0
	c.draw_colored_polygon(MillieSide.ellipse(at + Vector2(20, 2) * k, Vector2(130, 11) * k), Color(0.05, 0.04, 0.03, 0.4))
	# the far tusk, behind the head
	_tusk(c, o + Vector2(-9.0, 3.0 + toss) * k, k, TUSK_WHITE.darkened(0.3))
	# legs, the far pair first: thick forelegs under the hump, cloven hooves
	for i in range(4):
		var hip: Vector2 = [Vector2(-74, -46), Vector2(60, -50), Vector2(-54, -44), Vector2(80, -48)][i]
		var swing := sin(gait + float(i) * 1.6) * 0.7
		var knee: Vector2 = hip + Vector2.from_angle(PI * 0.5 + swing * 0.6) * 26.0
		var foot: Vector2 = knee + Vector2.from_angle(PI * 0.5 + swing) * 26.0
		var col := SOW_BELLY if i < 2 else SOW_FUR
		var w := 22.0 if hip.x > 0.0 else 18.0
		c.draw_polyline(PackedVector2Array([_q(o, k, hip), _q(o, k, knee), _q(o, k, foot)]), INK, (w + 5.0) * k)
		c.draw_polyline(PackedVector2Array([_q(o, k, hip), _q(o, k, knee), _q(o, k, foot)]), col, w * k)
		var hf := _q(o, k, foot)
		c.draw_colored_polygon(PackedVector2Array([hf + Vector2(-9, -3) * k, hf + Vector2(9, -3) * k, hf + Vector2(11, 6) * k,
			hf + Vector2(-11, 6) * k]), HOOF_DARK)
		c.draw_line(hf + Vector2(0, -2) * k, hf + Vector2(0, 6) * k, SOW_FUR, 2.0 * k)
	# the body: one silhouette, hump high, head low
	var body := PackedVector2Array()
	for i in range(SOW_BACK.size()):
		var v: Vector2 = SOW_BACK[i]
		if v.x > 90.0:
			v.y += toss
		body.append(_q(o, k, v))
	c.draw_colored_polygon(body, SOW_FUR)
	# the belly in shadow, the grizzle catching light along the back
	c.draw_colored_polygon(MillieSide.ellipse(_q(o, k, Vector2(-10, -42)), Vector2(96, 12) * k), SOW_BELLY)
	c.draw_polyline(PackedVector2Array([_q(o, k, Vector2(-96, -96)), _q(o, k, Vector2(-60, -110)),
		_q(o, k, Vector2(-14, -120)), _q(o, k, Vector2(30, -136)), _q(o, k, Vector2(60, -132))]), SOW_GRIZZLE, 7.0 * k)
	for s: Vector2 in SOW_STROKES:
		c.draw_line(_q(o, k, s), _q(o, k, s + Vector2(-12, 5)), SOW_GRIZZLE, 2.5 * k)
	var outline := body.duplicate()
	outline.append(body[0])
	c.draw_polyline(outline, INK, 5.0 * k)
	# the crest, hackles up: higher the harder she runs
	var crest := PackedVector2Array()
	for i in range(SOW_CREST_BASE.size()):
		var b: Vector2 = SOW_CREST_BASE[i]
		var ln := 24.0 + float((i * 7) % 5) * 4.0 + sin(gait + float(i)) * 3.0
		var tip := b + Vector2(-0.45, -1.0).normalized() * ln
		crest.append(_q(o, k, b))
		crest.append(_q(o, k, tip))
	# close the last tooth on its own base, or its edge crosses the one before
	crest.append(_q(o, k, SOW_CREST_BASE[SOW_CREST_BASE.size() - 1] + Vector2(4, 2)))
	for i in range(SOW_CREST_BASE.size() - 1, -1, -1):
		crest.append(_q(o, k, SOW_CREST_BASE[i] + Vector2(0, 10)))
	c.draw_colored_polygon(crest, SOW_CREST)
	var cl := crest.duplicate()
	cl.append(crest[0])
	c.draw_polyline(cl, INK, 3.0 * k)
	# the ear laid flat back
	var ear := PackedVector2Array([_q(o, k, Vector2(98, -112 + toss)), _q(o, k, Vector2(64, -134 + toss)),
		_q(o, k, Vector2(84, -104 + toss))])
	c.draw_colored_polygon(ear, SOW_BELLY)
	ear.append(ear[0])
	c.draw_polyline(ear, INK, 3.0 * k)
	# the tail up and lashing
	var flick := sin(t * 14.0) * 8.0
	c.draw_line(_q(o, k, Vector2(-108, -90)), _q(o, k, Vector2(-132, -114 + flick)), INK, 6.0 * k)
	c.draw_circle(_q(o, k, Vector2(-134, -116 + flick)), 6.0 * k, SOW_CREST)
	var h := o + Vector2(0.0, toss) * k
	# the snarl: the jaw dropped open, red gums, froth flying back
	c.draw_colored_polygon(PackedVector2Array([_q(h, k, Vector2(174, -36)), _q(h, k, Vector2(132, -32)),
		_q(h, k, Vector2(150, -22)), _q(h, k, Vector2(172, -24))]), SOW_GUMS)
	c.draw_polyline(PackedVector2Array([_q(h, k, Vector2(132, -32)), _q(h, k, Vector2(150, -20)),
		_q(h, k, Vector2(174, -22))]), INK, 4.0 * k)
	for f in range(3):
		var ff := fposmod(t * 3.0 + float(f) * 0.33, 1.0)
		c.draw_circle(_q(h, k, Vector2(130 - ff * 70.0, -30 - ff * 20.0 + float(f) * 6.0)), (4.5 - ff * 3.0) * k,
			Color(1, 1, 1, 0.9 * (1.0 - ff)))
	# the near tusk
	_tusk(c, h, k, TUSK_WHITE)
	# the snout disc, wet and flared
	c.draw_colored_polygon(MillieSide.ellipse(_q(h, k, Vector2(184, -48)), Vector2(10, 17) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(_q(h, k, Vector2(184, -48)), Vector2(8, 15) * k), SNOUT_PINK)
	c.draw_colored_polygon(MillieSide.ellipse(_q(h, k, Vector2(186, -55)), Vector2(2.5, 4) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(_q(h, k, Vector2(186, -41)), Vector2(2.5, 4) * k), INK)
	# the eye: small, burning, under a brow like a ledge
	var eye := _q(h, k, Vector2(132, -80))
	c.draw_circle(eye, 14.0 * k, Color(EYE_GLOW, 0.25))
	c.draw_circle(eye, 8.0 * k, INK)
	c.draw_circle(eye, 6.0 * k, EYE_RED)
	c.draw_circle(eye, 3.0 * k, EYE_GLOW)
	c.draw_circle(eye + Vector2(-2, -2) * k, 1.6 * k, Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([_q(h, k, Vector2(108, -100)), _q(h, k, Vector2(152, -84)),
		_q(h, k, Vector2(150, -76)), _q(h, k, Vector2(112, -88))]), INK)
	# snorting steam, both nostrils, on the stride
	var sn := fposmod(t * 2.2, 1.0)
	if sn < 0.6:
		var g := sn / 0.6
		IntroKit.puff(c, _q(h, k, Vector2(198 + g * 70.0, -56 - g * 34.0)), (9.0 + g * 24.0) * k, 0.9 * (1.0 - g))
		IntroKit.puff(c, _q(h, k, Vector2(196 + g * 60.0, -38 + g * 6.0)), (7.0 + g * 18.0) * k, 0.7 * (1.0 - g))


# a tusk: a crescent of ivory hooking up out of the lower jaw past the snout
static func _tusk(c: CanvasItem, h: Vector2, k: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for v: Vector2 in [Vector2(134, -28), Vector2(148, -30), Vector2(162, -42), Vector2(170, -62), Vector2(169, -88),
			Vector2(163, -66), Vector2(155, -48), Vector2(142, -37)]:
		pts.append(_q(h, k, v))
	c.draw_colored_polygon(pts, col)
	pts.append(pts[0])
	c.draw_polyline(pts, INK, 3.0 * k)


# the card: the wood gone white-hot behind RUN!, the mama charging in from
# the left of the frame, tusks first, dust boiling round her
static func _title(c: CanvasItem, t: float) -> void:
	# one smooth gradient: flat bands showed their steps
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.99, 0.82, 0.56), Color(0.62, 0.38, 0.22))
	var d := t - TITLE_AT
	for p in range(8):
		var f := fposmod(t * 1.6 + float(p) * 0.125, 1.0)
		IntroKit.puff(c, Vector2(-80.0 + f * 200.0, 640.0 - f * 160.0 + sin(float(p) * 2.0) * 40.0), 40.0 + f * 60.0,
			0.8 * (1.0 - f))
	boar(c, Vector2(-140.0 + d * 140.0, 700.0), 2.6, t, false)
	FilmKit.slam(c, t, "RUN!", Vector2(900, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
