extends CharacterBody2D

# The player: Millie, a medium-sized mutt, black with salt and pepper
# thrown in. Fast, agile, responsible for the entire relationship.

const SPEED := 330.0
const ACCEL := 2400.0
const Surfaces := preload("res://world/surfaces.gd")

var planted := false
# dug in and being hauled anyway: set by main when the leash drags a planted
# dog along, 1.0 on the frame it happens and fading; skid_dir is which way
var skid := 0.0
var skid_dir := Vector2.ZERO
var input_active := false
var dragged := false
# how hard the taut leash has her, 0..1 (the leash's taut amount), set by
# main.gd with `dragged`: control authority eases out with it, not at once
var drag_amt := 0.0
var bladder_slow := false
var sand_slow := false
var swimming := false
# what she is standing on right now, as a Surfaces.S value. Set by main
# each tick from surface_at(); the table in surfaces.gd says what it means.
var surface := Surfaces.S.PAVEMENT
var slick := false
# set by main while she is wading in the flood. One sideways scale inside
# the tick; a multiply on velocity every frame compounded into a crawl.
var flooded := false
const FLOOD_STEER := 0.55
var ice := false
var auto := false
var auto_move := Vector2.ZERO
# the zoomies: a reserve of energy the dog is dying to burn. Turbo spends
# it for a burst of speed; a walk should always shed some, like pee/poop.
var energy := 1.0
# set by main each tick from mood.gd: a mood changes how she handles, not just
# how the screen looks, and the handling is meant to land first. 1.0 is an
# ordinary unbothered dog; wobble is a veer in radians the zoomies add on top
# of wherever the player actually pointed.
var mood_speed := 1.0
var mood_accel := 1.0
var mood_wobble := 0.0
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
# Draw-only motion for terminal beats. Gameplay position and rotation stay
# authoritative; the leash receives the same world offset separately.
var presentation_offset := Vector2.ZERO
var presentation_rotation := 0.0
# a cutscene's walking speed (systems/arrival.gd); velocity is zero then
var presentation_speed := 0.0
var flecks: Array[Vector2] = []
var main: Node2D
var preview_mode := false
var preview_collar := ""
var preview_bandana := ""
var preview_coat := ""
# the raw movement input, so main can tell how hard she is scrambling away
# from a brink during a teeter
var input_dir := Vector2.ZERO
# a jump's height (the agility course's jumps): looks only, the body is drawn
# that far up over a shadow that stays on the ground
var hop := 0.0
var prev_hop := 0.0
var land_squash_t := 0.0
var launch_stretch_dir := Vector2.ZERO
var launch_stretch_t := 0.0
# While set (not zero) she faces this way whatever the stick says: in the rope
# tug she faces the toy, so pulling away from it is backing up, rump first.
var face_lock := Vector2.ZERO
# how braced she is, 0..1, easing in while face_lock holds: front paws
# planted out ahead, back paws spread
var brace := 0.0
const BRACE_RATE := 4.0
# live dog actions (0..1), eased by main while she digs, sniffs, or drinks
var digging := 0.0
var sniffing := 0.0
var drinking := 0.0


func base_speed() -> float:
	return SPEED * (Game.dog_speed_mult() if Game != null else 1.0)


func base_accel() -> float:
	return ACCEL * (Game.dog_accel_mult() if Game != null else 1.0)


func plant_grip_mult() -> float:
	return Game.dog_plant_mult() if Game != null else 1.0


func _dog_key() -> String:
	return Game.dog if Game != null else "millie"


func _dog_breed() -> String:
	return Game.dog_breed(_dog_key()) if Game != null else "mongrel"


func setup(m: Node2D) -> void:
	main = m


func set_cosmetic_preview(collar_key: String, bandana_key: String, coat_key := "") -> void:
	preview_collar = collar_key
	preview_bandana = bandana_key
	preview_coat = coat_key
	queue_redraw()


func _coat_data() -> Dictionary:
	# in the wardrobe the highlighted coat shows on the preview dog before
	# you have bought it; in the world it is always the equipped one
	if preview_mode and Game.COATS.has(preview_coat):
		return Game.COATS[preview_coat]
	return Game.coat_data()


func _cosmetic_collar_key() -> String:
	if preview_mode and Game.COLLARS.has(preview_collar):
		return preview_collar
	return Game.collar if Game.COLLARS.has(Game.collar) else "red"


func _cosmetic_bandana_key() -> String:
	if preview_mode and Game.BANDANAS.has(preview_bandana):
		return preview_bandana
	return Game.bandana if Game.BANDANAS.has(Game.bandana) else "none"


func get_ear_dynamics() -> Dictionary:
	var t := AnimClock.msec() / 1000.0
	var spd := _draw_speed()
	var speed_ratio := clampf(spd / base_speed(), 0.0, 1.8)
	var turbo_f := 1.0 if turbo_active else 0.0
	var wind_trail := speed_ratio * 3.2 + turbo_f * 2.6
	var flutter := sin(t * 34.0) * (0.6 * speed_ratio + 1.4 * turbo_f)
	var target_hip := -facing
	var turn_lag := (-facing).cross(hip_dir)
	var centrifugal_sway := clampf(turn_lag * 6.0, -2.8, 2.8)
	var crouching := peeing or squat_t > 0.0 or squat_ui > 0.0
	var twitch := 0.0
	var twitch_side := 1.0
	if spd < 5.0 and not crouching:
		var idle_cycle := fmod(t + 0.4, 4.2)
		if idle_cycle < 0.22:
			twitch = sin(idle_cycle / 0.22 * TAU) * 1.8
			twitch_side = -1.0 if fmod(t, 8.4) < 4.2 else 1.0
	return {
		"speed_ratio": speed_ratio,
		"wind_trail": wind_trail,
		"flutter": flutter,
		"centrifugal_sway": centrifugal_sway,
		"twitch": twitch,
		"twitch_side": twitch_side,
	}


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
		# 1 is everything solid; 8 is what only she has to go round (El Bosc's
		# fallen trunks, which the owner steps over)
		collision_mask = 1 | 8
		# Top down, nothing is a floor or a ceiling. Grounded mode took every
		# south face for a ceiling and threw away her sideways speed while she
		# touched one, so she crept along a block at 5 px/s; floating slides
		# her along any face at any angle, as walls already did
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		wall_min_slide_angle = 0.0
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
	skid = maxf(0.0, skid - delta * 4.0)
	launch_stretch_t = maxf(0.0, launch_stretch_t - delta)
	land_squash_t = maxf(0.0, land_squash_t - delta)
	if prev_hop > 0.5 and hop <= 0.01:
		land_squash_t = 0.16
	prev_hop = hop
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
	input_dir = iv
	input_active = iv.length() > 0.1
	planted = Input.is_action_pressed("plant") and not auto
	var answering_nature := Input.is_action_pressed("pee") and not auto
	# turbo: burn the zoomies for a burst of speed while energy lasts
	turbo_active = energy > 0.0 and input_active and (auto or Input.is_action_pressed("turbo"))
	if turbo_active:
		energy = maxf(0.0, energy - 0.28 * delta)
	var b_spd := base_speed()
	var b_acc := base_accel()
	if planted:
		if velocity.length() > b_spd * 0.6:
			skid = 1.0
			skid_dir = -velocity.normalized()
		velocity = Vector2.ZERO
	elif answering_nature:
		# stopping to go; not braced though - a yank interrupts, as in life
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	else:
		# a taut leash saps the DOG's authority: the heavier human's yanks
		# actually move you (flag set by main.gd/_apply_leash). Crucially,
		# an idle dragged dog barely brakes - braking toward zero was
		# silently cancelling the human's drag forces.
		var accel := b_acc
		if dragged:
			accel = lerpf(b_acc, 1000.0 if input_active else 250.0, drag_amt)
		if slick:
			# wet ground: less grip, more skate
			accel *= 0.45
		if ice:
			# packed snow/ice: barely any grip, momentum carries you
			accel *= 0.32
		# What she is standing on, from surfaces.gd rather than a multiplier
		# hardcoded here: sand is heavy going, grass grips better than it
		# runs, water is a happy dog-paddle. A full bladder is not a surface
		# - it waddles wherever you are - so it stays its own term.
		accel *= Surfaces.grip_mult(surface)
		var top := b_spd * (0.88 if bladder_slow else 1.0) * Surfaces.top_mult(surface)
		if main != null and main.has_method("dog_slope_mult"):
			top *= main.dog_slope_mult(global_position.y, velocity.y)
		if turbo_active:
			top *= TURBO_MULT
			accel = maxf(accel, b_acc * 1.33)
		# the mood goes on last, over the terrain and the turbo, so being
		# scared on sand is both of those things at once
		top *= mood_speed
		accel *= mood_accel
		# the zoomies do not steer: she goes roughly where you pointed. Only
		# the executed direction veers - input_dir keeps the player's actual
		# intent, which is what the rest of the game reads
		var go := iv if mood_wobble == 0.0 else iv.rotated(mood_wobble)
		var wish := go * top
		if flooded:
			wish.x *= FLOOD_STEER
		var prev_vel := velocity
		velocity = velocity.move_toward(wish, accel * delta)
		if face_lock != Vector2.ZERO:
			facing = face_lock
		elif input_active:
			facing = go.normalized()
		var crouching := peeing or squat_t > 0.0 or squat_ui > 0.0
		if not crouching and not planted:
			var spd := prev_vel.length()
			if spd > b_spd * 0.72:
				if input_active and go.dot(prev_vel.normalized()) < 0.2:
					skid = maxf(skid, clampf((spd - b_spd * 0.5) / b_spd, 0.35, 0.75))
					skid_dir = -prev_vel.normalized()
	move_and_slide()
	# floating motion keeps the speed she had into a face; drop it, so what
	# she is pressed against does not hold speed she cannot use
	for i in range(get_slide_collision_count()):
		var n := get_slide_collision(i).get_normal()
		if velocity.dot(n) < 0.0:
			velocity = velocity.slide(n)
	brace = move_toward(brace, 1.0 if face_lock != Vector2.ZERO else 0.0, BRACE_RATE * delta)
	# the hips trail the shoulders: the body hinges mid-turn
	# how she steps on what she is on: quick short steps on sand (no purchase),
	# slow heavy ones in mud, a slightly higher step through grass
	# the stride runs the way she is actually going: backing up, it runs back
	var stepping := velocity.length()
	if velocity.dot(facing) < -0.2 * stepping:
		stepping = -stepping
	gait += stepping * delta * 0.055 * _cadence()
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


func trigger_launch_stretch(dir: Vector2, duration: float = 0.28) -> void:
	launch_stretch_dir = dir.normalized()
	launch_stretch_t = duration


func hit_by_rider(dir: Vector2) -> void:
	knocked(dir, "rider")


# bowled over by something moving (a rider, a charging boar): a tumble that
# counts as taking a hit
func knocked(dir: Vector2, cause: String) -> void:
	if tumble_t > 0.0:
		return
	tumble_t = 0.8
	velocity = dir * 320.0
	main.on_dog_hit(cause)
	main.float_text(global_position, "yipe!", Color(1, 0.8, 0.6))


func fall_in(center: Vector2) -> void:
	# open holes are open holes, dogs included
	if tumble_t > 0.0 or hole_cd > 0.0:
		return
	tumble_t = 1.1
	hole_cd = 2.6
	global_position = center
	velocity = Vector2.ZERO
	main.on_dog_hit("hole")
	main.float_text(center, "oof", Color(1, 0.85, 0.6))


func forced_squat(duration: float) -> void:
	squat_t = duration
	velocity = Vector2.ZERO


func stumble() -> void:
	# a scrappy little bail off a kerb: she scrabbles, she is fine. Much
	# lighter than hit_by_rider, and it does not count as taking a hit.
	if tumble_t > 0.0:
		return
	tumble_t = 0.35
	velocity *= 0.35


func is_tumbling() -> bool:
	return tumble_t > 0.0


func _process(_delta: float) -> void:
	queue_redraw()


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_draw_xf()
	_draw_shapes()
	_b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_b.flush()


# how fast she looks to be going: her velocity, or a cutscene's walk
func _draw_speed() -> float:
	return maxf(velocity.length(), presentation_speed)


func _draw_xf(local_pos := Vector2.ZERO, local_rotation := 0.0,
		local_scale := Vector2.ONE) -> void:
	_b.draw_set_transform(presentation_offset + local_pos.rotated(presentation_rotation),
		presentation_rotation + local_rotation, local_scale)


# gait by surface (see tick): steps per distance, and how long each step is
func _cadence() -> float:
	var mult := 1.0
	var breed := _dog_breed()
	if breed == "french bulldog":
		mult = 1.25
	elif breed == "galgo":
		mult = 0.95
	match surface:
		Surfaces.S.SAND:
			return 1.35 * mult
		Surfaces.S.MUD:
			return 0.8 * mult
		Surfaces.S.GRASS:
			return 1.05 * mult
	return 1.0 * mult


func _stride() -> float:
	var mult := 1.0
	var breed := _dog_breed()
	if breed == "french bulldog":
		mult = 0.80
	elif breed == "galgo":
		mult = 1.20
	match surface:
		Surfaces.S.SAND:
			return 0.7 * mult
		Surfaces.S.MUD:
			return 1.25 * mult
		Surfaces.S.GRASS:
			return 1.1 * mult
	return 1.0 * mult


# the light comes from the upper left, as everywhere in the game
const LIGHT_DIR := Vector2(-0.6, -0.8)


# the torso as one shape: a capsule from the shoulders (ra) to the hips (rb)
static func _body_points(a: Vector2, b: Vector2, ra: float, rb: float) -> PackedVector2Array:
	var d := (b - a)
	var fwd := d.normalized() if d.length() > 0.01 else Vector2.DOWN
	var sd := fwd.orthogonal()
	var pts := PackedVector2Array()
	for k in range(9):
		var ang := PI * 0.5 + PI * float(k) / 8.0
		pts.append(a + (fwd * cos(ang) + sd * sin(ang)) * ra)
	for k in range(9):
		var ang := -PI * 0.5 + PI * float(k) / 8.0
		pts.append(b + (fwd * cos(ang) + sd * sin(ang)) * rb)
	return pts


func _draw_shapes() -> void:
	var t := AnimClock.msec() / 1000.0
	# a squashed contact shadow, offset as if the light is up and to the
	# left. Nothing sells "solid object on ground" faster than this.
	# (a preview built without a main, as in the tests, simply has no shadow)
	if not swimming and main != null:
		var lift: float = 1.0 + clampf(velocity.length() / 700.0, 0.0, 0.35)
		# contact_shadow resets the canvas transform when it is done, so the
		# shadow takes the cutscene offset itself and the body's transform is
		# set again below; otherwise the body drew at her gameplay position
		main.contact_shadow(_b, presentation_offset, 12.0, 8.0 * lift, 0.26)
	if hop > 0.0:
		var leap_s := clampf(hop * 0.016, 0.0, 0.22)
		_draw_xf(Vector2(0.0, -hop), 0.0, Vector2(1.0 - leap_s * 0.4, 1.0 + leap_s * 0.6))
	elif land_squash_t > 0.0:
		var sq := land_squash_t / 0.16
		_draw_xf(Vector2.ZERO, 0.0, Vector2(1.0 + sq * 0.16, 1.0 - sq * 0.12))
	elif launch_stretch_t > 0.0:
		var st := launch_stretch_t / 0.28
		_draw_xf(Vector2.ZERO, 0.0, Vector2(1.0 + st * 0.25, 1.0 - st * 0.14))
	else:
		_draw_xf()
	# the coat comes from data now (Game.COATS), not baked-in colours, so a
	# dog creator later means adding a row of parameters rather than editing
	# this renderer
	var cd: Dictionary = _coat_data()
	var fur: Color = cd.fur
	var fur_dark: Color = cd.dark
	var grizzle: Color = cd.mark
	var crouching := peeing or squat_t > 0.0 or squat_ui > 0.0
	var dig_u := clampf(digging, 0.0, 1.0)
	var sniff_u := clampf(sniffing, 0.0, 1.0)
	var drink_u := clampf(drinking, 0.0, 1.0)
	var bk := sin(clampf(bark_anim / 0.35, 0.0, 1.0) * PI) if bark_anim > 0.0 else 0.0
	var mood_id := int(main.mood.active) if (main != null and main.mood != null) else 0
	var mood_int := clampf(float(main.mood.intensity), 0.0, 1.0) if (main != null and main.mood != null) else 0.0
	var side := facing.orthogonal()
	var breed := _dog_breed()
	var is_galgo := breed == "galgo"
	var is_frenchie := breed == "french bulldog"
	var shoulder := facing * ((4.6 if is_frenchie else (7.5 if is_galgo else 6.0)) - 1.5 * dig_u)
	var hside := hip_dir.orthogonal()
	if swimming:
		# expanding wake rings behind her happy paddling self
		for i in range(3):
			var rr := fmod(t * 1.4 + i * 0.45, 1.35)
			_b.draw_arc(-facing * 6.0, 12.0 + rr * 26.0, 0, TAU, 22, Color(0.82, 0.9, 1.0, 0.32 * (1.0 - rr / 1.35)), 2.0)
	# THE WIGGLE: the rump swings with the gait
	var b_spd := base_speed()
	var wiggle := hside * sin(gait) * clampf(_draw_speed() / b_spd, 0.0, 1.0) * (3.5 if is_frenchie else 2.6)
	var hip := shoulder + hip_dir * (12.5 if is_frenchie else (22.0 if is_galgo else 17.0)) + wiggle
	# whippy tail: three tapering segments with a traveling wave, tuned by mood and action
	var wag_speed := 3.0 if crouching else 11.0
	var wag_amp := 0.15 if crouching else 0.38
	var tail_len_scale := 1.0
	var tail_angle_bias := 0.0
	if not crouching:
		if turbo_active or mood_id == 3: # ZOOMIES
			wag_speed = lerpf(wag_speed, 22.0, maxf(mood_int, 1.0 if turbo_active else 0.0))
			wag_amp = lerpf(wag_amp, 0.65, maxf(mood_int, 1.0 if turbo_active else 0.0))
		elif mood_id == 0: # HAPPY: perky, cheerful wagging
			wag_speed = lerpf(wag_speed, 16.0, mood_int)
			wag_amp = lerpf(wag_amp, 0.48, mood_int)
		elif mood_id == 2: # BARKY: alert, stiff high tail, fast small twitches
			wag_speed = lerpf(wag_speed, 26.0, mood_int)
			wag_amp = lerpf(wag_amp, 0.15, mood_int)
			tail_len_scale = lerpf(1.0, 1.15, mood_int)
		elif mood_id == 1: # SCARED: tucked under belly, trembling
			wag_speed = lerpf(wag_speed, 18.0, mood_int)
			wag_amp = lerpf(wag_amp, 0.04, mood_int)
			tail_len_scale = lerpf(1.0, 0.45, mood_int)
			tail_angle_bias = lerpf(0.0, PI * 0.85, mood_int)
		elif mood_id == 4: # TIRED: slow, drooping, lazy wag
			wag_speed = lerpf(wag_speed, 4.5, mood_int)
			wag_amp = lerpf(wag_amp, 0.20, mood_int)
			tail_len_scale = lerpf(1.0, 0.85, mood_int)
		elif _draw_speed() < 5.0 and not planted:
			# Idle standing: gentle relaxed tail sway
			wag_speed = 4.0
			wag_amp = 0.22
		elif sniff_u > 0.05 or dig_u > 0.05:
			wag_speed = maxf(wag_speed, 15.5)
			wag_amp = maxf(wag_amp, 0.44)
	if is_frenchie:
		# French bulldog natural short screw / stub tail, wiggling merrily on the rump
		var nub_wag := sin(t * wag_speed) * (wag_amp * 0.75)
		var tdir := hip_dir.rotated(tail_angle_bias + nub_wag)
		var tp := hip + hip_dir * 3.0
		_b.draw_circle(tp, 2.9, fur_dark)
		_b.draw_circle(tp + tdir * 2.6, 2.2, fur)
		_b.draw_circle(tp + tdir * 4.2, 1.5, fur_dark.darkened(0.2))
	else:
		var tail_scale: float = tail_len_scale * (1.35 if is_galgo else 1.0)
		var tp := hip + hip_dir * (4.0 * tail_scale)
		var tdir := hip_dir.rotated(tail_angle_bias)
		var widths: Array = [2.4, 1.8, 1.1] if is_galgo else [3.2, 2.4, 1.7]
		for s in range(3):
			tdir = tdir.rotated(sin(t * wag_speed - s * 0.9) * wag_amp)
			if is_galgo and s == 2:
				tdir = tdir.rotated(0.32 * (1.0 if tdir.x >= 0.0 else -1.0))
			var seg_len: float = (11.0 - s * 1.8) if is_galgo else (9.0 - s * 1.5)
			var nxt := tp + tdir * seg_len * tail_scale
			_b.draw_line(tp, nxt, fur_dark, widths[s])
			tp = nxt
	# four legs, trot gait: diagonal pairs move together, tucked when crouching,
	# scrabbling rapidly in front when digging up a buried bone
	var stride_mult := 0.78 if is_frenchie else (1.25 if is_galgo else 1.0)
	var amp := 0.0 if crouching else clampf(_draw_speed() / b_spd, 0.0, 1.0) * (5.5 * stride_mult) * _stride()
	var ph := sin(gait)
	var dig_scrabble := sin(t * 28.0) * 4.8 * dig_u
	# white-tipped paws, like she stepped in paint and regrets nothing
	var paw := Color(0.78, 0.76, 0.73)
	if surface == Surfaces.S.MUD:
		# sunk in it to the ankles
		paw = Color(0.36, 0.28, 0.20)
	# braced (the rope tug), the front paws dig in out ahead and the back
	# paws spread
	var front_reach := (4.5 if is_frenchie else (8.0 if is_galgo else 6.0)) + brace * 3.5 + 2.5 * dig_u
	var paw_r := 3.4 if is_frenchie else (2.5 if is_galgo else 3.0)
	var front_spread := 9.2 if is_frenchie else (6.8 if is_galgo else 7.5)
	_b.draw_circle(shoulder + side * front_spread + facing * (front_reach + ph * amp + dig_scrabble), paw_r, paw)
	_b.draw_circle(shoulder - side * front_spread + facing * (front_reach - ph * amp - dig_scrabble), paw_r, paw)
	if dig_u > 0.05:
		# clods of earth kicked back behind her scrabbling front paws
		for ci in range(3):
			var cp := fmod(t * 7.5 + float(ci) * 0.33, 1.0)
			var clod_at := shoulder - facing * (4.0 + cp * 15.0) + side * (float(ci - 1) * 6.5)
			_b.draw_circle(clod_at, (2.6 - cp * 1.4) * dig_u, Color(0.38, 0.29, 0.20, 0.75 * (1.0 - cp) * dig_u))
	var rear_reach := 1.0 if crouching else (3.2 if is_frenchie else (5.5 if is_galgo else 4.0))
	var rear_spread := (8.4 if is_frenchie else (5.8 if is_galgo else 7.0)) + brace * 1.5
	_b.draw_circle(hip + hside * rear_spread - hip_dir * (rear_reach - ph * amp * 0.8), paw_r + (0.1 if is_frenchie else 0.2), paw)
	_b.draw_circle(hip - hside * rear_spread - hip_dir * (rear_reach + ph * amp * 0.8), paw_r + (0.1 if is_frenchie else 0.2), paw)
	# lean street-dog torso, hinged; the rump drops into the squat. A rim a
	# shade darker on the side away from the light first, then the fur, then
	# the light along her back: plasticine, not a flat cut-out
	var hip_r := (8.8 if is_frenchie else (7.0 if is_galgo else 10.5)) if crouching else (7.6 if is_frenchie else (5.6 if is_galgo else 9.0))
	var shoulder_r := 9.8 if is_frenchie else (8.2 if is_galgo else 7.4)
	if _draw_speed() < 5.0 and not crouching:
		shoulder_r += sin(t * 3.2) * (0.60 if is_frenchie else 0.45)
	if is_frenchie and planted and not crouching:
		shoulder_r += 1.0
		hip_r += 0.8
	var rim := Vector2(1.2, 1.6)
	_b.draw_colored_polygon(_body_points(shoulder + rim, hip + rim, shoulder_r, hip_r), fur_dark.darkened(0.25))
	_b.draw_colored_polygon(_body_points(shoulder, hip, shoulder_r, hip_r), fur)
	_b.draw_colored_polygon(_body_points(shoulder + LIGHT_DIR * 2.6, hip + LIGHT_DIR * 2.6, (5.6 if is_frenchie else (4.6 if is_galgo else 4.2)), (4.0 if is_frenchie else (3.4 if is_galgo else 4.6))),
		fur.lightened(0.10))
	# only a few subtle flecks on the body - the grey lives on the head
	for i in range(6):
		var base := hip if i % 2 == 0 else shoulder
		_b.draw_circle(base + flecks[i], 1.0, Color(grizzle, 0.22))
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
		_b.draw_colored_polygon(bandana, bcol)
		_b.draw_line(bandana[0], bandana[1], edge, 1.5)
		_b.draw_line(bandana[1], bandana[2], edge, 1.5)
		_b.draw_line(bandana[2], bandana[0], edge, 1.5)
	var strap_w := 9.6 if is_frenchie else (7.5 if is_galgo else 8.0)
	var strap_thick := 7.0 if is_frenchie else (6.5 if is_galgo else 6.0)
	_b.draw_line(shoulder + side * strap_w, shoulder - side * strap_w, col, strap_thick)
	_b.draw_circle(shoulder, 2.4 if is_frenchie else 2.2, Color(0.3, 0.3, 0.32))
	var neck := shoulder + facing * (5.5 if is_frenchie else (9.0 if is_galgo else 6.5))
	var neck_w := 6.2 if is_frenchie else (4.5 if is_galgo else 5.5)
	var neck_thick := 4.5 if is_frenchie else (4.0 if is_galgo else 3.0)
	_b.draw_line(neck + side * neck_w, neck - side * neck_w, col, neck_thick)
	# head with a LONG nose; stretches forward and twitches when sniffing,
	# dips when digging/drinking, surges forward on a bark
	var sniff_twitch := side * (sin(t * 22.0) * 1.5 * sniff_u)
	var head_reach := 8.0 if is_frenchie else (13.5 if is_galgo else 10.0)
	var head := shoulder + facing * (head_reach + 2.0 * sniff_u + 1.2 * drink_u - 1.4 * dig_u + 2.0 * bk) + sniff_twitch
	var flop := sin(gait) * 1.6
	var ear_perk := 2.2 * sniff_u + 1.8 * bk - (2.4 * mood_int if mood_id == 1 else 0.0)
	var ear_flare := 1.8 * bk + (0.9 * mood_int if mood_id == 4 else 0.0)
	var ear_dyn: Dictionary = get_ear_dynamics()
	var wind_trail: float = ear_dyn.wind_trail
	var flutter: float = ear_dyn.flutter
	var centrifugal_sway: float = ear_dyn.centrifugal_sway
	var twitch: float = ear_dyn.twitch
	var twitch_side: float = ear_dyn.twitch_side
	if is_frenchie:
		# Iconic Frenchie "bat ears": upright, tall, broad-based with rounded tops,
		# facing forward/outward with warm inner ear leather visible
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + side * 4.6 * sg - facing * 0.5
			var ear_angle := 0.22 * sg + tw * 0.08 - wind_trail * 0.04
			var ear_up := facing.rotated(ear_angle)
			var ear_out := side.rotated(ear_angle) * sg
			var base_w := 3.6
			var ear_h := 10.5 + ear_perk * 0.8
			var ear_p0 := root - ear_out * 1.5 - ear_up * 1.0
			var ear_p1 := root + ear_out * base_w
			var ear_tip := root + ear_out * 4.2 + ear_up * ear_h
			var ear_tip_inner := root + ear_out * 1.8 + ear_up * (ear_h + 1.2)
			var ear_p3 := root - ear_out * 0.8 + ear_up * (ear_h * 0.75)
			# Outer shell
			_b.draw_colored_polygon(PackedVector2Array([
				ear_p0,
				ear_p1,
				ear_tip,
				ear_tip_inner,
				ear_p3,
			]), fur_dark)
			# Inner ear leather: soft warm pinkish-fur interior
			var inner_col := Color(
				clampf(fur_dark.r * 1.4 + 0.18, 0.0, 1.0),
				clampf(fur_dark.g * 1.1 + 0.12, 0.0, 1.0),
				clampf(fur_dark.b * 1.1 + 0.12, 0.0, 1.0)
			)
			_b.draw_colored_polygon(PackedVector2Array([
				root + ear_out * 0.2 + ear_up * 1.0,
				root + ear_out * (base_w - 0.9) + ear_up * 1.5,
				ear_tip - ear_out * 0.8 - ear_up * 1.8,
				ear_tip_inner - ear_out * 0.5 - ear_up * 2.2,
				ear_p3 + ear_out * 0.4 + ear_up * 0.5,
			]), inner_col)
	elif is_galgo:
		# folded rose ears laying streamlined along the nape of the neck
		for sg: float in [-1.0, 1.0]:
			var root := head + side * 4.0 * sg - facing * 0.5
			var ear_side := (3.8 + ear_flare * 0.4 + centrifugal_sway * 0.4) * sg
			var ear_back := 6.5 + wind_trail * 0.4 - ear_perk * 0.6
			var tip := head + side * ear_side - facing * ear_back
			_b.draw_colored_polygon(PackedVector2Array([
				root + facing * 1.0 - side * sg * 0.8,
				root + side * sg * 1.2,
				tip + side * sg * 1.2,
				tip - facing * 1.5,
				tip - side * sg * 1.0
			]), fur_dark)
	else:
		# big floppy ears, under the skull, swinging slightly with the stride,
		# trailing back in the slipstream at speed and swaying with turns
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + side * 5.0 * sg + facing * 1.0
			var ear_side := (7.6 + ear_flare + flop * 0.7 * sg + centrifugal_sway * 0.85 + tw * 0.5) * sg
			var ear_back := 8.0 + wind_trail + flutter * sg - ear_perk
			var tip := head + side * ear_side - facing * ear_back
			_b.draw_colored_polygon(PackedVector2Array([root + facing * 1.6 - side * sg * 1.0, root + side * sg * 1.6,
				tip + side * sg * 1.8, tip - facing * 2.0, tip - side * sg * 1.6]), fur_dark)
	var head_r := 8.2 if is_frenchie else (5.8 if is_galgo else 7.0)
	_b.draw_circle(head + rim * 0.7, head_r, fur_dark.darkened(0.25))
	_b.draw_circle(head, head_r, fur)
	# open jaw and pink tongue during a bark or while lapping water
	if bk > 0.05:
		var jaw_at := head + facing * ((6.2 if is_frenchie else 9.5) + bk * 2.2)
		var jaw_r := 4.0 if is_frenchie else 3.2
		_b.draw_circle(jaw_at, jaw_r, Color(0.38, 0.10, 0.12))
		_b.draw_circle(jaw_at + facing * 1.0, 2.5 if is_frenchie else 2.1, Color(0.92, 0.48, 0.54))
	elif drink_u > 0.05:
		var lap := maxf(0.0, sin(t * 16.0)) * drink_u
		if lap > 0.05:
			_b.draw_circle(head + facing * ((8.0 if is_frenchie else 11.0) + lap * 3.8), 2.2 if is_frenchie else 2.0, Color(0.94, 0.52, 0.58))
		for di in range(2):
			var dp := fmod(t * 3.4 + float(di) * 0.5, 1.0)
			var drop_dir := side * (1.0 if di == 0 else -1.0)
			_b.draw_circle(head + facing * (8.5 if is_frenchie else 11.5) + drop_dir * (3.0 + dp * 6.0), 1.4 * (1.0 - dp) * drink_u,
				Color(0.76, 0.90, 1.0, 0.65 * (1.0 - dp) * drink_u))
	# the muzzle: tapering out to the nose, not a stick
	if is_frenchie:
		var muz_len := 5.2
		var muzzle := PackedVector2Array([
			head + side * 5.2 + facing * 1.5,
			head + side * 4.0 + facing * muz_len,
			head - side * 4.0 + facing * muz_len,
			head - side * 5.2 + facing * 1.5
		])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_line(head + side * 3.6 + facing * 3.0, head - side * 3.6 + facing * 3.0, fur_dark.darkened(0.2), 2.2)
		_b.draw_circle(head + facing * 1.5, 3.8, Color(grizzle, 0.45))
		_b.draw_circle(head + LIGHT_DIR * 2.2, 2.2, fur.lightened(0.12))
	elif is_galgo:
		var muz_len := 13.5
		var muzzle := PackedVector2Array([
			head + side * 3.4 + facing * 2.0,
			head + side * 1.5 + facing * muz_len,
			head - side * 1.5 + facing * muz_len,
			head - side * 3.4 + facing * 2.0
		])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_circle(head + facing * 2.0, 3.2, Color(grizzle, 0.45))
		_b.draw_line(head + facing * 3.0, head + facing * (muz_len - 1.5), Color(grizzle, 0.5), 2.4)
		_b.draw_circle(head - facing * 2.0, 2.6, Color(grizzle, 0.3))
		_b.draw_circle(head + LIGHT_DIR * 2.0, 2.0, fur.lightened(0.12))
	else:
		var muzzle := PackedVector2Array([head + side * 4.6 + facing * 2.0, head + side * 2.2 + facing * 10.5,
			head - side * 2.2 + facing * 10.5, head - side * 4.6 + facing * 2.0])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_circle(head + facing * 2.0, 4.0, Color(grizzle, 0.45))
		_b.draw_line(head + facing * 3.0, head + facing * 9.0, Color(grizzle, 0.5), 3.0)
		_b.draw_circle(head - facing * 2.5, 3.2, Color(grizzle, 0.3))
		_b.draw_circle(head + LIGHT_DIR * 2.4, 2.4, fur.lightened(0.12))
	# eyes, set back on the skull, with the brows that make her a dog with a
	# plan (the icon's trick)
	if is_frenchie:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + facing * 1.8 + side * 4.5 * sg2
			_b.draw_circle(eye, 2.2, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + facing * 0.4, 1.35, Color(0.06, 0.05, 0.06))
			_b.draw_line(eye - facing * 2.0 + side * sg2 * 1.6, eye - facing * 2.4 - side * sg2 * 1.4,
				Color(grizzle, 0.75), 1.4)
	elif is_galgo:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + facing * 2.6 + side * 2.8 * sg2
			_b.draw_circle(eye, 1.6, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + facing * 0.5, 1.0, Color(0.06, 0.05, 0.06))
			_b.draw_line(eye - facing * 1.5 + side * sg2 * 1.2, eye - facing * 1.9 - side * sg2 * 1.0,
				Color(grizzle, 0.75), 1.0)
	else:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + facing * 2.2 + side * 3.6 * sg2
			_b.draw_circle(eye, 1.9, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + facing * 0.5, 1.15, Color(0.06, 0.05, 0.06))
			_b.draw_line(eye - facing * 1.8 + side * sg2 * 1.6, eye - facing * 2.3 - side * sg2 * 1.4,
				Color(grizzle, 0.75), 1.2)
	# the nose, with the shine on it
	var nose_len := 5.8 if is_frenchie else (14.0 if is_galgo else 11.0)
	var nose_r := 3.0 if is_frenchie else (2.0 if is_galgo else 2.6)
	var nose_shine := 0.9 if is_frenchie else (0.7 if is_galgo else 0.9)
	var nose_at := head + facing * nose_len + side * (sin(t * 28.0) * 0.7 * sniff_u)
	if is_frenchie:
		_b.draw_circle(nose_at + side * 0.9, nose_r * 0.85, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at - side * 0.9, nose_r * 0.85, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at, nose_r * 0.9, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at + LIGHT_DIR * nose_shine, nose_shine * 0.75, Color(0.55, 0.55, 0.58))
	else:
		_b.draw_circle(nose_at, nose_r, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at + LIGHT_DIR * nose_shine, nose_shine, Color(0.55, 0.55, 0.58))
	if sniff_u > 0.05:
		for si in range(2):
			var sp := 1.0 - fmod(t * 2.4 + float(si) * 0.5, 1.0)
			_b.draw_circle(nose_at + facing * (2.5 + sp * 7.0) + side * (float(si * 2 - 1) * 2.5 * sp),
				(1.2 + sp * 1.0) * sniff_u, Color(0.88, 0.92, 0.76, 0.45 * (1.0 - sp) * sniff_u))
	if peeing:
		for i in range(2):
			var a := t * 5.0 + i * 2.4
			_b.draw_circle(hip + hip_dir * 10.0 + hside * sin(a) * 3.0, 1.6, Color(0.93, 0.85, 0.4, 0.5))
	if skid > 0.0 and not crouching:
		# dust kicked up off the braced front paws, tinted to the surface underfoot
		var dust_col := Color(0.72, 0.66, 0.56)
		if ice:
			dust_col = Color(0.85, 0.92, 1.0)
		elif surface == Surfaces.S.SAND:
			dust_col = Color(0.82, 0.72, 0.50)
		elif surface == Surfaces.S.MUD:
			dust_col = Color(0.35, 0.26, 0.18)
		elif surface == Surfaces.S.GRASS:
			dust_col = Color(0.42, 0.48, 0.30)
		elif surface == Surfaces.S.WATER:
			dust_col = Color(0.85, 0.94, 1.0)
		for i in range(3):
			var kp := fmod(t * 5.0 + float(i) * 0.33, 1.0)
			var dp := facing * (14.0 + kp * 16.0) + side * (float(i) - 1.0) * 8.0 * (1.0 + kp)
			_b.draw_circle(dp, 3.0 + kp * 5.0, Color(dust_col.r, dust_col.g, dust_col.b, 0.40 * skid * (1.0 - kp)))
	if planted and not crouching:
		var mark_count := 6 if is_frenchie else 4
		var mark_w := 4.0 if is_frenchie else 3.0
		var mark_dist := 21.0 if is_frenchie else 19.0
		var mark_len := 8.0 if is_frenchie else 6.0
		for i in range(mark_count):
			var a2 := TAU * float(i) / float(mark_count) + 0.4
			var p := Vector2.from_angle(a2) * mark_dist
			_b.draw_line(p, p + Vector2.from_angle(a2) * mark_len, Color(0.3, 0.25, 0.2), mark_w)
	if tempted and tumble_t <= 0.0:
		_b.draw_line(Vector2(15, -30), Vector2(15, -22), Color(0.95, 0.62, 0.55), 3.0)
		_b.draw_circle(Vector2(15, -18), 2.0, Color(0.95, 0.62, 0.55))
	if bark_anim > 0.0:
		var r := (0.35 - bark_anim) / 0.35
		_b.draw_arc(head + facing * 8.0, 10.0 + r * 34.0, 0, TAU, 24, Color(1, 1, 1, 0.7 * (1.0 - r)), 2.0)
	if squat_ui > 0.0 or squat_t > 0.0:
		for i in range(3):
			_b.draw_circle(Vector2(-8 + i * 8, -26), 2.0, Color(1, 1, 1, 0.7))
		if squat_ui > 0.0:
			_b.draw_arc(Vector2.ZERO, 20.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(squat_ui, 0.0, 1.0), 20, Color(1, 0.95, 0.7), 3.0)
	if swimming:
		# waterline over the hindquarters and little paddle splashes up front
		_b.draw_circle(hip, 11.0, Color(0.42, 0.56, 0.66, 0.5))
		_b.draw_circle(shoulder + facing * 2.0, 9.0, Color(0.42, 0.56, 0.66, 0.32))
		_b.draw_circle(head + facing * 12.0 + side * sin(t * 18.0) * 4.0, 2.2, Color(0.9, 0.95, 1.0, 0.8))
		_b.draw_circle(head + facing * 12.0 - side * sin(t * 18.0) * 4.0, 1.8, Color(0.9, 0.95, 1.0, 0.6))
