class_name ForumSkater
extends RefCounted

# WALK 30: EL FÒRUM - EL SKATER DE L'ESPLANADA LIVE EVENT
#
# A street trick skateboarder in oversized hoodie and backward cap practicing
# lines across the wide concrete esplanade at Parc del Fòrum.
#
# Event timeline & choreography:
# 1. IDLE: Waits on the western side of the esplanade at x = 390.0, y = -2150.0.
# 2. TELEGRAPH: When dog or human approaches within 180 px from south (y >= -2330.0):
#    - 0.8 s warning telegraph: loud wheel clatter and shout
#      ("Watch the board!" / "Compte amb el patí!").
# 3. SKATING: Skates across the esplanade toward the sea wall at 220 px/s:
#    - Distracted human bump hazard: -8 patience drop on collision.
#    - Skateboard boop trick: dog boops the board directly for "board boop! +2".
#    - Dropped energy bar snack: fresh snack packet drops at center path (x = 640.0)
#      for "snack snatch! +2".
#    - Skater cheer on bark: barking within 140 px prompts a kickflip and "Yeah! +2".
#    - Near-miss dodge save: NearMiss.consider triggers "forum dodge! +2".
# 4. SETTLED: Comes to a halt beside the sea wall at x = 890.0, holding the board.
#
# Performance contract:
# - Zero new draw calls: batched via Forum's live ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const NearMiss := preload("res://systems/near_miss.gd")

enum State { IDLE, TELEGRAPH, SKATING, SETTLED }

const CROSSING_Y := -2150.0
const START_POS := Vector2(390.0, CROSSING_Y)
const END_POS := Vector2(890.0, CROSSING_Y)
const SPEED := 220.0
const TELEGRAPH_TIME := 0.8

# Visual colors
const HOODIE_TEAL := Color(0.18, 0.58, 0.64)
const CAP_BLACK := Color(0.12, 0.12, 0.14)
const PANTS_GREY := Color(0.32, 0.32, 0.36)
const DECK_MAPLE := Color(0.82, 0.64, 0.44)
const GRIP_TAPE := Color(0.16, 0.16, 0.18)
const WHEELS_URETHANE := Color(0.92, 0.90, 0.82)
const SNACK_WRAPPER := Color(0.95, 0.72, 0.18)

var state: State = State.IDLE
var pos: Vector2 = START_POS
var telegraph_t: float = 0.0
var roll_phase: float = 0.0

var human_hit: bool = false
var booped: bool = false
var snack_dropped: bool = false
var snack_taken: bool = false
var snack_pos := Vector2(640.0, CROSSING_Y)
var cheered: bool = false
var threatened: bool = false
var dodge_done: bool = false


func reset() -> void:
	state = State.IDLE
	pos = START_POS
	telegraph_t = 0.0
	roll_phase = 0.0
	human_hit = false
	booped = false
	snack_dropped = false
	snack_taken = false
	cheered = false
	threatened = false
	dodge_done = false


func tick(delta: float, dog_pos: Vector2, dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"telegraph": false,
		"bump_hazard": false,
		"snack_available": false,
		"snack_snatched": false,
		"boop": false,
		"cheer": false,
		"dodge_save": false,
	}

	match state:
		State.IDLE:
			var trig_dist: float = minf(dog_pos.distance_to(pos), human_pos.distance_to(pos))
			if trig_dist < 185.0 or (human_pos.y > CROSSING_Y and human_pos.y < CROSSING_Y + 160.0 and absf(human_pos.x - 640.0) < 220.0):
				state = State.TELEGRAPH
				telegraph_t = 0.0
				out["telegraph"] = true

		State.TELEGRAPH:
			telegraph_t += delta
			if telegraph_t >= TELEGRAPH_TIME:
				state = State.SKATING
				snack_dropped = true

		State.SKATING:
			pos.x += SPEED * delta
			roll_phase += delta * 18.0

			# Distracted human hazard
			if not human_hit and human_pos.distance_to(pos) < 26.0:
				human_hit = true
				out["bump_hazard"] = true

			# Board boop trick
			if not booped and dog_pos.distance_to(pos) < 28.0:
				booped = true
				out["boop"] = true

			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	# Near-miss dodge save
	if state == State.SKATING or state == State.SETTLED:
		var close: bool = state == State.SKATING and pos.distance_to(human_pos) <= 60.0
		var nm: Dictionary = NearMiss.consider(close, human_hit, threatened, dodge_done)
		threatened = bool(nm["threatened"])
		if bool(nm["dodge"]):
			dodge_done = true
			out["dodge_save"] = true

	# Dropped snack packet interactions
	if snack_dropped and not snack_taken:
		out["snack_available"] = true
		if dog_pos.distance_to(snack_pos) < 24.0:
			snack_taken = true
			out["snack_snatched"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if state == State.SKATING or state == State.SETTLED:
		if not cheered and bark_pos.distance_to(pos) < 140.0:
			cheered = true
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)

	# 1. Dropped snack packet
	if snack_dropped and not snack_taken:
		b.rect(Rect2(snack_pos + Vector2(2, 3), Vector2(14, 8)), sh)
		b.rect(Rect2(snack_pos, Vector2(14, 8)), SNACK_WRAPPER)
		b.rect(Rect2(snack_pos + Vector2(2, 2), Vector2(10, 4)), Color(0.20, 0.45, 0.85))

	# 2. Skateboarder & Deck
	var is_skating: bool = (state == State.SKATING)
	var lean_offset: float = sin(roll_phase) * 2.0 if is_skating else 0.0

	# Shadow
	b.circle(pos + Vector2(2, 6), 14.0, sh)

	if state == State.SETTLED:
		# Resting pose holding deck vertically
		b.circle(pos + Vector2(0, -6), 9.0, PANTS_GREY)
		b.circle(pos + Vector2(0, -14), 10.0, HOODIE_TEAL)
		b.circle(pos + Vector2(0, -22), 6.5, Color(0.88, 0.72, 0.58))
		b.circle(pos + Vector2(0, -23), 7.0, CAP_BLACK)
		# Held vertical deck
		b.rect(Rect2(pos + Vector2(7, -24), Vector2(5, 26)), DECK_MAPLE)
		b.rect(Rect2(pos + Vector2(7, -24), Vector2(2, 26)), GRIP_TAPE)
		return

	# Skateboard Deck (horizontal rolling)
	var deck_y: float = pos.y + 4.0
	b.rect(Rect2(pos.x - 16.0, deck_y, 32.0, 7.0), DECK_MAPLE)
	b.rect(Rect2(pos.x - 15.0, deck_y + 1.0, 30.0, 5.0), GRIP_TAPE)

	# Wheels
	var wheel_rot: float = sin(roll_phase * 2.0) * 1.5
	b.circle(Vector2(pos.x - 11.0, deck_y + 7.0 + wheel_rot), 2.5, WHEELS_URETHANE)
	b.circle(Vector2(pos.x + 11.0, deck_y + 7.0 - wheel_rot), 2.5, WHEELS_URETHANE)

	# Skater Body in sideways stance
	var hip_pos := pos + Vector2(lean_offset, -4.0)
	var torso_pos := hip_pos + Vector2(0.0, -9.0)
	var head_pos := torso_pos + Vector2(1.0, -8.0)

	# Baggy pants & legs
	b.circle(hip_pos + Vector2(-6.0, 2.0), 4.5, PANTS_GREY)
	b.circle(hip_pos + Vector2(6.0, 2.0), 4.5, PANTS_GREY)

	# Hoodie Torso
	b.circle(torso_pos, 8.5, HOODIE_TEAL)
	b.circle(torso_pos + Vector2(-5.0, -1.0), 4.0, HOODIE_TEAL.darkened(0.15))
	b.circle(torso_pos + Vector2(5.0, -1.0), 4.0, HOODIE_TEAL.lightened(0.12))

	# Head and backward cap
	b.circle(head_pos, 5.5, Color(0.88, 0.72, 0.58))
	b.circle(head_pos + Vector2(0.0, -1.5), 6.0, CAP_BLACK)
	# Cap visor turned backward
	b.rect(Rect2(head_pos.x - 8.0, head_pos.y - 3.5, 4.0, 2.0), CAP_BLACK.darkened(0.2))
