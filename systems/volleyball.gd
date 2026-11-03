class_name Volleyball
extends RefCounted

# WALK 4: LA PLATJA (the beach walk).
# Casual beach volleyball game on the raked sand court at y = -2000.0 (systems/passeig.gd).
#
# As the pair approaches on the outward walk (y ≈ -1750.0), the spiker leaps and
# winds up a spike. A 0.8 s warning telegraph triggers:
# Beachgoer shouts with a speech bubble: "Pilota fora!" ("Watch the ball!").
#
# The server spikes the ball across the net. It flies in a high arc
# eastward across the sand toward the boardwalk:
# - Millie intercepts or boops the ball: ("volley! +2", +2 bones, +2 combo).
#   The beachgoer calls: "Bona rematada!" ("Nice save!").
# - An oblivious human walking in its landing path gets bonked on the head:
#   ("Watch the game!", -8 patience).
# - Steering the human safely along the promenade earns a rewarded dodge:
#   ("good dodge! +2", saves_done += 1, "Whew, nice save!").
# The central autowalk line along the promenade (x = 770.0) remains safe and unblocked.

const COURT := Rect2(246.0, -2120.0, 120.0, 240.0)
const NET_Y := -2000.0
const SPIKER_POS := Vector2(290.0, -1940.0)
const RECEIVER_POS := Vector2(310.0, -2060.0)
const WARN_DIST := 420.0
const WARN_S := 0.8
const BALL_R := 4.8
const BOOP_R := 28.0
const HUMAN_HIT_R := 30.0
const GRAV := 420.0

enum St { WAITING, WARN, FLYING, BOUNCING, SETTLED, INTERCEPTED }

var state: int = St.WAITING
var pos := Vector2(290.0, -1940.0)
var vel := Vector2.ZERO
var z := 16.0
var vz := 0.0
var warn_t := 0.0
var triggered := false
var booped := false
var human_hit := false
var dodge_done := false
var was_near := false

# Four players on the court: 2 south of net, 2 north of net
const PLAYERS: Array = [
	Vector2(290.0, -1940.0), # Spiker (south)
	Vector2(330.0, -1925.0), # Partner (south)
	Vector2(285.0, -2070.0), # Defender 1 (north)
	Vector2(325.0, -2055.0), # Defender 2 (north)
]


func tick(dt: float, dog: Vector2, facing: Vector2, human: Vector2) -> Dictionary:
	var cue := {
		"warn": false,
		"spike": false,
		"bounce": false,
		"boop": false,
		"human_hit": false,
		"dodge": false,
	}

	# Track when human enters the volleyball latitude zone
	if absf(human.y - NET_Y) < 140.0:
		was_near = true

	# Dodge reward: if human passed safely on the promenade without getting hit
	if was_near and not human_hit and not dodge_done and human.y < NET_Y - 110.0:
		if human.x > 680.0:
			dodge_done = true
			cue["dodge"] = true

	match state:
		St.WAITING:
			# Triggers when dog approaches court from the south
			if not triggered and dog.distance_to(SPIKER_POS) < WARN_DIST and dog.y > SPIKER_POS.y - 60.0:
				state = St.WARN
				warn_t = 0.0
				triggered = true
				cue["warn"] = true
		St.WARN:
			warn_t += dt
			if warn_t >= WARN_S:
				state = St.FLYING
				pos = SPIKER_POS + Vector2(8.0, -12.0)
				z = 24.0
				vel = Vector2(175.0, -35.0)
				vz = 185.0
				cue["spike"] = true
		St.FLYING:
			pos += vel * dt
			vz -= GRAV * dt
			z += vz * dt

			# In-flight dog intercept
			if not booped and dog.distance_to(pos) < BOOP_R and z < 34.0:
				state = St.INTERCEPTED
				booped = true
				cue["boop"] = true
				vel = (facing.normalized() if facing.length() > 0.1 else Vector2(1.0, -0.4)) * 140.0
				vz = 110.0

			# Human hit check
			if not human_hit and human.distance_to(pos) < HUMAN_HIT_R and z < 32.0:
				human_hit = true
				cue["human_hit"] = true
				vel = Vector2(-40.0, 30.0)
				vz = 60.0

			# Ground bounce
			if z <= 0.0:
				z = 0.0
				vz = -vz * 0.48
				vel *= 0.60
				cue["bounce"] = true
				state = St.BOUNCING

		St.BOUNCING:
			pos += vel * dt
			vz -= GRAV * dt
			z += vz * dt

			# Ground level dog intercept / boop
			if not booped and dog.distance_to(pos) < BOOP_R:
				state = St.INTERCEPTED
				booped = true
				cue["boop"] = true
				vel = (facing.normalized() if facing.length() > 0.1 else Vector2.RIGHT) * 120.0
				vz = 90.0

			if z <= 0.0:
				z = 0.0
				vz = -vz * 0.40
				vel *= 0.55
				if vz < 22.0:
					vz = 0.0
					vel = Vector2.ZERO
					state = St.SETTLED

		St.INTERCEPTED:
			pos += vel * dt
			vz -= GRAV * dt
			z += vz * dt
			if z <= 0.0:
				z = 0.0
				vz = -vz * 0.35
				vel *= 0.50
				if vz < 18.0:
					vz = 0.0
					vel = Vector2.ZERO
					state = St.SETTLED

		St.SETTLED:
			# Millie can still nudge the resting ball once
			if not booped and dog.distance_to(pos) < BOOP_R:
				booped = true
				cue["boop"] = true
				vel = (facing.normalized() if facing.length() > 0.1 else Vector2.RIGHT) * 100.0
				state = St.INTERCEPTED

	return cue
