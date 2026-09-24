extends SceneTree

# Button prompts follow the device the player last used (#9, hud/prompts.gd):
# keyboard, controller or touch, switching on real input only - not on a pad
# merely being plugged in, a drifting stick, or the mouse clicks a touch
# screen emulates. Text set once is re-filled when the device changes, unless
# something else has written to that label since. And no UI string outside
# hud/prompts.gd names a key: every prompt goes through it, and every
# {token} in the source is an action it knows.

var checks := 0
var failures: Array[String] = []

const SOURCES := ["res://main.gd", "res://hud", "res://systems", "res://world", "res://entities", "res://autoload"]
const KEY_NAMES := ["SPACE", "ESC", "SHIFT", "TAB", "WASD"]


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	_devices()
	_names_and_fill()
	_bound_labels()
	_sources()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_prompts: OK")
		quit(0)
	else:
		quit(1)


func _key(pressed := true) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = pressed
	return e


func _devices() -> void:
	Prompts.device = Prompts.KEYS
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A
	b.pressed = true
	_check(Prompts.note(b) and Prompts.device == Prompts.PAD, "a pad button switches to the pad")
	_check(not Prompts.note(b), "a second pad press is not a change")
	_check(Prompts.note(_key()) and Prompts.device == Prompts.KEYS, "a key press switches to the keyboard")
	_check(not Prompts.note(_key(false)) and Prompts.device == Prompts.KEYS, "a key release changes nothing")
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.2
	_check(not Prompts.note(drift) and Prompts.device == Prompts.KEYS, "a drifting stick does not take the prompts over")
	var push := InputEventJoypadMotion.new()
	push.axis = JOY_AXIS_LEFT_Y
	push.axis_value = -0.9
	_check(Prompts.note(push) and Prompts.device == Prompts.PAD, "pushing the stick switches to the pad")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	_check(Prompts.note(touch) and Prompts.device == Prompts.TOUCH, "a touch switches to touch")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_check(not Prompts.note(click) and Prompts.device == Prompts.TOUCH, "the mouse click a touch emulates is ignored")


func _names_and_fill() -> void:
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("plant") == "SPACE" and Prompts.key("restart") == "R", "keyboard names")
	Prompts.device = Prompts.PAD
	_check(Prompts.key("plant") == "A" and Prompts.key("restart") == "Start" and Prompts.pad(), "controller names")
	Prompts.device = Prompts.TOUCH
	_check(Prompts.key("plant") == "DIG" and Prompts.key("pee") == "PEE", "touch names are the touch buttons' labels")
	_check(Prompts.key("turbo") == "SHIFT", "an action with no touch button falls back to its key")
	Prompts.device = Prompts.KEYS
	var t := Prompts.fill("{plant}  resume     {restart}  restart")
	_check(t == "SPACE  resume     R  restart", "fill replaces every token (%s)" % t)
	_check(Prompts.fill("no prompts here") == "no prompts here", "fill leaves plain text alone")
	for action: String in Prompts.NAMES.keys():
		var names: Array = Prompts.NAMES[action]
		_check(names.size() == 3 and String(names[0]) != "" and String(names[1]) != "",
			"'%s' names a key and a pad button" % action)


func _bound_labels() -> void:
	Prompts.device = Prompts.KEYS
	var a := Label.new()
	var b := Label.new()
	Prompts.set_text(a, "Press {restart} to try again")
	Prompts.set_text(b, "{pause}  settings")
	b.text = "something else now"
	_check(a.text == "Press R to try again", "set_text fills the template")
	Prompts.device = Prompts.PAD
	Prompts.refresh()
	_check(a.text == "Press Start to try again", "a device change re-fills the label (%s)" % a.text)
	_check(b.text == "something else now", "a label written to since keeps what it says")
	Prompts.set_text(a, "{plant} dig")
	Prompts.device = Prompts.KEYS
	Prompts.refresh()
	_check(a.text == "SPACE dig", "setting a label again replaces its template")
	a.free()
	b.free()
	Prompts.refresh()
	_check(Prompts._bound.is_empty(), "freed labels are forgotten")


func _sources() -> void:
	var files: Array[String] = []
	for s: String in SOURCES:
		if s.ends_with(".gd"):
			files.append(s)
		else:
			_collect(s, files)
	var token := RegEx.create_from_string("\\{([a-z_]+)\\}")
	var literal := RegEx.create_from_string("\"([^\"\\\\]|\\\\.)*\"")
	for path in files:
		if path.ends_with("prompts.gd"):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in range(lines.size()):
			var line := lines[i].strip_edges()
			if line.begins_with("#"):
				continue
			for m in literal.search_all(line):
				var s := m.get_string()
				for t in token.search_all(s):
					_check(Prompts.NAMES.has(t.get_string(1)),
						"%s:%d: {%s} is an action Prompts knows" % [path, i + 1, t.get_string(1)])
				for k: String in KEY_NAMES:
					if RegEx.create_from_string("\\b%s\\b" % k).search(s) != null:
						_check(false, "%s:%d: '%s' names a key; use Prompts" % [path, i + 1, s])


func _collect(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(d), out)
