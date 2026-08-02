extends Node

# Moods: what the walk feels like from inside the dog.
#
# The scent trail proved that "see the world as a dog does" is a rich seam,
# and a mood is that seam gone deeper. A mood is not a screen tint - it
# changes what the level IS to you. Scared, the world goes cold and narrow and
# you stop being able to read it by nose. Barky, every cat and pigeon on the
# street lights up and matters more than where the human wants to go. The
# picture and the handling move together, so the mood is something you notice
# in your hands before you notice it on the screen.
#
# WEATHER, NOT A MENU. A mood only ever arrives from something that HAPPENED -
# a guard dog waking up, a cat seen off, a snack swallowed whole - and then
# fades on its own. There is no button to choose one and no button to cancel
# one. What the player controls is what they DO about it, and doing the thing a
# mood wants feeds it: barking while barky keeps you barky, running while the
# zoomies are on keeps them going. That is the whole influence model, and it is
# why this reads as the dog reacting rather than the player picking a filter.
#
# The price of having no cancel button is that a mood must never take the game
# away from you, so every effect here is bounded and brief:
#
#   - nothing here changes the camera or the zoom. The one thing the player
#     must always keep is the frame they are playing in.
#   - SCARED narrows what you can SMELL, not what you can see well enough to
#     play. The vignette closes part way, never to a keyhole.
#   - the biggest speed change is a fifth either way, so a mood re-colours how
#     a stretch of pavement handles without ever driving for you.
#   - the longest mood is fifteen seconds and the HUD names it the whole time,
#     so a mood you dislike is never a sentence.
#
# Pure logic, like teeter.gd: main feeds it events and a delta, and reads
# multipliers and a grade back out. No node lookups, no drawing, so the whole
# thing is testable headless.

enum M { HAPPY, SCARED, BARKY, ZOOMIES, FLAT }

# Seconds for a mood at full strength to fade back to nothing. ZOOMIES is the
# shortest deliberately: a real frenetic-activity burst is half a minute of
# madness, not a mode you settle into. FLAT is the longest because a dog that
# has eaten a whole kebab off the pavement does not recover on a timer you
# would call brief.
const FADE := {
	M.SCARED: 9.0,
	M.BARKY: 10.0,
	M.ZOOMIES: 7.0,
	M.FLAT: 15.0,
}

# A mood has to be properly provoked before it takes over, so a single event
# rarely tips you: charge accumulates and only counts as a mood past this.
# Below it the mood is "brewing" and does nothing at all, which keeps one
# startled pigeon from re-grading the screen.
const ONSET := 0.34

# Effects at FULL strength. Everything is a multiplier scaled from 1.0 by the
# mood's intensity, so a half-strength mood is half the change - moods arrive
# and leave as a slide, never a switch.
#
#   speed  top speed
#   accel  how hard she gets to that speed (the "keen" dial)
#   scent  how much of the scent trail still reads
#   pull   how much of your authority the human's autopilot has to fight;
#          above 1 you lunge and the human struggles to steer you
const EFFECT := {
	# fear is fast and stupid: you can run, but you cannot read the world
	M.SCARED: {"speed": 1.16, "accel": 1.30, "scent": 0.35, "pull": 1.10},
	# arousal: keen, lunging, still nose-on but only for the interesting bits
	M.BARKY: {"speed": 1.06, "accel": 1.18, "scent": 0.80, "pull": 1.22},
	# the zoomies: all legs, no steering, and nothing else gets a look in
	M.ZOOMIES: {"speed": 1.22, "accel": 1.45, "scent": 0.55, "pull": 1.15},
	# flat: heavy going, and easy for the human to simply tow
	M.FLAT: {"speed": 0.80, "accel": 0.70, "scent": 0.90, "pull": 0.82},
}

# The grade each mood pulls the picture toward. M.HAPPY holds the authored
# values from grade.gdshader, so a fading mood lands exactly back on the look
# the game ships with rather than somewhere near it.
const GRADE := {
	M.HAPPY: {
		"sat": 1.12, "con": 1.05, "vig": 0.26, "lift": 0.055,
		"cool": Vector3(0.90, 0.95, 1.09), "warm": Vector3(1.07, 1.01, 0.93),
	},
	# cold, drained and closing in. The vignette does the work; the colour
	# just stops being friendly
	M.SCARED: {
		"sat": 0.72, "con": 1.18, "vig": 0.52, "lift": 0.020,
		"cool": Vector3(0.82, 0.90, 1.18), "warm": Vector3(0.92, 0.96, 1.06),
	},
	# everything vivid and too close, the way a street looks when you have
	# decided about it
	M.BARKY: {
		"sat": 1.42, "con": 1.16, "vig": 0.20, "lift": 0.050,
		"cool": Vector3(0.95, 0.95, 1.02), "warm": Vector3(1.16, 1.04, 0.88),
	},
	# wide open and bright: the vignette lifts, which is what makes a burst
	# feel like more room rather than more speed
	M.ZOOMIES: {
		"sat": 1.30, "con": 1.10, "vig": 0.12, "lift": 0.075,
		"cool": Vector3(0.94, 0.98, 1.10), "warm": Vector3(1.12, 1.05, 0.94),
	},
	# washed out and hazy, contrast gone soft - the look of not caring
	M.FLAT: {
		"sat": 0.80, "con": 0.90, "vig": 0.30, "lift": 0.130,
		"cool": Vector3(0.98, 0.98, 1.02), "warm": Vector3(1.02, 1.00, 0.98),
	},
}

# In the dog's own voice, because that gimmick is doing a lot of work for this
# game and a mood is exactly the place for it.
const SAID := {
	M.SCARED: "SOMETHING IS WRONG. STAY LOW.",
	M.BARKY: "EVERYTHING NEEDS TELLING.",
	M.ZOOMIES: "THE LEGS HAVE DECIDED.",
	M.FLAT: "EVERYTHING IS HEAVY.",
}
# and a short badge for the vitals panel, where there is no room for a sentence
const BADGE := {
	M.SCARED: "SCARED",
	M.BARKY: "BARKY",
	M.ZOOMIES: "ZOOMIES",
	M.FLAT: "FLAT",
}
# the colour the line and the badge are said in, pulled from each mood's own
# grade so the words agree with the picture behind them
const TINT := {
	M.SCARED: Color(0.72, 0.80, 1.00),
	M.BARKY: Color(1.00, 0.72, 0.44),
	M.ZOOMIES: Color(0.86, 1.00, 0.62),
	M.FLAT: Color(0.80, 0.78, 0.72),
}

# How fast the picture follows the mood. Slower than the mood itself on
# purpose: the handling changes first and the grade catches up, so you feel a
# mood before you see it. Faster coming back so a mood ending is clean.
const GRADE_RISE := 2.2
const GRADE_FALL := 3.4

# The zoomies do not steer. This is a wobble on top of wherever you pointed,
# from layered sines rather than a random number: it has to be reproducible or
# the autowalk determinism the CI leans on goes with it, and sines at
# unrelated frequencies read as unpredictable perfectly well.
const WOBBLE_DEG := 26.0

var main: Node2D
# charge per mood, 0..1, each decaying on its own clock. Kept separately rather
# than as one "current mood" so a scare landing mid-zoomies competes on merit
# instead of whichever fired last winning
var charge := {}
var active := M.HAPPY
var intensity := 0.0
var t := 0.0
# what the grade is showing right now, chased toward the active mood's target
var shown := {}
var _last_said := M.HAPPY


func _ready() -> void:
	reset()


func setup(m: Node2D) -> void:
	main = m
	reset()


func reset() -> void:
	charge = {M.SCARED: 0.0, M.BARKY: 0.0, M.ZOOMIES: 0.0, M.FLAT: 0.0}
	active = M.HAPPY
	intensity = 0.0
	t = 0.0
	_last_said = M.HAPPY
	shown = (GRADE[M.HAPPY] as Dictionary).duplicate()


# Something happened. amount is how much of a mood it is worth: roughly, 0.2 is
# a nudge that needs company to matter, 0.5 lands a mood on its own, and 1.0 is
# the whole thing at once.
func bump(m: int, amount: float) -> void:
	if m == M.HAPPY or not charge.has(m):
		return
	charge[m] = clampf(float(charge[m]) + amount, 0.0, 1.0)


func tick(delta: float) -> void:
	t += delta
	for m: int in charge:
		var fade: float = float(FADE[m])
		# Scaled by the part of the charge that is actually a mood, so a mood
		# provoked in full lasts FADE seconds before dropping back under ONSET.
		# Decaying at a flat 1/FADE instead would end SCARED in 5.9s while the
		# constant said 9, and every one of these numbers is meant to be
		# tunable by reading it.
		charge[m] = maxf(0.0, float(charge[m]) - delta * (1.0 - ONSET) / fade)
	# strongest charge wins, and only past ONSET, so a mood that is merely
	# brewing leaves the picture and the handling alone
	var best := M.HAPPY
	var best_v := ONSET
	for m: int in charge:
		if float(charge[m]) > best_v:
			best = m
			best_v = float(charge[m])
	active = best
	# rescale so intensity runs 0..1 across the part of the charge that counts,
	# rather than jumping to a third of the effect the instant a mood lands
	intensity = 0.0 if active == M.HAPPY else clampf((best_v - ONSET) / (1.0 - ONSET), 0.0, 1.0)
	_chase_grade(delta)


func _chase_grade(delta: float) -> void:
	var target: Dictionary = GRADE[active]
	var base: Dictionary = GRADE[M.HAPPY]
	# where the picture should be: the mood's look, mixed in by how strong the
	# mood is, so intensity does the blending and the chase only smooths it
	var rate: float = GRADE_RISE if active != M.HAPPY else GRADE_FALL
	var k: float = clampf(rate * delta, 0.0, 1.0)
	for key: String in base:
		var want: Variant = target[key]
		var from: Variant = base[key]
		if want is Vector3:
			var w3: Vector3 = (from as Vector3).lerp(want as Vector3, intensity)
			shown[key] = (shown[key] as Vector3).lerp(w3, k)
		else:
			var wf: float = lerpf(float(from), float(want), intensity)
			shown[key] = lerpf(float(shown[key]), wf, k)


# --- what main reads ---


func speed_mult() -> float:
	return _eff("speed")


func accel_mult() -> float:
	return _eff("accel")


func scent_mult() -> float:
	return _eff("scent")


func pull_mult() -> float:
	return _eff("pull")


func _eff(key: String) -> float:
	if active == M.HAPPY:
		return 1.0
	return lerpf(1.0, float((EFFECT[active] as Dictionary)[key]), intensity)


# BARKY is the one mood that adds information rather than taking it away:
# every creature worth telling off gets picked out.
func lights_targets() -> bool:
	return active == M.BARKY and intensity > 0.25


# A steering wobble for the zoomies, in radians, to be added to wherever the
# player pointed. Zero for every other mood.
func wobble() -> float:
	if active != M.ZOOMIES:
		return 0.0
	var w := sin(t * 5.3) * 0.6 + sin(t * 11.7 + 1.9) * 0.3 + sin(t * 2.1 + 0.7) * 0.1
	return deg_to_rad(WOBBLE_DEG) * w * intensity


func grade() -> Dictionary:
	return shown


func badge() -> String:
	return String(BADGE.get(active, ""))


func tint() -> Color:
	return TINT.get(active, Color.WHITE)


# True once per mood arriving, so main can say the line without repeating it
# every frame the mood is on.
func take_onset() -> String:
	if active == _last_said:
		return ""
	_last_said = active
	if active == M.HAPPY:
		return ""
	return String(SAID.get(active, ""))
