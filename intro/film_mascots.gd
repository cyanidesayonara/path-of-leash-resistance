class_name FilmMascots
extends RefCounted

# Les Atraccions' film, "Group hug": the telegraph to run as the walk turns
# for home (systems/home_chase.gd plays it through intro/film_player.gd). The
# park on a bright afternoon, side on: the big coaster's loop, the wheel, the
# bunting, and a little bandstand where the five mascots stand waving at
# nobody, mechanical, grins fixed. The two of them walk past, your human on
# the phone. The band organ winds down to a stop: her ears go up and she looks
# back. The waving has stopped. One head turns, then the next, then all five,
# and the big one in the middle, the dog that is not a dog, tips its head and
# opens its arms. They step down off the stage together and come, arms out. A
# push in on her face. She bolts, your human is yanked off after her, and
# HUG! slams in round a grin that fills the frame. The five are the walk's
# (entities/mascot_threat.gd).

const Cast := preload("res://entities/mascot_threat.gd")

const LENGTH := FilmKit.LENGTH
const BG := Color(0.50, 0.78, 0.94)
const FEET := 640.0
const STAGE_X := -230.0
const STAGE_TOP := FEET - 84.0
const STOP_AT := 1.3               # the organ stops, and the waving
const TURN_AT := 1.95              # the first head
const TURN_STEP := 0.13            # and one after another
const TIP_AT := 2.65               # the dog tips its head
const DOWN_AT := 2.95              # off the stage
const LAND_AT := 3.2
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const K := 1.2
# the line as they stand: [who, x on the stage, how much bigger]
const LINE := [["gull", -370.0, 0.92], ["sun", -196.0, 0.92], ["prawn", 196.0, 0.92], ["lizard", 370.0, 0.92], ["dog", 0.0, 1.2]]
# the order their heads turn in: from the far side, the dog last
const TURNS := [0, 1, 3, 2, 4]
const INK := IntroKit.INK
const PAVE := Color(0.88, 0.82, 0.72)
const PAVE_DARK := Color(0.76, 0.69, 0.60)
const TRACK := Color(0.86, 0.22, 0.52)
const STEEL := Color(0.94, 0.94, 0.96)
const TURQ := Color(0.18, 0.70, 0.68)
const SAFFRON := Color(0.96, 0.72, 0.18)
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[0.05, "chime", 1.1, -9.0],
	[0.45, "chime", 1.25, -10.0],
	[0.85, "chime", 0.9, -9.0],
	[1.15, "chime", 0.55, -8.0],
	[STOP_AT, "groan", 0.6, -6.0],
	[TURN_AT, "crack", 1.7, -10.0],
	[TURN_AT + 0.13, "crack", 1.6, -9.0],
	[TURN_AT + 0.26, "crack", 1.5, -8.0],
	[TURN_AT + 0.39, "crack", 1.4, -7.0],
	[TURN_AT + 0.52, "crack", 1.0, -5.0],
	[TIP_AT, "ooooh", 0.5, -6.0],
	[LAND_AT, "drum", 0.5, -1.0],
	[LAND_AT + 0.25, "drum", 0.6, -5.0],
	[LAND_AT + 0.5, "drum", 0.6, -4.0],
	[STARE_WHOOP, "whoop", 0.6, -5.0],
	[BOLT_AT, "bark", 1.1, -4.0],
	[TITLE_AT, "gat_roar", 1.3, -5.0],
]
const STARE_WHOOP := 4.3


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var shake := Vector2.ZERO
	var ml := Engine.get_main_loop()
	var gm: Node = ml.root.get_node_or_null("Game") if ml != null and ml is SceneTree else null
	if t >= LAND_AT and (gm == null or bool(gm.screen_shake)):
		shake = Vector2(sin(t * 83.0), sin(t * 59.0)) * 9.0 * (1.0 - Anim.span(t, LAND_AT, LAND_AT + 0.3))
	if t >= BOLT_AT:
		return [Vector2(Anim.k(t, [[BOLT_AT, 620.0], [TITLE_AT, 800.0, "in"]]), 450.0) + shake, 1.02]
	var x: float = Anim.k(t, [[0.0, 560.0], [1.5, 640.0, "io"], [1.95, -230.0, "io"], [DOWN_AT, -220.0], [3.3, 0.0, "io"],
		[3.9, 140.0, "io"], [4.2, 700.0, "io"], [BOLT_AT, 730.0]])
	var y: float = Anim.k(t, [[0.0, 450.0], [1.5, 460.0], [1.95, 350.0, "io"], [TIP_AT, 330.0, "io"], [DOWN_AT, 330.0], [3.3, 420.0, "io"], [4.2, 540.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.0], [1.5, 1.15, "io"], [1.95, 1.12, "io"], [TIP_AT, 1.55, "io"], [DOWN_AT, 1.5], [3.3, 0.96, "io"],
		[4.2, 1.36, "io"], [BOLT_AT, 1.46]])
	return [Vector2(x, y) + shake, z]


# where a mascot's feet are: on the stage, the step down, then coming on
static func at(i: int, t: float) -> Vector2:
	var sx := STAGE_X + float(LINE[i][1])
	if t < DOWN_AT:
		return Vector2(sx, STAGE_TOP)
	var f := Anim.span(t, DOWN_AT, LAND_AT)
	var run := maxf(0.0, t - LAND_AT)
	var go := 92.0 * run + (maxf(0.0, t - BOLT_AT) * 150.0)
	var y := lerpf(STAGE_TOP, FEET, f * f) - sin(f * PI) * 34.0
	if run > 0.0:
		y = FEET - absf(sin(t * 8.0 + float(i) * 1.3)) * 12.0 + (6.0 if float(LINE[i][2]) > 1.0 else -4.0)
	return Vector2(sx + 70.0 * f + go, y)


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_park(c, t_real)
	_stage(c, t)
	for n in range(LINE.size()):
		var who := String(LINE[n][0])
		var turn_from := TURN_AT + float(TURNS.find(n)) * TURN_STEP
		var turn := Anim.span(t, turn_from, turn_from + 0.09)
		var waving := 1.0 - Anim.span(t, STOP_AT, STOP_AT + 0.1)
		var arms := Anim.span(t, TIP_AT + float(n % 3) * 0.05, TIP_AT + 0.25 + float(n % 3) * 0.05)
		var tip := (0.30 * Anim.span(t, TIP_AT, TIP_AT + 0.3)) if who == "dog" else 0.0
		mascot(c, at(n, t), K * float(LINE[n][2]), who, t_real, {"wave": waving, "turn": turn, "arms": arms, "tip": tip,
			"run": 1.0 if t > LAND_AT else 0.0, "ph": float(n) * 1.1})
	if t >= LAND_AT and t < LAND_AT + 0.55:
		var f := Anim.span(t, LAND_AT, LAND_AT + 0.55)
		for i in range(10):
			IntroKit.puff(c, Vector2(STAGE_X - 220.0 + float(i) * 70.0, FEET - f * 16.0), 22.0 * (1.0 - f), 1.0 - f)
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


# --- the park ---------------------------------------------------------------------

static func _park(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1600, -900.0, 4600, 1500.0), Color(0.32, 0.66, 0.92), Color(0.94, 0.93, 0.80))
	for i in range(7):
		var cx := -1400.0 + float(i) * 620.0 + t * 8.0
		for q in range(4):
			c.draw_circle(Vector2(cx + float(q) * 52.0, -180.0 + float((i * 7 + q * 3) % 5) * 16.0), 46.0 - float(q % 2) * 12.0, Color(1.0, 1.0, 1.0, 0.75))
	# the coaster: its hills on white lattice, the loop, the train round it
	var pts := _track()
	for i in range(0, pts.size(), 3):
		var p := pts[i]
		if p.y < 470.0:
			c.draw_line(p, Vector2(p.x, 520.0), STEEL.darkened(0.12), 5.0)
			if i + 3 < pts.size() and absf(pts[i + 3].x - p.x) < 90.0:
				c.draw_line(Vector2(p.x, lerpf(p.y, 520.0, 0.5)), Vector2(pts[i + 3].x, lerpf(pts[i + 3].y, 520.0, 0.5)), STEEL.darkened(0.12), 3.0)
	c.draw_polyline(pts, TRACK.darkened(0.35), 15.0)
	c.draw_polyline(pts, TRACK, 9.0)
	for car in range(5):
		var u := fposmod(t * 0.17 - float(car) * 0.016, 1.0) * float(pts.size() - 1)
		var a := pts[int(u)]
		var q := a.lerp(pts[mini(int(u) + 1, pts.size() - 1)], u - floorf(u))
		c.draw_circle(q, 18.0, INK)
		c.draw_circle(q, 14.0, TURQ if car > 0 else SAFFRON)
	# the wheel
	var wc := Vector2(1060.0, 210.0)
	c.draw_line(wc, Vector2(960.0, 520.0), STEEL.darkened(0.2), 12.0)
	c.draw_line(wc, Vector2(1160.0, 520.0), STEEL.darkened(0.2), 12.0)
	c.draw_arc(wc, 220.0, 0.0, TAU, 48, STEEL, 9.0)
	c.draw_arc(wc, 196.0, 0.0, TAU, 48, STEEL.darkened(0.1), 4.0)
	for i in range(12):
		var d := Vector2.from_angle(float(i) * TAU / 12.0 + t * 0.12)
		c.draw_line(wc, wc + d * 220.0, STEEL.darkened(0.06), 4.0)
		var cab := wc + d * 220.0 + Vector2(0.0, 14.0)
		c.draw_circle(cab, 24.0, INK)
		c.draw_circle(cab, 20.0, [TRACK, TURQ, SAFFRON][i % 3])
	c.draw_circle(wc, 20.0, SAFFRON)
	# hedges, bunting strung across, the paving
	for i in range(26):
		var hx := -1560.0 + float(i) * 170.0
		c.draw_circle(Vector2(hx, 520.0), 74.0 + float(i % 3) * 14.0, Color(0.24, 0.52, 0.28))
		c.draw_circle(Vector2(hx - 18.0, 500.0), 44.0, Color(0.36, 0.64, 0.34))
	for span in range(5):
		var x0 := -1300.0 + float(span) * 640.0
		var prev := Vector2(x0, 130.0)
		c.draw_line(Vector2(x0, 120.0), Vector2(x0, 560.0), Color(0.92, 0.92, 0.94), 9.0)
		for k in range(1, 13):
			var u := float(k) / 12.0
			var q := Vector2(x0 + u * 640.0, 130.0 + sin(u * PI) * 70.0)
			c.draw_line(prev, q, INK, 2.5)
			c.draw_colored_polygon(PackedVector2Array([prev + Vector2(8.0, 2.0), q + Vector2(-8.0, 2.0), prev.lerp(q, 0.5) + Vector2(sin(t * 3.0 + float(k)) * 4.0, 34.0)]),
				[TRACK, SAFFRON, TURQ, Color(0.96, 0.96, 0.92)][k % 4])
			prev = q
	c.draw_rect(Rect2(-1600, 552.0, 4600, 800.0), PAVE)
	c.draw_rect(Rect2(-1600, 552.0, 4600, 12.0), PAVE_DARK)
	for row in range(4):
		var y := 592.0 + float(row * row) * 18.0 + float(row) * 18.0
		c.draw_line(Vector2(-1600, y), Vector2(3000, y), Color(PAVE_DARK, 0.7), 2.5)
	for i in range(40):
		var jx := -1600.0 + float(i) * 116.0
		c.draw_line(Vector2(jx, 564.0), Vector2(jx - 60.0, 900.0), Color(PAVE_DARK, 0.45), 2.0)


static func _track() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(40):
		var u := float(i) / 39.0
		pts.append(Vector2(lerpf(-1500.0, 250.0, u), 250.0 + sin(u * 11.0) * 170.0 * (0.5 + 0.5 * u)))
	var last := pts[pts.size() - 1]
	var lc := last + Vector2(60.0, -150.0)
	for i in range(1, 25):
		var a := PI * 0.5 + 0.38 - TAU * float(i) / 24.0
		pts.append(lc + Vector2(cos(a), sin(a)) * 160.0)
	for i in range(1, 25):
		var u := float(i) / 24.0
		pts.append(Vector2(lerpf(last.x + 40.0, 2300.0, u), lerpf(last.y, 330.0, u) + sin(u * 8.0) * 90.0))
	return pts


# the bandstand: a scalloped awning on candy poles, a step, the band organ's
# pipes behind, its bulbs out once it has stopped
static func _stage(c: CanvasItem, t: float) -> void:
	var r := Rect2(STAGE_X - 480.0, STAGE_TOP, 960.0, FEET - STAGE_TOP + 4.0)
	c.draw_rect(Rect2(r.position.x + 20.0, r.end.y - 6.0, r.size.x, 18.0), Color(0, 0, 0, 0.22))
	for p in range(9):
		var px := STAGE_X - 150.0 + float(p) * 37.0
		var h := 150.0 + 70.0 * sin(float(p) / 8.0 * PI)
		c.draw_rect(Rect2(px - 15.0, STAGE_TOP - h, 30.0, h), INK)
		c.draw_rect(Rect2(px - 12.0, STAGE_TOP - h + 3.0, 24.0, h), SAFFRON.darkened(0.08 * float(p % 2)))
		c.draw_rect(Rect2(px - 8.0, STAGE_TOP - h + 8.0, 5.0, h - 10.0), SAFFRON.lightened(0.4))
	c.draw_rect(r.grow(4.0), INK)
	c.draw_rect(r, Color(0.86, 0.22, 0.30))
	for i in range(16):
		c.draw_rect(Rect2(r.position.x + float(i) * 60.0, r.position.y + 16.0, 30.0, r.size.y - 16.0), Color(0.97, 0.95, 0.90))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 16.0)), SAFFRON)
	for s: float in [-1.0, 1.0]:
		var px := STAGE_X + s * 458.0
		c.draw_rect(Rect2(px - 11.0, STAGE_TOP - 450.0, 22.0, 450.0), INK)
		c.draw_rect(Rect2(px - 8.0, STAGE_TOP - 450.0, 16.0, 450.0), Color(0.97, 0.95, 0.90))
		for k in range(10):
			c.draw_line(Vector2(px - 8.0, STAGE_TOP - 440.0 + float(k) * 44.0), Vector2(px + 8.0, STAGE_TOP - 418.0 + float(k) * 44.0), Color(0.86, 0.22, 0.30), 8.0)
	var top := STAGE_TOP - 450.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(STAGE_X - 516.0, top), Vector2(STAGE_X + 516.0, top), Vector2(STAGE_X + 400.0, top - 92.0), Vector2(STAGE_X - 400.0, top - 92.0)]), INK)
	for i in range(11):
		var u0 := float(i) / 11.0
		var u1 := float(i + 1) / 11.0
		var col := TURQ if i % 2 == 0 else Color(0.97, 0.95, 0.90)
		c.draw_colored_polygon(PackedVector2Array([Vector2(STAGE_X + lerpf(-510.0, 510.0, u0), top), Vector2(STAGE_X + lerpf(-510.0, 510.0, u1), top),
			Vector2(STAGE_X + lerpf(-394.0, 394.0, u1), top - 86.0), Vector2(STAGE_X + lerpf(-394.0, 394.0, u0), top - 86.0)]), col)
		c.draw_circle(Vector2(STAGE_X + lerpf(-510.0, 510.0, (u0 + u1) * 0.5), top), 46.0, col)
	for i in range(19):
		var on := t < STOP_AT and (int(t * 8.0) + i) % 3 != 0
		c.draw_circle(Vector2(STAGE_X - 470.0 + float(i) * 52.0, top + 4.0), 9.0, INK)
		c.draw_circle(Vector2(STAGE_X - 470.0 + float(i) * 52.0, top + 4.0), 6.5, Color(1.0, 0.94, 0.60) if on else Color(0.46, 0.42, 0.40))


# --- the mascots --------------------------------------------------------------------

# One of them side on, feet at `at`. `o`: wave the arm going, turn 0 facing out
# to the crowd, 1 facing right, at you; arms opened for the hug; tip the head
# over; run the big shoes going; ph its own phase.
static func mascot(c: CanvasItem, at_: Vector2, k: float, who: String, t: float, o: Dictionary) -> void:
	var body: Color = Cast.BODY[who]
	var cos_: Color = Cast.COSTUME[who]
	var turn: float = o.get("turn", 0.0)
	var arms: float = o.get("arms", 0.0)
	var run: float = o.get("run", 0.0)
	var ph: float = o.get("ph", 0.0)
	var wave: float = o.get("wave", 0.0)
	var p := func(v: Vector2) -> Vector2: return at_ + v * k
	c.draw_colored_polygon(MillieSide.ellipse(at_ + Vector2(6, 2) * k, Vector2(66, 9) * k), Color(0, 0, 0, 0.26))
	# legs and shoes
	for s: float in [-1.0, 1.0]:
		var st := sin(t * 8.0 + ph + (PI if s > 0.0 else 0.0)) * run
		var foot := Vector2(s * 20.0 + st * 24.0, -10.0 - maxf(0.0, st) * 14.0)
		c.draw_line(p.call(Vector2(s * 17.0, -62.0)), p.call(foot), INK, 30.0 * k)
		c.draw_line(p.call(Vector2(s * 17.0, -62.0)), p.call(foot), cos_.darkened(0.18), 23.0 * k)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot + Vector2(12, 2)), Vector2(33, 16) * k), INK)
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot + Vector2(12, 1)), Vector2(29, 12.5) * k), Color(0.86, 0.20, 0.24))
		c.draw_colored_polygon(MillieSide.ellipse(p.call(foot + Vector2(18, -4)), Vector2(10, 4) * k), Color(1, 1, 1, 0.55))
	# the far arm
	_arm(c, p, Vector2(-34, -146), _hand(-1.0, arms, 0.0, t, ph), cos_, k)
	# the foam body, a drum with a belly
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(0, -108)), Vector2(62, 70) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(0, -108)), Vector2(57, 65) * k), cos_)
	c.draw_colored_polygon(MillieSide.ellipse(p.call(Vector2(6, -98)), Vector2(36, 44) * k), cos_.lightened(0.28))
	for q in range(3):
		c.draw_circle(p.call(Vector2(6.0, -134.0 + float(q) * 28.0)), 6.5 * k, INK)
		c.draw_circle(p.call(Vector2(6.0, -134.0 + float(q) * 28.0)), 4.6 * k, SAFFRON)
	_arm(c, p, Vector2(36, -146), _hand(1.0, arms, wave, t, ph), cos_, k)
	head(c, p.call(Vector2(4.0 * turn, -222)), k, who, body, t, turn, float(o.get("tip", 0.0)) + sin(t * 8.0 + ph) * 0.05 * run)


static func _hand(side: float, arms: float, wave: float, t: float, ph: float) -> Vector2:
	var rest := Vector2(side * 70.0, -92.0)
	var up := Vector2(side * 84.0 + sin(t * 6.0 + ph) * 22.0, -252.0)
	var open := Vector2(side * 104.0 + 20.0, -168.0 + sin(t * 9.0 + ph) * 8.0)
	return rest.lerp(up, wave).lerp(open, arms)


static func _arm(c: CanvasItem, p: Callable, sh: Vector2, hand: Vector2, col: Color, k: float) -> void:
	c.draw_line(p.call(sh), p.call(hand), INK, 33.0 * k)
	c.draw_line(p.call(sh), p.call(hand), col, 25.0 * k)
	c.draw_circle(p.call(sh), 13.0 * k, col)
	var d := (hand - sh).normalized()
	c.draw_circle(p.call(hand), 25.0 * k, INK)
	for f in range(4):
		var fd := d.rotated((float(f) - 1.5) * 0.52)
		c.draw_line(p.call(hand), p.call(hand + fd * 34.0), INK, 19.0 * k)
		c.draw_circle(p.call(hand + fd * 34.0), 9.5 * k, INK)
	for f in range(4):
		var fd := d.rotated((float(f) - 1.5) * 0.52)
		c.draw_line(p.call(hand), p.call(hand + fd * 34.0), Cast.GLOVE, 13.0 * k)
		c.draw_circle(p.call(hand + fd * 34.0), 6.5 * k, Cast.GLOVE)
	c.draw_circle(p.call(hand), 21.0 * k, Cast.GLOVE)


# the head, as big as the rest of it: round, seamed, the grin stitched on and
# the eyes wide, the pupils sliding round to you as it turns
static func head(c: CanvasItem, at_: Vector2, k: float, who: String, body: Color, t: float, turn: float, tip: float) -> void:
	var h := func(v: Vector2) -> Vector2: return at_ + v.rotated(tip) * k
	var sh := 16.0 * turn
	match who:
		"sun":
			for i in range(14):
				var d := Vector2.from_angle(float(i) * TAU / 14.0)
				var n := d.orthogonal()
				c.draw_colored_polygon(PackedVector2Array([h.call(d * 70.0 + n * 18.0), h.call(d * 112.0), h.call(d * 70.0 - n * 18.0)]), INK)
				c.draw_colored_polygon(PackedVector2Array([h.call(d * 70.0 + n * 13.0), h.call(d * 103.0), h.call(d * 70.0 - n * 13.0)]), Color(0.98, 0.56, 0.14))
		"dog":
			for s: float in [-1.0, 1.0]:
				c.draw_line(h.call(Vector2(s * 58.0, -44.0)), h.call(Vector2(s * 88.0, 26.0)), INK, 46.0 * k)
				c.draw_circle(h.call(Vector2(s * 88.0, 26.0)), 23.0 * k, INK)
				c.draw_line(h.call(Vector2(s * 58.0, -44.0)), h.call(Vector2(s * 88.0, 26.0)), Color(0.40, 0.24, 0.15), 37.0 * k)
				c.draw_circle(h.call(Vector2(s * 88.0, 26.0)), 18.5 * k, Color(0.40, 0.24, 0.15))
		"prawn":
			for s: float in [-1.0, 1.0]:
				var sw := sin(t * 4.0 + s) * 12.0
				var feel := PackedVector2Array([h.call(Vector2(s * 22.0, -60.0)), h.call(Vector2(s * 60.0 + sw, -130.0)), h.call(Vector2(s * 124.0 + sw, -150.0))])
				c.draw_polyline(feel, INK, 13.0 * k)
				c.draw_polyline(feel, body, 7.0 * k)
		"lizard":
			for i in range(6):
				var d := Vector2.from_angle(-PI * 0.5 + (float(i) - 2.5) * 0.42)
				var n := d.orthogonal()
				c.draw_colored_polygon(PackedVector2Array([h.call(d * 62.0 + n * 20.0), h.call(d * 122.0), h.call(d * 62.0 - n * 20.0)]), INK)
				c.draw_colored_polygon(PackedVector2Array([h.call(d * 62.0 + n * 14.0), h.call(d * 112.0), h.call(d * 62.0 - n * 14.0)]), Color(0.90, 0.30, 0.46))
	c.draw_circle(at_, 83.0 * k, INK)
	c.draw_circle(at_, 77.0 * k, body)
	c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(-24, -32)), Vector2(34, 24) * k, tip - 0.5), body.lightened(0.28))
	# the foam's seam, and the mesh the wearer looks out of, dark in the grin
	c.draw_arc(at_, 77.0 * k, PI * 0.12 + tip, PI * 0.88 + tip, 24, body.darkened(0.22), 5.0 * k)
	match who:
		"gull":
			c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(-112, -30)), h.call(Vector2(-40, -92)), h.call(Vector2(0, -122)), h.call(Vector2(40, -92)), h.call(Vector2(112, -30)), h.call(Vector2(0, -54))]), INK)
			c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(-99, -36)), h.call(Vector2(-38, -86)), h.call(Vector2(0, -113)), h.call(Vector2(38, -86)), h.call(Vector2(99, -36)), h.call(Vector2(0, -61))]), Color(0.14, 0.20, 0.40))
			c.draw_polyline(PackedVector2Array([h.call(Vector2(-92, -38)), h.call(Vector2(0, -62)), h.call(Vector2(92, -38))]), SAFFRON, 6.0 * k)
		"sun":
			c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(0, -62)), Vector2(104, 24) * k, tip), INK)
			c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(0, -62)), Vector2(97, 18) * k, tip), Color(0.50, 0.30, 0.16))
			c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(0, -88)), Vector2(52, 40) * k, tip), INK)
			c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(0, -87)), Vector2(47, 35) * k, tip), Color(0.60, 0.37, 0.20))
		"prawn":
			for i in range(3):
				c.draw_arc(at_, (77.0 - 16.0 * float(i)) * k, -PI * 0.86 + tip, -PI * 0.14 + tip, 18, body.darkened(0.2), 5.0 * k)
		"lizard":
			for i in range(5):
				c.draw_circle(h.call(Vector2(-44.0 + float(i) * 22.0, -50.0 + float(i % 2) * 13.0)), 8.0 * k, body.darkened(0.24))
	for s: float in [-1.0, 1.0]:
		var e := Vector2(s * 29.0 + sh, -14.0)
		c.draw_colored_polygon(MillieSide.ellipse(h.call(e), Vector2(27, 31) * k, tip), INK)
		c.draw_colored_polygon(MillieSide.ellipse(h.call(e), Vector2(22.5, 26.5) * k, tip), Color.WHITE)
		c.draw_circle(h.call(e + Vector2(13.0 * turn, 3.0 + 4.0 * turn)), 7.5 * k, INK)
	if who == "gull":
		c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(-24 + sh, 14)), h.call(Vector2(26 + sh, 12)), h.call(Vector2(74 * turn + sh * 0.5, 50)), h.call(Vector2(-6 + sh, 48))]), INK)
		c.draw_colored_polygon(PackedVector2Array([h.call(Vector2(-18 + sh, 19)), h.call(Vector2(23 + sh, 17)), h.call(Vector2(65 * turn + sh * 0.5, 47)), h.call(Vector2(-4 + sh, 43))]), Color(0.98, 0.66, 0.16))
		c.draw_line(h.call(Vector2(-14 + sh, 32)), h.call(Vector2(56 * turn + sh, 46)), INK, 5.0 * k)
		return
	if who == "dog":
		c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(sh * 1.4, 34)), Vector2(52, 38) * k, tip), body.lightened(0.34))
		c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(sh * 1.8, 12)), Vector2(20, 14) * k, tip), INK)
		c.draw_colored_polygon(MillieSide.ellipse(h.call(Vector2(sh * 1.8 - 5.0, 8)), Vector2(6, 4) * k, tip), Color(1, 1, 1, 0.7))
	var top := PackedVector2Array()
	var y := 34.0 if who == "dog" else 28.0
	for i in range(13):
		var u := float(i) / 12.0 * 2.0 - 1.0
		top.append(h.call(Vector2(u * 52.0 + sh, y - u * u * 18.0)))
	for i in range(12, -1, -1):
		var u := float(i) / 12.0 * 2.0 - 1.0
		top.append(h.call(Vector2(u * 50.0 + sh, y + 27.0 - u * u * 40.0)))
	c.draw_colored_polygon(top, INK)
	for i in range(9):
		var u := (float(i) + 0.5) / 9.0 * 2.0 - 1.0
		var hh := 21.0 - u * u * 16.0
		var q := Vector2(u * 47.0 + sh, y + 3.0 - u * u * 17.0)
		c.draw_colored_polygon(PackedVector2Array([h.call(q + Vector2(-4.6, 0)), h.call(q + Vector2(4.6, 0)), h.call(q + Vector2(4.6, hh)), h.call(q + Vector2(-4.6, hh))]), Cast.TEETH)


# the card: HUG!, the big dog's grin up from the bottom of the frame, its
# gloves closing in from both sides
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, -100.0, 1680, 924.0), Color(0.98, 0.52, 0.62), Color(0.98, 0.82, 0.36))
	var d := t - TITLE_AT
	for i in range(18):
		var a0 := float(i) * TAU / 18.0 + d * 0.15
		c.draw_colored_polygon(PackedVector2Array([Vector2(640, 560), Vector2(640, 560) + Vector2.from_angle(a0) * 1300.0, Vector2(640, 560) + Vector2.from_angle(a0 + TAU / 36.0) * 1300.0]), Color(1, 1, 1, 0.13))
	head(c, Vector2(640.0, 520.0 - d * 22.0), 2.75 + d * 0.16, "dog", Cast.BODY["dog"], t, 0.0, sin(d * 3.0) * 0.06)
	var close := Anim.span(t, TITLE_AT, TITLE_AT + 0.8)
	for s: float in [-1.0, 1.0]:
		var p := func(v: Vector2) -> Vector2: return Vector2(640.0, 520.0) + v * 3.2
		_arm(c, p, Vector2(s * 290.0, 90.0), Vector2(s * lerpf(250.0, 128.0, close), -6.0), Cast.COSTUME["dog"], 3.2)
	FilmKit.slam(c, t, "HUG!", Vector2(640, 170))
	var ml := Engine.get_main_loop()
	var gm: Node = ml.root.get_node_or_null("Game") if ml != null and ml is SceneTree else null
	if gm == null or bool(gm.flashes):
		IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
