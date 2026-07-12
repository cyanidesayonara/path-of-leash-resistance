extends Control

# Virtual touch controls for phones and tablets. A floating joystick on
# the left half of the screen feeds the move_* input actions with analog
# strength; buttons on the right press the named actions. Gameplay code
# reads Input exactly as it does for keyboard and gamepad - there is no
# second control scheme to maintain. Only visible on touch devices.

var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var buttons: Array[Dictionary] = []


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	buttons = [
		{"action": "plant", "label": "DIG", "center": Vector2(1150, 590), "r": 56.0, "id": -1},
		{"action": "bark", "label": "BARK", "center": Vector2(1155, 452), "r": 44.0, "id": -1},
		{"action": "pee", "label": "PEE", "center": Vector2(1022, 652), "r": 44.0, "id": -1},
		{"action": "restart", "label": "R", "center": Vector2(1244, 36), "r": 24.0, "id": -1},
	]


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			var hit := false
			for b in buttons:
				if e.position.distance_to(b.center) < float(b.r) + 16.0:
					b.id = e.index
					Input.action_press(b.action)
					hit = true
					break
			if not hit and e.position.x < 620.0:
				stick_id = e.index
				stick_origin = e.position
				stick_vec = Vector2.ZERO
				_feed_move()
		else:
			for b in buttons:
				if int(b.id) == e.index:
					b.id = -1
					Input.action_release(b.action)
			if e.index == stick_id:
				stick_id = -1
				stick_vec = Vector2.ZERO
				_feed_move()
		queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == stick_id:
			stick_vec = ((d.position - stick_origin) / 90.0).limit_length(1.0)
			_feed_move()
			queue_redraw()


func _feed_move() -> void:
	if stick_id == -1:
		for a in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(a)
		return
	Input.action_press("move_right", maxf(stick_vec.x, 0.0))
	Input.action_press("move_left", maxf(-stick_vec.x, 0.0))
	Input.action_press("move_down", maxf(stick_vec.y, 0.0))
	Input.action_press("move_up", maxf(-stick_vec.y, 0.0))


func _draw() -> void:
	var f := ThemeDB.fallback_font
	for b in buttons:
		var active: bool = int(b.id) != -1
		draw_circle(b.center, float(b.r), Color(0, 0, 0, 0.35 if active else 0.22))
		draw_arc(b.center, float(b.r), 0, TAU, 24, Color(1, 1, 1, 0.55 if active else 0.3), 3.0)
		var label: String = b.label
		draw_string(f, Vector2(b.center) + Vector2(-11.0 * label.length() / 2.0, 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	if stick_id != -1:
		draw_circle(stick_origin, 74.0, Color(1, 1, 1, 0.07))
		draw_arc(stick_origin, 74.0, 0, TAU, 28, Color(1, 1, 1, 0.3), 3.0)
		draw_circle(stick_origin + stick_vec * 58.0, 28.0, Color(1, 1, 1, 0.32))
