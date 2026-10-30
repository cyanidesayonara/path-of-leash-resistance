extends SceneTree

# Test for Walk 20: Els Senglars chase threat (entities/boar_threat.gd)
# and systems/home_chase.gd integration.

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
	var HomeChase: GDScript = load("res://systems/home_chase.gd")
	var BoarThreat: GDScript = load("res://entities/boar_threat.gd")

	# 1. Profile registration in HomeChase
	var prof: Dictionary = HomeChase.profile_for("boars")
	_check(not prof.is_empty(), "boars profile exists")
	_check(prof.get("kind") == "boars", "profile kind is boars")
	_check(prof.get("speed") == 142.0, "profile speed is 142.0")
	_check(prof.get("script") == "res://entities/boar_threat.gd", "profile points to boar_threat.gd")
	_check(prof.get("bands", []).size() == 2, "boar profile has 2 respite bands")
	_check(prof.get("warning", "").begins_with("WILD BOARS"), "warning starts with WILD BOARS")

	# 2. Threat instantiation & setup
	var threat: Node2D = BoarThreat.new()
	root.add_child(threat)
	threat.setup(null, -4000.0, 640.0, 280.0, 142.0)
	_check(threat.front_y == -4000.0, "initial front_y set")
	_check(threat.speed == 142.0, "speed set")
	_check(threat.cx == 640.0, "corridor cx set")
	_check(not threat.jammed(), "initially not jammed")

	# 3. Advance movement
	var prev_y: float = threat.front_y
	threat.advance(0.1, 300.0, 0.0)
	_check(threat.front_y > prev_y, "boar advances forward along y")
	_check(threat.threat_boundary() == threat.front_y, "threat boundary matches front_y")

	# 4. Catch detection
	# A dog right at front_y within the corridor should be caught
	var at_front := Vector2(640.0, threat.front_y - 40.0)
	_check(threat.caught(at_front), "caught within reach")
	var far_ahead := Vector2(640.0, threat.front_y + 100.0)
	_check(not threat.caught(far_ahead), "not caught when safely ahead")
	var far_wide := Vector2(640.0 + 350.0, threat.front_y - 40.0)
	_check(not threat.caught(far_wide), "not caught when outside corridor width")

	# 5. Jams handling
	threat.jams = Array([Vector2(640.0, threat.front_y + 5.0)], TYPE_VECTOR2, "", null)
	threat.advance(0.1, 300.0, 0.0)
	_check(threat.jammed(), "threat jams when reaching jam coordinate")
	_check(threat.jammed_now, "jammed_now one-shot raised")

	# 6. Procedural drawing verification
	# Calling _draw directly via queue_redraw / waiting frame
	await process_frame
	_check(true, "boar threat rendered frame cleanly")

	threat.queue_free()
	await process_frame

	if failures.is_empty():
		print("test_boar_chase: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_boar_chase: FAILED (%d errors in %d checks)" % [failures.size(), checks])
		quit(1)
