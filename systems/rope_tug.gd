class_name RopeTug
extends RefCounted

# Tug-of-war over a little rope toy, Millie at one end and a free dog at the
# other. The other dog hauls away in jerks, head-shaking; the rope between
# their mouths is a fixed length, so whoever gives less ground drags the
# other. Millie holds best planted (dig in) and pulls best running away from
# it, and turbo is a real heave. Drag it far enough your way and the rope is
# hers; get dragged as far the other way and it is gone; a long stalemate and
# both let go.
#
# Pure: positions in, positions out (tests/test_freedom_games.gd).

const ROPE := 46.0            # mouth to mouth
const WIN_DIST := 110.0       # ground gained along the starting line to win
const TIME_OUT := 14.0
const MY_SPEED := 0.35        # her own running, while she has a rope in her mouth
const THEIR_PULL := 110.0     # px/s the other dog hauls at, on average
const W_THEM := 2.0           # how hard the other dog is to shift
const W_STAND := 1.0          # Millie standing about
const W_AWAY := 2.4           # Millie running away from it
const W_TURBO := 2.6          # ...flat out (her extra speed does the rest)
const W_PLANT := 10.0         # ...dug in: holds, though it still gives ground

var axis := Vector2.RIGHT     # from the other dog to Millie, at the start
var origin := Vector2.ZERO    # the rope's middle at the start
var t := 0.0
var gained := 0.0             # along the axis, Millie's way positive


func _init(millie: Vector2, them: Vector2) -> void:
	var d := millie - them
	axis = d.normalized() if d.length() > 1.0 else Vector2.RIGHT
	origin = (millie + them) * 0.5


# One frame. `millie` is where her own movement took her this frame, `pull`
# the way she is pushing (the stick, unit or zero), `planted`/`turbo` her
# buttons. Returns [millie, them, result] with result "", "won", "lost" or
# "draw".
func step(millie: Vector2, them: Vector2, pull: Vector2, planted: bool, turbo: bool,
		delta: float) -> Array:
	t += delta
	# the other dog hauls away from her, in head-shaking jerks
	var away := (them - millie)
	away = away.normalized() if away.length() > 0.5 else -axis
	var jerk := 0.55 + 0.75 * maxf(0.0, sin(t * 7.3)) + 0.25 * sin(t * 2.1)
	var shake := away.orthogonal() * sin(t * 11.0) * 0.35
	them += (away + shake).normalized() * THEIR_PULL * jerk * delta
	# then the rope: the slack is taken up by each end in inverse proportion
	# to how hard it is to move
	var w_me := W_STAND
	if planted:
		w_me = W_PLANT
	elif pull.dot(-away) > 0.5:
		w_me = W_TURBO if turbo else W_AWAY
	var d := them - millie
	var len := d.length()
	if len > ROPE:
		var fix := d / len * (len - ROPE)
		millie += fix * (W_THEM / (w_me + W_THEM))
		them -= fix * (w_me / (w_me + W_THEM))
	gained = ((millie + them) * 0.5 - origin).dot(axis)
	var result := ""
	if gained > WIN_DIST:
		result = "won"
	elif gained < -WIN_DIST:
		result = "lost"
	elif t > TIME_OUT:
		result = "draw"
	return [millie, them, result]


# -1 (lost) .. +1 (won), for the banner's meter
func balance() -> float:
	return clampf(gained / WIN_DIST, -1.0, 1.0)
