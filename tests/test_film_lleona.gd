extends SceneTree

# La Lleona's two films (intro/film_lleona.gd, intro/film_lleona_win.gd): the
# shared length and beats, a camera in bounds throughout, cues that exist and
# fall inside the film, the fight naming both, the gaze on the pigeon stopping
# short of the dog and your human, and the victory's kiss landing on her.

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
	var Kit: GDScript = load("res://intro/film_kit.gd")
	var Boss: GDScript = load("res://systems/boss_lleona.gd")
	var lib: Dictionary = root.get_node("Sfx").lib
	for path: String in [Boss.FILM, Boss.FILM_WIN]:
		_check(ResourceLoader.exists(path), "%s is there for the fight to play" % path)
		var film: GDScript = load(path)
		_check(film.LENGTH == Kit.LENGTH and film.TITLE_AT == Kit.TITLE_AT, "%s keeps the films' timing" % path)
		_check("BG" in film, "%s paints its margins" % path)
		for i in range(67):
			var cam: Array = film.camera(float(i) * 0.1)
			_check(cam.size() == 2 and cam[0] is Vector2 and cam[1] > 0.5 and cam[1] < 2.0, "%s camera at %.1f" % [path, float(i) * 0.1])
		for cue: Array in film.CUES:
			_check(lib.has(String(cue[1])) and float(cue[0]) >= 0.0 and float(cue[0]) < film.LENGTH, "%s cue %s" % [path, cue])
	var W: GDScript = load(Boss.FILM)
	_check(W.STONE_AT < Kit.STARE_AT and W.EYES_AT > Kit.LOOK_AT, "she wakes after the dog looks and before the stare")
	_check(W.BIRD_POS.x < 440.0, "the pigeon is short of your human")
	_check(W.nose_pos(W.lleona_at(Kit.TITLE_AT), W.LLEONA_K, {"eye": 1.0}).x < 300.0, "she pulls up short of the dog")
	var V: GDScript = load(Boss.FILM_WIN)
	var rear: Vector2 = W.rear_pos(V.lleona_at(V.KISS_AT), V.K, V.pose(V.KISS_AT, V.KISS_AT))
	_check(absf(V.STEP_POS.x - 108.0 - rear.x) < 70.0 and absf(V.STEP_POS.y - 92.0 - rear.y) < 90.0, "the dog on the steps reaches her (%s)" % rear)
	print("test_film_lleona: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
