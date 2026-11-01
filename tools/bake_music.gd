extends SceneTree

# Renders every track of the soundtrack (audio/music.gd) once, ahead of time,
# and saves each as a QOA-compressed AudioStreamWAV resource in
# res://music/baked/<name>.res, loop points and all. Exported builds play
# these instead of synthesizing a walk's tracks while it is played: in the
# browser that synthesis shared the main thread, a slice of every frame for
# the first stretch of each walk. The editor and tests keep synthesizing live
# (autoload/sfx.gd), so a change to the music is heard at once and a stale
# bake is never played there. release.yml and tools/web_perf.sh run this
# before exporting; the folder is gitignored.
#
#   godot --headless --path . --script res://tools/bake_music.gd

const OUT := "res://music/baked"

var _names := PackedStringArray()
var _jobs: Array = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_names = Music.all_tracks()
	for nm in _names:
		_jobs.append(Music.job(nm))
	var t0 := Time.get_ticks_msec()
	# the renders are independent: one per worker thread
	var gid := WorkerThreadPool.add_group_task(_render, _jobs.size())
	WorkerThreadPool.wait_for_group_task_completion(gid)
	var total := 0
	for i in range(_jobs.size()):
		var path := "%s/%s.res" % [OUT, _names[i]]
		var size := bake_one(_jobs[i], path)
		if size < 0:
			push_error("bake_music: could not bake %s" % path)
			quit(1)
			return
		total += size
	print("bake_music: %d tracks, %.1f MB, %.1f s" % [_names.size(), total / 1048576.0, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(0)


# A rendered job saved as a compressed stream at path: its size in bytes, or
# -1. The job must have run (Music.Job.run) already.
static func bake_one(j: Music.Job, path: String) -> int:
	if j.stream == null:
		return -1
	var tmp := ProjectSettings.globalize_path("user://bake_%s.wav" % j.name)
	if j.stream.save_to_wav(tmp) != OK:
		return -1
	var opts := {"compress/mode": 2}
	if j.loop:
		opts.merge({"edit/loop_mode": 2, "edit/loop_begin": 0, "edit/loop_end": j.n})
	else:
		opts["edit/loop_mode"] = 1
	var q: AudioStreamWAV = AudioStreamWAV.load_from_file(tmp, opts)
	DirAccess.remove_absolute(tmp)
	if q == null or ResourceSaver.save(q, path) != OK:
		return -1
	return FileAccess.open(path, FileAccess.READ).get_length()


func _render(i: int) -> void:
	(_jobs[i] as Music.Job).run()
