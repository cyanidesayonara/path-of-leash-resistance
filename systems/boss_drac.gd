class_name BossDrac
extends RefCounted

# EL DRAC, El Mosaic's salamander boss: asleep on the fountain stair until
# she wakes him. He climbs off the plinth under a title card; your human will
# not walk past that dragon. Part one: tail whip and fountain jet. Part two:
# enrage, an S-curve slither through the hypostyle hall (mud chips, column
# bind, leash trip). No separate charge — the mammoth owns that.

const LevelBuild := preload("res://world/level_build.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Kit := preload("res://hud/ui_kit.gd")
const Surfaces := preload("res://world/surfaces.gd")

const PLINTH := LevelBuild.MOSAIC_SALAMANDER
# a short step down the stair off the fountain toward the pair
const LANDING := Vector2(640.0, -850.0)
const HOLD_Y := -780.0
const WAKE_Y := -860.0
const MAX_HP := 100.0
const FILM := "res://intro/film_drac.gd"
const FILM_WIN := "res://intro/film_drac_win.gd"
const LEG_OFFSETS: Array[Vector2] = [
	Vector2(-28.0, -36.0), Vector2(28.0, -36.0),
	Vector2(-28.0, 36.0), Vector2(28.0, 36.0),
]
const LEG_RADIUS := 16.0
const LEG_MEMORY := 1.5
const LEGS_TO_TIE := 3
const AWAKEN_TIME := 2.6
const CARD_TIME := 3.4
const CARD_FROM := 0.3
# part one: the tail whip (Mamut swipe, rear sector)
const TAIL_WARN := 0.8
const TAIL_STRIKE := 0.25
const TAIL_HALF := 0.9
const TAIL_REACH := 160.0
const TAIL_TRIGGER := 180.0
const TAIL_COOLDOWN := 2.4
const REAR_CONE := 1.15
const DODGE_DAMAGE := 12.0
# fountain jet (Mamut spray lane, along face_dir)
const JET_WARN := 0.8
const JET_TIME := 0.55
const JET_LEN := 360.0
const JET_W := 42.0
const JET_COOLDOWN := 2.8
const FRONT_CONE := 1.15
const PUDDLE_LIFE := 4.0
# part two: enrage, slither, column bind, leash trip
const ENRAGE_TIME := 1.7
const SLITHER_TIME := 2.2
const SLITHER_SPEED := 220.0
const SLITHER_COOLDOWN := 3.0
const SLITHER_WAVE := 5.5
const SLITHER_AMP := 70.0
const CHIP_EVERY := 0.18
const CHIP_LIFE := 3.0
const CHIP_HALF := 18.0
const COLUMN_DAMAGE := 25.0
const TRIP_DAMAGE := 25.0
const STUN_TIME := 2.6
const CLOTHESLINE_END_PTS := 3
const HIT_BOX_R := 48.0
# last stand: retreat, wrap legs, belly slide, settling boop
const RETREAT_SPEED := 200.0
const TURN_RATE := 1.6
const BOOP_REACH := 80.0
const WOBBLE_TIME := 1.2
const SLIDE_TIME := 1.4
const LAST_JET_EVERY := 3.6

const DRAC_BLUE := Color(0.18, 0.58, 0.76)
const DRAC_CYAN := Color(0.24, 0.74, 0.82)
const DRAC_GREEN := Color(0.24, 0.70, 0.44)
const DRAC_YELLOW := Color(0.96, 0.84, 0.22)
const DRAC_ORANGE := Color(0.94, 0.52, 0.18)
const DRAC_WHITE := Color(0.94, 0.94, 0.90)
const EYE_AMBER := Color(1.0, 0.78, 0.22)
const EYE_RED := Color(0.96, 0.28, 0.20)
const SHADOW := Color(0.12, 0.10, 0.08, 0.28)

enum State {
	IDLE, AWAKEN, ENRAGE, PROWL, TAIL_WHIP, JET, SLITHER,
	STUNNED, RETREAT, STAND, WRAPPED, SLIDE, CONTENT,
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
var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []
var leg_soft_indices: Array[int] = []
var leg_furniture_indices: Array[int] = []
var leg_touch_t: Array[float] = [-INF, -INF, -INF, -INF]
var legs_tied := 0
var lean := 0.0
var card_t := -1.0
var card: Control = null
var film_shown := false
var win_film_shown := false
var enraged := false
var hold_noticed := false
var tail_cd := 1.0
var jet_cd := 1.0
var ls_jet_cd := LAST_JET_EVERY
var whip_dir := Vector2.UP
var whip_side := 1.0
var whip_struck := false
var jet_struck := false
var slither_cd := 1.0
var slither_from := Vector2.ZERO
var slither_dir := Vector2.RIGHT
var chip_t := 0.0
var fountain_t := -1.0
var flash := 0.0
# puddles / chips: [{ "rect": Rect2, "kind": int, "until": float }]
var surface_zones: Array[Dictionary] = []


func setup(m: Node2D) -> void:
	main = m
	state = State.IDLE
	state_t = 0.0
	act_t = 0.0
	hp = MAX_HP
	max_hp = MAX_HP
	phase = 1
	pos = PLINTH
	face_dir = Vector2.DOWN
	enraged = false
	card_t = -1.0
	lean = 0.0
	film_shown = false
	win_film_shown = false
	hold_noticed = false
	tail_cd = 1.0
	jet_cd = 1.0
	ls_jet_cd = LAST_JET_EVERY
	slither_cd = 1.0
	chip_t = 0.0
	fountain_t = -1.0
	flash = 0.0
	whip_struck = false
	jet_struck = false
	legs_tied = 0
	leg_touch_t = [-INF, -INF, -INF, -INF]
	surface_zones.clear()
	leg_poles.clear()
	for off: Vector2 in LEG_OFFSETS:
		leg_poles.append(pos + off)


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


func in_fight() -> bool:
	return state != State.IDLE and not beaten()


func nose_tip() -> Vector2:
	return pos + face_dir * 70.0


func status() -> String:
	var near: bool = main != null and main.dog.global_position.distance_to(pos) < 600.0
	match state:
		State.TAIL_WHIP:
			return "WATCH THE TAIL!" if near else ""
		State.JET:
			return "WATCH THE JET!" if near else ""
		State.SLITHER:
			return "WIND HIM ROUND A COLUMN" if near else ""
		State.RETREAT:
			return "AFTER HIM! TO HIS STEPS"
		State.STAND:
			if last_jet_warning():
				return "WATCH THE JET!"
			return "WRAP THE LEASH AROUND HIS LEGS  %d/%d" % [legs_tied, LEGS_TO_TIE]
		State.SLIDE:
			return Prompts.fill("HE'S DOWN! {bark} ON HIS NOSE")
	return ""


func hush_banner() -> bool:
	return card_t >= 0.0 and card_t < CARD_FROM + CARD_TIME


func damage(amt: float) -> void:
	var was := hp
	flash = 0.4
	hp = maxf(0.0, hp - amt)
	if hp <= MAX_HP * 0.5 and phase == 1:
		phase = 2
		main.feed.say("EL DRAC IS FURIOUS!", EventFeed.Tone.LOUD)
	if hp <= 0.0 and was > 0.0:
		main.feed.say("HE'S HAD ENOUGH! AFTER HIM", EventFeed.Tone.GOOD)


func in_sector(p: Vector2, dir: Vector2, reach: float, half: float) -> bool:
	var d := p - pos
	if d.length() > reach or d.length() < 1.0:
		return d.length() < 1.0
	return absf(dir.angle_to(d)) <= half


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
			if Sfx.lib.has("drac_click"):
				Sfx.play("drac_click", 1.0, -6.0)
			else:
				Sfx.play("crack", 1.3, -10.0)
			card_t = 0.0
			_ensure_card()
		State.ENRAGE:
			enraged = true
			Sfx.play("crack", 0.7, -4.0)
			main.shake_t = maxf(float(main.shake_t), 0.7)
		State.TAIL_WHIP:
			state_t = TAIL_WARN
			whip_dir = -face_dir
			whip_side = -whip_side
			whip_struck = false
		State.JET:
			state_t = JET_WARN
			jet_struck = false
		State.SLITHER:
			slither_from = pos
			slither_dir = face_dir.normalized() if face_dir.length_squared() > 0.01 else Vector2.RIGHT
			chip_t = 0.0
			_shed_chip()
		State.STUNNED:
			state_t = STUN_TIME
		State.RETREAT:
			pass
		State.STAND:
			pos = PLINTH
			face_dir = Vector2.DOWN
			update_leg_positions()
			legs_tied = 0
			leg_touch_t = [-INF, -INF, -INF, -INF]
			ls_jet_cd = LAST_JET_EVERY
			Sfx.play("crack", 0.85, -3.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			main.feed.say("TIE UP HIS LEGS!", EventFeed.Tone.LOUD)
		State.WRAPPED:
			state_t = WOBBLE_TIME
			Sfx.play("intro_taut", 0.8, -5.0)
			Sfx.play("groan", 0.9, -5.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
		State.SLIDE:
			state_t = SLIDE_TIME
			main.drac_slid = true
			Sfx.play("crack", 0.5, -3.0)
			Sfx.play("whoop", 1.0, -6.0)
			main.shake_t = 1.2
			main.feed.say("EL DRAC SLIDES!", EventFeed.Tone.LOUD)
		State.CONTENT:
			hold_noticed = false
			Sfx.play("star", 1.1)
			Sfx.play("whoop", 1.1, -4.0)
			main.drac_settled = true
			main.combo.add("BOOP", 10)
			main.float_text(nose_tip(), "booped! +10", Color(1.0, 0.88, 0.25))
			main.feed.say("EL MOSAIC IS YOURS!", EventFeed.Tone.GOOD)
			main.human.say_line("Good... dragon?")
			fountain_t = 0.0
			if not win_film_shown and FilmPlayer.should_play(main) and ResourceLoader.exists(FILM_WIN):
				win_film_shown = true
				FilmPlayer.play(main, load(FILM_WIN))


func _hold_human() -> void:
	# Nobody walks past that dragon. The autowalk bot cannot fight, so passes.
	var h = main.human
	var want: bool = in_fight() and not main.auto_walk \
		and not h.homeward and h.global_position.y < HOLD_Y + 300.0
	if want:
		h.tut_hold_y = HOLD_Y
		if main.leash_target < main.LEASH_LENGTH:
			main.set_leash_target(main.LEASH_LENGTH)
		if not hold_noticed and h.global_position.y < HOLD_Y + 20.0:
			hold_noticed = true
			h.notice("Not past that dragon.", 1.8)
	elif h.tut_hold_y == HOLD_Y:
		h.tut_hold_y = -INF


func _tick_card(delta: float) -> void:
	if card_t >= 0.0:
		card_t += delta
		if card_t > CARD_TIME + CARD_FROM:
			card_t = -1.0
	if card != null and is_instance_valid(card):
		card.queue_redraw()


func _strike_tail() -> void:
	whip_struck = true
	Sfx.play("fling", 0.8, -3.0)
	Sfx.play("crack", 1.2, -8.0)
	var dog_p: Vector2 = main.dog.global_position
	var push := whip_dir.orthogonal() * whip_side
	if in_sector(dog_p, whip_dir, TAIL_REACH + 12.0, TAIL_HALF):
		main.dog.knocked((push + whip_dir * 0.4).normalized(), "tail")
	elif dog_p.distance_to(pos) < TAIL_REACH + 130.0 and hp > 0.0:
		_dodge(dog_p)
	if in_sector(main.human.global_position, whip_dir, TAIL_REACH + 12.0, TAIL_HALF):
		main.human.bumped(push)


func _dodge(at: Vector2) -> void:
	main.drac_dodges += 1
	main.combo.add("DODGE", 2)
	main.float_text(at, "dodged! +2", Color(0.8, 1.0, 0.7))
	damage(DODGE_DAMAGE)


func _lane_hit(p: Vector2, dir: Vector2, half_w: float) -> bool:
	var end := pos + dir * JET_LEN
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, pos, end)) < half_w


func _jet_puddle_rect(dir: Vector2) -> Rect2:
	var end := pos + dir * JET_LEN
	var hw := JET_W * 0.5
	var min_v := Vector2(minf(pos.x, end.x), minf(pos.y, end.y)) - Vector2(hw, hw)
	var max_v := Vector2(maxf(pos.x, end.x), maxf(pos.y, end.y)) + Vector2(hw, hw)
	return Rect2(min_v, max_v - min_v)


func _strike_jet() -> void:
	jet_struck = true
	Sfx.play("splash", 1.1, -4.0)
	var dir := face_dir.normalized()
	var dog_p: Vector2 = main.dog.global_position
	if _lane_hit(dog_p, dir, JET_W * 0.5 + 10.0):
		main.dog.knocked(dir, "jet")
		# headless ticks skip dog physics; shove her along the lane now
		main.dog.global_position += dir * 24.0
	if _lane_hit(main.human.global_position, dir, JET_W * 0.5 + 12.0):
		main.human.bumped(dir)
		main.human.global_position += dir * 18.0
	surface_zones.append({
		"rect": _jet_puddle_rect(dir),
		"kind": Surfaces.S.WATER,
		"until": main.elapsed + PUDDLE_LIFE,
	})


func _expire_zones() -> void:
	var i := surface_zones.size() - 1
	while i >= 0:
		if float(surface_zones[i].get("until", 0.0)) <= main.elapsed:
			surface_zones.remove_at(i)
		i -= 1


func _shed_chip() -> void:
	var h := CHIP_HALF
	surface_zones.append({
		"rect": Rect2(pos - Vector2(h, h), Vector2(h * 2.0, h * 2.0)),
		"kind": Surfaces.S.MUD,
		"until": main.elapsed + CHIP_LIFE,
	})


func _rope_taut_across() -> bool:
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


func check_trip() -> bool:
	return _rope_taut_across()


func check_column_bind() -> bool:
	if main.leash == null or main.leash.detached:
		return false
	if not _rope_taut_across():
		return false
	for y: float in LevelBuild.MOSAIC_HALL_ROWS:
		for x: float in LevelBuild.MOSAIC_HALL_COLS:
			if main.leash.touches(Vector2(x, y)):
				return true
	return false


func _hit(kind: String) -> void:
	flash = 0.5
	match kind:
		"column":
			main.drac_wound = true
			damage(COLUMN_DAMAGE)
			Sfx.play("intro_taut", 0.9, -4.0)
			Sfx.play("crack", 0.7, -2.0)
			main.feed.say("WOUND ROUND A COLUMN!", EventFeed.Tone.LOUD)
			main.combo.add("COLUMN", 8)
			main.float_text(pos, "wound! +8", Color(1.0, 0.85, 0.2))
		"trip":
			main.drac_tripped = true
			damage(TRIP_DAMAGE)
			Sfx.play("intro_taut", 0.9, -4.0)
			Sfx.play("crack", 0.55, -1.0)
			main.feed.say("TRIPPED!", EventFeed.Tone.LOUD)
			main.combo.add("TRIP", 8)
			main.float_text(pos, "tripped! +8", Color(1.0, 0.85, 0.2))
	main.shake_t = maxf(float(main.shake_t), 1.0)
	transition_to(State.STUNNED)


func _clamp_hall() -> void:
	pos.x = clampf(pos.x, LevelBuild.MOSAIC_HALL_COLS[0], LevelBuild.MOSAIC_HALL_COLS[LevelBuild.MOSAIC_HALL_COLS.size() - 1])
	pos.y = clampf(pos.y, LevelBuild.MOSAIC_HALL_Y1 + 40.0, LevelBuild.MOSAIC_HALL_Y0 - 40.0)


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


func _turn_to(p: Vector2, delta: float) -> void:
	var want := p - pos
	if want.length() < 1.0:
		return
	var a := face_dir.angle()
	var b := want.angle()
	var d := wrapf(b - a, -PI, PI)
	face_dir = Vector2.from_angle(a + clampf(d, -TURN_RATE * delta, TURN_RATE * delta))


func _tick_last_stand(delta: float, dog_p: Vector2) -> void:
	_turn_to(dog_p, delta)
	update_leg_positions()
	if act_t < 0.2:
		return
	ls_jet_cd -= delta
	# defensive jet from the steps, same telegraph as the fight's jet
	if ls_jet_cd <= JET_WARN and ls_jet_cd + delta > JET_WARN:
		if dog_p.distance_to(pos) < JET_LEN + 80.0:
			jet_struck = false
		else:
			ls_jet_cd = LAST_JET_EVERY
	if ls_jet_cd <= 0.0:
		_strike_jet()
		ls_jet_cd = LAST_JET_EVERY


func last_jet_warning() -> bool:
	return state == State.STAND and ls_jet_cd <= JET_WARN and ls_jet_cd > 0.0


func tick_state(delta: float) -> void:
	if main == null or main.frozen:
		return
	_tick_card(delta)
	_hold_human()
	_expire_zones()
	flash = maxf(0.0, flash - delta * 3.0)
	if fountain_t >= 0.0:
		fountain_t += delta
	var dog_p: Vector2 = main.dog.global_position
	act_t += delta
	match state:
		State.IDLE:
			# your human still short of him: a pair already past (a shot taken
			# further up the walk) leaves him asleep
			if dog_p.y <= WAKE_Y and main.human.global_position.y > HOLD_Y - 120.0 \
					and not bool(main.get("film_playing")):
				if not film_shown and FilmPlayer.should_play(main) and ResourceLoader.exists(FILM):
					film_shown = true
					FilmPlayer.play(main, load(FILM))
				else:
					transition_to(State.AWAKEN)
		State.AWAKEN:
			state_t += delta
			var k := clampf(state_t / AWAKEN_TIME, 0.0, 1.0)
			pos = PLINTH.lerp(LANDING, k)
			face_dir = Vector2.DOWN
			update_leg_positions()
			if state_t >= AWAKEN_TIME:
				pos = LANDING
				update_leg_positions()
				transition_to(State.PROWL)
		State.ENRAGE:
			state_t += delta
			if state_t >= ENRAGE_TIME:
				transition_to(State.PROWL)
		State.PROWL:
			# a hit that crossed half or emptied him lands between attacks too
			if hp <= 0.0 or (phase == 2 and not enraged):
				transition_to(State.PROWL)
				return
			tail_cd -= delta
			jet_cd -= delta
			slither_cd -= delta
			# no attack while his title card is up: the banner under it is hushed
			if hush_banner():
				return
			var d := dog_p.distance_to(pos)
			var behind := absf((-face_dir).angle_to(dog_p - pos)) < REAR_CONE
			var front := absf(face_dir.angle_to(dog_p - pos)) < FRONT_CONE
			if phase == 2 and slither_cd <= 0.0:
				slither_cd = SLITHER_COOLDOWN
				transition_to(State.SLITHER)
			elif d < TAIL_TRIGGER and behind and tail_cd <= 0.0:
				tail_cd = TAIL_COOLDOWN
				transition_to(State.TAIL_WHIP)
			elif d < JET_LEN and front and jet_cd <= 0.0:
				jet_cd = JET_COOLDOWN
				transition_to(State.JET)
		State.TAIL_WHIP:
			state_t -= delta
			if state_t <= 0.0:
				if not whip_struck:
					_strike_tail()
				var k := clampf(-state_t / TAIL_STRIKE, 0.0, 1.0)
				if k >= 1.0:
					transition_to(State.PROWL)
		State.JET:
			state_t -= delta
			if state_t <= 0.0:
				if not jet_struck:
					_strike_jet()
				var k := clampf(-state_t / JET_TIME, 0.0, 1.0)
				if k >= 1.0:
					transition_to(State.PROWL)
		State.SLITHER:
			state_t += delta
			var side := slither_dir.orthogonal()
			pos = slither_from + slither_dir * (state_t * SLITHER_SPEED) \
				+ side * sin(state_t * SLITHER_WAVE) * SLITHER_AMP
			_clamp_hall()
			face_dir = slither_dir
			update_leg_positions()
			chip_t += delta
			if chip_t >= CHIP_EVERY:
				chip_t = 0.0
				_shed_chip()
			if check_column_bind():
				_hit("column")
				return
			if check_trip():
				_hit("trip")
				return
			if state_t >= SLITHER_TIME:
				transition_to(State.PROWL)
		State.STUNNED:
			# empty HP: leave the daze for the retreat remap through PROWL
			if hp <= 0.0:
				transition_to(State.PROWL)
				return
			state_t -= delta
			if state_t <= 0.0:
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
				transition_to(State.SLIDE)
		State.SLIDE:
			# belly down the stair toward the landing, then wait for a nose boop
			if state_t > 0.0:
				state_t = maxf(0.0, state_t - delta)
				var k := 1.0 - clampf(state_t / SLIDE_TIME, 0.0, 1.0)
				pos.x = PLINTH.x
				pos.y = lerpf(PLINTH.y, LANDING.y, k)
				face_dir = Vector2.DOWN
				update_leg_positions()
		State.CONTENT:
			pass
		_:
			pass


func on_bark_action(bark_pos: Vector2) -> bool:
	var dog_p: Vector2 = main.dog.global_position
	var tip := nose_tip()
	var near := bark_pos.distance_to(tip) < BOOP_REACH or dog_p.distance_to(tip) < BOOP_REACH \
		or dog_p.distance_to(pos + face_dir * 60.0) < BOOP_REACH
	if state == State.SLIDE and near:
		Sfx.play("bark", 1.25)
		main.drac_booped = true
		transition_to(State.CONTENT)
		return true
	return false


func surface_at(p: Vector2) -> int:
	for z: Dictionary in surface_zones:
		if float(z.get("until", 0.0)) > main.elapsed and (z["rect"] as Rect2).has_point(p):
			return int(z["kind"])
	return -1  # -1 = no override


func awake_for_draw() -> bool:
	# beaten: hand the static salamander draw back to mosaic
	return state != State.IDLE and state != State.CONTENT


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
	if card_t < CARD_FROM:
		return
	var vs: Vector2 = card.size
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
	var accent := Color(0.18, 0.62, 0.70)
	card.draw_rect(Rect2(band.position, Vector2(vs.x, 5.0 * u)), accent)
	card.draw_rect(Rect2(band.position + Vector2(0.0, band.size.y - 5.0 * u), Vector2(vs.x, 5.0 * u)), accent)
	Kit.heading(card, Vector2(slide, cy - 34.0 * u), "EL MOSAIC", int(18.0 * u), Color(0.80, 0.78, 0.72),
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	Kit.heading(card, Vector2(slide, cy + 18.0 * u), "EL DRAC", int(52.0 * u), accent,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	var gloss := "The salamander, and he is awake"
	var gs := int(20.0 * u)
	var gw: float = Kit.text_w(Kit.body(), gloss, gs)
	card.draw_string(Kit.body(), Vector2(slide + (vs.x - gw) * 0.5, cy + 46.0 * u), gloss,
		HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Color(0.92, 0.88, 0.80))


func draw_ground(b: ShapeBatch, vt: float, vb: float) -> void:
	for z in surface_zones:
		var r: Rect2 = z["rect"]
		if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
			continue
		var kind: int = z["kind"]
		var remaining: float = float(z["until"]) - main.elapsed
		if kind == Surfaces.S.WATER:
			var a := clampf(remaining / 0.5, 0.0, 1.0) * 0.42
			b.rect(r, Color(0.30, 0.60, 0.78, a))
			b.circle(r.get_center(), minf(r.size.x, r.size.y) * 0.35, Color(0.45, 0.72, 0.88, a * 0.7))
		elif kind == Surfaces.S.MUD:
			var a := clampf(remaining / 0.4, 0.0, 1.0) * 0.65
			b.rect(r, Color(0.85, 0.72, 0.42, a * 0.4))
			for k in range(4):
				var cp := r.position + Vector2(fmod(float(k) * 17.0, r.size.x), fmod(float(k) * 23.0, r.size.y))
				var col := DRAC_BLUE if k % 2 == 0 else DRAC_YELLOW
				b.circle(cp, 3.5, Color(col.r, col.g, col.b, a))


func draw_warnings(b: ShapeBatch, t: float) -> void:
	var pulse := sin(t * 16.0) * 0.5 + 0.5
	if state == State.TAIL_WHIP and not whip_struck:
		var n := 16
		var prev := pos + whip_dir.rotated(-TAIL_HALF) * TAIL_REACH
		var col := Color(1.0, 0.45, 0.20, 0.22 + 0.14 * pulse)
		for i in range(1, n + 1):
			var a := -TAIL_HALF + float(i) * 2.0 * TAIL_HALF / float(n)
			var cur := pos + whip_dir.rotated(a) * TAIL_REACH
			b.line(prev, cur, col, 4.0)
			if i % 3 == 0:
				b.line(pos, cur, Color(col.r, col.g, col.b, 0.12), 2.0)
			prev = cur
		b.line(pos, pos + whip_dir * TAIL_REACH, col, 3.0)
	elif (state == State.JET and not jet_struck) or last_jet_warning():
		var from := pos + face_dir * 30.0
		var to := from + face_dir * JET_LEN
		var k := 1.0 - clampf(state_t / JET_WARN, 0.0, 1.0) if state == State.JET else \
			1.0 - clampf(ls_jet_cd / JET_WARN, 0.0, 1.0)
		b.line(from, to, Color(0.35, 0.75, 1.0, 0.16 + 0.10 * pulse), JET_W)
		b.line(from, from.lerp(to, clampf(k, 0.0, 1.0)), Color(0.50, 0.85, 1.0, 0.35), JET_W * 0.5)


func draw_drac(b: ShapeBatch, t: float) -> void:
	var at := pos
	if state == State.WRAPPED:
		at.x += sin(act_t * 16.0) * 4.0
	elif state == State.STUNNED:
		at.x += sin(t * 10.0) * 2.5
	elif state == State.SLIDE:
		var spray_c := at + Vector2(sin(t * 22.0) * 12.0, 0.0)
		b.circle(spray_c, 24.0, Color(0.70, 0.88, 1.0, 0.4))

	var f := face_dir
	var s := f.orthogonal()

	b.polygon(_ellipse(at + Vector2(8.0, 10.0), f, 56.0, 36.0, 16), SHADOW)

	# 4 splayed lizard legs at leg_poles
	for k in range(leg_poles.size()):
		var lp := leg_poles[k]
		if state in [State.PROWL, State.SLITHER, State.RETREAT]:
			lp += f * sin(t * 8.0 + float(k) * 1.6) * 5.0
		b.circle(lp, LEG_RADIUS + 2.0, Color(0.12, 0.10, 0.08, 0.8))
		b.circle(lp, LEG_RADIUS, DRAC_BLUE)
		var shard_col := DRAC_YELLOW if k % 2 == 0 else DRAC_GREEN
		b.circle(lp, LEG_RADIUS * 0.55, shard_col)
		for n in range(3):
			var claw := lp + f * (LEG_RADIUS + 3.0) + s * (float(n) - 1.0) * 6.0
			b.circle(claw, 2.5, Color(0.10, 0.08, 0.06))

	# tail
	var tail_pts := PackedVector2Array()
	var tail_wave := sin(t * 7.0) * 16.0 if state != State.CONTENT else 0.0
	if state == State.SLITHER:
		tail_wave = sin(act_t * SLITHER_WAVE) * SLITHER_AMP * 0.4
	for i in range(7):
		var frac := float(i) / 6.0
		var tp := at - f * (30.0 + frac * 65.0) + s * (sin(frac * PI) * 24.0 + frac * tail_wave)
		tail_pts.append(tp)
	for i in range(tail_pts.size() - 1):
		var w := lerpf(20.0, 6.0, float(i) / 6.0)
		b.line(tail_pts[i], tail_pts[i + 1], DRAC_BLUE, w)
		b.circle(tail_pts[i], w * 0.5, DRAC_CYAN)
		if i % 2 == 1:
			b.circle(tail_pts[i], w * 0.35, DRAC_YELLOW)

	# arched body
	var spine_offsets: Array[float] = [-18.0, -6.0, 8.0, 22.0, 34.0]
	var spine_radii: Array[float] = [24.0, 28.0, 27.0, 23.0, 18.0]
	var colors: Array[Color] = [DRAC_BLUE, DRAC_CYAN, DRAC_GREEN, DRAC_YELLOW, DRAC_ORANGE]
	for i in range(spine_offsets.size()):
		var sp_pos: Vector2 = at + f * spine_offsets[i]
		if state == State.SLITHER:
			sp_pos += s * sin(act_t * SLITHER_WAVE + float(i) * 0.8) * 12.0
		var r: float = spine_radii[i]
		b.circle(sp_pos, r + 2.0, Color(0.10, 0.08, 0.06))
		b.circle(sp_pos, r, colors[i % colors.size()])
		b.circle(sp_pos - f * 2.0, r * 0.65, DRAC_WHITE if i == 2 else colors[(i + 1) % colors.size()])
		b.circle(sp_pos - s * (r - 2.0), 4.5, DRAC_ORANGE)

	# head
	var head := at + f * 50.0
	b.circle(head, 20.0, Color(0.10, 0.08, 0.06))
	b.circle(head, 18.0, DRAC_BLUE)
	var snout := head + f * 14.0
	b.circle(snout, 14.0, DRAC_CYAN)
	b.circle(snout + f * 4.0, 8.0, DRAC_YELLOW)

	# eyes
	var awake := state != State.IDLE and state != State.CONTENT
	var eye_col := EYE_RED if (enraged and hp > 0.0) else EYE_AMBER
	for sd: float in [-1.0, 1.0]:
		var ep := head + f * 6.0 + s * sd * 12.0
		if awake:
			b.circle(ep, 5.0, Color(0.10, 0.08, 0.06))
			b.circle(ep, 3.8, eye_col)
			b.circle(ep + f * 1.0, 1.8, Color(0.10, 0.08, 0.06))
		else:
			b.line(ep - s * 3.0, ep + s * 3.0, Color(0.15, 0.12, 0.10), 2.0)

	# water stream shooting from mouth
	if (state == State.JET and jet_struck) or fountain_t >= 0.0:
		var mouth := snout + f * 8.0
		var jto := mouth + f * JET_LEN
		b.line(mouth, jto, Color(0.85, 0.95, 1.0, 0.85), 14.0)
		b.line(mouth, jto, Color(0.40, 0.75, 0.95, 0.9), 8.0)
		for j in range(6):
			var jp := mouth.lerp(jto, float(j) / 5.0) + Vector2(sin(t * 18.0 + float(j)) * 6.0, 0.0)
			b.circle(jp, 6.0, Color(0.92, 0.98, 1.0, 0.8))


func draw_rings(b: ShapeBatch, t: float) -> void:
	if state == State.STAND or state == State.WRAPPED:
		_ring(b, pos, 96.0, Color(0.98, 0.85, 0.30, 0.30 + sin(t * 8.0) * 0.15), 3.0)
		for k in range(leg_poles.size()):
			if main.elapsed - leg_touch_t[k] <= LEG_MEMORY or state == State.WRAPPED:
				_ring(b, leg_poles[k], LEG_RADIUS + 8.0, Color(1.0, 0.90, 0.20, 0.9), 3.5)
			else:
				_ring(b, leg_poles[k], LEG_RADIUS + 4.0, Color(0.98, 0.85, 0.30, 0.35), 2.0)
	elif state == State.SLIDE and state_t <= 0.0:
		var tip := nose_tip()
		var p_pulse := sin(t * 10.0) * 0.5 + 0.5
		_ring(b, tip, 28.0 + p_pulse * 8.0, Color(1.0, 0.88, 0.25, 0.7 + 0.3 * p_pulse), 3.0)
	if fountain_t >= 0.0 and fountain_t < 8.0:
		var a := clampf(fountain_t / 1.0, 0.0, 1.0) * clampf((8.0 - fountain_t) / 2.0, 0.0, 1.0)
		var top := nose_tip() - Vector2(0.0, 40.0)
		var r_colors: Array[Color] = [
			Color(0.96, 0.30, 0.30), Color(0.96, 0.62, 0.22), Color(0.96, 0.90, 0.24),
			Color(0.28, 0.82, 0.40), Color(0.22, 0.68, 0.96), Color(0.62, 0.32, 0.92)
		]
		for i in range(r_colors.size()):
			var rc: Color = r_colors[i]
			var rr := 90.0 - float(i) * 6.0
			var pts := PackedVector2Array()
			for k in range(17):
				var ang := PI + PI * float(k) / 16.0
				pts.append(top + Vector2(cos(ang) * rr, sin(ang) * rr * 0.6))
			for k in range(16):
				b.line(pts[k], pts[k + 1], Color(rc.r, rc.g, rc.b, 0.40 * a), 5.0)


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
	if state == State.IDLE or state == State.AWAKEN or hp <= 0.0 or state == State.CONTENT:
		return
	var at := pos
	var bar_w := 170.0
	var bar_h := 10.0
	var bp := _below_banner(at + Vector2(-bar_w * 0.5, -96.0), 24.0)
	c.draw_rect(Rect2(bp + Vector2(3.0, 3.0), Vector2(bar_w, bar_h)), SHADOW)
	c.draw_rect(Rect2(bp - Vector2(2.0, 2.0), Vector2(bar_w + 4.0, bar_h + 4.0)), Color(0.18, 0.16, 0.14))
	c.draw_rect(Rect2(bp - Vector2(1.0, 1.0), Vector2(bar_w + 2.0, bar_h + 2.0)), DRAC_CYAN.darkened(0.2))
	c.draw_rect(Rect2(bp, Vector2(bar_w, bar_h)), Color(0.10, 0.09, 0.08))
	var hf := clampf(hp / max_hp, 0.0, 1.0)
	if hf > 0.0:
		var fc := Color(0.96, 0.32, 0.22) if phase == 2 else Color(0.96, 0.74, 0.18)
		fc = fc.lerp(Color.WHITE, flash * 0.7)
		var fill := Rect2(bp + Vector2(1, 1), Vector2((bar_w - 2.0) * hf, bar_h - 2.0))
		c.draw_rect(fill, fc)
		c.draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), fc.lightened(0.35))
	c.draw_rect(Rect2(bp + Vector2(bar_w * 0.5 - 1.0, -2.0), Vector2(2.0, bar_h + 4.0)), Color(0.18, 0.16, 0.14))
	var fnt: Font = Kit.display()
	var label := "EL DRAC"
	var tw: float = Kit.text_w(fnt, label, 14)
	var tp := bp + Vector2((bar_w - tw) * 0.5, -5.0)
	c.draw_string_outline(fnt, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0.05, 0.04, 0.04, 0.85))
	c.draw_string(fnt, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, DRAC_YELLOW)


static func _ring(b: ShapeBatch, c: Vector2, r: float, col: Color, w: float) -> void:
	var n := 24
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
