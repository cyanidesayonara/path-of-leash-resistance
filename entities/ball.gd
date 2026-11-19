extends Node2D

# A tennis ball for real fetch: the owner THROWS it out, the dog runs to
# it, carries it in their mouth, and brings it back to the thrower. A
# delivered ball scores and gets thrown again. main.gd counts returns.
# It bounces as it goes. Snatched while it is still bouncing or rolling (no
# pickup press needed), and brought back quick, it pays more.

enum State { THROWN, RESTING, CARRIED }

var main: Node2D
var dog: Node2D
var thrower: Node2D  # who throws and who the ball is returned to
var state := State.THROWN
var vel := Vector2.ZERO
var lo := 0.0
var hi := 0.0
var bob := 0.0
var rest_t := 0.0
var arc := 0.0  # visual hop height while thrown
var x_lo := 180.0
var x_hi := 1100.0
var snatched := false   # taken on the move, not picked up off the grass
var out_t := 0.0        # seconds since it was thrown
const SNATCH_R := 24.0
const QUICK_S := 4.0    # back to the thrower within this: a quick fetch


func setup(
	m: Node2D,
	d: Node2D,
	thrower_node: Node2D,
	y_lo: float,
	y_hi: float,
	throw_x_lo: float = 180.0,
	throw_x_hi: float = 1100.0,
) -> void:
	main = m
	dog = d
	thrower = thrower_node
	lo = y_lo
	hi = y_hi
	# window must be set BEFORE the first throw - calling set_throw_window
	# after setup left the opening toss aimed at the default field
	x_lo = throw_x_lo
	x_hi = throw_x_hi
	_throw()


func set_throw_window(lo_x: float, hi_x: float) -> void:
	# the dog beach throws into the surf rather than across a field, so the
	# window has to be able to sit off to one side
	x_lo = lo_x
	x_hi = hi_x


func is_carried() -> bool:
	return state == State.CARRIED


# in her jaws: the ball bulges out either side of her muzzle and past its tip
func draw_held(c: ShapeBatch, bite: Vector2, fwd: Vector2, _side: Vector2, _jaw: float) -> void:
	var at := bite + fwd * 6.5
	c.circle(at, 5.7, Color(0.36, 0.38, 0.10, 0.9))
	c.circle(at, 5.0, Color(0.82, 0.86, 0.3))
	# one felt seam curling over the top, not two marks that read as eyes
	var seam := Color(0.95, 0.95, 0.9)
	var c0 := at + fwd.rotated(0.3) * 4.4
	var c1 := at + fwd.rotated(1.0) * 2.2
	var c2 := at + fwd.rotated(1.9) * 4.4
	c.line(c0, c1, seam, 1.1)
	c.line(c1, c2, seam, 1.1)


# held: in her mouth, drawn by her between her head and her muzzle
func _hold(d: Node2D) -> void:
	if state == State.CARRIED:
		d.held = self
	elif d.held == self:
		d.held = null


func _throw() -> void:
	state = State.THROWN
	snatched = false
	out_t = 0.0
	global_position = thrower.global_position
	var target := Vector2(randf_range(x_lo, x_hi), randf_range(lo + 40.0, hi - 40.0))
	vel = (target - global_position).normalized() * randf_range(340.0, 460.0)
	if thrower == main.human:
		main.human.throw_pose()


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	# a neighbour's ball outlives its owner only until they leave the park
	if not is_instance_valid(thrower):
		if state == State.CARRIED:
			main.dog_carrying = false
		queue_free()
		return
	bob += delta
	if state != State.CARRIED:
		out_t += delta
	_hold(dog)
	match state:
		State.THROWN:
			position += vel * delta
			vel = vel.move_toward(Vector2.ZERO, 300.0 * delta)
			# bounces, lower and quicker as it slows
			arc = absf(sin(out_t * 7.0)) * clampf(vel.length() / 32.0, 0.0, 14.0)
			if out_t > 0.35 and not main.dog_carrying and global_position.distance_to(dog.global_position) < SNATCH_R:
				state = State.CARRIED
				snatched = true
				main.dog_carrying = true
				main.on_ball_grabbed()
			if position.x < 100.0 or position.x > 1180.0:
				vel.x = -absf(vel.x) * signf(590.0 - position.x)
			position.y = clampf(position.y, lo, hi)
			if vel.length() < 26.0:
				state = State.RESTING
				rest_t = 0.0
		State.RESTING:
			arc = 0.0
			rest_t += delta
			# one ball in the mouth at a time (the player's own and a
			# neighbour's can both be out at once)
			if not main.dog_carrying and global_position.distance_to(dog.global_position) < 28.0:
				if main.auto_walk or Input.is_action_pressed("pickup") or Input.is_action_just_pressed("pickup"):
					state = State.CARRIED
					main.dog_carrying = true
					main.on_ball_grabbed()
		State.CARRIED:
			# ride at the dog's mouth (nose tip is ~facing*22 from centre)
			global_position = dog.global_position + dog.facing * 22.0
			if global_position.distance_to(thrower.global_position) < 42.0:
				main.dog_carrying = false
				main.on_ball_returned(thrower)
				_throw()
	Redraw.later(self)


func _draw() -> void:
	if state == State.CARRIED:
		return
	var y := -arc
	# the ball's shadow separates from it as it flies, which is the only cue
	# that says airborne in a top-down view
	main.contact_shadow(self, Vector2.ZERO, 6.0 - arc * 0.05, 4.0 + arc * 0.9, 0.18)
	draw_circle(Vector2(0, y), 6.0, Color(0.82, 0.86, 0.3))
	draw_arc(Vector2(0, y), 6.0, -0.4, 1.2, 8, Color(0.95, 0.95, 0.9), 1.2)
