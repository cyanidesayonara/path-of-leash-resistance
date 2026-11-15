extends SceneTree

# The plaça's pigeon game (systems/pigeon_game.gd), played in Plaça Reial's
# off-leash square: a flock lands; a bark close among them bursts the whole
# flock for the most; running at them flushes them one by one, for nothing;
# three flocks and it is over; a park has no pigeon game, the autowalk none.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _open(lvl: String) -> Node2D:
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 300.0)
	m.human.global_position = Vector2(640.0, m.GATE_Y - 60.0)
	m.leash.resnap()
	m._enter_freedom()
	await physics_frame
	return m


func _land(m: Node2D, pg) -> void:
	# park her far off so the flock lands and stays down
	m.dog.global_position = Vector2(100.0, m.GATE_Y - 60.0)
	for i in range(60 * 4):
		pg.tick(m, 1.0 / 60.0)
		if pg.active():
			return


func _down(pg) -> int:
	var n := 0
	for p in pg.flock:
		if is_instance_valid(p) and not p.flying:
			n += 1
	return n


func _run() -> void:
	var m: Node2D = await _open("reial")
	_check(m.freedom_kind == "placa", "Plaça Reial ends in a plaça")
	var pg = m.pigeon_game
	_check(pg != null, "a plaça has the pigeon game")
	if pg == null:
		_finish()
		return
	_land(m, pg)
	_check(pg.active() and _down(pg) == pg.FLOCK_N, "a flock of %d lands" % pg.FLOCK_N)
	# creep in close, stop, bark: the whole flock, double, and the bonus
	m.dog.turbo_active = false
	m.dog.global_position = pg.at + Vector2(60.0, 0.0)
	var b0: int = m.bones
	m.on_bark(m.dog.global_position)
	var pay: int = m.bones - b0
	_check(pay == pg.FLOCK_N * 2 + pg.FULL_BONUS, "a close bark bursts the whole flock for the most (%d)" % pay)
	_check(_down(pg) == 0, "the burst puts every pigeon up")
	pg.tick(m, 1.0 / 60.0)
	_check(pg.round == 1 and not pg.active(), "the flock gone, the round is over")
	# the next flock: run right up to it and the near ones go up before any bark
	_land(m, pg)
	_check(pg.active() and pg.round == 1, "a second flock lands somewhere new")
	m.dog.global_position = pg.at + Vector2(pg.SPREAD + 6.0, 0.0)
	for i in range(10):
		pg.tick(m, 1.0 / 60.0)
		await physics_frame
	_check(_down(pg) < pg.FLOCK_N and _down(pg) > 0, "running up to them flushes the near ones (%d still down)" % _down(pg))
	_check(pg.WARY_SPRINT > pg.WARY_WALK * 2.0, "at a sprint they see her from much further off")
	# a bark from far off pays only for the ones still down, single
	var still := _down(pg)
	m.dog.global_position = pg.at + Vector2(pg.BARK_REACH - pg.SPREAD - 12.0, 0.0)
	b0 = m.bones
	m.on_bark(m.dog.global_position)
	_check(m.bones - b0 == still, "a far bark pays one a pigeon still down (%d of %d)" % [m.bones - b0, still])
	pg.tick(m, 1.0 / 60.0)
	# a third, and it is done
	_land(m, pg)
	m.dog.global_position = pg.at
	m.on_bark(m.dog.global_position)
	pg.tick(m, 1.0 / 60.0)
	_check(pg.done, "three flocks and the game is over")
	m.queue_free()
	await process_frame
	var mp: Node2D = await _open("park")
	_check(mp.pigeon_game == null, "a dog park has no pigeon game")
	mp.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	print("%d checks, %d failures" % [checks, failures.size()])
	print("test_pigeon_game: " + ("OK" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
