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
# the trencadis: glazed shards on white mortar, in the colours of the one
# on the Park Guell stair
const INK := Color(0.10, 0.08, 0.06)
const GROUT := Color(0.80, 0.78, 0.72)
const TILE_BLUE := Color(0.12, 0.34, 0.74)
const TILE_CYAN := Color(0.16, 0.62, 0.78)
const TILE_GREEN := Color(0.26, 0.64, 0.34)
const TILE_YELLOW := Color(0.98, 0.80, 0.20)
const TILE_ORANGE := Color(0.94, 0.48, 0.14)
const TILE_WHITE := Color(0.98, 0.97, 0.93)
const TILES: Array[Color] = [TILE_BLUE, TILE_YELLOW, TILE_CYAN, TILE_ORANGE, TILE_GREEN, TILE_WHITE]
# his spine: joints from nose to hips, then down the tail
const BODY_N := 13
const TAIL_N := 11
# asleep his tail lies curled this far round (radians over its length)
const CURL := 2.3

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
			main.award_points(10, "booped! +10")
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
	main.award_points(2, "dodged! +2")
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
	if _lane_hit(main.human.global_position, dir, JET_W * 0.5 + 12.0):
		main.human.bumped(dir)
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
			main.award_points(8, "wound! +8")
		"trip":
			main.drac_tripped = true
			damage(TRIP_DAMAGE)
			Sfx.play("intro_taut", 0.9, -4.0)
			Sfx.play("crack", 0.55, -1.0)
			main.feed.say("TRIPPED!", EventFeed.Tone.LOUD)
			main.combo.add("TRIP", 8)
			main.award_points(8, "tripped! +8")
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
			# the jet's puddle: the wet it is, a paler sheet on it, a glint
			var a := clampf(remaining / 0.5, 0.0, 1.0)
			var rad := minf(r.size.x, r.size.y) * 0.5
			b.polygon(_rounded(r, rad), Color(0.24, 0.50, 0.70, 0.40 * a))
			b.polygon(_rounded(r.grow(-5.0), rad - 5.0), Color(0.46, 0.72, 0.88, 0.30 * a))
			var c := r.get_center()
			var along := Vector2(1.0, 0.0) if r.size.x > r.size.y else Vector2(0.0, 1.0)
			var half := maxf(r.size.x, r.size.y) * 0.5
			for k in range(3):
				var gp := c + along * (float(k) - 1.0) * half * 0.55 - Shade.light * rad * 0.3
				b.line(gp - along * 12.0, gp + along * 12.0, Color(0.92, 0.98, 1.0, 0.55 * a), 2.0)
		elif kind == Surfaces.S.MUD:
			# what he sheds in the slither: grit and chips of his own tile
			var a := clampf(remaining / 0.4, 0.0, 1.0)
			b.polygon(_rounded(r, 12.0), Color(0.86, 0.80, 0.66, 0.42 * a))
			for k in range(7):
				var h := _hash(r.position.x + float(k) * 3.1, r.position.y)
				var cp := r.position + Vector2(4.0 + fmod(float(k) * 17.0 + h * 9.0, r.size.x - 8.0), 4.0 + fmod(float(k) * 23.0 + h * 13.0, r.size.y - 8.0))
				var d := Vector2.from_angle(h * TAU) * 3.6
				var e := d.orthogonal() * (0.6 + h * 0.5)
				var col: Color = TILES[k % TILES.size()]
				b.quad(cp - d, cp + e, cp + d, cp - e, Color(col.r, col.g, col.b, a))


func draw_warnings(b: ShapeBatch, t: float) -> void:
	var pulse := sin(t * 16.0) * 0.5 + 0.5
	if state == State.TAIL_WHIP and not whip_struck:
		# the sector his tail will sweep, filling as the warning runs out
		var fill := 1.0 - clampf(state_t / TAIL_WARN, 0.0, 1.0)
		var a0 := whip_dir.angle() - TAIL_HALF
		var pts := PackedVector2Array([pos])
		var inner := PackedVector2Array([pos])
		for i in range(13):
			var d := Vector2.from_angle(a0 + TAIL_HALF * 2.0 * float(i) / 12.0)
			pts.append(pos + d * TAIL_REACH)
			inner.append(pos + d * TAIL_REACH * maxf(fill, 0.05))
		b.polygon(pts, Color(1.0, 0.36, 0.20, 0.10 + 0.08 * pulse))
		b.polygon(inner, Color(1.0, 0.36, 0.20, 0.20))
		for i in range(12):
			b.line(pts[i + 1], pts[i + 2], Color(1.0, 0.45, 0.28, 0.8), 3.0)
		b.line(pos, pts[1], Color(1.0, 0.45, 0.28, 0.6), 2.0)
		b.line(pos, pts[13], Color(1.0, 0.45, 0.28, 0.6), 2.0)
	elif (state == State.JET and not jet_struck) or last_jet_warning():
		var from := pos + face_dir * 30.0
		var to := from + face_dir * JET_LEN
		var side := face_dir.orthogonal() * JET_W * 0.5
		var k := 1.0 - clampf(state_t / JET_WARN, 0.0, 1.0) if state == State.JET else \
			1.0 - clampf(ls_jet_cd / JET_WARN, 0.0, 1.0)
		b.line(from, to, Color(0.35, 0.75, 1.0, 0.16 + 0.10 * pulse), JET_W)
		b.line(from, from.lerp(to, clampf(k, 0.0, 1.0)), Color(0.50, 0.85, 1.0, 0.35), JET_W * 0.5)
		b.line(from + side, to + side, Color(0.62, 0.90, 1.0, 0.65), 2.0)
		b.line(from - side, to - side, Color(0.62, 0.90, 1.0, 0.65), 2.0)
		var d := 40.0 + fmod(t * 260.0, 60.0)
		while d < JET_LEN - 10.0:
			var cp := from + face_dir * d
			var cc := Color(0.90, 0.98, 1.0, 0.7 * (1.0 - d / JET_LEN))
			b.line(cp - side * 0.6 - face_dir * 9.0, cp, cc, 2.5)
			b.line(cp + side * 0.6 - face_dir * 9.0, cp, cc, 2.5)
			d += 60.0


# How he holds himself in each state, for draw_salamander.
func _pose(t: float) -> Dictionary:
	var o := {
		"eye": 1.0, "eye_col": EYE_RED if (enraged and hp > 0.0) else EYE_AMBER,
		"wave": 2.0, "phase": t * 2.0, "tail_wag": 0.5, "tail_phase": t * 4.0,
		"flash": flash, "feet": leg_poles,
	}
	match state:
		State.AWAKEN:
			var k := clampf(state_t / AWAKEN_TIME, 0.0, 1.0)
			o["eye"] = clampf(state_t / 0.35, 0.0, 1.0)
			o["tail_bend"] = CURL * (1.0 - clampf(k * 2.0, 0.0, 1.0))
			o["wave"] = 7.0 * k
			o["phase"] = t * 7.0
			o["step"] = t * 9.0
		State.PROWL, State.RETREAT:
			o["wave"] = 5.0
			o["phase"] = t * 5.0
			o["step"] = t * 8.0
		State.ENRAGE:
			o["wave"] = 9.0
			o["phase"] = t * 24.0
			o["mouth"] = 1.0
			o["tail_wag"] = 1.6
			o["tail_phase"] = t * 22.0
			o["flash"] = maxf(flash, 0.35 + 0.35 * sin(t * 30.0))
		State.TAIL_WHIP:
			# cocked to one side through the warning, then across in a blink
			var cock := 1.0 - clampf(state_t / TAIL_WARN, 0.0, 1.0)
			var bend := -1.5 * cock
			var reach := 1.0 + 0.25 * cock
			if state_t <= 0.0:
				var k := clampf(-state_t / TAIL_STRIKE, 0.0, 1.0)
				bend = lerpf(-1.5, 1.6, k * k * (3.0 - 2.0 * k))
				reach = 1.45
			o["tail_bend"] = bend * whip_side
			o["tail_len"] = reach
			o["tail_wag"] = 0.15
		State.JET:
			o["mouth"] = 1.0 - clampf(state_t / JET_WARN, 0.0, 1.0) if state_t > 0.0 else 1.0
			o["tail_wag"] = 0.2
		State.SLITHER:
			o["wave"] = 15.0
			o["phase"] = state_t * SLITHER_WAVE * 2.0
			o["tail_wag"] = 1.5
			o["tail_phase"] = state_t * SLITHER_WAVE * 2.0
			o["step"] = t * 16.0
		State.STUNNED:
			o["dazed"] = true
			o["wave"] = 0.0
			o["tail_bend"] = 0.7
			o["tail_wag"] = 0.1
		State.STAND:
			o["mouth"] = 1.0 - clampf(ls_jet_cd / JET_WARN, 0.0, 1.0) if last_jet_warning() else 0.0
		State.WRAPPED:
			o["mouth"] = 0.7
			o["wave"] = 6.0
			o["phase"] = t * 26.0
		State.SLIDE:
			o["dazed"] = true
			o["wave"] = 4.0 if state_t > 0.0 else 0.0
			o["phase"] = t * 18.0
			o["tail_bend"] = 0.5
	return o


func draw_drac(b: ShapeBatch, t: float) -> void:
	var at := pos
	if state == State.WRAPPED:
		at.x += sin(act_t * 16.0) * 4.0
	elif state == State.STUNNED:
		at.x += sin(t * 10.0) * 2.5
	var f := face_dir
	var s := f.orthogonal()
	var o := _pose(t)
	if state == State.SLIDE and state_t > 0.0:
		# the belly slide: a wake of spray off either shoulder
		for sd: float in [-1.0, 1.0]:
			for k in range(4):
				var u := fposmod(t * 3.0 + float(k) * 0.25, 1.0)
				var sp := at + f * (30.0 - u * 70.0) + s * sd * (26.0 + u * 34.0)
				b.circle(sp, 7.0 * (1.0 - u) + 2.0, Color(0.86, 0.95, 1.0, 0.7 * (1.0 - u)))
	draw_salamander(b, at, f, t, o)

	if state == State.TAIL_WHIP and state_t <= 0.0:
		# the swish it leaves
		var k := clampf(-state_t / TAIL_STRIKE, 0.0, 1.0)
		var a0 := whip_dir.angle() - TAIL_HALF * whip_side
		var prev := Vector2.ZERO
		for i in range(11):
			var a := a0 + whip_side * TAIL_HALF * 2.0 * k * float(i) / 10.0
			var cur := at + Vector2.from_angle(a) * (TAIL_REACH - 14.0)
			if i > 0:
				b.line(prev, cur, Color(1.0, 0.97, 0.86, 0.75 * (1.0 - k) * float(i) / 10.0), 7.0 * float(i) / 10.0 + 1.0)
			prev = cur
	if state == State.JET and jet_struck:
		_draw_jet(b, at + f * 76.0, f, t, clampf(-state_t / JET_TIME, 0.0, 1.0))
	if state == State.STUNNED or (state == State.SLIDE and state_t <= 0.0):
		var head := at + f * 56.0
		for k in range(3):
			var sa := t * 6.0 + float(k) * TAU / 3.0
			var sp := head + Vector2(cos(sa) * 28.0, sin(sa) * 12.0 - 14.0)
			b.circle(sp, 4.4, Color(1.0, 0.92, 0.42))
			b.line(sp - Vector2(6.0, 0.0), sp + Vector2(6.0, 0.0), Color(1.0, 0.98, 0.80), 1.6)
			b.line(sp - Vector2(0.0, 6.0), sp + Vector2(0.0, 6.0), Color(1.0, 0.98, 0.80), 1.6)


# the fountain jet: a hard rope of water down the lane, breaking up as it
# goes, and where it lands
func _draw_jet(b: ShapeBatch, mouth: Vector2, f: Vector2, t: float, k: float) -> void:
	var s := f.orthogonal()
	var fade := 1.0 - k * k
	var n := 9
	var prev := mouth
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		var cur := mouth + f * (JET_LEN - 46.0) * u + s * sin(t * 30.0 + u * 9.0) * 5.0 * u
		var w := lerpf(13.0, JET_W * 0.8, u)
		b.line(prev, cur, Color(0.42, 0.74, 0.94, 0.55 * fade), w)
		b.line(prev, cur, Color(0.90, 0.97, 1.0, 0.85 * fade), w * 0.4)
		prev = cur
	for i in range(8):
		var u := fposmod(t * 2.4 + float(i) * 0.125, 1.0)
		var dp := mouth + f * (JET_LEN - 40.0) * u + s * sin(float(i) * 2.3) * (6.0 + u * 20.0)
		b.circle(dp, 3.0 + u * 2.0, Color(0.92, 0.98, 1.0, 0.8 * fade))
	var end := mouth + f * (JET_LEN - 46.0)
	_ring(b, end, 16.0 + k * 30.0, Color(0.86, 0.96, 1.0, 0.7 * fade), 3.0)
	_ring(b, end, 6.0 + k * 18.0, Color(1.0, 1.0, 1.0, 0.6 * fade), 2.0)


# Asleep on the stair, as the park has him: head down the steps, tail
# curled up behind. `content` is him after the fight, eyes shut in a smile.
static func draw_asleep(b: ShapeBatch, at: Vector2, f: Vector2, t: float, content: bool) -> void:
	draw_salamander(b, at, f, t, {"eye": 0.0, "happy": content, "tail_bend": CURL, "tail_wag": 0.0, "wave": 3.0,
		"phase": 0.6})


# The salamander from above, his middle at `at`, nose along `f`: a spine
# from snout to tail tip with a girth at every joint, skinned in broken tile
# on white mortar the way Gaudi's is, four splayed legs, bulging eyes.
# The pose `o`: `wave` and `phase` bend the body, `tail_bend` curls the tail
# (radians over its length), `tail_wag`/`tail_phase` swing it, `tail_len`
# stretches it, `eye` opens the eyes (`eye_col`), `happy`, `dazed`, `mouth`
# opens the mouth, `feet` are where the four feet are planted (his own legs'
# places when empty), `step` walks them, `flash` whitens him when hit.
static func draw_salamander(b: ShapeBatch, at: Vector2, f: Vector2, t: float, o: Dictionary) -> void:
	if f.length_squared() < 0.01:
		f = Vector2.DOWN
	var wave: float = o.get("wave", 0.0)
	var phase: float = o.get("phase", 0.0)
	var bend: float = o.get("tail_bend", 0.0)
	var wag: float = o.get("tail_wag", 0.0)
	var tphase: float = o.get("tail_phase", 0.0)
	var tail_len: float = o.get("tail_len", 1.0)
	var eye: float = o.get("eye", 1.0)
	var eye_col: Color = o.get("eye_col", EYE_AMBER)
	var happy: bool = o.get("happy", false)
	var dazed: bool = o.get("dazed", false)
	var mouth: float = o.get("mouth", 0.0)
	var white: float = o.get("flash", 0.0)
	var step: float = o.get("step", -1.0)
	var x := Transform2D(f, f.orthogonal(), at)

	# the spine, in his frame: head and trunk laid out along it, the tail
	# walked out behind joint by joint so a bend curls it
	var sp := PackedVector2Array()
	var rad := PackedFloat32Array()
	for i in range(BODY_N):
		var bx := lerpf(74.0, -36.0, float(i) / float(BODY_N - 1))
		var env := 1.0 - clampf((bx - 20.0) / 54.0, 0.0, 1.0) * 0.75
		sp.append(Vector2(bx, wave * sin(phase - bx * 0.05) * env))
		rad.append(_girth(bx))
	var heading := (sp[BODY_N - 1] - sp[BODY_N - 2]).angle()
	var ds := 9.6 * tail_len
	var p := sp[BODY_N - 1]
	for j in range(1, TAIL_N + 1):
		var v := float(j) / float(TAIL_N)
		var h := heading + bend * v + wag * sin(tphase - v * 4.0) * v * 0.7
		p += Vector2.from_angle(h) * ds
		sp.append(p)
		rad.append(lerpf(15.0, 3.2, pow(v, 0.8)))
	var n := sp.size()
	var pts := PackedVector2Array()
	var nrm := PackedVector2Array()
	for i in range(n):
		pts.append(x * sp[i])
	for i in range(n):
		var tan := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		nrm.append(tan.orthogonal())

	_strip(b, pts, nrm, rad, 3.0, Shade.light * 9.0, SHADOW)

	# legs under the body: shoulder to elbow to a splayed five-toed foot
	var feet: Array = o.get("feet", [])
	for k in range(4):
		var foot: Vector2 = feet[k] if feet.size() == 4 else x * Vector2(LEG_OFFSETS[k].y, LEG_OFFSETS[k].x)
		var loc: Vector2 = x.affine_inverse() * foot
		var front := loc.x > 0.0
		var sd := signf(loc.y)
		if step >= 0.0:
			foot += f * sin(step + float(k) * 1.7) * 6.0
		var hip: Vector2 = x * Vector2(24.0 if front else -22.0, sd * 14.0 + wave * sin(phase - (24.0 if front else -22.0) * 0.05))
		var out: Vector2 = (foot - hip).normalized()
		var elbow := hip.lerp(foot, 0.55) + out.orthogonal() * sd * (-5.0 if front else 5.0)
		b.capsule(hip, elbow, 9.4, INK)
		b.capsule(elbow, foot, 8.4, INK)
		b.circle(foot, 12.4, INK)
		var toe_dir := (out + f * 0.8).normalized()
		for n2 in range(4):
			var td := toe_dir.rotated((float(n2) - 1.5) * 0.5)
			b.capsule(foot + td * 9.0, foot + td * 17.0, 4.2, INK)
		b.capsule(hip, elbow, 7.4, TILE_BLUE)
		b.capsule(elbow, foot, 6.4, TILE_CYAN)
		b.circle(foot, 10.4, TILE_BLUE)
		for n2 in range(4):
			var td := toe_dir.rotated((float(n2) - 1.5) * 0.5)
			b.capsule(foot + td * 9.0, foot + td * 17.0, 2.5, TILE_BLUE if n2 % 2 == 0 else TILE_CYAN)
		_shard(b, hip.lerp(elbow, 0.55), out, 5.4, 4.6, TILE_YELLOW.lerp(Color.WHITE, white * 0.5), float(k))
		_shard(b, elbow.lerp(foot, 0.5), out, 4.4, 4.0, TILE_BLUE.lerp(Color.WHITE, white * 0.5), float(k) + 3.0)
		_shard(b, foot - out * 1.0, out, 5.6, 5.6, (TILE_ORANGE if front else TILE_GREEN).lerp(Color.WHITE, white * 0.5), float(k) + 7.0)

	# the skin: ink round it, mortar, then the tile
	_strip(b, pts, nrm, rad, 2.8, Vector2.ZERO, INK)
	b.circle(pts[0], rad[0] + 2.8, INK)
	_strip(b, pts, nrm, rad, 0.0, Vector2.ZERO, GROUT)
	b.circle(pts[0], rad[0], GROUT)
	for i in range(n - 1):
		var r0 := rad[i]
		var r1 := rad[i + 1]
		var cols := clampi(int((r0 + r1) / 13.0), 1, 4)
		for c in range(cols):
			var a0 := -1.0 + 2.0 * float(c) / float(cols)
			var a1 := -1.0 + 2.0 * float(c + 1) / float(cols)
			var h := _hash(float(i), float(c))
			# every shard its own odd shape, the mortar showing between
			var g0 := 0.03 + h * 0.05
			var g1 := 0.03 + fmod(h * 7.0, 1.0) * 0.05
			var pa := pts[i].lerp(pts[i + 1], g0)
			var pb := pts[i].lerp(pts[i + 1], 1.0 - g1)
			var la0 := a0 + (0.03 + 0.08 / float(cols) * h)
			var la1 := a1 - (0.03 + 0.08 / float(cols) * fmod(h * 3.0, 1.0))
			var edge := 0.98
			var q0 := pa + nrm[i] * r0 * la0 * edge
			var q1 := pb + nrm[i + 1] * r1 * la0 * edge
			var q2 := pb + nrm[i + 1] * r1 * la1 * edge
			var q3 := pa + nrm[i] * r0 * la1 * edge
			var col := _tile(i, c, cols, h)
			# the far side of him from the light sits a shade down
			var mid := (a0 + a1) * 0.5
			var lit := nrm[i].dot(-Shade.light) * mid
			col = col.lightened(0.16 * lit) if lit > 0.0 else col.darkened(-0.22 * lit)
			b.quad(q0, q1, q2, q3, col.lerp(Color.WHITE, white * 0.55))
	# the crest: a bright boss on every other joint of his back
	for i in range(3, BODY_N + 4, 2):
		b.circle(pts[i], 3.6, INK)
		b.circle(pts[i] - Shade.light * 0.8, 2.6, TILE_WHITE)
	# the glaze catches the sun here and there
	for k in range(5):
		var gi := 2 + k * 4
		if gi >= n:
			break
		var tw := pow(maxf(0.0, sin(t * 2.1 + float(k) * 1.9)), 6.0)
		b.circle(pts[gi] - nrm[gi] * rad[gi] * 0.4 - Shade.light * rad[gi] * 0.25, 1.4 + tw * 2.2, Color(1.0, 1.0, 1.0, 0.45 + 0.5 * tw))

	# the head: nostrils, the mouth when it opens, and the eyes up on top
	var tan0 := (pts[0] - pts[1]).normalized()
	if mouth > 0.03:
		b.circle(pts[0] + tan0 * 2.0, 3.0 + 6.0 * mouth, INK)
		b.circle(pts[0] + tan0 * 2.0, 1.5 + 4.6 * mouth, Color(0.62, 0.16, 0.14))
	for sd: float in [-1.0, 1.0]:
		b.circle(pts[0] - tan0 * 3.0 + nrm[0] * sd * 4.6, 1.5, INK)
	var hi := 2
	for sd: float in [-1.0, 1.0]:
		var ep: Vector2 = pts[hi] + nrm[hi] * sd * 12.5
		b.circle(ep, 8.4, INK)
		if dazed:
			b.circle(ep, 6.6, TILE_WHITE)
			for cr: float in [-1.0, 1.0]:
				b.line(ep - tan0 * 3.6 - nrm[hi] * 3.6 * cr, ep + tan0 * 3.6 + nrm[hi] * 3.6 * cr, INK, 2.0)
		elif eye <= 0.05 or happy:
			b.circle(ep, 6.6, TILE_BLUE)
			b.circle(ep - Shade.light * 1.6, 3.4, TILE_CYAN)
			if happy:
				b.line(ep - nrm[hi] * 4.6 - tan0 * 1.5, ep + tan0 * 1.5, INK, 2.0)
				b.line(ep + tan0 * 1.5, ep + nrm[hi] * 4.6 - tan0 * 1.5, INK, 2.0)
			else:
				b.line(ep - nrm[hi] * 5.0, ep + nrm[hi] * 5.0, INK, 2.2)
		else:
			b.circle(ep, 6.6, TILE_WHITE)
			b.circle(ep + tan0 * 1.2, 4.6 * eye, eye_col)
			b.line(ep + tan0 * (1.2 - 3.4 * eye), ep + tan0 * (1.2 + 3.4 * eye), INK, 2.2)
			b.circle(ep - Shade.light * 2.4, 1.3, Color.WHITE)
			# a lid of tile over the back of each eye: a glare
			b.line(ep - tan0 * 5.4 - nrm[hi] * 5.0, ep - tan0 * 5.4 + nrm[hi] * 5.0, TILE_ORANGE, 3.0)


# his girth at a point along his body, nose (74) to hips (-36)
static func _girth(bx: float) -> float:
	var keys := [[74.0, 9.0], [66.0, 15.0], [54.0, 19.0], [42.0, 15.5], [28.0, 23.0], [8.0, 27.0], [-12.0, 26.0],
		[-28.0, 21.0], [-36.0, 17.0]]
	for i in range(keys.size() - 1):
		if bx >= float(keys[i + 1][0]):
			var u := (float(keys[i][0]) - bx) / (float(keys[i][0]) - float(keys[i + 1][0]))
			return lerpf(float(keys[i][1]), float(keys[i + 1][1]), smoothstep(0.0, 1.0, u))
	return 17.0


# The tile at joint i, column c of `cols` across him: blues down his flanks,
# a yellow and orange stripe down his back, a band of gold round him every
# few joints, greens on the tail, a yellow snout.
static func _tile(i: int, c: int, cols: int, h: float) -> Color:
	var centre := cols >= 3 and (c == cols / 2 or (cols % 2 == 0 and c == cols / 2 - 1))
	if i < 2:
		return TILE_YELLOW if h < 0.7 else TILE_ORANGE
	if i >= BODY_N:
		var ring := (i - BODY_N) % 4
		if ring == 0:
			return TILE_YELLOW
		if ring == 2:
			return TILE_GREEN if h < 0.6 else TILE_CYAN
		return TILE_BLUE if h < 0.7 else TILE_CYAN
	if centre:
		return TILE_ORANGE if (i / 2) % 2 == 0 else TILE_YELLOW
	if i % 5 == 4:
		return TILE_YELLOW
	if h < 0.50:
		return TILE_BLUE
	if h < 0.74:
		return TILE_CYAN
	if h < 0.94:
		return TILE_GREEN
	return TILE_WHITE


static func _hash(a: float, c: float) -> float:
	return fposmod(sin(a * 12.9898 + c * 78.233) * 43758.5453, 1.0)


# one odd four-sided shard, `along` its long way
static func _shard(b: ShapeBatch, at: Vector2, along: Vector2, hl: float, hw: float, col: Color, key: float) -> void:
	var h := _hash(key, 1.7)
	var a := along.rotated((h - 0.5) * 0.7) * hl
	var w := along.orthogonal().rotated((h - 0.5) * 0.5) * hw
	b.quad(at - a - w * 0.8, at + a - w, at + a * 0.8 + w, at - a + w * 0.9, col)


# a ribbon along the spine, `grow` wider than his girth, moved by `off`
static func _strip(b: ShapeBatch, pts: PackedVector2Array, nrm: PackedVector2Array, rad: PackedFloat32Array,
		grow: float, off: Vector2, col: Color) -> void:
	for i in range(pts.size() - 1):
		var r0 := rad[i] + grow
		var r1 := rad[i + 1] + grow
		b.quad(pts[i] + nrm[i] * r0 + off, pts[i + 1] + nrm[i + 1] * r1 + off,
			pts[i + 1] - nrm[i + 1] * r1 + off, pts[i] - nrm[i] * r0 + off, col)


static func _rounded(r: Rect2, rad: float) -> PackedVector2Array:
	rad = clampf(rad, 1.0, minf(r.size.x, r.size.y) * 0.5)
	var out := PackedVector2Array()
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in range(4):
		for i in range(5):
			out.append(cs[k] + Vector2.from_angle(-PI * 0.5 + float(k) * PI * 0.5 + float(i) / 4.0 * PI * 0.5) * rad)
	return out


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
