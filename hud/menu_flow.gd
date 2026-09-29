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

const DETAIL_ROWS := ["walker", "time", "weather"]
const PAUSE_ROWS := ["resume", "restart", "settings", "quit"]
const SHOP_TABS := ["collar", "bandana", "coat"]
const SHOP_TAB_NAMES := {"collar": "COLLARS", "bandana": "BANDANAS", "coat": "COATS"}
const STEP_NAMES := ["CHOOSE A WALK", "GET READY"]


# --- which screen is up ---------------------------------------------------

static func screen(m: Node2D) -> String:
	if m.in_settings:
		return "settings"
	if m.msg_label != null and m.msg_label.visible:
		return "notice"
	if m.results_card != null and m.results_card.visible:
		return "results"
	if m.paused:
		return "pause"
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
			return [["plant", "start"], ["pause", "settings"]]
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
			return [["up_down", "pick"], ["plant", "select"], ["pause", "resume"]]
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
		return [["bark", "on to the walks"], ["restart", "practise again"]]
	if m.finished:
		return [["restart", "walk it again"], ["bark", "walk select"]]
	return [["restart", "try again"], ["bark", "walk select"]]


# --- the title's steps ------------------------------------------------------

static func apply_menu_step(m: Node2D) -> void:
	# one screen, one choice: the walk HUD stays down until the walk begins
	m.panel.visible = m.started
	m.goals_card.visible = m.started and not m.tutorial_mode
	m.dim.visible = (not m.started) and (m.in_shop or m.in_progress_view)
	# the chalked name is part of the world, so the world redraws to add or
	# drop it
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
	Sfx.play("ui")


# The controls, for the getting-ready card: [action, what it does].
static func controls() -> Array:
	return [["move", "move"], ["plant", "dig in / squat"], ["pee", "pee"], ["bark", "bark"],
		["turbo", "run"], ["pause", "pause"]]


static func start_walk(m: Node2D) -> void:
	m.started = true
	m.frozen = false
	# snapshot progress so the results can report stars and unlocks
	m.run_pre_total_stars = Game.total_stars()
	m.run_pre_level_stars = Game.stars(m.lvl)
	Game.menu_step = 1
	m.panel.visible = true
	m.goals_card.visible = not m.tutorial_mode
	m.dim.visible = false
	m.queue_redraw()


# Title input. Returns true when _process should stop for this frame.
static func tick_title(m: Node2D) -> bool:
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
				Sfx.play("ui")
				_go_step(m, 1)
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
	m.dim.visible = true
	Sfx.play("ui")


static func resume(m: Node2D) -> void:
	m.paused = false
	m.frozen = false
	m.dim.visible = false
	Sfx.play("ui")


static func tick_pause(m: Node2D) -> void:
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("bark"):
		resume(m)
	elif Input.is_action_just_pressed("move_down"):
		m.pause_idx = wrapi(m.pause_idx + 1, 0, PAUSE_ROWS.size())
		Sfx.play("ui")
	elif Input.is_action_just_pressed("move_up"):
		m.pause_idx = wrapi(m.pause_idx - 1, 0, PAUSE_ROWS.size())
		Sfx.play("ui")
	elif Input.is_action_just_pressed("pee"):
		open_settings(m)
	elif Input.is_action_just_pressed("plant"):
		match String(PAUSE_ROWS[m.pause_idx]):
			"resume":
				resume(m)
			"restart":
				restart_walk(m)
			"settings":
				open_settings(m)
			"quit":
				to_walk_select(m)


static func pause_rows(m: Node2D) -> Array:
	return ["RESUME", "START AGAIN", "SETTINGS", "QUIT TO WALK SELECT"]


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
