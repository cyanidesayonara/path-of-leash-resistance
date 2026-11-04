class_name Scooter
extends RefCounted

# WALK 7: EL GÒTIC - VINTAGE VESPA COURIER LIVE EVENT
# Signature telegraphed live event for El Gòtic (the medieval Gothic Quarter):
# A classic seafoam-turquoise delivery scooter ("la Vespa del Gòtic") driven by a
# courier wearing an open-face helmet and windbreaker buzzes across the cobbled
# alleyway at y = -1720.0, cutting between two side passages with a leather mail
# satchel strapped to the rear rack.
#
# Gameplay contract:
# - 0.8 s warning telegraph: When the pair reaches y = -1400.0, the courier sounds
#   the two-tone scooter horn ("Bip-bip!") and calls out from the side archway:
#   "Pas a la Vespa!" with a telegraphed speech bubble.
# - Soft failure / hazard: Distracted human wandering into the scooter's crossing path
#   gets bumped (-8 patience drop, "Whoa! Watch the scooter!",
#   rider: "Atenció, que el carreró és estret!").
# - Dog trick (letter snatch): As the scooter crosses the center alley (x >= 660.0), a
#   stamped airmail letter slips loose from the mail satchel onto the setts;
#   pouncing or booping it awards "letter snatch! +2" and increments bones/combo
#   (Rider: "Gràcies pel correu!").
# - Boop trick: Booping the scooter directly awards "scooter boop! +2"
#   ("Hola, gosset!").
# - Bark trick: Barking near the scooter (within 130 px) causes the rider to brake
#   with a tyre screech, awarding "scooter bark! +2" ("Ui, quin fre!").
# - Dodge save: Steering your human safely clear past the crossing trajectory after
#   entering threat radius (64 px) awards "gòtic dodge! +2" and increments saves_done
#   via NearMiss.consider. Walking past outside threat radius awards nothing.
# - Autowalk: Timing naturally clears the narrow corridor well before the autowalk pair
#   arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: Batched into El Gòtic's ShapeBatch (draw_live).

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(400.0, -1720.0)
const END_POS := Vector2(960.0, -1720.0)
const CROSSING_Y := -1720.0
const TRIGGER_Y := -1400.0

const WARN_DURATION := 0.8
const WALK_SPEED := 230.0
const BUMP_RADIUS := 32.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const DROP_X := 660.0

enum State { IDLE, TELEGRAPH, DRIVING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var letter_dropped: bool = false
var letter_snatched: bool = false
var letter_pos: Vector2 = Vector2.ZERO
var letter_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.04, 0.06, 0.24)

# Vintage Vespa colors
const VESPA_TURQUOISE := Color(0.28, 0.64, 0.60)
const VESPA_DARK := Color(0.20, 0.48, 0.45)
const VESPA_HIGHLIGHT := Color(0.42, 0.78, 0.74)
const TYRE_BLACK := Color(0.12, 0.12, 0.14)
const CHROME := Color(0.85, 0.88, 0.92)
const SEAT_BLACK := Color(0.18, 0.18, 0.20)
const SATCHEL_BROWN := Color(0.52, 0.36, 0.22)
const SATCHEL_DARK := Color(0.38, 0.25, 0.15)
const HEADLIGHT_GLOW := Color(1.0, 0.98, 0.85)

# Rider attire
const JACKET_BEIGE := Color(0.72, 0.68, 0.62)
const HELMET_WHITE := Color(0.92, 0.92, 0.94)
const GOGGLES_DARK := Color(0.15, 0.15, 0.18)
const SKIN_TONE := Color(0.88, 0.72, 0.58)

# Airmail letter
const LETTER_CREAM := Color(0.96, 0.95, 0.90)
const STAMP_RED := Color(0.85, 0.22, 0.20)
const STAMP_BLUE := Color(0.20, 0.35, 0.75)


func _init() -> void:
	_toss.seed = 0x6071C


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	letter_dropped = false
	letter_snatched = false
	letter_pos = Vector2.ZERO
	letter_vel = Vector2.ZERO
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

	# Update dropped letter physics
	if letter_dropped and not letter_snatched:
		letter_pos += letter_vel * delta
		letter_vel = letter_vel.move_toward(Vector2.ZERO, 45.0 * delta)
		if dog_pos.distance_to(letter_pos) <= SNATCH_RADIUS:
			letter_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.DRIVING) and not booped:
		if dog_pos.distance_to(pos) <= BOOP_RADIUS:
			booped = true
			out["boop"] = true

	match state:
		State.IDLE:
			if not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CROSSING_Y:
				triggered = true
				state = State.TELEGRAPH
				timer = 0.0
				out["warn"] = true

		State.TELEGRAPH:
			timer += delta
			anim_time += delta
			if timer >= WARN_DURATION:
				state = State.DRIVING
				timer = 0.0

		State.DRIVING:
			anim_time += delta
			pos.x += WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 14.0) * 0.8

			# Drops a stamped airmail letter near center alley
			if not letter_dropped and pos.x >= DROP_X:
				letter_dropped = true
				letter_pos = pos + Vector2(0.0, 10.0)
				letter_vel = Vector2(24.0, _toss.randf_range(-12.0, 12.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			anim_time += delta

	if state == State.DRIVING or state == State.SETTLED:
		var close := state == State.DRIVING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = step["threatened"]
		if step["dodge"]:
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if (state == State.TELEGRAPH or state == State.DRIVING) and not barked:
		if bark_pos.distance_to(pos) <= BARK_RADIUS:
			barked = true
			wobble_t = 0.5
			return true
	return false


func draw(_m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var b := ShapeBatch.new()
	var draw_pos := pos
	if wobble_t > 0.0:
		draw_pos.y += sin(wobble_t * 32.0) * 3.0

	# 1. Ground shadow
	b.circle(draw_pos + Vector2(1.0, 10.0), 22.0, SHADOW)
	b.rect(Rect2(draw_pos.x - 18.0, draw_pos.y - 7.0, 38.0, 15.0), SHADOW)

	# 2. Dropped airmail letter (if dropped and not yet snatched)
	if letter_dropped and not letter_snatched:
		b.rect(Rect2(letter_pos.x - 6.0 + 1.0, letter_pos.y - 4.0 + 1.0, 12.0, 8.0), SHADOW)
		b.rect(Rect2(letter_pos.x - 6.0, letter_pos.y - 4.0, 12.0, 8.0), LETTER_CREAM)
		b.rect(Rect2(letter_pos.x + 2.0, letter_pos.y - 3.5, 3.0, 3.0), STAMP_RED)
		b.line(letter_pos + Vector2(-5.0, 2.0), letter_pos + Vector2(3.0, 2.0), STAMP_BLUE, 1.0)

	# 3. Scooter wheels (front +X, rear -X)
	b.rect(Rect2(draw_pos.x + 12.0, draw_pos.y - 3.5, 9.0, 7.0), TYRE_BLACK)
	b.rect(Rect2(draw_pos.x + 14.0, draw_pos.y - 2.0, 5.0, 4.0), CHROME)
	b.rect(Rect2(draw_pos.x - 18.0, draw_pos.y - 3.5, 9.0, 7.0), TYRE_BLACK)
	b.rect(Rect2(draw_pos.x - 16.0, draw_pos.y - 2.0, 5.0, 4.0), CHROME)

	# 4. Classic curved Vespa body & side cowls
	# Rear curved body & teardrop cowls
	b.circle(draw_pos + Vector2(-10.0, 0.0), 10.0, VESPA_DARK)
	b.circle(draw_pos + Vector2(-9.0, 0.0), 9.0, VESPA_TURQUOISE)
	b.rect(Rect2(draw_pos.x - 12.0, draw_pos.y - 5.0, 18.0, 10.0), VESPA_TURQUOISE)
	# Floorboard
	b.rect(Rect2(draw_pos.x - 4.0, draw_pos.y - 4.0, 10.0, 8.0), VESPA_DARK)
	# Curved front legshield
	b.rect(Rect2(draw_pos.x + 6.0, draw_pos.y - 7.0, 4.0, 14.0), VESPA_TURQUOISE)
	b.line(draw_pos + Vector2(6.0, -7.0), draw_pos + Vector2(6.0, 7.0), CHROME, 1.5)

	# 5. Contoured leather seat
	b.rect(Rect2(draw_pos.x - 10.0, draw_pos.y - 4.0, 12.0, 8.0), SEAT_BLACK)

	# 6. Rear luggage rack & leather mail courier satchel
	b.line(draw_pos + Vector2(-14.0, -5.0), draw_pos + Vector2(-14.0, 5.0), CHROME, 1.5)
	b.rect(Rect2(draw_pos.x - 19.0, draw_pos.y - 5.0, 6.0, 10.0), SATCHEL_BROWN)
	b.rect(Rect2(draw_pos.x - 18.0, draw_pos.y - 4.0, 4.0, 8.0), SATCHEL_DARK)

	# 7. Courier rider
	# Torso in beige jacket
	b.circle(draw_pos + Vector2(-3.0, 0.0), 7.0, JACKET_BEIGE)
	# Head with vintage white helmet
	b.circle(draw_pos + Vector2(-1.0, 0.0), 5.5, HELMET_WHITE)
	b.line(draw_pos + Vector2(-4.0, 0.0), draw_pos + Vector2(2.0, 0.0), VESPA_TURQUOISE, 1.5) # helmet racing stripe
	b.rect(Rect2(draw_pos.x + 1.0, draw_pos.y - 3.5, 2.5, 7.0), GOGGLES_DARK) # goggles
	# Hands on handlebars
	b.circle(draw_pos + Vector2(6.0, -5.0), 2.2, SKIN_TONE)
	b.circle(draw_pos + Vector2(6.0, 5.0), 2.2, SKIN_TONE)

	# 8. Front chrome handlebars & headlight
	b.line(draw_pos + Vector2(6.0, -6.0), draw_pos + Vector2(6.0, 6.0), CHROME, 2.0)
	# Round headlight
	b.circle(draw_pos + Vector2(10.0, 0.0), 3.5, CHROME)
	b.circle(draw_pos + Vector2(10.0, 0.0), 2.5, HEADLIGHT_GLOW)

	b.flush(wc)
