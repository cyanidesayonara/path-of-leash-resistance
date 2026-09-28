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

# Each lesson has a STATION: "at" is how far up the walk it stands, far enough
# from the next that only one is on screen, holding exactly what the lesson
# needs and nothing else (see LevelBuild.tutorial_stations). "hold" means the
# owner waits at the station until the lesson lands or is skipped, so nothing
# is ever rushed; a lesson that needs the owner walking leaves it off.
const STEPS: Array[Dictionary] = [
	{
		"id": "walk", "at": 60.0, "hold": false,
		"title": "You are the dog.",
		"body": "Walk north with {move_with}. Your human follows - badly.",
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
		"id": "pee", "at": -1220.0, "hold": true,
		"title": "Business first.",
		"body": "Go to the hydrant and hold {pee} to leave your mark.",
	},
	{
		"id": "sniff", "at": -1620.0, "hold": true,
		"title": "A good sniff.",
		"body": "Stand still by the next hydrant and have a proper read of it.",
	},
	{
		"id": "nose", "at": -2020.0, "hold": true,
		"title": "Your nose beats your eyes.",
		"body": "Someone dropped a snack on the grass. SLOW DOWN: the slower you go, the further you smell. Find it.",
	},
	{
		"id": "bark", "at": -2420.0, "hold": true,
		"title": "Use your voice.",
		"body": "Press {bark} at the pigeons. It scatters them, and stops your human dead.",
	},
	{
		"id": "turbo", "at": -2820.0, "hold": true,
		"title": "The zoomies.",
		"body": "Hold {turbo} to burn them off. You are faster than they will ever be.",
	},
	{
		"id": "grind", "at": -3220.0, "hold": true,
		"title": "Ride the kerb.",
		"body": "Run fast along the edge of the path, then counter-steer left/right to keep your balance.",
	},
	{
		"id": "vault", "at": -3620.0, "hold": true,
		"title": "The rope is a pivot.",
		"body": "Catch the leash on the lamppost and keep running - swing round it and fly out.",
	},
	{
		"id": "fling", "at": -4020.0, "hold": true,
		"title": "Tetherball.",
		"body": "Your human is waiting by the post. Run round it twice to wind them up, then pull away.",
	},
	{
		"id": "teeter", "at": -4400.0, "hold": true,
		"title": "The brink.",
		"body": "Run at the pond's edge. When you wobble, scramble the other way.",
	},
	{
		"id": "bag", "at": -4780.0, "hold": true,
		"title": "Nature calls.",
		"body": "Stand still and hold {plant} to go. Your human bags it - eventually.",
	},
	{
		"id": "dig", "at": -5200.0, "hold": false,
		"title": "Off the lead.",
		"body": "In the dog park: stand on the turned earth and stay put to dig something up.",
	},
	{
		"id": "done", "at": -5300.0, "hold": false,
		"title": "Good dog.",
		"body": "That is the lot. Fetch the ball, then take your human home.",
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
