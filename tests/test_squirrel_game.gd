extends SceneTree

# The woodland clearing's squirrel game (systems/squirrel_game.gd), played in
# El Bosc's clearing: a squirrel forages; come near and it bolts up a trunk,
# never caught; a bark from under the tree pays most the first time; it
# rustles before it leaps (the telegraph) and a bark at the next tree before
# it settles grows a streak; after its leaps it goes, three squirrels and it
# is over. A plaça has no squirrel game, the autowalk none.
#
# Reached through the live object (m.squirrel_game): the script names autoloads.

const DT := 1.0 / 60.0

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
	root.get_node("Sfx").muted = true
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


# tick until it is in `state` (an int of its enum), up to `secs`
func _until(m: Node2D, sg, state: int, secs: float) -> bool:
	for i in range(int(secs * 60.0)):
		if int(sg.state) == state:
			return true
		sg.tick(m, DT)
	return int(sg.state) == state


func _run() -> void:
	var m: Node2D = await _open("trail")
	_check(m.freedom_kind == "clearing", "El Bosc ends in a clearing")
	var sg = m.squirrel_game
	_check(sg != null, "a clearing has the squirrel game")
	if sg == null:
		_finish()
		return
	var S = sg.S
	_check(sg._trees(m).size() >= 6, "the clearing has trees to run up (%d)" % sg._trees(m).size())

	# it comes down to forage, away from her
	m.dog.global_position = Vector2(110.0, m.GATE_Y - 80.0)
	_check(_until(m, sg, S.FORAGE, 4.0), "a squirrel comes down to forage")
	_check(sg.pos.distance_to(m.dog.global_position) > sg.ALERT, "it forages out of her reach")

	# she runs at it: it bolts for a trunk and is never caught on the way
	var closest := 1e9
	m.dog.global_position = sg.pos + Vector2(sg.ALERT - 20.0, 0.0)
	for i in range(60 * 5):
		if int(sg.state) == S.CLIMB or int(sg.state) == S.TREED:
			break
		# chase it at a dog's sprint, straight at it
		var d: Vector2 = sg.pos - m.dog.global_position
		if d.length() > 1.0:
			m.dog.global_position += d.normalized() * minf(d.length(), 330.0 * DT)
		if int(sg.state) == S.BOLT:
			closest = minf(closest, m.dog.global_position.distance_to(sg.pos))
		sg.tick(m, DT)
	_check(int(sg.state) == S.CLIMB or int(sg.state) == S.TREED, "it bolts up a tree")
	_check(closest >= sg.JINK * 0.5, "she never catches it on the way (closest %.0f px)" % closest)
	_check(_until(m, sg, S.TREED, 1.0), "it climbs into the crown")

	# a bark from under the tree: the first pays most, the next less
	m.dog.global_position = sg.tree + Vector2(40.0, 30.0)
	var b0: int = m.bones
	m.on_bark(m.dog.global_position)
	_check(m.bones - b0 == sg.PAY_FIRST, "the first bark up a tree pays %d" % sg.PAY_FIRST)
	var b1: int = m.bones
	m.on_bark(m.dog.global_position)
	_check(m.bones - b1 == sg.PAY_MORE, "the next bark at it pays %d" % sg.PAY_MORE)
	# a bark from across the clearing does nothing
	var b2: int = m.bones
	m.on_bark(sg.tree + Vector2(400.0, 0.0))
	_check(m.bones == b2, "a bark from far off does not count")

	# it rustles first (the telegraph), for LEAP_WARN, then leaps
	var from: Vector2 = sg.tree
	_check(_until(m, sg, S.RUSTLE, sg.TREED_S + 1.0), "it rustles its crown before it leaps")
	_check(sg.tree == from and sg.next_tree.x < INF and sg.next_tree != from,
		"during rustle it stays in this tree and marks the next")
	var rustle_t := 0.0
	while int(sg.state) == S.RUSTLE and rustle_t < 3.0:
		sg.tick(m, DT)
		rustle_t += DT
	_check(absf(rustle_t - sg.LEAP_WARN) < 0.1, "the rustle lasts LEAP_WARN (%.2f s)" % rustle_t)
	_check(_until(m, sg, S.TREED, 2.0), "it lands in the next tree")
	_check(sg.tree.distance_to(from) > 60.0, "a different tree")
	# barked at in the new tree before it settles: the streak pays more
	m.dog.global_position = sg.tree + Vector2(30.0, 40.0)
	var b3: int = m.bones
	m.on_bark(m.dog.global_position)
	_check(m.bones - b3 == sg.PAY_FIRST + sg.STREAK_PAY, "after it to the next tree: the streak pays (%d)" % (m.bones - b3))
	_check(sg.streak == 1, "the streak counts")

	# its leaps done, it goes, and after three squirrels the game is over
	for r in range(10):
		if sg.done:
			break
		m.dog.global_position = Vector2(110.0, m.GATE_Y - 80.0)
		for i in range(60 * 30):
			if sg.done:
				break
			if int(sg.state) == S.FORAGE:
				m.dog.global_position = sg.pos + Vector2(60.0, 0.0)
			sg.tick(m, DT)
	_check(sg.done and sg.round == sg.ROUNDS, "three squirrels and it is over")
	_check(sg.treed_total >= 2, "trees she barked it up are counted (%d)" % sg.treed_total)

	# a plaça has none
	m.queue_free()
	await physics_frame
	var p: Node2D = await _open("reial")
	_check(p.squirrel_game == null, "a plaça has no squirrel game")
	p.queue_free()
	_finish()


func _finish() -> void:
	print("test_squirrel_game: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
