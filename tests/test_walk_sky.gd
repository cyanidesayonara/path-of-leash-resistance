extends SceneTree

# A walk with its own sky (El Diluvi's rain, La Castanyada's dark, the first
# walk's clear day) sets it for that walk only. Browsing the walk select past
# one used to leave its rain or its dark on every walk after it, because the
# walk wrote over the player's own GET READY choice.

var _failures := 0
var _level: Node2D = null


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   %s" % what)
	else:
		print("  FAIL %s" % what)
		_failures += 1


func _load(level_id: String) -> Node2D:
	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
		_level = null
	var game = root.get_node("Game")
	game.level_id = level_id
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	await process_frame
	_level = m
	return m


func _sky() -> String:
	var game = root.get_node("Game")
	return "%s/%s" % [game.weather, "night" if game.night else "day"]


func _row(m: Node2D, id: String) -> Dictionary:
	for r: Dictionary in load("res://hud/menu_flow.gd").details_rows(m):
		if String(r.id) == id:
			return r
	return {}


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.weather = "snow"
	game.night = false

	var m := await _load("barri")
	_check(_sky() == "snow/day", "El Barri keeps the snowy day you picked (%s)" % _sky())
	_check(not bool(_row(m, "weather").fixed) and not bool(_row(m, "time").fixed),
		"on El Barri both rows can be changed")

	m = await _load("rain")
	_check(_sky() == "rain/day", "El Diluvi rains whatever you picked (%s)" % _sky())
	_check(bool(_row(m, "weather").fixed) and not bool(_row(m, "time").fixed),
		"on El Diluvi the weather row is the walk's, the time row yours")
	# a choice made while a walk holds the sky still belongs to the player
	game.toggle_night()
	_check(_sky() == "rain/night", "after dark on El Diluvi (%s)" % _sky())

	m = await _load("market")
	_check(_sky() == "snow/night", "El Mercat gets your snow back, and the dark you chose (%s)" % _sky())

	m = await _load("spook")
	_check(_sky() == "snow/night", "La Castanyada is after dark (%s)" % _sky())
	_check(bool(_row(m, "time").fixed) and not bool(_row(m, "weather").fixed),
		"on La Castanyada the time row is the walk's")
	m = await _load("spook")
	_check(_sky() == "snow/night", "La Castanyada stays dark on a reload (%s)" % _sky())

	m = await _load("barri")
	game.toggle_night()
	_check(_sky() == "snow/day", "back on El Barri, a day picked again (%s)" % _sky())
	m = await _load("spook")
	m = await _load("tutorial")
	_check(_sky() == "clear/day", "the first walk is a clear day (%s)" % _sky())
	m = await _load("oldtown")
	_check(_sky() == "snow/day", "El Gòtic after the first walk is your snowy day (%s)" % _sky())

	_check(not "daily" in game.CAROUSEL, "the walk select has no Daily Walk")
	_check(not game.LEVEL_NAMES.has("daily"), "and no name for one")

	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
	if _failures > 0:
		print("test_walk_sky: %d FAILURES" % _failures)
		quit(1)
	else:
		print("test_walk_sky: OK")
		quit(0)
