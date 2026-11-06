extends SceneTree

# Tests for the Keystone Chase Milestone Gate system:
# - Each tier requires completing the preceding tier's chase level end-to-end to enter
# - When locked by an uncompleted chase level, walk_info and best_line report
#   "Finish [Level Name] to open this walk."
# - A save from before the gates keeps the walks it already had open
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
	var saved_open: Array[String] = game.gate_open.duplicate()
	game.gate_open.clear()

	# 1. Fresh state: verify chase gate requirements
	game.records = {}
	for lv in game.LEVELS:
		game.records[lv] = game._default_level_record()

	_check(game.chase_gate_needed("barri") == "", "barri has no chase gate")
	_check(game.chase_gate_needed("neteja") == "", "neteja, the first chase, has no chase gate")
	_check(game.chase_gate_needed("besos") == "neteja", "besos requires neteja completed")
	_check(game.chase_gate_needed("market") == "neteja", "market requires neteja completed")
	_check(game.chase_gate_needed("vet") == "besos", "vet requires besos completed")
	_check(game.chase_gate_needed("spook") == "vet", "spook requires vet completed")
	_check(game.chase_gate_needed("site") == "boars", "site requires boars completed")
	_check(game.chase_gate_needed("raval") == "gracia", "raval requires gracia completed")

	# 2. Check lock text formatting
	var market_best: String = game.best_line("market")
	_check(market_best == "locked - finish La Neteja first", "market best_line names La Neteja: %s" % market_best)
	var vet_best: String = game.best_line("vet")
	_check(vet_best == "locked - finish El Besòs first", "vet best_line names El Besos: %s" % vet_best)
	var spook_best: String = game.best_line("spook")
	_check(spook_best == "locked - finish El Veterinari first", "spook best_line names El Veterinari: %s" % spook_best)

	# 3. Even with ample stars, chase block prevents unlock
	game.mark_goal("barri", "mark")
	for lv: String in ["street", "park", "beach", "neteja"]:
		if not game.records.has(lv):
			game.records[lv] = game._default_level_record()
		game.records[lv]["stars"] = 3
	_check(game.total_stars() >= int(game.STAR_GATE.get("market", 0)),
		"stars enough for market's star gate (%d)" % game.total_stars())
	_check(not game.is_unlocked("market"), "market is locked when neteja is uncompleted even with stars")

	# Check walk_info plaque text
	game.level_id = "market"
	var dummy_main := Node2D.new()
	var info: Dictionary = MenuFlow.walk_info(dummy_main)
	_check(bool(info.get("locked", false)), "walk_info flags market as locked")
	_check(String(info.get("chase_gate", "")) == "neteja", "walk_info records chase_gate as neteja")
	var line0: String = (info.get("lines", [""])[0] as String)
	_check(line0 == "Finish La Neteja to open this walk.", "walk_info line names La Neteja: %s" % line0)

	# 4. Completing neteja clears the gate
	_check(not game.has_completed("neteja"), "neteja is not completed yet")
	game.record_result("neteja", 15, 80.0, false)
	_check(game.has_completed("neteja"), "neteja is now completed")
	_check(game.chase_gate_needed("market") == "", "market no longer needs chase gate")
	_check(game.is_unlocked("market"), "with the stars and La Neteja walked, market opens")

	# 5. Completing besos clears vet
	_check(game.chase_gate_needed("vet") == "besos", "vet still needs besos")
	game.record_result("besos", 20, 95.0, false)
	_check(game.has_completed("besos"), "besos is now completed")
	_check(game.chase_gate_needed("vet") == "", "vet chase gate cleared")

	# 6. Finale: Raval Boss Arena opens upon completing gracia regardless of star count
	_check(not game.is_unlocked("raval"), "raval locked before gracia")
	# Simulate beating gracia
	game.records["gracia"] = {"bones": 50, "time": 110.0, "perfects": 1, "stars": 3, "goals": [], "style": 100, "completed": true}
	_check(game.has_completed("gracia"), "gracia completed")
	_check(game.is_unlocked("raval"), "raval unlocks directly when gracia is beaten regardless of stars")

	# 7. A save from before the gates keeps the gated walks it had open by
	# stars or had walked, but never one of the walks that came with the gates
	game.records = {}
	for lv in game.LEVELS:
		game.records[lv] = game._default_level_record()
	game.records["barri"].stars = 3
	game.records["street"].stars = 3
	game.records["park"].stars = 3
	game.records["beach"].stars = 3
	game.records["rain"].stars = 3
	game.records["market"].stars = 2
	game.records["montjuic"].bones = 12
	game.gate_open.clear()
	game._grandfather_chase_gates()
	_check(game.is_unlocked("market") and game.is_unlocked("rain"), "an old save at 17 stars keeps market and rain open")
	_check(game.chase_gate_needed("montjuic") == "", "an old save that walked montjuic keeps it")
	_check(game.chase_gate_needed("vet") == "besos", "an old save below the vet's stars is still gated there")
	_check(not game.gate_open.has("gracia") and not game.gate_open.has("raval"), "new walks are never grandfathered")

	# 8. A save from before the reshuffle keeps every walk the old order had
	# open, stars and all, and nothing the old order still had shut
	game.gate_open.clear()
	game.records = {}
	for lv in game.LEVELS:
		game.records[lv] = game._default_level_record()
	for lv: String in ["barri", "street", "park", "beach", "rain", "market"]:
		game.records[lv].stars = 3
	game.records["oldtown"].stars = 1
	game.records["besos"].bones = 9
	game._grandfather_reorder()
	_check(game.is_unlocked("rain") and game.is_unlocked("market") and game.is_unlocked("oldtown"),
		"rain, market and El Gotic stay open at 19 stars though they now follow La Neteja")
	_check(game.is_unlocked("trail") and game.is_unlocked("station"), "the trail and L'Estacio stay open by their old stars")
	_check(game.is_unlocked("besos"), "a walked El Besos stays open")
	_check(not game.is_unlocked("montjuic"), "montjuic needed La Neteja before too: still shut")
	_check(not game.is_unlocked("horta"), "horta was shut before and is shut now")
	game.gate_open.clear()

	# 9. A save from 1.69 keeps the walks that order had open: La Superilla
	# came after Gràcia then and needs Els Senglars now
	game.gate_open.clear()
	game.records = {}
	for lv in game.LEVELS:
		game.records[lv] = game._default_level_record()
	var filled := 0
	for lv: String in game.LEVELS:
		if filled >= 15:
			break
		game.records[lv].stars = 3
		filled += 1
	game.records["gracia"].bones = 9
	_check(not game.is_unlocked("superilla"), "without the old save's rules, La Superilla waits for Els Senglars")
	game._grandfather_from(game.V2_STAR_GATE, game.V2_CHASE_GATE)
	_check(game.is_unlocked("superilla"), "a 1.69 save with 45 stars and Gràcia walked keeps La Superilla open")
	game.gate_open.clear()

	# 10. Free play mode opens all walks
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
	game.gate_open.assign(saved_open)
	dummy_main.queue_free()

	if failures.is_empty():
		print("test_chase_milestone_gates: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_chase_milestone_gates: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
