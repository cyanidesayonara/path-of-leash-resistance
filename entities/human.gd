extends CharacterBody2D

const HumanLook := preload("res://entities/human_appearance.gd")

# The human. Dead weight with a phone. Walks north on autopilot,
# occasionally does something stupid. Telegraphs it first, to be fair.

enum HState { WALK, STOPPED, DRIFT, DASH, SELFIE, FILM, SIGNAL, CALL, WHIRL, GO_POOP, BAG, GO_BIN, TOSS, STUMBLE, FALLEN }

const WALK_SPEED := 92.0
# the whirl's orbit radius, and how fast it tightens onto it from wherever
# the owner was when it began (px/s)
const WHIRL_R := 30.0
const WHIRL_TIGHTEN := 200.0
var whirl_r := WHIRL_R
# The whirl, tuned. Spin-up is rad/s^2: a base rate plus whatever the dog is
# pulling with (main.gd feeds whirl_pull the leash tension, so the pole works
# as a pulley), and the pull fades over the frames after it stops.
const WHIRL_SPIN_BASE := 8.0
const WHIRL_SPIN_PER_PULL := 0.016
const WHIRL_OMEGA_MAX := 24.0
const WHIRL_PULL_DECAY := 0.9
# how much faster than the orbit she spins on the spot, for the look of it
const WHIRL_SPIN_LOOK := 1.4
# the fling: px/s per rad/s of orbit, floored and capped
const WHIRL_FLING_PER_OMEGA := 54.0
const WHIRL_FLING_MIN := 360.0
const WHIRL_FLING_MAX := 950.0
# Release. The launch is the tangent, once it points within this cone of the
# dog - the wait is what aims it, so there is nothing to correct. If it never
# does point there, she keeps orbiting at most WHIRL_EXTRA_ARC past the
# wound-turn budget, and only THAT launch leans toward the dog, by at most
# WHIRL_BLEND_MAX - under a quarter turn, so a lean can never reach the far
# side of the radius and reverse the way she was going round.
const WHIRL_AIM_COS := 0.5
const WHIRL_EXTRA_ARC := 0.6 * TAU
const WHIRL_BLEND_MAX := PI / 3.0
# The orbit's own timer, and the bail: a whirl that outlives the timer, or one
# whose pole stops being somewhere she could be wound on, staggers out along
# the tangent she is already on instead of being flung.
const WHIRL_TIMEOUT := 3.5
const WHIRL_LOSE_R := 140.0
const WHIRL_BAIL_MIN := 60.0
const WHIRL_BAIL_SPEED := 260.0
const WHIRL_BAIL_STUMBLE := 0.7
# how long she reads as stretched out along a fling after one. Cosmetic.
const WHIRL_STRETCH_T := 0.35
const PANIC_SPEED := 230.0

# how far before and after an island the owner is already on its side
const ISLAND_LEAD := 400.0
# ...and how far before a narrow the owner lines up for it
const NARROW_LEAD := 480.0
# how far short of a lesson's stop the owner starts drifting to its standing x
const TUT_STAND_LEAD := 420.0
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
# The reel is telegraphed like every other owner event: "click!" first, and
# the new length only REEL_WARN later, so the change never lands unseen.
const REEL_WARN := 0.8
var reel_pending_t := 0.0
var reel_pending_len := 0.0
var whirl_pole := Vector2.ZERO
var whirl_dir := 1.0
var whirl_omega := 0.0
var whirl_angle := 0.0
var whirl_turns := 0.0
# signed angular progress round whirl_pole in the direction committed at
# arming. It only grows, and nothing resets it: the budget is the turn count
# the rope was wound by, swept once, one way.
var whirl_unwound := 0.0
var whirl_pull := 0.0
var just_flung := false
var whirl_flung_t := 0.0
# set when an orbit was abandoned rather than flung, so main.gd can keep the
# rope slipping while she staggers clear without paying her for a fling
var whirl_bailed := false
var face_dir := Vector2.UP
var hgait := 0.0
var chain_target := Vector2.ZERO
var carrying_bag := false
var bin_stuck_t := 0.0
# THE PHONE CALL: once a walk the owner takes a call and stops dead for an
# age. Their obliviousness stops being an obstacle and becomes the dog's
# window - see main.gd, which lets the leash right out for the duration.
var call_used := false
var call_total := 0.0
var wading := false
var pond_bank_x := 0.0
var homeward := false
# the tutorial holds the owner here (north of it is where they stop); -INF off
var tut_hold_y := -INF
var tut_hold_x := INF
var parked := false
var park_target := Vector2.ZERO
var park_throw_t := 0.0
var strain := false
# Being dragged, shown: when the leash is taut and they are moving somewhere
# other than where they are walking, they turn to the pull, brace their feet,
# lean back, reach along the leash and scuff dust at their heels, instead of
# "walking" cheerfully towards the dog. Presentation only.
const DRAG_MIN := 50.0      # px/s of motion away from where they mean to go
const DRAG_EASE := 5.0
var walk_intent := Vector2.ZERO
var drag_amt := 0.0
var drag_dir := Vector2.DOWN
var panic := false
# THE LEASH CONVERSATION. Your human answers the leash like a person, not a
# fridge: a steady, moderate pull leads them (sideways across the path, a bit
# quicker if it is the way they are going, slower and waiting if it is back);
# hard, constant hauling wears their patience down, and when it runs out it is
# a telegraphed "HEY!" and a correction - a step back and a short leash. Dug in
# when it lands, it is them that stumbles. A slack leash builds patience back,
# and a patient human lets the reel out longer. They wait while she does her
# business. Tuning by playtest.
const GIVE_FULL := 520.0       # rope tension at which they give way fully
const GIVE_LAT := 150.0        # px across the path a full pull leads them
const GIVE_FWD := 0.35         # pulled their way: up to this much quicker
const GIVE_BACK := 0.65        # pulled back: up to this much slower
const PULL_EASE := 2.5         # 1/s: how fast the felt pull follows the rope
const PATIENCE_HARD := 900.0   # tension above which patience drains
const PATIENCE_DRAIN := 0.14   # per second at a hard pull
const PATIENCE_REFILL := 0.18  # per second with the leash slack
const PATIENCE_WARN := 0.45    # below this they glance up and grumble
const CORRECT_WARN := 0.8      # the "HEY!" telegraph, as every owner event
const CORRECT_HAUL := 240.0    # px/s they step back with
const CORRECT_REEL := 0.65     # the leash, cut to this much of its length
const CORRECT_REST := 0.7      # patience after a correction
const CORRECT_GRACE := 8.0     # s after a correction before patience drains again
const WAIT_MAX := 4.0          # s they wait while she does her business
var felt_pull := Vector2.ZERO
var _pull_now := Vector2.ZERO
var patience := 1.0
var correct_t := 0.0
var glance_t := 0.0
var grumbled := false
var waited := 0.0
var grace_t := 0.0
# the dog was already dug in when the HEY went up: bracing then is no answer
# to the telegraph, so it earns nothing (holding plant cannot farm the reward)
var planted_at_hey := false
var ice := false
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
	# a speech bubble, the same white bubble the world's other voices use
	# (world/pops_layer.gd): what the owner is about to do, telegraphed
	bubble = Label.new()
	bubble.position = Vector2(-60, -92)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.add_theme_font_size_override("font_size", 15)
	bubble.add_theme_color_override("font_color", Color(0.12, 0.11, 0.12))
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.98, 0.97, 0.94)
	bsb.set_corner_radius_all(9)
	bsb.content_margin_left = 9
	bsb.content_margin_right = 9
	bsb.content_margin_top = 2
	bsb.content_margin_bottom = 3
	bsb.shadow_color = Color(0, 0, 0, 0.2)
	bsb.shadow_size = 3
	bubble.add_theme_stylebox_override("normal", bsb)
	bubble.visible = false
	add_child(bubble)


func is_fallen() -> bool:
	return state == HState.FALLEN


func tick(delta: float) -> void:
	walk_intent = Vector2.ZERO
	iframes = maxf(0.0, iframes - delta)
	pull_cd = maxf(0.0, pull_cd - delta)
	halt_t = maxf(0.0, halt_t - delta)
	whirl_flung_t = maxf(0.0, whirl_flung_t - delta)
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
	# spooked witless (the "bolt" chase): the owner forgets the phone and
	# SPRINTS for home, dragging the dog behind them - the leash flips from
	# your tool into a tow-rope you are on the wrong end of
	if panic:
		velocity = velocity.move_toward(Vector2(0, PANIC_SPEED), 800.0 * delta)
		move_and_slide()
		face_dir = Vector2.DOWN
		hgait += delta
		if not bubble.visible:
			_show_bubble("AAH!")
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
			var sway := sin(main.elapsed * 4.0) * 30.0
			velocity = velocity.move_toward(Vector2(sway, 62.0), 220.0 * delta)
			move_and_slide()
			if state_t <= 0.0:
				state = HState.WALK
				bubble.visible = false
		HState.CALL:
			# planted, one hand to the ear, shifting their weight. They are
			# not going anywhere and they are not watching the dog.
			var shuf := sin(main.elapsed / 0.9) * 6.0
			velocity = velocity.move_toward(Vector2(shuf, 0.0), 180.0 * delta)
			move_and_slide()
			if state_t <= 0.0:
				state = HState.WALK
				bubble.visible = false
		HState.SIGNAL:
			# no bars: plants and holds the phone aloft, wandering a step in
			# hope of a signal - a dead stop as far as the dog is concerned
			var hunt := sin(main.elapsed * 2.5) * 10.0
			velocity = velocity.move_toward(Vector2(hunt, 0.0), 260.0 * delta)
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
			# runs for exactly as many turns as the rope was wound, the one
			# way it committed to at arming (the rope free-slips along
			# underneath). Pulling harder spins it up faster - the leash as
			# a pulley.
			if state_t <= 0.0 or not _whirl_pole_ok():
				# out of time, or the pole is not where the orbit is any
				# more: leave under control instead of orbiting nothing
				bail_whirl()
			else:
				whirl_omega = minf(whirl_omega + (WHIRL_SPIN_BASE + whirl_pull * WHIRL_SPIN_PER_PULL) * delta,
					WHIRL_OMEGA_MAX)
				whirl_pull *= WHIRL_PULL_DECAY
				var was := whirl_angle
				whirl_angle += whirl_dir * whirl_omega * delta
				whirl_unwound += whirl_dir * (whirl_angle - was)
				whirl_r = move_toward(whirl_r, WHIRL_R, WHIRL_TIGHTEN * delta)
				global_position = whirl_pole + Vector2.from_angle(whirl_angle) * whirl_r
				velocity = Vector2.from_angle(whirl_angle + whirl_dir * PI / 2.0) * whirl_omega * whirl_r
				rotation += whirl_dir * whirl_omega * WHIRL_SPIN_LOOK * delta
				# Orbit EXACTLY the wound amount (over-orbiting re-wraps the
				# rope the other way and the fling gets arrested), then hold
				# for the tangent to sweep toward the dog - at most
				# WHIRL_EXTRA_ARC. The ordinary release has nothing left to
				# decide: the orbit waited for the tangent, so the tangent IS
				# the launch. Only the launch the cap forces leans, and if even
				# a full lean would throw her away from the dog there is no
				# fling to be had and she staggers out instead.
				if whirl_unwound >= whirl_turns:
					var tangent := Vector2.from_angle(whirl_angle + whirl_dir * PI / 2.0)
					var aim := _aim_at_dog()
					if aim != Vector2.ZERO and tangent.dot(aim) > WHIRL_AIM_COS:
						release_whirl()
					elif whirl_unwound - whirl_turns >= WHIRL_EXTRA_ARC:
						if whirl_can_fling(global_position - whirl_pole, whirl_dir, aim):
							release_whirl(1.0)
						else:
							bail_whirl()
		_:
			if state == HState.DASH and state_t <= 0.0:
				_end_dash()
			_walk(delta)
	_events(delta)
	_converse(delta)
	_fiddle_with_reel(delta)
	_track_drag(delta)
	# face the direction of travel - except when deliberately walking
	# backwards (filming, backing up for a selfie)
	hgait += velocity.length() * delta * 0.06
	if velocity.length() > 12.0:
		var ft := velocity.normalized()
		if state == HState.FILM or state == HState.SELFIE:
			ft = -ft
		# looking up from the phone at her, and longer while a "HEY!" winds up
		if (glance_t > 1.6 or correct_t > 0.0) and main != null:
			var at: Vector2 = main.dog.global_position - global_position
			if at.length() > 1.0:
				ft = at.normalized()
		face_dir = face_dir.slerp(ft, minf(8.0 * delta, 1.0))
		if face_dir.length() < 0.1:
			face_dir = ft
		else:
			face_dir = face_dir.normalized()


func _converse(delta: float) -> void:
	felt_pull = felt_pull.lerp(_pull_now, minf(PULL_EASE * delta, 1.0))
	_pull_now = Vector2.ZERO
	glance_t = maxf(0.0, glance_t - delta)
	grace_t = maxf(0.0, grace_t - delta)
	# only a walking owner minds: on a call, in an orbit, down or held for a
	# lesson they are not keeping score
	var minding := state in [HState.WALK, HState.DRIFT] and tut_hold_y == -INF
	if correct_t > 0.0:
		# something else took over mid-telegraph (an orbit, a fall, a call):
		# the correction is off, and leaves them still short of patience
		if not (state in [HState.WALK, HState.DRIFT]):
			correct_t = 0.0
			patience = maxf(patience, 0.2)
			if bubble.text == "HEY!":
				bubble.visible = false
			return
		correct_t -= delta
		if correct_t <= 0.0:
			_correct()
		return
	if not minding:
		return
	var t := felt_pull.length()
	if t > PATIENCE_HARD and grace_t <= 0.0:
		var fwd := Vector2(0.0, 1.0 if homeward else -1.0)
		var back := 1.5 if felt_pull.dot(fwd) < 0.0 else 1.0
		patience -= PATIENCE_DRAIN * clampf(t / PATIENCE_HARD, 1.0, 2.0) * back * delta
	elif not strain:
		patience = minf(1.0, patience + PATIENCE_REFILL * delta)
	if patience < PATIENCE_WARN:
		# looking up from the phone: the first warning is a mutter, then a
		# glance at her every couple of seconds
		if not grumbled and telegraph_t <= 0.0:
			grumbled = true
			notice("oi...", 1.0)
		if glance_t <= 0.0:
			glance_t = 2.2
	elif patience > PATIENCE_WARN + 0.15:
		grumbled = false
	if patience <= 0.0 and telegraph_t <= 0.0 and halt_t <= 0.0:
		correct_t = CORRECT_WARN
		planted_at_hey = bool(main.dog.planted)
		_show_bubble("HEY!", "HE'S HAD ENOUGH! DIG IN")


func _correct() -> void:
	if main != null and main.has_method("tip"):
		main.tip("correct")
	patience = CORRECT_REST
	grace_t = CORRECT_GRACE
	grumbled = false
	bubble.visible = false
	# a click already armed would land after this and undo the short leash
	reel_pending_t = 0.0
	var to_dog: Vector2 = main.dog.global_position - global_position
	var away := -to_dog.normalized() if to_dog.length() > 1.0 else Vector2(0.0, 1.0 if homeward else -1.0)
	if main.dog.planted:
		# she was ready for it: the haul meets a dog dug in, and it is him
		# that lurches forward
		state = HState.STUMBLE
		state_t = 0.5
		velocity = -away * 150.0
		if not planted_at_hey:
			main.on_correction_braced(global_position)
		return
	velocity += away * CORRECT_HAUL
	main.set_leash_target(float(main.leash_len) * CORRECT_REEL, true)
	main.on_correction(global_position)


func is_correcting() -> bool:
	return correct_t > 0.0


func _fiddle_with_reel(delta: float) -> void:
	# constantly fiddles with the retractable leash, independent of the
	# event system: new random length on every "click!"
	if reel_pending_t > 0.0:
		reel_pending_t -= delta
		if reel_pending_t <= 0.0:
			main.set_leash_target(reel_pending_len)
	if tut_hold_y > -INF:
		reel_pending_t = 0.0
		return
	if state in [HState.FALLEN, HState.STUMBLE, HState.WHIRL]:
		return
	reel_timer -= delta
	if reel_timer > 0.0:
		return
	if telegraph_t > 0.0 or correct_t > 0.0:
		reel_timer = 0.5
		return
	reel_timer = randf_range(4.0, 8.0)
	reel_pending_len = randf_range(170.0, 430.0)
	# a patient human lets it out; a fed-up one keeps her close
	reel_pending_len = 170.0 + (reel_pending_len - 170.0) * (0.55 + 0.45 * patience)
	reel_pending_t = REEL_WARN
	_show_bubble("click!")
	var tw := create_tween()
	tw.tween_interval(REEL_WARN + 0.3)
	tw.tween_callback(func() -> void:
		if telegraph_t <= 0.0:
			bubble.visible = false)


func _walk(delta: float) -> void:
	# the tutorial's owner waits at a lesson (main.TUT_HOLD_BACK): stood still
	# on the phone until it is done, shuffling over to the lesson's spot first
	if global_position.y <= tut_hold_y and not homeward:
		var want := Vector2.ZERO
		if tut_hold_x < INF and absf(global_position.x - tut_hold_x) > 6.0:
			want = Vector2(signf(tut_hold_x - global_position.x) * WALK_SPEED * 0.6, 0.0)
		velocity = velocity.move_toward(want, 400.0 * delta)
		move_and_slide()
		return
	if halt_t > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		move_and_slide()
		return
	# she is doing her business: a decent human waits, for a while
	if main.dog.squat_t > 0.0 or main.dog.peeing:
		waited += delta
		if waited < WAIT_MAX:
			if waited <= delta * 1.5 and telegraph_t <= 0.0 and correct_t <= 0.0:
				notice("go on then", 1.4)
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			move_and_slide()
			return
	else:
		waited = 0.0
	# game time, not the wall clock: the weave decides where the owner (and a
	# dragged dog) is across the path, so it must not depend on how long the
	# game took to boot or how fast this machine renders (#6)
	var t: float = main.elapsed
	var speed := WALK_SPEED
	# the path where the owner IS, so the weave follows a bend instead of
	# drifting off the outside of it (El Bosc's pinch, El Mosaic's serpentine)
	var here: Vector2 = main.walk_edges(global_position.y)
	var cx: float = (here.x + here.y) * 0.5
	var half: float = (here.y - here.x) * 0.5
	# where the path splits round an island (El Parc's lake) the owner keeps
	# to its side of it, and starts crossing over early enough to get there
	for isl: Dictionary in main.islands:
		var ir: Rect2 = isl["rect"]
		if global_position.y > ir.position.y - ISLAND_LEAD and global_position.y < ir.end.y + ISLAND_LEAD:
			var lo: float = (ir.end.x + 30.0) if float(isl["side"]) > 0.0 else (here.x + 30.0)
			var hi: float = (here.y - 30.0) if float(isl["side"]) > 0.0 else (ir.position.x - 30.0)
			cx = (lo + hi) * 0.5
			half = maxf((hi - lo) * 0.5 + 60.0, 70.0)
	# where the path narrows to a single line (a plank over a trench) the
	# owner lines up for it early and keeps to it
	# (only on the way up to it and across it: once past, the path is theirs
	# again, or a narrow just before an island would steer them into it)
	for nw: Dictionary in main.narrows:
		var lo_y: float = float(nw["y0"]) - (NARROW_LEAD if homeward else 0.0)
		var hi_y: float = float(nw["y1"]) + (0.0 if homeward else NARROW_LEAD)
		if global_position.y > lo_y and global_position.y < hi_y:
			cx = (float(nw["x0"]) + float(nw["x1"])) * 0.5
			half = (float(nw["x1"]) - float(nw["x0"])) * 0.5 + 60.0
			if state == HState.DASH:
				dash_target.x = clampf(dash_target.x, float(nw["x0"]), float(nw["x1"]))
	var tx := cx + sin(t * 0.35 + wobble_seed) * minf(110.0, half - 60.0)
	if tut_hold_x < INF and global_position.y < tut_hold_y + TUT_STAND_LEAD:
		tx = tut_hold_x
	if state == HState.DRIFT:
		tx = cx + drift_dir * (half - 70.0)
		speed = 72.0
		if state_t <= 0.0:
			state = HState.WALK
	# forward is up on the way out, down on the walk home
	var fwd_y := 1.0 if homeward else -1.0
	# led by the leash: a steady pull draws them across the path and speeds or
	# slows them along it (the conversation, above)
	if state == HState.WALK or state == HState.DRIFT:
		tx = clampf(tx + clampf(felt_pull.x / GIVE_FULL, -1.0, 1.0) * GIVE_LAT, cx - half + 40.0, cx + half - 40.0)
		var along := felt_pull.y * fwd_y / GIVE_FULL
		speed *= 1.0 + GIVE_FWD * clampf(along, 0.0, 1.0) - GIVE_BACK * clampf(-along, 0.0, 1.0)
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
	if ice:
		# a heavy body on ice: grip drops, so momentum carries the owner
		# past where they meant to stop - and the leash yanks compound it
		accel *= 0.4
	walk_intent = dir * speed
	velocity = velocity.move_toward(dir * speed, accel * delta)
	move_and_slide()


func _events(delta: float) -> void:
	# a HEY! winding up owns the bubble: no new event starts over it
	if state != HState.WALK or halt_t > 0.0 or correct_t > 0.0:
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
		if main.signal_prone and roll < 0.45:
			# out in the woods there are no bars, ever
			pending_event = HState.SIGNAL
			_show_bubble("no bars out here")
		elif not call_used and roll < 0.08:
			pending_event = HState.CALL
			_show_bubble("ring ring...")
		elif roll < 0.18:
			pending_event = HState.STOPPED
			_show_bubble("ring ring")
			# a ringing phone is NOISE - in the scrapyard it wakes the guards
			main.on_phone_noise(global_position)
		elif roll < 0.36:
			pending_event = HState.DRIFT
			_show_bubble("typing...")
		elif roll < 0.5:
			pending_event = HState.DASH
			_show_bubble("ooh!")
		elif roll < 0.62:
			pending_event = HState.SELFIE
			_show_bubble("selfie!")
		elif roll < 0.72:
			pending_event = HState.FILM
			_show_bubble("filming...")
		elif roll < 0.84:
			pending_event = HState.SIGNAL
			_show_bubble("signal?")
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
			_show_bubble("ring ring", "HE STOPPED TO ANSWER! GO")
		HState.DRIFT:
			state = HState.DRIFT
			state_t = 1.8
			_show_bubble("typing...", "HE'S TEXTING! HE'S NOT LOOKING")
			drift_dir = 1.0 if randf() < 0.5 else -1.0
		HState.SELFIE:
			state = HState.SELFIE
			state_t = 2.2
			_show_bubble("selfie!", "HE'S TAKING A SELFIE")
		HState.FILM:
			state = HState.FILM
			state_t = randf_range(1.6, 2.4)
			_show_bubble("filming...", "HE'S FILMING! HE'S STOPPED")
		HState.SIGNAL:
			state = HState.SIGNAL
			state_t = randf_range(2.6, 4.2)
			_show_bubble("no signal...", "HE LOST SIGNAL! HE'LL BE AGES")
		HState.CALL:
			# a proper natter: long enough to be a real opportunity
			state = HState.CALL
			state_t = randf_range(16.0, 21.0)
			call_total = state_t
			call_used = true
			_show_bubble("hello? ...oh HI", "HE STOPPED! LEASH IS LOOSE")
		HState.DASH:
			var de: Vector2 = main.walk_edges(global_position.y)
			var lo: float = de.x + 40.0
			var hi: float = de.y - 40.0
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


# a remark that is not an event: the bubble for this long, then gone
func notice(text: String, secs: float) -> void:
	if state in [HState.FALLEN, HState.WHIRL]:
		return
	_show_bubble(text)
	var tw := create_tween()
	tw.tween_interval(secs)
	tw.tween_callback(func() -> void:
		if bubble.text == text:
			bubble.visible = false)


func _show_bubble(text: String, dog_news: String = "") -> void:
	# The bubble is diegetic and stays where it belongs, over the owner's head.
	# But the player is watching the DOG - that is the whole camera of this
	# game - so anything that changes what she can get away with was landing
	# out in the corner of the eye and going unread. dog_news is the same
	# moment said again next to her, in her voice.
	bubble.text = text
	bubble.reset_size()
	bubble.position.x = -bubble.size.x * 0.5
	bubble.visible = true
	if dog_news != "" and main != null and main.has_method("owner_news"):
		main.owner_news(dog_news)


func is_whirling() -> bool:
	return state == HState.WHIRL


func start_whirl(pole: Vector2, dir: float, turns: float) -> void:
	if state == HState.WHIRL or state == HState.FALLEN:
		return
	# a pole nobody could find is not something to be swung round
	if not (is_finite(pole.x) and is_finite(pole.y)):
		return
	state = HState.WHIRL
	state_t = WHIRL_TIMEOUT
	whirl_pole = pole
	# the direction main.gd committed to at arming, and the only one this
	# orbit will ever have
	whirl_dir = 1.0 if dir >= 0.0 else -1.0
	whirl_turns = clampf(turns, 0.6, 4.0) * TAU
	whirl_unwound = 0.0
	whirl_pull = 0.0
	whirl_bailed = false
	whirl_angle = (global_position - pole).angle()
	# the orbit starts where they are and tightens in, rather than snapping
	# them onto the 30 px circle on the first frame
	whirl_r = global_position.distance_to(pole)
	whirl_omega = clampf(velocity.length() / maxf(whirl_r, 30.0), 8.0, 14.0)
	telegraph_t = 0.0
	_show_bubble("wheee!")


# the orbit is only honest while the pole is still somewhere she could be
# wound on; main.gd checks the harder question of whether it is a pole at all
func _whirl_pole_ok() -> bool:
	if not (is_finite(whirl_pole.x) and is_finite(whirl_pole.y)):
		return false
	return global_position.distance_squared_to(whirl_pole) < WHIRL_LOSE_R * WHIRL_LOSE_R


func _aim_at_dog() -> Vector2:
	if main == null or main.dog == null:
		return Vector2.ZERO
	var to_dog: Vector2 = main.dog.global_position - global_position
	return to_dog.normalized() if to_dog.length() > 0.001 else Vector2.ZERO


# The launch direction. The tangent always moves away from the pole, so
# getting stuck on it is geometrically impossible, and `lean` is how far the
# budget has been overrun: a tangent that never lined up is leaned toward the
# dog, by less than a quarter turn, so the launch always keeps the angular
# direction the orbit had. Reads its arguments only.
func whirl_fling_dir(radial: Vector2, spin: float, aim: Vector2, lean: float) -> Vector2:
	var out := radial.normalized().rotated(spin * PI / 2.0)
	if aim == Vector2.ZERO or lean <= 0.0:
		return out
	var turn := clampf(out.angle_to(aim), -WHIRL_BLEND_MAX, WHIRL_BLEND_MAX) * minf(lean, 1.0)
	return out.rotated(turn)


# Is there a dogward launch to be had at all? The lean is bounded, so a dog
# sitting behind the way she is going cannot be thrown at: a launch that still
# points away from her is worse than no fling, so that is a stagger instead.
# A dog with no direction to give (at her feet, or none at all) is no reason to
# refuse. Reads its arguments only.
func whirl_can_fling(radial: Vector2, spin: float, aim: Vector2) -> bool:
	if aim == Vector2.ZERO:
		return true
	return whirl_fling_dir(radial, spin, aim, 1.0).dot(aim) > 0.0


# Which way she is already going round a point: the tie-break for a rope with
# no opinion about which way unwinds it (main.gd/_apply_leash). Reads its
# arguments only; a dead stop is settled the same way every time.
func orbit_sense(radial: Vector2, vel: Vector2) -> float:
	var sense := signf(radial.cross(vel))
	return sense if sense != 0.0 else 1.0


# `lean` is how far the launch may be turned toward the dog, 0 for not at all:
# only a release forced by the extra-arc cap gets one, because every other
# release already waited for the tangent to point where it wanted.
func release_whirl(lean := 0.0) -> void:
	if state != HState.WHIRL:
		return
	# The "toward the dog" part is release timing: the orbit waits for the
	# tangent to sweep at the dog. Fast flings sail PAST her, whose turn it
	# then is to get yanked along (the bungee).
	var radial := global_position - whirl_pole
	if radial.length() < 0.001 or not (is_finite(radial.x) and is_finite(radial.y)):
		radial = Vector2.from_angle(whirl_angle)
	var launch := whirl_fling_dir(radial, whirl_dir, _aim_at_dog(), lean)
	state = HState.STUMBLE
	state_t = 1.0
	rotation = 0.0
	bubble.visible = false
	whirl_pull = 0.0
	velocity = launch * clampf(whirl_omega * WHIRL_FLING_PER_OMEGA, WHIRL_FLING_MIN, WHIRL_FLING_MAX)
	just_flung = true
	whirl_flung_t = WHIRL_STRETCH_T
	main.float_text(global_position, "AAAA", Color(1, 0.9, 0.6))
	main.shake_t = maxf(float(main.shake_t), 0.35)


func bail_whirl() -> void:
	# Not a fling: the orbit ran out of time or lost its pole, so she carries
	# on along the tangent she is already travelling, at a stagger, from
	# exactly where she stands. No snap, and nothing to score.
	if state != HState.WHIRL:
		return
	var away := velocity.normalized()
	if away == Vector2.ZERO or not (is_finite(away.x) and is_finite(away.y)):
		away = Vector2.from_angle(whirl_angle + whirl_dir * PI / 2.0)
	state = HState.STUMBLE
	state_t = WHIRL_BAIL_STUMBLE
	rotation = 0.0
	whirl_pull = 0.0
	velocity = away * clampf(whirl_omega * whirl_r, WHIRL_BAIL_MIN, WHIRL_BAIL_SPEED)
	whirl_bailed = true
	_show_bubble("ugh, dizzy")
	var tw := create_tween()
	tw.tween_interval(WHIRL_BAIL_STUMBLE + 0.3)
	tw.tween_callback(func() -> void:
		if telegraph_t <= 0.0:
			bubble.visible = false)


# a line in the speech bubble for a moment, from the park bench (the
# frisbee's "ready...?", which is the telegraph before every throw)
func say_line(text: String) -> void:
	_show_bubble(text)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func() -> void:
		if bubble.text == text:
			bubble.visible = false)


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


func unpark() -> void:
	parked = false
	homeward = true
	bubble.visible = false
	_show_bubble("okay, home time")


func is_on_call() -> bool:
	return state == HState.CALL


func call_left() -> float:
	return maxf(0.0, state_t) if state == HState.CALL else 0.0


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


func _track_drag(delta: float) -> void:
	var off := velocity - walk_intent
	var dragged := strain and off.length() > DRAG_MIN and not (state in [HState.WHIRL, HState.FALLEN])
	drag_amt = move_toward(drag_amt, 1.0 if dragged else 0.0, DRAG_EASE * delta)
	if off.length() > 5.0:
		drag_dir = drag_dir.slerp(off.normalized(), minf(6.0 * delta, 1.0)).normalized()


# the leash's pull on them this frame: toward the dog along the rope, times
# its tension (main.gd/_leash_tug); read on the next tick
func feel_pull(dir: Vector2, tension: float) -> void:
	_pull_now = dir * tension


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


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_draw_shapes()
	_b.flush()


func _draw_shapes() -> void:
	# at night the phone is a real light source: a cold blue-white pool on
	# the pavement in front of them. The joke of the whole game, lit.
	if Game.night:
		var pt := AnimClock.msec() / 1000.0
		var pulse := 0.9 + 0.1 * sin(pt * 6.1)
		var lit := face_dir * 26.0
		for ring in range(4):
			var rr := 96.0 - ring * 21.0
			_b.draw_circle(lit, rr, Color(0.62, 0.78, 1.0, (0.028 + ring * 0.020) * pulse))
	# contact shadow first, matching the dog's light direction. A fallen
	# owner's shadow spreads out under them.
	if not wading:
		var spread := 1.45 if state == HState.FALLEN else 1.0
		_b.draw_set_transform(Vector2(5.0, 9.0), 0.0, Vector2(1.2 * spread, 0.52))
		_b.draw_circle(Vector2.ZERO, 16.0, Color(0.06, 0.05, 0.08, 0.28))
		_b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var woman: bool = Game.owner_id == "her"
	var shirt := Color(0.6, 0.38, 0.44) if woman else Color(0.35, 0.42, 0.55)
	var skin := Color(0.85, 0.72, 0.58)
	var pants := Color(0.3, 0.28, 0.34) if woman else Color(0.25, 0.27, 0.32)
	var hair_col := Color(0.42, 0.3, 0.18) if woman else Color(0.3, 0.22, 0.15)
	var t := AnimClock.msec() / 1000.0
	var fd := face_dir
	# dragged: turned to face the pull
	if drag_amt > 0.01:
		fd = fd.slerp(drag_dir, drag_amt).normalized()
	var side := fd.orthogonal()
	# feet step along the walking direction; dragged, they are braced wide
	# and forward and slide instead
	var stepping := velocity.length() > 5.0 and drag_amt < 0.5
	var sa := sin(hgait) * 6.0 if stepping else 0.0
	var brace := side * (7.0 + 3.0 * drag_amt) + fd * 6.0 * drag_amt
	var brace2 := -side * (7.0 + 3.0 * drag_amt) + fd * 6.0 * drag_amt
	if drag_amt > 0.3 and velocity.length() > 40.0:
		# dust scuffed up at the heels as they are hauled along
		for k in range(3):
			var ph := fmod(t * 5.0 + float(k) * 0.33, 1.0)
			var dust := Color(0.94, 0.91, 0.84, 0.6 * (1.0 - ph) * drag_amt)
			_b.draw_circle(brace - fd * (20.0 + ph * 16.0) + side * (ph * 4.0), 3.0 + ph * 4.0, dust)
			_b.draw_circle(brace2 - fd * (20.0 + ph * 16.0) - side * (ph * 4.0), 3.0 + ph * 4.0, dust)
	# dressed for the weather (human_appearance.gd outfit): a raincoat and
	# hood in the rain, coat, scarf and hat in the snow, shades by the sea
	var dress: Dictionary = HumanLook.outfit(Game.weather, Game.level_id, Game.night, 3 if woman else 2, shirt,
		"none", Color.BLACK, "none")
	shirt = dress["shirt"]
	# shoes, toes out in front
	var shoe := pants.darkened(0.4)
	for fp: Vector2 in [brace + fd * sa, brace2 - fd * sa]:
		_b.draw_colored_polygon(HumanLook._disc_points(fp + fd * 1.5, Vector2(6.2, 4.4), fd), shoe)
	# body with a slight walking sway; dragged, leaning back against the pull
	var sway := side * (sin(hgait * 0.5) * 1.2) if stepping else Vector2.ZERO
	sway -= fd * 5.0 * drag_amt
	HumanLook.draw_torso(_b, sway, fd, Vector2(13.5, 17.0), shirt, bool(dress["coat"]), dress["scarf"])
	if drag_amt > 0.05:
		# the leash hand, stretched out along the pull
		# out to the side, clear of the phone
		var hand := sway + side * 17.0 + fd * (12.0 + 12.0 * drag_amt)
		_b.draw_line(sway + side * 11.0, hand, skin, 5.0)
		_b.draw_circle(hand, 3.4, skin)
	# arms reaching forward to the phone, sleeves then hands
	var sleeve := shirt.darkened(0.08)
	for sg: float in [-1.0, 1.0]:
		_b.draw_line(side * 10.0 * sg, side * 7.0 * sg + fd * 9.0, sleeve, 6.0)
		_b.draw_line(side * 7.0 * sg + fd * 9.0, side * 4.0 * sg + fd * 17.0, skin, 4.6)
		_b.draw_circle(side * 4.0 * sg + fd * 17.5, 3.0, skin)
	# head: seen from above, a proper head of hair; she has a ponytail
	var head := fd * 5.0 - fd * 6.0 * drag_amt
	var hood: bool = String(dress["headwear"]) == "hood"
	if woman and not hood:
		_b.draw_colored_polygon(HumanLook._disc_points(head - fd * 12.0, Vector2(6.5, 3.8), fd), hair_col.darkened(0.12))
		_b.draw_circle(head - fd * 8.0, 2.4, Color(0.86, 0.30, 0.42))
	HumanLook.draw_head(_b, head, fd, 9.0, skin, hair_col, "long" if woman else "short", String(dress["headwear"]),
		dress["headwear_col"])
	if String(dress["eyewear"]) == "sunglasses":
		for sg2: float in [-1.0, 1.0]:
			_b.draw_circle(head + fd * 5.9 + side * 3.2 * sg2, 2.4, Color(0.08, 0.08, 0.10))
		_b.draw_line(head + fd * 5.9 + side * 1.0, head + fd * 5.9 - side * 1.0, Color(0.08, 0.08, 0.10), 1.0)
	# the phone, held out front, eternally glowing
	var glow := 0.55 + 0.2 * sin(t * 7.3)
	_b.draw_set_transform(fd * 24.0, fd.angle() + PI / 2.0, Vector2.ONE)
	_b.draw_rect(Rect2(-6, -9, 12, 18), Color(0.1, 0.1, 0.12))
	_b.draw_rect(Rect2(-4.5, -7, 9, 14), Color(0.7, 0.85, 1.0, glow))
	_b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if wading:
		# waist-deep, phone held higher, ripples of shame around the middle
		_b.draw_circle(Vector2(0, 4), 17.0, Color(0.42, 0.56, 0.66, 0.55))
		for i in range(2):
			var rr := fmod(t * 1.3 + i * 0.5, 1.2)
			_b.draw_arc(Vector2(0, 4), 16.0 + rr * 18.0, 0, TAU, 20, Color(0.82, 0.9, 1.0, 0.3 * (1.0 - rr / 1.2)), 2.0)
	# whatever she has stood in, now on your trousers. The compounding joke:
	# they never notice, and it stacks up over the whole walk.
	for sm in main.owner_smudges:
		var sc: Color = main.SUBSTANCES[String(sm.kind)].col
		var so: Vector2 = sm.off
		_b.draw_circle(so, 4.6, Color(sc.r, sc.g, sc.b, 0.85))
		_b.draw_circle(so + Vector2(-2.6, -2.2), 2.0, Color(sc.r, sc.g, sc.b, 0.8))
		_b.draw_circle(so + Vector2(2.6, -2.2), 2.0, Color(sc.r, sc.g, sc.b, 0.8))
	if carrying_bag:
		_b.draw_circle(side * 12.0 + fd * 2.0, 4.5, Color(0.9, 0.9, 0.92))
	if state == HState.BAG:
		# bent over the evidence, arm to the ground
		_b.draw_line(fd * 10.0, fd * 26.0, skin, 4.0)
		_b.draw_circle(fd * 26.0, 3.5, Color(0.9, 0.9, 0.92))
	if state == HState.SIGNAL:
		# the phone thrust skyward, hunting for a bar that will not come
		var up := head + Vector2(0, -22)
		_b.draw_line(head, up, skin, 4.0)
		_b.draw_rect(Rect2(up.x - 5.0, up.y - 8.0, 10.0, 15.0), Color(0.1, 0.1, 0.12))
		_b.draw_rect(Rect2(up.x - 3.5, up.y - 6.0, 7.0, 11.0), Color(0.7, 0.85, 1.0, 0.8))
		for b in range(3):
			_b.draw_rect(Rect2(up.x - 5.0 + b * 3.0, up.y - 15.0 - b * 2.0, 2.0, 4.0 + b * 2.0), Color(0.6, 0.6, 0.65))
		_b.draw_line(up + Vector2(-6, -18), up + Vector2(7, -6), Color(1, 0.4, 0.4), 2.0)
	if state == HState.FALLEN:
		for i in range(3):
			var a := t * 3.0 + TAU * i / 3.0
			_b.draw_circle(head + Vector2.from_angle(a) * 22.0, 2.5, Color(1, 0.9, 0.4))
	elif state == HState.WHIRL:
		# The orbit, read from outside: where she has just been, how fast she
		# is going now, and that she is still being hauled in. The node itself
		# is spinning, so world directions come back into its frame and the
		# arcs animate freely.
		var spin := clampf(whirl_omega / WHIRL_OMEGA_MAX, 0.0, 1.0)
		var inward := clampf((whirl_r - WHIRL_R) / WHIRL_R, 0.0, 1.0)
		for j in range(4):
			var back := whirl_angle - whirl_dir * (0.12 + 0.11 * float(j))
			var ghost := whirl_pole + Vector2.from_angle(back) * whirl_r
			_b.draw_circle((ghost - global_position).rotated(-rotation), 11.0 - 1.8 * float(j),
				Color(0.92, 0.9, 0.95, (0.26 - 0.055 * float(j)) * spin))
		# speed lines, longer and brighter the faster the orbit has wound up
		for j in range(3):
			_b.draw_arc(Vector2.ZERO, 23.0 + j * 6.0, PI * 0.15, PI * (0.85 + 0.1 * spin), 10,
				Color(1, 1, 1, (0.34 - j * 0.09) * (0.45 + 0.55 * spin)), 2.5 + spin)
		if inward > 0.02:
			# grit kicked up behind her while the orbit still tightens in
			var out := (global_position - whirl_pole).normalized().rotated(-rotation)
			for k in range(3):
				var ph := fmod(t * 6.0 + float(k) * 0.33, 1.0)
				_b.draw_circle(out * (14.0 + ph * 20.0), 2.5 + ph * 3.5,
					Color(0.94, 0.91, 0.84, 0.5 * (1.0 - ph) * inward))
	elif main.whirl_arm_amount() > 0.0:
		# the quarter second before an orbit: the rope taking up round the
		# pole she is about to go round, so it is never a surprise
		var wind: float = main.whirl_arm_amount()
		var to_pole: Vector2 = main.leash.human_contact_pole - global_position
		if to_pole.length() > 1.0 and is_finite(to_pole.x) and is_finite(to_pole.y):
			var at := to_pole.normalized().rotated(-rotation) * 16.0
			for k in range(2):
				_b.draw_arc(at, 9.0 + 7.0 * float(k) * wind, 0.0, TAU, 12,
					Color(1.0, 0.95, 0.7, 0.34 * wind / (1.0 + float(k))), 2.0)
	elif patience < PATIENCE_WARN and correct_t <= 0.0:
		# the patience running out, over their head: a scribble of temper that
		# grows as it goes
		var g := clampf((PATIENCE_WARN - patience) / PATIENCE_WARN, 0.0, 1.0)
		var tc := AnimClock.msec() / 1000.0
		var gc := Color(0.95, 0.35, 0.30, 0.45 + 0.55 * g)
		var n := 3 + int(g * 3.0)
		var gx := Vector2(-4.5 * float(n), -44.0)
		# a little storm cloud of temper, then the scribble under it
		_b.draw_circle(Vector2(-6.0, -50.0), 6.0 + 2.0 * g, Color(0.30, 0.28, 0.32, 0.5 + 0.4 * g))
		_b.draw_circle(Vector2(4.0, -51.0), 7.0 + 2.0 * g, Color(0.30, 0.28, 0.32, 0.5 + 0.4 * g))
		for k in range(n):
			var nx := gx + Vector2(9.0, -6.0 if k % 2 == 0 else 6.0) + Vector2(0.0, sin(tc * 14.0 + float(k)) * 1.5 * g)
			_b.draw_line(gx, nx, gc, 3.0)
			gx = nx
	elif strain:
		_b.draw_line(Vector2(16, -36), Vector2(16, -27), Color(1, 0.85, 0.3), 3.0)
		_b.draw_circle(Vector2(16, -22), 2.0, Color(1, 0.85, 0.3))
	if whirl_flung_t > 0.0 and velocity.length() > 60.0:
		# flung: stretched out along the launch, with the air she left behind
		var amt := whirl_flung_t / WHIRL_STRETCH_T
		var trail := -velocity.normalized().rotated(-rotation)
		for k in range(3):
			var o := side * (6.0 - 6.0 * float(k))
			_b.draw_line(o, o + trail * (26.0 + 14.0 * float(k)) * amt,
				Color(1.0, 0.97, 0.88, 0.40 * amt), 3.0 - 0.6 * float(k))
