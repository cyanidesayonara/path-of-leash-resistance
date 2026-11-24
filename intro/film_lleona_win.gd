class_name FilmLleonaWin
extends RefCounted

# Girona's victory film: La Lleona settled. The square after the fight, the
# rain easing. She sits dazed on the paving; the dog trots up and boops her
# nose, and the gold eyes open, kindly now. She springs back up her column and
# takes hold, purring. The sun comes out under the cloud, the stone pigeon
# cracks and is a pigeon again, and the dog climbs the iron steps and does what
# everyone who means to come back to Girona does: kisses the lioness behind.
# Your human arrives in time to miss it.

const F := preload("res://intro/film_lleona.gd")

const LENGTH := FilmKit.LENGTH
const BG := Color(0.16, 0.16, 0.30)
const FEET := 640.0
const COL_X := 160.0
const CLING_Y := 566.0
const SIT_X := 470.0
const K := 0.94
const S := FilmKit.S
const BOOP_AT := 1.3
const STAND_AT := 1.95
const LEAP_AT := 2.35
const HOLD_AT := 2.8             # back on her column
const BIRD_AT := 3.2             # the pigeon is a pigeon again
const STEPS_AT := 3.1            # the dog on the iron steps
const KISS_AT := 4.15
const HUMAN_STOP := 3.0
const TITLE_AT := FilmKit.TITLE_AT
const STEP_POS := Vector2(COL_X + 212.0, FEET - 46.0)
const BIRD_X := -10.0
const INK := IntroKit.INK
const PETALS: Array[Color] = [Color(0.92, 0.34, 0.46), Color(0.98, 0.78, 0.30), Color(0.74, 0.46, 0.84), Color(1.0, 0.94, 0.90)]
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.2, "whoop", 1.0, -8.0],
	[BOOP_AT, "bark", 1.25, -2.0],
	[BOOP_AT + 0.05, "star", 1.1, -3.0],
	[STAND_AT, "snort", 0.8, -5.0],
	[LEAP_AT, "fling", 0.7, -7.0],
	[HOLD_AT, "drum", 0.5, -2.0],
	[HOLD_AT + 0.2, "gat_purr", 0.8, -3.0],
	[BIRD_AT, "crack", 1.6, -5.0],
	[BIRD_AT + 0.1, "rustle", 1.4, -6.0],
	[KISS_AT, "pickup", 1.4, -2.0],
	[KISS_AT + 0.1, "star", 1.25, -3.0],
	[KISS_AT + 0.4, "whoop", 1.2, -4.0],
	[TITLE_AT, "lion_roar", 1.15, -5.0],
	[TITLE_AT + 0.1, "star", 1.0, -3.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var x: float = Anim.k(t, [[0.0, 620.0], [STAND_AT, 600.0, "io"], [HOLD_AT, 420.0, "io"], [3.6, 430.0], [KISS_AT, 330.0, "io"], [TITLE_AT, 380.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [STAND_AT, 470.0], [HOLD_AT, 400.0, "io"], [3.6, 420.0], [KISS_AT, 450.0, "io"], [TITLE_AT, 400.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.0], [STAND_AT, 1.06, "io"], [HOLD_AT, 0.94, "io"], [3.6, 1.0], [KISS_AT, 1.34, "io"], [4.8, 1.3], [TITLE_AT, 0.95, "io"]])
	return [Vector2(x, y), z]


static func lleona_at(t: float) -> Vector2:
	if t < LEAP_AT:
		return Vector2(SIT_X, FEET)
	if t < HOLD_AT:
		var f := Anim.span(t, LEAP_AT, HOLD_AT)
		return Vector2(lerpf(SIT_X, COL_X, f), lerpf(FEET, CLING_Y, f) - sin(f * PI) * 90.0)
	return Vector2(COL_X, CLING_Y)


# her pose at t, shared with the tests and whoever reaches for her nose or tail
static func pose(t: float, t_real: float) -> Dictionary:
	var stood := Anim.span(t, STAND_AT, LEAP_AT - 0.1)
	# the kiss: her eyes pop open, then she likes it
	var startled := t >= KISS_AT and t < KISS_AT + 0.5
	var content := t >= HOLD_AT + 0.25 and not startled
	return {
		"sit": 1.0 - stood,
		"cling": Anim.span(t, HOLD_AT - 0.2, HOLD_AT),
		"slump": 1.0 - Anim.span(t, BOOP_AT, BOOP_AT + 0.3),
		"eye": Anim.span(t, BOOP_AT, BOOP_AT + 0.2),
		"turn": 1.0,
		"happy": content,
		"jaw": 0.0, "soft": true, "ground": FEET,
		"crouch": Anim.span(t, LEAP_AT - 0.2, LEAP_AT) * (1.0 - Anim.span(t, LEAP_AT, LEAP_AT + 0.1)),
		"tilt": 0.04 * sin(t_real * 5.0) if content else (-0.22 if startled else 0.0),
	}


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	var wet := 1.0 - Anim.span(t_real, 2.2, 3.3)
	F.placa(c, t_real, wet)
	F.column(c, COL_X, FEET)
	var o := pose(t, t_real)
	var at := lleona_at(t)
	F.lleona(c, at, K, t_real, o)
	if t < BOOP_AT:
		# dazed: stars round her head
		for i in range(4):
			var a := t_real * 3.2 + float(i) * TAU / 4.0
			c.draw_circle(at + (F.head_pos(o) + Vector2(cos(a) * 62.0, -70.0 + sin(a) * 16.0)) * K, 6.0, Color(1.0, 0.90, 0.40))
	if t >= HOLD_AT and t < HOLD_AT + 0.5:
		var f := Anim.span(t, HOLD_AT, HOLD_AT + 0.5)
		for i in range(6):
			IntroKit.puff(c, Vector2(COL_X - 60.0 + float(i) * 34.0, CLING_Y - 60.0 - float(i % 2) * 120.0 + f * 40.0), 16.0 * (1.0 - f), 1.0 - f)
	_bird(c, t, t_real)
	_human(c, t_real)
	_dog(c, t_real)
	if t_real >= BOOP_AT and t_real < BOOP_AT + 0.6:
		_spark(c, F.nose_pos(at, K, o), Anim.span(t_real, BOOP_AT, BOOP_AT + 0.55))
	if t_real >= KISS_AT:
		_hearts(c, t_real, Vector2(STEP_POS.x - 108.0, STEP_POS.y - 92.0))
	F.rain(c, t_real, wet)
	if wet < 1.0:
		_petals(c, t_real, 1.0 - wet)
	FilmKit.fades(c, t_real)


# the pigeon of the wake film, still stone, cracking out of it and away
static func _bird(c: CanvasItem, t: float, t_real: float) -> void:
	var at := Vector2(BIRD_X, FEET - 14.0)
	if t < BIRD_AT:
		F.pigeon(c, at + Vector2(sin(t_real * 60.0) * 2.0 * Anim.span(t, BIRD_AT - 0.3, BIRD_AT), 0.0), t_real, false, true)
		return
	var f := Anim.span(t, BIRD_AT, BIRD_AT + 1.2)
	F.pigeon(c, at + Vector2(f * 90.0, -f * 760.0 + sin(t_real * 9.0) * 10.0), t_real, true, false)
	var g := Anim.span(t, BIRD_AT, BIRD_AT + 0.6)
	if g < 1.0:
		for i in range(9):
			var d := Vector2.from_angle(float(i) * TAU / 9.0)
			c.draw_circle(at + d * (10.0 + g * 60.0) + Vector2(0.0, g * g * 60.0), 5.0 * (1.0 - g) + 1.0, Color(F.STONE_LIT, 1.0 - g))


# in from the right to boop her nose; then, when she is up, to the iron steps,
# up them, and the kiss
static func _dog(c: CanvasItem, t: float) -> void:
	# a small dog has a short reach, so she stands in closer
	var g: Node = c.get_node_or_null("/root/Game")
	var size := MillieSide.breed_scale(MillieSide.breed_id_of(str(g.dog))) if g != null and g.get("dog") != null else 1.0
	var near := 108.0 * (1.0 - size)
	var mx := 0.0
	var my := FEET
	var trot := 0.0
	var boop := 0.0
	var kiss := 0.0
	if t < BOOP_AT:
		mx = Anim.k(t, [[0.0, 1080.0], [BOOP_AT - 0.1, SIT_X + 216.0 - near, "io"], [BOOP_AT, SIT_X + 200.0 - near]])
		trot = 1.0 - Anim.span(t, BOOP_AT - 0.3, BOOP_AT)
		boop = Anim.span(t, BOOP_AT - 0.15, BOOP_AT)
	elif t < STEPS_AT:
		mx = SIT_X + 200.0 - near + (120.0 + near) * Anim.span(t, BOOP_AT + 0.4, STAND_AT)
		boop = 1.0 - Anim.span(t, BOOP_AT + 0.25, BOOP_AT + 0.5)
	else:
		var f := Anim.span(t, STEPS_AT, KISS_AT - 0.2)
		mx = lerpf(SIT_X + 320.0, STEP_POS.x - near, f)
		# up the three steps over the last of the way, a hop for each
		var up := Anim.span(t, KISS_AT - 0.55, KISS_AT - 0.2)
		my = FEET - 46.0 * up - absf(sin(up * PI * 2.0)) * 12.0
		trot = 1.0 - Anim.span(t, KISS_AT - 0.3, KISS_AT - 0.15)
		kiss = Anim.span(t, KISS_AT - 0.15, KISS_AT) * (1.0 - Anim.span(t, KISS_AT + 0.45, KISS_AT + 0.7))
	var glad := Anim.span(t, KISS_AT + 0.5, KISS_AT + 0.8) + Anim.span(t, BOOP_AT + 0.5, STAND_AT) * (1.0 - Anim.span(t, STEPS_AT, STEPS_AT + 0.1))
	var bark := boop if t >= BOOP_AT else 0.0
	var pose := {
		"gait": trot, "phase": mx * TAU / (48.0 * S),
		"reach": 0.5 * maxf(boop, kiss) + 0.1 * trot, "push": 0.35 * maxf(boop, kiss) + 0.1 * trot,
		"lean": -0.25 * maxf(boop, kiss), "head_up": 0.35 * boop + 0.75 * kiss + 0.5 * glad,
		"ear": 0.9 * maxf(boop, kiss) + 0.8 * glad,
		"tail": sin(t * 20.0) * 0.5 * maxf(maxf(glad, kiss), trot) + 0.3, "mouth": 0.6 * bark + 0.5 * glad,
		"brow": 0.4 * glad,
	}
	IntroKit.millie(c, Vector2(mx, my), S * 1.02, -1.0, Anim.squash(1.0 + 0.14 * maxf(boop, kiss)), pose, my)


# your human: in from the right on the phone, stops, and looks up from it
# the moment after the kiss, to see nothing at all
static func _human(c: CanvasItem, t: float) -> void:
	var hx: float = Anim.k(t, [[0.0, 1320.0], [HUMAN_STOP, 900.0, "io"], [LENGTH, 900.0]])
	var walking := t < HUMAN_STOP
	var up := Anim.span(t, KISS_AT + 0.6, KISS_AT + 0.9)
	var hpose := {
		"scroll": t * 1.3, "stride": t * 7.5 if walking else 0.0, "stride_amp": 0.7 if walking else 0.0,
		"phone": 1.0, "glow": 0.5 * (1.0 - up), "reach": 0.4, "head": -0.3 * up, "mouth": 0.35 * up,
	}
	IntroKit.human(c, Vector2(hx, FEET), S, -1.0, Vector2.ONE, hpose, 0.0, FEET)
	if up > 0.0:
		IntroKit.dots(c, Vector2(hx - 10.0, FEET - 300.0), t - KISS_AT - 0.6)


static func _spark(c: CanvasItem, at: Vector2, f: float) -> void:
	var r := 52.0 * sin(f * PI * 0.5)
	c.draw_arc(at, r, 0.0, TAU, 24, Color(1.0, 0.90, 0.35, (1.0 - f) * 0.85), 3.0)
	for i in range(8):
		c.draw_circle(at + Vector2.from_angle(float(i) * TAU / 8.0) * r, 3.5 * (1.0 - f), Color(1.0, 1.0, 0.85, 1.0 - f))


static func _heart(c: CanvasItem, at: Vector2, r: float, a: float) -> void:
	for pass_i in range(2):
		var g := r + (4.0 if pass_i == 0 else 0.0)
		var col := Color(INK, a) if pass_i == 0 else Color(1.0, 0.40, 0.56, a)
		for s: float in [-1.0, 1.0]:
			c.draw_circle(at + Vector2(s * r * 0.5, -r * 0.3), g * 0.58, col)
		c.draw_colored_polygon(PackedVector2Array([at + Vector2(-g * 1.0, -r * 0.1), at + Vector2(g * 1.0, -r * 0.1), at + Vector2(0.0, g * 1.15)]), col)


static func _hearts(c: CanvasItem, t: float, at: Vector2) -> void:
	for i in range(6):
		var t0 := KISS_AT + float(i) * 0.11
		var f := Anim.span(t, t0, t0 + 1.3)
		if f <= 0.0 or f >= 1.0:
			continue
		_heart(c, at + Vector2(sin(f * 5.0 + float(i) * 1.9) * 30.0 + (float(i) - 2.5) * 12.0, -f * 190.0),
			(12.0 + float(i % 3) * 5.0) * minf(1.0, f * 6.0), clampf((1.0 - f) * 2.5, 0.0, 1.0))


static func _petals(c: CanvasItem, t: float, a: float) -> void:
	for i in range(30):
		var s := float(i) * 113.7
		var at := Vector2(-300.0 + fmod(s * 17.1, 1500.0) + sin(t * 1.6 + s) * 24.0, -100.0 + fmod(s * 29.3 + t * (110.0 + sin(s) * 40.0), 820.0))
		c.draw_set_transform(at, t * 3.0 + s, Vector2.ONE)
		c.draw_rect(Rect2(-4.5, -3.0, 9.0, 6.0), Color(PETALS[i % 4], a))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, -100.0, 1680, 924.0), Color(0.42, 0.48, 0.74), Color(1.0, 0.78, 0.46))
	var d := t - TITLE_AT
	F.lleona(c, Vector2(-270.0 + d * 40.0, 1010.0), 2.6, t, {"eye": 1.0, "happy": true, "turn": 1.0})
	FilmKit.slam(c, t, "LA LLEONA!", Vector2(740, 210))
	IntroTitle.word(c, "VICTÒRIA A GIRONA", Vector2(760, 420), 46)
	IntroTitle.word(c, "GIRONA IS YOURS", Vector2(760, 490), 30)
	_petals(c, t, 1.0)
	var ml := Engine.get_main_loop()
	var gm: Node = ml.root.get_node_or_null("Game") if ml != null and ml is SceneTree else null
	if gm == null or bool(gm.flashes):
		IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.98, 0.90))
