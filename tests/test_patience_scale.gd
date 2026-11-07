extends SceneTree

# Your human's patience runs from 0 to 1 (entities/human.gd). A live event
# that took 8.0 off it on a bump (Plaça d'Espanya's bubbles, El Fòrum's
# skater) emptied it at once and sprang a correction on the player for one
# bump. Every script that takes patience away takes a fraction of one.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _scan(dir: String) -> void:
	var rx := RegEx.create_from_string(r"patience\s*-\s*([0-9]+(?:\.[0-9]+)?)")
	for f: String in DirAccess.get_files_at(dir):
		if not f.ends_with(".gd"):
			continue
		var path := dir.path_join(f)
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in range(lines.size()):
			for mt: RegExMatch in rx.search_all(lines[i]):
				_check(float(mt.get_string(1)) < 1.0, "%s:%d takes %s off a 0..1 patience" % [path, i + 1, mt.get_string(1)])


func _initialize() -> void:
	for d: String in ["res://systems", "res://entities", "res://world"]:
		_scan(d)
	_check(load("res://systems/espanya.gd").BUMP_PATIENCE < 0.5, "a bubble bump costs a fraction")
	_check(load("res://systems/forum.gd").BUMP_PATIENCE < 0.5, "a board bump costs a fraction")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_patience_scale: OK")
		quit(0)
	else:
		quit(1)
