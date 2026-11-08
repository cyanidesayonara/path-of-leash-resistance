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
const WordStrip := preload("res://hud/word_strip.gd")

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
# the spelling goal's letters, as small tiles where a meter would be
const TILE := 15.0
const TILE_GAP := 2.0
# the column every count, readout, letter tile and the key pill ends on, so
# the right side reads as one straight edge like the ticks on the left
const COUNT_W := 30.0
# where the rows start under the heading, and how far below a row's top its
# ink reaches (the tick box, or the text's descenders)
const ROWS_TOP := PAD + 30.0
const INK := 15.0
const INK_COMPACT := 14.0
# the heading's ink starts this far above its baseline, so the card's top
# margin is PAD - 1: the bottom and sides use the same
const HEAD_ASCENT := 11.0
# collapsed: the second row's baseline and where its ink ends
const COLLAPSED_BASE := 27.0
const COLLAPSED_INK := 29.0
const READ_OK := Color(0.78, 0.73, 0.55)
const READ_BAD := Color(1.0, 0.52, 0.42)

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


# Under a menu (the dim is up: pause, settings, a walk card) the card fades
# out, so the menu is the only thing on screen; it fades back on resume.
const DIM_FADE := 6.0


func _process(delta: float) -> void:
	# THAT'S THE BASICS points at the phone pips, so the card stays for it
	var under_menu: bool = main != null and main.dim != null and main.dim.visible \
		and String(main.confirm_id) != "basics"
	modulate.a = move_toward(modulate.a, 0.0 if under_menu else 1.0, delta * DIM_FADE)
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
	# the last ink on the card, then the same margin as the top (PAD - 1
	# above the heading's ink) below it
	var ink := INK_COMPACT if compact else INK
	var bottom := ROWS_TOP + float(maxi(rows.size() - 1, 0)) * row_h + ink
	if extra > 0 or folded > 0:
		bottom = ROWS_TOP + float(rows.size()) * row_h + 14.0
	var margin := PAD + 10.0 - HEAD_ASCENT
	var h := bottom + margin
	if not open:
		# heading row, then the bar and the clock on a row of their own
		h = PAD + COLLAPSED_INK + margin
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
		var bar_y := PAD + COLLAPSED_BASE - 5.0
		var bar_r := Rect2(PAD, bar_y, bar_w, 3.5)
		draw_rect(bar_r, Color(1, 1, 1, 0.12))
		if frac > 0.0:
			draw_rect(Rect2(PAD, bar_y, bar_w * frac, 3.5),
				Color(0.62, 0.90, 0.66) if all_done else Color(0.94, 0.79, 0.35))
		# the walk's time against the clock goal, while that goal is open
		var clk: Dictionary = data.get("clock", {})
		if not clk.is_empty():
			var cw := w - PAD * 2.0 - bar_w - 8.0
			draw_string(f, Vector2(w - PAD - cw, PAD + COLLAPSED_BASE), String(clk.text),
				HORIZONTAL_ALIGNMENT_RIGHT, cw, 12, READ_BAD if bool(clk.bad) else READ_OK)
		return

	var y := PAD + 30.0
	for row: Dictionary in rows:
		var state := int(row.state)
		Icons.draw_check(self, Vector2(PAD, y + (0.0 if compact else 1.0)), BOX, state)
		var txt_col := Color(0.95, 0.93, 0.88)
		if state == Icons.Check.DONE_NOW:
			txt_col = Color(0.73, 0.85, 0.74)
		elif state == Icons.Check.DONE_BEFORE:
			txt_col = Color(0.47, 0.53, 0.48)
		var target := int(row.target)
		var open_row: bool = state != Icons.Check.DONE_NOW and state != Icons.Check.DONE_BEFORE
		var letters: Array = row.get("letters", []) if open_row else []
		var readout: String = String(row.get("readout", "")) if open_row else ""
		var show_meter: bool = target > 1 and open_row and letters.is_empty()
		var side_w := 0.0
		var right := W - PAD
		if show_meter:
			side_w = METER_W + 6.0 + COUNT_W
		elif not letters.is_empty():
			side_w = float(letters.size()) * (TILE + TILE_GAP) + 8.0
		elif readout != "":
			side_w = f.get_string_size(readout, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 12.0
		var text_w := W - TEXT_X - PAD - side_w
		# one line only: the card is a glance, not a document. Anything longer
		# than the card is the goal text's problem, not the layout's.
		draw_multiline_string(f, Vector2(TEXT_X, y + 12.0), String(row.text),
			HORIZONTAL_ALIGNMENT_LEFT, text_w, font_size, 1, txt_col)
		if not letters.is_empty():
			var lx := right - float(letters.size()) * (TILE + TILE_GAP) + TILE_GAP
			for l: Dictionary in letters:
				var c := Vector2(lx + TILE * 0.5, y + (1.0 if compact else 2.0) + TILE * 0.5)
				if bool(l.got):
					WordStrip.coin(self, f, c, TILE * 0.5, String(l.ch))
				else:
					draw_circle(c, TILE * 0.5, Color(1, 1, 1, 0.08))
					draw_arc(c, TILE * 0.5, 0.0, TAU, 16, Color(1, 1, 1, 0.25), 1.0, true)
					var cw := f.get_string_size(String(l.ch), HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
					draw_string(f, Vector2(c.x - cw * 0.5, c.y + 3.6), String(l.ch),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.35))
				lx += TILE + TILE_GAP
		elif readout != "":
			draw_string(f, Vector2(right - side_w, y + 12.0), readout,
				HORIZONTAL_ALIGNMENT_RIGHT, side_w, 13, READ_BAD if bool(row.get("bad", false)) else READ_OK)
		if show_meter:
			var got: int = mini(int(row.got), target)
			var mx := right - COUNT_W - 6.0 - METER_W
			Icons.draw_meter(self, Vector2(mx, y + (4.0 if compact else 5.0)), METER_W, 7.0 if not compact else 6.0,
				float(got) / float(target))
			draw_string(f, Vector2(right - COUNT_W, y + 12.0), "%d/%d" % [got, target],
				HORIZONTAL_ALIGNMENT_RIGHT, COUNT_W, 13, Color(0.78, 0.73, 0.55))
		y += row_h
	if folded > 0:
		draw_string(f, Vector2(TEXT_X, y + 11.0), "+ %d done" % folded,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.47, 0.53, 0.48))
	elif extra > 0:
		draw_string(f, Vector2(TEXT_X, y + 11.0), "+ %d more" % extra,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.56, 0.53, 0.48))
