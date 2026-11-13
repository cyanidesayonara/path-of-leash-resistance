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

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# --- Bronze & Arena Palette --------------------------------------------------
const BRONZE_PATINA := Color(0.24, 0.44, 0.38)     # weathered verdigris teal
const BRONZE_DARK := Color(0.26, 0.22, 0.16)       # dark cast bronze
const BRONZE_LIT := Color(0.68, 0.54, 0.28)        # warm bronze rim
const BRONZE_SHINE := Color(0.86, 0.72, 0.38)      # polished tourist touchpoints
const EYE_AMBER := Color(0.96, 0.74, 0.18)
const EYE_RED := Color(1.0, 0.28, 0.15)
const PLINTH_COL := Color(0.68, 0.65, 0.60)
const PLINTH_DARK := Color(0.50, 0.47, 0.43)
const WARN := Color(1.0, 0.36, 0.20)
const WIND_TINT := Color(0.70, 0.88, 0.98, 0.40)

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

func draw(wc: ShapeBatch, vt: float, vb: float) -> void:
	if COLOM_POS.y < vt - 600.0 or COLOM_POS.y > vb + 600.0:
		return

	# Draw Plinths
	_draw_plinth(wc, PLINTH_L)
	_draw_plinth(wc, PLINTH_R)

	# Warning Telegraphs
	if state == State.PINCER_WARN:
		_draw_pincer_warning(wc)
	elif state == State.ROAR_WARN or state == State.ROAR_BLAST:
		_draw_roar_cone(wc)
	elif state == State.RUSH_WARN:
		_draw_rush_warning(wc)

	# Draw Lions
	var anim: float = AnimClock.msec() / 1000.0
	_draw_lion(wc, lion_a, anim)
	_draw_lion(wc, lion_b, anim)

	# Sparks
	for s: Dictionary in sparks:
		var k: float = s.life / s.max_life
		wc.circle(s.pos, 3.5 * k, s.col)


func _draw_plinth(wc: ShapeBatch, p: Vector2) -> void:
	wc.rect(Rect2(p - PLINTH_HALF + LIGHT * 8.0, PLINTH_HALF * 2.0), SHADOW)
	wc.rect(Rect2(p - PLINTH_HALF, PLINTH_HALF * 2.0), PLINTH_DARK)
	wc.rect(Rect2(p - PLINTH_HALF + Vector2(4.0, 4.0), (PLINTH_HALF - Vector2(4.0, 4.0)) * 2.0), PLINTH_COL)


func _draw_lion(wc: ShapeBatch, lion: Dictionary, anim: float) -> void:
	var p: Vector2 = lion.pos
	var f_dir: Vector2 = lion.face_dir
	var side := f_dir.orthogonal()

	# Drop shadow
	wc.circle(p + LIGHT * 10.0, BODY_R + 6.0, SHADOW)

	# Hindquarters / Body (Dark bronze with verdigris patina)
	wc.circle(p, BODY_R, BRONZE_DARK)
	wc.circle(p - f_dir * 10.0, BODY_R * 0.85, BRONZE_PATINA)

	# Tail curving with bronze brush tuft
	var tail_root: Vector2 = p - f_dir * (BODY_R * 0.8)
	var tail_mid: Vector2 = tail_root - f_dir * 24.0 + side * float(lion.side) * 20.0
	var tail_tip: Vector2 = tail_mid - f_dir * 18.0 - side * float(lion.side) * 12.0
	wc.line(tail_root, tail_mid, BRONZE_DARK, 4.0)
	wc.line(tail_mid, tail_tip, BRONZE_PATINA, 3.5)
	wc.circle(tail_tip, 6.0, BRONZE_SHINE)

	# Front paws (with shiny tourist-rubbed toe highlights)
	var paw_l := p + f_dir * 20.0 - side * 18.0
	var paw_r := p + f_dir * 20.0 + side * 18.0
	wc.circle(paw_l, 10.0, BRONZE_DARK)
	wc.circle(paw_r, 10.0, BRONZE_DARK)
	wc.circle(paw_l + f_dir * 3.0, 6.0, BRONZE_SHINE)
	wc.circle(paw_r + f_dir * 3.0, 6.0, BRONZE_SHINE)

	# Majestic Scalloped Bronze Mane
	var mane_center := p + f_dir * 14.0
	wc.circle(mane_center, MANE_R + 4.0, BRONZE_DARK)
	wc.circle(mane_center, MANE_R, BRONZE_PATINA)
	for i in range(8):
		var a := float(i) * (TAU / 8.0) + anim * 0.2
		var lock_pos := mane_center + Vector2(cos(a), sin(a)) * (MANE_R - 4.0)
		wc.circle(lock_pos, 7.0, BRONZE_LIT)

	# Head & Muzzle
	var head_pos := mane_center + f_dir * 12.0
	wc.circle(head_pos, HEAD_R, BRONZE_PATINA)

	# Snout and nose
	var snout_pos := head_pos + f_dir * 10.0
	wc.circle(snout_pos, 11.0, BRONZE_DARK)
	wc.circle(snout_pos + f_dir * 3.0, 6.0, BRONZE_SHINE)

	# Eyes (Amber in Phase 1, Red in Phase 2)
	var eye_col: Color = EYE_RED if phase >= 2 else EYE_AMBER
	if state == State.CONTENT or (state == State.SAT and lion.booped):
		# Closed happy eye lines
		wc.line(head_pos - side * 7.0, head_pos - side * 12.0, BRONZE_DARK, 2.0)
		wc.line(head_pos + side * 7.0, head_pos + side * 12.0, BRONZE_DARK, 2.0)
	else:
		wc.circle(head_pos - side * 9.0 + f_dir * 3.0, 3.5, eye_col)
		wc.circle(head_pos + side * 9.0 + f_dir * 3.0, 3.5, eye_col)

	# Dazed stars orbiting head if stunned
	if lion.dazed > 0.0:
		for k in range(3):
			var star_a := anim * 6.0 + float(k) * (TAU / 3.0)
			var star_pos := head_pos + Vector2(cos(star_a) * 32.0, sin(star_a) * 14.0 - 18.0)
			wc.circle(star_pos, 4.5, BRONZE_SHINE)
			wc.line(star_pos - Vector2(4.0, 0.0), star_pos + Vector2(4.0, 0.0), Color.WHITE, 1.5)
			wc.line(star_pos - Vector2(0.0, 4.0), star_pos + Vector2(0.0, 4.0), Color.WHITE, 1.5)


func _draw_pincer_warning(wc: ShapeBatch) -> void:
	for k in range(2):
		var from := PLINTH_L if k == 0 else PLINTH_R
		var to: Vector2 = pincer_targets[k]
		wc.line(from, to, Color(WARN.r, WARN.g, WARN.b, 0.40), 28.0)
		wc.line(from, to, WARN, 3.0)


func _draw_roar_cone(wc: ShapeBatch) -> void:
	var r_pos: Vector2 = roaring_lion.pos
	var f_dir: Vector2 = roaring_lion.face_dir
	var left_ray := f_dir.rotated(-ROAR_HALF) * ROAR_REACH
	var right_ray := f_dir.rotated(ROAR_HALF) * ROAR_REACH
	wc.line(r_pos, r_pos + left_ray, WARN, 2.5)
	wc.line(r_pos, r_pos + right_ray, WARN, 2.5)
	# Concentric shock arcs
	var anim: float = AnimClock.msec() / 1000.0
	for d in [80.0, 160.0, 240.0]:
		var arc_r := fposmod(d + anim * 200.0, ROAR_REACH)
		wc.line(r_pos + f_dir.rotated(-ROAR_HALF * 0.8) * arc_r, r_pos + f_dir.rotated(ROAR_HALF * 0.8) * arc_r, WIND_TINT, 3.0)


func _draw_rush_warning(wc: ShapeBatch) -> void:
	# Dual crossing trajectory lanes
	wc.line(rush_starts[0], rush_ends[0], Color(WARN.r, WARN.g, WARN.b, 0.35), 32.0)
	wc.line(rush_starts[1], rush_ends[1], Color(WARN.r, WARN.g, WARN.b, 0.35), 32.0)
	wc.line(rush_starts[0], rush_ends[0], WARN, 3.0)
	wc.line(rush_starts[1], rush_ends[1], WARN, 3.0)

	# Target crossing reticle
	wc.circle(rush_cross_pos, 22.0, Color(WARN.r, WARN.g, WARN.b, 0.45))
	wc.circle(rush_cross_pos, 14.0, WARN)
