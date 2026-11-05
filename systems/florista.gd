class_name Florista
extends RefCounted

# LA FLORISTA DE LA RAMBLA (La Rambla live event)
#
# A Barcelona florist in a dark-green apron and straw sunhat carrying a wooden
# tray of fresh red roses ("les roses de la Rambla") crosses the central
# promenade at y = -2980.0 between flower kiosks.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -2660.0), calls out
#   "Flors fresques de la Rambla!" with a floral rustle sound.
# - Distracted human bump hazard: -8 patience drop, "Whoa! Watch the flowers!",
#   florista: "Ai, les meves roses!".
# - Near-miss dodge save: NearMiss.consider awards "rambla dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
#   Walking past without near miss awards nothing.
# - Dropped rose snatch trick: a cut red rose slips from the tray at center
#   promenade (x >= 630.0). Dog can snatch it for "rose snatch! +2".
# - Direct boop trick: booping the florist awards "florista boop! +2".
# - Bark trick: barking within 130 px startles her into a flower wobble for "florista bark! +2".
# - Autowalk clearance: passes well before autowalk pair arrives.
# - Zero new draw calls: batched into La Rambla's live ShapeBatch in _draw_rambla.
# - Independent RNG sequence, zero mutation of rope physics.

enum State {
	IDLE,
	TELEGRAPH,
	WALKING,
	SETTLED,
}

const START_POS := Vector2(380.0, -2980.0)
const END_POS := Vector2(890.0, -2980.0)
const CROSSING_Y := -2980.0
const TRIGGER_Y := -2660.0
const DROP_X := 630.0
const WALK_SPEED := 210.0
const WARN_DURATION := 0.8

const BUMP_RADIUS := 25.0
const THREAT_RADIUS := 68.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const SNATCH_RADIUS := 26.0

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var rose_dropped: bool = false
var rose_snatched: bool = false
var rose_pos: Vector2 = Vector2.ZERO
var rose_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Attire & floral colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const HAT_STRAW := Color(0.88, 0.78, 0.52)
const HAT_BAND := Color(0.24, 0.48, 0.28)
const APRON_GREEN := Color(0.20, 0.42, 0.26)
const APRON_TIE := Color(0.14, 0.32, 0.18)
const DRESS_CREAM := Color(0.92, 0.88, 0.82)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_BROWN := Color(0.38, 0.24, 0.16)
const TRAY_WOOD := Color(0.70, 0.52, 0.36)
const TRAY_EDGE := Color(0.52, 0.38, 0.24)
const ROSE_RED := Color(0.88, 0.16, 0.22)
const ROSE_DARK := Color(0.68, 0.10, 0.16)
const ROSE_LEAF := Color(0.28, 0.58, 0.24)
const ROSE_STEM := Color(0.20, 0.44, 0.18)


func _init() -> void:
	_toss.seed = 0xF10815  # FLORIS


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	rose_dropped = false
	rose_snatched = false
	rose_pos = Vector2.ZERO
	rose_vel = Vector2.ZERO
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

	# Update dropped rose physics
	if rose_dropped and not rose_snatched:
		rose_pos += rose_vel * delta
		rose_vel = rose_vel.move_toward(Vector2.ZERO, 45.0 * delta)
		if dog_pos.distance_to(rose_pos) <= SNATCH_RADIUS:
			rose_snatched = true
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
			pos.x += WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 8.0) * 1.5

			# Drops a red rose near center promenade
			if not rose_dropped and pos.x >= DROP_X:
				rose_dropped = true
				rose_pos = pos + Vector2(0.0, 8.0)
				rose_vel = Vector2(25.0, _toss.randf_range(-12.0, 12.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x >= END_POS.x:
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

	# Draw dropped rose on pavement if loose
	if rose_dropped and not rose_snatched:
		b.circle(rose_pos + Vector2(2.0, 3.0), 6.0, SHADOW)
		# Stem and leaves
		b.line(rose_pos + Vector2(-6.0, 3.0), rose_pos + Vector2(6.0, -2.0), ROSE_STEM, 1.8)
		b.circle(rose_pos + Vector2(-2.0, 2.0), 3.0, ROSE_LEAF)
		b.circle(rose_pos + Vector2(2.0, -1.0), 2.5, ROSE_LEAF)
		# Red petals
		b.circle(rose_pos + Vector2(5.0, -2.0), 4.5, ROSE_DARK)
		b.circle(rose_pos + Vector2(4.5, -2.5), 3.8, ROSE_RED)
		b.circle(rose_pos + Vector2(3.8, -3.2), 2.0, Color(1.0, 0.35, 0.40))

	# Florist character drawing
	var wobble := sin(anim_time * 16.0) * 4.0 if wobble_t > 0.0 else 0.0
	var bob := sin(anim_time * 8.0) * 1.5 if state == State.WALKING else 0.0
	var draw_p := pos + Vector2(0.0, bob)

	# Shadow
	b.circle(draw_p + Vector2(2.0, 4.0), 16.0, SHADOW)

	# Dress & dark green apron
	b.circle(draw_p, 13.0, DRESS_CREAM)
	b.circle(draw_p + Vector2(2.0, 0.0), 11.5, APRON_GREEN)
	b.line(draw_p + Vector2(-3.0, -8.0), draw_p + Vector2(5.0, -8.0), APRON_TIE, 2.0)
	b.line(draw_p + Vector2(-4.0, 8.0), draw_p + Vector2(5.0, 8.0), APRON_TIE, 2.0)

	# Wooden flower tray carried forward
	var tray_center := draw_p + Vector2(10.0 + wobble, 0.0)
	b.rect(Rect2(tray_center - Vector2(8.0, 12.0), Vector2(16.0, 24.0)), TRAY_EDGE)
	b.rect(Rect2(tray_center - Vector2(7.0, 11.0), Vector2(14.0, 22.0)), TRAY_WOOD)

	# Red roses and leaves inside the wooden tray
	var rose_offsets := [
		Vector2(-3.0, -6.0), Vector2(2.0, -5.0),
		Vector2(-2.0, 0.0), Vector2(3.0, 1.0),
		Vector2(-3.0, 6.0), Vector2(2.0, 5.0)
	]
	for ro: Vector2 in rose_offsets:
		var rp := tray_center + ro
		b.circle(rp + Vector2(-1.0, 0.0), 2.2, ROSE_LEAF)
		b.circle(rp, 3.2, ROSE_DARK)
		b.circle(rp + Vector2(-0.5, -0.5), 2.4, ROSE_RED)

	# Head & hair
	var head_p := draw_p + Vector2(-2.0, -1.0)
	b.circle(head_p, 8.5, HAIR_BROWN)
	b.circle(head_p + Vector2(2.0, 0.0), 6.5, SKIN_TONE)

	# Straw sunhat with green band
	b.circle(head_p + Vector2(0.5, -0.5), 9.0, HAT_STRAW)
	b.circle(head_p + Vector2(0.5, -0.5), 7.2, HAT_BAND)
	b.circle(head_p + Vector2(0.5, -0.5), 5.6, HAT_STRAW)
