extends SceneTree

# Who is out follows the weather and the hour (systems/outdoors.gd): no
# sunbathers, towels, picnics or open beach parasols at first light, after
# dark or in rain or snow; a walk in its own campaign sky keeps the crowd it
# was built with, and another sky only ever thins it.

# loaded once the tree is up: both read the Game autoload
var Outdoors: GDScript
var LevelBuild: GDScript

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


func _load(level_id: String, weather: String, hour: String) -> Node2D:
	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
		_level = null
	var game = root.get_node("Game")
	game.weather = weather
	game.hour = hour
	game.level_id = level_id
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	await process_frame
	_level = m
	return m


func _picnics(m: Node2D) -> int:
	var n := 0
	for it: Dictionary in m.verge_items:
		if String(it["kind"]) == "picnic":
			n += 1
	return n


func _run() -> void:
	Outdoors = load("res://systems/outdoors.gd")
	LevelBuild = load("res://world/level_build.gd")
	var game = root.get_node("Game")
	var keep_sky: Array = [game.weather, game.hour]
	var keep_args: bool = game.sky_from_args
	game.sky_from_args = true

	# the rules themselves
	for w: String in game.WEATHERS:
		for h: String in game.HOURS:
			var fair := (w == "clear" or w == "wind") and (h == "day" or h == "dusk")
			_check(Outdoors.sunbathers(w, h) == fair, "sunbathers out in %s/%s: %s" % [w, h, fair])
			_check(Outdoors.crowd_share(w, h) <= 1.0, "never more than a clear day's crowd in %s/%s" % [w, h])
	_check(Outdoors.busking("rain", "day") == false and Outdoors.busking("snow", "night") == false,
		"no busking in rain or snow")
	_check(Outdoors.terrace_parasols("rain", "day") and not Outdoors.terrace_parasols("clear", "night")
		and not Outdoors.terrace_parasols("snow", "day"), "a terrace parasol is up in the rain, furled at night and in snow")
	# every campaign walk in its own sky keeps its built crowd
	for lv: String in game.CAMPAIGN_SKY:
		var sky: Array = game.CAMPAIGN_SKY[lv]
		_check(Outdoors.crowd_count(14, String(sky[0]), String(sky[1]), sky) == 14,
			"%s in its own sky (%s/%s) keeps its whole crowd" % [lv, sky[0], sky[1]])
	_check(Outdoors.crowd_count(14, "rain", "night", ["clear", "day"]) < 14, "a clear-day walk thins out in rain at night")
	_check(Outdoors.crowd_count(14, "clear", "day", ["clear", "night"]) == 14, "a night walk by day is never over-full")
	_check(Outdoors.riding("roller", "wind", "dawn") and not Outdoors.riding("kid", "wind", "dawn"),
		"skaters out at first light, kids on scooters not yet")
	_check(Outdoors.riding("bike", "snow", "night"), "commuters ride in any sky")
	_check(not Outdoors.riding("roller", "rain", "day") and not Outdoors.riding("roller", "clear", "night"),
		"no skaters on a wet lane or in the dark")
	_check(Outdoors.pair_gap("clear", "dawn") < 1.0, "dog walkers come oftener at first light")

	# the beach: towels laid out on a clear day only
	var m := await _load("beach", "clear", "day")
	_check(m.towels.size() == 5, "Passeig on a clear day has its five towels (%d)" % m.towels.size())
	_check(m.parasols_up(), "and its parasols are up")
	for sky: Array in [["snow", "day"], ["rain", "day"], ["clear", "night"], ["wind", "dawn"]]:
		m = await _load("beach", String(sky[0]), String(sky[1]))
		_check(m.towels.is_empty(), "no towels on Passeig in %s/%s" % sky)
		_check(not m.parasols_up(), "beach parasols furled in %s/%s" % sky)

	# the park: the picnic, the frisbee pair and the sunbather stay in
	m = await _load("park", "clear", "day")
	var people_day: int = LevelBuild.park_people().size()
	_check(_picnics(m) > 0, "El Parc's verge has picnics on a clear day (%d)" % _picnics(m))
	m = await _load("park", "snow", "day")
	_check(_picnics(m) == 0, "and none in snow")
	_check(LevelBuild.park_people().size() == people_day - 4,
		"the lawn's picnic, frisbee pair and sunbather are not out in snow (%d of %d)" % [LevelBuild.park_people().size(), people_day])
	m = await _load("street", "clear", "night")
	_check(m.parasols_up() == false, "La Rambla's terrace parasols are furled at night")
	m = await _load("street", "rain", "day")
	_check(m.parasols_up(), "and up in the rain")

	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
	game.sky_from_args = keep_args
	game.weather = keep_sky[0]
	game.hour = keep_sky[1]
	if _failures > 0:
		print("test_outdoors: %d FAILURES" % _failures)
		quit(1)
	else:
		print("test_outdoors: OK")
		quit(0)
