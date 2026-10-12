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
	var cut := int(7.0 * 4.0 * (60.0 / 104.0) * Music.RATE)
	var title_job := Music.job("title")
	var intro_job := Music.job("intro")
	_check(not intro_job.loop, "intro job does not loop")
	_check(intro_job.loud_as_loop, "intro uses loop loudness")
	var want_mel: Array = []
	var want_shake: Array = []
	for ev in title_job.events:
		if int(ev[0]) >= cut:
			continue
		if String(ev[1]) == "bar" and String(ev[2][2]) == "marimba":
			want_mel.append(ev)
		elif String(ev[1]) == "hit" and String(ev[2][0]) == "shaker":
			want_shake.append(ev)
	var got_mel: Array = []
	var got_shake: Array = []
	for ev in intro_job.events:
		_check(String(ev[1]) != "pluck", "intro has no pluck")
		if String(ev[1]) == "bar":
			_check(String(ev[2][2]) == "marimba", "intro bars are marimba")
			got_mel.append(ev)
		elif String(ev[1]) == "hit":
			_check(String(ev[2][0]) == "shaker", "intro hits are the shaker")
			got_shake.append(ev)
	_check(got_mel.size() == want_mel.size() and got_mel.size() > 0, "intro keeps the early marimba")
	for i in range(mini(got_mel.size(), want_mel.size())):
		_check(int(got_mel[i][0]) == int(want_mel[i][0]), "marimba time %d" % i)
	_check(got_shake.size() == want_shake.size() and got_shake.size() > 0, "intro keeps the shaker")
	for i in range(mini(got_shake.size(), want_shake.size())):
		_check(int(got_shake[i][0]) == int(want_shake[i][0]), "shaker time %d" % i)
		_check(is_equal_approx(float(got_shake[i][2][1]), float(want_shake[i][2][1]) * 0.5), "shaker is half")
	var intro_whole := Music.render_stream("intro")
	var intro_sliced := Music.job("intro")
	while not intro_sliced.step(300):
		pass
	_check(intro_whole.data == intro_sliced.stream.data, "a sliced intro matches a whole one")
	_check(Music.render_stream("intro").data == intro_whole.data, "intro renders repeat")
	_check(intro_whole.loop_mode == AudioStreamWAV.LOOP_DISABLED, "intro stream does not loop")
	var expect := cut + int(Music.TAIL * Music.RATE)
	expect += (4 - expect % 4) % 4
	_check(intro_whole.data.size() / 2 == expect, "intro length is seven bars plus the tail")
	var n := intro_whole.data.size() / 2
	var peak := 0
	var sumsq := 0.0
	for i in range(n):
		var v := absi(intro_whole.data.decode_s16(i * 2))
		peak = maxi(peak, v)
		sumsq += float(v * v)
	var intro_rms := sqrt(sumsq / float(n)) / 32767.0
	_check(peak < 32500, "intro does not clip (peak %d)" % peak)
	_check(intro_rms > 0.05, "intro is not silent")
	var ratio := intro_rms / float(levels["title"])
	if ratio < 1.0:
		ratio = 1.0 / ratio
	# 1.25 rejects the sting loudness factor (1.25 / 0.8 = 1.56) while a loop-matched phrase passes
	_check(ratio < 1.25, "intro loudness matches the title (ratio %s)" % ratio)
	print("test_music: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)
