class_name Kickabout
extends RefCounted

# The kids' game in the side street that opens east off the avenue
# (docs/superpowers/specs/2026-10-17-dia-de-partit-design.md). The ball
# never moves until a kid has yelled. Scoring is dropping it between the
# jackets. After kick-off the kids are inside and the jackets stay.

const MOUTH := Vector2(868.0, -2180.0)
const JACKET_A := Vector2(868.0, -2210.0)
const JACKET_B := Vector2(868.0, -2150.0)
const KIDS: Array[Vector2] = [Vector2(1004.0, -2146.0), Vector2(1020.0, -2180.0), Vector2(1004.0, -2214.0)]
const GAP := 6.0
const WARN_T := 0.8
const ROLL := Vector2(-240.0, 8.0)
const STOP_X := 420.0
const PICK_R := 24.0
const MOUTH_R := 38.0
const BACK_R := 42.0

enum St { HELD, WARN, ROLLING, LOOSE, CARRIED, SCORED }

var state: int = St.HELD
var pos := KIDS[1]
var vel := Vector2.ZERO
var t := 0.0
var scored := false
var gone := false


func tick(dt: float, dog: Vector2, facing: Vector2, tumbling: bool, kickoff: bool) -> Dictionary:
	var cue := {"yell": false, "gol": false, "back": false}
	if kickoff and not gone:
		gone = true
		if state == St.HELD or state == St.WARN:
			state = St.LOOSE
			pos = MOUTH
			vel = Vector2.ZERO
	match state:
		St.HELD:
			# nobody yells at an empty street. The ball waits until she is near.
			if not gone and dog.distance_to(MOUTH) < 700.0:
				t += dt
			if t >= GAP and not gone:
				t = 0.0
				state = St.WARN
				cue["yell"] = true
		St.WARN:
			t += dt
			if t >= WARN_T:
				t = 0.0
				state = St.ROLLING
				vel = ROLL
				pos = KIDS[1]
		St.ROLLING:
			pos += vel * dt
			if pos.x <= STOP_X:
				pos.x = STOP_X
				state = St.LOOSE
				vel = Vector2.ZERO
			elif _can_take(dog, tumbling):
				state = St.CARRIED
		St.LOOSE:
			if _can_take(dog, tumbling):
				state = St.CARRIED
		St.CARRIED:
			var face := facing
			if face.length() < 0.1:
				face = Vector2.DOWN
			pos = dog + face.normalized() * 18.0
			if dog.distance_to(MOUTH) < MOUTH_R:
				state = St.SCORED
				scored = true
				pos = MOUTH
				cue["gol"] = true
			elif dog.distance_to(KIDS[1]) < BACK_R and not gone:
				state = St.HELD
				t = 0.0
				pos = KIDS[1]
				cue["back"] = true
		St.SCORED:
			pos = MOUTH
	return cue


func _can_take(dog: Vector2, tumbling: bool) -> bool:
	return not tumbling and dog.distance_to(pos) < PICK_R


func draw(wc: ShapeBatch, vt: float, vb: float) -> void:
	if MOUTH.y < vt - 80.0 or MOUTH.y > vb + 80.0:
		if pos.y < vt - 40.0 or pos.y > vb + 40.0:
			return
	var cloth := Color(0.22, 0.34, 0.62)
	var cloth2 := Color(0.55, 0.16, 0.28)
	wc.rect(Rect2(JACKET_A.x - 8.0, JACKET_A.y - 5.0, 16.0, 10.0), cloth)
	wc.rect(Rect2(JACKET_B.x - 8.0, JACKET_B.y - 5.0, 16.0, 10.0), cloth2)
	if not gone:
		var bob := sin(AnimClock.msec() / 280.0) * 1.4
		for i in KIDS.size():
			var k: Vector2 = KIDS[i] + Vector2(0.0, bob)
			wc.rect(Rect2(k.x - 5.0, k.y - 2.0, 10.0, 12.0), Color(0.85, 0.55, 0.28) if i != 1 else Color(0.25, 0.45, 0.72))
			wc.circle(k + Vector2(0.0, -8.0), 4.2, Color(0.86, 0.70, 0.55))
	wc.circle(pos, 5.5, Color(0.95, 0.95, 0.93))
	wc.circle(pos + Vector2(-1.4, -1.2), 1.6, Color(0.18, 0.18, 0.2))
