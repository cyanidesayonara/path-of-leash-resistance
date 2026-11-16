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

	# Defeated -> zoom restores to 1.0
	m.boss_gat.hp = 0.0
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
