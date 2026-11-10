extends SceneTree

# Tests La Ciutadella and El Mamut (systems/ciutadella.gd, systems/boss_mamut.gd):
# - Registration: LEVELS, CAROUSEL (the boss slot after El Besòs), the gates,
#   names, goals, the walk module; the level check
# - The wake holds your human, and only while they are short of him
# - Part one: no attack under his title card; a swipe knocks her in its sector, and one she is clear of wears him down
# - Part two: a charge into the lake splashes him, dazes him, and a boop lands
# - Part three: he goes back to his plinth, three legs tied sits him down, a
#   bark settles him and lets your human walk on
# - The parakeets' swoop on the croissant, shooed with a bark

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _ticks(m: Node2D, secs: float) -> void:
	var n := int(secs / DT)
	for i in range(n):
		m.elapsed += DT
		m.mamut.tick_state(DT)


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "ciutadella"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	# the fight is driven by hand from here: main stands still
	m.set_physics_process(false)
	m.set_process(false)
	var BM: GDScript = load("res://systems/boss_mamut.gd")
	var C: GDScript = load("res://systems/ciutadella.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration
	_check(game.LEVELS.has("ciutadella"), "in LEVELS")
	var ci: int = game.CAROUSEL.find("ciutadella")
	_check(ci == 11 and game.CAROUSEL[ci - 1] == "besos", "walk 11, the first boss slot, after El Besòs: %d" % ci)
	_check(int(game.STAR_GATE["ciutadella"]) == 15, "opens at 15 stars")
	_check(String(game.CHASE_GATE.get("ciutadella", "")) == "besos", "after El Besòs")
	_check(String(game.LEVEL_NAMES["ciutadella"]) == "La Ciutadella", "named La Ciutadella")
	_check(m.walk_mod == C, "its walk module")
	_check(m.gate_text == "ÀREA DE GOSSOS", "the gate says ÀREA DE GOSSOS")
	var ids: Array = G.LEVEL_GOAL_IDS["ciutadella"]
	_check(ids.size() == 15, "15 goals: %d" % ids.size())
	var defs: Dictionary = G.defs(m)
	for id: String in ids:
		_check(defs.has(id), "goal %s is defined" % id)
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	var mam = m.mamut
	_check(mam != null, "El Mamut is built")
	_check(mam.state == BM.State.IDLE and mam.pos == BM.PLINTH, "asleep on his plinth")
	_check(mam.leg_indices.size() == 4 and mam.is_leg_index(mam.leg_indices[0]), "four legs on the rope")
	_check(m.surface_at(Vector2(640.0, -1500.0)) == load("res://world/surfaces.gd").S.PAVEMENT, "the avenue's path is a path")
	_check(m.surface_at(Vector2(900.0, -2900.0)) == load("res://world/surfaces.gd").S.GRASS, "his lawn is grass")

	# 2. A pair already past him leaves him asleep
	m.human.global_position = Vector2(640.0, BM.HOLD_Y - 400.0)
	m.dog.global_position = Vector2(640.0, BM.HOLD_Y - 500.0)
	_ticks(m, 0.5)
	_check(mam.state == BM.State.IDLE, "still asleep with the pair past him")

	# 3. The wake, and the hold
	m.human.global_position = Vector2(640.0, BM.HOLD_Y + 120.0)
	m.dog.global_position = Vector2(640.0, BM.WAKE_Y - 30.0)
	_ticks(m, 0.1)
	_check(mam.state == BM.State.AWAKEN, "wakes as she passes")
	_check(m.human.tut_hold_y == BM.HOLD_Y, "your human is held short of him")
	_ticks(m, BM.AWAKEN_TIME + 0.1)
	_check(mam.state == BM.State.PROWL, "down off the plinth and plodding")
	_check(mam.pos.distance_to(BM.LANDING) < 40.0, "landed in front of the plinth")

	# 4. Part one: a swipe in front of him
	mam.face_dir = Vector2.DOWN
	mam.swipe_cd = 0.0
	mam.stomp_cd = 99.0
	var hits0: int = m.dog_hits
	m.dog.global_position = mam.pos + Vector2(0.0, 150.0)
	m.dog.tumble_t = 0.0
	# not while his title card is up over the banner
	mam.card_t = BM.CARD_FROM + 0.5
	_ticks(m, DT * 2.0)
	_check(mam.state == BM.State.PROWL, "no attack while his card hushes the banner")
	mam.card_t = BM.CARD_TIME + BM.CARD_FROM + 0.1
	_ticks(m, DT * 2.0)
	_check(mam.state == BM.State.SWIPE, "she is in front of him, within reach: he swipes")
	_ticks(m, BM.SWIPE_WARN + 0.05)
	_check(m.dog_hits == hits0 + 1, "the swipe knocks her in its sector")
	_ticks(m, BM.SWIPE_STRIKE + 0.1)
	_check(mam.state == BM.State.PROWL, "and he plods on")
	# a swipe she is clear of: out to one side
	mam.face_dir = Vector2.DOWN
	mam.swipe_cd = 0.0
	m.dog.tumble_t = 0.0
	var hp0: float = mam.hp
	m.dog.global_position = mam.pos + Vector2(0.0, 160.0)
	_ticks(m, DT * 2.0)
	_check(mam.state == BM.State.SWIPE, "a second swipe")
	m.dog.global_position = mam.pos + Vector2(260.0, -20.0)
	_ticks(m, BM.SWIPE_WARN + 0.05)
	_check(m.mamut_dodges == 1 and mam.hp < hp0, "a dodged swipe wears him down: %d, %.0f" % [m.mamut_dodges, mam.hp])
	_ticks(m, BM.SWIPE_STRIKE + 0.1)

	# 5. Part two: furious below half, and the charge into the lake
	mam.damage(mam.hp - 45.0)
	_check(mam.phase == 2, "below half he is in part two")
	_ticks(m, DT)
	_check(mam.state == BM.State.ENRAGE, "he trumpets first")
	_ticks(m, BM.ENRAGE_TIME + 0.1)
	_check(mam.state == BM.State.PROWL and mam.enraged, "then he plods on, furious")
	mam.pos = Vector2(700.0, -2900.0)
	mam.swipe_cd = 99.0
	mam.stomp_cd = 99.0
	mam.charge_cd = 0.0
	m.dog.global_position = Vector2(950.0, -2900.0)
	mam.face_dir = Vector2.LEFT
	_ticks(m, DT * 2.0)
	_check(mam.state == BM.State.CHARGE_WARN, "she is in range: he paws the gravel")
	m.dog.global_position = Vector2(930.0, -2780.0)
	m.dog.tumble_t = 0.0
	var hp1: float = mam.hp
	_ticks(m, BM.CHARGE_WARN + 1.0)
	_check(m.mamut_splashed, "the charge carries him into the lake")
	_check(mam.state == BM.State.STUNNED, "and dazes him")
	_check(absf(hp1 - mam.hp - BM.SPLASH_DAMAGE) < 0.1, "the splash costs him its damage")
	var hp2: float = mam.hp
	m.dog.global_position = mam.trunk_tip() + Vector2(-20.0, 0.0)
	C.on_bark(m, m.dog.global_position)
	_check(m.mamut_booped and mam.hp < hp2, "a bark on his trunk while he is dazed is a boop")
	_ticks(m, BM.SPLASH_STUN + 0.1)
	_check(mam.state == BM.State.SPRAY, "he comes up spraying")
	m.dog.global_position = Vector2(500.0, -2600.0)
	_ticks(m, BM.SPRAY_WARN + BM.SPRAY_TIME + 0.1)
	_check(mam.state == BM.State.PROWL and mam.pos.x < BM.SHORE_X, "and back out of the shallows")

	# 6. Part three: out of fight he goes back to his plinth
	mam.damage(mam.hp)
	_ticks(m, DT)
	_check(mam.state == BM.State.RETREAT, "out of fight he retreats")
	_ticks(m, 6.0)
	_check(mam.state == BM.State.STAND, "the last stand on his plinth")
	m.dog.global_position = BM.PLINTH + Vector2(0.0, 400.0)
	for k in range(3):
		mam.leg_touch_t[k] = m.elapsed
	_ticks(m, DT)
	_check(mam.state == BM.State.WRAPPED, "three legs tied: he wobbles")
	_ticks(m, BM.WOBBLE_TIME + 0.1)
	_check(mam.state == BM.State.SAT and m.mamut_sat, "and sits down hard")
	m.dog.global_position = mam.trunk_tip() + Vector2(0.0, 30.0)
	C.on_bark(m, m.dog.global_position)
	_check(mam.state == BM.State.CONTENT and m.mamut_settled, "a bark on his trunk settles him")
	_ticks(m, DT)
	_check(m.human.tut_hold_y != BM.HOLD_Y, "your human may walk on")

	# 7. The parakeets
	m.human.global_position = Vector2(640.0, C.BIRDS_Y - 20.0)
	C._tick_birds(m, DT)
	_check(String(m.ciut_birds.state) == "warn", "your human sees them first")
	for i in range(int((C.BIRDS_WARN + 0.1) / DT)):
		C._tick_birds(m, DT)
	_check(String(m.ciut_birds.state) == "swoop", "then the flock swoops")
	m.dog.global_position = m.human.global_position + Vector2(60.0, 0.0)
	C.on_bark(m, m.dog.global_position)
	_check(m.ciut_shooed and String(m.ciut_birds.state) == "fled", "a bark shoos them off the croissant")

	print("test_ciutadella: %d checks, %d failures" % [checks, failures.size()])
	for f in failures:
		print("  " + f)
	quit(1 if failures.size() > 0 else 0)
