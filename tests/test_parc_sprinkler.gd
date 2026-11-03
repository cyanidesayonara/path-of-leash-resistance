extends SceneTree

# Tests for El Parc's rotary lawn sprinkler live event (systems/sprinkler.gd).
# Verifies 0.8 s warning telegraph, rotation bounds, dog splash interaction,
# human phone hazard, dodge save reward, autowalk safety clearance, and level integration.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var SprinklerClass: GDScript = load("res://systems/sprinkler.gd")
	_check(SprinklerClass != null, "Sprinkler class loads")

	# 1. Constants and geometry
	var hp: Vector2 = SprinklerClass.HEAD_POS
	_check(hp == Vector2(390.0, -980.0), "head pos is on west lawn verge")
	_check(SprinklerClass.SPRAY_RADIUS == 160.0, "spray radius is 160 px")
	_check(SprinklerClass.WARN_S == 0.8, "telegraph is exactly 0.8 s")

	# Autowalk clearance: corridor center is 640.0, max eastward reach is 390 + 160 = 550.0
	var max_reach_x: float = hp.x + SprinklerClass.SPRAY_RADIUS
	_check(max_reach_x < 640.0, "spray max eastward reach (%.0f) leaves autowalk line (640) dry" % max_reach_x)

	# 2. State machine and 0.8 s telegraph
	var sp = SprinklerClass.new()
	_check(sp.state == SprinklerClass.St.IDLE, "starts in IDLE")
	_check(not sp.active, "not spraying in IDLE")

	# Approach from south: dog at y = -650 (dist ~335 to -980)
	var dog_pos := Vector2(430.0, -650.0)
	var human_pos := Vector2(430.0, -600.0)
	var cue: Dictionary = sp.tick(0.016, dog_pos, human_pos)
	_check(bool(cue["warn"]), "warn cue fires when approaching sprinkler")
	_check(sp.state == SprinklerClass.St.WARN, "enters WARN state")
	_check(not sp.active, "spray is not active during 0.8 s warning telegraph")

	# Tick 0.5 s into warning: still in WARN
	var cue_mid: Dictionary = sp.tick(0.5, dog_pos, human_pos)
	_check(not bool(cue_mid["warn"]), "warn cue does not re-fire")
	_check(sp.state == SprinklerClass.St.WARN, "still in WARN at 0.5 s")
	_check(not sp.active, "spray still not active at 0.5 s")

	# Tick remaining 0.35 s: warning ends at 0.8 s, enters SPRAYING
	sp.tick(0.35, dog_pos, human_pos)
	_check(sp.state == SprinklerClass.St.SPRAYING, "enters SPRAYING after 0.8 s warning")
	_check(sp.active, "spray is now active")

	# 3. Spray rotation bounds
	_check(sp.angle >= SprinklerClass.SWEEP_MIN - 0.01, "angle >= SWEEP_MIN")
	_check(sp.angle <= SprinklerClass.SWEEP_MAX + 0.01, "angle <= SWEEP_MAX")

	# 4. Dog splash interaction
	# Put dog right in the spray jet
	var jet_dir := Vector2.from_angle(sp.angle)
	var dog_in_spray: Vector2 = hp + jet_dir * 80.0
	var cue_splash: Dictionary = sp.tick(0.016, dog_in_spray, Vector2(640.0, -800.0))
	_check(bool(cue_splash["dog_splash"]), "dog gets splashed when in the water jet")
	_check(sp.dog_cooldown > 0.0, "dog splash cooldown is set")

	# Cooldown prevents repeated splash in next frame
	var cue_splash_cd: Dictionary = sp.tick(0.016, dog_in_spray, Vector2(640.0, -800.0))
	_check(not bool(cue_splash_cd["dog_splash"]), "dog splash respects cooldown")

	# 5. Human soaked hazard
	var human_in_spray: Vector2 = hp + jet_dir * 100.0
	var cue_soaked: Dictionary = sp.tick(0.016, Vector2(640.0, -800.0), human_in_spray)
	_check(bool(cue_soaked["human_soaked"]), "human gets soaked when walking into water jet")
	_check(sp.human_soaked, "human_soaked flag is true")

	# 6. Dodge / save reward on dry side
	var sp_dodge = SprinklerClass.new()
	sp_dodge.tick(0.016, Vector2(430.0, -650.0), Vector2(580.0, -850.0))
	sp_dodge.tick(0.85, Vector2(430.0, -650.0), Vector2(580.0, -950.0))
	# Human walks past at x = 580 (dry side) to y = -1150
	var cue_dodge: Dictionary = sp_dodge.tick(0.016, Vector2(580.0, -1180.0), Vector2(580.0, -1150.0))
	_check(bool(cue_dodge["dodge"]), "dodge cue fires when human guided safely along dry side")

	# 7. Integration test with main scene
	var game: Node = root.get_node("Game")
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.sprinkler != null, "main instantiates sprinkler on El Parc")

	# Verify drink progress and splash reward in game
	var initial_bones: int = m.bones
	var initial_drunk: float = m.drunk_amount
	m.sprinkler.state = SprinklerClass.St.SPRAYING
	m.sprinkler.active = true
	m.sprinkler.dog_cooldown = 0.0
	m.dog.global_position = hp + Vector2.from_angle(m.sprinkler.angle) * 70.0
	m.started = true
	m._tick_sprinkler(0.016)

	_check(m.bones == initial_bones + 2, "dog splash awards +2 bones in game")
	_check(m.drunk_amount > initial_drunk, "dog splash advances drink progress in game")

	# Verify tutorial mode does not instantiate sprinkler
	var m_tut: Node2D = load("res://main.tscn").instantiate()
	m_tut.tutorial_mode = true
	root.add_child(m_tut)
	if not m_tut.is_node_ready():
		await m_tut.ready
	_check(m_tut.sprinkler == null, "tutorial mode does not instantiate sprinkler")

	m.queue_free()
	m_tut.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_parc_sprinkler: OK")
		quit(0)
	else:
		quit(1)
