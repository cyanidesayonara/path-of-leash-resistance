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
	# the intro: a score cut to the film, then the title theme from its first
	# bar at the drop, so the title can take over from wherever it has got to
	var beat := 60.0 / float(Music.TITLE_BPM)
	var lead := int(float(Music.INTRO_LEAD_BARS) * 4.0 * beat * Music.RATE)
	_check(absf(Music.intro_lead_sec() - 9.22) < 0.05, "the drop lands on the bark (%.3f s)" % Music.intro_lead_sec())
	var title_job := Music.job("title")
	var intro_job := Music.job("intro")
	_check(not intro_job.loop, "intro job does not loop")
	_check(intro_job.loud_as_loop, "intro uses loop loudness")
	var cut := lead + int(float(Music.INTRO_TITLE_BARS) * 4.0 * beat * Music.RATE)
	var want: Array = []
	for ev in title_job.events:
		if int(ev[0]) + lead < cut:
			want.append([int(ev[0]) + lead, String(ev[1]), str(ev[2])])
	var got: Array = []
	var calm_hits := 0
	for ev in intro_job.events:
		if int(ev[0]) >= lead:
			got.append([int(ev[0]), String(ev[1]), str(ev[2])])
		elif String(ev[1]) == "hit" and int(ev[0]) < int(8.0 * beat * Music.RATE):
			calm_hits += 1
	var missing := 0
	for e in want:
		if not got.has(e):
			missing += 1
	_check(missing == 0, "after the drop the intro is the title theme (%d of %d missing)" % [missing, want.size()])
	_check(calm_hits == 0, "no drums while she stares at the leash (%d hits)" % calm_hits)
	var intro_whole := Music.render_stream("intro")
	var intro_sliced := Music.job("intro")
	while not intro_sliced.step(300):
		pass
	_check(intro_whole.data == intro_sliced.stream.data, "a sliced intro matches a whole one")
	_check(Music.render_stream("intro").data == intro_whole.data, "intro renders repeat")
	_check(intro_whole.loop_mode == AudioStreamWAV.LOOP_DISABLED, "intro stream does not loop")
	var expect := cut + int(Music.TAIL * Music.RATE)
	expect += (4 - expect % 4) % 4
	_check(intro_whole.data.size() / 2 == expect, "intro length is the score, four title bars and the tail")
	var n := intro_whole.data.size() / 2
	var peak := 0
	var calm := 0.0
	var full := 0.0
	for i in range(n):
		var v := absi(intro_whole.data.decode_s16(i * 2))
		peak = maxi(peak, v)
		if i < lead:
			calm += float(v * v)
		elif i < cut:
			full += float(v * v)
	var calm_rms := sqrt(calm / float(lead)) / 32767.0
	var full_rms := sqrt(full / float(cut - lead)) / 32767.0
	_check(peak < 32500, "intro does not clip (peak %d)" % peak)
	_check(calm_rms > 0.01, "the calm opening is heard (%s)" % calm_rms)
	_check(full_rms > calm_rms * 2.0, "the drop is a lift (%s to %s)" % [calm_rms, full_rms])
	# the handoff: the full band part is as loud as the title theme it hands to
	var ratio := full_rms / float(levels["title"])
	if ratio < 1.0:
		ratio = 1.0 / ratio
	_check(ratio < 1.25, "intro loudness after the drop matches the title (ratio %s)" % ratio)
	print("test_music: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)
