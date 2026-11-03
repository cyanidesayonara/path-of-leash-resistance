class_name LuggageTrolley
extends RefCounted

# WALK 9 / 19: L'ESTACIÓ - RUNAWAY STATION LUGGAGE TROLLEY
# Signature live event for L'Estació: an overloaded station luggage trolley
# (carretó d'equipatges) slips away on the polished terrazzo concourse floor
# at y = -1210.0, rolling eastward across the concourse with a panicked traveler
# running frantically after it.
#
# Gameplay contract:
# - 0.8 s warning telegraph: traveler loses grip of the trolley at x = 330.0,
#   y = -1210.0, calling out "Atenció, el carretó!" with a speech bubble
#   and rattling casters.
# - Soft failure / hazard: distracted human wandering into the trolley crossing
#   zone gets bumped (patience drop, "Whoa! Watch the cart!").
# - Dog trick: booping or pouncing on the rolling cart / luggage awards
#   "trolley boop! +2". Barking near the runaway cart alerts the station and
#   awards "trolley bark! +2".
# - Dodge: guiding your human onto the moving walkway entrance (x in [570, 710])
#   or safely waiting / maneuvering past the roll trajectory earns
#   "concourse dodge! +2" / "Whew, close one!".
# - Autowalk: timing naturally clears the central walking line before the autowalk
#   pair arrives, ensuring 100% reliable automated soak / CI traversal.
# - Zero new draw calls: batched into ShapeBatch with L'Estació concourse.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(330.0, -1210.0)
const END_POS := Vector2(940.0, -1210.0)
const CROSSING_Y := -1210.0
const TRIGGER_Y := -1040.0

const WARN_DURATION := 0.8
const ROLL_SPEED := 260.0
const CHASER_SPEED := 180.0
const BUMP_RADIUS := 34.0
const THREAT := 68.0
const BOOP_RADIUS := 32.0
const BARK_RADIUS := 160.0

enum State { IDLE, TELEGRAPH, ROLLING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var chaser_pos: Vector2 = START_POS - Vector2(44.0, 0.0)
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var last_joint_idx: int = -1

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)
const CHROME_BRIGHT := Color(0.85, 0.87, 0.90)
const CHROME_MID := Color(0.62, 0.65, 0.70)
const CHROME_DARK := Color(0.38, 0.40, 0.44)
const HANDLE_RED := Color(0.84, 0.20, 0.18)
const WHEEL_BLACK := Color(0.18, 0.18, 0.20)
const WHEEL_HUB := Color(0.72, 0.74, 0.78)

# Luggage colors
const SUITCASE_NAVY := Color(0.18, 0.28, 0.52)
const SUITCASE_YELLOW := Color(0.92, 0.72, 0.18)
const SUITCASE_CORAL := Color(0.82, 0.26, 0.24)
const STRAP_BLACK := Color(0.14, 0.14, 0.16)
const BUCKLE_GOLD := Color(0.88, 0.74, 0.32)

# Passenger colors
const JACKET_TEAL := Color(0.20, 0.52, 0.56)
const PANTS_DARK := Color(0.22, 0.24, 0.28)
const SKIN_TONE := Color(0.84, 0.68, 0.56)
const HAIR_BROWN := Color(0.32, 0.22, 0.16)
const SHOE_BROWN := Color(0.40, 0.28, 0.20)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	chaser_pos = START_POS - Vector2(44.0, 0.0)
	triggered = false
	human_hit = false
	booped = false
	barked = false
	dodged = false
	threatened = false
	last_joint_idx = -1


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"roll": false,
		"clatter": false,
		"bump": false,
		"boop": false,
		"dodge": false,
	}

	match state:
		State.IDLE:
			if not triggered and (dog_pos.y < TRIGGER_Y or human_pos.y < TRIGGER_Y) and human_pos.y > CROSSING_Y:
				state = State.TELEGRAPH
				timer = WARN_DURATION
				triggered = true
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.ROLLING
				timer = 0.0
				out["roll"] = true

		State.ROLLING:
			timer += delta
			pos.x = minf(END_POS.x, pos.x + ROLL_SPEED * delta)
			chaser_pos.x = minf(END_POS.x - 38.0, chaser_pos.x + CHASER_SPEED * delta)

			# Clatter over terrazzo brass joints (every 132 px)
			var joint_idx := int(pos.x / 132.0)
			if joint_idx != last_joint_idx:
				last_joint_idx = joint_idx
				out["clatter"] = true

			# Check human hazard bump
			if not human_hit and absf(human_pos.y - CROSSING_Y) < BUMP_RADIUS and absf(human_pos.x - pos.x) < BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Check dog boop trick
			if not booped and dog_pos.distance_to(pos) < BOOP_RADIUS:
				booped = true
				out["boop"] = true

			if pos.x >= END_POS.x:
				state = State.SETTLED
				timer = 0.0

		State.SETTLED:
			timer += delta
			if chaser_pos.x < END_POS.x - 38.0:
				chaser_pos.x = minf(END_POS.x - 38.0, chaser_pos.x + CHASER_SPEED * delta)

			# Dog can still boop settled trolley once if not booped yet
			if not booped and dog_pos.distance_to(pos) < BOOP_RADIUS:
				booped = true
				out["boop"] = true

	_dodge(human_pos, out)
	return out


func _dodge(human_pos: Vector2, out: Dictionary) -> void:
	if state != State.ROLLING and state != State.SETTLED:
		return
	var close := state == State.ROLLING and pos.distance_to(human_pos) <= THREAT
	var step := NearMiss.consider(close, human_hit, threatened, dodged)
	threatened = bool(step["threatened"])
	if bool(step["dodge"]):
		dodged = true
		out["dodge"] = true


func on_bark(dog_pos: Vector2) -> bool:
	if state in [State.TELEGRAPH, State.ROLLING] and not barked:
		if dog_pos.distance_to(pos) < BARK_RADIUS or dog_pos.distance_to(chaser_pos) < BARK_RADIUS:
			barked = true
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var tremble := Vector2.ZERO
	if state == State.TELEGRAPH:
		tremble.x = sin(timer * 40.0) * 1.5
	elif state == State.ROLLING:
		tremble.y = sin(timer * 28.0) * 1.0

	var tp := pos + tremble
	var cp := chaser_pos

	# Ground shadows
	b.rect(Rect2(tp.x - 20.0 + 8.0, tp.y - 13.0 + 10.0, 40.0, 26.0), SHADOW)
	b.circle(cp + LIGHT * 4.0, 9.0, SHADOW)

	# --- Trolley Frame (Stainless tubular steel) ---
	# Base wire grid platform
	b.rect(Rect2(tp.x - 20.0, tp.y - 13.0, 40.0, 26.0), CHROME_DARK)
	b.rect(Rect2(tp.x - 18.0, tp.y - 11.0, 36.0, 22.0), CHROME_MID)
	b.rect(Rect2(tp.x - 17.0, tp.y - 10.0, 34.0, 20.0), CHROME_BRIGHT)

	# Deck cross wires
	for wire_k in range(4):
		var wx := tp.x - 14.0 + float(wire_k) * 9.0
		b.line(Vector2(wx, tp.y - 10.0), Vector2(wx, tp.y + 10.0), CHROME_DARK, 1.2)
	b.line(Vector2(tp.x - 16.0, tp.y), Vector2(tp.x + 16.0, tp.y), CHROME_DARK, 1.2)

	# Front curved basket bumper
	b.line(Vector2(tp.x + 18.0, tp.y - 12.0), Vector2(tp.x + 21.0, tp.y), CHROME_BRIGHT, 2.4)
	b.line(Vector2(tp.x + 21.0, tp.y), Vector2(tp.x + 18.0, tp.y + 12.0), CHROME_BRIGHT, 2.4)

	# Rear push handle with red/orange grip
	b.line(Vector2(tp.x - 20.0, tp.y - 13.0), Vector2(tp.x - 24.0, tp.y - 13.0), CHROME_MID, 2.5)
	b.line(Vector2(tp.x - 20.0, tp.y + 13.0), Vector2(tp.x - 24.0, tp.y + 13.0), CHROME_MID, 2.5)
	b.line(Vector2(tp.x - 24.0, tp.y - 13.0), Vector2(tp.x - 24.0, tp.y + 13.0), HANDLE_RED, 3.5)

	# Caster wheels (4 corner wheels)
	var wheel_offsets: Array[Vector2] = [
		Vector2(16.0, -12.0), Vector2(16.0, 12.0),
		Vector2(-16.0, -12.0), Vector2(-16.0, 12.0)
	]
	for wo: Vector2 in wheel_offsets:
		var wp := tp + wo
		b.circle(wp, 3.0, WHEEL_BLACK)
		b.circle(wp, 1.2, WHEEL_HUB)

	# --- Stacked Luggage ---
	var wobble := sin(timer * 28.0) * 1.5 if state == State.ROLLING else 0.0

	# 1. Base navy blue hard-shell suitcase
	var navy_rect := Rect2(tp.x - 14.0 + wobble, tp.y - 10.0, 26.0, 20.0)
	b.rect(navy_rect, SUITCASE_NAVY)
	b.rect(Rect2(navy_rect.position.x, navy_rect.position.y, navy_rect.size.x, 3.0), SUITCASE_NAVY.lightened(0.25))
	b.line(Vector2(navy_rect.position.x, navy_rect.get_center().y),
		Vector2(navy_rect.end.x, navy_rect.get_center().y), SUITCASE_NAVY.darkened(0.3), 1.2)
	# Corner bumpers
	for cx: float in [navy_rect.position.x, navy_rect.end.x - 3.0]:
		for cy: float in [navy_rect.position.y, navy_rect.end.y - 3.0]:
			b.rect(Rect2(cx, cy, 3.0, 3.0), CHROME_MID)

	# 2. Medium yellow hard-shell suitcase on top
	var yel_rect := Rect2(tp.x - 8.0 + wobble * 0.7, tp.y - 7.0, 18.0, 14.0)
	b.rect(yel_rect, SUITCASE_YELLOW)
	b.rect(Rect2(yel_rect.position.x, yel_rect.position.y, yel_rect.size.x, 2.5), SUITCASE_YELLOW.lightened(0.25))
	b.line(Vector2(yel_rect.position.x, yel_rect.get_center().y),
		Vector2(yel_rect.end.x, yel_rect.get_center().y), SUITCASE_YELLOW.darkened(0.25), 1.0)

	# 3. Small coral travel duffel / bag
	var coral_rect := Rect2(tp.x - 4.0 + wobble * 0.4, tp.y - 4.0, 11.0, 8.0)
	b.rect(coral_rect, SUITCASE_CORAL)
	b.rect(Rect2(coral_rect.position.x, coral_rect.position.y, coral_rect.size.x, 2.0), SUITCASE_CORAL.lightened(0.25))

	# Luggage strap & golden buckle
	b.line(Vector2(tp.x - 1.0 + wobble, tp.y - 10.0), Vector2(tp.x - 1.0 + wobble, tp.y + 10.0), STRAP_BLACK, 2.0)
	b.rect(Rect2(tp.x - 2.5 + wobble, tp.y - 2.0, 4.0, 4.0), BUCKLE_GOLD)

	# --- Chasing Passenger ---
	# Head & hair
	b.circle(cp, 7.5, HAIR_BROWN)
	b.circle(cp + Vector2(2.5, 0.0), 5.5, SKIN_TONE)

	# Torso & dark pants
	b.rect(Rect2(cp.x - 5.0, cp.y - 7.0, 10.0, 14.0), JACKET_TEAL)
	b.rect(Rect2(cp.x - 5.0, cp.y - 7.0, 3.0, 14.0), JACKET_TEAL.lightened(0.2))

	# Arms & animation based on state
	match state:
		State.TELEGRAPH:
			# Hands raised in panic!
			b.line(cp + Vector2(2.0, -6.0), cp + Vector2(8.0, -15.0), JACKET_TEAL, 2.5)
			b.line(cp + Vector2(2.0, 6.0), cp + Vector2(8.0, 15.0), JACKET_TEAL, 2.5)
			b.circle(cp + Vector2(9.0, -16.0), 2.5, SKIN_TONE)
			b.circle(cp + Vector2(9.0, 16.0), 2.5, SKIN_TONE)
			# Feet standing
			b.circle(cp + Vector2(-4.0, -5.0), 2.2, SHOE_BROWN)
			b.circle(cp + Vector2(-4.0, 5.0), 2.2, SHOE_BROWN)

		State.ROLLING:
			# Frantic forward reaching arms!
			b.line(cp + Vector2(3.0, -5.0), cp + Vector2(16.0, -3.0), JACKET_TEAL, 2.5)
			b.line(cp + Vector2(3.0, 5.0), cp + Vector2(16.0, 3.0), JACKET_TEAL, 2.5)
			b.circle(cp + Vector2(17.0, -3.0), 2.5, SKIN_TONE)
			b.circle(cp + Vector2(17.0, 3.0), 2.5, SKIN_TONE)
			# Running stride
			var leg_stride := sin(timer * 18.0) * 6.0
			b.circle(cp + Vector2(-4.0 + leg_stride, -5.0), 2.4, SHOE_BROWN)
			b.circle(cp + Vector2(-4.0 - leg_stride, 5.0), 2.4, SHOE_BROWN)

		State.SETTLED:
			# Hands resting on knees catching breath
			b.line(cp + Vector2(2.0, -5.0), cp + Vector2(10.0, -4.0), JACKET_TEAL, 2.5)
			b.line(cp + Vector2(2.0, 5.0), cp + Vector2(10.0, 4.0), JACKET_TEAL, 2.5)
			b.circle(cp + Vector2(11.0, -4.0), 2.5, SKIN_TONE)
			b.circle(cp + Vector2(11.0, 4.0), 2.5, SKIN_TONE)
			b.circle(cp + Vector2(-3.0, -5.0), 2.2, SHOE_BROWN)
			b.circle(cp + Vector2(-3.0, 5.0), 2.2, SHOE_BROWN)

		State.IDLE:
			# Standing by trolley handle
			b.line(cp + Vector2(2.0, -5.0), cp + Vector2(8.0, -4.0), JACKET_TEAL, 2.5)
			b.line(cp + Vector2(2.0, 5.0), cp + Vector2(8.0, 4.0), JACKET_TEAL, 2.5)
			b.circle(cp + Vector2(9.0, -4.0), 2.5, SKIN_TONE)
			b.circle(cp + Vector2(9.0, 4.0), 2.5, SKIN_TONE)
			b.circle(cp + Vector2(-4.0, -5.0), 2.2, SHOE_BROWN)
			b.circle(cp + Vector2(-4.0, 5.0), 2.2, SHOE_BROWN)
