extends SceneTree

# A redraw asked for from physics is made once a frame (systems/redraw.gd):
# a node marked any number of times is redrawn once, a freed one is passed
# over (many freed at once included), and no entity, layer or main itself calls queue_redraw() from
# _physics_process or tick, where the engine would draw it after every
# physics step of a slow frame.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _scan(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var re := RegEx.new()
	re.compile("(?ms)^func (_physics_process|tick)\\(.*?(?=^func |\\z)")
	var call := RegEx.new()
	call.compile("(?<![\\w.])queue_redraw\\(\\)")
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".gd"):
			continue
		var src := FileAccess.get_file_as_string(dir.path_join(f))
		for m in re.search_all(src):
			if call.search(m.get_string()) != null:
				out.append("%s %s" % [f, m.get_string(1)])
	return out


func _run() -> void:
	var a := Node2D.new()
	var b := Node2D.new()
	root.add_child(a)
	root.add_child(b)
	Redraw.later(a)
	Redraw.later(a)
	Redraw.later(b)
	_check(Redraw._due.size() == 2, "a node marked twice is due once")
	b.free()
	Redraw.flush()
	_check(Redraw._due.is_empty(), "a flush clears what was due, a freed node included")
	a.queue_free()
	# many marked, half freed, then a flush. Keyed by the nodes themselves,
	# the flush hung when whole walks were unloaded one after another;
	# test_tony_hawk_quests.gd, which does that, is the regression test
	var many: Array[Node2D] = []
	for i in range(60):
		var n := Node2D.new()
		root.add_child(n)
		many.append(n)
		Redraw.later(n)
	for i in range(0, 60, 2):
		many[i].free()
	Redraw.flush()
	_check(Redraw._due.is_empty(), "a flush with freed nodes among the due finishes")
	for i in range(1, 60, 2):
		many[i].queue_free()

	var found := PackedStringArray()
	for dir: String in ["res://", "res://entities", "res://world", "res://systems", "res://hud"]:
		found.append_array(_scan(dir))
	_check(found.is_empty(), "nothing calls queue_redraw() from physics: %s" % ", ".join(found))
	if failures.is_empty():
		print("test_redraw_once: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_redraw_once: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
