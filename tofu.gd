extends Node2D

# The "bring Tofu home" quest. Tofu the cat has escaped again (she does
# this in real life) and turns up loose on the walk home. You cannot grab
# her - she keeps her skittish distance - so you HERD her: get close and
# she bolts to the next hiding spot further south, and you press her along
# spot by spot until she is all the way home.

const FLEE_R := 145.0
const DART_SPEED := 330.0

var main: Node2D
var my_dog: Node2D
var spots: Array[Vector2] = []  # ordered north -> south, home last
var idx := 0
var darting := false
var home := false
var seed_o := 0.0
var alert_t := 0.0


func setup(m: Node2D, mine: Node2D, hide_spots: Array[Vector2]) -> void:
	add_to_group("tofu")
	main = m
	my_dog = mine
	spots = hide_spots
	seed_o = randf() * 10.0
	if spots.size() > 0:
		global_position = spots[0]


func _physics_process(delta: float) -> void:
	if main.frozen or home or spots.is_empty():
		return
	alert_t = maxf(0.0, alert_t - delta)
	if darting:
		var target: Vector2 = spots[idx]
		global_position = global_position.move_toward(target, DART_SPEED * delta)
		if global_position.distance_to(target) < 4.0:
			darting = false
			if idx >= spots.size() - 1:
				home = true
				main.on_tofu_home(global_position)
	else:
		# hiding: bolt to the next spot south when the dog closes in
		if my_dog.global_position.distance_to(global_position) < FLEE_R:
			alert_t = 0.4
			if idx < spots.size() - 1:
				idx += 1
				darting = true
			else:
				home = true
				main.on_tofu_home(global_position)
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var white := Color(0.93, 0.91, 0.88)
	var brown := Color(0.62, 0.45, 0.28)
	var wag := sin(t * (2.0 if home else (10.0 if darting else 5.0)) + seed_o) * (0.2 if home else 0.45)
	draw_line(Vector2(-6, 0), Vector2(-6, 0) + Vector2(-10, -7).rotated(wag), brown, 2.5)
	draw_circle(Vector2.ZERO, 6.5, white)
	draw_circle(Vector2(-1, -2), 4.0, brown)
	draw_circle(Vector2(5, -3), 4.0, white)
	draw_circle(Vector2(6, -5), 2.2, brown)
	draw_line(Vector2(3, -6), Vector2(2, -9), brown, 2.0)
	draw_line(Vector2(7, -6), Vector2(8, -9), brown, 2.0)
	draw_line(Vector2(1, 0), Vector2(7, 0), Color(0.9, 0.45, 0.62), 2.0)
	draw_circle(Vector2(6, -3), 1.0, Color(0.75, 0.9, 0.3))
	if home:
		for i in range(2):
			var a := t * 2.0 + i * 3.0
			draw_circle(Vector2(0, -12) + Vector2.from_angle(a) * 8.0, 2.0, Color(0.95, 0.5, 0.6, 0.8))
	elif alert_t > 0.0 or darting:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.5))
