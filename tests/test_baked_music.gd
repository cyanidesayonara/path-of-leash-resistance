extends SceneTree

# The baked soundtrack (tools/bake_music.gd, autoload/sfx.gd): every track the
# game can ask for is on Music.all_tracks(), so the bake covers it; a baked
# track is a QOA stream with the render's length and loop points (a sting does
# not loop); an exported build takes a baked track from disk in one step
# instead of starting a synthesis job, and the editor still synthesizes.

const Bake := preload("res://tools/bake_music.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(60.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	# every cue main.gd can give Sfx
	var tracks := Music.all_tracks()
	var asked := PackedStringArray(["intro", "title", "freedom", "won", "lost"])
	for lvl in Game.LEVELS:
		asked.append(Music.walk_style(lvl))
	asked.append(Music.walk_style("tutorial"))
	var who: Dictionary = load("res://entities/challenger.gd").WHO
	for w: String in who.values() + ["kid"]:
		asked.append("dare_" + w)
	for a in asked:
		_check(a in tracks, "the bake covers %s" % a)

	# a loop and a sting, baked and loaded back
	for nm: String in ["won", "kid"]:
		var name := nm if nm == "won" else "dare_" + nm
		var j: Music.Job = Music.job(name)
		j.run()
		var path := "user://test_bake_%s.res" % name
		var size := Bake.bake_one(j, path)
		_check(size > 0, "%s bakes" % name)
		var s: AudioStreamWAV = load(path)
		_check(s != null and s.format == AudioStreamWAV.FORMAT_QOA, "%s is QOA-compressed" % name)
		if s != null:
			_check(absf(s.get_length() - j.stream.get_length()) < 0.01, "%s keeps its length" % name)
			_check(size < j.stream.data.size() / 3, "%s is under a third of the raw size" % name)
			if j.loop:
				_check(s.loop_mode == AudioStreamWAV.LOOP_FORWARD and s.loop_begin == 0 and s.loop_end == j.n,
					"%s loops where the render loops" % name)
			else:
				_check(s.loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s plays once" % name)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# Sfx: baked in an export, live in the editor
	var sfx: Node = root.get_node("Sfx")
	_check(not bool(sfx.music_baked), "the editor synthesizes the music live")
	var baked_path := "%s/won.res" % sfx.BAKED_DIR
	var had := FileAccess.file_exists(baked_path)
	if not had:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(sfx.BAKED_DIR))
		var w: Music.Job = Music.job("won")
		w.run()
		Bake.bake_one(w, baked_path)
	sfx.music_baked = true
	sfx._music_cache.erase("won")
	sfx._music_want = "won"
	sfx._music_next = ""
	sfx._music_work(1.0 / 60.0)
	_check(sfx._music_cache.has("won") and sfx._music_job == null, "a baked track is loaded, not synthesized")
	sfx.music_baked = false
	sfx._music_cache.erase("won")
	sfx._music_work(1.0 / 60.0)
	_check(sfx._music_job != null, "without the bake a track is synthesized")
	if sfx._music_thread != null:
		sfx._music_job.cancel = true
		sfx._music_thread.wait_to_finish()
		sfx._music_thread = null
	sfx._music_job = null
	sfx._music_want = ""
	if not had:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(baked_path))

	if failures.is_empty():
		print("test_baked_music: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_baked_music: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
