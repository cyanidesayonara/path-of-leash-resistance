extends SceneTree

# Every property read a systems/ or world/ module makes on main (`m.name`)
# names a variable, constant, method (as Callable), signal or Node2D/Node
# property that main.gd defines. Walk modules have read m.camera (instead of
# m.cam), which crashes only when that branch finally executes.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	var main_script: GDScript = load("res://main.gd")
	var have := {}
	for pd: Dictionary in main_script.get_script_property_list():
		have[String(pd.name)] = true
	for md: Dictionary in main_script.get_script_method_list():
		have[String(md.name)] = true
	for sd: Dictionary in main_script.get_script_signal_list():
		have[String(sd.name)] = true
	for c: String in main_script.get_script_constant_map():
		have[c] = true
	for pd: Dictionary in ClassDB.class_get_property_list("Node2D"):
		have[String(pd.name)] = true
	for pd: Dictionary in ClassDB.class_get_property_list("Node"):
		have[String(pd.name)] = true

	var prop_re := RegEx.create_from_string(r"\bm\.([a-z_][a-z0-9_]*)\b(?!\s*\()")
	var param_re := RegEx.create_from_string(r"(?:^|[(,])\s*m(?::\s*Node2D)?\s*(?:=[^,)]*)?(?=[,)]|$)")

	var folders := ["systems", "world"]
	for folder: String in folders:
		var dir := DirAccess.open("res://" + folder)
		if dir == null:
			continue
		for f: String in dir.get_files():
			if not f.ends_with(".gd"):
				continue
			var file_rel := folder + "/" + f
			var src := FileAccess.get_file_as_string("res://" + file_rel)
			var lines := src.split("\n")
			var in_m_func := false
			var sig_buf := ""
			var collecting_sig := false

			for line_idx in lines.size():
				var line_num := line_idx + 1
				var line := lines[line_idx]
				var stripped := line.strip_edges()

				if not line.begins_with("\t") and not line.begins_with(" "):
					if stripped.begins_with("func ") or stripped.begins_with("static func "):
						collecting_sig = true
						sig_buf = stripped

				if collecting_sig:
					if not sig_buf.ends_with(stripped):
						sig_buf += " " + stripped
					if ")" in sig_buf:
						collecting_sig = false
						in_m_func = param_re.search(sig_buf) != null

				if in_m_func:
					for hit: RegExMatch in prop_re.search_all(line):
						var name := hit.get_string(1)
						checks += 1
						if not have.has(name):
							failures.append("%s:%d: m.%s is not on main" % [file_rel, line_num, name])

	for msg: String in failures:
		print("FAIL: " + msg)
	if failures.is_empty():
		print("test_main_properties_exist: %d reads, OK" % checks)
		quit(0)
	else:
		print("test_main_properties_exist: %d FAILURES" % failures.size())
		quit(1)
