class_name BossLleona
extends RefCounted

# LA LLEONA, Girona's statue boss (docs/BOSSES.md): the Romanesque stone
# lioness of Plaça de Sant Feliu climbs down off her column, and your human
# will not walk past a lioness. She fights by looking: the danger is being
# seen, so the fight is about what stands between her and the dog.
#
# - The wake: the dog past WAKE_Y, her eyes open, she roars and leaps down off
#   the column (AWAKEN_TIME) under a title card.
# - Part one: she stalks round the dog. Close in front she rakes a paw across a
#   sector (RAKE_WARN filling it). Further off she claws the paving, and a
#   ripple of flagstones runs down a lane. One that misses wears her down.
# - Part two, below half: she bounds to one of three PERCHES and plants
#   herself; her eyes glint for GAZE_WARN, then a beam of stone gaze sweeps the
#   square across the dog. Seen, the dog is stone for STONE_TIME. Hidden behind
#   the column or a planter (a planter crumbles after one gaze), the gaze is
#   spent on nothing: that wears her down most, and leaves her SPENT, when a
#   bark on her nose is a boop and a nose at her tail is the kiss the town's
#   iron steps are for. A taut leash across her bound trips her; the
#   Basílica's rain spout blinds her; your human flung into her bowls her.
#   Your human is never turned to stone: they never look up from the phone.
# - Part three: out of fight she climbs back on her column and rakes at the dog
#   from it while the leash goes round three legs within LEG_MEMORY. She
#   wobbles, slides down, and a bark on her nose settles her.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Kit := preload("res://hud/ui_kit.gd")
const Ach := preload("res://systems/achievements.gd")

const SHADOW := Color(0.04, 0.05, 0.10, 0.28)
const STONE := Color(0.76, 0.70, 0.59)
const STONE_DARK := Color(0.43, 0.38, 0.33)
const STONE_LIT := Color(0.91, 0.86, 0.74)
const CARVE := Color(0.57, 0.51, 0.43)
const EYE_GOLD := Color(1.0, 0.82, 0.30)
const EYE_RED := Color(1.0, 0.32, 0.14)
const GAZE_COL := Color(1.0, 0.76, 0.28)
const SAFE := Color(0.25, 0.88, 0.82)
const WARN := Color(1.0, 0.36, 0.20)
const DUST := Color(0.80, 0.76, 0.66, 0.50)
const WATER := Color(0.62, 0.84, 1.0, 0.85)

# --- The arena: Plaça de Sant Feliu -------------------------------------------
const COLUMN := Vector2(640.0, -3320.0)
const COLUMN_RECT := Rect2(618.0, -3342.0, 44.0, 44.0)
const LANDING := Vector2(640.0, -3440.0)
const ARENA_L := 400.0
const ARENA_R := 880.0
const ARENA_TOP := -3620.0
const ARENA_BOT := -3205.0
const HOLD_Y := -3105.0
const WAKE_Y := -2960.0
# where she plants herself to look: west, north and east, so that the column's
# shadow from each falls inside the leash's reach of HOLD_Y
const PERCHES: Array[Vector2] = [
	Vector2(400.0, -3350.0), Vector2(640.0, -3500.0), Vector2(880.0, -3350.0),
]
const PLANTERS: Array[Rect2] = [
	Rect2(462.0, -3262.0, 52.0, 44.0), Rect2(766.0, -3262.0, 52.0, 44.0),
]
const SPOUT_AT := Vector2(868.0, -3280.0)
const SPOUT_R := 62.0

const LEG_OFFSETS: Array[Vector2] = [
	Vector2(-34.0, -36.0), Vector2(34.0, -36.0),
	Vector2(-34.0, 36.0), Vector2(34.0, 36.0),
]
const LEG_RADIUS := 15.0
const BODY_R := 54.0
const COLUMN_CLEAR := 82.0      # she keeps this far round the column

# --- Tuning ------------------------------------------------------------------
const MAX_HP := 100.0
const FILM := "res://intro/film_lleona.gd"
const FILM_WIN := "res://intro/film_lleona_win.gd"
const STALK_SPEED := 85.0
const STALK_DIST := 150.0
const BOUND_SPEED := 260.0
const BOUND_MAX := 3.2
const TURN_RATE := 2.2
const FRONT_CONE := 1.0
const RAKE_TRIGGER := 165.0
const RAKE_REACH := 160.0
const RAKE_HALF := 0.85
const RAKE_WARN := 0.85
const RAKE_STRIKE := 0.28
const RAKE_COOLDOWN := 2.3
const RIPPLE_MIN := 150.0
const RIPPLE_MAX := 430.0
const RIPPLE_WARN := 0.9
const RIPPLE_LEN := 400.0
const RIPPLE_W := 52.0
const RIPPLE_SPEED := 560.0
const RIPPLE_COOLDOWN := 3.2
const GAZE_WARN := 0.9
const GAZE_SWEEP := 1.7
const GAZE_SPAN := 0.95         # each side of where the dog was
const GAZE_HALF := 0.13         # half the beam
const GAZE_REACH := 640.0
const GAZE_COOLDOWN := 5.5
const STONE_TIME := 1.3
const SPENT_TIME := 2.8
const STUN_TIME := 2.8
const SPOUT_EVERY := 6.5
const SPOUT_WARN := 1.0
const SPOUT_POUR := 1.5
const DODGE_DAMAGE := 9.0
const DODGE_DAMAGE_2 := 4.0     # part two is won by hiding, not by dodging
const HIDE_DAMAGE := 18.0
const SPOUT_DAMAGE := 24.0
const TRIP_DAMAGE := 22.0
const BOWL_DAMAGE := 25.0
const BOOP_DAMAGE := 8.0
const KISS_DAMAGE := 16.0
const KISS_REACH := 46.0
const RETREAT_SPEED := 190.0
const LEG_MEMORY := 1.5
const LEGS_TO_TIE := 3
const TIE_FROM := 1.0           # a leash she climbed up across ties nothing yet
const CLOTHESLINE_END_PTS := 3
const HIT_BOX_R := 46.0
const BOOP_REACH := 74.0
const AWAKEN_TIME := 2.6
const AWAKEN_EYES := 0.4
const AWAKEN_ROAR := 1.1
const AWAKEN_LEAP := 1.7
const ENRAGE_TIME := 1.6
const ENRAGE_BLAST := 0.55
const LAST_RAKE_EVERY := 2.8
const LAST_RAKE_REACH := 150.0
const WOBBLE_TIME := 1.2
const SETTLED_SLIP := 2.5       # the wound leash slips off once she is settled
const CARD_TIME := 3.4
const CARD_FROM := 0.3
const LEAN_MAX := 220.0
const LEAN_EASE := 3.0
const SHOUT_GAP := 2.6
const STATUE_SCALE := 0.78      # curled on her column

enum State {
	IDLE, AWAKEN, ENRAGE, STALK, RAKE, RIPPLE, BOUND, GAZE_WARN, GAZE,
	SPENT, STUNNED, RETREAT, STAND, WRAPPED, SAT, CONTENT,
}

var state: State = State.IDLE
var state_t := 0.0
var act_t := 0.0
var hp := MAX_HP
var max_hp := MAX_HP
var phase := 1
var main: Node2D = null
var pos := COLUMN
var face_dir := Vector2.DOWN
var hop_z := 0.0

var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []
var leg_soft_indices: Array[int] = []
var leg_furniture_indices: Array[int] = []
var leg_touch_t: Array[float] = [-INF, -INF, -INF, -INF]
var legs_tied := 0

var rake_dir := Vector2.DOWN
var rake_side := 1.0
var rake_cd := 1.0
var rake_struck := false
var rake_swing := 0.0
var ripple_dir := Vector2.DOWN
var ripple_from := Vector2.ZERO
var ripple_hit := false
var ripple_human := false
var ripple_cd := 1.6
var perch := PERCHES[1]
var gaze_mid := Vector2.DOWN
var gaze_side := 1.0
var gaze_cd := GAZE_COOLDOWN
var gaze_caught := false
var gaze_hid := false
var gaze_planter := -1
var planters_up: Array[bool] = [true, true]
var spout_t := SPOUT_EVERY
var spout_pouring := false
var spout_hit := false
var booped_this := false
var kissed_this := false
var bowled_this := false
var last_rake_cd := LAST_RAKE_EVERY
var hold_noticed := false
var human_oblivious := false
var enraged := false
var film_shown := false
var win_film_shown := false

# the show: none of it touches the fight's rules
var flash := 0.0
var screen_flash := 0.0
var lean := 0.0
var card_t := -1.0
var card: Control = null
var cheer := 0.0
var gasp := 0.0
var shout_cd := 0.0
var rings: Array[Dictionary] = []
var bits: Array[Dictionary] = []
var cracks: Array[Dictionary] = []
var crowd: Array[Dictionary] = []
var fx := RandomNumberGenerator.new()

const CHEERS: Array[String] = ["Bravo!", "Go on, pup!", "Again!", "What a dog!", "Olé!"]
const GASPS: Array[String] = ["Look out!", "Oh no!", "Hide, pup!", "Don't look!"]
const WINS: Array[String] = ["Bravo!", "Good dog!", "Nice lioness!", "Visca!"]
const COATS: Array[Color] = [
	Color(0.80, 0.28, 0.26), Color(0.22, 0.42, 0.64), Color(0.92, 0.72, 0.26),
	Color(0.26, 0.52, 0.40), Color(0.56, 0.34, 0.62), Color(0.84, 0.84, 0.80),
]
const SKINS: Array[Color] = [
	Color(0.96, 0.80, 0.66), Color(0.82, 0.62, 0.46), Color(0.62, 0.42, 0.30), Color(0.45, 0.30, 0.22),
]
const PETALS: Array[Color] = [Color(0.92, 0.34, 0.46), Color(0.98, 0.78, 0.30), Color(0.74, 0.46, 0.84)]


# --- Setup -------------------------------------------------------------------

func setup(m_ref: Node2D) -> void:
	main = m_ref
	leg_poles.clear()
	for k in range(LEG_OFFSETS.size()):
		leg_poles.append(_leg_at(k))
	fx.seed = 1100
	# onlookers along the parapet and the Basílica's wall; drawn only
	crowd.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1150
	for x: float in [342.0, 938.0]:
		var y := -2900.0
		while y > -3760.0:
			crowd.append({"p": Vector2(x + rng.randf_range(-4.0, 4.0), y),
				"coat": COATS[rng.randi() % COATS.size()], "skin": SKINS[rng.randi() % SKINS.size()],
				"ph": rng.randf() * TAU, "brolly": rng.randf() < 0.6})
			y -= rng.randf_range(64.0, 110.0)


# Called by LevelBuild after the rope radii are filled: the legs are rope
# points with furniture slip, kept out of the static bodies.
func register_legs(m: Node2D) -> void:
	leg_indices.clear()
	leg_soft_indices.clear()
	leg_furniture_indices.clear()
	leg_poles.clear()
	for k in range(LEG_OFFSETS.size()):
		var lp := _leg_at(k)
		leg_indices.append(m.poles.size())
		leg_soft_indices.append(m.rope_soft.size())
		m.poles.append(lp)
		m.rope_radii.append(LEG_RADIUS + 2.0)
		m.rope_soft.append(lp)
		leg_poles.append(lp)


func is_leg_index(i: int) -> bool:
	return not leg_indices.is_empty() and i >= leg_indices[0] and i <= leg_indices[leg_indices.size() - 1]


# her legs turn with her: offsets are in her frame, face pointing down
func _leg_at(k: int) -> Vector2:
	# settled, she has her feet under her and the leash is round the column alone
	if state == State.CONTENT:
		return COLUMN
	return pos + LEG_OFFSETS[k].rotated(face_dir.angle() - PI * 0.5)


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


func nose() -> Vector2:
	return pos + face_dir * 58.0


func eye() -> Vector2:
	return pos + face_dir * 44.0


func rear() -> Vector2:
	return pos - face_dir * 62.0


func weak() -> bool:
	return state == State.SPENT or state == State.STUNNED


func damage(amt: float) -> void:
	var was := hp
	hp = maxf(0.0, hp - amt)
	if hp < was:
		flash = 1.0
		_cheer_up()
	if hp <= MAX_HP * 0.5 and phase == 1:
		phase = 2
		main.feed.say(I18n.t("w_la_lleona_is_furious"), EventFeed.Tone.LOUD)
	if hp <= 0.0 and was > 0.0:
		main.feed.say(I18n.t("w_she_s_had_enough_after_her"), EventFeed.Tone.GOOD)


# --- Transitions -------------------------------------------------------------

func transition_to(s: State) -> void:
	if s == State.STALK and hp <= 0.0:
		s = State.RETREAT
	elif s == State.STALK and phase == 2 and not enraged:
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
			Sfx.play("lion_roar", 0.9, -2.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
			gasp = 1.0
			_crowd_shout(GASPS)
		State.RAKE:
			state_t = RAKE_WARN
			rake_dir = face_dir
			rake_side = -rake_side
			rake_struck = false
		State.RIPPLE:
			state_t = RIPPLE_WARN
			ripple_dir = _to_dog()
			face_dir = ripple_dir
			ripple_from = pos + ripple_dir * 46.0
			ripple_hit = false
			ripple_human = false
			Sfx.play("grit", 0.6, -4.0)
		State.BOUND:
			perch = _pick_perch()
			Sfx.play("lion_roar", 1.25, -8.0)
			gasp = 1.0
			_crowd_shout(GASPS)
		State.GAZE_WARN:
			state_t = GAZE_WARN
			gaze_mid = _to_dog()
			face_dir = gaze_mid
			update_leg_positions()
			gaze_side = -gaze_side
			gaze_caught = false
			gaze_hid = false
			gaze_planter = -1
			Sfx.play("bell", 0.5, -3.0)
			main.float_text(pos + Vector2(0.0, -60.0), I18n.t("w_rumble"), Color(1.0, 0.88, 0.55))
		State.GAZE:
			state_t = GAZE_SWEEP
			Sfx.play("ooooh", 0.5, -4.0)
		State.SPENT, State.STUNNED:
			state_t = SPENT_TIME if s == State.SPENT else STUN_TIME
			booped_this = false
			kissed_this = false
			bowled_this = false
			Sfx.play("groan", 1.1, -5.0)
		State.RETREAT:
			_crowd_shout(CHEERS)
		State.STAND:
			pos = COLUMN
			face_dir = Vector2.DOWN
			hop_z = 0.0
			update_leg_positions()
			legs_tied = 0
			leg_touch_t = [-INF, -INF, -INF, -INF]
			last_rake_cd = LAST_RAKE_EVERY
			Sfx.play("lion_roar", 1.0, -3.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			main.feed.say(I18n.t("w_tie_up_her_legs"), EventFeed.Tone.LOUD)
			for r: float in [80.0, 150.0]:
				rings.append({"pos": pos, "r": r, "life": 0.7, "max": 0.7})
			_burst(pos, 16, STONE_DARK, 90.0, 260.0, 3.5, 0.6, false, 260.0)
		State.WRAPPED:
			state_t = WOBBLE_TIME
			Sfx.play("intro_taut", 0.8, -5.0)
			Sfx.play("groan", 1.0, -5.0)
			Sfx.play("ooooh", 1.0, -8.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
			gasp = 1.0
		State.SAT:
			Sfx.play("crack", 0.5, -3.0)
			Sfx.play("drum", 0.4, -1.0)
			Sfx.play("whoop", 1.0, -6.0)
			main.lleona_sat = true
			main.shake_t = 1.4
			main.feed.say(I18n.t("w_la_lleona_slides_down"), EventFeed.Tone.LOUD)
			for r: float in [50.0, 110.0, 180.0, 260.0]:
				rings.append({"pos": pos, "r": r, "life": 0.8, "max": 0.8})
			_burst(pos, 26, STONE_DARK, 120.0, 340.0, 4.0, 0.8, false, 300.0)
			_scatter_pigeons(pos, 900.0)
			screen_flash = 0.7
			_big_hit()
			_cheer_up()
		State.CONTENT:
			Sfx.play("gat_purr", 0.8, -2.0)
			Sfx.play("star", 1.1)
			Sfx.play("whoop", 1.1, -4.0)
			main.lleona_settled = true
			update_leg_positions()
			if main.leash != null:
				main.leash.free_slip_t = maxf(float(main.leash.free_slip_t), SETTLED_SLIP)
			Ach.on_boss_settled(main, "boss_lleona")
			main.combo.add("BOOP", 10)
			main.float_text(nose(), I18n.t("w_booped_10"), Color(1.0, 0.88, 0.25))
			main.feed.say(I18n.t("w_girona_is_yours"), EventFeed.Tone.GOOD)
			main.human.say_line(I18n.t("w_good_lioness"))
			cheer = 1.0
			shout_cd = 0.0
			_crowd_shout(WINS)
			if not win_film_shown and FilmPlayer.should_play(main) and ResourceLoader.exists(FILM_WIN):
				win_film_shown = true
				FilmPlayer.play(main, load(FILM_WIN))


# --- The gaze ----------------------------------------------------------------

# the perch farthest from the dog, so she always has the column to run for
func _pick_perch() -> Vector2:
	var dog_p: Vector2 = main.dog.global_position
	var best := PERCHES[0]
	for p: Vector2 in PERCHES:
		if p.distance_squared_to(dog_p) > best.distance_squared_to(dog_p):
			best = p
	return best


# what can be hidden behind: the column, then each planter still whole
func covers() -> Array[Rect2]:
	var out: Array[Rect2] = [COLUMN_RECT]
	for k in range(PLANTERS.size()):
		if planters_up[k]:
			out.append(PLANTERS[k])
	return out


# how far along from->to a rect is first met, 0..1, or 2 when it is not
static func _meets(from: Vector2, to: Vector2, r: Rect2) -> float:
	var d := to - from
	var t0 := 0.0
	var t1 := 1.0
	for ax in range(2):
		if absf(d[ax]) < 0.001:
			if from[ax] < r.position[ax] or from[ax] > r.end[ax]:
				return 2.0
			continue
		var a := (r.position[ax] - from[ax]) / d[ax]
		var b := (r.end[ax] - from[ax]) / d[ax]
		t0 = maxf(t0, minf(a, b))
		t1 = minf(t1, maxf(a, b))
	return t0 if t0 <= t1 else 2.0


# the cover between her eye and p: -1 none, 0 the column, 1.. a planter's
# number and one
func cover_between(p: Vector2) -> int:
	var from := eye()
	if _meets(from, p, COLUMN_RECT) <= 1.0:
		return 0
	for k in range(PLANTERS.size()):
		if planters_up[k] and _meets(from, p, PLANTERS[k]) <= 1.0:
			return k + 1
	return -1


func gaze_angle() -> float:
	var k := 1.0 - clampf(state_t / GAZE_SWEEP, 0.0, 1.0) if state == State.GAZE else 0.0
	return gaze_mid.angle() + gaze_side * lerpf(-GAZE_SPAN, GAZE_SPAN, k)


func _in_beam(p: Vector2) -> bool:
	var to := p - eye()
	return to.length() < GAZE_REACH and absf(wrapf(to.angle() - gaze_angle(), -PI, PI)) < GAZE_HALF


func _tick_gaze() -> void:
	var dog_p: Vector2 = main.dog.global_position
	if not gaze_caught and _in_beam(dog_p):
		var cov := cover_between(dog_p)
		if cov < 0:
			gaze_caught = true
			main.dog.petrify(STONE_TIME)
			Sfx.play("crack", 0.7, -3.0)
			main.float_text(dog_p, I18n.t("w_stone_dog"), Color(0.86, 0.84, 0.78))
			_burst(dog_p, 12, STONE, 60.0, 180.0, 3.0, 0.6, false, 160.0)
		else:
			gaze_hid = true
			if cov > 0:
				gaze_planter = cov - 1
	if not human_oblivious and _in_beam(main.human.global_position):
		human_oblivious = true
		main.human.say_line(I18n.t("w_is_it_getting_brighter"))


func _end_gaze() -> void:
	if gaze_planter >= 0 and planters_up[gaze_planter]:
		planters_up[gaze_planter] = false
		Sfx.play("crack", 0.8, -3.0)
		_burst(PLANTERS[gaze_planter].get_center(), 18, STONE_DARK, 80.0, 220.0, 4.0, 0.8, false, 240.0)
		main.feed.say(I18n.t("w_the_planter_is_stone_dust"), EventFeed.Tone.PLAIN)
	if gaze_caught:
		transition_to(State.STALK)
		return
	var dog_p: Vector2 = main.dog.global_position
	if gaze_hid:
		main.lleona_hides += 1
		main.combo.add("HIDE", 6)
		main.float_text(dog_p, I18n.t("w_unseen_6"), Color(0.5, 1.0, 0.92))
		main.feed.say(I18n.t("w_she_never_saw_you"), EventFeed.Tone.GOOD)
		damage(HIDE_DAMAGE)
	elif dog_p.distance_to(pos) < GAZE_REACH:
		_dodged(dog_p)
	transition_to(State.SPENT)


# --- Attacks and counters ------------------------------------------------------

func _to_dog() -> Vector2:
	var d: Vector2 = main.dog.global_position - pos
	return d.normalized() if d.length() > 1.0 else Vector2.DOWN


func in_sector(p: Vector2, dir: Vector2, reach: float, half: float) -> bool:
	var d := p - pos
	if d.length() > reach or d.length() < 1.0:
		return d.length() < 1.0
	return absf(dir.angle_to(d)) <= half


func _strike_rake(reach: float) -> void:
	rake_struck = true
	Sfx.play("fling", 1.0, -3.0)
	Sfx.play("crack", 1.2, -8.0)
	var dog_p: Vector2 = main.dog.global_position
	var push := rake_dir.orthogonal() * rake_side
	if in_sector(dog_p, rake_dir, reach + 10.0, RAKE_HALF):
		main.dog.knocked((push + rake_dir * 0.5).normalized(), "rake")
	elif dog_p.distance_to(pos) < reach + 120.0 and hp > 0.0:
		_dodged(dog_p)
	if in_sector(main.human.global_position, rake_dir, reach + 10.0, RAKE_HALF):
		main.human.bumped(push)
	for i in range(8):
		var a := rake_dir.angle() + lerpf(-RAKE_HALF, RAKE_HALF, float(i) / 7.0)
		_burst(pos + Vector2.from_angle(a) * reach * 0.8, 2, DUST, 40.0, 140.0, 4.0, 0.5, false, 120.0)
	_scatter_pigeons(pos, reach + 60.0)


# how far down its lane the ripple of flagstones has run
func ripple_at() -> float:
	return maxf(0.0, -state_t) * RIPPLE_SPEED


func _tick_ripple(delta: float) -> void:
	var was := maxf(0.0, -(state_t + delta)) * RIPPLE_SPEED
	var now := minf(ripple_at(), RIPPLE_LEN)
	if was <= 0.0:
		Sfx.play("drum", 0.5, -2.0)
		main.shake_t = maxf(float(main.shake_t), 0.5)
	var head := ripple_from + ripple_dir * now
	if fmod(act_t, 0.05) < delta:
		_burst(head, 4, STONE_DARK, 50.0, 150.0, 4.0, 0.5, false, 240.0)
		cracks.append({"p": head, "a": fx.randf() * TAU, "life": 8.0})
		if cracks.size() > 24:
			cracks.remove_at(0)
	if not ripple_hit and _in_ripple(main.dog.global_position, was, now):
		ripple_hit = true
		main.dog.knocked(ripple_dir, "flagstones")
	if not ripple_human and _in_ripple(main.human.global_position, was, now):
		ripple_human = true
		main.human.bumped(ripple_dir)


func _in_ripple(p: Vector2, from: float, to: float) -> bool:
	var along := (p - ripple_from).dot(ripple_dir)
	return along > from - 14.0 and along < to + 14.0 \
		and absf((p - ripple_from).dot(ripple_dir.orthogonal())) < RIPPLE_W * 0.5 + 10.0


func _dodged(at: Vector2) -> void:
	main.lleona_dodges += 1
	main.combo.add("DODGE", 2)
	main.float_text(at, I18n.t("w_dodged_2"), Color(0.8, 1.0, 0.7))
	damage(DODGE_DAMAGE if phase == 1 else DODGE_DAMAGE_2)


func check_trip() -> bool:
	var l = main.leash
	if l == null or l.detached:
		return false
	var rest: float = maxf(float(l.rest_len), 1.0)
	if l.taut_amount(l.used_length() / rest) < 0.15:
		return false
	var n: int = l.pts.size()
	for i in range(CLOTHESLINE_END_PTS, n - 1 - CLOTHESLINE_END_PTS):
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(pos, l.pts[i], l.pts[i + 1])
		if pos.distance_squared_to(cp) <= HIT_BOX_R * HIT_BOX_R:
			return true
	return false


func check_bowled() -> bool:
	if main.human.global_position.distance_to(pos) > BODY_R + 22.0:
		return false
	return main.human.whirl_flung_t > 0.0 or main.human.velocity.length() > 200.0


func _bowl() -> void:
	main.lleona_bowled = true
	damage(BOWL_DAMAGE)
	Sfx.play("drum", 0.5, -2.0)
	main.shake_t = 1.2
	main.human.bumped((main.human.global_position - pos).normalized())
	main.feed.say(I18n.t("w_human_bowling"), EventFeed.Tone.LOUD)
	main.combo.add("BOWLED", 12)
	main.float_text(pos, I18n.t("w_bowled_12"), Color(1.0, 0.6, 0.4))
	main.human.notice(I18n.t("w_ow_solid_stone"), 2.2)
	screen_flash = 0.35
	_big_hit()


func _hit(kind: String) -> void:
	match kind:
		"trip":
			main.lleona_tripped = true
			damage(TRIP_DAMAGE)
			Sfx.play("intro_taut", 0.9, -4.0)
			Sfx.play("drum", 0.45, -1.0)
			main.feed.say(I18n.t("w_tripped"), EventFeed.Tone.LOUD)
			main.combo.add("TRIP", 8)
			main.float_text(pos, I18n.t("w_tripped_8"), Color(1.0, 0.85, 0.2))
		"spout":
			main.lleona_blinded = true
			damage(SPOUT_DAMAGE)
			Sfx.play("splash", 0.8, -1.0)
			main.feed.say(I18n.t("w_rain_in_her_eyes"), EventFeed.Tone.LOUD)
			main.combo.add("SPLASH", 10)
			main.float_text(pos, I18n.t("w_splash_10"), Color(0.6, 0.85, 1.0))
			_burst(pos, 24, WATER, 110.0, 300.0, 4.0, 0.8, false, 320.0)
	hop_z = 0.0
	rake_swing = 0.0
	main.shake_t = maxf(float(main.shake_t), 0.9)
	screen_flash = 0.3
	_big_hit()
	transition_to(State.STUNNED)


# The Basílica's spout: it fills, pours on its ring, and stops. Where it pours
# is fixed, so she has to be led there. True when it blinded her this frame.
func _tick_spout(delta: float) -> bool:
	if state == State.IDLE or state == State.AWAKEN or hp <= 0.0:
		spout_pouring = false
		return false
	var was := spout_t
	spout_t -= delta
	if not spout_pouring:
		if was > SPOUT_WARN and spout_t <= SPOUT_WARN:
			Sfx.play("hiss", 0.8, -8.0)
		if spout_t <= 0.0:
			spout_pouring = true
			spout_hit = false
			spout_t = SPOUT_POUR
			Sfx.play("splash", 0.7, -5.0)
		return false
	if not spout_hit and pos.distance_to(SPOUT_AT) < SPOUT_R + 18.0 \
			and state in [State.STALK, State.RAKE, State.RIPPLE, State.BOUND]:
		spout_hit = true
		_hit("spout")
		return true
	if spout_t <= 0.0:
		spout_pouring = false
		spout_t = SPOUT_EVERY
	return false


func spout_warning() -> bool:
	return in_fight() and hp > 0.0 and not spout_pouring and spout_t <= SPOUT_WARN and state != State.AWAKEN


func _kiss() -> void:
	kissed_this = true
	main.lleona_kissed = true
	damage(KISS_DAMAGE)
	Sfx.play("pickup", 1.3, -3.0)
	main.combo.add("KISS", 8)
	main.float_text(rear(), I18n.t("w_kissed_8"), Color(1.0, 0.66, 0.76))
	main.feed.say(I18n.t("w_kissed_the_lioness"), EventFeed.Tone.GOOD)


func update_leg_tangle() -> void:
	var now: float = main.elapsed
	legs_tied = 0
	for k in range(leg_poles.size()):
		if act_t >= TIE_FROM and main.leash != null and main.leash.touches(leg_poles[k]):
			leg_touch_t[k] = now
		if now - leg_touch_t[k] <= LEG_MEMORY:
			legs_tied += 1
	if legs_tied >= LEGS_TO_TIE:
		transition_to(State.WRAPPED)


func _hold_human() -> void:
	# Nobody walks past a lioness. The autowalk bot cannot fight, so passes.
	var h = main.human
	var want: bool = in_fight() and not main.auto_walk \
		and not h.homeward and h.global_position.y < HOLD_Y + 300.0
	if want:
		h.tut_hold_y = HOLD_Y
		# and on the column's line: waiting off to one side they would hold the
		# leash short of her, and the last stand could not be won
		h.tut_hold_x = COLUMN.x
		if main.leash_target < main.LEASH_LENGTH:
			main.set_leash_target(main.LEASH_LENGTH)
		if not hold_noticed and h.global_position.y < HOLD_Y + 20.0:
			hold_noticed = true
			h.notice(I18n.t("w_not_past_a_lioness"), 1.8)
	elif h.tut_hold_y == HOLD_Y:
		h.tut_hold_y = -INF
		h.tut_hold_x = INF


# --- The tick ----------------------------------------------------------------

func tick_state(delta: float) -> void:
	if main.frozen:
		return
	_tick_show(delta)
	_hold_human()
	var dog_p: Vector2 = main.dog.global_position
	act_t += delta
	if _tick_spout(delta):
		return

	match state:
		State.IDLE:
			# your human still short of her: a pair already past (a shot taken
			# further up the walk) leaves her asleep
			if dog_p.y < WAKE_Y and main.human.global_position.y > HOLD_Y - 120.0 \
					and not bool(main.get("film_playing")):
				if not film_shown and FilmPlayer.should_play(main) and ResourceLoader.exists(FILM):
					film_shown = true
					FilmPlayer.play(main, load(FILM))
				else:
					transition_to(State.AWAKEN)

		State.AWAKEN:
			var was := act_t - delta
			if was < AWAKEN_EYES and act_t >= AWAKEN_EYES:
				Sfx.play("crack", 1.3, -8.0)
			if was < AWAKEN_ROAR and act_t >= AWAKEN_ROAR:
				Sfx.play("lion_roar", 1.0, 0.0)
				main.shake_t = maxf(float(main.shake_t), 0.9)
				for r: float in [100.0, 200.0, 320.0]:
					rings.append({"pos": pos, "r": r, "life": 0.9, "max": 0.9})
				_scatter_pigeons(pos, 400.0)
				main.human.notice(I18n.t("w_did_that_statue_just_twitch"), 2.2)
			if act_t >= AWAKEN_LEAP:
				var k := clampf((act_t - AWAKEN_LEAP) / (AWAKEN_TIME - AWAKEN_LEAP - 0.2), 0.0, 1.0)
				pos = COLUMN.lerp(LANDING, k)
				hop_z = sin(k * PI) * 34.0
				if k >= 1.0 and was < AWAKEN_TIME - 0.2:
					Sfx.play("drum", 0.45, -1.0)
					main.shake_t = maxf(float(main.shake_t), 0.7)
					rings.append({"pos": pos, "r": 110.0, "life": 0.6, "max": 0.6})
					_burst(pos, 14, DUST, 60.0, 180.0, 4.0, 0.6, false, 120.0)
				update_leg_positions()
			if act_t >= AWAKEN_TIME:
				hop_z = 0.0
				transition_to(State.STALK)

		State.ENRAGE:
			_turn_to(dog_p, delta * 2.0)
			update_leg_positions()
			hop_z = sin(clampf(act_t / ENRAGE_TIME, 0.0, 1.0) * PI) * 18.0
			if act_t - delta < ENRAGE_BLAST and act_t >= ENRAGE_BLAST:
				main.shake_t = maxf(float(main.shake_t), 1.0)
				for r: float in [90.0, 180.0, 290.0]:
					rings.append({"pos": pos, "r": r, "life": 0.8, "max": 0.8})
				_burst(pos, 22, GAZE_COL, 240.0, 400.0, 3.0, 0.4, true)
				_scatter_pigeons(pos, 500.0)
				screen_flash = 0.25
			if act_t >= ENRAGE_TIME:
				hop_z = 0.0
				gaze_cd = 0.6
				transition_to(State.STALK)

		State.STALK:
			# a hit that crossed half or emptied her lands between attacks too
			if hp <= 0.0 or (phase == 2 and not enraged):
				transition_to(State.STALK)
				return
			rake_cd -= delta
			ripple_cd -= delta
			gaze_cd -= delta
			_turn_to(dog_p, delta)
			var away := pos - dog_p
			var want := dog_p + (away.normalized() if away.length() > 1.0 else Vector2.UP) * STALK_DIST
			_step_to(want, STALK_SPEED, delta)
			# no attack while her title card is up: the banner is hushed under it
			if hush_banner():
				return
			var d := dog_p.distance_to(pos)
			var front := absf(face_dir.angle_to(dog_p - pos)) < FRONT_CONE
			if phase == 2 and gaze_cd <= 0.0 and d < GAZE_REACH:
				gaze_cd = GAZE_COOLDOWN
				transition_to(State.BOUND)
			elif d < RAKE_TRIGGER and front and rake_cd <= 0.0:
				rake_cd = RAKE_COOLDOWN
				transition_to(State.RAKE)
			elif d > RIPPLE_MIN and d < RIPPLE_MAX and ripple_cd <= 0.0:
				ripple_cd = RIPPLE_COOLDOWN
				transition_to(State.RIPPLE)

		State.RAKE:
			state_t -= delta
			if state_t > 0.0:
				rake_swing = -rake_side * clampf(1.0 - state_t / RAKE_WARN, 0.0, 1.0)
			else:
				if not rake_struck:
					_strike_rake(RAKE_REACH)
				var k := clampf(-state_t / RAKE_STRIKE, 0.0, 1.0)
				rake_swing = lerpf(-rake_side, rake_side, k)
				if k >= 1.0:
					rake_swing = 0.0
					transition_to(State.STALK)

		State.RIPPLE:
			state_t -= delta
			if state_t <= 0.0:
				_tick_ripple(delta)
				if ripple_at() >= RIPPLE_LEN:
					if not ripple_hit and dog_p.distance_to(ripple_from) < RIPPLE_LEN + 60.0 and hp > 0.0:
						_dodged(dog_p)
					transition_to(State.STALK)

		State.BOUND:
			_turn_to(perch, delta * 3.0)
			_step_to(perch, BOUND_SPEED, delta)
			hop_z = absf(sin(act_t * 7.0)) * 16.0
			if fmod(act_t, 0.1) < delta:
				_burst(pos - face_dir * 40.0, 2, DUST, 30.0, 90.0, 5.0, 0.5)
			if check_trip():
				_hit("trip")
				return
			if check_bowled():
				_bowl()
				hop_z = 0.0
				transition_to(State.STUNNED)
				bowled_this = true
				return
			if pos.distance_to(perch) < 6.0 or act_t > BOUND_MAX:
				hop_z = 0.0
				transition_to(State.GAZE_WARN)

		State.GAZE_WARN:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.GAZE)

		State.GAZE:
			state_t -= delta
			_tick_gaze()
			if state_t <= 0.0:
				_end_gaze()

		State.SPENT, State.STUNNED:
			state_t -= delta
			if not bowled_this and check_bowled():
				bowled_this = true
				_bowl()
			if not kissed_this and dog_p.distance_to(rear()) < KISS_REACH:
				_kiss()
			if state_t <= 0.0:
				transition_to(State.STALK)

		State.RETREAT:
			pos = pos.move_toward(COLUMN, RETREAT_SPEED * delta)
			_turn_to(COLUMN + (COLUMN - pos), delta)
			hop_z = move_toward(hop_z, 0.0, 60.0 * delta)
			update_leg_positions()
			if pos.distance_to(COLUMN) < 1.0:
				transition_to(State.STAND)

		State.STAND:
			_tick_last_stand(delta, dog_p)
			update_leg_tangle()

		State.WRAPPED:
			state_t -= delta
			if state_t <= 0.0:
				rake_swing = 0.0
				transition_to(State.SAT)

	if not main.auto_walk and state in [State.STALK, State.RAKE, State.RIPPLE, State.BOUND,
			State.GAZE_WARN, State.GAZE, State.SPENT, State.STUNNED, State.ENRAGE]:
		_shove_out(main.dog)
		if not main.human.is_whirling():
			_shove_out(main.human)


# a step over the square, round the column and never past her bounds
func _step_to(want: Vector2, spd: float, delta: float) -> void:
	want = want.clamp(Vector2(ARENA_L, ARENA_TOP), Vector2(ARENA_R, ARENA_BOT))
	var to := want - pos
	if to.length() < 1.0:
		return
	var dir := to.normalized()
	var off := pos - COLUMN
	# headed into the column, she goes along its side instead
	if off.length() < COLUMN_CLEAR + 12.0 and dir.dot(off) < 0.0:
		var n := off.normalized() if off.length() > 1.0 else Vector2.UP
		var along := n.orthogonal()
		dir = along if along.dot(dir) >= 0.0 else -along
	pos += dir * minf(spd * delta, to.length())
	off = pos - COLUMN
	if off.length() < COLUMN_CLEAR:
		pos = COLUMN + (off.normalized() if off.length() > 1.0 else Vector2.UP) * COLUMN_CLEAR
	update_leg_positions()


func _turn_to(p: Vector2, delta: float) -> void:
	var want := p - pos
	if want.length() < 1.0:
		return
	var a := face_dir.angle()
	var d := wrapf(want.angle() - a, -PI, PI)
	face_dir = Vector2.from_angle(a + clampf(d, -TURN_RATE * delta, TURN_RATE * delta))


func _tick_last_stand(delta: float, dog_p: Vector2) -> void:
	_turn_to(dog_p, delta)
	if act_t < 0.2:
		return
	last_rake_cd -= delta
	if last_rake_cd <= RAKE_WARN and last_rake_cd + delta > RAKE_WARN:
		if dog_p.distance_to(pos) < LAST_RAKE_REACH + 80.0:
			rake_dir = face_dir
			rake_side = -rake_side
		else:
			last_rake_cd = LAST_RAKE_EVERY
	if last_rake_cd <= RAKE_WARN and last_rake_cd > 0.0:
		rake_swing = -rake_side * (1.0 - last_rake_cd / RAKE_WARN)
	elif last_rake_cd <= 0.0:
		_strike_rake(LAST_RAKE_REACH)
		rake_swing = rake_side
		last_rake_cd = LAST_RAKE_EVERY
	else:
		rake_swing = move_toward(rake_swing, 0.0, delta * 4.0)


# true while the last stand's rake is telegraphed
func last_rake_warning() -> bool:
	return state == State.STAND and last_rake_cd <= RAKE_WARN and last_rake_cd > 0.0


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
	if not main.auto_walk:
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
	for i in range(rings.size() - 1, -1, -1):
		rings[i].life -= delta
		if rings[i].life <= 0.0:
			rings.remove_at(i)
	for i in range(cracks.size() - 1, -1, -1):
		cracks[i].life -= delta
		if cracks[i].life <= 0.0:
			cracks.remove_at(i)
	for i in range(bits.size() - 1, -1, -1):
		var b: Dictionary = bits[i]
		b.life -= delta
		if b.life <= 0.0:
			bits.remove_at(i)
			continue
		b.p += b.v * delta
		b.v *= exp(-1.5 * delta)
		if b.vz != 0.0 or b.z > 0.0:
			b.vz -= 900.0 * delta
			b.z = maxf(0.0, b.z + b.vz * delta)
			if b.z <= 0.0:
				b.vz = 0.0
	if card_t >= 0.0:
		card_t += delta
		if card_t > CARD_TIME + CARD_FROM:
			card_t = -1.0
	if card != null and is_instance_valid(card):
		card.queue_redraw()
	var want := 0.0
	var mid: float = (main.dog.global_position.y + main.human.global_position.y) * 0.5
	match state:
		State.IDLE:
			pass
		State.AWAKEN:
			want = (pos.y - mid) * 0.55
		State.SAT, State.CONTENT:
			if act_t < 2.5:
				want = (pos.y - mid) * 0.35
		_:
			want = (pos.y - mid) * 0.3
	want = clampf(want, -LEAN_MAX, LEAN_MAX)
	lean = lerpf(lean, want, 1.0 - exp(-LEAN_EASE * delta))


func on_bark_action(bark_pos: Vector2) -> bool:
	var dog_p: Vector2 = main.dog.global_position
	var near := bark_pos.distance_to(nose()) < BOOP_REACH or dog_p.distance_to(nose()) < BOOP_REACH
	if state == State.SAT and (near or dog_p.distance_to(pos) < 120.0):
		Sfx.bark(1.25)
		transition_to(State.CONTENT)
		return true
	if weak() and not booped_this and near:
		booped_this = true
		damage(BOOP_DAMAGE)
		main.lleona_booped = true
		main.combo.add("BOOP", 3)
		main.float_text(nose(), I18n.t("w_boop_3"), Color(1.0, 0.88, 0.25))
		return true
	return false


# --- The banner --------------------------------------------------------------

func status() -> String:
	var fight := fight_status()
	if fight != "":
		return fight
	if in_fight() and main.human.tut_hold_y == HOLD_Y \
			and main.human.global_position.y < HOLD_Y + 40.0:
		return I18n.t("boss_lleona_block")
	return ""


func fight_status() -> String:
	var near: bool = main.dog.global_position.distance_to(pos) < 700.0
	match state:
		State.RAKE:
			return I18n.t("boss_lleona_rake") if near else ""
		State.RIPPLE:
			return I18n.t("boss_lleona_ripple") if near else ""
		State.BOUND, State.GAZE_WARN, State.GAZE:
			return I18n.t("boss_lleona_gaze") if near else ""
		State.SPENT, State.STUNNED:
			return Prompts.fill(I18n.t("boss_lleona_spent")) if near else ""
		State.ENRAGE:
			return I18n.t("boss_lleona_furious") if near else ""
		State.RETREAT:
			return I18n.t("boss_lleona_retreat")
		State.STAND:
			if last_rake_warning():
				return I18n.t("boss_lleona_rake")
			return I18n.t("boss_lleona_legs") % [legs_tied, LEGS_TO_TIE]
		State.SAT:
			return Prompts.fill(I18n.t("boss_lleona_down"))
		State.STALK:
			if near and spout_warning():
				return I18n.t("boss_lleona_spout")
	return ""


func hush_banner() -> bool:
	return card_t >= CARD_FROM and card_t <= CARD_TIME + CARD_FROM


# --- The title card ----------------------------------------------------------

static func _flashes_on() -> bool:
	var ml := Engine.get_main_loop()
	var gm: Node = ml.root.get_node_or_null("Game") if ml != null and ml is SceneTree else null
	return true if gm == null else bool(gm.flashes)


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
	if screen_flash > 0.0 and _flashes_on():
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
	card.draw_rect(band, Color(0.06, 0.06, 0.08, 0.82))
	card.draw_rect(Rect2(band.position, Vector2(vs.x, 5.0 * u)), STONE_LIT)
	card.draw_rect(Rect2(band.position + Vector2(0.0, band.size.y - 5.0 * u), Vector2(vs.x, 5.0 * u)), STONE_LIT)
	Kit.heading(card, Vector2(slide, cy - 34.0 * u), "GIRONA", int(18.0 * u), Color(0.80, 0.78, 0.72),
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	Kit.heading(card, Vector2(slide, cy + 18.0 * u), "LA LLEONA", int(52.0 * u), STONE_LIT,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	var gloss := I18n.t("w_the_stone_lioness_and_she_is")
	var gs := int(20.0 * u)
	var gw: float = Kit.text_w(Kit.body(), gloss, gs)
	card.draw_string(Kit.body(), Vector2(slide + (vs.x - gw) * 0.5, cy + 46.0 * u), gloss,
		HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Color(0.92, 0.88, 0.80))


# --- Drawing -----------------------------------------------------------------

func draw(b: ShapeBatch, vt: float, vb: float, t: float) -> void:
	_draw_planters(b)
	_draw_cracks(b, vt, vb)
	_draw_spout(b, t)
	if in_fight() or cheer > 0.0:
		_draw_crowd(b, vt, vb, t)
	_draw_warnings(b, t)
	if pos.y > vt - 200.0 and pos.y < vb + 200.0:
		_draw_lioness(b, t)
	_draw_rings(b, t)
	_draw_bits(b, vt, vb)
	_draw_health_bar(b)


# Temps de Flors' stone planters, flowers spilling over; looked at, they are
# grey rubble in their own footprint
func _draw_planters(b: ShapeBatch) -> void:
	for k in range(PLANTERS.size()):
		var r := PLANTERS[k]
		var c := r.get_center()
		b.rect(Rect2(r.position + Shade.light * 9.0, r.size), SHADOW)
		b.rect(r, STONE_DARK)
		if planters_up[k]:
			b.rect(r.grow(-2.0), STONE)
			b.rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4.0, 4.0)), STONE_LIT)
			b.rect(r.grow(-8.0), Color(0.22, 0.17, 0.13))
			for i in range(13):
				var a := float(i) * 2.4
				var p := c + Vector2(cos(a) * 20.0, sin(a) * 15.0) * sqrt(float(i + 1) / 13.0)
				b.circle(p, 6.0, Color(0.20, 0.40, 0.24))
				b.circle(p + Vector2(-1.0, -1.5), 3.6, PETALS[i % 3])
		else:
			b.rect(r.grow(-3.0), Color(0.36, 0.34, 0.32))
			for i in range(11):
				var p := r.position + Vector2(8.0 + fposmod(float(i) * 17.3, r.size.x - 16.0), 8.0 + fposmod(float(i) * 11.7, r.size.y - 16.0))
				b.circle(p + Shade.light * 2.0, 6.0, SHADOW)
				b.circle(p, 4.0 + float(i % 3) * 1.4, STONE.darkened(0.12 * float(i % 4)))


func _draw_cracks(b: ShapeBatch, vt: float, vb: float) -> void:
	for cr: Dictionary in cracks:
		var p: Vector2 = cr.p
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		var a := clampf(float(cr.life) / 1.5, 0.0, 1.0)
		for i in range(4):
			var d := Vector2.from_angle(float(cr.a) + float(i) * TAU / 4.0)
			b.line(p + d * 3.0, p + d * (14.0 + float(i % 2) * 9.0), Color(0.14, 0.13, 0.15, 0.6 * a), 2.0)


func _draw_spout(b: ShapeBatch, t: float) -> void:
	# the gargoyle on the Basílica's wall, its mouth over the ring
	var g := Vector2(944.0, SPOUT_AT.y)
	b.capsule(g, g + Vector2(-26.0, 0.0), 8.0, STONE_DARK)
	b.capsule(g, g + Vector2(-24.0, -1.0), 5.5, STONE)
	b.circle(g + Vector2(-27.0, 0.0), 9.0, STONE_DARK)
	b.circle(g + Vector2(-27.0, -1.0), 7.0, STONE)
	b.circle(g + Vector2(-31.0, 1.0), 3.0, Color(0.12, 0.14, 0.18))
	# the worn basin in the paving under it
	b.ellipse(SPOUT_AT, 30.0, 22.0, Color(0.16, 0.20, 0.26, 0.45))
	if spout_warning():
		var k := 1.0 - clampf(spout_t / SPOUT_WARN, 0.0, 1.0)
		b.circle(SPOUT_AT, SPOUT_R * k, Color(0.45, 0.78, 1.0, 0.22))
		_ring(b, SPOUT_AT, SPOUT_R, Color(0.70, 0.90, 1.0, 0.45 + 0.4 * k), 3.0)
	elif spout_pouring:
		b.glow(SPOUT_AT, SPOUT_R + 14.0, Color(0.62, 0.84, 1.0, 0.65), 0.5)
		b.quad(g + Vector2(-27.0, -6.0), g + Vector2(-27.0, 6.0), SPOUT_AT + Vector2(0.0, 22.0), SPOUT_AT + Vector2(0.0, -22.0), WATER)
		for i in range(3):
			_ring(b, SPOUT_AT, 14.0 + fposmod(t * 60.0 + float(i) * 16.0, 48.0), Color(0.92, 0.98, 1.0, 0.5), 2.0)


func _draw_crowd(b: ShapeBatch, vt: float, vb: float, t: float) -> void:
	var raining: bool = Game.weather == "rain"
	for pp: Dictionary in crowd:
		var p: Vector2 = pp.p
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var coat: Color = pp.coat
		var jump := absf(sin(t * 9.0 + float(pp.ph))) * 7.0 * cheer
		var at := p + Vector2(signf(p.x - pos.x) * gasp * 4.0, -jump)
		b.circle(p + Shade.light * 3.0, 9.0, SHADOW)
		if cheer > 0.3 or gasp > 0.5:
			for sd: float in [-1.0, 1.0]:
				var hand := at + Vector2(sd * 9.0, -(14.0 if cheer > 0.3 else 9.0))
				b.line(at + Vector2(sd * 6.0, -2.0), hand, coat, 4.0)
				b.circle(hand, 2.6, pp.skin)
		b.circle(at, 9.0, coat.darkened(0.25))
		b.circle(at - Shade.light * 1.2, 7.6, coat)
		if raining and bool(pp.brolly) and cheer <= 0.3:
			b.circle(at + Vector2(0.0, -3.0), 14.0, coat.darkened(0.2))
			b.circle(at + Vector2(-3.0, -6.0), 6.0, coat.lightened(0.18))
			continue
		b.circle(at + Vector2(0.0, -2.0), 5.4, pp.skin)
		b.circle(at + Vector2(0.0, -3.4), 4.6, Color(0.20, 0.14, 0.10))


# The telegraphs, drawn on the ground under her: the rake's sector, the
# ripple's lane, and for the gaze the whole sector it will cross, the beam in
# it, and the shadow of each thing to hide behind.
func _draw_warnings(b: ShapeBatch, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 14.0)
	if (state == State.RAKE and state_t > 0.0) or last_rake_warning():
		var fill := 1.0 - (state_t if state == State.RAKE else last_rake_cd) / RAKE_WARN
		var reach := RAKE_REACH if state == State.RAKE else LAST_RAKE_REACH
		var a0 := rake_dir.angle() - RAKE_HALF
		var pts := PackedVector2Array([pos])
		var inner := PackedVector2Array([pos])
		for i in range(13):
			var d := Vector2.from_angle(a0 + RAKE_HALF * 2.0 * float(i) / 12.0)
			pts.append(pos + d * reach)
			inner.append(pos + d * reach * clampf(fill, 0.02, 1.0))
		b.polygon(pts, Color(WARN.r, WARN.g, WARN.b, 0.10 + 0.08 * pulse))
		b.polygon(inner, Color(WARN.r, WARN.g, WARN.b, 0.22))
		for i in range(1, 13):
			b.line(pts[i], pts[i + 1], Color(1.0, 0.45, 0.28, 0.8), 3.0)
		b.line(pos, pts[1], Color(1.0, 0.45, 0.28, 0.6), 2.0)
		b.line(pos, pts[13], Color(1.0, 0.45, 0.28, 0.6), 2.0)
	if state == State.RIPPLE:
		var side := ripple_dir.orthogonal() * RIPPLE_W * 0.5
		var end := ripple_from + ripple_dir * RIPPLE_LEN
		if state_t > 0.0:
			var k := 1.0 - clampf(state_t / RIPPLE_WARN, 0.0, 1.0)
			b.line(ripple_from, end, Color(WARN.r, WARN.g, WARN.b, 0.14 + 0.08 * pulse), RIPPLE_W)
			b.line(ripple_from, ripple_from.lerp(end, maxf(k, 0.02)), Color(WARN.r, WARN.g, WARN.b, 0.24), RIPPLE_W)
			b.line(ripple_from + side, end + side, Color(1.0, 0.45, 0.28, 0.7), 2.0)
			b.line(ripple_from - side, end - side, Color(1.0, 0.45, 0.28, 0.7), 2.0)
		else:
			# slabs thrown up in a row, highest at the head
			var now := minf(ripple_at(), RIPPLE_LEN)
			for i in range(5):
				var along := now - float(i) * 24.0
				if along < 0.0:
					continue
				var c := ripple_from + ripple_dir * along
				var lift := Vector2(0.0, -20.0 * (1.0 - float(i) / 5.0))
				var f := ripple_dir * 10.0
				b.quad(c - side - f, c + side - f, c + side + f, c - side + f, Color(0.08, 0.08, 0.10, 0.5))
				b.quad(c - side - f + lift, c - f + lift, c + f + lift * 0.7, c - side + f + lift * 0.7, STONE.darkened(0.15))
				b.quad(c - f + lift * 0.8, c + side - f + lift * 0.8, c + side + f + lift * 0.5, c + f + lift * 0.5, STONE.darkened(0.28))
	if state == State.GAZE_WARN or state == State.GAZE:
		_draw_gaze(b, pulse)


func _draw_gaze(b: ShapeBatch, pulse: float) -> void:
	var from := eye()
	var mid := gaze_mid.angle()
	# what it will cross, soft
	_fan(b, from, mid - GAZE_SPAN, mid + GAZE_SPAN, 40, Color(GAZE_COL.r, GAZE_COL.g, GAZE_COL.b, 0.16 + 0.05 * pulse))
	# safe ground: the shadow behind each cover
	for r: Rect2 in covers():
		_draw_safe(b, from, r, pulse)
	var a := gaze_angle()
	if state == State.GAZE_WARN:
		# where it starts and which way it will go
		var k := 1.0 - clampf(state_t / GAZE_WARN, 0.0, 1.0)
		for i in range(5):
			var ca := a + gaze_side * (0.12 + float(i) * 0.13)
			var tip := from + Vector2.from_angle(ca) * 150.0
			var dir := Vector2.from_angle(ca + gaze_side * PI * 0.5)
			var n := dir.orthogonal()
			var col := Color(1.0, 0.92, 0.66, 0.85 if k * 5.0 > float(i) else 0.2)
			b.line(tip - dir * 10.0 + n * 8.0, tip, col, 3.0)
			b.line(tip - dir * 10.0 - n * 8.0, tip, col, 3.0)
		b.glow(from, 30.0 + 40.0 * k, Color(1.0, 0.84, 0.36, 0.7))
	else:
		_fan(b, from, a - GAZE_HALF, a + GAZE_HALF, 12, Color(1.0, 0.84, 0.40, 0.70))
		b.line(from, from + Vector2.from_angle(a) * _ray(from, a), Color(1.0, 0.96, 0.78, 0.55), 3.0)
		b.glow(from, 64.0, Color(1.0, 0.90, 0.52, 0.8))


# how far the gaze goes at this angle before something stops it
func _ray(from: Vector2, a: float) -> float:
	var to := from + Vector2.from_angle(a) * GAZE_REACH
	var k := 1.0
	for r: Rect2 in covers():
		k = minf(k, _meets(from, to, r))
	return GAZE_REACH * k


# a fan of light from `from`, cut where cover stops it, fading with distance
func _fan(b: ShapeBatch, from: Vector2, a0: float, a1: float, n: int, col: Color) -> void:
	var rows := 5
	var pts := PackedVector2Array()
	var alphas := PackedFloat32Array()
	var reach := PackedFloat32Array()
	for i in range(n):
		reach.append(_ray(from, lerpf(a0, a1, float(i) / float(n - 1))))
	for r in range(rows):
		var u := float(r) / float(rows - 1)
		alphas.append(1.0 - u * u)
		for i in range(n):
			var a := lerpf(a0, a1, float(i) / float(n - 1))
			pts.append(from + Vector2.from_angle(a) * minf(GAZE_REACH * u, reach[i]))
	b.band(pts, n, col, alphas)


func _draw_safe(b: ShapeBatch, from: Vector2, r: Rect2, pulse: float) -> void:
	var c := r.get_center()
	var near := from.distance_to(c)
	if near > GAZE_REACH - 60.0:
		return
	var ca := (c - from).angle()
	var lo := 0.0
	var hi := 0.0
	for q: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var d := wrapf((q - from).angle() - ca, -PI, PI)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	var pts := PackedVector2Array()
	for dist: float in [near, near + 60.0, near + 130.0]:
		for i in range(4):
			pts.append(from + Vector2.from_angle(ca + lerpf(lo, hi, float(i) / 3.0)) * dist)
	b.band(pts, 4, Color(SAFE.r, SAFE.g, SAFE.b, 0.34 + 0.14 * pulse), PackedFloat32Array([1.0, 0.8, 0.0]))


func _draw_lioness(b: ShapeBatch, t: float) -> void:
	var statue := state in [State.IDLE, State.CONTENT, State.STAND, State.WRAPPED]
	var sc := STATUE_SCALE if statue else 1.0
	if state == State.AWAKEN:
		sc = lerpf(STATUE_SCALE, 1.0, clampf((act_t - AWAKEN_LEAP) / 0.6, 0.0, 1.0))
	var at := pos
	if state == State.WRAPPED:
		at.x += sin(act_t * 14.0) * (3.0 + clampf(act_t / WOBBLE_TIME, 0.0, 1.0) * 10.0)
	elif weak():
		at.x += sin(t * 9.0) * 2.0
	elif state == State.AWAKEN and act_t < AWAKEN_LEAP:
		at.x += sin(t * 50.0) * 1.2
	var f := face_dir
	var s := f.orthogonal()
	var awake := state != State.IDLE and state != State.CONTENT
	var c := at - Vector2(0.0, hop_z)
	var stone := STONE.lerp(Color.WHITE, (flash if _flashes_on() else 0.0) * 0.5)
	b.polygon(_ellipse(at + Shade.light * (12.0 + hop_z * 0.5), f, 66.0 * sc, 40.0 * sc, 20), SHADOW)
	if statue:
		# the column's capital under her, so she is seen to be up on it
		var cap := COLUMN_RECT.grow(15.0)
		b.polygon(PackedVector2Array([cap.position, Vector2(cap.end.x, cap.position.y), Vector2(cap.end.x, cap.position.y) + Shade.light * 34.0,
			cap.end + Shade.light * 34.0, Vector2(cap.position.x, cap.end.y) + Shade.light * 34.0, Vector2(cap.position.x, cap.end.y)]), SHADOW)
		b.rect(cap, STONE_DARK)
		b.rect(cap.grow(-2.5), STONE.darkened(0.10))
		b.rect(cap.grow(-9.0), STONE.darkened(0.22))
	var walking := state in [State.STALK, State.RETREAT, State.BOUND]
	# the tail: a carved rope with a leaf for a tuft, curling over her back
	var tp := c - f * 50.0 * sc
	var ta := f.angle() + PI
	var sway := sin(t * 2.2) * 0.10 if awake else 0.0
	for i in range(8):
		var nx := tp + Vector2.from_angle(ta) * 8.0 * sc
		b.capsule(tp, nx, (4.6 - float(i) * 0.2) * sc, STONE_DARK)
		b.capsule(tp, nx, (3.0 - float(i) * 0.15) * sc, stone)
		ta += 0.26 + sway
		tp = nx
	b.circle(tp, 8.0 * sc, STONE_DARK)
	b.circle(tp, 6.0 * sc, stone.darkened(0.06))
	# the paws, under the body; the raking one swings out in front
	for k in range(4):
		var o := LEG_OFFSETS[k]
		var lp := c + o.rotated(f.angle() - PI * 0.5) * sc
		if walking:
			lp += f * sin(t * 7.0 + (PI if k == 1 or k == 2 else 0.0)) * 8.0
		if k >= 2 and rake_swing != 0.0 and (o.x < 0.0) == (rake_side < 0.0):
			lp = c + f.rotated(rake_swing * 0.8) * 78.0
			b.capsule(c + f * 22.0, lp, 11.0, STONE_DARK)
			b.capsule(c + f * 22.0, lp, 8.5, stone)
		b.circle(lp, LEG_RADIUS * sc, STONE_DARK)
		b.circle(lp - Shade.light * 1.6, (LEG_RADIUS - 3.0) * sc, stone.darkened(0.08))
		for n in range(3):
			var toe := lp + f * 12.0 * sc + s * (float(n) - 1.0) * 6.5 * sc
			b.circle(toe, 3.6 * sc, STONE_DARK)
			b.circle(toe - f * 0.8, 2.4 * sc, STONE_LIT)
	# haunches, ribs, shoulders: three blocks, as a mason would cut her
	var spine: Array = [[-30.0, 36.0, 33.0], [0.0, 36.0, 27.0], [24.0, 32.0, 31.0]]
	for sp: Array in spine:
		b.polygon(_ellipse(c + f * float(sp[0]) * sc, f, float(sp[1]) * sc, float(sp[2]) * sc, 20), STONE_DARK)
	for sp: Array in spine:
		b.polygon(_ellipse(c + f * float(sp[0]) * sc, f, (float(sp[1]) - 2.5) * sc, (float(sp[2]) - 2.5) * sc, 20), stone)
	for sp: Array in spine:
		b.polygon(_ellipse(c + (f * float(sp[0]) - Shade.light * 5.0) * sc, f, float(sp[1]) * 0.62 * sc, float(sp[2]) * 0.58 * sc, 16), STONE_LIT.lerp(stone, 0.45))
	# the carved hair: rows of shallow curls down her flanks, worn at the back
	for j in range(6):
		var along := (-34.0 + float(j) * 12.0) * sc
		for sd: float in [-1.0, 1.0]:
			var p0 := c + f * along + s * sd * 8.0 * sc
			var p1 := p0 + s * sd * 13.0 * sc - f * 5.0 * sc
			b.line(p0, p1, CARVE, 1.8)
			b.line(p1, p1 + s * sd * 2.0 * sc + f * 6.0 * sc, CARVE, 1.8)
	b.line(c - f * 46.0 * sc, c + f * 34.0 * sc, STONE_LIT, 3.5 * sc)
	for cr: Array in [[-38.0, 10.0, -22.0, 20.0], [8.0, -20.0, 20.0, -10.0], [-10.0, -6.0, -4.0, -18.0]]:
		b.line(c + (f * float(cr[0]) + s * float(cr[1])) * sc, c + (f * float(cr[2]) + s * float(cr[3])) * sc, Color(0.30, 0.27, 0.24, 0.7), 1.5)
	# the head: round ears, a heavy brow, a blunt muzzle, and the ruff of stone
	# curls that has the town arguing whether she is a lion
	var hd := c + f * 46.0 * sc
	for i in range(9):
		var a := f.angle() + PI + (float(i) - 4.0) * 0.36
		b.circle(hd + Vector2.from_angle(a) * 21.0 * sc, 8.0 * sc, STONE_DARK)
		b.circle(hd + Vector2.from_angle(a) * 20.0 * sc, 6.0 * sc, stone.darkened(0.10))
	for sd: float in [-1.0, 1.0]:
		var ear := hd + (s * sd * 19.0 - f * 8.0) * sc
		b.circle(ear, 8.0 * sc, STONE_DARK)
		b.circle(ear, 5.5 * sc, stone)
		b.circle(ear + f * sc, 2.8 * sc, CARVE)
	b.circle(hd, 23.0 * sc, STONE_DARK)
	b.circle(hd, 20.5 * sc, stone)
	b.circle(hd - (f * 5.0 + Shade.light * 3.0) * sc, 12.0 * sc, STONE_LIT.lerp(stone, 0.3))
	var roaring := (state == State.AWAKEN and act_t > AWAKEN_ROAR and act_t < AWAKEN_LEAP) or state == State.ENRAGE
	if roaring:
		b.polygon(_ellipse(hd + f * 24.0 * sc, f, 11.0 * sc, 13.0 * sc, 14), Color(0.16, 0.10, 0.09))
		for sd: float in [-1.0, 1.0]:
			b.line(hd + (f * 18.0 + s * sd * 7.0) * sc, hd + (f * 25.0 + s * sd * 6.0) * sc, STONE_LIT, 3.0)
			b.line(hd + (f * 33.0 + s * sd * 6.0) * sc, hd + (f * 27.0 + s * sd * 5.0) * sc, STONE_LIT, 3.0)
	for sd: float in [-1.0, 1.0]:
		b.circle(hd + (f * 15.0 + s * sd * 6.0) * sc, 8.5 * sc, STONE_DARK)
		b.circle(hd + (f * 15.0 + s * sd * 6.0) * sc, 7.0 * sc, stone.lightened(0.06))
	var ns := hd + f * 20.0 * sc
	b.polygon(PackedVector2Array([ns - s * 5.0 * sc, ns + s * 5.0 * sc, ns + f * 5.0 * sc]), Color(0.30, 0.24, 0.21))
	for sd: float in [-1.0, 1.0]:
		var ep := hd + (f * 3.0 + s * sd * 10.0) * sc
		if weak():
			b.line(ep - f * 3.5 - s * 3.5, ep + f * 3.5 + s * 3.5, Color(0.28, 0.20, 0.16), 2.0)
			b.line(ep - f * 3.5 + s * 3.5, ep + f * 3.5 - s * 3.5, Color(0.28, 0.20, 0.16), 2.0)
		elif awake and not (state == State.AWAKEN and act_t < AWAKEN_EYES) and state != State.SAT:
			var ec := EYE_RED if enraged and hp > 0.0 else EYE_GOLD
			if state == State.GAZE or state == State.GAZE_WARN:
				ec = Color(1.0, 0.94, 0.62)
				b.glow(ep, 14.0, Color(1.0, 0.85, 0.40, 0.8))
			b.circle(ep, 5.2 * sc, Color(0.14, 0.10, 0.08))
			b.circle(ep + f * 0.8, 3.8 * sc, ec)
			b.line(ep - s * 1.2 * sc + f * 0.8, ep + s * 1.2 * sc + f * 0.8, Color(0.10, 0.06, 0.04), 1.6)
			# the brow comes down over the eye, so she glares
			b.line(ep + (s * sd * 6.0 - f * 5.0) * sc, ep + (-s * sd * 5.0 - f * 1.0) * sc, STONE_DARK, 3.0 * sc)
		else:
			b.line(ep - s * 4.0 * sc, ep + s * 4.0 * sc, Color(0.34, 0.28, 0.24), 2.0)
	if weak() or state == State.SAT:
		for i in range(4):
			var a := t * 3.0 + float(i) * TAU / 4.0
			b.circle(hd + Vector2(cos(a) * 30.0, sin(a) * 12.0) - Vector2(0.0, 34.0), 4.0, Color(1.0, 0.92, 0.40))
	if weak() and not kissed_this:
		# where the town kisses her: a heart over the tail
		var hp_ := rear() - Vector2(0.0, 16.0 + 3.0 * sin(t * 6.0))
		for sd: float in [-1.0, 1.0]:
			b.circle(hp_ + Vector2(sd * 4.5, -3.0), 5.4, Color(1.0, 0.42, 0.56))
		b.polygon(PackedVector2Array([hp_ + Vector2(-9.4, -1.0), hp_ + Vector2(9.4, -1.0), hp_ + Vector2(0.0, 10.0)]), Color(1.0, 0.42, 0.56))


func _draw_rings(b: ShapeBatch, t: float) -> void:
	for dr: Dictionary in rings:
		var frac: float = 1.0 - float(dr.life) / maxf(float(dr.max), 0.01)
		_ring(b, dr.pos, float(dr.r) * (0.3 + frac * 0.7), Color(DUST.r, DUST.g, DUST.b, (1.0 - frac) * 0.6), 4.0)
	if state == State.STAND:
		_ring(b, pos, 92.0, Color(0.98, 0.85, 0.30, 0.35 + sin(t * 8.0) * 0.15), 3.0)
	if state == State.STAND or state == State.WRAPPED:
		for k in range(leg_poles.size()):
			if main.elapsed - leg_touch_t[k] <= LEG_MEMORY or state == State.WRAPPED:
				_ring(b, leg_poles[k], LEG_RADIUS + 6.0, Color(1.0, 0.90, 0.20, 0.9), 3.0)


func _draw_bits(b: ShapeBatch, vt: float, vb: float) -> void:
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
				b.circle(p + Shade.light * 2.0, float(bt.r) * 0.8, SHADOW)
			b.circle(at, float(bt.r) * (0.5 + f * 0.5), col)


# The plate's top-left, pushed down below the HUD banner when it is over her
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


func _draw_health_bar(c: Object) -> void:
	if state == State.IDLE or state == State.AWAKEN or hp <= 0.0:
		return
	var bar_w := 160.0
	var bar_h := 10.0
	var bp := _below_banner(pos + Vector2(-bar_w * 0.5, -112.0 - hop_z), 24.0)
	c.draw_rect(Rect2(bp + Shade.light * 3.0, Vector2(bar_w, bar_h)), SHADOW)
	c.draw_rect(Rect2(bp - Vector2(2.0, 2.0), Vector2(bar_w + 4.0, bar_h + 4.0)), STONE_DARK)
	c.draw_rect(Rect2(bp - Vector2(1.0, 1.0), Vector2(bar_w + 2.0, bar_h + 2.0)), STONE_LIT)
	c.draw_rect(Rect2(bp, Vector2(bar_w, bar_h)), Color(0.10, 0.09, 0.08))
	var fc := Color(0.96, 0.32, 0.22) if phase == 2 else Color(0.96, 0.74, 0.18)
	fc = fc.lerp(Color.WHITE, (flash if _flashes_on() else 0.0) * 0.7)
	var fill := Rect2(bp + Vector2(1, 1), Vector2((bar_w - 2.0) * clampf(hp / max_hp, 0.0, 1.0), bar_h - 2.0))
	c.draw_rect(fill, fc)
	c.draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), fc.lightened(0.35))
	c.draw_rect(Rect2(bp + Vector2(bar_w * 0.5 - 1.0, -2.0), Vector2(2.0, bar_h + 4.0)), STONE_DARK)
	var fnt: Font = Kit.display()
	var tp := bp + Vector2((bar_w - Kit.text_w(fnt, "LA LLEONA", 14)) * 0.5, -5.0)
	c.draw_string_outline(fnt, tp, "LA LLEONA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0.05, 0.04, 0.04, 0.85))
	c.draw_string(fnt, tp, "LA LLEONA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, STONE_LIT)


static func _ring(b: ShapeBatch, c: Vector2, r: float, col: Color, w: float) -> void:
	var prev := c + Vector2(r, 0.0)
	for i in range(1, 29):
		var cur := c + Vector2.from_angle(TAU * float(i) / 28.0) * r
		b.line(prev, cur, col, w)
		prev = cur


static func _ellipse(c: Vector2, f: Vector2, rf: float, rs: float, n: int) -> PackedVector2Array:
	var s := f.orthogonal()
	var out := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		out.append(c + f * cos(a) * rf + s * sin(a) * rs)
	return out
