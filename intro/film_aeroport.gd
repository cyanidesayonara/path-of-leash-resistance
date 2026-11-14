class_name FilmAeroport
extends RefCounted

# L'Aeroport's film, "Last call": the telegraph to run as the walk turns for
# home (systems/home_chase.gd plays it through intro/film_player.gd).
# Terminal 1's pier, side on: the glass wall and a jet at its stand beyond it,
# the yellow signs, a row of seats, a gate desk. The two of them heading back
# up the concourse, your human on the phone. Bing bong: her ears go up and she
# looks back. Down the hall the gate queue's belts go taut, then go flying:
# airport security comes through them at a run, five of them, each holding
# out something a dog dreads: the travel crate with its door open, a catch
# net, a detector wand, a loudhailer, the flat of a hand and a whistle. Cases
# come skidding up the floor ahead of them. A push in on her face. She spins,
# digs in and bolts; the leash snaps taut, your human is yanked off after her,
# and RUN! slams in with the crate's mouth filling the frame and the net
# coming down. The five are the walk's (entities/aeroport_threat.gd).

const LENGTH := FilmKit.LENGTH
const BG := Color(0.12, 0.16, 0.22)
const FEET := 640.0              # the floor the pair walks on
const WALL_FOOT := 566.0         # where the glass meets the floor
const CEILING := -60.0
const QUEUE_X := -260.0          # the gate queue it comes through
const OUT_AT := 2.2            # they come through the queue: the belts go
const CASE_AT := 2.9             # the first case comes off a dolly
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const AS_K := 1.5                # the squad's scale: a head taller than your human
# the walk's colours (entities/aeroport_threat.gd, systems/aeroport_art.gd)
const BUGGY_BLUE := Color(0.12, 0.28, 0.55)
const BEACON := Color(1.0, 0.75, 0.15)
const WHEEL := Color(0.12, 0.12, 0.14)
# the line, as the walk's: [what they hold, x behind the lead, far rank,
# skin, a hi-vis vest]
const SQUAD := [
	["net", -290.0, true, Color(0.86, 0.62, 0.48), true],
	["wand", -110.0, true, Color(0.80, 0.60, 0.44), true],
	["megaphone", -380.0, false, Color(0.93, 0.76, 0.62), false],
	["whistle", -200.0, false, Color(0.97, 0.84, 0.72), false],
	["crate", 0.0, false, Color(0.56, 0.38, 0.26), true],
]
const NAVY := Color(0.14, 0.18, 0.28)
const HIVIS := Color(0.90, 0.95, 0.20)
const SKIN := Color(0.90, 0.72, 0.58)
const CASE_RED := Color(0.85, 0.18, 0.15)
const CASE_BLUE := Color(0.18, 0.40, 0.85)
const CASE_YELLOW := Color(0.94, 0.74, 0.16)
const CASE_GREEN := Color(0.22, 0.58, 0.44)
const CASE_PINK := Color(0.86, 0.44, 0.66)
const BELT_RED := Color(0.80, 0.14, 0.16)
const SIGN_YELLOW := Color(0.98, 0.82, 0.10)
const FLOOR := Color(0.87, 0.87, 0.86)
const FLOOR_FAR := Color(0.78, 0.80, 0.82)
const FRAME := Color(0.30, 0.33, 0.38)
const APRON := Color(0.66, 0.67, 0.67)
const PLANE_WHITE := Color(0.96, 0.97, 0.98)
const PLANE_SHADE := Color(0.82, 0.85, 0.90)
const TEAL := Color(0.10, 0.52, 0.58)
const INK := IntroKit.INK
const ShapeBatch := preload("res://systems/shape_batch.gd")
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.25, "chime", 1.0, -4.0],
	[OUT_AT, "crack", 1.3, -6.0],
	[OUT_AT + 0.1, "whoop", 1.4, -6.0],
	[2.55, "whistle", 1.5, -6.0],
	[CASE_AT, "crack", 1.0, -8.0],
	[3.3, "whoop", 1.6, -6.0],
	[3.55, "whistle", 1.7, -6.0],
	[4.40, "crack", 1.4, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "crack", 0.6, -3.0],
]


# the camera: [centre, zoom]. On the pair; a pan back down the hall to the
# queue as she looks round, held as it comes through; a whip to a close-up of
# her; a cut wide on the bolt that runs right with them; the card.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 640.0, "io"], [2.15, 120.0, "io"], [3.0, 240.0, "io"],
		[3.9, 420.0, "io"], [4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.15, 370.0, "io"], [3.9, 400.0, "io"], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.15, 0.86, "io"], [3.9, 0.92, "io"], [4.2, 1.7, "io"]])
	# it shakes the hall as it comes
	var rum := Anim.span(t, OUT_AT, OUT_AT + 0.2) * (1.0 - Anim.span(t, 3.9, 4.2))
	return [Vector2(x, y) + Vector2(sin(t * 83.0), sin(t * 61.0)) * 5.0 * rum, z]


# where the lead officer's feet are: off down the hall, through the queue,
# then after them (the crate is held out ahead of that)
static func squad_x(t: float) -> float:
	return Anim.k(t, [[0.0, -1500.0], [OUT_AT - 0.25, -900.0], [OUT_AT, QUEUE_X - 40.0], [2.9, -60.0, "out"], [3.9, 30.0],
		[BOLT_AT, 180.0], [TITLE_AT, 1300.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_terminal(c, t_real)
	var cx := squad_x(t_real)
	_queue(c, t_real, cx)
	_squad(c, Anim.twos(t_real), t_real, cx)
	FilmKit.pair(c, t_real, FEET)
	_cases(c, t_real, cx)
	_bing_bong(c, t_real)
	FilmKit.fades(c, t_real)


# a soft round pool of light: a gradient, never stacked discs
static func _glow(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	var b := ShapeBatch.new(c)
	b.glow(at, r, col, 0.1)
	b.flush()


# The pier: sky and apron through the glass with a jet at its stand and a
# tug going by, the roof's soffit and trusses, the yellow sign and the board,
# a column, seats with two people in them, the gate desk, the polished floor.
static func _terminal(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-1800, -900.0, 5000, 900.0 + WALL_FOOT), Color(0.36, 0.62, 0.90), Color(0.84, 0.91, 0.95))
	# cloud, in three soft banks
	for i in range(5):
		var cp := Vector2(-900.0 + float(i) * 640.0 + fposmod(float(i) * 173.0, 200.0), 60.0 + float(i % 3) * 70.0)
		for k in range(4):
			c.draw_colored_polygon(MillieSide.ellipse(cp + Vector2(float(k) * 62.0 - 90.0, sin(float(k) * 2.0) * 14.0), Vector2(90.0, 30.0)), Color(1.0, 1.0, 1.0, 0.55))
	# one climbing away, far off
	var fly := Vector2(-400.0 + t * 90.0, 150.0 - t * 16.0)
	c.draw_line(fly, fly + Vector2(46.0, -8.0), Color(0.94, 0.95, 0.97), 7.0)
	c.draw_colored_polygon(PackedVector2Array([fly + Vector2(18.0, -3.0), fly + Vector2(0.0, 14.0), fly + Vector2(10.0, 14.0), fly + Vector2(30.0, -5.0)]), Color(0.80, 0.83, 0.88))
	c.draw_colored_polygon(PackedVector2Array([fly + Vector2(2.0, -1.0), fly + Vector2(-8.0, -16.0), fly + Vector2(0.0, -16.0), fly + Vector2(12.0, -3.0)]), TEAL)
	# the far side of the field: the tower, hangars, the line of the sea
	var hz := WALL_FOOT - 150.0
	c.draw_rect(Rect2(-1800, hz - 14.0, 5000, 14.0), Color(0.40, 0.60, 0.78))
	for i in range(9):
		var hx := -1500.0 + float(i) * 420.0
		c.draw_rect(Rect2(hx, hz - 40.0 - float(i % 3) * 12.0, 230.0, 40.0 + float(i % 3) * 12.0), Color(0.66, 0.72, 0.80))
	c.draw_rect(Rect2(1690.0, hz - 250.0, 22.0, 250.0), Color(0.72, 0.76, 0.82))
	c.draw_colored_polygon(PackedVector2Array([Vector2(1664.0, hz - 250.0), Vector2(1738.0, hz - 250.0), Vector2(1752.0, hz - 290.0), Vector2(1650.0, hz - 290.0)]), Color(0.30, 0.40, 0.52))
	c.draw_rect(Rect2(1656.0, hz - 300.0, 90.0, 10.0), Color(0.80, 0.83, 0.88))
	# the apron and its paint
	c.draw_rect(Rect2(-1800, hz, 5000, 150.0), APRON)
	c.draw_rect(Rect2(-1800, hz + 60.0, 5000, 5.0), Color(0.96, 0.80, 0.16))
	for i in range(24):
		c.draw_rect(Rect2(-1800.0 + float(i) * 210.0, hz, 2.0, 150.0), Color(0.58, 0.59, 0.60))
	_jet(c, Vector2(620.0, hz + 96.0))
	# a tug and its dollies trundling along under the wing
	var tx := 2300.0 - fposmod(t * 150.0 + 600.0, 4200.0)
	for k in range(3):
		var dx := tx + 70.0 + float(k) * 64.0
		c.draw_rect(Rect2(dx, hz + 96.0, 54.0, 8.0), Color(0.30, 0.32, 0.36))
		for n in range(3):
			c.draw_rect(Rect2(dx + 4.0 + float(n) * 16.0, hz + 80.0 - float((n + k) % 2) * 8.0, 14.0, 16.0 + float((n + k) % 2) * 8.0),
				[CASE_RED, CASE_BLUE, CASE_YELLOW, CASE_GREEN][(n + k) % 4])
		c.draw_circle(Vector2(dx + 10.0, hz + 108.0), 6.0, WHEEL)
		c.draw_circle(Vector2(dx + 44.0, hz + 108.0), 6.0, WHEEL)
	c.draw_rect(Rect2(tx, hz + 78.0, 56.0, 26.0), Color(0.96, 0.80, 0.16))
	c.draw_rect(Rect2(tx + 6.0, hz + 62.0, 26.0, 18.0), Color(0.30, 0.34, 0.40))
	c.draw_circle(Vector2(tx + 12.0, hz + 108.0), 8.0, WHEEL)
	c.draw_circle(Vector2(tx + 44.0, hz + 108.0), 8.0, WHEEL)
	# the glass: a tint, two long reflections, the mullions and a transom
	c.draw_rect(Rect2(-1800, CEILING, 5000, WALL_FOOT - CEILING), Color(0.70, 0.86, 0.94, 0.16))
	for i in range(6):
		var rx := -1500.0 + float(i) * 760.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(rx, CEILING), Vector2(rx + 120.0, CEILING), Vector2(rx - 260.0, WALL_FOOT), Vector2(rx - 380.0, WALL_FOOT)]), Color(1.0, 1.0, 1.0, 0.10))
	var wx := -1680.0
	var n := 0
	while wx < 3200.0:
		c.draw_rect(Rect2(wx - (7.0 if n % 3 == 0 else 3.0), CEILING, 14.0 if n % 3 == 0 else 6.0, WALL_FOOT - CEILING), FRAME)
		wx += 240.0
		n += 1
	c.draw_rect(Rect2(-1800, WALL_FOOT - 330.0, 5000, 6.0), FRAME)
	c.draw_rect(Rect2(-1800, WALL_FOOT - 16.0, 5000, 16.0), FRAME)
	c.draw_rect(Rect2(-1800, WALL_FOOT - 16.0, 5000, 4.0), Color(0.56, 0.60, 0.66))
	# the roof: soffit, a truss to every heavy post, downlights
	c.draw_rect(Rect2(-1800, -900.0, 5000, 900.0 + CEILING), Color(0.86, 0.87, 0.88))
	c.draw_rect(Rect2(-1800, CEILING - 16.0, 5000, 16.0), Color(0.66, 0.68, 0.72))
	wx = -1680.0
	while wx < 3200.0:
		c.draw_line(Vector2(wx, CEILING), Vector2(wx + 240.0, CEILING + 90.0), Color(0.80, 0.82, 0.85), 10.0)
		c.draw_line(Vector2(wx + 720.0, CEILING), Vector2(wx + 480.0, CEILING + 90.0), Color(0.80, 0.82, 0.85), 10.0)
		c.draw_rect(Rect2(wx + 240.0, CEILING + 84.0, 240.0, 10.0), Color(0.74, 0.76, 0.80))
		wx += 720.0
	# the floor: polished, lighter where the day lies on it, the posts and
	# the bright sky standing in it upside down
	IntroKit.vgrad(c, Rect2(-1800, WALL_FOOT, 5000, 110.0), FLOOR_FAR, FLOOR)
	c.draw_rect(Rect2(-1800, WALL_FOOT + 110.0, 5000, 600.0), FLOOR)
	wx = -1680.0
	n = 0
	while wx < 3200.0:
		c.draw_colored_polygon(PackedVector2Array([Vector2(wx - 5.0, WALL_FOOT), Vector2(wx + 5.0, WALL_FOOT), Vector2(wx + 60.0, WALL_FOOT + 150.0), Vector2(wx + 30.0, WALL_FOOT + 150.0)]), Color(0.30, 0.33, 0.38, 0.12))
		c.draw_colored_polygon(PackedVector2Array([Vector2(wx + 20.0, WALL_FOOT), Vector2(wx + 220.0, WALL_FOOT), Vector2(wx + 330.0, WALL_FOOT + 230.0), Vector2(wx + 130.0, WALL_FOOT + 230.0)]), Color(1.0, 0.98, 0.90, 0.20))
		wx += 240.0
		n += 1
	for i in range(8):
		c.draw_rect(Rect2(-1800, WALL_FOOT + 40.0 + float(i) * float(i) * 9.0, 5000, 1.5), Color(0.70, 0.71, 0.72, 0.6))
	_furniture(c, t)


# the jet at the stand, side on, nose toward the terminal's far end: gear and
# engine, the door with the bridge on it, a tail in the airline's colour
static func _jet(c: CanvasItem, belly: Vector2) -> void:
	var y := belly.y - 150.0
	# gear, then the far wing behind the body
	for gx: float in [130.0, 520.0]:
		c.draw_line(Vector2(belly.x + gx, y + 50.0), Vector2(belly.x + gx, belly.y - 14.0), Color(0.40, 0.42, 0.46), 8.0)
		c.draw_circle(Vector2(belly.x + gx, belly.y - 12.0), 15.0, WHEEL)
		c.draw_circle(Vector2(belly.x + gx, belly.y - 12.0), 6.0, Color(0.6, 0.6, 0.62))
	# the tail
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x + 800.0, y - 40.0), Vector2(belly.x + 960.0, y - 250.0), Vector2(belly.x + 1040.0, y - 250.0),
		Vector2(belly.x + 990.0, y - 30.0)]), TEAL)
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x + 900.0, y - 150.0), Vector2(belly.x + 960.0, y - 250.0), Vector2(belly.x + 1040.0, y - 250.0),
		Vector2(belly.x + 1018.0, y - 150.0)]), Color(0.96, 0.80, 0.16))
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x + 860.0, y - 10.0), Vector2(belly.x + 1060.0, y - 26.0), Vector2(belly.x + 1070.0, y - 8.0), Vector2(belly.x + 880.0, y + 10.0)]), PLANE_SHADE)
	# the body: a long tube with a rounded nose and a tapering tail cone
	var body := PackedVector2Array([Vector2(belly.x - 20.0, y + 10.0), Vector2(belly.x + 30.0, y - 40.0), Vector2(belly.x + 110.0, y - 62.0),
		Vector2(belly.x + 800.0, y - 62.0), Vector2(belly.x + 1040.0, y - 24.0), Vector2(belly.x + 1040.0, y - 6.0),
		Vector2(belly.x + 780.0, y + 58.0), Vector2(belly.x + 80.0, y + 58.0), Vector2(belly.x + 10.0, y + 40.0)])
	c.draw_colored_polygon(body, PLANE_WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x + 10.0, y + 40.0), Vector2(belly.x + 80.0, y + 30.0), Vector2(belly.x + 800.0, y + 30.0),
		Vector2(belly.x + 1040.0, y - 6.0), Vector2(belly.x + 780.0, y + 58.0), Vector2(belly.x + 80.0, y + 58.0)]), PLANE_SHADE)
	c.draw_rect(Rect2(belly.x + 60.0, y + 14.0, 800.0, 7.0), TEAL)
	# the cockpit's glass, the windows, the forward door
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x + 24.0, y - 30.0), Vector2(belly.x + 66.0, y - 46.0), Vector2(belly.x + 78.0, y - 28.0), Vector2(belly.x + 34.0, y - 16.0)]), Color(0.12, 0.16, 0.22))
	var wx := belly.x + 150.0
	while wx < belly.x + 800.0:
		c.draw_rect(Rect2(wx, y - 22.0, 9.0, 13.0), Color(0.22, 0.28, 0.38))
		wx += 24.0
	c.draw_rect(Rect2(belly.x + 108.0, y - 36.0, 26.0, 56.0), Color(0.70, 0.73, 0.78))
	# the near wing, swept, and the engine under it
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x + 330.0, y + 26.0), Vector2(belly.x + 560.0, y + 30.0), Vector2(belly.x + 720.0, y + 62.0), Vector2(belly.x + 650.0, y + 66.0)]), Color(0.72, 0.75, 0.80))
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(belly.x + 420.0, y + 74.0), Vector2(78.0, 30.0)), PLANE_WHITE)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(belly.x + 352.0, y + 74.0), Vector2(14.0, 30.0)), TEAL)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(belly.x + 349.0, y + 74.0), Vector2(8.0, 24.0)), Color(0.12, 0.16, 0.22))
	# the bridge onto the door, out of the terminal's side
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x - 700.0, y - 70.0), Vector2(belly.x + 96.0, y - 44.0), Vector2(belly.x + 96.0, y + 26.0), Vector2(belly.x - 700.0, y + 10.0)]), Color(0.78, 0.80, 0.83))
	c.draw_colored_polygon(PackedVector2Array([Vector2(belly.x - 700.0, y - 70.0), Vector2(belly.x + 96.0, y - 44.0), Vector2(belly.x + 96.0, y - 34.0), Vector2(belly.x - 700.0, y - 58.0)]), Color(0.90, 0.91, 0.93))
	var rx := belly.x - 660.0
	while rx < belly.x + 60.0:
		c.draw_line(Vector2(rx, y - 60.0 + (rx - belly.x + 700.0) * 0.03), Vector2(rx, y + 10.0 + (rx - belly.x + 700.0) * 0.02), Color(0.64, 0.66, 0.70), 2.0)
		rx += 40.0
	c.draw_rect(Rect2(belly.x + 96.0, y - 48.0, 24.0, 78.0), Color(0.14, 0.16, 0.20))
	c.draw_line(Vector2(belly.x - 240.0, y + 20.0), Vector2(belly.x - 240.0, belly.y - 8.0), Color(0.50, 0.52, 0.56), 14.0)
	c.draw_circle(Vector2(belly.x - 240.0, belly.y - 10.0), 14.0, WHEEL)


# what stands in the hall: a column, the yellow sign and the board hung from
# the roof, a beam of seats with two people waiting, the gate desk
static func _furniture(c: CanvasItem, t: float) -> void:
	# the sign: the airport's yellow, the gates and an arrow
	c.draw_rect(Rect2(256.0, CEILING, 5.0, 196.0), Color(0.40, 0.42, 0.46))
	c.draw_rect(Rect2(540.0, CEILING, 5.0, 196.0), Color(0.40, 0.42, 0.46))
	c.draw_rect(Rect2(230.0, 136.0, 340.0, 82.0), INK)
	c.draw_rect(Rect2(236.0, 142.0, 328.0, 70.0), SIGN_YELLOW)
	IntroTitle.word(c, "B20-B30", Vector2(380.0, 177.0), 44, 0.0)
	c.draw_line(Vector2(480.0, 177.0), Vector2(540.0, 177.0), INK, 9.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(530.0, 156.0), Vector2(556.0, 177.0), Vector2(530.0, 198.0)]), INK)
	# the board: flights in rows, one of them in red
	c.draw_rect(Rect2(866.0, CEILING, 5.0, 170.0), Color(0.40, 0.42, 0.46))
	c.draw_rect(Rect2(1150.0, CEILING, 5.0, 170.0), Color(0.40, 0.42, 0.46))
	c.draw_rect(Rect2(840.0, 106.0, 340.0, 150.0), INK)
	c.draw_rect(Rect2(848.0, 114.0, 324.0, 20.0), SIGN_YELLOW)
	for row in range(5):
		var ry := 144.0 + float(row) * 21.0
		c.draw_rect(Rect2(856.0, ry, 46.0, 10.0), Color(0.98, 0.84, 0.30))
		c.draw_rect(Rect2(912.0, ry, 90.0 + fposmod(float(row) * 37.0, 60.0), 10.0), Color(0.90, 0.90, 0.86))
		c.draw_rect(Rect2(1090.0, ry, 30.0, 10.0), Color(0.90, 0.90, 0.86))
		var last := row == 1
		var blink := last and fposmod(t * 3.0, 1.0) < 0.5
		c.draw_rect(Rect2(1130.0, ry, 34.0, 10.0), Color(0.94, 0.30, 0.24, 0.3 if blink else 1.0) if last else Color(0.36, 0.86, 0.50))
	# a column, floor to roof
	c.draw_rect(Rect2(-90.0, CEILING, 74.0, FEET - 26.0 - CEILING), Color(0.80, 0.80, 0.79))
	c.draw_rect(Rect2(-90.0, CEILING, 16.0, FEET - 26.0 - CEILING), Color(0.90, 0.90, 0.89))
	c.draw_rect(Rect2(-34.0, CEILING, 18.0, FEET - 26.0 - CEILING), Color(0.66, 0.67, 0.68))
	c.draw_rect(Rect2(-98.0, FEET - 60.0, 90.0, 36.0), Color(0.44, 0.47, 0.52))
	c.draw_rect(Rect2(-90.0, 300.0, 74.0, 16.0), SIGN_YELLOW)
	# seats on their beam against the glass, two of them taken
	var sx := 1240.0
	c.draw_rect(Rect2(sx - 10.0, FEET - 86.0, 330.0, 8.0), Color(0.62, 0.65, 0.70))
	for lx: float in [sx + 10.0, sx + 300.0]:
		c.draw_line(Vector2(lx, FEET - 80.0), Vector2(lx, FEET - 34.0), Color(0.62, 0.65, 0.70), 7.0)
		c.draw_line(Vector2(lx - 18.0, FEET - 34.0), Vector2(lx + 18.0, FEET - 34.0), Color(0.62, 0.65, 0.70), 7.0)
	for k in range(5):
		var seat := Vector2(sx + float(k) * 64.0, FEET - 86.0)
		c.draw_colored_polygon(IntroKit.rrect(Rect2(seat.x, seat.y - 84.0, 14.0, 84.0), 6.0), Color(0.20, 0.22, 0.27))
		c.draw_colored_polygon(IntroKit.rrect(Rect2(seat.x, seat.y - 14.0, 56.0, 16.0), 6.0), Color(0.30, 0.33, 0.40))
		if k == 1 or k == 3:
			var shirt: Color = Color(0.72, 0.24, 0.22) if k == 1 else Color(0.24, 0.50, 0.42)
			c.draw_line(seat + Vector2(26.0, -18.0), seat + Vector2(24.0, -78.0), shirt, 30.0)
			c.draw_line(seat + Vector2(24.0, -20.0), seat + Vector2(62.0, -20.0), shirt.darkened(0.4), 18.0)
			c.draw_line(seat + Vector2(62.0, -20.0), seat + Vector2(64.0, 46.0), shirt.darkened(0.4), 16.0)
			c.draw_circle(seat + Vector2(28.0, -104.0), 19.0, SKIN)
			c.draw_circle(seat + Vector2(22.0, -110.0), 19.0, Color(0.16, 0.12, 0.10) if k == 1 else Color(0.80, 0.66, 0.34))
			# a paper, or a phone
			if k == 1:
				c.draw_rect(Rect2(seat.x + 44.0, seat.y - 96.0, 8.0, 56.0), Color(0.95, 0.94, 0.90))
			else:
				c.draw_rect(Rect2(seat.x + 50.0, seat.y - 70.0, 7.0, 20.0), INK)
	# the gate desk: yellow front, a screen, the agent behind it
	var dx := 1700.0
	c.draw_circle(Vector2(dx + 60.0, FEET - 196.0), 20.0, SKIN)
	c.draw_circle(Vector2(dx + 66.0, FEET - 202.0), 20.0, Color(0.42, 0.26, 0.14))
	c.draw_rect(Rect2(dx + 36.0, FEET - 178.0, 48.0, 60.0), BUGGY_BLUE)
	c.draw_rect(Rect2(dx, FEET - 150.0, 150.0, 124.0), NAVY)
	c.draw_rect(Rect2(dx, FEET - 150.0, 150.0, 12.0), Color(0.84, 0.85, 0.87))
	c.draw_rect(Rect2(dx + 12.0, FEET - 124.0, 126.0, 44.0), SIGN_YELLOW)
	IntroTitle.word(c, "B22", Vector2(dx + 75.0, FEET - 102.0), 34, 0.0)


# The gate queue down the hall: posts and red belts, standing until it comes
# through them. Then each post is flung, turning, and the belts trail off the
# push bar.
static func _queue(c: CanvasItem, t: float, cart_front: float) -> void:
	for i in range(5):
		var px := QUEUE_X + float(i) * 110.0 - 220.0
		var hit_t := _hit_time(px)
		var base := Vector2(px, FEET - 30.0)
		if t < hit_t:
			# standing, and its belt to the next one; the belts shiver before it lands
			var sh := sin(t * 60.0) * 3.0 * Anim.span(t, OUT_AT - 0.35, OUT_AT)
			if i < 4:
				c.draw_line(base + Vector2(0.0, -96.0 + sh), base + Vector2(110.0, -96.0 - sh), BELT_RED.darkened(0.25), 12.0)
				c.draw_line(base + Vector2(0.0, -96.0 + sh), base + Vector2(110.0, -96.0 - sh), BELT_RED, 8.0)
			_post(c, base, 0.0)
		else:
			var d := t - hit_t
			var at := base + Vector2(d * (380.0 + float(i) * 60.0), -sin(minf(d * 2.2, PI)) * (220.0 + float(i % 2) * 90.0))
			if d * 2.2 < PI:
				_post(c, at, d * (9.0 + float(i)))
				c.draw_line(at + Vector2(0.0, -60.0), at + Vector2(-90.0, -30.0 + sin(d * 20.0) * 24.0), BELT_RED, 8.0)
			else:
				_post(c, Vector2(at.x, FEET - 22.0), PI * 0.5)


static func _hit_time(px: float) -> float:
	# when the crate, out ahead of the lead, reaches this post
	var lo := OUT_AT - 0.25
	var hi := 2.9
	for k in range(14):
		var mid := (lo + hi) * 0.5
		if squad_x(mid) + 60.0 < px:
			lo = mid
		else:
			hi = mid
	return hi


static func _post(c: CanvasItem, base: Vector2, rot: float) -> void:
	c.draw_set_transform(base, rot, Vector2.ONE)
	c.draw_colored_polygon(MillieSide.ellipse(Vector2(0.0, 0.0), Vector2(26.0, 8.0)), Color(0.16, 0.16, 0.18))
	c.draw_rect(Rect2(-5.0, -100.0, 10.0, 100.0), Color(0.70, 0.72, 0.76))
	c.draw_rect(Rect2(-5.0, -100.0, 3.0, 100.0), Color(0.92, 0.92, 0.94))
	c.draw_rect(Rect2(-9.0, -112.0, 18.0, 18.0), Color(0.16, 0.16, 0.18))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# a suitcase side on: shell, ribs, wheels, the handle up
static func _case(c: CanvasItem, at: Vector2, rot: float, col: Color, k: float) -> void:
	c.draw_set_transform(at, rot, Vector2(k, k))
	c.draw_colored_polygon(IntroKit.rrect(Rect2(-24.0, -34.0, 48.0, 68.0), 8.0), INK)
	c.draw_colored_polygon(IntroKit.rrect(Rect2(-21.0, -31.0, 42.0, 62.0), 6.0), col)
	for rx: float in [-8.0, 8.0]:
		c.draw_rect(Rect2(rx - 1.5, -29.0, 3.0, 58.0), col.darkened(0.25))
	c.draw_rect(Rect2(-17.0, -29.0, 5.0, 58.0), col.lightened(0.3))
	c.draw_rect(Rect2(-12.0, -50.0, 4.0, 18.0), INK)
	c.draw_rect(Rect2(8.0, -50.0, 4.0, 18.0), INK)
	c.draw_rect(Rect2(-14.0, -54.0, 28.0, 7.0), INK)
	c.draw_circle(Vector2(-15.0, 37.0), 6.0, INK)
	c.draw_circle(Vector2(15.0, 37.0), 6.0, INK)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# the cases they boot up the hall: a low arc, then a long skid
static func _cases(c: CanvasItem, t: float, cart_front: float) -> void:
	var cols: Array[Color] = [CASE_RED, CASE_BLUE, CASE_PINK]
	for i in range(3):
		var t0 := CASE_AT + float(i) * 0.32
		if t < t0 or t >= BOLT_AT + 0.3:
			continue
		var d := t - t0
		var from := Vector2(squad_x(t0) - 150.0, FEET - 40.0)
		var land := Vector2(330.0 + float(i) * 70.0, FEET - 6.0 + float(i) * 14.0)
		var air := 0.55
		if d < air:
			var k := d / air
			var p := from.lerp(land, k) + Vector2(0.0, -sin(k * PI) * 150.0)
			_case(c, p, d * 11.0, cols[i], 1.0)
		else:
			# down, and sliding on its side, slower and slower
			var sl := 1.0 - exp(-(d - air) * 3.0)
			var p := land + Vector2(sl * (150.0 + float(i) * 40.0), -24.0)
			for k in range(3):
				c.draw_line(p + Vector2(-50.0 - float(k) * 26.0, 20.0 - float(k) * 10.0), p + Vector2(-30.0 - float(k) * 26.0, 20.0 - float(k) * 10.0), Color(1.0, 1.0, 1.0, 0.7 * (1.0 - sl)), 4.0)
			_case(c, p, PI * 0.5, cols[i], 1.0)
			if d - air < 0.25:
				IntroKit.puff(c, land + Vector2(0.0, -6.0), 26.0 * (1.0 - (d - air) * 4.0), 1.0 - (d - air) * 4.0)


# the announcement: two notes, ringing out of the sign's speaker
static func _bing_bong(c: CanvasItem, t: float) -> void:
	for i in range(2):
		var t0 := 1.25 + float(i) * 0.22
		var f := Anim.span(t, t0, t0 + 0.6)
		if f <= 0.0 or f >= 1.0:
			continue
		var at := Vector2(604.0, 176.0)
		for s: float in [-1.0, 1.0]:
			c.draw_arc(at, 30.0 + f * 80.0 + float(i) * 14.0, -0.6 if s > 0.0 else PI - 0.6, 0.6 if s > 0.0 else PI + 0.6, 12, Color(INK, 1.0 - f), 6.0)


# The squad, side on, running right; the lead officer's feet at `lead_x`.
# Bodies first, then what they hold over all of them, so nothing is lost
# behind the next one along. They are the walk's five
# (entities/aeroport_threat.gd).
static func _squad(c: CanvasItem, t: float, t_real: float, lead_x: float) -> void:
	var held := []
	for i in range(SQUAD.size()):
		var st: Array = SQUAD[i]
		var far: bool = st[2]
		var k := AS_K * (0.88 if far else 1.0)
		var feet := FEET - (18.0 if far else 0.0)
		var x := lead_x + float(st[1])
		var pose := _pose(t_real + float(i) * 0.37, st[3], st[4])
		pose["reach"] = 1.0
		var hand := IntroKit.human(c, Vector2(x, feet), k, 1.0, Vector2.ONE, pose, 0.0, feet)
		_cap(c, Vector2(x, feet), k)
		if String(st[0]) == "whistle" or String(st[0]) == "megaphone":
			_mouth_item(c, String(st[0]), Vector2(x, feet), k, t_real + float(i))
		held.append([String(st[0]), hand, t_real + float(i), k])
	for h: Array in held:
		_item(c, h[0], h[1], h[2], h[3])


static func _pose(t: float, skin: Color, vest: bool) -> Dictionary:
	return {
		"stride": t * 13.0, "stride_amp": 1.0, "phone": 0.0, "lean": 0.18, "head": -0.1,
		"skin": skin, "shirt": HIVIS if vest else NAVY, "trousers": NAVY, "hair": NAVY, "shoe": INK,
	}


# where an officer's face is, their feet at `at` (the lean is _pose's)
static func _face(at: Vector2, k: float) -> Vector2:
	return at + (Vector2.UP.rotated(0.18) * 94.0 + Vector2(0.0, -98.0) + Vector2(12.0, 6.0)) * k


# the peaked cap with its badge, and the mirrored glasses under the peak
static func _cap(c: CanvasItem, at: Vector2, k: float) -> void:
	var f := _face(at, k)
	c.draw_colored_polygon(PackedVector2Array([f + Vector2(-26, -14) * k, f + Vector2(14, -16) * k, f + Vector2(34, -10) * k,
		f + Vector2(14, -22) * k, f + Vector2(8, -36) * k, f + Vector2(-22, -34) * k]), INK)
	c.draw_colored_polygon(PackedVector2Array([f + Vector2(-23, -16) * k, f + Vector2(12, -19) * k, f + Vector2(6, -33) * k, f + Vector2(-20, -31) * k]), NAVY)
	c.draw_circle(f + Vector2(2, -25) * k, 4.0 * k, Color(0.96, 0.82, 0.30))
	c.draw_colored_polygon(IntroKit.rrect(Rect2(f + Vector2(-2, -13) * k, Vector2(20, 10) * k), 3.0 * k), INK)
	c.draw_line(f + Vector2(3, -9) * k, f + Vector2(13, -11) * k, Color(0.60, 0.84, 0.96), 2.4 * k)


# what goes to the mouth: the whistle and its shrill, the loudhailer and its roar
static func _mouth_item(c: CanvasItem, item: String, at: Vector2, k: float, t: float) -> void:
	var m := _face(at, k) + Vector2(14, 6) * k
	var pf := fposmod(t * 5.0, 1.0)
	if item == "whistle":
		c.draw_colored_polygon(IntroKit.rrect(Rect2(m - Vector2(2, 5) * k, Vector2(16, 10) * k), 4.0 * k), Color(0.82, 0.84, 0.88))
		for i in range(3):
			var d := Vector2.from_angle((float(i) - 1.0) * 0.5 - 0.3)
			c.draw_line(m + d * (22.0 + pf * 16.0) * k, m + d * (36.0 + pf * 28.0) * k, Color(INK, 1.0 - pf), 4.0 * k)
	else:
		c.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -8) * k, m + Vector2(56, -34) * k, m + Vector2(62, 30) * k, m + Vector2(0, 8) * k]), INK)
		c.draw_colored_polygon(PackedVector2Array([m + Vector2(4, -5) * k, m + Vector2(52, -27) * k, m + Vector2(56, 23) * k, m + Vector2(4, 5) * k]), Color(0.92, 0.93, 0.95))
		c.draw_colored_polygon(PackedVector2Array([m + Vector2(52, -30) * k, m + Vector2(62, -34) * k, m + Vector2(68, 30) * k, m + Vector2(56, 26) * k]), CASE_RED)
		for i in range(3):
			var f := fposmod(pf + float(i) / 3.0, 1.0)
			c.draw_arc(m + Vector2(60, -2) * k, (26.0 + f * 70.0) * k, -0.7, 0.7, 10, Color(INK, 1.0 - f), 5.0 * k)


# what one of them holds out, from their hand, side on, facing right
static func _item(c: CanvasItem, item: String, hand: Vector2, t: float, k: float) -> void:
	match item:
		"crate":
			crate(c, hand + Vector2(70.0, 6.0) * k, k, t)
		"net":
			_net(c, hand, t, k)
		"wand":
			var a := 0.2 + sin(t * 7.0) * 0.35
			var tip := hand + Vector2.from_angle(a) * 110.0 * k
			c.draw_line(hand - Vector2.from_angle(a) * 14.0 * k, tip, INK, 20.0 * k)
			c.draw_line(hand + Vector2.from_angle(a) * 26.0 * k, tip - Vector2.from_angle(a) * 4.0 * k, BEACON, 10.0 * k)
			var bl := fposmod(t * 3.0, 1.0)
			c.draw_circle(tip, 9.0 * k, Color(0.98, 0.20, 0.16))
			c.draw_arc(tip, (16.0 + bl * 34.0) * k, 0.0, TAU, 20, Color(0.98, 0.20, 0.16, 1.0 - bl), 4.0 * k)
		"whistle":
			# the flat of the hand: STOP
			c.draw_colored_polygon(IntroKit.rrect(Rect2(hand + Vector2(-4, -30) * k, Vector2(20, 40) * k), 7.0 * k), INK)
			c.draw_colored_polygon(IntroKit.rrect(Rect2(hand + Vector2(-1, -27) * k, Vector2(14, 34) * k), 5.0 * k), Color(0.96, 0.96, 0.94))
			return
	c.draw_circle(hand, 6.5 * k, Color(0.96, 0.96, 0.94))


# The travel crate, side on, its open mouth to the right at `mouth`: grey
# shell with its vent slots and a carry handle, the dark inside, the wire door
# swung wide, a LIVE ANIMAL sticker with its two arrows up. Where dogs go when
# dogs fly.
static func crate(c: CanvasItem, mouth: Vector2, k: float, t: float) -> void:
	var r := Rect2(mouth + Vector2(-130, -62) * k, Vector2(130, 112) * k)
	c.draw_colored_polygon(IntroKit.rrect(r.grow(4.0 * k), 16.0 * k), INK)
	c.draw_colored_polygon(IntroKit.rrect(r, 13.0 * k), Color(0.74, 0.76, 0.80))
	c.draw_rect(Rect2(r.position + Vector2(0, 50) * k, Vector2(130, 8) * k), Color(0.52, 0.55, 0.60))
	c.draw_colored_polygon(IntroKit.rrect(Rect2(r.position + Vector2(36, -16) * k, Vector2(54, 20) * k), 8.0 * k), INK)
	for i in range(4):
		c.draw_colored_polygon(IntroKit.rrect(Rect2(r.position + Vector2(14.0 + float(i) * 20.0, 12.0) * k, Vector2(12, 26) * k), 4.0 * k), Color(0.20, 0.22, 0.26))
	# the sticker
	c.draw_rect(Rect2(r.position + Vector2(18, 66) * k, Vector2(70, 34) * k), BEACON)
	for i in range(2):
		var ap := r.position + Vector2(36.0 + float(i) * 34.0, 84.0) * k
		c.draw_line(ap + Vector2(0, 10) * k, ap + Vector2(0, -6) * k, INK, 5.0 * k)
		c.draw_colored_polygon(PackedVector2Array([ap + Vector2(-8, -4) * k, ap + Vector2(8, -4) * k, ap + Vector2(0, -14) * k]), INK)
	# the mouth, and the dark in it
	c.draw_colored_polygon(MillieSide.ellipse(mouth + Vector2(-6, -6) * k, Vector2(20, 56) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(mouth + Vector2(-8, -6) * k, Vector2(14, 48) * k), Color(0.03, 0.03, 0.05))
	# the door, swinging on its hinge
	var sw := 0.5 + sin(t * 7.0) * 0.35
	var hinge := mouth + Vector2(-2, -62) * k
	var tip := hinge + Vector2.from_angle(-sw) * 100.0 * k
	var down := Vector2.from_angle(-sw).orthogonal() * 16.0 * k
	c.draw_line(hinge, tip, INK, 7.0 * k)
	for i in range(1, 6):
		var q := hinge.lerp(tip, float(i) / 5.0)
		c.draw_line(q - down * 0.2, q + down * 3.0 * (1.0 - absf(float(i) - 3.0) / 6.0), Color(0.84, 0.86, 0.90), 3.0 * k)


static func _net(c: CanvasItem, hand: Vector2, t: float, k: float) -> void:
	var sway := sin(t * 6.0) * 0.12
	var tip := hand + Vector2.from_angle(-0.95 + sway) * 200.0 * k
	c.draw_line(hand, tip, INK, 9.0 * k)
	c.draw_line(hand, tip, Color(0.56, 0.40, 0.24), 5.0 * k)
	var hoop := tip + Vector2.from_angle(-0.95 + sway) * 40.0 * k
	c.draw_colored_polygon(MillieSide.ellipse(hoop + Vector2(20.0, 40.0) * k, Vector2(22.0, 46.0) * k), Color(0.94, 0.96, 0.92, 0.5))
	for i in range(5):
		var f := (float(i) + 0.5) / 5.0
		c.draw_line(hoop + Vector2(-8.0, lerpf(-36.0, 36.0, f)) * k, hoop + Vector2(26.0, lerpf(10.0, 80.0, f)) * k, Color(1, 1, 1, 0.8), 1.5 * k)
	c.draw_colored_polygon(MillieSide.ellipse(hoop, Vector2(16.0, 44.0) * k), INK)
	c.draw_colored_polygon(MillieSide.ellipse(hoop, Vector2(10.0, 38.0) * k), Color(0.94, 0.96, 0.92, 0.55))


# the card: the hall gone amber behind RUN!, the crate's open mouth filling
# the left of it, cases in the air, the net coming down over the word
static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.30, 0.52, 0.80), Color(0.98, 0.74, 0.26))
	var d := t - TITLE_AT
	# the glass wall's posts, raked by speed
	for i in range(9):
		var x := fposmod(float(i) * 190.0 - d * 900.0, 1700.0) - 200.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, 0.0), Vector2(x + 18.0, 0.0), Vector2(x - 120.0, 824.0), Vector2(x - 138.0, 824.0)]), Color(1.0, 1.0, 1.0, 0.16))
	# cases, tumbling across
	var cols: Array[Color] = [CASE_RED, CASE_BLUE, CASE_PINK, CASE_GREEN, CASE_YELLOW]
	for i in range(5):
		var f := fposmod(d * 0.7 + float(i) * 0.23, 1.0)
		var at := Vector2(420.0 + float(i) * 190.0 + f * 160.0, 560.0 - sin(f * PI) * (220.0 + float(i % 2) * 120.0) + float(i % 3) * 40.0)
		_case(c, at, f * 9.0 + float(i), cols[i], 1.3)
	# the crate, mouth first, and the gloved hands shoving it
	var bob := sin(t * 18.0) * 5.0
	var mouth := Vector2(470.0 + d * 70.0, 500.0 + bob)
	crate(c, mouth, 3.6, t)
	c.draw_circle(mouth + Vector2(-330.0, -160.0), 46.0, INK)
	c.draw_circle(mouth + Vector2(-330.0, -160.0), 40.0, Color(0.96, 0.96, 0.94))
	# the net, swung in over the word
	var hoop := Vector2(1010.0 - d * 40.0, 150.0 + sin(d * 6.0) * 20.0)
	c.draw_line(Vector2(380.0 + d * 50.0, 60.0), hoop, INK, 16.0)
	c.draw_line(Vector2(380.0 + d * 50.0, 60.0), hoop, Color(0.56, 0.40, 0.24), 9.0)
	FilmKit.slam(c, t, "RUN!", Vector2(900, 330))
	c.draw_arc(hoop + Vector2(90.0, 30.0), 150.0, 0.0, TAU, 40, INK, 18.0)
	c.draw_arc(hoop + Vector2(90.0, 30.0), 150.0, 0.0, TAU, 40, Color(0.56, 0.40, 0.24), 10.0)
	for i in range(-3, 4):
		var off := float(i) * 40.0
		var hl := sqrt(maxf(0.0, 145.0 * 145.0 - off * off))
		c.draw_line(hoop + Vector2(90.0 + off, 30.0 - hl), hoop + Vector2(90.0 + off, 30.0 + hl), Color(1, 1, 1, 0.55), 3.0)
		c.draw_line(hoop + Vector2(90.0 - hl, 30.0 + off), hoop + Vector2(90.0 + hl, 30.0 + off), Color(1, 1, 1, 0.55), 3.0)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
