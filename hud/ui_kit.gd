extends RefCounted

# The look every screen shares: two faces of the one font, the card, the
# key cap, and the prompt bar along the bottom of the screen.
#
# Each screen used to be a stack of plain Labels in the same size and colour,
# so the walk select, the wardrobe, the owner choice and a game-over all read
# as the same wall of text, and every screen put its button hints somewhere
# different. Now a screen is a card with a heading in its own accent colour,
# and whatever it lets you do is a row of key caps in one place: the bottom
# of the screen, every time.
#
# Static, and every function takes the CanvasItem to draw onto, like
# ui_icons.gd. The web font has no fallbacks, so everything here is ASCII and
# every glyph that is not a letter (chevrons, locks, arrows) is a shape.

const Icons := preload("res://hud/ui_icons.gd")

const INK := Color(0.98, 0.95, 0.88)
const INK_SOFT := Color(0.80, 0.78, 0.74)
const INK_FAINT := Color(0.56, 0.57, 0.60)
const PANEL := Color(0.075, 0.08, 0.095, 0.95)
const GOLD := Color(0.98, 0.80, 0.38)
const GOOD := Color(0.58, 0.90, 0.62)
const BAD := Color(1.0, 0.56, 0.48)

# one accent per screen, so each one reads as its own place at a glance
const ACCENT := {
	"title": GOLD, "walk": GOLD, "details": Color(0.52, 0.80, 0.98),
	"shop": Color(0.98, 0.58, 0.68), "progress": Color(0.60, 0.90, 0.62),
	"settings": Color(0.70, 0.74, 0.98), "pause": GOLD, "notice": Color(1.0, 0.62, 0.50),
	"results": GOLD,
}

# the prompt bar: key caps this tall, this far up from the bottom edge
const BAR_PX := 15
const BAR_CAP_H := 26.0
const BAR_FROM_BOTTOM := 46.0
const BAR_GAP := 26.0

static var _display: FontVariation
static var _cards := {}


# The heavy face, for headings and anything that has to be read at a glance.
# A variation of the built-in font rather than a second font file: the game
# ships no assets but its icon, and emboldening is enough to set a heading
# apart from the body text under it.
static func display() -> Font:
	if _display == null:
		_display = FontVariation.new()
		_display.base_font = ThemeDB.fallback_font
		_display.variation_embolden = 0.85
		_display.set_spacing(TextServer.SPACING_GLYPH, 1)
	return _display


static func body() -> Font:
	return ThemeDB.fallback_font


static func text_w(f: Font, s: String, px: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


static func accent(screen: String) -> Color:
	return ACCENT.get(screen, GOLD)


static func _card_box(acc: Color, radius: int) -> StyleBoxFlat:
	var k := "%s/%d" % [acc.to_html(), radius]
	if not _cards.has(k):
		var sb := StyleBoxFlat.new()
		sb.bg_color = PANEL
		sb.set_corner_radius_all(radius)
		sb.border_width_top = 4
		sb.border_color = Color(acc.r, acc.g, acc.b, 0.9)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 4)
		sb.anti_aliasing = true
		_cards[k] = sb
	return _cards[k]


# The panel every screen sits on: dark, rounded, lifted off the world by a
# soft shadow, with the screen's accent along its top edge.
static func card(c: CanvasItem, r: Rect2, acc: Color, radius := 14) -> void:
	c.draw_style_box(_card_box(acc, radius), r)


# A heading with a dark outline, so it reads over the world as well as on a card.
static func heading(c: CanvasItem, at: Vector2, s: String, px: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var f := display()
	f.draw_string_outline(c.get_canvas_item(), at, s, align, w, px, 6, Color(0.04, 0.03, 0.06, col.a * 0.8))
	f.draw_string(c.get_canvas_item(), at, s, align, w, px, col)


static func keycap_w(label: String, px := BAR_PX) -> float:
	return maxf(float(px) * 1.8, text_w(display(), label, px) + float(px) * 1.2)


# A key cap with the button's name on it, for whichever device is in hand.
# `at` is its top-left; returns its width so a row can be laid out.
static func keycap(c: CanvasItem, at: Vector2, label: String, px := BAR_PX, h := BAR_CAP_H,
		a := 1.0) -> float:
	var w := keycap_w(label, px)
	var r := Rect2(at, Vector2(w, h))
	# the side of the key, then its face: reads as something you press
	c.draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0.30, 0.29, 0.28, a))
	c.draw_rect(r, Color(0.93, 0.91, 0.86, a))
	c.draw_rect(Rect2(r.position, Vector2(w, 2)), Color(1, 1, 1, 0.6 * a))
	var f := display()
	var tw := text_w(f, label, px)
	c.draw_string(f, Vector2(at.x + (w - tw) * 0.5, at.y + h * 0.5 + float(px) * 0.36), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(0.12, 0.11, 0.12, a))
	return w


static func _item_w(it: Array) -> float:
	return keycap_w(Prompts.key(String(it[0]))) + 8.0 + text_w(body(), String(it[1]), BAR_PX)


static func bar_width(items: Array) -> float:
	var w := 0.0
	for i in range(items.size()):
		w += _item_w(items[i]) + (BAR_GAP if i > 0 else 0.0)
	return w


# What this screen lets you do, as key caps and verbs, centred along the
# bottom of the screen. Every screen puts it in the same place, so there is
# one place to look. items: [[action, verb], ...]; an item with a third entry
# of false is shown dimmed (a thing you cannot do yet, like buying a coat you
# cannot afford).
static func prompt_bar(c: CanvasItem, vs: Vector2, items: Array, a := 1.0) -> void:
	if items.is_empty():
		return
	var w := bar_width(items)
	var y := vs.y - BAR_FROM_BOTTOM
	var back := Rect2((vs.x - w) * 0.5 - 18.0, y - 9.0, w + 36.0, BAR_CAP_H + 20.0)
	c.draw_rect(back, Color(0.05, 0.05, 0.07, 0.62 * a))
	var x := (vs.x - w) * 0.5
	for it: Array in items:
		var on: bool = it.size() < 3 or bool(it[2])
		var ia := a * (1.0 if on else 0.4)
		x += keycap(c, Vector2(x, y), Prompts.key(String(it[0])), BAR_PX, BAR_CAP_H, ia) + 8.0
		c.draw_string(body(), Vector2(x, y + BAR_CAP_H * 0.5 + float(BAR_PX) * 0.36), String(it[1]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, BAR_PX, Color(INK.r, INK.g, INK.b, ia))
		x += text_w(body(), String(it[1]), BAR_PX) + BAR_GAP


# a small right-pointing chevron, centred on `at`
static func chevron(c: CanvasItem, at: Vector2, s: float, col: Color, left := false) -> void:
	var d := -1.0 if left else 1.0
	c.draw_polyline(PackedVector2Array([at + Vector2(-s * 0.4 * d, -s * 0.7),
		at + Vector2(s * 0.4 * d, 0), at + Vector2(-s * 0.4 * d, s * 0.7)]), col, maxf(2.0, s * 0.3))


# a padlock, centred on `at`
static func lock(c: CanvasItem, at: Vector2, s: float, col: Color) -> void:
	c.draw_arc(at + Vector2(0, -s * 0.2), s * 0.42, PI, TAU, 12, col, maxf(1.6, s * 0.18))
	c.draw_rect(Rect2(at + Vector2(-s * 0.62, -s * 0.2), Vector2(s * 1.24, s * 0.95)), col)
	c.draw_circle(at + Vector2(0, s * 0.25), s * 0.14, PANEL)


static func breadcrumb_w(steps: Array) -> float:
	var w := 38.0 * float(maxi(0, steps.size() - 1))
	for s in steps:
		w += text_w(display(), String(s), 18)
	return w


# The steps of the title menu, left to right with the current one lit, so
# the player always knows which choice this is and how many are left.
static func breadcrumb(c: CanvasItem, at: Vector2, steps: Array, current: int, acc: Color) -> void:
	var x := at.x
	var f := display()
	for i in range(steps.size()):
		if i > 0:
			chevron(c, Vector2(x + 18.0, at.y - 7.0), 9.0, INK_FAINT)
			x += 38.0
		var s := String(steps[i])
		var col: Color = acc if i == current else INK_FAINT
		heading(c, Vector2(x, at.y), s, 18, col)
		if i == current:
			c.draw_rect(Rect2(x, at.y + 7.0, text_w(f, s, 18), 3.0), acc)
		x += text_w(f, s, 18)


# the player's standing: stars earned and bones banked, top right
static func purse(c: CanvasItem, right: Vector2, stars: int, bones: int) -> void:
	var f := display()
	var bs := str(bones)
	var x := right.x - text_w(f, bs, 20)
	heading(c, Vector2(x, right.y), bs, 20, INK)
	Icons.draw_bone(c, Vector2(x - 18.0, right.y - 7.0), 11.0)
	x -= 58.0
	var ss := str(stars)
	x -= text_w(f, ss, 20)
	heading(c, Vector2(x, right.y), ss, 20, INK)
	Icons.draw_star(c, Vector2(x - 16.0, right.y - 7.0), 10.0, true)
