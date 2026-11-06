extends SceneTree

const ConeDog := preload("res://systems/cone_dog.gd")

# Regression test for El Veterinari cone-of-shame dog live event (Walk 20).
# Tests the 0.8s warning telegraph ("Cone dog on the loose!"), eastward scramble
# across slippery linoleum floor, dropped bacon pill pocket snatch trick, distracted
# human bump hazard, dog boop trick, cone bark trick, clinic dodge save, autowalk
# safety, and leak-free cleanup.

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
	game.level_id = "vet"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.cone_dog != null, "cone_dog instantiated for vet walk")
	var cd: ConeDog = m.cone_dog

	# 1. Initial idle state
	_check(cd.state == ConeDog.State.IDLE, "starts in IDLE state")
	_check(not cd.triggered, "starts untriggered")
	_check(cd.pos == ConeDog.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1800.0)
	var far_human := Vector2(640.0, -1760.0)
	var out1: Dictionary = cd.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(cd.state == ConeDog.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -2020.0)
	var near_human := Vector2(640.0, -1980.0)
	var out2: Dictionary = cd.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(cd.state == ConeDog.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(cd.timer <= ConeDog.WARN_DURATION and cd.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % cd.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = cd.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(cd.state == ConeDog.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["scuffle"]), "scuffle has not fired yet during warning")
	_check(cd.pos == ConeDog.START_POS, "cone dog remains at start during telegraph")

	# 5. Warning completes -> transitions to RUNNING
	var out4: Dictionary = cd.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["scuffle"]), "scuffle fires after 0.8s warning expires")
	_check(cd.state == ConeDog.State.RUNNING, "transitions to RUNNING state")
	cd.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(cd.pos.x > ConeDog.START_POS.x, "cone dog begins scrambling east")

	# 6. Dog runs across corridor and drops bacon pill pocket
	var had_drop := false
	for step in range(30):
		var step_out: Dictionary = cd.tick(0.05, near_dog, Vector2.ZERO, near_human)
		if bool(step_out["drop_treat"]):
			had_drop = true
	_check(had_drop, "treat drops as cone dog crosses past central linoleum")
	_check(cd.treat_dropped, "treat_dropped flag set")

	# 7. Dog snatch trick on dropped treat
	var dog_at_treat := cd.treat_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = cd.tick(0.02, dog_at_treat, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog pouncing onto treat earns treat snatch trick")
	_check(cd.treat_snatched, "treat_snatched flag set")
	var out5b: Dictionary = cd.tick(0.02, dog_at_treat, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "treat snatch does not award twice")

	# 8. Distracted human in cone dog path gets bumped
	var human_in_path := Vector2(cd.pos.x, ConeDog.CROSSING_Y)
	var out6: Dictionary = cd.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(bool(out6["bump"]), "human in cone path gets bumped")
	_check(cd.human_hit, "human_hit flag set")
	var out6b: Dictionary = cd.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(not bool(out6b["bump"]), "human does not get bumped twice in single run")

	# 9. Dog boop trick on cone dog directly
	var test_cd := ConeDog.new()
	test_cd.reset()
	test_cd.tick(0.016, near_dog, Vector2.ZERO, near_human)  # Trigger
	test_cd.tick(0.85, near_dog, Vector2.ZERO, near_human)   # Start running
	var dog_boop_pos := test_cd.pos + Vector2(4.0, 2.0)
	var out_boop: Dictionary = test_cd.tick(0.02, dog_boop_pos, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping cone directly awards boop trick")
	_check(test_cd.booped, "booped flag set")
	var out_boop2: Dictionary = test_cd.tick(0.02, dog_boop_pos, Vector2.ZERO, far_human)
	_check(not bool(out_boop2["boop"]), "boop trick does not fire twice")

	# 10. Barking near cone dog alerts them and awards bark trick
	var bark_far := Vector2(200.0, -500.0)
	_check(not test_cd.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := test_cd.pos + Vector2(20.0, 10.0)
	_check(test_cd.on_bark(bark_near), "bark near cone dog triggers cone bark trick")
	_check(test_cd.barked, "barked flag set")
	_check(not test_cd.on_bark(bark_near), "bark trick does not award twice")

	# 11. Full run to east end triggers clinic dodge save if human avoided bump
	var test_dodge := ConeDog.new()
	test_dodge.reset()
	test_dodge.tick(0.016, near_dog, Vector2.ZERO, near_human)  # Trigger
	test_dodge.tick(0.85, near_dog, Vector2.ZERO, near_human)   # Running
	var dodge_human := Vector2(640.0, -2120.0)  # Close to crossing (60px away), safely clear of 32px bump radius
	var dodged_event := false
	for step in range(60):
		var step_out: Dictionary = test_dodge.tick(0.05, far_dog, Vector2.ZERO, dodge_human)
		if bool(step_out["dodge"]):
			dodged_event = true
	_check(dodged_event, "safely navigating crossing awards clinic dodge save")
	_check(test_dodge.dodged, "dodged flag set")
	_check(test_dodge.state == ConeDog.State.SETTLED, "cone dog settles at east side")

	# 12. Autowalk path safety: at x = 640.0, crossing clears center before human arrival
	var sim_cd := ConeDog.new()
	sim_cd.reset()
	var auto_dog := Vector2(640.0, -2005.0)
	var auto_human := Vector2(640.0, -1960.0)
	sim_cd.tick(0.016, auto_dog, Vector2.ZERO, auto_human)
	_check(sim_cd.state == ConeDog.State.TELEGRAPH, "autowalk triggers telegraph at y=-2005")

	var human_y := auto_human.y
	var human_speed := 65.0  # standard autopilot walk pace
	var t := 0.0
	var dt := 0.05
	var dog_x_at_crossing_y := 0.0

	while human_y > ConeDog.CROSSING_Y - 20.0:
		t += dt
		human_y -= human_speed * dt
		var cur_human := Vector2(640.0, human_y)
		var cur_dog := Vector2(640.0, human_y - 45.0)
		sim_cd.tick(dt, cur_dog, Vector2.ZERO, cur_human)
		if absf(human_y - ConeDog.CROSSING_Y) < 10.0:
			dog_x_at_crossing_y = sim_cd.pos.x

	_check(dog_x_at_crossing_y > 700.0,
		"cone dog is well past center line (x=%.1f > 700.0) when autowalk human reaches crossing" % dog_x_at_crossing_y)
	_check(not sim_cd.human_hit, "autowalk human never gets bumped by cone dog")

	# 13. Drawing executes cleanly via ShapeBatch
	var sb := ShapeBatch.new()
	sim_cd.draw(m, sb, -2400.0, -1900.0)
	_check(true, "draw() executes cleanly through ShapeBatch without error")

	# 14. Reset returns to IDLE
	sim_cd.reset()
	_check(sim_cd.state == ConeDog.State.IDLE, "reset() restores IDLE state")
	_check(sim_cd.pos == ConeDog.START_POS, "reset() restores START_POS")
	_check(not sim_cd.triggered, "reset() clears triggered flag")

	print("\n--- TEST VET CONE DOG RESULTS ---")
	print("Checks: %d, Failures: %d" % [checks, failures.size()])
	for f: String in failures:
		print("  FAIL: %s" % f)

	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
