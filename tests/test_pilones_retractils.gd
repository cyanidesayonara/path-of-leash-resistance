extends SceneTree

# Tests for systems/pilones_retractils.gd (retractable lit bollards in El Gòtic):
# - Two pedestrian-zone bollard gates created on oldtown, none on other walks
# - 0.8 s WARN_DOWN / WARN_UP telegraph before sinking and rising
# - Collision shape disables when sunk (lift <= 0.45) and re-enables when raised,
#   nudging any body standing on the plate clear
# - Delivery van advances through the gate during DOWN
# - Barking near a raised bollard trips WARN_DOWN and pays once

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(15.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var PR: GDScript = load("res://systems/pilones_retractils.gd")

	game.level_id = "oldtown"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)

	PR.tick(m, 0.05)
	_check(m.gotic_pilones.size() == 2, "two retractable bollards on oldtown")
	var g0: Dictionary = m.gotic_pilones[0]
	var cs0: CollisionShape2D = g0["shape"]
	_check(int(g0["state"]) == PR.State.UP and not cs0.disabled, "bollard starts UP with collision active")

	# Bark near raised bollard trips WARN_DOWN and awards bones once
	var bones0: int = m.bones
	var hit: bool = PR.on_bark(m, g0["pos"] + Vector2(20.0, 0.0))
	_check(hit, "bark near raised bollard triggers sensor")
	_check(int(g0["state"]) == PR.State.WARN_DOWN and is_equal_approx(float(g0["t"]), PR.WARN_SECS), "enters 0.8 s WARN_DOWN telegraph")
	_check(m.bones == bones0 + 2, "awards +2 bones on first sensor bark")

	# Step through WARN_DOWN -> DOWN -> van moves -> collision disables
	var van0: float = float(g0["van_off"])
	for _i in range(25):
		PR.tick(m, 0.05)
	_check(int(g0["state"]) == PR.State.DOWN, "bollard drops to DOWN after 0.8 s warn")
	_check(float(g0["lift"]) < 0.2 and cs0.disabled, "collision disabled when sunk")
	_check(not is_equal_approx(float(g0["van_off"]), van0), "delivery van advances through lowered gate")

	# Place dog on plate and advance to UP -> nudged clear
	m.dog.global_position = g0["pos"]
	for _i in range(90):
		PR.tick(m, 0.05)
	_check(int(g0["state"]) == PR.State.UP and not cs0.disabled, "bollard rises back to UP")
	_check(m.dog.global_position.distance_to(g0["pos"]) >= PR.BOLLARD_R + 13.0, "dog nudged clear when bollard rises")

	# Does not pay twice on same bollard
	var bones1: int = m.bones
	var hit2: bool = PR.on_bark(m, g0["pos"])
	_check(hit2 and m.bones == bones1, "second bark triggers sensor without paying twice")

	m.queue_free()
	await physics_frame

	if failures.is_empty():
		print("test_pilones_retractils: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_pilones_retractils: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
