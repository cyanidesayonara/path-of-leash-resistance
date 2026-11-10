extends SceneTree

# GDScript only checks a call or a property on an untyped object when the line
# runs. The walk modules reach main, the dog, your human and the leash through
# `m.` (a plain Node2D), and most of those lines sit in live-event branches the
# autowalk and the selftests never take: El Fòrum's skater set a
# `human.temper_t` that does not exist and the Raval's guitarist called a
# `human.bump()` that does not, and both shipped as a script error the first
# time a player's human was bumped.
#
# This reads every game script and holds each `m.human.X`, `m.dog.X`,
# `m.leash.X`, `m.feed.X`, `m.combo.X` and `m.X` (and `main.` for the same)
# against what the target script and its engine class really have.

const DIRS := ["res://systems", "res://entities", "res://world", "res://hud", "res://intro", "res://audio", "res://autoload"]
const TARGETS := {
	"human": "res://entities/human.gd",
	"dog": "res://entities/dog.gd",
	"leash": "res://entities/leash.gd",
	"feed": "res://hud/event_feed.gd",
	"combo": "res://systems/combo.gd",
}
const MAIN := "res://main.gd"

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


# every name a script answers to: its own methods, properties, constants and
# signals, and its engine base class's
func _members(path: String) -> Dictionary:
	var out := {}
	var sc: GDScript = load(path)
	for md: Dictionary in sc.get_script_method_list():
		out[String(md.name)] = true
	for pd: Dictionary in sc.get_script_property_list():
		out[String(pd.name)] = true
	for sd: Dictionary in sc.get_script_signal_list():
		out[String(sd.name)] = true
	for k: String in sc.get_script_constant_map():
		out[k] = true
	var base := String(sc.get_instance_base_type())
	for md: Dictionary in ClassDB.class_get_method_list(base):
		out[String(md.name)] = true
	for pd: Dictionary in ClassDB.class_get_property_list(base):
		out[String(pd.name)] = true
	for sd: Dictionary in ClassDB.class_get_signal_list(base):
		out[String(sd.name)] = true
	return out


func _initialize() -> void:
	var have := {}
	for t: String in TARGETS:
		have[t] = _members(String(TARGETS[t]))
	var main_has := _members(MAIN)
	var rx_sub := RegEx.create_from_string(r"\b(?:m|main)\.(human|dog|leash|feed|combo)\.([A-Za-z_]\w*)")
	var rx_main := RegEx.create_from_string(r"(?<![\w.])(?:m|main)\.([A-Za-z_]\w*)")
	var rx_str := RegEx.create_from_string("\"[^\"]*\"")
	var files: Array[String] = []
	for d: String in DIRS:
		for f: String in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				files.append(d.path_join(f))
	for path: String in files:
		var src := FileAccess.get_file_as_string(path)
		# only scripts whose `m` or `main` is the game's main node
		var m_is_main := src.contains("m: Node2D") or src.contains("main: Node2D") or src.contains("var main")
		var lines := src.split("\n")
		for i in range(lines.size()):
			var code: String = lines[i]
			var hash_at := code.find("#")
			if hash_at >= 0:
				code = code.substr(0, hash_at)
			code = rx_str.sub(code, "\"\"", true)
			for mt: RegExMatch in rx_sub.search_all(code):
				var t := mt.get_string(1)
				var member := mt.get_string(2)
				_check(have[t].has(member), "%s:%d: %s has no %s" % [path, i + 1, t, member])
			if m_is_main:
				for mt: RegExMatch in rx_main.search_all(code):
					var member := mt.get_string(1)
					_check(main_has.has(member), "%s:%d: main has no %s" % [path, i + 1, member])
	print("test_members_exist: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
