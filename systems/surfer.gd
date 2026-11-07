class_name Surfer
extends RefCounted

# WALK 24: PLATJA DE LLEVANT - BEACH SURFER LIVE EVENT
# Signature live event for Platja de Llevant (the dog beach at the far end of the coast):
# An energetic local surfer (el surfista de Llevant) wearing vibrant boardshorts
# and white zinc sunscreen carries a colorful 9-foot longboard under their arm,
# rushing westbound from the esplanade towards the stone coastal groin at y = -2140.0
# to paddle out into the Mediterranean surf.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Surfer steps out from the promenade pergola edge
#   at x = 880.0, y = -2140.0, balancing the surfboard and calling out
#   "Surfboard coming through!" with a telegraphed speech bubble.
# - Soft failure / hazard: distracted human wandering into the surfer's path
#   gets bumped by the surfboard nose (-8 patience drop, "Ow! Was that a surfboard?").
# - Dog trick: as the surfer crosses past the center esplanade (x <= 610.0), a chilled
#   wrapped lemon ice pop (polo de llimona) drops from their beach tote onto the
#   pavement; pouncing or booping it awards "polo snatch! +2" (surfer: "Hey, my polo!").
# - Bark trick: barking near the passing surfer startles them into an acrobatic
#   overhead board balance recovery, awarding "surfer bark! +2" ("Nice wave, buddy!").
# - Boop trick: booping the surfer directly awards "surfer boop! +2" ("Epa!").
# - Dodge save: steering your human safely clear past the crossing trajectory
#   awards "surf dodge! +2" / "Whew, close one!".
# - Autowalk: timing naturally clears the central corridor before the autowalk
#   pair arrives at y = -2140.0, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched directly into Platja de Llevant's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(880.0, -2140.0)
const END_POS := Vector2(340.0, -2140.0)
const CROSSING_Y := -2140.0
const TRIGGER_Y := -1900.0

const WARN_DURATION := 0.8
const RUN_SPEED := 185.0
const BUMP_RADIUS := 32.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 26.0
const BARK_RADIUS := 140.0
const POLO_DROP_X := 610.0

enum State { IDLE, TELEGRAPH, RUNNING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var polo_dropped: bool = false
var polo_snatched: bool = false
var polo_pos: Vector2 = Vector2.ZERO
var polo_vel: Vector2 = Vector2.ZERO
var bark_reacted: bool = false
var dodge_awarded: bool = false
var threatened: bool = false


func tick(delta: float, dog_pos: Vector2, dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	match state:
		State.IDLE:
			if not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CROSSING_Y:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				pos = START_POS
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.RUNNING
				timer = 0.0

		State.RUNNING:
			timer += delta
			var dir := (END_POS - START_POS).normalized()
			var dist := RUN_SPEED * delta
			pos += dir * dist

			# Drop polo ice pop when crossing past middle esplanade
			if not polo_dropped and pos.x <= POLO_DROP_X:
				polo_dropped = true
				polo_pos = pos + Vector2(6.0, 4.0)
				polo_vel = Vector2(25.0, 15.0)

			# Check distracted human collision
			if not human_hit and human_pos.distance_to(pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Reached beach sand / groin
			if pos.x <= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	# Polo ice pop physics & snatch check
	if polo_dropped and not polo_snatched:
		if polo_vel.length_squared() > 1.0:
			polo_pos += polo_vel * delta
			polo_vel = polo_vel.move_toward(Vector2.ZERO, 90.0 * delta)

		if dog_pos.distance_to(polo_pos) <= SNATCH_RADIUS:
			polo_snatched = true
			out["snatch"] = true

	# Dog boop check
	if not booped and (state == State.RUNNING or state == State.TELEGRAPH):
		if dog_pos.distance_to(pos) <= BOOP_RADIUS:
			booped = true
			out["boop"] = true

	if state == State.RUNNING or state == State.SETTLED:
		var close := state == State.RUNNING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodge_awarded)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodge_awarded = true
			out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if bark_reacted:
		return false
	if state != State.RUNNING and state != State.TELEGRAPH:
		return false
	if dog_pos.distance_to(pos) <= BARK_RADIUS:
		bark_reacted = true
		return true
	return false


func draw(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if state == State.IDLE:
		return

	# Draw dropped polo
	if polo_dropped and not polo_snatched:
		if polo_pos.y >= vt - 30.0 and polo_pos.y <= vb + 30.0:
			_draw_polo(m, wc, polo_pos)

	if pos.y < vt - 60.0 or pos.y > vb + 60.0:
		return

	var t: float = AnimClock.msec() / 1000.0
	var run_anim: float = sin(t * 12.0) if state == State.RUNNING else 0.0

	# Contact shadow
	m.contact_shadow(wc, pos + Vector2(0.0, 6.0), 22.0, 8.0, 0.28)

	# Running legs
	var leg_l := pos + Vector2(-4.0 + run_anim * 4.0, 6.0 + absf(run_anim) * 2.0)
	var leg_r := pos + Vector2(4.0 - run_anim * 4.0, 6.0 + absf(run_anim) * 2.0)
	# Boardshorts: tropical teal/cyan with yellow waistband
	wc.rect(Rect2(pos.x - 7.0, pos.y, 14.0, 6.0), Color(0.20, 0.65, 0.70))
	wc.line(pos + Vector2(-7.0, pos.y), pos + Vector2(7.0, pos.y), Color(0.96, 0.88, 0.30), 1.5)
	# Bare legs
	wc.circle(leg_l, 2.5, Color(0.85, 0.68, 0.52))
	wc.circle(leg_r, 2.5, Color(0.85, 0.68, 0.52))
	# Bare feet
	wc.circle(leg_l + Vector2(-1.0, 2.0), 2.0, Color(0.82, 0.64, 0.48))
	wc.circle(leg_r + Vector2(-1.0, 2.0), 2.0, Color(0.82, 0.64, 0.48))

	# Torso: sun-tanned bare skin with zinc stripes
	wc.circle(pos + Vector2(0.0, -1.0), 8.0, Color(0.85, 0.68, 0.52))

	# Head & windblown sandy-blonde hair
	wc.circle(pos + Vector2(0.0, -6.0), 4.5, Color(0.85, 0.68, 0.52))
	# Sandy blonde hair
	wc.circle(pos + Vector2(1.0, -7.5), 4.5, Color(0.88, 0.76, 0.48))
	wc.circle(pos + Vector2(-2.0, -8.0), 3.0, Color(0.82, 0.70, 0.42))
	# White zinc sunscreen strip across nose/cheeks
	wc.line(pos + Vector2(-3.0, -6.0), pos + Vector2(1.0, -6.0), Color(0.98, 0.98, 0.98, 0.9), 1.2)

	# 9-foot longboard surfboard carried under arm
	_draw_surfboard(wc, pos, run_anim)


func _draw_surfboard(wc: ShapeBatch, p: Vector2, run_anim: float) -> void:
	var tilt: float = sin(AnimClock.msec() / 100.0) * 1.5 if state == State.RUNNING else 0.0
	var overhead: bool = bark_reacted
	var b_center := p + (Vector2(0.0, -18.0) if overhead else Vector2(-4.0, -1.0 + tilt))
	var board_w := 42.0
	var board_h := 12.0

	# Surfboard body (tropical coral with cyan rail speed stripe)
	var coral := Color(0.95, 0.45, 0.35)
	var cyan_stripe := Color(0.25, 0.75, 0.82)
	var wax_deck := Color(0.98, 0.96, 0.92, 0.8)

	# Board shadow on body if overhead
	if overhead:
		wc.rect(Rect2(b_center.x - board_w * 0.5 + 2.0, b_center.y + 4.0, board_w, 4.0), Color(0.0, 0.0, 0.0, 0.2))

	# Surfboard rounded body
	wc.rect(Rect2(b_center.x - board_w * 0.5 + 6.0, b_center.y - board_h * 0.5, board_w - 12.0, board_h), coral)
	# Nose (pointed round on left / forward direction)
	wc.circle(Vector2(b_center.x - board_w * 0.5 + 6.0, b_center.y), board_h * 0.5, coral)
	# Tail (rounded square on right)
	wc.circle(Vector2(b_center.x + board_w * 0.5 - 6.0, b_center.y), board_h * 0.45, coral)

	# Cyan stringer / center speed stripe
	wc.line(Vector2(b_center.x - board_w * 0.5 + 4.0, b_center.y), Vector2(b_center.x + board_w * 0.5 - 4.0, b_center.y), cyan_stripe, 2.0)

	# White wax patches on deck
	wc.circle(b_center + Vector2(-6.0, -2.0), 2.2, wax_deck)
	wc.circle(b_center + Vector2(2.0, 1.5), 2.4, wax_deck)
	wc.circle(b_center + Vector2(10.0, -1.0), 2.0, wax_deck)

	# Black skeg fin near tail
	wc.line(Vector2(b_center.x + board_w * 0.5 - 8.0, b_center.y + board_h * 0.4), Vector2(b_center.x + board_w * 0.5 - 12.0, b_center.y + board_h * 0.4 + 4.0), Color(0.18, 0.18, 0.20), 2.0)

	# Arms holding board
	if overhead:
		wc.line(p + Vector2(-4.0, -3.0), b_center + Vector2(-8.0, 6.0), Color(0.85, 0.68, 0.52), 2.0)
		wc.line(p + Vector2(4.0, -3.0), b_center + Vector2(8.0, 6.0), Color(0.85, 0.68, 0.52), 2.0)
	else:
		wc.line(p + Vector2(0.0, -1.0), b_center + Vector2(4.0, 2.0), Color(0.85, 0.68, 0.52), 2.2)


func _draw_polo(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	m.contact_shadow(wc, p + Vector2(1.0, 2.0), 8.0, 3.5, 0.22)
	# Translucent yellow plastic wrapper
	wc.rect(Rect2(p.x - 7.0, p.y - 3.5, 14.0, 7.0), Color(1.0, 0.95, 0.60, 0.85))
	# Lemon-yellow ice pop bar
	wc.rect(Rect2(p.x - 5.0, p.y - 2.5, 9.0, 5.0), Color(1.0, 0.88, 0.20))
	# Wooden popsicle stick
	wc.line(p + Vector2(4.0, 0.0), p + Vector2(9.0, 0.0), Color(0.72, 0.58, 0.38), 1.8)
	# Frosty glint shimmer
	var glint: float = 0.5 + 0.5 * sin(AnimClock.msec() / 130.0)
	wc.circle(p + Vector2(-3.0, -1.5), 1.0 * glint, Color(1.0, 1.0, 0.90, 0.8 * glint))
