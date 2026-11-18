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
	"move_up": ["W", "stick", "stick"],
	"move_down": ["S", "stick", "stick"],
	"move_left": ["A", "stick", "stick"],
	"move_right": ["D", "stick", "stick"],
	"plant": ["SPACE", "A", "DIG"],
	"bark": ["E", "B", "BARK"],
	"pee": ["Q", "X", "PEE"],
	"poop": ["F", "Y", "POOP"],
	"pickup": ["G", "LB", "GRAB"],
	"turbo": ["SHIFT", "RB", "RUN"],
	"restart": ["R", "Start", "R"],
	"share": ["C", "right", "SHARE"],
	# same physical action as share, but the tutorial needs to describe what
	# the context-sensitive touch button does rather than call it SHARE
	"skip": ["C", "right", "SKIP"],
	"pause": ["ESC", "Back", "MENU"],
	"mute_music": ["M", "down", ""],
	"goals": ["TAB", "up", "tap"],
	"left": ["A", "<", "stick"],
	"right": ["D", ">", "stick"],
	"up_down": ["W / S", "stick", "stick"],
	"left_right": ["A / D", "left/right", "stick"],
	"back": ["ESC", "B", "BARK"],
	# the intro's skip hint: any press skips, this is the one it names
	"intro_skip": ["SPACE", "A", "TAP"],
}
# a stick has to be pushed this far to count as picking up the controller,
# so a drifting stick on a pad nobody holds never takes the prompts over
const STICK_WAKE := 0.5

static var device: int = _initial()
# labels whose text came from set_text: [WeakRef, template, text last set]
static var _bound: Array = []


static var _layout_key_overrides: Dictionary = {}
static var _layout_pad_overrides: Dictionary = {}


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
	if device == KEYS and _layout_key_overrides.has(action):
		return String(_layout_key_overrides[action])
	if device == PAD and _layout_pad_overrides.has(action):
		return String(_layout_pad_overrides[action])
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


static func key_label(code: int) -> String:
	match code:
		KEY_ESCAPE: return "ESC"
		KEY_SPACE: return "SPACE"
		KEY_SHIFT: return "SHIFT"
		KEY_CTRL: return "CTRL"
		KEY_ALT: return "ALT"
		KEY_TAB: return "TAB"
		KEY_ENTER: return "ENTER"
		KEY_BACKSPACE: return "BKSP"
		KEY_DELETE: return "DEL"
		KEY_INSERT: return "INS"
		KEY_HOME: return "HOME"
		KEY_END: return "END"
		KEY_PAGEUP: return "PGUP"
		KEY_PAGEDOWN: return "PGDN"
		KEY_UP: return "UP"
		KEY_DOWN: return "DOWN"
		KEY_LEFT: return "LEFT"
		KEY_RIGHT: return "RIGHT"
		KEY_SEMICOLON: return ";"
		KEY_APOSTROPHE: return "'"
		KEY_COMMA: return ","
		KEY_PERIOD: return "."
		KEY_SLASH: return "/"
		KEY_BACKSLASH: return "\\"
		KEY_BRACKETLEFT: return "["
		KEY_BRACKETRIGHT: return "]"
	var s := OS.get_keycode_string(code as Key).to_upper()
	return s if s != "" else "?"


static func pad_label(btn: int) -> String:
	match btn:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_DPAD_UP: return "up"
		JOY_BUTTON_DPAD_DOWN: return "down"
		JOY_BUTTON_DPAD_LEFT: return "left"
		JOY_BUTTON_DPAD_RIGHT: return "right"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_BACK: return "Back"
	return "B%d" % btn


static func update_layout(layout: String, custom_keys: Dictionary = {}, custom_pads: Dictionary = {}) -> void:
	_layout_key_overrides.clear()
	_layout_pad_overrides.clear()
	match layout:
		"arrows":
			_layout_key_overrides["move"] = "ARROWS"
			_layout_key_overrides["move_with"] = "the arrow keys"
			_layout_key_overrides["move_up"] = "UP"
			_layout_key_overrides["move_down"] = "DOWN"
			_layout_key_overrides["move_left"] = "LEFT"
			_layout_key_overrides["move_right"] = "RIGHT"
			_layout_key_overrides["up_down"] = "UP / DOWN"
			_layout_key_overrides["left_right"] = "LEFT / RIGHT"
			_layout_key_overrides["left"] = "LEFT"
			_layout_key_overrides["right"] = "RIGHT"
			_layout_key_overrides["bark"] = "CTRL"
			_layout_key_overrides["pee"] = "DEL"
			_layout_key_overrides["poop"] = "END"
			_layout_key_overrides["pickup"] = "PGDN"
			_layout_key_overrides["turbo"] = "SHIFT"
		"compact":
			_layout_key_overrides["move"] = "IJKL"
			_layout_key_overrides["move_with"] = "IJKL"
			_layout_key_overrides["move_up"] = "I"
			_layout_key_overrides["move_down"] = "K"
			_layout_key_overrides["move_left"] = "J"
			_layout_key_overrides["move_right"] = "L"
			_layout_key_overrides["up_down"] = "I / K"
			_layout_key_overrides["left_right"] = "J / L"
			_layout_key_overrides["left"] = "J"
			_layout_key_overrides["right"] = "L"
			_layout_key_overrides["plant"] = "SPACE"
			_layout_key_overrides["bark"] = "O"
			_layout_key_overrides["pee"] = "U"
			_layout_key_overrides["poop"] = "H"
			_layout_key_overrides["pickup"] = "N"
			_layout_key_overrides["turbo"] = ";"
		"southpaw":
			_layout_pad_overrides["move"] = "right stick"
			_layout_pad_overrides["move_with"] = "the right stick"
			_layout_pad_overrides["plant"] = "X"
			_layout_pad_overrides["bark"] = "A"
			_layout_pad_overrides["pee"] = "B"
			_layout_pad_overrides["poop"] = "Y"
			_layout_pad_overrides["pickup"] = "RB"
			_layout_pad_overrides["turbo"] = "LB"
	for act: String in custom_keys.keys():
		_layout_key_overrides[act] = key_label(int(custom_keys[act]))
	for act: String in custom_pads.keys():
		_layout_pad_overrides[act] = pad_label(int(custom_pads[act]))
	if custom_keys.has("move_left"):
		_layout_key_overrides["left"] = _layout_key_overrides["move_left"]
	if custom_keys.has("move_right"):
		_layout_key_overrides["right"] = _layout_key_overrides["move_right"]
	if custom_keys.has("move_up") or custom_keys.has("move_down"):
		var mu := String(_layout_key_overrides.get("move_up", NAMES["move_up"][KEYS]))
		var md := String(_layout_key_overrides.get("move_down", NAMES["move_down"][KEYS]))
		_layout_key_overrides["up_down"] = "%s / %s" % [mu, md]
	if custom_keys.has("move_left") or custom_keys.has("move_right"):
		var ml := String(_layout_key_overrides.get("move_left", NAMES["move_left"][KEYS]))
		var mr := String(_layout_key_overrides.get("move_right", NAMES["move_right"][KEYS]))
		_layout_key_overrides["left_right"] = "%s / %s" % [ml, mr]
	if custom_keys.has("move_up") or custom_keys.has("move_down") \
			or custom_keys.has("move_left") or custom_keys.has("move_right"):
		var mu := String(_layout_key_overrides.get("move_up", NAMES["move_up"][KEYS]))
		var ml := String(_layout_key_overrides.get("move_left", NAMES["move_left"][KEYS]))
		var md := String(_layout_key_overrides.get("move_down", NAMES["move_down"][KEYS]))
		var mr := String(_layout_key_overrides.get("move_right", NAMES["move_right"][KEYS]))
		var mv := "%s/%s/%s/%s" % [mu, ml, md, mr] \
			if (mu.length() > 1 or ml.length() > 1 or md.length() > 1 or mr.length() > 1) \
			else "%s%s%s%s" % [mu, ml, md, mr]
		_layout_key_overrides["move"] = mv
		_layout_key_overrides["move_with"] = mv
	if custom_keys.has("share"):
		_layout_key_overrides["skip"] = _layout_key_overrides["share"]
	if custom_keys.has("pause"):
		_layout_key_overrides["back"] = _layout_key_overrides["pause"]
	if custom_pads.has("share"):
		_layout_pad_overrides["skip"] = _layout_pad_overrides["share"]
	if custom_pads.has("bark"):
		_layout_pad_overrides["back"] = _layout_pad_overrides["bark"]
	refresh()


static func bound_key_label(action: String, custom_keys: Dictionary = {}) -> String:
	if custom_keys.has(action):
		return key_label(int(custom_keys[action]))
	if InputMap.has_action(action):
		for ev: InputEvent in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var kev := ev as InputEventKey
				var code := kev.physical_keycode if kev.physical_keycode != 0 else kev.keycode
				if code != 0:
					return key_label(code)
	if _layout_key_overrides.has(action):
		return String(_layout_key_overrides[action])
	var names: Array = NAMES.get(action, [action.to_upper(), "", ""])
	return String(names[KEYS])


static func bound_pad_label(action: String, custom_pads: Dictionary = {}) -> String:
	if custom_pads.has(action):
		return pad_label(int(custom_pads[action]))
	if InputMap.has_action(action):
		for ev: InputEvent in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton:
				return pad_label((ev as InputEventJoypadButton).button_index)
		if action.begins_with("move_"):
			for ev: InputEvent in InputMap.action_get_events(action):
				if ev is InputEventJoypadMotion:
					var ax := (ev as InputEventJoypadMotion).axis
					if ax == JOY_AXIS_RIGHT_X or ax == JOY_AXIS_RIGHT_Y:
						return "R stick"
					return "L stick"
	if _layout_pad_overrides.has(action):
		return String(_layout_pad_overrides[action])
	var names: Array = NAMES.get(action, ["", "stick", ""])
	var p := String(names[PAD])
	return p if p != "" else "-"
