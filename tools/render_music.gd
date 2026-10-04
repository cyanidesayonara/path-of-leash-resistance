extends SceneTree

# Renders soundtrack styles to WAV files, to listen to outside the game:
#   godot --headless --path . --script res://tools/render_music.gd -- OUTDIR title beach oldtown
# Prints how long each took to synthesise (it runs at load in the game).

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://music"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var styles: Array = args.slice(1) if args.size() > 1 else ["title", "beach", "oldtown"]
	for st: String in styles:
		var t0 := Time.get_ticks_msec()
		var buf := Music.render(st)
		var ms := Time.get_ticks_msec() - t0
		var stream := Music.to_stream(buf)
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		var path := "%s/music-%s.wav" % [out_dir, st]
		stream.save_to_wav(path)
		print("render_music: %s %.1fs of music in %d ms -> %s" % [st, float(buf.size()) / Music.RATE, ms, path])
	quit(0)
