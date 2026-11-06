class_name FilmPlinth
extends RefCounted

# The Rambla del Raval victory film, "El Rei del Raval":
# The celebratory finale scene on the plinth after defeating Botero's giant cat.
# Night in the circular plaça at the top of the rambla, side on:
# The palms, the terraces, lit windows, and the stone plinth. Botero's fat bronze cat
# lies happily toppled on the plinth, purring contentedly with eyes shut.
# The dog trots in, leaps triumphantly onto the plinth, chest puffed out, tail wagging,
# barking proudly over the defeated feline.
# Your human approaches, looks up from their phone in wonder, smiles, and raises the phone
# to snap a victory photo of the dog and cat! FLASH!
# Fireworks burst, confetti rains down, the terrace crowd cheers, and the celebratory
# title card slams in: EL REI! / VICTÒRIA AL RAVAL.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.05, 0.05, 0.10)
const FEET := 640.0
const PLINTH_X := 520.0
const PLINTH_TOP := FEET - 130.0   # 510.0
const PLINTH_W := 380.0
const HOP_START := 1.0
const HOP_END := 1.6
const HUMAN_STOP := 2.2
const AIM_AT := 2.8
const FLASH_AT := 3.6
const TITLE_AT := FilmKit.TITLE_AT

const INK := IntroKit.INK
const BRONZE_BASE := Color(0.30, 0.24, 0.19)
const BRONZE_DARK := Color(0.17, 0.13, 0.11)
const BRONZE_LIT := Color(0.46, 0.37, 0.27)
const BRONZE_SPEC := Color(0.78, 0.64, 0.46, 0.32)
const EYE_PUPIL := Color(0.12, 0.08, 0.06)
const NOSE_DARK := Color(0.20, 0.15, 0.14)
const WHISKER_WIRE := Color(0.70, 0.64, 0.54)
const STONE := Color(0.74, 0.72, 0.68)
const STONE_DARK := Color(0.56, 0.54, 0.50)
const PANOT := Color(0.66, 0.64, 0.60)
const PALM_TRUNK := Color(0.46, 0.35, 0.25)
const PALM_LEAF := Color(0.20, 0.48, 0.24)
const S := 1.45

# Sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.2, "gat_purr", 1.0, -4.0],
	[1.2, "whoop", 1.1, -4.0],
	[1.8, "bark", 1.25, -2.0],
	[2.5, "bark", 1.35, -3.0],
	[3.1, "ui", 1.0, -4.0],
	[FLASH_AT, "crack", 1.3, -2.0],
	[FLASH_AT + 0.05, "star", 1.1, -2.0],
	[FLASH_AT + 0.2, "ooooh", 1.0, -6.0],
	[4.0, "cracker", 1.0, -3.0],
	[4.4, "cracker", 1.2, -4.0],
	[4.8, "whoop", 1.2, -3.0],
	[TITLE_AT, "gat_clang", 0.9, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2(sin(t * 89.0), sin(t * 67.0)) * 12.0 * (1.0 - Anim.span(t, FLASH_AT, FLASH_AT + 0.3)) \
		if t >= FLASH_AT else Vector2.ZERO
	if t < HOP_START:
		return [Vector2(640.0, 480.0), 1.1]
	elif t < HUMAN_STOP:
		var f := Anim.span(t, HOP_START, HUMAN_STOP)
		return [Vector2(lerpf(640.0, 580.0, f), lerpf(480.0, 470.0, f)), lerpf(1.1, 1.2, f)]
	elif t < FLASH_AT:
		var f := Anim.span(t, HUMAN_STOP, FLASH_AT)
		return [Vector2(lerpf(580.0, 600.0, f), 470.0), lerpf(1.2, 1.26, f)]
	else:
		var f := Anim.span(t, FLASH_AT, TITLE_AT)
		return [Vector2(lerpf(600.0, 620.0, f), lerpf(470.0, 440.0, f)) + shake, lerpf(1.26, 0.98, f)]


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_rambla(c, t_real)
	_plinth(c, t)
	_toppled_cat(c, t_real)
	_dog(c, t_real)
	_human(c, t_real)
	if t_real >= FLASH_AT:
		_fireworks(c, t_real)
		_confetti(c, t_real)
	FilmKit.fades(c, t_real)


static func _rambla(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1000.0 + 130.0), Color(0.06, 0.06, 0.16), Color(0.20, 0.14, 0.24))
	var x := -1500.0
	var k := 0
	while x < 2800.0:
		var tone := Color(0.52, 0.40, 0.34).darkened(0.3 + 0.1 * float(k % 3))
		c.draw_rect(Rect2(x, -200.0 - float(k % 2) * 80.0, 300.0, FEET + 200.0), tone)
		for fl in range(3):
			for w in range(2):
				var win := Rect2(x + 50.0 + float(w) * 120.0, -120.0 + float(fl) * 150.0, 80.0, 100.0)
				c.draw_rect(win, Color(1.0, 0.80, 0.46) if (k + fl + w) % 3 != 0 else Color(0.14, 0.12, 0.18))
		c.draw_rect(Rect2(x + 30.0, 330.0, 240.0, 150.0), Color(1.0, 0.86, 0.60, 0.85) if k % 2 == 0 else Color(0.20, 0.18, 0.22))
		x += 300.0
		k += 1

	# Onlookers celebrating after flash
	var cheer_amp := Anim.span(t, FLASH_AT, FLASH_AT + 0.4)
	for i in range(16):
		var ox := -900.0 + float(i) * 180.0 + sin(float(i) * 2.1) * 30.0
		var jump := absf(sin(t * 8.0 + float(i) * 1.2)) * 24.0 * cheer_amp
		var oy := FEET - 70.0 - jump
		var col := Color(0.14, 0.12, 0.18)
		c.draw_rect(Rect2(ox - 14.0, oy - 70.0, 28.0, 70.0), col)
		c.draw_circle(Vector2(ox, oy - 84.0), 15.0, col)
		if cheer_amp > 0.1:
			var arm_ang := -PI * 0.4 + sin(t * 10.0 + float(i)) * 0.3
			c.draw_line(Vector2(ox, oy - 60.0), Vector2(ox, oy - 60.0) + Vector2.from_angle(arm_ang) * 40.0, col, 8.0)
		if i % 3 == 0:
			c.draw_rect(Rect2(ox + 24.0, FEET - 110.0, 60.0, 8.0), col)
			c.draw_rect(Rect2(ox + 50.0, FEET - 110.0, 6.0, 60.0), col)

	# Palms
	for px: float in [-600.0, 80.0, 980.0, 1680.0]:
		c.draw_line(Vector2(px, FEET - 40.0), Vector2(px + 30.0, 40.0), PALM_TRUNK, 26.0)
		for f in range(7):
			var a := -PI * 0.5 + (float(f) / 6.0 - 0.5) * 3.0 + sin(t * 1.3 + float(f)) * 0.04
			var tip := Vector2(px + 30.0, 40.0) + Vector2.from_angle(a) * 220.0 + Vector2(0, 60)
			c.draw_line(Vector2(px + 30.0, 40.0), tip, PALM_LEAF, 14.0)

	# Panot pavement
	c.draw_rect(Rect2(-1600, FEET - 40.0, 4600, 600.0), PANOT)
	for px in range(-15, 30):
		c.draw_line(Vector2(float(px) * 90.0, FEET - 40.0), Vector2(float(px) * 90.0 - 40.0, FEET + 200.0),
			PANOT.darkened(0.12), 2.0)


static func _plinth(c: CanvasItem, _t: float) -> void:
	var r := Rect2(PLINTH_X - PLINTH_W * 0.5, PLINTH_TOP, PLINTH_W, FEET - PLINTH_TOP + 10.0)
	c.draw_rect(r.grow(4.0), INK)
	c.draw_rect(r, STONE)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 18.0)), STONE.lightened(0.12))
	c.draw_rect(Rect2(Vector2(r.position.x - 10.0, FEET - 22.0), Vector2(r.size.x + 20.0, 26.0)), STONE_DARK)
	# Inscribed plaque
	var plaque := Rect2(PLINTH_X - 70.0, PLINTH_TOP + 36.0, 140.0, 50.0)
	c.draw_rect(plaque, BRONZE_DARK)
	c.draw_rect(plaque.grow(-3.0), BRONZE_LIT)


static func _toppled_cat(c: CanvasItem, t: float) -> void:
	var vibe := sin(t * 18.0) * 1.5
	var cat_at := Vector2(PLINTH_X + 65.0, PLINTH_TOP + vibe)
	var k := 0.88
	var p := func(v: Vector2) -> Vector2: return cat_at + v * k

	# Shadow on the stone plinth
	c.draw_colored_polygon(MillieSide.ellipse(cat_at + Vector2(0, 2) * k, Vector2(160, 12) * k), Color(0, 0, 0, 0.32))

	# Curled relaxed tail
	var tail := PackedVector2Array()
	var sw := sin(t * 4.0) * 14.0
	for i in range(9):
		var f := float(i) / 8.0
		tail.append(p.call(Vector2(140.0 + f * 40.0 + sin(f * PI) * sw * 0.2, -60.0 - f * 80.0 + sw * f)))
	c.draw_polyline(tail, INK, 30.0 * k)
	c.draw_polyline(tail, BRONZE_BASE, 24.0 * k)

	# Chubby belly lying comfortably
	var bc := Vector2(0, -78)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(165, 96) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc), Vector2(160, 90) * k), BRONZE_BASE)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(-20, -25)), Vector2(100, 42) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(-50, -45)), Vector2(35, 12) * k), BRONZE_SPEC)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(bc + Vector2(10, 45)), Vector2(130, 32) * k), BRONZE_DARK)

	# Relaxed paws
	for i in range(4):
		var paw_base: Vector2 = [Vector2(-90, -40), Vector2(-30, -35), Vector2(30, -35), Vector2(90, -40)][i]
		var paw_tip: Vector2 = paw_base + Vector2(sin(float(i) + t * 2.0) * 4.0, 38.0)
		var col := BRONZE_DARK if i % 2 == 0 else BRONZE_BASE
		c.draw_line(p.call(paw_base), p.call(paw_tip), INK, 34.0 * k)
		c.draw_line(p.call(paw_base), p.call(paw_tip), col, 26.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(paw_tip), Vector2(18, 10) * k), col)

	# Round contented head resting on paws
	var hc := Vector2(-120, -110)
	for s: float in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([p.call(hc + Vector2(-24 + s * 12, -40)), p.call(hc + Vector2(-12 + s * 12, -78)),
			p.call(hc + Vector2(0 + s * 12, -44))]), BRONZE_DARK if s < 0.0 else BRONZE_BASE)
	c.draw_circle(p.call(hc), 64.0 * k, INK)
	c.draw_circle(p.call(hc), 59.0 * k, BRONZE_BASE)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(-10, -20)), Vector2(35, 18) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(38, 18)), Vector2(26, 18) * k), BRONZE_LIT)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(hc + Vector2(-48, 8)), Vector2(9, 6) * k), NOSE_DARK)

	# Contented shut eyes (purring curved lines)
	var eye := hc + Vector2(-22, -8)
	c.draw_line(p.call(eye + Vector2(-12, 2)), p.call(eye + Vector2(0, -3)), EYE_PUPIL, 3.5 * k)
	c.draw_line(p.call(eye + Vector2(0, -3)), p.call(eye + Vector2(12, 2)), EYE_PUPIL, 3.5 * k)

	# Whiskers
	for w in range(3):
		var wy := 14.0 + float(w) * 8.0
		c.draw_line(p.call(hc + Vector2(-40, wy)), p.call(hc + Vector2(-90, wy - 8.0 + float(w) * 8.0)), WHISKER_WIRE, 2.2 * k)

	# Purring vibration bubbles / hearts
	for h in range(3):
		var ht := fmod(t * 1.5 + float(h) * 0.7, 2.1)
		var h_pos: Vector2 = p.call(hc) + Vector2(sin(ht * 4.0) * 16.0 - 20.0, -50.0 - ht * 45.0)
		var ha := clampf(1.0 - ht / 2.1, 0.0, 1.0) * 0.75
		c.draw_circle(h_pos, 5.0 + ht * 3.0, Color(0.98, 0.70, 0.75, ha * 0.4))
		c.draw_circle(h_pos, 3.0 + ht * 2.0, Color(1.0, 0.85, 0.90, ha))


static func _dog(c: CanvasItem, t: float) -> void:
	var mx: float
	var my: float
	var ground_y := FEET
	var face := 1.0
	var trot := 0.0
	var jump := 0.0
	var proud := 0.0

	if t < HOP_START:
		mx = Anim.k(t, [[0.0, 940.0], [HOP_START, 740.0, "io"]])
		my = FEET
		trot = 1.0
		face = -1.0
	elif t < HOP_END:
		var f := Anim.span(t, HOP_START, HOP_END)
		mx = lerpf(740.0, PLINTH_X - 85.0, f)
		my = lerpf(FEET, PLINTH_TOP, f) - sin(f * PI) * 110.0
		jump = sin(f * PI)
		face = -1.0
		ground_y = lerpf(FEET, PLINTH_TOP, f)
	else:
		mx = PLINTH_X - 85.0
		my = PLINTH_TOP
		proud = 1.0
		face = 1.0
		ground_y = PLINTH_TOP

	var yap := absf(sin(t * 14.0)) if proud > 0.0 and t < FLASH_AT + 1.2 else 0.0
	var pose := {
		"gait": trot,
		"phase": mx * TAU / (48.0 * S),
		"crouch": 0.25 * jump,
		"lean": 0.2 * jump - 0.15 * proud,
		"push": jump * 0.8,
		"reach": jump * 0.8,
		"head_up": 0.2 * trot + 0.65 * proud,
		"ear": 1.2 * proud + 0.3 * jump,
		"tail": 0.7 * proud + sin(t * 16.0) * 0.35 * proud + sin(t * 12.0) * 0.3 * trot,
		"mouth": 0.3 + 0.6 * yap if proud > 0.0 else 0.0,
		"brow": 0.8 * proud,
	}

	var sq := Anim.squash(1.0 + 0.2 * jump)
	IntroKit.millie(c, Vector2(mx, my), S * 1.05, face, sq, pose, ground_y)


static func _human(c: CanvasItem, t: float) -> void:
	var hx: float = Anim.k(t, [[0.0, 1180.0], [HUMAN_STOP, 860.0, "io"], [LENGTH, 860.0]])
	var walking := t < HUMAN_STOP
	var aiming := Anim.span(t, AIM_AT, FLASH_AT)
	var proud_human := Anim.span(t, FLASH_AT, FLASH_AT + 0.5)

	var hpose := {
		"stride": t * 7.5 if walking else 0.0,
		"stride_amp": 0.7 if walking else 0.0,
		"phone": 1.0,
		"glow": 0.6 if t < FLASH_AT else 0.1,
		"reach": 0.35 + 0.45 * aiming,
		"lean": -0.15 * aiming + 0.1 * proud_human,
		"head": -0.25 * aiming - 0.15 * proud_human,
		"mouth": 0.4 * aiming + 0.8 * proud_human,
	}

	var hand := IntroKit.human(c, Vector2(hx, FEET), S, -1.0, Vector2.ONE, hpose, 0.0, FEET)

	# Flash burst from phone
	if t >= FLASH_AT and t < FLASH_AT + 0.4:
		var f := Anim.span(t, FLASH_AT, FLASH_AT + 0.4)
		var flash_pos := hand + Vector2(-12.0, -18.0)
		c.draw_circle(flash_pos, 280.0 * (1.0 - f), Color(1.0, 0.98, 0.85, (1.0 - f) * 0.85))
		c.draw_circle(flash_pos, 90.0, Color(1.0, 1.0, 1.0, (1.0 - f)))


static func _fireworks(c: CanvasItem, t: float) -> void:
	var dt := t - FLASH_AT
	var bursts: Array[Dictionary] = [
		{"cx": 320.0, "cy": 160.0, "t0": 0.15, "col": Color(1.0, 0.35, 0.25)},
		{"cx": 680.0, "cy": 110.0, "t0": 0.55, "col": Color(0.98, 0.86, 0.28)},
		{"cx": 940.0, "cy": 180.0, "t0": 0.95, "col": Color(0.25, 0.72, 0.98)},
	]
	for b in bursts:
		var bt: float = dt - float(b["t0"])
		if bt > 0.0 and bt < 1.1:
			var f := bt / 1.1
			var col: Color = b["col"]
			var r := 160.0 * sin(f * PI * 0.5)
			c.draw_arc(Vector2(b["cx"], b["cy"]), r, 0.0, TAU, 32, Color(col.r, col.g, col.b, (1.0 - f) * 0.8), 3.5)
			for i in range(12):
				var a := float(i) * (TAU / 12.0)
				var pt := Vector2(b["cx"], b["cy"]) + Vector2.from_angle(a) * r
				c.draw_circle(pt, 4.0 * (1.0 - f), Color(1.0, 1.0, 0.9, 1.0 - f))


static func _confetti(c: CanvasItem, t: float) -> void:
	var dt := t - FLASH_AT
	var cols := [Color(0.96, 0.32, 0.28), Color(0.98, 0.84, 0.25), Color(0.24, 0.68, 0.96), Color(0.35, 0.86, 0.42)]
	for i in range(40):
		var seed_i := float(i) * 137.5
		var cx := fmod(seed_i * 19.3, 1280.0)
		var cy := fmod(seed_i * 31.7 + dt * (180.0 + sin(seed_i) * 60.0), 720.0)
		var rot := dt * 5.0 + seed_i
		var col: Color = cols[i % 4]
		var sz := Vector2(10.0, 6.0)
		c.draw_set_transform(Vector2(cx, cy), rot, Vector2.ONE)
		c.draw_rect(Rect2(-sz * 0.5, sz), col)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(0.98, 0.86, 0.52), Color(0.55, 0.32, 0.20))
	FilmKit.slam(c, t, "EL REI!", Vector2(640, 220))
	IntroTitle.word(c, "VICTORIA AL RAVAL", Vector2(640, 420), 46)
	IntroTitle.word(c, "THE RAMBLA IS YOURS", Vector2(640, 490), 30)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.98, 0.88))
