extends Node2D

# A traffic cone. Exists to be kicked. Dog, human, and riders all send
# it skittering; it spins, slides, and settles wherever physics leaves
# it, because nobody in history has ever put a cone back.

var main: Node2D
var dog: Node2D
var human: Node2D
var vel := Vector2.ZERO
var spin := 0.0


func setup(m: Node2D, d: Node2D, h: Node2D) -> void:
	add_to_group("cones")
	main = m
	dog = d
	human = h
	rotation = randf() * TAU


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	_kick_by(dog.global_position, dog.velocity, 24.0)
	_kick_by(human.global_position, human.velocity, 26.0)
	for b in main.riders_cache:
		_kick_by(b.global_position, b.vel, 28.0)
	if vel.length_squared() > 1.0:
		position += vel * delta
		vel = vel.move_toward(Vector2.ZERO, 300.0 * delta)
		rotation += spin * delta
		spin = move_toward(spin, 0.0, 6.0 * delta)
		# a cone punted into a hole is gone, and it is glorious
		for m in main.manholes:
			if global_position.distance_to(m) < 16.0:
				main.float_text(global_position, "plop", Color(0.8, 0.85, 0.9))
				queue_free()
				return
		for c in main.cellars:
			if (c as Rect2).has_point(global_position):
				main.float_text(global_position, "plop", Color(0.8, 0.85, 0.9))
				queue_free()
				return
		if main.pond.size.x > 0.0 and (main.pond as Rect2).has_point(global_position):
			main.float_text(global_position, "ploosh", Color(0.6, 0.8, 1.0))
			queue_free()
			return
		queue_redraw()


func _kick_by(p: Vector2, v: Vector2, r: float) -> void:
	var d := global_position - p
	var l := d.length()
	if l < r and l > 0.001:
		vel = d / l * maxf(v.length() * 0.7, 90.0)
		spin = randf_range(-8.0, 8.0)


func _draw() -> void:
	draw_rect(Rect2(-9, -9, 18, 18), Color(0.9, 0.5, 0.18, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0.92, 0.5, 0.16))
	draw_arc(Vector2.ZERO, 5.8, 0, TAU, 12, Color(0.95, 0.92, 0.85), 2.6)
	draw_circle(Vector2.ZERO, 2.2, Color(0.98, 0.6, 0.22))
