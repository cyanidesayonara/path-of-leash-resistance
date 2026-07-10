extends Node2D

# A cyclist. Does not brake. Has never braked.

var speed := 560.0
var dir := 1
var main: Node2D
var dog: Node2D
var human: Node2D
var min_dist := 9999.0
var hit_done := false
var tint := Color(0.4, 0.5, 0.45)


func setup(m: Node2D, d: Node2D, h: Node2D, direction: int) -> void:
	add_to_group("bikes")
	main = m
	dog = d
	human = h
	dir = direction
	speed = randf_range(480.0, 640.0)
	tint = [Color(0.42, 0.5, 0.46), Color(0.55, 0.42, 0.4), Color(0.42, 0.44, 0.56)][randi() % 3]


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	position.x += dir * speed * delta
	var hp: Vector2 = human.global_position
	min_dist = minf(min_dist, global_position.distance_to(hp))
	if not hit_done and absf(hp.x - global_position.x) < 48.0 and absf(hp.y - global_position.y) < 30.0:
		if human.fall("bike"):
			hit_done = true
	var dp: Vector2 = dog.global_position
	if absf(dp.x - global_position.x) < 44.0 and absf(dp.y - global_position.y) < 26.0:
		dog.hit_by_bike(dir)
	if global_position.x < -320.0 or global_position.x > 1600.0:
		if not hit_done and min_dist < 80.0:
			main.close_call(human.global_position)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var wheel := Color(0.15, 0.15, 0.17)
	draw_circle(Vector2(-20, 8), 9.0, wheel)
	draw_circle(Vector2(20, 8), 9.0, wheel)
	draw_line(Vector2(-20, 8), Vector2(20, 8), tint.darkened(0.3), 4.0)
	draw_circle(Vector2(0, -4), 10.0, tint)
	draw_circle(Vector2(dir * 6, -10), 6.0, Color(0.85, 0.72, 0.58))
	draw_arc(Vector2(dir * 6, -10), 6.5, PI, TAU, 10, Color(0.8, 0.3, 0.25), 3.0)
	for i in range(3):
		var x := -dir * (34.0 + i * 12.0)
		draw_line(Vector2(x, -2 + i * 4), Vector2(x - dir * 8.0, -2 + i * 4), Color(1, 1, 1, 0.25), 2.0)
