extends Node2D

# An off-leash dog in the freedom area: no owner, no leash, all zoomies.
# Wanders, play-bows, and is delighted to be greeted (once).

var main: Node2D
var my_dog: Node2D
var vel := Vector2.ZERO
var wander_t := 0.0
var seed_o := 0.0
var col := Color(0.6, 0.5, 0.4)
var lo := 0.0
var hi := 0.0
var bow := 0.0


func setup(m: Node2D, mine: Node2D, y_lo: float, y_hi: float) -> void:
	add_to_group("freedogs")
	main = m
	my_dog = mine
	lo = y_lo
	hi = y_hi
	seed_o = randf() * 10.0
	col = [Color(0.65, 0.52, 0.36), Color(0.8, 0.78, 0.74), Color(0.32, 0.28, 0.26), Color(0.7, 0.62, 0.45)][randi() % 4]


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(0.5, 1.5)
		# mostly mill about; sometimes bolt after your dog to play
		if randf() < 0.4 and my_dog.global_position.distance_to(global_position) < 300.0:
			vel = (my_dog.global_position - global_position).normalized() * 150.0
		else:
			vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 110.0
	bow += delta
	position += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 120.0 * delta)
	position.x = clampf(position.x, 90.0, 1190.0)
	position.y = clampf(position.y, lo, hi)
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# a wagging tail and a happy little play-bow bob
	var b := sin(bow * 6.0 + seed_o) * 1.5
	draw_line(Vector2(-8, b), Vector2(-15, -6 + sin(t * 12.0 + seed_o) * 4.0), col.darkened(0.2), 3.0)
	draw_circle(Vector2(0, b), 8.0, col)
	var face := (my_dog.global_position - global_position).normalized()
	draw_circle(face * 8.0 + Vector2(0, b), 5.5, col)
	draw_circle(face * 11.0 + Vector2(0, b), 1.6, Color(0.1, 0.09, 0.08))
	# little ears
	draw_line(face * 6.0 + Vector2(-3, b - 4), face * 4.0 + Vector2(-5, b - 9), col.darkened(0.25), 3.0)
	draw_line(face * 6.0 + Vector2(3, b - 4), face * 4.0 + Vector2(5, b - 9), col.darkened(0.25), 3.0)
