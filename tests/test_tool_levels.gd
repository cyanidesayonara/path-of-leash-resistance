extends SceneTree

# The screenshot sweep and the behaviour snapshot name every walk in
# Game.LEVELS. Both lists are written out in shell, and both stopped at
# Dia de Partit for four walks: CI's sweep never photographed El Port,
# Plaça Reial, El Veterinari or El Tibidabo, and a default snapshot never
# ran them.

const TOOLS := {
	"res://tools/shot_sweep.sh": "LEVELS=(",
	"res://tools/behaviour_snapshot.sh": "LEVELS=\"${LEVELS:-",
}

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	for path: String in TOOLS:
		# a Windows checkout may have CRLF line ends
		var text := FileAccess.get_file_as_string(path).replace("", "")
		var head: String = TOOLS[path]
		var at := text.find(head)
		_check(at >= 0, "%s has its level list" % path)
		if at < 0:
			continue
		var start := at + head.length()
		var line := text.substr(start, text.find("\n", start) - start)
		var listed: Array[String] = []
		for w: String in line.replace(")", " ").replace("}\"", " ").split(" ", false):
			listed.append(w)
		for lv: String in game.LEVELS:
			_check(lv in listed, "%s lists %s" % [path.get_file(), lv])
		for lv: String in listed:
			_check(lv in game.LEVELS, "%s lists only walks (%s)" % [path.get_file(), lv])
	print("test_tool_levels: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
