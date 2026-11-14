class_name RopeTug
extends RefCounted

# Tug-of-war over a rope toy, Millie at one end and a free dog at the other.
# The rope between their mouths is a fixed length, so whoever gives less
# ground drags the other.
#
# The other dog pulls in a rhythm a player can read: it winds up (crouches,
# growls, shakes: WIND, the telegraph), heaves hard (HEAVE), then catches its
# breath (REST) while barely holding on. Dig in through the heave and it
# gains little; pull away while it rests and the rope comes your way fast.
# Standing about loses. Drag the ribbon past your win line and the rope is
# hers; dragged past theirs, it is gone; a long stalemate and both let go.
#
# The toy itself is a stiff braided rope: it bows when the other dog shakes
# its head and springs straight again (`bend`), stiffer the harder it is
# pulled.
#
# Pure: positions in, positions out (tests/test_freedom_games.gd).

const ROPE := 84.0            # body to body: the mouths sit 15-18 in, so ~50 of toy shows
const WIN_DIST := 110.0       # ground gained along the starting line to win
const TIME_OUT := 16.0
const MY_SPEED := 0.25        # her own running, while she has a rope in her mouth

enum P { WIND, HEAVE, REST }
const WIND_S := 0.4           # the telegraph before every heave
const HEAVE_S := 0.6
const REST_S: Array[float] = [0.8, 1.15, 0.95, 1.3]   # cycled, so the rhythm is not a metronome
const FIRST_REST := 0.7       # a beat to take hold before the first wind-up
const PULL_WIND := 40.0       # px/s the other dog hauls at in each phase
const PULL_HEAVE := 210.0
const PULL_REST := 30.0

const W_THEM := 2.0           # how hard the other dog is to shift
const W_THEM_REST := 1.2      # ...catching its breath
const W_STAND := 1.0          # Millie standing about
const W_AWAY := 2.4           # Millie pulling away
const W_TURBO := 2.6          # ...flat out (her extra speed does the rest)
const W_PLANT := 10.0         # ...dug in: holds, though it still gives ground
const YANK := 1.7             # pulling away while it rests counts this much more
const CAUGHT := 0.45          # running, not dug in, when the heave lands: hauled off her feet

# the toy's stiffness: a spring on its sideways bow
const BEND_K := 90.0
const BEND_DAMP := 9.0
const BEND_MAX := 14.0
const SHAKE_HZ := 11.0
const BEND_DRIVE := 3200.0     # the head-shake's push on the bow: ~10 px in a heave

var axis := Vector2.RIGHT     # from the other dog to Millie, at the start
var origin := Vector2.ZERO    # the rope's middle at the start
var t := 0.0
var gained := 0.0             # along the axis, Millie's way positive
var phase := P.REST
var phase_t := FIRST_REST
var cycle := 0
var bend := 0.0               # the toy's sideways bow at its middle, px
var bend_v := 0.0
var strain := 0.0             # 0..1, how hard the rope is being pulled right now
var yank := false             # true on the first frame of a pull into their rest
var _yanking := false


func _init(millie: Vector2, them: Vector2) -> void:
	var d := millie - them
	axis = d.normalized() if d.length() > 1.0 else Vector2.RIGHT
	origin = (millie + them) * 0.5


func phase_len() -> float:
	match phase:
		P.WIND: return WIND_S
		P.HEAVE: return HEAVE_S
	return REST_S[cycle % REST_S.size()]


func _advance(delta: float) -> void:
	phase_t -= delta
	if phase_t > 0.0:
		return
	match phase:
		P.REST:
			phase = P.WIND
		P.WIND:
			phase = P.HEAVE
		P.HEAVE:
			phase = P.REST
			cycle += 1
	phase_t += phase_len()


func pull_now() -> float:
	match phase:
		P.WIND: return PULL_WIND
		P.HEAVE: return PULL_HEAVE
	return PULL_REST


# One frame. `millie` is where her own movement took her this frame, `pull`
# the way she is pushing (the stick, unit or zero), `planted`/`turbo` her
# buttons. Returns [millie, them, result] with result "", "won", "lost" or
# "draw".
func step(millie: Vector2, them: Vector2, pull: Vector2, planted: bool, turbo: bool,
		delta: float) -> Array:
	t += delta
	_advance(delta)
	var away := (them - millie)
	away = away.normalized() if away.length() > 0.5 else -axis
	# the other dog hauls away from her, shaking its head as it goes
	var shake_amt := 0.55 if phase == P.HEAVE else (0.25 if phase == P.WIND else 0.1)
	var shake := away.orthogonal() * sin(t * SHAKE_HZ) * shake_amt
	them += (away + shake).normalized() * pull_now() * delta
	# then the rope: the slack is taken up by each end in inverse proportion
	# to how hard it is to move
	var pulling := pull.dot(-away) > 0.5 and not planted
	var w_me := W_STAND
	if planted:
		w_me = W_PLANT
	elif pulling:
		w_me = W_TURBO if turbo else W_AWAY
		if phase == P.REST:
			w_me *= YANK
		elif phase == P.HEAVE:
			w_me *= CAUGHT
	var yanking := pulling and phase == P.REST
	yank = yanking and not _yanking
	_yanking = yanking
	var w_them := W_THEM_REST if phase == P.REST else W_THEM
	var d := them - millie
	var len := d.length()
	var over := 0.0
	if len > ROPE:
		over = len - ROPE
		var fix := d / len * over
		millie += fix * (w_them / (w_me + w_them))
		them -= fix * (w_me / (w_me + w_them))
	strain = clampf(over / 4.0 + (0.5 if phase == P.HEAVE else 0.0), 0.0, 1.0)
	# the toy bows with the head-shake and springs back; taut, it is stiffer
	var drive := sin(t * SHAKE_HZ) * shake_amt * BEND_DRIVE
	var k := BEND_K * (1.0 + strain * 2.0)
	bend_v += (drive - k * bend - BEND_DAMP * bend_v) * delta
	bend = clampf(bend + bend_v * delta, -BEND_MAX, BEND_MAX)
	gained = ((millie + them) * 0.5 - origin).dot(axis)
	var result := ""
	if gained > WIN_DIST:
		result = "won"
	elif gained < -WIN_DIST:
		result = "lost"
	elif t > TIME_OUT:
		result = "draw"
	return [millie, them, result]


# -1 (lost) .. +1 (won), for the meter
func balance() -> float:
	return clampf(gained / WIN_DIST, -1.0, 1.0)


# the ground line `frac` of the way to a win: 0 the start, +1 hers, -1 theirs
func line_at(frac: float) -> Vector2:
	return origin + axis * WIN_DIST * frac


# 0..1 through the wind-up, for the telegraph
func wind_amount() -> float:
	if phase != P.WIND:
		return 0.0
	return 1.0 - phase_t / WIND_S
