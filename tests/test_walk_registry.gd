extends SceneTree

# Tests that every walk in Game.LEVELS is registered across all per-walk
# tables, and that no table contains unknown walk keys without being on a
# documented allow list (e.g. "tutorial", "title", "freedom").
#
# When a walk is added to the game, it must be registered in all of these
# tables. If a walk is deliberately absent from WALK_MODULES because its
# behavior is built into main.gd directly, list it in WALK_MODULES_EXEMPT.

# Walks deliberately absent from main.gd's WALK_MODULES.
# When a walk has no dedicated systems/ or world/ module and its drawing/logic
# is handled entirely by main.gd or level_build.gd, it can be exempted here.
# Currently all 32 walks have their own module wired into WALK_MODULES.
const WALK_MODULES_EXEMPT := {}

const TABLES := [
	{
		"script": "res://autoload/game.gd",
		"table": "LEVEL_NAMES",
		"allow_extra": ["tutorial"],
	},
	{
		"script": "res://autoload/game.gd",
		"table": "LEVEL_SUBTITLES",
		"allow_extra": ["tutorial"],
	},
	{
		"script": "res://autoload/game.gd",
		"table": "LEVEL_SUBTITLES_CA",
		"allow_extra": ["tutorial"],
	},
	{
		"script": "res://autoload/game.gd",
		"table": "LEVEL_SUBTITLES_ES",
		"allow_extra": ["tutorial"],
	},
	{
		"script": "res://autoload/game.gd",
		"table": "STAR_GATE",
		"allow_extra": [],
	},
	{
		"script": "res://autoload/game.gd",
		"table": "CAMPAIGN_SKY",
		"allow_extra": [],
	},
	{
		"script": "res://autoload/game.gd",
		"table": "CAROUSEL",
		"allow_extra": ["tutorial"],
		"is_array": true,
	},
	{
		"script": "res://main.gd",
		"table": "WALK_MODULES",
		"allow_extra": [],
		"exempt": WALK_MODULES_EXEMPT,
	},
	{
		"script": "res://systems/goals.gd",
		"table": "LEVEL_GOAL_IDS",
		"allow_extra": [],
	},
	{
		"script": "res://systems/tony_hawk.gd",
		"table": "CLOCK_TARGETS",
		"allow_extra": [],
	},
	{
		"script": "res://systems/tony_hawk.gd",
		"table": "JAMON_POS",
		"allow_extra": [],
	},
	{
		"script": "res://audio/music.gd",
		"table": "STYLES",
		"allow_extra": ["title", "freedom"],
	},
	{
		"script": "res://world/world_sign.gd",
		"table": "MATERIALS",
		"allow_extra": ["tutorial"],
	},
]

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	var levels: Array[String] = game.LEVELS

	# 1. Check all tables for completeness and extraneous keys
	for entry: Dictionary in TABLES:
		var script_path: String = entry["script"]
		var table_name: String = entry["table"]
		var allow_extra: Array = entry.get("allow_extra", [])
		var exempt_map: Dictionary = entry.get("exempt", {})
		var is_array: bool = entry.get("is_array", false)

		var script_res = load(script_path)
		_check(script_res != null, "%s loaded" % script_path)
		if script_res == null:
			continue

		var table_val = script_res.get(table_name)
		_check(table_val != null, "%s has %s" % [script_path.get_file(), table_name])
		if table_val == null:
			continue

		if is_array:
			var arr: Array = table_val
			for lv: String in levels:
				_check(lv in arr, "(%s, %s)" % [lv, table_name])
			for item in arr:
				var key := String(item)
				_check(key in levels or key in allow_extra, "(%s, %s) unexpected key" % [key, table_name])
		else:
			var dict: Dictionary = table_val
			for lv: String in levels:
				if lv in exempt_map:
					continue
				_check(dict.has(lv), "(%s, %s)" % [lv, table_name])
			for k in dict:
				var key := String(k)
				_check(key in levels or key in allow_extra, "(%s, %s) unexpected key" % [key, table_name])

	# 2. Check world_sign.gd material definitions
	var sign_res = load("res://world/world_sign.gd")
	if sign_res != null:
		var sign_materials: Dictionary = sign_res.get("MATERIALS")
		var sign_feel: Dictionary = sign_res.get("FEEL")
		_check(sign_materials != null and sign_feel != null, "world_sign.gd has MATERIALS and FEEL")
		if sign_materials != null and sign_feel != null:
			for walk: String in sign_materials:
				var mat: String = String(sign_materials[walk])
				_check(sign_feel.has(mat), "(%s, world_sign.FEEL) material missing for walk %s" % [mat, walk])
			for mat_key in sign_feel:
				var mat := String(mat_key)
				# "prints" is used when weather == "snow"
				var valid_mat: bool = (mat == "prints") or (mat in sign_materials.values())
				_check(valid_mat, "(%s, world_sign.FEEL) unused material definition" % mat)

	print("test_walk_registry: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
