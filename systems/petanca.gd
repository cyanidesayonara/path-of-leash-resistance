class_name Petanca
extends RefCounted

# The old men's petanca game in El Barri (systems/barri.gd).
# As your dog passes the pitch on the gravel square, the thrower in his circle
# bowls a steel boule toward the jack at the far end.
# A telegraphed shout 0.8 s before the bowl ("Watch the boule!").
# The boule rolls along the sauló court with a soft rumble, clinking against the
# boules by the jack. If your dog intercepts or nudges the rolling boule, she
# boops it ("boop! +2") and the old man scolds ("Ha, good dog!").

const PITCH := Rect2(412.0, -1985.0, 130.0, 250.0)
const THROWER := Vector2(464.0, -1765.0)
const JACK := Vector2(470.0, -1955.0)
const TARGET_POS := Vector2(476.0, -1968.0)

const WARN_S := 0.8
const NOTICE_DIST := 460.0
const BOULE_R := 5.0
const BOOP_R := 24.0
const ROLL_SPEED := 200.0
const DECEL := 80.0

enum St { WAITING, WARN, BOWLING, SETTLED, BOOPED }

var state: int = St.WAITING
var pos := THROWER
var vel := Vector2.ZERO
var t := 0.0
var booped := false
var clinked := false


func tick(dt: float, dog: Vector2, facing: Vector2, _human: Vector2) -> Dictionary:
	var cue := {"warn": false, "clink": false, "boop": false}
	match state:
		St.WAITING:
			# triggers when dog nears the petanca pitch on the gravel square
			if dog.distance_to(THROWER) < NOTICE_DIST and dog.y > PITCH.position.y - 80.0:
				state = St.WARN
				t = 0.0
				cue["warn"] = true
		St.WARN:
			t += dt
			if t >= WARN_S:
				t = 0.0
				state = St.BOWLING
				pos = THROWER + Vector2(0.0, -10.0)
				vel = (TARGET_POS - pos).normalized() * ROLL_SPEED
		St.BOWLING:
			pos += vel * dt
			vel = vel.move_toward(Vector2.ZERO, DECEL * dt)
			if not booped and dog.distance_to(pos) < BOOP_R:
				state = St.BOOPED
				booped = true
				cue["boop"] = true
				vel = (facing.normalized() if facing.length() > 0.1 else Vector2.UP) * 160.0
			elif pos.distance_to(TARGET_POS) < 12.0 or vel.length() < 12.0:
				state = St.SETTLED
				pos = TARGET_POS
				vel = Vector2.ZERO
				if not clinked:
					clinked = true
					cue["clink"] = true
		St.BOOPED:
			pos += vel * dt
			vel = vel.move_toward(Vector2.ZERO, 140.0 * dt)
			# keep within pitch boundary
			pos.x = clampf(pos.x, PITCH.position.x + 6.0, PITCH.end.x - 6.0)
			pos.y = clampf(pos.y, PITCH.position.y + 6.0, PITCH.end.y - 6.0)
			if vel.length() < 4.0:
				vel = Vector2.ZERO
		St.SETTLED:
			# if dog comes and nudges the settled boule
			if not booped and dog.distance_to(pos) < BOOP_R:
				state = St.BOOPED
				booped = true
				cue["boop"] = true
				vel = (facing.normalized() if facing.length() > 0.1 else Vector2.LEFT) * 140.0
	return cue
