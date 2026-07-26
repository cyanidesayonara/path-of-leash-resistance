extends Node

# The teeter: the moment before you fall in.
#
# Walking into a manhole, a cellar or the water's edge used to be instant and
# unreadable - you were simply punished. Now the brink starts a BALANCE
# moment, borrowed from the manual/grind in the Tony Hawk games: you are
# tipping, and a scramble in the other direction saves you. Getting out of it
# is a small skill you can get good at, so the hazard becomes a place you
# lean into on purpose rather than something you resent.
#
# Deliberately generous, because a fiddly version of this would be a pain
# rather than a thrill: the pull starts gently and only bites as you lean
# further, the correction is stronger than the pull, and simply surviving
# HOLD seconds recovers you automatically. Pure 1-D logic (main feeds it how
# hard the player is scrambling away from the hazard), so it is testable
# headless and reusable for any brink.

# Tuned as a direct RATE rather than an accelerating velocity with damping:
# the first attempt double-integrated and the damping quietly capped the pull
# so far below the threshold that standing still saved you. A direct rate is
# predictable enough to tune by arithmetic, and still perfectly smooth.
#
# The resulting difficulty band, which is the whole design:
#   no input          -> you are in after ~0.45s
#   a token scramble  -> still lose (~0.65s)
#   a real scramble   -> hold upright and recover
#   a LATE full one   -> can still rescue a deep lean
const PULL_BASE := 1.6      # how hard the hole tugs when you are upright
const PULL_LEAN := 1.4      # ...and the extra tug the further you tip
const CORRECT := 3.0        # authority of a scramble in the other direction
const HOLD := 1.25          # survive this long and you are safe
const LEAN_LIMIT := 1.0     # past this you are in

var active := false
var lean := 0.0             # 0 upright, 1 gone
var vel := 0.0
var t := 0.0
var last_result := ""


func begin() -> void:
	active = true
	lean = 0.0
	vel = 0.0
	t = 0.0
	last_result = ""


func cancel() -> void:
	active = false
	lean = 0.0
	vel = 0.0
	t = 0.0


# counter: how hard the player is scrambling AWAY from the hazard, -1..1.
# Returns "" while still teetering, then "saved" or "fell" exactly once.
func tick(delta: float, counter: float) -> String:
	if not active:
		return ""
	t += delta
	# the hole pulls harder the further you are already leaning - that is
	# what makes a late save feel like a real recovery
	vel = PULL_BASE + lean * PULL_LEAN - clampf(counter, -1.0, 1.0) * CORRECT
	lean += vel * delta
	# you cannot bank progress by over-scrambling, but you are not punished
	# for it either: leaning "backwards" simply reads as upright
	if lean < 0.0:
		lean = 0.0
	if lean >= LEAN_LIMIT:
		active = false
		last_result = "fell"
		return "fell"
	if t >= HOLD:
		active = false
		last_result = "saved"
		return "saved"
	return ""


func fraction() -> float:
	# 0 upright .. 1 about to go, for the balance meter
	return clampf(lean / LEAN_LIMIT, 0.0, 1.0)


func time_left() -> float:
	return maxf(0.0, HOLD - t)
