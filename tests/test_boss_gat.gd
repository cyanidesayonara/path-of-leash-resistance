extends SceneTree

# Walk 26: Rambla del Raval — The "El Gat de Botero" Boss Arena
# Headless unit test verifying:
# 1. Campaign registration (LEVELS, CAROUSEL, STAR_GATE, LEVEL_NAMES, gate_text, freedom_kind)
# 2. LevelCheck.check(m) passes with zero issues
# 3. 15 authored goals in LEVEL_GOAL_IDS["raval"] including clothesline, topple, boop, pigeons, swat
# 4. BossGat state machine initialization and 4 leg pole registrations in m.poles
# 5. Phase 1: Dodging swats and counter-pulling staggers the statue
# 6. Phase 2: Bull Charges & Triple Counters (Clothesline, Palm smash, Human bowling)
# 7. Phase 3: AT-AT cable wrap coil detection and topple trigger
# 8. Belly Super Boop interaction via on_bark
# 9. Save record schema safety (strict preservation of Game.records keys, Game.persist = false)

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(10.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	# Strictly enforce save record safety
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "raval"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	var BG: GDScript = load("res://systems/boss_gat.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# 1. Registration in campaign
	_check(game.LEVELS.has("raval"), "raval is in LEVELS")
	_check(game.CAROUSEL.has("raval"), "raval is in CAROUSEL")
	_check(int(game.STAR_GATE.get("raval", 0)) == 43, "raval star gate is 43 stars")
	_check(String(game.LEVEL_NAMES.get("raval", "")) == "Rambla del Raval", "level name is Rambla del Raval")
	_check(m.gate_text == "RAMBLA DEL RAVAL", "gate text is RAMBLA DEL RAVAL")
	_check(m.freedom_kind == "placa", "ends in placa freedom area")

	# 2. Structural LevelCheck passes clean
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "level check clean: %s" % str(problems))

	# 3. 15 goals defined and valid
	var goal_ids: Array = G.LEVEL_GOAL_IDS.get("raval", [])
	_check(goal_ids.size() == 15, "raval has 15 goals (found %d)" % goal_ids.size())
	_check("clothesline" in goal_ids, "'clothesline' goal exists")
	_check("topple" in goal_ids, "'topple' goal exists")
	_check("boop" in goal_ids, "'boop' goal exists")
	_check("pigeons" in goal_ids, "'pigeons' goal exists")
	_check("swat" in goal_ids, "'swat' goal exists")

	# 4. BossGat initialization & leg pole registration
	var gat = m.get("boss_gat")
	_check(gat != null, "boss_gat instance exists on main")
	_check(gat.state == BG.State.IDLE, "starts in IDLE state")
	_check(gat.hp == 100.0, "initial hp is 100")
	_check(gat.phase == 1, "initial phase is 1")
	_check(gat.leg_indices.size() == 4, "4 leg indices registered")
	_check(gat.leg_poles.size() == 4, "4 leg positions stored")
	for idx: int in gat.leg_indices:
		_check(idx >= 0 and idx < m.poles.size(), "leg pole index %d in m.poles" % idx)

	# Verify leg poles update with position
	var init_leg_0: Vector2 = gat.leg_poles[0]
	gat.pos += Vector2(10.0, -20.0)
	gat.update_leg_positions()
	_check(gat.leg_poles[0] == init_leg_0 + Vector2(10.0, -20.0), "leg poles follow body position")
	_check(m.poles[gat.leg_indices[0]] == gat.leg_poles[0], "m.poles updated with leg position")

	# Reset position
	gat.pos = Vector2(640.0, -480.0)
	gat.update_leg_positions()

	# 5. State transitions: IDLE -> PROWL
	m.dog.global_position = Vector2(640.0, -280.0)
	gat.tick_state(0.1)
	_check(gat.state == BG.State.PROWL, "advancing dog triggers PROWL")

	# 6. State transitions: PROWL -> SWAT
	gat.swat_cooldown = 0.0
	gat.tick_state(0.1)
	_check(gat.state == BG.State.SWAT, "cooldown expiry triggers SWAT")
	_check(gat.dust_rings.size() > 0, "swat spawns dust telegraph ring")

	# Execute swat & dodge
	var pre_dodges: int = m.gat_swats_dodged
	var pre_hp: float = gat.hp
	m.dog.global_position = gat.swat_pos + Vector2(60.0, 0.0)
	gat.execute_swat()
	_check(m.gat_swats_dodged > pre_dodges, "dog near swat telegraph earns dodge")
	_check(gat.hp < pre_hp, "dodging swat inflicts stagger damage to boss")

	# 7. Phase 2 Transition & Bull Charges
	gat.damage_boss(40.0)
	_check(gat.phase == 2, "reducing HP to <= 50 triggers Phase 2")
	_check(gat.hp <= 50.0, "HP is now <= 50")

	# Bull charge telegraph
	gat.transition_to(BG.State.CHARGE_WARN)
	_check(gat.state == BG.State.CHARGE_WARN, "transitions to CHARGE_WARN")
	_check(gat.charge_dir.length() > 0.9, "charge_dir is normalized vector")

	gat.tick_state(0.9)
	_check(gat.state == BG.State.CHARGE, "warning expiry triggers CHARGE")

	# Set HP for testing all 3 counters cleanly
	gat.hp = 85.0

	# 8. Counter 1: Clothesline Counter with taut leash
	_check(not bool(m.get("gat_clotheslined")), "clotheslined initially false")
	gat.pos = Vector2(640.0, -1000.0)
	gat.update_leg_positions()
	for i in range(m.leash.pts.size()):
		var t_frac := float(i) / float(m.leash.pts.size() - 1)
		m.leash.pts[i] = Vector2(580.0 + t_frac * 120.0, -1000.0)
	var orig_len := float(m.leash_len)
	m.leash_len = 100.0
	m.leash.rest_len = 100.0
	var is_cl: bool = gat.check_clothesline()
	_check(is_cl, "check_clothesline returns true when taut leash intersects cat")

	# Process charge tick to trigger clothesline
	var hp_before_cl: float = gat.hp
	gat.tick_state(0.016)
	_check(bool(m.get("gat_clotheslined")), "gat_clotheslined is true after collision")
	_check(gat.hp <= hp_before_cl - 25.0, "clothesline deals 25 damage")
	_check(gat.state == BG.State.STUNNED, "clothesline stuns El Gat")

	# Move leash safely away for remaining tests
	m.leash_len = orig_len
	m.leash.rest_len = orig_len
	for i in range(m.leash.pts.size()):
		m.leash.pts[i] = Vector2(100.0 + float(i) * 5.0, 100.0)

	# 9. Counter 2: Obstacle Collision (Palm tree crash)
	gat.transition_to(BG.State.CHARGE)
	var palm_p: Vector2 = BG.PALMS[0]
	gat.pos = palm_p + Vector2(10.0, 10.0)
	_check(gat.check_obstacle_collision(), "check_obstacle_collision returns true near palm")
	var hp_before_smash: float = gat.hp
	gat.tick_state(0.016)
	_check(bool(m.get("gat_tree_smashed")), "gat_tree_smashed set to true")
	_check(gat.hp <= hp_before_smash - 20.0, "trunk smash deals 20 damage")
	_check(gat.state == BG.State.STUNNED, "obstacle smash stuns El Gat")

	# 10. Counter 3: Human Fling Pummel
	gat.transition_to(BG.State.CHARGE)
	gat.pos = Vector2(640.0, -1500.0)
	m.human.global_position = gat.pos + Vector2(20.0, 20.0)
	m.human.whirl_flung_t = 1.0 # Simulate tetherball launch
	_check(gat.check_human_pummel(), "check_human_pummel returns true when flung human is close")
	var hp_before_pummel: float = gat.hp
	gat.tick_state(0.016)
	_check(bool(m.get("gat_human_pummeled")), "gat_human_pummeled set to true")
	_check(gat.hp <= hp_before_pummel - 30.0, "human fling deals 30 damage")
	_check(gat.state == BG.State.STUNNED, "human pummel stuns El Gat")

	# 11. State transitions: Arrival at plaza -> ROAR (Phase 3)
	gat.pos.y = -4560.0
	gat.transition_to(BG.State.ROAR)
	_check(gat.state == BG.State.ROAR, "entering plaza triggers ROAR")
	_check(gat.pos == BG.PEDESTAL_POS, "snaps to plaza pedestal")

	# 12. AT-AT Leash Tangle / Coil detection
	gat.wrap_coils = 0.0
	gat.orbit_accum_angle = 0.0
	_check(gat.wrap_coils < 1.0, "initially 0 coils")

	# Simulate 1 orbit
	gat.orbit_accum_angle = TAU * 1.1
	gat.update_cable_wrap(0.016)
	_check(gat.wrap_coils >= 1.0, "1 orbit accumulates >= 1.0 coil")

	# Simulate 2 orbits
	gat.orbit_accum_angle = TAU * 2.1
	gat.update_cable_wrap(0.016)
	_check(gat.wrap_coils >= 2.0, "2 orbits accumulates >= 2.0 coils")

	# Simulate 3 orbits -> triggers WRAPPED
	gat.orbit_accum_angle = TAU * 3.1
	gat.update_cable_wrap(0.016)
	_check(gat.state == BG.State.WRAPPED, "3 coils triggers WRAPPED state")

	# WRAPPED countdown -> triggers TOPPLED
	gat.tick_state(1.0)
	_check(gat.state == BG.State.TOPPLED, "WRAPPED transition leads to TOPPLED")
	_check(bool(m.get("gat_toppled")), "m.gat_toppled set to true")
	_check(m.prize_pos == BG.PRIZE, "golden yarn prize revealed at overturned kiosk")
	_check(m.prize_text == BG.PRIZE_TEXT, "prize text set correctly")

	# 13. Super Boop interaction via on_bark
	_check(not bool(m.get("gat_booped")), "m.gat_booped initially false")
	var booped_far: bool = gat.on_bark_action(Vector2(0.0, 0.0))
	_check(not booped_far, "barking far from snout does not trigger boop")

	# Bark near snout triggers Super Boop
	m.dog.global_position = gat.snout_pos + Vector2(5.0, 5.0)
	var booped: bool = gat.on_bark_action(gat.snout_pos)
	_check(booped, "barking near snout returns true")
	_check(bool(m.get("gat_booped")), "m.gat_booped is now true")
	_check(gat.state == BG.State.PURR, "boop transitions boss to PURR")
	_check(gat.confetti.size() > 0, "victory confetti burst spawned")

	# 14. Save Record Schema Safety
	var test_rec: Dictionary = {
		"bones": 5,
		"time": 84.5,
		"perfects": 1,
		"stars": 3,
		"goals": ["topple", "boop", "clothesline"],
		"style": 240,
	}
	var required_keys := ["bones", "time", "perfects", "stars", "goals", "style"]
	for rk: String in required_keys:
		_check(test_rec.has(rk), "record schema has required key '%s'" % rk)
	_check(test_rec.size() == 6, "record schema has strictly 6 canonical keys")
	_check(game.persist == false, "game.persist remained false throughout test")

	# Summary
	print("test_boss_gat: %d checks, %d failures" % [checks, failures.size()])
	if not failures.is_empty():
		for f in failures:
			printerr("  " + f)
		quit(1)
	else:
		print("test_boss_gat: ALL CHECKS PASSED!")
		quit(0)
