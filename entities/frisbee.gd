extends Node2D

# The frisbee, after the fetch round: your human throws it long and it floats,
# curving, its shadow on the ground beneath. Snatch it out of the air for the
# real prize; picked up off the grass it still counts, just. Brought back to
# the bench, it goes again, three throws in all.
#
# Local RNG: the deterministic autowalk crosses this space (and never gets a
# frisbee, but the habit is the rule here).

enum State { WAIT, FLYING, LANDED, CARRIED, DONE }

const THROWS := 3
const WAIT_S := 0.8           # the telegraph: "ready...?" before every throw
const SPEED := 230.0          # px/s along the ground: it floats
const AIR_H := 34.0           # below this height she can take it out of the air
const CATCH_R := 26.0
const PICK_R := 22.0
const RETURN_R := 42.0

var main: Node2D
var dog: Node2D
var thrower: Node2D
var state := State.WAIT
var area := Rect2()
var from := Vector2.ZERO
var to := Vector2.ZERO
var bow := 0.0
var fly_t := 0.0
var fly_len := 1.0
var top_h := 50.0
var h := 0.0
var spin := 0.0
var wait_t := WAIT_S
var throws_left := THROWS
var air_catches := 0
var rng := RandomNumberGenerator.new()


func setup(m: Node2D, d: Node2D, thrower_node: Node2D, rect: Rect2, seed_v: int) -> void:
	main = m
	dog = d
	thrower = thrower_node
	area = rect
	rng.seed = seed_v
	global_position = thrower.global_position
	_get_ready()


func _get_ready() -> void:
	state = State.WAIT
	wait_t = WAIT_S
	global_position = thrower.global_position + Vector2(10, -8)
	if thrower == main.human:
		main.human.say_line("ready...?")


func _throw() -> void:
	from = global_position
	# long, and out into the space (up the screen, away from the gate)
	var ang := rng.randf_range(-PI * 0.85, -PI * 0.15)
	var dist := rng.randf_range(280.0, 440.0)
	to = from + Vector2.from_angle(ang) * dist
	to.x = clampf(to.x, area.position.x + 40.0, area.end.x - 40.0)
	to.y = clampf(to.y, area.position.y + 40.0, area.end.y - 60.0)
	fly_len = maxf(from.distance_to(to) / SPEED, 0.6)
	top_h = 44.0 + from.distance_to(to) * 0.05
	bow = rng.randf_range(-70.0, 70.0)
	fly_t = 0.0
	state = State.FLYING
	if thrower == main.human:
		main.human.throw_pose()
	Sfx.play("fling", 1.3, -10.0)


func is_carried() -> bool:
	return state == State.CARRIED


func in_air() -> bool:
	return state == State.FLYING


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	spin += delta * (14.0 if state == State.FLYING else 0.0)
	match state:
		State.WAIT:
			wait_t -= delta
			if wait_t <= 0.0:
				_throw()
		State.FLYING:
			fly_t += delta
			var f := clampf(fly_t / fly_len, 0.0, 1.0)
			var perp := (to - from).orthogonal().normalized()
			global_position = from.lerp(to, f) + perp * bow * sin(PI * f)
			# up fast, a long hang, down soft: the shape of a good throw
			h = top_h * sin(PI * pow(f, 0.8))
			if f > 0.2 and h < AIR_H and not main.dog_carrying \
					and global_position.distance_to(dog.global_position) < CATCH_R:
				_caught(true)
			elif f >= 1.0:
				state = State.LANDED
				h = 0.0
		State.LANDED:
			if not main.dog_carrying and global_position.distance_to(dog.global_position) < PICK_R:
				_caught(false)
		State.CARRIED:
			h = 0.0
			global_position = dog.global_position + dog.facing * 22.0
			if global_position.distance_to(thrower.global_position) < RETURN_R:
				main.dog_carrying = false
				throws_left -= 1
				main.on_frisbee_returned(throws_left)
				if throws_left > 0:
					_get_ready()
				else:
					state = State.DONE
					queue_free()
	queue_redraw()


func _caught(air: bool) -> void:
	state = State.CARRIED
	main.dog_carrying = true
	if air:
		air_catches += 1
	main.on_frisbee_caught(air)


var _b: ShapeBatch


func _draw() -> void:
	_b = ShapeBatch.new(self)
	# the shadow stays on the ground and shrinks as the disc climbs: the only
	# way to read height from straight above
	var sr := 9.0 - h * 0.06
	_b.draw_colored_polygon(_ellipse(Vector2(h * 0.25, h * 0.3 + 2.0), Vector2(sr, sr * 0.6), 0.0), Color(0, 0, 0, 0.2))
	var c := Vector2(0, -h)
	var tilt := sin(spin) * 0.25
	_b.draw_colored_polygon(_ellipse(c, Vector2(10.5, 8.0), tilt), Color(0.12, 0.1, 0.09))
	_b.draw_colored_polygon(_ellipse(c, Vector2(9.0, 6.6), tilt), Color(0.95, 0.42, 0.2))
	_b.draw_colored_polygon(_ellipse(c + Vector2(-1.5, -1.2), Vector2(5.0, 3.4), tilt), Color(1.0, 0.62, 0.36))
	# the spin, as a mark going round the rim
	var m := c + Vector2(cos(spin * 3.0) * 7.0, sin(spin * 3.0) * 5.0)
	_b.draw_circle(m, 1.6, Color(1, 0.95, 0.85))
	_b.flush()


static func _ellipse(c: Vector2, r: Vector2, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(14):
		var a := TAU * float(i) / 14.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	return pts
