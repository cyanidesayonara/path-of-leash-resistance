extends SceneTree

# The wind with real power (systems/gusts.gd): on a windy sky a gust is
# telegraphed before it blows and pushes nobody while it is only a warning;
# then it shoves the dog and your human downwind, the dog far less when she
# is planted, and bows the leash. A calm sky has no gusts. By the sea the
# wind blows off the water.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(game: Node, lv: String, want_sky: String) -> Node2D:
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = false
	m.phase = "out"
	# the walk's own campaign sky replaced the test's on load
	game.sky = want_sky
	return m


# the dog's velocity gained over one gust, along the wind
func _gust_push(m: Node2D, Gusts: GDScript, planted: bool) -> float:
	m.wind_next = 0.0
	m.wind_warn = 0.0
	m.wind_gust = 0.0
	Gusts.tick(m, 1.0 / 60.0)
	var dir: Vector2 = m.wind_dir
	m.dog.planted = planted
	var gained := 0.0
	for f in range(int((Gusts.GUST_WARN + Gusts.GUST_S) * 60.0) + 2):
		var before: Vector2 = m.dog.velocity
		Gusts.tick(m, 1.0 / 60.0)
		gained += (m.dog.velocity - before).dot(dir)
		m.dog.velocity = Vector2.ZERO
	m.dog.planted = false
	return gained


func _run() -> void:
	var Gusts: GDScript = load("res://systems/gusts.gd")
	var game: Node = root.get_node("Game")

	# a calm sky: nothing ever starts
	var m := await _load(game, "street", "clear")
	m.wind_next = 0.0
	for f in range(600):
		Gusts.tick(m, 1.0 / 60.0)
	_check(float(m.wind_warn) == 0.0 and float(m.wind_gust) == 0.0, "a clear, calm day has no gusts")
	m.queue_free()
	await process_frame

	# a gale: warned first, and the warning pushes nobody
	m = await _load(game, "street", "wind")
	# the first tick seeds the walk's wind and waits a while before its first gust
	Gusts.tick(m, 1.0 / 60.0)
	_check(float(m.wind_next) > 1.0 and float(m.wind_warn) == 0.0, "no gust the moment a walk starts")
	m.wind_next = 0.0
	Gusts.tick(m, 1.0 / 60.0)
	_check(float(m.wind_warn) > 0.0 and float(m.wind_gust) == 0.0, "a gust is telegraphed before it blows")
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	var quiet := true
	while float(m.wind_warn) > 0.0:
		Gusts.tick(m, 1.0 / 60.0)
		quiet = quiet and m.dog.velocity == Vector2.ZERO and m.human.velocity == Vector2.ZERO
	_check(quiet, "the telegraph pushes nobody")
	_check(float(m.wind_gust) > 0.0, "and then the gust blows")
	# the gust: dog and human carried downwind, the leash bowed
	var mid_before: Vector2 = m.leash.pts[m.leash.pts.size() / 2]
	var human_gain := 0.0
	var dir: Vector2 = m.wind_dir
	while float(m.wind_gust) > 0.0:
		var hb: Vector2 = m.human.velocity
		Gusts.tick(m, 1.0 / 60.0)
		human_gain += (m.human.velocity - hb).dot(dir)
	var bowed: Vector2 = m.leash.pts[m.leash.pts.size() / 2] - mid_before
	_check(m.dog.velocity.dot(dir) > 0.0, "the gust carries the dog downwind")
	_check(human_gain > 0.0, "and your human")
	_check(bowed.dot(dir) > 0.0, "and bows the leash's middle downwind")
	# planting holds her ground
	var free_push := _gust_push(m, Gusts, false)
	var planted_push := _gust_push(m, Gusts, true)
	_check(free_push > 0.0 and planted_push < free_push * 0.5, "a planted dog barely moves (%.1f vs %.1f)" % [planted_push, free_push])
	# a breeze blows softer than a gale
	game.sky = "breeze"
	var breeze_push := _gust_push(m, Gusts, false)
	_check(breeze_push > 0.0 and breeze_push < free_push, "a breeze pushes less than a gale (%.1f vs %.1f)" % [breeze_push, free_push])
	m.queue_free()
	await process_frame

	# by the sea, the wind comes off the water
	m = await _load(game, "beach", "wind")
	var y: float = m.dog.global_position.y
	var left: bool = Gusts.sea_on(m, y, -1.0)
	var right: bool = Gusts.sea_on(m, y, 1.0)
	if left != right:
		var d: Vector2 = Gusts.wind_dir(m, y)
		_check((d.x > 0.0) == left, "the beach's wind blows off the sea (%s, sea on the %s)" % [d, "left" if left else "right"])
	else:
		_check(false, "the beach has the sea on one side to blow off (left %s, right %s)" % [left, right])
	# and what it carries is spray, in a breeze as in a gale, blowing onshore
	for sky: String in ["wind", "breeze"]:
		game.sky = sky
		m.sea_check_t = 0.0
		m.wind_dir = Vector2(-1.0 if left else 1.0, 0.0)
		Gusts.tick_sea(m, 1.0 / 60.0)
		_check(bool(m.wind_off_sea), "a %s off the sea blows spray, not leaves" % sky)
		_check((m.wind_dir.x > 0.0) == left, "and blows onshore between gusts in a %s" % sky)
	game.sky = "clear"
	m.sea_check_t = 0.0
	Gusts.tick_sea(m, 1.0 / 60.0)
	_check(not bool(m.wind_off_sea), "a calm day by the sea blows nothing")
	m.queue_free()
	await process_frame

	# inland the wind carries leaves
	m = await _load(game, "park", "wind")
	m.sea_check_t = 0.0
	Gusts.tick_sea(m, 1.0 / 60.0)
	_check(not bool(m.wind_off_sea), "a gale in the park blows leaves, not spray")
	m.queue_free()
	await process_frame

	game.sky = "clear"
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
