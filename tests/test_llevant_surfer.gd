extends SceneTree

const Surfer := preload("res://systems/surfer.gd")

# Regression test for Platja de Llevant beach surfer live event (Walk 24).
# Tests the 0.8s warning telegraph ("Agafo l'onada!"), westbound run carrying
# the longboard across the esplanade, dropped polo snatch trick, distracted
# human bump hazard, dog boop trick, surfer bark trick, surf dodge save,
# autowalk safety, and leak-free cleanup.

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
	game.level_id = "llevant"

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.surfer != null, "surfer instantiated for llevant walk")
	var sf: Surfer = m.surfer

	# 1. Initial idle state
	_check(sf.state == Surfer.State.IDLE, "starts in IDLE state")
	_check(not sf.triggered, "starts untriggered")
	_check(sf.pos == Surfer.START_POS, "positioned at START_POS")

	# 2. Distant approach does not trigger
	var far_dog := Vector2(670.0, -1820.0)
	var far_human := Vector2(670.0, -1800.0)
	var out1: Dictionary = sf.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(not bool(out1["warn"]), "does not trigger when far south")
	_check(sf.state == Surfer.State.IDLE, "remains IDLE when far south")

	# 3. Crossing trigger line triggers 0.8s warning telegraph
	var near_dog := Vector2(670.0, -1940.0)
	var near_human := Vector2(670.0, -1910.0)
	var out2: Dictionary = sf.tick(0.016, near_dog, Vector2.ZERO, near_human)
	_check(bool(out2["warn"]), "triggers 0.8s warning telegraph")
	_check(sf.state == Surfer.State.TELEGRAPH, "transitions to TELEGRAPH state")
	_check(sf.timer <= Surfer.WARN_DURATION and sf.timer > 0.7,
		"timer initialized to 0.8s warning (%.2f)" % sf.timer)

	# 4. Remains in TELEGRAPH during warning window
	var out3: Dictionary = sf.tick(0.4, near_dog, Vector2.ZERO, near_human)
	_check(sf.state == Surfer.State.TELEGRAPH, "remains in TELEGRAPH at t=0.4s")
	_check(sf.pos == Surfer.START_POS, "surfer remains at start during telegraph")

	# 5. Warning completes -> transitions to RUNNING
	var out4: Dictionary = sf.tick(0.45, near_dog, Vector2.ZERO, near_human)
	_check(sf.state == Surfer.State.RUNNING, "transitions to RUNNING after 0.8s")
	sf.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(sf.pos.x < Surfer.START_POS.x, "begins moving west (%.1f)" % sf.pos.x)

	# 6. Moves westward across esplanade at ~185 px/s
	var x_before: float = sf.pos.x
	sf.tick(0.5, near_dog, Vector2.ZERO, near_human)
	_check(sf.pos.x < x_before - 70.0, "progresses west along crossing path (%.1f)" % sf.pos.x)

	# 7. Drops polo ice pop when crossing past middle esplanade (x <= 610.0)
	var safety_counter := 0
	while sf.pos.x > Surfer.POLO_DROP_X and safety_counter < 100:
		safety_counter += 1
		sf.tick(0.05, near_dog, Vector2.ZERO, near_human)
	_check(sf.polo_dropped, "drops polo past center esplanade")
	_check(sf.polo_pos.distance_to(sf.pos) < 30.0, "polo spawns near surfer")

	# Advance surfer forward so dog can snatch treat without booping surfer
	sf.tick(0.25, far_dog, Vector2.ZERO, near_human)
	_check(sf.pos.distance_to(sf.polo_pos) > Surfer.BOOP_RADIUS + 10.0,
		"surfer moves safely ahead of dropped polo")

	# 8. Dog snatches dropped polo
	_check(not sf.booped, "not booped before snatch")
	var out_snatch: Dictionary = sf.tick(0.05, sf.polo_pos, Vector2.ZERO, near_human)
	_check(bool(out_snatch["snatch"]), "dog snatches polo when close")
	_check(sf.polo_snatched, "polo marked as snatched")
	_check(not sf.booped, "snatching polo does not boop distant surfer")

	# 9. Bark reaction while running
	_check(not sf.bark_reacted, "bark not reacted yet")
	var bark_ok: bool = sf.on_bark(sf.pos + Vector2(40.0, 0.0))
	_check(bark_ok, "on_bark returns true within radius")
	_check(sf.bark_reacted, "bark_reacted set to true")
	var bark_repeat: bool = sf.on_bark(sf.pos + Vector2(20.0, 0.0))
	_check(not bark_repeat, "on_bark one-shot per encounter")

	# 10. Boop trick: dog catches up and boops surfer directly
	_check(not sf.booped, "not booped yet")
	var out_boop: Dictionary = sf.tick(0.016, sf.pos + Vector2(10.0, 0.0), Vector2.ZERO, near_human)
	_check(bool(out_boop["boop"]), "boop detected within radius")
	_check(sf.booped, "booped marked true")

	# 11. Human collision hazard (test on fresh instance)
	var hazard_sf := Surfer.new()
	hazard_sf.state = Surfer.State.RUNNING
	hazard_sf.pos = Vector2(670.0, -2140.0)
	var hit_human := Vector2(670.0, -2145.0)
	var out_hit: Dictionary = hazard_sf.tick(0.016, Vector2.ZERO, Vector2.ZERO, hit_human)
	_check(bool(out_hit["bump"]), "distracted human collision triggers bump hazard")
	_check(hazard_sf.human_hit, "human_hit flag set")

	# 12. Safe dodge past crossing awards save
	var dodge_sf := Surfer.new()
	dodge_sf.triggered = true
	dodge_sf.state = Surfer.State.RUNNING
	dodge_sf.pos = Vector2(450.0, -2140.0)
	var dodge_human := Vector2(670.0, -2100.0)
	var out_dodge_pre: Dictionary = dodge_sf.tick(0.016, Vector2.ZERO, Vector2.ZERO, dodge_human)
	_check(not bool(out_dodge_pre["dodge"]), "dodge not awarded while human is south of crossing")
	var safe_human := Vector2(670.0, -2170.0)
	var out_dodge: Dictionary = dodge_sf.tick(0.016, Vector2.ZERO, Vector2.ZERO, safe_human)
	_check(bool(out_dodge["dodge"]), "safely navigating crossing awards surf dodge save")
	_check(dodge_sf.dodge_awarded, "dodge_awarded set")

	# 13. Runs to END_POS and settles
	safety_counter = 0
	while sf.state == Surfer.State.RUNNING and safety_counter < 100:
		safety_counter += 1
		sf.tick(0.1, Vector2.ZERO, Vector2.ZERO, near_human)
	_check(sf.state == Surfer.State.SETTLED, "settles at beach sand")
	_check(sf.pos.x <= Surfer.END_POS.x + 1.0, "settles at END_POS")

	# 14. Return walk does not re-trigger
	var return_sf := Surfer.new()
	return_sf.triggered = true
	return_sf.state = Surfer.State.SETTLED
	var return_human := Vector2(670.0, -2000.0)
	var out_return: Dictionary = return_sf.tick(0.016, Vector2.ZERO, Vector2.ZERO, return_human)
	_check(not bool(out_return["warn"]), "does not re-trigger on return leg")

	# 15. Autowalk clearance: simulated uninterrupted autowalk traversal
	var sim_sf := Surfer.new()
	var auto_human := Vector2(670.0, -1850.0)
	var auto_dog := Vector2(670.0, -1880.0)
	var auto_hit := false
	for frame in range(400):
		var dt := 0.016667
		auto_human.y -= 85.0 * dt
		auto_dog.y -= 85.0 * dt
		var out_auto: Dictionary = sim_sf.tick(dt, auto_dog, Vector2(0.0, -85.0), auto_human)
		if bool(out_auto["bump"]):
			auto_hit = true
			break
	_check(not auto_hit, "autowalk completes crossing without surfer bump hazard")
	_check(sim_sf.triggered, "autowalk triggered surfer crossing")
	_check(sim_sf.dodge_awarded, "autowalk earned surf dodge save cleanly")

	# 16. Integration with main.gd
	_check(m.has_method("_tick_surfer"), "main has _tick_surfer method")

	m.free()

	print("test_llevant_surfer: %d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		quit(0)
	else:
		quit(1)
