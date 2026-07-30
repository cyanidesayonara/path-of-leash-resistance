extends SceneTree

# Fresh-save progression must work before the player has recorded a result.
# The temporary save path is mandatory: this regression must never touch the
# player's real records.cfg.

const GameScript := preload("res://game.gd")
const MARK_SAVE := "user://v153_fresh_mark_goal.cfg"
const RESULT_SAVE := "user://v153_fresh_record_result.cfg"
const CORRUPT_SAVE := "user://v153_corrupt_profile.cfg"

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
	_remove(MARK_SAVE)
	_remove(RESULT_SAVE)
	_remove(CORRUPT_SAVE)


func _set_unrelated_profile(game: Node, wallet: int) -> void:
	game.total_bones = wallet
	game.owned = {
		"collar:red": true,
		"collar:teal": true,
		"bandana:none": true,
		"bandana:navy": true,
		"coat:millie": true,
		"coat:gold": true,
	}
	game.collar = "teal"
	game.bandana = "navy"
	game.coat = "gold"
	game.vol_master = 0.31
	game.vol_sfx = 0.42
	game.vol_music = 0.53
	game.fullscreen = true
	game.goals_expanded = true


func _check_unrelated_profile(game: Node, wallet: int, label: String) -> void:
	_check(game.total_bones == wallet, label + " preserves the wallet")
	_check(bool(game.call("is_owned", "collar", "teal")), label + " preserves collar ownership")
	_check(bool(game.call("is_owned", "bandana", "navy")), label + " preserves bandana ownership")
	_check(bool(game.call("is_owned", "coat", "gold")), label + " preserves coat ownership")
	_check(
		game.collar == "teal" and game.bandana == "navy" and game.coat == "gold",
		label + " preserves equipped cosmetics"
	)
	_check(
		is_equal_approx(game.vol_master, 0.31)
		and is_equal_approx(game.vol_sfx, 0.42)
		and is_equal_approx(game.vol_music, 0.53),
		label + " preserves volume settings"
	)
	_check(game.fullscreen and game.goals_expanded, label + " preserves boolean settings")


func _check_record(
	record: Dictionary,
	bones: int,
	time: float,
	perfects: int,
	stars: int,
	goals: Array,
	label: String
) -> void:
	_check(record.size() == 5, label + " contains exactly the five record fields")
	_check(int(record.get("bones", -1)) == bones, label + " has the expected bones field")
	_check(is_equal_approx(float(record.get("time", -1.0)), time), label + " has the expected time field")
	_check(int(record.get("perfects", -1)) == perfects, label + " has the expected perfects field")
	_check(int(record.get("stars", -1)) == stars, label + " has the expected stars field")
	_check((record.get("goals", []) as Array) == goals, label + " has the expected goals field")


func _check_canonical_profile(game: Node, label: String) -> void:
	_check(game.records.size() == game.LEVELS.size(), label + " removes the daily record")
	for level in game.LEVELS:
		_check_record(game.records[level], 0, 0.0, 0, 0, [], label + " resets " + level)
	_check(game.total_bones == 0, label + " resets the wallet")
	_check(
		game.owned == {"collar:red": true, "bandana:none": true, "coat:millie": true},
		label + " resets ownership to freebies"
	)
	_check(
		game.collar == "red" and game.bandana == "none" and game.coat == "millie",
		label + " resets equipped cosmetics"
	)
	_check(
		is_equal_approx(game.vol_master, 0.85)
		and is_equal_approx(game.vol_sfx, 0.9)
		and is_equal_approx(game.vol_music, 0.55),
		label + " resets volume settings"
	)
	_check(not game.fullscreen and not game.goals_expanded, label + " resets boolean settings")


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_fresh_save_progression: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_fresh_save_progression: OK")
		quit(0)


func _initialize() -> void:
	_cleanup()
	var mark_game = GameScript.new()
	var injectable := _has_property(mark_game, "save_path")
	_check(injectable, "Game exposes an injectable save_path for isolated tests")
	if not injectable:
		mark_game.free()
		_finish()
		return

	mark_game.set("save_path", MARK_SAVE)
	_set_unrelated_profile(mark_game, 41)
	mark_game.records = {}

	var goal_ids := ["mark", "sniff", "phone", "paws", "bag", "fetch"]
	_check(mark_game.mark_goal("street", goal_ids[0]), "mark_goal initializes an empty records dictionary")
	_check_record(
		mark_game.records["street"],
		0,
		0.0,
		0,
		0,
		["mark"],
		"mark_goal initializer"
	)
	for id in goal_ids.slice(1):
		_check(
			mark_game.mark_goal("street", id),
			"fresh empty records accept goal '%s' before the first result" % id
		)
	_check_record(mark_game.records["street"], 0, 0.0, 0, 2, goal_ids, "six-goal Street record")
	_check(mark_game.goals_count("street") == 6, "six pre-result goals remain in the Street record")
	_check(mark_game.stars("street") == 2, "six pre-result goals earn two stars")
	_check(mark_game.is_unlocked("park"), "pre-result stars contribute to campaign unlocks")
	_check_unrelated_profile(mark_game, 41, "mark_goal")

	var mark_reopened = GameScript.new()
	mark_reopened.set("save_path", MARK_SAVE)
	mark_reopened.load_records()
	_check_record(mark_reopened.records["street"], 0, 0.0, 0, 2, goal_ids, "reloaded Street goals")
	_check(mark_reopened.is_unlocked("park"), "the mark_goal unlock survives a save reload")
	_check_unrelated_profile(mark_reopened, 41, "mark_goal reload")

	var result_game = GameScript.new()
	result_game.set("save_path", RESULT_SAVE)
	_set_unrelated_profile(result_game, 41)
	result_game.records = {}
	var result: Dictionary = result_game.record_result("park", 17, 42.5, true)
	_check(bool(result.bones_record), "the first result establishes a bones record")
	_check(bool(result.time_record), "the first result establishes a time record")
	_check_record(result_game.records["park"], 17, 42.5, 1, 0, [], "record_result initializer")
	_check_unrelated_profile(result_game, 58, "record_result")

	var result_reopened = GameScript.new()
	result_reopened.set("save_path", RESULT_SAVE)
	result_reopened.load_records()
	_check_record(result_reopened.records["park"], 17, 42.5, 1, 0, [], "reloaded first result")
	_check_unrelated_profile(result_reopened, 58, "record_result reload")

	var corrupt := FileAccess.open(CORRUPT_SAVE, FileAccess.WRITE)
	corrupt.store_string("[global\nthis is not a config")
	corrupt.close()
	result_reopened.level_id = "park"
	result_reopened.owner_id = "her"
	result_reopened.weather = "snow"
	result_reopened.night = true
	result_reopened.daily = true
	result_reopened.menu_step = 2
	result_reopened.set("save_path", CORRUPT_SAVE)
	result_reopened.load_records()
	_check_canonical_profile(result_reopened, "corrupt save")
	_check(
		result_reopened.level_id == "park"
		and result_reopened.owner_id == "her"
		and result_reopened.weather == "snow"
		and result_reopened.night
		and result_reopened.daily
		and result_reopened.menu_step == 2,
		"corrupt save reset preserves runtime-only selection state"
	)

	result_reopened.free()
	result_game.free()
	mark_reopened.free()
	mark_game.free()
	_finish()
