extends SceneTree

# The kid's dare on a real walk (entities/challenger.gd, systems/challenge.gd,
# main.start_challenge): it is offered when she comes near, and the clock
# waits for the offer; a lost dare is offered again, once she is back at the
# bench or after RETRY_WAIT while she is still close, at most RETRIES times
# and for a smaller reward; a won dare is never offered again; the autowalk
# bot never gets a second go. The giver and the dare are stepped by hand so
# nothing else on the walk moves.

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []
var m: Node2D
var g: Node2D


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _step(seconds: float) -> void:
	for i in range(int(round(seconds / DT))):
		g._physics_process(DT)
		m.challenge.tick(DT)


func _near(d: float) -> void:
	m.dog.global_position = g.global_position + Vector2(-d, 0.0)


func _fresh() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.set_process(false)
	m.set_physics_process(false)
	m.started = true
	m.frozen = false
	m.phase = "out"
	g = get_nodes_in_group("challengers")[0]
	g.set_physics_process(false)


func _lose() -> void:
	_step(m.challenge.OFFER_S + 0.1)
	m.challenge.timer = 0.01
	_step(DT * 2.0)


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = "street"
	await _fresh()

	_near(600.0)
	_step(1.0)
	_check(m.challenge.phase == "", "no dare while she is far from the bench")
	_near(100.0)
	_step(DT)
	_check(m.challenge.phase == "offer", "coming near the bench offers the dare")
	_check(m.challenge.reward == m.dare_reward(5, false) and m.dare_reward(5, false) == 35,
		"the first go pays 35 (%d)" % m.challenge.reward)
	m.challenge.add_trick()
	_check(m.challenge.count == 0, "a trick while the dare is being read does not count")
	_step(m.challenge.OFFER_S)
	_check(m.challenge.phase == "live" and m.challenge.active, "the clock starts after the offer")
	m.challenge.timer = 0.01
	_step(DT * 2.0)
	_check(m.challenge.phase == "end" and not m.challenge.succeeded and g.result == "lose", "running out of time loses")
	_step(m.challenge.END_S + 0.1)
	_check(m.challenge.phase == "", "the result card goes")

	# after RETRY_WAIT, still close by: the same dare again, for less
	_near(300.0)
	# the wait starts once the result card has gone
	_step(g.RETRY_WAIT - 0.5)
	_check(m.challenge.phase == "", "no retry before RETRY_WAIT")
	_step(1.0)
	_check(m.challenge.phase == "offer" and m.challenge.retry, "a retry is offered while she is still close")
	_check(m.challenge.reward == m.dare_reward(5, true) and m.challenge.reward == 25, "a retry pays 25 (%d)" % m.challenge.reward)
	_lose()

	# away from the bench and back: the second (and last) retry
	_near(800.0)
	_step(g.RETRY_WAIT + 1.0)
	_check(m.challenge.phase == "", "no retry while she is away from the bench")
	_near(100.0)
	_step(DT * 2.0)
	_check(m.challenge.phase == "offer" and g.retries == g.RETRIES, "coming back to the bench offers the last retry")
	_lose()
	_step(g.RETRY_WAIT * 3.0)
	_near(800.0)
	_step(1.0)
	_near(100.0)
	_step(1.0)
	_check(m.challenge.phase == "" and not g.has_another_go(), "no more goes once the retries are used")

	# a won dare is done, and pays
	m.queue_free()
	await process_frame
	await _fresh()
	_near(100.0)
	_step(DT)
	_step(m.challenge.OFFER_S + 0.1)
	var before: int = m.bones
	for i in range(5):
		m.challenge.add_trick()
	_check(m.challenge.succeeded and m.bones == before + 35, "winning the first go pays 35")
	_step(g.RETRY_WAIT * 2.0)
	_check(m.challenge.phase == "", "a won dare is never offered again")

	# the autowalk bot gets one go only
	m.queue_free()
	await process_frame
	await _fresh()
	m.auto_walk = true
	_near(100.0)
	_step(DT)
	_lose()
	_step(g.RETRY_WAIT * 2.0)
	_check(m.challenge.phase == "" and g.retries == 0, "the autowalk is never offered a retry")

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("DARE RETRY OK")
		quit(0)
	else:
		print("DARE RETRY FAIL")
		quit(1)
