extends SceneTree

# Tests for systems/cam_tricks.gd:
# - Arena zoom-out eases toward ARENA_ZOOM when a boss fight is active, and restores to 1.0 when over
# - Enrage triggers a brief dutch tilt that returns cleanly to base rotation (no continuous tilt)
# - Letterbox bars appear while hush_banner is active on boss reveal and hide afterwards
# - Near-miss saves_done / close_calls trigger _slowmo()

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
	var CamTricks: GDScript = load("res://systems/cam_tricks.gd")

	# 1. Boss arena zoom, enrage dutch tilt, and reveal letterbox on raval
	game.level_id = "raval"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)

	var zoom0: float = m.cam.zoom.x
	_check(m.letterbox_top != null and m.letterbox_bot != null, "letterbox bars built on HUD")
	_check(not m.letterbox_top.visible, "letterbox hidden before boss reveal")

	# Reveal card triggers letterbox
	m.boss_gat.state = m.boss_gat.State.AWAKEN
	m.boss_gat.hp = 100.0
	m.boss_gat.card_t = m.boss_gat.CARD_FROM + 0.1
	for _i in range(25):
		CamTricks.tick(m, 0.05)
	_check(m.letterbox_top.visible and m.letterbox_top.size.y > 20.0, "letterbox opens during boss reveal")
	_check(m.cam.zoom.x < zoom0 * 0.94, "camera zooms out in active boss arena (%.3f < %.3f)" % [m.cam.zoom.x, zoom0])
	_check(is_zero_approx(m.cam.rotation), "no dutch tilt before enrage")

	# End reveal -> letterbox slides shut
	m.boss_gat.card_t = -1.0
	for _i in range(30):
		CamTricks.tick(m, 0.05)
	_check(not m.letterbox_top.visible, "letterbox hides after boss reveal")

	# Enrage triggers brief dutch tilt, then returns to 0.0
	m.boss_gat.enraged = true
	CamTricks.tick(m, 0.02)
	_check(m.cam_tilt_t > 0.0, "enrage starts brief dutch tilt timer")
	CamTricks.tick(m, 0.25)
	_check(absf(m.cam.rotation) > 0.01, "dutch tilt angles camera mid-pulse")
	for _i in range(20):
		CamTricks.tick(m, 0.05)
	_check(m.cam_tilt_t == 0.0 and is_zero_approx(m.cam.rotation), "dutch tilt returns cleanly to zero (no continuous tilt)")

	# Framing: wherever he is round her, she and he are in the picture, and one
	# out of reach changes nothing
	var view := Vector2(1280.0, 720.0)
	for off: Vector2 in [Vector2(0, -330), Vector2(0, 330), Vector2(300, 0), Vector2(-250, 250), Vector2(40, -60)]:
		var dog := Vector2(640.0, -1000.0)
		var human := dog + Vector2(60.0, 170.0)
		var foe: Array[Vector2] = [dog + off]
		var fr: Vector2 = CamTricks.fight_frame(dog, human, foe, view, 1.28)
		var z := 1.28 * fr.y
		var mid := (dog.y + human.y) * 0.5 - 60.0 + fr.x
		for p: Vector2 in [dog, human]:
			var sy := (p.y - mid) * z + 360.0
			_check(sy > 60.0 and sy < 700.0, "the pair stays in view, boss at %s (%.0f)" % [off, sy])
		var by := (foe[0].y - mid) * z + 360.0
		_check(by > 40.0 and by < 690.0, "so does the boss at %s (%.0f)" % [off, by])
	_check(CamTricks.fight_frame(Vector2.ZERO, Vector2(0, 150), [Vector2(0, -1200)] as Array[Vector2], view, 1.28).x == 0.0, "a boss far off is let go")
	var jolt := 0.0
	for i in range(30):
		jolt = maxf(jolt, (CamTricks.shake(float(i + 1) / 60.0, 1.0) - CamTricks.shake(float(i) / 60.0, 1.0)).length())
	_check(jolt < 22.0, "the shake is a shudder, not jolts (%.1f px a frame at most)" % jolt)

	# Defeated -> zoom restores to 1.0
	m.boss_gat.hp = 0.0
	m.boss_gat.state = m.boss_gat.State.PURR
	for _i in range(40):
		CamTricks.tick(m, 0.05)
	_check(absf(m.cam.zoom.x - zoom0) < 0.002, "camera zoom restores after boss defeat (%.4f vs %.4f)" % [m.cam.zoom.x, zoom0])

	# 2. Near-miss save triggers slowmo
	m.started = true
	m.frozen = false
	m.auto_walk = false
	Engine.time_scale = 1.0
	m.saves_done += 1
	CamTricks.tick(m, 0.016)
	_check(Engine.time_scale < 0.99, "near-miss save triggers slowmo (time_scale=%.2f)" % Engine.time_scale)
	Engine.time_scale = 1.0

	m.queue_free()
	await physics_frame

	if failures.is_empty():
		print("test_cam_tricks: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_cam_tricks: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
