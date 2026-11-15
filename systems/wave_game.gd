class_name WaveGame
extends RefCounted

const EventFeed := preload("res://hud/event_feed.gd")

# The dog beach's own off-leash game: the waves. The sea is to the west; a
# wave builds out there (a white crest thickening: the telegraph), rushes up
# the sand, holds, and drains back, leaving the sand dark and wet. Follow it
# out as it drains and outrun the next one: the further out she dared, the
# more it pays, and dry escapes in a row add up. Caught by the water she is
# soaked and the streak is gone. Six waves. The autowalk never plays it.
#
# Pure in its rules (front_off, judge): positions in, results out
# (tests/test_wave_game.gd); main supplies the shoreline.

const WAVES := 6
const BUILD_S := 0.8          # the crest out at sea: the telegraph
const SURGE_S := 0.9          # up the sand
const HOLD_S := 0.3
const DRAIN_S := 1.6          # back down, leaving it wet
const LULL_S := 1.4           # the sand clear before the next one builds
const SURGE := 120.0          # how far up the sand a wave runs past the shoreline
const DARE := 40.0            # out this close to the shoreline (or past it) counts as daring
const PAY_MAX := 6
const START_S := 2.0          # a beat after she comes off the leash

enum P { LULL, BUILD, SURGE, HOLD, DRAIN }

var phase := P.LULL
var phase_t := START_S
var wave := 0
var streak := 0
var deepest := INF            # how far out (shore-relative x, negative is out) she got this lull
var soaked := false
var done := false


func phase_len() -> float:
	match phase:
		P.BUILD: return BUILD_S
		P.SURGE: return SURGE_S
		P.HOLD: return HOLD_S
		P.DRAIN: return DRAIN_S
	return LULL_S


# where the water's edge is, past the shoreline, right now
func front_off() -> float:
	var u := 1.0 - phase_t / phase_len()
	match phase:
		P.SURGE:
			return SURGE * (1.0 - pow(1.0 - u, 2.0))
		P.HOLD:
			return SURGE
		P.DRAIN:
			return SURGE * (1.0 - u * u)
	return 0.0


# how much the crest has built out at sea (0..1)
func crest() -> float:
	if phase == P.BUILD:
		return 1.0 - phase_t / BUILD_S
	return 0.0


# one frame: `rel` is her x relative to the shoreline at her y (negative is
# out in the sea). Returns events: ["dared"], ["outran", pay, streak],
# ["soaked"], ["done"].
func step(rel: float, delta: float) -> Array:
	var ev: Array = []
	if done:
		return ev
	phase_t -= delta
	# daring: out near the water's edge while it is drained back
	if phase == P.LULL or phase == P.BUILD or phase == P.DRAIN:
		if rel < front_off() + DARE and rel < deepest:
			if deepest >= DARE and rel < DARE:
				ev.append(["dared"])
			deepest = rel
	# caught: the water's edge past her
	if not soaked and (phase == P.SURGE or phase == P.HOLD) and rel < front_off() - 4.0:
		soaked = true
		streak = 0
		ev.append(["soaked"])
	if phase_t > 0.0:
		return ev
	match phase:
		P.LULL:
			phase = P.BUILD
		P.BUILD:
			phase = P.SURGE
			soaked = false
		P.SURGE:
			phase = P.HOLD
		P.HOLD:
			# the wave at its height: did she dare it and stay dry?
			if not soaked and deepest < DARE:
				streak += 1
				ev.append(["outran", pay_for(deepest, streak), streak])
			phase = P.DRAIN
			deepest = INF
			wave += 1
		P.DRAIN:
			if wave >= WAVES:
				done = true
				ev.append(["done"])
				return ev
			phase = P.LULL
	phase_t += phase_len()
	return ev


# further out pays more; a run of dry escapes adds one each
static func pay_for(deep: float, streak_n: int) -> int:
	var out := clampf((DARE - deep) / 20.0, 0.0, float(PAY_MAX - 1))
	return 1 + int(out) + maxi(0, streak_n - 1)
