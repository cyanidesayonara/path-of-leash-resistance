extends SceneTree

# Renders soundtrack styles and jingles to WAV files, to listen to outside the
# game:
#   godot --headless --path . --script res://tools/render_music.gd -- OUTDIR [name ...]
# With no names, renders every style and jingle. Prints how long each took to
# synthesise (the game spreads that over frames).

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://music"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var names: Array = args.slice(1)
	if names.is_empty():
		names = Music.STYLES.keys() + Music.JINGLES.keys()
	var total_ms := 0
	for nm: String in names:
		var t0 := Time.get_ticks_msec()
		var stream := Music.render_stream(nm)
		var ms := Time.get_ticks_msec() - t0
		total_ms += ms
		# one copy: reading stream.data in the loop would copy it every time
		var data := stream.data
		var secs := float(data.size()) / 2.0 / Music.RATE
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		var path := "%s/music-%s.wav" % [out_dir, nm]
		stream.save_to_wav(path)
		print("render_music: %-8s %5.1fs in %5d ms  peak %.2f -> %s" % [nm, secs, ms, peak / 32767.0, path])
	print("render_music: total %d ms" % total_ms)
	quit(0)
