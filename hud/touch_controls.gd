extends Control

const TutorialSteps := preload("res://systems/tutorial.gd")

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

# set by hud_build: which buttons make sense depends on where the walk is
var main: Node2D
# the goals card is a button on touch: tapping it opens and closes the list
var goals_id := -1
var _shown_state := ""
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var buttons: Array[Dictionary] = []
var split_x := 620.0
# the MENU button's centre: just right of the vitals card (hud_panel.gd,
# 16 + 196 wide), clear of it
const MENU_X := 264.0
# GRAB appears this close to the carry item, a little before the 28 px the
# grab itself needs, so the button is up before she arrives
const GRAB_REACH := 90.0


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_user_args()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _exit_tree() -> void:
	# A one-shot action can replace the scene before that finger's touch-up
	# arrives. Release only presses this control owns, or the new scene sees
	# the action held forever and a second tap never becomes just_pressed.
	if goals_id != -1:
		Input.action_release("goals")
		goals_id = -1
	for b: Dictionary in buttons:
		if int(b.id) != -1:
			Input.action_release(String(b.get("pressed", b.action)))
			b.id = -1
	if stick_id != -1:
		stick_id = -1
		stick_vec = Vector2.ZERO
		_feed_move()


func _layout() -> void:
	# button offsets from the bottom-right corner, preserved from the
	# original tuning (authored against a 1280x720 corner at 130,130)
	var sz := get_viewport_rect().size
	var corner := sz - Vector2(130.0, 130.0)
	# "when": always, walking (mid-walk only) or stopped (paused, or the walk
	# over). Touch had no way to pause, open settings or turbo (#62), and R
	# sat on top of the goals card all walk, one tap from restarting it.
	buttons = [
		{"action": "plant", "label": "DIG", "center": corner, "r": 56.0, "id": -1, "when": "primary"},
		# BARK is also "walk select" once a walk has stopped
		{"action": "bark", "label": "BARK", "center": corner + Vector2(5.0, -138.0), "r": 44.0, "id": -1, "when": "bark"},
		{"action": "pee", "label": "PEE", "center": corner + Vector2(-128.0, 62.0), "r": 44.0, "id": -1, "when": "primary"},
		# turbo is held, like the rest: in reach of the thumb on DIG
		{"action": "turbo", "label": "RUN", "center": corner + Vector2(-130.0, -72.0), "r": 40.0, "id": -1, "when": "walking"},
		# pickup has its own action since DIG stopped grabbing: shown only
		# with something in reach to grab
		{"action": "pickup", "label": "GRAB", "center": corner + Vector2(-240.0, 0.0), "r": 40.0, "id": -1, "when": "grab"},
		# pause mid-walk, and resume from the pause menu: small, top left
		# beside the vitals card, well away from the thumbs. The menus need
		# no MENU button: BARK is back on every one of them
		# (hud/menu_flow.gd), and the stick and DIG pick and confirm
		{"action": "pause", "label": "MENU", "center": Vector2(MENU_X, 40.0), "r": 26.0, "id": -1, "when": "menu"},
		# C / Y skips a tutorial lesson; kept clear of the results card and
		# the thumbs.
		{"action": "share", "label": "SKIP", "center": Vector2(360.0, 40.0), "r": 30.0, "id": -1, "when": "tutorial"},
		# R restarts at once, so it only appears when the walk has stopped.
		# Big, and at the left edge: the results card, the death card and the
		# pause text all sit in the middle, and nothing needs the stick then
		{"action": "restart", "label": "R", "center": Vector2(sz.x * 0.09, sz.y * 0.5), "r": 38.0, "id": -1, "when": "stopped"},
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
			if _walking() and main.goals_card != null and main.goals_card.visible \
					and main.goals_card.get_global_rect().has_point(e.position):
				goals_id = e.index
				Input.action_press("goals")
				hit = true
			for b in buttons:
				if hit:
					break
				if not _shown(b):
					continue
				if e.position.distance_to(b.center) < float(b.r) + 16.0:
					b.id = e.index
					# during the urge PEE is labelled POOP and presses only poop
					b.pressed = "poop" if b.action == "pee" and main != null and main.poop_state == 1 \
						else String(b.action)
					Input.action_press(b.pressed)
					hit = true
					break
			if not hit and e.position.x < split_x:
				stick_id = e.index
				stick_origin = e.position
				stick_vec = Vector2.ZERO
				_feed_move()
		else:
			if e.index == goals_id:
				goals_id = -1
				Input.action_release("goals")
			for b in buttons:
				if int(b.id) == e.index:
					b.id = -1
					Input.action_release(String(b.get("pressed", b.action)))
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


func _walking() -> bool:
	return main != null and bool(main.started) and not bool(main.frozen) and not bool(main.paused)


func _stopped() -> bool:
	return main != null and bool(main.started) and (bool(main.frozen) or bool(main.paused))


func _tutorial_skip() -> bool:
	if not _walking() or not bool(main.tutorial_mode):
		return false
	return String(TutorialSteps.step(int(main.tut_step)).id) != "done"


func _primary_controls() -> bool:
	# These actions also drive the title, shop, progress and settings. Only
	# death/results make all three dead; a paused walk still uses them.
	return main != null and (not bool(main.started) or not bool(main.frozen) or bool(main.paused))


func _menu_button() -> bool:
	if main == null or bool(main.in_settings) or bool(main.in_shop) or bool(main.in_progress_view):
		return false
	return _walking() or bool(main.paused)


func _shown(b: Dictionary) -> bool:
	match String(b.get("when", "always")):
		"walking":
			return _walking()
		"stopped":
			return _stopped()
		"tutorial":
			return _tutorial_skip()
		"menu":
			return _menu_button()
		"primary":
			return _primary_controls()
		"bark":
			return _primary_controls() or _stopped()
		"grab":
			return _grab_in_reach()
	return true


func _grab_in_reach() -> bool:
	if not _walking() or bool(main.dog_carrying) or main.dog == null:
		return false
	var at: Vector2 = main.dog.global_position
	if main.carry_pickup.x < INF and int(main.carry_state) == 0 and at.distance_to(main.carry_pickup) < GRAB_REACH:
		return true
	# untyped: the walk home frees the balls without clearing main's fields
	for b in [main.ball, main.npc_ball]:
		if is_instance_valid(b) and b.state == b.State.RESTING and at.distance_to(b.global_position) < GRAB_REACH:
			return true
	var f = main.frisbee
	return is_instance_valid(f) and f.state == f.State.LANDED and at.distance_to(f.global_position) < GRAB_REACH


func _process(_delta: float) -> void:
	# Every visibility predicate belongs in the signature. Tutorial progress
	# and opening a menu can change the set without changing walking/stopped
	# state.
	if not visible:
		return
	var state := ""
	for b: Dictionary in buttons:
		state += "1" if _shown(b) else "0"
	if state != _shown_state:
		_shown_state = state
		queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	for b in buttons:
		if not _shown(b):
			continue
		var active: bool = int(b.id) != -1
		draw_circle(b.center, float(b.r), Color(0, 0, 0, 0.35 if active else 0.22))
		draw_arc(b.center, float(b.r), 0, TAU, 24, Color(1, 1, 1, 0.55 if active else 0.3), 3.0)
		var label: String = b.label
		if b.action == "pee" and main != null and main.poop_state == 1:
			label = "POOP"
		draw_string(f, Vector2(b.center) + Vector2(-11.0 * label.length() / 2.0, 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
	if stick_id != -1:
		draw_circle(stick_origin, 74.0, Color(1, 1, 1, 0.07))
		draw_arc(stick_origin, 74.0, 0, TAU, 28, Color(1, 1, 1, 0.3), 3.0)
		draw_circle(stick_origin + stick_vec * 58.0, 28.0, Color(1, 1, 1, 0.32))
