extends SceneTree

# The soundtrack (audio/music.gd): every walk has an arrangement, a track is
# the same however finely its render is sliced, renders are repeatable, and
# what comes out is a healthy loop - sound all the way through, no clipping,
# loudness matched between styles.
#   godot --headless --path . --script res://tests/test_music.gd

var failures := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)


func _initialize() -> void:
	for lv in Game.LEVELS:
		_check(Music.walk_style(lv) == lv, "walk %s has its own arrangement" % lv)
	_check(Music.walk_style("tutorial") == "title", "an unknown level falls back to the title theme")
	# slicing does not change a sample
	var whole := Music.render_stream("won")
	var sliced := Music.job("won")
	var steps := 0
	while not sliced.step(300):
		steps += 1
	_check(steps > 3, "a 300 usec budget really slices the render (%d steps)" % steps)
	_check(whole.data == sliced.stream.data, "a sliced render matches a whole one")
	_check(Music.render_stream("won").data == whole.data, "renders are repeatable")
	_check(whole.loop_mode == AudioStreamWAV.LOOP_DISABLED, "a sting does not loop")
	# a few loops that between them use every instrument
	var levels := {}
	for nm: String in ["title", "guell", "rain", "oldtown"]:
		var s := Music.render_stream(nm)
		var data := s.data
		var n := data.size() / 2
		_check(s.loop_mode == AudioStreamWAV.LOOP_FORWARD and s.loop_end == n, "%s loops over its whole length" % nm)
		var peak := 0
		var sumsq := 0.0
		var quiet := 0
		var win := 0
		for i in range(n):
			var v := absi(data.decode_s16(i * 2))
			peak = maxi(peak, v)
			sumsq += float(v * v)
			win = maxi(win, v)
			if i % 11025 == 11024:
				if win < 300:
					quiet += 1
				win = 0
		var rms := sqrt(sumsq / float(n)) / 32767.0
		levels[nm] = rms
		_check(peak < 32500, "%s does not clip (peak %d)" % [nm, peak])
		_check(quiet == 0, "%s has no silent half-second (%d)" % [nm, quiet])
	var lo := 1.0
	var hi := 0.0
	for k: String in levels:
		lo = minf(lo, levels[k])
		hi = maxf(hi, levels[k])
	_check(hi / lo < 1.6, "styles within 4 dB of each other (%s)" % str(levels))
	print("test_music: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)
