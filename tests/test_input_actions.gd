extends SceneTree

# Every input action the code reads exists. Actions are registered in code
# (main._setup_input), so a typo or a prompt label used as an action
# ("intro_skip" once) parses fine and only logs an error every frame, on a
# screen no headless run reaches. Scans every script for Input.is_action_*,
# get_action_strength, get_axis and get_vector calls with literal names.

const DIRS := ["res://"]
const SKIP := ["res://godot", "res://build", "res://.godot", "res://tests"]

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _scripts(dir: String, out: Array[String]) -> void:
	for s: String in SKIP:
		if dir.begins_with(s):
			return
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		if not sub.begins_with("."):
			_scripts(dir.path_join(sub), out)


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.persist = false
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var call_re := RegEx.new()
	call_re.compile("(?:is_action(?:_just)?_(?:pressed|released)|get_action_strength|get_axis|get_vector)\\(([^)]*)\\)")
	var name_re := RegEx.new()
	name_re.compile("\"([a-z_0-9]+)\"")
	var files: Array[String] = []
	for d: String in DIRS:
		_scripts(d, files)
	var seen := 0
	for path: String in files:
		var src := FileAccess.get_file_as_string(path)
		for cm: RegExMatch in call_re.search_all(src):
			for nm: RegExMatch in name_re.search_all(cm.get_string(1)):
				seen += 1
				var action := nm.get_string(1)
				_check(InputMap.has_action(action), "%s reads action \"%s\", which is not registered" % [path, action])
	_check(seen > 20, "found the game's action reads (%d)" % seen)
	m.queue_free()
	await process_frame
	print("test_input_actions: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
