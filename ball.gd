extends Node2D

# A tennis ball for real fetch: the owner THROWS it out, the dog runs to
# it, carries it in their mouth, and brings it back to the thrower. A
# delivered ball scores and gets thrown again. main.gd counts returns.

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


func setup(m: Node2D, d: Node2D, thrower_node: Node2D, y_lo: float, y_hi: float) -> void:
	main = m
	dog = d
	thrower = thrower_node
	lo = y_lo
	hi = y_hi
	_throw()


func is_carried() -> bool:
	return state == State.CARRIED


func _throw() -> void:
	state = State.THROWN
	global_position = thrower.global_position
	var target := Vector2(randf_range(180.0, 1100.0), randf_range(lo + 40.0, hi - 40.0))
	vel = (target - global_position).normalized() * randf_range(340.0, 460.0)
	if thrower == main.human:
		main.human.throw_pose()


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	bob += delta
	match state:
		State.THROWN:
			position += vel * delta
			vel = vel.move_toward(Vector2.ZERO, 300.0 * delta)
			arc = clampf(vel.length() / 60.0, 0.0, 10.0)
			if position.x < 100.0 or position.x > 1180.0:
				vel.x = -absf(vel.x) * signf(590.0 - position.x)
			position.y = clampf(position.y, lo, hi)
			if vel.length() < 26.0:
				state = State.RESTING
				rest_t = 0.0
		State.RESTING:
			arc = 0.0
			rest_t += delta
			if global_position.distance_to(dog.global_position) < 22.0:
				state = State.CARRIED
				main.on_ball_grabbed()
		State.CARRIED:
			# ride at the dog's mouth
			global_position = dog.global_position + dog.facing * 13.0
			if global_position.distance_to(thrower.global_position) < 42.0:
				main.on_ball_returned(thrower)
				_throw()
	queue_redraw()


func _draw() -> void:
	var y := -arc
	draw_circle(Vector2(2, 4), 6.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2(0, y), 6.0, Color(0.82, 0.86, 0.3))
	draw_arc(Vector2(0, y), 6.0, -0.4, 1.2, 8, Color(0.95, 0.95, 0.9), 1.2)
