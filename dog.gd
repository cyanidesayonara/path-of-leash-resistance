extends CharacterBody2D

# The player. Fast, agile, responsible for the entire relationship.

const SPEED := 330.0
const ACCEL := 2400.0

var planted := false
var input_active := false
var dragged := false
var bladder_slow := false
var tumble_t := 0.0
var hole_cd := 0.0
var squat_t := 0.0
var squat_ui := 0.0
var bark_cd := 0.0
var bark_anim := 0.0
var facing := Vector2.UP
var main: Node2D


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	z_index = 10
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 14.0
	cs.shape = sh
	add_child(cs)


func tick(delta: float) -> void:
	bark_cd = maxf(0.0, bark_cd - delta)
	bark_anim = maxf(0.0, bark_anim - delta)
	hole_cd = maxf(0.0, hole_cd - delta)
	if squat_t > 0.0:
		# answering nature's call: immobile and braced, come what may
		squat_t -= delta
		planted = true
		input_active = false
		velocity = Vector2.ZERO
		return
	if tumble_t > 0.0:
		tumble_t -= delta
		planted = false
		input_active = false
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		rotation += 13.0 * delta
		if tumble_t <= 0.0:
			rotation = 0.0
		return
	var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_active = iv.length() > 0.1
	planted = Input.is_action_pressed("plant")
	if planted:
		velocity = Vector2.ZERO
	else:
		# a taut leash saps the DOG's authority: the heavier human's yanks
		# actually move you (flag set by main.gd/_apply_leash). Crucially,
		# an idle dragged dog barely brakes - braking toward zero was
		# silently cancelling the human's drag forces.
		var accel := ACCEL
		if dragged:
			accel = 1000.0 if input_active else 250.0
		# a full bladder waddles
		var top := SPEED * (0.88 if bladder_slow else 1.0)
		velocity = velocity.move_toward(iv * top, accel * delta)
		if input_active:
			facing = iv.normalized()
	move_and_slide()
	if Input.is_action_just_pressed("bark") and bark_cd <= 0.0:
		bark_cd = 1.2
		bark_anim = 0.35
		main.on_bark(global_position)


func hit_by_bike(dir: int) -> void:
	if tumble_t > 0.0:
		return
	tumble_t = 0.8
	velocity = Vector2(dir * 320.0, 0)
	main.float_text(global_position, "yipe!", Color(1, 0.8, 0.6))


func fall_in(center: Vector2) -> void:
	# open holes are open holes, dogs included
	if tumble_t > 0.0 or hole_cd > 0.0:
		return
	tumble_t = 1.1
	hole_cd = 2.6
	global_position = center
	velocity = Vector2.ZERO
	main.float_text(center, "oof", Color(1, 0.85, 0.6))


func forced_squat(duration: float) -> void:
	squat_t = duration
	velocity = Vector2.ZERO


func is_tumbling() -> bool:
	return tumble_t > 0.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var body := Color(0.55, 0.36, 0.2)
	var dark := Color(0.42, 0.27, 0.15)
	var wag := sin(t * 10.0) * 0.6
	var tail_dir := (-facing).rotated(wag)
	draw_line(Vector2.ZERO, tail_dir * 22.0, dark, 4.0)
	draw_circle(Vector2.ZERO, 14.0, body)
	var head_pos := facing * 12.0
	draw_circle(head_pos, 9.0, body)
	var side := facing.orthogonal()
	draw_circle(head_pos + side * 7.0, 4.0, dark)
	draw_circle(head_pos - side * 7.0, 4.0, dark)
	draw_circle(head_pos + facing * 7.0, 3.0, Color(0.15, 0.1, 0.08))
	if planted:
		for i in range(4):
			var a := TAU * i / 4.0 + 0.4
			var p := Vector2.from_angle(a) * 19.0
			draw_line(p, p + Vector2.from_angle(a) * 6.0, Color(0.3, 0.25, 0.2), 3.0)
	if bark_anim > 0.0:
		var r := (0.35 - bark_anim) / 0.35
		draw_arc(head_pos + facing * 10.0, 10.0 + r * 34.0, 0, TAU, 24, Color(1, 1, 1, 0.7 * (1.0 - r)), 2.0)
	if squat_ui > 0.0 or squat_t > 0.0:
		for i in range(3):
			draw_circle(Vector2(-8 + i * 8, -26), 2.0, Color(1, 1, 1, 0.7))
		if squat_ui > 0.0:
			draw_arc(Vector2.ZERO, 20.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(squat_ui, 0.0, 1.0), 20, Color(1, 0.95, 0.7), 3.0)
