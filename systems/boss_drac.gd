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
