extends SceneTree

# Comprehensive test suite verifying the 26-walk campaign expansion,
# 15 Tony Hawk-style quests per walk, 5 Keystone Chase Milestone gates,
# and THPS-style upgradable dog attributes.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(10.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	var sfx: Node = root.get_node("Sfx")
	if sfx != null:
		sfx.muted = true

	var goals_mod: GDScript = load("res://systems/goals.gd")
	var th_mod: GDScript = load("res://systems/tony_hawk.gd")
	var level_check: GDScript = load("res://world/level_check.gd")
	var main_scene: PackedScene = load("res://main.tscn")

	game.persist = false
	game.free_play = false

	# 1. Campaign Registration & 15 Goals Per Walk
	_check(game.LEVELS.size() == 27, "27 campaign walks registered in LEVELS: %d" % game.LEVELS.size())
	_check(game.CAROUSEL.size() == 28, "28 carousel walks registered (including tutorial): %d" % game.CAROUSEL.size())

	for lv in game.LEVELS:
		_check(game.LEVEL_NAMES.has(lv), "LEVEL_NAMES has %s" % lv)
		_check(game.LEVEL_SUBTITLES.has(lv), "LEVEL_SUBTITLES has %s" % lv)
		_check(game.STAR_GATE.has(lv), "STAR_GATE has %s" % lv)
		_check(goals_mod.LEVEL_GOAL_IDS.has(lv), "LEVEL_GOAL_IDS has %s" % lv)
		var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get(lv, [])
		_check(g_list.size() == 15, "%s has exactly 15 goals: %d" % [lv, g_list.size()])
		_check(th_mod.CLOCK_TARGETS.has(lv), "CLOCK_TARGETS has %s" % lv)
		_check(th_mod.JAMON_POS.has(lv), "JAMON_POS has %s" % lv)

	# 2. Keystone Chase Milestone Gating
	_check(game.chase_gate_needed("site") == "besos", "site gated by besos")
	_check(game.chase_gate_needed("montjuic") == "neteja", "montjuic gated by neteja")
	_check(game.chase_gate_needed("tibidabo") == "vet", "tibidabo gated by vet")
	_check(game.chase_gate_needed("raval") == "gracia", "raval gated by gracia")

	# 3. THPS Upgradable Dog Attributes System
	game.records = {}
	game.total_bones = 200
	game.dog = "millie"
	game.dog_upgrades = {}

	# Baseline Millie
	var base_speed: float = game.dog_speed_mult("millie")
	var base_plant: float = game.dog_plant_mult("millie")
	var base_herd: float = game.dog_herd_mult("millie")
	var base_accel: float = game.dog_accel_mult("millie")
	_check(is_equal_approx(base_speed, 1.0), "Millie base speed is 1.0")
	_check(is_equal_approx(base_plant, 1.0), "Millie base plant is 1.0")

	# Upgrade Speed
	_check(game.can_upgrade_stat("millie", "speed"), "can upgrade speed with 200 bones")
	var ok_up: bool = game.upgrade_dog_stat("millie", "speed")
	_check(ok_up, "upgraded speed successfully")
	_check(game.total_bones == 160, "bones deducted: 160 left")
	_check(game.get_dog_stat("millie", "speed") == 1, "millie speed level is 1")
	_check(is_equal_approx(game.dog_speed_mult("millie"), 1.05), "millie speed mult increased to 1.05: %f" % game.dog_speed_mult("millie"))

	# Cap at MAX_STAT_POINTS (5)
	for i in range(4):
		game.upgrade_dog_stat("millie", "speed")
	_check(game.get_dog_stat("millie", "speed") == 5, "millie speed level capped at 5")
	_check(not game.can_upgrade_stat("millie", "speed"), "cannot upgrade speed past 5")

	# Upgrade Pipa plant (with Pipa unlocked)
	game.records["barri"] = {"bones": 50, "time": 90.0, "perfects": 1, "stars": 15, "goals": ["mark", "sniff", "phone"], "style": 100}
	_check(game.is_dog_unlocked("pipa"), "pipa is unlocked with 15 stars")
	game.total_bones = 100
	var pipa_base_plant: float = game.dog_plant_mult("pipa")
	var pipa_ok: bool = game.upgrade_dog_stat("pipa", "plant")
	_check(pipa_ok, "pipa plant upgraded")
	_check(game.get_dog_stat("pipa", "plant") == 1, "pipa plant level is 1")
	_check(is_equal_approx(game.dog_plant_mult("pipa"), pipa_base_plant + 0.10), "pipa plant mult gained +0.10")

	# 4. LevelCheck on boars and gracia
	for ch_lv in ["boars", "gracia"]:
		game.level_id = ch_lv
		var m: Node2D = main_scene.instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		m._skip_title()
		var probs: Array = level_check.check(m)
		_check(probs.is_empty(), "LevelCheck on %s passes cleanly: %s" % [ch_lv, str(probs)])
		m.queue_free()
		await process_frame

	print("test_campaign_mastery: %d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_campaign_mastery: ALL CHECKS PASSED!")
		quit(0)
	else:
		quit(1)
