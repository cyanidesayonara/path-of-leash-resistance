class_name Escombriaire
extends RefCounted

# L'ESCOMBRIAIRE DE LA NETEJA (La Neteja live event)
#
# A Barcelona municipal street sweeper ("l'escombriaire de carrer") in high-visibility
# fluorescent yellow overalls with reflective silver safety bands and an orange work cap
# pushes a lime-green BCN NETA wheeled bin cart across the dawn alleyway from the east kerb
# to the west kerb at y = -1600.0, clearing the wet setts with a stiff push-broom.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -1300.0), calls out
#   "Wet street, mind the broom!" with a soapy splash and broom scuff sound.
# - Distracted human bump hazard: -8 patience drop, "Ugh, I'm all dusty!",
#   escombriaire: "Watch the bristles!".
# - Near-miss dodge save: NearMiss.consider awards "neteja dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
#   Walking past without near miss awards nothing.
# - Dropped rubber duck snatch trick: a bright yellow rubber bath duck ("l'ànec de goma")
#   slips from the gutter rubbish at center street (x <= 640.0). Dog can snatch it for
#   "duck snatch! +2".
# - Direct boop trick: booping the sweeper awards "escombriaire boop! +2".
# - Bark trick: barking within 130 px startles him into a broom wobble for "escombriaire bark! +2".
# - Autowalk clearance: passes well before autowalk pair arrives.
# - Zero new draw calls: batched into La Neteja's live ShapeBatch in _draw_street.
# - Independent RNG sequence, zero mutation of rope physics.

enum State {
	IDLE,
	TELEGRAPH,
	WALKING,
	SETTLED,
}

const START_POS := Vector2(810.0, -1600.0)
const END_POS := Vector2(460.0, -1600.0)
const CROSSING_Y := -1600.0
const TRIGGER_Y := -1300.0
const DROP_X := 640.0
const WALK_SPEED := 190.0
const WARN_DURATION := 0.8

const BUMP_RADIUS := 25.0
const THREAT_RADIUS := 64.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const SNATCH_RADIUS := 26.0

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var duck_dropped: bool = false
var duck_snatched: bool = false
var duck_pos: Vector2 = Vector2.ZERO
var duck_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Attire & gear colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const HIVIS_YELLOW := Color(0.85, 0.94, 0.18)
const SILVER_REFLECT := Color(0.92, 0.94, 0.96, 0.90)
const OVERALLS_NAVY := Color(0.18, 0.24, 0.32)
const CAP_ORANGE := Color(0.95, 0.45, 0.12)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_DARK := Color(0.24, 0.18, 0.14)
const CART_GREEN := Color(0.38, 0.72, 0.28)
const CART_LID := Color(0.24, 0.26, 0.28)
const CART_WHEEL := Color(0.12, 0.13, 0.14)
const BROOM_WOOD := Color(0.66, 0.48, 0.30)
const BROOM_BRISTLE := Color(0.82, 0.42, 0.22)
const DUCK_YELLOW := Color(1.0, 0.88, 0.15)
const DUCK_BEAK := Color(0.98, 0.48, 0.12)


func _init() -> void:
	_toss.seed = 0x0E7E1A  # NETEJA


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	duck_dropped = false
	duck_snatched = false
	duck_pos = Vector2.ZERO
	duck_vel = Vector2.ZERO
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

	# Update dropped rubber duck physics
	if duck_dropped and not duck_snatched:
		duck_pos += duck_vel * delta
		duck_vel = duck_vel.move_toward(Vector2.ZERO, 45.0 * delta)
		if dog_pos.distance_to(duck_pos) <= SNATCH_RADIUS:
			duck_snatched = true
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

			# Drops rubber duck near center street
			if not duck_dropped and pos.x <= DROP_X:
				duck_dropped = true
				duck_pos = pos + Vector2(0.0, 8.0)
				duck_vel = Vector2(-22.0, _toss.randf_range(-12.0, 12.0))

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

	# Draw dropped yellow rubber duck if loose
	if duck_dropped and not duck_snatched:
		b.circle(duck_pos + Vector2(1.5, 2.5), 5.0, SHADOW)
		# Body & head
		b.circle(duck_pos, 4.5, DUCK_YELLOW)
		b.circle(duck_pos + Vector2(-3.0, -2.5), 3.2, DUCK_YELLOW)
		# Orange beak & eye
		b.circle(duck_pos + Vector2(-5.5, -2.2), 1.6, DUCK_BEAK)
		b.circle(duck_pos + Vector2(-3.4, -3.4), 0.8, Color(0.1, 0.1, 0.1))

	# Sweeper character drawing
	var wobble := sin(anim_time * 16.0) * 4.0 if wobble_t > 0.0 else 0.0
	var bob := sin(anim_time * 8.0) * 1.5 if state == State.WALKING else 0.0
	var draw_p := pos + Vector2(0.0, bob)

	# Shadow
	b.circle(draw_p + Vector2(2.0, 4.0), 16.0, SHADOW)

	# Overalls & high-vis fluorescent yellow bib
	b.circle(draw_p, 13.0, OVERALLS_NAVY)
	b.circle(draw_p + Vector2(-1.0, 0.0), 11.5, HIVIS_YELLOW)

	# Reflective safety bands
	b.line(draw_p + Vector2(-7.0, -4.0), draw_p + Vector2(5.0, -4.0), SILVER_REFLECT, 2.0)
	b.line(draw_p + Vector2(-7.0, 4.0), draw_p + Vector2(5.0, 4.0), SILVER_REFLECT, 2.0)

	# Wheeled municipal cleaning bin cart pushed ahead (facing west)
	var cart_p := draw_p + Vector2(-18.0 + wobble, 0.0)
	b.circle(cart_p + Vector2(1.5, 3.0), 11.0, SHADOW)
	b.rect(Rect2(cart_p - Vector2(7.0, 10.0), Vector2(14.0, 20.0)), CART_GREEN)
	b.rect(Rect2(cart_p - Vector2(8.0, 11.0), Vector2(16.0, 4.0)), CART_LID)
	# Wheels
	b.circle(cart_p + Vector2(-4.0, -11.0), 3.0, CART_WHEEL)
	b.circle(cart_p + Vector2(-4.0, 11.0), 3.0, CART_WHEEL)

	# Stiff push-broom held in front
	var broom_p := draw_p + Vector2(-12.0 + wobble, -9.0)
	b.line(draw_p + Vector2(-2.0, -4.0), broom_p, BROOM_WOOD, 2.0)
	b.line(broom_p + Vector2(-2.0, -5.0), broom_p + Vector2(-2.0, 5.0), BROOM_BRISTLE, 3.5)

	# Head & hair
	var head_p := draw_p + Vector2(2.0, -1.0)
	b.circle(head_p, 8.5, HAIR_DARK)
	b.circle(head_p + Vector2(-2.0, 0.0), 6.5, SKIN_TONE)

	# Municipal orange work cap with peak facing west
	b.circle(head_p + Vector2(-0.5, -0.5), 8.5, CAP_ORANGE)
	b.rect(Rect2(head_p - Vector2(7.0, 3.5), Vector2(5.0, 7.0)), CAP_ORANGE.darkened(0.15))
