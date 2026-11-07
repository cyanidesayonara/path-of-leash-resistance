class_name Botanic
extends RefCounted

# EL BOTÀNIC DE MONTJUÏC (Montjuïc live event)
#
# A botanical gardener and succulent specialist ("el botànic de Montjuïc") in a straw sunhat
# and dark green gardening apron crosses the hillside terrace from the eastern cactus gardens
# toward the western pine overlook at y = -1750.0, carefully carrying a terracotta clay pot
# with a flowering rosette succulent.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -1450.0), calls out
#   "Mind the cactus!" with a terracotta clink and gravel scuff sound.
# - Distracted human bump hazard: -8 patience drop, "Ouch! Is that a cactus?",
#   botànic: "Mind the spines!".
# - Near-miss dodge save: NearMiss.consider awards "montjuïc dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
#   Walking past without near miss awards nothing.
# - Dropped succulent snatch trick: a potted terracotta succulent slips from his hands
#   at center terrace (x <= 640.0). Dog can snatch it for "succulent snatch! +2".
# - Direct boop trick: booping the botanist awards "botànic boop! +2".
# - Bark trick: barking within 130 px startles him into a pot wobble for "botànic bark! +2".
# - Autowalk clearance: passes well before autowalk pair arrives.
# - Zero new draw calls: batched into Montjuïc's live ShapeBatch in draw_live.
# - Independent RNG sequence, zero mutation of rope physics.

enum State {
	IDLE,
	TELEGRAPH,
	WALKING,
	SETTLED,
}

const START_POS := Vector2(850.0, -1750.0)
const END_POS := Vector2(430.0, -1750.0)
const CROSSING_Y := -1750.0
const TRIGGER_Y := -1450.0
const DROP_X := 640.0
const WALK_SPEED := 200.0
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
var pot_dropped: bool = false
var pot_snatched: bool = false
var pot_pos: Vector2 = Vector2.ZERO
var pot_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Attire & botanical colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const HAT_STRAW := Color(0.88, 0.80, 0.56)
const HAT_BAND := Color(0.22, 0.44, 0.26)
const APRON_GREEN := Color(0.20, 0.42, 0.24)
const APRON_STRAP := Color(0.48, 0.36, 0.24)
const SHIRT_LINEN := Color(0.92, 0.88, 0.80)
const TROUSERS_BROWN := Color(0.42, 0.34, 0.26)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_GREY := Color(0.50, 0.50, 0.52)
const POT_CLAY := Color(0.78, 0.44, 0.28)
const POT_DARK := Color(0.60, 0.32, 0.18)
const SOIL_DARK := Color(0.28, 0.22, 0.16)
const SUCCULENT_GREEN := Color(0.36, 0.66, 0.40)
const SUCCULENT_BLOSSOM := Color(0.95, 0.28, 0.28)
const TROWEL_STEEL := Color(0.75, 0.76, 0.78)


func _init() -> void:
	_toss.seed = 0xB07A11  # BOTANIC


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	pot_dropped = false
	pot_snatched = false
	pot_pos = Vector2.ZERO
	pot_vel = Vector2.ZERO
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

	# Update dropped succulent pot physics
	if pot_dropped and not pot_snatched:
		pot_pos += pot_vel * delta
		pot_vel = pot_vel.move_toward(Vector2.ZERO, 45.0 * delta)
		if dog_pos.distance_to(pot_pos) <= SNATCH_RADIUS:
			pot_snatched = true
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

			# Drops succulent pot near center terrace
			if not pot_dropped and pos.x <= DROP_X:
				pot_dropped = true
				pot_pos = pos + Vector2(0.0, 8.0)
				pot_vel = Vector2(-22.0, _toss.randf_range(-12.0, 12.0))

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

	# Draw dropped terracotta succulent pot if loose
	if pot_dropped and not pot_snatched:
		b.circle(pot_pos + Vector2(1.5, 2.5), 5.5, SHADOW)
		# Terracotta clay pot rim & body
		b.circle(pot_pos, 5.0, POT_DARK)
		b.circle(pot_pos + Vector2(-0.5, -0.5), 4.2, POT_CLAY)
		b.circle(pot_pos + Vector2(-0.5, -0.5), 3.2, SOIL_DARK)
		# Rosette succulent leaves & tiny red blossom
		b.circle(pot_pos + Vector2(-0.5, -0.5), 2.4, SUCCULENT_GREEN)
		b.circle(pot_pos + Vector2(-0.5, -0.5), 1.2, SUCCULENT_BLOSSOM)

	# Botanist character drawing
	var wobble := sin(anim_time * 16.0) * 4.0 if wobble_t > 0.0 else 0.0
	var bob := sin(anim_time * 8.0) * 1.5 if state == State.WALKING else 0.0
	var draw_p := pos + Vector2(0.0, bob)

	# Shadow
	b.circle(draw_p + Vector2(2.0, 4.0), 16.0, SHADOW)

	# Linen shirt & dark green gardening apron
	b.circle(draw_p, 13.0, SHIRT_LINEN)
	b.circle(draw_p + Vector2(-1.0, 0.0), 11.5, APRON_GREEN)

	# Apron straps & steel trowel in pocket
	b.line(draw_p + Vector2(-5.0, -8.0), draw_p + Vector2(5.0, 8.0), APRON_STRAP, 1.8)
	b.line(draw_p + Vector2(3.0, -3.0), draw_p + Vector2(7.0, -6.0), TROWEL_STEEL, 2.2)

	# Terracotta clay pot held in hands (facing west)
	var pot_held := draw_p + Vector2(-14.0 + wobble, 0.0)
	b.circle(pot_held + Vector2(1.0, 2.5), 8.0, SHADOW)
	b.circle(pot_held, 6.5, POT_DARK)
	b.circle(pot_held + Vector2(-0.5, -0.5), 5.5, POT_CLAY)
	b.circle(pot_held + Vector2(-0.5, -0.5), 4.2, SOIL_DARK)
	# Blooming rosette succulent
	b.circle(pot_held + Vector2(-0.5, -0.5), 3.2, SUCCULENT_GREEN)
	b.circle(pot_held + Vector2(-0.5, -0.5), 1.6, SUCCULENT_BLOSSOM)

	# Head & grey hair
	var head_p := draw_p + Vector2(1.5, -1.0)
	b.circle(head_p, 8.5, HAIR_GREY)
	b.circle(head_p + Vector2(-2.0, 0.0), 6.5, SKIN_TONE)

	# Wide straw sunhat with dark green band
	b.circle(head_p + Vector2(-0.5, -0.5), 9.2, HAT_STRAW)
	b.circle(head_p + Vector2(-0.5, -0.5), 7.4, HAT_BAND)
	b.circle(head_p + Vector2(-0.5, -0.5), 5.8, HAT_STRAW)
