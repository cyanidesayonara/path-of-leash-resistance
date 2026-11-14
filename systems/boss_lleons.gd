class_name BossLleons
extends RefCounted

# ELS LLEONS, El Port's twin bronze lion statues (docs/BOSSES.md):
# Two bronze lions at the foot of the Columbus Column (Monument a Colom, 1888)
# by Portal de la Pau. They wake at dusk as the pair approach the roundabout,
# and fight as a coordinated pair taking turns.
#
# - The wake: dog crosses WAKE_Y (-4000.0); left lion yawns with a creak, right lion
#   blinks open glowing amber eyes, they glance at each other, then focus on the dog.
# - Phase 1 (Pincer & Roar):
#   - PINCER: One lion circles wide to her far side while the other stalks in;
#     two warning lanes close on her from either side. Stepping out late dodges it.
#   - ROAR: A cone of wind that pushes the dog back toward the other lion.
#     The player can brace with {plant} (dig in) to resist the push.
# - Phase 2 (Double Rush, below 50% HP):
#   - Both rush with crossing lanes. Standing near the intersection and dodging
#     at the last moment tricks them into colliding: HEAD BUMP! Both dazed.
#   - While dazed, barking at either lion's nose awards a boop.
# - Phase 3 (Last Stand, below 10% HP):
#   - Both retreat to their corner plinths.
#   - Wrapping the leash around a leg of each lion ties them together: they wobble and sit.
#   - A friendly bark at each lion's nose (double boop) settles them into contented statues.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Prompts := preload("res://hud/prompts.gd")

const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# --- Bronze & Arena Palette --------------------------------------------------
# the 1888 casts: near-black bronze, verdigris in every hollow and down the
# shadow side, and bright metal only where hands reach (noses, toes)
const BRONZE_DEEP := Color(0.11, 0.09, 0.07)
const BRONZE_DARK := Color(0.25, 0.19, 0.12)
const BRONZE := Color(0.40, 0.31, 0.18)
const BRONZE_LIT := Color(0.54, 0.42, 0.22)
const BRONZE_SHINE := Color(0.90, 0.76, 0.42)
const PATINA_DARK := Color(0.17, 0.31, 0.27)
const PATINA := Color(0.33, 0.53, 0.45)
const MOUTH := Color(0.36, 0.08, 0.07)
const TONGUE := Color(0.72, 0.26, 0.22)
const FANG := Color(0.95, 0.90, 0.78)
const EYE_AMBER := Color(1.0, 0.78, 0.22)
const EYE_RED := Color(1.0, 0.30, 0.16)
const PLINTH_COL := Color(0.68, 0.65, 0.60)
const PLINTH_DARK := Color(0.50, 0.47, 0.43)
const WARN := Color(1.0, 0.36, 0.20)
const WIND := Color(0.80, 0.93, 1.0)
# how big a lion is drawn, and how long the bound to a rush's start is shown
const DRAW_K := 1.15
const LEAP_TIME := 0.35
const LEAP_JUMP := 60.0

enum Pose { REST, SIT, WALK, CROUCH, CHARGE, ROAR, DAZED }

# --- Arena & Geometry --------------------------------------------------------
const COLOM_POS := Vector2(640.0, -4500.0)
const PLINTH_L := Vector2(480.0, -4380.0)
const PLINTH_R := Vector2(800.0, -4380.0)
const PLINTH_HALF := Vector2(52.0, 38.0)

const HOLD_Y := -4120.0
const WAKE_Y := -4000.0

const BODY_R := 36.0
const HEAD_R := 22.0
const MANE_R := 32.0
const LEG_RADIUS := 14.0

const MAX_HP := 100.0
const FILM := "res://intro/film_lleons.gd"
const FILM_WIN := "res://intro/film_lleons_win.gd"

# --- Tuning ------------------------------------------------------------------
const PINCER_WARN := 0.85
const PINCER_SPEED := 250.0
const PINCER_COOLDOWN := 3.2
const ROAR_WARN := 0.80
const ROAR_DUR := 0.85
const ROAR_REACH := 290.0
const ROAR_HALF := 0.65       # half-angle in radians (~37 deg)
const ROAR_PUSH_FORCE := 380.0
const ROAR_COOLDOWN := 3.8
const RUSH_WARN := 1.00
const RUSH_SPEED := 380.0
# the double rush aims where she stands as it warns; both lions reach that
# point together, so stepping out in the warning makes them meet
const RUSH_TO_CROSS := 0.75
const RUSH_SPREAD := Vector2(240.0, 150.0)
const RUSH_CLEAR := 70.0
const ARENA_X := Vector2(440.0, 840.0)
const ARENA_Y := Vector2(-4520.0, -4280.0)
const RUSH_COOLDOWN := 4.2
const BUMP_STUN := 3.2
const BOOP_REACH := 65.0
const LEG_MEMORY := 2.0
const LEGS_TO_TIE := 2        # 1 leg on each lion

enum State {
	IDLE, AWAKEN, PROWL,
	PINCER_WARN, PINCER_STRIKE,
	ROAR_WARN, ROAR_BLAST,
	RUSH_WARN, RUSH_CHARGE,
	STUNNED, RETREAT, STAND, WRAPPED, SAT, CONTENT,
}

var state: State = State.IDLE
var state_t := 0.0
var act_t := 0.0
var hp := MAX_HP
var max_hp := MAX_HP
var phase := 1
var main: Node2D = null

# Lion A (West) and Lion B (East)
var lion_a := {
	"pos": PLINTH_L,
	"vel": Vector2.ZERO,
	"face_dir": Vector2.DOWN,
	"plinth": PLINTH_L,
	"jaw": 0.0,
	"eye": 0.0,
	"dazed": 0.0,
	"booped": false,
	"side": -1.0,
	# drawing only: paw travel, pace, and the bound shown for a cut in place
	"stride": 0.0,
	"speed": 0.0,
	"prev": PLINTH_L,
	"leap_from": PLINTH_L,
	"leap_t": 0.0,
}
var lion_b := {
	"pos": PLINTH_R,
	"vel": Vector2.ZERO,
	"face_dir": Vector2.DOWN,
	"plinth": PLINTH_R,
	"jaw": 0.0,
	"eye": 0.0,
	"dazed": 0.0,
	"booped": false,
	"side": 1.0,
	# drawing only: paw travel, pace, and the bound shown for a cut in place
	"stride": 0.0,
	"speed": 0.0,
	"prev": PLINTH_R,
	"leap_from": PLINTH_R,
	"leap_t": 0.0,
}

var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []
var leg_soft_indices: Array[int] = []
var leg_touch_t: Array[float] = [-INF, -INF]
var legs_tied := 0

var pincer_cd := 1.2
var roar_cd := 2.0
var rush_cd := RUSH_COOLDOWN
var pincer_targets: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var rush_starts: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var rush_ends: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var rush_cross_pos := Vector2.ZERO
var roaring_lion: Dictionary = lion_a

var boops_done := 0
var bump_done := false
var pincer_dodged := false
var pincer_hit := false
var roar_paid := false
var rush_hit := false
var rush_speeds: Array[float] = [RUSH_SPEED, RUSH_SPEED]
var film_shown := false
var win_film_shown := false
var hold_noticed := false

var lean := 0.0
var card_t := -1.0
var card: Control = null
var dust_rings: Array[Dictionary] = []
var sparks: Array[Dictionary] = []


func setup(m: Node2D) -> void:
	main = m
	state = State.IDLE
	state_t = 0.0
	act_t = 0.0
	hp = MAX_HP
	phase = 1
	boops_done = 0
	bump_done = false
	pincer_dodged = false
	film_shown = false
	win_film_shown = false
	hold_noticed = false
	legs_tied = 0
	leg_touch_t = [-INF, -INF]

	lion_a.pos = PLINTH_L
	lion_a.face_dir = Vector2.DOWN
	lion_a.jaw = 0.0
	lion_a.eye = 0.0
	lion_a.dazed = 0.0
	lion_a.booped = false

	lion_b.pos = PLINTH_R
	lion_b.face_dir = Vector2.DOWN
	lion_b.jaw = 0.0
	lion_b.eye = 0.0
	lion_b.dazed = 0.0
	lion_b.booped = false
	for lion: Dictionary in [lion_a, lion_b]:
		lion.stride = 0.0
		lion.speed = 0.0
		lion.prev = lion.pos
		lion.leap_from = lion.pos
		lion.leap_t = 0.0

	register_legs(m)


func register_legs(m: Node2D) -> void:
	leg_indices.clear()
	leg_soft_indices.clear()
	leg_poles.clear()
	var pos_a: Vector2 = lion_a.pos + Vector2(0.0, 16.0)
	var pos_b: Vector2 = lion_b.pos + Vector2(0.0, 16.0)
	for lp: Vector2 in [pos_a, pos_b]:
		leg_indices.append(m.poles.size())
		leg_soft_indices.append(m.rope_soft.size())
		m.poles.append(lp)
		m.rope_radii.append(LEG_RADIUS + 2.0)
		m.rope_soft.append(lp)
		leg_poles.append(lp)


func update_leg_positions() -> void:
	if leg_poles.size() < 2 or main == null:
		return
	leg_poles[0] = lion_a.pos + lion_a.face_dir * 14.0
	leg_poles[1] = lion_b.pos + lion_b.face_dir * 14.0
	for k in range(2):
		var pi: int = leg_indices[k]
		if pi < main.poles.size():
			main.poles[pi] = leg_poles[k]
		var si: int = leg_soft_indices[k]
		if si < main.rope_soft.size():
			main.rope_soft[si] = leg_poles[k]


func is_leg_index(i: int) -> bool:
	return not leg_indices.is_empty() and i >= leg_indices[0] and i <= leg_indices[leg_indices.size() - 1]


func in_fight() -> bool:
	return state != State.IDLE and state != State.SAT and state != State.CONTENT


func _sfx(sound: String, pitch: float = 1.0, db: float = 0.0) -> void:
	if main != null and main.has_node("/root/Sfx"):
		main.get_node("/root/Sfx").play(sound, pitch, db)


func tick_state(delta: float) -> void:
	state_t += delta
	act_t += delta
	_update_fx(delta)
	update_leg_positions()

	match state:
		State.IDLE:
			_tick_idle(delta)
		State.AWAKEN:
			_tick_awaken(delta)
		State.PROWL:
			_tick_prowl(delta)
		State.PINCER_WARN:
			_tick_pincer_warn(delta)
		State.PINCER_STRIKE:
			_tick_pincer_strike(delta)
		State.ROAR_WARN:
			_tick_roar_warn(delta)
		State.ROAR_BLAST:
			_tick_roar_blast(delta)
		State.RUSH_WARN:
			_tick_rush_warn(delta)
		State.RUSH_CHARGE:
			_tick_rush_charge(delta)
		State.STUNNED:
			_tick_stunned(delta)
		State.RETREAT:
			_tick_retreat(delta)
		State.STAND:
			_tick_stand(delta)
		State.WRAPPED:
			_tick_wrapped(delta)
		State.SAT:
			_tick_sat(delta)
		State.CONTENT:
			_tick_content(delta)
	_track_gait(delta)


# What the drawing needs of how they moved this tick: paw travel and pace,
# and a cut to a new spot (the rush's starts) kept to show as a bound.
func _track_gait(delta: float) -> void:
	for lion: Dictionary in [lion_a, lion_b]:
		var p: Vector2 = lion.pos
		var d: float = p.distance_to(lion.prev)
		if d > LEAP_JUMP:
			lion.leap_from = lion.prev
			lion.leap_t = LEAP_TIME
			d = 0.0
		else:
			lion.stride = float(lion.stride) + d
			lion.leap_t = maxf(0.0, float(lion.leap_t) - delta)
		lion.speed = lerpf(float(lion.speed), d / maxf(delta, 0.0001), 0.3)
		lion.prev = p


func _tick_idle(_delta: float) -> void:
	var dp: Vector2 = main.dog.global_position
	if dp.y < WAKE_Y:
		if not film_shown:
			var FP: GDScript = load("res://intro/film_player.gd")
			if FP != null and FP.should_play(main):
				film_shown = true
				FP.play(main, load(FILM))
		transition_to(State.AWAKEN)


func _tick_awaken(_delta: float) -> void:
	_hold_human()
	# Step 1: left lion yawns (0.0 .. 1.2s)
	if act_t < 1.2:
		lion_a.jaw = clampf(act_t / 0.6, 0.0, 1.0)
		lion_a.eye = clampf(act_t / 0.8, 0.0, 1.0)
	# Step 2: right lion blinks open (1.0 .. 2.0s)
	if act_t >= 1.0 and act_t < 2.0:
		lion_b.eye = clampf((act_t - 1.0) / 0.6, 0.0, 1.0)
	# Step 3: hop down from plinths (2.0 .. 3.0s)
	if act_t >= 2.0:
		var k := clampf((act_t - 2.0) / 0.8, 0.0, 1.0)
		lion_a.pos = PLINTH_L.lerp(PLINTH_L + Vector2(20.0, 60.0), k)
		lion_b.pos = PLINTH_R.lerp(PLINTH_R + Vector2(-20.0, 60.0), k)
		var dp: Vector2 = main.dog.global_position
		lion_a.face_dir = (dp - (lion_a.pos as Vector2)).normalized()
		lion_b.face_dir = (dp - (lion_b.pos as Vector2)).normalized()

	if act_t >= 3.0:
		_sfx("lion_roar", 1.0, -1.0)
		main.feed.say("WATCH OUT! THE BRONZE LIONS OF EL PORT!", EventFeed.Tone.LOUD)
		transition_to(State.PROWL)


func _tick_prowl(delta: float) -> void:
	_hold_human()
	pincer_cd -= delta
	roar_cd -= delta
	rush_cd -= delta

	var dp: Vector2 = main.dog.global_position
	# Steer lions in flanking prowl around the dog
	var target_a: Vector2 = dp + Vector2(-120.0, -40.0)
	var target_b: Vector2 = dp + Vector2(120.0, -40.0)
	lion_a.pos = (lion_a.pos as Vector2).move_toward(target_a, 110.0 * delta)
	lion_b.pos = (lion_b.pos as Vector2).move_toward(target_b, 110.0 * delta)
	lion_a.face_dir = (dp - (lion_a.pos as Vector2)).normalized()
	lion_b.face_dir = (dp - (lion_b.pos as Vector2)).normalized()

	# In phase 2 (HP <= 50), try Double Rush
	if phase >= 2 and rush_cd <= 0.0:
		_start_rush()
		return

	if pincer_cd <= 0.0:
		_start_pincer()
		return

	if roar_cd <= 0.0:
		_start_roar()
		return


func _start_pincer() -> void:
	var dp: Vector2 = main.dog.global_position
	pincer_targets[0] = dp + Vector2(40.0, 0.0)
	pincer_targets[1] = dp + Vector2(-40.0, 0.0)
	pincer_cd = PINCER_COOLDOWN
	pincer_dodged = false
	pincer_hit = false
	transition_to(State.PINCER_WARN)


func _tick_pincer_warn(_delta: float) -> void:
	_hold_human()
	lion_a.face_dir = (pincer_targets[0] - (lion_a.pos as Vector2)).normalized()
	lion_b.face_dir = (pincer_targets[1] - (lion_b.pos as Vector2)).normalized()
	if act_t >= PINCER_WARN:
		transition_to(State.PINCER_STRIKE)


func _tick_pincer_strike(delta: float) -> void:
	_hold_human()
	lion_a.pos = (lion_a.pos as Vector2).move_toward(pincer_targets[0], PINCER_SPEED * delta)
	lion_b.pos = (lion_b.pos as Vector2).move_toward(pincer_targets[1], PINCER_SPEED * delta)

	var dp: Vector2 = main.dog.global_position
	var hp_pos: Vector2 = main.human.global_position
	# Check dog dodge
	if not pincer_dodged and not pincer_hit:
		var d_a: float = (lion_a.pos as Vector2).distance_to(dp)
		var d_b: float = (lion_b.pos as Vector2).distance_to(dp)
		if d_a < BODY_R + 10.0 or d_b < BODY_R + 10.0:
			# hit once a pincer: the warning lanes were the telegraph
			pincer_hit = true
			var mid: Vector2 = ((lion_a.pos as Vector2) + (lion_b.pos as Vector2)) * 0.5
			main.dog.knocked((dp - mid).normalized() if dp.distance_to(mid) > 1.0 else Vector2.DOWN, "lion")
			main.human.say_line("Ouch! Careful!")
		elif d_a < BODY_R + 45.0 or d_b < BODY_R + 45.0:
			# Close miss awards dodge
			pincer_dodged = true
			main.lleons_pincer_dodges += 1
			main.award_points(3, "pincer dodged! +3")
			main.feed.say("PINCER DODGE!", EventFeed.Tone.GOOD)
			_take_damage(12.0)

	if (lion_a.pos as Vector2).distance_to(pincer_targets[0]) < 8.0 and (lion_b.pos as Vector2).distance_to(pincer_targets[1]) < 8.0:
		transition_to(State.PROWL)


func _start_roar() -> void:
	# Alternate between lion A and lion B
	roaring_lion = lion_a if randf() < 0.5 else lion_b
	var dp: Vector2 = main.dog.global_position
	roaring_lion.face_dir = (dp - (roaring_lion.pos as Vector2)).normalized()
	roar_cd = ROAR_COOLDOWN
	roar_paid = false
	transition_to(State.ROAR_WARN)


func _tick_roar_warn(_delta: float) -> void:
	_hold_human()
	var dp: Vector2 = main.dog.global_position
	roaring_lion.face_dir = (dp - (roaring_lion.pos as Vector2)).normalized()
	roaring_lion.jaw = clampf(act_t / ROAR_WARN, 0.0, 1.0)
	if act_t >= ROAR_WARN:
		_sfx("lion_roar", 1.05, 0.0)
		transition_to(State.ROAR_BLAST)


func _tick_roar_blast(delta: float) -> void:
	_hold_human()
	var dp: Vector2 = main.dog.global_position
	var to_dog: Vector2 = dp - (roaring_lion.pos as Vector2)
	var dist: float = to_dog.length()
	var r_dir: Vector2 = roaring_lion.face_dir
	var angle: float = absf(r_dir.angle_to(to_dog))

	if dist < ROAR_REACH and angle < ROAR_HALF:
		# Inside the roar wind cone!
		# If dog is planted, 14x mass resists the push!
		var push: Vector2 = r_dir * ROAR_PUSH_FORCE * (1.0 - dist / ROAR_REACH)
		if main.dog.planted:
			main.dog.velocity += push * 0.15
			if not roar_paid:
				roar_paid = true
				main.award_points(2, "planted! +2")
		else:
			main.dog.velocity += push * delta * 60.0

	if act_t >= ROAR_DUR:
		roaring_lion.jaw = 0.0
		_take_damage(8.0)
		transition_to(State.PROWL)


func _start_rush() -> void:
	# aim both lanes at where she stands now; each lion gets the speed that
	# brings it to the crossing at the same moment
	var dp: Vector2 = main.dog.global_position
	rush_cross_pos = Vector2(clampf(dp.x, ARENA_X.x, ARENA_X.y), clampf(dp.y, ARENA_Y.x, ARENA_Y.y))
	rush_starts[0] = rush_cross_pos + Vector2(-RUSH_SPREAD.x, RUSH_SPREAD.y)
	rush_starts[1] = rush_cross_pos + Vector2(RUSH_SPREAD.x, RUSH_SPREAD.y)
	for i in range(2):
		rush_starts[i].x = clampf(rush_starts[i].x, ARENA_X.x - 40.0, ARENA_X.y + 40.0)
		rush_ends[i] = rush_cross_pos + (rush_cross_pos - rush_starts[i])
		rush_speeds[i] = rush_starts[i].distance_to(rush_cross_pos) / RUSH_TO_CROSS
	rush_hit = false
	lion_a.pos = rush_starts[0]
	lion_b.pos = rush_starts[1]
	lion_a.face_dir = (rush_ends[0] - rush_starts[0]).normalized()
	lion_b.face_dir = (rush_ends[1] - rush_starts[1]).normalized()
	rush_cd = RUSH_COOLDOWN
	transition_to(State.RUSH_WARN)


func _tick_rush_warn(_delta: float) -> void:
	_hold_human()
	if act_t >= RUSH_WARN:
		transition_to(State.RUSH_CHARGE)


func _tick_rush_charge(delta: float) -> void:
	_hold_human()
	lion_a.pos = lion_a.pos.move_toward(rush_ends[0], rush_speeds[0] * delta)
	lion_b.pos = lion_b.pos.move_toward(rush_ends[1], rush_speeds[1] * delta)
	var dp: Vector2 = main.dog.global_position
	# run over on the way: once a rush
	if not rush_hit:
		for lion: Dictionary in [lion_a, lion_b]:
			if (lion.pos as Vector2).distance_to(dp) < BODY_R + 6.0:
				rush_hit = true
				main.dog.knocked(((dp - (lion.pos as Vector2)).normalized()) if dp.distance_to(lion.pos) > 1.0 else Vector2.DOWN, "lion")
				break

	# they meet at the crossing: only an empty crossing makes them collide;
	# she still there, or already run over, and they run on to their ends
	var dist_between: float = lion_a.pos.distance_to(lion_b.pos)
	if dist_between < (BODY_R + HEAD_R) * 1.5 and not rush_hit:
		if dp.distance_to(rush_cross_pos) > RUSH_CLEAR:
			_trigger_head_bump()
			return
		rush_hit = true

	if lion_a.pos.distance_to(rush_ends[0]) < 10.0 and lion_b.pos.distance_to(rush_ends[1]) < 10.0:
		transition_to(State.PROWL)


func _trigger_head_bump() -> void:
	bump_done = true
	main.lleons_bumped = true
	_sfx("head_bump", 1.0, 0.0)
	main.shake_t = maxf(float(main.shake_t), 0.7)
	main.award_points(20, "head bump! +20")
	main.feed.say("HEAD BUMP! BOTH LIONS DAZED!", EventFeed.Tone.LOUD)
	_take_damage(25.0)

	# Spawn bronze collision spark particles
	for k in range(16):
		var a := float(k) * (TAU / 16.0)
		var spd := randf_range(120.0, 280.0)
		sparks.append({
			"pos": rush_cross_pos,
			"vel": Vector2(cos(a), sin(a)) * spd,
			"life": 0.8,
			"max_life": 0.8,
			"col": BRONZE_SHINE,
		})

	lion_a.dazed = BUMP_STUN
	lion_b.dazed = BUMP_STUN
	lion_a.booped = false
	lion_b.booped = false
	transition_to(State.STUNNED)


func _tick_stunned(delta: float) -> void:
	_hold_human()
	lion_a.dazed -= delta
	lion_b.dazed -= delta
	if lion_a.dazed <= 0.0 and lion_b.dazed <= 0.0:
		if hp <= 10.0:
			transition_to(State.RETREAT)
		else:
			transition_to(State.PROWL)


func _tick_retreat(delta: float) -> void:
	_hold_human()
	lion_a.pos = lion_a.pos.move_toward(PLINTH_L, 160.0 * delta)
	lion_b.pos = lion_b.pos.move_toward(PLINTH_R, 160.0 * delta)
	lion_a.face_dir = (PLINTH_L - lion_a.pos).normalized() if lion_a.pos.distance_to(PLINTH_L) > 5.0 else Vector2.DOWN
	lion_b.face_dir = (PLINTH_R - lion_b.pos).normalized() if lion_b.pos.distance_to(PLINTH_R) > 5.0 else Vector2.DOWN

	if lion_a.pos.distance_to(PLINTH_L) < 8.0 and lion_b.pos.distance_to(PLINTH_R) < 8.0:
		transition_to(State.STAND)


func _tick_stand(_delta: float) -> void:
	_hold_human()
	lion_a.pos = PLINTH_L
	lion_b.pos = PLINTH_R
	lion_a.face_dir = Vector2.DOWN
	lion_b.face_dir = Vector2.DOWN
	update_leg_tangle()


func update_leg_tangle() -> void:
	var now: float = main.elapsed
	legs_tied = 0
	for k in range(leg_poles.size()):
		if main.leash != null and main.leash.touches(leg_poles[k]):
			leg_touch_t[k] = now
		if now - leg_touch_t[k] <= LEG_MEMORY:
			legs_tied += 1
	if legs_tied >= LEGS_TO_TIE:
		transition_to(State.WRAPPED)


func _tick_wrapped(_delta: float) -> void:
	_hold_human()
	if act_t >= 0.8:
		_sfx("drum", 0.4, 0.0)
		main.shake_t = maxf(float(main.shake_t), 0.5)
		main.feed.say("THEY SAT! BOOP THEIR NOSES!", EventFeed.Tone.LOUD)
		main.lleons_tied = true
		lion_a.booped = false
		lion_b.booped = false
		transition_to(State.SAT)


func _tick_sat(_delta: float) -> void:
	_hold_human()
	# Waiting for barks on both lions' noses
	if lion_a.booped and lion_b.booped:
		transition_to(State.CONTENT)


func _tick_content(_delta: float) -> void:
	# Battle won!
	main.lleons_settled = true
	if not win_film_shown:
		var FP: GDScript = load("res://intro/film_player.gd")
		if FP != null and FP.should_play(main):
			win_film_shown = true
			FP.play(main, load(FILM_WIN))


func on_bark_action(bark_pos: Vector2) -> bool:
	if state == State.STUNNED:
		var hit := false
		if not lion_a.booped and bark_pos.distance_to(lion_a.pos + lion_a.face_dir * HEAD_R) < BOOP_REACH:
			lion_a.booped = true
			hit = true
		if not lion_b.booped and bark_pos.distance_to(lion_b.pos + lion_b.face_dir * HEAD_R) < BOOP_REACH:
			lion_b.booped = true
			hit = true
		if hit:
			_sfx("star", 1.2, -4.0)
			main.award_points(10, "boop! +10")
			_take_damage(10.0)
			return true

	if state == State.SAT:
		var hit := false
		if not lion_a.booped and bark_pos.distance_to(lion_a.pos + lion_a.face_dir * HEAD_R) < BOOP_REACH:
			lion_a.booped = true
			hit = true
		if not lion_b.booped and bark_pos.distance_to(lion_b.pos + lion_b.face_dir * HEAD_R) < BOOP_REACH:
			lion_b.booped = true
			hit = true
		if hit:
			_sfx("star", 1.3, -3.0)
			main.award_points(15, "boop! +15")
			if lion_a.booped and lion_b.booped:
				main.feed.say("GOOD PUPS... ER, BIG CATS!", EventFeed.Tone.GOOD)
			return true
	return false


func _take_damage(dmg: float) -> void:
	hp = maxf(0.0, hp - dmg)
	if hp <= 50.0 and phase == 1:
		phase = 2
		main.feed.say("ELS LLEONS ENRAGED! WATCH THE CROSSING!", EventFeed.Tone.LOUD)
	if hp <= 10.0 and state != State.STUNNED and state != State.RETREAT and state != State.STAND:
		transition_to(State.RETREAT)


func transition_to(new_state: State) -> void:
	state = new_state
	state_t = 0.0
	act_t = 0.0


func _hold_human() -> void:
	if main.human == null:
		return
	if main.human.global_position.y < HOLD_Y:
		main.human.global_position.y = HOLD_Y
		main.human.velocity.y = maxf(main.human.velocity.y, 0.0)
		if not hold_noticed:
			hold_noticed = true
			main.human.notice("Whoa... since when do statues move?!", 2.4)


func _update_fx(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for s: Dictionary in sparks:
		s.pos += s.vel * delta
		s.life -= delta
		if s.life > 0.0:
			remaining.append(s)
	sparks = remaining


func status() -> String:
	match state:
		State.PINCER_WARN:
			return "PINCER ATTACK! STEP OUT!"
		State.ROAR_WARN:
			return Prompts.fill("INCOMING ROAR! {plant} TO DIG IN!")
		State.RUSH_WARN:
			return "CROSSING RUSH! TRICK THEM INTO COLLIDING!"
		State.STUNNED:
			return Prompts.fill("HEAD BUMP! {bark} AT THEIR NOSES!")
		State.STAND:
			return "LOOP LEASH AROUND BOTH PLINTHS  %d/%d" % [legs_tied, LEGS_TO_TIE]
		State.SAT:
			return Prompts.fill("{bark} ON EACH NOSE TO SETTLE THEM")
	return ""


func hush_banner() -> bool:
	return state == State.AWAKEN or state == State.PINCER_WARN or state == State.RUSH_WARN


# --- Drawing -----------------------------------------------------------------
# Everything goes through the walk's one ShapeBatch: no draw call of its own.
# A lion is drawn in his own frame (x along his nose, y across him) at
# DRAW_K, in one of seven poses picked from the fight's state.

func draw(wc: ShapeBatch, vt: float, vb: float) -> void:
	if COLOM_POS.y < vt - 600.0 or COLOM_POS.y > vb + 600.0:
		return
	var t: float = AnimClock.msec() / 1000.0

	_draw_plinth(wc, PLINTH_L, lion_a)
	_draw_plinth(wc, PLINTH_R, lion_b)

	if state == State.PINCER_WARN:
		_draw_pincer_warning(wc, t)
	elif state == State.ROAR_WARN or state == State.ROAR_BLAST:
		_draw_roar_cone(wc, t)
	elif state == State.RUSH_WARN:
		_draw_rush_warning(wc, t)

	# the far one first, so the near one overlaps him
	if (lion_a.pos as Vector2).y <= (lion_b.pos as Vector2).y:
		_draw_lion(wc, lion_a, t)
		_draw_lion(wc, lion_b, t)
	else:
		_draw_lion(wc, lion_b, t)
		_draw_lion(wc, lion_a, t)
	_draw_marks(wc, t)

	for sp: Dictionary in sparks:
		var k: float = float(sp.life) / float(sp.max_life)
		var col: Color = sp.col
		col.a = minf(k * 2.0, 1.0)
		wc.line(sp.pos, (sp.pos as Vector2) - (sp.vel as Vector2) * 0.05, col, 3.0 * k + 1.0)


# The stone corner plinth and its bronze plaque; with the lion away, the worn
# hollow he lay in.
func _draw_plinth(wc: ShapeBatch, p: Vector2, lion: Dictionary) -> void:
	var r := Rect2(p - PLINTH_HALF, PLINTH_HALF * 2.0)
	wc.rect(Rect2(r.position + Shade.light * 10.0, r.size), SHADOW)
	wc.rect(r, PLINTH_DARK)
	wc.rect(r.grow(-4.0), PLINTH_COL)
	wc.rect(Rect2(r.position + Vector2(4.0, 4.0), Vector2(r.size.x - 8.0, 3.0)), PLINTH_COL.lightened(0.16))
	wc.rect(Rect2(r.position + Vector2(4.0, 4.0), Vector2(3.0, r.size.y - 8.0)), PLINTH_COL.lightened(0.10))
	var pq := Rect2(p.x - 18.0, r.end.y - 15.0, 36.0, 9.0)
	wc.rect(pq, BRONZE_DEEP)
	wc.rect(pq.grow(-1.5), BRONZE)
	wc.line(Vector2(pq.position.x + 5.0, pq.get_center().y), Vector2(pq.end.x - 5.0, pq.get_center().y), BRONZE_DEEP, 1.0)
	if (lion.pos as Vector2).distance_to(p) > 30.0 and float(lion.leap_t) <= 0.0:
		var worn := Color(0.44, 0.47, 0.42, 0.55)
		wc.polygon(_ellipse(p + Vector2(0.0, -4.0), Vector2.DOWN, 30.0, 22.0, 16), worn)
		for sd: float in [-1.0, 1.0]:
			wc.circle(p + Vector2(sd * 14.0, 26.0), 6.0, worn)


func _pose_of(lion: Dictionary) -> Pose:
	if float(lion.leap_t) > 0.0:
		return Pose.CHARGE
	match state:
		State.IDLE, State.STAND, State.CONTENT, State.WRAPPED:
			return Pose.REST
		State.AWAKEN:
			if act_t < 2.0:
				return Pose.REST
			return Pose.CHARGE if act_t < 2.8 else Pose.ROAR
		State.SAT:
			return Pose.SIT
		State.PINCER_WARN, State.RUSH_WARN:
			return Pose.CROUCH
		State.PINCER_STRIKE, State.RUSH_CHARGE:
			return Pose.CHARGE if float(lion.speed) > 40.0 else Pose.WALK
		State.ROAR_WARN, State.ROAR_BLAST:
			return Pose.ROAR if is_same(lion, roaring_lion) else Pose.WALK
		State.STUNNED:
			return Pose.DAZED if float(lion.dazed) > 0.0 else Pose.WALK
	return Pose.WALK


# how far his jaw is open: the yawn of the wake, the roar that ends it, and
# the roar attack. Not lion.jaw alone, which the wake leaves open.
func _jaw_of(lion: Dictionary) -> float:
	match state:
		State.AWAKEN:
			if act_t >= 2.8:
				return clampf((act_t - 2.8) / 0.15, 0.0, 1.0)
			if float(lion.side) < 0.0:
				return clampf(act_t / 0.6, 0.0, 1.0) * (1.0 - clampf((act_t - 1.0) / 0.4, 0.0, 1.0))
			return 0.0
		State.ROAR_WARN, State.ROAR_BLAST:
			if is_same(lion, roaring_lion):
				return maxf(float(lion.jaw), 1.0 if state == State.ROAR_BLAST else 0.0)
	return 0.0


func _draw_lion(b: ShapeBatch, lion: Dictionary, t: float) -> void:
	var f: Vector2 = lion.face_dir
	if f.length_squared() < 0.01:
		f = Vector2.DOWN
	var at: Vector2 = lion.pos
	var sd: float = lion.side
	var pose := _pose_of(lion)
	var jaw := _jaw_of(lion)
	var lift := 0.0
	var airborne := false
	if float(lion.leap_t) > 0.0:
		# the cut to the rush's start, shown as a bound to it
		var u := 1.0 - float(lion.leap_t) / LEAP_TIME
		at = (lion.leap_from as Vector2).lerp(at, u * u * (3.0 - 2.0 * u))
		lift = sin(u * PI) * 30.0
		airborne = true
	elif state == State.AWAKEN and act_t >= 2.0 and act_t < 2.8:
		lift = sin((act_t - 2.0) / 0.8 * PI) * 24.0
		airborne = true
	elif state == State.WRAPPED:
		at.x += sin(act_t * 16.0) * (2.0 + act_t * 8.0)
	elif pose == Pose.DAZED:
		at.x += sin(t * 9.0 + sd) * 1.5
	var ph: float = float(lion.stride) / 15.0
	var awake := float(lion.eye) > 0.05 and state != State.IDLE
	var breath := sin(t * 1.7 + sd) * 0.5 if awake else 0.0

	# the pose: spine ends and girth, paws (front left, front right, hind
	# left, hind right) and where each leg leaves the body, the mane, the head
	var rear := Vector2(-22.0, 0.0)
	var chest := Vector2(6.0, 0.0)
	var girth := 19.0
	var roots: Array[Vector2] = [Vector2(12.0, -13.0), Vector2(12.0, 13.0), Vector2(-20.0, -14.0), Vector2(-20.0, 14.0)]
	var paws: Array[Vector2] = [Vector2(40.0, -12.0), Vector2(40.0, 12.0), Vector2(0.0, -24.0), Vector2(0.0, 24.0)]
	var haunch := 11.0            # the folded hind leg's bulge; 0 for none
	var mane_c := Vector2(14.0, 0.0)
	var mane_r := 21.0
	var sweep := 0.0              # the mane blown back
	var head_c := Vector2(25.0, 0.0)
	var head_rot := 0.0
	var tail: Array[Vector2] = []
	var shadow_len := 46.0
	match pose:
		Pose.REST:
			tail = [Vector2(-38.0, 0.0), Vector2(-45.0, sd * 10.0), Vector2(-40.0, sd * 22.0), Vector2(-24.0, sd * 28.0), Vector2(-12.0, sd * 28.0)]
		Pose.SIT:
			rear = Vector2(-12.0, 0.0)
			chest = Vector2(6.0, 0.0)
			girth = 17.0
			haunch = 13.0
			roots = [Vector2(10.0, -7.0), Vector2(10.0, 7.0), Vector2(-12.0, -15.0), Vector2(-12.0, 15.0)]
			paws = [Vector2(23.0, -7.0), Vector2(23.0, 7.0), Vector2(2.0, -22.0), Vector2(2.0, 22.0)]
			mane_c = Vector2(6.0, 0.0)
			head_c = Vector2(15.0, 0.0)
			head_rot = sin(t * 1.3 + sd) * 0.12
			tail = [Vector2(-30.0, 0.0), Vector2(-33.0, sd * 16.0), Vector2(-22.0, sd * 28.0), Vector2(-4.0, sd * 31.0), Vector2(12.0, sd * 26.0)]
			shadow_len = 36.0
		Pose.WALK:
			var sw := sin(ph) * 9.0
			rear = Vector2(-26.0, sin(ph) * 1.5)
			chest = Vector2(12.0, -sin(ph) * 1.5)
			girth = 16.0
			haunch = 0.0
			roots = [Vector2(10.0, -11.0), Vector2(10.0, 11.0), Vector2(-22.0, -11.0), Vector2(-22.0, 11.0)]
			paws = [Vector2(17.0 + sw, -19.0), Vector2(17.0 - sw, 19.0), Vector2(-22.0 - sw, -19.0), Vector2(-22.0 + sw, 19.0)]
			mane_c = Vector2(20.0, 0.0)
			mane_r = 20.0
			head_c = Vector2(31.0, 0.0)
			head_rot = sin(ph) * 0.06
			tail = _trail(-42.0, 11.0, sin(t * 3.0 + sd) * 7.0, sin(t * 3.0 + sd + 1.1) * 10.0)
			shadow_len = 50.0
		Pose.CROUCH:
			# low, rump up and wriggling, tail lashing: about to go
			var wig := sin(t * 24.0 + sd) * 2.5
			rear = Vector2(-20.0, wig)
			chest = Vector2(8.0, 0.0)
			girth = 19.0
			roots = [Vector2(8.0, -13.0), Vector2(8.0, 13.0), Vector2(-18.0, -14.0 + wig), Vector2(-18.0, 14.0 + wig)]
			paws = [Vector2(30.0, -15.0), Vector2(30.0, 15.0), Vector2(-12.0, -24.0 + wig), Vector2(-12.0, 24.0 + wig)]
			mane_c = Vector2(17.0, 0.0)
			head_c = Vector2(29.0, 0.0)
			tail = _trail(-36.0, 10.0, sin(t * 10.0 + sd) * 10.0 + wig, sin(t * 10.0 + sd + 1.3) * 16.0)
		Pose.CHARGE:
			# the gallop: all four reaching, then gathered under him
			var e := 1.0 if airborne else 0.5 + 0.5 * sin(float(lion.stride) / 20.0)
			rear = Vector2(-28.0, 0.0)
			chest = Vector2(13.0, 0.0)
			girth = 16.0
			haunch = 0.0
			roots = [Vector2(12.0, -9.0), Vector2(12.0, 9.0), Vector2(-25.0, -9.0), Vector2(-25.0, 9.0)]
			paws = [Vector2(lerpf(16.0, 44.0, e), -10.0), Vector2(lerpf(20.0, 40.0, e), 10.0),
				Vector2(lerpf(-16.0, -46.0, e), -11.0), Vector2(lerpf(-20.0, -42.0, e), 11.0)]
			mane_c = Vector2(22.0, 0.0)
			mane_r = 19.0
			sweep = 7.0
			head_c = Vector2(34.0, 0.0)
			tail = _trail(-42.0, 12.0, sin(t * 14.0 + sd) * 3.0, sin(t * 14.0 + sd + 1.0) * 5.0)
			shadow_len = 56.0
		Pose.ROAR:
			# braced, head thrust out, the mane standing on end
			var shake := sin(t * 55.0) * 1.2 * jaw
			rear = Vector2(-24.0, 0.0)
			chest = Vector2(8.0, shake)
			girth = 18.0
			haunch = 0.0
			roots = [Vector2(8.0, -13.0), Vector2(8.0, 13.0), Vector2(-22.0, -13.0), Vector2(-22.0, 13.0)]
			paws = [Vector2(19.0, -24.0), Vector2(19.0, 24.0), Vector2(-25.0, -22.0), Vector2(-25.0, 22.0)]
			mane_c = Vector2(18.0, shake)
			mane_r = 21.0 * (1.0 + 0.2 * jaw)
			head_c = Vector2(30.0 + 4.0 * jaw, shake)
			tail = _trail(-40.0, 11.0, sd * 4.0, -sd * 3.0)
		Pose.DAZED:
			rear = Vector2(-22.0, 0.0)
			chest = Vector2(8.0, 0.0)
			girth = 18.0
			haunch = 0.0
			roots = [Vector2(10.0, -13.0), Vector2(10.0, 13.0), Vector2(-20.0, -13.0), Vector2(-20.0, 13.0)]
			paws = [Vector2(20.0, -31.0), Vector2(14.0, 31.0), Vector2(-26.0, -30.0), Vector2(-18.0, 31.0)]
			mane_c = Vector2(16.0, 0.0)
			head_c = Vector2(27.0, 0.0)
			head_rot = sin(t * 2.6 + sd) * 0.4
			tail = _trail(-38.0, 9.0, sd * 8.0, -sd * 9.0)

	# the shadow stays on the ground; everything else rides the hop
	b.polygon(_ellipse(at + Shade.light * (9.0 + lift * 0.5), f, shadow_len * DRAW_K * (1.0 - lift * 0.004), 27.0 * DRAW_K, 18), SHADOW)
	var x := Transform2D(f * DRAW_K, f.orthogonal() * DRAW_K, at - Vector2(0.0, lift))
	var hi := -Shade.light * 2.6        # toward the light, in world space

	# tail, under the body
	for i in range(tail.size() - 1):
		b.capsule(x * tail[i], x * tail[i + 1], 3.6 * DRAW_K, BRONZE_DEEP)
	for i in range(tail.size() - 1):
		b.capsule(x * tail[i] + hi * 0.3, x * tail[i + 1] + hi * 0.3, 2.2 * DRAW_K, BRONZE_DARK)
	var tip: Vector2 = x * tail[tail.size() - 1]
	var tip_d: Vector2 = (tip - x * tail[tail.size() - 2]).normalized()
	b.capsule(tip, tip + tip_d * 7.0, 5.4 * DRAW_K, BRONZE_DEEP)
	b.capsule(tip, tip + tip_d * 7.0, 3.8 * DRAW_K, PATINA_DARK)
	b.line(tip, tip + tip_d * 8.0, PATINA, 1.4)

	# legs and paws
	for i in range(4):
		var root: Vector2 = x * roots[i]
		var paw: Vector2 = x * paws[i]
		var lr := (6.2 if i < 2 else 5.6) * DRAW_K
		b.capsule(root, paw, lr + 2.0, BRONZE_DEEP)
		b.capsule(root, paw, lr, PATINA_DARK)
		b.capsule(root + hi * 0.5, paw + hi * 0.5, lr - 1.6, BRONZE_DARK)
	if haunch > 0.0:
		for sd2: float in [-1.0, 1.0]:
			var h0: Vector2 = x * Vector2(rear.x - 2.0, rear.y + sd2 * 13.0)
			var h1: Vector2 = x * Vector2(rear.x + 12.0, rear.y + sd2 * 18.0)
			b.capsule(h0, h1, (haunch + 2.0) * DRAW_K, BRONZE_DEEP)
			b.capsule(h0, h1, haunch * DRAW_K, PATINA_DARK)
			b.capsule(h0 + hi, h1 + hi, (haunch - 2.2) * DRAW_K, BRONZE_DARK)
			b.circle(h0.lerp(h1, 0.5) + hi * 1.8, haunch * 0.5 * DRAW_K, BRONZE)
	for i in range(4):
		_paw(b, x * paws[i], f, 7.4 if i < 2 else 5.8)

	# the body: patina down the shadow side, bronze where the light and a
	# century of hands have kept it
	var p0: Vector2 = x * rear
	var p1: Vector2 = x * chest
	var gr := (girth + breath) * DRAW_K
	# deep chest, narrow loins, round rump: three girths along one spine
	var loin := gr * 0.84
	var chest_r := gr * 1.08
	b.capsule(p0, p1, loin + 2.4, BRONZE_DEEP)
	b.circle(p1, chest_r + 2.4, BRONZE_DEEP)
	b.circle(p0, gr + 2.4, BRONZE_DEEP)
	b.capsule(p0, p1, loin, PATINA_DARK)
	b.circle(p1, chest_r, PATINA_DARK)
	b.circle(p0, gr, PATINA_DARK)
	b.capsule(p0 + hi, p1 + hi, loin - 2.4, BRONZE_DARK)
	b.circle(p1 + hi, chest_r - 2.4, BRONZE_DARK)
	b.circle(p0 + hi, gr - 2.4, BRONZE_DARK)
	b.circle(p0 + hi * 2.0, gr * 0.5, BRONZE)
	b.capsule(p0.lerp(p1, 0.1) + hi * 2.2, p0.lerp(p1, 0.8) + hi * 2.2, gr * 0.52, BRONZE)
	b.line(p0.lerp(p1, 0.05) + hi * 2.6, p0.lerp(p1, 0.7) + hi * 2.6, BRONZE_LIT, 1.8)
	# verdigris runs down the flanks, along the ribs
	var across: Vector2 = f.orthogonal()
	var run := Color(PATINA.r, PATINA.g, PATINA.b, 0.55)
	for i in range(3):
		var u := 0.2 + float(i) * 0.22
		var rp: Vector2 = p0.lerp(p1, u)
		b.line(rp + across * loin * 0.45 - hi * 0.6, rp + across * loin * 0.88 - hi * 0.6 - f * 3.0, run, 1.5)
		b.line(rp - across * loin * 0.6, rp - across * loin * 0.88 - f * 3.0, Color(run.r, run.g, run.b, 0.35), 1.3)
	if pose == Pose.WALK or pose == Pose.CROUCH:
		# the shoulder blades, rolling as he prowls
		for sd2: float in [-1.0, 1.0]:
			var roll := sin(ph + (0.0 if sd2 < 0.0 else PI)) * 2.5
			b.circle(x * Vector2(chest.x - 6.0 + roll, chest.y + sd2 * 7.5) + hi * 0.6, 6.5 * DRAW_K, BRONZE)

	if pose == Pose.CHARGE and not airborne:
		for i in range(3):
			var o := (float(i) - 1.0) * 13.0
			var s0: Vector2 = x * Vector2(rear.x - 22.0, o)
			b.line(s0, s0 - f * (30.0 + float(i % 2) * 16.0), Color(1.0, 0.93, 0.80, 0.30), 2.5)

	_draw_head(b, lion, x * Transform2D(head_rot * 0.5, mane_c), x * Transform2D(head_rot, head_c),
		mane_r, sweep, jaw, pose, t)


# a tail trailing behind him: four joints swung by two waves
func _trail(from: float, step: float, w1: float, w2: float) -> Array[Vector2]:
	return [Vector2(from, 0.0), Vector2(from - step, w1 * 0.4), Vector2(from - step * 2.0, w1),
		Vector2(from - step * 3.0, (w1 + w2) * 0.5), Vector2(from - step * 4.0, w2)]


func _paw(b: ShapeBatch, at: Vector2, f: Vector2, r: float) -> void:
	var rr := r * DRAW_K
	var s := f.orthogonal()
	b.circle(at, rr + 1.8, BRONZE_DEEP)
	b.circle(at, rr, BRONZE_DARK)
	b.circle(at - Shade.light * 1.4, rr - 1.8, BRONZE)
	# toes, rubbed bright
	for n in range(3):
		var toe := at + f * rr * 0.72 + s * (float(n) - 1.0) * rr * 0.62
		b.circle(toe, rr * 0.36, BRONZE_DEEP)
		b.circle(toe - Shade.light * 0.5, rr * 0.25, BRONZE_SHINE)


# The mane and the head on it. `mx` is the mane's frame, `hx` the head's (x
# along the nose): a ruff of pointed locks open at the face, the broad
# skull with its ears, heavy brow, eyes, the pale muzzle and the nose.
func _draw_head(b: ShapeBatch, lion: Dictionary, mx: Transform2D, hx: Transform2D, mane_r: float,
		sweep: float, jaw: float, pose: Pose, t: float) -> void:
	var hi := -Shade.light * 2.2
	var sd: float = lion.side
	var n := 13
	var flare := jaw * 3.0
	var tips := PackedVector2Array()
	var bases := PackedVector2Array()
	for i in range(n):
		var a := PI * (0.30 + 1.40 * float(i) / float(n - 1))
		var jit := sin(t * 40.0 + float(i) * 2.1) * jaw * 1.4
		var d := Vector2.from_angle(a)
		tips.append(mx * (d * (mane_r + 4.5 + float(i % 2) * 2.5 + flare + jit) - Vector2(sweep, 0.0)))
		bases.append(mx * (Vector2.from_angle(a - 0.34) * (mane_r - 2.0)))
		bases.append(mx * (Vector2.from_angle(a + 0.34) * (mane_r - 2.0)))
	var mc: Vector2 = mx * Vector2.ZERO
	b.circle(mc, (mane_r + 2.4) * DRAW_K, BRONZE_DEEP)
	for i in range(n):
		var out: Vector2 = (tips[i] - mc).normalized()
		var wide: Vector2 = (bases[i * 2 + 1] - bases[i * 2]).normalized()
		b.quad(bases[i * 2] - wide * 2.4, tips[i] + out * 2.8, tips[i] + out * 2.8, bases[i * 2 + 1] + wide * 2.4, BRONZE_DEEP)
	for i in range(n):
		b.quad(bases[i * 2], tips[i], tips[i], bases[i * 2 + 1], PATINA_DARK if i % 2 == 0 else BRONZE_DARK)
	b.circle(mc, mane_r * DRAW_K, BRONZE_DARK)
	b.circle(mc + hi, (mane_r - 3.5) * DRAW_K, BRONZE)
	# the locks: cut lines between them, light on the crowns that face it,
	# green on the ones that do not
	for i in range(n):
		var a := PI * (0.30 + 1.40 * float(i) / float(n - 1))
		var d := Vector2.from_angle(a + 0.2)
		b.line(mx * (d * mane_r * 0.50), mx * (d * (mane_r - 1.0) - Vector2(sweep * 0.6, 0.0)), BRONZE_DEEP, 1.8)
		var d2 := Vector2.from_angle(a - 0.08)
		if mx.basis_xform(d2).normalized().dot(-Shade.light) > 0.1:
			b.line(mx * (d2 * mane_r * 0.58) + hi * 0.4, mx * (d2 * (mane_r - 2.5)) + hi * 0.4, BRONZE_LIT, 1.7)
		else:
			b.line(mx * (d2 * mane_r * 0.62), mx * (d2 * (mane_r - 2.0)), PATINA, 1.5)

	# ears, set back on the skull in the mane
	var nose_dir: Vector2 = hx.basis_xform(Vector2(1.0, 0.0)).normalized()
	for s2: float in [-1.0, 1.0]:
		var ep: Vector2 = hx * Vector2(-8.0, s2 * 9.5)
		b.circle(ep, 4.6 * DRAW_K, BRONZE_DEEP)
		b.circle(ep, 3.2 * DRAW_K, BRONZE)
		b.circle(ep + nose_dir * 0.8, 1.7 * DRAW_K, BRONZE_DEEP)

	# the open mouth goes under the muzzle: lower jaw, tongue, fangs
	if jaw > 0.02:
		var gape := 7.0 + 9.0 * jaw
		b.capsule(hx * Vector2(8.0, 0.0), hx * Vector2(8.0 + gape, 0.0), 7.4 * DRAW_K, BRONZE_DEEP)
		b.capsule(hx * Vector2(8.0, 0.0), hx * Vector2(8.0 + gape, 0.0), 5.9 * DRAW_K, BRONZE_DARK)
		b.capsule(hx * Vector2(9.0, 0.0), hx * Vector2(7.0 + gape, 0.0), 4.3 * DRAW_K, MOUTH)
		b.capsule(hx * Vector2(11.0, 0.0), hx * Vector2(6.0 + gape, 0.0), 2.2 * DRAW_K, TONGUE)
		for s2: float in [-1.0, 1.0]:
			var fang: Vector2 = hx * Vector2(9.0 + gape, s2 * 3.8)
			var back: Vector2 = fang - nose_dir * 5.5
			var w: Vector2 = nose_dir.orthogonal() * 1.8
			b.quad(fang - w, back, back, fang + w, FANG)

	# skull and muzzle
	var hc: Vector2 = hx * Vector2.ZERO
	b.circle(hc, 12.6 * DRAW_K, BRONZE_DEEP)
	b.circle(hc, 10.8 * DRAW_K, BRONZE_DARK)
	b.circle(hc + hi * 0.8, 8.8 * DRAW_K, BRONZE)
	b.circle(hx * Vector2(-3.0, 0.0) + hi, 4.6 * DRAW_K, BRONZE_LIT.lerp(BRONZE, 0.5))
	var m0: Vector2 = hx * Vector2(6.0, 0.0)
	var m1: Vector2 = hx * Vector2(13.5, 0.0)
	b.capsule(m0, m1, 6.9 * DRAW_K, BRONZE_DEEP)
	b.capsule(m0, m1, 5.5 * DRAW_K, BRONZE)
	b.capsule(m0 + hi * 0.5, m1 + hi * 0.5, 3.8 * DRAW_K, BRONZE_LIT)
	b.line(hx * Vector2(8.0, 0.0), hx * Vector2(15.0, 0.0), BRONZE_DARK, 1.4)
	# the nose, bright where everyone pats it
	var nose: Vector2 = hx * Vector2(18.5, 0.0)
	b.quad(hx * Vector2(15.0, -3.6), nose, nose, hx * Vector2(15.0, 3.6), BRONZE_DEEP)
	b.circle(hx * Vector2(15.6, 0.0) + hi * 0.3, 1.7 * DRAW_K, BRONZE_SHINE)
	for s2: float in [-1.0, 1.0]:
		for w in range(2):
			b.circle(hx * Vector2(10.0 + float(w) * 3.0, s2 * 3.2), 0.9, BRONZE_DEEP)

	# brow and eyes
	var happy := state == State.CONTENT or (state == State.SAT and bool(lion.booped))
	var open: float = clampf(float(lion.eye), 0.0, 1.0)
	if state == State.IDLE:
		open = 0.0
	var eye_col: Color = EYE_RED if phase >= 2 else EYE_AMBER
	for s2: float in [-1.0, 1.0]:
		var ep: Vector2 = hx * Vector2(4.6, s2 * 6.2)
		if pose == Pose.DAZED:
			for cr: float in [-1.0, 1.0]:
				b.line(hx * Vector2(1.6, s2 * 6.6 - 2.2 * cr), hx * Vector2(5.6, s2 * 6.6 + 2.2 * cr), BRONZE_DEEP, 1.8)
		elif happy:
			b.line(hx * Vector2(2.8, s2 * 4.6), hx * Vector2(4.8, s2 * 6.8), BRONZE_DEEP, 1.8)
			b.line(hx * Vector2(4.8, s2 * 6.8), hx * Vector2(2.8, s2 * 9.0), BRONZE_DEEP, 1.8)
		elif open <= 0.05:
			b.line(hx * Vector2(3.6, s2 * 4.4), hx * Vector2(3.6, s2 * 8.8), BRONZE_DEEP, 1.8)
		else:
			b.glow(ep, 10.0 * open, Color(eye_col.r, eye_col.g, eye_col.b, 0.55))
			b.circle(ep, 3.0 * DRAW_K, BRONZE_DEEP)
			b.circle(ep, 2.2 * DRAW_K * open, eye_col)
			b.circle(ep + nose_dir * 0.6, 1.0 * open, BRONZE_DEEP)
		if not happy and pose != Pose.DAZED:
			# the brow, drawn down toward the nose: a glower
			b.line(hx * Vector2(-0.5, s2 * 9.6), hx * Vector2(2.6 + 1.0 * open, s2 * 3.4), BRONZE_DEEP, 2.4)

	if float(lion.dazed) > 0.0:
		for k in range(3):
			var sa := t * 6.0 + float(k) * (TAU / 3.0) + sd
			var sp := hc + Vector2(cos(sa) * 30.0, sin(sa) * 13.0 - 16.0)
			b.circle(sp, 4.6, Color(1.0, 0.92, 0.42))
			b.line(sp - Vector2(6.5, 0.0), sp + Vector2(6.5, 0.0), Color(1.0, 0.98, 0.80), 1.6)
			b.line(sp - Vector2(0.0, 6.5), sp + Vector2(0.0, 6.5), Color(1.0, 0.98, 0.80), 1.6)


# where his nose is drawn: the boop's mark
func _nose_of(lion: Dictionary) -> Vector2:
	var f: Vector2 = lion.face_dir
	return (lion.pos as Vector2) + f * (44.0 if state == State.STUNNED else 32.0) * DRAW_K


# What the fight asks for, marked on the ground: the leg to loop in the last
# stand, the noses to bark at, the dust where they landed.
func _draw_marks(b: ShapeBatch, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 8.0)
	if state == State.STAND or state == State.WRAPPED:
		for k in range(leg_poles.size()):
			var held: bool = state == State.WRAPPED or (main != null and main.elapsed - leg_touch_t[k] <= LEG_MEMORY)
			var col := Color(1.0, 0.90, 0.20, 0.9) if held else Color(0.98, 0.85, 0.30, 0.35 + 0.25 * pulse)
			_ring(b, leg_poles[k], LEG_RADIUS + 8.0 + (0.0 if held else pulse * 3.0), col, 3.0)
	if state == State.STUNNED or state == State.SAT:
		for lion: Dictionary in [lion_a, lion_b]:
			if bool(lion.booped):
				continue
			_ring(b, _nose_of(lion), 12.0 + pulse * 5.0, Color(1.0, 0.95, 0.55, 0.85 - 0.4 * pulse), 2.5)
	if state == State.AWAKEN and act_t >= 2.8:
		var k := clampf((act_t - 2.8) / 0.5, 0.0, 1.0)
		for lion: Dictionary in [lion_a, lion_b]:
			_ring(b, lion.pos, 30.0 + k * 50.0, Color(0.86, 0.80, 0.68, (1.0 - k) * 0.6), 4.0)


# The pincer: each lion's lane to where he will land, as wide as he hits,
# filling as the warning runs out, chevrons running down it.
func _draw_pincer_warning(b: ShapeBatch, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 14.0)
	var k := clampf(act_t / PINCER_WARN, 0.0, 1.0)
	for i in range(2):
		var from: Vector2 = (lion_a if i == 0 else lion_b).pos
		_lane(b, from, pincer_targets[i], (BODY_R + 10.0) * 2.0, k, pulse, t)
		_ring(b, pincer_targets[i], BODY_R, Color(1.0, 0.45, 0.28, 0.5 + 0.3 * pulse), 2.5)


# The double rush: the two crossing lanes, and the ring to be out of when
# they meet.
func _draw_rush_warning(b: ShapeBatch, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 14.0)
	var k := clampf(act_t / RUSH_WARN, 0.0, 1.0)
	for i in range(2):
		_lane(b, rush_starts[i], rush_ends[i], (BODY_R + 6.0) * 2.0, k, pulse, t)
	b.circle(rush_cross_pos, RUSH_CLEAR * k, Color(WARN.r, WARN.g, WARN.b, 0.16 + 0.10 * pulse))
	_ring(b, rush_cross_pos, RUSH_CLEAR, Color(1.0, 0.85, 0.40, 0.55 + 0.4 * pulse), 3.0)
	for a: float in [PI * 0.25, PI * 0.75]:
		var d := Vector2.from_angle(a) * 13.0
		b.line(rush_cross_pos - d, rush_cross_pos + d, Color(1.0, 0.90, 0.78, 0.9), 4.0)


func _lane(b: ShapeBatch, from: Vector2, to: Vector2, width: float, k: float, pulse: float, t: float) -> void:
	var ln := from.distance_to(to)
	if ln < 1.0:
		return
	var d := (to - from) / ln
	var side := d.orthogonal() * width * 0.5
	b.line(from, to, Color(WARN.r, WARN.g, WARN.b, 0.14 + 0.08 * pulse), width)
	b.line(from, from.lerp(to, k), Color(WARN.r, WARN.g, WARN.b, 0.16), width)
	b.line(from + side, to + side, Color(1.0, 0.3, 0.2, 0.6), 2.0)
	b.line(from - side, to - side, Color(1.0, 0.3, 0.2, 0.6), 2.0)
	var at := 40.0 + fmod(t * 260.0, 60.0)
	while at < ln - 10.0:
		var cp := from + d * at
		var cc := Color(1.0, 0.85, 0.75, 0.75 * (1.0 - at / ln * 0.6))
		b.line(cp - side * 0.4 - d * 10.0, cp, cc, 3.0)
		b.line(cp + side * 0.4 - d * 10.0, cp, cc, 3.0)
		at += 60.0


# The roar: the cone it will blow down, filling through the warning; in the
# blast, gusts running out along it.
func _draw_roar_cone(b: ShapeBatch, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 14.0)
	var f: Vector2 = roaring_lion.face_dir
	var origin: Vector2 = roaring_lion.pos
	var a0 := f.angle() - ROAR_HALF
	var blast := state == State.ROAR_BLAST
	var k := 1.0 if blast else clampf(act_t / ROAR_WARN, 0.0, 1.0)
	var pts := PackedVector2Array([origin])
	var inner := PackedVector2Array([origin])
	for i in range(13):
		var d := Vector2.from_angle(a0 + ROAR_HALF * 2.0 * float(i) / 12.0)
		pts.append(origin + d * ROAR_REACH)
		inner.append(origin + d * ROAR_REACH * maxf(k, 0.05))
	if blast:
		var fade := 1.0 - clampf(act_t / ROAR_DUR, 0.0, 1.0)
		b.polygon(pts, Color(WIND.r, WIND.g, WIND.b, 0.10 + 0.10 * fade))
		for g in range(4):
			var gr := fposmod(float(g) * 0.25 + t * 1.6, 1.0)
			var rr := 50.0 + gr * (ROAR_REACH - 60.0)
			var gc := Color(WIND.r, WIND.g, WIND.b, (1.0 - gr) * 0.75)
			var prev := Vector2.ZERO
			for i in range(9):
				var d := Vector2.from_angle(a0 + ROAR_HALF * 2.0 * (0.08 + 0.84 * float(i) / 8.0))
				var cur := origin + d * (rr + sin(float(i) * 1.3 + t * 20.0) * 4.0)
				if i > 0:
					b.line(prev, cur, gc, 4.0 - gr * 2.0)
				prev = cur
		for i in range(5):
			var d := Vector2.from_angle(a0 + ROAR_HALF * 2.0 * (0.15 + 0.175 * float(i)))
			var s0 := fposmod(t * 2.2 + float(i) * 0.37, 1.0)
			b.line(origin + d * (40.0 + s0 * 200.0), origin + d * (76.0 + s0 * 200.0), Color(1.0, 1.0, 1.0, 0.5 * (1.0 - s0)), 2.0)
		return
	b.polygon(pts, Color(WARN.r, WARN.g, WARN.b, 0.10 + 0.08 * pulse))
	b.polygon(inner, Color(WARN.r, WARN.g, WARN.b, 0.20))
	for i in range(12):
		b.line(pts[i + 1], pts[i + 2], Color(1.0, 0.45, 0.28, 0.8), 3.0)
	b.line(pts[0], pts[1], Color(1.0, 0.45, 0.28, 0.6), 2.0)
	b.line(pts[0], pts[13], Color(1.0, 0.45, 0.28, 0.6), 2.0)


static func _ring(b: ShapeBatch, c: Vector2, r: float, col: Color, w: float) -> void:
	var n := 28
	var prev := c + Vector2(r, 0.0)
	for i in range(1, n + 1):
		var cur := c + Vector2.from_angle(TAU * float(i) / float(n)) * r
		b.line(prev, cur, col, w)
		prev = cur


static func _ellipse(c: Vector2, f: Vector2, rf: float, rs: float, n: int) -> PackedVector2Array:
	var s := f.orthogonal()
	var out := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		out.append(c + f * cos(a) * rf + s * sin(a) * rs)
	return out
