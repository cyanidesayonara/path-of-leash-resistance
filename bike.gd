extends Node2D

# A rider. Crossing bikes at intersections, bike-lane commuters, and
# wobbly kids on scooters all share this script. Art faces +x and the
# node rotates to the direction of travel.
# Commuters knock the human flat (phone risk); kids just bump ("sorry!").

var vel := Vector2.ZERO
var kind := "bike"  # "bike" | "kid"
var main: Node2D
var dog: Node2D
var human: Node2D
var min_dist := 9999.0
var hit_done := false
var tint := Color(0.4, 0.5, 0.45)
var band_lo := 0.0
var band_hi := 0.0
var base_x := 0.0
var wob_seed := 0.0
var swerve_t := 0.0


func setup(m: Node2D, d: Node2D, h: Node2D, v: Vector2, k: String) -> void:
	add_to_group("bikes")
	main = m
	dog = d
	human = h
	vel = v
	kind = k
	rotation = vel.angle()
	wob_seed = randf() * 10.0
	if kind == "kid":
		tint = [Color(0.75, 0.55, 0.3), Color(0.5, 0.62, 0.5), Color(0.65, 0.5, 0.62)][randi() % 3]
	else:
		tint = [Color(0.42, 0.5, 0.46), Color(0.55, 0.42, 0.4), Color(0.42, 0.44, 0.56)][randi() % 3]


func lane_keep(lo: float, hi: float) -> void:
	# kids weave inside a band instead of holding a line
	band_lo = lo
	band_hi = hi
	base_x = position.x
	swerve_t = randf_range(1.2, 2.8)


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	if kind == "kid" and band_hi > band_lo:
		swerve_t -= delta
		if swerve_t <= 0.0:
			swerve_t = randf_range(1.2, 2.8)
			base_x = clampf(base_x + randf_range(-70.0, 70.0), band_lo, band_hi)
		var t := Time.get_ticks_msec() / 1000.0
		var target_x := base_x + sin(t * 2.4 + wob_seed) * 24.0
		vel.x = clampf((target_x - position.x) * 3.0, -85.0, 85.0)
		rotation = vel.angle()
	# nobody, not even a wobbly kid, rides into an open manhole
	if absf(vel.y) > absf(vel.x):
		for m in main.manholes:
			var ahead: float = (m.y - global_position.y) * signf(vel.y)
			if ahead > 0.0 and ahead < 90.0 and absf(m.x - global_position.x) < 34.0:
				position.x += signf(global_position.x - m.x + 0.001) * 95.0 * delta
	position += vel * delta
	var hp: Vector2 = human.global_position
	var dh := global_position.distance_to(hp)
	min_dist = minf(min_dist, dh)
	if not hit_done and dh < 38.0:
		if kind == "bike":
			if human.fall("rider"):
				hit_done = true
		else:
			hit_done = true
			human.bumped((hp - global_position).normalized())
			main.float_text(global_position, "sorry!", Color(1, 1, 1, 0.9))
	if global_position.distance_to(dog.global_position) < 32.0:
		dog.hit_by_rider(vel.normalized())
	var gone_x := global_position.x < -320.0 or global_position.x > 1600.0
	var gone_y := absf(global_position.y - float(main.cam.position.y)) > 1150.0
	if gone_x or gone_y:
		if not hit_done and kind == "bike" and min_dist < 80.0:
			main.close_call(human.global_position)
		queue_free()
	queue_redraw()


func _draw() -> void:
	if kind == "bike":
		var wheel := Color(0.15, 0.15, 0.17)
		draw_circle(Vector2(-18, 0), 8.0, wheel)
		draw_circle(Vector2(18, 0), 8.0, wheel)
		draw_line(Vector2(-18, 0), Vector2(18, 0), tint.darkened(0.3), 4.0)
		draw_circle(Vector2.ZERO, 10.0, tint)
		draw_circle(Vector2(6, 0), 6.0, Color(0.85, 0.72, 0.58))
		draw_arc(Vector2(6, 0), 6.5, PI * 0.5, PI * 1.5, 10, Color(0.8, 0.3, 0.25), 3.0)
		for i in range(3):
			var x := -(30.0 + i * 11.0)
			draw_line(Vector2(x, -4 + i * 4), Vector2(x - 8.0, -4 + i * 4), Color(1, 1, 1, 0.25), 2.0)
	else:
		draw_rect(Rect2(-11, -3, 22, 6), tint.darkened(0.25))
		draw_circle(Vector2(-12, 0), 3.5, Color(0.15, 0.15, 0.17))
		draw_circle(Vector2(12, 0), 3.5, Color(0.15, 0.15, 0.17))
		draw_circle(Vector2.ZERO, 7.0, tint)
		draw_circle(Vector2(4, 0), 5.0, Color(0.85, 0.72, 0.58))
		draw_arc(Vector2(4, 0), 5.5, PI * 0.5, PI * 1.5, 8, Color(0.95, 0.85, 0.3), 2.5)
