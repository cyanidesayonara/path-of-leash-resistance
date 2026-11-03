extends SceneTree

const Waiter := preload("res://systems/waiter.gd")

# Regression test for Plaça Reial bistro waiter & tapas tray live event (Walk 19).
# Tests the 0.8s warning telegraph ("Compte amb la safata!"), eastward walk across
# plaza flagstones, tapas croqueta drop & dog snatch trick, human bump hazard,
# waiter bark trick, plaza dodge save, autowalk safety, and leak-free cleanup.

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
	game.level_id = "reial"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.waiter != null, "waiter instantiated for reial walk")
	var wt: Waiter = m.waiter

	# 1. Initial idle state
	_check(wt.state == Waiter.State.IDLE, "starts in IDLE state")
	_check(not wt.triggered, "starts untriggered")
	_check(wt.pos == Waiter.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -800.0)
	var far_human := Vector2(640.0, -760.0)
	var out1: Dictionary = wt.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(wt.state == Waiter.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1120.0)
	var near_human := Vector2(640.0, -1080.0)
	var out2: Dictionary = wt.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(wt.state == Waiter.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(wt.timer <= Waiter.WARN_DURATION and wt.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % wt.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = wt.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(wt.state == Waiter.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["walk"]), "walk has not fired yet during warning")
	_check(wt.pos == Waiter.START_POS, "waiter remains at start during telegraph")

	# 5. Warning completes -> transitions to WALKING
	var out4: Dictionary = wt.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["walk"]), "walk fires after 0.8s warning expires")
	_check(wt.state == Waiter.State.WALKING, "transitions to WALKING state")
	wt.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(wt.pos.x > Waiter.START_POS.x, "waiter begins walking east")

	# 6. Waiter walks across plaza and drops croqueta
	var had_drop := false
	for step in range(30):
		var step_out: Dictionary = wt.tick(0.05, near_dog, Vector2.ZERO, near_human)
		if bool(step_out["drop_croqueta"]):
			had_drop = true
	_check(had_drop, "tapas croqueta drops as waiter crosses past middle plaza")
	_check(wt.croqueta_dropped, "croqueta_dropped flag set")

	# 7. Dog snatch trick on dropped croqueta
	var dog_at_croqueta := wt.croqueta_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = wt.tick(0.02, dog_at_croqueta, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog pouncing onto croqueta earns croqueta snatch trick")
	_check(wt.croqueta_snatched, "croqueta_snatched flag set")
	var out5b: Dictionary = wt.tick(0.02, dog_at_croqueta, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "croqueta snatch does not award twice")

	# 8. Distracted human in waiter path gets bumped
	var human_in_path := Vector2(wt.pos.x, Waiter.CROSSING_Y)
	var out6: Dictionary = wt.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(bool(out6["bump"]), "human in waiter path gets bumped")
	_check(wt.human_hit, "human_hit flag set")
	var out6b: Dictionary = wt.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(not bool(out6b["bump"]), "human does not get bumped twice in single run")

	# 9. Barking near balancing waiter alerts them and awards bark trick
	var bark_far := Vector2(200.0, -500.0)
	_check(not wt.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := wt.pos + Vector2(20.0, 0.0)
	_check(wt.on_bark(bark_near), "bark near waiter triggers bark trick")
	_check(not wt.on_bark(bark_near), "bark trick does not award twice")

	# 10. Reset and test plaza dodge save
	wt.reset()
	_check(wt.state == Waiter.State.IDLE, "reset restores IDLE state")
	_check(wt.pos == Waiter.START_POS, "reset restores START_POS")
	_check(not wt.human_hit, "reset clears human_hit")
	_check(not wt.dodged, "reset clears dodged")

	# Trigger and walk
	wt.tick(0.016, near_dog, Vector2.ZERO, near_human)
	wt.tick(Waiter.WARN_DURATION + 0.05, near_dog, Vector2.ZERO, near_human)
	_check(wt.state == Waiter.State.WALKING, "re-entered WALKING after reset")

	# The walk's line, while the waiter is still at the door, is not a save.
	var human_dodged := Vector2(640.0, Waiter.CROSSING_Y - 30.0)
	var out7: Dictionary = wt.tick(0.05, near_dog, Vector2.ZERO, human_dodged)
	_check(not bool(out7["dodge"]), "walking the crossing line is not a save")
	_check(not wt.dodged, "dodged stays clear")

	# 11. Run until settled at outdoor tables
	for i in range(80):
		if wt.state == Waiter.State.SETTLED:
			break
		wt.tick(0.05, near_dog, Vector2.ZERO, human_dodged)
	_check(wt.state == Waiter.State.SETTLED, "waiter settles at END_POS")
	_check(wt.pos.x >= Waiter.END_POS.x, "waiter reached outdoor bistro tables")

	# 12. Autowalk trajectory safety analysis
	# When autowalk triggers at y = -1100, walking at base speed 65 px/s:
	var autowalk_speed := 65.0
	var time_to_cross := (absf(Waiter.CROSSING_Y) - absf(Waiter.TRIGGER_Y)) / autowalk_speed
	var waiter_dist_at_cross := (time_to_cross - Waiter.WARN_DURATION) * Waiter.WALK_SPEED
	var waiter_x_at_cross := Waiter.START_POS.x + waiter_dist_at_cross
	_check(waiter_x_at_cross > 650.0,
		"waiter is past central line (x=%.1f) when autowalk arrives at crossing" % waiter_x_at_cross)

	# Clean node tree exit
	m.queue_free()
	await process_frame
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_reial_waiter: OK")
		quit(0)
	else:
		quit(1)
