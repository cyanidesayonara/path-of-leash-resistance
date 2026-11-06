class_name MercatCart
extends RefCounted

# WALK 5: EL MERCAT (the market hall).
# A market porter pushes a two-wheeled wooden fruit handcart across the aisle
# between stall blocks at y = -2700.0, from the west wall to the east wall.
#
# A telegraphed shout 0.8 s before entering the walkway ("Produce cart coming through!").
# As the cart rattles over the terrazzo floor tile seams, a ripe orange bounces
# off the crates onto the floor. If Millie snatches it, she enjoys a snack
# ("snack! +2", +2 bones, +2 combo, advances snack goal).
# If the human walks into the cart, they bump it ("Watch out!", -8 patience),
# but if the human or dog is directly in front, the polite porter pauses
# ("After you!").

const START_POS := Vector2(270.0, -2700.0)
const END_POS := Vector2(980.0, -2700.0)
const CROSSING_Y := -2700.0
const WARN_DIST := 420.0
const WARN_S := 0.8
const SPEED := 130.0
const CART_SIZE := Vector2(46.0, 30.0)
const ORANGE_DROP_X := 590.0
const SNACK_DIST := 24.0
const HUMAN_BUMP_DIST := 34.0

enum St { WAITING, WARN, CROSSING, SETTLED }

var state: int = St.WAITING
var pos: Vector2 = START_POS
var warn_t := 0.0
var triggered := false
var creaked := false
var orange_dropped := false
var orange_eaten := false
var orange_pos := Vector2.ZERO
var orange_vel := Vector2.ZERO
var human_bumped := false
var paused_for_walker := false
var yield_cooldown := 0.0
var seam := -999


func tick(dt: float, dog_pos: Vector2, human_pos: Vector2) -> Dictionary:
	var cue := {
		"warn": false,
		"creak": false,
		"drop_orange": false,
		"snack": false,
		"bump": false,
		"yield": false,
	}

	if yield_cooldown > 0.0:
		yield_cooldown = maxf(0.0, yield_cooldown - dt)

	# Dropped orange physics and dog snack check
	if orange_dropped and not orange_eaten:
		if orange_vel.length() > 2.0:
			orange_pos += orange_vel * dt
			orange_vel = orange_vel.move_toward(Vector2.ZERO, 100.0 * dt)
		if dog_pos.distance_to(orange_pos) < SNACK_DIST:
			orange_eaten = true
			cue["snack"] = true

	match state:
		St.WAITING:
			# Triggers when the pair approaches the cross aisle from south
			if not triggered and dog_pos.distance_to(Vector2(640.0, CROSSING_Y)) < WARN_DIST and dog_pos.y > CROSSING_Y - 50.0:
				state = St.WARN
				warn_t = 0.0
				triggered = true
				cue["warn"] = true
		St.WARN:
			warn_t += dt
			if not creaked and warn_t >= 0.2:
				creaked = true
				cue["creak"] = true
			if warn_t >= WARN_S:
				state = St.CROSSING
				pos = START_POS
		St.CROSSING:
			# Check if human or dog is directly in front of the cart to yield politely
			var walker_in_front := false
			for walker in [human_pos, dog_pos]:
				if absf(walker.y - CROSSING_Y) < 28.0 and walker.x > pos.x + 10.0 and walker.x < pos.x + 50.0:
					walker_in_front = true
					break

			if walker_in_front:
				paused_for_walker = true
				if yield_cooldown <= 0.0:
					yield_cooldown = 2.5
					cue["yield"] = true
			else:
				paused_for_walker = false
				pos.x += SPEED * dt
				var crossed := int(pos.x / 180.0)
				if crossed != seam:
					seam = crossed
					cue["creak"] = true

			# Drop orange near middle terrazzo seam
			if not orange_dropped and pos.x >= ORANGE_DROP_X:
				orange_dropped = true
				orange_pos = Vector2(pos.x - 10.0, CROSSING_Y + 14.0)
				orange_vel = Vector2(30.0, 60.0)
				cue["drop_orange"] = true

			# Human collision check
			if not human_bumped and human_pos.distance_to(pos) < HUMAN_BUMP_DIST:
				human_bumped = true
				cue["bump"] = true

			# Reached east wall
			if pos.x >= END_POS.x:
				pos.x = END_POS.x
				state = St.SETTLED

		St.SETTLED:
			pass

	return cue
