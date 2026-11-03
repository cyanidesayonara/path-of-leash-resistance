extends SceneTree

const LostTourist := preload("res://systems/lost_tourist.gd")

# Regression test for El Laberint d'Horta lost maze tourist live event (Walk 23).
# Tests the 0.8s warning telegraph ("On és la sortida?!"), eastbound sprint across
# the maze aisle, dropped carquinyoli snatch trick, distracted human bump hazard,
# dog boop trick, tourist bark trick, maze dodge save, autowalk safety, and
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
	game.level_id = "horta"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.lost_tourist != null, "lost_tourist instantiated for horta walk")
	var lt: LostTourist = m.lost_tourist

	# 1. Initial idle state
	_check(lt.state == LostTourist.State.IDLE, "starts in IDLE state")
	_check(not lt.triggered, "starts untriggered")
	_check(lt.pos == LostTourist.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(640.0, -1420.0)
	var far_human := Vector2(640.0, -1400.0)
	var out1: Dictionary = lt.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(lt.state == LostTourist.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(640.0, -1540.0)
	var near_human := Vector2(640.0, -1510.0)
	var out2: Dictionary = lt.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(lt.state == LostTourist.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(lt.timer <= LostTourist.WARN_DURATION and lt.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % lt.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = lt.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(lt.state == LostTourist.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(lt.pos == LostTourist.START_POS, "tourist remains at start during telegraph")

	# 5. Warning completes -> transitions to RUNNING
	var out4: Dictionary = lt.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(lt.state == LostTourist.State.RUNNING, "transitions to RUNNING after 0.8s")
	lt.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(lt.pos.x > LostTourist.START_POS.x, "begins moving east (%.1f)" % lt.pos.x)

	# 6. Moves eastward across sauló path at ~200 px/s
	var x_before: float = lt.pos.x
	lt.tick(0.5, near_dog, Vector2.ZERO, near_human)
	_check(lt.pos.x > x_before + 80.0, "progresses east along crossing path (%.1f)" % lt.pos.x)

	# 7. Drops carquinyoli pastry when crossing past middle aisle (x >= 620.0)
	var safety_counter := 0
	while lt.pos.x < LostTourist.CARQUINYOLI_DROP_X and safety_counter < 100:
		safety_counter += 1
		lt.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(lt.carquinyoli_dropped, "drops carquinyoli past center aisle")
	_check(lt.carquinyoli_pos.distance_to(lt.pos) < 30.0, "carquinyoli spawns near tourist")

	# Advance tourist forward so dog can snatch pastry without booping tourist
	lt.tick(0.25, far_dog, Vector2.ZERO, near_human)
	_check(lt.pos.distance_to(lt.carquinyoli_pos) > LostTourist.BOOP_RADIUS + 10.0,
		"tourist moves safely ahead of dropped pastry")

	# 8. Dog snatches dropped carquinyoli
	_check(not lt.booped, "not booped before snatch")
	var out_snatch: Dictionary = lt.tick(0.05, lt.carquinyoli_pos, Vector2.ZERO, near_human)
	_check(bool(out_snatch["snatch"]), "dog snatches carquinyoli when close")
	_check(lt.carquinyoli_snatched, "carquinyoli marked as snatched")
	_check(not lt.booped, "snatching pastry does not boop distant tourist")

	# 9. Bark reaction while running
	_check(not lt.bark_reacted, "bark not reacted yet")
	var bark_ok: bool = lt.on_bark(lt.pos + Vector2(40.0, 0.0))
	_check(bark_ok, "on_bark returns true within radius")
	_check(lt.bark_reacted, "bark_reacted set to true")
	var bark_repeat: bool = lt.on_bark(lt.pos + Vector2(20.0, 0.0))
	_check(not bark_repeat, "on_bark one-shot per encounter")

	# 10. Boop trick: dog catches up and boops tourist directly
	_check(not lt.booped, "not booped yet")
	var out_boop: Dictionary = lt.tick(0.016, lt.pos + Vector2(10.0, 0.0), Vector2.ZERO, near_human)
	_check(bool(out_boop["boop"]), "boop detected within radius")
	_check(lt.booped, "booped marked true")

	# 11. Human collision hazard (test on fresh instance)
	var hazard_lt := LostTourist.new()
	hazard_lt.state = LostTourist.State.RUNNING
	hazard_lt.pos = Vector2(640.0, -1740.0)
	var hit_human := Vector2(640.0, -1745.0)
	var out_hit: Dictionary = hazard_lt.tick(0.016, Vector2.ZERO, Vector2.ZERO, hit_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_lt.human_hit, "human_hit flag set")

	# 12. A near miss is a save; walking the aisle while they are still at the hedge is not
	var dodge_lt := LostTourist.new()
	dodge_lt.triggered = true
	dodge_lt.state = LostTourist.State.RUNNING
	dodge_lt.pos = Vector2(850.0, -1740.0)
	var beside := dodge_lt.pos + Vector2(50.0, 0.0)
	var out_beside: Dictionary = dodge_lt.tick(0.0, Vector2.ZERO, Vector2.ZERO, beside)
	_check(not bool(out_beside["dodge"]), "standing beside the tourist is not yet a save")
	_check(not bool(out_beside["bump"]), "beside is outside the bump")
	var clear := dodge_lt.pos + Vector2(0.0, 140.0)
	var out_dodge: Dictionary = dodge_lt.tick(0.0, Vector2.ZERO, Vector2.ZERO, clear)
	_check(bool(out_dodge["dodge"]), "stepping clear of a near miss is a save")
	_check(dodge_lt.dodge_awarded, "dodge_awarded set")

	# 13. Runs to END_POS and settles
	safety_counter = 0
	while lt.state == LostTourist.State.RUNNING and safety_counter < 100:
		safety_counter += 1
		lt.tick(0.1, Vector2.ZERO, Vector2.ZERO, near_human)
	_check(lt.state == LostTourist.State.SETTLED, "settles at opposite wall")
	_check(lt.pos.x >= LostTourist.END_POS.x - 1.0, "settles at END_POS")

	# 14. Return walk does not re-trigger
	var return_lt := LostTourist.new()
	return_lt.triggered = true
	return_lt.state = LostTourist.State.SETTLED
	var return_human := Vector2(640.0, -1600.0)
	var out_return: Dictionary = return_lt.tick(0.016, Vector2.ZERO, Vector2.ZERO, return_human)
	_check(not bool(out_return["warn"]), "does not re-trigger on return leg")

	# 15. Autowalk clearance: simulated uninterrupted autowalk traversal
	var sim_lt := LostTourist.new()
	var auto_human := Vector2(640.0, -1450.0)
	var auto_dog := Vector2(640.0, -1480.0)
	var auto_hit := false
	for frame in range(400):
		var dt := 0.016667
		auto_human.y -= 85.0 * dt
		auto_dog.y -= 85.0 * dt
		var out_auto: Dictionary = sim_lt.tick(dt, auto_dog, Vector2(0.0, -85.0), auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
	_check(not auto_hit, "autowalk completes crossing without tourist bump hazard")
	_check(sim_lt.triggered, "autowalk triggered tourist crossing")
	# The autowalk passes within the tourist's reach, so the miss is a real save.
	_check(sim_lt.dodge_awarded, "autowalk near miss earns the maze dodge")

	# 16. Integration with main.gd
	_check(m.has_method("_tick_lost_tourist"), "main has _tick_lost_tourist method")

	m.free()

	print("test_horta_tourist: %d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		quit(0)
	else:
		quit(1)
