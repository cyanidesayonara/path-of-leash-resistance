extends Control

# The whole left-side HUD as one quiet card: phone pips, bones, the
# tube, mark dots, and a status line. The world is chaotic on purpose;
# the overlay is not.

const Icons := preload("res://hud/ui_icons.gd")
const Kit := preload("res://hud/ui_kit.gd")

# the card's size, and where the mood badge sits: its bottom row, under the
# mark dots and to the right of the tubes
const CARD_W := 196.0
const CARD_H := 92.0
const MOOD_X := 60.0
const MOOD_BASELINE := 86.0

# what a lesson can point at, and the outline drawn round it
const POINT_RECTS := {
	"phone": Rect2(10, 8, 66, 32),
	"tank": Rect2(12, 38, 20, 52),
	"zoomies": Rect2(30, 38, 20, 52),
}

var main: Node2D
var sb: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.10, 0.42)
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

	# phone pips: the phone's three lives, rendered as smart-device silhouettes
	# with glowing cyan screens when active and cracked red fractures when lost
	for i in range(3):
		var on: bool = i < main.phone_hp
		Icons.draw_phone_pip(_b, Vector2(14 + i * 21, 12), 24.0, on)

	# the bone count bank
	var bx := Vector2(104, 22)
	Icons.draw_bone(_b, bx, 11.0, Color(0.93, 0.90, 0.83))
	_b.draw_string(Kit.display(), Vector2(120, 29), str(main.bones), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.94, 0.90))

	# combo streak pill badge
	if main.streak > 1:
		var st_rect := Rect2(100, 35, 78, 16)
		_b.draw_rect(st_rect, Color(0.18, 0.50, 0.32, 0.45))
		_b.draw_rect(st_rect, Color(0.40, 0.85, 0.55, 0.70), false, 1.0)
		_b.draw_string(Kit.display(), Vector2(104, 47), "STREAK x%d" % main.streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 1.0, 0.80))

	# the pee / bladder tube (yellow) and droplet glyph
	var tr := Rect2(16, 42, 12, 36)
	_b.draw_rect(tr, Color(0.06, 0.08, 0.10, 0.65))
	var lh: float = 32.0 * clampf(main.pee, 0.0, 1.0)
	if lh > 1.0:
		var col := Color(0.94, 0.82, 0.25, 0.95)
		if main.pee >= 0.999 and fmod(AnimClock.msec() / 350.0, 2.0) < 1.0:
			col = Color(1.0, 0.94, 0.45)
		_b.draw_rect(Rect2(17, 44 + 32.0 - lh, 10, lh), col)
	_b.draw_rect(tr, Color(1, 1, 1, 0.45), false, 1.2)
	Icons.draw_droplet(_b, Vector2(22, 84), 7.5, Color(0.94, 0.82, 0.25, 0.90))

	# the zoomies / energy tube (green) and lightning bolt glyph
	var er := Rect2(34, 42, 12, 36)
	_b.draw_rect(er, Color(0.06, 0.08, 0.10, 0.65))
	var eh: float = 32.0 * clampf(main.dog.energy, 0.0, 1.0)
	var ecol := Color(0.35, 0.88, 0.45, 0.95)
	if float(main.golden_t) > 0.0:
		ecol = Color(1.0, 0.80, 0.30).lerp(Color(1.0, 0.95, 0.60), 0.5 + 0.5 * sin(AnimClock.msec() / 90.0))
	elif main.dog.turbo_active and fmod(AnimClock.msec() / 120.0, 2.0) < 1.0:
		ecol = Color(0.65, 1.0, 0.75)
	if eh > 1.0:
		_b.draw_rect(Rect2(35, 44 + 32.0 - eh, 10, eh), ecol)
	_b.draw_rect(er, Color(1, 1, 1, 0.45), false, 1.2)
	Icons.draw_bolt(_b, Vector2(40, 84), 7.5, ecol)

	# the meter a lesson is about, outlined and pulsing while it is up; the
	# phone's pips while THAT'S THE BASICS names them
	var point := "phone" if String(main.confirm_id) == "basics" else String(main.hud_point)
	if POINT_RECTS.has(point):
		var a := 0.55 + 0.45 * sin(AnimClock.msec() / 160.0)
		_b.draw_rect(POINT_RECTS[point], Color(0.98, 0.80, 0.38, a), false, 2.5)

	# territory mark posts: claimed marks glow bright gold with outer ring
	for i in range(5):
		var p := Vector2(60 + i * 16, 62)
		var claimed: bool = i < mini(main.marks.size(), 5)
		if claimed:
			_b.draw_circle(p, 3.8, Color(0.96, 0.88, 0.42, 0.95))
			_b.draw_arc(p, 5.5, 0, TAU, 14, Color(0.96, 0.88, 0.42, 0.85), 1.4)
		else:
			_b.draw_circle(p, 1.5, Color(1, 1, 1, 0.16))
			_b.draw_arc(p, 5.5, 0, TAU, 14, Color(1, 1, 1, 0.35), 1.2)

	# The mood, when there is one. It rides on the card's bottom rule as a
	# named badge with a bar, because a mood you cannot cancel has to be a mood
	# you can at least SEE going: the bar draining is the promise that this
	# passes on its own.
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
