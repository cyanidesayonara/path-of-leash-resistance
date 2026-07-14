extends Node2D

# A tennis ball for the off-leash fetch challenge. It bounces off to a
# new spot, the dog chases and touches it to "catch", and it launches
# again. Purely the freedom-romp toy; main.gd counts the catches.

var main: Node2D
var dog: Node2D
var vel := Vector2.ZERO
var lo := 0.0
var hi := 0.0
var caught_cd := 0.0
var bob := 0.0


func setup(m: Node2D, d: Node2D, y_lo: float, y_hi: float) -> void:
	main = m
	dog = d
	lo = y_lo
	hi = y_hi
	_launch(Vector2(randf_range(120.0, 1160.0), (y_lo + y_hi) / 2.0))


func _launch(toward: Vector2) -> void:
	vel = (toward - global_position).normalized() * randf_range(280.0, 420.0)


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	bob += delta
	caught_cd = maxf(0.0, caught_cd - delta)
	position += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 240.0 * delta)
	# keep it in the freedom yard
	if position.x < 90.0 or position.x > 1190.0:
		vel.x = -vel.x
	if position.y < lo or position.y > hi:
		vel.y = -vel.y
	position.x = clampf(position.x, 90.0, 1190.0)
	position.y = clampf(position.y, lo, hi)
	if vel.length() < 20.0:
		# sitting still - dog can grab it and it hops away again
		if global_position.distance_to(dog.global_position) < 20.0 and caught_cd <= 0.0:
			caught_cd = 0.4
			main.on_ball_caught()
			_launch(Vector2(randf_range(120.0, 1160.0), randf_range(lo, hi)))
	queue_redraw()


func _draw() -> void:
	var b := sin(bob * 8.0) * 2.0 if vel.length() > 20.0 else 0.0
	draw_circle(Vector2(2, 4), 6.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2(0, b), 6.0, Color(0.82, 0.86, 0.3))
	draw_arc(Vector2(0, b), 6.0, -0.4, 1.2, 8, Color(0.95, 0.95, 0.9), 1.2)
