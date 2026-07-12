extends Node2D

# A pigeon. Waddles around minding its own business until someone gets
# close, then the whole flock scatters. Pure distraction; scattering a
# flock is its own reward.

var main: Node2D
var dog: Node2D
var human: Node2D
var flying := false
var fly_dir := Vector2.UP
var wander_t := 0.0
var seed_o := 0.0


func setup(m: Node2D, d: Node2D, h: Node2D) -> void:
	add_to_group("pigeons")
	main = m
	dog = d
	human = h
	seed_o = randf() * 10.0


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	if flying:
		position += fly_dir * 430.0 * delta
		if absf(global_position.y - float(main.cam.position.y)) > 700.0:
			queue_free()
	else:
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(0.5, 1.4)
			position += Vector2(randf_range(-9.0, 9.0), randf_range(-9.0, 9.0))
		var threat := minf(
			global_position.distance_to(dog.global_position),
			global_position.distance_to(human.global_position))
		if threat < 70.0:
			scare()
		else:
			# traffic scatters pigeons too
			for b in get_tree().get_nodes_in_group("bikes"):
				if global_position.distance_to(b.global_position) < 90.0:
					scare()
					break
	queue_redraw()


func scare() -> void:
	if flying:
		return
	flying = true
	fly_dir = (global_position - dog.global_position).normalized().rotated(randf_range(-0.5, 0.5))


func _draw() -> void:
	var grey := Color(0.55, 0.56, 0.6)
	draw_circle(Vector2.ZERO, 4.0, grey)
	draw_circle(Vector2(3, -2), 2.2, grey.darkened(0.15))
	draw_circle(Vector2(4.6, -2), 0.8, Color(0.9, 0.6, 0.2))
	if flying:
		var t := Time.get_ticks_msec() / 1000.0
		var flap := sin(t * 24.0 + seed_o) * 4.0
		draw_line(Vector2(-2, 0), Vector2(-6, -3 - flap), grey.darkened(0.1), 2.0)
		draw_line(Vector2(2, 0), Vector2(6, -3 - flap), grey.darkened(0.1), 2.0)
