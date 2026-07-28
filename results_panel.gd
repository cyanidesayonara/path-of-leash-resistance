extends Control

# The end-of-walk card.
#
# It was one centred Label holding the whole summary as a single string, and
# with twelve goals on the boulevard the list ran off the bottom of the
# screen - the tail of the walk you had just finished, unreadable. A card that
# lays itself out cannot do that: the goals go into two columns when there are
# more than six, the panel measures its own height, and the whole thing is
# centred on what it actually contains.
#
# It also gets the icons: ticks, stars, bones and phone pips as shapes rather
# than ASCII, so the browser build looks like the desktop one.

const Icons := preload("res://ui_icons.gd")

const W := 900.0
const PAD := 34.0
const ROW_H := 25.0
const COL_SPLIT := 6        # more goals than this and it goes two-up

var main: Node2D
var sb: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.09, 0.93)
	sb.set_corner_radius_all(16)
	sb.border_width_top = 3
	sb.border_color = Color(0.86, 0.72, 0.36, 0.8)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var f := ThemeDB.fallback_font
	var d: Dictionary = main.results_data()
	var rows: Array = d.rows
	var two_col: bool = rows.size() > COL_SPLIT
	var per_col: int = int(ceil(float(rows.size()) / 2.0)) if two_col else rows.size()
	var extras: Array = d.lines
	# derived from the layout below, in the order it draws: title, stars, rows,
	# divider, tally, record lines, prompt. Guessing at this is how the prompt
	# ended up straddling the bottom edge of the card.
	var h := PAD + 224.0 + float(per_col) * ROW_H + float(extras.size()) * 22.0
	size = Vector2(W, h)
	# centre the card on what it holds, so a twelve-goal walk and a
	# three-goal walk are both framed
	position = Vector2((1280.0 - W) * 0.5, maxf(20.0, (720.0 - h) * 0.5))
	draw_style_box(sb, Rect2(0, 0, W, h))

	var y := PAD + 30.0
	draw_string(f, Vector2(0, y), String(d.title), HORIZONTAL_ALIGNMENT_CENTER, W, 30,
		Color(0.98, 0.95, 0.88))
	y += 34.0
	# the stars, drawn, with the line that comments on them
	var stars: int = int(d.stars)
	var sx := W * 0.5 - float(maxi(stars, 3)) * 15.0
	for i in range(maxi(stars, 3)):
		Icons.draw_star(self, Vector2(sx + float(i) * 30.0 + 15.0, y), 11.0, i < stars)
	if String(d.rating) != "":
		draw_string(f, Vector2(0, y + 30.0), String(d.rating), HORIZONTAL_ALIGNMENT_CENTER, W,
			17, Color(0.86, 0.84, 0.72))
	y += 50.0

	# the goals, in one or two columns
	var col_w: float = (W - PAD * 2.0) / (2.0 if two_col else 1.0)
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var col := 0 if not two_col else (0 if i < per_col else 1)
		var ry := y + float(i - col * per_col) * ROW_H
		var rx := PAD + float(col) * col_w
		Icons.draw_check(self, Vector2(rx, ry - 11.0), 14.0, int(row.state))
		var col_txt := Color(0.55, 0.58, 0.55)
		if int(row.state) == Icons.Check.DONE_NOW:
			col_txt = Color(0.72, 0.92, 0.76)
		elif int(row.state) == Icons.Check.DONE_BEFORE:
			col_txt = Color(0.55, 0.62, 0.56)
		elif int(row.state) == Icons.Check.PARTIAL:
			col_txt = Color(0.85, 0.80, 0.66)
		draw_multiline_string(f, Vector2(rx + 22.0, ry), String(row.text),
			HORIZONTAL_ALIGNMENT_LEFT, col_w - 30.0, 16, 1, col_txt)
	y += float(per_col) * ROW_H + 18.0
	draw_line(Vector2(PAD, y), Vector2(W - PAD, y), Color(1, 1, 1, 0.12), 1.5)
	y += 26.0

	# the tally, with icons instead of labels
	var tally_x := PAD + 6.0
	Icons.draw_bone(self, Vector2(tally_x + 8.0, y - 5.0), 11.0)
	draw_string(f, Vector2(tally_x + 26.0, y), str(int(d.bones)), HORIZONTAL_ALIGNMENT_LEFT,
		-1, 19, Color(0.96, 0.94, 0.88))
	var px := tally_x + 116.0
	for i in range(3):
		Icons.draw_phone_pip(self, Vector2(px + float(i) * 13.0, y - 13.0), 15.0,
			i < int(d.phone))
	draw_string(f, Vector2(px + 48.0, y), "phone", HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.72, 0.74, 0.78))
	draw_string(f, Vector2(0, y), "%ds" % int(d.time), HORIZONTAL_ALIGNMENT_CENTER, W, 19,
		Color(0.90, 0.88, 0.82))
	draw_string(f, Vector2(-PAD, y), "+%d bones from goals" % int(d.goal_bones),
		HORIZONTAL_ALIGNMENT_RIGHT, W, 16, Color(0.82, 0.80, 0.70))
	y += 28.0
	for line: String in extras:
		draw_string(f, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_CENTER, W, 16,
			Color(0.88, 0.84, 0.66))
		y += 22.0
	y += 14.0
	draw_string(f, Vector2(0, y), String(d.prompt), HORIZONTAL_ALIGNMENT_CENTER, W, 16,
		Color(0.78, 0.76, 0.72, 0.9))
