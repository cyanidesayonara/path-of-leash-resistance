extends SceneTree

# Tests for the Controls Overhaul:
# 1. Action separation: poop is separate from plant (dig in).
#    Holding plant does not squat when nature calls.
# 2. Pick-up action: dedicated pickup action grabs balls and parcels.
# 3. Trigger default & per-action rebinding: turbo defaults to right trigger
#    (RT / R2) and individual keyboard/gamepad/trigger rebinds update InputMap and Prompts.
# 4. Persistence: key_binds and pad_binds survive settings save/load roundtrip.

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
	var game: Node = root.get_node("Game")
	var keep_persist: bool = game.persist
	var keep_level: String = game.level_id
	var keep_key_binds: Dictionary = game.key_binds.duplicate(true)
	var keep_pad_binds: Dictionary = game.pad_binds.duplicate(true)
	game.persist = false
	root.get_node("Sfx").muted = true

	_test_gameplay_actions(game)
	_test_prompts_and_rebinds(game)

	game.key_binds = keep_key_binds
	game.pad_binds = keep_pad_binds
	game.apply_control_layout()
	game.level_id = keep_level
	game.persist = keep_persist

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_controls_overhaul: OK")
		quit(0)
	else:
		quit(1)


func _make_motion(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev


func _make_btn(btn: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	ev.pressed = true
	return ev


func _test_prompts_and_rebinds(game: Node) -> void:
	var was_style := Prompts.pad_style
	Prompts.pad_style = Prompts.PadStyle.XBOX
	game.clear_rebinds()
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("poop") == "F", "poop key default is F (%s)" % Prompts.key("poop"))
	_check(Prompts.key("pickup") == "G", "pickup key default is G (%s)" % Prompts.key("pickup"))

	Prompts.device = Prompts.PAD
	_check(Prompts.key("poop") == "Y", "poop pad default is Y (%s)" % Prompts.key("poop"))
	_check(Prompts.key("pickup") == "LB", "pickup pad default is LB (%s)" % Prompts.key("pickup"))
	_check(Prompts.key("turbo") == "RT", "turbo pad default is RT (%s)" % Prompts.key("turbo"))
	_check(InputMap.event_is_action(_make_motion(JOY_AXIS_TRIGGER_RIGHT, 0.8), "turbo"),
		"turbo defaults to JOY_AXIS_TRIGGER_RIGHT")
	_check(not InputMap.event_is_action(_make_btn(JOY_BUTTON_RIGHT_SHOULDER), "turbo"),
		"turbo no longer triggers on RB by default")

	Prompts.pad_style = Prompts.PadStyle.PLAYSTATION
	_check(Prompts.key("turbo") == "R2", "PlayStation turbo pad default is R2 (%s)" % Prompts.key("turbo"))
	_check(Prompts.key("pickup") == "L1", "PlayStation pickup pad default is L1 (%s)" % Prompts.key("pickup"))
	Prompts.pad_style = Prompts.PadStyle.XBOX

	# Per-action rebinding on keyboard, controller buttons, triggers, and sticks
	game.bind_key("poop", KEY_V)
	game.bind_pad("pickup", JOY_BUTTON_Y)
	game.bind_pad("turbo", JOY_BUTTON_RIGHT_SHOULDER)
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("poop") == "V", "rebound poop key prompt updates to V (%s)" % Prompts.key("poop"))
	Prompts.device = Prompts.PAD
	_check(Prompts.key("pickup") == "Y", "rebound pickup pad prompt updates to Y (%s)" % Prompts.key("pickup"))
	_check(Prompts.key("turbo") == "RB" and InputMap.event_is_action(_make_btn(JOY_BUTTON_RIGHT_SHOULDER), "turbo")
		and not InputMap.event_is_action(_make_motion(JOY_AXIS_TRIGGER_RIGHT, 0.8), "turbo"),
		"rebinding turbo to button replaces trigger axis")

	game.bind_pad_axis("pickup", JOY_AXIS_TRIGGER_LEFT, 1)
	_check(Prompts.key("pickup") == "LT" and InputMap.event_is_action(_make_motion(JOY_AXIS_TRIGGER_LEFT, 0.8), "pickup"),
		"rebinding pickup to left trigger updates Prompts and InputMap (%s)" % Prompts.key("pickup"))

	game.bind_pad_axis("move_up", JOY_AXIS_RIGHT_Y, -1)
	_check(Prompts.key("move") == "right stick"
		and Prompts.bound_pad_label("move_up", game.pad_binds) == "R stick ^"
		and InputMap.event_is_action(_make_motion(JOY_AXIS_RIGHT_Y, -0.8), "move_up"),
		"rebinding move_up to right stick updates Prompts and InputMap")

	# Reset to default
	game.clear_rebinds()
	_check(Prompts.key("turbo") == "RT" and InputMap.event_is_action(_make_motion(JOY_AXIS_TRIGGER_RIGHT, 0.8), "turbo"),
		"clear_rebinds restores RT trigger default for turbo")
	_check(InputMap.event_is_action(_make_motion(JOY_AXIS_LEFT_Y, -0.8), "move_up"),
		"clear_rebinds restores left stick for move_up")
	Prompts.device = Prompts.KEYS
	Prompts.pad_style = was_style


func _test_gameplay_actions(game: Node) -> void:
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)

	# 1. Verify settings roundtrip
	var orig_path: String = game.save_path
	var scratch := "user://test_controls_scratch.cfg"
	game.save_path = scratch
	var roundtrip_problems: Array = m._check_settings_roundtrip()
	game.save_path = orig_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	_check(roundtrip_problems.is_empty(), "settings roundtrip succeeded: %s" % str(roundtrip_problems))

	# 2. Verify plant vs poop separation
	m.poop_state = 1
	m.urge_timer = 20.0
	m.squat_progress = 0.0
	m.dog.planted = true
	m.dog.velocity = Vector2.ZERO

	# Simulate frame with dog.planted = true but NO poop button pressed
	Input.action_release("poop")
	Input.action_release("pee")
	m._bodily(0.2)
	_check(is_zero_approx(m.squat_progress), "holding plant does NOT advance squat progress (squat_progress=%.2f)" % m.squat_progress)

	# Simulate frame with poop button pressed
	Input.action_press("poop")
	m._bodily(0.5)
	_check(m.squat_progress > 0.4, "pressing poop advances squat progress (squat_progress=%.2f)" % m.squat_progress)
	Input.action_release("poop")

	# 3. Verify carry mission pick up
	m.carry_pickup = m.dog.global_position + Vector2(10.0, 0.0)
	m.carry_drop = m.dog.global_position + Vector2(200.0, 0.0)
	m.carry_state = 0
	m.dog_carrying = false
	m.auto_walk = false

	# Standing near carry_pickup without pressing pickup doesn't grab it
	Input.action_release("pickup")
	Input.action_release("plant")
	m._pickups(0.1)
	_check(m.carry_state == 0 and not m.dog_carrying, "near parcel without pickup action does not grab parcel")

	# Pressing pickup grabs parcel
	Input.action_press("pickup")
	m._pickups(0.1)
	_check(m.carry_state == 1 and m.dog_carrying, "pressing pickup grabs the parcel")
	Input.action_release("pickup")

	# 4. Verify tennis ball pick up
	m.phase = "freedom"
	var ball_script := load("res://entities/ball.gd")
	var ball: Node2D = Node2D.new()
	ball.set_script(ball_script)
	m.add_child(ball)
	ball.setup(m, m.dog, m.human, -500.0, 0.0)
	ball.state = 1  # State.RESTING
	ball.global_position = m.dog.global_position + Vector2(12.0, 0.0)
	m.dog_carrying = false

	# Resting near ball without pressing pickup doesn't grab it
	Input.action_release("pickup")
	Input.action_release("plant")
	ball._physics_process(0.1)
	_check(ball.state == 1 and not m.dog_carrying, "near ball without pickup action does not grab ball")

	# Pressing pickup grabs the ball
	Input.action_press("pickup")
	ball._physics_process(0.1)
	_check(ball.state == 2 and m.dog_carrying, "pressing pickup grabs the ball into mouth")
	Input.action_release("pickup")

	ball.free()
	m.free()
