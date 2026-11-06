extends SceneTree

const LuggageTrolley := preload("res://systems/luggage_trolley.gd")

# Regression test for L'Estació runaway luggage trolley live event (Walk 9 / 19).
# Tests the 0.8s warning telegraph ("Luggage cart coming through!"), eastward roll across
# the concourse floor, brass joint clatters, human bump hazard, dog boop trick,
# dog bark trick, concourse dodge save, autowalk safety, and leak-free cleanup.

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
	game.level_id = "station"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.luggage_trolley != null, "luggage_trolley instantiated for station walk")
	var lt: LuggageTrolley = m.luggage_trolley

	# 1. Initial idle state
	_check(lt.state == LuggageTrolley.State.IDLE, "starts in IDLE state")
	_check(not lt.triggered, "starts untriggered")
	_check(lt.pos == LuggageTrolley.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -800.0)
	var far_human := Vector2(640.0, -760.0)
	var out1: Dictionary = lt.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(lt.state == LuggageTrolley.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1050.0)
	var near_human := Vector2(640.0, -1020.0)
	var out2: Dictionary = lt.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(lt.state == LuggageTrolley.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(lt.timer <= LuggageTrolley.WARN_DURATION and lt.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % lt.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = lt.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(lt.state == LuggageTrolley.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(not bool(out3["roll"]), "roll has not fired yet during warning")
	_check(lt.pos == LuggageTrolley.START_POS, "trolley remains at start during telegraph")

	# 5. Warning completes -> transitions to ROLLING
	var out4: Dictionary = lt.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(bool(out4["roll"]), "roll fires after 0.8s warning expires")
	_check(lt.state == LuggageTrolley.State.ROLLING, "transitions to ROLLING state")
	lt.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(lt.pos.x > LuggageTrolley.START_POS.x, "trolley begins rolling east")

	# 6. Brass terrazzo joint clatter
	var had_clatter := false
	for step in range(20):
		var step_out: Dictionary = lt.tick(0.05, near_dog, Vector2.ZERO, near_human)
		if bool(step_out["clatter"]):
			had_clatter = true
	_check(had_clatter, "trolley clatters over brass floor joints while rolling")

	# 7. Distracted human in trolley path gets bumped
	var human_in_path := Vector2(lt.pos.x, LuggageTrolley.CROSSING_Y)
	var out5: Dictionary = lt.tick(0.02, near_dog, Vector2.ZERO, human_in_path)
	_check(bool(out5["bump"]), "human standing in trolley trajectory gets bumped")
	_check(lt.human_hit, "human_hit flag set")
	var out5b: Dictionary = lt.tick(0.02, near_dog, Vector2.ZERO, human_in_path)
	_check(not bool(out5b["bump"]), "human does not get bumped twice in single run")

	# 8. Dog booping rolling luggage awards boop trick
	var dog_at_cart := lt.pos + Vector2(2.0, 2.0)
	var out6: Dictionary = lt.tick(0.02, dog_at_cart, Vector2.ZERO, far_human)
	_check(bool(out6["boop"]), "dog booping rolling cart awards boop trick")
	_check(lt.booped, "booped flag set")
	var out6b: Dictionary = lt.tick(0.02, dog_at_cart, Vector2.ZERO, far_human)
	_check(not bool(out6b["boop"]), "boop trick does not award twice")

	# 9. Barking near trolley alerts station and awards bark trick
	var bark_far := Vector2(200.0, -500.0)
	_check(not lt.on_bark(bark_far), "distant bark does not trigger trick")
	var bark_near := lt.pos + Vector2(20.0, 0.0)
	_check(lt.on_bark(bark_near), "bark near trolley triggers bark trick")
	_check(not lt.on_bark(bark_near), "bark trick does not award twice")

	# 10. Reset and test concourse dodge save
	lt.reset()
	_check(lt.state == LuggageTrolley.State.IDLE, "reset restores IDLE state")
	_check(lt.pos == LuggageTrolley.START_POS, "reset restores START_POS")
	_check(not lt.human_hit, "reset clears human_hit")
	_check(not lt.dodged, "reset clears dodged")

	# Trigger and roll
	lt.tick(0.016, near_dog, Vector2.ZERO, near_human)
	lt.tick(LuggageTrolley.WARN_DURATION + 0.05, near_dog, Vector2.ZERO, near_human)
	_check(lt.state == LuggageTrolley.State.ROLLING, "re-entered ROLLING after reset")

	# The walk's line, while the trolley is still at the door, is not a save.
	var human_dodged := Vector2(640.0, LuggageTrolley.CROSSING_Y - 30.0)
	var out7: Dictionary = lt.tick(0.05, near_dog, Vector2.ZERO, human_dodged)
	_check(not bool(out7["dodge"]), "walking the crossing line is not a save")
	_check(not lt.dodged, "dodged stays clear")

	# 11. Run until settled at concourse edge
	for i in range(100):
		if lt.state == LuggageTrolley.State.SETTLED:
			break
		lt.tick(0.05, near_dog, Vector2.ZERO, human_dodged)
	_check(lt.state == LuggageTrolley.State.SETTLED, "trolley settles at END_POS")
	_check(lt.pos.x >= LuggageTrolley.END_POS.x, "trolley reached east concourse edge")

	# 12. Autowalk trajectory safety analysis
	# When autowalk triggers at y = -1040, walking at base speed 65 px/s:
	var autowalk_speed := 65.0
	var time_to_cross := (absf(LuggageTrolley.CROSSING_Y) - absf(LuggageTrolley.TRIGGER_Y)) / autowalk_speed
	var trolley_dist_at_cross := (time_to_cross - LuggageTrolley.WARN_DURATION) * LuggageTrolley.ROLL_SPEED
	var trolley_x_at_cross := LuggageTrolley.START_POS.x + trolley_dist_at_cross
	_check(trolley_x_at_cross > 780.0,
		"trolley is well past center line (x=%.1f) when autowalk arrives at crossing" % trolley_x_at_cross)

	# Clean node tree exit
	m.queue_free()
	await process_frame
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_estacio_trolley: OK")
		quit(0)
	else:
		quit(1)
