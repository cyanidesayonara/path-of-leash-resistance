extends SceneTree

const Gegant := preload("res://systems/gegant.gd")

# Regression test for Festa de Gràcia Gegant rehearsal twirl live event (Walk 26).
# Tests the 0.8s warning telegraph ("Giant coming through! Visca!"), eastbound crossing twirl
# across the decorated narrow street, dropped festival ribbon rosette snatch trick,
# distracted human bump hazard, dog boop trick, gegant bark dance trick, near-miss
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
	game.level_id = "gracia"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.gegant != null, "gegant instantiated for gracia walk")
	var g: Gegant = m.gegant

	# 1. Initial idle state
	_check(g.state == Gegant.State.IDLE, "starts in IDLE state")
	_check(not g.triggered, "starts untriggered")
	_check(g.pos == Gegant.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1600.0)
	var far_human := Vector2(640.0, -1560.0)
	var out1: Dictionary = g.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(g.state == Gegant.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1750.0)
	var near_human := Vector2(640.0, -1725.0)
	var out2: Dictionary = g.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(g.state == Gegant.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(g.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	g.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(g.state == Gegant.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(g.pos == Gegant.START_POS, "giant remains at start during telegraph")

	# 5. Warning completes -> transitions to TWIRLING
	g.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(g.state == Gegant.State.TWIRLING, "transitions to TWIRLING state after 0.8s")
	g.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(g.pos.x > Gegant.START_POS.x, "giant begins twirling east across street")

	# 6. Giant twirls across street and drops festival rosette
	for step in range(35):
		g.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(g.rosette_dropped, "rosette dropped as giant crosses center street")

	# 7. Dog snatch trick on dropped rosette
	var dog_at_rosette := g.rosette_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = g.tick(0.02, dog_at_rosette, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog pouncing onto rosette earns rosette snatch trick")
	_check(g.rosette_snatched, "rosette_snatched flag set")
	var out5b: Dictionary = g.tick(0.02, dog_at_rosette, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "rosette snatch does not award twice")

	# 8. Bark trick on twirling giant
	_check(not g.barked, "barked starts false")
	var bark_dog := g.pos + Vector2(50.0, 0.0)
	var bark_ok := g.on_bark(bark_dog)
	_check(bark_ok, "barking near giant triggers dance trick")
	_check(g.barked, "barked flag set")
	_check(not g.on_bark(bark_dog), "dance trick does not trigger twice")

	# 9. Direct boop trick
	_check(not g.booped, "booped starts false")
	var boop_dog := g.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = g.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping giant hem awards boop trick")
	_check(g.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_g := Gegant.new()
	hazard_g.triggered = true
	hazard_g.state = Gegant.State.TWIRLING
	hazard_g.pos = Vector2(640.0, Gegant.CROSSING_Y)
	var bump_human := hazard_g.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_g.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_g := Gegant.new()
	dodge_g.triggered = true
	dodge_g.state = Gegant.State.TWIRLING
	dodge_g.pos = Vector2(600.0, Gegant.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Gegant.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius (close <= 68.0)
	var near_dodge_human := dodge_g.pos + Vector2(52.0, 0.0)
	var out_threat: Dictionary = dodge_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_g.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_g.pos + Vector2(100.0, 0.0)
	var out_dodge: Dictionary = dodge_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards giant dodge save")
	_check(dodge_g.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_g.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_g.state == Gegant.State.SETTLED, "settles after crossing street")
	_check(dodge_g.pos == Gegant.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_g := Gegant.new()
	var auto_human := Vector2(640.0, -1800.0)
	var auto_dog := Vector2(640.0, -1830.0)
	var auto_hit := false
	for frame in range(300):
		auto_human.y -= 115.0 * 0.016
		auto_dog.y -= 115.0 * 0.016
		var out_auto: Dictionary = sim_g.tick(0.016, auto_dog, Vector2.UP * 115.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Gegant.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	g.reset()
	_check(g.state == Gegant.State.IDLE, "reset restores IDLE state")
	_check(not g.rosette_dropped, "reset clears rosette_dropped")
	_check(not g.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_gracia_gegant: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
