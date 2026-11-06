class_name Guitarrista
extends RefCounted

const NearMiss := preload("res://systems/near_miss.gd")
const EventFeed := preload("res://hud/event_feed.gd")

# EL GUITARRISTA DEL CARMEL (Els Búnquers live event)
#
# A Catalan rumba guitarist ("el guitarrista del Carmel") in a wide-brimmed Spanish fedora,
# rolled-up cream linen shirt, and leather guitar case crosses the hilltop gravel terrace from
# the eastern bunker parapet towards the western sunset mirador at y = -3500.0, carrying a Spanish
# acoustic guitar and singing chords of sunset rumba.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -3160.0), calls out
#   "Una rumbeta pel capvespre!" with an acoustic chime.
# - Distracted human bump hazard: -8 patience drop, "Whoa! Watch the guitar!",
#   guitarist: "Al tanto amb la guitarra!".
# - Near-miss dodge save: NearMiss.consider awards "carmel dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
#   Walking past without near miss awards nothing.
# - Dropped olives snatch trick: a tin of stuffed olives ("olives farcides") slips from his
#   picnic bag at center path (x <= 640.0). Dog can snatch it for "olives snatch! +2".
# - Direct boop trick: booping the guitarist awards "guitarrista boop! +2".
# - Bark trick: barking within 130 px prompts an energetic rumba flourish for "rumba bark! +2".
# - Autowalk clearance: crosses well before autowalk pair arrives.
# - Zero new draw calls: batched into Carmel's live ShapeBatch.
# - Independent RNG sequence, zero mutation of rope physics.

enum State {
	IDLE,
	TELEGRAPH,
	WALKING,
	SETTLED,
}

const START_POS := Vector2(810.0, -3500.0)
const END_POS := Vector2(470.0, -3500.0)
const CROSSING_Y := -3500.0
const TRIGGER_Y := -3160.0
const DROP_X := 640.0
const WALK_SPEED := 205.0
const WARN_DURATION := 0.8

const BUMP_RADIUS := 25.0
const THREAT_RADIUS := 66.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const SNATCH_RADIUS := 26.0

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var olives_dropped: bool = false
var olives_snatched: bool = false
var olives_pos: Vector2 = Vector2.ZERO
var olives_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Attire & guitar colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const HAT_FELT := Color(0.32, 0.22, 0.16)
const HAT_BAND := Color(0.78, 0.28, 0.24)
const SHIRT_CREAM := Color(0.94, 0.90, 0.82)
const TROUSERS_BROWN := Color(0.42, 0.32, 0.22)
const GUITAR_WOOD := Color(0.82, 0.54, 0.28)
const GUITAR_DARK := Color(0.46, 0.24, 0.14)
const GUITAR_HOLE := Color(0.18, 0.12, 0.08)
const CASE_LEATHER := Color(0.38, 0.24, 0.16)
const OLIVE_GREEN := Color(0.44, 0.56, 0.24)
const TIN_RED := Color(0.85, 0.26, 0.22)


func _init() -> void:
	_toss.seed = 350077


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	olives_dropped = false
	olives_snatched = false
	olives_pos = Vector2.ZERO
	olives_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	wobble_t = 0.0
	anim_time = 0.0


func tick(m: Node2D, delta: float) -> void:
	anim_time += delta
	if wobble_t > 0.0:
		wobble_t = maxf(0.0, wobble_t - delta)

	var dog_p: Vector2 = m.dog.global_position
	var human_p: Vector2 = m.human.global_position

	match state:
		State.IDLE:
			if not triggered and human_p.y < TRIGGER_Y and human_p.y > CROSSING_Y - 400.0:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				m.feed.say("El guitarrista: \"Una rumbeta pel capvespre!\"", EventFeed.Tone.LOUD)
				m.get_node("/root/Sfx").play("whoop", 1.15, -4.0)

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.WALKING

		State.WALKING:
			var dir := (END_POS - START_POS).normalized()
			pos += dir * WALK_SPEED * delta

			if not olives_dropped and pos.x <= DROP_X:
				olives_dropped = true
				olives_pos = pos + Vector2(0.0, -8.0)
				olives_vel = Vector2(_toss.randf_range(-40.0, -15.0), _toss.randf_range(20.0, 50.0))
				m.get_node("/root/Sfx").play("grit", 1.1, -4.0)

			if not human_hit:
				var dist_human := human_p.distance_to(pos)
				if dist_human < BUMP_RADIUS:
					human_hit = true
					m.human.bump(Vector2.DOWN, 8.0)
					m.float_text(human_p + Vector2(0, -34), "Watch the guitar!", Color(1.0, 0.45, 0.4), m.POP_SAY)
					m.float_text(pos + Vector2(0, -28), "Al tanto amb la guitarra!", Color(0.96, 0.88, 0.35))
					m.get_node("/root/Sfx").play("grunt", 0.95, -2.0)

			if pos.distance_to(END_POS) < 8.0:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	# Near-miss dodge save
	if state == State.WALKING or state == State.SETTLED:
		var close: bool = state == State.WALKING and pos.distance_to(human_p) <= THREAT_RADIUS
		var step: Dictionary = NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			m.saves_done += 1
			m.combo.add("CARMEL DODGE", 2)
			m.float_text(pos + Vector2(0, -32), "carmel dodge! +2", Color(0.96, 0.88, 0.35))
			m.get_node("/root/Sfx").play("bell", 1.25, -2.0)

	# Snatching dropped olives
	if olives_dropped and not olives_snatched:
		if olives_vel.length_squared() > 1.0:
			olives_pos += olives_vel * delta
			olives_vel = olives_vel.move_toward(Vector2.ZERO, 140.0 * delta)
		if dog_p.distance_to(olives_pos) < SNATCH_RADIUS:
			olives_snatched = true
			m.combo.add("OLIVES SNATCH", 2)
			m.float_text(olives_pos, "olives snatch! +2", Color(0.55, 0.85, 0.35))
			m.get_node("/root/Sfx").play("snack", 1.2, -2.0)

	# Direct boop
	if not booped and state in [State.WALKING, State.SETTLED]:
		if dog_p.distance_to(pos) < BOOP_RADIUS:
			booped = true
			wobble_t = 0.5
			m.combo.add("GUITARRISTA BOOP", 2)
			m.float_text(pos + Vector2(0, -32), "guitarrista boop! +2", Color(1.0, 0.85, 0.3))
			m.get_node("/root/Sfx").play("whoop", 1.25, -3.0)


func on_bark(m: Node2D) -> bool:
	if barked or state == State.IDLE:
		return false
	var dog_p: Vector2 = m.dog.global_position
	if dog_p.distance_to(pos) < BARK_RADIUS:
		barked = true
		wobble_t = 0.8
		m.combo.add("RUMBA BARK", 2)
		m.float_text(pos + Vector2(0, -36), "Olé! rumba bark! +2", Color(1.0, 0.75, 0.3))
		m.get_node("/root/Sfx").play("bell", 1.2, -3.0)
		return true
	return false


func draw(wc: ShapeBatch) -> void:
	if state == State.IDLE:
		return

	# Dropped tin of olives
	if olives_dropped and not olives_snatched:
		wc.circle(olives_pos + Vector2(2.0, 2.0), 6.0, SHADOW)
		wc.circle(olives_pos, 5.0, TIN_RED)
		wc.circle(olives_pos, 3.2, OLIVE_GREEN)

	var w_offset := sin(anim_time * 26.0) * 3.5 if wobble_t > 0.0 else 0.0
	var p := pos + Vector2(w_offset, 0.0)

	# Contact shadow
	wc.circle(p + Vector2(0.0, 6.0), 18.0, SHADOW)

	# Guitar case carried in right hand
	var case_p := p + Vector2(16.0, 4.0)
	wc.capsule(case_p + Vector2(0.0, -14.0), case_p + Vector2(0.0, 14.0), 7.0, CASE_LEATHER)

	# Guitarist body & fedora hat
	var walk_bob := sin(anim_time * 12.0) * 2.5 if state == State.WALKING else 0.0
	var head_p := p + Vector2(0.0, -28.0 + walk_bob)

	# Trousers and linen shirt
	wc.capsule(p + Vector2(-5.0, -4.0), p + Vector2(-5.0, 8.0), 4.5, TROUSERS_BROWN)
	wc.capsule(p + Vector2(5.0, -4.0), p + Vector2(5.0, 8.0), 4.5, TROUSERS_BROWN)
	wc.capsule(p + Vector2(0.0, -20.0 + walk_bob), p + Vector2(0.0, -4.0), 9.0, SHIRT_CREAM)

	# Spanish guitar slung across torso
	var g_p := p + Vector2(-8.0, -12.0 + walk_bob)
	wc.circle(g_p + Vector2(-4.0, 4.0), 9.0, GUITAR_WOOD)
	wc.circle(g_p + Vector2(-4.0, 4.0), 3.5, GUITAR_HOLE)
	wc.circle(g_p + Vector2(2.0, -3.0), 7.0, GUITAR_WOOD)
	wc.line(g_p + Vector2(2.0, -3.0), g_p + Vector2(10.0, -14.0), GUITAR_DARK, 3.0)

	# Head and brimmed hat
	wc.circle(head_p, 8.0, Color(0.88, 0.72, 0.58))
	wc.capsule(head_p + Vector2(-12.0, -3.0), head_p + Vector2(12.0, -3.0), 3.5, HAT_FELT)
	wc.circle(head_p + Vector2(0.0, -5.0), 7.0, HAT_FELT)
	wc.line(head_p + Vector2(-6.0, -4.0), head_p + Vector2(6.0, -4.0), HAT_BAND, 2.0)
