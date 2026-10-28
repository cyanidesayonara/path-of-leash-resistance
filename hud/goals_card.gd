extends Control

# The goal card, top right, Tony Hawk style: a fixed, stable list where a
# finished goal stays put with a tick and dims out rather than vanishing.
#
# It was a RichTextLabel full of BBCode and ASCII boxes. Drawing it instead
# buys three things the label could not: real tick and meter shapes (the web
# export has no font fallbacks, so [x] was not a stylistic choice), a height
# that follows the content exactly, and per-row layout - the meter now sits at
# a fixed column instead of trailing the end of the text, so the card stops
# looking ragged.
#
# Wrapping still comes from the font, via draw_multiline_string, so a long
# goal name cannot spill out of the card.

const Icons := preload("res://hud/ui_icons.gd")

const W := 416.0
const GOALS_X := 856.0
const PAD := 14.0
const ROW_H := 21.0
# a long list opened on purpose tightens to fit the screen (systems/goals.gd
# decides when, from the same two heights)
const ROW_H_COMPACT := 16.0
const BOX := 13.0
const TEXT_X := 34.0
const METER_W := 62.0
const FONT_SIZE := 15
const FONT_SIZE_COMPACT := 13

var main: Node2D
var sb: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	# opaque enough that dimmed, completed rows stay legible over bright
	# ground - at 0.3 they washed out completely against pale pavement
	sb.bg_color = Color(0.07, 0.08, 0.09, 0.66)
	sb.set_corner_radius_all(10)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var f := ThemeDB.fallback_font
	var data: Dictionary = main.goal_card_data()
	var rows: Array = data.rows
	var extra: int = int(data.extra)
	var open: bool = bool(data.open)
	var folded: int = int(data.get("folded_done", 0))
	var compact: bool = bool(data.get("compact", false))
	var row_h := ROW_H_COMPACT if compact else ROW_H
	var font_size := FONT_SIZE_COMPACT if compact else FONT_SIZE
	# Collapsed, this is a clean compact card in the corner showing goal count,
	# a mini progress bar, and the prompt key.
	var w: float = W if open else 200.0
	var h := PAD + 22.0 + float(rows.size()) * row_h + (16.0 if extra > 0 or folded > 0 else 0.0) + PAD * 0.6
	if not open:
		h = 42.0
	size = Vector2(w, h)
	# right-aligned to the ACTUAL viewport edge (aspect "expand" reveals more
	# or less than the 1280 reference width on most phone shapes), so
	# collapsing pulls it into the true corner instead of drifting toward
	# the middle of a wide window, or off the edge of a narrow one
	var right_margin := 1280.0 - (GOALS_X + W)  # 8px, preserved from the original tuning
	position.x = get_viewport_rect().size.x - right_margin - w
	draw_style_box(sb, Rect2(0, 0, w, h))
	var all_done: bool = bool(data.all_done)
	var head_col := Color(0.62, 0.90, 0.66) if all_done else Color(0.91, 0.86, 0.75)
	if bool(data.peeking):
		head_col = Color(1.0, 0.90, 0.55)
	draw_string(f, Vector2(PAD, PAD + 10.0), "GOALS  %d/%d" % [int(data.done), int(data.total)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, head_col)
	if all_done and open:
		draw_string(f, Vector2(PAD + 108.0, PAD + 10.0), "ALL CLEAR",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.62, 0.90, 0.66))

	# key / button prompt pill
	var key_str := String(data.key)
	var kw := f.get_string_size(key_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12.0
	var krect := Rect2(w - PAD - kw, PAD - 1.0, kw, 16.0)
	draw_rect(krect, Color(1, 1, 1, 0.10))
	draw_rect(krect, Color(1, 1, 1, 0.22), false, 1.0)
	draw_string(f, Vector2(krect.position.x + 6.0, krect.position.y + 12.0), key_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.78, 0.76, 0.70))

	if not open:
		# mini progress bar under the title
		var total_cnt := maxi(1, int(data.total))
		var done_cnt := int(data.done)
		var frac := clampf(float(done_cnt) / float(total_cnt), 0.0, 1.0)
		var bar_w := 98.0
		var bar_r := Rect2(PAD, PAD + 17.0, bar_w, 3.5)
		draw_rect(bar_r, Color(1, 1, 1, 0.12))
		if frac > 0.0:
			draw_rect(Rect2(PAD, PAD + 17.0, bar_w * frac, 3.5),
				Color(0.62, 0.90, 0.66) if all_done else Color(0.94, 0.79, 0.35))
		return

	var y := PAD + 30.0
	for row: Dictionary in rows:
		var state := int(row.state)
		Icons.draw_check(self, Vector2(PAD + 2.0, y + (0.0 if compact else 1.0)), BOX, state)
		var txt_col := Color(0.95, 0.93, 0.88)
		if state == Icons.Check.DONE_NOW:
			txt_col = Color(0.73, 0.85, 0.74)
		elif state == Icons.Check.DONE_BEFORE:
			txt_col = Color(0.47, 0.53, 0.48)
		var target := int(row.target)
		var show_meter: bool = target > 1 and state != Icons.Check.DONE_NOW \
			and state != Icons.Check.DONE_BEFORE
		var text_w := W - TEXT_X - PAD - (METER_W + 34.0 if show_meter else 0.0)
		# one line only: the card is a glance, not a document. Anything longer
		# than the card is the goal text's problem, not the layout's.
		draw_multiline_string(f, Vector2(TEXT_X, y + 12.0), String(row.text),
			HORIZONTAL_ALIGNMENT_LEFT, text_w, font_size, 1, txt_col)
		if show_meter:
			var got: int = mini(int(row.got), target)
			var mx := W - PAD - METER_W - 30.0
			Icons.draw_meter(self, Vector2(mx, y + (4.0 if compact else 5.0)), METER_W, 7.0 if not compact else 6.0,
				float(got) / float(target))
			draw_string(f, Vector2(mx + METER_W + 5.0, y + 12.0), "%d/%d" % [got, target],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.73, 0.55))
		y += row_h
	if folded > 0:
		draw_string(f, Vector2(TEXT_X, y + 11.0), "+ %d done" % folded,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.47, 0.53, 0.48))
	elif extra > 0:
		draw_string(f, Vector2(TEXT_X, y + 11.0), "+ %d more" % extra,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.56, 0.53, 0.48))
