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

const Icons := preload("res://ui_icons.gd")

const W := 416.0
const GOALS_X := 856.0
const PAD := 14.0
const ROW_H := 21.0
const BOX := 13.0
const TEXT_X := 34.0
const METER_W := 62.0
const FONT_SIZE := 15

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
	# Collapsed, this is one line in the corner. The game's chaos is supposed
	# to be in the level, not in a wall of text over the top of it, so the
	# list is something you ASK for - and it opens itself for a moment
	# whenever a goal actually lands, so you never miss the tick.
	var w: float = W if open else 190.0
	var h := PAD + 22.0 + float(rows.size()) * ROW_H + (16.0 if extra > 0 else 0.0) + PAD * 0.6
	if not open:
		h = 40.0
	size = Vector2(w, h)
	# right-aligned, so collapsing pulls it into the corner instead of
	# leaving a stub floating mid-screen
	position.x = GOALS_X + (W - w)
	draw_style_box(sb, Rect2(0, 0, w, h))
	var all_done: bool = bool(data.all_done)
	var head_col := Color(0.62, 0.90, 0.66) if all_done else Color(0.91, 0.86, 0.75)
	if bool(data.peeking):
		head_col = Color(1.0, 0.90, 0.55)
	draw_string(f, Vector2(PAD, PAD + 12.0), "GOALS  %d/%d" % [int(data.done), int(data.total)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, head_col)
	if all_done and open:
		draw_string(f, Vector2(PAD + 108.0, PAD + 12.0), "ALL CLEAR",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.62, 0.90, 0.66))
	if not open:
		# the key that opens it, quietly, once
		draw_string(f, Vector2(w - PAD - 42.0, PAD + 11.0), String(data.key),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.60, 0.56, 0.75))
		return
	var y := PAD + 30.0
	for row: Dictionary in rows:
		var state := int(row.state)
		Icons.draw_check(self, Vector2(PAD + 2.0, y + 1.0), BOX, state)
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
			HORIZONTAL_ALIGNMENT_LEFT, text_w, FONT_SIZE, 1, txt_col)
		if show_meter:
			var got: int = mini(int(row.got), target)
			var mx := W - PAD - METER_W - 30.0
			Icons.draw_meter(self, Vector2(mx, y + 5.0), METER_W, 7.0,
				float(got) / float(target))
			draw_string(f, Vector2(mx + METER_W + 5.0, y + 12.0), "%d/%d" % [got, target],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.73, 0.55))
		y += ROW_H
	if extra > 0:
		draw_string(f, Vector2(TEXT_X, y + 11.0), "+ %d more" % extra,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.56, 0.53, 0.48))
