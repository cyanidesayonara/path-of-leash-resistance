class_name SceneWalkies
extends RefCounted

# Intro 1, "Walkies?": the premise in fourteen seconds and no words.
# Morning in the flat. Your human on the sofa, face lit by the phone. Millie by
# the door, looking from the leash on its hook to them and back. She jumps for
# it, trots over, and drops the loop on their knee. Waits. Nothing. She noses
# the phone; it jolts; "...". She sighs. Their hand closes on the loop without
# them looking up - and she turns, crouches, and YANKS: the leash snaps
# straight, they leave the sofa, and the two of them go out through the door
# into the sun. The title hangs from the leash by a collar round the O.

const LENGTH := 15.0
const S := 1.6                 # character scale
const MS := 1.52               # Millie's scale
const FLOOR := 610.0
const DOOR := Rect2(1060, 250, 150, 360)
const HOOK := Vector2(1010, 360)
const SOFA_X := 380.0
const LEASH_LEN := 300.0
const CARRY_LEN := 120.0     # the leash gathered up in her mouth
const KNEE := Vector2(SOFA_X + 76.0, FLOOR - 104.0)   # where the loop lands
const TITLE_AT := 10.1


# the camera: [centre, zoom] in scene units. Wide enough at first to see who
# she is looking at; close on her and the hook for the jump; with her across
# the room; a push in on the crouch; then a hard cut wide for the yank.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return [Vector2(640, 360), 1.0]
	if t >= 9.25:
		return [Vector2(800, 420), 1.12]
	var cx: float = Anim.k(t, [[0.0, 720.0], [2.2, 720.0], [2.7, 930.0, "io"], [3.45, 930.0], [4.9, 620.0, "io"],
		[8.55, 620.0], [8.95, 570.0, "io"]])
	var cy: float = Anim.k(t, [[0.0, 430.0], [2.2, 430.0], [2.7, 445.0, "io"], [4.9, 450.0, "io"], [8.55, 450.0],
		[8.95, 455.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [2.2, 1.2], [2.7, 1.6, "io"], [3.45, 1.6], [4.9, 1.45, "io"], [8.55, 1.45],
		[8.95, 1.75, "io"]])
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
	# the door: its frame, the street blazing beyond it once open, and the door
	# itself swinging on its left hinge toward us (narrower as it turns, its
	# free edge taller as it comes nearer)
	c.draw_rect(DOOR.grow(12.0), Color(0.52, 0.36, 0.24))
	var ang := door_open * 1.9
	if door_open > 0.02:
		c.draw_rect(DOOR, Color(1.0, 0.95, 0.74))
		c.draw_colored_polygon(PackedVector2Array([DOOR.position + Vector2(0, DOOR.size.y), DOOR.end,
			DOOR.end + Vector2(160, 120), DOOR.position + Vector2(-60, DOOR.size.y + 120)]), Color(1.0, 0.95, 0.74, 0.35 * door_open))
	var hinge_x := DOOR.position.x
	var fx := hinge_x + DOOR.size.x * cos(ang)
	var grow := 1.0 + 0.22 * sin(ang)
	var top := DOOR.position.y - DOOR.size.y * (grow - 1.0) * 0.5
	var bot := DOOR.end.y + DOOR.size.y * (grow - 1.0) * 0.5
	var panel := PackedVector2Array([Vector2(hinge_x, DOOR.position.y), Vector2(fx, top), Vector2(fx, bot), Vector2(hinge_x, DOOR.end.y)])
	var shade := 1.0 - 0.35 * sin(ang)
	c.draw_colored_polygon(PackedVector2Array([panel[0] + Vector2(-2, -2), panel[1] + Vector2(2 * signf(fx - hinge_x), -2),
		panel[2] + Vector2(2 * signf(fx - hinge_x), 2), panel[3] + Vector2(-2, 2)]), IntroKit.INK)
	c.draw_colored_polygon(panel, Color(0.36 * shade, 0.52 * shade, 0.42 * shade))
	if absf(fx - hinge_x) > 20.0:
		var k0 := 0.12
		var k1 := 0.88
		for pn: Array in [[0.06, 0.40], [0.52, 0.92]]:
			var q := PackedVector2Array()
			for e: Vector2 in [Vector2(k0, pn[0]), Vector2(k1, pn[0]), Vector2(k1, pn[1]), Vector2(k0, pn[1])]:
				var xx := lerpf(hinge_x, fx, e.x)
				var yt := lerpf(DOOR.position.y, top, e.x)
				var yb := lerpf(DOOR.end.y, bot, e.x)
				q.append(Vector2(xx, lerpf(yt, yb, e.y)))
			c.draw_colored_polygon(q, Color(0.32 * shade, 0.47 * shade, 0.38 * shade))
		c.draw_circle(Vector2(lerpf(hinge_x, fx, 0.88), lerpf(lerpf(DOOR.position.y, top, 0.88), lerpf(DOOR.end.y, bot, 0.88), 0.53)),
			6.0, Color(0.86, 0.72, 0.36))
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
	# a yellow raincoat on the next hook: the hood hanging behind, the soft
	# shape of a coat on a peg, a sleeve and a pocket
	var ch := HOOK + Vector2(-62, 0)
	c.draw_rect(Rect2(ch + Vector2(-10, -8), Vector2(20, 10)), Color(0.40, 0.30, 0.22))
	var coat := Color(0.95, 0.76, 0.26)
	var shape := PackedVector2Array()
	for e: Vector2 in [Vector2(-10, 0), Vector2(10, 0), Vector2(24, 18), Vector2(28, 70), Vector2(32, 146), Vector2(0, 152),
		Vector2(-32, 146), Vector2(-28, 70), Vector2(-24, 18)]:
		shape.append(ch + e)
	var outline := PackedVector2Array()
	for q in shape:
		outline.append(ch + Vector2(0, 76) + (q - ch - Vector2(0, 76)) * 1.05)
	c.draw_colored_polygon(outline, IntroKit.INK)
	c.draw_colored_polygon(shape, coat)
	c.draw_colored_polygon(MillieSide.ellipse(ch + Vector2(0, 12), Vector2(13, 12)), coat.darkened(0.18))
	c.draw_line(ch + Vector2(-18, 30), ch + Vector2(-22, 118), coat.darkened(0.25), 3.0)
	c.draw_line(ch + Vector2(4, 24), ch + Vector2(4, 148), coat.darkened(0.3), 2.0)
	c.draw_line(ch + Vector2(10, 100), ch + Vector2(22, 100), coat.darkened(0.3), 2.5)
	# her bed, back against the wall under the coat, out of her way: a
	# cushioned basket with a raised rim, a little smaller for being further back
	IntroKit.box(c, Rect2(870, FLOOR - 58, 120, 36), 16.0, Color(0.42, 0.56, 0.74))
	IntroKit.box(c, Rect2(884, FLOOR - 48, 92, 14), 7.0, Color(0.88, 0.82, 0.72), 2.0)
	c.draw_line(Vector2(880, FLOOR - 50), Vector2(980, FLOOR - 50), Color(0.56, 0.70, 0.86), 3.0)


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
	var t := t_real
	if t >= TITLE_AT:
		_title(c, t)
		return
	# the door bursts open as she reaches it, overshoots, and swings back a
	# little after your human has gone through
	var door_open: float = Anim.k(t, [[9.5, 0.0], [9.58, 1.08, "snap"], [9.67, 0.94, "io"], [9.73, 1.0, "io"],
		[9.82, 1.0], [9.94, 0.75, "io"]])
	_room(c, t, door_open)
	_dressing(c)

	# ---------------------------------------------------------------- Millie
	# where she stands, and which way she faces
	var mx: float = Anim.k(t, [[0.0, 920.0], [3.45, 920.0], [3.6, 912.0, "out"], [4.95, 625.0, "io"],
		[5.35, 625.0], [5.7, 690.0, "io"], [6.55, 690.0], [6.85, 572.0, "out"], [7.05, 572.0], [7.35, 690.0, "io"],
		[9.25, 690.0], [9.55, 1135.0, "in"]])
	# turns are quick (two frames) and hidden in a little dip, so she never
	# shows as a sliver
	var face_raw: float = Anim.k(t, [[0.0, 1.0], [1.58, 1.0], [1.66, -1.0, "io"], [2.35, -1.0], [2.43, 1.0, "io"],
		[3.5, 1.0], [3.58, -1.0, "io"], [8.58, -1.0], [8.66, 1.0, "io"]])
	var face := signf(face_raw) * maxf(absf(face_raw), 0.55) if face_raw != 0.0 else 0.55
	var turn_dip := maxf(maxf(1.0 - absf(face_raw), 0.0), 0.0)
	var trot := Anim.span(t, 3.6, 3.75) * (1.0 - Anim.span(t, 4.8, 4.95)) \
		+ 0.6 * Anim.span(t, 5.4, 5.5) * (1.0 - Anim.span(t, 5.6, 5.7)) \
		+ 0.6 * Anim.span(t, 7.1, 7.2) * (1.0 - Anim.span(t, 7.25, 7.35))
	var sitting := clampf(1.0 - Anim.span(t, 2.55, 2.72) + Anim.span(t, 5.75, 6.0) - Anim.span(t, 6.48, 6.58)
		+ Anim.span(t, 7.4, 7.62) - Anim.span(t, 8.45, 8.58), 0.0, 1.0)
	var windup := Anim.span(t, 2.7, 2.8) * (1.0 - Anim.span(t, 2.9, 2.94))
	var air := Anim.span(t, 2.9, 3.12) * (1.0 - Anim.span(t, 3.12, 3.34))
	var crouch := Anim.span(t, 8.72, 9.1) * (1.0 - Anim.span(t, 9.25, 9.3))
	var dash := Anim.span(t, 9.25, 9.32)
	var paws_up := Anim.span(t, 4.95, 5.12) * (1.0 - Anim.span(t, 5.3, 5.45))
	var nudge := Anim.span(t, 6.75, 6.92) * (1.0 - Anim.span(t, 7.0, 7.15))
	var pose := {
		"sit": sitting,
		"gait": trot, "phase": t * 15.0,
		"crouch": maxf(maxf(windup, crouch), 0.5 * turn_dip),
		# up and forward at the hook, nose first; tipping down to land
		"lean": 0.25 * crouch + 0.12 * dash - 0.8 * paws_up - 0.15 * nudge
			+ Anim.k(t, [[2.9, 0.0], [3.0, -0.5, "out"], [3.12, -0.45], [3.3, 0.3, "io"], [3.4, 0.0, "io"]]),
		"push": crouch * 0.5 + dash * 0.9 + 0.8 * air,
		"reach": dash + 0.8 * air + 0.3 * paws_up,
		"head_up": Anim.k(t, [[0.0, 0.0], [0.8, 0.55, "io"], [1.45, 0.55], [1.55, 0.05, "io"], [2.35, 0.05], [2.5, 0.6, "io"],
			[3.12, 0.7], [3.5, 0.15, "io"], [4.95, 0.1], [5.15, 0.05, "io"], [5.5, 0.1], [5.9, 0.35, "io"], [6.6, 0.35],
			[6.88, 0.95, "out"], [7.1, 0.3, "io"], [7.6, -0.35, "io"], [8.45, -0.35], [8.65, 0.05, "io"], [9.0, -0.12]]),
		"ear": 0.35 * trot * sin(t * 15.0 + 1.0) + Anim.k(t, [[7.55, 0.0], [7.85, -0.4, "io"], [8.45, -0.4], [8.65, 0.0, "io"],
			[9.0, -0.3, "io"], [9.25, -0.3], [9.33, 0.7, "snap"]]),
		"tail": 0.45 * sin(t * 17.0) * Anim.span(t, 5.95, 6.1) * (1.0 - Anim.span(t, 6.4, 6.5))
			+ Anim.k(t, [[7.55, 0.0], [7.85, -0.6, "io"], [8.5, -0.6], [8.7, 0.25, "io"]]),
		"mouth": Anim.k(t, [[3.1, 0.0], [3.13, 0.45, "hold"], [5.25, 0.45], [5.28, 0.0, "hold"], [9.25, 0.0], [9.28, 0.9, "hold"]]),
		"brow": Anim.k(t, [[5.75, 0.0], [5.95, 1.0, "io"], [7.4, 1.0], [7.6, -0.6, "io"], [8.7, -0.6], [8.95, -1.0, "io"]]),
		"blink": 1.0 if (t > 1.2 and t < 1.28) or (t > 7.62 and t < 7.95) or (t > 6.3 and t < 6.36) else 0.0,
	}
	var stretch: float = Anim.k(t, [[2.7, 1.0], [2.8, 0.7, "io"], [2.9, 0.7], [2.95, 1.25, "snap"], [3.12, 1.05, "out"],
		[3.3, 1.12, "in"], [3.36, 0.8, "snap"], [3.5, 1.0, "back"],
		[8.72, 1.0], [9.1, 0.68, "io"], [9.25, 0.68]]) * (1.0 - 0.12 * turn_dip)
	var sq := Anim.squash(stretch)
	if t >= 9.25:
		sq = Vector2(1.38, 0.76)   # stretched along the dash
	# the jump: up until her mouth meets the hook, and down again
	var ground_pos := Vector2(mx, FLOOR)
	var mpos := ground_pos
	if air > 0.0:
		var probe := IntroKit.millie_points(Vector2.ZERO, MS, face, sq, pose)
		var peak: Vector2 = HOOK + Vector2(0, 10) - probe["mouth"]
		var up := Anim.curve("out", Anim.span(t, 2.9, 3.12)) * (1.0 - Anim.curve("in", Anim.span(t, 3.12, 3.34)))
		mpos = ground_pos.lerp(peak, up)
		# an arc, not a lift: a little forward going up, landing forward
		mpos.x += 26.0 * Anim.span(t, 2.9, 3.34)
	if paws_up > 0.0:
		mpos.y -= 14.0 * paws_up
	var mp := IntroKit.millie_points(mpos, MS, face, sq, pose)

	# --------------------------------------------------------------- your human
	# the yank lands: the arm is hauled out straight and the body tips after
	# it (9.27-9.42), then they leave the seat on a rising diagonal
	var tip := Anim.span(t, 9.27, 9.42)
	var off_sofa := Anim.span(t, 9.42, 9.54)
	var fly := Anim.span(t, 9.42, 9.8)
	var hx: float = lerpf(SOFA_X, 1135.0, Anim.curve("in", fly))
	var hy: float = FLOOR - sin(fly * PI) * 70.0 - 40.0 * off_sofa * (1.0 - fly)
	var reach: float = Anim.k(t, [[8.1, 0.0], [8.3, 0.35, "out"], [8.55, 0.85, "io"]])
	var hpose := {
		"sit": 1.0 - off_sofa,
		"lean": lerpf(0.15 + 0.5 * tip, 1.3, off_sofa) + Anim.k(t, [[8.1, 0.0], [8.3, 0.25, "out"], [8.55, 0.0, "io"]]),
		"scroll": t * 1.3 if t < 6.85 or t > 7.4 else 0.0,
		"blink": 1.0 if fposmod(t, 3.1) < 0.12 and t < 9.2 else 0.0,
		"phone": 1.0,
		"glow": 1.0,
		"reach": maxf(reach, tip) if t < 9.42 else 1.0,
		"reach_down": Anim.k(t, [[8.1, 0.0], [8.3, 0.6, "out"], [8.55, 0.0, "io"]]),
		"lift": off_sofa,
		"stride": t * 26.0,
		"phone_jolt": Anim.k(t, [[6.88, 0.0], [6.93, 1.0, "snap"], [7.15, 0.0, "back"]]),
		"head": Anim.k(t, [[6.88, 0.0], [6.93, -0.2, "snap"], [7.2, 0.0, "io"], [9.38, 0.0], [9.44, 0.25, "snap"]]),
		"mouth": 1.0 if t > 9.42 else 0.0,
	}
	var hsq := Vector2.ONE if t < 9.42 else Vector2(1.2, 0.86)

	# ------------------------------------------------------------------ draw
	_light(c)
	_sofa(c)
	var m_gone := mx >= 1134.0 and t > 9.5
	var h_gone := hx >= 1130.0
	var hand := Vector2(hx + 60.0, hy - 150.0)
	if not h_gone:
		hand = IntroKit.human(c, Vector2(hx, hy), S, 1.0, hsq, hpose, 0.0, FLOOR if t >= 9.42 else INF)
	# for the first frames off the seat, the sofa's back is in front of the legs
	if t > 9.42 and t < 9.58:
		IntroKit.box(c, Rect2(SOFA_X - 118, FLOOR - 236, 62, 210), 24.0, Color(0.78, 0.36, 0.28))
	# the leash, drawn behind her while she has it, in front of the human:
	# doubled on its hook; clipped to her collar with the loop in her mouth;
	# the loop dropped on their knee; the loop taken by the hand
	var hook_pt := HOOK + Vector2(0, 8)
	# while she carries it the leash is drawn in front of her, so you can see
	# she has it; the rest of the time behind; and not at all once they are out
	var rope_front := t >= 3.12 and t < 5.25
	var draw_rope := func() -> void:
		if t < 3.12:
			IntroKit.rope(c, t, hook_pt, hook_pt + Vector2(5, 0), true, LEASH_LEN, FLOOR - 4.0)
		elif t < 5.25:
			# carried gathered up in her mouth: a short swinging bight under
			# her chin, taken in as she lands
			var gather := Anim.curve("io", Anim.span(t, 3.12, 3.45))
			IntroKit.rope(c, t, mp["ring"], mp["mouth"], true, lerpf(LEASH_LEN, CARRY_LEN, gather), FLOOR - 4.0)
		elif t < 8.3:
			# let go on their knee, it pays back out to its whole length
			var to_knee := Anim.curve("io", Anim.span(t, 5.25, 5.4))
			var out := Anim.curve("io", Anim.span(t, 5.25, 5.9))
			IntroKit.rope(c, t, mp["ring"], mp["mouth"].lerp(KNEE, to_knee), true, lerpf(CARRY_LEN, LEASH_LEN, out), FLOOR - 4.0)
		else:
			var take := Anim.curve("io", Anim.span(t, 8.3, 8.42))
			IntroKit.rope(c, t, mp["ring"], KNEE.lerp(hand, take), true, LEASH_LEN, FLOOR - 4.0)
	if not rope_front and not h_gone:
		draw_rope.call()
	var m := mp
	if not m_gone:
		m = IntroKit.millie(c, mpos, MS, face, sq, pose, FLOOR)
	if rope_front:
		draw_rope.call()
	# the human's non-reply: a "..." over their head, after the phone jolts
	if t > 7.25 and t < 8.15:
		IntroKit.dots(c, Vector2(SOFA_X + 96, FLOOR - 352), t - 7.25)
	# the sigh: a soft curl of breath, drifting up and away from them
	IntroKit.breath(c, m["mouth"] + Vector2(6, -6), Anim.span(t, 7.62, 8.3))
	# the dash: speed lines behind both, a puff of dust where she left
	if t > 9.27 and not m_gone:
		IntroKit.speed_lines(c, mpos + Vector2(-60, -60), Vector2.RIGHT, 80.0, 3, 0.7)
	if t > 9.27 and t < 10.0:
		for k in range(3):
			IntroKit.puff(c, Vector2(650.0 - float(k) * 28.0, FLOOR - 12.0 - float(k % 2) * 12.0), 13.0 - float(k) * 3.0,
				1.0 - Anim.span(t, 9.3, 10.0))
	if hx > 620.0 and not h_gone:
		IntroKit.speed_lines(c, Vector2(hx, hy) + Vector2(-80, -140), Vector2.RIGHT, 80.0, 3, 0.6)
	# through the door: the light swallows whoever is in the doorway
	# the doorway's light, over whoever is stepping through it
	var thru := maxf(Anim.span(mx, 1040.0, 1134.0), Anim.span(hx, 1030.0, 1130.0))
	if door_open > 0.3 and thru > 0.0:
		c.draw_rect(DOOR.grow(-4.0), Color(1.0, 0.96, 0.78, minf(thru * 1.2, 1.0)))
	# a quick white flash once they are out, then the street
	var flash: float = Anim.k(t, [[9.84, 0.0], [9.95, 1.0, "out"], [TITLE_AT, 1.0]])
	IntroKit.fade(c, flash, Color(1.0, 0.98, 0.92))
	IntroKit.fade(c, 1.0 - Anim.span(t, 0.0, 0.8))


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
	c.draw_rect(Rect2(-200, 0, 1680, 640), Color(0.98, 0.95, 0.88, 0.25))
	# a soft shade behind where the title hangs, so cream letters read
	for i in range(6):
		var f := 1.0 - float(i) * 0.15
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(640, 300), Vector2(560, 150) * f), Color(0.30, 0.18, 0.10, 0.045))
	for tx: float in [110.0, 1170.0]:
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
	IntroTitle.draw(c, t - TITLE_AT, "swing")
	# and there they go along the bottom: Millie trotting ahead, the leash
	# taut, your human towed after her, leaning in, still on the phone
	var x: float = Anim.k(t, [[10.9, -120.0], [13.6, 1420.0, "lin"]])
	if t > 10.9 and t < 13.6:
		# feet matched to the ground: her trot and their stride advance with
		# the distance covered, not the clock
		var mphase := x * 0.125
		var mpose := {"gait": 1.0, "phase": mphase, "lean": 0.3, "crouch": 0.3, "push": 0.5, "head_up": 0.1,
			"tail": sin(mphase) * 0.3, "brow": 0.6, "mouth": 0.5}
		var hp := Vector2(x - 205.0, 652.0)
		var hand := IntroKit.human(c, hp, 0.9, 1.0, Vector2.ONE,
			{"stride": x * 0.036, "stride_amp": 1.0, "phone": 1.0, "glow": 0.5, "reach": 1.0, "lean": 0.32}, 0.0, 652.0)
		var mpt := IntroKit.millie_points(Vector2(x, 652.0), 0.9, 1.0, Vector2.ONE, mpose)
		IntroKit.leash(c, mpt["ring"], hand, 2.0 + 2.0 * sin(mphase * 2.0))
		IntroKit.millie(c, Vector2(x, 652.0), 0.9, 1.0, Vector2.ONE, mpose, 652.0)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.22), Color(1.0, 0.98, 0.92))
