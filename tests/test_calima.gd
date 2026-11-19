extends SceneTree

# The calima (Game.SKY "calima"): Sahara dust over the city. The rules see a
# clear day; only the calima carries dust; the grade is a warm haze unlike a
# plain clear day's, an orange murk rather than blue after dark; the overlay
# drifts fine dust and never leaves, fewer and slower than rain; and the
# fair-weather kinds (sunbathers, picnics, the ice-cream cart, the beach's
# towels and parasols) stay in.

var checks := 0
var failures: Array[String] = []
var _level: Node2D = null


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _overlay(kind: String, rain: float, wind: float, dust: float) -> Control:
	var o := Control.new()
	o.set_script(load("res://hud/weather_overlay.gd"))
	root.add_child(o)
	o.set_sky(kind, rain, wind, dust)
	return o


# how far the particles move on average over `secs`
func _drift(o: Control, secs: float) -> float:
	var before: Array[Vector2] = []
	before.assign(o.drops)
	o._process(secs)
	var moved := 0.0
	var n := 0
	for i in range(mini(before.size(), o.drops.size())):
		var d: float = (o.drops[i] as Vector2).distance_to(before[i])
		# a particle that went off screen and came back elsewhere says nothing
		if d < 400.0:
			moved += d
			n += 1
	return moved / maxf(float(n), 1.0)


func _load(game: Node, lv: String, sky: String, time: String) -> Node2D:
	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
		_level = null
	game.sky = sky
	game.time = time
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	await process_frame
	_level = m
	return m


func _run() -> void:
	var game: Node = root.get_node("Game")
	var SkyLook: GDScript = load("res://systems/sky.gd")
	var Outdoors: GDScript = load("res://systems/outdoors.gd")
	var I18n: GDScript = load("res://hud/i18n.gd")
	var keep_sky: String = game.sky
	var keep_time: String = game.time
	var keep_args: bool = game.sky_from_args
	game.sky_from_args = true

	# the sky itself
	_check("calima" in game.SKIES, "the calima is one of the skies")
	game.sky = "calima"
	_check(game.weather == "clear", "the rules see a clear day under a calima (%s)" % game.weather)
	_check(game.dust_amount() > 0.0, "a calima has dust (%.2f)" % game.dust_amount())
	_check(game.wind_amount() > 0.2 and game.wind_amount() < 0.5,
		"and a light wind, short of gusts (%.2f)" % game.wind_amount())
	for s: String in game.SKIES:
		if s != "calima":
			game.sky = s
			_check(game.dust_amount() == 0.0, "no dust under %s" % s)
	for lv: String in game.CAMPAIGN_SKY:
		_check(String(game.CAMPAIGN_SKY[lv][0]) != "calima", "%s's campaign sky is not a calima" % lv)
	for lang: String in I18n.LANGS:
		var row: Dictionary = I18n.T.get("weather_calima", {})
		_check(String(row.get(lang, "")) != "", "the calima has a label in %s" % lang)

	# the look
	var clear_day: Color = SkyLook.tint("street", "clear", "day")
	var dust_day: Color = SkyLook.tint("street", "calima", "day")
	_check(not dust_day.is_equal_approx(clear_day) and dust_day.r > dust_day.g and dust_day.g > dust_day.b,
		"a calima tints the day ochre (%s)" % dust_day)
	var gc: Dictionary = SkyLook.grade_mod("street", "clear", "day")
	var gd: Dictionary = SkyLook.grade_mod("street", "calima", "day")
	_check(float(gd["k_con"]) < float(gc["k_con"]), "the dust lowers contrast")
	_check(float(gd["k_sat"]) < float(gc["k_sat"]), "and drains a little colour")
	var haze: Vector3 = gd["haze"]
	_check(haze.x > 0.0 and haze.x > haze.y and haze.y > haze.z, "and lifts the shadows into a warm haze (%s)" % haze)
	_check((gc["haze"] as Vector3) == Vector3.ZERO, "a clear day has no haze")
	var warm: Vector3 = gd["k_warm"]
	_check(warm.x > warm.z, "ochre in the highlights (%s)" % warm)
	var night: Color = SkyLook.tint("street", "calima", "night")
	var clear_night: Color = SkyLook.tint("street", "clear", "night")
	_check(clear_night.b > clear_night.r and night.r > night.b,
		"after dark an orange murk, not the night's blue (%s against %s)" % [night, clear_night])
	var gn: Dictionary = SkyLook.grade_mod("street", "calima", "night")
	var cool: Vector3 = gn["k_cool"]
	_check(cool.x > cool.z, "and the night's shadows turned orange (%s)" % cool)
	var sun_c: Vector3 = SkyLook.grade_mod("neteja", "clear", "dawn")["sun"]
	var sun_d: Vector3 = SkyLook.grade_mod("neteja", "calima", "dawn")["sun"]
	_check(sun_d.x < sun_c.x and sun_d.x > 0.0, "a low sun through the dust is softer, still there")
	# the haze is one even term in the grade: the shader gets it as a uniform
	var gm := ShaderMaterial.new()
	gm.shader = load("res://hud/grade.gdshader")
	var happy := {"sat": 1.12, "con": 1.05, "vig": 0.26, "tight": 1.6, "exp": 1.0, "lift": 0.055,
		"tint": Vector3.ONE, "cool": Vector3(0.90, 0.95, 1.09), "warm": Vector3(1.07, 1.01, 0.93)}
	SkyLook.apply(gm, SkyLook.compose(happy, gd))
	_check((gm.get_shader_parameter("haze") as Vector3).is_equal_approx(haze), "the grade shader is handed the haze")
	SkyLook.apply(gm, SkyLook.compose(happy, gc))
	_check((gm.get_shader_parameter("haze") as Vector3) == Vector3.ZERO, "and none on a clear day")

	# in the air
	var o := _overlay("clear", 0.0, 0.35, 1.0)
	_check(String(o.mode) == "dust", "the overlay blows dust under a calima (%s)" % o.mode)
	_check(o.drops.size() > 0, "and has motes in it (%d)" % o.drops.size())
	var leaves := 0
	for i in range(o.drops.size()):
		if o._is_leaf(i):
			leaves += 1
	_check(leaves == 0, "and no leaves (%d)" % leaves)
	var breeze := _overlay("clear", 0.0, 0.35, 0.0)
	_check(String(breeze.mode) == "wind", "the same wind without the dust is leaves and grit")
	var rain := _overlay("rain", 1.0, 0.2, 0.0)
	_check(o.drops.size() < rain.drops.size() / 2, "far fewer motes than raindrops (%d, %d)" % [o.drops.size(), rain.drops.size()])
	var dust_v := _drift(o, 0.1)
	var rain_v := _drift(rain, 0.1)
	_check(dust_v > 0.0 and dust_v * 5.0 < rain_v, "and far slower (%.1f, %.1f px)" % [dust_v, rain_v])
	for n: Control in [o, breeze, rain]:
		n.get_parent().remove_child(n)
		n.free()

	# who is out
	game.sky = "clear"
	_check(Outdoors.sunbathers("clear", "day") and Outdoors.picnics("clear", "day") and Outdoors.icecream_open("clear", "day"),
		"a clear day has its sunbathers, picnics and ice cream")
	game.sky = "calima"
	_check(not Outdoors.sunbathers(game.weather, "day"), "no sunbathers in a calima")
	_check(not Outdoors.picnics(game.weather, "day"), "no picnics in a calima")
	_check(not Outdoors.icecream_open(game.weather, "day"), "the ice-cream cart stays shut in a calima")
	_check(not Outdoors.beach_parasols_open(game.weather, "day"), "the beach parasols stay furled")
	var m := await _load(game, "beach", "calima", "day")
	_check(game.weather == "clear" and m.towels.is_empty(), "no towels on Passeig in a calima (%d)" % m.towels.size())
	_check(not m.parasols_up(), "and its parasols are down")
	m = await _load(game, "beach", "clear", "day")
	_check(m.towels.size() > 0, "a clear day still lays them out (%d)" % m.towels.size())
	_check(m.weather_fx != null and String(m.weather_fx.mode) == "clear", "and its air is clear")
	m = await _load(game, "beach", "calima", "day")
	_check(m.weather_fx != null and String(m.weather_fx.mode) == "dust", "the walk's overlay blows dust under a calima")

	if _level != null:
		_level.get_parent().remove_child(_level)
		_level.free()
	game.sky_from_args = keep_args
	game.sky = keep_sky
	game.time = keep_time
	if failures.is_empty():
		print("test_calima: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_calima: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
