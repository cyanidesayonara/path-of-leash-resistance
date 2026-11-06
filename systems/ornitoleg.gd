class_name Ornitoleg
extends RefCounted

# L'ORNITÒLEG DEL BESÒS (El Besòs river park live event)
#
# A Catalan wildlife enthusiast and birdwatcher ("l'ornitòleg del Besòs") in a khaki
# safari bush hat and multi-pocket field vest crosses the riverside promenade from the
# eastern reed bank towards the flood wall at y = -2680.0, observing herons, egrets,
# and cormorants with a pair of field binoculars.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -2340.0), calls out
#   "Birdwatcher crossing!" with a bird chirp and field rustle sound.
# - Distracted human bump hazard: -8 patience drop, "Oops, didn't see you there!",
#   ornitòleg: "Mind the scope!".
# - Near-miss dodge save: NearMiss.consider awards "besòs dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
#   Walking past without near miss awards nothing.
# - Dropped binoculars snatch trick: a pair of field binoculars slips from around his neck
#   at center path (x <= 420.0). Dog can snatch it for "prismàtics snatch! +2".
# - Direct boop trick: booping the ornithologist awards "ornitòleg boop! +2".
# - Bark trick: barking within 130 px startles him into a spotting wobble for "ornitòleg bark! +2".
# - Autowalk clearance: passes well before autowalk pair arrives.
# - Zero new draw calls: batched into El Besòs's live ShapeBatch in draw_river.
# - Independent RNG sequence, zero mutation of rope physics.

enum State {
	IDLE,
	TELEGRAPH,
	WALKING,
	SETTLED,
}

const START_POS := Vector2(680.0, -2680.0)
const END_POS := Vector2(170.0, -2680.0)
const CROSSING_Y := -2680.0
const TRIGGER_Y := -2340.0
const DROP_X := 420.0
const WALK_SPEED := 210.0
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
var binoc_dropped: bool = false
var binoc_snatched: bool = false
var binoc_pos: Vector2 = Vector2.ZERO
var binoc_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Attire & birding gear colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const HAT_KHAKI := Color(0.78, 0.72, 0.54)
const HAT_BAND := Color(0.42, 0.38, 0.28)
const VEST_BEIGE := Color(0.82, 0.76, 0.60)
const POCKET_DARK := Color(0.68, 0.62, 0.48)
const SHIRT_SAGE := Color(0.48, 0.58, 0.44)
const TROUSERS_OLIVE := Color(0.32, 0.38, 0.28)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_GREY := Color(0.48, 0.48, 0.50)
const BINOC_BODY := Color(0.18, 0.20, 0.22)
const BINOC_LENS := Color(0.30, 0.55, 0.75)
const BINOC_STRAP := Color(0.12, 0.12, 0.14)
const STRAP_BRASS := Color(0.82, 0.70, 0.28)


func _init() -> void:
	_toss.seed = 0x08E505  # BESOS


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	binoc_dropped = false
	binoc_snatched = false
	binoc_pos = Vector2.ZERO
	binoc_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	wobble_t = 0.0
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	if wobble_t > 0.0:
		wobble_t = maxf(0.0, wobble_t - delta)

	# Update dropped binoculars physics
	if binoc_dropped and not binoc_snatched:
		binoc_pos += binoc_vel * delta
		binoc_vel = binoc_vel.move_toward(Vector2.ZERO, 45.0 * delta)
		if dog_pos.distance_to(binoc_pos) <= SNATCH_RADIUS:
			binoc_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.WALKING) and not booped:
		if dog_pos.distance_to(pos) <= BOOP_RADIUS:
			booped = true
			out["boop"] = true

	match state:
		State.IDLE:
			if not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CROSSING_Y - 200.0:
				triggered = true
				state = State.TELEGRAPH
				timer = 0.0
				out["warn"] = true

		State.TELEGRAPH:
			timer += delta
			anim_time += delta
			if timer >= WARN_DURATION:
				state = State.WALKING
				timer = 0.0

		State.WALKING:
			anim_time += delta
			pos.x -= WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 8.0) * 1.5

			# Drops binoculars near center path
			if not binoc_dropped and pos.x <= DROP_X:
				binoc_dropped = true
				binoc_pos = pos + Vector2(0.0, 8.0)
				binoc_vel = Vector2(-25.0, _toss.randf_range(-12.0, 12.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x <= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			anim_time += delta

	if state == State.WALKING or state == State.SETTLED:
		var close := state == State.WALKING and pos.distance_to(human_pos) <= THREAT_RADIUS
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = step["threatened"]
		if step["dodge"]:
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if (state == State.TELEGRAPH or state == State.WALKING) and not barked:
		if bark_pos.distance_to(pos) <= BARK_RADIUS:
			barked = true
			wobble_t = 0.5
			return true
	return false


func draw(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	# Draw dropped binoculars on ground if loose
	if binoc_dropped and not binoc_snatched:
		b.circle(binoc_pos + Vector2(2.0, 3.0), 5.5, SHADOW)
		# Twin barrels
		b.rect(Rect2(binoc_pos - Vector2(6.0, 4.0), Vector2(4.5, 8.0)), BINOC_BODY)
		b.rect(Rect2(binoc_pos + Vector2(1.5, -4.0), Vector2(4.5, 8.0)), BINOC_BODY)
		# Bridge & ocular lenses
		b.rect(Rect2(binoc_pos - Vector2(2.0, -1.0), Vector2(4.0, 2.5)), BINOC_STRAP)
		b.circle(binoc_pos + Vector2(-3.8, -4.0), 2.2, BINOC_LENS)
		b.circle(binoc_pos + Vector2(3.8, -4.0), 2.2, BINOC_LENS)
		b.circle(binoc_pos + Vector2(-3.8, 4.0), 2.5, BINOC_BODY)
		b.circle(binoc_pos + Vector2(3.8, 4.0), 2.5, BINOC_BODY)

	# Ornithologist character drawing
	var wobble := sin(anim_time * 16.0) * 4.0 if wobble_t > 0.0 else 0.0
	var bob := sin(anim_time * 8.0) * 1.5 if state == State.WALKING else 0.0
	var draw_p := pos + Vector2(0.0, bob)

	# Shadow
	b.circle(draw_p + Vector2(2.0, 4.0), 16.0, SHADOW)

	# Shoulders & safari vest
	b.circle(draw_p, 13.0, SHIRT_SAGE)
	b.circle(draw_p + Vector2(-1.0, 0.0), 11.5, VEST_BEIGE)

	# Vest pockets & strap
	b.rect(Rect2(draw_p - Vector2(8.0, 4.0), Vector2(5.0, 4.0)), POCKET_DARK)
	b.rect(Rect2(draw_p + Vector2(3.0, -4.0), Vector2(5.0, 4.0)), POCKET_DARK)
	b.line(draw_p + Vector2(-6.0, -9.0), draw_p + Vector2(6.0, 9.0), BINOC_STRAP, 1.8)

	# Binoculars held forward (facing westbound)
	var binoc_held := draw_p + Vector2(-11.0 + wobble, 0.0)
	b.rect(Rect2(binoc_held - Vector2(3.0, 5.0), Vector2(6.0, 10.0)), BINOC_BODY)
	b.circle(binoc_held + Vector2(-3.0, -3.0), 2.2, BINOC_LENS)
	b.circle(binoc_held + Vector2(-3.0, 3.0), 2.2, BINOC_LENS)

	# Head & grey hair
	var head_p := draw_p + Vector2(1.0, -1.0)
	b.circle(head_p, 8.5, HAIR_GREY)
	b.circle(head_p + Vector2(-2.0, 0.0), 6.5, SKIN_TONE)

	# Safari bush hat with wide brim and darker band
	b.circle(head_p + Vector2(-0.5, -0.5), 9.2, HAT_KHAKI)
	b.circle(head_p + Vector2(-0.5, -0.5), 7.4, HAT_BAND)
	b.circle(head_p + Vector2(-0.5, -0.5), 5.8, HAT_KHAKI)
