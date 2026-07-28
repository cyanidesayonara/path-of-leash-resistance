extends Node

# The kerb grind. Run along a kerb at a clip and you start balancing on it,
# Tony Hawk style: the longer you hold it the more it is worth, and the
# harder it gets to hold. Bailing costs you the trick and your combo but
# nothing else - this is a thing you SEEK OUT, not a hazard.
#
# Where teeter.gd is a one-way slide you fight out of, this is a two-sided
# balance you ride: the board wobbles left and right and you feather it with
# lateral nudges. The wobble is a deterministic function of elapsed grind
# time (no RNG), which keeps it reproducible in tests and, more importantly,
# LEARNABLE - the same kerb wobbles the same way, so getting good is real.

# Balancing on a kerb is an INVERTED PENDULUM: the further you are already
# tipped, the harder gravity takes you. A first attempt used only a wobble,
# which just oscillated safely around centre - an unattended grind never
# fell off, so there was no skill in it. The divergence term is what makes
# it a balance rather than a decoration, and its ramp is what guarantees
# even a perfect grind is finite.
const DIVERGE := 5.6        # instability: lean feeds on itself
const DIVERGE_RAMP := 0.85  # ...and gets worse the longer you ride
const WOBBLE_GAIN := 2.4    # the disturbance that keeps you honest
# The disturbance ramps as well as the instability, and that is deliberate:
# with only the divergence term, a PERFECT rider could pin the lean at zero
# and grind forever for unbounded points. A growing wobble eventually
# out-muscles the nudge no matter how well you ride, so every grind ends -
# the skill is in how long you stretch it, not whether it stops.
const WOBBLE_RAMP := 0.35
const CORRECT := 5.4        # authority of a lateral nudge
const DAMP := 0.86          # takes the jitter out of the wobble
const LIMIT := 1.0          # past this you are off
const SCORE_RATE := 9.0     # points per second, before the length bonus

var active := false
var lean := 0.0
var vel := 0.0
var t := 0.0
var phase := 0.0
var score := 0.0


func begin() -> void:
	active = true
	lean = 0.0
	vel = 0.0
	t = 0.0
	phase = 0.0
	score = 0.0


# counter: lateral nudge, -1..1, positive pushing against the current lean.
# Returns "" while riding, or "bailed" once when the balance is lost.
func tick(delta: float, counter: float) -> String:
	if not active:
		return ""
	t += delta
	phase += delta
	# a two-frequency wobble so it is not a plain sine you can trivially
	# time; deterministic, so a kerb always behaves the same way
	var push := sin(phase * 2.3) + 0.55 * sin(phase * 5.7)
	# the pendulum: any lean grows, and faster the longer you have ridden
	vel += lean * (DIVERGE + t * DIVERGE_RAMP) * delta
	vel += push * (WOBBLE_GAIN + t * WOBBLE_RAMP) * delta
	# counter is positive when it pushes lean back toward centre from the
	# positive side, so it always subtracts
	vel -= clampf(counter, -1.0, 1.0) * CORRECT * delta
	vel *= DAMP
	lean += vel * delta
	# a grind is worth more the longer you ride it
	score += SCORE_RATE * (1.0 + t * 0.5) * delta
	if absf(lean) >= LIMIT:
		active = false
		return "bailed"
	return ""


# stepping off cleanly: banks whatever the ride was worth
func land() -> int:
	if not active:
		return 0
	active = false
	return int(round(score))


func fraction() -> float:
	# -1..1 mapped to 0..1 for a centred balance bar
	return clampf((lean + 1.0) * 0.5, 0.0, 1.0)


func points() -> int:
	return int(round(score))
