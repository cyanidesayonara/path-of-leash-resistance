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

const SOURCES := ["res://main.gd", "res://hud", "res://systems", "res://world", "res://entities", "res://autoload", "res://intro"]
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
	Prompts.pad_style = Prompts.PadStyle.XBOX
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
	var trig_drift := InputEventJoypadMotion.new()
	trig_drift.axis = JOY_AXIS_TRIGGER_RIGHT
	trig_drift.axis_value = 0.2
	_check(not Prompts.note(trig_drift) and Prompts.device == Prompts.KEYS, "a resting trigger does not take the prompts over")
	var trig_pull := InputEventJoypadMotion.new()
	trig_pull.axis = JOY_AXIS_TRIGGER_RIGHT
	trig_pull.axis_value = 0.8
	_check(Prompts.note(trig_pull) and Prompts.device == Prompts.PAD, "pulling a trigger switches to the pad")
	_check(Prompts.note(_key()) and Prompts.device == Prompts.KEYS, "a key press returns to keyboard after trigger")
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
	Prompts.pad_style = Prompts.PadStyle.XBOX


func _names_and_fill() -> void:
	Prompts.pad_style = Prompts.PadStyle.XBOX
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("plant") == "SPACE" and Prompts.key("restart") == "R", "keyboard names")
	Prompts.device = Prompts.PAD
	_check(Prompts.key("plant") == "A" and Prompts.key("restart") == "Start" and Prompts.pad(), "controller names")
	_check(Prompts.key("turbo") == "RT", "xbox turbo prompt defaults to RT (%s)" % Prompts.key("turbo"))
	_check(Prompts.key("poop") != Prompts.key("share") and Prompts.key("poop") != Prompts.key("skip"), "poop and skip use distinct pad buttons")
	Prompts.pad_style = Prompts.PadStyle.PLAYSTATION
	_check(Prompts.key("turbo") == "R2" and Prompts.key("pickup") == "L1", "playstation trigger and shoulder prompts (%s / %s)" % [Prompts.key("turbo"), Prompts.key("pickup")])
	_check(Prompts.key("restart") == "Options" and Prompts.key("pause") == "Share", "playstation start/back prompts (%s / %s)" % [Prompts.key("restart"), Prompts.key("pause")])
	_check(Prompts.pad_bind_label(JOY_BUTTON_RIGHT_SHOULDER) == "R1", "pad_bind_label formats PS shoulder")
	_check(Prompts.pad_bind_label({"axis": JOY_AXIS_TRIGGER_LEFT, "sign": 1}) == "L2", "pad_bind_label formats PS left trigger")
	Prompts.pad_style = Prompts.PadStyle.XBOX
	_check(Prompts.pad_bind_label({"axis": JOY_AXIS_TRIGGER_RIGHT, "sign": 1}) == "RT", "pad_bind_label formats Xbox right trigger")
	_check(Prompts.pad_bind_label({"axis": JOY_AXIS_RIGHT_Y, "sign": -1}) == "R stick ^", "pad_bind_label formats right stick up")
	Prompts.device = Prompts.TOUCH
	_check(Prompts.key("plant") == "DIG" and Prompts.key("pee") == "PEE", "touch names are the touch buttons' labels")
	_check(Prompts.key("turbo") == "RUN" and Prompts.key("pause") == "MENU", "the touch buttons for turbo and the menu (#62)")
	_check(Prompts.key("share") == "SHARE" and Prompts.key("skip") == "SKIP", "touch names distinguish sharing from tutorial skipping")
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
