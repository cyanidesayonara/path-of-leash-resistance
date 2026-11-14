class_name ConeDog
extends RefCounted

# WALK 20: EL VETERINARI - RUNAWAY CONE-OF-SHAME DOG & DROPPED TREAT
# Signature live event for El Veterinari (the vet clinic):
# A panicked little dog wearing an oversized translucent white Elizabethan
# collar (el gos amb con de vergonya / campana d'Elisabet) bursts out of
# Radiografia at y = -2180.0, scrambling frantically across the slippery
# linoleum corridor towards the east waiting chairs.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Radiografia door rattles ajar at x = 360.0, y = -2200.0,
#   and a vet nurse in clinical teal scrubs pops out with a clipboard waving
#   frantically and shouting "Cone dog on the loose!" with a speech bubble.
# - Soft failure / hazard: distracted human wandering into the cone dog's trajectory
#   gets bumped by the wide plastic cone (-8 patience drop, "Ow, that cone is hard!").
# - Dog trick: as the pup scrambles across the linoleum, a savory clinic treat
#   (bacon pill pocket) drops from its mouth; pouncing or booping it awards
#   "treat snatch! +2".
# - Bark trick: barking near the crossing cone dog startles it into a comic skid
#   and pirouette, awarding "cone bark! +2" (muffled "Yip!").
# - Boop trick: booping the cone directly awards "cone boop! +2".
# - Dodge: steering your human safely clear past the crossing trajectory
#   awards "clinic dodge! +2" / "Whew, nice dodge!".
# - Autowalk: timing naturally clears the center line (x = 640.0) before the
#   autowalk pair arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched into El Veterinari's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(360.0, -2180.0)
const END_POS := Vector2(885.0, -2180.0)
const CROSSING_Y := -2180.0
const TRIGGER_Y := -2000.0

const WARN_DURATION := 0.8
const RUN_SPEED := 185.0
const BUMP_RADIUS := 32.0
const THREAT := 64.0
const DOOR := Vector2(360.0, -2200.0)
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 26.0
const BARK_RADIUS := 140.0
const TREAT_DROP_X := 530.0

enum State { IDLE, TELEGRAPH, RUNNING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var treat_dropped: bool = false
var treat_snatched: bool = false
var treat_pos: Vector2 = Vector2.ZERO
var treat_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var anim_time: float = 0.0
var _toss := RandomNumberGenerator.new()

# Visual colors
const SHADOW := Color(0.04, 0.05, 0.08, 0.20)

# Dog colors
const COAT_FAWN := Color(0.82, 0.62, 0.38)
const COAT_DARK := Color(0.55, 0.36, 0.20)
const BELLY_CREAM := Color(0.92, 0.85, 0.72)
const NOSE_BLACK := Color(0.12, 0.10, 0.10)

# Cone of shame
const CONE_WHITE := Color(0.95, 0.97, 1.0, 0.85)
const CONE_RIM := Color(0.85, 0.90, 0.98, 0.95)
const CONE_SHADE := Color(0.75, 0.82, 0.92, 0.50)
const COLLAR_BLUE := Color(0.20, 0.45, 0.85)

# Vet Nurse
const SCRUB_TEAL := Color(0.20, 0.65, 0.60)
const PANTS_WHITE := Color(0.95, 0.95, 0.95)
const HAIR_BROWN := Color(0.35, 0.22, 0.15)
const SKIN_TONE := Color(0.88, 0.72, 0.60)
const CLIPBOARD_WOOD := Color(0.70, 0.55, 0.38)
const CLIPBOARD_PAPER := Color(0.98, 0.98, 0.96)

# Dropped Treat (Bacon Pill Pocket)
const TREAT_BROWN := Color(0.62, 0.32, 0.22)
const TREAT_TAN := Color(0.88, 0.78, 0.58)


func _init() -> void:
	# its own sequence: a treat's scatter must not shift the walk's rng
	_toss.seed = 0xC0E1D06


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	treat_dropped = false
	treat_snatched = false
	treat_pos = Vector2.ZERO
	treat_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"scuffle": false,
		"bump": false,
		"boop": false,
		"drop_treat": false,
		"snatch": false,
		"dodge": false,
	}

	anim_time += delta

	# Dropped treat physics
	if treat_dropped and not treat_snatched:
		if treat_vel.length() > 2.0:
			treat_pos += treat_vel * delta
			treat_vel = treat_vel.move_toward(Vector2.ZERO, 90.0 * delta)
		if dog_pos.distance_to(treat_pos) < SNATCH_RADIUS:
			treat_snatched = true
			out["snatch"] = true

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
				state = State.RUNNING
				out["scuffle"] = true

		State.RUNNING:
			pos.x += RUN_SPEED * delta

			# Drop treat as dog reaches central floor
			if not treat_dropped and pos.x >= TREAT_DROP_X:
				treat_dropped = true
				treat_pos = pos + Vector2(2.0, 4.0)
				treat_vel = Vector2(50.0, _toss.randf_range(-15.0, 15.0))
				out["drop_treat"] = true

			# Soft bump on distracted human
			if not human_hit and human_pos.distance_to(pos) < BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Dog boop on cone dog
			if not booped and dog_pos.distance_to(pos) < BOOP_RADIUS:
				booped = true
				out["boop"] = true

			# Reached east side
			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	if state == State.RUNNING or state == State.SETTLED:
		var close := state == State.RUNNING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if state == State.RUNNING and not barked and pos.distance_to(bark_pos) < BARK_RADIUS:
		barked = true
		return true
	return false


# Vector art batched into El Veterinari's existing ShapeBatch
func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "vet":
		return

	# Only draw if within vertical view span
	if CROSSING_Y < vt - 120.0 or CROSSING_Y > vb + 120.0:
		return

	# 1. Radiografia door swung open when triggered
	if state != State.IDLE:
		var dp := DOOR
		# Open door opening (interior dark hallway)
		b.rect(Rect2(dp.x - 30.0, dp.y - 35.0, 28.0, 70.0), Color(0.15, 0.18, 0.20))
		# Door panel angled open into hallway
		b.rect(Rect2(dp.x - 24.0, dp.y - 32.0, 8.0, 64.0), Color(0.58, 0.42, 0.30))

		# Vet nurse standing at the doorway
		var np := Vector2(dp.x - 12.0, dp.y + 10.0)
		b.circle(np + Shade.light * 4.0, 10.0, SHADOW)
		# scrub top & trousers
		b.circle(np + Vector2(0.0, -8.0), 7.0, SCRUB_TEAL)
		b.rect(Rect2(np.x - 6.0, np.y - 8.0, 12.0, 14.0), SCRUB_TEAL)
		b.rect(Rect2(np.x - 5.0, np.y + 6.0, 4.0, 10.0), PANTS_WHITE)
		b.rect(Rect2(np.x + 1.0, np.y + 6.0, 4.0, 10.0), PANTS_WHITE)
		# nurse head & hair
		b.circle(np + Vector2(0.0, -14.0), 5.5, SKIN_TONE)
		b.circle(np + Vector2(0.0, -16.0), 4.5, HAIR_BROWN)
		# clipboard
		b.rect(Rect2(np.x + 4.0, np.y - 6.0, 7.0, 10.0), CLIPBOARD_WOOD)
		b.rect(Rect2(np.x + 5.0, np.y - 5.0, 5.0, 8.0), CLIPBOARD_PAPER)

	# 2. Dropped treat on linoleum floor
	if treat_dropped and not treat_snatched:
		b.circle(treat_pos + Shade.light * 2.0, 4.0, SHADOW)
		b.circle(treat_pos, 4.2, TREAT_BROWN)
		b.circle(treat_pos, 2.4, TREAT_TAN)
		b.circle(treat_pos + Vector2(1.0, -1.0), 1.0, Color(0.95, 0.45, 0.35))

	# 3. Cone Dog
	if state == State.RUNNING or state == State.SETTLED or state == State.TELEGRAPH:
		var dp := pos
		var wobble: float = sin(anim_time * 22.0) if state == State.RUNNING else 0.0
		var scramble: float = cos(anim_time * 28.0) if state == State.RUNNING else 0.0

		# Shadow on glossy linoleum
		b.circle(dp + Shade.light * 5.0, 14.0, SHADOW)

		# Scrambling paws with comic motion lines
		var paw_col := BELLY_CREAM
		var p1 := dp + Vector2(-6.0 + scramble * 4.0, -8.0)
		var p2 := dp + Vector2(8.0 - scramble * 4.0, -8.0)
		var p3 := dp + Vector2(-6.0 - scramble * 4.0, 8.0)
		var p4 := dp + Vector2(8.0 + scramble * 4.0, 8.0)
		b.circle(p1, 2.5, paw_col)
		b.circle(p2, 2.5, paw_col)
		b.circle(p3, 2.5, paw_col)
		b.circle(p4, 2.5, paw_col)

		if state == State.RUNNING:
			# subtle slippery floor scratch lines behind paws
			b.line(dp - Vector2(16.0, -2.0), dp - Vector2(8.0, -2.0), Color(0.92, 0.96, 0.95, 0.5), 1.2)
			b.line(dp - Vector2(18.0, 4.0), dp - Vector2(10.0, 4.0), Color(0.92, 0.96, 0.95, 0.5), 1.2)

		# Dog body (fawn coat)
		b.circle(dp, 9.0, COAT_FAWN)
		b.rect(Rect2(dp.x - 10.0, dp.y - 6.0, 14.0, 12.0), COAT_FAWN)
		b.circle(dp + Vector2(3.0, 0.0), 7.5, COAT_FAWN)

		# Tiny perky wagging tail
		var tail_wobble: float = sin(anim_time * 30.0) * 4.0 if state == State.RUNNING else 0.0
		b.line(dp - Vector2(10.0, 0.0), dp - Vector2(18.0, tail_wobble), COAT_DARK, 2.5)

		# Head with brown ears
		var head_p := dp + Vector2(8.0, wobble * 2.0)
		b.circle(head_p, 6.5, COAT_FAWN)
		b.circle(head_p + Vector2(-2.0, -6.0), 3.0, COAT_DARK)
		b.circle(head_p + Vector2(-2.0, 6.0), 3.0, COAT_DARK)
		b.circle(head_p + Vector2(5.0, 0.0), 2.2, NOSE_BLACK)

		# Giant Elizabethan Collar (Cone of Shame!)
		# The cone flares wide towards the east (+x)
		var collar_p := head_p + Vector2(2.0, 0.0)
		b.circle(collar_p, 5.0, COLLAR_BLUE)

		# The flared translucent cone
		var cone_pts: PackedVector2Array = [
			collar_p + Vector2(0.0, -5.0),
			collar_p + Vector2(16.0, -17.0 + wobble * 3.0),
			collar_p + Vector2(18.0, wobble * 3.0),
			collar_p + Vector2(16.0, 17.0 + wobble * 3.0),
			collar_p + Vector2(0.0, 5.0),
		]
		b.polygon(cone_pts, CONE_WHITE)
		b.line(collar_p + Vector2(16.0, -17.0 + wobble * 3.0), collar_p + Vector2(16.0, 17.0 + wobble * 3.0), CONE_RIM, 2.0)
		b.line(collar_p + Vector2(0.0, -5.0), collar_p + Vector2(16.0, -17.0 + wobble * 3.0), CONE_SHADE, 1.2)
		b.line(collar_p + Vector2(0.0, 5.0), collar_p + Vector2(16.0, 17.0 + wobble * 3.0), CONE_SHADE, 1.2)
