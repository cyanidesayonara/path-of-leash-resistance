extends SceneTree

const AwningDump := preload("res://systems/awning_dump.gd")

# Regression test for El Diluvi awning rain dump live event (Walk 5).
# Tests the 0.8s warning telegraph ("Aigua va!"), falling water cascade,
# human soaking hazard, dog splash trick, barking interaction, arcade dodge save,
# and autowalk central clearance.

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
	game.level_id = "rain"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.awning_dump != null, "awning_dump instantiated for rain walk")
	var ad: AwningDump = m.awning_dump

	# 1. Initial idle state
	_check(ad.state == AwningDump.State.IDLE, "starts in IDLE state")
	_check(not ad.triggered, "starts untriggered")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1000.0)
	var far_human := Vector2(640.0, -960.0)
	var out1: Dictionary = ad.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(ad.state == AwningDump.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1420.0)
	var near_human := Vector2(640.0, -1400.0)
	var out2: Dictionary = ad.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(ad.state == AwningDump.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(ad.timer <= AwningDump.WARN_DURATION and ad.timer > 0.7, "timer initialized to 0.8s warning (%.2f)" % ad.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = ad.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(ad.state == AwningDump.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["dump"]), "dump has not fired yet during warning")

	# 5. Warning completes -> transitions to DUMPING
	var out4: Dictionary = ad.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["dump"]), "dump fires after 0.8s warning expires")
	_check(ad.state == AwningDump.State.DUMPING, "transitions to DUMPING state")

	# 6. Autowalk line (x = 640.0) is completely clear of splash zone
	var autowalk_pos := Vector2(640.0, AwningDump.DUMP_Y)
	_check(not AwningDump.SPLASH_RECT.has_point(autowalk_pos), "autowalk central path is clear of splash rect")
	_check(autowalk_pos.distance_to(Vector2(AwningDump.CASCADE_X, AwningDump.DUMP_Y)) > 120.0,
		"autowalk path is >120px clear of water cascade")

	# 7. Distracted human wandering under awning gets soaked
	var human_in_dump := Vector2(AwningDump.CASCADE_X - 10.0, AwningDump.DUMP_Y)
	var out5: Dictionary = ad.tick(0.05, near_dog, Vector2.ZERO, human_in_dump)
	_check(bool(out5["soak"]), "human under dump gets soaked")
	_check(ad.human_hit, "human_hit flag set")
	var out5b: Dictionary = ad.tick(0.05, near_dog, Vector2.ZERO, human_in_dump)
	_check(not bool(out5b["soak"]), "human does not get hit twice in single dump")

	# 8. Fast dog dashing into splash gets dog_splash trick
	var dog_in_dump := Vector2(AwningDump.CASCADE_X - 15.0, AwningDump.DUMP_Y)
	var slow_vel := Vector2(0.0, -30.0)
	var fast_vel := Vector2(0.0, -220.0)
	var out6a: Dictionary = ad.tick(0.05, dog_in_dump, slow_vel, Vector2(640.0, AwningDump.DUMP_Y))
	_check(not bool(out6a["dog_splash"]), "slow dog walking through does not get splash trick")
	var out6b: Dictionary = ad.tick(0.05, dog_in_dump, fast_vel, Vector2(640.0, AwningDump.DUMP_Y))
	_check(bool(out6b["dog_splash"]), "fast dog dashing through gets awning splash trick")

	# 9. Barking near falling cascade triggers rain bark
	var bark_far := Vector2(500.0, -1000.0)
	_check(not ad.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := Vector2(AwningDump.CASCADE_X - 10.0, AwningDump.DUMP_Y + 10.0)
	_check(ad.on_bark(bark_near), "bark near cascade triggers rain bark trick")
	_check(not ad.on_bark(bark_near), "bark trick does not award twice")

	# 10. Reset and test covered arcade dodge save
	ad.reset()
	_check(ad.state == AwningDump.State.IDLE, "reset restores IDLE state")
	ad.tick(0.016, near_dog, Vector2.ZERO, near_human)
	ad.tick(AwningDump.WARN_DURATION + 0.05, near_dog, Vector2.ZERO, near_human)
	_check(ad.state == AwningDump.State.DUMPING, "re-entered DUMPING after reset")
	# Human walking through west arcade (x < 600.0) while passing dump
	var human_in_arcade := Vector2(480.0, AwningDump.DUMP_Y - 10.0)
	var out7: Dictionary = ad.tick(0.05, near_dog, Vector2.ZERO, human_in_arcade)
	_check(bool(out7["dodge"]), "human walking through dry arcade earns dodge save")
	_check(ad.dodged, "dodged flag set")

	# 11. Expiry transitions to DRAINED
	ad.tick(AwningDump.DUMP_DURATION + 0.1, near_dog, Vector2.ZERO, human_in_arcade)
	_check(ad.state == AwningDump.State.DRAINED, "transitions to DRAINED after duration")

	# Clean node tree exit
	m.queue_free()
	await process_frame
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_diluvi_awning_dump: OK")
		quit(0)
	else:
		quit(1)
