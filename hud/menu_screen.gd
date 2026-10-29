extends Control

# Draws whichever menu screen is up, from hud/menu_flow.gd's model, in
# hud/ui_kit.gd's look. Each screen is its own layout with its own accent,
# so choosing a walk, getting ready, dressing Millie and reading your
# progress no longer look like four copies of one list:
#
#   title     the main menu: the name is chalked in the world, and the
#             list of where to go is a card at the left, under it
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

const MAIN_W := 300.0
const MAIN_ROW_H := 44.0
const SHOP_W := 1040.0
const SHOP_H := 540.0
const SHOP_ROW_H := 44.0
const DETAILS_W := 400.0
const PROGRESS_W := 900.0
const PROGRESS_ROW_H := 32.0
const PAUSE_W := 560.0
const PAUSE_CELL_H := 58.0
const PAUSE_GAP := 12.0
const WALKCARD_W := 620.0
const CONFIRM_W := 460.0
const FIRST_ROW_H := 50.0
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
	if s != _drawn and s != "walking":
		_open_t = 0.0
		if s == "shop":
			_shop_t = 0.45
	_open_t = minf(1.0, _open_t + delta / OPEN_S)
	if s == "shop":
		_shop_t += delta
		main.shop_preview.position = shop_rect().position + Vector2(218.0, 262.0)
		var ang := -PI * 0.5 + sin(_shop_t * 0.85) * 0.68
		main.shop_preview.facing = Vector2.from_angle(ang)
		main.shop_preview.hip_dir = -main.shop_preview.facing.rotated(sin(_shop_t * 1.7) * 0.08)
		main.shop_preview.gait = _shop_t * 2.2
		main.shop_preview.hop = maxf(0.0, float(main.shop_preview.hop) - delta * 36.0)
		main.shop_preview.bark_anim = maxf(0.0, float(main.shop_preview.bark_anim) - delta)
		main.shop_preview.queue_redraw()
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
const OPEN_S := 0.14
var _drawn := ""
var _fade := 0.0
var _fade_from := ""
var _open_t := 1.0
var _shop_t := 0.45


func _card_pop(center: Vector2) -> void:
	var u := 1.0 - pow(1.0 - clampf(_open_t, 0.0, 1.0), 3.0)
	var sc := lerpf(0.965, 1.0, u)
	draw_set_transform(center - center * sc, 0.0, Vector2(sc, sc))


func _draw() -> void:
	if main == null:
		return
	var vs := get_viewport_rect().size
	var s := Flow.screen(main)
	if s == "walking" and _fade > 0.0:
		s = _fade_from
	match s:
		"title":
			_main(vs)
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
	Kit.prompt_bar(self, vs, Flow.prompts(main, s))


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


# The main menu: one row per place to go, picked with up/down. The card sits
# at the left, below the chalked name and clear of the pair, in the band
# between the name and the prompt bar; on a small screen the rows close up
# to fit that band rather than run under the bar.
func _main(vs: Vector2) -> void:
	var acc := Kit.accent("title")
	var labels := Flow.main_labels(main)
	var n := labels.size()
	var top := maxf(24.0, _name_at().y + 76.0)
	var bottom := vs.y - Kit.BAR_FROM_BOTTOM - 24.0
	var pad := 14.0
	var row_h := clampf((bottom - top - pad * 2.0) / float(n), 30.0, MAIN_ROW_H)
	var h := pad * 2.0 + row_h * float(n)
	var y0 := maxf(top, (top + bottom) * 0.5 - h * 0.5)
	var r := Rect2(48.0, y0, MAIN_W, h)
	Kit.card(self, r, acc)
	var f := Kit.display()
	var px := 20 if row_h >= 40.0 else 17
	var picked_i := clampi(int(main.main_idx), 0, n - 1)
	for i in range(n):
		var rr := Rect2(r.position.x + 12.0, r.position.y + pad + row_h * float(i), r.size.x - 24.0, row_h)
		var picked := i == picked_i
		if picked:
			draw_rect(rr, Color(acc.r, acc.g, acc.b, 0.14))
			draw_rect(Rect2(rr.position, Vector2(4.0, rr.size.y)), acc)
			Kit.chevron(self, Vector2(rr.position.x + 22.0, rr.get_center().y), 8.0, acc)
		draw_string(f, Vector2(rr.position.x + 40.0, rr.get_center().y + float(px) * 0.36), String(labels[i]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, px, Kit.INK if picked else Kit.INK_SOFT)
	Kit.purse(self, Vector2(vs.x - 40.0, 48.0), Game.total_stars(), Game.total_bones)


func _walk(vs: Vector2) -> void:
	_top(vs, 0)
	var info := Flow.walk_info(main)
	# The walk's name and what it means are on the ground, in the walk's own
	# stuff and the gloss under it (main._draw_ground_title). This strip under
	# them says only what the ground cannot: how this walk has gone, or what
	# opens it. One line, so it never repeats the name.
	# It always sits in the same place, over the prompt bar at the foot of the
	# screen, whichever walk is in view, with the walk dots above it.
	var w := minf(560.0, vs.x - 48.0)
	var shake: float = sin(float(main.locked_nudge) * 60.0) * 10.0 * (float(main.locked_nudge) / 0.35)
	var h := 50.0
	var top := vs.y - Kit.BAR_FROM_BOTTOM - 22.0 - h
	var r := Rect2(vs.x * 0.5 - w * 0.5 + shake, top, w, h)
	Kit.card(self, r, Kit.accent("walk"), 12)
	# browse arrows at its two ends: the name on the ground is left whole
	Kit.chevron(self, Vector2(r.position.x - 22.0, r.get_center().y), 18.0, Kit.GOLD, true)
	Kit.chevron(self, Vector2(r.end.x + 22.0, r.get_center().y), 18.0, Kit.GOLD)
	var body := Kit.body()
	var row_y := r.position.y + 32.0
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
		draw_string(body, Vector2(r.position.x, row_y), "free play" if Game.free_play else String(info.best),
			HORIZONTAL_ALIGNMENT_RIGHT, w - 28.0, 17, Kit.GOLD if Game.free_play else Kit.INK_SOFT)
	else:
		draw_string(body, Vector2(r.position.x, row_y), "     ".join(info.lines),
			HORIZONTAL_ALIGNMENT_CENTER, w, 16, Kit.INK_SOFT)
	# where this walk sits in the list: one dot a walk, hollow while locked
	var n := int(info.count)
	var dx := 14.0
	var x0 := vs.x * 0.5 - dx * float(n - 1) * 0.5 + shake
	for i in range(n):
		var p := Vector2(x0 + dx * float(i), r.position.y - 14.0)
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
	var row_h := 46.0
	var h := 68.0 + float(rows.size()) * row_h + 16.0 + ceilf(float(legend.size()) / 2.0) * 32.0 + 16.0
	# anchored over the prompt bar, like the walk select's card, so the walk's
	# name and gloss on the ground above it are never under it
	var r := Rect2(48.0, maxf(8.0, vs.y - Kit.BAR_FROM_BOTTOM - 22.0 - h), DETAILS_W, h)
	Kit.card(self, r, acc)
	Kit.heading(self, r.position + Vector2(28.0, 44.0), "GET READY", 25, acc)
	var y := r.position.y + 66.0
	var f := Kit.display()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var picked: bool = i == int(main.details_idx)
		var rr := Rect2(r.position.x + 14.0, y, r.size.x - 28.0, 40.0)
		if picked:
			draw_rect(rr, Color(acc.r, acc.g, acc.b, 0.14))
			draw_rect(Rect2(rr.position, Vector2(4.0, rr.size.y)), acc)
		draw_string(f, Vector2(rr.position.x + 16.0, y + 26.0), String(row.name), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 15, Kit.INK_SOFT if picked else Kit.INK_FAINT)
		var fixed := bool(row.fixed)
		var val := String(row.value)
		var vx := rr.end.x - 40.0
		var vw := Kit.text_w(f, val, 20)
		var unlocked: bool = bool(row.get("unlocked", true))
		var vcol: Color = Kit.INK_FAINT if (fixed or not unlocked) else (Kit.INK if picked else Kit.INK_SOFT)
		draw_string(f, Vector2(vx - vw, y + 28.0), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, vcol)
		if fixed:
			draw_string(Kit.body(), Vector2(vx - vw - 110.0, y + 27.0), "set for today",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Kit.INK_FAINT)
		elif not unlocked:
			Kit.lock(self, Vector2(vx - vw - 18.0, y + 20.0), 12.0, Kit.INK_FAINT)
		elif picked:
			Kit.chevron(self, Vector2(vx - vw - 18.0, y + 20.0), 9.0, acc, true)
			Kit.chevron(self, Vector2(vx + 16.0, y + 20.0), 9.0, acc)
			if row.has("trait"):
				var tr := String(row.trait)
				draw_string(Kit.body(), Vector2(vx - vw - 28.0 - Kit.text_w(Kit.body(), tr, 12), y + 26.0),
					tr, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Kit.INK_SOFT)
		y += row_h
	y += 4.0
	draw_line(Vector2(r.position.x + 28.0, y), Vector2(r.end.x - 28.0, y), Color(1, 1, 1, 0.1), 1.5)
	y += 8.0
	# the controls, once, where the player is already looking before the
	# walk starts, instead of a line of them across the bottom of the walk
	for i in range(legend.size()):
		var it: Array = legend[i]
		var cx := r.position.x + 28.0 + float(i % 2) * 180.0
		var cy := y + float(i / 2) * 32.0
		var kw := Kit.keycap(self, Vector2(cx, cy), Prompts.key(String(it[0])), 13, 20.0)
		draw_string(Kit.body(), Vector2(cx + kw + 8.0, cy + 15.0), String(it[1]), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 13, Kit.INK_SOFT)


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
			note = "%s is wearing this" % Game.dog_name()
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


static func progress_row_h(vs: Vector2, row_count: int) -> float:
	var top_limit := 16.0
	var bottom_limit := vs.y - Kit.BAR_FROM_BOTTOM - 16.0
	var avail := maxf(120.0, bottom_limit - top_limit - 102.0)
	return clampf(avail / float(maxi(row_count, 1)), 6.0, PROGRESS_ROW_H)


static func progress_rect(vs: Vector2, row_count: int) -> Rect2:
	var w := minf(PROGRESS_W, vs.x - 80.0)
	var rh := progress_row_h(vs, row_count)
	var h := 88.0 + float(row_count) * rh + 14.0
	var top_limit := 16.0
	var bottom_limit := vs.y - Kit.BAR_FROM_BOTTOM - 16.0
	var y0 := clampf((top_limit + bottom_limit - h) * 0.5, top_limit, maxf(top_limit, bottom_limit - h))
	return Rect2(vs.x * 0.5 - w * 0.5, y0, w, h)


func _progress(vs: Vector2) -> void:
	var acc := Kit.accent("progress")
	var rows := Flow.progress_rows(main)
	var rh := progress_row_h(vs, rows.size())
	var r := progress_rect(vs, rows.size())
	var w := r.size.x
	_card_pop(r.get_center())
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(36.0, 44.0), "YOUR WALKS", 26, acc)
	Kit.purse(self, Vector2(r.end.x - 36.0, r.position.y + 42.0), Game.total_stars(), Game.total_bones)
	var f := Kit.display()
	var body := Kit.body()
	var c_stars := r.position.x + w * 0.46
	var c_goals := r.position.x + w * 0.60
	var c_best := r.position.x + w * 0.76
	var hy := r.position.y + 78.0
	for col: Array in [[r.position.x + 36.0, "WALK"], [c_stars, "STARS"], [c_goals, "GOALS"], [c_best, "BEST"]]:
		draw_string(f, Vector2(float(col[0]), hy), String(col[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Kit.INK_FAINT)
	var y := hy + 10.0
	var font_px := 17 if rh >= 28.0 else (15 if rh >= 16.0 else (13 if rh >= 11.0 else 10))
	var sub_px := 15 if rh >= 28.0 else (14 if rh >= 16.0 else (11 if rh >= 11.0 else 9))
	var star_r := 7.5 if rh >= 16.0 else (5.5 if rh >= 11.0 else 4.0)
	var star_gap := 20.0 if rh >= 16.0 else (15.0 if rh >= 11.0 else 11.0)
	var lock_sz := 11.0 if rh >= 16.0 else (8.5 if rh >= 11.0 else 6.5)
	var meter_h := 6.0 if rh >= 16.0 else (4.5 if rh >= 11.0 else 3.5)
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var by := y + float(i) * rh
		var current := String(row.id) == Game.level_id
		if current:
			draw_rect(Rect2(r.position.x + 20.0, by, w - 40.0, rh), Color(acc.r, acc.g, acc.b, 0.11))
			draw_rect(Rect2(r.position.x + 20.0, by, 3.0, rh), acc)
		elif i % 2 == 0:
			draw_rect(Rect2(r.position.x + 20.0, by, w - 40.0, rh), Color(1, 1, 1, 0.03))
		var base := by + rh * 0.70
		var locked := bool(row.locked)
		var ncol: Color = Kit.INK_SOFT if locked else Kit.INK
		draw_string(f, Vector2(r.position.x + 36.0, base), String(row.name), HORIZONTAL_ALIGNMENT_LEFT, -1, font_px, ncol)
		var nw := Kit.text_w(f, String(row.name), font_px)
		var gloss_w := maxf(40.0, c_stars - (r.position.x + 54.0 + nw))
		draw_string(body, Vector2(r.position.x + 46.0 + nw, base), String(row.gloss), HORIZONTAL_ALIGNMENT_LEFT,
			gloss_w, sub_px, Kit.INK_SOFT)
		if locked:
			Kit.lock(self, Vector2(c_stars + 8.0, base - 5.0), lock_sz, Kit.INK_FAINT)
			draw_string(body, Vector2(c_stars + 24.0, base), "opens at %d stars" % int(row.gate),
				HORIZONTAL_ALIGNMENT_LEFT, -1, sub_px, Kit.INK_SOFT)
			continue
		for s in range(3):
			Icons.draw_star(self, Vector2(c_stars + 8.0 + float(s) * star_gap, base - 5.0), star_r, s < int(row.stars))
		var gt := maxi(1, int(row.goals_total))
		var all_goals := int(row.goals) >= gt and gt > 0
		draw_string(body, Vector2(c_goals, base), "%d / %d" % [int(row.goals), int(row.goals_total)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, sub_px, Kit.GOOD if all_goals else Kit.INK_SOFT)
		Icons.draw_meter(self, Vector2(c_goals + 54.0, base - 9.0), 50.0, meter_h, float(row.goals) / float(gt),
			Kit.GOLD if all_goals else Kit.accent("progress"))
		draw_string(body, Vector2(c_best, base), String(row.best) if String(row.best) != "" else "-",
			HORIZONTAL_ALIGNMENT_LEFT, -1, sub_px, Kit.INK_SOFT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _pause(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var labels := Flow.pause_labels(main)
	var rows := (labels.size() + Flow.PAUSE_COLS - 1) / Flow.PAUSE_COLS
	var h := 110.0 + float(rows) * (PAUSE_CELL_H + PAUSE_GAP) + 14.0
	var r := Rect2(vs.x * 0.5 - PAUSE_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, PAUSE_W, h)
	_card_pop(r.get_center())
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 50.0), "PAUSED", 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, PAUSE_W)
	var sub := "%s    %s" % [String(main._walk_name()), Flow.clock(float(main.elapsed))]
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 80.0), sub, HORIZONTAL_ALIGNMENT_CENTER,
		PAUSE_W, 18, Kit.INK)
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
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


const WALKCARD_COL_SPLIT := 6
const WALKCARD_TWO_COL_W := 860.0


static func walk_card_rect(vs: Vector2, goal_count: int, has_lesson := false) -> Rect2:
	var two_col := not has_lesson and goal_count > WALKCARD_COL_SPLIT
	var per_col := int(ceil(float(goal_count) / 2.0)) if two_col else (1 if has_lesson else maxi(goal_count, 1))
	var w := minf(WALKCARD_TWO_COL_W if two_col else WALKCARD_W, vs.x - 48.0)
	var h := 130.0 + float(per_col) * 28.0 + 20.0
	var bottom_limit := vs.y - Kit.BAR_FROM_BOTTOM - 16.0
	var y0 := clampf(vs.y * 0.5 - h * 0.5 - 20.0, 16.0, maxf(16.0, bottom_limit - h))
	return Rect2(vs.x * 0.5 - w * 0.5, y0, w, h)


func _walk_card(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var wc := Flow.walk_card(main)
	var goals: Array = wc.goals
	var has_lesson := String(wc.lesson) != ""
	var two_col := not has_lesson and goals.size() > WALKCARD_COL_SPLIT
	var per_col := int(ceil(float(goals.size()) / 2.0)) if two_col else maxi(goals.size(), 1)
	var r := walk_card_rect(vs, goals.size(), has_lesson)
	var w := r.size.x
	_card_pop(r.get_center())
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 52.0), String(wc.name).to_upper(), 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, w)
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 82.0), "%s    %s" % [String(wc.gloss), String(wc.time)],
		HORIZONTAL_ALIGNMENT_CENTER, w, 18, Kit.INK)
	var y := r.position.y + 122.0
	var body := Kit.body()
	if has_lesson:
		draw_string(body, Vector2(r.position.x, y), String(wc.lesson), HORIZONTAL_ALIGNMENT_CENTER,
			w, 17, Kit.INK_SOFT)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if goals.is_empty():
		draw_string(body, Vector2(r.position.x, y), "No goals on this walk.", HORIZONTAL_ALIGNMENT_CENTER,
			w, 17, Kit.INK_FAINT)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var col_w := (w - 48.0) / (2.0 if two_col else 1.0)
	for i in range(goals.size()):
		var g: Dictionary = goals[i]
		var col := 0 if not two_col else (0 if i < per_col else 1)
		var ry := y + float(i - col * per_col) * 28.0
		var rx := r.position.x + 24.0 + float(col) * col_w
		var done := bool(g.done)
		Icons.draw_check(self, Vector2(rx + 6.0, ry - 11.0), 14.0, int(g.state))
		var count_room := 64.0 if (int(g.target) > 1 and not done) else 12.0
		draw_string(body, Vector2(rx + 28.0, ry), String(g.text), HORIZONTAL_ALIGNMENT_LEFT,
			col_w - 28.0 - count_room, 16 if two_col else 17, Kit.INK_FAINT if done else Kit.INK)
		if int(g.target) > 1 and not done:
			draw_string(body, Vector2(rx + col_w - 68.0, ry), "%d / %d" % [int(g.got), int(g.target)],
				HORIZONTAL_ALIGNMENT_RIGHT, 56.0, 14, Kit.INK_SOFT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _confirm(vs: Vector2) -> void:
	var acc := Kit.accent("notice")
	var c := Flow.confirm_card(main)
	var first := String(main.confirm_id) == "first"
	var lines := String(c.body).split("\n")
	var opts: Array = Flow.FIRST_OPTIONS if first else []
	var extra := 16.0 + FIRST_ROW_H * float(opts.size()) + 44.0 if first else 0.0
	var h := 150.0 + extra + 26.0 * float(lines.size() - 1)
	var r := Rect2(vs.x * 0.5 - CONFIRM_W * 0.5, vs.y * 0.5 - h * 0.5 - 20.0, CONFIRM_W, h)
	_card_pop(r.get_center())
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 56.0), String(c.title), 28, acc,
		HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_W)
	for i in range(lines.size()):
		draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 100.0 + 26.0 * i), lines[i],
			HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_W, 19, Kit.INK_SOFT)
	if first:
		# the two answers, a list like the main menu's
		var oy := r.position.y + 124.0 + 26.0 * float(lines.size() - 1)
		var f := Kit.display()
		for i in range(opts.size()):
			var rr := Rect2(r.position.x + 28.0, oy + FIRST_ROW_H * float(i), CONFIRM_W - 56.0, FIRST_ROW_H - 6.0)
			var picked: bool = i == int(main.first_idx)
			draw_rect(rr, Color(acc.r, acc.g, acc.b, 0.16) if picked else Color(1, 1, 1, 0.04))
			draw_rect(rr, acc if picked else Color(1, 1, 1, 0.10), false, 2.0 if picked else 1.0)
			if picked:
				Kit.chevron(self, Vector2(rr.position.x + 20.0, rr.get_center().y), 8.0, acc)
			draw_string(f, Vector2(rr.position.x + 38.0, rr.get_center().y + 6.5), String(opts[i]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.INK if picked else Kit.INK_SOFT)
		# the "don't ask again" box: the prompt bar's key ticks it, and the
		# card shows whether it is ticked
		var label := "Don't ask me again"
		var tw: float = Kit.body().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var box := 16.0
		var x0 := r.position.x + CONFIRM_W * 0.5 - (box + 10.0 + tw) * 0.5
		var by := oy + FIRST_ROW_H * float(opts.size()) + 12.0
		Icons.draw_check(self, Vector2(x0, by), box,
			Icons.Check.DONE_NOW if not Game.ask_tutorial else Icons.Check.OPEN)
		draw_string(Kit.body(), Vector2(x0 + box + 10.0, by + 13.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Kit.INK if not Game.ask_tutorial else Kit.INK_SOFT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _notice(vs: Vector2) -> void:
	var n := Flow.notice(main)
	var acc: Color = Kit.GOLD if main.finished else Kit.accent("notice")
	var w := minf(NOTICE_W, vs.x - 48.0)
	var body := _wrap_lines(n.body, Kit.body(), 18, w - 64.0)
	var h := 92.0 + float(body.size()) * 26.0 + 24.0
	var r := Rect2(vs.x * 0.5 - w * 0.5, vs.y * 0.5 - h * 0.5 - 30.0, w, h)
	_card_pop(r.get_center())
	Kit.card(self, r, acc, 16)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 56.0), String(n.title), 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, w)
	var y := r.position.y + 96.0
	for line: String in body:
		draw_string(Kit.body(), Vector2(r.position.x, y), line, HORIZONTAL_ALIGNMENT_CENTER, w, 18,
			Kit.INK)
		y += 26.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# break lines that would run past the card, on spaces, so a narrow window
# wraps a sentence instead of cutting its last word
func _wrap_lines(lines: Array, f: Font, px: int, room: float) -> Array[String]:
	var out: Array[String] = []
	for raw in lines:
		var s := String(raw)
		if s == "" or f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= room:
			out.append(s)
			continue
		var cur := ""
		for word in s.split(" "):
			var nxt := word if cur == "" else cur + " " + word
			if f.get_string_size(nxt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= room:
				cur = nxt
			else:
				if cur != "":
					out.append(cur)
				cur = word
		if cur != "":
			out.append(cur)
	return out
