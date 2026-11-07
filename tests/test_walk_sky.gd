extends SceneTree

# The campaign walks each walk in its own sky (Game.CAMPAIGN_SKY), shown on
# the walk card. A finished walk can be walked free (GET READY's WALK row):
# the player's own time and weather, nothing recorded. A walk with its own
# sky (El Diluvi's rain, La Castanyada's dark, the first walk's clear day)
# keeps it even then. Whatever a walk holds, it holds for that walk only:
# browsing past one used to leave its rain or its dark on every walk after it.

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
	var keep_records: Dictionary = game.records.duplicate(true)
	var keep_free_play: bool = game.free_play
	var keep_free_walk: bool = game.free_walk
	var keep_sky := [game.weather, game.night]
	game.free_play = false
	game.free_walk = false
	game.records = {}
	for lv: String in game.LEVELS:
		game.records[lv] = game._default_level_record()
	game.weather = "snow"
	game.night = false
	var Flow = load("res://hud/menu_flow.gd")

	for lv: String in game.LEVELS:
		if lv != "tutorial":
			_check(game.CAMPAIGN_SKY.has(lv), "the campaign has a sky for %s" % lv)

	# the campaign: a walk not yet finished is walked in its own sky
	var m := await _load("barri")
	_check(_sky() == "clear/day", "the campaign walks El Barri on a clear day (%s)" % _sky())
	_check(bool(_row(m, "weather").fixed) and bool(_row(m, "time").fixed), "and holds both rows")
	_check(bool(_row(m, "mode").fixed) and String(_row(m, "mode").value) == "CAMPAIGN",
		"an unfinished walk cannot be walked free")
	_check(game.recording("barri"), "the campaign records")
	m = await _load("reial")
	_check(_sky() == "clear/night", "Plaça Reial is walked after dark (%s)" % _sky())
	game.free_walk = true
	m = await _load("market")
	_check(_sky() == "clear/day", "FREE WALK does nothing on a walk not finished (%s)" % _sky())

	# a finished walk, walked free: the player's own sky, nothing recorded
	game.records["barri"].time = 60.0
	m = await _load("barri")
	_check(_sky() == "snow/day", "a free walk on El Barri is your snowy day (%s)" % _sky())
	_check(not bool(_row(m, "weather").fixed) and not bool(_row(m, "time").fixed), "with both rows yours")
	_check(not bool(_row(m, "mode").fixed) and String(_row(m, "mode").value) == "FREE WALK", "the row says FREE WALK")
	_check(not game.recording("barri"), "a free walk records nothing")
	_check(not game.mark_goal("barri", "mark"), "a free walk marks no goal")
	game.toggle_night()
	m = await _load("market")
	_check(_sky() == "clear/day", "the next unfinished walk is the campaign's again (%s)" % _sky())
	m = await _load("barri")
	_check(_sky() == "snow/night", "and El Barri gets back the dark you chose (%s)" % _sky())

	# GET READY's WALK row switches between the two on the spot
	for i in Flow.details_rows(m).size():
		if String(Flow.details_rows(m)[i].id) == "mode":
			m.details_idx = i
	Flow.details_change(m, 1)
	_check(not game.free_walk and _sky() == "clear/day", "back to the campaign: a clear day (%s)" % _sky())
	Flow.details_change(m, 1)
	_check(game.free_walk and _sky() == "snow/night", "free again: your snowy night (%s)" % _sky())

	# a walk's own sky holds even on a free walk
	game.records["rain"].time = 60.0
	game.records["spook"].time = 60.0
	m = await _load("rain")
	_check(_sky() == "rain/night", "El Diluvi rains on a free walk too (%s)" % _sky())
	_check(bool(_row(m, "weather").fixed) and not bool(_row(m, "time").fixed),
		"on a free El Diluvi the weather row is the walk's, the time row yours")
	m = await _load("spook")
	_check(_sky() == "snow/night", "La Castanyada is after dark on a free walk too (%s)" % _sky())
	_check(bool(_row(m, "time").fixed) and not bool(_row(m, "weather").fixed),
		"on a free La Castanyada the time row is the walk's")
	m = await _load("tutorial")
	_check(_sky() == "clear/day", "the first walk is a clear day (%s)" % _sky())
	m = await _load("barri")
	_check(_sky() == "snow/night", "after the first walk, your free sky again (%s)" % _sky())

	# the walk card says how the campaign walks it
	_check(Flow.sky_line("espanya") == "night, clear", "the card: Plaça d'Espanya at night (%s)" % Flow.sky_line("espanya"))
	_check(Flow.sky_line("rain") == "day, rain", "the card: El Diluvi in the rain (%s)" % Flow.sky_line("rain"))

	_check(not "daily" in game.CAROUSEL, "the walk select has no Daily Walk")
	_check(not game.LEVEL_NAMES.has("daily"), "and no name for one")

	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
	game.records = keep_records
	game.free_play = keep_free_play
	game.free_walk = keep_free_walk
	game.weather = keep_sky[0]
	game.night = keep_sky[1]
	if _failures > 0:
		print("test_walk_sky: %d FAILURES" % _failures)
		quit(1)
	else:
		print("test_walk_sky: OK")
		quit(0)
