extends SceneTree

const Scooter := preload("res://systems/scooter.gd")

# Regression test for El Gòtic (oldtown, Walk 7) Vintage Vespa Courier live event.
# Tests 0.8s warning telegraph ("Scooter coming through!"), eastward crossing drive across
# the narrow alleyway at y = -1720.0, airmail letter drop and dog snatch trick,
# distracted human bump hazard, scooter boop trick, brake screech bark trick,
# near-miss dodge save, autowalk safety, and clean reset.

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
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "oldtown"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.scooter != null, "scooter instantiated for oldtown walk")
	var s: Scooter = m.scooter

	# 1. Initial idle state
	_check(s.state == Scooter.State.IDLE, "starts in IDLE state")
	_check(not s.triggered, "starts untriggered")
	_check(s.pos == Scooter.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1200.0)
	var far_human := Vector2(640.0, -1150.0)
	var out1: Dictionary = s.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when south of trigger line")
	_check(s.state == Scooter.State.IDLE, "remains IDLE when south of trigger line")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1420.0)
	var near_human := Vector2(640.0, -1405.0)
	var out2: Dictionary = s.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(s.state == Scooter.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(s.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	s.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(s.state == Scooter.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(s.pos == Scooter.START_POS, "scooter remains at start during telegraph")

	# 5. Warning completes -> transitions to DRIVING
	s.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(s.state == Scooter.State.DRIVING, "transitions to DRIVING state after 0.8s")
	s.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(s.pos.x > Scooter.START_POS.x, "scooter begins driving east across alley")

	# 6. Drives across alley and drops an airmail letter
	for step in range(25):
		s.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(s.letter_dropped, "letter dropped as scooter crosses center alley")
	# Scooter drives further ahead so dog can interact with letter and scooter separately
	for step in range(5):
		s.tick(0.05, near_dog, Vector2.ZERO, near_human)

	# 7. Dog snatch trick on dropped airmail letter
	var dog_at_letter := s.letter_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = s.tick(0.02, dog_at_letter, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog snatching letter awards letter snatch trick")
	_check(s.letter_snatched, "letter_snatched flag set")
	var out5b: Dictionary = s.tick(0.02, dog_at_letter, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "letter snatch does not award twice")

	# 8. Bark trick on moving scooter
	_check(not s.barked, "barked starts false")
	var bark_dog := s.pos + Vector2(40.0, 0.0)
	var bark_ok := s.on_bark(bark_dog)
	_check(bark_ok, "barking near scooter triggers bark trick")
	_check(s.barked, "barked flag set")
	_check(s.wobble_t > 0.0, "wobble_t set upon bark")
	_check(not s.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not s.booped, "booped starts false")
	var boop_dog := s.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = s.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping scooter awards boop trick")
	_check(s.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_s := Scooter.new()
	hazard_s.triggered = true
	hazard_s.state = Scooter.State.DRIVING
	hazard_s.pos = Vector2(640.0, Scooter.CROSSING_Y)
	var bump_human := hazard_s.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_s.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_s.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_s := Scooter.new()
	dodge_s.triggered = true
	dodge_s.state = Scooter.State.DRIVING
	dodge_s.pos = Vector2(640.0, Scooter.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Scooter.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_s.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius (close <= 64.0)
	var near_dodge_human := dodge_s.pos + Vector2(45.0, 0.0)
	var out_threat: Dictionary = dodge_s.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_s.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_s.pos + Vector2(90.0, 0.0)
	var out_dodge: Dictionary = dodge_s.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards gotic dodge save")
	_check(dodge_s.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_s.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_s.state == Scooter.State.SETTLED, "settles after crossing alley")
	_check(dodge_s.pos == Scooter.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_s := Scooter.new()
	var auto_human := Vector2(680.0, -1390.0)
	var auto_dog := Vector2(680.0, -1420.0)
	var auto_hit := false
	for frame in range(350):
		auto_human.y -= 125.0 * 0.016
		auto_dog.y -= 125.0 * 0.016
		var out_auto: Dictionary = sim_s.tick(0.016, auto_dog, Vector2.UP * 125.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Scooter.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	s.reset()
	_check(s.state == Scooter.State.IDLE, "reset restores IDLE state")
	_check(not s.letter_dropped, "reset clears letter_dropped")
	_check(not s.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_gotic_scooter: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
