extends SceneTree

const Unicyclist := preload("res://systems/unicyclist.gd")

# Regression test for El Tibidabo summit fairground unicyclist live event (Walk 21).
# Tests the 0.8s warning telegraph ("Unicycle coming through!"), eastward ride
# across the mountain road, dropped juggling pin snatch trick, distracted human
# bump hazard, dog boop trick, unicycle bark trick, summit dodge save, autowalk
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
	game.level_id = "tibidabo"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.unicyclist != null, "unicyclist instantiated for tibidabo walk")
	var uc: Unicyclist = m.unicyclist

	# 1. Initial idle state
	_check(uc.state == Unicyclist.State.IDLE, "starts in IDLE state")
	_check(not uc.triggered, "starts untriggered")
	_check(uc.pos == Unicyclist.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1750.0)
	var far_human := Vector2(640.0, -1710.0)
	var out1: Dictionary = uc.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(uc.state == Unicyclist.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1940.0)
	var near_human := Vector2(640.0, -1900.0)
	var out2: Dictionary = uc.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(uc.state == Unicyclist.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(uc.timer <= Unicyclist.WARN_DURATION and uc.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % uc.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = uc.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(uc.state == Unicyclist.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["wobble"]), "wobble has not fired yet during warning")
	_check(uc.pos == Unicyclist.START_POS, "unicyclist remains at start during telegraph")

	# 5. Warning completes -> transitions to RIDING
	var out4: Dictionary = uc.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["wobble"]), "wobble fires after 0.8s warning expires")
	_check(uc.state == Unicyclist.State.RIDING, "transitions to RIDING state")
	uc.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(uc.pos.x > Unicyclist.START_POS.x, "unicyclist begins riding east")

	# 6. Unicyclist rides across road and drops juggling pin
	var had_drop := false
	for step in range(35):
		var step_out: Dictionary = uc.tick(0.05, near_dog, Vector2.ZERO, near_human)
		if bool(step_out["drop_pin"]):
			had_drop = true
	_check(had_drop, "juggling pin drops as unicyclist crosses past middle road")
	_check(uc.pin_dropped, "pin_dropped flag set")

	# 7. Dog snatch trick on dropped juggling pin
	var dog_at_pin := uc.pin_pos + Vector2(2.0, 2.0)
	var out5: Dictionary = uc.tick(0.02, dog_at_pin, Vector2.ZERO, far_human)
	_check(bool(out5["snatch"]), "dog pouncing onto pin earns pin snatch trick")
	_check(uc.pin_snatched, "pin_snatched flag set")
	var out5b: Dictionary = uc.tick(0.02, dog_at_pin, Vector2.ZERO, far_human)
	_check(not bool(out5b["snatch"]), "pin snatch does not award twice")

	# 8. Distracted human in unicycle path gets bumped
	var human_in_path := Vector2(uc.pos.x, Unicyclist.CROSSING_Y)
	var out6: Dictionary = uc.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(bool(out6["bump"]), "human in unicycle path gets bumped")
	_check(uc.human_hit, "human_hit flag set")
	var out6b: Dictionary = uc.tick(0.02, far_dog, Vector2.ZERO, human_in_path)
	_check(not bool(out6b["bump"]), "human does not get bumped twice in single run")

	# 9. Dog boop trick on unicyclist directly
	var test_uc := Unicyclist.new()
	test_uc.reset()
	test_uc.tick(0.016, near_dog, Vector2.ZERO, near_human)  # Trigger
	test_uc.tick(0.85, near_dog, Vector2.ZERO, near_human)   # Start riding
	var dog_boop_pos := test_uc.pos + Vector2(4.0, 2.0)
	var out_boop: Dictionary = test_uc.tick(0.02, dog_boop_pos, Vector2.ZERO, far_human)
	_check(bool(out_boop["boop"]), "dog booping unicyclist directly awards boop trick")
	_check(test_uc.booped, "booped flag set")
	var out_boop2: Dictionary = test_uc.tick(0.02, dog_boop_pos, Vector2.ZERO, far_human)
	_check(not bool(out_boop2["boop"]), "boop trick does not fire twice")

	# 10. Barking near unicyclist alerts them and awards bark trick
	var bark_far := Vector2(200.0, -500.0)
	_check(not test_uc.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := test_uc.pos + Vector2(20.0, 10.0)
	_check(test_uc.on_bark(bark_near), "bark near unicyclist triggers unicycle bark trick")
	_check(test_uc.barked, "barked flag set")
	_check(not test_uc.on_bark(bark_near), "bark trick does not award twice")

	# 11. Full run to east end triggers summit dodge save if human avoided bump
	var test_dodge := Unicyclist.new()
	test_dodge.reset()
	test_dodge.tick(0.016, near_dog, Vector2.ZERO, near_human)  # Trigger
	test_dodge.tick(0.85, near_dog, Vector2.ZERO, near_human)   # Riding
	var dodge_human := Vector2(640.0, -2040.0)  # Close to crossing (60px away), safely clear of 30px bump radius
	var dodged_event := false
	for step in range(65):
		var step_out: Dictionary = test_dodge.tick(0.05, far_dog, Vector2.ZERO, dodge_human)
		if bool(step_out["dodge"]):
			dodged_event = true
	_check(dodged_event, "safely navigating crossing awards summit dodge save")
	_check(test_dodge.dodged, "dodged flag set")
	_check(test_dodge.state == Unicyclist.State.SETTLED, "unicyclist settles at east verge")

	# 12. Autowalk path safety: at x = 640.0, crossing clears center before human arrival
	var sim_uc := Unicyclist.new()
	sim_uc.reset()
	var auto_dog := Vector2(640.0, -1925.0)
	var auto_human := Vector2(640.0, -1880.0)
	sim_uc.tick(0.016, auto_dog, Vector2.ZERO, auto_human)
	_check(sim_uc.state == Unicyclist.State.TELEGRAPH, "autowalk triggers telegraph at y=-1925")

	var human_y := auto_human.y
	var human_speed := 65.0  # standard autopilot walk pace
	var t := 0.0
	var dt := 0.05
	var uc_x_at_crossing_y := 0.0

	while human_y > Unicyclist.CROSSING_Y - 20.0:
		t += dt
		human_y -= human_speed * dt
		var cur_human := Vector2(640.0, human_y)
		var cur_dog := Vector2(640.0, human_y - 45.0)
		sim_uc.tick(dt, cur_dog, Vector2.ZERO, cur_human)
		if absf(human_y - Unicyclist.CROSSING_Y) < 10.0:
			uc_x_at_crossing_y = sim_uc.pos.x

	_check(uc_x_at_crossing_y > 700.0,
		"unicyclist is well past center line (x=%.1f > 700.0) when autowalk human reaches crossing" % uc_x_at_crossing_y)
	_check(not sim_uc.human_hit, "autowalk human never gets bumped by unicyclist")

	# 13. Drawing executes cleanly via ShapeBatch
	var sb := ShapeBatch.new()
	sim_uc.draw(m, sb, -2300.0, -1900.0)
	_check(true, "draw() executes cleanly through ShapeBatch without error")

	# 14. Reset returns to IDLE
	sim_uc.reset()
	_check(sim_uc.state == Unicyclist.State.IDLE, "reset() restores IDLE state")
	_check(sim_uc.pos == Unicyclist.START_POS, "reset() restores START_POS")
	_check(not sim_uc.triggered, "reset() clears triggered flag")

	print("\n--- TEST TIBIDABO UNICYCLIST RESULTS ---")
	print("Checks: %d, Failures: %d" % [checks, failures.size()])
	for f: String in failures:
		print("  FAIL: %s" % f)

	m.queue_free()
	quit(1 if failures.size() > 0 else 0)
