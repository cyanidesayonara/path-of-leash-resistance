extends SceneTree

const TrailRunner := preload("res://systems/trail_runner.gd")

# Regression test for La Carretera de les Aigües trail runner live event (Walk 22).
# Tests the 0.8s warning telegraph ("Pista, pista!"), westbound run across the
# sauló track, dropped electrolyte gel snatch trick, distracted human bump hazard,
# dog boop trick, runner bark trick, trail dodge save, autowalk safety, and
# leak-free cleanup.

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
	game.level_id = "aigues"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.trail_runner != null, "trail_runner instantiated for aigues walk")
	var tr: TrailRunner = m.trail_runner

	# 1. Initial idle state
	_check(tr.state == TrailRunner.State.IDLE, "starts in IDLE state")
	_check(not tr.triggered, "starts untriggered")
	_check(tr.pos == TrailRunner.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(585.0, -1350.0)
	var far_human := Vector2(585.0, -1310.0)
	var out1: Dictionary = tr.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(tr.state == TrailRunner.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(585.0, -1540.0)
	var near_human := Vector2(585.0, -1500.0)
	var out2: Dictionary = tr.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(tr.state == TrailRunner.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(tr.timer <= TrailRunner.WARN_DURATION and tr.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % tr.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = tr.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(tr.state == TrailRunner.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["clack"]), "clack has not fired yet during warning")
	_check(tr.pos == TrailRunner.START_POS, "runner remains at start during telegraph")

	# 5. Warning completes -> transitions to RUNNING
	var out4: Dictionary = tr.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["clack"]), "clack fires after 0.8s warning expires")
	_check(tr.state == TrailRunner.State.RUNNING, "transitions to RUNNING state")
	tr.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(tr.pos.x < TrailRunner.START_POS.x, "runner begins running west")

	# 6. Runner sprints across track and drops energy gel
	var had_drop := false
	for step in range(35):
		var step_out: Dictionary = tr.tick(0.05, near_dog, Vector2.ZERO, near_human)
		if bool(step_out["drop_gel"]):
			had_drop = true
	_check(had_drop, "energy gel drops as runner crosses middle track")
	_check(tr.gel_dropped, "gel_dropped flag set")

	# 7. Dog snatch trick on dropped energy gel
	var dog_at_gel := tr.gel_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = tr.tick(0.02, dog_at_gel, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog pouncing onto gel earns gel snatch trick")
	_check(tr.gel_snatched, "gel_snatched flag set")
	var out5b: Dictionary = tr.tick(0.02, dog_at_gel, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "gel snatch does not award twice")

	# 8. Distracted human in runner path gets bumped
	var human_in_path := Vector2(tr.pos.x, TrailRunner.CROSSING_Y)
	var out6: Dictionary = tr.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(bool(out6["bump"]), "human in runner path gets bumped")
	_check(tr.human_hit, "human_hit flag set")
	var out6b: Dictionary = tr.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(not bool(out6b["bump"]), "human does not get bumped twice in single run")

	# 9. Dog boop trick on trail runner directly
	var test_tr := TrailRunner.new()
	test_tr.reset()
	test_tr.tick(0.016, near_dog, Vector2.ZERO, near_human)  # Trigger
	test_tr.tick(0.85, near_dog, Vector2.ZERO, near_human)   # Start running
	var dog_boop_pos := test_tr.pos + Vector2(4.0, 2.0)
	var out_boop: Dictionary = test_tr.tick(0.02, dog_boop_pos, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping runner directly awards boop trick")
	_check(test_tr.booped, "booped flag set")
	var out_boop2: Dictionary = test_tr.tick(0.02, dog_boop_pos, Vector2.ZERO, far_human)
	_check(not bool(out_boop2["boop"]), "boop trick does not fire twice")

	# 10. Barking near trail runner alerts them and awards bark trick
	var bark_far := Vector2(200.0, -500.0)
	_check(not test_tr.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := test_tr.pos + Vector2(20.0, 10.0)
	_check(test_tr.on_bark(bark_near), "bark near runner triggers runner bark trick")
	_check(test_tr.barked, "barked flag set")
	_check(not test_tr.on_bark(bark_near), "bark trick does not award twice")

	# 11. Full run to west end triggers trail dodge save if human avoided bump
	var test_dodge := TrailRunner.new()
	test_dodge.reset()
	test_dodge.tick(0.016, near_dog, Vector2.ZERO, near_human)  # Trigger
	test_dodge.tick(0.85, near_dog, Vector2.ZERO, near_human)   # Running
	var dodge_human := Vector2(585.0, -1640.0)  # Close to crossing (60px away), safely clear of 30px bump radius
	var dodged_event := false
	for step in range(65):
		var step_out: Dictionary = test_dodge.tick(0.05, far_dog, Vector2.ZERO, dodge_human)
		if bool(step_out["dodge"]):
			dodged_event = true
	_check(dodged_event, "safely navigating crossing awards trail dodge save")
	_check(test_dodge.dodged, "dodged flag set")
	_check(test_dodge.state == TrailRunner.State.SETTLED, "trail runner settles at west verge")

	# 12. Autowalk path safety: at x = 585.0, crossing clears center before human arrival
	var sim_tr := TrailRunner.new()
	sim_tr.reset()
	var auto_dog := Vector2(585.0, -1525.0)
	var auto_human := Vector2(585.0, -1480.0)
	sim_tr.tick(0.016, auto_dog, Vector2.ZERO, auto_human)
	_check(sim_tr.state == TrailRunner.State.TELEGRAPH, "autowalk triggers telegraph at y=-1525")

	var human_y := auto_human.y
	var human_speed := 65.0  # standard autopilot walk pace
	var t := 0.0
	var dt := 0.05
	var tr_x_at_crossing_y := 0.0

	while human_y > TrailRunner.CROSSING_Y - 20.0:
		t += dt
		human_y -= human_speed * dt
		var cur_human := Vector2(585.0, human_y)
		var cur_dog := Vector2(585.0, human_y - 45.0)
		sim_tr.tick(dt, cur_dog, Vector2.ZERO, cur_human)
		if absf(human_y - TrailRunner.CROSSING_Y) < 10.0:
			tr_x_at_crossing_y = sim_tr.pos.x

	_check(tr_x_at_crossing_y < 460.0,
		"trail runner is well past center line (x=%.1f < 460.0) when autowalk human reaches crossing" % tr_x_at_crossing_y)
	_check(not sim_tr.human_hit, "autowalk human never gets bumped by trail runner")

	# 13. Drawing executes cleanly via ShapeBatch
	var sb := ShapeBatch.new()
	sim_tr.draw(m, sb, -1900.0, -1500.0)
	_check(true, "draw() executes cleanly through ShapeBatch without error")

	# 14. Reset returns to IDLE
	sim_tr.reset()
	_check(sim_tr.state == TrailRunner.State.IDLE, "reset() restores IDLE state")
	_check(sim_tr.pos == TrailRunner.START_POS, "reset() restores START_POS")
	_check(not sim_tr.triggered, "reset() clears triggered flag")

	print("\n--- TEST AIGUES TRAIL RUNNER RESULTS ---")
	print("Checks: %d, Failures: %d" % [checks, failures.size()])
	for f: String in failures:
		print("  FAIL: %s" % f)

	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
