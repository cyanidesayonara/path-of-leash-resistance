extends RefCounted

# THE FIRST WALK: a calm, safe place to learn each verb one at a time.
#
# We have accumulated a lot of mechanics - some obvious (walk, pee), some
# absolutely not (grind, vault, the nose, the teeter) - and nothing taught
# them. This is the fix: no traffic, no chases, no walkers, nothing that can
# end your walk, and one instruction at a time with room to practise it for
# as long as you like before the next arrives.
#
# The steps are DATA so the teaching order can be retuned without touching
# the driver, and every one is skippable, because a tutorial that traps a
# player who cannot do the thing is worse than no tutorial at all. Order
# runs from "you already know this" to "nobody would guess this".
#
# Two parts. THE BASICS (up to "bag") are what every walk needs; then a card
# offers the first real walk straight away, or the tricks for whoever wants
# them. THE TRICKS end in the dog park, and the tutorial ends there too: no
# long walk home with nothing left to learn.

# Each lesson has a STATION: "at" is how far up the walk it stands, far enough
# from the next that only one is on screen, holding exactly what the lesson
# needs and nothing else (see LevelBuild.tutorial_stations). "hold" means the
# owner waits at the station until the lesson lands or is skipped, so nothing
# is ever rushed; a lesson that needs the owner walking leaves it off.
# "stand" (-1 west, 1 east) puts the waiting owner by that edge of the path,
# for a lesson whose target is off to one side. "meter" names the HUD meter the
# lesson uses (hud_panel.gd outlines it while the lesson is up).
const STEPS: Array[Dictionary] = [
	{
		"id": "walk", "at": 60.0, "hold": false,
		"title": "Walkies.",
		"body": "Walk up the path with {move_with}. Your human follows - badly.",
	},
	{
		"id": "pull", "at": -420.0, "hold": true,
		"title": "The leash is real rope.",
		"body": "Your human has stopped. Walk on until the rope goes tight.",
	},
	{
		"id": "plant", "at": -820.0, "hold": false,
		"title": "Dig in.",
		"body": "Hold {plant} while the rope is tight. Your human cannot budge you.",
	},
	{
		"id": "pee", "at": -1220.0, "hold": true, "meter": "tank",
		"title": "Business first.",
		"body": "Hold {pee} at the hydrant to leave your mark. Your tank is the yellow bar.",
	},
	{
		"id": "sniff", "at": -1620.0, "hold": true,
		"title": "A good sniff.",
		"body": "Stand still by the next hydrant and have a proper read of it.",
	},
	{
		"id": "nose", "at": -2020.0, "hold": true, "stand": -1,
		"title": "Your nose beats your eyes.",
		"body": "A snack is somewhere on the grass. Go slowly: the slower you go, the further you smell.",
	},
	{
		"id": "bark", "at": -2420.0, "hold": true,
		"title": "Use your voice.",
		"body": "Press {bark} at the pigeons. It scatters them, and stops your human dead.",
	},
	{
		"id": "turbo", "at": -2820.0, "hold": true, "meter": "zoomies",
		"title": "The zoomies.",
		"body": "Hold {turbo} to burn off the green bar. You are faster than they will ever be.",
	},
	{
		"id": "bag", "at": -3220.0, "hold": true,
		"title": "Nature calls.",
		"body": "Stand still and hold {plant} to squat. Your human bags it - eventually.",
	},
	{
		"id": "vault", "at": -3620.0, "hold": true,
		"title": "The rope is a pivot.",
		"body": "Hold {turbo}, catch the leash on the lamppost and keep running - swing round it and fly out.",
	},
	{
		"id": "fling", "at": -4020.0, "hold": true,
		"title": "Tetherball.",
		"body": "Your human is waiting by the post. Run round it twice to wind them up, then pull away.",
	},
	{
		"id": "grind", "at": -4400.0, "hold": true,
		"title": "Ride the ledge.",
		"body": "Hold {turbo} and run along the stone ledge to get up on it. Steer against the wobble.",
	},
	{
		"id": "teeter", "at": -4780.0, "hold": true, "stand": 1,
		"title": "The brink.",
		"body": "Run at the pond's edge. When you wobble, scramble the other way.",
	},
	{
		"id": "dig", "at": -5200.0, "hold": false,
		"title": "Off the leash.",
		"body": "In the dog park: stand on the turned earth and stay put to dig something up.",
	},
	{
		"id": "done", "at": -5300.0, "hold": false,
		"title": "Good dog.",
		"body": "That is the lot. The park is yours: go and play.",
	},
]


static func index_of(id: String) -> int:
	for i in range(STEPS.size()):
		if String(STEPS[i]["id"]) == id:
			return i
	return -1


static func at(id: String) -> float:
	var i := index_of(id)
	return float(STEPS[i]["at"]) if i >= 0 else 0.0


static func step_count() -> int:
	return STEPS.size()


static func step(i: int) -> Dictionary:
	if i < 0 or i >= STEPS.size():
		return {"id": "", "title": "", "body": "", "at": 0.0, "hold": false}
	return STEPS[i]
