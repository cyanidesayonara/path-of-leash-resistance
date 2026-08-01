extends Control

# The settings screen.
#
# Drawn rather than assembled out of Labels: each row needs a name, a slider
# and a value to line up in columns, and the game's font is proportional, so
# padded text ("%-15s") lands ragged - the first attempt at this looked like
# a shopping list. Drawing it also sidesteps the web export's missing font
# fallbacks for everything except the row names, which are plain ASCII.

const W := 600.0
const ROW_H := 52.0
const ROWS_Y := 92.0
const FOOTER_H := 36.0    # room below the last row for the hint line
const NAME_X := 42.0
const BAR_X := 296.0
const BAR_W := 208.0
const BAR_H := 13.0

var main: Node2D
var sb: StyleBoxFlat
var sel: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m
	# the row count (and so the panel's height) is only known once main is
	# set - the web build drops the fullscreen row, and _ready() ran before
	# this with a guessed count
	_recentre()


func _row_count() -> int:
	# a sane guess before main is wired up; setup() re-centres for real
	return main.settings_rows().size() if main != null else 4


func _panel_height() -> float:
	return ROWS_Y + float(_row_count()) * ROW_H + FOOTER_H


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.075, 0.09, 0.93)
	sb.set_corner_radius_all(14)
	sb.border_width_top = 3
	sb.border_color = Color(0.86, 0.72, 0.36, 0.75)
	sel = StyleBoxFlat.new()
	sel.bg_color = Color(1.0, 0.88, 0.6, 0.11)
	sel.set_corner_radius_all(9)
	# centred on the actual viewport, not the 1280x720 reference - aspect
	# "expand" reveals more or less than that on most phone shapes
	_recentre()
	get_viewport().size_changed.connect(_recentre)


func _recentre() -> void:
	var vs := get_viewport_rect().size
	position = Vector2((vs.x - W) * 0.5, (vs.y - _panel_height()) * 0.5)


func _process(_delta: float) -> void:
	# only ever visible while the world is frozen, so this costs nothing
	if visible:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var f := ThemeDB.fallback_font
	var h := _panel_height()
	draw_style_box(sb, Rect2(0, 0, W, h))
	draw_string(f, Vector2(NAME_X, 46), "SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 27,
		Color(0.98, 0.94, 0.86))
	draw_line(Vector2(NAME_X, 62), Vector2(W - NAME_X, 62), Color(1, 1, 1, 0.14), 1.5)
	var rows: Array = main.settings_rows()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var y := ROWS_Y + float(i) * ROW_H
		var picked: bool = i == main.settings_idx
		if picked:
			draw_style_box(sel, Rect2(NAME_X - 14.0, y - 22.0, W - (NAME_X - 14.0) * 2.0, 40.0))
			# a small caret, and the arrows that say this row takes left/right
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(NAME_X - 24.0, y - 7.0), Vector2(NAME_X - 24.0, y + 5.0),
					Vector2(NAME_X - 15.0, y - 1.0)
				]), Color(0.98, 0.82, 0.42))
		var name_col := Color(0.98, 0.95, 0.88) if picked else Color(0.72, 0.72, 0.75)
		draw_string(f, Vector2(NAME_X, y + 6.0), String(row.name), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 20, name_col)
		if String(row.kind) == "slider":
			_slider(f, y, float(row.v), picked)
		else:
			_toggle(f, y, bool(row.v), picked)
	var hint := ("stick  choose     left/right  change     B  back" if main.pad_hints()
		else "W / S  choose     A / D  change     ESC  back")
	draw_string(f, Vector2(NAME_X, h - 24.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.78, 0.76, 0.72, 0.85))


func _slider(f: Font, y: float, v: float, picked: bool) -> void:
	var track := Rect2(BAR_X, y - BAR_H * 0.5, BAR_W, BAR_H)
	draw_rect(track, Color(1, 1, 1, 0.08))
	var fill := clampf(v, 0.0, 1.0) * BAR_W
	if fill > 1.0:
		var col := Color(0.98, 0.82, 0.42) if picked else Color(0.62, 0.6, 0.5)
		draw_rect(Rect2(track.position, Vector2(fill, BAR_H)), col)
	draw_rect(track, Color(1, 1, 1, 0.22), false, 1.2)
	# ten notches, so a step is a visible step rather than a guess
	for n in range(1, 10):
		var nx := BAR_X + BAR_W * float(n) / 10.0
		draw_line(Vector2(nx, track.position.y), Vector2(nx, track.end.y),
			Color(0, 0, 0, 0.28), 1.0)
	var txt := "%d%%" % int(round(v * 100.0))
	draw_string(f, Vector2(BAR_X + BAR_W + 16.0, y + 6.0), txt, HORIZONTAL_ALIGNMENT_LEFT,
		-1, 18, Color(0.95, 0.93, 0.88) if picked else Color(0.7, 0.7, 0.72))


func _toggle(f: Font, y: float, on: bool, picked: bool) -> void:
	var box := Rect2(BAR_X, y - 11.0, 52.0, 22.0)
	var track_col := Color(0.35, 0.55, 0.4, 0.85) if on else Color(1, 1, 1, 0.09)
	draw_rect(box, track_col)
	draw_rect(box, Color(1, 1, 1, 0.22), false, 1.2)
	var knob := Vector2(box.position.x + (38.0 if on else 14.0), y)
	draw_circle(knob, 8.0, Color(0.98, 0.82, 0.42) if picked else Color(0.72, 0.7, 0.62))
	draw_string(f, Vector2(BAR_X + BAR_W + 16.0, y + 6.0), "ON" if on else "OFF",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
		Color(0.95, 0.93, 0.88) if picked else Color(0.7, 0.7, 0.72))
