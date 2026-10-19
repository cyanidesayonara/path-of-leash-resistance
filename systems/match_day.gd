class_name MatchDay
extends RefCounted

# Dia de Partit's match clock (docs/superpowers/specs/
# 2026-10-17-dia-de-partit-design.md). Pure: the caller passes the walk time,
# where the pair is, and whether they have turned for home. Kick-off is the
# clock or the gate, whichever comes first. Nothing here touches the rope.

enum Ph { PREMATCH, RUSH, KICKOFF, MATCH, FULLTIME }

const KICKOFF_T := 210.0       # seconds of the walk out
const RUSH_LEAD := 25.0        # the last stretch before the clock wins
const DRAIN_T := 8.0           # the streets empty over this long
const FULLTIME_Y := -3000.0    # passed going south, on the way home
const FULLTIME_WAIT := 60.0    # seconds of the match before the final whistle can come
const MATCH_PACE := 0.88       # how their pace gives once the phone shows the match

# dropped when the crowd goes in: the avenue, clear of the middle's stalls
const LITTER: Array[Vector2] = [
	Vector2(580.0, -1500.0), Vector2(740.0, -1900.0), Vector2(560.0, -2400.0),
	Vector2(780.0, -2750.0), Vector2(520.0, -3200.0), Vector2(700.0, -3600.0),
]

var phase := Ph.PREMATCH
var phase_t := 0.0
var walk_t := 0.0
var match_t := 0.0
var _pa := false
var _whistle := false


# One step. homeward is the walk home. pair_y is the northmost of the pair
# (smaller y is further up the walk). gate_y is the walk's own gate.
# The dictionary carries the one-shots for this step: pa, whistle, and the
# banner text (empty when the clock has nothing to say).
func advance(dt: float, pair_y: float, gate_y: float, homeward: bool) -> Dictionary:
	if phase == Ph.PREMATCH or phase == Ph.RUSH:
		if not homeward:
			walk_t += dt
		if walk_t >= KICKOFF_T or pair_y <= gate_y:
			_to(Ph.KICKOFF)
		elif phase == Ph.PREMATCH and walk_t >= KICKOFF_T - RUSH_LEAD:
			_to(Ph.RUSH)
	elif phase == Ph.KICKOFF:
		phase_t += dt
		if phase_t >= DRAIN_T:
			_to(Ph.MATCH)
	elif phase == Ph.MATCH:
		phase_t += dt
		match_t += dt
		if homeward and match_t >= FULLTIME_WAIT and pair_y >= FULLTIME_Y:
			_to(Ph.FULLTIME)
	else:
		phase_t += dt
	var cue := {
		"phase": phase,
		"pa": _pa,
		"whistle": _whistle,
		"banner": "KICK-OFF SOON" if phase == Ph.RUSH else "",
	}
	_pa = false
	_whistle = false
	return cue


func _to(next: Ph) -> void:
	if phase == next:
		return
	phase = next
	phase_t = 0.0
	if next == Ph.RUSH:
		_pa = true
	elif next == Ph.KICKOFF:
		_whistle = true
	elif next == Ph.MATCH:
		match_t = 0.0


func on_the_match() -> bool:
	return phase >= Ph.KICKOFF
