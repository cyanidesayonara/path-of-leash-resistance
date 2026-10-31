extends SceneTree

# Rambla del Raval, El Gat de Botero (systems/boss_gat.gd), on a real walk:
# - registration, a clean level check, and the fifteen goals the fight can earn
# - the legs: rope points with furniture slip, kept out of the static bodies,
#   that follow him in main.poles, main.rope_soft and the leash's own copy
# - he wakes, prowls north only, and swats where the dust ring was: a hit
#   knocks her, a near miss staggers him
# - below half he charges; a taut leash across his path, a palm, or your
#   human flung into him each stun him, and the rope's ends never count
# - a bark on his nose while dazed is one boop per stun
# - out of fight he walks back to his plinth; three legs within LEG_MEMORY
#   tie him, he topples, and a bark on the snout settles him
# - your human waits short of the plaça until then, and walks on after

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.persist = false
	game._reset_persisted_state()
	root.get_node("Sfx").muted = true
	game.level_id = "raval"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.auto_walk = false

	var BG: GDScript = load("res://systems/boss_gat.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# registration
	_check(game.LEVELS.has("raval") and game.CAROUSEL.has("raval"), "raval is a walk")
	_check(String(game.LEVEL_NAMES.get("raval", "")) == "Rambla del Raval", "named Rambla del Raval")
	_check(m.gate_text == "RAMBLA DEL RAVAL", "gate text")
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	var goal_ids: Array = G.LEVEL_GOAL_IDS.get("raval", [])
	_check(goal_ids.size() == 15, "fifteen goals (found %d)" % goal_ids.size())
	for id: String in ["clothesline", "smash", "pummel", "pigeons", "swat"]:
		_check(id in goal_ids, "'%s' goal on the list" % id)
	var defs: Dictionary = m._goal_defs()
	for id: String in goal_ids:
		_check(defs.has(id), "goal '%s' has a definition" % id)

	# the legs
	var gat = m.boss_gat
	_check(gat != null and gat.state == BG.State.IDLE, "starts asleep")
	_check(gat.leg_indices.size() == 4, "four legs registered")
	for k in range(gat.leg_indices.size()):
		var idx: int = gat.leg_indices[k]
		_check(idx >= int(m.body_pole_count), "leg %d has no static body" % k)
		_check(gat.is_leg_index(idx), "leg %d is a leg index" % k)
		_check(m.rope_soft.has(m.poles[idx]), "leg %d is a soft rope point" % k)
		_check(m.leash.furniture_poles.has(m.poles[idx]), "leg %d slips like furniture" % k)
	_check(not gat.is_leg_index(0), "the first palm is no leg")
	gat.pos += Vector2(10.0, -20.0)
	gat.update_leg_positions()
	var leg0: Vector2 = gat.pos + BG.LEG_OFFSETS[0]
	_check(m.poles[gat.leg_indices[0]] == leg0, "main.poles follows him")
	_check(m.rope_soft[gat.leg_soft_indices[0]] == leg0, "rope_soft follows him")
	_check(m.leash.furniture_poles.has(leg0), "the leash's furniture copy follows him")
	gat.pos = BG.START_PLINTH
	gat.update_leg_positions()

	# wake and prowl
	m.human.global_position = Vector2(640.0, -200.0)
	m.dog.global_position = Vector2(640.0, BG.WAKE_Y - 40.0)
	gat.tick_state(0.016)
	_check(gat.state == BG.State.AWAKEN, "she walks past WAKE_Y: he wakes")
	_check(gat.card != null and gat.card_t >= 0.0, "the title card comes up")
	for i in range(int(BG.AWAKEN_TIME / 0.05) + 2):
		gat.tick_state(0.05)
	_check(gat.state == BG.State.PROWL, "the wake played, he climbs down")
	_check(gat.plinth_cracked, "his plinth cracked on the way")
	_check(gat.pos.y < BG.START_PLINTH.y - BG.PLINTH_HALF.y, "he lands off the front of his plinth")
	m.dog.global_position = Vector2(640.0, 400.0)
	var y0: float = gat.pos.y
	m.human.global_position = Vector2(640.0, -1200.0)
	for i in range(60):
		gat.tick_state(0.016)
	_check(gat.pos.y < y0, "he prowls ahead of your human")
	var y1: float = gat.pos.y
	m.human.global_position = Vector2(640.0, 200.0)
	for i in range(60):
		gat.tick_state(0.016)
	_check(gat.pos.y <= y1, "he never walks back south")

	# the swat: a hit, then a near miss
	gat.swat_cooldown = 0.0
	m.dog.global_position = gat.pos + Vector2(0.0, 90.0)
	gat.tick_state(0.016)
	_check(gat.state == BG.State.SWAT, "she comes close: he swats")
	_check(not gat.dust_rings.is_empty(), "the dust ring telegraphs it")
	var dodged0: int = m.gat_swats_dodged
	var hp0: float = gat.hp
	m.dog.global_position = gat.swat_pos
	gat.tick_state(BG.SWAT_WARN + 0.01)
	_check(gat.state == BG.State.PROWL, "the swat lands and he prowls on")
	_check(m.gat_swats_dodged == dodged0 and gat.hp == hp0, "a hit is no dodge")
	gat.swat_cooldown = 0.0
	m.dog.global_position = gat.pos + Vector2(0.0, 90.0)
	gat.tick_state(0.016)
	m.dog.global_position = gat.swat_pos + Vector2(90.0, 0.0)
	gat.tick_state(BG.SWAT_WARN + 0.01)
	_check(m.gat_swats_dodged == dodged0 + 1, "a near miss is a dodge")
	_check(is_equal_approx(gat.hp, hp0 - BG.DODGE_DAMAGE), "a dodge staggers him")

	# phase two
	gat.damage_boss(gat.hp - BG.MAX_HP * 0.5)
	_check(gat.phase == 2, "half his health gone: he charges")
	gat.transition_to(BG.State.PROWL)
	_check(gat.state == BG.State.ENRAGE, "back on his feet below half, he rears up first")
	for i in range(int(BG.ENRAGE_TIME / 0.05) + 2):
		gat.tick_state(0.05)
	_check(gat.state != BG.State.ENRAGE and gat.enraged, "and only once")
	gat.transition_to(BG.State.PROWL)
	_check(gat.state == BG.State.PROWL, "the next time he just prowls")

	# solid: she is kept out of his body
	m.dog.global_position = gat.pos + Vector2(10.0, 5.0)
	gat.swat_cooldown = 99.0
	gat.charge_cooldown = 99.0
	gat.tick_state(0.016)
	_check(m.dog.global_position.distance_to(gat.pos) >= BG.BODY_R - 0.5, "she cannot stand inside him")

	# the clothesline: a taut rope across his body, then only its ends
	gat.hp = 90.0
	gat.pos = Vector2(640.0, -1000.0)
	gat.update_leg_positions()
	m.dog.global_position = Vector2(500.0, -1000.0)
	m.human.global_position = Vector2(780.0, -1000.0)
	_lay_rope(m, Vector2(500.0, -1000.0), Vector2(780.0, -1000.0))
	gat.transition_to(BG.State.CHARGE)
	gat.charge_dir = Vector2.ZERO
	_check(gat.check_clothesline(), "a taut rope across him is a clothesline")
	gat.tick_state(0.016)
	_check(bool(m.gat_clotheslined) and gat.state == BG.State.STUNNED, "the clothesline stuns him")
	_check(is_equal_approx(gat.hp, 90.0 - BG.CLOTHESLINE_DAMAGE), "for CLOTHESLINE_DAMAGE")
	gat.pos = m.leash.pts[0] + Vector2(-30.0, 0.0)
	_check(not gat.check_clothesline(), "rope at her collar is no clothesline")
	gat.pos = Vector2(640.0, -1000.0)
	_lay_rope(m, Vector2(100.0, 100.0), Vector2(200.0, 100.0))

	# one boop per stun
	var nose: Vector2 = gat.pos + gat.face_dir * 48.0
	var hp_b: float = gat.hp
	_check(gat.on_bark_action(nose), "a bark on his nose while dazed is a boop")
	_check(is_equal_approx(gat.hp, hp_b - BG.BOOP_DAMAGE), "the boop hurts his pride")
	_check(not gat.on_bark_action(nose), "one boop per stun")

	# the palm
	gat.hp = 90.0
	gat.transition_to(BG.State.CHARGE)
	gat.charge_dir = Vector2.ZERO
	gat.pos = BG.PALMS[4] + Vector2(10.0, 10.0)
	gat.tick_state(0.016)
	_check(bool(m.gat_tree_smashed) and gat.state == BG.State.STUNNED, "a palm in his path stuns him")

	# your human, flung
	gat.hp = 90.0
	gat.transition_to(BG.State.CHARGE)
	gat.charge_dir = Vector2.ZERO
	gat.pos = Vector2(640.0, -1500.0)
	m.human.global_position = gat.pos + Vector2(20.0, 20.0)
	m.human.whirl_flung_t = 1.0
	gat.tick_state(0.016)
	_check(bool(m.gat_human_pummeled) and gat.state == BG.State.STUNNED, "your human flung into him stuns him")
	m.human.whirl_flung_t = 0.0

	# your human waits short of the plaça
	m.human.global_position = Vector2(640.0, BG.HOLD_Y + 100.0)
	gat.tick_state(0.016)
	_check(m.human.tut_hold_y == BG.HOLD_Y, "your human holds at HOLD_Y while he is up")
	_check(gat.status() == "" or gat.status() == gat.status().to_upper(), "the banner is in capitals")

	# out of fight: home to the plinth
	gat.hp = 0.0
	gat.transition_to(BG.State.PROWL)
	_check(gat.state == BG.State.RETREAT, "out of fight he retreats")
	for i in range(1200):
		gat.tick_state(0.05)
		if gat.state != BG.State.RETREAT:
			break
	_check(gat.state == BG.State.ROAR and gat.pos == BG.PEDESTAL_POS, "he reaches his plinth and roars")
	_check(gat.status().begins_with("WRAP THE LEASH"), "the banner asks for the tangle")
	var phase_was: String = m.phase
	var poop_was: int = m.poop_state
	m.phase = "out"
	m.poop_state = 1
	m._update_hud()
	_check(m.hud_status.begins_with("WRAP THE LEASH"), "the last stand outranks the bladder's banner: %s" % m.hud_status)
	m.phase = phase_was
	m.poop_state = poop_was

	# the last stand: he swats at her, telegraphed, while she ties him
	m.dog.global_position = gat.pos + Vector2(110.0, 30.0)
	gat.ls_swat_cd = 0.0
	gat.tick_state(0.016)
	_check(gat.ls_swat_t > 0.0 and not gat.dust_rings.is_empty(), "on his plinth he still swats, with a ring first")
	var cracks0: int = gat.cracks.size()
	gat.tick_state(BG.SWAT_WARN + 0.01)
	_check(gat.cracks.size() == cracks0 + 1 and gat.state == BG.State.ROAR, "the paw lands and he fights on")
	m.dog.global_position = Vector2(640.0, BG.HOLD_Y + 200.0)

	# the tangle: two legs, a stale third, then three in time
	m.elapsed = 100.0
	gat.leg_touch_t.assign([100.0, 100.0, 100.0 - BG.LEG_MEMORY - 0.1, -INF])
	gat.update_leg_tangle()
	_check(gat.state == BG.State.ROAR and gat.legs_tied == 2, "a leg touched too long ago does not count")
	gat.leg_touch_t[2] = 99.5
	gat.update_leg_tangle()
	_check(gat.state == BG.State.WRAPPED, "three legs in LEG_MEMORY tie him up")
	gat.tick_state(BG.WOBBLE_TIME * 0.5)
	_check(gat.state == BG.State.WRAPPED, "tied, he teeters first")
	gat.tick_state(BG.WOBBLE_TIME * 0.5 + 0.01)
	_check(gat.state == BG.State.TOPPLED and bool(m.gat_toppled), "tied, he topples")
	_check(not gat.on_bark_action(Vector2.ZERO) or gat.state != BG.State.PURR, "a bark far away does nothing")
	m.dog.global_position = gat.snout_pos + Vector2(30.0, 0.0)
	_check(gat.on_bark_action(gat.snout_pos), "a bark on the snout")
	_check(gat.beaten() and bool(m.gat_booped), "settles him for good")
	for i in range(50):
		gat.tick_state(0.1)
	_check(gat.fireworks_left == 0, "fireworks over the plaça")
	gat.tick_state(0.016)
	_check(m.human.tut_hold_y != BG.HOLD_Y, "your human walks on into the plaça")

	_check(game.persist == false, "no save was written")
	m.queue_free()
	await process_frame
	if failures.is_empty():
		print("test_boss_gat: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_boss_gat: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)


# Lay the rope straight from a to b, stretched well past its rest length.
func _lay_rope(m: Node2D, a: Vector2, b: Vector2) -> void:
	var n: int = m.leash.pts.size()
	for i in range(n):
		var p: Vector2 = a.lerp(b, float(i) / float(n - 1))
		m.leash.pts[i] = p
		if i < m.leash.prev.size():
			m.leash.prev[i] = p
	m.leash.rest_len = a.distance_to(b) * 0.8
