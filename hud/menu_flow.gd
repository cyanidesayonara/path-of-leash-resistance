extends RefCounted

# The title-screen flow and the screens reachable from it: the menu steps
# (owner, walk select, night/weather toggles), the wardrobe shop, the settings
# panel's rows and navigation, and the progress screen.
#
# Static functions over main's state. main.gd keeps a same-name forwarder for
# each (tests, settings_panel.gd and level_check.gd call several by name) and
# keeps the input handling that drives them in its _process for now.




static func owner_label_text(m: Node2D, owner_id: String) -> String:
	return "WALKING:  %s" % owner_id.to_upper()


static func apply_menu_step(m: Node2D) -> void:
	# Tony Hawk rules: each screen shows ONE choice and ONE instruction.
	# Gameplay HUD (panel, quests) stays hidden until the walk begins.
	var in_menu: bool = not m.started
	m.panel.visible = m.started
	m.goals_card.visible = m.started and not m.tutorial_mode
	# The game's name and the walk's name are drawn INTO the level now (chalk
	# on the pavement, a stick in the sand), so the labels that used to float
	# over the top of them are gone. What is left on the HUD is the things a
	# label is genuinely better at: the prompt and the run's details.
	m.title_l.visible = false
	m.sub_l.visible = false
	m.select_l.visible = false
	m.record_l.visible = in_menu and m.menu_step == 1
	m.owner_l.visible = in_menu and m.menu_step == 2
	m.night_l.visible = in_menu and m.menu_step == 2
	m.weather_l.visible = in_menu and m.menu_step == 2
	m.prompt_l.visible = in_menu
	# discreet, bottom-left, the same treatment as the version tag - the
	# middle of the title screen is already busy with the level blurb
	m.menu_hint_l.visible = in_menu
	m.menu_hint_l.text = "%s  settings" % m._kb_or_pad("ESC", "Back")
	if not in_menu:
		return
	match m.menu_step:
		0:
			m.title_l.add_theme_font_size_override("font_size", 60)
			m.title_l.position.y = 210
			m.title_l.text = "PATH OF LEASH RESISTANCE"
			m.sub_l.add_theme_font_size_override("font_size", 22)
			m.sub_l.position.y = 288
			m.sub_l.text = "you are the dog. go and touch grass."
		1:
			m.title_l.add_theme_font_size_override("font_size", 30)
			m.title_l.position.y = 150
			m.title_l.text = "CHOOSE YOUR WALK   (%d stars)" % Game.total_stars()
			var sel: String = Game.level_id  # carousel id (may be "daily")
			var locked := not Game.is_unlocked(sel)
			m.select_l.add_theme_font_size_override("font_size", 52)
			m.select_l.text = ("[ %s ]" % Game.LEVEL_NAMES[sel]) if locked else ("<   %s   >" % Game.LEVEL_NAMES[sel])
			m.select_l.position.y = 220
			m.record_l.position.y = 300
			var rl: String = Game.best_line(sel)
			if sel != "daily" and Game.is_unlocked(sel):
				rl += "    goals %d/%d" % [Game.goals_count(sel), int((m.LEVEL_GOAL_IDS.get(sel, []) as Array).size())]
			m.record_l.text = rl
		2:
			m.title_l.add_theme_font_size_override("font_size", 40)
			m.title_l.position.y = 150
			m.title_l.text = Game.LEVEL_NAMES[Game.level_id].to_upper()
			m.owner_l.text = owner_label_text(m, Game.owner_id)
	refresh_menu_text(m)


static func open_shop(m: Node2D) -> void:
	m.in_shop = true
	for l: Label in [m.title_l, m.sub_l, m.prompt_l, m.select_l, m.owner_l, m.night_l, m.weather_l, m.record_l,
			m.menu_hint_l]:
		l.visible = false
	m.shop_title_l.visible = true
	m.shop_l.visible = true
	m.shop_preview_bg.visible = true
	m.shop_preview_l.visible = true
	m.shop_preview.visible = true
	# the preview dog is a Node2D, so it cannot anchor itself the way the panel
	# behind it does - park it on the panel's centre instead, read at open time
	# so it follows the cluster onto whatever shape the screen turns out to be
	m.shop_preview.position = m.shop_preview_bg.position + Vector2(220.0, 175.0)
	refresh_shop(m)


static func shop_data(m: Node2D, kind: String, key: String) -> Dictionary:
	match kind:
		"collar": return Game.COLLARS[key]
		"coat": return Game.COATS[key]
		_: return Game.BANDANAS[key]


static func equip(m: Node2D, kind: String, key: String) -> void:
	Game.equip(kind, key)


static func shop_select(m: Node2D) -> void:
	var it: Dictionary = m.shop_items[m.shop_idx]
	var kind: String = it.kind
	var key: String = it.key
	if Game.is_owned(kind, key) or Game.buy(kind, key):
		equip(m, kind, key)
		Game.save_records()
	# (if the buy failed, not enough bones - the price stays shown)
	refresh_shop(m)


static func refresh_shop(m: Node2D) -> void:
	m.shop_title_l.text = "MILLIE'S WARDROBE      %d bones" % Game.total_bones
	var lines := ""
	for i in range(m.shop_items.size()):
		var it: Dictionary = m.shop_items[i]
		var key: String = it.key
		var data: Dictionary = shop_data(m, String(it.kind), key)
		var equipped: bool = (
			(it.kind == "collar" and Game.collar == key)
			or (it.kind == "bandana" and Game.bandana == key)
			or (it.kind == "coat" and Game.coat == key)
		)
		var tag := ""
		if equipped:
			tag = "  [EQUIPPED]"
		elif Game.is_owned(String(it.kind), key):
			tag = "  (owned - press to wear)"
		else:
			tag = "  %d bones" % int(data.cost)
		var cursor: String = ">  " if i == m.shop_idx else "    "
		lines += "%s%s%s\n" % [cursor, data.name, tag]
	lines += "\nleft / right browse    %s buy or wear    %s back" % [m._kb_or_pad("SPACE", "A"), m._kb_or_pad("E", "B")]
	m.shop_l.text = lines
	var highlighted: Dictionary = m.shop_items[m.shop_idx]
	var preview_collar: String = Game.collar
	var preview_bandana: String = Game.bandana
	var preview_coat: String = Game.coat
	match String(highlighted.kind):
		"collar": preview_collar = highlighted.key
		"coat": preview_coat = highlighted.key
		_: preview_bandana = highlighted.key
	m.shop_preview.set_cosmetic_preview(preview_collar, preview_bandana, preview_coat)


static func refresh_menu_text(m: Node2D) -> void:
	# controller labels only when a controller is attached
	var pad := Input.get_connected_joypads().size() > 0
	m.hint_l.text = ("stick: move   A: dig in / squat   X: pee   B: bark   RB: turbo   Back: pause" if pad
		else "WASD: move   SPACE: dig in / squat   Q: pee   E: bark   SHIFT: turbo   ESC: pause")
	var fixed: String = "  (fixed today)" if Game.daily else "        (%s)" % m._kb_or_pad("E", "B")
	m.night_l.text = "TIME:  %s%s" % [("NIGHT" if Game.night else "DAY"), fixed]
	m.weather_l.text = "WEATHER:  %s%s" % [Game.WEATHER_NAMES[Game.weather], "" if Game.daily else "        (%s)" % m._kb_or_pad("Q", "X")]
	var go = m._kb_or_pad("SPACE", "A")
	match m.menu_step:
		0:
			m.prompt_l.text = "press  %s  to begin" % go
			m.hint_l.visible = false
		1:
			if not Game.is_unlocked(Game.level_id):
				m.prompt_l.text = "locked - earn %d stars" % int(Game.STAR_GATE.get(Game.level_id, 0))
			else:
				m.prompt_l.text = "%s / %s  browse     %s  choose     %s  wardrobe     %s  progress" % [m._kb_or_pad("A", "<"), m._kb_or_pad("D", ">"), go, m._kb_or_pad("E", "B"), m._kb_or_pad("Q", "X")]
			m.hint_l.visible = false
		2:
			m.prompt_l.text = "press  %s  to go walkies" % go
			m.hint_l.visible = true


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
	return Input.get_connected_joypads().size() > 0


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
	for l: Label in [m.title_l, m.sub_l, m.prompt_l, m.select_l, m.owner_l, m.night_l, m.weather_l, m.record_l,
			m.hint_l, m.menu_hint_l]:
		l.visible = false
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
		# back to the pause card we came from
		m.pause_l.visible = true
		m.dim.visible = true
	else:
		m.dim.visible = false
		apply_menu_step(m)
		refresh_menu_text(m)


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


static func progress_text(m: Node2D) -> String:
	var t := "YOUR WALKS\n\n"
	for lv in Game.LEVELS:
		var nm: String = Game.LEVEL_NAMES[lv]
		if not Game.is_unlocked(lv):
			t += "%s   -   locked (%d stars)\n" % [nm, int(Game.STAR_GATE.get(lv, 0))]
			continue
		var total: int = (m.LEVEL_GOAL_IDS.get(lv, []) as Array).size()
		var rec := "no record yet"
		if Game.records.has(lv) and int(Game.records[lv].get("bones", 0)) > 0:
			rec = "%d bones  %ds" % [int(Game.records[lv].bones), int(Game.records[lv].time)]
		t += "%s   %s   goals %d/%d   %s\n" % [nm, Game.star_str(Game.stars(lv)), Game.goals_count(lv), total, rec]
	t += "\nTOTAL:  %d stars    %d bones banked\n\n%s  back" % [
		Game.total_stars(), Game.total_bones, m._kb_or_pad("E", "B")]
	return t
