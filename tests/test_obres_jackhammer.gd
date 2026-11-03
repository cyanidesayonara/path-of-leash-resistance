extends SceneTree

const Jackhammer := preload("res://systems/jackhammer.gd")

# Regression test for Les Obres pneumatic jackhammer live event (Walk 11).
# Tests the 0.8s warning telegraph ("Atenció, el martell!"), drilling state,
# human rattle hazard, dog detour and bark tricks, quiet passage dodge save,
# autowalk clearance, and clean exit.

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
	game.level_id = "site"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.jackhammer != null, "jackhammer instantiated for site walk")
	var jh: Jackhammer = m.jackhammer

	# 1. Initial idle state
	_check(jh.state == Jackhammer.State.IDLE, "starts in IDLE state")
	_check(not jh.triggered, "starts untriggered")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(690.0, -2000.0)
	var far_human := Vector2(690.0, -1960.0)
	var out1: Dictionary = jh.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(jh.state == Jackhammer.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(690.0, -2330.0)
	var near_human := Vector2(690.0, -2310.0)
	var out2: Dictionary = jh.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(jh.state == Jackhammer.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(jh.timer <= Jackhammer.WARN_DURATION and jh.timer > 0.7, "timer initialized to 0.8s warning (%.2f)" % jh.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = jh.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(jh.state == Jackhammer.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["drill"]), "drill has not fired yet during warning")

	# 5. Warning completes -> transitions to DRILLING
	var out4: Dictionary = jh.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["drill"]), "drill fires after 0.8s warning expires")
	_check(jh.state == Jackhammer.State.DRILLING, "transitions to DRILLING state")

	# 6. Autowalk line (x = 690.0) is completely clear of pit and rattle zone
	var autowalk_pos := Vector2(690.0, Jackhammer.PIT_POS.y)
	_check(autowalk_pos.distance_to(Jackhammer.PIT_POS) > Jackhammer.RATTLE_RADIUS + 80.0,
		"autowalk path is >80px clear of rattle radius")

	# 7. Distracted human in deafening rattle zone gets startled
	var human_in_rattle := Jackhammer.PIT_POS + Vector2(-20.0, 10.0)
	var out5: Dictionary = jh.tick(0.05, near_dog, Vector2.ZERO, human_in_rattle)
	_check(bool(out5["rattle"]), "human in rattle zone gets startled")
	_check(jh.human_hit, "human_hit flag set")
	var out5b: Dictionary = jh.tick(0.05, near_dog, Vector2.ZERO, human_in_rattle)
	_check(not bool(out5b["rattle"]), "human does not get rattled twice in single drill pass")

	# 8. Fast dog dashing through detour lane gets smooth detour trick
	var dog_in_detour := Vector2(700.0, Jackhammer.PIT_POS.y)
	var slow_vel := Vector2(0.0, -30.0)
	var fast_vel := Vector2(0.0, -200.0)
	var out6a: Dictionary = jh.tick(0.05, dog_in_detour, slow_vel, Vector2(690.0, Jackhammer.PIT_POS.y))
	_check(not bool(out6a["dog_detour"]), "slow dog walking through does not get detour trick")
	var out6b: Dictionary = jh.tick(0.05, dog_in_detour, fast_vel, Vector2(690.0, Jackhammer.PIT_POS.y))
	_check(bool(out6b["dog_detour"]), "fast dog dashing through detour lane gets smooth detour trick")

	# 9. Barking near jackhammer triggers trick
	var bark_far := Vector2(400.0, -2000.0)
	_check(not jh.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := Jackhammer.PIT_POS + Vector2(-20.0, 15.0)
	_check(jh.on_bark(bark_near), "bark near drill triggers jackhammer bark trick")
	_check(not jh.on_bark(bark_near), "bark trick does not award twice")

	# 10. Reset and test quiet passage dodge save
	jh.reset()
	_check(jh.state == Jackhammer.State.IDLE, "reset restores IDLE state")
	jh.tick(0.016, near_dog, Vector2.ZERO, near_human)
	jh.tick(Jackhammer.WARN_DURATION + 0.05, near_dog, Vector2.ZERO, near_human)
	_check(jh.state == Jackhammer.State.DRILLING, "re-entered DRILLING after reset")
	# The ordinary line past the pit is not a save.
	var human_quiet := Vector2(640.0, Jackhammer.PIT_POS.y - 10.0)
	var out7: Dictionary = jh.tick(0.05, near_dog, Vector2.ZERO, human_quiet)
	_check(not bool(out7["dodge"]), "walking past the pit is not a save")
	_check(not jh.dodged, "dodged stays clear")

	# 11. Expiry transitions to FINISHED
	jh.tick(Jackhammer.DRILL_DURATION + 0.1, near_dog, Vector2.ZERO, human_quiet)
	_check(jh.state == Jackhammer.State.FINISHED, "transitions to FINISHED after duration")

	# Clean node tree exit
	m.queue_free()
	await process_frame
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_obres_jackhammer: OK")
		quit(0)
	else:
		quit(1)
