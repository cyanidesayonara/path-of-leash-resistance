extends SceneTree

const Castanyera := preload("res://systems/castanyera.gd")

# Regression test for La Castanyada hurrying castanyera live event (Walk 12).
# Tests the 0.8s warning telegraph ("Castanyes calentes!"), eastbound crossing walk
# across the festive street, dropped roasted chestnut paperina snatch trick,
# distracted human bump hazard, dog boop trick, castanyera bark trick, near-miss
# dodge save, autowalk safety, and clean reset.

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
	game.level_id = "spook"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.castanyera != null, "castanyera instantiated for spook walk")
	var c: Castanyera = m.castanyera

	# 1. Initial idle state
	_check(c.state == Castanyera.State.IDLE, "starts in IDLE state")
	_check(not c.triggered, "starts untriggered")
	_check(c.pos == Castanyera.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1400.0)
	var far_human := Vector2(640.0, -1350.0)
	var out1: Dictionary = c.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(c.state == Castanyera.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1500.0)
	var near_human := Vector2(640.0, -1470.0)
	var out2: Dictionary = c.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(c.state == Castanyera.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(c.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	c.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(c.state == Castanyera.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(c.pos == Castanyera.START_POS, "castanyera remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	c.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(c.state == Castanyera.State.WALKING, "transitions to WALKING state after 0.8s")
	c.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(c.pos.x > Castanyera.START_POS.x, "castanyera begins walking east across street")

	# 6. Castanyera walks across street and drops paper cone of hot chestnuts
	for step in range(35):
		c.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(c.paperina_dropped, "paperina dropped as castanyera crosses center street")

	# 7. Dog snatch trick on dropped paperina
	var dog_at_paperina := c.paperina_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = c.tick(0.02, dog_at_paperina, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog pouncing onto paperina earns chestnut snatch trick")
	_check(c.paperina_snatched, "paperina_snatched flag set")
	var out5b: Dictionary = c.tick(0.02, dog_at_paperina, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "chestnut snatch does not award twice")

	# 8. Bark trick on walking castanyera
	_check(not c.barked, "barked starts false")
	var bark_dog := c.pos + Vector2(40.0, 0.0)
	var bark_ok := c.on_bark(bark_dog)
	_check(bark_ok, "barking near castanyera triggers bark trick")
	_check(c.barked, "barked flag set")
	_check(not c.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not c.booped, "booped starts false")
	var boop_dog := c.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = c.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping castanyera apron awards boop trick")
	_check(c.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_c := Castanyera.new()
	hazard_c.triggered = true
	hazard_c.state = Castanyera.State.WALKING
	hazard_c.pos = Vector2(640.0, Castanyera.CROSSING_Y)
	var bump_human := hazard_c.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_c.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_c.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_c := Castanyera.new()
	dodge_c.triggered = true
	dodge_c.state = Castanyera.State.WALKING
	dodge_c.pos = Vector2(600.0, Castanyera.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Castanyera.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_c.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius (close <= 64.0)
	var near_dodge_human := dodge_c.pos + Vector2(50.0, 0.0)
	var out_threat: Dictionary = dodge_c.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_c.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_c.pos + Vector2(100.0, 0.0)
	var out_dodge: Dictionary = dodge_c.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards chestnut dodge save")
	_check(dodge_c.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_c.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_c.state == Castanyera.State.SETTLED, "settles after crossing street")
	_check(dodge_c.pos == Castanyera.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_c := Castanyera.new()
	var auto_human := Vector2(640.0, -1450.0)
	var auto_dog := Vector2(640.0, -1480.0)
	var auto_hit := false
	for frame in range(350):
		auto_human.y -= 115.0 * 0.016
		auto_dog.y -= 115.0 * 0.016
		var out_auto: Dictionary = sim_c.tick(0.016, auto_dog, Vector2.UP * 115.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Castanyera.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	c.reset()
	_check(c.state == Castanyera.State.IDLE, "reset restores IDLE state")
	_check(not c.paperina_dropped, "reset clears paperina_dropped")
	_check(not c.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_castanyada_live_event: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
