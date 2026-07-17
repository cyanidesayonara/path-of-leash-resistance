extends CharacterBody2D

# The human. Dead weight with a phone. Walks north on autopilot,
# occasionally does something stupid. Telegraphs it first, to be fair.

enum HState { WALK, STOPPED, DRIFT, DASH, SELFIE, FILM, WHIRL, GO_POOP, BAG, GO_BIN, TOSS, STUMBLE, FALLEN }

const WALK_SPEED := 92.0

var state: HState = HState.WALK
var state_t := 0.0
var event_timer := 4.0
var telegraph_t := 0.0
var pending_event: HState = HState.STOPPED
var drift_dir := 1.0
var dash_target := Vector2.ZERO
var pending_bench := false
var sit_after_dash := false
var iframes := 0.0
var halt_t := 0.0
var pull_cd := 0.0
var reel_timer := 5.0
var whirl_pole := Vector2.ZERO
var whirl_dir := 1.0
var whirl_omega := 0.0
var whirl_angle := 0.0
var whirl_turns := 0.0
var whirl_unwound := 0.0
var whirl_pull := 0.0
var just_flung := false
var face_dir := Vector2.UP
var hgait := 0.0
var chain_target := Vector2.ZERO
var carrying_bag := false
var bin_stuck_t := 0.0
var wading := false
var pond_bank_x := 0.0
var homeward := false
var parked := false
var park_target := Vector2.ZERO
var park_throw_t := 0.0
var strain := false
var wobble_seed := 0.0
var main: Node2D
var bubble: Label


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	z_index = 10
	collision_layer = 4
	collision_mask = 1
	wobble_seed = randf() * 10.0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 15.0
	cs.shape = sh
	add_child(cs)
	bubble = Label.new()
	bubble.position = Vector2(-60, -92)
	bubble.size = Vector2(120, 24)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.add_theme_font_size_override("font_size", 16)
	bubble.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	bubble.visible = false
	add_child(bubble)


func is_fallen() -> bool:
	return state == HState.FALLEN


func tick(delta: float) -> void:
	iframes = maxf(0.0, iframes - delta)
	pull_cd = maxf(0.0, pull_cd - delta)
	halt_t = maxf(0.0, halt_t - delta)
	state_t -= delta
	# parked at the off-leash area: shuffle to the bench, then play
	# fetch - throwing the ball out for the dog to bring back
	if parked:
		park_throw_t = maxf(0.0, park_throw_t - delta)
		var to_seat := park_target - global_position
		if to_seat.length() > 6.0:
			velocity = to_seat.normalized() * 70.0
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		if park_throw_t <= 0.0 and not bubble.visible:
			_show_bubble("...")
		return
	# strain is cleared and re-set by main.gd/_apply_leash each frame
	match state:
		HState.FALLEN:
			velocity = Vector2.ZERO
			if state_t <= 0.0:
				state = HState.WALK
				rotation = 0.0
				iframes = 1.5
		HState.STUMBLE:
			velocity = velocity.move_toward(Vector2.ZERO, 550.0 * delta)
			move_and_slide()
			if state_t <= 0.0:
				state = HState.WALK
		HState.STOPPED:
			velocity = velocity.move_toward(Vector2.ZERO, 320.0 * delta)
			move_and_slide()
			if state_t <= 0.0:
				state = HState.WALK
				bubble.visible = false
		HState.SELFIE:
			# shuffles backward for a better angle, oblivious
			velocity = velocity.move_toward(Vector2(0, 22.0), 220.0 * delta)
			move_and_slide()
			if state_t <= 0.0:
				state = HState.WALK
				bubble.visible = false
		HState.FILM:
			# walks backwards while filming, weaving
			var sway := sin(Time.get_ticks_msec() / 250.0) * 30.0
			velocity = velocity.move_toward(Vector2(sway, 62.0), 220.0 * delta)
			move_and_slide()
			if state_t <= 0.0:
				state = HState.WALK
				bubble.visible = false
		HState.GO_POOP:
			# duty overrides doomscrolling: walk to the scene
			var to_poop := chain_target - global_position
			if to_poop.length() < 22.0:
				state = HState.BAG
				state_t = 2.0
				velocity = Vector2.ZERO
				_show_bubble("bagging...")
			else:
				velocity = velocity.move_toward(to_poop.normalized() * 120.0, 300.0 * delta)
				move_and_slide()
		HState.BAG:
			velocity = Vector2.ZERO
			if state_t <= 0.0:
				carrying_bag = true
				main.on_business_picked()
				chain_target = main.nearest_bin(global_position)
				state = HState.GO_BIN
				_show_bubble("where's a bin...")
		HState.GO_BIN:
			var to_bin := chain_target - global_position
			var before_x := global_position
			# close enough, OR wedged against something (a parked van):
			# a stuck owner just lobs the bag from where they stand
			if to_bin.length() < 70.0 or bin_stuck_t > 1.2:
				state = HState.TOSS
				state_t = 0.55
				velocity = Vector2.ZERO
				face_dir = to_bin.normalized()
				bin_stuck_t = 0.0
				_show_bubble("toss...")
			else:
				velocity = velocity.move_toward(to_bin.normalized() * 120.0, 300.0 * delta)
				move_and_slide()
				if global_position.distance_to(before_x) < 0.6:
					bin_stuck_t += delta
				else:
					bin_stuck_t = 0.0
		HState.TOSS:
			velocity = Vector2.ZERO
			if state_t <= 0.0:
				carrying_bag = false
				bubble.visible = false
				main.toss_bag(global_position + face_dir * 14.0, chain_target)
				state = HState.STOPPED
				state_t = 0.8
		HState.WHIRL:
			# cartoon tetherball: choreographed accelerating orbit that
			# runs for exactly as many turns as the rope was wound (the
			# rope free-slips along underneath). Pulling harder spins it
			# up faster - the leash as a pulley.
			whirl_omega = minf(whirl_omega + (8.0 + whirl_pull * 0.016) * delta, 24.0)
			whirl_pull *= 0.9
			var step := whirl_dir * whirl_omega * delta
			whirl_angle += step
			whirl_unwound += absf(step)
			global_position = whirl_pole + Vector2.from_angle(whirl_angle) * 30.0
			velocity = Vector2.from_angle(whirl_angle + whirl_dir * PI / 2.0) * whirl_omega * 30.0
			rotation += whirl_dir * whirl_omega * 1.4 * delta
			# orbit EXACTLY the wound amount (over-orbiting re-wraps the
			# rope the other way and the fling gets arrested), then hold
			# briefly - at most 0.6 extra turn - for the tangent to sweep
			# toward the dog
			if whirl_unwound >= whirl_turns:
				var tangent := Vector2.from_angle(whirl_angle + whirl_dir * PI / 2.0)
				var aim: Vector2 = (main.dog.global_position - global_position).normalized()
				if tangent.dot(aim) > 0.5 or whirl_unwound > whirl_turns + 0.6 * TAU:
					release_whirl()
			if state_t <= 0.0:
				release_whirl()
		_:
			if state == HState.DASH and state_t <= 0.0:
				_end_dash()
			_walk(delta)
	_events(delta)
	_fiddle_with_reel(delta)
	# face the direction of travel - except when deliberately walking
	# backwards (filming, backing up for a selfie)
	hgait += velocity.length() * delta * 0.06
	if velocity.length() > 12.0:
		var ft := velocity.normalized()
		if state == HState.FILM or state == HState.SELFIE:
			ft = -ft
		face_dir = face_dir.slerp(ft, minf(8.0 * delta, 1.0))
		if face_dir.length() < 0.1:
			face_dir = ft
		else:
			face_dir = face_dir.normalized()


func _fiddle_with_reel(delta: float) -> void:
	# constantly fiddles with the retractable leash, independent of the
	# event system: new random length on every "click!"
	if state in [HState.FALLEN, HState.STUMBLE, HState.WHIRL]:
		return
	reel_timer -= delta
	if reel_timer > 0.0:
		return
	if telegraph_t > 0.0:
		reel_timer = 0.5
		return
	reel_timer = randf_range(4.0, 8.0)
	main.set_leash_target(randf_range(170.0, 430.0))
	_show_bubble("click!")
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void:
		if telegraph_t <= 0.0:
			bubble.visible = false)


func _walk(delta: float) -> void:
	if halt_t > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		move_and_slide()
		return
	var t := Time.get_ticks_msec() / 1000.0
	var speed := WALK_SPEED
	var cx: float = main.walk_cx
	var half: float = main.walk_half
	var tx := cx + sin(t * 0.35 + wobble_seed) * minf(110.0, half - 60.0)
	if state == HState.DRIFT:
		tx = cx + drift_dir * (half - 70.0)
		speed = 72.0
		if state_t <= 0.0:
			state = HState.WALK
	# forward is up on the way out, down on the walk home
	var fwd_y := 1.0 if homeward else -1.0
	var dir := Vector2(clampf((tx - global_position.x) / 60.0, -1.0, 1.0) * 0.8, fwd_y).normalized()
	if state == HState.DASH:
		var to_target := dash_target - global_position
		if to_target.length() < 14.0:
			_end_dash()
			velocity = Vector2.ZERO
			return
		dir = to_target.normalized()
		speed = 250.0
	# heavy: momentum builds and bleeds slowly, lunges harder during a dash.
	# No motor sapping while strained: leash tension vs mass (main.gd)
	# decides the tug of war, and the human is the heavy one.
	var accel := 420.0 if state == HState.DASH else 240.0
	if wading:
		# reluctant wader: wants OUT, heads for the nearest bank, slowed
		# by the water and by dignity
		dir = Vector2(signf(pond_bank_x - global_position.x + 0.001), -0.15).normalized()
		speed = 46.0
		accel = 200.0
	velocity = velocity.move_toward(dir * speed, accel * delta)
	move_and_slide()


func _events(delta: float) -> void:
	if state != HState.WALK or halt_t > 0.0:
		return
	if telegraph_t > 0.0:
		telegraph_t -= delta
		if telegraph_t <= 0.0:
			bubble.visible = false
			_fire_event()
		return
	event_timer -= delta
	if event_timer <= 0.0:
		event_timer = randf_range(3.5, 6.5)
		var roll := randf()
		pending_bench = false
		if roll < 0.2:
			pending_event = HState.STOPPED
			_show_bubble("ring ring")
		elif roll < 0.4:
			pending_event = HState.DRIFT
			_show_bubble("typing...")
		elif roll < 0.56:
			pending_event = HState.DASH
			_show_bubble("ooh!")
		elif roll < 0.68:
			pending_event = HState.SELFIE
			_show_bubble("selfie!")
		elif roll < 0.78:
			pending_event = HState.FILM
			_show_bubble("filming...")
		else:
			pending_event = HState.DASH
			pending_bench = true
			_show_bubble("tired...")
		telegraph_t = 0.8


func _fire_event() -> void:
	match pending_event:
		HState.STOPPED:
			state = HState.STOPPED
			state_t = randf_range(1.5, 2.8)
		HState.DRIFT:
			state = HState.DRIFT
			state_t = 1.8
			drift_dir = 1.0 if randf() < 0.5 else -1.0
		HState.SELFIE:
			state = HState.SELFIE
			state_t = 2.2
			_show_bubble("selfie!")
		HState.FILM:
			state = HState.FILM
			state_t = randf_range(1.6, 2.4)
			_show_bubble("filming...")
		HState.DASH:
			var lo: float = main.walk_cx - main.walk_half + 40.0
			var hi: float = main.walk_cx + main.walk_half - 40.0
			if pending_bench:
				var b = main.nearest_bench(global_position)
				if b == null:
					state = HState.STOPPED
					state_t = 2.0
					return
				sit_after_dash = true
				dash_target = b as Vector2
				state = HState.DASH
				state_t = 2.2
			else:
				state = HState.DASH
				state_t = 1.2
				var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, -0.3)).normalized() * randf_range(130.0, 210.0)
				dash_target = global_position + off
				dash_target.x = clampf(dash_target.x, lo, hi)


func _end_dash() -> void:
	if sit_after_dash:
		sit_after_dash = false
		state = HState.STOPPED
		state_t = 3.0
		_show_bubble("just a sec")
	else:
		state = HState.WALK


func _show_bubble(text: String) -> void:
	bubble.text = text
	bubble.visible = true


func is_whirling() -> bool:
	return state == HState.WHIRL


func start_whirl(pole: Vector2, dir: float, turns: float) -> void:
	if state == HState.WHIRL or state == HState.FALLEN:
		return
	state = HState.WHIRL
	state_t = 3.5
	whirl_pole = pole
	whirl_dir = dir
	whirl_turns = clampf(turns, 0.6, 4.0) * TAU
	whirl_unwound = 0.0
	whirl_pull = 0.0
	whirl_angle = (global_position - pole).angle()
	whirl_omega = clampf(velocity.length() / 30.0, 8.0, 14.0)
	telegraph_t = 0.0
	_show_bubble("wheee!")


func flip_whirl() -> void:
	# main.gd noticed the rope winding tighter: the direction guess was
	# wrong. Reverse, and start the unwind count fresh.
	if state != HState.WHIRL:
		return
	whirl_dir = -whirl_dir
	whirl_unwound = 0.0


func release_whirl() -> void:
	if state != HState.WHIRL:
		return
	# launch along the PURE tangent: a tangent ray always moves away from
	# the pole, so getting stuck on it is geometrically impossible. The
	# "toward the dog" part comes from release timing. Fast flings sail
	# PAST the dog, whose turn it then is to get yanked along (the bungee).
	var tangent := Vector2.from_angle(whirl_angle + whirl_dir * PI / 2.0)
	state = HState.STUMBLE
	state_t = 1.0
	rotation = 0.0
	bubble.visible = false
	var speed := clampf(whirl_omega * 30.0 * 1.8, 360.0, 950.0)
	velocity = tangent * speed
	just_flung = true
	main.float_text(global_position, "AAAA", Color(1, 0.9, 0.6))
	main.shake_t = maxf(float(main.shake_t), 0.35)


func throw_pose() -> void:
	park_throw_t = 0.5
	_show_bubble("go get it!")
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(func() -> void:
		if not parked or park_throw_t <= 0.0:
			bubble.visible = false)


func park_at(seat: Vector2) -> void:
	parked = true
	park_target = seat
	state = HState.WALK
	state_t = 0.0
	telegraph_t = 0.0
	carrying_bag = false


func unpark() -> void:
	parked = false
	homeward = true
	bubble.visible = false
	_show_bubble("okay, home time")


func is_available_for_chore() -> bool:
	return state == HState.WALK and not parked


func fetch_poop(spot: Vector2) -> void:
	if state in [HState.FALLEN, HState.WHIRL, HState.GO_POOP, HState.BAG, HState.GO_BIN, HState.TOSS]:
		return
	state = HState.GO_POOP
	chain_target = spot
	telegraph_t = 0.0
	_show_bubble("ugh, hold on")


func show_nag() -> void:
	# opinions about where dogs belong, delivered without looking up
	if state != HState.WALK or telegraph_t > 0.0:
		return
	_show_bubble("come on!")
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void:
		if telegraph_t <= 0.0:
			bubble.visible = false)


func resume_to_bin(bin: Vector2) -> void:
	# chain interrupted while already carrying the bag: head for a bin
	if state in [HState.FALLEN, HState.WHIRL, HState.GO_BIN, HState.TOSS]:
		return
	state = HState.GO_BIN
	chain_target = bin
	telegraph_t = 0.0
	_show_bubble("where's a bin...")


func bumped(dir: Vector2) -> void:
	# a slow scooter kid is a shove, not a wipeout
	if state in [HState.FALLEN, HState.WHIRL]:
		return
	state = HState.STUMBLE
	state_t = 0.45
	velocity = dir * 190.0
	telegraph_t = 0.0
	bubble.visible = false


func notify_strain() -> void:
	if state != HState.FALLEN:
		strain = true


func on_leash_yank(dir: Vector2, dog_planted: bool, yank_speed: float) -> void:
	if state == HState.FALLEN:
		return
	if dog_planted and pull_cd <= 0.0 and yank_speed > 110.0 and state != HState.STUMBLE:
		pull_cd = 1.0
		state = HState.STUMBLE
		state_t = 0.55
		velocity = -dir * (yank_speed * 0.9 + 90.0)
		telegraph_t = 0.0
		bubble.visible = false
		main.float_text(global_position, "whoa!", Color(1, 1, 1))
		main.on_stumble_save(global_position)


func fall(_reason: String) -> bool:
	if state == HState.FALLEN or iframes > 0.0:
		return false
	state = HState.FALLEN
	state_t = 1.6
	velocity = Vector2.ZERO
	rotation = PI / 2.0 * (1.0 if randf() < 0.5 else -1.0)
	telegraph_t = 0.0
	bubble.visible = false
	main.crack_phone(global_position)
	return true


func halt(duration: float) -> void:
	if state in [HState.WALK, HState.DRIFT, HState.DASH]:
		halt_t = duration
		state = HState.WALK
		move_and_collide(Vector2(0, 16))
		_show_bubble("huh?")
		var tw := create_tween()
		tw.tween_interval(duration)
		tw.tween_callback(func() -> void: bubble.visible = false)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var woman: bool = Game.owner_id == "her"
	var shirt := Color(0.6, 0.38, 0.44) if woman else Color(0.35, 0.42, 0.55)
	var skin := Color(0.85, 0.72, 0.58)
	var pants := Color(0.3, 0.28, 0.34) if woman else Color(0.25, 0.27, 0.32)
	var hair_col := Color(0.42, 0.3, 0.18) if woman else Color(0.3, 0.22, 0.15)
	var t := Time.get_ticks_msec() / 1000.0
	var fd := face_dir
	var side := fd.orthogonal()
	# feet step along the walking direction
	var stepping := velocity.length() > 5.0
	var sa := sin(hgait) * 6.0 if stepping else 0.0
	draw_circle(side * 7.0 + fd * sa, 5.0, pants)
	draw_circle(-side * 7.0 - fd * sa, 5.0, pants)
	# body with a slight walking sway
	var sway := side * (sin(hgait * 0.5) * 1.2) if stepping else Vector2.ZERO
	draw_circle(sway, 16.0, shirt)
	# arms reaching forward to the phone
	draw_line(side * 10.0, side * 4.0 + fd * 17.0, skin, 5.0)
	draw_line(-side * 10.0, -side * 4.0 + fd * 17.0, skin, 5.0)
	# head, hair on the back of it; she gets the fuller cut and a ponytail
	var head := fd * 5.0
	draw_circle(head, 9.0, skin)
	var back := (-fd).angle()
	draw_arc(head, 9.0, back - (1.15 if woman else 0.85), back + (1.15 if woman else 0.85), 12, hair_col, 5.0)
	if woman:
		draw_circle(head - fd * 11.0, 3.6, hair_col)
	# the phone, held out front, eternally glowing
	var glow := 0.55 + 0.2 * sin(t * 7.3)
	draw_set_transform(fd * 24.0, fd.angle() + PI / 2.0, Vector2.ONE)
	draw_rect(Rect2(-6, -9, 12, 18), Color(0.1, 0.1, 0.12))
	draw_rect(Rect2(-4.5, -7, 9, 14), Color(0.7, 0.85, 1.0, glow))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if wading:
		# waist-deep, phone held higher, ripples of shame around the middle
		draw_circle(Vector2(0, 4), 17.0, Color(0.42, 0.56, 0.66, 0.55))
		for i in range(2):
			var rr := fmod(t * 1.3 + i * 0.5, 1.2)
			draw_arc(Vector2(0, 4), 16.0 + rr * 18.0, 0, TAU, 20, Color(0.82, 0.9, 1.0, 0.3 * (1.0 - rr / 1.2)), 2.0)
	if carrying_bag:
		draw_circle(side * 12.0 + fd * 2.0, 4.5, Color(0.9, 0.9, 0.92))
	if state == HState.BAG:
		# bent over the evidence, arm to the ground
		draw_line(fd * 10.0, fd * 26.0, skin, 4.0)
		draw_circle(fd * 26.0, 3.5, Color(0.9, 0.9, 0.92))
	if state == HState.FALLEN:
		for i in range(3):
			var a := t * 3.0 + TAU * i / 3.0
			draw_circle(head + Vector2.from_angle(a) * 22.0, 2.5, Color(1, 0.9, 0.4))
	elif state == HState.WHIRL:
		# speed lines; the node itself is spinning, so they animate freely
		for j in range(3):
			draw_arc(Vector2.ZERO, 23.0 + j * 6.0, PI * 0.15, PI * 0.85, 10, Color(1, 1, 1, 0.34 - j * 0.09), 2.5)
	elif strain:
		draw_line(Vector2(16, -36), Vector2(16, -27), Color(1, 0.85, 0.3), 3.0)
		draw_circle(Vector2(16, -22), 2.0, Color(1, 0.85, 0.3))
