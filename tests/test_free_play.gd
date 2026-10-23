extends SceneTree

# Tests for the Free Play / Demo mode toggle:
# - unlocks all walks freely for practice without star gate requirements;
# - suppresses permanent career persistence (goals, stars, bone records, style records, wallet);
# - survives save/load settings roundtrip;
# - clean toggle off restores career star gates.

var MenuFlow: GDScript

var checks := 0
var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: %s" % message)
		print("FAIL: %s" % message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	MenuFlow = load("res://hud/menu_flow.gd")
	var game = root.get_node("Game")

	var orig_free_play: bool = game.free_play
	var orig_persist: bool = game.persist
	game.persist = false

	# 1. Default state
	game.free_play = false
	_check(game.is_unlocked("tutorial"), "tutorial is always unlocked")
	_check(game.is_unlocked("barri"), "barri (0 stars) is unlocked")
	var high_walk: String = "partit"
	var high_gate: int = int(game.STAR_GATE.get(high_walk, 27))
	var naturally_unlocked: bool = game.total_stars() >= high_gate
	_check(game.is_unlocked(high_walk) == naturally_unlocked, "partit follows star gate when free play is off")

	# 2. Free play unlock
	game.free_play = true
	_check(game.is_unlocked(high_walk), "partit is unlocked when free play is on")
	for lv: String in game.LEVELS:
		_check(game.is_unlocked(lv), "walk '%s' is unlocked under free play" % lv)

	# 3. Non-persistence of goals under free play
	var test_walk := "besos"
	var test_goal := "test_non_persisted_goal"
	var goals_before: int = game.goals_count(test_walk)
	var marked: bool = game.mark_goal(test_walk, test_goal)
	_check(not marked, "mark_goal returns false under free play")
	_check(game.goals_count(test_walk) == goals_before, "goals count did not increment under free play")
	_check(not game.goal_done(test_walk, test_goal), "goal is not marked done under free play")

	# 4. Non-persistence of results and bone banking under free play
	var bones_before: int = game.total_bones
	var res: Dictionary = game.record_result(test_walk, 999, 10.0, true)
	_check(not bool(res.get("bones_record", false)), "record_result does not award bones_record under free play")
	_check(not bool(res.get("time_record", false)), "record_result does not award time_record under free play")
	_check(game.total_bones == bones_before, "total bones wallet does not bank bones under free play")

	# 5. Non-persistence of style under free play
	var style_marked: bool = game.record_style(test_walk, 500)
	_check(not style_marked, "record_style returns false under free play")

	# 6. Restoring free play off returns to standard star gating
	game.free_play = false
	_check(game.is_unlocked(high_walk) == naturally_unlocked, "turning free play off restores star gate")

	# 7. MenuFlow settings integration
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.started = false
	m.frozen = true

	var keys: Array = MenuFlow.settings_keys(m)
	_check(keys.has("free_play"), "settings keys include free_play")
	var rows: Array = MenuFlow.settings_rows(m)
	var fp_row_found := false
	for r: Dictionary in rows:
		if String(r.get("name", "")) == "FREE PLAY (DEMO)":
			fp_row_found = true
			_check(String(r.get("kind", "")) == "toggle", "free play setting is a toggle")
	_check(fp_row_found, "settings rows contain 'FREE PLAY (DEMO)'")

	# Test settings adjust toggle
	m.settings_idx = keys.find("free_play")
	game.free_play = false
	MenuFlow.settings_adjust(m, 1)
	_check(game.free_play == true, "settings adjust toggles free play on")
	MenuFlow.settings_adjust(m, 1)
	_check(game.free_play == false, "settings adjust toggles free play off")

	# Settings roundtrip check
	game.persist = true
	var roundtrip_problems: Array = MenuFlow.check_settings_roundtrip(m)
	_check(roundtrip_problems.is_empty(), "settings roundtrip with free_play passed (%s)" % ", ".join(roundtrip_problems))

	# Cleanup
	m.queue_free()
	game.free_play = orig_free_play
	game.persist = orig_persist

	print("\ntest_free_play: %d checks, %d failures" % [checks, failures.size()])
	if not failures.is_empty():
		for f: String in failures:
			print(" - %s" % f)
		quit(1)
	else:
		print("FREE PLAY OK")
		quit(0)
