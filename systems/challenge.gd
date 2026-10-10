extends Node

# Combo Phase B: a self-contained, optional combo CHALLENGE handed out by
# a character on the walk. It is a bounded window with a target number of
# tricks - land them in time and it pays out. The walk itself stays
# time-free; only the challenge has a clock, and failing costs nothing.
#
# A dare goes through three phases, and the card under the banner
# (hud/event_feed.gd) shows each one:
#   "offer"  the telegraph: what to do and how long there is, read BEFORE the
#            clock starts (OFFER_S, like every other event in the game, only
#            long enough to read a sentence)
#   "live"   the clock runs; the card shows tricks landed and time left
#   "end"    how it went, for END_S: the payout, or what was needed
# begin() skips the offer and starts the clock at once (tests, and anything
# that has already said its piece).

const OFFER_S := 2.6
const END_S := 3.2

var main: Node2D
var phase := ""
var active := false
var done := false
var succeeded := false
var target := 0
var count := 0
var timer := 0.0
var duration := 0.0
# what a win pays, and whether this is a second go
var reward := 0
var retry := false
var offer_t := 0.0
var end_t := 0.0


func setup(m: Node2D) -> void:
	main = m


# Say the dare first; the clock starts when the offer has been up OFFER_S.
func offer(trick_target: int, seconds: float, pays: int, again := false) -> void:
	phase = "offer"
	active = false
	done = false
	succeeded = false
	target = maxi(1, trick_target)
	count = 0
	duration = maxf(0.1, seconds)
	timer = duration
	reward = pays
	retry = again
	offer_t = OFFER_S
	end_t = 0.0


func begin(trick_target: int, seconds: float) -> void:
	phase = "live"
	active = true
	done = false
	succeeded = false
	target = maxi(1, trick_target)
	count = 0
	duration = maxf(0.1, seconds)
	timer = duration
	offer_t = 0.0
	end_t = 0.0


func add_trick() -> void:
	if not active:
		return
	count += 1
	if count >= target:
		_finish(true)


func tick(delta: float) -> void:
	if phase == "offer":
		offer_t -= delta
		if offer_t <= 0.0:
			offer_t = 0.0
			var pays := reward
			var again := retry
			begin(target, duration)
			reward = pays
			retry = again
			if main != null and main.has_method("on_challenge_live"):
				main.on_challenge_live()
		return
	if phase == "end":
		end_t -= delta
		if end_t <= 0.0:
			end_t = 0.0
			phase = ""
		return
	if not active:
		return
	timer -= delta
	if timer <= 0.0:
		timer = 0.0
		_finish(false)


# The card is up from the offer until the result has been read.
func showing() -> bool:
	return phase != ""


func fraction() -> float:
	return clampf(timer / duration, 0.0, 1.0) if duration > 0.0 else 0.0


# How far through the offer's telegraph, 0 to 1.
func offer_fraction() -> float:
	return clampf(1.0 - offer_t / OFFER_S, 0.0, 1.0)


func _finish(win: bool) -> void:
	active = false
	done = true
	succeeded = win
	phase = "end"
	end_t = END_S
	if main != null:
		main.on_challenge_done(win, target, count)
