extends SceneTree

# El Gat's last stand is won with the real rope, not hand-set touch times
# (test_boss_gat): the dog circling his plinth with your human held at HOLD_Y
# winds the leash onto three legs within LEG_MEMORY, either way round, close
# in or wide. A rope that slipped off his legs would leave the walk unwinnable,
# as your human never passes him.

const CASES := [[160.0, 1.0, 140.0], [240.0, -1.0, 110.0], [320.0, 1.0, 85.0]]
const DEADLINE := 6.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(60.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.persist = false
	game._reset_persisted_state()
	root.get_node("Sfx").muted = true
	var BG: GDScript = load("res://systems/boss_gat.gd")
	for cs: Array in CASES:
		var spd: float = cs[0]
		var dirn: float = cs[1]
		var rad: float = cs[2]
		game.level_id = "raval"
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		for k in range(3):
			await physics_frame
		m._skip_title()
		m.auto_walk = false
		var gat = m.boss_gat
		gat.pos = BG.PEDESTAL_POS
		gat.update_leg_positions()
		gat.hp = 0.0
		gat.transition_to(BG.State.ROAR)
		var c: Vector2 = BG.PEDESTAL_POS
		m.human.global_position = Vector2(640.0, BG.HOLD_Y + 10.0)
		m.dog.global_position = c + Vector2(0.0, rad)
		m.leash.resnap()
		var ang := PI * 0.5
		var t := 0.0
		while t < DEADLINE and gat.state == BG.State.ROAR:
			# his swats are dodged elsewhere; here she only runs her circle
			gat.ls_swat_cd = 99.0
			ang += dirn * spd / rad / 60.0
			m.dog.global_position = c + Vector2(cos(ang), sin(ang)) * rad
			m.dog.velocity = Vector2(-sin(ang), cos(ang)) * spd * dirn
			await physics_frame
			t += 1.0 / 60.0
		_check(gat.state == BG.State.WRAPPED,
			"circling at %d px/s, radius %d, %s ties him (state %s after %.1fs)" % [
				spd, rad, "clockwise" if dirn > 0.0 else "anticlockwise", BG.State.keys()[gat.state], t])
		m.queue_free()
		await process_frame

	if failures.is_empty():
		print("test_boss_tie_rope: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_boss_tie_rope: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
