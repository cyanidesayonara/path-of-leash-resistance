extends SceneTree

# The dare-giver on a real walk (entities/challenger.gd, systems/challenge.gd,
# main.start_challenge). It is offered when she comes near and waits for a
# bark to take it; walking off lapses the offer until she comes back. Every giver has the same ladder of three dares and one
# rule for the next go: lose, and the same dare is offered again; win, and
# the next, harder one. Either way it comes once she is back near the giver
# or after RETRY_WAIT while she is still close, as often as she likes, until
# the last dare is won. A dare pays the same however many goes it took, and a
# harder one pays more. The autowalk bot gets the first dare only. Each walk
# has its own giver (challenger.WHO), and on Passeig Marítim it is the bronze
# monkey on the Pont del Petroli's steps. The giver and the dare are stepped
# by hand so nothing else on the walk moves.

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


# take the dare on offer as a player does, with a bark, and get set
func _take() -> void:
	m.on_bark(m.dog.global_position)
	_step(m.challenge.READY_S + 0.1)


func _lose() -> void:
	_take()
	m.challenge.timer = 0.01
	_step(DT * 2.0)
	_step(m.challenge.END_S + 0.1)


func _win() -> void:
	_take()
	for i in range(int(m.challenge.target)):
		m.challenge.add_trick()
	_step(m.challenge.END_S + 0.1)


# away and back again, which offers whatever is next
func _come_back() -> void:
	_near(g.notice_r() + 300.0)
	_step(0.5)
	_near(100.0)
	_step(DT * 2.0)


func _check_givers(game: Node) -> void:
	m.queue_free()
	await process_frame
	var script: GDScript = load("res://entities/challenger.gd")
	for level: String in game.LEVELS:
		game.level_id = level
		await _fresh()
		var want: String = script.giver_for(level)
		_check(g.who == want, "%s: the dare-giver is %s (%s)" % [level, want, g.who])
		var said: Dictionary = g.LINES[g.who]
		for key: String in ["idle", "dare", "won", "lost", "done"]:
			_check(said.has(key), "%s: %s has a line for %s" % [level, g.who, key])
		# plain words, whoever says them: the numbers in so many words, a harder one after
		# a win, try again after a loss
		_check(String(said["dare"]).contains("%d tricks in %d seconds"),
			"%s: %s says the numbers plainly (%s)" % [level, g.who, said["dare"]])
		_check(String(said["won"]).contains("harder") and String(said["lost"]).contains("try again"),
			"%s: %s says what happens next" % [level, g.who])
		for key: String in said:
			var line := String(said[key])
			_check(line.begins_with("%d") or line[0] == line[0].to_upper(), "%s: %s starts each line with a capital (%s)" % [level, g.who, key])
		if g.who == "monkey":
			_check(g.global_position.distance_to(m.LevelBuild.beach_monkey()) < 0.5,
				"beach: the monkey gives the dare from his block on the pier's steps")
		else:
			m.cam.position.y = g.position.y
			var nearest := INF
			var need := 0.0
			for tree: Dictionary in m.canopy_trees():
				var d: float = g.position.distance_to(tree.p)
				if d < nearest:
					nearest = d
					need = float(tree.r) + 24.0
			_check(nearest >= need, "%s dare giver stays out from under tree crowns (%.1f >= %.1f)" % [
				level, nearest, need])
		m.queue_free()
		await process_frame


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = "park"
	await _fresh()

	_near(600.0)
	_step(1.0)
	_check(m.challenge.phase == "", "no dare while she is far from the giver")
	_near(100.0)
	_step(DT)
	_check(m.challenge.phase == "offer" and not m.challenge.retry, "coming near offers the first dare")
	_check(m.challenge.target == 6 and g.dare_number() == 1 and g.dare_count() == 3, "the first dare is 6 tricks, 1 of 3")
	_check(m.challenge.reward == m.dare_reward(6) and m.dare_reward(6) == 38, "the first dare pays 38 (%d)" % m.challenge.reward)
	m.challenge.add_trick()
	_check(m.challenge.count == 0, "a trick while the dare is on offer does not count")
	_check(g._line().ends_with(g.TAKE) and g._line().contains("6 tricks in 20 seconds"),
		"the giver says the numbers and that a bark takes it (%s)" % g._line())
	var said: Array[String] = load("res://world/speech_bubble.gd").lines(g._line(), g.TAKE)
	_check(said.size() == 2 and said[1] == g.TAKE.strip_edges(),
		"the offer's bubble is two lines, the dare over the bark (%s)" % [said])
	_step(m.challenge.OFFER_S * 3.0)
	_check(m.challenge.phase == "offer" and m.challenge.waiting, "the offer waits for her bark, however long")
	# walking off without barking lets it lapse, and coming back makes it again
	_near(g.NEAR_R + 50.0)
	_step(DT * 2.0)
	_check(m.challenge.phase == "" and g.result == "lapsed", "walking off lapses the offer")
	_near(100.0)
	_step(DT * 2.0)
	_check(m.challenge.phase == "offer" and m.challenge.target == 6 and not m.challenge.retry,
		"coming back makes the same offer again")
	m.on_bark(m.dog.global_position)
	_check(m.challenge.phase == "offer" and not m.challenge.waiting, "a bark takes the dare")
	_check(g._line() == "Get ready...", "taking it, the giver says get ready")
	_check(m._music_cue() == "" and m._music_next() == "dare_" + g.who,
		"the walk's music stops for the count-in, the giver's tune ready")
	var counted: int = m.dare_counts
	_step(m.challenge.READY_S + 0.1)
	_check(m.dare_counts - counted == m.challenge.COUNT_IN, "a three-tick count-in (%d)" % (m.dare_counts - counted))
	_check(m.challenge.phase == "live" and m.challenge.active, "the clock starts after a moment to get set")
	_check(m._music_cue() == "dare_" + g.who, "the giver's tune plays while the clock runs")
	_check(is_equal_approx(m._dare_tempo(), 1.0), "at its own tempo at first")
	m.challenge.timer = m.HURRY_S * 0.5
	_check(m._dare_tempo() > 1.0 and m._dare_tempo() < m.DARE_HURRY, "faster as the clock runs out")
	m.challenge.timer = 0.01
	_step(DT * 2.0)
	_check(m.challenge.phase == "end" and not m.challenge.succeeded and g.result == "lose", "running out of time loses")
	_check(g._line().contains("try again"), "after a loss the giver says to come back and try again")
	_step(m.challenge.END_S + 0.1)
	_check(m.challenge.phase == "", "the result card goes")

	# after RETRY_WAIT, still close by: the same dare again, for the same pay
	_near(300.0)
	_step(g.RETRY_WAIT - 0.5)
	_check(m.challenge.phase == "", "no second go before RETRY_WAIT")
	_step(1.0)
	_check(m.challenge.phase == "offer" and m.challenge.retry and m.challenge.target == 6,
		"a lost dare is offered again while she is still close")
	_check(m.challenge.reward == 38, "the same dare again pays the same (%d)" % m.challenge.reward)
	_lose()

	# lost as often as she likes: away and back, the same dare every time
	for i in range(3):
		_near(800.0)
		_step(g.RETRY_WAIT + 1.0)
		_check(m.challenge.phase == "", "no dare while she is away (%d)" % i)
		_near(100.0)
		_step(DT * 2.0)
		_check(m.challenge.phase == "offer" and m.challenge.target == 6, "back at the giver, the same dare again (%d)" % i)
		_lose()

	# won: the next one is harder and pays more
	_come_back()
	_check(m.challenge.target == 6, "still the first dare until it is won")
	var before: int = m.bones
	_win()
	_check(m.bones == before + 38 and g.rung == 1, "winning the first dare pays 38 and moves up the ladder")
	_check(g._line().contains("harder"), "after a win the giver says there is a harder one")
	_come_back()
	_check(m.challenge.phase == "offer" and not m.challenge.retry and m.challenge.target == 8 and g.dare_number() == 2,
		"coming back after a win offers dare 2 of 3: 7 tricks")
	_check(m.challenge.reward == m.dare_reward(8) and m.challenge.reward > 38, "a harder dare pays more (%d)" % m.challenge.reward)
	_lose()
	_come_back()
	_check(m.challenge.target == 8 and m.challenge.retry, "losing dare 2 offers dare 2 again")
	_win()
	_step(g.RETRY_WAIT + 1.0)
	_check(m.challenge.phase == "offer" and m.challenge.target == 10 and g.dare_number() == 3,
		"staying close after a win offers dare 3 of 3: 10 tricks")
	_win()
	_check(not g.has_another_go() and g._line() == String(g.LINES[g.who]["done"]), "the last dare won, the giver is done")
	_come_back()
	_step(g.RETRY_WAIT * 2.0)
	_check(m.challenge.phase == "", "no dare once the ladder is climbed")

	# the autowalk bot gets the first dare only
	m.queue_free()
	await process_frame
	await _fresh()
	m.auto_walk = true
	_near(100.0)
	_step(DT)
	_step(m.challenge.OFFER_S + 0.1)
	_check(m.challenge.phase == "live", "the autowalk takes the first dare by itself")
	m.challenge.timer = 0.01
	_step(DT * 2.0)
	_step(m.challenge.END_S + 0.1)
	_step(g.RETRY_WAIT * 2.0)
	_come_back()
	_check(m.challenge.phase == "" and g.rung == 0, "the autowalk is never offered a second dare")

	await _check_givers(game)
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("DARE RETRY OK")
		quit(0)
	else:
		print("DARE RETRY FAIL")
		quit(1)
