extends SceneTree

# Tests for the Controls Overhaul:
# 1. Action separation: poop is separate from plant (dig in).
#    Holding plant does not squat when nature calls.
# 2. Pick-up action: dedicated pickup action grabs balls and parcels.
# 3. Layouts & rebinding: default, arrows, compact, and southpaw layouts
#    properly configure InputMap and Prompts tokens.
# 4. Persistence: control_layout survives settings save/load roundtrip.

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
	game.persist = false
	root.get_node("Sfx").muted = true

	_test_prompts_and_layouts(game)
	_test_gameplay_actions(game)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_controls_overhaul: OK")
		quit(0)
	else:
		quit(1)


func _test_prompts_and_layouts(game: Node) -> void:
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("poop") == "Q", "poop key default is Q (%s)" % Prompts.key("poop"))
	_check(Prompts.key("pickup") == "SPACE", "pickup key default is SPACE (%s)" % Prompts.key("pickup"))

	Prompts.device = Prompts.PAD
	_check(Prompts.key("poop") == "X", "poop pad default is X (%s)" % Prompts.key("poop"))
	_check(Prompts.key("pickup") == "A", "pickup pad default is A (%s)" % Prompts.key("pickup"))

	# Layout switching
	game.control_layout = "arrows"
	game.apply_control_layout()
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("move") == "ARROWS", "arrows layout key prompt for move is ARROWS")
	_check(Prompts.key("poop") == "DEL", "arrows layout key prompt for poop is DEL")

	game.control_layout = "compact"
	game.apply_control_layout()
	_check(Prompts.key("move") == "IJKL", "compact layout key prompt for move is IJKL")
	_check(Prompts.key("poop") == "U", "compact layout key prompt for poop is U")

	game.control_layout = "southpaw"
	game.apply_control_layout()
	Prompts.device = Prompts.PAD
	_check(Prompts.key("move") == "right stick", "southpaw layout pad prompt for move is right stick")
	_check(Prompts.key("turbo") == "LB", "southpaw layout pad prompt for turbo is LB")

	# Reset to default
	game.control_layout = "default"
	game.apply_control_layout()
	Prompts.device = Prompts.KEYS


func _test_gameplay_actions(game: Node) -> void:
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)

	# 1. Verify settings roundtrip
	var roundtrip_problems: Array = m._check_settings_roundtrip()
	_check(roundtrip_problems.is_empty(), "settings roundtrip with control_layout succeeded: %s" % str(roundtrip_problems))

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

	ball.queue_free()
	m.queue_free()
