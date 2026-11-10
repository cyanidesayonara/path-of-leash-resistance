extends SceneTree

# Tests La Cremada's Churro Cart live event (systems/churro_cart.gd,
# systems/cremada.gd):
# - Registration: m.churro_cart present on La Cremada
# - Conditions: active in clear/wind and dusk/night; packed in rain/snow or day
# - 0.8 s warning telegraph: fires once as human passes TRIGGER_Y, no bumps during it
# - Active tricks:
#   - Dropped churro snack when dog reaches CHURRO_DROP_POS
#   - Bark greeting when dog barks near the cart
#   - Soft hazard bump (-0.08 patience) only when human walks into HIT_R
#   - Near-miss dodge when human steps close and clears without hit
# - Autowalk safety: cart is 95 px east of center line, autowalk passes clean

const DT := 1.0 / 60.0
const ChurroCart := preload("res://systems/churro_cart.gd")

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
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "cremada"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = false

	# 1. Registration & layout
	_check(m.churro_cart != null, "churro_cart initialized on cremada")
	_check(ChurroCart.CART_POS == Vector2(735.0, -4180.0), "cart placed at x=735, y=-4180")
	_check(ChurroCart.TRIGGER_Y == -3960.0, "trigger y at -3960")
	_check(ChurroCart.WARN_DURATION == 0.8, "0.8s warning duration")
	_check(ChurroCart.BUMP_PATIENCE == 0.08, "0.08 bump patience")

	# 2. Weather & hour conditions
	_check(ChurroCart.active_in("clear", "night"), "active in clear night")
	_check(ChurroCart.active_in("wind", "night"), "active in wind night")
	_check(ChurroCart.active_in("clear", "dusk"), "active in clear dusk")
	_check(not ChurroCart.active_in("rain", "night"), "inactive in rain")
	_check(not ChurroCart.active_in("snow", "night"), "inactive in snow")
	_check(not ChurroCart.active_in("clear", "day"), "inactive by day")
	_check(not ChurroCart.active_in("clear", "dawn"), "inactive at dawn")

	# 3. Unit state machine
	var c: ChurroCart = ChurroCart.new()
	c.sky_ok = true

	# Idle: outside trigger zone
	var r: Dictionary = c.tick(DT, Vector2(640.0, -3800.0), Vector2(640.0, -3800.0), true)
	_check(not bool(r["warn"]), "no warn before trigger line")
	_check(c.state == ChurroCart.State.IDLE, "remains idle")

	# Inward walking does not trigger
	r = c.tick(DT, Vector2(640.0, -4000.0), Vector2(640.0, -4000.0), false)
	_check(not bool(r["warn"]), "inward walk does not trigger")
	_check(c.state == ChurroCart.State.IDLE, "remains idle on inward walk")

	# Trigger telegraph: outward crossing -3960
	r = c.tick(DT, Vector2(640.0, -3970.0), Vector2(640.0, -3970.0), true)
	_check(bool(r["warn"]), "telegraph fires at trigger line")
	_check(c.state == ChurroCart.State.TELEGRAPH, "state is telegraph")
	_check(c.timer == ChurroCart.WARN_DURATION, "timer set to 0.8")

	# During telegraph: no bumps even if human touches cart
	r = c.tick(0.4, Vector2(640.0, -4180.0), ChurroCart.CART_POS, true)
	_check(not bool(r["bump"]), "no bump during telegraph")
	_check(c.state == ChurroCart.State.TELEGRAPH, "still telegraphing")

	# Telegraph finishes after remaining 0.4s
	r = c.tick(0.41, Vector2(640.0, -4100.0), Vector2(640.0, -4100.0), true)
	_check(c.state == ChurroCart.State.ACTIVE, "state is active after telegraph")

	# 4. Bark trick
	_check(c.on_bark(ChurroCart.CART_POS + Vector2(50.0, 0.0)), "bark near cart succeeds")
	_check(not c.on_bark(ChurroCart.CART_POS + Vector2(50.0, 0.0)), "second bark returns false")

	# 5. Dropped churro snack snatch
	_check(not c.churro_eaten, "churro not eaten yet")
	r = c.tick(DT, Vector2(640.0, -4100.0), Vector2(640.0, -4100.0), true)
	_check(not bool(r["snatch"]), "no snatch while dog is far")

	r = c.tick(DT, ChurroCart.CHURRO_DROP_POS, Vector2(640.0, -4100.0), true)
	_check(bool(r["snatch"]), "snatch fires when dog reaches dropped churro")
	_check(c.churro_eaten, "churro marked eaten")

	r = c.tick(DT, ChurroCart.CHURRO_DROP_POS, Vector2(640.0, -4100.0), true)
	_check(not bool(r["snatch"]), "snatch does not re-fire")

	# 6. Soft hazard bump
	var c_bump: ChurroCart = ChurroCart.new()
	c_bump.sky_ok = true
	c_bump.state = ChurroCart.State.ACTIVE
	r = c_bump.tick(DT, Vector2(640.0, -4180.0), ChurroCart.CART_POS, true)
	_check(bool(r["bump"]), "bump fires when human enters cart footprint")
	_check(c_bump.human_hit, "human_hit flagged")
	_check(c_bump.bump_dir != Vector2.ZERO, "bump direction calculated")

	r = c_bump.tick(DT, Vector2(640.0, -4180.0), ChurroCart.CART_POS, true)
	_check(not bool(r["bump"]), "bump fires only once")

	# 7. NearMiss dodge
	var c_dodge: ChurroCart = ChurroCart.new()
	c_dodge.sky_ok = true
	c_dodge.state = ChurroCart.State.ACTIVE
	# Step into close threat zone without hitting
	r = c_dodge.tick(DT, Vector2(640.0, -4180.0), ChurroCart.CART_POS + Vector2(-38.0, 0.0), true)
	_check(c_dodge.threatened, "human threatened when close to cart")
	_check(not bool(r["dodge"]), "no dodge while still close")

	# Step clear away
	r = c_dodge.tick(DT, Vector2(640.0, -4180.0), Vector2(640.0, -4250.0), true)
	_check(bool(r["dodge"]), "dodge awarded after stepping clear")

	# 8. Autowalk line safety (x = 640.0)
	var c_auto: ChurroCart = ChurroCart.new()
	c_auto.sky_ok = true
	c_auto.state = ChurroCart.State.ACTIVE
	var auto_y := -3900.0
	var bumped := false
	var dodged := false
	while auto_y > -4400.0:
		var step: Dictionary = c_auto.tick(DT, Vector2(640.0, auto_y - 20.0), Vector2(640.0, auto_y), true)
		if bool(step["bump"]):
			bumped = true
		if bool(step["dodge"]):
			dodged = true
		auto_y -= 2.0
	_check(not bumped, "autowalk never bumps cart")
	_check(not dodged, "autowalk never earns dodge")

	m.queue_free()
	await physics_frame

	print("test_churro_cart: %d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		quit(0)
	else:
		quit(1)
