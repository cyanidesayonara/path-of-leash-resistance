class_name Prompts
extends RefCounted

# Every on-screen button prompt names its button through here, for whichever
# device the player last touched: keyboard, controller or touch screen (#9).
# It used to be chosen by whether a controller was PLUGGED IN, so a pad left
# on the desk put pad names in front of a keyboard player, and phones got
# keyboard keys they do not have.
#
# Prompts name ACTIONS, not keys: key("plant") is SPACE, A or DIG. Text with
# several prompts in it uses tokens: fill("{plant} dig in   {bark} bark").
# A label set with set_text() keeps its template, and refresh() re-fills it
# when the device changes, so one-shot text (the pause menu, "press R to try
# again") follows the player's hands too. main.gd feeds note() every input
# event. A class rather than a node, so tests and panels can call it.

enum { KEYS, PAD, TOUCH }

# per action: [keyboard, controller, touch]. The touch names are the labels
# on hud/touch_controls.gd's buttons; an action with no touch button falls
# back to its keyboard name.
const NAMES := {
	"move": ["WASD", "stick", "stick"],
	"move_with": ["WASD", "the left stick", "the stick"],
	"plant": ["SPACE", "A", "DIG"],
	"bark": ["E", "B", "BARK"],
	"pee": ["Q", "X", "PEE"],
	"turbo": ["SHIFT", "RB", "RUN"],
	"restart": ["R", "Start", "R"],
	"share": ["C", "Y", "SHARE"],
	# same physical action as share, but the tutorial needs to describe what
	# the context-sensitive touch button does rather than call it SHARE
	"skip": ["C", "Y", "SKIP"],
	"pause": ["ESC", "Back", "MENU"],
	"mute_music": ["M", "LB", ""],
	"goals": ["TAB", "up", "tap"],
	"left": ["A", "<", "stick"],
	"right": ["D", ">", "stick"],
	"up_down": ["W / S", "stick", "stick"],
	"left_right": ["A / D", "left/right", "stick"],
	"back": ["ESC", "B", "BARK"],
}
# a stick has to be pushed this far to count as picking up the controller,
# so a drifting stick on a pad nobody holds never takes the prompts over
const STICK_WAKE := 0.5

static var device: int = _initial()
# labels whose text came from set_text: [WeakRef, template, text last set]
static var _bound: Array = []


static func _initial() -> int:
	# --prompts=pad or --prompts=touch starts on that device, for screenshots
	for a in OS.get_cmdline_user_args():
		if a == "--prompts=pad":
			return PAD
		if a == "--prompts=touch":
			return TOUCH
		if a == "--prompts=keys":
			return KEYS
	if Input.get_connected_joypads().size() > 0:
		return PAD
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return TOUCH
	return KEYS


static func key(action: String) -> String:
	var names: Array = NAMES.get(action, [action, action, ""])
	var n := String(names[device])
	return n if n != "" else String(names[KEYS])


static func pad() -> bool:
	return device == PAD


# "{plant} dig in" -> "SPACE dig in" on a keyboard
static func fill(template: String) -> String:
	var out := template
	for action: String in NAMES.keys():
		var token := "{%s}" % action
		if out.contains(token):
			out = out.replace(token, key(action))
	return out


static func set_text(label: Object, template: String) -> void:
	var text := fill(template)
	label.text = text
	for entry: Array in _bound:
		if (entry[0] as WeakRef).get_ref() == label:
			entry[1] = template
			entry[2] = text
			return
	_bound.append([weakref(label), template, text])


# Re-fill every label set_text wrote, unless something else has written to it
# since: a label now showing other text keeps it.
static func refresh() -> void:
	var keep: Array = []
	for entry: Array in _bound:
		var label: Object = (entry[0] as WeakRef).get_ref()
		if label == null:
			continue
		if String(label.text) == String(entry[2]):
			entry[2] = fill(String(entry[1]))
			label.text = entry[2]
		keep.append(entry)
	_bound = keep


# Which device an input event came from. Returns true when that changes the
# device. Mouse events are ignored: touch screens also emit emulated mouse
# clicks, and nothing in the game is played with a mouse.
static func note(event: InputEvent) -> bool:
	var was := device
	if event is InputEventKey and event.pressed:
		device = KEYS
	elif event is InputEventJoypadButton and event.pressed:
		device = PAD
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= STICK_WAKE:
		device = PAD
	elif event is InputEventScreenTouch and event.pressed:
		device = TOUCH
	return device != was
