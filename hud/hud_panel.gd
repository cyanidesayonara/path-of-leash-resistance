extends Control

# The whole left-side HUD as one quiet card: phone pips, bones, the
# tube, mark dots, and a status line. The world is chaotic on purpose;
# the overlay is not.

# the card's size, and where the mood badge sits: its bottom row, under the
# mark dots and to the right of the tubes
const CARD_W := 196.0
const CARD_H := 92.0
const MOOD_X := 60.0
const MOOD_BASELINE := 86.0

var main: Node2D
var sb: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.1, 0.32)
	sb.set_corner_radius_all(10)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_draw_shapes()
	_b.flush()


func _draw_shapes() -> void:
	var f := ThemeDB.fallback_font
	_b.draw_style_box(sb, Rect2(0, 0, CARD_W, CARD_H))
	# phone pips: the phone's three lives
	for i in range(3):
		var r := Rect2(14 + i * 21, 12, 14, 24)
		_b.draw_rect(r, Color(0.16, 0.18, 0.22))
		var on: bool = i < main.phone_hp
		_b.draw_rect(r.grow(-2.5), Color(0.7, 0.85, 1.0, 0.9) if on else Color(0.3, 0.32, 0.36))
	# the bone count
	var bx := Vector2(104, 24)
	_b.draw_line(bx + Vector2(-7, 0), bx + Vector2(7, 0), Color(0.92, 0.9, 0.84), 4.0)
	for c in [Vector2(-8, -3), Vector2(-8, 3), Vector2(8, -3), Vector2(8, 3)]:
		_b.draw_circle(bx + c, 3.0, Color(0.92, 0.9, 0.84))
	_b.draw_string(f, Vector2(120, 31), str(main.bones), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.95, 0.94, 0.9))
	if main.streak > 1:
		_b.draw_string(f, Vector2(120, 48), "streak x%d" % main.streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 1.0, 0.75))
	# the pee tube (yellow) and the zoomies/energy tube (green)
	var tr := Rect2(16, 44, 12, 38)
	_b.draw_rect(tr, Color(1, 1, 1, 0.12))
	var lh: float = 34.0 * clampf(main.pee, 0.0, 1.0)
	if lh > 2.0:
		var col := Color(0.93, 0.83, 0.25, 0.9)
		if main.pee >= 0.999 and fmod(AnimClock.msec() / 400.0, 2.0) < 1.0:
			col = Color(1.0, 0.92, 0.35)
		_b.draw_rect(Rect2(17, 46 + 34.0 - lh, 10, lh), col)
	_b.draw_rect(tr, Color(1, 1, 1, 0.5), false, 1.5)
	var er := Rect2(34, 44, 12, 38)
	_b.draw_rect(er, Color(1, 1, 1, 0.12))
	var eh: float = 34.0 * clampf(main.dog.energy, 0.0, 1.0)
	if eh > 2.0:
		var ecol := Color(0.4, 0.8, 0.5, 0.9)
		if main.dog.turbo_active and fmod(AnimClock.msec() / 120.0, 2.0) < 1.0:
			ecol = Color(0.6, 1.0, 0.7)
		_b.draw_rect(Rect2(35, 46 + 34.0 - eh, 10, eh), ecol)
	_b.draw_rect(er, Color(1, 1, 1, 0.5), false, 1.5)
	# mark dots: territory progress
	for i in range(5):
		var p := Vector2(60 + i * 16, 64)
		if i < mini(main.marks.size(), 5):
			_b.draw_circle(p, 5.0, Color(0.95, 0.88, 0.5, 0.9))
		_b.draw_arc(p, 5.0, 0, TAU, 12, Color(1, 1, 1, 0.4), 1.2)
	# The mood, when there is one. It rides on the card's bottom rule as a
	# named badge with a bar, because a mood you cannot cancel has to be a mood
	# you can at least SEE going: the bar draining is the promise that this
	# passes on its own.
	# It sits in the card's bottom row, under the mark dots and clear of the
	# tubes: drawn at y=40 its letters rose into the third phone pip (#7). The
	# bar starts after the name's real width, so no badge runs into it.
	if main.mood != null:
		var badge: String = main.mood.badge()
		if badge != "":
			var mi: float = clampf(main.mood.intensity, 0.0, 1.0)
			var tint: Color = main.mood.tint()
			_b.draw_string(f, Vector2(MOOD_X, MOOD_BASELINE), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
				Color(tint.r, tint.g, tint.b, 0.55 + 0.45 * mi))
			var bar_x: float = MOOD_X + f.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 8.0
			var bar_w: float = maxf(24.0, CARD_W - 10.0 - bar_x)
			var mb := Rect2(bar_x, MOOD_BASELINE - 6.0, bar_w, 4)
			_b.draw_rect(mb, Color(1, 1, 1, 0.12))
			_b.draw_rect(Rect2(mb.position, Vector2(bar_w * mi, 4)), Color(tint.r, tint.g, tint.b, 0.8))
	# The status line used to live here, tucked under the card in the top-left
	# corner - the furthest point on the screen from where anybody is looking.
	# It is the feed's banner now (event_feed.gd): centre screen, just under the
	# dog, in the one place the game says things. This card is for STATE that is
	# always true - phone, bones, bladder, energy, marks, mood - and carries no
	# announcements at all, which is what keeps it readable at a glance.
