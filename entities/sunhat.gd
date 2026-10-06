extends Node2D

# Your human's sunhat, taken by a gust high on Montjuïc (systems/montjuic.gd
# blow_hat). It tumbles off downwind and fetches up on the path; she can pick
# it up and take it back to them, or leave it. Self-managing and order
# independent, like the ball: it only reads the dog and the human.

enum State { FLYING, RESTING, CARRIED }

const DRAG := 170.0            # px/s/s it loses tumbling along
const REST_SPEED := 22.0
const PICK_R := 22.0
const GIVE_R := 44.0
const LOST_BEHIND := 760.0     # this far behind your human, it is gone
const EDGE_IN := 14.0          # it fetches up this far inside the path's edge
const STRAW := Color(0.92, 0.84, 0.62)

var main: Node2D
var state := State.FLYING
var vel := Vector2.ZERO
var spin := 0.0
var spin_v := 0.0
var lift := 0.0


func setup(m: Node2D, at: Vector2, v: Vector2) -> void:
	main = m
	global_position = at
	vel = v
	spin_v = 9.0 * signf(v.x if absf(v.x) > 1.0 else 1.0)
	lift = 18.0
	z_index = 3


func _physics_process(delta: float) -> void:
	if main == null or main.frozen:
		return
	var dog: Node2D = main.dog
	var human: Node2D = main.human
	# the off-leash space has its own toys: a hat carried in drops at the gate
	if main.phase == "freedom":
		if state == State.CARRIED:
			state = State.RESTING
		return
	match state:
		State.FLYING:
			global_position += vel * delta
			vel = vel.move_toward(Vector2.ZERO, DRAG * delta)
			spin += spin_v * delta
			spin_v = move_toward(spin_v, 0.0, 6.0 * delta)
			lift = maxf(0.0, lift - 22.0 * delta)
			_keep_on_path()
			if vel.length() < REST_SPEED:
				state = State.RESTING
				lift = 0.0
		State.RESTING:
			if global_position.distance_to(dog.global_position) < PICK_R and not dog.is_tumbling():
				state = State.CARRIED
				Sfx.play("pickup", 1.2, -6.0)
				main.float_text(global_position + Vector2(0, -24), "got it", Color(1, 0.95, 0.8), main.POP_SAY)
		State.CARRIED:
			global_position = dog.global_position + dog.facing * 22.0
			spin = dog.facing.angle()
			if global_position.distance_to(human.global_position) < GIVE_R and not human.is_fallen():
				main.on_hat_returned(global_position)
				queue_free()
				return
	if state != State.CARRIED and global_position.y - human.global_position.y > LOST_BEHIND:
		queue_free()
		return
	queue_redraw()


func _keep_on_path() -> void:
	var e: Vector2 = main.walk_edges(global_position.y)
	var lo := e.x + EDGE_IN
	var hi := e.y - EDGE_IN
	if hi <= lo:
		return
	if global_position.x < lo:
		global_position.x = lo
		vel.x = 0.0
		vel *= 0.5
	elif global_position.x > hi:
		global_position.x = hi
		vel.x = 0.0
		vel *= 0.5


func _draw() -> void:
	var y := -lift
	if state != State.CARRIED:
		main.contact_shadow(self, Vector2.ZERO, 11.0, 4.0 + lift * 0.4, 0.2)
	# a straw sunhat from above, tilted as it tumbles: the brim, the crown
	# and its band
	var squash := Vector2(1.0, 0.55 + 0.45 * absf(cos(spin))) if state == State.FLYING else Vector2.ONE
	draw_set_transform(Vector2(0, y), spin, squash)
	draw_circle(Vector2.ZERO, 11.0, STRAW)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, STRAW.darkened(0.18), 1.2)
	draw_circle(Vector2.ZERO, 6.4, STRAW.darkened(0.06))
	draw_arc(Vector2.ZERO, 6.4, 0.0, TAU, 16, Color(0.30, 0.22, 0.20), 1.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
