extends SceneTree

const Fisherman := preload("res://systems/fisherman.gd")

# Regression test for El Port quayside fisherman reel-in live event (Walk 18).
# Tests the 0.8s warning telegraph ("Pica el peix!"), arching sea bass reel,
# quayside swing line snag hazard, central boardwalk dodge save, gull barking trick,
# landed fish pounce trick, autowalk central clearance, and leak-free cleanup.

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
	game.level_id = "port"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.fisherman != null, "fisherman instantiated for port walk")
	var fm: Fisherman = m.fisherman

	# 1. Initial idle state
	_check(fm.state == Fisherman.State.IDLE, "starts in IDLE state")
	_check(not fm.triggered, "starts untriggered")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1000.0)
	var far_human := Vector2(640.0, -960.0)
	var out1: Dictionary = fm.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(fm.state == Fisherman.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1790.0)
	var near_human := Vector2(640.0, -1760.0)
	var out2: Dictionary = fm.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(fm.state == Fisherman.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(fm.timer <= Fisherman.WARN_DURATION and fm.timer > 0.7, "timer initialized to 0.8s warning (%.2f)" % fm.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = fm.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(fm.state == Fisherman.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["reel"]), "reel has not fired yet during warning")

	# 5. Warning completes -> transitions to REELING
	var out4: Dictionary = fm.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["reel"]), "reel fires after 0.8s warning expires")
	_check(fm.state == Fisherman.State.REELING, "transitions to REELING state")

	# 6. Autowalk line (x = 640.0) is completely clear of quayside swing zone
	var autowalk_pos := Vector2(640.0, Fisherman.FISHERMAN_POS.y)
	_check(autowalk_pos.x < Fisherman.SWING_ZONE_X, "autowalk central path is west of quayside swing zone")
	_check(autowalk_pos.distance_to(Fisherman.FISHERMAN_POS) > 200.0,
		"autowalk path is >200px clear of fisherman (%.1f px)" % autowalk_pos.distance_to(Fisherman.FISHERMAN_POS))

	# 7. Distracted human wandering into quayside edge zone gets snagged
	var human_in_swing := Vector2(880.0, Fisherman.FISHERMAN_POS.y)
	var out5: Dictionary = fm.tick(0.05, near_dog, Vector2.ZERO, human_in_swing)
	_check(bool(out5["line_snag"]), "human in quayside swing zone gets snagged by line")
	_check(fm.human_hit, "human_hit flag set")
	var out5b: Dictionary = fm.tick(0.05, near_dog, Vector2.ZERO, human_in_swing)
	_check(not bool(out5b["line_snag"]), "human does not get snagged twice in single catch")

	# 8. Barking near reeling fisherman scares gulls and triggers trick
	var bark_far := Vector2(500.0, -1000.0)
	_check(not fm.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := Vector2(850.0, Fisherman.FISHERMAN_POS.y)
	_check(fm.on_bark(bark_near), "bark near fisherman triggers gull bark trick")
	_check(not fm.on_bark(bark_near), "gull bark trick does not award twice")

	# 9. Reeling duration expires -> fish lands on flagstones
	fm.tick(Fisherman.REEL_DURATION + 0.1, near_dog, Vector2.ZERO, autowalk_pos)
	_check(fm.state == Fisherman.State.LANDED, "transitions to LANDED state after reel")

	# 10. Dog pouncing onto landed fish earns fish snatch trick
	var dog_near_fish := Fisherman.FISH_LAND_POS + Vector2(4.0, 2.0)
	var out6: Dictionary = fm.tick(0.05, dog_near_fish, Vector2.ZERO, autowalk_pos)
	_check(bool(out6["fish_snatch"]), "dog pouncing on fish earns fish snatch trick")
	_check(fm.fish_snatched, "fish_snatched flag set")
	var out6b: Dictionary = fm.tick(0.05, dog_near_fish, Vector2.ZERO, autowalk_pos)
	_check(not bool(out6b["fish_snatch"]), "fish snatch does not award twice")

	# 11. Reset and test boardwalk dodge save
	fm.reset()
	_check(fm.state == Fisherman.State.IDLE, "reset restores IDLE state")
	_check(not fm.human_hit, "reset clears human_hit")
	_check(not fm.dodged, "reset clears dodged")

	# Trigger and reel
	fm.tick(0.016, near_dog, Vector2.ZERO, near_human)
	fm.tick(Fisherman.WARN_DURATION + 0.05, near_dog, Vector2.ZERO, near_human)
	_check(fm.state == Fisherman.State.REELING, "re-entered REELING after reset")

	# Guiding human safely along central boardwalk (x = 640.0) past fisherman
	var human_on_boardwalk := Vector2(640.0, Fisherman.FISHERMAN_POS.y - 10.0)
	var out7: Dictionary = fm.tick(0.05, near_dog, Vector2.ZERO, human_on_boardwalk)
	_check(bool(out7["dodge"]), "guiding human along boardwalk earns dodge save")
	_check(fm.dodged, "dodged flag set")

	# 12. Landed expiry transitions to FINISHED
	fm.tick(Fisherman.REEL_DURATION + 0.1, near_dog, Vector2.ZERO, human_on_boardwalk)
	_check(fm.state == Fisherman.State.LANDED, "transitions to LANDED state")
	fm.tick(Fisherman.LANDED_DURATION + 0.1, near_dog, Vector2.ZERO, human_on_boardwalk)
	_check(fm.state == Fisherman.State.FINISHED, "transitions to FINISHED after landed timer")

	# Clean node tree exit
	m.queue_free()
	await process_frame
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_port_fishing: OK")
		quit(0)
	else:
		quit(1)
