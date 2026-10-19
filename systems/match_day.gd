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
# goals: the first no sooner than 25s after kick-off, then at least 35s
# apart, and never more than three. The swell is the telegraph; the roar
# follows it; your human is a second behind the stadium.
const GOAL_FIRST := 25.0
const GOAL_GAP := 35.0
const GOAL_CAP := 3
const SWELL_T := 1.5
const REACT_LAG := 1.0
const BESIDE := 70.0

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
var goals: Array[Dictionary] = []
var goal_i := 0
var _swell := -1.0
var _react_in := -1.0
var _side := ""
var _ooooh := false
var _roar := false
var _react := ""
var _flare := false
var _flare_in := 22.0
var force_in := -1.0
var roar_side := ""


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
		_goals(dt)
		if homeward and match_t >= FULLTIME_WAIT and pair_y >= FULLTIME_Y:
			_to(Ph.FULLTIME)
	else:
		phase_t += dt
	var cue := {
		"phase": phase,
		"pa": _pa,
		"whistle": _whistle,
		"banner": "KICK-OFF SOON" if phase == Ph.RUSH else "",
		"ooooh": _ooooh,
		"roar": _roar,
		"react": _react,
		"flare": _flare,
	}
	_pa = false
	_whistle = false
	_ooooh = false
	_roar = false
	_react = ""
	_flare = false
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
		_plan(20261019)


func on_the_match() -> bool:
	return phase >= Ph.KICKOFF


func _plan(seed: int) -> void:
	goals.clear()
	goal_i = 0
	_swell = -1.0
	_react_in = -1.0
	if force_in >= 0.0:
		goals.append({"at": force_in, "side": "home"})
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := 2 + (rng.randi() % 2)
	var at := GOAL_FIRST + rng.randf() * 12.0
	var which := rng.randi() % n
	var disallow := rng.randf() < 0.5
	for i in n:
		var side := "home" if rng.randf() < 0.65 else "away"
		if disallow and i == which:
			side = "no"
		goals.append({"at": at, "side": side})
		at += GOAL_GAP + rng.randf() * 18.0


func _goals(dt: float) -> void:
	if _swell < 0.0 and goal_i < goals.size() and match_t >= float(goals[goal_i]["at"]):
		_side = String(goals[goal_i]["side"])
		goal_i += 1
		_swell = SWELL_T
		_ooooh = true
	if _swell >= 0.0:
		_swell -= dt
		if _swell <= 0.0:
			_swell = -1.0
			_roar = true
			roar_side = _side
			_react_in = REACT_LAG
	if _react_in >= 0.0:
		_react_in -= dt
		if _react_in <= 0.0:
			_react_in = -1.0
			_react = _side
	_flare_in -= dt
	if _flare_in <= 0.0 and _swell < 0.0:
		_flare = true
		_flare_in = 18.0 + float(goal_i) * 3.0


# How hard the roar hits. x is the SCARED bump, y the ZOOMIES bump. Beside
# her human she joins in; further off it is a fright, louder near the bowl.
static func roar_mood(beside: bool, stadium_dist: float) -> Vector2:
	if beside:
		return Vector2(0.0, 0.8)
	var close := clampf(1.0 - stadium_dist / 2200.0, 0.2, 1.0)
	return Vector2(clampf(0.35 + 0.55 * close, 0.0, 1.0), 0.0)
