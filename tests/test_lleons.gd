extends SceneTree

# Tests El Port and Els Lleons (systems/port.gd, systems/boss_lleons.gd):
# - 1. Registration: in LEVELS, 15 goals in LEVEL_GOAL_IDS["port"], defs, m.lleons built, level check clean
# - 2. Asleep on plinths: Lion A at PLINTH_L, Lion B at PLINTH_R, State.IDLE, two legs registered on leash
# - 3. Wake trigger: dog crosses WAKE_Y, transitions to AWAKEN, holds human at HOLD_Y, then PROWL
# - 4. Phase 1 (Pincer strike): warn telegraph, strike, close miss awards pincer dodge
# - 5. Phase 1 (Roar wind): blast pushes dog, plant reduces push
# - 5b. The crane's cargo net: the leash hauled taut on its post drops it after
#   its warning, pinning a lion under it; one outside is unhurt
# - 5c. The mooring bollards: the leash on a leg and a bollard ties him; his
#   twin's strike runs into him; he strains free in time
# - 5d. The Golondrina's horn: bark at the pier, both lions flinch toward it
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


# the dog and your human held at two spots, the rope laid straight between
# them at this rest length
func _lay_leash(m: Node2D, dog_at: Vector2, human_at: Vector2, rest: float) -> void:
	m.dog.global_position = dog_at
	m.human.global_position = human_at
	m.human.rotation = 0.0
	m.leash.rest_len = rest
	m.leash.resnap()



# the rope laid as if wound: from the dog to `via`, once round the last of
# `via`, on to the bollard, once round it, and to your human's hand
func _wind_leash(m: Node2D, via: Array, bol: Vector2, hand: Vector2, rest: float) -> void:
	var path: Array[Vector2] = []
	path.append(via[0])
	var leg: Vector2 = via[via.size() - 1]
	for i in range(9):
		path.append(leg + Vector2.from_angle(PI * 1.2 + TAU * float(i) / 8.0) * 15.0)
	for i in range(9):
		path.append(bol + Vector2.from_angle(PI * 1.2 + TAU * float(i) / 8.0) * 15.0)
	path.append(hand)
	m.dog.global_position = path[0] - m.leash.dog_offset
	m.human.rotation = 0.0
	m.human.global_position = hand - m.leash.hand_offset
	m.leash.rest_len = rest
	# resample the polyline into the rope's points, evenly by length
	var total := 0.0
	for i in range(path.size() - 1):
		total += path[i].distance_to(path[i + 1])
	var n: int = m.leash.N
	var seg := 0
	var acc := 0.0
	for k in range(n):
		var want := total * float(k) / float(n - 1)
		while seg < path.size() - 2 and acc + path[seg].distance_to(path[seg + 1]) < want:
			acc += path[seg].distance_to(path[seg + 1])
			seg += 1
		var l := path[seg].distance_to(path[seg + 1])
		var q := path[seg].lerp(path[seg + 1], clampf((want - acc) / maxf(l, 0.001), 0.0, 1.0))
		m.leash.pts[k] = q
		m.leash.prev[k] = q


# the rope and the fight ticked together, the lions left to move
func _rope_ticks(m: Node2D, secs: float) -> void:
	for i in range(int(secs / DT)):
		m.elapsed += DT
		m.leash.tick(DT)
		m.lleons.tick_state(DT)

# the real rope solved every tick with both ends held, the lions kept where
# the test puts them
func _haul(m: Node2D, boss: Object, a_at: Vector2, b_at: Vector2, secs: float) -> void:
	for i in range(int(secs / DT)):
		boss.lion_a.pos = a_at
		boss.lion_b.pos = b_at
		m.elapsed += DT
		m.leash.tick(DT)
		boss.tick_state(DT)


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

	# 4b. The arena: the crane's cargo net. The leash wound on its post and
	# hauled taut trips it; it drops after its warning and pins a lion under it.
	boss.transition_to(BL.State.PROWL)
	boss.pincer_cd = 99.0
	boss.roar_cd = 99.0
	boss.rush_cd = 99.0
	_check(m.poles.has(BL.NET_POST), "the net's post is a pole the leash wraps")
	var under: Vector2 = BL.NET_C + Vector2(12.0, 18.0)
	var clear: Vector2 = BL.NET_C + Vector2(0.0, -BL.NET_R - 60.0)
	# slack: the leash lies by the post and nothing happens
	_lay_leash(m, BL.NET_POST + Vector2(60.0, -50.0), BL.NET_POST + Vector2(-60.0, 50.0), 400.0)
	_haul(m, boss, under, clear, 0.6)
	_check(boss.net == BL.Net.UP and not boss.net_hauled, "a slack leash by the post leaves the net hanging")
	# hauled: the rope bent round the post, pulled past its length
	_lay_leash(m, BL.NET_POST + Vector2(150.0, -120.0), BL.NET_POST + Vector2(-150.0, 120.0), 340.0)
	var hp_n: float = boss.hp
	var bones_n: int = m.bones
	_haul(m, boss, under, clear, 0.1)
	_check(m.leash.touches(BL.NET_POST), "the rope rests on the post")
	_check(boss.net_hauled, "and is hauled taut on it (taut %.2f)" % m.leash.taut_amount(m.leash.used_length() / m.leash.rest_len))
	_haul(m, boss, under, clear, BL.NET_PULL_HOLD + 0.05)
	_check(boss.net == BL.Net.WARN, "the haul starts the net's warning")
	_haul(m, boss, under, clear, BL.NET_WARN - 0.2)
	_check(boss.net == BL.Net.WARN and float(boss.lion_a.dazed) <= 0.0 and boss.hp == hp_n,
		"nothing falls during the warning")
	_haul(m, boss, under, clear, 0.3)
	_check(boss.net == BL.Net.DOWN, "the net drops after its warning")
	_check(float(boss.lion_a.dazed) > BL.NET_STUN - 0.5, "the lion under it is pinned and dazed")
	_check(float(boss.lion_b.dazed) <= 0.0, "the lion outside it is untouched")
	_check(absf(hp_n - boss.hp - BL.NET_DAMAGE) < 0.1, "the pin costs them %.0f (lost %.0f)" % [BL.NET_DAMAGE, hp_n - boss.hp])
	_check(boss.state == BL.State.STUNNED and boss.stun_net, "the fight stops while he is pinned")
	_check(m.bones == bones_n + 12, "netting a lion pays 12 (got %d)" % (m.bones - bones_n))
	_check(not boss.on_bark_action(boss._nose_of(boss.lion_b)), "the free lion takes no boop")
	_check(boss.on_bark_action(boss.lion_a.pos + boss.lion_a.face_dir * BL.HEAD_R) and boss.lion_a.booped,
		"the pinned lion's nose takes one")
	# he gets up, the crane hauls it back, and it waits to be pulled again
	_lay_leash(m, BL.NET_POST + Vector2(-60.0, 50.0), BL.NET_POST + Vector2(-60.0, 140.0), 400.0)
	_haul(m, boss, under, clear, BL.NET_STUN + 0.2)
	_check(boss.state == BL.State.PROWL, "he gets up out of the net")
	_haul(m, boss, under, clear, BL.NET_HOIST + 0.2)
	_check(boss.net == BL.Net.UP and boss.net_cd > 0.0, "the crane hauls it back up and it reloads")
	boss.pincer_cd = 99.0
	boss.roar_cd = 99.0
	boss.rush_cd = 99.0
	# a drop with both lions clear of it hurts nobody
	boss.net_cd = 0.0
	_lay_leash(m, BL.NET_POST + Vector2(150.0, -120.0), BL.NET_POST + Vector2(-150.0, 120.0), 340.0)
	var hp_m: float = boss.hp
	_haul(m, boss, clear, clear + Vector2(-140.0, 0.0), BL.NET_PULL_HOLD + BL.NET_WARN + 0.3)
	_check(boss.net == BL.Net.DOWN and boss.hp == hp_m and boss.state == BL.State.PROWL,
		"dropped on nobody, it pins nobody")
	_check(boss.net_pins == 1, "one lion netted in all")
	# leave the net and the leash out of the rest of the fight
	boss.net_cd = 999.0
	_lay_leash(m, Vector2(640.0, BL.WAKE_Y - 20.0), Vector2(640.0, BL.HOLD_Y + 100.0), 400.0)
	m.leash.tick(DT)
	boss.lion_a.dazed = 0.0
	boss.lion_b.dazed = 0.0
	boss.transition_to(BL.State.PROWL)

	# 4c. The mooring bollards: the leash on a lion's leg and on a bollard,
	# taut, ties him there; his twin striking runs into him
	boss.hp = 90.0
	boss.transition_to(BL.State.PROWL)
	boss.pincer_cd = 99.0
	boss.roar_cd = 99.0
	boss.rush_cd = 99.0
	var bol: Vector2 = BL.ARENA_BOLLARDS[0]
	_check(m.poles.has(BL.ARENA_BOLLARDS[0]) and m.poles.has(BL.ARENA_BOLLARDS[1]), "the arena bollards are poles")
	var u := Vector2(-0.6, -0.8)
	var leg_at: Vector2 = bol + u * 110.0
	var tie_a: Vector2 = leg_at - u * 14.0
	var far_b := Vector2(560.0, -4330.0)
	boss.lion_a.face_dir = u
	_wind_leash(m, [bol + u * 260.0, leg_at], bol, bol + Vector2(-60.0, 50.0), 400.0)
	_haul(m, boss, tie_a, far_b, 0.1)
	_check(m.leash.touches(boss.leg_poles[0], 12.0) and m.leash.touches(bol), "the rope is wound round his leg and the bollard")
	_haul(m, boss, tie_a, far_b, 0.2)
	_check(boss.held(0) and not boss.held(1), "the lion is tied to the bollard, his twin is not")
	var held_pos: Vector2 = boss.lion_a.pos
	var b_from: Vector2 = boss.lion_b.pos
	_rope_ticks(m, 0.5)
	_check((boss.lion_a.pos as Vector2).distance_to(held_pos) < 0.5, "tied, he cannot move")
	_check((boss.lion_b.pos as Vector2).distance_to(b_from) > 20.0, "his twin still prowls")
	# his twin's pincer runs through him
	boss._start_pincer()
	boss.pincer_targets[1] = held_pos
	boss.lion_b.pos = held_pos + Vector2(-200.0, 0.0)
	var hp_t: float = boss.hp
	var bones_t: int = m.bones
	_rope_ticks(m, BL.PINCER_WARN + 0.9)
	_check(boss.tether_bumps == 1 and boss.state == BL.State.STUNNED, "the pincer runs into his tied twin")
	_check(float(boss.lion_a.dazed) > 0.0 and float(boss.lion_b.dazed) > 0.0, "and both are dazed")
	_check(absf(hp_t - boss.hp - BL.TETHER_BUMP_DAMAGE) < 0.1, "for %.0f damage" % BL.TETHER_BUMP_DAMAGE)
	_check(m.bones == bones_t + 16, "tying one for his twin's charge pays 16 (got %d)" % (m.bones - bones_t))
	_check(not boss.held(0), "the bump unties him")
	_check(m.lleons_bumped, "and it counts as tricking them into colliding")
	m.lleons_bumped = false
	# tied too long, he strains free and cannot be tied again at once
	boss.lion_a.dazed = 0.0
	boss.lion_b.dazed = 0.0
	boss.transition_to(BL.State.PROWL)
	boss.tether_rest.fill(0.0)
	boss.lion_a.face_dir = u
	_wind_leash(m, [bol + u * 260.0, leg_at], bol, bol + Vector2(-60.0, 50.0), 400.0)
	_haul(m, boss, tie_a, far_b, 1.0)
	_check(boss.held(0), "tied again")
	_haul(m, boss, tie_a, far_b, BL.TETHER_MAX)
	_check(not boss.held(0) and boss.tether_rest[0] > 0.0, "after %.0f s he strains free" % BL.TETHER_MAX)
	_lay_leash(m, Vector2(640.0, BL.WAKE_Y - 20.0), Vector2(640.0, BL.HOLD_Y + 100.0), 400.0)
	m.leash.tick(DT)
	boss.tether_t.fill(0.0)
	boss.tether_rest.fill(0.0)
	boss.tether_leg_t.fill(INF)

	# 4d. The Golondrina's horn: bark at the pier, the boat answers after its
	# warning, and both lions flinch toward the sound
	boss.hp = 90.0
	boss.transition_to(BL.State.PROWL)
	boss.pincer_cd = 99.0
	boss.roar_cd = 99.0
	boss.rush_cd = 99.0
	var ha := Vector2(600.0, -4300.0)
	var hb := Vector2(720.0, -4250.0)
	_check(not boss.on_bark_action(Vector2(500.0, -4200.0)) and boss.horn_t < 0.0, "a bark away from the pier sounds no horn")
	_check(boss.on_bark_action(BL.HORN_SPOT + Vector2(-60.0, 0.0)) and boss.horn_t >= 0.0, "a bark at the pier and she answers")
	_haul(m, boss, ha, hb, BL.HORN_WARN - 0.2)
	_check(boss.state == BL.State.PROWL and float(boss.lion_a.dazed) <= 0.0, "nothing until the horn sounds")
	var bones_h: int = m.bones
	_ticks(m, 0.3)
	_check(boss.horn_blasts == 1 and boss.state == BL.State.STUNNED and boss.stun_horn, "the horn: they flinch")
	_check(float(boss.lion_a.dazed) > 0.0 and float(boss.lion_b.dazed) > 0.0, "both lions dazed by it")
	_check((boss.lion_a.pos as Vector2).distance_to(BL.HORN_SPOT) < ha.distance_to(BL.HORN_SPOT) - 20.0
		and (boss.lion_b.pos as Vector2).distance_to(BL.HORN_SPOT) < hb.distance_to(BL.HORN_SPOT) - 20.0,
		"both hop toward the sound")
	_check((boss.lion_a.face_dir as Vector2).dot(((BL.HORN_SPOT - boss.lion_a.pos) as Vector2).normalized()) > 0.9,
		"and look at it")
	_check(m.bones == bones_h + 6, "the horn pays 6 (got %d)" % (m.bones - bones_h))
	_check(not boss.on_bark_action(BL.HORN_SPOT + Vector2(-60.0, 0.0)) and boss.horn_t < 0.0, "the horn waits to reload")
	boss.horn_cd = 999.0
	boss.lion_a.dazed = 0.0
	boss.lion_b.dazed = 0.0
	boss.transition_to(BL.State.PROWL)

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
