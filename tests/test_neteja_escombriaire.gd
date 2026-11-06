extends SceneTree

const Escombriaire := preload("res://systems/escombriaire.gd")

# Regression test for La Neteja (neteja, Walk 10) Street Cleaner ("L'Escombriaire") live event.
# Tests 0.8s warning telegraph ("Wet street, mind the broom!"), westward crossing walk across
# the dawn back street at y = -1600.0, yellow rubber duck drop and dog snatch trick,
# distracted human bump hazard, escombriaire boop trick, startle bark trick,
# near-miss dodge save ("neteja dodge! +2"), autowalk safety clearance, and clean reset.

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
	game.level_id = "neteja"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.escombriaire != null, "escombriaire instantiated for neteja walk")
	var e: Escombriaire = m.escombriaire

	# 1. Initial idle state
	_check(e.state == Escombriaire.State.IDLE, "starts in IDLE state")
	_check(not e.triggered, "starts untriggered")
	_check(e.pos == Escombriaire.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1100.0)
	var far_human := Vector2(640.0, -1050.0)
	var out1: Dictionary = e.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when south of trigger line")
	_check(e.state == Escombriaire.State.IDLE, "remains IDLE when south of trigger line")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1320.0)
	var near_human := Vector2(640.0, -1305.0)
	var out2: Dictionary = e.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(e.state == Escombriaire.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(e.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	e.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(e.state == Escombriaire.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(e.pos == Escombriaire.START_POS, "escombriaire remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	e.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(e.state == Escombriaire.State.WALKING, "transitions to WALKING state after 0.8s")
	e.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(e.pos.x < Escombriaire.START_POS.x, "escombriaire begins walking west across street")

	# 6. Walks across street and drops rubber duck
	for step in range(20):
		e.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(e.duck_dropped, "rubber duck dropped as escombriaire crosses center street")
	_check(e.state == Escombriaire.State.WALKING, "still walking across street")

	# 7. Dog snatch trick on dropped rubber duck
	var dog_at_duck := e.duck_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = e.tick(0.02, dog_at_duck, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog snatching rubber duck awards duck snatch trick")
	_check(e.duck_snatched, "duck_snatched flag set")
	var out5b: Dictionary = e.tick(0.02, dog_at_duck, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "duck snatch does not award twice")

	# 8. Bark trick on sweeper
	_check(not e.barked, "barked starts false")
	var bark_dog := e.pos + Vector2(40.0, 0.0)
	var bark_ok := e.on_bark(bark_dog)
	_check(bark_ok, "barking near sweeper triggers bark trick")
	_check(e.barked, "barked flag set")
	_check(e.wobble_t > 0.0, "wobble_t set upon bark")
	_check(not e.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not e.booped, "booped starts false")
	var boop_dog := e.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = e.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping sweeper awards boop trick")
	_check(e.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_e := Escombriaire.new()
	hazard_e.triggered = true
	hazard_e.state = Escombriaire.State.WALKING
	hazard_e.pos = Vector2(640.0, Escombriaire.CROSSING_Y)
	var bump_human := hazard_e.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_e.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_e.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_e := Escombriaire.new()
	dodge_e.triggered = true
	dodge_e.state = Escombriaire.State.WALKING
	dodge_e.pos = Vector2(640.0, Escombriaire.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Escombriaire.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_e.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius
	var near_dodge_human := dodge_e.pos + Vector2(45.0, 0.0)
	var out_threat: Dictionary = dodge_e.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_e.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_e.pos + Vector2(90.0, 0.0)
	var out_dodge: Dictionary = dodge_e.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards neteja dodge save")
	_check(dodge_e.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_e.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_e.state == Escombriaire.State.SETTLED, "settles after crossing street")
	_check(dodge_e.pos == Escombriaire.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_e := Escombriaire.new()
	var auto_human := Vector2(640.0, -1290.0)
	var auto_dog := Vector2(640.0, -1320.0)
	var auto_hit := false
	for frame in range(400):
		auto_human.y -= 125.0 * 0.016
		auto_dog.y -= 125.0 * 0.016
		var out_auto: Dictionary = sim_e.tick(0.016, auto_dog, Vector2.UP * 125.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Escombriaire.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	e.reset()
	_check(e.state == Escombriaire.State.IDLE, "reset restores IDLE state")
	_check(not e.duck_dropped, "reset clears duck_dropped")
	_check(not e.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_neteja_escombriaire: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
