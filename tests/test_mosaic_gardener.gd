extends SceneTree

const Gardener := preload("res://systems/gardener.gd")

# Regression test for Park Güell (El Mosaic, Walk 14) Municipal Gardener live event.
# Tests 0.8s warning telegraph ("Wheelbarrow coming through!"), eastward crossing walk across
# Plaça de la Natura at y = -3200.0, terracotta flower pot drop and dog snatch trick,
# distracted human bump hazard, gardener boop trick, startle bark trick, near-miss
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
	game.level_id = "guell"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.gardener != null, "gardener instantiated for guell walk")
	var g: Gardener = m.gardener

	# 1. Initial idle state
	_check(g.state == Gardener.State.IDLE, "starts in IDLE state")
	_check(not g.triggered, "starts untriggered")
	_check(g.pos == Gardener.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -2700.0)
	var far_human := Vector2(640.0, -2650.0)
	var out1: Dictionary = g.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when south of trigger line")
	_check(g.state == Gardener.State.IDLE, "remains IDLE when south of trigger line")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -2850.0)
	var near_human := Vector2(640.0, -2825.0)
	var out2: Dictionary = g.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(g.state == Gardener.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(g.timer < 0.1, "timer initialized at 0.0s")

	# 4. Remains in TELEGRAPH during warning window
	g.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(g.state == Gardener.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(g.pos == Gardener.START_POS, "gardener remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	g.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(g.state == Gardener.State.WALKING, "transitions to WALKING state after 0.8s")
	g.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(g.pos.x > Gardener.START_POS.x, "gardener begins walking east across terrace")

	# 6. Trundles across terrace and drops a geranium flower pot
	for step in range(35):
		g.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(g.pot_dropped, "flower pot dropped as wheelbarrow crosses center terrace")
	# Gardener walks further ahead so dog can interact with pot and gardener separately
	for step in range(12):
		g.tick(0.05, near_dog, Vector2.ZERO, near_human)

	# 7. Dog snatch trick on dropped geranium pot
	var dog_at_pot := g.pot_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = g.tick(0.02, dog_at_pot, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog snatching geranium pot awards geranium snatch trick")
	_check(g.pot_snatched, "pot_snatched flag set")
	var out5b: Dictionary = g.tick(0.02, dog_at_pot, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "geranium snatch does not award twice")

	# 8. Bark trick on walking gardener
	_check(not g.barked, "barked starts false")
	var bark_dog := g.pos + Vector2(40.0, 0.0)
	var bark_ok := g.on_bark(bark_dog)
	_check(bark_ok, "barking near gardener triggers bark trick")
	_check(g.barked, "barked flag set")
	_check(g.wobble_t > 0.0, "wobble_t set upon bark")
	_check(not g.on_bark(bark_dog), "bark trick does not trigger twice")

	# 9. Direct boop trick
	_check(not g.booped, "booped starts false")
	var boop_dog := g.pos + Vector2(10.0, 0.0)
	var out_boop: Dictionary = g.tick(0.016, boop_dog, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping gardener awards boop trick")
	_check(g.booped, "booped flag set")

	# 10. Distracted human collision triggers bump hazard
	var hazard_g := Gardener.new()
	hazard_g.triggered = true
	hazard_g.state = Gardener.State.WALKING
	hazard_g.pos = Vector2(640.0, Gardener.CROSSING_Y)
	var bump_human := hazard_g.pos + Vector2(15.0, 0.0)
	var out_hit: Dictionary = hazard_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, bump_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_g.human_hit, "human_hit flag set")

	# 11. Near-miss dodge: stepping close and clearing without getting hit
	var dodge_g := Gardener.new()
	dodge_g.triggered = true
	dodge_g.state = Gardener.State.WALKING
	dodge_g.pos = Vector2(600.0, Gardener.CROSSING_Y)
	# Standing far away is not a save
	var far_line := Vector2(640.0, Gardener.CROSSING_Y - 120.0)
	var out_far: Dictionary = dodge_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, far_line)
	_check(not bool(out_far["dodge"]), "ordinary line clear of threat is not a save")
	# Moving inside threat radius (close <= 70.0)
	var near_dodge_human := dodge_g.pos + Vector2(50.0, 0.0)
	var out_threat: Dictionary = dodge_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, near_dodge_human)
	_check(not bool(out_threat["dodge"]), "inside threat is not yet a save")
	_check(dodge_g.threatened, "threatened flag armed")
	# Moving clear safely
	var clear_human := dodge_g.pos + Vector2(100.0, 0.0)
	var out_dodge: Dictionary = dodge_g.tick(0.016, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(bool(out_dodge["dodge"]), "clearing threat safely awards mosaic dodge save")
	_check(dodge_g.dodged, "dodged flag set")

	# 12. Runs to END_POS and settles
	for i in range(120):
		dodge_g.tick(0.05, Vector2.ZERO, Vector2.ZERO, clear_human)
	_check(dodge_g.state == Gardener.State.SETTLED, "settles after crossing terrace")
	_check(dodge_g.pos == Gardener.END_POS, "positioned at END_POS when settled")

	# 13. Autowalk safety: autowalk pair clears crossing safely
	var sim_g := Gardener.new()
	var auto_human := Vector2(640.0, -2810.0)
	var auto_dog := Vector2(640.0, -2840.0)
	var auto_hit := false
	for frame in range(350):
		auto_human.y -= 125.0 * 0.016
		auto_dog.y -= 125.0 * 0.016
		var out_auto: Dictionary = sim_g.tick(0.016, auto_dog, Vector2.UP * 125.0, auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
		if auto_human.y < Gardener.CROSSING_Y - 50.0:
			break
	_check(not auto_hit, "autowalk completes crossing safely without bump")

	# 14. Reset cleans up
	g.reset()
	_check(g.state == Gardener.State.IDLE, "reset restores IDLE state")
	_check(not g.pot_dropped, "reset clears pot_dropped")
	_check(not g.dodged, "reset clears dodged")

	m.queue_free()
	await process_frame
	print("test_mosaic_gardener: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
