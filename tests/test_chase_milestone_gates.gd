extends SceneTree

# Tests for the Keystone Chase Milestone Gate system:
# - Each tier requires completing the preceding tier's chase level end-to-end to enter
# - When locked by an uncompleted chase level, walk_info and best_line report
#   "Complete [Level Name] to enter"
# - Beating the chase level immediately clears the chase block for the next tier
# - The Grand Finale (Rambla del Raval) unlocks directly upon beating Festa de Gràcia regardless of stars
# - Free play mode bypasses all gates

var MenuFlow: GDScript
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
	MenuFlow = load("res://hud/menu_flow.gd")
	var game: Node = root.get_node("Game")
	game.persist = false
	game.free_play = false
	var saved_records: Dictionary = game.records.duplicate(true)
	var saved_bones: int = game.total_bones

	# 1. Fresh state: verify chase gate requirements
	game.records = {}
	for lv in game.LEVELS:
		game.records[lv] = game._default_level_record()

	_check(game.chase_gate_needed("barri") == "", "barri has no chase gate")
	_check(game.chase_gate_needed("besos") == "", "besos has no chase gate")
	_check(game.chase_gate_needed("site") == "besos", "site requires besos completed")
	_check(game.chase_gate_needed("spook") == "besos", "spook requires besos completed")
	_check(game.chase_gate_needed("montjuic") == "neteja", "montjuic requires neteja completed")
	_check(game.chase_gate_needed("tibidabo") == "vet", "tibidabo requires vet completed")
	_check(game.chase_gate_needed("raval") == "gracia", "raval requires gracia completed")

	# 2. Check lock text formatting
	var site_best: String = game.best_line("site")
	_check(site_best == "locked - complete El Besòs to enter", "site best_line says complete El Besos: %s" % site_best)
	var mont_best: String = game.best_line("montjuic")
	_check(mont_best == "locked - complete La Neteja to enter", "montjuic best_line says complete La Neteja: %s" % mont_best)
	var tib_best: String = game.best_line("tibidabo")
	_check(tib_best == "locked - complete El Veterinari to enter", "tibidabo best_line says complete El Veterinari: %s" % tib_best)

	# 3. Even with ample stars, chase block prevents unlock
	game.mark_goal("barri", "mark")
	_check(not game.is_unlocked("site"), "site is locked when besos is uncompleted even with stars")

	# Check walk_info plaque text
	game.level_id = "site"
	var dummy_main := Node2D.new()
	var info: Dictionary = MenuFlow.walk_info(dummy_main)
	_check(bool(info.get("locked", false)), "walk_info flags site as locked")
	_check(String(info.get("chase_gate", "")) == "besos", "walk_info records chase_gate as besos")
	var line0: String = (info.get("lines", [""])[0] as String)
	_check(line0 == "Complete El Besòs to enter", "walk_info line says Complete El Besos to enter: %s" % line0)

	# 4. Completing besos clears the gate
	_check(not game.has_completed("besos"), "besos is not completed yet")
	game.record_result("besos", 15, 80.0, false)
	_check(game.has_completed("besos"), "besos is now completed")
	_check(game.chase_gate_needed("site") == "", "site no longer needs chase gate")

	# 5. Completing neteja clears montjuic
	_check(game.chase_gate_needed("montjuic") == "neteja", "montjuic still needs neteja")
	game.record_result("neteja", 20, 95.0, false)
	_check(game.has_completed("neteja"), "neteja is now completed")
	_check(game.chase_gate_needed("montjuic") == "", "montjuic chase gate cleared")

	# 6. Finale: Raval Boss Arena opens upon completing gracia regardless of star count
	_check(not game.is_unlocked("raval"), "raval locked before gracia")
	# Simulate beating gracia
	game.records["gracia"] = {"bones": 50, "time": 110.0, "perfects": 1, "stars": 3, "goals": [], "style": 100, "completed": true}
	_check(game.has_completed("gracia"), "gracia completed")
	_check(game.is_unlocked("raval"), "raval unlocks directly when gracia is beaten regardless of stars")

	# 7. Free play mode opens all walks
	game.records = {}
	for lv in game.LEVELS:
		game.records[lv] = game._default_level_record()
	game.free_play = true
	_check(game.is_unlocked("site"), "free play unlocks site")
	_check(game.is_unlocked("montjuic"), "free play unlocks montjuic")
	_check(game.is_unlocked("raval"), "free play unlocks raval")
	_check(game.chase_gate_needed("site") == "", "free play clears chase_gate_needed")

	# Restore state
	game.free_play = false
	game.records = saved_records
	game.total_bones = saved_bones
	dummy_main.queue_free()

	if failures.is_empty():
		print("test_chase_milestone_gates: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_chase_milestone_gates: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
