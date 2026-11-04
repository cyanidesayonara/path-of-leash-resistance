extends SceneTree

const Ornitoleg := preload("res://systems/ornitoleg.gd")

# Regression test for El Besòs (besos, Walk 15) Birdwatcher ("L'Ornitòleg") live event.
# Tests 0.8s warning telegraph ("Mireu, un bernat pescaire!"), westward crossing walk across
# the riverside promenade at y = -2680.0, field binoculars drop and dog snatch trick,
# distracted human bump hazard, ornitòleg boop trick, startle bark trick,
# near-miss dodge save ("besòs dodge! +2"), autowalk safety clearance, and clean reset.

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
	game.level_id = "besos"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.ornitoleg != null, "ornitoleg instantiated for besos walk")
	var o: Ornitoleg = m.ornitoleg

	# 1. Initial idle state
	_check(o.state == Ornitoleg.State.IDLE, "starts in IDLE state")
	_check(not o.triggered, "starts untriggered")
	_check(o.pos == Ornitoleg.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(400.0, -2100.0)
	var far_human := Vector2(400.0, -2050.0)
	var out1: Dictionary = o.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when south of trigger line")
	_check(o.state == Ornitoleg.State.IDLE, "remains IDLE when south of trigger line")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(400.0, -2360.0)
	var near_human := Vector2(400.0, -2345.0)
	var out2: Dictionary = o.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(o.state == Ornitoleg.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(o.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	o.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(o.state == Ornitoleg.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(o.pos == Ornitoleg.START_POS, "ornitoleg remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	o.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(o.state == Ornitoleg.State.WALKING, "transitions to WALKING state after 0.8s")
	o.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(o.pos.x < Ornitoleg.START_POS.x, "ornitoleg begins walking west across riverbank")

	# 6. Walks across promenade and drops binoculars
	for step in range(35):
		o.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(o.binoc_dropped, "binoculars dropped as ornitoleg crosses center path")
	# Ornithologist walks further ahead so dog can interact with binoculars and ornithologist separately
	for step in range(5):
		o.tick(0.05, near_dog, Vector2.ZERO, near_human)

	# 7. Dog snatch trick on dropped binoculars
	var dog_at_binoc := o.binoc_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = o.tick(0.02, dog_at_binoc, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog snatching binoculars awards prismàtics snatch trick")
	_check(o.binoc_snatched, "binoc_snatched flag set")
	var out5b: Dictionary = o.tick(0.02, dog_at_binoc, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "binoculars snatch does not award twice")

	# 8. Bark trick on ornithologist
	_check(not o.barked, "barked starts false")
	var bark_dog := o.pos + Vector2(40.0, 0.0)
	var bark_ok := o.on_bark(bark_dog)
	_check(bark_ok, "barking near ornithologist triggers bark trick")
	_check(o.barked, "barked flag set")
	_check(o.wobble_t > 0.0, "wobble_t set upon bark")
	_check(not o.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not o.booped, "booped starts false")
	var boop_dog := o.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = o.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping ornithologist awards boop trick")
	_check(o.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_o := Ornitoleg.new()
	hazard_o.triggered = true
	hazard_o.state = Ornitoleg.State.WALKING
	hazard_o.pos = Vector2(400.0, Ornitoleg.CROSSING_Y)
	var bump_human := hazard_o.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_o.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_o.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_o := Ornitoleg.new()
	dodge_o.triggered = true
	dodge_o.state = Ornitoleg.State.WALKING
	dodge_o.pos = Vector2(400.0, Ornitoleg.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(400.0, Ornitoleg.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_o.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius
	var near_dodge_human := dodge_o.pos + Vector2(45.0, 0.0)
	var out_threat: Dictionary = dodge_o.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_o.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_o.pos + Vector2(90.0, 0.0)
	var out_dodge: Dictionary = dodge_o.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards besòs dodge save")
	_check(dodge_o.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_o.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_o.state == Ornitoleg.State.SETTLED, "settles after crossing promenade")
	_check(dodge_o.pos == Ornitoleg.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_o := Ornitoleg.new()
	var auto_human := Vector2(400.0, -2330.0)
	var auto_dog := Vector2(400.0, -2360.0)
	var auto_hit := false
	for frame in range(400):
		auto_human.y -= 125.0 * 0.016
		auto_dog.y -= 125.0 * 0.016
		var out_auto: Dictionary = sim_o.tick(0.016, auto_dog, Vector2.UP * 125.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Ornitoleg.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	o.reset()
	_check(o.state == Ornitoleg.State.IDLE, "reset restores IDLE state")
	_check(not o.binoc_dropped, "reset clears binoc_dropped")
	_check(not o.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_besos_ornitoleg: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
