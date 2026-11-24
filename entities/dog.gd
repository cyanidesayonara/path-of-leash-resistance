extends CharacterBody2D

# The player: Millie, a medium-sized mutt, black with salt and pepper
# thrown in. Fast, agile, responsible for the entire relationship.

const SPEED := 330.0
const ACCEL := 2400.0
const Surfaces := preload("res://world/surfaces.gd")

# what she is recoloured to as stone: shadow to light, by her own colours' value
const STONE_LO := Color(0.66, 0.64, 0.60)
const STONE_HI := Color(0.94, 0.92, 0.86)

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
# while a dare's clock runs the zoomies are free (main sets it): every swing
# needs them, and a dare is 20-odd seconds of nothing but swings
var free_turbo := false
# set by main each tick from mood.gd: a mood changes how she handles, not just
# how the screen looks, and the handling is meant to land first. 1.0 is an
# ordinary unbothered dog; wobble is a veer in radians the zoomies add on top
# of wherever the player actually pointed.
var mood_speed := 1.0
var mood_accel := 1.0
var mood_wobble := 0.0
var turbo_active := false
const TURBO_MULT := 1.7
# zoomies grip: Millie's, scaled by each breed's acceleration
const TURBO_ACCEL := 3200.0
# the collision circle every walk is built round; a breed's gap_mult scales it
const BODY_RADIUS := 14.0
# A breed drawn on another's frame: the proportions, gait and muzzle are the
# frame's, and only what makes her herself (ears, tail, markings) is her own.
# The ratonero is a smaller, squarer mongrel; the podenco a galgo's frame.
const BODY_PLAN := {"ratonero bodeguero": "mongrel", "podenco": "galgo"}
const DRAW_SCALE := {"ratonero bodeguero": 0.84}
# the white of a tricolor's or a podenco's markings, whatever the coat
const MARK_WHITE := Color(0.93, 0.91, 0.87)
const MARK_TAN := Color(0.74, 0.52, 0.30)
var tumble_t := 0.0
var stone_t := 0.0   # turned to stone by La Lleona: rooted and braced
# riding a loose tile (ride()): time left, of, and the carried velocity
var ride_t := 0.0
var ride_time := 0.0
var ride_vel := Vector2.ZERO
const RIDE_STEER := 2.2
var hole_cd := 0.0
var squat_t := 0.0
var squat_ui := 0.0
# while nature calls: 0 not calling, 1 calling on a poor spot, 2 on a good
# spot (main.poop_spot_good), shown as a soft ring at her paws
var poop_cue := 0
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
# Her idle quirk (Game.DOGS' "quirk"): stood still a while, on a walk or in
# the wardrobe, she does her own small thing now and then. Drawing only: it
# never reaches tick(), so where she is and how fast are untouched. Moving,
# or any input at all, ends it at once.
const QUIRK_FIRST := 4.0       # seconds stood still before the first
const QUIRK_GAP_MIN := 8.0     # then one every this many to...
const QUIRK_GAP_MAX := 15.0
const QUIRK_LEN := 1.5
const QUIRK_STILL_SPEED := 5.0
var quirks := true
var quirk := ""                # the one playing, or ""
var quirk_u := 0.0             # how far through it, 0..1
var _quirk_n := -1             # which of this stillness's quirks it is
var _still_since := 0          # AnimClock msec she was last moving or asked anything
var _still_known := false
var _snorted := -1
# the pose it makes, worked out once a frame for _draw_shapes
var _q_shift := Vector2.ZERO
var _q_scale := Vector2.ONE


func base_speed() -> float:
	return SPEED * (Game.dog_speed_mult() if Game != null else 1.0)


func base_accel() -> float:
	return ACCEL * (Game.dog_accel_mult() if Game != null else 1.0)


func plant_grip_mult() -> float:
	return Game.dog_plant_mult() if Game != null else 1.0


func herd_mult() -> float:
	return Game.dog_herd_mult() if Game != null else 1.0


func muck_mult() -> float:
	return Game.dog_muck_mult() if Game != null else 1.0

var col_shape: CollisionShape2D


func mass_mult() -> float:
	return Game.dog_mass_mult() if Game != null else 1.0


func reel_mult() -> float:
	return Game.dog_reel_mult() if Game != null else 1.0


func gap_mult() -> float:
	return Game.dog_gap_mult() if Game != null else 1.0


func collision_radius() -> float:
	return BODY_RADIUS * gap_mult()


func apply_breed_shape() -> void:
	if col_shape != null and col_shape.shape is CircleShape2D:
		(col_shape.shape as CircleShape2D).radius = collision_radius()


func _dog_key() -> String:
	return Game.dog if Game != null else "millie"


func _dog_breed() -> String:
	return Game.dog_breed(_dog_key()) if Game != null else "mongrel"


func setup(m: Node2D) -> void:
	main = m
	apply_breed_shape()


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
		col_shape = CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = collision_radius()
		col_shape.shape = sh
		add_child(col_shape)
		for i in range(14):
			flecks.append(Vector2.from_angle(randf() * TAU) * randf_range(2.0, 9.5))
	else:
		var preview_rng := RandomNumberGenerator.new()
		preview_rng.seed = 1729
		for i in range(14):
			flecks.append(Vector2.from_angle(preview_rng.randf() * TAU) * preview_rng.randf_range(2.0, 9.5))


func tick(delta: float) -> void:
	if col_shape != null and col_shape.shape is CircleShape2D:
		var cr := collision_radius()
		if not is_equal_approx((col_shape.shape as CircleShape2D).radius, cr):
			(col_shape.shape as CircleShape2D).radius = cr
	bark_cd = maxf(0.0, bark_cd - delta)
	skid = maxf(0.0, skid - delta * 4.0)
	launch_stretch_t = maxf(0.0, launch_stretch_t - delta)
	land_squash_t = maxf(0.0, land_squash_t - delta)
	if prev_hop > 0.5 and hop <= 0.01:
		land_squash_t = 0.16
	prev_hop = hop
	bark_anim = maxf(0.0, bark_anim - delta)
	hole_cd = maxf(0.0, hole_cd - delta)
	if stone_t > 0.0:
		stone_t -= delta
		planted = true
		input_active = false
		velocity = Vector2.ZERO
		return
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
	if ride_t > 0.0:
		_tick_ride(delta)
		return
	var iv := auto_move if auto else _screen_input()
	input_dir = iv
	input_active = iv.length() > 0.1
	planted = Input.is_action_pressed("plant") and not auto
	var answering_nature := Input.is_action_pressed("pee") and not auto
	# turbo: burn the zoomies for a burst of speed while energy lasts
	turbo_active = energy > 0.0 and input_active and (auto or Input.is_action_pressed("turbo"))
	if turbo_active and not free_turbo:
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
			accel = maxf(accel, TURBO_ACCEL * b_acc / ACCEL)
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


# Riding something loose across the ground (El Drac's shed tiles): she goes
# where it carries her, steering a little, for `time` seconds; a wall ends it.
func ride(v: Vector2, time: float) -> void:
	ride_vel = v
	ride_t = time
	ride_time = time


# The stick and keys mean screen directions: on a turned camera (the
# Diagonal spike) up is up the screen, so it is turned into the world.
func _screen_input() -> Vector2:
	var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if main != null and main.cam != null and main.cam.rotation != 0.0:
		iv = iv.rotated(main.cam.rotation)
	return iv


func is_riding() -> bool:
	return ride_t > 0.0


func _tick_ride(delta: float) -> void:
	ride_t -= delta
	planted = false
	var iv := auto_move if auto else _screen_input()
	input_dir = iv
	input_active = iv.length() > 0.1
	if input_active:
		var turn := clampf(ride_vel.angle_to(iv), -RIDE_STEER * delta, RIDE_STEER * delta)
		ride_vel = ride_vel.rotated(turn)
	# full speed off the mark, easing as the tile grinds to a stop
	velocity = ride_vel * lerpf(0.55, 1.0, clampf(ride_t / maxf(ride_time, 0.01), 0.0, 1.0))
	facing = ride_vel.normalized()
	move_and_slide()
	if get_slide_collision_count() > 0:
		ride_t = 0.0
	gait += velocity.length() * delta * 0.02


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
	ride_t = 0.0
	velocity = dir * 320.0
	main.on_dog_hit(cause)
	main.float_text(global_position, I18n.t("w_yipe"), Color(1, 0.8, 0.6))


# a statue for `secs`: she neither moves nor can be moved, and it is a hit
func petrify(secs: float) -> void:
	if stone_t > 0.0:
		return
	tumble_t = 0.0
	rotation = 0.0
	ride_t = 0.0
	stone_t = secs
	velocity = Vector2.ZERO
	main.on_dog_hit("gaze")


func fall_in(center: Vector2) -> void:
	# open holes are open holes, dogs included
	if tumble_t > 0.0 or hole_cd > 0.0:
		return
	tumble_t = 1.1
	hole_cd = 2.6
	global_position = center
	velocity = Vector2.ZERO
	main.on_dog_hit("hole")
	main.float_text(center, I18n.t("w_oof_3"), Color(1, 0.85, 0.6))


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
	_tick_quirk()
	queue_redraw()


# Where in its quirks a dog stood still for `still` seconds is: x the quirk's
# number (-1 between quirks), y how far through it. The gaps are a hash of the
# number, so the same stillness always plays the same way.
static func quirk_phase(still: float) -> Vector2:
	var at := QUIRK_FIRST
	var n := 0
	while at <= still:
		if still < at + QUIRK_LEN:
			return Vector2(n, (still - at) / QUIRK_LEN)
		at += lerpf(QUIRK_GAP_MIN, QUIRK_GAP_MAX, _quirk_hash(n))
		n += 1
	return Vector2(-1.0, 0.0)


static func _quirk_hash(n: int) -> float:
	return fposmod(sin(float(n) * 12.9898 + 4.1414) * 43758.5453, 1.0)


# nothing asked of her and nothing happening to her
func _quirk_idle() -> bool:
	if not quirks or Input.is_anything_pressed():
		return false
	if preview_mode:
		return is_visible_in_tree()
	if main == null or not bool(main.get("started")) or bool(main.get("paused")) or bool(main.get("frozen")):
		return false
	if input_active or planted or peeing or squat_t > 0.0 or squat_ui > 0.0 or tumble_t > 0.0 or ride_t > 0.0:
		return false
	if swimming or hop > 0.0 or bark_anim > 0.0 or face_lock != Vector2.ZERO or skid > 0.0:
		return false
	if digging > 0.05 or sniffing > 0.05 or drinking > 0.05:
		return false
	return _draw_speed() <= QUIRK_STILL_SPEED


func _tick_quirk() -> void:
	var now := AnimClock.msec()
	if not _quirk_idle() or not _still_known:
		_still_since = now
		_still_known = true
		quirk = ""
		quirk_u = 0.0
		_quirk_n = -1
		_snorted = -1
		return
	var ph := quirk_phase(float(now - _still_since) / 1000.0)
	_quirk_n = int(ph.x)
	if _quirk_n < 0:
		quirk = ""
		quirk_u = 0.0
		return
	quirk = Game.dog_quirk(_dog_key()) if Game != null else "sniff"
	quirk_u = ph.y
	# Mochi snorts at your human on every other sit
	if quirk == "sit" and quirk_u >= 0.55 and _snorted != _quirk_n:
		_snorted = _quirk_n
		if _quirk_n % 2 == 0:
			Sfx.play("snort", 1.7, -18.0)


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch


# What is in her mouth: anything with draw_held(batch, bite, fwd, side, jaw),
# which her draw calls between her head and her muzzle. The thing's own
# drawing stands down while she holds it.
var held: Object = null
var _bite_local := Vector2.ZERO


# the middle of her jaws, in the world, as she was last drawn
func mouth_point() -> Vector2:
	if _bite_local == Vector2.ZERO:
		return global_position + facing * 18.0
	var sc := _q_scale * float(DRAW_SCALE.get(_dog_breed(), 1.0))
	return global_position + presentation_offset + _q_shift + (_bite_local * sc).rotated(presentation_rotation)


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_quirk_pose(AnimClock.msec() / 1000.0)
	_draw_xf()
	_draw_shapes()
	if stone_t > 0.0:
		# a black dog cannot be tinted to stone, so her colours are remapped
		for i in range(_b._colors.size()):
			var c: Color = _b._colors[i]
			if c.a > 0.5:
				_b._colors[i] = Color(STONE_LO.lerp(STONE_HI, c.get_luminance()), c.a)
	_b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_b.flush()


# how fast she looks to be going: her velocity, or a cutscene's walk
func _draw_speed() -> float:
	return maxf(velocity.length(), presentation_speed)


func _draw_xf(local_pos := Vector2.ZERO, local_rotation := 0.0,
		local_scale := Vector2.ONE) -> void:
	_b.draw_set_transform(presentation_offset + _q_shift + local_pos.rotated(presentation_rotation),
		presentation_rotation + local_rotation, local_scale * _q_scale * float(DRAW_SCALE.get(_dog_breed(), 1.0)))


# How far into each part of her quirk she is this frame (0 with none playing).
var _q_sniff := 0.0       # Millie: nose down...
var _q_sweep := 0.0       # ...and the head swept side to side, -1..1
var _q_stretch := 0.0     # Pipa: front legs out
var _q_sit := 0.0         # Mochi: sat down
var _q_snort := 0.0       # ...the puff of a snort, 0..1 as it spreads
var _q_lie := 0.0         # Bruna: lying down, head up
var _q_tilt := 0.0        # Tito: the head tilt after the tremble
var _q_dig := 0.0         # Perla: a quick scrabble at the ground
var _q_perk := 0.0        # Duna: ears up tall, listening
var _q_look := 0.0        # how far her head is turned to your human
var _q_look_ang := 0.0


func _quirk_pose(t: float) -> void:
	_q_shift = Vector2.ZERO
	_q_scale = Vector2.ONE
	_q_sniff = 0.0
	_q_sweep = 0.0
	_q_stretch = 0.0
	_q_sit = 0.0
	_q_snort = 0.0
	_q_lie = 0.0
	_q_tilt = 0.0
	_q_look = 0.0
	_q_dig = 0.0
	_q_perk = 0.0
	if quirk == "":
		return
	var u := quirk_u
	var side := facing.orthogonal()
	match quirk:
		"sniff":
			_q_sniff = smoothstep(0.0, 0.15, u) * (1.0 - smoothstep(0.85, 1.0, u))
			_q_sweep = sin(u * TAU * 2.0) * _q_sniff
		"stretch":
			_q_stretch = smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(0.52, 0.66, u))
			var shiver := smoothstep(0.6, 0.66, u) * (1.0 - smoothstep(0.9, 1.0, u))
			_q_shift = side * sin(t * 75.0) * 1.3 * shiver
		"sit":
			# down heavily: quick, with a thump of squash as she lands
			_q_sit = smoothstep(0.0, 0.1, u) * (1.0 - smoothstep(0.88, 1.0, u))
			var thump := clampf(1.0 - absf(u - 0.11) / 0.05, 0.0, 1.0)
			_q_scale = Vector2(1.0 + 0.08 * thump, 1.0 - 0.06 * thump)
			_q_look = smoothstep(0.12, 0.25, u) * (1.0 - smoothstep(0.85, 0.95, u))
			if _quirk_n % 2 == 0:
				_q_snort = clampf((u - 0.55) / 0.25, 0.0, 1.0) if u >= 0.55 and u < 0.8 else 0.0
		"lie":
			_q_lie = smoothstep(0.0, 0.2, u) * (1.0 - smoothstep(0.85, 1.0, u))
			_q_look = _q_lie
		"scrabble":
			# the ratter at a smell in the ground: a quick dig, then a look up
			_q_dig = smoothstep(0.0, 0.1, u) * (1.0 - smoothstep(0.55, 0.65, u))
			_q_look = smoothstep(0.65, 0.75, u) * (1.0 - smoothstep(0.9, 1.0, u))
		"listen":
			# the hound hears something: ears up tall, her head turning to it
			_q_perk = smoothstep(0.0, 0.12, u) * (1.0 - smoothstep(0.85, 1.0, u))
			_q_sweep = sin(u * PI * 1.5) * 0.6 * _q_perk
		"tremble":
			var shake := smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.5, 0.58, u))
			_q_shift = side * sin(t * 62.0) * 0.8 * shake + facing * sin(t * 47.0) * 0.4 * shake
			_q_tilt = smoothstep(0.6, 0.64, u) * (1.0 - smoothstep(0.9, 1.0, u))
	if _q_look > 0.0:
		# at your human on a walk; in the wardrobe, up at whoever is looking
		_q_look_ang = 0.6
		if not preview_mode and main != null and main.get("human") != null:
			var to: Vector2 = (main.human.global_position - global_position).rotated(-global_rotation)
			_q_look_ang = clampf(facing.angle_to(to), -1.3, 1.3)


# gait by surface (see tick): steps per distance, and how long each step is
func _cadence() -> float:
	var mult := 1.0
	var breed := _dog_breed()
	if breed == "ratonero bodeguero":
		mult = 1.22
	elif breed == "podenco":
		mult = 0.98
	elif breed == "french bulldog":
		mult = 1.25
	elif breed == "galgo":
		mult = 0.95
	elif breed == "gos d'atura":
		mult = 1.04
	elif breed == "chihuahua":
		mult = 1.35
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
	if breed == "ratonero bodeguero":
		mult = 0.86
	elif breed == "podenco":
		mult = 1.14
	elif breed == "french bulldog":
		mult = 0.80
	elif breed == "galgo":
		mult = 1.20
	elif breed == "gos d'atura":
		mult = 1.05
	elif breed == "chihuahua":
		mult = 0.70
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


# the head radius of the frame a pricked-eared breed is drawn on
static func head_r_of(podenco: bool) -> float:
	return 5.8 if podenco else 7.0


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
	var dig_u := maxf(clampf(digging, 0.0, 1.0), _q_dig)
	var sniff_u := maxf(clampf(sniffing, 0.0, 1.0), _q_sniff)
	var drink_u := clampf(drinking, 0.0, 1.0)
	var bk := sin(clampf(bark_anim / 0.35, 0.0, 1.0) * PI) if bark_anim > 0.0 else 0.0
	var mood_id := int(main.mood.active) if (main != null and main.mood != null) else 0
	var mood_int := clampf(float(main.mood.intensity), 0.0, 1.0) if (main != null and main.mood != null) else 0.0
	var side := facing.orthogonal()
	var look := _dog_breed()
	var breed: String = BODY_PLAN.get(look, look)
	var is_perla := look == "ratonero bodeguero"
	var is_duna := look == "podenco"
	var is_galgo := breed == "galgo"
	var is_frenchie := breed == "french bulldog"
	var is_gos := breed == "gos d'atura"
	var is_tito := breed == "chihuahua"
	var shoulder := facing * ((3.8 if is_tito else (6.8 if is_gos else (4.6 if is_frenchie else (7.5 if is_galgo else 6.0)))) - 1.5 * dig_u)
	var hside := hip_dir.orthogonal()
	if swimming:
		# expanding wake rings behind her happy paddling self
		for i in range(3):
			var rr := fmod(t * 1.4 + i * 0.45, 1.35)
			_b.draw_arc(-facing * 6.0, 12.0 + rr * 26.0, 0, TAU, 22, Color(0.82, 0.9, 1.0, 0.32 * (1.0 - rr / 1.35)), 2.0)
	# THE WIGGLE: the rump swings with the gait
	var b_spd := base_speed()
	var wiggle := hside * sin(gait) * clampf(_draw_speed() / b_spd, 0.0, 1.0) * (2.2 if is_tito else (3.5 if is_frenchie else (2.8 if is_gos else 2.6)))
	# sat, the rump comes in under her; lying, a little
	var hip := shoulder + hip_dir * (10.5 if is_tito else (18.5 if is_gos else (12.5 if is_frenchie else (22.0 if is_galgo else 17.0)))) \
		* (1.0 - 0.4 * _q_sit - 0.08 * _q_lie) + wiggle
	if is_tito and (_draw_speed() < 6.0 or crouching):
		hip += hside * (sin(t * 36.0) * 0.4)
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
	var tail_curl_sgn := 1.0 if facing.x >= -0.01 else -1.0
	if is_perla:
		# the ratonero's short tail, carried up and wagged hard
		var tdir := hip_dir.rotated(tail_angle_bias)
		var tp := hip + hip_dir * 3.5
		for s in range(2):
			tdir = tdir.rotated(sin(t * wag_speed * 1.2 - float(s) * 0.8) * wag_amp * 1.1)
			var nxt := tp + tdir * (6.0 - float(s) * 1.6) * tail_len_scale
			_b.draw_line(tp, nxt, fur_dark, 3.0 - float(s) * 0.9)
			tp = nxt
		_b.draw_circle(tp, 1.2, MARK_WHITE)
	elif is_frenchie:
		# French bulldog natural short screw / stub tail, wiggling merrily on the rump
		var nub_wag := sin(t * wag_speed) * (wag_amp * 0.75)
		var tdir := hip_dir.rotated(tail_angle_bias + nub_wag)
		var tp := hip + hip_dir * 3.0
		_b.draw_circle(tp, 2.9, fur_dark)
		_b.draw_circle(tp + tdir * 2.6, 2.2, fur)
		_b.draw_circle(tp + tdir * 4.2, 1.5, fur_dark.darkened(0.2))
	elif is_gos:
		# Gos d'atura long feathered plume tail (cua plomosa) with sabre curve
		var tail_scale: float = tail_len_scale * 1.15
		var tp := hip + hip_dir * (4.0 * tail_scale)
		var tdir := hip_dir.rotated(tail_angle_bias)
		var widths: Array = [3.8, 3.2, 2.4]
		for s in range(3):
			tdir = tdir.rotated(sin(t * wag_speed - s * 0.9) * wag_amp)
			if s >= 1:
				tdir = tdir.rotated(0.20 * tail_curl_sgn)
			var seg_len: float = (10.0 - s * 1.5) * tail_scale
			var nxt := tp + tdir * seg_len
			_b.draw_line(tp, nxt, fur_dark, widths[s])
			var feather_dir := tdir.orthogonal() * tail_curl_sgn
			_b.draw_line(tp.lerp(nxt, 0.5), nxt + (feather_dir * 0.5 + tdir * 0.6) * (3.0 - float(s) * 0.6), fur, 1.8)
			tp = nxt
	elif is_tito:
		# Chihuahua high-carried sickle tail (cua en falç) arching over the rump
		var tail_scale: float = tail_len_scale * 0.75
		var tp := hip + hip_dir * (3.0 * tail_scale)
		var tdir := hip_dir.rotated(tail_angle_bias)
		var widths: Array = [2.2, 1.6, 1.0]
		for s in range(3):
			tdir = tdir.rotated(sin(t * (wag_speed * 1.35) - float(s) * 0.8) * (wag_amp * 0.85))
			tdir = tdir.rotated(0.28 * tail_curl_sgn)
			var seg_len: float = (5.5 - float(s) * 0.9) * tail_scale
			var nxt := tp + tdir * seg_len
			_b.draw_line(tp, nxt, fur_dark, widths[s])
			tp = nxt
	else:
		var tail_scale: float = tail_len_scale * (1.35 if is_galgo else 1.0)
		var tp := hip + hip_dir * (4.0 * tail_scale)
		var tdir := hip_dir.rotated(tail_angle_bias)
		var widths: Array = [2.4, 1.8, 1.1] if is_galgo else [3.2, 2.4, 1.7]
		for s in range(3):
			tdir = tdir.rotated(sin(t * wag_speed - s * 0.9) * wag_amp)
			if is_galgo and s == 2:
				tdir = tdir.rotated(0.32 * tail_curl_sgn)
			var seg_len: float = (11.0 - s * 1.8) if is_galgo else (9.0 - s * 1.5)
			var nxt := tp + tdir * seg_len * tail_scale
			_b.draw_line(tp, nxt, fur_dark, widths[s])
			tp = nxt
	# four legs, trot gait: diagonal pairs move together, tucked when crouching,
	# scrabbling rapidly in front when digging up a buried bone
	# _stride() already carries the breed's stride
	var amp := 0.0 if crouching else clampf(_draw_speed() / b_spd, 0.0, 1.0) * 5.5 * _stride()
	var ph := sin(gait)
	var dig_scrabble := sin(t * 28.0) * 4.8 * dig_u
	# white-tipped paws, like she stepped in paint and regrets nothing
	var paw := Color(0.78, 0.76, 0.73)
	if surface == Surfaces.S.MUD:
		# sunk in it to the ankles
		paw = Color(0.36, 0.28, 0.20)
	# braced (the rope tug), the front paws dig in out ahead and the back
	# paws spread
	var front_reach := (3.8 if is_tito else (6.5 if is_gos else (4.5 if is_frenchie else (8.0 if is_galgo else 6.0)))) + brace * 3.5 + 2.5 * dig_u
	var paw_r := 1.7 if is_tito else (3.2 if is_gos else (3.4 if is_frenchie else (2.5 if is_galgo else 3.0)))
	var front_spread := 5.2 if is_tito else (8.2 if is_gos else (9.2 if is_frenchie else (6.8 if is_galgo else 7.5)))
	if quirk != "":
		# the stretch's forelegs out long; lying, paws out in front together
		front_reach += 13.0 * _q_stretch + 7.0 * _q_lie
		front_spread += 0.6 * _q_stretch + 1.8 * _q_lie
	_b.draw_circle(shoulder + side * front_spread + facing * (front_reach + ph * amp + dig_scrabble), paw_r, paw)
	_b.draw_circle(shoulder - side * front_spread + facing * (front_reach - ph * amp - dig_scrabble), paw_r, paw)
	if dig_u > 0.05:
		# clods of earth kicked back behind her scrabbling front paws
		for ci in range(3):
			var cp := fmod(t * 7.5 + float(ci) * 0.33, 1.0)
			var clod_at := shoulder - facing * (4.0 + cp * 15.0) + side * (float(ci - 1) * 6.5)
			_b.draw_circle(clod_at, (2.6 - cp * 1.4) * dig_u, Color(0.38, 0.29, 0.20, 0.75 * (1.0 - cp) * dig_u))
	var rear_reach := 1.0 if crouching else (2.8 if is_tito else (4.4 if is_gos else (3.2 if is_frenchie else (5.5 if is_galgo else 4.0))))
	var rear_spread := (4.8 if is_tito else (7.8 if is_gos else (8.4 if is_frenchie else (5.8 if is_galgo else 7.0)))) + brace * 1.5
	if quirk != "":
		# sat, the hind paws come forward under her; lying, out to the side
		rear_reach += 3.0 * _q_sit - 1.5 * _q_lie
		rear_spread += 1.2 * _q_sit + 3.0 * _q_lie
	_b.draw_circle(hip + hside * rear_spread - hip_dir * (rear_reach - ph * amp * 0.8), paw_r + (0.1 if is_frenchie else 0.2), paw)
	_b.draw_circle(hip - hside * rear_spread - hip_dir * (rear_reach + ph * amp * 0.8), paw_r + (0.1 if is_frenchie else 0.2), paw)
	# lean street-dog torso, hinged; the rump drops into the squat. A rim a
	# shade darker on the side away from the light first, then the fur, then
	# the light along her back: plasticine, not a flat cut-out
	var hip_r := (5.4 if is_tito else (9.2 if is_gos else (8.8 if is_frenchie else (7.0 if is_galgo else 10.5)))) if crouching else (4.6 if is_tito else (8.2 if is_gos else (7.6 if is_frenchie else (5.6 if is_galgo else 9.0))))
	var shoulder_r := 5.2 if is_tito else (8.8 if is_gos else (9.8 if is_frenchie else (8.2 if is_galgo else 7.4)))
	if _draw_speed() < 5.0 and not crouching:
		shoulder_r += sin(t * 3.2) * (0.60 if is_frenchie else 0.45)
	if is_frenchie and planted and not crouching:
		shoulder_r += 1.0
		hip_r += 0.8
	if quirk != "":
		# the chest down in the stretch; haunches spread sat; flat out lying
		shoulder_r += 1.6 * _q_lie - 1.2 * _q_stretch
		hip_r += 1.8 * _q_sit + 2.0 * _q_lie
	var rim := Vector2(1.2, 1.6)
	# the ratonero is a white dog, her coat's colour a saddle over her back
	var body_fur: Color = MARK_WHITE if is_perla else fur
	_b.draw_colored_polygon(_body_points(shoulder + rim, hip + rim, shoulder_r, hip_r), body_fur.darkened(0.25) if is_perla else fur_dark.darkened(0.25))
	_b.draw_colored_polygon(_body_points(shoulder, hip, shoulder_r, hip_r), body_fur)
	if is_perla:
		_b.draw_colored_polygon(_body_points(shoulder.lerp(hip, 0.42), shoulder.lerp(hip, 0.80), shoulder_r * 0.55, hip_r * 0.58), fur)
	_b.draw_colored_polygon(_body_points(shoulder + LIGHT_DIR * 2.6, hip + LIGHT_DIR * 2.6, (2.8 if is_tito else (5.0 if is_gos else (5.6 if is_frenchie else (4.6 if is_galgo else 4.2)))), (2.4 if is_tito else (4.4 if is_gos else (4.0 if is_frenchie else (3.4 if is_galgo else 4.6))))),
		fur.lightened(0.10))
	if is_duna:
		# the podenco's white chest
		_b.draw_circle(shoulder + facing * 1.5, shoulder_r * 0.5, MARK_WHITE)
	if is_gos:
		# Soft backward-swept shaggy locks along the flanks and haunches
		for fi in range(3):
			var u: float = 0.28 + float(fi) * 0.24
			var fl_center := shoulder.lerp(hip, u)
			var fl_w: float = shoulder_r * (1.0 - u) + hip_r * u - 0.6
			var hair_wobble := sin(t * 7.0 + float(fi) * 1.5) * 0.45
			for sgn: float in [-1.0, 1.0]:
				var fp: Vector2 = fl_center + side * (fl_w * sgn)
				var tip: Vector2 = fp + side * ((1.2 + hair_wobble) * sgn) + hip_dir * 4.2
				_b.draw_line(fp, tip, fur_dark, 2.6)
				_b.draw_line(fp + hip_dir * 0.6, tip - side * sgn * 0.3, fur, 1.8)
		# Muck speckles clinging to her coat when wet_paws > 0.0
		if main != null and main.wet_paws > 0.0 and main.SUBSTANCES.has(main.paw_kind):
			var mcol: Color = (main.SUBSTANCES[main.paw_kind] as Dictionary).col
			for mi in range(5):
				var mu: float = 0.15 + float(mi) * 0.18
				var mw: float = shoulder_r * (1.0 - mu) + hip_r * mu + 0.6
				var mp := shoulder.lerp(hip, mu) + side * (mw * (1.0 if mi % 2 == 0 else -1.0))
				_b.draw_circle(mp, 1.4, mcol)
		# Fresh coat grooming glints when main.fresh_coat_t > 0.0
		if main != null and main.fresh_coat_t > 0.0:
			var st: float = AnimClock.msec() * 0.006
			for si in range(4):
				var su: float = 0.2 + float(si) * 0.22
				var sw: float = (shoulder_r * (1.0 - su) + hip_r * su + 4.0) * (1.0 if si % 2 == 0 else -1.0)
				var sp: Vector2 = shoulder.lerp(hip, su) + side * sw
				var sa: float = 0.5 + 0.5 * sin(st * 4.0 + float(si) * 1.57)
				if sa > 0.25:
					var scol := Color(1.0, 0.95, 0.70, sa * 0.85)
					_b.draw_line(sp - Vector2(2.5, 0), sp + Vector2(2.5, 0), scol, 1.4)
					_b.draw_line(sp - Vector2(0, 2.5), sp + Vector2(0, 2.5), scol, 1.4)
					_b.draw_circle(sp, 0.9, Color.WHITE)
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
	var strap_w := 5.0 if is_tito else (8.6 if is_gos else (9.6 if is_frenchie else (7.5 if is_galgo else 8.0)))
	var strap_thick := 3.8 if is_tito else (6.5 if is_gos else (7.0 if is_frenchie else (6.5 if is_galgo else 6.0)))
	_b.draw_line(shoulder + side * strap_w, shoulder - side * strap_w, col, strap_thick)
	_b.draw_circle(shoulder, 1.5 if is_tito else (2.4 if is_frenchie else 2.2), Color(0.3, 0.3, 0.32))
	_leash_clip(shoulder)
	var neck := shoulder + facing * (4.2 if is_tito else (7.2 if is_gos else (5.5 if is_frenchie else (9.0 if is_galgo else 6.5))))
	var neck_w := 3.6 if is_tito else (5.8 if is_gos else (6.2 if is_frenchie else (4.5 if is_galgo else 5.5)))
	var neck_thick := 2.4 if is_tito else (3.8 if is_gos else (4.5 if is_frenchie else (4.0 if is_galgo else 3.0)))
	_b.draw_line(neck + side * neck_w, neck - side * neck_w, col, neck_thick)
	# the way her head points: her facing, but for a quirk turning it on the
	# neck (to look at your human, or sweeping a sniff from side to side)
	var hf := facing
	var hs := side
	if quirk != "":
		hf = facing.rotated(_q_look_ang * _q_look + 0.4 * _q_sweep + 0.5 * _q_tilt)
		hs = hf.orthogonal()
	# head with a LONG nose; stretches forward and twitches when sniffing,
	# dips when digging/drinking, surges forward on a bark
	var sniff_twitch := hs * (sin(t * 22.0) * 1.5 * sniff_u)
	var head_reach := 6.5 if is_tito else (10.8 if is_gos else (8.0 if is_frenchie else (13.5 if is_galgo else 10.0)))
	if quirk != "":
		# low and long along the stretched forelegs; drawn back to look up sat
		# or lying with her head up
		head_reach += 3.5 * _q_stretch - 1.2 * _q_sit - 1.5 * _q_lie
	var head := shoulder + hf * (head_reach + 2.0 * sniff_u + 1.2 * drink_u - 1.4 * dig_u + 2.0 * bk) + sniff_twitch
	if _q_tilt > 0.0:
		head += hs * 2.0 * _q_tilt
	var flop := sin(gait) * 1.6
	var ear_perk := 2.2 * sniff_u + 1.8 * bk - (2.4 * mood_int if mood_id == 1 else 0.0) + 3.0 * _q_perk
	var ear_flare := 1.8 * bk + (0.9 * mood_int if mood_id == 4 else 0.0)
	var speed_ratio := clampf(_draw_speed() / b_spd, 0.0, 1.8)
	var turbo_f := 1.0 if turbo_active else 0.0
	var wind_trail := speed_ratio * 3.2 + turbo_f * 2.6
	var flutter := sin(t * 34.0) * (0.6 * speed_ratio + 1.4 * turbo_f)
	var centrifugal_sway := clampf((-facing).cross(hip_dir) * 6.0, -2.8, 2.8)
	var twitch := 0.0
	var twitch_side := 1.0
	if _draw_speed() < 5.0 and not crouching:
		var idle_cycle := fmod(t + 0.4, 4.2)
		if idle_cycle < 0.22:
			twitch = sin(idle_cycle / 0.22 * TAU) * 1.8
			twitch_side = -1.0 if fmod(t, 8.4) < 4.2 else 1.0
	if _q_lie > 0.0:
		# lying watching him, the ears up and flicking, one then the other
		ear_perk += 1.6 * _q_lie
		var flick := fmod(quirk_u * 5.0, 1.0)
		if flick < 0.3:
			twitch = sin(flick / 0.3 * TAU) * 3.2 * _q_lie
			twitch_side = -1.0 if int(quirk_u * 5.0) % 2 == 0 else 1.0
	if is_duna or is_perla:
		# pricked ears, seen from above as triangles standing out to the sides
		# and a little back: the podenco's huge, a hound listening for
		# rabbits; the ratonero's small and sharp, the tips folded forward
		var big := is_duna
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + hs * (head_r_of(big) * 0.55) * sg - hf * 1.2
			var back := (0.55 if big else 0.35) + wind_trail * 0.05 - ear_perk * 0.06 + tw * 0.08
			var ear_up := (hs * sg - hf * back).normalized().rotated(0.5 * _q_tilt)
			var ear_out := ear_up.orthogonal()
			var ear_h := (13.0 if big else 8.4) + ear_perk * (0.9 if big else 0.6)
			var base_w := 3.6 if big else 3.2
			var tip := root + ear_up * ear_h
			_b.draw_colored_polygon(PackedVector2Array([root - ear_out * base_w, root + ear_out * base_w, tip]), fur_dark)
			var inner_col := Color(clampf(fur_dark.r * 1.4 + 0.24, 0.0, 1.0),
				clampf(fur_dark.g * 1.1 + 0.15, 0.0, 1.0), clampf(fur_dark.b * 1.1 + 0.15, 0.0, 1.0))
			_b.draw_colored_polygon(PackedVector2Array([root - ear_out * (base_w * 0.45) + ear_up * 1.5,
				root + ear_out * (base_w * 0.45) + ear_up * 1.5, tip - ear_up * (ear_h * 0.25)]), inner_col)
			if not big:
				_b.draw_line(tip, tip + hf * 1.8 - ear_up * 0.6, fur_dark.darkened(0.2), 1.6)
	elif is_frenchie:
		# Iconic Frenchie "bat ears": upright, tall, broad-based with rounded tops,
		# facing forward/outward with warm inner ear leather visible
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + hs * 4.6 * sg - hf * 0.5
			var ear_angle := 0.22 * sg + tw * 0.08 - wind_trail * 0.04
			var ear_up := hf.rotated(ear_angle)
			var ear_out := hs.rotated(ear_angle) * sg
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
	elif is_gos:
		# Gos d'atura drop ears: triangular hanging ears thickly thatched with long shaggy fringe
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + hs * 4.6 * sg - hf * 0.5
			var ear_sway := (sin(gait * 1.5) * 1.2 + centrifugal_sway * 0.6 + tw * 0.6) * sg
			var ear_side := (4.2 + ear_flare * 0.5 + ear_sway) * sg
			var ear_drop := 7.5 + wind_trail * 0.5 - ear_perk * 0.5
			var tip := head + hs * ear_side - hf * ear_drop
			var ear_pts := PackedVector2Array([
				root + hf * 1.2 - hs * sg * 1.0,
				root + hs * sg * 1.8,
				tip + hs * sg * 1.6,
				tip - hf * 2.2,
				tip - hs * sg * 1.4
			])
			_b.draw_colored_polygon(ear_pts, fur_dark)
			var fringe_tip := tip - hf * 2.5 + hs * sg * 0.8
			_b.draw_line(tip, fringe_tip, fur_dark.darkened(0.2), 2.2)
			_b.draw_line(tip + hs * sg * 1.2, fringe_tip + hs * sg * 0.6, fur, 1.8)
	elif is_tito:
		# Giant upright satellite ears: tall flared triangular bat ears with warm inner blush
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + hs * 3.4 * sg - hf * 0.4
			# the head tilt cocks both ears one way: one up, one out
			var ear_flare_ang := (0.65 + ear_flare * 0.3) * sg + tw * 0.15 - wind_trail * 0.05 + 0.7 * _q_tilt
			var ear_up := hf.rotated(ear_flare_ang)
			var ear_out := hs.rotated(ear_flare_ang) * sg
			var ear_h := 8.8 + ear_perk * 0.9
			var base_w := 2.8
			var ear_p0 := root - ear_out * 1.0 - ear_up * 0.8
			var ear_p1 := root + ear_out * base_w
			var ear_tip := root + ear_out * 3.2 + ear_up * ear_h
			var ear_p3 := root - ear_out * 0.6 + ear_up * (ear_h * 0.65)
			_b.draw_colored_polygon(PackedVector2Array([
				ear_p0,
				ear_p1,
				ear_tip,
				ear_p3,
			]), fur_dark)
			var inner_col := Color(
				clampf(fur_dark.r * 1.45 + 0.22, 0.0, 1.0),
				clampf(fur_dark.g * 1.15 + 0.14, 0.0, 1.0),
				clampf(fur_dark.b * 1.15 + 0.14, 0.0, 1.0)
			)
			_b.draw_colored_polygon(PackedVector2Array([
				root + ear_out * 0.2 + ear_up * 0.8,
				root + ear_out * (base_w - 0.7) + ear_up * 1.2,
				ear_tip - ear_out * 0.6 - ear_up * 1.4,
				ear_p3 + ear_out * 0.3 + ear_up * 0.4,
			]), inner_col)
	elif is_galgo:
		# folded rose ears laying streamlined along the nape of the neck
		for sg: float in [-1.0, 1.0]:
			var root := head + hs * 4.0 * sg - hf * 0.5
			var ear_side := (3.8 + ear_flare * 0.4 + centrifugal_sway * 0.4) * sg
			var ear_back := 6.5 + wind_trail * 0.4 - ear_perk * 0.6
			var tip := head + hs * ear_side - hf * ear_back
			_b.draw_colored_polygon(PackedVector2Array([
				root + hf * 1.0 - hs * sg * 0.8,
				root + hs * sg * 1.2,
				tip + hs * sg * 1.2,
				tip - hf * 1.5,
				tip - hs * sg * 1.0
			]), fur_dark)
	else:
		# big floppy ears, under the skull, swinging slightly with the stride,
		# trailing back in the slipstream at speed and swaying with turns
		for sg: float in [-1.0, 1.0]:
			var tw: float = twitch if sg == twitch_side else 0.0
			var root := head + hs * 5.0 * sg + hf * 1.0
			var ear_side := (7.6 + ear_flare + flop * 0.7 * sg + centrifugal_sway * 0.85 + tw * 0.5) * sg
			var ear_back := 8.0 + wind_trail + flutter * sg - ear_perk
			var tip := head + hs * ear_side - hf * ear_back
			_b.draw_colored_polygon(PackedVector2Array([root + hf * 1.6 - hs * sg * 1.0, root + hs * sg * 1.6,
				tip + hs * sg * 1.8, tip - hf * 2.0, tip - hs * sg * 1.6]), fur_dark)
	var head_r := 5.5 if is_tito else (7.8 if is_gos else (8.2 if is_frenchie else (5.8 if is_galgo else 7.0)))
	_b.draw_circle(head + rim * 0.7, head_r, fur_dark.darkened(0.25))
	_b.draw_circle(head, head_r, fur)
	if is_perla or is_duna:
		# a white blaze up the middle of her face; the ratonero's tan
		# eyebrow spots either side of it
		_b.draw_line(head - hf * (head_r * 0.7), head + hf * (head_r * 0.9), MARK_WHITE, 2.2 if is_perla else 1.8)
		if is_perla:
			for sg5: float in [-1.0, 1.0]:
				_b.draw_circle(head + hf * 0.4 + hs * 2.6 * sg5, 1.3, MARK_TAN)
	# open jaw and pink tongue during a bark or while lapping water
	if bk > 0.05:
		var jaw_at := head + hf * ((4.8 if is_tito else (6.2 if is_frenchie else 9.5)) + bk * 2.2)
		var jaw_r := 2.2 if is_tito else (4.0 if is_frenchie else 3.2)
		_b.draw_circle(jaw_at, jaw_r, Color(0.38, 0.10, 0.12))
		_b.draw_circle(jaw_at + hf * 1.0, 1.5 if is_tito else (2.5 if is_frenchie else 2.1), Color(0.92, 0.48, 0.54))
	elif drink_u > 0.05:
		var lap := maxf(0.0, sin(t * 16.0)) * drink_u
		if lap > 0.05:
			_b.draw_circle(head + hf * ((6.2 if is_tito else (8.0 if is_frenchie else 11.0)) + lap * 3.8), 1.5 if is_tito else (2.2 if is_frenchie else 2.0), Color(0.94, 0.52, 0.58))
		for di in range(2):
			var dp := fmod(t * 3.4 + float(di) * 0.5, 1.0)
			var drop_dir := hs * (1.0 if di == 0 else -1.0)
			_b.draw_circle(head + hf * ((6.8 if is_tito else (8.5 if is_frenchie else 11.5))) + drop_dir * (2.0 + dp * 4.0 if is_tito else (3.0 + dp * 6.0)), (1.0 if is_tito else 1.4) * (1.0 - dp) * drink_u,
				Color(0.76, 0.90, 1.0, 0.65 * (1.0 - dp) * drink_u))
	# what she holds sits between her jaws, under the muzzle that closes over it
	var muz_reach := 5.2 if is_frenchie else (11.2 if is_gos else (4.8 if is_tito else (13.5 if is_galgo else 10.5)))
	var jaw_w := 4.6 if is_frenchie else (3.8 if is_gos else (2.3 if is_tito else (2.4 if is_galgo else 3.4)))
	_bite_local = head + hf * (muz_reach * 0.6)
	if held != null and is_instance_valid(held):
		held.draw_held(_b, _bite_local, hf, hs, jaw_w)
	# the muzzle: tapering out to the nose, not a stick
	if is_frenchie:
		var muz_len := 5.2
		var muzzle := PackedVector2Array([
			head + hs * 5.2 + hf * 1.5,
			head + hs * 4.0 + hf * muz_len,
			head - hs * 4.0 + hf * muz_len,
			head - hs * 5.2 + hf * 1.5
		])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_line(head + hs * 3.6 + hf * 3.0, head - hs * 3.6 + hf * 3.0, fur_dark.darkened(0.2), 2.2)
		_b.draw_circle(head + hf * 1.5, 3.8, Color(grizzle, 0.45))
		_b.draw_circle(head + LIGHT_DIR * 2.2, 2.2, fur.lightened(0.12))
	elif is_gos:
		var muz_len := 11.2
		var muzzle := PackedVector2Array([
			head + hs * 4.4 + hf * 2.0,
			head + hs * 3.2 + hf * muz_len,
			head - hs * 3.2 + hf * muz_len,
			head - hs * 4.4 + hf * 2.0
		])
		_b.draw_colored_polygon(muzzle, fur)
		for sgn: float in [-1.0, 1.0]:
			var m_base: Vector2 = head + hs * (3.0 * sgn) + hf * 7.2
			var m_tip: Vector2 = head + hs * (4.6 * sgn) + hf * (5.2 + sin(t * 12.0) * 0.3 * sniff_u)
			_b.draw_line(m_base, m_tip, fur_dark, 2.2)
			_b.draw_line(m_base + hf * 1.2, m_tip + hf * 1.4, Color(grizzle, 0.55), 1.6)
		_b.draw_circle(head + hf * 4.5, 3.6, Color(grizzle, 0.42))
		_b.draw_circle(head + LIGHT_DIR * 2.3, 2.3, fur.lightened(0.12))
	elif is_tito:
		var muz_len := 4.8
		var muzzle := PackedVector2Array([
			head + hs * 3.0 + hf * 1.2,
			head + hs * 1.6 + hf * muz_len,
			head - hs * 1.6 + hf * muz_len,
			head - hs * 3.0 + hf * 1.2
		])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_circle(head + hf * 1.2, 2.4, Color(grizzle, 0.4))
		_b.draw_circle(head + LIGHT_DIR * 1.6, 1.6, fur.lightened(0.12))
	elif is_galgo:
		var muz_len := 13.5
		var muzzle := PackedVector2Array([
			head + hs * 3.4 + hf * 2.0,
			head + hs * 1.5 + hf * muz_len,
			head - hs * 1.5 + hf * muz_len,
			head - hs * 3.4 + hf * 2.0
		])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_circle(head + hf * 2.0, 3.2, Color(grizzle, 0.45))
		_b.draw_line(head + hf * 3.0, head + hf * (muz_len - 1.5), Color(grizzle, 0.5), 2.4)
		_b.draw_circle(head - hf * 2.0, 2.6, Color(grizzle, 0.3))
		_b.draw_circle(head + LIGHT_DIR * 2.0, 2.0, fur.lightened(0.12))
	else:
		var muzzle := PackedVector2Array([head + hs * 4.6 + hf * 2.0, head + hs * 2.2 + hf * 10.5,
			head - hs * 2.2 + hf * 10.5, head - hs * 4.6 + hf * 2.0])
		_b.draw_colored_polygon(muzzle, fur)
		_b.draw_circle(head + hf * 2.0, 4.0, Color(grizzle, 0.45))
		_b.draw_line(head + hf * 3.0, head + hf * 9.0, Color(grizzle, 0.5), 3.0)
		_b.draw_circle(head - hf * 2.5, 3.2, Color(grizzle, 0.3))
		_b.draw_circle(head + LIGHT_DIR * 2.4, 2.4, fur.lightened(0.12))
	# eyes, set back on the skull, with the brows that make her a dog with a
	# plan (the icon's trick)
	if is_frenchie:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + hf * 1.8 + hs * 4.5 * sg2
			_b.draw_circle(eye, 2.2, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + hf * 0.4, 1.35, Color(0.06, 0.05, 0.06))
			_b.draw_line(eye - hf * 2.0 + hs * sg2 * 1.6, eye - hf * 2.4 - hs * sg2 * 1.4,
				Color(grizzle, 0.75), 1.4)
	elif is_gos:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + hf * 2.2 + hs * 3.4 * sg2
			_b.draw_circle(eye, 1.8, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + hf * 0.4, 1.15, Color(0.06, 0.05, 0.06))
			var brow_start := eye - hf * 1.8 + hs * sg2 * 2.2
			var brow_tip := eye + hf * 0.6 - hs * sg2 * 0.4
			_b.draw_line(brow_start, brow_tip, fur_dark, 2.2)
			_b.draw_line(brow_start - hs * sg2 * 0.8, brow_tip + hf * 0.8, fur, 1.6)
	elif is_tito:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + hf * 1.8 + hs * 2.5 * sg2
			_b.draw_circle(eye, 1.65, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + hf * 0.35, 1.15, Color(0.06, 0.05, 0.06))
			_b.draw_circle(eye + LIGHT_DIR * 0.45, 0.42, Color(1, 1, 1, 0.85))
			_b.draw_line(eye - hf * 1.3 + hs * sg2 * 1.1, eye - hf * 1.7 - hs * sg2 * 0.9,
				Color(grizzle, 0.7), 1.0)
	elif is_galgo:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + hf * 2.6 + hs * 2.8 * sg2
			_b.draw_circle(eye, 1.6, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + hf * 0.5, 1.0, Color(0.06, 0.05, 0.06))
			_b.draw_line(eye - hf * 1.5 + hs * sg2 * 1.2, eye - hf * 1.9 - hs * sg2 * 1.0,
				Color(grizzle, 0.75), 1.0)
	else:
		for sg2: float in [-1.0, 1.0]:
			var eye := head + hf * 2.2 + hs * 3.6 * sg2
			_b.draw_circle(eye, 1.9, Color(0.96, 0.94, 0.88))
			_b.draw_circle(eye + hf * 0.5, 1.15, Color(0.06, 0.05, 0.06))
			_b.draw_line(eye - hf * 1.8 + hs * sg2 * 1.6, eye - hf * 2.3 - hs * sg2 * 1.4,
				Color(grizzle, 0.75), 1.2)
	# the nose, with the shine on it
	var nose_len := 5.0 if is_tito else (5.8 if is_frenchie else (11.8 if is_gos else (14.0 if is_galgo else 11.0)))
	var nose_r := 1.8 if is_tito else (3.0 if is_frenchie else (2.6 if is_gos else (2.0 if is_galgo else 2.6)))
	var nose_shine := 0.6 if is_tito else (0.9 if is_frenchie else (0.7 if is_galgo else 0.9))
	var nose_at := head + hf * nose_len + hs * (sin(t * 28.0) * 0.7 * sniff_u)
	if is_frenchie:
		_b.draw_circle(nose_at + hs * 0.9, nose_r * 0.85, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at - hs * 0.9, nose_r * 0.85, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at, nose_r * 0.9, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at + LIGHT_DIR * nose_shine, nose_shine * 0.75, Color(0.55, 0.55, 0.58))
	else:
		_b.draw_circle(nose_at, nose_r, Color(0.05, 0.05, 0.06))
		_b.draw_circle(nose_at + LIGHT_DIR * nose_shine, nose_shine, Color(0.55, 0.55, 0.58))
	if _q_snort > 0.0:
		# the snort: a puff out of each nostril
		for sg3: float in [-1.0, 1.0]:
			_b.draw_circle(nose_at + hf * (3.0 + 9.0 * _q_snort) + hs * sg3 * (1.5 + 5.0 * _q_snort),
				1.6 + 2.4 * _q_snort, Color(0.94, 0.95, 0.97, 0.8 * (1.0 - _q_snort)))
	if sniff_u > 0.05:
		for si in range(2):
			var sp := 1.0 - fmod(t * 2.4 + float(si) * 0.5, 1.0)
			_b.draw_circle(nose_at + hf * (2.5 + sp * 7.0) + hs * (float(si * 2 - 1) * 2.5 * sp),
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
		_b.draw_arc(head + hf * 8.0, 10.0 + r * 34.0, 0, TAU, 24, Color(1, 1, 1, 0.7 * (1.0 - r)), 2.0)
	if poop_cue == 2:
		# a good spot: a breathing green ring on the ground round her
		var k := 0.5 + 0.5 * sin(t * 5.0)
		_b.draw_arc(Vector2(0, 4), 24.0 + k * 3.0, 0, TAU, 28, Color(0.55, 0.95, 0.55, 0.35 + 0.25 * k), 2.5)
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


# The leash clipped to her harness ring: the rope is tied to her middle and
# drawn under her, so the last of it, from the ring to where it comes out
# from under her, is drawn here on top, with the steel clasp on the ring.
func _leash_clip(ring: Vector2) -> void:
	if main == null or main.get("leash") == null or main.leash.get_parent() == null:
		return
	var l: Node2D = main.leash
	if bool(l.detached) or l.pts.size() < 3 or l.dog != self:
		return
	var out: Vector2 = (l.pts[2] - l.pts[0]).rotated(-global_rotation)
	if out.length_squared() < 1.0:
		return
	var exit := out.normalized() * 15.0
	var strap: Color = l.strap_colour()
	_b.draw_line(ring + Vector2(0.6, 0.9), exit + Vector2(0.6, 0.9), Color(0.05, 0.04, 0.06, 0.3), 3.6)
	_b.draw_line(ring, exit, strap.darkened(0.3), 3.4)
	_b.draw_line(ring, exit, strap, 2.0)
	_b.draw_circle(ring, 2.6, Color(0.46, 0.48, 0.52))
	_b.draw_circle(ring + Vector2(-0.6, -0.6), 1.2, Color(0.86, 0.88, 0.92))
