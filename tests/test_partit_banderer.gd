extends SceneTree

const Banderer := preload("res://systems/banderer.gd")

# Regression test for Dia de Partit (partit, Walk 17) Match-day Flag Bearer ("El Banderer") live event.
# Tests 0.8s warning telegraph ("Força Barça, que comença el partit!"), westward crossing walk across
# the stadium avenue at y = -1380.0, match scarf drop and dog snatch trick,
# distracted human bump hazard, banderer boop trick, startle bark trick,
# near-miss dodge save ("partit dodge! +2"), autowalk safety clearance, and clean reset.

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
	game.level_id = "partit"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.banderer != null, "banderer instantiated for partit walk")
	var b: Banderer = m.banderer

	# 1. Initial idle state
	_check(b.state == Banderer.State.IDLE, "starts in IDLE state")
	_check(not b.triggered, "starts untriggered")
	_check(b.pos == Banderer.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -920.0)
	var far_human := Vector2(640.0, -880.0)
	var out1: Dictionary = b.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when south of trigger line")
	_check(b.state == Banderer.State.IDLE, "remains IDLE when south of trigger line")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1040.0)
	var near_human := Vector2(640.0, -1025.0)
	var out2: Dictionary = b.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(b.state == Banderer.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(b.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	b.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(b.state == Banderer.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(b.pos == Banderer.START_POS, "banderer remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	b.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(b.state == Banderer.State.WALKING, "transitions to WALKING state after 0.8s")
	b.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(b.pos.x < Banderer.START_POS.x, "banderer begins walking west across avenue")

	# 6. Walks across avenue and drops match scarf
	for step in range(35):
		b.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(b.scarf_dropped, "match scarf dropped as banderer crosses center avenue")
	_check(b.state == Banderer.State.WALKING, "still walking across avenue")

	# 7. Dog snatch trick on dropped match scarf
	var dog_at_scarf := b.scarf_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = b.tick(0.02, dog_at_scarf, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog snatching match scarf awards scarf snatch trick")
	_check(b.scarf_snatched, "scarf_snatched flag set")
	var out5b: Dictionary = b.tick(0.02, dog_at_scarf, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "scarf snatch does not award twice")

	# 8. Bark trick on flag bearer
	_check(not b.barked, "barked starts false")
	var bark_dog := b.pos + Vector2(40.0, 0.0)
	var bark_ok := b.on_bark(bark_dog)
	_check(bark_ok, "barking near flag bearer triggers bark trick")
	_check(b.barked, "barked flag set")
	_check(b.wobble_t > 0.0, "wobble_t set upon bark")
	_check(not b.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not b.booped, "booped starts false")
	var boop_dog := b.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = b.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping flag bearer awards boop trick")
	_check(b.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_b := Banderer.new()
	hazard_b.triggered = true
	hazard_b.state = Banderer.State.WALKING
	hazard_b.pos = Vector2(640.0, Banderer.CROSSING_Y)
	var bump_human := hazard_b.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_b.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_b.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_b := Banderer.new()
	dodge_b.triggered = true
	dodge_b.state = Banderer.State.WALKING
	dodge_b.pos = Vector2(640.0, Banderer.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Banderer.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_b.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius
	var near_dodge_human := dodge_b.pos + Vector2(45.0, 0.0)
	var out_threat: Dictionary = dodge_b.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_b.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_b.pos + Vector2(90.0, 0.0)
	var out_dodge: Dictionary = dodge_b.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards partit dodge save")
	_check(dodge_b.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_b.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_b.state == Banderer.State.SETTLED, "settles after crossing avenue")
	_check(dodge_b.pos == Banderer.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_b := Banderer.new()
	var auto_human := Vector2(640.0, -1010.0)
	var auto_dog := Vector2(640.0, -1040.0)
	var auto_hit := false
	for frame in range(400):
		auto_human.y -= 125.0 * 0.016
		auto_dog.y -= 125.0 * 0.016
		var out_auto: Dictionary = sim_b.tick(0.016, auto_dog, Vector2.UP * 125.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Banderer.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	b.reset()
	_check(b.state == Banderer.State.IDLE, "reset restores IDLE state")
	_check(not b.scarf_dropped, "reset clears scarf_dropped")
	_check(not b.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_partit_banderer: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
