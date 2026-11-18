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
const UiScale := preload("res://hud/ui_scale.gd")
const Ach := preload("res://systems/achievements.gd")

const MAIN_W := 300.0
const MAIN_ROW_H := 44.0
const SHOP_W := 1040.0
const SHOP_H := 540.0
const SHOP_ROW_H := 44.0
const DETAILS_W := 400.0
const PORTRAIT_W := 240.0
const PROGRESS_W := 900.0
const PROGRESS_ROW_H := 32.0
const PAUSE_W := 560.0
const PAUSE_CELL_H := 58.0
const PAUSE_GAP := 12.0
const WALKCARD_W := 620.0
const CONFIRM_W := 460.0
const FIRST_ROW_H := 50.0
const NOTICE_W := 660.0
const CREDITS_W := 760.0
const CREDITS_AUTO_SPEED := 18.0
const CREDITS_MANUAL_SPEED := 240.0

var main: Node2D
var _credits_clip: Control


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits_clip = Control.new()
	_credits_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits_clip.clip_contents = true
	_credits_clip.visible = false
	add_child(_credits_clip)
	_credits_clip.draw.connect(_draw_credits_body)


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
		var sl := shop_layout(get_viewport_rect().size)
		var sk := float(sl.scale)
		main.shop_preview.position = (sl.rect as Rect2).position + Vector2(218.0, 262.0) * sk
		main.shop_preview.scale = Vector2(sk, sk)
		var ang := -PI * 0.5 + sin(_shop_t * 0.85) * 0.68
		main.shop_preview.facing = Vector2.from_angle(ang)
		main.shop_preview.hip_dir = -main.shop_preview.facing.rotated(sin(_shop_t * 1.7) * 0.08)
		main.shop_preview.gait = _shop_t * 2.2
		main.shop_preview.hop = maxf(0.0, float(main.shop_preview.hop) - delta * 36.0)
		main.shop_preview.bark_anim = maxf(0.0, float(main.shop_preview.bark_anim) - delta)
		main.shop_preview.queue_redraw()
	elif main.shop_preview != null:
		main.shop_preview.scale = Vector2.ONE
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
	if _credits_clip != null:
		_credits_clip.visible = (s == "credits")
		if s == "credits":
			var vs := get_viewport_rect().size
			var cr := _credits_rect(vs)
			var br := _credits_body_rect(cr)
			var layout := _credits_layout(br.size.x)
			var max_s := maxf(0.0, float(layout.h) - br.size.y)
			var up_held := InputMap.has_action("move_up") and Input.is_action_pressed("move_up")
			var dn_held := InputMap.has_action("move_down") and Input.is_action_pressed("move_down")
			if up_held or dn_held:
				var dir := (1.0 if dn_held else 0.0) - (1.0 if up_held else 0.0)
				main.credits_scroll += dir * CREDITS_MANUAL_SPEED * delta
			else:
				main.credits_scroll += CREDITS_AUTO_SPEED * delta
			main.credits_scroll = clampf(float(main.credits_scroll), 0.0, max_s)
			var u := 1.0 - pow(1.0 - clampf(_open_t, 0.0, 1.0), 3.0)
			var sc := lerpf(0.965, 1.0, u)
			_credits_clip.position = br.position
			_credits_clip.size = br.size
			_credits_clip.pivot_offset = cr.get_center() - br.position
			_credits_clip.scale = Vector2(sc, sc)
			_credits_clip.queue_redraw()
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
		"controls":
			_controls(vs)
		"credits":
			_credits(vs)
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
	var bw := Kit.breadcrumb_w(Flow.step_names())
	Kit.breadcrumb(self, Vector2(vs.x * 0.5 - bw * 0.5, 48.0), Flow.step_names(), step,
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
	Kit.mosaic_card(self, r, acc)
	var f := Kit.display()
	var px := 20 if row_h >= 40.0 else 17
	var picked_i := clampi(int(main.main_idx), 0, n - 1)
	for i in range(n):
		var rr := Rect2(r.position.x + 12.0, r.position.y + pad + row_h * float(i), r.size.x - 24.0, row_h)
		var picked := i == picked_i
		if picked:
			draw_rect(rr, Kit.pick_fill(acc))
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
	var w := minf(560.0, vs.x - 84.0)
	var shake: float = sin(float(main.locked_nudge) * 60.0) * 10.0 * (float(main.locked_nudge) / 0.35) if Game.screen_shake else 0.0
	# the chapter's heading and its walks on top, this walk's record under them
	var h := 112.0
	var bar_top := Kit.prompt_bar_top(self, vs, Flow.prompts(main, "walk")) - 14.0
	var top := bar_top - h
	var r := Rect2(vs.x * 0.5 - w * 0.5 + shake, top, w, h)
	Kit.card(self, r, Kit.accent("walk"), 12)
	# browse arrows at its two ends: the name on the ground is left whole
	Kit.chevron(self, Vector2(r.position.x - 22.0, r.get_center().y), 18.0, Kit.GOLD, true)
	Kit.chevron(self, Vector2(r.end.x + 22.0, r.get_center().y), 18.0, Kit.GOLD)
	var body := Kit.body()
	var row_y := r.position.y + 94.0
	if bool(info.locked):
		Kit.lock(self, Vector2(r.position.x + 34.0, row_y - 6.0), 16.0, Kit.INK_FAINT)
		draw_string(body, Vector2(r.position.x + 58.0, row_y), String(info.lines[0]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Kit.INK_SOFT)
		if not info.has("chase_gate"):
			var have := float(info.have)
			var gate := maxf(1.0, float(info.gate))
			Icons.draw_meter(self, Vector2(r.end.x - 150.0, row_y - 10.0), 110.0, 8.0, have / gate)
			Icons.draw_star(self, Vector2(r.end.x - 24.0, row_y - 6.0), 8.0, true)
	elif info.has("stars"):
		for i in range(3):
			Icons.draw_star(self, Vector2(r.position.x + 34.0 + float(i) * 26.0, row_y - 6.0), 10.0,
				i < int(info.stars))
		var goals := I18n.t("walk_goals") % [int(info.goals), int(info.goals_total)]
		draw_string(body, Vector2(r.position.x + 126.0, row_y), goals, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 17, Kit.INK)
		var right := I18n.t("walk_free_play") if Game.free_play else String(info.best)
		if not Game.free_play and String(info.get("sky", "")) != "":
			right = "%s   %s" % [String(info.sky), right]
		draw_string(body, Vector2(r.position.x, row_y), right,
			HORIZONTAL_ALIGNMENT_RIGHT, w - 28.0, 17, Kit.GOLD if Game.free_play else Kit.INK_SOFT)
	else:
		draw_string(body, Vector2(r.position.x, row_y), "     ".join(info.lines),
			HORIZONTAL_ALIGNMENT_CENTER, w, 16, Kit.INK_SOFT)
	_chapter_strip(vs, r, info, shake)


# Where this walk sits in the campaign: the chapter's heading (its number and
# a tab for each chapter), then its walks as tokens, the one in
# view lifted in saffron. A chase is a magenta diamond, a boss a turquoise
# ring; a locked walk is hollow.
func _chapter_strip(vs: Vector2, r: Rect2, info: Dictionary, shake: float) -> void:
	var walks: Array = info.chapter_walks
	var ci := int(info.chapter)
	var n := walks.size()
	var f := Kit.display()
	var head_y := r.position.y + 26.0
	var title := I18n.t("menu_chapter") % (ci + 1)
	var tw := Kit.text_w(f, title, 15)
	var x := r.position.x + 28.0
	draw_string(f, Vector2(x, head_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Kit.SAFFRON)
	x += tw + 12.0
	for k in range(int(info.chapters)):
		var tab := Rect2(x + float(k) * 16.0, head_y - 9.0, 12.0, 5.0)
		draw_rect(tab, Kit.SAFFRON if k == ci else Color(Kit.INK_FAINT, 0.6))
	# the walks
	var dx := minf(40.0, (r.size.x - 56.0) / float(maxi(1, n)))
	var x0 := r.get_center().x - dx * float(n - 1) * 0.5
	var y := r.position.y + 54.0
	draw_line(Vector2(r.position.x + 28.0, r.position.y + 74.0), Vector2(r.end.x - 28.0, r.position.y + 74.0),
		Color(1, 1, 1, 0.08), 1.5)
	for k in range(n):
		var lv: String = walks[k]
		var p := Vector2(x0 + dx * float(k), y)
		var here := lv == String(info.id)
		var open := Game.is_unlocked(lv)
		var col: Color = Kit.INK
		if lv in Game.BOSS_WALKS:
			col = Kit.TURQUOISE
		elif lv in Game.CHASE_WALKS:
			col = Kit.MAGENTA
		if here:
			col = Kit.SAFFRON
		var rad := 9.0 if here else 6.0
		if lv in Game.CHASE_WALKS:
			var dia := PackedVector2Array([p + Vector2(0, -rad - 1.5), p + Vector2(rad + 1.5, 0), p + Vector2(0, rad + 1.5),
				p + Vector2(-rad - 1.5, 0)])
			if open or here:
				draw_colored_polygon(dia, col)
			else:
				dia.append(dia[0])
				draw_polyline(dia, Color(col, 0.55), 1.6)
		else:
			if open or here:
				draw_circle(p, rad, col)
			else:
				draw_arc(p, rad, 0, TAU, 16, Color(col, 0.5), 1.6)
			if lv in Game.BOSS_WALKS:
				draw_arc(p, rad + 4.0, 0, TAU, 20, Color(col, 0.9 if (open or here) else 0.45), 2.0)
		if here:
			draw_arc(p, rad + 3.0 + (4.0 if lv in Game.BOSS_WALKS else 0.0), 0, TAU, 24, Color(Kit.SAFFRON, 0.5), 2.0)
		elif open and Game.stars(lv) >= 3:
			# all three stars: a small saffron pip over it
			draw_circle(p + Vector2(0, -rad - 5.0), 2.2, Kit.SAFFRON)


func _details(vs: Vector2) -> void:
	var acc := Kit.accent("details")
	var rows := Flow.details_rows(main)
	var legend := Flow.controls()
	var bar_top := Kit.prompt_bar_top(self, vs, Flow.prompts(main, "details")) - 14.0
	var max_h := maxf(240.0, bar_top - 12.0)
	var legend_rows := ceilf(float(legend.size()) / 2.0)
	var legend_step := 26.0
	var row_h := 43.0
	var h := 62.0 + float(rows.size()) * row_h + 12.0 + legend_rows * legend_step + 12.0
	if h > max_h:
		legend_step = 21.0
		row_h = clampf(floor((max_h - 62.0 - 18.0 - legend_rows * legend_step) / float(maxi(rows.size(), 1))), 32.0, 43.0)
		h = 62.0 + float(rows.size()) * row_h + 10.0 + legend_rows * legend_step + 8.0
	# anchored over the prompt bar, like the walk select's card, so the walk's
	# name and gloss on the ground above it are never under it
	var dw := minf(DETAILS_W, vs.x - 64.0)
	var r := Rect2(48.0 if dw >= DETAILS_W else (vs.x - dw) * 0.5, maxf(10.0, bar_top - h), dw, h)
	if r.position.y >= 62.0:
		_top(vs, 1)
	else:
		Kit.purse(self, Vector2(vs.x - 40.0, 48.0), Game.total_stars(), Game.total_bones)
	Kit.card(self, r, acc)
	Kit.heading(self, r.position + Vector2(28.0, 42.0), I18n.t("details_title"), 24, acc)
	var y := r.position.y + 62.0
	var f := Kit.display()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var picked: bool = i == int(main.details_idx)
		var rr := Rect2(r.position.x + 14.0, y, r.size.x - 28.0, row_h - 5.0)
		if picked:
			draw_rect(rr, Kit.pick_fill(acc))
			draw_rect(Rect2(rr.position, Vector2(4.0, rr.size.y)), acc)
		var has_trait := row.has("trait")
		var cy := rr.get_center().y
		if has_trait and picked:
			draw_string(f, Vector2(rr.position.x + 16.0, cy - 3.0), String(row.name), HORIZONTAL_ALIGNMENT_LEFT,
				-1, 12, Kit.INK_SOFT)
			draw_string(Kit.body(), Vector2(rr.position.x + 16.0, cy + 12.0), String(row.trait), HORIZONTAL_ALIGNMENT_LEFT,
				-1, 11, Color(acc.r, acc.g, acc.b, 0.95))
		else:
			draw_string(f, Vector2(rr.position.x + 16.0, cy + 5.0), String(row.name), HORIZONTAL_ALIGNMENT_LEFT,
				-1, 15, Kit.INK_SOFT if picked else Kit.INK_FAINT)
		var fixed := bool(row.fixed)
		var val := String(row.value)
		var vx := rr.end.x - 40.0
		var vw := Kit.text_w(f, val, 20)
		var unlocked: bool = bool(row.get("unlocked", true))
		var vcol: Color = Kit.INK_FAINT if (fixed or not unlocked) else (Kit.INK if picked else Kit.INK_SOFT)
		draw_string(f, Vector2(vx - vw, cy + 7.0), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, vcol)
		if fixed:
			var why := String(row.get("hint", I18n.t("details_set_by_walk")))
			draw_string(Kit.body(), Vector2(vx - vw - 12.0 - Kit.text_w(Kit.body(), why, 13), cy + 6.0), why,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Kit.INK_FAINT)
		elif not unlocked:
			Kit.lock(self, Vector2(vx - vw - 18.0, cy), 12.0, Kit.INK_FAINT)
		elif picked:
			Kit.chevron(self, Vector2(vx - vw - 18.0, cy), 9.0, acc, true)
			Kit.chevron(self, Vector2(vx + 16.0, cy), 9.0, acc)
		y += row_h
	y += 2.0
	draw_line(Vector2(r.position.x + 28.0, y), Vector2(r.end.x - 28.0, y), Color(1, 1, 1, 0.1), 1.5)
	y += 6.0
	# the controls, once, where the player is already looking before the
	# walk starts, instead of a line of them across the bottom of the walk
	for i in range(legend.size()):
		var it: Array = legend[i]
		var cx := r.position.x + 28.0 + float(i % 2) * 180.0
		var cy := y + float(i / 2) * legend_step
		var kw := Kit.keycap(self, Vector2(cx, cy), Prompts.key(String(it[0])), 12, 18.0)
		draw_string(Kit.body(), Vector2(cx + kw + 8.0, cy + 13.0), String(it[1]), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 13, Kit.INK_SOFT)
	if r.end.x + 14.0 + PORTRAIT_W <= vs.x - 16.0:
		_portrait(Rect2(r.end.x + 14.0, r.position.y, PORTRAIT_W, r.size.y), acc)


# the two of you, side on as the films draw you, beside GET READY: a new
# dog or a NEW LOOK shows here at once, not only as a dot on the ground
func _portrait(r: Rect2, acc: Color) -> void:
	Kit.card(self, r, acc)
	var t := AnimClock.msec() / 1000.0
	var feet := r.end.y - 30.0
	# a lit backdrop, so a dark coat or a dark shirt still reads on the card
	var lit := Rect2(r.position.x + 12.0, r.position.y + 12.0, r.size.x - 24.0, feet - r.position.y - 4.0)
	IntroKit.vgrad(self, lit, Color(acc.r, acc.g, acc.b, 0.03), Color(acc.r, acc.g, acc.b, 0.12))
	draw_rect(Rect2(r.position.x + 12.0, feet - 2.0, r.size.x - 24.0, 18.0), Color(1, 1, 1, 0.10))
	var k := clampf((r.size.y - 90.0) / 300.0, 0.5, 0.95)
	var hand := IntroKit.human(self, Vector2(r.position.x + 66.0, feet), k, 1.0, Vector2.ONE, {
		"phone": 1.0, "glow": 0.5, "reach": 0.35, "scroll": t * 1.5, "blink": 1.0 if fposmod(t, 3.7) < 0.12 else 0.0,
	}, 0.0, feet)
	var m := IntroKit.millie(self, Vector2(r.position.x + 168.0, feet), k * 0.72, -1.0, Vector2.ONE, {
		"head_up": 0.45, "tail": sin(t * 7.0) * 0.6, "ear": 0.2,
	}, feet)
	IntroKit.leash(self, m["ring"], hand, 30.0)


func shop_layout(vs: Vector2) -> Dictionary:
	var bar_top := Kit.prompt_bar_top(self, vs, Flow.prompts(main, "shop") if main != null else []) - 14.0
	var avail_w := maxf(320.0, vs.x - 40.0)
	var avail_h := maxf(220.0, bar_top - 14.0)
	var k := minf(1.0, minf(avail_w / SHOP_W, avail_h / SHOP_H))
	var w := SHOP_W * k
	var h := SHOP_H * k
	var x0 := (vs.x - w) * 0.5
	var y0 := clampf(14.0 + (avail_h - h) * 0.5, 14.0, maxf(14.0, bar_top - h))
	return {"rect": Rect2(x0, y0, w, h), "scale": k}


func shop_rect() -> Rect2:
	return shop_layout(get_viewport_rect().size).rect


func _shop(vs: Vector2) -> void:
	var acc := Kit.accent("shop")
	var sl := shop_layout(vs)
	var sr: Rect2 = sl.rect
	var sk := float(sl.scale)
	draw_set_transform(sr.position, 0.0, Vector2(sk, sk))
	var r := Rect2(Vector2.ZERO, Vector2(SHOP_W, SHOP_H))
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(36.0, 54.0), I18n.t("shop_title"), 30, acc)
	var f := Kit.display()
	var bones := str(Game.total_bones)
	var bx := r.end.x - 36.0 - Kit.text_w(f, bones, 22)
	Kit.heading(self, Vector2(bx, r.position.y + 52.0), bones, 22, Kit.INK)
	Icons.draw_bone(self, Vector2(bx - 20.0, r.position.y + 44.0), 12.0)
	# the tabs
	var tab := Flow.shop_tab_of(main)
	var tx := r.position.x + 440.0
	for k: String in Flow.SHOP_TABS:
		var nm: String = I18n.t(Flow.SHOP_TAB_NAMES[k])
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
		"maxed":
			note = I18n.t("shop_maxed_note") % Game.MAX_STAT_POINTS
			ncol = Kit.GOOD
		"wearing":
			note = I18n.t("shop_wearing_note") % Game.dog_name()
			ncol = Kit.GOOD
		"owned":
			note = I18n.t("shop_owned_note")
		"afford":
			note = I18n.t("shop_cost_note") % int(data.cost)
			ncol = Kit.GOLD
		"short":
			note = I18n.t("shop_short_note") % [int(data.cost), int(data.cost) - Game.total_bones]
			ncol = Kit.INK_FAINT
	var shake: float = sin(float(main.locked_nudge) * 60.0) * 8.0 * (float(main.locked_nudge) / 0.35) if Game.screen_shake else 0.0
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
			draw_rect(rr, Kit.pick_fill(acc))
			draw_rect(Rect2(rr.position, Vector2(4.0, rr.size.y)), acc)
		_swatch(Vector2(lx + 30.0, y + rr.size.y * 0.5), tab, key, d)
		if tab == "stats":
			var cur_stat := Game.get_dog_stat(Game.dog, key)
			var stat_str := I18n.t("shop_level") % [cur_stat, Game.MAX_STAT_POINTS]
			draw_string(Kit.body(), Vector2(lx + 56.0, y + 25.0), "%s (%s)" % [String(d.name), stat_str], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.INK if picked else Kit.INK_SOFT)
		else:
			draw_string(Kit.body(), Vector2(lx + 56.0, y + 25.0), String(d.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.INK if picked else Kit.INK_SOFT)
		var rs := Flow.shop_state(tab, key)
		var right := rr.end.x - 16.0
		match rs:
			"maxed":
				var mw := Kit.text_w(f, I18n.t("shop_maxed"), 13)
				draw_rect(Rect2(right - mw - 16.0, y + 9.0, mw + 16.0, 20.0), Color(Kit.GOOD.r, Kit.GOOD.g, Kit.GOOD.b, 0.22))
				draw_string(f, Vector2(right - mw - 8.0, y + 24.0), I18n.t("shop_maxed"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Kit.GOOD)
			"wearing":
				var tw := Kit.text_w(f, I18n.t("shop_wearing"), 13)
				draw_rect(Rect2(right - tw - 16.0, y + 9.0, tw + 16.0, 20.0), Color(Kit.GOOD.r, Kit.GOOD.g, Kit.GOOD.b, 0.22))
				draw_string(f, Vector2(right - tw - 8.0, y + 24.0), I18n.t("shop_wearing"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Kit.GOOD)
			"owned":
				draw_string(f, Vector2(lx, y + 25.0), I18n.t("shop_owned"), HORIZONTAL_ALIGNMENT_RIGHT, lw - 16.0, 13, Kit.INK_FAINT)
			_:
				var cost := str(int(d.cost))
				var ccol: Color = Kit.GOLD if rs == "afford" else Kit.INK_FAINT
				draw_string(f, Vector2(lx, y + 25.0), cost, HORIZONTAL_ALIGNMENT_RIGHT, lw - 16.0, 17, ccol)
				Icons.draw_bone(self, Vector2(right - Kit.text_w(f, cost, 17) - 18.0, y + 19.0), 9.0,
					Color(ccol.r, ccol.g, ccol.b, 0.9))
		y += SHOP_ROW_H
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _swatch(at: Vector2, kind: String, key: String, d: Dictionary) -> void:
	match kind:
		"stats":
			draw_circle(at, 10.0, Kit.GOLD)
			draw_circle(at, 6.0, Kit.PANEL)
			draw_circle(at, 3.0, Kit.GOLD)
		"collar":
			if key == "rainbow":
				var cols := [Color(0.85, 0.25, 0.25), Color(0.95, 0.6, 0.2), Color(0.95, 0.85, 0.3),
					Color(0.35, 0.75, 0.4), Color(0.3, 0.5, 0.85), Color(0.6, 0.35, 0.75)]
				for i in range(6):
					draw_arc(at, 10.0, TAU * float(i) / 6.0, TAU * float(i + 1) / 6.0, 6, cols[i], 6.0)
			else:
				draw_arc(at, 10.0, 0, TAU, 20, d.col, 6.0)
			draw_circle(at + Vector2(0, 11.0), 3.0, Kit.SAFFRON)
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
	return clampf(avail / float(maxi(row_count, 1)), 4.0, PROGRESS_ROW_H)


static func progress_rect(vs: Vector2, row_count: int) -> Rect2:
	var w := minf(PROGRESS_W, vs.x - 80.0)
	var rh := progress_row_h(vs, row_count)
	var h := 88.0 + float(row_count) * rh + 14.0
	var top_limit := 16.0
	var bottom_limit := vs.y - Kit.BAR_FROM_BOTTOM - 16.0
	var y0 := clampf((top_limit + bottom_limit - h) * 0.5, top_limit, maxf(top_limit, bottom_limit - h))
	return Rect2(vs.x * 0.5 - w * 0.5, y0, w, h)


# text cut at a word, or a letter, to fit w, with "..." where it was cut
static func fit_text(f: Font, text: String, px: int, w: float) -> String:
	if Kit.text_w(f, text, px) <= w:
		return text
	var cut := text
	while cut.length() > 1 and Kit.text_w(f, cut + "...", px) > w:
		var sp := cut.rfind(" ")
		cut = cut.substr(0, sp) if sp > cut.length() / 2 else cut.substr(0, cut.length() - 1)
	return cut.strip_edges() + "..."


func _progress(vs: Vector2) -> void:
	if Flow.progress_is_achievements(main):
		_achievements(vs)
		return
	var acc := Kit.accent("progress")
	var rows := Flow.progress_rows(main)
	var rh := progress_row_h(vs, rows.size())
	var r := progress_rect(vs, rows.size())
	var w := r.size.x
	_card_pop(r.get_center())
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(36.0, 44.0), I18n.t("progress_title"), 26, acc)
	Kit.purse(self, Vector2(r.end.x - 36.0, r.position.y + 42.0), Game.total_stars(), Game.total_bones)
	var f := Kit.display()
	# the page: this chapter's number and a tab for each, plus the achievements page
	var cx := r.position.x + 36.0 + Kit.text_w(f, I18n.t("progress_title"), 26) + 24.0
	var ctitle := I18n.t("menu_chapter") % (int(main.progress_chapter) + 1)
	draw_string(f, Vector2(cx, r.position.y + 42.0), ctitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Kit.SAFFRON)
	cx += Kit.text_w(f, ctitle, 15) + 12.0
	_draw_progress_tabs(cx, r.position.y + 33.0, int(main.progress_chapter))
	var body := Kit.body()
	var c_stars := r.position.x + w * 0.46
	var c_goals := r.position.x + w * 0.60
	var c_best := r.position.x + w * 0.76
	var hy := r.position.y + 78.0
	for col: Array in [[r.position.x + 36.0, I18n.t("progress_col_walk")], [c_stars, I18n.t("progress_col_stars")], [c_goals, I18n.t("progress_col_goals")], [c_best, I18n.t("progress_col_best")]]:
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
			draw_rect(Rect2(r.position.x + 20.0, by, w - 40.0, rh), Kit.pick_fill(acc))
			draw_rect(Rect2(r.position.x + 20.0, by, 3.0, rh), acc)
		elif i % 2 == 0:
			draw_rect(Rect2(r.position.x + 20.0, by, w - 40.0, rh), Color(1, 1, 1, 0.03))
		var base := by + rh * 0.70
		var locked := bool(row.locked)
		var ncol: Color = Kit.INK_SOFT if locked else Kit.INK
		draw_string(f, Vector2(r.position.x + 36.0, base), String(row.name), HORIZONTAL_ALIGNMENT_LEFT, -1, font_px, ncol)
		var nw := Kit.text_w(f, String(row.name), font_px)
		# cut to the stars column: draw_string's width does not clip, and a
		# long gloss ran on under the stars
		var gloss_w := c_stars - 14.0 - (r.position.x + 46.0 + nw)
		if gloss_w > 30.0:
			draw_string(body, Vector2(r.position.x + 46.0 + nw, base), fit_text(body, String(row.gloss), sub_px, gloss_w),
				HORIZONTAL_ALIGNMENT_LEFT, -1, sub_px, Kit.INK_SOFT)
		if locked:
			Kit.lock(self, Vector2(c_stars + 8.0, base - 5.0), lock_sz, Kit.INK_FAINT)
			var lock_lbl := I18n.t("progress_opens_at_one" if int(row.gate) == 1 else "progress_opens_at") % int(row.gate)
			if String(row.get("chase_gate", "")) != "":
				var ch_id: String = String(row.chase_gate)
				lock_lbl = I18n.t("progress_finish_first") % Game.LEVEL_NAMES.get(ch_id, ch_id)
			draw_string(body, Vector2(c_stars + 24.0, base), lock_lbl,
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


static func controls_layout(vs: Vector2, main_node: Node2D, win: Window = null) -> Dictionary:
	var ins := UiScale.safe_insets(win)
	var top_limit := maxf(12.0, ins.y + 8.0)
	var items := Flow.prompts(main_node, "controls") if main_node != null else []
	var bottom_limit := Kit.prompt_bar_top(main_node, vs, items) - 14.0 if (main_node != null and not items.is_empty()) else (vs.y - Kit.BAR_FROM_BOTTOM - ins.w - 14.0)
	var avail_h := maxf(200.0, bottom_limit - top_limit)
	var avail_w := maxf(300.0, vs.x - 28.0 - ins.x - ins.z)
	var acts := Game.REBIND_ACTIONS.size()
	var two_col := avail_w >= 680.0
	var per_col := (acts + 1) / 2 if two_col else acts
	var compact := avail_h < 420.0
	var title_px := 22 if compact else 26
	var title_y := 34.0 if compact else 42.0
	var sub_y := 52.0 if compact else 64.0
	var hdr_h := 56.0 if compact else 70.0
	var gap_y := 6.0 if compact else 8.0
	var rst_h := 28.0 if compact else 36.0
	var foot_h := 8.0 if compact else 10.0
	var row_h := clampf(floor((avail_h - hdr_h - gap_y - rst_h - foot_h) / float(maxi(per_col, 1))), 23.0, 40.0)
	var h := hdr_h + float(per_col) * row_h + gap_y + rst_h + foot_h
	var w := minf(900.0, avail_w) if two_col else minf(560.0, avail_w)
	var x0 := clampf(ins.x + (vs.x - ins.x - ins.z - w) * 0.5, ins.x + 8.0, maxf(ins.x + 8.0, vs.x - ins.z - w - 8.0))
	var y0 := clampf(top_limit + (avail_h - h) * 0.5, top_limit, maxf(top_limit, bottom_limit - h))
	return {
		"rect": Rect2(x0, y0, w, h),
		"two_col": two_col,
		"per_col": per_col,
		"compact": compact,
		"title_px": title_px,
		"title_y": title_y,
		"sub_y": sub_y,
		"hdr_h": hdr_h,
		"gap_y": gap_y,
		"rst_h": rst_h,
		"row_h": row_h,
	}


func _controls(vs: Vector2) -> void:
	var acc := Kit.accent("controls")
	var rows := Flow.controls_rows(main)
	var lay := controls_layout(vs, main, get_window() if is_inside_tree() else null)
	var acts := Game.REBIND_ACTIONS.size()
	var two_col := bool(lay.two_col)
	var per_col := int(lay.per_col)
	var compact := bool(lay.compact)
	var title_px := int(lay.title_px)
	var title_y := float(lay.title_y)
	var sub_y := float(lay.sub_y)
	var hdr_h := float(lay.hdr_h)
	var gap_y := float(lay.gap_y)
	var rst_h := float(lay.rst_h)
	var row_h := float(lay.row_h)
	var r: Rect2 = lay.rect
	var w := r.size.x
	_card_pop(r.get_center())
	Kit.card(self, r, acc, 16)
	var pad_x := 28.0 if compact else 34.0
	var f := Kit.display()
	var body := Kit.body()
	Kit.heading(self, r.position + Vector2(pad_x, title_y), I18n.t("controls_title"), title_px, acc)
	var hint := I18n.t("controls_layout_hint") % I18n.t("layout_" + Game.control_layout)
	var title_end := pad_x + Kit.text_w(f, I18n.t("controls_title"), title_px) + 18.0
	draw_string(body, r.position + Vector2(title_end, title_y), hint, HORIZONTAL_ALIGNMENT_LEFT,
		maxf(80.0, w * 0.45 - title_end), 14 if compact else 15, Kit.INK_SOFT)
	var col_gap := 28.0
	var col_w := (w - pad_x * 2.0 - col_gap) * 0.5 if two_col else (w - pad_x * 2.0)
	var pad_slot_w := clampf(col_w * 0.24, 72.0, 106.0)
	var key_slot_w := clampf(col_w * 0.24, 72.0, 106.0)
	var col_count := 2 if two_col else 1
	for c_i in range(col_count):
		var cx := r.position.x + pad_x + float(c_i) * (col_w + col_gap)
		var k_x := cx + col_w - pad_slot_w - key_slot_w
		var p_x := cx + col_w - pad_slot_w
		draw_string(f, Vector2(k_x, r.position.y + sub_y), I18n.t("controls_key"),
			HORIZONTAL_ALIGNMENT_CENTER, key_slot_w, 11, Kit.INK_FAINT)
		draw_string(f, Vector2(p_x, r.position.y + sub_y), I18n.t("controls_pad"),
			HORIZONTAL_ALIGNMENT_CENTER, pad_slot_w, 11, Kit.INK_FAINT)
	draw_line(r.position + Vector2(pad_x, hdr_h - 4.0), r.position + Vector2(w - pad_x, hdr_h - 4.0),
		Color(1, 1, 1, 0.12), 1.5)
	var row_px := 13 if row_h < 28.0 else (14 if row_h < 34.0 else 16)
	var cap_px := 11 if row_h < 28.0 else (12 if row_h < 34.0 else 14)
	var cap_h := clampf(row_h - 5.0, 18.0, 24.0)
	for i in range(acts):
		var row: Dictionary = rows[i]
		var col := 0 if not two_col else (i / per_col)
		var ri := i if not two_col else (i % per_col)
		var cx := r.position.x + pad_x + float(col) * (col_w + col_gap)
		var ry := r.position.y + hdr_h + float(ri) * row_h
		var rr := Rect2(cx - 8.0, ry + 1.0, col_w + 16.0, row_h - 2.0)
		var picked: bool = i == int(main.controls_idx)
		var listening := bool(row.listening)
		if listening:
			draw_rect(rr, Color(Kit.SAFFRON.r, Kit.SAFFRON.g, Kit.SAFFRON.b, 0.18))
			draw_rect(rr, Kit.SAFFRON, false, 1.8)
		elif picked:
			draw_rect(rr, Kit.pick_fill(acc))
			draw_rect(Rect2(rr.position, Vector2(3.5, rr.size.y)), acc)
		var k_x := cx + col_w - pad_slot_w - key_slot_w
		var p_x := cx + col_w - pad_slot_w
		var label_room := maxf(60.0, k_x - cx - 8.0)
		var name_col := Kit.SAFFRON if listening else (Kit.INK if picked else Kit.INK_SOFT)
		draw_string(f, Vector2(cx + 4.0, ry + row_h * 0.5 + float(row_px) * 0.36),
			fit_text(f, String(row.name), row_px, label_room),
			HORIZONTAL_ALIGNMENT_LEFT, label_room, row_px, name_col)
		if listening:
			var ltxt := fit_text(f, I18n.t("controls_listen"), cap_px, key_slot_w + pad_slot_w - 4.0)
			draw_string(f, Vector2(k_x, ry + row_h * 0.5 + float(cap_px) * 0.36), ltxt,
				HORIZONTAL_ALIGNMENT_CENTER, key_slot_w + pad_slot_w, cap_px, Kit.SAFFRON)
		else:
			var ktxt := String(row.key_txt)
			var kw := Kit.keycap_w(ktxt, cap_px)
			Kit.keycap(self, Vector2(k_x + (key_slot_w - kw) * 0.5, ry + (row_h - cap_h) * 0.5), ktxt, cap_px, cap_h)
			var ptxt := String(row.pad_txt)
			var pw := Kit.keycap_w(ptxt, cap_px)
			Kit.keycap(self, Vector2(p_x + (pad_slot_w - pw) * 0.5, ry + (row_h - cap_h) * 0.5), ptxt, cap_px, cap_h, 0.85)
	var rst: Dictionary = rows[acts]
	var rst_y := r.position.y + hdr_h + float(per_col) * row_h + gap_y
	var rst_r := Rect2(r.position.x + pad_x, rst_y, w - pad_x * 2.0, rst_h)
	var rst_picked: bool = int(main.controls_idx) >= acts
	draw_rect(rst_r, Kit.pick_fill(acc) if rst_picked else Color(1, 1, 1, 0.04))
	draw_rect(rst_r, acc if rst_picked else Color(1, 1, 1, 0.14), false, 2.0 if rst_picked else 1.0)
	if rst_picked:
		Kit.chevron(self, Vector2(rst_r.position.x + 20.0, rst_r.get_center().y), 7.5, acc)
	var rst_px := 14 if compact else 16
	draw_string(f, Vector2(rst_r.position.x, rst_r.get_center().y + float(rst_px) * 0.36), String(rst.name),
		HORIZONTAL_ALIGNMENT_CENTER, rst_r.size.x, rst_px, Kit.INK if rst_picked else Kit.INK_SOFT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_progress_tabs(cx: float, ty: float, active: int) -> void:
	var n_ch := Game.chapters().size()
	var total := Flow.progress_page_count()
	for k in range(total):
		var col: Color
		if k == active:
			col = Kit.SAFFRON
		elif k >= n_ch:
			col = Color(Kit.TURQUOISE, 0.55)
		else:
			col = Color(Kit.INK_FAINT, 0.6)
		var tw := 16.0 if k >= n_ch else 12.0
		draw_rect(Rect2(cx + float(k) * 16.0, ty, tw, 5.0), col)


static func achievements_grid_params(vs: Vector2) -> Dictionary:
	var cols := 2 if vs.x < 960.0 else 3
	var rows_n := ceili(float(Ach.FEATS.size()) / float(cols))
	var margin_x := 44.0 if vs.x < 1100.0 else 80.0
	var w := minf(1060.0, vs.x - margin_x)
	var top_limit := 16.0
	var bottom_limit := vs.y - Kit.BAR_FROM_BOTTOM - 16.0
	var avail_h := maxf(180.0, bottom_limit - top_limit)
	var compact := avail_h < 480.0
	var head_h := 72.0 if compact else 86.0
	var gap_y := 4.0 if compact else 8.0
	var bot_pad := 10.0 if compact else 16.0
	var max_cell := (avail_h - head_h - bot_pad - float(rows_n - 1) * gap_y) / float(rows_n)
	var cell_h := clampf(max_cell, 32.0, 56.0 if cols == 3 else 60.0)
	var h := head_h + float(rows_n) * cell_h + float(rows_n - 1) * gap_y + bot_pad
	var y0 := clampf((top_limit + bottom_limit - h) * 0.5, top_limit, maxf(top_limit, bottom_limit - h))
	return {
		"cols": cols, "rows": rows_n, "compact": compact,
		"head_h": head_h, "gap_y": gap_y, "cell_h": cell_h,
		"rect": Rect2(vs.x * 0.5 - w * 0.5, y0, w, h),
	}


func _achievements(vs: Vector2) -> void:
	var acc := Kit.accent("progress")
	var gp := achievements_grid_params(vs)
	var r: Rect2 = gp.rect
	var cols: int = int(gp.cols)
	var cell_h: float = float(gp.cell_h)
	var gap_y: float = float(gp.gap_y)
	var head_h: float = float(gp.head_h)
	var compact: bool = bool(gp.compact)
	_card_pop(r.get_center())
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(36.0, 44.0), I18n.t("progress_title"), 26, acc)
	Kit.purse(self, Vector2(r.end.x - 36.0, r.position.y + 42.0), Game.total_stars(), Game.total_bones)
	var f := Kit.display()
	var body := Kit.body()
	var cx := r.position.x + 36.0 + Kit.text_w(f, I18n.t("progress_title"), 26) + 20.0
	var tab_lbl := I18n.t("progress_achievements_tab")
	draw_string(f, Vector2(cx, r.position.y + 42.0), tab_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Kit.SAFFRON)
	cx += Kit.text_w(f, tab_lbl, 15) + 12.0
	_draw_progress_tabs(cx, r.position.y + 33.0, int(main.progress_chapter))
	var count_lbl := I18n.t("progress_achievements_count") % [Ach.unlocked_count(), Ach.FEATS.size()]
	var hy := r.position.y + (64.0 if compact else 72.0)
	draw_string(f, Vector2(r.position.x + 36.0, hy), count_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Kit.INK_FAINT)

	var gap_x := 12.0 if cols == 3 else 16.0
	var pad_x := 28.0
	var col_w := (r.size.x - pad_x * 2.0 - float(cols - 1) * gap_x) / float(cols)
	var y_start := r.position.y + head_h
	var title_px := 14 if cell_h >= 46.0 else 12
	var hint_px := 12 if cell_h >= 46.0 else 10
	var star_r := 7.0 if cell_h >= 46.0 else 5.5
	var lock_sz := 8.5 if cell_h >= 46.0 else 6.5
	for i in range(Ach.FEATS.size()):
		var feat: Dictionary = Ach.FEATS[i]
		var col_i := i % cols
		var row_i := i / cols
		var cr := Rect2(r.position.x + pad_x + float(col_i) * (col_w + gap_x),
			y_start + float(row_i) * (cell_h + gap_y), col_w, cell_h)
		var unlocked := Ach.has(String(feat.id))
		if unlocked:
			draw_rect(cr, Color(Kit.NAVY_RAISED.r, Kit.NAVY_RAISED.g, Kit.NAVY_RAISED.b, 0.96))
			draw_rect(Rect2(cr.position, Vector2(3.0, cr.size.y)), Kit.SAFFRON)
			draw_rect(cr, Color(Kit.SAFFRON.r, Kit.SAFFRON.g, Kit.SAFFRON.b, 0.35), false, 1.0)
			Icons.draw_star(self, Vector2(cr.position.x + 18.0, cr.get_center().y), star_r, true)
		else:
			draw_rect(cr, Color(1, 1, 1, 0.025))
			draw_rect(cr, Color(Kit.INK_FAINT.r, Kit.INK_FAINT.g, Kit.INK_FAINT.b, 0.16), false, 1.0)
			Kit.lock(self, Vector2(cr.position.x + 18.0, cr.get_center().y - 1.0), lock_sz, Kit.INK_FAINT)
		var tx := cr.position.x + 33.0
		var tw := cr.size.x - 41.0
		var y_name := cr.position.y + (cell_h * 0.43 if cell_h >= 46.0 else 15.0)
		var y_hint := cr.position.y + (cell_h * 0.79 if cell_h >= 46.0 else 30.0)
		var ncol := Kit.INK if unlocked else Kit.INK_FAINT
		var hcol := Kit.INK_SOFT if unlocked else Color(Kit.INK_FAINT.r, Kit.INK_FAINT.g, Kit.INK_FAINT.b, 0.72)
		draw_string(f, Vector2(tx, y_name), fit_text(f, I18n.t(String(feat.name)), title_px, tw),
			HORIZONTAL_ALIGNMENT_LEFT, -1, title_px, ncol)
		draw_string(body, Vector2(tx, y_hint), fit_text(body, I18n.t(String(feat.hint)), hint_px, tw),
			HORIZONTAL_ALIGNMENT_LEFT, -1, hint_px, hcol)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _credits_rect(vs: Vector2) -> Rect2:
	var w := minf(CREDITS_W, vs.x - 48.0)
	var top_limit := 16.0
	var bottom_limit := vs.y - Kit.BAR_FROM_BOTTOM - 16.0
	var avail_h := maxf(180.0, bottom_limit - top_limit)
	var h := clampf(avail_h * 0.88, 200.0, minf(560.0, avail_h))
	var y0 := clampf((top_limit + bottom_limit - h) * 0.5, top_limit, maxf(top_limit, bottom_limit - h))
	return Rect2(vs.x * 0.5 - w * 0.5, y0, w, h)


static func _credits_body_rect(r: Rect2) -> Rect2:
	return Rect2(r.position.x + 34.0, r.position.y + 74.0, maxf(120.0, r.size.x - 74.0), maxf(80.0, r.size.y - 94.0))


func _credits_layout(inner_w: float) -> Dictionary:
	var f := Kit.display()
	var body := Kit.body()
	var items: Array = []
	var y := 6.0
	# Game, creator and city right at the fold
	items.append({"rule": false, "font": f, "px": 22, "col": Kit.SAFFRON, "align": HORIZONTAL_ALIGNMENT_CENTER, "text": I18n.t("credits_game_title"), "y": y + 22.0})
	y += 30.0
	items.append({"rule": false, "font": f, "px": 18, "col": Kit.INK, "align": HORIZONTAL_ALIGNMENT_CENTER, "text": I18n.t("credits_made_by"), "y": y + 18.0})
	y += 24.0
	items.append({"rule": false, "font": body, "px": 15, "col": Kit.TURQUOISE, "align": HORIZONTAL_ALIGNMENT_CENTER, "text": I18n.t("credits_made_in"), "y": y + 15.0})
	y += 30.0
	items.append({"rule": true, "y": y})
	y += 18.0
	# Dogs
	items.append({"rule": false, "font": f, "px": 13, "col": Kit.SAFFRON, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": I18n.t("credits_dogs_heading"), "y": y + 13.0})
	y += 20.0
	for ln: String in _wrap_lines([I18n.t("credits_dogs_list")], body, 16, inner_w):
		items.append({"rule": false, "font": body, "px": 16, "col": Kit.INK, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": ln, "y": y + 16.0})
		y += 24.0
	y += 10.0
	items.append({"rule": true, "y": y})
	y += 18.0
	# Fonts (OFL)
	items.append({"rule": false, "font": f, "px": 13, "col": Kit.TURQUOISE, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": I18n.t("credits_fonts_heading"), "y": y + 13.0})
	y += 20.0
	for k: String in ["credits_fonts_bricolage", "credits_fonts_inter"]:
		for ln: String in _wrap_lines([I18n.t(k)], body, 14, inner_w):
			items.append({"rule": false, "font": body, "px": 14, "col": Kit.INK_SOFT, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": ln, "y": y + 14.0})
			y += 20.0
		y += 4.0
	for ln: String in _wrap_lines([I18n.t("credits_fonts_ofl")], body, 12, inner_w):
		items.append({"rule": false, "font": body, "px": 12, "col": Kit.INK_FAINT, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": ln, "y": y + 12.0})
		y += 17.0
	y += 10.0
	items.append({"rule": true, "y": y})
	y += 18.0
	# Engine (Godot MIT)
	items.append({"rule": false, "font": f, "px": 13, "col": Kit.TURQUOISE, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": I18n.t("credits_engine_heading"), "y": y + 13.0})
	y += 20.0
	items.append({"rule": false, "font": f, "px": 15, "col": Kit.INK, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": I18n.t("credits_engine_godot"), "y": y + 15.0})
	y += 22.0
	for para: String in I18n.t("credits_engine_mit").split("\n"):
		if para == "":
			y += 8.0
			continue
		for ln: String in _wrap_lines([para], body, 12, inner_w):
			items.append({"rule": false, "font": body, "px": 12, "col": Kit.INK_FAINT, "align": HORIZONTAL_ALIGNMENT_LEFT, "text": ln, "y": y + 12.0})
			y += 17.0
	y += 20.0
	return {"items": items, "h": y}


func _credits(vs: Vector2) -> void:
	var acc := Kit.accent("credits")
	var r := _credits_rect(vs)
	var br := _credits_body_rect(r)
	_card_pop(r.get_center())
	Kit.card(self, r, acc, 16)
	Kit.heading(self, r.position + Vector2(34.0, 44.0), I18n.t("credits_title"), 26, acc)
	draw_line(Vector2(r.position.x + 28.0, r.position.y + 62.0), Vector2(r.end.x - 28.0, r.position.y + 62.0),
		Color(acc.r, acc.g, acc.b, 0.25), 1.5)
	var layout := _credits_layout(br.size.x)
	var total_h: float = float(layout.h)
	if total_h > br.size.y:
		var track := Rect2(br.end.x + 12.0, br.position.y, 4.0, br.size.y)
		draw_rect(track, Color(1, 1, 1, 0.08))
		var thumb_h := maxf(24.0, br.size.y * (br.size.y / total_h))
		var frac := clampf(float(main.credits_scroll) / maxf(1.0, total_h - br.size.y), 0.0, 1.0)
		var thumb_y := br.position.y + frac * (br.size.y - thumb_h)
		draw_rect(Rect2(track.position.x, thumb_y, track.size.x, thumb_h), Color(acc.r, acc.g, acc.b, 0.65))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_credits_body() -> void:
	if main == null or Flow.screen(main) != "credits":
		return
	var w := _credits_clip.size.x
	var h := _credits_clip.size.y
	if w <= 1.0 or h <= 1.0:
		return
	var layout := _credits_layout(w)
	var max_s := maxf(0.0, float(layout.h) - h)
	var off := clampf(float(main.credits_scroll), 0.0, max_s)
	for item: Dictionary in layout.items:
		var yy := float(item.y) - off
		if bool(item.rule):
			if yy >= -4.0 and yy <= h + 4.0:
				_credits_clip.draw_line(Vector2(0.0, yy), Vector2(w, yy), Color(1, 1, 1, 0.10), 1.0)
			continue
		var px := int(item.px)
		if yy < -4.0 or yy - float(px) > h + 4.0:
			continue
		var align := int(item.align) as HorizontalAlignment
		var span := w if align == HORIZONTAL_ALIGNMENT_CENTER else -1.0
		_credits_clip.draw_string(item.font as Font, Vector2(0.0, yy), String(item.text), align, span, px, item.col as Color)


func _pause(vs: Vector2) -> void:
	var acc := Kit.accent("pause")
	var labels := Flow.pause_labels(main)
	var rows := (labels.size() + Flow.PAUSE_COLS - 1) / Flow.PAUSE_COLS
	var bar_top := Kit.prompt_bar_top(self, vs, Flow.prompts(main, "pause")) - 14.0
	var avail_h := maxf(200.0, bar_top - 12.0)
	var pw := minf(PAUSE_W, vs.x - 40.0)
	var cell_h := clampf(floor((avail_h - 110.0 - 14.0) / float(maxi(rows, 1)) - PAUSE_GAP), 38.0, PAUSE_CELL_H)
	var h := 110.0 + float(rows) * (cell_h + PAUSE_GAP) + 14.0
	var py := clampf(vs.y * 0.5 - h * 0.5 - 20.0, 12.0, maxf(12.0, bar_top - h))
	var r := Rect2(vs.x * 0.5 - pw * 0.5, py, pw, h)
	_card_pop(r.get_center())
	Kit.mosaic_card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 50.0), I18n.t("pause_title"), 30, acc,
		HORIZONTAL_ALIGNMENT_CENTER, pw)
	var sub := "%s    %s" % [String(main._walk_name()), Flow.clock(float(main.elapsed))]
	draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 80.0), sub, HORIZONTAL_ALIGNMENT_CENTER,
		pw, 18, Kit.INK)
	var f := Kit.display()
	var cw := (pw - 48.0 - PAUSE_GAP) * 0.5
	for i in range(labels.size()):
		var col := i % Flow.PAUSE_COLS
		var row := i / Flow.PAUSE_COLS
		var cell := Rect2(r.position.x + 24.0 + float(col) * (cw + PAUSE_GAP),
			r.position.y + 100.0 + float(row) * (cell_h + PAUSE_GAP), cw, cell_h)
		var picked: bool = i == int(main.pause_idx)
		draw_rect(cell, Kit.pick_fill(acc) if picked else Color(1, 1, 1, 0.04))
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
		draw_string(body, Vector2(r.position.x, y), I18n.t("walkcard_no_goals"), HORIZONTAL_ALIGNMENT_CENTER,
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
	var opts: Array = Flow.first_options() if first else []
	var extra := 16.0 + FIRST_ROW_H * float(opts.size()) + 44.0 if first else 0.0
	var h := 150.0 + extra + 26.0 * float(lines.size() - 1)
	var bar_top := Kit.prompt_bar_top(self, vs, Flow.prompts(main, "confirm")) - 14.0
	var cw := minf(CONFIRM_W, vs.x - 40.0)
	var cy := clampf(vs.y * 0.5 - h * 0.5 - 20.0, 12.0, maxf(12.0, bar_top - h))
	var r := Rect2(vs.x * 0.5 - cw * 0.5, cy, cw, h)
	_card_pop(r.get_center())
	Kit.card(self, r, acc)
	Kit.heading(self, Vector2(r.position.x, r.position.y + 56.0), String(c.title), 28, acc,
		HORIZONTAL_ALIGNMENT_CENTER, cw)
	for i in range(lines.size()):
		draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 100.0 + 26.0 * i), lines[i],
			HORIZONTAL_ALIGNMENT_CENTER, cw, 19, Kit.INK_SOFT)
	if first:
		# the two answers, a list like the main menu's
		var oy := r.position.y + 124.0 + 26.0 * float(lines.size() - 1)
		var f := Kit.display()
		for i in range(opts.size()):
			var rr := Rect2(r.position.x + 28.0, oy + FIRST_ROW_H * float(i), cw - 56.0, FIRST_ROW_H - 6.0)
			var picked: bool = i == int(main.first_idx)
			draw_rect(rr, Kit.pick_fill(acc) if picked else Color(1, 1, 1, 0.04))
			draw_rect(rr, acc if picked else Color(1, 1, 1, 0.10), false, 2.0 if picked else 1.0)
			if picked:
				Kit.chevron(self, Vector2(rr.position.x + 20.0, rr.get_center().y), 8.0, acc)
			draw_string(f, Vector2(rr.position.x + 38.0, rr.get_center().y + 6.5), String(opts[i]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.INK if picked else Kit.INK_SOFT)
		# the "don't ask again" box: the prompt bar's key ticks it, and the
		# card shows whether it is ticked
		var label := I18n.t("confirm_dont_ask")
		var tw: float = Kit.body().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var box := 16.0
		var x0 := r.position.x + cw * 0.5 - (box + 10.0 + tw) * 0.5
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
