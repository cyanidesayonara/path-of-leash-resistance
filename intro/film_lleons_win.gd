class_name FilmLleonsWin
extends RefCounted

# The El Port victory film, "Els Lleons del Port":
# The celebratory payoff scene after settling the twin bronze lions of the
# Columbus Monument (docs/BOSSES.md).
#
# A calm sunset at Portal de la Pau by Port Vell, side on:
# The harbor basin behind, moored sailboats, the Columbus column.
# The two bronze lions sit side by side on their corner plinths, eyes half-closed
# in peaceful contentment, glowing soft amber.
# The dog barks a cheerful farewell, and your human catches up, smiling warmly.
# Golden sunset glimmers across the Mediterranean water, and the title card slams in:
# ELS LLEONS! / GUARDIANS DEL PORT / EL PORT IS YOURS.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.85, 0.52, 0.38)
const FEET := 640.0
const PLINTH_L_X := 180.0
const PLINTH_R_X := 440.0
const PLINTH_TOP := FEET - 120.0

const BOOP_AT := 1.2
const PURR_AT := 1.8
const WALK_OFF_AT := 2.5
const TITLE_AT := FilmKit.TITLE_AT

const BRONZE_PATINA := Color(0.24, 0.44, 0.38)
const BRONZE_DARK := Color(0.26, 0.22, 0.16)
const BRONZE_LIT := Color(0.68, 0.54, 0.28)
const BRONZE_SHINE := Color(0.86, 0.72, 0.38)
const EYE_AMBER := Color(0.96, 0.74, 0.18)
const PLINTH := Color(0.65, 0.62, 0.58)
const WATER := Color(0.18, 0.32, 0.46)

const CUES := [
	[0.2, "whoop", 1.0, -6.0],
	[BOOP_AT, "bark", 1.2, -2.0],
	[BOOP_AT + 0.05, "star", 1.1, -2.0],
	[PURR_AT, "gat_purr", 0.9, -4.0],
	[TITLE_AT, "lion_roar", 0.95, -2.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	var x: float = Anim.k(t, [[0.0, 360.0], [2.0, 480.0, "io"], [3.8, 560.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 440.0], [2.0, 460.0, "io"], [3.8, 470.0]])
	var z: float = Anim.k(t, [[0.0, 1.1], [2.0, 1.0, "io"], [3.8, 0.95, "io"]])
	return [Vector2(x, y), z]


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_harbor_backdrop(c, t_real)
	_plinths(c, t)

	# Seated calm lions on plinths
	_draw_sitting_lion(c, Vector2(PLINTH_L_X, PLINTH_TOP), true)
	_draw_sitting_lion(c, Vector2(PLINTH_R_X, PLINTH_TOP), false)

	# Pair strolling happily
	var dog_x := Anim.k(t, [[0.0, 320.0], [BOOP_AT, 320.0], [WALK_OFF_AT, 580.0, "io"], [TITLE_AT, 780.0]])
	var human_x := Anim.k(t, [[0.0, 220.0], [WALK_OFF_AT, 460.0, "io"], [TITLE_AT, 660.0]])
	FilmKit.pair(c, t_real, Vector2(dog_x, FEET), Vector2(human_x, FEET), false, false, "dusk")


static func _harbor_backdrop(c: CanvasItem, _t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200.0, -100.0, 1680.0, 600.0), Color(0.92, 0.48, 0.35), Color(0.38, 0.22, 0.42))
	c.draw_rect(Rect2(-200.0, 460.0, 1680.0, 100.0), WATER)
	c.draw_rect(Rect2(280.0, 180.0, 80.0, 300.0), Color(0.20, 0.18, 0.22, 0.75))
	c.draw_circle(Vector2(320.0, 180.0), 30.0, Color(0.20, 0.18, 0.22, 0.75))
	c.draw_rect(Rect2(-200.0, FEET - 40.0, 1680.0, 300.0), Color(0.48, 0.40, 0.32))


static func _plinths(c: CanvasItem, _t: float) -> void:
	for px in [PLINTH_L_X, PLINTH_R_X]:
		var r := Rect2(px - 60.0, PLINTH_TOP, 120.0, FEET - PLINTH_TOP - 40.0)
		c.draw_rect(r, PLINTH)
		c.draw_rect(Rect2(px - 66.0, PLINTH_TOP, 132.0, 18.0), Color(0.55, 0.52, 0.48))


static func _draw_sitting_lion(c: CanvasItem, at: Vector2, is_left: bool) -> void:
	var side_scale := 1.0 if is_left else -1.0
	# Hindquarters / Sitting base
	c.draw_circle(at + Vector2(-side_scale * 12.0, -22.0), 26.0, BRONZE_DARK)
	c.draw_circle(at + Vector2(-side_scale * 12.0, -22.0), 22.0, BRONZE_PATINA)
	# Mane
	var mane_pos := at + Vector2(side_scale * 16.0, -36.0)
	c.draw_circle(mane_pos, 26.0, BRONZE_DARK)
	c.draw_circle(mane_pos, 22.0, BRONZE_PATINA)
	# Head
	var head_pos := mane_pos + Vector2(side_scale * 10.0, -4.0)
	c.draw_circle(head_pos, 16.0, BRONZE_LIT)
	# Peaceful closed eye lines
	c.draw_line(head_pos + Vector2(side_scale * 3.0, -4.0), head_pos + Vector2(side_scale * 9.0, -3.0), BRONZE_DARK, 2.0)
	# Snout & Nose
	c.draw_circle(head_pos + Vector2(side_scale * 13.0, 3.0), 6.5, BRONZE_DARK)
	c.draw_circle(head_pos + Vector2(side_scale * 15.0, 2.0), 3.0, BRONZE_SHINE)


static func _title(c: CanvasItem, t: float) -> void:
	FilmKit.title_card(c, t, "ELS LLEONS", "The Twin Guardians of El Port")
