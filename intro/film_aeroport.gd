class_name FilmAeroport
extends RefCounted

# L'Aeroport's chase film, "Terminal Run": the telegraph to run as the walk
# turns for home (systems/home_chase.gd plays it through intro/film_player.gd).
# Terminal 1 concourse, side on: panoramic glass windows overlooking the tarmac
# with the tail fin of an airliner, departure matrix signs, and the moving
# walkway handrail. The two of them heading for the exit, your human checking
# their phone boarding pass. An airport chime: ding-dong-ding! Her ears perk up
# and she looks back. Around a polished pillar squeals the Security Cart Buggy
# on two wheels, amber roof beacon strobing, siren chirping, and an officer
# shouting into a megaphone! A push in on her face. She spins, digs in and bolts;
# the leash snaps taut, your human is yanked off after her, and RUN! slams in
# with the buggy's grille and a skidding red suitcase filling the frame.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.12, 0.16, 0.22)
const FEET := 640.0              # the concourse floor
const WALL_FOOT := 560.0         # glass window base
const CART_START_X := -120.0
const BUGGY_AT := 2.2            # buggy rounds the pillar
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT

# Colors
const FLOOR_LIGHT := Color(0.88, 0.90, 0.94)
const FLOOR_DARK := Color(0.80, 0.83, 0.88)
const WINDOW_FRAME := Color(0.40, 0.44, 0.50)
const WINDOW_GLASS := Color(0.70, 0.84, 0.92, 0.50)
const APRON_TARMAC := Color(0.35, 0.38, 0.40)
const FIN_WHITE := Color(0.96, 0.97, 0.98)
const FIN_BLUE := Color(0.12, 0.26, 0.56)
const FIN_RED := Color(0.85, 0.18, 0.15)
const PILLAR_STEEL := Color(0.55, 0.58, 0.65)
const BUGGY_WHITE := Color(0.95, 0.96, 0.98)
const BUGGY_BLUE := Color(0.12, 0.28, 0.55)
const BEACON_AMBER := Color(1.0, 0.75, 0.15)
const SUITCASE_RED := Color(0.85, 0.18, 0.15)
const SUITCASE_BLUE := Color(0.18, 0.40, 0.85)

const CUES := [
	[1.20, "chime", 1.0, -4.0],
	[BUGGY_AT, "whoop", 1.4, -6.0],
	[2.70, "van_horn", 1.1, -8.0],
	[3.40, "whoop", 1.6, -6.0],
	[4.40, "crack", 1.4, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "crack", 0.6, -3.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1520.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.5, 660.0, "io"], [2.2, 280.0, "io"], [3.9, 420.0, "io"], [4.2, 780.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 450.0, "io"], [3.9, 460.0], [4.2, 530.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.5, 1.25, "io"], [2.2, 0.95, "io"], [3.9, 1.02, "io"], [4.2, 1.75, "io"]])
	return [Vector2(x, y), z]


static func buggy_x(t: float) -> float:
	return Anim.k(t, [[BUGGY_AT, CART_START_X], [3.9, 140.0, "out"], [BOLT_AT, 280.0], [TITLE_AT, 1420.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_terminal_concourse(c, t_real)
	if t_real >= BUGGY_AT:
		_security_cart(c, buggy_x(t_real), t_real)
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


static func _terminal_concourse(c: CanvasItem, t: float) -> void:
	# Outside tarmac and sky
	c.draw_rect(Rect2(-1600, -900, 4600, WALL_FOOT + 900.0), Color(0.75, 0.84, 0.92))
	c.draw_rect(Rect2(-1600, WALL_FOOT - 180.0, 4600, 180.0), APRON_TARMAC)

	# Tail fin of parked airliner outside
	var fin := PackedVector2Array([
		Vector2(20.0, WALL_FOOT - 60.0),
		Vector2(180.0, WALL_FOOT - 340.0),
		Vector2(260.0, WALL_FOOT - 340.0),
		Vector2(140.0, WALL_FOOT - 60.0),
	])
	c.draw_colored_polygon(fin, FIN_WHITE)
	var stripe := PackedVector2Array([
		Vector2(140.0, WALL_FOOT - 260.0),
		Vector2(180.0, WALL_FOOT - 340.0),
		Vector2(230.0, WALL_FOOT - 340.0),
		Vector2(190.0, WALL_FOOT - 260.0),
	])
	c.draw_colored_polygon(stripe, FIN_RED)

	# Floor
	c.draw_rect(Rect2(-1600, WALL_FOOT, 4600, 600.0), FLOOR_LIGHT)
	c.draw_rect(Rect2(-1600, WALL_FOOT + 70.0, 4600, 40.0), FLOOR_DARK)

	# Window frames and mullions
	c.draw_line(Vector2(-1600, WALL_FOOT), Vector2(3000, WALL_FOOT), WINDOW_FRAME, 6.0)
	c.draw_line(Vector2(-1600, WALL_FOOT - 320.0), Vector2(3000, WALL_FOOT - 320.0), WINDOW_FRAME, 4.0)
	var wx := -1400.0
	while wx < 3000.0:
		c.draw_line(Vector2(wx, WALL_FOOT - 320.0), Vector2(wx, WALL_FOOT), WINDOW_FRAME, 4.0)
		wx += 240.0

	# Massive structural pillar
	c.draw_rect(Rect2(-80.0, -900.0, 70.0, WALL_FOOT + 900.0), PILLAR_STEEL)
	c.draw_rect(Rect2(-80.0, WALL_FOOT - 20.0, 70.0, 20.0), Color(0.35, 0.38, 0.44))

	# Moving walkway handrail in background
	c.draw_rect(Rect2(-1600, FEET - 60.0, 4600, 8.0), Color(0.12, 0.12, 0.14))
	c.draw_rect(Rect2(-1600, FEET - 52.0, 4600, 40.0), Color(0.65, 0.80, 0.88, 0.40))


static func _security_cart(c: CanvasItem, cx: float, t: float) -> void:
	var cy := FEET - 20.0
	var bob := sin(t * 22.0) * 2.0

	# Four wheels
	c.draw_circle(Vector2(cx - 50.0, cy), 18.0, Color(0.12, 0.12, 0.14))
	c.draw_circle(Vector2(cx + 50.0, cy), 18.0, Color(0.12, 0.12, 0.14))
	c.draw_circle(Vector2(cx - 50.0, cy), 8.0, Color(0.6, 0.6, 0.6))
	c.draw_circle(Vector2(cx + 50.0, cy), 8.0, Color(0.6, 0.6, 0.6))

	# Buggy chassis body
	var body := PackedVector2Array([
		Vector2(cx - 70.0, cy - 14.0),
		Vector2(cx - 70.0, cy - 50.0),
		Vector2(cx - 20.0, cy - 50.0),
		Vector2(cx + 10.0, cy - 70.0),
		Vector2(cx + 65.0, cy - 50.0),
		Vector2(cx + 70.0, cy - 14.0),
	])
	c.draw_colored_polygon(body, BUGGY_WHITE)
	c.draw_rect(Rect2(cx - 70.0, cy - 36.0, 140.0, 12.0), BUGGY_BLUE)

	# Driver
	c.draw_circle(Vector2(cx - 10.0, cy - 74.0 + bob), 14.0, Color(0.15, 0.20, 0.32))
	c.draw_rect(Rect2(cx - 22.0, cy - 60.0 + bob, 24.0, 22.0), Color(0.92, 0.94, 0.20))

	# Roof roll-bar & amber strobe beacon
	c.draw_line(Vector2(cx - 40.0, cy - 50.0), Vector2(cx - 40.0, cy - 110.0), Color(0.3, 0.3, 0.3), 4.0)
	c.draw_line(Vector2(cx + 20.0, cy - 70.0), Vector2(cx + 20.0, cy - 110.0), Color(0.3, 0.3, 0.3), 4.0)
	c.draw_line(Vector2(cx - 50.0, cy - 110.0), Vector2(cx + 30.0, cy - 110.0), BUGGY_WHITE, 6.0)

	var flash := 0.6 + 0.4 * sin(t * 18.0)
	c.draw_circle(Vector2(cx - 10.0, cy - 118.0), 9.0, BEACON_AMBER)
	c.draw_circle(Vector2(cx - 10.0, cy - 118.0), 22.0, Color(1.0, 0.65, 0.10, 0.35 * flash))

	# Tumbling luggage skidding behind
	var skid_x := cx - 110.0
	c.draw_rect(Rect2(skid_x, cy - 12.0, 24.0, 16.0), SUITCASE_RED)
	c.draw_line(Vector2(skid_x - 30.0, cy), Vector2(skid_x + 20.0, cy), Color(1.0, 0.8, 0.2, 0.5), 2.0)


static func _title(c: CanvasItem, t: float) -> void:
	# Card background gradient
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.94, 0.96, 0.98), Color(0.35, 0.55, 0.75))
	var d := t - TITLE_AT

	# Skidding suitcase sliding into foreground
	var sx: float = 80.0 + d * 180.0
	var sy := 520.0 - sin(d * 8.0) * 20.0
	c.draw_rect(Rect2(sx, sy, 110.0, 74.0), SUITCASE_RED)
	c.draw_rect(Rect2(sx + 20.0, sy + 15.0, 70.0, 44.0), Color(0.70, 0.12, 0.10))
	c.draw_rect(Rect2(sx + 95.0, sy + 25.0, 24.0, 24.0), Color(0.2, 0.2, 0.2))

	# Buggy bumper roaring from left
	var bx: float = -180.0 + d * 220.0
	c.draw_rect(Rect2(bx, 280.0, 260.0, 140.0), BUGGY_WHITE)
	c.draw_rect(Rect2(bx, 340.0, 260.0, 24.0), BUGGY_BLUE)
	c.draw_circle(Vector2(bx + 180.0, 260.0), 28.0, BEACON_AMBER)
	c.draw_circle(Vector2(bx + 180.0, 260.0), 55.0, Color(1.0, 0.65, 0.15, 0.40))

	FilmKit.slam(c, t, "RUN!", Vector2(880, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
