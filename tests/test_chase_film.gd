extends SceneTree

# The chase walks' story films (intro/film_player.gd): the walk freezes under
# the film and is handed back when it ends or is skipped, the chase's warning
# runs once after it, a pause held over the film keeps the walk frozen, and
# a film never plays headless, for the autowalk or in a screenshot run.
# La Neteja's chase profile carries its film; the films' sound cues exist.

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


class FakeMain:
	extends Node
	var frozen := false
	var paused := false
	var film_playing := false
	var auto_walk := false


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	root.get_node("Sfx").muted = true
	var HomeChase: GDScript = load("res://systems/home_chase.gd")
	var FP: GDScript = load("res://intro/film_player.gd")
	var film: GDScript = load(HomeChase.SWEEPER_FILM)
	var m := FakeMain.new()
	root.add_child(m)

	# when a film may play
	_check(not FP.should_play(m, PackedStringArray()), "never headless")
	_check(FP.should_play(m, PackedStringArray(["--films"])), "--films forces it")
	m.auto_walk = true
	_check(not FP.should_play(m, PackedStringArray()), "never for the autowalk")
	m.auto_walk = false
	_check(not FP.should_play(m, PackedStringArray(["--no-films"])), "--no-films stops it")
	_check(HomeChase.profile_for("neteja").get("film", "") == HomeChase.SWEEPER_FILM, "La Neteja's chase has its film")

	# the cues name sounds that exist
	var lib: Dictionary = root.get_node("Sfx").lib
	for cue: Array in film.CUES:
		_check(lib.has(String(cue[1])), "the film's cue %s is a sound" % cue[1])

	# played to the end: frozen under it, handed back once, then gone
	var calls := [0]
	var fp = FP.play(m, film, func() -> void: calls[0] += 1)
	_check(m.frozen and m.film_playing, "the walk freezes under the film")
	var t := 0.0
	while t < float(film.LENGTH) - 0.1:
		fp._process(DT)
		t += DT
	_check(m.frozen and calls[0] == 0, "still frozen until the film ends")
	for i in range(20):
		fp._process(DT)
	_check(not m.frozen and not m.film_playing and calls[0] == 1, "handed back once at the end")
	for i in range(40):
		if is_instance_valid(fp):
			fp._process(DT)
	await process_frame
	_check(not is_instance_valid(fp), "the film leaves after its fade")

	# skipped: any key ends it at once, after a quarter second
	calls[0] = 0
	fp = FP.play(m, film, func() -> void: calls[0] += 1)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	fp._input(key)
	_check(calls[0] == 0 and m.frozen, "a press in the first quarter second is ignored")
	for i in range(20):
		fp._process(DT)
	fp._input(key)
	_check(calls[0] == 1 and not m.frozen, "a key skips it and hands the walk back")
	fp._input(key)
	_check(calls[0] == 1, "a second press does nothing more")
	fp.queue_free()

	# paused over the film: the pause keeps the walk frozen afterwards
	calls[0] = 0
	fp = FP.play(m, film, func() -> void: calls[0] += 1)
	m.paused = true
	for i in range(30):
		fp._process(DT)
	fp._input(key)
	_check(m.frozen and calls[0] == 1, "a pause still up keeps the walk frozen")
	m.paused = false
	fp.queue_free()

	# a walk already frozen is left frozen
	m.frozen = true
	fp = FP.play(m, film, Callable())
	for i in range(30):
		fp._process(DT)
	fp._input(key)
	_check(m.frozen, "a film over a frozen walk does not unfreeze it")
	fp.queue_free()

	m.queue_free()
	await process_frame
	if failures.is_empty():
		print("test_chase_film: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_chase_film: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
