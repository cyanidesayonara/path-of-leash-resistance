extends SceneTree

# The tutorial reuses Street geometry, but it is not a campaign run. This test
# exercises the real Game autoload and main scene while all writes are routed
# to a disposable save.

const GameScript := preload("res://game.gd")
const ChallengerScript := preload("res://challenger.gd")
const POPULATED_SAVE := "user://v153_tutorial_populated.cfg"
const MISSING_SAVE := "user://v153_tutorial_missing.cfg"

var failures := 0


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if String(property.name) == property_name:
			return true
	return false


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _cleanup() -> void:
	_remove(POPULATED_SAVE)
	_remove(MISSING_SAVE)


func _default_record() -> Dictionary:
	return {"bones": 0, "time": 0.0, "perfects": 0, "stars": 0, "goals": []}


func _write_populated_profile(game: Node) -> void:
	game.records = {}
	for level in game.LEVELS:
		game.records[level] = _default_record()
	game.records["street"] = {
		"bones": 88,
		"time": 44.0,
		"perfects": 2,
		"stars": 1,
		"goals": ["mark", "sniff", "phone"],
	}
	game.records["daily"] = {"bones": 73, "seed": game.daily_seed()}
	game.total_bones = 321
	game.owned = {
		"collar:red": true,
		"collar:gold": true,
		"bandana:none": true,
		"bandana:navy": true,
		"coat:millie": true,
		"coat:gold": true,
	}
	game.collar = "gold"
	game.bandana = "navy"
	game.coat = "gold"
	game.vol_master = 0.21
	game.vol_sfx = 0.32
	game.vol_music = 0.43
	game.fullscreen = true
	game.goals_expanded = true
	game.save_records()


func _check_clean_profile(game: Node) -> void:
	_check(game.records.size() == game.LEVELS.size(), "missing save removes the daily record")
	for level in game.LEVELS:
		_check(game.records[level] == _default_record(), "missing save resets " + level)
	_check(game.total_bones == 0, "missing save resets the wallet")
	_check(
		game.owned == {"collar:red": true, "bandana:none": true, "coat:millie": true},
		"missing save resets ownership to freebies"
	)
	_check(
		game.collar == "red" and game.bandana == "none" and game.coat == "millie",
		"missing save resets equipped cosmetics"
	)
	_check(
		is_equal_approx(game.vol_master, 0.85)
		and is_equal_approx(game.vol_sfx, 0.9)
		and is_equal_approx(game.vol_music, 0.55),
		"missing save resets all volume settings"
	)
	_check(not game.fullscreen, "missing save resets fullscreen")
	_check(not game.goals_expanded, "missing save resets the goals-card setting")


func _has_challenger_child(node: Node) -> bool:
	for child in node.get_children():
		if child.get_script() == ChallengerScript:
			return true
	return false


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_tutorial_isolation: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_tutorial_isolation: OK")
		quit(0)


func _run() -> void:
	_cleanup()

	# Safe RED evidence even before save-path injection exists: the old main
	# always creates a campaign challenge giver in tutorial mode and has no
	# dedicated tutorial completion path.
	var main_script = load("res://main.gd")
	_check(main_script != null, "real main script loads")
	if main_script == null:
		_finish()
		return
	var probe := Node2D.new()
	probe.set_script(main_script)
	probe.tutorial_mode = true
	probe.call("_spawn_challenger")
	_check(not _has_challenger_child(probe), "tutorial does not spawn a campaign challenge giver")
	var dedicated_completion := probe.has_method("_finish_tutorial_walk")
	_check(dedicated_completion, "tutorial has a dedicated non-campaign result path")
	probe.free()

	var game = root.get_node("Game")
	var injectable := _has_property(game, "save_path")
	_check(injectable, "tutorial integration can inject a disposable Game save path")
	if not injectable or not dedicated_completion:
		_finish()
		return

	game.set("save_path", POPULATED_SAVE)
	_write_populated_profile(game)
	game.records = {}
	game.total_bones = -1
	game.owned = {}
	game.collar = "red"
	game.bandana = "none"
	game.coat = "millie"
	game.vol_master = 1.0
	game.vol_sfx = 1.0
	game.vol_music = 1.0
	game.fullscreen = false
	game.goals_expanded = false
	game.load_records()
	_check(game.total_bones == 321, "populated tutorial fixture loads its wallet")
	_check(game.records.has("daily"), "populated tutorial fixture loads its daily record")
	_check(game.collar == "gold" and game.coat == "gold", "populated tutorial fixture loads equipment")
	_check(game.fullscreen and game.goals_expanded, "populated tutorial fixture loads settings")

	game.level_id = "tutorial"
	game.owner_id = "her"
	game.weather = "snow"
	game.night = true
	game.daily = false
	game.menu_step = 2
	game.set("save_path", MISSING_SAVE)
	game.load_records()
	_check_clean_profile(game)
	_check(
		game.level_id == "tutorial"
		and game.owner_id == "her"
		and game.weather == "snow"
		and game.night
		and not game.daily
		and game.menu_step == 2,
		"missing save reset preserves runtime-only menu and selection state"
	)
	_check(not FileAccess.file_exists(MISSING_SAVE), "missing tutorial fixture remains absent after load")

	var street_before: Dictionary = game.records["street"].duplicate(true)
	var wallet_before := int(game.total_bones)

	var sfx = root.get_node("Sfx")
	sfx.muted = true
	sfx.music_on = false
	if sfx.music_player != null:
		sfx.music_player.stop()
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.frozen = true

	_check(main.tutorial_mode, "real main scene enters tutorial mode")
	_check(main.lvl == "street", "tutorial still reuses Street geometry")
	_check(main.active_quests.is_empty(), "tutorial does not build Street campaign goals")
	_check(not main.tofu_quest_active and not main.tofu_home, "tutorial has no Tofu campaign state")
	_check(main.challenge_giver == null, "tutorial has no active challenge giver reference")
	_check(not bool(main.challenge.active), "tutorial campaign challenge remains inactive")
	_check(get_nodes_in_group("challengers").is_empty(), "tutorial scene contains no challenger node")

	var lesson_step := int(main.tut_step)
	var lesson_bones := int(main.bones)
	main.call("_tut_advance", true)
	_check(main.tut_step == lesson_step + 1, "tutorial lesson progression still advances")
	_check(main.bones == lesson_bones + 2, "tutorial lesson feedback keeps its local bone reward")
	main.call("_update_tut_card")
	_check(main.tut_label.visible and main.tut_hint.visible, "tutorial lesson card remains active during play")

	var post_lesson_bones := int(main.bones)
	main.call("on_tofu_home", main.dog.global_position)
	_check(not main.tofu_home, "tutorial ignores the Tofu campaign completion path")
	_check(main.bones == post_lesson_bones, "tutorial does not award Tofu campaign bones")

	var campaign_goal := {"id": "mark", "text": "claim %d spots", "target": 5}
	main.call("_credit_goal", campaign_goal)
	_check(game.records["street"] == street_before, "tutorial campaign-goal path leaves Street unchanged")
	_check(game.total_bones == wallet_before, "tutorial campaign-goal path leaves wallet unchanged")

	var direct_result: Dictionary = game.record_result("tutorial", 999, 1.0, true)
	_check(
		not bool(direct_result.bones_record) and not bool(direct_result.time_record),
		"Game rejects tutorial campaign result records"
	)
	_check(not game.records.has("tutorial"), "tutorial result does not create a persistent record")
	_check(game.total_bones == wallet_before, "tutorial result does not bank bones")

	main.dog.global_position.y = main.HOME_Y + 10.0
	main.human.global_position.y = main.HOME_Y + 10.0
	main.call("_finish_walk")
	_check(main.finished, "tutorial reaches its own completion state")
	var practice_line := "%d practice bones - not banked" % int(main.bones)
	var expected_results := {
		"title": "GOOD DOG.",
		"stars": 0,
		"rating": "You know the ropes.",
		"rows": [],
		"bones": int(main.bones),
		"phone": int(main.phone_hp),
		"time": int(main.elapsed),
		"goal_bones": 0,
		"lines": [practice_line, "Lessons complete. The real walks are waiting."],
		"prompt": "press  %s  for walk select" % main.call("_kb_or_pad", "R", "Start"),
	}
	_check(main.results == expected_results, "tutorial produces the complete practice-only result payload")
	_check((main.results.lines as Array).has(practice_line), "rendered result text labels practice bones as not banked")
	_check(
		main.results_card.visible
		and not main.tut_label.visible
		and not main.tut_hint.visible
		and not main.goals_card.visible
		and not main.panel.visible
		and main.dim.visible
		and not main.msg_label.visible,
		"visible tutorial result replaces the lesson and campaign HUD"
	)
	_check(game.records["street"] == street_before, "tutorial completion leaves Street record unchanged")
	_check(game.total_bones == wallet_before, "tutorial completion leaves wallet unchanged")
	_check(not main.tofu_quest_active and not main.tofu_home, "tutorial completion leaves Tofu state inactive")
	_check(not bool(main.challenge.active), "tutorial completion leaves campaign challenge inactive")
	_check(not FileAccess.file_exists(MISSING_SAVE), "tutorial paths do not create the missing save fixture")

	var reopened = GameScript.new()
	reopened.set("save_path", MISSING_SAVE)
	reopened.load_records()
	_check(reopened.records["street"] == street_before, "Street record remains unchanged after reload")
	_check(reopened.total_bones == wallet_before, "wallet remains unchanged after reload")
	_check(not reopened.records.has("tutorial"), "reload contains no tutorial campaign record")

	reopened.free()
	main.free()
	_finish()


func _initialize() -> void:
	call_deferred("_run")
