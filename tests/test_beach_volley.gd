extends SceneTree

# Tests for La Platja's beach volleyball live event (systems/volleyball.gd).
# Casual game on the sand court at y = -2000.0 (systems/passeig.gd).
#
# 1. Court geometry and autowalk clearance
# 2. State machine, approach detection and 0.8 s telegraph
# 3. Ball flight, parabolic arc, shadow and ground bounce
# 4. Dog intercept / volley boop in flight and settled
# 5. Human collision hazard and dry promenade dodge save
# 6. Integration with main scene and tutorial isolation

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
	var VolleyballClass: GDScript = load("res://systems/volleyball.gd")
	var LevelBuild: GDScript = load("res://world/level_build.gd")

	# 1. Court geometry and placement
	_check(VolleyballClass.COURT == LevelBuild.BEACH_COURT, "volleyball court matches BEACH_COURT")
	_check(VolleyballClass.PLAYERS.size() == 4, "four players on the court (2 south, 2 north)")
	_check(VolleyballClass.SPIKER_POS.x >= LevelBuild.BEACH_COURT.position.x, "spiker x inside court")
	_check(VolleyballClass.SPIKER_POS.x <= LevelBuild.BEACH_COURT.end.x, "spiker x inside court")
	_check(VolleyballClass.SPIKER_POS.y > LevelBuild.BEACH_COURT.get_center().y, "spiker stands in south court")

	# 2. State machine and 0.8 s warning telegraph
	var vb = VolleyballClass.new()
	_check(vb.state == VolleyballClass.St.WAITING, "starts in WAITING state")
	_check(not vb.triggered, "not triggered at start")
	_check(vb.vel == Vector2.ZERO, "ball stationary at start")

	# Approach from south: dog at y = -1650 (dist ~290 to spiker at -1940)
	var dog_pos := Vector2(290.0, -1650.0)
	var human_pos := Vector2(770.0, -1600.0)
	var facing := Vector2.UP

	var cue_init: Dictionary = vb.tick(0.016, dog_pos, facing, human_pos)
	_check(bool(cue_init["warn"]), "warn cue fires when approaching volleyball court")
	_check(vb.state == VolleyballClass.St.WARN, "enters WARN state")
	_check(vb.triggered, "marked triggered")
	_check(vb.vel == Vector2.ZERO, "ball remains held during warning")

	# Tick 0.5 s into warning: still in WARN
	var cue_mid: Dictionary = vb.tick(0.5, dog_pos, facing, human_pos)
	_check(not bool(cue_mid["warn"]), "warn cue does not re-fire")
	_check(vb.state == VolleyballClass.St.WARN, "still in WARN at 0.5 s")
	_check(vb.vel == Vector2.ZERO, "ball still held at 0.5 s")

	# Tick remaining 0.35 s (total 0.85 s >= 0.8 s): spike occurs
	var cue_spike: Dictionary = vb.tick(0.35, dog_pos, facing, human_pos)
	_check(bool(cue_spike["spike"]), "spike cue fires after 0.8 s warning")
	_check(vb.state == VolleyballClass.St.FLYING, "ball enters FLYING state")
	_check(vb.vel.x > 0.0, "ball flies eastward toward the sand/boardwalk")
	_check(vb.z > 0.0, "ball has height in the air")
	_check(vb.vz > 0.0, "ball vertical velocity is upward")

	# 3. Flight, bounce, and settling physics
	var vb_flight = VolleyballClass.new()
	vb_flight.tick(0.016, dog_pos, facing, human_pos)
	vb_flight.tick(0.85, dog_pos, facing, human_pos) # Trigger spike

	# Simulate flight until bounce
	var bounced := false
	var max_east_x: float = vb_flight.pos.x
	for step in range(120): # up to 2 seconds
		var cue_f: Dictionary = vb_flight.tick(0.016, Vector2(100.0, 0.0), facing, Vector2(770.0, -1500.0))
		max_east_x = maxf(max_east_x, vb_flight.pos.x)
		if bool(cue_f["bounce"]):
			bounced = true
			break

	_check(bounced, "ball bounces on the sand")
	_check(vb_flight.state == VolleyballClass.St.BOUNCING or vb_flight.state == VolleyballClass.St.SETTLED, "enters BOUNCING/SETTLED on ground contact")
	_check(max_east_x < 770.0, "ball flight arc (%.0f) leaves central autowalk line (770) unobstructed" % max_east_x)

	# 4. Dog in-flight interception
	var vb_dog = VolleyballClass.new()
	vb_dog.tick(0.016, dog_pos, facing, human_pos)
	vb_dog.tick(0.85, dog_pos, facing, human_pos) # Spiked

	# Run dog into ball position in flight
	var intercept_pos: Vector2 = vb_dog.pos
	var cue_boop: Dictionary = vb_dog.tick(0.016, intercept_pos, Vector2.RIGHT, human_pos)
	_check(bool(cue_boop["boop"]), "dog intercepts/volleys ball in flight")
	_check(vb_dog.state == VolleyballClass.St.INTERCEPTED, "state enters INTERCEPTED")
	_check(vb_dog.booped, "booped flag is set")

	# 5. Human hazard collision
	var vb_human = VolleyballClass.new()
	vb_human.tick(0.016, dog_pos, facing, human_pos)
	vb_human.tick(0.85, dog_pos, facing, human_pos)

	# Place human right at ball landing location
	var cue_hit: Dictionary = vb_human.tick(0.016, Vector2(0.0, 0.0), facing, vb_human.pos)
	_check(bool(cue_hit["human_hit"]), "human gets hit when walking into volleyball path")
	_check(vb_human.human_hit, "human_hit flag set")

	# 6. Promenade dodge save reward
	var vb_dodge = VolleyballClass.new()
	vb_dodge.tick(0.016, dog_pos, facing, Vector2(770.0, -1950.0))
	vb_dodge.tick(0.85, dog_pos, facing, Vector2(770.0, -1980.0))
	# Human walks along promenade (x = 770) past net to y = -2150
	var cue_dodge: Dictionary = vb_dodge.tick(0.016, dog_pos, facing, Vector2(770.0, -2150.0))
	_check(bool(cue_dodge["dodge"]), "dodge cue fires when human guided safely along promenade")

	# 7. Integration test with main scene
	var game: Node = root.get_node("Game")
	game.level_id = "beach"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.volleyball != null, "main instantiates volleyball on La Platja")

	# Verify game state reaction to volley boop
	var initial_bones: int = m.bones
	m.volleyball.state = VolleyballClass.St.FLYING
	m.volleyball.z = 15.0
	m.volleyball.pos = Vector2(400.0, -2000.0)
	m.dog.global_position = Vector2(400.0, -2000.0)
	m.dog.facing = Vector2.UP
	m.started = true
	m._tick_volleyball(0.016)

	_check(m.bones == initial_bones + 2, "volleyball boop awards +2 bones")

	# Verify tutorial mode does not instantiate volleyball
	var m_tut: Node2D = load("res://main.tscn").instantiate()
	m_tut.tutorial_mode = true
	root.add_child(m_tut)
	if not m_tut.is_node_ready():
		await m_tut.ready
	_check(m_tut.volleyball == null, "tutorial mode does not instantiate volleyball")

	m.queue_free()
	m_tut.queue_free()
	await process_frame
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_beach_volley: OK")
		quit(0)
	else:
		quit(1)
