extends RefCounted

# The one speech bubble every voice in the world uses: your human, the
# dare-givers and every passer-by (world/pops_layer.gd lays them out and draws
# them, above everything in the world and under the HUD).
#
# Cream, rounded, a soft shadow, dark ink, a tail down to whoever is talking.
# A line wider than WRAP_W goes on two lines, never more; a dare and its
# "Bark if you're in!" split where they join. It pops open with a small
# overshoot, so a new line catches the eye without a flash.

const Kit := preload("res://hud/ui_kit.gd")

const PX := 14
const WRAP_W := 220.0
const LINE_H := 17.0
const PAD_X := 10.0
const PAD_Y := 5.0
const RADIUS := 9
const TAIL_W := 11.0
# the gap the tail spans between the speaker's head and the bubble
const TAIL_H := 9.0
const POP_S := 0.16
const PAPER := Color(0.98, 0.97, 0.93)
const PAPER_WIN := Color(0.88, 0.98, 0.86)
const INK := Color(0.13, 0.12, 0.14)
const EDGE := Color(0.20, 0.18, 0.20, 0.30)

static var _sb: StyleBoxFlat


# The text as it is drawn: one line, or two split at `split_after` (a suffix
# that goes on its own line) or else at the space nearest the middle.
static func lines(text: String, split_after := "") -> Array[String]:
	var f := Kit.body()
	if Kit.text_w(f, text, PX) <= WRAP_W:
		return [text]
	if split_after != "" and text.ends_with(split_after) and text.length() > split_after.length():
		return [text.substr(0, text.length() - split_after.length()).strip_edges(), split_after.strip_edges()]
	var mid := text.length() / 2
	var best := -1
	for i in text.length():
		if text[i] == " " and (best < 0 or absi(i - mid) < absi(best - mid)):
			best = i
	if best < 0:
		return [text]
	return [text.substr(0, best), text.substr(best + 1)]


static func size_of(ls: Array[String]) -> Vector2:
	var f := Kit.body()
	var w := 0.0
	for l: String in ls:
		w = maxf(w, Kit.text_w(f, l, PX))
	return Vector2(w + PAD_X * 2.0, LINE_H * float(ls.size()) + PAD_Y * 2.0)


# box: where the bubble sits (laid out by the caller); tip: the speaker's
# head, where the tail points; t: seconds since this line appeared; a: fade.
static func draw(ci: CanvasItem, box: Rect2, tip: Vector2, ls: Array[String], t: float, a: float,
		paper := PAPER) -> void:
	if _sb == null:
		_sb = StyleBoxFlat.new()
		_sb.set_corner_radius_all(RADIUS)
		_sb.set_border_width_all(1)
		_sb.shadow_size = 4
		_sb.shadow_offset = Vector2(0.0, 2.0)
		_sb.anti_aliasing = true
	# pop: 0.7 -> 1.06 -> 1.0, scaled about the tail's root
	var k := clampf(t / POP_S, 0.0, 1.0)
	var s := lerpf(0.7, 1.06, k) if k < 0.7 else lerpf(1.06, 1.0, (k - 0.7) / 0.3)
	var root := Vector2(clampf(tip.x, box.position.x + RADIUS + TAIL_W * 0.5, box.end.x - RADIUS - TAIL_W * 0.5),
		box.end.y)
	ci.draw_set_transform(root * (1.0 - s), 0.0, Vector2(s, s))
	var fill := Color(paper.r, paper.g, paper.b, paper.a * a)
	_sb.bg_color = fill
	_sb.border_color = Color(EDGE.r, EDGE.g, EDGE.b, EDGE.a * a)
	_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.22 * a)
	# the tail first, so the body hides its root; it bends to the speaker
	# wherever the layout put the bubble
	var tail := PackedVector2Array([root + Vector2(-TAIL_W * 0.5, -2.0), root + Vector2(TAIL_W * 0.5, -2.0), tip])
	ci.draw_colored_polygon(tail, fill)
	ci.draw_polyline(PackedVector2Array([tail[0] + Vector2(0.0, 2.0), tip, tail[1] + Vector2(0.0, 2.0)]),
		_sb.border_color, 1.0, true)
	ci.draw_style_box(_sb, box)
	# cover the border where the tail joins
	ci.draw_rect(Rect2(root.x - TAIL_W * 0.5 + 1.0, box.end.y - 2.0, TAIL_W - 2.0, 2.0), fill)
	if t >= POP_S * 0.5:
		var f := Kit.body()
		var ink := Color(INK.r, INK.g, INK.b, a)
		for i in ls.size():
			var lw := Kit.text_w(f, ls[i], PX)
			ci.draw_string(f, Vector2(box.get_center().x - lw * 0.5, box.position.y + PAD_Y + 13.0 + LINE_H * float(i)),
				ls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, PX, ink)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
