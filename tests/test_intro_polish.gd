extends SceneTree

# Intro cues, the handoff into the title theme, and the yank camera.
#   godot --headless --path . --script res://tests/test_intro_polish.gd

# loaded in _run, not preloaded: intro_player.gd refers to Sfx and Game,
# which are not registered yet while this test script is being compiled
var IntroPlayerScript: GDScript

var failures := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	IntroPlayerScript = load("res://intro/intro_player.gd")
	_cues()
	_handoff()
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
	sfx.prepare_intro()
	_check(sfx._music_cache.has("intro"), "the phrase is rendered")
	var stream: AudioStreamWAV = sfx._music_cache["intro"]
	_check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "cached phrase does not loop")
	sfx.handoff(14.4, 0.45)
	_check(sfx._handoff_on, "a finished film waits to hand off")
	_check(is_equal_approx(sfx._handoff_from, 14.4), "the title continues at 14.4")
	_check(is_equal_approx(sfx._handoff_fade, 0.45), "the handoff fade is 0.45")
	sfx.handoff(0.0, 0.45)
	_check(is_equal_approx(sfx._handoff_from, 0.0), "a skip starts the title at the top")
	sfx._handoff_on = false
