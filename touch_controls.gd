extends Control

# Virtual touch controls for phones and tablets. A floating joystick on
# the left half of the screen feeds the move_* input actions with analog
# strength; buttons on the right press the named actions. Gameplay code
# reads Input exactly as it does for keyboard and gamepad - there is no
# second control scheme to maintain. Only visible on touch devices.
#
# Button centres and the stick/button split are computed from the actual
# viewport size, not hardcoded against the 1280x720 reference frame. The
# project stretches with aspect "expand" so a phone's real aspect ratio
# (almost always wider or narrower than 16:9) reveals MORE or LESS canvas
# than 1280x720 rather than letterboxing it - a control cluster anchored to
# literal x=1150..1244 would drift away from the true right edge on a wide
# window, and the "< 620 = left half" stick threshold would stop matching
# the screen's actual midpoint, opening a dead zone between the stick and
# the buttons that responds to neither.

var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var buttons: Array[Dictionary] = []
var split_x := 620.0


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_user_args()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	# button offsets from the bottom-right corner, preserved from the
	# original tuning (authored against a 1280x720 corner at 130,130)
	var sz := get_viewport_rect().size
	var corner := sz - Vector2(130.0, 130.0)
	buttons = [
		{"action": "plant", "label": "DIG", "center": corner, "r": 56.0, "id": -1},
		{"action": "bark", "label": "BARK", "center": corner + Vector2(5.0, -138.0), "r": 44.0, "id": -1},
		{"action": "pee", "label": "PEE", "center": corner + Vector2(-128.0, 62.0), "r": 44.0, "id": -1},
		{"action": "restart", "label": "R", "center": Vector2(sz.x - 36.0, 36.0), "r": 24.0, "id": -1},
	]
	split_x = sz.x * 0.5 - 20.0
	queue_redraw()


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
			if not hit and e.position.x < split_x:
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
