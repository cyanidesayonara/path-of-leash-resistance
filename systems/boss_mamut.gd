class_name BossMamut
extends RefCounted

# EL MAMUT, La Ciutadella's statue boss (docs/BOSSES.md): the stone mammoth
# by the boating lake climbs off his plinth as she passes, and your human will
# not walk past a mammoth. Heavy, slow and wide: the danger is how much ground
# he covers, never his speed.
#
# - The wake: the dog past WAKE_Y, his ear twitches, the trunk lifts, he
#   trumpets and steps down off the plinth (AWAKEN_TIME) under a title card.
# - Part one: he plods LEAD ahead of your human and turns toward the dog slowly
#   (TURN_RATE), so her place is beside him or behind. In front, within reach,
#   he swipes his trunk across a sector of the ground (SWIPE_WARN filling it
#   first). Beside or behind him, he rears and stomps, and a shockwave rings
#   out to STOMP_R. A swipe or stomp that misses her wears him down.
# - Part two, below half: he trumpets, his eyes go red, and he adds the tusk
#   charge, a lane drawn ahead. Into the lake past SHORE_X he goes in to his
#   knees: SPLASH, the longest daze, and he comes up spraying a lane of lake
#   water. Into a plane tree he bonks; across a taut leash he trips; your human
#   flung into him bowls him. Dazed, a bark on his trunk is a boop.
# - Part three: out of fight, he plods back to his plinth and swipes at her
#   from it while she winds the leash round three of his legs within
#   LEG_MEMORY. He wobbles, sits down hard, and a bark on the trunk settles
#   him: a happy trumpet, a fountain from his trunk with a rainbow in it, and
#   your human walks on.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Kit := preload("res://hud/ui_kit.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# --- Colors ------------------------------------------------------------------
const STONE := Color(0.53, 0.49, 0.45)
const STONE_DARK := Color(0.37, 0.34, 0.31)
const STONE_LIT := Color(0.68, 0.64, 0.59)
const FUR := Color(0.45, 0.41, 0.37)
const TUSK := Color(0.93, 0.89, 0.79)
const TUSK_DARK := Color(0.76, 0.71, 0.60)
const MOSS := Color(0.40, 0.52, 0.30, 0.55)
const EYE_AMBER := Color(0.98, 0.80, 0.30)
const EYE_RED := Color(1.0, 0.30, 0.14)
const PLINTH_COL := Color(0.72, 0.69, 0.63)
const PLINTH_DARK := Color(0.58, 0.55, 0.50)
const DUST := Color(0.82, 0.76, 0.62, 0.50)
const WATER := Color(0.55, 0.78, 0.95, 0.85)
const WARN := Color(1.0, 0.36, 0.20)

# --- The arena: the lawn by the boating lake ---------------------------------
const PLINTH := Vector2(800.0, -2800.0)
const PLINTH_HALF := Vector2(74.0, 60.0)
# where he lands, stepping down off the front of his plinth
const LANDING := Vector2(730.0, -2700.0)
const ARENA_L := 330.0
const ARENA_TOP := -3180.0
const ARENA_BOT := -2260.0
# the lake's edge: east of this is water
const SHORE_X := 972.0
const LAKE_TOP := -3230.0
const LAKE_BOT := -2230.0
# your human waits here, short of him, until he is settled
const HOLD_Y := -2540.0
const WAKE_Y := -2400.0
# the plane trees on the lawn: rope poles, and what a charge bonks into
const ARENA_TREES: Array[Vector2] = [
	Vector2(410.0, -2420.0), Vector2(420.0, -2760.0), Vector2(410.0, -3080.0),
	Vector2(610.0, -3060.0), Vector2(900.0, -2380.0),
]

const LEG_OFFSETS: Array[Vector2] = [
	Vector2(-40.0, -44.0), Vector2(40.0, -44.0),
	Vector2(-40.0, 44.0), Vector2(40.0, 44.0),
]
const LEG_RADIUS := 20.0
const BODY_R := 80.0

const PRIZE := Vector2(470.0, -3150.0)
const PRIZE_TEXT := "grab the rower's dropped sandwich"

# --- Tuning ------------------------------------------------------------------
const MAX_HP := 100.0
const FILM := "res://intro/film_mamut.gd"
const LEAD := 240.0             # how far ahead of your human he plods
const PLOD_SPEED := 70.0
const CATCH_SPEED := 150.0
const DRIFT_SPEED := 55.0
const TURN_RATE := 1.6          # radians a second: get beside him
const FRONT_CONE := 1.15        # within this of his face she is in front
const SWIPE_TRIGGER := 210.0
const SWIPE_REACH := 200.0
const SWIPE_HALF := 0.95        # half the swept sector, radians
const SWIPE_WARN := 0.85        # every owner-scale event is about 0.8 s
const SWIPE_STRIKE := 0.30      # the trunk crossing the sector
const SWIPE_COOLDOWN := 2.4
const STOMP_R := 135.0
const STOMP_DODGE := 270.0
const STOMP_WARN := 0.95
const STOMP_COOLDOWN := 3.0
const DODGE_DAMAGE := 12.0
const CHARGE_MIN := 170.0
const CHARGE_MAX := 540.0
const CHARGE_WARN := 1.0
const CHARGE_SPEED := 360.0
const CHARGE_TIME := 1.35
const CHARGE_COOLDOWN := 3.6
const SPLASH_DAMAGE := 30.0
const BONK_DAMAGE := 20.0
const TRIP_DAMAGE := 25.0
const BOWL_DAMAGE := 25.0
const BOOP_DAMAGE := 10.0
const STUN_TIME := 2.6
const SPLASH_STUN := 3.6
const SPRAY_WARN := 0.85
const SPRAY_TIME := 0.7
const SPRAY_LEN := 380.0
const SPRAY_W := 48.0
const RETREAT_SPEED := 150.0
const LEG_MEMORY := 1.5
const LEGS_TO_TIE := 3
const CLOTHESLINE_END_PTS := 3
const HIT_BOX_R := 52.0
const BOOP_REACH := 80.0
const AWAKEN_TIME := 2.6
const AWAKEN_EAR := 0.4
const AWAKEN_TRUMPET := 1.1
const AWAKEN_STEP := 1.7
const ENRAGE_TIME := 1.7
const ENRAGE_BLAST := 0.6
const LAST_SWIPE_EVERY := 2.6
const LAST_SWIPE_REACH := 230.0
const WOBBLE_TIME := 1.2
const CARD_TIME := 3.4
const CARD_FROM := 0.3
const LEAN_MAX := 220.0
const LEAN_EASE := 3.0
const CRATERS_MAX := 10
const CRATER_LIFE := 10.0
const SHOUT_GAP := 2.6

enum State {
	IDLE, AWAKEN, ENRAGE, PROWL, SWIPE, STOMP, CHARGE_WARN, CHARGE,
	STUNNED, SPRAY, RETREAT, STAND, WRAPPED, SAT, CONTENT,
}

var state: State = State.IDLE
var state_t := 0.0
var act_t := 0.0
var hp := MAX_HP
var max_hp := MAX_HP
var phase := 1
var main: Node2D = null
var pos := PLINTH
var face_dir := Vector2.DOWN
var hop_z := 0.0

var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []
var leg_soft_indices: Array[int] = []
var leg_furniture_indices: Array[int] = []
var leg_touch_t: Array[float] = [-INF, -INF, -INF, -INF]
var legs_tied := 0

var swipe_dir := Vector2.DOWN
var swipe_side := 1.0
var swipe_cd := 1.0
var swipe_struck := false
var stomp_cd := 1.5
var charge_dir := Vector2.DOWN
var charge_end := Vector2.ZERO
var charge_cd := CHARGE_COOLDOWN
var charge_hit_done := false
var charge_from_tree := false
var stun_splash := false
var stun_booped := false
var stun_bowled := false
var spray_dir := Vector2.DOWN
var spray_hit := false
var ls_swipe_cd := LAST_SWIPE_EVERY
var hold_noticed := false
var enraged := false
var film_shown := false

# the show: none of it touches the fight's rules
var flash := 0.0
var screen_flash := 0.0
var lean := 0.0
var card_t := -1.0
var card: Control = null
var cheer := 0.0
var gasp := 0.0
var shout_cd := 0.0
var ear_t := 0.0
var trunk_lift := 0.0           # 0 hanging, 1 raised high
var trunk_sweep := 0.0          # -1..1 across a swipe
var fountain_t := -1.0
var rings: Array[Dictionary] = []
var bits: Array[Dictionary] = []
var craters: Array[Dictionary] = []
var crowd: Array[Dictionary] = []
var fx := RandomNumberGenerator.new()

const CHEERS: Array[String] = ["Bravo!", "Go on, pup!", "Again!", "What a dog!", "Olé!"]
const GASPS: Array[String] = ["Look out!", "Oh no!", "Watch out, pup!", "Run!"]
const WINS: Array[String] = ["Bravo!", "Good dog!", "Nice mammoth!", "Visca!"]
const SHIRTS: Array[Color] = [
	Color(0.85, 0.30, 0.28), Color(0.25, 0.45, 0.75), Color(0.95, 0.78, 0.30),
	Color(0.30, 0.62, 0.42), Color(0.62, 0.38, 0.70), Color(0.92, 0.92, 0.88),
]
const SKINS: Array[Color] = [
	Color(0.96, 0.80, 0.66), Color(0.82, 0.62, 0.46), Color(0.62, 0.42, 0.30), Color(0.45, 0.30, 0.22),
]
const HAIRS: Array[Color] = [
	Color(0.12, 0.09, 0.07), Color(0.35, 0.22, 0.12), Color(0.70, 0.55, 0.30), Color(0.55, 0.55, 0.55),
]
const RAINBOW: Array[Color] = [
	Color(0.95, 0.30, 0.28), Color(0.98, 0.62, 0.22), Color(0.98, 0.90, 0.30),
	Color(0.40, 0.80, 0.40), Color(0.32, 0.56, 0.92), Color(0.56, 0.40, 0.84),
]


# --- Setup -------------------------------------------------------------------

func setup(m_ref: Node2D) -> void:
	main = m_ref
	state = State.IDLE
	hp = MAX_HP
	phase = 1
	pos = PLINTH
	face_dir = Vector2.DOWN
	hold_noticed = false
	enraged = false
	card_t = -1.0
	lean = 0.0
	rings.clear()
	bits.clear()
	craters.clear()
	leg_poles.clear()
	for off: Vector2 in LEG_OFFSETS:
		leg_poles.append(pos + off)
	fx.seed = 1907
	_build_crowd()


# Onlookers along the hedge west of the lawn, and two rowers on the lake.
# Drawn only.
func _build_crowd() -> void:
	crowd.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1888
	var y := -2300.0
	while y > -3150.0:
		_add_onlooker(rng, Vector2(ARENA_L - 34.0 + rng.randf_range(-6.0, 6.0), y), false)
		y -= rng.randf_range(44.0, 70.0)
	_add_onlooker(rng, Vector2(1090.0, -2560.0), true)
	_add_onlooker(rng, Vector2(1150.0, -2960.0), true)


func _add_onlooker(rng: RandomNumberGenerator, at: Vector2, rowing: bool) -> void:
	crowd.append({
		"p": at, "shirt": SHIRTS[rng.randi() % SHIRTS.size()],
		"skin": SKINS[rng.randi() % SKINS.size()], "hair": HAIRS[rng.randi() % HAIRS.size()],
		"ph": rng.randf() * TAU, "rowing": rowing,
	})


# Called by LevelBuild after the rope radii are filled: the legs are rope
# points with furniture slip, kept out of the static bodies.
func register_legs(m: Node2D) -> void:
	leg_indices.clear()
	leg_soft_indices.clear()
	leg_furniture_indices.clear()
	leg_poles.clear()
	for k in range(LEG_OFFSETS.size()):
		var lp: Vector2 = _leg_at(k)
		leg_indices.append(m.poles.size())
		leg_soft_indices.append(m.rope_soft.size())
		m.poles.append(lp)
		m.rope_radii.append(LEG_RADIUS + 2.0)
		m.rope_soft.append(lp)
		leg_poles.append(lp)


func is_leg_index(i: int) -> bool:
	return not leg_indices.is_empty() and i >= leg_indices[0] and i <= leg_indices[leg_indices.size() - 1]


# his legs turn with him: offsets are in his frame, face pointing down
func _leg_at(k: int) -> Vector2:
	var ang := face_dir.angle() - PI * 0.5
	return pos + LEG_OFFSETS[k].rotated(ang)


func update_leg_positions() -> void:
	if leg_poles.size() != 4:
		return
	var leash_furn: Array = main.leash.furniture_poles if main.leash != null else []
	if leg_furniture_indices.size() != leg_indices.size():
		leg_furniture_indices.clear()
		for k in range(leg_indices.size()):
			leg_furniture_indices.append(leash_furn.find(leg_poles[k]))
	for k in range(4):
		var target := _leg_at(k)
		leg_poles[k] = target
		if k < leg_indices.size():
			var idx: int = leg_indices[k]
			if idx >= 0 and idx < main.poles.size():
				main.poles[idx] = target
			var si: int = leg_soft_indices[k]
			if si >= 0 and si < main.rope_soft.size():
				main.rope_soft[si] = target
			var fi: int = leg_furniture_indices[k]
			if fi >= 0 and fi < leash_furn.size():
				leash_furn[fi] = target


func beaten() -> bool:
	return state == State.CONTENT


# awake and not yet settled: the fight is on
func in_fight() -> bool:
	return state != State.IDLE and not beaten()


func trunk_tip() -> Vector2:
	var side := face_dir.orthogonal()
	var reach := 118.0 - trunk_lift * 30.0
	return pos + face_dir * reach + side * trunk_sweep * 40.0


func damage(amt: float) -> void:
	var was := hp
	hp = maxf(0.0, hp - amt)
	if hp < was:
		flash = 1.0
		_cheer_up()
	if hp <= MAX_HP * 0.5 and phase == 1:
		phase = 2
		main.feed.say("EL MAMUT IS FURIOUS!", EventFeed.Tone.LOUD)
		main.human.notice("Is the statue... charging?", 2.2)
	if hp <= 0.0 and was > 0.0:
		main.feed.say("HE'S HAD ENOUGH! AFTER HIM", EventFeed.Tone.GOOD)


# --- Transitions -------------------------------------------------------------

func transition_to(s: State) -> void:
	if s == State.PROWL and hp <= 0.0:
		s = State.RETREAT
	elif s == State.PROWL and phase == 2 and not enraged:
		s = State.ENRAGE
	state = s
	state_t = 0.0
	act_t = 0.0
	match s:
		State.AWAKEN:
			gasp = 1.0
			Sfx.play("drum", 0.6, -4.0)
			Sfx.play("ooooh", 0.9, -10.0)
			card_t = 0.0
			_ensure_card()
		State.ENRAGE:
			enraged = true
			Sfx.play("mamut_trumpet", 0.85, -2.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
			gasp = 1.0
			_crowd_shout(GASPS)
		State.SWIPE:
			state_t = SWIPE_WARN
			swipe_dir = face_dir
			swipe_side = -swipe_side
			swipe_struck = false
		State.STOMP:
			state_t = STOMP_WARN
			rings.append({"pos": pos, "r": STOMP_R, "life": STOMP_WARN, "max": STOMP_WARN, "warn": true})
		State.CHARGE_WARN:
			state_t = CHARGE_WARN
			charge_dir = _to_dog()
			face_dir = charge_dir
			charge_end = pos + charge_dir * CHARGE_SPEED * CHARGE_TIME
			Sfx.play("mamut_trumpet", 1.15, -5.0)
			main.shake_t = maxf(float(main.shake_t), 0.3)
			gasp = 1.0
			_crowd_shout(GASPS)
		State.CHARGE:
			state_t = CHARGE_TIME
			charge_hit_done = false
			charge_from_tree = _near_tree()
			Sfx.play("fling", 0.6, -4.0)
		State.STUNNED:
			state_t = SPLASH_STUN if stun_splash else STUN_TIME
			stun_booped = false
			stun_bowled = false
			Sfx.play("groan", 0.8, -5.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			_burst(trunk_tip(), 12, Color(1.0, 0.9, 0.45), 160.0, 340.0, 2.5, 0.35, true)
		State.SPRAY:
			state_t = SPRAY_WARN + SPRAY_TIME
			spray_dir = _to_dog()
			face_dir = spray_dir
			spray_hit = false
			trunk_lift = 0.6
		State.RETREAT:
			_crowd_shout(CHEERS)
		State.STAND:
			pos = PLINTH
			face_dir = Vector2.DOWN
			update_leg_positions()
			legs_tied = 0
			leg_touch_t = [-INF, -INF, -INF, -INF]
			ls_swipe_cd = LAST_SWIPE_EVERY
			Sfx.play("mamut_trumpet", 0.95, -3.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			main.feed.say("TIE UP HIS LEGS!", EventFeed.Tone.LOUD)
			for r: float in [80.0, 150.0]:
				rings.append({"pos": pos, "r": r, "life": 0.7, "max": 0.7})
			_burst(pos, 16, STONE_DARK, 90.0, 260.0, 3.5, 0.6, false, 260.0)
		State.WRAPPED:
			state_t = WOBBLE_TIME
			Sfx.play("intro_taut", 0.8, -5.0)
			Sfx.play("groan", 0.9, -5.0)
			Sfx.play("ooooh", 1.0, -8.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
			gasp = 1.0
		State.SAT:
			Sfx.play("crack", 0.5, -3.0)
			Sfx.play("drum", 0.4, -1.0)
			Sfx.play("whoop", 1.0, -6.0)
			main.mamut_sat = true
			main.shake_t = 1.4
			main.feed.say("EL MAMUT SITS DOWN!", EventFeed.Tone.LOUD)
			trunk_lift = 0.0
			for r: float in [50.0, 110.0, 180.0, 260.0]:
				rings.append({"pos": pos, "r": r, "life": 0.8, "max": 0.8})
			_burst(pos, 26, STONE_DARK, 120.0, 340.0, 4.0, 0.8, false, 300.0)
			_scatter_pigeons(pos, 900.0)
			screen_flash = 0.7
			_big_hit()
			_cheer_up()
		State.CONTENT:
			Sfx.play("mamut_trumpet", 1.3, -3.0)
			Sfx.play("star", 1.1)
			Sfx.play("whoop", 1.1, -4.0)
			main.mamut_settled = true
			main.combo.add("BOOP", 10)
			main.float_text(trunk_tip(), "booped! +10", Color(1.0, 0.88, 0.25))
			main.feed.say("LA CIUTADELLA IS YOURS!", EventFeed.Tone.GOOD)
			main.human.say_line("Good... mammoth?")
			cheer = 1.0
			shout_cd = 0.0
			_crowd_shout(WINS)
			fountain_t = 0.0
			trunk_lift = 1.0


# --- Attacks -----------------------------------------------------------------

func _to_dog() -> Vector2:
	var d: Vector2 = main.dog.global_position - pos
	return d.normalized() if d.length() > 1.0 else Vector2.DOWN


func in_sector(p: Vector2, dir: Vector2, reach: float, half: float) -> bool:
	var d := p - pos
	if d.length() > reach or d.length() < 1.0:
		return d.length() < 1.0
	return absf(dir.angle_to(d)) <= half


func _strike_swipe(reach: float) -> void:
	swipe_struck = true
	Sfx.play("fling", 0.8, -3.0)
	Sfx.play("crack", 1.2, -8.0)
	var dog_p: Vector2 = main.dog.global_position
	var push := swipe_dir.orthogonal() * swipe_side
	if in_sector(dog_p, swipe_dir, reach + 12.0, SWIPE_HALF):
		main.dog.knocked((push + swipe_dir * 0.4).normalized(), "trunk")
	elif dog_p.distance_to(pos) < reach + 130.0 and hp > 0.0:
		_dodged(dog_p)
	if in_sector(main.human.global_position, swipe_dir, reach + 12.0, SWIPE_HALF):
		main.human.bumped(push)
	# the gravel swept aside in an arc
	for i in range(8):
		var a := swipe_dir.angle() + lerpf(-SWIPE_HALF, SWIPE_HALF, float(i) / 7.0)
		_burst(pos + Vector2.from_angle(a) * reach * 0.8, 2, DUST, 40.0, 140.0, 4.0, 0.5, false, 120.0)
	_scatter_pigeons(pos, reach + 60.0)


func _strike_stomp() -> void:
	Sfx.play("drum", 0.35, 0.0)
	Sfx.play("crack", 0.6, -4.0)
	main.shake_t = maxf(float(main.shake_t), 0.7)
	var dog_p: Vector2 = main.dog.global_position
	var d := dog_p.distance_to(pos)
	if d <= STOMP_R:
		main.dog.knocked((dog_p - pos).normalized() if d > 1.0 else Vector2.DOWN, "stomp")
	elif d < STOMP_DODGE and hp > 0.0:
		_dodged(dog_p)
	var hd: float = main.human.global_position.distance_to(pos)
	if hd <= STOMP_R:
		main.human.bumped((main.human.global_position - pos).normalized())
	for r: float in [STOMP_R, STOMP_R * 1.5, STOMP_DODGE]:
		rings.append({"pos": pos, "r": r, "life": 0.55, "max": 0.55})
	craters.append({"p": pos + face_dir * 30.0, "a": fx.randf() * TAU, "life": CRATER_LIFE})
	if craters.size() > CRATERS_MAX:
		craters.remove_at(0)
	_burst(pos, 14, STONE_DARK, 80.0, 240.0, 3.0, 0.6, false, 260.0)
	_scatter_pigeons(pos, 320.0)


func _dodged(at: Vector2) -> void:
	main.mamut_dodges += 1
	main.combo.add("DODGE", 2)
	main.float_text(at, "dodged! +2", Color(0.8, 1.0, 0.7))
	damage(DODGE_DAMAGE)


func _near_tree() -> bool:
	for tr: Vector2 in ARENA_TREES:
		if pos.distance_squared_to(tr) < 58.0 * 58.0:
			return true
	return false


func check_trip() -> bool:
	var l = main.leash
	if l == null or l.detached:
		return false
	var rest: float = maxf(float(l.rest_len), 1.0)
	if l.taut_amount(l.used_length() / rest) < 0.15:
		return false
	var hit_sq := HIT_BOX_R * HIT_BOX_R
	var n: int = l.pts.size()
	for i in range(CLOTHESLINE_END_PTS, n - 1 - CLOTHESLINE_END_PTS):
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(pos, l.pts[i], l.pts[i + 1])
		if pos.distance_squared_to(cp) <= hit_sq:
			return true
	return false


func check_bowled() -> bool:
	if main.human.global_position.distance_to(pos) > BODY_R:
		return false
	return main.human.whirl_flung_t > 0.0 or main.human.velocity.length() > 200.0


func _bowl() -> void:
	main.mamut_bowled = true
	damage(BOWL_DAMAGE)
	Sfx.play("drum", 0.5, -2.0)
	main.shake_t = 1.2
	main.human.bumped((main.human.global_position - pos).normalized())
	main.feed.say("HUMAN BOWLING!", EventFeed.Tone.LOUD)
	main.combo.add("BOWLED", 12)
	main.float_text(pos, "bowled! +12", Color(1.0, 0.6, 0.4))
	main.human.notice("Ow! Solid stone!", 2.2)
	screen_flash = 0.35
	_big_hit()


func _hit(kind: String) -> void:
	# a charge cut short: tripped, into a tree, or into the lake
	match kind:
		"trip":
			main.mamut_tripped = true
			damage(TRIP_DAMAGE)
			Sfx.play("intro_taut", 0.9, -4.0)
			Sfx.play("drum", 0.45, -1.0)
			main.feed.say("TRIPPED!", EventFeed.Tone.LOUD)
			main.combo.add("TRIP", 8)
			main.float_text(pos, "tripped! +8", Color(1.0, 0.85, 0.2))
		"tree":
			main.mamut_bonked = true
			damage(BONK_DAMAGE)
			Sfx.play("crack", 0.55, -3.0)
			Sfx.play("drum", 0.6, -3.0)
			main.feed.say("BONK! RIGHT INTO THE TREE", EventFeed.Tone.LOUD)
			main.combo.add("BONK", 6)
			main.float_text(pos, "bonk! +6", Color(0.9, 0.5, 0.3))
			_burst(pos + charge_dir * 50.0, 14, Color(0.40, 0.62, 0.30), 60.0, 200.0, 4.0, 1.1, false, 200.0)
		"lake":
			main.mamut_splashed = true
			damage(SPLASH_DAMAGE)
			Sfx.play("splash", 0.55, 0.0)
			Sfx.play("splash", 0.8, -4.0)
			main.feed.say("SPLASH! INTO THE LAKE", EventFeed.Tone.LOUD)
			main.combo.add("SPLASH", 10)
			main.float_text(pos, "splash! +10", Color(0.6, 0.85, 1.0))
			for i in range(3):
				rings.append({"pos": pos, "r": 70.0 + float(i) * 60.0, "life": 0.9, "max": 0.9, "col": WATER})
			_burst(pos, 30, WATER, 120.0, 360.0, 4.5, 0.9, false, 360.0)
			face_dir = Vector2.LEFT
	main.shake_t = maxf(float(main.shake_t), 1.1)
	screen_flash = 0.3
	_big_hit()
	stun_splash = kind == "lake"
	transition_to(State.STUNNED)


# --- The tangle and the hold -------------------------------------------------

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


func _hold_human() -> void:
	# Nobody walks past a mammoth. The autowalk bot cannot fight, so passes.
	var h = main.human
	var want: bool = state != State.IDLE and not beaten() and not main.auto_walk \
		and not h.homeward and h.global_position.y < HOLD_Y + 300.0
	if want:
		h.tut_hold_y = HOLD_Y
		if main.leash_target < main.LEASH_LENGTH:
			main.set_leash_target(main.LEASH_LENGTH)
		if not hold_noticed and h.global_position.y < HOLD_Y + 20.0:
			hold_noticed = true
			h.notice("Not past a mammoth.", 1.8)
	elif h.tut_hold_y == HOLD_Y:
		h.tut_hold_y = -INF


# --- The tick ----------------------------------------------------------------

func tick_state(delta: float) -> void:
	if main.frozen:
		return
	_tick_show(delta)
	_hold_human()
	var dog_p: Vector2 = main.dog.global_position
	act_t += delta

	match state:
		State.IDLE:
			# your human still short of him: a pair already past (a shot taken
			# further up the walk) leaves him asleep
			if dog_p.y < WAKE_Y and main.human.global_position.y > HOLD_Y - 120.0 \
					and not bool(main.get("film_playing")):
				if not film_shown and FilmPlayer.should_play(main) and ResourceLoader.exists(FILM):
					film_shown = true
					FilmPlayer.play(main, load(FILM))
				else:
					transition_to(State.AWAKEN)

		State.AWAKEN:
			var was := act_t - delta
			if was < AWAKEN_EAR and act_t >= AWAKEN_EAR:
				ear_t = 0.6
				Sfx.play("crack", 1.3, -10.0)
			if was < AWAKEN_TRUMPET and act_t >= AWAKEN_TRUMPET:
				Sfx.play("mamut_trumpet", 1.0, 0.0)
				main.shake_t = maxf(float(main.shake_t), 0.9)
				for r: float in [100.0, 200.0, 320.0]:
					rings.append({"pos": pos, "r": r, "life": 0.9, "max": 0.9})
				_scatter_pigeons(pos, 400.0)
				main.human.notice("Was the mammoth always... facing us?", 2.2)
			trunk_lift = clampf((act_t - 0.7) / 0.4, 0.0, 1.0) if act_t < AWAKEN_STEP else \
				1.0 - clampf((act_t - AWAKEN_STEP) / 0.6, 0.0, 1.0)
			if act_t >= AWAKEN_STEP:
				var k := clampf((act_t - AWAKEN_STEP) / (AWAKEN_TIME - AWAKEN_STEP - 0.2), 0.0, 1.0)
				pos = PLINTH.lerp(LANDING, k)
				hop_z = sin(k * PI) * 30.0 + (1.0 - k) * 14.0
				face_dir = Vector2.DOWN.slerp((LANDING - PLINTH).normalized(), 0.4)
				if k >= 1.0 and was < AWAKEN_TIME - 0.2:
					Sfx.play("drum", 0.4, -1.0)
					main.shake_t = maxf(float(main.shake_t), 0.7)
					rings.append({"pos": pos, "r": 110.0, "life": 0.6, "max": 0.6})
					_burst(pos, 14, DUST, 60.0, 180.0, 4.0, 0.6, false, 120.0)
				update_leg_positions()
			else:
				hop_z = minf(act_t / AWAKEN_TRUMPET, 1.0) * 14.0
			if act_t >= AWAKEN_TIME:
				hop_z = 0.0
				transition_to(State.PROWL)

		State.ENRAGE:
			_turn_to(dog_p, delta * 2.0)
			hop_z = sin(clampf(act_t / ENRAGE_TIME, 0.0, 1.0) * PI) * 22.0
			trunk_lift = sin(clampf(act_t / ENRAGE_TIME, 0.0, 1.0) * PI)
			if act_t - delta < ENRAGE_BLAST and act_t >= ENRAGE_BLAST:
				main.shake_t = maxf(float(main.shake_t), 1.0)
				for r: float in [90.0, 180.0, 290.0]:
					rings.append({"pos": pos, "r": r, "life": 0.8, "max": 0.8})
				_burst(pos, 22, Color(1.0, 0.55, 0.3), 240.0, 400.0, 3.0, 0.4, true)
				_scatter_pigeons(pos, 500.0)
				screen_flash = 0.25
			if act_t >= ENRAGE_TIME:
				hop_z = 0.0
				charge_cd = 0.8
				transition_to(State.PROWL)

		State.PROWL:
			# a hit that crossed half or emptied him lands between attacks too
			if hp <= 0.0 or (phase == 2 and not enraged):
				transition_to(State.PROWL)
				return
			swipe_cd -= delta
			stomp_cd -= delta
			charge_cd -= delta
			trunk_lift = move_toward(trunk_lift, 0.15, delta)
			_turn_to(dog_p, delta)
			var hy: float = main.human.global_position.y
			var want_y := clampf(minf(pos.y, hy - LEAD), ARENA_TOP + 110.0, HOLD_Y - 150.0)
			var against := dog_p.distance_to(pos) < BODY_R + 26.0
			var spd := CATCH_SPEED if pos.y - want_y > 120.0 else PLOD_SPEED
			if not against:
				pos.y = move_toward(pos.y, want_y, spd * delta)
				pos.x = move_toward(pos.x, clampf(dog_p.x, ARENA_L + 100.0, SHORE_X - 100.0), DRIFT_SPEED * delta)
			update_leg_positions()
			# no attack while his title card is up: the banner under it is hushed,
			# and the first swipe came with no word of what to do
			if hush_banner():
				return
			var d := dog_p.distance_to(pos)
			var front := absf(face_dir.angle_to(dog_p - pos)) < FRONT_CONE
			if d < SWIPE_TRIGGER and front and swipe_cd <= 0.0:
				swipe_cd = SWIPE_COOLDOWN
				transition_to(State.SWIPE)
			elif d < STOMP_DODGE - 40.0 and not front and stomp_cd <= 0.0:
				stomp_cd = STOMP_COOLDOWN
				transition_to(State.STOMP)
			elif phase == 2 and charge_cd <= 0.0 and d > CHARGE_MIN and d < CHARGE_MAX:
				charge_cd = CHARGE_COOLDOWN
				transition_to(State.CHARGE_WARN)

		State.SWIPE:
			state_t -= delta
			if state_t > 0.0:
				# the trunk drawn back to the far side, ready
				trunk_sweep = -swipe_side * clampf(1.0 - state_t / SWIPE_WARN, 0.0, 1.0)
				trunk_lift = 0.35
			else:
				if not swipe_struck:
					_strike_swipe(SWIPE_REACH)
				var k := clampf(-state_t / SWIPE_STRIKE, 0.0, 1.0)
				trunk_sweep = lerpf(-swipe_side, swipe_side, k)
				if k >= 1.0:
					trunk_sweep = 0.0
					transition_to(State.PROWL)

		State.STOMP:
			state_t -= delta
			hop_z = (1.0 - clampf(state_t / STOMP_WARN, 0.0, 1.0)) * 26.0
			if state_t <= 0.0:
				hop_z = 0.0
				_strike_stomp()
				transition_to(State.PROWL)

		State.CHARGE_WARN:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.CHARGE)

		State.CHARGE:
			state_t -= delta
			pos += charge_dir * CHARGE_SPEED * delta
			pos.y = clampf(pos.y, ARENA_TOP + 40.0, HOLD_Y + 60.0)
			var into_side := pos.x < ARENA_L + 60.0
			pos.x = clampf(pos.x, ARENA_L + 60.0, SHORE_X + 46.0)
			update_leg_positions()
			_scatter_pigeons(pos, 140.0)
			if pos.x >= SHORE_X + 6.0:
				_hit("lake")
				return
			if check_trip():
				_hit("trip")
				return
			if charge_from_tree and not _near_tree():
				charge_from_tree = false
			if not charge_from_tree and _near_tree():
				_hit("tree")
				return
			if check_bowled():
				_bowl()
				stun_splash = false
				transition_to(State.STUNNED)
				stun_bowled = true
				return
			if not charge_hit_done and dog_p.distance_to(pos) < BODY_R + 8.0:
				charge_hit_done = true
				main.dog.knocked(charge_dir, "tusks")
			if main.human.global_position.distance_to(pos) < BODY_R + 8.0:
				main.human.bumped(charge_dir)
			if fmod(act_t, 0.08) < delta:
				_burst(pos - charge_dir * 60.0, 2, DUST, 30.0, 90.0, 6.0, 0.5)
			if state_t <= 0.0 or into_side:
				transition_to(State.PROWL)

		State.STUNNED:
			state_t -= delta
			if not stun_bowled and check_bowled():
				stun_bowled = true
				_bowl()
			if state_t <= 0.0:
				if stun_splash and hp > 0.0:
					stun_splash = false
					transition_to(State.SPRAY)
				else:
					stun_splash = false
					transition_to(State.PROWL)

		State.SPRAY:
			state_t -= delta
			if state_t <= SPRAY_TIME:
				_tick_spray(delta)
			if state_t <= 0.0:
				# back out of the shallows
				pos.x = minf(pos.x, SHORE_X - 90.0)
				update_leg_positions()
				transition_to(State.PROWL)

		State.RETREAT:
			pos = pos.move_toward(PLINTH, RETREAT_SPEED * delta)
			_turn_to(PLINTH + (PLINTH - pos), delta)
			update_leg_positions()
			if pos.distance_to(PLINTH) < 1.0:
				transition_to(State.STAND)

		State.STAND:
			_tick_last_stand(delta, dog_p)
			update_leg_tangle()

		State.WRAPPED:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.SAT)

		State.CONTENT:
			trunk_lift = move_toward(trunk_lift, 0.8, delta)

	if not main.auto_walk and state in [State.PROWL, State.SWIPE, State.STOMP, State.CHARGE_WARN,
			State.CHARGE, State.STUNNED, State.SPRAY, State.RETREAT, State.ENRAGE]:
		_shove_out(main.dog)
		if not main.human.is_whirling():
			_shove_out(main.human)


func _turn_to(p: Vector2, delta: float) -> void:
	var want := p - pos
	if want.length() < 1.0:
		return
	var a := face_dir.angle()
	var b := want.angle()
	var d := wrapf(b - a, -PI, PI)
	face_dir = Vector2.from_angle(a + clampf(d, -TURN_RATE * delta, TURN_RATE * delta))


func _tick_spray(_delta: float) -> void:
	trunk_lift = 0.55
	var from := trunk_tip()
	if fmod(act_t, 0.04) < 0.017:
		for i in range(3):
			var v := spray_dir.rotated(fx.randf_range(-0.12, 0.12)) * fx.randf_range(420.0, 560.0)
			bits.append({"p": from, "v": v, "z": 6.0, "vz": 60.0, "life": 0.7, "max": 0.7,
				"col": WATER, "r": 4.0, "spark": false})
	if spray_hit:
		return
	var end := from + spray_dir * SPRAY_LEN
	var dog_p: Vector2 = main.dog.global_position
	if dog_p.distance_to(Geometry2D.get_closest_point_to_segment(dog_p, from, end)) < SPRAY_W * 0.5 + 10.0:
		spray_hit = true
		main.dog.knocked(spray_dir, "spray")
	var hp_: Vector2 = main.human.global_position
	if hp_.distance_to(Geometry2D.get_closest_point_to_segment(hp_, from, end)) < SPRAY_W * 0.5 + 12.0:
		spray_hit = true
		main.human.bumped(spray_dir)
		main.human.notice("Hey! Not the phone!", 1.8)


func _tick_last_stand(delta: float, dog_p: Vector2) -> void:
	_turn_to(dog_p, delta)
	if act_t < 0.2:
		return
	ls_swipe_cd -= delta
	# a swipe at her from the plinth, the same telegraph as the fight's
	if ls_swipe_cd <= SWIPE_WARN and ls_swipe_cd + delta > SWIPE_WARN:
		if dog_p.distance_to(pos) < LAST_SWIPE_REACH + 80.0:
			swipe_dir = face_dir
			swipe_side = -swipe_side
		else:
			ls_swipe_cd = LAST_SWIPE_EVERY
	if ls_swipe_cd <= SWIPE_WARN and ls_swipe_cd > 0.0:
		trunk_sweep = -swipe_side * (1.0 - ls_swipe_cd / SWIPE_WARN)
	elif ls_swipe_cd <= 0.0:
		_strike_swipe(LAST_SWIPE_REACH)
		trunk_sweep = swipe_side
		ls_swipe_cd = LAST_SWIPE_EVERY
	else:
		trunk_sweep = move_toward(trunk_sweep, 0.0, delta * 4.0)


# true while the last stand's swipe is telegraphed
func last_swipe_warning() -> bool:
	return state == State.STAND and ls_swipe_cd <= SWIPE_WARN and ls_swipe_cd > 0.0


func _shove_out(body: Node2D) -> void:
	var d: Vector2 = body.global_position - pos
	var l := d.length()
	if l >= BODY_R:
		return
	var n: Vector2 = d / l if l > 0.5 else Vector2.DOWN
	var to: Vector2 = pos + n * BODY_R
	for r: Rect2 in main.solid_rects:
		if r.grow(14.0).has_point(to):
			return
	for tr: Vector2 in ARENA_TREES:
		if to.distance_squared_to(tr) < 30.0 * 30.0:
			return
	var e: Vector2 = main.walk_edges(to.y)
	if to.x < e.x + 8.0 or to.x > e.y - 8.0:
		return
	body.global_position = to


func _scatter_pigeons(at: Vector2, r: float) -> void:
	for p in main.get_tree().get_nodes_in_group("pigeons"):
		if p.global_position.distance_to(at) < r:
			p.scare()


func _burst(at: Vector2, n: int, col: Color, spd_lo: float, spd_hi: float,
		r: float, life: float, spark := false, lob := 0.0) -> void:
	for i in range(n):
		var ang := fx.randf() * TAU
		var spd := fx.randf_range(spd_lo, spd_hi)
		bits.append({
			"p": at, "v": Vector2(cos(ang), sin(ang)) * spd * (0.55 if lob > 0.0 else 1.0),
			"z": 0.0, "vz": fx.randf_range(0.5, 1.0) * lob,
			"life": life * fx.randf_range(0.7, 1.0), "max": life,
			"col": col, "r": r, "spark": spark,
		})


func _big_hit() -> void:
	if main.auto_walk:
		return
	main._slowmo()


func _cheer_up() -> void:
	cheer = 1.0
	gasp = 0.0
	Sfx.play("whoop", fx.randf_range(0.9, 1.15), -12.0)
	_crowd_shout(CHEERS)


func _crowd_shout(lines: Array[String]) -> void:
	if shout_cd > 0.0 or crowd.is_empty():
		return
	var dog_p: Vector2 = main.dog.global_position
	var best := -1
	var best_d := 620.0
	for i in range(crowd.size()):
		var d: float = (crowd[i].p as Vector2).distance_to(dog_p)
		if d < best_d and d > 90.0:
			best_d = d
			best = i
	if best < 0:
		return
	shout_cd = SHOUT_GAP
	main.float_text(crowd[best].p + Vector2(0.0, -14.0), lines[fx.randi() % lines.size()],
			Color(1.0, 1.0, 1.0), main.POP_SAY)


func _tick_show(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 5.0)
	screen_flash = maxf(0.0, screen_flash - delta * 2.5)
	cheer = maxf(0.0, cheer - delta * (0.25 if state == State.CONTENT else 0.6))
	gasp = maxf(0.0, gasp - delta * 0.8)
	shout_cd = maxf(0.0, shout_cd - delta)
	ear_t = maxf(0.0, ear_t - delta)
	for i in range(rings.size() - 1, -1, -1):
		rings[i].life -= delta
		if rings[i].life <= 0.0:
			rings.remove_at(i)
	for i in range(bits.size() - 1, -1, -1):
		var b: Dictionary = bits[i]
		b.life -= delta
		if b.life <= 0.0:
			bits.remove_at(i)
			continue
		b.p += b.v * delta
		b.v *= exp(-float(b.get("drag", 1.5)) * delta)
		if b.vz != 0.0 or b.z > 0.0:
			b.vz -= 900.0 * delta
			b.z = maxf(0.0, b.z + b.vz * delta)
			if b.z <= 0.0:
				b.vz = 0.0
	for i in range(craters.size() - 1, -1, -1):
		craters[i].life -= delta
		if craters[i].life <= 0.0:
			craters.remove_at(i)
	# the happy fountain: water thrown up from his raised trunk, falling back
	if fountain_t >= 0.0:
		fountain_t += delta
		if fountain_t < 4.5 and fmod(fountain_t, 0.05) < delta:
			var tip := trunk_tip() - Vector2(0.0, 30.0)
			for i in range(2):
				bits.append({"p": tip, "v": Vector2(fx.randf_range(-90.0, 90.0), fx.randf_range(-60.0, 20.0)),
					"z": 40.0, "vz": fx.randf_range(380.0, 520.0), "life": 1.3, "max": 1.3,
					"col": WATER, "r": 4.0, "spark": false, "drag": 0.6})
		if fountain_t > 7.0:
			fountain_t = -1.0
	if card_t >= 0.0:
		card_t += delta
		if card_t > CARD_TIME + CARD_FROM:
			card_t = -1.0
	if card != null and is_instance_valid(card):
		card.queue_redraw()
	var want := 0.0
	var mid: float = (main.dog.global_position.y + main.human.global_position.y) * 0.5
	match state:
		State.AWAKEN:
			want = (pos.y - mid) * 0.55
		State.ENRAGE, State.WRAPPED:
			want = (pos.y - mid) * 0.35
		State.PROWL, State.SWIPE, State.STOMP, State.CHARGE_WARN, State.CHARGE, State.STUNNED, \
				State.SPRAY, State.RETREAT, State.STAND:
			# he is big and he is the fight: keep him in the frame, not under the HUD
			want = (pos.y - mid) * 0.3
		State.SAT, State.CONTENT:
			if act_t < 2.5:
				want = (pos.y - mid) * 0.35
	want = clampf(want, -LEAN_MAX, LEAN_MAX)
	lean = lerpf(lean, want, 1.0 - exp(-LEAN_EASE * delta))


func on_bark_action(bark_pos: Vector2) -> bool:
	var dog_p: Vector2 = main.dog.global_position
	var tip := trunk_tip()
	var near := bark_pos.distance_to(tip) < BOOP_REACH or dog_p.distance_to(tip) < BOOP_REACH \
		or dog_p.distance_to(pos + face_dir * 60.0) < BOOP_REACH
	if state == State.SAT and near:
		Sfx.play("bark", 1.25)
		transition_to(State.CONTENT)
		return true
	if state == State.STUNNED and not stun_booped and near:
		stun_booped = true
		damage(BOOP_DAMAGE)
		main.mamut_booped = true
		main.combo.add("BOOP", 3)
		main.float_text(tip, "boop! +3", Color(1.0, 0.88, 0.25))
		return true
	return false


# --- The banner --------------------------------------------------------------

func status() -> String:
	var fight := fight_status()
	if fight != "":
		return fight
	if state != State.IDLE and not beaten() and main.human.tut_hold_y == HOLD_Y \
			and main.human.global_position.y < HOLD_Y + 40.0:
		return "YOUR HUMAN WON'T PASS HIM. DEAL WITH EL MAMUT"
	return ""


func fight_status() -> String:
	var near: bool = main.dog.global_position.distance_to(pos) < 600.0
	match state:
		State.SWIPE:
			return "WATCH THE TRUNK!" if near else ""
		State.STOMP:
			return "STOMP! GET CLEAR" if near else ""
		State.CHARGE_WARN, State.CHARGE:
			return "CHARGE! LEAD HIM INTO THE LAKE" if near else ""
		State.STUNNED:
			return Prompts.fill("HE'S DAZED! {bark} ON HIS TRUNK") if near else ""
		State.SPRAY:
			return "HE'S SPRAYING! OUT OF THE WAY" if near else ""
		State.ENRAGE:
			return "EL MAMUT IS FURIOUS! GET CLEAR" if near else ""
		State.RETREAT:
			return "AFTER HIM! TO HIS PLINTH"
		State.STAND:
			if last_swipe_warning():
				return "WATCH THE TRUNK!"
			return "WRAP THE LEASH AROUND HIS LEGS  %d/%d" % [legs_tied, LEGS_TO_TIE]
		State.SAT:
			return Prompts.fill("HE'S DOWN! {bark} ON HIS TRUNK")
	return ""


func hush_banner() -> bool:
	return card_t >= CARD_FROM and card_t <= CARD_TIME + CARD_FROM


# --- The title card ----------------------------------------------------------

func _ensure_card() -> void:
	if card != null or main.hud == null:
		return
	card = Control.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.hud.add_child(card)
	if main.dim != null:
		main.hud.move_child(card, main.dim.get_index())
	card.draw.connect(_draw_card)


func _draw_card() -> void:
	var vs: Vector2 = card.size
	if screen_flash > 0.0:
		card.draw_rect(Rect2(Vector2.ZERO, vs), Color(1.0, 0.97, 0.88, screen_flash * 0.55))
	if card_t < CARD_FROM:
		return
	var k := card_t - CARD_FROM
	var slide := 0.0
	if k < 0.35:
		slide = -(1.0 - ease(k / 0.35, 0.4)) * vs.x
	elif k > CARD_TIME - 0.35:
		slide = ease((k - CARD_TIME + 0.35) / 0.35, 2.5) * vs.x
	var u := clampf(vs.y / 720.0, 0.5, 1.0)
	var cy := 64.0 * u
	var band := Rect2(Vector2(slide, cy - 58.0 * u), Vector2(vs.x, 116.0 * u))
	card.draw_rect(band, Color(0.06, 0.06, 0.06, 0.82))
	card.draw_rect(Rect2(band.position, Vector2(vs.x, 5.0 * u)), STONE_LIT)
	card.draw_rect(Rect2(band.position + Vector2(0.0, band.size.y - 5.0 * u), Vector2(vs.x, 5.0 * u)), STONE_LIT)
	Kit.heading(card, Vector2(slide, cy - 34.0 * u), "LA CIUTADELLA", int(18.0 * u), Color(0.80, 0.78, 0.72),
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	Kit.heading(card, Vector2(slide, cy + 18.0 * u), "EL MAMUT", int(52.0 * u), TUSK,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	var gloss := "The stone mammoth, and he is awake"
	var gs := int(20.0 * u)
	var gw: float = Kit.text_w(Kit.body(), gloss, gs)
	card.draw_string(Kit.body(), Vector2(slide + (vs.x - gw) * 0.5, cy + 46.0 * u), gloss,
		HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Color(0.92, 0.88, 0.80))


# --- Drawing -----------------------------------------------------------------

# The plinth, drawn under everything of his: on it he is the statue.
func draw_plinth(b: ShapeBatch) -> void:
	var r := Rect2(PLINTH - PLINTH_HALF, PLINTH_HALF * 2.0)
	b.rect(Rect2(r.position + LIGHT * 12.0, r.size), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.26))
	b.rect(r, PLINTH_DARK)
	b.rect(r.grow(-5.0), PLINTH_COL)
	b.rect(Rect2(r.position + Vector2(5.0, 5.0), Vector2(r.size.x - 10.0, 4.0)), PLINTH_COL.lightened(0.15))
	var pq := Rect2(PLINTH.x - 20.0, r.end.y - 18.0, 40.0, 12.0)
	b.rect(pq, Color(0.45, 0.34, 0.18))
	b.rect(pq.grow(-1.5), Color(0.62, 0.48, 0.26))
	for ly: float in [3.5, 7.0]:
		b.line(Vector2(pq.position.x + 4.0, pq.position.y + ly), Vector2(pq.end.x - 4.0, pq.position.y + ly), Color(0.32, 0.22, 0.12), 1.0)
	if state != State.IDLE and pos.distance_to(PLINTH) > 4.0:
		# the empty top, cracked where his feet stood
		var cc := Color(0.30, 0.28, 0.26, 0.7)
		for k in range(4):
			var lp: Vector2 = PLINTH + LEG_OFFSETS[k]
			b.circle(lp, 15.0, Color(0.52, 0.50, 0.46))
			b.line(lp, lp + Vector2(10.0, -8.0).rotated(float(k)), cc, 1.6)


func draw_ground(b: ShapeBatch, vt: float, vb: float) -> void:
	draw_plinth(b)
	var cc := Color(0.30, 0.24, 0.16, 0.7)
	for cr: Dictionary in craters:
		var cp: Vector2 = cr.p
		if cp.y < vt - 80.0 or cp.y > vb + 80.0:
			continue
		var a := clampf(float(cr.life) / 1.5, 0.0, 1.0)
		b.circle(cp, 34.0, Color(0.36, 0.30, 0.20, 0.30 * a))
		for i in range(6):
			var d := Vector2.from_angle(float(cr.a) + float(i) * TAU / 6.0)
			b.line(cp + d * 14.0, cp + d * (30.0 + float(i % 2) * 14.0), Color(cc.r, cc.g, cc.b, cc.a * a), 2.2)


func draw_crowd(b: ShapeBatch, vt: float, vb: float, t: float) -> void:
	for pp: Dictionary in crowd:
		var p: Vector2 = pp.p
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var ph: float = pp.ph
		var shirt: Color = pp.shirt
		var skin: Color = pp.skin
		if bool(pp.rowing):
			# a rowing boat, rocking harder while the fight is loud
			var rock := sin(t * 2.0 + ph) * (2.0 + gasp * 6.0)
			var hull := PackedVector2Array([
				p + Vector2(-16.0, -34.0 + rock), p + Vector2(16.0, -34.0 + rock),
				p + Vector2(22.0, 26.0 - rock), p + Vector2(0.0, 40.0), p + Vector2(-22.0, 26.0 + rock),
			])
			b.circle(p + Vector2(0.0, 6.0), 34.0, Color(0.20, 0.36, 0.48, 0.22))
			b.polygon(hull, Color(0.50, 0.30, 0.18))
			b.circle(p + Vector2(0.0, 2.0), 14.0, Color(0.62, 0.40, 0.24))
			var oar := sin(t * 2.4 + ph) * 0.5
			for sd: float in [-1.0, 1.0]:
				b.line(p + Vector2(sd * 8.0, 0.0), p + Vector2(sd * 38.0, 10.0 * oar * sd), Color(0.70, 0.56, 0.36), 2.5)
			b.circle(p, 8.0, shirt)
			b.circle(p + Vector2(0.0, -2.0), 5.0, skin)
			b.circle(p + Vector2(0.0, -3.0), 4.2, pp.hair)
			continue
		var away := Vector2(signf(p.x - pos.x), 0.0)
		var jump := absf(sin(t * 9.0 + ph)) * 7.0 * cheer
		var at := p + away * gasp * 4.0 + Vector2(0.0, -jump)
		b.circle(p + LIGHT * 3.0, 9.0, SHADOW)
		if cheer > 0.3 or gasp > 0.5:
			var up := 14.0 if cheer > 0.3 else 9.0
			for sd: float in [-1.0, 1.0]:
				var hand := at + Vector2(sd * 9.0, -up)
				b.line(at + Vector2(sd * 6.0, -2.0), hand, shirt, 4.0)
				b.circle(hand, 2.6, skin)
		b.circle(at, 9.0, shirt.darkened(0.25))
		b.circle(at - LIGHT * 1.2, 7.6, shirt)
		b.circle(at + Vector2(0.0, -2.0), 5.4, skin)
		b.circle(at + Vector2(0.0, -3.4), 4.6, pp.hair)


# The telegraphs: the swipe's sector, the stomp's ring, the charge's lane and
# the spray's lane, drawn on the ground under him.
func draw_warnings(b: ShapeBatch, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 14.0)
	if state == State.SWIPE and state_t > 0.0 or last_swipe_warning():
		var fill := 1.0 - (state_t / SWIPE_WARN if state == State.SWIPE else ls_swipe_cd / SWIPE_WARN)
		var reach := SWIPE_REACH if state == State.SWIPE else LAST_SWIPE_REACH
		var pts := PackedVector2Array([pos])
		var a0 := swipe_dir.angle() - SWIPE_HALF
		for i in range(13):
			pts.append(pos + Vector2.from_angle(a0 + SWIPE_HALF * 2.0 * float(i) / 12.0) * reach)
		b.polygon(pts, Color(WARN.r, WARN.g, WARN.b, 0.10 + 0.08 * pulse))
		var inner := PackedVector2Array([pos])
		for i in range(13):
			inner.append(pos + Vector2.from_angle(a0 + SWIPE_HALF * 2.0 * float(i) / 12.0) * reach * clampf(fill, 0.0, 1.0))
		b.polygon(inner, Color(WARN.r, WARN.g, WARN.b, 0.22))
		for i in range(12):
			b.line(pts[i + 1], pts[i + 2], Color(1.0, 0.45, 0.28, 0.8), 3.0)
		b.line(pos, pts[1], Color(1.0, 0.45, 0.28, 0.6), 2.0)
		b.line(pos, pts[13], Color(1.0, 0.45, 0.28, 0.6), 2.0)
	if state == State.CHARGE_WARN:
		var side := charge_dir.orthogonal()
		var lane := Color(WARN.r, WARN.g, WARN.b, 0.22 + 0.12 * pulse)
		b.line(pos, charge_end, lane, 64.0)
		b.line(pos + side * 32.0, charge_end + side * 32.0, Color(1.0, 0.3, 0.2, 0.6), 2.0)
		b.line(pos - side * 32.0, charge_end - side * 32.0, Color(1.0, 0.3, 0.2, 0.6), 2.0)
		var ln := pos.distance_to(charge_end)
		var d := 60.0 + fmod(t * 260.0, 60.0)
		while d < ln - 10.0:
			var cp := pos + charge_dir * d
			var cc := Color(1.0, 0.85, 0.75, 0.75 * (1.0 - d / ln))
			b.line(cp - side * 16.0 - charge_dir * 10.0, cp, cc, 3.0)
			b.line(cp + side * 16.0 - charge_dir * 10.0, cp, cc, 3.0)
			d += 60.0
	if state == State.SPRAY and state_t > SPRAY_TIME:
		var from := trunk_tip()
		var to := from + spray_dir * SPRAY_LEN
		var k := 1.0 - (state_t - SPRAY_TIME) / SPRAY_WARN
		b.line(from, to, Color(0.55, 0.78, 0.98, 0.14 + 0.08 * pulse), SPRAY_W)
		b.line(from, from.lerp(to, clampf(k, 0.0, 1.0)), Color(0.55, 0.78, 0.98, 0.26), SPRAY_W * 0.5)


func draw_mamut(b: ShapeBatch, t: float) -> void:
	var at := pos
	if state == State.WRAPPED:
		var k := clampf(act_t / WOBBLE_TIME, 0.0, 1.0)
		at.x += sin(act_t * 14.0) * (3.0 + k * 12.0)
	elif state == State.CHARGE_WARN:
		var k := 1.0 - clampf(state_t / CHARGE_WARN, 0.0, 1.0)
		at -= charge_dir * 12.0 * k
		at.x += sin(t * 60.0) * 1.5 * k
	elif state == State.STUNNED:
		at.x += sin(t * 9.0) * 2.0
	var f := face_dir
	var s := f.orthogonal()
	var lift := Vector2(0.0, -hop_z)
	var sat := state == State.SAT
	var awake := state != State.IDLE and state != State.CONTENT
	var in_lake := at.x > SHORE_X - 10.0
	# the shadow on the ground, then everything lifted by hop_z
	b.polygon(_ellipse(at + LIGHT * (16.0 + hop_z * 0.5), f, 78.0, 62.0, 20), SHADOW)
	if in_lake:
		b.polygon(_ellipse(at, f, 92.0, 76.0, 20), Color(0.70, 0.86, 0.98, 0.35))
	var c := at + lift
	var stone := STONE.lerp(Color.WHITE, flash * 0.5)
	# legs: the stone columns he stands on, seen from above as feet
	if not sat:
		for k in range(4):
			var lp := c + LEG_OFFSETS[k].rotated(f.angle() - PI * 0.5)
			if state in [State.PROWL, State.RETREAT, State.CHARGE]:
				lp += f * sin(t * 6.0 + float(k) * 1.7) * 4.0
			b.circle(lp, LEG_RADIUS, STONE_DARK)
			b.circle(lp - LIGHT * 2.0, LEG_RADIUS - 4.0, stone.darkened(0.12))
			for n in range(3):
				var toe := lp + f * 14.0 + s * (float(n) - 1.0) * 7.0
				b.circle(toe, 3.2, TUSK_DARK)
	# the shaggy body: a fringe of tufts round a domed back
	var body_c := c - f * 10.0
	if sat:
		body_c = c - f * 22.0
	for i in range(18):
		var a := float(i) * TAU / 18.0
		var e := body_c + f * cos(a) * 62.0 + s * sin(a) * 52.0
		b.circle(e, 15.0, FUR.darkened(0.15))
	b.polygon(_ellipse(body_c, f, 64.0, 54.0, 22), stone)
	b.polygon(_ellipse(body_c - LIGHT * 6.0 - f * 6.0, f, 48.0, 38.0, 18), STONE_LIT.lerp(stone, 0.4))
	# fur strokes down his back
	for i in range(7):
		var off := (float(i) - 3.0) * 12.0
		var p0 := body_c - f * 40.0 + s * off
		b.line(p0, p0 + f * 50.0 + s * off * 0.15, FUR.darkened(0.25), 2.0)
	b.circle(body_c + s * 24.0 - f * 20.0, 6.0, MOSS)
	b.circle(body_c - s * 30.0 + f * 6.0, 4.0, MOSS)
	# the domed head, small ears, eyes
	var head := c + f * 50.0
	if sat:
		head = c + f * 34.0
	var ear_w := sin(ear_t * 30.0) * 4.0 if ear_t > 0.0 else 0.0
	for sd: float in [-1.0, 1.0]:
		b.circle(head + s * sd * (32.0 + ear_w * sd) - f * 8.0, 13.0, FUR.darkened(0.2))
	b.circle(head, 34.0, stone.darkened(0.05))
	b.circle(head - f * 6.0 - LIGHT * 4.0, 22.0, STONE_LIT)
	b.circle(head - f * 14.0, 10.0, STONE_LIT.lightened(0.1))
	var eye_col := EYE_RED if enraged and hp > 0.0 else EYE_AMBER
	for sd: float in [-1.0, 1.0]:
		var ep := head + f * 14.0 + s * sd * 16.0
		if awake and state != State.SAT:
			b.circle(ep, 5.0, Color(0.12, 0.10, 0.08))
			b.circle(ep, 3.4, eye_col.lerp(Color.WHITE, 0.2 * sin(t * 6.0)))
		else:
			# closed: asleep as a statue, or content
			b.line(ep - s * 4.0, ep + s * 4.0, Color(0.22, 0.20, 0.18), 2.0)
	# the tusks: long, curving out and back in
	for sd: float in [-1.0, 1.0]:
		var p0 := head + f * 20.0 + s * sd * 14.0
		var p1 := p0 + f * 26.0 + s * sd * 18.0
		var p2 := p1 + f * 26.0 + s * sd * 2.0
		var p3 := p2 + f * 10.0 - s * sd * 14.0
		b.line(p0, p1, TUSK_DARK, 9.0)
		b.line(p1, p2, TUSK_DARK, 7.5)
		b.line(p2, p3, TUSK_DARK, 5.5)
		b.line(p0, p1, TUSK, 6.0)
		b.line(p1, p2, TUSK, 5.0)
		b.line(p2, p3, TUSK, 3.5)
		b.circle(p3, 2.2, TUSK)
	# the trunk: a tapering chain from the face to the tip
	var tip := trunk_tip() + lift
	var root := head + f * 26.0
	var mid := root.lerp(tip, 0.5) + s * trunk_sweep * 14.0 - f * trunk_lift * 10.0
	for i in range(9):
		var u := float(i) / 8.0
		var p := root.lerp(mid, u).lerp(mid.lerp(tip, u), u)
		var r := lerpf(13.0, 6.0, u)
		b.circle(p + LIGHT * 1.5, r, stone.darkened(0.22))
		b.circle(p, r - 1.5, stone.darkened(0.04))
	b.circle(tip, 6.5, stone.darkened(0.25))
	b.circle(tip, 3.0, Color(0.22, 0.20, 0.18))
	if state == State.STUNNED or state == State.SAT:
		for i in range(4):
			var a := t * 3.0 + float(i) * TAU / 4.0
			var sp := head + Vector2(cos(a) * 34.0, sin(a) * 14.0) - Vector2(0.0, 44.0)
			b.circle(sp, 4.0, Color(1.0, 0.92, 0.40))


# the leash's grip on his legs during the last stand, the rings of his
# stomps and wake, and the health bar over him
func draw_rings(b: ShapeBatch, t: float) -> void:
	for dr in rings:
		var frac: float = 1.0 - (float(dr.life) / maxf(float(dr.max), 0.01))
		if dr.get("warn", false):
			var wr: float = dr.r
			b.circle(dr.pos, wr * frac, Color(WARN.r, WARN.g, WARN.b, 0.12 + 0.16 * frac))
			_ring(b, dr.pos, wr, Color(1.0, 0.4, 0.25, 0.55 + 0.4 * frac), 3.0)
			_ring(b, dr.pos, STOMP_DODGE, Color(1.0, 0.85, 0.40, 0.25 + 0.25 * frac), 2.0)
			continue
		var r: float = float(dr.r) * (0.3 + frac * 0.7)
		var base: Color = dr.get("col", DUST)
		_ring(b, dr.pos, r, Color(base.r, base.g, base.b, (1.0 - frac) * 0.6), 4.0)
	if state == State.STAND:
		_ring(b, pos, 104.0, Color(0.98, 0.85, 0.30, 0.35 + sin(t * 8.0) * 0.15), 3.0)
	if state == State.STAND or state == State.WRAPPED:
		for k in range(leg_poles.size()):
			if main.elapsed - leg_touch_t[k] <= LEG_MEMORY or state == State.WRAPPED:
				_ring(b, leg_poles[k], LEG_RADIUS + 6.0, Color(1.0, 0.90, 0.20, 0.9), 3.0)
	if fountain_t >= 0.0 and fountain_t < 7.0:
		# a rainbow in the spray, fading in and out
		var a := clampf(fountain_t / 1.0, 0.0, 1.0) * clampf((7.0 - fountain_t) / 2.0, 0.0, 1.0)
		var top := trunk_tip() - Vector2(0.0, 60.0)
		for i in range(RAINBOW.size()):
			var rc: Color = RAINBOW[i]
			var rr := 120.0 - float(i) * 7.0
			var pts := PackedVector2Array()
			for k in range(17):
				var ang := PI + PI * float(k) / 16.0
				pts.append(top + Vector2(cos(ang) * rr, sin(ang) * rr * 0.6))
			for k in range(16):
				b.line(pts[k], pts[k + 1], Color(rc.r, rc.g, rc.b, 0.45 * a), 6.0)


func draw_bits(b: ShapeBatch, vt: float, vb: float) -> void:
	for bt: Dictionary in bits:
		var p: Vector2 = bt.p
		if p.y < vt - 120.0 or p.y > vb + 120.0:
			continue
		var f: float = clampf(float(bt.life) / float(bt.max), 0.0, 1.0)
		var col: Color = bt.col
		col.a *= minf(f * 2.0, 1.0)
		var at := p - Vector2(0.0, float(bt.z))
		if bt.spark:
			b.line(at, at - (bt.v as Vector2) * 0.035, col, float(bt.r))
		else:
			if bt.z > 0.0:
				b.circle(p + LIGHT * 2.0, float(bt.r) * 0.8, SHADOW)
			b.circle(at, float(bt.r) * (0.5 + f * 0.5), col)


# The plate's top-left, pushed down below the HUD banner when the banner is up
# over him: the banner sits top centre, and he is in the top third of the
# screen for most of the fight. `above` is how far the name rises over `bp`.
func _below_banner(bp: Vector2, above: float) -> Vector2:
	if main == null or main.feed == null:
		return bp
	var r: Rect2 = main.feed.banner_rect()
	if r.size == Vector2.ZERO:
		return bp
	var screen_bottom: Vector2 = main.feed.get_canvas_transform() * Vector2(r.get_center().x, r.end.y + 6.0)
	var world: Vector2 = main.get_global_transform_with_canvas().affine_inverse() * screen_bottom
	bp.y = maxf(bp.y, world.y + above)
	return bp


func draw_health_bar(c: Object) -> void:
	if state == State.IDLE or state == State.AWAKEN or hp <= 0.0:
		return
	var at := pos - Vector2(0.0, hop_z)
	var bar_w := 170.0
	var bar_h := 10.0
	var bp := _below_banner(at + Vector2(-bar_w * 0.5, -128.0), 24.0)
	c.draw_rect(Rect2(bp + LIGHT * 3.0, Vector2(bar_w, bar_h)), SHADOW)
	c.draw_rect(Rect2(bp - Vector2(2.0, 2.0), Vector2(bar_w + 4.0, bar_h + 4.0)), STONE_DARK)
	c.draw_rect(Rect2(bp - Vector2(1.0, 1.0), Vector2(bar_w + 2.0, bar_h + 2.0)), STONE_LIT)
	c.draw_rect(Rect2(bp, Vector2(bar_w, bar_h)), Color(0.10, 0.09, 0.08))
	var hf := clampf(hp / max_hp, 0.0, 1.0)
	if hf > 0.0:
		var fc := Color(0.96, 0.32, 0.22) if phase == 2 else Color(0.96, 0.74, 0.18)
		fc = fc.lerp(Color.WHITE, flash * 0.7)
		var fill := Rect2(bp + Vector2(1, 1), Vector2((bar_w - 2.0) * hf, bar_h - 2.0))
		c.draw_rect(fill, fc)
		c.draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), fc.lightened(0.35))
	c.draw_rect(Rect2(bp + Vector2(bar_w * 0.5 - 1.0, -2.0), Vector2(2.0, bar_h + 4.0)), STONE_DARK)
	var fnt: Font = Kit.display()
	var label := "EL MAMUT"
	var tw: float = Kit.text_w(fnt, label, 14)
	var tp := bp + Vector2((bar_w - tw) * 0.5, -5.0)
	c.draw_string_outline(fnt, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0.05, 0.04, 0.04, 0.85))
	c.draw_string(fnt, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TUSK)


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
