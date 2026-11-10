extends SceneTree

# Tests the La Ciutadella victory film ("El Mamut de la Ciutadella", intro/film_mamut_win.gd)
# and its integration with El Mamut in systems/boss_mamut.gd.

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


class FakeMain:
	extends Node2D
	var frozen := false
	var paused := false
	var film_playing := false
	var auto_walk := false
	var mamut_settled := false
	var combo: FakeCombo
	var feed: FakeFeed
	var dog: Node2D
	var human: FakeHuman

	func _init() -> void:
		combo = FakeCombo.new()
		feed = FakeFeed.new()
		dog = Node2D.new()
		human = FakeHuman.new()
		add_child(dog)
		add_child(human)

	func float_text(_pos: Vector2, _txt: String, _col: Color) -> void:
		pass


class FakeCombo:
	func add(_kind: String, _pts: int) -> void:
		pass


class FakeFeed:
	func say(_txt: String, _tone: int = 0) -> void:
		pass


class FakeHuman:
	extends Node2D
	func say_line(_txt: String) -> void:
		pass
	func is_whirling() -> bool:
		return false


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	root.get_node("Sfx").muted = true
	var Kit: GDScript = load("res://intro/film_kit.gd")
	var Boss: GDScript = load("res://systems/boss_mamut.gd")
	var FP: GDScript = load("res://intro/film_player.gd")
	var film: GDScript = load(Boss.FILM_WIN)

	_check(film != null, "film_mamut_win loads")
	_check(float(film.LENGTH) == float(Kit.LENGTH), "film length matches shared contract")
	_check(float(film.TITLE_AT) == float(Kit.TITLE_AT), "title card time matches shared contract")

	# Check camera contract across stages
	for t: float in [0.0, 0.8, 1.4, 2.2, 3.3, 4.0, 5.0, 6.0]:
		var cam: Array = film.camera(t)
		_check(cam.size() == 2, "camera returns [center, zoom] at t=%.1f" % t)
		_check(cam[0] is Vector2, "camera center is Vector2 at t=%.1f" % t)
		_check(cam[1] is float and cam[1] > 0.5 and cam[1] < 2.0, "camera zoom in bounds at t=%.1f" % t)

	# Sound cues validity
	var lib: Dictionary = root.get_node("Sfx").lib
	for cue: Array in film.CUES:
		var ctime: float = float(cue[0])
		var cname: String = String(cue[1])
		_check(lib.has(cname), "cue %s exists in Sfx" % cname)
		_check(ctime >= 0.0 and ctime < float(film.LENGTH), "cue %s plays within film bounds" % cname)

	# Test integration with boss_mamut State.CONTENT
	var m := FakeMain.new()
	root.add_child(m)

	var boss_inst: RefCounted = Boss.new()
	boss_inst.set("main", m)

	_check(not boss_inst.get("win_film_shown"), "win_film_shown starts false")

	# In headless mode, FilmPlayer.should_play(m) is false
	_check(not FP.should_play(m), "should_play is false in headless")

	# When booped into State.CONTENT
	boss_inst.set("state", Boss.State.SAT)
	boss_inst.transition_to(Boss.State.CONTENT)
	_check(boss_inst.get("state") == Boss.State.CONTENT, "transitions to CONTENT")
	_check(m.mamut_settled, "mamut_settled marked true on main")
	_check(not m.film_playing, "film does not play headless")

	if failures.is_empty():
		print("test_film_mamut_win: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_film_mamut_win: %d failures out of %d checks" % [failures.size(), checks])
		quit(1)
