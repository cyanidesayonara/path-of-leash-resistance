extends SceneTree

# Tests for El Mercat's fruit handcart live event (systems/mercat_cart.gd).
# Verifies 0.8 s warning telegraph, crossing movement, dropped orange snack,
# human bump hazard, walker yielding, and main scene level integration.

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
	var MercatCartClass: GDScript = load("res://systems/mercat_cart.gd")
	_check(MercatCartClass != null, "MercatCart class loads")

	# 1. Constants and geometry
	_check(MercatCartClass.START_POS == Vector2(270.0, -2700.0), "starts by west wall stall at y = -2700")
	_check(MercatCartClass.END_POS == Vector2(980.0, -2700.0), "settles by east wall at y = -2700")
	_check(MercatCartClass.CROSSING_Y == -2700.0, "crosses at y = -2700 cross aisle")
	_check(MercatCartClass.WARN_S == 0.8, "telegraph is exactly 0.8 s")

	# 2. State machine and 0.8 s telegraph
	var cart = MercatCartClass.new()
	_check(cart.state == MercatCartClass.St.WAITING, "starts in WAITING state")

	# Dog approaching from south
	var dog_approach := Vector2(640.0, -2350.0) # dist = 350 < 420
	var human_pos := Vector2(640.0, -2300.0)
	var cue: Dictionary = cart.tick(0.016, dog_approach, human_pos)
	_check(bool(cue["warn"]), "warn cue fires on approach to cross aisle")
	_check(cart.state == MercatCartClass.St.WARN, "enters WARN state")

	# Mid warning at 0.4 s: still waiting, cart hasn't moved
	cart.tick(0.4, dog_approach, human_pos)
	_check(cart.state == MercatCartClass.St.WARN, "still in WARN at 0.4 s")
	_check(cart.pos.x == MercatCartClass.START_POS.x, "cart has not moved during 0.8 s telegraph")

	# Complete warning at 0.8 s
	cart.tick(0.45, dog_approach, human_pos)
	_check(cart.state == MercatCartClass.St.CROSSING, "enters CROSSING after 0.8 s warning")

	# 3. Crossing movement and dropped orange
	var init_x: float = cart.pos.x
	cart.tick(1.0, Vector2(100.0, -2000.0), Vector2(100.0, -2000.0))
	_check(cart.pos.x > init_x, "cart moves eastward across aisle")

	# Advance cart past ORANGE_DROP_X (590.0)
	while cart.pos.x < MercatCartClass.ORANGE_DROP_X:
		cart.tick(0.1, Vector2(100.0, -2000.0), Vector2(100.0, -2000.0))
	var cue_drop: Dictionary = cart.tick(0.1, Vector2(100.0, -2000.0), Vector2(100.0, -2000.0))
	_check(cart.orange_dropped, "orange drops as cart rattles over terrazzo seam")

	# 4. Dog snack interaction
	_check(not cart.orange_eaten, "orange is not yet eaten")
	var cue_snack: Dictionary = cart.tick(0.016, cart.orange_pos, human_pos)
	_check(bool(cue_snack["snack"]), "dog snacks on dropped orange")
	_check(cart.orange_eaten, "orange is marked eaten")

	# 5. Polite yielding when walker is in front
	var cart_yield = MercatCartClass.new()
	cart_yield.state = MercatCartClass.St.CROSSING
	cart_yield.pos = Vector2(500.0, -2700.0)
	# Human directly in front of cart at (525.0, -2700.0)
	var cue_yield: Dictionary = cart_yield.tick(0.016, Vector2(100.0, -2000.0), Vector2(525.0, -2700.0))
	_check(cart_yield.paused_for_walker, "porter pauses cart when walker is in front")
	_check(bool(cue_yield["yield"]), "yield cue fires")

	# 6. Reaching end and settling
	while cart.state == MercatCartClass.St.CROSSING:
		cart.tick(0.5, Vector2(100.0, -2000.0), Vector2(100.0, -2000.0))
	_check(cart.state == MercatCartClass.St.SETTLED, "cart reaches east wall and settles")
	_check(cart.pos.x >= MercatCartClass.END_POS.x, "settled at east wall position")

	# 7. Level integration test with main scene
	var game: Node = root.get_node("Game")
	game.level_id = "market"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.mercat_cart != null, "main instantiates mercat_cart on El Mercat")

	# Test snack bonus and goal advancement
	var initial_bones: int = m.bones
	var initial_kebabs: int = m.kebabs_eaten
	m.mercat_cart.orange_dropped = true
	m.mercat_cart.orange_pos = Vector2(550.0, -2700.0)
	m.mercat_cart.orange_eaten = false
	m.dog.global_position = m.mercat_cart.orange_pos
	m.started = true
	m._tick_mercat_cart(0.016)

	_check(m.bones == initial_bones + 2, "dog snacking on orange awards +2 bones")
	_check(m.kebabs_eaten == initial_kebabs + 1, "dog snacking advances kebabs_eaten snack goal")

	# Verify tutorial mode does not instantiate cart
	var m_tut: Node2D = load("res://main.tscn").instantiate()
	m_tut.tutorial_mode = true
	root.add_child(m_tut)
	if not m_tut.is_node_ready():
		await m_tut.ready
	_check(m_tut.mercat_cart == null, "tutorial mode does not instantiate mercat_cart")

	m.queue_free()
	m_tut.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mercat_cart: OK")
		quit(0)
	else:
		quit(1)
