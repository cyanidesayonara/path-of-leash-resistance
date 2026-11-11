class_name BossDrac
extends RefCounted

# EL DRAC, El Mosaic's salamander boss: asleep on the fountain stair until
# she wakes him. He climbs off the plinth under a title card; your human will
# not walk past that dragon. Part one: a tail whip across the rear sector
# (Mamut's swipe, axis -face_dir); a clear miss wears him down.

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

enum State {
	IDLE, AWAKEN, ENRAGE, PROWL, TAIL_WHIP, JET, SLITHER,
	STUNNED, RETREAT, STAND, WRAPPED, SLIDE, CONTENT,
}

var state: State = State.IDLE
var state_t := 0.0
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
var whip_dir := Vector2.UP
var whip_side := 1.0
var whip_struck := false
var jet_struck := false
# puddles / chips: [{ "rect": Rect2, "kind": int, "until": float }]
var surface_zones: Array[Dictionary] = []


func setup(m: Node2D) -> void:
	main = m
	state = State.IDLE
	state_t = 0.0
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
	whip_struck = false
	jet_struck = false
	legs_tied = 0
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


func status() -> String:
	var near: bool = main != null and main.dog.global_position.distance_to(pos) < 600.0
	match state:
		State.TAIL_WHIP:
			return "WATCH THE TAIL!" if near else ""
		State.JET:
			return "WATCH THE JET!" if near else ""
	return ""


func hush_banner() -> bool:
	return card_t >= 0.0 and card_t < CARD_FROM + CARD_TIME


func damage(amt: float) -> void:
	hp = maxf(0.0, hp - amt)


func in_sector(p: Vector2, dir: Vector2, reach: float, half: float) -> bool:
	var d := p - pos
	if d.length() > reach or d.length() < 1.0:
		return d.length() < 1.0
	return absf(dir.angle_to(d)) <= half


func transition_to(s: State) -> void:
	state = s
	state_t = 0.0
	match s:
		State.AWAKEN:
			if Sfx.lib.has("drac_click"):
				Sfx.play("drac_click", 1.0, -6.0)
			else:
				Sfx.play("crack", 1.3, -10.0)
			card_t = 0.0
			_ensure_card()
		State.TAIL_WHIP:
			state_t = TAIL_WARN
			whip_dir = -face_dir
			whip_side = -whip_side
			whip_struck = false
		State.JET:
			state_t = JET_WARN
			jet_struck = false
		State.CONTENT:
			hold_noticed = false


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


func tick_state(delta: float) -> void:
	if main == null or main.frozen:
		return
	_tick_card(delta)
	_hold_human()
	_expire_zones()
	var dog_p: Vector2 = main.dog.global_position
	match state:
		State.IDLE:
			# your human still short of him: a pair already past (a shot taken
			# further up the walk) leaves him asleep
			if dog_p.y <= WAKE_Y and main.human.global_position.y > HOLD_Y - 120.0 \
					and not bool(main.get("film_playing")):
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
		State.PROWL:
			tail_cd -= delta
			jet_cd -= delta
			# no attack while his title card is up: the banner under it is hushed
			if hush_banner():
				return
			var d := dog_p.distance_to(pos)
			var behind := absf((-face_dir).angle_to(dog_p - pos)) < REAR_CONE
			var front := absf(face_dir.angle_to(dog_p - pos)) < FRONT_CONE
			if d < TAIL_TRIGGER and behind and tail_cd <= 0.0:
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
		_:
			pass


func on_bark_action(_pos: Vector2) -> bool:
	return false


func surface_at(p: Vector2) -> int:
	for z: Dictionary in surface_zones:
		if float(z.get("until", 0.0)) > main.elapsed and (z["rect"] as Rect2).has_point(p):
			return int(z["kind"])
	return -1  # -1 = no override


func awake_for_draw() -> bool:
	return state != State.IDLE


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
