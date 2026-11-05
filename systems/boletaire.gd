class_name Boletaire
extends RefCounted

# WALK 8: EL BOSC - MUSHROOM FORAGER ("EL BOLETAIRE") LIVE EVENT
# Signature telegraphed live event for El Bosc (Collserola pine woodland trail):
# A traditional Catalan mushroom hunter ("el boletaire") in a corduroy flat cap,
# flannel shirt, and hiking boots steps out from the pine grove at y = -1650.0 with
# a hazel walking stick, carrying a flat woven wicker basket full of freshly picked
# saffron milk cap mushrooms ("rovellons de pi") across the needle-strewn trail.
#
# Gameplay contract:
# - 0.8 s warning telegraph: When the pair reaches y = -1320.0, the forager calls
#   out from the western pine grove threshold at x = 380.0, y = -1650.0:
#   "Mireu quins rovellons!" with a telegraphed speech bubble and brush rustle.
# - Soft failure / hazard: Distracted human wandering into the forager's path
#   gets bumped (-8 patience drop, "Whoa! Watch the basket!",
#   forager: "Al tanto amb els bolets!").
# - Dog trick (rovelló snatch): As the forager strides across the trail (x >= 650.0),
#   a prize saffron milk cap ("rovelló") slips loose from the wicker basket onto
#   the pine needles; pouncing or booping it awards "rovelló snatch! +2" and
#   increments bones/combo (Forager: "Ei, el meu rovelló!").
# - Boop trick: Booping the forager directly awards "boletaire boop! +2"
#   ("Hola, gosset de bosc!").
# - Bark trick: Barking near the forager (within 130 px) causes him to stumble/wobble
#   in surprise, awarding "boletaire bark! +2" ("Ui, quin ensurt!").
# - Dodge save: Steering your human safely clear past the crossing trajectory after
#   entering threat radius (64 px) awards "bosc dodge! +2" and increments saves_done
#   via NearMiss.consider. Walking past outside threat radius awards nothing.
# - Autowalk: Timing naturally clears the trail center well before the autowalk pair
#   arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: Batched into El Bosc's ShapeBatch (draw_live).

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(380.0, -1650.0)
const END_POS := Vector2(920.0, -1650.0)
const CROSSING_Y := -1650.0
const TRIGGER_Y := -1320.0

const WARN_DURATION := 0.8
const WALK_SPEED := 180.0
const BUMP_RADIUS := 30.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const DROP_X := 650.0

enum State { IDLE, TELEGRAPH, WALKING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var mushroom_dropped: bool = false
var mushroom_snatched: bool = false
var mushroom_pos: Vector2 = Vector2.ZERO
var mushroom_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.04, 0.24)

# Attire & gear
const BOOTS_BROWN := Color(0.36, 0.24, 0.16)
const PANTS_OLIVE := Color(0.32, 0.38, 0.25)
const SHIRT_RED := Color(0.68, 0.24, 0.20)
const SHIRT_DARK := Color(0.48, 0.16, 0.14)
const CAP_BROWN := Color(0.48, 0.34, 0.22)
const BEARD_GREY := Color(0.78, 0.76, 0.74)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const STICK_WOOD := Color(0.55, 0.40, 0.25)

# Basket & Rovellons
const BASKET_WICKER := Color(0.72, 0.58, 0.38)
const BASKET_RIM := Color(0.54, 0.42, 0.26)
const MUSHROOM_ORANGE := Color(0.92, 0.48, 0.18)
const MUSHROOM_CORE := Color(0.75, 0.35, 0.12)
const MUSHROOM_STEM := Color(0.95, 0.82, 0.65)


func _init() -> void:
	_toss.seed = 0xB01E7


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	mushroom_dropped = false
	mushroom_snatched = false
	mushroom_pos = Vector2.ZERO
	mushroom_vel = Vector2.ZERO
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

	# Update dropped mushroom physics
	if mushroom_dropped and not mushroom_snatched:
		mushroom_pos += mushroom_vel * delta
		mushroom_vel = mushroom_vel.move_toward(Vector2.ZERO, 40.0 * delta)
		if dog_pos.distance_to(mushroom_pos) <= SNATCH_RADIUS:
			mushroom_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.WALKING) and not booped:
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
				state = State.WALKING
				timer = 0.0

		State.WALKING:
			anim_time += delta
			pos.x += WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 9.0) * 1.2

			# Drops a saffron milk cap near center trail
			if not mushroom_dropped and pos.x >= DROP_X:
				mushroom_dropped = true
				mushroom_pos = pos + Vector2(0.0, 10.0)
				mushroom_vel = Vector2(20.0, _toss.randf_range(-10.0, 10.0))

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
		var close := state == State.WALKING and pos.distance_to(human_pos) <= THREAT
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


func draw(_m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var b := ShapeBatch.new()
	var draw_pos := pos
	if wobble_t > 0.0:
		draw_pos.y += sin(wobble_t * 32.0) * 3.0

	# 1. Ground shadow
	b.circle(draw_pos + Vector2(1.0, 8.0), 16.0, SHADOW)

	# 2. Dropped rovelló mushroom (if dropped and not yet snatched)
	if mushroom_dropped and not mushroom_snatched:
		b.circle(mushroom_pos + Vector2(1.0, 1.5), 5.0, SHADOW)
		b.circle(mushroom_pos, 5.5, MUSHROOM_ORANGE)
		b.circle(mushroom_pos, 3.2, MUSHROOM_CORE)
		b.circle(mushroom_pos + Vector2(0.0, 1.0), 1.4, MUSHROOM_STEM)

	# 3. Boots & trousers
	var step_phase := sin(anim_time * 9.0)
	var left_foot := draw_pos + Vector2(-4.0 + step_phase * 4.0, 6.0)
	var right_foot := draw_pos + Vector2(4.0 - step_phase * 4.0, 6.0)
	b.circle(left_foot, 3.5, BOOTS_BROWN)
	b.circle(right_foot, 3.5, BOOTS_BROWN)
	b.rect(Rect2(draw_pos.x - 6.0, draw_pos.y - 2.0, 12.0, 8.0), PANTS_OLIVE)

	# 4. Flannel shirt torso
	b.circle(draw_pos + Vector2(0.0, -2.0), 8.5, SHIRT_RED)
	b.rect(Rect2(draw_pos.x - 6.0, draw_pos.y - 6.0, 12.0, 8.0), SHIRT_DARK)

	# 5. Head, beard & flat cap ("gorra de pana")
	b.circle(draw_pos + Vector2(0.0, -10.0), 5.5, SKIN_TONE)
	b.circle(draw_pos + Vector2(0.0, -8.0), 4.5, BEARD_GREY)
	b.circle(draw_pos + Vector2(0.0, -11.0), 5.8, CAP_BROWN)
	b.rect(Rect2(draw_pos.x + 1.0, draw_pos.y - 13.0, 4.0, 4.0), CAP_BROWN) # cap visor

	# 6. Walking stick in right hand (+Y)
	var hand_pos := draw_pos + Vector2(6.0, 1.0)
	b.circle(hand_pos, 2.2, SKIN_TONE)
	b.line(draw_pos + Vector2(8.0, -12.0), draw_pos + Vector2(9.0, 10.0), STICK_WOOD, 2.0)

	# 7. Wicker basket of rovellons carried on left arm (-Y)
	var basket_pos := draw_pos + Vector2(-6.0, -2.0)
	b.circle(basket_pos, 2.2, SKIN_TONE) # left hand
	b.circle(basket_pos + Vector2(-3.0, 0.0), 7.0, BASKET_RIM)
	b.circle(basket_pos + Vector2(-3.0, 0.0), 6.0, BASKET_WICKER)
	# Fresh orange saffron milk caps inside basket
	b.circle(basket_pos + Vector2(-4.0, -2.0), 2.8, MUSHROOM_ORANGE)
	b.circle(basket_pos + Vector2(-1.5, 1.0), 2.5, MUSHROOM_ORANGE)
	b.circle(basket_pos + Vector2(-5.0, 1.5), 2.2, MUSHROOM_CORE)

	b.flush(wc)
