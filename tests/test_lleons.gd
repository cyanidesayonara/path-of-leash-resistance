extends SceneTree

# Tests El Port and Els Lleons (systems/port.gd, systems/boss_lleons.gd):
# - 1. Registration: in LEVELS, 15 goals in LEVEL_GOAL_IDS["port"], defs, m.lleons built, level check clean
# - 2. Asleep on plinths: Lion A at PLINTH_L, Lion B at PLINTH_R, State.IDLE, two legs registered on leash
# - 3. Wake trigger: dog crosses WAKE_Y, transitions to AWAKEN, holds human at HOLD_Y, then PROWL
# - 4. Phase 1 (Pincer strike): warn telegraph, strike, close miss awards pincer dodge
# - 5. Phase 1 (Roar wind): blast pushes dog, plant reduces push
# - 6. Phase 2 (Double Rush & HEAD BUMP): crossing charge, collision causes HEAD BUMP and stuns both
# - 7. Stunned boop: bark at stunned nose awards boop
# - 8. Phase 3 (Retreat & Stand): below 10% HP retreats to plinths
# - 9. Tying legs: leash touches on both plinth legs transitions to WRAPPED then SAT
# - 10. Double boop victory: barks on both noses settle them into CONTENT

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
		m.lleons.tick_state(DT)


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "port"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)

	var BL: GDScript = load("res://systems/boss_lleons.gd")
	var P: GDScript = load("res://systems/port.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration
	_check(game.LEVELS.has("port"), "in LEVELS")
	_check(String(game.LEVEL_NAMES["port"]) == "El Port", "named El Port")
	_check(m.walk_mod == P, "its walk module is Port")
	var ids: Array = G.LEVEL_GOAL_IDS["port"]
	_check(ids.size() == 15, "15 goals: %d" % ids.size())
	_check(ids.has("lleons_pincer") and ids.has("lleons_bump"), "has lleons_pincer and lleons_bump goals")
	var defs: Dictionary = G.defs(m)
	for id: String in ids:
		_check(defs.has(id), "goal %s is defined" % id)
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	var boss = m.lleons
	_check(boss != null, "Els Lleons is built")
	_check(boss.state == BL.State.IDLE, "starts IDLE")
	_check(boss.lion_a.pos == BL.PLINTH_L and boss.lion_b.pos == BL.PLINTH_R, "lions on plinths")
	_check(boss.leg_indices.size() == 2 and boss.is_leg_index(boss.leg_indices[0]), "two legs in poles")

	# 2. Wake trigger and hold
	m.human.global_position = Vector2(640.0, BL.HOLD_Y + 100.0)
	m.dog.global_position = Vector2(640.0, BL.WAKE_Y - 20.0)
	_ticks(m, 0.1)
	_check(boss.state == BL.State.AWAKEN, "wakes as dog passes WAKE_Y")
	_ticks(m, 3.2)
	_check(boss.state == BL.State.PROWL, "transitions to PROWL after awakening")

	# 3. Phase 1: Pincer dodge
	boss._start_pincer()
	_check(boss.state == BL.State.PINCER_WARN, "starts PINCER_WARN")
	_ticks(m, BL.PINCER_WARN + 0.05)
	_check(boss.state == BL.State.PINCER_STRIKE, "strikes in PINCER_STRIKE")
	# Put dog near lion_a's current position within miss radius
	m.dog.global_position = (boss.lion_a.pos as Vector2) + Vector2(BL.BODY_R + 25.0, 0.0)
	_ticks(m, 0.05)
	_check(m.lleons_pincer_dodges >= 1, "pincer dodged recorded")
	# a second pincer re-arms: it can be dodged again
	var dodges1: int = m.lleons_pincer_dodges
	boss.transition_to(BL.State.PROWL)
	boss._start_pincer()
	_ticks(m, BL.PINCER_WARN + 0.05)
	m.dog.global_position = (boss.lion_a.pos as Vector2) + Vector2(BL.BODY_R + 25.0, 0.0)
	_ticks(m, 0.05)
	_check(m.lleons_pincer_dodges == dodges1 + 1, "each pincer can be dodged")

	# 4. Phase 1: Roar wind push
	boss._start_roar()
	_check(boss.state == BL.State.ROAR_WARN, "starts ROAR_WARN")
	_ticks(m, BL.ROAR_WARN + 0.1)
	_check(boss.state == BL.State.ROAR_BLAST, "blasts ROAR_BLAST")
	m.dog.global_position = boss.roaring_lion.pos + boss.roaring_lion.face_dir * 120.0
	m.dog.velocity = Vector2.ZERO
	m.dog.planted = false
	_ticks(m, 0.1)
	var pushed_vel: float = m.dog.velocity.length()
	_check(pushed_vel > 10.0, "roar wind pushes unplanted dog")
	# planted through the whole roar: paid once, not every frame
	boss.transition_to(BL.State.PROWL)
	boss._start_roar()
	_ticks(m, BL.ROAR_WARN + 0.05)
	m.dog.global_position = boss.roaring_lion.pos + boss.roaring_lion.face_dir * 120.0
	m.dog.planted = true
	var bones_r: int = m.bones
	for i in range(int(BL.ROAR_DUR / 0.05) - 2):
		m.dog.global_position = boss.roaring_lion.pos + boss.roaring_lion.face_dir * 120.0
		_ticks(m, 0.05)
	m.dog.planted = false
	_check(m.bones == bones_r + 2, "planting through a roar pays 2 once (got %d)" % (m.bones - bones_r))

	# 5. Phase 2: Double Rush. Standing in the crossing to the end: run over, no bump
	boss.hp = 45.0
	boss.phase = 2
	boss.transition_to(BL.State.PROWL)
	var stand_at := Vector2(640.0, -4400.0)
	m.dog.global_position = stand_at
	boss._start_rush()
	_check(boss.state == BL.State.RUSH_WARN, "starts RUSH_WARN")
	_check(boss.rush_cross_pos.distance_to(stand_at) < 1.0, "the lanes cross where she stands")
	_ticks(m, BL.RUSH_WARN + 0.05)
	_check(boss.state == BL.State.RUSH_CHARGE, "charges RUSH_CHARGE")
	for i in range(40):
		m.dog.global_position = stand_at
		_ticks(m, 0.05)
	_check(not m.lleons_bumped, "she stayed in the crossing: no head bump")
	_check(boss.state != BL.State.STUNNED, "and they are not dazed")

	# stepped out during the warning: they meet each other
	boss.transition_to(BL.State.PROWL)
	m.dog.global_position = stand_at
	boss._start_rush()
	m.dog.global_position = stand_at + Vector2(0.0, 160.0)
	_ticks(m, BL.RUSH_WARN + 0.05)
	for i in range(30):
		if boss.state != BL.State.RUSH_CHARGE:
			break
		m.dog.global_position = stand_at + Vector2(0.0, 160.0)
		_ticks(m, 0.05)
	_check(boss.state == BL.State.STUNNED, "collided into STUNNED")
	_check(m.lleons_bumped, "HEAD BUMP recorded in main.lleons_bumped")
	_check(boss.lion_a.dazed > 0.0 and boss.lion_b.dazed > 0.0, "both lions dazed")

	# 6. Boop while stunned
	var nose_a: Vector2 = boss.lion_a.pos + boss.lion_a.face_dir * BL.HEAD_R
	var booped: bool = boss.on_bark_action(nose_a)
	_check(booped and boss.lion_a.booped, "bark near lion A nose boops it while stunned")

	# 7. Phase 3: Retreat to plinths below 10% HP
	boss.hp = 8.0
	boss.lion_a.dazed = 0.0
	boss.lion_b.dazed = 0.0
	_ticks(m, 0.1)
	_check(boss.state == BL.State.RETREAT, "retreats to plinths below 10% HP")
	_ticks(m, 2.5)
	_check(boss.state == BL.State.STAND, "stands on plinths")

	# 8. Tangle legs with leash
	boss.leg_touch_t[0] = m.elapsed
	boss.leg_touch_t[1] = m.elapsed
	boss.update_leg_tangle()
	_check(boss.state == BL.State.WRAPPED, "wrapping both plinths triggers WRAPPED")
	_ticks(m, 1.0)
	_check(boss.state == BL.State.SAT, "lions sit down (SAT)")
	_check(m.lleons_tied, "recorded in main.lleons_tied")

	# 9. Double boop settles lions into CONTENT
	boss.lion_a.booped = false
	boss.lion_b.booped = false
	var nose_1: Vector2 = boss.lion_a.pos + boss.lion_a.face_dir * BL.HEAD_R
	var nose_2: Vector2 = boss.lion_b.pos + boss.lion_b.face_dir * BL.HEAD_R
	boss.on_bark_action(nose_1)
	boss.on_bark_action(nose_2)
	_check(boss.lion_a.booped and boss.lion_b.booped, "both lions booped")
	_ticks(m, 0.1)
	_check(boss.state == BL.State.CONTENT, "settled into CONTENT")
	_check(m.lleons_settled, "battle won recorded in main.lleons_settled")

	m.queue_free()
	await process_frame
	print("test_lleons: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
