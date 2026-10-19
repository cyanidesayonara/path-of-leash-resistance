class_name LostScarf
extends RefCounted

# A kid on her dad's shoulders loses her scarf before kick-off. Wind takes
# it in a gust; a calm day it slips off. Either way it fetches up at the
# edge of the river, and the two of them wait by a lamppost.

const START := Vector2(740.0, -1680.0)
const LAMP := Vector2(700.0, -1940.0)
const PICK_R := 22.0
const GIVE_R := 44.0
const WALK := 70.0
const WIND_V := 320.0
const SLIP_V := 110.0
const EDGE_IN := 50.0

enum St { WORN, FLYING, REST, CARRIED, BACK, MISSED }

var state: int = St.WORN
var at := START
var scarf := START
var vel := Vector2.ZERO
var wind := false
var back := false
var _said := false
var _land := START


func tick(dt: float, dog: Vector2, facing: Vector2, tumbling: bool, kickoff: bool, edges: Callable) -> Dictionary:
	var cue := {"scarf": false, "good": false}
	if state == St.WORN and kickoff:
		state = St.MISSED
		return cue
	if state == St.WORN and dog.distance_to(at) < 520.0:
		_lose(edges)
		cue["scarf"] = true
	elif state == St.FLYING:
		at = at.move_toward(LAMP, WALK * dt)
		scarf += vel * dt
		if scarf.distance_to(_land) < 12.0 or vel.length() < 18.0:
			scarf = _land
			vel = Vector2.ZERO
			state = St.REST
	elif state == St.REST:
		at = at.move_toward(LAMP, WALK * dt)
		if not _said and at.distance_to(LAMP) < 10.0:
			_said = true
			cue["scarf"] = true
		if not tumbling and dog.distance_to(scarf) < PICK_R:
			state = St.CARRIED
	elif state == St.CARRIED:
		var face := facing
		if face.length() < 0.1:
			face = Vector2.DOWN
		scarf = dog + face.normalized() * 20.0
		at = at.move_toward(LAMP, WALK * dt)
		if not _said and at.distance_to(LAMP) < 10.0:
			_said = true
			cue["scarf"] = true
		if dog.distance_to(at) < GIVE_R:
			state = St.BACK
			back = true
			scarf = at
			cue["good"] = true
	return cue


func _lose(edges: Callable) -> void:
	var e: Vector2 = edges.call(at.y)
	var land_x := e.x + EDGE_IN
	if land_x >= e.y - EDGE_IN:
		land_x = (e.x + e.y) * 0.5
	_land = Vector2(land_x, at.y + 30.0)
	var speed := WIND_V if wind else SLIP_V
	vel = (_land - at).normalized() * speed
	scarf = at
	state = St.FLYING


func waiting() -> bool:
	return _said


func draw(wc: ShapeBatch, vt: float, vb: float) -> void:
	if state == St.MISSED or state == St.BACK:
		return
	if at.y < vt - 80.0 or at.y > vb + 120.0:
		return
	var bob := sin(AnimClock.msec() / 320.0) * 1.2
	var dad := at + Vector2(0.0, bob)
	wc.rect(Rect2(dad.x - 7.0, dad.y - 4.0, 14.0, 18.0), Color(0.20, 0.32, 0.58))
	wc.circle(dad + Vector2(0.0, -12.0), 5.0, Color(0.84, 0.68, 0.52))
	var kid := dad + Vector2(0.0, -20.0)
	wc.rect(Rect2(kid.x - 5.0, kid.y - 2.0, 10.0, 10.0), Color(0.55, 0.14, 0.26))
	wc.circle(kid + Vector2(0.0, -7.0), 3.6, Color(0.90, 0.74, 0.58))
	if state == St.WORN:
		wc.rect(Rect2(kid.x - 6.0, kid.y - 1.0, 12.0, 3.0), Color(0.16, 0.30, 0.62))
	else:
		wc.rect(Rect2(scarf.x - 7.0, scarf.y - 2.0, 14.0, 4.0), Color(0.16, 0.30, 0.62))
		wc.rect(Rect2(scarf.x - 7.0, scarf.y + 1.2, 14.0, 2.2), Color(0.55, 0.14, 0.26))
