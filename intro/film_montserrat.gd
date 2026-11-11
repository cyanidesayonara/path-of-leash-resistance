class_name FilmMontserrat
extends RefCounted

# Montserrat's chase film, "The Horns of Montserrat": the telegraph to run
# as the walk turns for home (systems/home_chase.gd plays it through intro/film_player.gd).
# The serrated mountain spires of Montserrat, side on: sheer conglomerate rock
# needles rising against the high morning blue sky, stunted mountain pines,
# and the monastery terrace balustrade. The two of them heading down the trail,
# your human framing a selfie with the mountain pinnacles behind.
#
# A sharp mountain echo: *BLEAT!* (1.20 s). Her ears perk up and she looks back.
# High up on a rock pinnacle, an alpha wild mountain goat stamps its hooves,
# lowers its massive backward-curved horns, and bleats again!
# It leaps down the rocky crags, head-butting a loose boulder down the trail!
# A push in on her face. She spins, digs in and bolts; the leash snaps taut,
# your human is yanked off after her, and RUN! slams in with the charging goat's
# horns and a bouncing rock face filling the frame.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.12, 0.16, 0.22)
const FEET := 640.0              # the trail terrace
const WALL_FOOT := 560.0         # rock face base
const GOAT_START_X := -120.0
const GOAT_AT := 2.2             # goat leaps into view
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT

# Colors
const SKY_BLUE := Color(0.65, 0.78, 0.90)
const MOUNTAIN_HAZE := Color(0.55, 0.62, 0.72)
const ROCK_BASE := Color(0.72, 0.65, 0.55)
const ROCK_DARK := Color(0.50, 0.44, 0.36)
const ROCK_LIGHT := Color(0.85, 0.78, 0.68)
const PINE_GREEN := Color(0.24, 0.38, 0.22)
const GOAT_FUR := Color(0.58, 0.46, 0.36)
const GOAT_BELLY := Color(0.82, 0.76, 0.68)
const GOAT_HORN := Color(0.28, 0.26, 0.24)
const GOAT_EYE := Color(0.95, 0.85, 0.20)
const BOULDER_COL := Color(0.68, 0.62, 0.54)

const CUES := [
	[1.20, "bleat", 1.0, -4.0],
	[GOAT_AT, "bleat", 1.1, -5.0],
	[2.80, "crack", 1.0, -8.0],
	[3.60, "bleat", 1.2, -6.0],
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
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 430.0, "io"], [3.9, 450.0], [4.2, 530.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.5, 1.25, "io"], [2.2, 0.95, "io"], [3.9, 1.02, "io"], [4.2, 1.75, "io"]])
	return [Vector2(x, y), z]


static func goat_x(t: float) -> float:
	return Anim.k(t, [[GOAT_AT, GOAT_START_X], [3.9, 160.0, "out"], [BOLT_AT, 300.0], [TITLE_AT, 1420.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_montserrat_backdrop(c, t_real)
	if t_real >= GOAT_AT:
		_charging_goat(c, goat_x(t_real), t_real)
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


static func _montserrat_backdrop(c: CanvasItem, _t: float) -> void:
	# Sky
	c.draw_rect(Rect2(-1600, -900, 4600, WALL_FOOT + 900.0), SKY_BLUE)

	# Distant mountain haze
	var haze := PackedVector2Array([
		Vector2(-400.0, WALL_FOOT),
		Vector2(-100.0, WALL_FOOT - 320.0),
		Vector2(200.0, WALL_FOOT - 260.0),
		Vector2(500.0, WALL_FOOT - 380.0),
		Vector2(800.0, WALL_FOOT - 290.0),
		Vector2(1200.0, WALL_FOOT - 350.0),
		Vector2(1600.0, WALL_FOOT),
	])
	c.draw_colored_polygon(haze, MOUNTAIN_HAZE)

	# Conglomerate rock needle spires (agulles) in middle ground
	var needle_1 := PackedVector2Array([
		Vector2(40.0, WALL_FOOT),
		Vector2(90.0, WALL_FOOT - 420.0),
		Vector2(140.0, WALL_FOOT - 450.0),
		Vector2(190.0, WALL_FOOT - 410.0),
		Vector2(230.0, WALL_FOOT),
	])
	c.draw_colored_polygon(needle_1, ROCK_BASE)
	c.draw_polyline(needle_1, ROCK_LIGHT, 4.0)

	var needle_2 := PackedVector2Array([
		Vector2(320.0, WALL_FOOT),
		Vector2(370.0, WALL_FOOT - 380.0),
		Vector2(410.0, WALL_FOOT - 410.0),
		Vector2(450.0, WALL_FOOT - 370.0),
		Vector2(490.0, WALL_FOOT),
	])
	c.draw_colored_polygon(needle_2, ROCK_DARK)

	# Mountain trail floor
	c.draw_rect(Rect2(-1600, WALL_FOOT, 4600, FEET - WALL_FOOT + 200.0), ROCK_BASE)
	c.draw_rect(Rect2(-1600, FEET - 6.0, 4600, 12.0), ROCK_LIGHT)

	# Stunted mountain pines
	for px: float in [-120.0, 260.0, 750.0]:
		c.draw_line(Vector2(px, WALL_FOOT), Vector2(px, WALL_FOOT - 60.0), Color(0.4, 0.28, 0.18), 6.0)
		c.draw_circle(Vector2(px, WALL_FOOT - 70.0), 22.0, PINE_GREEN)
		c.draw_circle(Vector2(px + 10.0, WALL_FOOT - 80.0), 18.0, PINE_GREEN.lightened(0.08))


static func _charging_goat(c: CanvasItem, cx: float, t: float) -> void:
	var leap_phase := fmod(t * 8.0, TAU)
	var cy: float = FEET - 40.0 - absf(sin(leap_phase)) * 26.0

	# Shadow
	c.draw_circle(Vector2(cx, FEET), 28.0, Color(0.0, 0.0, 0.0, 0.3))

	# Legs galloping
	var leg_swing := sin(leap_phase) * 16.0
	c.draw_line(Vector2(cx - 18.0, cy + 10.0), Vector2(cx - 24.0 + leg_swing, FEET), Color(0.3, 0.2, 0.15), 5.0)
	c.draw_line(Vector2(cx + 18.0, cy + 10.0), Vector2(cx + 24.0 - leg_swing, FEET), Color(0.3, 0.2, 0.15), 5.0)

	# Body
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 32.0, cy + 6.0),
		Vector2(cx - 24.0, cy - 20.0),
		Vector2(cx + 24.0, cy - 16.0),
		Vector2(cx + 34.0, cy + 10.0),
	]), GOAT_FUR)
	c.draw_circle(Vector2(cx + 4.0, cy + 4.0), 16.0, GOAT_BELLY)

	# Head and Beard
	var head_pos := Vector2(cx + 36.0, cy - 22.0)
	c.draw_circle(head_pos, 14.0, GOAT_FUR)
	c.draw_circle(head_pos + Vector2(10.0, 4.0), 8.0, GOAT_BELLY)
	c.draw_line(head_pos + Vector2(8.0, 10.0), head_pos + Vector2(6.0, 22.0), GOAT_BELLY, 3.0) # beard

	# Eye
	c.draw_circle(head_pos + Vector2(4.0, -2.0), 3.0, GOAT_EYE)

	# Giant curved horn
	var horn := PackedVector2Array([
		head_pos + Vector2(-2.0, -8.0),
		head_pos + Vector2(-18.0, -38.0),
		head_pos + Vector2(-36.0, -52.0),
		head_pos + Vector2(-30.0, -48.0),
		head_pos + Vector2(-12.0, -32.0),
		head_pos + Vector2(2.0, -8.0),
	])
	c.draw_colored_polygon(horn, GOAT_HORN)

	# Bouncing rock kicking up dust
	var rock_x := cx + 70.0
	var rock_y := FEET - 14.0 - absf(sin(t * 12.0)) * 14.0
	c.draw_circle(Vector2(rock_x, rock_y), 12.0, BOULDER_COL)
	c.draw_circle(Vector2(rock_x - 3.0, rock_y - 3.0), 6.0, Color(0.8, 0.75, 0.7))


static func _title(c: CanvasItem, t: float) -> void:
	# Card background gradient
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 720.0 + 104.0), Color(0.85, 0.78, 0.68), Color(0.45, 0.38, 0.30))
	var d := t - TITLE_AT

	# Rolling boulder smashing into foreground
	var rx: float = 90.0 + d * 190.0
	var ry := 500.0 - sin(d * 8.0) * 22.0
	c.draw_circle(Vector2(rx + 40.0, ry + 20.0), 45.0, Color(0.0, 0.0, 0.0, 0.35))
	c.draw_circle(Vector2(rx + 40.0, ry + 20.0), 40.0, BOULDER_COL)
	c.draw_circle(Vector2(rx + 30.0, ry + 12.0), 24.0, ROCK_LIGHT)

	# Charging mountain goat horns roaring from left
	var gx: float = -160.0 + d * 230.0
	var gy := 360.0
	c.draw_circle(Vector2(gx + 120.0, gy), 55.0, GOAT_FUR)
	c.draw_circle(Vector2(gx + 160.0, gy - 20.0), 38.0, GOAT_BELLY)

	# Massive horns swept across the card
	var card_horn := PackedVector2Array([
		Vector2(gx + 140.0, gy - 30.0),
		Vector2(gx + 90.0, gy - 130.0),
		Vector2(gx + 20.0, gy - 170.0),
		Vector2(gx + 40.0, gy - 150.0),
		Vector2(gx + 110.0, gy - 110.0),
		Vector2(gx + 155.0, gy - 30.0),
	])
	c.draw_colored_polygon(card_horn, GOAT_HORN)

	FilmKit.slam(c, t, "RUN!", Vector2(880, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
