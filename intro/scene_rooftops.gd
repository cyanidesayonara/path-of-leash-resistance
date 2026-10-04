class_name SceneRooftops
extends RefCounted

# Intro 2, "Down from the rooftops": the place first. Dawn over Barcelona's
# roofs (water tanks, chimneys, a basilica's spires far off, pigeons), the
# camera drops down a façade of green shutters, balconies, laundry and
# geraniums to a street door. It opens. Millie steps out, nose down. Your
# human follows, phone up. She looks up at them, then down the street; ears
# up, a crouch - and she lunges, the leash snaps taut, they lurch after her,
# the camera whips along and the title slams in.

const LENGTH := 13.0
const S := 1.5
const STREET := 640.0
const DOOR_X := 640.0
const TITLE_AT := 8.9


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return [Vector2(640, 360), 1.0]
	var cy: float = Anim.k(t, [[0.0, -620.0], [0.8, -620.0], [4.6, 470.0, "io"]])
	var cx: float = Anim.k(t, [[0.0, 640.0], [7.9, 680.0, "io"], [8.3, 900.0, "out"], [8.85, 2200.0, "in"]])
	var z: float = Anim.k(t, [[0.0, 1.0], [4.0, 1.0], [5.2, 1.3, "io"], [7.6, 1.3], [7.9, 1.45, "io"], [8.3, 1.2, "out"]])
	return [Vector2(cx, cy), z]


static func _sky(c: CanvasItem) -> void:
	for i in range(14):
		var f := float(i) / 13.0
		c.draw_rect(Rect2(-600, -1200.0 + f * 900.0, 3800, 900.0 / 13.0 + 1.0), Color(0.36, 0.42, 0.66).lerp(Color(0.99, 0.78, 0.58), f))
	c.draw_rect(Rect2(-600, -300, 3800, 1200), Color(0.99, 0.80, 0.60))
	c.draw_circle(Vector2(1020, -470), 120.0, Color(1.0, 0.92, 0.70, 0.35))
	c.draw_circle(Vector2(1020, -470), 60.0, Color(1.0, 0.95, 0.80, 0.8))
	# the far city: blocks, and the basilica's spires
	var far := Color(0.70, 0.54, 0.58)
	var x := -500.0
	var k := 0
	while x < 2600.0:
		var w := 60.0 + fmod(float(k) * 37.0, 70.0)
		var h := 40.0 + fmod(float(k) * 53.0, 80.0)
		c.draw_rect(Rect2(x, -380.0 - h, w, h + 100.0), far)
		x += w
		k += 1
	for sp: Array in [[300.0, 260.0], [330.0, 300.0], [362.0, 280.0], [394.0, 240.0]]:
		var bx: float = sp[0]
		var hh: float = sp[1]
		c.draw_rect(Rect2(bx - 9.0, -380.0 - hh, 18.0, hh), far.darkened(0.08))
		c.draw_colored_polygon(MillieSide.ellipse(Vector2(bx, -380.0 - hh), Vector2(9, 18)), far.darkened(0.08))
		c.draw_circle(Vector2(bx, -396.0 - hh), 4.0, far.darkened(0.08))


static func _roofs(c: CanvasItem, t: float) -> void:
	# the neighbouring roofs, terracotta, with what sits on Barcelona roofs
	var tile := Color(0.76, 0.42, 0.28)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-600, -300), Vector2(-100, -390), Vector2(400, -300)]), tile.darkened(0.1))
	c.draw_colored_polygon(PackedVector2Array([Vector2(900, -300), Vector2(1350, -380), Vector2(1900, -300)]), tile)
	for tk: Vector2 in [Vector2(250, -330), Vector2(1240, -360), Vector2(1460, -340)]:
		c.draw_rect(Rect2(tk + Vector2(-26, -50), Vector2(52, 50)).grow(2.0), IntroKit.INK)
		c.draw_rect(Rect2(tk + Vector2(-26, -50), Vector2(52, 50)), Color(0.86, 0.86, 0.84))
		c.draw_colored_polygon(MillieSide.ellipse(tk + Vector2(0, -50), Vector2(26, 6)), Color(0.70, 0.70, 0.70))
	for ch: Vector2 in [Vector2(-40, -400), Vector2(1080, -360)]:
		c.draw_rect(Rect2(ch + Vector2(-10, -40), Vector2(20, 44)), Color(0.56, 0.36, 0.26))
		c.draw_rect(Rect2(ch + Vector2(-16, -46), Vector2(32, 8)), Color(0.40, 0.26, 0.20))
	for an: Vector2 in [Vector2(160, -380), Vector2(1350, -380)]:
		c.draw_line(an, an + Vector2(0, -70), IntroKit.INK, 3.0)
		for j in range(3):
			c.draw_line(an + Vector2(-20 + j * 4, -60 + j * 14), an + Vector2(20 - j * 4, -60 + j * 14), IntroKit.INK, 2.0)
	# pigeons crossing the dawn
	for p in range(3):
		var px := fmod(t * 160.0 + float(p) * 260.0, 2000.0) - 400.0
		var py := -560.0 + float(p) * 40.0 + sin(t * 2.0 + float(p)) * 10.0
		var flap := sin(t * 16.0 + float(p) * 2.0) * 8.0
		c.draw_polyline(PackedVector2Array([Vector2(px - 14, py - flap), Vector2(px, py), Vector2(px + 14, py - flap)]), IntroKit.INK, 3.0)


static func _facade(c: CanvasItem, t: float, door_open: float) -> void:
	var wall := Color(0.88, 0.70, 0.48)
	c.draw_rect(Rect2(-600, -300, 3800, STREET + 300), wall)
	# cornice
	c.draw_rect(Rect2(-600, -316, 3800, 24), wall.lightened(0.15))
	c.draw_rect(Rect2(-600, -292, 3800, 6), wall.darkened(0.25))
	# three floors of windows with green shutters and iron balconies
	for fl in range(3):
		var wy := -220.0 + float(fl) * 200.0
		for col in range(-1, 7):
			var wx := 120.0 + float(col) * 220.0
			var win := Rect2(wx, wy, 90, 140)
			c.draw_rect(win.grow(6.0), wall.darkened(0.12))
			c.draw_rect(win, Color(0.20, 0.16, 0.14))
			var open := fmod(float(col * 3 + fl), 4.0) < 2.0
			var shut := Color(0.30, 0.52, 0.38)
			if open:
				c.draw_rect(Rect2(wx - 40, wy, 38, 140), shut)
				c.draw_rect(Rect2(wx + 92, wy, 38, 140), shut)
			else:
				c.draw_rect(win, shut)
				for sl in range(10):
					c.draw_line(Vector2(wx, wy + 8.0 + float(sl) * 13.0), Vector2(wx + 90, wy + 8.0 + float(sl) * 13.0), shut.darkened(0.25), 2.0)
			# the balcony: slab, rail, bars, and on some a pot of geraniums
			c.draw_rect(Rect2(wx - 20, wy + 140, 130, 10), wall.darkened(0.3))
			c.draw_line(Vector2(wx - 18, wy + 100), Vector2(wx + 108, wy + 100), IntroKit.INK, 3.0)
			for bar in range(9):
				c.draw_line(Vector2(wx - 14.0 + float(bar) * 15.0, wy + 100), Vector2(wx - 14.0 + float(bar) * 15.0, wy + 140), IntroKit.INK, 2.0)
			if (col + fl) % 3 == 0:
				c.draw_rect(Rect2(wx + 4, wy + 86, 22, 16), Color(0.74, 0.40, 0.26))
				for gi in range(4):
					c.draw_circle(Vector2(wx + 8.0 + float(gi) * 5.0, wy + 82.0 - float(gi % 2) * 5.0), 5.0, Color(0.88, 0.16, 0.22))
		# laundry strung across between two balconies on the middle floor
		if fl == 1:
			var la := Vector2(560, wy + 60)
			var lb := Vector2(780, wy + 60)
			c.draw_line(la, lb, IntroKit.INK, 1.5)
			for gi in range(4):
				var gx := la.x + 30.0 + float(gi) * 50.0
				var sway := sin(t * 2.0 + float(gi)) * 3.0
				var gc: Color = [Color(0.96, 0.96, 0.92), Color(0.30, 0.50, 0.82), Color(0.94, 0.70, 0.30), Color(0.86, 0.36, 0.40)][gi]
				c.draw_colored_polygon(PackedVector2Array([Vector2(gx - 14, wy + 60), Vector2(gx + 14, wy + 60),
					Vector2(gx + 12 + sway, wy + 100), Vector2(gx - 12 + sway, wy + 100)]), gc)
	# the street level: shop shutters either side, the door in the middle
	for sx: float in [180.0, 960.0]:
		c.draw_rect(Rect2(sx, 430, 200, STREET - 430), Color(0.56, 0.58, 0.60))
		for sl in range(14):
			c.draw_line(Vector2(sx, 436.0 + float(sl) * 14.0), Vector2(sx + 200, 436.0 + float(sl) * 14.0), Color(0.44, 0.46, 0.48), 2.0)
	var dr := Rect2(DOOR_X - 90, 400, 180, STREET - 400)
	c.draw_rect(dr.grow(14.0), wall.darkened(0.25))
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(DOOR_X, 400), Vector2(104, 50)), wall.darkened(0.25))
	c.draw_rect(dr, Color(0.10, 0.08, 0.07))
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(DOOR_X, 400), Vector2(90, 40)), Color(0.10, 0.08, 0.07))
	# two leaves, swinging in
	var lw := 90.0 * (1.0 - door_open * 0.8)
	for side: float in [-1.0, 1.0]:
		var lr := Rect2(DOOR_X - lw if side < 0.0 else DOOR_X, 400, lw, STREET - 400)
		if side > 0.0:
			lr.position.x = DOOR_X + 90.0 - lw
		if side < 0.0:
			lr.position.x = DOOR_X - 90.0
		c.draw_rect(lr, Color(0.44, 0.28, 0.18))
		c.draw_rect(Rect2(lr.position + Vector2(10, 20), Vector2(maxf(lw - 20.0, 1.0), 90)), Color(0.38, 0.24, 0.15))
		c.draw_rect(Rect2(lr.position + Vector2(10, 130), Vector2(maxf(lw - 20.0, 1.0), 90)), Color(0.38, 0.24, 0.15))
	# the pavement and the kerb
	c.draw_rect(Rect2(-600, STREET, 3800, 200), Color(0.74, 0.70, 0.64))
	c.draw_rect(Rect2(-600, STREET + 120, 3800, 14), Color(0.58, 0.55, 0.50))
	for px in range(-6, 30):
		c.draw_line(Vector2(float(px) * 110.0, STREET), Vector2(float(px) * 110.0 - 30.0, STREET + 120), Color(0.66, 0.62, 0.56), 2.0)


static func draw(c: CanvasItem, t_real: float) -> void:
	var t := Anim.twos(t_real)
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var door_open: float = Anim.k(t, [[4.6, 0.0], [5.0, 1.0, "out"]])
	_sky(c)
	_roofs(c, t_real)
	_facade(c, t_real, door_open)
	# Millie: out of the dark doorway, nose down, then the lunge
	var mx: float = Anim.k(t, [[4.9, DOOR_X - 40.0], [6.0, 780.0, "out"], [7.9, 780.0], [8.6, 1700.0, "in"]])
	var sniff := Anim.span(t, 5.0, 6.2) * (1.0 - Anim.span(t, 6.3, 6.6))
	var crouch := Anim.span(t, 7.3, 7.8) * (1.0 - Anim.span(t, 7.85, 7.95))
	var go := Anim.span(t, 7.85, 7.95)
	var walk := Anim.span(t, 4.9, 6.0) * (1.0 - Anim.span(t, 5.9, 6.0))
	var pose := {
		"lean": 0.25 * sniff + 0.22 * crouch + 0.12 * go,
		"crouch": crouch,
		"head_up": -0.45 * sniff + Anim.k(t, [[6.4, 0.0], [6.7, 0.8, "out"], [7.1, 0.8], [7.3, 0.1, "io"]]),
		"reach": sin(t_real * 13.0) * 0.6 * walk + go,
		"push": -sin(t_real * 13.0) * 0.6 * walk + 0.4 * crouch + 0.9 * go,
		"ear": Anim.k(t, [[7.0, 0.0], [7.2, -0.4, "out"], [7.85, -0.4], [7.95, 1.2, "snap"]]),
		"tail": Anim.k(t, [[6.7, 0.0], [6.9, 0.5, "out"]]) * sin(t_real * 16.0) * (1.0 - go),
		"mouth": 0.8 * go,
		"brow": Anim.k(t, [[6.6, 0.0], [6.8, 1.0, "out"], [7.3, 1.0], [7.5, -1.0, "io"]]),
	}
	var sq := Anim.squash(Anim.k(t, [[7.3, 1.0], [7.8, 0.8, "io"], [7.95, 1.35, "snap"]]))
	if t > 7.9:
		sq = Vector2(1.35, 0.8)
	var mpos := Vector2(mx, STREET + 70.0) + Anim.boil(t_real, 2.0, 0.5)
	# your human: out of the door a beat later, then yanked along
	var hx: float = Anim.k(t, [[5.6, DOOR_X - 60.0], [6.6, 620.0, "out"], [7.95, 620.0], [8.6, 1500.0, "in"]])
	var hwalk := Anim.span(t, 5.6, 6.6) * (1.0 - Anim.span(t, 6.5, 6.6))
	var hgo := Anim.span(t, 7.95, 8.1)
	var hpose := {
		"stride": t_real * 9.0, "stride_amp": maxf(hwalk, hgo),
		"phone": 1.0, "glow": 0.4, "reach": 0.4 + 0.6 * hgo,
		"lean": 0.85 * hgo, "lift": 0.5 * hgo, "head": 0.3 * hgo, "mouth": hgo,
	}
	var hand := Vector2.ZERO
	if t > 5.5:
		hand = IntroKit.human(c, Vector2(hx, STREET + 70.0), S, 1.0, Vector2(1.2, 0.88) if hgo > 0.0 else Vector2.ONE, hpose)
	if t < 4.85:
		IntroKit.fade(c, 1.0 - Anim.span(t_real, 0.0, 1.0))
		return
	var m := IntroKit.millie(c, mpos, S * 0.95, 1.0, sq, pose)
	if t > 5.5:
		IntroKit.leash(c, m["ring"], hand, Anim.k(t, [[5.5, 50.0], [7.8, 40.0], [7.95, 0.0, "snap"]]))
	else:
		# the leash, ahead of whoever is holding it in the dark
		IntroKit.leash(c, m["ring"], Vector2(DOOR_X - 90.0, STREET - 40.0), 30.0)
	if t > 7.9:
		IntroKit.speed_lines(c, mpos + Vector2(-60, -70), Vector2.RIGHT, 160.0)
		IntroKit.speed_lines(c, Vector2(hx, STREET - 160.0), Vector2.RIGHT, 120.0, 3)
	IntroKit.fade(c, 1.0 - Anim.span(t_real, 0.0, 1.0))
	# the whip: a white streak as the camera flies along
	IntroKit.fade(c, Anim.span(t_real, 8.6, 8.9), Color(1.0, 0.95, 0.85))


static func _title(c: CanvasItem, t: float) -> void:
	# the sunny street the lunge took them into, behind the title
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(0, f * 720.0, 1280, 720.0 / 7.0 + 1.0), Color(0.99, 0.84, 0.62).lerp(Color(0.88, 0.70, 0.48), f))
	c.draw_rect(Rect2(0, 560, 1280, 160), Color(0.74, 0.70, 0.64))
	IntroTitle.draw(c, t - TITLE_AT, "slam")
	# the thump: dust from where it hit
	var d := Anim.span(t, TITLE_AT + 0.28, TITLE_AT + 0.9)
	if d > 0.0 and d < 1.0:
		for k in range(6):
			var a := float(k) / 5.0 * PI
			IntroKit.puff(c, Vector2(640, 420) + Vector2(cos(a) * (380.0 + d * 120.0), sin(a) * 30.0 + 40.0), 16.0 * (1.0 - d), 1.0 - d)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.25), Color(1.0, 0.95, 0.85))
