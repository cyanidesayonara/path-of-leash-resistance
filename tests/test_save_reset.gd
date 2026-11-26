extends SceneTree

# The campaign's fresh start (autoload/game.gd, SAVE_VERSION): a save from
# before it keeps its settings and nothing that was earned.
# - every kind of old save: the released one with everything in it, one from
#   before the chase gates, one with settings alone
# - nothing is written on load; the first save replaces the file, keeps the old
#   one beside it, once, and never asks again
# - a save of the current version loads untouched
# - the main menu's line, and its fit in every language
# Everything runs on scratch files: never the player's records.cfg.

const GameScript := preload("res://autoload/game.gd")
const PATH := "user://test_save_reset.cfg"
const OLD := "user://test_save_reset_before_campaign.cfg"

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _clean() -> void:
	for p in [PATH, OLD]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _game() -> Node:
	var g: Node = GameScript.new()
	g.save_path = PATH
	g.persist = true
	return g


# a 1.76 save with everything in it
func _full(cf: ConfigFile) -> void:
	for lv in ["barri", "street", "neteja", "girona", "raval"]:
		cf.set_value(lv, "bones", 40)
		cf.set_value(lv, "time", 90.0)
		cf.set_value(lv, "perfects", 2)
		cf.set_value(lv, "stars", 3)
		cf.set_value(lv, "style", 900)
		cf.set_value(lv, "goals", ["mark", "sniff", "phone"])
	cf.set_value("global", "total_bones", 5000)
	cf.set_value("global", "tutorial_done", true)
	cf.set_value("global", "walks_lost", 12)
	cf.set_value("global", "gate_open", PackedStringArray(["raval", "site"]))
	cf.set_value("global", "gates_version", 5)
	cf.set_value("cosmetics", "owned", ["collar:red", "collar:gold", "coat:gold"])
	cf.set_value("cosmetics", "collar", "gold")
	cf.set_value("cosmetics", "coat", "gold")
	cf.set_value("player", "dog", "bruna")
	cf.set_value("player", "dog_upgrades", {"millie": {"nose": 2}})
	cf.set_value("player", "training", {"millie": 4})
	cf.set_value("player", "finds_found", {"barri": ["x"]})
	cf.set_value("player", "skills_done", {"millie": ["barri"]})
	cf.set_value("tips", "seen", PackedStringArray(["a"]))
	cf.set_value("achievements", "unlocked", PackedStringArray(["boss_mamut"]))
	cf.set_value("achievements", "dogs_walked", PackedStringArray(["millie"]))
	cf.set_value("achievements", "gallery_bones", PackedStringArray(["drac"]))
	cf.set_value("freedom", "agility_best", 31.0)
	_settings(cf)


func _settings(cf: ConfigFile) -> void:
	cf.set_value("settings", "vol_master", 0.31)
	cf.set_value("settings", "vol_sfx", 0.42)
	cf.set_value("settings", "vol_music", 0.53)
	cf.set_value("settings", "language", "ca")
	cf.set_value("settings", "control_layout", "arrows")
	cf.set_value("settings", "key_binds", {"poop": KEY_V})
	cf.set_value("settings", "pad_binds", {"pickup": JOY_BUTTON_Y, "turbo": {"axis": JOY_AXIS_TRIGGER_LEFT, "sign": 1}})
	cf.set_value("settings", "screen_shake", false)
	cf.set_value("settings", "flashes", false)
	cf.set_value("settings", "text_size", "large")
	cf.set_value("settings", "goals_expanded", true)
	cf.set_value("settings", "ask_tutorial", false)
	cf.set_value("settings", "free_play", true)


func _is_fresh(g: Node, what: String) -> void:
	var clean: Node = GameScript.new()
	clean._reset_persisted_state()
	for k: String in ["records", "total_bones", "owned", "collar", "bandana", "coat", "dog", "dog_upgrades", "training",
			"finds_found", "skills_done", "human_look", "tutorial_done", "walks_lost", "tips_seen", "achievements",
			"dogs_walked", "gallery_bones", "agility_best", "ask_tutorial", "free_play"]:
		_check(g.get(k) == clean.get(k), "%s: %s is a new player's (%s)" % [what, k, g.get(k)])
	_check(g.total_stars() == 0 and not g.is_unlocked("raval") and not g.is_unlocked("neteja") and g.is_unlocked("barri"),
		"%s: the campaign is at its first walk" % what)
	clean.free()


func _settings_kept(g: Node, what: String) -> void:
	_check(is_equal_approx(g.vol_master, 0.31) and is_equal_approx(g.vol_sfx, 0.42) and is_equal_approx(g.vol_music, 0.53), "%s: the volumes are kept" % what)
	var tb: Variant = g.pad_binds.get("turbo")
	var trig_ok: bool = tb is Dictionary and int((tb as Dictionary).get("axis", -1)) == JOY_AXIS_TRIGGER_LEFT
	_check(g.language == "ca" and int(g.key_binds.get("poop", 0)) == KEY_V
		and int(g.pad_binds.get("pickup", -1)) == JOY_BUTTON_Y and trig_ok,
		"%s: language and controls are kept" % what)
	_check(not g.screen_shake and not g.flashes and g.text_size == "large" and g.goals_expanded, "%s: accessibility is kept" % what)


func _run() -> void:
	_clean()
	# 1. the released save
	var cf := ConfigFile.new()
	_full(cf)
	cf.save(PATH)
	var bytes := FileAccess.get_file_as_bytes(PATH)
	var g := _game()
	g.load_records()
	_is_fresh(g, "1.76")
	_settings_kept(g, "1.76")
	_check(g.fresh_start, "a returning player is told")
	_check(FileAccess.get_file_as_bytes(PATH) == bytes and not FileAccess.file_exists(OLD), "loading writes nothing")

	# a run that never saves leaves it exactly as it was
	var again := _game()
	again.load_records()
	_check(again.fresh_start and FileAccess.get_file_as_bytes(PATH) == bytes, "and the next launch finds it as it was")
	again.persist = false
	again.save_records()
	_check(FileAccess.get_file_as_bytes(PATH) == bytes, "a run that does not persist never touches it")
	again.free()

	# 2. the first real save
	g.record_result("barri", 7, 80.0, false)
	_check(not g.fresh_start, "told until the first save, and not after")
	_check(FileAccess.get_file_as_bytes(OLD) == bytes, "the old save is kept beside the new one, byte for byte")
	var back := _game()
	back.load_records()
	_check(not back.fresh_start and int(back.records["barri"].bones) == 7 and back.total_bones == g.total_bones, "the new save loads as it is")
	_settings_kept(back, "after the save")
	back.total_bones = 900
	back.save_records()
	_check(FileAccess.get_file_as_bytes(OLD) == bytes, "a later save leaves the kept one alone")
	back.free()
	g.free()

	# 3. from before the chase gates: no gates version, ownership by bare name
	_clean()
	cf = ConfigFile.new()
	cf.set_value("street", "stars", 3)
	cf.set_value("global", "total_bones", 400)
	cf.set_value("cosmetics", "owned", ["red", "none", "gold"])
	_settings(cf)
	cf.save(PATH)
	g = _game()
	g.load_records()
	_is_fresh(g, "an early save")
	_settings_kept(g, "an early save")
	_check(g.fresh_start, "an early player is told too")
	g.free()

	# 4. settings alone: nothing lost, nothing said
	_clean()
	cf = ConfigFile.new()
	_settings(cf)
	cf.save(PATH)
	g = _game()
	g.load_records()
	_settings_kept(g, "settings alone")
	_check(not g.fresh_start, "a save with nothing earned in it says nothing")
	g.free()

	# 5. no save at all
	_clean()
	g = _game()
	g.load_records()
	_is_fresh(g, "a new player")
	_check(not g.fresh_start, "a new player is told nothing")
	g.free()
	_clean()

	# 6. the main menu's line, in every language
	var I: GDScript = load("res://hud/i18n.gd")
	var e: Dictionary = I.T["menu_fresh_start"]
	for lang in ["en", "ca", "es"]:
		_check(String(e[lang]).count("%d") == 1, "the line counts the walks (%s)" % lang)
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	game.fresh_start = true
	for lang in ["en", "ca", "es"]:
		I.set_language(lang)
		for k in range(4):
			await process_frame
	I.set_language("en")
	_check(is_instance_valid(m), "the main menu draws it")
	# the window losing focus is not the player doing something
	_clean()
	cf = ConfigFile.new()
	_full(cf)
	cf.save(PATH)
	bytes = FileAccess.get_file_as_bytes(PATH)
	var keep_path: String = game.save_path
	game.save_path = PATH
	game.persist = true
	game.load_records()
	m.on_app_paused()
	_check(game.fresh_start and FileAccess.get_file_as_bytes(PATH) == bytes, "looking away replaces nothing")
	game.save_records()
	m.on_app_paused()
	_check(not game.fresh_start and FileAccess.get_file_as_bytes(PATH) != bytes, "and saves as ever once there is a new save")
	game.persist = false
	game.save_path = keep_path
	_clean()

	print("test_save_reset: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
