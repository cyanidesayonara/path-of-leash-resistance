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
	_check(Outdoors.street_sellers("clear", "night") and Outdoors.street_sellers("wind", "night")
		and not Outdoors.street_sellers("clear", "day") and not Outdoors.street_sellers("clear", "dusk")
		and not Outdoors.street_sellers("rain", "night"), "street sellers lay out their sheets only on a dry night")
	_check(Outdoors.terrace_patrons("clear", "night") and Outdoors.terrace_patrons("wind", "day")
		and not Outdoors.terrace_patrons("rain", "night") and not Outdoors.terrace_patrons("snow", "day"),
		"terrace tables are taken when it is dry, empty in rain or snow")
	_check(Outdoors.busker_onlookers("clear", "night") and not Outdoors.busker_onlookers("clear", "dawn")
		and not Outdoors.busker_onlookers("rain", "day"), "a busker draws onlookers only while busking, not at dawn")
	# El Metro: underground the weather stops at the stairs
	_check(Outdoors.underground_busker("rain", "day") and Outdoors.underground_busker("snow", "dusk")
		and not Outdoors.underground_busker("clear", "night"), "the metro's busker plays in any weather, not after dark")
	_check(Outdoors.umbrella_shakers("rain", "day") and Outdoors.umbrella_shakers("snow", "night")
		and not Outdoors.umbrella_shakers("clear", "day"), "umbrellas are shaken out only in rain or snow")
	_check(Outdoors.underground_crowd(26, "rain", "day") == 26, "rain never thins the metro's rush hour")
	_check(Outdoors.underground_crowd(26, "clear", "dawn") < 26 and Outdoors.underground_crowd(1, "clear", "dawn") >= 2,
		"first light thins it, never below two")
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

	# Carrer de Blai: terraces full at night, a few by day, empty in the rain;
	# standers out in the evening and in the doorways when it rains; shutters
	# and deliveries by day
	_check(Outdoors.terrace_diners("clear", "night") > Outdoors.terrace_diners("clear", "day"),
		"Blai's terraces fill at night")
	_check(Outdoors.terrace_diners("rain", "night") == 0.0 and Outdoors.terrace_diners("snow", "day") == 0.0,
		"and empty in rain and snow")
	_check(Outdoors.standers_out("clear", "night") and not Outdoors.standers_out("clear", "day"),
		"groups stand out with a drink after dark, not by day")
	_check(Outdoors.standers_out("rain", "day") and Outdoors.standers_in_doorways("rain", "day"),
		"and in the rain they stand in the doorways")
	_check(Outdoors.bar_shutters("clear", "night") == 0.0 and Outdoors.bar_shutters("clear", "day") > 0.0,
		"shutters are down by day and up at night")
	_check(Outdoors.deliveries("rain", "day") and not Outdoors.deliveries("clear", "night"),
		"deliveries by day in any weather, never at night")
	m = await _load("blai", "clear", "night")
	var night_diners: int = m.blai_diners.size()
	var night_standers: int = m.performers.size()
	m = await _load("blai", "clear", "day")
	_check(m.blai_diners.size() < night_diners and night_diners > 0,
		"Blai has fewer diners by day than at night (%d, %d)" % [m.blai_diners.size(), night_diners])
	_check(m.performers.size() == 0 and night_standers > 0, "and nobody standing out with a drink by day")
	_check(m.blai_delivery.size() > 0, "and a delivery by a bar door")
	m = await _load("blai", "rain", "night")
	_check(m.blai_diners.is_empty(), "nobody sits out on Blai in the rain")
	_check(m.performers.size() > 0, "they stand in the doorways instead")

	# Sant Pau: bench sitters and sketchers out in dry dusk/day, empty in rain/snow
	_check(Outdoors.garden_sitters("clear", "dusk") > Outdoors.garden_sitters("clear", "dawn"),
		"Sant Pau benches fuller at dusk than dawn")
	_check(Outdoors.garden_sitters("rain", "dusk") == 0.0 and Outdoors.garden_sitters("snow", "day") == 0.0,
		"and empty in rain and snow")
	_check(Outdoors.sketchers_out("clear", "dusk") and not Outdoors.sketchers_out("rain", "day") and not Outdoors.sketchers_out("clear", "night"),
		"sketchers out in dry light/dusk, not in rain or at night")
	m = await _load("santpau", "clear", "dusk")
	var dusk_sitters: int = m.santpau_sitters.size()
	var dusk_sketchers: int = m.performers.size()
	_check(dusk_sitters > 0 and dusk_sketchers > 0, "Sant Pau has sitters and sketchers at dusk (%d, %d)" % [dusk_sitters, dusk_sketchers])
	m = await _load("santpau", "rain", "dusk")
	_check(m.santpau_sitters.is_empty() and m.performers.is_empty(), "nobody sits or sketches in Sant Pau in the rain")

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
