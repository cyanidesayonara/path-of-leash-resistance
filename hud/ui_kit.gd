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
# ui_icons.gd. Every glyph that is not a letter (chevrons, locks, arrows) is a
# shape.
#
# The palette is Trencadis, Gaudi's broken-tile mosaic: saffron, turquoise and
# magenta on a deep navy (chosen 2026-11-16). The website's colours are
# generated from these constants (tools/site_palette.gd), so change them here.

const Icons := preload("res://hud/ui_icons.gd")
const UiScale := preload("res://hud/ui_scale.gd")

const INK := Color("f4f1ea")
const INK_SOFT := Color("c9cfdf")
const INK_FAINT := Color("8590ad")
const NAVY := Color("14203d")
const NAVY_RAISED := Color("1d2c52")
# the shadow under a key cap, grout between tiles, the website's backdrop
const NAVY_DEEP := Color("0b1430")
const PICK_NAVY := Color("2a3d6e")
const PANEL := Color(NAVY.r, NAVY.g, NAVY.b, 0.95)
# a panel laid over the walk itself (goals, gauges, banner): see-through
const PANEL_SOFT := Color(NAVY.r, NAVY.g, NAVY.b, 0.72)
const SAFFRON := Color("ffb020")
const TURQUOISE := Color("1fc9b7")
const MAGENTA := Color("e5487a")
const LEAF := Color("8bcb3c")
# GOLD predates the palette and is used everywhere as "the primary colour"
const GOLD := SAFFRON
const GOOD := LEAF
const BAD := Color("ff6b5a")

# Two colours for screens, not one per screen: saffron where you are going
# (the title, the walk, pause, results), turquoise for the screens beside it
# (details, wardrobe, progress, settings), magenta for a question or warning.
const ACCENT := {
	"title": SAFFRON, "walk": SAFFRON, "details": TURQUOISE,
	"shop": TURQUOISE, "progress": TURQUOISE,
	"settings": TURQUOISE, "pause": SAFFRON, "notice": MAGENTA,
	"results": SAFFRON,
}

# the prompt bar: key caps this tall, this far up from the bottom edge
const BAR_PX := 15
const BAR_CAP_H := 26.0
const BAR_FROM_BOTTOM := 46.0
const BAR_GAP := 26.0

static var _display: FontVariation
static var _body: FontVariation
static var _cards := {}

# The two faces, both OFL (fonts/OFL-*.txt). They carry the accents the
# built-in font lacked, so Catalan names can be written as they are spelled.
const DISPLAY_FILE := preload("res://fonts/BricolageGrotesque.ttf")
const BODY_FILE := preload("res://fonts/Inter.ttf")
const DISPLAY_WEIGHT := 800
const BODY_WEIGHT := 500


# The heavy face, for headings and anything that has to be read at a glance.
static func display() -> Font:
	if _display == null:
		_display = FontVariation.new()
		_display.base_font = DISPLAY_FILE
		_display.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): DISPLAY_WEIGHT}
	return _display


# The reading face, for everything else. Game makes it the fallback font at
# start, so every Label and every draw_string that asks ThemeDB gets it too.
static func body() -> Font:
	if _body == null:
		_body = FontVariation.new()
		_body.base_font = BODY_FILE
		_body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): BODY_WEIGHT}
	return _body


static func text_w(f: Font, s: String, px: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


static func accent(screen: String) -> Color:
	return ACCENT.get(screen, SAFFRON)


# The fill behind a picked row or cell. A see-through wash of a cool accent
# reads as its own tint on the navy; saffron washed over navy turns to mud,
# so a warm accent lifts the row to a lighter navy instead and leaves the
# colour to the row's bar or outline.
static func pick_fill(acc: Color) -> Color:
	if acc.r > acc.b:
		return Color(PICK_NAVY.r, PICK_NAVY.g, PICK_NAVY.b, 0.95)
	return Color(acc.r, acc.g, acc.b, 0.15)


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


# A trencadis strip, the palette's signature: two courses of broken tile
# shards with slanted joints in navy grout, laid along the top edge of a card
# between its rounded corners. The same shards every time (no RNG), and one
# draw call for the whole strip.
const MOSAIC_ROW := 6.0
const MOSAIC_GROUT := 2.0
const MOSAIC_COLS := [SAFFRON, TURQUOISE, MAGENTA, SAFFRON, LEAF, TURQUOISE, INK, MAGENTA, SAFFRON]


static func mosaic(c: CanvasItem, r: Rect2, radius := 14, a := 1.0) -> void:
	var x0 := r.position.x + float(radius)
	var x1 := r.end.x - float(radius)
	var top := r.position.y
	var h := MOSAIC_ROW * 2.0 + MOSAIC_GROUT * 3.0
	var b := ShapeBatch.new(c)
	b.rect(Rect2(x0, top, x1 - x0, h), Color(NAVY_DEEP.r, NAVY_DEEP.g, NAVY_DEEP.b, a))
	for row in range(2):
		var y0 := top + MOSAIC_GROUT + float(row) * (MOSAIC_ROW + MOSAIC_GROUT)
		var y1 := y0 + MOSAIC_ROW
		var x := x0 + MOSAIC_GROUT
		var lean := 0.0
		var i := row * 17
		while x < x1 - MOSAIC_GROUT - 6.0:
			# widths, slants and colours from a fixed hash of the shard's index
			var k := hash(i * 7919 + 13)
			var w := 12.0 + float(k % 23)
			var next_lean := float((k >> 7) % 11) - 5.0
			var xe := x + w
			if xe >= x1 - MOSAIC_GROUT - 10.0:
				xe = x1 - MOSAIC_GROUT
				next_lean = 0.0
			var col: Color = MOSAIC_COLS[(k >> 13) % MOSAIC_COLS.size()]
			var g := MOSAIC_GROUT * 0.5
			b.polygon(PackedVector2Array([Vector2(x + lean + g, y0), Vector2(xe + next_lean - g, y0),
				Vector2(xe - next_lean - g, y1), Vector2(x - lean + g, y1)]),
				Color(col.r, col.g, col.b, a))
			x = xe
			lean = next_lean
			i += 1
	b.flush()


# room kept clear of a fitted heading's box, for the 6px outline plus a little
# air, so the last stroke is not cut off by the card edge
const HEAD_PAD := 20.0


# The size a heading is actually drawn at. A width passed to draw_string clips
# any glyph that crosses it, which is how the last letter of a long loss
# ("YOUR HUMAN WENT DOWN THE MANHOLE") lost its final stroke. Shrink until the
# words, and the outline around them, sit inside the box.
static func heading_px(s: String, px: int, w: float) -> int:
	if w <= 0.0:
		return px
	var size := px
	var room := w - HEAD_PAD
	var f := display()
	while size > 15 and text_w(f, s, size) > room:
		size -= 1
	return size


# A heading with a dark outline, so it reads over the world as well as on a card.
static func heading(c: CanvasItem, at: Vector2, s: String, px: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	var f := display()
	var size := heading_px(s, px, w)
	var draw_at := at
	var draw_align := align
	var draw_w := w
	if w > 0.0:
		# placed by hand and drawn unclipped, so the outline is not cut either
		var tw := text_w(f, s, size)
		draw_align = HORIZONTAL_ALIGNMENT_LEFT
		draw_w = -1.0
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			draw_at = Vector2(at.x + (w - tw) * 0.5, at.y)
		elif align == HORIZONTAL_ALIGNMENT_RIGHT:
			draw_at = Vector2(at.x + w - tw - HEAD_PAD * 0.5, at.y)
	var ci := c.get_canvas_item()
	f.draw_string_outline(ci, draw_at, s, draw_align, draw_w, size, 6, Color(0.03, 0.05, 0.11, col.a * 0.8))
	f.draw_string(ci, draw_at, s, draw_align, draw_w, size, col)


static func keycap_w(label: String, px := BAR_PX) -> float:
	return maxf(float(px) * 1.8, text_w(display(), label, px) + float(px) * 1.2)


# A key cap with the button's name on it, for whichever device is in hand.
# `at` is its top-left; returns its width so a row can be laid out.
static func keycap(c: CanvasItem, at: Vector2, label: String, px := BAR_PX, h := BAR_CAP_H,
		a := 1.0) -> float:
	var w := keycap_w(label, px)
	var r := Rect2(at, Vector2(w, h))
	# the side of the key, then its face: reads as something you press
	c.draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(NAVY_DEEP.r, NAVY_DEEP.g, NAVY_DEEP.b, a))
	c.draw_rect(r, Color(INK.r, INK.g, INK.b, a))
	c.draw_rect(Rect2(r.position, Vector2(w, 2)), Color(1, 1, 1, 0.6 * a))
	var f := display()
	var tw := text_w(f, label, px)
	c.draw_string(f, Vector2(at.x + (w - tw) * 0.5, at.y + h * 0.5 + float(px) * 0.36), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(NAVY.r, NAVY.g, NAVY.b, a))
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
	var ins := UiScale.safe_insets(c.get_window() if c.is_inside_tree() else null)
	var y := vs.y - BAR_FROM_BOTTOM - ins.w
	var back := Rect2((vs.x - w) * 0.5 - 18.0, y - 9.0, w + 36.0, BAR_CAP_H + 20.0)
	c.draw_rect(back, Color(NAVY_DEEP.r, NAVY_DEEP.g, NAVY_DEEP.b, 0.62 * a))
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
