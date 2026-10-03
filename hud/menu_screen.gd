extends Control

# Draws whichever menu screen is up, from hud/menu_flow.gd's model, in
# hud/ui_kit.gd's look. Each screen is its own layout with its own accent,
# so choosing a walk, getting ready, dressing Millie and reading your
# progress no longer look like four copies of one list:
#
#   title     the name is chalked in the world; only the prompt bar here
#   walk      the walk's name is in the world too, in its own material; a
#             plaque under it says what you have done there
#   details   a card at the left: who walks, day or night, the weather, and
#             the controls, beside the pair it is about
#   shop      the wardrobe takes the screen: Millie on a spotlight, tabs,
#             and a list with a swatch for every item
#   progress  one table of every walk
#   pause     a grid you move through, not a line of shortcuts
#   walkcard  THIS WALK from the pause grid: the walk's name and its goals
#   confirm   the question before starting again or quitting
#   notice    the cards a walk ends on
#
# and every one of them has its buttons in the same bar along the bottom.

const Kit := preload("res://hud/ui_kit.gd")
const Icons := preload("res://hud/ui_icons.gd")
const Flow := preload("res://hud/menu_flow.gd")

const SHOP_W := 1040.0
const SHOP_H := 540.0
const SHOP_ROW_H := 44.0
const DETAILS_W := 400.0
const PROGRESS_W := 900.0
const PROGRESS_ROW_H := 30.0
const PAUSE_W := 560.0
const PAUSE_CELL_H := 58.0
const PAUSE_GAP := 12.0
const WALKCARD_W := 620.0
const CONFIRM_W := 460.0
const NOTICE_W := 660.0

var main: Node2D


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if main == null:
		return
	main.locked_nudge = maxf(0.0, float(main.locked_nudge) - delta)
	var s := Flow.screen(main)
	if s == "shop":
		main.shop_preview.position = shop_rect().position + Vector2(218.0, 262.0)
	# setting off: the screen that was up fades as the walk begins, rather
	# than blinking out. The name stays behind; it is part of the ground.
	if s == "walking" and _drawn in ["title", "walk", "details"]:
		_fade_from = _drawn
		_fade = FADE_S
	var fading := _fade > 0.0
	_fade = maxf(0.0, _fade - delta)
	modulate.a = (_fade / FADE_S) if s == "walking" and _fade > 0.0 else 1.0
	# nothing to draw during a walk, so nothing to redraw - except the frame
	# the fade ends on, which has to clear the last faded picture
	if s != "walking" or _drawn != "walking" or fading:
		queue_redraw()
	_drawn = s


const FADE_S := 0.6
var _drawn := ""
var _fade := 0.0
var _fade_from := ""


func _draw() -> void:
	if main == null:
		return
	var vs := get_viewport_rect().size
	var s := Flow.screen(main)
	if s == "walking" and _fade > 0.0:
		s = _fade_from
	match s:
		"walk":
			_walk(vs)
		"details":
			_details(vs)
		"shop":
			_shop(vs)
		"progress":
			_progress(vs)
		"pause":
			_pause(vs)
		"walkcard":
			_walk_card(vs)
		"confirm":
			_confirm(vs)
		"notice":
			_notice(vs)
	var a := 1.0
	if s == "title":
		# the one thing on the title screen, breathing so it reads as waiting
		a = 0.65 + 0.35 * sin(AnimClock.msec() / 420.0)
	Kit.prompt_bar(self, vs, Flow.prompts(main, s), a)


func _top(vs: Vector2, step: int) -> void:
	# centred: the touch MENU button lives in the top-left corner
	var bw := Kit.breadcrumb_w(Flow.STEP_NAMES)
	Kit.breadcrumb(self, Vector2(vs.x * 0.5 - bw * 0.5, 48.0), Flow.STEP_NAMES, step,
		Kit.accent(["walk", "details"][step]))
	Kit.purse(self, Vector2(vs.x - 40.0, 48.0), Game.total_stars(), Game.total_bones)


# where the walk's name is chalked, on screen
func _name_at() -> Vector2:
	var y: float = float(main.START_Y) - 190.0
	return main.get_global_transform_with_canvas() * Vector2(640.0, y)


func _walk(vs: Vector2) -> void:
	_top(vs, 0)
	var info := Flow.walk_info(main)
	var at := _name_at()
	var w := 560.0
	var shake: float = sin(float(main.locked_nudge) * 60.0) * 10.0 * (float(main.locked_nudge) / 0.35)
	var r := Rect2(vs.x * 0.5 - w * 0.5 + shake, at.y + 52.0, w, 48.0)
	Kit.card(self, r, Kit.accent("walk"), 12)
	var body := Kit.body()
	var row_y := r.position.y + 30.0
	if bool(info.locked):
		Kit.lock(self, Vector2(r.position.x + 34.0, row_y - 6.0), 16.0, Kit.INK_FAINT)
		draw_string(body, Vector2(r.position.x + 58.0, row_y), String(info.lines[0]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Kit.INK_SOFT)
		var have := float(info.have)
		var gate := maxf(1.0, float(info.gate))
		Icons.draw_meter(self, Vector2(r.end.x - 150.0, row_y - 10.0), 110.0, 8.0, have / gate)
		Icons.draw_star(self, Vector2(r.end.x - 24.0, row_y - 6.0), 8.0, true)
	elif info.has("stars"):
		for i in range(3):
			Icons.draw_star(self, Vector2(r.position.x + 34.0 + float(i) * 26.0, row_y - 6.0), 10.0,
				i < int(info.stars))
		var goals := "%d / %d goals" % [int(info.goals), int(info.goals_total)]
		draw_string(body, Vector2(r.position.x + 126.0, row_y), goals, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 17, Kit.INK)
		draw_string(body, Vector2(r.position.x, row_y), String(info.best), HORIZONTAL_ALIGNMENT_RIGHT,
			w - 28.0, 17, Kit.INK_SOFT)
	else:
		draw_string(body, Vector2(r.position.x, row_y), "     ".join(info.lines),
			HORIZONTAL_ALIGNMENT_CENTER, w, 16, Kit.INK_SOFT)
	# where this walk sits in the list: one dot a walk, hollow while locked
	var n := int(info.count)
	var dx := 14.0
	var x0 := vs.x * 0.5 - dx * float(n - 1) * 0.5 + shake
	for i in range(n):
		var p := Vector2(x0 + dx * float(i), at.y - 78.0)
		var lv: String = Game.CAROUSEL[i]
		if i == int(info.index):
			draw_circle(p, 4.5, Kit.GOLD)
		elif Game.is_unlocked(lv):
			draw_circle(p, 3.0, Color(1, 1, 1, 0.45))
		else:
			draw_arc(p, 3.0, 0, TAU, 10, Color(1, 1, 1, 0.3), 1.2)


func _details(vs: Vector2) -> void:
	_top(vs, 1)
	var acc := Kit.accent("details")
	var rows := Flow.details_rows(main)
	var legend := Flow.controls()
	var h := 70.0 + float(rows.size()) * 56.0 + 36.0 + ceilf(float(legend.size()) / 2.0) * 34.0 + 20.0
	var r := Rect2(48.0, vs.y * 0.5 - h * 0.5, DETAILS_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, r.position + Vector2(28.0, 46.0), "GET READY", 26, acc)
	var y := r.position.y + 72.0
	var f := Kit.display()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var picked: bool = i == int(main.details_idx)
		var rr := Rect2(r.position.x + 14.0, y, r.size.x - 28.0, 48.0)
		if picked:
			draw_rect(rr, Color(acc.r, acc.g, acc.b, 0.14))
			draw_rect(Rect2(rr.position, Vector2(4.0, rr.size.y)), acc)
		draw_string(f, Vector2(rr.position.x + 16.0, y + 30.0), String(row.name), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 15, Kit.INK_SOFT if picked else Kit.INK_FAINT)
		var fixed := bool(row.fixed)
		var val := String(row.value)
		var vx := rr.end.x - 40.0
		var vw := Kit.text_w(f, val, 21)
		var vcol: Color = Kit.INK_FAINT if fixed else (Kit.INK if picked else Kit.INK_SOFT)
		draw_string(f, Vector2(vx - vw, y + 32.0), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, vcol)
		if fixed:
			draw_string(Kit.body(), Vector2(vx - vw - 110.0, y + 31.0), "set for today",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Kit.INK_FAINT)
		elif picked:
			Kit.chevron(self, Vector2(vx - vw - 18.0, y + 24.0), 9.0, acc, true)
			Kit.chevron(self, Vector2(vx + 16.0, y + 24.0), 9.0, acc)
		y += 56.0
	y += 8.0
	draw_line(Vector2(r.position.x + 28.0, y), Vector2(r.end.x - 28.0, y), Color(1, 1, 1, 0.1), 1.5)
	y += 12.0
	# the controls, once, where the player is already looking before the
	# walk starts, instead of a line of them across the bottom of the walk
	for i in range(legend.size()):
		var it: Array = legend[i]
		var cx := r.position.x + 28.0 + float(i % 2) * 180.0
		var cy := y + float(i / 2) * 34.0
		var kw := Kit.keycap(self, Vector2(cx, cy), Prompts.key(String(it[0])), 13, 22.0)
		draw_string(Kit.body(), Vector2(cx + kw + 8.0, cy + 16.0), String(it[1]), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 14, Kit.INK_SOFT)


func shop_rect() -> Rect2:
	var vs := get_viewport_rect().size
	var w := minf(SHOP_W, vs.x - 80.0)
	return Rect2(vs.x * 0.5 - w * 0.5, vs.y * 0.5 - SHOP_H * 0.5 - 20.0, w, SHOP_H)


func _shop(vs: Vector2) -> void:
	var acc := Kit.accent("shop")
	var r := shop_rect()
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(36.0, 54.0), "WARDROBE", 30, acc)
	var f := Kit.display()
	var bones := str(Game.total_bones)
	var bx := r.end.x - 36.0 - Kit.text_w(f, bones, 22)
	Kit.heading(self, Vector2(bx, r.position.y + 52.0), bones, 22, Kit.INK)
	Icons.draw_bone(self, Vector2(bx - 20.0, r.position.y + 44.0), 12.0)
	# the tabs
	var tab := Flow.shop_tab_of(main)
	var tx := r.position.x + 440.0
	for k: String in Flow.SHOP_TABS:
		var nm: String = Flow.SHOP_TAB_NAMES[k]
		var on := k == tab
		Kit.heading(self, Vector2(tx, r.position.y + 104.0), nm, 17, acc if on else Kit.INK_FAINT)
		if on:
			draw_rect(Rect2(tx, r.position.y + 112.0, Kit.text_w(f, nm, 17), 3.0), acc)
		tx += Kit.text_w(f, nm, 17) + 34.0
	draw_line(Vector2(r.position.x + 440.0, r.position.y + 122.0), Vector2(r.end.x - 36.0, r.position.y + 122.0),
		Color(1, 1, 1, 0.1), 1.5)
	# Millie, on a spotlight, wearing what is highlighted
	var spot := r.position + Vector2(218.0, 262.0)
	draw_circle(spot, 150.0, Color(1, 1, 1, 0.04))
	draw_circle(spot, 118.0, Color(1, 1, 1, 0.05))
	draw_arc(spot, 150.0, 0, TAU, 48, Color(acc.r, acc.g, acc.b, 0.25), 2.0)
	var it: Dictionary = main.shop_items[main.shop_idx]
	var data: Dictionary = Flow.shop_data(main, String(it.kind), String(it.key))
	Kit.heading(self, Vector2(r.position.x + 36.0, r.position.y + 454.0), String(data.name), 22, Kit.INK,
		HORIZONTAL_ALIGNMENT_CENTER, 364.0)
	var st := Flow.shop_state(String(it.kind), String(it.key))
	var note := ""
	var ncol := Kit.INK_SOFT
	match st:
		"wearing":
			note = "She is wearing this"
			ncol = Kit.GOOD
		"owned":
			note = "Yours already"
		"afford":
			note = "%d bones" % int(data.cost)
			ncol = Kit.GOLD
		"short":
			note = "%d bones - %d more to go" % [int(data.cost), int(data.cost) - Game.total_bones]
			ncol = Kit.INK_FAINT
	var shake: float = sin(float(main.locked_nudge) * 60.0) * 8.0 * (float(main.locked_nudge) / 0.35)
	draw_string(Kit.body(), Vector2(r.position.x + 36.0 + shake, r.position.y + 482.0), note,
		HORIZONTAL_ALIGNMENT_CENTER, 364.0, 16, ncol)
	# the list for this tab
	var y := r.position.y + 136.0
	var lx := r.position.x + 440.0
	var lw := r.end.x - 36.0 - lx
	for i: int in Flow.shop_tab_items(main, tab):
		var row: Dictionary = main.shop_items[i]
		var key := String(row.key)
		var d: Dictionary = Flow.shop_data(main, tab, key)
		var picked: bool = i == int(main.shop_idx)
		var rr := Rect2(lx, y, lw, SHOP_ROW_H - 6.0)
		if picked:
			draw_rect(rr, Color(acc.r, acc.g, acc.b, 0.15))
			draw_rect(Rect2(rr.position, Vector2(4.0, rr.size.y)), acc)
		_swatch(Vector2(lx + 30.0, y + rr.size.y * 0.5), tab, key, d)
		draw_string(Kit.body(), Vector2(lx + 56.0, y + 25.0), String(d.name), HORIZONTAL_ALIGNMENT_LEFT, -1,
			18, Kit.INK if picked else Kit.INK_SOFT)
		var rs := Flow.shop_state(tab, key)
		var right := rr.end.x - 16.0
		match rs:
			"wearing":
				var tw := Kit.text_w(f, "WEARING", 13)
				draw_rect(Rect2(right - tw - 16.0, y + 9.0, tw + 16.0, 20.0), Color(Kit.GOOD.r, Kit.GOOD.g, Kit.GOOD.b, 0.22))
				draw_string(f, Vector2(right - tw - 8.0, y + 24.0), "WEARING", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Kit.GOOD)
			"owned":
				draw_string(f, Vector2(lx, y + 25.0), "OWNED", HORIZONTAL_ALIGNMENT_RIGHT, lw - 16.0, 13, Kit.INK_FAINT)
			_:
				var cost := str(int(d.cost))
				var ccol: Color = Kit.GOLD if rs == "afford" else Kit.INK_FAINT
				draw_string(f, Vector2(lx, y + 25.0), cost, HORIZONTAL_ALIGNMENT_RIGHT, lw - 16.0, 17, ccol)
				Icons.draw_bone(self, Vector2(right - Kit.text_w(f, cost, 17) - 18.0, y + 19.0), 9.0,
					Color(ccol.r, ccol.g, ccol.b, 0.9))
		y += SHOP_ROW_H


func _swatch(at: Vector2, kind: String, key: String, d: Dictionary) -> void:
	match kind:
		"collar":
			if key == "rainbow":
				var cols := [Color(0.85, 0.25, 0.25), Color(0.95, 0.6, 0.2), Color(0.95, 0.85, 0.3),
					Color(0.35, 0.75, 0.4), Color(0.3, 0.5, 0.85), Color(0.6, 0.35, 0.75)]
				for i in range(6):
					draw_arc(at, 10.0, TAU * float(i) / 6.0, TAU * float(i + 1) / 6.0, 6, cols[i], 6.0)
			else:
				draw_arc(at, 10.0, 0, TAU, 20, d.col, 6.0)
			draw_circle(at + Vector2(0, 11.0), 3.0, Color(0.85, 0.78, 0.45))
		"bandana":
			if key == "none":
				draw_arc(at, 11.0, 0, TAU, 20, Kit.INK_FAINT, 1.6)
				draw_line(at + Vector2(-7, 7), at + Vector2(7, -7), Kit.INK_FAINT, 1.6)
			else:
				draw_colored_polygon(PackedVector2Array([at + Vector2(-13, -7), at + Vector2(13, -7),
					at + Vector2(0, 11)]), d.col)
		"coat":
			draw_circle(at, 13.0, d.dark)
			draw_circle(at + Vector2(-1.5, -1.5), 11.0, d.fur)
			draw_circle(at + Vector2(3.0, 4.0), 5.0, d.mark)


func _progress(vs: Vector2) -> void:
	var acc := Kit.accent("progress")
	var rows := Flow.progress_rows(main)
	var w := minf(PROGRESS_W, vs.x - 80.0)
	var h := 120.0 + float(rows.size()) * PROGRESS_ROW_H + 18.0
	var r := Rect2(vs.x * 0.5 - w * 0.5, maxf(20.0, vs.y * 0.5 - h * 0.5 - 24.0), w, h)
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(36.0, 52.0), "YOUR WALKS", 28, acc)
	Kit.purse(self, Vector2(r.end.x - 36.0, r.position.y + 50.0), Game.total_stars(), Game.total_bones)
	var f := Kit.display()
	var body := Kit.body()
	var c_stars := r.position.x + w * 0.46
	var c_goals := r.position.x + w * 0.60
	var c_best := r.position.x + w * 0.76
	var hy := r.position.y + 94.0
	for col: Array in [[r.position.x + 36.0, "WALK"], [c_stars, "STARS"], [c_goals, "GOALS"], [c_best, "BEST"]]:
		draw_string(f, Vector2(float(col[0]), hy), String(col[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Kit.INK_FAINT)
	var y := hy + 12.0
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var by := y + float(i) * PROGRESS_ROW_H
		if i % 2 == 0:
			draw_rect(Rect2(r.position.x + 20.0, by, w - 40.0, PROGRESS_ROW_H), Color(1, 1, 1, 0.03))
		var base := by + 21.0
		var locked := bool(row.locked)
		var ncol: Color = Kit.INK_FAINT if locked else Kit.INK
		draw_string(f, Vector2(r.position.x + 36.0, base), String(row.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ncol)
		var nw := Kit.text_w(f, String(row.name), 16)
		draw_string(body, Vector2(r.position.x + 46.0 + nw, base), String(row.gloss), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 13, Kit.INK_FAINT)
		if locked:
			Kit.lock(self, Vector2(c_stars + 8.0, base - 5.0), 11.0, Kit.INK_FAINT)
			draw_string(body, Vector2(c_stars + 24.0, base), "opens at %d stars" % int(row.gate),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Kit.INK_FAINT)
			continue
		for s in range(3):
			Icons.draw_star(self, Vector2(c_stars + 8.0 + float(s) * 20.0, base - 5.0), 7.5, s < int(row.stars))
		var gt := maxi(1, int(row.goals_total))
		draw_string(body, Vector2(c_goals, base), "%d / %d" % [int(row.goals), int(row.goals_total)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Kit.INK_SOFT)
		Icons.draw_meter(self, Vector2(c_goals + 54.0, base - 9.0), 50.0, 6.0, float(row.goals) / float(gt),
			Kit.accent("progress"))
		draw_string(body, Vector2(c_best, base), String(row.best) if String(row.best) != "" else "-",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Kit.INK_SOFT)


func _pause(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var labels := Flow.pause_labels(main)
	var rows := (labels.size() + Flow.PAUSE_COLS - 1) / Flow.PAUSE_COLS
	var h := 110.0 + float(rows) * (PAUSE_CELL_H + PAUSE_GAP) + 14.0
	var r := Rect2(vs.x * 0.5 - PAUSE_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, PAUSE_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 50.0), "PAUSED", 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, PAUSE_W)
	var sub := "%s    %s" % [String(main._walk_name()), Flow.clock(float(main.elapsed))]
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 78.0), sub, HORIZONTAL_ALIGNMENT_CENTER,
		PAUSE_W, 15, Kit.INK_FAINT)
	var f := Kit.display()
	var cw := (PAUSE_W - 48.0 - PAUSE_GAP) * 0.5
	for i in range(labels.size()):
		var col := i % Flow.PAUSE_COLS
		var row := i / Flow.PAUSE_COLS
		var cell := Rect2(r.position.x + 24.0 + float(col) * (cw + PAUSE_GAP),
			r.position.y + 100.0 + float(row) * (PAUSE_CELL_H + PAUSE_GAP), cw, PAUSE_CELL_H)
		var picked: bool = i == int(main.pause_idx)
		draw_rect(cell, Color(acc.r, acc.g, acc.b, 0.16) if picked else Color(1, 1, 1, 0.04))
		draw_rect(cell, acc if picked else Color(1, 1, 1, 0.10), false, 2.0 if picked else 1.0)
		if picked:
			Kit.chevron(self, Vector2(cell.position.x + 20.0, cell.get_center().y), 8.0, acc)
		draw_string(f, Vector2(cell.position.x + 36.0, cell.get_center().y + 7.0), String(labels[i]),
			HORIZONTAL_ALIGNMENT_LEFT, cw - 44.0, 19, Kit.INK if picked else Kit.INK_SOFT)


func _walk_card(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var wc := Flow.walk_card(main)
	var goals: Array = wc.goals
	var lines := goals.size() if String(wc.lesson) == "" else 1
	var h := 130.0 + float(maxi(lines, 1)) * 30.0 + 20.0
	var r := Rect2(vs.x * 0.5 - WALKCARD_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, WALKCARD_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 52.0), String(wc.name), 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, WALKCARD_W)
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 80.0), "%s    %s" % [String(wc.gloss), String(wc.time)],
		HORIZONTAL_ALIGNMENT_CENTER, WALKCARD_W, 15, Kit.INK_FAINT)
	var y := r.position.y + 122.0
	var body := Kit.body()
	if String(wc.lesson) != "":
		draw_string(body, Vector2(r.position.x, y), String(wc.lesson), HORIZONTAL_ALIGNMENT_CENTER,
			WALKCARD_W, 17, Kit.INK_SOFT)
		return
	if goals.is_empty():
		draw_string(body, Vector2(r.position.x, y), "No goals on this walk.", HORIZONTAL_ALIGNMENT_CENTER,
			WALKCARD_W, 17, Kit.INK_FAINT)
		return
	for g: Dictionary in goals:
		var done := bool(g.done)
		Icons.draw_check(self, Vector2(r.position.x + 32.0, y - 11.0), 14.0,
			Icons.Check.DONE_NOW if done else (Icons.Check.PARTIAL if int(g.got) > 0 else Icons.Check.OPEN))
		draw_string(body, Vector2(r.position.x + 56.0, y), String(g.text), HORIZONTAL_ALIGNMENT_LEFT,
			WALKCARD_W - 180.0, 17, Kit.INK_FAINT if done else Kit.INK)
		if int(g.target) > 1 and not done:
			draw_string(body, Vector2(r.end.x - 110.0, y), "%d / %d" % [int(g.got), int(g.target)],
				HORIZONTAL_ALIGNMENT_RIGHT, 80.0, 15, Kit.INK_SOFT)
		y += 30.0


func _confirm(vs: Vector2) -> void:
	var acc := Kit.accent("notice")
	var c := Flow.confirm_card(main)
	var h := 150.0
	var r := Rect2(vs.x * 0.5 - CONFIRM_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, CONFIRM_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 56.0), String(c.title), 28, acc,
		HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_W)
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 100.0), String(c.body),
		HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_W, 19, Kit.INK_SOFT)


func _notice(vs: Vector2) -> void:
	var n := Flow.notice(main)
	var acc: Color = Kit.GOLD if main.finished else Kit.accent("notice")
	var body: Array = n.body
	var h := 92.0 + float(body.size()) * 26.0 + 24.0
	var r := Rect2(vs.x * 0.5 - NOTICE_W * 0.5, vs.y * 0.5 - h * 0.5 - 30.0, NOTICE_W, h)
	Kit.card(self, r, acc, 16)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 56.0), String(n.title), 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, NOTICE_W)
	var y := r.position.y + 96.0
	for line: String in body:
		draw_string(Kit.body(), Vector2(r.position.x, y), line, HORIZONTAL_ALIGNMENT_CENTER, NOTICE_W, 18,
			Kit.INK_SOFT)
		y += 26.0
