class_name FilmLleons
extends RefCounted

# El Port's film, "Els Lleons": the wake of the twin bronze lions of the
# Columbus Monument (docs/BOSSES.md), played as she first passes WAKE_Y
# (-4000.0) on El Port.
#
# Sunset at Portal de la Pau: Mediterranean harbor basin behind, the tall
# Columbus column silhouetted against the dusk sky. The pair walk in side-on.
# A metallic yawn creaks from the left lion; the right lion blinks open glowing
# amber eyes. They glance at each other, then focus their gaze down on the little dog.
# She plants herself boldly and barks. ELS LLEONS slams in!

const LENGTH := FilmKit.LENGTH
const BG := Color(0.85, 0.52, 0.38)     # dusk sunset orange/rose
const FEET := 640.0
const PLINTH_L_X := 120.0
const PLINTH_R_X := 420.0
const PLINTH_TOP := FEET - 120.0

const YAWN_AT := 1.70
const EYES_AT := 2.20
const TURN_AT := 2.80
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT

const BRONZE_PATINA := Color(0.24, 0.44, 0.38)
const BRONZE_DARK := Color(0.26, 0.22, 0.16)
const BRONZE_LIT := Color(0.68, 0.54, 0.28)
const BRONZE_SHINE := Color(0.86, 0.72, 0.38)
const EYE_AMBER := Color(0.96, 0.74, 0.18)
const PLINTH := Color(0.65, 0.62, 0.58)
const WATER := Color(0.18, 0.32, 0.46)
const INK := IntroKit.INK

const CUES := [
	[1.30, "gat_clang", 0.6, -10.0],
	[YAWN_AT, "lion_roar", 0.8, -4.0],
	[EYES_AT, "chime", 1.2, -6.0],
	[TURN_AT, "gat_clang", 0.9, -6.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.4, "bark", 1.1, -4.0],
	[TITLE_AT, "lion_roar", 1.0, -1.0],
]


static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		return [Vector2(380.0, 430.0), Anim.k(t, [[BOLT_AT, 1.0], [TITLE_AT, 0.92, "io"]])]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.5, 640.0, "io"], [2.0, 270.0, "io"], [3.8, 320.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 480.0], [2.0, 420.0, "io"], [3.8, 440.0]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.5, 1.25, "io"], [2.0, 0.95, "io"], [3.8, 1.05, "io"]])
	return [Vector2(x, y), z]


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	var t := Anim.twos(t_real)
	_harbor_backdrop(c, t_real)
	_plinths(c, t)

	var yawn := Anim.span(t, YAWN_AT, YAWN_AT + 0.5) * (1.0 - Anim.span(t, YAWN_AT + 0.6, YAWN_AT + 1.0))
	var eyes_open := Anim.span(t, EYES_AT, EYES_AT + 0.3)
	var turned := Anim.span(t, TURN_AT, TURN_AT + 0.4)

	# Draw side-on Left and Right Lions
	_draw_film_lion(c, Vector2(PLINTH_L_X, PLINTH_TOP), yawn, eyes_open, turned, true)
	_draw_film_lion(c, Vector2(PLINTH_R_X, PLINTH_TOP), 0.0, eyes_open, turned, false)

	# The pair
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


static func _harbor_backdrop(c: CanvasItem, _t: float) -> void:
	# Sunset gradient sky
	IntroKit.vgrad(c, Rect2(-200.0, -100.0, 1680.0, 600.0), Color(0.92, 0.48, 0.35), Color(0.38, 0.22, 0.42))
	# Distant sea horizon & masts
	c.draw_rect(Rect2(-200.0, 460.0, 1680.0, 100.0), WATER)
	# Columbus column base silhouette in background
	c.draw_rect(Rect2(240.0, 200.0, 80.0, 280.0), Color(0.20, 0.18, 0.22, 0.75))
	c.draw_circle(Vector2(280.0, 200.0), 30.0, Color(0.20, 0.18, 0.22, 0.75))
	# Boardwalk ground
	c.draw_rect(Rect2(-200.0, FEET - 40.0, 1680.0, 300.0), Color(0.48, 0.40, 0.32))


static func _plinths(c: CanvasItem, _t: float) -> void:
	for px in [PLINTH_L_X, PLINTH_R_X]:
		var r := Rect2(px - 60.0, PLINTH_TOP, 120.0, FEET - PLINTH_TOP - 40.0)
		c.draw_rect(r, PLINTH)
		c.draw_rect(Rect2(px - 66.0, PLINTH_TOP, 132.0, 18.0), Color(0.55, 0.52, 0.48))


static func _draw_film_lion(c: CanvasItem, at: Vector2, jaw: float, eye: float, turned: float, is_left: bool) -> void:
	var side_scale := 1.0 if is_left else -1.0
	# Body
	c.draw_circle(at + Vector2(-side_scale * 15.0, -28.0), 28.0, BRONZE_DARK)
	c.draw_circle(at + Vector2(-side_scale * 15.0, -28.0), 24.0, BRONZE_PATINA)
	# Mane
	var mane_pos := at + Vector2(side_scale * 18.0, -38.0)
	c.draw_circle(mane_pos, 26.0, BRONZE_DARK)
	c.draw_circle(mane_pos, 22.0, BRONZE_PATINA)
	# Head
	var head_pos := mane_pos + Vector2(side_scale * (12.0 - turned * 6.0), -6.0)
	c.draw_circle(head_pos, 16.0, BRONZE_LIT)
	# Eye
	if eye > 0.1:
		c.draw_circle(head_pos + Vector2(side_scale * 6.0, -4.0), 3.5 * eye, EYE_AMBER)
	# Snout & Jaw
	var jaw_drop := jaw * 8.0
	c.draw_circle(head_pos + Vector2(side_scale * 14.0, 4.0 + jaw_drop), 7.0, BRONZE_DARK)
	c.draw_circle(head_pos + Vector2(side_scale * 16.0, 2.0), 3.5, BRONZE_SHINE)


static func _title(c: CanvasItem, t: float) -> void:
	IntroKit.vgrad(c, Rect2(-200, 0.0, 1680, 824.0), Color(0.92, 0.56, 0.40), Color(0.38, 0.22, 0.42))
	FilmKit.slam(c, t, "ELS LLEONS!", Vector2(660, 200))
	IntroTitle.word(c, "THE BRONZE LIONS OF EL PORT", Vector2(640, 420), 30)
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
