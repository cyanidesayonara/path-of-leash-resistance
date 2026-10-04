extends RefCounted

# The title-screen flow and every screen reachable from it: the title, the
# walk select, getting ready (who walks, day or night, the weather), the
# wardrobe, the progress screen, settings, the pause menu, and the notice
# cards a walk can end on.
#
# This file is the MODEL: which screen is up, what it holds, and what the
# player can press on it. hud/menu_screen.gd draws it and hud/ui_kit.gd holds
# the shared look. Static functions over main's state; main.gd keeps a
# same-name forwarder for each one another script or a test calls.

const TutorialSteps := preload("res://systems/tutorial.gd")
const UiIcons := preload("res://hud/ui_icons.gd")

const DETAIL_ROWS := ["walker", "time", "weather"]
const PAUSE_CELLS := ["resume", "walk", "restart", "settings", "select", "exit"]
const PAUSE_LABELS := {"resume": "RESUME", "walk": "THIS WALK", "restart": "START AGAIN",
	"settings": "SETTINGS", "select": "WALK SELECT", "exit": "EXIT GAME"}
const PAUSE_COLS := 2
const SHOP_TABS := ["collar", "bandana", "coat"]
const SHOP_TAB_NAMES := {"collar": "COLLARS", "bandana": "BANDANAS", "coat": "COATS"}
const STEP_NAMES := ["CHOOSE A WALK", "GET READY"]

# Leaving the application is a desktop thing: a browser tab is closed by
# the browser. `--no-exit` and tests set this to see the web layout anywhere.
static var exit_hidden := false


# --- which screen is up ---------------------------------------------------

static func screen(m: Node2D) -> String:
	if m.in_settings:
		return "settings"
	if m.confirm_id != "":
		return "confirm"
	if m.msg_label != null and m.msg_label.visible:
		return "notice"
	if m.results_card != null and m.results_card.visible:
		return "results"
	if m.paused:
		return "walkcard" if m.pause_view == "walk" else "pause"
	if m.started:
		return "walking"
	if m.in_shop:
		return "shop"
	if m.in_progress_view:
		return "progress"
	return ["title", "walk", "details"][clampi(m.menu_step, 0, 2)]


# What the player can press on this screen, as [action, verb] pairs for the
# prompt bar (ui_kit.gd). An optional third entry of false dims the item.
static func prompts(m: Node2D, which := "") -> Array:
	match which if which != "" else screen(m):
		"title":
			var out := [["plant", "start"], ["pause", "settings"]]
			if can_exit():
				out.append(["bark", "exit game"])
			return out
		"confirm":
			if String(m.confirm_id) == "first":
				return [["plant", "learn the ropes"], ["bark", "straight to the walks"],
					["pee", "ask me again" if not Game.ask_tutorial else "don't ask again"]]
			return [["plant", "yes"], ["bark", "cancel"]]
		"walkcard":
			return [["bark", "back"]]
		"walk":
			var open := Game.is_unlocked(Game.level_id)
			return [["left_right", "browse"], ["plant", "choose", open], ["bark", "wardrobe"],
				["pee", "progress"], ["pause", "settings"]]
		"details":
			return [["up_down", "pick"], ["left_right", "change"], ["plant", "go walkies"],
				["bark", "back"]]
		"shop":
			var it: Dictionary = m.shop_items[m.shop_idx]
			var st := shop_state(String(it.kind), String(it.key))
			var verb := "wear"
			if st == "wearing":
				verb = "wearing"
			elif st != "owned":
				verb = "buy"
			return [["left_right", "tab"], ["up_down", "browse"],
				["plant", verb, st == "owned" or st == "afford"], ["bark", "back"]]
		"progress":
			return [["bark", "back"]]
		"settings":
			return [["up_down", "pick"], ["left_right", "change"], ["back", "done"]]
		"pause":
			return [["move", "pick"], ["plant", "select"], ["pause", "resume"]]
		"results":
			return end_prompts(m)
		"notice":
			var out := end_prompts(m)
			if m.finished and Game.daily and not m.daily_copied and m.daily_share != "":
				out.insert(0, ["share", "copy result"])
			return out
	return []


static func end_prompts(m: Node2D) -> Array:
	if m.tutorial_mode:
		return [["plant", "on to El Barri"], ["bark", "walk select"], ["restart", "practise again"]]
	if m.finished:
		return [["restart", "walk it again"], ["bark", "walk select"]]
	return [["restart", "try again"], ["bark", "walk select"]]


# --- the title's steps ------------------------------------------------------

static func apply_menu_step(m: Node2D) -> void:
	# one screen, one choice: the walk HUD stays down until the walk begins
	m.panel.visible = m.started
	m.goals_card.visible = m.started and not m.tutorial_mode
	m.dim.visible = (not m.started) and (m.in_shop or m.in_progress_view)
	# the name is part of the world, so the world redraws to add or drop it,
	# and its pieces are laid for what this step says
	m.build_signs()
	m.queue_redraw()


static func refresh_menu_text(m: Node2D) -> void:
	# everything on the menus is drawn from the model each frame, and follows
	# the device in hand by itself; nothing to re-fill
	pass


# The walk-select plaque: what the player has done on the walk in view.
static func walk_info(m: Node2D) -> Dictionary:
	var sel: String = Game.level_id
	var info := {"id": sel, "locked": not Game.is_unlocked(sel), "index": Game.CAROUSEL.find(sel),
		"count": Game.CAROUSEL.size(), "lines": []}
	if sel == "daily":
		var today := "%s, %s%s" % [Game.LEVEL_NAMES[Game.daily_level()],
			String(Game.WEATHER_NAMES[Game.daily_weather()]).to_lower(),
			", at night" if Game.daily_night() else ""]
		info.lines = ["Today: " + today]
		if Game.records.has("daily") and int(Game.records["daily"].bones) > 0:
			info.lines.append("Your best today: %d bones" % int(Game.records["daily"].bones))
		else:
			info.lines.append("The same walk for everyone, new every day.")
		return info
	if sel == "tutorial":
		info.lines = ["One trick at a time, with nothing to get in the way."]
		return info
	if info.locked:
		var gate := int(Game.STAR_GATE.get(sel, 0))
		info["gate"] = gate
		info["have"] = Game.total_stars()
		info.lines = ["Earn %d more star%s to open this walk." % [gate - Game.total_stars(),
			"" if gate - Game.total_stars() == 1 else "s"]]
		return info
	info["stars"] = Game.stars(sel)
	info["goals"] = Game.goals_count(sel)
	info["goals_total"] = (m.LEVEL_GOAL_IDS.get(sel, []) as Array).size()
	if Game.records.has(sel) and int(Game.records[sel].bones) > 0:
		info["best"] = "Best: %d bones in %s" % [int(Game.records[sel].bones), clock(float(Game.records[sel].time))]
	else:
		info["best"] = "Not walked yet"
	return info


static func clock(secs: float) -> String:
	var s := int(round(secs))
	return "%d:%02d" % [s / 60, s % 60]


# The getting-ready rows. `fixed` rows are set by the day on the daily walk.
static func details_rows(m: Node2D) -> Array:
	return [
		{"id": "walker", "name": "YOUR HUMAN", "value": "HIM" if Game.owner_id == "him" else "HER", "fixed": false},
		{"id": "time", "name": "TIME", "value": "NIGHT" if Game.night else "DAY", "fixed": Game.daily},
		{"id": "weather", "name": "WEATHER", "value": String(Game.WEATHER_NAMES[Game.weather]),
			"fixed": Game.daily},
	]


static func details_change(m: Node2D, dir: int) -> void:
	var row: Dictionary = details_rows(m)[m.details_idx]
	if bool(row.fixed):
		return
	match String(row.id):
		"walker":
			Game.toggle_owner()
			m.human.queue_redraw()
		"time":
			Game.night = not Game.night
			m.night_cm.color = m._weather_tint()
		"weather":
			Game.cycle_weather(dir)
			m.night_cm.color = m._weather_tint()
			m.weather_fx.mode = Game.weather
			# snow writes the name in paw prints
			m.build_signs()
	Sfx.play("ui")


# The controls, for the getting-ready card: [action, what it does].
static func controls() -> Array:
	return [["move", "move"], ["plant", "dig in / squat"], ["pee", "pee"], ["bark", "bark"],
		["turbo", "run"], ["pause", "pause"]]


static func start_walk(m: Node2D) -> void:
	m.started = true
	# the very first real walk, for a player who skipped the tutorial: the
	# two buttons nobody would guess
	if not Game.tutorial_done:
		Tips.show(m, "start")
	m.frozen = false
	# snapshot progress so the results can report stars and unlocks
	m.run_pre_total_stars = Game.total_stars()
	m.run_pre_level_stars = Game.stars(m.lvl)
	Game.menu_step = 1
	m.panel.visible = true
	m.goals_card.visible = not m.tutorial_mode
	m.dim.visible = false
	# the name stays on the ground; the line under it is menu text
	m.create_tween().tween_property(m, "gloss_a", 0.0, 1.2)
	m.queue_redraw()


# Title input. Returns true when _process should stop for this frame.
static func tick_title(m: Node2D) -> bool:
	if m.confirm_id != "":
		tick_confirm(m)
		return true
	if m.in_shop:
		tick_shop(m)
		return true
	if m.in_progress_view:
		if (Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pee")
				or Input.is_action_just_pressed("plant") or Input.is_action_just_pressed("pause")):
			close_progress(m)
		return true
	if Input.is_action_just_pressed("pause"):
		open_settings_from_menu(m)
		return true
	match m.menu_step:
		0:
			if Input.is_action_just_pressed("plant"):
				if Game.ask_tutorial and not Game.tutorial_done:
					open_confirm(m, "first")
					return true
				Sfx.play("ui")
				_go_step(m, 1)
			elif Input.is_action_just_pressed("bark") and can_exit():
				open_confirm(m, "exit")
		1:
			if Input.is_action_just_pressed("pee"):
				open_progress(m)
				return true
			if Input.is_action_just_pressed("bark"):
				open_shop(m)
				return true
			if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
				Game.cycle_level(1 if Input.is_action_just_pressed("move_right") else -1)
				Game.menu_step = 1
				m.get_tree().reload_current_scene()
				return true
			if Input.is_action_just_pressed("plant"):
				if not Game.is_unlocked(Game.level_id):
					# a locked walk shakes its plaque instead of opening
					m.locked_nudge = 0.35
					return false
				Sfx.play("ui")
				m.details_idx = 0
				_go_step(m, 2)
		2:
			if Input.is_action_just_pressed("move_down"):
				m.details_idx = wrapi(m.details_idx + 1, 0, DETAIL_ROWS.size())
				Sfx.play("ui")
			elif Input.is_action_just_pressed("move_up"):
				m.details_idx = wrapi(m.details_idx - 1, 0, DETAIL_ROWS.size())
				Sfx.play("ui")
			elif Input.is_action_just_pressed("move_right"):
				details_change(m, 1)
			elif Input.is_action_just_pressed("move_left"):
				details_change(m, -1)
			elif Input.is_action_just_pressed("bark"):
				Sfx.play("ui")
				_go_step(m, 1)
			elif Input.is_action_just_pressed("plant"):
				Sfx.play("ui")
				start_walk(m)
	return false


static func _go_step(m: Node2D, step: int) -> void:
	m.menu_step = step
	Game.menu_step = step
	apply_menu_step(m)


# --- the pause menu ---------------------------------------------------------

static func open_pause(m: Node2D) -> void:
	m.paused = true
	m.frozen = true
	m.pause_idx = 0
	m.pause_view = ""
	m.confirm_id = ""
	m.dim.visible = true
	Sfx.play("ui")


static func resume(m: Node2D) -> void:
	m.paused = false
	m.frozen = false
	m.pause_view = ""
	m.confirm_id = ""
	m.dim.visible = false
	Sfx.play("ui")


static func tick_pause(m: Node2D) -> void:
	if m.confirm_id != "":
		tick_confirm(m)
		return
	if m.pause_view == "walk":
		tick_walk_card(m)
		return
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("bark"):
		resume(m)
	elif Input.is_action_just_pressed("move_down"):
		pause_move(m, 0, 1)
	elif Input.is_action_just_pressed("move_up"):
		pause_move(m, 0, -1)
	elif Input.is_action_just_pressed("move_right"):
		pause_move(m, 1, 0)
	elif Input.is_action_just_pressed("move_left"):
		pause_move(m, -1, 0)
	elif Input.is_action_just_pressed("pee"):
		open_settings(m)
	elif Input.is_action_just_pressed("plant"):
		pause_activate(m)


static func pause_activate(m: Node2D) -> void:
	match String(pause_ids(m)[m.pause_idx]):
		"resume":
			resume(m)
		"walk":
			open_walk_card(m)
		"restart":
			open_confirm(m, "restart")
		"settings":
			open_settings(m)
		"select":
			to_walk_select(m)
		"exit":
			open_confirm(m, "exit")


static func can_exit() -> bool:
	return not exit_hidden and not OS.has_feature("web")


static func pause_ids(m: Node2D) -> Array:
	var out := PAUSE_CELLS.duplicate()
	if not can_exit():
		out.erase("exit")
	return out


static func pause_labels(m: Node2D) -> Array:
	var out := []
	for id: String in pause_ids(m):
		out.append(PAUSE_LABELS[id])
	return out


# One step across the grid. Rows wrap; a short last row (the web's five
# cells) only has its left cell, so landing on the gap takes that instead.
static func pause_move(m: Node2D, dx: int, dy: int) -> void:
	var n := pause_ids(m).size()
	var rows := (n + PAUSE_COLS - 1) / PAUSE_COLS
	var col: int = int(m.pause_idx) % PAUSE_COLS
	var row: int = int(m.pause_idx) / PAUSE_COLS
	if dx != 0:
		col = wrapi(col + dx, 0, PAUSE_COLS)
	if dy != 0:
		row = wrapi(row + dy, 0, rows)
	var i := row * PAUSE_COLS + col
	if i >= n:
		i = row * PAUSE_COLS
	m.pause_idx = i
	Sfx.play("ui")


static func open_walk_card(m: Node2D) -> void:
	m.pause_view = "walk"
	Sfx.play("ui")


static func close_walk_card(m: Node2D) -> void:
	m.pause_view = ""
	Sfx.play("ui")


# The walk you are on, from what the game already knows: its name and gloss,
# then each goal with how far along it is, or the lesson in the tutorial.
static func walk_card(m: Node2D) -> Dictionary:
	var key := "tutorial" if m.tutorial_mode else String(m.lvl)
	var out := {"name": m._walk_name(), "gloss": String(Game.LEVEL_SUBTITLES.get(key, "")),
		"time": clock(float(m.elapsed)), "goals": [], "lesson": ""}
	if m.tutorial_mode:
		var st: Dictionary = TutorialSteps.step(m.tut_step)
		# the closing "done" step is the tutorial's last card, not a lesson
		if String(st.id) != "" and String(st.id) != "done":
			out.lesson = "Lesson %d of %d: %s" % [int(m.tut_step) + 1, TutorialSteps.step_count() - 1,
				String(st.title)]
		return out
	for q: Dictionary in m.active_quests:
		var target := int(q.target)
		var hit: bool = m.run_goals_hit.has(q.id)
		var done: bool = hit or ((not Game.daily) and Game.goal_done(m.lvl, q.id))
		var got := target if done else mini(int(q.fn.call()), target)
		var state: int
		if hit:
			state = UiIcons.Check.DONE_NOW
		elif done:
			state = UiIcons.Check.DONE_BEFORE
		else:
			state = UiIcons.Check.PARTIAL if got > 0 else UiIcons.Check.OPEN
		out.goals.append({"text": m._quest_text(q), "got": got, "target": target, "done": done,
			"state": state})
	return out


static func tick_walk_card(m: Node2D) -> void:
	if (Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pause")
			or Input.is_action_just_pressed("plant")):
		close_walk_card(m)


# --- questions: START AGAIN and EXIT GAME ask first --------------------------

# tests swap this in so a confirmed exit can be checked without ending the run
static var quit_hook := Callable()

const CONFIRMS := {
	"restart": {"title": "START AGAIN", "body": "Start this walk again?"},
	"exit": {"title": "EXIT GAME", "body": "Quit the game?"},
	"first": {"title": "FIRST TIME?", "body": "A short walk that shows you the ropes."},
}


static func open_confirm(m: Node2D, which: String) -> void:
	m.confirm_id = which
	Sfx.play("ui")


static func confirm_card(m: Node2D) -> Dictionary:
	return CONFIRMS.get(String(m.confirm_id), {"title": "", "body": ""})


static func confirm_cancel(m: Node2D) -> void:
	m.confirm_id = ""
	Sfx.play("ui")


static func confirm_accept(m: Node2D) -> void:
	var which := String(m.confirm_id)
	m.confirm_id = ""
	match which:
		"restart":
			restart_walk(m)
		"exit":
			quit_game(m)


static func quit_game(m: Node2D) -> void:
	if quit_hook.is_valid():
		quit_hook.call()
		return
	m.get_tree().quit()


static func tick_confirm(m: Node2D) -> void:
	if String(m.confirm_id) == "first":
		tick_first(m)
		return
	if Input.is_action_just_pressed("plant"):
		confirm_accept(m)
	elif Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pause"):
		confirm_cancel(m)


# The title's first-walk question: the tutorial (the default, on the main
# button), straight to the walks, or a box ticked so it never asks again.
static func tick_first(m: Node2D) -> void:
	if Input.is_action_just_pressed("plant"):
		m.confirm_id = ""
		Sfx.play("ui")
		start_tutorial(m)
	elif Input.is_action_just_pressed("bark"):
		m.confirm_id = ""
		Sfx.play("ui")
		_go_step(m, 1)
	elif Input.is_action_just_pressed("pee"):
		Game.ask_tutorial = not Game.ask_tutorial
		Game.save_records()
		Sfx.play("ui")
	elif Input.is_action_just_pressed("pause"):
		confirm_cancel(m)


static func start_tutorial(m: Node2D) -> void:
	Game.level_id = "tutorial"
	Game.quick_start = true
	m.get_tree().reload_current_scene()


# Straight from the first walk into the first real one: no menu between.
static func to_first_walk(m: Node2D) -> void:
	Game.level_id = "barri"
	Game.quick_start = true
	m.get_tree().reload_current_scene()


# Straight back into the same walk, skipping the menus: what "try again"
# means. main._ready starts the walk when it finds this set.
static func restart_walk(m: Node2D) -> void:
	Game.quick_start = true
	m.get_tree().reload_current_scene()


static func to_walk_select(m: Node2D) -> void:
	Game.menu_step = 1
	# out of the tutorial, the walk select opens on the first real walk
	if m.tutorial_mode:
		Game.level_id = "barri"
	m.get_tree().reload_current_scene()


# Input on a stopped walk: a result, a game-over or the daily card.
static func tick_end(m: Node2D) -> bool:
	if m.tutorial_mode and m.finished and Input.is_action_just_pressed("plant"):
		to_first_walk(m)
		return true
	if Input.is_action_just_pressed("restart"):
		restart_walk(m)
		return true
	if Input.is_action_just_pressed("bark"):
		to_walk_select(m)
		return true
	return false


# --- the wardrobe -----------------------------------------------------------

static func open_shop(m: Node2D) -> void:
	m.in_shop = true
	m.shop_preview.visible = true
	apply_menu_step(m)
	refresh_shop(m)
	Sfx.play("ui")


static func close_shop(m: Node2D) -> void:
	m.in_shop = false
	m.shop_preview.visible = false
	apply_menu_step(m)
	Sfx.play("ui")


static func tick_shop(m: Node2D) -> void:
	if Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pause"):
		close_shop(m)
	elif Input.is_action_just_pressed("move_down"):
		shop_step(m, 1)
	elif Input.is_action_just_pressed("move_up"):
		shop_step(m, -1)
	elif Input.is_action_just_pressed("move_right"):
		shop_tab(m, 1)
	elif Input.is_action_just_pressed("move_left"):
		shop_tab(m, -1)
	elif Input.is_action_just_pressed("plant"):
		shop_select(m)


static func shop_data(m: Node2D, kind: String, key: String) -> Dictionary:
	match kind:
		"collar": return Game.COLLARS[key]
		"coat": return Game.COATS[key]
		_: return Game.BANDANAS[key]


static func equip(m: Node2D, kind: String, key: String) -> void:
	Game.equip(kind, key)


static func wearing(kind: String, key: String) -> bool:
	return ((kind == "collar" and Game.collar == key) or (kind == "bandana" and Game.bandana == key)
		or (kind == "coat" and Game.coat == key))


# "wearing", "owned", "afford" (not owned, enough bones) or "short"
static func shop_state(kind: String, key: String) -> String:
	if wearing(kind, key):
		return "wearing"
	if Game.is_owned(kind, key):
		return "owned"
	var cost := int(shop_data(null, kind, key).cost)
	return "afford" if Game.total_bones >= cost else "short"


static func shop_tab_of(m: Node2D) -> String:
	return String(m.shop_items[m.shop_idx].kind)


# the item indices on one tab, in list order
static func shop_tab_items(m: Node2D, kind: String) -> Array:
	var out := []
	for i in range(m.shop_items.size()):
		if String(m.shop_items[i].kind) == kind:
			out.append(i)
	return out


static func shop_step(m: Node2D, dir: int) -> void:
	var items := shop_tab_items(m, shop_tab_of(m))
	var at := items.find(m.shop_idx)
	m.shop_idx = int(items[wrapi(at + dir, 0, items.size())])
	refresh_shop(m)
	Sfx.play("ui")


static func shop_tab(m: Node2D, dir: int) -> void:
	var t := SHOP_TABS.find(shop_tab_of(m))
	var kind: String = SHOP_TABS[wrapi(t + dir, 0, SHOP_TABS.size())]
	var items := shop_tab_items(m, kind)
	# land on what she is wearing from that tab, so the cursor starts on
	# something that means something
	m.shop_idx = int(items[0])
	for i: int in items:
		if wearing(kind, String(m.shop_items[i].key)):
			m.shop_idx = i
	refresh_shop(m)
	Sfx.play("ui")


static func shop_select(m: Node2D) -> void:
	var it: Dictionary = m.shop_items[m.shop_idx]
	var kind: String = it.kind
	var key: String = it.key
	if Game.is_owned(kind, key) or Game.buy(kind, key):
		equip(m, kind, key)
		Game.save_records()
		Sfx.play("ui")
	else:
		m.locked_nudge = 0.35
	refresh_shop(m)


static func refresh_shop(m: Node2D) -> void:
	# the preview wears what is highlighted, over what she has on
	var highlighted: Dictionary = m.shop_items[m.shop_idx]
	var preview_collar: String = Game.collar
	var preview_bandana: String = Game.bandana
	var preview_coat: String = Game.coat
	match String(highlighted.kind):
		"collar": preview_collar = highlighted.key
		"coat": preview_coat = highlighted.key
		_: preview_bandana = highlighted.key
	m.shop_preview.set_cosmetic_preview(preview_collar, preview_bandana, preview_coat)


# --- the progress screen ------------------------------------------------------

static func open_progress(m: Node2D) -> void:
	m.in_progress_view = true
	apply_menu_step(m)
	Sfx.play("ui")


static func close_progress(m: Node2D) -> void:
	m.in_progress_view = false
	apply_menu_step(m)
	Sfx.play("ui")


static func progress_rows(m: Node2D) -> Array:
	var out := []
	for lv in Game.LEVELS:
		var row := {"id": lv, "name": Game.LEVEL_NAMES[lv], "gloss": Game.LEVEL_SUBTITLES.get(lv, ""),
			"locked": not Game.is_unlocked(lv), "gate": int(Game.STAR_GATE.get(lv, 0))}
		row["stars"] = Game.stars(lv)
		row["goals"] = Game.goals_count(lv)
		row["goals_total"] = (m.LEVEL_GOAL_IDS.get(lv, []) as Array).size()
		row["best"] = ""
		if Game.records.has(lv) and int(Game.records[lv].get("bones", 0)) > 0:
			row["best"] = "%d bones  %s" % [int(Game.records[lv].bones), clock(float(Game.records[lv].time))]
		out.append(row)
	return out


# --- notices: the cards a walk can end on ---------------------------------

static func show_notice(m: Node2D, template: String) -> void:
	# the first line is the card's title, the rest its body. The label holds
	# the text (the soak tool reads it) and menu_screen.gd draws the card.
	m.frozen = true
	m.dim.visible = true
	m.msg_label.visible = true
	Prompts.set_text(m.msg_label, template)


static func notice(m: Node2D) -> Dictionary:
	var parts := String(m.msg_label.text).split("\n")
	var title := parts[0] if parts.size() > 0 else ""
	var body: Array[String] = []
	for i in range(1, parts.size()):
		body.append(parts[i])
	# no blank lines at either end of the body
	while not body.is_empty() and body[0].strip_edges() == "":
		body.remove_at(0)
	while not body.is_empty() and body[body.size() - 1].strip_edges() == "":
		body.remove_at(body.size() - 1)
	return {"title": title, "body": body}


# --- settings ---------------------------------------------------------------

static func settings_keys(m: Node2D) -> Array:
	# the browser owns the window, so offering a fullscreen toggle there
	# would be a button that lies
	if OS.has_feature("web"):
		return ["master", "sfx", "music", "goals"]
	return ["master", "sfx", "music", "fullscreen", "goals"]


static func settings_rows(m: Node2D) -> Array:
	# the panel draws whatever this returns, so a new setting is one entry
	var out := []
	for k in settings_keys(m):
		var v: float = 0.0
		var kind := "slider"
		match k:
			"master": v = Game.vol_master
			"sfx": v = Game.vol_sfx
			"music": v = Game.vol_music
			"fullscreen":
				v = 1.0 if Game.fullscreen else 0.0
				kind = "toggle"
			"goals":
				v = 1.0 if Game.goals_expanded else 0.0
				kind = "toggle"
		out.append({"name": m.SETTING_NAMES[k], "kind": kind, "v": v})
	return out


static func pad_hints(m: Node2D) -> bool:
	return Prompts.pad()


static func check_settings_roundtrip(m: Node2D) -> Array:
	# The settings are only worth having if they survive a restart, and a
	# typo in a ConfigFile key fails silently - the value simply reverts to
	# its default the next time you launch. So write odd values, read them
	# back, and put the player's own settings back afterwards.
	var p: Array = []
	var keep := [Game.vol_master, Game.vol_sfx, Game.vol_music, Game.fullscreen]
	Game.vol_master = 0.3
	Game.vol_sfx = 0.1
	Game.vol_music = 0.7
	Game.fullscreen = true
	Game.save_records()
	Game.vol_master = 0.0
	Game.vol_sfx = 0.0
	Game.vol_music = 0.0
	Game.fullscreen = false
	Game.load_records()
	if not (is_equal_approx(Game.vol_master, 0.3) and is_equal_approx(Game.vol_sfx, 0.1)
			and is_equal_approx(Game.vol_music, 0.7) and Game.fullscreen):
		p.append("settings did not survive a save/load round trip (%.2f %.2f %.2f %s)"
			% [Game.vol_master, Game.vol_sfx, Game.vol_music, Game.fullscreen])
	Game.vol_master = keep[0]
	Game.vol_sfx = keep[1]
	Game.vol_music = keep[2]
	Game.fullscreen = keep[3]
	Game.save_records()
	# and the slider steps must stay inside 0..1 however hard you lean on them
	m.settings_idx = 0
	for i in range(20):
		settings_adjust(m, -1)
	if Game.vol_master < 0.0:
		p.append("master volume ran below zero (%.2f)" % Game.vol_master)
	for i in range(30):
		settings_adjust(m, 1)
	if Game.vol_master > 1.0:
		p.append("master volume ran above one (%.2f)" % Game.vol_master)
	Game.vol_master = keep[0]
	Game.apply_settings()
	Game.save_records()
	return p


static func open_settings_from_menu(m: Node2D) -> void:
	open_settings(m)


static func open_settings(m: Node2D) -> void:
	m.in_settings = true
	m.settings_idx = 0
	m.settings_panel.visible = true
	m.dim.visible = true
	# the world stops redrawing while settings are open (_process returns
	# early), so redraw once now to drop the chalked title from behind the panel
	m.queue_redraw()
	Sfx.play("ui")


static func close_settings(m: Node2D) -> void:
	m.in_settings = false
	m.settings_panel.visible = false
	m.queue_redraw()
	Game.save_records()
	Sfx.play("ui")
	if m.paused:
		# back to the pause menu we came from
		m.dim.visible = true
	else:
		apply_menu_step(m)


static func settings_adjust(m: Node2D, dir: int) -> void:
	var keys := settings_keys(m)
	var key: String = keys[m.settings_idx]
	match key:
		"master":
			Game.vol_master = clampf(Game.vol_master + 0.1 * dir, 0.0, 1.0)
			Game.apply_settings()
			Sfx.play("ui")
		"sfx":
			Game.vol_sfx = clampf(Game.vol_sfx + 0.1 * dir, 0.0, 1.0)
			Sfx.play("ui")  # so you hear what you just set
		"music":
			Game.vol_music = clampf(Game.vol_music + 0.1 * dir, 0.0, 1.0)
			Sfx.apply_music_volume()
		"fullscreen":
			Game.fullscreen = not Game.fullscreen
			Game.apply_settings()
			Sfx.play("ui")
		"goals":
			Game.goals_expanded = not Game.goals_expanded
			Sfx.play("ui")


static func tick_settings(m: Node2D) -> void:
	var n: int = settings_keys(m).size()
	if Input.is_action_just_pressed("move_down"):
		m.settings_idx = wrapi(m.settings_idx + 1, 0, n)
		Sfx.play("ui")
	elif Input.is_action_just_pressed("move_up"):
		m.settings_idx = wrapi(m.settings_idx - 1, 0, n)
		Sfx.play("ui")
	elif Input.is_action_just_pressed("move_right"):
		settings_adjust(m, 1)
	elif Input.is_action_just_pressed("move_left"):
		settings_adjust(m, -1)
	elif (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("bark")
			or Input.is_action_just_pressed("plant")):
		close_settings(m)
