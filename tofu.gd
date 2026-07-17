extends Node2D

# The "bring Tofu home" quest. Tofu the cat has escaped again (she does
# this in real life). She turns up lost in the off-leash area. You cannot
# grab her - she keeps her skittish distance - so you HERD her: get close
# and she darts away, and you use that to push her onto her mat by the
# owner's bench. Corner her there and she gives up and comes home.

const FLEE_R := 135.0
const FLEE_SPEED := 240.0
const MAT_R := 40.0
const SETTLE_TIME := 1.4

var main: Node2D
var my_dog: Node2D
var mat: Vector2
var bounds: Rect2
var settle := 0.0
var home := false
var wander := Vector2.ZERO
var wander_t := 0.0
var seed_o := 0.0
var bubble_t := 0.0


func setup(m: Node2D, mine: Node2D, mat_pos: Vector2, park_bounds: Rect2) -> void:
	add_to_group("tofu")
	main = m
	my_dog = mine
	mat = mat_pos
	bounds = park_bounds
	seed_o = randf() * 10.0


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	if home:
		return
	var to_mat := global_position.distance_to(mat)
	if to_mat < MAT_R:
		# cornered on her mat: she gives up and settles home
		settle += delta
		bubble_t = 0.3
		if settle >= SETTLE_TIME:
			home = true
			main.on_tofu_home(global_position)
		queue_redraw()
		return
	settle = maxf(0.0, settle - delta * 1.5)
	var dd := global_position.distance_to(my_dog.global_position)
	if dd < FLEE_R and dd > 0.1:
		# skitter away from the dog (this is the herding lever)
		var away := (global_position - my_dog.global_position).normalized()
		global_position += away * FLEE_SPEED * delta * clampf(1.0 - dd / FLEE_R, 0.3, 1.0)
		bubble_t = 0.3
	else:
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(0.7, 1.8)
			wander = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 26.0
		global_position += wander * delta
	bubble_t = maxf(0.0, bubble_t - delta)
	global_position.x = clampf(global_position.x, bounds.position.x + 12.0, bounds.end.x - 12.0)
	global_position.y = clampf(global_position.y, bounds.position.y + 12.0, bounds.end.y - 12.0)
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var white := Color(0.93, 0.91, 0.88)
	var brown := Color(0.62, 0.45, 0.28)
	# Tofu: white with brown on top, pink harness, alert tail
	var tail_wag := sin(t * (2.0 if home else 8.0) + seed_o) * (0.2 if home else 0.4)
	draw_line(Vector2(-6, 0), Vector2(-6, 0) + Vector2(-10, -7).rotated(tail_wag), brown, 2.5)
	draw_circle(Vector2.ZERO, 6.5, white)
	draw_circle(Vector2(-1, -2), 4.0, brown)
	draw_circle(Vector2(5, -3), 4.0, white)
	draw_circle(Vector2(6, -5), 2.2, brown)
	draw_line(Vector2(3, -6), Vector2(2, -9), brown, 2.0)
	draw_line(Vector2(7, -6), Vector2(8, -9), brown, 2.0)
	draw_line(Vector2(1, 0), Vector2(7, 0), Color(0.9, 0.45, 0.62), 2.0)
	draw_circle(Vector2(6, -3), 1.0, Color(0.75, 0.9, 0.3))
	if home:
		# content: purring hearts
		for i in range(2):
			var a := t * 2.0 + i * 3.0
			draw_circle(Vector2(0, -12) + Vector2.from_angle(a) * 8.0, 2.0, Color(0.95, 0.5, 0.6, 0.8))
	elif bubble_t > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-8, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.5))
