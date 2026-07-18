extends CharacterBody2D

# The player: Millie, a medium-sized mutt, black with salt and pepper
# thrown in. Fast, agile, responsible for the entire relationship.

const SPEED := 330.0
const ACCEL := 2400.0

var planted := false
var input_active := false
var dragged := false
var bladder_slow := false
var sand_slow := false
var swimming := false
var slick := false
var ice := false
var auto := false
var auto_move := Vector2.ZERO
# the zoomies: a reserve of energy the dog is dying to burn. Turbo spends
# it for a burst of speed; a walk should always shed some, like pee/poop.
var energy := 1.0
var turbo_active := false
const TURBO_MULT := 1.7
var tumble_t := 0.0
var hole_cd := 0.0
var squat_t := 0.0
var squat_ui := 0.0
var bark_cd := 0.0
var bark_anim := 0.0
var peeing := false
var tempted := false
var facing := Vector2.UP
var hip_dir := Vector2.DOWN
var gait := 0.0
var flecks: Array[Vector2] = []
var main: Node2D
var preview_mode := false
var preview_collar := ""
var preview_bandana := ""


func setup(m: Node2D) -> void:
	main = m


func set_cosmetic_preview(collar_key: String, bandana_key: String) -> void:
	preview_collar = collar_key
	preview_bandana = bandana_key
	queue_redraw()


func _cosmetic_collar_key() -> String:
	if preview_mode and Game.COLLARS.has(preview_collar):
		return preview_collar
	return Game.collar if Game.COLLARS.has(Game.collar) else "red"


func _cosmetic_bandana_key() -> String:
	if preview_mode and Game.BANDANAS.has(preview_bandana):
		return preview_bandana
	return Game.bandana if Game.BANDANAS.has(Game.bandana) else "none"


func _bandana_points(shoulder: Vector2, forward: Vector2) -> PackedVector2Array:
	var side := forward.orthogonal()
	var base := shoulder - forward
	return PackedVector2Array([
		base + side * 7.0,
		base - side * 7.0,
		shoulder - forward * 15.0,
	])


func _ready() -> void:
	z_index = 10
	if not preview_mode:
		collision_layer = 2
		collision_mask = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 14.0
		cs.shape = sh
		add_child(cs)
		for i in range(14):
			flecks.append(Vector2.from_angle(randf() * TAU) * randf_range(2.0, 9.5))
	else:
		var preview_rng := RandomNumberGenerator.new()
		preview_rng.seed = 1729
		for i in range(14):
			flecks.append(Vector2.from_angle(preview_rng.randf() * TAU) * preview_rng.randf_range(2.0, 9.5))


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
	var iv := auto_move if auto else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_active = iv.length() > 0.1
	planted = Input.is_action_pressed("plant") and not auto
	var answering_nature := Input.is_action_pressed("pee") and not auto
	# turbo: burn the zoomies for a burst of speed while energy lasts
	turbo_active = energy > 0.0 and input_active and (auto or Input.is_action_pressed("turbo"))
	if turbo_active:
		energy = maxf(0.0, energy - 0.28 * delta)
	if planted:
		velocity = Vector2.ZERO
	elif answering_nature:
		# stopping to go; not braced though - a yank interrupts, as in life
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	else:
		# a taut leash saps the DOG's authority: the heavier human's yanks
		# actually move you (flag set by main.gd/_apply_leash). Crucially,
		# an idle dragged dog barely brakes - braking toward zero was
		# silently cancelling the human's drag forces.
		var accel := ACCEL
		if dragged:
			accel = 1000.0 if input_active else 250.0
		if slick:
			# wet ground: less grip, more skate
			accel *= 0.45
		if ice:
			# packed snow/ice: barely any grip, momentum carries you
			accel *= 0.32
		# a full bladder waddles; sand is heavy going; water is a happy
		# dog-paddle (slower, but she would stay in all day); turbo rips
		var top := SPEED * (0.88 if bladder_slow else 1.0) * (0.8 if sand_slow else 1.0) * (0.62 if swimming else 1.0)
		if turbo_active:
			top *= TURBO_MULT
			accel = maxf(accel, 3200.0)
		velocity = velocity.move_toward(iv * top, accel * delta)
		if input_active:
			facing = iv.normalized()
	move_and_slide()
	# the hips trail the shoulders: the body hinges mid-turn
	gait += velocity.length() * delta * 0.055
	var target_hip := -facing
	hip_dir = hip_dir.slerp(target_hip, minf(10.0 * delta, 1.0))
	if hip_dir.length() < 0.1:
		hip_dir = target_hip
	else:
		hip_dir = hip_dir.normalized()
	if Input.is_action_just_pressed("bark") and bark_cd <= 0.0:
		bark_cd = 1.2
		bark_anim = 0.35
		main.on_bark(global_position)


func hit_by_rider(dir: Vector2) -> void:
	if tumble_t > 0.0:
		return
	tumble_t = 0.8
	velocity = dir * 320.0
	main.on_dog_hit()
	main.float_text(global_position, "yipe!", Color(1, 0.8, 0.6))


func fall_in(center: Vector2) -> void:
	# open holes are open holes, dogs included
	if tumble_t > 0.0 or hole_cd > 0.0:
		return
	tumble_t = 1.1
	hole_cd = 2.6
	global_position = center
	velocity = Vector2.ZERO
	main.on_dog_hit()
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
	var fur := Color(0.14, 0.13, 0.14)
	var fur_dark := Color(0.08, 0.08, 0.09)
	var grizzle := Color(0.62, 0.6, 0.58)
	var crouching := peeing or squat_t > 0.0 or squat_ui > 0.0
	var side := facing.orthogonal()
	var shoulder := facing * 6.0
	var hside := hip_dir.orthogonal()
	if swimming:
		# expanding wake rings behind her happy paddling self
		for i in range(3):
			var rr := fmod(t * 1.4 + i * 0.45, 1.35)
			draw_arc(-facing * 6.0, 12.0 + rr * 26.0, 0, TAU, 22, Color(0.82, 0.9, 1.0, 0.32 * (1.0 - rr / 1.35)), 2.0)
	# THE WIGGLE: the rump swings with the gait
	var wiggle := hside * sin(gait) * clampf(velocity.length() / SPEED, 0.0, 1.0) * 2.6
	var hip := shoulder + hip_dir * 17.0 + wiggle
	# whippy tail: three tapering segments with a traveling wave
	var wag_speed := 3.0 if crouching else 11.0
	var tp := hip + hip_dir * 4.0
	var tdir := hip_dir
	var widths: Array[float] = [3.2, 2.4, 1.7]
	for s in range(3):
		tdir = tdir.rotated(sin(t * wag_speed - s * 0.9) * (0.15 if crouching else 0.38))
		var nxt := tp + tdir * (9.0 - s * 1.5)
		draw_line(tp, nxt, fur_dark, widths[s])
		tp = nxt
	# four legs, trot gait: diagonal pairs move together, tucked when crouching
	var amp := 0.0 if crouching else clampf(velocity.length() / SPEED, 0.0, 1.0) * 5.5
	var ph := sin(gait)
	# white-tipped paws, like she stepped in paint and regrets nothing
	var paw := Color(0.78, 0.76, 0.73)
	draw_circle(shoulder + side * 7.5 + facing * (6.0 + ph * amp), 3.0, paw)
	draw_circle(shoulder - side * 7.5 + facing * (6.0 - ph * amp), 3.0, paw)
	var rear_reach := 1.0 if crouching else 4.0
	draw_circle(hip + hside * 7.0 - hip_dir * (rear_reach - ph * amp * 0.8), 3.2, paw)
	draw_circle(hip - hside * 7.0 - hip_dir * (rear_reach + ph * amp * 0.8), 3.2, paw)
	# lean street-dog torso, hinged; the rump drops into the squat
	draw_line(shoulder, hip, fur, 13.0)
	draw_circle(hip, 10.5 if crouching else 9.0, fur)
	draw_circle(shoulder, 8.5, fur)
	# only a few subtle flecks on the body - the grey lives on the head
	for i in range(6):
		var base := hip if i % 2 == 0 else shoulder
		draw_circle(base + flecks[i], 1.0, Color(grizzle, 0.22))
	# the Julius K9 harness across the shoulders, and the collar - colour
	# set by the equipped cosmetic (rainbow shimmers)
	var collar_key := _cosmetic_collar_key()
	var col: Color = Game.COLLARS[collar_key].col
	if collar_key == "rainbow":
		col = Color.from_hsv(fmod(t * 0.35, 1.0), 0.7, 0.9)
	var bandana_key := _cosmetic_bandana_key()
	if bandana_key != "none":
		var bcol: Color = Game.BANDANAS[bandana_key].col
		var bandana := _bandana_points(shoulder, facing)
		var edge := bcol.darkened(0.35)
		draw_colored_polygon(bandana, bcol)
		draw_line(bandana[0], bandana[1], edge, 1.5)
		draw_line(bandana[1], bandana[2], edge, 1.5)
		draw_line(bandana[2], bandana[0], edge, 1.5)
	draw_line(shoulder + side * 8.0, shoulder - side * 8.0, col, 6.0)
	draw_circle(shoulder, 2.2, Color(0.3, 0.3, 0.32))
	var neck := shoulder + facing * 6.5
	draw_line(neck + side * 5.5, neck - side * 5.5, col, 3.0)
	# head with a LONG street-dog nose; grey on the crown and the face
	var head := shoulder + facing * 10.0
	draw_circle(head, 7.0, fur)
	draw_line(head, head + facing * 10.0, fur, 5.5)
	draw_circle(head + facing * 2.0, 4.0, Color(grizzle, 0.45))
	draw_line(head + facing * 3.0, head + facing * 9.0, Color(grizzle, 0.5), 3.0)
	draw_circle(head - facing * 2.5, 3.2, Color(grizzle, 0.3))
	draw_circle(head + facing * 11.0, 2.4, Color(0.05, 0.05, 0.06))
	# big floppy ears, swinging slightly with the stride
	var flop := sin(gait) * 1.6
	draw_line(head + side * 4.0, head + side * 9.5 - facing * 3.5 + side * flop, fur_dark, 5.5)
	draw_line(head - side * 4.0, head - side * 9.5 - facing * 3.5 - side * flop, fur_dark, 5.5)
	if peeing:
		for i in range(2):
			var a := t * 5.0 + i * 2.4
			draw_circle(hip + hip_dir * 10.0 + hside * sin(a) * 3.0, 1.6, Color(0.93, 0.85, 0.4, 0.5))
	if planted and not crouching:
		for i in range(4):
			var a2 := TAU * i / 4.0 + 0.4
			var p := Vector2.from_angle(a2) * 19.0
			draw_line(p, p + Vector2.from_angle(a2) * 6.0, Color(0.3, 0.25, 0.2), 3.0)
	if tempted and tumble_t <= 0.0:
		draw_line(Vector2(15, -30), Vector2(15, -22), Color(0.95, 0.62, 0.55), 3.0)
		draw_circle(Vector2(15, -18), 2.0, Color(0.95, 0.62, 0.55))
	if bark_anim > 0.0:
		var r := (0.35 - bark_anim) / 0.35
		draw_arc(head + facing * 8.0, 10.0 + r * 34.0, 0, TAU, 24, Color(1, 1, 1, 0.7 * (1.0 - r)), 2.0)
	if squat_ui > 0.0 or squat_t > 0.0:
		for i in range(3):
			draw_circle(Vector2(-8 + i * 8, -26), 2.0, Color(1, 1, 1, 0.7))
		if squat_ui > 0.0:
			draw_arc(Vector2.ZERO, 20.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(squat_ui, 0.0, 1.0), 20, Color(1, 0.95, 0.7), 3.0)
	if swimming:
		# waterline over the hindquarters and little paddle splashes up front
		draw_circle(hip, 11.0, Color(0.42, 0.56, 0.66, 0.5))
		draw_circle(shoulder + facing * 2.0, 9.0, Color(0.42, 0.56, 0.66, 0.32))
		draw_circle(head + facing * 12.0 + side * sin(t * 18.0) * 4.0, 2.2, Color(0.9, 0.95, 1.0, 0.8))
		draw_circle(head + facing * 12.0 - side * sin(t * 18.0) * 4.0, 1.8, Color(0.9, 0.95, 1.0, 0.6))
