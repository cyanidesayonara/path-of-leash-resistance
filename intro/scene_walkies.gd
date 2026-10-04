class_name SceneWalkies
extends RefCounted

# Intro 1, "Walkies?": the premise in fourteen seconds and no words.
# Morning in the flat. Your human on the sofa, face lit by the phone. Millie by
# the door, looking from the leash on its hook to them and back. She fetches
# it, trots over, drops it at their feet, waits. Nothing. She nudges the
# phone. "...". She sighs. They take the loop without looking up - and she
# crouches, and YANKS, and they leave the sofa horizontally, phone still up,
# out of the door into the sun. The title swings down on its leash.

const LENGTH := 15.0
const S := 1.6                 # character scale
const FLOOR := 610.0
const DOOR := Rect2(1060, 250, 150, 360)
const HOOK := Vector2(1010, 360)
const SOFA_X := 380.0
# where the dropped loop lay when your human reached for it
static var loop_at := Vector2(560, 600)


# the camera: [centre, zoom] in scene units. Close on her and the hook, across
# to the sofa for the waiting, a push in on the crouch, then wide for the yank.
static func camera(t: float) -> Array:
	if t >= 10.4:
		return [Vector2(640, 360), 1.0]
	var cx: float = Anim.k(t, [[0.0, 900.0], [3.3, 900.0], [5.0, 560.0, "io"], [8.6, 560.0], [8.9, 600.0, "io"],
		[9.3, 600.0], [9.45, 760.0, "snap"]])
	var cy: float = Anim.k(t, [[0.0, 470.0], [5.0, 450.0, "io"], [8.6, 450.0], [8.9, 520.0, "io"], [9.3, 520.0],
		[9.45, 400.0, "snap"]])
	var z: float = Anim.k(t, [[0.0, 1.55], [3.3, 1.55], [5.0, 1.5, "io"], [8.6, 1.5], [9.0, 2.0, "io"], [9.3, 2.0],
		[9.45, 1.15, "snap"]])
	return [Vector2(cx, cy), z]


static func _room(c: CanvasItem, t: float, door_open: float) -> void:
	# the wall, warm, darker at the top
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(-200, f * FLOOR, 1680, FLOOR / 7.0 + 1.0), Color(0.86, 0.78, 0.66).lerp(Color(0.95, 0.88, 0.76), f))
	# the window, morning outside, and its light on the floor
	var win := Rect2(150, 130, 210, 230)
	c.draw_rect(win.grow(10.0), Color(0.56, 0.40, 0.28))
	c.draw_rect(win, Color(0.74, 0.88, 0.96))
	c.draw_rect(Rect2(win.position.x + 100, win.position.y, 10, win.size.y), Color(0.56, 0.40, 0.28))
	c.draw_rect(Rect2(win.position.x, win.position.y + 110, win.size.x, 10), Color(0.56, 0.40, 0.28))
	c.draw_colored_polygon(PackedVector2Array([Vector2(150, 360), Vector2(360, 360), Vector2(560, FLOOR + 60), Vector2(300, FLOOR + 60)]),
		Color(1.0, 0.95, 0.75, 0.18))
	# a picture on the wall: a dog, naturally
	c.draw_rect(Rect2(560, 170, 120, 90).grow(6.0), Color(0.30, 0.22, 0.16))
	c.draw_rect(Rect2(560, 170, 120, 90), Color(0.90, 0.84, 0.66))
	c.draw_circle(Vector2(620, 222), 22.0, Color(0.15, 0.15, 0.17))
	# skirting and floorboards
	c.draw_rect(Rect2(-200, FLOOR - 18, 1680, 18), Color(0.96, 0.93, 0.86))
	c.draw_rect(Rect2(-200, FLOOR, 1680, 820 - FLOOR), Color(0.62, 0.44, 0.29))
	for k in range(8):
		var y := FLOOR + 8.0 + float(k) * 20.0
		c.draw_line(Vector2(-200, y), Vector2(1480, y), Color(0.52, 0.36, 0.23), 2.0)
	# the door: frame, then the door swinging open into a blaze of street
	c.draw_rect(DOOR.grow(12.0), Color(0.52, 0.36, 0.24))
	if door_open > 0.0:
		c.draw_rect(DOOR, Color(1.0, 0.94, 0.70))
	var dw := DOOR.size.x * (1.0 - door_open * 0.85)
	var door_r := Rect2(DOOR.position, Vector2(dw, DOOR.size.y))
	c.draw_rect(door_r.grow(2.0), IntroKit.INK)
	c.draw_rect(door_r, Color(0.36, 0.52, 0.42))
	c.draw_rect(Rect2(door_r.position + Vector2(16, 22), Vector2(maxf(dw - 32.0, 2.0), 130)), Color(0.32, 0.47, 0.38))
	c.draw_rect(Rect2(door_r.position + Vector2(16, 190), Vector2(maxf(dw - 32.0, 2.0), 140)), Color(0.32, 0.47, 0.38))
	c.draw_circle(door_r.position + Vector2(dw - 18.0, 190), 6.0, Color(0.86, 0.72, 0.36))
	# the hook by the door
	c.draw_rect(Rect2(HOOK + Vector2(-12, -8), Vector2(24, 10)), Color(0.40, 0.30, 0.22))
	c.draw_circle(HOOK + Vector2(0, 6), 4.0, Color(0.70, 0.70, 0.72))


static func _sofa(c: CanvasItem) -> void:
	var body := Color(0.78, 0.36, 0.28)
	var lit := body.lightened(0.16)
	# legs, then the back, the arm and the seat as soft rounded forms
	for fx: float in [SOFA_X - 98.0, SOFA_X + 176.0]:
		IntroKit.box(c, Rect2(fx, FLOOR - 26, 14, 26), 3.0, Color(0.30, 0.22, 0.16), 2.0)
	IntroKit.box(c, Rect2(SOFA_X - 118, FLOOR - 236, 62, 210), 24.0, body)
	IntroKit.box(c, Rect2(SOFA_X - 118, FLOOR - 112, 316, 88), 20.0, body)
	IntroKit.box(c, Rect2(SOFA_X + 150, FLOOR - 164, 58, 140), 26.0, body)
	# the seat cushions, their seam, and the light along the back's top
	IntroKit.box(c, Rect2(SOFA_X - 64, FLOOR - 128, 220, 34), 14.0, lit, 2.0)
	c.draw_line(Vector2(SOFA_X + 46, FLOOR - 126), Vector2(SOFA_X + 46, FLOOR - 96), IntroKit.INK, 2.0)
	c.draw_line(Vector2(SOFA_X - 100, FLOOR - 224), Vector2(SOFA_X - 100, FLOOR - 140), lit, 6.0)
	# a throw pillow wedged in the corner
	c.draw_colored_polygon(IntroKit.rrect(Rect2(SOFA_X - 70, FLOOR - 204, 54, 74).grow(2.0), 16.0), IntroKit.INK)
	c.draw_colored_polygon(IntroKit.rrect(Rect2(SOFA_X - 70, FLOOR - 204, 54, 74), 16.0), Color(0.96, 0.82, 0.40))
	for k in range(3):
		c.draw_line(Vector2(SOFA_X - 62 + k * 16, FLOOR - 196), Vector2(SOFA_X - 62 + k * 16, FLOOR - 138), Color(0.86, 0.64, 0.24), 3.0)


# the flat: a lamp by the sofa, a plant at the window, a rug, a coat on the
# hook beside the leash, and her own bed by the door (empty: she has plans)
static func _dressing(c: CanvasItem) -> void:
	# the rug, flat on the boards in front of the sofa
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(560, FLOOR + 22), Vector2(300, 22)), IntroKit.INK)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(560, FLOOR + 22), Vector2(296, 18)), Color(0.36, 0.48, 0.62))
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(560, FLOOR + 22), Vector2(250, 12)), Color(0.86, 0.70, 0.44))
	# the floor lamp, lit
	c.draw_line(Vector2(130, FLOOR), Vector2(130, FLOOR - 300), IntroKit.INK, 6.0)
	IntroKit.box(c, Rect2(110, FLOOR - 8, 40, 8), 3.0, Color(0.20, 0.20, 0.22), 2.0)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(130, FLOOR - 300), Vector2(90, 80)), Color(1.0, 0.92, 0.66, 0.16))
	var shade := PackedVector2Array([Vector2(100, FLOOR - 340), Vector2(160, FLOOR - 340), Vector2(178, FLOOR - 288), Vector2(82, FLOOR - 288)])
	c.draw_colored_polygon(PackedVector2Array([shade[0] + Vector2(-3, -3), shade[1] + Vector2(3, -3), shade[2] + Vector2(4, 3), shade[3] + Vector2(-4, 3)]), IntroKit.INK)
	c.draw_colored_polygon(shade, Color(0.98, 0.90, 0.68))
	# the plant on the windowsill
	IntroKit.box(c, Rect2(320, 344, 34, 30), 6.0, Color(0.76, 0.42, 0.28), 2.0)
	for k in range(5):
		var a := -PI * 0.5 + (float(k) - 2.0) * 0.45
		var tip := Vector2(337, 344) + Vector2.from_angle(a) * 44.0
		c.draw_line(Vector2(337, 344), tip, IntroKit.INK, 9.0)
		c.draw_line(Vector2(337, 344), tip, Color(0.32, 0.56, 0.30), 6.0)
	# a coat on the next hook: rounded shoulders on its loop, a collar, a
	# sleeve hanging down the front, a pocket
	var ch := HOOK + Vector2(-60, 0)
	c.draw_rect(Rect2(ch + Vector2(-10, -8), Vector2(20, 10)), Color(0.40, 0.30, 0.22))
	var coat := Color(0.36, 0.46, 0.40)
	IntroKit.box(c, Rect2(ch.x - 26, ch.y + 6, 52, 150), 18.0, coat)
	c.draw_colored_polygon(PackedVector2Array([ch + Vector2(-12, 6), ch + Vector2(12, 6), ch + Vector2(0, 30)]), coat.darkened(0.25))
	IntroKit.box(c, Rect2(ch.x + 6, ch.y + 24, 16, 104), 8.0, coat.darkened(0.1), 2.0)
	c.draw_line(ch + Vector2(-14, 96), ch + Vector2(2, 96), coat.darkened(0.35), 3.0)
	# her bed by the door, side on: a cushioned basket with a raised rim
	IntroKit.box(c, Rect2(808, FLOOR - 44, 150, 44), 18.0, Color(0.42, 0.56, 0.74))
	IntroKit.box(c, Rect2(826, FLOOR - 30, 114, 18), 9.0, Color(0.88, 0.82, 0.72), 2.0)
	c.draw_line(Vector2(818, FLOOR - 34), Vector2(948, FLOOR - 34), Color(0.56, 0.70, 0.86), 3.0)


# the morning light from the window, a soft shaft across the room, and the
# edges of the room falling into shade
static func _light(c: CanvasItem) -> void:
	for i in range(4):
		var f := float(i) * 18.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(150 - f, 130), Vector2(360 + f, 130), Vector2(760 + f * 2.0, FLOOR + 80),
			Vector2(300 - f, FLOOR + 80)]), Color(1.0, 0.95, 0.78, 0.05))
	for i in range(6):
		var w := 40.0 + float(i) * 40.0
		c.draw_rect(Rect2(-200, -100, w, 900), Color(0.20, 0.12, 0.08, 0.035))
		c.draw_rect(Rect2(1480 - w, -100, w, 900), Color(0.20, 0.12, 0.08, 0.035))


static func draw(c: CanvasItem, t_real: float) -> void:
	# smooth: animating on twos with a boil read as judder, not as clay
	var t := t_real
	if t_real >= 10.4:
		_title(c, t_real)
		return
	var door_open: float = Anim.k(t, [[9.5, 0.0], [9.65, 1.0, "snap"]])
	_room(c, t, door_open)
	_dressing(c)
	# --- Millie's path through the scene
	var mx: float = Anim.k(t, [[0.0, 930.0], [3.3, 930.0], [3.5, 960.0, "out"], [5.1, 560.0, "io"],
		[6.7, 560.0], [7.0, 520.0, "out"], [7.5, 560.0, "io"], [8.6, 600.0], [9.3, 600.0],
		[9.75, 1350.0, "in"]])
	var my: float = Anim.k(t, [[0.0, 0.0], [2.9, 0.0], [3.15, -70.0, "out"], [3.4, 0.0, "in"],
		[6.6, 0.0], [6.9, -40.0, "out"], [7.4, 0.0, "in"]])
	# turns pass through a squash rather than flipping in one frame
	var face: float = Anim.k(t, [[0.0, 1.0], [1.55, 1.0], [1.75, -1.0, "io"], [2.25, -1.0], [2.45, 1.0, "io"],
		[3.3, 1.0], [3.5, -1.0, "io"], [8.45, -1.0], [8.65, 1.0, "io"]])
	var trot := Anim.span(t, 3.5, 3.7) * (1.0 - Anim.span(t, 4.9, 5.1))
	var sitting := 1.0 - Anim.span(t, 2.6, 2.8) + Anim.span(t, 5.3, 5.6) - Anim.span(t, 6.5, 6.6) \
		+ Anim.span(t, 7.4, 7.7) - Anim.span(t, 8.6, 8.7)
	sitting = clampf(sitting, 0.0, 1.0)
	var crouch := Anim.span(t, 8.75, 9.05) * (1.0 - Anim.span(t, 9.3, 9.4))
	var yank := Anim.span(t, 9.3, 9.45)
	var pose := {
		"sit": sitting,
		"gait": trot, "phase": t * 15.0,
		"crouch": crouch,
		"lean": 0.22 * crouch + 0.12 * yank,
		"push": crouch * 0.4 + yank * 0.9,
		"reach": yank * 1.0,
		"head_up": Anim.k(t, [[0.0, 0.0], [0.8, 0.55, "io"], [1.5, 0.55], [1.6, 0.0, "io"], [2.4, 0.0], [2.5, 0.5, "io"],
			[3.4, 0.2], [5.3, 0.0], [5.6, 0.35, "io"], [6.6, 0.35], [6.9, 0.7, "out"], [7.4, 0.3], [7.7, -0.35, "io"],
			[8.5, -0.35], [8.7, 0.0], [9.0, -0.1]]),
		"ear": 0.4 * trot * sin(t_real * 14.0 + 1.0) + Anim.k(t, [[7.5, 0.0], [7.8, -0.35, "io"], [8.5, -0.35], [8.7, 0.0], [9.35, 0.0], [9.5, 1.2, "snap"]]),
		"tail": Anim.k(t, [[5.6, 0.0], [5.7, 0.4]]) * sin(t_real * 18.0) * Anim.span(t, 5.6, 6.5) * (1.0 - Anim.span(t, 6.5, 6.6)) \
			+ Anim.k(t, [[7.5, 0.0], [7.8, -0.6, "io"], [8.6, -0.6], [8.8, 0.3]]),
		"mouth": Anim.k(t, [[3.2, 0.0], [3.25, 0.5, "hold"], [5.2, 0.5], [5.25, 0.0, "hold"], [9.35, 0.0], [9.4, 0.9, "hold"]]),
		"brow": Anim.k(t, [[5.4, 0.0], [5.6, 1.0, "io"], [7.4, 1.0], [7.6, -0.6, "io"], [8.7, -0.6], [8.9, -1.0, "io"]]),
		"blink": 1.0 if (t > 7.6 and t < 7.9) or (t > 1.2 and t < 1.3) else 0.0,
	}
	var sq := Anim.squash(Anim.k(t, [[2.85, 1.0], [2.95, 0.8, "out"], [3.1, 1.25, "out"], [3.35, 1.0, "io"],
		[8.75, 1.0], [9.05, 0.78, "io"], [9.3, 0.78], [9.4, 1.35, "snap"]]))
	if t > 9.3:
		sq = Vector2(1.35, 0.78)   # stretched along the dash
	var mpos := Vector2(mx, FLOOR + my)
	# --- your human: on the sofa, until they are not
	var hx: float = Anim.k(t, [[9.45, SOFA_X], [9.95, 1500.0, "in"]])
	var hy: float = Anim.k(t, [[9.45, FLOOR], [9.6, FLOOR - 50.0, "out"]])
	var lift := Anim.span(t, 9.42, 9.55)
	var hpose := {
		"sit": 1.0 - lift,
		"lean": lerpf(0.0, 1.25, lift),
		"phone": 1.0,
		"glow": 1.0,
		"reach": Anim.k(t, [[8.1, 0.0], [8.35, 0.8, "out"]]) if t < 9.45 else 1.0,
		"lift": lift,
		"head": Anim.k(t, [[6.85, 0.0], [6.95, -0.25, "out"], [7.3, 0.0, "io"], [9.45, 0.0], [9.5, 0.3, "snap"]]),
		"mouth": 1.0 if t > 9.45 else 0.0,
	}
	var hsq := Vector2(1.0, 1.0) if t < 9.45 else Vector2(1.25, 0.85)
	_sofa(c)
	var hand := IntroKit.human(c, Vector2(hx, hy), S, 1.0, hsq, hpose)
	# the leash: on its hook; in her mouth; dropped at their feet; then from
	# her collar to the hand that took it
	var m := IntroKit.millie(c, mpos, S * 0.95, face, sq, pose, FLOOR)
	# one leash, as rope: hanging doubled on its hook; then clipped to her
	# collar with the loop in her mouth, swinging and dragging as she trots;
	# dropped at their feet; then the loop in the hand that took it
	var hook_pt := HOOK + Vector2(0, 8)
	if t < 3.2:
		# hanging doubled on its hook: both ends there, the loop below
		IntroKit.rope(c, t, hook_pt, hook_pt + Vector2(6, 0), true, 300.0, FLOOR - 4.0, 0)
	elif t < 5.2:
		IntroKit.rope(c, t, m["ring"], m["mouth"], true, 300.0, FLOOR - 4.0, 1)
	elif t < 8.25:
		IntroKit.rope(c, t, m["ring"], Vector2.ZERO, false, 300.0, FLOOR - 4.0, 2)
		loop_at = IntroKit.rope_p[IntroKit.ROPE_N - 1]
	else:
		# the loop rises from the floor into the hand that reached for it
		var up := Anim.curve("io", Anim.span(t, 8.25, 8.6))
		IntroKit.rope(c, t, m["ring"], loop_at.lerp(hand, up), true, 300.0, FLOOR - 4.0, 2)
	# the nudge: the phone wobbles; "..."
	if t > 7.0 and t < 8.1:
		IntroKit.dots(c, Vector2(SOFA_X + 120, FLOOR - 330), t - 7.0)
	# the sigh: a little puff from her nose
	if t > 7.6 and t < 8.2:
		var pf := Anim.span(t, 7.6, 8.2)
		IntroKit.puff(c, m["mouth"] + Vector2(-30.0 * pf - 10.0, -10.0 * pf), 8.0 + 6.0 * pf, 1.0 - pf)
	# the yank: speed lines, a dust kick
	if t > 9.35:
		IntroKit.speed_lines(c, mpos + Vector2(-40, -70), Vector2.RIGHT, 140.0)
		IntroKit.speed_lines(c, Vector2(hx, hy) + Vector2(-60, -200), Vector2.RIGHT, 160.0, 3)
		for k in range(3):
			IntroKit.puff(c, Vector2(600.0 - float(k) * 30.0, FLOOR - 10.0 - float(k % 2) * 14.0), 14.0 - float(k) * 3.0,
				1.0 - Anim.span(t, 9.4, 10.2))
	_light(c)
	# sunlight flooding in through the door, then white
	var flash: float = Anim.k(t_real, [[9.6, 0.0], [10.1, 1.0, "in"], [10.4, 1.0]])
	IntroKit.fade(c, flash, Color(1.0, 0.97, 0.88))
	IntroKit.fade(c, 1.0 - Anim.span(t_real, 0.0, 0.8))


# the street they burst out into, in daylight and kept soft so the title is
# what you look at: sky, a row of house fronts with shutters and balconies,
# two plane trees, a lamppost, the pavement and the kerb
static func _street(c: CanvasItem) -> void:
	for i in range(10):
		var f := float(i) / 9.0
		c.draw_rect(Rect2(-200, f * 420.0, 1680, 420.0 / 9.0 + 1.0), Color(0.62, 0.80, 0.92).lerp(Color(0.94, 0.92, 0.84), f))
	var fronts := [Color(0.90, 0.78, 0.60), Color(0.86, 0.66, 0.52), Color(0.92, 0.86, 0.72), Color(0.84, 0.72, 0.60)]
	var x := -120.0
	var k := 0
	while x < 1400.0:
		var w := 230.0 + float((k * 37) % 60)
		var top := 150.0 + float((k * 53) % 70)
		var col: Color = fronts[k % fronts.size()]
		c.draw_rect(Rect2(x, top, w, 640.0 - top), col)
		c.draw_rect(Rect2(x, top, w, 10), col.darkened(0.12))
		var wy := top + 40.0
		while wy < 560.0:
			var wx := x + 30.0
			while wx < x + w - 50.0:
				c.draw_rect(Rect2(wx, wy, 34, 54), Color(0.46, 0.60, 0.54))
				c.draw_line(Vector2(wx - 6, wy + 56), Vector2(wx + 40, wy + 56), col.darkened(0.35), 3.0)
				wx += 66.0
			wy += 96.0
		x += w
		k += 1
	# a light haze over the fronts, so they sit back behind the title
	c.draw_rect(Rect2(-200, 0, 1680, 640), Color(0.98, 0.95, 0.88, 0.45))
	for tx: float in [180.0, 1100.0]:
		c.draw_rect(Rect2(tx - 6, 470, 12, 170), Color(0.42, 0.34, 0.26))
		for blob: Vector2 in [Vector2(0, -20), Vector2(-46, 6), Vector2(46, 6), Vector2(-22, 34), Vector2(26, 34)]:
			c.draw_circle(Vector2(tx, 470) + blob, 52.0, Color(0.48, 0.64, 0.38))
		c.draw_circle(Vector2(tx - 20, 440), 30.0, Color(0.58, 0.74, 0.44))
	c.draw_line(Vector2(960, 640), Vector2(960, 430), Color(0.22, 0.24, 0.26), 6.0)
	c.draw_circle(Vector2(960, 424), 12.0, Color(0.98, 0.94, 0.78))
	c.draw_rect(Rect2(-200, 640, 1680, 100), Color(0.80, 0.76, 0.70))
	c.draw_rect(Rect2(-200, 700, 1680, 40), Color(0.62, 0.60, 0.58))
	c.draw_line(Vector2(-200, 640), Vector2(1480, 640), IntroKit.INK, 3.0)


static func _title(c: CanvasItem, t: float) -> void:
	_street(c)
	IntroTitle.draw(c, t - 10.4, "swing")
	# and there they go: Millie trotting along the bottom, towing your human,
	# who is still looking at the phone
	var tt := t
	var x: float = Anim.k(tt, [[10.9, -260.0], [13.6, 1500.0, "lin"]])
	if tt > 10.9 and tt < 13.6:
		var m := IntroKit.millie(c, Vector2(x, 652.0), 0.9, 1.0, Vector2.ONE,
			{"gait": 1.0, "phase": t * 15.0, "head_up": 0.3, "tail": sin(t * 15.0) * 0.4, "brow": 1.0, "mouth": 0.3})
		var hand := IntroKit.human(c, Vector2(x - 190.0, 652.0), 0.9, 1.0, Vector2.ONE,
			{"stride": t * 11.0, "stride_amp": 1.0, "phone": 1.0, "glow": 0.5, "reach": 0.8, "lean": 0.3})
		IntroKit.leash(c, m["ring"], hand, 6.0)
	IntroKit.fade(c, 1.0 - Anim.span(t, 10.4, 10.8), Color(1.0, 0.97, 0.88))
