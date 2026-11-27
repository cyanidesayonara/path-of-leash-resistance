extends Control

# The settings screen.
#
# Drawn rather than assembled out of Labels: each row needs a name, a slider
# and a value to line up in columns, and the game's font is proportional, so
# padded text ("%-15s") lands ragged - the first attempt at this looked like
# a shopping list. Drawing it also sidesteps the web export's missing font
# fallbacks for everything except the row names, which are plain ASCII.

const W := 600.0
const ROW_H := 44.0
const ROWS_Y := 84.0
const FOOTER_H := 12.0
const NAME_X := 42.0
const BAR_X := 296.0
const BAR_W := 208.0
const BAR_H := 13.0

const Kit := preload("res://hud/ui_kit.gd")
const Flow := preload("res://hud/menu_flow.gd")
const UiScale := preload("res://hud/ui_scale.gd")

var main: Node2D
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


func _layout(vs: Vector2) -> Dictionary:
	var n := _row_count()
	var ins := UiScale.safe_insets(get_window() if is_inside_tree() else null)
	var items := Flow.prompts(main, "settings") if main != null else []
	var top_limit := maxf(12.0, ins.y + 8.0)
	var bottom_limit := (Kit.prompt_bar_top(self, vs, items) - 14.0) if not items.is_empty() else (vs.y - Kit.BAR_FROM_BOTTOM - ins.w - 14.0)
	var avail_h := maxf(200.0, bottom_limit - top_limit)
	var avail_w := maxf(300.0, vs.x - 28.0 - ins.x - ins.z)
	var two_col := (84.0 + float(n) * 38.0 + 12.0 > avail_h) and avail_w >= 760.0
	var cols := 2 if two_col else 1
	var per_col := int(ceil(float(n) / 2.0)) if two_col else n
	var compact := avail_h < 420.0
	var title_px := 23 if compact else 27
	var title_y := 38.0 if compact else 46.0
	var line_y := 52.0 if compact else 62.0
	var gap_y := 8.0 if compact else 10.0
	var footer_h := 10.0 if compact else 12.0
	var row_h := clampf(floor((avail_h - line_y - gap_y - footer_h) / float(maxi(per_col, 1))), 28.0, ROW_H)
	var h := line_y + gap_y + float(per_col) * row_h + footer_h
	var w := minf(900.0, avail_w) if two_col else minf(W, avail_w)
	var x0 := clampf(ins.x + (vs.x - ins.x - ins.z - w) * 0.5, ins.x + 8.0, maxf(ins.x + 8.0, vs.x - ins.z - w - 8.0))
	var y0 := clampf(top_limit + (avail_h - h) * 0.5, top_limit, maxf(top_limit, bottom_limit - h))
	return {
		"rect": Rect2(x0, y0, w, h),
		"two_col": two_col,
		"cols": cols,
		"per_col": per_col,
		"title_px": title_px,
		"title_y": title_y,
		"line_y": line_y,
		"first_row_y": line_y + gap_y + row_h * 0.5,
		"row_h": row_h,
	}


func _panel_height() -> float:
	return float(_layout(get_viewport_rect().size).rect.size.y)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var acc := Kit.accent("settings")
	sel = StyleBoxFlat.new()
	sel.bg_color = Color(acc.r, acc.g, acc.b, 0.13)
	sel.set_corner_radius_all(9)
	# centred on the actual viewport, not the 1280x720 reference - aspect
	# "expand" reveals more or less than that on most phone shapes
	_recentre()
	get_viewport().size_changed.connect(_recentre)


func _recentre() -> void:
	var lay := _layout(get_viewport_rect().size)
	var r: Rect2 = lay.rect
	size = r.size
	position = r.position


func _process(_delta: float) -> void:
	# only ever visible while the world is frozen, so this costs nothing
	if visible:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var f := ThemeDB.fallback_font
	var lay := _layout(get_viewport_rect().size)
	var r: Rect2 = lay.rect
	if not r.position.is_equal_approx(position):
		position = r.position
	size = r.size
	var w := r.size.x
	var h := r.size.y
	var two_col := bool(lay.two_col)
	var per_col := int(lay.per_col)
	var row_h := float(lay.row_h)
	var first_y := float(lay.first_row_y)
	var line_y := float(lay.line_y)
	var pad_x := 32.0 if two_col else NAME_X
	Kit.card(self, Rect2(0, 0, w, h), Kit.accent("settings"))
	Kit.heading(self, Vector2(pad_x, float(lay.title_y)), I18n.t("settings_title"), int(lay.title_px), Kit.accent("settings"))
	draw_line(Vector2(pad_x, line_y), Vector2(w - pad_x, line_y), Color(1, 1, 1, 0.14), 1.5)
	var col_gap := 34.0
	var col_w := (w - pad_x * 2.0 - col_gap) * 0.5 if two_col else (w - pad_x * 2.0)
	var name_px := 15 if (two_col or row_h < 38.0) else 18
	var val_px := 15 if (two_col or row_h < 38.0) else 18
	var box_h := clampf(row_h - 8.0, 22.0, 36.0)
	var rows: Array = main.settings_rows()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var col := 0 if not two_col else (i / per_col)
		var ri := i if not two_col else (i % per_col)
		var cx := pad_x + float(col) * (col_w + col_gap)
		var y := first_y + float(ri) * row_h
		var picked: bool = i == main.settings_idx
		if picked:
			draw_style_box(sel, Rect2(cx - 12.0, y - box_h * 0.5, col_w + 24.0, box_h))
			# a small caret, and the arrows that say this row takes left/right
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(cx - 21.0, y - 5.5), Vector2(cx - 21.0, y + 5.5),
					Vector2(cx - 13.0, y)
				]), Kit.accent("settings"))
		var name_col := Kit.INK if picked else Kit.INK_DIM
		var bar_w := 130.0 if two_col else minf(BAR_W, maxf(120.0, col_w - 270.0))
		var val_room := 52.0 if two_col else 64.0
		var bar_x := cx + col_w - bar_w - val_room
		var name_room := maxf(80.0, bar_x - cx - 10.0)
		draw_string(Kit.display(), Vector2(cx, y + float(name_px) * 0.34), String(row.name), HORIZONTAL_ALIGNMENT_LEFT,
			name_room, name_px, name_col)
		if String(row.kind) == "slider":
			_slider(f, bar_x, bar_w, y, float(row.v), val_px, picked)
		elif String(row.kind) == "choice":
			_choice(f, bar_x, bar_w + val_room, y, String(row.text), val_px, picked)
		elif String(row.kind) == "submenu":
			_submenu(f, bar_x, bar_w + val_room, y, String(row.text), val_px, picked)
		else:
			_toggle(f, bar_x, bar_w, y, bool(row.v), val_px, picked)
	# the buttons are on the prompt bar along the bottom (menu_screen.gd)


func _slider(f: Font, bx: float, bw: float, y: float, v: float, px: int, picked: bool) -> void:
	var track := Rect2(bx, y - BAR_H * 0.5, bw, BAR_H)
	draw_rect(track, Color(1, 1, 1, 0.08))
	var fill := clampf(v, 0.0, 1.0) * bw
	if fill > 1.0:
		var col := Kit.SAFFRON if picked else Kit.INK_MUTE
		draw_rect(Rect2(track.position, Vector2(fill, BAR_H)), col)
	draw_rect(track, Color(1, 1, 1, 0.22), false, 1.2)
	# ten notches, so a step is a visible step rather than a guess
	for n in range(1, 10):
		var nx := bx + bw * float(n) / 10.0
		draw_line(Vector2(nx, track.position.y), Vector2(nx, track.end.y),
			Color(0, 0, 0, 0.28), 1.0)
	var txt := "%d%%" % int(round(v * 100.0))
	draw_string(f, Vector2(bx + bw + 12.0, y + float(px) * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT,
		-1, px, Kit.INK if picked else Kit.INK_DIM)


# one of a list, stepped with left/right: the value between two arrows
func _choice(f: Font, bx: float, bw: float, y: float, txt: String, px: int, picked: bool) -> void:
	var col := Kit.INK if picked else Kit.INK_DIM
	var arrow := Kit.accent("settings") if picked else Color(1, 1, 1, 0.22)
	draw_colored_polygon(PackedVector2Array([Vector2(bx + 8.0, y - 6.5), Vector2(bx, y), Vector2(bx + 8.0, y + 6.5)]), arrow)
	draw_string(f, Vector2(bx + 14.0, y + float(px) * 0.34), txt, HORIZONTAL_ALIGNMENT_CENTER, bw - 28.0, px, col)
	draw_colored_polygon(PackedVector2Array([Vector2(bx + bw - 8.0, y - 6.5), Vector2(bx + bw, y), Vector2(bx + bw - 8.0, y + 6.5)]), arrow)


func _submenu(f: Font, bx: float, bw: float, y: float, txt: String, px: int, picked: bool) -> void:
	var col := Kit.INK if picked else Kit.INK_DIM
	var arrow := Kit.accent("settings") if picked else Color(1, 1, 1, 0.30)
	draw_string(f, Vector2(bx, y + float(px) * 0.34), txt, HORIZONTAL_ALIGNMENT_RIGHT, bw - 18.0, px, col)
	draw_colored_polygon(PackedVector2Array([Vector2(bx + bw - 8.0, y - 6.5), Vector2(bx + bw, y), Vector2(bx + bw - 8.0, y + 6.5)]), arrow)


func _toggle(f: Font, bx: float, bw: float, y: float, on: bool, px: int, picked: bool) -> void:
	var box := Rect2(bx, y - 10.5, 50.0, 21.0)
	var track_col := Color(Kit.TURQUOISE, 0.75) if on else Color(1, 1, 1, 0.09)
	draw_rect(box, track_col)
	draw_rect(box, Color(1, 1, 1, 0.22), false, 1.2)
	var knob := Vector2(box.position.x + (37.0 if on else 13.0), y)
	draw_circle(knob, 7.5, Kit.SAFFRON if picked else Kit.INK_SOFT)
	draw_string(f, Vector2(bx + bw + 12.0, y + float(px) * 0.34), I18n.t("setting_on" if on else "setting_off"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, px,
		Kit.INK if picked else Kit.INK_DIM)
