extends SceneTree

# Intro cues, the handoff into the title theme, and the yank camera.
#   godot --headless --path . --script res://tests/test_intro_polish.gd

# loaded in _run, not preloaded: intro_player.gd refers to Sfx and Game,
# which are not registered yet while this test script is being compiled
var IntroPlayerScript: GDScript
var SceneWalkiesScript: GDScript

var failures := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	IntroPlayerScript = load("res://intro/intro_player.gd")
	SceneWalkiesScript = load("res://intro/scene_walkies.gd")
	_cues()
	_handoff()
	_camera()
	_volume_keys()
	_skip_hint()
	print("test_intro_polish: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)


func _cues() -> void:
	var sfx = root.get_node("Sfx")
	var intro_constants := IntroPlayerScript.get_script_constant_map()
	var cues: Array = intro_constants["CUES"]
	var end_at: float = intro_constants["END_AT"]
	var rate: int = int(sfx.get_script().get_script_constant_map()["RATE"])
	var want: Array = [
		[3.12, "intro_hook", 1.0, -10.0],
		[3.34, "intro_paws", 1.0, -12.0],
		[5.30, "intro_loop", 1.0, -10.0],
		[6.92, "intro_tap", 1.0, -12.0],
		[7.65, "intro_sigh", 1.0, -14.0],
		[9.22, "bark", 1.0, -3.0],
		[9.30, "intro_taut", 1.0, -8.0],
		[9.44, "intro_door", 1.0, -8.0],
	]
	_check(cues == want, "intro cue list")
	for row in cues:
		var t := float(row[0])
		var name := String(row[1])
		_check(t >= 0.0 and t <= end_at, "cue time %s" % name)
		_check(sfx.lib.has(name), "library has %s" % name)
		if name == "bark":
			continue
		var dur := float(sfx.lib[name].data.size()) / 2.0 / float(rate)
		var limit := 0.6 if name == "intro_sigh" else 0.4
		_check(dur > 0.02 and dur < limit, "%s lasts %s s" % [name, dur])
	for old in ["pickup", "ui", "tangle", "hiss", "fling", "crack", "star"]:
		var found := false
		for row in cues:
			if String(row[1]) == old:
				found = true
		_check(not found, "%s is not an intro cue" % old)


func _handoff() -> void:
	# Sfx is an autoload name, not in scope while this --script file compiles
	var sfx = root.get_node("Sfx")
	_check(not sfx.has_method("prepare_intro"), "the phrase is not rendered in one blocking call")
	var music = load("res://audio/music.gd")
	var phrase: AudioStreamWAV = music.render_stream("intro")
	_check(phrase.loop_mode == AudioStreamWAV.LOOP_DISABLED, "the phrase does not loop")
	sfx.handoff(false, 0.45)
	_check(sfx._handoff_on and not sfx._handoff_skip, "a finished film hands the melody on")
	_check(is_equal_approx(sfx._handoff_fade, 0.45), "the handoff fade is 0.45")
	sfx.handoff(true, 0.45)
	_check(sfx._handoff_skip, "a skip starts the title at the top")
	# a walk wanted before the title is ready: the handoff must not hold its
	# music back. Headless Sfx has no players, so lend it some, and short
	# placeholder tracks so the worker has nothing to render.
	var players: Array = []
	for i in range(3):
		var pl := AudioStreamPlayer.new()
		sfx.add_child(pl)
		players.append(pl)
	sfx.music_player = players[0]
	sfx._music_out = players[1]
	sfx._jingle = players[2]
	var blip := AudioStreamWAV.new()
	blip.data = PackedByteArray([0, 0, 0, 0])
	for k in ["park", "won", "lost"]:
		sfx._music_cache[k] = blip
	sfx._music_next = ""
	sfx._music_hold = 0.0
	sfx._music_want = "park"
	sfx._process(1.0 / 60.0)
	_check(not sfx._handoff_on, "a handoff gives way to any other music")
	_check(sfx._music_now == "park", "and that music starts")
	sfx.music_player = null
	for pl: AudioStreamPlayer in players:
		pl.stop()
		pl.queue_free()
	sfx._music_want = ""
	sfx._music_now = ""
	sfx._music_cache.clear()


func _camera() -> void:
	var close: Array = SceneWalkiesScript.camera(9.04)
	_check((close[0] as Vector2).is_equal_approx(Vector2(570, 455)), "close on the crouch")
	_check(is_equal_approx(float(close[1]), 1.75), "close zoom")
	var wide: Array = SceneWalkiesScript.camera(9.22)
	_check((wide[0] as Vector2).is_equal_approx(Vector2(800, 420)), "wide on the yank")
	_check(is_equal_approx(float(wide[1]), 1.12), "wide zoom")
	var held: Array = SceneWalkiesScript.camera(9.5)
	_check((held[0] as Vector2).is_equal_approx(Vector2(800, 420)), "the wide frame holds")
	var street: Array = SceneWalkiesScript.camera(10.1)
	_check((street[0] as Vector2).is_equal_approx(Vector2(640, 360)), "the street is still a cut")
	_check(is_equal_approx(float(street[1]), 1.0), "street zoom")


func _volume_keys() -> void:
	for code in [KEY_VOLUMEUP, KEY_VOLUMEDOWN, KEY_VOLUMEMUTE]:
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = code
		_check(not IntroPlayerScript.skips(ev), "volume key %s does not skip" % code)
		ev.keycode = KEY_NONE
		ev.physical_keycode = code
		_check(not IntroPlayerScript.skips(ev), "physical volume key %s does not skip" % code)
	var space := InputEventKey.new()
	space.pressed = true
	space.keycode = KEY_SPACE
	_check(IntroPlayerScript.skips(space), "a normal key still skips")


func _skip_hint() -> void:
	# the hint names a real button on every device, never an empty cap
	var was: int = Prompts.device
	for dev in [Prompts.KEYS, Prompts.PAD, Prompts.TOUCH]:
		Prompts.device = dev
		_check(Prompts.key("intro_skip") != "" and Prompts.key("intro_skip") != "intro_skip",
			"the skip hint names a button on device %d" % dev)
	Prompts.device = was
	var hint = IntroPlayerScript.SkipHint.new()
	_check(hint.SHOW_AT > 0.25, "the hint waits until a press can skip")
	hint.free()
