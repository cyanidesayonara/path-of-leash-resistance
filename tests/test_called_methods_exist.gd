extends SceneTree

# Every call a systems/ module makes on main (`m.name(`) names a function
# main.gd (or Node2D) has. Agents have added calls to functions that do not
# exist (award_points, leash.has_contact_with) and stubbed them in their own
# tests; the walk then logs a SCRIPT ERROR every frame it runs that line.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	var main_script: GDScript = load("res://main.gd")
	var have := {}
	for md: Dictionary in main_script.get_script_method_list():
		have[String(md.name)] = true
	var call_re := RegEx.create_from_string(r"\bm\.([a-z_][a-z0-9_]*)\(")
	var dir := DirAccess.open("res://systems")
	for f: String in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		var src := FileAccess.get_file_as_string("res://systems/" + f)
		for hit: RegExMatch in call_re.search_all(src):
			var name := hit.get_string(1)
			checks += 1
			if not have.has(name) and not ClassDB.class_has_method("Node2D", name):
				failures.append("%s calls m.%s(), which main.gd does not define" % [f, name])
	for msg: String in failures:
		print("FAIL: " + msg)
	if failures.is_empty():
		print("test_called_methods_exist: %d calls, OK" % checks)
		quit(0)
	else:
		print("test_called_methods_exist: %d FAILURES" % failures.size())
		quit(1)
