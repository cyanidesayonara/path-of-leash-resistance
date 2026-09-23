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

const STEPS: Array[Dictionary] = [
	{
		"id": "walk",
		"title": "You are the dog.",
		"body": "Walk north with WASD. Your human follows - badly.",
	},
	{
		"id": "pull",
		"title": "The leash is real rope.",
		"body": "Walk on until it goes tight. Feel them drag behind you.",
	},
	{
		"id": "pee",
		"title": "Business first.",
		"body": "Find a hydrant and hold Q to leave your mark.",
	},
	{
		"id": "sniff",
		"title": "A good sniff.",
		"body": "Stand still by a hydrant and have a proper read of it.",
	},
	{
		"id": "nose",
		"title": "Your nose beats your eyes.",
		"body": "SLOW DOWN. The slower you go, the further you smell - follow the drifting scent.",
	},
	{
		"id": "dig",
		"title": "Something is buried here.",
		"body": "Stand on the turned earth and stay put to dig it up.",
	},
	{
		"id": "bark",
		"title": "Use your voice.",
		"body": "Press E to bark. It stops your human dead and scatters birds.",
	},
	{
		"id": "turbo",
		"title": "The zoomies.",
		"body": "Hold SHIFT to burn them off. You are faster than they will ever be.",
	},
	{
		"id": "grind",
		"title": "Ride the kerb.",
		"body": "Run fast along the kerb edge, then counter-steer left/right to hold your balance.",
	},
	{
		"id": "vault",
		"title": "The rope is a pivot.",
		"body": "Catch the leash on a lamppost and keep running - swing round it and fly out.",
	},
	{
		"id": "done",
		"title": "Good dog.",
		"body": "That is the lot. Head north to the park and go and enjoy yourself.",
	},
]


static func step_count() -> int:
	return STEPS.size()


static func step(i: int) -> Dictionary:
	if i < 0 or i >= STEPS.size():
		return {"id": "", "title": "", "body": ""}
	return STEPS[i]
